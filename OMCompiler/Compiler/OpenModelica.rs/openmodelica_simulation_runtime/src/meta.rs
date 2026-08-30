//! Builds the [`SimMeta`] the shared driver runs on, from `MODEL_DATA` and the
//! init XML.
//!
//! The result-signal list is C's `mat4_init4` order -- time, real variables,
//! integer variables, boolean variables, the parameters, then the aliases -- so
//! the `.mat` this runtime writes has the same signals in the same places as the
//! one the C runtime writes for the same model.

use core::ffi::c_char;

use openmodelica_sim_meta::{
    Layout, MetaKind, MetaVar, Neg, ParamVars, SimMeta, SotiVars, WTy, var_filter,
};

use crate::abi::*;
use crate::model_data::InitXml;

fn cstr(p: *const c_char) -> String {
    if p.is_null() {
        return String::new();
    }
    unsafe { core::ffi::CStr::from_ptr(p) }.to_string_lossy().into_owned()
}

/// C's `printArrayName`: one name per scalar element, row-major subscripts inside
/// one pair of brackets. A state derivative keeps its `der(...)` parentheses
/// around the subscript.
fn scalar_names(name: &str, dim: &DIMENSION_INFO, is_state_derivative: bool) -> Vec<String> {
    if dim.numberOfDimensions == 0 || dim.dimensions.is_null() {
        return vec![name.to_string()];
    }
    let sizes: Vec<usize> = (0..dim.numberOfDimensions)
        .map(|k| unsafe { (*dim.dimensions.add(k)).start.max(0) as usize })
        .collect();
    let base = if is_state_derivative { name.strip_suffix(')').unwrap_or(name) } else { name };
    (0..dim.scalar_length)
        .map(|linear| {
            let mut rem = linear;
            let mut out = base.to_string();
            for k in 0..sizes.len() {
                let stride: usize = sizes[k + 1..].iter().product();
                let ix = rem / stride + 1;
                rem %= stride;
                out.push(if k == 0 { '[' } else { ',' });
                out.push_str(&ix.to_string());
            }
            out.push(']');
            if is_state_derivative {
                out.push(')');
            }
            out
        })
        .collect()
}

/// C's `printArrayDescription`: the comment, with the unit appended in brackets.
fn description(comment: &str, unit: &str) -> String {
    if unit.is_empty() { comment.to_string() } else { format!("{comment} [{unit}]") }
}

fn filter_bits(filter_output: c_int_t, is_alias: bool) -> u8 {
    let mut bits = 0u8;
    if filter_output != 0 {
        bits |= var_filter::FILTERED;
    }
    if is_alias {
        bits |= var_filter::ALIAS;
    }
    bits
}

type c_int_t = core::ffi::c_int;

/// The unit of each variable group, straight from the XML (`modelData` keeps it
/// as a MetaModelica string this runtime does not build).
struct Units<'a> {
    xml: &'a InitXml,
}

impl Units<'_> {
    fn get(&self, class_type: &str, index: usize) -> String {
        self.xml
            .group(class_type)
            .get(index)
            .and_then(|o| o.as_ref())
            .map(|v| v.attrs.get("unit").cloned().unwrap_or_default())
            .unwrap_or_default()
    }
}

