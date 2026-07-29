//! The visualization scene parsed from a `<model>_visual.xml` (emitted by
//! `-d=visxml`). Each numeric field is either a constant or a result-variable
//! reference resolved per frame against a simulation result.

use roxmltree::{Document, Node};

/// A scalar in the visual XML: a literal, or a cref naming a result variable.
#[derive(Clone, Debug, PartialEq)]
pub enum Attr {
    Const(f64),
    Cref(String),
}

impl Attr {
    pub fn resolve(&self, r: &dyn crate::Resolver, t: f64) -> f64 {
        match self {
            Attr::Const(v) => *v,
            Attr::Cref(name) => r.value(name, t),
        }
    }
    pub fn as_const(&self) -> Option<f64> {
        match self {
            Attr::Const(v) => Some(*v),
            Attr::Cref(_) => None,
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ShapeKind {
    Box,
    Sphere,
    Cylinder,
    Cone,
    PipeCylinder,
    Pipe,
    Beam,
    Gearwheel,
    Spring,
    /// A CAD file reference (dxf/stl/obj/3ds); the string is the raw type text.
    Cad,
}

impl ShapeKind {
    fn parse(s: &str) -> ShapeKind {
        match s {
            "box" => ShapeKind::Box,
            "sphere" => ShapeKind::Sphere,
            "cylinder" => ShapeKind::Cylinder,
            "cone" => ShapeKind::Cone,
            "pipecylinder" => ShapeKind::PipeCylinder,
            "pipe" => ShapeKind::Pipe,
            "beam" => ShapeKind::Beam,
            "gearwheel" => ShapeKind::Gearwheel,
            "spring" => ShapeKind::Spring,
            _ => ShapeKind::Cad,
        }
    }
    /// Stable tag handed to renderers.
    pub fn tag(self) -> u8 {
        self as u8
    }
}

#[derive(Clone, Debug)]
pub struct Shape {
    pub id: String,
    pub kind: ShapeKind,
    pub type_text: String,
    pub t: [Attr; 9],
    pub r: [Attr; 3],
    pub r_shape: [Attr; 3],
    pub length_dir: [Attr; 3],
    pub width_dir: [Attr; 3],
    pub length: Attr,
    pub width: Attr,
    pub height: Attr,
    pub extra: Attr,
    pub color: [Attr; 3],
    pub spec_coeff: Attr,
}

#[derive(Clone, Debug, Default)]
pub struct Scene {
    pub shapes: Vec<Shape>,
}

fn attr_from_node(node: Node) -> Attr {
    let text = node.text().unwrap_or("").trim();
    match node.tag_name().name() {
        "cref" => Attr::Cref(text.to_string()),
        "bconst" => Attr::Const(if text == "true" { 1.0 } else { 0.0 }),
        // enum/exp both parse as a number (enum is an integer literal).
        _ => Attr::Const(text.parse().unwrap_or(0.0)),
    }
}

/// The scalar children of `<name>` under `parent`, in document order.
fn attrs(parent: Node, name: &str) -> Vec<Attr> {
    match parent.children().find(|c| c.has_tag_name(name)) {
        Some(container) => container
            .children()
            .filter(|c| c.is_element())
            .map(attr_from_node)
            .collect(),
        None => Vec::new(),
    }
}

fn arr3(v: &[Attr], fill: f64) -> [Attr; 3] {
    let g = |i: usize| v.get(i).cloned().unwrap_or(Attr::Const(fill));
    [g(0), g(1), g(2)]
}

fn arr9(v: &[Attr]) -> [Attr; 9] {
    std::array::from_fn(|i| v.get(i).cloned().unwrap_or(Attr::Const(0.0)))
}

fn scalar(parent: Node, name: &str) -> Attr {
    attrs(parent, name).into_iter().next().unwrap_or(Attr::Const(0.0))
}

fn text_child(parent: Node, name: &str) -> String {
    parent
        .children()
        .find(|c| c.has_tag_name(name))
        .and_then(|n| n.text())
        .unwrap_or("")
        .trim()
        .to_string()
}

impl Scene {
    /// Parse a `_visual.xml`. Malformed shape nodes are skipped, not fatal.
    pub fn parse(xml: &str) -> Result<Scene, String> {
        let doc = Document::parse(xml).map_err(|e| e.to_string())?;
        let root = doc.root_element();
        let mut shapes = Vec::new();
        for node in root.children().filter(|c| c.has_tag_name("shape")) {
            let type_text = text_child(node, "type");
            if type_text.is_empty() {
                continue;
            }
            shapes.push(Shape {
                id: text_child(node, "ident"),
                kind: ShapeKind::parse(&type_text),
                type_text,
                t: arr9(&attrs(node, "T")),
                r: arr3(&attrs(node, "r"), 0.0),
                r_shape: arr3(&attrs(node, "r_shape"), 0.0),
                length_dir: arr3(&attrs(node, "lengthDir"), 0.0),
                width_dir: arr3(&attrs(node, "widthDir"), 0.0),
                length: scalar(node, "length"),
                width: scalar(node, "width"),
                height: scalar(node, "height"),
                extra: scalar(node, "extra"),
                color: arr3(&attrs(node, "color"), 0.0),
                spec_coeff: scalar(node, "specCoeff"),
            });
        }
        Ok(Scene { shapes })
    }

    /// Every distinct cref the scene references (for the client to pre-map to
    /// result columns). Order is deterministic (first-seen).
    pub fn crefs(&self) -> Vec<String> {
        let mut seen: Vec<String> = Vec::new();
        let mut push = |a: &Attr| {
            if let Attr::Cref(n) = a {
                if !seen.iter().any(|s| s == n) {
                    seen.push(n.clone());
                }
            }
        };
        for s in &self.shapes {
            for a in s
                .t
                .iter()
                .chain(&s.r)
                .chain(&s.r_shape)
                .chain(&s.length_dir)
                .chain(&s.width_dir)
                .chain(&s.color)
                .chain([&s.length, &s.width, &s.height, &s.extra, &s.spec_coeff])
            {
                push(a);
            }
        }
        seen
    }
}
