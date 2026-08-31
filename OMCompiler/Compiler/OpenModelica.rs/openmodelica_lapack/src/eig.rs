//! Eigenvalues, the real Schur form and the Hessenberg reduction: `DGEEV`,
//! `DGEES`, `DHSEQR`, `DGEHRD`, `DORGHR`, `DTRSYL`.
//!
//! The drivers follow their Fortran step for step — `DGEBAL`, `DGEHRD`,
//! `DORGHR`, the QR iteration in [`crate::hqr`], `trevc`, `DGEBAK` — because the
//! order `WR`/`WI` come out in is part of the answer a model reads.
//! `dgehrd`/`dorghr` are written here for the same reason as the QR family:
//! LAPACK leaves the *reflectors* in `A` plus `TAU`, which no decomposition API
//! hands back.
//!
//! See `LICENSE-LAPACK` at the crate root.


use crate::blas::{at, dlarf_left, dlarfg, set};
use crate::{abs, opt, SAFMIN};

/// Reduce `a` (rows/columns `ilo..=ihi`, 1-based inclusive) to upper Hessenberg
/// form and run the QR iteration on it, as `DGEEV` and `DGEES` do between
/// `DGEBAL` and `DTREVC`. `want_z` also returns the accumulated Schur basis `Z`.
///
/// The caller has already balanced, so the reduction and the iteration both stay
/// inside the active window: outside it `Z` is the identity and `h` is already
/// triangular.
fn hess_qr(
    n: usize,
    ilo: usize,
    ihi: usize,
    h: &mut [f64],
    ldh: usize,
    wr: &mut [f64],
    wi: &mut [f64],
    want_t: bool,
    want_z: bool,
) -> (Option<Vec<f64>>, i32) {
    let mut tau = vec![0.0f64; n.max(1)];
    dgehrd(n, ilo, ihi, h, ldh, &mut tau);
    // DGEEV copies the packed reflectors out of A's lower triangle before the
    // iteration overwrites them, then expands them in place.
    let mut z = if want_z {
        let mut z = h.to_vec();
        dorghr(n, ilo, ihi, &mut z, ldh, &tau);
        Some(z)
    } else {
        None
    };
    // What DGEHRD left below the subdiagonal is reflector storage, not part of the
    // Hessenberg matrix.
    for i in ilo..=ihi {
        for r in i + 2..=ihi {
            crate::blas::set(h, ldh, r - 1, i - 1, 0.0);
        }
    }
    // DHSEQR's own preamble: the eigenvalues DGEBAL isolated are on the diagonal
    // already, and only the window goes through the iteration.
    for i in (1..ilo).chain(ihi + 1..=n) {
        wr[i - 1] = at(h, ldh, i - 1, i - 1);
        wi[i - 1] = 0.0;
    }
    if ilo == ihi {
        wr[ilo - 1] = at(h, ldh, ilo - 1, ilo - 1);
        wi[ilo - 1] = 0.0;
        return (z, 0);
    }
    let mut dummy = vec![0.0f64; if want_z { 0 } else { n * n }];
    let zz = z.as_deref_mut().unwrap_or(&mut dummy);
    #[cfg(feature = "faer-backend")]
    let info =
        crate::faer_backend::multishift_qr_window(want_t, want_z, n, ilo, ihi, h, ldh, wr, wi, zz, ldh);
    #[cfg(not(feature = "faer-backend"))]
    let info = crate::hqr::dlahqr(want_t, want_z, n, ilo, ihi, h, ldh, wr, wi, ilo, ihi, zz, ldh);
    if (want_t || info != 0) && n > 2 {
        for j in 1..=n - 2 {
            for i in j + 2..=n {
                crate::blas::set(h, ldh, i - 1, j - 1, 0.0);
            }
        }
    }
    (z, info)
}

