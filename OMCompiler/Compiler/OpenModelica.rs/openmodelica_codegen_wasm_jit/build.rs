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
    build_external_c_wasm(&crate_dir, &out_dir);
    build_fmi3_me_adapter(&crate_dir, &out_dir);
}

/// Build + embed the model-agnostic FMI3 ME adapter (`openmodelica_fmi3_wasm`) as
/// a dylink side module, linked with the per-model module at FMU-export time.
/// Built here regardless of omc's own target arch: build scripts run on the host.
fn build_fmi3_me_adapter(crate_dir: &Path, out_dir: &Path) {
    for v in ADAPTER_VARIANTS {
        build_fmi3_adapter(crate_dir, out_dir, v);
    }
}

/// One FMI3 adapter build: a WIT world selected by Cargo features, from the same
/// `openmodelica_fmi3_wasm` crate.
struct AdapterVariant {
    /// Output basename (`fmi3_<name>_adapter.wasm`) and env-override stem.
    name: &'static str,
    /// Human label for diagnostics.
    label: &'static str,
    /// `cargo build` feature args (empty = default features → Model Exchange).
    cargo_args: &'static [&'static str],
}

/// Model Exchange (default features), Co-Simulation, and the combined me_cs world.
const ADAPTER_VARIANTS: &[AdapterVariant] = &[
    AdapterVariant { name: "me", label: "ME", cargo_args: &[] },
    AdapterVariant { name: "cs", label: "CS", cargo_args: &["--no-default-features", "--features", "cs"] },
    AdapterVariant { name: "mecs", label: "me_cs", cargo_args: &["--no-default-features", "--features", "me,cs"] },
];

fn build_fmi3_adapter(crate_dir: &Path, out_dir: &Path, v: &AdapterVariant) {
    let name = format!("fmi3_{}_adapter", v.name);
    let dest = out_dir.join(format!("{name}.wasm"));
    let stamp = out_dir.join(format!("{name}.wasm.hash"));
    let adapter_dir = crate_dir
        .parent()
        .expect("crate has a parent dir")
        .join("openmodelica_fmi3_wasm");
    let runtime_dir = crate_dir
        .parent()
        .expect("crate has a parent dir")
        .join("openmodelica_codegen_wasm_jit_runtime");
    let sim_meta_dir = crate_dir
        .parent()
        .expect("crate has a parent dir")
        .join("openmodelica_sim_meta");

    let env_override = format!("OMC_FMI3_{}_ADAPTER", v.name.to_uppercase());
    println!("cargo:rerun-if-env-changed={env_override}");
    if let Ok(path) = std::env::var(&env_override) {
        copy(Path::new(&path), &dest);
        std::fs::write(&stamp, format!("override:{path}")).ok();
        return;
    }

    // The adapter depends on the runtime + sim_meta crates, so hash all three.
    let mut files = Vec::new();
    for d in [&adapter_dir, &runtime_dir, &sim_meta_dir] {
        collect_files(&d.join("src"), &mut files);
        for m in ["Cargo.toml", "Cargo.lock"] {
            let p = d.join(m);
            if p.exists() {
                files.push(p);
            }
        }
    }
    collect_files(&adapter_dir.join("wit"), &mut files);
    files.sort();
    for f in &files {
        println!("cargo:rerun-if-changed={}", f.display());
    }
    let mut h: u64 = 0xcbf29ce484222325;
    for f in &files {
        if let Ok(b) = std::fs::read(f) {
            for &byte in &b {
                h ^= byte as u64;
                h = h.wrapping_mul(0x100000001b3);
            }
        }
    }
    let hash = format!("{h:016x}-{}", v.name);
    if dest.exists()
        && std::fs::metadata(&dest).map(|m| m.len() > 0).unwrap_or(false)
        && std::fs::read_to_string(&stamp).ok().as_deref() == Some(&hash)
    {
        return;
    }

    match build_dylink_adapter(&adapter_dir, out_dir, v) {
        Ok(produced) => {
            copy(&produced, &dest);
            std::fs::write(&stamp, &hash).ok();
        }
        Err(e) => {
            let committed = crate_dir.join(format!("{name}.wasm"));
            if committed.exists() {
                println!(
                    "cargo:warning=could not rebuild the FMI3 {} adapter ({e}); using the prebuilt {}",
                    v.label,
                    committed.display()
                );
                copy(&committed, &dest);
                std::fs::write(&stamp, "prebuilt").ok();
            } else {
                println!(
                    "cargo:warning=could not build the FMI3 {} adapter ({e}); that FMI3 wasm \
                     export will be unavailable. Install `rustup target add wasm32-unknown-unknown`.",
                    v.label
                );
                std::fs::write(&dest, []).ok();
                std::fs::write(&stamp, "missing").ok();
            }
        }
    }
}

