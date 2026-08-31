// Manually written file.
//
// Rust counterpart of `OMCompiler/Compiler/runtime/FMIImpl.c` for the two
// `external "C"` bodies of `OMCompiler/Compiler/Util/FMIExt.mo`.
//
// The C implementation drives fmilib: `fmi_import_get_fmi_version` extracts
// the FMU zip into the working directory and reads the `fmiVersion`
// attribute of `modelDescription.xml`; `fmi*_import_parse_xml` then parses
// the same file and `FMIImpl__initializeFMI{1,2}Import` walk the parsed
// model to build the `FMI.Info` / `FMI.TypeDefinitions` /
// `FMI.ExperimentAnnotation` / `FMI.ModelVariables` records. We do the same
// in pure Rust (the `zip` crate + `roxmltree`), so there is nothing to keep
// alive across the import — `releaseFMIImport` is a no-op (the C version
// frees the fmilib context/instances).
//
// Behavioral notes (all mirroring FMIImpl.c / fmilib, see the inline
// comments at the matching places):
//
//   * The result lists are built by *prepending* in iteration order — i.e.
//     they come back reversed, exactly like the C `mmc_mk_cons` loops — and
//     the caller (`CevalScriptBackend.importFMU`) `listReverse`s the type
//     definitions and model variables. The `fmiNumberOfContinuousStates` /
//     `fmiNumberOfEventIndicators` lists stay in descending order ([n..1]),
//     as in C.
//   * fmilib sorts type definitions by name and enumeration items by value;
//     model variables keep XML document order (sortOrder = 0 in C).
//   * The opaque pointers the C code smuggles through `Option<Integer>`
//     (fmilib context / import instance / variable-list instance) and the
//     per-variable `instance` field carry no meaning in this port (nothing
//     to free, and no template reads them); they are `Some(0)` / `0`.
//   * On failure the C code reports a scripting error and returns
//     `result = false` with NULL/empty outputs; the caller checks
//     `true := b`. fmilib additionally logs its own diagnostic lines
//     ("module = FMIXML, log level = ERROR: ...") through the import
//     logger; of those only the missing-DefaultExperiment-attribute
//     warnings are reproduced here.
//   * `inFMILogLevel` is fmilib's jm_callbacks.log_level.

#![allow(non_snake_case)]

use std::io::Read;
use std::sync::Arc;

use metamodelica::Result;
use arcstr::ArcStr;
use metamodelica::List;

use crate::Error;
use openmodelica_error::ErrorTypes;
use crate::FMI;
use crate::System;

// Error templates from FMIImpl.c (gettext'd there; untranslated here).
const VERSION_ERR: &str = "The FMU version is %s. Unknown/Unsupported FMU version.";
const PARSE_ERR: &str = "Error parsing the modelDescription.xml file.";
const CS_UNSUPPORTED_ERR: &str =
    "The FMU version is 2.0 and FMU type is %s. Unsupported FMU type. Only FMI 2.0 ModelExchange is supported.";

/// `c_add_message(NULL, -1, ErrorType_scripting, ErrorLevel_error, ...)`
/// equivalent: an ad-hoc scripting error with no source location.
fn add_scripting_error(template: &str, tokens: &[&str]) {
    let mut toks: Arc<List<ArcStr>> = Arc::new(List::Nil);
    for t in tokens.iter().rev() {
        toks = metamodelica::cons(ArcStr::from(*t), toks);
    }
    let _ = Error::addMessage(
        ErrorTypes::Message {
            id: -1,
            ty: ErrorTypes::MessageType::SCRIPTING,
            severity: ErrorTypes::Severity::ERROR,
            message: ArcStr::from(template),
        },
        toks,
    );
}

/// FMIImpl.c fills its static jm_callbacks on the first import only, so that
/// call's loglevel sticks for the rest of the process.
static JM_LOG_LEVEL: std::sync::OnceLock<i32> = std::sync::OnceLock::new();

/// jm_log_level_warning.
const JM_LOG_LEVEL_WARNING: i32 = 3;
/// jm_log_level_error.
const JM_LOG_LEVEL_ERROR: i32 = 2;

/// FMIImpl.c's `importlogger`. The tokens read message/level/module because
/// c_add_message reverses them.
fn jm_log(level: i32, level_name: ArcStr, severity: ErrorTypes::Severity, module: &str, message: &str) {
    if level > *JM_LOG_LEVEL.get().unwrap_or(&JM_LOG_LEVEL_WARNING) {
        return;
    }
    let _ = Error::addMessage(
        ErrorTypes::Message {
            id: -1,
            ty: ErrorTypes::MessageType::SCRIPTING,
            severity,
            message: arcstr::literal!("module = %s, log level = %s: %s"),
        },
        metamodelica::list![ArcStr::from(message), level_name, ArcStr::from(module)],
    );
}

fn jm_log_warning(module: &str, message: &str) {
    jm_log(JM_LOG_LEVEL_WARNING, arcstr::literal!("WARNING"), ErrorTypes::Severity::WARNING, module, message);
}

fn jm_log_error(module: &str, message: &str) {
    jm_log(JM_LOG_LEVEL_ERROR, arcstr::literal!("ERROR"), ErrorTypes::Severity::ERROR, module, message);
}

type InitializeFMIImportResult = (
    bool,                                   // result
    Option<i32>,                            // outFMIContext
    Option<i32>,                            // outFMIInstance
    FMI::Info,                              // outFMIInfo
    Arc<List<FMI::TypeDefinitions>>,        // outTypeDefinitionsList
    FMI::ExperimentAnnotation,              // outExperimentAnnotation
    Option<i32>,                            // outModelVariablesInstance
    Arc<List<FMI::ModelVariables>>,         // outModelVariablesList
);

/// The all-defaults failure tuple: `result = false`, everything else empty.
/// (The C code returns NULL records the MM caller never touches because it
/// checks `true := b` first; defaults are this port's NULL-equivalent.)
fn failure() -> InitializeFMIImportResult {
    (
        false,
        Some(0),
        Some(0),
        FMI::Info::default(),
        metamodelica::nil(),
        FMI::ExperimentAnnotation::default(),
        Some(0),
        metamodelica::nil(),
    )
}

