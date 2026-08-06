//! Which solver each `-nls` / `-nlsLS` / `-ls` / `-lss` selects.
//!
//! Set once per run and read on every solve, so it is four plain atomics rather
//! than the parsed `SimFlags` — reading that clones its `-override=` list, one
//! `String` per parameter. Both ways in end here: a host-driven run pushes the
//! codes through [`rt_set_solvers`] (that build links no flag store of its own),
//! and the in-wasm session sets them from the flags it parsed.
//!
//! The codes are `SimFlags::solver_codes`; 0 means unset, and the enums below
//! mirror `openmodelica_sim_meta::simflags`, so neither may be renumbered alone.

use core::sync::atomic::{AtomicU32, Ordering};

/// `-nls`
#[derive(Clone, Copy, PartialEq, Eq)]
pub(crate) enum Nls {
    /// Unset: the codegen's density-based choice, then the full retry ladder.
    Default,
    Hybrid,
    Kinsol,
    Newton,
    /// C's `NLS_MIXED`: `solveHomotopy` (damped Newton, minpack fallback), dense.
    Mixed,
    Homotopy,
}

/// `-nlsLS`, the linear solver inside the nonlinear one.
#[derive(Clone, Copy, PartialEq, Eq)]
pub(crate) enum NlsLs {
    Klu,
    Rsparse,
    TotalPivot,
    Lapack,
}

/// `-ls`, for a dense-stored linear system.
#[derive(Clone, Copy, PartialEq, Eq)]
pub(crate) enum Ls {
    Lapack,
    TotalPivot,
    Klu,
}

/// `-lss`, for a sparse (torn) linear system.
#[derive(Clone, Copy, PartialEq, Eq)]
pub(crate) enum Lss {
    Klu,
    Rsparse,
}

/// The backend a sparse solve runs on, once a selector has been matched to it.
#[derive(Clone, Copy, PartialEq, Eq)]
pub(crate) enum Sparse {
    Klu,
    Rsparse,
}

static NLS: AtomicU32 = AtomicU32::new(0);
static NLS_LS: AtomicU32 = AtomicU32::new(0);
static LS: AtomicU32 = AtomicU32::new(0);
static LSS: AtomicU32 = AtomicU32::new(0);
/// `-nlssMinSize` / `-nlssMaxDensity`, C's `nonlinearSparseSolverMinSize` /
/// `nonlinearSparseSolverMaxDensity`, at their defaults until a run sets them.
static NLSS_MIN_SIZE: AtomicU32 = AtomicU32::new(1000);
static NLSS_MAX_DENSITY: core::sync::atomic::AtomicU64 =
    core::sync::atomic::AtomicU64::new(0x3FB999999999999A); // 0.1

/// C's `newtonFTol` / `newtonXTol` / `maxStepFactor` (`model_help.c`), which
/// `-newtonFTol` / `-newtonXTol` / `-newtonMaxStepFactor` move. The homotopy Newton
/// and KINSOL both read them, so they live here rather than in either solver.
static NEWTON_FTOL: core::sync::atomic::AtomicU64 = core::sync::atomic::AtomicU64::new(0x3D719799812DEA11); // 1e-12
static NEWTON_XTOL: core::sync::atomic::AtomicU64 = core::sync::atomic::AtomicU64::new(0x3D719799812DEA11);
static MAX_STEP_FACTOR: core::sync::atomic::AtomicU64 = core::sync::atomic::AtomicU64::new(0x426D1A94A2000000); // 1e12

#[unsafe(no_mangle)]
pub extern "C" fn rt_set_newton_tuning(ftol: f64, xtol: f64, max_step_factor: f64) {
    NEWTON_FTOL.store(ftol.to_bits(), Ordering::Relaxed);
    NEWTON_XTOL.store(xtol.to_bits(), Ordering::Relaxed);
    MAX_STEP_FACTOR.store(max_step_factor.to_bits(), Ordering::Relaxed);
}

pub(crate) fn newton_ftol() -> f64 {
    f64::from_bits(NEWTON_FTOL.load(Ordering::Relaxed))
}

pub(crate) fn newton_xtol() -> f64 {
    f64::from_bits(NEWTON_XTOL.load(Ordering::Relaxed))
}

#[cfg(sundials)]
pub(crate) fn max_step_factor() -> f64 {
    f64::from_bits(MAX_STEP_FACTOR.load(Ordering::Relaxed))
}

