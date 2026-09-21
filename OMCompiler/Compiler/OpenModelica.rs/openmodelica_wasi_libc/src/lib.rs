//! The external-"C" wasm artifacts `openmodelica_codegen_wasm_jit`'s FMU linker
//! links into a host-free wasm FMU. The work is all in `build.rs`: it leaves the
//! artifacts in `OUT_DIR`, and `openmodelica_wasm_jit::blobs` -- which reaches
//! that directory through this crate's `links` metadata -- is what reads them.
