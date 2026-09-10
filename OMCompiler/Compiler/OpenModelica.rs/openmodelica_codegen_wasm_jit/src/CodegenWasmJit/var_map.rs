//! The variable->slot map (`SimVarMap`), scalarization of array variables,
//! array/const groups, and the result-variable list.

use super::*;

/// Byte offset of `time` within `SimData`.
pub(super) const TIME_OFF: u32 = 0;

/// Byte offset of the first real variable (`realVars[0]`, a state).
pub(super) const REAL_OFF: u32 = 8;

/// The data the equation-function lowering needs to resolve component
/// references: the cref->slot map and the per-variable start expressions.
#[derive(Clone)]
pub(crate) struct SimVarMap {
    /// Shared with every [`SimCtx`] rather than copied per generated function, so
    /// filled through `Arc::make_mut` (single owner until emission starts).
    pub(crate) vars: Arc<HashMap<String, SimSlot>>,
    pub(super) starts: Arc<HashMap<String, Option<Arc<DAE::Exp>>>>,
    /// State cref key -> its start-value slot; when present, `$START.<key>` reads the
    /// slot instead of the inline expression.
    pub(super) start_slots: Arc<HashMap<String, u32>>,
    /// Finalized array-variable groups (base cref key -> contiguous slot range).
    pub(super) array_groups: Arc<HashMap<String, ArrayGroup>>,
    /// The arrays that are not one contiguous range (see `ScatterGroup`).
    pub(super) scatter_groups: Arc<HashMap<String, ScatterGroup>>,
    /// `varKind = CONST` variables own no `SimData` slot: a reference is the
    /// binding literal, as in C's `varArrayNameValues`. `const_groups` is the
    /// `array_groups` counterpart, `const_acc` its transient accumulator.
    pub(super) consts: Arc<HashMap<String, Arc<DAE::Exp>>>,
    pub(super) const_groups: Arc<HashMap<String, ConstGroup>>,
    const_acc: HashMap<String, Vec<(Vec<i32>, Arc<DAE::Exp>, WTy)>>,
    /// External object cref key -> the mangled name of its class's destructor.
    pub(super) extobj_dtors: Arc<HashMap<String, String>>,
    /// Transient accumulator: base cref key -> the scalarized elements seen.
    /// Finalized into `array_groups` / `scatter_groups` at the end of
    /// [`build_var_map`].
    pub(super) array_acc: HashMap<String, Vec<AccElem>>,
    /// `SimData` byte offset of the `terminate` flag (see [`SimLayout`]).
    pub(super) terminate_off: u32,
    pub(super) terminal_off: u32,
    pub(super) initial_off: u32,
    /// `SimData` byte offset of the fired `terminate`'s message + source position.
    pub(super) term_info_off: u32,
    /// `SimData` byte offset of the nonlinear-solver failure flag (see [`SimLayout`]).
    pub(super) nls_fail_off: u32,
    /// `SES_NONLINEAR` system index -> its `rt_solve_nls` job. Filled by
    /// [`collect_nls_jobs`] before the equation functions are lowered.
    pub(super) nls_jobs: Arc<HashMap<i32, NlsJob>>,
    /// `SimGenericCall` index -> the shared for-loop body (`generic_loop_calls`).
    pub(super) generic_calls: Arc<HashMap<i32, SimCode::SimGenericCall>>,
    /// Number of `sample(...)` time events (see [`SampleInfo`]).
    pub(super) n_samples: u32,
    /// `SimData` byte offset of the per-sample `active` flags (`SimLayout`).
    pub(super) sample_active_off: u32,
    /// `SimData` byte offset of the held relation values (`SimLayout::relations_off`).
    pub(super) relations_off: u32,
    /// `SimData` byte offset of the relation-evaluation-mode flag.
    pub(super) rel_fresh_off: u32,
    /// `SimData` byte offset of the held relation snapshot (`SimLayout::stored_rel_off`).
    pub(super) stored_rel_off: u32,
    /// `SimData` byte offset of `relationsPre` (`SimLayout::relations_pre_off`).
    pub(super) relations_pre_off: u32,
    /// Number of indexed relations (bounds the `relations[]` region).
    pub(super) n_relations: u32,
    /// `SimData` byte offset of the held math-event values (`mathEventsValuePre`).
    pub(super) mathevents_off: u32,
    /// Number of math-event slots (bounds the `mathEventsValuePre` region).
    pub(super) n_mathevents: u32,
    /// `SimData` byte offset of the homotopy parameter lambda (`SimLayout`).
    pub(super) lambda_off: u32,
    /// C's `homotopyMethod` code (`SimLayout::homotopy_method`).
    pub(super) homotopy_method: u8,
    /// `SimCtx::old_real`.
    pub(super) old_real: Option<(u32, u32)>,
    /// `SimData` byte offset of the zero-crossing hysteresis tolerance (`SimCtx::zctol_off`).
    pub(super) zctol_off: u32,
    /// `SimData` byte offset of `zeroCrossingsPre` (`SimLayout::zc_pre_off`).
    pub(super) zc_pre_off: u32,
    /// `SimData` byte offset of the `$_clkfire` flags (`SimLayout::clock_fire_off`).
    pub(super) clock_fire_off: u32,
    /// Number of `delay(...)` expression buffers (`delayedExps.maxDelayedIndex + 1`).
    pub(super) n_delays: u32,
    /// Number of `spatialDistribution(...)` operators (`spatialInfo.maxIndex + 1`).
    pub(super) n_spatial: u32,
    /// `+profiling`'s clock plan (`SimCtx::prof`).
    pub(super) prof: Option<Arc<ProfPlan>>,
}

/// C's `crefStrXml`: the display name `_init.xml` carries into `modelData`'s
/// `info.name`, and with it the result file. `$DER` / `$PRE` qualifiers print as
/// `der(...)` / `pre(...)`, nesting included (`$DER.$DER.x` -> `der(der(x))`).
pub(crate) fn cref_display(cr: &Arc<DAE::ComponentRef>) -> Result<String> {
    use DAE::ComponentRef as C;
    Ok(match &**cr {
        C::CREF_QUAL { ident, componentRef, .. } if &**ident == "$DER" => {
            format!("der({})", cref_display(componentRef)?)
        }
        C::CREF_QUAL { ident, componentRef, .. } if &**ident == "$PRE" => {
            format!("pre({})", cref_display(componentRef)?)
        }
        C::CREF_QUAL { componentRef, .. } => format!(
            "{}.{}",
            ComponentReferenceBasics::printComponentRefStr(ComponentReferenceBasics::crefFirstCref(
                cr.clone()
            )?)?,
            cref_display(componentRef)?
        ),
        _ => ComponentReferenceBasics::printComponentRefStr(cr.clone())?.to_string(),
    })
}

