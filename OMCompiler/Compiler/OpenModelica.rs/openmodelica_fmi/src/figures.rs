//! The OpenModelica `<Figures>` and `<Visualization>` tool annotations.
//!
//! FMI has nowhere for "which plots describe this model", so the export writes
//! them under `<Annotations><Annotation type="org.openmodelica">` and
//! [`crate::ToolAnnotation`] keeps the XML. An unknown `version` yields nothing
//! rather than a guess.

use crate::ToolAnnotation;
use roxmltree::{Document, Node};

/// FMI 3.0's `<Annotation type=…>`, and the `<Tool name=…>` older exports wrote.
const TYPE: &str = "org.openmodelica";
const TOOL: &str = "OpenModelica";
const VERSION: &str = "1";

#[derive(Clone, Debug, Default, PartialEq)]
pub struct Curve {
    /// The x variable; empty means time.
    pub x: String,
    pub y: String,
    pub legend: String,
}

#[derive(Clone, Debug, Default, PartialEq)]
pub struct Axis {
    pub label: String,
    pub unit: String,
    pub min: Option<f64>,
    pub max: Option<f64>,
    /// `scale="Log"`; linear otherwise.
    pub log: bool,
}

#[derive(Clone, Debug, Default, PartialEq)]
pub struct Plot {
    pub title: String,
    pub preferred: bool,
    /// `<TerminalRef terminal=…>`, for a plot named by terminal rather than by
    /// explicit curves.
    pub terminal: Option<String>,
    pub curves: Vec<Curve>,
    pub x: Option<Axis>,
    pub y: Option<Axis>,
    pub y2: Option<Axis>,
}

#[derive(Clone, Debug, Default, PartialEq)]
pub struct Figure {
    pub title: String,
    pub group: String,
    pub preferred: bool,
    pub caption: String,
    pub plots: Vec<Plot>,
}

/// `<Visualization file=…>`: the `_visual.xml` scene in `resources/`.
#[derive(Clone, Debug, Default, PartialEq)]
pub struct Visualization {
    pub file: String,
}

fn openmodelica_xml(annotations: &[ToolAnnotation]) -> Option<&str> {
    annotations.iter().find(|t| t.name == TYPE || t.name == TOOL).map(|t| t.xml.as_str())
}

/// True when the element's `version` is absent or the one we read.
fn known_version(n: Node) -> bool {
    n.attribute("version").is_none_or(|v| v == VERSION)
}

fn text_attr(n: Node, name: &str) -> String {
    n.attribute(name).unwrap_or_default().to_string()
}

fn num_attr(n: Node, name: &str) -> Option<f64> {
    n.attribute(name).and_then(|v| v.trim().parse().ok())
}

fn children<'a>(n: Node<'a, 'a>, tag: &'a str) -> impl Iterator<Item = Node<'a, 'a>> {
    n.children().filter(move |c| c.is_element() && c.tag_name().name() == tag)
}

fn axis(plot: Node, role: &str) -> Option<Axis> {
    let a = children(plot, "Axis").find(|a| a.attribute("role") == Some(role))?;
    Some(Axis {
        label: text_attr(a, "label"),
        unit: text_attr(a, "unit"),
        min: num_attr(a, "min"),
        max: num_attr(a, "max"),
        log: a.attribute("scale") == Some("Log"),
    })
}

fn plot(p: Node) -> Option<Plot> {
    let curves: Vec<Curve> = children(p, "Curve")
        .filter_map(|c| {
            let y = c.attribute("y")?;
            (!y.is_empty()).then(|| Curve {
                x: text_attr(c, "x"),
                y: y.to_string(),
                legend: text_attr(c, "legend"),
            })
        })
        .collect();
    // A plot named only by a terminal has nothing to draw here; a host that
    // resolves terminals can still read the reference off the annotation.
    if curves.is_empty() {
        return None;
    }
    Some(Plot {
        title: text_attr(p, "title"),
        preferred: p.attribute("preferred") == Some("true"),
        terminal: children(p, "TerminalRef").next().and_then(|t| t.attribute("terminal")).map(str::to_string),
        curves,
        x: axis(p, "x"),
        y: axis(p, "y"),
        y2: axis(p, "y2"),
    })
}

