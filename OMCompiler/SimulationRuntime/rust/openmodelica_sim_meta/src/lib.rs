//! Per-model simulation metadata shared between the wasm-jit codegen (host) and
//! the in-wasm simulation driver.
//!
//! The wasm-jit codegen runs on the host and knows everything about a model's
//! `SimData` layout, its result variables, and its solver structure (Jacobian
//! sparsity/coloring, dynamic state sets, per-state nominals). The driver that
//! consumes that information must be able to run **in-wasm** (so `functionODE`
//! and the Jacobian are called wasm→wasm), where it can only see the model's
//! linear memory and an embedded metadata blob. This crate is the wire format
//! between the two: the codegen builds a [`SimMeta`], [`encode`]s it into a byte
//! blob emitted as a data segment of the model module, and the driver [`decode`]s
//! it. `no_std` + `alloc`, no I/O — **one** definition of every layout offset and
//! solver descriptor so the emitter and the driver cannot drift.
//!
//! It carries exactly what the driver, the per-step row capture, the parameter
//! read-back and the `.mat` writer need: the `SimData` [`Layout`], the run
//! scalars, the ordered result variables ([`MetaVar`]), and the solver metadata
//! ([`JacAInfo`], [`StateSetInfo`], state nominals).

#![cfg_attr(not(feature = "std"), no_std)]

extern crate alloc;

use alloc::format;
use alloc::string::String;
use alloc::vec::Vec;

pub mod driver;
pub mod linearize;
// The solvers and the flags/logging they read live in `openmodelica_solvers`,
// which knows nothing about `SimData`; re-exported here so `sim_meta::gbode`
// (and the paths the codegen already uses) still name them.
pub use openmodelica_solvers::{delay, fixedstep, gbode, omclog, simflags, spatial, sysstat};
pub use openmodelica_arrow_writer::units::{BaseUnit, DisplayUnit, UnitDef};
pub use openmodelica_arrow_writer::VarTy;
/// `-csvInput`, which needs a filesystem: host builds only.
#[cfg(feature = "std")]
pub(crate) mod extinput;
/// `-reconcile*`, which needs a filesystem too.
#[cfg(feature = "std")]
pub mod datarecon;
/// `+profiling`, whose files go out through [`files`] like every other side file,
/// so an artifact's in-wasm driver reports as the host does.
pub mod profiling;
pub mod result;
pub mod strings;
/// The writer every file a run leaves beside its result goes through.
pub mod files;
pub mod optimization;
pub mod parmod;
pub(crate) mod qss;
pub mod rtclock;
/// The `LOG_STATS` block a finished run prints.
pub mod stats;
pub mod sync;
#[cfg(all(feature = "std", unix, ipopt))]
pub mod lapack_dyn;
#[cfg(not(all(feature = "std", unix, ipopt)))]
pub mod lapack_dyn {}
#[cfg(sundials)]
pub use openmodelica_solvers::sundials;

/// Whether this build's driver has the real CVODE and IDA linked in (`build.rs`),
/// so a `-s=cvode`/`-s=ida` (or `method=`) run can be served.
pub const CVODE: bool = cfg!(sundials);
pub const IDA: bool = cfg!(sundials);

/// Byte offset of `time` within `SimData`.
pub const TIME_OFF: u32 = 0;
/// Byte offset of the first real variable within `SimData`:
/// `[ time | states | ders | algs | params… ]`.
pub const REAL_OFF: u32 = 8;

/// i32 words in the fired-`terminate` info block at [`Layout::term_info_off`]:
/// `msg`, `file`, `lineStart`, `colStart`, `lineEnd`, `colEnd`, `readOnly`.
pub const TERM_INFO_WORDS: u32 = 7;

/// Bytes per base clock / sub-clock in `SimData` — the mutable half of C's
/// `BASECLOCK_DATA` / `SUBCLOCK_DATA`; the constant half is in [`BaseClockMeta`].
pub const BASECLOCK_BYTES: u32 = 40;
pub const SUBCLOCK_BYTES: u32 = 24;

/// Field offsets inside those blocks, baked into the emitted module and read back
/// by the driver.
pub mod clock_field {
    pub const INTERVAL: u32 = 0;
    pub const PREV_INTERVAL: u32 = 8;
    pub const LAST_ACTIVATION: u32 = 16;
    pub const COUNT: u32 = 24;
    pub const INTERVAL_COUNTER: u32 = 28;
    pub const RESOLUTION: u32 = 32;

    pub const SUB_PREV_INTERVAL: u32 = 0;
    pub const SUB_LAST_ACTIVATION: u32 = 8;
    pub const SUB_COUNT: u32 = 16;
}

/// The wasm value type a scalar occupies in `SimData` (4-byte `i32` for
/// Integer/Boolean, 8-byte `f64` for Real). The single definition used by both
/// the codegen and the driver.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum WTy {
    I32,
    F64,
}

/// C's `HOMOTOPY_METHOD`, selected by `--homotopyApproach` (and forced to
/// [`Self::None`] by `--replaceHomotopy`). The numbering is C's.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum HomotopyMethod {
    LocalEquidistant = 0,
    #[default]
    GlobalEquidistant = 1,
    GlobalAdaptive = 2,
    LocalAdaptive = 3,
    None = 4,
}

impl HomotopyMethod {
    pub fn from_code(c: u8) -> Self {
        match c {
            0 => Self::LocalEquidistant,
            2 => Self::GlobalAdaptive,
            3 => Self::LocalAdaptive,
            4 => Self::None,
            _ => Self::GlobalEquidistant,
        }
    }
    pub fn code(self) -> u8 {
        self as u8
    }
    /// The parameter reaches the whole initial system, not just the component.
    pub fn is_global(self) -> bool {
        matches!(self, Self::GlobalEquidistant | Self::GlobalAdaptive)
    }
    /// The step size is the arc-length continuation's, not `1/init_lambda_steps`.
    pub fn is_adaptive(self) -> bool {
        matches!(self, Self::GlobalAdaptive | Self::LocalAdaptive)
    }
}

/// Fully-resolved layout of one model's `SimData` block. All offsets are byte
/// offsets within the block; all are compile-time constants baked into the
/// generated module. This is the single source of truth: the codegen computes it
/// via [`Layout::new`] and the driver reads it back verbatim from the blob.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub struct Layout {
    pub n_states: u32,
    /// `algVars ++ discreteAlgVars` (the real algebraic variables emitted as
    /// time-variant result signals after the states and derivatives).
    pub n_real_alg: u32,
    /// `functionAlgebraics` ends with C's `storePreValues`, so a driver calls it
    /// only in the once-per-step order.
    pub has_when: bool,
    /// A nonlinear system carries the homotopy operator (C's `homotopySupport`), so
    /// the driver runs the continuation over `functionInitialEquations_lambda0`.
    pub has_homotopy: bool,
    /// `--homotopyApproach` as C's `homotopyMethod` callback field: whose
    /// continuation runs, and whether it is equidistant or adaptive.
    pub homotopy_method: HomotopyMethod,
    /// A simplified lambda = 0 system was generated, so the continuation's first
    /// step can call `functionInitialEquations_lambda0`.
    pub has_init_lambda0: bool,
    /// The model has `delay(...)` or `spatialDistribution(...)`, i.e. an operator
    /// with an internal history that `functionStoreDelayed` /
    /// `functionStoreSpatialDistribution` must be fed at every accepted point.
    pub has_history_ops: bool,
    /// The model has a `SES_LINEAR` with a symbolic Jacobian, the only reader of
    /// `old_real_off`.
    pub has_old_real: bool,
    /// `SimData` offset of the homotopy parameter lambda (f64).
    pub lambda_off: u32,
    pub rparam_off: u32,
    pub int_off: u32,
    pub iparam_off: u32,
    pub bool_off: u32,
    pub bparam_off: u32,
    /// String algebraic variables (one i32 String handle each).
    pub str_off: u32,
    /// String parameters (one i32 String handle each).
    pub sparam_off: u32,
    /// External-object variables (one i32 pointer-registry handle each).
    pub eobj_off: u32,
    /// `pre()` regions parallel to the live variable regions.
    pub pre_real_off: u32,
    pub pre_int_off: u32,
    pub pre_bool_off: u32,
    /// C's `data->localData[1]->realVars`: the reals as of the last accepted step,
    /// a method-1 linear system's `aux_x`.
    pub old_real_off: u32,
    /// `terminate(...)` flag (i32).
    pub terminate_off: u32,
    /// `terminal()` flag (i32): C's `data->simulationInfo->terminal`, raised by
    /// the driver for the run's final discrete update.
    pub terminal_off: u32,
    /// `initial()` flag (i32): C's `data->simulationInfo->initial`, raised by the
    /// driver for the whole initialization phase.
    pub initial_off: u32,
    /// C's `TermMsg`/`TermInfo`: the fired `terminate(...)`'s message and source
    /// position, as `[msg, file, lineStart, colStart, lineEnd, colEnd, readOnly]`
    /// (i32 each; the first two are String handles).
    pub term_info_off: u32,
    /// Number of result rows actually written (i32).
    pub n_out_off: u32,
    /// Nonlinear-solver failure flag (i32).
    pub nls_fail_off: u32,
    /// Number of `sample(...)` time events.
    pub n_samples: u32,
    /// Base of the sample parameter region (start/interval f64 pairs).
    pub sample_off: u32,
    /// Base of the per-sample `active` flags (one i32 each).
    pub sample_active_off: u32,
    /// Number of state-event zero-crossing functions.
    pub n_zc: u32,
    /// Base of the zero-crossing value region (one f64 per crossing).
    pub zc_off: u32,
    /// `zeroCrossingsPre`: the previous accepted g-value of each crossing (one f64
    /// per crossing). `delayZeroCrossing` reads it; the driver snapshots it from
    /// `zc_off` at init and after each accepted point/event.
    pub zc_pre_off: u32,
    /// Where an integrator's root callback writes its g-values (one f64 per
    /// crossing): C's `gout`, kept apart from `zc_off` so a probe never overwrites
    /// the accepted-point snapshot.
    pub zc_probe_off: u32,
    /// Number of indexed relations (hysteresis count).
    pub n_rel: u32,
    /// Base of the held relation values (one i32 per indexed relation).
    pub relations_off: u32,
    /// Relation evaluation mode (i32): 0 held, 1 event, 2 initialization.
    pub rel_fresh_off: u32,
    /// `storedRelations` snapshot (one i32 per relation).
    pub stored_rel_off: u32,
    /// `relationsPre` (one i32 per relation).
    pub relations_pre_off: u32,
    /// Base of the state-set Jacobian scratch region (f64).
    pub stateset_off: u32,
    /// Base of the nonlinear-system analytic-Jacobian scratch region (f64): the
    /// per-system seed and column-result slots the emitted `nls_jac` callbacks use.
    pub nls_jac_off: u32,
    /// `mathEventsValuePre` length.
    pub n_math: u32,
    /// Base of the held math-event values (f64 each).
    pub mathevents_off: u32,
    /// Zero-crossing hysteresis tolerance slot (f64).
    pub zctol_off: u32,
    /// C's `realVarsData[i].attribute.start`: one f64 per real variable, in
    /// real-variable index order (states, derivatives, algebraics).
    /// `functionInitStartValues` fills it; `-iif`/`-override` may replace entries;
    /// the driver then copies it over the live region (C's `setAllVarsToStart`).
    pub start_off: u32,
    /// C's `realVarsData[i].attribute.nominal` as declared, one f64 per real
    /// variable in [`Layout::start_off`] order. [`Layout::state_nom_off`] is the
    /// integrator's clamped copy.
    pub real_nom_off: u32,
    /// Base of the per-state `nominal` attribute (one f64 per state), written by
    /// `functionUpdateBoundVariableAttributes` once the parameters are computed.
    /// `fmax(|nominal|, 1e-32)` rather than the attribute itself: it is the
    /// integrator's `atol` scale and the Jacobian's FD step floor.
    pub state_nom_off: u32,
    /// Base of the per-state `max` attribute, written the same way; C's
    /// `functionJacAC_num` flips its difference quotient at the bound.
    pub state_max_off: u32,
    /// Base of the linearization scratch (f64): the symbolic `A|B|C|D` the
    /// `linearJac*` fill (column-major), then their seed/`$pDER` slots.
    pub linz_off: u32,
    pub n_linz: u32,
    /// `method="optimization"`: the attribute arrays C reads out of the `_init.xml`
    /// (`realVarsData[i].attribute`), one entry per real variable in real-variable
    /// index order — `min`, `max`, `nominal` as f64 and `useNominal` as i32
    /// (`start` is [`Layout::start_off`], which every model has). Written by
    /// `functionUpdateBoundVariableAttributes` once the parameters are known; the
    /// optimizer also *writes* `nominal` back, as C does.
    /// `n_opt_attr` is 0 for a model without an optimization problem.
    pub n_opt_attr: u32,
    pub opt_min_off: u32,
    pub opt_max_off: u32,
    pub opt_nom_off: u32,
    pub opt_use_nom_off: u32,
    /// C's `simulationInfo->sensitivityMatrix`: `d(state)/d(parameter)`,
    /// parameter-major, written by the IDA driver from `IDAGetSens` and captured
    /// as a result row's last columns.
    pub n_sens: u32,
    pub sens_off: u32,
    /// `--daeMode`: C's `daeModeData->nResidualVars`, also the size of the implicit
    /// system IDA solves. 0 ⇒ an explicit ODE, and no `dae_*` region exists.
    pub n_dae_res: u32,
    /// Base of `daeModeData->residualVars` (f64 each).
    pub dae_res_off: u32,
    pub n_dae_aux: u32,
    /// Base of `daeModeData->auxiliaryVars` (f64 each).
    pub dae_aux_off: u32,
    /// `daeModeData->nAlgebraicDAEVars`: the unknowns IDA carries after the states,
    /// so `n_dae_res == n_states + n_dae_alg`.
    pub n_dae_alg: u32,
    /// Base of their `nominal` attributes, written like `state_nom_off`.
    pub dae_alg_nom_off: u32,
    /// Number of synchronous base clocks (`SimCode.clockedPartitions`).
    pub n_base_clocks: u32,
    /// Base of the per-base-clock state ([`BASECLOCK_BYTES`] each).
    pub clock_off: u32,
    /// Total number of sub-clocks over all base clocks.
    pub n_sub_clocks: u32,
    /// Base of the per-sub-clock state ([`SUBCLOCK_BYTES`] each), flattened in
    /// base-clock order — [`BaseClockMeta::sub_base`] indexes into it.
    pub subclock_off: u32,
    /// Base of the per-base-clock `$_clkfire` flags (one i32 each): an event
    /// clock's `when`-body raises its flag, the driver fires and clears it.
    pub clock_fire_off: u32,
    /// One f64 per attribute `functionUpdateBoundVariableAttributes` computes; C
    /// prints those values from inside that function, which the driver cannot.
    pub n_attr_log: u32,
    pub attr_log_off: u32,
    /// C's `compiledWithSymSolver` (`--symSolver`): 0 none, 1 `impEuler`, 2
    /// `expEuler`. Nonzero ⇒ the module exports `symbolicInlineSystem` and the two
    /// regions below exist.
    pub sym_solver: u8,
    /// C's `simulationInfo->inlineData`: the step size `__OMC_DT` (f64) the inline
    /// equations read, and the `<state>$Old` values (one f64 per state) they step
    /// from.
    pub inline_dt_off: u32,
    pub alg_old_off: u32,
    /// Residuals `functionRemovedInitialEquations` checks; 0 ⇒ it is a stub.
    pub n_removed_init: u32,
    /// The rejected residual (f64) and its 1-based index (i32); index 0 ⇒ consistent.
    pub removed_init_res_off: u32,
    pub removed_init_idx_off: u32,
    pub total: u32,
}

