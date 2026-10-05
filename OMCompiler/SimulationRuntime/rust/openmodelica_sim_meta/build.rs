//! Decides whether the driver gets the real CVODE and IDA (`cfg(sundials)`).
//!
//! Two sources, both prepared by `.cmake/rust_omc.cmake`:
//!   * wasip1 — `OMC_SUNDIALS_WASM_DIR`. The archives are linked by the runtime
//!     crate's build script (it owns the link order for the whole set), so here
//!     the variable only selects the cfg.
//!   * host — `OMC_SUNDIALS_NATIVE_DIR`, linked here: the host-driven driver
//!     lives in `libOpenModelicaCompiler`, which nothing else links SUNDIALS into.
//!     These are the C runtime's own archives, so their index size is whatever
//!     that build chose (64) rather than the wasm archives' 32 — hence
//!     `sundials_i64`.
//!
//! Unset means no CVODE/IDA; `simflags::check` then rejects `-s=cvode`/`-s=ida`
//! up front.
//!
//! Ipopt (`cfg(ipopt)`) follows the host SUNDIALS pattern: `OMC_IPOPT_NATIVE_DIR`
//! holds the C runtime's own archives, linked here because the optimization driver
//! lives in `libOpenModelicaCompiler` too. There is no wasm build — MUMPS is
//! Fortran 90 — so an in-wasm runtime never gets one and reports the same
//! "Ipopt is needed but not available" a C runtime without `OMC_HAVE_IPOPT` does.

use std::path::Path;

/// Archives in link order: each entry may only depend on later ones. SUNDIALS
/// ships one archive per module -- the N_Vector/SUNMatrix/SUNLinearSolver
/// implementations and the SUNContext/SUNErrCode core are their own -- so each
/// has to be listed, mirroring `LIBS` in openmodelica_codegen_wasm_jit_runtime.
const NATIVE_LIBS: &[&str] = &[
    "sundials_kinsol",
    "sundials_cvode",
    "sundials_idas",
    "sundials_sunlinsolklu",
    "sundials_sunlinsoldense",
    "sundials_sunmatrixsparse",
    "sundials_sunmatrixdense",
    "sundials_nvecserial",
    "sundials_core",
    "klu",
    "amd",
    "colamd",
    "btf",
    "suitesparseconfig",
];

/// Ipopt and its linear solver, in link order (the C runtime's own order): each
/// entry may only depend on later ones. `seq` is MUMPS' sequential MPI stub, which
/// `mumps_common` needs for `mumps_elapse_`; `metis` is its fill-reducing ordering.
const IPOPT_LIBS: &[&str] = &["ipopt", "dmumps", "mumps_common", "seq", "metis"];

fn main() {
    println!("cargo::rustc-check-cfg=cfg(sundials)");
    println!("cargo::rustc-check-cfg=cfg(sundials_i64)");
    println!("cargo::rustc-check-cfg=cfg(ipopt)");
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_WASM_DIR");
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_NATIVE_DIR");
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_NATIVE_INDEX_SIZE");
    println!("cargo:rerun-if-env-changed=OMC_IPOPT_NATIVE_DIR");
    sundials();
    ipopt();
}

