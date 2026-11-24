//! Figures of simulation results drawn into files: the `Figure`, `Plot`,
//! `Curve` and `Axis` records of MLS 3.7, section 18.5.2, as JSON from the
//! `OpenModelica.Scripting` records of the same names. Each plot is a charton
//! chart; a figure stacks its plots in one SVG, which resvg rasterizes for PNG.

use std::collections::HashMap;
use std::sync::{Arc, OnceLock};

use charton::error::ChartonError;
use charton::prelude::*;
use charton::scale::ScaleDomain;
use openmodelica_result_files::ResultFile;
use openmodelica_result_files::cmp::format_g_prec;
use openmodelica_result_files::fs;
use openmodelica_result_files::scripting::Messages;
use resvg::tiny_skia;
use resvg::usvg::{self, fontdb};
use serde_json::Value;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Pattern {
    None,
    Solid,
    Dash,
    Dot,
    DashDot,
    DashDotDot,
}

#[derive(Clone, Debug, Default)]
pub struct Axis {
    pub min: Option<f64>,
    pub max: Option<f64>,
    pub unit: String,
    pub label: String,
    /// The base of a logarithmic scale.
    pub log: Option<f64>,
}

#[derive(Clone, Debug)]
pub struct Curve {
    pub x: String,
    pub y: String,
    pub legend: String,
    pub z_order: i64,
    /// A CSS color; empty is automatic.
    pub color: String,
    pub pattern: Pattern,
    /// In mm, as in the `Line` annotation.
    pub thickness: f64,
    /// Empty: the figure's result file.
    pub file: String,
}

#[derive(Clone, Debug, Default)]
pub struct Plot {
    pub title: String,
    pub identifier: String,
    pub curves: Vec<Curve>,
    pub x: Axis,
    pub y: Axis,
}

#[derive(Clone, Debug, Default)]
pub struct Figure {
    pub title: String,
    pub plots: Vec<Plot>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Legend {
    Top,
    Bottom,
    Left,
    Right,
    None,
}

impl Legend {
    pub fn parse(s: &str) -> Option<Legend> {
        Some(match s {
            "top" => Legend::Top,
            "bottom" => Legend::Bottom,
            "left" => Legend::Left,
            "right" => Legend::Right,
            "none" => Legend::None,
            _ => return None,
        })
    }
}

#[derive(Clone, Copy, Debug)]
pub struct Options {
    /// Width and height of each plot, in pixels.
    pub width: u32,
    pub height: u32,
    pub legend: Legend,
}

fn string(v: &Value, key: &str) -> String {
    v.get(key).and_then(Value::as_str).unwrap_or("").to_owned()
}

/// `Real[:]` bounds: empty is automatic.
fn bound(v: &Value, key: &str) -> Option<f64> {
    v.get(key)?.as_array()?.first()?.as_f64()
}

fn list<'a>(v: &'a Value, key: &str) -> &'a [Value] {
    v.get(key).and_then(Value::as_array).map_or(&[], Vec::as_slice)
}

/// An enumeration literal by its last identifier.
fn literal<'a>(v: &'a Value, key: &str) -> Option<&'a str> {
    v.get(key)?.as_str()?.rsplit('.').next()
}

fn axis(v: Option<&Value>) -> Axis {
    let Some(v) = v else {
        return Axis::default();
    };
    Axis {
        min: bound(v, "min"),
        max: bound(v, "max"),
        unit: string(v, "unit"),
        label: string(v, "label"),
        log: v
            .get("scale")
            .filter(|s| string(s, "scaleType") == "Log")
            .map(|s| s.get("base").and_then(Value::as_f64).unwrap_or(10.0).max(2.0)),
    }
}

fn curve(v: &Value) -> Curve {
    let x = string(v, "x");
    Curve {
        x: if x.is_empty() { "time".to_owned() } else { x },
        y: string(v, "y"),
        legend: string(v, "legend"),
        z_order: v.get("zOrder").and_then(Value::as_i64).unwrap_or(0),
        color: string(v, "color"),
        pattern: match literal(v, "pattern") {
            Some("None") => Pattern::None,
            Some("Dash") => Pattern::Dash,
            Some("Dot") => Pattern::Dot,
            Some("DashDot") => Pattern::DashDot,
            Some("DashDotDot") => Pattern::DashDotDot,
            _ => Pattern::Solid,
        },
        thickness: v.get("thickness").and_then(Value::as_f64).unwrap_or(0.25),
        file: string(v, "fileName"),
    }
}

