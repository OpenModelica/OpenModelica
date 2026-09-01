//! The port of `optimization/eval_all/`: the five Ipopt callbacks.
//!
//! Each recovers the [`OptData`] from Ipopt's user-data pointer, the same way the
//! DASSL residual recovers its context. They report `true` even after a model
//! error, as the C ones do; the error is surfaced once `IpoptSolve` returns.

use alloc::format;
use alloc::vec;
use alloc::vec::Vec;
use core::ffi::c_void;

use super::ipopt::{Index, Number};
use super::run::OptData;
use super::setup;
use crate::omclog;

/// Recover the problem from Ipopt's user data, moving whatever Ipopt has printed so
/// far into the log first — that is what keeps its banner ahead of the
/// `LOG_IPOPT_ERROR` lines these callbacks emit, as in the C target's output.
unsafe fn opt<'a>(user: *mut c_void) -> &'a mut OptData {
    let data = unsafe { &mut *(user as *mut OptData) };
    if let Some(out) = data.out.as_ref() {
        out.drain();
    }
    data
}

// ───────────────────────────────── EvalF.c ─────────────────────────────────

/// C's `evalfF`: the objective, `∫ lagrange dt + mayer(tf)`.
pub(crate) unsafe extern "C" fn eval_f(
    _n: Index,
    vopt: *mut Number,
    new_x: bool,
    obj: *mut Number,
    user: *mut c_void,
) -> bool {
    let data = unsafe { opt(user) };
    let n = data.dim.nv_total;
    let v = unsafe { core::slice::from_raw_parts(vopt, n) }.to_vec();
    if new_x {
        setup::opt_data2model_data(data, &v, 1);
    }
    let mut lagrange = 0.0;
    let mut mayer = 0.0;
    if data.s.lagrange {
        let (nsi, np, il) = (data.dim.nsi, data.dim.np, data.dim.index_lagrange);
        let mut erg = vec![0.0; np];
        for j in 0..np {
            erg[j] = data.time.dt[0] * data.v(0, j)[il];
        }
        for i in 1..nsi {
            for j in 0..np {
                erg[j] += data.time.dt[i] * data.v(i, j)[il];
            }
        }
        for j in 0..np {
            lagrange += data.rk.b[j] * erg[j];
        }
    }
    if data.s.mayer {
        let (nsi, np, im) = (data.dim.nsi, data.dim.np, data.dim.index_mayer);
        mayer = data.v(nsi - 1, np - 1)[im];
    }
    unsafe { *obj = lagrange + mayer };
    true
}

/// C's `evalfDiffF`: the objective gradient, which is the Lagrange row of every
/// point's Jacobian plus the Mayer row at the last one.
pub(crate) unsafe extern "C" fn eval_grad_f(
    n: Index,
    vopt: *mut Number,
    new_x: bool,
    grad: *mut Number,
    user: *mut c_void,
) -> bool {
    let data = unsafe { opt(user) };
    let n = n as usize;
    let v = unsafe { core::slice::from_raw_parts(vopt, n) }.to_vec();
    if new_x {
        setup::opt_data2model_data(data, &v, 1);
    }
    let (nv, nsi, np, n_j) = (data.dim.nv, data.dim.nsi, data.dim.np, data.dim.n_j);
    let out = unsafe { core::slice::from_raw_parts_mut(grad, n) };
    if data.s.lagrange {
        let mut ii = 0;
        for i in 0..nsi {
            for j in 0..np {
                out[ii..ii + nv].copy_from_slice(data.jac_row(i, j, n_j));
                ii += nv;
            }
        }
    } else {
        out.fill(0.0);
    }
    if data.s.mayer {
        let grad_m = data.jac_row(nsi - 1, np - 1, n_j + 1).to_vec();
        let base = n - nv;
        if data.s.lagrange {
            for i in 0..nv {
                out[base + i] += grad_m[i];
            }
        } else {
            out[base..base + nv].copy_from_slice(&grad_m);
        }
    }
    true
}