pub fn build(data: *mut DATA, xml: &InitXml, layout: &Layout, prefix: &str) -> SimMeta {
    let md: &MODEL_DATA = unsafe { &*(*data).modelData };
    let si: &SIMULATION_INFO = unsafe { &*(*data).simulationInfo };
    let units = Units { xml };

    let mut vars: Vec<MetaVar> = Vec::new();
    vars.push(MetaVar {
        name: "time".into(),
        comment: "Simulation time [s]".into(),
        kind: MetaKind::Time,
        filter: 0,
    });

    // Real variables: states, derivatives, then the algebraic ones. Their result
    // column is the scalar index plus one (column 0 is time).
    for a in 0..md.nVariablesRealArray as usize {
        let v = unsafe { &*md.realVarsData.add(a) };
        let base = unsafe { *si.realVarsIndex.add(a) };
        let is_der = (md.nStatesArray as usize..2 * md.nStatesArray as usize).contains(&a);
        let group = if a < md.nStatesArray as usize {
            "rSta"
        } else if is_der {
            "rDer"
        } else {
            "rAlg"
        };
        let index = if group == "rAlg" { a - 2 * md.nStatesArray as usize } else { a % md.nStatesArray.max(1) as usize };
        let unit = units.get(group, index);
        for (k, name) in scalar_names(&cstr(v.info.name), &v.dimension, is_der).into_iter().enumerate() {
            vars.push(MetaVar {
                name,
                comment: description(&cstr(v.info.comment), &unit),
                kind: MetaKind::Column { col: (base + k) as u32 + 1, negate: Neg::None },
                filter: filter_bits(v.filterOutput, false),
            });
        }
    }

    let int_col0 = layout.n_reals_row();
    for a in 0..md.nVariablesIntegerArray as usize {
        let v = unsafe { &*md.integerVarsData.add(a) };
        let base = unsafe { *si.integerVarsIndex.add(a) };
        for (k, name) in scalar_names(&cstr(v.info.name), &v.dimension, false).into_iter().enumerate() {
            vars.push(MetaVar {
                name,
                comment: cstr(v.info.comment),
                kind: MetaKind::Column { col: int_col0 + (base + k) as u32, negate: Neg::None },
                filter: filter_bits(v.filterOutput, false),
            });
        }
    }
    let bool_col0 = int_col0 + layout.n_int_alg();
    for a in 0..md.nVariablesBooleanArray as usize {
        let v = unsafe { &*md.booleanVarsData.add(a) };
        let base = unsafe { *si.booleanVarsIndex.add(a) };
        for (k, name) in scalar_names(&cstr(v.info.name), &v.dimension, false).into_iter().enumerate() {
            vars.push(MetaVar {
                name,
                comment: cstr(v.info.comment),
                kind: MetaKind::Column { col: bool_col0 + (base + k) as u32, negate: Neg::None },
                filter: filter_bits(v.filterOutput, false),
            });
        }
    }

    // Parameters, read out of `SimData` once the run is over.
    for a in 0..md.nParametersRealArray as usize {
        let v = unsafe { &*md.realParameterData.add(a) };
        let base = unsafe { *si.realParamsIndex.add(a) };
        let unit = units.get("rPar", a);
        for (k, name) in scalar_names(&cstr(v.info.name), &v.dimension, false).into_iter().enumerate() {
            vars.push(MetaVar {
                name,
                comment: description(&cstr(v.info.comment), &unit),
                kind: MetaKind::Param {
                    off: layout.rparam_off + (base + k) as u32 * 8,
                    wty: WTy::F64,
                    negate: Neg::None,
                },
                filter: filter_bits(v.filterOutput, false),
            });
        }
    }
    for a in 0..md.nParametersIntegerArray as usize {
        let v = unsafe { &*md.integerParameterData.add(a) };
        let base = unsafe { *si.integerParamsIndex.add(a) };
        for (k, name) in scalar_names(&cstr(v.info.name), &v.dimension, false).into_iter().enumerate() {
            vars.push(MetaVar {
                name,
                comment: cstr(v.info.comment),
                kind: MetaKind::Param {
                    off: layout.iparam_off + (base + k) as u32 * 4,
                    wty: WTy::I32,
                    negate: Neg::None,
                },
                filter: filter_bits(v.filterOutput, false),
            });
        }
    }
    for a in 0..md.nParametersBooleanArray as usize {
        let v = unsafe { &*md.booleanParameterData.add(a) };
        let base = unsafe { *si.booleanParamsIndex.add(a) };
        for (k, name) in scalar_names(&cstr(v.info.name), &v.dimension, false).into_iter().enumerate() {
            vars.push(MetaVar {
                name,
                comment: cstr(v.info.comment),
                kind: MetaKind::Param {
                    off: layout.bparam_off + (base + k) as u32 * 4,
                    wty: WTy::I32,
                    negate: Neg::None,
                },
                filter: filter_bits(v.filterOutput, false),
            });
        }
    }

    // Aliases read the slot of the variable or parameter they name.
    let real_alias_kind = |al: &DATA_ALIAS| -> MetaKind {
        let neg = if al.negate != 0 { Neg::Arith } else { Neg::None };
        match al.aliasType {
            2 => MetaKind::Time,
            1 => {
                let base = unsafe { *si.realParamsIndex.add(al.nameID as usize) };
                MetaKind::Param { off: layout.rparam_off + base as u32 * 8, wty: WTy::F64, negate: neg }
            }
            _ => {
                let base = unsafe { *si.realVarsIndex.add(al.nameID as usize) };
                MetaKind::Column { col: base as u32 + 1, negate: neg }
            }
        }
    };
    for a in 0..md.nAliasRealArray as usize {
        let al = unsafe { &*md.realAlias.add(a) };
        let is_der = al.aliasType == 0
            && (md.nStatesArray..2 * md.nStatesArray).contains(&(al.nameID as i64));
        let dim = alias_dimension(md, al, 0);
        for name in scalar_names(&cstr(al.info.name), dim, is_der) {
            vars.push(MetaVar {
                name,
                comment: cstr(al.info.comment),
                kind: real_alias_kind(al),
                filter: filter_bits(al.filterOutput, true),
            });
        }
    }
    for (kind_ix, (count, arr)) in [
        (md.nAliasIntegerArray, md.integerAlias),
        (md.nAliasBooleanArray, md.booleanAlias),
    ]
    .into_iter()
    .enumerate()
    {
        for a in 0..count as usize {
            let al = unsafe { &*arr.add(a) };
            let neg = if al.negate != 0 {
                if kind_ix == 1 { Neg::Not } else { Neg::Arith }
            } else {
                Neg::None
            };
            let kind = if al.aliasType == 1 {
                let (base, off, wty) = if kind_ix == 0 {
                    (unsafe { *si.integerParamsIndex.add(al.nameID as usize) }, layout.iparam_off, WTy::I32)
                } else {
                    (unsafe { *si.booleanParamsIndex.add(al.nameID as usize) }, layout.bparam_off, WTy::I32)
                };
                MetaKind::Param { off: off + base as u32 * 4, wty, negate: neg }
            } else {
                let (base, col0) = if kind_ix == 0 {
                    (unsafe { *si.integerVarsIndex.add(al.nameID as usize) }, int_col0)
                } else {
                    (unsafe { *si.booleanVarsIndex.add(al.nameID as usize) }, bool_col0)
                };
                MetaKind::Column { col: col0 + base as u32, negate: neg }
            };
            let dim = alias_dimension(md, al, kind_ix + 1);
            for name in scalar_names(&cstr(al.info.name), dim, false) {
                vars.push(MetaVar {
                    name,
                    comment: cstr(al.info.comment),
                    kind: kind.clone(),
                    filter: filter_bits(al.filterOutput, true),
                });
            }
        }
    }

    let soti = soti_vars(md, si);
    let params = param_vars(md, si);
    let zc_desc = descriptions(md.nZeroCrossings, |i| unsafe {
        (*(*data).callback).zeroCrossingDescription.map(|f| {
            let mut idx: *mut c_int_t = core::ptr::null_mut();
            cstr(f(i, &mut idx))
        })
    });
    let rel_desc = descriptions(md.nRelations, |i| unsafe {
        (*(*data).callback).relationDescription.map(|f| cstr(f(i)))
    });

    SimMeta {
        layout: *layout,
        start_time: si.startTime,
        stop_time: si.stopTime,
        n_intervals: si.numSteps.max(0) as u32,
        method: cstr(si.solverMethod),
        cs_method: String::new(),
        fmi_solver_flags: String::new(),
        tolerance: si.tolerance,
        output_format: cstr(si.outputFormat),
        prefix: prefix.to_string(),
        model_name: cstr(md.modelName),
        vars,
        jac_a: jac_a_info(data, layout),
        state_sets: crate::stateset::describe(data, layout),
        fmi_vrs: Vec::new(),
        fmi_dae_enable_vr: 0,
        zc_desc,
        rel_desc,
        sample_index: (0..md.nSamples).map(|i| unsafe { (*md.samplesInfo.add(i as usize)).index as i32 }).collect(),
        soti,
        params,
        attr_log: Vec::new(),
        removed_init_desc: Vec::new(),
        nls_warnings: Vec::new(),
        sens_params: Vec::new(),
        nls_vars: Vec::new(),
        n_lin_systems: md.nLinearSystems as u32,
        dae: dae_info(data, layout),
        clocks: Vec::new(),
        lin: None,
        parmod: None,
        opt: None,
        inputs: Vec::new(),
        recon: None,
        prof: None,
    }
}