impl Figure {
    pub fn from_json(json: &str) -> Result<Figure, String> {
        let v: Value = serde_json::from_str(json).map_err(|e| e.to_string())?;
        let plots = list(&v, "plots")
            .iter()
            .map(|p| Plot {
                title: string(p, "title"),
                identifier: string(p, "identifier"),
                curves: list(p, "curves").iter().map(curve).collect(),
                x: axis(p.get("x")),
                y: axis(p.get("y")),
            })
            .collect();
        Ok(Figure {
            title: string(&v, "title"),
            plots,
        })
    }
}

/// The scripting API's `plotFigure`, with its `width`, `height` and
/// `legendPosition` arguments.
pub fn plot(
    msgs: &mut dyn Messages,
    figure_json: &str,
    result_file: &str,
    out_file: &str,
    width: i32,
    height: i32,
    legend_position: &str,
) -> bool {
    let Some(legend) = Legend::parse(legend_position) else {
        msgs.error("Unknown legend position %s.", &[legend_position]);
        return false;
    };
    let opts = Options {
        width: width.max(1) as u32,
        height: height.max(1) as u32,
        legend,
    };
    plot_figure(msgs, figure_json, result_file, out_file, &opts)
}

/// Draws `figure_json` with the data of `result_file` (and of each curve's
/// own file) into `out_file`, `.svg` or `.png` by suffix.
pub fn plot_figure(
    msgs: &mut dyn Messages,
    figure_json: &str,
    result_file: &str,
    out_file: &str,
    opts: &Options,
) -> bool {
    let figure = match Figure::from_json(figure_json) {
        Ok(f) => f,
        Err(e) => {
            msgs.error("Invalid figure: %s", &[&e]);
            return false;
        }
    };
    let png = out_file.ends_with(".png");
    if !png && !out_file.ends_with(".svg") {
        msgs.error("Unknown suffix of plot file '%s'; use .svg or .png.", &[out_file]);
        return false;
    }
    let mut files = Files::new(result_file);
    let Some(svg) = render(msgs, &figure, &mut files, opts) else {
        return false;
    };
    let bytes = if png {
        match svg_to_png(&svg) {
            Some(b) => b,
            None => {
                msgs.error("Failed to draw the plot into %s.", &[out_file]);
                return false;
            }
        }
    } else {
        svg.into_bytes()
    };
    let ok = fs::write(out_file, &bytes).is_ok();
    if !ok {
        msgs.error("Failed to write to file %s.", &[out_file]);
    }
    ok
}

/// The result files a figure reads, each opened once.
struct Files {
    default: String,
    open: HashMap<String, Option<ResultFile>>,
}

impl Files {
    fn new(default: &str) -> Files {
        Files {
            default: default.to_owned(),
            open: HashMap::new(),
        }
    }

    fn get(&mut self, msgs: &mut dyn Messages, path: &str) -> Option<&mut ResultFile> {
        let path = if path.is_empty() { self.default.as_str() } else { path };
        if !self.open.contains_key(path) {
            let file = match ResultFile::open(path) {
                Ok(f) => Some(f),
                Err(e) => {
                    msgs.error("%s", &[&e]);
                    None
                }
            };
            self.open.insert(path.to_owned(), file);
        }
        self.open.get_mut(path)?.as_mut()
    }
}

fn column(file: &mut ResultFile, var: &str) -> Option<Vec<f64>> {
    if var == "time" {
        file.time().ok().map(<[f64]>::to_vec)
    } else {
        file.trajectory(var)
    }
}

/// How the values of a variable are shown on an axis.
#[derive(Clone, Debug, PartialEq)]
struct Shown {
    unit: String,
    factor: f64,
    offset: f64,
    inverse: bool,
}

impl Shown {
    fn same(unit: String) -> Shown {
        Shown {
            unit,
            factor: 1.0,
            offset: 0.0,
            inverse: false,
        }
    }

