//! The [`SimEngine`] the shared driver runs the C model through.
//!
//! Reads and writes go to [`RtData`]'s region map; calls go to
//! `data->callback`, through `src/shim.c` so a failed `assert` in the model comes
//! back as an error instead of unwinding past us.

use core::ffi::{c_int, c_long};

use openmodelica_sim_meta::driver::{self, Result, SimEngine};

use crate::abi::*;
use crate::data::RtData;
use crate::support::error_stage;

unsafe extern "C" {
    fn omr_protected_call(
        f: unsafe extern "C" fn(*mut DATA, *mut threadData_t) -> c_int,
        data: *mut DATA,
        threadData: *mut threadData_t,
        stage: c_int,
    ) -> c_int;
    fn omr_protected_call1(
        f: unsafe extern "C" fn(*mut DATA, *mut threadData_t, c_long) -> c_int,
        data: *mut DATA,
        threadData: *mut threadData_t,
        arg: c_long,
        stage: c_int,
    ) -> c_int;
    fn omr_protected_call_zc(
        f: unsafe extern "C" fn(*mut DATA, *mut threadData_t, *mut f64) -> c_int,
        data: *mut DATA,
        threadData: *mut threadData_t,
        gout: *mut f64,
        stage: c_int,
    ) -> c_int;
}

pub struct CEngine {
    pub rt: RtData,
    /// Which error stage a model call runs under, so an assertion reports the way
    /// C's `omc_assert_simulation` does for that phase.
    pub stage: c_int,
}

impl CEngine {
    pub fn new(rt: RtData) -> Self {
        CEngine { rt, stage: error_stage::SIMULATION }
    }

    /// Publish the flags the generated equations read but the layout keeps
    /// elsewhere: C's `discreteCall`/`solveContinuous` pair, which
    /// `relationhysteresis` branches on, stands for the driver's relation mode.
    fn publish(&mut self) {
        let mode = {
            let mut b = [0u8; 4];
            let _ = self.rt.read(self.rt.layout.rel_fresh_off, &mut b);
            i32::from_ne_bytes(b)
        };
        let si = self.rt.info();
        // 0 held, 1 event, 2 initialization -- C reaches the held branch through
        // `discreteCall == 0 || solveContinuous`, and the fresh one through neither.
        si.discreteCall = if mode == 0 { 0 } else { 1 };
        si.solveContinuous = (mode == 0) as c_int;
        // `localData[1]`'s time is what `$_old` equations read.
        let t = self.rt.local(0).timeValue;
        self.rt.local(1).timeValue = t;
    }

    /// Call one `data->callback` entry point under the shim's jump buffer. A
    /// callback the model left null is nothing to do — C's own runtime skips the
    /// optional ones the same way.
    fn call_cb(
        &mut self,
        f: Option<unsafe extern "C" fn(*mut DATA, *mut threadData_t) -> c_int>,
    ) -> Result<()> {
        let Some(f) = f else { return Ok(()) };
        self.publish();
        let rc = unsafe { omr_protected_call(f, self.rt.data, self.rt.thread_data, self.stage) };
        if rc == -1 { Err(MODEL_ERROR) } else { Ok(()) }
    }
}

/// What a call that left through its jump buffer reports back; the reason itself
/// is already on the log, from `omr_assert_report`. C would first re-run the step
/// with the assertion absorbed and look for an event around it — this runtime
/// does not (see `error_stage_addr` in the handoff), so the error ends the run.
const MODEL_ERROR: &str = "a model assertion was violated and could not be absorbed";

impl SimEngine for CEngine {
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> Result<()> {
        self.rt.read(addr, buf)
    }

    fn write_bytes(&mut self, addr: u32, buf: &[u8]) -> Result<()> {
        self.rt.write(addr, buf)
    }

    fn has_discrete_entry(&self) -> bool {
        self.rt.callbacks().functionDAE.is_some()
    }