/// The figures the OpenModelica annotation declares, in the order it wrote them.
pub fn figures(annotations: &[ToolAnnotation]) -> Vec<Figure> {
    let Some(xml) = openmodelica_xml(annotations) else { return Vec::new() };
    let Ok(doc) = Document::parse(xml) else { return Vec::new() };
    let Some(root) = children(doc.root_element(), "Figures").next() else { return Vec::new() };
    if !known_version(root) {
        return Vec::new();
    }
    children(root, "Figure")
        .filter_map(|f| {
            let plots: Vec<Plot> = children(f, "Plot").filter_map(plot).collect();
            if plots.is_empty() {
                return None;
            }
            Some(Figure {
                title: text_attr(f, "title"),
                group: text_attr(f, "group"),
                preferred: f.attribute("preferred") == Some("true"),
                caption: children(f, "Caption")
                    .next()
                    .and_then(|c| c.text())
                    .unwrap_or_default()
                    .to_string(),
                plots,
            })
        })
        .collect()
}

/// The `_visual.xml` scene the model exported, if it did.
pub fn visualization(annotations: &[ToolAnnotation]) -> Option<Visualization> {
    let xml = openmodelica_xml(annotations)?;
    let doc = Document::parse(xml).ok()?;
    let v = children(doc.root_element(), "Visualization").next()?;
    if !known_version(v) {
        return None;
    }
    let file = v.attribute("file")?;
    (!file.is_empty()).then(|| Visualization { file: file.to_string() })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn annotations(inner: &str) -> Vec<ToolAnnotation> {
        vec![ToolAnnotation {
            name: TYPE.to_string(),
            xml: format!("<Annotation type=\"org.openmodelica\">{inner}</Annotation>"),
        }]
    }

    /// What FMUs exported before FMI 3.0's spelling carry.
    fn tool_annotations(inner: &str) -> Vec<ToolAnnotation> {
        vec![ToolAnnotation { name: TOOL.to_string(), xml: format!("<Tool name=\"OpenModelica\">{inner}</Tool>") }]
    }

    #[test]
    fn reads_a_figure_from_the_old_tool_element() {
        let a = tool_annotations(r#"<Figures version="1"><Figure title="F"><Plot><Curve y="a"/></Plot></Figure></Figures>"#);
        assert_eq!(figures(&a).len(), 1);
    }

    #[test]
    fn reads_a_figure() {
        let a = annotations(
            r#"<Figures version="1"><Figure title="F" preferred="true">
                 <Plot title="P"><Axis role="y" label="angle" unit="rad" scale="Log" min="0"/>
                   <Curve y="a.b.c" legend="one"/><Curve y="d" x="e"/></Plot>
                 <Caption>why</Caption></Figure></Figures>"#,
        );
        let f = figures(&a);
        assert_eq!(f.len(), 1);
        assert!(f[0].preferred);
        assert_eq!(f[0].caption, "why");
        assert_eq!(f[0].plots[0].curves[0], Curve { x: String::new(), y: "a.b.c".into(), legend: "one".into() });
        assert_eq!(f[0].plots[0].curves[1].x, "e");
        let y = f[0].plots[0].y.as_ref().unwrap();
        assert!(y.log && y.min == Some(0.0) && y.unit == "rad");
        assert!(f[0].plots[0].x.is_none());
    }

    #[test]
    fn skips_a_plot_with_no_curves_and_an_unknown_version() {
        assert!(figures(&annotations(r#"<Figures version="1"><Figure><Plot title="P"/></Figure></Figures>"#)).is_empty());
        assert!(figures(&annotations(r#"<Figures version="2"><Figure><Plot><Curve y="a"/></Plot></Figure></Figures>"#)).is_empty());
    }

    #[test]
    fn reads_the_visualization() {
        assert_eq!(
            visualization(&annotations(r#"<Visualization version="1" file="M_visual.xml"/>"#)),
            Some(Visualization { file: "M_visual.xml".into() })
        );
        assert_eq!(visualization(&annotations(r#"<Visualization version="9" file="x.xml"/>"#)), None);
        assert_eq!(visualization(&annotations("")), None);
    }

    #[test]
    fn no_openmodelica_annotation_is_not_an_error() {
        let other = vec![ToolAnnotation { name: "Other".into(), xml: "<Tool name=\"Other\"/>".into() }];
        assert!(figures(&other).is_empty());
        assert!(visualization(&other).is_none());
    }
}
