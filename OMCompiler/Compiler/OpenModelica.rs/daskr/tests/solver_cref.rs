//! End-to-end cross-validation of the Rust `ddaskr` driver against the original
//! C `_daskr_ddaskr_`, integrating the same DAE with identical callbacks and
//! comparing the trajectories bit-for-bit.
//!
//! ```text
//! cargo test -p daskr --features cref
//! ```
#![cfg(feature = "cref")]
#![allow(non_snake_case, clippy::too_many_arguments, unsafe_op_in_unsafe_fn)]

use daskr::solver::{self, JacFn, PsolFn, ResFn, RtFn};

// C callback ABIs (Fortran-style, all by pointer).
type CRes = unsafe extern "C" fn(*mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut i32, *mut f64, *mut i32);
type CJac = unsafe extern "C" fn(*mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut i32);
type CPsol = unsafe extern "C" fn(*mut i32, *mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut i32, *mut f64, *mut f64, *mut i32, *mut f64, *mut i32);
type CRt = unsafe extern "C" fn(*mut i32, *mut f64, *mut f64, *mut f64, *mut i32, *mut f64, *mut f64, *mut i32);
// Krylov preconditioner-setup `jac`: (res, ires, neq, t, y, yprime, rewt, savr,
// wk, h, cj, wp, iwp, ier, rpar, ipar).
type CJacK = unsafe extern "C" fn(CRes, *mut i32, *mut i32, *mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut f64, *mut i32, *mut i32, *mut f64, *mut i32);

unsafe extern "C" {
    fn _daskr_xsetf_(mflag: *const i32);
    fn _daskr_ddaskr_(
        res: CRes,
        neq: *const i32,
        t: *mut f64,
        y: *mut f64,
        yprime: *mut f64,
        tout: *const f64,
        info: *mut i32,
        rtol: *mut f64,
        atol: *mut f64,
        idid: *mut i32,
        rwork: *mut f64,
        lrw: *const i32,
        iwork: *mut i32,
        liw: *const i32,
        rpar: *mut f64,
        ipar: *mut i32,
        jac: CJac,
        psol: CPsol,
        rt: CRt,
        nrt: *const i32,
        jroot: *mut i32,
    );
}

fn bits(a: f64) -> u64 {
    a.to_bits()
}

/// The reference C uses f2c `static` locals and is not reentrant, so every test
/// that calls into it must serialize through this single shared lock.
static SERIAL: std::sync::Mutex<()> = std::sync::Mutex::new(());