// ───────────────────────────────── EvalG.c ─────────────────────────────────

/// C's `evalfG`: the collocation constraints and the path/final constraints.
pub(crate) unsafe extern "C" fn eval_g(
    _n: Index,
    vopt: *mut Number,
    new_x: bool,
    m: Index,
    g: *mut Number,
    user: *mut c_void,
) -> bool {
    let data = unsafe { opt(user) };
    let nv_total = data.dim.nv_total;
    let v = unsafe { core::slice::from_raw_parts(vopt, nv_total) }.to_vec();
    if new_x {
        let index = data.index;
        setup::opt_data2model_data(data, &v, index);
    }
    let (nx, nv, nc, ncf, nsi, np) = (
        data.dim.nx,
        data.dim.nv,
        data.dim.nc,
        data.dim.ncf,
        data.dim.nsi,
        data.dim.np,
    );
    let index_con = data.dim.index_con;
    let index_conf = data.dim.index_conf;
    let m = m as usize;
    let out = unsafe { core::slice::from_raw_parts_mut(g, m) };
    let a = data.rk.a;

    // The previous point's states (`sv0` for the first interval), and this
    // interval's points, as C's sliding `vv` window.
    let point = |i: usize, k: usize| -> &[f64] {
        let base = (i * np + k) * nv;
        &v[base..base + nv]
    };
    let mut shift = 0;
    if np == 3 {
        for i in 0..nsi {
            let sdt = &data.bounds.scaldt[i];
            let prev: Vec<f64> = if i == 0 {
                data.sv0.clone()
            } else {
                point(i - 1, np - 1).to_vec()
            };
            let (p0, p1, p2) =
                (point(i, 0).to_vec(), point(i, 1).to_vec(), point(i, 2).to_vec());
            for (j, coeff) in a.iter().enumerate().take(3) {
                for k in 0..nx {
                    let der = data.v(i, j)[nx + k];
                    out[shift] = match j {
                        0 => {
                            (coeff[0] * prev[k] + coeff[3] * p2[k] + sdt[k] * der)
                                - (coeff[1] * p0[k] + coeff[2] * p1[k])
                        }
                        1 => {
                            (coeff[1] * p0[k] + sdt[k] * der)
                                - (coeff[0] * prev[k] + coeff[2] * p1[k] + coeff[3] * p2[k])
                        }
                        _ => {
                            (coeff[0] * prev[k] + coeff[2] * p1[k] + sdt[k] * der)
                                - (coeff[1] * p0[k] + coeff[3] * p2[k])
                        }
                    };
                    shift += 1;
                }
                out[shift..shift + nc]
                    .copy_from_slice(&data.v(i, j)[index_con..index_con + nc]);
                shift += nc;
            }
        }
        // Terminal constraint(s).
        if ncf > 0 {
            let last = data.v(nsi - 1, 2)[index_conf..index_conf + ncf].to_vec();
            out[shift..shift + ncf].copy_from_slice(&last);
        }
    } else if np == 1 {
        for i in 0..nsi {
            let sdt = &data.bounds.scaldt[i];
            let prev: Vec<f64> = if i == 0 {
                data.sv0.clone()
            } else {
                point(i - 1, 0).to_vec()
            };
            let p0 = point(i, 0).to_vec();
            for k in 0..nx {
                let der = data.v(i, 0)[nx + k];
                out[shift] = prev[k] + (sdt[k] * der - p0[k]);
                shift += 1;
            }
            out[shift..shift + nc].copy_from_slice(&data.v(i, 0)[index_con..index_con + nc]);
            shift += nc;
        }
        if ncf > 0 {
            let last = data.v(nsi - 1, 0)[index_conf..index_conf + ncf].to_vec();
            out[m - ncf..].copy_from_slice(&last);
        }
    }
    if omclog::active(omclog::IPOPT_ERROR) {
        print_max_error(data, out);
    }
    true
}