    fn call1_raw(&mut self, name: &str, _arg: u32) -> Result<()> {
        let cb = self.rt.callbacks();
        match name {
            "functionODE" => {
                self.rt.info().callStatistics.functionODE += 1;
                self.call_cb(cb.functionODE)
            }
            "functionAlgebraics" => {
                self.rt.info().callStatistics.functionAlgebraics += 1;
                self.call_cb(cb.functionAlgebraics)
            }
            "functionDAE" => {
                self.rt.info().callStatistics.updateDiscreteSystem += 1;
                self.call_cb(cb.functionDAE)
            }
            "functionLocalKnownVars" => self.call_cb(cb.functionLocalKnownVars),
            "functionInitialEquations" => self.call_cb(cb.functionInitialEquations),
            "functionInitialEquations_lambda0" => {
                self.call_cb(cb.functionInitialEquations_lambda0)
            }
            "functionRemovedInitialEquations" => self.call_cb(cb.functionRemovedInitialEquations),
            "functionUpdateBoundParameters" => self.call_cb(cb.updateBoundParameters),
            "functionUpdateBoundVariableAttributes" => {
                let r = self.call_cb(cb.updateBoundVariableAttributes);
                self.sync_attributes();
                r
            }
            "functionCheckAsserts" => self.call_cb(cb.checkForAsserts),
            "functionStoreDelayed" => self.call_cb(cb.function_storeDelayed),
            "functionStoreSpatialDistribution" => {
                self.call_cb(cb.function_storeSpatialDistribution)
            }
            "functionInitSpatialDistribution" => self.call_cb(cb.function_initSpatialDistribution),
            "functionZeroCrossingsEquations" => {
                self.rt.info().callStatistics.functionZeroCrossingsEquations += 1;
                self.call_cb(cb.function_ZeroCrossingsEquations)
            }
            "symbolicInlineSystem" => self.call_cb(cb.symbolicInlineSystems),
            "callExternalObjectDestructors" => {
                if let Some(f) = cb.callExternalObjectDestructors {
                    unsafe { f(self.rt.data, self.rt.thread_data) };
                }
                Ok(())
            }
            "initSample" => {
                if let Some(f) = cb.function_initSample {
                    self.publish();
                    unsafe { f(self.rt.data, self.rt.thread_data) };
                }
                Ok(())
            }
            "functionUpdateRelations" => {
                let Some(f) = cb.function_updateRelations else { return Ok(()) };
                self.publish();
                // C's `evalZeroCross`: fresh, hysteretic relation values.
                let rc = unsafe {
                    omr_protected_call1(
                        core::mem::transmute::<
                            unsafe extern "C" fn(*mut DATA, *mut threadData_t, c_int) -> c_int,
                            unsafe extern "C" fn(*mut DATA, *mut threadData_t, c_long) -> c_int,
                        >(f),
                        self.rt.data,
                        self.rt.thread_data,
                        1,
                        self.stage,
                    )
                };
                if rc == -1 { Err(MODEL_ERROR) } else { Ok(()) }
            }
            // A C model has no generated function for either: the start values
            // come from the init XML, which this runtime read into `modelData`.
            "functionParameters" => {
                self.set_all_params_to_start();
                Ok(())
            }
            "functionInitStartValues" => Ok(()),
            "functionInitDelay" => {
                let md = self.rt.model();
                let start = self.rt.info().startTime;
                crate::operators::init(md.nDelayExpressions as usize, start);
                Ok(())
            }
            // Reached only for a model with `$STATESET`s, which the metadata
            // builder does not describe yet, so the driver never asks.
            "functionStateSetJacobians" => {
                Err("dynamic state selection is not served by this runtime yet")
            }
            _ => Err("the C model has no such entry point"),
        }
    }

    fn call1_if_present_raw(&mut self, name: &str, arg: u32) -> Result<()> {
        match self.call1_raw(name, arg) {
            Err(e) if e == "the C model has no such entry point" => Ok(()),
            other => other,
        }
    }

    fn call2_raw(&mut self, name: &str, _a: u32, b: u32) -> Result<()> {
        match name {
            driver::MODEL_FN_ZC => {
                let Some(f) = self.rt.callbacks().function_ZeroCrossings else { return Ok(()) };
                self.rt.info().callStatistics.functionZeroCrossings += 1;
                self.publish();
                // `b` addresses the flat crossing-value region; C writes straight
                // into `zeroCrossings` / the probe buffer behind it.
                let gout = self.gout_ptr(b)?;
                let rc = unsafe {
                    omr_protected_call_zc(f, self.rt.data, self.rt.thread_data, gout, self.stage)
                };
                if rc == -1 { Err(MODEL_ERROR) } else { Ok(()) }
            }
            driver::MODEL_FN_DAE => Err("--daeMode is not served by this runtime yet"),
            driver::MODEL_FN_UPDATE_SYNC | driver::MODEL_FN_EQS_SYNC => {
                Err("clocked partitions are not served by this runtime yet")
            }
            _ => Err("the C model has no such two-argument entry point"),
        }
    }

