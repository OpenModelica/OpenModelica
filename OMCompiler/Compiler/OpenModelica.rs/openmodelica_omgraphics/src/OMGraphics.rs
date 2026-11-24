//! Qt-free renderer for Modelica graphical (Icon) annotations: the Rust port of
//! `runtime/OMGraphics.cpp` + `OMGraphics_omc.cpp`, the `external "C"` bodies of
//! `Compiler/Util/OMGraphics.mo`. Modelica has y up, SVG has y down, so the
//! drawing sits in a root group that flips y and text/images undo the flip.

// The entry points keep their MetaModelica names, which mmtorust calls.
#![allow(non_snake_case)]

use std::collections::HashSet;
use std::sync::{Arc, Mutex, OnceLock};

use arcstr::ArcStr;
use base64::Engine;
use openmodelica_util::JSON::JSON;
use openmodelica_util::ModelInstanceReference;
use openmodelica_util::UnorderedMap;
use openmodelica_util::Vector;
use resvg::tiny_skia;
use resvg::usvg::{self, fontdb};
use skrifa::MetadataProvider;

/// `printf("%g")`, matching the C++ renderer's `ostringstream` precision(6).
fn num(v: f64) -> String {
    const P: i32 = 6;
    let v = if !v.is_finite() || v == 0.0 { 0.0 } else { v };
    if v == 0.0 {
        return "0".to_string();
    }
    let sci = format!("{:.*e}", (P - 1) as usize, v);
    let (mantissa, exponent) = sci.split_once('e').unwrap();
    let exp: i32 = exponent.parse().unwrap();
    if exp < -4 || exp >= P {
        format!(
            "{}e{}{:02}",
            strip_trailing_zeros(mantissa),
            if exp < 0 { '-' } else { '+' },
            exp.abs()
        )
    } else {
        strip_trailing_zeros(&format!("{:.*}", (P - 1 - exp).max(0) as usize, v))
    }
}

fn strip_trailing_zeros(s: &str) -> String {
    if s.contains('.') {
        s.trim_end_matches('0').trim_end_matches('.').to_string()
    } else {
        s.to_string()
    }
}

fn escape_xml(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for ch in s.chars() {
        match ch {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '"' => out.push_str("&quot;"),
            '\'' => out.push_str("&apos;"),
            _ => out.push(ch),
        }
    }
    out
}

// Data model, mirroring OMEdit's ModelInstance::* graphic classes
// (OMEditLIB/Modeling/Model.h) with plain Rust types.

/// A negative component marks "no colour set": Modelica's default text colour
/// is {-1,-1,-1}.
#[derive(Clone, Copy)]
struct Color {
    r: i32,
    g: i32,
    b: i32,
}

impl Color {
    const BLACK: Color = Color { r: 0, g: 0, b: 0 };
    const UNSET: Color = Color { r: -1, g: -1, b: -1 };

    fn is_set(&self) -> bool {
        self.r >= 0 && self.g >= 0 && self.b >= 0
    }

    fn to_svg(self) -> String {
        format!("rgb({},{},{})", self.r.max(0), self.g.max(0), self.b.max(0))
    }
}

#[derive(Clone, Copy, Default)]
struct Point {
    x: f64,
    y: f64,
}

/// A Modelica extent {{x1,y1},{x2,y2}}.
#[derive(Clone, Copy, Default)]
struct Extent {
    p1: Point,
    p2: Point,
}

/// Discriminants are the 1-based annotation enumeration index.
#[derive(Clone, Copy, PartialEq)]
enum LinePattern {
    None = 1,
    Solid,
    Dash,
    Dot,
    DashDot,
    DashDotDot,
}

#[derive(Clone, Copy, PartialEq)]
enum FillPattern {
    None = 1,
    Solid,
}

#[derive(Clone, Copy, PartialEq)]
enum EllipseClosure {
    None = 1,
    Chord,
    Radial,
}

#[derive(Clone, Copy, PartialEq)]
enum TextAlignment {
    Left = 1,
    Center,
    Right,
}

#[derive(Clone, Copy, PartialEq)]
enum TextStyle {
    Bold = 1,
    Italic,
    UnderLine,
}

#[derive(Clone, Copy, PartialEq)]
enum ShapeKind {
    Rectangle,
    Line,
    Polygon,
    Ellipse,
    Text,
    Bitmap,
}

impl LinePattern {
    fn from_index(i: i32) -> LinePattern {
        match i {
            1 => LinePattern::None,
            3 => LinePattern::Dash,
            4 => LinePattern::Dot,
            5 => LinePattern::DashDot,
            6 => LinePattern::DashDotDot,
            _ => LinePattern::Solid,
        }
    }
}

impl FillPattern {
    /// Gradients/hatches are approximated as solid, as in the C++ renderer.
    fn from_index(i: i32) -> FillPattern {
        if i == 1 { FillPattern::None } else { FillPattern::Solid }
    }
}

impl EllipseClosure {
    fn from_index(i: i32) -> EllipseClosure {
        match i {
            1 => EllipseClosure::None,
            3 => EllipseClosure::Radial,
            _ => EllipseClosure::Chord,
        }
    }
}

impl TextAlignment {
    fn from_index(i: i32) -> TextAlignment {
        match i {
            1 => TextAlignment::Left,
            3 => TextAlignment::Right,
            _ => TextAlignment::Center,
        }
    }
}

impl TextStyle {
    fn from_index(i: i32) -> TextStyle {
        match i {
            2 => TextStyle::Italic,
            3 => TextStyle::UnderLine,
            _ => TextStyle::Bold,
        }
    }
}

/// One graphic primitive; only the fields relevant to `kind` are meaningful.
#[derive(Clone)]
struct Shape {
    kind: ShapeKind,

    // GraphicItem
    visible: bool,
    origin: Point,
    rotation: f64,

    // FilledShape (Rectangle, Polygon, Ellipse, Text)
    line_color: Color,
    fill_color: Color,
    line_pattern: LinePattern,
    fill_pattern: FillPattern,
    line_thickness: f64,

    // Rectangle / Ellipse / Text / Bitmap
    extent: Extent,
    radius: f64,

    // Line / Polygon
    points: Vec<Point>,
    color: Color,
    thickness: f64,

    // Ellipse
    start_angle: f64,
    end_angle: f64,
    closure: EllipseClosure,

    // Text
    text_string: ArcStr,
    font_size: f64,
    text_color: Color,
    font_name: ArcStr,
    text_styles: Vec<TextStyle>,
    horizontal_alignment: TextAlignment,

    // Bitmap
    file_name: ArcStr,
    image_source: ArcStr,
}

impl Default for Shape {
    fn default() -> Shape {
        Shape {
            kind: ShapeKind::Rectangle,
            visible: true,
            origin: Point::default(),
            rotation: 0.0,
            line_color: Color::BLACK,
            fill_color: Color::BLACK,
            line_pattern: LinePattern::Solid,
            fill_pattern: FillPattern::None,
            line_thickness: 0.25,
            extent: Extent::default(),
            radius: 0.0,
            points: Vec::new(),
            color: Color::BLACK,
            thickness: 0.25,
            start_angle: 0.0,
            end_angle: 360.0,
            closure: EllipseClosure::Chord,
            text_string: ArcStr::new(),
            font_size: 0.0,
            text_color: Color::UNSET,
            font_name: ArcStr::new(),
            text_styles: Vec::new(),
            horizontal_alignment: TextAlignment::Center,
            file_name: ArcStr::new(),
            image_source: ArcStr::new(),
        }
    }
}

struct Icon {
    extent: Extent,
    graphics: Vec<Shape>,
}

