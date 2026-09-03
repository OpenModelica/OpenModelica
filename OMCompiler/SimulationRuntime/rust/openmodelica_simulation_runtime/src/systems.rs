//! Linear systems: `initializeLinearSystems`, `solve_linear_system` and the
//! generic dense Jacobian evaluation a torn one needs.
//!
//! Port of `simulation/solver/linearSystem.c` + `linearSolverLapack.c` +
//! `jacobian_util.c`'s `evalJacobian`, over the same `LINEAR_SYSTEM_DATA` the
//! generated code fills. The factorization is `openmodelica_lapack`'s `dgesv`,
//! which is the LAPACK the wasm-jit runtime factors with too, so a system gets
//! the same pivot order and `INFO` on either target.

use core::ffi::{c_int, c_void};

use openmodelica_solvers::{omclog, sysstat};

use crate::abi::*;
use crate::model_data::calloc;

/// `enum EVAL_CONTEXT` (util/context.h), as `openmodelica_nls` numbers them.
pub const CONTEXT_ALGEBRAIC: c_int = openmodelica_nls::CONTEXT_ALGEBRAIC as c_int;
pub const CONTEXT_SYM_JACOBIAN: c_int = openmodelica_nls::CONTEXT_SYM_JACOBIAN as c_int;

/// The scratch one dense system needs between calls, kept where C keeps its
/// solver data.
struct LapackData {
    ipiv: Vec<i32>,
    /// The factored copy of `A`, so the solve can reuse it across the columns of
    /// a symbolic Jacobian evaluation (C's `reuseMatrixJac`).
    lu: Vec<f64>,
    /// The previous iterate, for a `method == 1` (torn) system.
    work: Vec<f64>,
    b: Vec<f64>,
}

/// A raw pointer, not a borrow of `ls`: the scratch and the system's own arrays
/// are used side by side throughout a solve.
fn solver_data(ls: &LINEAR_SYSTEM_DATA) -> *mut LapackData {
    ls.solverData[0] as *mut LapackData
}

/// C's `initializeLinearSystems`: allocate each system's `A`/`b`/attribute
/// arrays, install the element setters the generated `setA`/`setb` call, and let
/// the model fill in its static data.
pub fn initialize_linear_systems(data: *mut DATA, thread_data: *mut threadData_t) {
    let md = unsafe { &*(*data).modelData };
    let si = unsafe { &mut *(*data).simulationInfo };
    // C prints the header whatever the count is; only the loop is conditional.
    omclog::info(omclog::LS, true, "initialize linear system solvers");
    omclog::info!(omclog::LS, false, "{} linear systems", md.nLinearSystems);
    for i in 0..md.nLinearSystems as usize {
        let ls = unsafe { &mut *si.linearSystemData.add(i) };
        let size = ls.size.max(0) as usize;
        ls.totalTime = 0.0;
        ls.failed = 0;
        ls.b = calloc(size.max(1));
        ls.nominal = calloc(size.max(1));
        ls.min = calloc(size.max(1));
        ls.max = calloc(size.max(1));

        if ls.method == 1 {
            let jacobian = unsafe { si.analyticJacobians.add(ls.jacobianIndex.max(0) as usize) };
            let failed = match ls.initialAnalyticalJacobian {
                Some(f) => (unsafe { f(data, thread_data, jacobian) }) != 0,
                None => true,
            };
            if failed {
                ls.jacobianIndex = -1;
                crate::throw(
                    thread_data,
                    &format!(
                        "Failed to initialize the jacobian for torn linear system {}.",
                        ls.equationIndex
                    ),
                );
            }
            let j = unsafe { &*jacobian };
            if j.sizeRows != size || j.sizeCols != size {
                ls.jacobianIndex = -1;
                crate::throw(
                    thread_data,
                    &format!(
                        "Jacobian of torn linear system {} is {}x{}, but the system has size {size}.",
                        ls.equationIndex, j.sizeRows, j.sizeCols
                    ),
                );
            }
            ls.nnz = unsafe { (*j.sparsePattern).nnz } as modelica_integer;
            ls.jacobian = jacobian;
        }

        // KLU is linked (the nonlinear solver's), but nothing binds it to a linear
        // system yet, so every one is factored densely -- as C does without
        // SuiteSparse.
        ls.useSparseSolver = 0;
        ls.setAElement = Some(set_a_element);
        ls.setBElement = Some(set_b_element);
        ls.A = calloc((size * size).max(1));
        let scratch = Box::new(LapackData {
            ipiv: vec![0; size.max(1)],
            lu: vec![0.0; (size * size).max(1)],
            work: vec![0.0; size.max(1)],
            b: vec![0.0; size.max(1)],
        });
        ls.solverData[0] = Box::into_raw(scratch) as *mut c_void;

        if let Some(f) = ls.initializeStaticLSData {
            unsafe { f(data, thread_data, ls, 1) };
        }
    }
    omclog::close(omclog::LS);
}

