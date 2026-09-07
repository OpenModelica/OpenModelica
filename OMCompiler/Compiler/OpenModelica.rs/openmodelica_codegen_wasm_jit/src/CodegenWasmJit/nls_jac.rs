//! Symbolic Jacobian usability for NLS/linear systems: result rows, seeds,
//! dimensions, scratch sizes.

use super::*;

/// The residual row a Jacobian result var maps to: its `SimVar.index`, which is
/// what the C template indexes `jacobian->resultVars[]` with.
pub(crate) fn jac_result_row(sv: &SimCodeVar::SimVar) -> Option<usize> {
    usize::try_from(sv.index).ok()
}

/// Every variable a Jacobian's column equations can reference, other than the
/// seeds: the `$pDER` results and the temporaries. The old backend lists them in
/// `columnVars`; the new backend leaves that empty and registers them (together
/// with the seeds, which are filtered out here) in `crefsHT` only.
pub(crate) fn jac_column_vars(jm: &SimCode::JacobianMatrix) -> Vec<SimCodeVar::SimVar> {
    use openmodelica_backend_types::BackendDAE::VarKind;
    let mut seen: HashSet<String> = HashSet::new();
    let mut out: Vec<SimCodeVar::SimVar> = Vec::new();
    let mut push = |sv: &SimCodeVar::SimVar| {
        if matches!(sv.varKind, VarKind::SEED_VAR) {
            return;
        }
        if let Ok(key) = sim_cref_key(&sv.name) {
            if seen.insert(key) {
                out.push(sv.clone());
            }
        }
    };
    for sv in jac_listed_vars(jm) {
        push(&sv);
    }
    out
}

/// Every variable a Jacobian matrix lists, nothing dropped — what
/// [`jac_column_vars`] filters. One it cannot name (an array slice) gets no slot,
/// so [`jac_lowerable`] has to see it.
pub(super) fn jac_listed_vars(jm: &SimCode::JacobianMatrix) -> Vec<SimCodeVar::SimVar> {
    let columns = lst(&jm.columns).next().into_iter().flat_map(|c| lst(&c.columnVars).cloned());
    let ht = jm
        .crefsHT
        .iter()
        .flat_map(|(_, (_, _, entries), _, _)| {
            entries.borrow().iter().flatten().map(|e| e.1.clone()).collect::<Vec<_>>()
        })
        .collect::<Vec<_>>();
    columns.chain(ht).collect()
}

/// A cref's name with its final subscripts dropped, spelled as [`array_element_of`]
/// spells an element's base.
fn cref_base_name(cr: &Arc<DAE::ComponentRef>) -> Option<String> {
    use DAE::ComponentRef as C;
    let mut base = String::new();
    let mut node: &Arc<DAE::ComponentRef> = cr;
    loop {
        match &**node {
            C::CREF_IDENT { ident, .. } => {
                base.push_str(ident);
                return Some(base);
            }
            C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
                base.push_str(ident);
                if !crate::CodegenWasmJitFunctions::push_qual_subs(subscriptLst, &mut base) {
                    return None;
                }
                base.push('.');
                node = componentRef;
            }
            _ => return None,
        }
    }
}

/// Whether a symbolic Jacobian can be lowered at all: every seed / column variable
/// resolves to a scratch slot, and every column equation is one [`lower_equation`]
/// handles and names nothing but those slots. An array-valued Jacobian needs the
/// run-time loops the C template emits, so it keeps the numerical Jacobian instead.
pub(crate) fn jac_lowerable(jm: &SimCode::JacobianMatrix) -> bool {
    let Some(col) = lst(&jm.columns).next() else { return false };
    let listed = jac_listed_vars(jm);
    if lst(&jm.seedVars).chain(listed.iter()).any(|sv| sim_cref_key(&sv.name).is_err()) {
        return false;
    }
    lst(&col.constantEqns).chain(lst(&col.columnEqns)).all(jac_eq_lowerable)
}

