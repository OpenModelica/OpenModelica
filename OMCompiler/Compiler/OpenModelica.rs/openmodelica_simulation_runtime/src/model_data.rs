//! `read_input_xml` + `allocModelDataVars`: fills `MODEL_DATA` from the model's
//! `<prefix>_init.xml`.
//!
//! The generated C carries only the counts of *array* variables; the names,
//! attributes, start values and alias structure live in the XML beside the
//! executable, which the C runtime reads with expat. This is the same read, with
//! the same defaults and the same ordering (`rSta`, `rDer`, `rAlg`, then the
//! parameters), so a model sees identical `modelData` under either runtime.

use core::ffi::{c_char, c_int, c_void};
use std::collections::HashMap;

use crate::abi::*;

/// One `<ScalarVariable>`, as the attribute soup C keeps it in: the element's own
/// attributes plus the typed child's (`<Real start=".."/>`) and the `<Dimension>`
/// entries, flattened into one map the way C's expat handler builds it.
pub struct XmlVar {
    pub attrs: HashMap<String, String>,
}

impl XmlVar {
    fn get(&self, key: &str) -> &str {
        self.attrs.get(key).map_or("", |s| s.as_str())
    }
}

/// What the XML says, grouped the way `read_input_xml` consumes it.
pub struct InitXml {
    /// `classType` -> variables, each at its `classIndex`.
    pub groups: HashMap<String, Vec<Option<XmlVar>>>,
    /// The `fmiModelDescription` attributes.
    pub md: HashMap<String, String>,
    /// The `DefaultExperiment` attributes.
    pub experiment: HashMap<String, String>,
}

impl InitXml {
    pub fn group(&self, class_type: &str) -> &[Option<XmlVar>] {
        self.groups.get(class_type).map_or(&[], |v| v.as_slice())
    }
    pub fn md(&self, key: &str) -> &str {
        self.md.get(key).map_or("", |s| s.as_str())
    }
    pub fn experiment(&self, key: &str) -> &str {
        self.experiment.get(key).map_or("", |s| s.as_str())
    }
}

pub fn parse(path: &str) -> Result<InitXml, String> {
    let text = std::fs::read_to_string(path).map_err(|e| format!("cannot read {path}: {e}"))?;
    parse_str(&text)
}

pub fn parse_str(text: &str) -> Result<InitXml, String> {
    let doc = roxmltree::Document::parse(text).map_err(|e| format!("cannot parse the init XML: {e}"))?;
    let root = doc.root_element();
    let md: HashMap<String, String> =
        root.attributes().map(|a| (a.name().to_string(), a.value().to_string())).collect();
    let mut experiment = HashMap::new();
    let mut groups: HashMap<String, Vec<Option<XmlVar>>> = HashMap::new();

    for node in root.children().filter(|n| n.is_element()) {
        match node.tag_name().name() {
            "DefaultExperiment" => {
                experiment =
                    node.attributes().map(|a| (a.name().to_string(), a.value().to_string())).collect();
            }
            "ModelVariables" => {
                for sv in node.children().filter(|n| n.is_element()) {
                    let mut attrs: HashMap<String, String> =
                        sv.attributes().map(|a| (a.name().to_string(), a.value().to_string())).collect();
                    let mut dims = 0usize;
                    for child in sv.children().filter(|n| n.is_element()) {
                        // `<Real start=".." fixed=".."/>` and `<Dimension .../>`.
                        if child.tag_name().name() == "Dimension" {
                            dims += 1;
                            for a in child.attributes() {
                                attrs.insert(format!("dim-{dims}-{}", a.name()), a.value().to_string());
                            }
                        } else {
                            for a in child.attributes() {
                                attrs.insert(a.name().to_string(), a.value().to_string());
                            }
                        }
                    }
                    if dims > 0 {
                        attrs.insert("num_dimensions".into(), dims.to_string());
                    }
                    let class_type = attrs.get("classType").cloned().unwrap_or_default();
                    let class_index: usize =
                        attrs.get("classIndex").and_then(|s| s.parse().ok()).unwrap_or(0);
                    let slot = groups.entry(class_type).or_default();
                    if slot.len() <= class_index {
                        slot.resize_with(class_index + 1, || None);
                    }
                    slot[class_index] = Some(XmlVar { attrs });
                }
            }
            _ => {}
        }
    }
    Ok(InitXml { groups, md, experiment })
}

// ---------------------------------------------------------------------------
// Value readers, matching `read_value_*` in simulation_input_xml.c.
// ---------------------------------------------------------------------------

pub fn read_real(s: &str, default: f64) -> f64 {
    match s {
        "" => default,
        "true" => 1.0,
        "false" => 0.0,
        _ => s.parse().unwrap_or(default),
    }
}