/// The scaling `DGEEV`/`DGEES` apply before balancing when the largest entry sits
/// outside `[sqrt(SAFMIN)/eps, eps/sqrt(SAFMIN)]`, so the QR iteration's
/// thresholds stay meaningful. `Some(anrm)` means the matrix was scaled and the
/// eigenvalues have to be scaled back.
pub(crate) fn prescale(n: usize, a: &mut [f64], lda: usize) -> Option<f64> {
    let smlnum = crate::sqrt(SAFMIN) / crate::hqr::ULP;
    let bignum = 1.0 / smlnum;
    let anrm = (0..n).flat_map(|j| (0..n).map(move |i| (i, j))).map(|(i, j)| abs(at(a, lda, i, j)))
        .fold(0.0f64, f64::max);
    let cscale = if anrm > 0.0 && anrm < smlnum {
        smlnum
    } else if anrm > bignum {
        bignum
    } else {
        return None;
    };
    for j in 0..n {
        crate::hqr::dlascl(anrm, cscale, &mut a[j * lda..j * lda + n]);
    }
    Some(anrm / cscale)
}

/// `DGEEV`'s final normalization: each eigenvector to Euclidean norm 1, and a
/// conjugate pair rotated so its largest-modulus component is real. Both halves
/// of a pair share the scale, and column `j+1` holds the imaginary part.
pub(crate) fn normalize_eigenvectors(v: &mut [f64], ldv: usize, n: usize, wi: &[f64]) {
    let mut i = 0;
    while i < n {
        if wi[i] == 0.0 {
            let scl = 1.0 / crate::blas::dnrm2(&v[i * ldv..i * ldv + n]);
            crate::blas::dscal(scl, &mut v[i * ldv..i * ldv + n]);
            i += 1;
        } else if wi[i] > 0.0 {
            let scl = 1.0
                / crate::hqr::dlapy2(
                    crate::blas::dnrm2(&v[i * ldv..i * ldv + n]),
                    crate::blas::dnrm2(&v[(i + 1) * ldv..(i + 1) * ldv + n]),
                );
            crate::blas::dscal(scl, &mut v[i * ldv..i * ldv + n]);
            crate::blas::dscal(scl, &mut v[(i + 1) * ldv..(i + 1) * ldv + n]);
            let mods: Vec<f64> = (0..n)
                .map(|k| at(v, ldv, k, i) * at(v, ldv, k, i) + at(v, ldv, k, i + 1) * at(v, ldv, k, i + 1))
                .collect();
            let k = crate::blas::idamax(&mods);
            let (cs, sn, _) = crate::hqr::dlartg(at(v, ldv, k, i), at(v, ldv, k, i + 1));
            crate::hqr::drot(n, v, i * ldv, 1, (i + 1) * ldv, 1, cs, sn);
            crate::blas::set(v, ldv, k, i + 1, 0.0);
            i += 2;
        } else {
            i += 1;
        }
    }
}

/// `DGEEV`: eigenvalues, and optionally the left (`jobvl = "V"`) and right
/// (`jobvr = "V"`) eigenvectors, of a general real matrix. A conjugate pair
/// occupies two columns — real part then imaginary part — and each eigenvector
/// has Euclidean norm 1 with its largest-modulus component real.
#[allow(clippy::too_many_arguments)]
pub fn dgeev(
    jobvl: &str,
    jobvr: &str,
    n: usize,
    a: &[f64],
    lda: usize,
    wr: &mut [f64],
    wi: &mut [f64],
    vl: &mut [f64],
    ldvl: usize,
    vr: &mut [f64],
    ldvr: usize,
) -> i32 {
    #[cfg(feature = "faer-backend")]
    return crate::faer_backend::dgeev(jobvl, jobvr, n, a, lda, wr, wi, vl, ldvl, vr, ldvr);
    #[cfg(not(feature = "faer-backend"))]
    dgeev_ref(jobvl, jobvr, n, a, lda, wr, wi, vl, ldvl, vr, ldvr)
}

