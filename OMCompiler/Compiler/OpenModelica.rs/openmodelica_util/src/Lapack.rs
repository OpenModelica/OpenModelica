// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/Lapack.mo`'s `external "C"`
// declarations, which are thin FFI shims into `runtime/lapackimpl.c`. Like the
// C runtime, we bind the system LAPACK directly through its Fortran ABI (the
// `d*_` symbols, linked via `build.rs`) and reproduce the matrix/vector
// marshalling that `lapackimpl.c` performs:
//
//   * MetaModelica matrices are `list<list<Real>>` (a list of rows). LAPACK
//     expects column-major storage with leading dimension equal to the row
//     count, so element (row i, col j) lives at `buf[j*rows + i]`. This mirrors
//     `alloc_real_matrix`/`mk_rml_real_matrix`.
//   * Vectors are `list<Real>` / `list<Integer>` stored contiguously.
//
// The dimensions handed to each allocation/result-builder are copied verbatim
// from `lapackimpl.c` so the observable behaviour matches the C runtime.
//
// `CHARACTER*1` arguments (`trans`, `jobvl`, …) are passed without the hidden
// Fortran string-length argument, exactly as `lapackimpl.c` does — LAPACK only
// inspects the first character via `LSAME` and never reads the length. The
// LAPACK `integer` type is 32-bit on the system (reference/OpenBLAS LP64
// build), matching the port's `Integer`.

#![allow(non_snake_case)]

use std::sync::Arc;

use arcstr::ArcStr;
use core::ffi::c_char;
use metamodelica::{List, OrderedFloat, Real, nil};

type Mat = Arc<List<Arc<List<Real>>>>;
type Vec64 = Arc<List<Real>>;
type IVec = Arc<List<i32>>;

unsafe extern "C" {
    fn dgeev_(
        jobvl: *const c_char, jobvr: *const c_char, n: *const i32, a: *mut f64, lda: *const i32,
        wr: *mut f64, wi: *mut f64, vl: *mut f64, ldvl: *const i32, vr: *mut f64, ldvr: *const i32,
        work: *mut f64, lwork: *const i32, info: *mut i32,
    );
    fn dgegv_(
        jobvl: *const c_char, jobvr: *const c_char, n: *const i32, a: *mut f64, lda: *const i32,
        b: *mut f64, ldb: *const i32, alphar: *mut f64, alphai: *mut f64, beta: *mut f64,
        vl: *mut f64, ldvl: *const i32, vr: *mut f64, ldvr: *const i32, work: *mut f64,
        lwork: *const i32, info: *mut i32,
    );
    fn dgels_(
        trans: *const c_char, m: *const i32, n: *const i32, nrhs: *const i32, a: *mut f64,
        lda: *const i32, b: *mut f64, ldb: *const i32, work: *mut f64, lwork: *const i32,
        info: *mut i32,
    );
    fn dgelsx_(
        m: *const i32, n: *const i32, nrhs: *const i32, a: *mut f64, lda: *const i32, b: *mut f64,
        ldb: *const i32, jpvt: *mut i32, rcond: *const f64, rank: *mut i32, work: *mut f64,
        info: *mut i32,
    );
    fn dgelsy_(
        m: *const i32, n: *const i32, nrhs: *const i32, a: *mut f64, lda: *const i32, b: *mut f64,
        ldb: *const i32, jpvt: *mut i32, rcond: *const f64, rank: *mut i32, work: *mut f64,
        lwork: *const i32, info: *mut i32,
    );
    fn dgesv_(
        n: *const i32, nrhs: *const i32, a: *mut f64, lda: *const i32, ipiv: *mut i32, b: *mut f64,
        ldb: *const i32, info: *mut i32,
    );
    fn dgglse_(
        m: *const i32, n: *const i32, p: *const i32, a: *mut f64, lda: *const i32, b: *mut f64,
        ldb: *const i32, c: *mut f64, d: *mut f64, x: *mut f64, work: *mut f64, lwork: *const i32,
        info: *mut i32,
    );
    fn dgtsv_(
        n: *const i32, nrhs: *const i32, dl: *mut f64, d: *mut f64, du: *mut f64, b: *mut f64,
        ldb: *const i32, info: *mut i32,
    );
    fn dgbsv_(
        n: *const i32, kl: *const i32, ku: *const i32, nrhs: *const i32, ab: *mut f64,
        ldab: *const i32, ipiv: *mut i32, b: *mut f64, ldb: *const i32, info: *mut i32,
    );
    fn dgesvd_(
        jobu: *const c_char, jobvt: *const c_char, m: *const i32, n: *const i32, a: *mut f64,
        lda: *const i32, s: *mut f64, u: *mut f64, ldu: *const i32, vt: *mut f64, ldvt: *const i32,
        work: *mut f64, lwork: *const i32, info: *mut i32,
    );
    fn dgetrf_(
        m: *const i32, n: *const i32, a: *mut f64, lda: *const i32, ipiv: *mut i32, info: *mut i32,
    );
    fn dgetrs_(
        trans: *const c_char, n: *const i32, nrhs: *const i32, a: *mut f64, lda: *const i32,
        ipiv: *mut i32, b: *mut f64, ldb: *const i32, info: *mut i32,
    );
    fn dgetri_(
        n: *const i32, a: *mut f64, lda: *const i32, ipiv: *mut i32, work: *mut f64,
        lwork: *const i32, info: *mut i32,
    );
    fn dgeqpf_(
        m: *const i32, n: *const i32, a: *mut f64, lda: *const i32, jpvt: *mut i32, tau: *mut f64,
        work: *mut f64, info: *mut i32,
    );
    fn dorgqr_(
        m: *const i32, n: *const i32, k: *const i32, a: *mut f64, lda: *const i32, tau: *mut f64,
        work: *mut f64, lwork: *const i32, info: *mut i32,
    );
    fn dhseqr_(
        job: *const c_char, compz: *const c_char, n: *const i32, ilo: *const i32, ihi: *const i32,
        h: *mut f64, ldh: *const i32, wr: *mut f64, wi: *mut f64, z: *mut f64, ldz: *const i32,
        work: *mut f64, lwork: *const i32, info: *mut i32,
    );
}

