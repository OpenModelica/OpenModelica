//! LAPACK routines over faer's decompositions.
//!
//! faer is column-major with an explicit column stride, which is LAPACK's own
//! layout, so most of these hand the caller's buffer straight to faer rather than
//! copying it. What is left here is LAPACK's packaging: `IPIV` as a swap
//! sequence, `INFO`, the `job` letters, and the conjugate-pair convention.

use core::cell::RefCell;
use core::mem::MaybeUninit;

use faer::dyn_stack::{MemBuffer, MemStack, StackReq};
use faer::prelude::*;
use faer::{Par, Spec, linalg};

use crate::opt;

std::thread_local! {
    /// faer asks for scratch memory per call; on a small matrix that allocation
    /// is most of the work. One buffer per thread, grown to the largest request.
    static SCRATCH: RefCell<Vec<MaybeUninit<u8>>> = const { RefCell::new(Vec::new()) };
    /// The same, for the permutations the LU wrappers translate `IPIV` through:
    /// six vectors per `dgetrf`/`dgetrs` pair.
    static PERM: RefCell<Vec<usize>> = const { RefCell::new(Vec::new()) };
}

/// faer 0.24.4's `gevd_scratch`/`hessenberg_to_qz_scratch` under-report for
/// `n <= 5`, and `gevd_real` then panics inside faer. Sizing for a larger
/// problem covers the shortfall. `tests/small_gevd.rs` pins it.
const GEVD_MIN_SCRATCH_DIM: usize = 8;

/// Run `f` with `req` bytes of scratch. Falls back to a fresh buffer if the
/// thread's is already in use, so a nested call cannot panic on the borrow.
fn with_stack<R>(req: StackReq, f: impl FnOnce(&mut MemStack) -> R) -> R {
    let need = req.size_bytes() + req.align_bytes();
    let mut f = Some(f);
    let reused = SCRATCH.with(|s| match s.try_borrow_mut() {
        Ok(mut buf) => {
            if buf.len() < need {
                buf.resize(need, MaybeUninit::uninit());
            }
            Some(f.take().expect("called once")(MemStack::new(&mut buf[..])))
        }
        Err(_) => None,
    });
    match reused {
        Some(r) => r,
        None => f.take().expect("called once")(MemStack::new(&mut MemBuffer::new(req))),
    }
}

/// Run `f` with `len` `usize`s of scratch, reused like [`with_stack`]. The
/// contents are the previous call's; every caller initialises what it reads.
fn with_perm<R>(len: usize, f: impl FnOnce(&mut [usize]) -> R) -> R {
    let mut f = Some(f);
    let reused = PERM.with(|s| match s.try_borrow_mut() {
        Ok(mut buf) => {
            if buf.len() < len {
                buf.resize(len, 0);
            }
            Some(f.take().expect("called once")(&mut buf[..len]))
        }
        Err(_) => None,
    });
    match reused {
        Some(r) => r,
        None => f.take().expect("called once")(&mut vec![0usize; len]),
    }
}

fn view<'a>(a: &'a mut [f64], m: usize, n: usize, lda: usize) -> MatMut<'a, f64> {
    MatMut::from_column_major_slice_with_stride_mut(&mut a[..lda * (n - 1) + m], m, n, lda)
}

fn view_ref<'a>(a: &'a [f64], m: usize, n: usize, lda: usize) -> MatRef<'a, f64> {
    MatRef::from_column_major_slice_with_stride(&a[..lda * (n - 1) + m], m, n, lda)
}

/// `IPIV` is the sequence of row swaps applied left to right; faer reports the
/// resulting permutation. Exact both ways: step `j` brings the row that belongs
/// at `j` there with one swap.
fn ipiv_from_perm(perm: &[usize], ipiv: &mut [i32], k: usize, scratch: &mut [usize]) {
    let m = perm.len();
    let (at, pos) = scratch.split_at_mut(m);
    for i in 0..m {
        at[i] = i;
        pos[i] = i;
    }
    for (j, slot) in ipiv.iter_mut().enumerate().take(k) {
        let want = perm[j];
        let p = pos[want];
        *slot = (p + 1) as i32;
        let (aj, ap) = (at[j], at[p]);
        at.swap(j, p);
        pos[aj] = p;
        pos[ap] = j;
    }
}

