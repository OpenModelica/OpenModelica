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
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

/// Run a nested build. Captured, not inherited: concurrent children would
/// interleave, and none may write on this script's `cargo:` stdout.
fn run(cmd: &mut Command, what: &str) -> Result<(), String> {
    let out = cmd
        .stdin(Stdio::null())
        .output()
        .map_err(|e| format!("could not spawn {what}: {e}"))?;
    std::io::stderr().write_all(&out.stderr).ok();
    if !out.status.success() {
        return Err(format!("{what} exited with {}", out.status));
    }
    Ok(())
}

/// `items.iter().map(f)`, one thread each, results in input order; a worker panic
/// resurfaces here. Spawning all at once does not oversubscribe: the nested
/// cargos share this build's jobserver through `CARGO_MAKEFLAGS`.
fn par_map<T: Sync, R: Send>(items: &[T], f: impl Fn(&T) -> R + Sync) -> Vec<R> {
    let f = &f;
    std::thread::scope(|s| {
        let handles: Vec<_> = items.iter().map(|it| s.spawn(move || f(it))).collect();
        handles
            .into_iter()
            .map(|h| h.join().unwrap_or_else(|e| std::panic::resume_unwind(e)))
            .collect()
    })
}

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
    let (mut hash, tracked) = hash_inputs(&runtime_dir, &[]);
    for f in &tracked {
        println!("cargo:rerun-if-changed={}", f.display());
    }
    // SUNDIALS/KLU for the wasip1 runtimes. Part of the stamp key: gaining or
    // losing the archives changes the runtime's exports, so the blobs must rebuild.
    // CMake sets OMC_SUNDIALS_WASM_DIR when the sundials feature is enabled.
    println!("cargo::rustc-check-cfg=cfg(sundials)");
    let sundials = sundials_wasm_dir();
    if let Some((_, key)) = &sundials {
        hash = format!("{hash}:{key}");
        // Backs the crate's `SUNDIALS` const: with the archives, `-lss=klu` is
        // servable.
        println!("cargo:rustc-cfg=sundials");
    }
    let sundials_dir = sundials.as_ref().map(|(d, _)| d.as_path());
    // The JIT runtime (wasm32-unknown-unknown) and the standalone runtime
    // (wasm32-wasip1) are built from the same sources; both must run on every
    // invocation (the JIT build short-circuits on its own cache/override).
    std::thread::scope(|s| {
        s.spawn(|| build_jit_runtime(&crate_dir, &runtime_dir, &out_dir, &dest, &hash));
        s.spawn(|| build_wasip1_runtime(&crate_dir, &runtime_dir, &out_dir, &hash, sundials_dir));
        s.spawn(|| {
            build_wasip1_interactive_runtime(&crate_dir, &runtime_dir, &out_dir, &hash, sundials_dir)
        });
        s.spawn(|| build_external_c_wasm(&crate_dir, &out_dir));
        s.spawn(|| build_fmi3_me_adapter(&crate_dir, &out_dir));
        s.spawn(|| build_native_fmu_loaders(&crate_dir, &out_dir));
    });
}