/// Compile the FMI3 adapter to a dylink side module. `build-std` because the
/// precompiled `liballoc` is non-PIC; `--allow-undefined` because
/// `__heap_base`/`__heap_end` become imports the linker supplies;
/// `-Zcodegen-backend=llvm` because the workspace default cranelift cannot target
/// wasm and RUSTFLAGS here replaces the crate's `.cargo/config.toml`.
fn build_dylink_adapter(adapter_dir: &Path, out_dir: &Path, v: &AdapterVariant) -> Result<PathBuf, String> {
    let target = "wasm32-unknown-unknown";
    // Separate target dirs: the worlds differ only by feature, and sharing one
    // would rebuild the crate on every alternation.
    let target_dir = out_dir.join(format!("adapter-dylink-target-{}", v.name));
    let cargo = std::env::var("CARGO").unwrap_or_else(|_| "cargo".to_owned());
    let rustflags = "-Zcodegen-backend=llvm -Crelocation-model=pic \
        -Clink-arg=--experimental-pic -Clink-arg=--shared -Clink-arg=--no-entry \
        -Clink-arg=--allow-undefined";
    let status = Command::new(cargo)
        .current_dir(adapter_dir)
        .args(["build", "-Z", "build-std=core,alloc,panic_abort", "--release", "--target", target])
        .args(v.cargo_args)
        .arg("--target-dir")
        .arg(&target_dir)
        .env("RUSTFLAGS", rustflags)
        .env_remove("CARGO_ENCODED_RUSTFLAGS")
        .env_remove("CARGO_BUILD_RUSTFLAGS")
        .env_remove("RUSTC_WORKSPACE_WRAPPER")
        .status()
        .map_err(|e| format!("could not spawn cargo: {e}"))?;
    if !status.success() {
        return Err(format!("cargo build (dylink) exited with {status}"));
    }
    let produced = target_dir.join(target).join("release").join("openmodelica_fmi3_wasm.wasm");
    if !produced.exists() {
        return Err(format!("expected dylink wasm not found at {}", produced.display()));
    }
    Ok(produced)
}

