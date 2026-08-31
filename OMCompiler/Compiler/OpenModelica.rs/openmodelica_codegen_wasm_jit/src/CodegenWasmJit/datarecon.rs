//! `--preOptModules+=dataReconciliation`: the model side of C's
//! `dataReconciliation.cpp`.
//!
//! C generates `data_function`/`setc_function`/`setb_function` to copy variables
//! between `SimData` and three `simulationInfo` arrays; here the runtime addresses
//! the slots directly, so only the two symbolic Jacobians (`F` and `H`) need code
//! — built exactly like `-l`'s `linearJac*`, each filling one column-major matrix.

use std::collections::HashMap;
use std::sync::Arc;

use metamodelica::{List, Result};
use openmodelica_backend_types::BackendDAE;
use openmodelica_simcode_types::{SimCode, SimCodeVar};
use openmodelica_sim_meta::{Neg, ReconInfo, ReconJac, ReconVar};

use crate::CodegenWasmJit::{SimVarMap, count, jac_column_vars, jac_result_row, lst};
use crate::CodegenWasmJitFunctions::{FnCtx, FnInfo, Literals, SimSlot, WTy, sim_cref_key};

/// The two matrices, in the order they occupy the scratch region.
pub(crate) const JAC_FNS: [&str; 2] = ["reconJacF", "reconJacH"];

/// The `F`/`H` matrices the backend produced, with the shape C's `initJacobian`
/// would report.
pub(crate) struct ReconPlan {
    pub(crate) jacs: [Option<(Arc<SimCode::JacobianMatrix>, u32, u32)>; 2],
    /// Whether the model carries data-reconciliation variables at all.
    pub(crate) present: bool,
}

impl ReconPlan {
    /// The matrices themselves, then the seeds and column variables their columns
    /// assign — laid out behind `-l`'s scratch.
    pub(crate) fn n_scratch_f64(&self) -> u32 {
        if !self.present {
            return 0;
        }
        self.jacs
            .iter()
            .flatten()
            .map(|(jm, r, c)| r * c + count(&jm.seedVars) as u32 + jac_column_vars(jm).len() as u32)
            .sum()
    }

    /// Where matrix `k`'s output region starts, relative to `base`.
    fn matrix_off(&self, base: u32, k: usize) -> u32 {
        let mut off = base;
        for j in 0..k {
            if let Some((_, r, c)) = &self.jacs[j] {
                off += r * c * 8;
            }
        }
        off
    }
}

pub(crate) fn build_plan(sim_code: &SimCode::SimCode, vars: &SimCodeVar::SimVars) -> ReconPlan {
    let present = lst(&vars.dataReconinputVars).next().is_some();
    let names = ["F", "H"];
    let jacs = core::array::from_fn(|k| {
        if !present {
            return None;
        }
        let jm = lst(&sim_code.jacobianMatrices).find(|j| &*j.matrixName == names[k])?.clone();
        let cols = count(&jm.seedVars) as u32;
        let rows = matrix_rows(&jm);
        if rows == 0 || cols == 0 {
            return None;
        }
        let has_equations =
            lst(&jm.columns).next().is_some_and(|c| lst(&c.columnEqns).next().is_some());
        (has_equations && crate::CodegenWasmJit::jac_lowerable(&jm)).then_some((jm, rows, cols))
    });
    ReconPlan { jacs, present }
}

/// C's `sizeRows`, as `linearize::matrix_rows`: one past the last row a `JAC_VAR`
/// result or the sparsity pattern names.
fn matrix_rows(jm: &SimCode::JacobianMatrix) -> u32 {
    let results = jac_column_vars(jm)
        .iter()
        .filter(|v| matches!(v.varKind, BackendDAE::VarKind::JAC_VAR))
        .filter_map(jac_result_row)
        .map(|r| r as u32 + 1)
        .max()
        .unwrap_or(0);
    let sparse = lst(&jm.sparsity).flat_map(|(_, nz)| lst(nz)).map(|r| *r as u32 + 1).max().unwrap_or(0);
    results.max(sparse)
}

/// One matrix's seed slots (column order) and result slots (row order).
pub(crate) struct ReconJacInfo {
    pub(crate) seed_offs: Vec<u32>,
    pub(crate) result_offs: Vec<Option<u32>>,
    pub(crate) out_off: u32,
    pub(crate) rows: u32,
    pub(crate) cols: u32,
}

/// Register the Jacobians' seed / column-variable crefs behind the matrices.
pub(crate) fn build_jac_infos(
    plan: &ReconPlan,
    base: u32,
    var_map: &mut SimVarMap,
) -> Result<Vec<Option<ReconJacInfo>>> {
    use BackendDAE::VarKind;
    let mut cursor = plan.matrix_off(base, plan.jacs.len());
    let mut infos = Vec::with_capacity(2);
    for (k, jac) in plan.jacs.iter().enumerate() {
        let Some((jm, rows, cols)) = jac else {
            infos.push(None);
            continue;
        };
        let (rows, cols) = (*rows as usize, *cols as usize);
        let mut listed = Vec::new();
        for sv in lst(&jm.seedVars) {
            Arc::make_mut(&mut var_map.vars).insert(
                sim_cref_key(&sv.name)?,
                SimSlot { off: cursor, wty: WTy::F64, negate: Neg::None, heap: false },
            );
            listed.push(cursor);
            cursor += 8;
        }
        let mut result_offs = vec![None; rows];
        for sv in &jac_column_vars(jm) {
            Arc::make_mut(&mut var_map.vars).insert(
                sim_cref_key(&sv.name)?,
                SimSlot { off: cursor, wty: WTy::F64, negate: Neg::None, heap: false },
            );
            if matches!(sv.varKind, VarKind::JAC_VAR)
                && let Some(row) = jac_result_row(sv).filter(|&r| r < rows)
            {
                result_offs[row] = Some(cursor);
            }
            cursor += 8;
        }
        let seed_offs = crate::CodegenWasmJit::jac_seed_offs_by_column(jm, &listed, cols)
            .ok_or("CodegenWasmJit: data-reconciliation Jacobian seed columns are not a permutation")?;
        infos.push(Some(ReconJacInfo {
            seed_offs,
            result_offs,
            out_off: plan.matrix_off(base, k),
            rows: rows as u32,
            cols: cols as u32,
        }));
    }
    Ok(infos)
}

