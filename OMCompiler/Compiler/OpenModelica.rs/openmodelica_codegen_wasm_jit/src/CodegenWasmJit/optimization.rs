//! `method="optimization"`: what the ported Ipopt collocation solver needs from the
//! model, i.e. `CodegenC.tpl`'s `optimizationComponents` (`<model>_13opt.c`) and the
//! `realVarsData[i].attribute` values C reads out of the `_init.xml`.
//!
//! The symbolic B/C/D themselves come from the same lowering the `-l` linearization
//! uses (`LinzPlan`); this module adds the per-column entry point the optimizer
//! drives them through, and assembles [`OptInfo`].

use std::collections::HashMap;
use std::string::String;
use std::sync::Arc;

use openmodelica_backend_types::BackendDAE;
use openmodelica_simcode_types::{SimCode, SimCodeVar};
use openmodelica_sim_meta::{OptInfo, OptJac, OptTerm};

use crate::CodegenWasmJit::{count, lst};

/// C's `BackendDAE.optimizationMayerTermName` / `optimizationLagrangeTermName`.
const MAYER_TERM: &str = "$OMC$objectMayerTerm";
const LAGRANGE_TERM: &str = "$OMC$objectLagrangeTerm";

/// Whether the model carries an optimization problem: the backend emitted the
/// class attributes `optimize()` sets `+gDynOpt` for. `ClassAttributes` has the
/// single record `OPTIMIZATION_ATTRS`, so a non-empty list *is* the answer.
pub(crate) fn is_optimization(sim_code: &SimCode::SimCode) -> bool {
    lst(&sim_code.classAttributes).next().is_some()
}

/// The real variables C appends after the algebraics: the path and then the final
/// constraints.
pub(crate) fn constraint_vars(
    vars: &SimCodeVar::SimVars,
) -> Vec<&SimCodeVar::SimVar> {
    lst(&vars.realOptimizeConstraintsVars)
        .chain(lst(&vars.realOptimizeFinalConstraintsVars))
        .collect()
}

/// The per-real-variable attribute values C reads from the `_init.xml`, as the
/// constant defaults the emitted `functionUpdateBoundVariableAttributes` stores.
/// A parameter-dependent attribute overwrites its slot there; these are the
/// literals (and C's fallbacks for an attribute the model never gives).
pub(crate) struct AttrDefaults {
    /// `(offset, value)` for the three f64 regions.
    pub reals: Vec<(u32, f64)>,
    /// `(offset, value)` for the `useNominal` i32 region.
    pub ints: Vec<(u32, i32)>,
}

/// Collect them for `reals` in real-variable index order (states, derivatives,
/// algebraics, constraints) and register the parameter-dependent ones in
/// `attr_targets` so they are updated after `functionParameters`.
pub(crate) fn attr_defaults(
    reals: &[&SimCodeVar::SimVar],
    layout: &openmodelica_sim_meta::Layout,
    attr_targets: &mut HashMap<String, crate::CodegenWasmJitFunctions::AttrTargets>,
) -> AttrDefaults {
    let mut out = AttrDefaults { reals: Vec::new(), ints: Vec::new() };
    for (i, sv) in reals.iter().enumerate() {
        let i = i as u32;
        // C's `dummyREAL_ATTRIBUTE` / the xml reader's defaults.
        for (base, exp, fallback) in [
            (layout.opt_min_off, &sv.minValue, -f64::MAX),
            (layout.opt_max_off, &sv.maxValue, f64::MAX),
            (layout.opt_nom_off, &sv.nominalValue, 1.0),
        ] {
            let off = base + i * 8;
            out.reals.push((off, crate::CodegenWasmJit::const_value(exp).unwrap_or(fallback)));
            if let Ok(k) = crate::CodegenWasmJit::sim_cref_key(&sv.name) {
                let t = attr_targets.entry(k).or_default();
                if base == layout.opt_min_off {
                    t.opt_min_offs.push(off);
                } else if base == layout.opt_max_off {
                    t.opt_max_offs.push(off);
                } else {
                    t.opt_nom_offs.push(off);
                }
            }
        }
        out.ints.push((layout.opt_use_nom_off + i * 4, use_nominal(sv) as i32));
    }
    out
}

