//! Every routine run side by side with the **system** LAPACK on the same inputs:
//! `cargo test --features reference-lapack`. Where `tests/reference.rs` pins
//! values checked by hand once, this covers the routines that have none.
//!
//! Off by default (needs `liblapack.so`) and never with `fortran-abi`, which
//! defines the same `d*_` symbols.
//!
//! Deterministic factorizations are compared element by element; where the
//! mathematics leaves freedom, the invariant is compared instead — eigenvalues as
//! sorted lists, singular vectors up to sign, a Schur form by its eigenvalues.
#![cfg(feature = "reference-lapack")]
#![allow(non_snake_case)]

use core::ffi::c_char;

use openmodelica_lapack as om;

#[link(name = "lapack")]
unsafe extern "C" {
    fn dgesv_(n: *const i32, nrhs: *const i32, a: *mut f64, lda: *const i32, ipiv: *mut i32,
              b: *mut f64, ldb: *const i32, info: *mut i32);
    fn dgetrf_(m: *const i32, n: *const i32, a: *mut f64, lda: *const i32, ipiv: *mut i32,
               info: *mut i32);
    fn dgetrs_(trans: *const c_char, n: *const i32, nrhs: *const i32, a: *const f64,
               lda: *const i32, ipiv: *const i32, b: *mut f64, ldb: *const i32, info: *mut i32);
    fn dgetri_(n: *const i32, a: *mut f64, lda: *const i32, ipiv: *const i32, work: *mut f64,
               lwork: *const i32, info: *mut i32);
    fn dgecon_(norm: *const c_char, n: *const i32, a: *const f64, lda: *const i32,
               anorm: *const f64, rcond: *mut f64, work: *mut f64, iwork: *mut i32,
               info: *mut i32);
    fn dlange_(norm: *const c_char, m: *const i32, n: *const i32, a: *const f64, lda: *const i32,
               work: *mut f64) -> f64;
    fn dpotrf_(uplo: *const c_char, n: *const i32, a: *mut f64, lda: *const i32, info: *mut i32);
    fn dpotrs_(uplo: *const c_char, n: *const i32, nrhs: *const i32, a: *const f64,
               lda: *const i32, b: *mut f64, ldb: *const i32, info: *mut i32);
    fn dgeqrf_(m: *const i32, n: *const i32, a: *mut f64, lda: *const i32, tau: *mut f64,
               work: *mut f64, lwork: *const i32, info: *mut i32);
    fn dgeqp3_(m: *const i32, n: *const i32, a: *mut f64, lda: *const i32, jpvt: *mut i32,
               tau: *mut f64, work: *mut f64, lwork: *const i32, info: *mut i32);
    fn dorgqr_(m: *const i32, n: *const i32, k: *const i32, a: *mut f64, lda: *const i32,
               tau: *const f64, work: *mut f64, lwork: *const i32, info: *mut i32);
    fn dormqr_(side: *const c_char, trans: *const c_char, m: *const i32, n: *const i32,
               k: *const i32, a: *const f64, lda: *const i32, tau: *const f64, c: *mut f64,
               ldc: *const i32, work: *mut f64, lwork: *const i32, info: *mut i32);
    fn dgels_(trans: *const c_char, m: *const i32, n: *const i32, nrhs: *const i32, a: *mut f64,
              lda: *const i32, b: *mut f64, ldb: *const i32, work: *mut f64, lwork: *const i32,
              info: *mut i32);
    fn dgelsy_(m: *const i32, n: *const i32, nrhs: *const i32, a: *mut f64, lda: *const i32,
               b: *mut f64, ldb: *const i32, jpvt: *mut i32, rcond: *const f64, rank: *mut i32,
               work: *mut f64, lwork: *const i32, info: *mut i32);
    fn dgglse_(m: *const i32, n: *const i32, p: *const i32, a: *mut f64, lda: *const i32,
               b: *mut f64, ldb: *const i32, c: *mut f64, d: *mut f64, x: *mut f64,
               work: *mut f64, lwork: *const i32, info: *mut i32);
    fn dgesvd_(jobu: *const c_char, jobvt: *const c_char, m: *const i32, n: *const i32,
               a: *mut f64, lda: *const i32, s: *mut f64, u: *mut f64, ldu: *const i32,
               vt: *mut f64, ldvt: *const i32, work: *mut f64, lwork: *const i32,
               info: *mut i32);
    fn dgeev_(jobvl: *const c_char, jobvr: *const c_char, n: *const i32, a: *mut f64,
              lda: *const i32, wr: *mut f64, wi: *mut f64, vl: *mut f64, ldvl: *const i32,
              vr: *mut f64, ldvr: *const i32, work: *mut f64, lwork: *const i32, info: *mut i32);
    fn dgehrd_(n: *const i32, ilo: *const i32, ihi: *const i32, a: *mut f64, lda: *const i32,
               tau: *mut f64, work: *mut f64, lwork: *const i32, info: *mut i32);
    fn dorghr_(n: *const i32, ilo: *const i32, ihi: *const i32, a: *mut f64, lda: *const i32,
               tau: *const f64, work: *mut f64, lwork: *const i32, info: *mut i32);
    fn dhseqr_(job: *const c_char, compz: *const c_char, n: *const i32, ilo: *const i32,
               ihi: *const i32, h: *mut f64, ldh: *const i32, wr: *mut f64, wi: *mut f64,
               z: *mut f64, ldz: *const i32, work: *mut f64, lwork: *const i32, info: *mut i32);
    fn dtrsyl_(trana: *const c_char, tranb: *const c_char, isgn: *const i32, m: *const i32,
               n: *const i32, a: *const f64, lda: *const i32, b: *const f64, ldb: *const i32,
               c: *mut f64, ldc: *const i32, scale: *mut f64, info: *mut i32);
    fn dgtsv_(n: *const i32, nrhs: *const i32, dl: *mut f64, d: *mut f64, du: *mut f64,
              b: *mut f64, ldb: *const i32, info: *mut i32);
    fn dgbsv_(n: *const i32, kl: *const i32, ku: *const i32, nrhs: *const i32, ab: *mut f64,
              ldab: *const i32, ipiv: *mut i32, b: *mut f64, ldb: *const i32, info: *mut i32);
    fn dgegv_(jobvl: *const c_char, jobvr: *const c_char, n: *const i32, a: *mut f64,
              lda: *const i32, b: *mut f64, ldb: *const i32, alphar: *mut f64, alphai: *mut f64,
              beta: *mut f64, vl: *mut f64, ldvl: *const i32, vr: *mut f64, ldvr: *const i32,
              work: *mut f64, lwork: *const i32, info: *mut i32);
    fn dgelsx_(m: *const i32, n: *const i32, nrhs: *const i32, a: *mut f64, lda: *const i32,
               b: *mut f64, ldb: *const i32, jpvt: *mut i32, rcond: *const f64, rank: *mut i32,
               work: *mut f64, info: *mut i32);
    fn dgeqpf_(m: *const i32, n: *const i32, a: *mut f64, lda: *const i32, jpvt: *mut i32,
               tau: *mut f64, work: *mut f64, info: *mut i32);
}

