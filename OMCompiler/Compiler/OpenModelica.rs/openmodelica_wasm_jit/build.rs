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
        s.spawn(|| {
            let adapters = build_fmi3_me_adapter(&crate_dir, &out_dir, sundials_dir.is_some());
            build_solver_dylinks(&out_dir, sundials_dir, &adapters);
        });
        s.spawn(|| build_wasip1_fused_adapter(&crate_dir, &out_dir, &hash, sundials_dir));
        s.spawn(|| build_native_fmu_loaders(&crate_dir, &out_dir));
        s.spawn(|| build_lapack_dylink(&crate_dir, &out_dir));
    });
}

/// Build the **fused** artifact runtime: the FMI 3.0 adapter, the in-wasm driver
/// and the simulation runtime in one non-PIC `wasm32-wasip1` core module.
///
/// It links the solver archives statically, as the standalone runtimes do, so it needs
/// none of the side modules a component FMU composes. Model-independent, so it is
/// compiled once into the `.cwasm` cache.
fn build_wasip1_fused_adapter(
    crate_dir: &Path,
    out_dir: &Path,
    hash: &str,
    sundials_dir: Option<&Path>,
) {
    let dest = out_dir.join("fmi3_fused_wasip1.wasm");
    let stamp = out_dir.join("fmi3_fused_wasip1.wasm.hash");
    println!("cargo:rerun-if-env-changed=OMC_FMI3_FUSED_WASIP1");
    if let Ok(path) = std::env::var("OMC_FMI3_FUSED_WASIP1") {
        copy(Path::new(&path), &dest);
        std::fs::write(&stamp, format!("override:{path}")).ok();
        return;
    }
    let adapter_dir = crate_dir
        .parent()
        .expect("crate has a parent dir")
        .join("openmodelica_fmi3_wasm");
    let features = match sundials_dir {
        Some(_) => "me,cs,capi,sundials,host_lin_solve",
        None => "me,cs,capi,host_lin_solve",
    };
    // The adapter's sources as well as the runtime's, and how it is built: any of
    // them changing produces a different blob, and a stamp that misses one serves
    // a stale blob that looks current.
    let (digest, files) = hash_inputs(&adapter_dir, &[adapter_dir.join("wit")]);
    for f in &files {
        println!("cargo:rerun-if-changed={}", f.display());
    }
    let stamp_val =
        format!("{hash}:{digest}:{features}:build-std,rustflags-opt3,immediate-abort");
    if dest.exists()
        && std::fs::metadata(&dest).map(|m| m.len() > 0).unwrap_or(false)
        && std::fs::read_to_string(&stamp).ok().as_deref() == Some(stamp_val.as_str())
    {
        return;
    }
    // The runtime crate's own `.cargo/config.toml` flags, which an explicit
    // RUSTFLAGS here replaces. `-Copt-level=3` in the flags and not a `--config`
    // profile, which the crate's `opt-level = "s"` outranks: `rt_solve_nls` and
    // minpack link in here, and the runtime's manifest sets 3 for them.
    let rustflags = "-Clink-arg=--export-table -Clink-arg=--growable-table \
                     -Clink-arg=--allow-undefined -Ctarget-feature=+simd128 -Copt-level=3";
    let target = "wasm32-wasip1";
    let target_dir = out_dir.join("adapter-fused-target");
    let cargo = std::env::var("CARGO").unwrap_or_else(|_| "cargo".to_owned());
    let mut cmd = Command::new(cargo);
    cmd.current_dir(&adapter_dir)
        // `-Zbuild-std`: the crate's `panic = "immediate-abort"`, which the
        // precompiled `core` does not satisfy. The dylink adapter builds the same
        // way.
        .args(["build", "-Z", "build-std=std,panic_abort", "--release", "--target", target])
        .args(["--no-default-features", "--features", features])
        .arg("--target-dir")
        .arg(&target_dir)
        // `--allow-undefined`: the model's `function*` are imports here, and the
        // runtime's own cdylib artifact (unused) references the sink this crate
        // defines. sccache goes with the outer build's other wrappers.
        .env("RUSTFLAGS", rustflags)
        .env_remove("CARGO_ENCODED_RUSTFLAGS")
        .env_remove("CARGO_BUILD_RUSTFLAGS")
        .env_remove("RUSTC_WRAPPER")
        .env_remove("RUSTC_WORKSPACE_WRAPPER")
        ;
    match sundials_dir {
        Some(d) => { cmd.env("OMC_SUNDIALS_WASM_DIR", d); }
        None => { cmd.env_remove("OMC_SUNDIALS_WASM_DIR"); }
    }
    match run(&mut cmd, "cargo build (fused wasip1 adapter)") {
        Ok(()) => {
            let produced = target_dir
                .join(target)
                .join("release")
                .join("openmodelica_fmi3_wasm.wasm");
            if produced.exists() {
                copy(&produced, &dest);
                std::fs::write(&stamp, &stamp_val).ok();
                return;
            }
            println!("cargo:warning=the fused wasip1 adapter produced no wasm");
        }
        // Not fatal: the dylink adapter still serves the artifact, one runtime copy
        // short of SUNDIALS.
        Err(e) => println!("cargo:warning=could not build the fused wasip1 adapter ({e})"),
    }
    std::fs::write(&dest, []).ok();
    std::fs::write(&stamp, "missing").ok();
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

/// Build + embed `openmodelica_lapack` as a dylink side module (`liblapack.wasm`)
/// for an FMU whose model calls `external "FORTRAN 77"` LAPACK. Mandatory like
/// the FMI3 adapter: a failure means a broken build environment.
///
/// `build-std=std` because the precompiled `libstd` is not PIC and a dylink side
/// module has to be; `+simd128` for faer's kernels.
fn build_lapack_dylink(crate_dir: &Path, out_dir: &Path) {
    let dest = out_dir.join("liblapack.wasm");
    let stamp = out_dir.join("liblapack.wasm.hash");
    let lapack_dir = crate_dir.parent().expect("crate has a parent dir").join("openmodelica_lapack");

    println!("cargo:rerun-if-env-changed=OMC_LAPACK_WASM");
    if let Ok(path) = std::env::var("OMC_LAPACK_WASM") {
        copy(Path::new(&path), &dest);
        std::fs::write(&stamp, format!("override:{path}")).ok();
        return;
    }

    let (hash, files) = hash_inputs(&lapack_dir, &[]);
    let hash = format!("{hash}-{}", wasm_opt_key());
    for f in &files {
        println!("cargo:rerun-if-changed={}", f.display());
    }
    if dest.exists()
        && std::fs::metadata(&dest).map(|m| m.len() > 0).unwrap_or(false)
        && std::fs::read_to_string(&stamp).ok().as_deref() == Some(&hash)
    {
        return;
    }

    match build_lapack_wasm(&lapack_dir, out_dir) {
        Ok(produced) => {
            copy(&produced, &dest);
            wasm_opt(&dest);
            std::fs::write(&stamp, &hash).ok();
        }
        Err(e) => panic!(
            "failed to build the LAPACK dylink module: {e}\n\
             A wasm FMU whose model calls Modelica.Math.Matrices needs it. Needs the wasm \
             target and std sources (`rustup target add wasm32-unknown-unknown`, \
             `rustup component add rust-src`); set OMC_LAPACK_WASM to a prebuilt .wasm to \
             skip the build."
        ),
    }
}

fn build_lapack_wasm(lapack_dir: &Path, out_dir: &Path) -> Result<PathBuf, String> {
    let target = "wasm32-unknown-unknown";
    let target_dir = out_dir.join("lapack-dylink-target");
    let cargo = std::env::var("CARGO").unwrap_or_else(|_| "cargo".to_owned());
    let rustflags = "-Zcodegen-backend=llvm -Crelocation-model=pic \
        -Clink-arg=--experimental-pic -Clink-arg=--shared -Clink-arg=--no-entry \
        -Clink-arg=--allow-undefined -Ctarget-feature=+simd128";
    let mut cmd = Command::new(cargo);
    cmd.current_dir(lapack_dir)
        .args(["build", "-Z", "build-std=std,panic_abort", "--release", "--target", target])
        .args(["--features", "fortran-abi"])
        .arg("--target-dir")
        .arg(&target_dir)
        .env("RUSTFLAGS", rustflags)
        .env_remove("CARGO_ENCODED_RUSTFLAGS")
        .env_remove("CARGO_BUILD_RUSTFLAGS")
        .env_remove("RUSTC_WORKSPACE_WRAPPER");
    run(&mut cmd, "cargo build (LAPACK dylink)")?;
    let produced = target_dir.join(target).join("release").join("openmodelica_lapack.wasm");
    if !produced.exists() {
        return Err(format!("expected dylink wasm not found at {}", produced.display()));
    }
    Ok(produced)
}

/// Build + embed the model-agnostic FMI3 ME adapter (`openmodelica_fmi3_wasm`) as
/// a dylink side module, linked with the per-model module at FMU-export time.
/// Built here regardless of omc's own target arch: build scripts run on the host.
/// Mandatory: a failed build aborts rather than shipping an omc without it.
/// Returns the two that import the solvers, me_cs first: its imports decide what the
/// side modules export, and ME's have to be a subset.
fn build_fmi3_me_adapter(crate_dir: &Path, out_dir: &Path, sundials: bool) -> [PathBuf; 2] {
    par_map(ADAPTER_VARIANTS, |v| build_fmi3_adapter(crate_dir, out_dir, v, sundials));
    [out_dir.join("fmi3_mecs_adapter.wasm"), out_dir.join("fmi3_me_adapter.wasm")]
}

/// `wasm-opt -O3` the module in place, when CMake found binaryen. Every exported FMU
/// links these, and they are built once per omc build and stamped, so binaryen's
/// optimizer costs the export nothing: ~11% off the module, and the solver libraries'
/// inner loops get -O3 rather than only clang's.
///
/// The feature list comes from CMake (`WASM_OPT_FEATURES`) rather than `-all`: the
/// release `strip` drops the `target_features` section binaryen would auto-detect
/// from, so it defaults to MVP and rejects the bulk-memory/sign-ext ops these carry.
/// A failure is not fatal -- the unoptimized module is correct.
///
/// Not applied to what `openmodelica_wasi_libc` hands over: `libc_pic` and
/// `modelicaexternalc` are already optimized by wasi-libc and clang, and the vendored
/// `wasi_snapshot_preview1` adapter is a wasmtime release artifact, not a side module
/// of ours.
fn wasm_opt(path: &Path) {
    let Some(exe) = std::env::var_os("OMC_WASM_OPT").filter(|v| !v.is_empty()) else { return };
    let tmp = path.with_extension("opt.tmp");
    let mut cmd = Command::new(&exe);
    cmd.arg("-O3");
    for f in std::env::var("OMC_WASM_OPT_FEATURES").unwrap_or_default().split_whitespace() {
        cmd.arg(f);
    }
    let ok = cmd
        .arg(path)
        .arg("-o")
        .arg(&tmp)
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
        && std::fs::metadata(&tmp).map(|m| m.len() > 0).unwrap_or(false);
    if ok {
        std::fs::rename(&tmp, path).ok();
    } else {
        std::fs::remove_file(&tmp).ok();
        println!("cargo:warning=wasm-opt failed on {}; using it unoptimized", path.display());
    }
}

/// Part of every stamp that covers a wasm-opt'd module: turning binaryen on or off
/// has to rebuild them, and a cached blob from the other setting is not equivalent.
fn wasm_opt_key() -> String {
    match std::env::var("OMC_WASM_OPT").ok().filter(|v| !v.is_empty()) {
        Some(exe) => format!("opt3:{exe}:{}", std::env::var("OMC_WASM_OPT_FEATURES").unwrap_or_default()),
        None => "noopt".to_string(),
    }
}

/// One selectable solver library: an FMU links `BASE_GROUP` plus whichever of these
/// its `--fmiFlags` can reach, and a stub for each one left out.
struct SolverGroup {
    /// Blob basename, and `om_have_<name>` for the capability report.
    name: &'static str,
    archives: &'static [&'static str],
    /// Prefixes of the adapter's imports this group owns. These have to *partition*
    /// the entry points: SUNDIALS bundles a copy of the shared implementations into
    /// every integrator archive, so asking what defines what would give `driver` and
    /// `kinsol` their own copy of everything in `base`.
    owns: &'static [&'static str],
}

