//! Builds the external-"C" artifacts omc carries itself: a `-fPIC` wasi-libc
//! `libc.so` for its own side modules, the ModelicaUtilities.h functions a
//! host-free FMU's libraries call and the dummy `usertab` the MSL's tables import,
//! as PIC dylink side modules, and the vendored `wasi_snapshot_preview1` adapter.
//! The libraries' own modules, and the libc they were built against, come with the
//! libraries, from the package manager.
//!
//! All inputs are provided by CMake via environment variables. This crate does not
//! build wasi-libc itself — the CMake target `rust_wasi_pic_sysroot` handles that
//! before cargo runs.
//!
//! Failure in any step (sysroot missing, external-C clang failure) is a hard error.

use std::path::{Path, PathBuf};
use std::process::Command;

fn main() {
    let crate_dir = PathBuf::from(env("CARGO_MANIFEST_DIR"));
    let out_dir = PathBuf::from(env("OUT_DIR"));

    // Where openmodelica_wasm_jit::blobs reads these from. `links` in Cargo.toml is
    // what makes cargo pass it on, as DEP_OMC_WASI_BLOBS_DIR.
    println!("cargo::metadata=dir={}", out_dir.display());

    let adapter_dest = out_dir.join("wasi_snapshot_preview1.reactor.wasm");
    provide_preview1_adapter(&adapter_dest);

    let libc_dest = out_dir.join("libc_pic.wasm");
    let utilities_dest = out_dir.join("ModelicaUtilities.wasm");
    let usertab_dest = out_dir.join("usertab_dylink.wasm");

    // The CI hand-over: with every side module already built there is nothing
    // here that needs a wasm toolchain or the sysroot.
    if ![&libc_dest, &utilities_dest, &usertab_dest].iter().all(|d| prebuilt_in(d)) {
        // PIC wasi sysroot: provided by CMake's rust_wasi_pic_sysroot target.
        let sysroot = ensure_pic_wasi_sysroot();
        copy(&sysroot.join("lib/wasm32-wasip1/libc.so"), &libc_dest);
        let utilities = build_utilities_dylink(&crate_dir, &out_dir, &sysroot, "wasm32-wasip1")
            .unwrap_or_else(|e| panic!("failed to build the PIC ModelicaUtilities dylink module: {e}"));
        copy(&utilities, &utilities_dest);
        let usertab = build_usertab_dylink(&out_dir, &sysroot, "wasm32-wasip1")
            .unwrap_or_else(|e| panic!("failed to build the PIC usertab dummy dylink module: {e}"));
        copy(&usertab, &usertab_dest);
    }

    let published = [libc_dest.as_path(), utilities_dest.as_path(), usertab_dest.as_path(), adapter_dest.as_path()];
    publish(&published);
}

/// The side modules this script builds are wasm whatever platform omc is being
/// built for, so a multi-stage CI builds them once and hands them over:
/// `OMC_WASM_PREBUILT_OUT` collects them, `OMC_WASM_PREBUILT_IN` takes them --
/// which is what lets a build with no wasm toolchain (the Windows and macOS
/// cross builds) get through this script. The same directory serves
/// `openmodelica_wasm_jit`'s blobs. Trusted, not checked.
fn prebuilt_in(dest: &Path) -> bool {
    println!("cargo:rerun-if-env-changed=OMC_WASM_PREBUILT_IN");
    let Some(dir) = std::env::var_os("OMC_WASM_PREBUILT_IN") else { return false };
    let src = PathBuf::from(dir).join(dest.file_name().expect("a blob has a file name"));
    if !src.is_file() {
        return false;
    }
    copy(&src, dest);
    true
}

/// Copy the finished blobs out of `OUT_DIR`: to `OMC_WASM_PREBUILT_OUT` for a later
/// build's `OMC_WASM_PREBUILT_IN`, and to `OMC_WASM_BLOB_OUT`, which is what the
/// install rule ships (omc reads them from there at run time, not from its binary).
fn publish(blobs: &[&Path]) {
    for var in ["OMC_WASM_PREBUILT_OUT", "OMC_WASM_BLOB_OUT"] {
        println!("cargo:rerun-if-env-changed={var}");
        let Some(dir) = std::env::var_os(var) else { continue };
        let dir = PathBuf::from(dir);
        std::fs::create_dir_all(&dir).expect("create the wasm blob directory");
        for b in blobs {
            copy(b, &dir.join(b.file_name().expect("a blob has a file name")));
        }
    }
}

