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
//     logger; those internal lines are not reproduced here, only the
//     errors FMIImpl.c itself raises.
//   * `inFMILogLevel` only configures the fmilib logger in C; with no
//     fmilib here it is unused.

#![allow(non_snake_case)]

use std::io::Read;
use std::sync::Arc;

use anyhow::Result;
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
    _inFMILogLevel: i32,
    inInputConnectors: bool,
    inOutputConnectors: bool,
    inIsModelDescriptionImport: bool,
) -> Result<InitializeFMIImportResult> {
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
/// number (fmilib parse error).
fn parse_default_experiment(root: &roxmltree::Node<'_, '_>) -> Option<FMI::ExperimentAnnotation> {
    let mut start = 0.0;
    let mut stop = 1.0;
    let mut tolerance = 1e-4;
    if let Some(de) = child_element(root, "DefaultExperiment") {
        if let Some(v) = de.attribute("startTime") {
            start = v.trim().parse().ok()?;
        }
        if let Some(v) = de.attribute("stopTime") {
            stop = v.trim().parse().ok()?;
        }
        if let Some(v) = de.attribute("tolerance") {
            tolerance = v.trim().parse().ok()?;
        }
    }
    Some(FMI::ExperimentAnnotation {
        fmiExperimentStartTime: metamodelica::Real::from(start),
        fmiExperimentStopTime: metamodelica::Real::from(stop),
        fmiExperimentTolerance: metamodelica::Real::from(tolerance),
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
    let experiment = parse_default_experiment(root)?;

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
    let experiment = parse_default_experiment(root)?;

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