impl Default for Icon {
    fn default() -> Icon {
        Icon {
            extent: Extent {
                p1: Point { x: -100.0, y: -100.0 },
                p2: Point { x: 100.0, y: 100.0 },
            },
            graphics: Vec::new(),
        }
    }
}

/// lineThickness is in mm and 0 means "default". Rendered directly in coordinate
/// units, which matches OMEdit closely enough for icon-sized drawings.
fn stroke_width(thickness: f64) -> f64 {
    if thickness > 0.0 { thickness } else { 0.25 }
}

fn dash_array(p: LinePattern, w: f64) -> String {
    let u = stroke_width(w);
    match p {
        LinePattern::Dash => format!("{},{}", num(4.0 * u), num(4.0 * u)),
        LinePattern::Dot => format!("{},{}", num(u), num(2.0 * u)),
        LinePattern::DashDot => format!("{},{},{},{}", num(4.0 * u), num(2.0 * u), num(u), num(2.0 * u)),
        LinePattern::DashDotDot => format!(
            "{},{},{},{},{},{}",
            num(4.0 * u),
            num(2.0 * u),
            num(u),
            num(2.0 * u),
            num(u),
            num(2.0 * u)
        ),
        _ => String::new(),
    }
}

fn stroke_style(line: Color, pattern: LinePattern, thickness: f64) -> String {
    if pattern == LinePattern::None {
        return "stroke:none;".to_string();
    }
    let mut s = format!(
        "stroke:{};stroke-width:{};",
        line.to_svg(),
        num(stroke_width(thickness))
    );
    let da = dash_array(pattern, thickness);
    if !da.is_empty() {
        s.push_str(&format!("stroke-dasharray:{};", da));
    }
    s
}

fn fill_style(fill: Color, pattern: FillPattern) -> String {
    if pattern == FillPattern::None {
        "fill:none;".to_string()
    } else {
        format!("fill:{};", fill.to_svg())
    }
}

fn emit_points(svg: &mut String, pts: &[Point]) {
    for (i, p) in pts.iter().enumerate() {
        if i > 0 {
            svg.push(' ');
        }
        svg.push_str(&format!("{},{}", num(p.x), num(p.y)));
    }
}

fn emit_rectangle(svg: &mut String, s: &Shape) {
    let x = s.extent.p1.x.min(s.extent.p2.x);
    let y = s.extent.p1.y.min(s.extent.p2.y);
    let w = (s.extent.p2.x - s.extent.p1.x).abs();
    let h = (s.extent.p2.y - s.extent.p1.y).abs();
    svg.push_str(&format!(
        "    <rect x=\"{}\" y=\"{}\" width=\"{}\" height=\"{}\"",
        num(x),
        num(y),
        num(w),
        num(h)
    ));
    if s.radius > 0.0 {
        svg.push_str(&format!(" rx=\"{}\" ry=\"{}\"", num(s.radius), num(s.radius)));
    }
    svg.push_str(&format!(
        " style=\"{}{}\"/>\n",
        fill_style(s.fill_color, s.fill_pattern),
        stroke_style(s.line_color, s.line_pattern, s.line_thickness)
    ));
}

fn emit_line(svg: &mut String, s: &Shape) {
    svg.push_str("    <polyline points=\"");
    emit_points(svg, &s.points);
    svg.push_str(&format!(
        "\" style=\"fill:none;{}stroke-linecap:round;stroke-linejoin:round;\"/>\n",
        stroke_style(s.color, s.line_pattern, s.thickness)
    ));
}

fn emit_polygon(svg: &mut String, s: &Shape) {
    svg.push_str("    <polygon points=\"");
    emit_points(svg, &s.points);
    svg.push_str(&format!(
        "\" style=\"{}{}\"/>\n",
        fill_style(s.fill_color, s.fill_pattern),
        stroke_style(s.line_color, s.line_pattern, s.line_thickness)
    ));
}

fn is_full_ellipse(s: &Shape) -> bool {
    (s.end_angle - s.start_angle).abs() >= 359.999 || (s.start_angle == 0.0 && s.end_angle == 0.0)
}

fn emit_ellipse(svg: &mut String, s: &Shape) {
    let cx = (s.extent.p1.x + s.extent.p2.x) / 2.0;
    let cy = (s.extent.p1.y + s.extent.p2.y) / 2.0;
    let rx = (s.extent.p2.x - s.extent.p1.x).abs() / 2.0;
    let ry = (s.extent.p2.y - s.extent.p1.y).abs() / 2.0;
    if is_full_ellipse(s) {
        svg.push_str(&format!(
            "    <ellipse cx=\"{}\" cy=\"{}\" rx=\"{}\" ry=\"{}\" style=\"{}{}\"/>\n",
            num(cx),
            num(cy),
            num(rx),
            num(ry),
            fill_style(s.fill_color, s.fill_pattern),
            stroke_style(s.line_color, s.line_pattern, s.line_thickness)
        ));
        return;
    }
    // closure: None = open arc, Chord = line between the endpoints, Radial = wedge
    let a0 = s.start_angle.to_radians();
    let a1 = s.end_angle.to_radians();
    let (x0, y0) = (cx + rx * a0.cos(), cy + ry * a0.sin());
    let (x1, y1) = (cx + rx * a1.cos(), cy + ry * a1.sin());
    let large = if (s.end_angle - s.start_angle).abs() > 180.0 {
        1
    } else {
        0
    };
    let arc = format!("A {} {} 0 {} 1 {} {}", num(rx), num(ry), large, num(x1), num(y1));
    match s.closure {
        EllipseClosure::None => svg.push_str(&format!(
            "    <path d=\"M {} {} {}\" style=\"fill:none;{}\"/>\n",
            num(x0),
            num(y0),
            arc,
            stroke_style(s.line_color, s.line_pattern, s.line_thickness)
        )),
        EllipseClosure::Chord => svg.push_str(&format!(
            "    <path d=\"M {} {} {} Z\" style=\"{}{}\"/>\n",
            num(x0),
            num(y0),
            arc,
            fill_style(s.fill_color, s.fill_pattern),
            stroke_style(s.line_color, s.line_pattern, s.line_thickness)
        )),
        EllipseClosure::Radial => svg.push_str(&format!(
            "    <path d=\"M {} {} L {} {} {} Z\" style=\"{}{}\"/>\n",
            num(cx),
            num(cy),
            num(x0),
            num(y0),
            arc,
            fill_style(s.fill_color, s.fill_pattern),
            stroke_style(s.line_color, s.line_pattern, s.line_thickness)
        )),
    }
}