/// Read a `list<list<Real>>` of `rows`×`cols` into a column-major `f64` buffer
/// (`buf[j*rows + i]`).
fn mat_in(rows: i32, cols: i32, data: &Mat) -> Vec<f64> {
    let (r, c) = (rows.max(0) as usize, cols.max(0) as usize);
    let mut m = vec![0.0f64; r * c];
    for (i, row) in (&**data).into_iter().enumerate() {
        if i >= r {
            break;
        }
        for (j, v) in (&**row).into_iter().enumerate() {
            if j >= c {
                break;
            }
            m[j * r + i] = v.0;
        }
    }
    m
}

/// Build a `list<list<Real>>` of `rows`×`cols` from a column-major buffer.
fn mat_out(rows: i32, cols: i32, m: &[f64]) -> Mat {
    let (r, c) = (rows.max(0) as usize, cols.max(0) as usize);
    Arc::new(List::from_iter((0..r).map(|i| {
        Arc::new(List::from_iter((0..c).map(|j| OrderedFloat(m[j * r + i]))))
    })))
}

fn vec_in(n: i32, data: &Vec64) -> Vec<f64> {
    let len = n.max(0) as usize;
    let mut v = vec![0.0f64; len];
    for (i, x) in (&**data).into_iter().enumerate() {
        if i >= len {
            break;
        }
        v[i] = x.0;
    }
    v
}

fn vec_out(n: i32, v: &[f64]) -> Vec64 {
    let len = n.max(0) as usize;
    Arc::new(List::from_iter((0..len).map(|i| OrderedFloat(v[i]))))
}

fn ivec_in(n: i32, data: &IVec) -> Vec<i32> {
    let len = n.max(0) as usize;
    let mut v = vec![0i32; len];
    for (i, x) in (&**data).into_iter().enumerate() {
        if i >= len {
            break;
        }
        v[i] = *x;
    }
    v
}

fn ivec_out(n: i32, v: &[i32]) -> IVec {
    let len = n.max(0) as usize;
    Arc::new(List::from_iter((0..len).map(|i| v[i])))
}

/// First byte of a LAPACK single-character option (`"N"`, `"T"`, `"V"`, …).
fn ch(s: &ArcStr) -> c_char {
    *s.as_bytes().first().unwrap_or(&b' ') as c_char
}