/// One column equation of a symbolic Jacobian, against what [`lower_equation`]
/// accepts: a differentiated algebraic loop is a `SES_LINEAR`, a differentiated
/// external or table call a `SES_ALGORITHM`.
fn jac_eq_lowerable(eq: &Arc<SimCode::SimEqSystem>) -> bool {
    use SimCode::SimEqSystem as E;
    match &**eq {
        // `lower_linear_system` needs either a usable `simJac` or the residuals of a
        // torn system; the inner equations run through `lower_equation` too.
        E::SES_LINEAR { lSystem, .. } => {
            let torn = lst(&lSystem.residual).any(|e| matches!(&**e, E::SES_RESIDUAL { .. }));
            let sim_jac = lst(&lSystem.simJac).next().is_some()
                && lst(&lSystem.simJac).all(|(_, _, e)| matches!(&**e, E::SES_RESIDUAL { .. }))
                && count(&lSystem.beqs) == count(&lSystem.vars);
            (torn || sim_jac)
                && lst(&lSystem.residual).all(jac_eq_lowerable)
                && lst(&lSystem.simJac).all(|(_, _, e)| jac_eq_lowerable(e))
                && lst(&lSystem.beqs)
                    .all(|e| openmodelica_frontend_base::Expression::extractCrefsFromExp(e.clone()).is_ok())
        }
        // The aliased equation is a model equation, which lowering handles anyway.
        E::SES_ALIAS { .. } => true,
        _ => jac_eq_crefs(eq).is_some(),
    }
}

/// Every cref a Jacobian column equation names, `None` for a kind
/// [`lower_equation`] does not handle at all.
fn jac_eq_crefs(eq: &SimCode::SimEqSystem) -> Option<Vec<Arc<DAE::ComponentRef>>> {
    use SimCode::SimEqSystem as E;
    use openmodelica_backend_types::BackendDAE::WhenOperator as W;
    let mut out = Vec::new();
    let exp = |e: &Arc<DAE::Exp>, out: &mut Vec<_>| -> bool {
        match openmodelica_frontend_base::Expression::extractCrefsFromExp(e.clone()) {
            Ok(crs) => {
                out.extend(lst(&crs).cloned());
                true
            }
            Err(_) => false,
        }
    };
    match eq {
        E::SES_SIMPLE_ASSIGN { cref, exp: rhs, .. } => {
            out.push(cref.clone());
            exp(rhs, &mut out).then_some(out)
        }
        E::SES_ARRAY_CALL_ASSIGN { lhs, exp: rhs, .. } => {
            (exp(lhs, &mut out) && exp(rhs, &mut out)).then_some(out)
        }
        E::SES_RESIDUAL { exp: e, .. } => exp(e, &mut out).then_some(out),
        E::SES_RESIZABLE_ASSIGN { .. } | E::SES_GENERIC_ASSIGN { .. } => Some(out),
        // `traverseDAEEquationsStmts` visits a statement's left-hand side too.
        E::SES_ALGORITHM { statements, .. } => {
            let alg = Arc::new(DAE::Algorithm { statementLst: statements.clone() });
            let exps = openmodelica_frontend_base::Algorithm::getAllExps(alg).ok()?;
            lst(&exps).all(|e| exp(e, &mut out)).then_some(out)
        }
        E::SES_WHEN { conditions, whenStmtLst, elseWhen, .. } => {
            out.extend(lst(conditions).cloned());
            for op in lst(whenStmtLst) {
                let ok = match op {
                    W::ASSIGN { left, right, .. } => exp(left, &mut out) && exp(right, &mut out),
                    W::REINIT { stateVar, value, .. } => {
                        out.push(stateVar.clone());
                        exp(value, &mut out)
                    }
                    W::ASSERT { condition, message, .. } => {
                        exp(condition, &mut out) && exp(message, &mut out)
                    }
                    W::TERMINATE { message, .. } => exp(message, &mut out),
                    W::NORETCALL { exp: e, .. } => exp(e, &mut out),
                };
                if !ok {
                    return None;
                }
            }
            match elseWhen {
                Some(ew) => {
                    out.extend(jac_eq_crefs(ew)?);
                    Some(out)
                }
                None => Some(out),
            }
        }
        _ => None,
    }
}

/// The residual rows of the Jacobian's `JAC_VAR` result variables, in
/// [`jac_column_vars`] order, iff they form a valid permutation of `0..n` (so the
/// Jacobian rows can be placed unambiguously); otherwise `None`.
fn nls_jac_result_rows(jm: &SimCode::JacobianMatrix, n: usize) -> Option<Vec<usize>> {
    use openmodelica_backend_types::BackendDAE::VarKind;
    let rows: Vec<usize> = jac_column_vars(jm)
        .iter()
        .filter(|v| matches!(v.varKind, VarKind::JAC_VAR))
        .map(jac_result_row)
        .collect::<Option<Vec<_>>>()?;
    let mut sorted = rows.clone();
    sorted.sort_unstable();
    if sorted.len() == n && sorted.iter().enumerate().all(|(i, &r)| i == r) {
        Some(rows)
    } else {
        None
    }
}