/// Always linked when any other group is: the SUNDIALS core, vectors, matrices, the
/// dense/Krylov/nonlinear solvers and KLU the others call into. Named for KLU, the
/// only solver in it a flag selects on its own.
const BASE_GROUP: SolverGroup = SolverGroup {
    name: "klu",
    archives: &[
        "sundials_sunlinsolklu", "sundials_sunlinsoldense",
        "sundials_sunlinsolspgmr", "sundials_sunlinsolspbcgs", "sundials_sunlinsolsptfqmr",
        "sundials_sunnonlinsolnewton", "sundials_sunnonlinsolfixedpoint",
        "sundials_sunmatrixsparse", "sundials_sunmatrixdense",
        "sundials_nvecserial", "sundials_core",
        "klu", "amd", "colamd", "btf", "suitesparseconfig",
    ],
    owns: &["N_V", "SUN", "klu_"],
};

/// PRIMME is not among them: the adapter is built without that feature, and its
/// BLAS/LAPACK calls resolve against a Rust crate no side module has.
const SOLVER_GROUPS: &[SolverGroup] = &[
    SolverGroup {
        name: "sundials_driver",
        archives: &["sundials_idas", "sundials_cvode"],
        owns: &["CVode", "IDA"],
    },
    SolverGroup { name: "kinsol", archives: &["sundials_kinsol"], owns: &["KIN"] },
    SolverGroup {
        name: "umfpack",
        archives: &["umfpack", "amd", "suitesparseconfig"],
        owns: &["umfpack_"],
    },
    SolverGroup { name: "lis", archives: &["lis"], owns: &["lis_"] },
];