pub fn dgeev(
    inJOBVL: ArcStr,
    inJOBVR: ArcStr,
    inN: i32,
    inA: Mat,
    inLDA: i32,
    inLDVL: i32,
    inLDVR: i32,
    inWORK: Vec64,
    inLWORK: i32,
) -> (Mat, Vec64, Vec64, Mat, Mat, Vec64, i32) {
    let mut a = mat_in(inLDA, inN, &inA);
    let mut work = vec_in(inLWORK, &inWORK);
    let mut wr = vec![0.0f64; inN.max(0) as usize];
    let mut wi = vec![0.0f64; inN.max(0) as usize];
    let mut vl = vec![0.0f64; (inLDVL.max(0) * inN.max(0)) as usize];
    let mut vr = vec![0.0f64; (inLDVR.max(0) * inN.max(0)) as usize];
    let (jobvl, jobvr) = (ch(&inJOBVL), ch(&inJOBVR));
    let mut info = 0;
    unsafe {
        dgeev_(
            &jobvl, &jobvr, &inN, a.as_mut_ptr(), &inLDA, wr.as_mut_ptr(), wi.as_mut_ptr(),
            vl.as_mut_ptr(), &inLDVL, vr.as_mut_ptr(), &inLDVR, work.as_mut_ptr(), &inLWORK,
            &mut info,
        );
    }
    (
        mat_out(inLDA, inN, &a),
        vec_out(inN, &wr),
        vec_out(inN, &wi),
        mat_out(inLDVL, inN, &vl),
        mat_out(inLDVR, inN, &vr),
        vec_out(inLWORK, &work),
        info,
    )
}

pub fn dgegv(
    inJOBVL: ArcStr,
    inJOBVR: ArcStr,
    inN: i32,
    inA: Mat,
    inLDA: i32,
    inB: Mat,
    inLDB: i32,
    inLDVL: i32,
    inLDVR: i32,
    inWORK: Vec64,
    inLWORK: i32,
) -> (Vec64, Vec64, Vec64, Mat, Mat, Vec64, i32) {
    let mut a = mat_in(inLDA, inN, &inA);
    let mut b = mat_in(inLDB, inN, &inB);
    let mut alphar = vec![0.0f64; inN.max(0) as usize];
    let mut alphai = vec![0.0f64; inN.max(0) as usize];
    let mut beta = vec![0.0f64; inN.max(0) as usize];
    let mut vl = vec![0.0f64; (inLDVL.max(0) * inN.max(0)) as usize];
    // lapackimpl.c sizes vr with ldvl (not ldvr); reproduce it (they are equal
    // in practice, both = N).
    let mut vr = vec![0.0f64; (inLDVL.max(0) * inN.max(0)) as usize];
    let mut work = vec_in(inLWORK, &inWORK);
    let (jobvl, jobvr) = (ch(&inJOBVL), ch(&inJOBVR));
    let mut info = 0;
    unsafe {
        dgegv_(
            &jobvl, &jobvr, &inN, a.as_mut_ptr(), &inLDA, b.as_mut_ptr(), &inLDB,
            alphar.as_mut_ptr(), alphai.as_mut_ptr(), beta.as_mut_ptr(), vl.as_mut_ptr(), &inLDVL,
            vr.as_mut_ptr(), &inLDVR, work.as_mut_ptr(), &inLWORK, &mut info,
        );
    }
    (
        vec_out(inN, &alphar),
        vec_out(inN, &alphai),
        vec_out(inN, &beta),
        mat_out(inLDVL, inN, &vl),
        mat_out(inLDVL, inN, &vr),
        vec_out(inLWORK, &work),
        info,
    )
}

pub fn dgels(
    inTRANS: ArcStr,
    inM: i32,
    inN: i32,
    inNRHS: i32,
    inA: Mat,
    inLDA: i32,
    inB: Mat,
    inLDB: i32,
    inWORK: Vec64,
    inLWORK: i32,
) -> (Mat, Mat, Vec64, i32) {
    let mut a = mat_in(inLDA, inN, &inA);
    let mut b = mat_in(inLDA, inNRHS, &inB);
    let mut work = vec_in(inLWORK, &inWORK);
    let trans = ch(&inTRANS);
    let mut info = 0;
    unsafe {
        dgels_(
            &trans, &inM, &inN, &inNRHS, a.as_mut_ptr(), &inLDA, b.as_mut_ptr(), &inLDB,
            work.as_mut_ptr(), &inLWORK, &mut info,
        );
    }
    (mat_out(inLDA, inN, &a), mat_out(inLDA, inNRHS, &b), vec_out(inLWORK, &work), info)
}

