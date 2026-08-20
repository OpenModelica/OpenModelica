//! The external-"C" wasm artifacts `openmodelica_codegen_wasm_jit`'s FMU linker
//! links into a host-free wasm FMU (built by `build.rs`). Each is an empty slice
//! when its toolchain was unavailable at build time.

/// ModelicaExternalC as a PIC dylink side module.
pub static EXTERNAL_C_DYLINK: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/modelicaexternalc_dylink.wasm"));

/// The dummy `usertab` ModelicaExternalC imports, separate so it can be linked last.
pub static USERTAB_DYLINK: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/usertab_dylink.wasm"));

/// A `-fPIC` wasi-libc `libc.so` dylink module (Debian's is non-PIC).
pub static LIBC_PIC: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/libc_pic.wasm"));

/// The `wasi_snapshot_preview1` → preview2 reactor adapter.
pub static WASI_P1_ADAPTER: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/wasi_snapshot_preview1.reactor.wasm"));

/// SUNDIALS (CVODE + IDAS) and KLU as a PIC dylink side module, linked into an FMU
/// only when its Co-Simulation driver needs them. Empty when this omc was built
/// without a sundials source tree.
pub static SUNDIALS_DYLINK: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/sundials_dylink.wasm"));

/// Whether a wasm FMU can be given CVODE/IDA (the module above was built).
pub fn sundials_available() -> bool {
    !SUNDIALS_DYLINK.is_empty()
}

/// Whether external "C" in a host-free wasm FMU is supported (all three present).
pub fn available() -> bool {
    !EXTERNAL_C_DYLINK.is_empty() && !LIBC_PIC.is_empty() && !WASI_P1_ADAPTER.is_empty()
}