/// `SimMeta::dae` from `simulationInfo->daeModeData`, which the generated
/// `initializeDAEmodeData` filled: the algebraic unknowns IDA carries after the
/// states, and the residual Jacobian's sparsity with its coloring.
fn dae_info(data: *mut DATA, layout: &Layout) -> Option<openmodelica_sim_meta::DaeInfo> {
    if layout.n_dae_res == 0 {
        return None;
    }
    let d = unsafe { &*(*data).simulationInfo.as_ref()?.daeModeData };
    let alg_offs = (0..layout.n_dae_alg as usize)
        .map(|i| {
            let ix = unsafe { *d.algIndexes.add(i) } as u32;
            openmodelica_sim_meta::REAL_OFF + ix * 8
        })
        .collect();
    Some(openmodelica_sim_meta::DaeInfo {
        alg_offs,
        sparsity: sparsity_info(d.sparsePattern, layout.n_dae_res),
    })
}

/// C's `SPARSE_PATTERN` as the driver's `JacAInfo`, without the column evaluator
/// (C's `JACOBIAN_ONLY_SPARSITY`); [`jac_a_info`] adds one where the model has it.
fn sparsity_info(sp: *const SPARSE_PATTERN, n: u32) -> Option<openmodelica_sim_meta::JacAInfo> {
    let sp = unsafe { sp.as_ref()? };
    let n = n as usize;
    if sp.sizeCols as usize != n || sp.maxColors == 0 {
        return None;
    }
    let rows_by_col: Vec<Vec<u32>> = (0..n)
        .map(|c| {
            let from = unsafe { *sp.leadindex.add(c) } as usize;
            let to = unsafe { *sp.leadindex.add(c + 1) } as usize;
            (from..to).map(|k| unsafe { *sp.index.add(k) }).collect()
        })
        .collect();
    // `colorCols[col]` is the column's 1-based colour, as `genSPColors` writes it.
    let mut colors = vec![Vec::new(); sp.maxColors as usize];
    for c in 0..n {
        let col = unsafe { *sp.colorCols.add(c) } as usize;
        if col == 0 || col > colors.len() {
            return None;
        }
        colors[col - 1].push(c as u32);
    }
    if rows_by_col.iter().flatten().any(|&r| r as usize >= n) {
        return None;
    }
    Some(openmodelica_sim_meta::JacAInfo { n: n as u32, colors, rows_by_col, sym: None })
}