fn emit_text(svg: &mut String, s: &Shape, name_text: &str, measure: Measure) {
    let (x0, x1) = (s.extent.p1.x.min(s.extent.p2.x), s.extent.p1.x.max(s.extent.p2.x));
    // The anchor belongs at the edge the text is aligned to, not at the centre
    // of the extent: anchoring "start" in the middle of the box indents the
    // text by half its width.
    let cx = match s.horizontal_alignment {
        TextAlignment::Left => x0,
        TextAlignment::Right => x1,
        TextAlignment::Center => (x0 + x1) / 2.0,
    };
    let cy = (s.extent.p1.y + s.extent.p2.y) / 2.0;
    let h = (s.extent.p2.y - s.extent.p1.y).abs();

    let txt = if name_text.is_empty() {
        s.text_string.to_string()
    } else {
        s.text_string.replace("%name", name_text)
    };

    // "If the fontSize attribute is 0 the text is scaled to fit its extent"
    // (Modelica specification 18.6.5.5), which means both ways: fitting only
    // the height overflows a box narrower than the text is long, and much of
    // OpenIPSL puts a sentence in a 200-unit box.
    let size = if s.font_size > 0.0 {
        s.font_size
    } else {
        let by_height = if h > 0.0 { h * 0.8 } else { 10.0 };
        let width = x1 - x0;
        let advance = measure(s, &txt);
        if width > 0.0 && advance > 0.0 && by_height * advance > width {
            width / advance
        } else {
            by_height
        }
    };

    let col = if s.text_color.is_set() {
        s.text_color
    } else {
        s.line_color
    };
    let anchor = match s.horizontal_alignment {
        TextAlignment::Left => "start",
        TextAlignment::Right => "end",
        TextAlignment::Center => "middle",
    };

    let mut style = String::new();
    if s.text_styles.contains(&TextStyle::Bold) {
        style.push_str("font-weight:bold;");
    }
    if s.text_styles.contains(&TextStyle::Italic) {
        style.push_str("font-style:italic;");
    }
    if s.text_styles.contains(&TextStyle::UnderLine) {
        style.push_str("text-decoration:underline;");
    }

    // undo the root y-flip locally so the text is upright
    svg.push_str(&format!(
        "    <g transform=\"translate({},{}) scale(1,-1)\">\n",
        num(cx),
        num(cy)
    ));
    svg.push_str(&format!(
        "      <text x=\"0\" y=\"0\" text-anchor=\"{}\" dominant-baseline=\"central\" font-size=\"{}\"",
        anchor,
        num(size)
    ));
    svg.push_str(&format!(" font-family=\"{}\"", escape_xml(&font_family(&s.font_name))));
    svg.push_str(&format!(
        " style=\"fill:{};{}\">{}</text>\n    </g>\n",
        col.to_svg(),
        style,
        escape_xml(&txt)
    ));
}

/// The width of `text` at font size 1 in the font of `s`.
type Measure<'a> = &'a dyn Fn(&Shape, &str) -> f64;

/// Width of a string at font size 1, estimated from per-character advances for
/// a Helvetica-like face: the SVG cannot know the font of whoever shows it.
fn text_advance(_: &Shape, text: &str) -> f64 {
    text.chars()
        .map(|c| match c {
            'i' | 'j' | 'l' | '.' | ',' | ':' | ';' | '\'' | '|' | '!' => 0.26,
            ' ' | '(' | ')' | '[' | ']' | '/' | '\\' | '-' | 'f' | 't' | 'r' => 0.33,
            'm' | 'w' => 0.83,
            'M' | 'W' => 0.89,
            'I' | 'J' => 0.33,
            c if c.is_ascii_uppercase() => 0.70,
            c if c.is_ascii_digit() => 0.56,
            c if c.is_ascii_lowercase() => 0.55,
            _ => 0.55,
        })
        .sum()
}

#[derive(Clone, Copy)]
enum Generic {
    SansSerif,
    Serif,
    Monospace,
}

impl Generic {
    /// In order of preference: Liberation, and Arimo, Tinos and Cousine, have
    /// the widths of the first ones.
    fn names(self) -> [&'static str; 4] {
        match self {
            Generic::SansSerif => ["Arial", "Helvetica", "Liberation Sans", "Arimo"],
            Generic::Serif => ["Times New Roman", "Times", "Liberation Serif", "Tinos"],
            Generic::Monospace => ["Courier New", "Courier", "Liberation Mono", "Cousine"],
        }
    }

    /// The font files of web/fonts.
    fn served(self) -> &'static str {
        match self {
            Generic::SansSerif => "LiberationSans",
            Generic::Serif => "LiberationSerif",
            Generic::Monospace => "LiberationMono",
        }
    }

    fn css(self) -> &'static str {
        match self {
            Generic::SansSerif => "sans-serif",
            Generic::Serif => "serif",
            Generic::Monospace => "monospace",
        }
    }

    fn family(self) -> fontdb::Family<'static> {
        match self {
            Generic::SansSerif => fontdb::Family::SansSerif,
            Generic::Serif => fontdb::Family::Serif,
            Generic::Monospace => fontdb::Family::Monospace,
        }
    }
}

/// A Modelica `fontName` as a font of its own, if it names one, and the generic
/// family. The specification requires serif, sans-serif and monospace.
fn font_stack(name: &str) -> (Option<String>, Generic) {
    match name.to_ascii_lowercase().as_str() {
        "" | "sans-serif" | "arial" | "helvetica" => (None, Generic::SansSerif),
        "serif" | "times" | "times new roman" => (None, Generic::Serif),
        "monospace" | "courier" | "courier new" => (None, Generic::Monospace),
        _ => (Some(name.replace(['\'', '"', '\\'], "")), Generic::SansSerif),
    }
}

/// The CSS font list for a Modelica `fontName`, the same fonts the PNG looks for.
fn font_family(name: &str) -> String {
    let (own, generic) = font_stack(name);
    own.iter()
        .map(String::as_str)
        .chain(generic.names())
        .map(|n| {
            if n.contains(' ') {
                format!("'{n}'")
            } else {
                n.to_string()
            }
        })
        .chain([generic.css().to_string()])
        .collect::<Vec<_>>()
        .join(", ")
}

fn image_mime(data: &[u8]) -> &'static str {
    let text = data.strip_prefix(b"\xEF\xBB\xBF").unwrap_or(data).trim_ascii_start();
    match data {
        [0x89, b'P', b'N', b'G', ..] => "image/png",
        [0xFF, 0xD8, 0xFF, ..] => "image/jpeg",
        [b'G', b'I', b'F', b'8', ..] => "image/gif",
        [b'B', b'M', ..] => "image/bmp",
        [b'R', b'I', b'F', b'F', _, _, _, _, b'W', b'E', b'B', b'P', ..] => "image/webp",
        _ if text.starts_with(b"<") => "image/svg+xml",
        _ => "image/png",
    }
}

fn read_uri(uri: &str) -> Option<Vec<u8>> {
    let scheme = uri.split_once(':')?.0.to_ascii_lowercase();
    if scheme != "modelica" && scheme != "file" {
        return None;
    }
    let path = metamodelica::uriToFilename(ArcStr::from(uri)).ok()?;
    openmodelica_wasi::fs::read(&path).ok()
}

/// `imageSource`, or else the file `fileName` names, as a data URI, so that the
/// SVG does not depend on files outside it.
fn bitmap_href(s: &Shape) -> Option<String> {
    let b64 = base64::engine::general_purpose::STANDARD;
    if !s.image_source.is_empty() {
        let data: String = s.image_source.chars().filter(|c| !c.is_ascii_whitespace()).collect();
        let head = b64
            .decode(&data.as_bytes()[..data.len().min(64) / 4 * 4])
            .unwrap_or_default();
        return Some(format!("data:{};base64,{}", image_mime(&head), data));
    }
    if s.file_name.is_empty() {
        return None;
    }
    Some(match read_uri(&s.file_name) {
        Some(data) => format!("data:{};base64,{}", image_mime(&data), b64.encode(&data)),
        None => escape_xml(&s.file_name),
    })
}

fn emit_bitmap(svg: &mut String, s: &Shape) {
    let Some(href) = bitmap_href(s) else {
        return;
    };
    let (p1, p2) = (s.extent.p1, s.extent.p2);
    let w = (p2.x - p1.x).abs();
    let h = (p2.y - p1.y).abs();
    // x2 < x1 and y2 < y1 flip the image (Modelica specification, Bitmap).
    // Otherwise y is flipped back, as the root group flips it.
    let sx = if p2.x < p1.x { -1 } else { 1 };
    let sy = if p2.y < p1.y { 1 } else { -1 };
    svg.push_str(&format!(
        "    <g transform=\"translate({},{}) scale({},{})\">\n",
        num((p1.x + p2.x) / 2.0),
        num((p1.y + p2.y) / 2.0),
        sx,
        sy
    ));
    // The default preserveAspectRatio, xMidYMid meet, scales and centres the
    // image as Modelica asks.
    svg.push_str(&format!(
        "      <image x=\"{}\" y=\"{}\" width=\"{}\" height=\"{}\" xlink:href=\"{}\"/>\n    </g>\n",
        num(-w / 2.0),
        num(-h / 2.0),
        num(w),
        num(h),
        href
    ));
}

