// The LAPACK the FFI declarations in `src/Lapack.rs` resolve against is
// `openmodelica_lapack`, an ordinary Rust dependency, so nothing is linked here
// for it any more — see that file's `extern crate`.
fn main() {
    // The wasm target has no C toolchain to compile the shim below with, and the
    // `dynload` that uses it is `cfg`'d out there, so this build script is a
    // no-op.
    if std::env::var("CARGO_CFG_TARGET_ARCH").as_deref() == Ok("wasm32") {
        return;
    }

    // Runtime error interception shim for evaluated external C functions
    // (see src/runtime_error_shim.c and the rebinding in dynload::ensure_runtime).
    // The `va_list` formatting it performs cannot be written in stable Rust.
    println!("cargo:rerun-if-changed=src/runtime_error_shim.c");
    let mut build = cc::Build::new();
    build.file("src/runtime_error_shim.c");

    // System.gccVersion: omc_config.h's `__VERSION__` for MinGW builds.
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("windows")
        && std::env::var("CARGO_CFG_TARGET_ENV").as_deref() == Ok("gnu")
    {
        let cc = build.get_compiler();
        let version = ["-dumpfullversion", "-dumpversion"].iter().find_map(|flag| {
            let out = cc.to_command().arg(flag).output().ok()?;
            let v = String::from_utf8(out.stdout).ok()?.trim().to_string();
            (out.status.success() && !v.is_empty()).then_some(v)
        });
        println!("cargo:rustc-env=OMC_GCC_VERSION={}", version.unwrap_or_default());
    }

    build.compile("omrs_runtime_error_shim");
}
