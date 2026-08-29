//! The globals and small helpers the generated C names directly.
//!
//! Everything here has a counterpart in the C runtime (`model_help.c`,
//! `jacobian_util.c`, `simulation_omc_assert.c`, `options.c`); the behaviour is
//! the C one, so a model compiled against either runtime behaves the same.

use core::ffi::{VaList, c_char, c_int, c_long, c_uint, c_void};
use core::ptr;

use openmodelica_solvers::omclog;

use crate::abi::*;

// ---------------------------------------------------------------------------
// Globals the generated code writes or reads.
// ---------------------------------------------------------------------------

/// `options.c`: whether each `-flag` was given, and its value. The Rust runtime
/// parses the command line with `openmodelica_solvers::simflags`; these two are
/// filled from that parse so the generated code (`omc_flag[FLAG_MOO_OPTIMIZATION]`)
/// and the jacobian sparsity reader (`-inputPath`) see the same answers.
#[unsafe(no_mangle)]
pub static mut omc_flag: [c_int; FLAG_MAX] = [0; FLAG_MAX];
#[unsafe(no_mangle)]
pub static mut omc_flagValue: [*const c_char; FLAG_MAX] = [ptr::null(); FLAG_MAX];

/// `model_help.c`. The generated equation functions tick the profiling clocks
/// only when this is set.
#[unsafe(no_mangle)]
pub static mut measure_time_flag: c_int = 0;
/// Set by the generated `main` to say how the model was translated.
#[unsafe(no_mangle)]
pub static mut compiledInDAEMode: c_int = 0;
#[unsafe(no_mangle)]
pub static mut compiledWithSymSolver: c_int = 0;
/// `-steadyState`'s tolerance (`model_help.c`), whose default C also sets here.
/// The driver reads the flag itself; this exists because the generated code and
/// the C headers name the global.
#[unsafe(no_mangle)]
pub static mut steadyStateTol: f64 = 1e-3;
/// The zero-crossing hysteresis width the `*ZC` relations use (C's `setZCtol`).
/// Mapped into the layout at `zctol_off`, so the driver sets it directly.
#[unsafe(no_mangle)]
pub static mut tolZC: f64 = 0.0;

/// `simulation_runtime.h`: a fired `terminate(...)`, its message and position.
#[unsafe(no_mangle)]
pub static mut terminationTerminate: c_int = 0;
#[unsafe(no_mangle)]
pub static mut TermMsg: *mut c_char = ptr::null_mut();
#[unsafe(no_mangle)]
pub static mut TermInfo: FILE_INFO = FILE_INFO::dummy();

/// `dae_mode.h`: which stage of a step an equation belongs to.
#[unsafe(no_mangle)]
pub static EVAL_DYNAMIC: c_int = 1;
#[unsafe(no_mangle)]
pub static EVAL_ALGEBRAIC: c_int = 2;
#[unsafe(no_mangle)]
pub static EVAL_ZEROCROSS: c_int = 4;
#[unsafe(no_mangle)]
pub static EVAL_DISCRETE: c_int = 8;

/// Byte offsets `src/shim.c` needs into `threadData_t`. Taken from the mirror, so
/// `tests/abi_layout.rs` guards them too.
#[unsafe(no_mangle)]
pub static omr_td_off_mmc_jumper: usize = core::mem::offset_of!(threadData_t, mmc_jumper);
#[unsafe(no_mangle)]
pub static omr_td_off_global_jumper: usize = core::mem::offset_of!(threadData_t, globalJumpBuffer);
#[unsafe(no_mangle)]
pub static omr_td_off_sim_jumper: usize = core::mem::offset_of!(threadData_t, simulationJumpBuffer);
#[unsafe(no_mangle)]
pub static omr_td_off_error_stage: usize = core::mem::offset_of!(threadData_t, currentErrorStage);

/// `util/omc_error.h`'s `errorStage`, which decides what an assertion does.
pub mod error_stage {
    pub const NO_ERROR: i32 = 0;
    pub const SIMULATION: i32 = 1;
    pub const NONLINEARSOLVER: i32 = 2;
    pub const INTEGRATOR: i32 = 3;
    pub const EVENTSEARCH: i32 = 4;
    pub const EVENTHANDLING: i32 = 5;
    pub const OPTIMIZE: i32 = 6;
}