    fn apply(&self, v: f64) -> f64 {
        if self.inverse {
            self.factor / v
        } else {
            self.factor * v + self.offset
        }
    }
}

/// `var` in `axis_unit`, or else in its display unit. `None` when `axis_unit`
/// is set and cannot be reached from the variable's unit.
fn shown(file: &ResultFile, var: &str, axis_unit: &str) -> Option<Shown> {
    let unit = if var == "time" { "s".to_owned() } else { file.unit(var) };
    let display = if var == "time" {
        String::new()
    } else {
        file.display_unit(var)
    };
    let target = if !axis_unit.is_empty() {
        axis_unit
    } else if !display.is_empty() {
        display.as_str()
    } else {
        unit.as_str()
    };
    if unit.is_empty() || target == unit {
        return Some(Shown::same(target.to_owned()));
    }
    let conversion = file.unit_def(&unit).and_then(|d| d.display_unit(target).cloned());
    match conversion {
        Some(du) => Some(Shown {
            unit: target.to_owned(),
            factor: du.factor,
            offset: if file.relative_quantity(var) { 0.0 } else { du.offset },
            inverse: du.inverse,
        }),
        None if axis_unit.is_empty() => Some(Shown::same(unit)),
        None => None,
    }
}

/// `%{var}` replaced by the final value of `var`, `%%` by `%`. A vendor
/// markup `%__Vendor(...)` before the brace is ignored.
fn replace_variables(text: &str, file: Option<&mut ResultFile>) -> String {
    if !text.contains('%') {
        return text.to_owned();
    }
    let mut file = file;
    let mut out = String::new();
    let mut rest = text;
    while let Some(i) = rest.find('%') {
        out.push_str(&rest[..i]);
        rest = &rest[i + 1..];
        if let Some(r) = rest.strip_prefix('%') {
            out.push('%');
            rest = r;
            continue;
        }
        let mut body = rest;
        while let Some(r) = body.strip_prefix("__") {
            match r.find(')') {
                Some(close) => body = &r[close + 1..],
                None => break,
            }
        }
        let Some(inner) = body.strip_prefix('{') else {
            out.push('%');
            continue;
        };
        let Some(end) = reference_end(inner) else {
            out.push('%');
            continue;
        };
        let var = inner[..end].trim();
        let value = file.as_deref_mut().and_then(|f| {
            let stop = f.stop_time();
            f.value_at(var, stop)
        });
        match value {
            Some(v) => out.push_str(&format_g_prec(v, 6)),
            None => {
                out.push('%');
                out.push_str(&rest[..rest.len() - inner.len() + end + 1]);
            }
        }
        rest = &inner[end + 1..];
    }
    out.push_str(rest);
    out
}

/// The index of the brace that closes a result reference, skipping quoted
/// identifiers such as `'}bar{'`.
fn reference_end(s: &str) -> Option<usize> {
    let mut quoted = false;
    let mut escaped = false;
    for (i, c) in s.char_indices() {
        match c {
            _ if escaped => escaped = false,
            '\\' if quoted => escaped = true,
            '\'' => quoted = !quoted,
            '}' if !quoted => return Some(i),
            _ => {}
        }
    }
    None
}

const PALETTE: [&str; 10] = [
    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf",
];

struct Series {
    name: String,
    in_legend: bool,
    color: String,
    width: f64,
    dash: Vec<f64>,
    z_order: i64,
    xs: Vec<f64>,
    ys: Vec<f64>,
}

/// Per pixel column of a curve whose x does not decrease: the first, lowest,
/// highest and last row, in row order. Nothing changes on screen.
fn decimate(xs: &[f64], ys: &[f64], columns: usize) -> (Vec<f64>, Vec<f64>) {
    let n = xs.len();
    let (x0, x1) = (xs[0], xs[n - 1]);
    if n <= 4 * columns || !(x1 > x0) {
        return (xs.to_vec(), ys.to_vec());
    }
    let column = |x: f64| (((x - x0) / (x1 - x0)) * columns as f64) as usize;
    let mut keep: Vec<usize> = Vec::with_capacity(4 * columns + 4);
    let mut start = 0;
    while start < n {
        let c = column(xs[start]);
        let mut end = start + 1;
        while end < n && column(xs[end]) == c {
            end += 1;
        }
        let (mut lo, mut hi) = (start, start);
        for i in start..end {
            if ys[i] < ys[lo] {
                lo = i;
            }
            if ys[i] > ys[hi] {
                hi = i;
            }
        }
        let mut picked = [start, lo, hi, end - 1];
        picked.sort_unstable();
        for i in picked {
            if keep.last() != Some(&i) {
                keep.push(i);
            }
        }
        start = end;
    }
    (
        keep.iter().map(|&i| xs[i]).collect(),
        keep.iter().map(|&i| ys[i]).collect(),
    )
}

