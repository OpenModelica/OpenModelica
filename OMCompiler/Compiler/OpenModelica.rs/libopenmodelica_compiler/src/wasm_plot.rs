//! Browser-wasm plotting. The compiler invokes `System::plotCallBack` when an
//! evaluated `plot(...)`/`plotAll(...)`/`plotParametric(...)` script runs and a
//! plot callback is registered (otherwise it tries to spawn the external
//! `OMPlot` process, which does not exist on wasm). We register a callback that
//! reads the simulation result out of the VFS, renders an SVG chart with the
//! `charton` crate, and inserts it into the page's `#log` element — right where
//! the command's text output appears.
//!
//! The callback is the C `PlotCallback` ABI (so it plugs into the same registry
//! the native OMEdit Qt callback uses). It must not unwind across that boundary,
//! so every fallible step returns a `Result` and failures are reported as a log
//! line rather than a panic.

use std::ffi::{CStr, c_char, c_int, c_void};
use std::sync::Arc;

use arcstr::ArcStr;
use charton::prelude::*;

use metamodelica::List;
use openmodelica_frontend_types::Values;
use openmodelica_script_util::SimulationResults;
use openmodelica_util::System;

/// Install the wasm plot callback. Called once from `omc_init`.
pub fn register() {
    System::omc_set_plot_callback(std::ptr::null_mut(), Some(plot_callback));
}

/// Decode a C string argument (null → empty).
unsafe fn cs(p: *const c_char) -> String {
    if p.is_null() {
        String::new()
    } else {
        unsafe { CStr::from_ptr(p) }.to_string_lossy().into_owned()
    }
}

/// The C `PlotCallback`: a host class pointer (unused here), the external-window
/// flag, then the 18 string arguments `System::plotCallBack` forwards.
#[allow(clippy::too_many_arguments)]
unsafe extern "C" fn plot_callback(
    _class: *mut c_void,
    _external_window: c_int,
    filename: *const c_char,
    title: *const c_char,
    _grid: *const c_char,
    plot_type: *const c_char,
    log_x: *const c_char,
    log_y: *const c_char,
    x_label: *const c_char,
    y_label: *const c_char,
    x1: *const c_char,
    x2: *const c_char,
    y1: *const c_char,
    y2: *const c_char,
    _curve_width: *const c_char,
    _curve_style: *const c_char,
    _legend_position: *const c_char,
    _footer: *const c_char,
    auto_scale: *const c_char,
    variables: *const c_char,
) {
    let args = unsafe {
        PlotArgs {
            filename: cs(filename),
            title: cs(title),
            plot_type: cs(plot_type),
            log_x: cs(log_x) == "true",
            log_y: cs(log_y) == "true",
            x_label: cs(x_label),
            y_label: cs(y_label),
            x1: cs(x1).parse().unwrap_or(0.0),
            x2: cs(x2).parse().unwrap_or(0.0),
            y1: cs(y1).parse().unwrap_or(0.0),
            y2: cs(y2).parse().unwrap_or(0.0),
            auto_scale: cs(auto_scale) == "true",
            variables: cs(variables),
        }
    };
    match render(&args) {
        Ok(svg) => insert_html(&format!("<div class=\"plot\">{svg}</div>")),
        Err(e) => insert_html(&format!("<div class=\"err\">plot failed: {}</div>", escape(&e))),
    }
}

struct PlotArgs {
    filename: String,
    title: String,
    plot_type: String,
    log_x: bool,
    log_y: bool,
    x_label: String,
    y_label: String,
    x1: f64,
    x2: f64,
    y1: f64,
    y2: f64,
    auto_scale: bool,
    variables: String,
}

/// Read the result and render the requested chart to an SVG string.
fn render(a: &PlotArgs) -> Result<String, String> {
    let filename = ArcStr::from(a.filename.as_str());

    if a.plot_type == "plotparametric" {
        // `variables` is "<xvar> <yvar>": plot the second against the first.
        // charton's line renderer sorts points by x, which would scramble a
        // (generally non-monotonic) parametric trajectory — so draw points.
        let names: Vec<&str> = a.variables.split_whitespace().collect();
        let [xvar, yvar] = names[..] else {
            return Err("plotParametric expects exactly two variables".into());
        };
        let cols = read_columns(&filename, &[xvar, yvar])?;
        let ds = Dataset::new()
            .with_column("x", cols[0].clone())
            .map_err(|e| e.to_string())?
            .with_column("y", cols[1].clone())
            .map_err(|e| e.to_string())?;
        let (x, y) = scaled_axes(a);
        let chart = Chart::build(ds)
            .map_err(|e| e.to_string())?
            .mark_point()
            .map_err(|e| e.to_string())?
            .encode((x, y))
            .map_err(|e| e.to_string())?;
        return finish(chart.with_size(720, 420), a, xvar, yvar);
    }

    // Time series: `plot` lists the variables, `plotAll` leaves them empty.
    let names: Vec<String> = if a.variables.split_whitespace().next().is_some() {
        a.variables.split_whitespace().map(str::to_owned).collect()
    } else {
        let all = SimulationResults::readVariables(filename.clone(), false, false)
            .map_err(|e| e.to_string())?;
        // Drop the independent variable and internal helper variables.
        list_to_vec(&all)
            .into_iter()
            .map(|s| s.to_string())
            .filter(|s| s != "time" && !s.starts_with('$'))
            .collect()
    };
    if names.is_empty() {
        return Err("no variables to plot".into());
    }

    // Read "time" plus each variable, then reshape to long form so a single
    // `color` encoding draws one line per variable.
    let mut wanted: Vec<&str> = Vec::with_capacity(names.len() + 1);
    wanted.push("time");
    wanted.extend(names.iter().map(String::as_str));
    let cols = read_columns(&filename, &wanted)?;
    let time = &cols[0];

    let mut xs: Vec<f64> = Vec::new();
    let mut ys: Vec<f64> = Vec::new();
    let mut series: Vec<String> = Vec::new();
    for (name, col) in names.iter().zip(&cols[1..]) {
        for (&t, &v) in time.iter().zip(col.iter()) {
            xs.push(t);
            ys.push(v);
            series.push(name.clone());
        }
    }

    let ds = Dataset::new()
        .with_column("x", xs)
        .map_err(|e| e.to_string())?
        .with_column("y", ys)
        .map_err(|e| e.to_string())?
        .with_column("series", series)
        .map_err(|e| e.to_string())?;
    let (x, y) = scaled_axes(a);
    let chart = Chart::build(ds)
        .map_err(|e| e.to_string())?
        .mark_line()
        .map_err(|e| e.to_string())?
        .encode((x, y, alt::color("series")))
        .map_err(|e| e.to_string())?;
    let xlabel = if a.x_label.is_empty() { "time" } else { &a.x_label };
    finish(chart.with_size(720, 420), a, xlabel, &a.y_label)
}

