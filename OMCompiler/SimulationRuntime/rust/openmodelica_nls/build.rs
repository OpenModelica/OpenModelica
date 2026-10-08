//! Decides whether the nonlinear ladder gets the real KINSOL (`cfg(sundials)`),
//! and compiles `src/primme_svds.c` where the host links a native PRIMME.
//!
//! Same two sources as `openmodelica_sim_meta`'s script, and for the same reason:
//! `openmodelica_solvers` owns the link order for the whole archive set, so here
//! the variables only select the cfg.

fn main() {
    primme();
    // `system-lapack` names `dgetrf_`/`dgetrs_`; an executable already links
    // liblapack, but a plain `cargo test` of this crate does not.
    if std::env::var_os("CARGO_FEATURE_SYSTEM_LAPACK").is_some() {
        link_lapack(&["lapack"]);
    }
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

/// `omc_primme_svds`, which `-lv=LOG_NLS_SVD` reaches. The wasm build compiles the
/// shim into the PRIMME archive itself (rust_omc.cmake's `rust_primme_wasm`); a
/// native host names the archive the C runtime links and gets the shim here.
fn primme() {
    println!("cargo::rustc-check-cfg=cfg(primme)");
    println!("cargo:rerun-if-env-changed=OMC_PRIMME_NATIVE_DIR");
    println!("cargo:rerun-if-env-changed=OMC_PRIMME_INCLUDE_DIR");
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_WASM_DIR");
    println!("cargo:rerun-if-changed=src/primme_svds.c");
    // wasm: the shim is compiled into libprimme.a itself, which the same
    // directory carries (rust_omc.cmake's rust_primme_wasm feeds the collect).
    if std::env::var("CARGO_CFG_TARGET_ARCH").unwrap_or_default() == "wasm32" {
        if std::env::var("CARGO_CFG_TARGET_OS").unwrap_or_default() == "wasi"
            && std::env::var_os("OMC_SUNDIALS_WASM_DIR").is_some()
        {
            println!("cargo:rustc-cfg=primme");
        }
        return;
    }
    let Some(lib) = std::env::var_os("OMC_PRIMME_NATIVE_DIR") else { return };
    let include = std::env::var("OMC_PRIMME_INCLUDE_DIR")
        .expect("OMC_PRIMME_NATIVE_DIR without OMC_PRIMME_INCLUDE_DIR");
    cc::Build::new()
        .file("src/primme_svds.c")
        .include(&include)
        .warnings(false)
        .compile("omc_primme_svds");
    println!("cargo:rustc-link-search=native={}", std::path::Path::new(&lib).display());
    println!("cargo:rustc-link-lib=static=primme");
    // PRIMME's dense algebra, in all four precisions.
    link_lapack(&["lapack", "blas"]);
    println!("cargo:rustc-cfg=primme");
}

/// Windows has no system `lapack`/`blas` (MSVC has no `lapack.lib`, MSYS2 only
/// OpenBLAS), so CMake names the LAPACK/BLAS it found in `OMC_LAPACK_LINK`,
/// `|`-separated. `openmodelica_sim_meta`'s script does the same for Ipopt.
fn link_lapack(system: &[&str]) {
    println!("cargo:rerun-if-env-changed=OMC_LAPACK_LINK");
    let Ok(libs) = std::env::var("OMC_LAPACK_LINK") else {
        for l in system {
            println!("cargo:rustc-link-lib=dylib={l}");
        }
        return;
    };
    let gnu = std::env::var("CARGO_CFG_TARGET_ENV").as_deref() == Ok("gnu");
    for lib in libs.split('|').map(std::path::Path::new) {
        let (Some(dir), Some(name)) = (lib.parent(), link_name(lib, gnu)) else { continue };
        println!("cargo:rustc-link-search=native={}", dir.display());
        println!("cargo:rustc-link-lib=dylib={name}");
    }
}

/// The name to link a library file by: `openblas.lib` on MSVC, and on MinGW the
/// import library `libopenblas.dll.a` (or `libopenblas.a`) is `-lopenblas`.
fn link_name(lib: &std::path::Path, gnu: bool) -> Option<String> {
    let file = lib.file_name()?.to_str()?;
    if !gnu {
        return Some(lib.file_stem()?.to_string_lossy().into_owned());
    }
    let stem = file.strip_suffix(".dll.a").or_else(|| file.strip_suffix(".a"))
        .or_else(|| file.strip_suffix(".dll"))?;
    Some(stem.strip_prefix("lib").unwrap_or(stem).to_string())
}