/// `SimMeta::jac_a` from `analyticJacobians[INDEX_JAC_A]`, which `data::initialize`
/// has already had the model fill. The seeds and results are C's own arrays, which
/// `build_regions` maps onto the layout's Jacobian window.
fn jac_a_info(data: *mut DATA, layout: &Layout) -> Option<openmodelica_sim_meta::JacAInfo> {
    let j = crate::data::jac_a(data)?;
    let n = layout.n_states;
    let mut info = sparsity_info(j.sparsePattern, n)?;
    if j.availability != JACOBIAN_AVAILABLE
        || j.evalColumn.is_none()
        || j.sizeCols != n as usize
        || j.sizeRows != n as usize
    {
        return Some(info);
    }
    let cols = j.sizeCols as u32;
    info.sym = Some(openmodelica_sim_meta::JacSym {
        seed_offs: (0..cols).map(|k| layout.nls_jac_off + k * 8).collect(),
        result_offs: (0..n).map(|k| layout.nls_jac_off + (cols + k) * 8).collect(),
        has_constant: j.constantEqns.is_some(),
        adj: None,
    });
    Some(info)
}

/// The dimension of the variable an alias reads, which gives its element names.
fn alias_dimension(md: &MODEL_DATA, al: &DATA_ALIAS, kind: usize) -> &'static DIMENSION_INFO {
    // A scalar shape for the cases with no array behind them (an alias of time).
    const SCALAR: &DIMENSION_INFO = &DIMENSION_INFO {
        numberOfDimensions: 0,
        dimensions: core::ptr::null_mut(),
        scalar_length: 1,
    };
    let ix = al.nameID as usize;
    unsafe {
        match (kind, al.aliasType) {
            (0, 0) => &(*md.realVarsData.add(ix)).dimension,
            (0, 1) => &(*md.realParameterData.add(ix)).dimension,
            (1, 0) => &(*md.integerVarsData.add(ix)).dimension,
            (1, 1) => &(*md.integerParameterData.add(ix)).dimension,
            (2, 0) => &(*md.booleanVarsData.add(ix)).dimension,
            (2, 1) => &(*md.booleanParameterData.add(ix)).dimension,
            _ => SCALAR,
        }
    }
}