/// C's `shouldFilterOutput`: protected variables and `HideResult=true`, each
/// switched back on by its own simflag.
fn filter_bits(sv: &SimCodeVar::SimVar) -> u8 {
    let mut f = 0;
    if sv.isProtected {
        f |= var_filter::PROTECTED;
        if sv.isEncrypted {
            f |= var_filter::ENCRYPTED;
        }
    }
    if sv.hideResult == Some(true) {
        f |= var_filter::HIDE_RESULT;
    }
    f
}

/// In the result file with no simflag asked for it — the `-override` reachable set.
fn is_result_output(sv: &SimCodeVar::SimVar) -> bool {
    filter_bits(sv) == 0
}

/// Resolve `simulate(..., variableFilter=)` — C's `initializeOutputFilter`, which
/// filters every name that does not match `^(<filter>)$`. C matches per run; the
/// runtimes have no regex engine, so it is settled here into
/// [`var_filter::FILTERED`], protected variables included (`-emit_protected`
/// can reach them). It walks the variable and *alias* arrays only, so a plain
/// parameter is never filtered.
pub(super) fn apply_variable_filter(result_vars: &mut [ResultVar], filter: &str) {
    if filter == ".*" || filter.is_empty() {
        return;
    }
    let Ok(re) = openmodelica_util::System::Regex::new(&format!("^({filter})$")) else {
        eprintln!("Failed to compile regular expression: {filter}. Defaulting to outputting all variables.");
        return;
    };
    for v in result_vars.iter_mut() {
        let is_param = matches!(v.kind, ResultKind::Param { .. }) && v.filter & var_filter::ALIAS == 0;
        if !matches!(v.kind, ResultKind::Time) && !is_param && !re.is_match(&v.name) {
            v.filter |= var_filter::FILTERED;
        }
    }
}

/// The Modelica type of a variable, through subtype and array wrappers.
fn var_ty(ty: &DAE::Type) -> VarTy {
    match ty {
        DAE::Type::T_INTEGER { .. } | DAE::Type::T_ENUMERATION { .. } => VarTy::Integer,
        DAE::Type::T_BOOL { .. } => VarTy::Boolean,
        DAE::Type::T_STRING { .. } => VarTy::String,
        DAE::Type::T_SUBTYPE_BASIC { complexType, .. } => var_ty(complexType),
        DAE::Type::T_ARRAY { ty, .. } => var_ty(ty),
        _ => VarTy::Real,
    }
}

fn is_boolean_type(ty: &DAE::Type) -> bool {
    match ty {
        DAE::Type::T_BOOL { .. } => true,
        DAE::Type::T_SUBTYPE_BASIC { complexType, .. } => is_boolean_type(complexType),
        DAE::Type::T_ARRAY { ty, .. } => is_boolean_type(ty),
        _ => false,
    }
}

/// Literal names of an enumeration type; the stored value is the 1-based index
/// into these.
fn enumeration_names(ty: &DAE::Type) -> Option<Vec<String>> {
    match ty {
        DAE::Type::T_ENUMERATION { names, .. } => Some(lst(names).map(|n| n.to_string()).collect()),
        DAE::Type::T_SUBTYPE_BASIC { complexType, .. } => enumeration_names(complexType),
        DAE::Type::T_ARRAY { ty, .. } => enumeration_names(ty),
        _ => None,
    }
}

/// Map a display name ([`cref_display`], so a derivative already reads `der(x)`)
/// to the name it carries in the result file, or `None` to drop it. `$`-prefixed
/// names are backend-internal auxiliaries (`$cse*`, `$whenCondition*`, …) and are
/// not output.
/// C's `time_unvarying`: a variable a literal parameter equation assigns is
/// computed once at initialization, so the `.mat` stores it with the parameters
/// (`CodegenC.functionUpdateBoundParameters`, `Expression.isSimpleLiteralValue`).
pub(super) fn mark_unvarying(result_vars: &mut [ResultVar], param_eqs: &[Arc<SimCode::SimEqSystem>]) -> Result<()> {
    let mut literal: HashSet<String> = HashSet::new();
    for eq in param_eqs {
        if let SimCode::SimEqSystem::SES_SIMPLE_ASSIGN { cref, exp, .. } = &**eq
            && matches!(
                &**exp,
                DAE::Exp::ICONST { .. } | DAE::Exp::RCONST { .. } | DAE::Exp::BCONST { .. } | DAE::Exp::ENUM_LITERAL { .. }
            )
            && let Some(name) = result_name(&cref_display(cref)?)
        {
            literal.insert(name);
        }
    }
    for v in result_vars.iter_mut() {
        if matches!(v.kind, ResultKind::Column { .. }) && v.filter & var_filter::ALIAS == 0 && literal.contains(&v.name) {
            v.unvarying = true;
        }
    }
    Ok(())
}

fn result_name(raw: &str) -> Option<String> {
    if raw.starts_with('$') && !OPT_RESULT_PREFIXES.iter().any(|p| raw.starts_with(p)) {
        None
    } else {
        Some(raw.to_string())
    }
}

/// The `$`-prefixed variables C's result file *does* carry: an `optimization`
/// model's objective terms (`BackendDAE.optimization{Mayer,Lagrange}TermName`) and
/// its constraint residuals (`DynamicOptimization`'s `$con$` / `$finalCon$` /
/// `$EqCon$`). The rest of the `$` namespace is the backend's own bookkeeping,
/// which C hides through `hideResult` and this port drops by name.
const OPT_RESULT_PREFIXES: [&str; 4] = ["$OMC$object", "$con$", "$finalCon$", "$EqCon$"];

/// Evaluate a constant variable's binding to a scalar, for the `*ConstVars`
/// lists (which have no SimData slot). Handles the literal forms model constants
/// actually take (numbers, booleans, enums, and unary minus thereof).
pub(crate) fn const_value(exp: &Option<Arc<DAE::Exp>>) -> Option<f64> {
    fn eval(e: &DAE::Exp) -> Option<f64> {
        use DAE::Exp as E;
        match e {
            E::ICONST { integer } => Some(*integer as f64),
            E::RCONST { real } => Some(real.into_inner()),
            E::BCONST { bool } => Some(if *bool { 1.0 } else { 0.0 }),
            E::ENUM_LITERAL { index, .. } => Some(*index as f64),
            E::UNARY { operator: DAE::Operator::UMINUS { .. }, exp } => eval(exp).map(|v| -v),
            E::CAST { exp, .. } => eval(exp),
            _ => None,
        }
    }
    exp.as_ref().and_then(|e| eval(e))
}

