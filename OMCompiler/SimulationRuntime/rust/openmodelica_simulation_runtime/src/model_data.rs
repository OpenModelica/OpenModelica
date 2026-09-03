//! `read_input_xml` + `allocModelDataVars`: fills `MODEL_DATA` from the model's
//! `<prefix>_init.xml`.
//!
//! The generated C carries only the counts of *array* variables; the names,
//! attributes, start values and alias structure live in the XML beside the
//! executable, which the C runtime reads with expat. This is the same read, with
//! the same defaults and the same ordering (`rSta`, `rDer`, `rAlg`, then the
//! parameters), so a model sees identical `modelData` under either runtime.

use core::ffi::{c_char, c_int, c_long, c_void};
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

/// C's `read_value_long`, an `atol`: the leading integer of the text, so an
/// Integer written as `2.0` reads 2 and anything else 0.
pub fn read_long(s: &str, default: modelica_integer) -> modelica_integer {
    match s {
        "" => default,
        "true" => 1,
        "false" => 0,
        _ => {
            let t = s.trim_start();
            let end = t
                .char_indices()
                .take_while(|&(i, c)| c.is_ascii_digit() || (i == 0 && (c == '-' || c == '+')))
                .map(|(i, c)| i + c.len_utf8())
                .last()
                .unwrap_or(0);
            t[..end].parse().unwrap_or(0)
        }
    }
}

pub fn read_bool(s: &str) -> c_int {
    (s == "true" || s == "1") as c_int
}


/// C's `REAL_MIN`/`REAL_MAX` attribute defaults.
const REAL_MIN: f64 = -f64::MAX;
const REAL_MAX: f64 = f64::MAX;
const INTEGER_MIN: modelica_integer = modelica_integer::MIN / 2;
const INTEGER_MAX: modelica_integer = modelica_integer::MAX / 2;

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

unsafe extern "C" {
    // The interned MMC strings `libOpenModelicaRuntimeC` keeps for the empty string
    // and every one-byte string, which C's own constructors return instead of
    // allocating (`util/modelica_string_lit.h`).
    static mmc_emptystring: *mut c_void;
    static mmc_strings_len1: [*mut c_void; 256];
}

/// C's `mmc_mk_scon_persist` (`util/modelica_string.h`), a `static inline` with no
/// symbol to call: an `mmc_string` -- header word then the bytes and their NUL --
/// whose tagged pointer is a `modelica_string`. Never freed, as "persist" says.
/// A `const char*` the generated code owns, as a `String`.
pub fn cstr(p: *const c_char) -> String {
    if p.is_null() {
        return String::new();
    }
    unsafe { core::ffi::CStr::from_ptr(p) }.to_string_lossy().into_owned()
}

/// `MMC_STRINGDATA`, the inverse of [`mk_scon_persist`]: the bytes behind an
/// `mmc_string`'s header word.
pub fn string_value(p: *mut c_void) -> String {
    if p.is_null() {
        return String::new();
    }
    let data = unsafe { (p as *mut u8).sub(3).add(core::mem::size_of::<usize>()) };
    unsafe { core::ffi::CStr::from_ptr(data as *const c_char) }.to_string_lossy().into_owned()
}

pub fn mk_scon_persist(s: &str) -> *mut c_void {
    let n = s.len();
    if n == 0 {
        return unsafe { mmc_emptystring };
    }
    if n == 1 {
        return unsafe { mmc_strings_len1[s.as_bytes()[0] as usize] };
    }
    const W: usize = core::mem::size_of::<usize>();
    let log2_w = W.trailing_zeros() as usize;
    let header = (n << 3) + ((1 << (3 + log2_w)) + 5);
    let words = (header >> (3 + log2_w)) + 1;
    let p = unsafe { libc::malloc(words * W) } as *mut u8;
    assert!(!p.is_null(), "out of memory building a String start value");
    unsafe {
        *(p as *mut usize) = header;
        core::ptr::copy_nonoverlapping(s.as_ptr(), p.add(W), n);
        *p.add(W + n) = 0;
        // `MMC_TAGPTR`: RML-style tagged pointers offset a heap object by 3.
        p.add(3) as *mut c_void
    }
}

