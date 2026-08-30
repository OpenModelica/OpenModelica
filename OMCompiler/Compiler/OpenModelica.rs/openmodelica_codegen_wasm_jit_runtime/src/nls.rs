//! The wasm ABI over [`openmodelica_nls`]: table indices and linear-memory
//! addresses on this side, plain slices on the other.
//!
//! The solver itself is shared with `openmodelica_simulation_runtime`, which
//! supplies the same seam over `NONLINEAR_SYSTEM_DATA`, and so is KINSOL
//! ([`openmodelica_nls::kinsol`]). What stays here is the marshalling, the `rt_*`
//! entry points the emitted module calls, and `newton_sparse_solve` -- the sparse
//! Newton that stands in for KINSOL where the archives are absent, over this
//! runtime's own `lin_sparse_cached`.

use alloc::vec;
use core::cell::UnsafeCell;
use core::sync::atomic::Ordering;

use openmodelica_nls as nls;
use openmodelica_nls::newton_diagnostics::DiagInfo;
use openmodelica_solvers::solverflags;
pub use openmodelica_nls::*;

use crate::{load_f64, load_u32, rt_alloc, rt_free, store_f64, store_u32};

/// Install the parts of a run that are this runtime's rather than the solver's.
///
/// Only three doors lead into core code that can reach them -- a solve, a throw
/// and a model error -- and each opens with this, so there is no initialization
/// order to get wrong. A handful of relaxed stores behind a flag; a solve is
/// thousands of floating-point operations.
fn install_hooks() {
    use core::sync::atomic::AtomicBool;
    static DONE: AtomicBool = AtomicBool::new(false);
    if DONE.swap(true, Ordering::Relaxed) {
        return;
    }
    nls::host::set_trap(crate::trap);
    nls::host::set_note_runtime_error(crate::note_runtime_error);
    nls::host::set_note_runtime_error_flag(crate::note_runtime_error_flag);
    nls::host::set_write_file(crate::files::write_file);
    nls::host::set_file_prefix(crate::files::prefix);
    // `-saveInitialGuess_system`, which KINSOL reaches: the state it writes is the
    // run's model and `SimData`, and only this runtime knows where those are.
    #[cfg(sundials)]
    {
        nls::host::set_initial_guess_request(crate::model_ctx::take_request);
        nls::host::set_initial_guess_writer(|path| {
            crate::model_ctx::write(path).map_err(alloc::string::String::from)
        });
    }
}

/// C's `throwStreamPrint`, with this runtime's reporting installed.
pub(crate) fn throw_stream(s: &str) {
    install_hooks();
    nls::throw_stream(s)
}

/// A model error where the generated code calls `throwStreamPrint` -- an invalid
/// root, a zero divisor, an index out of range.
pub(crate) fn model_error() {
    install_hooks();
    nls::model_error()
}

/// A string literal the module's pool owns, borrowed for the length of the call.
fn borrowed_str<'a>(h: u32) -> &'a str {
    core::str::from_utf8(unsafe { crate::str_bytes(h) }).unwrap_or("")
}

/// Address of the evaluation context, so the driver marks a context with a store
/// rather than a wasm call per evaluation.
#[unsafe(no_mangle)]
pub extern "C" fn rt_context_addr() -> u32 {
    nls::eval_context_addr() as u32
}

#[unsafe(no_mangle)]
pub extern "C" fn rt_set_step_size(h: f64) {
    nls::set_step_size(h);
}

/// Address of the error stage, so the driver marks a region with a store rather
/// than a wasm call per evaluation (as for [`rt_context_addr`]).
#[unsafe(no_mangle)]
pub extern "C" fn rt_error_stage_addr() -> u32 {
    nls::error_stage_addr() as u32
}

/// C's `createGlobalConstraints` / `createLocalConstraints` reports. `msg` is the
/// dumped constraint expression, borrowed from the module's literal pool.
#[unsafe(no_mangle)]
pub extern "C" fn rt_dt_cons_violated(msg: u32, local: u32) {
    nls::dt_cons_violated(borrowed_str(msg), local != 0);
}

/// The local variant, which also fails the evaluation it ran in.
#[unsafe(no_mangle)]
pub extern "C" fn rt_dt_local_violated(msg: u32) {
    nls::dt_local_violated(borrowed_str(msg));
}

/// C's `equationLinear`/`equationNonlinear` entry line.
#[unsafe(no_mangle)]
pub extern "C" fn rt_dt_solving(index: i32, strict: i32, time: f64, linear: u32) {
    nls::dt_solving(index, strict, time, linear != 0);
}

/// C's two `LOG_DT` lines that announce the strict set taking over.
#[unsafe(no_mangle)]
pub extern "C" fn rt_dt_fallback(cons: u32) {
    nls::dt_fallback(cons != 0);
}

