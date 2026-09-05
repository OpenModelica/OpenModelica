//! Model-agnostic FMI 3.0 Model-Exchange adapter.
//!
//! Compiled once to a `wasm32-unknown-unknown` dylink side module, then linked
//! (`wit_component::Linker`, see `CodegenWasmJit::link_fmu_component`) with a
//! per-model kernel module into an `fmi:fmi3/model-exchange-fmu` component. It
//! drives the model over the shared `SimData` linear-memory block, calling the
//! model's exported equation functions.
//!
//! Value references are `CodegenFMU3`'s (the same ones in the FMU's
//! `modelDescription.xml`); the emitter embeds the vr -> `SimData` slot table in
//! the metadata blob, since that scheme cannot be derived from the layout.
//!
//! The runtime is linked in only for the shared dlmalloc allocator + `rt_*`
//! primitives + linear memory: one heap for both the model's `rt_alloc` and
//! wit-bindgen's `cabi_realloc`.

#![no_std]

extern crate alloc;
// Linked in for its allocator, panic handler, memory and `rt_*` exports, which
// also satisfy the model's `env` imports.
extern crate openmodelica_codegen_wasm_jit_runtime;

use alloc::string::{String, ToString};
use alloc::vec;
use alloc::vec::Vec;
use core::cell::RefCell;

use openmodelica_sim_meta::driver::{
    self, dae_solve_explicit, eval_stage, event_update, run_initialization, set_param_overrides,
    set_zc_tolerance, Samples, SimEngine,
};
#[cfg(feature = "cs")]
use openmodelica_sim_meta::driver::{CsDefer, CsDriver, CsStep};
use openmodelica_sim_meta::{decode, omclog, simflags, FmiVr, Layout, Neg, WTy, REAL_OFF, TIME_OFF};

// ── Model kernel imports ─────────────────────────────────────────────────────
// `env` is the dylink convention: the Linker resolves these against the model
// library's exports, and the model's `rt_*` + memory against this adapter's.
#[link(wasm_import_module = "env")]
unsafe extern "C" {
    // The two-argument entry points, not yet guarded: a failed `assert()` in one of
    // these still traps.
    fn functionZeroCrossings(sim_data: u32, gout: u32);
    fn functionUpdateSynchronous(sim_data: u32, base_idx: u32);
    fn functionEquationsSynchronous(sim_data: u32, idx: u32);
    // `--daeMode`'s residual, exported (empty) by every model so this resolves.
    fn evaluateDAEResiduals(sim_data: u32, eval_stage: u32);
    fn om_meta_ptr() -> u32;
    fn om_meta_len() -> u32;
}

// The rest of the driver's entry points, imported only by the me_cs build, which
// also carries the model's own simulation runtime (`om:sim/simulation`). The
// emitter exports all of them from every model, so the link resolves regardless.
#[cfg(all(feature = "me", feature = "cs"))]
#[link(wasm_import_module = "env")]
unsafe extern "C" {
    fn simulate(sim_data: u32, start: f64, stop: f64, n_steps: u32) -> u32;
    #[link_name = "linearJacA$guard"]
    fn linearJacA_guard(sim_data: u32) -> u32;
    #[link_name = "linearJacB$guard"]
    fn linearJacB_guard(sim_data: u32) -> u32;
    #[link_name = "linearJacC$guard"]
    fn linearJacC_guard(sim_data: u32) -> u32;
    #[link_name = "linearJacD$guard"]
    fn linearJacD_guard(sim_data: u32) -> u32;
}

// Each entry point again, wrapped by the emitter in a `try_table` for the model-error
// tag: 1 means a failed `assert()` unwound out of it.
#[link(wasm_import_module = "env")]
unsafe extern "C" {
    #[link_name = "functionParameters$guard"]
    fn functionParameters_guard(sim_data: u32) -> u32;
    #[link_name = "functionInitStartValues$guard"]
    fn functionInitStartValues_guard(sim_data: u32) -> u32;
    #[link_name = "functionInitialEquations$guard"]
    fn functionInitialEquations_guard(sim_data: u32) -> u32;
    #[link_name = "functionInitialEquations_lambda0$guard"]
    fn functionInitialEquations_lambda0_guard(sim_data: u32) -> u32;
    #[link_name = "functionODE$guard"]
    fn functionODE_guard(sim_data: u32) -> u32;
    #[link_name = "functionAlgebraics$guard"]
    fn functionAlgebraics_guard(sim_data: u32) -> u32;
    #[link_name = "functionOutputs$guard"]
    fn functionOutputs_guard(sim_data: u32) -> u32;
    #[link_name = "functionStateSetJacobians$guard"]
    fn functionStateSetJacobians_guard(sim_data: u32) -> u32;
    #[link_name = "functionZeroCrossingsEquations$guard"]
    fn functionZeroCrossingsEquations_guard(sim_data: u32) -> u32;
    #[link_name = "functionUpdateRelations$guard"]
    fn functionUpdateRelations_guard(sim_data: u32) -> u32;
    #[link_name = "functionCheckAsserts$guard"]
    fn functionCheckAsserts_guard(sim_data: u32) -> u32;
    #[link_name = "functionStoreDelayed$guard"]
    fn functionStoreDelayed_guard(sim_data: u32) -> u32;
    #[link_name = "functionInitDelay$guard"]
    fn functionInitDelay_guard(sim_data: u32) -> u32;
    #[link_name = "functionStoreSpatialDistribution$guard"]
    fn functionStoreSpatialDistribution_guard(sim_data: u32) -> u32;
    #[link_name = "functionInitSpatialDistribution$guard"]
    fn functionInitSpatialDistribution_guard(sim_data: u32) -> u32;
    #[link_name = "functionUpdateBoundParameters$guard"]
    fn functionUpdateBoundParameters_guard(sim_data: u32) -> u32;
    #[link_name = "functionUpdateBoundVariableAttributes$guard"]
    fn functionUpdateBoundVariableAttributes_guard(sim_data: u32) -> u32;
    #[link_name = "functionRemovedInitialEquations$guard"]
    fn functionRemovedInitialEquations_guard(sim_data: u32) -> u32;
    #[link_name = "functionJacA_constantEqns$guard"]
    fn functionJacA_constantEqns_guard(sim_data: u32) -> u32;
    #[link_name = "functionJacA_column$guard"]
    fn functionJacA_column_guard(sim_data: u32) -> u32;
    #[link_name = "initSample$guard"]
    fn initSample_guard(sim_data: u32) -> u32;
    #[link_name = "functionInitSynchronous$guard"]
    fn functionInitSynchronous_guard(sim_data: u32) -> u32;
    #[link_name = "callExternalObjectDestructors$guard"]
    fn callExternalObjectDestructors_guard(sim_data: u32) -> u32;
    #[link_name = "symbolicInlineSystem$guard"]
    fn symbolicInlineSystem_guard(sim_data: u32) -> u32;
    #[link_name = "functionDAE$guard"]
    fn functionDAE_guard(sim_data: u32) -> u32;
}

// ── Messages ─────────────────────────────────────────────────────────────────
// Two channels, as C's FMU has: `messageText` prints the `-lv` streams to stdout,
// and the `log-message` callback (`fmi3LogMessage`) carries what
// `fmu3_model_interface.c` sends through `FILTERED_LOG`.

/// The FMU's stdout, which for a component is WASI's: `fd_write` on the preview1
/// descriptor, which the adapter `CodegenWasmJit::link_fmu_component` composes in
/// bridges to `wasi:cli/stdout`.
mod stdio {
    const STDOUT: i32 = 1;
    const STDERR: i32 = 2;

    #[repr(C)]
    struct Ciovec {
        buf: *const u8,
        len: usize,
    }

    #[link(wasm_import_module = "wasi_snapshot_preview1")]
    unsafe extern "C" {
        #[link_name = "fd_write"]
        fn fd_write(fd: i32, iovs: *const Ciovec, iovs_len: usize, nwritten: *mut usize) -> i32;
    }

    fn write(fd: i32, bytes: &[u8]) {
        let mut rest = bytes;
        while !rest.is_empty() {
            let iov = Ciovec { buf: rest.as_ptr(), len: rest.len() };
            let mut n = 0usize;
            let rc = unsafe { fd_write(fd, &iov, 1, &mut n) };
            if rc != 0 || n == 0 || n > rest.len() {
                return;
            }
            rest = &rest[n..];
        }
    }

    /// C's `printf` + `fflush(NULL)`: written whole and now, so it interleaves
    /// with the importer's own output in the order the two produced it.
    pub fn print(bytes: &[u8]) {
        write(STDOUT, bytes);
    }

    /// The same for fd 2, where C's `omc_assert_fmi` writes a thread-less assertion.
    pub fn stderr(bytes: &[u8]) {
        write(STDERR, bytes);
    }
}

/// C's `logCategoriesNames`, which is also what `CodegenFMU3` declares in
/// `modelDescription.xml`. `logFmi3Call` is unused: the adapter logs no call trace.
const CATEGORIES: [&str; 11] = [
    "logEvents",
    "logSingularLinearSystems",
    "logNonlinearSystems",
    "logDynamicStateSelection",
    "logStatusWarning",
    "logStatusDiscard",
    "logStatusError",
    "logStatusFatal",
    "logStatusPending",
    "logAll",
    "logFmi3Call",
];
const CAT_WARNING: u32 = 4;
const CAT_ERROR: u32 = 6;
const CAT_ALL: u32 = 9;

