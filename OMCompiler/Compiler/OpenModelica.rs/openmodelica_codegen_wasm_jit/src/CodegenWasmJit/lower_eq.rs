//! Lowering one `SimEqSystem`: assignments, arrays, dynamic tearing and
//! linear systems.

use super::*;

pub(super) fn lower_equation_inner(
    ctx: &mut FnCtx,
    eq: &SimCode::SimEqSystem,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
) -> Result<()> {
    use SimCode::SimEqSystem as E;
    if let Some(info) = eq_info(eq) {
        ctx.set_src_loc(info);
    }
    match eq {
        E::SES_SIMPLE_ASSIGN { cref, exp, .. } => {
            let lhs = DAE::Exp::CREF { componentRef: cref.clone(), ty: t_real() };
            ctx.sim_assign(&lhs, exp)
        }
        // Dynamic tearing: C's `createLocalConstraints` checks the `localCon`
        // constraints *before* the assignment, and only in the casual set's residual.
        E::SES_SIMPLE_ASSIGN_CONSTRAINTS { cref, exp, cons, .. } => {
            if ctx.dt_local_cons() {
                for (c, local) in dt_constraints(cons) {
                    if local {
                        crate::CodegenWasmJitFunctions::emit_dt_local_constraint(ctx, &c)?;
                    }
                }
            }
            let lhs = DAE::Exp::CREF { componentRef: cref.clone(), ty: t_real() };
            ctx.sim_assign(&lhs, exp)
        }
        // A whole-array assignment `lhs := exp` (lhs is already a cref expression,
        // exp an array-valued expression). For a model array variable this routes
        // through the whole-array scatter in `compile_sim_cref_assign`.
        E::SES_ARRAY_CALL_ASSIGN { lhs, exp, .. } => ctx.sim_assign(lhs, exp),
        // C's `equationGenericAssign`.
        E::SES_RESIZABLE_ASSIGN { call_index, iters, .. } => {
            emit_resizable_assign(ctx, *call_index, iters)
        }
        E::SES_GENERIC_ASSIGN { call_index, scal_indices, .. } => {
            emit_generic_assign(ctx, *call_index, scal_indices)
        }
        E::SES_ENTWINED_ASSIGN { call_order, single_calls, .. } => {
            emit_entwined_assign(ctx, call_order, single_calls, eq_index)
        }
        E::SES_LINEAR { lSystem, alternativeTearing: Some(at), .. } => {
            lower_dynamic_tearing(ctx, eq_index, DtSystem::Linear(lSystem, at))
        }
        E::SES_NONLINEAR { nlSystem, alternativeTearing: Some(at), .. } => {
            lower_dynamic_tearing(ctx, eq_index, DtSystem::Nonlinear(nlSystem, at))
        }
        E::SES_LINEAR { lSystem, .. } => lower_linear_system(ctx, lSystem, eq_index, -1),
        E::SES_NONLINEAR { nlSystem, .. } => lower_nonlinear_system(ctx, nlSystem, eq_index),
        E::SES_ALGORITHM { statements, .. } => ctx.sim_stmts(statements),
        // Inside a nonlinear system the residual function backs the known outputs
        // up around the body; standalone this is C's `equationAlgorithm`.
        E::SES_INVERSE_ALGORITHM { statements, knownOutputCrefs, insideNonLinearSystem, .. } => {
            if *insideNonLinearSystem {
                return ctx.sim_stmts(statements);
            }
            let known: Vec<Arc<DAE::ComponentRef>> = lst(knownOutputCrefs).cloned().collect();
            let saved = backup_known_outputs(ctx, &known)?;
            ctx.sim_stmts(statements)?;
            restore_known_outputs(ctx, &known, &saved)
        }
        E::SES_WHEN { conditions, whenStmtLst, elseWhen, .. } => {
            ctx.sim_when(conditions, whenStmtLst, elseWhen)
        }
        // C's `equationIfEquationAssign`.
        E::SES_IFEQUATION { ifbranches, elsebranch, .. } => {
            let mut depth = 0;
            for (cond, eqs) in lst(ifbranches) {
                ctx.sim_if_cond(cond)?;
                for e in lst(eqs) {
                    lower_equation(ctx, e, eq_index)?;
                }
                ctx.sim_else();
                depth += 1;
            }
            for e in lst(elsebranch) {
                lower_equation(ctx, e, eq_index)?;
            }
            for _ in 0..depth {
                ctx.sim_end_block();
            }
            Ok(())
        }
        // An alias equation re-runs another equation (by index): inline it.
        E::SES_ALIAS { aliasOf, .. } => {
            let target = eq_index
                .get(aliasOf)
                .ok_or_else(|| "SES_ALIAS references unknown equation index")?
                .clone();
            lower_equation(ctx, &target, eq_index)
        }
        other => Err(eq_kind_name(other)),
    }
}