/// The seed slot offsets in *column* order (`SimVar.index`, what the C template
/// indexes `jacobian->seedVars[]` with), from the offsets registered for
/// `jm.seedVars`. `None` unless the indices are a permutation of `0..n`.
pub(crate) fn jac_seed_offs_by_column(jm: &SimCode::JacobianMatrix, offs: &[u32], n: usize) -> Option<Vec<u32>> {
    let mut by_col = vec![u32::MAX; n];
    for (sv, &off) in lst(&jm.seedVars).zip(offs) {
        let c = usize::try_from(sv.index).ok()?;
        if c >= n || by_col[c] != u32::MAX {
            return None;
        }
        by_col[c] = off;
    }
    by_col.iter().all(|&o| o != u32::MAX).then_some(by_col)
}

/// A nonlinear system has a usable symbolic Jacobian: a `jacobianMatrix` with one
/// seed per iteration variable and `JAC_VAR` results covering every residual row
/// (a square dense Jacobian, as `hybrj` needs).
pub(super) fn nls_jac_usable(nlsystem: &SimCode::NonlinearSystem) -> bool {
    use SimCode::SimEqSystem as E;
    // For/generic-residual Jacobian columns are array-valued, which the flat
    // `emit_nls_jac_body` can't model; use the numerical Jacobian instead.
    if lst(&nlsystem.eqs).any(|e| matches!(&**e, E::SES_FOR_RESIDUAL { .. } | E::SES_GENERIC_RESIDUAL { .. })) {
        return false;
    }
    // `emit_nls_residual_body` writes `r[i]` for the i-th scalar residual while the
    // Jacobian rows are in `res_index` space (C's `res[res_index]`), so the two only
    // line up when the residuals are already in that order.
    if lst(&nlsystem.eqs)
        .filter_map(|e| match &**e {
            E::SES_RESIDUAL { res_index, .. } => Some(*res_index),
            _ => None,
        })
        .enumerate()
        .any(|(i, r)| r != i as i32)
    {
        return false;
    }
    let Some(jm) = &nlsystem.jacobianMatrix else { return false };
    if lst(&jm.columns).next().is_none_or(|c| lst(&c.columnEqns).next().is_none()) || !jac_lowerable(jm) {
        return false;
    }
    let n = lst(&nlsystem.crefs).count();
    let rows = n - nls_lambda_extra(nlsystem) as usize;
    n > 0 && count(&jm.seedVars) as usize == n && nls_jac_result_rows(jm, rows).is_some()
}

/// The `SimData` slot a torn system's iteration variable reads and writes. An
/// initialization system can solve for a start value, and C's `cref` makes
/// `$START.<var>` an lvalue into that variable's `attribute.start` — its start
/// slot here. A discrete (Integer/Boolean) unknown the tearing could not avoid
/// keeps its own type: C truncates the solver's `x` on write and widens on
/// read. `Ok(None)` leaves naming the system to the caller.
pub(crate) fn iteration_var_slot(
    vars: &HashMap<String, SimSlot>,
    start_slots: &HashMap<String, u32>,
    cr: &Arc<DAE::ComponentRef>,
) -> Result<Option<IterSlot>> {
    let key = sim_cref_key(cr)?;
    if let Some(off) = key.strip_prefix("$START.").and_then(|k| start_slots.get(k)) {
        return Ok(Some(IterSlot { off: *off, wty: WTy::F64 }));
    }
    match vars.get(&key) {
        None => Ok(None),
        Some(slot) if slot.heap => {
            record_error(format!(
                "CodegenWasmJit: torn-system unknown `{key}` is not a numeric variable"
            ));
            Err("CodegenWasmJit: torn-system unknown is not a numeric variable")
        }
        Some(slot) => Ok(Some(IterSlot { off: slot.off, wty: slot.wty })),
    }
}

