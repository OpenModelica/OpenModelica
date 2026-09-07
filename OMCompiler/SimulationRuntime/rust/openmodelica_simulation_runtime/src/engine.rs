//! The [`SimEngine`] the shared driver runs the C model through.
//!
//! Reads and writes go to [`RtData`]'s region map; calls go to
//! `data->callback`, through `src/shim.c` so a failed `assert` in the model comes
//! back as an error instead of unwinding past us.

use core::ffi::{c_char, c_int, c_long};
use core::sync::atomic::{AtomicBool, Ordering};

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

/// C's `noThrowAsserts`, as the driver opens and closes its window.
static NO_THROW: AtomicBool = AtomicBool::new(false);
/// A violated `assert()` the model only noted inside it (C's `needToReThrow`).
static NOTED_ASSERT: AtomicBool = AtomicBool::new(false);

pub fn set_no_throw(v: bool) {
    NO_THROW.store(v, Ordering::Relaxed);
}

unsafe extern "C" {
    fn rt_init(numTimer: c_int);
    fn rt_clear(ix: c_int);
    fn rt_ncall(ix: c_int) -> u32;
    fn rt_ncall_total(ix: c_int) -> u32;
    fn rt_ncall_min(ix: c_int) -> u32;
    fn rt_ncall_max(ix: c_int) -> u32;
    fn rt_accumulated(ix: c_int) -> f64;
    fn rt_max_accumulated(ix: c_int) -> f64;
    fn rt_total(ix: c_int) -> f64;
}