struct Logger {
    /// `instanceName`, which the callback reports alongside the message.
    name: String,
    /// Bit per [`CATEGORIES`] index; empty until `loggingOn`.
    cats: u32,
}

static mut LOGGER: Logger = Logger { name: String::new(), cats: 0 };

/// The sink is a bare `fn(&str)`, so its context is a static (wasm, single-threaded).
fn logger() -> &'static mut Logger {
    unsafe { &mut *core::ptr::addr_of_mut!(LOGGER) }
}

#[cfg(not(feature = "capi"))]
fn log_raw(status: Status, cat: u32, msg: &str) {
    let l = logger();
    fmi::fmi3::callbacks::log_message(&l.name, status, CATEGORIES[cat as usize], msg.trim_end_matches('\n'));
}

/// Linked as a core module there is no importer to call back into, so what the
/// component sends through `fmi3LogMessage` goes where its `-lv` streams already
/// go: the FMU's stdout, which the host captures.
#[cfg(feature = "capi")]
fn log_raw(status: Status, cat: u32, msg: &str) {
    let _ = status;
    let l = logger();
    stdio::print(
        alloc::format!("{}: {}: {}\n", l.name, CATEGORIES[cat as usize], msg.trim_end_matches('\n')).as_bytes(),
    );
}

/// [`Engine::call1`] was asked for a model function this adapter does not import.
const UNKNOWN_MODEL_FN: &str = "fmi3-me: unknown model function";

/// A runtime/driver failure. The FMI status alone tells the importer nothing, and
/// C's FMUs report the reason through the logger, so say it before failing.
///
/// Those three have logged their own reason already (`LOG_ASSERT` / `LOG_INIT` /
/// `model terminate`), as the standalone driver's reporting also assumes.
fn err_status(msg: &str) -> Status {
    if msg != driver::ASSERT_ERR && msg != driver::INIT_FAILED_ERR && msg != driver::SOLVER_FAILED_ERR
    {
        fmi_log(Status::Error, CAT_ERROR, msg);
    }
    Status::Error
}

/// C's `FILTERED_LOG` / `isCategoryLogged`.
fn fmi_log(status: Status, cat: u32, msg: &str) {
    let cats = logger().cats;
    if cats & (1 << cat) != 0 || cats & (1 << CAT_ALL) != 0 {
        log_raw(status, cat, msg);
    }
}

/// The runtime's and driver's log lines. C's `messageText` prints every type with
/// `printf`, so they go to stdout with the stream and type in the header, not to
/// the logger.
fn log_sink(_stream: omclog::Stream, _ty: omclog::LogType, s: &str) {
    stdio::print(s.as_bytes());
}

/// C's `omcInstantiate`: every category follows `loggingOn` until
/// `set-debug-logging` picks specific ones.
fn init_logging(name: String, logging_on: bool) {
    let l = logger();
    l.name = name;
    l.cats = if logging_on { !0 } else { 0 };
    driver::set_log_sink(log_sink);
    driver::set_terminate_reporter(terminate_fmi);
    omclog::set_mask(omclog::FMU_STREAMS);
}

/// C's `omc_terminate_fmi`, which `fmi2Instantiate` installs: stderr, not the
/// driver's `LOG_STDOUT` notice. The importer reports the terminate itself.
fn terminate_fmi(pos: &str, msg: &str) {
    stdio::stderr(alloc::format!("{pos}Modelica Terminate: {msg}!\n").as_bytes());
}

/// The runtime `String` behind a handle, empty for the null handle.
fn rt_string(handle: i32) -> String {
    use openmodelica_codegen_wasm_jit_runtime as rt;
    let h = handle as u32;
    if h == 0 {
        return String::new();
    }
    let len = rt::rt_str_len(h) as usize;
    let bytes = unsafe { core::slice::from_raw_parts(rt::rt_str_data(h) as *const u8, len) };
    String::from_utf8_lossy(bytes).into_owned()
}

/// C's `omc_assert_fmi_common`: the source position, then the message.
fn assert_message(msg: i32, file: i32, sline: i32) -> String {
    let msg = rt_string(msg);
    let file = rt_string(file);
    if file.is_empty() || sline == 0 {
        return msg;
    }
    alloc::format!("{file}:{sline}: {msg}")
}

/// C's FMU logs the violation then `longjmp`s out of the FMI call, which returns
/// `fmi3Error` with the instance usable — so answer that the code must unwind.
/// `cond` picks which C implementation is mirrored: `fmi2Instantiate` swaps in
/// `omc_assert_fmi` only for the `FUNCTION_CONTEXT` pointer, while an equation
/// `assert()` stays on `omc_assert_simulation_withEquationIndexes`'s `LOG_ASSERT`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_assert(
    msg: i32,
    file: i32,
    sline: i32,
    scol: i32,
    eline: i32,
    ecol: i32,
    read_only: i32,
    cond: i32,
    initial: i32,
    sim_data: i32,
) -> i32 {
    if cond != 0 {
        let info = driver::AssertInfo {
            msg: rt_string(msg),
            file: rt_string(file),
            read_only: read_only != 0,
            line_start: sline,
            col_start: scol,
            line_end: eline,
            col_end: ecol,
        };
        let time = driver::read_f64(&Engine, sim_data as u32 + TIME_OFF).unwrap_or(0.0);
        driver::log_assert_block(&info, &rt_string(cond), time, initial != 0);
        return 1;
    }
    fmi_log(Status::Error, CAT_ERROR, &assert_message(msg, file, sline));
    1
}

/// Warning-level assertion: non-fatal, so continue (C's `omc_assert_fmi_warning`).
#[unsafe(no_mangle)]
pub extern "C" fn rt_assert_warning(
    _cond: i32,
    msg: i32,
    file: i32,
    sline: i32,
    _scol: i32,
    _eline: i32,
    _ecol: i32,
    _read_only: i32,
    _initial: i32,
) {
    fmi_log(Status::Warning, CAT_WARNING, &assert_message(msg, file, sline));
}

/// The `print` builtin: model output, which C sends to stdout unformatted — not a
/// `-lv` stream.
#[unsafe(no_mangle)]
pub extern "C" fn rt_print(str: i32) {
    stdio::print(rt_string(str).as_bytes());
}

/// Where the runtime's `omc_assert` writes: it has no WASI of its own.
#[unsafe(no_mangle)]
pub extern "C" fn rt_stderr_write(ptr: *const u8, len: usize) {
    let bytes = unsafe { core::slice::from_raw_parts(ptr, len) };
    stdio::stderr(bytes);
}

/// Per-row assert formatting: the FMI master steps the model instead of the emitted
/// `simulate` loop that calls this.
#[unsafe(no_mangle)]
pub extern "C" fn rt_row_asserts(_sim_data: i32, _warn: i32) -> i32 {
    0
}

// ── SimEngine over the merged module's shared linear memory ──────────────────
struct Engine;

impl SimEngine for Engine {
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> driver::Result<()> {
        let src = unsafe { core::slice::from_raw_parts(addr as *const u8, buf.len()) };
        buf.copy_from_slice(src);
        Ok(())
    }
    fn write_bytes(&mut self, addr: u32, buf: &[u8]) -> driver::Result<()> {
        let dst = unsafe { core::slice::from_raw_parts_mut(addr as *mut u8, buf.len()) };
        dst.copy_from_slice(buf);
        Ok(())
    }
    fn set_string(&mut self, addr: u32, bytes: &[u8]) -> driver::Result<()> {
        openmodelica_codegen_wasm_jit_runtime::set_string_slot(addr, bytes);
        Ok(())
    }
    fn call1_raw(&mut self, name: &str, arg: u32) -> driver::Result<()> {
        let threw = unsafe {
            match name {
                "functionParameters" => functionParameters_guard(arg),
                "functionInitStartValues" => functionInitStartValues_guard(arg),
                "functionInitialEquations" => functionInitialEquations_guard(arg),
                "functionInitialEquations_lambda0" => functionInitialEquations_lambda0_guard(arg),
                "functionODE" => functionODE_guard(arg),
                "functionAlgebraics" => functionAlgebraics_guard(arg),
                "functionOutputs" => functionOutputs_guard(arg),
                "functionStateSetJacobians" => functionStateSetJacobians_guard(arg),
                "functionZeroCrossingsEquations" => functionZeroCrossingsEquations_guard(arg),
                "functionUpdateRelations" => functionUpdateRelations_guard(arg),
                "functionCheckAsserts" => functionCheckAsserts_guard(arg),
                "functionStoreDelayed" => functionStoreDelayed_guard(arg),
                "functionInitDelay" => functionInitDelay_guard(arg),
                "functionStoreSpatialDistribution" => functionStoreSpatialDistribution_guard(arg),
                "functionInitSpatialDistribution" => functionInitSpatialDistribution_guard(arg),
                "functionUpdateBoundParameters" => functionUpdateBoundParameters_guard(arg),
                "functionUpdateBoundVariableAttributes" => functionUpdateBoundVariableAttributes_guard(arg),
                "functionRemovedInitialEquations" => functionRemovedInitialEquations_guard(arg),
                "functionJacA_constantEqns" => functionJacA_constantEqns_guard(arg),
                "functionJacA_column" => functionJacA_column_guard(arg),
                "initSample" => initSample_guard(arg),
                "functionInitSynchronous" => functionInitSynchronous_guard(arg),
                "callExternalObjectDestructors" => callExternalObjectDestructors_guard(arg),
                "symbolicInlineSystem" => symbolicInlineSystem_guard(arg),
                "functionDAE" => functionDAE_guard(arg),
                #[cfg(all(feature = "me", feature = "cs"))]
                "linearJacA" => linearJacA_guard(arg),
                #[cfg(all(feature = "me", feature = "cs"))]
                "linearJacB" => linearJacB_guard(arg),
                #[cfg(all(feature = "me", feature = "cs"))]
                "linearJacC" => linearJacC_guard(arg),
                #[cfg(all(feature = "me", feature = "cs"))]
                "linearJacD" => linearJacD_guard(arg),
                _ => return Err(UNKNOWN_MODEL_FN),
            }
        };
        // The assertion was logged where it fired; the caller turns this into the
        // status the FMI call answers with, leaving the instance usable.
        if threw != 0 {
            return Err(driver::ASSERT_ERR);
        }
        Ok(())
    }