fn dash(pattern: Pattern, width: f64) -> Vec<f64> {
    let w = width.max(1.0);
    match pattern {
        Pattern::Dash => vec![6.0 * w, 3.0 * w],
        Pattern::Dot => vec![w, 2.0 * w],
        Pattern::DashDot => vec![6.0 * w, 2.0 * w, w, 2.0 * w],
        Pattern::DashDotDot => vec![6.0 * w, 2.0 * w, w, 2.0 * w, w, 2.0 * w],
        Pattern::None | Pattern::Solid => vec![],
    }
}

fn curve_name(c: &Curve) -> String {
    if c.x == "time" {
        c.y.clone()
    } else {
        format!("{} vs. {}", c.y, c.x)
    }
}

fn file_label(path: &str) -> &str {
    path.rsplit(['/', '\\']).next().unwrap_or(path)
}

/// One axis of a plot: the unit shown for each curve, `None` for the whole
/// axis when one curve cannot be shown in the axis unit.
fn axis_units(
    msgs: &mut dyn Messages,
    files: &mut Files,
    curves: &[(&Curve, String)],
    axis: &Axis,
    use_x: bool,
) -> (Vec<Option<Shown>>, bool) {
    let mut out = Vec::new();
    let mut ok = true;
    for (c, path) in curves {
        let var = if use_x { &c.x } else { &c.y };
        let s = files.get(msgs, path).and_then(|f| shown(f, var, &axis.unit));
        if s.is_none() && !axis.unit.is_empty() {
            ok = false;
        }
        out.push(s);
    }
    if ok {
        return (out, true);
    }
    msgs.warning(
        "The unit %s of a plot axis does not apply to all of its curves; the axis shows the units of the variables.",
        &[&axis.unit],
    );
    let out = curves
        .iter()
        .map(|(c, path)| {
            let var = if use_x { &c.x } else { &c.y };
            files.get(msgs, path).and_then(|f| shown(f, var, ""))
        })
        .collect();
    (out, false)
}

fn common_unit(units: &[Option<Shown>]) -> Option<String> {
    let first = units.first()?.as_ref()?.unit.clone();
    units
        .iter()
        .all(|u| u.as_ref().is_some_and(|u| u.unit == first))
        .then_some(first)
        .filter(|u| !u.is_empty())
}

fn with_unit(label: String, unit: Option<&str>) -> String {
    match unit {
        Some(u) if label.is_empty() => format!("[{u}]"),
        Some(u) => format!("{label} [{u}]"),
        None => label,
    }
}

fn plot_label(i: usize) -> String {
    let mut n = i;
    let mut s = String::new();
    loop {
        s.insert(0, (b'a' + (n % 26) as u8) as char);
        if n < 26 {
            break;
        }
        n = n / 26 - 1;
    }
    format!("({s})")
}

struct Drawn {
    svg: String,
    titles: Vec<String>,
}

