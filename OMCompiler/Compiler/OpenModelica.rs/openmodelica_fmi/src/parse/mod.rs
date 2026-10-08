//! `modelDescription.xml` → [`ModelDescription`], one parser per FMI version.
//!
//! The parsers are lenient in the same way importers have to be: a missing
//! required attribute is an error, but an unknown element or attribute is
//! ignored, and a defaulted attribute that is absent takes its default.

mod v1;
mod v2;
mod v3;

use crate::description::*;
pub(crate) use v3::unknowns as unknowns3;
use crate::{Error, Result};
use roxmltree::{Document, Node};

pub fn model_description(xml: &str) -> Result<ModelDescription> {
    let doc = Document::parse(xml).map_err(|e| Error::Xml(e.to_string()))?;
    let root = doc.root_element();
    if root.tag_name().name() != "fmiModelDescription" {
        return Err(Error::Xml(format!(
            "root element is <{}>, not <fmiModelDescription>",
            root.tag_name().name()
        )));
    }
    let version = attr(root, "fmiVersion").ok_or_else(|| Error::Xml("no fmiVersion".into()))?;
    let mut md = match version.split('.').next().unwrap_or_default() {
        "1" => v1::parse(root)?,
        "2" => v2::parse(root)?,
        "3" => v3::parse(root)?,
        _ => return Err(Error::UnsupportedVersion(version.to_string())),
    };
    md.fmi_version_string = version.to_string();
    md.tool_annotations = tool_annotations(root, xml);
    md.resolve_declared_types();
    md.build_index();
    Ok(md)
}

/// `<Annotations>`, kept as the raw XML the tool wrote: nothing here interprets a
/// vendor's extension, but the OpenModelica `<Figures>` annotation is what the
/// plotter reads. FMI 3.0 names the entries `<Annotation type=…>`, 1.0 and 2.0
/// `<Tool name=…>`; both are read.
fn tool_annotations(root: Node, xml: &str) -> Vec<ToolAnnotation> {
    root.children()
        .filter(|n| matches!(n.tag_name().name(), "Annotations" | "VendorAnnotations"))
        .flat_map(|a| a.children())
        .filter_map(|t| {
            let name = match t.tag_name().name() {
                "Tool" => attr(t, "name")?,
                "Annotation" => attr(t, "type")?,
                _ => return None,
            };
            Some(ToolAnnotation { name: name.to_string(), xml: xml.get(t.range())?.to_string() })
        })
        .collect()
}

pub(crate) fn attr<'a>(n: Node<'a, 'a>, name: &str) -> Option<&'a str> {
    n.attribute(name)
}

pub(crate) fn string_attr(n: Node, name: &str) -> Option<String> {
    n.attribute(name).map(str::to_string)
}

pub(crate) fn required<'a>(n: Node<'a, 'a>, name: &str) -> Result<&'a str> {
    attr(n, name).ok_or_else(|| {
        Error::Xml(format!("<{}> has no {name} attribute", n.tag_name().name()))
    })
}

/// xs:boolean, which XML spells either way round.
pub(crate) fn bool_attr(n: Node, name: &str, default: bool) -> bool {
    match attr(n, name) {
        Some("true") | Some("1") => true,
        Some("false") | Some("0") => false,
        _ => default,
    }
}

pub(crate) fn f64_attr(n: Node, name: &str) -> Option<f64> {
    attr(n, name)?.trim().parse().ok()
}

pub(crate) fn u32_attr(n: Node, name: &str) -> Option<u32> {
    attr(n, name)?.trim().parse().ok()
}

pub(crate) fn u64_attr(n: Node, name: &str) -> Option<u64> {
    attr(n, name)?.trim().parse().ok()
}

pub(crate) fn i32_attr(n: Node, name: &str) -> Option<i32> {
    attr(n, name)?.trim().parse().ok()
}

/// A whitespace-separated list attribute (`dependencies`, `clocks`, an array
/// variable's `start`).
pub(crate) fn list_attr<T: std::str::FromStr>(n: Node, name: &str) -> Option<Vec<T>> {
    Some(attr(n, name)?.split_whitespace().filter_map(|s| s.parse().ok()).collect())
}