    fn call2_raw(&mut self, name: &str, a: u32, b: u32) -> driver::Result<()> {
        unsafe {
            match name {
                driver::MODEL_FN_ZC => functionZeroCrossings(a, b),
                driver::MODEL_FN_UPDATE_SYNC => functionUpdateSynchronous(a, b),
                driver::MODEL_FN_EQS_SYNC => functionEquationsSynchronous(a, b),
                driver::MODEL_FN_DAE => evaluateDAEResiduals(a, b),
                _ => return Err(UNKNOWN_MODEL_FN),
            }
        }
        Ok(())
    }
    /// A name this adapter does not import is a function the model does not have.
    fn call1_if_present_raw(&mut self, name: &str, arg: u32) -> driver::Result<()> {
        match self.call1_raw(name, arg) {
            Err(UNKNOWN_MODEL_FN) => Ok(()),
            r => r,
        }
    }
    #[cfg(all(feature = "me", feature = "cs"))]
    fn call_simulate(&mut self, s: u32, a: f64, b: f64, n: u32) -> driver::Result<u32> {
        Ok(unsafe { simulate(s, a, b, n) })
    }
    /// The FMI interfaces step the model themselves; only the simulation runtime
    /// the me_cs build carries takes the emitted `simulate` loop.
    #[cfg(not(all(feature = "me", feature = "cs")))]
    fn call_simulate(&mut self, _s: u32, _a: f64, _b: f64, _n: u32) -> driver::Result<u32> {
        Err("fmi3-me: simulate not used")
    }
    fn take_pending_assert(&mut self) -> Option<[i32; 9]> {
        None
    }
    fn take_pending_reinits(&mut self) -> Vec<(u32, f64)> {
        openmodelica_codegen_wasm_jit_runtime::take_reinit_notes()
    }
    fn clean_nls_history(&mut self, time: f64) {
        openmodelica_codegen_wasm_jit_runtime::rt_nls_clean_history(time);
    }
    // The adapter, the runtime and the model kernel share one linear memory.
    fn context_addr(&mut self) -> u32 {
        openmodelica_codegen_wasm_jit_runtime::rt_context_addr()
    }
    fn error_stage_addr(&mut self) -> u32 {
        openmodelica_codegen_wasm_jit_runtime::rt_error_stage_addr()
    }
    fn no_throw_div_zero_addr(&mut self) -> u32 {
        openmodelica_codegen_wasm_jit_runtime::rt_no_throw_div_zero_addr()
    }
    // `+profiling`'s clocks: the artifact links the model and the runtime into one
    // module, so they are this module's own.
    fn prof_row(&mut self) -> u32 {
        openmodelica_codegen_wasm_jit_runtime::prof::rt_prof_row()
    }
    fn prof_dump(&mut self) -> u32 {
        openmodelica_codegen_wasm_jit_runtime::prof::rt_prof_dump()
    }
    fn prof_clear(&mut self) {
        openmodelica_codegen_wasm_jit_runtime::prof::rt_prof_clear(0);
    }
    fn prof_init(&mut self, n: u32) {
        openmodelica_codegen_wasm_jit_runtime::prof::rt_prof_init(n);
    }
}

// ── Value references ─────────────────────────────────────────────────────────
/// vr -> `SimData` slot, agreeing with the `modelDescription.xml` `CodegenFMU3`
/// generated for this FMU. The blob carries the table sorted; instantiation
/// expands it into a direct index, the value references being dense.
struct Vrs {
    by_vr: Vec<Option<FmiVr>>,
}

impl Vrs {
    fn new(table: Vec<FmiVr>) -> Self {
        let max = table.last().map_or(0, |e| e.vr as usize);
        let mut by_vr = vec![None; max + 1];
        for e in table {
            by_vr[e.vr as usize] = Some(e);
        }
        Vrs { by_vr }
    }

    /// `None` for a vr with no `SimData` slot (a String, an external object).
    fn resolve(&self, vr: u32) -> Option<FmiVr> {
        *self.by_vr.get(vr as usize)?
    }

    /// Each vr followed by the rest of its array's block.
    fn expand(&self, vrs: &[u32]) -> Vec<u32> {
        let mut out = Vec::with_capacity(vrs.len());
        for &vr in vrs {
            let len = self.resolve(vr).map_or(1, |e| e.len.max(1));
            out.extend(vr..vr + len);
        }
        out
    }
}

// ── Instance state ───────────────────────────────────────────────────────────
/// C's `ModelState`, as far as the component acts on it.
#[derive(Clone, Copy, PartialEq)]
enum Mode {
    Instantiated,
    Init,
    Ready,
}

struct MeState {
    sim_data: u32,
    layout: Layout,
    /// The whole metadata blob: the start state comes from it at instantiate, and
    /// CS builds its driver from the solver settings, state sets and sparsity.
    meta: openmodelica_sim_meta::SimMeta,
    /// Built on exit-initialization-mode, once the model is initialized.
    #[cfg(feature = "cs")]
    cs: Option<CsDriver>,
    /// `eventModeUsed` from instantiation: `do-step` stops at and reports each event
    /// for the master, rather than handling it internally.
    /// FMI's `eventModeUsed`/`earlyReturnAllowed`, folded into who resolves an
    /// event and where the step may stop.
    #[cfg(feature = "cs")]
    defer: openmodelica_sim_meta::driver::CsDefer,
    vrs: Vrs,
    mode: Mode,
    /// C's `model_state_me_continuous_time_mode`.
    continuous_time: bool,
    /// fmi-ls-dae: the `EnableDAEParameter` structural parameter's value reference (0 when
    /// the model has no DAE formulation), whether it is set, and whether the
    /// importer is in Configuration Mode, the only place it may be set.
    dae_enable_vr: u32,
    dae_mode: bool,
    configuring: bool,
    /// Set when the embedded solver has just left consistent derivatives and
    /// algebraic unknowns behind, so the refresh below need not solve for them
    /// again. Only a Co-Simulation step can promise that; any set clears it.
    dae_current: bool,
    /// C's `_need_update`, consumed by `update_if_needed`.
    need_update: bool,
    /// Every set made before Initialization Mode is left, applied by
    /// `run_initialization`: states as start overrides (see `FmiVr::start_off`),
    /// everything else as parameters. C's `setReal` writes the `start` attribute
    /// in both states, and `fmi2EnterInitializationMode` snapshots the live values
    /// into it, so a set made before Initialization Mode counts too.
    init_overrides: Vec<(u32, WTy, f64)>,
    init_start_overrides: Vec<(u32, WTy, f64)>,
    /// String parameter sets, applied after `run_initialization` so init equations
    /// don't clobber them (cf `init_overrides`).
    init_string_overrides: Vec<(u32, String)>,
    /// The ODE Jacobian for the point the model holds, and whether it is still
    /// the point it was assembled at.
    jacobian_cache: Vec<f64>,
    jacobian_valid: bool,
    /// C's `stateSetData`, seeded by the initial solve.
    dss: driver::StateSelection,
    /// Sample schedule, loaded once the model's `initSample` has run.
    samples: Option<Samples>,
    /// Synchronous clocks (C's `initSynchronous`), for a model that has any.
    sync: Option<openmodelica_sim_meta::sync::Sync>,
}

