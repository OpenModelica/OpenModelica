//! Builds the external-"C" artifacts a host-free wasm FMU links in, embedded by
//! `src/lib.rs`: a `-fPIC` wasi-libc `libc.so`, ModelicaExternalC as a PIC dylink
//! side module, and the vendored `wasi_snapshot_preview1` adapter.
//!
//! All inputs are provided by CMake via environment variables. This crate does not
//! build wasi-libc itself — the CMake target `rust_wasi_pic_sysroot` handles that
//! before cargo runs.
//!
//! Failure in any step (sysroot missing, external-C clang failure) is a hard error.

use std::path::{Path, PathBuf};
use std::process::Command;

/// What wasi-libc's `<unistd.h>` says, given to the ModelicaExternalC sources
/// directly: they reach that header only for `__unix__`/`__linux__`/`__APPLE_CC__`,
/// so on wasm they derive no `_POSIX_` and give up on functions wasi-libc has.
const POSIX_VERSION: &str = "-D_POSIX_VERSION=200809L";

fn main() {
    let crate_dir = PathBuf::from(env("CARGO_MANIFEST_DIR"));
    let out_dir = PathBuf::from(env("OUT_DIR"));

    provide_preview1_adapter(&out_dir.join("wasi_snapshot_preview1.reactor.wasm"));

    let mec_dest = out_dir.join("modelicaexternalc_dylink.wasm");
    let libc_dest = out_dir.join("libc_pic.wasm");

    // PIC wasi sysroot: provided by CMake's rust_wasi_pic_sysroot target.
    let sysroot = ensure_pic_wasi_sysroot();
    let triple = "wasm32-wasip1";
    let libc_so = sysroot.join("lib").join(triple).join("libc.so");
    if !libc_so.exists() {
        panic!("PIC wasi sysroot {} has no {}; external \"C\" in wasm FMUs requires libc.so",
               sysroot.display(), libc_so.display());
    }
    copy(&libc_so, &libc_dest);

    // ModelicaExternalC dylink: mandatory for FMI wasm FMU export.
    let module = build_external_c_dylink(&crate_dir, &out_dir, &sysroot, triple)
        .unwrap_or_else(|e| panic!("failed to build the PIC ModelicaExternalC dylink module: {e}"));
    copy(&module, &mec_dest);

    let usertab = build_usertab_dylink(&out_dir, &sysroot, triple)
        .unwrap_or_else(|e| panic!("failed to build the PIC usertab dummy dylink module: {e}"));
    copy(&usertab, &out_dir.join("usertab_dylink.wasm"));

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

/// Compile ModelicaExternalC (+ `external_c_callbacks.c`,
/// `external_c_stubs.c`) to a PIC dylink side module, then strip its
/// `_initialize` export: reactor mode emits both `_initialize` and
/// `__wasm_call_ctors`, and `wit_component::Linker` rejects a library
/// exporting both — keep the dylink-standard `__wasm_call_ctors`.
fn build_external_c_dylink(crate_dir: &Path, out_dir: &Path, sysroot: &Path, triple: &str) -> Result<PathBuf, String> {
    println!("cargo:rerun-if-env-changed=OMC_EXTERNAL_C_SOURCES");
    let c_sources = std::env::var("OMC_EXTERNAL_C_SOURCES").ok().map(PathBuf::from).ok_or_else(|| {
        "OMC_EXTERNAL_C_SOURCES not set".to_owned()
    })?;
    // No usertab source, so it stays an `env.usertab` import the FMU link resolves
    // against the model's own libraries first.
    let names = [
        "ModelicaStandardTables.c", "ModelicaStrings.c", "ModelicaRandom.c",
        "ModelicaIO.c", "ModelicaMatIO.c", "snprintf.c",
        "ModelicaInternal.c", "ModelicaFFT.c",
    ];
    let mut srcs: Vec<PathBuf> = names.iter().map(|n| c_sources.join(n)).collect();
    if let Some(missing) = srcs.iter().find(|p| !p.exists()) {
        return Err(format!("missing {}", missing.display()));
    }
    let zlib_dir = c_sources.join("zlib");
    let mut zlib = collect_c_files(&zlib_dir);
    zlib.sort();
    srcs.extend(zlib);
    let stubs = crate_dir.join("external_c_stubs.c");
    let callbacks = crate_dir.join("external_c_callbacks.c");
    println!("cargo:rerun-if-changed={}", stubs.display());
    println!("cargo:rerun-if-changed={}", callbacks.display());
    for s in &srcs {
        println!("cargo:rerun-if-changed={}", s.display());
    }

    let raw = out_dir.join("modelicaexternalc_dylink_raw.wasm");
    let builtins = find_wasm_builtins().ok_or("no libclang_rt.builtins-wasm32.a found")?;
    let clang = std::env::var("OMC_WASI_CLANG").unwrap_or_else(|_| "clang".to_owned());
    let status = Command::new(&clang)
        .arg(format!("--target={triple}"))
        .arg(format!("--sysroot={}", sysroot.display()))
        .args(["-O2", "-fPIC", "-nodefaultlibs", "-mexec-model=reactor", POSIX_VERSION,
               "-DNO_MUTEX", "-DHAVE_ZLIB", "-Wno-error=implicit-function-declaration"])
        .arg("-I").arg(&c_sources)
        .arg("-I").arg(&zlib_dir)
        .args(&srcs).arg(&stubs).arg(&callbacks)
        .args(["-Wl,--experimental-pic", "-Wl,--shared", "-Wl,--no-entry",
               "-Wl,--export-all", "-Wl,--allow-undefined"])
        .arg(&builtins)
        .arg("-o").arg(&raw)
        .status()
        .map_err(|e| format!("spawn {clang}: {e}"))?;
    if !status.success() {
        return Err(format!("clang (dylink) exited with {status}"));
    }
    let bytes = std::fs::read(&raw).map_err(|e| format!("read raw dylink: {e}"))?;
    let stripped = strip_wasm_export(&bytes, "_initialize");
    let out = out_dir.join("modelicaexternalc_dylink_stripped.wasm");
    std::fs::write(&out, &stripped).map_err(|e| format!("write dylink: {e}"))?;
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

fn collect_c_files(dir: &Path) -> Vec<PathBuf> {
    let Ok(rd) = std::fs::read_dir(dir) else { return Vec::new() };
    rd.flatten().map(|e| e.path())
        .filter(|p| p.extension().map(|x| x == "c").unwrap_or(false))
        .collect()
}

fn copy(from: &Path, to: &Path) {
    std::fs::copy(from, to)
        .unwrap_or_else(|e| panic!("copy {} -> {}: {e}", from.display(), to.display()));
}

fn env(key: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| panic!("{key} not set"))
}