/// `linearSystemData->A[row + col*size] = value`.
unsafe extern "C" fn set_a_element(
    row: c_int,
    col: c_int,
    value: f64,
    _nth: c_int,
    ls: *mut LINEAR_SYSTEM_DATA,
    _td: *mut threadData_t,
) {
    unsafe {
        let size = (*ls).size as usize;
        *(*ls).A.add(row as usize + col as usize * size) = value;
    }
}

unsafe extern "C" fn set_b_element(
    row: c_int,
    value: f64,
    ls: *mut LINEAR_SYSTEM_DATA,
    _td: *mut threadData_t,
) {
    unsafe { *(*ls).b.add(row as usize) = value };
}

/// What [`eval_jacobian`] reports when the model left through its jump buffer, so
/// the caller can treat the assembly as a voided trial rather than a hard error.
pub const MODEL_THREW: &str = "the model raised an error while evaluating a Jacobian";

/// C's `evalJacobian` (column evaluation): one model call per colour, each
/// filling the columns that colour seeds. `out` is column-major with
/// `min(sizeRows, sizeCols)` rows when `dense`, else the sparse value array.
pub fn eval_jacobian(
    data: *mut DATA,
    thread_data: *mut threadData_t,
    jacobian: *mut JACOBIAN,
    parent: *mut JACOBIAN,
    out: &mut [f64],
    dense: bool,
) -> Result<(), &'static str> {
    let j = unsafe { &mut *jacobian };
    if j.isBidirectional != 0 && !j.adjointJacobian.is_null() {
        return Err("a bidirectionally evaluated Jacobian is not served by this runtime yet");
    }
    if j.isRowEval != 0 {
        return Err("a row-evaluated Jacobian is not served by this runtime yet");
    }
    let stage = crate::support::error_stage::NONLINEARSOLVER;
    if let Some(f) = j.constantEqns
        && !crate::support::protected(thread_data, stage, || {
            unsafe { f(data, thread_data, jacobian, parent) };
        })
    {
        return Err(MODEL_THREW);
    }
    let dense_rows = j.sizeRows.min(j.sizeCols);
    if dense {
        out[..dense_rows * j.sizeCols].fill(0.0);
    }
    if j.sparsePattern.is_null() {
        return Ok(());
    }
    let sp = unsafe { &*j.sparsePattern };
    for color in 0..sp.maxColors {
        for column in 0..j.sizeCols {
            if unsafe { *sp.colorCols.add(column) } == color + 1 {
                unsafe { *j.seedVars.add(column) = 1.0 };
            }
        }
        match j.evalColumn {
            Some(f) => {
                if !crate::support::protected(thread_data, stage, || {
                    unsafe { f(data, thread_data, jacobian, parent) };
                }) {
                    return Err(MODEL_THREW);
                }
            }
            None => return Err("the Jacobian has no column evaluation"),
        };
        for column in 0..j.sizeCols {
            if unsafe { *sp.colorCols.add(column) } != color + 1 {
                continue;
            }
            let (from, to) = unsafe {
                (*sp.leadindex.add(column) as usize, *sp.leadindex.add(column + 1) as usize)
            };
            for nz in from..to {
                let row = unsafe { *sp.index.add(nz) } as usize;
                let v = unsafe { *j.resultVars.add(row) };
                if !dense {
                    out[nz] = v;
                } else if row < dense_rows {
                    out[column * dense_rows + row] = v;
                }
            }
            unsafe { *j.seedVars.add(column) = 0.0 };
        }
    }
    Ok(())
}

