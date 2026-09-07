//! Equation-list utilities: flattening, nested equations, parameter
//! bindings, assigned crefs, equation indices/kinds, parmod task graph.

use super::*;

/// Flatten a `list<list<SimEqSystem>>` (partitioned equations) to a flat Vec.
pub(super) fn flatten_eqs_ll(
    eqs: &List<List<Arc<SimCode::SimEqSystem>>>,
) -> Vec<Arc<SimCode::SimEqSystem>> {
    let mut out = Vec::new();
    for part in lst(eqs) {
        for e in lst(part) {
            out.push(e.clone());
        }
    }
    out
}

/// `+profiling`: the clock plan the instrumented code ticks and the report's
/// metadata. C reads both out of `_info.json` (`simulation_info_json.c`): every
/// equation in position order — which is index order — with a profile block for
/// each linear/nonlinear system under `blocks`, for every equation under `all`.
pub(super) fn prof_plan(
    sim_code: &SimCode::SimCode,
    mi: &SimCode::ModelInfo,
) -> Result<(Option<Arc<ProfPlan>>, Option<openmodelica_sim_meta::ProfInfo>)> {
    use openmodelica_sim_meta::{ProfEq, ProfFn, ProfInfo, ProfVar, SrcInfo};
    use openmodelica_util::Config;
    // C's `measure_time_flag` initializer, in `CodegenC`'s order.
    let level: u8 = if Config::profileHtml()? {
        5
    } else if Config::profileSome()? {
        1
    } else if Config::profileAll()? {
        2
    } else {
        return Ok((None, None));
    };
    let src_info = |i: &metamodelica::SourceInfo| SrcInfo {
        file: i.fileName.to_string(),
        line_start: i.lineNumberStart,
        col_start: i.columnNumberStart,
        line_end: i.lineNumberEnd,
        col_end: i.columnNumberEnd,
        read_only: i.isReadOnly,
    };
    let mut fn_index = HashMap::new();
    let mut functions = Vec::new();
    for (i, f) in lst(&mi.functions).enumerate() {
        use SimCodeFunction::Function::Function as F;
        let (name, info) = match &**f {
            F::FUNCTION { name, info, .. }
            | F::PARALLEL_FUNCTION { name, info, .. }
            | F::KERNEL_FUNCTION { name, info, .. }
            | F::EXTERNAL_FUNCTION { name, info, .. }
            | F::RECORD_CONSTRUCTOR { name, info, .. } => (name, info),
        };
        fn_index.insert(crate::CodegenWasmJitFunctions::mangle(name)?, i as u32);
        functions.push(ProfFn {
            // `SerializeModelInfo.serializePath`, which drops the `FULLYQUALIFIED`
            // wrapper without a leading delimiter: `MeasureTime.A.f`, not `.MeasureTime.A.f`.
            name: openmodelica_frontend_dump::AbsynUtil::pathString(name.clone(), arcstr::literal!("."), false, false)?
                .to_string(),
            info: src_info(info),
        });
    }
    // C's `info.id` is the variable's `_init.xml` value reference: one counter from
    // 1000 over `SerializeInitXML.modelVariables`' lists, the alias and sensitivity
    // variables included. The report lists `modelData`'s arrays instead, so an id is
    // not a position in it.
    let mut vr_of: HashMap<String, u32> = HashMap::new();
    let mut vr = 1000u32;
    for list in [
        &mi.vars.stateVars, &mi.vars.derivativeVars, &mi.vars.algVars, &mi.vars.discreteAlgVars,
        &mi.vars.realOptimizeConstraintsVars, &mi.vars.realOptimizeFinalConstraintsVars,
        &mi.vars.paramVars, &mi.vars.aliasVars,
        &mi.vars.intAlgVars, &mi.vars.intParamVars, &mi.vars.intAliasVars,
        &mi.vars.boolAlgVars, &mi.vars.boolParamVars, &mi.vars.boolAliasVars,
        &mi.vars.stringAlgVars, &mi.vars.stringParamVars, &mi.vars.stringAliasVars,
        &mi.vars.sensitivityVars,
    ] {
        for sv in lst(list) {
            vr_of.entry(cref_display(&sv.name)?).or_insert(vr);
            vr += 1;
        }
    }
    // C's `modelData` variable arrays, in `printModelInfo` order.
    let mut vars = Vec::new();
    for list in [
        &mi.vars.stateVars, &mi.vars.derivativeVars, &mi.vars.algVars, &mi.vars.discreteAlgVars, &mi.vars.paramVars,
        &mi.vars.intAlgVars, &mi.vars.intParamVars, &mi.vars.boolAlgVars, &mi.vars.boolParamVars,
        &mi.vars.stringAlgVars, &mi.vars.stringParamVars,
    ] {
        for sv in lst(list) {
            let name = cref_display(&sv.name)?;
            vars.push(ProfVar {
                id: vr_of.get(&name).copied().unwrap_or(0),
                name,
                comment: sv.comment.to_string(),
                info: src_info(&sv.source.info),
            });
        }
    }
    // Every equation the `_info.json` lists, by index; a system's defines are its
    // unknowns, an assignment's its left-hand side.
    let mut table: HashMap<i32, (bool, Vec<String>)> = HashMap::new();
    let mut err = None;
    let mut note = |e: &Arc<SimCode::SimEqSystem>| {
        use SimCode::SimEqSystem as E;
        let entry = match &**e {
            E::SES_LINEAR { lSystem, .. } => {
                lst(&lSystem.vars).map(|v| cref_display(&v.name)).collect::<Result<Vec<_>>>().map(|d| (true, d))
            }
            E::SES_NONLINEAR { nlSystem, .. } => {
                lst(&nlSystem.crefs).map(cref_display).collect::<Result<Vec<_>>>().map(|d| (true, d))
            }
            E::SES_SIMPLE_ASSIGN { cref, .. } | E::SES_SIMPLE_ASSIGN_CONSTRAINTS { cref, .. } => {
                cref_display(cref).map(|d| (false, vec![d]))
            }
            E::SES_ARRAY_CALL_ASSIGN { lhs, .. } => match &**lhs {
                DAE::Exp::CREF { componentRef, .. } => cref_display(componentRef).map(|d| (false, vec![d])),
                _ => Ok((false, Vec::new())),
            },
            _ => Ok((false, Vec::new())),
        };
        match entry {
            Ok(v) => {
                table.insert(eq_index_of(e), v);
            }
            Err(x) => err = Some(x),
        }
    };
    for list in [
        &sim_code.initialEquations, &sim_code.initialEquations_lambda0, &sim_code.removedInitialEquations,
        &sim_code.allEquations, &sim_code.startValueEquations, &sim_code.nominalValueEquations,
        &sim_code.minValueEquations, &sim_code.maxValueEquations, &sim_code.parameterEquations,
        &sim_code.algorithmAndEquationAsserts, &sim_code.inlineEquations, &sim_code.jacobianEquations,
    ] {
        for e in lst(list) {
            visit_nested_eqs(e, &mut note);
        }
    }
    drop(note);
    if let Some(x) = err {
        return Err(x);
    }
    let n = table.keys().max().map_or(1, |m| (*m).max(0) + 1) as usize;
    let mut equations = Vec::with_capacity(n);
    let mut blocks = HashMap::new();
    // Under `all` C's block 0 exists but belongs to no equation.
    let all = level & 2 != 0;
    let mut block_eqs: Vec<u32> = if all { vec![0] } else { Vec::new() };
    for i in 0..n {
        let (system, defines) = table.get(&(i as i32)).cloned().unwrap_or_default();
        equations.push(ProfEq { id: i as u32, defines });
        // `readEquations`: a block for each system under `blocks`, for every
        // equation but the dummy under `all`.
        if i > 0 && (all || (level & 1 != 0 && system)) {
            blocks.insert(i as i32, block_eqs.len() as u32);
            block_eqs.push(i as u32);
        }
    }
    let plan = ProfPlan { level, n_functions: functions.len() as u32, n_blocks: block_eqs.len() as u32, fn_index, blocks };
    Ok((Some(Arc::new(plan)), Some(ProfInfo { level, functions, vars, equations, blocks: block_eqs })))
}

