//! Ipopt's C interface (`IpStdCInterface.h`), as the optimization runtime uses it.
//!
//! `ipnumber` is `double` and `ipindex` is `int` for the in-tree build
//! (`IPOPT_SINGLE=OFF`, `IPOPT_INT64=OFF`); the callbacks return C `bool`, which
//! is Rust's `bool`. Only the entry points `optimizer_main.c` calls are declared.

use core::ffi::{c_char, c_int, c_void};

pub type Number = f64;
pub type Index = c_int;

/// Opaque `IpoptProblem`.
#[repr(transparent)]
#[derive(Clone, Copy)]
pub struct Problem(*mut c_void);

impl Problem {
    pub fn is_null(self) -> bool {
        self.0.is_null()
    }
}

pub type EvalF =
    unsafe extern "C" fn(Index, *mut Number, bool, *mut Number, *mut c_void) -> bool;
pub type EvalGradF =
    unsafe extern "C" fn(Index, *mut Number, bool, *mut Number, *mut c_void) -> bool;
pub type EvalG =
    unsafe extern "C" fn(Index, *mut Number, bool, Index, *mut Number, *mut c_void) -> bool;
#[allow(clippy::type_complexity)]
pub type EvalJacG = unsafe extern "C" fn(
    Index,
    *mut Number,
    bool,
    Index,
    Index,
    *mut Index,
    *mut Index,
    *mut Number,
    *mut c_void,
) -> bool;
#[allow(clippy::type_complexity)]
pub type EvalH = unsafe extern "C" fn(
    Index,
    *mut Number,
    bool,
    Number,
    Index,
    *mut Number,
    bool,
    Index,
    *mut Index,
    *mut Index,
    *mut Number,
    *mut c_void,
) -> bool;

unsafe extern "C" {
    #[allow(clippy::too_many_arguments)]
    fn CreateIpoptProblem(
        n: Index,
        x_l: *mut Number,
        x_u: *mut Number,
        m: Index,
        g_l: *mut Number,
        g_u: *mut Number,
        nele_jac: Index,
        nele_hess: Index,
        index_style: Index,
        eval_f: EvalF,
        eval_g: EvalG,
        eval_grad_f: EvalGradF,
        eval_jac_g: EvalJacG,
        eval_h: EvalH,
    ) -> Problem;
    fn FreeIpoptProblem(p: Problem);
    fn AddIpoptStrOption(p: Problem, keyword: *const c_char, val: *const c_char) -> bool;
    fn AddIpoptNumOption(p: Problem, keyword: *const c_char, val: Number) -> bool;
    fn AddIpoptIntOption(p: Problem, keyword: *const c_char, val: Index) -> bool;
    fn IpoptSolve(
        p: Problem,
        x: *mut Number,
        g: *mut Number,
        obj_val: *mut Number,
        mult_g: *mut Number,
        mult_x_l: *mut Number,
        mult_x_u: *mut Number,
        user_data: *mut c_void,
    ) -> c_int;
}

/// `ApplicationReturnStatus`, as far as `runOptimizer` distinguishes them.
pub const SOLVE_SUCCEEDED: c_int = 0;
pub const SOLVED_TO_ACCEPTABLE_LEVEL: c_int = 1;

/// An `IpoptProblem` that frees itself, so an early return cannot leak it.
pub struct Nlp {
    problem: Problem,
}

impl Drop for Nlp {
    fn drop(&mut self) {
        if !self.problem.is_null() {
            unsafe { FreeIpoptProblem(self.problem) };
        }
    }
}

/// The callback set, in `CreateIpoptProblem` order.
pub struct Callbacks {
    pub f: EvalF,
    pub g: EvalG,
    pub grad_f: EvalGradF,
    pub jac_g: EvalJacG,
    pub h: EvalH,
}

