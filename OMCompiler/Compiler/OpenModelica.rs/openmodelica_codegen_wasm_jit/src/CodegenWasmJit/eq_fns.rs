//! Lowering equation lists into wasm functions: units, chunking and
//! splitting oversized bodies, shared chunks.

use super::*;

pub(super) fn finish_fn(ctx: FnCtx) -> we::Function {
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    func
}

/// One lowering step of an equation entry point.
pub(super) enum EqUnit<'a> {
    /// A parameter's binding expression, assigned ahead of `parameterEquations`.
    Binding(&'a Arc<DAE::ComponentRef>, &'a Arc<DAE::Exp>),
    /// A SimCode equation; `Some(mask)` adds the DAE-mode stage guard.
    Eq(&'a Arc<SimCode::SimEqSystem>, Option<u32>),
}

impl EqUnit<'_> {
    /// Operands of a plain `cref := exp`, which `sim_const_store` may fold into a
    /// data segment.
    fn assign_operands(&self) -> Option<(&Arc<DAE::ComponentRef>, &Arc<DAE::Exp>)> {
        match self {
            EqUnit::Binding(cref, exp) => Some((cref, exp)),
            EqUnit::Eq(eq, None) => match &***eq {
                SimCode::SimEqSystem::SES_SIMPLE_ASSIGN { cref, exp, .. } => Some((cref, exp)),
                _ => None,
            },
            EqUnit::Eq(_, Some(_)) => None,
        }
    }
}

/// Lower one unit. A constant store to a `SimData` slot reads nothing, so a
/// consecutive stretch of them may be merged: such a unit only joins `pending`
/// (by slot offset, last value winning), and anything else first flushes the
/// stretch as data segments through `emit_sim_const_stores`.
pub(super) fn lower_unit(
    ctx: &mut FnCtx,
    unit: &EqUnit,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    pending: &mut BTreeMap<u32, Vec<u8>>,
) -> Result<()> {
    if let Some((cref, exp)) = unit.assign_operands() {
        if let Some((off, bytes)) = sim_const_store(ctx, cref, exp)? {
            pending.insert(off, bytes);
            return Ok(());
        }
    }
    emit_sim_const_stores(ctx, &core::mem::take(pending))?;
    match unit {
        EqUnit::Binding(cref, exp) => {
            let lhs = DAE::Exp::CREF { componentRef: (*cref).clone(), ty: t_real() };
            ctx.sim_assign(&lhs, exp)
        }
        EqUnit::Eq(eq, stages) => {
            if let Some(mask) = stages {
                ctx.sim_stage_guard(*mask);
            }
            lower_equation(ctx, eq, eq_index)?;
            if stages.is_some() {
                ctx.sim_end_block();
            }
            Ok(())
        }
    }
}

/// Instruction budget for one chunk of a split equation entry point, cut on emitted
/// size rather than equation count (one `SES_ALGORITHM` can outweigh a thousand
/// assignments). Emitting a whole list as one function makes Cranelift the dominant
/// cost of a wasm-jit build: its register allocation is superlinear in body size,
/// every declared local is zero-initialized at entry, and per-function parallel
/// compilation has nothing to spread. `OMC_WASM_CHUNK_INSTRS` overrides it; 0 never
/// splits.
fn chunk_instrs() -> usize {
    static N: OnceLock<usize> = OnceLock::new();
    *N.get_or_init(|| match std::env::var("OMC_WASM_CHUNK_INSTRS").ok().and_then(|v| v.parse().ok()) {
        Some(0) => usize::MAX,
        Some(n) => n,
        None => 4096,
    })
}

/// [`chunk_instrs`] for a nonlinear system's residual, which `OMC_WASM_NLS_CHUNK_INSTRS`
/// overrides separately; 0 never splits.
pub(super) fn nls_chunk_instrs() -> usize {
    static N: OnceLock<usize> = OnceLock::new();
    *N.get_or_init(|| match std::env::var("OMC_WASM_NLS_CHUNK_INSTRS").ok().and_then(|v| v.parse().ok()) {
        Some(0) => usize::MAX,
        Some(n) => n,
        None => chunk_instrs(),
    })
}