pub fn dgelsx(
    inM: i32,
    inN: i32,
    inNRHS: i32,
    inA: Mat,
    inLDA: i32,
    inB: Mat,
    inLDB: i32,
    inJPVT: IVec,
    inRCOND: Real,
    inWORK: Vec64,
) -> (Mat, Mat, IVec, i32, i32) {
    let mut a = mat_in(inLDA, inN, &inA);
    let mut b = mat_in(inLDB, inNRHS, &inB);
    let mut jpvt = ivec_in(inN, &inJPVT);
    // Workspace size as computed by lapackimpl.c.
    let mn = inM.min(inN);
    let lwork = (mn + 3 * inN).max(2 * mn + inNRHS);
    let mut work = vec_in(lwork, &inWORK);
    let rcond = inRCOND.0;
    let mut rank = 0;
    let mut info = 0;
    unsafe {
        dgelsx_(
            &inM, &inN, &inNRHS, a.as_mut_ptr(), &inLDA, b.as_mut_ptr(), &inLDB, jpvt.as_mut_ptr(),
            &rcond, &mut rank, work.as_mut_ptr(), &mut info,
        );
    }
    (mat_out(inLDA, inN, &a), mat_out(inLDA, inNRHS, &b), ivec_out(inN, &jpvt), rank, info)
}

pub fn dgelsy(
    inM: i32,
    inN: i32,
    inNRHS: i32,
    inA: Mat,
    inLDA: i32,
    inB: Mat,
    inLDB: i32,
    inJPVT: IVec,
    inRCOND: Real,
    inWORK: Vec64,
    inLWORK: i32,
) -> (Mat, Mat, IVec, i32, Vec64, i32) {
    let mut a = mat_in(inLDA, inN, &inA);
    let mut b = mat_in(inLDB, inNRHS, &inB);
    let mut work = vec_in(inLWORK, &inWORK);
    let mut jpvt = ivec_in(inN, &inJPVT);
    let rcond = inRCOND.0;
    let mut rank = 0;
    let mut info = 0;
    unsafe {
        dgelsy_(
            &inM, &inN, &inNRHS, a.as_mut_ptr(), &inLDA, b.as_mut_ptr(), &inLDB, jpvt.as_mut_ptr(),
            &rcond, &mut rank, work.as_mut_ptr(), &inLWORK, &mut info,
        );
    }
    (
        mat_out(inLDA, inN, &a),
        mat_out(inLDA, inNRHS, &b),
        ivec_out(inN, &jpvt),
        rank,
        vec_out(inLWORK, &work),
        info,
    )
}

pub fn dgesv(inN: i32, inNRHS: i32, inA: Mat, inLDA: i32, inB: Mat, inLDB: i32) -> (Mat, IVec, Mat, i32) {
    let mut a = mat_in(inLDA, inN, &inA);
    let mut b = mat_in(inLDB, inNRHS, &inB);
    let mut ipiv = vec![0i32; inN.max(0) as usize];
    let mut info = 0;
    unsafe {
        dgesv_(&inN, &inNRHS, a.as_mut_ptr(), &inLDA, ipiv.as_mut_ptr(), b.as_mut_ptr(), &inLDB, &mut info);
    }
    (mat_out(inLDA, inN, &a), ivec_out(inN, &ipiv), mat_out(inLDB, inNRHS, &b), info)
}

pub fn dgglse(
    inM: i32,
    inN: i32,
    inP: i32,
    inA: Mat,
    inLDA: i32,
    inB: Mat,
    inLDB: i32,
    inC: Vec64,
    inD: Vec64,
    inWORK: Vec64,
    inLWORK: i32,
) -> (Mat, Mat, Vec64, Vec64, Vec64, Vec64, i32) {
    let mut a = mat_in(inLDA, inN, &inA);
    let mut b = mat_in(inLDB, inN, &inB);
    let mut c = vec_in(inM, &inC);
    let mut d = vec_in(inP, &inD);
    let mut x = vec![0.0f64; inN.max(0) as usize];
    let mut work = vec_in(inLWORK, &inWORK);
    let mut info = 0;
    unsafe {
        dgglse_(
            &inM, &inN, &inP, a.as_mut_ptr(), &inLDA, b.as_mut_ptr(), &inLDB, c.as_mut_ptr(),
            d.as_mut_ptr(), x.as_mut_ptr(), work.as_mut_ptr(), &inLWORK, &mut info,
        );
    }
    (
        mat_out(inLDA, inN, &a),
        mat_out(inLDB, inN, &b),
        vec_out(inM, &c),
        vec_out(inP, &d),
        vec_out(inN, &x),
        vec_out(inLWORK, &work),
        info,
    )
}