/// Run both drivers over the same `touts` with identical setup and assert the
/// trajectories (and counters) match bit-for-bit. Returns the final IDID.
fn compare(
    info0: [i32; 24],
    neq: i32,
    nrt: i32,
    y0: &[f64],
    yp0: &[f64],
    res_c: CRes,
    res_r: ResFn,
    jac_c: CJac,
    jac_r: JacFn,
    rt_c: CRt,
    rt_r: RtFn,
    psol_c: CPsol,
    psol_r: PsolFn,
    preset: impl Fn(&mut [i32]),
    touts: &[f64],
) -> i32 {
    let _guard = SERIAL.lock().unwrap_or_else(|e| e.into_inner());

    // Silence diagnostics in both implementations.
    unsafe { _daskr_xsetf_(&0) };
    daskr::aux::xsetf(0);

    let lrw = 600i32;
    let liw = 100i32;

    let (mut tc, mut yc, mut ypc) = (0.0f64, y0.to_vec(), yp0.to_vec());
    let mut infoc = info0;
    let mut rtolc = vec![1e-8f64; neq as usize];
    let mut atolc = vec![1e-8f64; neq as usize];
    let mut rworkc = vec![0.0f64; lrw as usize];
    let mut iworkc = vec![0i32; liw as usize];
    let (mut rparc, mut iparc) = ([0.0f64], [0i32]);
    let mut jrootc = vec![0i32; nrt.max(1) as usize];
    let mut ididc = 0i32;
    preset(&mut iworkc);

    let (mut tr, mut yr, mut ypr) = (0.0f64, y0.to_vec(), yp0.to_vec());
    let mut infor = info0;
    let mut rtolr = vec![1e-8f64; neq as usize];
    let mut atolr = vec![1e-8f64; neq as usize];
    let mut rworkr = vec![0.0f64; lrw as usize];
    let mut iworkr = vec![0i32; liw as usize];
    let (mut rparr, mut iparr) = ([0.0f64], [0i32]);
    let mut jrootr = vec![0i32; nrt.max(1) as usize];
    let mut ididr = 0i32;
    preset(&mut iworkr);

    for (kk, &tout) in touts.iter().enumerate() {
        unsafe {
            _daskr_ddaskr_(
                res_c, &neq, &mut tc, yc.as_mut_ptr(), ypc.as_mut_ptr(), &tout, infoc.as_mut_ptr(),
                rtolc.as_mut_ptr(), atolc.as_mut_ptr(), &mut ididc, rworkc.as_mut_ptr(), &lrw,
                iworkc.as_mut_ptr(), &liw, rparc.as_mut_ptr(), iparc.as_mut_ptr(), jac_c, psol_c,
                rt_c, &nrt, jrootc.as_mut_ptr(),
            );
            let mut toutr = tout;
            solver::ddaskr(
                res_r, neq, &mut tr, yr.as_mut_ptr(), ypr.as_mut_ptr(), &mut toutr,
                infor.as_mut_ptr(), rtolr.as_mut_ptr(), atolr.as_mut_ptr(), &mut ididr,
                rworkr.as_mut_ptr(), lrw, iworkr.as_mut_ptr(), liw, rparr.as_mut_ptr(),
                iparr.as_mut_ptr(), jac_r, solver::dummy_jack, psol_r, rt_r, nrt,
                jrootr.as_mut_ptr(),
            );
        }

        assert_eq!(ididc, ididr, "idid mismatch step {kk} tout={tout}");
        assert_eq!(bits(tc), bits(tr), "t mismatch step {kk}: C={tc} R={tr}");
        for i in 0..neq as usize {
            assert_eq!(bits(yc[i]), bits(yr[i]), "y[{i}] mismatch step {kk}: C={} R={}", yc[i], yr[i]);
            assert_eq!(bits(ypc[i]), bits(ypr[i]), "yp[{i}] mismatch step {kk}");
        }
        for j in 0..nrt as usize {
            assert_eq!(jrootc[j], jrootr[j], "jroot[{j}] mismatch step {kk}");
        }
        for &s in &[11i32, 12, 13, 14, 15, 7, 8] {
            assert_eq!(iworkc[(s - 1) as usize], iworkr[(s - 1) as usize], "iwork[{s}] mismatch step {kk}");
        }
        if ididc == 5 || ididc < 0 {
            break; // root reached, or a (matching) error: stop before re-calling
        }
    }
    ididr
}

// --- callbacks: damped oscillator G1=y1'-y2, G2=y2'+y1+0.1*y2 ----------------
#[inline]
fn osc_res(y: *const f64, yp: *const f64, d: *mut f64) {
    unsafe {
        *d.add(0) = *yp.add(0) - *y.add(1);
        *d.add(1) = *yp.add(1) + *y.add(0) + 0.1 * *y.add(1);
    }
}
unsafe extern "C" fn res_c(_t: *mut f64, y: *mut f64, yp: *mut f64, _cj: *mut f64, d: *mut f64, _i: *mut i32, _rp: *mut f64, _ip: *mut i32) {
    osc_res(y, yp, d);
}
unsafe fn res_r(_t: *mut f64, y: *mut f64, yp: *mut f64, _cj: *mut f64, d: *mut f64, _i: *mut i32, _rp: *mut f64, _ip: *mut i32) {
    osc_res(y, yp, d);
}

#[inline]
unsafe fn osc_jac(pd: *mut f64, cj: f64) {
    *pd.add(0) = cj;
    *pd.add(1) = 1.0;
    *pd.add(2) = -1.0;
    *pd.add(3) = 0.1 + cj;
}
unsafe extern "C" fn jac_c(_t: *mut f64, _y: *mut f64, _yp: *mut f64, pd: *mut f64, _d: *mut f64, cj: *mut f64, _h: *mut f64, _wt: *mut f64, _rp: *mut f64, _ip: *mut i32) {
    osc_jac(pd, *cj);
}
unsafe fn jac_r(_t: *mut f64, _y: *mut f64, _yp: *mut f64, pd: *mut f64, _d: *mut f64, cj: *mut f64, _h: *mut f64, _wt: *mut f64, _rp: *mut f64, _ip: *mut i32) {
    osc_jac(pd, *cj);
}

