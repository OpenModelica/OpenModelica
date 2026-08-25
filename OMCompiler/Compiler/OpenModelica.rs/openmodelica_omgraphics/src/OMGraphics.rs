//! Qt-free renderer for Modelica graphical (Icon) annotations: the Rust port of
//! `runtime/OMGraphics.cpp` + `OMGraphics_omc.cpp`, the `external "C"` bodies of
//! `Compiler/Util/OMGraphics.mo`. Modelica has y up, SVG has y down, so the
//! drawing sits in a root group that flips y and text/images undo the flip.

// The entry points keep their MetaModelica names, which mmtorust calls.
#![allow(non_snake_case)]

use std::sync::Arc;

use arcstr::ArcStr;
use openmodelica_util::JSON::JSON;
use openmodelica_util::ModelInstanceReference;
use openmodelica_util::UnorderedMap;
use openmodelica_util::Vector;

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
        if i == 1 {
            FillPattern::None
        } else {
            FillPattern::Solid
        }
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
        LinePattern::DashDot => format!(
            "{},{},{},{}",
            num(4.0 * u),
            num(2.0 * u),
            num(u),
            num(2.0 * u)
        ),
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
    (s.end_angle - s.start_angle).abs() >= 359.999
        || (s.start_angle == 0.0 && s.end_angle == 0.0)
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
    let large = if (s.end_angle - s.start_angle).abs() > 180.0 { 1 } else { 0 };
    let arc = format!(
        "A {} {} 0 {} 1 {} {}",
        num(rx),
        num(ry),
        large,
        num(x1),
        num(y1)
    );
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

fn emit_text(svg: &mut String, s: &Shape, name_text: &str) {
    let cx = (s.extent.p1.x + s.extent.p2.x) / 2.0;
    let cy = (s.extent.p1.y + s.extent.p2.y) / 2.0;
    let h = (s.extent.p2.y - s.extent.p1.y).abs();
    let size = if s.font_size > 0.0 {
        s.font_size
    } else if h > 0.0 {
        h * 0.8
    } else {
        10.0
    };

    let txt = if name_text.is_empty() {
        s.text_string.to_string()
    } else {
        s.text_string.replace("%name", name_text)
    };

    let col = if s.text_color.is_set() { s.text_color } else { s.line_color };
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
    if !s.font_name.is_empty() {
        svg.push_str(&format!(" font-family=\"{}\"", escape_xml(&s.font_name)));
    }
    svg.push_str(&format!(
        " style=\"fill:{};{}\">{}</text>\n    </g>\n",
        col.to_svg(),
        style,
        escape_xml(&txt)
    ));
}

fn emit_bitmap(svg: &mut String, s: &Shape) {
    let x = s.extent.p1.x.min(s.extent.p2.x);
    let y = s.extent.p1.y.min(s.extent.p2.y);
    let w = (s.extent.p2.x - s.extent.p1.x).abs();
    let h = (s.extent.p2.y - s.extent.p1.y).abs();
    let href = if !s.image_source.is_empty() {
        format!("data:image/png;base64,{}", s.image_source)
    } else if !s.file_name.is_empty() {
        escape_xml(&s.file_name)
    } else {
        return;
    };
    // undo the y-flip so the image is not upside down
    svg.push_str(&format!(
        "    <g transform=\"translate({},{}) scale(1,-1)\">\n",
        num(x),
        num(y + h)
    ));
    svg.push_str(&format!(
        "      <image x=\"0\" y=\"0\" width=\"{}\" height=\"{}\" preserveAspectRatio=\"none\" xlink:href=\"{}\"/>\n    </g>\n",
        num(w),
        num(h),
        href
    ));
}

