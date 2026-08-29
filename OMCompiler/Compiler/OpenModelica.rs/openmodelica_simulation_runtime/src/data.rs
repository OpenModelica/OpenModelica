//! `initializeDataStruc` and the flat `SimData` the shared driver addresses.
//!
//! The driver reads and writes the model through one byte-addressed block whose
//! offsets a [`Layout`] describes -- the wasm-jit runtime's linear memory. A C
//! model has no such block: its variables live in the arrays `DATA` points at.
//! So this module allocates those arrays the way `model_help.c` does, and then
//! builds a *region map* from the layout's address space onto them. Reading
//! `sim_data + layout.pre_real_off + 8*i` reaches `simulationInfo->realVarsPre[i]`
//! with no copying; where the two ABIs disagree on a width (a `modelica_integer`
//! is 4 bytes in wasm and 8 here) the map converts, and the regions C has no
//! home for (the driver's own scratch) fall through to a buffer this module owns.

use core::ffi::{c_int, c_void};

use openmodelica_sim_meta::{Layout, REAL_OFF};

use crate::abi::*;
use crate::model_data::calloc;

/// C's `SIZERINGBUFFER`.
const RING: usize = 3;

/// Bytes past `Layout::total` this runtime adds to the flat address space, for the
/// slots the shared driver addresses as memory but the wasm layout keeps in the
/// runtime module rather than in `SimData`: the evaluation context
/// ([`CONTEXT_OFF`]) and the error-stage pair ([`ERR_STAGE_OFF`]).
pub const RT_EXTRA: u32 = 16;

/// Offset of C's `simulationInfo->currentContext` in that space, relative to
/// `Layout::total`. `setContext` is one store, so the driver marks a Jacobian
/// assembly without a call.
pub const CONTEXT_OFF: u32 = 0;

/// The driver's `[stage, hit]` i32 pair (`SimEngine::error_stage_addr`), which has
/// no C counterpart: `CEngine::publish` projects the stage onto
/// `threadData->currentErrorStage` and `simulationInfo->noThrowAsserts`, and a model
/// error absorbed under it raises `hit`. Driver-owned memory, so no region maps it.
pub const ERR_STAGE_OFF: u32 = 8;

/// How a stretch of the flat address space is stored on the C side.
#[derive(Clone, Copy)]
enum Backing {
    /// Byte-for-byte the same; `base` is the native start of the region.
    Direct(*mut u8),
    /// 4-byte flat slots over 8-byte `modelica_integer`s.
    WidenInt(*mut modelica_integer),
    /// `SAMPLE_INFO[i].start` / `.interval` behind flat `(f64, f64)` pairs.
    Samples(*mut SAMPLE_INFO),
    /// No C counterpart (a `modelica_string` / external-object handle, which the
    /// numeric driver never interprets): reads zero, writes are dropped.
    Opaque,
}

struct Region {
    start: u32,
    end: u32,
    backing: Backing,
}

/// Everything one run needs: the C structures, the layout over them, and the
/// buffer backing the parts of that layout C does not store.
pub struct RtData {
    pub data: *mut DATA,
    pub thread_data: *mut threadData_t,
    pub layout: Layout,
    /// The driver's own regions (scratch, attribute mirrors, flags C has no field
    /// for), at their layout offsets so a lookup miss can index straight in.
    owned: Vec<u8>,
    regions: Vec<Region>,
    /// `[start, end)` of the real-variable region and its native base -- checked
    /// before the region table, as almost every access lands here.
    reals: (u32, u32, *mut u8),
}

// The runtime is single-threaded; the pointers are the run's own C structures.
unsafe impl Send for RtData {}
unsafe impl Sync for RtData {}

impl RtData {
    /// The region `addr` falls in and its offset within it; `None` means the
    /// address belongs to the driver's own buffer.
    #[inline]
    fn find(&self, addr: u32) -> Option<(&Region, u32)> {
        let ix = self.regions.partition_point(|r| r.end <= addr);
        let r = self.regions.get(ix)?;
        (addr >= r.start).then(|| (r, addr - r.start))
    }