/// Model side (emitted by `emit_assert`): is a failed assert currently recoverable —
/// inside a nonlinear-solver residual, or the integrator's? Non-zero → the model
/// records the assert via [`rt_nls_note_assert`] and bails out instead of trapping.
#[unsafe(no_mangle)]
pub extern "C" fn rt_nls_recovering() -> i32 {
    nls::recovering() as i32
}

/// Model side: flag that a recoverable assert fired at the current trial point.
#[unsafe(no_mangle)]
pub extern "C" fn rt_nls_note_assert() {
    nls::note_assert();
}

/// Model side (emitted by `emit_assert`): a failed `assert()` the solver absorbs.
/// C's `omc_assert_simulation` logs it where it fires, before the `longjmp` the
/// solver catches. `sim_data` is 0 outside a simulation; the three String handles
/// are this call's to release.
#[unsafe(no_mangle)]
pub extern "C" fn rt_nls_assert_failed(
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
) {
    // C's `longjmp` ends the evaluation at its first model error, so the asserts
    // after it never run. Here every frame returns and the rest carries on, so
    // report only what C's jump would have reached -- as [`throw_stream`] does.
    let report = nls::throw_reports() && assert_logged();
    nls::note_assert();
    if report {
        use openmodelica_sim_meta::TIME_OFF;
        use openmodelica_sim_meta::driver::{AssertInfo, log_assert_block};
        let info = AssertInfo {
            msg: rt_string(msg),
            file: rt_string(file),
            read_only: read_only != 0,
            line_start: sline,
            col_start: scol,
            line_end: eline,
            col_end: ecol,
        };
        let time = if sim_data != 0 { unsafe { load_f64(sim_data as u32 + TIME_OFF) } } else { 0.0 };
        log_assert_block(&info, &rt_string(cond), time, initial != 0);
    }
    for h in [msg, file, cond] {
        if h != 0 {
            crate::rt_release(h as u32);
        }
    }
}

/// C's `assertCommonVar` (a math builtin's domain guard): `omc_assert_warning`
/// heads the `LOG_ASSERT` block and `throwStreamPrintWithEquationIndexes` adds the
/// message, both before `getBestJumpBuffer` picks the jump buffer — so a fatal
/// violation reports exactly as a caught one does. Returns non-zero where a solver
/// residual or the step catches it, so the caller returns instead of unwinding.
/// `msg` is this call's to release.
#[unsafe(no_mangle)]
pub extern "C" fn rt_assert_common(msg: i32, sim_data: i32, initial: i32) -> i32 {
    let caught = nls::error_caught();
    if nls::throw_reports() {
        use openmodelica_sim_meta::TIME_OFF;
        let time = if sim_data != 0 { unsafe { load_f64(sim_data as u32 + TIME_OFF) } } else { 0.0 };
        crate::omclog::warning(
            crate::omclog::ASSERT,
            false,
            &alloc::format!(
                "The following assertion has been violated {}at time {}",
                if initial != 0 { "during initialization " } else { "" },
                crate::omclog::f(time, 0, 6)
            ),
        );
        if nls::throw_logged() {
            crate::omclog::debug(crate::omclog::ASSERT, false, &rt_string(msg));
        }
    }
    if msg != 0 {
        crate::rt_release(msg as u32);
    }
    if caught {
        rt_nls_note_assert();
        return 1;
    }
    // The flag is what makes the caller's unwind report as an assertion, not a crash.
    crate::note_runtime_error_flag();
    0
}

/// C's stage switch in `va_omc_assert_simulation_withEquationIndexes`.
fn assert_logged() -> bool {
    match nls::error_stage() {
        ERROR_NONLINEARSOLVER => crate::omclog::active(crate::omclog::NLS),
        ERROR_INTEGRATOR => crate::omclog::active(crate::omclog::SOLVER),
        _ => true,
    }
}

fn rt_string(h: i32) -> alloc::string::String {
    if h == 0 {
        return alloc::string::String::new();
    }
    alloc::string::String::from_utf8_lossy(unsafe { crate::str_bytes(h as u32) }).into_owned()
}

/// C's `throwStreamPrint`: log `msg` on `LOG_ASSERT` and unwind. `msg` is borrowed
/// (the module's literal pool owns it). Returns only where the unwind is
/// recoverable.
#[unsafe(no_mangle)]
pub extern "C" fn rt_throw_stream(msg: u32) {
    throw_stream(borrowed_str(msg))
}

#[unsafe(no_mangle)]
pub extern "C" fn rt_no_throw_div_zero_addr() -> u32 {
    nls::no_throw_div_zero_addr() as u32
}