impl MeState {
    fn read_f64(&self, off: u32) -> f64 {
        driver::read_f64(&Engine, self.sim_data + off).unwrap_or(0.0)
    }
    fn write_f64(&self, off: u32, v: f64) {
        let mut e = Engine;
        let _ = driver::write_f64(&mut e, self.sim_data + off, v);
    }
    fn read_i32(&self, off: u32) -> i32 {
        driver::read_i32(&Engine, self.sim_data + off).unwrap_or(0)
    }
    fn write_i32(&self, off: u32, v: i32) {
        let mut e = Engine;
        let _ = e.write_bytes(self.sim_data + off, &v.to_le_bytes());
    }
    /// Read the runtime `String` referenced by the i32 handle in slot `off`.
    fn read_string(&self, off: u32) -> String {
        rt_string(self.read_i32(off))
    }
    /// Store `s` as a fresh runtime `String` handle in slot `off`, releasing the
    /// handle it replaces (a no-op on the null handle).
    fn write_string(&self, off: u32, s: &str) {
        use openmodelica_codegen_wasm_jit_runtime as rt;
        let old = self.read_i32(off) as u32;
        let bytes = s.as_bytes();
        let h = rt::rt_str_new(bytes.len() as u32);
        unsafe {
            core::ptr::copy_nonoverlapping(bytes.as_ptr(), rt::rt_str_data(h) as *mut u8, bytes.len());
        }
        self.write_i32(off, h as i32);
        rt::rt_release(old);
    }
    /// C's `fmi2Instantiate`/`fmi2Reset`: the `start` attributes, readable before
    /// the importer leaves Initialization Mode. A failure here is left to the
    /// initial solve, which is where it is reported.
    fn seed_start_state(&self) {
        let mut e = Engine;
        let _ = driver::seed_start_state(&mut e, self.sim_data, &self.meta);
    }

    /// `functionOutputs`, not `functionAlgebraics`: a getter runs no discrete update.
    ///
    /// A `--daeMode` model has neither: its continuous equations are the residual
    /// `F(t, x, x', z) = 0`. In DAE mode the importer has set `x'` and `z` and reads
    /// `F` back; in ODE mode the model owes it `x'` and `z`, solved for here.
    fn eval(&self) -> driver::Result<()> {
        let mut e = Engine;
        if self.layout.dae_mode() {
            if !self.dae_mode && !self.dae_current {
                let dae = self.meta.dae.as_ref().ok_or("fmi3: DAE-mode model without DAE metadata")?;
                dae_solve_explicit(&mut e, self.sim_data, &self.layout, dae)?;
            }
            return e.call2(
                driver::MODEL_FN_DAE,
                self.sim_data,
                eval_stage::DYNAMIC | eval_stage::ALGEBRAIC,
            );
        }
        e.call1("functionODE", self.sim_data)?;
        e.call1("functionOutputs", self.sim_data)
    }

    /// `functionODE` for the derivatives and the event indicators: a `--daeMode`
    /// model has no such partial evaluation, so it evaluates whole.
    fn eval_ode(&mut self) -> Result<(), Status> {
        if self.layout.dae_mode() {
            return self.update_if_needed();
        }
        self.evaluate(|m| Engine.call1("functionODE", m.sim_data))
    }

    /// C's try block around one FMI call: a model error or an unsolved nonlinear
    /// system is the master's to retry in Continuous Time Mode (`fmi3Discard`,
    /// C's `IRES = -1`) and fails the call anywhere else.
    fn evaluate(&mut self, f: impl FnOnce(&mut Self) -> driver::Result<()>) -> Result<(), Status> {
        let mut e = Engine;
        self.write_i32(self.layout.nls_fail_off, 0);
        let region = self.continuous_time.then(|| driver::open_fmi_call_region(&mut e));
        let run = f(self);
        let absorbed = region.is_some_and(|save| driver::close_fmi_call_region(&mut e, save));
        let unsolved = driver::take_nls_failure(&mut e, self.sim_data, &self.layout);
        run.map_err(err_status)?;
        if absorbed || unsolved {
            return Err(if self.continuous_time { Status::Discard } else { Status::Error });
        }
        Ok(())
    }

    /// The state a value reference reads, when it is one of the continuous
    /// states (or one of their derivatives): `SimData` keeps the states first
    /// and their derivatives right after.
    fn state_index(&self, vr: u32) -> Option<usize> {
        let off = self.vrs.resolve(vr).filter(|v| v.negate == Neg::None)?.off;
        let i = off.checked_sub(REAL_OFF)? / 8;
        (i < self.layout.n_states).then_some(i as usize)
    }

    fn derivative_index(&self, vr: u32) -> Option<usize> {
        let off = self.vrs.resolve(vr).filter(|v| v.negate == Neg::None)?.off;
        let i = off.checked_sub(REAL_OFF)? / 8;
        (i >= self.layout.n_states && i < 2 * self.layout.n_states)
            .then_some((i - self.layout.n_states) as usize)
    }

    /// The ODE Jacobian at the point the model currently holds, column-major.
    /// Assembled once per point: the states and the time both invalidate it, so
    /// a master asking for one seed after another pays for a single assembly.
    fn jacobian(&mut self, n: usize) -> Result<&[f64], Status> {
        if self.jacobian_valid {
            return Ok(&self.jacobian_cache);
        }
        let jac = self.meta.jac_a.as_ref().ok_or(Status::Error)?;
        if jac.sym.is_none() || jac.n as usize != n {
            return Err(Status::Error);
        }
        self.jacobian_cache.clear();
        self.jacobian_cache.resize(n * n, 0.0);
        let mut e = Engine;
        let matrix = &mut self.jacobian_cache;
        driver::eval_sym_jacobian(&mut e, self.sim_data, jac, 0, true, &mut |row, col, _, v| {
            matrix[col * n + row] = v;
        })
        .map_err(|_| Status::Error)?;
        self.jacobian_valid = true;
        Ok(&self.jacobian_cache)
    }

    /// C's `updateIfNeeded`. In Initialization Mode the update is the initial
    /// solve, with the sets made so far as start values.
    fn update_if_needed(&mut self) -> Result<(), Status> {
        if !self.need_update {
            return Ok(());
        }
        // The point moved, so a Jacobian assembled at the old one is stale.
        self.jacobian_valid = false;
        if self.mode == Mode::Init {
            self.run_init().map_err(err_status)?;
        } else {
            self.evaluate(|m| m.eval())?;
        }
        self.need_update = false;
        Ok(())
    }

    /// C's `initialization()`, repeatable: the overrides stay, so the importer can
    /// keep setting and get a fresh solve each time.
    fn run_init(&mut self) -> driver::Result<()> {
        set_param_overrides(self.init_overrides.clone(), self.init_start_overrides.clone(), Vec::new());
        let mut e = Engine;
        let start_time = self.read_f64(TIME_OFF);
        // No `-csvInput` on the FMI path: the importer drives the inputs.
        run_initialization(&mut e, self.sim_data, &self.layout, &[], start_time)?;
        self.dss = driver::StateSelection::initial(&mut e, self.sim_data, &self.meta)?;
        // C's `initializeModel` runs `initSynchronous` too.
        if !self.meta.clocks.is_empty() {
            let mut sync = openmodelica_sim_meta::sync::Sync::new(&mut e, &self.meta, self.sim_data)?;
            sync.take_fired(&mut e, start_time)?;
            self.sync = Some(sync);
        }
        // After the init equations, so they land in the slots last.
        for (off, val) in core::mem::take(&mut self.init_string_overrides) {
            self.write_string(off, &val);
        }
        Ok(())
    }

    /// C's `setReal` writing the `start` attribute. Last write per slot wins, so a
    /// master iterating an algebraic loop does not grow the list.
    fn record_override(&mut self, off: u32, wty: WTy, val: f64, is_start: bool) {
        let list = if is_start { &mut self.init_start_overrides } else { &mut self.init_overrides };
        match list.iter_mut().find(|(o, _, _)| *o == off) {
            Some(e) => e.2 = val,
            None => list.push((off, wty, val)),
        }
    }
}

// ── WIT bindings ────────────────────────────────────────────────────────────
// One crate, three FMU types selected by the `me`/`cs` features: `me` → Model
// Exchange, `cs` → Co-Simulation, both → a single me_cs component. All builds
// share the state, the vr table and the 54 common resource methods.
#[cfg(all(feature = "me", not(feature = "cs")))]
wit_bindgen::generate!({
    world: "model-exchange-fmu",
    path: "wit",
    std_feature,
});
#[cfg(all(feature = "cs", not(feature = "me")))]
wit_bindgen::generate!({
    world: "co-simulation-fmu",
    path: "wit",
    std_feature,
});
#[cfg(all(feature = "me", feature = "cs"))]
wit_bindgen::generate!({
    world: "model-exchange-and-co-simulation-fmu",
    path: "wit",
    std_feature,
    // The OpenModelica interfaces are ours; the FMI ones come from the world's
    // own package.
    with: { "om:sim/simulation@0.1.0": generate, "om:ext/native@0.1.0": generate },
});

use exports::fmi::fmi3::common::Guest as CommonGuest;
#[cfg(feature = "me")]
use exports::fmi::fmi3::model_exchange::{
    CompletedStepResult, Guest as MeGuest, GuestModelExchangeInstance, ModelExchangeInstance,
};
#[cfg(feature = "cs")]
use exports::fmi::fmi3::co_simulation::{
    CoSimulationInstance, DoStepResult, Guest as CsGuest, GuestCoSimulationInstance,
};
// The shared types (`use types.{…}` in both interfaces) are one type; import them
// from whichever interface this build exports, preferring model-exchange.
#[cfg(feature = "me")]
use exports::fmi::fmi3::model_exchange::{
    DiscreteStatesInfo, IntervalFraction, IntervalQualifier, Status, VariableDependency,
};
#[cfg(all(feature = "cs", not(feature = "me")))]
use exports::fmi::fmi3::co_simulation::{
    DiscreteStatesInfo, IntervalFraction, IntervalQualifier, Status, VariableDependency,
};