impl Layout {
    /// Compute the `SimData` layout from a model's variable/solver counts. The
    /// codegen's single call site; the byte offsets it derives are exactly what
    /// the emitted module bakes in and the driver reads back.
    #[allow(clippy::too_many_arguments)]
    pub fn new(
        n_states: u32,
        n_real_alg: u32,
        n_real_param: u32,
        n_int_alg: u32,
        n_int_param: u32,
        n_bool_alg: u32,
        n_bool_param: u32,
        n_str_alg: u32,
        n_str_param: u32,
        n_eobj: u32,
        n_samples: u32,
        n_zc: u32,
        n_rel: u32,
        n_stateset_f64: u32,
        n_nlsjac_f64: u32,
        n_math: u32,
        n_sens: u32,
        n_dae_res: u32,
        n_dae_aux: u32,
        n_dae_alg: u32,
        n_base_clocks: u32,
        n_sub_clocks: u32,
        n_linz: u32,
        n_opt_attr: u32,
        n_attr_log: u32,
        n_removed_init: u32,
        sym_solver: u8,
        has_when: bool,
        has_homotopy: bool,
        homotopy_method: HomotopyMethod,
        has_init_lambda0: bool,
        has_history_ops: bool,
        has_old_real: bool,
    ) -> Self {
        let n_real = 2 * n_states + n_real_alg; // states | ders | algs
        let rparam_off = REAL_OFF + n_real * 8;
        let int_off = rparam_off + n_real_param * 8;
        let iparam_off = int_off + n_int_alg * 4;
        let bool_off = iparam_off + n_int_param * 4;
        let bparam_off = bool_off + n_bool_alg * 4;
        let str_off = bparam_off + n_bool_param * 4;
        let sparam_off = str_off + n_str_alg * 4;
        let eobj_off = sparam_off + n_str_param * 4;
        // pre() region, 8-aligned so the real pre-slots are naturally aligned.
        let pre_real_off = (eobj_off + n_eobj * 4 + 7) & !7;
        let pre_int_off = pre_real_off + n_real * 8;
        let pre_bool_off = pre_int_off + n_int_alg * 4;
        let old_real_off = (pre_bool_off + n_bool_alg * 4 + 7) & !7;
        let terminate_off = old_real_off + if has_old_real { n_real * 8 } else { 0 };
        let terminal_off = terminate_off + 4;
        let initial_off = terminal_off + 4;
        let term_info_off = initial_off + 4;
        let n_out_off = term_info_off + TERM_INFO_WORDS * 4;
        let nls_fail_off = n_out_off + 4;
        let lambda_off = (nls_fail_off + 4 + 7) & !7;
        let sample_off = (lambda_off + 8 + 7) & !7;
        let sample_active_off = sample_off + n_samples * 16;
        let zc_off = (sample_active_off + n_samples * 4 + 7) & !7;
        let zc_pre_off = zc_off + n_zc * 8;
        let zc_probe_off = zc_pre_off + n_zc * 8;
        let relations_off = zc_probe_off + n_zc * 8;
        let rel_fresh_off = relations_off + n_rel * 4;
        let stored_rel_off = rel_fresh_off + 4;
        let relations_pre_off = stored_rel_off + n_rel * 4;
        let stateset_off = (relations_pre_off + n_rel * 4 + 7) & !7;
        let nls_jac_off = stateset_off + n_stateset_f64 * 8;
        let mathevents_off = nls_jac_off + n_nlsjac_f64 * 8;
        let n_math_slots = if n_math > 0 { n_math + 2 } else { 0 };
        let zctol_off = mathevents_off + n_math_slots * 8;
        let start_off = zctol_off + 8;
        let real_nom_off = start_off + n_real * 8;
        let state_nom_off = real_nom_off + n_real * 8;
        let state_max_off = state_nom_off + n_states * 8;
        let sens_off = state_max_off + n_states * 8;
        let dae_res_off = sens_off + n_sens * 8;
        let dae_aux_off = dae_res_off + n_dae_res * 8;
        let dae_alg_nom_off = dae_aux_off + n_dae_aux * 8;
        let clock_off = dae_alg_nom_off + n_dae_alg * 8;
        let subclock_off = clock_off + n_base_clocks * BASECLOCK_BYTES;
        let clock_fire_off = subclock_off + n_sub_clocks * SUBCLOCK_BYTES;
        let linz_off = (clock_fire_off + n_base_clocks * 4 + 7) & !7;
        let opt_min_off = linz_off + n_linz * 8;
        let opt_max_off = opt_min_off + n_opt_attr * 8;
        let opt_nom_off = opt_max_off + n_opt_attr * 8;
        let opt_use_nom_off = opt_nom_off + n_opt_attr * 8;
        let attr_log_off = (opt_use_nom_off + n_opt_attr * 4 + 7) & !7;
        let removed_init_res_off = attr_log_off + n_attr_log * 8;
        let removed_init_idx_off = removed_init_res_off + 8;
        let inline_dt_off = (removed_init_idx_off + 4 + 7) & !7;
        let alg_old_off = inline_dt_off + if sym_solver > 0 { 8 } else { 0 };
        let total = alg_old_off + if sym_solver > 0 { n_states * 8 } else { 0 };
        Layout {
            n_states, n_real_alg, has_when, has_homotopy, homotopy_method, has_init_lambda0, has_history_ops, has_old_real, lambda_off, rparam_off, int_off, iparam_off,
            bool_off, bparam_off, str_off, sparam_off, eobj_off, pre_real_off, pre_int_off, pre_bool_off, old_real_off,
            terminate_off, terminal_off, initial_off, term_info_off, n_out_off, nls_fail_off, n_samples, sample_off, sample_active_off, n_zc, zc_off, zc_pre_off, zc_probe_off,
            n_rel, relations_off, rel_fresh_off, stored_rel_off, relations_pre_off, stateset_off, nls_jac_off, n_math,
            mathevents_off, zctol_off, start_off, real_nom_off, state_nom_off, state_max_off, n_sens, sens_off,
            n_dae_res, dae_res_off, n_dae_aux, dae_aux_off, n_dae_alg, dae_alg_nom_off,
            n_base_clocks, clock_off, n_sub_clocks, subclock_off, clock_fire_off, linz_off, n_linz,
            n_opt_attr, opt_min_off, opt_max_off, opt_nom_off, opt_use_nom_off,
            n_attr_log, attr_log_off,
            n_removed_init, removed_init_res_off, removed_init_idx_off,
            sym_solver, inline_dt_off, alg_old_off, total,
        }
    }

    /// Byte offset of base clock `i`'s state block.
    pub fn base_clock_off(&self, i: u32) -> u32 {
        self.clock_off + i * BASECLOCK_BYTES
    }
    /// Byte offset of the sub-clock at flat index `k`.
    pub fn sub_clock_off(&self, k: u32) -> u32 {
        self.subclock_off + k * SUBCLOCK_BYTES
    }

    /// Byte offset of real variable `i`'s `start` attribute slot.
    pub fn real_start_off(&self, i: u32) -> u32 {
        self.start_off + i * 8
    }

    /// Byte offset of real variable `i`'s `nominal` attribute slot.
    pub fn real_nominal_off(&self, i: u32) -> u32 {
        self.real_nom_off + i * 8
    }

    /// C's `compiledInDAEMode`: the integrator solves `F(t, y, y') = 0` over states
    /// *and* algebraic unknowns through `evaluateDAEResiduals`, not `functionODE`.
    pub fn dae_mode(&self) -> bool {
        self.n_dae_res > 0
    }

    /// Offset of the `pre()` slot mirroring a live variable slot at byte offset
    /// `off`, if `off` is in a variable region that carries pre-values.
    pub fn pre_slot_off(&self, off: u32) -> Option<u32> {
        if off >= REAL_OFF && off < self.rparam_off {
            Some(self.pre_real_off + (off - REAL_OFF))
        } else if off >= self.int_off && off < self.iparam_off {
            Some(self.pre_int_off + (off - self.int_off))
        } else if off >= self.bool_off && off < self.bparam_off {
            Some(self.pre_bool_off + (off - self.bool_off))
        } else {
            None
        }
    }

    /// Bytes the live real region (states | derivatives | algebraics) spans.
    pub fn real_bytes(&self) -> usize {
        ((2 * self.n_states + self.n_real_alg) * 8) as usize
    }

    /// f64 in the real part of a result row: `time` + states + derivatives + real
    /// algebraics.
    pub fn n_reals_row(&self) -> u32 {
        1 + 2 * self.n_states + self.n_real_alg
    }
    /// Integer algebraic variables (between `int_off` and `iparam_off`).
    pub fn n_int_alg(&self) -> u32 {
        (self.iparam_off - self.int_off) / 4
    }
    /// Boolean algebraic variables (between `bool_off` and `bparam_off`).
    pub fn n_bool_alg(&self) -> u32 {
        (self.bparam_off - self.bool_off) / 4
    }
    /// String algebraic variables (between `str_off` and `sparam_off`).
    pub fn n_str_alg(&self) -> u32 {
        (self.sparam_off - self.str_off) / 4
    }
    /// Total f64 columns in a result row: the real part, the integer and boolean
    /// algebraics (captured per row as f64), the sensitivities, then the String
    /// algebraics as interned ids ([`crate::strings`]).
    pub fn n_row_total(&self) -> u32 {
        self.n_reals_row() + self.n_int_alg() + self.n_bool_alg() + self.n_sens + self.n_str_alg()
    }
    /// First result-row column of the String block.
    pub fn str_col0(&self) -> u32 {
        self.sens_col0() + self.n_sens
    }
    /// First result-row column of the sensitivity block.
    pub fn sens_col0(&self) -> u32 {
        self.n_reals_row() + self.n_int_alg() + self.n_bool_alg()
    }
}

/// How a negated alias derives its value. C's `crefToCStr` negates a Boolean
/// logically, everything else arithmetically.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum Neg {
    #[default]
    None,
    /// `-v`
    Arith,
    /// `!v`, i.e. `1 - v` over the 0/1 encoding.
    Not,
}

impl Neg {
    pub fn apply_f64(self, v: f64) -> f64 {
        match self {
            Neg::None => v,
            Neg::Arith => -v,
            Neg::Not => 1.0 - v,
        }
    }
    pub fn apply_i32(self, v: i32) -> i32 {
        match self {
            Neg::None => v,
            Neg::Arith => -v,
            Neg::Not => (v == 0) as i32,
        }
    }
    /// Compose one more negation step (an alias of an alias).
    pub fn toggle(self, is_bool: bool) -> Neg {
        match self {
            Neg::None if is_bool => Neg::Not,
            Neg::None => Neg::Arith,
            _ => Neg::None,
        }
    }
    fn code(self) -> u8 {
        match self {
            Neg::None => 0,
            Neg::Arith => 1,
            Neg::Not => 2,
        }
    }
    fn from_code(c: u8) -> Neg {
        match c {
            1 => Neg::Arith,
            2 => Neg::Not,
            _ => Neg::None,
        }
    }
}

/// How a result signal sources its value (the run-time superset of
/// `openmodelica_mat_writer::MatKind`: `Param` additionally carries the `SimData`
/// offset/type so the driver can read the parameter's value back after the run).
#[derive(Clone, PartialEq, Debug)]
pub enum MetaKind {
    /// The independent variable, `time`.
    Time,
    /// A time-variant real signal at result-buffer column `col` (`negate` for a
    /// negated alias).
    Column { col: u32, negate: Neg },
    /// A time-invariant parameter read from `SimData` at byte offset `off` as
    /// `wty` (`negate` for a negated alias).
    Param { off: u32, wty: WTy, negate: Neg },
    /// A compile-time constant.
    Const { value: f64 },
}

impl MetaKind {
    /// Project onto the `.mat` writer's kind.
    pub fn mat(&self) -> openmodelica_mat_writer::MatKind {
        use openmodelica_mat_writer::{MatKind, Neg as MatNeg};
        let neg = |n: &Neg| match n {
            Neg::None => MatNeg::None,
            Neg::Arith => MatNeg::Arith,
            Neg::Not => MatNeg::Not,
        };
        match self {
            MetaKind::Time => MatKind::Time,
            MetaKind::Column { col, negate } => MatKind::Column { col: *col, negate: neg(negate) },
            MetaKind::Param { negate, .. } => MatKind::Param { negate: neg(negate) },
            MetaKind::Const { value } => MatKind::Const { value: *value },
        }
    }

    /// Project onto the `.arrow` writer's kind.
    pub fn arrow(&self) -> openmodelica_arrow_writer::ArrowKind {
        use openmodelica_arrow_writer::{Affine, ArrowKind};
        let affine = |n: &Neg| match n {
            Neg::None => Affine::IDENTITY,
            Neg::Arith => Affine::NEGATE,
            Neg::Not => Affine::NOT,
        };
        match self {
            MetaKind::Time => ArrowKind::Time,
            MetaKind::Column { col, negate } => ArrowKind::Column { col: *col, affine: affine(negate) },
            MetaKind::Param { negate, .. } => ArrowKind::Param { affine: affine(negate) },
            MetaKind::Const { value } => ArrowKind::Const { value: *value },
        }
    }

    /// Project onto the `.plt` writer's kind.
    pub fn plt(&self) -> openmodelica_plt_writer::PltKind {
        use openmodelica_plt_writer::{Neg as PltNeg, PltKind};
        let neg = |n: &Neg| match n {
            Neg::None => PltNeg::None,
            Neg::Arith => PltNeg::Arith,
            Neg::Not => PltNeg::Not,
        };
        match self {
            MetaKind::Time => PltKind::Time,
            MetaKind::Column { col, negate } => PltKind::Column { col: *col, negate: neg(negate) },
            MetaKind::Param { negate, .. } => PltKind::Param { negate: neg(negate) },
            MetaKind::Const { value } => PltKind::Const { value: *value },
        }
    }
}