    fn call_simulate(&mut self, _sim_data: u32, _start: f64, _stop: f64, _n: u32) -> Result<u32> {
        Err("the C model has no in-model simulate entry point")
    }

    fn take_pending_assert(&mut self) -> Option<[i32; 9]> {
        None
    }
}

impl CEngine {
    /// The native address behind a flat crossing-value buffer, which C's
    /// `function_ZeroCrossings` writes through a `double*`.
    fn gout_ptr(&mut self, addr: u32) -> Result<*mut f64> {
        let l = self.rt.layout;
        let si = self.rt.info();
        if addr == l.zc_off {
            Ok(si.zeroCrossings)
        } else if addr == l.zc_probe_off {
            Ok(si.zeroCrossingsBackup)
        } else if addr == l.zc_pre_off {
            Ok(si.zeroCrossingsPre)
        } else {
            Err("zero-crossing values requested outside the crossing regions")
        }
    }

    /// C's `setAllParamsToStart`: the parameter arrays take the start values the
    /// init XML gave, before any bound-parameter equation runs.
    fn set_all_params_to_start(&mut self) {
        let md = self.rt.model();
        let si = self.rt.info();
        unsafe {
            for a in 0..md.nParametersRealArray as usize {
                let p = &*md.realParameterData.add(a);
                let base = *si.realParamsIndex.add(a);
                for k in 0..p.dimension.scalar_length {
                    *si.realParameter.add(base + k) = p.attribute.start.real_at(k, 0.0);
                }
            }
            for a in 0..md.nParametersIntegerArray as usize {
                let p = &*md.integerParameterData.add(a);
                let base = *si.integerParamsIndex.add(a);
                for k in 0..p.dimension.scalar_length {
                    *si.integerParameter.add(base + k) = p.attribute.start;
                }
            }
            for a in 0..md.nParametersBooleanArray as usize {
                let p = &*md.booleanParameterData.add(a);
                let base = *si.booleanParamsIndex.add(a);
                for k in 0..p.dimension.scalar_length {
                    *si.booleanParameter.add(base + k) = p.attribute.start;
                }
            }
        }
    }

    /// The `start`, `nominal` and `max` attribute regions the driver reads are a
    /// flat mirror of `modelData->realVarsData[i].attribute`, which the generated
    /// `updateBoundVariableAttributes` writes. Refresh them whenever it has run.
    pub fn sync_attributes(&mut self) {
        let l = self.rt.layout;
        let md = self.rt.model();
        let si = self.rt.info();
        let n_states = l.n_states as usize;
        let mut start = vec![0.0f64; (2 * l.n_states + l.n_real_alg) as usize];
        let mut nominal = vec![1.0f64; start.len()];
        unsafe {
            for a in 0..md.nVariablesRealArray as usize {
                let v = &*md.realVarsData.add(a);
                let base = *si.realVarsIndex.add(a);
                for k in 0..v.dimension.scalar_length {
                    if base + k >= start.len() {
                        break;
                    }
                    start[base + k] = v.attribute.start.real_at(k, 0.0);
                    nominal[base + k] = v.attribute.nominal.real_at(k, 1.0);
                }
            }
        }
        let bytes: Vec<u8> = start.iter().flat_map(|v| v.to_ne_bytes()).collect();
        let _ = self.rt.write(l.start_off, &bytes);
        let bytes: Vec<u8> = nominal.iter().flat_map(|v| v.to_ne_bytes()).collect();
        let _ = self.rt.write(l.real_nom_off, &bytes);
        // The integrator's copies: C clamps the nominal away from zero and takes
        // the declared `max` as the difference quotient's bound.
        let clamped: Vec<u8> =
            nominal[..n_states].iter().flat_map(|v| v.abs().max(1e-32).to_ne_bytes()).collect();
        let _ = self.rt.write(l.state_nom_off, &clamped);
        let mut maxs = vec![f64::MAX; n_states];
        unsafe {
            for a in 0..md.nVariablesRealArray as usize {
                let v = &*md.realVarsData.add(a);
                let base = *si.realVarsIndex.add(a);
                for k in 0..v.dimension.scalar_length {
                    if base + k < n_states {
                        maxs[base + k] = v.attribute.max.real_at(k, f64::MAX);
                    }
                }
            }
        }
        let bytes: Vec<u8> = maxs.iter().flat_map(|v| v.to_ne_bytes()).collect();
        let _ = self.rt.write(l.state_max_off, &bytes);
    }
}