fn emit_shape(svg: &mut String, s: &Shape, name_text: &str, measure: Measure) {
    if !s.visible {
        return;
    }
    let transformed = s.origin.x != 0.0 || s.origin.y != 0.0 || s.rotation != 0.0;
    if transformed {
        svg.push_str("  <g transform=\"");
        if s.origin.x != 0.0 || s.origin.y != 0.0 {
            svg.push_str(&format!("translate({},{}) ", num(s.origin.x), num(s.origin.y)));
        }
        if s.rotation != 0.0 {
            svg.push_str(&format!("rotate({})", num(s.rotation)));
        }
        svg.push_str("\">\n");
    }
    match s.kind {
        ShapeKind::Rectangle => emit_rectangle(svg, s),
        ShapeKind::Line => emit_line(svg, s),
        ShapeKind::Polygon => emit_polygon(svg, s),
        ShapeKind::Ellipse => emit_ellipse(svg, s),
        ShapeKind::Text => emit_text(svg, s, name_text, measure),
        ShapeKind::Bitmap => emit_bitmap(svg, s),
    }
    if transformed {
        svg.push_str("  </g>\n");
    }
}

/// The coordinate-system extent padded by the widest stroke: a shape on the
/// boundary centres its stroke on the path, so half of it would be clipped.
struct ViewBox {
    x: f64,
    y: f64,
    w: f64,
    h: f64,
    ymin: f64,
    ymax: f64,
}

fn view_box(icon: &Icon) -> ViewBox {
    let e = &icon.extent;
    let mut xmin = e.p1.x.min(e.p2.x);
    let mut xmax = e.p1.x.max(e.p2.x);
    let mut ymin = e.p1.y.min(e.p2.y);
    let mut ymax = e.p1.y.max(e.p2.y);
    if xmax <= xmin {
        xmin = -100.0;
        xmax = 100.0;
    }
    if ymax <= ymin {
        ymin = -100.0;
        ymax = 100.0;
    }
    // A shape may be drawn outside the coordinate system, and commonly is: the
    // `%name` label sits at {{-100,140},{100,100}} above a {{-100,-100},
    // {100,100}} icon in most of OpenIPSL and much of MSL. Clipping to the
    // coordinate system alone loses it.
    for s in &icon.graphics {
        let Some((x0, y0, x1, y1)) = shape_bounds(s) else {
            continue;
        };
        xmin = xmin.min(x0);
        xmax = xmax.max(x1);
        ymin = ymin.min(y0);
        ymax = ymax.max(y1);
    }
    let w = xmax - xmin;
    let h = ymax - ymin;
    let mut max_stroke: f64 = 0.0;
    for s in &icon.graphics {
        let tw = if s.kind == ShapeKind::Line {
            s.thickness
        } else {
            s.line_thickness
        };
        max_stroke = max_stroke.max(stroke_width(tw));
    }
    let margin = max_stroke.max(0.005 * w.max(h));
    ViewBox {
        x: xmin - margin,
        y: ymin - margin,
        w: w + 2.0 * margin,
        h: h + 2.0 * margin,
        ymin: ymin - margin,
        ymax: ymax + margin,
    }
}

/// A visible shape's axis-aligned bounds in the icon's coordinates, its own
/// origin and rotation applied. `None` for a shape that draws nothing.
fn shape_bounds(s: &Shape) -> Option<(f64, f64, f64, f64)> {
    if !s.visible {
        return None;
    }
    let corners: Vec<Point> = match s.kind {
        ShapeKind::Line | ShapeKind::Polygon => s.points.clone(),
        _ => {
            let (x0, x1) = (s.extent.p1.x.min(s.extent.p2.x), s.extent.p1.x.max(s.extent.p2.x));
            let (y0, y1) = (s.extent.p1.y.min(s.extent.p2.y), s.extent.p1.y.max(s.extent.p2.y));
            vec![
                Point { x: x0, y: y0 },
                Point { x: x1, y: y0 },
                Point { x: x1, y: y1 },
                Point { x: x0, y: y1 },
            ]
        }
    };
    let mut bounds: Option<(f64, f64, f64, f64)> = None;
    for p in corners {
        let p = apply_shape_transform(s, p);
        bounds = Some(match bounds {
            None => (p.x, p.y, p.x, p.y),
            Some((x0, y0, x1, y1)) => (x0.min(p.x), y0.min(p.y), x1.max(p.x), y1.max(p.y)),
        });
    }
    bounds
}

/// Stroke widths as OMEdit draws them into a library pixmap: `lineThickness +
/// 3.0` (ShapeAnnotation.cpp). An icon is shown a couple of centimetres wide,
/// where the default 0.25 in a 200-unit coordinate system is a line too faint
/// to see — several OpenIPSL icons are all but blank without this. A diagram is
/// viewed at its own scale and keeps the widths it asks for.
fn thumbnail_strokes(icon: &Icon) -> Icon {
    const BIAS: f64 = 3.0;
    Icon {
        extent: icon.extent,
        graphics: icon
            .graphics
            .iter()
            .map(|s| {
                let mut s = s.clone();
                s.line_thickness = stroke_width(s.line_thickness) + BIAS;
                s.thickness = stroke_width(s.thickness) + BIAS;
                s
            })
            .collect(),
    }
}

/// `None` when nothing is drawn. An icon layer can hold shapes that all draw
/// nothing — every one invisible, or of a kind this renderer has no output for
/// — and an empty frame on the page is worse than no icon at all.
fn render_icon_svg(icon: &Icon, name_text: &str, measure: Measure) -> Option<String> {
    let icon = &thumbnail_strokes(icon);
    let mut body = String::new();
    for s in &icon.graphics {
        emit_shape(&mut body, s, name_text, measure);
    }
    if body.trim().is_empty() {
        return None;
    }
    let vb = view_box(icon);
    let mut svg = String::new();
    svg.push_str("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n");
    svg.push_str(&format!(
        "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" version=\"1.1\" width=\"{}\" height=\"{}\" viewBox=\"{} {} {} {}\">\n",
        num(vb.w),
        num(vb.h),
        num(vb.x),
        num(vb.y),
        num(vb.w),
        num(vb.h)
    ));
    // map Modelica (y up) to SVG (y down): y' = (ymin+ymax) - y
    svg.push_str(&format!(
        "  <g transform=\"matrix(1 0 0 -1 0 {})\">\n",
        num(vb.ymin + vb.ymax)
    ));
    svg.push_str(&body);
    svg.push_str("  </g>\n</svg>\n");
    Some(svg)
}

// PNG renderer. FMI 3.0 requires the icons referenced from
// terminalsAndIcons.xml to be PNG; the SVG is an optional companion. The PNG is
// rendered from the SVG, so the two show the same.

const MAX_DIM: f32 = 512.0; // clamp for the image size (px)

/// The shape's local transform, mirroring the SVG `translate() rotate()` group.
fn apply_shape_transform(s: &Shape, p: Point) -> Point {
    let a = s.rotation.to_radians();
    let (sa, ca) = a.sin_cos();
    Point {
        x: s.origin.x + (ca * p.x - sa * p.y),
        y: s.origin.y + (sa * p.x + ca * p.y),
    }
}