/// One result signal (C-compatible order: time, states, derivatives, algebraics,
/// then parameters).
#[derive(Clone, PartialEq, Debug)]
pub struct MetaVar {
    pub name: String,
    pub comment: String,
    pub unit: String,
    pub display_unit: String,
    /// FMI's `relativeQuantity`: the value is a difference in its unit, so a
    /// conversion scales it but adds no offset.
    pub relative_quantity: bool,
    pub ty: VarTy,
    /// A discrete-time variable (changes only at events).
    pub discrete: bool,
    pub kind: MetaKind,
    /// C's `filterOutput`, split into its reasons ([`var_filter`]).
    pub filter: u8,
    /// C's `time_unvarying`: a `Column` computed once during initialization
    /// (a literal parameter equation), which the `.mat` stores in `data_1`.
    pub unvarying: bool,
    /// The literals of an enumeration variable (`ty` is `Integer`).
    pub enumeration: Option<Vec<String>>,
}

/// The `modelData` variable arrays C's `dumpInitialSolution` walks, in print order.
/// Values, `pre`-values and real `start`s live in `SimData`; only the names and the
/// constant attributes it quotes are metadata.
#[derive(Clone, PartialEq, Debug, Default)]
pub struct SotiVars {
    /// Real variables in real-variable index order (states, derivatives, then the
    /// other reals). Their `start` and `nominal` attributes are `SimData` slots.
    pub reals: Vec<String>,
    /// Integer/Boolean variables with their `start` attribute.
    pub ints: Vec<(String, i32)>,
    pub bools: Vec<(String, i32)>,
    /// String variables with their `start` attribute.
    pub strings: Vec<(String, String)>,
    /// C's `nDiscreteRealArray`: how many of [`SotiVars::reals`] at the tail are
    /// discrete. `checkForDiscreteChanges` walks exactly those.
    pub n_discrete_real: u32,
}

/// C's `modelData` parameter arrays (name, `start`, `fixed`) in the order of the
/// `SimData` parameter regions, which hold the values `printParameters` reports.
#[derive(Clone, Debug, Default, PartialEq)]
pub struct ParamVars {
    pub reals: Vec<(String, f64, bool)>,
    pub ints: Vec<(String, i32, bool)>,
    pub bools: Vec<(String, i32, bool)>,
    /// C prints no `fixed` for a String parameter.
    pub strings: Vec<(String, String)>,
}

/// What C's `importStartValues` walks, one entry per [`IMPORT_GROUP`]: each
/// quantity's name and the slot its imported `start` goes to — the `start` attribute
/// for a real variable, the live slot for everything else.
pub type ImportRoster<'a> = [Vec<(&'a str, u32, WTy)>; 6];

/// C's `importStartValues` group headers, in the order its loops run.
pub const IMPORT_GROUP: [&str; 6] = [
    "real variables",
    "integer variables",
    "boolean variables",
    "real parameters",
    "integer parameters",
    "boolean parameters",
];

/// The variable (C's `info.name`) an [`Layout::attr_log_off`] slot belongs to, and
/// which attribute of it — an index into [`ATTR_NAME`].
#[derive(Clone, Debug, PartialEq)]
pub struct AttrLog {
    pub kind: u8,
    pub name: String,
}

/// [`AttrLog::kind`], in the group order C prints.
pub const ATTR_NAME: [&str; 4] = ["min", "max", "nominal", "start"];

/// [`MetaVar::filter`] bits: what keeps a variable out of the result file, and
/// which flag lets it back in (C's `shouldFilterOutput` +
/// `initializeOutputFilter`).
pub mod var_filter {
    /// `protected` variable; `-emit_protected` emits it.
    pub const PROTECTED: u8 = 1;
    /// `annotation(HideResult=true)`; `-ignoreHideResult` emits it.
    pub const HIDE_RESULT: u8 = 2;
    /// The model's `variableFilter` did not match the name; `-variableFilter`
    /// replaces that decision.
    pub const FILTERED: u8 = 4;
    /// An alias reading another variable's slot. Not a filter reason: it gives C's
    /// un-filter rule its direction (an emitted alias keeps its base variable).
    pub const ALIAS: u8 = 8;
    /// Protected and encrypted, which `-emit_protected` does not reach.
    pub const ENCRYPTED: u8 = 16;
}

/// ODE state-Jacobian ∂f/∂x ("A") sparsity + coloring for the colored-FD path.
#[derive(Clone, PartialEq, Debug)]
pub struct JacAInfo {
    pub n: u32,
    /// Each color: the 0-based column (state) indices perturbed together.
    pub colors: Vec<Vec<u32>>,
    /// `rows_by_col[col]` = 0-based rows nonzero in column `col` (CSC).
    pub rows_by_col: Vec<Vec<u32>>,
    /// The symbolic column evaluation — C's `JACOBIAN_AVAILABLE`; `None` is
    /// `JACOBIAN_ONLY_SPARSITY`.
    pub sym: Option<JacSym>,
}

/// What the host needs to drive `functionJacA_column`: C's `JACOBIAN` seed / result
/// arrays, here plain `SimData` slots.
#[derive(Clone, PartialEq, Debug, Default)]
pub struct JacSym {
    /// Seed slot per differentiation column, in column order.
    pub seed_offs: Vec<u32>,
    /// Result slot per row; `u32::MAX` is a structural zero (no result variable).
    pub result_offs: Vec<u32>,
    /// `functionJacA_constantEqns` has a body (C's `jacobian->constantEqns`).
    pub has_constant: bool,
    /// The adjoint (row) evaluator of a bidirectionally compiled matrix.
    pub adj: Option<JacAdj>,
}

/// C's `adjointJacobian`: `functionJacADJ_column`, seeded by row, results by column.
#[derive(Clone, PartialEq, Debug, Default)]
pub struct JacAdj {
    pub seed_offs: Vec<u32>,
    /// Result slot per column; `u32::MAX` is a structural zero.
    pub result_offs: Vec<u32>,
    /// Result and temporary slots, cleared between colors (they accumulate).
    pub zero_offs: Vec<u32>,
    pub has_constant: bool,
    /// Each color: the rows seeded together.
    pub row_colors: Vec<Vec<u32>>,
}

/// `--daeMode` metadata the [`Layout`]'s scalars cannot carry.
#[derive(Clone, PartialEq, Debug, Default)]
pub struct DaeInfo {
    /// C's `daeModeData->algIndexes` as `SimData` offsets, in the order they follow
    /// the states in IDA's `y`.
    pub alg_offs: Vec<u32>,
    /// `daeModeData->sparsePattern`: `∂F/∂(y, y')` with its coloring. `None` ⇒ no
    /// pattern, which the KLU linear solver cannot work without.
    pub sparsity: Option<JacAInfo>,
}

/// `--linearizationDumpLanguage`: the frame, the matrix rendering and the
/// file name.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum LinLanguage {
    #[default]
    Modelica,
    Matlab,
    Julia,
    Python,
}

impl LinLanguage {
    /// The extension `linearized_model` gets.
    pub fn ext(self) -> &'static str {
        match self {
            LinLanguage::Modelica => ".mo",
            LinLanguage::Matlab => ".m",
            LinLanguage::Julia => ".jl",
            LinLanguage::Python => ".py",
        }
    }
}

/// One `input`/`output` variable's `SimData` slot.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub struct LinVar {
    pub off: u32,
    pub negate: Neg,
}

/// What `-l` needs beyond the ODE: C's `nInputVars`/`nOutputVars` as `SimData`
/// slots (standing in for its `input_function`/`output_function`), and the
/// `linear_model_frame()` the code generator baked the dump language into.
#[derive(Clone, PartialEq, Debug, Default)]
pub struct LinInfo {
    /// Slots of the top-level `input` variables, in `u`/`B` column order.
    pub input_vars: Vec<LinVar>,
    /// Slots of the top-level `output` variables, in `y`/`C` row order.
    pub output_vars: Vec<LinVar>,
    pub language: LinLanguage,
    /// C's `linear_model_frame()` / `linear_model_datarecovery_frame()`: a printf
    /// frame with `%s` per matrix/vector (and `%g` for the stop time). Empty is
    /// what the template emits when linearization is disabled or too big.
    pub frame: String,
    pub frame_datarec: String,
    /// What C's empty frame prints before it.
    pub disabled_reason: String,
    /// Bit `k` ⇒ matrix `k` (`A`,`B`,`C`,`D`) has a symbolic `linearJac*` export,
    /// C's `initialAnalyticJacobian<X>` availability. Bit 0 is also C's
    /// `sizeTmpVars > 0`, which decides whether the numeric pass runs.
    pub sym_mask: u8,
    /// C's `modelData->runTestsuite`: shortens the created-model notice.
    pub run_testsuite: bool,
    /// Rows of each matrix: `nStates` for `A`/`B`, `nOutputVars` for `C`/`D`.
    pub jac_rows: [u32; 4],
    pub jac_cols: [u32; 4],
}

/// One variable a data-reconciliation list names, C's `dataReconciliationInputNames`
/// / `dataReconciliationUnmeasuredVariables` entry paired with its `SimData` slot.
#[derive(Clone, PartialEq, Debug, Default)]
pub struct ReconVar {
    pub off: u32,
    pub negate: Neg,
    pub name: String,
    /// C's `attribute.displayUnit` and `info.comment`, quoted by the reports.
    pub unit: String,
    pub comment: String,
}

/// A symbolic Jacobian the reconciliation drives (C's `INDEX_JAC_F` / `INDEX_JAC_H`).
/// `off` is where the matching export writes the finished `rows * cols` matrix,
/// column-major, as C's `getJacobianMatrixF` assembles it.
#[derive(Clone, PartialEq, Eq, Debug, Default)]
pub struct ReconJac {
    pub rows: u32,
    pub cols: u32,
    pub off: u32,
}

/// What `-reconcile`/`-reconcileBoundaryConditions`/`-reconcileState` need: the
/// three variable lists C's `data_function`/`setc_function`/`setb_function` copy
/// between `SimData` and `simulationInfo`, and the two Jacobians.
#[derive(Clone, PartialEq, Debug, Default)]
pub struct ReconInfo {
    /// C's `datainputVars`: the measured variables of interest, written before
    /// each `functionDAE` and named in the reports.
    pub input_vars: Vec<ReconVar>,
    /// C's `setcVars`: the auxiliary conditions' residuals, read after it.
    pub setc_vars: Vec<ReconVar>,
    /// C's `setbVars`: the unmeasured variables of interest.
    pub setb_vars: Vec<ReconVar>,
    pub jac_f: Option<ReconJac>,
    pub jac_h: Option<ReconJac>,
    /// C's `modelData->nRelatedBoundaryConditions`, counted by the code generator.
    pub n_related_boundary: u32,
    /// C's `modelData->modelFileName` and `modelDir`, quoted by the HTML reports.
    pub model_file: String,
    pub model_dir: String,
    /// C's `CONFIG_VERSION`, which the reports sign themselves with.
    pub version: String,
}

/// The compile-time half of C's `SUBCLOCK_DATA` (its `CLOCK_STATS` live in `SimData`).
#[derive(Clone, PartialEq, Eq, Debug, Default)]
pub struct SubClockMeta {
    /// `shiftCounter/resolution` of `shiftSample`/`backSample`, relative to the
    /// base clock.
    pub shift_num: i64,
    pub shift_den: i64,
    /// `subSample(u, f)` is `f/1`, `superSample(u, f)` is `1/f`.
    pub factor_num: i64,
    pub factor_den: i64,
    /// Trigger an event at the sub-clock's activation time.
    pub hold_events: bool,
    /// The sub-clock names a `solverMethod` (C's `"External"`). Only the
    /// `LOG_SYNCHRONOUS` dump distinguishes it; it is driven like any other.
    pub external_solver: bool,
}

/// The compile-time half of C's `BASECLOCK_DATA`.
#[derive(Clone, PartialEq, Eq, Debug, Default)]
pub struct BaseClockMeta {
    pub is_event_clock: bool,
    /// An `INFERRED_CLOCK` base clock, defaulted to `Clock(1, 1)` with a warning.
    pub inferred: bool,
    /// Flat index of this clock's first sub-clock in the sub-clock region.
    pub sub_base: u32,
    pub sub: Vec<SubClockMeta>,
}

/// Dynamic state-selection metadata for one `$STATESET`. All offsets are
/// SimData-relative bytes.
#[derive(Clone, PartialEq, Debug)]
pub struct StateSetInfo {
    pub n_candidates: u32,
    pub n_states: u32,
    pub n_dummy: u32,
    /// Candidate variable slots (real), candidate order (matches the seeds).
    pub candidate_offs: Vec<u32>,
    /// State variable slots (real), state order.
    pub state_offs: Vec<u32>,
    /// `A[row][col]` integer slots, row-major (`a_offs[row*n_candidates + col]`).
    pub a_offs: Vec<u32>,
    /// Jacobian seed slots (f64), candidate order: set one to 1 to pick a column.
    pub seed_offs: Vec<u32>,
    /// Jacobian result slots (f64), row order (`n_dummy` of them) — column output.
    pub result_offs: Vec<u32>,
    /// Candidate names, candidate order (C's `statescandidates[i]->name`).
    pub candidate_names: Vec<String>,
}

/// One symbolic Jacobian the optimizer differentiates through: C's
/// `analyticJacobians[INDEX_JAC_{B,C,D}]` with the parts `diffSynColoredOptimizerSystem`
/// reads. Not square (B/C are `nStates+nInputVars` columns by
/// `nStates + nOptimizeConstraints (+ lagrange, + mayer)` rows), so both dimensions
/// are carried.
#[derive(Clone, PartialEq, Debug, Default)]
pub struct OptJac {
    pub n_cols: u32,
    pub n_rows: u32,
    /// Each color: the 0-based columns seeded together (C's `sparsePattern->colorCols`
    /// inverted, as [`JacAInfo::colors`]).
    pub colors: Vec<Vec<u32>>,
    /// `rows_by_col[col]` = the 0-based nonzero rows of that column (C's
    /// `leadindex`/`index` pair).
    pub rows_by_col: Vec<Vec<u32>>,
    /// Seed slots in column order (C's `seedVars`): the optimizer writes the
    /// variable's nominal value into the columns of one color and 0 elsewhere.
    pub seed_offs: Vec<u32>,
    /// Result slots in row order (C's `resultVars`).
    pub result_offs: Vec<u32>,
    /// Model export evaluating one column, and the seed-independent equations to
    /// run first (C's `constantEqns`); empty when there are none.
    pub column_fn: String,
    pub const_fn: String,
}