/// `rtclock.h`: the first clock the generated code's `SIM_PROF_*` macros index from.
const SIM_TIMER_FIRST_FUNCTION: c_int = 16;

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
    /// on), its open region as `threadData->currentErrorStage`, and its assert
    /// window as `noThrowAsserts`.
    fn publish(&mut self) {
        let mode = {
            let mut b = [0u8; 4];
            let _ = self.rt.read(self.rt.layout.rel_fresh_off, &mut b);
            i32::from_ne_bytes(b)
        };
        let ds = self.driver_stage() as u32;
        self.stage = match ds {
            openmodelica_nls::ERROR_INTEGRATOR => error_stage::INTEGRATOR,
            openmodelica_nls::ERROR_NONLINEARSOLVER => error_stage::NONLINEARSOLVER,
            openmodelica_nls::ERROR_EVENTHANDLING => error_stage::EVENTHANDLING,
            _ => error_stage::SIMULATION,
        };
        let si = self.rt.info();
        si.noThrowAsserts = NO_THROW.load(Ordering::Relaxed) as modelica_boolean;
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

    /// What a model call's return means: a violated assertion the model only
    /// noted (`needToReThrow`) is kept for the driver to settle when it closes the
    /// assert window; a jump it took raises the open region's `hit` word rather
    /// than ending the run -- as long as a region is open to absorb it.
    fn absorb(&mut self, rc: c_int) -> Result<()> {
        let si = self.rt.info();
        if si.needToReThrow != 0 {
            si.needToReThrow = 0;
            NOTED_ASSERT.store(true, Ordering::Relaxed);
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

    fn lin_frame(&mut self, datarec: bool) -> Option<String> {
        Some(crate::linearize::frame(self.rt.data, datarec))
    }

    /// C's generated `updateBoundVariableAttributes` prints the block itself.
    fn model_logs_bound_attrs(&self) -> bool {
        true
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
            // C's `initSynchronous` calls this at every solver setup; the layout
            // already ran it once. A real call moves `baseClocks`, so the region
            // map is re-pointed after it.
            "functionInitSynchronous" => {
                if crate::sync::take_fresh() {
                    return Ok(());
                }
                self.publish();
                crate::sync::init_clocks(self.rt.data, self.rt.thread_data);
                crate::data::build_regions(&mut self.rt);
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
                // `evalZeroCross = 0`, the plain relations C's `updateDiscreteSystem`
                // opens with; the wasm codegen's function computes the same.
                let rc = unsafe {
                    omr_protected_call1(
                        core::mem::transmute::<
                            unsafe extern "C" fn(*mut DATA, *mut threadData_t, c_int) -> c_int,
                            unsafe extern "C" fn(*mut DATA, *mut threadData_t, c_long) -> c_int,
                        >(f),
                        self.rt.data,
                        self.rt.thread_data,
                        0,
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
            // The copies between `simulationInfo`'s arrays and the model's own
            // variables; a wasm model writes the variables directly and has none.
            "functionInputVars" => self.call_cb(cb.input_function),
            "functionOutputVars" => self.call_cb(cb.output_function),
            "functionReconInputs" => self.call_cb(cb.data_function),
            "functionReconSetC" => self.call_cb(cb.setc_function),
            "functionReconSetB" => self.call_cb(cb.setb_function),
            // C's `functionJac<X>` (`linearize.cpp`) and `getJacobianMatrix<X>`
            // (`dataReconciliation.cpp`), into the flat window the shared
            // implementation reads the matrix back from.
            "linearJacA" | "linearJacB" | "linearJacC" | "linearJacD" | "reconJacF"
            | "reconJacH" => {
                let (k, recon) = match crate::datarecon::index_of(name) {
                    Some(k) => (k, true),
                    None => (crate::linearize::index_of(name).unwrap_or(0), false),
                };
                self.publish();
                let mut out: Vec<f64> = Vec::new();
                let (data, thread_data) = (self.rt.data, self.rt.thread_data);
                let ok = crate::support::protected(thread_data, self.stage, || match recon {
                    true => crate::datarecon::eval(data, thread_data, k, &mut out),
                    false => crate::linearize::eval(data, thread_data, k, &mut out),
                });
                self.absorb(if ok { 0 } else { -1 })?;
                let base = match recon {
                    true => crate::datarecon::window(&self.rt.layout, data, k),
                    false => crate::linearize::window(&self.rt.layout, data, k),
                };
                for (i, v) in out.iter().enumerate() {
                    self.write_bytes(base + (i as u32) * 8, &v.to_le_bytes())?;
                }
                Ok(())
            }
            // `optJac<X>_column` / `optJac<X>_constantEqns`: one column set of
            // `INDEX_JAC_{B,C,D}`. The optimizer seeded `seedVars` itself, through
            // the window the region map points at C's own array.
            _ => match crate::optimization::index_of(name) {
                Some((k, constant)) => {
                    self.publish();
                    let (data, thread_data) = (self.rt.data, self.rt.thread_data);
                    let ok = crate::support::protected(thread_data, self.stage, || {
                        crate::optimization::eval(data, thread_data, k, constant);
                    });
                    self.absorb(if ok { 0 } else { -1 })
                }
                None => Err("the C model has no such entry point"),
            },
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
            // The driver names a sub-clock by its flat index, which is what a wasm
            // module's dispatcher takes; C's takes the `(base, sub)` pair.
            driver::MODEL_FN_UPDATE_SYNC => {
                let Some(f) = self.rt.callbacks().function_updateSynchronous else { return Ok(()) };
                self.publish();
                let (data, thread_data, base) = (self.rt.data, self.rt.thread_data, b as c_long);
                let ok = crate::support::protected(thread_data, self.stage, || {
                    unsafe { f(data, thread_data, base) };
                });
                self.absorb(if ok { 0 } else { -1 })
            }
            driver::MODEL_FN_EQS_SYNC => {
                let Some(f) = self.rt.callbacks().function_equationsSynchronous else {
                    return Ok(());
                };
                self.publish();
                let (data, thread_data) = (self.rt.data, self.rt.thread_data);
                let (base, sub) = crate::sync::split(data, b);
                let ok = crate::support::protected(thread_data, self.stage, || {
                    unsafe { f(data, thread_data, base, sub) };
                });
                self.absorb(if ok { 0 } else { -1 })
            }
            _ => Err("the C model has no such two-argument entry point"),
        }
    }

    fn call_simulate(&mut self, _sim_data: u32, _start: f64, _stop: f64, _n: u32) -> Result<u32> {
        Err("the C model has no in-model simulate entry point")
    }

    /// The string slots are opaque to the region map (a `modelica_string` is a
    /// pointer here); the value is read from the array C keeps it in.
    fn string_at(&self, addr: u32) -> Result<String> {
        let l = &self.rt.layout;
        let md = unsafe { &*(*self.rt.data).modelData };
        let (base, count, arr) = if addr >= l.sparam_off {
            (l.sparam_off, md.nParametersString, unsafe { (*(*self.rt.data).simulationInfo).stringParameter })
        } else {
            (l.str_off, md.nVariablesString, unsafe { (*(*(*self.rt.data).localData)).stringVars })
        };
        let i = ((addr - base) / 4) as c_long;
        if i >= count || arr.is_null() {
            return Err("string slot out of range");
        }
        Ok(crate::model_data::string_value(unsafe { *arr.add(i as usize) }))
    }

    /// C's `rt_init` in `initRuntimeAndSimulation`: the function, equation and
    /// block clocks the generated code ticks, plus C's sentinel.
    fn prof_init(&mut self, n: u32) {
        let xml = &self.rt.model().modelDataXml;
        unsafe { rt_init(SIM_TIMER_FIRST_FUNCTION + n as c_int + xml.nEquations as c_int + 4) };
    }

    /// C's `clear_rt_step` over the function and block clocks.
    fn prof_clear(&mut self) {
        for i in 0..crate::data::prof_clocks(self.rt.model()) as c_int {
            unsafe { rt_clear(SIM_TIMER_FIRST_FUNCTION + i) };
        }
    }

    /// The step record the profiler reads: every clock's call count, then its seconds.
    fn prof_row(&mut self) -> u32 {
        let n = crate::data::prof_clocks(self.rt.model()) as usize;
        let mut b = vec![0u8; n * 12];
        for i in 0..n {
            let ix = SIM_TIMER_FIRST_FUNCTION + i as c_int;
            b[4 * i..4 * i + 4].copy_from_slice(&unsafe { rt_ncall(ix) }.to_le_bytes());
            let o = 4 * n + 8 * i;
            b[o..o + 8].copy_from_slice(&unsafe { rt_accumulated(ix) }.to_le_bytes());
        }
        let off = self.rt.prof_off;
        let _ = self.rt.write(off, &b);
        off
    }

    /// The run totals, 40 bytes per clock in the profiler's record order.
    fn prof_dump(&mut self) -> u32 {
        let n = crate::data::prof_clocks(self.rt.model()) as usize;
        let mut b = vec![0u8; n * 40];
        for i in 0..n {
            let ix = SIM_TIMER_FIRST_FUNCTION + i as c_int;
            let o = 40 * i;
            unsafe {
                b[o..o + 8].copy_from_slice(&rt_total(ix).to_le_bytes());
                b[o + 8..o + 16].copy_from_slice(&rt_max_accumulated(ix).to_le_bytes());
                b[o + 16..o + 24].copy_from_slice(&rt_accumulated(ix).to_le_bytes());
                b[o + 24..o + 28].copy_from_slice(&rt_ncall_total(ix).to_le_bytes());
                b[o + 28..o + 32].copy_from_slice(&rt_ncall_min(ix).to_le_bytes());
                b[o + 32..o + 36].copy_from_slice(&rt_ncall_max(ix).to_le_bytes());
                b[o + 36..o + 40].copy_from_slice(&rt_ncall(ix).to_le_bytes());
            }
        }
        let off = self.rt.prof_off;
        let _ = self.rt.write(off, &b);
        off
    }

    fn sample_index(&self, k: usize) -> Option<i32> {
        let md = self.rt.model();
        (k < md.nSamples.max(0) as usize).then(|| unsafe { (*md.samplesInfo.add(k)).index as i32 })
    }

    fn update_static_system_data(&mut self, linear: bool) {
        let (data, td) = (self.rt.data, self.rt.thread_data);
        let md = self.rt.model();
        let si = self.rt.info();
        self.publish();
        if linear {
            for i in 0..md.nLinearSystems.max(0) as usize {
                let ls = unsafe { &mut *si.linearSystemData.add(i) };
                if let Some(f) = ls.initializeStaticLSData {
                    unsafe { f(data, td, ls, 0) };
                }
            }
        } else {
            for i in 0..md.nNonLinearSystems.max(0) as usize {
                let sys = unsafe { &mut *si.nonlinearSystemData.add(i) };
                if let Some(f) = sys.initializeStaticNLSData {
                    unsafe { f(data, td, sys, 0, 0) };
                }
            }
        }
    }

    fn set_rhs_final(&mut self, final_eval: bool) {
        unsafe { crate::support::RHSFinalFlag = final_eval as c_int };
    }

    fn take_noted_assert(&mut self) -> bool {
        NOTED_ASSERT.swap(false, Ordering::Relaxed)
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
        let mut nominal = vec![1.0f64; (2 * l.n_states + l.n_real_alg) as usize];
        unsafe {
            for a in 0..md.nVariablesRealArray as usize {
                let v = &*md.realVarsData.add(a);
                let base = *si.realVarsIndex.add(a);
                for k in 0..v.dimension.scalar_length {
                    if base + k >= nominal.len() {
                        break;
                    }
                    nominal[base + k] = v.attribute.nominal.real_at(k, 1.0);
                }
            }
        }
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
        // The optimizer reads `min`/`max`/`nominal`/`useNominal` of every real
        // variable, not just the states'; C reaches them through
        // `getMinFromScalarIdx` and friends, which is this scalarization.
        if l.n_opt_attr > 0 {
            let n = l.n_opt_attr as usize;
            let (mut min, mut max) = (vec![-f64::MAX; n], vec![f64::MAX; n]);
            let mut use_nom = vec![0i32; n];
            unsafe {
                for a in 0..md.nVariablesRealArray as usize {
                    let v = &*md.realVarsData.add(a);
                    let base = *si.realVarsIndex.add(a);
                    for k in 0..v.dimension.scalar_length {
                        if base + k >= n {
                            break;
                        }
                        min[base + k] = v.attribute.min.real_at(k, -f64::MAX);
                        max[base + k] = v.attribute.max.real_at(k, f64::MAX);
                        use_nom[base + k] = (v.attribute.useNominal != 0) as i32;
                    }
                }
            }
            let f64s = |v: &[f64]| -> Vec<u8> { v.iter().flat_map(|x| x.to_ne_bytes()).collect() };
            let _ = self.rt.write(l.opt_min_off, &f64s(&min));
            let _ = self.rt.write(l.opt_max_off, &f64s(&max));
            let _ = self.rt.write(l.opt_nom_off, &f64s(&nominal[..n.min(nominal.len())]));
            let bytes: Vec<u8> = use_nom.iter().flat_map(|v| v.to_ne_bytes()).collect();
            let _ = self.rt.write(l.opt_use_nom_off, &bytes);
        }
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