/// The slow half of C's `__OMC_DIV_SIM` (util/division.h): the emitted code divides
/// and calls here only for a zero divisor or a non-finite result. `msg` is the
/// divisor's source form, borrowed from the module's literal pool.
#[unsafe(no_mangle)]
pub extern "C" fn rt_div_sim(a: f64, b: f64, msg: u32, time: f64, initial: i32) -> f64 {
    use openmodelica_sim_meta::driver::format_g;
    let s = borrowed_str(msg);
    let res = if b != 0.0 {
        a / b
    } else if initial != 0 && a == 0.0 {
        // C's 0/0 at initialization is zero, not the nan that would go on to fail a
        // domain check somewhere downstream.
        return 0.0;
    } else if no_throw_div_zero() {
        crate::omclog::warning(
            crate::omclog::DIVISION,
            false,
            &alloc::format!(
                "solver will try to handle division by zero at time {}: {s}",
                format_g(time, 16)
            ),
        );
        a / b
    } else {
        throw_stream(&alloc::format!(
            "division by zero at time {}, (a={}) / (b={}), where divisor b expression is: {s}",
            format_g(time, 16),
            format_g(a, 16),
            format_g(b, 16)
        ));
        a / b
    };
    if !res.is_finite() {
        let m = alloc::format!(
            "division leads to inf or nan at time {}, (a={}) / (b={}), where divisor b is: {s}",
            format_g(time, 6),
            format_g(a, 6),
            format_g(b, 6)
        );
        if no_throw_div_zero() {
            crate::omclog::warning(crate::omclog::DIVISION, false, &m);
        } else {
            throw_stream(&m);
        }
    }
    res
}

/// Build the Jacobian-assemble closure used by both kinsol and newton sparse paths.
/// `gather` is the pattern block where `jac` fills a dense `n×n` rather than the CSC
/// values — a system `-nls=kinsol` solves sparsely though the codegen chose dense.
fn make_assemble<'a>(
    n: usize,
    jac: &'a mut dyn FnMut(&[f64], &mut [f64]),
    gather: Option<alloc::vec::Vec<u32>>,
) -> impl FnMut(&[f64], &mut [f64]) + 'a {
    // The model's own buffer: the CSC values, or the dense matrix `gather` reads.
    let mut raw = vec![0.0f64; if gather.is_some() { n * n } else { 0 }];
    move |xs: &[f64], vals: &mut [f64]| match &gather {
        Some(pat) => {
            jac(xs, &mut raw);
            for c in 0..n {
                for k in pat[c] as usize..pat[c + 1] as usize {
                    let row = pat[n + 1 + k] as usize;
                    vals[k] = raw[c * n + row];
                }
            }
        }
        None => jac(xs, vals),
    }
}


/// `-nlsLS`: which backend the linear solve inside the sparse nonlinear solver
/// runs on. C's `totalpivot`/`lapack` have no sparse implementation here, so they
/// fall to `rsparse` alongside an unlinked KLU.
fn nls_ls_backend() -> solverflags::Sparse {
    match solverflags::nls_ls() {
        solverflags::NlsLs::Klu => solverflags::Sparse::Klu,
        _ => solverflags::Sparse::Rsparse,
    }
}

/// Count at `count_addr`, then `HIST_DEPTH` × (time, `n` values) from `base`.
struct MemHistory {
    count_addr: u32,
    base: u32,
    n: usize,
}

impl MemHistory {
    fn entry(&self, k: usize) -> u32 {
        self.base + (k * (8 + self.n * 8)) as u32
    }
}

impl History for MemHistory {
    fn len(&self) -> usize {
        (unsafe { load_u32(self.count_addr) } as usize).min(HIST_DEPTH)
    }
    fn time(&self, k: usize) -> f64 {
        unsafe { load_f64(self.entry(k)) }
    }
    fn value(&self, k: usize, i: usize) -> f64 {
        unsafe { load_f64(self.entry(k) + 8 + (i * 8) as u32) }
    }
    fn shift(&mut self, from: usize, to: usize) {
        let (src, dst) = (self.entry(from), self.entry(to));
        for b in 0..(1 + self.n) as u32 {
            unsafe { store_f64(dst + b * 8, load_f64(src + b * 8)) };
        }
    }
    fn put(&mut self, k: usize, len: usize, time: f64, x: &[f64]) {
        let at = self.entry(k);
        unsafe { store_f64(at, time) };
        for (i, v) in x.iter().enumerate() {
            unsafe { store_f64(at + 8 + (i * 8) as u32, *v) };
        }
        unsafe { store_u32(self.count_addr, len as u32) };
    }
    fn set_len(&mut self, len: usize) {
        unsafe { store_u32(self.count_addr, len as u32) };
    }
}

/// C's `simulationInfo->nonlinearSystemData`: each system's (state address, size),
/// filled by the module `start`.
struct RosterCell(UnsafeCell<alloc::vec::Vec<(u32, usize)>>);
// Single-threaded wasm: no concurrent access.
unsafe impl Sync for RosterCell {}
static ROSTER: RosterCell = RosterCell(UnsafeCell::new(alloc::vec::Vec::new()));