/// C's `$OMC$objectMayerTerm`: the real-variable index holding the term's value
/// and the Jacobian rows its derivative lands in (C's `index_Dres` / `index_DresB`
/// / `index_DresC`, its `derIndex`). A row is `None` when the backend did not
/// differentiate the term into that matrix.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub struct OptTerm {
    pub index: u32,
    pub row_b: Option<u32>,
    pub row_c: Option<u32>,
}

/// What `method="optimization"` needs from the model beyond the ODE: the
/// constraint counts, the objective terms, the input variables and the symbolic
/// Jacobians. `None` ⇒ the model was not translated with
/// `--generateDynamicJacobian`/Optimica, and C's generated `mayer`/`lagrange`
/// stubs would report "The model was not compiled with -g=Optimica".
#[derive(Clone, PartialEq, Debug, Default)]
pub struct OptInfo {
    /// C's `nOptimizeConstraints` / `nOptimizeFinalConstraints`. Their variables are
    /// the *last* real variables, so the first constrained index (C's `index_con`)
    /// is `n_real - (n_con + n_final_con)`.
    pub n_con: u32,
    pub n_final_con: u32,
    /// Real-variable indices of the `input` variables, in C's `inputVars` order —
    /// the optimizer's `u` (C's `getInputVarIndicesInOptimization`).
    pub inputs: Vec<u32>,
    /// C's `OPT_LOOP_INPUT`: an input whose value is taken from another variable's
    /// slot when the initial guess comes from a file (C's `setInputData(data, 1)`).
    /// Pairs of (input index into [`inputs`], source real index).
    pub loop_inputs: Vec<(u32, u32)>,
    pub mayer: Option<OptTerm>,
    pub lagrange: Option<OptTerm>,
    /// Every real variable's name, in real-variable index order. C reads
    /// `realVarsData[i].info.name`; the result variables are not enough here — an
    /// input or a constraint variable (`$y`, `$EqCon$y`) is not among them.
    pub real_names: Vec<String>,
    /// C's `getTimeGrid`: the `$OPT_TGRID` parameter slots defining a model-supplied
    /// time grid; empty ⇒ the equidistant grid from `numberOfIntervals`.
    pub tgrid: Vec<u32>,
    /// Slot holding the Optimica `startTime` class attribute (C's `startTimeOpt`,
    /// which starts a pre-simulation phase before `t0`); `None` ⇒ C's default of
    /// `startTime - 1.0`, i.e. no pre-simulation.
    pub start_time_opt: Option<u32>,
    /// C's `INDEX_JAC_B`/`_C`/`_D`. `B` and `C` are required (the constraint
    /// Jacobian and its final-point variant); `D` exists only with final
    /// constraints.
    pub jac_b: Option<OptJac>,
    pub jac_c: Option<OptJac>,
    pub jac_d: Option<OptJac>,
}

/// Solver statistics filled by the driver and rendered into the simulation log by
/// the host (`LOG_STATS`, mirroring the C runtime's `### STATISTICS ###`).
#[derive(Default, Clone, Debug)]
pub struct SolveStats {
    pub method: &'static str,
    pub steps: u64,
    pub res_evals: u64,
    pub jac_evals: u64,
    pub err_test_fails: u64,
    pub conv_test_fails: u64,
    pub state_events: u64,
    pub time_events: u64,
    pub lin_solves: u64,
    /// [`rtclock`] at the end of the run: seconds per clock, and how often each was
    /// opened. Travels with the stats so an in-wasm run's timers reach the host.
    pub timers: [f64; rtclock::N],
    pub tcalls: [u64; rtclock::N],
    /// Per linear/nonlinear system, for `LOG_STATS_V`. Read out of the wasm runtime
    /// (which solves them) by the host after the run; empty unless it was on.
    pub systems: alloc::vec::Vec<sysstat::SysStat>,
}

/// One FMI value reference and the `SimData` slot it names. The value references
/// are `SimCodeUtil.getFMI3ValueReference`'s, so they cannot be derived from the
/// layout geometry -- the codegen records the mapping here instead.
#[derive(Clone, Copy, PartialEq, Debug)]
pub struct FmiVr {
    pub vr: u32,
    pub off: u32,
    pub wty: WTy,
    /// The variable is a negated alias of the slot at `off`; a read negates it.
    pub negate: Neg,
    /// A real variable's `start` attribute slot, 0 for everything else. An
    /// Initialization Mode set must land here: `setAllVarsToStart` runs after the
    /// parameter overrides and would overwrite `off` from it.
    pub start_off: u32,
    /// The variable is a String: `off` is its i32 runtime-String-handle slot, so
    /// the adapter reads/writes it through `rt_str_*` rather than as a number.
    pub is_string: bool,
    /// The slot of this output's derivative (`$<name>_der`, which
    /// `-d=fmuExperimental` adds), 0 for everything else. What
    /// `fmi2GetRealOutputDerivatives` reports.
    pub der_off: u32,
    /// An FMI 3.0 array variable's element count (the elements follow at
    /// `vr + 1`..), 1 for a scalar.
    pub len: u32,
}

/// The `--parmodauto` ODE task graph C reads from `<model>_ode.json`: one task per
/// ODE equation, with the tasks it reads a variable from.
#[derive(Clone, Debug, PartialEq)]
pub struct ParmodInfo {
    pub tasks: Vec<ParmodTask>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct ParmodTask {
    pub eq_index: i32,
    /// Task ids (positions in [`ParmodInfo::tasks`]) this one depends on.
    pub parents: Vec<u32>,
}

/// Everything the driver and the `.mat` writer need about one model: its layout,
/// the run scalars, the ordered result variables, and the solver metadata.
#[derive(Clone, PartialEq, Debug, Default)]
pub struct SimMeta {
    pub layout: Layout,
    pub start_time: f64,
    pub stop_time: f64,
    pub n_intervals: u32,
    /// Integration method (`"dassl"`, `"euler"`, …; empty = the dassl default).
    pub method: String,
    /// What a Co-Simulation `do-step` integrates with (C's
    /// `FMI2CS_initializeSolverData`: `-s` from `_flags.json`, else euler).
    /// Empty except for a CS export.
    pub cs_method: String,
    /// The nonlinear/linear solver selection an FMU export hard-codes, as a simflags
    /// argv fragment (`-nls=kinsol -lss=klu`). An importer has no channel to pass
    /// these, so `--fmiFlags` is consumed at export and the FMU applies them when it
    /// instantiates; the export links exactly the solver libraries they reach.
    /// Empty except for an FMU export.
    pub fmi_solver_flags: String,
    /// Relative/absolute tolerance for the adaptive integrators.
    pub tolerance: f64,
    /// Result file format (`"mat"`, `"empty"`).
    pub output_format: String,
    /// File-name prefix; the result file is `<prefix>_res.mat`.
    pub prefix: String,
    /// The model's name (diagnostics).
    pub model_name: String,
    pub vars: Vec<MetaVar>,
    /// The units [`MetaVar::unit`] and [`MetaVar::display_unit`] name, defined:
    /// the SI dimensions and the conversion to each display unit. Only the
    /// `.arrow` writer uses them; the other formats carry no unit table.
    pub units: Vec<UnitDef>,
    /// ODE state Jacobian sparsity + coloring; `None` ⇒ numerical Jacobian.
    pub jac_a: Option<JacAInfo>,
    /// Dynamic state selection metadata (one per `$STATESET`); empty otherwise.
    pub state_sets: Vec<StateSetInfo>,
    /// FMI value reference -> `SimData` slot, sorted by `vr`. Only filled for the
    /// FMU export; empty for a plain simulation.
    pub fmi_vrs: Vec<FmiVr>,
    /// fmi-ls-dae's `EnableDAE` structural parameter, the value reference that
    /// switches a `--daeMode` FMU into DAE mode; 0 for an FMU without one.
    pub fmi_dae_enable_vr: u32,
    /// Per-zero-crossing description (Modelica source of the relation, e.g.
    /// `x > 0.0`), 1:1 with the layout's zero-crossings — the driver names the
    /// culprit crossing in the chattering message. Empty ⇒ descriptions absent.
    pub zc_desc: Vec<String>,
    /// Per-relation description, 1:1 with the layout's relations — C's
    /// `relationDescription`, dumped in the `LOG_EVENTS` relation status block.
    pub rel_desc: Vec<String>,
    /// C's `samplesInfo[i].index`, 1:1 with the layout's samples; named in the
    /// `LOG_EVENTS` time-event line.
    pub sample_index: Vec<i32>,
    /// C's `modelData` variable arrays, for the `LOG_SOTI` initialization dump.
    pub soti: SotiVars,
    /// C's `modelData` parameter arrays, for the `LOG_INIT_V` parameter dump.
    pub params: ParamVars,
    /// 1:1 with the [`Layout::attr_log_off`] slots.
    pub attr_log: Vec<AttrLog>,
    /// Modelica source of each residual `functionRemovedInitialEquations` checks;
    /// C bakes the same text into the generated `errorStreamPrint`.
    pub removed_init_desc: Vec<String>,
    /// C's `initializeNonlinearSystems` startup warnings, decided at compile time:
    /// so far only a sparsity pattern `sparsitySanityCheck` rejects.
    pub nls_warnings: Vec<String>,
    /// C's `simulationInfo->sensitivityParList`: the `SimData` offsets of the
    /// parameters `--calculateSensitivities` selected, in block order.
    pub sens_params: Vec<u32>,
    /// Per nonlinear system, its equation index and the iteration variables in
    /// solver order — C reads the same list out of the `_info.json` `defines` array
    /// to name the unknowns in its `-lv=LOG_NLS` blocks.
    pub nls_vars: Vec<NlsVars>,
    /// C's `modelData->nLinearSystems`, which `initializeLinearSystems` announces.
    pub n_lin_systems: u32,
    /// `--daeMode` solver metadata; `Some` exactly when [`Layout::dae_mode`].
    pub dae: Option<DaeInfo>,
    /// Synchronous base clocks in `base_idx` order; empty for a model with no
    /// clocked partitions.
    pub clocks: Vec<BaseClockMeta>,
    /// What `-l` needs; `None` for a target that emits no linearization support.
    pub lin: Option<LinInfo>,
    /// The `--parmodauto` ODE task graph; `None` for a model translated without it.
    pub parmod: Option<ParmodInfo>,
    /// What `method="optimization"` needs; `None` for a model without an
    /// optimization problem.
    pub opt: Option<OptInfo>,
    /// C's `modelData->nInputVars` / `inputNames`: each `input` variable in
    /// declaration order. `-csvInput` matches its columns against the names.
    pub inputs: Vec<InputVar>,
    /// What the `-reconcile*` procedures need; `None` unless the model was
    /// translated with `--preOptModules+=dataReconciliation`.
    pub recon: Option<ReconInfo>,
    /// `+profiling`; `None` for a model translated without it.
    pub prof: Option<ProfInfo>,
}

/// One `input` variable. C writes the file's value both to the `start` attribute,
/// for `setAllVarsToStart` to publish (`start_off`), and to the variable itself
/// before every evaluation (`off`); a non-real input has only the one slot.
#[derive(Clone, Debug, PartialEq)]
pub struct InputVar {
    pub off: u32,
    pub start_off: u32,
    pub wty: WTy,
    /// The result name the file's column header has to match.
    pub name: String,
}

/// A source position, as C's `FILE_INFO`.
#[derive(Clone, Debug, Default, PartialEq)]
pub struct SrcInfo {
    pub file: String,
    pub line_start: i32,
    pub col_start: i32,
    pub line_end: i32,
    pub col_end: i32,
    pub read_only: bool,
}

/// What `+profiling` reports on (`_prof.xml` / `_prof.json`): C's `modelDataXml`
/// functions and equations plus the `modelData` variable arrays.
#[derive(Clone, Debug, Default, PartialEq)]
pub struct ProfInfo {
    /// C's `measure_time_flag`: 1 `blocks`, 5 `blocks+html`, 2 `all`.
    pub level: u8,
    /// In `modelInfo.functions` order — the clock index of function `i` is `i`.
    pub functions: Vec<ProfFn>,
    /// C's `modelData` variable arrays in `printModelInfo` order.
    pub vars: Vec<ProfVar>,
    /// Dense by equation index (`_info.json` position); index 0 is the dummy.
    pub equations: Vec<ProfEq>,
    /// Equation index of profile block `k` — clock `functions.len() + k`.
    pub blocks: Vec<u32>,
}

#[derive(Clone, Debug, Default, PartialEq)]
pub struct ProfFn {
    pub name: String,
    pub info: SrcInfo,
}

#[derive(Clone, Debug, Default, PartialEq)]
pub struct ProfVar {
    pub id: u32,
    pub name: String,
    pub comment: String,
    pub info: SrcInfo,
}

#[derive(Clone, Debug, Default, PartialEq)]
pub struct ProfEq {
    pub id: u32,
    /// The variables the equation defines (`_info.json` `defines`).
    pub defines: Vec<String>,
}

/// [`SimMeta::nls_vars`] entry.
#[derive(Clone, Debug, Default, PartialEq)]
pub struct NlsVars {
    pub eq_index: u32,
    pub names: Vec<String>,
    /// The tail of C's `eqn_simcode_indices` — the SimCode index of each residual
    /// equation, in solver order, which `LOG_NLS_SVD` and
    /// `LOG_NLS_NEWTON_DIAGNOSTICS` name their rows by. C keeps the torn equations
    /// ahead of them and slices; only the tail is read.
    pub eqns: Vec<i32>,
    /// C's `NONLINEAR_PATTERN` counts: equations, unknowns, nonlinear entries.
    pub pattern: [u32; 3],
    /// In the section `LOG_NLS_NEWTON_DIAGNOSTICS` reports on (see
    /// `newtonDiagnostics`'s caller in C's `solve_nonlinear_system`).
    pub init_diag: bool,
}

impl SimMeta {
    pub fn cs_method(&self) -> &str {
        if self.cs_method.is_empty() { &self.method } else { &self.cs_method }
    }

