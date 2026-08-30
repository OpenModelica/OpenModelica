//! `-l=<t>`: linearize the model around the point the run stopped at, C's
//! `linearization/linearize.cpp`.
//!
//! `der(x) = A x + B u`, `y = C x + D u`, plus `z = Cz x + Dz u` under
//! `-l_datarec`. The matrices come from the symbolic `linearJac*` exports or from
//! C's scaled forward difference quotients, and are rendered into the
//! [`LinInfo::frame`] the code generator baked the dump language into. The file is
//! handed back for whichever entry point owns the file system.

use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec;
use alloc::vec::Vec;

use crate::driver::{Result, SimEngine, format_g, read_f64, write_f64, write_i32};
use crate::{LinInfo, LinLanguage, LinVar, REAL_OFF, SimMeta};

/// The linearized model, for the caller to write where its file system is.
#[derive(Clone, Debug, PartialEq)]
pub struct LinFile {
    /// `linearized_model` plus the language's extension.
    pub name: String,
    pub content: String,
}


/// C's `numericalDifferentiationDeltaXlinearize` default.
fn default_delta_x() -> f64 {
    libm::sqrt(f64::EPSILON * 2e1)
}

/// The four symbolic matrices, in `MODEL_FNS`/[`LinInfo::jac_rows`] order.
const JAC_FNS: [&str; 4] = ["linearJacA", "linearJacB", "linearJacC", "linearJacD"];

/// `SimData` offset of matrix `k`: one region, `A|B|C|D`, each column-major.
fn jac_off(lin: &LinInfo, layout: &crate::Layout, k: usize) -> u32 {
    let mut off = layout.linz_off;
    for j in 0..k {
        off += lin.jac_rows[j] * lin.jac_cols[j] * 8;
    }
    off
}

fn read_lin_var(e: &dyn SimEngine, sim_data: u32, v: &LinVar) -> Result<f64> {
    let raw = read_f64(e, sim_data + v.off)?;
    Ok(v.negate.apply_f64(raw))
}

fn write_lin_var(e: &mut dyn SimEngine, sim_data: u32, v: &LinVar, value: f64) -> Result<()> {
    write_f64(e, sim_data + v.off, v.negate.apply_f64(value))
}

/// C's `functionODE_residual`.
fn ode_residual(
    e: &mut dyn SimEngine,
    model: &SimMeta,
    lin: &LinInfo,
    sim_data: u32,
    u: &[f64],
    dx: &mut [f64],
    dy: &mut [f64],
    dz: Option<&mut [f64]>,
) -> Result<()> {
    let layout = &model.layout;
    for (i, v) in lin.input_vars.iter().enumerate() {
        write_lin_var(e, sim_data, v, u[i])?;
    }
    // A wasm model's slots are its variables, so the write above is the whole
    // assignment; C copies `simulationInfo->inputVars` across with these two.
    e.call1_if_present("functionInputVars", sim_data)?;
    e.call1("functionODE", sim_data)?;
    e.call1("functionAlgebraics", sim_data)?;
    e.call1_if_present("functionOutputVars", sim_data)?;
    for (i, slot) in dx.iter_mut().enumerate() {
        *slot = read_f64(e, sim_data + REAL_OFF + (layout.n_states + i as u32) * 8)?;
    }
    for (i, slot) in dy.iter_mut().enumerate() {
        *slot = read_lin_var(e, sim_data, &lin.output_vars[i])?;
    }
    if let Some(dz) = dz {
        for (i, slot) in dz.iter_mut().enumerate() {
            *slot = read_f64(e, sim_data + REAL_OFF + (2 * layout.n_states + i as u32) * 8)?;
        }
    }
    Ok(())
}

fn read_states(e: &dyn SimEngine, sim_data: u32, n: u32) -> Result<Vec<f64>> {
    (0..n).map(|i| read_f64(e, sim_data + REAL_OFF + i * 8)).collect()
}