    /// Read `buf.len()` bytes at flat address `addr`, converting on the way where
    /// the backing's width differs from the layout's.
    #[inline]
    pub fn read(&self, addr: u32, buf: &mut [u8]) -> Result<(), &'static str> {
        if addr >= self.reals.0 && addr + buf.len() as u32 <= self.reals.1 {
            unsafe {
                core::ptr::copy_nonoverlapping(
                    self.reals.2.add((addr - self.reals.0) as usize),
                    buf.as_mut_ptr(),
                    buf.len(),
                )
            };
            return Ok(());
        }
        match self.find(addr) {
            None => {
                let end = addr as usize + buf.len();
                let src = self.owned.get(addr as usize..end).ok_or("SimData read out of range")?;
                buf.copy_from_slice(src);
                Ok(())
            }
            Some((r, off)) => match r.backing {
                Backing::Direct(base) => {
                    if addr as usize + buf.len() > r.end as usize {
                        return Err("SimData read crosses a region boundary");
                    }
                    unsafe {
                        core::ptr::copy_nonoverlapping(base.add(off as usize), buf.as_mut_ptr(), buf.len())
                    };
                    Ok(())
                }
                Backing::WidenInt(base) => {
                    if buf.len() % 4 != 0 || off % 4 != 0 {
                        return Err("SimData integer read is not a whole number of 4-byte slots");
                    }
                    for (k, out) in buf.chunks_exact_mut(4).enumerate() {
                        let v = unsafe { *base.add(off as usize / 4 + k) } as i32;
                        out.copy_from_slice(&v.to_ne_bytes());
                    }
                    Ok(())
                }
                Backing::Samples(base) => {
                    if buf.len() % 8 != 0 || off % 8 != 0 {
                        return Err("SimData sample read is not a whole number of 8-byte slots");
                    }
                    for (k, out) in buf.chunks_exact_mut(8).enumerate() {
                        let slot = off as usize + k * 8;
                        let s = unsafe { &*base.add(slot / 16) };
                        let v = if slot % 16 == 0 { s.start } else { s.interval };
                        out.copy_from_slice(&v.to_ne_bytes());
                    }
                    Ok(())
                }
                Backing::Opaque => {
                    buf.fill(0);
                    Ok(())
                }
            },
        }
    }

    /// [`RtData::read`]'s counterpart.
    #[inline]
    pub fn write(&mut self, addr: u32, buf: &[u8]) -> Result<(), &'static str> {
        if addr >= self.reals.0 && addr + buf.len() as u32 <= self.reals.1 {
            unsafe {
                core::ptr::copy_nonoverlapping(
                    buf.as_ptr(),
                    self.reals.2.add((addr - self.reals.0) as usize),
                    buf.len(),
                )
            };
            return Ok(());
        }
        let found = self.find(addr).map(|(r, off)| (r.backing, r.end, off));
        match found {
            None => {
                let end = addr as usize + buf.len();
                let dst = self.owned.get_mut(addr as usize..end).ok_or("SimData write out of range")?;
                dst.copy_from_slice(buf);
                Ok(())
            }
            Some((backing, region_end, off)) => match backing {
                Backing::Direct(base) => {
                    if addr as usize + buf.len() > region_end as usize {
                        return Err("SimData write crosses a region boundary");
                    }
                    unsafe {
                        core::ptr::copy_nonoverlapping(buf.as_ptr(), base.add(off as usize), buf.len())
                    };
                    Ok(())
                }
                Backing::WidenInt(base) => {
                    if buf.len() % 4 != 0 || off % 4 != 0 {
                        return Err("SimData integer write is not a whole number of 4-byte slots");
                    }
                    for (k, src) in buf.chunks_exact(4).enumerate() {
                        let v = i32::from_ne_bytes(src.try_into().unwrap());
                        unsafe { *base.add(off as usize / 4 + k) = v as modelica_integer };
                    }
                    Ok(())
                }
                Backing::Samples(base) => {
                    if buf.len() % 8 != 0 || off % 8 != 0 {
                        return Err("SimData sample write is not a whole number of 8-byte slots");
                    }
                    for (k, src) in buf.chunks_exact(8).enumerate() {
                        let slot = off as usize + k * 8;
                        let s = unsafe { &mut *base.add(slot / 16) };
                        let v = f64::from_ne_bytes(src.try_into().unwrap());
                        if slot % 16 == 0 { s.start = v } else { s.interval = v }
                    }
                    Ok(())
                }
                Backing::Opaque => Ok(()),
            },
        }
    }

    // The C structures outlive the run and are reached through raw pointers, so
    // these do not borrow `self` -- the region map writes through them freely.
    pub fn model(&self) -> &'static MODEL_DATA {
        unsafe { &*(*self.data).modelData }
    }
    pub fn info(&self) -> &'static mut SIMULATION_INFO {
        unsafe { &mut *(*self.data).simulationInfo }
    }
    pub fn callbacks(&self) -> &'static OpenModelicaGeneratedFunctionCallbacks {
        unsafe { &*(*self.data).callback }
    }
    pub fn local(&self, i: usize) -> &'static mut SIMULATION_DATA {
        unsafe { &mut **(*self.data).localData.add(i) }
    }
}

