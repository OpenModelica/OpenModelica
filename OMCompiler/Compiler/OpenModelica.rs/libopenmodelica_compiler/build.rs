// A Mach-O library records the path its dependents load it from (its install
// name), and ld64 defaults that to the output path — here the cargo target
// directory of whoever built it. `@rpath` defers the lookup to the loading
// binary's rpath list instead, which the omc launcher (openmodelica/build.rs)
// and the CMake install rules point at the install layout.
fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("macos") {
        println!(
            "cargo:rustc-cdylib-link-arg=-Wl,-install_name,@rpath/libOpenModelicaCompiler.dylib"
        );
    }
}