// ───────────────────────────── harness ─────────────────────────────

/// A deterministic well-conditioned pseudo-random matrix. A fixed LCG rather than
/// a dependency, and diagonally dominated so the comparison is about the
/// algorithms and not about which one loses a badly conditioned problem first.
fn rand_mat(m: usize, n: usize, seed: u64) -> Vec<f64> {
    let mut s = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
    let mut next = || {
        s = s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((s >> 33) as f64 / (1u64 << 31) as f64) - 1.0
    };
    let mut a = vec![0.0; m * n];
    for j in 0..n {
        for i in 0..m {
            a[i + j * m] = next();
        }
    }
    for i in 0..m.min(n) {
        a[i + i * m] += m as f64;
    }
    a
}

/// A symmetric positive-definite matrix, for the Cholesky routines.
fn spd(n: usize, seed: u64) -> Vec<f64> {
    let b = rand_mat(n, n, seed);
    let mut a = vec![0.0; n * n];
    for j in 0..n {
        for i in 0..n {
            a[i + j * n] = (0..n).map(|k| b[i + k * n] * b[j + k * n]).sum::<f64>();
        }
    }
    a
}

const TOL: f64 = 1e-9;

fn same(got: &[f64], want: &[f64], what: &str) {
    assert_eq!(got.len(), want.len(), "{what}: length");
    let scale = want.iter().fold(1.0f64, |m, v| m.max(v.abs()));
    for (i, (g, w)) in got.iter().zip(want).enumerate() {
        assert!(
            (g - w).abs() <= TOL * scale,
            "{what}[{i}]: got {g}, LAPACK {w}\n  got    {got:?}\n  LAPACK {want:?}"
        );
    }
}

fn same_i(got: &[i32], want: &[i32], what: &str) {
    assert_eq!(got, want, "{what}");
}

/// Column by column, allowing the sign freedom every orthogonal factor has.
fn same_up_to_sign(got: &[f64], want: &[f64], m: usize, n: usize, what: &str) {
    for j in 0..n {
        let (g, w) = (&got[j * m..j * m + m], &want[j * m..j * m + m]);
        let dot: f64 = g.iter().zip(w).map(|(a, b)| a * b).sum();
        let s = if dot < 0.0 { -1.0 } else { 1.0 };
        let flipped: Vec<f64> = g.iter().map(|v| v * s).collect();
        same(&flipped, w, &format!("{what} column {j}"));
    }
}

/// LAPACK's `d*_` take everything by reference; these keep the call sites short.
fn i(v: usize) -> i32 {
    v as i32
}
fn c(s: &str) -> c_char {
    s.as_bytes()[0] as c_char
}

// ───────────────────────────── LU family ─────────────────────────────

#[test]
fn dgetrf_matches() {
    for (m, n) in [(5, 5), (7, 4), (4, 7), (1, 1)] {
        let a0 = rand_mat(m, n, 11 + m as u64 * 10 + n as u64);
        let (mut a, mut want) = (a0.clone(), a0.clone());
        let mut ipiv = vec![0i32; m.min(n)];
        let mut wipiv = vec![0i32; m.min(n)];
        let mut winfo = 0;
        let info = om::dgetrf(m, n, &mut a, m, &mut ipiv);
        unsafe { dgetrf_(&i(m), &i(n), want.as_mut_ptr(), &i(m), wipiv.as_mut_ptr(), &mut winfo) };
        assert_eq!(info, winfo, "dgetrf {m}x{n}: INFO");
        same_i(&ipiv, &wipiv, &format!("dgetrf {m}x{n}: IPIV"));
        same(&a, &want, &format!("dgetrf {m}x{n}: packed L\\U"));
    }
}

#[test]
fn dgesv_matches() {
    let n = 6;
    let a0 = rand_mat(n, n, 21);
    let b0 = rand_mat(n, 2, 22);
    let (mut a, mut want_a) = (a0.clone(), a0.clone());
    let (mut b, mut want_b) = (b0.clone(), b0.clone());
    let (mut ipiv, mut wipiv) = (vec![0i32; n], vec![0i32; n]);
    let mut winfo = 0;
    let info = om::dgesv(n, 2, &mut a, n, &mut ipiv, &mut b, n);
    unsafe {
        dgesv_(&i(n), &i(2), want_a.as_mut_ptr(), &i(n), wipiv.as_mut_ptr(), want_b.as_mut_ptr(),
               &i(n), &mut winfo)
    };
    assert_eq!(info, winfo, "dgesv: INFO");
    same_i(&ipiv, &wipiv, "dgesv: IPIV");
    same(&a, &want_a, "dgesv: factored A");
    same(&b, &want_b, "dgesv: X");
}

#[test]
fn dgetrs_matches() {
    let n = 5;
    let a0 = rand_mat(n, n, 31);
    let b0 = rand_mat(n, 3, 32);
    let (mut lu, mut ipiv) = (a0.clone(), vec![0i32; n]);
    om::dgetrf(n, n, &mut lu, n, &mut ipiv);
    for t in ["N", "T"] {
        let (mut b, mut want) = (b0.clone(), b0.clone());
        let mut winfo = 0;
        let info = om::dgetrs(t, n, 3, &lu, n, &ipiv, &mut b, n);
        unsafe {
            dgetrs_(&c(t), &i(n), &i(3), lu.as_ptr(), &i(n), ipiv.as_ptr(), want.as_mut_ptr(),
                    &i(n), &mut winfo)
        };
        assert_eq!(info, winfo, "dgetrs {t}: INFO");
        same(&b, &want, &format!("dgetrs {t}: X"));
    }
}

