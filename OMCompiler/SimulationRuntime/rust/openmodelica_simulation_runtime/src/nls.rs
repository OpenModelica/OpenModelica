//! Nonlinear systems: `initializeNonlinearSystems`, `solve_nonlinear_system` and
//! `check_nonlinear_solutions`, over [`openmodelica_nls`].
//!
//! Port of `nonlinearSystem.c`'s bookkeeping only — the solver ladder under it is
//! the shared one, reached through the same `NlsModel` / `NlsState` /
//! `NlsPersistent` / `NlsBackend` seam the wasm-jit runtime supplies. What this
//! file adds is the `NONLINEAR_SYSTEM_DATA` side of that seam: the model's entry
//! points, the relation mode as C's `discreteCall`/`solveContinuous` pair, the
//! stored solutions C keeps in `oldValueList`, and the system's sparsity pattern
//! for `openmodelica_nls::kinsol`.

use core::ffi::{c_int, c_void};

use openmodelica_nls as nls;
use openmodelica_sim_meta::driver;
use openmodelica_solvers::{omclog, simflags, solverflags};

use crate::abi::*;
use crate::systems::eval_jacobian;

/// The error stage a model call from the solver runs at: C's
/// `ERROR_NONLINEARSOLVER` inside `solve_nonlinear_system`'s own region -- which
/// makes a violated assertion a note rather than the end of the run -- and the
/// caller's stage before it, where C's `updateInnerEquation` still reports.
fn stage(outer: c_int) -> c_int {
    if nls::error_stage() == nls::ERROR_NONLINEARSOLVER {
        crate::support::error_stage::NONLINEARSOLVER
    } else {
        outer
    }
}

/// The driver's failed-system slot (`Layout::nls_fail_off`): the equation index
/// plus one of the first system a pass could not solve, 0 for none. Mapped into the
/// layout by `data::build_regions`.
pub static mut nls_fail_slot: i32 = 0;

/// `NLS_SOLVER_STATUS` (simulation_data.h).
const NLS_FAILED: c_int = 0;
const NLS_SOLVED: c_int = 1;

/// C's `enum JACOBIAN_MATRIX_FORMAT` (simulation_data.h).
const OMC_MATRIX_SPARSE: c_int = 1;

/// The per-system state C spreads over `oldValueList` and its solver data.
struct Scratch {
    /// The system's sparsity pattern as CSC, which the sparse solvers keep
    /// addressing for the whole run: `colptr[size + 1]` and `rowidx[nnz]`.
    colptr: Vec<i32>,
    rowidx: Vec<i32>,
    /// The same as the shared solver wants it, `colptr ++ rowidx`, for the dense
    /// ladder's scatter.
    pattern: Vec<u32>,
    /// C's `oldValueList`, as the depth the shared solver bounds it to.
    history: VecHistory,
    /// `solveHomotopy`'s residual scaling, which survives between calls.
    res_scaling: Vec<f64>,
}

/// [`nls::History`] over a plain `Vec`: C's list is unbounded and reaches 40+, but
/// the entry `getValues` picks is never past 5.
#[derive(Default)]
struct VecHistory {
    entries: Vec<(f64, Vec<f64>)>,
}

impl nls::History for VecHistory {
    fn len(&self) -> usize {
        self.entries.len()
    }
    fn time(&self, k: usize) -> f64 {
        self.entries[k].0
    }
    fn value(&self, k: usize, i: usize) -> f64 {
        self.entries[k].1[i]
    }
    fn shift(&mut self, from: usize, to: usize) {
        if to == self.entries.len() {
            let e = self.entries[from].clone();
            self.entries.push(e);
        } else {
            self.entries[to] = self.entries[from].clone();
        }
    }
    fn put(&mut self, k: usize, len: usize, time: f64, x: &[f64]) {
        if k == self.entries.len() {
            self.entries.push((time, x.to_vec()));
        } else {
            self.entries[k] = (time, x.to_vec());
        }
        self.entries.truncate(len);
    }
    fn set_len(&mut self, len: usize) {
        self.entries.truncate(len);
    }
}

fn scratch(sys: &NONLINEAR_SYSTEM_DATA) -> *mut Scratch {
    sys.solverData as *mut Scratch
}

// ---------------------------------------------------------------------------
// The model side of the seam
// ---------------------------------------------------------------------------

unsafe extern "C" {
    /// `residualFunc` under `threadData`'s jump buffer, so a violated assertion in
    /// the model comes back as -1 instead of unwinding past Rust frames.
    fn omr_protected_residual(
        f: unsafe extern "C" fn(*mut RESIDUAL_USERDATA, *const f64, *mut f64, *const c_int),
        user: *mut RESIDUAL_USERDATA,
        x: *const f64,
        r: *mut f64,
        flag: *const c_int,
        thread_data: *mut threadData_t,
        stage: c_int,
    ) -> c_int;
    /// The casual tearing set's variant, whose return value is C's `f_con`.
    fn omr_protected_residual_con(
        f: unsafe extern "C" fn(*mut RESIDUAL_USERDATA, *const f64, *mut f64, *const c_int) -> c_int,
        user: *mut RESIDUAL_USERDATA,
        x: *const f64,
        r: *mut f64,
        flag: *const c_int,
        thread_data: *mut threadData_t,
        stage: c_int,
    ) -> c_int;
}