/// `DGETRF`: `A = P*L*U` in place, `IPIV` 1-based, `INFO` the first zero pivot.
pub fn dgetrf(m: usize, n: usize, a: &mut [f64], lda: usize, ipiv: &mut [i32]) -> i32 {
    let minmn = m.min(n);
    if minmn == 0 {
        return 0;
    }
    let req = linalg::lu::partial_pivoting::factor::lu_in_place_scratch::<usize, f64>(
        m,
        n,
        Par::Seq,
        Spec::default(),
    );
    with_perm(4 * m, |bufs| {
        let (perm, rest) = bufs.split_at_mut(m);
        let (perm_inv, swaps) = rest.split_at_mut(m);
        with_stack(req, |stack| {
            let mat = view(a, m, n, lda);
            let p = linalg::lu::partial_pivoting::factor::lu_in_place(
                mat,
                perm,
                perm_inv,
                Par::Seq,
                stack,
                Spec::default(),
            )
            .1;
            ipiv_from_perm(p.arrays().0, ipiv, minmn, swaps);
        });
    });
    for j in 0..minmn {
        if a[j + j * lda] == 0.0 {
            return (j + 1) as i32;
        }
    }
    0
}

/// `DPOTRF`: only the named triangle is read and written, as LAPACK leaves the
/// other alone. faer factors the lower triangle, so `"U"` is mirrored in and the
/// transpose written back.
pub fn dpotrf(uplo: &str, n: usize, a: &mut [f64], lda: usize) -> i32 {
    if n == 0 {
        return 0;
    }
    let upper = opt(uplo) == b'U';
    let mut work = Mat::<f64>::from_fn(n, n, |i, j| {
        let (r, c) = if upper { (i.min(j), i.max(j)) } else { (i.max(j), i.min(j)) };
        a[r + c * lda]
    });
    let mut mem = MemBuffer::new(linalg::cholesky::llt::factor::cholesky_in_place_scratch::<f64>(
        n,
        Par::Seq,
        Spec::default(),
    ));
    let info = linalg::cholesky::llt::factor::cholesky_in_place(
        work.as_mut(),
        Default::default(),
        Par::Seq,
        MemStack::new(&mut mem),
        Spec::default(),
    );
    match info {
        Ok(_) => {
            for j in 0..n {
                for i in j..n {
                    let v = work[(i, j)];
                    if upper {
                        a[j + i * lda] = v;
                    } else {
                        a[i + j * lda] = v;
                    }
                }
            }
            0
        }
        // faer reports no index, so LAPACK's INFO is the first leading minor that
        // is not positive definite. Off the happy path, so it costs nothing when
        // `A` is SPD.
        Err(_) => {
            for k in 1..=n {
                let mut lead = Mat::<f64>::from_fn(k, k, |i, j| {
                    let (r, c) =
                        if upper { (i.min(j), i.max(j)) } else { (i.max(j), i.min(j)) };
                    a[r + c * lda]
                });
                let mut mem =
                    MemBuffer::new(linalg::cholesky::llt::factor::cholesky_in_place_scratch::<
                        f64,
                    >(k, Par::Seq, Spec::default()));
                if linalg::cholesky::llt::factor::cholesky_in_place(
                    lead.as_mut(),
                    Default::default(),
                    Par::Seq,
                    MemStack::new(&mut mem),
                    Spec::default(),
                )
                .is_err()
                {
                    return k as i32;
                }
            }
            1
        }
    }
}

/// `DGESVD`. faer computes the full factors directly (`u` may be `m`×`m`), so
/// `"A"` needs no basis completion. faer returns `V`; LAPACK wants `V^T`.
#[allow(clippy::too_many_arguments)]
pub fn dgesvd(
    jobu: &str,
    jobvt: &str,
    m: usize,
    n: usize,
    a: &mut [f64],
    lda: usize,
    s: &mut [f64],
    u: &mut [f64],
    ldu: usize,
    vt: &mut [f64],
    ldvt: usize,
) -> i32 {
    let (ju, jvt) = (opt(jobu), opt(jobvt));
    if !matches!(ju, b'A' | b'S' | b'O' | b'N') {
        return -1;
    }
    if !matches!(jvt, b'A' | b'S' | b'O' | b'N') || (jvt == b'O' && ju == b'O') {
        return -2;
    }
    let minmn = m.min(n);
    if minmn == 0 {
        return 0;
    }
    let ncu = match ju {
        b'A' => m,
        b'N' => 0,
        _ => minmn,
    };
    let ncv = match jvt {
        b'A' => n,
        b'N' => 0,
        _ => minmn,
    };
    // DGESVD scales `A` into range and scales the singular values back; faer
    // does not, and overflows without it.
    let smlnum = crate::sqrt(crate::SAFMIN) / crate::PREC;
    let bignum = 1.0 / smlnum;
    let anrm = crate::dlange("M", m, n, a, lda);
    let scale_to = if anrm > 0.0 && anrm < smlnum {
        Some(smlnum)
    } else if anrm > bignum {
        Some(bignum)
    } else {
        None
    };
    let scaled = scale_to.map(|to| {
        let mut c = crate::pack(m, n, a, lda);
        for j in 0..n {
            crate::hqr::dlascl(anrm, to, &mut c[j * m..j * m + m]);
        }
        c
    });
    let mut su = Mat::<f64>::zeros(m, ncu.max(1));
    let mut sv = Mat::<f64>::zeros(n, ncv.max(1));
    let mut sd = faer::diag::Diag::<f64>::zeros(minmn);
    let cu = svd_vectors(ju, m, minmn);
    let cv = svd_vectors(jvt, n, minmn);
    let mut mem = MemBuffer::new(linalg::svd::svd_scratch::<f64>(
        m,
        n,
        cu,
        cv,
        Par::Seq,
        Spec::default(),
    ));
    let r = linalg::svd::svd(
        match &scaled {
            Some(c) => view_ref(c, m, n, m),
            None => view_ref(a, m, n, lda),
        },
        sd.as_mut(),
        (ncu > 0).then(|| su.as_mut()),
        (ncv > 0).then(|| sv.as_mut()),
        Par::Seq,
        MemStack::new(&mut mem),
        Spec::default(),
    );
    if r.is_err() {
        return 1;
    }
    for k in 0..minmn {
        s[k] = sd[k];
    }
    if let Some(to) = scale_to {
        crate::hqr::dlascl(to, anrm, &mut s[..minmn]);
    }
    if ncu > 0 {
        let (dst, ld) = if ju == b'O' { (&mut *a, lda) } else { (&mut *u, ldu) };
        for j in 0..ncu {
            for i in 0..m {
                dst[i + j * ld] = su[(i, j)];
            }
        }
    }
    if ncv > 0 {
        let rows = ncv;
        let (dst, ld) = if jvt == b'O' { (&mut *a, lda) } else { (&mut *vt, ldvt) };
        for j in 0..n {
            for i in 0..rows {
                dst[i + j * ld] = sv[(j, i)];
            }
        }
    }
    0
}