/// C's `initializeDataStruc`: allocate every array `DATA` points at, then lay the
/// driver's flat address space over them.
pub fn initialize(data: *mut DATA, thread_data: *mut threadData_t) -> RtData {
    let md: &mut MODEL_DATA = unsafe { &mut *(*data).modelData };
    let si: &mut SIMULATION_INFO = unsafe { &mut *(*data).simulationInfo };

    array_index_maps(md, si);

    md.nStates = unsafe { *si.realVarsIndex.add(md.nStatesArray as usize) } as i64;
    md.nVariablesReal = unsafe { *si.realVarsIndex.add(md.nVariablesRealArray as usize) } as i64;
    md.nVariablesInteger = unsafe { *si.integerVarsIndex.add(md.nVariablesIntegerArray as usize) } as i64;
    md.nVariablesBoolean = unsafe { *si.booleanVarsIndex.add(md.nVariablesBooleanArray as usize) } as i64;
    md.nVariablesString = unsafe { *si.stringVarsIndex.add(md.nVariablesStringArray as usize) } as i64;
    md.nParametersReal = unsafe { *si.realParamsIndex.add(md.nParametersRealArray as usize) } as i64;
    md.nParametersInteger =
        unsafe { *si.integerParamsIndex.add(md.nParametersIntegerArray as usize) } as i64;
    md.nParametersBoolean =
        unsafe { *si.booleanParamsIndex.add(md.nParametersBooleanArray as usize) } as i64;
    md.nParametersString = unsafe { *si.stringParamsIndex.add(md.nParametersStringArray as usize) } as i64;
    md.nAliasReal = md.nAliasRealArray;
    md.nAliasInteger = md.nAliasIntegerArray;
    md.nAliasBoolean = md.nAliasBooleanArray;
    md.nAliasString = md.nAliasStringArray;

    md.dag = core::ptr::null_mut();
    si.evalSelection = core::ptr::null_mut();

    let n_real = md.nVariablesReal as usize;
    let n_int = md.nVariablesInteger as usize;
    let n_bool = md.nVariablesBoolean as usize;
    let n_str = md.nVariablesString as usize;
    let n_states = md.nStates as usize;

    // The ring buffer, whose entries the C runtime rotates. The driver keeps the
    // previous accepted point itself (`old_real_off` is `localData[1]`), so the
    // entries stay put and only their contents change.
    let local: *mut *mut SIMULATION_DATA = calloc(RING);
    for i in 0..RING {
        let sd: *mut SIMULATION_DATA = calloc(1);
        unsafe {
            (*sd).timeValue = si.startTime;
            (*sd).realVars = calloc(n_real.max(1));
            (*sd).integerVars = calloc(n_int.max(1));
            (*sd).booleanVars = calloc(n_bool.max(1));
            (*sd).stringVars = calloc(n_str.max(1));
            *local.add(i) = sd;
        }
    }
    unsafe { (*data).localData = local };
    unsafe { (*data).simulationData = core::ptr::null_mut() };

    md.samplesInfo = calloc(md.nSamples as usize);
    si.nextSampleEvent = si.startTime;
    si.nextSampleTimes = calloc(md.nSamples as usize);
    si.samples = calloc(md.nSamples as usize);

    si.baseClocks = if md.nBaseClocks > 0 { calloc(md.nBaseClocks as usize) } else { core::ptr::null_mut() };
    si.intvlTimers = core::ptr::null_mut();
    si.spatialDistributionData = if md.nSpatialDistributions > 0 {
        calloc(md.nSpatialDistributions as usize)
    } else {
        core::ptr::null_mut()
    };

    // The defaults `initializeDataStruc` installs; the command line may replace
    // them (`-nls`, `-ls`, ...).
    si.nlsMethod = NLS_MIXED;
    si.nlsLinearSolver = NLS_LS_DEFAULT;
    si.lsMethod = crate::systems::LS_DEFAULT;
    si.lssMethod = LSS_DEFAULT;
    si.mixedMethod = MIXED_SEARCH;
    si.newtonStrategy = NEWTON_DAMPED2;
    si.nlsCsvInfomation = 0;
    si.currentContext = crate::systems::CONTEXT_ALGEBRAIC;
    si.jacobianEvals = md.nStates as c_int;

    let n_zc = md.nZeroCrossings as usize;
    let n_rel = md.nRelations as usize;
    si.zeroCrossings = calloc(n_zc.max(1));
    si.zeroCrossingsPre = calloc(n_zc.max(1));
    si.zeroCrossingsBackup = calloc(n_zc.max(1));
    si.relations = calloc(n_rel.max(1));
    si.relationsPre = calloc(n_rel.max(1));
    si.storedRelations = calloc(n_rel.max(1));
    si.mathEventsValuePre = calloc((md.nMathEvents as usize).max(1));
    si.zeroCrossingIndex = calloc(n_zc.max(1));
    for i in 0..n_zc {
        unsafe { *si.zeroCrossingIndex.add(i) = i as i64 };
    }
    si.states_left = calloc(n_states.max(1));
    si.states_right = calloc(n_states.max(1));

    si.realVarsOld = calloc(n_real.max(1));
    si.integerVarsOld = calloc(n_int.max(1));
    si.booleanVarsOld = calloc(n_bool.max(1));
    si.stringVarsOld = calloc(n_str.max(1));
    si.realVarsPre = calloc(n_real.max(1));
    si.integerVarsPre = calloc(n_int.max(1));
    si.booleanVarsPre = calloc(n_bool.max(1));
    si.stringVarsPre = calloc(n_str.max(1));

    si.realParameter = calloc((md.nParametersReal as usize).max(1));
    si.integerParameter = calloc((md.nParametersInteger as usize).max(1));
    si.booleanParameter = calloc((md.nParametersBoolean as usize).max(1));
    si.stringParameter = calloc((md.nParametersString as usize).max(1));

    si.inputVars = calloc((md.nInputVars as usize).max(1));
    si.outputVars = calloc((md.nOutputVars as usize).max(1));
    si.setcVars = calloc((md.nSetcVars as usize).max(1));
    si.datainputVars = calloc((md.ndataReconVars as usize).max(1));
    si.setbVars = calloc((md.nSetbVars as usize).max(1));

    let cb = unsafe { &*(*data).callback };
    if md.nMixedSystems > 0 {
        si.mixedSystemData = calloc(md.nMixedSystems as usize);
        if let Some(f) = cb.initialMixedSystem {
            unsafe { f(md.nMixedSystems as c_int, si.mixedSystemData) };
        }
    }
    if md.nLinearSystems > 0 {
        si.linearSystemData = calloc(md.nLinearSystems as usize);
        if let Some(f) = cb.initialLinearSystem {
            unsafe { f(md.nLinearSystems as c_int, si.linearSystemData) };
        }
    }
    if md.nNonLinearSystems > 0 {
        si.nonlinearSystemData = calloc(md.nNonLinearSystems as usize);
        if let Some(f) = cb.initialNonLinearSystem {
            unsafe { f(md.nNonLinearSystems as c_int, si.nonlinearSystemData) };
        }
    }
    if md.nStateSets > 0 {
        si.stateSetData = calloc(md.nStateSets as usize);
        if let Some(f) = cb.initializeStateSets {
            unsafe { f(md.nStateSets as c_int, si.stateSetData, data) };
        }
    }
    si.daeModeData = calloc(1);
    if let Some(f) = cb.initializeDAEmodeData {
        unsafe { f(data, si.daeModeData) };
    }
    si.inlineData = calloc(1);
    unsafe {
        (*si.inlineData).algVars = calloc(n_states.max(1));
        (*si.inlineData).algOldVars = calloc(n_states.max(1));
    }
    si.analyticJacobians = calloc((md.nJacobians as usize).max(1));
    md.modelDataXml.functionNames = core::ptr::null_mut();
    md.modelDataXml.equationInfo = core::ptr::null_mut();
    si.extObjs = calloc((md.nExtObjs as usize).max(1));

    si.chatteringInfo.numEventLimit = 100;
    si.chatteringInfo.lastSteps = calloc(si.chatteringInfo.numEventLimit as usize);
    si.chatteringInfo.lastTimes = calloc(si.chatteringInfo.numEventLimit as usize);
    si.chatteringInfo.currentIndex = 0;
    si.chatteringInfo.lastStepsNumStateEvents = 0;
    si.chatteringInfo.messageEmitted = 0;

    si.callStatistics.functionODE = 0;
    si.callStatistics.updateDiscreteSystem = 0;
    si.callStatistics.functionZeroCrossingsEquations = 0;
    si.callStatistics.functionZeroCrossings = 0;
    si.callStatistics.functionEvalDAE = 0;
    si.callStatistics.functionAlgebraics = 0;

    si.lambda = 1.0;
    si.terminal = 0;
    si.initial = 0;
    si.sampleActivated = 0;
    // The switches the generated equations branch on. The generated `main` leaves
    // `SIMULATION_INFO` on its stack uninitialised, so anything read before it is
    // written is whatever was there -- `noThrowAsserts` in particular turns every
    // failed `assert` into a silent note.
    si.solveContinuous = 0;
    si.noThrowDivZero = 0;
    si.noThrowAsserts = 0;
    si.needToReThrow = 0;
    si.discreteCall = 0;
    si.needToIterate = 0;
    si.simulationSuccess = 0;
    si.solverSteps = 0.0;
    si.homotopySteps = 0;
    si.currentJacobianEval = 0;
    si.currentContextOld = si.currentContext;
    si.timeValueOld = si.startTime;
    si.backupSolverData = core::ptr::null_mut();
    si.sensitivityMatrix = core::ptr::null_mut();
    si.sensitivityParList = core::ptr::null_mut();
    si.delayStructure = core::ptr::null_mut();
    si.external_input.active = 0;
    si.external_input.u = core::ptr::null_mut();
    si.external_input.t = core::ptr::null_mut();
    si.external_input.N = 0;
    si.external_input.n = 0;
    si.external_input.i = 0;

    // The systems' own allocation, once `analyticJacobians` exists for a torn
    // system's Jacobian to be initialized into.
    crate::systems::initialize_linear_systems(data, thread_data);
    crate::nls::initialize_nonlinear_systems(data, thread_data);
    crate::stateset::initialize_state_sets(data, thread_data);
    crate::mixed::initialize_mixed_systems(data, thread_data);

    let layout = layout_for(data, md, si, cb);
    let mut rt = RtData {
        data,
        thread_data,
        layout,
        owned: vec![0u8; (layout.total + RT_EXTRA) as usize],
        regions: Vec::new(),
        reals: (0, 0, core::ptr::null_mut()),
    };
    build_regions(&mut rt);
    rt
}