/// Build + embed the ModelicaExternalC WASI side module (`modelicaexternalc.wasm`)
/// that the web (wasmer) simulation host loads to provide the `ext.Modelica*_*`
/// external functions (native uses libffi + the `.so` instead). Compiled from the
/// ModelicaExternalC C sources with `clang --target=wasm32-wasi -mexec-model=reactor`
/// over wasi-libc (Debian `wasi-libc` + `lld` + `libclang-rt-*-dev-wasm32`). Unlike
/// Emscripten's `-sPURE_WASI` (which can't emit `path_open`), this produces a real
/// WASI reactor whose `fopen`/`opendir` lower to `path_open`/`fd_readdir`, so the
/// host's VFS-backed `wasi_shim` gives file-based tables + ModelicaIO readers real
/// file access. `ModelicaIO`/`ModelicaMatIO`/zlib are compiled in (`-DHAVE_ZLIB`).
/// Undefined `env.Modelica*` symbols become imports the host provides;
/// `external_c_stubs.c` supplies the one libc gap (`mkdtemp`, MatIO write-path only).
/// Best-effort: if `clang` is unavailable an empty placeholder is written (the wasmer
/// host then reports these externals as unavailable; native builds don't use it).
fn build_external_c_wasm(crate_dir: &Path, out_dir: &Path) {
    let dest = out_dir.join("modelicaexternalc.wasm");
    let stamp = out_dir.join("modelicaexternalc.wasm.hash");
    let stubs = crate_dir.join("external_c_stubs.c");
    // The C-Sources dir: preferably the exact path the CMake build passes (the
    // crate builds from a synced copy whose relative path can't reach it), else
    // computed relative to the crate (in-tree cargo build).
    println!("cargo:rerun-if-env-changed=OMC_EXTERNAL_C_SOURCES");
    let c_sources = std::env::var("OMC_EXTERNAL_C_SOURCES").ok().map(PathBuf::from).or_else(|| {
        crate_dir.parent().and_then(Path::parent).and_then(Path::parent)
            .map(|omc| omc.join("SimulationRuntime/ModelicaExternalC/C-Sources"))
    });
    // The C source files compiled into the module (each contributes its exports).
    // ModelicaIO+MatIO+snprintf give the file-based readers; zlib backs v7 .mat.
    let sources = [
        "ModelicaStandardTables.c", "ModelicaStrings.c", "ModelicaRandom.c",
        "ModelicaIO.c", "ModelicaMatIO.c", "snprintf.c",
        "ModelicaInternal.c", "ModelicaFFT.c",
    ];
    let src_paths: Vec<Option<PathBuf>> =
        sources.iter().map(|s| c_sources.as_ref().map(|d| d.join(s))).collect();

    println!("cargo:rerun-if-changed={}", stubs.display());
    for src in src_paths.iter().flatten() {
        println!("cargo:rerun-if-changed={}", src.display());
    }
    println!("cargo:rerun-if-env-changed=OMC_WASM_EXTERNAL_C");
    if let Ok(path) = std::env::var("OMC_WASM_EXTERNAL_C") {
        copy(Path::new(&path), &dest);
        std::fs::write(&stamp, format!("override:{path}")).ok();
        return;
    }

    let (c_sources, mut src_paths) = match c_sources {
        Some(d) if src_paths.iter().all(|s| s.as_ref().map(|p| p.exists()).unwrap_or(false)) => {
            (d, src_paths.into_iter().flatten().collect::<Vec<_>>())
        }
        _ => { placeholder(&dest); return; }
    };
    let zlib_dir = c_sources.join("zlib");
    let mut zlib_srcs = collect_c_files(&zlib_dir);
    zlib_srcs.sort();
    for z in &zlib_srcs {
        println!("cargo:rerun-if-changed={}", z.display());
    }
    src_paths.extend(zlib_srcs);
    // Cache on all C inputs plus the compiler/sysroot selection.
    println!("cargo:rerun-if-env-changed=OMC_WASI_CLANG");
    println!("cargo:rerun-if-env-changed=OMC_WASI_SYSROOT");
    let clang = std::env::var("OMC_WASI_CLANG").unwrap_or_else(|_| "clang".to_owned());
    let sysroot = std::env::var("OMC_WASI_SYSROOT").unwrap_or_else(|_| "/usr".to_owned());
    let hash = {
        let mut h: u64 = 0xcbf29ce484222325;
        let mut mix = |bytes: &[u8]| for &byte in bytes { h ^= byte as u64; h = h.wrapping_mul(0x100000001b3); };
        for f in src_paths.iter().chain(std::iter::once(&stubs)) {
            if let Ok(b) = std::fs::read(f) { mix(&b); }
        }
        mix(clang.as_bytes());
        mix(sysroot.as_bytes());
        format!("{h:016x}")
    };
    if dest.exists() && std::fs::metadata(&dest).map(|m| m.len() > 0).unwrap_or(false)
        && std::fs::read_to_string(&stamp).ok().as_deref() == Some(&hash) {
        return;
    }

    // `--export-all`: export every symbol / never dead-code-eliminate, so a
    // compatibility entry point an older MSL calls (e.g. CombiTable1D_init2 vs
    // init3) is always present — mirrors a native `.so`'s dynamic symbol table.
    // `--allow-undefined`: unresolved `Modelica*` calls become `env` imports the
    // host supplies. `-mexec-model=reactor`: exports `_initialize` (runs ctors) and
    // no `_start`. `HAVE_ZLIB` enables v7 .mat; `NO_MUTEX` drops pthread deps.
    let status = Command::new(&clang)
        .args(["--target=wasm32-wasi", "-O2", "-mexec-model=reactor",
               "-DNO_MUTEX", "-DHAVE_ZLIB", "-Wno-error=implicit-function-declaration"])
        .arg(format!("--sysroot={sysroot}"))
        .arg("-I").arg(&c_sources)
        .arg("-I").arg(&zlib_dir)
        .args(&src_paths).arg(&stubs)
        .args(["-Wl,--export-all", "-Wl,--allow-undefined"])
        .arg("-o").arg(&dest)
        .status();
    match status {
        Ok(s) if s.success() && std::fs::metadata(&dest).map(|m| m.len() > 0).unwrap_or(false) => {
            std::fs::write(&stamp, &hash).ok();
        }
        _ => {
            println!("cargo:warning=could not build modelicaexternalc.wasm with `{clang}` \
                      (--target=wasm32-wasi, sysroot {sysroot}); ModelicaExternalC functions \
                      will be unavailable on the web target. Install `wasi-libc`, `lld`, and \
                      `libclang-rt-<ver>-dev-wasm32`.");
            placeholder(&dest);
        }
    }
}