fn svd_vectors(job: u8, full: usize, thin: usize) -> linalg::svd::ComputeSvdVectors {
    use linalg::svd::ComputeSvdVectors::*;
    match job {
        b'N' => No,
        b'A' if full > thin => Full,
        _ => Thin,
    }
}

/// `DGEEV`: eigenvalues, and eigenvectors in LAPACK's packed real form — a
/// conjugate pair is two adjacent columns, real part then imaginary, positive
/// imaginary first. faer's `evd_real` already uses that convention.
///
/// `DGEBAL`/`DGEBAK` stay on this side of the call: faer's `evd_real` does not
/// balance, and on a matrix whose rows span a few decades — a state matrix in
/// mixed units — the unbalanced QR iteration loses digits the Fortran does not.
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
    if n == 0 {
        return 0;
    }
    let want_l = opt(jobvl) == b'V';
    let want_r = opt(jobvr) == b'V';
    let mut h = crate::pack(n, n, a, lda);
    let unscale = crate::eig::prescale(n, &mut h, n);
    let (ilo, ihi, scale) = crate::hqr::dgebal("B", n, &mut h, n);
    let mut sre = faer::diag::Diag::<f64>::zeros(n);
    let mut sim = faer::diag::Diag::<f64>::zeros(n);
    let mut ul = Mat::<f64>::zeros(n, n);
    let mut ur = Mat::<f64>::zeros(n, n);
    let mut mem = MemBuffer::new(linalg::evd::evd_scratch::<f64>(
        n,
        if want_l { linalg::evd::ComputeEigenvectors::Yes } else { linalg::evd::ComputeEigenvectors::No },
        if want_r { linalg::evd::ComputeEigenvectors::Yes } else { linalg::evd::ComputeEigenvectors::No },
        Par::Seq,
        Spec::default(),
    ));
    let r = linalg::evd::evd_real(
        view_ref(&h, n, n, n),
        sre.as_mut(),
        sim.as_mut(),
        want_l.then(|| ul.as_mut()),
        want_r.then(|| ur.as_mut()),
        Par::Seq,
        MemStack::new(&mut mem),
        Spec::default(),
    );
    if r.is_err() {
        return 1;
    }
    for k in 0..n {
        wr[k] = sre[k];
        wi[k] = sim[k];
    }
    for (want, src, v, ldv, side) in
        [(want_r, &ur, &mut *vr, ldvr, "R"), (want_l, &ul, &mut *vl, ldvl, "L")]
    {
        if !want {
            continue;
        }
        for j in 0..n {
            for i in 0..n {
                v[i + j * ldv] = src[(i, j)];
            }
        }
        crate::hqr::dgebak("B", side, n, ilo, ihi, &scale, n, v, ldv);
        crate::eig::normalize_eigenvectors(v, ldv, n, wi);
    }
    if let Some(f) = unscale {
        crate::hqr::dlascl(1.0, f, &mut wr[..n]);
        crate::hqr::dlascl(1.0, f, &mut wi[..n]);
    }
    0
}