/// The x/y encodings, with log scales applied as the command requested.
fn scaled_axes(a: &PlotArgs) -> (charton::encode::x::X, charton::encode::y::Y) {
    let mut x = alt::x("x");
    let mut y = alt::y("y");
    if a.log_x {
        x = x.with_scale(Scale::Log);
    }
    if a.log_y {
        y = y.with_scale(Scale::Log);
    }
    (x, y)
}

/// Apply title/labels/ranges and render to SVG. Takes an already-sized
/// `LayeredChart` so it is shared by the line (time series) and point
/// (parametric) charts without being generic over the mark type.
fn finish(mut lc: LayeredChart, a: &PlotArgs, xlabel: &str, ylabel: &str) -> Result<String, String> {
    if !a.title.is_empty() {
        lc = lc.with_title(a.title.clone());
    }
    if !xlabel.is_empty() {
        lc = lc.with_x_label(xlabel.to_owned());
    }
    if !ylabel.is_empty() {
        lc = lc.with_y_label(ylabel.to_owned());
    }
    // Honour the explicit axis ranges unless the command asked to auto-scale.
    if !a.auto_scale {
        lc = lc.with_x_domain(a.x1, a.x2).with_y_domain(a.y1, a.y2);
    }
    lc.to_svg().map_err(|e| e.to_string())
}

/// Read full trajectories for `vars` (variable-major) from the result file as
/// plain `f64` columns.
fn read_columns(filename: &ArcStr, vars: &[&str]) -> Result<Vec<Vec<f64>>, String> {
    let mut lst: Arc<List<ArcStr>> = metamodelica::nil();
    for v in vars.iter().rev() {
        lst = metamodelica::cons(ArcStr::from(*v), lst);
    }
    let dataset = SimulationResults::readDataset(filename.clone(), lst, 0).map_err(|e| e.to_string())?;
    let Values::Value::ARRAY { valueLst, .. } = dataset.as_ref() else {
        return Err("readDataset did not return an array".into());
    };
    let mut cols = Vec::new();
    for row in valueLst.as_ref() {
        cols.push(real_vec(row)?);
    }
    if cols.len() != vars.len() {
        return Err("readDataset returned the wrong number of columns".into());
    }
    Ok(cols)
}

/// Extract a `Vec<f64>` from a `Values.ARRAY` of reals/integers.
fn real_vec(v: &Values::Value) -> Result<Vec<f64>, String> {
    let Values::Value::ARRAY { valueLst, .. } = v else {
        return Err("expected an array of values".into());
    };
    let mut out = Vec::new();
    for x in valueLst.as_ref() {
        match x.as_ref() {
            Values::Value::REAL { real } => out.push(real.0),
            Values::Value::INTEGER { integer } => out.push(*integer as f64),
            _ => return Err("expected a numeric value".into()),
        }
    }
    Ok(out)
}

fn list_to_vec(l: &Arc<List<ArcStr>>) -> Vec<ArcStr> {
    let mut out = Vec::new();
    for x in l.as_ref() {
        out.push(x.clone());
    }
    out
}

/// Append raw HTML to the page's `#log` element and scroll it into view. A no-op
/// when there is no DOM (e.g. the node-host wasm build).
fn insert_html(html: &str) {
    let Some(win) = web_sys::window() else { return };
    let Some(doc) = win.document() else { return };
    let Ok(Some(log)) = doc.query_selector("#log") else { return };
    let Ok(div) = doc.create_element("div") else { return };
    div.set_inner_html(html);
    let _ = log.append_child(&div);
    log.set_scroll_top(log.scroll_height());
}

/// Minimal HTML-text escaping for error messages.
fn escape(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;")
}