/// `k == 0` starts a fresh roster, so a second model replaces the first.
#[unsafe(no_mangle)]
pub extern "C" fn rt_nls_register(k: u32, hist_addr: u32, n: u32) {
    let roster = unsafe { &mut *ROSTER.0.get() };
    roster.truncate(k as usize);
    roster.push((hist_addr, n as usize));
}

/// C's `sysNumber`: the index in `nonlinearSystemData` the homotopy messages quote
/// (not the equation index). The roster is registered in that order.
fn nls_sys_number(hist_addr: u32) -> u32 {
    let roster = unsafe { &*ROSTER.0.get() };
    roster.iter().position(|(h, _)| *h == hist_addr).unwrap_or(0) as u32
}

/// [`set_var_names`] across the module boundary: `ptr`/`len` are a NUL-separated
/// UTF-8 list. `eq_index == u32::MAX` clears the roster.
#[unsafe(no_mangle)]
pub extern "C" fn rt_nls_set_names(eq_index: u32, ptr: u32, len: u32) {
    if eq_index == u32::MAX {
        nls::clear_names();
        return;
    }
    let bytes = unsafe { core::slice::from_raw_parts(ptr as *const u8, len as usize) };
    let list = bytes
        .split(|b| *b == 0)
        .filter(|s| !s.is_empty())
        .map(|s| alloc::string::String::from_utf8_lossy(s).into_owned())
        .collect();
    nls::push_var_names(eq_index, list);
}

/// What `-lv=LOG_NLS_NEWTON_DIAGNOSTICS` needs per system beyond the names.
/// `eqns` is `len` little-endian u32 at `ptr` in this module's memory;
/// `eq_index == u32::MAX` clears the roster.
#[unsafe(no_mangle)]
pub extern "C" fn rt_nls_set_diag(eq_index: u32, n_eqns: u32, n_vars: u32, n_nonlinear: u32, init_diag: u32, ptr: u32, len: u32) {
    if eq_index == u32::MAX {
        nls::clear_diag();
        return;
    }
    let eqns = (0..len).map(|i| unsafe { load_u32(ptr + 4 * i) }).collect();
    nls::push_diag(
        eq_index,
        DiagInfo { pattern: [n_eqns, n_vars, n_nonlinear], init_diag: init_diag != 0, eqns },
    );
}

/// [`rt_nls_set_diag`] for a driver in the same module.
pub(crate) fn set_diag(systems: &[openmodelica_sim_meta::NlsVars]) {
    nls::set_diag(
        systems
            .iter()
            .map(|s| {
                (
                    s.eq_index,
                    DiagInfo {
                        pattern: s.pattern,
                        init_diag: s.init_diag,
                        eqns: s.eqns.iter().map(|e| *e as u32).collect(),
                    },
                )
            })
            .collect(),
    )
}

/// C's `cleanUpOldValueListAfterEvent`, called once per event.
#[unsafe(no_mangle)]
pub extern "C" fn rt_nls_clean_history(time: f64) {
    for &(addr, n) in unsafe { &*ROSTER.0.get() } {
        let mut hist = MemHistory { count_addr: addr, base: addr + 16 + 2 * (n * 8) as u32, n };
        history_clean(&mut hist, time);
    }
}

/// The norm below which C accepts a less accurate solution rather than failing
/// (`FTOL_WITH_LESS_ACCURACY`). KINSOL's own stopping tolerances are C's
/// `newtonFTol`/`newtonXTol`, i.e. [`newton_ftol`]/[`newton_xtol`].
const KIN_FTOL_LESS_ACCURACY: f64 = 1.0e-6;

/// `‖diag(scale)·v‖∞`, the norm KINSOL's stopping tests use.
fn scaled_max_norm(v: &[f64], scale: &[f64]) -> f64 {
    let mut m = 0.0f64;
    for (a, s) in v.iter().zip(scale) {
        let t = libm::fabs(a * s);
        if !(t <= m) {
            m = t;
        }
    }
    m
}

