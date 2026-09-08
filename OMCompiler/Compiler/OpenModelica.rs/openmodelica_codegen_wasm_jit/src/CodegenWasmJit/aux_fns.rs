//! The model's auxiliary exported functions: init/sample, synchronous,
//! bound attributes, zero crossings, relations, delay and spatialDistribution.

use super::*;

/// The initial equations the backend removed as redundant, kept as `0 = <exp>`
/// checks. A `SCONST` residual is C's `res = 0`, never inconsistent.
pub(super) fn removed_init_residuals(sim_code: &SimCode::SimCode) -> Vec<&Arc<DAE::Exp>> {
    lst(&sim_code.removedInitialEquations)
        .filter_map(|eq| match &**eq {
            SimCode::SimEqSystem::SES_RESIDUAL { exp, .. } => Some(exp),
            _ => None,
        })
        .filter(|exp| !matches!(&***exp, DAE::Exp::SCONST { .. }))
        .collect()
}

/// Build `functionRemovedInitialEquations(SimData*)`. The first residual off zero
/// stops the function; a non-residual entry is an ordinary equation.
pub(super) fn build_removed_init_eqs_fn(
    sim_code: &SimCode::SimCode,
    layout: &SimLayout,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut ctx = FnCtx::new_sim(sim_ctx(var_map), by_name, literals);
    ctx.emit_removed_init_reset(layout.removed_init_idx_off)?;
    let mut pending: BTreeMap<u32, Vec<u8>> = BTreeMap::new();
    let mut index = 0u32;
    for eq in lst(&sim_code.removedInitialEquations) {
        match &**eq {
            SimCode::SimEqSystem::SES_RESIDUAL { exp, .. } => {
                if matches!(&**exp, DAE::Exp::SCONST { .. }) {
                    continue;
                }
                emit_sim_const_stores(&mut ctx, &core::mem::take(&mut pending))?;
                ctx.emit_removed_init_residual(
                    index,
                    exp,
                    layout.removed_init_res_off,
                    layout.removed_init_idx_off,
                )?;
                index += 1;
            }
            _ => lower_unit(&mut ctx, &EqUnit::Eq(eq, None), eq_index, &mut pending)?,
        }
    }
    emit_sim_const_stores(&mut ctx, &pending)?;
    Ok(finish_fn(ctx))
}