/// Build one PIC side module per solver library, plus a stub for each.
///
/// The archives are the ones the wasip1 runtimes link statically: CMake compiles them
/// `-fPIC` for exactly this, and wasm-ld relaxes those relocations away again in the
/// static link, which comes out byte-identical.
///
/// Exports are read off `adapter`, the me_cs adapter that will import them -- the
/// entry points each group `owns`, plus, for the base, whatever the others leave
/// undefined. `--export-if-defined` both pulls the archive member in and keeps it, so
/// a driver reaching for a new entry point needs no list here updated.
///
/// Empty blobs without the archives, so an FMU export rejects `-s=cvode` up front.
fn build_solver_dylinks(out_dir: &Path, sundials_dir: Option<&Path>, adapters: &[PathBuf; 2]) {
    let all: Vec<&SolverGroup> = core::iter::once(&BASE_GROUP).chain(SOLVER_GROUPS).collect();
    println!("cargo:rerun-if-env-changed=OMC_WASM_OPT");
    println!("cargo:rerun-if-env-changed=OMC_WASM_OPT_FEATURES");
    println!("cargo:rerun-if-env-changed=OMC_SOLVER_DYLINK_DIR");
    let override_dir = std::env::var_os("OMC_SOLVER_DYLINK_DIR").map(PathBuf::from);
    if let Some(dir) = &override_dir {
        for g in &all {
            for kind in ["", "_stub"] {
                let f = format!("solver_{}{kind}.wasm", g.name);
                copy(&dir.join(&f), &out_dir.join(&f));
            }
        }
        return;
    }
    if sundials_dir.is_none() {
        for g in &all {
            for kind in ["", "_stub"] {
                std::fs::write(out_dir.join(format!("solver_{}{kind}.wasm", g.name)), [])
                    .expect("write an empty solver blob");
            }
        }
        std::fs::write(out_dir.join("solver_dylinks.hash"), "no-sundials").ok();
        return;
    }
    // A warning here would ship an omc that looks healthy and refuses `-s=cvode`.
    if let Err(e) = link_solver_dylinks(out_dir, sundials_dir.unwrap(), adapters, &all) {
        panic!(
            "failed to link the solver dylink side modules: {e}\n\
             This build has the wasm solver archives (OMC_SUNDIALS_WASM_DIR is set), so the \
             omc it produces must be able to export a wasm FMU with -s=cvode/ida. Configure \
             with -DRUST_OMC_ENABLE_SUNDIALS=OFF if that is not wanted."
        );
    }
}

