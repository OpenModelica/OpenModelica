//! The external-"C" wasm artifacts `openmodelica_codegen_wasm_jit`'s FMU linker
//! links into a host-free wasm FMU (built by `build.rs`). Each is an empty slice
//! when its toolchain was unavailable at build time.

/// ModelicaExternalC as a PIC dylink side module.
pub static EXTERNAL_C_DYLINK: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/modelicaexternalc_dylink.wasm"));

/// A `-fPIC` wasi-libc `libc.so` dylink module (Debian's is non-PIC).
pub static LIBC_PIC: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/libc_pic.wasm"));

/// The `wasi_snapshot_preview1` → preview2 reactor adapter.
pub static WASI_P1_ADAPTER: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/wasi_snapshot_preview1.reactor.wasm"));

/// Whether external "C" in a host-free wasm FMU is supported (all three present).
pub fn available() -> bool {
    !EXTERNAL_C_DYLINK.is_empty() && !LIBC_PIC.is_empty() && !WASI_P1_ADAPTER.is_empty()
}
