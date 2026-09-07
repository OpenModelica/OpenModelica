//! Nonlinear systems: parts, jobs, nominal map, the residual/Jacobian
//! functions (`build_nls_fns`) and start-value emission.

use super::*;

/// Partition a nonlinear system's equations into the inner (torn) constraint
/// equations and the `SES_RESIDUAL` residual expressions, and its iteration
/// unknowns. Shared by [`collect_nls_jobs`] (which counts unknowns) and
/// [`build_nls_fns`] (which emits the callbacks).
pub(super) fn nls_parts(
    nlsystem: &SimCode::NonlinearSystem,
) -> Result<(Vec<Arc<SimCode::SimEqSystem>>, NlsResiduals, Vec<Arc<DAE::ComponentRef>>)> {
    use SimCode::SimEqSystem as E;
    let mut inner: Vec<Arc<SimCode::SimEqSystem>> = Vec::new();
    let mut residuals: Vec<NlsResidual> = Vec::new();
    for e in lst(&nlsystem.eqs) {
        match &**e {
            E::SES_RESIDUAL { exp, res_index, .. } => {
                residuals.push(match exp_array_rows(exp) {
                    Some(rows) => NlsResidual::Array { exp: exp.clone(), res_index: *res_index, rows },
                    None => NlsResidual::Scalar { exp: exp.clone(), res_index: *res_index },
                });
            }
            E::SES_FOR_RESIDUAL { iterators, exp, res_index, .. } => {
                residuals.push(NlsResidual::For {
                    iterators: lst(iterators).cloned().collect(),
                    exp: exp.clone(),
                    res_index: *res_index,
                });
            }
            E::SES_GENERIC_RESIDUAL { iterators, scal_indices, exp, res_index, .. } => {
                residuals.push(NlsResidual::Generic {
                    iterators: lst(iterators).cloned().collect(),
                    scal_indices: lst(scal_indices).copied().collect(),
                    exp: exp.clone(),
                    res_index: *res_index,
                });
            }
            _ => inner.push(e.clone()),
        }
    }
    let iter_vars: Vec<Arc<DAE::ComponentRef>> = lst(&nlsystem.crefs).cloned().collect();
    if residuals.is_empty() {
        // An inverse algorithm is the system's lone equation and its own residual.
        if let [e] = inner.as_slice() {
            if let E::SES_INVERSE_ALGORITHM { knownOutputCrefs, .. } = &**e {
                let known = lst(knownOutputCrefs).cloned().collect();
                return Ok((inner, NlsResiduals::InverseAlgorithm(known), iter_vars));
            }
        }
        // No unknowns either: the system is its inner equations, evaluated once.
        if iter_vars.is_empty() {
            return Ok((inner, NlsResiduals::Explicit(residuals), iter_vars));
        }
        return Err("CodegenWasmJit: SES_NONLINEAR has no residual equations");
    }
    // Only checkable when every residual's row count is static. An adaptive
    // approach appends `__HOM_LAMBDA` without a residual: the arc-length
    // condition closes it.
    let extra = usize::from(is_homotopy_lambda(iter_vars.last()));
    let rows = residuals.iter().try_fold(0usize, |acc, r| r.rows().map(|n| acc + n));
    if rows.is_some_and(|rows| iter_vars.len() != rows + extra) {
        return Err("CodegenWasmJit: SES_NONLINEAR unknown/residual count mismatch");
    }
    Ok((inner, NlsResiduals::Explicit(residuals), iter_vars))
}

/// The element count of an array-typed expression; `None` for a scalar.
pub(super) fn exp_array_rows(exp: &Arc<DAE::Exp>) -> Option<usize> {
    let ty = openmodelica_frontend_base::Expression::r#typeof(exp.clone()).ok()?;
    let dims = type_dims(&ty)?;
    (!dims.is_empty()).then(|| dims.iter().product())
}