pub(crate) fn child<'a>(n: Node<'a, 'a>, name: &str) -> Option<Node<'a, 'a>> {
    n.children().find(|c| c.is_element() && c.tag_name().name() == name)
}

pub(crate) fn children<'a>(
    n: Node<'a, 'a>,
    name: &'static str,
) -> impl Iterator<Item = Node<'a, 'a>> {
    n.children().filter(move |c| c.is_element() && c.tag_name().name() == name)
}

pub(crate) fn causality(s: Option<&str>, default: Causality) -> Causality {
    match s {
        Some("parameter") => Causality::Parameter,
        Some("calculatedParameter") => Causality::CalculatedParameter,
        Some("input") => Causality::Input,
        Some("output") => Causality::Output,
        Some("local") => Causality::Local,
        Some("independent") => Causality::Independent,
        Some("structuralParameter") => Causality::StructuralParameter,
        _ => default,
    }
}

pub(crate) fn variability(s: Option<&str>, default: Variability) -> Variability {
    match s {
        Some("constant") => Variability::Constant,
        Some("fixed") => Variability::Fixed,
        Some("tunable") => Variability::Tunable,
        Some("discrete") => Variability::Discrete,
        Some("continuous") => Variability::Continuous,
        _ => default,
    }
}

pub(crate) fn initial(s: Option<&str>) -> Option<Initial> {
    match s {
        Some("exact") => Some(Initial::Exact),
        Some("approx") => Some(Initial::Approx),
        Some("calculated") => Some(Initial::Calculated),
        _ => None,
    }
}

pub(crate) fn dependencies_kind(n: Node) -> Vec<DependenciesKind> {
    attr(n, "dependenciesKind")
        .map(|s| {
            s.split_whitespace()
                .map(|k| match k {
                    "constant" => DependenciesKind::Constant,
                    "fixed" => DependenciesKind::Fixed,
                    "tunable" => DependenciesKind::Tunable,
                    "discrete" => DependenciesKind::Discrete,
                    _ => DependenciesKind::Dependent,
                })
                .collect()
        })
        .unwrap_or_default()
}

pub(crate) fn default_experiment(root: Node) -> Option<DefaultExperiment> {
    let n = child(root, "DefaultExperiment")?;
    Some(DefaultExperiment {
        start_time: f64_attr(n, "startTime"),
        stop_time: f64_attr(n, "stopTime"),
        tolerance: f64_attr(n, "tolerance"),
        step_size: f64_attr(n, "stepSize"),
    })
}

pub(crate) fn log_categories(root: Node) -> Vec<LogCategory> {
    let Some(cats) = child(root, "LogCategories") else { return Vec::new() };
    children(cats, "Category")
        .filter_map(|c| {
            Some(LogCategory {
                name: attr(c, "name")?.to_string(),
                description: string_attr(c, "description"),
            })
        })
        .collect()
}

/// The empty variable every parser fills in from there.
pub(crate) fn blank_variable(name: String, vr: u32, index: u32, ty: VarType) -> Variable {
    Variable {
        name,
        value_reference: vr,
        index,
        description: None,
        ty,
        causality: Causality::Local,
        variability: Variability::Continuous,
        initial: None,
        start: None,
        declared_type: None,
        quantity: None,
        unit: None,
        display_unit: None,
        relative_quantity: false,
        unbounded: false,
        min: None,
        max: None,
        nominal: None,
        derivative: None,
        reinit: false,
        previous: None,
        intermediate_update: false,
        clocks: Vec::new(),
        dimensions: Vec::new(),
        clock: None,
        binary: None,
        aliases: Vec::new(),
        alias: Alias::NoAlias,
        can_handle_multiple_set_per_time_instant: false,
    }
}

/// Turn the 1-based variable indices FMI 1.0/2.0 use into value references.
pub(crate) fn index_to_vr(vars: &[Variable], index: u32) -> Option<u32> {
    vars.get(index.checked_sub(1)? as usize).map(|v| v.value_reference)
}