/// Build the FMI loader (`openmodelica_fmi_ls_wasm_to_native`, both versions) once per
/// platform an exported FMU may run on: this machine's plus
/// `OMC_FMU_NATIVE_TARGETS`. Independent of omc's *own* target, so a wasm omc
/// gets them too.
fn build_native_fmu_loaders(crate_dir: &Path, out_dir: &Path) {
    let loader_dir = crate_dir
        .parent()
        .expect("crate has a parent dir")
        .join("openmodelica_fmi_ls_wasm_to_native");
    println!("cargo:rerun-if-env-changed=OMC_FMU_NATIVE_TARGETS");

    // `(triple, asked for by name)`. A named target that will not build is fatal:
    // shipping an omc that quietly offers fewer platforms than the build asked
    // for is worse than a red build. `OMC_FMU_NATIVE_OPTIONAL` takes the whole
    // set back to best-effort.
    println!("cargo:rerun-if-env-changed=OMC_FMU_NATIVE_OPTIONAL");
    let optional = std::env::var("OMC_FMU_NATIVE_OPTIONAL").is_ok_and(|v| v != "0");
    let mut targets = vec![(env("HOST"), false)];
    for t in std::env::var("OMC_FMU_NATIVE_TARGETS").unwrap_or_default().split(',') {
        let t = t.trim();
        if !t.is_empty() && !targets.iter().any(|(x, _)| x == t) {
            targets.push((t.to_owned(), true));
        }
    }

    let (digest, files) = hash_inputs(&loader_dir, &[]);
    for f in &files {
        println!("cargo:rerun-if-changed={}", f.display());
    }
    let sdk = macos_sdk();

    // cargo-xwin keeps only the CRT architectures it was last asked for, so name
    // every MSVC target's arch up front.
    let mut archs: Vec<&str> = targets
        .iter()
        .map(|(t, _)| t)
        .filter(|t| t.ends_with("-msvc"))
        .filter_map(|t| t.split('-').next())
        .collect();
    archs.sort();
    archs.dedup();
    let xwin_arch = archs.join(",");

    // Not embedded in omc: one native library per platform is ~4 MB that only an
    // FMU export ever reads. CMake collects them from `OMC_FMU_LOADERS_OUT` and
    // installs them (lib/omc/fmu-loaders, or the web bundle), with an index for
    // the browser, which cannot list a directory.
    println!("cargo:rerun-if-env-changed=OMC_FMU_LOADERS_OUT");
    let staging = std::env::var_os("OMC_FMU_LOADERS_OUT")
        .map(PathBuf::from)
        .unwrap_or_else(|| out_dir.join("fmu-loaders"));
    // Libraries an earlier build produced, taken as-is instead of cross-built
    // again. Ignored when it is `staging`, which the next lines empty.
    println!("cargo:rerun-if-env-changed=OMC_FMU_LOADERS_IN");
    std::fs::create_dir_all(&staging).expect("create the FMU loader staging dir");
    let staging_real = staging.canonicalize().unwrap_or_else(|_| staging.clone());
    let prebuilt = std::env::var_os("OMC_FMU_LOADERS_IN")
        .map(PathBuf::from)
        .and_then(|d| d.canonicalize().ok())
        .filter(|d| d.is_dir() && *d != staging_real);
    // Emptied, so dropping a platform from the list also drops its library from
    // the install rather than leaving one nothing indexes.
    std::fs::remove_dir_all(&staging).ok();
    std::fs::create_dir_all(&staging).expect("create the FMU loader staging dir");
    struct Loader {
        target: String,
        requested: bool,
        platform: String,
        artifact: String,
        ext: String,
        dest: PathBuf,
        stamp: PathBuf,
        hash: String,
        build: bool,
    }
    let mut loaders = Vec::new();
    for (target, requested) in &targets {
        let Some((platform, artifact)) = loader_artifact_name(target) else {
            let msg = format!(
                "{target} cannot be an FMU platform: the component is compiled by cranelift, \
                 which only has x86-64 and aarch64 backends among the platforms FMI names"
            );
            assert!(!*requested || optional, "{msg}");
            println!("cargo:warning={msg}");
            continue;
        };
        let dest = out_dir.join(format!("fmu_loader_{platform}"));
        let stamp = out_dir.join(format!("fmu_loader_{platform}.hash"));
        let hash = match sdk.as_deref().filter(|_| target.contains("apple")) {
            Some(sdk) => format!("{digest}-{target}-{sdk}"),
            None => format!("{digest}-{target}"),
        };
        let cached = dest.exists()
            && std::fs::metadata(&dest).map(|m| m.len() > 0).unwrap_or(false)
            && std::fs::read_to_string(&stamp).ok().as_deref() == Some(&hash);
        let ext =
            Path::new(&artifact).extension().and_then(|e| e.to_str()).unwrap_or("so").to_owned();
        let handed_over = prebuilt
            .as_ref()
            .map(|d| d.join(format!("{platform}.{ext}")))
            .filter(|f| f.is_file());
        if let (false, Some(f)) = (cached, &handed_over) {
            copy(f, &dest);
            std::fs::write(&stamp, &hash).ok();
        }
        loaders.push(Loader {
            target: target.clone(),
            requested: *requested,
            platform,
            artifact,
            ext,
            dest,
            stamp,
            hash,
            build: !cached && handed_over.is_none(),
        });
    }

    // A wasmtime-linking cdylib per platform, none filling the machine alone.
    // MSVC targets use `cargo xwin` which races on its clang symlink setup when
    // two instances run concurrently; build them sequentially.
    let mut xwin_results: Vec<_> = Vec::new();
    let xwin: Vec<_> = loaders
        .iter()
        .filter(|l| l.build && l.target.ends_with("-msvc"))
        .collect();
    for l in &xwin {
        xwin_results.push(
            build_native_loader(&loader_dir, out_dir, &l.target, &l.artifact, &xwin_arch, sdk.as_deref())
                .map(|produced| {
                    copy(&produced, &l.dest);
                    std::fs::write(&l.stamp, &l.hash).ok();
                }),
        );
    }
    let built = par_map(&loaders, |l| {
        if l.target.ends_with("-msvc") {
            return Ok(());
        }
        if !l.build {
            return Ok(());
        }
        build_native_loader(&loader_dir, out_dir, &l.target, &l.artifact, &xwin_arch, sdk.as_deref())
            .map(|produced| {
                copy(&produced, &l.dest);
                std::fs::write(&l.stamp, &l.hash).ok();
            })
    });

    let mut index = String::new();
    let mut xwin_results_iter = xwin_results.into_iter();
    for (l, outcome) in loaders.iter().zip(built) {
        let Loader { target, platform, ext, .. } = l;
        // MSVC targets were built sequentially (not through par_map)
        let outcome = if l.target.ends_with("-msvc") && l.build {
            xwin_results_iter.next().unwrap()
        } else {
            outcome
        };
        if let Err(e) = outcome {
            let msg = format!(
                "could not build the FMU loader for {target} ({e}), so an exported FMU \
                 cannot offer the {platform} platform. A cross target needs its Rust \
                 target and a C toolchain: cargo-xwin for *-pc-windows-msvc, \
                 cargo-zigbuild (+ ziglang) otherwise, and a macOS SDK in \
                 OMC_FMU_MACOS_SDK for *-apple-darwin. \
                 Set OMC_FMU_NATIVE_OPTIONAL=1 to build without it."
            );
            assert!(!l.requested || optional, "{msg}");
            println!("cargo:warning={msg}");
            continue;
        }
        copy(&l.dest, &staging.join(format!("{platform}.{ext}")));
        index.push_str(&format!(
            "{}{{\"platform\":{platform:?},\"triple\":{target:?},\"file\":\"{platform}.{ext}\",\"ext\":\".{ext}\"}}",
            if index.is_empty() { "" } else { "," }
        ));
    }
    std::fs::write(staging.join("index.json"), format!("[{index}]\n")).expect("write the loader index");
}

