//! The [`SimEngine`] the shared driver runs the C model through.
//!
//! Reads and writes go to [`RtData`]'s region map; calls go to
//! `data->callback`, through `src/shim.c` so a failed `assert` in the model comes
//! back as an error instead of unwinding past us.

use core::ffi::{c_char, c_int, c_long};

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
    /// C's `omc_assert_simulation` does for that phase. Republished from the
    /// driver's own stage word on every call (see [`CEngine::publish`]).
    pub stage: c_int,
}

impl CEngine {
    pub fn new(rt: RtData) -> Self {
        CEngine { rt, stage: error_stage::SIMULATION }
    }

    /// Flat address of the driver's `[stage, hit]` pair.
    fn err_off(&self) -> u32 {
        self.rt.layout.total + crate::data::ERR_STAGE_OFF
    }

    /// The region the driver currently has open.
    fn driver_stage(&self) -> i32 {
        let mut b = [0u8; 4];
        let _ = self.rt.read(self.err_off(), &mut b);
        i32::from_ne_bytes(b)
    }

    /// Raise the pair's `hit` word: a model error the open region absorbed, which
    /// is what the driver reads when it closes the region.
    fn mark_hit(&mut self) {
        let _ = self.rt.write(self.err_off() + 4, &1i32.to_ne_bytes());
    }

    /// Whether a model error raised now is one of the open region's to absorb.
    /// Outside every region it is what C's outermost `MMC_TRY_INTERNAL` would not
    /// catch either, and ends the run.
    fn error_absorbed(stage: i32) -> bool {
        use openmodelica_nls as nls;
        [
            nls::ERROR_INTEGRATOR,
            nls::ERROR_NONLINEARSOLVER,
            nls::ERROR_SIMULATION_STEP,
            nls::ERROR_EVENTHANDLING,
        ]
        .contains(&(stage as u32))
    }

    /// Publish what the generated code reads but the layout keeps elsewhere, before
    /// every model call: the driver's relation mode as C's
    /// `discreteCall`/`solveContinuous` pair (what `relationhysteresis` branches
    /// on), and its open region as `threadData->currentErrorStage` plus
    /// `noThrowAsserts`.
    fn publish(&mut self) {
        let mode = {
            let mut b = [0u8; 4];
            let _ = self.rt.read(self.rt.layout.rel_fresh_off, &mut b);
            i32::from_ne_bytes(b)
        };
        // The driver's region, as the two things C keeps it in: the stage decides
        // which jump buffer an assertion takes and how loudly it reports, and
        // `noThrowAsserts` is C's `simulationUpdate` region, where the generated
        // assert only notes itself in `needToReThrow` and carries on.
        let ds = self.driver_stage() as u32;
        self.stage = match ds {
            openmodelica_nls::ERROR_INTEGRATOR => error_stage::INTEGRATOR,
            openmodelica_nls::ERROR_NONLINEARSOLVER => error_stage::NONLINEARSOLVER,
            openmodelica_nls::ERROR_EVENTHANDLING => error_stage::EVENTHANDLING,
            _ => error_stage::SIMULATION,
        };
        let si = self.rt.info();
        si.noThrowAsserts = (ds == openmodelica_nls::ERROR_EVENTHANDLING) as modelica_boolean;
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
        self.absorb(rc)
    }

    /// What a model call's return means for the region the driver has open: a
    /// violated assertion the model only noted (`needToReThrow`), or a jump it
    /// took, both raise the pair's `hit` word rather than ending the run -- as long
    /// as a region is open to absorb it.
    fn absorb(&mut self, rc: c_int) -> Result<()> {
        let si = self.rt.info();
        let noted = si.needToReThrow != 0;
        si.needToReThrow = 0;
        if noted {
            self.mark_hit();
        }
        if rc != -1 {
            return Ok(());
        }
        if Self::error_absorbed(self.driver_stage()) {
            self.mark_hit();
            return Ok(());
        }
        // The reason is already on the log, from `omr_assert_report`; naming it C's
        // own `longjmp` is what makes the driver print the initialization notice.
        Err(driver::ASSERT_ERR)
    }
}

impl SimEngine for CEngine {
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> Result<()> {
        self.rt.read(addr, buf)
    }

    fn write_bytes(&mut self, addr: u32, buf: &[u8]) -> Result<()> {
        self.rt.write(addr, buf)
    }

    /// C's `currentContext`, mapped past the layout's end (`data::CONTEXT_OFF`).
    fn context_addr(&mut self) -> u32 {
        self.rt.layout.total + crate::data::CONTEXT_OFF
    }

    /// The `[stage, hit]` pair, in the driver's own memory past the layout's end.
    fn error_stage_addr(&mut self) -> u32 {
        self.err_off()
    }

    /// The per-system statistics `LOG_STATS_V` renders, measured where the systems
    /// are solved: `openmodelica_solvers::sysstat`, which both runtimes bracket.
    fn sys_stats(&mut self) -> Vec<openmodelica_solvers::sysstat::SysStat> {
        openmodelica_solvers::sysstat::systems().to_vec()
    }

    /// The shared solvers' counters (`openmodelica_solvers::counters`), which the
    /// wasm runtime hands over as `rt_stat` slots. The driver reads
    /// `RT_STAT_HOMOTOPY_STEPS` out of these for C's "with N local homotopy steps".
    fn rt_stats(&mut self) -> [u64; driver::RT_STATS] {
        let mut out = [0u64; driver::RT_STATS];
        for (k, slot) in out.iter_mut().enumerate() {
            *slot = openmodelica_solvers::counters::stat(k as u32);
        }
        out
    }