pub fn initializeFMIImport(
    inFileName: ArcStr,
    inWorkingDirectory: ArcStr,
    inFMILogLevel: i32,
    inInputConnectors: bool,
    inOutputConnectors: bool,
    inIsModelDescriptionImport: bool,
) -> Result<InitializeFMIImportResult> {
    let _ = JM_LOG_LEVEL.set(inFMILogLevel);
    // `fmi_import_get_fmi_version`: extract the FMU into the working
    // directory, then read the fmiVersion attribute. Every failure mode up
    // to and including "fmiVersion attribute is not 1.0/2.0" maps to the
    // same error the C code raises: fmi_version_to_string yields "unknown"
    // for both the unknown and the unsupported enum value.
    if extract_fmu(&inFileName, &inWorkingDirectory).is_err() {
        add_scripting_error(VERSION_ERR, &["unknown"]);
        return Ok(failure());
    }
    let md_path = format!("{inWorkingDirectory}/modelDescription.xml");
    let xml_bytes = match std::fs::read(&md_path) {
        Ok(b) => b,
        Err(_) => {
            add_scripting_error(VERSION_ERR, &["unknown"]);
            return Ok(failure());
        }
    };
    // fmilib's expat honors the XML encoding declaration; roxmltree only
    // takes UTF-8. Fall back to a Latin-1-family decode for the rare
    // non-UTF-8 modelDescription (OpenModelica itself always writes UTF-8).
    let xml_text: String = match std::str::from_utf8(&xml_bytes) {
        Ok(s) => s.to_owned(),
        Err(_) => encoding_rs::WINDOWS_1252.decode(&xml_bytes).0.into_owned(),
    };
    let doc = match roxmltree::Document::parse(&xml_text) {
        Ok(d) => d,
        Err(_) => {
            // Malformed XML already fails the SAX scan for fmiVersion in C.
            add_scripting_error(VERSION_ERR, &["unknown"]);
            return Ok(failure());
        }
    };
    let root = doc.root_element();
    let version = if root.has_tag_name("fmiModelDescription") { root.attribute("fmiVersion") } else { None };
    match version {
        Some("1.0") => match parse_fmi1(&root, inInputConnectors, inOutputConnectors) {
            Some((info, typedefs, experiment, vars)) => {
                Ok((true, Some(0), Some(0), info, typedefs, experiment, Some(0), vars))
            }
            None => {
                add_scripting_error(PARSE_ERR, &[]);
                Ok(failure())
            }
        },
        Some("2.0") => {
            let Some((info, typedefs, experiment, vars)) = parse_fmi2(&root, inInputConnectors, inOutputConnectors)
            else {
                add_scripting_error(PARSE_ERR, &[]);
                return Ok(failure());
            };
            // "remove the following block once we have support for FMI 2.0
            // CS": a CS-only 2.0 FMU is rejected unless this is a pure
            // model-description import. fmiType 2 = fmi2_fmu_kind_cs.
            if !inIsModelDescriptionImport && info.fmiType == 2 {
                add_scripting_error(CS_UNSUPPORTED_ERR, &["CoSimulation"]);
                return Ok(failure());
            }
            Ok((true, Some(0), Some(0), info, typedefs, experiment, Some(0), vars))
        }
        Some("3.0") => {
            // `fmi3_import_parse_xml` reports what its scheme does not know before
            // anything is read out of the document, then does the same for the
            // FMU's `terminalsAndIcons.xml` if it has one.
            fmi3_scheme_diagnostics(&root, FMI3_MD_ELEMENTS, FMI3_MD_ATTRIBUTES);
            terminals_and_icons_diagnostics(&inWorkingDirectory);
            let Some((info, typedefs, experiment, vars)) = parse_fmi3(&xml_text, inInputConnectors, inOutputConnectors)
            else {
                add_scripting_error(PARSE_ERR, &[]);
                return Ok(failure());
            };
            Ok((true, Some(0), Some(0), info, typedefs, experiment, Some(0), vars))
        }
        // Missing attribute, wrong root element, or an unsupported version
        // string: fmi_version_to_string maps all of these to "unknown".
        _ => {
            add_scripting_error(VERSION_ERR, &["unknown"]);
            Ok(failure())
        }
    }
}

/// The C version frees the fmilib variable list / import instance / context
/// behind the three `Option<Integer>` handles. This port owns all imported
/// data as plain Rust values, so there is nothing to release.
pub fn releaseFMIImport(
    _inFMIModelVariablesInstance: Option<i32>,
    _inFMIInstance: Option<i32>,
    _inFMIContext: Option<i32>,
    _inFMIVersion: ArcStr,
) -> Result<()> {
    Ok(())
}

// ───────────────────────────── FMU extraction ────────────────────────────

/// `fmi_zip_unzip`: extract the whole archive into `dest_dir`, preserving
/// entry paths. Unix permissions are restored like in `Unzip.unzipPath`
/// (rw-r--r-- base for files, rwxr-xr-x for directories).
fn extract_fmu(zip_path: &str, dest_dir: &str) -> Result<(), ()> {
    let bytes = openmodelica_wasi::fs::read(zip_path).map_err(|_| ())?;
    let mut archive = zip::ZipArchive::new(std::io::Cursor::new(bytes)).map_err(|_| ())?;
    for i in 0..archive.len() {
        let mut entry = archive.by_index(i).map_err(|_| ())?;
        // Skip entries that would escape the destination (zip-slip). The C
        // miniunz-based code would happily write them; refusing is strictly
        // safer and never triggers for well-formed FMUs.
        let Some(rel) = entry.enclosed_name() else { continue };
        let out_path = std::path::Path::new(dest_dir).join(rel);
        let out_str = out_path.to_string_lossy();
        if entry.is_dir() {
            openmodelica_wasi::fs::create_dir_all(&out_str).map_err(|_| ())?;
            continue;
        }
        if let Some(parent) = out_path.parent() {
            openmodelica_wasi::fs::create_dir_all(&parent.to_string_lossy()).map_err(|_| ())?;
        }
        let mut contents = Vec::new();
        entry.read_to_end(&mut contents).map_err(|_| ())?;
        openmodelica_wasi::fs::write(&out_str, &contents).map_err(|_| ())?;
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let mode = entry.unix_mode().unwrap_or(0) | 0o644;
            let _ = std::fs::set_permissions(&out_path, std::fs::Permissions::from_mode(mode));
        }
    }
    Ok(())
}

// ───────────────────────────── shared helpers ────────────────────────────

/// `makeStringFMISafe`: replace the characters `. [ ] space , ( )` with `_`.
fn make_string_fmi_safe(s: &str) -> String {
    s.chars()
        .map(|c| match c {
            '.' | '[' | ']' | ' ' | ',' | '(' | ')' => '_',
            c => c,
        })
        .collect()
}