fn emit_shape(svg: &mut String, s: &Shape, name_text: &str) {
    if !s.visible {
        return;
    }
    let transformed = s.origin.x != 0.0 || s.origin.y != 0.0 || s.rotation != 0.0;
    if transformed {
        svg.push_str("  <g transform=\"");
        if s.origin.x != 0.0 || s.origin.y != 0.0 {
            svg.push_str(&format!(
                "translate({},{}) ",
                num(s.origin.x),
                num(s.origin.y)
            ));
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
        ShapeKind::Text => emit_text(svg, s, name_text),
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
    let xmin = e.p1.x.min(e.p2.x);
    let xmax = e.p1.x.max(e.p2.x);
    let ymin = e.p1.y.min(e.p2.y);
    let ymax = e.p1.y.max(e.p2.y);
    let mut w = xmax - xmin;
    let mut h = ymax - ymin;
    if w <= 0.0 {
        w = 200.0;
    }
    if h <= 0.0 {
        h = 200.0;
    }
    let mut max_stroke: f64 = 0.0;
    for s in &icon.graphics {
        let tw = if s.kind == ShapeKind::Line { s.thickness } else { s.line_thickness };
        max_stroke = max_stroke.max(stroke_width(tw));
    }
    let margin = max_stroke.max(0.005 * w.max(h));
    ViewBox {
        x: xmin - margin,
        y: ymin - margin,
        w: w + 2.0 * margin,
        h: h + 2.0 * margin,
        ymin,
        ymax,
    }
}

fn render_icon_svg(icon: &Icon, name_text: &str) -> String {
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
    for s in &icon.graphics {
        emit_shape(&mut svg, s, name_text);
    }
    svg.push_str("  </g>\n</svg>\n");
    svg
}

// PNG rasteriser. FMI 3.0 requires the icons referenced from
// terminalsAndIcons.xml to be PNG; the SVG is an optional companion.
// Anti-aliasing is by supersampling: drawn at SS x, then box-downsampled.

const SS: usize = 3; // supersampling factor (per axis)
const MAX_DIM: f64 = 512.0; // clamp for the final image size (px)

/// RGBA8, row-major, transparent background.
struct Raster {
    w: usize,
    h: usize,
    px: Vec<u8>,
}

impl Raster {
    fn new(w: usize, h: usize) -> Raster {
        Raster { w, h, px: vec![0; w * h * 4] }
    }

    fn set(&mut self, x: i64, y: i64, c: Color) {
        if x < 0 || y < 0 || x as usize >= self.w || y as usize >= self.h {
            return;
        }
        let i = ((y as usize) * self.w + x as usize) * 4;
        self.px[i] = c.r.max(0) as u8;
        self.px[i + 1] = c.g.max(0) as u8;
        self.px[i + 2] = c.b.max(0) as u8;
        self.px[i + 3] = 255;
    }
}

/// Icon coordinates to supersampled device pixels, y flipped.
struct DeviceMap {
    vb: ViewBox,
    sw: f64,
    sh: f64,
}

impl DeviceMap {
    fn map(&self, x: f64, y: f64) -> Point {
        Point {
            x: (x - self.vb.x) / self.vb.w * self.sw,
            y: ((self.vb.y + self.vb.h) - y) / self.vb.h * self.sh,
        }
    }
}

/// The shape's local transform, mirroring the SVG `translate() rotate()` group.
fn apply_shape_transform(s: &Shape, p: Point) -> Point {
    let a = s.rotation.to_radians();
    let (sa, ca) = a.sin_cos();
    Point {
        x: s.origin.x + (ca * p.x - sa * p.y),
        y: s.origin.y + (sa * p.x + ca * p.y),
    }
}

/// Even-odd scanline fill of device-space vertices.
fn fill_polygon(r: &mut Raster, pts: &[Point], c: Color) {
    if pts.len() < 3 {
        return;
    }
    let ymin = pts.iter().fold(f64::INFINITY, |a, p| a.min(p.y));
    let ymax = pts.iter().fold(f64::NEG_INFINITY, |a, p| a.max(p.y));
    let y0 = (ymin.floor() as i64).max(0);
    let y1 = (ymax.ceil() as i64).min(r.h as i64 - 1);
    let mut xs: Vec<f64> = Vec::new();
    for y in y0..=y1 {
        let yc = y as f64 + 0.5;
        xs.clear();
        for i in 0..pts.len() {
            let (a, b) = (pts[i], pts[(i + 1) % pts.len()]);
            if (a.y <= yc && b.y > yc) || (b.y <= yc && a.y > yc) {
                let t = (yc - a.y) / (b.y - a.y);
                xs.push(a.x + t * (b.x - a.x));
            }
        }
        if xs.len() < 2 {
            continue;
        }
        xs.sort_by(|a, b| a.partial_cmp(b).unwrap());
        for pair in xs.chunks_exact(2) {
            let xa = ((pair[0] - 0.5).ceil() as i64).max(0);
            let xb = ((pair[1] - 0.5).floor() as i64).min(r.w as i64 - 1);
            for x in xa..=xb {
                r.set(x, y, c);
            }
        }
    }
}

/// Round line caps/joins.
fn fill_disk(r: &mut Raster, cx: f64, cy: f64, rad: f64, c: Color) {
    if rad <= 0.0 {
        return;
    }
    let x0 = ((cx - rad).floor() as i64).max(0);
    let x1 = ((cx + rad).ceil() as i64).min(r.w as i64 - 1);
    let y0 = ((cy - rad).floor() as i64).max(0);
    let y1 = ((cy + rad).ceil() as i64).min(r.h as i64 - 1);
    let r2 = rad * rad;
    for y in y0..=y1 {
        for x in x0..=x1 {
            let dx = x as f64 + 0.5 - cx;
            let dy = y as f64 + 0.5 - cy;
            if dx * dx + dy * dy <= r2 {
                r.set(x, y, c);
            }
        }
    }
}

/// A quad per segment plus a disk at every vertex.
fn stroke_polyline(r: &mut Raster, pts: &[Point], closed: bool, c: Color, width_px: f64) {
    let hw = width_px.max(1.0) / 2.0;
    let n = pts.len();
    if n < 2 {
        if n == 1 {
            fill_disk(r, pts[0].x, pts[0].y, hw, c);
        }
        return;
    }
    let segs = if closed { n } else { n - 1 };
    for i in 0..segs {
        let (a, b) = (pts[i], pts[(i + 1) % n]);
        let (dx, dy) = (b.x - a.x, b.y - a.y);
        let len = (dx * dx + dy * dy).sqrt();
        if len < 1e-9 {
            continue;
        }
        let (nx, ny) = (-dy / len * hw, dx / len * hw);
        let quad = [
            Point { x: a.x + nx, y: a.y + ny },
            Point { x: b.x + nx, y: b.y + ny },
            Point { x: b.x - nx, y: b.y - ny },
            Point { x: a.x - nx, y: a.y - ny },
        ];
        fill_polygon(r, &quad, c);
    }
    for p in pts {
        fill_disk(r, p.x, p.y, hw, c);
    }
}

fn ellipse_points(s: &Shape) -> Vec<Point> {
    let cx = (s.extent.p1.x + s.extent.p2.x) / 2.0;
    let cy = (s.extent.p1.y + s.extent.p2.y) / 2.0;
    let rx = (s.extent.p2.x - s.extent.p1.x).abs() / 2.0;
    let ry = (s.extent.p2.y - s.extent.p1.y).abs() / 2.0;
    let full = is_full_ellipse(s);
    let (a0, a1) = if full {
        (0.0, std::f64::consts::TAU)
    } else {
        (s.start_angle.to_radians(), s.end_angle.to_radians())
    };
    const N: i32 = 64;
    let mut pts = Vec::with_capacity(N as usize + 2);
    if !full && s.closure == EllipseClosure::Radial {
        pts.push(Point { x: cx, y: cy }); // pie centre
    }
    for i in 0..=N {
        let a = a0 + (a1 - a0) * f64::from(i) / f64::from(N);
        pts.push(Point { x: cx + rx * a.cos(), y: cy + ry * a.sin() });
    }
    pts
}

fn to_device(m: &DeviceMap, s: &Shape, pts: &[Point]) -> Vec<Point> {
    pts.iter()
        .map(|p| {
            let w = apply_shape_transform(s, *p);
            m.map(w.x, w.y)
        })
        .collect()
}

fn raster_shape(r: &mut Raster, m: &DeviceMap, s: &Shape) {
    if !s.visible {
        return;
    }
    // stroke width: coordinate units -> pixels
    let px_per_unit = m.sw / m.vb.w;
    match s.kind {
        ShapeKind::Rectangle => {
            let x0 = s.extent.p1.x.min(s.extent.p2.x);
            let x1 = s.extent.p1.x.max(s.extent.p2.x);
            let y0 = s.extent.p1.y.min(s.extent.p2.y);
            let y1 = s.extent.p1.y.max(s.extent.p2.y);
            let corners = [
                Point { x: x0, y: y0 },
                Point { x: x1, y: y0 },
                Point { x: x1, y: y1 },
                Point { x: x0, y: y1 },
            ];
            let dev = to_device(m, s, &corners);
            if s.fill_pattern != FillPattern::None {
                fill_polygon(r, &dev, s.fill_color);
            }
            if s.line_pattern != LinePattern::None {
                stroke_polyline(r, &dev, true, s.line_color, stroke_width(s.line_thickness) * px_per_unit);
            }
        }
        ShapeKind::Polygon => {
            let dev = to_device(m, s, &s.points);
            if s.fill_pattern != FillPattern::None {
                fill_polygon(r, &dev, s.fill_color);
            }
            if s.line_pattern != LinePattern::None {
                stroke_polyline(r, &dev, true, s.line_color, stroke_width(s.line_thickness) * px_per_unit);
            }
        }
        ShapeKind::Ellipse => {
            let dev = to_device(m, s, &ellipse_points(s));
            // a partial ellipse is only closed for Chord/Radial
            let closed = is_full_ellipse(s) || s.closure != EllipseClosure::None;
            if closed && s.fill_pattern != FillPattern::None {
                fill_polygon(r, &dev, s.fill_color);
            }
            if s.line_pattern != LinePattern::None {
                stroke_polyline(r, &dev, closed, s.line_color, stroke_width(s.line_thickness) * px_per_unit);
            }
        }
        ShapeKind::Line => {
            let dev = to_device(m, s, &s.points);
            if s.line_pattern != LinePattern::None {
                stroke_polyline(r, &dev, false, s.color, stroke_width(s.thickness) * px_per_unit);
            }
        }
        // no font / image decoder in this Qt-free path
        ShapeKind::Text | ShapeKind::Bitmap => {}
    }
}

/// Average RGBA over each SS x SS block, so edges come out anti-aliased.
fn downsample(hi: &Raster, factor: usize) -> Raster {
    let mut lo = Raster::new(hi.w / factor, hi.h / factor);
    for y in 0..lo.h {
        for x in 0..lo.w {
            let (mut sr, mut sg, mut sb, mut sa) = (0u64, 0u64, 0u64, 0u64);
            for dy in 0..factor {
                for dx in 0..factor {
                    let i = ((y * factor + dy) * hi.w + (x * factor + dx)) * 4;
                    let p = &hi.px[i..i + 4];
                    // premultiply so transparent texels don't bleed black into edges
                    sr += u64::from(p[0]) * u64::from(p[3]);
                    sg += u64::from(p[1]) * u64::from(p[3]);
                    sb += u64::from(p[2]) * u64::from(p[3]);
                    sa += u64::from(p[3]);
                }
            }
            let o = (y * lo.w + x) * 4;
            if sa > 0 {
                lo.px[o] = (sr / sa) as u8;
                lo.px[o + 1] = (sg / sa) as u8;
                lo.px[o + 2] = (sb / sa) as u8;
            }
            lo.px[o + 3] = (sa / (factor * factor) as u64) as u8;
        }
    }
    lo
}

fn put_u32(out: &mut Vec<u8>, v: u32) {
    out.extend_from_slice(&v.to_be_bytes());
}

/// length + type + data + CRC over type+data.
fn put_chunk(out: &mut Vec<u8>, tag: &[u8; 4], data: &[u8]) {
    put_u32(out, data.len() as u32);
    out.extend_from_slice(tag);
    out.extend_from_slice(data);
    let mut crc = flate2::Crc::new();
    crc.update(tag);
    crc.update(data);
    put_u32(out, crc.sum());
}

/// PNG colour type 6, filter 0 per row.
fn encode_png(img: &Raster) -> Vec<u8> {
    use std::io::Write;

    let mut ihdr = Vec::with_capacity(13);
    put_u32(&mut ihdr, img.w as u32);
    put_u32(&mut ihdr, img.h as u32);
    ihdr.extend_from_slice(&[8, 6, 0, 0, 0]); // bit depth, RGBA, deflate, filter, no interlace

    let mut raw = Vec::with_capacity(img.h * (img.w * 4 + 1));
    for y in 0..img.h {
        raw.push(0); // filter type: none
        raw.extend_from_slice(&img.px[y * img.w * 4..(y + 1) * img.w * 4]);
    }

    let mut enc = flate2::write::ZlibEncoder::new(Vec::new(), flate2::Compression::best());
    if enc.write_all(&raw).is_err() {
        return Vec::new();
    }
    let Ok(idat) = enc.finish() else {
        return Vec::new();
    };

    let mut out = Vec::with_capacity(idat.len() + 64);
    out.extend_from_slice(&[0x89, b'P', b'N', b'G', 0x0D, 0x0A, 0x1A, 0x0A]);
    put_chunk(&mut out, b"IHDR", &ihdr);
    put_chunk(&mut out, b"IDAT", &idat);
    put_chunk(&mut out, b"IEND", &[]);
    out
}

fn render_icon_png(icon: &Icon) -> Vec<u8> {
    if icon.graphics.is_empty() {
        return Vec::new();
    }
    let vb = view_box(icon);
    // ~1 px per coordinate unit, clamped, aspect preserved
    let maxc = vb.w.max(vb.h);
    let scale = if maxc > MAX_DIM { MAX_DIM / maxc } else { 1.0 };
    let out_w = ((vb.w * scale).round() as usize).max(1);
    let out_h = ((vb.h * scale).round() as usize).max(1);

    let mut hi = Raster::new(out_w * SS, out_h * SS);
    let m = DeviceMap { sw: hi.w as f64, sh: hi.h as f64, vb };
    for s in &icon.graphics {
        raster_shape(&mut hi, &m, s);
    }
    encode_png(&downsample(&hi, SS))
}

// JSON accessors. `None` plays the role of the C++ renderer's null Json
// sentinel, so lookups chain without intermediate checks.

type J = Option<Arc<JSON>>;

trait JsonExt {
    fn get(&self, key: &str) -> J;
    fn at(&self, index: usize) -> J;
    fn items(&self) -> Vec<Arc<JSON>>;
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
            JSON::OBJECT { values } => {
                UnorderedMap::get(ArcStr::from(key), values.clone()).ok().flatten()
            }
            _ => None,
        }
    }

    fn at(&self, index: usize) -> J {
        match self.as_deref()? {
            JSON::LIST { values } => (&**values).into_iter().nth(index).cloned(),
            JSON::ARRAY { values } => {
                Vector::get(values.clone(), index as i32 + 1).ok()
            }
            _ => None,
        }
    }

    fn items(&self) -> Vec<Arc<JSON>> {
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
        matches!(
            self.as_deref(),
            Some(JSON::OBJECT { .. } | JSON::LIST_OBJECT { .. })
        )
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
        Point { x: j.at(0).as_num(), y: j.at(1).as_num() }
    } else {
        Point::default()
    }
}