pub fn read_long(s: &str, default: c_long_t) -> c_long_t {
    match s {
        "" => default,
        "true" => 1,
        "false" => 0,
        _ => s.parse().unwrap_or(default),
    }
}

pub fn read_bool(s: &str) -> c_int {
    (s == "true" || s == "1") as c_int
}

type c_long_t = core::ffi::c_long;

/// C's `REAL_MIN`/`REAL_MAX` attribute defaults.
const REAL_MIN: f64 = -f64::MAX;
const REAL_MAX: f64 = f64::MAX;
const INTEGER_MIN: c_long_t = c_long_t::MIN / 2;
const INTEGER_MAX: c_long_t = c_long_t::MAX / 2;

// ---------------------------------------------------------------------------
// Allocation helpers.
// ---------------------------------------------------------------------------

pub(crate) fn calloc<T>(n: usize) -> *mut T {
    unsafe { libc::calloc(n.max(1), core::mem::size_of::<T>()) as *mut T }
}

/// A NUL-terminated copy the C side keeps forever (`omc_strdup` in the C reader).
pub(crate) fn strdup(s: &str) -> *const c_char {
    let c = std::ffi::CString::new(s).unwrap_or_default();
    unsafe { libc::strdup(c.as_ptr()) }
}

/// `read_array_var_real`: a whitespace-separated value list, or one default.
fn read_array_real(out: &mut real_array, s: &str, default: f64) {
    let values: Vec<f64> = s.split_whitespace().map(|t| read_real(t, default)).collect();
    let values = if values.is_empty() { vec![default] } else { values };
    let data: *mut f64 = calloc(values.len());
    for (i, v) in values.iter().enumerate() {
        unsafe { *data.add(i) = *v };
    }
    let dim: *mut _index_t = calloc(1);
    unsafe { *dim = values.len() as _index_t };
    out.ndims = 1;
    out.dim_size = dim;
    out.data = data as *mut c_void;
    out.flexible = 0;
}

fn read_var_info(v: &XmlVar, info: &mut VAR_INFO) {
    info.name = strdup(v.get("name"));
    info.inputIndex = read_long(v.get("inputIndex"), -1) as c_int;
    info.id = read_long(v.get("valueReference"), -1) as c_int;
    info.comment = strdup(v.get("description"));
    info.info.filename = strdup(v.get("fileName"));
    info.info.lineStart = read_long(v.get("startLine"), 0) as c_int;
    info.info.colStart = read_long(v.get("startColumn"), 0) as c_int;
    info.info.lineEnd = read_long(v.get("endLine"), 0) as c_int;
    info.info.colEnd = read_long(v.get("endColumn"), 0) as c_int;
    info.info.readonly = read_long(v.get("fileWritable"), 0) as c_int;
}

fn read_dimension(v: &XmlVar, dim: &mut DIMENSION_INFO) {
    let n = read_long(v.get("num_dimensions"), 0).max(0) as usize;
    dim.numberOfDimensions = n;
    if n == 0 {
        dim.dimensions = core::ptr::null_mut();
        dim.scalar_length = 1;
        return;
    }
    let arr: *mut DIMENSION_ATTRIBUTE = calloc(n);
    for i in 0..n {
        let start = read_long(v.get(&format!("dim-{}-start", i + 1)), -1);
        let vref = read_long(v.get(&format!("dim-{}-valueReference", i + 1)), -1);
        let d = unsafe { &mut *arr.add(i) };
        d.start = start;
        d.valueReference = vref;
        d.ty = if start > 0 && vref == -1 { 0 } else { 1 };
    }
    dim.dimensions = arr;
    // Set once the structural parameters are known (`calculateAllScalarLength`).
    dim.scalar_length = usize::MAX;
}

/// C's `shouldFilterOutput`, over the flags this runtime has already parsed.
fn should_filter(v: &XmlVar) -> c_int {
    let ep = unsafe { crate::support::omc_flag[FLAG_EMIT_PROTECTED] } != 0;
    let ihr = unsafe { crate::support::omc_flag[FLAG_IGNORE_HIDERESULT] } != 0;
    let protected = v.get("isProtected") == "true";
    let hide = v.get("hideResult") == "true";
    let encrypted = v.get("isEncrypted") == "true";
    let mut filter = protected || hide;
    if !encrypted && ep && protected {
        filter = false;
    }
    if ihr && hide {
        filter = false;
    }
    filter as c_int
}