/// The port of `DGEEV`, kept as the faer-free fallback.
#[allow(clippy::too_many_arguments)]
pub fn dgeev_ref(
    jobvl: &str,
    jobvr: &str,
    n: usize,
    a: &[f64],
    lda: usize,
    wr: &mut [f64],
    wi: &mut [f64],
    vl: &mut [f64],
    ldvl: usize,
    vr: &mut [f64],
    ldvr: usize,
) -> i32 {
    if n == 0 {
        return 0;
    }
    let (want_l, want_r) = (opt(jobvl) == b'V', opt(jobvr) == b'V');
    let mut h = crate::pack(n, n, a, lda);
    let unscale = prescale(n, &mut h, n);
    let (ilo, ihi, scale) = crate::hqr::dgebal("B", n, &mut h, n);
    // The Schur form, not just the eigenvalues, whenever a side is wanted: that is
    // what `trevc` reads.
    let (z, info) = hess_qr(n, ilo, ihi, &mut h, n, wr, wi, want_l || want_r, want_l || want_r);

    if info == 0 && let Some(z) = z {
        // DTREVC back-transforms in place over the Schur basis, so each side
        // starts from its own copy of Z.
        for (want, v, ldv, right) in [(want_r, &mut *vr, ldvr, true), (want_l, &mut *vl, ldvl, false)] {
            if !want {
                continue;
            }
            for j in 0..n {
                for i in 0..n {
                    set(v, ldv, i, j, z[i + j * n]);
                }
            }
            crate::trevc::dtrevc(right, n, &h, n, v, ldv);
            crate::hqr::dgebak("B", if right { "R" } else { "L" }, n, ilo, ihi, &scale, n, v, ldv);
            normalize_eigenvectors(v, ldv, n, wi);
        }
    }

    if let Some(f) = unscale {
        let first = info.max(0) as usize;
        crate::hqr::dlascl(1.0, f, &mut wr[first..n]);
        crate::hqr::dlascl(1.0, f, &mut wi[first..n]);
        if info > 0 {
            crate::hqr::dlascl(1.0, f, &mut wr[..ilo - 1]);
            crate::hqr::dlascl(1.0, f, &mut wi[..ilo - 1]);
        }
    }
    info
}

/// `DGEES`: the real Schur factorization `A = Z*T*Z'`. `jobvs = "V"` returns `Z`.
/// Eigenvalue sorting (`sort = "S"`) is not implemented — MSL's `realSchur` does
/// not ask for it — and is reported as `INFO = -2`.
///
/// Balanced with `"P"`, not `"B"`: only a permutation keeps `Z` orthogonal, which
/// is what makes the returned factorization a Schur one.
#[allow(clippy::too_many_arguments)]
pub fn dgees(
    jobvs: &str,
    sort: &str,
    n: usize,
    a: &mut [f64],
    lda: usize,
    wr: &mut [f64],
    wi: &mut [f64],
    vs: &mut [f64],
    ldvs: usize,
) -> i32 {

    if opt(sort) == b'S' {
        return -2;
    }
    if n == 0 {
        return 0;
    }
    let want_vs = opt(jobvs) == b'V';
    let mut h = crate::pack(n, n, a, lda);
    let unscale = prescale(n, &mut h, n);
    let (ilo, ihi, scale) = crate::hqr::dgebal("P", n, &mut h, n);
    let (z, info) = hess_qr(n, ilo, ihi, &mut h, n, wr, wi, true, want_vs);
    if let Some(mut z) = z {
        crate::hqr::dgebak("P", "R", n, ilo, ihi, &scale, n, &mut z, n);
        for j in 0..n {
            for i in 0..n {
                set(vs, ldvs, i, j, z[i + j * n]);
            }
        }
    }
    if let Some(f) = unscale {
        for j in 0..n {
            crate::hqr::dlascl(1.0, f, &mut h[j * n..j * n + n]);
        }
        crate::hqr::dlascl(1.0, f, &mut wr[..n]);
        crate::hqr::dlascl(1.0, f, &mut wi[..n]);
    }
    for j in 0..n {
        for i in 0..n {
            set(a, lda, i, j, h[i + j * n]);
        }
    }
    info
}

/// `DHSEQR`: eigenvalues (`job = "E"`) or the Schur form (`job = "S"`) of an
/// upper Hessenberg matrix. `compz = "I"` returns the Schur vectors of `H` in `z`;
/// `"V"` multiplies them into the `z` supplied (the `Q` from `dgehrd`/`dorghr`),
/// which is how `Matrices.eigenvaluesHessenberg` chains the two.
#[allow(clippy::too_many_arguments)]
pub fn dhseqr(
    job: &str,
    compz: &str,
    n: usize,
    h: &mut [f64],
    ldh: usize,
    wr: &mut [f64],
    wi: &mut [f64],
    z: &mut [f64],
    ldz: usize,
) -> i32 {

    if n == 0 {
        return 0;
    }
    let want_t = opt(job) == b'S';
    let want_z = matches!(opt(compz), b'I' | b'V');
    // `compz = "V"` accumulates into the caller's Z, so the rotations have to land
    // there directly; `"I"` starts from the identity.
    if opt(compz) == b'I' {
        for j in 0..n {
            for i in 0..n {
                set(z, ldz, i, j, if i == j { 1.0 } else { 0.0 });
            }
        }
    }
    #[cfg(feature = "faer-backend")]
    let info =
        crate::faer_backend::multishift_qr_window(want_t, want_z, n, 1, n, h, ldh, wr, wi, z, ldz);
    #[cfg(not(feature = "faer-backend"))]
    let info = crate::hqr::dlahqr(want_t, want_z, n, 1, n, h, ldh, wr, wi, 1, n, z, ldz);
    if (want_t || info != 0) && n > 2 {
        for j in 0..n - 2 {
            for i in j + 2..n {
                set(h, ldh, i, j, 0.0);
            }
        }
    }
    info
}