/// 1 when the last unknown is `__HOM_LAMBDA`, which has no residual row: C's
/// `size` is then one more than the solver's `n`.
/// `(sizeRows, sizeCols)` of the Jacobian C's `initialAnalyticalJacobian` would
/// initialize; `None` when it returns none (no column equations or no pattern).
pub(super) fn nls_jac_dims(nlsystem: &SimCode::NonlinearSystem) -> Option<(usize, usize)> {
    let jm = nlsystem.jacobianMatrix.as_ref()?;
    let col = lst(&jm.columns).next()?;
    let cols = match &jm.sparsityMatrix {
        SimCode::Sparsity::SPARSITY { .. } => jac_seed_scalar_count(jm)?,
        _ if lst(&jm.sparsity).next().is_none() => return None,
        _ => count(&jm.seedVars),
    };
    Some((usize::try_from(col.numberOfResultVars).ok()?, cols))
}

/// C's `getNumElems`.
fn sim_var_scalar_count(sv: &SimCodeVar::SimVar) -> Option<usize> {
    if !matches!(&*sv.type_, DAE::Type::T_ARRAY { .. }) {
        return Some(1);
    }
    lst(&sv.numArrayElement).map(|d| d.parse::<usize>().ok()).product()
}

/// C's `numScalarElems(seedVars)`.
pub(super) fn jac_seed_scalar_count(jm: &SimCode::JacobianMatrix) -> Option<usize> {
    lst(&jm.seedVars).map(sim_var_scalar_count).sum()
}

pub(super) fn nls_lambda_extra(nlsystem: &SimCode::NonlinearSystem) -> u32 {
    u32::from(is_homotopy_lambda(lst(&nlsystem.crefs).last()))
}

/// `nls_parts` for a linear system: the residuals, which may be array-valued and so
/// carry their `res_index`, and the inner (torn) equations, into `inner`.
pub(super) fn lin_residuals(
    lsystem: &SimCode::LinearSystem,
    inner: &mut Vec<Arc<SimCode::SimEqSystem>>,
) -> Vec<NlsResidual> {
    use SimCode::SimEqSystem as E;
    let mut residuals = Vec::new();
    for e in lst(&lsystem.residual) {
        match &**e {
            E::SES_RESIDUAL { exp, res_index, .. } => residuals.push(match exp_array_rows(exp) {
                Some(rows) => NlsResidual::Array { exp: exp.clone(), res_index: *res_index, rows },
                None => NlsResidual::Scalar { exp: exp.clone(), res_index: *res_index },
            }),
            E::SES_FOR_RESIDUAL { iterators, exp, res_index, .. } => residuals.push(NlsResidual::For {
                iterators: lst(iterators).cloned().collect(),
                exp: exp.clone(),
                res_index: *res_index,
            }),
            E::SES_GENERIC_RESIDUAL { iterators, scal_indices, exp, res_index, .. } => {
                residuals.push(NlsResidual::Generic {
                    iterators: lst(iterators).cloned().collect(),
                    scal_indices: lst(scal_indices).copied().collect(),
                    exp: exp.clone(),
                    res_index: *res_index,
                })
            }
            _ => inner.push(e.clone()),
        }
    }
    residuals
}

/// Torn linear system usable for analytic assembly: square Jacobian with one seed
/// per iteration variable and `JAC_VAR` results covering every residual row
/// (`n_res` = the residual vector's row count). The `nls_jac_usable` analogue for
/// linear.
pub(super) fn lin_jac_usable(lsystem: &SimCode::LinearSystem, n_res: Option<usize>) -> bool {
    let Some(n_res) = n_res else { return false };
    let Some(jm) = &lsystem.jacobianMatrix else { return false };
    if lst(&jm.columns).next().is_none_or(|c| lst(&c.columnEqns).next().is_none()) || !jac_lowerable(jm) {
        return false;
    }
    let n = count(&lsystem.vars) as usize;
    n > 0 && n == n_res && count(&jm.seedVars) as usize == n && nls_jac_result_rows(jm, n).is_some()
}

