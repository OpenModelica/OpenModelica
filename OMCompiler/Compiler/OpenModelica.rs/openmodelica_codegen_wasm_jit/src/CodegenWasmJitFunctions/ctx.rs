//! Codegen contexts and descriptors: `FnCtx`, `SimCtx`, `Literals`,
//! `ProfPlan`, `NlsJob`, attribute targets, array/scatter/const groups, slots.

use super::*;

/// The module's constant pool: every literal concatenated into the single
/// passive data segment 0, since `memory.init` reads its segment at a source
/// offset. One segment rather than one per literal, which wasm caps at 100000.
#[derive(Default)]
pub(crate) struct Literals {
    blob: Vec<u8>,
    /// `(hash, len)` -> offsets already placed. Keyed by hash so the pool is not
    /// held twice; `intern` still compares before reusing one.
    seen: HashMap<(u64, usize), Vec<u32>>,
}

impl Literals {
    /// Offset of `bytes` within segment 0, appending them if not already there.
    pub(crate) fn intern(&mut self, bytes: &[u8]) -> u32 {
        use core::hash::{Hash, Hasher};
        let mut h = std::collections::hash_map::DefaultHasher::new();
        bytes.hash(&mut h);
        let key = (h.finish(), bytes.len());
        let offsets = self.seen.entry(key).or_default();
        if let Some(&off) = offsets.iter().find(|&&o| self.blob[o as usize..][..bytes.len()] == *bytes) {
            return off;
        }
        let off = self.blob.len() as u32;
        self.blob.extend_from_slice(bytes);
        offsets.push(off);
        off
    }

    /// Whether nothing was interned. Not "the blob is empty": an empty String
    /// literal adds no bytes but still emits a `memory.init` naming segment 0.
    pub(crate) fn is_empty(&self) -> bool {
        self.seen.is_empty()
    }

    pub(crate) fn blob(&self) -> &[u8] {
        &self.blob
    }
}

/// Per-function compilation state.
pub(crate) struct FnCtx<'a> {
    /// ident -> (local index, Modelica type). Inputs are the wasm params
    /// (indices `0..n_params`); outputs and locals follow.
    pub(super) locals: HashMap<String, (u32, SigTy)>,
    /// Wasm types of every non-parameter local (for `Function::new`), in index
    /// order starting at `n_params`.
    pub(super) extra_locals: Vec<we::ValType>,
    pub(super) n_params: u32,
    /// Output local indices, pushed (in order) before every `return`.
    pub(super) outputs: Vec<(u32, SigTy)>,
    /// Resolves a `CALL` to another generated function.
    pub(super) by_name: &'a HashMap<String, FnInfo>,
    /// Module-wide constant pool; `intern` gives the offset into data segment 0.
    pub(super) literals: &'a mut Literals,
    pub(super) instrs: Vec<we::Instruction<'static>>,
    /// Number of currently-open structured-control frames (`block`/`loop`/`if`),
    /// maintained automatically by [`FnCtx::emit`]. A relative branch index to a
    /// frame opened at level `L` is `ctrl_depth - L` (see [`FnCtx::branch_to`]).
    pub(super) ctrl_depth: u32,
    /// Stack of enclosing loops, innermost last: `(break_level, continue_level)`,
    /// the `ctrl_depth` values of the loop's break-target and continue-target
    /// blocks. Drives `break`/`continue` (`STMT_BREAK`/`STMT_CONTINUE`).
    pub(super) loops: Vec<(u32, u32)>,
    /// Heap locals that hold a *borrowed* reference (not owned), so they must be
    /// skipped by `release_heap_locals` — currently the `for x in array` iterator,
    /// which aliases an element of the array that outlives the loop.
    pub(super) borrowed_locals: Vec<u32>,
    /// Scratch pair shared by every [`emit_elem_ptr`] in the body: its sequence is
    /// straight-line, so one pair is enough.
    pub(super) elem_ptr_tmp: Option<(u32, u32)>,
    /// Where the equation or statement being lowered came from: C reports a model
    /// error at the generated C position, which `-d=gendebugsymbols` rewrites to
    /// this one, and there is no generated C here to name. Rendered only at the
    /// few sites that can raise one ([`emit_src_loc`]).
    pub(super) src_loc: Option<metamodelica::SourceInfo>,
    /// Set when lowering *simulation* equations (the `CodegenWasmJit` target): a
    /// resolver that maps model component references not bound as wasm locals to
    /// slots in the shared `SimData` block. `None` for ordinary function bodies.
    pub(crate) sim: Option<SimCtx>,
    /// Dynamic tearing: set while lowering the *casual* tearing set's residual, where
    /// a violated `localCon` constraint ends the evaluation (C's
    /// `residualFuncConstraints` returning 1 — see `createLocalConstraints`).
    pub(super) dt_local_cons: bool,
    /// Dynamic tearing: while lowering the casual tearing set itself, the
    /// [`ctrl_depth`](Self::ctrl_depth) of the block a failed solve branches out of,
    /// to hand the component to the strict set instead of reporting it unsolved.
    pub(super) dt_fallback: Option<u32>,
}

/// Resolver for model variables when lowering simulation equations. Component
/// references that are not function-local wasm slots (states, state
/// derivatives, algebraics, parameters, `time`) are read/written through the
/// `SimData` block whose base pointer is held in the wasm local `data_local`
/// (the equation function's first parameter); every variable lives at a
/// compile-time-constant byte offset. See `CodegenWasmJit`.
///
/// The maps are shared (`Arc`) with `SimVarMap`, not copied: one `SimCtx` is built
/// per generated function and a large model has hundreds of them.
/// `+profiling`: which clock each profiled function and equation block ticks —
/// C's `<fn>_index` defines and `profileBlockIndex` (see `prof.rs`).
pub(crate) struct ProfPlan {
    /// C's `measure_time_flag`: bit 1 `blocks`, bit 2 `all`, bit 4 html.
    pub(crate) level: u8,
    pub(crate) n_functions: u32,
    pub(crate) n_blocks: u32,
    /// Mangled function name -> clock.
    pub(crate) fn_index: HashMap<String, u32>,
    /// Equation index -> profile block; the block's clock is `n_functions + block`.
    pub(crate) blocks: HashMap<i32, u32>,
}

impl ProfPlan {
    pub(crate) fn all(&self) -> bool {
        self.level & 2 != 0
    }
    pub(crate) fn block_clock(&self, eq_index: i32) -> Option<u32> {
        self.blocks.get(&eq_index).map(|b| self.n_functions + b)
    }
}

