//! Build script for `openmodelica_codegen_wasm_jit`.
//!
//! The crate embeds a precompiled wasm "linear-memory runtime"
//! (`openmodelica_codegen_wasm_jit_runtime`, a standalone `[workspace]` cdylib
//! built for `wasm32-unknown-unknown`) via `include_bytes!`. Previously that
//! `.wasm` was produced by hand with `openmodelica_codegen_wasm_jit_runtime/
//! build-runtime.sh` and committed. This script does it automatically — but
//! **cached**: the (relatively slow) wasm `cargo build` runs only when the
//! runtime crate's sources actually change, keyed by a hash of its inputs plus
//! cargo's own `rerun-if-changed` tracking. The result is written to
//! `$OUT_DIR/runtime.wasm`, which the source `include_bytes!`s.
//!
//! Overrides / fallbacks:
//!  * `OMC_WASM_RUNTIME=/path/to/runtime.wasm` — use a prebuilt file, skip building.
//!  * If the wasm build fails (e.g. the `wasm32-unknown-unknown` target is not
//!    installed) but a `runtime.wasm` sits next to the crate, use that and warn;
//!    otherwise fail with instructions.

use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
use std::process::Command;

fn main() {
    let crate_dir = PathBuf::from(env("CARGO_MANIFEST_DIR"));
    let out_dir = PathBuf::from(env("OUT_DIR"));
    let runtime_dir = crate_dir
        .parent()
        .expect("crate has a parent dir")
        .join("openmodelica_codegen_wasm_jit_runtime");
    let dest = out_dir.join("runtime.wasm");

    // Re-run this script only when the runtime crate (or an override) changes.
    // We also list every file individually below (via the hash walk) so edits
    // to existing files are caught even where directory mtime is unreliable.
    println!("cargo:rerun-if-changed={}", runtime_dir.join("Cargo.toml").display());
    println!("cargo:rerun-if-changed={}", runtime_dir.join("Cargo.lock").display());
    // Only track the prebuilt fallback when it actually exists: cargo treats a
    // `rerun-if-changed` on a *missing* path as always-dirty, which would re-run
    // this script on every build (the normal case, since `runtime.wasm` is
    // `.gitignore`d and absent).
    let committed_runtime = crate_dir.join("runtime.wasm");
    if committed_runtime.exists() {
        println!("cargo:rerun-if-changed={}", committed_runtime.display());
    }
    println!("cargo:rerun-if-env-changed=OMC_WASM_RUNTIME");

    // Hash of every input that affects the produced wasm.
    let (hash, tracked) = hash_inputs(&runtime_dir);
    for f in &tracked {
        println!("cargo:rerun-if-changed={}", f.display());
    }
    // The JIT runtime (wasm32-unknown-unknown) and the standalone runtime
    // (wasm32-wasip1) are built from the same sources; both must run on every
    // invocation (the JIT build short-circuits on its own cache/override).
    build_jit_runtime(&crate_dir, &runtime_dir, &out_dir, &dest, &hash);
    build_wasip1_runtime(&crate_dir, &runtime_dir, &out_dir, &hash);
}

/// Build + embed the `wasm32-unknown-unknown` JIT runtime (`runtime.wasm`): the
/// allocator / refcount / string + array primitives the generated model/function
/// modules import at JIT time. Honours the `OMC_WASM_RUNTIME` override and an
/// input-hash cache, falling back to a committed `runtime.wasm`.
fn build_jit_runtime(crate_dir: &Path, runtime_dir: &Path, out_dir: &Path, dest: &Path, hash: &str) {
    let stamp = out_dir.join("runtime.wasm.hash");

    // Explicit override always wins (and is cheap), so check it before the cache.
    if let Ok(path) = std::env::var("OMC_WASM_RUNTIME") {
        copy(Path::new(&path), dest);
        std::fs::write(&stamp, format!("override:{path}")).ok();
        return;
    }

    // Cache hit: the cached wasm is present and its inputs are unchanged.
    if dest.exists() && std::fs::read_to_string(&stamp).ok().as_deref() == Some(hash) {
        return;
    }

    match build_runtime_wasm(runtime_dir, out_dir, "wasm32-unknown-unknown") {
        Ok(produced) => {
            copy(&produced, dest);
            std::fs::write(&stamp, hash).expect("write runtime.wasm.hash");
        }
        Err(e) => {
            // Fall back to a prebuilt artifact committed/dropped next to the crate.
            let committed = crate_dir.join("runtime.wasm");
            if committed.exists() {
                println!(
                    "cargo:warning=could not rebuild the wasm-jit runtime ({e}); \
                     using the prebuilt {}",
                    committed.display()
                );
                copy(&committed, dest);
                std::fs::write(&stamp, "prebuilt").ok();
            } else {
                panic!(
                    "failed to build the wasm-jit linear-memory runtime: {e}\n\
                     Install the target with `rustup target add wasm32-unknown-unknown`, \
                     or set OMC_WASM_RUNTIME=/path/to/runtime.wasm to a prebuilt file."
                );
            }
        }
    }
}