/// Classify a `SimData` slot (by byte offset) into how it appears in the result
/// file: a time-variant real reads a result-buffer column; a real/integer/
/// boolean parameter reads `data_1`. Integer/boolean *algebraic* variables (not
/// captured per row) and string variables have no numeric result column.
fn kind_from_slot(off: u32, wty: WTy, negate: Neg, heap: bool, layout: &SimLayout) -> Option<ResultKind> {
    if heap {
        // Strings: the row carries the interned text (`sim_meta::strings`) for an
        // algebraic one; a parameter is read at result-file open.
        if off >= layout.str_off && off < layout.sparam_off {
            return Some(ResultKind::Column { col: layout.str_col0() + (off - layout.str_off) / 4, negate });
        }
        if off >= layout.sparam_off && off < layout.eobj_off {
            return Some(ResultKind::Param { off, wty, negate });
        }
        return None;
    }
    if off == TIME_OFF {
        return Some(ResultKind::Column { col: 0, negate });
    }
    if off >= REAL_OFF && off < layout.rparam_off {
        // realVars region (states | derivatives | algebraics) -> data_2 column.
        return Some(ResultKind::Column { col: 1 + (off - REAL_OFF) / 8, negate });
    }
    // Integer / boolean *algebraic* variables are captured per row (as f64) in
    // the columns after the real part, so a varying one is recorded over time.
    if off >= layout.int_off && off < layout.iparam_off {
        let col = layout.n_reals_row() + (off - layout.int_off) / 4;
        return Some(ResultKind::Column { col, negate });
    }
    if off >= layout.bool_off && off < layout.bparam_off {
        let col = layout.n_reals_row() + layout.n_int_alg() + (off - layout.bool_off) / 4;
        return Some(ResultKind::Column { col, negate });
    }
    // Real / integer / boolean *parameters* are time-invariant -> data_1.
    let is_param = (off >= layout.rparam_off && off < layout.int_off)
        || (off >= layout.iparam_off && off < layout.bool_off)
        || (off >= layout.bparam_off && off < layout.str_off);
    if is_param {
        return Some(ResultKind::Param { off, wty, negate });
    }
    None // string slots
}

/// Expand every whole-array `SimVar` (`--simCodeScalarize=false`) into its
/// row-major scalar element `SimVar`s; already-scalar vars pass through.
pub(super) fn scalarize_sim_vars(vars: &SimCodeVar::SimVars) -> Result<SimCodeVar::SimVars> {
    // Already scalarized by NBackend; the element vars still carry the parent's
    // numArrayElement, so re-expanding would duplicate them.
    if openmodelica_util::Flags::getConfigBool(openmodelica_util::Flags::SIM_CODE_SCALARIZE.clone())? {
        return Ok(vars.clone());
    }
    let mut out = vars.clone();
    out.stateVars = scalarize_var_list(&vars.stateVars)?;
    out.derivativeVars = scalarize_var_list(&vars.derivativeVars)?;
    out.algVars = scalarize_var_list(&vars.algVars)?;
    out.discreteAlgVars = scalarize_var_list(&vars.discreteAlgVars)?;
    out.realOptimizeConstraintsVars = scalarize_var_list(&vars.realOptimizeConstraintsVars)?;
    out.realOptimizeFinalConstraintsVars = scalarize_var_list(&vars.realOptimizeFinalConstraintsVars)?;
    out.intAlgVars = scalarize_var_list(&vars.intAlgVars)?;
    out.boolAlgVars = scalarize_var_list(&vars.boolAlgVars)?;
    out.inputVars = scalarize_var_list(&vars.inputVars)?;
    out.outputVars = scalarize_var_list(&vars.outputVars)?;
    out.aliasVars = scalarize_var_list(&vars.aliasVars)?;
    out.intAliasVars = scalarize_var_list(&vars.intAliasVars)?;
    out.boolAliasVars = scalarize_var_list(&vars.boolAliasVars)?;
    out.paramVars = scalarize_var_list(&vars.paramVars)?;
    out.intParamVars = scalarize_var_list(&vars.intParamVars)?;
    out.boolParamVars = scalarize_var_list(&vars.boolParamVars)?;
    out.stringAlgVars = scalarize_var_list(&vars.stringAlgVars)?;
    out.stringParamVars = scalarize_var_list(&vars.stringParamVars)?;
    out.stringAliasVars = scalarize_var_list(&vars.stringAliasVars)?;
    out.extObjVars = scalarize_var_list(&vars.extObjVars)?;
    out.constVars = scalarize_var_list(&vars.constVars)?;
    out.intConstVars = scalarize_var_list(&vars.intConstVars)?;
    out.boolConstVars = scalarize_var_list(&vars.boolConstVars)?;
    out.stringConstVars = scalarize_var_list(&vars.stringConstVars)?;
    Ok(out)
}

fn scalarize_var_list(list: &List<SimCodeVar::SimVar>) -> Result<List<SimCodeVar::SimVar>> {
    let mut out: Vec<SimCodeVar::SimVar> = Vec::new();
    for sv in &**list {
        let dims = array_dims_of(&sv.numArrayElement)?;
        if dims.is_empty() {
            out.push(sv.clone());
            continue;
        }
        for idx in row_major_indices(&dims) {
            let mut e = sv.clone();
            e.name = cref_with_indices(&sv.name, &idx);
            e.numArrayElement = metamodelica::nil();
            e.arrayCref = None;
            e.aliasvar = reindex_aliasvar(&sv.aliasvar, &idx);
            e.initialValue = index_attr(&sv.initialValue, &idx);
            e.nominalValue = index_attr(&sv.nominalValue, &idx);
            e.minValue = index_attr(&sv.minValue, &idx);
            e.maxValue = index_attr(&sv.maxValue, &idx);
            out.push(e);
        }
    }
    Ok(out.into_iter().collect::<List<SimCodeVar::SimVar>>())
}

/// Parse `numArrayElement` (dimension sizes) to integers; empty for a scalar.
fn array_dims_of(nae: &List<ArcStr>) -> Result<Vec<u32>> {
    let mut dims = Vec::new();
    for s in &**nae {
        match s.trim().parse::<u32>() {
            Ok(d) => dims.push(d),
            Err(_) => {
                record_error(format!("CodegenWasmJit: non-integer array dimension `{s}`"));
                return Err("CodegenWasmJit: non-integer array dimension");
            }
        }
    }
    Ok(dims)
}

/// All 1-based index tuples of shape `dims`, row-major (last axis fastest).
pub(crate) fn row_major_indices(dims: &[u32]) -> Vec<Vec<i32>> {
    let mut out = vec![Vec::new()];
    for &d in dims {
        let mut next = Vec::with_capacity(out.len() * d as usize);
        for prefix in &out {
            for i in 1..=d as i32 {
                let mut p = prefix.clone();
                p.push(i);
                next.push(p);
            }
        }
        out = next;
    }
    out
}