/// C's `NONLINEAR_SYSTEM_DATA` function pointers as the solver's [`nls::NlsModel`].
struct CModel {
    data: *mut DATA,
    thread_data: *mut threadData_t,
    sys: *mut NONLINEAR_SYSTEM_DATA,
    /// Rows of the dense Jacobian, which is C's `min(sizeRows, sizeCols)`.
    jac_rows: usize,
    /// The shape `jacobian` fills: the pattern's CSC values where the backend chose
    /// a sparse factorization, else a dense column-major matrix.
    csc: bool,
    /// `threadData->currentErrorStage` at entry, C's `saveJumpState`.
    outer_stage: c_int,
}

impl CModel {
    fn sys(&self) -> &mut NONLINEAR_SYSTEM_DATA {
        unsafe { &mut *self.sys }
    }
}

impl nls::NlsModel for CModel {
    fn load_guess(&mut self, x: &mut [f64]) {
        let Some(f) = self.sys().getIterationVars else { return };
        // The generated function writes `size` values -- `__HOM_LAMBDA` included on
        // a homotopy system whose solver asks for the residual-count many.
        let size = self.sys().size.max(0) as usize;
        if x.len() < size {
            let mut full = vec![0.0f64; size];
            self.load_guess(&mut full);
            x.copy_from_slice(&full[..x.len()]);
            return;
        }
        let (data, p) = (self.data, x.as_mut_ptr());
        crate::support::protected(self.thread_data, stage(self.outer_stage), || unsafe { f(data, p) });
    }

    fn residual(&mut self, x: &[f64], r: &mut [f64]) {
        let sys = self.sys();
        // The generated residual writes `size` values (its inf/nan guard fills them
        // all), one more than a homotopy system has residuals.
        let size = sys.size.max(0) as usize;
        if r.len() < size {
            let mut full = vec![0.0f64; size];
            self.residual(x, &mut full);
            r.copy_from_slice(&full[..r.len()]);
            return;
        }
        let mut user = RESIDUAL_USERDATA {
            data: self.data,
            threadData: self.thread_data,
            solverData: core::ptr::null_mut(),
        };
        // C passes `&nonlinsys->size` as the flag; the generated residual reads it
        // only where it distinguishes the residual from the Jacobian call.
        let flag: c_int = 1;
        // A casual tearing set's residual is the constraint-checking one, whose
        // return value is C's `f_con`: 1 means this trial violated a local
        // constraint and the solver should fall back to the strict set.
        let stage = stage(self.outer_stage);
        let con = sys.residualFuncConstraints.filter(|_| sys.strictTearingFunctionCall.is_some());
        let rc = match (con, sys.residualFunc) {
            (Some(f), _) => unsafe {
                omr_protected_residual_con(
                    f, &mut user, x.as_ptr(), r.as_mut_ptr(), &flag, self.thread_data, stage,
                )
            },
            (None, Some(f)) => unsafe {
                omr_protected_residual(
                    f, &mut user, x.as_ptr(), r.as_mut_ptr(), &flag, self.thread_data, stage,
                )
            },
            (None, None) => return,
        };
        if rc == -1 {
            // The message is already on the log, from the assert itself. Recording
            // the hit is what turns this trial into a rejected one, exactly as the
            // wasm model's `rt_nls_note_assert` does.
            nls::note_assert();
        } else if rc != 0 {
            nls::dt_note_violated();
        }
    }

    fn jacobian(&mut self, x: &[f64], out: &mut [f64]) {
        // C's `getAnalyticalJacobian` evaluates the residual at `x` first, so the
        // Jacobian columns are taken at the point they belong to.
        let mut discard = vec![0.0f64; self.sys().size.max(0) as usize];
        self.residual(x, &mut discard);
        let si = unsafe { &*(*self.data).simulationInfo };
        let sys = self.sys();
        let jacobian = unsafe { si.analyticJacobians.add(sys.jacobianIndex.max(0) as usize) };
        let dense = !self.csc;
        match eval_jacobian(self.data, self.thread_data, jacobian, core::ptr::null_mut(), out, dense) {
            Ok(()) => {}
            // The model raised an error at this trial: the solver voids it, exactly
            // as it does for one raised in the residual.
            Err(e) if e == crate::systems::MODEL_THREW => {
                nls::note_assert();
                out.fill(0.0);
            }
            Err(e) => {
                omclog::warning(omclog::STDOUT, false, e);
                out.fill(0.0);
            }
        }
    }