/// Dynamic tearing (`--dynamicTearing`): the two tearing sets of one torn strong
/// component. `Linear`/`Nonlinear` carry `(strict, casual)`, C's `lSystem`/`nlSystem`
/// and its `alternativeTearing`.
enum DtSystem<'a> {
    Linear(&'a Arc<SimCode::LinearSystem>, &'a Arc<SimCode::LinearSystem>),
    Nonlinear(&'a Arc<SimCode::NonlinearSystem>, &'a Arc<SimCode::NonlinearSystem>),
}

/// Every `CONSTRAINT_DT` of an equation's constraint list, as `(condition, local)`.
pub(crate) fn dt_constraints(cons: &List<Arc<DAE::Constraint>>) -> Vec<(Arc<DAE::Exp>, bool)> {
    lst(cons)
        .filter_map(|c| match &**c {
            DAE::Constraint::CONSTRAINT_DT { constraint, localCon } => {
                Some((constraint.clone(), *localCon))
            }
            _ => None,
        })
        .collect()
}

/// Every constraint a casual tearing set's inner equations carry, in C's order
/// (`createGlobalConstraints` over `at.eqs` / `at.residual`).
fn dt_system_constraints(sys: &DtSystem) -> Vec<(Arc<DAE::Exp>, bool)> {
    use SimCode::SimEqSystem as E;
    let inner: Vec<Arc<SimCode::SimEqSystem>> = match sys {
        DtSystem::Linear(_, at) => lst(&at.residual).cloned().collect(),
        DtSystem::Nonlinear(_, at) => lst(&at.eqs).cloned().collect(),
    };
    let mut out = Vec::new();
    for e in &inner {
        if let E::SES_SIMPLE_ASSIGN_CONSTRAINTS { cons, .. } = &**e {
            out.extend(dt_constraints(cons));
        }
    }
    out
}

/// Lower a dynamically torn strong component, C's `equation*AlternativeTearing`:
/// announce the casual set, check its constraints, solve it; a violated constraint
/// (or, for a linear system, a failed solve) falls through to the strict set. A
/// *nonlinear* casual set's failed solve is handled inside `rt_solve_nls`, where
/// C's `solveNLS` calls `strictTearingFunctionCall`.
fn lower_dynamic_tearing(
    ctx: &mut FnCtx,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    sys: DtSystem,
) -> Result<()> {
    let linear = matches!(sys, DtSystem::Linear(..));
    let (strict_index, casual_index) = match &sys {
        DtSystem::Linear(ls, at) => (ls.index, at.index),
        DtSystem::Nonlinear(nls, at) => (nls.index, at.index),
    };
    let cons = dt_system_constraints(&sys);
    let mut lower_casual = |c: &mut FnCtx| -> Result<()> {
        match &sys {
            DtSystem::Linear(_, at) => lower_linear_system(c, at, eq_index, strict_index),
            DtSystem::Nonlinear(_, at) => lower_nonlinear_system(c, at, eq_index),
        }
    };
    let mut lower_strict = |c: &mut FnCtx| -> Result<()> {
        match &sys {
            DtSystem::Linear(ls, _) => lower_linear_system(c, ls, eq_index, -1),
            DtSystem::Nonlinear(nls, _) => lower_nonlinear_system(c, nls, eq_index),
        }
    };
    crate::CodegenWasmJitFunctions::emit_dynamic_tearing(
        ctx, casual_index, strict_index, linear, &cons, &mut lower_casual, &mut lower_strict,
    )
}