pub struct Instance {
    st: RefCell<MeState>,
}

/// Allocate and zero the model's `SimData` and build the instance state. Shared by
/// both worlds' instantiate.
/// The simulation flags the export hard-coded into the metadata. The export linked
/// exactly the libraries these reach, so a rejection here means the two disagree and
/// the instance must not come up quietly using another solver.
fn apply_baked_solver_flags(flags: &str) -> Option<()> {
    if flags.is_empty() {
        return Some(());
    }
    let argv: Vec<String> = core::iter::once("model".to_string())
        .chain(flags.split_whitespace().map(str::to_string))
        .collect();
    // An FMU writes no result file; `-variableFilter` is the importer's.
    let cap = simflags::Capabilities {
        variable_filter: true,
        ..openmodelica_codegen_wasm_jit_runtime::sim_capabilities()
    };
    let parsed = simflags::parse(&argv)
        .and_then(|f| {
            simflags::check(&f, cap)?;
            Ok(f)
        })
        .map_err(|e| {
            omclog::error!(omclog::ASSERT, false, "this FMU was exported with `{flags}`: {e}")
        })
        .ok()?;
    openmodelica_codegen_wasm_jit_runtime::apply_sim_flags(&parsed);
    simflags::print_notices(&parsed);
    let streams = parsed.log_mask & !omclog::ALWAYS_ON;
    simflags::set_flags(parsed);
    omclog::set_mask(omclog::FMU_STREAMS | streams);
    Some(())
}

fn new_state() -> Option<MeState> {
    #[allow(unused_mut)]
    let mut meta = read_meta();
    let layout = meta.layout;
    if layout.total == 0 {
        return None;
    }
    // From the model's own DefaultExperiment, as in C's FMU.
    openmodelica_codegen_wasm_jit_runtime::rt_set_step_size(meta.step_size());
    apply_baked_solver_flags(&meta.fmi_solver_flags)?;
    let sim_data = openmodelica_codegen_wasm_jit_runtime::rt_sim_data_new(layout.total);
    let dae_enable_vr = meta.fmi_dae_enable_vr;
    let dss = driver::StateSelection::new(&meta);
    let st = MeState {
        sim_data,
        layout,
        vrs: Vrs::new(core::mem::take(&mut meta.fmi_vrs)),
        meta,
        dss,
        #[cfg(feature = "cs")]
        cs: None,
        #[cfg(feature = "cs")]
        defer: CsDefer::None,
        mode: Mode::Instantiated,
        continuous_time: false,
        dae_enable_vr,
        dae_mode: false,
        configuring: false,
        dae_current: false,
        need_update: true,
        init_overrides: Vec::new(),
        init_start_overrides: Vec::new(),
        init_string_overrides: Vec::new(),
        samples: None,
        sync: None,
        jacobian_cache: Vec::new(),
        jacobian_valid: false,
    };
    st.seed_start_state();
    Some(st)
}

/// The metadata blob the emitter embedded in the model module.
fn read_meta() -> openmodelica_sim_meta::SimMeta {
    let ptr = unsafe { om_meta_ptr() };
    let len = unsafe { om_meta_len() } as usize;
    let bytes = unsafe { core::slice::from_raw_parts(ptr as *const u8, len) };
    decode(bytes).unwrap_or_default()
}