    fn strict_fallback(&mut self) -> bool {
        let Some(f) = self.sys().strictTearingFunctionCall else { return false };
        let (data, td) = (self.data, self.thread_data);
        let mut ok = false;
        if !crate::support::protected(td, stage(self.outer_stage), || ok = unsafe { f(data, td) != 0 }) {
            nls::note_assert();
            return false;
        }
        ok
    }
}

/// The run's flags and relation state as [`nls::NlsState`].
struct CState {
    data: *mut DATA,
    sys: *mut NONLINEAR_SYSTEM_DATA,
}

impl CState {
    fn info(&self) -> &mut SIMULATION_INFO {
        unsafe { &mut *(*self.data).simulationInfo }
    }
}

impl nls::NlsState for CState {
    fn relation_mode(&self) -> u32 {
        let si = self.info();
        if si.solveContinuous != 0 {
            0
        } else if si.initial != 0 {
            2
        } else {
            u32::from(si.discreteCall != 0)
        }
    }

    fn set_relation_mode(&mut self, mode: u32) {
        // The pair `relationhysteresis` branches on: held relations are
        // `solveContinuous`, fresh ones `discreteCall`.
        let si = self.info();
        si.solveContinuous = (mode == 0) as modelica_boolean;
        si.discreteCall = (mode != 0) as modelica_boolean;
    }

    fn relations(&self, out: &mut [i32]) {
        let si = self.info();
        for (i, v) in out.iter_mut().enumerate() {
            *v = unsafe { *si.relations.add(i) } as i32;
        }
    }

    fn relation_count(&self) -> usize {
        let md = unsafe { &*(*self.data).modelData };
        md.nRelations.max(0) as usize
    }

    fn lambda(&self) -> f64 {
        self.info().lambda
    }

    fn set_lambda(&mut self, v: f64) {
        self.info().lambda = v;
    }

    fn note_failure(&mut self, eq_index: u32) {
        unsafe {
            (*self.sys).solved = NLS_FAILED;
            // First-writer-wins, as C throws out of the equation list at the first
            // failure and never reports a later one.
            if nls_fail_slot == 0 {
                nls_fail_slot = eq_index as i32 + 1;
            }
        }
    }
}

/// KINSOL over the system's CSC Jacobian, with KLU as its linear solver -- C's
/// `kinsolSolver.c`, shared with the wasm-jit runtime as `openmodelica_nls::kinsol`.
/// Without the SUNDIALS archives there is none, and every system takes the shared
/// solver's dense ladder instead.
struct CBackend<'a> {
    /// Keys the KINSOL/KLU memory kept for this system across the run.
    handle: u32,
    colptr: &'a [i32],
    rowidx: &'a [i32],
    nnz: usize,
}

impl nls::NlsBackend for CBackend<'_> {
    fn has_sparse(&self) -> bool {
        nls::kinsol::AVAILABLE && !self.colptr.is_empty()
    }

    fn has_kinsol(&self) -> bool {
        nls::kinsol::AVAILABLE
    }

    fn has_kinsol_dense(&self) -> bool {
        nls::kinsol::AVAILABLE
    }

    fn solve_sparse(
        &mut self,
        req: nls::NlsRequest,
        load_guess: &mut dyn FnMut(&mut [f64]),
        eval: &mut dyn FnMut(&[f64], &mut [f64]),
        jac: &mut dyn FnMut(&[f64], &mut [f64]),
    ) -> bool {
        let pat = nls::kinsol::Pattern {
            nnz: self.nnz,
            colptr: self.colptr,
            rowidx: self.rowidx,
            colors: req.colors,
            max: req.max,
        };
        nls::kinsol::solve_selected(
            self.handle, req.n, &pat, req.nominal, req.guess, req.old_values, req.x, req.eq_index,
            req.time, req.has_jacobian, load_guess, eval, jac,
        )
    }

    fn solve_kinsol_dense(
        &mut self,
        req: nls::NlsRequest,
        load_guess: &mut dyn FnMut(&mut [f64]),
        eval: &mut dyn FnMut(&[f64], &mut [f64]),
        jac: &mut dyn FnMut(&[f64], &mut [f64]),
    ) -> bool {
        let start = req.x.to_vec();
        nls::kinsol::b_solve(
            self.handle, req.n, 0, None, req.nominal, &start, req.old_values, req.x, req.eq_index,
            req.time, load_guess, eval, req.has_jacobian.then_some(jac),
        )
    }
}

// ---------------------------------------------------------------------------
// Initialization
// ---------------------------------------------------------------------------