/// The sparse nonlinear solver a system with an analytic sparsity pattern gets, as
/// in C: KINSOL over the Jacobian assembled straight into CSC, factorized by KLU.
/// [`newton_sparse_solve`] stands in for it where SUNDIALS is not linked in, and
/// serves `-nlsLS=rsparse`. `pattern` is `colptr[n+1] ++ rowidx[nnz]`.
#[allow(clippy::too_many_arguments)]
fn kinsol_sparse_solve(
    n: usize,
    x: &mut [f64],
    guess: &[f64],
    warm: &[f64],
    nominal: &[f64],
    jac: &mut dyn FnMut(&[f64], &mut [f64]),
    pattern: &[u32],
    nnz: usize,
    jac_csc: bool,
    handle: u32,
    eq_index: u32,
    time: f64,
    has_jacobian: bool,
    old_values: &[f64],
    load_guess: &mut dyn FnMut(&mut [f64]),
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    #[cfg(sundials)]
    if nls_ls_backend() == solverflags::Sparse::Klu {
        // C's retry ladder re-picks the start point, but only through settings its
        // loop head overrides; `warm` is the caller's own second attempt.
        let colptr: alloc::vec::Vec<i32> = pattern[..n + 1].iter().map(|v| *v as i32).collect();
        let rowidx: alloc::vec::Vec<i32> =
            pattern[n + 1..n + 1 + nnz].iter().map(|v| *v as i32).collect();
        let gather = (!jac_csc).then(|| pattern.to_vec());
        let mut assemble = make_assemble(n, jac, gather);
        return crate::sundials::kinsol_solve_selected(
            handle, n, nnz, &colptr, &rowidx, nominal, guess, old_values, x, eq_index, time,
            has_jacobian, load_guess, eval, &mut assemble,
        );
    }
    // only the KINSOL path names the system it dumps, or differences its own Jacobian
    let _ = (eq_index, time, has_jacobian, old_values);
    let _ = load_guess; // only the KINSOL-B rung re-reads the model's own values
    newton_sparse_solve(n, x, guess, warm, nominal, jac, pattern, nnz, jac_csc, handle, eval)
}

/// C's `-nls=experimental-kinsol` on a system with no sparsity pattern: the dense
/// linear solver, and the analytic Jacobian only where the model emits one.
#[allow(clippy::too_many_arguments)]
fn kinsol_b_dense_solve(
    n: usize,
    x: &mut [f64],
    nominal: &[f64],
    old_values: &[f64],
    has_jac: bool,
    handle: u32,
    eq_index: u32,
    time: f64,
    load_guess: &mut dyn FnMut(&mut [f64]),
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    jaceval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    #[cfg(sundials)]
    {
        let start = x.to_vec();
        return crate::sundials::kinsol_b_solve(
            handle, n, 0, None, nominal, &start, old_values, x, eq_index, time, load_guess, eval,
            has_jac.then_some(jaceval),
        );
    }
    #[cfg(not(sundials))]
    {
        let _ = (n, x, nominal, old_values, has_jac, handle, eq_index, time, load_guess, eval, jaceval);
        false
    }
}

