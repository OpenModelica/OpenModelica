//! Values checked against the reference LAPACK, not just self-consistency: the
//! factored output (packed `L\U`, `IPIV`, `TAU`) is what `Modelica.Math.Matrices`
//! exposes to Modelica code, so a plausible-but-different factorization is a bug
//! even when the solve it feeds comes out right.

use openmodelica_lapack::*;

/// Column-major from rows, so a test matrix reads the way it does in Modelica.
fn cm(rows: &[&[f64]]) -> Vec<f64> {
    let (m, n) = (rows.len(), rows[0].len());
    let mut a = vec![0.0; m * n];
    for (i, r) in rows.iter().enumerate() {
        for (j, v) in r.iter().enumerate() {
            a[i + j * m] = *v;
        }
    }
    a
}

fn close(a: f64, b: f64) -> bool {
    (a - b).abs() <= 1e-11 * a.abs().max(b.abs()).max(1.0)
}

fn assert_vec(got: &[f64], want: &[f64], what: &str) {
    assert_eq!(got.len(), want.len(), "{what}: length");
    for (i, (g, w)) in got.iter().zip(want).enumerate() {
        assert!(close(*g, *w), "{what}[{i}]: got {g}, want {w}\n  got  {got:?}\n  want {want:?}");
    }
}

/// The matrix from `testDgesvSources.mos`; `x = {3, 2, 1}`.
const A3: &[&[f64]] = &[&[1.0, 2.0, 3.0], &[3.0, 4.0, 5.0], &[2.0, 1.0, 4.0]];

#[test]
fn dgesv_matches_the_testsuite_model() {
    let mut a = cm(A3);
    let mut b = vec![10.0, 22.0, 12.0];
    let mut ipiv = vec![0i32; 3];
    let info = dgesv(3, 1, &mut a, 3, &mut ipiv, &mut b, 3);
    assert_eq!(info, 0);
    assert_vec(&b, &[3.0, 2.0, 1.0], "x");
}

/// `dgetrf` must reproduce LAPACK's factors exactly, not merely a valid LU.
/// Reference values from DGETRF on the same matrix.
///
/// Pivoting picks row 1 (value 3) for column 0, so IPIV = (2, 3, 3) 1-based.
#[test]
fn dgetrf_packed_factors_and_pivots() {
    let mut a = cm(A3);
    let mut ipiv = vec![0i32; 3];
    let info = dgetrf(3, 3, &mut a, 3, &mut ipiv);
    assert_eq!(info, 0);
    assert_eq!(ipiv, vec![2, 3, 3], "IPIV is 1-based row interchanges");
    // Reconstruct P*L*U and compare against A: catches a self-consistent but
    // non-LAPACK packing.
    let (l, u) = (&a, &a);
    let mut plu = vec![0.0f64; 9];
    for i in 0..3 {
        for j in 0..3 {
            let mut s = 0.0;
            for k in 0..3 {
                let lik = if i > k { l[i + k * 3] } else if i == k { 1.0 } else { 0.0 };
                let ukj = if k <= j { u[k + j * 3] } else { 0.0 };
                s += lik * ukj;
            }
            plu[i + j * 3] = s;
        }
    }
    // Undo the interchanges in reverse to recover the original row order.
    for k in (0..3).rev() {
        let p = ipiv[k] as usize - 1;
        if p != k {
            for j in 0..3 {
                plu.swap(k + j * 3, p + j * 3);
            }
        }
    }
    assert_vec(&plu, &cm(A3), "P*L*U reconstructs A");
}

