//! This build's revision, the analogue of the C build's `CONFIG_REVISION`
//! (revision.h).
//!
//! It is not compiled in next to `Settings::getVersionNr`, whose crate
//! (`openmodelica_util`) every other one depends on: a revision there rebuilds
//! the whole compiler on every commit. Each host — the omc/OMEdit cdylib, the
//! OMShell backend — pushes [`REVISION`] in at startup with
//! `openmodelica_backend_main::capi::set_version` instead.

/// E.g. `v1.28.0-dev-258-g17570b42c7-rust`, or `"unknown"` when neither cmake
/// nor git could supply one. See build.rs.
pub const REVISION: &str = env!("OMC_REVISION");