fn render(msgs: &mut dyn Messages, figure: &Figure, files: &mut Files, opts: &Options) -> Option<String> {
    let labelled = figure.plots.iter().any(|p| !p.identifier.is_empty());
    let many_files = {
        let mut paths: Vec<&str> = Vec::new();
        for c in figure.plots.iter().flat_map(|p| &p.curves) {
            let p = if c.file.is_empty() {
                files.default.as_str()
            } else {
                c.file.as_str()
            };
            if !paths.contains(&p) {
                paths.push(p);
            }
        }
        paths.len() > 1
    };
    let mut charts = Vec::new();
    for (k, plot) in figure.plots.iter().enumerate() {
        let mut title = replace_variables(&plot.title, files.get(msgs, ""));
        if labelled {
            title = if title.is_empty() {
                plot_label(k)
            } else {
                format!("{} {title}", plot_label(k))
            };
        }
        match render_plot(msgs, plot, files, opts, many_files, &title) {
            Some(d) => charts.push(d),
            None => return None,
        }
    }
    if charts.is_empty() {
        msgs.error("The figure has no plots.", &[]);
        return None;
    }
    let mut title = replace_variables(&figure.title, files.get(msgs, ""));
    if title.is_empty() {
        let mut names: Vec<&str> = Vec::new();
        for n in charts.iter().flat_map(|d| d.titles.iter()) {
            if !names.contains(&n.as_str()) {
                names.push(n);
            }
        }
        title = names.join(", ");
    }
    Some(compose(&title, &charts, opts))
}

fn render_plot(
    msgs: &mut dyn Messages,
    plot: &Plot,
    files: &mut Files,
    opts: &Options,
    many_files: bool,
    title: &str,
) -> Option<Drawn> {
    let curves: Vec<(&Curve, String)> = plot
        .curves
        .iter()
        .filter(|c| c.pattern != Pattern::None)
        .map(|c| {
            (
                c,
                if c.file.is_empty() {
                    files.default.clone()
                } else {
                    c.file.clone()
                },
            )
        })
        .collect();
    let (x_units, x_unit_ok) = axis_units(msgs, files, &curves, &plot.x, true);
    let (y_units, y_unit_ok) = axis_units(msgs, files, &curves, &plot.y, false);
    let x_common = common_unit(&x_units);
    let y_common = common_unit(&y_units);
    let x_range = (
        to_axis(plot.x.min.filter(|_| x_unit_ok), plot.x.log),
        to_axis(plot.x.max.filter(|_| x_unit_ok), plot.x.log),
    );
    let y_range = (
        to_axis(plot.y.min.filter(|_| y_unit_ok), plot.y.log),
        to_axis(plot.y.max.filter(|_| y_unit_ok), plot.y.log),
    );

    let mut series: Vec<Series> = Vec::new();
    let mut names: Vec<String> = Vec::new();
    for (i, (c, path)) in curves.iter().enumerate() {
        let Some(file) = files.get(msgs, path) else {
            return None;
        };
        let (Some(xs), Some(ys)) = (column(file, &c.x), column(file, &c.y)) else {
            let missing = if column(file, &c.x).is_none() { &c.x } else { &c.y };
            msgs.warning("Variable %s is not in result file %s.", &[missing, file_label(path)]);
            continue;
        };
        let xu = x_units[i].clone().unwrap_or_else(|| Shown::same(String::new()));
        let yu = y_units[i].clone().unwrap_or_else(|| Shown::same(String::new()));
        let mut pts: Vec<(f64, f64)> = xs
            .iter()
            .zip(&ys)
            .filter_map(|(&x, &y)| {
                Some((
                    to_axis(Some(xu.apply(x)), plot.x.log)?,
                    to_axis(Some(yu.apply(y)), plot.y.log)?,
                ))
            })
            .filter(|&(x, y)| x.is_finite() && y.is_finite())
            .collect();
        if let (Some(lo), Some(hi)) = x_range
            && c.x == "time"
        {
            let first = pts
                .iter()
                .position(|p| p.0 >= lo)
                .unwrap_or(pts.len())
                .saturating_sub(1);
            let last = pts
                .iter()
                .rposition(|p| p.0 <= hi)
                .map_or(0, |i| (i + 2).min(pts.len()));
            pts = if first < last {
                pts[first..last].to_vec()
            } else {
                Vec::new()
            };
        }
        if pts.is_empty() {
            msgs.warning("Variable %s has no values to plot.", &[&c.y]);
            continue;
        }
        let (mut px, mut py): (Vec<f64>, Vec<f64>) = pts.into_iter().unzip();
        if c.x == "time" {
            (px, py) = decimate(&px, &py, opts.width as usize);
        }
        let mut name = if c.legend.is_empty() {
            curve_name(c)
        } else {
            replace_variables(&c.legend, Some(file))
        };
        if c.legend.is_empty() && many_files {
            name = format!("{name} ({})", file_label(path));
        }
        if y_common.is_none() && !yu.unit.is_empty() {
            name = format!("{name} [{}]", yu.unit);
        }
        let base = name.clone();
        let mut k = 2;
        while names.contains(&name) {
            name = format!("{base} ({k})");
            k += 1;
        }
        names.push(name.clone());
        let width = (c.thickness * 96.0 / 25.4).max(0.5);
        series.push(Series {
            name,
            in_legend: true,
            color: if c.color.is_empty() {
                PALETTE[i % PALETTE.len()].to_owned()
            } else {
                c.color.clone()
            },
            width,
            dash: dash(c.pattern, width),
            z_order: c.z_order,
            xs: px,
            ys: py,
        });
    }
    if series.is_empty() {
        msgs.error("A plot of the figure has no curves to draw.", &[]);
        return None;
    }

    let x_label = if !plot.x.label.is_empty() {
        replace_variables(&plot.x.label, files.get(msgs, ""))
    } else {
        let first = &curves[0].0.x;
        if curves.iter().all(|(c, _)| &c.x == first) {
            first.clone()
        } else {
            String::new()
        }
    };
    let y_label = if !plot.y.label.is_empty() {
        replace_variables(&plot.y.label, files.get(msgs, ""))
    } else if series.len() == 1 && curves.len() == 1 && curves[0].0.legend.is_empty() {
        curves[0].0.y.clone()
    } else {
        String::new()
    };
    let x_label = with_unit(x_label, x_common.as_deref());
    let y_label = with_unit(y_label, y_common.as_deref());

    let domain: Vec<String> = series.iter().filter(|s| s.in_legend).map(|s| s.name.clone()).collect();
    let palette: Vec<&str> = series
        .iter()
        .filter(|s| s.in_legend)
        .map(|s| s.color.as_str())
        .collect();
    let mut order: Vec<usize> = (0..series.len()).collect();
    order.sort_by_key(|&i| series[i].z_order);

    let chart = draw(
        &series, &order, &domain, plot, opts, title, &x_label, &y_label, x_range, y_range, palette,
    );
    match chart {
        Ok(svg) => Some(Drawn {
            svg,
            titles: curves.iter().map(|(c, _)| curve_name(c)).collect(),
        }),
        Err(e) => {
            msgs.error("Failed to draw the plot: %s", &[&e]);
            None
        }
    }
}