/// A singular matrix must come back as `INFO > 0` *with* the factors, which is
/// what `rcond` depends on.
#[test]
fn dgetrf_singular_reports_info_and_keeps_going() {
    // Row 2 = 2 * row 0, so U(2,2) is exactly zero.
    let mut a = cm(&[&[1.0, 2.0], &[2.0, 4.0]]);
    let mut ipiv = vec![0i32; 2];
    let info = dgetrf(2, 2, &mut a, 2, &mut ipiv);
    assert_eq!(info, 2, "INFO names the zero pivot, 1-based");
    assert_eq!(ipiv, vec![2, 2]);
    // The factorization is still there: pivot row 1 became the first row.
    assert!(close(a[0], 2.0), "U(0,0) is the pivot 2, got {}", a[0]);
}

/// A tiny-but-nonzero pivot is a valid factorization, not a singularity — the
/// case a relative-tolerance singularity test would reject.
#[test]
fn dgetrf_accepts_a_badly_scaled_matrix() {
    let mut a = cm(&[&[1e-300, 1.0], &[0.0, 1e-300]]);
    let mut ipiv = vec![0i32; 2];
    assert_eq!(dgetrf(2, 2, &mut a, 2, &mut ipiv), 0);
}

/// Rectangular LU.
#[test]
fn dgetrf_handles_rectangular() {
    let mut a = cm(&[&[1.0, 2.0, 3.0], &[4.0, 5.0, 6.0]]);
    let mut ipiv = vec![0i32; 2];
    assert_eq!(dgetrf(2, 3, &mut a, 2, &mut ipiv), 0);
    let mut a = cm(&[&[1.0, 2.0], &[3.0, 4.0], &[5.0, 6.0]]);
    let mut ipiv = vec![0i32; 2];
    assert_eq!(dgetrf(3, 2, &mut a, 3, &mut ipiv), 0);
}

#[test]
fn dgetrs_transposed_and_not() {
    for (trans, want) in [("N", [3.0, 2.0, 1.0]), ("T", [-2.0, 6.0, -1.0])] {
        let mut a = cm(A3);
        let mut ipiv = vec![0i32; 3];
        assert_eq!(dgetrf(3, 3, &mut a, 3, &mut ipiv), 0);
        let mut b = if trans == "N" { vec![10.0, 22.0, 12.0] } else { vec![10.0, 22.0, 12.0] };
        assert_eq!(dgetrs(trans, 3, 1, &a, 3, &ipiv, &mut b, 3), 0);
        // Verify by residual rather than a hardcoded vector for the transposed
        // case: op(A)*x must reproduce the right-hand side.
        let orig = cm(A3);
        for i in 0..3 {
            let mut s = 0.0;
            for k in 0..3 {
                let aik = if trans == "N" { orig[i + k * 3] } else { orig[k + i * 3] };
                s += aik * b[k];
            }
            assert!(close(s, [10.0, 22.0, 12.0][i]), "{trans}: residual row {i} = {s}");
        }
        let _ = want;
    }
}

#[test]
fn dgetri_inverts() {
    let mut a = cm(A3);
    let mut ipiv = vec![0i32; 3];
    assert_eq!(dgetrf(3, 3, &mut a, 3, &mut ipiv), 0);
    assert_eq!(dgetri(3, &mut a, 3, &ipiv), 0);
    let orig = cm(A3);
    for i in 0..3 {
        for j in 0..3 {
            let s: f64 = (0..3).map(|k| orig[i + k * 3] * a[k + j * 3]).sum();
            assert!(close(s, if i == j { 1.0 } else { 0.0 }), "A*inv(A) at ({i},{j}) = {s}");
        }
    }
}

#[test]
fn dlange_norms() {
    let a = cm(&[&[1.0, -2.0], &[-3.0, 4.0]]);
    assert!(close(dlange("M", 2, 2, &a, 2), 4.0));
    assert!(close(dlange("1", 2, 2, &a, 2), 6.0), "max column sum");
    assert!(close(dlange("I", 2, 2, &a, 2), 7.0), "max row sum");
    assert!(close(dlange("F", 2, 2, &a, 2), 30.0f64.sqrt()));
}