/// C's `initializeNonlinearSystems`: allocate each system's arrays, initialize its
/// analytic Jacobian, and let the model fill in nominal / min / max and the
/// sparsity pattern.
pub fn initialize_nonlinear_systems(data: *mut DATA, thread_data: *mut threadData_t) {
    let md = unsafe { &*(*data).modelData };
    let si = unsafe { &mut *(*data).simulationInfo };
    omclog::info(omclog::NLS, true, "initialize non-linear system solvers");
    omclog::info!(omclog::NLS, false, "{} non-linear systems", md.nNonLinearSystems);
    for i in 0..md.nNonLinearSystems as usize {
        let sys = unsafe { &mut *si.nonlinearSystemData.add(i) };
        let size = sys.size.max(0) as usize;
        sys.numberOfFEval = 0;
        sys.numberOfIterations = 0;
        sys.lastTimeSolved = 0.0;
        sys.totalTime = 0.0;
        sys.solved = NLS_SOLVED;

        if sys.residualFunc.is_none() && sys.strictTearingFunctionCall.is_none() {
            crate::throw(thread_data, "residual function pointer is invalid");
        }

        if sys.jacobianIndex != -1 {
            let jacobian = unsafe { si.analyticJacobians.add(sys.jacobianIndex.max(0) as usize) };
            let failed = match sys.initialAnalyticalJacobian {
                Some(f) => (unsafe { f(data, thread_data, jacobian) }) != 0,
                None => true,
            };
            let j = unsafe { &*jacobian };
            // C also rejects a Jacobian whose shape is not the system's: it would
            // run over the solver's buffer, and its columns would not be the
            // iteration variables either.
            let rows = if adaptive_homotopy(data, sys) { size - 1 } else { size };
            if failed || j.sizeRows != rows || j.sizeCols != size {
                if !failed {
                    omclog::warning!(
                        omclog::STDOUT,
                        false,
                        "Analytic Jacobian of non-linear system {i} is {}x{}, but the system has {size} iteration variables. This indicates that something went wrong during Jacobian generation. Using a numeric Jacobian instead.",
                        j.sizeRows,
                        j.sizeCols,
                    );
                }
                sys.jacobianIndex = -1;
            }
        }

        sys.nlsx = crate::model_data::calloc(size.max(1));
        sys.nlsxExtrapolation = crate::model_data::calloc(size.max(1));
        sys.nlsxOld = crate::model_data::calloc(size.max(1));
        sys.resValues = crate::model_data::calloc(size.max(1));
        sys.nominal = crate::model_data::calloc(size.max(1));
        sys.min = crate::model_data::calloc(size.max(1));
        sys.max = crate::model_data::calloc(size.max(1));
        if let Some(f) = sys.initializeStaticNLSData {
            unsafe { f(data, thread_data, sys, 1, 1) };
        }

        // C's `sparsitySanityCheck`, run for every pattern the model built,
        // whatever the matrix format says: an irregular one is dropped and NLS
        // scaling with it.
        if !sys.sparsePattern.is_null() && !sparsity_is_regular(unsafe { &*sys.sparsePattern }, size)
        {
            omclog::warning!(
                omclog::STDOUT,
                false,
                "Sparsity pattern for non-linear system {i} is not regular. This indicates that something went wrong during sparsity pattern generation. Removing sparsity pattern and disabling NLS scaling.",
            );
            crate::support::freeSparsePattern(sys.sparsePattern);
            sys.sparsePattern = core::ptr::null_mut();
            unsafe { crate::support::omc_flag[crate::abi::FLAG_NO_SCALING] = 1 };
        }

        register_names(data, sys);
        sys.nlsMethod = si.nlsMethod;
        sys.nlsLinearSolver = si.nlsLinearSolver;
        let (colptr, rowidx, colors) = csc_pattern(sys, size);
        let pattern: Vec<u32> = colptr
            .iter()
            .chain(rowidx.iter())
            .map(|v| *v as u32)
            .chain(colors.iter().copied())
            .collect();
        sys.solverData = Box::into_raw(Box::new(Scratch {
            colptr,
            rowidx,
            pattern,
            history: VecHistory::default(),
            res_scaling: vec![0.0; size.max(1)],
        })) as *mut c_void;
    }
    omclog::close(omclog::NLS);
}

