//! `SimMeta` construction: units, start/parameter tables, attribute logs and
//! the relation/zero-crossing descriptions.

use super::*;

/// The `modelica.units` table: every unit the result variables name, with its SI
/// dimensions and the conversion to each display unit they name.
///
/// The SI dimensions come from `modelInfo.unitDefinitions`, which the FMI
/// exporter already builds; the display conversion comes from the unit database
/// itself (`SimCodeUtil.unitConversion`, which is `convertUnits`), because in
/// that list a display unit is a top-level unit and collides with a variable
/// declaring the same name as its own unit.
pub(super) fn collect_unit_defs(mi: &SimCode::ModelInfo, result_vars: &[ResultVar]) -> Vec<UnitDef> {
    let base_of = |name: &str| {
        lst(&mi.unitDefinitions).find(|u| u.name.as_str() == name).and_then(|u| match u.baseUnit {
            SimCode::BASEUNIT { s, m, kg, A, K, mol, cd, factor, offset } => {
                Some(BaseUnit { exponents: [kg, m, s, A, K, mol, cd, 0], factor: factor.into_inner(), offset: offset.into_inner() })
            }
            SimCode::NOBASEUNIT => None,
        })
    };
    let mut units: Vec<UnitDef> = Vec::new();
    for v in result_vars.iter().filter(|v| !v.unit.is_empty()) {
        let at = match units.iter().position(|u| u.name == v.unit) {
            Some(i) => i,
            None => {
                units.push(UnitDef { name: v.unit.clone(), base: base_of(&v.unit), display_units: Vec::new() });
                units.len() - 1
            }
        };
        if v.display_unit.is_empty() || v.display_unit == v.unit || units[at].display_unit(&v.display_unit).is_some() {
            continue;
        }
        // v_display = factor * v_unit + offset, FMI's own <DisplayUnit>.
        let (converts, factor, offset) =
            openmodelica_backend::SimCodeUtil::unitConversion(ArcStr::from(v.display_unit.as_str()), ArcStr::from(v.unit.as_str()));
        if converts {
            units[at].display_units.push(DisplayUnit::new(&v.display_unit, factor.into_inner(), offset.into_inner()));
        }
    }
    units
}

/// Assemble the [`openmodelica_sim_meta::SimMeta`] embedded in the model module
/// (decoded by both the in-wasm driver and the standalone `_start`) from the
/// resolved layout, result variables, run settings and solver metadata. The
/// layout / result-var / solver types are shared with the driver, so this is a
/// direct copy — no conversion, hence no drift.
#[allow(clippy::too_many_arguments)]
pub(super) fn build_sim_meta(
    layout: &SimLayout,
    result_vars: &[ResultVar],
    units: Vec<UnitDef>,
    settings: &SimCode::SimulationSettings,
    cs_method: &str,
    fmi_solver_flags: &str,
    model_name: &str,
    prefix: &str,
    jac_a: Option<JacAInfo>,
    state_sets: &[StateSetInfo],
    fmi_vrs: Vec<FmiVr>,
    fmi_dae_enable_vr: u32,
    zc_desc: Vec<String>,
    rel_desc: Vec<String>,
    params: openmodelica_sim_meta::ParamVars,
    attr_log: Vec<openmodelica_sim_meta::AttrLog>,
    removed_init_desc: Vec<String>,
    nls_warnings: Vec<String>,
    sample_index: Vec<i32>,
    soti: openmodelica_sim_meta::SotiVars,
    sens_params: Vec<u32>,
    nls_vars: Vec<openmodelica_sim_meta::NlsVars>,
    n_lin_systems: u32,
    dae: Option<openmodelica_sim_meta::DaeInfo>,
    clocks: Vec<BaseClockMeta>,
    lin: Option<openmodelica_sim_meta::LinInfo>,
    opt: Option<openmodelica_sim_meta::OptInfo>,
    inputs: Vec<openmodelica_sim_meta::InputVar>,
    recon: Option<openmodelica_sim_meta::ReconInfo>,
    prof: Option<openmodelica_sim_meta::ProfInfo>,
    parmod: Option<openmodelica_sim_meta::ParmodInfo>,
) -> openmodelica_sim_meta::SimMeta {
    openmodelica_sim_meta::SimMeta {
        layout: *layout,
        start_time: settings.startTime.into_inner(),
        stop_time: settings.stopTime.into_inner(),
        n_intervals: settings.numberOfIntervals.max(0) as u32,
        method: settings.method.to_string(),
        cs_method: cs_method.to_string(),
        fmi_solver_flags: fmi_solver_flags.to_string(),
        tolerance: settings.tolerance.into_inner(),
        output_format: settings.outputFormat.to_string(),
        prefix: prefix.to_string(),
        model_name: model_name.to_string(),
        vars: result_vars.to_vec(),
        units,
        jac_a,
        state_sets: state_sets.to_vec(),
        fmi_vrs,
        fmi_dae_enable_vr,
        zc_desc,
        rel_desc,
        params,
        attr_log,
        removed_init_desc,
        nls_warnings,
        sample_index,
        soti,
        sens_params,
        nls_vars,
        n_lin_systems,
        dae,
        clocks,
        lin,
        opt,
        inputs,
        recon,
        prof,
        parmod,
    }
}