/// Optional description attribute → escaped MM string (the C code runs
/// descriptions through `omc__escapedString(str, 0)`; missing → "").
fn escaped_description(attr: Option<&str>) -> ArcStr {
    match attr {
        None => arcstr::literal!(""),
        Some(d) => System::escapedString(ArcStr::from(d), false),
    }
}

fn attr_or_empty(node: &roxmltree::Node, name: &str) -> ArcStr {
    ArcStr::from(node.attribute(name).unwrap_or(""))
}

/// `[n, n-1, .., 1]` — the C builds these by consing 1..n and never
/// reverses them.
fn descending_int_list(n: u32) -> Arc<List<i32>> {
    let mut list: Arc<List<i32>> = metamodelica::nil();
    for i in 1..=n as i64 {
        list = metamodelica::cons(i as i32, list);
    }
    list
}

fn element_children<'a, 'input>(
    node: &roxmltree::Node<'a, 'input>,
    tag: &'static str,
) -> impl Iterator<Item = roxmltree::Node<'a, 'input>> {
    node.children().filter(move |c| c.is_element() && c.has_tag_name(tag))
}

fn child_element<'a, 'input>(node: &roxmltree::Node<'a, 'input>, tag: &'static str) -> Option<roxmltree::Node<'a, 'input>> {
    element_children(node, tag).next()
}

/// XML boolean (xs:boolean): true/false/1/0.
fn parse_xml_bool(s: &str) -> Option<bool> {
    match s.trim() {
        "true" | "1" => Some(true),
        "false" | "0" => Some(false),
        _ => None,
    }
}

/// One parsed `<ScalarVariable>` type child, shared between FMI 1/2.
struct VariableType<'a> {
    /// Tag of the type element: Real/Integer/Boolean/String/Enumeration.
    tag: &'static str,
    /// Raw `start` attribute (presence = hasStartValue).
    start: Option<&'a str>,
    /// The type element node (for fixed/declaredType lookups).
    node: roxmltree::Node<'a, 'a>,
}

const VARIABLE_TYPE_TAGS: [&str; 5] = ["Real", "Integer", "Boolean", "String", "Enumeration"];

fn variable_type<'a>(sv: &roxmltree::Node<'a, 'a>) -> Option<VariableType<'a>> {
    for child in sv.children().filter(|c| c.is_element()) {
        for tag in VARIABLE_TYPE_TAGS {
            if child.has_tag_name(tag) {
                return Some(VariableType { tag, start: child.attribute("start"), node: child });
            }
        }
    }
    None
}

/// Build the ModelVariables record for one ScalarVariable. Returns `None`
/// on anything fmilib's validating parser would reject (missing required
/// attribute, malformed number). `placements` is the running
/// (yInput, yOutput) connector-placement state shared across the variable
/// loop, mirroring the counters in FMIImpl.c.
#[allow(clippy::too_many_arguments)]
fn build_variable(
    sv: &roxmltree::Node<'_, '_>,
    vt: &VariableType<'_>,
    variability: ArcStr,
    causality: ArcStr,
    is_fixed: bool,
    input_connectors: bool,
    output_connectors: bool,
    placements: &mut (i32, i32),
) -> Option<FMI::ModelVariables> {
    let name = ArcStr::from(make_string_fmi_safe(sv.attribute("name")?));
    let description = escaped_description(sv.attribute("description"));
    let value_reference: u32 = sv.attribute("valueReference")?.trim().parse().ok()?;
    let value_reference = metamodelica::Real::from(value_reference as f64);
    let has_start_value = vt.start.is_some();

    // Connector placement: inputs stack down the left edge, outputs down
    // the right, 25 units apart (xInputPlacement/yInputPlacement & co).
    let (mut x1, mut x2, mut y1, mut y2) = (0, 0, 0, 0);
    if causality == "input" && input_connectors {
        (x1, x2, y1, y2) = (-120, -100, placements.0, placements.0 + 20);
        placements.0 -= 25;
    } else if causality == "output" && output_connectors {
        (x1, x2, y1, y2) = (100, 120, placements.1, placements.1 + 20);
        placements.1 -= 25;
    }

    // The variant-independent fields, then the per-type start value.
    macro_rules! variable {
        ($variant:ident, $base_type:expr, $start_value:expr) => {
            FMI::ModelVariables::$variant {
                // fmilib variable pointer in C; carries no meaning here.
                instance: 0,
                name,
                description,
                baseType: $base_type,
                variability,
                causality,
                hasStartValue: has_start_value,
                startValue: $start_value,
                isFixed: is_fixed,
                valueReference: value_reference,
                x1Placement: x1,
                x2Placement: x2,
                y1Placement: y1,
                y2Placement: y2,
            }
        };
    }
    Some(match vt.tag {
        "Real" => {
            let start = match vt.start {
                Some(s) => metamodelica::Real::from(s.trim().parse::<f64>().ok()?),
                None => metamodelica::Real::from(0.0),
            };
            variable!(REALVARIABLE, arcstr::literal!("Real"), start)
        }
        "Integer" => {
            let start = match vt.start {
                Some(s) => s.trim().parse::<i32>().ok()?,
                None => 0,
            };
            variable!(INTEGERVARIABLE, arcstr::literal!("Integer"), start)
        }
        "Boolean" => {
            let start = match vt.start {
                Some(s) => parse_xml_bool(s)?,
                None => false,
            };
            variable!(BOOLEANVARIABLE, arcstr::literal!("Boolean"), start)
        }
        "String" => {
            let start = ArcStr::from(vt.start.unwrap_or(""));
            variable!(STRINGVARIABLE, arcstr::literal!("String"), start)
        }
        "Enumeration" => {
            // The base type of an enumeration variable is the *name* of its
            // declared type (run through makeStringFMISafe like in C).
            let declared = ArcStr::from(make_string_fmi_safe(vt.node.attribute("declaredType")?));
            let start = match vt.start {
                Some(s) => s.trim().parse::<i32>().ok()?,
                None => 0,
            };
            variable!(ENUMERATIONVARIABLE, declared, start)
        }
        _ => unreachable!("variable_type only yields the five tags above"),
    })
}