#[test]
fn dgetri_matches() {
    let n = 5;
    let a0 = rand_mat(n, n, 41);
    let (mut lu, mut ipiv) = (a0.clone(), vec![0i32; n]);
    om::dgetrf(n, n, &mut lu, n, &mut ipiv);
    let (mut inv, mut want) = (lu.clone(), lu.clone());
    let (mut work, mut winfo) = (vec![0.0f64; n * 64], 0);
    let info = om::dgetri(n, &mut inv, n, &ipiv);
    unsafe {
        dgetri_(&i(n), want.as_mut_ptr(), &i(n), ipiv.as_ptr(), work.as_mut_ptr(),
                &i(n * 64), &mut winfo)
    };
    assert_eq!(info, winfo, "dgetri: INFO");
    same(&inv, &want, "dgetri: A^-1");
}

#[test]
fn dlange_matches() {
    let (m, n) = (5, 4);
    let a = rand_mat(m, n, 51);
    let mut work = vec![0.0f64; m];
    for norm in ["1", "I", "F", "M"] {
        let got = om::dlange(norm, m, n, &a, m);
        let want =
            unsafe { dlange_(&c(norm), &i(m), &i(n), a.as_ptr(), &i(m), work.as_mut_ptr()) };
        same(&[got], &[want], &format!("dlange '{norm}'"));
    }
}

#[test]
fn dgecon_matches() {
    let n = 5;
    let a0 = rand_mat(n, n, 61);
    let mut work = vec![0.0f64; 4 * n];
    let mut iwork = vec![0i32; n];
    for norm in ["1", "I"] {
        let anorm =
            unsafe { dlange_(&c(norm), &i(n), &i(n), a0.as_ptr(), &i(n), work.as_mut_ptr()) };
        let (mut lu, mut ipiv) = (a0.clone(), vec![0i32; n]);
        om::dgetrf(n, n, &mut lu, n, &mut ipiv);
        let (got, info) = om::dgecon(norm, n, &lu, n, anorm);
        let (mut want, mut winfo) = (0.0f64, 0);
        unsafe {
            dgecon_(&c(norm), &i(n), lu.as_ptr(), &i(n), &anorm, &mut want, work.as_mut_ptr(),
                    iwork.as_mut_ptr(), &mut winfo)
        };
        assert_eq!(info, winfo, "dgecon '{norm}': INFO");
        // The condition estimator is a heuristic (DLACN2's random restarts), so
        // the two need only agree on the order of magnitude.
        assert!(
            got > 0.0 && want > 0.0 && (got / want).log10().abs() < 1.0,
            "dgecon '{norm}': got {got}, LAPACK {want}"
        );
    }
}

// ───────────────────────────── Cholesky ─────────────────────────────

#[test]
fn dpotrf_dpotrs_match() {
    let n = 5;
    let a0 = spd(n, 71);
    let b0 = rand_mat(n, 2, 72);
    for uplo in ["U", "L"] {
        let (mut a, mut want) = (a0.clone(), a0.clone());
        let mut winfo = 0;
        let info = om::dpotrf(uplo, n, &mut a, n);
        unsafe { dpotrf_(&c(uplo), &i(n), want.as_mut_ptr(), &i(n), &mut winfo) };
        assert_eq!(info, winfo, "dpotrf {uplo}: INFO");
        // Only the named triangle is defined; the other keeps the input.
        for j in 0..n {
            for r in 0..n {
                let in_tri = if uplo == "U" { r <= j } else { r >= j };
                if in_tri {
                    same(&[a[r + j * n]], &[want[r + j * n]], &format!("dpotrf {uplo} ({r},{j})"));
                }
            }
        }
        let (mut b, mut wb) = (b0.clone(), b0.clone());
        let info = om::dpotrs(uplo, n, 2, &a, n, &mut b, n);
        unsafe {
            dpotrs_(&c(uplo), &i(n), &i(2), want.as_ptr(), &i(n), wb.as_mut_ptr(), &i(n),
                    &mut winfo)
        };
        assert_eq!(info, winfo, "dpotrs {uplo}: INFO");
        same(&b, &wb, &format!("dpotrs {uplo}: X"));
    }
}

// ───────────────────────────── QR family ─────────────────────────────

#[test]
fn dgeqrf_matches() {
    for (m, n) in [(6, 4), (4, 6), (5, 5)] {
        let a0 = rand_mat(m, n, 81 + m as u64);
        let (mut a, mut want) = (a0.clone(), a0.clone());
        let (mut tau, mut wtau) = (vec![0.0f64; m.min(n)], vec![0.0f64; m.min(n)]);
        let (mut work, mut winfo) = (vec![0.0f64; n * 64], 0);
        om::dgeqrf(m, n, &mut a, m, &mut tau);
        unsafe {
            dgeqrf_(&i(m), &i(n), want.as_mut_ptr(), &i(m), wtau.as_mut_ptr(),
                    work.as_mut_ptr(), &i(n * 64), &mut winfo)
        };
        same(&tau, &wtau, &format!("dgeqrf {m}x{n}: TAU"));
        same(&a, &want, &format!("dgeqrf {m}x{n}: packed R and reflectors"));
    }
}

#[test]
fn dorgqr_matches() {
    let (m, n) = (6, 4);
    let a0 = rand_mat(m, n, 91);
    let (mut a, mut want) = (a0.clone(), a0.clone());
    let (mut tau, mut wtau) = (vec![0.0f64; n], vec![0.0f64; n]);
    let (mut work, mut winfo) = (vec![0.0f64; n * 64], 0);
    om::dgeqrf(m, n, &mut a, m, &mut tau);
    unsafe {
        dgeqrf_(&i(m), &i(n), want.as_mut_ptr(), &i(m), wtau.as_mut_ptr(), work.as_mut_ptr(),
                &i(n * 64), &mut winfo)
    };
    om::dorgqr(m, n, n, &mut a, m, &tau);
    unsafe {
        dorgqr_(&i(m), &i(n), &i(n), want.as_mut_ptr(), &i(m), wtau.as_ptr(),
                work.as_mut_ptr(), &i(n * 64), &mut winfo)
    };
    same(&a, &want, "dorgqr: Q");
}