macro_rules! read_group {
    ($ty:ty, $out:expr, $vars:expr, $start:expr, $count:expr, $alias_map:expr, $attr:expr) => {{
        for i in 0..$count {
            let Some(v) = $vars.get(i).and_then(|o| o.as_ref()) else { continue };
            let slot: &mut $ty = unsafe { &mut *$out.add($start + i) };
            read_var_info(v, &mut slot.info);
            read_dimension(v, &mut slot.dimension);
            slot.filterOutput = should_filter(v);
            slot.time_unvarying = 0;
            $attr(v, slot);
            $alias_map.insert(v.get("name").to_string(), ($start + i) as i64);
        }
    }};
}

/// The variable and parameter arrays `read_input_xml` fills, plus the name ->
/// index maps the alias variables resolve through.
pub struct AliasMaps {
    pub vars: HashMap<String, i64>,
    pub params: HashMap<String, i64>,
}

/// `read_model_description_sizes`: the array-variable counts.
pub fn read_sizes(xml: &InitXml, md: &mut MODEL_DATA) {
    md.nStatesArray = read_long(xml.md("numberOfContinuousStates"), 0);
    let n_alg = read_long(xml.md("numberOfRealAlgebraicVariables"), 0);
    md.nVariablesRealArray = 2 * md.nStatesArray + n_alg;
    md.nAliasRealArray = read_long(xml.md("numberOfRealAlgebraicAliasVariables"), 0);
    md.nParametersRealArray = read_long(xml.md("numberOfRealParameters"), 0);

    md.nParametersIntegerArray = read_long(xml.md("numberOfIntegerParameters"), 0);
    md.nVariablesIntegerArray = read_long(xml.md("numberOfIntegerAlgebraicVariables"), 0);
    md.nAliasIntegerArray = read_long(xml.md("numberOfIntegerAliasVariables"), 0);

    md.nParametersBooleanArray = read_long(xml.md("numberOfBooleanParameters"), 0);
    md.nVariablesBooleanArray = read_long(xml.md("numberOfBooleanAlgebraicVariables"), 0);
    md.nAliasBooleanArray = read_long(xml.md("numberOfBooleanAliasVariables"), 0);

    md.nParametersStringArray = read_long(xml.md("numberOfStringParameters"), 0);
    md.nVariablesStringArray = read_long(xml.md("numberOfStringAlgebraicVariables"), 0);
    md.nAliasStringArray = read_long(xml.md("numberOfStringAliasVariables"), 0);
}

/// `read_experiment`: the `<DefaultExperiment>` settings, which the command line
/// may override later.
pub fn read_experiment(xml: &InitXml, si: &mut SIMULATION_INFO) {
    si.startTime = read_real(xml.experiment("startTime"), 0.0);
    si.stopTime = read_real(xml.experiment("stopTime"), 1.0);
    si.stepSize = read_real(xml.experiment("stepSize"), (si.stopTime - si.startTime) / 500.0);
    si.tolerance = read_real(xml.experiment("tolerance"), 1e-5);
    si.solverMethod = strdup(xml.experiment("solver"));
    si.outputFormat = strdup(xml.experiment("outputFormat"));
    si.variableFilter = strdup(xml.experiment("variableFilter"));
    si.numSteps = if si.stepSize > 0.0 {
        ((si.stopTime - si.startTime) / si.stepSize).round() as c_long_t
    } else {
        0
    };
}