#[allow(clippy::too_many_arguments)]
fn draw(
    series: &[Series],
    order: &[usize],
    domain: &[String],
    plot: &Plot,
    opts: &Options,
    title: &str,
    x_label: &str,
    y_label: &str,
    x_range: (Option<f64>, Option<f64>),
    y_range: (Option<f64>, Option<f64>),
    palette: Vec<&str>,
) -> Result<String, String> {
    let err = |e: ChartonError| e.to_string();
    let mut layered: Option<LayeredChart> = None;
    for &i in order {
        let s = &series[i];
        let n = s.xs.len();
        let ds = Dataset::new()
            .with_column("x", s.xs.clone())
            .map_err(err)?
            .with_column("y", s.ys.clone())
            .map_err(err)?
            .with_column("series", vec![s.name.clone(); n])
            .map_err(err)?;
        let (x, y) = (alt::x("x"), alt::y("y"));
        let (width, dash, color) = (s.width, s.dash.clone(), s.color.clone());
        let chart = Chart::build(ds)
            .map_err(err)?
            .mark_path()
            .map_err(err)?
            .configure_path(move |m| m.with_stroke(color.as_str()).with_stroke_width(width).with_dash(dash));
        let chart = if s.in_legend {
            let color = alt::color("series").with_domain(ScaleDomain::Discrete(domain.to_vec()));
            chart.encode((x, y, color)).map_err(err)?
        } else {
            chart.encode((x, y)).map_err(err)?
        };
        layered = Some(match layered {
            None => chart.into(),
            Some(l) => l.and(chart),
        });
    }
    let mut lc = layered.ok_or("no curves")?.with_size(opts.width, opts.height);
    if !title.is_empty() {
        lc = lc.with_title(title.to_owned());
    }
    lc = lc
        .with_x_label(x_label.to_owned())
        .with_y_label(y_label.to_owned())
        .with_color_label("");
    let x_domain = full_range(x_range, plot.x.log.is_some(), series.iter().map(|s| s.xs.as_slice()));
    if let Some((lo, hi)) = x_domain {
        lc = lc.with_x_domain(lo, hi);
    }
    if let (Some(base), Some((lo, hi))) = (plot.x.log, x_domain) {
        let ticks = log_ticks(lo, hi, base);
        lc = lc.with_x_ticks(ticks.iter().map(|(v, l)| (*v, l.as_str())).collect::<Vec<_>>());
    }
    let y_domain = full_range(y_range, plot.y.log.is_some(), series.iter().map(|s| s.ys.as_slice()));
    if let Some((lo, hi)) = y_domain {
        lc = lc.with_y_domain(lo, hi);
    }
    if let (Some(base), Some((lo, hi))) = (plot.y.log, y_domain) {
        let ticks = log_ticks(lo, hi, base);
        lc = lc.with_y_ticks(ticks.iter().map(|(v, l)| (*v, l.as_str())).collect::<Vec<_>>());
    }
    let position = match opts.legend {
        Legend::Top => LegendPosition::Top,
        Legend::Bottom => LegendPosition::Bottom,
        Legend::Left => LegendPosition::Left,
        Legend::Right => LegendPosition::Right,
        Legend::None => LegendPosition::None,
    };
    lc = lc.configure_theme(move |t| t.with_legend_position(position).with_palette(palette));
    lc.to_svg().map_err(err)
}