/// Write faer's eigenvectors out in LAPACK's convention: Euclidean norm 1, and
/// for a conjugate pair (two adjacent columns, real part then imaginary) the
/// component of largest modulus made real.
fn copy_eigenvectors(n: usize, src: &Mat<f64>, wi: &[f64], dst: &mut [f64], ld: usize) {
    let mut j = 0;
    while j < n {
        if wi[j] == 0.0 {
            let norm = (0..n).map(|i| src[(i, j)] * src[(i, j)]).sum::<f64>().sqrt();
            let f = if norm > 0.0 { 1.0 / norm } else { 1.0 };
            for i in 0..n {
                dst[i + j * ld] = src[(i, j)] * f;
            }
            j += 1;
        } else {
            let norm = (0..n)
                .map(|i| src[(i, j)] * src[(i, j)] + src[(i, j + 1)] * src[(i, j + 1)])
                .sum::<f64>()
                .sqrt();
            let f = if norm > 0.0 { 1.0 / norm } else { 1.0 };
            // Rotate so the largest-modulus component has no imaginary part.
            let mut k = 0;
            let mut best = -1.0;
            for i in 0..n {
                let v = src[(i, j)] * src[(i, j)] + src[(i, j + 1)] * src[(i, j + 1)];
                if v > best {
                    best = v;
                    k = i;
                }
            }
            let r = best.sqrt();
            let (c, sn) = if r > 0.0 {
                (src[(k, j)] / r, src[(k, j + 1)] / r)
            } else {
                (1.0, 0.0)
            };
            for i in 0..n {
                let (re, im) = (src[(i, j)], src[(i, j + 1)]);
                dst[i + j * ld] = (re * c + im * sn) * f;
                dst[i + (j + 1) * ld] = (im * c - re * sn) * f;
            }
            j += 2;
        }
    }
}

// `DHSEQR`/`DGEES` are not here: faer computes a real Schur form internally but
// `linalg::evd::schur::real_schur` is `pub(crate)`, so `multishift_qr` cannot be
// called from outside the crate — only its `multishift_qr_scratch` sizing
// function is exported, which looks like an oversight worth raising upstream.
// Until then `hqr.rs` keeps those two.

/// `DLAHQR`'s contract over faer's multishift QR: `[ilo, ihi]` is LAPACK's
/// 1-based inclusive window, and the return is `INFO`.
#[allow(clippy::too_many_arguments)]
pub fn multishift_qr_window(
    want_t: bool,
    want_z: bool,
    n: usize,
    ilo: usize,
    ihi: usize,
    h: &mut [f64],
    ldh: usize,
    wr: &mut [f64],
    wi: &mut [f64],
    z: &mut [f64],
    ldz: usize,
) -> i32 {
    use faer::Auto;
    use faer::linalg::evd::schur::SchurParams;

    let params = <SchurParams as Auto<f64>>::auto();
    let req = linalg::evd::schur::multishift_qr_scratch::<f64>(
        n,
        ihi - ilo + 1,
        want_z,
        want_t,
        Par::Seq,
        params,
    );
    let mut zmat = want_z.then(|| Mat::<f64>::from_fn(n, n, |i, j| z[i + j * ldz]));
    let info = with_stack(req, |stack| {
        let hm = view(h, n, n, ldh);
        crate::faer_real_schur::multishift_qr(
            want_t,
            hm,
            zmat.as_mut().map(|m| m.as_mut()),
            ColMut::from_slice_mut(&mut wr[..n]),
            ColMut::from_slice_mut(&mut wi[..n]),
            ilo - 1,
            ihi,
            Par::Seq,
            stack,
            params,
        )
        .0
    });
    if let Some(m) = zmat {
        for j in 0..n {
            for i in 0..n {
                z[i + j * ldz] = m[(i, j)];
            }
        }
    }
    info as i32
}

