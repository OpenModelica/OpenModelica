//! The libm calls the solvers make, as C makes them: the platform libm under
//! `std` (glibc beside the C runtime it is compared against), the `libm` crate
//! where there is none (`no_std`).

#[cfg(feature = "std")]
mod imp {
    #[inline]
    pub fn fabs(x: f64) -> f64 {
        x.abs()
    }
    #[inline]
    pub fn sqrt(x: f64) -> f64 {
        x.sqrt()
    }
    #[inline]
    pub fn pow(x: f64, y: f64) -> f64 {
        x.powf(y)
    }
    #[inline]
    pub fn exp(x: f64) -> f64 {
        x.exp()
    }
    #[inline]
    pub fn log(x: f64) -> f64 {
        x.ln()
    }
    #[inline]
    pub fn log10(x: f64) -> f64 {
        x.log10()
    }
    #[inline]
    pub fn floor(x: f64) -> f64 {
        x.floor()
    }
    #[inline]
    pub fn ceil(x: f64) -> f64 {
        x.ceil()
    }
    #[inline]
    pub fn round(x: f64) -> f64 {
        x.round()
    }
    #[inline]
    pub fn trunc(x: f64) -> f64 {
        x.trunc()
    }
    #[inline]
    pub fn fmax(x: f64, y: f64) -> f64 {
        x.max(y)
    }
    #[inline]
    pub fn fmin(x: f64, y: f64) -> f64 {
        x.min(y)
    }
}

#[cfg(not(feature = "std"))]
mod imp {
    pub use libm::{ceil, exp, fabs, floor, fmax, fmin, log, log10, pow, round, sqrt, trunc};
}

pub use imp::*;