/// `eqs` with everything [`visit_nested_eqs`] reaches appended.
pub(super) fn eqs_with_nested(eqs: &[Arc<SimCode::SimEqSystem>]) -> Vec<Arc<SimCode::SimEqSystem>> {
    let mut out = Vec::with_capacity(eqs.len());
    for e in eqs {
        visit_nested_eqs(e, &mut |i| out.push(i.clone()));
    }
    out
}

/// Build one equation function (`SimData* -> ()`), lowering each equation in
/// order. Unsupported equation kinds (systems, array assigns) fail loudly so a
/// model that needs them is rejected rather than silently mis-simulated.
/// Collect parameter binding assignments (`cref := initialValue`) from all
/// parameter `SimVar`s that have a binding, in declaration order.
pub(super) fn collect_param_bindings(
    vars: &SimCodeVar::SimVars,
    computed: &std::collections::HashSet<String>,
) -> Vec<(Arc<DAE::ComponentRef>, Arc<DAE::Exp>)> {
    let mut out = Vec::new();
    for p in lst(&vars.paramVars)
        .chain(lst(&vars.intParamVars))
        .chain(lst(&vars.boolParamVars))
        .chain(lst(&vars.stringParamVars))
    {
        // A parameter an equation computes must not also be assigned from its binding
        // here: the prelude runs before both equation lists, so the binding would see
        // dependencies that are still 0 (or a null handle). A *constant* binding reads
        // nothing, so it is stored regardless — C's `setAllParamsToStart`.
        if let Some(v) = &p.initialValue {
            if !is_const_exp(v) && sim_cref_key(&p.name).map(|k| is_computed(&k, computed)).unwrap_or(false) {
                continue;
            }
            out.push((p.name.clone(), v.clone()));
        }
    }
    out
}

