// Link the system LAPACK (and its BLAS backend) so the FFI declarations in
// `src/Lapack.rs` resolve. The reference `liblapack.so` provides the
// `d*_` Fortran-ABI routines; `libblas` satisfies its transitive symbols.
fn main() {
    // The wasm target has no native LAPACK/BLAS to link and no C toolchain to
    // compile the shim; both the FFI (`src/Lapack.rs`) and the C error shim
    // (`dynload`) are `cfg`'d out for wasm, so this build script is a no-op there.
    if std::env::var("CARGO_CFG_TARGET_ARCH").as_deref() == Ok("wasm32") {
        return;
    }

    println!("cargo:rustc-link-lib=dylib=lapack");
    println!("cargo:rustc-link-lib=dylib=blas");

    // Runtime error interception shim for evaluated external C functions
    // (see src/runtime_error_shim.c and the rebinding in dynload::ensure_runtime).
    // The `va_list` formatting it performs cannot be written in stable Rust.
    println!("cargo:rerun-if-changed=src/runtime_error_shim.c");
    cc::Build::new()
        .file("src/runtime_error_shim.c")
        .compile("omrs_runtime_error_shim");
}