/// The layout the driver addresses this model through. Regions C stores itself
/// are mapped onto it; the rest is the driver's own and lives in `RtData::owned`.
fn layout_for(
    data: *mut DATA,
    md: &MODEL_DATA,
    _si: &SIMULATION_INFO,
    cb: &OpenModelicaGeneratedFunctionCallbacks,
) -> Layout {
    // C's `homotopySupport`: whether any nonlinear system carries the operator.
    // `callback->homotopyMethod` only says *which* continuation would run.
    let has_homotopy = (0..md.nNonLinearSystems as usize)
        .any(|i| unsafe { (*_si.nonlinearSystemData.add(i)).homotopySupport != 0 });
    let n_states = md.nStates as u32;
    let n_real_alg = (md.nVariablesReal - 2 * md.nStates).max(0) as u32;
    let dae = unsafe { md.nStateSets >= 0 && !_si.daeModeData.is_null() }
        .then(|| unsafe { &*_si.daeModeData });
    let (n_dae_res, n_dae_aux, n_dae_alg) = match dae {
        Some(d) if unsafe { crate::support::compiledInDAEMode } != 0 => {
            (d.nResidualVars as u32, d.nAuxiliaryVars as u32, d.nAlgebraicDAEVars as u32)
        }
        _ => (0, 0, 0),
    };
    Layout::new(
        n_states,
        n_real_alg,
        md.nParametersReal as u32,
        md.nVariablesInteger as u32,
        md.nParametersInteger as u32,
        md.nVariablesBoolean as u32,
        md.nParametersBoolean as u32,
        md.nVariablesString as u32,
        md.nParametersString as u32,
        md.nExtObjs as u32,
        md.nSamples as u32,
        md.nZeroCrossings as u32,
        md.nRelations as u32,
        // Each `$STATESET`'s Jacobian seeds and result rows, which the driver
        // addresses as memory. They are C's `JACOBIAN`'s own arrays; the region map
        // below points at them rather than copying.
        crate::stateset::scratch_words(data),
        0, // nonlinear-system Jacobian scratch: likewise, JACOBIAN
        md.nMathEvents as u32,
        0, // sensitivities
        n_dae_res,
        n_dae_aux,
        n_dae_alg,
        md.nBaseClocks as u32,
        0, // sub-clocks: filled once function_initSynchronous has run
        0, // linearization scratch: the C model's analyticJacobians
        0, // optimization attributes
        0, // bound-attribute log
        0, // removed initial equations
        unsafe { crate::support::compiledWithSymSolver } as u8,
        // `has_when` asks whether `functionAlgebraics` doubles as the discrete
        // update, which is a property of the wasm-jit codegen's split. A C model
        // keeps the `when`-equations in `functionDAE`, so its `functionAlgebraics`
        // is the plain algebraic pass a pre-event row wants evaluated.
        false,
        has_homotopy,
        openmodelica_sim_meta::HomotopyMethod::from_code(cb.homotopyMethod as u8),
        cb.functionInitialEquations_lambda0.is_some(),
        md.nDelayExpressions > 0 || md.nSpatialDistributions > 0,
        true,
    )
}