/// The Modelica source of each zero-crossing relation (via
/// `ExpressionBasics::printExpStr`), so the driver can name the crossing that
/// triggered chattering. A math-event crossing has no relation string.
/// C's `modelData` variable arrays: the same lists, in the same order, as the
/// `SimData` variable regions.
pub(super) fn soti_vars(vars: &SimCodeVar::SimVars) -> Result<openmodelica_sim_meta::SotiVars> {
    let named = |sv: &SimCodeVar::SimVar| cref_display(&sv.name);
    let mut reals = Vec::new();
    for sv in lst(&vars.stateVars).chain(lst(&vars.derivativeVars)).chain(real_alg_vars(vars)) {
        reals.push(named(sv)?);
    }
    let mut ints = Vec::new();
    for sv in lst(&vars.intAlgVars) {
        ints.push((named(sv)?, const_int(&sv.initialValue).unwrap_or(0)));
    }
    let mut bools = Vec::new();
    for sv in lst(&vars.boolAlgVars) {
        bools.push((named(sv)?, const_int(&sv.initialValue).unwrap_or(0)));
    }
    let mut strings = Vec::new();
    for sv in lst(&vars.stringAlgVars) {
        strings.push((named(sv)?, const_str(&sv.initialValue).unwrap_or_default()));
    }
    let n_discrete_real = lst(&vars.discreteAlgVars).count() as u32;
    Ok(openmodelica_sim_meta::SotiVars { reals, ints, bools, strings, n_discrete_real })
}

/// C's `modelData` parameter arrays: the same lists, in the same order, as the
/// `SimData` parameter regions.
pub(super) fn param_vars(vars: &SimCodeVar::SimVars) -> Result<openmodelica_sim_meta::ParamVars> {
    let mut reals = Vec::new();
    for sv in lst(&vars.paramVars) {
        reals.push((cref_display(&sv.name)?.to_string(), const_real(&sv.initialValue).unwrap_or(0.0), sv.isFixed));
    }
    let mut ints = Vec::new();
    for sv in lst(&vars.intParamVars) {
        ints.push((cref_display(&sv.name)?.to_string(), const_int(&sv.initialValue).unwrap_or(0), sv.isFixed));
    }
    let mut bools = Vec::new();
    for sv in lst(&vars.boolParamVars) {
        bools.push((cref_display(&sv.name)?.to_string(), const_int(&sv.initialValue).unwrap_or(0), sv.isFixed));
    }
    let mut strings = Vec::new();
    for sv in lst(&vars.stringParamVars) {
        strings.push((cref_display(&sv.name)?.to_string(), const_str(&sv.initialValue).unwrap_or_default()));
    }
    Ok(openmodelica_sim_meta::ParamVars { reals, ints, bools, strings })
}

/// Name and attribute kind of every attribute-log slot.
pub(super) fn attr_log_entries(sim_code: &SimCode::SimCode) -> Result<Vec<openmodelica_sim_meta::AttrLog>> {
    let mut out = Vec::new();
    for (attr, cref, _) in bound_attr_equations(sim_code) {
        let raw = cref_display(cref)?.to_string();
        let name = raw.strip_prefix("$START.").unwrap_or(&raw).to_string();
        let kind = match attr {
            Attr::Min => 0,
            Attr::Max => 1,
            Attr::Nominal => 2,
            Attr::Start => 3,
        };
        out.push(openmodelica_sim_meta::AttrLog { kind, name });
    }
    Ok(out)
}

/// One description per relation, from the backend's list rather than from the
/// subset [`collect_relations`] can evaluate: `delayZeroCrossing` /
/// `spatialDistributionZeroCrossing` are stored as the bare call, which no target
/// assigns to `relations[]`, but C's `relationDescription` still names them.
pub(super) fn rel_descriptions(
    rels: &List<openmodelica_backend_types::BackendDAE::ZeroCrossing>,
) -> Vec<String> {
    lst(rels).map(|zc| dump_exp(&zc.relation_)).collect()
}

pub(super) fn zc_descriptions(crossings: &[ZcInfo]) -> Vec<String> {
    crossings
        .iter()
        .map(|zc| match zc {
            ZcInfo::Bool { expr } => dump_exp(expr),
            ZcInfo::Math { expr, .. } => dump_exp(expr),
        })
        .collect()
}

/// The mangled name of an external object's destructor (`<class>.destructor`), for
/// looking up its compiled wasm function. `sv` must be an `extObjVars` entry
/// (`T_COMPLEX`/`EXTERNAL_OBJ`); mirrors `SimCodeFunctionUtil.addDestructor`.
pub(super) fn extobj_destructor_key(sv: &SimCodeVar::SimVar) -> Result<String> {
    let path = match &*sv.type_ {
        DAE::Type::T_COMPLEX { complexClassType: openmodelica_frontend_types::ClassInf::State::EXTERNAL_OBJ { path }, .. } => path.clone(),
        _ => return Err("CodegenWasmJit: external object variable has a non-EXTERNAL_OBJ type"),
    };
    let dpath = openmodelica_frontend_dump::AbsynUtil::joinPaths(
        path,
        Arc::new(openmodelica_ast::Absyn::Path::IDENT { name: arcstr::literal!("destructor") }),
    )?;
    crate::CodegenWasmJitFunctions::mangle(&dpath)
}

/// Flatten a `list<SimEqSystem>` to a Vec of references.
pub(super) fn flatten_eqs(eqs: &List<Arc<SimCode::SimEqSystem>>) -> Vec<Arc<SimCode::SimEqSystem>> {
    lst(eqs).cloned().collect()
}