/// C's `printMaxError`: the largest constraint violation and where it is, logged
/// once per `evalfG` under `-lv=LOG_IPOPT_ERROR`.
fn print_max_error(data: &OptData, g: &[f64]) {
    let (nx, n_j, np, nsi, ncf) = (
        data.dim.nx,
        data.dim.n_j,
        data.dim.np,
        data.dim.nsi,
        data.dim.ncf,
    );
    let mut gmax = -1.0;
    let (mut ii, mut jj, mut kk) = (0usize, 0usize, -1i64);
    let mut l = 0;
    for i in 0..nsi {
        for j in 0..np {
            for k in 0..nx {
                let tmp = libm::fabs(g[l]);
                l += 1;
                if tmp > gmax {
                    (ii, jj, kk, gmax) = (i, j, k as i64, tmp);
                }
            }
            for k in nx..n_j {
                let over = g[l] - data.ipop.gmax[l];
                let under = data.ipop.gmin[l] - g[l];
                let tmp = over.max(under).max(0.0);
                l += 1;
                if tmp > gmax {
                    (ii, jj, kk, gmax) = (i, j, k as i64, tmp);
                }
            }
        }
    }
    for k in n_j..n_j + ncf {
        let over = g[l] - data.ipop.gmax[l];
        let under = data.ipop.gmin[l] - g[l];
        let tmp = over.max(under).max(0.0);
        l += 1;
        if tmp > gmax {
            (ii, jj, kk, gmax) = (nsi - 1, np - 1, k as i64, tmp);
        }
    }
    if kk < 0 {
        return;
    }
    let kk = kk as usize;
    let t = data.time.t[ii][jj];
    let name = |i: usize| data.names.get(i).map(alloc::string::String::as_str).unwrap_or("");
    // C prints these through `ryu_hr_tdzp_buf`, the shortest round-trip form.
    let (g, tt) = (omclog::shortest(gmax), omclog::shortest(t));
    let msg = if kk < nx {
        format!("max error is {g} for the approximation of the state {}(time = {tt})", name(kk))
    } else if kk < n_j {
        format!(
            "max violation is {g} for the constraint {}(time = {tt})",
            name(kk - nx + data.dim.index_con)
        )
    } else {
        format!(
            "max violation is {g} for the final constraint {}(time = {tt})",
            name(kk - nx + data.dim.index_con)
        )
    };
    omclog::info(omclog::IPOPT_ERROR, false, &msg);
}

