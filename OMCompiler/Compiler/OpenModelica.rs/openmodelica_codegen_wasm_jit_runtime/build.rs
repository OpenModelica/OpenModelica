//! Links the wasm SUNDIALS/KLU archives into the wasip1 runtimes when
//! `OMC_SUNDIALS_WASM_DIR` is set by the parent build script
//! (`openmodelica_codegen_wasm_jit`'s build.rs, forwarded from CMake's
//! `rust_sundials_wasm` target). Sets `cfg(sundials)` so `src/sundials.rs`
//! and its callers compile in.
//!
//! When `OMC_SUNDIALS_WASM_DIR` is not set, sundials is simply not linked
//! (the pure-Rust fallback is used). When it is set, missing archives are a
//! hard error — the parent build script only sets it when the archives exist.

use std::path::Path;

/// Archives in link order: each entry may only depend on later ones. `wasm-ld`
/// resolves archives in the order given, so a wrong order is an undefined symbol.
const LIBS: &[&str] = &[
    "sundials_kinsol",
    // IDAS, not IDA: same entry points plus the forward-sensitivity ones, as the
    // C runtime links it.
    "sundials_idas",
    "sundials_cvode",
    "sundials_sunlinsolklu",
    "sundials_sunlinsoldense",
    "sundials_sunmatrixsparse",
    "sundials_sunmatrixdense",
    "sundials_nvecserial",
    "klu",
    "amd",
    "colamd",
    "btf",
    "suitesparseconfig",
];

fn main() {
    println!("cargo::rustc-check-cfg=cfg(sundials)");
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_WASM_DIR");

    // wasip1 only: the no_std JIT runtime (wasm32-unknown-unknown) has no libc for
    // SUNDIALS to call, and the host `cargo test` build links nothing.
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("wasi") {
        return;
    }
    let Ok(dir) = std::env::var("OMC_SUNDIALS_WASM_DIR") else { return };
    let lib = Path::new(&dir).join("lib");
    let missing: Vec<_> = LIBS.iter()
        .filter(|l| !lib.join(format!("lib{l}.a")).exists())
        .collect();
    if !missing.is_empty() {
        panic!("OMC_SUNDIALS_WASM_DIR={} is missing {missing:?}; the sundials wasm \
                cross-compile failed (check the rust_sundials_wasm CMake target)", lib.display());
    }
    println!("cargo:rustc-link-search=native={}", lib.display());
    for l in LIBS {
        println!("cargo:rustc-link-lib=static={l}");
    }
    println!("cargo:rustc-cfg=sundials");
}
