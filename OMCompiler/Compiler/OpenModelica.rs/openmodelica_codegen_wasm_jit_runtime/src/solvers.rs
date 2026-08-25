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
    Umfpack,
    Lis,
}

/// `-lss`, for a sparse (torn) linear system.
#[derive(Clone, Copy, PartialEq, Eq)]
pub(crate) enum Lss {
    Klu,
    Umfpack,
    Rsparse,
    Lis,
}

/// The backend a *direct* sparse solve runs on, once a selector has been matched
/// to it. Iterative Lis needs an initial guess, so `-lss lis` is served earlier.
#[derive(Clone, Copy, PartialEq, Eq)]
pub(crate) enum Sparse {
    Klu,
    Umfpack,
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

/// `-lvMaxWarn`, C's `maxWarnDisplays` (`DEFAULT_FLAG_LV_MAX_WARN`).
static MAX_WARN_DISPLAYS: AtomicU32 = AtomicU32::new(3);

#[unsafe(no_mangle)]
pub extern "C" fn rt_set_max_warn(n: u32) {
    MAX_WARN_DISPLAYS.store(n, Ordering::Relaxed);
}

pub(crate) fn max_warn_displays() -> u64 {
    MAX_WARN_DISPLAYS.load(Ordering::Relaxed) as u64
}

/// `-ils` (C's `init_lambda_steps`, default 3) and `-homotopyOnFirstTry` /
/// `-noHomotopyOnFirstTry` as C's tri-state flag: 0 unset, 1 on, 2 off.
static INIT_LAMBDA_STEPS: AtomicU32 = AtomicU32::new(3);
static HOMOTOPY_ON_FIRST_TRY: AtomicU32 = AtomicU32::new(0);

#[unsafe(no_mangle)]
pub extern "C" fn rt_set_homotopy(init_lambda_steps: u32, on_first_try: u32) {
    INIT_LAMBDA_STEPS.store(init_lambda_steps, Ordering::Relaxed);
    HOMOTOPY_ON_FIRST_TRY.store(on_first_try, Ordering::Relaxed);
}

pub(crate) fn init_lambda_steps() -> i32 {
    INIT_LAMBDA_STEPS.load(Ordering::Relaxed) as i32
}

/// C sets the flag itself for a model with homotopy support, so an unset flag
/// reads as set here (only `-noHomotopyOnFirstTry` turns it off).
pub(crate) fn homotopy_on_first_try() -> bool {
    HOMOTOPY_ON_FIRST_TRY.load(Ordering::Relaxed) != 2
}

/// C's `model_help.c` homotopy constants. A cell rather than atomics: read once
/// per run, and the runtime is single-threaded (as `nls::RosterCell`).
struct HomCell(core::cell::UnsafeCell<openmodelica_sim_meta::simflags::HomTuning>);
unsafe impl Sync for HomCell {}
static HOM: HomCell = HomCell(core::cell::UnsafeCell::new(
    openmodelica_sim_meta::simflags::HomTuning {
        adapt_bend: 0.5,
        h_eps: 1e-5,
        tau_dec: 10.0,
        tau_dec_pred: 2.0,
        tau_inc: 2.0,
        tau_inc_threshold: 10.0,
        tau_max: 10.0,
        tau_min: 1e-4,
        tau_start: 0.2,
        max_lambda_steps: 0,
        max_newton_steps: 20,
        max_tries: 10,
        orthogonal_backtrace: false,
        neg_start_dir: false,
    },
));

pub(crate) fn hom_tuning() -> openmodelica_sim_meta::simflags::HomTuning {
    unsafe { *HOM.0.get() }
}

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub extern "C" fn rt_set_homotopy_tuning(
    adapt_bend: f64,
    h_eps: f64,
    tau_dec: f64,
    tau_dec_pred: f64,
    tau_inc: f64,
    tau_inc_threshold: f64,
    tau_max: f64,
    tau_min: f64,
    tau_start: f64,
    max_lambda_steps: u32,
    max_newton_steps: u32,
    max_tries: u32,
    orthogonal_backtrace: u32,
    neg_start_dir: u32,
) {
    unsafe {
        *HOM.0.get() = openmodelica_sim_meta::simflags::HomTuning {
            adapt_bend,
            h_eps,
            tau_dec,
            tau_dec_pred,
            tau_inc,
            tau_inc_threshold,
            tau_max,
            tau_min,
            tau_start,
            max_lambda_steps,
            max_newton_steps,
            max_tries,
            orthogonal_backtrace: orthogonal_backtrace != 0,
            neg_start_dir: neg_start_dir != 0,
        };
    }
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

/// Mirrors `BackendDAEUtil.useSparseSolver`, which chose this system's format.
pub(crate) fn nls_use_sparse(size: usize, nnz: usize) -> bool {
    let density = nnz as f64 / (size * size) as f64;
    density < f64::from_bits(NLSS_MAX_DENSITY.load(Ordering::Relaxed))
        || size > NLSS_MIN_SIZE.load(Ordering::Relaxed) as usize
}

pub(crate) fn apply_flags(f: &openmodelica_sim_meta::simflags::SimFlags) {
    let (nls, nls_ls, ls, lss) = f.solver_codes();
    rt_set_solvers(nls, nls_ls, ls, lss);
    let (ftol, xtol, msf) = openmodelica_sim_meta::simflags::newton_tuning(f);
    rt_set_newton_tuning(ftol, xtol, msf);
    rt_set_max_warn(f.max_warn.unwrap_or(3));
    let (steps, first) = openmodelica_sim_meta::simflags::homotopy_codes(f);
    rt_set_homotopy(steps, first);
    let h = openmodelica_sim_meta::simflags::hom_tuning(f);
    rt_set_homotopy_tuning(
        h.adapt_bend, h.h_eps, h.tau_dec, h.tau_dec_pred, h.tau_inc, h.tau_inc_threshold,
        h.tau_max, h.tau_min, h.tau_start, h.max_lambda_steps, h.max_newton_steps, h.max_tries,
        h.orthogonal_backtrace as u32, h.neg_start_dir as u32,
    );
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
        5 if cfg!(sundials) => Ls::Umfpack,
        6 if cfg!(sundials) => Ls::Lis,
        _ => Ls::Lapack, // 0 unset, 1 default, 2 lapack — C's dense default
    }
}

pub(crate) fn lss() -> Lss {
    match LSS.load(Ordering::Relaxed) {
        5 if cfg!(sundials) => Lss::Lis,
        _ if !cfg!(sundials) => Lss::Rsparse,
        3 => Lss::Rsparse,
        4 => Lss::Umfpack,
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
