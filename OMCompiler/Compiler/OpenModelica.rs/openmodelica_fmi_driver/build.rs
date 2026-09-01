//! Decides whether the Model Exchange master gets CVODE and IDA
//! (`cfg(sundials)`), which is what `Solver::all` offers them on.
//!
//! The same two variables `openmodelica_solvers` reads, both prepared by
//! `.cmake/rust_omc.cmake`. That crate owns the bindings and links the archives;
//! here they only select the cfg, so the two stay in step.

fn main() {
    println!("cargo::rustc-check-cfg=cfg(sundials)");
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_WASM_DIR");
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_NATIVE_DIR");
    let os = std::env::var("CARGO_CFG_TARGET_OS").unwrap_or_default();
    let have = match std::env::var("CARGO_CFG_TARGET_ARCH").as_deref() {
        // wasm32-unknown-unknown has no libc for SUNDIALS to call.
        Ok("wasm32") => os == "wasi" && std::env::var_os("OMC_SUNDIALS_WASM_DIR").is_some(),
        _ => std::env::var_os("OMC_SUNDIALS_NATIVE_DIR").is_some(),
    };
    if have {
        println!("cargo:rustc-cfg=sundials");
    }
}