    /// C's `cleanUpOldValueListAfterEvent`.
    fn clean_nls_history(&mut self, time: f64) {
        crate::nls::clean_history_after_event(self.rt.data, time);
    }

    /// `crate::systems` / `crate::nls` are C's own `initialize*Systems`.
    fn host_logs_system_init(&self) -> bool {
        true
    }

    /// C's `TermMsg` / `TermInfo`, which `omc_terminate_simulation` fills; the
    /// driver's own `term_info` region has no C counterpart.
    fn terminate_info(&self) -> Option<driver::TerminateInfo> {
        fn cstr(p: *const c_char) -> String {
            if p.is_null() {
                return String::new();
            }
            unsafe { core::ffi::CStr::from_ptr(p) }.to_string_lossy().into_owned()
        }
        let info = unsafe { crate::support::TermInfo };
        Some(driver::TerminateInfo {
            msg: cstr(unsafe { crate::support::TermMsg }),
            file: cstr(info.filename),
            span: [info.lineStart, info.colStart, info.lineEnd, info.colEnd],
            readonly: info.readonly != 0,
        })
    }

    /// C's generated `updateBoundVariableAttributes` prints the block itself.
    fn model_logs_bound_attrs(&self) -> bool {
        true
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
            // The generated body prints the inconsistent equation and returns 1.
            "functionRemovedInitialEquations" => {
                let Some(f) = cb.functionRemovedInitialEquations else { return Ok(()) };
                self.publish();
                let rc =
                    unsafe { omr_protected_call(f, self.rt.data, self.rt.thread_data, self.stage) };
                self.absorb(rc)?;
                if rc > 0 { Err(driver::REMOVED_INIT_INCONSISTENT) } else { Ok(()) }
            }
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
            // C allocates in `initializeDataStruc` and the model's function only
            // fills; the driver calls this on every initialization attempt, so the
            // allocation belongs with it.
            "functionInitSpatialDistribution" => {
                crate::spatial::init(self.rt.model().nSpatialDistributions as usize);
                self.call_cb(cb.function_initSpatialDistribution)
            }
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
                self.absorb(rc)
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
            // C's `analyticJacobians[INDEX_JAC_A]` column evaluation; the driver
            // seeds and reads it through the flat window `build_regions` maps.
            "functionJacA_column" | "functionJacA_constantEqns" => {
                let jac = crate::data::jac_a_ptr(self.rt.data);
                let Some(j) = (unsafe { jac.as_ref() }) else { return Ok(()) };
                let f = if name == "functionJacA_column" { j.evalColumn } else { j.constantEqns };
                let Some(f) = f else { return Ok(()) };
                self.publish();
                let ok = crate::support::protected(self.rt.thread_data, self.stage, || {
                    unsafe { f(self.rt.data, self.rt.thread_data, jac, core::ptr::null_mut()) };
                });
                self.absorb(if ok { 0 } else { -1 })
            }
            "functionStateSetJacobians" => {
                self.publish();
                crate::stateset::eval_jacobians(self.rt.data, self.rt.thread_data)
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
                self.absorb(rc)
            }
            // C's `evaluateDAEResiduals`, the one entry point `--daeMode` adds; `b`
            // is the evaluation stage.
            driver::MODEL_FN_DAE => {
                let dae = self.rt.info().daeModeData;
                let f = unsafe { dae.as_ref() }
                    .and_then(|d| d.evaluateDAEResiduals)
                    .ok_or("the C model has no DAE residual function")?;
                self.publish();
                let rc = unsafe {
                    omr_protected_call1(
                        core::mem::transmute::<
                            unsafe extern "C" fn(*mut DATA, *mut threadData_t, c_int) -> c_int,
                            unsafe extern "C" fn(*mut DATA, *mut threadData_t, c_long) -> c_int,
                        >(f),
                        self.rt.data,
                        self.rt.thread_data,
                        b as c_long,
                        self.stage,
                    )
                };
                self.absorb(rc)
            }
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
            for a in 0..md.nParametersStringArray as usize {
                let p = &*md.stringParameterData.add(a);
                let base = *si.stringParamsIndex.add(a);
                for k in 0..p.dimension.scalar_length {
                    *si.stringParameter.add(base + k) = p.attribute.start;
                }
            }
        }
    }

    /// C's `copyStartValuestoInitValues` for the String variables, which the driver
    /// cannot do: their region in the flat layout is opaque, so `set_all_vars_to_start`
    /// leaves `stringVars` at the null every generated `stringEqual` would follow.
    pub fn seed_string_vars(&mut self) {
        let md = self.rt.model();
        let si = self.rt.info();
        let sd = self.rt.local(0);
        unsafe {
            for a in 0..md.nVariablesStringArray as usize {
                let v = &*md.stringVarsData.add(a);
                let base = *si.stringVarsIndex.add(a);
                for k in 0..v.dimension.scalar_length {
                    *sd.stringVars.add(base + k) = v.attribute.start;
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
        // C's `getAlgebraicDAEVarNominals`: the algebraic unknowns IDA carries after
        // the states, clamped like the states' own.
        if l.n_dae_alg > 0 {
            let ix = unsafe { (*si.daeModeData).algIndexes };
            let alg: Vec<u8> = (0..l.n_dae_alg as usize)
                .flat_map(|i| {
                    let k = unsafe { *ix.add(i) } as usize;
                    nominal.get(k).copied().unwrap_or(1.0).abs().max(1e-32).to_ne_bytes()
                })
                .collect();
            let _ = self.rt.write(l.dae_alg_nom_off, &alg);
        }
    }
}