/// `DGGEV`: the generalized eigenvalues of `(A, B)` as
/// `(ALPHAR + i*ALPHAI) / BETA`, and optionally the eigenvectors. A real QZ, so
/// a singular `B` gives the `BETA = 0` infinite eigenvalues LAPACK reports.
#[allow(clippy::too_many_arguments)]
pub fn dggev(
    jobvl: &str,
    jobvr: &str,
    n: usize,
    a: &[f64],
    lda: usize,
    b: &[f64],
    ldb: usize,
    alphar: &mut [f64],
    alphai: &mut [f64],
    beta: &mut [f64],
    vl: &mut [f64],
    ldvl: usize,
    vr: &mut [f64],
    ldvr: usize,
) -> i32 {
    use faer::linalg::evd::ComputeEigenvectors as CE;

    if n == 0 {
        return 0;
    }
    let want_l = opt(jobvl) == b'V';
    let want_r = opt(jobvr) == b'V';
    // gevd_real consumes A and B.
    let mut am = Mat::<f64>::from_fn(n, n, |i, j| a[i + j * lda]);
    let mut bm = Mat::<f64>::from_fn(n, n, |i, j| b[i + j * ldb]);
    let mut sre = faer::diag::Diag::<f64>::zeros(n);
    let mut sim = faer::diag::Diag::<f64>::zeros(n);
    let mut bet = faer::diag::Diag::<f64>::zeros(n);
    let mut ul = Mat::<f64>::zeros(n, n);
    let mut ur = Mat::<f64>::zeros(n, n);
    let req = linalg::gevd::gevd_scratch::<f64>(
        n.max(GEVD_MIN_SCRATCH_DIM),
        if want_l { CE::Yes } else { CE::No },
        if want_r { CE::Yes } else { CE::No },
        Par::Seq,
        Spec::default(),
    );
    let r = with_stack(req, |stack| {
        linalg::gevd::gevd_real(
            am.as_mut(),
            bm.as_mut(),
            sre.as_mut(),
            sim.as_mut(),
            bet.as_mut(),
            want_l.then(|| ul.as_mut()),
            want_r.then(|| ur.as_mut()),
            Par::Seq,
            stack,
            Spec::default(),
        )
    });
    if r.is_err() {
        return 1;
    }
    for k in 0..n {
        alphar[k] = sre[k];
        alphai[k] = sim[k];
        beta[k] = bet[k];
    }
    conjugate_pairs(n, alphar, alphai, beta);
    if want_l {
        copy_eigenvectors(n, &ul, alphai, vl, ldvl);
    }
    if want_r {
        copy_eigenvectors(n, &ur, alphai, vr, ldvr);
    }
    0
}

/// `DHGEQZ`: the QZ iteration on an already Hessenberg-triangular pair. `job`
/// `"E"` returns eigenvalues only, `"S"` also the generalized Schur form in
/// `h`/`t`; `compq`/`compz` are `"I"` (start from the identity), `"V"`
/// (accumulate into the caller's) or `"N"`.
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
    use faer::Auto;
    use faer::linalg::evd::ComputeEigenvectors as CE;
    use faer::linalg::gevd::GeneralizedSchurParams;

    if n == 0 {
        return 0;
    }
    let want_s = opt(job) == b'S';
    let (cq, cz) = (opt(compq), opt(compz));
    if !matches!(opt(job), b'E' | b'S') {
        return -1;
    }
    if !matches!(cq, b'N' | b'I' | b'V') {
        return -2;
    }
    if !matches!(cz, b'N' | b'I' | b'V') {
        return -3;
    }
    let mut am = Mat::<f64>::from_fn(n, n, |i, j| h[i + j * ldh]);
    let mut bm = Mat::<f64>::from_fn(n, n, |i, j| t[i + j * ldt]);
    let mut qm = (cq != b'N').then(|| match cq {
        b'V' => Mat::<f64>::from_fn(n, n, |i, j| q[i + j * ldq]),
        _ => Mat::<f64>::identity(n, n),
    });
    let mut zm = (cz != b'N').then(|| match cz {
        b'V' => Mat::<f64>::from_fn(n, n, |i, j| z[i + j * ldz]),
        _ => Mat::<f64>::identity(n, n),
    });
    let mut ar = faer::Col::<f64>::zeros(n);
    let mut ai = faer::Col::<f64>::zeros(n);
    let mut be = faer::Col::<f64>::zeros(n);
    let params = <GeneralizedSchurParams as Auto<f64>>::auto();
    let req = linalg::gevd::qz_real::hessenberg_to_qz_scratch::<f64>(
        n.max(GEVD_MIN_SCRATCH_DIM),
        Par::Seq,
        params,
    );
    with_stack(req, |stack| {
        linalg::gevd::qz_real::hessenberg_to_qz(
            am.as_mut(),
            bm.as_mut(),
            qm.as_mut().map(|m| m.as_mut()),
            zm.as_mut().map(|m| m.as_mut()),
            ar.as_mut(),
            ai.as_mut(),
            be.as_mut(),
            if want_s { CE::Yes } else { CE::No },
            Par::Seq,
            params,
            stack,
        )
    });
    for k in 0..n {
        alphar[k] = ar[k];
        alphai[k] = ai[k];
        beta[k] = be[k];
    }
    conjugate_pairs(n, alphar, alphai, beta);
    if want_s {
        for j in 0..n {
            for i in 0..n {
                h[i + j * ldh] = am[(i, j)];
                t[i + j * ldt] = bm[(i, j)];
            }
        }
    }
    if let Some(m) = qm {
        for j in 0..n {
            for i in 0..n {
                q[i + j * ldq] = m[(i, j)];
            }
        }
    }
    if let Some(m) = zm {
        for j in 0..n {
            for i in 0..n {
                z[i + j * ldz] = m[(i, j)];
            }
        }
    }
    0
}

