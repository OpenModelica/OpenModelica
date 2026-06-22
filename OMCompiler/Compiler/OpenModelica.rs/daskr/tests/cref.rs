//! Bit-exact cross-validation of the Rust port against the original Cdaskr C.
//!
//! Enabled only with `--features cref` (the C reference is built by build.rs):
//!
//! ```text
//! cargo test -p daskr --features cref
//! ```
#![cfg(feature = "cref")]

use daskr::linpack;

// --- reference C entry points (Fortran calling convention: all by pointer) ---
#[allow(non_snake_case)]
unsafe extern "C" {
    fn _daskr_idamax_(n: *const i32, dx: *const f64, incx: *const i32) -> i32;
    fn _daskr_ddot_(
        n: *const i32,
        dx: *const f64,
        incx: *const i32,
        dy: *const f64,
        incy: *const i32,
    ) -> f64;
    fn _daskr_dnrm2_(n: *const i32, dx: *const f64, incx: *const i32) -> f64;
    fn _daskr_dscal_(n: *const i32, da: *const f64, dx: *mut f64, incx: *const i32) -> i32;
    fn _daskr_dcopy_(
        n: *const i32,
        sx: *const f64,
        incx: *const i32,
        sy: *mut f64,
        incy: *const i32,
    ) -> i32;
    fn _daskr_daxpy_(
        n: *const i32,
        da: *const f64,
        dx: *const f64,
        incx: *const i32,
        dy: *mut f64,
        incy: *const i32,
    ) -> i32;
    fn _daskr_dgefa_(
        a: *mut f64,
        lda: *const i32,
        n: *const i32,
        ipvt: *mut i32,
        info: *mut i32,
    ) -> i32;
    fn _daskr_dgesl_(
        a: *const f64,
        lda: *const i32,
        n: *const i32,
        ipvt: *const i32,
        b: *mut f64,
        job: *const i32,
    ) -> i32;
    fn _daskr_dgbfa_(
        abd: *mut f64,
        lda: *const i32,
        n: *const i32,
        ml: *const i32,
        mu: *const i32,
        ipvt: *mut i32,
        info: *mut i32,
    ) -> i32;
    fn _daskr_dgbsl_(
        abd: *const f64,
        lda: *const i32,
        n: *const i32,
        ml: *const i32,
        mu: *const i32,
        ipvt: *const i32,
        b: *mut f64,
        job: *const i32,
    ) -> i32;
    fn _daskr_d1mach_(idummy: *const i32) -> f64;
}

/// Tiny SplitMix64-based PRNG so the tests are deterministic and dependency-free.
struct Rng(u64);
impl Rng {
    fn new(seed: u64) -> Self {
        Rng(seed)
    }
    fn next_u64(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E37_79B9_7F4A_7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
        z ^ (z >> 31)
    }
    /// Uniform in [-1, 1).
    fn f(&mut self) -> f64 {
        (self.next_u64() >> 11) as f64 / (1u64 << 53) as f64 * 2.0 - 1.0
    }
    fn vec(&mut self, n: usize) -> Vec<f64> {
        (0..n).map(|_| self.f()).collect()
    }
}

fn bits_eq(a: &[f64], b: &[f64]) -> bool {
    a.len() == b.len() && a.iter().zip(b).all(|(x, y)| x.to_bits() == y.to_bits())
}

#[test]
fn d1mach_matches() {
    let c = unsafe { _daskr_d1mach_(&1) };
    assert_eq!(daskr::aux::d1mach().to_bits(), c.to_bits());
}

#[test]
fn idamax_matches() {
    let mut rng = Rng::new(1);
    // idamax (like dnrm2) is only defined for incx >= 1.
    for &n in &[0i32, 1, 2, 5, 17, 64] {
        for &incx in &[1i32, 2, 3] {
            let len = (n.max(1) * incx.abs()) as usize;
            let dx = rng.vec(len.max(1));
            let r = linpack::idamax(n, &dx, incx);
            let c = unsafe { _daskr_idamax_(&n, dx.as_ptr(), &incx) };
            assert_eq!(r, c, "idamax n={n} incx={incx}");
        }
    }
}

#[test]
fn ddot_matches() {
    let mut rng = Rng::new(2);
    for &n in &[0i32, 1, 3, 5, 7, 23, 100] {
        for &(incx, incy) in &[(1i32, 1i32), (2, 1), (1, 3), (2, 3), (-1, 1), (-2, -3)] {
            let lenx = (n.max(1) * incx.abs()).max(1) as usize;
            let leny = (n.max(1) * incy.abs()).max(1) as usize;
            let dx = rng.vec(lenx);
            let dy = rng.vec(leny);
            let r = linpack::ddot(n, &dx, incx, &dy, incy);
            let c = unsafe { _daskr_ddot_(&n, dx.as_ptr(), &incx, dy.as_ptr(), &incy) };
            assert_eq!(r.to_bits(), c.to_bits(), "ddot n={n} incx={incx} incy={incy}");
        }
    }
}

#[test]
fn dnrm2_matches() {
    let mut rng = Rng::new(3);
    for &n in &[0i32, 1, 2, 5, 17, 64] {
        for &incx in &[1i32, 2, 3] {
            let len = (n.max(1) * incx.abs()).max(1) as usize;
            let mut dx = rng.vec(len);
            // exercise tiny/huge components (the scaled phases) too
            if n >= 3 {
                dx[0] = 1e-180;
                dx[incx.unsigned_abs() as usize] = 1e180;
            }
            let r = linpack::dnrm2(n, &dx, incx);
            let c = unsafe { _daskr_dnrm2_(&n, dx.as_ptr(), &incx) };
            assert_eq!(r.to_bits(), c.to_bits(), "dnrm2 n={n} incx={incx}");
        }
    }
}