/// `<DefaultExperiment>` of either FMI version: startTime (default 0),
/// stopTime (default 1.0), tolerance (default 1e-4) — fmilib's
/// FMI{1,2}_DEFAULT_EXPERIMENT_TOLERANCE. Returns `None` on a malformed
/// number (fmilib parse error). `version` (1 or 2) only names the fmilib
/// module the missing-attribute warnings come from.
fn parse_default_experiment(root: &roxmltree::Node<'_, '_>, version: u32) -> Option<FMI::ExperimentAnnotation> {
    let de = child_element(root, "DefaultExperiment");
    // Each fmilib getter warns when its attribute was absent; FMIImpl.c reads
    // them in this order.
    let mut values = [0.0, 1.0, 1e-4];
    for (value, (getter, attribute)) in values
        .iter_mut()
        .zip([("start", "startTime"), ("stop", "stopTime"), ("tolerance", "tolerance")])
    {
        match de.as_ref().and_then(|de| de.attribute(attribute)) {
            Some(v) => *value = v.trim().parse().ok()?,
            None => jm_log_warning(
                &format!("FMI{version}XML"),
                &format!(
                    "fmi{version}_xml_get_default_experiment_{getter}: \
                     returning default value, since no attribute was defined in modelDescription"
                ),
            ),
        }
    }
    Some(FMI::ExperimentAnnotation {
        fmiExperimentStartTime: metamodelica::Real::from(values[0]),
        fmiExperimentStopTime: metamodelica::Real::from(values[1]),
        fmiExperimentTolerance: metamodelica::Real::from(values[2]),
    })
}

/// Prepend `items` (already in fmilib order) onto a list, so the result is
/// reversed exactly like the C `mmc_mk_cons` loops produce.
fn prepended_list<T: Clone>(items: impl IntoIterator<Item = T>) -> Arc<List<T>> {
    let mut list: Arc<List<T>> = metamodelica::nil();
    for item in items {
        list = metamodelica::cons(item, list);
    }
    list
}

/// An enumeration `<Item>`'s pieces: (value, ENUMERATIONITEM record).
/// FMI2 items carry an explicit integer value; FMI1 items are implicitly
/// numbered by document position (1-based ordinal).
fn enumeration_items(
    enum_node: &roxmltree::Node<'_, '_>,
    explicit_values: bool,
) -> Option<Vec<(i32, FMI::EnumerationItem)>> {
    let mut items = Vec::new();
    for (idx, item) in element_children(enum_node, "Item").enumerate() {
        let value = if explicit_values {
            item.attribute("value")?.trim().parse::<i32>().ok()?
        } else {
            (idx + 1) as i32
        };
        items.push((
            value,
            FMI::EnumerationItem {
                // name is a required attribute in both FMI versions.
                name: ArcStr::from(item.attribute("name")?),
                description: attr_or_empty(&item, "description"),
            },
        ));
    }
    // fmilib sorts enum items by value (duplicates only log an error).
    items.sort_by_key(|(v, _)| *v);
    Some(items)
}

// ───────────────────────────────── FMI 2.0 ───────────────────────────────

type ParsedModelDescription = (
    FMI::Info,
    Arc<List<FMI::TypeDefinitions>>,
    FMI::ExperimentAnnotation,
    Arc<List<FMI::ModelVariables>>,
);

fn parse_fmi2(
    root: &roxmltree::Node<'_, '_>,
    input_connectors: bool,
    output_connectors: bool,
) -> Option<ParsedModelDescription> {
    let model_name = ArcStr::from(root.attribute("modelName")?);
    let guid = ArcStr::from(root.attribute("guid")?);

    // FMU kind from the presence of <ModelExchange>/<CoSimulation>;
    // me = 1, cs = 2, me_and_cs = 3 (fmi2_fmu_kind_enu_t). FMIImpl folds
    // me_and_cs back to me and takes the matching modelIdentifier. A file
    // with neither element fails fmilib's validation.
    let me = child_element(root, "ModelExchange");
    let cs = child_element(root, "CoSimulation");
    let (fmi_type, model_identifier) = match (me, cs) {
        // modelIdentifier is required on both elements in the FMI2 schema.
        (Some(me), _) => (1, ArcStr::from(me.attribute("modelIdentifier")?)),
        (None, Some(cs)) => (2, ArcStr::from(cs.attribute("modelIdentifier")?)),
        (None, None) => return None,
    };

    // Continuous states: fmilib counts the <Derivatives> unknowns in
    // <ModelStructure> (fmi2_xml_get_number_of_continuous_states).
    let number_of_continuous_states = child_element(root, "ModelStructure")
        .and_then(|ms| child_element(&ms, "Derivatives"))
        .map(|d| d.children().filter(|c| c.is_element()).count() as u32)
        .unwrap_or(0);
    let number_of_event_indicators: u32 = match root.attribute("numberOfEventIndicators") {
        Some(v) => v.trim().parse().ok()?,
        None => 0,
    };

    let info = FMI::Info {
        fmiVersion: arcstr::literal!("2.0"),
        fmiType: fmi_type,
        fmiModelName: model_name,
        fmiModelIdentifier: model_identifier,
        fmiGuid: guid,
        fmiDescription: escaped_description(root.attribute("description")),
        fmiGenerationTool: attr_or_empty(root, "generationTool"),
        fmiGenerationDateAndTime: attr_or_empty(root, "generationDateAndTime"),
        fmiVariableNamingConvention: ArcStr::from(root.attribute("variableNamingConvention").unwrap_or("flat")),
        fmiNumberOfContinuousStates: descending_int_list(number_of_continuous_states),
        fmiNumberOfEventIndicators: descending_int_list(number_of_event_indicators),
    };

    let typedefs = parse_type_definitions(root, "SimpleType", true)?;
    let experiment = parse_default_experiment(root, 2)?;

    // Model variables in document order (C uses sortOrder = 0).
    let mut variables: Vec<FMI::ModelVariables> = Vec::new();
    let mut placements = (60, 60);
    if let Some(mv) = child_element(root, "ModelVariables") {
        for sv in element_children(&mv, "ScalarVariable") {
            let vt = variable_type(&sv)?;
            // FMI2 defaults: causality "local", variability "continuous".
            let causality_attr = sv.attribute("causality").unwrap_or("local");
            let variability_attr = sv.attribute("variability").unwrap_or("continuous");
            // getFMI2ModelVariableCausality: input/output/parameter pass
            // through, everything else (local, calculatedParameter,
            // independent, unknown) maps to "".
            let causality = match causality_attr {
                "input" => arcstr::literal!("input"),
                "output" => arcstr::literal!("output"),
                "parameter" => arcstr::literal!("parameter"),
                _ => arcstr::literal!(""),
            };
            // getFMI2ModelVariableVariability: only "constant" passes
            // through ("fixed"/"tunable"/"discrete"/"continuous" → "").
            let variability = match variability_attr {
                "constant" => arcstr::literal!("constant"),
                _ => arcstr::literal!(""),
            };
            // FMI2 isFixed: variability attribute equals "fixed".
            let is_fixed = variability_attr == "fixed";
            variables.push(build_variable(
                &sv, &vt, variability, causality, is_fixed,
                input_connectors, output_connectors, &mut placements,
            )?);
        }
    }
    Some((info, typedefs, experiment, prepended_list(variables)))
}