    /// [`ImportRoster`] for this model: the codegen resolves the `-iif` file against
    /// it and the driver applies the result, so both index the same list.
    pub fn import_roster(&self) -> ImportRoster<'_> {
        let l = &self.layout;
        fn group<'a>(names: Vec<&'a str>, off: &dyn Fn(usize) -> u32, wty: WTy) -> Vec<(&'a str, u32, WTy)> {
            names.into_iter().enumerate().map(|(i, n)| (n, off(i), wty)).collect()
        }
        [
            group(
                self.soti.reals.iter().map(|n| n.as_str()).collect(),
                &|i| l.real_start_off(i as u32),
                WTy::F64,
            ),
            group(
                self.soti.ints.iter().map(|(n, _)| n.as_str()).collect(),
                &|i| l.int_off + i as u32 * 4,
                WTy::I32,
            ),
            group(
                self.soti.bools.iter().map(|(n, _)| n.as_str()).collect(),
                &|i| l.bool_off + i as u32 * 4,
                WTy::I32,
            ),
            group(
                self.params.reals.iter().map(|(n, _, _)| n.as_str()).collect(),
                &|i| l.rparam_off + i as u32 * 8,
                WTy::F64,
            ),
            group(
                self.params.ints.iter().map(|(n, _, _)| n.as_str()).collect(),
                &|i| l.iparam_off + i as u32 * 4,
                WTy::I32,
            ),
            group(
                self.params.bools.iter().map(|(n, _, _)| n.as_str()).collect(),
                &|i| l.bparam_off + i as u32 * 4,
                WTy::I32,
            ),
        ]
    }

    /// Number of equidistant output rows the run writes, before C's terminal step
    /// adds its own. `n_intervals + 1` for a real interval; a zero-length run
    /// (`stop <= start`) writes the start point only, regardless of
    /// `numberOfIntervals`.
    pub fn n_output_rows(&self) -> u32 {
        if self.stop_time > self.start_time {
            self.n_intervals + 1
        } else {
            1
        }
    }

    /// Which of [`vars`](Self::vars) the result file holds, in order: C's
    /// `filterOutput` as the file is opened.
    ///
    /// `matcher` is a compiled `-variableFilter` (wrapped in C's `^(…)$`) and
    /// *replaces* [`var_filter::FILTERED`]; `None` keeps it. A plain parameter is
    /// exempt either way — `initializeOutputFilter` never touches one.
    pub fn output_keep(&self, matcher: Option<&dyn Fn(&str) -> bool>) -> Vec<bool> {
        let (emit_protected, ignore_hide) =
            crate::simflags::with_flags(|f| (f.emit_protected, f.ignore_hide_result));
        let mut keep: Vec<bool> = self
            .vars
            .iter()
            .map(|v| {
                if matches!(v.kind, MetaKind::Time) {
                    return true; // never filtered
                }
                // C's `shouldFilterOutput`: either flag *clears* the verdict both
                // reasons set, so `-emit_protected` alone emits a variable that is
                // protected *and* `HideResult=true`.
                let protected = v.filter & var_filter::PROTECTED != 0;
                let hidden = v.filter & var_filter::HIDE_RESULT != 0;
                let mut filtered = protected || hidden;
                if protected && emit_protected && v.filter & var_filter::ENCRYPTED == 0 {
                    filtered = false;
                }
                if hidden && ignore_hide {
                    filtered = false;
                }
                if filtered {
                    return false;
                }
                let is_param =
                    matches!(v.kind, MetaKind::Param { .. }) && v.filter & var_filter::ALIAS == 0;
                match matcher {
                    Some(m) if !is_param => m(&v.name),
                    _ => v.filter & var_filter::FILTERED == 0,
                }
            })
            .collect();
        // `Const` has no slot to share.
        let slot_of = |v: &MetaVar| match v.kind {
            MetaKind::Column { col, .. } => Some((0u8, col)),
            MetaKind::Param { off, .. } => Some((1u8, off)),
            _ => None,
        };
        let mut needed = alloc::collections::BTreeSet::new();
        for (i, v) in self.vars.iter().enumerate() {
            if keep[i] && v.filter & var_filter::ALIAS != 0 {
                needed.extend(slot_of(v));
            }
        }
        if !needed.is_empty() {
            for (i, v) in self.vars.iter().enumerate() {
                if !keep[i] && v.filter & var_filter::ALIAS == 0 {
                    keep[i] = slot_of(v).is_some_and(|s| needed.contains(&s));
                }
            }
        }
        keep
    }

    /// C's result-file resolution (`simulation_runtime.cpp`): `-r` outright, else
    /// `<prefix>_res.<format>` under `-outputPath`. What a driver that writes the
    /// file itself names it, and what `+profiling` reports as `outputFilename`.
    pub fn result_file(&self) -> String {
        crate::simflags::with_flags(|f| match (&f.result_file, &f.output_path) {
            (Some(r), _) => r.clone(),
            (None, Some(dir)) => format!("{dir}/{}_res.{}", self.prefix, self.output_format),
            (None, None) => format!("{}_res.{}", self.prefix, self.output_format),
        })
    }

    /// C's `simulationInfo->stepSize`: the output interval `SimCodeMain` writes into
    /// the init XML, or the `-stepSize` override. Solver policy reads it too (the NLS
    /// initial-guess window, the chattering limit), so it is not only the grid.
    pub fn step_size(&self) -> f64 {
        if let Some(h) = crate::simflags::with_flags(|f| f.step_size) {
            return h;
        }
        self.translated_step_size()
    }

    /// [`step_size`](Self::step_size) as the model was translated, ignoring
    /// `-stepSize`: what C reads out of the init XML.
    fn translated_step_size(&self) -> f64 {
        let n = if self.n_intervals > 0 { self.n_intervals } else { 500 };
        (self.stop_time - self.start_time) / n as f64
    }

    /// C's `read_experiment` (`simulation_input_xml.c`) plus the step-size checks
    /// `solver_main.c` makes right after it: the run scalars the model was translated
    /// with, overridden by the command line. [`n_intervals`](Self::n_intervals) is C's
    /// `numSteps`, which the output grid is cut from, so a moved step size lands there.
    ///
    /// Called once per run by whichever entry point owns the driver.
    pub fn apply_flags(&mut self, f: &crate::simflags::SimFlags) {
        use crate::omclog::{self, STDOUT};
        let translated = self.translated_step_size();
        let mut recalc = false;
        if let Some(t) = f.start_time {
            self.start_time = t;
            recalc = true;
        }
        if let Some(t) = f.stop_time {
            self.stop_time = t;
            recalc = true;
        }
        let span = self.stop_time - self.start_time;
        let mut step = match f.step_size {
            Some(h) => h,
            None if recalc => {
                omclog::warning(
                    STDOUT,
                    true,
                    "Start or stop time was overwritten, but no new integrator step size was \
                     provided.",
                );
                omclog::info(STDOUT, false, "Re-calculating step size for 500 intervals.");
                omclog::info(STDOUT, false, "Use `-stepSize=<value>` to silence this warning.");
                omclog::close_warning(STDOUT);
                span / 500.0
            }
            None => translated,
        };
        let min_step = 4.0 * f64::EPSILON * libm::fmax(libm::fabs(self.start_time), libm::fabs(self.stop_time));
        if step < min_step && span > 0.0 {
            omclog::warning!(
                STDOUT,
                false,
                "The step-size {} is too small. Adjust the step-size to {}.",
                crate::driver::format_g(step, 6),
                crate::driver::format_g(min_step, 6),
            );
            step = min_step;
        }
        if step > span + 1e-7 {
            omclog::warning(STDOUT, true, "Integrator step size greater than length of experiment");
            omclog::info!(
                STDOUT,
                false,
                "start time: {:.6}, stop time: {:.6}, integrator step size: {:.6}",
                self.start_time,
                self.stop_time,
                step,
            );
            omclog::close_warning(STDOUT);
        }
        // Only when a flag moved it: `n_intervals` is exact where C re-derives it
        // from the step size the init XML carries.
        if (recalc || f.step_size.is_some()) && span > 0.0 && step > 0.0 {
            self.n_intervals = libm::round(span / step) as u32;
        }
        if let Some(t) = f.tolerance {
            self.tolerance = t;
        }
        if let Some(fmt) = &f.output_format {
            self.output_format = fmt.clone();
        }
        if f.noemit {
            self.output_format = String::from("empty");
        }
        // C's `startNonInteractiveSimulation`, after `read_experiment`.
        if let Some(t) = f.linearize {
            self.stop_time = t;
            omclog::info!(STDOUT, false, "Linearization will be performed at point of time: {t:.6}");
        }
    }

    /// [`apply_flags`](Self::apply_flags) on a copy, for a caller whose metadata is
    /// shared between runs.
    pub fn with_flags(&self, f: &crate::simflags::SimFlags) -> SimMeta {
        let mut m = self.clone();
        m.apply_flags(f);
        m
    }
}

// ─────────────────────────────── wire format ─────────────────────────────────
//
// A flat little-endian encoding behind a 4-byte magic + version. Strings are
// length-prefixed (u32 + utf8 bytes); a `Vec` is a u32 count + elements;
// `MetaKind` / `Option` are a u8 tag + payload. Hand-rolled (no serde) to keep
// the crate dependency-free and trivially buildable for every target.

const MAGIC: &[u8; 4] = b"OMSM";
const VERSION: u32 = 21;

fn put_u32(o: &mut Vec<u8>, v: u32) {
    o.extend_from_slice(&v.to_le_bytes());
}
fn put_f64(o: &mut Vec<u8>, v: f64) {
    o.extend_from_slice(&v.to_le_bytes());
}
fn put_str(o: &mut Vec<u8>, s: &str) {
    put_u32(o, s.len() as u32);
    o.extend_from_slice(s.as_bytes());
}
fn put_u32s(o: &mut Vec<u8>, v: &[u32]) {
    put_u32(o, v.len() as u32);
    for &x in v {
        put_u32(o, x);
    }
}
fn put_u32s2(o: &mut Vec<u8>, v: &[Vec<u32>]) {
    put_u32(o, v.len() as u32);
    for row in v {
        put_u32s(o, row);
    }
}
fn put_layout(o: &mut Vec<u8>, l: &Layout) {
    for v in [
        l.n_states, l.n_real_alg, l.lambda_off, l.rparam_off, l.int_off, l.iparam_off, l.bool_off,
        l.bparam_off, l.str_off, l.sparam_off, l.eobj_off, l.pre_real_off, l.pre_int_off, l.pre_bool_off, l.old_real_off,
        l.terminate_off, l.terminal_off, l.initial_off, l.term_info_off, l.n_out_off, l.nls_fail_off, l.n_samples, l.sample_off, l.sample_active_off,
        l.n_zc, l.zc_off, l.zc_pre_off, l.zc_probe_off, l.n_rel, l.relations_off, l.rel_fresh_off, l.stored_rel_off, l.relations_pre_off,
        l.stateset_off, l.nls_jac_off, l.n_math, l.mathevents_off, l.zctol_off, l.start_off,
        l.real_nom_off, l.state_nom_off, l.state_max_off, l.n_sens, l.sens_off,
        l.n_dae_res, l.dae_res_off, l.n_dae_aux, l.dae_aux_off, l.n_dae_alg, l.dae_alg_nom_off,
        l.n_base_clocks, l.clock_off, l.n_sub_clocks, l.subclock_off, l.clock_fire_off,
        l.linz_off, l.n_linz,
        l.n_opt_attr, l.opt_min_off, l.opt_max_off, l.opt_nom_off, l.opt_use_nom_off,
        l.n_attr_log, l.attr_log_off,
        l.n_removed_init, l.removed_init_res_off, l.removed_init_idx_off,
        l.inline_dt_off, l.alg_old_off,
        l.total,
    ] {
        put_u32(o, v);
    }
    o.push(l.sym_solver);
    o.push(l.has_when as u8);
    o.push(l.has_homotopy as u8);
    o.push(l.homotopy_method.code());
    o.push(l.has_init_lambda0 as u8);
    o.push(l.has_history_ops as u8);
    o.push(l.has_old_real as u8);
}
fn put_jac(o: &mut Vec<u8>, j: &Option<JacAInfo>) {
    match j {
        None => o.push(0),
        Some(j) => {
            o.push(1);
            put_u32(o, j.n);
            put_u32s2(o, &j.colors);
            put_u32s2(o, &j.rows_by_col);
            match &j.sym {
                None => o.push(0),
                Some(s) => {
                    o.push(1);
                    put_u32s(o, &s.seed_offs);
                    put_u32s(o, &s.result_offs);
                    o.push(s.has_constant as u8);
                    match &s.adj {
                        None => o.push(0),
                        Some(a) => {
                            o.push(1);
                            put_u32s(o, &a.seed_offs);
                            put_u32s(o, &a.result_offs);
                            put_u32s(o, &a.zero_offs);
                            o.push(a.has_constant as u8);
                            put_u32s2(o, &a.row_colors);
                        }
                    }
                }
            }
        }
    }
}
fn put_kind(o: &mut Vec<u8>, k: &MetaKind) {
    match k {
        MetaKind::Time => o.push(0),
        MetaKind::Column { col, negate } => {
            o.push(1);
            put_u32(o, *col);
            o.push(negate.code());
        }
        MetaKind::Param { off, wty, negate } => {
            o.push(2);
            put_u32(o, *off);
            o.push(matches!(wty, WTy::F64) as u8);
            o.push(negate.code());
        }
        MetaKind::Const { value } => {
            o.push(3);
            put_f64(o, *value);
        }
    }
}