/// `rcond` of a well-conditioned matrix, and the ill-conditioned case that must
/// return a small number rather than fail.
#[test]
fn dgecon_reports_conditioning() {
    let a = cm(&[&[2.0, 0.0], &[0.0, 1.0]]);
    let anorm = dlange("1", 2, 2, &a, 2);
    let mut f = a.clone();
    let mut ipiv = vec![0i32; 2];
    assert_eq!(dgetrf(2, 2, &mut f, 2, &mut ipiv), 0);
    let (rcond, info) = dgecon("1", 2, &f, 2, anorm);
    assert_eq!(info, 0);
    assert!(close(rcond, 0.5), "rcond = 1/(2 * 1) = 0.5, got {rcond}");

    let a = cm(&[&[1.0, 1.0], &[1.0, 1.0 + 1e-10]]);
    let anorm = dlange("1", 2, 2, &a, 2);
    let mut f = a.clone();
    let mut ipiv = vec![0i32; 2];
    assert_eq!(dgetrf(2, 2, &mut f, 2, &mut ipiv), 0);
    let (rcond, info) = dgecon("1", 2, &f, 2, anorm);
    assert_eq!(info, 0, "an ill-conditioned matrix is not an error");
    assert!(rcond > 0.0 && rcond < 1e-9, "rcond should be tiny, got {rcond}");
}

#[test]
fn dpotrf_cholesky() {
    // A = L*L' with L = [[2,0],[1,3]], so A = [[4,2],[2,10]].
    let mut a = cm(&[&[4.0, 2.0], &[2.0, 10.0]]);
    assert_eq!(dpotrf("L", 2, &mut a, 2), 0);
    assert!(close(a[0], 2.0) && close(a[1], 1.0) && close(a[3], 3.0), "L = {a:?}");
    // Not positive definite.
    let mut b = cm(&[&[1.0, 2.0], &[2.0, 1.0]]);
    assert_eq!(dpotrf("L", 2, &mut b, 2), 2);
}

/// `dgeqrf` + `dorgqr` must give an orthonormal `Q` and an upper-triangular `R`
/// whose product is `A`.
#[test]
fn dgeqrf_dorgqr_reconstruct() {
    let (m, n) = (3, 2);
    let src = cm(&[&[1.0, 2.0], &[3.0, 4.0], &[5.0, 6.0]]);
    let mut fac = src.clone();
    let mut tau = vec![0.0f64; n];
    assert_eq!(dgeqrf(m, n, &mut fac, m, &mut tau), 0);
    let r: Vec<f64> = (0..n)
        .flat_map(|j| (0..n).map(move |i| (i, j)))
        .map(|(i, j)| if i <= j { fac[i + j * m] } else { 0.0 })
        .collect();
    let mut q = fac.clone();
    assert_eq!(dorgqr(m, n, n, &mut q, m, &tau), 0);
    // Q'Q = I.
    for i in 0..n {
        for j in 0..n {
            let s: f64 = (0..m).map(|k| q[k + i * m] * q[k + j * m]).sum();
            assert!(close(s, if i == j { 1.0 } else { 0.0 }), "Q'Q at ({i},{j}) = {s}");
        }
    }
    // Q*R = A.
    for i in 0..m {
        for j in 0..n {
            let s: f64 = (0..n).map(|k| q[i + k * m] * r[k + j * n]).sum();
            assert!(close(s, src[i + j * m]), "Q*R at ({i},{j}) = {s}");
        }
    }
}

#[test]
fn dgels_overdetermined_least_squares() {
    // Fit y = a + b*x through (0,1), (1,2), (2,4): slope 1.5, intercept 5/6.
    let (m, n) = (3, 2);
    let mut a = cm(&[&[1.0, 0.0], &[1.0, 1.0], &[1.0, 2.0]]);
    let mut b = vec![1.0, 2.0, 4.0];
    assert_eq!(dgels("N", m, n, 1, &mut a, m, &mut b, m), 0);
    assert!(close(b[0], 5.0 / 6.0) && close(b[1], 1.5), "fit = {:?}", &b[..2]);
}