/// A literal the `_init.xml` would carry verbatim as a `start` attribute.
fn is_const_exp(e: &DAE::Exp) -> bool {
    matches!(
        e,
        DAE::Exp::ICONST { .. }
            | DAE::Exp::RCONST { .. }
            | DAE::Exp::BCONST { .. }
            | DAE::Exp::SCONST { .. }
            | DAE::Exp::ENUM_LITERAL { .. }
    )
}

/// Whether an equation list assigns `key`, directly or as one element of its array:
/// the `SimVar`s are scalarized (`ts[1]`, `layer[1][1][1][1]`), an array assign names
/// the whole `ts`. `sim_cref_key` spells one bracket pair per subscript, so strip
/// every rank, not just the last.
fn is_computed(key: &str, computed: &std::collections::HashSet<String>) -> bool {
    let mut key = key;
    loop {
        if computed.contains(key) {
            return true;
        }
        let Some(i) = key.strip_suffix(']').and_then(|k| k.rfind('[')) else { return false };
        key = &key[..i];
    }
}

/// Keys of the crefs a `SimEqSystem` list assigns, a system's iteration
/// variables included.
pub(super) fn assigned_cref_keys(eqs: &[Arc<SimCode::SimEqSystem>]) -> std::collections::HashSet<String> {
    use SimCode::SimEqSystem as E;
    let mut set = std::collections::HashSet::new();
    let mut add = |cr: &DAE::ComponentRef| {
        if let Ok(k) = sim_cref_key(cr) {
            set.insert(k);
        }
    };
    for eq in eqs {
        match &**eq {
            E::SES_SIMPLE_ASSIGN { cref, .. }
            | E::SES_SIMPLE_ASSIGN_CONSTRAINTS { cref, .. }
            | E::SES_FOR_LOOP { cref, .. } => add(cref),
            E::SES_ARRAY_CALL_ASSIGN { lhs, .. } => {
                if let DAE::Exp::CREF { componentRef, .. } = &**lhs {
                    add(componentRef);
                }
            }
            E::SES_LINEAR { lSystem, alternativeTearing, .. } => {
                for s in std::iter::once(lSystem).chain(alternativeTearing.iter()) {
                    for v in lst(&s.vars) {
                        add(&v.name);
                    }
                }
            }
            E::SES_NONLINEAR { nlSystem, alternativeTearing, .. } => {
                for s in std::iter::once(nlSystem).chain(alternativeTearing.iter()) {
                    for c in lst(&s.crefs) {
                        add(c);
                    }
                }
            }
            E::SES_MIXED { discVars, .. } => {
                for v in lst(discVars) {
                    add(&v.name);
                }
            }
            E::SES_ALGORITHM { statements, .. } | E::SES_INVERSE_ALGORITHM { statements, .. } => {
                let defs = openmodelica_frontend_base::Expression::extractUniqueCrefsFromStatmentS(
                    statements.clone(),
                );
                if let Ok((defs, _)) = defs {
                    for c in lst(&defs) {
                        add(c);
                    }
                }
            }
            _ => {}
        }
    }
    set
}