/// `(FMI platform tuple, artifact file name)` for a rustc target triple.
fn loader_artifact_name(target: &str) -> Option<(String, String)> {
    let arch = target.split('-').next()?;
    let arch = match arch {
        "x86_64" => "x86_64",
        "aarch64" => "aarch64",
        _ => return None,
    };
    let stem = "openmodelica_fmi_ls_wasm_to_native";
    let (os, artifact) = if target.contains("windows") {
        ("windows", format!("{stem}.dll"))
    } else if target.contains("darwin") || target.contains("apple") {
        ("darwin", format!("lib{stem}.dylib"))
    } else if target.contains("linux") {
        ("linux", format!("lib{stem}.so"))
    } else {
        return None;
    };
    Some((format!("{arch}-{os}"), artifact))
}

/// The cargo subcommand that can *link* for `target`: the loader is an ordinary
/// native library (`wasmtime-wasi` compiles a C fiber), so a cross target needs a
/// cross C toolchain — cargo-xwin for the MSVC CRT/SDK, cargo-zigbuild for the
/// rest. `OMC_FMU_NATIVE_CARGO_<triple with _ for ->` overrides one target, e.g.
/// to use a real cross gcc.
fn cargo_subcommand(target: &str) -> Vec<String> {
    let key = format!("OMC_FMU_NATIVE_CARGO_{}", target.replace('-', "_"));
    println!("cargo:rerun-if-env-changed={key}");
    if let Ok(v) = std::env::var(&key) {
        return v.split_whitespace().map(str::to_owned).collect();
    }
    let sub = if target == env("HOST") {
        vec!["build"]
    } else if target.ends_with("-msvc") {
        vec!["xwin", "build"]
    } else {
        vec!["zigbuild"]
    };
    sub.into_iter().map(str::to_owned).collect()
}

/// An unpacked macOS SDK for the `*-apple-darwin` loaders: zig ships no Apple
/// frameworks and the loader reaches CoreFoundation through `cap-time-ext`.
/// `OMC_FMU_MACOS_SDK` is CMake's `RUST_OMC_MACOS_SDK`.
fn macos_sdk() -> Option<String> {
    println!("cargo:rerun-if-env-changed=OMC_FMU_MACOS_SDK");
    println!("cargo:rerun-if-env-changed=SDKROOT");
    ["OMC_FMU_MACOS_SDK", "SDKROOT"]
        .iter()
        .filter_map(|k| std::env::var(k).ok())
        .find(|v| !v.is_empty())
}

/// zig, cargo-zigbuild and cargo-xwin cache below `$HOME/.cache`, unwritable for
/// a container uid with no passwd entry. A fixed fallback path: cargo-zigbuild's
/// linker wrapper lives there and reaches rustc as `-Clinker=`, an sccache key.
fn cross_toolchain_cache(cmd: &mut Command) {
    if home_cache_writable() {
        return;
    }
    let cache = std::env::temp_dir().join("omc-cross-toolchain-cache");
    for (var, dir) in [
        ("CARGO_ZIGBUILD_CACHE_DIR", "cargo-zigbuild"),
        ("XWIN_CACHE_DIR", "cargo-xwin"),
        ("ZIG_GLOBAL_CACHE_DIR", "zig"),
    ] {
        if std::env::var_os(var).is_none() {
            cmd.env(var, cache.join(dir));
        }
    }
}