#[test]
fn dormqr_matches() {
    let (m, n) = (5, 5);
    let a0 = rand_mat(m, n, 101);
    let c0 = rand_mat(m, 3, 102);
    let (mut qr, mut wqr) = (a0.clone(), a0.clone());
    let (mut tau, mut wtau) = (vec![0.0f64; n], vec![0.0f64; n]);
    let (mut work, mut winfo) = (vec![0.0f64; 64 * n], 0);
    om::dgeqrf(m, n, &mut qr, m, &mut tau);
    unsafe {
        dgeqrf_(&i(m), &i(n), wqr.as_mut_ptr(), &i(m), wtau.as_mut_ptr(), work.as_mut_ptr(),
                &i(64 * n), &mut winfo)
    };
    for trans in ["N", "T"] {
        let (mut cc, mut wc) = (c0.clone(), c0.clone());
        om::dormqr("L", trans, m, 3, n, &qr, m, &tau, &mut cc, m);
        unsafe {
            dormqr_(&c("L"), &c(trans), &i(m), &i(3), &i(n), wqr.as_ptr(), &i(m), wtau.as_ptr(),
                    wc.as_mut_ptr(), &i(m), work.as_mut_ptr(), &i(64 * n), &mut winfo)
        };
        same(&cc, &wc, &format!("dormqr L/{trans}"));
    }
}

#[test]
fn dgeqp3_permutation_matches() {
    let (m, n) = (6, 4);
    let a0 = rand_mat(m, n, 111);
    let (mut a, mut want) = (a0.clone(), a0.clone());
    let (mut jpvt, mut wjpvt) = (vec![0i32; n], vec![0i32; n]);
    let (mut tau, mut wtau) = (vec![0.0f64; n], vec![0.0f64; n]);
    let (mut work, mut winfo) = (vec![0.0f64; 64 * n], 0);
    om::dgeqp3(m, n, &mut a, m, &mut jpvt, &mut tau);
    unsafe {
        dgeqp3_(&i(m), &i(n), want.as_mut_ptr(), &i(m), wjpvt.as_mut_ptr(), wtau.as_mut_ptr(),
                work.as_mut_ptr(), &i(64 * n), &mut winfo)
    };
    // The pivot order is what `Matrices.QR` returns to Modelica, so it must be
    // LAPACK's; `R` follows from it.
    same_i(&jpvt, &wjpvt, "dgeqp3: JPVT");
    same(&tau, &wtau, "dgeqp3: TAU");
    same(&a, &want, "dgeqp3: packed R and reflectors");
}

#[test]
fn dgels_matches() {
    for (m, n) in [(6, 3), (3, 6)] {
        let a0 = rand_mat(m, n, 121 + m as u64);
        let ldb = m.max(n);
        let b0 = rand_mat(ldb, 2, 122);
        let (mut a, mut wa) = (a0.clone(), a0.clone());
        let (mut b, mut wb) = (b0.clone(), b0.clone());
        let (mut work, mut winfo) = (vec![0.0f64; 64 * ldb], 0);
        let info = om::dgels("N", m, n, 2, &mut a, m, &mut b, ldb);
        unsafe {
            dgels_(&c("N"), &i(m), &i(n), &i(2), wa.as_mut_ptr(), &i(m), wb.as_mut_ptr(),
                   &i(ldb), work.as_mut_ptr(), &i(64 * ldb), &mut winfo)
        };
        assert_eq!(info, winfo, "dgels {m}x{n}: INFO");
        // Only the solution is compared: this crate factors `A` differently (and
        // does not leave `A` factored), while `X` is unique for a full-rank `A`.
        for j in 0..2 {
            same(&b[j * ldb..j * ldb + n], &wb[j * ldb..j * ldb + n], &format!("dgels {m}x{n}: X"));
        }
    }
}

#[test]
fn dgelsy_matches() {
    // Full rank, rank deficient and underdetermined: only a case whose trailing
    // columns vanish shows whether the rank came from DLAIC1. The last two are
    // ModelicaTest.Math.Matrices' own `leastSquares` inputs.
    let cases: &[(usize, usize, Vec<f64>, u64)] = &[
        (6, 3, rand_mat(6, 3, 131), 132),
        (3, 6, rand_mat(3, 6, 133), 134),
        (6, 4, {
            // Column 3 = column 0 + column 1: rank 3 of 4.
            let mut a = rand_mat(6, 4, 135);
            for r in 0..6 {
                a[r + 3 * 6] = a[r] + a[r + 6];
            }
            a
        }, 136),
        (2, 3, vec![1.0, 4.0, 2.0, 5.0, 3.0, 6.0], 137),
        (2, 3, vec![1.0, 4.0, 0.0, 0.0, 0.0, 0.0], 138),
    ];
    for (m, n, a0, bseed) in cases {
        let (m, n) = (*m, *n);
        let ldb = m.max(n);
        let b0 = rand_mat(ldb, 2, *bseed);
        let (mut a, mut wa) = (a0.clone(), a0.clone());
        let (mut b, mut wb) = (b0.clone(), b0.clone());
        let (mut jpvt, mut wjpvt) = (vec![0i32; n], vec![0i32; n]);
        let (mut work, mut winfo, mut wrank) = (vec![0.0f64; 64 * ldb.max(m)], 0, 0);
        let rcond = 100.0 * f64::EPSILON;
        let what = format!("dgelsy {m}x{n}");
        let (rank, info) = om::dgelsy(m, n, 2, &mut a, m, &mut b, ldb, &mut jpvt, rcond);
        unsafe {
            dgelsy_(&i(m), &i(n), &i(2), wa.as_mut_ptr(), &i(m), wb.as_mut_ptr(), &i(ldb),
                    wjpvt.as_mut_ptr(), &rcond, &mut wrank, work.as_mut_ptr(),
                    &i(64 * ldb.max(m)), &mut winfo)
        };
        assert_eq!(info, winfo, "{what}: INFO");
        assert_eq!(rank as i32, wrank, "{what}: RANK");
        for j in 0..2 {
            same(&b[j * ldb..j * ldb + n], &wb[j * ldb..j * ldb + n], &format!("{what}: X"));
        }
        // Pivots only where they are determined: the deficient case below leaves
        // two columns with equal residual norms, and rounding breaks that tie.
        // Either choice spans the same subspace, which is why X matched anyway.
        if rank == m.min(n) {
            same_i(&jpvt, &wjpvt, &format!("{what}: JPVT"));
        }
    }
}

