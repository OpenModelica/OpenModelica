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
    cc::Build::new()
        .file("src/runtime_error_shim.c")
        .compile("omrs_runtime_error_shim");
}
