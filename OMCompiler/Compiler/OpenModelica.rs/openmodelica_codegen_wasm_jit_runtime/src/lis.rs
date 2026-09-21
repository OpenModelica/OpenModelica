//! `linearSolverLis.c` against the real Lis 1.4.12, cross-compiled to wasm and
//! linked by `build.rs` with the rest of the third-party archives.
//!
//! `A` and `b` arrive assembled (the generated code is C's `setA`/`setb`) and the
//! method-1 residual test is `rt_ls_check_step`, so what is left of `solveLis` is
//! the option set, the initial guess and the solve. `LIS_INT` is `int`,
//! `LIS_SCALAR` is `double`, and every handle is opaque.

use core::ffi::{c_char, c_int, c_void};

type LisInt = c_int;

/// `LIS_COMM_WORLD` without MPI, `LIS_INS_VALUE`, `LIS_MATRIX_CSR` (`lis.h`).
const LIS_COMM_WORLD: LisInt = 0x1;
const LIS_INS_VALUE: LisInt = 0;
const LIS_MATRIX_CSR: LisInt = 1;

unsafe extern "C" {
    fn lis_vector_create(comm: LisInt, v: *mut *mut c_void) -> LisInt;
    fn lis_vector_set_size(v: *mut c_void, local_n: LisInt, global_n: LisInt) -> LisInt;
    fn lis_vector_destroy(v: *mut c_void) -> LisInt;
    fn lis_vector_set_value(flag: LisInt, i: LisInt, value: f64, v: *mut c_void) -> LisInt;
    fn lis_vector_get_values(v: *mut c_void, start: LisInt, count: LisInt, value: *mut f64) -> LisInt;
    fn lis_matrix_create(comm: LisInt, a: *mut *mut c_void) -> LisInt;
    fn lis_matrix_destroy(a: *mut c_void) -> LisInt;
    fn lis_matrix_set_size(a: *mut c_void, local_n: LisInt, global_n: LisInt) -> LisInt;
    fn lis_matrix_set_type(a: *mut c_void, matrix_type: LisInt) -> LisInt;
    fn lis_matrix_set_value(flag: LisInt, i: LisInt, j: LisInt, value: f64, a: *mut c_void) -> LisInt;
    fn lis_matrix_assemble(a: *mut c_void) -> LisInt;
    fn lis_solver_create(s: *mut *mut c_void) -> LisInt;
    fn lis_solver_destroy(s: *mut c_void) -> LisInt;
    fn lis_solver_set_option(text: *mut c_char, s: *mut c_void) -> LisInt;
    fn lis_solve(a: *mut c_void, b: *mut c_void, x: *mut c_void, s: *mut c_void) -> LisInt;
}

/// `lis_returncode` (`lis_solver.c`), for C's failure warning.
const LIS_OUT_OF_MEMORY: i32 = 3;
const RETURNCODE: [&str; 7] = [
    "LIS_SUCCESS",
    "LIS_ILL_OPTION",
    "LIS_BREAKDOWN",
    "LIS_OUT_OF_MEMORY",
    "LIS_MAXITER",
    "LIS_NOT_IMPLEMENTED",
    "LIS_ERR_FILE_IO",
];

fn set_option(solver: *mut c_void, opt: &str) {
    let mut buf = alloc::vec::Vec::with_capacity(opt.len() + 1);
    buf.extend_from_slice(opt.as_bytes());
    buf.push(0);
    unsafe { lis_solver_set_option(buf.as_mut_ptr() as *mut c_char, solver) };
}

/// C's `DATA_LIS`, held for a system's lifetime as `allocateLisData` holds it.
pub(crate) struct Solver {
    a: *mut c_void,
    b: *mut c_void,
    x: *mut c_void,
    solver: *mut c_void,
    n: usize,
}

impl Solver {
    /// `allocateLisData`, options included.
    pub(crate) fn new(n: usize) -> Option<Solver> {
        let mut s = Solver {
            a: core::ptr::null_mut(),
            b: core::ptr::null_mut(),
            x: core::ptr::null_mut(),
            solver: core::ptr::null_mut(),
            n,
        };
        let ni = n as LisInt;
        unsafe {
            lis_vector_create(LIS_COMM_WORLD, &mut s.b);
            lis_vector_set_size(s.b, ni, 0);
            lis_vector_create(LIS_COMM_WORLD, &mut s.x);
            lis_vector_set_size(s.x, ni, 0);
            lis_matrix_create(LIS_COMM_WORLD, &mut s.a);
            lis_matrix_set_size(s.a, ni, 0);
            lis_matrix_set_type(s.a, LIS_MATRIX_CSR);
            lis_solver_create(&mut s.solver);
        }
        if s.a.is_null() || s.b.is_null() || s.x.is_null() || s.solver.is_null() {
            return None;
        }
        set_option(s.solver, "-print none");
        set_option(s.solver, &alloc::format!("-maxiter {}", n * 100));
        set_option(s.solver, "-scale none");
        set_option(s.solver, "-p none");
        set_option(s.solver, "-initx_zeros 0");
        set_option(s.solver, "-tol 1.0e-12");
        Some(s)
    }