/// The 54 methods both resources share (`co-simulation-instance` and
/// `model-exchange-instance` declare the same getters/setters and mode
/// transitions). One body, expanded into whichever guest trait this build's world
/// generated.
macro_rules! shared_instance_methods {
    () => {

    /// C's `omcSetDebugLogging`: every category off, then the named ones follow
    /// `logging_on`; an unknown name is reported unfiltered, as in C. A category
    /// named like a runtime stream (`LOG_EVENTS`; the export declares them all)
    /// switches that stream instead.
    fn set_debug_logging(&self, logging_on: bool, categories: Vec<String>) -> Status {
        let mut cats = 0u32;
        let mut unknown: Vec<String> = Vec::new();
        let mut streams: Vec<String> = Vec::new();
        let mut fmi_categories = false;
        for c in categories {
            match CATEGORIES.iter().position(|n| *n == c) {
                Some(i) => {
                    fmi_categories = true;
                    if logging_on {
                        cats |= 1 << i;
                    }
                }
                None if omclog::STREAM_NAME.contains(&c.as_str()) => streams.push(c),
                None => unknown.push(c),
            }
        }
        if fmi_categories || streams.is_empty() {
            logger().cats = cats;
        }
        if let Ok(m) = omclog::mask_from_streams(&streams) {
            let m = m & !omclog::ALWAYS_ON;
            let cur = omclog::mask();
            omclog::set_mask(if logging_on { cur | m } else { cur & !m });
        }
        for c in unknown {
            log_raw(
                Status::Warning,
                CAT_ERROR,
                &alloc::format!("logging category '{c}' is not supported by model"),
            );
        }
        Status::Ok
    }

    fn enter_initialization_mode(
        &self,
        tolerance: Option<f64>,
        start_time: f64,
        _stop_time: Option<f64>,
    ) -> Status {
        let mut st = self.st.borrow_mut();
        // The sets made while Instantiated stay: C's `setStartValues` here turns
        // the live values into the `start` attributes the initial solve reads.
        st.mode = Mode::Init;
        st.need_update = true;
        st.dae_current = false;
        st.write_f64(TIME_OFF, start_time);
        let (sim_data, layout) = (st.sim_data, st.layout);
        let mut e = Engine;
        match set_zc_tolerance(&mut e, sim_data, &layout, tolerance.unwrap_or(0.0)) {
            Ok(()) => Status::Ok,
            Err(err) => err_status(err),
        }
    }

    fn exit_initialization_mode(&self) -> Status {
        let mut st = self.st.borrow_mut();
        // Only when something was set since the last solve: a get in Initialization
        // Mode has already run it otherwise.
        if let Err(status) = st.update_if_needed() {
            return status;
        }
        st.mode = Mode::Ready;
        // `run_initialization` has run `initSample`, so the schedule is readable.
        if st.layout.n_samples > 0 {
            let start_time = st.read_f64(TIME_OFF);
            match Samples::load(&Engine, st.sim_data, &st.layout, start_time) {
                Ok(s) => st.samples = Some(s),
                Err(err) => return err_status(err),
            }
        }
        // The CS driver is built lazily on the first `do-step` (see there): a me_cs
        // component driven in Model Exchange must not pay for — or be perturbed by —
        // a driver it never uses. Event Mode is the exception: the master's first
        // action after init is an event iteration (`update-discrete-states`), which
        // must run through the driver's sample schedule, so build it eagerly.
        #[cfg(feature = "cs")]
        if st.defer != CsDefer::None {
            let (sim_data, t) = (st.sim_data, st.read_f64(TIME_OFF));
            let (meta, defer) = (st.meta.clone(), st.defer);
            let sync = st.sync.take();
            match CsDriver::new(&mut Engine, &meta, sim_data, t, defer, sync) {
                Ok(d) => st.cs = Some(d),
                Err(err) => return err_status(err),
            }
        }
        Status::Ok
    }

    fn enter_event_mode(&self) -> Status {
        self.st.borrow_mut().continuous_time = false;
        Status::Ok
    }

    /// The master has located the event and set time/states; run the discrete
    /// update here. `iterate_discrete` already runs to a fixed point, so one pass
    /// always suffices and `new-discrete-states-needed` stays false.
    fn update_discrete_states(&self) -> Result<DiscreteStatesInfo, Status> {
        let mut st = self.st.borrow_mut();
        let (sim_data, layout) = (st.sim_data, st.layout);
        let time = st.read_f64(TIME_OFF);
        let mut e = Engine;

        // The CS driver owns the instance's clock schedule and fires the timers
        // itself, so `fmi_handle_timers` below must not fire them a second time.
        #[cfg(feature = "cs")]
        let (up, clocks_handled) = if let Some(mut d) = st.cs.take() {
            // Route through the driver so its sample and clock schedules advance in
            // step with the integrator (see `CsDriver::do_event_update`).
            let meta = st.meta.clone();
            let r = d.do_event_update(&mut e, &meta, time);
            st.cs = Some(d);
            match r {
                Ok(up) => (up, true),
                Err(err) => return Err(err_status(err)),
            }
        } else {
            match event_update(&mut e, sim_data, &layout, st.samples.as_mut(), time) {
                Ok(up) => (up, false),
                Err(err) => return Err(err_status(err)),
            }
        };
        #[cfg(not(feature = "cs"))]
        let (up, clocks_handled) = match event_update(&mut e, sim_data, &layout, st.samples.as_mut(), time) {
            Ok(up) => (up, false),
            Err(err) => return Err(err_status(err)),
        };

        // C's `discreteCall = 0` at the end of `functionDAE`: left in event mode, every
        // later evaluation restores the relations and hides the next crossing.
        st.write_i32(layout.rel_fresh_off, 0);

        // After the discrete update, as `perform_simulation` has it rather than before
        // it as C's FMU export does: the state-set Jacobian is worth no more than the
        // point it is evaluated at.
        let reselected = {
            let m = &mut *st;
            match m.dss.reselect(&mut e, sim_data, &m.meta) {
                Ok(changed) => changed,
                Err(err) => return Err(err_status(err)),
            }
        };
        if reselected {
            st.need_update = true;
        st.dae_current = false;
        }

        // C's `internalEventUpdate`: the timers, then the earliest of the next
        // sample and the next activation.
        let mut next = up.next_event_time;
        let mut ticked = false;
        let pending_sync = if clocks_handled { None } else { st.sync.take() };
        if let Some(mut sync) = pending_sync {
            let r = driver::fmi_handle_timers(&mut e, &mut sync, &st.meta, sim_data, time);
            let tc = sync.next_time();
            st.sync = Some(sync);
            match r {
                Ok(fired) => ticked = fired,
                Err(err) => return Err(err_status(err)),
            }
            if tc.is_finite() {
                next = Some(next.map_or(tc, |n: f64| n.min(tc)));
            }
        }

        Ok(DiscreteStatesInfo {
            new_discrete_states_needed: false,
            terminate_simulation: up.terminate,
            // C's `updateSolverNominals`: a pivoted state set integrates other
            // variables, with other nominals.
            nominals_of_continuous_states_changed: reselected,
            values_of_continuous_states_changed: up.states_changed || ticked || reselected,
            next_event_time_defined: next.is_some(),
            next_event_time: next.unwrap_or(0.0),
        })
    }

    fn terminate(&self) -> Status {
        let st = self.st.borrow();
        let mut e = Engine;
        let _ = e.call1_if_present("callExternalObjectDestructors", st.sim_data);
        Status::Ok
    }

    /// Back to the instantiated state: what initialization and the steps after it
    /// built goes with the `SimData` it was built over, or the next run continues
    /// from the last one.
    fn reset(&self) -> Status {
        let mut st = self.st.borrow_mut();
        unsafe {
            core::ptr::write_bytes(st.sim_data as *mut u8, 0, st.layout.total as usize);
        }
        st.mode = Mode::Instantiated;
        st.continuous_time = false;
        st.dae_mode = false;
        st.configuring = false;
        st.need_update = true;
        st.dae_current = false;
        st.init_overrides.clear();
        st.init_start_overrides.clear();
        st.init_string_overrides.clear();
        st.samples = None;
        st.sync = None;
        #[cfg(feature = "cs")]
        {
            st.cs = None;
        }
        st.seed_start_state();
        Status::Ok
    }

    /// The one structural parameter is `fixed`: Configuration Mode is open from
    /// Instantiated only, not the Reconfiguration Mode a `tunable` one would allow.
    fn enter_configuration_mode(&self) -> Status {
        let mut st = self.st.borrow_mut();
        if st.mode != Mode::Instantiated || st.configuring {
            return err_status("fmi3EnterConfigurationMode: only allowed in the Instantiated state");
        }
        st.configuring = true;
        Status::Ok
    }
    fn exit_configuration_mode(&self) -> Status {
        let mut st = self.st.borrow_mut();
        if !st.configuring {
            return err_status("fmi3ExitConfigurationMode: not in Configuration Mode");
        }
        st.configuring = false;
        Status::Ok
    }

    // ── Getters ───────────────────────────────────────────────────────────────
    fn get_float32(&self, _: Vec<u32>) -> Result<Vec<f32>, Status> {
        Err(Status::Error)
    }
    fn get_float64(&self, vrs: Vec<u32>) -> Result<Vec<f64>, Status> {
        let mut st = self.st.borrow_mut();
        st.update_if_needed()?;
        let vrs = st.vrs.expand(&vrs);
        let mut out = Vec::with_capacity(vrs.len());
        for vr in vrs {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::F64 => out.push(e.negate.apply_f64(st.read_f64(e.off))),
                _ => return Err(Status::Error),
            }
        }
        Ok(out)
    }
    fn get_int8(&self, _: Vec<u32>) -> Result<Vec<i8>, Status> {
        Err(Status::Error)
    }
    fn get_int16(&self, _: Vec<u32>) -> Result<Vec<i16>, Status> {
        Err(Status::Error)
    }
    fn get_int32(&self, vrs: Vec<u32>) -> Result<Vec<i32>, Status> {
        let mut st = self.st.borrow_mut();
        st.update_if_needed()?;
        let vrs = st.vrs.expand(&vrs);
        let mut out = Vec::with_capacity(vrs.len());
        for vr in vrs {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && !e.is_string => {
                    out.push(e.negate.apply_i32(st.read_i32(e.off)))
                }
                _ => return Err(Status::Error),
            }
        }
        Ok(out)
    }
    // fmi3 accesses `<Enumeration>` vars via Int64; they are `WTy::I32` slots here,
    // so widen/narrow around the i32.
    fn get_int64(&self, vrs: Vec<u32>) -> Result<Vec<i64>, Status> {
        let mut st = self.st.borrow_mut();
        st.update_if_needed()?;
        let vrs = st.vrs.expand(&vrs);
        let mut out = Vec::with_capacity(vrs.len());
        for vr in vrs {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && !e.is_string => {
                    out.push(e.negate.apply_i32(st.read_i32(e.off)) as i64)
                }
                _ => return Err(Status::Error),
            }
        }
        Ok(out)
    }
    fn get_uint8(&self, _: Vec<u32>) -> Result<Vec<u8>, Status> {
        Err(Status::Error)
    }
    fn get_uint16(&self, _: Vec<u32>) -> Result<Vec<u16>, Status> {
        Err(Status::Error)
    }
    fn get_uint32(&self, _: Vec<u32>) -> Result<Vec<u32>, Status> {
        Err(Status::Error)
    }
    fn get_uint64(&self, vrs: Vec<u32>) -> Result<Vec<u64>, Status> {
        let mut st = self.st.borrow_mut();
        st.update_if_needed()?;
        let vrs = st.vrs.expand(&vrs);
        let mut out = Vec::with_capacity(vrs.len());
        for vr in vrs {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && !e.is_string => out.push(st.read_i32(e.off) as u64),
                _ => return Err(Status::Error),
            }
        }
        Ok(out)
    }
    fn get_boolean(&self, vrs: Vec<u32>) -> Result<Vec<bool>, Status> {
        let mut st = self.st.borrow_mut();
        st.update_if_needed()?;
        let vrs = st.vrs.expand(&vrs);
        let mut out = Vec::with_capacity(vrs.len());
        for vr in vrs {
            if vr == st.dae_enable_vr && vr != 0 {
                out.push(st.dae_mode);
                continue;
            }
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && !e.is_string => {
                    out.push(e.negate.apply_i32(st.read_i32(e.off)) != 0)
                }
                _ => return Err(Status::Error),
            }
        }
        Ok(out)
    }
    fn get_string(&self, vrs: Vec<u32>) -> Result<Vec<String>, Status> {
        let mut st = self.st.borrow_mut();
        st.update_if_needed()?;
        let vrs = st.vrs.expand(&vrs);
        let mut out = Vec::with_capacity(vrs.len());
        for vr in vrs {
            match st.vrs.resolve(vr) {
                Some(e) if e.is_string => out.push(st.read_string(e.off)),
                _ => return Err(Status::Error),
            }
        }
        Ok(out)
    }
    fn get_binary(&self, _: Vec<u32>) -> Result<Vec<Vec<u8>>, Status> {
        Err(Status::Error)
    }
    fn get_clock(&self, _: Vec<u32>) -> Result<Vec<bool>, Status> {
        Err(Status::Error)
    }

    // ── Setters ───────────────────────────────────────────────────────────────
    fn set_float32(&self, _: Vec<u32>, _: Vec<f32>) -> Status {
        Status::Error
    }
    fn set_float64(&self, vrs: Vec<u32>, values: Vec<f64>) -> Status {
        let mut st = self.st.borrow_mut();
        let vrs = st.vrs.expand(&vrs);
        if vrs.len() != values.len() {
            return Status::Error;
        }
        for (vr, v) in vrs.into_iter().zip(values) {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::F64 && e.negate == Neg::None => {
                    st.write_f64(e.off, v);
                    if st.mode != Mode::Ready {
                        let start = e.start_off != 0;
                        st.record_override(if start { e.start_off } else { e.off }, WTy::F64, v, start);
                    }
                }
                _ => return Status::Error,
            }
        }
        st.need_update = true;
        st.dae_current = false;
        Status::Ok
    }
    fn set_int8(&self, _: Vec<u32>, _: Vec<i8>) -> Status {
        Status::Error
    }
    fn set_int16(&self, _: Vec<u32>, _: Vec<i16>) -> Status {
        Status::Error
    }
    fn set_int32(&self, vrs: Vec<u32>, values: Vec<i32>) -> Status {
        let mut st = self.st.borrow_mut();
        let vrs = st.vrs.expand(&vrs);
        if vrs.len() != values.len() {
            return Status::Error;
        }
        for (vr, v) in vrs.into_iter().zip(values) {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && e.negate == Neg::None && !e.is_string => {
                    st.write_i32(e.off, v);
                    if st.mode != Mode::Ready {
                        st.record_override(e.off, WTy::I32, v as f64, false);
                    }
                }
                _ => return Status::Error,
            }
        }
        st.need_update = true;
        st.dae_current = false;
        Status::Ok
    }
    fn set_int64(&self, vrs: Vec<u32>, values: Vec<i64>) -> Status {
        let mut st = self.st.borrow_mut();
        let vrs = st.vrs.expand(&vrs);
        if vrs.len() != values.len() {
            return Status::Error;
        }
        for (vr, v) in vrs.into_iter().zip(values) {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && e.negate == Neg::None && !e.is_string => {
                    st.write_i32(e.off, v as i32);
                    if st.mode != Mode::Ready {
                        st.record_override(e.off, WTy::I32, v as f64, false);
                    }
                }
                _ => return Status::Error,
            }
        }
        st.need_update = true;
        st.dae_current = false;
        Status::Ok
    }
    fn set_uint8(&self, _: Vec<u32>, _: Vec<u8>) -> Status {
        Status::Error
    }
    fn set_uint16(&self, _: Vec<u32>, _: Vec<u16>) -> Status {
        Status::Error
    }
    fn set_uint32(&self, _: Vec<u32>, _: Vec<u32>) -> Status {
        Status::Error
    }
    fn set_uint64(&self, vrs: Vec<u32>, values: Vec<u64>) -> Status {
        let mut st = self.st.borrow_mut();
        let vrs = st.vrs.expand(&vrs);
        if vrs.len() != values.len() {
            return Status::Error;
        }
        for (vr, v) in vrs.into_iter().zip(values) {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && e.negate == Neg::None && !e.is_string => {
                    st.write_i32(e.off, v as i32);
                    if st.mode != Mode::Ready {
                        st.record_override(e.off, WTy::I32, v as f64, false);
                    }
                }
                _ => return Status::Error,
            }
        }
        st.need_update = true;
        st.dae_current = false;
        Status::Ok
    }
    fn set_boolean(&self, vrs: Vec<u32>, values: Vec<bool>) -> Status {
        let mut st = self.st.borrow_mut();
        let vrs = st.vrs.expand(&vrs);
        if vrs.len() != values.len() {
            return Status::Error;
        }
        for (vr, v) in vrs.into_iter().zip(values) {
            if vr == st.dae_enable_vr && vr != 0 {
                if !st.configuring {
                    return err_status("fmi-ls-dae: the DAE-mode parameter can only be set in Configuration Mode");
                }
                if v && !st.layout.dae_mode() {
                    return err_status("fmi-ls-dae: this FMU has no DAE formulation");
                }
                st.dae_mode = v;
                continue;
            }
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && e.negate == Neg::None && !e.is_string => {
                    let iv = if v { 1 } else { 0 };
                    st.write_i32(e.off, iv);
                    if st.mode != Mode::Ready {
                        st.record_override(e.off, WTy::I32, iv as f64, false);
                    }
                }
                _ => return Status::Error,
            }
        }
        st.need_update = true;
        st.dae_current = false;
        Status::Ok
    }
    fn set_string(&self, vrs: Vec<u32>, values: Vec<String>) -> Status {
        let mut st = self.st.borrow_mut();
        let vrs = st.vrs.expand(&vrs);
        if vrs.len() != values.len() {
            return Status::Error;
        }
        for (vr, val) in vrs.into_iter().zip(values) {
            match st.vrs.resolve(vr) {
                Some(e) if e.is_string => {
                    st.write_string(e.off, &val);
                    if st.mode != Mode::Ready {
                        st.init_string_overrides.retain(|(o, _)| *o != e.off);
                        st.init_string_overrides.push((e.off, val)); // see the field
                    }
                }
                _ => return Status::Error,
            }
        }
        st.need_update = true;
        st.dae_current = false;
        Status::Ok
    }
    fn set_binary(&self, _: Vec<u32>, _: Vec<Vec<u8>>) -> Status {
        Status::Error
    }
    fn set_clock(&self, _: Vec<u32>, _: Vec<bool>) -> Status {
        Status::Error
    }

    fn get_number_of_variable_dependencies(&self, _: u32) -> Result<u64, Status> {
        Err(Status::Error)
    }
    fn get_variable_dependencies(&self, _: u32) -> Result<Vec<VariableDependency>, Status> {
        Err(Status::Error)
    }

    fn get_fmu_state(&self) -> Result<Vec<u8>, Status> {
        let st = self.st.borrow();
        let mut bytes = vec![0u8; st.layout.total as usize];
        let _ = Engine.read_bytes(st.sim_data, &mut bytes);
        Ok(bytes)
    }
    fn set_fmu_state(&self, state: Vec<u8>) -> Status {
        let st = self.st.borrow();
        if state.len() != st.layout.total as usize {
            return Status::Error;
        }
        let mut e = Engine;
        let _ = e.write_bytes(st.sim_data, &state);
        Status::Ok
    }

    /// `d(derivatives)/d(states) · seed`, out of the model's symbolic Jacobian.
    ///
    /// Lets an importer integrate the FMU with the Jacobian the model was
    /// compiled with instead of differencing it. Only derivatives with respect
    /// to states are answered — the only block the symbolic Jacobian holds.
    fn get_directional_derivative(
        &self,
        unknowns: Vec<u32>,
        knowns: Vec<u32>,
        seed: Vec<f64>,
    ) -> Result<Vec<f64>, Status> {
        if knowns.len() != seed.len() {
            return Err(Status::Error);
        }
        let mut st = self.st.borrow_mut();
        st.update_if_needed()?;
        let n = st.layout.n_states as usize;
        let rows: Vec<usize> = unknowns.iter().filter_map(|vr| st.derivative_index(*vr)).collect();
        let cols: Vec<usize> = knowns.iter().filter_map(|vr| st.state_index(*vr)).collect();
        if rows.len() != unknowns.len() || cols.len() != knowns.len() {
            return Err(Status::Error);
        }
        let jacobian = st.jacobian(n)?;
        Ok(rows
            .iter()
            .map(|&row| {
                cols.iter()
                    .zip(&seed)
                    .map(|(&col, s)| jacobian[col * n + row] * s)
                    .sum()
            })
            .collect())
    }
    fn get_adjoint_derivative(
        &self,
        _: Vec<u32>,
        _: Vec<u32>,
        _: Vec<f64>,
    ) -> Result<Vec<f64>, Status> {
        Err(Status::Error)
    }

    fn get_interval_decimal(&self, _: Vec<u32>) -> Result<Vec<(f64, IntervalQualifier)>, Status> {
        Err(Status::Error)
    }
    fn get_interval_fraction(
        &self,
        _: Vec<u32>,
    ) -> Result<Vec<(IntervalFraction, IntervalQualifier)>, Status> {
        Err(Status::Error)
    }
    fn get_shift_decimal(&self, _: Vec<u32>) -> Result<Vec<f64>, Status> {
        Err(Status::Error)
    }
    fn get_shift_fraction(&self, _: Vec<u32>) -> Result<Vec<IntervalFraction>, Status> {
        Err(Status::Error)
    }
    fn set_interval_decimal(&self, _: Vec<u32>, _: Vec<f64>) -> Status {
        Status::Error
    }
    fn set_interval_fraction(&self, _: Vec<u32>, _: Vec<IntervalFraction>) -> Status {
        Status::Error
    }
    fn set_shift_decimal(&self, _: Vec<u32>, _: Vec<f64>) -> Status {
        Status::Error
    }
    fn set_shift_fraction(&self, _: Vec<u32>, _: Vec<IntervalFraction>) -> Status {
        Status::Error
    }
    fn evaluate_discrete_states(&self) -> Status {
        Status::Ok
    }
    fn enter_step_mode(&self) -> Status {
        Status::Ok
    }

    /// C's `fmi2GetRealOutputDerivatives`: `$<name>_der`. C reports the first
    /// derivative whatever order is asked for.
    fn get_output_derivatives(&self, requests: Vec<(u32, u32)>) -> Result<Vec<f64>, Status> {
        let mut st = self.st.borrow_mut();
        st.update_if_needed()?;
        let mut out = Vec::with_capacity(requests.len());
        for (vr, _order) in requests {
            match st.vrs.resolve(vr) {
                Some(e) if e.der_off != 0 => out.push(st.read_f64(e.der_off)),
                _ => {
                    return Err(err_status(
                        "the model has no output derivative for this variable                          (an FMU exported with -d=fmuExperimental has them)",
                    ))
                }
            }
        }
        Ok(out)
    }
    };
}