/// No `-lc`: that would record a `NEEDED libc.so` the component has no library under
/// that name for, so the archives' libc calls stay `env` imports the FMU linker
/// resolves against the PIC `libc.so` beside them. `--strip-all` drops the archives'
/// DWARF, more bytes than their code; `dylink.0` survives it.
const DYLINK_LINK_ARGS: &[&str] = &[
    "--target=wasm32-wasip1",
    "-fPIC",
    "-nodefaultlibs",
    "-nostartfiles",
    "-Wl,--experimental-pic",
    "-Wl,--shared",
    "-Wl,--no-entry",
    "-Wl,--allow-undefined",
    "-Wl,--strip-all",
];

fn link_solver_dylinks(
    out_dir: &Path,
    sundials_dir: &Path,
    adapters: &[PathBuf; 2],
    all: &[&SolverGroup],
) -> Result<(), String> {
    let adapter = &adapters[0];
    let lib = sundials_dir.join("lib");
    let mut missing: Vec<&str> = all
        .iter()
        .flat_map(|g| g.archives)
        .copied()
        .filter(|l| !lib.join(format!("lib{l}.a")).exists())
        .collect();
    missing.sort();
    missing.dedup();
    if !missing.is_empty() {
        return Err(format!(
            "{} is missing {missing:?}; the wasm solver cross-compile failed (check the \
             rust_sundials_collect CMake target)",
            lib.display()
        ));
    }
    let bytes = std::fs::read(adapter)
        .map_err(|e| format!("read the me_cs adapter {}: {e}", adapter.display()))?;
    if bytes.is_empty() {
        return Err(format!("the me_cs adapter {} is empty", adapter.display()));
    }
    let adapter_imports = imports(&bytes);
    let mut wanted: Vec<String> = adapter_imports
        .iter()
        .filter(|(m, _, kind, _)| m == "env" && *kind == FUNC)
        .map(|(_, f, ..)| f.clone())
        .collect();
    wanted.sort();
    wanted.dedup();
    if !wanted.iter().any(|n| n.starts_with("CVode")) {
        return Err(format!(
            "the me_cs adapter {} imports no CVODE entry point, so it was built without its \
             `sundials` feature and no side module could serve it",
            adapter.display()
        ));
    }
    let owned = |g: &SolverGroup| -> Vec<String> {
        wanted.iter().filter(|n| g.owns.iter().any(|p| n.starts_with(p))).cloned().collect()
    };

    let clang = std::env::var("OMC_WASI_CLANG").unwrap_or_else(|_| "clang".to_owned());
    let builtins = find_wasm_builtins().ok_or("no libclang_rt.builtins-wasm32.a found")?;
    let libc = libc_exports()?;
    let stamp = out_dir.join("solver_dylinks.hash");
    let key = {
        let mut h: u64 = 0xcbf29ce484222325;
        let mut feed = |b: &[u8]| {
            for x in b {
                h ^= *x as u64;
                h = h.wrapping_mul(0x100000001b3);
            }
        };
        feed(archives_key(&lib).as_bytes());
        feed(clang.as_bytes());
        feed(wasm_opt_key().as_bytes());
        for a in DYLINK_LINK_ARGS.iter().copied().chain(wanted.iter().map(|w| w.as_str())) {
            feed(a.as_bytes());
        }
        for g in all {
            feed(g.name.as_bytes());
            for a in g.archives {
                feed(a.as_bytes());
            }
            for o in g.owns {
                feed(o.as_bytes());
            }
        }
        format!("{h:016x}")
    };
    let current = |g: &SolverGroup| {
        ["", "_stub"].iter().all(|k| {
            out_dir
                .join(format!("solver_{}{k}.wasm", g.name))
                .metadata()
                .map(|m| m.len() > 0)
                .unwrap_or(false)
        })
    };
    if all.iter().all(|g| current(g))
        && std::fs::read_to_string(&stamp).ok().as_deref() == Some(key.as_str())
    {
        return Ok(());
    }

    // Pass 1: the leaf groups, whose roots are only what they own.
    let mut base_roots = owned(&BASE_GROUP);
    for g in SOLVER_GROUPS {
        let module = link_group(out_dir, &lib, &clang, &builtins, g, &owned(g))?;
        // They call into `base`, so what they leave open is part of its root set.
        base_roots.extend(
            imports(&module)
                .into_iter()
                .filter(|(m, ..)| m == "env" || m.starts_with("GOT."))
                .map(|(_, f, ..)| f)
                .filter(|f| !f.starts_with("__") && f != "memory" && !libc.contains(f)),
        );
    }
    base_roots.sort();
    base_roots.dedup();
    let base = link_group(out_dir, &lib, &clang, &builtins, &BASE_GROUP, &base_roots)?;

    // `--export-if-defined` skipping a name is what makes the libc and model-kernel
    // imports harmless, and would as quietly drop a solver whose archive went missing
    // or whose `owns` prefix names the wrong group.
    let mut have = exported_names(&base);
    for g in SOLVER_GROUPS {
        have.extend(exported_names(&std::fs::read(group_path(out_dir, g, "")).unwrap_or_default()));
    }
    // Every adapter that imports the solvers, not just the one the roots came from:
    // ME's import set has to stay a subset of me_cs's.
    let prefixes: Vec<&str> = all.iter().flat_map(|g| g.owns).copied().collect();
    for a in adapters {
        let bytes = std::fs::read(a).map_err(|e| format!("read {}: {e}", a.display()))?;
        let dropped: Vec<String> = imports(&bytes)
            .into_iter()
            .filter(|(m, _, kind, _)| m == "env" && *kind == FUNC)
            .map(|(_, f, ..)| f)
            .filter(|f| prefixes.iter().any(|p| f.starts_with(p)) && !have.contains(f))
            .collect();
        if !dropped.is_empty() {
            return Err(format!(
                "no group defines {dropped:?}, which {} imports; the archives in {} are \
                 missing one, or a `SolverGroup::owns` prefix names the wrong group",
                a.display(),
                lib.display()
            ));
        }
    }
    // What `--allow-undefined` let through has to be there at FMU-export time.
    let base_exports = exported_names(&base);
    for g in SOLVER_GROUPS {
        let module = std::fs::read(group_path(out_dir, g, "")).unwrap_or_default();
        let open: Vec<String> = imports(&module)
            .into_iter()
            .filter(|(m, ..)| m == "env" || m.starts_with("GOT."))
            .map(|(_, f, ..)| f)
            .filter(|f| {
                !f.starts_with("__")
                    && f != "memory"
                    && !libc.contains(f)
                    && !base_exports.contains(f)
            })
            .collect();
        if !open.is_empty() {
            return Err(format!("the {} side module needs {open:?}, which neither the base \
                                module nor libc.so exports", g.name));
        }
    }

    // Signatures read off the adapter's own type section.
    let types = func_types_as_c(&bytes);
    let type_of: std::collections::BTreeMap<&str, u32> = adapter_imports
        .iter()
        .filter(|(m, _, kind, _)| m == "env" && *kind == FUNC)
        .map(|(_, f, _, idx)| (f.as_str(), *idx))
        .collect();
    for g in all {
        link_group_stub(out_dir, &clang, &builtins, g, &owned(g), &types, &type_of)?;
    }
    std::fs::write(&stamp, &key).ok();
    Ok(())
}