/// Encode `m` into the byte blob the codegen emits and the driver decodes.
pub fn encode(m: &SimMeta) -> Vec<u8> {
    let mut o = Vec::new();
    o.extend_from_slice(MAGIC);
    put_u32(&mut o, VERSION);
    put_layout(&mut o, &m.layout);
    put_f64(&mut o, m.start_time);
    put_f64(&mut o, m.stop_time);
    put_u32(&mut o, m.n_intervals);
    put_str(&mut o, &m.method);
    put_str(&mut o, &m.cs_method);
    put_str(&mut o, &m.fmi_solver_flags);
    put_f64(&mut o, m.tolerance);
    put_str(&mut o, &m.output_format);
    put_str(&mut o, &m.prefix);
    put_str(&mut o, &m.model_name);
    put_u32(&mut o, m.vars.len() as u32);
    for v in &m.vars {
        put_str(&mut o, &v.name);
        put_str(&mut o, &v.comment);
        put_str(&mut o, &v.unit);
        put_str(&mut o, &v.display_unit);
        o.push(v.relative_quantity as u8);
        o.push(v.ty.code());
        o.push(v.discrete as u8);
        put_kind(&mut o, &v.kind);
        o.push(v.filter);
        o.push(v.unvarying as u8);
        match &v.enumeration {
            None => o.push(0),
            Some(literals) => {
                o.push(1);
                put_u32(&mut o, literals.len() as u32);
                for l in literals {
                    put_str(&mut o, l);
                }
            }
        }
    }
    put_jac(&mut o, &m.jac_a);
    put_u32(&mut o, m.state_sets.len() as u32);
    for s in &m.state_sets {
        put_u32(&mut o, s.n_candidates);
        put_u32(&mut o, s.n_states);
        put_u32(&mut o, s.n_dummy);
        put_u32s(&mut o, &s.candidate_offs);
        put_u32s(&mut o, &s.state_offs);
        put_u32s(&mut o, &s.a_offs);
        put_u32s(&mut o, &s.seed_offs);
        put_u32s(&mut o, &s.result_offs);
        put_u32(&mut o, s.candidate_names.len() as u32);
        for n in &s.candidate_names {
            put_str(&mut o, n);
        }
    }
    put_u32(&mut o, m.fmi_vrs.len() as u32);
    for v in &m.fmi_vrs {
        put_u32(&mut o, v.vr);
        put_u32(&mut o, v.off);
        o.push(matches!(v.wty, WTy::F64) as u8);
        o.push(v.negate.code());
        put_u32(&mut o, v.start_off);
        o.push(v.is_string as u8);
        put_u32(&mut o, v.der_off);
        put_u32(&mut o, v.len);
    }
    put_u32(&mut o, m.fmi_dae_enable_vr);
    put_u32(&mut o, m.zc_desc.len() as u32);
    for d in &m.zc_desc {
        put_str(&mut o, d);
    }
    put_u32(&mut o, m.rel_desc.len() as u32);
    for d in &m.rel_desc {
        put_str(&mut o, d);
    }
    put_u32(&mut o, m.params.reals.len() as u32);
    for (n, v, f) in &m.params.reals {
        put_str(&mut o, n);
        put_f64(&mut o, *v);
        o.push(*f as u8);
    }
    for list in [&m.params.ints, &m.params.bools] {
        put_u32(&mut o, list.len() as u32);
        for (n, v, f) in list {
            put_str(&mut o, n);
            put_u32(&mut o, *v as u32);
            o.push(*f as u8);
        }
    }
    put_u32(&mut o, m.params.strings.len() as u32);
    for (n, v) in &m.params.strings {
        put_str(&mut o, n);
        put_str(&mut o, v);
    }
    put_u32(&mut o, m.attr_log.len() as u32);
    for a in &m.attr_log {
        o.push(a.kind);
        put_str(&mut o, &a.name);
    }
    put_u32(&mut o, m.removed_init_desc.len() as u32);
    for d in &m.removed_init_desc {
        put_str(&mut o, d);
    }
    put_u32(&mut o, m.nls_warnings.len() as u32);
    for d in &m.nls_warnings {
        put_str(&mut o, d);
    }
    put_u32(&mut o, m.sample_index.len() as u32);
    for i in &m.sample_index {
        put_u32(&mut o, *i as u32);
    }
    put_u32(&mut o, m.soti.reals.len() as u32);
    for n in &m.soti.reals {
        put_str(&mut o, n);
    }
    for list in [&m.soti.ints, &m.soti.bools] {
        put_u32(&mut o, list.len() as u32);
        for (n, v) in list {
            put_str(&mut o, n);
            put_u32(&mut o, *v as u32);
        }
    }
    put_u32(&mut o, m.soti.strings.len() as u32);
    for (n, v) in &m.soti.strings {
        put_str(&mut o, n);
        put_str(&mut o, v);
    }
    put_u32(&mut o, m.soti.n_discrete_real);
    put_u32s(&mut o, &m.sens_params);
    put_u32(&mut o, m.nls_vars.len() as u32);
    for v in &m.nls_vars {
        put_u32(&mut o, v.eq_index);
        put_u32(&mut o, v.names.len() as u32);
        for n in &v.names {
            put_str(&mut o, n);
        }
        put_u32s(&mut o, &v.eqns.iter().map(|e| *e as u32).collect::<Vec<_>>());
        for c in v.pattern {
            put_u32(&mut o, c);
        }
        o.push(v.init_diag as u8);
    }
    put_u32(&mut o, m.n_lin_systems);
    match &m.dae {
        None => o.push(0),
        Some(d) => {
            o.push(1);
            put_u32s(&mut o, &d.alg_offs);
            put_jac(&mut o, &d.sparsity);
        }
    }
    put_u32(&mut o, m.clocks.len() as u32);
    for c in &m.clocks {
        o.push(c.is_event_clock as u8);
        o.push(c.inferred as u8);
        put_u32(&mut o, c.sub_base);
        put_u32(&mut o, c.sub.len() as u32);
        for s in &c.sub {
            for v in [s.shift_num, s.shift_den, s.factor_num, s.factor_den] {
                o.extend_from_slice(&v.to_le_bytes());
            }
            o.push(s.hold_events as u8);
            o.push(s.external_solver as u8);
        }
    }
    match &m.lin {
        None => o.push(0),
        Some(l) => {
            o.push(1);
            for g in [&l.input_vars, &l.output_vars] {
                put_u32(&mut o, g.len() as u32);
                for v in g {
                    put_u32(&mut o, v.off);
                    o.push(v.negate.code());
                }
            }
            o.push(l.language as u8);
            put_str(&mut o, &l.frame);
            put_str(&mut o, &l.frame_datarec);
            put_str(&mut o, &l.disabled_reason);
            o.push(l.sym_mask);
            o.push(l.run_testsuite as u8);
            for v in l.jac_rows.iter().chain(l.jac_cols.iter()) {
                put_u32(&mut o, *v);
            }
        }
    }
    match &m.opt {
        None => o.push(0),
        Some(t) => {
            o.push(1);
            put_u32(&mut o, t.n_con);
            put_u32(&mut o, t.n_final_con);
            put_u32s(&mut o, &t.inputs);
            put_u32(&mut o, t.loop_inputs.len() as u32);
            for &(i, src) in &t.loop_inputs {
                put_u32(&mut o, i);
                put_u32(&mut o, src);
            }
            for term in [&t.mayer, &t.lagrange] {
                match term {
                    None => o.push(0),
                    Some(x) => {
                        o.push(1);
                        put_u32(&mut o, x.index);
                        for row in [x.row_b, x.row_c] {
                            put_u32(&mut o, row.map_or(u32::MAX, |r| r));
                        }
                    }
                }
            }
            put_u32(&mut o, t.real_names.len() as u32);
            for n in &t.real_names {
                put_str(&mut o, n);
            }
            put_u32s(&mut o, &t.tgrid);
            put_u32(&mut o, t.start_time_opt.unwrap_or(u32::MAX));
            for j in [&t.jac_b, &t.jac_c, &t.jac_d] {
                match j {
                    None => o.push(0),
                    Some(j) => {
                        o.push(1);
                        put_u32(&mut o, j.n_cols);
                        put_u32(&mut o, j.n_rows);
                        put_u32s2(&mut o, &j.colors);
                        put_u32s2(&mut o, &j.rows_by_col);
                        put_u32s(&mut o, &j.seed_offs);
                        put_u32s(&mut o, &j.result_offs);
                        put_str(&mut o, &j.column_fn);
                        put_str(&mut o, &j.const_fn);
                    }
                }
            }
        }
    }
    put_u32(&mut o, m.inputs.len() as u32);
    for v in &m.inputs {
        put_u32(&mut o, v.off);
        put_u32(&mut o, v.start_off);
        o.push(matches!(v.wty, WTy::F64) as u8);
        put_str(&mut o, &v.name);
    }
    match &m.recon {
        None => o.push(0),
        Some(rc) => {
            o.push(1);
            for list in [&rc.input_vars, &rc.setc_vars, &rc.setb_vars] {
                put_u32(&mut o, list.len() as u32);
                for v in list {
                    put_u32(&mut o, v.off);
                    o.push(v.negate.code());
                    put_str(&mut o, &v.name);
                    put_str(&mut o, &v.unit);
                    put_str(&mut o, &v.comment);
                }
            }
            for jac in [&rc.jac_f, &rc.jac_h] {
                match jac {
                    None => o.push(0),
                    Some(j) => {
                        o.push(1);
                        put_u32(&mut o, j.rows);
                        put_u32(&mut o, j.cols);
                        put_u32(&mut o, j.off);
                    }
                }
            }
            put_u32(&mut o, rc.n_related_boundary);
            put_str(&mut o, &rc.model_file);
            put_str(&mut o, &rc.model_dir);
            put_str(&mut o, &rc.version);
        }
    }
    fn put_info(o: &mut Vec<u8>, i: &SrcInfo) {
        put_str(o, &i.file);
        for v in [i.line_start, i.col_start, i.line_end, i.col_end] {
            put_u32(o, v as u32);
        }
        o.push(i.read_only as u8);
    }
    match &m.prof {
        None => o.push(0),
        Some(p) => {
            o.push(p.level);
            put_u32(&mut o, p.functions.len() as u32);
            for f in &p.functions {
                put_str(&mut o, &f.name);
                put_info(&mut o, &f.info);
            }
            put_u32(&mut o, p.vars.len() as u32);
            for v in &p.vars {
                put_u32(&mut o, v.id);
                put_str(&mut o, &v.name);
                put_str(&mut o, &v.comment);
                put_info(&mut o, &v.info);
            }
            put_u32(&mut o, p.equations.len() as u32);
            for e in &p.equations {
                put_u32(&mut o, e.id);
                put_u32(&mut o, e.defines.len() as u32);
                for d in &e.defines {
                    put_str(&mut o, d);
                }
            }
            put_u32s(&mut o, &p.blocks);
        }
    }
    match &m.parmod {
        None => o.push(0),
        Some(p) => {
            o.push(1);
            put_u32(&mut o, p.tasks.len() as u32);
            for t in &p.tasks {
                put_u32(&mut o, t.eq_index as u32);
                put_u32s(&mut o, &t.parents);
            }
        }
    }
    put_u32(&mut o, m.units.len() as u32);
    for u in &m.units {
        put_str(&mut o, &u.name);
        match &u.base {
            None => o.push(0),
            Some(b) => {
                o.push(1);
                for e in b.exponents {
                    put_u32(&mut o, e as u32);
                }
                put_f64(&mut o, b.factor);
                put_f64(&mut o, b.offset);
            }
        }
        put_u32(&mut o, u.display_units.len() as u32);
        for d in &u.display_units {
            put_str(&mut o, &d.name);
            put_f64(&mut o, d.factor);
            put_f64(&mut o, d.offset);
            o.push(d.inverse as u8);
        }
    }
    o
}

/// A cursor over the input with bounds-checked little-endian reads.
struct Reader<'a> {
    b: &'a [u8],
    p: usize,
}
impl<'a> Reader<'a> {
    fn take(&mut self, n: usize) -> Result<&'a [u8], &'static str> {
        let s = self.b.get(self.p..self.p + n).ok_or("sim_meta: truncated")?;
        self.p += n;
        Ok(s)
    }
    fn u32(&mut self) -> Result<u32, &'static str> {
        Ok(u32::from_le_bytes(self.take(4)?.try_into().unwrap()))
    }
    fn f64(&mut self) -> Result<f64, &'static str> {
        Ok(f64::from_le_bytes(self.take(8)?.try_into().unwrap()))
    }
    fn i64(&mut self) -> Result<i64, &'static str> {
        Ok(i64::from_le_bytes(self.take(8)?.try_into().unwrap()))
    }
    fn u8(&mut self) -> Result<u8, &'static str> {
        Ok(self.take(1)?[0])
    }
    fn string(&mut self) -> Result<String, &'static str> {
        let n = self.u32()? as usize;
        let s = self.take(n)?;
        Ok(String::from_utf8_lossy(s).into_owned())
    }
    fn u32s(&mut self) -> Result<Vec<u32>, &'static str> {
        let n = self.u32()? as usize;
        let mut v = Vec::with_capacity(n);
        for _ in 0..n {
            v.push(self.u32()?);
        }
        Ok(v)
    }
    fn u32s2(&mut self) -> Result<Vec<Vec<u32>>, &'static str> {
        let n = self.u32()? as usize;
        let mut v = Vec::with_capacity(n);
        for _ in 0..n {
            v.push(self.u32s()?);
        }
        Ok(v)
    }
    fn jac(&mut self) -> Result<Option<JacAInfo>, &'static str> {
        Ok(match self.u8()? {
            0 => None,
            _ => Some(JacAInfo {
                n: self.u32()?,
                colors: self.u32s2()?,
                rows_by_col: self.u32s2()?,
                sym: match self.u8()? {
                    0 => None,
                    _ => Some(JacSym {
                        seed_offs: self.u32s()?,
                        result_offs: self.u32s()?,
                        has_constant: self.u8()? != 0,
                        adj: match self.u8()? {
                            0 => None,
                            _ => Some(JacAdj {
                                seed_offs: self.u32s()?,
                                result_offs: self.u32s()?,
                                zero_offs: self.u32s()?,
                                has_constant: self.u8()? != 0,
                                row_colors: self.u32s2()?,
                            }),
                        },
                    }),
                },
            }),
        })
    }
    fn layout(&mut self) -> Result<Layout, &'static str> {
        let mut l = Layout {
            n_states: self.u32()?,
            n_real_alg: self.u32()?,
            lambda_off: self.u32()?,
            rparam_off: self.u32()?,
            int_off: self.u32()?,
            iparam_off: self.u32()?,
            bool_off: self.u32()?,
            bparam_off: self.u32()?,
            str_off: self.u32()?,
            sparam_off: self.u32()?,
            eobj_off: self.u32()?,
            pre_real_off: self.u32()?,
            pre_int_off: self.u32()?,
            pre_bool_off: self.u32()?,
            old_real_off: self.u32()?,
            terminate_off: self.u32()?,
            terminal_off: self.u32()?,
            initial_off: self.u32()?,
            term_info_off: self.u32()?,
            n_out_off: self.u32()?,
            nls_fail_off: self.u32()?,
            n_samples: self.u32()?,
            sample_off: self.u32()?,
            sample_active_off: self.u32()?,
            n_zc: self.u32()?,
            zc_off: self.u32()?,
            zc_pre_off: self.u32()?,
            zc_probe_off: self.u32()?,
            n_rel: self.u32()?,
            relations_off: self.u32()?,
            rel_fresh_off: self.u32()?,
            stored_rel_off: self.u32()?,
            relations_pre_off: self.u32()?,
            stateset_off: self.u32()?,
            nls_jac_off: self.u32()?,
            n_math: self.u32()?,
            mathevents_off: self.u32()?,
            zctol_off: self.u32()?,
            start_off: self.u32()?,
            real_nom_off: self.u32()?,
            state_nom_off: self.u32()?,
            state_max_off: self.u32()?,
            n_sens: self.u32()?,
            sens_off: self.u32()?,
            n_dae_res: self.u32()?,
            dae_res_off: self.u32()?,
            n_dae_aux: self.u32()?,
            dae_aux_off: self.u32()?,
            n_dae_alg: self.u32()?,
            dae_alg_nom_off: self.u32()?,
            n_base_clocks: self.u32()?,
            clock_off: self.u32()?,
            n_sub_clocks: self.u32()?,
            subclock_off: self.u32()?,
            clock_fire_off: self.u32()?,
            linz_off: self.u32()?,
            n_linz: self.u32()?,
            n_opt_attr: self.u32()?,
            opt_min_off: self.u32()?,
            opt_max_off: self.u32()?,
            opt_nom_off: self.u32()?,
            opt_use_nom_off: self.u32()?,
            n_attr_log: self.u32()?,
            attr_log_off: self.u32()?,
            n_removed_init: self.u32()?,
            removed_init_res_off: self.u32()?,
            removed_init_idx_off: self.u32()?,
            inline_dt_off: self.u32()?,
            alg_old_off: self.u32()?,
            total: self.u32()?,
            sym_solver: 0,
            has_when: false,
            has_homotopy: false,
            homotopy_method: HomotopyMethod::default(),
            has_init_lambda0: false,
            has_history_ops: false,
            has_old_real: false,
        };
        l.sym_solver = self.u8()?;
        l.has_when = self.u8()? != 0;
        l.has_homotopy = self.u8()? != 0;
        l.homotopy_method = HomotopyMethod::from_code(self.u8()?);
        l.has_init_lambda0 = self.u8()? != 0;
        l.has_history_ops = self.u8()? != 0;
        l.has_old_real = self.u8()? != 0;
        Ok(l)
    }
    fn enumeration(&mut self) -> Result<Option<Vec<String>>, &'static str> {
        if self.u8()? == 0 {
            return Ok(None);
        }
        (0..self.u32()?).map(|_| self.string()).collect::<Result<Vec<_>, _>>().map(Some)
    }
    fn kind(&mut self) -> Result<MetaKind, &'static str> {
        Ok(match self.u8()? {
            0 => MetaKind::Time,
            1 => MetaKind::Column { col: self.u32()?, negate: Neg::from_code(self.u8()?) },
            2 => MetaKind::Param {
                off: self.u32()?,
                wty: if self.u8()? != 0 { WTy::F64 } else { WTy::I32 },
                negate: Neg::from_code(self.u8()?),
            },
            3 => MetaKind::Const { value: self.f64()? },
            _ => return Err("sim_meta: bad MetaKind tag"),
        })
    }
}