/// A scaled Newton iteration with a line search over the same CSC Jacobian, using
/// the runtime's own sparse LU: KINSOL's scaling (`xScale[i] = 1/max(nominal_i,
/// |x_i|)`, `fScale[i] = 1/max_j |J_ij / xScale_j|`) and stopping tests, with C's
/// retry ladder approximated by five start-point / scaling / line-search variations.
#[allow(clippy::too_many_arguments)]
fn newton_sparse_solve(
    n: usize,
    x: &mut [f64],
    guess: &[f64],
    warm: &[f64],
    nominal: &[f64],
    jac: &mut dyn FnMut(&[f64], &mut [f64]),
    pattern: &[u32],
    nnz: usize,
    jac_csc: bool,
    handle: u32,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    let colptr: alloc::vec::Vec<usize> = (0..=n).map(|k| pattern[k] as usize).collect();
    let rowidx: alloc::vec::Vec<usize> = (0..nnz).map(|k| pattern[n + 1 + k] as usize).collect();
    // `lin_sparse_cached` addresses its arguments in linear memory, so the pattern
    // and the per-iteration values/right-hand side are staged there. The pattern is
    // written once; only `vals` and `b` move per iteration.
    let colptr_addr = rt_alloc(((n + 1) * 4) as u32);
    let rowidx_addr = rt_alloc((nnz * 4) as u32);
    let val_ptr = rt_alloc((nnz * 8) as u32);
    let b_ptr = rt_alloc((n * 8) as u32);
    for (k, v) in colptr.iter().enumerate() {
        unsafe { store_u32(colptr_addr + (k * 4) as u32, *v as u32) };
    }
    for (k, v) in rowidx.iter().enumerate() {
        unsafe { store_u32(rowidx_addr + (k * 4) as u32, *v as u32) };
    }

    let mut vals = vec![0.0f64; nnz];
    let gather = (!jac_csc).then(|| pattern.to_vec());
    let mut assemble = make_assemble(n, jac, gather);

    let mut f = vec![0.0f64; n];
    let mut xscale = vec![1.0f64; n];
    let mut fscale = vec![1.0f64; n];
    let mut xnew = vec![0.0f64; n];
    let mut dx = vec![0.0f64; n];

    // `(start from the last accepted values, scaled, line search)` per attempt;
    // attempt 0 is kinsol's configured default, the rest are C's retry ladder.
    const ATTEMPTS: [(bool, bool, bool); 5] = [
        (false, true, true),
        (false, false, true),
        (true, true, true),
        (false, true, false),
        (true, false, true),
    ];
    let mut solved = false;
    for &(from_warm, scaled, linesearch) in ATTEMPTS.iter() {
        x.copy_from_slice(if from_warm { warm } else { guess });
        for i in 0..n {
            xscale[i] = if scaled { 1.0 / libm::fmax(nominal[i], libm::fabs(x[i])) } else { 1.0 };
        }
        // f scaling from the column-scaled Jacobian at the entry point.
        for s in fscale.iter_mut() {
            *s = 1.0;
        }
        if scaled {
            assemble(x, &mut vals);
            let mut rowmax = vec![1.0e-12f64; n];
            for c in 0..n {
                for k in colptr[c]..colptr[c + 1] {
                    let v = libm::fabs(vals[k] / xscale[c]);
                    if v > rowmax[rowidx[k]] {
                        rowmax[rowidx[k]] = v;
                    }
                }
            }
            for i in 0..n {
                fscale[i] = 1.0 / rowmax[i];
            }
        }

        eval(x, &mut f);
        let mut fnorm = scaled_max_norm(&f, &fscale);
        for _ in 0..100 * n {
            if !fnorm.is_finite() {
                break;
            }
            if fnorm <= solverflags::newton_ftol() {
                solved = true;
                break;
            }
            assemble(x, &mut vals);
            for (k, v) in vals.iter().enumerate() {
                unsafe { store_f64(val_ptr + (k * 8) as u32, *v) };
            }
            for i in 0..n {
                unsafe { store_f64(b_ptr + (i * 8) as u32, -f[i]) };
            }
            if crate::lin_sparse_cached(
                handle, colptr_addr, rowidx_addr, val_ptr, b_ptr, n as u32, nnz as u32,
                nls_ls_backend(),
            ) != 0
            {
                break; // singular: next attempt
            }
            for i in 0..n {
                dx[i] = unsafe { load_f64(b_ptr + (i * 8) as u32) };
            }
            // Damped step: halve until the scaled residual improves (kinsol's
            // KIN_LINESEARCH; KIN_NONE takes the full step).
            let mut lambda = 1.0f64;
            let mut fnew;
            loop {
                for i in 0..n {
                    xnew[i] = x[i] + lambda * dx[i];
                }
                eval(&xnew, &mut f);
                fnew = scaled_max_norm(&f, &fscale);
                if !linesearch || fnew < fnorm || lambda <= LAMBDA_MIN {
                    break;
                }
                lambda *= 0.5;
            }
            // KIN_STEP_LT_STPTOL: a step this small cannot improve the iterate.
            let mut step = 0.0f64;
            for i in 0..n {
                let d = libm::fabs(lambda * dx[i]) / libm::fmax(libm::fabs(x[i]), 1.0 / xscale[i]);
                if !(d <= step) {
                    step = d;
                }
            }
            x.copy_from_slice(&xnew);
            fnorm = fnew;
            if step <= solverflags::newton_xtol() {
                solved = fnorm < KIN_FTOL_LESS_ACCURACY;
                break;
            }
        }
        if !solved && fnorm.is_finite() && fnorm < KIN_FTOL_LESS_ACCURACY {
            // C's "move forward with a less accurate solution".
            solved = true;
        }
        if solved {
            break;
        }
    }
    rt_free(b_ptr);
    rt_free(val_ptr);
    rt_free(rowidx_addr);
    rt_free(colptr_addr);
    solved
}

/// The wasm-jit runtime's [`NlsModel`]: the four entry points are
/// `__indirect_function_table` indices exchanging values through linear memory.
struct WasmModel {
    sim_data: u32,
    res_idx: u32,
    load_idx: u32,
    jac_idx: u32,
    strict_idx: u32,
    /// Scratch for the unknowns, residuals and Jacobian; freed by `rt_solve_nls`.
    x_ptr: u32,
    r_ptr: u32,
    jac_ptr: u32,
}

impl WasmModel {
    fn put(&self, x: &[f64]) {
        for (i, v) in x.iter().enumerate() {
            unsafe { store_f64(self.x_ptr + (i * 8) as u32, *v) };
        }
    }
}

impl NlsModel for WasmModel {
    fn load_guess(&mut self, x: &mut [f64]) {
        let load: extern "C" fn(u32, u32) = unsafe { core::mem::transmute(self.load_idx as usize) };
        load(self.sim_data, self.x_ptr);
        for (i, v) in x.iter_mut().enumerate() {
            *v = unsafe { load_f64(self.x_ptr + (i * 8) as u32) };
        }
    }

    fn residual(&mut self, x: &[f64], r: &mut [f64]) {
        let residual: extern "C" fn(u32, u32, u32) =
            unsafe { core::mem::transmute(self.res_idx as usize) };
        // A system with no unknowns has no buffers; C passes null there too.
        if x.is_empty() && r.is_empty() {
            residual(self.sim_data, 0, 0);
            return;
        }
        self.put(x);
        residual(self.sim_data, self.x_ptr, self.r_ptr);
        for (i, v) in r.iter_mut().enumerate() {
            *v = unsafe { load_f64(self.r_ptr + (i * 8) as u32) };
        }
    }

