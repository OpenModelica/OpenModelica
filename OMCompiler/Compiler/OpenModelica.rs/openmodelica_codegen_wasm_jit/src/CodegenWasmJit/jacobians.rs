//! Symbolic Jacobians: the linearization plan, per-system Jacobian
//! functions, slot registration, linear-system CSC patterns.

use super::*;

impl LinzPlan {
    /// C's `initialAnalyticJacobian<X>` availability, as [`LinInfo::sym_mask`]: a
    /// matrix is the linearization's only if it fits the shape `-l` expects — one
    /// column per seed, and no more rows than the output region (a row the backend
    /// left out is structurally zero, which `emit_linz_jac_body` stores). An
    /// `optimization` model's reshaped B/C/D are lowered for the optimizer but left
    /// off the linearization's difference-quotient fallback.
    fn sym_mask(&self) -> u8 {
        (0..4)
            .filter(|&k| {
                self.jacs[k].is_some()
                    && self.real_rows[k] <= self.rows[k]
                    && self.real_cols[k] == self.cols[k]
            })
            .fold(0u8, |m, k| m | 1 << k)
    }

    /// Whether matrix `k` fills the linearization's output region.
    fn lin_ok(&self, k: usize) -> bool {
        self.sym_mask() & (1 << k) != 0
    }

    /// f64 slots the matrices occupy at the head of the region — all four at the
    /// linearization's shape, so an offset does not move with availability.
    fn n_matrix_f64(&self) -> u32 {
        (0..4).map(|k| self.rows[k] * self.cols[k]).sum()
    }

    /// Those plus every seed / column variable the available columns assign.
    pub(super) fn n_scratch_f64(&self) -> u32 {
        if self.jacs.iter().all(Option::is_none) {
            return 0;
        }
        self.n_matrix_f64()
            + self
                .jacs
                .iter()
                .chain(core::iter::once(&self.adj))
                .flatten()
                .map(|jm| count(&jm.seedVars) as u32 + jac_column_vars(jm).len() as u32)
                .sum::<u32>()
    }
}

pub(super) fn build_linz_plan(
    sim_code: &SimCode::SimCode,
    vars: &SimCodeVar::SimVars,
    n_states: u32,
) -> Result<LinzPlan> {
    let n_in = count(&vars.inputVars) as u32;
    let n_out = count(&vars.outputVars) as u32;
    let n_alg = count(&vars.algVars) as u32;
    let prefix = model_name_prefix(sim_code);
    let frames = linearize::build_frames(vars, n_states, n_in, n_out, n_alg, &prefix)?;
    let rows = [n_states, n_states, n_out, n_out];
    let cols = [n_states, n_in, n_states, n_in];
    let found = linearize::symbolic_jacobians(sim_code);
    let jacs = core::array::from_fn(|k| found[k].as_ref().map(|(jm, _, _)| jm.clone()));
    let real_rows = core::array::from_fn(|k| found[k].as_ref().map_or(0, |&(_, r, _)| r));
    let real_cols = core::array::from_fn(|k| found[k].as_ref().map_or(0, |&(_, _, c)| c));
    let adj = found[0].as_ref().filter(|(a, _, _)| a.isBidirectional).and_then(|(a, _, _)| {
        let jm = lst(&sim_code.jacobianMatrices).find(|j| j.matrixName == a.adjointMatrixName)?.clone();
        let has_equations = lst(&jm.columns).next().is_some_and(|c| lst(&c.columnEqns).next().is_some());
        (has_equations && jac_lowerable(&jm)).then_some(jm)
    });
    Ok(LinzPlan { frames, rows, cols, jacs, adj, real_rows, real_cols })
}

/// C's `modelNamePrefix`: the linearization frames quote it as the model's
/// description, and it is the FMU's modelIdentifier.
pub(super) fn model_name_prefix(sim_code: &SimCode::SimCode) -> String {
    openmodelica_util::System::makeC89Identifier(sim_code.fileNamePrefix.clone()).to_string()
}

