//! Builds the external-"C" artifacts a host-free wasm FMU links in, embedded by
//! `src/lib.rs`: a `-fPIC` wasi-libc `libc.so`, ModelicaExternalC as a PIC dylink
//! side module, and the vendored `wasi_snapshot_preview1` adapter. Debian's
//! wasi-libc is non-PIC, so a `-fPIC` one (wasi-sdk-32, `BUILD_SHARED=ON`) is built
//! here and ModelicaExternalC compiled against it. Best-effort: empty placeholders
//! when the toolchain is unavailable, and the consumer then reports external "C"
//! in wasm FMUs as unsupported.

use std::path::{Path, PathBuf};
use std::process::Command;

fn main() {
    let crate_dir = PathBuf::from(env("CARGO_MANIFEST_DIR"));
    let out_dir = PathBuf::from(env("OUT_DIR"));

    provide_preview1_adapter(&out_dir.join("wasi_snapshot_preview1.reactor.wasm"));

    let mec_dest = out_dir.join("modelicaexternalc_dylink.wasm");
    let libc_dest = out_dir.join("libc_pic.wasm");

    let Some(sysroot) = ensure_pic_wasi_sysroot(&out_dir) else {
        placeholder(&mec_dest);
        placeholder(&libc_dest);
        return;
    };
    let triple = "wasm32-wasip1";
    let libc_so = sysroot.join("lib").join(triple).join("libc.so");
    if !libc_so.exists() {
        println!("cargo:warning=PIC wasi sysroot has no {}; external \"C\" in wasm FMUs disabled", libc_so.display());
        placeholder(&mec_dest);
        placeholder(&libc_dest);
        return;
    }
    copy(&libc_so, &libc_dest);

    match build_external_c_dylink(&crate_dir, &out_dir, &sysroot, triple) {
        Ok(m) => copy(&m, &mec_dest),
        Err(e) => {
            println!("cargo:warning=could not build the PIC ModelicaExternalC dylink module ({e}); \
                      external \"C\" in wasm FMUs disabled");
            placeholder(&mec_dest);
            placeholder(&libc_dest);
        }
    }
}

const WASI_P1_ADAPTER_URL: &str =
    "https://github.com/bytecodealliance/wasmtime/releases/download/v27.0.0/wasi_snapshot_preview1.reactor.wasm";

/// The preview1→preview2 reactor adapter: `OMC_WASI_P1_ADAPTER` (CMake downloads it),
/// else a cached curl download for a raw cargo build, else a placeholder.
fn provide_preview1_adapter(dest: &Path) {
    println!("cargo:rerun-if-env-changed=OMC_WASI_P1_ADAPTER");
    if let Ok(p) = std::env::var("OMC_WASI_P1_ADAPTER") {
        if Path::new(&p).exists() {
            copy(Path::new(&p), dest);
            return;
        }
    }
    let cached = dest.with_extension("dl");
    if !cached.exists() {
        let ok = Command::new("curl")
            .args(["-sSfL", "-o"]).arg(&cached).arg(WASI_P1_ADAPTER_URL)
            .status().map(|s| s.success()).unwrap_or(false);
        if !ok {
            std::fs::remove_file(&cached).ok();
        }
    }
    if cached.exists() { copy(&cached, dest); } else { placeholder(dest); }
}

/// A `-fPIC` wasi-libc sysroot: `OMC_WASI_PIC_SYSROOT` if set, else built + cached.
fn ensure_pic_wasi_sysroot(out_dir: &Path) -> Option<PathBuf> {
    println!("cargo:rerun-if-env-changed=OMC_WASI_PIC_SYSROOT");
    if let Ok(p) = std::env::var("OMC_WASI_PIC_SYSROOT") {
        let p = PathBuf::from(p);
        if p.join("lib/wasm32-wasip1/libc.so").exists() {
            return Some(p);
        }
        println!("cargo:warning=OMC_WASI_PIC_SYSROOT={} has no lib/wasm32-wasip1/libc.so", p.display());
    }
    let sysroot = out_dir.join("wasi-pic-sysroot");
    if sysroot.join("lib/wasm32-wasip1/libc.so").exists() {
        return Some(sysroot);
    }
    match build_pic_wasi_libc(out_dir, &sysroot) {
        Ok(()) => Some(sysroot),
        Err(e) => {
            println!("cargo:warning=could not build a PIC wasi-libc ({e}); set OMC_WASI_PIC_SYSROOT \
                      to a prebuilt sysroot to enable external \"C\" in wasm FMUs");
            None
        }
    }
}