/// `daeModeData.daeEquations` flattened over its partitions, each equation paired with
/// the `EVAL_*` stage mask it runs in. Mirrors C's `equationNames_` for
/// `contextDAEmode`: an equation with no evaluation attributes inherits the preceding
/// one's mask (C leaves `evalStages` unassigned there), starting from every stage.
pub(super) fn dae_residual_equations(dae: &SimCode::DaeModeData) -> Vec<(Arc<SimCode::SimEqSystem>, u32)> {
    use openmodelica_sim_meta::driver::eval_stage as stage;
    let all = stage::DYNAMIC | stage::ALGEBRAIC | stage::ZEROCROSS | stage::DISCRETE;
    let mut stages = all;
    let mut out = Vec::new();
    for part in lst(&dae.daeEquations) {
        for eq in lst(part) {
            let mut discrete = false;
            if let Some(attr) = eq_attr_of(eq) {
                let ev = &attr.evalStages;
                stages = (ev.dynamicEval as u32) * stage::DYNAMIC
                    | (ev.algebraicEval as u32) * stage::ALGEBRAIC
                    | (ev.zerocrossEval as u32) * stage::ZEROCROSS
                    | (ev.discreteEval as u32) * stage::DISCRETE;
                discrete = matches!(attr.kind, openmodelica_backend_types::BackendDAE::EquationKind::DISCRETE_EQUATION);
            }
            // A discrete-kind equation runs in the discrete stage only.
            let stages = if discrete { stages & stage::DISCRETE } else { stages };
            if stages != 0 {
                out.push((eq.clone(), stages));
            }
        }
    }
    out
}

/// `SimCodeUtil.eqInfo`.
pub(super) fn eq_info(eq: &SimCode::SimEqSystem) -> Option<&metamodelica::SourceInfo> {
    use SimCode::SimEqSystem as E;
    match eq {
        E::SES_RESIDUAL { source, .. }
        | E::SES_FOR_RESIDUAL { source, .. }
        | E::SES_GENERIC_RESIDUAL { source, .. }
        | E::SES_SIMPLE_ASSIGN { source, .. }
        | E::SES_SIMPLE_ASSIGN_CONSTRAINTS { source, .. }
        | E::SES_ARRAY_CALL_ASSIGN { source, .. }
        | E::SES_RESIZABLE_ASSIGN { source, .. }
        | E::SES_GENERIC_ASSIGN { source, .. }
        | E::SES_ENTWINED_ASSIGN { source, .. }
        | E::SES_IFEQUATION { source, .. }
        | E::SES_WHEN { source, .. }
        | E::SES_FOR_LOOP { source, .. }
        | E::SES_FOR_EQUATION { source, .. } => Some(&source.info),
        _ => None,
    }
}