/// Dynamic tearing: each casual tearing set's equation index -> its strict set's.
pub(super) fn nls_strict_map(eq_lists: &[&[Arc<SimCode::SimEqSystem>]]) -> HashMap<i32, i32> {
    use SimCode::SimEqSystem as E;
    let mut out = HashMap::new();
    for list in eq_lists {
        for e in *list {
            if let E::SES_NONLINEAR { nlSystem, alternativeTearing: Some(at), .. } = &**e {
                out.insert(at.index, nlSystem.index);
            }
        }
    }
    out
}

/// The `__HOM_LAMBDA` unknown `generateHomotopyComponents` appends under an
/// adaptive approach. C maps the cref to `simulationInfo->lambda`.
pub(super) fn is_homotopy_lambda(cr: Option<&Arc<DAE::ComponentRef>>) -> bool {
    matches!(cr.map(|c| &**c),
        Some(DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. })
            if subscriptLst.is_empty()
                && ident.as_str() == openmodelica_backend_types::BackendDAE::homotopyLambda)
}

/// Scan the compiled equation lists for `SES_NONLINEAR` systems (deduplicated by
/// index, in first-seen order) and assign each an `rt_solve_nls` job. Returns the
/// ordered systems (for [`build_nls_fns`]) and the index -> job map, which is
/// threaded to the equation lowering via `SimVarMap`/`SimCtx`.
pub(super) fn collect_nls_jobs(
    eq_lists: &[&[Arc<SimCode::SimEqSystem>]],
    nominal_of: &HashMap<String, (f64, f64, f64)>,
    attr_targets: &mut HashMap<String, AttrTargets>,
) -> (Vec<Arc<SimCode::NonlinearSystem>>, HashMap<i32, NlsJob>, u32, Vec<f64>, Vec<f64>, Vec<i32>, Vec<String>) {
    use SimCode::SimEqSystem as E;
    let mut systems: Vec<Arc<SimCode::NonlinearSystem>> = Vec::new();
    // Numbered and ordered by `indexNonLinearSystem`, as C's `sysNum` loop is.
    let mut warnings: Vec<(i32, String)> = Vec::new();
    let mut jobs: HashMap<i32, NlsJob> = HashMap::new();
    let mut hist_off = 0u32;
    let mut nominal_off = 0u32;
    let mut pat_off = 0u32;
    // Concatenated `colptr[n+1] | rowidx[nnz]` of every sparsely-solved system, in
    // system order; the module `start` writes them into the pattern block.
    let mut patterns: Vec<i32> = Vec::new();
    // Concatenated nominal values, in system order; the module `start` writes them
    // into the nominal block, and each job's `nominal_off` indexes into it.
    let mut nominals: Vec<f64> = Vec::new();
    // `min`/`max` pairs alongside them, in the same order.
    let mut bounds: Vec<f64> = Vec::new();
    for list in eq_lists {
        for e in *list {
            // A dynamically torn component registers both sets: the strict one (whose
            // function the casual set falls back to) and the casual one.
            let both: Vec<(&Arc<SimCode::NonlinearSystem>, bool)> = match &**e {
                E::SES_NONLINEAR { nlSystem, alternativeTearing: Some(at), .. } => {
                    vec![(nlSystem, false), (at, true)]
                }
                E::SES_NONLINEAR { nlSystem, .. } => vec![(nlSystem, false)],
                _ => Vec::new(),
            };
            for (nlSystem, casual) in both {
                if jobs.contains_key(&nlSystem.index) {
                    continue;
                }
                let n = lst(&nlSystem.crefs).count() as u32;
                let mut has_jac = nls_jac_usable(nlSystem);
                // C's `initializeNonlinearSystemData` shape check.
                if let Some((rows, cols)) = nls_jac_dims(nlSystem) {
                    let size = n as usize;
                    if rows != size - nls_lambda_extra(nlSystem) as usize || cols != size {
                        warnings.push((nlSystem.indexNonLinearSystem, format!(
                            "Analytic Jacobian of non-linear system {} is {rows}x{cols}, but the system \
                             has {size} iteration variables. This indicates that something went wrong \
                             during Jacobian generation. Using a numeric Jacobian instead.",
                            nlSystem.indexNonLinearSystem
                        )));
                        has_jac = false;
                    }
                }
                let mixed = nlSystem.mixedSystem;
                // The pattern goes in whenever it exists: C's density/size rule only
                // picks the *default* solver (kinsol+KLU vs the dense ladder), while
                // `-nls=kinsol` hands every patterned system to KINSOL.
                // C builds the pattern from the `JAC_MATRIX` alone — an empty column
                // list still carries one — then checks it.
                let raw_pat = nlSystem
                    .jacobianMatrix
                    .as_ref()
                    .and_then(|jm| nls_jac_pattern_raw(jm, n as usize));
                let pat = raw_pat.filter(|p| {
                    p.passes_sanity_check(n as usize) || {
                        warnings.push((nlSystem.indexNonLinearSystem, format!(
                            "Sparsity pattern for non-linear system {} is not regular. This indicates \
                             that something went wrong during sparsity pattern generation. Removing \
                             sparsity pattern and disabling NLS scaling.",
                            nlSystem.indexNonLinearSystem
                        )));
                        false
                    }
                });
                let pat = pat.filter(|p| p.is_square(n as usize));
                let nnz = pat.as_ref().map_or(0, |p| p.rowidx.len() as u32);
                let sparse_default = nnz != 0 && nls_use_sparse(n as usize, nnz as usize);
                if std::env::var("OMC_WASM_SIM_BENCH").is_ok() {
                    eprintln!(
                        "wasm-jit nls {}: n={n} nnz={} jac={has_jac} mixed={mixed} sparse={} colors={}",
                        nlSystem.index,
                        nls_system_nnz(nlSystem),
                        sparse_default,
                        pat.as_ref().map_or(0, |p| p.colors.len()),
                    );
                }
                if let Some(p) = &pat {
                    patterns.extend_from_slice(&p.colptr);
                    patterns.extend_from_slice(&p.rowidx);
                    patterns.extend_from_slice(&p.color_of_column(n as usize));
                }
                jobs.insert(nlSystem.index, NlsJob { k: systems.len() as u32, n, eq_index: nlSystem.index as u32, hist_off, nominal_off, has_jac, mixed, nnz, pat_off, sparse_default, homotopy_support: nlSystem.homotopySupport, casual });
                if nnz != 0 {
                    pat_off += 4 * (2 * n + 1 + nnz);
                }
                hist_off += crate::CodegenWasmJitFunctions::nls_hist_bytes(n);
                nominal_off += 8 * n;
                for cr in lst(&nlSystem.crefs) {
                    let key = sim_cref_key(cr).ok();
                    let (nom, lo, hi) = key
                        .as_ref()
                        .and_then(|k| nominal_of.get(k).copied())
                        .unwrap_or((1.0, -f64::MAX, f64::MAX));
                    if let Some(k) = key {
                        attr_targets.entry(k).or_default().nls.push(nominals.len() as u32);
                    }
                    nominals.push(nom);
                    bounds.push(lo);
                    bounds.push(hi);
                }
                systems.push(nlSystem.clone());
            }
        }
    }
    warnings.sort_by_key(|(k, _)| *k);
    (systems, jobs, hist_off, nominals, bounds, patterns, warnings.into_iter().map(|(_, w)| w).collect())
}

