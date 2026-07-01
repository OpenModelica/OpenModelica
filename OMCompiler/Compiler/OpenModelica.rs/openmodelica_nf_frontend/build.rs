// Compiles the C++ exception barrier used by FFI.callFunction — see the
// comments in src/ffi_catch.cpp and src/FFI.rs.
fn main() {
    // libffi (and this C++ exception barrier around it) drive FFI.callFunction,
    // which is native-only; on wasm FFI is a stub, so skip the C++ build.
    if std::env::var("CARGO_CFG_TARGET_ARCH").as_deref() == Ok("wasm32") {
        return;
    }
    println!("cargo:rerun-if-changed=src/ffi_catch.cpp");
    cc::Build::new()
        .cpp(true)
        .file("src/ffi_catch.cpp")
        .compile("omrs_ffi_catch");
}