/// `DGEHRD`: reduce `A` to upper Hessenberg form by `Q'*A*Q`. On return the
/// Hessenberg matrix is in the upper triangle and first subdiagonal of `A`, and
/// reflector `k` is `TAU(k)` plus `V(k+2:)` below it — the packed form `dorghr`
/// consumes. `ilo`/`ihi` are LAPACK's 1-based active window.
pub fn dgehrd(
    n: usize,
    ilo: usize,
    ihi: usize,
    a: &mut [f64],
    lda: usize,
    tau: &mut [f64],
) -> i32 {
    #[cfg(feature = "faer-backend")]
    if let Some(r) = crate::faer_backend::dgehrd(n, ilo, ihi, a, lda, tau) {
        return r;
    }
    dgehrd_ref(n, ilo, ihi, a, lda, tau)
}

/// The port of `DGEHRD`, and the only path for a proper `[ilo, ihi]` window.
pub fn dgehrd_ref(
    n: usize,
    ilo: usize,
    ihi: usize,
    a: &mut [f64],
    lda: usize,
    tau: &mut [f64],
) -> i32 {
    if n == 0 || ihi <= ilo {
        return 0;
    }
    // 0-based, and `ihi` is inclusive in LAPACK.
    let (lo, hi) = (ilo - 1, ihi - 1);
    for k in lo..hi.saturating_sub(1).max(lo) {
        if k + 2 > hi {
            break;
        }
        let alpha = at(a, lda, k + 1, k);
        let (beta, t) = dlarfg(alpha, &mut a[k + 2 + k * lda..hi + 1 + k * lda]);
        tau[k] = t;
        let v: Vec<f64> = a[k + 2 + k * lda..hi + 1 + k * lda].to_vec();
        // The similarity transform, not a one-sided factorization. Right before
        // left, as DGEHD2 does: the two orders differ in the last bits, and the
        // Schur form they lead to picks a different — equally valid — 2x2 block
        // representation for a complex pair, which is visible in `dgeev`'s
        // eigenvectors.
        let rows = hi - k;
        crate::blas::dlarf_right(&v, t, hi + 1, rows, &mut a[(k + 1) * lda..], lda);
        let rest = &mut a[(k + 1) * lda..];
        dlarf_left(&v, t, rows, n - k - 1, &mut rest[k + 1..], lda);
        set(a, lda, k + 1, k, beta);
        for i in k + 2..=hi {
            set(a, lda, i, k, v[i - k - 2]);
        }
    }
    0
}

/// `DORGHR`: form the `Q` of a [`dgehrd`] reduction. `a` holds that packed form on
/// input and `Q` on output.
pub fn dorghr(
    n: usize,
    ilo: usize,
    ihi: usize,
    a: &mut [f64],
    lda: usize,
    tau: &[f64],
) -> i32 {
    let (lo, hi) = (ilo - 1, ihi.saturating_sub(1));
    // Shift the reflector columns one to the right and make everything outside
    // the active window the identity — DORGHR's own setup, after which the
    // reflectors sit on the sub-block's subdiagonal and DORGQR consumes them
    // exactly as it does a `dgeqrf` factorization.
    for j in (lo + 1..=hi).rev() {
        for i in 0..j {
            set(a, lda, i, j, 0.0);
        }
        for i in j + 1..=hi {
            let v = at(a, lda, i, j - 1);
            set(a, lda, i, j, v);
        }
        for i in hi + 1..n {
            set(a, lda, i, j, 0.0);
        }
    }
    for j in (0..=lo).chain(hi + 1..n) {
        for i in 0..n {
            set(a, lda, i, j, if i == j { 1.0 } else { 0.0 });
        }
    }
    let nh = hi - lo;
    if nh > 0 {
        // The sub-block at (lo+1, lo+1) shares the caller's leading dimension, so
        // it is a suffix of the same buffer rather than a copy.
        crate::qr::dorgqr(nh, nh, nh - 1, &mut a[(lo + 1) + (lo + 1) * lda..], lda, &tau[lo..lo + nh - 1]);
    }
    0
}

