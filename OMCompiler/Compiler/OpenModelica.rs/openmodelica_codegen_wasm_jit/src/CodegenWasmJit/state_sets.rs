//! State sets: scratch layout, `StateSetInfo`, the state-set Jacobian.

use super::*;

/// Register each state set's Jacobian seed/column crefs at the scratch region and
/// collect the driver-side [`StateSetInfo`], so the emitted
/// `functionStateSetJacobians` works on the Jacobian's own storage.
pub(super) fn build_state_set_infos(
    state_sets: &List<SimCode::StateSet>,
    layout: &SimLayout,
    var_map: &mut SimVarMap,
) -> Result<Vec<StateSetInfo>> {
    use openmodelica_backend_types::BackendDAE::VarKind;
    let mut infos = Vec::new();
    let mut cursor = layout.stateset_off;
    let real_slot = |var_map: &SimVarMap, cr: &Arc<DAE::ComponentRef>| -> Result<u32> {
        let key = sim_cref_key(cr)?;
        let slot = var_map
            .vars
            .get(&key)
            .ok_or_else(|| "CodegenWasmJit: state-set variable has no slot")?;
        if slot.wty != WTy::F64 {
            return Err("CodegenWasmJit: state-set variable is not a Real variable");
        }
        Ok(slot.off)
    };
    for set in lst(state_sets) {
        let n_candidates = set.nCandidates.max(0) as u32;
        let n_states = set.nStates.max(0) as u32;
        let n_dummy = n_candidates - n_states;
        let jm = &set.jacobianMatrix;
        let register = |var_map: &mut SimVarMap, sv: &SimCodeVar::SimVar, cursor: &mut u32| -> Result<u32> {
            let off = *cursor;
            *cursor += 8;
            Arc::make_mut(&mut var_map.vars).insert(sim_cref_key(&sv.name)?, SimSlot { off, wty: WTy::F64, negate: Neg::None, heap: false });
            Ok(off)
        };

        // Seeds are listed in their own order; the driver wants Jacobian-column order.
        let listed: Vec<u32> = lst(&jm.seedVars)
            .map(|sv| register(var_map, &sv, &mut cursor))
            .collect::<Result<_>>()?;
        let seed_offs = jac_seed_offs_by_column(jm, &listed, n_candidates as usize)
            .ok_or("CodegenWasmJit: state-set Jacobian seed columns are not a permutation")?;

        let mut result_offs = vec![u32::MAX; n_dummy as usize];
        for sv in &jac_column_vars(jm) {
            let off = register(var_map, sv, &mut cursor)?;
            if matches!(sv.varKind, VarKind::JAC_VAR) {
                let row = jac_result_row(sv)
                    .filter(|&r| r < n_dummy as usize)
                    .ok_or("CodegenWasmJit: state-set Jacobian result var has no row index")?;
                result_offs[row] = off;
            }
        }
        if result_offs.contains(&u32::MAX) {
            return Err("CodegenWasmJit: state-set Jacobian has no result var for every row");
        }

        let candidate_offs: Vec<u32> = lst(&set.statescandidates)
            .map(|cr| real_slot(var_map, cr))
            .collect::<Result<_>>()?;
        let candidate_names: Vec<String> =
            lst(&set.statescandidates).map(|cr| cref_display(cr)).collect::<Result<_>>()?;
        let state_offs: Vec<u32> = lst(&set.states)
            .map(|cr| real_slot(var_map, cr))
            .collect::<Result<_>>()?;

        // `$STATESET.A` is an `nStates × nCandidates` integer selection matrix.
        // a_offs is row-major (the driver reads `a_offs[row*nc+col]`).
        let a_base_cref = openmodelica_frontend_dump::ComponentReferenceBasics::crefStripLastSubs(set.crA.clone())?;
        let a_base = sim_cref_key(&a_base_cref)?;
        let mut a_offs = Vec::new();
        for row in 1..=n_states {
            for c in 1..=n_candidates {
                let slot = stateset_a_slot(var_map, &a_base, row, c, n_candidates)
                    .ok_or_else(|| "CodegenWasmJit: state-set matrix entry has no slot")?;
                a_offs.push(slot.off);
            }
        }

        infos.push(StateSetInfo {
            n_candidates,
            n_states,
            n_dummy,
            candidate_offs,
            state_offs,
            a_offs,
            seed_offs,
            result_offs,
            candidate_names,
        });
    }
    Ok(infos)
}