/// A value on an axis: its logarithm on a logarithmic one, where only
/// positive values have a place.
fn to_axis(v: Option<f64>, log: Option<f64>) -> Option<f64> {
    match log {
        None => v,
        Some(base) => v.filter(|&v| v > 0.0).map(|v| v.ln() / base.ln()),
    }
}

/// The range of an axis: the bounds that are set, the data for the others.
/// A logarithmic axis always gets one, for its ticks.
fn full_range<'a>(
    range: (Option<f64>, Option<f64>),
    log: bool,
    data: impl Iterator<Item = &'a [f64]>,
) -> Option<(f64, f64)> {
    if let (Some(lo), Some(hi)) = range {
        return Some((lo, hi));
    }
    if range == (None, None) && !log {
        return None;
    }
    let (mut dmin, mut dmax) = (f64::INFINITY, f64::NEG_INFINITY);
    for v in data.flatten() {
        dmin = dmin.min(*v);
        dmax = dmax.max(*v);
    }
    let (mut lo, mut hi) = (range.0.unwrap_or(dmin), range.1.unwrap_or(dmax));
    if !(hi > lo) {
        lo -= 0.5;
        hi += 0.5;
    }
    Some((lo, hi))
}

/// The ticks of a logarithmic axis between `lo` and `hi`, which are
/// logarithms: at powers of `base`, or at 1, 2 and 5 times the powers of ten
/// when fewer than two powers fit.
fn log_ticks(lo: f64, hi: f64, base: f64) -> Vec<(f64, String)> {
    let (first, last) = (lo.ceil() as i64, hi.floor() as i64);
    if last > first + 1 {
        let step = ((last - first) / 8 + 1) as usize;
        return (first..=last)
            .step_by(step)
            .map(|k| (k as f64, format_g_prec(base.powi(k as i32), 6)))
            .collect();
    }
    let (vlo, vhi) = (base.powf(lo), base.powf(hi));
    let mut ticks = Vec::new();
    for k in vlo.log10().floor() as i32..=vhi.log10().ceil() as i32 {
        for m in [1.0, 2.0, 5.0] {
            let v = m * 10f64.powi(k);
            if v >= vlo * (1.0 - 1e-12) && v <= vhi * (1.0 + 1e-12) {
                ticks.push((v.ln() / base.ln(), format_g_prec(v, 6)));
            }
        }
    }
    ticks
}

fn escape_xml(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}

const TITLE_HEIGHT: u32 = 36;