/// Lower a `SES_LINEAR` system. Matching the C runtime, `A` is assembled
/// symbolically from `simJac` (`(row, col, SES_RESIDUAL(exp))`, 0-based,
/// column-major) and `b` from `beqs` — `setLinearMatrixA`/`setLinearVectorb` —
/// rather than by residual probing; [`compile_linear_system_symbolic`] then solves
/// dense or sparse per the density/size threshold. For a torn system the
/// `residual` list's non-`SES_RESIDUAL` entries are the inner equations that
/// recover the non-iteration torn variables, run once at the solution.
///
/// The residual-probing path ([`compile_linear_system`]) is the fallback for the
/// rare system without a usable `simJac`.
///
/// `dt_strict`: the strict set's equation index when `lsystem` is a casual tearing
/// set (whose `LOG_DT` line the caller has already printed, ahead of the constraint
/// check), or -1 for a system solved on its own.
pub(super) fn lower_linear_system(
    ctx: &mut FnCtx,
    lsystem: &SimCode::LinearSystem,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    dt_strict: i32,
) -> Result<()> {
    // C's `equationLinear` line; the casual variant is printed at the call site.
    if dt_strict < 0 {
        crate::CodegenWasmJitFunctions::emit_dt_solving(ctx, lsystem.index, -1, true)?;
    }
    // Only the casual set itself hands a failed solve to the strict set; a system
    // nested in its inner equations reports its own, as C's own function does.
    let saved = ctx.dt_fallback();
    if dt_strict < 0 {
        ctx.set_dt_fallback(None);
    }
    // C measures `solve_linear_system` from before the `A`/`b` assembly, which here
    // is emitted code rather than a runtime call, so the bracket spans the system.
    let n = lst(&lsystem.vars).count() as i32;
    crate::CodegenWasmJitFunctions::emit_ls_bracket(ctx, lsystem.index, n, lin_system_nnz(lsystem) as i32, true)?;
    let r = lower_linear_system_body(ctx, lsystem, eq_index);
    ctx.set_dt_fallback(saved);
    r?;
    crate::CodegenWasmJitFunctions::emit_ls_bracket(ctx, lsystem.index, n, 0, false)
}