/// C's `evalfDiffG`: the constraint Jacobian, as a triplet pattern on the first
/// call and values afterwards.
pub(crate) unsafe extern "C" fn eval_jac_g(
    _n: Index,
    vopt: *mut Number,
    new_x: bool,
    _m: Index,
    nele: Index,
    i_row: *mut Index,
    j_col: *mut Index,
    values: *mut Number,
    user: *mut c_void,
) -> bool {
    let data = unsafe { opt(user) };
    let nele = nele as usize;
    if values.is_null() {
        let rows = unsafe { core::slice::from_raw_parts_mut(i_row, nele) };
        let cols = unsafe { core::slice::from_raw_parts_mut(j_col, nele) };
        generated_jac_struct(data, rows, cols);
        return true;
    }
    let nv_total = data.dim.nv_total;
    let v = unsafe { core::slice::from_raw_parts(vopt, nv_total) }.to_vec();
    data.iter_ += 1;
    if new_x {
        setup::opt_data2model_data(data, &v, 1);
    }
    let (nx, nv, n_j, ncf, nsi, np) = (
        data.dim.nx,
        data.dim.nv,
        data.dim.n_j,
        data.dim.ncf,
        data.dim.nsi,
        data.dim.np,
    );
    let out = unsafe { core::slice::from_raw_parts_mut(values, nele) };
    let mut k = 0;
    if np == 3 {
        for i in 0..nsi {
            for j in 0..np {
                for l in 0..nx {
                    let a = data.rk.a[j];
                    let row = data.jac_row(i, j, l).to_vec();
                    let pat = &data.s.jder_con[l * nv..l * nv + nv];
                    // The first interval has no incoming state, so its first block
                    // lacks the `a[0]` cell.
                    match (i, j) {
                        (0, 0) => struct_jac_01(&a, &row, out, &mut k, l, pat),
                        (0, 1) => struct_jac_02(&a, &row, out, &mut k, l, pat),
                        (0, 2) => struct_jac_03(&a, &row, out, &mut k, l, pat),
                        (_, 0) => struct_jac_1(&a, &row, out, &mut k, l, pat),
                        (_, 1) => struct_jac_2(&a, &row, out, &mut k, l, pat),
                        (_, _) => struct_jac_3(&a, &row, out, &mut k, l, pat),
                    }
                }
                for l in nx..n_j {
                    let row = data.jac_row(i, j, l).to_vec();
                    let pat = &data.s.jder_con[l * nv..l * nv + nv];
                    struct_jac_c(&row, out, &mut k, pat);
                }
            }
        }
        for l in 0..ncf {
            let row = data.jf[l * nv..l * nv + nv].to_vec();
            let pat = &data.s.j[2][l * nv..l * nv + nv];
            struct_jac_c(&row, out, &mut k, pat);
        }
    } else if np == 1 {
        for i in 0..nsi {
            for l in 0..nx {
                if i > 0 {
                    out[k] = 1.0;
                    k += 1;
                }
                let row = data.jac_row(i, 0, l).to_vec();
                for ii in 0..nv {
                    if data.s.jder_con[l * nv + ii] {
                        out[k] = if ii == l { row[ii] - 1.0 } else { row[ii] };
                        k += 1;
                    }
                }
            }
            for l in nx..n_j {
                let row = data.jac_row(i, 0, l).to_vec();
                for ii in 0..nv {
                    if data.s.jder_con[l * nv + ii] {
                        out[k] = row[ii];
                        k += 1;
                    }
                }
            }
        }
        for l in 0..ncf {
            let row = data.jf[l * nv..l * nv + nv].to_vec();
            let pat = &data.s.j[2][l * nv..l * nv + nv];
            struct_jac_c(&row, out, &mut k, pat);
        }
    }
    true
}

/// C's `structJac01`: the first interval's first collocation point.
fn struct_jac_01(a: &[f64; 5], row: &[f64], out: &mut [f64], k: &mut usize, j: usize, pat: &[bool]) {
    for (l, &on) in pat.iter().enumerate() {
        if on {
            out[*k] = if j == l { row[l] - a[1] } else { row[l] };
            *k += 1;
        }
    }
    out[*k] = -a[2];
    *k += 1;
    out[*k] = a[3];
    *k += 1;
}

fn struct_jac_1(a: &[f64; 5], row: &[f64], out: &mut [f64], k: &mut usize, j: usize, pat: &[bool]) {
    out[*k] = a[0];
    *k += 1;
    struct_jac_01(a, row, out, k, j, pat);
}

fn struct_jac_02(a: &[f64; 5], row: &[f64], out: &mut [f64], k: &mut usize, j: usize, pat: &[bool]) {
    out[*k] = a[1];
    *k += 1;
    for (l, &on) in pat.iter().enumerate() {
        if on {
            out[*k] = if j == l { row[l] - a[2] } else { row[l] };
            *k += 1;
        }
    }
    out[*k] = -a[3];
    *k += 1;
}

fn struct_jac_2(a: &[f64; 5], row: &[f64], out: &mut [f64], k: &mut usize, j: usize, pat: &[bool]) {
    out[*k] = -a[0];
    *k += 1;
    struct_jac_02(a, row, out, k, j, pat);
}

fn struct_jac_03(a: &[f64; 5], row: &[f64], out: &mut [f64], k: &mut usize, j: usize, pat: &[bool]) {
    out[*k] = -a[1];
    *k += 1;
    out[*k] = a[2];
    *k += 1;
    for (l, &on) in pat.iter().enumerate() {
        if on {
            out[*k] = if j == l { row[l] - a[3] } else { row[l] };
            *k += 1;
        }
    }
}