/// What `src/shim.c` should longjmp to after an assertion was reported.
mod jump {
    pub const NONE: i32 = 0;
    pub const SIMULATION: i32 = 1;
    pub const GLOBAL: i32 = 2;
}

// ---------------------------------------------------------------------------
// Assertions (the Rust half of src/shim.c).
// ---------------------------------------------------------------------------

fn cstr(p: *const c_char) -> String {
    if p.is_null() {
        return String::new();
    }
    unsafe { core::ffi::CStr::from_ptr(p) }.to_string_lossy().into_owned()
}

/// C's `messageText` puts the source position on its own line ahead of the
/// message (`printInfo`'s `[file:l:c-l:c:writable]`); a `\n` in the text makes
/// `omclog` continue with the `|` sub-line headers, exactly as C's recursion does.
fn with_position(info: &FILE_INFO, msg: &str) -> String {
    if info.filename.is_null() || unsafe { *info.filename } == 0 {
        return msg.to_string();
    }
    format!(
        "[{}:{}:{}-{}:{}:{}]\n{msg}",
        cstr(info.filename),
        info.lineStart,
        info.colStart,
        info.lineEnd,
        info.colEnd,
        if info.readonly != 0 { "readonly" } else { "writable" }
    )
}

/// Run `f` under `threadData`'s simulation jump buffer, at error stage `stage`.
/// `false` = the model left through the jump.
///
/// Every model callback called from inside a Rust frame goes through this: a
/// `longjmp` past those frames would skip the solver's own bookkeeping and land at
/// whatever catch is open further out -- not where C's would land, since C's frames
/// there are the ones being skipped.
pub(crate) fn protected<F: FnMut()>(
    thread_data: *mut threadData_t,
    stage: c_int,
    mut f: F,
) -> bool {
    unsafe extern "C" fn trampoline<F: FnMut()>(p: *mut c_void) {
        unsafe { (*(p as *mut F))() }
    }
    let rc = unsafe {
        omr_protected(trampoline::<F>, &mut f as *mut F as *mut c_void, thread_data, stage)
    };
    rc != -1
}

/// src/shim.c, which owns the two things Rust cannot express.
unsafe extern "C" {
    fn omr_protected(
        thunk: unsafe extern "C" fn(*mut c_void),
        ctx: *mut c_void,
        thread_data: *mut threadData_t,
        stage: c_int,
    ) -> c_int;
    fn omr_vformat(msg: *const c_char, ap: VaList) -> *mut c_char;
    fn omr_free(p: *mut c_void);
    /// Leave through one of `threadData`'s jump buffers; does not return.
    pub(crate) fn omr_jump(threadData: *mut threadData_t, where_: c_int);
}

/// Format a `printf` message the way the C runtime does, then drop the varargs.
fn vformat(msg: *const c_char, ap: VaList) -> String {
    let p = unsafe { omr_vformat(msg, ap) };
    if p.is_null() {
        return cstr(msg);
    }
    let s = cstr(p);
    unsafe { omr_free(p as *mut c_void) };
    s
}

