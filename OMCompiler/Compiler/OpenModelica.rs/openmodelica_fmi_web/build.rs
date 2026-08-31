//! Links the wasm SUNDIALS/KLU archives into this module, which is what gives
//! the Model Exchange master `-s=cvode` and `-s=ida` in the browser.
//!
//! `openmodelica_solvers` owns the bindings but links nothing on wasm: the
//! archives belong to whoever produces the final module, and for this page that
//! is here. Without `OMC_SUNDIALS_WASM_DIR` the page is offered the solvers that
//! need no SUNDIALS.

use std::path::Path;

/// Archives in link order: each entry may only depend on later ones. SUNDIALS
/// ships one archive per module, so each has to be listed; the KLU set comes
/// along because the bindings name `SUNLinSol_KLU`.
const LIBS: &[&str] = &[
    // IDAS, not IDA: same entry points plus the forward-sensitivity ones, as the
    // C runtime links it.
    "sundials_idas",
    "sundials_cvode",
    "sundials_sunlinsolklu",
    "sundials_sunlinsoldense",
    "sundials_sunmatrixsparse",
    "sundials_sunmatrixdense",
    "sundials_nvecserial",
    "sundials_core",
    "klu",
    "amd",
    "colamd",
    "btf",
    "suitesparseconfig",
];

fn main() {
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_WASM_DIR");
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("wasi") {
        return;
    }
    let Some(dir) = std::env::var_os("OMC_SUNDIALS_WASM_DIR") else { return };
    let lib = Path::new(&dir).join("lib");
    let missing: Vec<_> = LIBS.iter().filter(|l| !lib.join(format!("lib{l}.a")).exists()).collect();
    if !missing.is_empty() {
        panic!(
            "OMC_SUNDIALS_WASM_DIR={} is missing {missing:?}; the sundials wasm \
             cross-compile failed (check the rust_sundials_wasm CMake target)",
            lib.display()
        );
    }
    println!("cargo:rustc-link-search=native={}", lib.display());
    for l in LIBS {
        println!("cargo:rustc-link-lib=static={l}");
        // Cargo tracks this crate's sources, not what `wasm-ld` takes from the
        // archives; without this a rebuilt archive is silently not linked.
        println!("cargo:rerun-if-changed={}", lib.join(format!("lib{l}.a")).display());
    }
}