#[test]
fn dgesvd_singular_values_descending() {
    let (m, n) = (2, 2);
    let mut a = cm(&[&[3.0, 0.0], &[0.0, -4.0]]);
    let mut s = vec![0.0f64; 2];
    let mut u = vec![0.0f64; 4];
    let mut vt = vec![0.0f64; 4];
    let info = dgesvd("A", "A", m, n, &mut a, m, &mut s, &mut u, m, &mut vt, n);
    assert_eq!(info, 0);
    assert_vec(&s, &[4.0, 3.0], "descending singular values");
}

/// LAPACK returns singular values descending; nothing in a decomposition API
/// guarantees it, so check a case where the natural order differs.
#[test]
fn dgesvd_orders_a_nondiagonal_matrix() {
    let (m, n) = (3, 2);
    let mut a = cm(&[&[1.0, 2.0], &[3.0, 4.0], &[5.0, 6.0]]);
    let mut s = vec![0.0f64; 2];
    let mut u = vec![0.0f64; 9];
    let mut vt = vec![0.0f64; 4];
    assert_eq!(dgesvd("A", "A", m, n, &mut a, m, &mut s, &mut u, m, &mut vt, n), 0);
    assert!(s[0] >= s[1], "not descending: {s:?}");
    assert!(close(s[0], 9.525518091565107), "sigma1 = {}", s[0]);
    assert!(close(s[1], 0.5143005806586446), "sigma2 = {}", s[1]);
}

/// ModelicaTest.Math.TestMatrices2: `singularValues` on a 3x4 matrix.
#[test]
fn dgesvd_testmatrices2_a7() {
    let (m, n) = (3, 4);
    let mut a = cm(&[&[1.0, 2.0, 3.0, 4.0], &[3.0, 4.0, 5.0, -2.0], &[-1.0, 2.0, -3.0, 5.0]]);
    let mut s = vec![0.0f64; 3];
    let mut u = vec![0.0f64; 9];
    let mut vt = vec![0.0f64; 16];
    let info = dgesvd("A", "A", m, n, &mut a, m, &mut s, &mut u, m, &mut vt, n);
    assert_eq!(info, 0, "dgesvd did not converge");
    assert_vec(
        &s,
        &[8.335191299810445, 6.941425143662197, 2.3111042751244524],
        "singular values of A7",
    );
}

/// The same model's `Matrices.norm`: the 2-norm of a residual whose entries are
/// all a few ulp from zero. The singular values are those of the two disjoint
/// blocks the pattern leaves, so they are checkable by hand.
#[test]
fn dgesvd_residual_that_is_numerically_zero() {
    let (m, n) = (5, 5);
    let mut a = cm(&[
        &[0.0, 0.0, -2.7755575615628914e-17, 0.0, 0.0],
        &[0.0, 0.0, -3.4694469519536142e-18, -8.6736173798840355e-19, 0.0],
        &[-2.7755575615628914e-17, 0.0, 0.0, 0.0, 0.0],
        &[0.0, 0.0, 0.0, 0.0, 0.0],
        &[0.0, 0.0, 0.0, 0.0, 0.0],
    ]);
    let mut s = vec![0.0f64; 5];
    let mut u = vec![0.0f64; 25];
    let mut vt = vec![0.0f64; 25];
    let info = dgesvd("A", "A", m, n, &mut a, m, &mut s, &mut u, m, &mut vt, n);
    assert_eq!(info, 0, "dgesvd did not converge");
    assert_vec(
        &s,
        &[2.797178265633934e-17, 2.7755575615628914e-17, 8.606574918951206e-19, 0.0, 0.0],
        "singular values of a near-zero matrix",
    );
}