#[test]
fn dgglse_matches() {
    let (m, n, p) = (6, 4, 2);
    let a0 = rand_mat(m, n, 141);
    let b0 = rand_mat(p, n, 142);
    let c0 = rand_mat(m, 1, 143);
    let d0 = rand_mat(p, 1, 144);
    let (mut wa, mut wb) = (a0.clone(), b0.clone());
    let (mut wc, mut wd) = (c0.clone(), d0.clone());
    let (mut x, mut wx) = (vec![0.0f64; n], vec![0.0f64; n]);
    let (mut work, mut winfo) = (vec![0.0f64; 64 * (m + n + p)], 0);
    let info = om::dgglse(m, n, p, &a0, m, &b0, p, &c0, &d0, &mut x);
    unsafe {
        dgglse_(&i(m), &i(n), &i(p), wa.as_mut_ptr(), &i(m), wb.as_mut_ptr(), &i(p),
                wc.as_mut_ptr(), wd.as_mut_ptr(), wx.as_mut_ptr(), work.as_mut_ptr(),
                &i(64 * (m + n + p)), &mut winfo)
    };
    assert_eq!(info, winfo, "dgglse: INFO");
    same(&x, &wx, "dgglse: X");
}

// ───────────────────────────── SVD ─────────────────────────────

#[test]
fn dgesvd_matches() {
    for (m, n) in [(6, 4), (4, 6), (5, 5)] {
        let a0 = rand_mat(m, n, 151 + m as u64);
        let k = m.min(n);
        let (mut a, mut wa) = (a0.clone(), a0.clone());
        let (mut s, mut ws) = (vec![0.0f64; k], vec![0.0f64; k]);
        let (mut u, mut wu) = (vec![0.0f64; m * m], vec![0.0f64; m * m]);
        let (mut vt, mut wvt) = (vec![0.0f64; n * n], vec![0.0f64; n * n]);
        let (mut work, mut winfo) = (vec![0.0f64; 64 * (m + n)], 0);
        let info = om::dgesvd("A", "A", m, n, &mut a, m, &mut s, &mut u, m, &mut vt, n);
        unsafe {
            dgesvd_(&c("A"), &c("A"), &i(m), &i(n), wa.as_mut_ptr(), &i(m), ws.as_mut_ptr(),
                    wu.as_mut_ptr(), &i(m), wvt.as_mut_ptr(), &i(n), work.as_mut_ptr(),
                    &i(64 * (m + n)), &mut winfo)
        };
        assert_eq!(info, winfo, "dgesvd {m}x{n}: INFO");
        same(&s, &ws, &format!("dgesvd {m}x{n}: singular values"));
        // A singular vector is fixed only up to sign, and only the first k are
        // determined at all (the rest complete an arbitrary orthonormal basis).
        same_up_to_sign(&u[..m * k], &wu[..m * k], m, k, &format!("dgesvd {m}x{n}: U"));
    }
}

// ───────────────────────────── eigen ─────────────────────────────

/// Eigenvalues **in the order they are returned**, interleaved as `(WR, WI)`.
///
/// Not sorted: the order is the part a caller sees.
/// `Modelica.Math.Matrices.eigenValues` hands `WR`/`WI` straight to the model, so
/// a reordering is a behaviour change even when the set is right. It is decided
/// by DGEBAL's isolating permutation and by DLAHQR deflating from the bottom,
/// both of which `openmodelica_lapack::hqr` reproduces.
fn in_order(wr: &[f64], wi: &[f64]) -> Vec<f64> {
    wr.iter().zip(wi).flat_map(|(r, i)| [*r, *i]).collect()
}

/// Two eigenvector matrices column by column, allowing exactly the freedom the
/// mathematics leaves.
///
/// A real eigenvalue fixes its vector up to sign once `DGEEV` has scaled it to
/// norm 1. A conjugate pair does not: `(v_re, v_im)` and `(-v_im, v_re)` are the
/// same complex vector times `i`, and which one comes out turns on the last bits
/// of the Hessenberg reduction — whose BLAS here is OpenBLAS, neither the
/// reference loops nor reproducible across thread counts. So a pair is compared
/// by its row moduli `sqrt(re^2 + im^2)`, which that rotation leaves alone.
fn same_eigenvectors(got: &[f64], want: &[f64], n: usize, wi: &[f64], what: &str) {
    fn col(v: &[f64], j: usize, n: usize) -> &[f64] { &v[j * n..j * n + n] }
    let mut j = 0;
    while j < n {
        if wi[j] == 0.0 {
            same_up_to_sign(col(got, j, n), col(want, j, n), n, 1, &format!("{what} col {j}"));
            j += 1;
        } else {
            // sqrt(re^2 + im^2) per row: invariant under the pair's rotation.
            let mag = |v: &[f64]| -> Vec<f64> {
                (0..n).map(|i| (v[j * n + i].powi(2) + v[(j + 1) * n + i].powi(2)).sqrt()).collect()
            };
            same(&mag(got), &mag(want), &format!("{what} pair at {j}"));
            j += 2;
        }
    }
}

#[test]
fn dgeev_eigenvalues_match() {
    // Sizes past a single 2x2 block, so a complex pair's placement is exercised.
    for (n, seed) in [(2usize, 160u64), (3, 161), (4, 162), (5, 163), (8, 164), (12, 165), (20, 166)] {
        let a0 = rand_mat(n, n, seed);
        let (mut wr, mut wi) = (vec![0.0f64; n], vec![0.0f64; n]);
        let (mut lwr, mut lwi) = (vec![0.0f64; n], vec![0.0f64; n]);
        let (mut vr, mut lvr) = (vec![0.0f64; n * n], vec![0.0f64; n * n]);
        let (mut vl, mut lvl) = (vec![0.0f64; n * n], vec![0.0f64; n * n]);
        let mut wa = a0.clone();
        let (mut work, mut winfo) = (vec![0.0f64; 64 * n], 0);
        let info = om::dgeev("V", "V", n, &a0, n, &mut wr, &mut wi, &mut vl, n, &mut vr, n);
        unsafe {
            dgeev_(&c("V"), &c("V"), &i(n), wa.as_mut_ptr(), &i(n), lwr.as_mut_ptr(),
                   lwi.as_mut_ptr(), lvl.as_mut_ptr(), &i(n), lvr.as_mut_ptr(), &i(n),
                   work.as_mut_ptr(), &i(64 * n), &mut winfo)
        };
        assert_eq!(info, winfo, "dgeev {n}x{n} seed {seed}: INFO");
        same(&in_order(&wr, &wi), &in_order(&lwr, &lwi), "dgeev: eigenvalues");
        same_eigenvectors(&vr, &lvr, n, &wi, "dgeev: VR");
        same_eigenvectors(&vl, &lvl, n, &wi, "dgeev: VL");
    }
}