    fn jacobian(&mut self, x: &[f64], out: &mut [f64]) {
        let jacf: extern "C" fn(u32, u32, u32) =
            unsafe { core::mem::transmute(self.jac_idx as usize) };
        self.put(x);
        jacf(self.sim_data, self.x_ptr, self.jac_ptr);
        for (k, v) in out.iter_mut().enumerate() {
            *v = unsafe { load_f64(self.jac_ptr + (k * 8) as u32) };
        }
    }

    fn strict_fallback(&mut self) -> bool {
        let strict: extern "C" fn(u32) -> i32 =
            unsafe { core::mem::transmute(self.strict_idx as usize) };
        strict(self.sim_data) != 0
    }
}

/// The wasm-jit runtime's [`NlsState`]: every flag is a `SimData` slot.
struct WasmState {
    nls_fail_addr: u32,
    rel_fresh_addr: u32,
    rel_addr: u32,
    n_rel: u32,
    lambda_addr: u32,
}

impl NlsState for WasmState {
    fn relation_mode(&self) -> u32 {
        unsafe { load_u32(self.rel_fresh_addr) }
    }
    fn set_relation_mode(&mut self, mode: u32) {
        unsafe { store_u32(self.rel_fresh_addr, mode) };
    }
    fn relations(&self, out: &mut [i32]) {
        for (i, v) in out.iter_mut().enumerate() {
            *v = unsafe { load_u32(self.rel_addr + (i * 4) as u32) } as i32;
        }
    }
    fn relation_count(&self) -> usize {
        self.n_rel as usize
    }
    fn lambda(&self) -> f64 {
        if self.lambda_addr == 0 { 1.0 } else { unsafe { load_f64(self.lambda_addr) } }
    }
    fn set_lambda(&mut self, v: f64) {
        if self.lambda_addr != 0 {
            unsafe { store_f64(self.lambda_addr, v) };
        }
    }
    fn note_failure(&mut self, eq_index: u32) {
        // First-writer-wins: C throws out of the equation list at the first
        // failure and never reports a later one.
        unsafe {
            if load_u32(self.nls_fail_addr) == 0 {
                store_u32(self.nls_fail_addr, eq_index + 1);
            }
        }
    }
}

/// The wasm-jit runtime's KINSOL and sparse-Newton solvers.
struct WasmBackend<'a> {
    pattern: &'a [u32],
    nnz: usize,
    jac_csc: bool,
    handle: u32,
}

impl NlsBackend for WasmBackend<'_> {
    /// Always real: without SUNDIALS `kinsol_sparse_solve` falls back to
    /// `newton_sparse_solve` over the same pattern.
    fn has_sparse(&self) -> bool {
        true
    }

    /// `-nls=kinsol_b` on a dense system, which without SUNDIALS has no stand-in and
    /// fails the attempt. Answering `true` regardless is what this runtime did
    /// before the flag existed; saying `cfg!(sundials)` would send such a run down
    /// the dense ladder instead, which is a behaviour change for a flag no test
    /// combines with a build that has no archives.
    fn has_kinsol(&self) -> bool {
        true
    }

    fn solve_sparse(
        &mut self,
        req: NlsRequest,
        load_guess: &mut dyn FnMut(&mut [f64]),
        eval: &mut dyn FnMut(&[f64], &mut [f64]),
        jac: &mut dyn FnMut(&[f64], &mut [f64]),
    ) -> bool {
        kinsol_sparse_solve(
            req.n, req.x, req.guess, req.warm, req.nominal, jac, self.pattern, self.nnz,
            self.jac_csc, self.handle, req.eq_index, req.time, req.has_jacobian, req.old_values,
            load_guess, eval,
        )
    }

    fn solve_kinsol_dense(
        &mut self,
        req: NlsRequest,
        load_guess: &mut dyn FnMut(&mut [f64]),
        eval: &mut dyn FnMut(&[f64], &mut [f64]),
        jac: &mut dyn FnMut(&[f64], &mut [f64]),
    ) -> bool {
        kinsol_b_dense_solve(
            req.n, req.x, req.nominal, req.old_values, req.has_jacobian, self.handle, req.eq_index,
            req.time, load_guess, eval, jac,
        )
    }
}

/// The per-system block the codegen reserved (`nls_hist_bytes`):
/// `count: u32 (padded to 8) | lastTimeSolved: f64 | resScaling[n] |
/// nlsxExtrapolation[n] | HIST_DEPTH × (time: f64, x[n])`. [`MemHistory`] is the
/// [`History`] over its tail.
struct MemBlock {
    hist_addr: u32,
    n: usize,
}

