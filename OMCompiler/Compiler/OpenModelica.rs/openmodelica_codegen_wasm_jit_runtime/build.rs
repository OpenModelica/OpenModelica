//! Links the wasm SUNDIALS/KLU archives into the wasip1 runtimes when
//! `openmodelica_codegen_wasm_jit`'s build script has cross-compiled them
//! (`OMC_SUNDIALS_WASM_DIR`), and sets `cfg(sundials)` so `src/sundials.rs` and its
//! callers compile in. Absent archives are not an error: the runtime then keeps
//! using its pure-Rust solvers, and a raw `cargo build` of this crate still works.

use std::path::Path;

/// Archives in link order: each entry may only depend on later ones. `wasm-ld`
/// resolves archives in the order given, so a wrong order is an undefined symbol.
const LIBS: &[&str] = &[
    "sundials_kinsol",
    "sundials_ida",
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
        println!("cargo:warning=OMC_SUNDIALS_WASM_DIR={} is missing {missing:?}; building \
                  without SUNDIALS", lib.display());
        return;
    }
    println!("cargo:rustc-link-search=native={}", lib.display());
    for l in LIBS {
        println!("cargo:rustc-link-lib=static={l}");
    }
    println!("cargo:rustc-cfg=sundials");
}