/// Reads a font file of web/fonts on the web, where omc has no system fonts.
pub type FontSource = fn(&str) -> Option<Vec<u8>>;

static FONT_SOURCE: OnceLock<FontSource> = OnceLock::new();

pub fn set_font_source(source: FontSource) {
    let _ = FONT_SOURCE.set(source);
}

/// The fonts of the PNG: the system's, read once per process, or on the web
/// the served files a text has needed so far.
struct Fonts {
    db: Arc<fontdb::Database>,
    served: HashSet<String>,
}

fn fonts() -> &'static Mutex<Fonts> {
    static FONTS: OnceLock<Mutex<Fonts>> = OnceLock::new();
    FONTS.get_or_init(|| {
        #[allow(unused_mut)]
        let mut db = fontdb::Database::new();
        #[cfg(not(target_arch = "wasm32"))]
        db.load_system_fonts();
        Mutex::new(Fonts {
            db: Arc::new(db),
            served: HashSet::new(),
        })
    })
}

impl Fonts {
    fn serve(&mut self, file: &str) {
        let Some(source) = FONT_SOURCE.get() else {
            return;
        };
        if self.served.insert(file.to_string())
            && let Some(data) = source(file)
        {
            Arc::make_mut(&mut self.db).load_font_data(data);
        }
    }

    /// Before the PNG is drawn, on the web: the served file for the text of `s`,
    /// and DejaVu Sans if that lacks one of its characters, as for ∠ and ∨ in
    /// MSL icons.
    fn prepare(&mut self, s: &Shape, text: &str) {
        let (_, generic) = font_stack(&s.font_name);
        let style = match (
            s.text_styles.contains(&TextStyle::Bold),
            s.text_styles.contains(&TextStyle::Italic),
        ) {
            (false, false) => "Regular",
            (true, false) => "Bold",
            (false, true) => "Italic",
            (true, true) => "BoldItalic",
        };
        self.serve(&format!("{}-{style}.ttf", generic.served()));
        if self
            .face(s)
            .is_some_and(|id| advances(&self.db, id, text).contains(&None))
        {
            self.serve("DejaVuSans.ttf");
        }
    }

    /// The face resvg draws the text of `s` with: the same query its font
    /// resolver makes for the families `font_family` lists.
    fn face(&self, s: &Shape) -> Option<fontdb::ID> {
        let (own, generic) = font_stack(&s.font_name);
        let mut families: Vec<fontdb::Family> = own.iter().map(|n| fontdb::Family::Name(n)).collect();
        families.extend(generic.names().map(fontdb::Family::Name));
        families.push(generic.family());
        self.db.query(&fontdb::Query {
            families: &families,
            weight: if s.text_styles.contains(&TextStyle::Bold) {
                fontdb::Weight::BOLD
            } else {
                fontdb::Weight::NORMAL
            },
            stretch: fontdb::Stretch::Normal,
            style: if s.text_styles.contains(&TextStyle::Italic) {
                fontdb::Style::Italic
            } else {
                fontdb::Style::Normal
            },
        })
    }
}

/// The advance of each character of `text` at size 1 in face `id`; `None`
/// where the face lacks the character.
fn advances(db: &fontdb::Database, id: fontdb::ID, text: &str) -> Vec<Option<f64>> {
    db.with_face_data(id, |data, index| {
        let Ok(font) = skrifa::FontRef::from_index(data, index) else {
            return vec![None; text.chars().count()];
        };
        let charmap = font.charmap();
        let size = skrifa::instance::Size::unscaled();
        let glyphs = font.glyph_metrics(size, skrifa::instance::LocationRef::default());
        let upem = f64::from(
            font.metrics(size, skrifa::instance::LocationRef::default())
                .units_per_em
                .max(1),
        );
        text.chars()
            .map(|c| {
                charmap
                    .map(c)
                    .and_then(|g| glyphs.advance_width(g))
                    .map(|w| f64::from(w) / upem)
            })
            .collect()
    })
    .unwrap_or_default()
}

/// A face for a character the faces in `used` lack: one of `used[0]`'s style,
/// weight and spacing if there is one, and DejaVu Sans, which the web build
/// has, before others. usvg's own choice accepts an oblique face for upright
/// text, and draws all of the text with it when it has every character.
fn fallback_face(db: &fontdb::Database, c: char, used: &[fontdb::ID]) -> Option<fontdb::ID> {
    type Key = (Vec<fontdb::ID>, char);
    static CHOSEN: OnceLock<Mutex<std::collections::HashMap<Key, Option<fontdb::ID>>>> = OnceLock::new();
    let key = (used.to_vec(), c);
    if let Some(id) = CHOSEN.get_or_init(Default::default).lock().ok()?.get(&key) {
        return *id;
    }
    let base = db.face(*used.first()?)?;
    let id = db
        .faces()
        .filter(|f| !used.contains(&f.id))
        .filter(|f| {
            advances(db, f.id, c.encode_utf8(&mut [0; 4]))
                .first()
                .is_some_and(Option::is_some)
        })
        .min_by_key(|f| {
            (
                f.style != base.style,
                f.weight != base.weight,
                f.monospaced != base.monospaced,
                !f.families.iter().any(|(n, _)| n == "DejaVu Sans"),
            )
        })
        .map(|f| f.id);
    CHOSEN.get_or_init(Default::default).lock().ok()?.insert(key, id);
    id
}

/// The width of `text` at size 1 as usvg lays it out: in face `id`, and in
/// fallback faces for the characters it lacks.
fn text_width(db: &fontdb::Database, id: fontdb::ID, text: &str) -> f64 {
    let chars: Vec<char> = text.chars().collect();
    let mut used = vec![id];
    let mut widths = advances(db, id, text);
    while let Some(i) = widths.iter().position(Option::is_none) {
        let Some(fallback) = fallback_face(db, chars[i], &used) else {
            break;
        };
        used.push(fallback);
        let other = advances(db, fallback, text);
        if other.iter().all(Option::is_some) {
            widths = other;
            break;
        }
        for (w, o) in widths.iter_mut().zip(other) {
            if w.is_none() {
                *w = o;
            }
        }
    }
    widths.into_iter().map(|w| w.unwrap_or(0.55)).sum()
}

fn svg_to_png(svg: &str, db: Arc<fontdb::Database>) -> Option<Vec<u8>> {
    let opt = usvg::Options {
        fontdb: db,
        font_resolver: usvg::FontResolver {
            select_font: usvg::FontResolver::default_font_selector(),
            select_fallback: Box::new(|c, used, db| fallback_face(db, c, used)),
        },
        // emit_bitmap inlines every file it can read
        image_href_resolver: usvg::ImageHrefResolver {
            resolve_data: usvg::ImageHrefResolver::default_data_resolver(),
            resolve_string: Box::new(|_, _| None),
        },
        ..usvg::Options::default()
    };
    let tree = usvg::Tree::from_str(svg, &opt).ok()?;
    let size = tree.size();
    // ~1 px per coordinate unit, clamped, aspect preserved
    let scale = (MAX_DIM / size.width().max(size.height())).min(1.0);
    let mut pixmap = tiny_skia::Pixmap::new(
        ((size.width() * scale).round() as u32).max(1),
        ((size.height() * scale).round() as u32).max(1),
    )?;
    resvg::render(
        &tree,
        tiny_skia::Transform::from_scale(scale, scale),
        &mut pixmap.as_mut(),
    );
    pixmap.encode_png().ok()
}