fn group_path(out_dir: &Path, g: &SolverGroup, kind: &str) -> PathBuf {
    out_dir.join(format!("solver_{}{kind}.wasm", g.name))
}

/// One group from its archives, exporting `roots` plus the `om_have_<name>` marker
/// that tells the FMU's runtime the library is really there.
fn link_group(
    out_dir: &Path,
    lib: &Path,
    clang: &str,
    builtins: &Path,
    g: &SolverGroup,
    roots: &[String],
) -> Result<Vec<u8>, String> {
    let marker = out_dir.join(format!("om_have_{}.c", g.name));
    std::fs::write(&marker, format!("int om_have_{}(void) {{ return 1; }}\n", g.name))
        .map_err(|e| format!("write {}: {e}", marker.display()))?;
    let dest = group_path(out_dir, g, "");
    let mut cmd = Command::new(clang);
    cmd.args(DYLINK_LINK_ARGS).arg(format!("-L{}", lib.display()));
    for a in g.archives {
        cmd.arg(format!("-l{a}"));
    }
    for r in roots {
        cmd.arg(format!("-Wl,--export-if-defined={r}"));
    }
    let status = cmd
        .arg(&marker)
        .arg(format!("-Wl,--export=om_have_{}", g.name))
        .arg(builtins)
        .arg("-o")
        .arg(&dest)
        .status()
        .map_err(|e| format!("spawn {clang}: {e}"))?;
    if !status.success() {
        return Err(format!("{clang} ({} side module) exited with {status}", g.name));
    }
    wasm_opt(&dest);
    std::fs::read(&dest).map_err(|e| format!("read {}: {e}", dest.display()))
}

/// The stand-in for a group an FMU was not given: every entry point it owns, with the
/// adapter's signature and a trap body, and the marker answering 0. A trap is
/// unreachable -- `simflags::check` rejects the solver on that very marker first.
fn link_group_stub(
    out_dir: &Path,
    clang: &str,
    builtins: &Path,
    g: &SolverGroup,
    owns: &[String],
    types: &[(String, Vec<String>)],
    type_of: &std::collections::BTreeMap<&str, u32>,
) -> Result<(), String> {
    let mut src = format!(
        "/* Generated by openmodelica_wasm_jit's build script. */\n\
         int om_have_{}(void) {{ return 0; }}\n",
        g.name
    );
    for f in owns {
        let idx = *type_of.get(f.as_str()).ok_or_else(|| format!("no import type for {f}"))?;
        let (result, params) = types
            .get(idx as usize)
            .ok_or_else(|| format!("{f}: type index {idx} is outside the adapter's type section"))?;
        if result.is_empty() || params.iter().any(|p| p.is_empty()) {
            return Err(format!("{f} has a signature no C declaration can express"));
        }
        let args = if params.is_empty() {
            "void".to_owned()
        } else {
            params
                .iter()
                .enumerate()
                .map(|(i, t)| format!("{t} a{i}"))
                .collect::<Vec<_>>()
                .join(", ")
        };
        src.push_str(&format!("{result} {f}({args}) {{ __builtin_trap(); }}\n"));
    }
    let c = out_dir.join(format!("solver_{}_stub.c", g.name));
    std::fs::write(&c, &src).map_err(|e| format!("write {}: {e}", c.display()))?;
    let dest = group_path(out_dir, g, "_stub");
    let mut cmd = Command::new(clang);
    cmd.args(DYLINK_LINK_ARGS);
    for f in owns.iter().map(|f| f.as_str()).chain([format!("om_have_{}", g.name).as_str()]) {
        cmd.arg(format!("-Wl,--export={f}"));
    }
    let status = cmd
        .arg(&c)
        .arg(builtins)
        .arg("-o")
        .arg(&dest)
        .status()
        .map_err(|e| format!("spawn {clang}: {e}"))?;
    if !status.success() {
        return Err(format!("{clang} ({} stub) exited with {status}", g.name));
    }
    wasm_opt(&dest);
    Ok(())
}