fn home_cache_writable() -> bool {
    let Some(dir) = std::env::var_os("XDG_CACHE_HOME")
        .map(PathBuf::from)
        .or_else(|| std::env::var_os("HOME").map(|h| PathBuf::from(h).join(".cache")))
    else {
        return false;
    };
    if std::fs::create_dir_all(&dir).is_err() {
        return false;
    }
    let probe = dir.join(".omc-cache-probe");
    let ok = std::fs::write(&probe, []).is_ok();
    std::fs::remove_file(&probe).ok();
    ok
}

fn build_native_loader(
    loader_dir: &Path,
    out_dir: &Path,
    target: &str,
    artifact: &str,
    xwin_arch: &str,
    macos_sdk: Option<&str>,
) -> Result<PathBuf, String> {
    let target_dir = out_dir.join(format!("fmu-loader-target-{target}"));
    let cargo = std::env::var("CARGO").unwrap_or_else(|_| "cargo".to_owned());
    let mut cmd = Command::new(cargo);
    cross_toolchain_cache(&mut cmd);
    if !xwin_arch.is_empty() {
        cmd.env("XWIN_ARCH", xwin_arch);
    }
    if target.contains("apple") {
        match macos_sdk {
            // zig reports a nonexistent sysroot as the same "framework not found".
            Some(sdk) if !Path::new(sdk).join("System/Library/Frameworks").is_dir() => {
                return Err(format!("{sdk} is not a macOS SDK (no System/Library/Frameworks)"));
            }
            Some(sdk) => {
                cmd.env("SDKROOT", sdk);
            }
            // A macOS host has its own SDK, found through xcrun.
            None if env("HOST").contains("apple") => {}
            None => {
                return Err("no macOS SDK: point OMC_FMU_MACOS_SDK (CMake RUST_OMC_MACOS_SDK) \
                            or SDKROOT at an unpacked MacOSX<version>.sdk"
                    .to_owned())
            }
        }
        // ld64 defaults the install name to the output path, which would put this
        // build directory in every exported FMU.
        cmd.env("RUSTFLAGS", format!("-Clink-arg=-Wl,-install_name,@rpath/{artifact}"));
    } else {
        cmd.env_remove("RUSTFLAGS");
    }
    cmd.current_dir(loader_dir)
        .args(cargo_subcommand(target))
        .args(["--release", "--target", target])
        .arg("--target-dir")
        .arg(&target_dir)
        .env_remove("CARGO_ENCODED_RUSTFLAGS")
        .env_remove("CARGO_BUILD_RUSTFLAGS")
        .env_remove("RUSTC_WORKSPACE_WRAPPER");
    run(&mut cmd, &format!("cargo build for {target}"))?;
    let produced = target_dir.join(target).join("release").join(artifact);
    if !produced.exists() {
        return Err(format!("expected library not found at {}", produced.display()));
    }
    Ok(produced)
}

