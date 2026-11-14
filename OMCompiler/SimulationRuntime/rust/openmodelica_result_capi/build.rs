// ld64 defaults a dylib's install name to its output path in the cargo target
// directory, which omc and the GUI clients would then load it from.
fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    if matches!(std::env::var("CARGO_CFG_TARGET_OS").as_deref(), Ok("macos" | "ios")) {
        println!("cargo:rustc-cdylib-link-arg=-Wl,-install_name,@rpath/libomc_result.dylib");
    }
}