/// The classic `optimize()` runtime's NLP solver, host-only.
fn ipopt() {
    if std::env::var("CARGO_CFG_TARGET_ARCH").as_deref() == Ok("wasm32") {
        return;
    }
    let Some(dir) = std::env::var_os("OMC_IPOPT_NATIVE_DIR") else { return };
    let lib = Path::new(&dir).join("lib");
    let missing: Vec<_> = IPOPT_LIBS
        .iter()
        .filter(|l| ![format!("lib{l}.a"), format!("{l}.lib")].iter().any(|n| lib.join(n).exists()))
        .collect();
    if !missing.is_empty() {
        panic!(
            "OMC_IPOPT_NATIVE_DIR={} is missing {missing:?}; the Ipopt build failed \
             (check the rust_ipopt_native_collect CMake target)",
            lib.display()
        );
    }
    println!("cargo:rustc-link-search=native={}", lib.display());
    for l in IPOPT_LIBS {
        println!("cargo:rustc-link-lib=static={l}");
    }
    // Ipopt is C++; MUMPS is Fortran (quadmath). LAPACK/BLAS: `lapack_dyn` on
    // unix, elsewhere what CMake found (see link_lapack), else by name.
    //
    // quadmath only where GCC builds it. It exists to provide __float128 on
    // targets whose `long double` is something else; on aarch64 `long double`
    // is already IEEE binary128, so there is no libquadmath at all -- not even a
    // cross package -- and naming it fails the link.
    let unix = std::env::var_os("CARGO_CFG_UNIX").is_some();
    let arch = std::env::var("CARGO_CFG_TARGET_ARCH").unwrap_or_default();
    if !unix {
        link_lapack(&["lapack", "blas"]);
    }
    let mut libs: Vec<&str> = vec!["stdc++", "gfortran"];
    if matches!(arch.as_str(), "x86" | "x86_64") {
        libs.push("quadmath");
    }
    for l in libs {
        println!("cargo:rustc-link-lib=dylib={l}");
    }
    println!("cargo:rustc-cfg=ipopt");
}

/// Windows has no system `lapack`/`blas` (MSVC has no `lapack.lib`, MSYS2 only
/// OpenBLAS), so CMake names the LAPACK/BLAS it found in `OMC_LAPACK_LINK`,
/// `|`-separated. A copy of the one in `openmodelica_nls`'s script, for Ipopt.
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

fn sundials() {
    // The FMI3 adapter's build: the calls stay undefined and become wasm imports the
    // FMU linker resolves, so there is nothing to link and no target to check.
    if std::env::var_os("CARGO_FEATURE_SUNDIALS_EXTERN").is_some() {
        println!("cargo:rustc-cfg=sundials");
        return;
    }
    let arch = std::env::var("CARGO_CFG_TARGET_ARCH").unwrap_or_default();
    let os = std::env::var("CARGO_CFG_TARGET_OS").unwrap_or_default();
    if arch == "wasm32" {
        // wasm32-unknown-unknown is the no_std function-JIT runtime: no libc for
        // SUNDIALS to call.
        if os == "wasi" && std::env::var_os("OMC_SUNDIALS_WASM_DIR").is_some() {
            println!("cargo:rustc-cfg=sundials");
        }
        return;
    }
    let Some(dir) = std::env::var_os("OMC_SUNDIALS_NATIVE_DIR") else { return };
    let lib = Path::new(&dir).join("lib");
    // MSVC keeps the CMake target's `_static` suffix; openmodelica_solvers, which
    // links them, resolves the same way.
    let missing: Vec<_> = NATIVE_LIBS
        .iter()
        .filter(|l| {
            ![format!("lib{l}.a"), format!("{l}.lib"), format!("{l}_static.lib")]
                .iter()
                .any(|n| lib.join(n).exists())
        })
        .collect();
    if !missing.is_empty() {
        panic!("OMC_SUNDIALS_NATIVE_DIR={} is missing {missing:?}; the host SUNDIALS \
                build failed (check the rust_sundials_native_collect CMake target)", lib.display());
    }
    // The archives are linked by `openmodelica_solvers`, which owns the
    // bindings; here the directory only decides the cfg.
    println!("cargo:rustc-cfg=sundials");
    match std::env::var("OMC_SUNDIALS_NATIVE_INDEX_SIZE").as_deref() {
        Ok("64") => println!("cargo:rustc-cfg=sundials_i64"),
        Ok("32") => {}
        other => panic!("OMC_SUNDIALS_NATIVE_INDEX_SIZE must be 32 or 64, got {other:?}"),
    }
}