/// A copy of `cr` with `idx` appended as `INDEX` subscripts on its deepest ident.
fn cref_with_indices(cr: &Arc<DAE::ComponentRef>, idx: &[i32]) -> Arc<DAE::ComponentRef> {
    use DAE::ComponentRef as C;
    match &**cr {
        C::CREF_IDENT { ident, identType, .. } => {
            let subs: List<Arc<DAE::Subscript>> = idx
                .iter()
                .map(|&i| Arc::new(DAE::Subscript::INDEX { exp: Arc::new(DAE::Exp::ICONST { integer: i }) }))
                .collect();
            Arc::new(C::CREF_IDENT { ident: ident.clone(), identType: identType.clone(), subscriptLst: subs })
        }
        C::CREF_QUAL { ident, identType, subscriptLst, componentRef } => Arc::new(C::CREF_QUAL {
            ident: ident.clone(),
            identType: identType.clone(),
            subscriptLst: subscriptLst.clone(),
            componentRef: cref_with_indices(componentRef, idx),
        }),
        _ => cr.clone(),
    }
}

/// Index an optional array-valued attribute (start/nominal/min/max) to element `idx`.
fn index_attr(attr: &Option<Arc<DAE::Exp>>, idx: &[i32]) -> Option<Arc<DAE::Exp>> {
    attr.as_ref().map(|e| index_exp(e, idx))
}

/// Element `idx` of an array expression: literal `ARRAY`/`MATRIX` indexed
/// statically, otherwise a simplified `ASUB` — `x(each start = 1)` arrives as
/// `{1.0 for $i in 1:n}`, which only folds through `simplifyAsub`.
fn index_exp(exp: &Arc<DAE::Exp>, idx: &[i32]) -> Arc<DAE::Exp> {
    use DAE::Exp as E;
    if idx.is_empty() {
        return exp.clone();
    }
    match &**exp {
        E::ARRAY { array, .. } => {
            if let Some(e) = (&**array).into_iter().nth((idx[0] - 1) as usize) {
                return index_exp(e, &idx[1..]);
            }
        }
        E::MATRIX { matrix, .. } if idx.len() >= 2 => {
            if let Some(row) = (&**matrix).into_iter().nth((idx[0] - 1) as usize) {
                if let Some(e) = (&**row).into_iter().nth((idx[1] - 1) as usize) {
                    return index_exp(e, &idx[2..]);
                }
            }
        }
        _ => {}
    }
    let sub: List<Arc<DAE::Subscript>> = idx
        .iter()
        .map(|&i| Arc::new(DAE::Subscript::INDEX { exp: Arc::new(E::ICONST { integer: i }) }))
        .collect();
    let asub = Arc::new(E::ASUB { exp: exp.clone(), sub: sub });
    openmodelica_frontend_base::ExpressionSimplify::simplify1(asub.clone())
        .map(|(e, _)| e)
        .unwrap_or(asub)
}

/// Subscript an alias target by the same `idx`; `NOALIAS` passes through.
fn reindex_aliasvar(av: &SimCodeVar::AliasVariable, idx: &[i32]) -> SimCodeVar::AliasVariable {
    use SimCodeVar::AliasVariable as A;
    match av {
        A::ALIAS { varName } => A::ALIAS { varName: cref_with_indices(varName, idx) },
        A::NEGATEDALIAS { varName } => A::NEGATEDALIAS { varName: cref_with_indices(varName, idx) },
        A::NOALIAS => A::NOALIAS,
    }
}

/// Append the `$Sensitivities.<par>.<state>` result variables — the layout's
/// sensitivity block, in its order — and return the `SimData` offsets of the
/// parameters they differentiate against (C's `sensitivityParList`, resolved
/// through the `paramVars` order the real-parameter region follows). The names
/// bypass [`result_name`], which filters `$`-prefixed ones; C keeps them.
pub(super) fn push_sensitivity_vars(
    sens_vars: &[&SimCodeVar::SimVar],
    n_sens_par: usize,
    vars: &SimCodeVar::SimVars,
    layout: &SimLayout,
    result_vars: &mut Vec<ResultVar>,
) -> Result<Vec<u32>> {
    if sens_vars.is_empty() {
        return Ok(Vec::new());
    }
    let params: HashMap<String, u32> = lst(&vars.paramVars)
        .enumerate()
        .map(|(k, sv)| Ok((cref_display(&sv.name)?, layout.rparam_off + (k as u32) * 8)))
        .collect::<Result<_>>()?;
    let mut offs = Vec::with_capacity(n_sens_par);
    for sv in &sens_vars[..n_sens_par] {
        let name = cref_display(&sv.name)?;
        let off = *params
            .get(&name)
            .ok_or("CodegenWasmJit: a sensitivity parameter is not a real parameter of the model")?;
        offs.push(off);
    }
    for (i, sv) in sens_vars[n_sens_par..].iter().enumerate() {
        result_vars.push(ResultVar {
            name: cref_display(&sv.name)?,
            comment: sv.comment.to_string(),
            kind: ResultKind::Column { col: layout.sens_col0() + i as u32, negate: Neg::None },
            unit: sv.unit.to_string(),
            display_unit: sv.displayUnit.to_string(),
            relative_quantity: sv.relativeQuantity,
            ty: var_ty(&sv.type_),
            discrete: sv.isDiscrete,
            filter: filter_bits(sv),
            unvarying: false,
            enumeration: None,
        });
    }
    Ok(offs)
}