/// C's `va_omc_assert_simulation_withEquationIndexes`: report on `OMC_LOG_ASSERT`
/// and say which jump buffer to take, per the current error stage.
fn assert_report(threadData: *mut threadData_t, info: FILE_INFO, text: &str) -> c_int {
    let stage = if threadData.is_null() {
        error_stage::SIMULATION
    } else {
        unsafe { (*threadData).currentErrorStage }
    };
    let quiet = match stage {
        error_stage::NONLINEARSOLVER => !omclog::active(omclog::NLS),
        error_stage::INTEGRATOR => !omclog::active(omclog::SOLVER),
        _ => false,
    };
    if !quiet {
        omclog::error(omclog::ASSERT, false, &with_position(&info, text));
    }
    match stage {
        error_stage::EVENTHANDLING | error_stage::OPTIMIZE => jump::GLOBAL,
        _ => jump::SIMULATION,
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_assert_simulation(
    threadData: *mut threadData_t,
    info: FILE_INFO,
    msg: *const c_char,
    ap: ...
) -> ! {
    // Every temporary is dropped inside the block: the longjmp below leaves this
    // frame without unwinding it, exactly as it leaves C's.
    let target = {
        let text = vformat(msg, ap);
        assert_report(threadData, info, &text)
    };
    unsafe { omr_jump(threadData, target) };
    unreachable!("omr_jump returned")
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_assert_simulation_withEquationIndexes(
    threadData: *mut threadData_t,
    info: FILE_INFO,
    _indexes: *const c_int,
    msg: *const c_char,
    ap: ...
) -> ! {
    let target = {
        let text = vformat(msg, ap);
        assert_report(threadData, info, &text)
    };
    unsafe { omr_jump(threadData, target) };
    unreachable!("omr_jump returned")
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_assert_warning_simulation(info: FILE_INFO, msg: *const c_char, ap: ...) {
    let text = vformat(msg, ap);
    omclog::warning(omclog::ASSERT, false, &with_position(&info, &text));
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_assert_warning_simulation_withEquationIndexes(
    info: FILE_INFO,
    _indexes: *const c_int,
    msg: *const c_char,
    ap: ...
) {
    let text = vformat(msg, ap);
    omclog::warning(omclog::ASSERT, false, &with_position(&info, &text));
}

/// C's `omc_terminate_simulation`: record the message; the driver stops at the
/// next output row.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_terminate_simulation(info: FILE_INFO, msg: *const c_char, ap: ...) {
    let text = vformat(msg, ap);
    set_term_msg(info, &text);
}

/// C's `omc_throw_simulation`: an external C function asserted.
#[unsafe(no_mangle)]
pub extern "C" fn omc_throw_simulation(threadData: *mut threadData_t) -> ! {
    set_term_msg(FILE_INFO::dummy(), "Assertion triggered by external C function");
    unsafe { omr_jump(threadData, jump::GLOBAL) };
    unreachable!("omr_jump returned")
}

fn set_term_msg(info: FILE_INFO, text: &str) {
    let c = std::ffi::CString::new(text).unwrap_or_default();
    unsafe {
        if !TermMsg.is_null() {
            libc::free(TermMsg as *mut c_void);
        }
        TermMsg = libc::strdup(c.as_ptr());
        TermInfo = info;
        terminationTerminate = 1;
    }
}

/// `simulation_omc_assert.c`: the two indexed variants are function-pointer
/// globals the generated `main` re-points, pre-set to the simulation versions.
#[unsafe(no_mangle)]
pub static mut omc_assert_withEquationIndexes: unsafe extern "C" fn(
    *mut threadData_t,
    FILE_INFO,
    *const c_int,
    *const c_char,
    ...
) -> ! = omc_assert_simulation_withEquationIndexes;

#[unsafe(no_mangle)]
pub static mut omc_assert_warning_withEquationIndexes: unsafe extern "C" fn(
    FILE_INFO,
    *const c_int,
    *const c_char,
    ...
) = omc_assert_warning_simulation_withEquationIndexes;

/// C's `throwPrintsMessage`: `LOG_ASSERT` carries the message, except out of the
/// nonlinear solver, where it follows `LOG_NLS`. The integrator stage does not
/// get that treatment here -- C's failed-algebraic-solve throw is raised there.
fn throw_prints_message(stage: c_int) -> bool {
    if !omclog::active(omclog::ASSERT) {
        return false;
    }
    if stage == error_stage::NONLINEARSOLVER {
        return omclog::active(omclog::NLS);
    }
    true
}

/// C's `throwStreamPrint`: report on `OMC_LOG_ASSERT` and leave through the
/// buffer `getBestJumpBuffer` picks for the stage. Unlike `omc_assert_simulation`
/// the message is a debug one, and `ERROR_OPTIMIZE` takes the simulation buffer.
pub(crate) fn throw_stream(threadData: *mut threadData_t, msg: &str) -> ! {
    let stage = if threadData.is_null() {
        error_stage::SIMULATION
    } else {
        unsafe { (*threadData).currentErrorStage }
    };
    let target = {
        if throw_prints_message(stage) {
            omclog::debug(omclog::ASSERT, false, msg);
        }
        match stage {
            error_stage::EVENTSEARCH
            | error_stage::SIMULATION
            | error_stage::NONLINEARSOLVER
            | error_stage::INTEGRATOR
            | error_stage::OPTIMIZE => jump::SIMULATION,
            _ => jump::GLOBAL,
        }
    };
    unsafe { omr_jump(threadData, target) };
    unreachable!("omr_jump returned")
}

/// The shim's last resort: nothing can catch this, so say why and stop.
#[unsafe(no_mangle)]
pub extern "C" fn omr_fatal(msg: *const c_char) {
    omclog::error(omclog::STDOUT, false, &cstr(msg));
    std::process::exit(1);
}

// ---------------------------------------------------------------------------
// Relations (`model_help.c`).
// ---------------------------------------------------------------------------

#[unsafe(no_mangle)]
pub extern "C" fn Less(a: f64, b: f64) -> c_int {
    (a < b) as c_int
}
#[unsafe(no_mangle)]
pub extern "C" fn LessEq(a: f64, b: f64) -> c_int {
    (a <= b) as c_int
}
#[unsafe(no_mangle)]
pub extern "C" fn Greater(a: f64, b: f64) -> c_int {
    (a > b) as c_int
}
#[unsafe(no_mangle)]
pub extern "C" fn GreaterEq(a: f64, b: f64) -> c_int {
    (a >= b) as c_int
}

fn zc_eps(a: f64, b: f64, a_nominal: f64, b_nominal: f64) -> f64 {
    (unsafe { tolZC }) * (a.abs().max(b.abs()) + a_nominal.abs().max(b_nominal.abs()))
}

#[unsafe(no_mangle)]
pub extern "C" fn LessZC(a: f64, b: f64, an: f64, bn: f64, direction: c_int) -> c_int {
    let eps = zc_eps(a, b, an, bn);
    (if direction != 0 { a - b <= eps } else { a - b <= -eps }) as c_int
}
#[unsafe(no_mangle)]
pub extern "C" fn GreaterZC(a: f64, b: f64, an: f64, bn: f64, direction: c_int) -> c_int {
    let eps = zc_eps(a, b, an, bn);
    (if direction != 0 { a - b >= -eps } else { a - b >= eps }) as c_int
}
#[unsafe(no_mangle)]
pub extern "C" fn LessEqZC(a: f64, b: f64, an: f64, bn: f64, direction: c_int) -> c_int {
    (GreaterZC(a, b, an, bn, (direction == 0) as c_int) == 0) as c_int
}
#[unsafe(no_mangle)]
pub extern "C" fn GreaterEqZC(a: f64, b: f64, an: f64, bn: f64, direction: c_int) -> c_int {
    (LessZC(a, b, an, bn, (direction == 0) as c_int) == 0) as c_int
}

// ---------------------------------------------------------------------------
// Analytic-Jacobian scaffolding (`jacobian_util.c`), called by the generated
// `initialAnalyticJacobian*`.
// ---------------------------------------------------------------------------

/// `calloc` that returns a non-null pointer for a zero-length request, as the C
/// runtime's allocations are always dereferenceable.
fn calloc_bytes(n: usize) -> *mut c_void {
    unsafe { libc::calloc(n.max(1), 1) }
}

#[unsafe(no_mangle)]
pub extern "C" fn initJacobian(
    jacobian: *mut JACOBIAN,
    sizeCols: c_uint,
    sizeRows: c_uint,
    sizeTmpVars: c_uint,
    dag: *mut c_void,
    evalColumn: jacobianColumn_func_ptr,
    constantEqns: jacobianColumn_func_ptr,
    sparsePattern: *mut SPARSE_PATTERN,
) {
    let j = unsafe { &mut *jacobian };
    j.sizeCols = sizeCols as usize;
    j.sizeRows = sizeRows as usize;
    j.sizeTmpVars = sizeTmpVars as usize;
    j.seedVars = calloc_bytes(sizeCols as usize * 8) as *mut f64;
    j.resultVars = calloc_bytes(sizeRows as usize * 8) as *mut f64;
    j.tmpVars = calloc_bytes(sizeTmpVars as usize * 8) as *mut f64;
    j.dag = dag;
    j.evalSelection = ptr::null_mut();
    j.evalColumn = evalColumn;
    j.constantEqns = constantEqns;
    j.sparsePattern = sparsePattern;
    j.availability = JACOBIAN_UNKNOWN;
    j.dae_cj = 0.0;
    j.isRowEval = 0;
    j.isBidirectional = 0;
    j.adjointJacobian = ptr::null_mut();
    j.recoverMask = ptr::null_mut();
    j.csrToCscMap = ptr::null_mut();
}

#[unsafe(no_mangle)]
pub extern "C" fn allocSparsePattern(
    n_leadIndex: c_uint,
    nnz: c_uint,
    maxColors: c_uint,
) -> *mut SPARSE_PATTERN {
    let p = calloc_bytes(core::mem::size_of::<SPARSE_PATTERN>()) as *mut SPARSE_PATTERN;
    let s = unsafe { &mut *p };
    s.nnz = nnz;
    s.leadindex = calloc_bytes((n_leadIndex as usize + 1) * 4) as *mut c_uint;
    s.index = calloc_bytes(nnz as usize * 4) as *mut c_uint;
    s.colorCols = calloc_bytes(n_leadIndex as usize * 4) as *mut c_uint;
    s.maxColors = maxColors;
    s.sizeCols = n_leadIndex;
    p
}

#[unsafe(no_mangle)]
pub extern "C" fn freeSparsePattern(pattern: *mut SPARSE_PATTERN) {
    if pattern.is_null() {
        return;
    }
    unsafe {
        let s = &mut *pattern;
        libc::free(s.leadindex as *mut c_void);
        libc::free(s.index as *mut c_void);
        libc::free(s.colorCols as *mut c_void);
        s.leadindex = ptr::null_mut();
        s.index = ptr::null_mut();
        s.colorCols = ptr::null_mut();
    }
}

/// The `<Model>_Jac<X>.bin` beside the executable (or under `-inputPath` /
/// an FMU's `resources`), which the generated Jacobian init reads its sparsity
/// pattern from.
#[unsafe(no_mangle)]
pub extern "C" fn openSparsePatternFile(
    data: *mut DATA,
    threadData: *mut threadData_t,
    filename: *const c_char,
) -> *mut libc::FILE {
    let name = cstr(filename);
    let dir = unsafe {
        if omc_flag[crate::abi::FLAG_INPUT_PATH] != 0 {
            Some(cstr(omc_flagValue[crate::abi::FLAG_INPUT_PATH]))
        } else if !(*(*data).modelData).resourcesDir.is_null() {
            Some(cstr((*(*data).modelData).resourcesDir))
        } else {
            None
        }
    };
    let full = match dir {
        Some(d) => format!("{d}/{name}"),
        None => name.clone(),
    };
    let path = std::ffi::CString::new(full.clone()).unwrap_or_default();
    let f = unsafe { libc::fopen(path.as_ptr(), c"rb".as_ptr()) };
    if f.is_null() {
        crate::throw(threadData, &format!("Could not open sparsity pattern file {full}."));
    }
    f
}

#[unsafe(no_mangle)]
pub extern "C" fn readSparsePatternColor(
    threadData: *mut threadData_t,
    file: *mut libc::FILE,
    colorCols: *mut c_uint,
    color: c_uint,
    length: c_uint,
    maxIndex: c_uint,
) {
    for _ in 0..length {
        let mut index: c_uint = 0;
        let n = unsafe { libc::fread(&mut index as *mut c_uint as *mut c_void, 4, 1, file) };
        if n != 1 {
            crate::throw(
                threadData,
                &format!("Error while reading color {color} of sparsity pattern."),
            );
        }
        if index >= maxIndex {
            crate::throw(
                threadData,
                &format!(
                    "Error while reading color {color} of sparsity pattern. Index {index} out of bounds"
                ),
            );
        }
        unsafe { *colorCols.add(index as usize) = color };
    }
}

/// C's adaptive evaluation of `functionODE` (`eval_dep.c`). The Rust runtime's
/// integrators always evaluate the whole right-hand side, as the wasm-jit runtime
/// does, so no dependency graph is built and nothing selects a subset.
#[unsafe(no_mangle)]
pub extern "C" fn buildEvalDAG_ODE(modelData: *mut MODEL_DATA, _nEqns: usize, _ixs: *const usize) {
    unsafe { (*modelData).dag = ptr::null_mut() };
}

#[unsafe(no_mangle)]
pub extern "C" fn buildEvalDAG_Jac(
    jacobian: *mut JACOBIAN,
    _modelData: *mut MODEL_DATA,
    _nEqns: usize,
    _ixs: *const usize,
) {
    unsafe { (*jacobian).dag = ptr::null_mut() };
}

// ---------------------------------------------------------------------------
// Event-triggering math functions (`model_help.c`). Their argument is held over
// a continuous step and only refreshed on a discrete call, so `integer(x)` is a
// step function the integrator sees as constant between events.
// ---------------------------------------------------------------------------

/// Whether the model is in a discrete evaluation, where the held values refresh.
fn discrete_call(data: *mut DATA) -> bool {
    let si = unsafe { &*(*data).simulationInfo };
    si.discreteCall != 0 && si.solveContinuous == 0
}

fn math_pre(data: *mut DATA, index: modelica_integer) -> *mut f64 {
    unsafe { (*(*data).simulationInfo).mathEventsValuePre.add(index as usize) }
}

#[unsafe(no_mangle)]
pub extern "C" fn _event_integer(x: f64, index: modelica_integer, data: *mut DATA) -> modelica_integer {
    let slot = math_pre(data, index);
    if discrete_call(data) {
        unsafe { *slot = x.floor() };
    }
    unsafe { *slot as modelica_integer }
}

#[unsafe(no_mangle)]
pub extern "C" fn _event_floor(x: f64, index: modelica_integer, data: *mut DATA) -> f64 {
    let slot = math_pre(data, index);
    if discrete_call(data) {
        unsafe { *slot = x };
    }
    unsafe { *slot }.floor()
}

#[unsafe(no_mangle)]
pub extern "C" fn _event_ceil(x: f64, index: modelica_integer, data: *mut DATA) -> f64 {
    let slot = math_pre(data, index);
    if discrete_call(data) {
        unsafe { *slot = x };
    }
    unsafe { *slot }.ceil()
}

#[unsafe(no_mangle)]
pub extern "C" fn _event_mod_integer(
    x1: modelica_integer,
    x2: modelica_integer,
    index: modelica_integer,
    data: *mut DATA,
    _threadData: *mut threadData_t,
) -> modelica_integer {
    if discrete_call(data) {
        unsafe {
            *math_pre(data, index) = x1 as f64;
            *math_pre(data, index + 1) = x2 as f64;
        }
    }
    let tmp = x1 % x2;
    if (x2 > 0 && tmp < 0) || (x2 < 0 && tmp > 0) { tmp + x2 } else { tmp }
}

#[unsafe(no_mangle)]
pub extern "C" fn _event_mod_real(
    x1: f64,
    x2: f64,
    index: modelica_integer,
    data: *mut DATA,
    _threadData: *mut threadData_t,
) -> f64 {
    if discrete_call(data) {
        unsafe {
            *math_pre(data, index) = x1;
            *math_pre(data, index + 1) = x2;
        }
    }
    x1 - _event_floor(x1 / x2, index + 2, data) * x2
}

#[unsafe(no_mangle)]
pub extern "C" fn _event_div_integer(
    x1: modelica_integer,
    x2: modelica_integer,
    index: modelica_integer,
    data: *mut DATA,
    threadData: *mut threadData_t,
) -> modelica_integer {
    if discrete_call(data) {
        unsafe {
            *math_pre(data, index) = x1 as f64;
            *math_pre(data, index + 1) = x2 as f64;
        }
    }
    let (v1, v2) = unsafe { (*math_pre(data, index) as i64, *math_pre(data, index + 1) as i64) };
    if v2 == 0 {
        let time = unsafe { (**(*data).localData).timeValue };
        // C's `%f`, so the message does not turn on the event time's last bits.
        crate::throw(
            threadData,
            &format!("event_div_integer failed at time {time:.6} because x2 is zero!"),
        );
    }
    v1 / v2
}

#[unsafe(no_mangle)]
pub extern "C" fn _event_div_real(
    x1: f64,
    x2: f64,
    index: modelica_integer,
    data: *mut DATA,
    _threadData: *mut threadData_t,
) -> f64 {
    if discrete_call(data) {
        unsafe {
            *math_pre(data, index) = x1;
            *math_pre(data, index + 1) = x2;
        }
    }
    let (v1, v2) = unsafe { (*math_pre(data, index), *math_pre(data, index + 1)) };
    (v1 / v2).trunc()
}

// ---------------------------------------------------------------------------
// Attribute lookup by scalar index (`arrayIndex.c`): the generated code asks for
// the declared `start` / `nominal` / `min` / `max` of a scalarized variable.
// ---------------------------------------------------------------------------

/// `enum var_kind` (util/varinfo.h): only a parameter reads a different array.
const VAR_KIND_PARAMETER: c_int = 3;

/// Which `real_array` attribute of which variable a `(kind, scalar index)` names.
fn real_attribute(
    si: &SIMULATION_INFO,
    md: &MODEL_DATA,
    kind: c_int,
    scalar_idx: usize,
    pick: impl Fn(&REAL_ATTRIBUTE) -> &real_array,
    fallback: f64,
) -> f64 {
    let (rev, data) = match kind {
        VAR_KIND_PARAMETER => (si.realParamsReverseIndex, md.realParameterData),
        _ => (si.realVarsReverseIndex, md.realVarsData),
    };
    unsafe {
        let ix = &*rev.add(scalar_idx);
        pick(&(*data.add(ix.array_idx)).attribute).real_at(ix.dim_idx, fallback)
    }
}

/// `getStartFromScalarIdx` / `getMinFromScalarIdx` / `getMaxFromScalarIdx` take a
/// `var_type` before the kind; `getNominalFromScalarIdx` does not.
#[unsafe(no_mangle)]
pub extern "C" fn getStartFromScalarIdx(
    simulationInfo: *const SIMULATION_INFO,
    modelData: *const MODEL_DATA,
    _ty: c_int,
    kind: c_int,
    scalar_idx: usize,
) -> f64 {
    real_attribute(unsafe { &*simulationInfo }, unsafe { &*modelData }, kind, scalar_idx, |a| &a.start, 0.0)
}

#[unsafe(no_mangle)]
pub extern "C" fn getMinFromScalarIdx(
    simulationInfo: *const SIMULATION_INFO,
    modelData: *const MODEL_DATA,
    _ty: c_int,
    kind: c_int,
    scalar_idx: usize,
) -> f64 {
    real_attribute(unsafe { &*simulationInfo }, unsafe { &*modelData }, kind, scalar_idx, |a| &a.min, -f64::MAX)
}

#[unsafe(no_mangle)]
pub extern "C" fn getMaxFromScalarIdx(
    simulationInfo: *const SIMULATION_INFO,
    modelData: *const MODEL_DATA,
    _ty: c_int,
    kind: c_int,
    scalar_idx: usize,
) -> f64 {
    real_attribute(unsafe { &*simulationInfo }, unsafe { &*modelData }, kind, scalar_idx, |a| &a.max, f64::MAX)
}

#[unsafe(no_mangle)]
pub extern "C" fn getNominalFromScalarIdx(
    simulationInfo: *const SIMULATION_INFO,
    modelData: *const MODEL_DATA,
    kind: c_int,
    scalar_idx: usize,
) -> f64 {
    real_attribute(unsafe { &*simulationInfo }, unsafe { &*modelData }, kind, scalar_idx, |a| &a.nominal, 1.0)
}