/// C's `attribute.useNominal`: the model declared a `nominal`.
fn use_nominal(sv: &SimCodeVar::SimVar) -> bool {
    sv.nominalValue.is_some()
}

/// [`OptInfo`] for the model, or `None` when it carries no optimization problem.
/// `reals` is the real-variable list in index order and `jacs` the lowered B/C/D
/// with their slots, as `build_linz_jac_infos` registered them.
#[allow(clippy::too_many_arguments)]
pub(crate) fn build_opt_info(
    sim_code: &SimCode::SimCode,
    vars: &SimCodeVar::SimVars,
    reals: &[&SimCodeVar::SimVar],
    jacs: [Option<OptJac>; 3],
    var_map: &crate::CodegenWasmJit::SimVarMap,
) -> Result<Option<OptInfo>, &'static str> {
    if !is_optimization(sim_code) {
        return Ok(None);
    }
    let index_of = |sv: &SimCodeVar::SimVar| -> Option<u32> {
        let key = crate::CodegenWasmJit::sim_cref_key(&sv.name).ok()?;
        reals
            .iter()
            .position(|r| crate::CodegenWasmJit::sim_cref_key(&r.name).ok().as_deref() == Some(key.as_str()))
            .map(|i| i as u32)
    };
    // The optimizer's `u`, as C's `pickUpBoundsForInputsInOptimization` collects it:
    // the real inputs, whose bounds it reads out of the real region.
    let mut inputs: Vec<u32> = Vec::new();
    // C's `OPT_LOOP_INPUT`: the input takes another variable's value when the guess
    // comes from a file (`setInputData(data, 1)`).
    let mut loop_inputs = Vec::new();
    for sv in lst(&vars.inputVars) {
        let Some(index) = index_of(sv) else { continue };
        if let BackendDAE::VarKind::OPT_LOOP_INPUT { replaceExp } = &sv.varKind
            && let Some(src) = reals.iter().position(|r| {
                crate::CodegenWasmJit::sim_cref_key(&r.name).ok()
                    == crate::CodegenWasmJit::sim_cref_key(replaceExp).ok()
            })
        {
            loop_inputs.push((inputs.len() as u32, src as u32));
        }
        inputs.push(index);
    }
    // The objective terms: their own real index, and the Jacobian row their
    // derivative lands in — C reads the row off the `$pDER` cref's `SimVar.index`.
    let term = |name: &str| -> Option<OptTerm> {
        let index = reals.iter().position(|r| {
            crate::CodegenWasmJit::sim_cref_key(&r.name).is_ok_and(|k| k == name)
        })? as u32;
        Some(OptTerm {
            index,
            row_b: term_row(sim_code, "B", name),
            row_c: term_row(sim_code, "C", name),
        })
    };
    // C's `getTimeGrid`: the `$OPT_TGRID` parameters, in parameter order.
    let tgrid: Vec<u32> = lst(&vars.paramVars)
        .filter(|sv| matches!(sv.varKind, BackendDAE::VarKind::OPT_TGRID { .. }))
        .filter_map(|sv| {
            crate::CodegenWasmJit::sim_cref_key(&sv.name)
                .ok()
                .and_then(|k| var_map.vars.get(&k).map(|s| s.off))
        })
        .collect();
    // C's `realVarsData[i].info.name`, which the optimizer's messages quote.
    let real_names: Vec<String> = reals
        .iter()
        .map(|sv| {
            let n = crate::CodegenWasmJit::cref_display(&sv.name).unwrap_or_default();
            match n.strip_prefix("$DER.") {
                Some(base) => format!("der({base})"),
                None => n,
            }
        })
        .collect();
    let [jac_b, jac_c, jac_d] = jacs;
    Ok(Some(OptInfo {
        n_con: count(&vars.realOptimizeConstraintsVars) as u32,
        n_final_con: count(&vars.realOptimizeFinalConstraintsVars) as u32,
        inputs,
        loop_inputs,
        real_names,
        mayer: term(MAYER_TERM),
        lagrange: term(LAGRANGE_TERM),
        tgrid,
        // The Optimica `startTime` class attribute would start a pre-simulation;
        // not emitted yet, so the optimizer uses C's `startTime - 1.0` default.
        start_time_opt: None,
        jac_b,
        jac_c,
        jac_d,
    }))
}