/// The per-system metadata the shared solver's reports need, from
/// `<Model>_info.json` and the system's `NONLINEAR_PATTERN`. The iteration-variable
/// names come from the same file, but lazily (`nls::host::set_var_names_lookup`):
/// a run with every log stream off never opens it, as C's own reader does not.
fn register_names(data: *mut DATA, sys: &NONLINEAR_SYSTEM_DATA) {
    let eq = sys.equationIndex as u32;
    // The SVD dump labels its rows by the same equation indices.
    let wanted = omclog::active(omclog::NLS_NEWTON_DIAGNOSTICS)
        || omclog::active(omclog::NLS_SVD)
        || omclog::active(omclog::NLS_SVD_V);
    if !wanted || sys.nonlinearPattern.is_null() {
        return;
    }
    let p = unsafe { &*sys.nonlinearPattern };
    // C slices `eqn_simcode_indices` from the end: the torn equations come first
    // and only the residuals' own indices are read.
    let torn = (sys.torn_plus_residual_size.max(0) as usize).saturating_sub(sys.size.max(0) as usize);
    let eqns = if sys.eqn_simcode_indices.is_null() {
        Vec::new()
    } else {
        (torn..sys.torn_plus_residual_size.max(0) as usize)
            .map(|k| unsafe { *sys.eqn_simcode_indices.add(k) } as u32)
            .collect()
    };
    nls::push_diag(
        eq,
        openmodelica_nls::newton_diagnostics::DiagInfo {
            pattern: [p.numberOfEqns, p.numberOfVars, p.numberOfNonlinear],
            init_diag: crate::info_json::is_init_diag_section(data, eq),
            eqns,
        },
    );
}

/// The system's `SPARSE_PATTERN` as CSC plus its colouring, or empty where the
/// backend chose a dense factorization or the pattern does not survive C's
/// `sparsitySanityCheck`. A missing `analyticalJacobianColumn` is not a reason to
/// drop it -- `nlsSparseJac` differences the pattern instead.
fn csc_pattern(sys: &mut NONLINEAR_SYSTEM_DATA, size: usize) -> (Vec<i32>, Vec<i32>, Vec<u32>) {
    if sys.matrixFormat != OMC_MATRIX_SPARSE || sys.sparsePattern.is_null() {
        return (Vec::new(), Vec::new(), Vec::new());
    }
    let sp = unsafe { &*sys.sparsePattern };
    let cols = (sp.sizeCols as usize).min(size);
    let mut colptr = vec![0i32; size + 1];
    for c in 0..=cols {
        colptr[c] = unsafe { *sp.leadindex.add(c) } as i32;
    }
    // A Jacobian with fewer seed directions than unknowns leaves the tail empty.
    for c in cols + 1..=size {
        colptr[c] = colptr[cols];
    }
    let nnz = colptr[size] as usize;
    let rowidx = (0..nnz).map(|k| unsafe { *sp.index.add(k) } as i32).collect();
    // C's `colorCols` counts from 1; a column past `sizeCols` gets its own colour.
    let mut next = sp.maxColors;
    let colors = (0..size)
        .map(|c| match c < cols {
            true => unsafe { *sp.colorCols.add(c) }.saturating_sub(1),
            false => {
                next += 1;
                next - 1
            }
        })
        .collect();
    (colptr, rowidx, colors)
}

/// C's `sparsitySanityCheck`: every column has an entry, every row is hit, and
/// there are at least `size` nonzeros. C names the offending row or column on
/// `LOG_NLS`; the caller's summary warning is what this reports instead.
fn sparsity_is_regular(sp: &SPARSE_PATTERN, size: usize) -> bool {
    if size == 0 || (sp.nnz as usize) < size {
        return false;
    }
    let cols = (sp.sizeCols as usize).min(size);
    for c in 1..cols {
        if unsafe { *sp.leadindex.add(c) == *sp.leadindex.add(c - 1) } {
            return false;
        }
    }
    let mut hit = vec![false; size];
    for k in 0..unsafe { *sp.leadindex.add(sp.sizeCols as usize) } as usize {
        let row = unsafe { *sp.index.add(k) } as usize;
        if row < size {
            hit[row] = true;
        }
    }
    hit.into_iter().all(|h| h)
}

/// C's `adaptiveHomotopy`: the approaches that solve for lambda alongside the
/// unknowns, which is why such a system's `size` is one more than its residuals.
fn adaptive_homotopy(data: *mut DATA, sys: &NONLINEAR_SYSTEM_DATA) -> bool {
    let method = unsafe { (*(*data).callback).homotopyMethod };
    sys.homotopySupport != 0
        && (method as u32 == nls::HOM_GLOBAL_ADAPTIVE || method as u32 == nls::HOM_LOCAL_ADAPTIVE)
}

// ---------------------------------------------------------------------------
// The entry points the generated code names
// ---------------------------------------------------------------------------