#[test]
fn dhseqr_eigenvalues_match() {
    let n = 5;
    let a0 = rand_mat(n, n, 171);
    // A genuine Hessenberg input: zero below the subdiagonal.
    let mut h = a0.clone();
    for j in 0..n {
        for r in j + 2..n {
            h[r + j * n] = 0.0;
        }
    }
    let (mut hh, mut wh) = (h.clone(), h.clone());
    let (mut wr, mut wi) = (vec![0.0f64; n], vec![0.0f64; n]);
    let (mut lwr, mut lwi) = (vec![0.0f64; n], vec![0.0f64; n]);
    let (mut z, mut wz) = (vec![0.0f64; n * n], vec![0.0f64; n * n]);
    let (mut work, mut winfo) = (vec![0.0f64; 64 * n], 0);
    let info = om::dhseqr("E", "N", n, &mut hh, n, &mut wr, &mut wi, &mut z, n);
    unsafe {
        dhseqr_(&c("E"), &c("N"), &i(n), &i(1), &i(n), wh.as_mut_ptr(), &i(n), lwr.as_mut_ptr(),
                lwi.as_mut_ptr(), wz.as_mut_ptr(), &i(n), work.as_mut_ptr(), &i(64 * n),
                &mut winfo)
    };
    assert_eq!(info, winfo, "dhseqr: INFO");
    same(&in_order(&wr, &wi), &in_order(&lwr, &lwi), "dhseqr: eigenvalues");
}

#[test]
fn dgehrd_dorghr_match() {
    let n = 6;
    let a0 = rand_mat(n, n, 181);
    let (mut a, mut want) = (a0.clone(), a0.clone());
    let (mut tau, mut wtau) = (vec![0.0f64; n - 1], vec![0.0f64; n - 1]);
    let (mut work, mut winfo) = (vec![0.0f64; 64 * n], 0);
    om::dgehrd(n, 1, n, &mut a, n, &mut tau);
    unsafe {
        dgehrd_(&i(n), &i(1), &i(n), want.as_mut_ptr(), &i(n), wtau.as_mut_ptr(),
                work.as_mut_ptr(), &i(64 * n), &mut winfo)
    };
    same(&tau, &wtau, "dgehrd: TAU");
    same(&a, &want, "dgehrd: packed H and reflectors");
    om::dorghr(n, 1, n, &mut a, n, &tau);
    unsafe {
        dorghr_(&i(n), &i(1), &i(n), want.as_mut_ptr(), &i(n), wtau.as_ptr(),
                work.as_mut_ptr(), &i(64 * n), &mut winfo)
    };
    same(&a, &want, "dorghr: Q");
}

#[test]
fn dgees_eigenvalues_match() {
    let n = 5;
    let a0 = rand_mat(n, n, 191);
    let (mut a, mut wa) = (a0.clone(), a0.clone());
    let (mut wr, mut wi) = (vec![0.0f64; n], vec![0.0f64; n]);
    let (mut lwr, mut lwi) = (vec![0.0f64; n], vec![0.0f64; n]);
    let (mut vs, mut lvs) = (vec![0.0f64; n * n], vec![0.0f64; n * n]);
    let (mut work, mut winfo) = (vec![0.0f64; 64 * n], 0);
    let info = om::dgees("V", "N", n, &mut a, n, &mut wr, &mut wi, &mut vs, n);
    // DGEES takes a SELECT function pointer; with SORT = "N" it is never called,
    // so DHSEQR on the Hessenberg reduction is the same factorization by a path
    // that needs no callback.
    unsafe {
        dgehrd_(&i(n), &i(1), &i(n), wa.as_mut_ptr(), &i(n), vec![0.0f64; n - 1].as_mut_ptr(),
                work.as_mut_ptr(), &i(64 * n), &mut winfo)
    };
    let mut wa2 = a0.clone();
    let mut wtau = vec![0.0f64; n - 1];
    unsafe {
        dgehrd_(&i(n), &i(1), &i(n), wa2.as_mut_ptr(), &i(n), wtau.as_mut_ptr(),
                work.as_mut_ptr(), &i(64 * n), &mut winfo);
        dorghr_(&i(n), &i(1), &i(n), lvs.as_mut_ptr(), &i(n), wtau.as_ptr(), work.as_mut_ptr(),
                &i(64 * n), &mut winfo);
        dhseqr_(&c("S"), &c("V"), &i(n), &i(1), &i(n), wa2.as_mut_ptr(), &i(n),
                lwr.as_mut_ptr(), lwi.as_mut_ptr(), lvs.as_mut_ptr(), &i(n), work.as_mut_ptr(),
                &i(64 * n), &mut winfo)
    };
    assert_eq!(info, 0, "dgees: INFO");
    same(&in_order(&wr, &wi), &in_order(&lwr, &lwi), "dgees: eigenvalues");
    // A = Z*T*Z' whatever order the Schur form came out in.
    let recon: Vec<f64> = (0..n * n)
        .map(|k| {
            let (r, cc) = (k % n, k / n);
            (0..n)
                .flat_map(|p| (0..n).map(move |q| (p, q)))
                .map(|(p, q)| vs[r + p * n] * a[p + q * n] * vs[cc + q * n])
                .sum()
        })
        .collect();
    same(&recon, &a0, "dgees: Z*T*Z'");
}

// ───────────────────────────── Sylvester ─────────────────────────────