pub(crate) struct SimCtx {
    /// wasm local index holding the `SimData` base pointer.
    pub(crate) data_local: u32,
    /// Canonical cref key (`super::sim_cref_key`) -> slot in `SimData`.
    pub(crate) vars: Arc<HashMap<String, SimSlot>>,
    /// Canonical cref key -> its `start` value expression (for `$START.<cref>`),
    /// `None` when the variable has no explicit start (defaults to the type's
    /// zero). Stored separately from `vars` because `$START` reads the start
    /// attribute, not the live value.
    pub(crate) starts: Arc<HashMap<String, Option<Arc<DAE::Exp>>>>,
    /// State cref key -> its start-value slot; `$START.<key>` reads the slot when
    /// present, else the inline expression. Empty while building the fill function.
    pub(crate) start_slots: Arc<HashMap<String, u32>>,
    /// Canonical cref key of an *array-valued* model variable (the base name with
    /// no final subscript, e.g. `body.R_start.T`) -> the contiguous slot range its
    /// scalarized elements occupy. A whole-array reference reads/writes the range
    /// as one runtime array object (gather on read, scatter on assign). See
    /// `compile_sim_cref_read`/`compile_sim_cref_assign`.
    pub(crate) array_groups: Arc<HashMap<String, ArrayGroup>>,
    /// The same keys for the arrays that are not one contiguous range; only a
    /// run-time subscript resolves through these (see `ScatterGroup`).
    pub(crate) scatter_groups: Arc<HashMap<String, ScatterGroup>>,
    /// `varKind = CONST` variables own no slot: a reference is the binding
    /// literal, as in C's `varArrayNameValues`.
    pub(crate) consts: Arc<HashMap<String, Arc<DAE::Exp>>>,
    pub(crate) const_groups: Arc<HashMap<String, ConstGroup>>,
    /// External object cref key -> the mangled name of its class's destructor.
    pub(crate) extobj_dtors: Arc<HashMap<String, String>>,
    /// `SimData` byte offset of the `terminate` flag, written by a fired
    /// `terminate(...)` when-operator (see `lower_when_op`).
    pub(crate) terminate_off: u32,
    /// `SimData` byte offset of the `terminal()` flag, raised by the driver for
    /// the run's final discrete update.
    pub(crate) terminal_off: u32,
    /// `SimData` byte offset of the `initial()` flag, raised by the driver for
    /// the initialization phase.
    pub(crate) initial_off: u32,
    /// `SimData` byte offset of the fired `terminate(...)`'s message + source
    /// position (C's `TermMsg`/`TermInfo`).
    pub(crate) term_info_off: u32,
    /// `SimData` byte offset of the nonlinear-solver failure flag, raised by a
    /// non-converging `SES_NONLINEAR` system (`rt_solve_nls`).
    pub(crate) nls_fail_off: u32,
    /// `SES_NONLINEAR` system index -> its `rt_solve_nls` job (shared-table slot
    /// + unknown count). Empty when the model has no nonlinear systems.
    pub(crate) nls_jobs: Arc<HashMap<i32, NlsJob>>,
    /// `SimGenericCall` index -> the shared for-loop body it runs (C's
    /// `sc.generic_loop_calls`).
    pub(crate) generic_calls: Arc<HashMap<i32, SimCode::SimGenericCall>>,
    /// Number of `sample(...)` time events, bounding the `active` flag region.
    pub(crate) n_samples: u32,
    /// `SimData` byte offset of the per-sample `active` flags.
    pub(crate) sample_active_off: u32,
    /// `SimData` byte offset of the held relation values (`relations[]`).
    pub(crate) relations_off: u32,
    /// `SimData` byte offset of the relation-evaluation-mode flag.
    pub(crate) rel_fresh_off: u32,
    /// `SimData` byte offset of the held relation snapshot — the hysteresis
    /// *direction* source, held fixed across an event's discrete update.
    pub(crate) stored_rel_off: u32,
    /// `SimData` byte offset of `relationsPre` (held-mode relation values).
    pub(crate) relations_pre_off: u32,
    /// Number of indexed relations.
    pub(crate) n_relations: u32,
    /// `SimData` byte offset of the held math-event values (`mathEventsValuePre`).
    pub(crate) mathevents_off: u32,
    /// Number of math-event slots (bounds the `mathEventsValuePre` region).
    pub(crate) n_mathevents: u32,
    /// `SimData` byte offset of the homotopy parameter lambda (`homotopy(a, s)` =
    /// `s + lambda*(a-s)`).
    pub(crate) lambda_off: u32,
    /// C's `homotopyMethod` code, handed to `rt_solve_nls`.
    pub(crate) homotopy_method: u8,
    /// True while lowering the `functionZeroCrossings` body: an indexed relation is
    /// then evaluated *fresh* (so a sign change is detectable) rather than held.
    pub(crate) zc_context: bool,
    /// `SimData` byte offset of the zero-crossing hysteresis tolerance, written by
    /// the driver at run start from the run's tolerance. Continuous (Real) indexed
    /// relations use a ±`tolZC*(max(|a|,|b|)+max(nom))` band at events and in
    /// `functionZeroCrossings` so a relation stays put within the band — this keeps
    /// a bouncing ball from chattering through the floor near rest.
    pub(crate) zctol_off: u32,
    /// C's `data->localData[1]->realVars` as `(one past the live real region, the
    /// mirror's base)`; `None` when no linear system reads it.
    pub(crate) old_real: Option<(u32, u32)>,
    /// `SimData` byte offset of `zeroCrossingsPre` — the previous accepted
    /// g-values, read by the `delayZeroCrossing` builtin in `zc_context`.
    pub(crate) zc_pre_off: u32,
    /// `SimData` byte offset of the per-base-clock `$_clkfire` flags.
    pub(crate) clock_fire_off: u32,
    /// Sub-clock block of the clocked partition being lowered — C's
    /// `baseClockIndex`/`subClockIndex`, resolved to an address. `None` outside one.
    pub(crate) sub_clock_off: Option<u32>,
    /// `+profiling`'s clock plan; `None` for a model translated without it.
    pub(crate) prof: Option<Arc<ProfPlan>>,
}

/// One base clock's `SimData` slots and its parameter-dependent init expressions
/// (see [`FnCtx::emit_init_synchronous`]).
pub(crate) struct ClockInit {
    pub(crate) off: u32,
    /// `RATIONAL_CLOCK`'s `resolution`; `None` is C's default of 1.
    pub(crate) resolution: Option<Arc<DAE::Exp>>,
    /// `EVENT_CLOCK`'s `startInterval`, C's initial `stats.previousInterval`.
    pub(crate) start_interval: Option<Arc<DAE::Exp>>,
    pub(crate) sub_offs: Vec<u32>,
}

/// What one base clock's arm of `functionUpdateSynchronous` recomputes.
pub(crate) enum ClockUpdate {
    /// `RATIONAL_CLOCK`: `intervalCounter`, and `interval` from it.
    Rational(Arc<DAE::Exp>),
    /// `REAL_CLOCK`: `interval` directly.
    Real(Arc<DAE::Exp>),
    /// `INFERRED_CLOCK`, defaulted to `Clock(1, 1)`.
    Inferred,
    /// An event or solver clock has no interval to recompute.
    Nothing,
}