/// What the PIC `libc.so` the FMU linker adds beside the side modules has.
fn libc_exports() -> Result<std::collections::BTreeSet<String>, String> {
    let sysroot = std::env::var("OMC_WASI_PIC_SYSROOT")
        .map_err(|_| "OMC_WASI_PIC_SYSROOT not set (CMake provides it)")?;
    let libc = Path::new(&sysroot).join("lib/wasm32-wasip1/libc.so");
    Ok(exported_names(
        &std::fs::read(&libc).map_err(|e| format!("read {}: {e}", libc.display()))?,
    ))
}

/// An import descriptor kind byte.
const FUNC: u8 = 0x00;

/// `(module, field, kind, typeidx)` per import; `typeidx` only means anything for
/// `FUNC`. Sections are `(id byte, u32 size, payload)`; an import is two names, a
/// kind byte, then that kind's descriptor.
fn imports(module: &[u8]) -> Vec<(String, String, u8, u32)> {
    let mut out = Vec::new();
    sections(module, |id, start| {
        if id != 2 {
            return;
        }
        let mut p = start;
        for _ in 0..leb(module, &mut p) {
            let m = name(module, &mut p);
            let f = name(module, &mut p);
            let kind = *module.get(p).unwrap_or(&0);
            p += 1;
            let mut idx = 0;
            match kind {
                FUNC => idx = leb(module, &mut p),
                0x01 => {
                    p += 1;
                    limits(module, &mut p);
                }
                0x02 => limits(module, &mut p),
                _ => p += 2,
            }
            out.push((m, f, kind, idx));
        }
    });
    out
}

/// Each function type in `module`'s type section as a C `(result, params)`. wasm's
/// numeric types are C's on this ABI, so a stub with the same signature defines the
/// import correctly.
fn func_types_as_c(module: &[u8]) -> Vec<(String, Vec<String>)> {
    fn ctype(b: u8) -> &'static str {
        match b {
            0x7f => "int",
            0x7e => "long long",
            0x7d => "float",
            0x7c => "double",
            _ => "",
        }
    }
    let mut out = Vec::new();
    sections(module, |id, start| {
        if id != 1 {
            return;
        }
        let mut p = start;
        for _ in 0..leb(module, &mut p) {
            // 0x60 is the function-type tag; nothing else appears in these modules.
            let tag = *module.get(p).unwrap_or(&0);
            p += 1;
            if tag != 0x60 {
                out.push((String::new(), Vec::new()));
                continue;
            }
            let mut params = Vec::new();
            for _ in 0..leb(module, &mut p) {
                params.push(ctype(*module.get(p).unwrap_or(&0)).to_owned());
                p += 1;
            }
            let n_res = leb(module, &mut p);
            let result = match n_res {
                0 => "void".to_owned(),
                1 => {
                    let t = ctype(*module.get(p).unwrap_or(&0)).to_owned();
                    p += 1;
                    t
                }
                _ => {
                    for _ in 0..n_res {
                        p += 1;
                    }
                    String::new()
                }
            };
            out.push((result, params));
        }
    });
    out
}

/// The names `module` exports, of every kind.
fn exported_names(module: &[u8]) -> std::collections::BTreeSet<String> {
    let mut out = std::collections::BTreeSet::new();
    sections(module, |id, start| {
        if id != 7 {
            return;
        }
        let mut p = start;
        for _ in 0..leb(module, &mut p) {
            let n = name(module, &mut p);
            p += 1; // kind
            leb(module, &mut p); // index
            out.insert(n);
        }
    });
    out
}

fn sections(module: &[u8], mut f: impl FnMut(u8, usize)) {
    let mut p = 8; // magic + version
    while p + 1 < module.len() {
        let id = module[p];
        p += 1;
        let size = leb(module, &mut p) as usize;
        f(id, p);
        p = (p + size).min(module.len());
    }
}

fn leb(b: &[u8], p: &mut usize) -> u32 {
    let (mut v, mut shift) = (0u32, 0);
    while let Some(&x) = b.get(*p) {
        *p += 1;
        v |= ((x & 0x7f) as u32) << shift;
        if x & 0x80 == 0 {
            break;
        }
        shift += 7;
    }
    v
}

fn name(b: &[u8], p: &mut usize) -> String {
    let n = leb(b, p) as usize;
    let end = (*p + n).min(b.len());
    let s = String::from_utf8_lossy(&b[*p..end]).into_owned();
    *p = end;
    s
}