#[test]
fn dtrsyl_matches() {
    // Quasi-triangular operands, which is what DTRSYL is defined on: the real
    // Schur forms of two random matrices, one of them carrying a 2x2 block.
    let (m, n) = (5, 4);
    let a = schur_form(m, 201);
    let b = schur_form(n, 202);
    let c0 = rand_mat(m, n, 203);
    for (ta, tb) in [("N", "N"), ("T", "N"), ("N", "T"), ("T", "T")] {
        for isgn in [1, -1] {
            let (mut cc, mut wc) = (c0.clone(), c0.clone());
            let (mut wscale, mut winfo) = (0.0f64, 0);
            let (scale, info) = om::dtrsyl(ta, tb, isgn, m, n, &a, m, &b, n, &mut cc, m);
            unsafe {
                dtrsyl_(&c(ta), &c(tb), &isgn, &i(m), &i(n), a.as_ptr(), &i(m), b.as_ptr(),
                        &i(n), wc.as_mut_ptr(), &i(m), &mut wscale, &mut winfo)
            };
            let what = format!("dtrsyl {ta}/{tb} isgn={isgn}");
            assert_eq!(info, winfo, "{what}: INFO");
            same(&[scale], &[wscale], &format!("{what}: SCALE"));
            same(&cc, &wc, &format!("{what}: X"));
        }
    }
}

/// The real Schur form `T` of a random matrix, via the system LAPACK so the input
/// to the routine under test is not itself in question.
fn schur_form(n: usize, seed: u64) -> Vec<f64> {
    let mut a = rand_mat(n, n, seed);
    let mut tau = vec![0.0f64; n.max(2) - 1];
    let (mut wr, mut wi) = (vec![0.0f64; n], vec![0.0f64; n]);
    let mut z = vec![0.0f64; n * n];
    let (mut work, mut info) = (vec![0.0f64; 64 * n], 0);
    unsafe {
        dgehrd_(&i(n), &i(1), &i(n), a.as_mut_ptr(), &i(n), tau.as_mut_ptr(), work.as_mut_ptr(),
                &i(64 * n), &mut info);
        dhseqr_(&c("S"), &c("N"), &i(n), &i(1), &i(n), a.as_mut_ptr(), &i(n), wr.as_mut_ptr(),
                wi.as_mut_ptr(), z.as_mut_ptr(), &i(n), work.as_mut_ptr(), &i(64 * n),
                &mut info);
    }
    // DHSEQR leaves the reflectors below the subdiagonal untouched; the Schur
    // form is the quasi-triangular part.
    for j in 0..n {
        for r in j + 2..n {
            a[r + j * n] = 0.0;
        }
    }
    a
}

// ─────────────────── the deprecated routines MSL 3 still calls ───────────────

#[test]
fn dgeqpf_matches() {
    let (m, n) = (6, 4);
    let a0 = rand_mat(m, n, 231);
    let (mut a, mut want) = (a0.clone(), a0.clone());
    let (mut jpvt, mut wjpvt) = (vec![0i32; n], vec![0i32; n]);
    let (mut tau, mut wtau) = (vec![0.0f64; n], vec![0.0f64; n]);
    let (mut work, mut winfo) = (vec![0.0f64; 3 * n], 0);
    om::dgeqpf(m, n, &mut a, m, &mut jpvt, &mut tau);
    unsafe {
        dgeqpf_(&i(m), &i(n), want.as_mut_ptr(), &i(m), wjpvt.as_mut_ptr(), wtau.as_mut_ptr(),
                work.as_mut_ptr(), &mut winfo)
    };
    same_i(&jpvt, &wjpvt, "dgeqpf: JPVT");
    same(&tau, &wtau, "dgeqpf: TAU");
    same(&a, &want, "dgeqpf: packed R and reflectors");
}

#[test]
fn dgelsx_matches() {
    let (m, n) = (6, 3);
    let a0 = rand_mat(m, n, 241);
    let ldb = m.max(n);
    let b0 = rand_mat(ldb, 2, 242);
    let (mut a, mut wa) = (a0.clone(), a0.clone());
    let (mut b, mut wb) = (b0.clone(), b0);
    let (mut jpvt, mut wjpvt) = (vec![0i32; n], vec![0i32; n]);
    let (mut work, mut winfo, mut wrank) = (vec![0.0f64; 10 * (m + n)], 0, 0);
    let rcond = 1e-12;
    let (rank, info) = om::dgelsx(m, n, 2, &mut a, m, &mut b, ldb, &mut jpvt, rcond);
    unsafe {
        dgelsx_(&i(m), &i(n), &i(2), wa.as_mut_ptr(), &i(m), wb.as_mut_ptr(), &i(ldb),
                wjpvt.as_mut_ptr(), &rcond, &mut wrank, work.as_mut_ptr(), &mut winfo)
    };
    assert_eq!(info, winfo, "dgelsx: INFO");
    assert_eq!(rank as i32, wrank, "dgelsx: RANK");
    for j in 0..2 {
        same(&b[j * ldb..j * ldb + n], &wb[j * ldb..j * ldb + n], "dgelsx: X");
    }
}

/// `ALPHA`/`BETA` are fixed only up to a common scale, so the comparison is over
/// the eigenvalues `ALPHA/BETA` they encode — sorted, since neither iteration
/// promises an order.
#[test]
fn dgegv_eigenvalues_match() {
    for seed in [251u64, 252] {
        let n = 5;
        let a0 = rand_mat(n, n, seed);
        let b0 = rand_mat(n, n, seed + 1000);
        let (mut ar, mut ai, mut be) = (vec![0.0f64; n], vec![0.0f64; n], vec![0.0f64; n]);
        let (mut lar, mut lai, mut lbe) = (vec![0.0f64; n], vec![0.0f64; n], vec![0.0f64; n]);
        let (mut wa, mut wb) = (a0.clone(), b0.clone());
        let (mut work, mut winfo) = (vec![0.0f64; 64 * n], 0);
        let info = om::dgegv("N", "N", n, &a0, n, &b0, n, &mut ar, &mut ai, &mut be);
        unsafe {
            dgegv_(&c("N"), &c("N"), &i(n), wa.as_mut_ptr(), &i(n), wb.as_mut_ptr(), &i(n),
                   lar.as_mut_ptr(), lai.as_mut_ptr(), lbe.as_mut_ptr(),
                   core::ptr::null_mut(), &i(1), core::ptr::null_mut(), &i(1),
                   work.as_mut_ptr(), &i(64 * n), &mut winfo)
        };
        assert_eq!(info, winfo, "dgegv seed {seed}: INFO");
        same(&ratios(&ar, &ai, &be), &ratios(&lar, &lai, &lbe), &format!("dgegv seed {seed}"));
    }
}

