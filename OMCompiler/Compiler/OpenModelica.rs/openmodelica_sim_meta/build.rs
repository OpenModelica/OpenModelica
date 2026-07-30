//! Decides whether the driver gets the real CVODE (`cfg(sundials)`).
//!
//! Two sources, both prepared by `.cmake/rust_omc.cmake`:
//!   * wasip1 — `OMC_SUNDIALS_WASM_DIR`. The archives are linked by the runtime
//!     crate's build script (it owns the link order for the whole set), so here
//!     the variable only selects the cfg.
//!   * host — `OMC_SUNDIALS_NATIVE_DIR`, linked here: the host-driven driver
//!     lives in `libOpenModelicaCompiler`, which nothing else links SUNDIALS into.
//!     This is the C runtime's own archive, so its index size is whatever that
//!     build chose (64) rather than the wasm archives' 32 — hence `sundials_i64`.
//!
//! Unset means no CVODE; `simflags::check` then rejects `-s=cvode` up front.

use std::path::Path;

fn main() {
    println!("cargo::rustc-check-cfg=cfg(sundials)");
    println!("cargo::rustc-check-cfg=cfg(sundials_i64)");
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_WASM_DIR");
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_NATIVE_DIR");
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_NATIVE_INDEX_SIZE");

    let arch = std::env::var("CARGO_CFG_TARGET_ARCH").unwrap_or_default();
    let os = std::env::var("CARGO_CFG_TARGET_OS").unwrap_or_default();
    if arch == "wasm32" {
        // wasm32-unknown-unknown is the no_std function-JIT runtime: no libc for
        // SUNDIALS to call.
        if os == "wasi" && std::env::var_os("OMC_SUNDIALS_WASM_DIR").is_some() {
            println!("cargo:rustc-cfg=sundials");
        }
        return;
    }
    let Some(dir) = std::env::var_os("OMC_SUNDIALS_NATIVE_DIR") else { return };
    let lib = Path::new(&dir).join("lib");
    if !["libsundials_cvode.a", "sundials_cvode.lib"].iter().any(|n| lib.join(n).exists()) {
        panic!("OMC_SUNDIALS_NATIVE_DIR={} has no sundials_cvode archive; the host \
                SUNDIALS build failed (check the rust_sundials_native CMake target)", lib.display());
    }
    println!("cargo:rustc-link-search=native={}", lib.display());
    println!("cargo:rustc-link-lib=static=sundials_cvode");
    println!("cargo:rustc-cfg=sundials");
    match std::env::var("OMC_SUNDIALS_NATIVE_INDEX_SIZE").as_deref() {
        Ok("64") => println!("cargo:rustc-cfg=sundials_i64"),
        Ok("32") => {}
        other => panic!("OMC_SUNDIALS_NATIVE_INDEX_SIZE must be 32 or 64, got {other:?}"),
    }
}