/// Build a PIC wasi-libc sysroot from `OMC_WASI_LIBC_SRC` (CMake provides it; a raw
/// `cargo build` falls back to a git clone). The non-obvious flags: `BUILD_SHARED=ON`
/// for the PIC `libc.so`; `CMAKE_LINK_DEPENDS_USE_LINKER=OFF` (wasm-ld rejects the
/// `--dependency-file` CMake would pass); `CMAKE_AR=llvm-ar` (GNU `ar` can't archive
/// wasm).
fn build_pic_wasi_libc(out_dir: &Path, sysroot_out: &Path) -> Result<(), String> {
    println!("cargo:rerun-if-env-changed=OMC_WASI_LIBC_SRC");
    let src = match std::env::var("OMC_WASI_LIBC_SRC") {
        Ok(p) => PathBuf::from(p),
        Err(_) => {
            let src = out_dir.join("wasi-libc-src");
            if !src.join("CMakeLists.txt").exists() {
                std::fs::remove_dir_all(&src).ok();
                run("git", &[
                    "clone", "--depth", "1", "--branch", "wasi-sdk-32",
                    "https://github.com/WebAssembly/wasi-libc.git",
                    &src.to_string_lossy(),
                ])?;
            }
            src
        }
    };
    if !src.join("CMakeLists.txt").exists() {
        return Err(format!("wasi-libc source at {} has no CMakeLists.txt", src.display()));
    }
    let build = out_dir.join("wasi-libc-build");
    // Start from a clean build dir so a stale CMakeCache (e.g. a prior configure that
    // picked GNU `ar`) can't defeat the flags below.
    std::fs::remove_dir_all(&build).ok();
    let builtins = find_wasm_builtins().ok_or("no libclang_rt.builtins-wasm32.a found")?;
    let (llvm_ar, llvm_ranlib) = find_llvm_ar_ranlib().ok_or("no llvm-ar found (need LLVM binutils)")?;
    run("cmake", &[
        "-S", &src.to_string_lossy(), "-B", &build.to_string_lossy(),
        "-DCMAKE_C_COMPILER=clang", "-DTARGET_TRIPLE=wasm32-wasip1",
        "-DBUILD_SHARED=ON", "-DBUILD_TESTS=OFF",
        "-DCMAKE_LINK_DEPENDS_USE_LINKER=OFF",
        &format!("-DCMAKE_AR={}", llvm_ar.display()),
        &format!("-DCMAKE_RANLIB={}", llvm_ranlib.display()),
        &format!("-DBUILTINS_LIB={}", builtins.display()),
    ])?;
    run("cmake", &["--build", &build.to_string_lossy(), "-j", &num_jobs()])?;
    let built = build.join("sysroot");
    if !built.join("lib/wasm32-wasip1/libc.so").exists() {
        return Err("wasi-libc build produced no libc.so".into());
    }
    std::fs::remove_dir_all(sysroot_out).ok();
    copy_dir(&built, sysroot_out).map_err(|e| format!("copy sysroot: {e}"))?;
    Ok(())
}