// ───────────────────────────────── FMI 1.0 ───────────────────────────────

fn parse_fmi1(
    root: &roxmltree::Node<'_, '_>,
    input_connectors: bool,
    output_connectors: bool,
) -> Option<ParsedModelDescription> {
    let model_name = ArcStr::from(root.attribute("modelName")?);
    let model_identifier = ArcStr::from(root.attribute("modelIdentifier")?);
    let guid = ArcStr::from(root.attribute("guid")?);

    // FMI1 kind from <Implementation>: none → me (0),
    // CoSimulation_StandAlone → 1, CoSimulation_Tool → 2
    // (fmi1_fmu_kind_enu_t; see also FMI.getFMIType's "1.0" cases).
    let fmi_type = match child_element(root, "Implementation") {
        None => 0,
        Some(imp) => {
            if child_element(&imp, "CoSimulation_StandAlone").is_some() {
                1
            } else if child_element(&imp, "CoSimulation_Tool").is_some() {
                2
            } else {
                // <Implementation> with neither child fails fmilib's parse.
                return None;
            }
        }
    };

    // Both counts are required attributes in FMI 1.0.
    let number_of_continuous_states: u32 = root.attribute("numberOfContinuousStates")?.trim().parse().ok()?;
    let number_of_event_indicators: u32 = root.attribute("numberOfEventIndicators")?.trim().parse().ok()?;

    let info = FMI::Info {
        fmiVersion: arcstr::literal!("1.0"),
        fmiType: fmi_type,
        fmiModelName: model_name,
        fmiModelIdentifier: model_identifier,
        fmiGuid: guid,
        fmiDescription: escaped_description(root.attribute("description")),
        fmiGenerationTool: attr_or_empty(root, "generationTool"),
        fmiGenerationDateAndTime: attr_or_empty(root, "generationDateAndTime"),
        fmiVariableNamingConvention: ArcStr::from(root.attribute("variableNamingConvention").unwrap_or("flat")),
        fmiNumberOfContinuousStates: descending_int_list(number_of_continuous_states),
        fmiNumberOfEventIndicators: descending_int_list(number_of_event_indicators),
    };

    let typedefs = parse_type_definitions(root, "Type", false)?;
    let experiment = parse_default_experiment(root, 1)?;

    let mut variables: Vec<FMI::ModelVariables> = Vec::new();
    let mut placements = (60, 60);
    if let Some(mv) = child_element(root, "ModelVariables") {
        for sv in element_children(&mv, "ScalarVariable") {
            let vt = variable_type(&sv)?;
            // FMI1 defaults: causality "internal", variability "continuous".
            // getFMI1ModelVariableCausality: input/output pass through,
            // internal/none/unknown → "".
            let causality = match sv.attribute("causality").unwrap_or("internal") {
                "input" => arcstr::literal!("input"),
                "output" => arcstr::literal!("output"),
                _ => arcstr::literal!(""),
            };
            // getFMI1ModelVariableVariability: constant/parameter pass
            // through, discrete/continuous/unknown → "".
            let variability = match sv.attribute("variability").unwrap_or("continuous") {
                "constant" => arcstr::literal!("constant"),
                "parameter" => arcstr::literal!("parameter"),
                _ => arcstr::literal!(""),
            };
            // FMI1 isFixed (fmi1_xml_get_variable_is_fixed = structKind==start
            // && type->isFixed): a start value is present AND the `fixed`
            // attribute (default true) is set.
            //
            // fmilib quirk: `fmi1_xml_handle_String` parses the `fixed`
            // attribute but — unlike the Real/Integer/Boolean/Enumeration
            // handlers — never assigns it back to `start->typeBase.isFixed`,
            // which therefore keeps its init default of 0. So a String
            // variable's isFixed is *always* false regardless of `start`/`fixed`.
            // Mirror that, otherwise FMU-imported String parameters become
            // fixed bindings (`= "x"`) instead of the unbound `(start="x")`
            // declarations the C/fmilib oracle produces.
            let is_fixed = if vt.tag == "String" {
                false
            } else {
                match (vt.start, vt.node.attribute("fixed")) {
                    (None, _) => false,
                    (Some(_), None) => true,
                    (Some(_), Some(f)) => parse_xml_bool(f)?,
                }
            };
            variables.push(build_variable(
                &sv, &vt, variability, causality, is_fixed,
                input_connectors, output_connectors, &mut placements,
            )?);
        }
    }
    Some((info, typedefs, experiment, prepended_list(variables)))
}

// ────────────────────────────── TypeDefinitions ──────────────────────────