/// The problem's bounds. Each slice is handed to Ipopt, which copies it.
pub struct Bounds<'a> {
    pub x_min: &'a mut [Number],
    pub x_max: &'a mut [Number],
    pub g_min: &'a mut [Number],
    pub g_max: &'a mut [Number],
    pub nele_jac: usize,
    pub nele_hess: usize,
}

impl Nlp {
    /// C's `CreateIpoptProblem` with 0-based (C-style) triplet indices.
    pub fn new(b: Bounds<'_>, cb: Callbacks) -> Result<Self, &'static str> {
        let n = b.x_min.len();
        let m = b.g_min.len();
        if b.x_max.len() != n || b.g_max.len() != m {
            return Err("Ipopt: mismatched bound array lengths");
        }
        let problem = unsafe {
            CreateIpoptProblem(
                n as Index,
                b.x_min.as_mut_ptr(),
                b.x_max.as_mut_ptr(),
                m as Index,
                b.g_min.as_mut_ptr(),
                b.g_max.as_mut_ptr(),
                b.nele_jac as Index,
                b.nele_hess as Index,
                0,
                cb.f,
                cb.g,
                cb.grad_f,
                cb.jac_g,
                cb.h,
            )
        };
        if problem.is_null() {
            return Err("Ipopt: CreateIpoptProblem failed");
        }
        Ok(Nlp { problem })
    }

    /// The option setters. A rejected keyword is a programming error here (the set
    /// of options is fixed), so it is reported rather than ignored.
    pub fn str_option(&self, keyword: &str, val: &str) -> bool {
        let (k, v) = (cstr(keyword), cstr(val));
        unsafe { AddIpoptStrOption(self.problem, k.as_ptr(), v.as_ptr()) }
    }
    pub fn num_option(&self, keyword: &str, val: f64) -> bool {
        let k = cstr(keyword);
        unsafe { AddIpoptNumOption(self.problem, k.as_ptr(), val) }
    }
    pub fn int_option(&self, keyword: &str, val: i32) -> bool {
        let k = cstr(keyword);
        unsafe { AddIpoptIntOption(self.problem, k.as_ptr(), val) }
    }

    /// C's `IpoptSolve`. `x` is the starting point on entry and the solution on
    /// exit; the multiplier arrays are read for a warm start and written back.
    /// `user_data` reaches the callbacks unmodified.
    #[allow(clippy::too_many_arguments)]
    pub fn solve(
        &self,
        x: &mut [Number],
        obj: &mut Number,
        mult_g: &mut [Number],
        mult_x_l: &mut [Number],
        mult_x_u: &mut [Number],
        user_data: *mut c_void,
    ) -> c_int {
        unsafe {
            IpoptSolve(
                self.problem,
                x.as_mut_ptr(),
                core::ptr::null_mut(),
                obj,
                mult_g.as_mut_ptr(),
                mult_x_l.as_mut_ptr(),
                mult_x_u.as_mut_ptr(),
                user_data,
            )
        }
    }
}

/// A NUL-terminated copy for the `char*` options; the C side copies the string.
fn cstr(s: &str) -> alloc::vec::Vec<c_char> {
    s.bytes().map(|b| b as c_char).chain(core::iter::once(0)).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use core::ffi::c_void;

    // HS071 from Ipopt's own C example: min x1*x4*(x1+x2+x3) + x3 subject to
    // x1*x2*x3*x4 >= 25 and sum(xi^2) == 40, 1 <= xi <= 5. Solving it end to end
    // is what proves the archive set, the callback ABI and the option setters.
    unsafe extern "C" fn f(_n: Index, x: *mut Number, _new: bool, obj: *mut Number, _u: *mut c_void) -> bool {
        let x = unsafe { core::slice::from_raw_parts(x, 4) };
        unsafe { *obj = x[0] * x[3] * (x[0] + x[1] + x[2]) + x[2] };
        true
    }
    unsafe extern "C" fn grad_f(_n: Index, x: *mut Number, _new: bool, g: *mut Number, _u: *mut c_void) -> bool {
        let x = unsafe { core::slice::from_raw_parts(x, 4) };
        let g = unsafe { core::slice::from_raw_parts_mut(g, 4) };
        g[0] = x[3] * (2.0 * x[0] + x[1] + x[2]);
        g[1] = x[0] * x[3];
        g[2] = x[0] * x[3] + 1.0;
        g[3] = x[0] * (x[0] + x[1] + x[2]);
        true
    }
    unsafe extern "C" fn g(_n: Index, x: *mut Number, _new: bool, _m: Index, out: *mut Number, _u: *mut c_void) -> bool {
        let x = unsafe { core::slice::from_raw_parts(x, 4) };
        let out = unsafe { core::slice::from_raw_parts_mut(out, 2) };
        out[0] = x[0] * x[1] * x[2] * x[3];
        out[1] = x.iter().map(|v| v * v).sum();
        true
    }
    #[allow(clippy::too_many_arguments)]
    unsafe extern "C" fn jac_g(
        _n: Index, x: *mut Number, _new: bool, _m: Index, _nele: Index,
        i_row: *mut Index, j_col: *mut Index, values: *mut Number, _u: *mut c_void,
    ) -> bool {
        if values.is_null() {
            let (r, c) = unsafe {
                (core::slice::from_raw_parts_mut(i_row, 8), core::slice::from_raw_parts_mut(j_col, 8))
            };
            for k in 0..8 {
                r[k] = (k / 4) as Index;
                c[k] = (k % 4) as Index;
            }
        } else {
            let x = unsafe { core::slice::from_raw_parts(x, 4) };
            let v = unsafe { core::slice::from_raw_parts_mut(values, 8) };
            v[0] = x[1] * x[2] * x[3];
            v[1] = x[0] * x[2] * x[3];
            v[2] = x[0] * x[1] * x[3];
            v[3] = x[0] * x[1] * x[2];
            for k in 0..4 {
                v[4 + k] = 2.0 * x[k];
            }
        }
        true
    }
    // Exact Hessian is optional for this check; BFGS keeps the test to the ABI.
    #[allow(clippy::too_many_arguments)]
    unsafe extern "C" fn h(
        _n: Index, _x: *mut Number, _new: bool, _of: Number, _m: Index, _l: *mut Number,
        _nl: bool, _nele: Index, _r: *mut Index, _c: *mut Index, _v: *mut Number, _u: *mut c_void,
    ) -> bool {
        false
    }

    #[test]
    fn solves_hs071() {
        let mut x_min = [1.0; 4];
        let mut x_max = [5.0; 4];
        let mut g_min = [25.0, 40.0];
        let mut g_max = [2e19, 40.0];
        let nlp = Nlp::new(
            Bounds {
                x_min: &mut x_min,
                x_max: &mut x_max,
                g_min: &mut g_min,
                g_max: &mut g_max,
                nele_jac: 8,
                nele_hess: 10,
            },
            Callbacks { f, g, grad_f, jac_g, h },
        )
        .expect("CreateIpoptProblem");
        assert!(nlp.str_option("hessian_approximation", "limited-memory"));
        assert!(nlp.num_option("tol", 1e-8));
        assert!(nlp.int_option("print_level", 0));
        let mut x = [1.0, 5.0, 5.0, 1.0];
        let mut obj = 0.0;
        let mut mult_g = [0.0; 2];
        let mut mult_l = [0.0; 4];
        let mut mult_u = [0.0; 4];
        let status =
            nlp.solve(&mut x, &mut obj, &mut mult_g, &mut mult_l, &mut mult_u, core::ptr::null_mut());
        assert_eq!(status, SOLVE_SUCCEEDED);
        // The documented optimum.
        let expect = [1.0, 4.743, 3.821, 1.379];
        for (got, want) in x.iter().zip(expect) {
            assert!((got - want).abs() < 1e-3, "x = {x:?}");
        }
        assert!((obj - 17.014).abs() < 1e-3, "obj = {obj}");
    }
}