/// faer's real QZ writes a conjugate pair's eigenvalue into the first slot
/// only; the second holds the 2x2 block's other diagonal entry, which is not an
/// eigenvalue. faer's own `solvers.rs::real_to_cplx` discards it the same way.
/// Forcing the conjugate is also LAPACK's convention.
fn conjugate_pairs(n: usize, alphar: &mut [f64], alphai: &mut [f64], beta: &mut [f64]) {
    let mut k = 0;
    while k < n {
        if alphai[k] != 0.0 && k + 1 < n {
            alphar[k + 1] = alphar[k];
            alphai[k + 1] = -alphai[k];
            beta[k + 1] = beta[k];
            k += 2;
        } else {
            k += 1;
        }
    }
}

/// `DGEQRF` over faer's blocked Householder QR.
///
/// faer stores the same reflectors, and with a block size of 1 its `Q_coeff`
/// row is `TAU` reciprocated (`inf` where LAPACK has `0`). So the output is
/// LAPACK's, and `dorgqr`/`dormqr`/`dgels` consume it unchanged.
pub fn dgeqrf(m: usize, n: usize, a: &mut [f64], lda: usize, tau: &mut [f64]) -> i32 {
    let k = m.min(n);
    if k == 0 {
        return 0;
    }
    let mut qc = Mat::<f64>::zeros(1, k);
    let req = linalg::qr::no_pivoting::factor::qr_in_place_scratch::<f64>(
        m,
        n,
        1,
        Par::Seq,
        Spec::default(),
    );
    with_stack(req, |stack| {
        linalg::qr::no_pivoting::factor::qr_in_place(
            view(a, m, n, lda),
            qc.as_mut(),
            Par::Seq,
            stack,
            Spec::default(),
        );
    });
    for (j, t) in tau.iter_mut().enumerate().take(k) {
        let c = qc[(0, j)];
        *t = if c.is_finite() && c != 0.0 { 1.0 / c } else { 0.0 };
    }
    0
}

/// LAPACK's `IPIV` as the permutation faer wants: apply the swaps left to
/// right, which is the inverse of what [`ipiv_from_perm`] reconstructs.
fn perm_from_ipiv_into(ipiv: &[i32], n: usize, fwd: &mut [usize], inv: &mut [usize]) {
    for (i, slot) in fwd.iter_mut().enumerate() {
        *slot = i;
    }
    for (j, &p) in ipiv.iter().enumerate().take(n) {
        let p = (p - 1) as usize;
        if p < n {
            fwd.swap(j, p);
        }
    }
    for (i, &f) in fwd.iter().enumerate() {
        inv[f] = i;
    }
}

fn perm_from_ipiv(ipiv: &[i32], n: usize) -> (Vec<usize>, Vec<usize>) {
    let (mut fwd, mut inv) = (vec![0usize; n], vec![0usize; n]);
    perm_from_ipiv_into(ipiv, n, &mut fwd, &mut inv);
    (fwd, inv)
}

/// `DGETRS`: solve from the packed `L\U` and `IPIV`. faer takes `L` and `U` as
/// separate views over the same packed matrix, as its `PartialPivLu` does.
#[allow(clippy::too_many_arguments)]
pub fn dgetrs(
    trans: &str,
    n: usize,
    nrhs: usize,
    a: &[f64],
    lda: usize,
    ipiv: &[i32],
    b: &mut [f64],
    ldb: usize,
) -> i32 {
    if n == 0 || nrhs == 0 {
        return 0;
    }
    let lu = view_ref(a, n, n, lda);
    let req = linalg::lu::partial_pivoting::solve::solve_in_place_scratch::<usize, f64>(
        n,
        nrhs,
        Par::Seq,
    );
    with_perm(2 * n, |bufs| {
        let (fwd, inv) = bufs.split_at_mut(n);
        perm_from_ipiv_into(ipiv, n, fwd, inv);
        let perm = unsafe { faer::perm::PermRef::new_unchecked(fwd, inv, n) };
        with_stack(req, |stack| {
            let rhs = view(b, n, nrhs, ldb);
            if opt(trans) == b'N' {
                linalg::lu::partial_pivoting::solve::solve_in_place(lu, lu, perm, rhs, Par::Seq, stack);
            } else {
                linalg::lu::partial_pivoting::solve::solve_transpose_in_place(
                    lu, lu, perm, rhs, Par::Seq, stack,
                );
            }
        });
    });
    0
}

/// `DPOTRS`: solve from the Cholesky factor. faer factors the lower triangle,
/// so `"U"` is transposed in.
pub fn dpotrs(uplo: &str, n: usize, nrhs: usize, a: &[f64], lda: usize, b: &mut [f64], ldb: usize) -> i32 {
    if n == 0 || nrhs == 0 {
        return 0;
    }
    let upper = opt(uplo) == b'U';
    let l = Mat::<f64>::from_fn(n, n, |i, j| if upper { a[j + i * lda] } else { a[i + j * lda] });
    let req = linalg::cholesky::llt::solve::solve_in_place_scratch::<f64>(n, nrhs, Par::Seq);
    with_stack(req, |stack| {
        linalg::cholesky::llt::solve::solve_in_place(l.as_ref(), view(b, n, nrhs, ldb), Par::Seq, stack);
    });
    0
}