/// The optimizer's Jacobian entry points, in emission order: for B, C and D the
/// seed-independent equations and then one column. Matched by
/// `OptJac::{const_fn, column_fn}`.
pub(crate) const OPT_JAC_FNS: [&str; 6] = [
    "optJacB_const", "optJacB", "optJacC_const", "optJacC", "optJacD_const", "optJacD",
];

/// The real variables after the states and their derivatives, in C's
/// `realVars` order: the algebraics, then the discrete ones, then an
/// `optimization` model's path and final constraint variables (C's
/// `nVariablesReal` counts those last, which is what the optimizer's
/// `index_con = nReal - (nc + ncf)` relies on).
pub(super) fn real_alg_vars(vars: &SimCodeVar::SimVars) -> Vec<&SimCodeVar::SimVar> {
    lst(&vars.algVars)
        .chain(lst(&vars.discreteAlgVars))
        .chain(lst(&vars.realOptimizeConstraintsVars))
        .chain(lst(&vars.realOptimizeFinalConstraintsVars))
        .collect()
}

/// Map each scalar Real (and Integer) variable's cref key to its `(nominal, min, max)` attributes,
/// defaulting to `(1.0, -inf, +inf)` where unset or non-constant.
pub(super) fn build_nls_nominal_map(vars: &SimCodeVar::SimVars) -> HashMap<String, (f64, f64, f64)> {
    let mut map = HashMap::new();
    // `derivativeVars`: a `$DER.x` iteration variable otherwise scales at nominal 1.
    let all = lst(&vars.stateVars)
        .chain(lst(&vars.derivativeVars))
        .chain(lst(&vars.algVars))
        .chain(lst(&vars.discreteAlgVars))
        .chain(lst(&vars.intAlgVars))
        .chain(lst(&vars.paramVars))
        .chain(lst(&vars.aliasVars));
    for sv in all {
        if let Ok(key) = sim_cref_key(&sv.name) {
            let nom = const_value(&sv.nominalValue).map(|v| v.abs()).filter(|v| *v > 0.0).unwrap_or(1.0);
            let lo = const_value(&sv.minValue).unwrap_or(-f64::MAX);
            let hi = const_value(&sv.maxValue).unwrap_or(f64::MAX);
            map.entry(key).or_insert((nom, lo, hi));
        }
    }
    map
}