fn limits(b: &[u8], p: &mut usize) {
    let flags = leb(b, p);
    leb(b, p);
    if flags & 1 != 0 {
        leb(b, p);
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

/// Model Exchange (default features) and the combined me_cs world, which serves
/// Co-Simulation too (its imports are a `co-simulation-fmu`'s exactly, its exports
/// a superset). ME stays separate: it imports only `callbacks`, so an ME-only host
/// that cannot supply `intermediate-update-callbacks` would fail to instantiate a
/// me_cs component -- and only me_cs embeds a driver, so only it asks for SUNDIALS.
const ADAPTER_VARIANTS: &[AdapterVariant] = &[
    // Model Exchange integrates nothing, but its initialisation and residuals run the
    // same nonlinear and linear solvers, and the export hard-codes which ones into the
    // metadata -- so it asks for the libraries too, minus the integrator.
    AdapterVariant {
        name: "me",
        label: "ME",
        cargo_args: &["--no-default-features", "--features", "me,sundials"],
    },
    // One me_cs adapter, with the solver bundle as imports `SOLVER_LIBRARIES` resolves.
    AdapterVariant {
        name: "mecs",
        label: "me_cs",
        cargo_args: &["--no-default-features", "--features", "me,cs,sundials"],
    },
    // The same me_cs adapter with an FMI 3.0 C API instead of the component's WIT
    // exports, for a host that links it as a dylink library: it is then a *fixed*
    // library, compiled once into the on-disk `.cwasm` cache rather than into
    // every model's component.
    AdapterVariant {
        name: "mecs_capi",
        label: "me_cs (C API)",
        cargo_args: &["--no-default-features", "--features", "me,cs,capi"],
    },
];

fn build_fmi3_adapter(crate_dir: &Path, out_dir: &Path, v: &AdapterVariant, sundials: bool) {
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
    let hash = format!("{digest}-{}-{sundials}-{}", v.name, wasm_opt_key());
    if dest.exists()
        && std::fs::metadata(&dest).map(|m| m.len() > 0).unwrap_or(false)
        && std::fs::read_to_string(&stamp).ok().as_deref() == Some(&hash)
    {
        return;
    }

    match build_dylink_adapter(&adapter_dir, out_dir, v, sundials) {
        Ok(produced) => {
            copy(&produced, &dest);
            wasm_opt(&dest);
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
/// precompiled `libstd`/`liballoc` are non-PIC (and `std`, not `core,alloc`,
/// since the runtime it links is a std crate); `--allow-undefined` because
/// `__heap_base`/`__heap_end` become imports the linker supplies;
/// `-Zcodegen-backend=llvm` because the workspace default cranelift cannot target
/// wasm and RUSTFLAGS here replaces the crate's `.cargo/config.toml`; `+simd128`
/// for the faer kernels the dense solve reaches, as in `liblapack.wasm`.
fn build_dylink_adapter(adapter_dir: &Path, out_dir: &Path, v: &AdapterVariant, sundials: bool) -> Result<PathBuf, String> {
    let target = "wasm32-unknown-unknown";
    // Separate target dirs: the worlds differ only by feature, and sharing one
    // would rebuild the crate on every alternation.
    let target_dir = out_dir.join(format!("adapter-dylink-target-{}", v.name));
    let cargo = std::env::var("CARGO").unwrap_or_else(|_| "cargo".to_owned());
    let rustflags = "-Zcodegen-backend=llvm -Crelocation-model=pic \
        -Clink-arg=--experimental-pic -Clink-arg=--shared -Clink-arg=--no-entry \
        -Clink-arg=--allow-undefined -Ctarget-feature=+simd128";
    let mut cmd = Command::new(cargo);
    cmd.current_dir(adapter_dir)
        .args(["build", "-Z", "build-std=std,panic_abort", "--release", "--target", target])
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
///
/// The `Modelica*` entry points are not among them: the side module carries
/// `external_c_callbacks.c`, the same one an FMU links, so a `%g` is interpolated
/// by `vsnprintf` before the host ever sees the message. Only allocation stays
/// host-side (`OM_EXT_HOST_ALLOC`) — the buffer lives in the side module's own
/// memory and the trampoline frees it after copying it out.
const HOST_PROVIDED: &[&str] = &[
    "rt_ext_error",
    "rt_ext_message",
    "rt_ext_warning",
    "ModelicaAllocateString",
    "ModelicaAllocateStringWithErrorReturn",
    "ModelicaInternal_getTime",
    "ModelicaInternal_getpid",
    "usertab",
];

/// `--export-all` keeps older MSL compatibility entry points present, but exports
/// functions only — hence `__stack_pointer`, which the recovery path restores.
const EXTRA_LINK_ARGS: &[&str] = &["-Wl,--export-all", "-Wl,--export=__stack_pointer"];

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
    let callbacks = crate_dir.join("../openmodelica_wasi_libc/external_c_callbacks.c");
    let sources = [
        "ModelicaStandardTables.c", "ModelicaStrings.c", "ModelicaRandom.c",
        "ModelicaIO.c", "ModelicaMatIO.c", "snprintf.c",
        "ModelicaInternal.c", "ModelicaFFT.c",
    ];
    let src_paths: Vec<PathBuf> = sources.iter().map(|s| c_sources.join(s)).collect();

    println!("cargo:rerun-if-changed={}", stubs.display());
    println!("cargo:rerun-if-changed={}", callbacks.display());
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
    let hdf5 = wasm_hdf5();

    let all_srcs: Vec<_> = src_paths.iter().chain(zlib_srcs.iter()).collect();
    let hash = {
        let mut h: u64 = 0xcbf29ce484222325;
        let mut mix = |bytes: &[u8]| for &byte in bytes { h ^= byte as u64; h = h.wrapping_mul(0x100000001b3); };
        for f in all_srcs.iter().copied().chain([&stubs, &callbacks]) {
            if let Ok(b) = std::fs::read(f) { mix(&b); }
        }
        mix(clang.as_bytes());
        mix(sysroot.as_bytes());
        if let Some((_, archive)) = &hdf5 {
            if let Ok(b) = std::fs::read(archive) { mix(&b); }
        }
        for s in HOST_PROVIDED { mix(s.as_bytes()); }
        for s in EXTRA_LINK_ARGS { mix(s.as_bytes()); }
        format!("{h:016x}")
    };
    if dest.exists() && std::fs::metadata(&dest).map(|m| m.len() > 0).unwrap_or(false)
        && std::fs::read_to_string(&stamp).ok().as_deref() == Some(&hash) {
        return;
    }

    // `-mexec-model=reactor`: exports `_initialize` (runs ctors), no `_start`.
    // `-nodefaultlibs` means `-lc` has to be explicit.
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
    // `-D_POSIX_VERSION` as for the dylink build; see `openmodelica_wasi_libc`.
    cmd.args(["--target=wasm32-wasip1", "-O2", "-mexec-model=reactor", "-D_POSIX_VERSION=200809L",
               "-nodefaultlibs", "-DNO_MUTEX", "-DHAVE_ZLIB", "-DOM_EXT_HOST_ALLOC",
               "-Wno-error=implicit-function-declaration"])
        .arg(format!("--sysroot={sysroot}"))
        .arg("-I").arg(&c_sources)
        .arg("-I").arg(&zlib_dir)
        .args(&all_srcs).arg(&stubs).arg(&callbacks)
        .arg("-lc");
    if let Some((include, archive)) = &hdf5 {
        // HDF5's plugin loader's dlopen/dlsym are stubbed in
        // external_c_callbacks.c, so they never reach HOST_PROVIDED.
        cmd.arg("-DHAVE_HDF5=1").arg("-I").arg(include).arg(archive);
    }
    cmd.arg(&builtins)
        .args(EXTRA_LINK_ARGS)
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

/// The HDF5 wasm install tree (`OMC_WASM_HDF5_DIR`, from CMake's
/// rust_hdf5_wasm) that gives ModelicaMatIO its MAT v7.3 support. Absent, v7.3
/// files are rejected at `Mat_Open`.
fn wasm_hdf5() -> Option<(PathBuf, PathBuf)> {
    println!("cargo:rerun-if-env-changed=OMC_WASM_HDF5_DIR");
    let dir = PathBuf::from(std::env::var("OMC_WASM_HDF5_DIR").ok()?);
    let archive = dir.join("lib/libhdf5.a");
    println!("cargo:rerun-if-changed={}", archive.display());
    if !archive.exists() {
        panic!("OMC_WASM_HDF5_DIR={} has no lib/libhdf5.a", dir.display());
    }
    Some((dir.join("include"), archive))
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
/// PRIMME's archive rides in the SUNDIALS hand-off directory; the runtime's
/// `primme` feature is only servable when it is there.
fn has_primme(sundials_dir: Option<&Path>) -> bool {
    sundials_dir.is_some_and(|d| d.join("lib").join("libprimme.a").exists())
}

fn standalone_features(sundials_dir: Option<&Path>) -> String {
    let mut f = "standalone".to_string();
    if has_primme(sundials_dir) {
        f.push_str(",primme");
    }
    f
}

/// Returns `Some((dir, key))` when `OMC_SUNDIALS_WASM_DIR` is set (the key is
/// appended to the runtime stamp so sundials on/off toggles rebuild the blobs).
/// Returns `None` when the env var is absent (sundials feature disabled).
fn sundials_wasm_dir() -> Option<(PathBuf, String)> {
    println!("cargo:rerun-if-env-changed=OMC_SUNDIALS_WASM_DIR");
    let dir: PathBuf = std::env::var("OMC_SUNDIALS_WASM_DIR").ok()?.into();
    // PRIMME arriving or leaving changes the runtime's features, so it belongs in
    // the key too.
    let base = if has_primme(Some(&dir)) { "cmake+primme" } else { "cmake" };
    let key = format!("{base}:{}", archives_key(&dir.join("lib")));
    Some((dir, key))
}

/// The archives the wasip1 runtimes link, as part of the runtime stamp: cargo
/// tracks the crate's sources, not what the linker pulls in. CMake collects them
/// with `copy_if_different`, so an unchanged archive keeps its mtime.
fn archives_key(lib: &Path) -> String {
    let mut archives: Vec<PathBuf> = std::fs::read_dir(lib)
        .into_iter()
        .flatten()
        .flatten()
        .map(|e| e.path())
        .filter(|p| p.extension().is_some_and(|e| e == "a"))
        .collect();
    archives.sort();
    let mut h: u64 = 0xcbf29ce484222325;
    let mut feed = |bytes: &[u8]| {
        for b in bytes {
            h ^= *b as u64;
            h = h.wrapping_mul(0x100000001b3);
        }
    };
    for p in &archives {
        println!("cargo:rerun-if-changed={}", p.display());
        let meta = std::fs::metadata(p).ok();
        let len = meta.as_ref().map_or(0, |m| m.len());
        let mtime = meta
            .and_then(|m| m.modified().ok())
            .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
            .map_or(0, |d| d.as_nanos());
        feed(p.file_name().unwrap_or_default().as_encoded_bytes());
        feed(&len.to_le_bytes());
        feed(&mtime.to_le_bytes());
    }
    format!("{h:016x}")
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
        &["--no-default-features", "--features", &standalone_features(sundials_dir)],
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
    let mut features = if native && !wasmer && !inwasm_driver {
        "host_lin_solve,host_log".to_string()
    } else {
        "session,inwasm_solve,host_log".to_string()
    };
    if has_primme(sundials_dir) {
        features.push_str(",primme");
    }
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
        &["--no-default-features", "--features", &features],
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
        // `build.rs` too: it picks the archives and the cfgs, and is not in `src`.
        for m in ["Cargo.toml", "Cargo.lock", "build.rs"] {
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
