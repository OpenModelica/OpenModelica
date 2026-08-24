//! LAPACK's Fortran ABI: every argument by reference, `<name>_` symbols. These
//! are what a generated wasm module's `external "FORTRAN 77"` calls bind to once
//! `liblapack.wasm` is linked in.
//!
//! # Character arguments
//!
//! Real Fortran passes a hidden length after every `CHARACTER*(*)`, but OMC's C
//! target declares them as a bare `char*` (`extTypeF77` in
//! `CodegenCFunctions.tpl` yields `char`, and `extFunDefArgF77` adds no length),
//! relying on LAPACK reading only the first character through `LSAME`. These
//! entry points match that: `*const c_char`, no length, first byte only. That
//! also means they never need the string NUL-terminated.
//!
//! # `WORK` / `LWORK`
//!
//! Accepted and ignored — this crate allocates its own workspace. A query
//! (`lwork = -1`) writes the size the reference implementation would report into
//! `work[0]` and returns without computing anything, so MSL's
//! `lwork = max(1, 12*n)` sizing and any query-then-call caller both work.

use core::ffi::c_char;

use crate::{band, chol, eig, gev, lu, qr, svd};

/// The first character of a Fortran character argument, uppercased. A null
/// pointer reads as a space, which no LAPACK option matches.
unsafe fn ch(p: *const c_char) -> &'static str {
    // The routines below compare only the first byte, so a 1-byte view is enough
    // and the caller need not NUL-terminate.
    const TABLE: [&str; 26] = [
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R",
        "S", "T", "U", "V", "W", "X", "Y", "Z",
    ];
    if p.is_null() {
        return " ";
    }
    let b = unsafe { *p } as u8;
    match b.to_ascii_uppercase() {
        c @ b'A'..=b'Z' => TABLE[(c - b'A') as usize],
        b'1' => "1",
        b'2' => "2",
        _ => " ",
    }
}

unsafe fn u(p: *const i32) -> usize {
    unsafe { (*p).max(0) as usize }
}

/// Answer an `LWORK = -1` workspace query. Returns whether it was one.
unsafe fn query(lwork: *const i32, work: *mut f64, size: usize) -> bool {
    if lwork.is_null() || unsafe { *lwork } != -1 {
        return false;
    }
    if !work.is_null() {
        unsafe { *work = size.max(1) as f64 };
    }
    true
}

macro_rules! sl {
    ($p:expr, $n:expr) => {
        unsafe { core::slice::from_raw_parts_mut($p, $n) }
    };
}
macro_rules! slc {
    ($p:expr, $n:expr) => {
        unsafe { core::slice::from_raw_parts($p, $n) }
    };
}

// ───────────────────────────── LU family ─────────────────────────────