/// C's `functionJacAC_num`: perturb each state, difference `A`, `C` and `Cz`.
#[allow(clippy::too_many_arguments)]
fn jac_ac_num(
    e: &mut dyn SimEngine,
    model: &SimMeta,
    lin: &LinInfo,
    sim_data: u32,
    delta_h: f64,
    u: &[f64],
    a: &mut [f64],
    c: &mut [f64],
    cz: Option<&mut [f64]>,
) -> Result<()> {
    let layout = &model.layout;
    let (n_x, n_y, n_z) = (layout.n_states as usize, lin.output_vars.len(), layout.n_real_alg as usize);
    let do_z = cz.is_some();
    let (mut x0, mut x1) = (vec![0.0; n_x], vec![0.0; n_x]);
    let (mut y0, mut y1) = (vec![0.0; n_y], vec![0.0; n_y]);
    let (mut z0, mut z1) = (vec![0.0; n_z], vec![0.0; n_z]);
    let mut cz = cz;

    ode_residual(e, model, lin, sim_data, u, &mut x0, &mut y0, do_z.then_some(&mut z0[..]))?;
    let mut scaling = Vec::with_capacity(n_x);
    for i in 0..n_x as u32 {
        let nominal = read_f64(e, sim_data + layout.state_nom_off + i * 8)?;
        let x = read_f64(e, sim_data + REAL_OFF + i * 8)?;
        scaling.push(libm::fmax(nominal, libm::fabs(x)));
    }
    for i in 0..n_x {
        let addr = sim_data + REAL_OFF + (i as u32) * 8;
        let xsave = read_f64(e, addr)?;
        let mut delta_hh = delta_h * (libm::fabs(xsave) + 1.0);
        if xsave + delta_hh >= read_f64(e, sim_data + layout.state_max_off + (i as u32) * 8)? {
            delta_hh = -delta_hh;
        }
        write_f64(e, addr, xsave + delta_hh / scaling[i])?;
        delta_hh = 1.0 / delta_hh * scaling[i];

        ode_residual(e, model, lin, sim_data, u, &mut x1, &mut y1, do_z.then_some(&mut z1[..]))?;

        for j in 0..n_x {
            a[i * n_x + j] = (x1[j] - x0[j]) * delta_hh;
        }
        for j in 0..n_y {
            c[i * n_y + j] = (y1[j] - y0[j]) * delta_hh;
        }
        if let Some(cz) = cz.as_deref_mut() {
            for j in 0..n_z {
                cz[i * n_z + j] = (z1[j] - z0[j]) * delta_hh;
            }
        }
        write_f64(e, addr, xsave)?;
    }
    Ok(())
}

/// C's `functionJacBD_num`: the same difference quotients over the inputs.
#[allow(clippy::too_many_arguments)]
fn jac_bd_num(
    e: &mut dyn SimEngine,
    model: &SimMeta,
    lin: &LinInfo,
    sim_data: u32,
    delta_h: f64,
    u: &[f64],
    b: &mut [f64],
    d: &mut [f64],
    dz: Option<&mut [f64]>,
) -> Result<()> {
    let layout = &model.layout;
    let (n_x, n_u, n_y, n_z) =
        (layout.n_states as usize, u.len(), lin.output_vars.len(), layout.n_real_alg as usize);
    let do_z = dz.is_some();
    let (mut x0, mut x1) = (vec![0.0; n_x], vec![0.0; n_x]);
    let (mut y0, mut y1) = (vec![0.0; n_y], vec![0.0; n_y]);
    let (mut z0, mut z1) = (vec![0.0; n_z], vec![0.0; n_z]);
    let mut dz = dz;
    let mut u = u.to_vec();

    ode_residual(e, model, lin, sim_data, &u, &mut x0, &mut y0, do_z.then_some(&mut z0[..]))?;
    for i in 0..n_u {
        let usave = u[i];
        let mut delta_hh = delta_h * (libm::fabs(usave) + 1.0);
        u[i] = usave + delta_hh;
        delta_hh = 1.0 / delta_hh;

        ode_residual(e, model, lin, sim_data, &u, &mut x1, &mut y1, do_z.then_some(&mut z1[..]))?;

        for j in 0..n_x {
            b[i * n_x + j] = (x1[j] - x0[j]) * delta_hh;
        }
        for j in 0..n_y {
            d[i * n_y + j] = (y1[j] - y0[j]) * delta_hh;
        }
        if let Some(dz) = dz.as_deref_mut() {
            for j in 0..n_z {
                dz[i * n_z + j] = (z1[j] - z0[j]) * delta_hh;
            }
        }
        u[i] = usave;
    }
    Ok(())
}