/// The documented gap: a singular `B` gives LAPACK an infinite eigenvalue and
/// gives this crate `INFO = n+1`. The point of the test is that it is refused
/// rather than answered wrongly.
#[test]
fn dgegv_refuses_a_singular_b() {
    let n = 5;
    let a = rand_mat(n, n, 253);
    let mut b = rand_mat(n, n, 1253);
    for r in 0..n {
        b[r + (n - 1) * n] = b[r];
    }
    let (mut ar, mut ai, mut be) = (vec![0.0f64; n], vec![0.0f64; n], vec![0.0f64; n]);
    assert_eq!(om::dgegv("N", "N", n, &a, n, &b, n, &mut ar, &mut ai, &mut be), (n + 1) as i32);

    // LAPACK does answer it, with a BETA of zero — what the reduction cannot do.
    let (mut lar, mut lai, mut lbe) = (vec![0.0f64; n], vec![0.0f64; n], vec![0.0f64; n]);
    let (mut wa, mut wb) = (a.clone(), b.clone());
    let (mut work, mut winfo) = (vec![0.0f64; 64 * n], 0);
    unsafe {
        dgegv_(&c("N"), &c("N"), &i(n), wa.as_mut_ptr(), &i(n), wb.as_mut_ptr(), &i(n),
               lar.as_mut_ptr(), lai.as_mut_ptr(), lbe.as_mut_ptr(), core::ptr::null_mut(),
               &i(1), core::ptr::null_mut(), &i(1), work.as_mut_ptr(), &i(64 * n), &mut winfo)
    };
    assert_eq!(winfo, 0);
    assert!(lbe.iter().any(|v| v.abs() < 1e-12), "LAPACK reports an infinite eigenvalue: {lbe:?}");
}

/// `(ALPHAR + i*ALPHAI)/BETA` as a sorted list, with an infinite eigenvalue
/// (`BETA = 0`) kept as a marker rather than a NaN. Sorted, and `|imaginary|`:
/// `dgegv` reduces to `B^-1 A`, so it has no QZ order to agree with — only the
/// set of eigenvalues is comparable.
fn ratios(ar: &[f64], ai: &[f64], be: &[f64]) -> Vec<f64> {
    const INF: f64 = 1e300;
    let mut v: Vec<(f64, f64)> = (0..ar.len())
        .map(|k| if be[k] == 0.0 { (INF, 0.0) } else { (ar[k] / be[k], (ai[k] / be[k]).abs()) })
        .collect();
    v.sort_by(|a, b| a.0.total_cmp(&b.0).then(a.1.total_cmp(&b.1)));
    v.into_iter().flat_map(|(r, i)| [r, i]).collect()
}

#[test]
fn dgegv_rejects_eigenvector_requests() {
    let n = 3;
    let (a, b) = (rand_mat(n, n, 261), rand_mat(n, n, 262));
    let (mut ar, mut ai, mut be) = (vec![0.0f64; n], vec![0.0f64; n], vec![0.0f64; n]);
    assert_eq!(om::dgegv("V", "N", n, &a, n, &b, n, &mut ar, &mut ai, &mut be), -1);
    assert_eq!(om::dgegv("N", "V", n, &a, n, &b, n, &mut ar, &mut ai, &mut be), -2);
}

// ───────────────────────────── banded ─────────────────────────────

#[test]
fn dgtsv_matches() {
    let n = 6;
    let dl0: Vec<f64> = (0..n - 1).map(|k| 1.0 + k as f64 * 0.25).collect();
    let d0: Vec<f64> = (0..n).map(|k| 8.0 + k as f64).collect();
    let du0: Vec<f64> = (0..n - 1).map(|k| -2.0 + k as f64 * 0.5).collect();
    let b0 = rand_mat(n, 2, 211);
    let (mut dl, mut d, mut du, mut b) = (dl0.clone(), d0.clone(), du0.clone(), b0.clone());
    let (mut wdl, mut wd, mut wdu, mut wb) = (dl0, d0, du0, b0.clone());
    let mut winfo = 0;
    let info = om::dgtsv(n, 2, &mut dl, &mut d, &mut du, &mut b, n);
    unsafe {
        dgtsv_(&i(n), &i(2), wdl.as_mut_ptr(), wd.as_mut_ptr(), wdu.as_mut_ptr(),
               wb.as_mut_ptr(), &i(n), &mut winfo)
    };
    assert_eq!(info, winfo, "dgtsv: INFO");
    same(&b, &wb, "dgtsv: X");
}

#[test]
fn dgbsv_matches() {
    let (n, kl, ku) = (6, 1, 2);
    let ldab = 2 * kl + ku + 1;
    // LAPACK's band storage: A(i,j) at AB(kl+ku+1+i-j, j), rows kl.. used by the
    // factorization.
    let mut ab = vec![0.0f64; ldab * n];
    for j in 0..n {
        for r in j.saturating_sub(ku)..(j + kl + 1).min(n) {
            ab[(kl + ku + r - j) + j * ldab] = if r == j { 9.0 } else { 1.0 + r as f64 * 0.1 };
        }
    }
    let b0 = rand_mat(n, 2, 221);
    let (mut a, mut wa) = (ab.clone(), ab.clone());
    let (mut b, mut wb) = (b0.clone(), b0);
    let (mut ipiv, mut wipiv) = (vec![0i32; n], vec![0i32; n]);
    let mut winfo = 0;
    let info = om::dgbsv(n, kl, ku, 2, &mut a, ldab, &mut ipiv, &mut b, n);
    unsafe {
        dgbsv_(&i(n), &i(kl), &i(ku), &i(2), wa.as_mut_ptr(), &i(ldab), wipiv.as_mut_ptr(),
               wb.as_mut_ptr(), &i(n), &mut winfo)
    };
    assert_eq!(info, winfo, "dgbsv: INFO");
    same(&b, &wb, "dgbsv: X");
}