/// Walk `<TypeDefinitions>` and collect the enumeration types. `type_tag`
/// is `SimpleType` (FMI2) or `Type` (FMI1); `explicit_values` selects
/// FMI2-style `<Item value=…>` vs FMI1's implicit 1-based ordinals.
///
/// fmilib sorts the typedef table by name (jm_compare_named/strcmp), and
/// FMIImpl iterates it in that order consing each enum type — so the
/// returned (reversed) list has the names in *descending* byte order; the
/// MM caller's listReverse restores ascending.
fn parse_type_definitions(
    root: &roxmltree::Node<'_, '_>,
    type_tag: &'static str,
    explicit_values: bool,
) -> Option<Arc<List<FMI::TypeDefinitions>>> {
    let mut enums: Vec<FMI::TypeDefinitions> = Vec::new();
    if let Some(td) = child_element(root, "TypeDefinitions") {
        for ty in element_children(&td, type_tag) {
            let name = ty.attribute("name")?;
            // Only enumeration types are imported (C `continue`s otherwise).
            let enum_tag = if explicit_values { "Enumeration" } else { "EnumerationType" };
            let Some(enum_node) = child_element(&ty, enum_tag) else { continue };
            let items = enumeration_items(&enum_node, explicit_values)?;
            // min/max: FMI2 takes the smallest/largest item value (items
            // are value-sorted); FMI1 reads the EnumerationType min/max
            // attributes (fmilib defaults: min 1, max INT_MAX).
            let (min, max) = if explicit_values {
                (
                    items.first().map(|(v, _)| *v).unwrap_or(0),
                    items.last().map(|(v, _)| *v).unwrap_or(0),
                )
            } else {
                let min = match enum_node.attribute("min") {
                    Some(v) => v.trim().parse().ok()?,
                    None => 1,
                };
                let max = match enum_node.attribute("max") {
                    Some(v) => v.trim().parse().ok()?,
                    None => i32::MAX,
                };
                (min, max)
            };
            enums.push(FMI::TypeDefinitions {
                name: ArcStr::from(make_string_fmi_safe(name)),
                description: attr_or_empty(&ty, "description"),
                quantity: attr_or_empty(&enum_node, "quantity"),
                min,
                max,
                // Items ascending by value: the C loop conses from the last
                // item down to the first, ending head-first at item 1.
                items: prepended_list(items.into_iter().rev().map(|(_, item)| item)),
            });
        }
    }
    // fmilib's name-sorted table order, then reversed by prepending.
    enums.sort_by(|a, b| a.name.as_bytes().cmp(b.name.as_bytes()));
    Some(prepended_list(enums))
}

// ───────────────────────────────── FMI 3.0 ───────────────────────────────
//
// fmilib parses a 3.0 FMU with a generic XML driver plus a *scheme*: the element
// and attribute names it knows. Anything outside it is reported, which an import
// prints — hence the tables and the two diagnostics passes below.

const FMI3XML: &str = "FMI3XML";
const XSI_NS: &str = "http://www.w3.org/2001/XMLSchema-instance";

/// `FMI3_XML_ELMLIST_MODEL_DESCR`.
const FMI3_MD_ELEMENTS: &[&str] = &[
    "fmiModelDescription", "ModelExchange", "CoSimulation", "ScheduledExecution", "SourceFiles",
    "File", "UnitDefinitions", "Unit", "BaseUnit", "DisplayUnit", "TypeDefinitions", "SimpleType",
    "Item", "DefaultExperiment", "VendorAnnotations", "Tool", "ModelVariables", "Dimension",
    "Start", "Alias", "Annotations", "LogCategories", "Category", "Float64Type", "Float32Type",
    "Int64Type", "Int32Type", "Int16Type", "Int8Type", "UInt64Type", "UInt32Type", "UInt16Type",
    "UInt8Type", "BooleanType", "BinaryType", "ClockType", "StringType", "EnumerationType",
    "ModelStructure", "Output", "ContinuousStateDerivative", "ClockedState", "InitialUnknown",
    "EventIndicator", "Float64", "Float32", "Int64", "Int32", "Int16", "Int8", "UInt64", "UInt32",
    "UInt16", "UInt8", "Boolean", "Binary", "Clock", "String", "Enumeration",
];

/// `FMI3_XML_ATTRLIST_MODEL_DESCR`, with `FMI3_SI_BASE_UNITS` spelled out.
const FMI3_MD_ATTRIBUTES: &[&str] = &[
    "fmiVersion", "name", "description", "factor", "offset", "inverse",
    "kg", "m", "s", "A", "K", "mol", "cd", "rad",
    "quantity", "unit", "displayUnit", "relativeQuantity", "unbounded", "min", "max", "nominal",
    "declaredType", "start", "derivative", "reinit", "startTime", "stopTime", "tolerance",
    "stepSize", "value", "valueReference", "variability", "causality", "initial", "previous",
    "clocks", "canHandleMultipleSetPerTimeInstant", "intermediateUpdate", "mimeType", "maxSize",
    "intervalVariability", "canBeDeactivated", "priority", "intervalDecimal", "shiftDecimal",
    "supportsFraction", "resolution", "intervalCounter", "shiftCounter", "dependencies",
    "dependenciesKind", "modelName", "modelIdentifier", "instantiationToken", "author",
    "copyright", "license", "version", "generationTool", "generationDateAndTime",
    "variableNamingConvention", "numberOfEventIndicators", "input", "needsExecutionTool",
    "canBeInstantiatedOnlyOncePerProcess", "canGetAndSetFMUState", "canSerializeFMUState",
    "providesDirectionalDerivatives", "providesDirectionalDerivative", "providesAdjointDerivatives",
    "providesPerElementDependencies", "providesEvaluateDiscreteStates",
    "needsCompletedIntegratorStep", "canHandleVariableCommunicationStepSize",
    "fixedInternalStepSize", "maxOutputDerivativeOrder", "recommendedIntermediateInputSmoothness",
    "providesIntermediateUpdate", "mightReturnEarlyFromDoStep",
    "canReturnEarlyAfterIntermediateUpdate", "hasEventMode",
];

/// `FMI_XML_ELMLIST_TERM_ICON` / `FMI_XML_ATTRLIST_TERM_ICON`: the whole scheme.
const TERM_ICON_ELEMENTS: &[&str] = &[
    "fmiTerminalsAndIcons", "Terminals", "Terminal", "TerminalMemberVariable",
    "TerminalStreamMemberVariable", "TerminalGraphicalRepresentation",
];
const TERM_ICON_ATTRIBUTES: &[&str] = &["fmiVersion", "name", "description"];

/// The attribute half of `fmi3_parse_element_start`. An unknown element is skipped
/// along with its subtree, as `skipElementCnt` does.
fn fmi3_scheme_diagnostics(node: &roxmltree::Node<'_, '_>, elements: &[&str], attributes: &[&str]) {
    if !elements.contains(&node.tag_name().name()) {
        return;
    }
    for a in node.attributes() {
        match a.namespace() {
            Some(XSI_NS) => match a.name() {
                "noNamespaceSchemaLocation" => jm_log_warning(
                    FMI3XML,
                    &format!(
                        "Attribute noNamespaceSchemaLocation='{}' is ignored. Using standard fmiModelDescription.xsd.",
                        a.value()
                    ),
                ),
                "nil" | "type" => jm_log_warning(
                    FMI3XML,
                    &format!("Attribute {{{XSI_NS}}}{}={} is ignored", a.name(), a.value()),
                ),
                "schemaLocation" => {}
                other => jm_log_error(
                    FMI3XML,
                    &format!("Unknown attribute '{XSI_NS}|{other}={}' in XML", a.value()),
                ),
            },
            // A namespace fmilib has no expat prefix for reaches the name test bare.
            _ if attributes.contains(&a.name()) => {}
            _ if a.name().starts_with("providesPartialDerivativesOf_") => jm_log_warning(
                FMI3XML,
                &format!(
                    "FMI API function fmiGetPartialDerivatives is removed from the specification. \
                     Attribute {} will be ignored.",
                    a.name()
                ),
            ),
            _ => jm_log_error(FMI3XML, &format!("Unknown attribute '{}={}' in XML", a.name(), a.value())),
        }
    }
    for child in node.children().filter(|c| c.is_element()) {
        fmi3_scheme_diagnostics(&child, elements, attributes);
    }
}