/// Build + embed the model-agnostic FMI3 ME adapter (`openmodelica_fmi3_wasm`) as
/// a dylink side module, linked with the per-model module at FMU-export time.
/// Built here regardless of omc's own target arch: build scripts run on the host.
/// Mandatory: a failed build aborts rather than shipping an omc without it.
fn build_fmi3_me_adapter(crate_dir: &Path, out_dir: &Path) {
    par_map(ADAPTER_VARIANTS, |v| build_fmi3_adapter(crate_dir, out_dir, v));
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

/// Model Exchange (default features), Co-Simulation, and the combined me_cs world; the
/// `_sundials` variants add CVODE/IDA and are picked only for a `method=` needing them.
const ADAPTER_VARIANTS: &[AdapterVariant] = &[
    AdapterVariant { name: "me", label: "ME", cargo_args: &[] },
    AdapterVariant { name: "cs", label: "CS", cargo_args: &["--no-default-features", "--features", "cs"] },
    AdapterVariant { name: "mecs", label: "me_cs", cargo_args: &["--no-default-features", "--features", "me,cs"] },
    AdapterVariant {
        name: "cs_sundials",
        label: "CS+SUNDIALS",
        cargo_args: &["--no-default-features", "--features", "cs,sundials"],
    },
    AdapterVariant {
        name: "mecs_sundials",
        label: "me_cs+SUNDIALS",
        cargo_args: &["--no-default-features", "--features", "me,cs,sundials"],
    },
];

fn build_fmi3_adapter(crate_dir: &Path, out_dir: &Path, v: &AdapterVariant) {
    let name = format!("fmi3_{}_adapter", v.name);
    let dest = out_dir.join(format!("{name}.wasm"));
    let stamp = out_dir.join(format!("{name}.wasm.hash"));
    let adapter_dir = crate_dir
        .parent()
        .expect("crate has a parent dir")
        .join("openmodelica_fmi3_wasm");
    let env_override = format!("OMC_FMI3_{}_ADAPTER", v.name.to_uppercase());
    println!("cargo:rerun-if-env-changed={env_override}");
    if let Ok(path) = std::env::var(&env_override) {
        copy(Path::new(&path), &dest);
        std::fs::write(&stamp, format!("override:{path}")).ok();
        return;
    }

    // Every crate the adapter reaches through a `path` dep, transitively: the
    // runtime and sim_meta are only the first hop — sim_meta reaches daskr, and a
    // fixed list bakes a stale solver into the adapter.
    let (digest, files) = hash_inputs(&adapter_dir, &[adapter_dir.join("wit")]);
    for f in &files {
        println!("cargo:rerun-if-changed={}", f.display());
    }
    let hash = format!("{digest}-{}", v.name);
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
                panic!(
                    "failed to build the FMI3 {} adapter: {e}\n\
                     FMI3 wasm FMU export requires it. Install the wasm target and std \
                     sources (`rustup target add wasm32-unknown-unknown`, \
                     `rustup component add rust-src`), or set {env_override} to a prebuilt .wasm.",
                    v.label
                );
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
    let mut cmd = Command::new(cargo);
    cmd.current_dir(adapter_dir)
        .args(["build", "-Z", "build-std=core,alloc,panic_abort", "--release", "--target", target])
        .args(v.cargo_args)
        .arg("--target-dir")
        .arg(&target_dir)
        .env("RUSTFLAGS", rustflags)
        .env_remove("CARGO_ENCODED_RUSTFLAGS")
        .env_remove("CARGO_BUILD_RUSTFLAGS")
        .env_remove("RUSTC_WORKSPACE_WRAPPER");
    run(&mut cmd, &format!("cargo build (dylink, {})", v.label))?;
    let produced = target_dir.join(target).join("release").join("openmodelica_fmi3_wasm.wasm");
    if !produced.exists() {
        return Err(format!("expected dylink wasm not found at {}", produced.display()));
    }
    Ok(produced)
}

/// The `env` imports `sim_runtime_wasmer::define_external_imports` binds. Any other
/// undefined symbol is a link error, see `build_external_c_wasm`.
const HOST_PROVIDED: &[&str] = &[
    "ModelicaError",
    "ModelicaFormatError",
    "ModelicaFormatMessage",
    "ModelicaFormatWarning",
    "ModelicaVFormatError",
    "ModelicaVFormatWarning",
    "ModelicaAllocateString",
    "ModelicaAllocateStringWithErrorReturn",
    "ModelicaInternal_getTime",
    "ModelicaInternal_getpid",
    "usertab",
];

/// Build + embed the ModelicaExternalC WASI side module (`modelicaexternalc.wasm`)
/// for the web (wasmer) simulation host. Provides `ext.Modelica*_*` external functions
/// (native uses libffi + `.so` instead). Compiled with `clang --target=wasm32-wasip1
/// --sysroot=OMC_WASI_PIC_SYSROOT`. Uses the same PIC wasi-libc sysroot as the dylink
/// module built by openmodelica_wasi_libc.
///
/// Mandatory: a failed build is a hard error (no placeholder).
fn build_external_c_wasm(crate_dir: &Path, out_dir: &Path) {
    let dest = out_dir.join("modelicaexternalc.wasm");
    let stamp = out_dir.join("modelicaexternalc.wasm.hash");

    // Check for prebuilt override (CI hand-off) before requiring OMC_EXTERNAL_C_SOURCES.
    println!("cargo:rerun-if-env-changed=OMC_WASM_EXTERNAL_C");
    if let Ok(path) = std::env::var("OMC_WASM_EXTERNAL_C") {
        copy(Path::new(&path), &dest);
        std::fs::write(&stamp, format!("override:{path}")).ok();
        return;
    }

    println!("cargo:rerun-if-env-changed=OMC_EXTERNAL_C_SOURCES");
    let c_sources = std::env::var("OMC_EXTERNAL_C_SOURCES")
        .map(PathBuf::from)
        .expect("OMC_EXTERNAL_C_SOURCES not set (CMake provides it)");

    let stubs = crate_dir.join("external_c_stubs.c");
    let sources = [
        "ModelicaStandardTables.c", "ModelicaStrings.c", "ModelicaRandom.c",
        "ModelicaIO.c", "ModelicaMatIO.c", "snprintf.c",
        "ModelicaInternal.c", "ModelicaFFT.c",
    ];
    let src_paths: Vec<PathBuf> = sources.iter().map(|s| c_sources.join(s)).collect();

    println!("cargo:rerun-if-changed={}", stubs.display());
    for src in &src_paths {
        println!("cargo:rerun-if-changed={}", src.display());
    }

    // Verify all sources exist.
    for src in &src_paths {
        if !src.exists() {
            panic!("missing C source: {}", src.display());
        }
    }

    let zlib_dir = c_sources.join("zlib");
    let mut zlib_srcs = collect_c_files(&zlib_dir);
    zlib_srcs.sort();
    for z in &zlib_srcs {
        println!("cargo:rerun-if-changed={}", z.display());
    }

    println!("cargo:rerun-if-env-changed=OMC_WASI_CLANG");
    println!("cargo:rerun-if-env-changed=OMC_WASI_PIC_SYSROOT");
    let clang = std::env::var("OMC_WASI_CLANG").unwrap_or_else(|_| "clang".to_owned());
    let sysroot = std::env::var("OMC_WASI_PIC_SYSROOT")
        .expect("OMC_WASI_PIC_SYSROOT not set (CMake provides it)");

    let all_srcs: Vec<_> = src_paths.iter().chain(zlib_srcs.iter()).collect();
    let hash = {
        let mut h: u64 = 0xcbf29ce484222325;
        let mut mix = |bytes: &[u8]| for &byte in bytes { h ^= byte as u64; h = h.wrapping_mul(0x100000001b3); };
        for f in all_srcs.iter().copied().chain(std::iter::once(&stubs)) {
            if let Ok(b) = std::fs::read(f) { mix(&b); }
        }
        mix(clang.as_bytes());
        mix(sysroot.as_bytes());
        for s in HOST_PROVIDED { mix(s.as_bytes()); }
        format!("{h:016x}")
    };
    if dest.exists() && std::fs::metadata(&dest).map(|m| m.len() > 0).unwrap_or(false)
        && std::fs::read_to_string(&stamp).ok().as_deref() == Some(&hash) {
        return;
    }

    // `--export-all`: export every symbol so older MSL compatibility entry points
    // are always present. `-mexec-model=reactor`: exports `_initialize` (runs ctors),
    // no `_start`. `-nodefaultlibs` means `-lc` has to be explicit.
    //
    // `--allow-undefined-file` rather than blanket `--allow-undefined`: a sysroot that
    // fails to provide libc must be a link error, not a module whose `malloc`/`strlen`/
    // `__wasi_init_tp` quietly turn into imports the host cannot satisfy.
    let permit = out_dir.join("modelicaexternalc.imports");
    std::fs::write(&permit, HOST_PROVIDED.join("\n")).expect("write import permit list");
    let builtins = find_wasm_builtins().ok_or_else(|| {
        "no libclang_rt.builtins-wasm32.a found (need libclang-rt-*-dev-wasm32)"
    }).unwrap_or_else(|e| panic!("{e}"));
    let mut cmd = Command::new(&clang);
    cmd.args(["--target=wasm32-wasip1", "-O2", "-mexec-model=reactor",
               "-nodefaultlibs", "-DNO_MUTEX", "-DHAVE_ZLIB",
               "-Wno-error=implicit-function-declaration"])
        .arg(format!("--sysroot={sysroot}"))
        .arg("-I").arg(&c_sources)
        .arg("-I").arg(&zlib_dir)
        .args(&all_srcs).arg(&stubs)
        .arg("-lc")
        .arg(&builtins)
        .arg("-Wl,--export-all")
        .arg(format!("-Wl,--allow-undefined-file={}", permit.display()))
        .arg("-o").arg(&dest);
    let what = format!("{clang} (modelicaexternalc.wasm, --target=wasm32-wasip1, sysroot {sysroot})");
    run(&mut cmd, &what).unwrap_or_else(|e| panic!("{e}"));
    if !std::fs::metadata(&dest).map(|m| m.len() > 0).unwrap_or(false) {
        panic!("modelicaexternalc.wasm is empty");
    }
    std::fs::write(&stamp, &hash).ok();
}

/// The `.c` files directly under `dir` (non-recursive), for the bundled zlib.
fn collect_c_files(dir: &Path) -> Vec<PathBuf> {
    let Ok(rd) = std::fs::read_dir(dir) else { return Vec::new() };
    rd.flatten().map(|e| e.path())
        .filter(|p| p.extension().map(|x| x == "c").unwrap_or(false))
        .collect()
}

/// Locate the clang wasm builtins archive (`libclang_rt.builtins-wasm32.a`).
/// Checked in env override first, then auto-detected via `clang -print-resource-dir`.
fn find_wasm_builtins() -> Option<PathBuf> {
    if let Ok(p) = std::env::var("OMC_WASM_BUILTINS") {
        let p = PathBuf::from(p);
        if p.exists() { return Some(p); }
    }
    let clang = std::env::var("OMC_WASI_CLANG").unwrap_or_else(|_| "clang".to_owned());
    let out = Command::new(&clang).arg("-print-resource-dir").output().ok()?;
    let dir = PathBuf::from(String::from_utf8(out.stdout).ok()?.trim());
    let cand = dir.join("lib/wasi/libclang_rt.builtins-wasm32.a");
    cand.exists().then_some(cand)
}

/// Return the SUNDIALS/KLU wasm archives dir prebuilt by CMake.
///
/// Returns `Some((dir, key))` when `OMC_SUNDIALS_WASM_DIR` is set (the key is
/// appended to the runtime stamp so sundials on/off toggles rebuild the blobs).
/// Returns `None` when the env var is absent (sundials feature disabled).
fn sundials_wasm_dir() -> Option<(PathBuf, String)> {
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_WASM_DIR");
    let dir = std::env::var("OMC_SUNDIALS_WASM_DIR").ok()?
        .into();
    Some((dir, "cmake".to_owned()))
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
fn build_wasip1_runtime(
    crate_dir: &Path,
    runtime_dir: &Path,
    out_dir: &Path,
    hash: &str,
    sundials_dir: Option<&Path>,
) {
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

    println!("cargo:rerun-if-env-changed=OMC_WASM_RUNTIME_WASIP1");
    if let Ok(path) = std::env::var("OMC_WASM_RUNTIME_WASIP1") {
        copy(Path::new(&path), &dest);
        std::fs::write(&stamp, format!("override:{path}")).ok();
        return;
    }

    // The wasip1 variant is built from the same sources, so the same input hash
    // gates the cache.
    if dest.exists() && std::fs::read_to_string(&stamp).ok().as_deref() == Some(hash) {
        return;
    }

    match build_runtime_wasm_named(
        runtime_dir,
        out_dir,
        "wasm32-wasip1",
        "openmodelica_codegen_wasm_jit_runtime",
        "runtime-target",
        &["--no-default-features", "--features", "standalone"],
        sundials_dir,
    ) {
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
/// Build + embed the `wasm32-wasip1` **interactive** runtime (`runtime_wasip1_
/// interactive.wasm`): the crate with `--features session` (host-driven in-wasm
/// driver) so it exports `rt_*`+`memory`+`__indirect_function_table` (the model
/// imports them) and imports only `wasi_snapshot_preview1` — the std runtime the
/// sparse solver (`rsparse`) needs, instantiated with the existing `wasi_shim`.
/// Native omc adds `host_lin_solve` (delegate the solve to the host); web omc
/// omits it and solves in-wasm.
fn build_wasip1_interactive_runtime(
    crate_dir: &Path,
    runtime_dir: &Path,
    out_dir: &Path,
    hash: &str,
    sundials_dir: Option<&Path>,
) {
    let dest = out_dir.join("runtime_wasip1_interactive.wasm");
    let stamp = out_dir.join("runtime_wasip1_interactive.wasm.hash");

    // omc-on-wasm builds this too (Part A2 uses it via wasmer-js); no wasm-merge is
    // needed, unlike the standalone variant, so it is not skipped for wasm32 omc.
    println!("cargo:rerun-if-env-changed=OMC_WASM_RUNTIME_WASIP1_INTERACTIVE");
    if let Ok(path) = std::env::var("OMC_WASM_RUNTIME_WASIP1_INTERACTIVE") {
        copy(Path::new(&path), &dest);
        std::fs::write(&stamp, format!("override:{path}")).ok();
        return;
    }

    // Native wasmtime: lean host-delegating blob (`host_lin_solve`), no in-wasm
    // driver/solver linked in. Web (wasm32) and native-wasmer solve in-wasm
    // (`session,inwasm_solve`) — the wasmer host has no native solver. `inwasm_driver`
    // opts the native build into the in-wasm variant for OMC_WASM_INWASM_DRIVER=1.
    let native = std::env::var("CARGO_CFG_TARGET_ARCH").as_deref() != Ok("wasm32");
    let wasmer = std::env::var("CARGO_FEATURE_ENGINE_WASMER").is_ok();
    let inwasm_driver = std::env::var("CARGO_FEATURE_INWASM_DRIVER").is_ok();
    let features = if native && !wasmer && !inwasm_driver {
        "host_lin_solve,host_log"
    } else {
        "session,inwasm_solve,host_log"
    };
    // The feature set is part of the cache key: toggling the engine must rebuild.
    let stamp_val = format!("{hash}:{features}");

    if dest.exists() && std::fs::read_to_string(&stamp).ok().as_deref() == Some(stamp_val.as_str()) {
        return;
    }

    match build_runtime_wasm_named(
        runtime_dir,
        out_dir,
        "wasm32-wasip1",
        "openmodelica_codegen_wasm_jit_runtime",
        "runtime-interactive-target",
        &["--no-default-features", "--features", features],
        sundials_dir,
    ) {
        Ok(produced) => {
            copy(&produced, &dest);
            std::fs::write(&stamp, &stamp_val).expect("write runtime_wasip1_interactive.wasm.hash");
        }
        Err(e) => {
            // Hard error, not a silent fallback: the no_std runtime would dense-solve.
            let _ = crate_dir;
            panic!(
                "failed to build the wasip1 interactive runtime: {e}\n\
                 Install the target with `rustup target add wasm32-wasip1`, or set \
                 OMC_WASM_RUNTIME_WASIP1_INTERACTIVE=/path/to/runtime_wasip1_interactive.wasm."
            );
        }
    }
}

fn build_runtime_wasm(runtime_dir: &Path, out_dir: &Path, target: &str) -> Result<PathBuf, String> {
    build_runtime_wasm_named(
        runtime_dir,
        out_dir,
        target,
        "openmodelica_codegen_wasm_jit_runtime",
        "runtime-target",
        &[],
        None,
    )
}

/// Compile a wasm-only cdylib crate at `crate_dir` to `target` (release) and
/// return the produced `<artifact>.wasm`. `target_dir_prefix` isolates its cargo
/// target dir so parallel variants don't churn each other's cache. `extra_args`
/// passes cargo feature flags (e.g. `--no-default-features`). Scrubs the host
/// build's RUSTFLAGS / codegen-backend so the wasm build uses the default LLVM
/// backend.
fn build_runtime_wasm_named(
    crate_dir: &Path,
    out_dir: &Path,
    target: &str,
    artifact: &str,
    target_dir_prefix: &str,
    extra_args: &[&str],
    sundials_dir: Option<&Path>,
) -> Result<PathBuf, String> {
    let target_dir = out_dir.join(format!("{target_dir_prefix}-{target}"));
    let cargo = std::env::var("CARGO").unwrap_or_else(|_| "cargo".to_owned());
    let mut cmd = Command::new(cargo);
    cmd.current_dir(crate_dir)
        .args(["build", "--release", "--target", target])
        .args(extra_args)
        .arg("--target-dir")
        .arg(&target_dir)
        // Don't inherit the host build's flags/backend selection.
        .env_remove("RUSTFLAGS")
        .env_remove("CARGO_ENCODED_RUSTFLAGS")
        .env_remove("CARGO_BUILD_RUSTFLAGS")
        .env_remove("RUSTC_WORKSPACE_WRAPPER");
    match sundials_dir {
        Some(d) => { cmd.env("OMC_SUNDIALS_WASM_DIR", d); }
        // Cargo's env is inherited; clear a stale outer setting so the nested build
        // agrees with what this script actually produced.
        None => { cmd.env_remove("OMC_SUNDIALS_WASM_DIR"); }
    }
    run(&mut cmd, &format!("cargo build for {target} ({target_dir_prefix})"))?;
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
fn hash_inputs(runtime_dir: &Path, extra_dirs: &[PathBuf]) -> (String, Vec<PathBuf>) {
    let mut files = Vec::new();
    for d in extra_dirs {
        collect_files(d, &mut files);
    }
    // Hash the runtime crate and every crate it reaches via `path = "..."` deps,
    // discovered transitively from the Cargo.toml files: a hardcoded list silently
    // misses edits to an unlisted path-dep and bakes a stale crate into the wasm.
    let mut queue = vec![runtime_dir.to_path_buf()];
    let mut seen: std::collections::BTreeSet<PathBuf> = std::collections::BTreeSet::new();
    while let Some(dir) = queue.pop() {
        let key = std::fs::canonicalize(&dir).unwrap_or_else(|_| dir.clone());
        if !seen.insert(key) {
            continue;
        }
        // The directory too: a new file is invisible to a rerun-if-changed list
        // built from the files that existed last time.
        println!("cargo:rerun-if-changed={}", dir.join("src").display());
        collect_files(&dir.join("src"), &mut files);
        let manifest = dir.join("Cargo.toml");
        for m in ["Cargo.toml", "Cargo.lock"] {
            let p = dir.join(m);
            if p.exists() {
                files.push(p);
            }
        }
        for dep in path_deps(&manifest) {
            queue.push(dir.join(dep));
        }
    }
    files.sort();
    files.dedup();
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

/// Relative `path = "..."` values from a Cargo.toml (local path dependencies).
fn path_deps(manifest: &Path) -> Vec<String> {
    let Ok(text) = std::fs::read_to_string(manifest) else { return Vec::new() };
    let mut out = Vec::new();
    for line in text.lines() {
        let Some(rest) = line.split_once("path").and_then(|(_, r)| {
            let r = r.trim_start();
            r.strip_prefix('=').map(|r| r.trim_start())
        }) else {
            continue;
        };
        let bytes = rest.as_bytes();
        if bytes.first() != Some(&b'"') {
            continue;
        }
        if let Some(end) = rest[1..].find('"') {
            out.push(rest[1..=end].to_string());
        }
    }
    out
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