/// Build `functionInitSynchronous(SimData*)` — C's `function_initSynchronous`.
pub(super) fn build_init_synchronous_fn(
    clocks: &[ClockInfo],
    layout: &SimLayout,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut ctx = FnCtx::new_sim(sim_ctx(var_map), by_name, literals);
    let inits: Vec<ClockInit> = clocks
        .iter()
        .enumerate()
        .map(|(i, c)| ClockInit {
            off: layout.base_clock_off(i as u32),
            resolution: match &*c.kind {
                DAE::ClockKind::RATIONAL_CLOCK { resolution, .. } => Some(resolution.clone()),
                _ => None,
            },
            start_interval: match &*c.kind {
                DAE::ClockKind::EVENT_CLOCK { startInterval, .. } => Some(startInterval.clone()),
                _ => None,
            },
            sub_offs: (0..c.meta.sub.len() as u32)
                .map(|k| layout.sub_clock_off(c.meta.sub_base + k))
                .collect(),
        })
        .collect();
    ctx.emit_init_synchronous(&inits)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionUpdateSynchronous(SimData*, base_idx)` — C's
/// `function_updateSynchronous`, whose `switch` becomes one `if` per base clock.
pub(super) fn build_update_synchronous_fn(
    clocks: &[ClockInfo],
    layout: &SimLayout,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut ctx = FnCtx::new_sim_params(sim_ctx(var_map), by_name, literals, 2);
    for (i, c) in clocks.iter().enumerate() {
        let update = match &*c.kind {
            DAE::ClockKind::RATIONAL_CLOCK { intervalCounter, .. } => ClockUpdate::Rational(intervalCounter.clone()),
            DAE::ClockKind::REAL_CLOCK { interval } => ClockUpdate::Real(interval.clone()),
            DAE::ClockKind::INFERRED_CLOCK => ClockUpdate::Inferred,
            DAE::ClockKind::EVENT_CLOCK { .. } | DAE::ClockKind::SOLVER_CLOCK { .. } => ClockUpdate::Nothing,
        };
        if matches!(update, ClockUpdate::Nothing) {
            continue;
        }
        ctx.sim_index_guard(i as u32);
        ctx.emit_update_synchronous(layout.base_clock_off(i as u32), &update)?;
        ctx.sim_end_block();
    }
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionEquationsSynchronous(SimData*, sub_idx)` — C's
/// `function_equationsSynchronous`, with the (base, sub) pair flattened to the
/// sub-clock's index in the `SimData` sub-clock region.
pub(super) fn build_equations_synchronous_fn(
    clocks: &[ClockInfo],
    layout: &SimLayout,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut ctx = FnCtx::new_sim_params(sim_ctx(var_map), by_name, literals, 2);
    for c in clocks {
        for (k, eqs) in c.sub_eqs.iter().enumerate() {
            let flat = c.meta.sub_base + k as u32;
            ctx.sim_index_guard(flat);
            ctx.set_sub_clock(Some(layout.sub_clock_off(flat)));
            for eq in eqs {
                lower_equation(&mut ctx, eq, eq_index)?;
            }
            ctx.set_sub_clock(None);
            ctx.sim_end_block();
        }
    }
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionInitStartValues(SimData*)`: every real variable's `start`
/// attribute slot, in real-variable index order — the values C's `_init.xml`
/// carries. The driver copies the slots over the live region afterwards (C's
/// `setAllVarsToStart`), so `-iif`/`-override` land in between. Literals only, as
/// in C's `SerializeInitXML.expString`: evaluating a parameter-bound start here
/// would put it on the wrong side of the `pre`-value snapshot.
pub(super) fn build_init_start_values_fn(
    reals: &[&SimCodeVar::SimVar],
    layout: &SimLayout,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut ctx = FnCtx::new_sim(sim_ctx(var_map), by_name, literals);
    let starts: Vec<(f64, u32)> = reals
        .iter()
        .enumerate()
        .map(|(i, sv)| (literal_value(&sv.initialValue).unwrap_or(0.0), layout.real_start_off(i as u32)))
        .collect();
    ctx.emit_init_start_values(&starts)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// The attribute equations in C's `min`, `max`, `nominal`, `start` group order.
/// A start equation assigns `$START.<var>`, i.e. that variable's `start` attribute.
pub(super) fn bound_attr_equations(
    sim_code: &SimCode::SimCode,
) -> Vec<(Attr, &Arc<DAE::ComponentRef>, &Arc<DAE::Exp>)> {
    let mut out = Vec::new();
    for (attr, eqs) in [
        (Attr::Min, &sim_code.minValueEquations),
        (Attr::Max, &sim_code.maxValueEquations),
        (Attr::Nominal, &sim_code.nominalValueEquations),
        (Attr::Start, &sim_code.startValueEquations),
    ] {
        for eq in lst(eqs) {
            if let SimCode::SimEqSystem::SES_SIMPLE_ASSIGN { cref, exp, .. } = &**eq {
                out.push((attr, cref, exp));
            }
        }
    }
    out
}

/// What C's `_init.xml` records for an attribute, i.e. what
/// `SerializeInitXML.expString` serializes: a literal, and nothing else.
pub(super) fn literal_value(exp: &Option<Arc<DAE::Exp>>) -> Option<f64> {
    fn eval(e: &DAE::Exp) -> Option<f64> {
        use DAE::Exp as E;
        match e {
            E::ICONST { integer } => Some(*integer as f64),
            E::RCONST { real } => Some(real.into_inner()),
            E::BCONST { bool } => Some(*bool as u8 as f64),
            E::ENUM_LITERAL { index, .. } => Some(*index as f64),
            E::REDUCTION { expr, .. } => eval(expr),
            _ => None,
        }
    }
    exp.as_deref().and_then(eval)
}

/// Build `functionUpdateBoundVariableAttributes(SimData*)`. An attribute bound to a
/// parameter is not a constant, so the backend hands it over as an equation; only
/// here, after `functionParameters`, does it have a value. Every attribute is
/// evaluated (as C does) and left in the log region, whatever else it feeds.
pub(super) fn build_update_bound_attrs_fn(
    sim_code: &SimCode::SimCode,
    layout: &SimLayout,
    defaults: &[(u32, f64)],
    int_defaults: &[(u32, i32)],
    attr_targets: &HashMap<String, AttrTargets>,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut attrs: Vec<(Attr, Arc<DAE::Exp>, AttrTargets, u32, Option<SimSlot>)> = Vec::new();
    for (i, (attr, cref, exp)) in bound_attr_equations(sim_code).into_iter().enumerate() {
        let key = sim_cref_key(cref).ok().map(|k| k.strip_prefix("$START.").unwrap_or(&k).to_string());
        let targets = key.as_deref().and_then(|k| attr_targets.get(k)).cloned().unwrap_or_default();
        let var = match attr {
            Attr::Start => key.as_deref().and_then(|k| var_map.vars.get(k)).copied(),
            _ => None,
        };
        attrs.push((attr, exp.clone(), targets, layout.attr_log_off + i as u32 * 8, var));
    }
    let sim = sim_ctx(var_map);
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    ctx.emit_update_bound_attrs(defaults, int_defaults, &attrs)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionAttrDefaults(SimData*)`: the constant attribute defaults only, for
/// a solver built before initialization.
pub(super) fn build_attr_defaults_fn(
    defaults: &[(u32, f64)],
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut ctx = FnCtx::new_sim(sim_ctx(var_map), by_name, literals);
    ctx.emit_update_bound_attrs(defaults, &[], &[])?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionZeroCrossings(SimData*, gout)`: evaluate each crossing into
/// `gout` (see [`FnCtx::emit_zero_crossings`]).
pub(super) fn build_zero_crossings_fn(
    crossings: &[ZcInfo],
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let sim = SimCtx { zc_context: true, ..sim_ctx(var_map) };
    let mut ctx = FnCtx::new_sim_params(sim, by_name, literals, 2);
    ctx.emit_zero_crossings(crossings, 1)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionUpdateRelations(SimData*)`: C's `function_updateRelations(data,
/// 0)`, the exact recomputation of every `relations[]` entry.
pub(super) fn build_update_relations_fn(
    relations: &[Option<Arc<DAE::Exp>>],
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let sim = SimCtx { zc_context: true, ..sim_ctx(var_map) };
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    ctx.emit_update_relations(relations, var_map.relations_off)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionStoreDelayed(SimData*)` (C's `function_storeDelayed`): append
/// each `delay(...)` expression's current value to its ring buffer.
pub(super) fn build_store_delayed_fn(
    sim_code: &SimCode::SimCode,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let delayed: Vec<(i32, Arc<DAE::Exp>, Arc<DAE::Exp>, Arc<DAE::Exp>)> =
        lst(&sim_code.delayedExps.delayedExps)
            .map(|(i, (e, d, dmax))| (*i, e.clone(), d.clone(), dmax.clone()))
            .collect();
    let sim = sim_ctx(var_map);
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    ctx.emit_store_delayed(&delayed)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionInitDelay(SimData*)`: `rt_delay_init(n_delays, time)`, called at
/// init with `time == startTime`.
pub(super) fn build_init_delay_fn(n_delays: u32) -> we::Function {
    use we::Instruction as I;
    let mut f = we::Function::new([]);
    f.instruction(&I::I32Const(n_delays as i32));
    f.instruction(&I::LocalGet(0)); // SimData*
    f.instruction(&I::F64Load(crate::CodegenWasmJitFunctions::mem_arg(0, 3))); // time (TIME_OFF)
    f.instruction(&I::Call(rt_index("rt_delay_init").expect("rt_delay_init is a runtime builtin")));
    f.instruction(&I::End);
    f
}

/// The model's `spatialDistribution(...)` operators, lowest index first (the
/// backend collects them in reverse).
fn spatial_ops(sim_code: &SimCode::SimCode) -> Vec<SimCode::SpatialDistribution> {
    let mut ops: Vec<SimCode::SpatialDistribution> =
        lst(&sim_code.spatialInfo.spatialDistributions).cloned().collect();
    ops.sort_by_key(|sd| sd.index);
    ops
}

/// Build `functionStoreSpatialDistribution(SimData*)`; see [`FnCtx::emit_store_spatial`].
pub(super) fn build_store_spatial_fn(
    sim_code: &SimCode::SimCode,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let sim = sim_ctx(var_map);
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    ctx.emit_store_spatial(&spatial_ops(sim_code))?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionInitSpatialDistribution(SimData*)`; see [`FnCtx::emit_init_spatial`].
pub(super) fn build_init_spatial_fn(
    sim_code: &SimCode::SimCode,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let sim = sim_ctx(var_map);
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    ctx.emit_init_spatial(var_map.n_spatial, &spatial_ops(sim_code))?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Lower a single `SimEqSystem` into the current equation function.
pub(crate) fn lower_equation(
    ctx: &mut FnCtx,
    eq: &SimCode::SimEqSystem,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
) -> Result<()> {
    // C's `SIM_PROF_TICK_EQ` / `SIM_PROF_ACC_EQ` around a profiled block: every
    // equation under `all`, the linear and nonlinear systems under `blocks` — where
    // C's tick counts one call, its nonlinear block takes it back (the residual
    // calls count) and its linear one adds the setup call.
    let prof = ctx.sim.as_ref().and_then(|s| s.prof.clone());
    let clock = prof.as_ref().and_then(|p| p.block_clock(eq_index_of(eq)));
    if let Some(c) = clock {
        crate::CodegenWasmJitFunctions::emit_prof(ctx, clock, "rt_prof_tick")?;
        let all = prof.as_ref().is_some_and(|p| p.all());
        let ncall = match eq {
            SimCode::SimEqSystem::SES_NONLINEAR { .. } if !all => -1,
            SimCode::SimEqSystem::SES_LINEAR { .. } if !all => 1,
            _ => 0,
        };
        if ncall != 0 {
            ctx.emit(we::Instruction::I32Const(c as i32));
            ctx.emit(we::Instruction::I32Const(ncall));
            ctx.emit(we::Instruction::Call(rt_index("rt_prof_add_ncall")?));
        }
    }
    let _g = crate::CodegenWasmJitFunctions::PartGuard::new(format!("equation {}", eq_index_of(eq)));
    lower_equation_inner(ctx, eq, eq_index)?;
    crate::CodegenWasmJitFunctions::emit_prof(ctx, clock, "rt_prof_acc")
}