    /// Seed the iteration with `x0` (C's `aux_x`, since `-initx_zeros 0`), solve,
    /// and write the result back over `b`. `fill_a` drives `setAElementLis`: the
    /// matrix lives in Lis's own CSR, so it takes a setter rather than a buffer.
    fn solve(&mut self, fill_a: impl FnOnce(&mut dyn FnMut(usize, usize, f64)), b: &mut [f64], x0: &[f64]) -> LisInt {
        let n = self.n;
        unsafe {
            for i in 0..n {
                lis_vector_set_value(LIS_INS_VALUE, i as LisInt, x0[i], self.x);
            }
            lis_matrix_set_size(self.a, n as LisInt, 0);
            let a = self.a;
            fill_a(&mut |row, col, v| {
                lis_matrix_set_value(LIS_INS_VALUE, row as LisInt, col as LisInt, v, a);
            });
            lis_matrix_assemble(self.a);
            for i in 0..n {
                lis_vector_set_value(LIS_INS_VALUE, i as LisInt, b[i], self.b);
            }
            let err = lis_solve(self.a, self.b, self.x, self.solver);
            if err == 0 {
                lis_vector_get_values(self.x, 0, n as LisInt, b.as_mut_ptr());
            }
            err
        }
    }
}

impl Drop for Solver {
    /// `freeLisData`.
    fn drop(&mut self) {
        unsafe {
            lis_matrix_destroy(self.a);
            lis_vector_destroy(self.b);
            lis_vector_destroy(self.x);
            lis_solver_destroy(self.solver);
        }
    }
}

std::thread_local! {
    /// One [`Solver`] per system, as C allocates one in `initializeLinearSystems`.
    /// Keyed on the size too, so a caller with no handle of its own cannot be
    /// handed a solver built for another size; sharing one is otherwise harmless,
    /// since nothing but the size-derived options survives a solve.
    static CACHE: core::cell::RefCell<std::collections::HashMap<(u32, usize), Solver>> =
        core::cell::RefCell::new(std::collections::HashMap::new());
}

/// The per-system solvers belong to one run.
pub(crate) fn reset_caches() {
    CACHE.with(|c| c.borrow_mut().clear());
}

/// A cached solve. 0 solved, 1 not. `lis_solve` swallows the iteration's own
/// return code (it keeps it in `solver->retcode` and hands back `LIS_SUCCESS`), so
/// a breakdown or an exhausted iteration count counts as solved with whatever `x`
/// it reached; only a rejected method-1 step fails the system, as in C.
fn solve_cached(
    key: u32,
    n: usize,
    b: &mut [f64],
    x0: &[f64],
    eq_index: i32,
    time: f64,
    fill_a: impl FnOnce(&mut dyn FnMut(usize, usize, f64)),
) -> i32 {
    let err = CACHE.with(|cell| {
        let mut cache = cell.borrow_mut();
        let entry = match cache.entry((key, n)) {
            std::collections::hash_map::Entry::Occupied(e) => e.into_mut(),
            std::collections::hash_map::Entry::Vacant(slot) => match Solver::new(n) {
                Some(s) => slot.insert(s),
                None => return LIS_OUT_OF_MEMORY,
            },
        };
        entry.solve(fill_a, b, x0)
    });
    if err == 0 {
        return 0;
    }
    let code = usize::try_from(err).ok().and_then(|i| RETURNCODE.get(i)).copied().unwrap_or("LIS_ERR");
    crate::omclog::warning!(crate::omclog::LS_V, false, "lis_solve : {code}(code={err})");
    crate::omclog::warning!(
        crate::omclog::LS,
        false,
        "Failed to solve linear system of equations (no. {eq_index}) at time {time:.6}, system status {err}.",
    );
    1
}

/// `-ls lis` on a dense column-major `a` (`n*n`).
pub(crate) fn solve_dense(a: &[f64], b: &mut [f64], x0: &[f64], n: usize, eq_index: i32, time: f64) -> i32 {
    solve_cached(eq_index as u32, n, b, x0, eq_index, time, |set| {
        // C's `setA` passes only the structural nonzeros; a dense `A` is all we
        // have, so an exactly-zero element stands in for "not there".
        for col in 0..n {
            for row in 0..n {
                let v = a[col * n + row];
                if v != 0.0 {
                    set(row, col, v);
                }
            }
        }
    })
}

/// `-lss lis` on a CSC `A`, keyed by the caller's system handle.
pub(crate) fn solve_csc(
    key: u32,
    colptr: &[i32],
    rowidx: &[i32],
    values: &[f64],
    b: &mut [f64],
    x0: &[f64],
    n: usize,
    eq_index: i32,
    time: f64,
) -> i32 {
    solve_cached(key, n, b, x0, eq_index, time, |set| {
        for col in 0..n {
            for k in colptr[col] as usize..colptr[col + 1] as usize {
                set(rowidx[k] as usize, col, values[k]);
            }
        }
    })
}