unsafe extern "C" fn rt_c(_neq: *mut i32, _t: *mut f64, y: *mut f64, _yp: *mut f64, _nrt: *mut i32, rval: *mut f64, _rp: *mut f64, _ip: *mut i32) {
    *rval.add(0) = *y.add(0);
}
unsafe fn rt_r(_neq: *mut i32, _t: *mut f64, y: *mut f64, _yp: *mut f64, _nrt: *mut i32, rval: *mut f64, _rp: *mut f64, _ip: *mut i32) {
    *rval.add(0) = *y.add(0);
}

// C dummies matching the typed ABIs.
unsafe extern "C" fn dummy_jac_c(_t: *mut f64, _y: *mut f64, _yp: *mut f64, _pd: *mut f64, _d: *mut f64, _cj: *mut f64, _h: *mut f64, _wt: *mut f64, _rp: *mut f64, _ip: *mut i32) {}
unsafe extern "C" fn dummy_rt_c(_neq: *mut i32, _t: *mut f64, _y: *mut f64, _yp: *mut f64, _nrt: *mut i32, _rval: *mut f64, _rp: *mut f64, _ip: *mut i32) {}
unsafe extern "C" fn dummy_psol_c(_neq: *mut i32, _t: *mut f64, _y: *mut f64, _yp: *mut f64, _savr: *mut f64, _wk: *mut f64, _cj: *mut f64, _wt: *mut f64, _wp: *mut f64, _iwp: *mut i32, _b: *mut f64, _eplin: *mut f64, _ier: *mut i32, _rp: *mut f64, _ip: *mut i32) {}

// Identity left preconditioner P = I for the Krylov path: solving P*x = b
// leaves `b` untouched. INFO(15)=0 means JAC is never called, so no setup.
unsafe extern "C" fn id_psol_c(_neq: *mut i32, _t: *mut f64, _y: *mut f64, _yp: *mut f64, _savr: *mut f64, _wk: *mut f64, _cj: *mut f64, _wt: *mut f64, _wp: *mut f64, _iwp: *mut i32, _b: *mut f64, _eplin: *mut f64, ier: *mut i32, _rp: *mut f64, _ip: *mut i32) {
    *ier = 0;
}
unsafe fn id_psol_r(_neq: *mut i32, _t: *mut f64, _y: *mut f64, _yp: *mut f64, _savr: *mut f64, _wk: *mut f64, _cj: *mut f64, _wt: *mut f64, _wp: *mut f64, _iwp: *mut i32, _b: *mut f64, _eplin: *mut f64, ier: *mut i32, _rp: *mut f64, _ip: *mut i32) {
    *ier = 0;
}

// --- diagonal left preconditioner P = diag(A), A = dG/dY + cj*dG/dYPRIME ------
// For the oscillator A = [[cj, -1],[1, 0.1+cj]], so diag(A) = [cj, 0.1+cj].
// JAC stores the two diagonal entries in WP (LENWP=2); PSOL divides b by them.
#[inline]
unsafe fn diag_jac(cj: f64, wp: *mut f64) {
    *wp.add(0) = cj;
    *wp.add(1) = 0.1 + cj;
}
#[inline]
unsafe fn diag_solve(wp: *const f64, b: *mut f64) {
    *b.add(0) /= *wp.add(0);
    *b.add(1) /= *wp.add(1);
}
unsafe extern "C" fn jack_c(_res: CRes, _ires: *mut i32, _neq: *mut i32, _t: *mut f64, _y: *mut f64, _yp: *mut f64, _rewt: *mut f64, _savr: *mut f64, _wk: *mut f64, _h: *mut f64, cj: *mut f64, wp: *mut f64, _iwp: *mut i32, ier: *mut i32, _rp: *mut f64, _ip: *mut i32) {
    diag_jac(*cj, wp);
    *ier = 0;
}
unsafe fn jack_r(_res: ResFn, _ires: *mut i32, _neq: *mut i32, _t: *mut f64, _y: *mut f64, _yp: *mut f64, _rewt: *mut f64, _savr: *mut f64, _wk: *mut f64, _h: *mut f64, cj: *mut f64, wp: *mut f64, _iwp: *mut i32, ier: *mut i32, _rp: *mut f64, _ip: *mut i32) {
    diag_jac(*cj, wp);
    *ier = 0;
}
unsafe extern "C" fn pre_psol_c(_neq: *mut i32, _t: *mut f64, _y: *mut f64, _yp: *mut f64, _savr: *mut f64, _wk: *mut f64, _cj: *mut f64, _wt: *mut f64, wp: *mut f64, _iwp: *mut i32, b: *mut f64, _eplin: *mut f64, ier: *mut i32, _rp: *mut f64, _ip: *mut i32) {
    diag_solve(wp, b);
    *ier = 0;
}
unsafe fn pre_psol_r(_neq: *mut i32, _t: *mut f64, _y: *mut f64, _yp: *mut f64, _savr: *mut f64, _wk: *mut f64, _cj: *mut f64, _wt: *mut f64, wp: *mut f64, _iwp: *mut i32, b: *mut f64, _eplin: *mut f64, ier: *mut i32, _rp: *mut f64, _ip: *mut i32) {
    diag_solve(wp, b);
    *ier = 0;
}