pub fn dgtsv(
    inN: i32,
    inNRHS: i32,
    inDL: Vec64,
    inD: Vec64,
    inDU: Vec64,
    inB: Mat,
    inLDB: i32,
) -> (Vec64, Vec64, Vec64, Mat, i32) {
    let mut dl = vec_in(inN - 1, &inDL);
    let mut d = vec_in(inN, &inD);
    let mut du = vec_in(inN - 1, &inDU);
    let mut b = mat_in(inLDB, inNRHS, &inB);
    let mut info = 0;
    unsafe {
        dgtsv_(&inN, &inNRHS, dl.as_mut_ptr(), d.as_mut_ptr(), du.as_mut_ptr(), b.as_mut_ptr(), &inLDB, &mut info);
    }
    (vec_out(inN - 1, &dl), vec_out(inN, &d), vec_out(inN - 1, &du), mat_out(inLDB, inNRHS, &b), info)
}

pub fn dgbsv(
    inN: i32,
    inKL: i32,
    inKU: i32,
    inNRHS: i32,
    inAB: Mat,
    inLDAB: i32,
    inB: Mat,
    inLDB: i32,
) -> (Mat, IVec, Mat, i32) {
    let mut ab = mat_in(inLDAB, inN, &inAB);
    let mut b = mat_in(inLDB, inNRHS, &inB);
    let mut ipiv = vec![0i32; inN.max(0) as usize];
    let mut info = 0;
    unsafe {
        dgbsv_(
            &inN, &inKL, &inKU, &inNRHS, ab.as_mut_ptr(), &inLDAB, ipiv.as_mut_ptr(),
            b.as_mut_ptr(), &inLDB, &mut info,
        );
    }
    (mat_out(inLDAB, inN, &ab), ivec_out(inN, &ipiv), mat_out(inLDB, inNRHS, &b), info)
}

pub fn dgesvd(
    inJOBU: ArcStr,
    inJOBVT: ArcStr,
    inM: i32,
    inN: i32,
    inA: Mat,
    inLDA: i32,
    inLDU: i32,
    inLDVT: i32,
    inWORK: Vec64,
    inLWORK: i32,
) -> (Mat, Vec64, Mat, Mat, Vec64, i32) {
    let lds = inM.min(inN);
    let ucol = match ch(&inJOBU) as u8 {
        b'A' => inM,
        b'S' => lds,
        _ => 0,
    };
    let mut a = mat_in(inLDA, inN, &inA);
    let mut s = vec![0.0f64; lds.max(0) as usize];
    // LAPACK requires a valid (non-null) `u` pointer with ldu >= 1 even when it
    // is not referenced (jobu = 'N'/'O'); allocate at least one element.
    let mut u = vec![0.0f64; ((inLDU.max(0) * ucol.max(0)) as usize).max(1)];
    let mut vt = vec![0.0f64; (inLDVT.max(0) * inN.max(0)) as usize];
    let mut work = vec_in(inLWORK, &inWORK);
    let (jobu, jobvt) = (ch(&inJOBU), ch(&inJOBVT));
    let mut info = 0;
    unsafe {
        dgesvd_(
            &jobu, &jobvt, &inM, &inN, a.as_mut_ptr(), &inLDA, s.as_mut_ptr(), u.as_mut_ptr(),
            &inLDU, vt.as_mut_ptr(), &inLDVT, work.as_mut_ptr(), &inLWORK, &mut info,
        );
    }
    let out_u = if ucol > 0 { mat_out(inLDU, ucol, &u) } else { nil() };
    (mat_out(inLDA, inN, &a), vec_out(lds, &s), out_u, mat_out(inLDVT, inN, &vt), vec_out(inLWORK, &work), info)
}

pub fn dgetrf(inM: i32, inN: i32, inA: Mat, inLDA: i32) -> (Mat, IVec, i32) {
    let ldipiv = inM.min(inN);
    let mut a = mat_in(inLDA, inN, &inA);
    let mut ipiv = vec![0i32; ldipiv.max(0) as usize];
    let mut info = 0;
    unsafe {
        dgetrf_(&inM, &inN, a.as_mut_ptr(), &inLDA, ipiv.as_mut_ptr(), &mut info);
    }
    (mat_out(inLDA, inN, &a), ivec_out(ldipiv, &ipiv), info)
}