/// The equation's `BackendDAE.EquationAttributes`, absent for the few systems that
/// carry none (`SES_ALIAS` and friends).
fn eq_attr_of(eq: &SimCode::SimEqSystem) -> Option<&openmodelica_backend_types::BackendDAE::EquationAttributes> {
    use SimCode::SimEqSystem as E;
    match eq {
        E::SES_RESIDUAL { eqAttr, .. }
        | E::SES_FOR_RESIDUAL { eqAttr, .. }
        | E::SES_GENERIC_RESIDUAL { eqAttr, .. }
        | E::SES_SIMPLE_ASSIGN { eqAttr, .. }
        | E::SES_SIMPLE_ASSIGN_CONSTRAINTS { eqAttr, .. }
        | E::SES_ARRAY_CALL_ASSIGN { eqAttr, .. }
        | E::SES_RESIZABLE_ASSIGN { eqAttr, .. }
        | E::SES_GENERIC_ASSIGN { eqAttr, .. }
        | E::SES_ENTWINED_ASSIGN { eqAttr, .. }
        | E::SES_IFEQUATION { eqAttr, .. }
        | E::SES_ALGORITHM { eqAttr, .. }
        | E::SES_INVERSE_ALGORITHM { eqAttr, .. }
        | E::SES_LINEAR { eqAttr, .. }
        | E::SES_NONLINEAR { eqAttr, .. }
        | E::SES_MIXED { eqAttr, .. }
        | E::SES_WHEN { eqAttr, .. }
        | E::SES_FOR_LOOP { eqAttr, .. }
        | E::SES_FOR_EQUATION { eqAttr, .. }
        | E::SES_ALGEBRAIC_SYSTEM { eqAttr, .. } => Some(eqAttr),
        E::SES_ALIAS { .. } => None,
    }
}

/// Units of `evaluateDAEResiduals(SimData*, stage)`. C tests `evalStages &
/// currentEvalStage` against a per-equation assignment; here the mask is a
/// constant, so the guard is a single `and`/`if`.
pub(super) fn dae_units(eqs: &[(Arc<SimCode::SimEqSystem>, u32)]) -> Vec<EqUnit<'_>> {
    eqs.iter().map(|(eq, stages)| EqUnit::Eq(eq, Some(*stages))).collect()
}

pub(super) fn generic_call_index(call: &SimCode::SimGenericCall) -> i32 {
    use SimCode::SimGenericCall as G;
    match call {
        G::SINGLE_GENERIC_CALL { index, .. }
        | G::IF_GENERIC_CALL { index, .. }
        | G::WHEN_GENERIC_CALL { index, .. } => *index,
    }
}

pub(crate) fn eq_kind_name(eq: &SimCode::SimEqSystem) -> &'static str {
    use SimCode::SimEqSystem as E;
    match eq {
        E::SES_RESIDUAL { .. } => "SES_RESIDUAL",
        E::SES_FOR_RESIDUAL { .. } => "SES_FOR_RESIDUAL",
        E::SES_GENERIC_RESIDUAL { .. } => "SES_GENERIC_RESIDUAL",
        E::SES_SIMPLE_ASSIGN { .. } => "SES_SIMPLE_ASSIGN",
        E::SES_SIMPLE_ASSIGN_CONSTRAINTS { .. } => "SES_SIMPLE_ASSIGN_CONSTRAINTS",
        E::SES_ARRAY_CALL_ASSIGN { .. } => "SES_ARRAY_CALL_ASSIGN",
        E::SES_LINEAR { .. } => "SES_LINEAR",
        E::SES_NONLINEAR { .. } => "SES_NONLINEAR",
        E::SES_MIXED { .. } => "SES_MIXED",
        E::SES_WHEN { .. } => "SES_WHEN",
        E::SES_IFEQUATION { .. } => "SES_IFEQUATION",
        E::SES_ALGORITHM { .. } => "SES_ALGORITHM",
        E::SES_INVERSE_ALGORITHM { .. } => "SES_INVERSE_ALGORITHM",
        E::SES_RESIZABLE_ASSIGN { .. } => "SES_RESIZABLE_ASSIGN",
        E::SES_GENERIC_ASSIGN { .. } => "SES_GENERIC_ASSIGN",
        E::SES_ENTWINED_ASSIGN { .. } => "SES_ENTWINED_ASSIGN",
        E::SES_FOR_LOOP { .. } => "SES_FOR_LOOP",
        E::SES_FOR_EQUATION { .. } => "SES_FOR_EQUATION",
        E::SES_ALIAS { .. } => "SES_ALIAS",
        E::SES_ALGEBRAIC_SYSTEM { .. } => "SES_ALGEBRAIC_SYSTEM",
    }
}