/// `fmi3_xml_parse_terminals_and_icons`, run after the model description. A missing
/// or unreadable file is not an error (fmilib logs it at info level, which is dropped).
fn terminals_and_icons_diagnostics(working_directory: &str) {
    let path = format!("{working_directory}/terminalsAndIcons/terminalsAndIcons.xml");
    let Ok(bytes) = openmodelica_wasi::fs::read(&path) else { return };
    let Ok(text) = String::from_utf8(bytes) else { return };
    let Ok(doc) = roxmltree::Document::parse(&text) else { return };
    fmi3_scheme_diagnostics(&doc.root_element(), TERM_ICON_ELEMENTS, TERM_ICON_ATTRIBUTES);
}

/// `FMIImpl__initializeFMI3Import`, over the model description `openmodelica_fmi`
/// read. The `fmi3_import_get_*` calls C makes are a *view* of that document, so only
/// the view is written out: fmilib's spellings, and the reversed lists the
/// MetaModelica caller expects.
///
/// FMI 1.0 and 2.0 keep their own readers below — they must reproduce fmilib's
/// quirks, which the shared reader deliberately does not have.
fn parse_fmi3(
    xml: &str,
    input_connectors: bool,
    output_connectors: bool,
) -> Option<ParsedModelDescription> {
    use openmodelica_fmi::{Causality, Dimension, Start, VarType, Variability};

    let md = openmodelica_fmi::model_description(xml).ok()?;

    // FMIImpl takes the model identifier of the interface it imports, Model Exchange
    // first (fmi3_fmu_kind_enu_t: me = 2, cs = 4, se = 8).
    let (fmi_type, interface) = [(2, &md.model_exchange), (4, &md.co_simulation), (8, &md.scheduled_execution)]
        .into_iter()
        .find_map(|(kind, i)| Some((kind, i.as_ref()?)))?;

    let info = FMI::Info {
        fmiVersion: arcstr::literal!("3.0"),
        fmiType: fmi_type,
        fmiModelName: ArcStr::from(md.model_name.as_str()),
        fmiModelIdentifier: ArcStr::from(interface.model_identifier.as_str()),
        fmiGuid: ArcStr::from(md.instantiation_token.as_str()),
        fmiDescription: escaped_description(md.description.as_deref()),
        fmiGenerationTool: ArcStr::from(md.generation_tool.as_deref().unwrap_or("")),
        fmiGenerationDateAndTime: ArcStr::from(md.generation_date_and_time.as_deref().unwrap_or("")),
        fmiVariableNamingConvention: ArcStr::from(md.variable_naming_convention.as_str()),
        // FMI 3.0 has no scalar counts: both come from the <ModelStructure> lists.
        fmiNumberOfContinuousStates: descending_int_list(md.model_structure.continuous_state_derivatives.len() as u32),
        fmiNumberOfEventIndicators: descending_int_list(md.number_of_event_indicators),
    };

    // Only enumeration types are imported, as in FMI 1.0/2.0.
    let mut enums: Vec<FMI::TypeDefinitions> = Vec::new();
    for td in md.type_definitions.iter().filter(|t| t.ty == VarType::Enumeration) {
        let mut items: Vec<_> = td.items.iter().collect();
        items.sort_by_key(|i| i.value);
        enums.push(FMI::TypeDefinitions {
            name: ArcStr::from(make_string_fmi_safe(&td.name)),
            description: ArcStr::from(td.description.as_deref().unwrap_or("")),
            quantity: ArcStr::from(td.quantity.as_deref().unwrap_or("")),
            min: items.first().map(|i| i.value as i32).unwrap_or(0),
            max: items.last().map(|i| i.value as i32).unwrap_or(0),
            items: prepended_list(items.into_iter().rev().map(|i| FMI::EnumerationItem {
                name: ArcStr::from(i.name.as_str()),
                description: ArcStr::from(i.description.as_deref().unwrap_or("")),
            })),
        });
    }
    enums.sort_by(|a, b| a.name.as_bytes().cmp(b.name.as_bytes()));

    let experiment = fmi3_default_experiment(&md);

    let mut variables: Vec<FMI::ModelVariables> = Vec::new();
    let mut placements = (60, 60);
    for v in &md.variables {
        // getFMI3ModelVariableCausality: a structural parameter is reported as a
        // parameter, and the independent one is named so the wrapper can leave it out.
        let causality = match v.causality {
            Causality::Input => arcstr::literal!("input"),
            Causality::Output => arcstr::literal!("output"),
            Causality::Parameter | Causality::StructuralParameter => arcstr::literal!("parameter"),
            Causality::Independent => arcstr::literal!("independent"),
            Causality::Local | Causality::CalculatedParameter => arcstr::literal!(""),
        };
        // getFMI3ModelVariableVariability: only "constant" is passed through; the
        // rest leaves the wrapper on the Modelica default.
        let variability = if v.variability == Variability::Constant {
            arcstr::literal!("constant")
        } else {
            arcstr::literal!("")
        };
        // An enumeration's Modelica type is the name of its declared type; Binary
        // and Clock have none.
        let declared = ArcStr::from(make_string_fmi_safe(v.declared_type.as_deref().unwrap_or("")));
        let base_type = match v.ty {
            VarType::Float32 | VarType::Float64 => arcstr::literal!("Real"),
            VarType::Int8 | VarType::UInt8 | VarType::Int16 | VarType::UInt16
            | VarType::Int32 | VarType::UInt32 | VarType::Int64 | VarType::UInt64 => arcstr::literal!("Integer"),
            VarType::Boolean => arcstr::literal!("Boolean"),
            VarType::String => arcstr::literal!("String"),
            VarType::Enumeration => declared.clone(),
            VarType::Binary | VarType::Clock => arcstr::literal!(""),
        };
        // `fmi3_base_type_to_string` has no name for the two types outside the
        // base-type enum's string table.
        let fmi_type = match v.ty {
            VarType::Binary | VarType::Clock => arcstr::literal!("Error"),
            t => ArcStr::from(t.as_str()),
        };
        // A dimension given by a value reference is only known once the FMU is
        // instantiated, and is reported as 0.
        let dimensions = prepended_list(v.dimensions.iter().rev().map(|d| match d {
            Dimension::Fixed(k) => *k as i32,
            Dimension::ValueReference(_) => 0,
        }));
        // The records take a list because a variable can be an array; C reads only the
        // scalar start.
        let start = if v.dimensions.is_empty() { v.start.as_ref() } else { None };

        let (mut x1, mut x2, mut y1, mut y2) = (0, 0, 0, 0);
        if causality == "input" && input_connectors {
            (x1, x2, y1, y2) = (-120, -100, placements.0, placements.0 + 20);
            placements.0 -= 25;
        } else if causality == "output" && output_connectors {
            (x1, x2, y1, y2) = (100, 120, placements.1, placements.1 + 20);
            placements.1 -= 25;
        }

        macro_rules! variable {
            ($variant:ident, $start_value:expr $(, $extra:ident : $value:expr)*) => {
                FMI::ModelVariables::$variant {
                    // fmilib variable pointer in C; carries no meaning here.
                    instance: 0,
                    name: ArcStr::from(make_string_fmi_safe(&v.name)),
                    description: escaped_description(v.description.as_deref()),
                    baseType: base_type,
                    fmiType: fmi_type,
                    variability,
                    causality,
                    hasStartValue: v.start.is_some(),
                    isFixed: v.variability == Variability::Fixed,
                    valueReference: v.value_reference as i32,
                    dimensions,
                    $($extra: $value,)*
                    startValue: $start_value,
                    x1Placement: x1,
                    x2Placement: x2,
                    y1Placement: y1,
                    y2Placement: y2,
                }
            };
        }
        let first_int = || match start {
            Some(Start::Ints(i)) => prepended_list(i.first().map(|&i| i as i32)),
            _ => metamodelica::nil(),
        };
        variables.push(match v.ty {
            VarType::Float32 | VarType::Float64 => variable!(
                FMI3REALVARIABLE,
                match start {
                    Some(Start::Reals(r)) => prepended_list(r.first().map(|&r| metamodelica::Real::from(r))),
                    _ => metamodelica::nil(),
                }
            ),
            VarType::Boolean => variable!(
                FMI3BOOLEANVARIABLE,
                match start {
                    Some(Start::Bools(b)) => prepended_list(b.first().copied()),
                    _ => metamodelica::nil(),
                }
            ),
            VarType::String => variable!(
                FMI3STRINGVARIABLE,
                match start {
                    Some(Start::Strings(s)) => prepended_list(s.first().map(|s| ArcStr::from(s.as_str()))),
                    _ => metamodelica::nil(),
                }
            ),
            VarType::Enumeration => variable!(FMI3ENUMERATIONVARIABLE, first_int(), declaredType: declared),
            VarType::Binary => variable!(
                FMI3BINARYVARIABLE,
                // `getFMI3ModelVariableStartValue` reads no start for a Binary.
                metamodelica::nil(),
                mimeType: ArcStr::from(v.binary.as_ref().map(|b| b.mime_type.as_str()).unwrap_or("")),
                maxSize: v.binary.as_ref().and_then(|b| b.max_size).unwrap_or(0) as i32
            ),
            VarType::Clock => FMI::ModelVariables::FMI3CLOCKVARIABLE {
                instance: 0,
                name: ArcStr::from(make_string_fmi_safe(&v.name)),
                description: escaped_description(v.description.as_deref()),
                baseType: base_type,
                fmiType: fmi_type,
                variability,
                causality,
                hasStartValue: v.start.is_some(),
                isFixed: v.variability == Variability::Fixed,
                valueReference: v.value_reference as i32,
                dimensions,
                intervalVariability: ArcStr::from(
                    v.clock.as_ref().map(|c| interval_variability_string(c.interval_variability)).unwrap_or(""),
                ),
                intervalDecimal: metamodelica::Real::from(
                    v.clock.as_ref().and_then(|c| c.interval_decimal).unwrap_or(0.0),
                ),
                hasIntervalDecimal: v.clock.as_ref().is_some_and(|c| c.interval_decimal.is_some()),
                x1Placement: x1,
                x2Placement: x2,
                y1Placement: y1,
                y2Placement: y2,
            },
            _ => variable!(FMI3INTEGERVARIABLE, first_int()),
        });
    }
    Some((info, prepended_list(enums), experiment, prepended_list(variables)))
}