/// An equation entry point lowered into chunk functions. The entry points sit at
/// fixed function indices (`simulate` and the host driver call them by index), so
/// the chunks go after every fixed-index body and their indices are only known at
/// the end of module assembly: the entry point is reserved as a placeholder body
/// and filled in with [`SplitFn::thunk`] there.
pub(super) struct SplitFn {
    /// Body-list slot reserved for the entry point.
    pub(super) slot: usize,
    /// This entry point's chunks, by position in [`ChunkPool`]. Entry points that
    /// evaluate the same equations share them (see [`eq_segments`]).
    pub(super) chunks: Vec<usize>,
    /// `(SimData*)`, plus DAE mode's `stage`.
    pub(super) n_params: u32,
    /// Entry points called (with the same arguments) ahead of the chunks.
    pub(super) pre_calls: Vec<u32>,
}

impl SplitFn {
    pub(super) fn thunk(&self, chunk_base: u32) -> we::Function {
        use we::Instruction as I;
        let mut f = we::Function::new([]);
        let mut call = |f: &mut we::Function, idx: u32| {
            for p in 0..self.n_params {
                f.instruction(&I::LocalGet(p));
            }
            f.instruction(&I::Call(idx));
        };
        for c in &self.pre_calls {
            call(&mut f, *c);
        }
        for c in &self.chunks {
            call(&mut f, chunk_base + *c as u32);
        }
        f.instruction(&I::End);
        f
    }
}

/// The module's chunk functions, emitted after every fixed-index body. An entry
/// point names them by pool position, and several may name the same one.
#[derive(Default)]
pub(super) struct ChunkPool {
    pub(super) fns: Vec<we::Function>,
    /// Per chunk, for the function and name sections.
    pub(super) meta: Vec<(u32, String)>,
}

impl ChunkPool {
    pub(super) fn len(&self) -> usize {
        self.fns.len()
    }
    pub(super) fn push(&mut self, f: we::Function, ty: u32, name: String) {
        self.fns.push(f);
        self.meta.push((ty, name));
    }
}

/// Lower `units` into chunk functions appended to `pool`, reserving a `bodies`
/// slot for the entry point that calls them. `stateset_diag` heads the first chunk
/// and `save_pre` tails the last; with no units at all they get a chunk to
/// themselves. Cuts only happen where no constant-store stretch is open, so
/// [`lower_unit`]'s merging never straddles a chunk boundary.
#[allow(clippy::too_many_arguments)]
pub(super) fn build_split_fn(
    name: &'static str,
    units: &[EqUnit],
    n_params: u32,
    ty: u32,
    stateset_diag: &[u32],
    save_pre: &[(u32, u32, u32)],
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
    bodies: &mut Vec<we::Function>,
    pool: &mut ChunkPool,
    per_unit: bool,
) -> Result<SplitFn> {
    let slot = bodies.len();
    bodies.push(empty_eqfn());
    let chunks = build_chunks(
        name, units, n_params, ty, stateset_diag, save_pre, var_map, eq_index, by_name, literals,
        pool, per_unit,
    )?;
    Ok(SplitFn { slot, chunks, n_params, pre_calls: Vec::new() })
}