/// The row of matrix `matrix` holding `term`'s derivative: the `JAC_VAR` result
/// whose cref is `<term>.$pDER<matrix>.dummyVar<matrix>`, which is what C's
/// template looks up with `crefToIndex(createDifferentiatedCrefName(...))`.
fn term_row(sim_code: &SimCode::SimCode, matrix: &str, term: &str) -> Option<u32> {
    let jm = lst(&sim_code.jacobianMatrices).find(|j| &*j.matrixName == matrix)?;
    let prefix = format!("{term}.$pDER{matrix}.");
    crate::CodegenWasmJit::jac_column_vars(jm)
        .iter()
        .filter(|v| matches!(v.varKind, BackendDAE::VarKind::JAC_VAR))
        .find(|v| {
            crate::CodegenWasmJit::sim_cref_key(&v.name).is_ok_and(|k| k.starts_with(&prefix))
        })
        .and_then(crate::CodegenWasmJit::jac_result_row)
        .map(|r| r as u32)
}

/// One matrix's [`OptJac`]: its shape, sparsity, colouring and the slots the
/// optimizer seeds and reads, plus the names of the two exports that evaluate it.
#[allow(clippy::too_many_arguments)]
pub(crate) fn opt_jac(
    jm: &SimCode::JacobianMatrix,
    rows: u32,
    cols: u32,
    seed_offs: &[u32],
    result_offs: &[Option<u32>],
    column_fn: &str,
    const_fn: &str,
) -> OptJac {
    // `sparsity` is positional per column; a column with no entry is structurally
    // zero. C reads the same pattern out of the `_JacX.bin` file.
    let mut rows_by_col: Vec<Vec<u32>> = vec![Vec::new(); cols as usize];
    for (i, (_, nz)) in lst(&jm.sparsity).enumerate() {
        if let Some(slot) = rows_by_col.get_mut(i) {
            *slot = lst(nz).map(|r| *r as u32).filter(|r| *r < rows).collect();
        }
    }
    let colors: Vec<Vec<u32>> = lst(&jm.coloredCols)
        .map(|grp| lst(grp).map(|c| *c as u32).filter(|c| *c < cols).collect())
        .collect();
    // C evaluates one column per colour when the backend gave no colouring.
    let colors = if colors.iter().all(Vec::is_empty) {
        (0..cols).map(|c| vec![c]).collect()
    } else {
        colors
    };
    OptJac {
        n_cols: cols,
        n_rows: rows,
        colors,
        rows_by_col,
        seed_offs: seed_offs.to_vec(),
        // A structurally-zero row is never read, so its slot is irrelevant; 0 keeps
        // the vector dense (the optimizer indexes it by row).
        result_offs: result_offs.iter().map(|o| o.unwrap_or(0)).collect(),
        column_fn: column_fn.to_string(),
        const_fn: const_fn.to_string(),
    }
}

/// The equations of one Jacobian's column, split as the optimizer calls them:
/// `constantEqns` once per evaluation point, `columnEqns` once per colour.
pub(crate) fn jac_eqns(
    jm: &SimCode::JacobianMatrix,
) -> (Vec<Arc<SimCode::SimEqSystem>>, Vec<Arc<SimCode::SimEqSystem>>) {
    let Some(col) = lst(&jm.columns).next() else { return (Vec::new(), Vec::new()) };
    (
        lst(&col.constantEqns).cloned().collect(),
        lst(&col.columnEqns).cloned().collect(),
    )
}