fn struct_jac_3(a: &[f64; 5], row: &[f64], out: &mut [f64], k: &mut usize, j: usize, pat: &[bool]) {
    out[*k] = a[0];
    *k += 1;
    struct_jac_03(a, row, out, k, j, pat);
}

/// C's `structJacC`: a constraint row, no collocation cells.
fn struct_jac_c(row: &[f64], out: &mut [f64], k: &mut usize, pat: &[bool]) {
    for (l, &on) in pat.iter().enumerate() {
        if on {
            out[*k] = row[l];
            *k += 1;
        }
    }
}

/// C's `generated_jac_struc`: the triplet pattern of the whole constraint Jacobian.
fn generated_jac_struct(data: &OptData, rows: &mut [Index], cols: &mut [Index]) {
    let (nv, nx, nsi, n_j, np, ncf) = (
        data.dim.nv,
        data.dim.nx,
        data.dim.nsi,
        data.dim.n_j,
        data.dim.np,
        data.dim.ncf,
    );
    let npv = np * nv;
    // One writer for both triplet arrays, so the pattern helpers below can share it
    // (two closures cannot each hold `&mut` to the arrays).
    struct Trip<'a> {
        rows: &'a mut [Index],
        cols: &'a mut [Index],
        k: usize,
    }
    impl Trip<'_> {
        fn cell(&mut self, r: usize, c: usize) {
            self.rows[self.k] = r as Index;
            self.cols[self.k] = c as Index;
            self.k += 1;
        }
        fn row(&mut self, pat: &[bool], r: usize, c: usize) {
            for (i, &on) in pat.iter().enumerate() {
                if on {
                    self.cell(r, c + i);
                }
            }
        }
    }
    let mut t = Trip { rows, cols, k: 0 };
    let pat = |l: usize| &data.s.jder_con[l * nv..l * nv + nv];
    let patf = |l: usize| &data.s.j[2][l * nv..l * nv + nv];

    let mut r = 0;
    let mut c = 0;
    if np == 3 {
        for block in 0..3 {
            for j in 0..nx {
                let tmp_r = r + j;
                let tmp_c = c + j;
                match block {
                    0 => {
                        t.row(pat(j), tmp_r, c);
                        t.cell(tmp_r, tmp_c + nv);
                        t.cell(tmp_r, tmp_c + 2 * nv);
                    }
                    1 => {
                        t.cell(tmp_r, tmp_c);
                        t.row(pat(j), tmp_r, c + nv);
                        t.cell(tmp_r, tmp_c + 2 * nv);
                    }
                    _ => {
                        t.cell(tmp_r, tmp_c);
                        t.cell(tmp_r, tmp_c + nv);
                        t.row(pat(j), tmp_r, c + 2 * nv);
                    }
                }
            }
            for j in nx..n_j {
                t.row(pat(j), r + j, c + block * nv);
            }
            r += n_j;
        }
        c = (np - 1) * nv;
        for _ in 1..nsi {
            for block in 0..3 {
                for j in 0..nx {
                    let tmp_r = r + j;
                    let tmp_c = c + j;
                    for m in 0..4 {
                        if m == block + 1 {
                            t.row(pat(j), tmp_r, c + (block + 1) * nv);
                        } else {
                            t.cell(tmp_r, tmp_c + m * nv);
                        }
                    }
                }
                for j in nx..n_j {
                    t.row(pat(j), r + j, c + (block + 1) * nv);
                }
                r += n_j;
            }
            c += npv;
        }
        for j in 0..ncf {
            t.row(patf(j), r + j, c);
        }
    } else if np == 1 {
        for j in 0..n_j {
            t.row(pat(j), r + j, c);
        }
        r += n_j;
        c = (np - 1) * nv;
        for _ in 1..nsi {
            for j in 0..nx {
                t.cell(r + j, c + j);
                t.row(pat(j), r + j, c + nv);
            }
            for j in nx..n_j {
                t.row(pat(j), r + j, c + nv);
            }
            r += n_j;
            c += npv;
        }
        for j in 0..ncf {
            t.row(patf(j), r + j, c);
        }
    }
}