/// Set the four selectors for the next run. Host-driven builds call this through
/// the export; the in-wasm session calls [`apply_flags`] instead.
#[unsafe(no_mangle)]
pub extern "C" fn rt_set_solvers(nls: u32, nls_ls: u32, ls: u32, lss: u32) {
    NLS.store(nls, Ordering::Relaxed);
    NLS_LS.store(nls_ls, Ordering::Relaxed);
    LS.store(ls, Ordering::Relaxed);
    LSS.store(lss, Ordering::Relaxed);
}

/// C's `initializeNonlinearSystemData` rule: kinsol+KLU when the density is under
/// `nlssMaxDensity` or the size over `nlssMinSize`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_set_nlss_thresholds(min_size: u32, max_density: f64) {
    NLSS_MIN_SIZE.store(min_size, Ordering::Relaxed);
    NLSS_MAX_DENSITY.store(max_density.to_bits(), Ordering::Relaxed);
}

pub(crate) fn nls_use_sparse(size: usize, nnz: usize) -> bool {
    let density = nnz as f64 / (size * size) as f64;
    density < f64::from_bits(NLSS_MAX_DENSITY.load(Ordering::Relaxed))
        || size > NLSS_MIN_SIZE.load(Ordering::Relaxed) as usize
}

#[cfg(any(feature = "session", feature = "standalone"))]
pub(crate) fn apply_flags(f: &openmodelica_sim_meta::simflags::SimFlags) {
    let (nls, nls_ls, ls, lss) = f.solver_codes();
    rt_set_solvers(nls, nls_ls, ls, lss);
    let (min_size, max_density) = openmodelica_sim_meta::simflags::nlss_thresholds(f);
    rt_set_nlss_thresholds(min_size, max_density);
    let (ftol, xtol, msf) = openmodelica_sim_meta::simflags::newton_tuning(f);
    rt_set_newton_tuning(ftol, xtol, msf);
}

pub(crate) fn nls() -> Nls {
    match NLS.load(Ordering::Relaxed) {
        1 => Nls::Hybrid,
        2 => Nls::Kinsol,
        3 => Nls::Newton,
        4 => Nls::Mixed,
        5 => Nls::Homotopy,
        _ => Nls::Default,
    }
}

/// KLU needs the SUNDIALS archives; without them every request falls to `rsparse`,
/// which is also where C's unimplemented-here values (`totalpivot`, `lapack`) go.
pub(crate) fn nls_ls() -> NlsLs {
    match NLS_LS.load(Ordering::Relaxed) {
        _ if !cfg!(sundials) => NlsLs::Rsparse,
        2 => NlsLs::TotalPivot,
        3 => NlsLs::Lapack,
        5 => NlsLs::Rsparse,
        _ => NlsLs::Klu, // 0 unset, 1 default, 4 klu — C's sparse default
    }
}

pub(crate) fn ls() -> Ls {
    match LS.load(Ordering::Relaxed) {
        3 => Ls::TotalPivot,
        4 if cfg!(sundials) => Ls::Klu,
        _ => Ls::Lapack, // 0 unset, 1 default, 2 lapack — C's dense default
    }
}

pub(crate) fn lss() -> Lss {
    match LSS.load(Ordering::Relaxed) {
        _ if !cfg!(sundials) => Lss::Rsparse,
        3 => Lss::Rsparse,
        _ => Lss::Klu, // 0 unset, 1 default, 2 klu — C's sparse default
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // The decode must agree with `SimFlags::solver_codes`, which is tested against
    // the same numbers on the other side.
    #[test]
    fn unset_codes_give_c_defaults() {
        rt_set_solvers(0, 0, 0, 0);
        assert!(nls() == Nls::Default);
        assert!(ls() == Ls::Lapack);
        // KLU is the sparse default only where the archives are linked.
        assert!(lss() == if cfg!(sundials) { Lss::Klu } else { Lss::Rsparse });
    }

    #[test]
    fn codes_select_their_solver() {
        rt_set_solvers(2, 2, 3, 3);
        assert!(nls() == Nls::Kinsol);
        assert!(ls() == Ls::TotalPivot);
        assert!(lss() == Lss::Rsparse);
        assert!(nls_ls() == if cfg!(sundials) { NlsLs::TotalPivot } else { NlsLs::Rsparse });
        rt_set_solvers(0, 0, 0, 0);
    }
}
