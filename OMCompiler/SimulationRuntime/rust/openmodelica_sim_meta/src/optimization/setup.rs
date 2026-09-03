//! The port of `optimization/DataManagement/`: picking the problem out of the
//! model (`MoveData.c`), the derivative/Hessian structure (`DerStructure.c`), the
//! initial guess (`InitialGuess.c`) and writing the solution back (`res2file`).

use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec;
use alloc::vec::Vec;

use super::model::Model;
use super::run::{flags_bool, zeros, BoundsData, Dim, Ipop, OptData, Rk, Structure, Time};
use crate::driver::{self, format_g, Result, SimEngine};
use crate::{omclog, OptInfo, OptJac, SimMeta};

/// Radau IIA collocation points for `np = 3` (C's `c[]`), and the trivial one for
/// `np = 1`.
const C3: [f64; 3] = [
    0.155_051_025_721_682_19,
    0.644_948_974_278_317_8,
    1.000_00,
];

/// C's `pickUpModelData`.
pub(crate) fn pick_up_model_data(
    e: &mut (dyn SimEngine + 'static),
    meta: &SimMeta,
    sim_data: u32,
    opt: OptInfo,
) -> Result<OptData> {
    let mut model = Model::new(e, sim_data, &meta.layout, opt.inputs.len());
    let names = opt.real_names.clone();
    let mut data = OptData {
        dim: Dim::default(),
        time: Time::default(),
        bounds: BoundsData::default(),
        rk: Rk::default(),
        s: Structure::default(),
        ipop: Ipop::default(),
        v: Vec::new(),
        v0: Vec::new(),
        sv0: Vec::new(),
        snapshot: Vec::new(),
        j: Vec::new(),
        tmp_j: Vec::new(),
        jf: Vec::new(),
        tmp_jf: Vec::new(),
        h: Vec::new(),
        hl: Vec::new(),
        hm: Vec::new(),
        hcf: Vec::new(),
        old_h: Vec::new(),
        iter_: 0,
        index: 0,
        model: core::mem::replace(&mut model, Model::new(e, sim_data, &meta.layout, 0)),
        opt,
        names,
        rows: Vec::new(),
        input_csv: String::new(),
        out: None,
        meta: meta.clone(),
        tol: meta.tolerance,
        start_time: meta.start_time,
        stop_time: meta.stop_time,
        num_steps: meta.n_intervals,
    };
    // The model handle above was swapped out to satisfy the borrow checker; use the
    // real one (same engine and layout, sized for the inputs).
    data.model = Model::new(e, sim_data, &meta.layout, data.opt.inputs.len());

    pick_up_dim(&mut data);
    // C's `check_nominal` reads the initialized state (`localData[1]->realVars`) for
    // its heuristic, so the initial values are latched before the bounds.
    data.v0 = zeros(data.dim.n_real);
    data.model.read_reals(&mut data.v0);
    pick_up_bounds(&mut data);
    pick_up_time(&mut data);
    set_rk_coeff(&mut data);
    calculated_scaling_helper(&mut data);
    omclog::close(omclog::SOLVER);

    let (nsi, np, n_real) = (data.dim.nsi, data.dim.np, data.dim.n_real);
    data.v = zeros(nsi * np * n_real);
    // C copies `localData[0]->realVars` here, after the bounds; `-stateFile` may
    // still change it.
    data.model.read_reals(&mut data.v0);
    pick_up_states(&mut data);

    data.sv0 = (0..data.dim.nx).map(|i| data.v0[i] * data.bounds.scal_f[i]).collect();
    data.snapshot = read_snapshot(&mut data);
    print_some_model_infos(&mut data);
    if let Some(err) = data.model.err {
        return Err(err);
    }
    Ok(data)
}

/// The discrete state `copy_initial_values` restores at every collocation point:
/// C's integer/boolean variables, their `pre` values, the real `pre` values and the
/// three relation arrays.
fn snapshot_regions(data: &OptData) -> Vec<(u32, usize)> {
    let l = &data.model.layout;
    let n_real = data.dim.n_real;
    vec![
        (l.int_off, (l.n_int_alg() * 4) as usize),
        (l.bool_off, (l.n_bool_alg() * 4) as usize),
        (l.pre_real_off, n_real * 8),
        (l.pre_int_off, (l.n_int_alg() * 4) as usize),
        (l.pre_bool_off, (l.n_bool_alg() * 4) as usize),
        (l.relations_off, (l.n_rel * 4) as usize),
        (l.relations_pre_off, (l.n_rel * 4) as usize),
        (l.stored_rel_off, (l.n_rel * 4) as usize),
    ]
}

fn read_snapshot(data: &mut OptData) -> Vec<u8> {
    let regions = snapshot_regions(data);
    let total: usize = regions.iter().map(|r| r.1).sum();
    let mut out = vec![0u8; total];
    let mut p = 0;
    for (off, len) in regions {
        let end = p + len;
        data.model.read_region(off, &mut out[p..end]);
        p = end;
    }
    out
}

/// C's `copy_initial_values`: the initial real variables and the whole discrete
/// state back into the model.
pub(crate) fn copy_initial_values(data: &mut OptData) {
    let v0 = core::mem::take(&mut data.v0);
    data.model.write_reals(&v0);
    data.v0 = v0;
    let snap = core::mem::take(&mut data.snapshot);
    let mut p = 0;
    for (off, len) in snapshot_regions(data) {
        data.model.write_region(off, &snap[p..p + len]);
        p += len;
    }
    data.snapshot = snap;
}

/// C's `pickUpDim`.
fn pick_up_dim(data: &mut OptData) {
    let np = match crate::simflags::with_flags(|f| f.optimizer_np) {
        Some(n) if n == 1 || n == 3 => n as usize,
        Some(n) => {
            omclog::warning!(
                omclog::STDOUT,
                false,
                "FLAG_OPTIZER_NP is {n}. Currently optimizer support only 1 and 3.\n\
                 FLAG_OPTIZER_NP set of 3",
            );
            3
        }
        None => 3,
    };
    let l = data.model.layout;
    let opt = &data.opt;
    let d = &mut data.dim;
    d.np = np;
    d.nx = l.n_states as usize;
    d.nu = opt.inputs.len();
    d.nv = d.nx + d.nu;
    d.nc = opt.n_con as usize;
    d.ncf = opt.n_final_con as usize;
    d.n_j = d.nx + d.nc;
    d.n_j2 = d.n_j + 2;
    d.n_real = (2 * l.n_states + l.n_real_alg) as usize;
    d.index_con = d.n_real - (d.nc + d.ncf);
    d.index_conf = d.index_con + d.nc;

    // C's `getTimeGrid`: a model-supplied grid wins over `numberOfIntervals`, and
    // `-optimizerTimeGrid` over both.
    data.time.model_grid = !opt.tgrid.is_empty();
    d.nsi = if data.time.model_grid {
        opt.tgrid.len() - 1
    } else {
        data.num_steps as usize
    };
    if data.time.model_grid {
        let offs = data.opt.tgrid.clone();
        data.time.tt = offs.iter().map(|&off| data.model.read_f64_at(off)).collect();
    }
    if let Some(file) = crate::simflags::with_flags(|f| f.optimizer_tgrid.clone()) {
        let (nsi, ok) = grid_file_rows(&file, data.dim.nsi);
        data.dim.nsi = nsi;
        data.dim.ex_time_grid = ok;
    }
    let d = &mut data.dim;
    d.nt = d.nsi * d.np;
    d.nv_total = d.nt * d.nv;
    d.n_res = d.nt * d.n_j + d.ncf;
    assert!(d.nt > 0);
}

/// C's `getNsi`: one interval per line of the grid file, minus the first (`t0`).
fn grid_file_rows(file: &str, nsi: usize) -> (usize, bool) {
    match read_grid_file(file) {
        Err(e) => {
            omclog::warning(omclog::STDOUT, false, &e);
            (nsi, false)
        }
        Ok(times) if times.len() < 2 => {
            omclog::warning!(omclog::STDOUT, false, "time grid file: {file} is empty");
            (nsi, false)
        }
        Ok(times) => (times.len() - 1, true),
    }
}

/// The times in a `-optimizerTimeGrid` file, one per line.
fn read_grid_file(file: &str) -> core::result::Result<Vec<f64>, String> {
    let text = crate::extinput::read_file(file)
        .ok_or_else(|| format!("OMC can't find the file {file}."))?;
    Ok(text.split_whitespace().filter_map(|w| w.parse::<f64>().ok()).collect())
}

/// C's `pickUpTime`: the collocation grid.
fn pick_up_time(data: &mut OptData) {
    let (nsi, np) = (data.dim.nsi, data.dim.np);
    let np1 = np - 1;
    let c: Vec<f64> = match np {
        1 => vec![1.0],
        3 => C3.to_vec(),
        n => {
            omclog::error!(omclog::STDOUT, false, "Not support np = {n}");
            vec![1.0]
        }
    };
    let t = &mut data.time;
    t.t0 = data.start_time.max(data.bounds.pre_sim);
    t.tf = data.stop_time;
    t.dt = zeros(nsi + 1);
    t.dt[0] = (t.tf - t.t0) / nsi as f64;
    t.t = vec![zeros(np); nsi];
    if nsi < 1 {
        omclog::error!(omclog::STDOUT, false, "Not support numberOfIntervals = {nsi} < 1");
    }
    let dc: Vec<f64> = c.iter().map(|ck| ck * t.dt[0]).collect();
    for k in 0..np {
        t.t[0][k] = t.t0 + dc[k];
    }
    for i in 1..nsi {
        t.dt[i] = t.dt[i - 1];
        for k in 0..np {
            t.t[i][k] = t.t[i - 1][np1] + dc[k];
        }
    }
    t.t[nsi - 1][np1] = t.tf;
    if nsi > 1 {
        let i = nsi - 1;
        t.dt[i] = t.t[i][np1] - t.t[i - 1][np1];
        for k in 0..np {
            t.t[i][k] = t.t[i - 1][np1] + c[k] * t.dt[i];
        }
    } else {
        t.dt[1] = t.dt[0];
    }

    if let Some(file) = crate::simflags::with_flags(|f| f.optimizer_tgrid.clone()) {
        overwrite_time_grid_file(data, &file, &c);
    }
    if data.time.model_grid {
        overwrite_time_grid_model(data, &c);
    }
}

/// C's `overwriteTimeGridFile`: the file lists the interval end points.
fn overwrite_time_grid_file(data: &mut OptData, file: &str, c: &[f64]) {
    let times = match read_grid_file(file) {
        Ok(t) if t.len() >= 2 => t,
        _ => return,
    };
    let (nsi, np) = (data.dim.nsi, data.dim.np);
    let np1 = np - 1;
    let t = &mut data.time;
    t.t0 = times[0];
    t.t[0][np1] = times[1];
    t.dt[0] = t.t[0][np1] - t.t0;
    if t.dt[0] <= 0.0 {
        omclog::warning(omclog::STDOUT, false, "read time grid from file fail!");
        omclog::warning!(
            omclog::STDOUT,
            false,
            "line 0: {} <= {}",
            format_g(t.t[0][np1], 6),
            format_g(t.t0, 6),
        );
        return;
    }
    for k in 0..np {
        t.t[0][k] = t.t0 + c[k] * t.dt[0];
    }
    for i in 1..nsi {
        let Some(&end) = times.get(i + 1) else { break };
        t.t[i][np1] = end;
        t.dt[i] = t.t[i][np1] - t.t[i - 1][np1];
        for k in 0..np {
            t.t[i][k] = t.t[i - 1][np1] + c[k] * t.dt[i];
        }
        if t.dt[i] <= 0.0 {
            omclog::warning(omclog::STDOUT, false, "read time grid");
            omclog::warning!(
                omclog::STDOUT,
                false,
                "line {i}/{nsi}: {} <= {}",
                format_g(t.t[i][np1], 6),
                format_g(t.t[i - 1][np1], 6),
            );
            omclog::warning(omclog::STDOUT, false, "failed!");
            return;
        }
    }
    t.tf = t.t[nsi - 1][np1];
}

/// C's `overwriteTimeGridModel`: the `$OPT_TGRID` parameters, sorted.
fn overwrite_time_grid_model(data: &mut OptData, c: &[f64]) {
    let (nsi, np) = (data.dim.nsi, data.dim.np);
    let t = &mut data.time;
    t.t0 = t.tt[0];
    t.tf = t.tt[nsi];
    t.tt.sort_by(|a, b| a.partial_cmp(b).unwrap_or(core::cmp::Ordering::Equal));
    for i in 0..nsi {
        t.dt[i] = t.tt[i + 1] - t.tt[i];
        for k in 0..np {
            t.t[i][k] = t.tt[i] + c[k] * t.dt[i];
        }
    }
}

/// C's `pickUpBounds`, including `pickUpBoundsForInputsInOptimization`: the
/// per-variable bounds, the nominal heuristic and the scaled NLP bounds.
fn pick_up_bounds(data: &mut OptData) {
    let (nx, nu, nv) = (data.dim.nx, data.dim.nu, data.dim.nv);
    let attrs = data.model.layout;
    let inputs = data.opt.inputs.clone();

    data.bounds.vnom = zeros(nv);
    data.bounds.scal_f = zeros(nv);
    data.bounds.vmin = zeros(nv);
    data.bounds.vmax = zeros(nv);
    data.bounds.u0 = zeros(nu);

    // C's `startTimeOpt`: `startTime - 1` unless the model set the class attribute,
    // in which case a pre-simulation runs from `startTime` to it.
    data.bounds.pre_sim = match data.opt.start_time_opt {
        Some(off) => data.model.read_f64_at(off),
        None => data.start_time - 1.0,
    };

    // Inputs first (C fills `umin`/`umax`/`unom`/`u0` through the callback), then the
    // states, then the input nominals — the order matters because `check_nominal`
    // reads `u0` clipped to its bounds.
    let mut use_nominal_input = vec![false; nu];
    for (k, &idx) in inputs.iter().enumerate() {
        let i = idx as usize;
        data.bounds.vmin[nx + k] = data.model.read_f64_at(attrs.opt_min_off + (i as u32) * 8);
        data.bounds.vmax[nx + k] = data.model.read_f64_at(attrs.opt_max_off + (i as u32) * 8);
        data.bounds.vnom[nx + k] = data.model.read_f64_at(attrs.opt_nom_off + (i as u32) * 8);
        data.bounds.u0[k] = data.model.read_f64_at(attrs.real_start_off(i as u32));
        use_nominal_input[k] = data.model.read_i32_at(attrs.opt_use_nom_off + (i as u32) * 4) != 0;
    }

    for i in 0..nx {
        let min = data.model.read_f64_at(attrs.opt_min_off + (i as u32) * 8);
        let max = data.model.read_f64_at(attrs.opt_max_off + (i as u32) * 8);
        let nominal = data.model.read_f64_at(attrs.opt_nom_off + (i as u32) * 8);
        let set = data.model.read_i32_at(attrs.opt_use_nom_off + (i as u32) * 4) != 0;
        let x0 = data.v0.get(i).copied().unwrap_or(0.0);
        data.bounds.vnom[i] = check_nominal(min, max, nominal, set, x0);
        // C writes the heuristic nominal back into the model's attribute, so the
        // initial guess's DASSL tolerances are scaled by it.
        let nom = data.bounds.vnom[i];
        data.model.write_f64_at(attrs.opt_nom_off + (i as u32) * 8, nom);
        data.model.write_f64_at(data.model.layout.state_nom_off + (i as u32) * 8, nom);
        data.bounds.scal_f[i] = 1.0 / nom;
        data.bounds.vmin[i] = min * data.bounds.scal_f[i];
        data.bounds.vmax[i] = max * data.bounds.scal_f[i];
    }

    for k in 0..nu {
        let i = nx + k;
        let (umin, umax) = (data.bounds.vmin[i], data.bounds.vmax[i]);
        data.bounds.u0[k] = data.bounds.u0[k].max(umin).min(umax);
        let nom = check_nominal(
            umin,
            umax,
            data.bounds.vnom[i],
            use_nominal_input[k],
            libm::fabs(data.bounds.u0[k]),
        );
        data.bounds.vnom[i] = nom;
        data.bounds.scal_f[i] = 1.0 / nom;
        data.bounds.vmin[i] *= data.bounds.scal_f[i];
        data.bounds.vmax[i] *= data.bounds.scal_f[i];
    }

    let nv_total = data.dim.nv_total;
    data.bounds.v_min_all = Vec::with_capacity(nv_total);
    data.bounds.v_max_all = Vec::with_capacity(nv_total);
    for _ in 0..data.dim.nt {
        data.bounds.v_min_all.extend_from_slice(&data.bounds.vmin);
        data.bounds.v_max_all.extend_from_slice(&data.bounds.vmax);
    }
}

/// C's `check_nominal`: the heuristic when a variable has no `nominal` of its own.
fn check_nominal(min: f64, max: f64, nominal: f64, set: bool, x0: f64) -> f64 {
    if set {
        return libm::fabs(nominal).max(1e-16);
    }
    let (amax, amin) = (libm::fabs(max), libm::fabs(min));
    let mut nom = amax.max(amin);
    if nom > 1e12 {
        let tmp = amax.min(amin);
        let ax0 = libm::fabs(x0);
        nom = if tmp < 1e12 { tmp.max(ax0) } else { 1.0 + ax0 };
    }
    nom.max(1e-16)
}

/// C's `calculatedScalingHelper`.
fn calculated_scaling_helper(data: &mut OptData) {
    let (nsi, np, nx) = (data.dim.nsi, data.dim.np, data.dim.nx);
    data.bounds.scaldt = (0..nsi)
        .map(|i| (0..nx).map(|j| data.bounds.scal_f[j] * data.time.dt[i]).collect())
        .collect();
    data.bounds.scalb = (0..nsi)
        .map(|i| (0..np).map(|j| data.time.dt[i] * data.rk.b[j]).collect())
        .collect();
}

/// C's `setRKCoeff`: the inverse Radau IIA coefficients the constraints use.
fn set_rk_coeff(data: &mut OptData) {
    let rk = &mut data.rk;
    if data.dim.np == 3 {
        rk.a[0] = [
            4.139_387_691_339_813_7,
            3.224_744_871_391_589,
            1.167_840_084_690_405_5,
            0.253_197_264_742_180_8,
            0.0,
        ];
        rk.a[1] = [
            1.739_387_691_339_813_8,
            3.567_840_084_690_405_4,
            0.775_255_128_608_411,
            1.053_197_264_742_180_8,
            0.0,
        ];
        rk.a[2] = [
            3.0,
            5.531_972_647_421_808,
            7.531_972_647_421_808,
            5.0,
            0.0,
        ];
        rk.b[0] = 0.376_403_062_700_467_3;
        rk.b[1] = 0.512_485_826_188_421_6;
        rk.b[2] = 1.0 - (rk.b[0] + rk.b[1]);
    } else if data.dim.np == 1 {
        rk.a[0][0] = 1.0;
        rk.b[0] = rk.a[0][0];
    }
}

/// C's `printSomeModelInfos`: the "Optimizer Variables" block, which the testsuite
/// compares verbatim.
fn print_some_model_infos(data: &mut OptData) {
    let (nx, nv) = (data.dim.nx, data.dim.nv);
    let attrs = data.model.layout;
    let mut out = String::from("\nOptimizer Variables");
    out.push_str("\n========================================================");
    for i in 0..nx {
        let xmin = data.bounds.vmin[i];
        let xmax = data.bounds.vmax[i];
        // The unscaled attribute, as C prints `realVarsData[i].attribute.min`.
        let min = data.model.read_f64_at(attrs.opt_min_off + (i as u32) * 8);
        let max = data.model.read_f64_at(attrs.opt_max_off + (i as u32) * 8);
        let start = data.model.read_f64_at(attrs.real_start_off(i as u32));
        let min_s = if xmin > -1e20 {
            format!(", min = {}", format_g(min, 6))
        } else {
            ", min = -Inf".to_string()
        };
        let max_s = if xmax < 1e20 {
            format!(", max = {}", format_g(max, 6))
        } else {
            ", max = +Inf".to_string()
        };
        out.push_str(&format!(
            "\nState[{i}]:{}(start = {}, nominal = {}{min_s}{max_s}, init = {})",
            data.names.get(i).map(String::as_str).unwrap_or(""),
            format_g(start, 6),
            format_g(data.bounds.vnom[i], 6),
            format_g(data.v0.get(i).copied().unwrap_or(0.0), 6),
        ));
    }
    for (k, i) in (nx..nv).enumerate() {
        let unom = data.bounds.vnom[i];
        let umin = data.bounds.vmin[i];
        let umax = data.bounds.vmax[i];
        let min_s = if umin > -1e20 {
            format!(", min = {}", format_g(umin * unom, 6))
        } else {
            ", min = -Inf".to_string()
        };
        let max_s = if umax < 1e20 {
            format!(", max = {}", format_g(umax * unom, 6))
        } else {
            ", max = +Inf".to_string()
        };
        let name = data
            .opt
            .inputs
            .get(k)
            .and_then(|&idx| data.names.get(idx as usize))
            .map(String::as_str)
            .unwrap_or("");
        out.push_str(&format!(
            "\nInput[{i}]:{name}(start = {}, nominal = {}{min_s}{max_s})",
            format_g(data.bounds.u0[k], 6),
            format_g(unom, 6),
        ));
    }
    out.push_str("\n--------------------------------------------------------");
    out.push_str(&format!("\nnumber of nonlinear constraints: {}", data.dim.nc));
    out.push_str("\n========================================================\n");
    driver::log_line(omclog::STDOUT, omclog::INFO, &out);
}

/// C's `pickUpStates`: `-csvInput` overrides start values by name.
fn pick_up_states(data: &mut OptData) {
    let Some(file) = crate::simflags::with_flags(|f| f.state_file.clone()) else { return };
    let Some(text) = crate::extinput::read_file(&file) else {
        omclog::warning!(omclog::STDOUT, false, "OMC can't find the file {file}.");
        return;
    };
    if text.lines().next().is_none() {
        omclog::error!(omclog::STDOUT, false, "External input file: {file} is empty!");
        return;
    }
    let mut out = String::new();
    for (i, line) in text.lines().enumerate() {
        let mut it = line.split_whitespace();
        let (Some(name), Some(value)) = (it.next(), it.next()) else { continue };
        let Ok(start) = value.parse::<f64>() else { continue };
        match data.names.iter().position(|n| n == name) {
            Some(j) => {
                data.model.write_real(j, start);
                let slot = i.min(data.v0.len().saturating_sub(1));
                data.v0[slot] = start;
                out.push_str(&format!("\n[{i}]set {name}.start {}", format_g(start, 6)));
            }
            None => omclog::warning!(
                omclog::STDOUT,
                false,
                "it was impossible to set {name}.start {}",
                format_g(start, 6),
            ),
        }
    }
    out.push('\n');
    driver::log_line(omclog::STDOUT, omclog::INFO, &out);
    data.model.input_function(&data.opt.clone());
    data.model.update_discrete_system();
}

// ───────────────────────────── DerStructure.c ─────────────────────────────

/// C's `allocate_der_struct`: the Jacobian and Hessian patterns, and the arrays
/// sized from them.
pub(crate) fn allocate_der_struct(data: &mut OptData) -> Result<()> {
    data.dim.update_hessian = match crate::simflags::with_flags(|f| f.keep_hessian) {
        Some(n) if n >= 0 => n,
        Some(n) => {
            omclog::warning!(
                omclog::STDOUT,
                false,
                "not support {n} for keep hessian-matrix constant.",
            );
            0
        }
        None => 0,
    };

    let (nv, nsi, np) = (data.dim.nv, data.dim.nsi, data.dim.np);
    let (n_j, n_j2, ncf) = (data.dim.n_j, data.dim.n_j2, data.dim.ncf);

    // C's `matrix[1..4]` from `initialAnalyticJacobianX() == 0`; index 0 is unused.
    data.s.matrix = [
        false,
        false, // A is not used by the optimizer
        data.opt.jac_b.is_some(),
        data.opt.jac_c.is_some(),
        data.opt.jac_d.is_some(),
    ];
    data.s.j[0] = flags_bool((n_j + 1) * nv);
    data.s.j[1] = flags_bool(n_j2 * nv);
    data.s.j[2] = flags_bool(ncf * nv);

    data.s.der_index = [-1, -1, -1];
    data.s.mayer = data.opt.mayer.is_some();
    data.s.lagrange = data.opt.lagrange.is_some();
    if let Some(m) = data.opt.mayer {
        data.s.der_index[0] = m.row_c.map_or(-1, |r| r as i32);
        data.dim.index_mayer = m.index as usize;
    }
    if let Some(l) = data.opt.lagrange {
        data.s.der_index[1] = l.row_b.map_or(-1, |r| r as i32);
        data.s.der_index[2] = l.row_c.map_or(-1, |r| r as i32);
        data.dim.index_lagrange = l.index as usize;
    }

    local_jac_struct(data);
    if omclog::active(omclog::IPOPT_JAC) || omclog::active(omclog::IPOPT_HESSE) {
        print_local_jac_struct(data);
    }
    local_hessian_struct(data);
    if omclog::active(omclog::IPOPT_JAC) || omclog::active(omclog::IPOPT_HESSE) {
        print_local_hessian_struct(data);
    }
    update_local_jac_struct(data);

    data.j = zeros(nsi * np * n_j2 * nv);
    data.tmp_j = zeros(n_j2 * nv);
    data.jf = zeros(ncf * nv);
    data.tmp_jf = zeros(ncf * nv);
    data.h = zeros(n_j * nv * nv);
    data.hcf = zeros(ncf * nv * nv);
    data.hm = zeros(nv * nv);
    data.hl = zeros(nv * nv);
    if data.dim.update_hessian > 0 {
        let nhess = (nsi * np - 1) * data.dim.nh0_ + data.dim.nh1_;
        data.old_h = zeros(nhess);
    }
    data.dim.iter_update_hessian = data.dim.update_hessian - 1;
    Ok(())
}

/// C's `local_jac_struct`: turn each Jacobian's sparsity into the constraint
/// Jacobian's own pattern, and the row remapping that skips the objective rows.
fn local_jac_struct(data: &mut OptData) {
    let (nv, nx, n_j, n_j2, ncf) = (
        data.dim.nv,
        data.dim.nx,
        data.dim.n_j,
        data.dim.n_j2,
        data.dim.ncf,
    );
    data.s.jder_con = flags_bool(n_j * nv);
    data.s.grad_m = flags_bool(nv);
    data.s.grad_l = flags_bool(nv);
    data.s.index_con2 = vec![0; data.dim.nc];
    data.s.index_con3 = vec![0; data.dim.nc];

    // C loops `index = 2..4` over B, C and D, filling `J[index-2]`.
    for index in 2..5usize {
        let Some(jac) = jac_of(&data.opt, index) else { continue };
        let tmp = index - 2;
        for col in 0..jac.n_cols.min(nv as u32) as usize {
            for &row in &jac.rows_by_col[col] {
                let stride = match tmp {
                    0 => nv,
                    1 => nv,
                    _ => nv,
                };
                let idx = row as usize * stride + col;
                if let Some(slot) = data.s.j[tmp].get_mut(idx) {
                    *slot = true;
                }
            }
        }
        // The rows holding path constraints, skipping the Lagrange / Mayer rows.
        let mut tmp_nj = n_j;
        if data.s.lagrange {
            tmp_nj += 1;
        }
        if data.s.mayer && index == 3 {
            tmp_nj += 1;
        }
        let mut j = 0;
        for ii in nx..tmp_nj {
            let ii_i = ii as i32;
            if index == 2 && ii_i != data.s.der_index[1] {
                if let Some(s) = data.s.index_con2.get_mut(j) {
                    *s = ii;
                }
                j += 1;
            } else if index == 3 && ii_i != data.s.der_index[2] && ii_i != data.s.der_index[0] {
                if let Some(s) = data.s.index_con3.get_mut(j) {
                    *s = ii;
                }
                j += 1;
            }
        }
    }

    // C: the constraint Jacobian's pattern is B's, with the constraint rows taken
    // from `indexCon2`.
    let mut n_jderx = 0;
    for i in 0..n_j {
        for j in 0..nv {
            let src_row = if i < nx { i } else { data.s.index_con2[i - nx] };
            if data.s.j[0][src_row * nv + j] {
                data.s.jder_con[i * nv + j] = true;
                n_jderx += 1;
            }
        }
    }
    data.dim.n_jderx = n_jderx;
    data.dim.n_jfderx = data.s.j[2].iter().filter(|b| **b).count();

    if data.s.lagrange && data.s.der_index[1] >= 0 {
        let row = data.s.der_index[1] as usize;
        for j in 0..nv {
            if data.s.j[0][row * nv + j] {
                data.s.grad_l[j] = true;
            }
        }
    }
    if data.s.mayer && data.s.der_index[0] >= 0 {
        let row = data.s.der_index[0] as usize;
        for j in 0..nv {
            if data.s.j[1][row * nv + j] {
                data.s.grad_m[j] = true;
            }
        }
    }

    // Row remapping: a B row lands at `index_j2[row]`, a C row at `index_j3[row]`;
    // the objective rows are moved above the constraints (`n_j`, `n_j + 1`).
    data.s.index_j2 = vec![0; n_j + 1];
    let mut j = 0;
    for i in 0..=n_j {
        if i as i32 == data.s.der_index[1] {
            data.s.index_j2[i] = n_j;
        } else {
            data.s.index_j2[i] = j;
            j += 1;
        }
    }
    data.s.index_j3 = vec![0; n_j2];
    let mut j = 0;
    for i in 0..n_j2 {
        if i as i32 == data.s.der_index[2] {
            data.s.index_j3[i] = n_j;
        } else if i as i32 == data.s.der_index[0] {
            data.s.index_j3[i] = n_j + 1;
        } else {
            data.s.index_j3[i] = j;
            j += 1;
        }
    }
    let _ = ncf;
}

/// The Jacobian at C's `indexABCD[index]`.
fn jac_of(opt: &OptInfo, index: usize) -> Option<&OptJac> {
    match index {
        2 => opt.jac_b.as_ref(),
        3 => opt.jac_c.as_ref(),
        4 => opt.jac_d.as_ref(),
        _ => None,
    }
}

/// C's `update_local_jac_struct`: the collocation constraint always has a diagonal.
fn update_local_jac_struct(data: &mut OptData) {
    let nv = data.dim.nv;
    for i in 0..data.dim.nx {
        if !data.s.jder_con[i * nv + i] {
            data.s.jder_con[i * nv + i] = true;
            data.dim.n_jderx += 1;
        }
    }
}

/// C's `local_hessian_struct`: the (over-estimated) Hessian pattern, from the outer
/// products of the Jacobian rows and the objective gradients.
fn local_hessian_struct(data: &mut OptData) {
    let (nv, n_j, ncf) = (data.dim.nv, data.dim.n_j, data.dim.ncf);
    data.s.hg = flags_bool(n_j * nv * nv);
    data.s.hcf = flags_bool(ncf * nv * nv);
    data.s.hm = flags_bool(nv * nv);
    data.s.hl = flags_bool(nv * nv);
    data.s.h0 = flags_bool(nv * nv);
    data.s.h1 = flags_bool(nv * nv);
    data.dim.nh0 = 0;
    data.dim.nh1 = 0;
    data.dim.nh0_ = 0;
    data.dim.nh1_ = 0;

    for l in 0..n_j {
        for i in 0..nv {
            for j in 0..nv {
                if data.s.jder_con[l * nv + i] && data.s.jder_con[l * nv + j] {
                    data.s.hg[(l * nv + i) * nv + j] = true;
                }
            }
        }
    }
    for l in 0..ncf {
        for i in 0..nv {
            for j in 0..nv {
                if data.s.j[2][l * nv + i] && data.s.j[2][l * nv + j] {
                    data.s.hcf[(l * nv + i) * nv + j] = true;
                }
            }
        }
    }
    if data.s.lagrange {
        for i in 0..nv {
            for j in 0..nv {
                if data.s.grad_l[i] && data.s.grad_l[j] {
                    data.s.hl[i * nv + j] = true;
                }
            }
        }
    }
    if data.s.mayer {
        for i in 0..nv {
            for j in 0..nv {
                if data.s.grad_m[i] && data.s.grad_m[j] {
                    data.s.hm[i * nv + j] = true;
                }
            }
        }
    }

    for i in 0..nv {
        for j in 0..nv {
            let ij = i * nv + j;
            if n_j > 0 {
                for l in 0..n_j {
                    let tmp = data.s.hg[(l * nv + i) * nv + j] || data.s.hl[ij];
                    if tmp && !data.s.h0[ij] {
                        data.s.h0[ij] = true;
                        data.dim.nh0 += 1;
                        if i <= j {
                            data.dim.nh0_ += 1;
                        }
                    }
                    if (tmp || data.s.hm[ij]) && !data.s.h1[ij] {
                        data.s.h1[ij] = true;
                        data.dim.nh1 += 1;
                        if i <= j {
                            data.dim.nh1_ += 1;
                        }
                    }
                    if data.s.h0[ij] && data.s.h1[ij] {
                        break;
                    }
                }
            } else {
                if data.s.hl[ij] {
                    data.s.h0[ij] = true;
                    data.dim.nh0 += 1;
                    if i <= j {
                        data.dim.nh0_ += 1;
                    }
                }
                if data.s.h0[ij] || data.s.hm[ij] {
                    data.s.h1[ij] = true;
                    data.dim.nh1 += 1;
                    if i <= j {
                        data.dim.nh1_ += 1;
                    }
                }
            }
        }
    }
    if ncf > 0 {
        for i in 0..nv {
            for j in 0..nv {
                let ij = i * nv + j;
                for l in 0..ncf {
                    if data.s.hcf[(l * nv + i) * nv + j] && !data.s.h1[ij] {
                        data.s.h1[ij] = true;
                        data.dim.nh1 += 1;
                        if i <= j {
                            data.dim.nh1_ += 1;
                        }
                        break;
                    }
                }
            }
        }
    }
}

/// C's `print_local_jac_struct`.
fn print_local_jac_struct(data: &OptData) {
    let (nv, n_j, ncf) = (data.dim.nv, data.dim.n_j, data.dim.ncf);
    let mut out = format!("\nJacabian Structure {n_j} x {nv}");
    out.push_str("\n========================================================");
    for i in 0..n_j {
        out.push('\n');
        for j in 0..nv {
            out.push_str(if data.s.jder_con[i * nv + j] { "* " } else { "0 " });
        }
    }
    if ncf > 0 {
        out.push_str("\n-------------------------------------------------------");
        out.push_str("\nfinal constraint(s)");
        for i in 0..ncf {
            out.push('\n');
            for j in 0..nv {
                out.push_str(if data.s.j[2][i * nv + j] { "* " } else { "0 " });
            }
        }
    }
    out.push_str("\n========================================================");
    out.push_str("\nGradient Structure");
    out.push_str("\n========================================================");
    if data.s.lagrange {
        out.push_str("\nlagrange");
        out.push_str("\n-------------------------------------------------------");
        out.push('\n');
        for j in 0..nv {
            out.push_str(if data.s.grad_l[j] { "* " } else { "0 " });
        }
    }
    if data.s.mayer {
        out.push_str("\nmayer");
        out.push_str("\n-------------------------------------------------------");
        out.push('\n');
        for j in 0..nv {
            out.push_str(if data.s.grad_m[j] { "* " } else { "0 " });
        }
    }
    driver::log_line(omclog::STDOUT, omclog::INFO, &out);
}

/// C's `print_local_hessian_struct`.
fn print_local_hessian_struct(data: &OptData) {
    let nv = data.dim.nv;
    let mut out = String::from("\n========================================================");
    out.push_str(&format!(
        "\nHessian Structure {nv} x {nv}\tnz = {}",
        data.dim.nh0
    ));
    out.push_str("\n========================================================");
    for i in 0..nv {
        out.push('\n');
        for j in 0..nv {
            out.push_str(if data.s.h0[i * nv + j] { "* " } else { "0 " });
        }
    }
    if data.dim.nh1 != data.dim.nh0 {
        out.push_str("\n========================================================");
        out.push_str(&format!(
            "\nHessian Structure {nv} x {nv} for t = stopTime \tnz = {}",
            data.dim.nh1
        ));
        out.push_str("\n========================================================");
        for i in 0..nv {
            out.push('\n');
            for j in 0..nv {
                out.push_str(if data.s.h1[i * nv + j] { "* " } else { "0 " });
            }
        }
    }
    driver::log_line(omclog::STDOUT, omclog::INFO, &out);
}

// ───────────────────────────── InitialGuess.c ─────────────────────────────

/// C's `initial_guess_optimizer`: the trajectory the NLP starts from, and the
/// derived `vopt`/bound arrays.
pub(crate) fn initial_guess(data: &mut OptData) -> Result<()> {
    data.dim.iter = 0;
    let flags = crate::simflags::with_flags(|f| f.clone());
    data.ipop.csv_ostep = flags.csv_ostep.clone();
    data.ipop.debug_jac = flags.opt_debug_jac.clone();

    // C opens `optimizeInput.csv` here and writes the header; the rows follow from
    // the pre-simulation and `res2file`.
    let mut header = String::from("time ");
    for &idx in &data.opt.inputs {
        header.push_str(data.names.get(idx as usize).map(String::as_str).unwrap_or(""));
        header.push(' ');
    }
    header.push('\n');
    data.input_csv = header;

    let mut opt = 1;
    if let Some(cflag) = flags.ipopt_init.as_deref() {
        opt = initial_guess_cflag(data, cflag);
    }
    if opt > 0 {
        opt = initial_guess_sim(data, opt)?;
    }
    init_ipopt_data(data, opt);
    Ok(())
}

/// C's `initial_guess_ipopt_cflag`: `-ipopt_init=const|sim|file`.
fn initial_guess_cflag(data: &mut OptData, cflag: &str) -> i32 {
    match cflag {
        "const" | "CONST" => {
            let u0 = data.bounds.u0.clone();
            data.model.inputs.copy_from_slice(&u0);
            let v0 = data.v0.clone();
            for i in 0..data.dim.nsi {
                for j in 0..data.dim.np {
                    data.v_mut(i, j).copy_from_slice(&v0);
                }
            }
            omclog::info(omclog::IPOPT, false, "Using const trajectory as initial guess.");
            0
        }
        "sim" | "SIM" => {
            omclog::info(omclog::IPOPT, false, "Using simulation as initial guess.");
            1
        }
        "file" | "FILE" => {
            omclog::info(omclog::STDOUT, false, "Using values from file as initial guess.");
            2
        }
        other => {
            omclog::warning!(omclog::STDOUT, false, "not support ipopt_init={other}");
            1
        }
    }
}

/// C's `initial_guess_ipopt_sim`: simulate the model over the collocation grid with
/// DASSL and take each point's variables as the guess.
fn initial_guess_sim(data: &mut OptData, o: i32) -> Result<i32> {
    let (nx, nu, np, nsi, n_real) = (
        data.dim.nx,
        data.dim.nu,
        data.dim.np,
        data.dim.nsi,
        data.dim.n_real,
    );
    // C clamps the tolerance for the guess: `min(max(tol,1e-8),1e-3)`.
    let tol = data.tol;
    let guess_tol = tol.max(1e-8).min(1e-3);
    omclog::info(omclog::SOLVER, false, "Initial Guess: Initializing DASSL");

    // C's `externalInputallocate`: with `-csvInput` the guess's inputs come from the
    // file, so `u0` is only used when there is none.
    let opt = data.opt.clone();
    let input_names: Vec<&str> = opt
        .inputs
        .iter()
        .map(|&i| data.names.get(i as usize).map(String::as_str).unwrap_or(""))
        .collect();
    let mut ext = crate::extinput::ExtInputHook::load_reals(&opt.inputs, &input_names);
    // The file drives the inputs for the guess only; the Ipopt iterations take
    // theirs from `vopt`.
    let _armed = ext.as_mut().map(crate::extinput::arm);
    if ext.is_none() {
        let u0 = data.bounds.u0.clone();
        data.model.inputs.copy_from_slice(&u0);
    }
    data.model.input_function(&opt);

    let print_guess = omclog::active(omclog::INIT) && !omclog::active(omclog::SOLVER);
    let meta = data.guess_meta(guess_tol);
    let engine = data.model.engine;
    let sim_data = data.model.sim_data;
    let e = unsafe { &mut *engine };
    let mut stepper = driver::GuessStepper::new(e, &meta, sim_data, data.start_time)?;

    // C's pre-simulation: when the Optimica `startTime` is beyond the experiment's,
    // simulate up to it first and emit those rows.
    if data.start_time < data.time.t0 {
        let mut t = data.start_time;
        data.csv_row(t);
        let mut out = String::from("\nPreSim");
        out.push_str("\n========================================================\n");
        out.push_str(&format!("\ndone: time[0] = {}", format_g(data.start_time, 6)));
        driver::log_line(omclog::STDOUT, omclog::INFO, &out);
        while t < data.time.t0 {
            if let Some(hook) = ext.as_mut() {
                hook.ext.update(t, &mut data.model.inputs);
                data.model.input_function(&opt);
            }
            t = (t + data.time.dt[0]).min(data.time.t0);
            let e = unsafe { &mut *engine };
            stepper.step_to(e, &meta, t)?;
            let now = stepper.time();
            driver::log_line(omclog::STDOUT, omclog::INFO, &format!("\ndone: time[0] = {}", format_g(now, 6)));
            data.emit_row(now)?;
            data.csv_row(now);
        }
        copy_initial_values(data);
        let mut out = String::from("\n--------------------------------------------------------");
        out.push_str("\nfinished: PreSim");
        out.push_str("\n========================================================\n");
        driver::log_line(omclog::STDOUT, omclog::INFO, &out);
    }

    // `-ipopt_init=file` needs `-iif` to name the result file the guess is read from.
    let iif = crate::simflags::with_flags(|f| f.init_file.clone());
    let op = if o == 2 && iif.as_deref().is_some_and(|s| !s.is_empty()) { 2 } else { 1 };
    // C's `importStartValues` writes the start attributes, which carry over from
    // one collocation point to the next; `start` mirrors that array.
    let attrs = data.model.layout;
    let names = data.names.clone();
    let name_refs: Vec<&str> = names.iter().map(String::as_str).collect();
    let mut start = zeros(n_real);
    if op == 2 {
        for (l, s) in start.iter_mut().enumerate() {
            *s = data.model.read_f64_at(attrs.real_start_off(l as u32));
        }
    }

    if print_guess {
        let mut out = String::from("\nInitial Guess");
        out.push_str("\n========================================================\n");
        out.push_str(&format!("\ndone: time[0] = {}", format_g(data.time.t0, 6)));
        driver::log_line(omclog::STDOUT, omclog::INFO, &out);
    }

    let mut k = 1;
    for i in 0..nsi {
        for j in 0..np {
            let t = data.time.t[i][j];
            if let Some(hook) = ext.as_mut() {
                let now = stepper.time();
                hook.ext.update(now, &mut data.model.inputs);
                data.model.input_function(&opt);
            }
            if op == 1 {
                let e = unsafe { &mut *engine };
                stepper.step_to(e, &meta, t)?;
            } else {
                // C's `importStartValues` at this point's time, then every real
                // variable set to its start (`getStartFromScalarIdx`). A name the
                // file does not carry keeps the start it already had.
                driver::read_result_file(iif.as_deref().unwrap_or(""), &name_refs, t, &mut start)
                    .map_err(driver::leak_error)?;
                for (l, &v) in start.iter().enumerate() {
                    data.model.write_f64_at(attrs.real_start_off(l as u32), v);
                }
                data.model.write_reals(&start);
            }
            if print_guess {
                driver::log_line(omclog::STDOUT, omclog::INFO, &format!("\ndone: time[{k}] = {}", format_g(t, 6)));
            }
            k += 1;
            let mut buf = zeros(n_real);
            data.model.read_reals(&mut buf);
            data.v_mut(i, j).copy_from_slice(&buf);
            for l in 0..nx {
                let (lo, hi) = (
                    data.bounds.vmin[l] * data.bounds.vnom[l],
                    data.bounds.vmax[l] * data.bounds.vnom[l],
                );
                let v = data.v(i, j)[l];
                if v < lo || v > hi {
                    driver::log_line(omclog::STDOUT, omclog::INFO, "\n********************************************\n");
                    omclog::warning!(
                        omclog::STDOUT,
                        false,
                        "Initial guess failure at time {}",
                        format_g(t, 6),
                    );
                    omclog::warning!(
                        omclog::STDOUT,
                        false,
                        "{}<= ({}={}) <={}",
                        format_g(lo, 6),
                        data.names.get(l).map(String::as_str).unwrap_or(""),
                        format_g(v, 6),
                        format_g(hi, 6),
                    );
                    driver::log_line(omclog::STDOUT, omclog::INFO, "\n********************************************");
                }
            }
        }
    }
    if print_guess {
        let mut out = String::from("\n--------------------------------------------------------");
        out.push_str("\nfinished: Initial Guess");
        out.push_str("\n========================================================\n");
        driver::log_line(omclog::STDOUT, omclog::INFO, &out);
    }
    let _ = nu;
    Ok(op)
}

/// C's `init_ipopt_data`: `vopt` from the guess, and the constraint bounds.
fn init_ipopt_data(data: &mut OptData, op: i32) {
    let d = &data.dim;
    let (nx, nv, nsi, np, nc, ncf) = (d.nx, d.nv, d.nsi, d.np, d.nc, d.ncf);
    let (nv_total, n_res, n_j) = (d.nv_total, d.n_res, d.n_j);
    let (index_con, index_conf) = (d.index_con, d.index_conf);
    data.ipop.vopt = zeros(nv_total);
    data.ipop.mult_x_l = zeros(nv_total);
    data.ipop.mult_x_u = zeros(nv_total);
    data.ipop.gmin = zeros(n_res);
    data.ipop.gmax = zeros(n_res);
    data.ipop.mult_g = zeros(n_res);

    let opt = data.opt.clone();
    let mut shift = 0;
    for i in 0..nsi {
        for j in 0..np {
            let point = data.v(i, j).to_vec();
            data.model.write_reals(&point);
            data.model.set_input_data(&opt, op == 2);
            for l in 0..nx {
                data.ipop.vopt[l + shift] = point[l] * data.bounds.scal_f[l];
            }
            for l in nx..nv {
                data.ipop.vopt[l + shift] =
                    data.model.inputs[l - nx] * data.bounds.scal_f[l];
            }
            shift += nv;
        }
    }

    // Path-constraint bounds repeat at every collocation point; the final ones sit
    // at the end of `g`.
    let attrs = data.model.layout;
    let l = n_res - ncf;
    for j in 0..nc {
        let idx = (j + index_con) as u32;
        let min = data.model.read_f64_at(attrs.opt_min_off + idx * 8);
        let max = data.model.read_f64_at(attrs.opt_max_off + idx * 8);
        let mut i = nx;
        while i < l {
            data.ipop.gmin[i + j] = min;
            data.ipop.gmax[i + j] = max;
            i += n_j;
        }
    }
    for j in 0..ncf {
        let idx = (j + index_conf) as u32;
        data.ipop.gmin[l + j] = data.model.read_f64_at(attrs.opt_min_off + idx * 8);
        data.ipop.gmax[l + j] = data.model.read_f64_at(attrs.opt_max_off + idx * 8);
    }
}

// ───────────────────────── MoveData.c: writing back ─────────────────────────

/// C's `res2file`: the optimal trajectory into the result rows (and the input
/// values into `optimizeInput.csv`).
pub(crate) fn res2file(data: &mut OptData) -> Result<()> {
    let (nx, nu, nv, nsi, np, n_real) = (
        data.dim.nx,
        data.dim.nu,
        data.dim.nv,
        data.dim.nsi,
        data.dim.np,
        data.dim.n_real,
    );
    // The Radau extrapolation of the inputs back to `t0` (C's `a[]`).
    let a: Vec<f64> = match np {
        3 => vec![
            1.558_078_204_724_922_4,
            -0.891_411_538_058_255_7,
            0.333_333_333_333_333_33,
        ],
        1 => vec![1.0],
        n => {
            omclog::error!(omclog::STDOUT, false, "Not support np = {n}");
            return Err("CodegenWasmJit: unsupported number of collocation points");
        }
    };
    let vopt = core::mem::take(&mut data.ipop.vopt);
    opt_data2model_data(data, &vopt, 0);

    let t0 = data.time.t0;
    let mut line = format!("{:.6} ", t0);
    for (i, j) in (nx..nv).enumerate() {
        let mut tmpv = 0.0;
        for (k, ak) in a.iter().enumerate() {
            tmpv += ak * vopt[k * nv + j];
        }
        tmpv = tmpv.max(data.bounds.vmin[j]).min(data.bounds.vmax[j]);
        data.model.inputs[i] = tmpv * data.bounds.vnom[j];
        line.push_str(&format!("{:.6} ", data.model.inputs[i] as f32));
    }
    line.push('\n');
    data.input_csv.push_str(&line);

    copy_initial_values(data);
    data.model.set_time(t0);
    let opt = data.opt.clone();
    data.model.input_function(&opt);
    data.model.update_discrete_system();
    data.emit_row(t0)?;

    for ii in 0..nsi {
        for jj in 0..np {
            let point = data.v(ii, jj).to_vec();
            data.model.write_reals(&point);
            let t = data.time.t[ii][jj];
            let mut line = format!("{:.6} ", t);
            for i in 0..nu {
                let u = vopt[ii * nv * np + jj * nv + nx + i] * data.bounds.vnom[i + nx];
                line.push_str(&format!("{:.6} ", u as f32));
            }
            line.push('\n');
            data.input_csv.push_str(&line);
            data.emit_row(t)?;
        }
    }
    let _ = n_real;
    data.ipop.vopt = vopt;
    // C keeps `optimizeInput.csv` open from the initial guess to here; the rows were
    // collected in `input_csv`.
    if let Err(e) = std::fs::write("optimizeInput.csv", &data.input_csv) {
        omclog::warning!(omclog::STDOUT, false, "optimizeInput.csv could not be written: {e}");
    }
    Ok(())
}

/// C's `optData2ModelData`: evaluate the model at every collocation point for the
/// current `vopt`, and (when `index` is nonzero) the Jacobians there too.
pub(crate) fn opt_data2model_data(data: &mut OptData, vopt: &[f64], index: i32) {
    let (nsi, np, nv) = (data.dim.nsi, data.dim.np, data.dim.nv);
    copy_initial_values(data);
    let mut shift = 0;
    for i in 0..nsi - 1 {
        for j in 0..np {
            set_local_vars(data, vopt, i, j, shift);
            update_do_system(data, i, j, index, 2);
            shift += nv;
        }
    }
    let i = nsi - 1;
    for j in 0..np - 1 {
        set_local_vars(data, vopt, i, j, shift);
        update_do_system(data, i, j, index, 2);
        shift += nv;
    }
    let j = np - 1;
    set_local_vars(data, vopt, i, j, shift);
    update_do_system(data, i, j, index, 3);

    // The terminal constraints' Jacobian is evaluated once, at the final point.
    if index != 0 && data.s.matrix[4] {
        diff_syn_colored_f(data);
    }
}

/// C's `setLocalVars`: this point's states and inputs into the model, starting from
/// the `pre` values so discrete variables keep them.
fn set_local_vars(data: &mut OptData, vopt: &[f64], i: usize, j: usize, shift: usize) {
    let (nx, nv, n_real) = (data.dim.nx, data.dim.nv, data.dim.n_real);
    let mut point = zeros(n_real);
    data.model.read_pre_reals(&mut point);
    let t = data.time.t[i][j];
    for k in 0..nx {
        point[k] = vopt[shift + k] * data.bounds.vnom[k];
    }
    data.v_mut(i, j).copy_from_slice(&point);
    data.model.write_reals(&point);
    data.model.set_time(t);
    for k in nx..nv {
        data.model.inputs[k - nx] = vopt[shift + k] * data.bounds.vnom[k];
    }
}

/// C's `updateDOSystem`: the discrete update at one point, then its Jacobian.
fn update_do_system(data: &mut OptData, i: usize, j: usize, index: i32, m: usize) {
    let opt = data.opt.clone();
    data.model.input_function(&opt);
    data.model.update_discrete_system();
    // The evaluated point is what the callbacks read back.
    let n_real = data.dim.n_real;
    let mut buf = zeros(n_real);
    data.model.read_reals(&mut buf);
    data.v_mut(i, j).copy_from_slice(&buf);
    if index != 0 {
        diff_syn_colored(data, i, j, m);
    }
}

/// C's `diffSynColoredOptimizerSystem`: B (`m = 2`) or C (`m = 3`) at one
/// collocation point, scaled into the constraint Jacobian's rows.
pub(crate) fn diff_syn_colored(data: &mut OptData, i: usize, j: usize, m: usize) {
    let Some(jac) = jac_of(&data.opt, m).cloned() else { return };
    let (nv, nx, n_j) = (data.dim.nv, data.dim.nx, data.dim.n_j);
    let n_j1 = n_j + 1;
    let scaldt = data.bounds.scaldt[i].clone();
    let scalb = data.bounds.scalb[i][j];
    let index_j: Vec<usize> =
        if m == 3 { data.s.index_j3.clone() } else { data.s.index_j2.clone() };
    let vnom = data.bounds.vnom.clone();
    let (lagrange, mayer) = (data.s.lagrange, data.s.mayer);

    let mut out = vec![(0usize, 0usize, 0.0f64); 0];
    data.model.eval_jac_colored(&jac, &vnom, |row, col, v| out.push((row, col, v)));
    let target = data.jac_mut(i, j);
    for (row, col, v) in out {
        let l = match index_j.get(row) {
            Some(&l) => l,
            None => continue,
        };
        let scaled = if l < nx {
            v * scaldt[l]
        } else if l < n_j {
            v
        } else if l == n_j && lagrange {
            v * scalb
        } else if l == n_j1 && mayer {
            v
        } else {
            continue;
        };
        if let Some(slot) = target.get_mut(l * nv + col) {
            *slot = scaled;
        }
    }
}

/// C's `diffSynColoredOptimizerSystemF`: D, the final constraints' Jacobian.
pub(crate) fn diff_syn_colored_f(data: &mut OptData) {
    if data.dim.ncf == 0 {
        return;
    }
    let Some(jac) = data.opt.jac_d.clone() else { return };
    let nv = data.dim.nv;
    let vnom = data.bounds.vnom.clone();
    let mut out = vec![(0usize, 0usize, 0.0f64); 0];
    data.model.eval_jac_colored(&jac, &vnom, |row, col, v| out.push((row, col, v)));
    for (row, col, v) in out {
        if let Some(slot) = data.jf.get_mut(row * nv + col) {
            *slot = v;
        }
    }
}

impl OptData {
    /// The metadata the guess's DASSL run reads: this model with the guess's
    /// clamped tolerance.
    fn guess_meta(&self, tol: f64) -> SimMeta {
        let mut m = self.meta.clone();
        m.tolerance = tol;
        m
    }

    /// A `optimizeInput.csv` row for the current inputs.
    fn csv_row(&mut self, t: f64) {
        let mut line = format!("{:.6} ", t);
        for i in 0..self.dim.nu {
            line.push_str(&format!("{:.6} ", self.model.inputs[i] as f32));
        }
        line.push('\n');
        self.input_csv.push_str(&line);
    }

    /// One result row from `SimData` as it stands, at time `t`. C's `res2file` and
    /// its pre-simulation both emit an already-evaluated point (the collocation
    /// point's variables, or `updateContinuousSystem` after a DASSL step), so
    /// nothing is re-evaluated here.
    fn emit_row(&mut self, t: f64) -> Result<()> {
        let (sim_data, layout) = (self.model.sim_data, self.model.layout);
        let e = unsafe { &mut *self.model.engine };
        driver::write_f64(e, sim_data + crate::TIME_OFF, t)?;
        driver::capture_row(e, &mut self.rows, sim_data, &layout)
    }
}