/// Build the cref->slot map and the result-variable list from the model's
/// `SimVars`. The slot offsets follow [`SimLayout`]; the result order matches
/// the C runtime (time, states, state derivatives, real algebraics, then
/// parameters) so the `.mat` reads back identically.
pub(super) fn build_var_map(
    vars: &SimCodeVar::SimVars,
    layout: &SimLayout,
) -> Result<(SimVarMap, Vec<ResultVar>, Vec<EditableParam>)> {
    let mut map = SimVarMap {
        vars: Arc::default(),
        starts: Arc::default(),
        start_slots: Arc::default(),
        array_groups: Arc::default(),
        scatter_groups: Arc::default(),
        consts: Arc::default(),
        const_groups: Arc::default(),
        const_acc: HashMap::new(),
        extobj_dtors: Arc::default(),
        array_acc: HashMap::new(),
        terminate_off: layout.terminate_off,
        terminal_off: layout.terminal_off,
        initial_off: layout.initial_off,
        term_info_off: layout.term_info_off,
        nls_fail_off: layout.nls_fail_off,
        nls_jobs: Arc::new(HashMap::new()),
        generic_calls: Arc::new(HashMap::new()),
        n_samples: 0,
        sample_active_off: layout.sample_active_off,
        relations_off: layout.relations_off,
        rel_fresh_off: layout.rel_fresh_off,
        stored_rel_off: layout.stored_rel_off,
        relations_pre_off: layout.relations_pre_off,
        n_relations: layout.n_rel,
        mathevents_off: layout.mathevents_off,
        n_mathevents: layout.n_math,
        lambda_off: layout.lambda_off,
        homotopy_method: layout.homotopy_method.code(),
        old_real: layout.has_old_real.then_some((layout.rparam_off, layout.old_real_off)),
        zctol_off: layout.zctol_off,
        zc_pre_off: layout.zc_pre_off,
        clock_fire_off: layout.clock_fire_off,
        n_delays: 0,
        n_spatial: 0,
        prof: None,
    };
    let mut result_vars: Vec<ResultVar> = Vec::new();
    // User-settable parameters (isValueChangeable), collected as they are laid out.
    let mut editable: Vec<EditableParam> = Vec::new();
    // Collected separately: the `push_editable` closure borrows `editable`. Merged below.
    let mut start_editable: Vec<EditableParam> = Vec::new();
    let mut string_editable: Vec<EditableParam> = Vec::new();
    let mut push_editable = |sv: &SimCodeVar::SimVar, name: &str, off: u32, wty: WTy| {
        if sv.isValueChangeable && is_result_output(sv) {
            if let Some(disp) = result_name(name) {
                editable.push(EditableParam {
                    name: disp,
                    comment: sv.comment.to_string(),
                    unit: sv.unit.to_string(),
                    display_unit: sv.displayUnit.to_string(),
                    relative_quantity: sv.relativeQuantity,
                    off,
                    wty,
                    is_start: false,
                    is_bool: is_boolean_type(&sv.type_),
                    is_string: false,
                    enum_names: enumeration_names(&sv.type_).unwrap_or_default(),
                });
            }
        }
    };

    // time — result signal 0.
    result_vars.push(ResultVar {
        name: "time".to_string(),
        comment: "Simulation time [s]".to_string(),
        unit: "s".to_string(),
        display_unit: String::new(),
        relative_quantity: false,
        ty: VarTy::Real,
        discrete: false,
        kind: ResultKind::Time,
        filter: 0,
        unvarying: false,
        enumeration: None,
    });

    let states: Vec<&SimCodeVar::SimVar> = lst(&vars.stateVars).collect();
    let ders: Vec<&SimCodeVar::SimVar> = lst(&vars.derivativeVars).collect();

    // Push a primary (non-alias) variable: register its slot (equations reference
    // even protected ones) and list it as a result signal carrying why a run would
    // filter it — the overriding flags are not known here.
    let mut push_primary =
        |map: &mut SimVarMap, result_vars: &mut Vec<ResultVar>,
         sv: &SimCodeVar::SimVar, off: u32, wty: WTy, heap: bool, raw_name: String| -> Result<()> {
            insert_var(map, sv, off, wty, heap)?;
            if let Some(name) = result_name(&raw_name) {
                if let Some(kind) = kind_from_slot(off, wty, Neg::None, heap, layout) {
                    result_vars.push(ResultVar {
                        name,
                        comment: sv.comment.to_string(),
                        kind,
                        unit: sv.unit.to_string(),
                        display_unit: sv.displayUnit.to_string(),
            relative_quantity: sv.relativeQuantity,
                        ty: var_ty(&sv.type_),
                        discrete: sv.isDiscrete,
                        filter: filter_bits(sv),
                        unvarying: false,
                        enumeration: enumeration_names(&sv.type_),
                    });
                }
            }
            Ok(())
        };

    // States | derivatives | real algebraics -> the realVars region (data_2). Each
    // also owns a `start` attribute slot (C's `realVarsData[i].attribute.start`).
    let mut push_start = |map: &mut SimVarMap, sv: &SimCodeVar::SimVar, i: u32, name: &str| -> Result<()> {
        let start_off = layout.real_start_off(i);
        Arc::make_mut(&mut map.start_slots).insert(sim_cref_key(&sv.name)?, start_off);
        if sv.isValueChangeable && is_result_output(sv) {
            if let Some(disp) = result_name(name) {
                start_editable.push(EditableParam {
                    name: disp,
                    comment: sv.comment.to_string(),
                    unit: sv.unit.to_string(),
                    display_unit: sv.displayUnit.to_string(),
                    relative_quantity: sv.relativeQuantity,
                    off: start_off,
                    wty: WTy::F64,
                    is_start: true,
                    is_bool: is_boolean_type(&sv.type_),
                    is_string: false,
                    enum_names: enumeration_names(&sv.type_).unwrap_or_default(),
                });
            }
        }
        Ok(())
    };
    for (i, sv) in states.iter().enumerate() {
        let name = cref_display(&sv.name)?;
        push_start(&mut map, sv, i as u32, &name)?;
        push_primary(&mut map, &mut result_vars, sv, REAL_OFF + (i as u32) * 8, WTy::F64, false, name)?;
    }
    for (i, sv) in ders.iter().enumerate() {
        let name = cref_display(&sv.name)?;
        push_start(&mut map, sv, layout.n_states + i as u32, &name)?;
        push_primary(&mut map, &mut result_vars, sv, REAL_OFF + (layout.n_states + i as u32) * 8, WTy::F64, false, name)?;
    }
    let real_algs = real_alg_vars(vars);
    for (j, sv) in real_algs.iter().enumerate() {
        let name = cref_display(&sv.name)?;
        push_start(&mut map, sv, 2 * layout.n_states + j as u32, &name)?;
        push_primary(&mut map, &mut result_vars, sv, REAL_OFF + (2 * layout.n_states + j as u32) * 8, WTy::F64, false, name)?;
    }

    // Real / Integer / Boolean parameters -> data_1. Integer & Boolean algebraic
    // variables get slots (for equation resolution) but no result column yet
    // (they are not captured per row); strings get slots only.
    for (k, sv) in lst(&vars.paramVars).enumerate() {
        let name = cref_display(&sv.name)?;
        let off = layout.rparam_off + (k as u32) * 8;
        push_primary(&mut map, &mut result_vars, sv, off, WTy::F64, false, name.clone())?;
        push_editable(sv, &name, off, WTy::F64);
    }
    for (i, sv) in lst(&vars.intAlgVars).enumerate() {
        let name = cref_display(&sv.name)?;
        let off = layout.int_off + (i as u32) * 4;
        push_primary(&mut map, &mut result_vars, sv, off, WTy::I32, false, name)?;
    }
    for (k, sv) in lst(&vars.intParamVars).enumerate() {
        let name = cref_display(&sv.name)?;
        let off = layout.iparam_off + (k as u32) * 4;
        push_primary(&mut map, &mut result_vars, sv, off, WTy::I32, false, name.clone())?;
        push_editable(sv, &name, off, WTy::I32);
    }
    for (i, sv) in lst(&vars.boolAlgVars).enumerate() {
        let name = cref_display(&sv.name)?;
        let off = layout.bool_off + (i as u32) * 4;
        push_primary(&mut map, &mut result_vars, sv, off, WTy::I32, false, name)?;
    }
    for (k, sv) in lst(&vars.boolParamVars).enumerate() {
        let name = cref_display(&sv.name)?;
        let off = layout.bparam_off + (k as u32) * 4;
        push_primary(&mut map, &mut result_vars, sv, off, WTy::I32, false, name.clone())?;
        push_editable(sv, &name, off, WTy::I32);
    }
    for (i, sv) in lst(&vars.stringAlgVars).enumerate() {
        let name = cref_display(&sv.name)?;
        push_primary(&mut map, &mut result_vars, sv, layout.str_off + (i as u32) * 4, WTy::I32, true, name)?;
    }
    for (k, sv) in lst(&vars.stringParamVars).enumerate() {
        let off = layout.sparam_off + (k as u32) * 4;
        push_primary(&mut map, &mut result_vars, sv, off, WTy::I32, true, cref_display(&sv.name)?)?;
        // Not a result signal, but `_init.xml` lists it and C's `-override` reaches it.
        if sv.isValueChangeable && is_result_output(sv)
            && let Some(disp) = result_name(&cref_display(&sv.name)?)
        {
            string_editable.push(EditableParam {
                name: disp,
                comment: sv.comment.to_string(),
                unit: sv.unit.to_string(),
                display_unit: String::new(),
                relative_quantity: false,
                off,
                wty: WTy::I32,
                is_start: false,
                is_bool: false,
                is_string: true,
                enum_names: Vec::new(),
            });
        }
    }
    // External objects: one i32 pointer-registry handle each. Not heap (no ARC);
    // the constructor (a parameter equation) writes the handle, the destructor
    // frees the native object. No result column.
    for (i, sv) in lst(&vars.extObjVars).enumerate() {
        insert_var(&mut map, sv, layout.eobj_off + (i as u32) * 4, WTy::I32, false)?;
        Arc::make_mut(&mut map.extobj_dtors).insert(sim_cref_key(&sv.name)?, extobj_destructor_key(sv)?);
    }

    // Compile-time constants (real / integer / boolean): no SimData slot — their
    // value is the binding literal. Emit each to data_1 (the C runtime keeps them
    // in the result too, e.g. visualization colors). Record their values so a
    // constant's aliases resolve below.
    let mut const_of: HashMap<String, f64> = HashMap::new();
    let const_lists = [
        (&vars.constVars, Some(WTy::F64)),
        (&vars.intConstVars, Some(WTy::I32)),
        (&vars.boolConstVars, Some(WTy::I32)),
        (&vars.stringConstVars, None),
    ];
    for sv in const_lists.iter().flat_map(|(l, wty)| lst(l).map(move |sv| (sv, *wty))) {
        let (sv, wty) = sv;
        let key = sim_cref_key(&sv.name)?;
        if let Some(exp) = sv.initialValue.clone() {
            Arc::make_mut(&mut map.consts).insert(key.clone(), exp.clone());
            if let (Some(wty), Some((base, subs))) = (wty, array_element_of(&sv.name)?) {
                map.const_acc.entry(base).or_default().push((subs, exp, wty));
            }
        }
        let Some(value) = const_value(&sv.initialValue) else { continue };
        const_of.insert(key, value);
        if let Some(name) = result_name(&cref_display(&sv.name)?) {
            result_vars.push(ResultVar {
                name,
                comment: sv.comment.to_string(),
                kind: ResultKind::Const { value },
                unit: sv.unit.to_string(),
                display_unit: sv.displayUnit.to_string(),
            relative_quantity: sv.relativeQuantity,
                ty: var_ty(&sv.type_),
                discrete: sv.isDiscrete,
                filter: filter_bits(sv),
                unvarying: false,
                enumeration: enumeration_names(&sv.type_),
            });
        }
    }

    // Aliases: resolve to the target variable's slot (with negation) so equations
    // and `$START` of an alias read the aliased value, AND emit the alias as a
    // result signal pointing at the target's data column / parameter (with sign)
    // — the C runtime's `dataInfo` aliasing, so the data is stored once.
    // A Boolean negation is logical, any other arithmetic (C's `crefToCStr`).
    let alias_lists = lst(&vars.aliasVars)
        .map(|v| (v, false))
        .chain(lst(&vars.intAliasVars).map(|v| (v, false)))
        .chain(lst(&vars.boolAliasVars).map(|v| (v, true)))
        .chain(lst(&vars.stringAliasVars).map(|v| (v, false)));
    for (av, is_bool) in alias_lists {
        let (target, negate) = match &av.aliasvar {
            SimCodeVar::AliasVariable::ALIAS { varName } => (varName.clone(), false),
            SimCodeVar::AliasVariable::NEGATEDALIAS { varName } => (varName.clone(), true),
            SimCodeVar::AliasVariable::NOALIAS => continue,
        };
        let tkey = sim_cref_key(&target)?;
        let time_slot = match &*target {
            DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } if ident.as_str() == "time" && subscriptLst.is_empty() => {
                Some(SimSlot { off: TIME_OFF, wty: WTy::F64, negate: Neg::None, heap: false })
            }
            _ => None,
        };
        let Some(tslot) = map.vars.get(&tkey).copied().or(time_slot) else {
            // Target has no slot: it may be a compile-time constant.
            if let Some(&cval) = const_of.get(&tkey) {
                if let Some(name) = result_name(&cref_display(&av.name)?) {
                    let value =
                        if negate { Neg::None.toggle(is_bool).apply_f64(cval) } else { cval };
                    result_vars.push(ResultVar {
                        name,
                        comment: av.comment.to_string(),
                        kind: ResultKind::Const { value },
                        unit: av.unit.to_string(),
                        display_unit: av.displayUnit.to_string(),
                        relative_quantity: av.relativeQuantity,
                        ty: var_ty(&av.type_),
                        discrete: av.isDiscrete,
                        filter: filter_bits(av) | var_filter::ALIAS,
                        unvarying: false,
                        enumeration: enumeration_names(&av.type_),
                    });
                }
            }
            continue;
        };
        let slot = SimSlot {
            off: tslot.off,
            wty: tslot.wty,
            negate: if negate { tslot.negate.toggle(is_bool) } else { tslot.negate },
            heap: tslot.heap,
        };
        Arc::make_mut(&mut map.vars).insert(sim_cref_key(&av.name)?, slot);
        // An alias array is assigned as a whole, so it needs a group over the
        // target's slots.
        for g in array_element_keys(&av.name)? {
            map.array_acc.entry(g.base).or_default().push(AccElem {
                subs: g.subs,
                pieces: g.pieces,
                off: slot.off,
                wty: slot.wty,
                neg: slot.negate,
                heap: slot.heap,
            });
        }
        if let (Some(name), Some(kind)) = (
            result_name(&cref_display(&av.name)?),
            kind_from_slot(slot.off, slot.wty, slot.negate, slot.heap, layout),
        ) {
            result_vars.push(ResultVar {
                name,
                comment: av.comment.to_string(),
                kind,
                unit: av.unit.to_string(),
                display_unit: av.displayUnit.to_string(),
                        relative_quantity: av.relativeQuantity,
                ty: var_ty(&av.type_),
                discrete: av.isDiscrete,
                filter: filter_bits(av) | var_filter::ALIAS,
                unvarying: false,
                enumeration: enumeration_names(&av.type_),
            });
        }
    }

    // `pre()` slots: for every live variable slot in a pre-carrying region
    // (real / integer / boolean variables, including aliases), register a
    // parallel `$PRE.<key>` slot at the mirrored offset. Reads/writes of
    // `$PRE.x` then resolve like any other variable (see `compile_sim_cref_*`).
    let pre_entries: Vec<(String, SimSlot)> = map
        .vars
        .iter()
        .filter_map(|(key, slot)| {
            layout.pre_slot_off(slot.off).map(|off| {
                (format!("$PRE.{key}"), SimSlot { off, ..*slot })
            })
        })
        .collect();
    for (key, slot) in pre_entries {
        Arc::make_mut(&mut map.vars).insert(key, slot);
    }
    // Same for the array accumulator, so `pre(x[i])` with a non-constant subscript
    // resolves through a `$PRE.<base>` group.
    let pre_groups: Vec<(String, Vec<AccElem>)> = map
        .array_acc
        .iter()
        .filter_map(|(base, elems)| {
            let pre: Option<Vec<_>> = elems
                .iter()
                .map(|e| {
                    let mut pieces = e.pieces.clone();
                    pieces[0].insert_str(0, "$PRE.");
                    Some(AccElem {
                        subs: e.subs.clone(),
                        pieces,
                        off: layout.pre_slot_off(e.off)?,
                        wty: e.wty,
                        neg: e.neg,
                        heap: e.heap,
                    })
                })
                .collect();
            Some((format!("$PRE.{base}"), pre?))
        })
        .collect();
    map.array_acc.extend(pre_groups);

    finalize_array_groups(&mut map)?;
    editable.extend(start_editable);
    editable.extend(string_editable);
    Ok((map, result_vars, editable))
}