/// C's `array2string`: row-major text of a column-major `row × col` matrix.
fn array2string(a: &[f64], row: usize, col: usize, lang: LinLanguage) -> String {
    let sep = if lang == LinLanguage::Julia { " " } else { ", " };
    let mut out = String::new();
    for i in 0..row {
        let mut k = i;
        for _ in 0..col.saturating_sub(1) {
            out.push_str(&format_g(a[k], 16));
            out.push_str(sep);
            k += row;
        }
        if col > 0 {
            out.push_str(&format_g(a[k], 16));
        }
        if i + 1 != row && col != 0 {
            out.push_str(";\n\t");
        }
    }
    out
}

/// C's `array2PythonString`: a list of row lists.
fn array2python(a: &[f64], row: usize, col: usize) -> String {
    if row == 0 || col == 0 {
        return "[]\n".to_string();
    }
    let mut out = String::from("[");
    for i in 0..row {
        let mut k = i;
        out.push('[');
        for _ in 0..col - 1 {
            out.push_str(&format_g(a[k], 16));
            out.push_str(", ");
            k += row;
        }
        out.push_str(&format_g(a[k], 16));
        if i + 1 != row {
            out.push_str("],\n\t");
        }
    }
    out.push_str("]]\n");
    out
}

/// The frame's `x0`/`u0`/`z0`: `{}` is not valid Modelica, hence `zeros(0)`.
fn vector_literal(v: &[f64], lang: LinLanguage) -> String {
    let body = || array2string(v, 1, v.len(), lang);
    match (v.is_empty(), lang) {
        (true, LinLanguage::Python) => "[0]".to_string(),
        (true, _) => "zeros(0)".to_string(),
        (false, LinLanguage::Julia | LinLanguage::Python) => format!("[{}]", body()),
        (false, _) => format!("{{{}}}", body()),
    }
}

/// Substitute the frame's `printf` conversions: `%s` the next matrix/vector text,
/// `%g` the stop time.
fn fill_frame(frame: &str, args: &[String], stop_time: f64) -> String {
    let mut out = String::with_capacity(frame.len());
    let mut next = 0;
    let mut it = frame.chars();
    while let Some(c) = it.next() {
        if c != '%' {
            out.push(c);
            continue;
        }
        match it.next() {
            Some('s') => {
                if let Some(a) = args.get(next) {
                    out.push_str(a);
                }
                next += 1;
            }
            Some('g') => out.push_str(&format_g(stop_time, 6)),
            Some('%') => out.push('%'),
            Some(other) => {
                out.push('%');
                out.push(other);
            }
            None => out.push('%'),
        }
    }
    out
}

/// Run `linearJac<k>` and read the matrix it left in the linearization region.
fn read_symbolic(
    e: &mut dyn SimEngine,
    model: &SimMeta,
    lin: &LinInfo,
    sim_data: u32,
    k: usize,
    out: &mut [f64],
) -> Result<()> {
    e.call1(JAC_FNS[k], sim_data)?;
    let base = sim_data + jac_off(lin, &model.layout, k);
    for (i, slot) in out.iter_mut().enumerate() {
        *slot = read_f64(e, base + (i as u32) * 8)?;
    }
    Ok(())
}

/// C's report once the file has been written; an empty frame is the one the
/// template emits when linearization was disabled. `(messages, is_error)`.
pub fn write_notice(lin: &LinInfo, file: &LinFile, path: &str) -> (Vec<String>, bool) {
    if !file.content.is_empty() {
        return (created_notice(lin, path), false);
    }
    let mut msgs = Vec::new();
    if !lin.disabled_reason.is_empty() {
        msgs.push(lin.disabled_reason.clone());
    }
    msgs.push("Linear model could not be created.".to_string());
    (msgs, true)
}

/// C's `LOG_STDOUT` notice, as plain messages: the callers own their log.
pub fn created_notice(lin: &LinInfo, path: &str) -> Vec<String> {
    if lin.run_testsuite {
        return vec!["Linear model is created.".to_string()];
    }
    vec![
        format!("Linear model is created at {path}"),
        "The output format can be changed with the command line option --linearizationDumpLanguage."
            .to_string(),
        "The options are: --linearizationDumpLanguage=none, modelica, matlab, julia, python."
            .to_string(),
        "In OMEdit Simulation Setup->Linearize->Target language for linearized model.".to_string(),
    ]
}