/// Register the Jacobians' seed / column-variable crefs behind the matrices, and
/// return each matrix's seed and result slots.
pub(super) fn build_linz_jac_infos(
    plan: &LinzPlan,
    layout: &SimLayout,
    var_map: &mut SimVarMap,
) -> Result<(Vec<Option<LinzJacInfo>>, Option<AdjJacInfo>)> {
    let mut cursor = layout.linz_off + plan.n_matrix_f64() * 8;
    let mut infos = Vec::with_capacity(4);
    for (k, jm) in plan.jacs.iter().enumerate() {
        let Some(jm) = jm else {
            infos.push(None);
            continue;
        };
        // `emit_linz_jac_body` stores a slot or a structural zero for every row of
        // the output region, so cover both shapes.
        let rows = plan.real_rows[k].max(plan.rows[k]) as usize;
        let cols = plan.real_cols[k] as usize;
        let (info, _, _) = register_jac_slots(jm, rows, cols, &mut cursor, var_map)?;
        infos.push(Some(info));
    }
    // The new backend's column code reads seed/result arrays whole.
    finalize_array_groups(var_map)?;
    // The adjoint names its temporaries as A does; C keeps `tmpVars` per matrix.
    let adj = match &plan.adj {
        Some(jm) => {
            let n = plan.real_rows[0] as usize;
            let mut map = var_map.clone();
            let (info, zero_offs, _) = register_jac_slots(jm, n, n, &mut cursor, &mut map)?;
            finalize_array_groups(&mut map)?;
            Some(AdjJacInfo { info, zero_offs, map })
        }
        None => None,
    };
    Ok((infos, adj))
}

pub(super) struct AdjJacInfo {
    pub(super) info: LinzJacInfo,
    pub(super) zero_offs: Vec<u32>,
    pub(super) map: SimVarMap,
}

/// A scratch slot per seed and column variable from `cursor` on; also returns the
/// non-seed slots.
pub(super) fn register_jac_slots(
    jm: &SimCode::JacobianMatrix,
    rows: usize,
    cols: usize,
    cursor: &mut u32,
    var_map: &mut SimVarMap,
) -> Result<(LinzJacInfo, Vec<u32>, Vec<(String, SimSlot)>)> {
    use openmodelica_backend_types::BackendDAE::VarKind;
    let column_vars = jac_column_vars(jm);
    // The pairs this matrix registered. Two matrices can name their variables alike
    // (the new backend names every system's after the same one), and then the shared
    // map only keeps the last; lowering a body binds these back over it.
    let mut registered: Vec<(String, SimSlot)> = Vec::new();
    // The new backend lists an array's base beside its elements.
    let mut bases: HashSet<String> = HashSet::new();
    for sv in lst(&jm.seedVars).chain(column_vars.iter()) {
        if let Some((base, _)) = array_element_of(&sv.name)? {
            bases.insert(base);
        }
    }
    let mut insert = |sv: &SimCodeVar::SimVar, var_map: &mut SimVarMap, cursor: &mut u32| -> Result<Option<u32>> {
        let key = sim_cref_key(&sv.name)?;
        if bases.contains(&key) {
            return Ok(None);
        }
        let off = *cursor;
        let slot = SimSlot { off, wty: WTy::F64, negate: Neg::None, heap: false };
        registered.push((key.clone(), slot));
        Arc::make_mut(&mut var_map.vars).insert(key, slot);
        for g in array_element_keys(&sv.name)? {
            var_map.array_acc.entry(g.base).or_default().push(AccElem {
                subs: g.subs,
                pieces: g.pieces,
                off,
                wty: WTy::F64,
                neg: Neg::None,
                heap: false,
            });
        }
        *cursor += 8;
        Ok(Some(off))
    };
    let mut listed = Vec::new();
    for sv in lst(&jm.seedVars) {
        listed.push(insert(sv, var_map, cursor)?.ok_or("CodegenWasmJit: a Jacobian seed is an array base")?);
    }
    let mut result_offs = vec![None; rows];
    let mut others = Vec::new();
    for sv in &column_vars {
        let Some(off) = insert(sv, var_map, cursor)? else { continue };
        others.push(off);
        if matches!(sv.varKind, VarKind::JAC_VAR)
            && let Some(row) = jac_result_row(sv).filter(|&r| r < rows)
        {
            result_offs[row] = Some(off);
        }
    }
    let seed_offs = jac_seed_offs_by_column(jm, &listed, cols)
        .ok_or("CodegenWasmJit: linearization Jacobian seed columns are not a permutation")?;
    Ok((LinzJacInfo { seed_offs, result_offs }, others, registered))
}

/// One matrix's seed slots (column order) and result slots (row order; `None` is
/// a structural zero).
pub(super) struct LinzJacInfo {
    pub(super) seed_offs: Vec<u32>,
    pub(super) result_offs: Vec<Option<u32>>,
}

