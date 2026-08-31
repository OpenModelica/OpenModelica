// Mirror the reference omc binary's RUNPATH (`$ORIGIN/../lib/<triple>/omc:$ORIGIN`).
//
// External-function shared objects (e.g. ffi/libModelicaExternalC.so) have a
// DT_NEEDED on `libOpenModelicaRuntimeC.so`, which the reference resolves
// because omc links that library and ld.so finds it through this RUNPATH at
// process start, registering it under its basename. The Rust port doesn't
// link the C runtime; instead `openmodelica_util::dynload` dlopen()s it by
// basename before loading user libraries — and that basename lookup resolves
// through this same RUNPATH when the binary is installed as `<prefix>/bin/omc`.
//
// Windows note: DLL dependencies resolve via the executable's directory and
// PATH, so no equivalent is needed (and rpath args would not be accepted).
fn main() {
    let target_os = std::env::var("CARGO_CFG_TARGET_OS").unwrap_or_default();
    let target_arch = std::env::var("CARGO_CFG_TARGET_ARCH").unwrap_or_default();

    // The cdylib (libopenmodelica_compiler) is built first by the cmake
    // `rust_libopenmodelica` target, ordered before this binary, into the cargo
    // profile directory. Derive that directory from OUT_DIR
    // (`<target>/<profile>/build/openmodelica-<hash>/out`) — three parents up —
    // so it is correct with or without a `--target <triple>` subdir.
    let out_dir = std::env::var("OUT_DIR").expect("OUT_DIR set by cargo");
    let dir = std::path::Path::new(&out_dir)
        .ancestors()
        .nth(3)
        .expect("OUT_DIR has the <target>/<profile>/build/<pkg>/out layout")
        .display()
        .to_string();

    // Windows: link the cdylib's import library directly by path. rustc emits it
    // as `OpenModelicaCompiler.dll.lib` next to the DLL; passing the full path as
    // a link arg sidesteps the default `-l` search for `OpenModelicaCompiler.lib`.
    // DLL dependencies resolve via the executable's directory and PATH at run
    // time, so no rpath equivalent is needed.
    if target_os == "windows" {
        println!("cargo:rustc-link-arg-bins={dir}/OpenModelicaCompiler.dll.lib");
        println!("cargo:rerun-if-changed={dir}/OpenModelicaCompiler.dll.lib");
        return;
    }

    let triple = match target_os.as_str() {
        // Same per-OS layout as `Autoconf::triple` in openmodelica_util.
        "linux" => format!("{target_arch}-linux-gnu"),
        "macos" => format!("{target_arch}-apple-darwin"),
        _ => return,
    };
    // Thin-launcher linkage. This binary contains no compiler code; it calls
    // `omc_cli_run` in libOpenModelicaCompiler.so.
    //
    // Runtime rpath search order matters because more than one copy of the .so
    // can exist. The INSTALL layout comes first (relocatable, `$ORIGIN/../lib/
    // <triple>/omc` — where the cmake install puts the .so next to the simulation
    // runtime; matches CMAKE_INSTALL_RPATH), so an installed omc loads the
    // installed cdylib. In a dev/build tree that path does not exist, so ld.so
    // falls through to the absolute profile dir (the just-built copy), and
    // finally $ORIGIN.
    println!("cargo:rustc-link-arg-bins=-Wl,-rpath,$ORIGIN/../lib/{triple}/omc");
    println!("cargo:rustc-link-arg-bins=-Wl,-rpath,{dir}");
    // Link `-lOpenModelicaCompiler` as a *trailing* link-arg rather than a
    // plain `cargo:rustc-link-lib`: rustc emits build-script link libs ahead
    // of the crate's own object files, where the global `-Wl,--as-needed`
    // (set by the workspace) drops the DT_NEEDED because `omc_cli_run` is not
    // yet an unresolved reference at that point. Placed after the objects
    // (link-args go last), the reference is live and the .so is retained.
    println!("cargo:rustc-link-arg-bins=-L{dir}");
    println!("cargo:rustc-link-arg-bins=-lOpenModelicaCompiler");
    println!("cargo:rerun-if-changed={dir}/libOpenModelicaCompiler.so");
    println!("cargo:rustc-link-arg-bins=-Wl,-rpath,$ORIGIN");
    // libomcruntime.so (dlopened by the `-d=gen` pipeline) resolves the
    // compiler callback `omc_Error_getCurrentComponent`. In the static build it
    // came from the binary's own Error module (DynLoadExt.rs); now that the
    // compiler lives in libOpenModelicaCompiler.so, the .so exports it and ld.so
    // resolves it from there (the .so is a DT_NEEDED, so its dynamic symbols are
    // in the global scope for later dlopen()s). The `-u`/--export-dynamic-symbol
    // are kept as a harmless safety net.
    println!("cargo:rustc-link-arg-bins=-Wl,-u,omc_Error_getCurrentComponent");
    println!("cargo:rustc-link-arg-bins=-Wl,--export-dynamic-symbol=omc_Error_getCurrentComponent");
}