/// The plots one below the other, under the figure title.
fn compose(title: &str, charts: &[Drawn], opts: &Options) -> String {
    let (w, h) = (opts.width, opts.height);
    let total = TITLE_HEIGHT + h * charts.len() as u32;
    let mut svg = format!(
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{w}\" height=\"{total}\" viewBox=\"0 0 {w} {total}\">\n\
         <rect width=\"100%\" height=\"100%\" fill=\"white\"/>\n\
         <text x=\"{}\" y=\"{}\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"18\" font-weight=\"bold\">{}</text>\n",
        w / 2,
        TITLE_HEIGHT - 12,
        escape_xml(title)
    );
    for (k, d) in charts.iter().enumerate() {
        svg.push_str(&nest(&d.svg, TITLE_HEIGHT + h * k as u32, &format!("p{k}-")));
        svg.push('\n');
    }
    svg.push_str("</svg>\n");
    svg
}

/// A chart's SVG document as a nested `<svg>` at `y`, its ids prefixed so
/// that the plots of one figure do not share clip paths.
fn nest(doc: &str, y: u32, prefix: &str) -> String {
    let start = doc.find("<svg").unwrap_or(0);
    let body = &doc[start..];
    let body = body
        .replace("id=\"", &format!("id=\"{prefix}"))
        .replace("url(#", &format!("url(#{prefix}"))
        .replace("href=\"#", &format!("href=\"#{prefix}"));
    body.replacen("<svg", &format!("<svg x=\"0\" y=\"{y}\""), 1)
}

fn font_db() -> Arc<fontdb::Database> {
    static DB: OnceLock<Arc<fontdb::Database>> = OnceLock::new();
    DB.get_or_init(|| {
        #[allow(unused_mut)]
        let mut db = fontdb::Database::new();
        #[cfg(not(target_arch = "wasm32"))]
        db.load_system_fonts();
        let installed = |names: &[&str]| {
            names
                .iter()
                .find(|n| db.faces().any(|f| f.families.iter().any(|(family, _)| family == *n)))
                .map(|n| n.to_string())
        };
        let sans = [
            "DejaVu Sans",
            "Liberation Sans",
            "Arial",
            "Helvetica",
            "Noto Sans",
            "Segoe UI",
        ];
        if let Some(family) = installed(&sans) {
            db.set_sans_serif_family(family);
        }
        Arc::new(db)
    })
    .clone()
}

fn svg_to_png(svg: &str) -> Option<Vec<u8>> {
    let opt = usvg::Options {
        fontdb: font_db(),
        ..usvg::Options::default()
    };
    let tree = usvg::Tree::from_str(svg, &opt).ok()?;
    let size = tree.size().to_int_size();
    let mut pixmap = tiny_skia::Pixmap::new(size.width(), size.height())?;
    resvg::render(&tree, tiny_skia::Transform::default(), &mut pixmap.as_mut());
    pixmap.encode_png().ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn variable_replacement() {
        assert_eq!(replace_variables("100%% done", None), "100% done");
        assert_eq!(replace_variables("w = %{w}", None), "w = %{w}");
        assert_eq!(reference_end("foo . '}bar{'} rest"), Some(13));
    }

    #[test]
    fn decimation_keeps_extremes() {
        let xs: Vec<f64> = (0..10000).map(|i| i as f64).collect();
        let ys: Vec<f64> = xs.iter().map(|x| (x / 50.0).sin()).collect();
        let (dx, dy) = decimate(&xs, &ys, 100);
        assert!(dx.len() <= 400);
        assert_eq!(dx[0], 0.0);
        assert_eq!(*dx.last().unwrap(), 9999.0);
        let max = dy.iter().cloned().fold(f64::MIN, f64::max);
        assert!((max - 1.0).abs() < 1e-3);
    }

    #[test]
    fn labels() {
        assert_eq!(plot_label(0), "(a)");
        assert_eq!(plot_label(25), "(z)");
        assert_eq!(plot_label(26), "(aa)");
    }

    #[test]
    fn logarithmic_ticks() {
        let t: Vec<String> = log_ticks(-1.0, 2.0, 10.0).into_iter().map(|t| t.1).collect();
        assert_eq!(t, ["0.1", "1", "10", "100"]);
        let t: Vec<String> = log_ticks(0.0, 1.6, 10.0).into_iter().map(|t| t.1).collect();
        assert_eq!(t, ["1", "2", "5", "10", "20"]);
    }
}