/// C's `linearize`, once the run reached the linearization point. `None` when
/// `-l` was not asked for.
pub fn linearize(e: &mut dyn SimEngine, model: &SimMeta, sim_data: u32) -> Result<Option<LinFile>> {
    let (asked, datarec, delta_h) = crate::simflags::with_flags(|f| {
        (f.linearize.is_some(), f.linearize_datarec, f.delta_x_linearize.unwrap_or_else(default_delta_x))
    });
    if !asked {
        return Ok(None);
    }
    let Some(lin) = &model.lin else {
        return Err("linearization is not available for this model");
    };
    let layout = &model.layout;
    let (n_x, n_u, n_y, n_z) =
        (layout.n_states as usize, lin.input_vars.len(), lin.output_vars.len(), layout.n_real_alg as usize);

    // C linearizes with `discreteCall == 0`: relations and `mathEventsValuePre`
    // stay held, so a perturbed state cannot step a discrete value.
    write_i32(e, sim_data + layout.rel_fresh_off, 0)?;

    let mut a = vec![0.0; n_x * n_x];
    let mut b = vec![0.0; n_x * n_u];
    let mut c = vec![0.0; n_y * n_x];
    let mut d = vec![0.0; n_y * n_u];
    let mut cz = vec![0.0; n_z * n_x];
    let mut dz = vec![0.0; n_z * n_u];

    let x0 = read_states(e, sim_data, layout.n_states)?;
    let u0: Vec<f64> =
        lin.input_vars.iter().map(|v| read_lin_var(e, sim_data, v)).collect::<Result<_>>()?;
    // C reads z0 before anything perturbs the model.
    let z0: Vec<f64> = if datarec {
        (0..n_z as u32)
            .map(|i| read_f64(e, sim_data + REAL_OFF + (2 * layout.n_states + i) * 8))
            .collect::<Result<_>>()?
    } else {
        Vec::new()
    };

    // `Cz`/`Dz` are only ever numeric. C skips the numeric pass as soon as `A` is
    // symbolic — it generates all four together, so the rest are too; here a single
    // matrix can fail to lower, and one that did is differenced rather than left at
    // C's `calloc` zero.
    if datarec || lin.sym_mask != 0b1111 {
        jac_ac_num(e, model, lin, sim_data, delta_h, &u0, &mut a, &mut c, datarec.then_some(&mut cz[..]))?;
        jac_bd_num(e, model, lin, sim_data, delta_h, &u0, &mut b, &mut d, datarec.then_some(&mut dz[..]))?;
    }
    for (k, m) in [&mut a, &mut b, &mut c, &mut d].into_iter().enumerate() {
        if lin.sym_mask & (1 << k) != 0 {
            read_symbolic(e, model, lin, sim_data, k, m)?;
        }
    }

    // C writes the (empty) file either way and reports it afterwards.
    let from_model = e.lin_frame(datarec);
    let frame = match &from_model {
        Some(f) => f,
        None => if datarec { &lin.frame_datarec } else { &lin.frame },
    };
    let lang = lin.language;
    if frame.is_empty() {
        return Ok(Some(LinFile { name: format!("linearized_model{}", lang.ext()), content: String::new() }));
    }

    let mat = |m: &[f64], row: usize, col: usize| match lang {
        LinLanguage::Python => array2python(m, row, col),
        _ => array2string(m, row, col, lang),
    };
    let mut args = vec![vector_literal(&x0, lang), vector_literal(&u0, lang)];
    if datarec {
        args.push(vector_literal(&z0, lang));
    }
    args.push(mat(&a, n_x, n_x));
    args.push(mat(&b, n_x, n_u));
    args.push(mat(&c, n_y, n_x));
    args.push(mat(&d, n_y, n_u));
    if datarec {
        args.push(mat(&cz, n_z, n_x));
        args.push(mat(&dz, n_z, n_u));
    }
    Ok(Some(LinFile {
        name: format!("linearized_model{}", lang.ext()),
        content: fill_frame(frame, &args, model.stop_time),
    }))
}