fn parse_extent(j: &J) -> Extent {
    if j.len() >= 2 {
        Extent { p1: parse_point(&j.at(0)), p2: parse_point(&j.at(1)) }
    } else {
        Extent::default()
    }
}

fn parse_points(j: &J) -> Vec<Point> {
    j.items().into_iter().map(|p| parse_point(&Some(p))).collect()
}

fn parse_color(j: &J) -> Color {
    if j.len() >= 3 {
        Color { r: j.at(0).as_int(), g: j.at(1).as_int(), b: j.at(2).as_int() }
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
            s.horizontal_alignment =
                TextAlignment::from_index(enum_index(&el[14], TextAlignment::Center as i32));
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
fn find_icon_object(root: &J) -> J {
    let icon = root.get("annotation").get("Icon");
    if icon.is_object() {
        return icon;
    }
    let icon = root.get("Icon");
    if icon.is_object() {
        return icon;
    }
    if root.get("graphics").is_array() || root.get("coordinateSystem").is_object() {
        return root.clone();
    }
    None
}

fn icon_from_json(root: &J) -> Icon {
    let mut icon = Icon::default();
    let Some(icon_obj) = find_icon_object(root) else {
        return icon;
    };
    let icon_obj = Some(icon_obj);

    let ext = icon_obj.get("coordinateSystem").get("extent");
    if ext.len() >= 2 {
        icon.extent = parse_extent(&ext);
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
    icon: J,
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
        let ext = e
            .get("annotation")
            .get("Placement")
            .get("transformation")
            .get("extent");
        let Some(b) = placement_box(&ext) else {
            continue; // no placement -> not drawn
        };
        let icon = t.get("annotation").get("Icon");
        out.push(PlacedConnector {
            name: e.get("name").as_str(),
            icon_base_name: icon_base_name_of(&t.get("name").as_str()),
            x1: b[0],
            y1: b[1],
            x2: b[2],
            y2: b[3],
            icon: if icon.is_object() { icon } else { None },
        });
    }
    out
}

fn connector_icon(handle: i32, index: i32) -> Option<Icon> {
    let cs = collect_placed_connectors(&ModelInstanceReference::get(handle));
    let c = cs.get(usize::try_from(index).ok()?)?;
    let icon = icon_from_json(&c.icon);
    if icon.graphics.is_empty() { None } else { Some(icon) }
}

fn write_binary_file(path: &str, data: &[u8]) -> bool {
    !data.is_empty() && openmodelica_wasi::fs::write(path, data).is_ok()
}

// The bodies of Compiler/Util/OMGraphics.mo. `handle` is an in-memory
// model-instance reference (issue #15219) holding list-form JSON.

fn model_icon(handle: i32) -> Option<Icon> {
    let icon = icon_from_json(&ModelInstanceReference::get(handle));
    if icon.graphics.is_empty() { None } else { Some(icon) }
}

pub fn iconSVGFromHandle(handle: i32, modelName: ArcStr) -> ArcStr {
    match model_icon(handle) {
        Some(icon) => ArcStr::from(render_icon_svg(&icon, &modelName)),
        None => ArcStr::new(),
    }
}

pub fn graphicalRepresentationXMLFromHandle(handle: i32, scaleToMm: metamodelica::Real) -> ArcStr {
    match model_icon(handle) {
        Some(icon) => ArcStr::from(render_graphical_representation_xml(
            &icon,
            scaleToMm.into_inner(),
        )),
        None => ArcStr::new(),
    }
}

pub fn writeIconPNGFromHandle(handle: i32, _modelName: ArcStr, path: ArcStr) -> bool {
    match model_icon(handle) {
        Some(icon) => write_binary_file(&path, &render_icon_png(&icon)),
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
        Some(icon) => ArcStr::from(render_icon_svg(&icon, "")),
        None => ArcStr::new(),
    }
}

pub fn writePlacedConnectorIconPNG(handle: i32, index: i32, path: ArcStr) -> bool {
    match connector_icon(handle, index) {
        Some(icon) => write_binary_file(&path, &render_icon_png(&icon)),
        None => false,
    }
}