/// C's `doOverride`: `-override` / `-overrideFile` rewrite the `start` attribute
/// of every quantity the XML marks `isValueChangeable`, before anything reads it.
/// The walk is in C's order, so the log lines and warnings come out in it too.
pub fn do_override(xml: &mut InitXml, flags: &openmodelica_sim_meta::simflags::SimFlags) {
    use openmodelica_sim_meta::omclog;
    let raw = flags.override_raw.as_deref();
    let file = flags.override_file.as_ref();
    if let (Some(raw), Some((path, _))) = (raw, file) {
        omclog::info!(omclog::SOLVER, false, "using -override={raw} and -overrideFile={path}");
    }
    if let Some((path, _)) = file {
        omclog::info!(omclog::SOLVER, false, "read override values from file: {path}");
    }
    if raw.is_none() && file.is_none() {
        omclog::info(omclog::SOLVER, false, "NO override given on the command line.");
        return;
    }
    fn given(v: Option<&str>) -> &str {
        v.unwrap_or("[not given]")
    }
    omclog::info!(omclog::SOLVER, false, "-override={}", given(raw));
    omclog::info!(omclog::SOLVER, false, "-overrideFile={}", given(file.map(|(_, j)| j.as_str())));

    // C fills a hash map, so a repeated name keeps the last value and warns; the
    // insertion order is the one the unused-override warnings come out in.
    let mut map: Vec<(String, String)> = Vec::new();
    let mut index: HashMap<String, usize> = HashMap::new();
    for (name, val) in &flags.overrides {
        match index.get(name) {
            Some(&k) => {
                let old = &map[k].1;
                omclog::warning!(
                    omclog::STDOUT,
                    false,
                    "You are overriding variable: {name}={old} again with {name}={val}.",
                );
                map[k].1 = val.clone();
            }
            None => {
                index.insert(name.clone(), map.len());
                map.push((name.clone(), val.clone()));
            }
        }
    }
    let mut used: Vec<bool> = vec![false; map.len()];

    // C walks `rSta`/`rDer` together by index, then the rest group by group; only
    // the two real-parameter groups warn about a value near zero.
    let n_states = read_long(xml.md("numberOfContinuousStates"), 0) as usize;
    let n_real_alg = read_long(xml.md("numberOfRealAlgebraicVariables"), 0) as usize;
    let plan: &[(&str, usize, bool)] = &[
        ("rSta", n_states, false),
        ("rDer", n_states, false),
        ("rAlg", n_real_alg, false),
        ("iAlg", read_long(xml.md("numberOfIntegerAlgebraicVariables"), 0) as usize, false),
        ("bAlg", read_long(xml.md("numberOfBooleanAlgebraicVariables"), 0) as usize, false),
        ("sAlg", read_long(xml.md("numberOfStringAlgebraicVariables"), 0) as usize, false),
        ("rPar", read_long(xml.md("numberOfRealParameters"), 0) as usize, true),
        ("iPar", read_long(xml.md("numberOfIntegerParameters"), 0) as usize, true),
        ("bPar", read_long(xml.md("numberOfBooleanParameters"), 0) as usize, false),
        ("sPar", read_long(xml.md("numberOfStringParameters"), 0) as usize, false),
        ("rAli", read_long(xml.md("numberOfRealAlgebraicAliasVariables"), 0) as usize, false),
        ("iAli", read_long(xml.md("numberOfIntegerAliasVariables"), 0) as usize, false),
        ("bAli", read_long(xml.md("numberOfBooleanAliasVariables"), 0) as usize, false),
        ("sAli", read_long(xml.md("numberOfStringAliasVariables"), 0) as usize, false),
    ];
    // C interleaves the two state groups; the rest follow in order.
    let order: Vec<(&str, usize, bool)> = {
        let mut v = Vec::new();
        for i in 0..n_states {
            v.push(("rSta", i, false));
            v.push(("rDer", i, false));
        }
        for &(g, n, warn) in &plan[2..] {
            for i in 0..n {
                v.push((g, i, warn));
            }
        }
        v
    };
    for (group, i, warn_small) in order {
        let Some(slot) = xml.groups.get_mut(group).and_then(|g| g.get_mut(i)) else { continue };
        let Some(v) = slot.as_mut() else { continue };
        let name = v.get("name").to_string();
        let Some(&k) = index.get(&name) else { continue };
        used[k] = true;
        let value = map[k].1.clone();
        if v.get("isValueChangeable") != "true" {
            omclog::warning!(
                omclog::STDOUT,
                false,
                "It is not possible to override the following quantity: {name}\nIt seems to be structural, final, protected or evaluated or has a non-constant binding.",
            );
            continue;
        }
        omclog::info!(omclog::SOLVER, false, "override {name} = {value}");
        if warn_small && value.parse::<f64>().map(|x| x.abs() < 1e-6).unwrap_or(false) {
            omclog::warning!(
                omclog::STDOUT,
                false,
                "You are overriding {name} with a small value or zero.\nThis could lead to numerically dirty solutions or divisions by zero if not tearingStrictness=veryStrict.",
            );
        }
        v.attrs.insert("start".to_string(), value);
    }
    for (k, (name, _)) in map.iter().enumerate() {
        if !used[k] {
            omclog::warning!(
                omclog::STDOUT,
                false,
                "simulation_input_xml.c: override variable name not found in model: {name}\n",
            );
        }
    }
    omclog::info(omclog::SOLVER, false, "override done!");
}