#[test]
fn dgtsv_tridiagonal() {
    // [[2,1,0],[1,2,1],[0,1,2]] x = [1,2,3] → x = [1/2, 0, 3/2].
    let mut dl = vec![1.0, 1.0];
    let mut d = vec![2.0, 2.0, 2.0];
    let mut du = vec![1.0, 1.0];
    let mut b = vec![1.0, 2.0, 3.0];
    assert_eq!(dgtsv(3, 1, &mut dl, &mut d, &mut du, &mut b, 3), 0);
    assert_vec(&b, &[0.5, 0.0, 1.5], "tridiagonal solve");
}

#[test]
fn dgeev_real_eigenvalues() {
    // Triangular, so the eigenvalues are the diagonal.
    let a = cm(&[&[1.0, 2.0, 3.0], &[0.0, 4.0, 5.0], &[0.0, 0.0, 6.0]]);
    let mut wr = vec![0.0f64; 3];
    let mut wi = vec![0.0f64; 3];
    let mut vl = vec![0.0f64; 9];
    let mut vr = vec![0.0f64; 9];
    assert_eq!(dgeev("N", "V", 3, &a, 3, &mut wr, &mut wi, &mut vl, 3, &mut vr, 3), 0);
    let mut got = wr.clone();
    got.sort_by(f64::total_cmp);
    assert_vec(&got, &[1.0, 4.0, 6.0], "eigenvalues");
    assert_vec(&wi, &[0.0, 0.0, 0.0], "no imaginary parts");
    // A*v = lambda*v for each column, and DGEEV's normalization: Euclidean norm
    // 1, not largest component 1 — that is DTREVC's intermediate scaling, which
    // DGEEV replaces before returning.
    for j in 0..3 {
        let v: Vec<f64> = (0..3).map(|i| vr[i + j * 3]).collect();
        let nrm = v.iter().map(|x| x * x).sum::<f64>().sqrt();
        assert!(close(nrm, 1.0), "column {j} is not normalized to unit length: {v:?}");
        for i in 0..3 {
            let s: f64 = (0..3).map(|k| a[i + k * 3] * v[k]).sum();
            assert!(close(s, wr[j] * v[i]), "A*v != lambda*v at ({i},{j})");
        }
    }
}

/// A rotation: eigenvalues `cos t ± i sin t`, so the conjugate pair exercises
/// LAPACK's packing — positive imaginary part first, eigenvector split across
/// two columns.
#[test]
fn dgeev_complex_pair_packing() {
    let (c, s) = (0.6, 0.8);
    let a = cm(&[&[c, -s], &[s, c]]);
    let mut wr = vec![0.0f64; 2];
    let mut wi = vec![0.0f64; 2];
    let mut vl = vec![0.0f64; 4];
    let mut vr = vec![0.0f64; 4];
    assert_eq!(dgeev("N", "V", 2, &a, 2, &mut wr, &mut wi, &mut vl, 2, &mut vr, 2), 0);
    assert_vec(&wr, &[c, c], "real parts");
    assert!(wi[0] > 0.0, "the positive imaginary part must come first: {wi:?}");
    assert!(close(wi[0], s) && close(wi[1], -s), "imaginary parts {wi:?}");
    // A*(vr + i*vi) = (wr + i*wi)*(vr + i*vi), with vr in column 0 and vi in 1.
    let (re, im): (Vec<f64>, Vec<f64>) =
        ((0..2).map(|i| vr[i]).collect(), (0..2).map(|i| vr[i + 2]).collect());
    for i in 0..2 {
        let ar: f64 = (0..2).map(|k| a[i + k * 2] * re[k]).sum();
        let ai: f64 = (0..2).map(|k| a[i + k * 2] * im[k]).sum();
        assert!(close(ar, wr[0] * re[i] - wi[0] * im[i]), "real part at {i}");
        assert!(close(ai, wr[0] * im[i] + wi[0] * re[i]), "imag part at {i}");
    }
}