/// The runtime half of the plan, once the variable map exists.
pub(super) fn build_lin_info(
    plan: &LinzPlan,
    vars: &SimCodeVar::SimVars,
    var_map: &SimVarMap,
) -> Result<Option<openmodelica_sim_meta::LinInfo>> {
    use openmodelica_sim_meta::LinVar;
    // A compile-time-constant input/output has no slot to perturb or read, so the
    // model cannot be linearized (nor can C's); `-l` reports it rather than
    // translation failing.
    let slots = |list: &List<SimCodeVar::SimVar>| -> Result<Option<Vec<LinVar>>> {
        let mut out = Vec::new();
        for sv in lst(list) {
            let Some(slot) = var_map.vars.get(&sim_cref_key(&sv.name)?) else { return Ok(None) };
            out.push(LinVar { off: slot.off, negate: slot.negate });
        }
        Ok(Some(out))
    };
    let (Some(input_vars), Some(output_vars)) = (slots(&vars.inputVars)?, slots(&vars.outputVars)?)
    else {
        return Ok(None);
    };
    Ok(Some(openmodelica_sim_meta::LinInfo {
        input_vars,
        output_vars,
        language: plan.frames.language,
        frame: plan.frames.frame.clone(),
        frame_datarec: plan.frames.frame_datarec.clone(),
        disabled_reason: plan.frames.disabled_reason.clone(),
        sym_mask: plan.sym_mask(),
        run_testsuite: openmodelica_util::Testsuite::isRunning()?,
        jac_rows: plan.rows,
        jac_cols: plan.cols,
    }))
}

/// A Jacobian the emitter cannot lower is not an error, so its attempt reports here.
pub(crate) const JAC_CHECKPOINT: ArcStr = arcstr::literal!("wasm-jit symbolic Jacobian");

/// Lower the symbolic Jacobians' columns: `linearJac<X>` for `-l`, the
/// `functionJacA_{constantEqns,column}` pair the integrators drive, and for an
/// `optimization` model the `optJac<X>{_const,}` pair the optimizer drives one
/// colour at a time. A matrix that does not lower is dropped from the plan, so
/// `sym_mask` reports it unavailable and the run differentiates numerically —
/// availability is what the emitter can lower, not a prediction of it. Returns
/// `linearJac<X>`, A's pair, then B/C/D's.
#[allow(clippy::too_many_arguments)]
pub(super) fn build_jac_fns(
    plan: &mut LinzPlan,
    infos: &[Option<LinzJacInfo>],
    is_optimization: bool,
    layout: &SimLayout,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
    adj_map: Option<&SimVarMap>,
) -> Result<(Vec<we::Function>, [we::Function; 2], Vec<we::Function>, [we::Function; 2])> {
    let (mut linz_fns, mut jac_a_fns, mut opt_fns) = (Vec::new(), None, Vec::new());
    let mut out_off = layout.linz_off;
    for k in 0..4 {
        let mut built = None;
        if let (Some(jm), Some(info)) = (plan.jacs[k].clone(), infos.get(k).and_then(Option::as_ref)) {
            openmodelica_error::ErrorExt::setCheckpoint(JAC_CHECKPOINT);
            let attempt = (|| -> Result<(we::Function, [we::Function; 2])> {
                // A reshaped matrix has no linearization output region to fill.
                let lin = match plan.lin_ok(k) {
                    true => build_linz_jac_fn(plan, info, k, out_off, var_map, eq_index, by_name, literals)?,
                    false => empty_eqfn(),
                };
                // A is the integrators'; only the optimizer reads B, C and D.
                if k > 0 && !is_optimization {
                    return Ok((lin, [empty_eqfn(), empty_eqfn()]));
                }
                let (constant, column) = optimization::jac_eqns(&jm);
                let jm_map = with_jac_calls(var_map, &jm);
                Ok((lin, [
                    build_eq_fn_single(&eq_units(&constant), &jm_map, eq_index, by_name, literals)?,
                    build_eq_fn_single(&eq_units(&column), &jm_map, eq_index, by_name, literals)?,
                ]))
            })();
            match attempt {
                Ok(fns) => {
                    openmodelica_error::ErrorExt::delCheckpoint(JAC_CHECKPOINT);
                    built = Some(fns);
                }
                Err(_) => {
                    openmodelica_error::ErrorExt::rollBack(JAC_CHECKPOINT);
                    plan.jacs[k] = None;
                }
            }
        }
        let (lin, pair) = built.unwrap_or_else(|| (empty_eqfn(), [empty_eqfn(), empty_eqfn()]));
        linz_fns.push(lin);
        match k {
            0 => jac_a_fns = Some(pair),
            _ => opt_fns.extend(pair),
        }
        out_off += plan.rows[k] * plan.cols[k] * 8;
    }
    let mut adj_fns = [empty_eqfn(), empty_eqfn()];
    if plan.jacs[0].is_none() {
        plan.adj = None;
    }
    if let (Some(jm), Some(adj_map)) = (plan.adj.clone(), adj_map) {
        openmodelica_error::ErrorExt::setCheckpoint(JAC_CHECKPOINT);
        let attempt = (|| -> Result<[we::Function; 2]> {
            let (constant, column) = optimization::jac_eqns(&jm);
            let jm_map = with_jac_calls(adj_map, &jm);
            Ok([
                build_eq_fn_single(&eq_units(&constant), &jm_map, eq_index, by_name, literals)?,
                build_eq_fn_single(&eq_units(&column), &jm_map, eq_index, by_name, literals)?,
            ])
        })();
        match attempt {
            Ok(fns) => {
                openmodelica_error::ErrorExt::delCheckpoint(JAC_CHECKPOINT);
                adj_fns = fns;
            }
            Err(_) => {
                openmodelica_error::ErrorExt::rollBack(JAC_CHECKPOINT);
                plan.adj = None;
            }
        }
    }
    Ok((linz_fns, jac_a_fns.unwrap_or_else(|| [empty_eqfn(), empty_eqfn()]), opt_fns, adj_fns))
}