/// `DGETRI`: `inv(A)` from the packed factors, overwriting `a`. The zero-pivot
/// check is here because faer's `inverse` assumes a nonsingular `U`.
pub fn dgetri(n: usize, a: &mut [f64], lda: usize, ipiv: &[i32]) -> i32 {
    if n == 0 {
        return 0;
    }
    for j in 0..n {
        if a[j + j * lda] == 0.0 {
            return (j + 1) as i32;
        }
    }
    let (fwd, inv) = perm_from_ipiv(ipiv, n);
    let perm = unsafe { faer::perm::PermRef::new_unchecked(&fwd, &inv, n) };
    let mut out = Mat::<f64>::zeros(n, n);
    let req = linalg::lu::partial_pivoting::inverse::inverse_scratch::<usize, f64>(n, Par::Seq);
    with_stack(req, |stack| {
        let lu = view_ref(a, n, n, lda);
        linalg::lu::partial_pivoting::inverse::inverse(out.as_mut(), lu, lu, perm, Par::Seq, stack);
    });
    for j in 0..n {
        for i in 0..n {
            a[i + j * lda] = out[(i, j)];
        }
    }
    0
}

/// `DGEHRD` over faer's Hessenberg reduction, for the full window only.
/// `Some` when faer handled it; `None` when `[ilo, ihi]` is a proper
/// subwindow, which faer cannot express and the port handles.
///
/// Same storage as LAPACK — the reflectors live below the subdiagonal — with
/// the `householder` row reciprocated as in [`dgeqrf`].
pub fn dgehrd(
    n: usize,
    ilo: usize,
    ihi: usize,
    a: &mut [f64],
    lda: usize,
    tau: &mut [f64],
) -> Option<i32> {
    if ilo != 1 || ihi != n {
        return None;
    }
    if n <= 1 {
        return Some(0);
    }
    let mut hh = Mat::<f64>::zeros(1, n - 1);
    let req = linalg::evd::hessenberg::hessenberg_in_place_scratch::<f64>(
        n,
        1,
        Par::Seq,
        Spec::default(),
    );
    with_stack(req, |stack| {
        linalg::evd::hessenberg::hessenberg_in_place(
            view(a, n, n, lda),
            hh.as_mut(),
            Par::Seq,
            stack,
            Spec::default(),
        );
    });
    for (j, t) in tau.iter_mut().enumerate().take(n - 1) {
        let c = hh[(0, j)];
        *t = if c.is_finite() && c != 0.0 { 1.0 / c } else { 0.0 };
    }
    Some(0)
}

/// faer's Householder factor for a block size of 1: `TAU` reciprocated, in the
/// shape its `apply_block_householder_sequence_*` functions expect.
fn householder_factor(tau: &[f64], k: usize) -> Mat<f64> {
    Mat::from_fn(1, k, |_, j| if tau[j] != 0.0 { 1.0 / tau[j] } else { f64::INFINITY })
}

/// `DORMQR`: multiply `C` by `Q` (or `Q'`) from a `dgeqrf` factorization.
#[allow(clippy::too_many_arguments)]
pub fn dormqr(
    side: &str,
    trans: &str,
    m: usize,
    n: usize,
    k: usize,
    a: &[f64],
    lda: usize,
    tau: &[f64],
    c: &mut [f64],
    ldc: usize,
) -> i32 {
    use linalg::householder as hh;

    if m == 0 || n == 0 || k == 0 {
        return 0;
    }
    let left = opt(side) == b'L';
    let transpose = opt(trans) == b'T';
    // The reflectors span `m` rows when applied on the left, `n` on the right.
    let rows = if left { m } else { n };
    let basis = view_ref(a, rows, k, lda);
    let hf = householder_factor(tau, k);
    let req = if left {
        hh::apply_block_householder_sequence_on_the_left_in_place_scratch::<f64>(rows, 1, n)
    } else {
        hh::apply_block_householder_sequence_on_the_right_in_place_scratch::<f64>(rows, 1, m)
    };
    with_stack(req, |stack| {
        let cm = view(c, m, n, ldc);
        match (left, transpose) {
            (true, false) => hh::apply_block_householder_sequence_on_the_left_in_place_with_conj(
                basis, hf.as_ref(), faer::Conj::No, cm, Par::Seq, stack),
            (true, true) => hh::apply_block_householder_sequence_transpose_on_the_left_in_place_with_conj(
                basis, hf.as_ref(), faer::Conj::No, cm, Par::Seq, stack),
            (false, false) => hh::apply_block_householder_sequence_on_the_right_in_place_with_conj(
                basis, hf.as_ref(), faer::Conj::No, cm, Par::Seq, stack),
            (false, true) => hh::apply_block_householder_sequence_transpose_on_the_right_in_place_with_conj(
                basis, hf.as_ref(), faer::Conj::No, cm, Par::Seq, stack),
        }
    });
    0
}