/// `DTRSYL`: solve `op(A)*X + isgn*X*op(B) = scale*C` for quasi-upper-triangular
/// `A` (`m`×`m`) and `B` (`n`×`n`), overwriting `C` with `X`. Returns
/// `(scale, INFO)`; `INFO = 1` means `A` and `B` have eigenvalues so close that
/// the solution was perturbed, as LAPACK reports it.
///
/// Bartels–Stewart: one `p*q ≤ 4` Sylvester system per pair of diagonal blocks,
/// taken in the order that leaves both coupling sums already solved.
///
/// A transposed operand is handled by reversing its index order rather than by a
/// second recursion: `J*A'*J` is quasi-upper-triangular again, with the same
/// blocks in the opposite order, and `J` on `X` and `C` cancels through.
#[allow(clippy::too_many_arguments)]
pub fn dtrsyl(
    trana: &str,
    tranb: &str,
    isgn: i32,
    m: usize,
    n: usize,
    a: &[f64],
    lda: usize,
    b: &[f64],
    ldb: usize,
    c: &mut [f64],
    ldc: usize,
) -> (f64, i32) {
    if m == 0 || n == 0 {
        return (1.0, 0);
    }
    let (ta, tb) = (opt(trana) != b'N', opt(tranb) != b'N');
    let (aa, bb) = (reversed(m, a, lda, ta), reversed(n, b, ldb, tb));
    let idx = |i: usize, j: usize| {
        (if ta { m - 1 - i } else { i }) + (if tb { n - 1 - j } else { j }) * m
    };
    let mut x = vec![0.0f64; m * n];
    for j in 0..n {
        for i in 0..m {
            x[idx(i, j)] = at(c, ldc, i, j);
        }
    }
    let info = sylvester(m, n, &aa, &bb, isgn as f64, &mut x);
    for j in 0..n {
        for i in 0..m {
            set(c, ldc, i, j, x[idx(i, j)]);
        }
    }
    (1.0, info)
}

/// A packed copy of an `n`×`n` matrix, index-reversed and transposed (`J*M'*J`)
/// when `t`.
fn reversed(n: usize, src: &[f64], ld: usize, t: bool) -> Vec<f64> {
    let mut out = vec![0.0f64; n * n];
    for j in 0..n {
        for i in 0..n {
            out[i + j * n] = if t { at(src, ld, n - 1 - j, n - 1 - i) } else { at(src, ld, i, j) };
        }
    }
    out
}

/// The `(start, size)` of each diagonal block of a quasi-upper-triangular matrix.
/// The real Schur form leaves an exact zero on the subdiagonal between blocks, so
/// the test is exact, as LAPACK's is.
fn quasi_blocks(n: usize, m: &[f64]) -> Vec<(usize, usize)> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < n {
        let size = if i + 1 < n && m[i + 1 + i * n] != 0.0 { 2 } else { 1 };
        out.push((i, size));
        i += size;
    }
    out
}