/// One nonlinear system's `rt_solve_nls` wiring: `k` is the job ordinal (its
/// `residual`/`load` functions occupy shared-table slots `nls_base + 4k` and
/// `nls_base + 4k + 1`), `n` is the number of iteration unknowns, `hist_off` is
/// this system's byte offset into the extrapolation-history block (allocated at
/// `NLS_HIST_GLOBAL` by the module's `start`).
#[derive(Clone, Copy)]
pub(crate) struct NlsJob {
    pub(crate) k: u32,
    pub(crate) n: u32,
    /// C's `NONLINEAR_SYSTEM_DATA::equationIndex`: the number its messages quote.
    pub(crate) eq_index: u32,
    pub(crate) hist_off: u32,
    /// Byte offset of this system's `n` nominal values into the nominal block
    /// (`NLS_NOMINAL_GLOBAL`), read by `rt_solve_nls` for x-scaling.
    pub(crate) nominal_off: u32,
    /// The system has a symbolic Jacobian: shared-table slot `4k+2` holds an
    /// `nls_jac` callback and `rt_solve_nls` uses `hybrj`.
    pub(crate) has_jac: bool,
    /// C's `NONLINEAR_SYSTEM_DATA::mixedSystem`: the residual branches on discretes.
    pub(crate) mixed: bool,
    /// Nonzero count of the Jacobian's CSC pattern, 0 where there is none.
    pub(crate) nnz: u32,
    /// Byte offset of this system's `colptr`/`rowidx` pattern into the pattern
    /// block (`NLS_PAT_GLOBAL`); only meaningful when `nnz != 0`.
    pub(crate) pat_off: u32,
    /// C's per-system default `nlsMethod` by the density/size rule: `NLS_KINSOL`
    /// (sparse) rather than the dense `NLS_MIXED` ladder. `-nls=` overrides it, and
    /// it also picks the format `nls_jac` writes (CSC vs dense `n×n`).
    pub(crate) sparse_default: bool,
    /// C's `NONLINEAR_SYSTEM_DATA::homotopySupport`.
    pub(crate) homotopy_support: bool,
    /// Dynamic tearing: this is the *casual* tearing set, so shared-table slot
    /// `4k+3` holds the strict set's `solve(sim_data) -> solved` function — C's
    /// `strictTearingFunctionCall`, which `solveNLS` falls back to.
    pub(crate) casual: bool,
}

/// Per-system solver state for `n` unknowns: a count (padded to 8), C's
/// `lastTimeSolved`, the residual scaling carried between calls, C's
/// `nlsxExtrapolation`, and `HIST_DEPTH` stored solutions (time + `n`). Matches
/// `rt_solve_nls`'s layout.
pub(crate) fn nls_hist_bytes(n: u32) -> u32 {
    const DEPTH: u32 = 10; // = the runtime's `nls::HIST_DEPTH`
    16 + 8 * n + 8 * n + DEPTH * (8 + 8 * n)
}

/// Model global holding the base address of the NLS extrapolation-history block
/// (`rt_alloc`ated once by `start`; zeroed, so every system's count starts 0).
pub(crate) const NLS_HIST_GLOBAL: u32 = 1;

/// Model global holding the base address of the NLS nominal block (`n` `f64`
/// per system, filled with codegen-time constants by `start`).
pub(crate) const NLS_NOMINAL_GLOBAL: u32 = 2;

/// Model global holding the base address of the sparse-NLS pattern block
/// (`colptr[n+1]` then `rowidx[nnz]`, `i32`, per sparsely-solved system).
pub(crate) const NLS_PAT_GLOBAL: u32 = 3;

/// Model global holding the base address of the NLS bounds block: the `min`/`max`
/// pair per iteration variable, which the solver constrains its restarts to.
pub(crate) const NLS_BOUNDS_GLOBAL: u32 = 4;

/// A variable attribute the solvers read back at run time.
#[derive(Clone, Copy, PartialEq, Eq)]
pub(crate) enum Attr {
    Nominal,
    Min,
    Max,
    /// `start`, which the optimizer reads for the input variables (C's `u0`).
    Start,
}

/// Where one variable's attribute lands: its entry in each nonlinear system that
/// iterates on it (indexing the nominal block, and the `min`/`max` pair at twice that
/// in the bounds block), and the `SimData` nominal slots the integrator scales by (a
/// state's, and in DAE mode an algebraic unknown's).
#[derive(Clone, Default)]
pub(crate) struct AttrTargets {
    pub(crate) nls: Vec<u32>,
    pub(crate) nom_offs: Vec<u32>,
    /// A state's `SimData` `max` slot, which the numeric linearization reads.
    pub(crate) max_offs: Vec<u32>,
    /// C's `realVarsData[i].attribute` as declared (`Layout::real_nom_off` and the
    /// optimizer's arrays): verbatim, without the `fmax(|nominal|, 1e-32)` clamp.
    pub(crate) raw_min_offs: Vec<u32>,
    pub(crate) raw_max_offs: Vec<u32>,
    pub(crate) raw_nom_offs: Vec<u32>,
    pub(crate) start_offs: Vec<u32>,
}

/// The contiguous `SimData` slot range backing one scalarized array model
/// variable. The backend lays an array's scalar elements out consecutively in
/// row-major order; this records the start offset and shape so a whole-array
/// reference can be marshalled to/from a runtime array object with one bulk copy.
#[derive(Clone)]
pub(crate) struct ArrayGroup {
    /// Byte offset of element `[1,1,…]` (row-major first) within `SimData`.
    pub(crate) base_off: u32,
    /// Element value type (`F64` for Real, `I32` for Integer/Boolean).
    pub(crate) wty: WTy,
    /// The elements are heap handles (String), so a read borrows and must retain.
    pub(crate) heap: bool,
    /// Array dimension sizes (row-major, outermost first).
    pub(crate) dims: Vec<u32>,
    /// Product of `dims` (number of scalar elements).
    pub(crate) total: u32,
    /// The `dims.len() + 1` pieces an element key is spelled from, one subscript
    /// between each: `["module", ".x", ""]` -> `module[i].x[j]`.
    pub(crate) key_pieces: Vec<String>,
}

impl ArrayGroup {
    /// The cref key of element `idx` (1-based), as `sim_cref_key` spells it.
    pub(crate) fn elem_key(&self, idx: &[i32]) -> String {
        let mut s = String::new();
        for (k, piece) in self.key_pieces.iter().enumerate() {
            s.push_str(piece);
            if let Some(i) = idx.get(k) {
                s.push('[');
                s.push_str(&i.to_string());
                s.push(']');
            }
        }
        s
    }
}