/// `DORGQR`: expand the reflectors into `Q`'s first `n` columns, by applying
/// the sequence to the identity.
pub fn dorgqr(m: usize, n: usize, k: usize, a: &mut [f64], lda: usize, tau: &[f64]) -> i32 {
    if m == 0 || n == 0 {
        return 0;
    }
    let basis: Vec<f64> = (0..lda * k.max(1)).map(|i| a[i]).collect();
    let mut q = vec![0.0f64; m * n];
    for j in 0..n.min(m) {
        q[j + j * m] = 1.0;
    }
    if k > 0 {
        dormqr("L", "N", m, n, k, &basis, lda, tau, &mut q, m);
    }
    for j in 0..n {
        for i in 0..m {
            a[i + j * lda] = q[i + j * m];
        }
    }
    0
}

/// `DGEQP3`: QR with column pivoting. LAPACK's `JPVT` is 1-based and, on entry,
/// a nonzero entry pins that column to the front; faer always pivots freely, so
/// a pinned column falls back to the port.
pub fn dgeqp3(
    m: usize,
    n: usize,
    a: &mut [f64],
    lda: usize,
    jpvt: &mut [i32],
    tau: &mut [f64],
) -> Option<i32> {
    if jpvt.iter().take(n).any(|&p| p != 0) {
        return None;
    }
    let k = m.min(n);
    if k == 0 {
        return Some(0);
    }
    let mut qc = Mat::<f64>::zeros(1, k);
    let mut perm = vec![0usize; n];
    let mut perm_inv = vec![0usize; n];
    let req = linalg::qr::col_pivoting::factor::qr_in_place_scratch::<usize, f64>(
        m,
        n,
        1,
        Par::Seq,
        Spec::default(),
    );
    with_stack(req, |stack| {
        linalg::qr::col_pivoting::factor::qr_in_place(
            view(a, m, n, lda),
            qc.as_mut(),
            &mut perm,
            &mut perm_inv,
            Par::Seq,
            stack,
            Spec::default(),
        );
    });
    for (j, slot) in jpvt.iter_mut().enumerate().take(n) {
        *slot = (perm[j] + 1) as i32;
    }
    for (j, t) in tau.iter_mut().enumerate().take(k) {
        let c = qc[(0, j)];
        *t = if c.is_finite() && c != 0.0 { 1.0 / c } else { 0.0 };
    }
    Some(0)
}

/// `DTRSM`: solve `op(A)*X = alpha*B` (`side = "L"`) or `X*op(A) = alpha*B`
/// (`"R"`) for a triangular `A`, in place.
///
/// faer solves `A*X = B` from the left only, reading whichever triangle the
/// call names. A transpose is expressed by transposing the view — which also
/// flips the triangle — and the right side by transposing both `A` and `B`,
/// since `X*op(A) = B` is `op(A)'*X' = B'`.
#[allow(clippy::too_many_arguments)]
pub fn dtrsm(
    side: &str,
    uplo: &str,
    transa: &str,
    diag: &str,
    m: usize,
    n: usize,
    alpha: f64,
    a: &[f64],
    lda: usize,
    b: &mut [f64],
    ldb: usize,
) {
    use linalg::triangular_solve as ts;

    if m == 0 || n == 0 {
        return;
    }
    let left = opt(side) == b'L';
    let trans = opt(transa) == b'T' || opt(transa) == b'C';
    let unit = opt(diag) == b'U';
    let lower = opt(uplo) == b'L';
    if alpha != 1.0 {
        for j in 0..n {
            for i in 0..m {
                b[i + j * ldb] *= alpha;
            }
        }
    }
    let k = if left { m } else { n };
    let am = view_ref(a, k, k, lda);
    // faer solves with `op(A)` on the left, which for `side = "R"` is `op(A)'`
    // because `X*op(A) = B` is `op(A)'*X' = B'`. Combining the two transposes
    // leaves one iff `trans == left`, and transposing the view also swaps which
    // triangle is the structural one.
    let (am, lower) = if trans == left { (am.transpose(), !lower) } else { (am, lower) };
    let mut bm = view(b, m, n, ldb);
    let bm = if left { bm.rb_mut() } else { bm.rb_mut().transpose_mut() };
    match (lower, unit) {
        (true, false) => ts::solve_lower_triangular_in_place(am, bm, Par::Seq),
        (true, true) => ts::solve_unit_lower_triangular_in_place(am, bm, Par::Seq),
        (false, false) => ts::solve_upper_triangular_in_place(am, bm, Par::Seq),
        (false, true) => ts::solve_unit_upper_triangular_in_place(am, bm, Par::Seq),
    }
}