#[test]
fn dscal_matches() {
    let mut rng = Rng::new(4);
    for &n in &[0i32, 1, 4, 5, 11, 50] {
        for &incx in &[1i32, 2, 3] {
            let len = (n.max(1) * incx.abs()).max(1) as usize;
            let base = rng.vec(len);
            let da = rng.f();
            let mut r = base.clone();
            let mut c = base.clone();
            linpack::dscal(n, da, &mut r, incx);
            unsafe { _daskr_dscal_(&n, &da, c.as_mut_ptr(), &incx) };
            assert!(bits_eq(&r, &c), "dscal n={n} incx={incx}");
        }
    }
}

#[test]
fn dcopy_matches() {
    let mut rng = Rng::new(5);
    for &n in &[0i32, 1, 7, 8, 15, 30] {
        for &(incx, incy) in &[(1i32, 1i32), (2, 1), (1, 3), (-1, 1), (-2, -3)] {
            let lenx = (n.max(1) * incx.abs()).max(1) as usize;
            let leny = (n.max(1) * incy.abs()).max(1) as usize;
            let sx = rng.vec(lenx);
            let base = rng.vec(leny);
            let mut r = base.clone();
            let mut c = base.clone();
            linpack::dcopy(n, &sx, incx, &mut r, incy);
            unsafe { _daskr_dcopy_(&n, sx.as_ptr(), &incx, c.as_mut_ptr(), &incy) };
            assert!(bits_eq(&r, &c), "dcopy n={n} incx={incx} incy={incy}");
        }
    }
}

#[test]
fn daxpy_matches() {
    let mut rng = Rng::new(6);
    for &n in &[0i32, 1, 4, 5, 9, 40] {
        for &(incx, incy) in &[(1i32, 1i32), (2, 1), (1, 3), (-1, 1), (-2, -3)] {
            let lenx = (n.max(1) * incx.abs()).max(1) as usize;
            let leny = (n.max(1) * incy.abs()).max(1) as usize;
            let dx = rng.vec(lenx);
            let base = rng.vec(leny);
            let da = rng.f();
            let mut r = base.clone();
            let mut c = base.clone();
            linpack::daxpy(n, da, &dx, incx, &mut r, incy);
            unsafe { _daskr_daxpy_(&n, &da, dx.as_ptr(), &incx, c.as_mut_ptr(), &incy) };
            assert!(bits_eq(&r, &c), "daxpy n={n} incx={incx} incy={incy}");
        }
    }
}

#[test]
fn dgefa_dgesl_matches() {
    let mut rng = Rng::new(7);
    for &n in &[1i32, 2, 3, 5, 10, 25] {
        let lda = n;
        let a0 = rng.vec((lda * n) as usize);
        let b0 = rng.vec(n as usize);

        for &job in &[0i32, 1] {
            let (mut ar, mut ac) = (a0.clone(), a0.clone());
            let (mut ir, mut ic) = (vec![0i32; n as usize], vec![0i32; n as usize]);
            let (mut infor, mut infoc) = (0i32, 0i32);
            linpack::dgefa(&mut ar, lda, n, &mut ir, &mut infor);
            unsafe { _daskr_dgefa_(ac.as_mut_ptr(), &lda, &n, ic.as_mut_ptr(), &mut infoc) };
            assert!(bits_eq(&ar, &ac), "dgefa factors n={n}");
            assert_eq!(ir, ic, "dgefa ipvt n={n}");
            assert_eq!(infor, infoc, "dgefa info n={n}");

            let (mut br, mut bc) = (b0.clone(), b0.clone());
            linpack::dgesl(&ar, lda, n, &ir, &mut br, job);
            unsafe { _daskr_dgesl_(ac.as_ptr(), &lda, &n, ic.as_ptr(), bc.as_mut_ptr(), &job) };
            assert!(bits_eq(&br, &bc), "dgesl solution n={n} job={job}");
        }
    }
}

#[test]
fn dgbfa_dgbsl_matches() {
    let mut rng = Rng::new(8);
    for &(n, ml, mu) in &[(5i32, 1i32, 1i32), (8, 2, 1), (10, 3, 2), (12, 0, 2), (15, 2, 0)] {
        let lda = 2 * ml + mu + 1;
        let a0 = rng.vec((lda * n) as usize);
        let b0 = rng.vec(n as usize);

        for &job in &[0i32, 1] {
            let (mut ar, mut ac) = (a0.clone(), a0.clone());
            let (mut ir, mut ic) = (vec![0i32; n as usize], vec![0i32; n as usize]);
            let (mut infor, mut infoc) = (0i32, 0i32);
            linpack::dgbfa(&mut ar, lda, n, ml, mu, &mut ir, &mut infor);
            unsafe {
                _daskr_dgbfa_(ac.as_mut_ptr(), &lda, &n, &ml, &mu, ic.as_mut_ptr(), &mut infoc)
            };
            assert!(bits_eq(&ar, &ac), "dgbfa factors n={n} ml={ml} mu={mu}");
            assert_eq!(ir, ic, "dgbfa ipvt n={n} ml={ml} mu={mu}");
            assert_eq!(infor, infoc, "dgbfa info n={n} ml={ml} mu={mu}");

            let (mut br, mut bc) = (b0.clone(), b0.clone());
            linpack::dgbsl(&ar, lda, n, ml, mu, &ir, &mut br, job);
            unsafe {
                _daskr_dgbsl_(ac.as_ptr(), &lda, &n, &ml, &mu, ic.as_ptr(), bc.as_mut_ptr(), &job)
            };
            assert!(bits_eq(&br, &bc), "dgbsl solution n={n} ml={ml} mu={mu} job={job}");
        }
    }
}