/// Build + embed the `wasm32-wasip1` variant of the runtime (the `_start` + driver
/// half, `src/standalone.rs`) as `runtime_wasip1.wasm`. This is the merge input
/// for the standalone-export module (`emit_standalone_module`, native only), so it
/// is only built when omc itself targets a native host — never folded into the omc
/// wasm module, which cannot run `wasm-merge`. An empty placeholder is written when
/// the omc target is wasm32 or the wasip1 target/build is unavailable, so the
/// native `include_bytes!` still compiles (`emit_standalone_module` reports the
/// absence at call time).
fn build_wasip1_runtime(crate_dir: &Path, runtime_dir: &Path, out_dir: &Path, hash: &str) {
    let dest = out_dir.join("runtime_wasip1.wasm");
    let stamp = out_dir.join("runtime_wasip1.wasm.hash");

    // omc-on-wasm never emits standalone modules (no `wasm-merge`), so skip the
    // (native-host) wasip1 build and leave only an empty placeholder.
    if std::env::var("CARGO_CFG_TARGET_ARCH").as_deref() == Ok("wasm32") {
        if !dest.exists() {
            std::fs::write(&dest, []).ok();
        }
        return;
    }

    if let Ok(path) = std::env::var("OMC_WASM_RUNTIME_WASIP1") {
        copy(Path::new(&path), &dest);
        std::fs::write(&stamp, format!("override:{path}")).ok();
        return;
    }
    println!("cargo:rerun-if-env-changed=OMC_WASM_RUNTIME_WASIP1");

    // The wasip1 variant is built from the same sources, so the same input hash
    // gates the cache.
    if dest.exists() && std::fs::read_to_string(&stamp).ok().as_deref() == Some(hash) {
        return;
    }

    match build_runtime_wasm(runtime_dir, out_dir, "wasm32-wasip1") {
        Ok(produced) => {
            copy(&produced, &dest);
            std::fs::write(&stamp, hash).expect("write runtime_wasip1.wasm.hash");
        }
        Err(e) => {
            let committed = crate_dir.join("runtime_wasip1.wasm");
            if committed.exists() {
                println!(
                    "cargo:warning=could not rebuild the wasip1 standalone runtime ({e}); \
                     using the prebuilt {}",
                    committed.display()
                );
                copy(&committed, &dest);
                std::fs::write(&stamp, "prebuilt").ok();
            } else {
                // Non-fatal: the JIT path does not need it. Only the standalone
                // export (`emit_standalone_module`) does, and it checks for empty.
                println!(
                    "cargo:warning=could not build the wasip1 standalone runtime ({e}); \
                     standalone-export modules will be unavailable. \
                     Install the target with `rustup target add wasm32-wasip1`."
                );
                std::fs::write(&dest, []).ok();
                std::fs::write(&stamp, "missing").ok();
            }
        }
    }
}

/// Compile `openmodelica_codegen_wasm_jit_runtime` to `wasm32-unknown-unknown`
/// (release) and return the path of the produced `.wasm`. Builds into an
/// isolated target dir under `OUT_DIR` so it never contends with the host
/// build's lock, and scrubs host `RUSTFLAGS`/codegen-backend settings (the host
/// workspace selects the cranelift backend, which cannot target wasm — the
/// runtime must build with the default LLVM backend).
fn build_runtime_wasm(runtime_dir: &Path, out_dir: &Path, target: &str) -> Result<PathBuf, String> {
    // One target dir per triple so the two variants (wasm32-unknown-unknown JIT
    // runtime + wasm32-wasip1 standalone runtime) don't churn each other's cache.
    let target_dir = out_dir.join(format!("runtime-target-{target}"));
    let cargo = std::env::var("CARGO").unwrap_or_else(|_| "cargo".to_owned());
    let status = Command::new(cargo)
        .current_dir(runtime_dir)
        .args(["build", "--release", "--target", target])
        .arg("--target-dir")
        .arg(&target_dir)
        // Don't inherit the host build's flags/backend selection.
        .env_remove("RUSTFLAGS")
        .env_remove("CARGO_ENCODED_RUSTFLAGS")
        .env_remove("CARGO_BUILD_RUSTFLAGS")
        .env_remove("RUSTC_WORKSPACE_WRAPPER")
        .status()
        .map_err(|e| format!("could not spawn cargo: {e}"))?;
    if !status.success() {
        return Err(format!("cargo build for {target} exited with {status}"));
    }
    let produced = target_dir
        .join(target)
        .join("release")
        .join("openmodelica_codegen_wasm_jit_runtime.wasm");
    if !produced.exists() {
        return Err(format!("expected wasm not found at {}", produced.display()));
    }
    Ok(produced)
}

/// Stable hash over the runtime crate's sources + manifests. Returns the hex
/// digest and the list of files that were hashed (for `rerun-if-changed`).
fn hash_inputs(runtime_dir: &Path) -> (String, Vec<PathBuf>) {
    let mut files = Vec::new();
    collect_files(&runtime_dir.join("src"), &mut files);
    for m in ["Cargo.toml", "Cargo.lock"] {
        let p = runtime_dir.join(m);
        if p.exists() {
            files.push(p);
        }
    }
    files.sort();
    // Map path -> content, hashed deterministically (FNV-1a over sorted entries).
    let mut entries: BTreeMap<String, Vec<u8>> = BTreeMap::new();
    for f in &files {
        if let Ok(bytes) = std::fs::read(f) {
            entries.insert(f.display().to_string(), bytes);
        }
    }
    let mut h: u64 = 0xcbf29ce484222325;
    let mut feed = |bytes: &[u8]| {
        for &b in bytes {
            h ^= b as u64;
            h = h.wrapping_mul(0x100000001b3);
        }
    };
    for (name, bytes) in &entries {
        feed(name.as_bytes());
        feed(&[0]);
        feed(bytes);
        feed(&[0]);
    }
    (format!("{h:016x}"), files)
}

fn collect_files(dir: &Path, out: &mut Vec<PathBuf>) {
    let Ok(rd) = std::fs::read_dir(dir) else { return };
    for entry in rd.flatten() {
        let p = entry.path();
        if p.is_dir() {
            collect_files(&p, out);
        } else {
            out.push(p);
        }
    }
}

fn copy(from: &Path, to: &Path) {
    std::fs::copy(from, to)
        .unwrap_or_else(|e| panic!("copy {} -> {}: {e}", from.display(), to.display()));
}

fn env(key: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| panic!("{key} not set"))
}