/// Register one variable's slot (by canonical cref key) and its start value. If
/// the variable is a scalarized array element (`base[c1,…,cn]`), also record it
/// under its array base name so a whole-array reference can later be marshalled.
pub(super) fn insert_var(map: &mut SimVarMap, sv: &SimCodeVar::SimVar, off: u32, wty: WTy, heap: bool) -> Result<()> {
    let key = sim_cref_key(&sv.name)?;
    Arc::make_mut(&mut map.vars).insert(key.clone(), SimSlot { off, wty, negate: Neg::None, heap });
    Arc::make_mut(&mut map.starts).insert(key, sv.initialValue.clone());
    for g in array_element_keys(&sv.name)? {
        map.array_acc.entry(g.base).or_default().push(AccElem {
            subs: g.subs,
            pieces: g.pieces,
            off,
            wty,
            neg: Neg::None,
            heap,
        });
    }
    Ok(())
}

/// If `cr` is a scalarized array element `base[c1,…,cn]` — the subscripts on the
/// deepest component all constant — its base name and those subscripts.
pub(super) fn array_element_of(cr: &Arc<DAE::ComponentRef>) -> Result<Option<(String, Vec<i32>)>> {
    use DAE::ComponentRef as C;
    let mut base = String::new();
    let mut node: &Arc<DAE::ComponentRef> = cr;
    loop {
        match &**node {
            C::CREF_IDENT { ident, subscriptLst, .. } => {
                base.push_str(ident);
                if subscriptLst.is_empty() {
                    return Ok(None);
                }
                return Ok(const_int_subscripts(subscriptLst)?.map(|subs| (base, subs)));
            }
            C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
                base.push_str(ident);
                if !crate::CodegenWasmJitFunctions::push_qual_subs(subscriptLst, &mut base) {
                    return Ok(None);
                }
                base.push('.');
                node = componentRef;
            }
            _ => return Ok(None),
        }
    }
}

