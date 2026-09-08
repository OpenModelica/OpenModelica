//! Build `openmodelica_result_web` for `wasm32-unknown-unknown` into
//! `OUT_DIR/pkg`, which `src/lib.rs` embeds. Needs only `rustup target add
//! wasm32-unknown-unknown`: wasm-bindgen runs as a library, so its schema
//! version cannot drift from the module's the way an installed CLI's can.
//!
//! `wasm-opt` is optional (it only shrinks the module) and comes from
//! `OMC_WASM_OPT` -- which CMake already sets for `openmodelica_wasm_jit` --
//! `WASM_OPT`, or `PATH`.

use std::path::{Path, PathBuf};
use std::process::Command;

use wasm_bindgen_cli_support::Bindgen;

/// What `rustc --print cfg --target wasm32-unknown-unknown` reports. Needed
/// because a release build is stripped of the `target_features` section
/// binaryen reads, so it assumes MVP and rejects what rustc emitted.
const DEFAULT_FEATURES: &str = "--enable-bulk-memory --enable-multivalue --enable-mutable-globals \
     --enable-nontrapping-float-to-int --enable-reference-types --enable-sign-ext --enable-simd";

fn main() {
    let out = PathBuf::from(std::env::var("OUT_DIR").expect("OUT_DIR"));
    // The runtime workspace root; the module's own manifest points at the
    // compiler workspace, which needs transpiled MetaModelica.
    let runtime = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR"))
        .parent()
        .expect("the crate has a parent directory")
        .to_path_buf();
    for f in ["openmodelica_result_web/src/lib.rs", "openmodelica_result_web/Cargo.toml"] {
        println!("cargo::rerun-if-changed={}", runtime.join(f).display());
    }
    for f in ["openmodelica_result_files/src", "openmodelica_result_diff/src"] {
        println!("cargo::rerun-if-changed={}", runtime.join(f).display());
    }
    for v in ["OMC_WASM_OPT", "OMC_WASM_OPT_FEATURES", "WASM_OPT"] {
        println!("cargo::rerun-if-env-changed={v}");
    }

    let pkg = out.join("pkg");
    if let Err(e) = build(&runtime, &out, &pkg) {
        println!("cargo::error={e}");
        std::process::exit(1);
    }
    println!("cargo::rustc-env=OPENMODELICA_RESULT_WEB_PKG={}", pkg.display());
}

fn build(runtime: &Path, out: &Path, pkg: &Path) -> Result<(), String> {
    let target_dir = out.join("wasm-target");
    // A nested cargo must not share the outer build directory (it is locked),
    // nor inherit the flags cargo exports into a build script.
    let mut cargo = Command::new(std::env::var("CARGO").unwrap_or_else(|_| "cargo".into()));
    for k in [
        "RUSTC",
        "RUSTC_WRAPPER",
        "RUSTC_WORKSPACE_WRAPPER",
        "RUSTFLAGS",
        "CARGO_ENCODED_RUSTFLAGS",
        "CARGO_BUILD_TARGET",
        "CARGO_BUILD_RUSTFLAGS",
        "CARGO_MAKEFLAGS",
        "CARGO_UNSTABLE_BUILD_STD",
    ] {
        cargo.env_remove(k);
    }
    let status = cargo
        .env("CARGO_TARGET_DIR", &target_dir)
        .current_dir(runtime)
        .args([
            "build",
            "-p",
            "openmodelica_result_web",
            "--release",
            "--target",
            "wasm32-unknown-unknown",
        ])
        .status()
        .map_err(|e| format!("could not run cargo for the wasm build: {e}"))?;
    if !status.success() {
        return Err(format!(
            "building openmodelica_result_web for wasm32-unknown-unknown failed ({status}); \
             `rustup target add wasm32-unknown-unknown` if the target is missing"
        ));
    }

    let wasm = target_dir.join("wasm32-unknown-unknown/release/openmodelica_result_web.wasm");
    Bindgen::new()
        .input_path(&wasm)
        .web(true)
        // The library defaults this the other way from the CLI, leaving `init()`
        // nowhere to fetch the module from. CMake still uses the CLI.
        .map(|b| b.omit_default_module_path(false))
        .and_then(|b| b.typescript(false).generate(pkg))
        // The versions resolve in separate workspaces, so they can be bumped apart.
        .map_err(|e| {
            let pinned = pinned_bindgen_version(runtime).unwrap_or_else(|| "that version".to_owned());
            format!(
                "wasm-bindgen failed: {e}\nIf this is a schema mismatch, set \
                 wasm-bindgen-cli-support in openmodelica_result_web_embed/Cargo.toml to {pinned}, \
                 the wasm-bindgen openmodelica_result_web pins."
            )
        })?;
    wasm_opt(&pkg.join("openmodelica_result_web_bg.wasm"));
    Ok(())
}

/// The `wasm-bindgen = "=x.y.z"` line of `openmodelica_result_web`'s manifest,
/// for the error message above. `None` if it cannot be read.
fn pinned_bindgen_version(runtime: &Path) -> Option<String> {
    let manifest = std::fs::read_to_string(runtime.join("openmodelica_result_web/Cargo.toml")).ok()?;
    manifest.lines().find_map(|l| {
        let rest = l.strip_prefix("wasm-bindgen")?.trim_start().strip_prefix('=')?;
        Some(rest.trim().trim_matches('"').trim_start_matches('=').trim().to_owned())
    })
}

/// `-Oz`: about a third off, which every page serving the module pays for.
fn wasm_opt(wasm: &Path) {
    let exe = ["OMC_WASM_OPT", "WASM_OPT"]
        .iter()
        .find_map(|v| std::env::var_os(v).filter(|s| !s.is_empty()))
        .unwrap_or_else(|| "wasm-opt".into());
    let features = std::env::var("OMC_WASM_OPT_FEATURES").unwrap_or_else(|_| DEFAULT_FEATURES.to_owned());
    let tmp = wasm.with_extension("opt.tmp");
    let mut cmd = Command::new(&exe);
    cmd.arg("-Oz");
    for f in features.split_whitespace() {
        cmd.arg(f);
    }
    let ok = cmd.arg(wasm).arg("-o").arg(&tmp).status().map(|s| s.success()).unwrap_or(false)
        && std::fs::metadata(&tmp).map(|m| m.len() > 0).unwrap_or(false);
    if ok {
        std::fs::rename(&tmp, wasm).ok();
    } else {
        std::fs::remove_file(&tmp).ok();
        println!(
            "cargo::warning=wasm-opt ({}) did not run; openmodelica_result_web is about a third \
             larger than it need be",
            exe.to_string_lossy()
        );
    }
}