/// The preview1→preview2 reactor adapter: `OMC_WASI_P1_ADAPTER` from CMake.
fn provide_preview1_adapter(dest: &Path) {
    println!("cargo:rerun-if-env-changed=OMC_WASI_P1_ADAPTER");
    if let Ok(p) = std::env::var("OMC_WASI_P1_ADAPTER") {
        let path = Path::new(&p);
        if path.exists() {
            copy(path, dest);
            return;
        }
    }
    panic!("wasi_snapshot_preview1 adapter not found. Set OMC_WASI_P1_ADAPTER (CMake provides it).");
}

/// PIC wasi sysroot: `OMC_WASI_PIC_SYSROOT` from CMake's rust_wasi_pic_sysroot target.
fn ensure_pic_wasi_sysroot() -> PathBuf {
    println!("cargo:rerun-if-env-changed=OMC_WASI_PIC_SYSROOT");
    let p = std::env::var("OMC_WASI_PIC_SYSROOT")
        .expect("OMC_WASI_PIC_SYSROOT not set — build via CMake which sets it");
    let p = PathBuf::from(p);
    let libc_so = p.join("lib/wasm32-wasip1/libc.so");
    println!("cargo:rerun-if-changed={}", libc_so.display());
    if libc_so.exists() {
        return p;
    }
    panic!("OMC_WASI_PIC_SYSROOT={} has no lib/wasm32-wasip1/libc.so", p.display());
}

/// `external_c_callbacks.c`: the ModelicaUtilities.h functions in the wasm, over
/// the `rt_ext_*` host imports, so a `ModelicaFormatError` is formatted by the
/// guest's own `vsnprintf`.
fn build_utilities_dylink(crate_dir: &Path, out_dir: &Path, sysroot: &Path, triple: &str) -> Result<PathBuf, String> {
    let src = crate_dir.join("external_c_callbacks.c");
    println!("cargo:rerun-if-changed={}", src.display());
    let raw = out_dir.join("ModelicaUtilities_raw.wasm");
    let builtins = find_wasm_builtins().ok_or("no libclang_rt.builtins-wasm32.a found")?;
    let clang = std::env::var("OMC_WASI_CLANG").unwrap_or_else(|_| "clang".to_owned());
    let status = Command::new(&clang)
        .arg(format!("--target={triple}"))
        .arg(format!("--sysroot={}", sysroot.display()))
        .args(["-O2", "-fPIC", "-nodefaultlibs", "-mexec-model=reactor"])
        .arg(&src)
        .args(["-Wl,--experimental-pic", "-Wl,--shared", "-Wl,--no-entry",
               "-Wl,--export-all", "-Wl,--allow-undefined"])
        .arg(&builtins)
        .arg("-o").arg(&raw)
        .status()
        .map_err(|e| format!("spawn {clang}: {e}"))?;
    if !status.success() {
        return Err(format!("clang (ModelicaUtilities dylink) exited with {status}"));
    }
    let bytes = std::fs::read(&raw).map_err(|e| format!("read raw ModelicaUtilities dylink: {e}"))?;
    let out = out_dir.join("ModelicaUtilities_stripped.wasm");
    std::fs::write(&out, strip_wasm_export(&bytes, "_initialize"))
        .map_err(|e| format!("write ModelicaUtilities dylink: {e}"))?;
    Ok(out)
}