#[unsafe(no_mangle)]
pub unsafe extern "C" fn dgesv_(
    n: *const i32,
    nrhs: *const i32,
    a: *mut f64,
    lda: *const i32,
    ipiv: *mut i32,
    b: *mut f64,
    ldb: *const i32,
    info: *mut i32,
) {
    let (n, nrhs, lda, ldb) = unsafe { (u(n), u(nrhs), u(lda), u(ldb)) };
    let r = lu::dgesv(
        n,
        nrhs,
        sl!(a, lda * n.max(1)),
        lda,
        sl!(ipiv, n),
        sl!(b, ldb * nrhs.max(1)),
        ldb,
    );
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn dgetrf_(
    m: *const i32,
    n: *const i32,
    a: *mut f64,
    lda: *const i32,
    ipiv: *mut i32,
    info: *mut i32,
) {
    let (m, n, lda) = unsafe { (u(m), u(n), u(lda)) };
    let r = lu::dgetrf(m, n, sl!(a, lda * n.max(1)), lda, sl!(ipiv, m.min(n)));
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn dgetrs_(
    trans: *const c_char,
    n: *const i32,
    nrhs: *const i32,
    a: *const f64,
    lda: *const i32,
    ipiv: *const i32,
    b: *mut f64,
    ldb: *const i32,
    info: *mut i32,
) {
    let (n, nrhs, lda, ldb) = unsafe { (u(n), u(nrhs), u(lda), u(ldb)) };
    let r = lu::dgetrs(
        unsafe { ch(trans) },
        n,
        nrhs,
        slc!(a, lda * n.max(1)),
        lda,
        slc!(ipiv, n),
        sl!(b, ldb * nrhs.max(1)),
        ldb,
    );
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn dgetri_(
    n: *const i32,
    a: *mut f64,
    lda: *const i32,
    ipiv: *const i32,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (n, lda) = unsafe { (u(n), u(lda)) };
    if unsafe { query(lwork, work, n) } {
        unsafe { *info = 0 };
        return;
    }
    let r = lu::dgetri(n, sl!(a, lda * n.max(1)), lda, slc!(ipiv, n));
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn dgecon_(
    norm: *const c_char,
    n: *const i32,
    a: *const f64,
    lda: *const i32,
    anorm: *const f64,
    rcond: *mut f64,
    _work: *mut f64,
    _iwork: *mut i32,
    info: *mut i32,
) {
    let (n, lda) = unsafe { (u(n), u(lda)) };
    let (r, i) =
        lu::dgecon(unsafe { ch(norm) }, n, slc!(a, lda * n.max(1)), lda, unsafe { *anorm });
    unsafe {
        *rcond = r;
        *info = i;
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn dlange_(
    norm: *const c_char,
    m: *const i32,
    n: *const i32,
    a: *const f64,
    lda: *const i32,
    _work: *mut f64,
) -> f64 {
    let (m, n, lda) = unsafe { (u(m), u(n), u(lda)) };
    lu::dlange(unsafe { ch(norm) }, m, n, slc!(a, lda * n.max(1)), lda)
}

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dgesvx_(
    fact: *const c_char,
    trans: *const c_char,
    n: *const i32,
    nrhs: *const i32,
    a: *mut f64,
    lda: *const i32,
    af: *mut f64,
    ldaf: *const i32,
    ipiv: *mut i32,
    _equed: *mut c_char,
    _r: *mut f64,
    _c: *mut f64,
    b: *const f64,
    ldb: *const i32,
    x: *mut f64,
    ldx: *const i32,
    rcond: *mut f64,
    ferr: *mut f64,
    berr: *mut f64,
    _work: *mut f64,
    _iwork: *mut i32,
    info: *mut i32,
) {
    let (n, nrhs) = unsafe { (u(n), u(nrhs)) };
    let (lda, ldaf, ldb, ldx) = unsafe { (u(lda), u(ldaf), u(ldb), u(ldx)) };
    let (rc, i) = lu::dgesvx(
        unsafe { ch(fact) },
        unsafe { ch(trans) },
        n,
        nrhs,
        sl!(a, lda * n.max(1)),
        lda,
        sl!(af, ldaf * n.max(1)),
        ldaf,
        sl!(ipiv, n),
        slc!(b, ldb * nrhs.max(1)),
        ldb,
        sl!(x, ldx * nrhs.max(1)),
        ldx,
        sl!(ferr, nrhs),
        sl!(berr, nrhs),
    );
    unsafe {
        *rcond = rc;
        *info = i;
    }
}

// ─────────────────────────── Cholesky ───────────────────────────

#[unsafe(no_mangle)]
pub unsafe extern "C" fn dpotrf_(
    uplo: *const c_char,
    n: *const i32,
    a: *mut f64,
    lda: *const i32,
    info: *mut i32,
) {
    let (n, lda) = unsafe { (u(n), u(lda)) };
    let r = chol::dpotrf(unsafe { ch(uplo) }, n, sl!(a, lda * n.max(1)), lda);
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn dpotrs_(
    uplo: *const c_char,
    n: *const i32,
    nrhs: *const i32,
    a: *const f64,
    lda: *const i32,
    b: *mut f64,
    ldb: *const i32,
    info: *mut i32,
) {
    let (n, nrhs, lda, ldb) = unsafe { (u(n), u(nrhs), u(lda), u(ldb)) };
    let r = chol::dpotrs(
        unsafe { ch(uplo) },
        n,
        nrhs,
        slc!(a, lda * n.max(1)),
        lda,
        sl!(b, ldb * nrhs.max(1)),
        ldb,
    );
    unsafe { *info = r };
}

// ───────────────────────────── QR family ─────────────────────────────

#[unsafe(no_mangle)]
pub unsafe extern "C" fn dgeqrf_(
    m: *const i32,
    n: *const i32,
    a: *mut f64,
    lda: *const i32,
    tau: *mut f64,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (m, n, lda) = unsafe { (u(m), u(n), u(lda)) };
    if unsafe { query(lwork, work, n) } {
        unsafe { *info = 0 };
        return;
    }
    let r = qr::dgeqrf(m, n, sl!(a, lda * n.max(1)), lda, sl!(tau, m.min(n)));
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn dgeqp3_(
    m: *const i32,
    n: *const i32,
    a: *mut f64,
    lda: *const i32,
    jpvt: *mut i32,
    tau: *mut f64,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (m, n, lda) = unsafe { (u(m), u(n), u(lda)) };
    if unsafe { query(lwork, work, 3 * n + 1) } {
        unsafe { *info = 0 };
        return;
    }
    let r = qr::dgeqp3(m, n, sl!(a, lda * n.max(1)), lda, sl!(jpvt, n), sl!(tau, m.min(n)));
    unsafe { *info = r };
}

/// The deprecated predecessor of [`dgeqp3_`]: no `LWORK`, same factorization.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn dgeqpf_(
    m: *const i32,
    n: *const i32,
    a: *mut f64,
    lda: *const i32,
    jpvt: *mut i32,
    tau: *mut f64,
    _work: *mut f64,
    info: *mut i32,
) {
    let (m, n, lda) = unsafe { (u(m), u(n), u(lda)) };
    let r = qr::dgeqpf(m, n, sl!(a, lda * n.max(1)), lda, sl!(jpvt, n), sl!(tau, m.min(n)));
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn dorgqr_(
    m: *const i32,
    n: *const i32,
    k: *const i32,
    a: *mut f64,
    lda: *const i32,
    tau: *const f64,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (m, n, k, lda) = unsafe { (u(m), u(n), u(k), u(lda)) };
    if unsafe { query(lwork, work, n) } {
        unsafe { *info = 0 };
        return;
    }
    let r = qr::dorgqr(m, n, k, sl!(a, lda * n.max(1)), lda, slc!(tau, k));
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dormqr_(
    side: *const c_char,
    trans: *const c_char,
    m: *const i32,
    n: *const i32,
    k: *const i32,
    a: *const f64,
    lda: *const i32,
    tau: *const f64,
    c: *mut f64,
    ldc: *const i32,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (m, n, k, lda, ldc) = unsafe { (u(m), u(n), u(k), u(lda), u(ldc)) };
    if unsafe { query(lwork, work, n.max(m)) } {
        unsafe { *info = 0 };
        return;
    }
    let r = qr::dormqr(
        unsafe { ch(side) },
        unsafe { ch(trans) },
        m,
        n,
        k,
        slc!(a, lda * k.max(1)),
        lda,
        slc!(tau, k),
        sl!(c, ldc * n.max(1)),
        ldc,
    );
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dgels_(
    trans: *const c_char,
    m: *const i32,
    n: *const i32,
    nrhs: *const i32,
    a: *mut f64,
    lda: *const i32,
    b: *mut f64,
    ldb: *const i32,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (m, n, nrhs, lda, ldb) = unsafe { (u(m), u(n), u(nrhs), u(lda), u(ldb)) };
    if unsafe { query(lwork, work, m.min(n) + m.max(n).max(nrhs)) } {
        unsafe { *info = 0 };
        return;
    }
    let r = qr::dgels(
        unsafe { ch(trans) },
        m,
        n,
        nrhs,
        sl!(a, lda * n.max(1)),
        lda,
        sl!(b, ldb * nrhs.max(1)),
        ldb,
    );
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dgelsy_(
    m: *const i32,
    n: *const i32,
    nrhs: *const i32,
    a: *mut f64,
    lda: *const i32,
    b: *mut f64,
    ldb: *const i32,
    jpvt: *mut i32,
    rcond: *const f64,
    rank: *mut i32,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (m, n, nrhs, lda, ldb) = unsafe { (u(m), u(n), u(nrhs), u(lda), u(ldb)) };
    if unsafe { query(lwork, work, 3 * n + 1 + 2 * n.max(nrhs)) } {
        unsafe { *info = 0 };
        return;
    }
    let (rk, i) = qr::dgelsy(
        m,
        n,
        nrhs,
        slc!(a, lda * n.max(1)),
        lda,
        sl!(b, ldb * nrhs.max(1)),
        ldb,
        sl!(jpvt, n),
        unsafe { *rcond },
    );
    unsafe {
        *rank = rk as i32;
        *info = i;
    }
}

/// The deprecated predecessor of [`dgelsy_`]: no `LWORK`, same solution.
#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dgelsx_(
    m: *const i32,
    n: *const i32,
    nrhs: *const i32,
    a: *mut f64,
    lda: *const i32,
    b: *mut f64,
    ldb: *const i32,
    jpvt: *mut i32,
    rcond: *const f64,
    rank: *mut i32,
    _work: *mut f64,
    info: *mut i32,
) {
    let (m, n, nrhs, lda, ldb) = unsafe { (u(m), u(n), u(nrhs), u(lda), u(ldb)) };
    let (rk, i) = qr::dgelsx(
        m,
        n,
        nrhs,
        slc!(a, lda * n.max(1)),
        lda,
        sl!(b, ldb * nrhs.max(1)),
        ldb,
        sl!(jpvt, n),
        unsafe { *rcond },
    );
    unsafe {
        *rank = rk as i32;
        *info = i;
    }
}

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dgglse_(
    m: *const i32,
    n: *const i32,
    p: *const i32,
    a: *mut f64,
    lda: *const i32,
    b: *mut f64,
    ldb: *const i32,
    c: *mut f64,
    d: *mut f64,
    x: *mut f64,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (m, n, p, lda, ldb) = unsafe { (u(m), u(n), u(p), u(lda), u(ldb)) };
    if unsafe { query(lwork, work, m + n + p) } {
        unsafe { *info = 0 };
        return;
    }
    let r = qr::dgglse(
        m,
        n,
        p,
        slc!(a, lda * n.max(1)),
        lda,
        slc!(b, ldb * n.max(1)),
        ldb,
        slc!(c, m),
        slc!(d, p),
        sl!(x, n),
    );
    unsafe { *info = r };
}

// ───────────────────────────── SVD ─────────────────────────────

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dgesvd_(
    jobu: *const c_char,
    jobvt: *const c_char,
    m: *const i32,
    n: *const i32,
    a: *mut f64,
    lda: *const i32,
    s: *mut f64,
    u_: *mut f64,
    ldu: *const i32,
    vt: *mut f64,
    ldvt: *const i32,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (m, n, lda, ldu, ldvt) = unsafe { (u(m), u(n), u(lda), u(ldu), u(ldvt)) };
    if unsafe { query(lwork, work, 5 * m.min(n).max(1) + m.max(n)) } {
        unsafe { *info = 0 };
        return;
    }
    let r = svd::dgesvd(
        unsafe { ch(jobu) },
        unsafe { ch(jobvt) },
        m,
        n,
        sl!(a, lda * n.max(1)),
        lda,
        sl!(s, m.min(n)),
        sl!(u_, ldu * m.max(1)),
        ldu,
        sl!(vt, ldvt * n.max(1)),
        ldvt,
    );
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dgesdd_(
    jobz: *const c_char,
    m: *const i32,
    n: *const i32,
    a: *mut f64,
    lda: *const i32,
    s: *mut f64,
    u_: *mut f64,
    ldu: *const i32,
    vt: *mut f64,
    ldvt: *const i32,
    work: *mut f64,
    lwork: *const i32,
    _iwork: *mut i32,
    info: *mut i32,
) {
    let (m, n, lda, ldu, ldvt) = unsafe { (u(m), u(n), u(lda), u(ldu), u(ldvt)) };
    if unsafe { query(lwork, work, 4 * m.min(n) * m.min(n) + 7 * m.min(n)) } {
        unsafe { *info = 0 };
        return;
    }
    let r = svd::dgesdd(
        unsafe { ch(jobz) },
        m,
        n,
        sl!(a, lda * n.max(1)),
        lda,
        sl!(s, m.min(n)),
        sl!(u_, ldu * m.max(1)),
        ldu,
        sl!(vt, ldvt * n.max(1)),
        ldvt,
    );
    unsafe { *info = r };
}

// ─────────────────── eigenvalues / Schur / Hessenberg ───────────────────

/// `VL`/`VR` are untouched: [`gev::dgegv`] serves `JOBVL = JOBVR = "N"` only and
/// reports anything else as a bad argument.
#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dgegv_(
    jobvl: *const c_char,
    jobvr: *const c_char,
    n: *const i32,
    a: *mut f64,
    lda: *const i32,
    b: *mut f64,
    ldb: *const i32,
    alphar: *mut f64,
    alphai: *mut f64,
    beta: *mut f64,
    _vl: *mut f64,
    _ldvl: *const i32,
    _vr: *mut f64,
    _ldvr: *const i32,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (n, lda, ldb) = unsafe { (u(n), u(lda), u(ldb)) };
    if unsafe { query(lwork, work, 8 * n.max(1)) } {
        unsafe { *info = 0 };
        return;
    }
    let r = gev::dgegv(
        unsafe { ch(jobvl) },
        unsafe { ch(jobvr) },
        n,
        slc!(a, lda * n.max(1)),
        lda,
        slc!(b, ldb * n.max(1)),
        ldb,
        sl!(alphar, n),
        sl!(alphai, n),
        sl!(beta, n),
    );
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dgeev_(
    jobvl: *const c_char,
    jobvr: *const c_char,
    n: *const i32,
    a: *mut f64,
    lda: *const i32,
    wr: *mut f64,
    wi: *mut f64,
    vl: *mut f64,
    ldvl: *const i32,
    vr: *mut f64,
    ldvr: *const i32,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (n, lda, ldvl, ldvr) = unsafe { (u(n), u(lda), u(ldvl), u(ldvr)) };
    if unsafe { query(lwork, work, 4 * n.max(1)) } {
        unsafe { *info = 0 };
        return;
    }
    let r = eig::dgeev(
        unsafe { ch(jobvl) },
        unsafe { ch(jobvr) },
        n,
        slc!(a, lda * n.max(1)),
        lda,
        sl!(wr, n),
        sl!(wi, n),
        sl!(vl, ldvl * n.max(1)),
        ldvl,
        sl!(vr, ldvr * n.max(1)),
        ldvr,
    );
    unsafe { *info = r };
}

/// `DGEES` takes a `SELECT` function pointer, which is only read when
/// `sort = "S"` — unsupported, so the pointer is ignored.
#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dgees_(
    jobvs: *const c_char,
    sort: *const c_char,
    _select: *const core::ffi::c_void,
    n: *const i32,
    a: *mut f64,
    lda: *const i32,
    sdim: *mut i32,
    wr: *mut f64,
    wi: *mut f64,
    vs: *mut f64,
    ldvs: *const i32,
    work: *mut f64,
    lwork: *const i32,
    _bwork: *mut i32,
    info: *mut i32,
) {
    let (n, lda, ldvs) = unsafe { (u(n), u(lda), u(ldvs)) };
    if unsafe { query(lwork, work, 3 * n.max(1)) } {
        unsafe { *info = 0 };
        return;
    }
    let r = eig::dgees(
        unsafe { ch(jobvs) },
        unsafe { ch(sort) },
        n,
        sl!(a, lda * n.max(1)),
        lda,
        sl!(wr, n),
        sl!(wi, n),
        sl!(vs, ldvs * n.max(1)),
        ldvs,
    );
    unsafe {
        if !sdim.is_null() {
            *sdim = 0;
        }
        *info = r;
    }
}

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dhseqr_(
    job: *const c_char,
    compz: *const c_char,
    n: *const i32,
    _ilo: *const i32,
    _ihi: *const i32,
    h: *mut f64,
    ldh: *const i32,
    wr: *mut f64,
    wi: *mut f64,
    z: *mut f64,
    ldz: *const i32,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (n, ldh, ldz) = unsafe { (u(n), u(ldh), u(ldz)) };
    if unsafe { query(lwork, work, n.max(1)) } {
        unsafe { *info = 0 };
        return;
    }
    let r = eig::dhseqr(
        unsafe { ch(job) },
        unsafe { ch(compz) },
        n,
        sl!(h, ldh * n.max(1)),
        ldh,
        sl!(wr, n),
        sl!(wi, n),
        sl!(z, ldz * n.max(1)),
        ldz,
    );
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn dgehrd_(
    n: *const i32,
    ilo: *const i32,
    ihi: *const i32,
    a: *mut f64,
    lda: *const i32,
    tau: *mut f64,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (n, ilo, ihi, lda) = unsafe { (u(n), u(ilo), u(ihi), u(lda)) };
    if unsafe { query(lwork, work, n.max(1)) } {
        unsafe { *info = 0 };
        return;
    }
    let r = eig::dgehrd(n, ilo, ihi, sl!(a, lda * n.max(1)), lda, sl!(tau, n.max(1) - 1));
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn dorghr_(
    n: *const i32,
    ilo: *const i32,
    ihi: *const i32,
    a: *mut f64,
    lda: *const i32,
    tau: *const f64,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (n, ilo, ihi, lda) = unsafe { (u(n), u(ilo), u(ihi), u(lda)) };
    if unsafe { query(lwork, work, n.max(1)) } {
        unsafe { *info = 0 };
        return;
    }
    let r = eig::dorghr(n, ilo, ihi, sl!(a, lda * n.max(1)), lda, slc!(tau, n.max(1) - 1));
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dtrsyl_(
    trana: *const c_char,
    tranb: *const c_char,
    isgn: *const i32,
    m: *const i32,
    n: *const i32,
    a: *const f64,
    lda: *const i32,
    b: *const f64,
    ldb: *const i32,
    c: *mut f64,
    ldc: *const i32,
    scale: *mut f64,
    info: *mut i32,
) {
    let (m, n, lda, ldb, ldc) = unsafe { (u(m), u(n), u(lda), u(ldb), u(ldc)) };
    let (s, i) = eig::dtrsyl(
        unsafe { ch(trana) },
        unsafe { ch(tranb) },
        unsafe { *isgn },
        m,
        n,
        slc!(a, lda * m.max(1)),
        lda,
        slc!(b, ldb * n.max(1)),
        ldb,
        sl!(c, ldc * n.max(1)),
        ldc,
    );
    unsafe {
        *scale = s;
        *info = i;
    }
}

// ───────────────────────── banded / tridiagonal ─────────────────────────

#[unsafe(no_mangle)]
pub unsafe extern "C" fn dgtsv_(
    n: *const i32,
    nrhs: *const i32,
    dl: *mut f64,
    d: *mut f64,
    du: *mut f64,
    b: *mut f64,
    ldb: *const i32,
    info: *mut i32,
) {
    let (n, nrhs, ldb) = unsafe { (u(n), u(nrhs), u(ldb)) };
    let r = band::dgtsv(
        n,
        nrhs,
        sl!(dl, n.max(1) - 1),
        sl!(d, n),
        sl!(du, n.max(1) - 1),
        sl!(b, ldb * nrhs.max(1)),
        ldb,
    );
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dgbsv_(
    n: *const i32,
    kl: *const i32,
    ku: *const i32,
    nrhs: *const i32,
    ab: *mut f64,
    ldab: *const i32,
    ipiv: *mut i32,
    b: *mut f64,
    ldb: *const i32,
    info: *mut i32,
) {
    let (n, kl, ku, nrhs) = unsafe { (u(n), u(kl), u(ku), u(nrhs)) };
    let (ldab, ldb) = unsafe { (u(ldab), u(ldb)) };
    let r = band::dgbsv(
        n,
        kl,
        ku,
        nrhs,
        sl!(ab, ldab * n.max(1)),
        ldab,
        sl!(ipiv, n),
        sl!(b, ldb * nrhs.max(1)),
        ldb,
    );
    unsafe { *info = r };
}

// ───────────────────────────── BLAS ─────────────────────────────

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dtrsm_(
    side: *const c_char,
    uplo: *const c_char,
    transa: *const c_char,
    diag: *const c_char,
    m: *const i32,
    n: *const i32,
    alpha: *const f64,
    a: *const f64,
    lda: *const i32,
    b: *mut f64,
    ldb: *const i32,
) {
    let (m, n, lda, ldb) = unsafe { (u(m), u(n), u(lda), u(ldb)) };
    let k = if unsafe { ch(side) } == "L" { m } else { n };
    crate::blas::dtrsm(
        unsafe { ch(side) },
        unsafe { ch(uplo) },
        unsafe { ch(transa) },
        unsafe { ch(diag) },
        m,
        n,
        unsafe { *alpha },
        slc!(a, lda * k.max(1)),
        lda,
        sl!(b, ldb * n.max(1)),
        ldb,
    );
}

// ───────────────────────────── generalized eigenproblem ─────────────────────

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dggev_(
    jobvl: *const c_char,
    jobvr: *const c_char,
    n: *const i32,
    a: *mut f64,
    lda: *const i32,
    b: *mut f64,
    ldb: *const i32,
    alphar: *mut f64,
    alphai: *mut f64,
    beta: *mut f64,
    vl: *mut f64,
    ldvl: *const i32,
    vr: *mut f64,
    ldvr: *const i32,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (n, lda, ldb, ldvl, ldvr) = unsafe { (u(n), u(lda), u(ldb), u(ldvl), u(ldvr)) };
    if unsafe { query(lwork, work, 8 * n.max(1)) } {
        unsafe { *info = 0 };
        return;
    }
    let want_l = unsafe { ch(jobvl) } == "V";
    let want_r = unsafe { ch(jobvr) } == "V";
    let r = gev::dggev(
        unsafe { ch(jobvl) },
        unsafe { ch(jobvr) },
        n,
        slc!(a, lda * n.max(1)),
        lda,
        slc!(b, ldb * n.max(1)),
        ldb,
        sl!(alphar, n),
        sl!(alphai, n),
        sl!(beta, n),
        if want_l { sl!(vl, ldvl * n.max(1)) } else { &mut [] },
        ldvl,
        if want_r { sl!(vr, ldvr * n.max(1)) } else { &mut [] },
        ldvr,
    );
    unsafe { *info = r };
}

/// `DGGEVX` is `DGGEV` plus balancing and the condition estimates. The
/// eigenvalues and eigenvectors are the same, so the reciprocal condition
/// numbers are reported as `1` and the balancing as the identity — MSL's
/// `eigenValues`-style callers read the eigen-decomposition, not `rconde`.
#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dggevx_(
    _balanc: *const c_char,
    jobvl: *const c_char,
    jobvr: *const c_char,
    _sense: *const c_char,
    n: *const i32,
    a: *mut f64,
    lda: *const i32,
    b: *mut f64,
    ldb: *const i32,
    alphar: *mut f64,
    alphai: *mut f64,
    beta: *mut f64,
    vl: *mut f64,
    ldvl: *const i32,
    vr: *mut f64,
    ldvr: *const i32,
    ilo: *mut i32,
    ihi: *mut i32,
    lscale: *mut f64,
    rscale: *mut f64,
    abnrm: *mut f64,
    bbnrm: *mut f64,
    rconde: *mut f64,
    rcondv: *mut f64,
    work: *mut f64,
    lwork: *const i32,
    _iwork: *mut i32,
    _bwork: *mut i32,
    info: *mut i32,
) {
    let nn = unsafe { u(n) };
    if unsafe { query(lwork, work, 2 * nn * nn + 12 * nn + 16) } {
        unsafe { *info = 0 };
        return;
    }
    unsafe {
        *ilo = 1;
        *ihi = nn as i32;
        *abnrm = lu::dlange("1", nn, nn, slc!(a, u(lda) * nn.max(1)), u(lda));
        *bbnrm = lu::dlange("1", nn, nn, slc!(b, u(ldb) * nn.max(1)), u(ldb));
    }
    for k in 0..nn {
        unsafe {
            *lscale.add(k) = 1.0;
            *rscale.add(k) = 1.0;
            *rconde.add(k) = 1.0;
            *rcondv.add(k) = 1.0;
        }
    }
    unsafe {
        dggev_(
            jobvl, jobvr, n, a, lda, b, ldb, alphar, alphai, beta, vl, ldvl, vr, ldvr, work,
            lwork, info,
        )
    };
}

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dhgeqz_(
    job: *const c_char,
    compq: *const c_char,
    compz: *const c_char,
    n: *const i32,
    _ilo: *const i32,
    _ihi: *const i32,
    h: *mut f64,
    ldh: *const i32,
    t: *mut f64,
    ldt: *const i32,
    alphar: *mut f64,
    alphai: *mut f64,
    beta: *mut f64,
    q: *mut f64,
    ldq: *const i32,
    z: *mut f64,
    ldz: *const i32,
    work: *mut f64,
    lwork: *const i32,
    info: *mut i32,
) {
    let (n, ldh, ldt, ldq, ldz) = unsafe { (u(n), u(ldh), u(ldt), u(ldq), u(ldz)) };
    if unsafe { query(lwork, work, n.max(1)) } {
        unsafe { *info = 0 };
        return;
    }
    let want_q = unsafe { ch(compq) } != "N";
    let want_z = unsafe { ch(compz) } != "N";
    let r = eig::dhgeqz(
        unsafe { ch(job) },
        unsafe { ch(compq) },
        unsafe { ch(compz) },
        n,
        sl!(h, ldh * n.max(1)),
        ldh,
        sl!(t, ldt * n.max(1)),
        ldt,
        sl!(alphar, n),
        sl!(alphai, n),
        sl!(beta, n),
        if want_q { sl!(q, ldq * n.max(1)) } else { &mut [] },
        ldq,
        if want_z { sl!(z, ldz * n.max(1)) } else { &mut [] },
        ldz,
    );
    unsafe { *info = r };
}

#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn dtrevc_(
    side: *const c_char,
    howmny: *const c_char,
    _select: *mut i32,
    n: *const i32,
    t: *const f64,
    ldt: *const i32,
    vl: *mut f64,
    ldvl: *const i32,
    vr: *mut f64,
    ldvr: *const i32,
    mm: *const i32,
    m: *mut i32,
    _work: *mut f64,
    info: *mut i32,
) {
    let (n, ldt, ldvl, ldvr, mm) = unsafe { (u(n), u(ldt), u(ldvl), u(ldvr), u(mm)) };
    let want_l = matches!(unsafe { ch(side) }, "L" | "B");
    let want_r = matches!(unsafe { ch(side) }, "R" | "B");
    let r = crate::trevc::dtrevc_lapack(
        unsafe { ch(side) },
        unsafe { ch(howmny) },
        n,
        slc!(t, ldt * n.max(1)),
        ldt,
        if want_l { sl!(vl, ldvl * mm.max(1)) } else { &mut [] },
        ldvl,
        if want_r { sl!(vr, ldvr * mm.max(1)) } else { &mut [] },
        ldvr,
        mm,
        unsafe { &mut *m },
    );
    unsafe { *info = r };
}
