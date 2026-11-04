//! The real SUNDIALS/KLU, cross-compiled to wasm and linked in by `build.rs`
//! (`cfg(sundials)`): the SuiteSparse solvers behind this runtime's *linear*
//! systems. KINSOL, which the nonlinear ones use, is
//! [`openmodelica_nls::kinsol`] -- shared with the runtime the C code generator
//! links -- and is re-exported at the end of this file under the names
//! `src/nls.rs` calls it by.
//!
//! Indices here are `i32` (`SUNDIALS_INDEX_SIZE=32`, see the build script for why)
//! and `sunrealtype` is `f64`. The shared binding cannot assume that: the host
//! archives are built with 64-bit indices, so it takes them as `SunIndex`.

/// Whether the real solvers are linked into this blob.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sundials_available() -> i32 {
    cfg!(sundials) as i32
}

/// What this build can serve, for `simflags::check`.
pub fn capabilities() -> openmodelica_sim_meta::simflags::Capabilities {
    openmodelica_sim_meta::simflags::Capabilities {
        klu: groups::klu(),
        kinsol: groups::kinsol(),
        lis: groups::lis(),
        ida: openmodelica_sim_meta::IDA && groups::driver(),
        cvode: openmodelica_sim_meta::CVODE && groups::driver(),
        // Served by the driver's per-step deadline; both runtimes install a clock.
        alarm: true,
        // No regex engine in wasm; the model's own filter is resolved at codegen.
        variable_filter: false,
        // Ipopt has no wasm build (MUMPS is Fortran), so `method="optimization"`
        // reports "Ipopt is needed but not available." here.
        optimization: false,
        // Both runtimes drive a whole trajectory, which is all QSS can do.
    }
}

/// Which solver libraries this build has. An FMU links one PIC side module per
/// library, chosen at export, so the answer is a run-time one: the stub standing in
/// for what was left out answers 0 where a real module answers 1. Every other build
/// links the archives statically and has all of them or none.
#[cfg(sundials_dylink)]
mod groups {
    unsafe extern "C" {
        fn om_have_klu() -> i32;
        fn om_have_kinsol() -> i32;
        fn om_have_lis() -> i32;
        fn om_have_sundials_driver() -> i32;
    }
    macro_rules! ask {
        ($name:ident, $sym:ident) => {
            pub fn $name() -> bool {
                unsafe { $sym() != 0 }
            }
        };
    }
    ask!(klu, om_have_klu);
    ask!(kinsol, om_have_kinsol);
    ask!(lis, om_have_lis);
    ask!(driver, om_have_sundials_driver);
}

#[cfg(not(sundials_dylink))]
mod groups {
    macro_rules! ask {
        ($name:ident) => {
            pub fn $name() -> bool {
                cfg!(sundials)
            }
        };
    }
    ask!(klu);
    ask!(kinsol);
    ask!(lis);
    ask!(driver);
}

/// Whether KINSOL is linked. Only an FMU answers no: what its export left out is a
/// stub that traps, and no flag records the density rule's choice of KINSOL.
pub(crate) fn have_kinsol() -> bool {
    groups::kinsol()
}

/// The same for KLU.
pub(crate) fn have_klu() -> bool {
    groups::klu()
}

/// Smoke test that the archives are linked and callable: `klu_defaults` reports
/// success and its values land where the shared mirror puts them, and KINSOL
/// allocates.
#[cfg(sundials)]
#[unsafe(no_mangle)]
pub extern "C" fn rt_sundials_selftest() -> i32 {
    let common_ok = openmodelica_solvers::klu::layout_ok();
    (common_ok && openmodelica_nls::kinsol::sun::probe()) as i32
}

#[cfg(not(sundials))]
#[unsafe(no_mangle)]
pub extern "C" fn rt_sundials_selftest() -> i32 {
    0
}

/// The CSC of `Aᵀ` KLU factorizes, as C's `setAElementKlu` fills it, plus `perm`:
/// where each entry reads from in the caller's CSC-of-`A` values.
#[cfg(sundials)]
pub(crate) struct Transposed {
    ap: alloc::vec::Vec<i32>,
    ai: alloc::vec::Vec<i32>,
    perm: alloc::vec::Vec<u32>,
    ax: alloc::vec::Vec<f64>,
}

#[cfg(sundials)]
impl Transposed {
    fn new(n: usize, colptr: &[i32], rowidx: &[i32]) -> Option<Transposed> {
        let nnz = *colptr.get(n)? as usize;
        let mut ap = alloc::vec![0i32; n + 1];
        for &r in &rowidx[..nnz] {
            ap[r as usize + 1] += 1;
        }
        for r in 0..n {
            ap[r + 1] += ap[r];
        }
        let mut fill: alloc::vec::Vec<i32> = ap[..n].to_vec();
        let mut ai = alloc::vec![0i32; nnz];
        let mut perm = alloc::vec![0u32; nnz];
        for c in 0..n {
            for k in colptr[c] as usize..colptr[c + 1] as usize {
                let slot = &mut fill[rowidx[k] as usize];
                ai[*slot as usize] = c as i32;
                perm[*slot as usize] = k as u32;
                *slot += 1;
            }
        }
        Some(Transposed {
            ap,
            ai,
            perm,
            ax: alloc::vec![0.0f64; nnz],
        })
    }

    fn gather(&mut self, values: *const f64) {
        let src = unsafe { core::slice::from_raw_parts(values, self.perm.len()) };
        for (dst, &k) in self.ax.iter_mut().zip(&self.perm) {
            *dst = src[k as usize];
        }
    }
}