/// Whether any equation, at any nesting depth, is a `SES_LINEAR` C would solve
/// with `method = 1`.
pub(super) fn has_method1_linear(sim_code: &SimCode::SimCode) -> bool {
    fn walk(e: &Arc<SimCode::SimEqSystem>) -> bool {
        use SimCode::SimEqSystem as E;
        match &**e {
            E::SES_LINEAR { lSystem, alternativeTearing, .. } => {
                lSystem.jacobianMatrix.is_some()
                    || alternativeTearing.as_ref().is_some_and(|a| a.jacobianMatrix.is_some())
                    || lst(&lSystem.residual).any(walk)
            }
            E::SES_NONLINEAR { nlSystem, alternativeTearing, .. } => {
                lst(&nlSystem.eqs).any(walk)
                    || alternativeTearing.as_ref().is_some_and(|a| lst(&a.eqs).any(walk))
            }
            E::SES_MIXED { cont, discEqs, .. } => walk(cont) || lst(discEqs).any(walk),
            E::SES_IFEQUATION { ifbranches, elsebranch, .. } => {
                lst(ifbranches).any(|(_, eqs)| lst(eqs).any(walk)) || lst(elsebranch).any(walk)
            }
            _ => false,
        }
    }
    let lists = [
        &sim_code.allEquations,
        &sim_code.initialEquations,
        &sim_code.initialEquations_lambda0,
        &sim_code.parameterEquations,
        &sim_code.removedInitialEquations,
        &sim_code.removedEquations,
        &sim_code.startValueEquations,
        &sim_code.equationsForZeroCrossings,
        &sim_code.inlineEquations,
    ];
    lists.iter().any(|l| lst(l).any(walk))
        || lst(&sim_code.odeEquations).chain(lst(&sim_code.algebraicEquations)).any(|p| lst(p).any(walk))
        || sim_code.daeModeData.as_ref().is_some_and(|d| lst(&d.daeEquations).any(|p| lst(p).any(walk)))
}

/// Index `e` by its own index and recurse into nested equations (torn-system
/// inner constraints, mixed cont/disc parts, if-branches), which an `SES_ALIAS`
/// may target but which the top-level lists don't reach.
pub(super) fn index_eq_recursive(e: &Arc<SimCode::SimEqSystem>, idx: &mut HashMap<i32, Arc<SimCode::SimEqSystem>>) {
    use SimCode::SimEqSystem as E;
    let key = eq_index_of(e);
    if key >= 0 {
        idx.entry(key).or_insert_with(|| e.clone());
    }
    match &**e {
        E::SES_LINEAR { lSystem, alternativeTearing, .. } => {
            let mut index_lin = |s: &Arc<SimCode::LinearSystem>, idx: &mut _| {
                for inner in lst(&s.residual) {
                    index_eq_recursive(inner, idx);
                }
                for (_, _, inner) in lst(&s.simJac) {
                    index_eq_recursive(inner, idx);
                }
            };
            index_lin(lSystem, idx);
            if let Some(alt) = alternativeTearing {
                index_lin(alt, idx);
            }
        }
        E::SES_NONLINEAR { nlSystem, alternativeTearing, .. } => {
            for inner in lst(&nlSystem.eqs) {
                index_eq_recursive(inner, idx);
            }
            if let Some(alt) = alternativeTearing {
                for inner in lst(&alt.eqs) {
                    index_eq_recursive(inner, idx);
                }
            }
        }
        E::SES_MIXED { cont, discEqs, .. } => {
            index_eq_recursive(cont, idx);
            for inner in lst(discEqs) {
                index_eq_recursive(inner, idx);
            }
        }
        E::SES_IFEQUATION { ifbranches, elsebranch, .. } => {
            for (_, eqs) in lst(ifbranches) {
                for inner in lst(eqs) {
                    index_eq_recursive(inner, idx);
                }
            }
            for inner in lst(elsebranch) {
                index_eq_recursive(inner, idx);
            }
        }
        _ => {}
    }
}