fn build_regions(rt: &mut RtData) {
    let l = rt.layout;
    let md = rt.model();
    let si = rt.info();
    let sd0 = rt.local(0);
    let sd1 = rt.local(1);
    let n_real = md.nVariablesReal as u32;
    let n_int = md.nVariablesInteger as u32;
    let n_bool = md.nVariablesBoolean as u32;

    let mut regions: Vec<Region> = Vec::new();
    let mut direct = |start: u32, bytes: u32, base: *mut c_void| {
        if bytes > 0 {
            regions.push(Region { start, end: start + bytes, backing: Backing::Direct(base as *mut u8) });
        }
    };

    // `time` is a field of SIMULATION_DATA, not part of `realVars`.
    direct(0, 8, &mut sd0.timeValue as *mut f64 as *mut c_void);
    direct(REAL_OFF, n_real * 8, sd0.realVars as *mut c_void);
    direct(l.rparam_off, md.nParametersReal as u32 * 8, si.realParameter as *mut c_void);
    direct(l.bool_off, n_bool * 4, sd0.booleanVars as *mut c_void);
    direct(l.bparam_off, md.nParametersBoolean as u32 * 4, si.booleanParameter as *mut c_void);
    direct(l.pre_real_off, n_real * 8, si.realVarsPre as *mut c_void);
    direct(l.pre_bool_off, n_bool * 4, si.booleanVarsPre as *mut c_void);
    direct(l.old_real_off, n_real * 8, sd1.realVars as *mut c_void);
    direct(l.terminate_off, 4, &raw mut crate::support::terminationTerminate as *mut c_void);
    direct(l.terminal_off, 4, &mut si.terminal as *mut c_int as *mut c_void);
    direct(l.initial_off, 4, &mut si.initial as *mut c_int as *mut c_void);
    direct(l.lambda_off, 8, &mut si.lambda as *mut f64 as *mut c_void);
    direct(l.sample_active_off, l.n_samples * 4, si.samples as *mut c_void);
    direct(l.zc_off, l.n_zc * 8, si.zeroCrossings as *mut c_void);
    direct(l.zc_pre_off, l.n_zc * 8, si.zeroCrossingsPre as *mut c_void);
    direct(l.zc_probe_off, l.n_zc * 8, si.zeroCrossingsBackup as *mut c_void);
    direct(l.relations_off, l.n_rel * 4, si.relations as *mut c_void);
    direct(l.stored_rel_off, l.n_rel * 4, si.storedRelations as *mut c_void);
    direct(l.relations_pre_off, l.n_rel * 4, si.relationsPre as *mut c_void);
    direct(l.mathevents_off, l.n_math * 8, si.mathEventsValuePre as *mut c_void);
    direct(l.zctol_off, 8, &raw mut crate::support::tolZC as *mut c_void);
    // Past the layout: C's `currentContext`, which the driver's `setContext`
    // writes and both `solve_linear_system` (`reuseMatrixJac`) and the nonlinear
    // solver's `updateInitialGuessDB` read.
    direct(l.total + CONTEXT_OFF, 4, &mut si.currentContext as *mut c_int as *mut c_void);
    for (off, bytes, base) in crate::stateset::regions(rt.data, &l) {
        direct(off, bytes, base);
    }
    if l.sym_solver > 0 {
        direct(l.inline_dt_off, 8, unsafe { &mut (*si.inlineData).dt } as *mut f64 as *mut c_void);
        direct(l.alg_old_off, l.n_states * 8, unsafe { (*si.inlineData).algOldVars } as *mut c_void);
    }
    if l.n_dae_res > 0 {
        direct(l.dae_res_off, l.n_dae_res * 8, unsafe { (*si.daeModeData).residualVars } as *mut c_void);
        direct(l.dae_aux_off, l.n_dae_aux * 8, unsafe { (*si.daeModeData).auxiliaryVars } as *mut c_void);
    }

    if n_int > 0 {
        regions.push(Region {
            start: l.int_off,
            end: l.int_off + n_int * 4,
            backing: Backing::WidenInt(sd0.integerVars),
        });
        regions.push(Region {
            start: l.pre_int_off,
            end: l.pre_int_off + n_int * 4,
            backing: Backing::WidenInt(si.integerVarsPre),
        });
    }
    if md.nParametersInteger > 0 {
        regions.push(Region {
            start: l.iparam_off,
            end: l.iparam_off + md.nParametersInteger as u32 * 4,
            backing: Backing::WidenInt(si.integerParameter),
        });
    }
    if l.n_samples > 0 {
        regions.push(Region {
            start: l.sample_off,
            end: l.sample_off + l.n_samples * 16,
            backing: Backing::Samples(md.samplesInfo),
        });
    }
    // String and external-object handles: a `modelica_string` is a pointer here
    // and a 4-byte handle in the flat layout, and the driver only ever moves them
    // around, so neither side reads the other's.
    for (start, count) in [
        (l.str_off, md.nVariablesString as u32),
        (l.sparam_off, md.nParametersString as u32),
        (l.eobj_off, md.nExtObjs as u32),
    ] {
        if count > 0 {
            regions.push(Region { start, end: start + count * 4, backing: Backing::Opaque });
        }
    }

    regions.sort_by_key(|r| r.start);
    rt.reals = (REAL_OFF, REAL_OFF + n_real * 8, sd0.realVars as *mut u8);
    rt.regions = regions;
}

