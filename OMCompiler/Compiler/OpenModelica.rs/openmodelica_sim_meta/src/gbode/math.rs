//! Short names for the libm calls gbode needs; the crate is `no_std` in the
//! in-wasm build, where the inherent float methods are not all available.

pub use libm::{fabs as abs, log as ln, pow, sqrt};