/// The `index` of a `SimEqSystem` (best-effort; systems without a top-level
/// index report -1).
/// The `--parmodauto` task graph C's `SerializeTaskSystemInfo` writes to
/// `<model>_ode.json` and `om_pm_model.cpp` loads: one task per ODE equation with
/// what it defines and uses, and an edge from every earlier task defining
/// something a later one uses (`TaskSystem_v2::add_node`). Reads of a dense
/// linear system's `A`/`b` count as uses too; C's loader only sees a torn system's
/// inner equations.
pub(super) fn parmod_info(ode_eqs: &[Arc<SimCode::SimEqSystem>]) -> Result<openmodelica_sim_meta::ParmodInfo> {
    use SimCode::SimEqSystem as E;
    use openmodelica_frontend_base::{ComponentReference, Expression};
    fn name(cref: &Arc<DAE::ComponentRef>) -> Result<String> {
        Ok(ComponentReference::crefStr(cref.clone())?.to_string())
    }
    fn uses(exp: &Arc<DAE::Exp>) -> Result<Vec<String>> {
        lst(&Expression::extractUniqueCrefsFromExpDerPreStart(exp.clone(), true)?).map(name).collect()
    }
    fn unsupported(index: i32, what: &str) -> &'static str {
        Box::leak(format!("parmodauto: equation {index}: {what}").into_boxed_str())
    }
    // C's `load_simple_assign_check_local_define` / `load_simple_residual`.
    fn inner(eq: &E, lhs: &mut HashSet<String>, rhs: &mut HashSet<String>) -> Result<()> {
        let (define, exp) = match eq {
            E::SES_SIMPLE_ASSIGN { cref, exp, .. }
            | E::SES_SIMPLE_ASSIGN_CONSTRAINTS { cref, exp, .. }
            | E::SES_FOR_LOOP { cref, exp, .. } => (Some(name(cref)?), exp),
            E::SES_ARRAY_CALL_ASSIGN { lhs, exp, .. } => (Some(name(&Expression::expCref(lhs.clone())?)?), exp),
            E::SES_RESIDUAL { exp, .. } => (None, exp),
            other => return Err(unsupported(eq_index_of(other), "internal equation type not yet handled")),
        };
        match define {
            Some(d) => {
                lhs.insert(d);
                for u in uses(exp)? {
                    if !lhs.contains(&u) {
                        rhs.insert(u);
                    }
                }
            }
            None => rhs.extend(uses(exp)?),
        }
        Ok(())
    }
    let sorted = |eqs: &List<Arc<E>>| -> Vec<Arc<E>> {
        let mut v: Vec<Arc<E>> = lst(eqs).cloned().collect();
        v.sort_by_key(|e| eq_index_of(e));
        v
    };
    let mut nodes: Vec<(i32, HashSet<String>, HashSet<String>)> = Vec::new();
    for eq in ode_eqs {
        let index = eq_index_of(eq);
        let mut lhs = HashSet::new();
        let mut rhs = HashSet::new();
        match &**eq {
            E::SES_RESIDUAL { exp, .. } => rhs.extend(uses(exp)?),
            E::SES_SIMPLE_ASSIGN { cref, exp, .. }
            | E::SES_SIMPLE_ASSIGN_CONSTRAINTS { cref, exp, .. }
            | E::SES_FOR_LOOP { cref, exp, .. } => {
                lhs.insert(name(cref)?);
                rhs.extend(uses(exp)?);
            }
            E::SES_ARRAY_CALL_ASSIGN { lhs: l, exp, .. } => {
                lhs.insert(name(&Expression::expCref(l.clone())?)?);
                rhs.extend(uses(exp)?);
            }
            E::SES_ALGORITHM { statements, .. } | E::SES_INVERSE_ALGORITHM { statements, .. } => {
                let (defs, used) = Expression::extractUniqueCrefsFromStatmentS(statements.clone())?;
                lhs.extend(lst(&defs).map(name).collect::<Result<Vec<_>>>()?);
                rhs.extend(lst(&used).map(name).collect::<Result<Vec<_>>>()?);
            }
            E::SES_LINEAR { lSystem, alternativeTearing: None, .. } => {
                for v in lst(&lSystem.vars) {
                    lhs.insert(name(&v.name)?);
                }
                for e in sorted(&lSystem.residual) {
                    inner(&e, &mut lhs, &mut rhs)?;
                }
                for b in lst(&lSystem.beqs) {
                    rhs.extend(uses(b)?.into_iter().filter(|u| !lhs.contains(u)));
                }
                for (_, _, cell) in lst(&lSystem.simJac) {
                    if let E::SES_RESIDUAL { exp, .. } = &**cell {
                        rhs.extend(uses(exp)?.into_iter().filter(|u| !lhs.contains(u)));
                    }
                }
            }
            E::SES_NONLINEAR { nlSystem, alternativeTearing: None, .. } => {
                for c in lst(&nlSystem.crefs) {
                    lhs.insert(name(c)?);
                }
                for e in sorted(&nlSystem.eqs) {
                    inner(&e, &mut lhs, &mut rhs)?;
                }
            }
            E::SES_LINEAR { .. } | E::SES_NONLINEAR { .. } => {
                return Err(unsupported(index, "dynamic tearing is not supported"));
            }
            E::SES_WHEN { .. } => return Err(unsupported(index, "equation type not yet handled: when")),
            E::SES_IFEQUATION { .. } => return Err(unsupported(index, "equation type not yet handled: if-equation")),
            E::SES_MIXED { .. } => return Err(unsupported(index, "equation type not yet handled: container")),
            E::SES_ALIAS { .. } => return Err(unsupported(index, "equation type not yet handled: alias")),
            _ => return Err(unsupported(index, "equation type not yet handled")),
        }
        nodes.push((index, lhs, rhs));
    }
    let mut tasks = Vec::with_capacity(nodes.len());
    for (j, (index, _, rhs)) in nodes.iter().enumerate() {
        let parents: Vec<u32> = nodes[..j]
            .iter()
            .enumerate()
            .filter(|(_, (_, lhs, _))| rhs.iter().any(|u| lhs.contains(u)))
            .map(|(i, _)| i as u32)
            .collect();
        tasks.push(openmodelica_sim_meta::ParmodTask { eq_index: *index, parents });
    }
    Ok(openmodelica_sim_meta::ParmodInfo { tasks })
}