/// C's `solve_nonlinear_system`. Returns 0 when the system solved, 1 when it did
/// not — which fails the step the integrator is in, exactly as C's does.
#[unsafe(no_mangle)]
pub extern "C" fn solve_nonlinear_system(
    data: *mut DATA,
    thread_data: *mut threadData_t,
    sys_number: c_int,
) -> c_int {
    let si = unsafe { &mut *(*data).simulationInfo };
    let sys = unsafe { &mut *si.nonlinearSystemData.add(sys_number as usize) };
    let size = sys.size.max(0) as usize;
    let time = unsafe { (**(*data).localData).timeValue };

    // C's `noThrowDivZero`, raised over the solve and lowered at its end — which is
    // the only place a run lowers it again.
    si.noThrowDivZero = 1;
    // The shared solver records a solution only outside a Jacobian assembly, which
    // it reads from its own context slot; publish C's. Before the driver's first
    // `setContext` the field is still 0 (`UNKNOWN`), where C stands at `ALGEBRAIC`.
    let ctx = match si.currentContext {
        0 => nls::CONTEXT_ALGEBRAIC,
        c => c as u32,
    };
    nls::set_eval_context(ctx);
    nls::set_step_size(si.stepSize);

    let has_jacobian = sys.jacobianIndex != -1 && sys.analyticalJacobianColumn.is_some();
    // C's `size` counts `__HOM_LAMBDA` among the unknowns where an adaptive
    // approach solves for it; the residuals -- and so the Jacobian's rows and
    // everything kept per residual -- are one fewer. The shared solver draws the
    // line at `size > 1`, so this must too.
    let lambda_unknown = adaptive_homotopy(data, sys) && size > 1;
    let jac_rows = size - usize::from(lambda_unknown);
    let sd: &mut Scratch = unsafe { &mut *scratch(sys) };
    // The homotopy solvers drive an `n x (n+1)` Jacobian, which no sparse pattern
    // describes; such a system fills the dense shape whatever its format says.
    let csc = !sd.colptr.is_empty() && !lambda_unknown && has_jacobian;
    // C's `initKinsolMemory` on a system without a pattern: `nnz = size*size`, a
    // full CSC whose value order is the dense column-major one the model fills.
    if sd.colptr.is_empty()
        && !lambda_unknown
        && matches!(solverflags::nls(), solverflags::Nls::Kinsol | solverflags::Nls::KinsolB)
    {
        sd.colptr = (0..=size).map(|c| (c * size) as i32).collect();
        sd.rowidx = (0..size * size).map(|k| (k % size) as i32).collect();
        sd.pattern = sd.colptr.iter().chain(&sd.rowidx).map(|&v| v as u32).collect();
    }
    let full_pattern = !csc && !sd.colptr.is_empty();
    let outer_stage = unsafe { (*thread_data).currentErrorStage };
    let mut model = CModel { data, thread_data, sys, jac_rows, csc, outer_stage };
    let mut state = CState { data, sys };
    let mut backend = CBackend {
        handle: sys_number as u32,
        colptr: &sd.colptr,
        rowidx: &sd.rowidx,
        nnz: sd.rowidx.len(),
    };

    let nominal = unsafe { core::slice::from_raw_parts(sys.nominal, size) }.to_vec();
    let mut bounds = vec![0.0f64; 2 * size];
    for i in 0..size {
        bounds[2 * i] = unsafe { *sys.min.add(i) };
        bounds[2 * i + 1] = unsafe { *sys.max.add(i) };
    }

    let spec = nls::NlsSpec {
        eq_index: sys.equationIndex as u32,
        size,
        time,
        casual: sys.strictTearingFunctionCall.is_some(),
        mixed: sys.mixedSystem != 0,
        hom_support: sys.homotopySupport != 0,
        hom_method: unsafe { (*(*data).callback).homotopyMethod } as u32,
        // Only where the backend chose a sparse factorization, which is the same
        // decision `nls_use_sparse` re-derives: a dense-format system then takes the
        // dense ladder, as C's `nlsMethod` sends it to hybrd.
        nnz: if csc || full_pattern { sd.rowidx.len() as u32 } else { 0 },
        jac_csc: csc,
        sys_num: sys_number as u32,
        nominal: &nominal,
        bounds: &bounds,
        pattern: if csc || full_pattern { &sd.pattern } else { &[] },
        has_jacobian,
    };

    let hist_n = jac_rows;
    let sd: &mut Scratch = unsafe { &mut *scratch(sys) };
    sd.res_scaling.resize(hist_n, 0.0);
    let ret = {
        let extrapolation =
            unsafe { core::slice::from_raw_parts_mut(sys.nlsxExtrapolation, hist_n) };
        let mut mem = nls::NlsPersistent {
            history: &mut sd.history,
            res_scaling: &mut sd.res_scaling,
            extrapolation,
            last_solved: &mut sys.lastTimeSolved,
        };
        nls::solve_nls(&spec, &mut model, &mut state, &mut mem, &mut backend)
    };

    // C's solvers leave the answer in `nlsx`, and that -- not the unknown slots --
    // is what the generated `eqFunction` copies back into the model. The shared
    // solver leaves it in the slots instead, so publish it: `getIterationVars` is
    // exactly the reverse copy, and is what C's own `getInitialGuess` uses.
    if let Some(f) = sys.getIterationVars {
        unsafe { f(data, sys.nlsx) };
    }
    sys.solved = if ret == 1 { NLS_FAILED } else { NLS_SOLVED };
    sys.numberOfCall += 1;
    if ret == 1 {
        sys.numberOfFailures += 1;
    }
    si.noThrowDivZero = 0;
    si.solveContinuous = 0;
    check_nonlinear_solution(data, 1, sys_number)
}