/// The array groups a scalarized element joins. `b[1].a[2].y` joins `b[1].a`,
/// keyed as `sim_cref_key` spells it, and the flattened `b.a.y`, which is what
/// `b[$i].a[$j].y` resolves through.
pub(super) fn array_element_keys(cr: &Arc<DAE::ComponentRef>) -> Result<Vec<GroupEntry>> {
    let mut out = Vec::new();
    if let Some((base, subs)) = array_element_of(cr)? {
        let mut pieces = vec![base.clone()];
        pieces.resize(subs.len() + 1, String::new());
        out.push(GroupEntry { base, subs, pieces });
    }
    if let Some(e) = flat_array_element_of(cr)? {
        if !out.iter().any(|g| g.base == e.base) {
            out.push(e);
        }
    }
    Ok(out)
}

/// A group membership: its key, the element's index in it, and how the group
/// spells an element key (`ArrayGroup::key_pieces`).
pub(super) struct GroupEntry {
    pub(super) base: String,
    pub(super) subs: Vec<i32>,
    pub(super) pieces: Vec<String>,
}

/// One scalarized element accumulated for an array base: where it sits in the
/// array, how the group spells its key, and where its value lives.
#[derive(Clone)]
pub(super) struct AccElem {
    pub(super) subs: Vec<i32>,
    pub(super) pieces: Vec<String>,
    pub(super) off: u32,
    pub(super) wty: WTy,
    pub(super) neg: Neg,
    pub(super) heap: bool,
}