/// Per-system scratch offsets for the analytic-Jacobian `nls_jac` callback: the
/// seed slots (one per differentiation column) and the column-result slots (one
/// per residual row). Both live in the `nls_jac_off` region, registered as var
/// slots so the Jacobian `columnEqns` resolve their `$SEED.*`/`$pDER.*` crefs.
pub(super) struct NlsJacInfo {
    pub(super) seed_offs: Vec<u32>,
    pub(super) result_offs: Vec<u32>,
    /// This system's own seed/column slots. The new backend names every system's
    /// Jacobian variables after the *same* matrix (`$SEED_ALG_LS_JAC_1.u`,
    /// `$pDER_ALG_LS_JAC_1.$RES_SIM_0`, ...), so the shared cref map only keeps the
    /// last system that registered them; lowering a Jacobian body binds these back.
    pub(super) slots: Vec<(String, SimSlot)>,
}

/// The nonlinear-solver part of the module `start`: grow the shared
/// `rt.__indirect_function_table` by `4 * n` slots, record the base (the old
/// size) in the `nls_base` global, then write each system's `residual`/`load`
/// function references into `base + 4k` / `base + 4k + 1`
/// (`fn_indices[k] = (residual, load, jac, strict)`). `rt_solve_nls` reads these
/// indices back via the global (see `emit_solve_nls_call`). Also `rt_alloc`s the
/// extrapolation-history block (`hist_bytes`) into `NLS_HIST_GLOBAL`.
pub(super) fn emit_nls_start(
    f: &mut we::Function,
    fn_indices: &[(u32, u32, Option<u32>, Option<u32>)],
    hist_bytes: u32,
    sizes: &[u32],
    nominals: &[f64],
    bounds: &[f64],
    patterns: &[i32],
) {
    use we::Instruction as I;
    use crate::CodegenWasmJitFunctions::{NLS_BOUNDS_GLOBAL, NLS_NOMINAL_GLOBAL, NLS_PAT_GLOBAL};
    // history block (zeroed by rt_alloc, so every system's count starts 0).
    if hist_bytes > 0 {
        f.instruction(&I::I32Const(hist_bytes as i32));
        f.instruction(&I::Call(rt_index("rt_alloc").expect("rt_alloc is a runtime builtin")));
        f.instruction(&I::GlobalSet(NLS_HIST_GLOBAL));
    }
    // Hand each system's slice of it to the runtime's roster.
    let mut hist_off = 0u32;
    for (k, n) in sizes.iter().enumerate() {
        f.instruction(&I::I32Const(k as i32));
        f.instruction(&I::GlobalGet(NLS_HIST_GLOBAL));
        f.instruction(&I::I32Const(hist_off as i32));
        f.instruction(&I::I32Add);
        f.instruction(&I::I32Const(*n as i32));
        f.instruction(&I::Call(rt_index("rt_nls_register").expect("rt_nls_register is a runtime builtin")));
        hist_off += crate::CodegenWasmJitFunctions::nls_hist_bytes(*n);
    }
    // nominal block: rt_alloc, then store each system's iteration-variable nominal
    // constants (concatenated in system order) for `rt_solve_nls`'s x-scaling.
    if !nominals.is_empty() {
        f.instruction(&I::I32Const((nominals.len() * 8) as i32));
        f.instruction(&I::Call(rt_index("rt_alloc").expect("rt_alloc is a runtime builtin")));
        f.instruction(&I::GlobalSet(NLS_NOMINAL_GLOBAL));
        for (i, nom) in nominals.iter().enumerate() {
            f.instruction(&I::GlobalGet(NLS_NOMINAL_GLOBAL));
            f.instruction(&I::F64Const((*nom).into()));
            f.instruction(&I::F64Store(crate::CodegenWasmJitFunctions::mem_arg((i * 8) as u32, 3)));
        }
    }
    // bounds block: the `min`/`max` pair per iteration variable, same order.
    if !bounds.is_empty() {
        f.instruction(&I::I32Const((bounds.len() * 8) as i32));
        f.instruction(&I::Call(rt_index("rt_alloc").expect("rt_alloc is a runtime builtin")));
        f.instruction(&I::GlobalSet(NLS_BOUNDS_GLOBAL));
        for (i, v) in bounds.iter().enumerate() {
            f.instruction(&I::GlobalGet(NLS_BOUNDS_GLOBAL));
            f.instruction(&I::F64Const((*v).into()));
            f.instruction(&I::F64Store(crate::CodegenWasmJitFunctions::mem_arg((i * 8) as u32, 3)));
        }
    }
    // sparse-pattern block: the concatenated `colptr`/`rowidx` of every system
    // solved sparsely, indexed by each job's `pat_off`.
    if !patterns.is_empty() {
        f.instruction(&I::I32Const((patterns.len() * 4) as i32));
        f.instruction(&I::Call(rt_index("rt_alloc").expect("rt_alloc is a runtime builtin")));
        f.instruction(&I::GlobalSet(NLS_PAT_GLOBAL));
        for (i, v) in patterns.iter().enumerate() {
            f.instruction(&I::GlobalGet(NLS_PAT_GLOBAL));
            f.instruction(&I::I32Const(*v));
            f.instruction(&I::I32Store(crate::CodegenWasmJitFunctions::mem_arg((i * 4) as u32, 2)));
        }
    }
    // base = table.grow(null, 4n) — returns the old size (the growable table's max
    // is unbounded, so this cannot fail here). Four slots per system:
    // `4k`=residual, `4k+1`=load, `4k+2`=jac, `4k+3`=the strict tearing set's solve
    // (the last two left null where the system has neither).
    f.instruction(&I::RefNull(we::HeapType::FUNC));
    f.instruction(&I::I32Const((4 * fn_indices.len()) as i32));
    f.instruction(&I::TableGrow(0));
    f.instruction(&I::GlobalSet(NLS_BASE_GLOBAL));
    fn set_slot(f: &mut we::Function, off: i32, idx: u32) {
        use we::Instruction as I;
        f.instruction(&I::GlobalGet(NLS_BASE_GLOBAL));
        f.instruction(&I::I32Const(off));
        f.instruction(&I::I32Add);
        f.instruction(&I::RefFunc(idx));
        f.instruction(&I::TableSet(0));
    }
    for (k, (res_idx, load_idx, jac_idx, strict_idx)) in fn_indices.iter().enumerate() {
        let base_off = (4 * k) as i32;
        set_slot(f, base_off, *res_idx);
        set_slot(f, base_off + 1, *load_idx);
        if let Some(jac_idx) = jac_idx {
            set_slot(f, base_off + 2, *jac_idx);
        }
        if let Some(strict_idx) = strict_idx {
            set_slot(f, base_off + 3, *strict_idx);
        }
    }
}