/// An array with no [`ArrayGroup`] because its scalarized elements are not one
/// contiguous block: alias elimination pointed them at unrelated slots, or one is
/// a negated alias. A run-time subscript selects between their own offsets.
#[derive(Clone)]
pub(crate) struct ScatterGroup {
    pub(crate) wty: WTy,
    /// See [`ArrayGroup::heap`].
    pub(crate) heap: bool,
    pub(crate) dims: Vec<u32>,
    /// `SimData` byte offset and alias negation of each element, row-major.
    pub(crate) elems: Vec<(u32, Neg)>,
}

/// A constant array's elements, row-major; it owns no `SimData` slots.
#[derive(Clone)]
pub(crate) struct ConstGroup {
    pub(crate) wty: WTy,
    pub(crate) dims: Vec<u32>,
    pub(crate) values: Vec<Arc<DAE::Exp>>,
}

/// A scalar model variable's location within the `SimData` block.
#[derive(Clone, Copy)]
pub(crate) struct SimSlot {
    /// Byte offset of the value within the `SimData` block.
    pub(crate) off: u32,
    /// Value type — `F64` for Real, `I32` for Integer/Boolean/String handle.
    pub(crate) wty: WTy,
    /// Alias negation: the cref is a negated alias of the variable at `off`, so
    /// a read negates and a write is rejected (aliases are never assigned).
    pub(crate) negate: Neg,
    /// The slot holds a reference-counted heap handle (a String). A read retains;
    /// an assignment releases the previous handle before storing the new (owned)
    /// one. Scalar Real/Integer/Boolean slots are not heap.
    pub(crate) heap: bool,
}

impl<'a> FnCtx<'a> {
    /// The simulation context, present whenever a *simulation* equation function
    /// is being lowered (`new_sim`). Absent for ordinary Modelica-function
    /// lowering; reaching a sim-only path without it is an internal error, so it
    /// is surfaced as a `Result` rather than an `unwrap` that would trap the JIT.
    pub(crate) fn sim(&self) -> Result<&SimCtx> {
        self.sim
            .as_ref()
            .ok_or_else(|| "CodegenWasmJit: sim context missing (internal error)")
    }

    /// Emit `A[n,n] = 1` for each state set's identity selection (C's
    /// `initializeStateSetPivoting`): `offs` are the SimData byte offsets of the
    /// diagonal `$STATESET.A` integer slots. Run once before initialisation so the
    /// dynamic-state-selection `SES_LINEAR`/`SES_NONLINEAR` systems (`set.x = A·q`)
    /// are non-singular; without it `A` stays 0 and the selected-state rows vanish.
    pub(crate) fn emit_stateset_diag_init(&mut self, offs: &[u32]) -> Result<()> {
        let data = self.sim()?.data_local;
        for &off in offs {
            self.emit(we::Instruction::LocalGet(data));
            self.emit(we::Instruction::I32Const(1));
            self.emit(we::Instruction::I32Store(mem_arg(off, 2)));
        }
        Ok(())
    }

    pub(crate) fn set_src_loc(&mut self, info: &metamodelica::SourceInfo) {
        self.src_loc = Some(info.clone());
    }

    /// Instructions emitted so far: where to cut a split equation function.
    pub(crate) fn instr_len(&self) -> usize {
        self.instrs.len()
    }

    pub(crate) fn emit(&mut self, i: we::Instruction<'static>) {
        // Track structured-control nesting so `break`/`continue` can compute their
        // relative branch depth. `Else` keeps the same frame; `End` closes one.
        match i {
            we::Instruction::Block(_)
            | we::Instruction::Loop(_)
            | we::Instruction::If(_)
            | we::Instruction::TryTable(..) => {
                self.ctrl_depth += 1;
            }
            we::Instruction::End => {
                self.ctrl_depth = self.ctrl_depth.saturating_sub(1);
            }
            _ => {}
        }
        self.instrs.push(i);
    }
    pub(super) fn ctrl_depth(&self) -> u32 {
        self.ctrl_depth
    }

    pub(crate) fn emit_drop(&mut self) {
        self.emit(we::Instruction::Drop);
    }

    /// Emit an unconditional branch to the structured-control frame that was open
    /// at `target_level` (a recorded `ctrl_depth`). `br 0` is the innermost frame.
    pub(super) fn branch_to(&mut self, target_level: u32) {
        let rel = self.ctrl_depth - target_level;
        self.emit(we::Instruction::Br(rel));
    }
    /// Allocate a fresh scratch local of the given type and return its index.
    /// Never reused, so transient uses inside one expression never clobber.
    pub(super) fn alloc_temp(&mut self, wty: WTy) -> u32 {
        let idx = self.n_params + self.extra_locals.len() as u32;
        self.extra_locals.push(wty.val());
        idx
    }
    pub(super) fn elem_ptr_temps(&mut self) -> (u32, u32) {
        match self.elem_ptr_tmp {
            Some(p) => p,
            None => {
                let p = (self.alloc_temp(WTy::I32), self.alloc_temp(WTy::I32));
                self.elem_ptr_tmp = Some(p);
                p
            }
        }
    }

    /// Build a context for lowering one *simulation* equation function (see
    /// `CodegenWasmJit`). The function takes the `SimData` base pointer as its
    /// single parameter (wasm local 0); all model variables resolve through
    /// `sim` rather than wasm locals. `by_name` resolves calls to model
    /// functions (Modelica functions used by the equations); `literals` is the
    /// module-wide String-literal pool.
    pub(crate) fn new_sim(
        sim: SimCtx,
        by_name: &'a HashMap<String, FnInfo>,
        literals: &'a mut Literals,
    ) -> Self {
        Self::new_sim_params(sim, by_name, literals, 1)
    }

    /// Like [`new_sim`] but for a sim helper taking extra pointer parameters after
    /// the `SimData` pointer (wasm locals `1..n_params`) — the `rt_solve_nls`
    /// `residual(sim_data, x, r)` / `load(sim_data, x)` callbacks.
    pub(crate) fn new_sim_params(
        sim: SimCtx,
        by_name: &'a HashMap<String, FnInfo>,
        literals: &'a mut Literals,
        n_params: u32,
    ) -> Self {
        FnCtx {
            locals: HashMap::new(),
            extra_locals: Vec::new(),
            n_params, // local 0 = SimData pointer
            outputs: Vec::new(),
            by_name,
            literals,
            instrs: Vec::new(),
            ctrl_depth: 0,
            loops: Vec::new(),
            borrowed_locals: Vec::new(),
            elem_ptr_tmp: None,
            src_loc: None,
            sim: Some(sim),
            dt_local_cons: false,
            dt_fallback: None,
        }
    }

    /// Dynamic tearing: whether a violated local constraint must end the evaluation
    /// (the casual set's residual), and the block a failed casual solve escapes to.
    pub(crate) fn set_dt_local_cons(&mut self, on: bool) {
        self.dt_local_cons = on;
    }

    pub(crate) fn dt_local_cons(&self) -> bool {
        self.dt_local_cons
    }