/// [`build_split_fn`] without an entry point of its own.
#[allow(clippy::too_many_arguments)]
pub(super) fn build_chunks(
    name: &str,
    units: &[EqUnit],
    n_params: u32,
    ty: u32,
    stateset_diag: &[u32],
    save_pre: &[(u32, u32, u32)],
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
    pool: &mut ChunkPool,
    per_unit: bool,
) -> Result<Vec<usize>> {
    let first = pool.len();
    let mut i = 0usize;
    let _fg = crate::CodegenWasmJitFunctions::FnNameGuard::new(name);
    while i < units.len() || (pool.len() == first && !(stateset_diag.is_empty() && save_pre.is_empty()))
    {
        let mut ctx = FnCtx::new_sim_params(sim_ctx(var_map), by_name, &mut *literals, n_params);
        if pool.len() == first {
            ctx.emit_stateset_diag_init(stateset_diag)?;
        }
        let mut pending: BTreeMap<u32, Vec<u8>> = BTreeMap::new();
        while i < units.len() {
            // Cancellation poll, throttled: the equation functions are the bulk of
            // the emit for models with no user functions to poll between.
            if i & 63 == 0 {
                metamodelica::cancel::bail_if_cancelled()?;
            }
            lower_unit(&mut ctx, &units[i], eq_index, &mut pending)?;
            i += 1;
            if per_unit || (pending.is_empty() && ctx.instr_len() >= chunk_instrs()) {
                break;
            }
        }
        emit_sim_const_stores(&mut ctx, &pending)?;
        if i == units.len() {
            ctx.sim_save_pre_values(save_pre)?;
        }
        pool.push(finish_fn(ctx), ty, format!("{name}${}", pool.len() - first));
    }
    Ok((first..pool.len()).collect())
}

/// `Dae` is C's `allEquationsPlusWhen` surplus: the when-equations, which only
/// `functionDAE` runs.
#[derive(Clone, Copy, PartialEq)]
enum EqOwner {
    Ode,
    Alg,
    Dae,
}

/// A run of `allEquations` that is also a run of the `odeEquations` or
/// `algebraicEquations` list holding it, so its chunks serve both entry points, the
/// way C's `eqFunction_<n>` do.
pub(super) struct EqSegment {
    owner: EqOwner,
    /// Where the run starts in its own list (0 for an [`EqOwner::Dae`] run).
    pos: usize,
    /// Where it sits in `allEquations`.
    span: core::ops::Range<usize>,
    chunks: Vec<usize>,
}

/// The equation's own index, including the forms [`eq_index_of`] leaves at -1.
fn eq_id_of(eq: &SimCode::SimEqSystem) -> i32 {
    use SimCode::SimEqSystem as E;
    match eq {
        E::SES_ALIAS { index, .. } | E::SES_FOR_EQUATION { index, .. } => *index,
        _ => eq_index_of(eq),
    }
}

/// Cut `all` (C's `allEquations`) into runs shared with `ode`/`alg`; `None` unless
/// the two tile what they claim of it, which leaves the caller lowering a copy of
/// its own.
///
/// The orders differ by more than the interleaving -- `algebraicEquations` ends with
/// C's `removedEquations` reversed -- so that tail comes back one equation per run.
pub(super) fn eq_segments(
    ode: &[Arc<SimCode::SimEqSystem>],
    alg: &[Arc<SimCode::SimEqSystem>],
    all: &[Arc<SimCode::SimEqSystem>],
) -> Option<Vec<EqSegment>> {
    let mut own: HashMap<i32, (EqOwner, usize)> = HashMap::new();
    for (owner, eqs) in [(EqOwner::Ode, ode), (EqOwner::Alg, alg)] {
        for (pos, e) in eqs.iter().enumerate() {
            if own.insert(eq_id_of(e), (owner, pos)).is_some() {
                return None;
            }
        }
    }
    let mut segs: Vec<EqSegment> = Vec::new();
    for (i, e) in all.iter().enumerate() {
        let (owner, pos) = own.get(&eq_id_of(e)).copied().unwrap_or((EqOwner::Dae, 0));
        let joins = |s: &EqSegment| {
            s.owner == owner && (owner == EqOwner::Dae || s.pos + s.span.len() == pos)
        };
        match segs.last_mut() {
            Some(s) if joins(s) => s.span.end = i + 1,
            _ => segs.push(EqSegment { owner, pos, span: i..i + 1, chunks: Vec::new() }),
        }
    }
    // An entry point calls its own segments in its list's order, so they must tile it.
    for (owner, len) in [(EqOwner::Ode, ode.len()), (EqOwner::Alg, alg.len())] {
        let mut runs: Vec<(usize, usize)> =
            segs.iter().filter(|s| s.owner == owner).map(|s| (s.pos, s.span.len())).collect();
        runs.sort_unstable();
        let mut next = 0;
        for (pos, n) in runs {
            if pos != next {
                return None;
            }
            next += n;
        }
        if next != len {
            return None;
        }
    }
    Some(segs)
}