/// Lower `reconJacF` / `reconJacH`; a matrix that does not lower is dropped from
/// the plan, and the runtime reports it as C's `Cannot Compute Jacobian Matrix`.
#[allow(clippy::too_many_arguments)]
pub(crate) fn build_jac_fns(
    plan: &mut ReconPlan,
    infos: &mut [Option<ReconJacInfo>],
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<Vec<wasm_encoder::Function>> {
    let mut fns = Vec::new();
    for k in 0..2 {
        let built = match (plan.jacs[k].clone(), infos[k].as_ref()) {
            (Some((jm, _, _)), Some(info)) => {
                openmodelica_error::ErrorExt::setCheckpoint(crate::CodegenWasmJit::JAC_CHECKPOINT);
                let attempt = build_jac_fn(&jm, info, var_map, eq_index, by_name, literals);
                match attempt {
                    Ok(f) => {
                        openmodelica_error::ErrorExt::delCheckpoint(crate::CodegenWasmJit::JAC_CHECKPOINT);
                        Some(f)
                    }
                    Err(_) => {
                        openmodelica_error::ErrorExt::rollBack(crate::CodegenWasmJit::JAC_CHECKPOINT);
                        plan.jacs[k] = None;
                        infos[k] = None;
                        None
                    }
                }
            }
            _ => None,
        };
        fns.push(built.unwrap_or_else(crate::CodegenWasmJit::empty_eqfn));
    }
    Ok(fns)
}

fn build_jac_fn(
    jm: &SimCode::JacobianMatrix,
    info: &ReconJacInfo,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<wasm_encoder::Function> {
    use crate::CodegenWasmJit::{lower_equation, sim_ctx};
    let col = lst(&jm.columns).next();
    let constant_eqns: Vec<Arc<SimCode::SimEqSystem>> =
        col.map(|c| lst(&c.constantEqns).cloned().collect()).unwrap_or_default();
    let column_eqns: Vec<Arc<SimCode::SimEqSystem>> =
        col.map(|c| lst(&c.columnEqns).cloned().collect()).unwrap_or_default();
    let mut ctx = FnCtx::new_sim(sim_ctx(var_map), by_name, literals);
    let lower = |c: &mut FnCtx, eqs: &[Arc<SimCode::SimEqSystem>]| -> Result<()> {
        for eq in eqs {
            lower_equation(c, eq, eq_index)?;
        }
        Ok(())
    };
    lower(&mut ctx, &constant_eqns)?;
    crate::CodegenWasmJitFunctions::emit_linz_jac_body(
        &mut ctx,
        info.out_off,
        info.rows as usize,
        &info.seed_offs,
        &info.result_offs,
        &mut |c: &mut FnCtx| lower(c, &column_eqns),
    )?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = wasm_encoder::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// The three variable lists plus the Jacobians, as the runtime sees them.
pub(crate) fn build_recon_info(
    sim_code: &SimCode::SimCode,
    vars: &SimCodeVar::SimVars,
    plan: &ReconPlan,
    infos: &[Option<ReconJacInfo>],
    var_map: &SimVarMap,
    n_related_boundary: u32,
) -> Result<Option<ReconInfo>> {
    if !plan.present {
        return Ok(None);
    }
    let list = |l: &Arc<List<SimCodeVar::SimVar>>| -> Result<Vec<ReconVar>> {
        let mut out = Vec::new();
        for sv in lst(l) {
            let key = sim_cref_key(&sv.name)?;
            let slot = var_map
                .vars
                .get(&key)
                .ok_or("CodegenWasmJit: data-reconciliation variable has no SimData slot")?;
            out.push(ReconVar {
                off: slot.off,
                negate: slot.negate,
                name: crate::CodegenWasmJit::cref_display(&sv.name)?,
                unit: sv.displayUnit.to_string(),
                comment: sv.comment.to_string(),
            });
        }
        Ok(out)
    };
    let jac = |k: usize| -> Option<ReconJac> {
        let info = infos.get(k)?.as_ref()?;
        Some(ReconJac { rows: info.rows, cols: info.cols, off: info.out_off })
    };
    Ok(Some(ReconInfo {
        input_vars: list(&vars.dataReconinputVars)?,
        setc_vars: list(&vars.dataReconSetcVars)?,
        setb_vars: list(&vars.dataReconSetBVars)?,
        jac_f: jac(0),
        jac_h: jac(1),
        n_related_boundary,
        model_file: sim_code.modelInfo.fileName.to_string(),
        model_dir: sim_code.modelInfo.directory.to_string(),
        version: openmodelica_util::Settings::getVersionNr().to_string(),
    }))
}