    pub(crate) fn set_dt_fallback(&mut self, level: Option<u32>) {
        self.dt_fallback = level;
    }

    pub(crate) fn dt_fallback(&self) -> Option<u32> {
        self.dt_fallback
    }

    /// Whether the system being lowered is a casual tearing set (C's
    /// `strictTearingFunctionCall != NULL`).
    pub(crate) fn dt_casual(&self) -> bool {
        self.dt_fallback.is_some()
    }

    /// Open `if (stage & mask)` around the next equation, `stage` being the DAE-mode
    /// residual's second parameter; `sim_end_block` closes it.
    pub(crate) fn sim_stage_guard(&mut self, mask: u32) {
        self.emit(we::Instruction::LocalGet(1));
        self.emit(we::Instruction::I32Const(mask as i32));
        self.emit(we::Instruction::I32And);
        self.emit(we::Instruction::If(we::BlockType::Empty));
    }

    /// Open `if (idx == v)` on the second parameter, where C dispatches with a
    /// `switch`; `sim_end_block` closes it.
    pub(crate) fn sim_index_guard(&mut self, v: u32) {
        self.emit(we::Instruction::LocalGet(1));
        self.emit(we::Instruction::I32Const(v as i32));
        self.emit(we::Instruction::I32Eq);
        self.emit(we::Instruction::If(we::BlockType::Empty));
    }

    /// Open `if (cond)`; `sim_else` starts the next branch, `sim_end_block` closes one.
    pub(crate) fn sim_if_cond(&mut self, cond: &DAE::Exp) -> Result<()> {
        let w = compile_exp(self, cond)?;
        coerce(self, w, WTy::I32);
        self.emit(we::Instruction::If(we::BlockType::Empty));
        Ok(())
    }

    pub(crate) fn sim_else(&mut self) {
        self.emit(we::Instruction::Else);
    }

    pub(crate) fn sim_end_block(&mut self) {
        self.emit(we::Instruction::End);
    }

    /// Point the clock builtins at sub-clock `off` (a `SimData` byte offset) while
    /// the partition it belongs to is lowered.
    pub(crate) fn set_sub_clock(&mut self, off: Option<u32>) {
        if let Some(s) = self.sim.as_mut() {
            s.sub_clock_off = off;
        }
    }

    /// Lower one equation `cref := rhs` into this context.
    pub(crate) fn sim_assign(&mut self, lhs: &DAE::Exp, rhs: &DAE::Exp) -> Result<()> {
        compile_assign(self, lhs, rhs)
    }

    /// Lower a list of algorithm statements into this context.
    pub(crate) fn sim_stmts(&mut self, stmts: &List<Arc<DAE::Statement>>) -> Result<()> {
        compile_stmts(self, stmts)
    }

    /// Emit `savePreValues`: `pre := live` for each `(pre_off, live_off, bytes)`
    /// region (via `memory.copy` within `SimData`). Appended to the per-step
    /// function so a `when` edge test sees the previous step's values.
    pub(crate) fn sim_save_pre_values(&mut self, regions: &[(u32, u32, u32)]) -> Result<()> {
        let data = self.sim()?.data_local;
        for &(dst_off, src_off, bytes) in regions {
            if bytes == 0 {
                continue;
            }
            self.emit(we::Instruction::LocalGet(data));
            self.emit(we::Instruction::I32Const(dst_off as i32));
            self.emit(we::Instruction::I32Add);
            self.emit(we::Instruction::LocalGet(data));
            self.emit(we::Instruction::I32Const(src_off as i32));
            self.emit(we::Instruction::I32Add);
            self.emit(we::Instruction::I32Const(bytes as i32));
            self.emit(we::Instruction::MemoryCopy { src_mem: 0, dst_mem: 0 });
        }
        Ok(())
    }

    /// Emit `initSample`: for each sample `k`, evaluate its `start`/`interval`
    /// expressions (which may reference parameters, so this runs after
    /// `functionParameters`) and store them as f64 into the sample region at
    /// `sample_off + k*16` / `+ k*16 + 8`. The driver reads them back to schedule
    /// the time events. `samples[k] = (startExp, intervalExp)`.
    pub(crate) fn emit_init_sample(
        &mut self,
        samples: &[(Arc<DAE::Exp>, Arc<DAE::Exp>)],
        sample_off: u32,
    ) -> Result<()> {
        let data = self.sim()?.data_local;
        for (k, (start, interval)) in samples.iter().enumerate() {
            let base = sample_off + k as u32 * 16;
            for (exp, off) in [(start, base), (interval, base + 8)] {
                self.emit(we::Instruction::LocalGet(data));
                let w = compile_exp(self, exp)?;
                coerce(self, w, WTy::F64);
                self.emit(we::Instruction::F64Store(mem_arg(off, 3)));
            }
        }
        Ok(())
    }

    /// Emit `functionInitSynchronous`: C's `function_initSynchronous` minus the
    /// compile-time constants. Called after `functionParameters`, since
    /// `resolution` / `startInterval` may be parameter-dependent.
    pub(crate) fn emit_init_synchronous(&mut self, clocks: &[ClockInit]) -> Result<()> {
        let data = self.sim()?.data_local;
        for c in clocks {
            self.emit(we::Instruction::LocalGet(data));
            match &c.resolution {
                Some(e) => {
                    let w = compile_exp(self, e)?;
                    coerce(self, w, WTy::I32);
                }
                None => self.emit(we::Instruction::I32Const(1)),
            }
            self.emit(we::Instruction::I32Store(mem_arg(c.off + clock_field::RESOLUTION, 2)));
            // C's `(CLOCK_STATS){<startInterval>, 0, -1}`.
            self.emit(we::Instruction::LocalGet(data));
            match &c.start_interval {
                Some(e) => {
                    let w = compile_exp(self, e)?;
                    coerce(self, w, WTy::F64);
                }
                None => self.emit(we::Instruction::F64Const(0.0.into())),
            }
            self.emit(we::Instruction::F64Store(mem_arg(c.off + clock_field::PREV_INTERVAL, 3)));
            for (off, v) in [
                (c.off + clock_field::INTERVAL, -1.0),
                (c.off + clock_field::LAST_ACTIVATION, -1.0),
            ] {
                self.emit(we::Instruction::LocalGet(data));
                self.emit(we::Instruction::F64Const(v.into()));
                self.emit(we::Instruction::F64Store(mem_arg(off, 3)));
            }
            for (off, v) in [
                (c.off + clock_field::COUNT, 0),
                (c.off + clock_field::INTERVAL_COUNTER, -1),
            ] {
                self.emit(we::Instruction::LocalGet(data));
                self.emit(we::Instruction::I32Const(v));
                self.emit(we::Instruction::I32Store(mem_arg(off, 2)));
            }
            for &sub in &c.sub_offs {
                self.emit(we::Instruction::LocalGet(data));
                self.emit(we::Instruction::F64Const(0.0.into()));
                self.emit(we::Instruction::F64Store(mem_arg(sub + clock_field::SUB_PREV_INTERVAL, 3)));
                self.emit(we::Instruction::LocalGet(data));
                self.emit(we::Instruction::F64Const((-1.0).into()));
                self.emit(we::Instruction::F64Store(mem_arg(sub + clock_field::SUB_LAST_ACTIVATION, 3)));
                self.emit(we::Instruction::LocalGet(data));
                self.emit(we::Instruction::I32Const(0));
                self.emit(we::Instruction::I32Store(mem_arg(sub + clock_field::SUB_COUNT, 2)));
            }
        }
        Ok(())
    }