/// C's `check_nonlinear_solution` for one system.
fn check_nonlinear_solution(data: *mut DATA, print: c_int, sys_number: c_int) -> c_int {
    let si = unsafe { &*(*data).simulationInfo };
    let sys = unsafe { &*si.nonlinearSystemData.add(sys_number as usize) };
    if sys.solved != NLS_FAILED {
        return 0;
    }
    if print != 0 {
        let time = unsafe { (**(*data).localData).timeValue };
        omclog::warning!(
            omclog::NLS,
            false,
            "nonlinear system {} fails: at t={}",
            sys.equationIndex,
            openmodelica_sim_meta::driver::format_g(time, 6),
        );
        if si.initial != 0 {
            omclog::warning(
                omclog::INIT,
                false,
                "The system might not be able to initialize because the iteration variables listed below have no suitable start values. The model was probably developed with another tool that selects different iteration (tearing) variables, so its start values may apply to other variables than the ones OpenModelica iterates on here. Try providing start values for the iteration variables below, or a different tearing method (e.g. --tearingMethod=omcTearing).",
            );
        }
    }
    1
}

/// C's `check_nonlinear_solutions`: whether any nonlinear system failed this step.
#[unsafe(no_mangle)]
pub extern "C" fn check_nonlinear_solutions(data: *mut DATA, print: c_int) -> c_int {
    let md = unsafe { &*(*data).modelData };
    for i in 0..md.nNonLinearSystems as c_int {
        if check_nonlinear_solution(data, print, i) != 0 {
            return 1;
        }
    }
    0
}

/// C's `cleanUpOldValueListAfterEvent`, called once per event: the stored solutions
/// past the event are no longer on the trajectory.
pub fn clean_history_after_event(data: *mut DATA, time: f64) {
    let md = unsafe { &*(*data).modelData };
    let si = unsafe { &*(*data).simulationInfo };
    for i in 0..md.nNonLinearSystems as usize {
        let sys = unsafe { &*si.nonlinearSystemData.add(i) };
        if sys.solverData.is_null() {
            continue;
        }
        let sd: &mut Scratch = unsafe { &mut *scratch(sys) };
        nls::history_clean(&mut sd.history, time);
    }
}

// ---------------------------------------------------------------------------
// What the solver leaves to the runtime around it
// ---------------------------------------------------------------------------

struct PrefixCell(core::cell::UnsafeCell<String>);
// A simulation executable runs one model on one thread, as the C runtime does.
unsafe impl Sync for PrefixCell {}
static PREFIX: PrefixCell = PrefixCell(core::cell::UnsafeCell::new(String::new()));
static THREAD_DATA: core::sync::atomic::AtomicUsize = core::sync::atomic::AtomicUsize::new(0);
static MODEL_DATA_PTR: core::sync::atomic::AtomicUsize = core::sync::atomic::AtomicUsize::new(0);

/// Give the shared solver this runtime's side of [`nls::host`]: C's
/// `modelData->modelFilePrefix`, `omc_fopen` beside the result, and the jump a
/// model error leaves through.
pub fn install_hooks(data: *mut DATA, thread_data: *mut threadData_t, prefix: &str) {
    *unsafe { &mut *PREFIX.0.get() } = String::from(prefix);
    THREAD_DATA.store(thread_data as usize, core::sync::atomic::Ordering::Relaxed);
    MODEL_DATA_PTR.store(data as usize, core::sync::atomic::Ordering::Relaxed);
    nls::host::set_file_prefix(|| unsafe { &*PREFIX.0.get() });
    nls::host::set_write_file(|name, data| {
        if let Err(e) = std::fs::write(name, data) {
            omclog::warning!(omclog::STDOUT, false, "could not write {name}: {e}");
        }
    });
    nls::host::set_note_runtime_error(|msg| omclog::debug(omclog::ASSERT, false, msg));
    nls::host::set_note_runtime_error_flag(|| {});
    nls::host::set_var_names_lookup(|eq| {
        let data = MODEL_DATA_PTR.load(core::sync::atomic::Ordering::Relaxed) as *mut DATA;
        if data.is_null() { Vec::new() } else { crate::info_json::equation_vars(data, eq) }
    });
    nls::host::set_trap(|| {
        let td = THREAD_DATA.load(core::sync::atomic::Ordering::Relaxed) as *mut threadData_t;
        crate::throw(td, "a model error was raised where nothing could absorb it")
    });
    // Both names are the path the flag gave; only the wasm host needs a second one.
    nls::host::set_initial_guess_request(|eq_index| {
        simflags::with_flags(|f| match &f.save_initial_guess {
            Some((path, idx)) if *idx == eq_index as i32 => Some((path.clone(), path.clone())),
            _ => None,
        })
        .filter(|_| !GUESS_DONE.swap(true, core::sync::atomic::Ordering::Relaxed))
    });
    nls::host::set_initial_guess_writer(write_state);
}