/// The `("N", "N")` Bartels–Stewart recursion over packed `a`/`b`, `x` holding `C`
/// on entry and `X` on return.
fn sylvester(m: usize, n: usize, a: &[f64], b: &[f64], sgn: f64, x: &mut [f64]) -> i32 {
    let a_blocks = quasi_blocks(m, a);
    let b_blocks = quasi_blocks(n, b);
    // Block row K of A depends on the rows below it and block column L of B on
    // the columns left of it, so K descends while L ascends.
    let mut info = 0;
    for &(l, q) in &b_blocks {
        for &(k, p) in a_blocks.iter().rev() {
            let mut rhs = vec![0.0f64; p * q];
            for jj in 0..q {
                for ii in 0..p {
                    let mut v = x[(k + ii) + (l + jj) * m];
                    for r in k + p..m {
                        v -= a[(k + ii) + r * m] * x[r + (l + jj) * m];
                    }
                    for r in 0..l {
                        v -= sgn * x[(k + ii) + r * m] * b[r + (l + jj) * n];
                    }
                    rhs[ii + jj * p] = v;
                }
            }
            let ak: Vec<f64> = (0..p * p).map(|t| a[(k + t % p) + (k + t / p) * m]).collect();
            let bl: Vec<f64> = (0..q * q).map(|t| b[(l + t % q) + (l + t / q) * n]).collect();
            info |= solve_block_sylvester(p, q, &ak, &bl, sgn, &mut rhs);
            for jj in 0..q {
                for ii in 0..p {
                    x[(k + ii) + (l + jj) * m] = rhs[ii + jj * p];
                }
            }
        }
    }
    info
}

/// `Ak*Z + sgn*Z*Bl = rhs` for blocks of order 1 or 2, as the `p*q`-square
/// Kronecker system `(I ⊗ Ak + sgn * Bl' ⊗ I) vec(Z) = vec(rhs)`. A pivot too
/// small to divide by (the two blocks share an eigenvalue) is raised to `smin`
/// and reported as `INFO = 1`, which is what LAPACK's perturbation does.
fn solve_block_sylvester(p: usize, q: usize, ak: &[f64], bl: &[f64], sgn: f64, rhs: &mut [f64]) -> i32 {
    let s = p * q;
    let mut mat = vec![0.0f64; s * s];
    for jj in 0..q {
        for ii in 0..p {
            let r = ii + jj * p;
            for j2 in 0..q {
                for i2 in 0..p {
                    let c = i2 + j2 * p;
                    let mut v = 0.0;
                    if jj == j2 {
                        v += ak[ii + i2 * p];
                    }
                    if ii == i2 {
                        v += sgn * bl[j2 + jj * q];
                    }
                    mat[r + c * s] = v;
                }
            }
        }
    }
    let scale = ak.iter().chain(bl).fold(0.0f64, |m, v| m.max(abs(*v)));
    let smin = (crate::EPS * scale).max(crate::SAFMIN);
    let mut info = 0;
    for col in 0..s {
        let piv = (col..s).max_by(|x, y| abs(mat[*x + col * s]).total_cmp(&abs(mat[*y + col * s]))).unwrap();
        if piv != col {
            for j in 0..s {
                mat.swap(col + j * s, piv + j * s);
            }
            rhs.swap(col, piv);
        }
        if abs(mat[col + col * s]) < smin {
            mat[col + col * s] = smin;
            info = 1;
        }
        for r in col + 1..s {
            let f = mat[r + col * s] / mat[col + col * s];
            for j in col..s {
                mat[r + j * s] -= f * mat[col + j * s];
            }
            rhs[r] -= f * rhs[col];
        }
    }
    for col in (0..s).rev() {
        let mut v = rhs[col];
        for j in col + 1..s {
            v -= mat[col + j * s] * rhs[j];
        }
        rhs[col] = v / mat[col + col * s];
    }
    info
}

/// `DHGEQZ`: the QZ iteration on an already Hessenberg-triangular pair `(H, T)`.
/// Needs `faer-backend`; without a QZ here there is nothing to fall back on, so
/// it reports `INFO = n+1`, which is LAPACK's "the iteration failed" code.
#[allow(clippy::too_many_arguments)]
pub fn dhgeqz(
    job: &str,
    compq: &str,
    compz: &str,
    n: usize,
    h: &mut [f64],
    ldh: usize,
    t: &mut [f64],
    ldt: usize,
    alphar: &mut [f64],
    alphai: &mut [f64],
    beta: &mut [f64],
    q: &mut [f64],
    ldq: usize,
    z: &mut [f64],
    ldz: usize,
) -> i32 {
    #[cfg(feature = "faer-backend")]
    return crate::faer_backend::dhgeqz(
        job, compq, compz, n, h, ldh, t, ldt, alphar, alphai, beta, q, ldq, z, ldz,
    );
    #[cfg(not(feature = "faer-backend"))]
    {
        let _ = (job, compq, compz, h, ldh, t, ldt, alphar, alphai, beta, q, ldq, z, ldz);
        (n + 1) as i32
    }
}