    /// One base clock's arm of `functionUpdateSynchronous` (C's `updatePartition`):
    /// re-evaluate the clock's interval, which may depend on a variable.
    pub(crate) fn emit_update_synchronous(&mut self, off: u32, update: &ClockUpdate) -> Result<()> {
        let data = self.sim()?.data_local;
        match update {
            ClockUpdate::Nothing => {}
            ClockUpdate::Rational(counter) => {
                self.emit(we::Instruction::LocalGet(data));
                let w = compile_exp(self, counter)?;
                coerce(self, w, WTy::I32);
                self.emit(we::Instruction::I32Store(mem_arg(off + clock_field::INTERVAL_COUNTER, 2)));
                self.emit(we::Instruction::LocalGet(data));
                self.emit(we::Instruction::LocalGet(data));
                self.emit(we::Instruction::I32Load(mem_arg(off + clock_field::INTERVAL_COUNTER, 2)));
                self.emit(we::Instruction::F64ConvertI32S);
                self.emit(we::Instruction::LocalGet(data));
                self.emit(we::Instruction::I32Load(mem_arg(off + clock_field::RESOLUTION, 2)));
                self.emit(we::Instruction::F64ConvertI32S);
                self.emit(we::Instruction::F64Div);
                self.emit(we::Instruction::F64Store(mem_arg(off + clock_field::INTERVAL, 3)));
            }
            ClockUpdate::Real(interval) => {
                self.emit(we::Instruction::LocalGet(data));
                let w = compile_exp(self, interval)?;
                coerce(self, w, WTy::F64);
                self.emit(we::Instruction::F64Store(mem_arg(off + clock_field::INTERVAL, 3)));
            }
            // C's `INFERRED_CLOCK` default `Clock(intervalCounter=1, resolution=1)`.
            ClockUpdate::Inferred => {
                self.emit(we::Instruction::LocalGet(data));
                self.emit(we::Instruction::I32Const(1));
                self.emit(we::Instruction::I32Store(mem_arg(off + clock_field::INTERVAL_COUNTER, 2)));
                self.emit(we::Instruction::LocalGet(data));
                self.emit(we::Instruction::F64Const(1.0.into()));
                self.emit(we::Instruction::F64Store(mem_arg(off + clock_field::INTERVAL, 3)));
            }
        }
        Ok(())
    }

    /// Emit `functionUpdateBoundVariableAttributes`: the constant per-state
    /// `nominal`, then each attribute equation, into the slots the solvers read
    /// (C's `updateBoundVariableAttributes` + `updateStaticDataOfNonlinearSystems`).
    pub(crate) fn emit_update_bound_attrs(
        &mut self,
        defaults: &[(u32, f64)],
        int_defaults: &[(u32, i32)],
        attrs: &[(Attr, Arc<DAE::Exp>, AttrTargets, u32, Option<SimSlot>)],
    ) -> Result<()> {
        let data = self.sim()?.data_local;
        for (off, value) in defaults {
            self.emit(we::Instruction::LocalGet(data));
            self.emit(we::Instruction::F64Const((*value).into()));
            self.emit(we::Instruction::F64Store(mem_arg(*off, 3)));
        }
        for (off, value) in int_defaults {
            self.emit(we::Instruction::LocalGet(data));
            self.emit(we::Instruction::I32Const(*value));
            self.emit(we::Instruction::I32Store(mem_arg(*off, 2)));
        }
        if attrs.is_empty() {
            return Ok(());
        }
        let (raw, val) = (self.alloc_temp(WTy::F64), self.alloc_temp(WTy::F64));
        for (attr, exp, targets, log_off, var) in attrs {
            let w = compile_exp(self, exp)?;
            coerce(self, w, WTy::F64);
            self.emit(we::Instruction::LocalSet(raw));
            // C prints the value from inside this function; the driver reads it here.
            self.emit(we::Instruction::LocalGet(data));
            self.emit(we::Instruction::LocalGet(raw));
            self.emit(we::Instruction::F64Store(mem_arg(*log_off, 3)));
            if matches!(attr, Attr::Nominal) {
                for off in &targets.nom_offs {
                    // C's `dassl.c`: `atol[i] = tol * fmax(fabs(nominal), 1e-32)`.
                    self.emit(we::Instruction::LocalGet(data));
                    self.emit(we::Instruction::LocalGet(raw));
                    self.emit(we::Instruction::F64Abs);
                    self.emit(we::Instruction::F64Const(1e-32f64.into()));
                    self.emit(we::Instruction::F64Max);
                    self.emit(we::Instruction::F64Store(mem_arg(*off, 3)));
                }
            }
            if matches!(attr, Attr::Max) {
                for off in &targets.max_offs {
                    self.emit(we::Instruction::LocalGet(data));
                    self.emit(we::Instruction::LocalGet(raw));
                    self.emit(we::Instruction::F64Store(mem_arg(*off, 3)));
                }
            }
            let raw_offs: &[u32] = match attr {
                Attr::Min => &targets.raw_min_offs,
                Attr::Max => &targets.raw_max_offs,
                Attr::Nominal => &targets.raw_nom_offs,
                Attr::Start => &targets.start_offs,
            };
            for off in raw_offs {
                self.emit(we::Instruction::LocalGet(data));
                self.emit(we::Instruction::LocalGet(raw));
                self.emit(we::Instruction::F64Store(mem_arg(*off, 3)));
            }
            // C's `postExp`: `<var> = $START.<var>`, but not for a String, whose slot
            // holds a reference-counted handle.
            if let Some(slot) = var.filter(|s| s.negate == Neg::None && !s.heap) {
                self.emit(we::Instruction::LocalGet(data));
                self.emit(we::Instruction::LocalGet(raw));
                match slot.wty {
                    WTy::F64 => self.emit(we::Instruction::F64Store(mem_arg(slot.off, 3))),
                    _ => {
                        self.emit(we::Instruction::I32TruncSatF64S);
                        self.emit(we::Instruction::I32Store(mem_arg(slot.off, 2)));
                    }
                }
            }
            if targets.nls.is_empty() {
                continue;
            }
            self.emit(we::Instruction::LocalGet(raw));
            match attr {
                // `start` has no nonlinear-solver slot; it only feeds the optimizer.
                Attr::Start => {}
                // A nonpositive nominal would collapse the x-scaling; 1 stands in.
                Attr::Nominal => {
                    self.emit(we::Instruction::F64Abs);
                    self.emit(we::Instruction::LocalTee(val));
                    self.emit(we::Instruction::F64Const(1.0f64.into()));
                    self.emit(we::Instruction::LocalGet(val));
                    self.emit(we::Instruction::F64Const(0.0f64.into()));
                    self.emit(we::Instruction::F64Gt);
                    self.emit(we::Instruction::Select);
                }
                Attr::Min | Attr::Max => {}
            }
            self.emit(we::Instruction::LocalSet(val));
            let (global, stride, slot) = match attr {
                Attr::Nominal => (NLS_NOMINAL_GLOBAL, 8, 0),
                Attr::Min => (NLS_BOUNDS_GLOBAL, 16, 0),
                Attr::Max => (NLS_BOUNDS_GLOBAL, 16, 8),
                // Not a solver input; `targets.nls` is empty for a `start`.
                Attr::Start => continue,
            };
            for idx in &targets.nls {
                self.emit(we::Instruction::GlobalGet(global));
                self.emit(we::Instruction::LocalGet(val));
                self.emit(we::Instruction::F64Store(mem_arg(idx * stride + slot, 3)));
            }
        }
        Ok(())
    }