/// Build `functionStateSetJacobians(SimData*)`: run every state set's Jacobian
/// `constantEqns` and `columnEqns` over the scratch slots. The driver seeds one
/// candidate at a time and reads back one Jacobian column
/// (`getAnalyticalJacobianSet` in C's `stateset.c`).
pub(super) fn build_stateset_jac_fn(
    state_sets: &List<SimCode::StateSet>,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut eqs: Vec<Arc<SimCode::SimEqSystem>> = Vec::new();
    for set in lst(state_sets) {
        for col in lst(&set.jacobianMatrix.columns) {
            eqs.extend(lst(&col.constantEqns).cloned());
            eqs.extend(lst(&col.columnEqns).cloned());
        }
    }
    build_eq_fn_single(&eq_units(&eqs), var_map, eq_index, by_name, literals)
}

/// Slot of the state-set selection-matrix entry `A[row,col]` (1-based). The backend
/// scalarizes `$STATESET{n}.A` either 2D (key `A[row][col]`) or flat row-major (key
/// `A[k]`, `k = (row-1)*nCandidates + col`); try the 2D key first, then the flat one.
fn stateset_a_slot<'a>(
    var_map: &'a SimVarMap,
    a_base: &str,
    row: u32,
    col: u32,
    n_candidates: u32,
) -> Option<&'a SimSlot> {
    var_map.vars.get(&format!("{a_base}[{row}][{col}]")).or_else(|| {
        let k = (row - 1) * n_candidates + col;
        var_map.vars.get(&format!("{a_base}[{k}]"))
    })
}

/// Byte offsets of the diagonal `$STATESET.A[n,n]` integer slots for every state
/// set, so [`FnCtx::emit_stateset_diag_init`] can seed an identity state
/// selection before initialisation (C's `initializeStateSetPivoting`). The A
/// matrix (`nStates × nCandidates`) is otherwise never assigned on this path — no
/// dynamic re-pivoting yet — so a fixed valid selection is what makes the
/// `set.x = A·candidates` systems solvable. `A[n,n]=1` (states = the first
/// `nStates` candidates) is a valid selection whenever those candidates stay
/// independent (true for the models in scope; a candidate going singular
/// mid-run would need the runtime `pivot`/`stateSelection` port).
pub(super) fn stateset_diag_offsets(
    state_sets: &List<SimCode::StateSet>,
    var_map: &SimVarMap,
) -> Result<Vec<u32>> {
    let mut offs = Vec::new();
    for set in lst(state_sets) {
        // `crA` names the first `A` element; strip its subscripts to the base `A`.
        let base_cref = openmodelica_frontend_dump::ComponentReferenceBasics::crefStripLastSubs(set.crA.clone())?;
        let base = sim_cref_key(&base_cref)?;
        let n_candidates = set.nCandidates.max(0) as u32;
        for n in 1..=set.nStates.max(0) as u32 {
            let slot = stateset_a_slot(var_map, &base, n, n, n_candidates)
                .ok_or_else(|| "CodegenWasmJit: state-set matrix entry has no slot")?;
            if slot.wty != WTy::I32 {
                return Err("CodegenWasmJit: state-set matrix entry is not an Integer variable");
            }
            offs.push(slot.off);
        }
    }
    Ok(offs)
}

/// Lower a `SES_NONLINEAR` (torn) system: emit the call to the runtime solver
/// `rt_solve_nls` for this system's pre-registered job. The Newton driver lives
/// in the runtime; the model contributes only the `residual`/`load` functions
/// (emitted by [`build_nls_fns`]) reached via `call_indirect`. The system's job
/// (shared-table slot + unknown count) was assigned in [`collect_nls_jobs`].
pub(super) fn lower_nonlinear_system(
    ctx: &mut FnCtx,
    nlsystem: &SimCode::NonlinearSystem,
    _eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
) -> Result<()> {
    let job = *ctx
        .sim()?
        .nls_jobs
        .get(&nlsystem.index)
        .ok_or_else(|| "CodegenWasmJit: SES_NONLINEAR was not registered for rt_solve_nls")?;
    emit_solve_nls_call(ctx, job)?;
    // The 0/1/2 return is dropped here — a failure surfaces through the `nls_fail`
    // flag, and only the strict-set function ([`emit_nls_strict_body`]) reads it.
    ctx.emit_drop();
    Ok(())
}