/// Empty when nothing is drawn. Text that fits its extent is sized with the
/// font it is drawn with, not with the estimate of the SVG.
fn render_icon_png(icon: &Icon, name_text: &str) -> Vec<u8> {
    let substitute = |s: &Shape| {
        if name_text.is_empty() {
            s.text_string.to_string()
        } else {
            s.text_string.replace("%name", name_text)
        }
    };
    let Ok(mut fonts) = fonts().lock() else {
        return Vec::new();
    };
    for s in icon.graphics.iter().filter(|s| s.kind == ShapeKind::Text) {
        fonts.prepare(s, &substitute(s));
    }
    let measure = |s: &Shape, text: &str| match fonts.face(s) {
        Some(id) => text_width(&fonts.db, id, text),
        None => text_advance(s, text),
    };
    render_icon_svg(icon, name_text, &measure)
        .and_then(|svg| svg_to_png(&svg, fonts.db.clone()))
        .unwrap_or_default()
}

// JSON accessors. `None` plays the role of the C++ renderer's null Json
// sentinel, so lookups chain without intermediate checks.

type J = Option<metamodelica::Ref<JSON>>;

trait JsonExt {
    fn get(&self, key: &str) -> J;
    fn at(&self, index: usize) -> J;
    fn items(&self) -> Vec<metamodelica::Ref<JSON>>;
    fn len(&self) -> usize;
    fn is_object(&self) -> bool;
    fn is_array(&self) -> bool;
    fn as_num(&self) -> f64;
    fn as_int(&self) -> i32;
    fn as_bool(&self) -> bool;
    fn as_str(&self) -> ArcStr;
}

impl JsonExt for J {
    fn get(&self, key: &str) -> J {
        match self.as_deref()? {
            JSON::LIST_OBJECT { values } => (&**values)
                .into_iter()
                .find(|(k, _)| k.as_str() == key)
                .map(|(_, v)| v.clone()),
            JSON::OBJECT { values } => UnorderedMap::get(ArcStr::from(key), values.clone()).ok().flatten(),
            _ => None,
        }
    }

    fn at(&self, index: usize) -> J {
        match self.as_deref()? {
            JSON::LIST { values } => (&**values).into_iter().nth(index).cloned(),
            JSON::ARRAY { values } => Vector::get(values.clone(), index as i32 + 1).ok(),
            _ => None,
        }
    }

    fn items(&self) -> Vec<metamodelica::Ref<JSON>> {
        match self.as_deref() {
            Some(JSON::LIST { values }) => (&**values).into_iter().cloned().collect(),
            Some(JSON::ARRAY { values }) => (1..=Vector::size(values.clone()))
                .map(|i| Vector::getNoBounds(values.clone(), i))
                .collect(),
            _ => Vec::new(),
        }
    }

    fn len(&self) -> usize {
        match self.as_deref() {
            Some(JSON::LIST { values }) => values.len() as usize,
            Some(JSON::ARRAY { values }) => Vector::size(values.clone()) as usize,
            _ => 0,
        }
    }

    fn is_object(&self) -> bool {
        matches!(self.as_deref(), Some(JSON::OBJECT { .. } | JSON::LIST_OBJECT { .. }))
    }

    fn is_array(&self) -> bool {
        matches!(self.as_deref(), Some(JSON::LIST { .. } | JSON::ARRAY { .. }))
    }

    fn as_num(&self) -> f64 {
        match self.as_deref() {
            Some(JSON::NUMBER { r }) => r.into_inner(),
            Some(JSON::INTEGER { i }) => f64::from(*i),
            _ => 0.0,
        }
    }

    fn as_int(&self) -> i32 {
        match self.as_deref() {
            Some(JSON::INTEGER { i }) => *i,
            Some(JSON::NUMBER { r }) => r.into_inner() as i32,
            _ => 0,
        }
    }

    fn as_bool(&self) -> bool {
        matches!(self.as_deref(), Some(JSON::TRUE))
    }

    fn as_str(&self) -> ArcStr {
        match self.as_deref() {
            Some(JSON::STRING { str: s }) => s.clone(),
            _ => ArcStr::new(),
        }
    }
}

fn parse_point(j: &J) -> Point {
    if j.len() >= 2 {
        Point {
            x: j.at(0).as_num(),
            y: j.at(1).as_num(),
        }
    } else {
        Point::default()
    }
}

fn parse_extent(j: &J) -> Extent {
    if j.len() >= 2 {
        Extent {
            p1: parse_point(&j.at(0)),
            p2: parse_point(&j.at(1)),
        }
    } else {
        Extent::default()
    }
}

fn parse_points(j: &J) -> Vec<Point> {
    j.items().into_iter().map(|p| parse_point(&Some(p))).collect()
}

fn parse_color(j: &J) -> Color {
    if j.len() >= 3 {
        Color {
            r: j.at(0).as_int(),
            g: j.at(1).as_int(),
            b: j.at(2).as_int(),
        }
    } else {
        Color::BLACK
    }
}

/// An annotation enum is `{"$kind":"enum","name":...,"index":N}`.
fn enum_index(j: &J, dflt: i32) -> i32 {
    if j.is_object() {
        let idx = j.get("index");
        if idx.is_some() {
            return idx.as_int();
        }
    } else if matches!(j.as_deref(), Some(JSON::INTEGER { .. } | JSON::NUMBER { .. })) {
        return j.as_int();
    }
    dflt
}

fn parse_graphic_item(el: &[J], s: &mut Shape) {
    s.visible = el[0].as_bool();
    s.origin = parse_point(&el[1]);
    s.rotation = el[2].as_num();
}

/// FilledShape occupies elements 3..7.
fn parse_filled_shape(el: &[J], s: &mut Shape) {
    s.line_color = parse_color(&el[3]);
    s.fill_color = parse_color(&el[4]);
    s.line_pattern = LinePattern::from_index(enum_index(&el[5], LinePattern::Solid as i32));
    s.fill_pattern = FillPattern::from_index(enum_index(&el[6], FillPattern::None as i32));
    s.line_thickness = el[7].as_num();
}

fn parse_shape(name: &str, elements: &J) -> Option<Shape> {
    // reads past the end must yield null, not panic
    let mut el: Vec<J> = elements.items().into_iter().map(Some).collect();
    if el.len() < 16 {
        el.resize(16, None);
    }

    let mut s = Shape::default();
    match name {
        "Rectangle" => {
            s.kind = ShapeKind::Rectangle;
            parse_graphic_item(&el, &mut s);
            parse_filled_shape(&el, &mut s);
            // el[8] borderPattern: not drawn
            s.extent = parse_extent(&el[9]);
            s.radius = el[10].as_num();
        }
        "Line" => {
            s.kind = ShapeKind::Line;
            parse_graphic_item(&el, &mut s);
            s.points = parse_points(&el[3]);
            s.color = parse_color(&el[4]);
            s.line_pattern = LinePattern::from_index(enum_index(&el[5], LinePattern::Solid as i32));
            s.thickness = el[6].as_num();
            // el[7..9] arrows, arrow size, smoothing: not drawn
        }
        "Polygon" => {
            s.kind = ShapeKind::Polygon;
            parse_graphic_item(&el, &mut s);
            parse_filled_shape(&el, &mut s);
            s.points = parse_points(&el[8]);
            // el[9] smoothing: not drawn
        }
        "Ellipse" => {
            s.kind = ShapeKind::Ellipse;
            parse_graphic_item(&el, &mut s);
            parse_filled_shape(&el, &mut s);
            s.extent = parse_extent(&el[8]);
            s.start_angle = el[9].as_num();
            s.end_angle = el[10].as_num();
            s.closure = EllipseClosure::from_index(enum_index(&el[11], EllipseClosure::Chord as i32));
        }
        "Text" => {
            s.kind = ShapeKind::Text;
            parse_graphic_item(&el, &mut s);
            parse_filled_shape(&el, &mut s);
            s.extent = parse_extent(&el[8]);
            s.text_string = el[9].as_str();
            s.font_size = el[10].as_num();
            s.text_color = parse_color(&el[11]); // {-1,-1,-1} stays "not set"
            s.font_name = el[12].as_str();
            s.text_styles = el[13]
                .items()
                .into_iter()
                .map(|st| TextStyle::from_index(enum_index(&Some(st), TextStyle::Bold as i32)))
                .collect();
            s.horizontal_alignment = TextAlignment::from_index(enum_index(&el[14], TextAlignment::Center as i32));
        }
        "Bitmap" => {
            s.kind = ShapeKind::Bitmap;
            parse_graphic_item(&el, &mut s);
            s.extent = parse_extent(&el[3]);
            s.file_name = el[4].as_str();
            s.image_source = el[5].as_str();
        }
        _ => return None,
    }
    Some(s)
}