/// `read_model_description_sizes`: the array-variable counts.
pub fn read_sizes(xml: &InitXml, md: &mut MODEL_DATA) {
    md.nStatesArray = read_long(xml.md("numberOfContinuousStates"), 0) as c_long;
    let n_alg = read_long(xml.md("numberOfRealAlgebraicVariables"), 0) as c_long;
    md.nVariablesRealArray = 2 * md.nStatesArray + n_alg;
    md.nAliasRealArray = read_long(xml.md("numberOfRealAlgebraicAliasVariables"), 0) as c_long;
    md.nParametersRealArray = read_long(xml.md("numberOfRealParameters"), 0) as c_long;

    md.nParametersIntegerArray = read_long(xml.md("numberOfIntegerParameters"), 0) as c_long;
    md.nVariablesIntegerArray = read_long(xml.md("numberOfIntegerAlgebraicVariables"), 0) as c_long;
    md.nAliasIntegerArray = read_long(xml.md("numberOfIntegerAliasVariables"), 0) as c_long;

    md.nParametersBooleanArray = read_long(xml.md("numberOfBooleanParameters"), 0) as c_long;
    md.nVariablesBooleanArray = read_long(xml.md("numberOfBooleanAlgebraicVariables"), 0) as c_long;
    md.nAliasBooleanArray = read_long(xml.md("numberOfBooleanAliasVariables"), 0) as c_long;

    md.nParametersStringArray = read_long(xml.md("numberOfStringParameters"), 0) as c_long;
    md.nVariablesStringArray = read_long(xml.md("numberOfStringAlgebraicVariables"), 0) as c_long;
    md.nAliasStringArray = read_long(xml.md("numberOfStringAliasVariables"), 0) as c_long;
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
        ((si.stopTime - si.startTime) / si.stepSize).round() as modelica_integer
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
    md.realSensitivityData = calloc(md.nSensitivityVars.max(0) as usize);

    let real_attr = |v: &XmlVar, slot: &mut STATIC_REAL_DATA| {
        read_array_real(&mut slot.attribute.start, v.get("start"), 0.0);
        slot.attribute.fixed = read_bool(v.get("fixed"));
        slot.attribute.useNominal = read_bool(v.get("useNominal"));
        read_array_real(&mut slot.attribute.nominal, v.get("nominal"), 1.0);
        read_array_real(&mut slot.attribute.min, v.get("min"), REAL_MIN);
        read_array_real(&mut slot.attribute.max, v.get("max"), REAL_MAX);
        slot.attribute.unit = mk_scon_persist(v.get("unit"));
        slot.attribute.displayUnit = mk_scon_persist(v.get("displayUnit"));
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
    let str_attr = |v: &XmlVar, slot: &mut STATIC_STRING_DATA| {
        slot.attribute.start = mk_scon_persist(v.get("start"));
    };

    let n_states = md.nStatesArray as usize;
    let n_real = md.nVariablesRealArray as usize;
    read_group!(STATIC_REAL_DATA, md.realVarsData, xml.group("rSta"), 0, n_states, maps.vars, real_attr);
    read_group!(STATIC_REAL_DATA, md.realVarsData, xml.group("rDer"), n_states, n_states, maps.vars, real_attr);
    read_group!(STATIC_REAL_DATA, md.realVarsData, xml.group("rAlg"), 2 * n_states, n_real - 2 * n_states, maps.vars, real_attr);
    // `-idaSensitivity`'s parameters and `$Sensitivities.<par>.<state>` results.
    let mut sens_names = HashMap::new();
    read_group!(STATIC_REAL_DATA, md.realSensitivityData, xml.group("rSen"), 0, md.nSensitivityVars.max(0) as usize, sens_names, real_attr);
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

/// C's `initializeOutputFilter` (`simulation_runtime.cpp`): `variableFilter` as a
/// POSIX extended regex over every result name, on top of the protected/hidden
/// verdicts `read_variables` left. An alias that matches keeps the variable it
/// names; a parameter alias only where the format writes parameters cheaply
/// (`mat`).
pub fn initialize_output_filter(md: &mut MODEL_DATA, filter: &str, cheap_aliases_and_params: bool) {
    let pattern = format!("^({filter})$");
    if pattern == "^(.*)$" {
        return;
    }
    let re = match openmodelica_regex::Regex::new(&pattern) {
        Ok(re) => re,
        Err(err) => {
            eprintln!(
                "Failed to compile regular expression: {pattern} with error: {err}. Defaulting to outputting all variables."
            );
            return;
        }
    };
    // A name the model description could not decode is one no pattern matches.
    let dropped = |name: *const c_char| -> modelica_boolean {
        let name = unsafe { core::ffi::CStr::from_ptr(name) };
        !name.to_str().is_ok_and(|n| re.is_match(n)) as modelica_boolean
    };
    macro_rules! filter_group {
        ($n:expr, $vars:expr, $n_alias:expr, $aliases:expr, $params:expr) => {{
            for i in 0..$n as usize {
                let v = unsafe { &mut *$vars.add(i) };
                if v.filterOutput == 0 {
                    v.filterOutput = dropped(v.info.name);
                }
            }
            for i in 0..$n_alias as usize {
                let al = unsafe { &mut *$aliases.add(i) };
                if al.filterOutput != 0 {
                    continue;
                }
                match al.aliasType {
                    0 => {
                        al.filterOutput = dropped(al.info.name);
                        if al.filterOutput == 0 {
                            unsafe { (*$vars.add(al.nameID as usize)).filterOutput = 0 };
                        }
                    }
                    1 => {
                        al.filterOutput = dropped(al.info.name);
                        if al.filterOutput == 0 && cheap_aliases_and_params {
                            unsafe { (*$params.add(al.nameID as usize)).filterOutput = 0 };
                        }
                    }
                    _ => {}
                }
            }
        }};
    }
    filter_group!(md.nVariablesRealArray, md.realVarsData, md.nAliasRealArray, md.realAlias, md.realParameterData);
    filter_group!(
        md.nVariablesIntegerArray,
        md.integerVarsData,
        md.nAliasIntegerArray,
        md.integerAlias,
        md.integerParameterData
    );
    filter_group!(
        md.nVariablesBooleanArray,
        md.booleanVarsData,
        md.nAliasBooleanArray,
        md.booleanAlias,
        md.booleanParameterData
    );
    filter_group!(
        md.nVariablesStringArray,
        md.stringVarsData,
        md.nAliasStringArray,
        md.stringAlias,
        md.stringParameterData
    );
}