pub fn dgetrs(
    inTRANS: ArcStr,
    inN: i32,
    inNRHS: i32,
    inA: Mat,
    inLDA: i32,
    inIPIV: IVec,
    inB: Mat,
    inLDB: i32,
) -> (Mat, i32) {
    let mut a = mat_in(inLDA, inN, &inA);
    let mut b = mat_in(inLDB, inNRHS, &inB);
    let mut ipiv = ivec_in(inN, &inIPIV);
    let trans = ch(&inTRANS);
    let mut info = 0;
    unsafe {
        dgetrs_(
            &trans, &inN, &inNRHS, a.as_mut_ptr(), &inLDA, ipiv.as_mut_ptr(), b.as_mut_ptr(),
            &inLDB, &mut info,
        );
    }
    (mat_out(inLDB, inNRHS, &b), info)
}

pub fn dgetri(inN: i32, inA: Mat, inLDA: i32, inIPIV: IVec, inWORK: Vec64, inLWORK: i32) -> (Mat, Vec64, i32) {
    let mut a = mat_in(inLDA, inN, &inA);
    let mut work = vec_in(inLWORK, &inWORK);
    let mut ipiv = ivec_in(inN, &inIPIV);
    let mut info = 0;
    unsafe {
        dgetri_(&inN, a.as_mut_ptr(), &inLDA, ipiv.as_mut_ptr(), work.as_mut_ptr(), &inLWORK, &mut info);
    }
    (mat_out(inLDA, inN, &a), vec_out(inLWORK, &work), info)
}

pub fn dgeqpf(
    inM: i32,
    inN: i32,
    inA: Mat,
    inLDA: i32,
    inJPVT: IVec,
    inWORK: Vec64,
) -> (Mat, IVec, Vec64, i32) {
    let ldtau = inM.min(inN);
    let lwork = 3 * inN;
    let mut a = mat_in(inLDA, inN, &inA);
    let mut jpvt = ivec_in(inN, &inJPVT);
    let mut tau = vec![0.0f64; ldtau.max(0) as usize];
    let mut work = vec_in(lwork, &inWORK);
    let mut info = 0;
    unsafe {
        dgeqpf_(
            &inM, &inN, a.as_mut_ptr(), &inLDA, jpvt.as_mut_ptr(), tau.as_mut_ptr(),
            work.as_mut_ptr(), &mut info,
        );
    }
    (mat_out(inLDA, inN, &a), ivec_out(inN, &jpvt), vec_out(ldtau, &tau), info)
}

pub fn dorgqr(
    inM: i32,
    inN: i32,
    inK: i32,
    inA: Mat,
    inLDA: i32,
    inTAU: Vec64,
    inWORK: Vec64,
    inLWORK: i32,
) -> (Mat, Vec64, i32) {
    let mut a = mat_in(inLDA, inN, &inA);
    let mut tau = vec_in(inK, &inTAU);
    let mut work = vec_in(inLWORK, &inWORK);
    let mut info = 0;
    unsafe {
        dorgqr_(
            &inM, &inN, &inK, a.as_mut_ptr(), &inLDA, tau.as_mut_ptr(), work.as_mut_ptr(),
            &inLWORK, &mut info,
        );
    }
    (mat_out(inLDA, inN, &a), vec_out(inLWORK, &work), info)
}

pub fn dhseqr(
    inJOB: ArcStr,
    inCOMPZ: ArcStr,
    inN: i32,
    inILO: i32,
    inIHI: i32,
    inH: Mat,
    inLDH: i32,
    inZ: Mat,
    inLDZ: i32,
    inWORK: Vec64,
    inLWORK: i32,
) -> (Mat, Vec64, Vec64, Mat, Vec64, i32) {
    let mut h = mat_in(inLDH, inN, &inH);
    let mut z = mat_in(inLDZ, inN, &inZ);
    let mut wr = vec![0.0f64; inN.max(0) as usize];
    let mut wi = vec![0.0f64; inN.max(0) as usize];
    let mut work = vec_in(inLWORK, &inWORK);
    let (job, compz) = (ch(&inJOB), ch(&inCOMPZ));
    let mut info = 0;
    unsafe {
        dhseqr_(
            &job, &compz, &inN, &inILO, &inIHI, h.as_mut_ptr(), &inLDH, wr.as_mut_ptr(),
            wi.as_mut_ptr(), z.as_mut_ptr(), &inLDZ, work.as_mut_ptr(), &inLWORK, &mut info,
        );
    }
    (
        mat_out(inLDH, inN, &h),
        vec_out(inN, &wr),
        vec_out(inN, &wi),
        mat_out(inLDZ, inN, &z),
        vec_out(inLWORK, &work),
        info,
    )
}