/// Decode a blob produced by [`encode`]. Errors on a bad magic/version or a
/// truncated/corrupt stream.
pub fn decode(bytes: &[u8]) -> Result<SimMeta, &'static str> {
    let mut r = Reader { b: bytes, p: 0 };
    if r.take(4)? != MAGIC {
        return Err("sim_meta: bad magic");
    }
    if r.u32()? != VERSION {
        return Err("sim_meta: unsupported version");
    }
    let layout = r.layout()?;
    let start_time = r.f64()?;
    let stop_time = r.f64()?;
    let n_intervals = r.u32()?;
    let method = r.string()?;
    let cs_method = r.string()?;
    let fmi_solver_flags = r.string()?;
    let tolerance = r.f64()?;
    let output_format = r.string()?;
    let prefix = r.string()?;
    let model_name = r.string()?;
    let nvars = r.u32()? as usize;
    let mut vars = Vec::with_capacity(nvars);
    for _ in 0..nvars {
        vars.push(MetaVar {
            name: r.string()?,
            comment: r.string()?,
            unit: r.string()?,
            display_unit: r.string()?,
            relative_quantity: r.u8()? != 0,
            ty: VarTy::from_code(r.u8()?),
            discrete: r.u8()? != 0,
            kind: r.kind()?,
            filter: r.u8()?,
            unvarying: r.u8()? != 0,
            enumeration: r.enumeration()?,
        });
    }
    let jac_a = r.jac()?;
    let nsets = r.u32()? as usize;
    let mut state_sets = Vec::with_capacity(nsets);
    for _ in 0..nsets {
        let mut s = StateSetInfo {
            n_candidates: r.u32()?,
            n_states: r.u32()?,
            n_dummy: r.u32()?,
            candidate_offs: r.u32s()?,
            state_offs: r.u32s()?,
            a_offs: r.u32s()?,
            seed_offs: r.u32s()?,
            result_offs: r.u32s()?,
            candidate_names: Vec::new(),
        };
        let nn = r.u32()? as usize;
        s.candidate_names = (0..nn).map(|_| r.string()).collect::<core::result::Result<_, _>>()?;
        state_sets.push(s);
    }
    let nvr = r.u32()? as usize;
    let mut fmi_vrs = Vec::with_capacity(nvr);
    for _ in 0..nvr {
        let vr = r.u32()?;
        let off = r.u32()?;
        let wty = if r.u8()? != 0 { WTy::F64 } else { WTy::I32 };
        let negate = Neg::from_code(r.u8()?);
        let start_off = r.u32()?;
        let is_string = r.u8()? != 0;
        let der_off = r.u32()?;
        let len = r.u32()?;
        fmi_vrs.push(FmiVr { vr, off, wty, negate, start_off, is_string, der_off, len });
    }
    let fmi_dae_enable_vr = r.u32()?;
    let ndesc = r.u32()? as usize;
    let mut zc_desc = Vec::with_capacity(ndesc);
    for _ in 0..ndesc {
        zc_desc.push(r.string()?);
    }
    let nrdesc = r.u32()? as usize;
    let mut rel_desc = Vec::with_capacity(nrdesc);
    for _ in 0..nrdesc {
        rel_desc.push(r.string()?);
    }
    let mut params = ParamVars::default();
    for _ in 0..r.u32()? {
        params.reals.push((r.string()?, r.f64()?, r.u8()? != 0));
    }
    for list in [&mut params.ints, &mut params.bools] {
        for _ in 0..r.u32()? {
            list.push((r.string()?, r.u32()? as i32, r.u8()? != 0));
        }
    }
    for _ in 0..r.u32()? {
        params.strings.push((r.string()?, r.string()?));
    }
    let mut attr_log = Vec::new();
    for _ in 0..r.u32()? {
        attr_log.push(AttrLog { kind: r.u8()?, name: r.string()? });
    }
    let nridesc = r.u32()? as usize;
    let mut removed_init_desc = Vec::with_capacity(nridesc);
    for _ in 0..nridesc {
        removed_init_desc.push(r.string()?);
    }
    let nwarn = r.u32()? as usize;
    let mut nls_warnings = Vec::with_capacity(nwarn);
    for _ in 0..nwarn {
        nls_warnings.push(r.string()?);
    }
    let sample_index = r.u32s()?.into_iter().map(|v| v as i32).collect();
    let mut soti = SotiVars::default();
    for _ in 0..r.u32()? {
        soti.reals.push(r.string()?);
    }
    for _ in 0..r.u32()? {
        soti.ints.push((r.string()?, r.u32()? as i32));
    }
    for _ in 0..r.u32()? {
        soti.bools.push((r.string()?, r.u32()? as i32));
    }
    for _ in 0..r.u32()? {
        soti.strings.push((r.string()?, r.string()?));
    }
    soti.n_discrete_real = r.u32()?;
    let sens_params = r.u32s()?;
    let nsys = r.u32()? as usize;
    let mut nls_vars = Vec::with_capacity(nsys);
    for _ in 0..nsys {
        let eq_index = r.u32()?;
        let nn = r.u32()? as usize;
        let mut names = Vec::with_capacity(nn);
        for _ in 0..nn {
            names.push(r.string()?);
        }
        let eqns = r.u32s()?.into_iter().map(|v| v as i32).collect();
        let pattern = [r.u32()?, r.u32()?, r.u32()?];
        let init_diag = r.u8()? != 0;
        nls_vars.push(NlsVars { eq_index, names, eqns, pattern, init_diag });
    }
    let n_lin_systems = r.u32()?;
    let dae = match r.u8()? {
        0 => None,
        _ => Some(DaeInfo { alg_offs: r.u32s()?, sparsity: r.jac()? }),
    };
    let nclocks = r.u32()? as usize;
    let mut clocks = Vec::with_capacity(nclocks);
    for _ in 0..nclocks {
        let is_event_clock = r.u8()? != 0;
        let inferred = r.u8()? != 0;
        let sub_base = r.u32()?;
        let nsub = r.u32()? as usize;
        let mut sub = Vec::with_capacity(nsub);
        for _ in 0..nsub {
            sub.push(SubClockMeta {
                shift_num: r.i64()?,
                shift_den: r.i64()?,
                factor_num: r.i64()?,
                factor_den: r.i64()?,
                hold_events: r.u8()? != 0,
                external_solver: r.u8()? != 0,
            });
        }
        clocks.push(BaseClockMeta { is_event_clock, inferred, sub_base, sub });
    }
    let lin = match r.u8()? {
        0 => None,
        _ => {
            let mut group = || -> Result<Vec<LinVar>, &'static str> {
                let n = r.u32()? as usize;
                let mut out = Vec::with_capacity(n);
                for _ in 0..n {
                    out.push(LinVar { off: r.u32()?, negate: Neg::from_code(r.u8()?) });
                }
                Ok(out)
            };
            let input_vars = group()?;
            let output_vars = group()?;
            let language = match r.u8()? {
                0 => LinLanguage::Modelica,
                1 => LinLanguage::Matlab,
                2 => LinLanguage::Julia,
                3 => LinLanguage::Python,
                _ => return Err("sim_meta: bad LinLanguage tag"),
            };
            let frame = r.string()?;
            let frame_datarec = r.string()?;
            let disabled_reason = r.string()?;
            let sym_mask = r.u8()?;
            let run_testsuite = r.u8()? != 0;
            let mut dims = [0u32; 8];
            for d in &mut dims {
                *d = r.u32()?;
            }
            let (rows, cols) = dims.split_at(4);
            Some(LinInfo {
                input_vars,
                output_vars,
                language,
                frame,
                frame_datarec,
                disabled_reason,
                sym_mask,
                run_testsuite,
                jac_rows: rows.try_into().unwrap(),
                jac_cols: cols.try_into().unwrap(),
            })
        }
    };
    let opt = match r.u8()? {
        0 => None,
        _ => {
            let n_con = r.u32()?;
            let n_final_con = r.u32()?;
            let inputs = r.u32s()?;
            let nloop = r.u32()? as usize;
            let mut loop_inputs = Vec::with_capacity(nloop);
            for _ in 0..nloop {
                loop_inputs.push((r.u32()?, r.u32()?));
            }
            let mut term = || -> Result<Option<OptTerm>, &'static str> {
                Ok(match r.u8()? {
                    0 => None,
                    _ => {
                        let index = r.u32()?;
                        let mut row = || r.u32().map(|v| (v != u32::MAX).then_some(v));
                        Some(OptTerm { index, row_b: row()?, row_c: row()? })
                    }
                })
            };
            let mayer = term()?;
            let lagrange = term()?;
            let n_names = r.u32()? as usize;
            let mut real_names = Vec::with_capacity(n_names);
            for _ in 0..n_names {
                real_names.push(r.string()?);
            }
            let tgrid = r.u32s()?;
            let start_time_opt = { let v = r.u32()?; (v != u32::MAX).then_some(v) };
            let mut jac = || -> Result<Option<OptJac>, &'static str> {
                Ok(match r.u8()? {
                    0 => None,
                    _ => Some(OptJac {
                        n_cols: r.u32()?,
                        n_rows: r.u32()?,
                        colors: r.u32s2()?,
                        rows_by_col: r.u32s2()?,
                        seed_offs: r.u32s()?,
                        result_offs: r.u32s()?,
                        column_fn: r.string()?,
                        const_fn: r.string()?,
                    }),
                })
            };
            let jac_b = jac()?;
            let jac_c = jac()?;
            let jac_d = jac()?;
            Some(OptInfo {
                n_con, n_final_con, inputs, loop_inputs, mayer, lagrange, real_names, tgrid,
                start_time_opt, jac_b, jac_c, jac_d,
            })
        }
    };
    let mut inputs = Vec::new();
    for _ in 0..r.u32()? {
        let off = r.u32()?;
        let start_off = r.u32()?;
        let wty = if r.u8()? != 0 { WTy::F64 } else { WTy::I32 };
        inputs.push(InputVar { off, start_off, wty, name: r.string()? });
    }
    let recon = match r.u8()? {
        0 => None,
        _ => {
            let mut lists = [Vec::new(), Vec::new(), Vec::new()];
            for list in &mut lists {
                for _ in 0..r.u32()? {
                    let off = r.u32()?;
                    let negate = Neg::from_code(r.u8()?);
                    list.push(ReconVar {
                        off,
                        negate,
                        name: r.string()?,
                        unit: r.string()?,
                        comment: r.string()?,
                    });
                }
            }
            let mut jac = |r: &mut Reader| -> core::result::Result<Option<ReconJac>, &'static str> {
                Ok(match r.u8()? {
                    0 => None,
                    _ => Some(ReconJac { rows: r.u32()?, cols: r.u32()?, off: r.u32()? }),
                })
            };
            let (jac_f, jac_h) = (jac(&mut r)?, jac(&mut r)?);
            let [input_vars, setc_vars, setb_vars] = lists;
            Some(ReconInfo {
                input_vars,
                setc_vars,
                setb_vars,
                jac_f,
                jac_h,
                n_related_boundary: r.u32()?,
                model_file: r.string()?,
                model_dir: r.string()?,
                version: r.string()?,
            })
        }
    };
    let mut info = |r: &mut Reader| -> core::result::Result<SrcInfo, &'static str> {
        Ok(SrcInfo {
            file: r.string()?,
            line_start: r.u32()? as i32,
            col_start: r.u32()? as i32,
            line_end: r.u32()? as i32,
            col_end: r.u32()? as i32,
            read_only: r.u8()? != 0,
        })
    };
    let prof = match r.u8()? {
        0 => None,
        level => {
            let mut functions = Vec::new();
            for _ in 0..r.u32()? {
                functions.push(ProfFn { name: r.string()?, info: info(&mut r)? });
            }
            let mut vars = Vec::new();
            for _ in 0..r.u32()? {
                vars.push(ProfVar { id: r.u32()?, name: r.string()?, comment: r.string()?, info: info(&mut r)? });
            }
            let mut equations = Vec::new();
            for _ in 0..r.u32()? {
                let id = r.u32()?;
                let mut defines = Vec::new();
                for _ in 0..r.u32()? {
                    defines.push(r.string()?);
                }
                equations.push(ProfEq { id, defines });
            }
            Some(ProfInfo { level, functions, vars, equations, blocks: r.u32s()? })
        }
    };
    let parmod = match r.u8()? {
        0 => None,
        _ => {
            let mut tasks = Vec::new();
            for _ in 0..r.u32()? {
                tasks.push(ParmodTask { eq_index: r.u32()? as i32, parents: r.u32s()? });
            }
            Some(ParmodInfo { tasks })
        }
    };
    let mut units = Vec::new();
    for _ in 0..r.u32()? {
        let name = r.string()?;
        let base = match r.u8()? {
            0 => None,
            _ => {
                let mut exponents = [0i32; 8];
                for e in &mut exponents {
                    *e = r.u32()? as i32;
                }
                Some(BaseUnit { exponents, factor: r.f64()?, offset: r.f64()? })
            }
        };
        let mut display_units = Vec::new();
        for _ in 0..r.u32()? {
            display_units.push(DisplayUnit { name: r.string()?, factor: r.f64()?, offset: r.f64()?, inverse: r.u8()? != 0 });
        }
        units.push(UnitDef { name, base, display_units });
    }
    Ok(SimMeta {
        layout, start_time, stop_time, n_intervals, method, cs_method, fmi_solver_flags, tolerance,
        output_format, prefix,
        model_name, vars, units, jac_a, state_sets, fmi_vrs, fmi_dae_enable_vr, zc_desc, rel_desc, params, attr_log,
        removed_init_desc, nls_warnings, sample_index, soti, sens_params, nls_vars, n_lin_systems, dae, clocks, lin, opt, inputs, recon, prof,
        parmod,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use alloc::string::ToString;
    use alloc::vec;

    fn sample() -> SimMeta {
        SimMeta {
            // Every flag non-default, so the round-trip covers the flag block.
            layout: Layout::new(
                2, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 4, 1, 2, 1, 2, 6, 5, 2, 1, 2, true, true,
                HomotopyMethod::LocalAdaptive, true, true, true,
            ),
            start_time: 0.0,
            stop_time: 1.0,
            n_intervals: 500,
            method: "dassl".to_string(),
            cs_method: "euler".to_string(),
            fmi_solver_flags: "-nls=kinsol -lss=klu".to_string(),
            tolerance: 1e-6,
            output_format: "mat".to_string(),
            prefix: "MyModel".to_string(),
            model_name: "MyModel".to_string(),
            units: vec![UnitDef {
                name: "K".to_string(),
                base: Some(BaseUnit { exponents: [0, 0, 0, 0, 1, 0, 0, 0], factor: 1.0, offset: 0.0 }),
                display_units: vec![DisplayUnit { name: "degC".to_string(), factor: 1.0, offset: -273.15, inverse: false }],
            }],
            vars: vec![
                MetaVar { name: "time".to_string(), comment: "Time in s".to_string(), kind: MetaKind::Time, unit: String::new(), display_unit: String::new(), relative_quantity: false, ty: VarTy::Real, discrete: false, filter: 0, unvarying: false, enumeration: None },
                MetaVar { name: "x".to_string(), comment: "".to_string(), kind: MetaKind::Column { col: 1, negate: Neg::None }, unit: String::new(), display_unit: String::new(), relative_quantity: false, ty: VarTy::Real, discrete: false, filter: var_filter::PROTECTED, unvarying: false, enumeration: None },
                MetaVar { name: "y".to_string(), comment: "neg alias".to_string(), kind: MetaKind::Column { col: 1, negate: Neg::Not }, unit: String::new(), display_unit: String::new(), relative_quantity: false, ty: VarTy::Real, discrete: false, filter: var_filter::ALIAS, unvarying: false, enumeration: None },
                MetaVar { name: "p".to_string(), comment: "a param".to_string(), kind: MetaKind::Param { off: 88, wty: WTy::F64, negate: Neg::Arith }, unit: String::new(), display_unit: String::new(), relative_quantity: false, ty: VarTy::Real, discrete: false, filter: 0, unvarying: false, enumeration: None },
                MetaVar { name: "n".to_string(), comment: "".to_string(), kind: MetaKind::Param { off: 92, wty: WTy::I32, negate: Neg::None }, unit: String::new(), display_unit: String::new(), relative_quantity: false, ty: VarTy::Real, discrete: false, filter: var_filter::HIDE_RESULT, unvarying: false, enumeration: None },
                MetaVar { name: "k".to_string(), comment: "".to_string(), kind: MetaKind::Const { value: 9.5 }, unit: String::new(), display_unit: String::new(), relative_quantity: false, ty: VarTy::Real, discrete: false, filter: var_filter::FILTERED, unvarying: false, enumeration: None },
            ],
            jac_a: Some(JacAInfo {
                n: 2,
                colors: vec![vec![0], vec![1]],
                rows_by_col: vec![vec![0, 1], vec![1]],
                sym: Some(JacSym {
                    seed_offs: vec![300, 308],
                    result_offs: vec![316, u32::MAX],
                    has_constant: true,
                    adj: None,
                }),
            }),
            state_sets: vec![StateSetInfo {
                n_candidates: 3,
                n_states: 2,
                n_dummy: 1,
                candidate_offs: vec![8, 16, 24],
                state_offs: vec![8, 16],
                a_offs: vec![100, 104, 108, 112, 116, 120],
                seed_offs: vec![200, 208, 216],
                result_offs: vec![224],
                candidate_names: vec!["a.w".to_string(), "b.w".to_string(), "c.w".to_string()],
            }],
            fmi_vrs: vec![
                FmiVr { vr: 0, off: 8, wty: WTy::F64, negate: Neg::None, start_off: 96, is_string: false, der_off: 0, len: 1 },
                FmiVr { vr: 7, off: 64, wty: WTy::I32, negate: Neg::Arith, start_off: 0, is_string: true, der_off: 0, len: 1 },
            ],
            fmi_dae_enable_vr: 9,
            zc_desc: vec!["x > 0.0".to_string(), "y < 1.0".to_string()],
            rel_desc: vec!["x > 0.0".to_string(), "y < 1.0".to_string()],
            params: ParamVars {
                reals: vec![("a".to_string(), 1.5, true)],
                ints: vec![("i".to_string(), 3, false)],
                bools: vec![("b".to_string(), 1, true)],
                strings: vec![("s".to_string(), "two".to_string())],
            },
            attr_log: vec![
                AttrLog { kind: 0, name: "x".to_string() },
                AttrLog { kind: 3, name: "y".to_string() },
            ],
            removed_init_desc: vec!["4.0 - z".to_string()],
            nls_warnings: Vec::new(),
            sample_index: vec![1],
            soti: SotiVars::default(),
            sens_params: vec![88],
            nls_vars: vec![NlsVars {
                eq_index: 1074,
                names: vec!["pipe.medium.T".to_string(), "pipe.medium.p".to_string()],
                eqns: vec![1072, 1073],
                pattern: [2, 2, 3],
                init_diag: true,
            }],
            n_lin_systems: 2,
            dae: Some(DaeInfo {
                alg_offs: vec![32, 40],
                sparsity: Some(JacAInfo {
                    n: 4,
                    colors: vec![vec![0, 2], vec![1, 3]],
                    rows_by_col: vec![vec![0], vec![0, 1], vec![2], vec![2, 3]],
                    sym: None,
                }),
            }),
            clocks: vec![BaseClockMeta {
                is_event_clock: false,
                inferred: false,
                sub_base: 0,
                sub: vec![
                    SubClockMeta { shift_num: 0, shift_den: 1, factor_num: 1, factor_den: 1, hold_events: false, external_solver: false },
                    SubClockMeta { shift_num: 1, shift_den: 3, factor_num: 4, factor_den: 1, hold_events: true, external_solver: false },
                ],
            }],
            lin: Some(LinInfo {
                input_vars: vec![LinVar { off: 40, negate: Neg::None }],
                output_vars: vec![LinVar { off: 48, negate: Neg::Arith }],
                language: LinLanguage::Julia,
                frame: "function linearized_model()\n%s%s%s%s%s%s\nend".to_string(),
                frame_datarec: String::new(),
                disabled_reason: String::new(),
                sym_mask: 0b1011,
                run_testsuite: false,
                jac_rows: [2, 2, 1, 1],
                jac_cols: [2, 1, 2, 1],
            }),
            opt: Some(OptInfo {
                n_con: 1,
                n_final_con: 1,
                inputs: vec![4],
                loop_inputs: vec![(0, 3)],
                mayer: Some(OptTerm { index: 5, row_b: None, row_c: Some(2) }),
                lagrange: Some(OptTerm { index: 6, row_b: Some(2), row_c: Some(3) }),
                real_names: vec!["x".to_string(), "der(x)".to_string()],
                tgrid: vec![120, 128],
                start_time_opt: Some(136),
                jac_b: Some(OptJac {
                    n_cols: 3,
                    n_rows: 2,
                    colors: vec![vec![0], vec![1, 2]],
                    rows_by_col: vec![vec![0], vec![0, 1], vec![1]],
                    seed_offs: vec![400, 408, 416],
                    result_offs: vec![424, 432],
                    column_fn: "optJacB".to_string(),
                    const_fn: String::new(),
                }),
                jac_c: None,
                jac_d: None,
            }),
            inputs: vec![InputVar { off: 96, start_off: 104, wty: WTy::F64, name: "u".to_string() }],
            recon: Some(ReconInfo {
                input_vars: vec![ReconVar {
                    off: 16,
                    negate: Neg::None,
                    name: "x".to_string(),
                    unit: "K".to_string(),
                    comment: "measured".to_string(),
                }],
                setc_vars: vec![ReconVar {
                    off: 24,
                    negate: Neg::Arith,
                    name: "c".to_string(),
                    unit: String::new(),
                    comment: String::new(),
                }],
                setb_vars: vec![ReconVar {
                    off: 32,
                    negate: Neg::Not,
                    name: "b".to_string(),
                    unit: "1".to_string(),
                    comment: "unmeasured".to_string(),
                }],
                jac_f: Some(ReconJac { rows: 1, cols: 2, off: 200 }),
                jac_h: None,
                n_related_boundary: 1,
                model_file: "MyModel.mo".to_string(),
                model_dir: "/tmp".to_string(),
                version: "v1.25.0".to_string(),
            }),
            parmod: Some(ParmodInfo {
                tasks: vec![ParmodTask { eq_index: 3, parents: vec![] }, ParmodTask { eq_index: 5, parents: vec![0] }],
            }),
            prof: Some(ProfInfo {
                level: 5,
                functions: vec![ProfFn { name: "f".to_string(), info: SrcInfo { file: "a.mo".to_string(), line_start: 1, col_start: 2, line_end: 3, col_end: 4, read_only: true } }],
                vars: vec![ProfVar { id: 7, name: "x".to_string(), comment: "c".to_string(), info: SrcInfo::default() }],
                equations: vec![ProfEq { id: 0, defines: vec![] }, ProfEq { id: 1, defines: vec!["x".to_string()] }],
                blocks: vec![1],
            }),
        }
    }

    #[test]
    fn round_trips() {
        let m = sample();
        let blob = encode(&m);
        let back = decode(&blob).expect("decode");
        assert_eq!(m, back);
        // Re-encoding the decoded value is byte-identical (canonical).
        assert_eq!(blob, encode(&back));
    }

    #[test]
    fn layout_widths() {
        let l = sample().layout;
        assert_eq!(l.n_reals_row(), 1 + 2 * 2 + 1); // time + 2 states + 2 ders + 1 alg
        assert_eq!(l.n_int_alg(), 1);
        assert_eq!(l.n_bool_alg(), 1);
        assert_eq!(l.n_sens, 2);
        assert_eq!(l.n_row_total(), 6 + 1 + 1 + 2);
        assert_eq!(l.sens_col0(), 6 + 1 + 1);
    }

    /// The sample's `x` is protected and its alias `y` is not, so `x` rides along.
    #[test]
    fn output_keep_follows_the_flags() {
        let m = sample();
        let names = |keep: Vec<bool>| -> Vec<&str> {
            m.vars.iter().zip(keep).filter(|(_, k)| *k).map(|(v, _)| v.name.as_str()).collect()
        };
        simflags::set_flags(simflags::SimFlags::default());
        assert_eq!(names(m.output_keep(None)), ["time", "x", "y", "p"]);

        let mut f = simflags::SimFlags { ignore_hide_result: true, ..Default::default() };
        simflags::set_flags(f.clone());
        assert_eq!(names(m.output_keep(None)), ["time", "x", "y", "p", "n"]);

        // A `-variableFilter` replaces the model's verdict, so `k` is reachable;
        // `time` is never filtered and the parameter `p` is exempt.
        f.ignore_hide_result = false;
        simflags::set_flags(f);
        let only_k = |n: &str| n == "k";
        assert_eq!(names(m.output_keep(Some(&only_k))), ["time", "p", "k"]);
    }

    /// C's `read_experiment`: the command line replaces what the model was
    /// translated with, and `numSteps` follows the step size.
    #[test]
    fn apply_flags_is_cs_read_experiment() {
        let flags = |args: &[&str]| {
            let argv: Vec<String> =
                core::iter::once("model".into()).chain(args.iter().map(|a| a.to_string())).collect();
            simflags::parse(&argv).expect("parses")
        };
        // Untouched by an empty command line.
        let m = sample().with_flags(&simflags::SimFlags::default());
        assert_eq!((m.start_time, m.stop_time, m.n_intervals), (0.0, 1.0, 500));

        // Moving the interval alone re-cuts it into 500 intervals, as C does.
        let m = sample().with_flags(&flags(&["-startTime=1", "-stopTime=3"]));
        assert_eq!((m.start_time, m.stop_time, m.n_intervals), (1.0, 3.0, 500));

        // `-stepSize` is what `numSteps` is derived from.
        let f = flags(&["-stopTime=2", "-stepSize=0.01", "-tolerance=1e-9", "-outputFormat=empty"]);
        let m = sample().with_flags(&f);
        assert_eq!((m.stop_time, m.n_intervals, m.tolerance), (2.0, 200, 1e-9));
        assert_eq!(m.output_format, "empty");
        // ... and `step_size()` still reports the exact value asked for.
        simflags::set_flags(f);
        assert_eq!(m.step_size(), 0.01);
        simflags::set_flags(simflags::SimFlags::default());

        // `-noemit` is `-outputFormat=empty`.
        assert_eq!(sample().with_flags(&flags(&["-noemit"])).output_format, "empty");
    }

    #[test]
    fn rejects_bad_input() {
        assert!(decode(b"nope").is_err());
        assert!(decode(&[]).is_err());
        let mut blob = encode(&sample());
        blob.truncate(blob.len() - 1); // chop the last byte
        assert!(decode(&blob).is_err());
    }
}