    /// Store each real variable's declared `start` value in its start attribute
    /// slot at `off`.
    pub(crate) fn emit_init_start_values(&mut self, starts: &[(f64, u32)]) -> Result<()> {
        let data = self.sim()?.data_local;
        for (value, off) in starts {
            self.emit(we::Instruction::LocalGet(data));
            self.emit(we::Instruction::F64Const((*value).into()));
            self.emit(we::Instruction::F64Store(mem_arg(*off, 3)));
        }
        Ok(())
    }

    /// Emit `functionZeroCrossings`: store each crossing `k`'s g-value as f64 at
    /// `gout + k*8`, `gout` being the second parameter. A `Bool` crossing stores
    /// `expr ? 1 : -1`, as C's `gout[k] = (relation_) ? 1 : -1`.
    pub(crate) fn emit_zero_crossings(
        &mut self,
        crossings: &[crate::CodegenWasmJit::ZcInfo],
        gout_local: u32,
    ) -> Result<()> {
        use crate::CodegenWasmJit::ZcInfo;
        for (k, zc) in crossings.iter().enumerate() {
            self.emit(we::Instruction::LocalGet(gout_local));
            match zc {
                ZcInfo::Bool { expr } => {
                    // `select` picks `1.0` when the condition (top of stack) is
                    // nonzero, else `-1.0`; push both values first, condition last.
                    self.emit(we::Instruction::F64Const(1.0f64.into()));
                    self.emit(we::Instruction::F64Const((-1.0f64).into()));
                    let w = compile_exp(self, expr)?;
                    coerce(self, w, WTy::I32);
                    self.emit(we::Instruction::Select);
                }
                ZcInfo::Math { kind, ops, idx, .. } => {
                    // gout = (test(fresh arg) != test(held pre)) ? 1 : -1.
                    self.emit(we::Instruction::F64Const(1.0f64.into()));
                    self.emit(we::Instruction::F64Const((-1.0f64).into()));
                    emit_math_test_fresh(self, *kind, ops)?;
                    emit_math_test_pre(self, *kind, *idx)?;
                    self.emit(we::Instruction::F64Ne);
                    self.emit(we::Instruction::Select);
                }
            }
            self.emit(we::Instruction::F64Store(mem_arg(k as u32 * 8, 3)));
        }
        Ok(())
    }

    /// Emit `functionUpdateRelations`: store each relation's exact value into
    /// `relations[i]`, C's `function_updateRelations(data, 0)`. No hysteresis band
    /// and no held `relationsPre`, so the event handler can snapshot the result as
    /// the band direction. `None` entries keep their index without a store.
    pub(crate) fn emit_update_relations(
        &mut self,
        relations: &[Option<Arc<DAE::Exp>>],
        relations_off: u32,
    ) -> Result<()> {
        let data = self.sim()?.data_local;
        if relations.len() > self.sim()?.n_relations as usize {
            return Err("CodegenWasmJit: relations list longer than the relations[] region");
        }
        for (i, rel) in relations.iter().enumerate() {
            let Some(rel) = rel else { continue };
            let DAE::Exp::RELATION { exp1, operator, exp2, .. } = &**rel else {
                return Err("CodegenWasmJit: non-relation in the relations list");
            };
            self.emit(we::Instruction::LocalGet(data));
            let w = compile_relation_fresh(self, exp1, operator, exp2)?;
            coerce(self, w, WTy::I32);
            self.emit(we::Instruction::I32Store(mem_arg(relations_off + i as u32 * 4, 2)));
        }
        Ok(())
    }

    /// Emit `functionStoreDelayed`: `rt_delay_store(idx, time, e, d, dmax)` per
    /// `delay(...)` expression (C's `function_storeDelayed`).
    pub(crate) fn emit_store_delayed(
        &mut self,
        delayed: &[(i32, Arc<DAE::Exp>, Arc<DAE::Exp>, Arc<DAE::Exp>)],
    ) -> Result<()> {
        let data = self.sim()?.data_local;
        for (idx, e, d, dmax) in delayed {
            self.emit(we::Instruction::I32Const(*idx));
            self.emit(we::Instruction::LocalGet(data)); // time (TIME_OFF = 0)
            self.emit(we::Instruction::F64Load(mem_arg(0, 3)));
            for exp in [e, d, dmax] {
                let w = compile_exp(self, exp)?;
                coerce(self, w, WTy::F64);
            }
            self.emit(we::Instruction::Call(rt_index("rt_delay_store")?));
        }
        Ok(())
    }

    /// Emit `functionStoreSpatialDistribution`: `rt_spatial_store(idx, time, in0,
    /// in1, x, positiveVelocity)` per `spatialDistribution(...)` operator (C's
    /// `function_storeSpatialDistribution`).
    ///
    /// An operator inside an `if`-branch is guarded by the same condition as the
    /// branch: storing while it is inactive would advance a profile the model is not
    /// reading (#16099).
    pub(crate) fn emit_store_spatial(
        &mut self,
        spatial: &[SimCode::SpatialDistribution],
    ) -> Result<()> {
        let data = self.sim()?.data_local;
        for sd in spatial {
            if let Some(cond) = &sd.condition {
                compile_bool_operand(self, cond)?;
                self.emit(we::Instruction::If(we::BlockType::Empty));
            }
            self.emit(we::Instruction::I32Const(sd.index));
            self.emit(we::Instruction::LocalGet(data)); // time (TIME_OFF = 0)
            self.emit(we::Instruction::F64Load(mem_arg(0, 3)));
            for exp in [&sd.in0, &sd.in1, &sd.pos] {
                let w = compile_exp(self, exp)?;
                coerce(self, w, WTy::F64);
            }
            let w = compile_exp(self, &sd.dir)?;
            coerce(self, w, WTy::I32);
            self.emit(we::Instruction::Call(rt_index("rt_spatial_store")?));
            if sd.condition.is_some() {
                self.emit(we::Instruction::End);
            }
        }
        Ok(())
    }

