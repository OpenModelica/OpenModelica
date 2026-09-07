//! HDF5 as an install tree rather than a Rust API: the consumer is
//! `ModelicaMatIO.c` built with `HAVE_HDF5`, which calls the C entry points.
//! Empty without the `library` feature.

/// The HDF5 install tree `build.rs` published: `include/` and `lib/libhdf5.a`.
#[cfg(feature = "library")]
pub fn root() -> &'static str {
    env!("OMC_HDF5_ROOT")
}