/// Total f64 scratch slots the NLS analytic Jacobians need: seeds + column
/// variables per usable system. Scans a superset of the systems
/// [`collect_nls_jobs`] registers, so the region is always large enough.
pub(super) fn nls_jac_scratch_f64(sim_code: &SimCode::SimCode) -> u32 {
    use SimCode::SimEqSystem as E;
    let mut seen: HashSet<i32> = HashSet::new();
    let mut total = 0u32;
    let mut scan = |eqs: Vec<Arc<SimCode::SimEqSystem>>| {
        for e in &eqs_with_nested(&eqs) {
            if let E::SES_NONLINEAR { nlSystem, alternativeTearing, .. } = &**e {
                // A dynamically torn component has two sets, each with its own Jacobian.
                for sys in std::iter::once(nlSystem).chain(alternativeTearing.iter()) {
                    if seen.insert(sys.index) && nls_jac_usable(sys) {
                        // seeds + all column variables (results + intermediates) get slots.
                        let jm = sys.jacobianMatrix.as_ref().unwrap();
                        total += count(&jm.seedVars) as u32 + jac_column_vars(jm).len() as u32;
                    }
                }
            }
        }
    };
    scan(flatten_eqs(&sim_code.parameterEquations));
    scan(flatten_eqs(&sim_code.initialEquations));
    scan(flatten_eqs(&sim_code.initialEquations_lambda0));
    scan(flatten_eqs(&sim_code.removedInitialEquations));
    scan(flatten_eqs(&sim_code.algorithmAndEquationAsserts));
    scan(flatten_eqs(&sim_code.equationsForZeroCrossings));
    scan(flatten_eqs_ll(&sim_code.odeEquations));
    scan(flatten_eqs_ll(&sim_code.algebraicEquations));
    scan(flatten_eqs(&sim_code.allEquations));
    scan(flatten_eqs(&sim_code.inlineEquations));
    scan(clocked_eqs(sim_code));
    if let Some(d) = &sim_code.daeModeData {
        scan(flatten_eqs_ll(&d.daeEquations));
    }
    total
}

/// Every clocked sub-partition equation, flattened.
pub(super) fn clocked_eqs(sim_code: &SimCode::SimCode) -> Vec<Arc<SimCode::SimEqSystem>> {
    let mut out = Vec::new();
    for part in lst(&sim_code.clockedPartitions) {
        for sp in lst(&part.subPartitions) {
            out.extend(lst(&sp.equations).chain(lst(&sp.removedEquations)).cloned());
        }
    }
    out
}

/// Register each system's Jacobian seed/result crefs at the `nls_jac_off` scratch
/// region (mirroring [`build_state_set_infos`]) and return the per-system offsets.
/// `nls_systems` is in [`collect_nls_jobs`] order, so offsets are assigned in the
/// same order the jobs were.
pub(super) fn build_nls_jac_infos(
    nls_systems: &[Arc<SimCode::NonlinearSystem>],
    layout: &SimLayout,
    var_map: &mut SimVarMap,
) -> Result<HashMap<i32, NlsJacInfo>> {
    let mut infos = HashMap::new();
    let mut cursor = layout.nls_jac_off;
    for sys in nls_systems {
        if !nls_jac_usable(sys) {
            continue;
        }
        let jm = sys.jacobianMatrix.as_ref().unwrap();
        // A homotopy system's Jacobian is `n×(n+1)`: a `__HOM_LAMBDA` column, no row.
        let n_cols = count(&jm.seedVars);
        let n_rows = n_cols - nls_lambda_extra(sys) as usize;
        let (info, _, slots) = register_jac_slots(jm, n_rows, n_cols, &mut cursor, var_map)
            .map_err(|_| "CodegenWasmJit: nonlinear-system Jacobian seed columns are not a permutation")?;
        let result_offs: Vec<u32> = info
            .result_offs
            .iter()
            .map(|o| o.ok_or("CodegenWasmJit: nonlinear-system Jacobian is missing a residual row"))
            .collect::<Result<_>>()?;
        let seed_offs = info.seed_offs;
        infos.insert(sys.index, NlsJacInfo { seed_offs, result_offs, slots });
    }
    finalize_array_groups(var_map)?;
    Ok(infos)
}

/// The `-l` plan: the frames, and the symbolic `A`/`B`/`C`/`D` the flat emitter
/// can lower.
pub(crate) struct LinzPlan {
    pub(super) frames: linearize::Frames,
    /// `[A, B, C, D]` dimensions.
    pub(super) rows: [u32; 4],
    pub(super) cols: [u32; 4],
    pub(super) jacs: [Option<Arc<SimCode::JacobianMatrix>>; 4],
    /// A's adjoint (row) evaluator, when compiled bidirectionally.
    pub(super) adj: Option<Arc<SimCode::JacobianMatrix>>,
    /// The shape each matrix really has (`symbolic_jacobians`), which differs from
    /// `rows`/`cols` when `DynamicOptimization` reshaped it for an `optimization`
    /// model. The slots and the results follow these.
    pub(super) real_rows: [u32; 4],
    pub(super) real_cols: [u32; 4],
}