fn descriptions(count: i64, get: impl Fn(c_int_t) -> Option<String>) -> Vec<String> {
    (0..count).map(|i| get(i as c_int_t).unwrap_or_default()).collect()
}

/// What the `LOG_SOTI` initialization dump walks.
fn soti_vars(md: &MODEL_DATA, si: &SIMULATION_INFO) -> SotiVars {
    let mut v = SotiVars::default();
    unsafe {
        for a in 0..md.nVariablesRealArray as usize {
            let d = &*md.realVarsData.add(a);
            let base = *si.realVarsIndex.add(a);
            for k in 0..d.dimension.scalar_length {
                let _ = base;
                v.reals.push(scalar_names(&cstr(d.info.name), &d.dimension, false)[k].clone());
            }
        }
        for a in 0..md.nVariablesIntegerArray as usize {
            let d = &*md.integerVarsData.add(a);
            v.ints.push((cstr(d.info.name), d.attribute.start as i32));
        }
        for a in 0..md.nVariablesBooleanArray as usize {
            let d = &*md.booleanVarsData.add(a);
            v.bools.push((cstr(d.info.name), d.attribute.start));
        }
        for a in 0..md.nVariablesStringArray as usize {
            let d = &*md.stringVarsData.add(a);
            v.strings.push((cstr(d.info.name), String::new()));
        }
    }
    v.n_discrete_real = md.nDiscreteRealArray as u32;
    v
}

/// What the `LOG_INIT_V` parameter dump reports.
fn param_vars(md: &MODEL_DATA, _si: &SIMULATION_INFO) -> ParamVars {
    let mut p = ParamVars::default();
    unsafe {
        for a in 0..md.nParametersRealArray as usize {
            let d = &*md.realParameterData.add(a);
            for name in scalar_names(&cstr(d.info.name), &d.dimension, false) {
                p.reals.push((name, d.attribute.start.first_real(0.0), d.attribute.fixed != 0));
            }
        }
        for a in 0..md.nParametersIntegerArray as usize {
            let d = &*md.integerParameterData.add(a);
            p.ints.push((cstr(d.info.name), d.attribute.start as i32, d.attribute.fixed != 0));
        }
        for a in 0..md.nParametersBooleanArray as usize {
            let d = &*md.booleanParameterData.add(a);
            p.bools.push((cstr(d.info.name), d.attribute.start, d.attribute.fixed != 0));
        }
        for a in 0..md.nParametersStringArray as usize {
            let d = &*md.stringParameterData.add(a);
            p.strings.push((cstr(d.info.name), String::new()));
        }
    }
    p
}