/// Lower the segments once; the three entry points' chunk lists come back, each
/// headed by `functionLocalKnownVars` as C's are.
#[allow(clippy::too_many_arguments)]
pub(super) fn build_shared_eq_chunks(
    mut segs: Vec<EqSegment>,
    all: &[Arc<SimCode::SimEqSystem>],
    local_known: &[Arc<SimCode::SimEqSystem>],
    ty: u32,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
    pool: &mut ChunkPool,
) -> Result<(Vec<usize>, Vec<usize>, Vec<usize>)> {
    let head = build_chunks(
        "functionLocalKnownVars", &eq_units(local_known), 1, ty, &[], &[], var_map, eq_index,
        by_name, literals, pool, false,
    )?;
    for seg in &mut segs {
        let name = format!("eqFunction_{}", eq_id_of(&all[seg.span.start]));
        seg.chunks = build_chunks(
            &name, &eq_units(&all[seg.span.clone()]), 1, ty, &[], &[], var_map, eq_index, by_name,
            literals, pool, false,
        )?;
    }
    let call = |segs: &[&EqSegment]| -> Vec<usize> {
        head.iter().copied().chain(segs.iter().flat_map(|s| s.chunks.iter().copied())).collect()
    };
    let own = |owner: EqOwner| -> Vec<&EqSegment> {
        let mut own: Vec<&EqSegment> = segs.iter().filter(|s| s.owner == owner).collect();
        own.sort_by_key(|s| s.pos);
        own
    };
    Ok((call(&own(EqOwner::Ode)), call(&own(EqOwner::Alg)), call(&segs.iter().collect::<Vec<_>>())))
}

/// Lower `units` into one function, for entry points whose size is bounded by the
/// model's structure rather than its equation count.
pub(super) fn build_eq_fn_single(
    units: &[EqUnit],
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut ctx = FnCtx::new_sim(sim_ctx(var_map), by_name, literals);
    let mut pending: BTreeMap<u32, Vec<u8>> = BTreeMap::new();
    for (i, unit) in units.iter().enumerate() {
        if i & 63 == 0 {
            metamodelica::cancel::bail_if_cancelled()?;
        }
        lower_unit(&mut ctx, unit, eq_index, &mut pending)?;
    }
    emit_sim_const_stores(&mut ctx, &pending)?;
    Ok(finish_fn(ctx))
}

/// `EqUnit::Eq` over a plain equation list.
pub(super) fn eq_units(eqs: &[Arc<SimCode::SimEqSystem>]) -> Vec<EqUnit<'_>> {
    eqs.iter().map(|e| EqUnit::Eq(e, None)).collect()
}

/// Build the `initSample(SimData*)` function: evaluate each sample's
/// `start`/`interval` into the sample region (see [`FnCtx::emit_init_sample`]).
/// Called by the driver after `functionParameters`.
pub(super) fn build_init_sample_fn(
    samples: &[SampleInfo],
    layout: &SimLayout,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let sim = sim_ctx(var_map);
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    let pairs: Vec<(Arc<DAE::Exp>, Arc<DAE::Exp>)> =
        samples.iter().map(|s| (s.start.clone(), s.interval.clone())).collect();
    ctx.emit_init_sample(&pairs, layout.sample_off)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}