/// `getFMI3IntervalVariability`, which FMI Library has no `to_string` for.
fn interval_variability_string(v: openmodelica_fmi::IntervalVariability) -> &'static str {
    use openmodelica_fmi::IntervalVariability as I;
    match v {
        I::Constant => "constant",
        I::Fixed => "fixed",
        I::Tunable => "tunable",
        I::Changing => "changing",
        I::Countdown => "countdown",
        I::Triggered => "triggered",
    }
}

/// `<DefaultExperiment>`: each fmilib getter warns when its attribute was absent,
/// and FMIImpl.c reads them in this order.
fn fmi3_default_experiment(md: &openmodelica_fmi::ModelDescription) -> FMI::ExperimentAnnotation {
    let de = md.default_experiment;
    let mut values = [0.0, 1.0, 1e-4];
    for (value, (getter, given)) in values.iter_mut().zip([
        ("start", de.and_then(|d| d.start_time)),
        ("stop", de.and_then(|d| d.stop_time)),
        ("tolerance", de.and_then(|d| d.tolerance)),
    ]) {
        match given {
            Some(v) => *value = v,
            None => jm_log_warning(
                FMI3XML,
                &format!(
                    "fmi3_xml_get_default_experiment_{getter}: returning default value, \
                     since no attribute was defined in modelDescription"
                ),
            ),
        }
    }
    FMI::ExperimentAnnotation {
        fmiExperimentStartTime: metamodelica::Real::from(values[0]),
        fmiExperimentStopTime: metamodelica::Real::from(values[1]),
        fmiExperimentTolerance: metamodelica::Real::from(values[2]),
    }
}
