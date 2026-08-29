//! Decides whether the nonlinear ladder gets the real KINSOL (`cfg(sundials)`).
//!
//! Same two sources as `openmodelica_sim_meta`'s script, and for the same reason:
//! `openmodelica_solvers` owns the link order for the whole archive set, so here
//! the variables only select the cfg.

fn main() {
    println!("cargo::rustc-check-cfg=cfg(sundials)");
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_WASM_DIR");
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_NATIVE_DIR");
    if std::env::var_os("CARGO_FEATURE_SUNDIALS_EXTERN").is_some() {
        println!("cargo:rustc-cfg=sundials");
        return;
    }
    let arch = std::env::var("CARGO_CFG_TARGET_ARCH").unwrap_or_default();
    let os = std::env::var("CARGO_CFG_TARGET_OS").unwrap_or_default();
    if arch == "wasm32" {
        if os == "wasi" && std::env::var_os("OMC_SUNDIALS_WASM_DIR").is_some() {
            println!("cargo:rustc-cfg=sundials");
        }
        return;
    }
    // Deliberately not a second existence check: `openmodelica_solvers` panics if
    // any archive in the set (KINSOL included) is missing, so the directory being
    // set is the whole answer. Checking here would cache a "no" from a build that
    // ran before the archives were collected, and cargo re-runs a build script on a
    // changed environment, not on a file that appeared.
    if std::env::var_os("OMC_SUNDIALS_NATIVE_DIR").is_some() {
        println!("cargo:rustc-cfg=sundials");
    }
}