/// The `.c` files directly under `dir` (non-recursive), for the bundled zlib.
fn collect_c_files(dir: &Path) -> Vec<PathBuf> {
    let Ok(rd) = std::fs::read_dir(dir) else { return Vec::new() };
    rd.flatten().map(|e| e.path())
        .filter(|p| p.extension().map(|x| x == "c").unwrap_or(false))
        .collect()
}

/// Write an empty `modelicaexternalc.wasm` so `include_bytes!` still compiles; the wasmer
/// host treats a zero-length module as "no table externals available".
fn placeholder(dest: &Path) {
    if !dest.exists() || std::fs::metadata(dest).map(|m| m.len() > 0).unwrap_or(true) {
        std::fs::write(dest, []).ok();
    }
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
    build_runtime_wasm_named(
        runtime_dir,
        out_dir,
        target,
        "openmodelica_codegen_wasm_jit_runtime",
        "runtime-target",
    )
}

/// Compile a wasm-only cdylib crate at `crate_dir` to `target` (release) and
/// return the produced `<artifact>.wasm`. `target_dir_prefix` isolates its cargo
/// target dir so parallel variants don't churn each other's cache. Scrubs the
/// host build's RUSTFLAGS / codegen-backend so the wasm build uses the default
/// LLVM backend.
fn build_runtime_wasm_named(
    crate_dir: &Path,
    out_dir: &Path,
    target: &str,
    artifact: &str,
    target_dir_prefix: &str,
) -> Result<PathBuf, String> {
    let target_dir = out_dir.join(format!("{target_dir_prefix}-{target}"));
    let cargo = std::env::var("CARGO").unwrap_or_else(|_| "cargo".to_owned());
    let status = Command::new(cargo)
        .current_dir(crate_dir)
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
        .join(format!("{artifact}.wasm"));
    if !produced.exists() {
        return Err(format!("expected wasm not found at {}", produced.display()));
    }
    Ok(produced)
}

/// Stable hash over the runtime crate's sources + manifests. Returns the hex
/// digest and the list of files that were hashed (for `rerun-if-changed`).
///
/// The path dependencies count too: the driver and the metadata wire format live
/// in `openmodelica_sim_meta`. Miss them and the cache serves a runtime whose
/// `decode` no longer matches the emitted blob, which fails at run time
/// (`rt_sim_start failed`), not at build time.
fn hash_inputs(runtime_dir: &Path) -> (String, Vec<PathBuf>) {
    let mut files = Vec::new();
    let deps = runtime_dir.parent().expect("crate has a parent dir");
    for d in [runtime_dir, &deps.join("openmodelica_sim_meta"), &deps.join("openmodelica_mat_writer")] {
        collect_files(&d.join("src"), &mut files);
        for m in ["Cargo.toml", "Cargo.lock"] {
            let p = d.join(m);
            if p.exists() {
                files.push(p);
            }
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