/// The matrix's own `generic_loop_calls` (C's `genericCall_jac_<i>`) in front of
/// the model's.
fn with_jac_calls(var_map: &SimVarMap, jm: &SimCode::JacobianMatrix) -> SimVarMap {
    let mut out = var_map.clone();
    if lst(&jm.generic_loop_calls).next().is_some() {
        let mut calls = (*out.generic_calls).clone();
        for c in lst(&jm.generic_loop_calls) {
            calls.insert(generic_call_index(c), c.clone());
        }
        out.generic_calls = Arc::new(calls);
    }
    out
}

/// Build one `linearJac<X>(SimData*)`: C's `functionJacX` loop moved into the
/// model, so the driver reads a finished matrix.
#[allow(clippy::too_many_arguments)]
fn build_linz_jac_fn(
    plan: &LinzPlan,
    info: &LinzJacInfo,
    k: usize,
    out_off: u32,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let jm = plan.jacs[k].as_ref().ok_or("CodegenWasmJit: no linearization Jacobian")?;
    let col = lst(&jm.columns).next();
    let constant_eqns: Vec<Arc<SimCode::SimEqSystem>> =
        col.map(|c| lst(&c.constantEqns).cloned().collect()).unwrap_or_default();
    let column_eqns: Vec<Arc<SimCode::SimEqSystem>> =
        col.map(|c| lst(&c.columnEqns).cloned().collect()).unwrap_or_default();
    let mut ctx = FnCtx::new_sim(sim_ctx(var_map), by_name, literals);
    let mut lower = |c: &mut FnCtx, eqs: &[Arc<SimCode::SimEqSystem>]| -> Result<()> {
        for eq in eqs {
            lower_equation(c, eq, eq_index)?;
        }
        Ok(())
    };
    lower(&mut ctx, &constant_eqns)?;
    crate::CodegenWasmJitFunctions::emit_linz_jac_body(
        &mut ctx,
        out_off,
        plan.rows[k] as usize,
        &info.seed_offs,
        &info.result_offs,
        &mut |c: &mut FnCtx| lower(c, &column_eqns),
    )?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// A linear system's `A x = b` row count, `None` if it is not static.
fn lin_n_res(lsystem: &SimCode::LinearSystem) -> Option<usize> {
    residual_rows(&lin_residuals(lsystem, &mut Vec::new()))
}

/// Usable torn linear systems, deduped by index. `lin_jac_scratch_f64` (reserve)
/// and `build_lin_jac_infos` (register) both call this so they agree on the set.
fn lin_jac_systems(sim_code: &SimCode::SimCode) -> Vec<Arc<SimCode::LinearSystem>> {
    use SimCode::SimEqSystem as E;
    let mut seen: HashSet<i32> = HashSet::new();
    let mut out: Vec<Arc<SimCode::LinearSystem>> = Vec::new();
    let mut scan = |eqs: Vec<Arc<SimCode::SimEqSystem>>| {
        for e in &eqs_with_nested(&eqs) {
            if let E::SES_LINEAR { lSystem, alternativeTearing, .. } = &**e {
                // A dynamically torn component has two sets, each with its own Jacobian.
                for sys in std::iter::once(lSystem).chain(alternativeTearing.iter()) {
                    if sys.tornSystem && seen.insert(sys.index) && lin_jac_usable(sys, lin_n_res(sys)) {
                        out.push(sys.clone());
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
    // A differentiated algebraic loop is a torn linear system in a Jacobian column.
    for jm in lst(&sim_code.jacobianMatrices) {
        if !jac_lowerable(jm) {
            continue;
        }
        for col in lst(&jm.columns) {
            scan(flatten_eqs(&col.constantEqns));
            scan(flatten_eqs(&col.columnEqns));
        }
    }
    out
}

/// f64 scratch slots the torn-linear analytic Jacobians need: seeds + all column
/// variables per usable system. Reserved after the NLS portion of the Jacobian
/// scratch region.
pub(super) fn lin_jac_scratch_f64(sim_code: &SimCode::SimCode) -> u32 {
    let mut total = 0u32;
    for sys in lin_jac_systems(sim_code) {
        let jm = sys.jacobianMatrix.as_ref().unwrap();
        total += count(&jm.seedVars) as u32 + jac_column_vars(jm).len() as u32;
    }
    total
}

/// Register each torn-linear system's Jacobian seed/column-result crefs in the
/// Jacobian scratch region, starting after the NLS portion (`nls_jac_scratch_f64`).
/// The column equations then resolve their `$SEED`/`$pDER` slots when lowered, and
/// [`lin_jac_offsets`] reads the same slots back for assembly.
pub(super) fn build_lin_jac_infos(
    sim_code: &SimCode::SimCode,
    layout: &SimLayout,
    var_map: &mut SimVarMap,
) -> Result<()> {
    let mut cursor = layout.nls_jac_off + nls_jac_scratch_f64(sim_code) * 8;
    for sys in lin_jac_systems(sim_code) {
        let jm = sys.jacobianMatrix.as_ref().unwrap();
        let column_vars = jac_column_vars(jm);
        // As in `register_jac_slots`: an array base listed beside its elements gets
        // no slot, an access to it reaches the elements' through `array_acc`.
        let mut bases: HashSet<String> = HashSet::new();
        for sv in lst(&jm.seedVars).chain(column_vars.iter()) {
            if let Some((base, _)) = array_element_of(&sv.name)? {
                bases.insert(base);
            }
        }
        for sv in lst(&jm.seedVars).chain(column_vars.iter()) {
            let key = sim_cref_key(&sv.name)?;
            if bases.contains(&key) {
                continue;
            }
            let off = cursor;
            Arc::make_mut(&mut var_map.vars).insert(key, SimSlot { off, wty: WTy::F64, negate: Neg::None, heap: false });
            for g in array_element_keys(&sv.name)? {
                var_map.array_acc.entry(g.base).or_default().push(AccElem {
                    subs: g.subs,
                    pieces: g.pieces,
                    off,
                    wty: WTy::F64,
                    neg: Neg::None,
                    heap: false,
                });
            }
            cursor += 8;
        }
    }
    Ok(())
}

/// Seed slots (in `seedVars`/column order) and result slots (at residual row via
/// `jac_result_row`) for a torn-linear Jacobian, read from the slots
/// `build_lin_jac_infos` registered. Feeds `compile_linear_system_analytic`.
pub(super) fn lin_jac_offsets(lsystem: &SimCode::LinearSystem, vars: &HashMap<String, SimSlot>, n: usize) -> Result<(Vec<u32>, Vec<u32>)> {
    use openmodelica_backend_types::BackendDAE::VarKind;
    let jm = lsystem.jacobianMatrix.as_ref().ok_or("CodegenWasmJit: torn-linear system has no Jacobian")?;
    let lookup = |cr: &Arc<DAE::ComponentRef>| -> Result<u32> {
        let key = sim_cref_key(cr)?;
        Ok(vars.get(&key).ok_or("CodegenWasmJit: torn-linear Jacobian slot not registered")?.off)
    };
    let listed: Vec<u32> = lst(&jm.seedVars).map(|sv| lookup(&sv.name)).collect::<Result<_>>()?;
    let seed_offs = jac_seed_offs_by_column(jm, &listed, n)
        .ok_or("CodegenWasmJit: torn-linear Jacobian seed columns are not a permutation")?;
    let mut result_offs = vec![u32::MAX; n];
    for sv in &jac_column_vars(jm) {
        if matches!(sv.varKind, VarKind::JAC_VAR) {
            let row = jac_result_row(sv).filter(|&r| r < n)
                .ok_or("CodegenWasmJit: torn-linear Jacobian result var has no row index")?;
            result_offs[row] = lookup(&sv.name)?;
        }
    }
    if seed_offs.len() != n || result_offs.iter().any(|&o| o == u32::MAX) {
        return Err("CodegenWasmJit: torn-linear Jacobian seed/result mismatch");
    }
    Ok((seed_offs, result_offs))
}

/// Accumulate into `dep[lhs]` the seed columns that `eq`'s RHS depends on, for the
/// [`lin_jac_csc_pattern`] dataflow: a seed cref contributes its own column, any
/// other cref contributes its already-computed `dep` set (the column equations are
/// in dependency order). Only `SES_SIMPLE_ASSIGN` is handled; anything else -> None.
fn csc_accum_dep(
    eq: &Arc<SimCode::SimEqSystem>,
    seed_col: &HashMap<String, usize>,
    dep: &mut HashMap<String, Vec<usize>>,
) -> Option<()> {
    use SimCode::SimEqSystem as E;
    let E::SES_SIMPLE_ASSIGN { cref, exp, .. } = &**eq else { return None };
    let mut s: Vec<usize> = Vec::new();
    let crefs = openmodelica_frontend_base::Expression::extractCrefsFromExp(exp.clone()).ok()?;
    for cr in &*crefs {
        let k = sim_cref_key(cr).ok()?;
        if let Some(&c) = seed_col.get(&k) {
            if !s.contains(&c) { s.push(c); }
        } else if let Some(ds) = dep.get(&k) {
            for &c in ds { if !s.contains(&c) { s.push(c); } }
        }
    }
    dep.insert(sim_cref_key(cref).ok()?, s);
    Some(())
}

/// CSC pattern (`colptr`, `rowidx`, in `res_index` rows / iteration-variable cols)
/// of a torn-linear system's `A`, derived by propagating seed dependencies through
/// the Jacobian column equations: `A[row][col] != 0` iff the residual `row`'s
/// derivative depends on seed `col`. This is the true sparsity in the assembler's
/// own row order — the Jacobian's stored `sparsity` is in a dependent-var order
/// that does not map to `res_index`. Returns `None` for any unsupported equation
/// (caller falls back to dense assembly).
pub(super) fn lin_jac_csc_pattern(lsystem: &SimCode::LinearSystem, n: usize) -> Option<(Vec<i32>, Vec<i32>)> {
    use openmodelica_backend_types::BackendDAE::VarKind;
    let jm = lsystem.jacobianMatrix.as_ref()?;
    let col = lst(&jm.columns).next()?;
    let mut seed_col: HashMap<String, usize> = HashMap::new();
    for sv in lst(&jm.seedVars) {
        seed_col.insert(sim_cref_key(&sv.name).ok()?, usize::try_from(sv.index).ok()?);
    }
    let mut dep: HashMap<String, Vec<usize>> = HashMap::new();
    for eq in lst(&col.constantEqns) {
        csc_accum_dep(eq, &seed_col, &mut dep)?;
    }
    for eq in lst(&col.columnEqns) {
        csc_accum_dep(eq, &seed_col, &mut dep)?;
    }
    // Column c (iteration var) gets residual row r whenever result r depends on seed c.
    let mut cols: Vec<Vec<i32>> = vec![Vec::new(); n];
    for sv in &jac_column_vars(jm) {
        if !matches!(sv.varKind, VarKind::JAC_VAR) {
            continue;
        }
        let r = jac_result_row(sv).filter(|&r| r < n)?;
        if let Some(ds) = dep.get(&sim_cref_key(&sv.name).ok()?) {
            for &c in ds {
                if c >= n {
                    return None;
                }
                cols[c].push(r as i32);
            }
        }
    }
    let mut colptr = vec![0i32; n + 1];
    let mut rowidx = Vec::new();
    for c in 0..n {
        cols[c].sort_unstable();
        rowidx.extend_from_slice(&cols[c]);
        colptr[c + 1] = colptr[c] + cols[c].len() as i32;
    }
    if rowidx.is_empty() {
        return None;
    }
    Some((colptr, rowidx))
}

/// Build the `residual(sim_data, x, r)` and `load(sim_data, x)` callback
/// functions for one nonlinear system (the model-specific half of
/// `rt_solve_nls`, reached by `call_indirect` over the shared table).
///
/// `strict` is the strict tearing set's job when `nlsystem` is a casual one: a
/// fourth callback, `solve(sim_data) -> solved`, is then emitted for
/// `rt_solve_nls` to fall back to (C's `strictTearingFunctionCall`), and the
/// residual carries the casual set's local constraint checks.
#[allow(clippy::too_many_arguments)]
pub(super) fn build_nls_fns(
    nlsystem: &SimCode::NonlinearSystem,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
    jac_info: Option<&NlsJacInfo>,
    strict: Option<NlsJob>,
    pool: &mut ChunkPool,
    residual_ty: u32,
) -> Result<(NlsResidualFn, we::Function, Option<we::Function>, Option<we::Function>)> {
    let _fg = crate::CodegenWasmJitFunctions::FnNameGuard::new(&format!(
        "nonlinear system {}",
        nlsystem.index
    ));
    let (inner, residuals, iter_vars) = nls_parts(nlsystem)?;
    let mut slots: Vec<IterSlot> = Vec::with_capacity(iter_vars.len());
    for cr in &iter_vars {
        if is_homotopy_lambda(Some(cr)) {
            slots.push(IterSlot { off: var_map.lambda_off, wty: WTy::F64 });
            continue;
        }
        let slot = iteration_var_slot(&var_map.vars, &var_map.start_slots, cr)?
            .ok_or("CodegenWasmJit: nonlinear-system unknown has no slot")?;
        slots.push(slot);
    }
    let mk_sim = || sim_ctx(var_map);
    let finish = |ctx: FnCtx| -> we::Function {
        let (locals, instrs) = ctx.finish_sim();
        let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
        for i in &instrs {
            func.instruction(i);
        }
        func
    };

    // residual(sim_data, x, r): 3 params.
    let residual = build_residual_fn(
        nlsystem.index, &slots, &residuals, &inner, strict.is_some(), var_map, eq_index, by_name,
        literals, pool, residual_ty,
    )?;
    // load(sim_data, x): 2 params.
    let load = {
        let mut ctx = FnCtx::new_sim_params(mk_sim(), by_name, literals, 2);
        emit_nls_load_body(&mut ctx, &slots)?;
        finish(ctx)
    };
    // jac(sim_data, x, jptr): column-major `n×n` analytic Jacobian, emitted only
    // when the system carries a usable symbolic Jacobian.
    let jac = match (&nlsystem.jacobianMatrix, jac_info) {
        (Some(jm), Some(info)) => {
            let col = lst(&jm.columns)
                .next()
                .ok_or_else(|| "CodegenWasmJit: nonlinear-system Jacobian has no column")?;
            let constant_eqns: Vec<Arc<SimCode::SimEqSystem>> = lst(&col.constantEqns).cloned().collect();
            let column_eqns: Vec<Arc<SimCode::SimEqSystem>> = lst(&col.columnEqns).cloned().collect();
            // Bind this matrix's own seed/column slots over the shared map, which
            // holds whichever system registered the shared names last.
            let mut sim = mk_sim();
            let mut vars = (*sim.vars).clone();
            for (key, slot) in &info.slots {
                vars.insert(key.clone(), *slot);
            }
            sim.vars = Arc::new(vars);
            let mut ctx = FnCtx::new_sim_params(sim, by_name, literals, 3);
            let mut lower_inner = |c: &mut FnCtx| -> Result<()> {
                for eq in &inner {
                    lower_equation(c, eq, eq_index)?;
                }
                Ok(())
            };
            let mut lower_constant = |c: &mut FnCtx| -> Result<()> {
                for eq in &constant_eqns {
                    lower_equation(c, eq, eq_index)?;
                }
                Ok(())
            };
            let mut lower_column = |c: &mut FnCtx| -> Result<()> {
                for eq in &column_eqns {
                    lower_equation(c, eq, eq_index)?;
                }
                Ok(())
            };
            // Colored CSC assembly (C's `evalJacobian`) whenever the symbolic
            // sparsity is available: `#colors` column-equation passes instead of
            // `n`, into CSC values for a sparse system or a dense `n×n` otherwise.
            match nls_jac_pattern(jm, slots.len()) {
                Some(pat) => emit_nls_jac_csc_body(
                    &mut ctx, &slots, &info.seed_offs, &info.result_offs,
                    &pat.colptr, &pat.rowidx, &pat.colors,
                    !nls_use_sparse(slots.len(), pat.rowidx.len()),
                    &mut lower_inner, &mut lower_constant, &mut lower_column,
                )?,
                None => emit_nls_jac_body(
                    &mut ctx, &slots, &info.seed_offs, &info.result_offs,
                    &mut lower_inner, &mut lower_constant, &mut lower_column,
                )?,
            }
            Some(finish(ctx))
        }
        _ => None,
    };
    // solve(sim_data) -> solved: the strict tearing set, C's `eqFunction_<ls.index>`.
    let strict_fn = strict
        .map(|job| -> Result<we::Function> {
            let mut ctx = FnCtx::new_sim_params(mk_sim(), by_name, literals, 1);
            crate::CodegenWasmJitFunctions::emit_nls_strict_body(&mut ctx, job)?;
            Ok(finish(ctx))
        })
        .transpose()?;
    Ok((residual, load, jac, strict_fn))
}

/// A residual callback: one function, or [`ChunkPool`] positions a thunk calls in
/// order from the callback's own function index.
pub(super) enum NlsResidualFn {
    Whole(we::Function),
    Chunked(Vec<usize>),
}

/// Lower the `residual(sim_data, x, r)` callback, split past [`nls_chunk_instrs`]
/// as the equation entry points are, and for the same reason. A cut carries nothing
/// across: the pieces communicate through `SimData` and the `x`/`r` pointers.
///
/// Two shapes stay whole: an inverse-algorithm residual, whose saved outputs live in
/// locals across the inner equations, and a dynamic-tearing casual set, whose
/// local-constraint checks leave by `return` — which from a chunk would skip only the
/// rest of that chunk.
#[allow(clippy::too_many_arguments)]
fn build_residual_fn(
    index: i32,
    slots: &[IterSlot],
    residuals: &NlsResiduals,
    inner: &[Arc<SimCode::SimEqSystem>],
    strict: bool,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
    pool: &mut ChunkPool,
    residual_ty: u32,
) -> Result<NlsResidualFn> {
    let explicit = match residuals {
        NlsResiduals::Explicit(r) if !strict => r,
        _ => {
            let mut ctx = FnCtx::new_sim_params(sim_ctx(var_map), by_name, literals, 3);
            // C's `residualFuncConstraints` for a casual set: each inner equation's
            // `localCon` constraints are checked before it runs.
            ctx.set_dt_local_cons(strict);
            let mut lower_inner = |c: &mut FnCtx| -> Result<()> {
                for eq in inner {
                    lower_equation(c, eq, eq_index)?;
                }
                Ok(())
            };
            emit_nls_residual_body(&mut ctx, index, slots, residuals, &mut lower_inner)?;
            return Ok(NlsResidualFn::Whole(finish_fn(ctx)));
        }
    };
    let budget = nls_chunk_instrs();
    let mut fns: Vec<we::Function> = Vec::new();
    let (mut eq, mut store) = (0usize, 0usize);
    loop {
        let mut ctx = FnCtx::new_sim_params(sim_ctx(var_map), by_name, &mut *literals, 3);
        if fns.is_empty() {
            emit_nls_residual_prologue(&mut ctx, index, slots)?;
        }
        while eq < inner.len() {
            lower_equation(&mut ctx, &inner[eq], eq_index)?;
            eq += 1;
            if ctx.instr_len() >= budget {
                break;
            }
        }
        if eq == inner.len() {
            while store < explicit.len() {
                emit_nls_residual_store(&mut ctx, explicit, store)?;
                store += 1;
                if ctx.instr_len() >= budget {
                    break;
                }
            }
            if store == explicit.len() {
                emit_nls_residual_epilogue(&mut ctx, index)?;
            }
        }
        let done = eq == inner.len() && store == explicit.len();
        fns.push(finish_fn(ctx));
        if done {
            break;
        }
    }
    if fns.len() == 1 {
        return Ok(NlsResidualFn::Whole(fns.remove(0)));
    }
    let first = pool.len();
    for (n, f) in fns.into_iter().enumerate() {
        pool.push(f, residual_ty, format!("nonlinearSystem{index}_residual${n}"));
    }
    Ok(NlsResidualFn::Chunked((first..pool.len()).collect()))
}