/// Compile ModelicaExternalC (+ `DummyUsertab`, `external_c_callbacks.c` for the
/// `env.Modelica*` callbacks, `external_c_stubs.c` for libc gaps) to a PIC dylink
/// side module, then strip its `_initialize` export: reactor mode emits both
/// `_initialize` and `__wasm_call_ctors`, and `wit_component::Linker` rejects a
/// library exporting both — keep the dylink-standard `__wasm_call_ctors`.
fn build_external_c_dylink(crate_dir: &Path, out_dir: &Path, sysroot: &Path, triple: &str) -> Result<PathBuf, String> {
    println!("cargo:rerun-if-env-changed=OMC_EXTERNAL_C_SOURCES");
    let c_sources = std::env::var("OMC_EXTERNAL_C_SOURCES").ok().map(PathBuf::from).or_else(|| {
        // From OpenModelica.rs/openmodelica_wasi_libc up to OMCompiler, then down.
        crate_dir.parent().and_then(Path::parent).and_then(Path::parent)
            .map(|omc| omc.join("SimulationRuntime/ModelicaExternalC/C-Sources"))
    }).ok_or("no ModelicaExternalC C-Sources dir")?;
    let names = [
        "ModelicaStandardTables.c", "ModelicaStrings.c", "ModelicaRandom.c",
        "ModelicaIO.c", "ModelicaMatIO.c", "snprintf.c",
        "ModelicaInternal.c", "ModelicaFFT.c", "ModelicaStandardTablesDummyUsertab.c",
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
        .args(["-O2", "-fPIC", "-nodefaultlibs", "-mexec-model=reactor",
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

/// Locate `llvm-ar` + `llvm-ranlib` — unversioned, else `-<N>` from clang's major
/// (Ubuntu ships only `llvm-ar-<N>`).
fn find_llvm_ar_ranlib() -> Option<(PathBuf, PathBuf)> {
    let clang = std::env::var("OMC_WASI_CLANG").unwrap_or_else(|_| "clang".to_owned());
    let mut stems = vec![String::new()];
    if let Ok(out) = Command::new(&clang).arg("-dumpversion").output() {
        if let Ok(v) = String::from_utf8(out.stdout) {
            if let Some(major) = v.trim().split('.').next() {
                stems.push(format!("-{major}"));
            }
        }
    }
    for stem in &stems {
        if let (Some(ar), Some(ranlib)) =
            (which(&format!("llvm-ar{stem}")), which(&format!("llvm-ranlib{stem}")))
        {
            return Some((ar, ranlib));
        }
    }
    None
}

/// First match for `name` on `PATH` (a minimal `which`, to avoid a dep).
fn which(name: &str) -> Option<PathBuf> {
    std::env::var_os("PATH").and_then(|paths| {
        std::env::split_paths(&paths).map(|d| d.join(name)).find(|p| p.is_file())
    })
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

fn run(cmd: &str, args: &[&str]) -> Result<(), String> {
    let status = Command::new(cmd).args(args).status()
        .map_err(|e| format!("spawn {cmd}: {e}"))?;
    if status.success() { Ok(()) } else { Err(format!("{cmd} exited with {status}")) }
}

fn num_jobs() -> String {
    std::thread::available_parallelism().map(|n| n.get()).unwrap_or(4).to_string()
}

fn copy_dir(from: &Path, to: &Path) -> std::io::Result<()> {
    std::fs::create_dir_all(to)?;
    for e in std::fs::read_dir(from)? {
        let e = e?;
        let (src, dst) = (e.path(), to.join(e.file_name()));
        if e.file_type()?.is_dir() {
            copy_dir(&src, &dst)?;
        } else {
            std::fs::copy(&src, &dst)?;
        }
    }
    Ok(())
}

/// Write an empty artifact so `include_bytes!` still compiles; the consumer treats
/// a zero-length module as "external \"C\" in wasm FMUs unavailable".
fn placeholder(dest: &Path) {
    if !dest.exists() || std::fs::metadata(dest).map(|m| m.len() > 0).unwrap_or(true) {
        std::fs::write(dest, []).ok();
    }
}

fn copy(from: &Path, to: &Path) {
    std::fs::copy(from, to)
        .unwrap_or_else(|e| panic!("copy {} -> {}: {e}", from.display(), to.display()));
}

fn env(key: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| panic!("{key} not set"))
}