/// The name with every subscript stripped, the subscripts outermost-first, and
/// the pieces they sit between. `None` unless an outer component is subscripted.
fn flat_array_element_of(cr: &Arc<DAE::ComponentRef>) -> Result<Option<GroupEntry>> {
    use DAE::ComponentRef as C;
    let mut base = String::new();
    let mut subs = Vec::new();
    let mut pieces = Vec::new();
    let mut piece = String::new();
    let mut qualified_subs = false;
    let mut node: &Arc<DAE::ComponentRef> = cr;
    loop {
        let (ident, subscriptLst, next) = match &**node {
            C::CREF_IDENT { ident, subscriptLst, .. } => (ident, subscriptLst, None),
            C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
                qualified_subs |= !subscriptLst.is_empty();
                (ident, subscriptLst, Some(componentRef))
            }
            _ => return Ok(None),
        };
        base.push_str(ident);
        piece.push_str(ident);
        match const_int_subscripts(subscriptLst)? {
            Some(s) => {
                for ix in s {
                    subs.push(ix);
                    pieces.push(core::mem::take(&mut piece));
                }
            }
            None => return Ok(None),
        }
        match next {
            Some(n) => {
                base.push('.');
                piece.push('.');
                node = n;
            }
            None => {
                pieces.push(piece);
                return Ok((qualified_subs && !subs.is_empty())
                    .then_some(GroupEntry { base, subs, pieces }));
            }
        }
    }
}

/// Parse a subscript list to constant 1-based integer indices, or `None` if any
/// subscript is not a constant integer / enum / Boolean literal (a slice, `:`,
/// expression).
fn const_int_subscripts(subs: &List<Arc<DAE::Subscript>>) -> Result<Option<Vec<i32>>> {
    let mut out = Vec::new();
    for sub in &**subs {
        match &**sub {
            DAE::Subscript::INDEX { exp } => match crate::CodegenWasmJitFunctions::const_index_value(exp) {
                Some(ix) => out.push(ix),
                None => return Ok(None),
            },
            _ => return Ok(None),
        }
    }
    Ok(Some(out))
}

/// Finalize the accumulated array elements into [`ArrayGroup`]s. For each base:
/// derive the shape from the maximum index per axis, then *verify* that the
/// scalarized elements occupy a contiguous, row-major slot range (offset of
/// element `[i1,…,in]` equals `base_off + rowmajor_index * stride`). If the
/// backend ever lays them out differently, fail loudly rather than silently
/// build a wrong array — there is no heuristic fallback.
///
/// A well-shaped group that is not contiguous becomes a [`ScatterGroup`] instead,
/// which is enough to select one element by a run-time subscript.
pub(super) fn finalize_array_groups(map: &mut SimVarMap) -> Result<()> {
    let acc = std::mem::take(&mut map.array_acc);
    for (base, elems) in acc {
        let Some(first) = elems.first() else { continue };
        let rank = first.subs.len();
        // A group that cannot be treated as one whole-array is skipped, not fatal:
        // individual element references still resolve through their own slots, and
        // a genuine whole-array reference fails later as "unknown variable". Only
        // truly malformed shapes (non-positive index) are errors.
        if elems.iter().any(|e| e.subs.len() != rank) {
            continue; // ragged rank (element and its own sub-slice both present)
        }
        // Shape: 1-based max index per axis.
        let mut dims = vec![0u32; rank];
        for e in &elems {
            for (axis, &ix) in e.subs.iter().enumerate() {
                if ix < 1 {
                    record_error(format!(
                        "CodegenWasmJit: non-positive subscript {ix} for array variable `{base}`"));
                    return Err("CodegenWasmJit: non-positive array subscript");
                }
                dims[axis] = dims[axis].max(ix as u32);
            }
        }
        let total: u32 = dims.iter().product();
        if total as usize != elems.len() {
            continue; // not all elements present (e.g. a sub-slice is its own variable)
        }
        let wty = first.wty;
        let heap = first.heap;
        if elems.iter().any(|e| e.wty != wty || e.heap != heap) {
            continue; // mixed element storage types: not a uniform array
        }
        // Row-major element table. `total == elems.len()` only rules out a hole if
        // no two elements share an index, so an unfilled entry skips the group.
        let mut table = vec![None; total as usize];
        for e in &elems {
            let lin = e.subs.iter().enumerate().fold(0u32, |lin, (axis, &ix)| lin * dims[axis] + (ix as u32 - 1));
            table[lin as usize] = Some((e.off, e.neg));
        }
        let Some(table) = table.into_iter().collect::<Option<Vec<_>>>() else { continue };
        // Contiguous row-major and unnegated? If not (aliased elsewhere, or the
        // elements straddle SimData regions) the array cannot be gathered or
        // assigned as a whole; only a single element resolves.
        let stride = match wty { WTy::F64 => 8, WTy::I32 => 4 };
        let base_off = table[0].0;
        let contiguous = table.iter().enumerate().all(|(lin, &(off, neg))| {
            neg == Neg::None && off == base_off + lin as u32 * stride
        });
        if !contiguous {
            Arc::make_mut(&mut map.scatter_groups)
                .insert(base, ScatterGroup { wty, heap, dims, elems: table });
            continue;
        }
        let key_pieces = first.pieces.clone();
        Arc::make_mut(&mut map.array_groups)
            .insert(base, ArrayGroup { base_off, wty, heap, dims, total, key_pieces });
    }
    finalize_const_groups(map)
}

/// [`finalize_array_groups`] for constants, which own no slots: the group is the
/// row-major list of its elements' literals.
fn finalize_const_groups(map: &mut SimVarMap) -> Result<()> {
    let acc = std::mem::take(&mut map.const_acc);
    for (base, mut elems) in acc {
        let Some(rank) = elems.first().map(|(s, _, _)| s.len()) else { continue };
        if elems.iter().any(|(s, _, _)| s.len() != rank) {
            continue; // ragged rank
        }
        if elems.iter().any(|(subs, _, _)| subs.iter().any(|&ix| ix < 1)) {
            continue;
        }
        let mut dims = vec![0u32; rank];
        for (subs, _, _) in &elems {
            for (axis, &ix) in subs.iter().enumerate() {
                dims[axis] = dims[axis].max(ix as u32);
            }
        }
        let total: u32 = dims.iter().product();
        if total as usize != elems.len() {
            continue; // not every element is its own constant
        }
        let wty = elems[0].2;
        if elems.iter().any(|(_, _, w)| *w != wty) {
            continue;
        }
        elems.sort_by_key(|(subs, _, _)| {
            subs.iter().enumerate().fold(0u32, |lin, (axis, &ix)| lin * dims[axis] + (ix as u32 - 1))
        });
        let values = elems.into_iter().map(|(_, e, _)| e).collect();
        Arc::make_mut(&mut map.const_groups).insert(base, ConstGroup { wty, dims, values });
    }
    Ok(())
}