#[cfg(sundials)]
pub(crate) mod klu {
    use openmodelica_solvers::klu::Factorization;

    /// C's `DATA_KLU` over a CSC pattern: the transpose is built here and handed
    /// to the shared [`Factorization`], which carries C's refactor policy.
    ///
    /// KLU gets `Aᵀ` and a transpose solve, as in C. Factorizing `A` instead holds
    /// `rgrowth` under the 1e-3 threshold on a MultiBody chain, so the pivots are
    /// rechosen every solve and `functionODE` stops being a function of the states
    /// alone — which quietly ruins any finite-difference Jacobian taken through it.
    pub struct Solver {
        fact: Factorization,
        t: super::Transposed,
    }

    impl Solver {
        /// `colptr`/`rowidx` are the caller's CSC of `A`; the transpose is built here.
        pub fn new(n: usize, colptr: &[i32], rowidx: &[i32]) -> Option<Solver> {
            let mut t = super::Transposed::new(n, colptr, rowidx)?;
            let fact = Factorization::analyze(n, &mut t.ap, &mut t.ai)?;
            Some(Solver { fact, t })
        }

        /// Factorize with `values` (the caller's CSC-of-`A` order) and solve
        /// `A x = b` in place. `false` if the matrix is singular or a KLU call failed.
        pub fn solve(&mut self, values: *const f64, b: *mut f64, n: usize) -> bool {
            self.t.gather(values);
            let t = &mut self.t;
            self.fact.factor(&mut t.ap, &mut t.ai, &mut t.ax)
                && self.fact.tsolve(unsafe { core::slice::from_raw_parts_mut(b, n) })
        }
    }
}

#[cfg(sundials)]
std::thread_local! {
    /// One [`klu::Solver`] per system `handle`, so the symbolic analysis is done
    /// once per run as it is in C.
    static KLU_CACHE: core::cell::RefCell<std::collections::HashMap<u32, klu::Solver>> =
        core::cell::RefCell::new(std::collections::HashMap::new());
}

/// Drop the per-system factorizations and KINSOL memory; they belong to one run.
pub(crate) fn reset_caches() {
    #[cfg(sundials)]
    {
        KLU_CACHE.with(|c| c.borrow_mut().clear());
        openmodelica_nls::kinsol::reset_caches();
        crate::lis::reset_caches();
    }
}

/// KLU solve of the CSC system `A x = b` (`b ← x`), reusing `handle`'s symbolic
/// analysis. 0 solved, 1 singular.
#[cfg(sundials)]
pub(crate) fn klu_solve_cached(
    handle: u32,
    colptr: u32,
    rowidx: u32,
    values: u32,
    b_ptr: u32,
    n: usize,
    nnz: usize,
) -> i32 {
    KLU_CACHE.with(|cell| {
        let mut cache = cell.borrow_mut();
        let entry = match cache.entry(handle) {
            std::collections::hash_map::Entry::Occupied(e) => e.into_mut(),
            std::collections::hash_map::Entry::Vacant(slot) => {
                let colp = unsafe { core::slice::from_raw_parts(colptr as *const i32, n + 1) };
                let rowi = unsafe { core::slice::from_raw_parts(rowidx as *const i32, nnz) };
                match klu::Solver::new(n, colp, rowi) {
                    Some(s) => slot.insert(s),
                    None => return 1,
                }
            }
        };
        !entry.solve(values as *const f64, b_ptr as *mut f64, n) as i32
    })
}

/// A dense column-major `A` as CSC of its structural nonzeros.
#[cfg(sundials)]
fn csc_from_dense(a: &[f64], n: usize) -> (alloc::vec::Vec<i32>, alloc::vec::Vec<i32>, alloc::vec::Vec<f64>) {
    let mut colptr = alloc::vec::Vec::with_capacity(n + 1);
    let mut rowidx = alloc::vec::Vec::new();
    let mut values = alloc::vec::Vec::new();
    colptr.push(0i32);
    for col in 0..n {
        for row in 0..n {
            let v = a[col * n + row];
            if v != 0.0 {
                rowidx.push(row as i32);
                values.push(v);
            }
        }
        colptr.push(rowidx.len() as i32);
    }
    (colptr, rowidx, values)
}

/// KLU solve of a dense column-major `A` (`n*n` f64 at `a_ptr`): scan the
/// structural nonzeros into CSC and factorize from scratch, there being no system
/// handle to cache under. 0 solved, 1 singular.
#[cfg(sundials)]
pub(crate) fn klu_solve_dense(a_ptr: u32, b_ptr: u32, n: usize) -> i32 {
    let a = unsafe { core::slice::from_raw_parts(a_ptr as *const f64, n * n) };
    let (colptr, rowidx, values) = csc_from_dense(a, n);
    match klu::Solver::new(n, &colptr, &rowidx) {
        Some(mut s) => !s.solve(values.as_ptr(), b_ptr as *mut f64, n) as i32,
        None => 1,
    }
}

// The KINSOL half of C's `kinsolSolver.c` / `kinsol_b.c` is
// `openmodelica_nls::kinsol`, shared with `openmodelica_simulation_runtime`: the
// binding exchanges plain slices, so both runtimes drive the same one.
#[cfg(sundials)]
pub(crate) use openmodelica_nls::kinsol::{b_solve as kinsol_b_solve, solve_selected as kinsol_solve_selected};