    /// Emit `functionInitSpatialDistribution`: allocate the operators for this run
    /// and fill each from its `initialPoints`/`initialValues` parameter arrays (C's
    /// `allocSpatialDistribution` + `function_initSpatialDistribution`).
    pub(crate) fn emit_init_spatial(
        &mut self,
        n_spatial: u32,
        spatial: &[SimCode::SpatialDistribution],
    ) -> Result<()> {
        self.emit(we::Instruction::I32Const(n_spatial as i32));
        self.emit(we::Instruction::Call(rt_index("rt_spatial_init")?));
        for sd in spatial {
            // The two array handles are owned here and only borrowed by the runtime,
            // so they go through temps and are released after the call.
            let mut temps = Vec::new();
            for exp in [&sd.initPnts, &sd.initVals] {
                let w = compile_exp(self, exp)?;
                if w != WTy::I32 {
                    return Err("CodegenWasmJit: spatialDistribution initialPoints/initialValues is not an array");
                }
                let t = self.alloc_temp(WTy::I32);
                self.emit(we::Instruction::LocalSet(t));
                temps.push(t);
            }
            self.emit(we::Instruction::I32Const(sd.index));
            for t in &temps {
                self.emit(we::Instruction::LocalGet(*t));
            }
            self.emit(we::Instruction::Call(rt_index("rt_spatial_init_profile")?));
            for t in &temps {
                release_temp_array(self, *t)?;
            }
        }
        Ok(())
    }

    /// Clear the rejected-residual index, so a re-run never reports a stale verdict.
    pub(crate) fn emit_removed_init_reset(&mut self, idx_off: u32) -> Result<()> {
        let data = self.sim()?.data_local;
        self.emit(we::Instruction::LocalGet(data));
        self.emit(we::Instruction::I32Const(0));
        self.emit(we::Instruction::I32Store(mem_arg(idx_off, 2)));
        Ok(())
    }

    /// C's `functionRemovedInitialEquationsBody`: missing zero by more than `1e-5`
    /// leaves the residual and its 1-based index behind for the driver and ends the
    /// function, as C's `return 1` does.
    pub(crate) fn emit_removed_init_residual(
        &mut self,
        index: u32,
        exp: &DAE::Exp,
        res_off: u32,
        idx_off: u32,
    ) -> Result<()> {
        use we::Instruction as I;
        let data = self.sim()?.data_local;
        let res = self.alloc_temp(WTy::F64);
        let w = compile_exp(self, exp)?;
        coerce(self, w, WTy::F64);
        self.emit(I::LocalTee(res));
        self.emit(I::F64Abs);
        self.emit(I::F64Const(1e-5f64.into()));
        self.emit(I::F64Gt);
        self.emit(I::If(we::BlockType::Empty));
        self.emit(I::LocalGet(data));
        self.emit(I::LocalGet(res));
        self.emit(I::F64Store(mem_arg(res_off, 3)));
        self.emit(I::LocalGet(data));
        self.emit(I::I32Const(index as i32 + 1));
        self.emit(I::I32Store(mem_arg(idx_off, 2)));
        self.emit(I::Return);
        self.emit(I::End);
        Ok(())
    }

    /// Lower a `when {conditions} then whenStmtLst; elseWhen` equation. The body
    /// runs on the rising edge of any condition — `cond && !pre(cond)`, matching
    /// the C target (`equationWhen`) — so it fires once per event and pre-values
    /// must be saved after each step.
    pub(crate) fn sim_when(
        &mut self,
        conditions: &List<Arc<DAE::ComponentRef>>,
        stmts: &List<openmodelica_backend_types::BackendDAE::WhenOperator>,
        else_when: &Option<Arc<openmodelica_simcode_types::SimCode::SimEqSystem>>,
    ) -> Result<()> {
        use we::Instruction as I;
        let conds: Vec<&Arc<DAE::ComponentRef>> = (&**conditions).into_iter().collect();
        // Edge guard: OR of `cond && !pre(cond)`; an empty condition list never
        // fires (C emits `0`).
        if conds.is_empty() {
            self.emit(I::I32Const(0));
        } else {
            for (i, c) in conds.iter().enumerate() {
                if compile_sim_cref_read(self, c)?.is_none() {
                    return Err("CodegenWasmJit: when-condition is not a model variable");
                }
                let pre = pre_cref(c);
                compile_sim_cref_read(self, &pre)?;
                self.emit(I::I32Eqz); // !pre(cond)
                self.emit(I::I32And); // cond && !pre(cond)
                if i > 0 {
                    self.emit(I::I32Or);
                }
            }
        }
        self.emit(I::If(we::BlockType::Empty));
        for op in &**stmts {
            self.lower_when_op(op)?;
        }
        if let Some(ew) = else_when {
            self.emit(I::Else);
            match &**ew {
                openmodelica_simcode_types::SimCode::SimEqSystem::SES_WHEN {
                    conditions, whenStmtLst, elseWhen, ..
                } => self.sim_when(conditions, whenStmtLst, elseWhen)?,
                other => return Err("CodegenWasmJit: elseWhen is not a SES_WHEN"),
            }
        }
        self.emit(I::End);
        Ok(())
    }

    fn lower_when_op(&mut self, op: &openmodelica_backend_types::BackendDAE::WhenOperator) -> Result<()> {
        use openmodelica_backend_types::BackendDAE::WhenOperator as W;
        match op {
            W::ASSIGN { left, right, .. } => compile_assign(self, left, right),
            W::REINIT { stateVar, value, .. } => {
                let lhs = DAE::Exp::CREF { componentRef: stateVar.clone(), ty: crate::CodegenWasmJit::t_real() };
                compile_assign(self, &lhs, value)?;
                emit_reinit_note(self, stateVar)
            }
            W::TERMINATE { message, source } => emit_terminate(self, message, source),
            W::ASSERT { condition, message, level, source } => emit_assert(self, condition, message, level, source),
            W::NORETCALL { exp, .. } => emit_noretcall(self, exp),
        }
    }

    /// Finish a hand-assembled (simulation) function body: append the final
    /// `end`, and return its extra-local declarations and instruction stream
    /// ready for `we::Function::new`. The caller has already emitted any
    /// `return`/fall-through value handling appropriate for the function.
    pub(crate) fn finish_sim(mut self) -> (Vec<we::ValType>, Vec<we::Instruction<'static>>) {
        self.emit(we::Instruction::End);
        (self.extra_locals, self.instrs)
    }
}