/// One-shot, as C's `B_save_initial_guess_system` is: it throws once written.
static GUESS_DONE: core::sync::atomic::AtomicBool = core::sync::atomic::AtomicBool::new(false);

/// Raw because the solve runs inside `driver::drive`, which holds the engine these
/// belong to; nothing here writes.
static STATE_META: core::sync::atomic::AtomicUsize = core::sync::atomic::AtomicUsize::new(0);
static STATE_RT: core::sync::atomic::AtomicUsize = core::sync::atomic::AtomicUsize::new(0);

/// Publish what [`write_state`] reads, for the length of a run.
pub fn set_state_source(meta: *const openmodelica_sim_meta::SimMeta, rt: *const crate::data::RtData) {
    STATE_META.store(meta as usize, core::sync::atomic::Ordering::Relaxed);
    STATE_RT.store(rt as usize, core::sync::atomic::Ordering::Relaxed);
}

/// Reading the region map needs no model call, and the engine is busy driving the
/// solve this runs inside.
struct ReadOnly(*const crate::data::RtData);

impl driver::SimEngine for ReadOnly {
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> driver::Result<()> {
        unsafe { &*self.0 }.read(addr, buf)
    }
    fn write_bytes(&mut self, _addr: u32, _buf: &[u8]) -> driver::Result<()> {
        Err("the initial-guess writer does not write SimData")
    }
    fn call1_raw(&mut self, _name: &str, _arg: u32) -> driver::Result<()> {
        Err("the initial-guess writer does not call the model")
    }
    fn call1_if_present_raw(&mut self, _name: &str, _arg: u32) -> driver::Result<()> {
        Ok(())
    }
    fn call2_raw(&mut self, _name: &str, _a: u32, _b: u32) -> driver::Result<()> {
        Err("the initial-guess writer does not call the model")
    }
    fn call_simulate(&mut self, _sim_data: u32, _start: f64, _stop: f64, _n: u32) -> driver::Result<u32> {
        Err("the initial-guess writer does not call the model")
    }
    fn take_pending_assert(&mut self) -> Option<[i32; 9]> {
        None
    }
}

/// C's `mat4_init4` + `mat4_writeParameterData4` + `mat4_emit4`, where the solver
/// stands.
fn write_state(path: &str) -> Result<(), String> {
    let meta = STATE_META.load(core::sync::atomic::Ordering::Relaxed)
        as *const openmodelica_sim_meta::SimMeta;
    let rt = STATE_RT.load(core::sync::atomic::Ordering::Relaxed) as *const crate::data::RtData;
    if meta.is_null() || rt.is_null() {
        return Err(String::from("no model to write the initial guess from"));
    }
    let meta = unsafe { &*meta };
    let engine = ReadOnly(rt);
    let mut rows = Vec::new();
    driver::capture_row(&engine, &mut rows, 0, &meta.layout).map_err(String::from)?;
    // Every parameter, in `meta.vars` order: `result::write` is what applies `keep`.
    let mut params = Vec::new();
    for v in &meta.vars {
        if let openmodelica_sim_meta::MetaKind::Param { off, wty, .. } = &v.kind {
            params.push(match wty {
                openmodelica_sim_meta::WTy::F64 => {
                    driver::read_f64(&engine, *off).map_err(String::from)?
                }
                openmodelica_sim_meta::WTy::I32 => {
                    driver::read_i32(&engine, *off).map_err(String::from)? as f64
                }
            });
        }
    }
    let Some(bytes) = openmodelica_sim_meta::result::write(
        meta,
        "mat",
        &rows,
        meta.layout.n_row_total(),
        &params,
        &meta.output_keep(None),
        openmodelica_mat_writer::Precision::Double,
    ) else {
        return Err(String::from("cannot write the initial guess file"));
    };
    std::fs::write(path, bytes).map_err(|e| format!("cannot write {path}: {e}"))
}

/// `-nls=kinsol` on a build without the SUNDIALS archives; say so once rather than
/// silently taking the dense ladder anyway.
pub fn warn_once_unsupported_nls() {
    use core::sync::atomic::{AtomicBool, Ordering};
    static WARNED: AtomicBool = AtomicBool::new(false);
    if !nls::kinsol::AVAILABLE
        && matches!(solverflags::nls(), solverflags::Nls::Kinsol | solverflags::Nls::KinsolB)
        && !WARNED.swap(true, Ordering::Relaxed)
    {
        omclog::warning(
            omclog::STDOUT,
            false,
            "-nls: this runtime was built without SUNDIALS; using the dense solver ladder.",
        );
    }
}