/// C's `solve_linear_system`: the `-ls` ladder over the dense solvers. A sparse
/// `-lss` and `-ls=klu`/`umfpack`/`lis` are not served; they are warned about once
/// and factored densely.
/// C's `readFlag`s in `initRuntimeAndSimulation`: `-ls`, `-nls` and `-nlsLS` onto
/// `simulationInfo`, in `simulation_options.h`'s enumerations. The generated code
/// and the C-side solver dispatch read these; the shared solvers read
/// `solverflags`.
pub fn apply_solver_flags(si: &mut SIMULATION_INFO, f: &openmodelica_sim_meta::simflags::SimFlags) {
    use openmodelica_sim_meta::simflags::{Ls, Nls, NlsLs};
    if let Some(ls) = f.ls {
        si.lsMethod = match ls {
            Ls::Default => LS_DEFAULT,
            Ls::Lapack => LS_LAPACK,
            Ls::Lis => LS_LIS,
            Ls::Klu => LS_KLU,
            Ls::Umfpack => LS_UMFPACK,
            Ls::TotalPivot => LS_TOTALPIVOT,
        };
    }
    if let Some(nls) = f.nls {
        si.nlsMethod = match nls {
            Nls::Hybrid => NLS_HYBRID,
            Nls::Kinsol => NLS_KINSOL,
            Nls::KinsolB => NLS_KINSOL_B,
            Nls::Newton => NLS_NEWTON,
            Nls::Mixed => NLS_MIXED,
            Nls::Homotopy => NLS_HOMOTOPY,
        };
    }
    if let Some(ls) = f.nls_ls {
        si.nlsLinearSolver = match ls {
            NlsLs::Default => NLS_LS_DEFAULT,
            NlsLs::TotalPivot => NLS_LS_TOTALPIVOT,
            NlsLs::Lapack => NLS_LS_LAPACK,
            NlsLs::Klu | NlsLs::Rsparse => NLS_LS_KLU,
        };
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn solve_linear_system(
    data: *mut DATA,
    thread_data: *mut threadData_t,
    sys_number: c_int,
    aux_x: *mut f64,
) -> c_int {
    let si = unsafe { &mut *(*data).simulationInfo };
    let ls = unsafe { &mut *si.linearSystemData.add(sys_number as usize) };
    // C's `rt_ext_tp_tick(&linsys->totalTimeClock)`; `A` and `b` are assembled
    // inside, so the assembly mark is taken there.
    sysstat::begin(ls.equationIndex as i32, false, ls.size.max(0) as u32, ls.nnz.max(0) as u32);
    si.noThrowDivZero = 1;
    let method = si.lsMethod;
    let success = match method {
        LS_TOTALPIVOT => solve_total_pivot(data, thread_data, ls, sys_number, aux_x) as c_int,
        LS_LAPACK => solve_lapack(data, thread_data, ls, sys_number, aux_x) as c_int,
        LS_DEFAULT => solve_default(data, thread_data, ls, sys_number, aux_x),
        _ => {
            warn_once_unsupported_ls(method);
            solve_default(data, thread_data, ls, sys_number, aux_x)
        }
    };
    sysstat::end([0; 3]);
    ls.solved = success;
    ls.numberOfCall += 1;
    check_linear_solution(data, 1, sys_number)
}

/// C's `LS_DEFAULT` branch: LAPACK, then dynamic tearing's strict set if the
/// system has one, else the total-pivot fallback. `2` is C's "solved by the
/// strict tearing set".
fn solve_default(
    data: *mut DATA,
    thread_data: *mut threadData_t,
    ls: &mut LINEAR_SYSTEM_DATA,
    sys_number: c_int,
    aux_x: *mut f64,
) -> c_int {
    if solve_lapack(data, thread_data, ls, sys_number, aux_x) {
        ls.failed = 0;
        return 1;
    }
    if let Some(strict) = ls.strictTearingFunctionCall {
        omclog::info(
            omclog::DT,
            false,
            "Solving the casual tearing set failed! Now the strict tearing set is used.",
        );
        let ok = unsafe { strict(data, thread_data) } != 0;
        ls.failed = !ok as modelica_boolean;
        return if ok { 2 } else { 0 };
    }
    // C reports the fallback on stdout the first time a system needs it and on
    // LOG_LS from then on, so a system that fails at every step says so once.
    let stream = if ls.failed != 0 { omclog::LS } else { omclog::STDOUT };
    let time = unsafe { (**(*data).localData).timeValue };
    omclog::warning_with_limit!(
        stream,
        ls.numberOfFailures as u64,
        unsafe { (*(*data).simulationInfo).maxWarnDisplays as u64 },
        "The default linear solver fails, the fallback solver with total pivoting is started at time {time:.6}. That might raise performance issues, for more information use -lv LOG_LS.",
    );
    let ok = solve_total_pivot(data, thread_data, ls, sys_number, aux_x);
    ls.failed = 1;
    ok as c_int
}

/// `-ls=<other>` reaches a solver this runtime does not have; say so once rather
/// than silently factoring densely anyway.
fn warn_once_unsupported_ls(method: c_int) {
    use core::sync::atomic::{AtomicBool, Ordering};
    static WARNED: AtomicBool = AtomicBool::new(false);
    if WARNED.swap(true, Ordering::Relaxed) {
        return;
    }
    let name = match method {
        LS_LIS => "lis",
        LS_KLU => "klu",
        LS_UMFPACK => "umfpack",
        _ => "the requested",
    };
    omclog::info!(
        omclog::LS,
        false,
        "-ls: {name} linear solver is not served by this runtime; using the default.",
    );
}

/// C's `solveTotalPivot` (`linearSolverTotalPivot.c`): the same `A`/`b`
/// assembly as the LAPACK solver, factored by
/// [`openmodelica_nls::total_pivot_solve`], which is C's
/// `solveSystemWithTotalPivotSearchLS`.
fn solve_total_pivot(
    data: *mut DATA,
    thread_data: *mut threadData_t,
    ls: &mut LINEAR_SYSTEM_DATA,
    _sys_number: c_int,
    aux_x: *mut f64,
) -> bool {
    let size = ls.size.max(0) as usize;
    let time = unsafe { (**(*data).localData).timeValue };
    let eq = ls.equationIndex;
    omclog::info!(
        omclog::LS,
        false,
        "Start solving Linear System {eq} (size {size}) at time {} with Total Pivot Solver",
        openmodelica_sim_meta::driver::format_g(time, 6),
    );
    let mut a = vec![0.0f64; (size * size).max(1)];
    let mut b = vec![0.0f64; size.max(1)];
    if ls.method == 0 {
        unsafe { core::ptr::write_bytes(ls.A, 0, size * size) };
        if let Some(f) = ls.setA {
            unsafe { f(data, thread_data, ls) };
        }
        a[..size * size].copy_from_slice(unsafe { core::slice::from_raw_parts(ls.A, size * size) });
        if let Some(f) = ls.setb {
            unsafe { f(data, thread_data, ls) };
        }
        // C's last column of `Ab` is `-b`, which is what `total_pivot_solve` makes
        // of the right-hand side it is handed.
        b[..size].copy_from_slice(unsafe { core::slice::from_raw_parts(ls.b, size) });
    } else {
        if ls.jacobianIndex == -1 {
            crate::throw(thread_data, "jacobian function pointer is invalid");
        }
        if let Err(e) =
            eval_jacobian(data, thread_data, ls.jacobian, ls.parentJacobian, &mut a, true)
        {
            omclog::warning(omclog::STDOUT, false, e);
            return false;
        }
        // C writes the residual itself into `Ab`'s last column, i.e. the negated
        // right-hand side, where the LAPACK path negates the Jacobian instead.
        residual(data, thread_data, ls, aux_x, &mut b);
        for v in b.iter_mut() {
            *v = -*v;
        }
    }
    sysstat::mark_assembly_done();

    if !openmodelica_nls::total_pivot_solve(&a, &mut b, size) {
        omclog::warning!(
            omclog::STDOUT,
            false,
            "Error solving linear system of equations (no. {eq}) at time {time:.6}.",
        );
        return false;
    }
    if ls.method == 1 {
        // The step is added to the old solution, then the inner equations run at
        // the new point.
        for i in 0..size {
            unsafe { *aux_x.add(i) += b[i] };
        }
        let mut res = vec![0.0f64; size.max(1)];
        residual(data, thread_data, ls, aux_x, &mut res);
    } else {
        for i in 0..size {
            unsafe { *aux_x.add(i) = b[i] };
        }
    }
    true
}

/// One call of the torn system's residual function at `x`.
fn residual(
    data: *mut DATA,
    thread_data: *mut threadData_t,
    ls: &LINEAR_SYSTEM_DATA,
    x: *const f64,
    out: &mut [f64],
) {
    let Some(f) = ls.residualFunc else {
        crate::throw(thread_data, "the torn linear system has no residual function");
    };
    let flag: c_int = 0;
    let mut user =
        RESIDUAL_USERDATA { data, threadData: thread_data, solverData: core::ptr::null_mut() };
    unsafe { f(&mut user, x, out.as_mut_ptr(), &flag) };
}

fn solve_lapack(
    data: *mut DATA,
    thread_data: *mut threadData_t,
    ls: &mut LINEAR_SYSTEM_DATA,
    sys_number: c_int,
    aux_x: *mut f64,
) -> bool {
    let si = unsafe { &mut *(*data).simulationInfo };
    let size = ls.size.max(0) as usize;
    let time = unsafe { (**(*data).localData).timeValue };
    let eq = ls.equationIndex;
    if omclog::active(omclog::LS) {
        omclog::info!(
            omclog::LS,
            false,
            "Start solving Linear System {eq} (size {size}) at time {} with Lapack Solver",
            openmodelica_sim_meta::driver::format_g(time, 6),
        );
    }
    // C's `reuseMatrixJac`: inside a symbolic Jacobian's later columns the matrix
    // is unchanged, so the previous factorization is reused.
    let reuse = si.currentContext == CONTEXT_SYM_JACOBIAN && si.currentJacobianEval > 0;
    let mut lapack_err = None;

    // C ends `jacobianTime` where the generated `setA`/`setb` are done.
    sysstat::mark_assembly_done();
    let sd: &mut LapackData = unsafe { &mut *solver_data(ls) };
    sd.b.resize(size.max(1), 0.0);
    sd.work.resize(size.max(1), 0.0);
    sd.lu.resize((size * size).max(1), 0.0);
    sd.ipiv.resize(size.max(1), 0);

    if ls.method == 0 {
        if !reuse {
            unsafe { core::ptr::write_bytes(ls.A, 0, size * size) };
            if let Some(f) = ls.setA {
                unsafe { f(data, thread_data, ls) };
            }
        }
        if let Some(f) = ls.setb {
            unsafe { f(data, thread_data, ls) };
        }
        sd.b.copy_from_slice(unsafe { core::slice::from_raw_parts(ls.b, size) });
        if !reuse {
            sd.lu.copy_from_slice(unsafe { core::slice::from_raw_parts(ls.A, size * size) });
        }
    } else {
        if !reuse {
            if ls.jacobianIndex == -1 {
                crate::throw(thread_data, "jacobian function pointer is invalid");
            }
            let mut jac = vec![0.0f64; size * size];
            if let Err(e) =
                eval_jacobian(data, thread_data, ls.jacobian, ls.parentJacobian, &mut jac, true)
            {
                lapack_err = Some(e);
            }
            // C negates the Jacobian into A (`getAnalyticalJacobianLapack`).
            for (dst, src) in sd.lu.iter_mut().zip(&jac) {
                *dst = -*src;
            }
        }
        // The residual at the current iterate is the right-hand side.
        sd.work.copy_from_slice(unsafe { core::slice::from_raw_parts(aux_x, size) });
        sd.b.fill(0.0);
        let flag: c_int = 1;
        let mut user =
            RESIDUAL_USERDATA { data, threadData: thread_data, solverData: core::ptr::null_mut() };
        let residual = ls.residualFunc;
        match residual {
            Some(f) => unsafe { f(&mut user, sd.work.as_ptr(), sd.b.as_mut_ptr(), &flag) },
            None => lapack_err = Some("the torn linear system has no residual function"),
        }
    }
    if let Some(e) = lapack_err {
        omclog::warning(omclog::STDOUT, false, e);
        return false;
    }

    let info = if reuse {
        openmodelica_lapack::lu::dgetrs("N", size, 1, &sd.lu, size, &sd.ipiv, &mut sd.b, size);
        0
    } else {
        let mut lu = sd.lu.clone();
        let info = openmodelica_lapack::lu::dgesv(size, 1, &mut lu, size, &mut sd.ipiv, &mut sd.b, size);
        sd.lu = lu;
        info
    };
    if info != 0 {
        ls.numberOfFailures += 1;
        omclog::warning_with_limit!(
            omclog::LS,
            ls.numberOfFailures as u64,
            unsafe { (*(*data).simulationInfo).maxWarnDisplays as u64 },
            "Failed to solve linear system of equations (no. {eq}) at time {}, system is singular for U[{}, {}].",
            openmodelica_sim_meta::driver::format_g(time, 6),
            info + 1,
            info + 1,
        );
        return false;
    }

    if ls.method == 1 {
        // x = xold + xnew, then re-run the inner equations at the new point.
        for i in 0..size {
            unsafe { *aux_x.add(i) = sd.work[i] + sd.b[i] };
        }
        let x = unsafe { core::slice::from_raw_parts(aux_x, size) }.to_vec();
        sd.work.fill(0.0);
        let flag: c_int = 1;
        let mut user =
            RESIDUAL_USERDATA { data, threadData: thread_data, solverData: core::ptr::null_mut() };
        let residual = ls.residualFunc;
        if let Some(f) = residual {
            unsafe { f(&mut user, x.as_ptr(), sd.work.as_mut_ptr(), &flag) };
        }
        let norm = sd.work.iter().map(|v| v * v).sum::<f64>().sqrt();
        if norm.is_nan() || norm > 1e-4 {
            ls.numberOfFailures += 1;
            omclog::warning_with_limit!(
                omclog::LS,
                ls.numberOfFailures as u64,
                unsafe { (*(*data).simulationInfo).maxWarnDisplays as u64 },
                "Failed to solve linear system of equations (no. {eq}) at time {}. Residual norm is {norm:.15}.",
                openmodelica_sim_meta::driver::format_g(time, 6),
            );
            return false;
        }
    } else {
        for i in 0..size {
            unsafe { *aux_x.add(i) = sd.b[i] };
        }
    }
    let _ = sys_number;
    true
}

/// C's `check_linear_solution` for one system: report and fail the step if it
/// did not solve.
fn check_linear_solution(data: *mut DATA, print: c_int, sys_number: c_int) -> c_int {
    let si = unsafe { &*(*data).simulationInfo };
    let ls = unsafe { &*si.linearSystemData.add(sys_number as usize) };
    if ls.solved != 0 {
        return 0;
    }
    if print != 0 {
        let time = unsafe { (**(*data).localData).timeValue };
        omclog::warning!(
            omclog::STDOUT,
            false,
            "Solving linear system {} fails at time {}. For more information use -lv LOG_LS.",
            ls.equationIndex,
            openmodelica_sim_meta::driver::format_g(time, 6),
        );
    }
    1
}

/// C's `check_linear_solutions`: whether any linear system failed in this step.
#[unsafe(no_mangle)]
pub extern "C" fn check_linear_solutions(data: *mut DATA, print: c_int) -> c_int {
    let md = unsafe { &*(*data).modelData };
    for i in 0..md.nLinearSystems as c_int {
        if check_linear_solution(data, print, i) != 0 {
            return 1;
        }
    }
    0
}