// ───────────────────────────────── EvalL.c ─────────────────────────────────

/// C's `guess_step_size_for_numerical_differentiation`.
fn guess_step(v: f64) -> f64 {
    1e-5 * libm::fabs(v) + 1e-8
}

/// C's `ipopt_h`: the Lagrangian's Hessian, differenced from the symbolic
/// Jacobians (C differentiates the Jacobian numerically rather than emitting a
/// second-order derivative).
#[allow(clippy::too_many_arguments)]
pub(crate) unsafe extern "C" fn eval_h(
    _n: Index,
    vopt: *mut Number,
    _new_x: bool,
    obj_factor: Number,
    m: Index,
    lambda: *mut Number,
    _new_lambda: bool,
    nele: Index,
    i_row: *mut Index,
    j_col: *mut Index,
    values: *mut Number,
    user: *mut c_void,
) -> bool {
    let data = unsafe { opt(user) };
    let nele = nele as usize;
    let keep = data.dim.update_hessian > data.dim.iter_update_hessian;
    data.dim.iter_update_hessian += 1;
    if values.is_null() {
        let rows = unsafe { core::slice::from_raw_parts_mut(i_row, nele) };
        let cols = unsafe { core::slice::from_raw_parts_mut(j_col, nele) };
        init_hessian_structure(data, rows, cols);
        return true;
    }
    let out = unsafe { core::slice::from_raw_parts_mut(values, nele) };
    if keep {
        out.copy_from_slice(&data.old_h[..nele]);
        return true;
    }
    let nv_total = data.dim.nv_total;
    let mut v = unsafe { core::slice::from_raw_parts(vopt, nv_total) }.to_vec();
    let lam = unsafe { core::slice::from_raw_parts(lambda, m as usize) }.to_vec();
    fill_hessian_values(data, &mut v, &lam, obj_factor, out);
    if data.dim.update_hessian > 0 {
        data.old_h[..nele].copy_from_slice(out);
    }
    true
}

/// C's `init_hessian_structure`: the lower triangle of each point's Hessian block.
fn init_hessian_structure(data: &OptData, rows: &mut [Index], cols: &mut [Index]) {
    let (nsi, np, nv) = (data.dim.nsi, data.dim.np, data.dim.nv);
    let mut k = 0;
    let (mut r, mut c) = (0usize, 0usize);
    for _ in 0..nsi.saturating_sub(1) {
        for _ in 0..np {
            for j in 0..nv {
                for l in 0..j + 1 {
                    if data.s.h0[j * nv + l] {
                        rows[k] = (r + j) as Index;
                        cols[k] = (c + l) as Index;
                        k += 1;
                    }
                }
            }
            r += nv;
            c += nv;
        }
    }
    // The last interval: its final point uses `H1` (the Mayer term and the final
    // constraints contribute only there).
    for p in 1..=np {
        for j in 0..nv {
            for l in 0..j + 1 {
                let h1 = np == p && data.s.h1[j * nv + l];
                if h1 || data.s.h0[j * nv + l] {
                    rows[k] = (r + j) as Index;
                    cols[k] = (c + l) as Index;
                    k += 1;
                }
            }
        }
        r += nv;
        c += nv;
    }
}