/// `allocateArrayIndexMaps` + `computeVarIndices` + the reverse maps.
fn array_index_maps(md: &mut MODEL_DATA, si: &mut SIMULATION_INFO) {
    let sr = core::mem::size_of::<STATIC_REAL_DATA>();
    let sint = core::mem::size_of::<STATIC_INTEGER_DATA>();
    let sb = core::mem::size_of::<STATIC_BOOLEAN_DATA>();
    let ss = core::mem::size_of::<STATIC_STRING_DATA>();

    // C's `calculateAllScalarLength`: the integer parameters' start values are the
    // structural parameters a dimension may be given by, and they are known here.
    for (data, stride, count) in [
        (md.realVarsData.cast::<u8>(), sr, md.nVariablesRealArray),
        (md.integerVarsData.cast::<u8>(), sint, md.nVariablesIntegerArray),
        (md.booleanVarsData.cast::<u8>(), sb, md.nVariablesBooleanArray),
        (md.stringVarsData.cast::<u8>(), ss, md.nVariablesStringArray),
        (md.realParameterData.cast::<u8>(), sr, md.nParametersRealArray),
        (md.integerParameterData.cast::<u8>(), sint, md.nParametersIntegerArray),
        (md.booleanParameterData.cast::<u8>(), sb, md.nParametersBooleanArray),
        (md.stringParameterData.cast::<u8>(), ss, md.nParametersStringArray),
    ] {
        for i in 0..count as usize {
            let dim = unsafe { &mut *(data.add(i * stride) as *mut DIMENSION_INFO) };
            dim.scalar_length = calculate_length(dim, md);
        }
    }

    let index = |data: *const u8, stride: usize, n: i64| -> *mut usize {
        let out: *mut usize = calloc(n as usize + 1);
        let mut acc = 0usize;
        unsafe {
            *out = 0;
            for i in 0..n as usize {
                let dim = &*(data.add(i * stride) as *const DIMENSION_INFO);
                acc += dim.scalar_length;
                *out.add(i + 1) = acc;
            }
        }
        out
    };
    let identity = |n: i64| -> *mut usize {
        let out: *mut usize = calloc(n as usize + 1);
        for i in 0..=n as usize {
            unsafe { *out.add(i) = i };
        }
        out
    };

    si.realVarsIndex = index(md.realVarsData.cast(), sr, md.nVariablesRealArray);
    si.integerVarsIndex = index(md.integerVarsData.cast(), sint, md.nVariablesIntegerArray);
    si.booleanVarsIndex = index(md.booleanVarsData.cast(), sb, md.nVariablesBooleanArray);
    si.stringVarsIndex = index(md.stringVarsData.cast(), ss, md.nVariablesStringArray);
    si.realParamsIndex = index(md.realParameterData.cast(), sr, md.nParametersRealArray);
    si.integerParamsIndex = index(md.integerParameterData.cast(), sint, md.nParametersIntegerArray);
    si.booleanParamsIndex = index(md.booleanParameterData.cast(), sb, md.nParametersBooleanArray);
    si.stringParamsIndex = index(md.stringParameterData.cast(), ss, md.nParametersStringArray);
    si.realAliasIndex = identity(md.nAliasRealArray);
    si.integerAliasIndex = identity(md.nAliasIntegerArray);
    si.booleanAliasIndex = identity(md.nAliasBooleanArray);
    si.stringAliasIndex = identity(md.nAliasStringArray);

    let reverse = |vars_index: *const usize, n_array: i64| -> *mut array_index_t {
        let total = if n_array > 0 { unsafe { *vars_index.add(n_array as usize) } } else { 0 };
        let out: *mut array_index_t = calloc(total.max(1));
        for a in 0..n_array as usize {
            let (from, to) = unsafe { (*vars_index.add(a), *vars_index.add(a + 1)) };
            for (k, s) in (from..to).enumerate() {
                unsafe { *out.add(s) = array_index_t { array_idx: a, dim_idx: k } };
            }
        }
        out
    };
    si.realVarsReverseIndex = reverse(si.realVarsIndex, md.nVariablesRealArray);
    si.integerVarsReverseIndex = reverse(si.integerVarsIndex, md.nVariablesIntegerArray);
    si.booleanVarsReverseIndex = reverse(si.booleanVarsIndex, md.nVariablesBooleanArray);
    si.stringVarsReverseIndex = reverse(si.stringVarsIndex, md.nVariablesStringArray);
    si.realParamsReverseIndex = reverse(si.realParamsIndex, md.nParametersRealArray);
    si.integerParamsReverseIndex = reverse(si.integerParamsIndex, md.nParametersIntegerArray);
    si.booleanParamsReverseIndex = reverse(si.booleanParamsIndex, md.nParametersBooleanArray);
    si.stringParamsReverseIndex = reverse(si.stringParamsIndex, md.nParametersStringArray);
    si.realAliasReverseIndex = reverse(si.realAliasIndex, md.nAliasRealArray);
    si.integerAliasReverseIndex = reverse(si.integerAliasIndex, md.nAliasIntegerArray);
    si.booleanAliasReverseIndex = reverse(si.booleanAliasIndex, md.nAliasBooleanArray);
    si.stringAliasReverseIndex = reverse(si.stringAliasIndex, md.nAliasStringArray);
}

/// C's `calculateLength`: the product of the declared dimensions, a dimension
/// given by value reference resolved against the integer parameters.
fn calculate_length(dim: &mut DIMENSION_INFO, md: &MODEL_DATA) -> usize {
    if dim.numberOfDimensions == 0 || dim.dimensions.is_null() {
        return 1;
    }
    let mut length = 1usize;
    for k in 0..dim.numberOfDimensions {
        let d = unsafe { &mut *dim.dimensions.add(k) };
        if d.ty == 1 {
            let mut found = None;
            for i in 0..md.nParametersIntegerArray as usize {
                let p = unsafe { &*md.integerParameterData.add(i) };
                if p.info.id as i64 == d.valueReference {
                    found = Some(p.attribute.start);
                    break;
                }
            }
            d.start = found.unwrap_or(0);
        }
        length = length.saturating_mul(d.start.max(0) as usize);
    }
    length
}