#[cfg(feature = "me")]
impl GuestModelExchangeInstance for Instance {
    shared_instance_methods!();
    fn instantiate_model_exchange(
        instance_name: String,
        _instantiation_token: String,
        _resource_path: String,
        _visible: bool,
        logging_on: bool,
    ) -> Option<ModelExchangeInstance> {
        init_logging(instance_name, logging_on);
        // What `OpenModelica_fmuLoadResource` resolves against: the loader preopens
        // the FMU's `resources/` as this component's root, not the host path.
        openmodelica_codegen_wasm_jit_runtime::set_resources_dir("/");
        let st = new_state()?;
        Some(ModelExchangeInstance::new(Instance { st: RefCell::new(st) }))
    }

    fn enter_continuous_time_mode(&self) -> Status {
        self.st.borrow_mut().continuous_time = true;
        Status::Ok
    }

    fn set_time(&self, time: f64) -> Status {
        let mut st = self.st.borrow_mut();
        st.write_f64(TIME_OFF, time);
        st.need_update = true;
        st.dae_current = false;
        Status::Ok
    }
    fn set_continuous_states(&self, states: Vec<f64>) -> Status {
        let mut st = self.st.borrow_mut();
        if states.len() != st.layout.n_states as usize {
            return Status::Error;
        }
        for (i, v) in states.into_iter().enumerate() {
            st.write_f64(REAL_OFF + (i as u32) * 8, v);
        }
        st.need_update = true;
        st.dae_current = false;
        Status::Ok
    }