/// C's `fill_hessian_values`.
fn fill_hessian_values(
    data: &mut OptData,
    v: &mut [f64],
    lambda: &[f64],
    obj_factor: f64,
    out: &mut [f64],
) {
    let (nsi, np, nv, n_j) = (data.dim.nsi, data.dim.np, data.dim.nv, data.dim.n_j);
    let update_cost = obj_factor != 0.0;
    let update_mayer = update_cost && data.s.mayer;
    let update_lagrange = update_cost && data.s.lagrange;
    data.dim.iter += 1;
    data.dim.iter_update_hessian = 0;
    setup::copy_initial_values(data);

    let mut k = 0;
    let mut voff = 0;
    let mut loff = 0;
    for ii in 0..nsi.saturating_sub(1) {
        for p in 0..np {
            hessian_numerical(data, v, voff, &lambda[loff..], obj_factor, ii, p, false);
            for i in 0..nv {
                for j in 0..i + 1 {
                    if data.s.h0[i * nv + j] {
                        out[k] = weighted_sum(data, i, j, update_lagrange);
                        k += 1;
                    }
                }
            }
            voff += nv;
            loff += n_j;
        }
    }
    let ii = nsi - 1;
    for p in 0..np {
        hessian_numerical(data, v, voff, &lambda[loff..], obj_factor, ii, p, true);
        for i in 0..nv {
            for j in 0..i + 1 {
                let last = p + 1 == np;
                if last && data.s.h1[i * nv + j] {
                    out[k] = weighted_sum_last(data, i, j, update_lagrange, update_mayer);
                    k += 1;
                } else if data.s.h0[i * nv + j] {
                    out[k] = weighted_sum(data, i, j, update_lagrange);
                    k += 1;
                }
            }
        }
        voff += nv;
        loff += n_j;
    }
}

/// C's `calculate_hessian_matrix_numerical` and its
/// `..._last_time_intervall` variant: difference the symbolic Jacobian in each
/// optimization variable.
#[allow(clippy::too_many_arguments)]
fn hessian_numerical(
    data: &mut OptData,
    v: &mut [f64],
    voff: usize,
    lambda: &[f64],
    obj_factor: f64,
    i: usize,
    j: usize,
    last_interval: bool,
) {
    let (nv, nx, n_j, np, nsi, ncf) = (
        data.dim.nv,
        data.dim.nx,
        data.dim.n_j,
        data.dim.np,
        data.dim.nsi,
        data.dim.ncf,
    );
    let n_j1 = n_j + 1;
    let update_cost = data.s.lagrange && obj_factor != 0.0;
    let final_point = last_interval && j + 1 == np && i + 1 == nsi;
    let update_mayer = final_point && data.s.mayer && obj_factor != 0.0;
    let jac_index = if update_mayer { 3 } else { 2 };

    let t = data.time.t[i][j];
    data.model.set_time(t);
    let point = data.v(i, j).to_vec();
    data.model.write_reals(&point);

    for ii in 0..nv {
        let v_save = v[voff + ii];
        let mut h = guess_step(v_save);
        v[voff + ii] += h;
        // C flips the difference at the upper bound (`>=` off the last interval).
        let at_bound = if last_interval {
            v[voff + ii] > data.bounds.vmax[ii]
        } else {
            v[voff + ii] >= data.bounds.vmax[ii]
        };
        if at_bound {
            h = -h;
            v[voff + ii] = v_save + h;
        }
        // The perturbed point through the model, then its Jacobian.
        let mut perturbed = data.v(i, j).to_vec();
        for l in 0..nx {
            perturbed[l] = v[voff + l] * data.bounds.vnom[l];
        }
        data.model.write_reals(&perturbed);
        for l in nx..nv {
            data.model.inputs[l - nx] = v[voff + l] * data.bounds.vnom[l];
        }
        let opt = data.opt.clone();
        data.model.input_function(&opt);
        data.model.update_discrete_system();
        let saved = core::mem::take(&mut data.tmp_j);
        data.tmp_j = saved;
        diff_syn_colored_tmp(data, i, j, jac_index);
        v[voff + ii] = v_save;

        for jj in 0..ii + 1 {
            if data.s.h0[ii * nv + jj] {
                for l in 0..n_j {
                    let use_row = data.s.hg[(l * nv + ii) * nv + jj]
                        && (last_interval || lambda.get(l).copied().unwrap_or(0.0) != 0.0);
                    if use_row {
                        let d = data.tmp_j[l * nv + jj] - data.jac_row(i, j, l)[jj];
                        data.h[(l * nv + ii) * nv + jj] =
                            d * lambda.get(l).copied().unwrap_or(0.0) / h;
                    }
                }
            }
        }
        if update_cost {
            let hh = obj_factor / h;
            for jj in 0..ii + 1 {
                if data.s.hl[ii * nv + jj] {
                    let d = data.tmp_j[n_j * nv + jj] - data.jac_row(i, j, n_j)[jj];
                    data.hl[ii * nv + jj] = d * hh;
                } else if !last_interval {
                    data.hl[ii * nv + jj] = 0.0;
                }
            }
        }
        if update_mayer {
            let hh = obj_factor / h;
            for jj in 0..ii + 1 {
                if data.s.hm[ii * nv + jj] {
                    let d = data.tmp_j[n_j1 * nv + jj] - data.jac_row(i, j, n_j1)[jj];
                    data.hm[ii * nv + jj] = d * hh;
                }
            }
        }
        if final_point && ncf > 0 {
            diff_syn_colored_f_tmp(data);
            for jj in 0..ii + 1 {
                if data.s.h0[ii * nv + jj] {
                    for l in 0..ncf {
                        if data.s.hcf[(l * nv + ii) * nv + jj] {
                            let d = data.tmp_jf[l * nv + jj] - data.jf[l * nv + jj];
                            data.hcf[(l * nv + ii) * nv + jj] =
                                d * lambda.get(n_j + l).copied().unwrap_or(0.0) / h;
                        }
                    }
                }
            }
        }
    }
}