/// Krylov with a real preconditioner (INFO(12)=1, INFO(15)=1): the `jack`
/// routine computes diagonal preconditioner data into WP and `psol` applies it.
/// This is the only path that exercises the JAC/WP/IWP setup threading
/// (LENWP=IWORK(27)) through the driver, `dnsk`'s `jcalc` logic, and `dslvk`'s
/// preconditioner call. Cross-checked against the C bit-for-bit.
#[test]
fn krylov_preconditioned() {
    let _guard = SERIAL.lock().unwrap_or_else(|e| e.into_inner());
    unsafe { _daskr_xsetf_(&0) };
    daskr::aux::xsetf(0);

    let (neq, nrt) = (2i32, 0i32);
    let (lrw, liw) = (600i32, 100i32);
    let mut info = [0i32; 24];
    info[11] = 1; // INFO(12)=1 -> Krylov
    info[14] = 1; // INFO(15)=1 -> JAC supplied for preconditioner setup

    let (y0, yp0) = ([1.0f64, 0.0], [0.0f64, -1.0]);
    let touts = touts();

    let (mut tc, mut yc, mut ypc) = (0.0, y0.to_vec(), yp0.to_vec());
    let (mut infoc, mut ididc) = (info, 0i32);
    let (mut rtolc, mut atolc) = (vec![1e-8; 2], vec![1e-8; 2]);
    let mut rworkc = vec![0.0; lrw as usize];
    let mut iworkc = vec![0i32; liw as usize];
    iworkc[26] = neq; // IWORK(27) = LENWP = 2
    let (mut rparc, mut iparc, mut jrootc) = ([0.0], [0i32], [0i32]);

    let (mut tr, mut yr, mut ypr) = (0.0, y0.to_vec(), yp0.to_vec());
    let (mut infor, mut ididr) = (info, 0i32);
    let (mut rtolr, mut atolr) = (vec![1e-8; 2], vec![1e-8; 2]);
    let mut rworkr = vec![0.0; lrw as usize];
    let mut iworkr = vec![0i32; liw as usize];
    iworkr[26] = neq;
    let (mut rparr, mut iparr, mut jrootr) = ([0.0], [0i32], [0i32]);

    for (kk, &tout) in touts.iter().enumerate() {
        unsafe {
            _daskr_ddaskr_(
                res_c, &neq, &mut tc, yc.as_mut_ptr(), ypc.as_mut_ptr(), &tout, infoc.as_mut_ptr(),
                rtolc.as_mut_ptr(), atolc.as_mut_ptr(), &mut ididc, rworkc.as_mut_ptr(), &lrw,
                iworkc.as_mut_ptr(), &liw, rparc.as_mut_ptr(), iparc.as_mut_ptr(),
                std::mem::transmute::<CJacK, CJac>(jack_c), pre_psol_c, dummy_rt_c, &nrt, jrootc.as_mut_ptr(),
            );
            let mut toutr = tout;
            solver::ddaskr(
                res_r, neq, &mut tr, yr.as_mut_ptr(), ypr.as_mut_ptr(), &mut toutr,
                infor.as_mut_ptr(), rtolr.as_mut_ptr(), atolr.as_mut_ptr(), &mut ididr,
                rworkr.as_mut_ptr(), lrw, iworkr.as_mut_ptr(), liw, rparr.as_mut_ptr(),
                iparr.as_mut_ptr(), solver::dummy_jacd, jack_r, pre_psol_r, solver::dummy_rt, nrt,
                jrootr.as_mut_ptr(),
            );
        }
        assert_eq!(ididc, ididr, "idid mismatch step {kk} tout={tout}");
        assert_eq!(bits(tc), bits(tr), "t mismatch step {kk}: C={tc} R={tr}");
        for i in 0..neq as usize {
            assert_eq!(bits(yc[i]), bits(yr[i]), "y[{i}] mismatch step {kk}: C={} R={}", yc[i], yr[i]);
            assert_eq!(bits(ypc[i]), bits(ypr[i]), "yp[{i}] mismatch step {kk}");
        }
        for &s in &[11i32, 12, 13, 14, 15, 7, 8] {
            assert_eq!(iworkc[(s - 1) as usize], iworkr[(s - 1) as usize], "iwork[{s}] mismatch step {kk}");
        }
        if ididc < 0 {
            break;
        }
    }
    assert!(ididr > 0, "Krylov-preconditioned integration failed: IDID={ididr}");
}