/// `allocModelDataVars` + the `read_variables` calls: every variable and
/// parameter array of `modelData`, in the order the C reader fills them.
pub fn read_variables(xml: &InitXml, md: &mut MODEL_DATA) -> AliasMaps {
    let mut maps = AliasMaps { vars: HashMap::new(), params: HashMap::new() };

    md.realVarsData = calloc(md.nVariablesRealArray as usize);
    md.integerVarsData = calloc(md.nVariablesIntegerArray as usize);
    md.booleanVarsData = calloc(md.nVariablesBooleanArray as usize);
    md.stringVarsData = calloc(md.nVariablesStringArray as usize);
    md.realParameterData = calloc(md.nParametersRealArray as usize);
    md.integerParameterData = calloc(md.nParametersIntegerArray as usize);
    md.booleanParameterData = calloc(md.nParametersBooleanArray as usize);
    md.stringParameterData = calloc(md.nParametersStringArray as usize);
    md.realAlias = calloc(md.nAliasRealArray as usize);
    md.integerAlias = calloc(md.nAliasIntegerArray as usize);
    md.booleanAlias = calloc(md.nAliasBooleanArray as usize);
    md.stringAlias = calloc(md.nAliasStringArray as usize);

    let real_attr = |v: &XmlVar, slot: &mut STATIC_REAL_DATA| {
        read_array_real(&mut slot.attribute.start, v.get("start"), 0.0);
        slot.attribute.fixed = read_bool(v.get("fixed"));
        slot.attribute.useNominal = read_bool(v.get("useNominal"));
        read_array_real(&mut slot.attribute.nominal, v.get("nominal"), 1.0);
        read_array_real(&mut slot.attribute.min, v.get("min"), REAL_MIN);
        read_array_real(&mut slot.attribute.max, v.get("max"), REAL_MAX);
        slot.attribute.unit = core::ptr::null_mut();
        slot.attribute.displayUnit = core::ptr::null_mut();
    };
    let int_attr = |v: &XmlVar, slot: &mut STATIC_INTEGER_DATA| {
        slot.attribute.start = read_long(v.get("start"), 0);
        slot.attribute.fixed = read_bool(v.get("fixed"));
        slot.attribute.min = read_long(v.get("min"), INTEGER_MIN);
        slot.attribute.max = read_long(v.get("max"), INTEGER_MAX);
    };
    let bool_attr = |v: &XmlVar, slot: &mut STATIC_BOOLEAN_DATA| {
        slot.attribute.start = read_bool(v.get("start"));
        slot.attribute.fixed = read_bool(v.get("fixed"));
    };
    let str_attr = |_v: &XmlVar, slot: &mut STATIC_STRING_DATA| {
        slot.attribute.start = core::ptr::null_mut();
    };

    let n_states = md.nStatesArray as usize;
    let n_real = md.nVariablesRealArray as usize;
    read_group!(STATIC_REAL_DATA, md.realVarsData, xml.group("rSta"), 0, n_states, maps.vars, real_attr);
    read_group!(STATIC_REAL_DATA, md.realVarsData, xml.group("rDer"), n_states, n_states, maps.vars, real_attr);
    read_group!(STATIC_REAL_DATA, md.realVarsData, xml.group("rAlg"), 2 * n_states, n_real - 2 * n_states, maps.vars, real_attr);
    read_group!(STATIC_INTEGER_DATA, md.integerVarsData, xml.group("iAlg"), 0, md.nVariablesIntegerArray as usize, maps.vars, int_attr);
    read_group!(STATIC_BOOLEAN_DATA, md.booleanVarsData, xml.group("bAlg"), 0, md.nVariablesBooleanArray as usize, maps.vars, bool_attr);
    read_group!(STATIC_STRING_DATA, md.stringVarsData, xml.group("sAlg"), 0, md.nVariablesStringArray as usize, maps.vars, str_attr);

    read_group!(STATIC_REAL_DATA, md.realParameterData, xml.group("rPar"), 0, md.nParametersRealArray as usize, maps.params, real_attr);
    read_group!(STATIC_INTEGER_DATA, md.integerParameterData, xml.group("iPar"), 0, md.nParametersIntegerArray as usize, maps.params, int_attr);
    read_group!(STATIC_BOOLEAN_DATA, md.booleanParameterData, xml.group("bPar"), 0, md.nParametersBooleanArray as usize, maps.params, bool_attr);
    read_group!(STATIC_STRING_DATA, md.stringParameterData, xml.group("sPar"), 0, md.nParametersStringArray as usize, maps.params, str_attr);

    read_alias(md.realAlias, xml.group("rAli"), md.nAliasRealArray as usize, &maps);
    read_alias(md.integerAlias, xml.group("iAli"), md.nAliasIntegerArray as usize, &maps);
    read_alias(md.booleanAlias, xml.group("bAli"), md.nAliasBooleanArray as usize, &maps);
    read_alias(md.stringAlias, xml.group("sAli"), md.nAliasStringArray as usize, &maps);

    maps
}

/// `read_alias_var`: resolve each alias to the variable or parameter it reads,
/// keeping C's `negate` / `aliasType` encoding.
fn read_alias(out: *mut DATA_ALIAS, vars: &[Option<XmlVar>], count: usize, maps: &AliasMaps) {
    for i in 0..count {
        let Some(v) = vars.get(i).and_then(|o| o.as_ref()) else { continue };
        let slot = unsafe { &mut *out.add(i) };
        read_var_info(v, &mut slot.info);
        slot.filterOutput = should_filter(v);
        let alias = v.get("alias");
        slot.negate = (alias == "negatedAlias") as c_int;
        let target = v.get("aliasVariable");
        if target == "time" {
            slot.aliasType = 2;
            slot.nameID = 0;
        } else if let Some(ix) = maps.vars.get(target) {
            slot.aliasType = 0;
            slot.nameID = *ix as c_int;
        } else if let Some(ix) = maps.params.get(target) {
            slot.aliasType = 1;
            slot.nameID = *ix as c_int;
        } else {
            // C leaves an unresolved alias pointing at index 0 of the variables.
            slot.aliasType = 0;
            slot.nameID = 0;
        }
    }
}