/// [`setup::diff_syn_colored`] into `tmp_j` rather than the point's Jacobian.
fn diff_syn_colored_tmp(data: &mut OptData, i: usize, j: usize, m: usize) {
    let saved = data.jac(i, j).to_vec();
    setup::diff_syn_colored(data, i, j, m);
    let fresh = data.jac(i, j).to_vec();
    data.tmp_j.copy_from_slice(&fresh);
    data.jac_mut(i, j).copy_from_slice(&saved);
}

/// The same for the final constraints' Jacobian.
fn diff_syn_colored_f_tmp(data: &mut OptData) {
    let saved = data.jf.clone();
    setup::diff_syn_colored_f(data);
    data.tmp_jf = core::mem::replace(&mut data.jf, saved);
}

/// C's `calculate_weighted_sum_with_lagrange_multiplicator_from_tensor`.
fn weighted_sum(data: &OptData, i: usize, j: usize, update_lagrange: bool) -> f64 {
    let (nv, n_j) = (data.dim.nv, data.dim.n_j);
    let mut sum = 0.0;
    for l in 0..n_j {
        if data.s.hg[(l * nv + i) * nv + j] {
            sum += data.h[(l * nv + i) * nv + j];
        }
    }
    if update_lagrange && data.s.hl[i * nv + j] {
        sum += data.hl[i * nv + j];
    }
    sum
}

/// Its `..._last_time_intervall` variant, which adds the final constraints and the
/// Mayer term.
fn weighted_sum_last(
    data: &OptData,
    i: usize,
    j: usize,
    update_lagrange: bool,
    update_mayer: bool,
) -> f64 {
    let (nv, n_j, ncf) = (data.dim.nv, data.dim.n_j, data.dim.ncf);
    let mut sum = 0.0;
    if data.s.h0[i * nv + j] {
        for l in 0..n_j {
            if data.s.hg[(l * nv + i) * nv + j] {
                sum += data.h[(l * nv + i) * nv + j];
            }
        }
        if update_lagrange && data.s.hl[i * nv + j] {
            sum += data.hl[i * nv + j];
        }
    }
    for l in 0..ncf {
        if data.s.hcf[(l * nv + i) * nv + j] {
            sum += data.hcf[(l * nv + i) * nv + j];
        }
    }
    if update_mayer && data.s.hm[i * nv + j] {
        sum += data.hm[i * nv + j];
    }
    sum
}