fn lower_linear_system_body(
    ctx: &mut FnCtx,
    lsystem: &SimCode::LinearSystem,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
) -> Result<()> {
    use SimCode::SimEqSystem as E;
    let mut inner: Vec<Arc<SimCode::SimEqSystem>> = Vec::new();
    let residuals = lin_residuals(lsystem, &mut inner);
    let torn = !residuals.is_empty();
    let vars: Vec<Arc<DAE::ComponentRef>> = lst(&lsystem.vars).map(|v| v.name.clone()).collect();
    let n = vars.len();

    // A from simJac, b from beqs. `usable` false if any entry is not an ordinary
    // scalar residual (e.g. a for-residual we can't index statically).
    let mut a_entries: Vec<(usize, usize, &Arc<DAE::Exp>)> = Vec::new();
    let mut usable = true;
    for entry in lst(&lsystem.simJac) {
        let (row, col, eq) = entry;
        match &**eq {
            E::SES_RESIDUAL { exp, .. } => a_entries.push((*row as usize, *col as usize, exp)),
            _ => {
                usable = false;
                break;
            }
        }
    }
    let b_exps: Vec<&Arc<DAE::Exp>> = lst(&lsystem.beqs).collect();

    if usable && !a_entries.is_empty() && b_exps.len() == n {
        // Torn systems recover their inner variables at the solution; the non-torn
        // form has none (its `inner` is empty regardless).
        let mut lower_inner = |c: &mut FnCtx| -> Result<()> {
            if torn {
                for eq in &inner {
                    lower_equation(c, eq, eq_index)?;
                }
            }
            Ok(())
        };
        return compile_linear_system_symbolic(ctx, &vars, n, &a_entries, &b_exps, &mut lower_inner, lsystem.index);
    }

    // Only a torn system supplies the residuals both assembly paths need.
    if !torn {
        return Err("CodegenWasmJit: SES_LINEAR has neither a usable simJac nor residual equations");
    }
    let use_sparse = lin_torn_use_sparse(lsystem, n);
    let mut lower_inner = |c: &mut FnCtx| -> Result<()> {
        for eq in &inner {
            lower_equation(c, eq, eq_index)?;
        }
        Ok(())
    };

    // Prefer analytic-Jacobian assembly (C's method 1); probe only when there is no
    // usable Jacobian (its slots were registered by `build_lin_jac_infos`).
    if lin_jac_usable(lsystem, residual_rows(&residuals)) {
        let (seed_offs, result_offs) = {
            let vars = &ctx.sim()?.vars;
            lin_jac_offsets(lsystem, vars, n)?
        };
        let jm = lsystem.jacobianMatrix.as_ref().unwrap();
        let col = lst(&jm.columns).next().unwrap();
        let constant_eqns: Vec<Arc<SimCode::SimEqSystem>> = lst(&col.constantEqns).cloned().collect();
        let column_eqns: Vec<Arc<SimCode::SimEqSystem>> = lst(&col.columnEqns).cloned().collect();
        let mut lower_constant = |c: &mut FnCtx| -> Result<()> {
            for eq in &constant_eqns { lower_equation(c, eq, eq_index)?; }
            Ok(())
        };
        let mut lower_column = |c: &mut FnCtx| -> Result<()> {
            for eq in &column_eqns { lower_equation(c, eq, eq_index)?; }
            Ok(())
        };
        // Sparse: assemble straight into CSC (no dense n² buffer) when the pattern
        // remaps cleanly to res_index rows; otherwise dense A + runtime nonzero scan.
        if use_sparse {
            if let Some((colptr, rowidx)) = lin_jac_csc_pattern(lsystem, n) {
                return compile_linear_system_analytic_csc(
                    ctx, lsystem.index, &vars, &residuals, &seed_offs, &result_offs, &colptr, &rowidx,
                    &mut lower_inner, &mut lower_constant, &mut lower_column,
                );
            }
        }
        return compile_linear_system_analytic(
            ctx, &vars, &residuals, &seed_offs, &result_offs,
            &mut lower_inner, &mut lower_constant, &mut lower_column, use_sparse, lsystem.index,
        );
    }

    // C keys `method` off `ls.jacobianMatrix` alone, not off whether it assembles
    // `A` from one.
    compile_linear_system(ctx, &vars, &residuals, &mut lower_inner, use_sparse, lsystem.jacobianMatrix.is_some(), lsystem.index)
}

/// Whether a torn linear system uses the sparse solver (C's density/size
/// threshold), an unknown nonzero count counting as dense.
fn lin_torn_use_sparse(lsystem: &SimCode::LinearSystem, n: usize) -> bool {
    use crate::CodegenWasmJitFunctions::lin_use_sparse;
    if n == 0 {
        return false;
    }
    let nnz = lin_system_nnz(lsystem);
    nnz > 0 && lin_use_sparse(n, nnz)
}

/// Total f64 count of the state-set Jacobian scratch region: the seeds plus every
/// variable the column equations write.
pub(super) fn stateset_scratch_f64(state_sets: &List<SimCode::StateSet>) -> Result<u32> {
    let mut n = 0u32;
    for set in lst(state_sets) {
        n += count(&set.jacobianMatrix.seedVars) as u32 + jac_column_vars(&set.jacobianMatrix).len() as u32;
    }
    Ok(n)
}