/// The C dummy `usertab` on its own, so the FMU link can put it behind a model's own.
fn build_usertab_dylink(out_dir: &Path, sysroot: &Path, triple: &str) -> Result<PathBuf, String> {
    let c_sources = std::env::var("OMC_EXTERNAL_C_SOURCES").ok().map(PathBuf::from)
        .ok_or_else(|| "OMC_EXTERNAL_C_SOURCES not set".to_owned())?;
    let src = c_sources.join("ModelicaStandardTablesUsertab.c");
    if !src.exists() {
        return Err(format!("missing {}", src.display()));
    }
    println!("cargo:rerun-if-changed={}", src.display());

    let raw = out_dir.join("usertab_dylink_raw.wasm");
    let builtins = find_wasm_builtins().ok_or("no libclang_rt.builtins-wasm32.a found")?;
    let clang = std::env::var("OMC_WASI_CLANG").unwrap_or_else(|_| "clang".to_owned());
    let status = Command::new(&clang)
        .arg(format!("--target={triple}"))
        .arg(format!("--sysroot={}", sysroot.display()))
        .args(["-O2", "-fPIC", "-nodefaultlibs", "-mexec-model=reactor", "-DDUMMY_FUNCTION_USERTAB"])
        .arg("-I").arg(&c_sources)
        .arg(&src)
        .args(["-Wl,--experimental-pic", "-Wl,--shared", "-Wl,--no-entry",
               "-Wl,--export=usertab", "-Wl,--allow-undefined"])
        .arg(&builtins)
        .arg("-o").arg(&raw)
        .status()
        .map_err(|e| format!("spawn {clang}: {e}"))?;
    if !status.success() {
        return Err(format!("clang (usertab dylink) exited with {status}"));
    }
    let bytes = std::fs::read(&raw).map_err(|e| format!("read raw usertab dylink: {e}"))?;
    let out = out_dir.join("usertab_dylink_stripped.wasm");
    std::fs::write(&out, strip_wasm_export(&bytes, "_initialize"))
        .map_err(|e| format!("write usertab dylink: {e}"))?;
    Ok(out)
}

/// Remove a single named export from a core wasm module's export section, leaving
/// the referenced function in place. Used to drop the redundant `_initialize`.
fn strip_wasm_export(module: &[u8], name: &str) -> Vec<u8> {
    fn uleb(mut v: u32, out: &mut Vec<u8>) {
        loop {
            let mut b = (v & 0x7f) as u8;
            v >>= 7;
            if v != 0 { b |= 0x80; }
            out.push(b);
            if v == 0 { break; }
        }
    }
    fn read_uleb(b: &[u8], i: &mut usize) -> u32 {
        let (mut r, mut s) = (0u32, 0u32);
        loop {
            let x = b[*i]; *i += 1;
            r |= ((x & 0x7f) as u32) << s;
            if x & 0x80 == 0 { break; }
            s += 7;
        }
        r
    }
    let mut out = Vec::with_capacity(module.len());
    out.extend_from_slice(&module[..8]);
    let mut i = 8;
    while i < module.len() {
        let id = module[i]; i += 1;
        let mut hdr = i;
        let size = read_uleb(module, &mut hdr) as usize;
        let body = &module[hdr..hdr + size];
        i = hdr + size;
        if id != 7 {
            out.push(id);
            uleb(size as u32, &mut out);
            out.extend_from_slice(body);
            continue;
        }
        let mut j = 0;
        let count = read_uleb(body, &mut j);
        let mut kept: Vec<(&[u8], u8, u32)> = Vec::new();
        for _ in 0..count {
            let nl = read_uleb(body, &mut j) as usize;
            let nm = &body[j..j + nl]; j += nl;
            let kind = body[j]; j += 1;
            let idx = read_uleb(body, &mut j);
            if nm != name.as_bytes() {
                kept.push((nm, kind, idx));
            }
        }
        let mut nb = Vec::new();
        uleb(kept.len() as u32, &mut nb);
        for (nm, kind, idx) in kept {
            uleb(nm.len() as u32, &mut nb);
            nb.extend_from_slice(nm);
            nb.push(kind);
            uleb(idx, &mut nb);
        }
        out.push(id);
        uleb(nb.len() as u32, &mut out);
        out.extend_from_slice(&nb);
    }
    out
}

fn find_wasm_builtins() -> Option<PathBuf> {
    if let Ok(p) = std::env::var("OMC_WASM_BUILTINS") {
        let p = PathBuf::from(p);
        if p.exists() { return Some(p); }
    }
    let out = Command::new(std::env::var("OMC_WASI_CLANG").unwrap_or_else(|_| "clang".to_owned()))
        .arg("-print-resource-dir").output().ok()?;
    let dir = PathBuf::from(String::from_utf8(out.stdout).ok()?.trim());
    let cand = dir.join("lib/wasi/libclang_rt.builtins-wasm32.a");
    cand.exists().then_some(cand)
}

fn copy(from: &Path, to: &Path) {
    std::fs::copy(from, to)
        .unwrap_or_else(|e| panic!("copy {} -> {}: {e}", from.display(), to.display()));
}

fn env(key: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| panic!("{key} not set"))
}