    /// C's `internalGetDerivatives`, which leaves `_need_update` set for the next
    /// getter. In DAE mode the derivatives are the importer's own, set as knowns
    /// of the residuals; in ODE mode a `--daeMode` model solves for them.
    ///
    /// In Continuous Time Mode this is the master's integrator residual, so it
    /// answers `fmi3Discard` -- C's `IRES = -1` -- for a model error (see `evaluate`).
    fn get_continuous_state_derivatives(&self) -> Result<Vec<f64>, Status> {
        let mut st = self.st.borrow_mut();
        if st.need_update && (!st.dae_mode || st.mode == Mode::Init) {
            st.eval_ode()?;
        }
        let n = st.layout.n_states;
        let base = REAL_OFF + n * 8;
        Ok((0..n).map(|i| st.read_f64(base + i * 8)).collect())
    }
    fn get_event_indicators(&self) -> Result<Vec<f64>, Status> {
        let mut st = self.st.borrow_mut();
        if st.need_update {
            st.eval_ode()?;
            st.need_update = false;
        }
        if st.layout.n_zc == 0 {
            return Ok(Vec::new());
        }
        // C's root callbacks: a crossing may read an algebraic `functionODE` skips.
        st.evaluate(|m| {
            let mut e = Engine;
            driver::eval_zc_equations(&mut e, m.sim_data, &m.layout)?;
            e.call2(driver::MODEL_FN_ZC, m.sim_data, m.sim_data + m.layout.zc_off)
        })?;
        Ok((0..st.layout.n_zc).map(|i| st.read_f64(st.layout.zc_off + i * 8)).collect())
    }
    fn get_continuous_states(&self) -> Result<Vec<f64>, Status> {
        let st = self.st.borrow();
        Ok((0..st.layout.n_states).map(|i| st.read_f64(REAL_OFF + i * 8)).collect())
    }
    fn get_nominals_of_continuous_states(&self) -> Result<Vec<f64>, Status> {
        let st = self.st.borrow();
        driver::state_nominals(&Engine, st.sim_data, &st.layout).map_err(err_status)
    }
    fn get_number_of_event_indicators(&self) -> Result<u64, Status> {
        Ok(self.st.borrow().layout.n_zc as u64)
    }
    fn get_number_of_continuous_states(&self) -> Result<u64, Status> {
        Ok(self.st.borrow().layout.n_states as u64)
    }

    /// Must not touch the model state: `functionAlgebraics` would fire the
    /// when-bodies outside Event Mode and save their `pre`, so the following
    /// `update-discrete-states` sees no edge and the `reinit` is lost. Every when
    /// is guarded by a zero-crossing or a sample, so Event Mode is reached anyway.
    fn completed_integrator_step(
        &self,
        _no_set_fmu_state_prior_to_current_point: bool,
    ) -> Result<CompletedStepResult, Status> {
        let mut st = self.st.borrow_mut();
        // C's `internal_CompletedIntegratorStep`; it leaves `_need_update` set.
        st.evaluate(|m| m.eval())?;
        // The only point the importer gives us to record the accepted step.
        driver::store_operators(&mut Engine, st.sim_data, &st.layout).map_err(err_status)?;
        st.need_update = true;
        st.dae_current = false;
        let sim_data = st.sim_data;
        let m = &mut *st;
        let switching = m.dss.would_change(&mut Engine, sim_data, &m.meta).map_err(err_status)?;
        Ok(CompletedStepResult {
            enter_event_mode: switching,
            terminate_simulation: st.read_i32(st.layout.terminate_off) != 0,
        })
    }
}


struct Fmu;

impl CommonGuest for Fmu {
    fn get_version() -> String {
        "3.0".to_string()
    }
}

#[cfg(feature = "me")]
impl MeGuest for Fmu {
    type ModelExchangeInstance = Instance;
}

#[cfg(feature = "cs")]
impl GuestCoSimulationInstance for Instance {
    shared_instance_methods!();

    fn instantiate_co_simulation(
        instance_name: String,
        _instantiation_token: String,
        _resource_path: String,
        _visible: bool,
        logging_on: bool,
        event_mode_used: bool,
        early_return_allowed: bool,
        _required_intermediate_variables: Vec<u32>,
    ) -> Option<CoSimulationInstance> {
        init_logging(instance_name, logging_on);
        // What `OpenModelica_fmuLoadResource` resolves against: the loader preopens
        // the FMU's `resources/` as this component's root, not the host path.
        openmodelica_codegen_wasm_jit_runtime::set_resources_dir("/");
        let mut st = new_state()?;
        st.defer = match (event_mode_used, early_return_allowed) {
            (false, _) => CsDefer::None,
            (true, false) => CsDefer::AtTarget,
            (true, true) => CsDefer::Any,
        };
        // C's `fmi2Instantiate` sets the internal solver up here, CS only.
        driver::log_cs_solver_setup(&st.meta, st.defer);
        Some(CoSimulationInstance::new(Instance { st: RefCell::new(st) }))
    }

    /// Integrate to the communication point, reporting the events the instance's
    /// [`CsDefer`] leaves to the master and resolving the rest.
    fn do_step(
        &self,
        current_communication_point: f64,
        communication_step_size: f64,
        _no_set_fmu_state_prior_to_current_point: bool,
    ) -> Result<DoStepResult, Status> {
        let mut st = self.st.borrow_mut();
        let target = current_communication_point + communication_step_size;
        let defer = st.defer;
        let meta = st.meta.clone();
        let mut e = Engine;
        // Build the driver on first use, over the initialized state at the start
        // point (FMI ran Initialization Mode; the importer may also have set inputs).
        // Event Mode already built it in exit-initialization-mode.
        if st.cs.is_none() {
            let (sim_data, t) = (st.sim_data, st.read_f64(TIME_OFF));
            let sync = st.sync.take();
            match CsDriver::new(&mut e, &meta, sim_data, t, defer, sync) {
                Ok(d) => st.cs = Some(d),
                Err(e) => return Err(err_status(e)),
            }
        }
        let Some(mut driver) = st.cs.take() else { return Err(Status::Error) };
        let outcome = driver.step_to(&mut e, &meta, target, defer, &mut st.dss);
        let last = driver.time();
        st.cs = Some(driver);
        // C's `fmi2DoStep`: the getters now report the new time's values. The step
        // ended on `functionAlgebraics`, so a DAE model's unknowns are current and
        // the refresh must not solve for them a second time.
        st.need_update = true;
        st.dae_current = matches!(&outcome, Ok(CsStep::Reached));
        let eps = target.abs().max(1.0) * 1e-10;
        match outcome {
            Ok(CsStep::Reached) => Ok(DoStepResult {
                last_successful_time: last,
                event_handling_needed: false,
                terminate_simulation: false,
                early_return: false,
            }),
            Ok(CsStep::Event { time }) => Ok(DoStepResult {
                last_successful_time: time,
                event_handling_needed: true,
                terminate_simulation: false,
                early_return: time + eps < target,
            }),
            Ok(CsStep::Terminated) => Ok(DoStepResult {
                last_successful_time: last,
                event_handling_needed: false,
                terminate_simulation: true,
                early_return: false,
            }),
            Err(e) => Err(err_status(e)),
        }
    }

    fn set_input_derivatives(&self, _: Vec<(u32, u32)>, _: Vec<f64>) -> Status {
        Status::Error
    }
}

#[cfg(feature = "cs")]
impl CsGuest for Fmu {
    type CoSimulationInstance = Instance;
}

/// The model's own simulation runtime, exported alongside the FMI interfaces by
/// the me_cs build (the world that declares `om:sim/simulation`).
#[cfg(all(feature = "me", feature = "cs"))]
mod sim_run;
// The host serves it in the C-API (linked) build, where the WIT import has no
// canonical-ABI lowering to reach it through.
#[cfg(all(feature = "me", feature = "cs", not(feature = "capi")))]
mod native_ext;

/// The same adapter reached as a core module rather than a component, so a host
/// can compile it once and keep the artifact.
#[cfg(feature = "capi")]
mod capi;

// The component's exports, which is what pulls in the resource intrinsics: the
// C-API build is linked as a core module and needs none of them.
#[cfg(not(feature = "capi"))]
export!(Fmu);