impl MemBlock {
    fn last_solved(&self) -> u32 {
        self.hist_addr + 8
    }
    fn scale(&self) -> u32 {
        self.hist_addr + 16
    }
    fn extrap(&self) -> u32 {
        self.scale() + (self.n * 8) as u32
    }
    fn read(&self, at: u32, out: &mut [f64]) {
        for (i, v) in out.iter_mut().enumerate() {
            *v = unsafe { load_f64(at + (i * 8) as u32) };
        }
    }
    fn write(&self, at: u32, v: &[f64]) {
        for (i, x) in v.iter().enumerate() {
            unsafe { store_f64(at + (i * 8) as u32, *x) };
        }
    }
}

/// The `SES_NONLINEAR` entry point the emitted module calls: the wasm ABI --
/// table indices and linear-memory addresses -- marshalled into [`solve_nls`].
#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub extern "C" fn rt_solve_nls(
    sim_data: u32,
    res_idx: u32,
    load_idx: u32,
    n: u32,
    nls_fail_addr: u32,
    hist_addr: u32,
    time: f64,
    rel_fresh_addr: u32,
    nominal_addr: u32,
    bounds_addr: u32,
    jac_idx: u32,
    rel_addr: u32,
    n_rel: u32,
    mixed: u32,
    pat_addr: u32,
    nnz: u32,
    sparse_default: u32,
    lss_handle: u32,
    eq_index: u32,
    hom_support: u32,
    hom_method: u32,
    lambda_addr: u32,
    strict_idx: u32,
) -> i32 {
    install_hooks();
    let size = n as usize;
    let has_jacobian = jac_idx != u32::MAX;
    // The residual count -- one less than the unknowns where an adaptive homotopy
    // carries `__HOM_LAMBDA` -- which is what the history block is sized by.
    let lambda_unknown = hom_support != 0
        && (hom_method == HOM_GLOBAL_ADAPTIVE || hom_method == HOM_LOCAL_ADAPTIVE)
        && size > 1;
    let hist_n = size - usize::from(lambda_unknown);
    // The shape the model fills, as [`solve_nls`] reads it back.
    let jac_len = if has_jacobian && !lambda_unknown && sparse_default != 0 {
        nnz as usize
    } else {
        hist_n * size
    };
    let mut model = WasmModel {
        sim_data,
        res_idx,
        load_idx,
        jac_idx,
        strict_idx,
        x_ptr: rt_alloc(((size + 1) * 8) as u32),
        r_ptr: rt_alloc((size.max(1) * 8) as u32),
        jac_ptr: if has_jacobian { rt_alloc((jac_len.max(1) * 8) as u32) } else { 0 },
    };
    let mut state =
        WasmState { nls_fail_addr, rel_fresh_addr, rel_addr, n_rel, lambda_addr };

    let mut nominal = vec![0.0f64; size];
    for (i, v) in nominal.iter_mut().enumerate() {
        *v = unsafe { load_f64(nominal_addr + (i * 8) as u32) };
    }
    let mut bounds = vec![0.0f64; 2 * size];
    for (i, v) in bounds.iter_mut().enumerate() {
        *v = unsafe { load_f64(bounds_addr + (i * 8) as u32) };
    }
    let pattern: alloc::vec::Vec<u32> = if has_jacobian && nnz != 0 {
        (0..size + 1 + nnz as usize).map(|k| unsafe { load_u32(pat_addr + (k * 4) as u32) }).collect()
    } else {
        alloc::vec::Vec::new()
    };

    let block = MemBlock { hist_addr, n: hist_n };
    let mut res_scaling = vec![0.0f64; hist_n];
    let mut extrapolation = vec![0.0f64; hist_n];
    block.read(block.scale(), &mut res_scaling);
    block.read(block.extrap(), &mut extrapolation);
    let mut last_solved = unsafe { load_f64(block.last_solved()) };
    let mut hist =
        MemHistory { count_addr: hist_addr, base: block.extrap() + (hist_n * 8) as u32, n: hist_n };

    let spec = NlsSpec {
        eq_index,
        size,
        time,
        casual: strict_idx != u32::MAX,
        mixed: mixed != 0,
        hom_support: hom_support != 0,
        hom_method,
        nnz,
        jac_csc: sparse_default != 0,
        sys_num: nls_sys_number(hist_addr),
        nominal: &nominal,
        bounds: &bounds,
        pattern: &pattern,
        has_jacobian,
    };
    let mut backend =
        WasmBackend { pattern: &pattern, nnz: nnz as usize, jac_csc: sparse_default != 0, handle: lss_handle };
    let ret = {
        let mut mem = NlsPersistent {
            history: &mut hist,
            res_scaling: &mut res_scaling,
            extrapolation: &mut extrapolation,
            last_solved: &mut last_solved,
        };
        solve_nls(&spec, &mut model, &mut state, &mut mem, &mut backend)
    };
    block.write(block.scale(), &res_scaling);
    block.write(block.extrap(), &extrapolation);
    unsafe { store_f64(block.last_solved(), last_solved) };

    rt_free(model.x_ptr);
    rt_free(model.r_ptr);
    if has_jacobian {
        rt_free(model.jac_ptr);
    }
    ret
}