/// Accepts the model-instance/annotation root, a bare `{Icon:{...}}`, or the
/// Icon object itself.
fn find_layer_object(root: &J, layer: &str) -> J {
    let found = root.get("annotation").get(layer);
    if found.is_object() {
        return found;
    }
    let found = root.get(layer);
    if found.is_object() {
        return found;
    }
    if root.get("graphics").is_array() || root.get("coordinateSystem").is_object() {
        return root.clone();
    }
    None
}

/// A class's Icon layer is its base classes' unioned with its own, the base
/// classes' drawn first (behind); most of MSL draws its icon that way.
fn collect_icon(root: &J, icon: &mut Icon, depth: u32) {
    collect_layer(root, "Icon", icon, depth);
}

fn collect_layer(root: &J, layer: &str, icon: &mut Icon, depth: u32) {
    if depth > 32 {
        return; // a malformed instance must not recurse forever
    }
    for e in root.get("elements").items() {
        let e = Some(e);
        if e.get("$kind").as_str() == "extends" {
            collect_layer(&e.get("baseClass"), layer, icon, depth + 1);
        }
    }
    let Some(icon_obj) = find_layer_object(root, layer) else {
        return;
    };
    let icon_obj = Some(icon_obj);

    let ext = icon_obj.get("coordinateSystem").get("extent");
    if ext.len() >= 2 {
        icon.extent = parse_extent(&ext); // the most derived declaration wins
    }

    for g in icon_obj.get("graphics").items() {
        let g = Some(g);
        let name = g.get("name").as_str();
        let elements = g.get("elements");
        if name.is_empty() || !elements.is_array() {
            continue;
        }
        if let Some(s) = parse_shape(&name, &elements) {
            icon.graphics.push(s);
        }
    }
}

fn icon_from_json(root: &J) -> Icon {
    let mut icon = Icon::default();
    collect_icon(root, &mut icon, 0);
    icon
}

/// The bare <GraphicalRepresentation> element, for splicing into
/// terminalsAndIcons.xml.
fn render_graphical_representation_xml(icon: &Icon, scale_to_mm: f64) -> String {
    let e = &icon.extent;
    let x1 = e.p1.x.min(e.p2.x);
    let y1 = e.p1.y.min(e.p2.y);
    let x2 = e.p1.x.max(e.p2.x);
    let y2 = e.p1.y.max(e.p2.y);
    let scale = if scale_to_mm > 0.0 { scale_to_mm } else { 0.5 };
    format!(
        "  <GraphicalRepresentation>\n    \
         <CoordinateSystem x1=\"{x1}\" y1=\"{y1}\" x2=\"{x2}\" y2=\"{y2}\" suggestedScalingFactorTo_mm=\"{scale}\"/>\n    \
         <Icon x1=\"{x1}\" y1=\"{y1}\" x2=\"{x2}\" y2=\"{y2}\"/>\n  \
         </GraphicalRepresentation>\n",
        x1 = num(x1),
        y1 = num(y1),
        x2 = num(x2),
        y2 = num(y2),
        scale = num(scale)
    )
}

// Placed-connector graphics, for FMI 3.0 TerminalGraphicalRepresentation. Only
// where a port sits on the icon and what to draw for it; which ports exist and
// their direction come from the flat model, not from here.

struct PlacedConnector {
    name: ArcStr,
    icon_base_name: String,
    x1: f64,
    y1: f64,
    x2: f64,
    y2: f64,
    ty: J,
}

/// The type path with non-alphanumerics turned into underscores.
fn icon_base_name_of(type_name: &str) -> String {
    type_name
        .chars()
        .map(|c| if c.is_ascii_alphanumeric() { c } else { '_' })
        .collect()
}

/// placement extent [[x,y],[x,y]] -> min/max bounding box.
fn placement_box(ext: &J) -> Option<[f64; 4]> {
    if ext.len() < 2 {
        return None;
    }
    let (p1, p2) = (ext.at(0), ext.at(1));
    if p1.len() < 2 || p2.len() < 2 {
        return None;
    }
    let (ax, ay) = (p1.at(0).as_num(), p1.at(1).as_num());
    let (bx, by) = (p2.at(0).as_num(), p2.at(1).as_num());
    Some([ax.min(bx), ay.min(by), ax.max(bx), ay.max(by)])
}

/// Top-level connector components carrying a graphical Placement.
fn collect_placed_connectors(root: &J) -> Vec<PlacedConnector> {
    let mut out = Vec::new();
    for e in root.get("elements").items() {
        let e = Some(e);
        if e.get("$kind").as_str() != "component" {
            continue;
        }
        let t = e.get("type");
        if !t.is_object() || t.get("restriction").as_str() != "connector" {
            continue;
        }
        let ext = e.get("annotation").get("Placement").get("transformation").get("extent");
        let Some(b) = placement_box(&ext) else {
            continue; // no placement -> not drawn
        };
        out.push(PlacedConnector {
            name: e.get("name").as_str(),
            icon_base_name: icon_base_name_of(&t.get("name").as_str()),
            x1: b[0],
            y1: b[1],
            x2: b[2],
            y2: b[3],
            ty: t,
        });
    }
    out
}

fn connector_icon(handle: i32, index: i32) -> Option<Icon> {
    let cs = collect_placed_connectors(&ModelInstanceReference::get(handle));
    let c = cs.get(usize::try_from(index).ok()?)?;
    let icon = icon_from_json(&c.ty);
    if icon.graphics.is_empty() { None } else { Some(icon) }
}

fn write_binary_file(path: &str, data: &[u8]) -> bool {
    !data.is_empty() && openmodelica_wasi::fs::write(path, data).is_ok()
}

/// A `Line` annotation as the diagram dump writes it: named fields, not the
/// positional record form the `graphics` list uses.
fn parse_line_annotation(line: &J) -> Option<Shape> {
    let points = parse_points(&line.get("points"));
    if points.len() < 2 {
        return None;
    }
    let mut shape = Shape {
        kind: ShapeKind::Line,
        points,
        ..Shape::default()
    };
    let color = line.get("color");
    if color.len() >= 3 {
        shape.color = parse_color(&color);
    }
    let thickness = line.get("thickness");
    if thickness.is_some() {
        shape.thickness = thickness.as_num();
    }
    shape.line_pattern = LinePattern::from_index(enum_index(&line.get("pattern"), 2));
    Some(shape)
}

/// Where a component sits on the diagram: `Placement.transformation`, whose
/// extent is relative to `origin` and whose rotation turns about it.
struct Placement {
    x1: f64,
    y1: f64,
    x2: f64,
    y2: f64,
    origin: Point,
    rotation: f64,
}