fn touts() -> Vec<f64> {
    (1..=40).map(|k| 0.25 * k as f64).collect()
}

#[test]
fn dense_numerical() {
    compare([0; 24], 2, 0, &[1.0, 0.0], &[0.0, -1.0], res_c, res_r, dummy_jac_c, solver::dummy_jacd, dummy_rt_c, solver::dummy_rt, dummy_psol_c, solver::dummy_psol, |_| {}, &touts());
}

#[test]
fn dense_analytic_jacobian() {
    let mut info = [0; 24];
    info[4] = 1; // INFO(5)=1
    compare(info, 2, 0, &[1.0, 0.0], &[0.0, -1.0], res_c, res_r, jac_c, jac_r, dummy_rt_c, solver::dummy_rt, dummy_psol_c, solver::dummy_psol, |_| {}, &touts());
}

#[test]
fn banded_numerical() {
    let mut info = [0; 24];
    info[5] = 1; // INFO(6)=1
    compare(info, 2, 0, &[1.0, 0.0], &[0.0, -1.0], res_c, res_r, dummy_jac_c, solver::dummy_jacd, dummy_rt_c, solver::dummy_rt, dummy_psol_c, solver::dummy_psol, |iw| { iw[0] = 1; iw[1] = 1; }, &touts());
}

#[test]
fn initial_condition_calc() {
    let mut info = [0; 24];
    info[10] = 1; // INFO(11)=1
    let idid = compare(info, 2, 0, &[1.0, 0.0], &[5.0, 5.0], res_c, res_r, dummy_jac_c, solver::dummy_jacd, dummy_rt_c, solver::dummy_rt, dummy_psol_c, solver::dummy_psol, |iw| { iw[40] = 1; iw[41] = 1; }, &touts());
    assert_eq!(idid, 3);
}

#[test]
fn root_finding() {
    let idid = compare([0; 24], 2, 1, &[1.0, 0.0], &[0.0, -1.0], res_c, res_r, dummy_jac_c, solver::dummy_jacd, rt_c, rt_r, dummy_psol_c, solver::dummy_psol, |_| {}, &touts());
    assert_eq!(idid, 5);
}

/// Krylov (SPIGMR) linear-solver path: INFO(12)=1 with an identity left
/// preconditioner (INFO(15)=0, so JAC is unused). Exercises dnsk/dslvk/dspigm/
/// datv/dorth/dheqr/dhels and dnsik — none of which the direct-method tests
/// above touch — and checks they match the C bit-for-bit.
#[test]
fn krylov_numerical() {
    let mut info = [0; 24];
    info[11] = 1; // INFO(12)=1 -> Krylov method
    compare(info, 2, 0, &[1.0, 0.0], &[0.0, -1.0], res_c, res_r, dummy_jac_c, solver::dummy_jacd, dummy_rt_c, solver::dummy_rt, id_psol_c, id_psol_r, |_| {}, &touts());
}

/// Krylov path combined with the initial-condition calculation (INFO(11)=1),
/// which routes through `dnsik`/`ddasik` rather than `dnsid`/`ddasid`.
#[test]
fn krylov_initial_condition_calc() {
    let mut info = [0; 24];
    info[10] = 1; // INFO(11)=1 -> compute consistent initial conditions
    info[11] = 1; // INFO(12)=1 -> Krylov method
    let idid = compare(info, 2, 0, &[1.0, 0.0], &[5.0, 5.0], res_c, res_r, dummy_jac_c, solver::dummy_jacd, dummy_rt_c, solver::dummy_rt, id_psol_c, id_psol_r, |iw| { iw[40] = 1; iw[41] = 1; }, &touts());
    assert_eq!(idid, 3);
}