pub(super) fn eq_index_of(eq: &SimCode::SimEqSystem) -> i32 {
    use SimCode::SimEqSystem as E;
    match eq {
        E::SES_RESIDUAL { index, .. }
        | E::SES_FOR_RESIDUAL { index, .. }
        | E::SES_GENERIC_RESIDUAL { index, .. }
        | E::SES_SIMPLE_ASSIGN { index, .. }
        | E::SES_SIMPLE_ASSIGN_CONSTRAINTS { index, .. }
        | E::SES_ARRAY_CALL_ASSIGN { index, .. }
        | E::SES_RESIZABLE_ASSIGN { index, .. }
        | E::SES_GENERIC_ASSIGN { index, .. }
        | E::SES_ENTWINED_ASSIGN { index, .. }
        | E::SES_IFEQUATION { index, .. }
        | E::SES_ALGORITHM { index, .. }
        | E::SES_INVERSE_ALGORITHM { index, .. }
        | E::SES_MIXED { index, .. }
        | E::SES_WHEN { index, .. }
        | E::SES_ALGEBRAIC_SYSTEM { index, .. }
        | E::SES_FOR_LOOP { index, .. } => *index,
        // Torn systems carry their index inside the system record, not as a
        // top-level field; an `SES_ALIAS` can point at the whole system.
        E::SES_LINEAR { lSystem, .. } => lSystem.index,
        E::SES_NONLINEAR { nlSystem, .. } => nlSystem.index,
        _ => -1,
    }
}

/// An empty function body, valid for any void signature. Used for the optional
/// equation functions (`initSample`, `functionZeroCrossings`,
/// `functionStateSetJacobians`, `functionInitialEquations_lambda0`) when a model
/// lacks that feature, so the model still *exports* every driver entry point. The
/// standalone `wasm-merge` (and the interactive shared table) then always resolve
/// them; the shared driver only calls one when the corresponding metadata count is
/// nonzero, so the stub is never entered.
pub(crate) fn empty_eqfn() -> we::Function {
    let mut f = we::Function::new([]);
    f.instruction(&we::Instruction::End);
    f
}