fn parse_placement(component: &J) -> Option<Placement> {
    let t = component.get("annotation").get("Placement").get("transformation");
    let b = placement_box(&t.get("extent"))?;
    let origin_json = t.get("origin");
    let origin = if origin_json.len() >= 2 {
        parse_point(&origin_json)
    } else {
        Point { x: 0.0, y: 0.0 }
    };
    // The extent is given relative to `origin`, and the rotation turns about
    // it. With the default origin of {0,0} the two are the same thing, which is
    // why only the rotated components looked misplaced.
    Some(Placement {
        x1: b[0] + origin.x,
        y1: b[1] + origin.y,
        x2: b[2] + origin.x,
        y2: b[3] + origin.y,
        origin,
        rotation: t.get("rotation").as_num(),
    })
}

/// The class' Diagram layer, its components drawn at their placements, and its
/// connection lines. A component is emitted as its own icon inside a transform
/// that maps the icon's coordinate system onto the placement box, which is what
/// makes an icon drawn for a 200x200 grid land correctly in a 20x20 slot.
pub fn diagram_svg_from_json(json: &metamodelica::Ref<JSON>, model_name: &str) -> Option<String> {
    let root = Some(json.clone());
    let mut diagram = Icon::default();
    collect_layer(&root, "Diagram", &mut diagram, 0);

    let components: Vec<metamodelica::Ref<JSON>> = root.get("components").items();
    let connections: Vec<metamodelica::Ref<JSON>> = root.get("connections").items();

    // The shapes go into `body` first. A diagram can have components and still
    // draw nothing — a record whose components carry no placement or no icon of
    // their own — and an empty frame on the page is worse than no diagram.
    let mut body = String::new();
    let mut svg = &mut body;

    for s in &diagram.graphics {
        emit_shape(&mut svg, s, model_name, &text_advance);
    }

    for component in &components {
        let component = Some(component.clone());
        let Some(placement) = parse_placement(&component) else {
            continue; // no placement: the component is not shown
        };
        let icon = icon_from_json(&component.get("type"));
        if icon.graphics.is_empty() {
            continue;
        }
        let e = &icon.extent;
        let (ex1, ex2) = (e.p1.x.min(e.p2.x), e.p1.x.max(e.p2.x));
        let (ey1, ey2) = (e.p1.y.min(e.p2.y), e.p1.y.max(e.p2.y));
        if ex2 - ex1 == 0.0 || ey2 - ey1 == 0.0 {
            continue;
        }
        let sx = (placement.x2 - placement.x1) / (ex2 - ex1);
        let sy = (placement.y2 - placement.y1) / (ey2 - ey1);
        svg.push_str("    <g");
        svg.push_str(&format!(
            " data-component=\"{}\"",
            escape_xml(&component.get("name").as_str())
        ));
        if placement.rotation != 0.0 {
            svg.push_str(&format!(
                " transform=\"rotate({} {} {})\"",
                num(placement.rotation),
                num(placement.origin.x),
                num(placement.origin.y)
            ));
        }
        svg.push_str(">\n");
        svg.push_str(&format!(
            "    <g transform=\"translate({} {}) scale({} {})\">\n",
            num(placement.x1 - ex1 * sx),
            num(placement.y1 - ey1 * sy),
            num(sx),
            num(sy)
        ));
        for s in &icon.graphics {
            emit_shape(&mut svg, s, &component.get("name").as_str(), &text_advance);
        }
        svg.push_str("    </g>\n    </g>\n");
    }

    for connection in &connections {
        let connection = Some(connection.clone());
        if let Some(shape) = parse_line_annotation(&connection.get("annotation").get("Line")) {
            emit_shape(&mut svg, &shape, "", &text_advance);
        }
    }

    if body.trim().is_empty() {
        return None;
    }

    let vb = view_box(&diagram);
    let mut svg = String::new();
    svg.push_str("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n");
    svg.push_str(&format!(
        "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" version=\"1.1\" width=\"{}\" height=\"{}\" viewBox=\"{} {} {} {}\">\n",
        num(vb.w), num(vb.h), num(vb.x), num(vb.y), num(vb.w), num(vb.h)
    ));
    svg.push_str(&format!(
        "  <g transform=\"matrix(1 0 0 -1 0 {})\">\n",
        num(vb.ymin + vb.ymax)
    ));
    svg.push_str(&body);
    svg.push_str("  </g>\n</svg>\n");
    Some(svg)
}

/// Render a class' icon straight from its instance JSON, for a caller that
/// already holds it. The handle entry points below exist because MetaModelica
/// cannot pass a JSON value across the `external "C"` boundary; Rust callers
/// need neither the reference table nor its 256 slots.
pub fn icon_svg_from_json(json: &metamodelica::Ref<JSON>, model_name: &str) -> Option<String> {
    render_icon_svg(&icon_from_json(&Some(json.clone())), model_name, &text_advance)
}

/// The same icon as a PNG, for hosts that cannot render SVG.
pub fn icon_png_from_json(json: &metamodelica::Ref<JSON>, model_name: &str) -> Option<Vec<u8>> {
    let png = render_icon_png(&icon_from_json(&Some(json.clone())), model_name);
    if png.is_empty() { None } else { Some(png) }
}

// The bodies of Compiler/Util/OMGraphics.mo. `handle` is an in-memory
// model-instance reference (issue #15219) holding list-form JSON.

fn model_icon(handle: i32) -> Option<Icon> {
    let icon = icon_from_json(&ModelInstanceReference::get(handle));
    if icon.graphics.is_empty() { None } else { Some(icon) }
}

pub fn iconSVGFromHandle(handle: i32, modelName: ArcStr) -> ArcStr {
    match model_icon(handle) {
        Some(icon) => render_icon_svg(&icon, &modelName, &text_advance).map_or_else(ArcStr::new, ArcStr::from),
        None => ArcStr::new(),
    }
}

pub fn graphicalRepresentationXMLFromHandle(handle: i32, scaleToMm: metamodelica::Real) -> ArcStr {
    match model_icon(handle) {
        Some(icon) => ArcStr::from(render_graphical_representation_xml(&icon, scaleToMm.into_inner())),
        None => ArcStr::new(),
    }
}

pub fn writeIconPNGFromHandle(handle: i32, modelName: ArcStr, path: ArcStr) -> bool {
    match model_icon(handle) {
        Some(icon) => write_binary_file(&path, &render_icon_png(&icon, &modelName)),
        None => false,
    }
}

pub fn placedConnectorCount(handle: i32) -> i32 {
    collect_placed_connectors(&ModelInstanceReference::get(handle)).len() as i32
}

pub fn placedConnectorInfo(handle: i32, index: i32) -> ArcStr {
    let cs = collect_placed_connectors(&ModelInstanceReference::get(handle));
    let Some(c) = usize::try_from(index).ok().and_then(|i| cs.get(i)) else {
        return ArcStr::new();
    };
    ArcStr::from(format!(
        "{}\t{}\t{}\t{}\t{}\t{}",
        c.name,
        c.icon_base_name,
        num(c.x1),
        num(c.y1),
        num(c.x2),
        num(c.y2)
    ))
}

pub fn placedConnectorIconSVG(handle: i32, index: i32) -> ArcStr {
    match connector_icon(handle, index) {
        Some(icon) => render_icon_svg(&icon, "", &text_advance).map_or_else(ArcStr::new, ArcStr::from),
        None => ArcStr::new(),
    }
}

pub fn writePlacedConnectorIconPNG(handle: i32, index: i32, path: ArcStr) -> bool {
    match connector_icon(handle, index) {
        Some(icon) => write_binary_file(&path, &render_icon_png(&icon, "")),
        None => false,
    }
}
