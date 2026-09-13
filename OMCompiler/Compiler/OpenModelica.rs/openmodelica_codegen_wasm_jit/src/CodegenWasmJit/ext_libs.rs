//! The model's own `external "C"` libraries: resolving `Library`/`Include`
//! annotations, compiling include sources, dylink needs, search paths.

use super::*;

/// What the `Library` annotations resolved to. `SimCodeFunctionUtil` emits each
/// one twice: the wasm module name, then the host linker spec.
#[derive(Default)]
pub(crate) struct ExtLibraries {
    pub wasm: Vec<ExtLibrary>,
    /// In link order, for a native host to fall back to.
    pub native: Vec<String>,
    /// The system libraries among them: named by soname, with no file behind them
    /// that an export could ship. Also in `native`/`fallback`, which only dlopen.
    pub native_system: Vec<String>,
    /// The platform LAPACK/BLAS, searched after the process image.
    pub fallback: Vec<String>,
    /// The static archives and object files among them, likewise in link order.
    pub archives: Vec<String>,
    /// `#include` lines for the C sources a `Library` named, which the C target
    /// hands to the compiler rather than the linker.
    pub sources: Vec<String>,
}

/// Resolve the `Library` annotations against the library directories. A name that
/// resolves to nothing is reported here, not later as an unresolvable `ext.<fn>`
/// import. `fortran`: a FORTRAN 77 import adds the platform LAPACK/BLAS
/// (`Library="lapack"` names nothing; the C runtime always links them).
pub(crate) fn resolve_ext_libraries(
    mp: &SimCodeFunction::MakefileParams,
    fortran: bool,
    notes: &mut Vec<String>,
) -> Result<ExtLibraries> {
    let mut dirs: Vec<String> = vec![String::new()]; // relative to the working directory
    for d in lst(&mp.libPaths) {
        dirs.push(format!("{d}/"));
    }
    for lib in lst(&mp.libs) {
        if let Some(d) = lib.strip_prefix("-L") {
            dirs.push(format!("{}/", d.trim_matches('"')));
        }
    }
    // The rest of the `LDFLAGS=` line CodegenC.tpl writes. `ffi/` comes first: it
    // holds the shared build of libraries the lib dir ships only as archives.
    dirs.push(format!("{}/lib/{}/omc/ffi/", mp.omhome, openmodelica_util::Autoconf::triple));
    dirs.push(format!("{}/lib/{}/omc/", mp.omhome, openmodelica_util::Autoconf::triple));
    dirs.push(format!("{}/lib/", mp.omhome));
    for d in ld_search_dirs(&mp.ldflags) {
        dirs.push(format!("{d}/"));
    }
    let mut out = ExtLibraries::default();
    let mut seen: HashSet<String> = HashSet::new();
    // A `Library` yields `<name>.wasm` and the `-l<name>` a native host falls back
    // to, both naming the same file. Placing one twice re-runs its `_initialize`.
    let mut placed: HashSet<String> = HashSet::new();
    for lib in lst(&mp.libs) {
        let lib = lib.to_string();
        if !seen.insert(lib.clone()) {
            continue;
        }
        if !lib.ends_with(".wasm") {
            // A wasm build installed beside the native one: its functions bind
            // wasm->wasm, where the native one costs a host trampoline per call.
            // Both are kept — the `Include` wrappers over the library are served by
            // the host, and those link against the platform build.
            let mut have_wasm = false;
            if let Some((path, bytes)) = find_wasm_library(&lib, &dirs) {
                have_wasm = true;
                if placed.insert(path.clone()) {
                    out.wasm.push(ExtLibrary { name: path, bytes, fixed: true });
                }
            }
            if let Some(path) = find_source_library(&lib, &dirs) {
                out.sources.push(format!("#include \"{}\"", path.replace('\\', "/")));
            } else {
                match find_native_library(&lib, &dirs) {
                    Some(NativeLib::Shared(path)) => out.native.push(path),
                    Some(NativeLib::Archive(path)) => out.archives.push(path),
                    // A soname no file backs is the platform's to find. Not worth
                    // asking for when the module is already here.
                    Some(NativeLib::System(soname)) if !have_wasm => {
                        out.native.push(soname.clone());
                        out.native_system.push(soname);
                    }
                    _ => (),
                }
            }
            continue;
        }
        let Some((path, bytes)) = find_ext_library(&lib, &dirs) else {
            notes.push(format!(
                "`{lib}` was not found (looked in {}); a wasm target loads a prebuilt shared \
                 library, built with `clang --target=wasm32-wasip1 -fPIC -shared`",
                dirs.iter().map(|d| if d.is_empty() { "." } else { d.trim_end_matches('/') })
                    .collect::<Vec<_>>().join(", ")
            ));
            continue;
        };
        if placed.insert(path.clone()) {
            out.wasm.push(ExtLibrary { name: path, bytes, fixed: true });
        }
    }
    if fortran {
        for lib in ["-llapack", "-lblas"] {
            if !seen.insert(lib.to_string()) {
                continue;
            }
            match find_native_library(lib, &dirs) {
                Some(NativeLib::Shared(path)) => out.fallback.push(path),
                Some(NativeLib::System(soname)) => {
                    out.fallback.push(soname.clone());
                    out.native_system.push(soname);
                }
                _ => (),
            }
        }
    }
    Ok(out)
}

/// Compile the model's `Include` annotations into a wasm library: C *source* has no
/// `Library` to load. Native only; the browser omc has no compiler. A failure is a
/// note, not an error: only a symbol nothing defines is fatal.
#[cfg(not(target_arch = "wasm32"))]
pub(crate) fn compile_include_library(
    prefix: &str,
    includes: &[String],
    include_dirs: &[String],
    cflags: &str,
    missing: &[ExtCallSig],
    notes: &mut Vec<String>,
) -> Result<Option<ExtLibrary>> {
    if includes.is_empty() {
        return Ok(None);
    }
    let wrappers = openmodelica_wasm_jit::model::ext_wrappers(missing);
    match compile_include_tu(prefix, includes, include_dirs, cflags, &wrappers, notes)? {
        // Keep why they did not compile: it explains a symbol still missing.
        None if !wrappers.is_empty() => compile_include_tu(prefix, includes, include_dirs, cflags, "", notes),
        r => Ok(r),
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn compile_include_tu(
    prefix: &str,
    includes: &[String],
    include_dirs: &[String],
    cflags: &str,
    wrappers: &str,
    notes: &mut Vec<String>,
) -> Result<Option<ExtLibrary>> {
    use std::process::Command;
    let sysroot = wasi_sysroot();
    let clang = std::env::var("OMC_WASI_CLANG").unwrap_or_else(|_| "clang".to_owned());
    let dir = std::env::temp_dir().join(format!("om-wasm-include-{}-{prefix}", std::process::id()));
    std::fs::create_dir_all(&dir).map_err(|_| "CodegenWasmJit: cannot create a temporary directory")?;
    let tu = dir.join(format!("{prefix}_includes.c"));
    let out = dir.join(format!("{prefix}_includes.wasm"));
    let preamble = openmodelica_wasm_jit::model::INCLUDE_PREAMBLE;
    std::fs::write(&tu, [preamble, &includes.join("\n"), "\n", wrappers].concat())
        .map_err(|_| "CodegenWasmJit: cannot write the external \"C\" translation unit")?;

    let mut cmd = Command::new(&clang);
    cmd.args(["--target=wasm32-wasip1", "-O1", "-fPIC", "-shared", "-nodefaultlibs"])
        .arg(format!("--sysroot={}", sysroot.display()))
        .args(["-Wl,--export-all", "-Wl,--allow-undefined"]);
    // Only the preprocessor part of `--cflags`: the rest is host code generation.
    cmd.args(openmodelica_wasm_jit::model::cflags_cpp_args(cflags));
    // Compiled in a temporary directory, so `#include "x.h"` needs the model's own.
    if let Ok(cwd) = std::env::current_dir() {
        cmd.arg("-I").arg(cwd);
    }
    for dir in openmodelica_wasm_jit::model::omc_c_include_dirs() {
        cmd.arg("-I").arg(dir);
    }
    // `IncludeDirectory` annotations, already `-I"..."` strings.
    for inc in include_dirs {
        cmd.arg(inc.trim_matches('"'));
    }
    cmd.arg("-o").arg(&out).arg(&tu);
    if let Some(builtins) = wasm_builtins(&sysroot) {
        cmd.arg(builtins);
    }
    let output = match cmd.output() {
        Ok(o) => o,
        Err(e) => {
            notes.push(format!("`{clang}` could not be run to compile the `Include` C sources: {e}"));
            return Ok(None);
        }
    };
    if !output.status.success() {
        notes.push(format!(
            "the `Include` C sources did not compile for the wasm target:\n{}\n{}",
            openmodelica_wasm_jit::model::command_line(&cmd),
            String::from_utf8_lossy(&output.stderr)
        ));
        return Ok(None);
    }
    let bytes = std::fs::read(&out).map_err(|_| "CodegenWasmJit: cannot read the compiled include library")?;
    let _ = std::fs::remove_dir_all(&dir);
    Ok(Some(ExtLibrary { name: format!("{prefix}_includes.wasm"), bytes, fixed: false }))
}

#[cfg(target_arch = "wasm32")]
pub(crate) fn compile_include_library(
    _prefix: &str,
    includes: &[String],
    _include_dirs: &[String],
    _cflags: &str,
    _missing: &[ExtCallSig],
    notes: &mut Vec<String>,
) -> Result<Option<ExtLibrary>> {
    if includes.is_empty() {
        return Ok(None);
    }
    notes.push(
        "the implementation comes from an `Include` annotation with C source, which has to be \
         compiled — the browser omc has no compiler. Provide it as a `Library` built with \
         `clang --target=wasm32-wasip1 -fPIC -shared`"
            .to_string(),
    );
    Ok(None)
}

/// The sysroot omc ships, unless pointed elsewhere.
#[cfg(not(target_arch = "wasm32"))]
fn wasi_sysroot() -> std::path::PathBuf {
    if let Ok(p) = std::env::var("OMC_WASI_SYSROOT") {
        return std::path::PathBuf::from(p);
    }
    let home = openmodelica_util::Settings::getInstallationDirectoryPath()
        .map(|p| p.to_string())
        .unwrap_or_default();
    std::path::PathBuf::from(home).join("lib/wasm32-wasip1/omc/sysroot")
}

/// The shipped sysroot carries a copy; otherwise probe clang, whose 21 driver
/// looks under a per-triple directory while Debian still uses `lib/wasi`.
#[cfg(not(target_arch = "wasm32"))]
fn wasm_builtins(sysroot: &std::path::Path) -> Option<std::path::PathBuf> {
    let shipped = sysroot.join("lib/wasm32-wasip1/libclang_rt.builtins-wasm32.a");
    if shipped.exists() {
        return Some(shipped);
    }
    let out = std::process::Command::new(std::env::var("OMC_WASI_CLANG").unwrap_or_else(|_| "clang".to_owned()))
        .arg("-print-resource-dir")
        .output()
        .ok()?;
    let res = std::path::PathBuf::from(String::from_utf8_lossy(&out.stdout).trim().to_string());
    [
        res.join("lib/wasm32-unknown-wasip1/libclang_rt.builtins.a"),
        res.join("lib/wasi/libclang_rt.builtins-wasm32.a"),
    ]
    .into_iter()
    .find(|p| p.exists())
}

/// Whether the `Include` sources must become a wasm library even with nothing
/// missing from the `ext` imports: ModelicaExternalC calls C's overridable
/// `usertab` hook from inside the wasm, so no `ext` import names it and only the
/// sources say whether the model overrides the erroring default.
pub(crate) fn include_overrides_builtin(sources: &[String]) -> bool {
    sources.iter().any(|s| s.contains("usertab"))
}

/// The `external "C"` functions neither `libs` nor the libraries every run can
/// load (libc, ModelicaExternalC, LAPACK) export — what an `Include` still has to
/// provide.
pub(crate) fn missing_ext_symbols(ext_imports: &[ExtCallSig], libs: &[ExtLibrary]) -> Vec<ExtCallSig> {
    let mut defined: HashSet<&str> = HashSet::new();
    for bytes in libs.iter().map(|l| &l.bytes[..]).chain([LIBC_PIC(), EXTERNAL_C_DYLINK(), LAPACK_DYLINK()]) {
        defined.extend(wasm_exports(bytes));
    }
    ext_imports.iter().filter(|s| !defined.contains(s.name.as_str())).cloned().collect()
}

/// What a dylink library needs from outside: the functions it calls (`env`) and
/// the ones whose address it takes (`GOT.func`).
pub(super) fn dylink_needs(bytes: &[u8]) -> Vec<String> {
    use wasmparser::{Imports, TypeRef};
    let mut out = Vec::new();
    let mut add = |module: &str, name: &str, is_func: bool| {
        if (module == "env" && is_func) || module == "GOT.func" {
            out.push(name.to_string());
        }
    };
    for payload in wasmparser::Parser::new(0).parse_all(bytes).flatten() {
        let wasmparser::Payload::ImportSection(reader) = payload else { continue };
        for group in reader.into_iter().flatten() {
            match group {
                Imports::Single(_, imp) => add(imp.module, imp.name, matches!(imp.ty, TypeRef::Func(_))),
                Imports::Compact1 { module, items } => {
                    for it in items.into_iter().flatten() {
                        add(module, it.name, matches!(it.ty, TypeRef::Func(_)));
                    }
                }
                Imports::Compact2 { module, names, ty } => {
                    for n in names.into_iter().flatten() {
                        add(module, n, matches!(ty, TypeRef::Func(_)));
                    }
                }
            }
        }
    }
    out.sort();
    out.dedup();
    out
}

/// Which of `needs` nothing in the wasm world defines; `--allow-undefined` lets a
/// library link without them.
pub(super) fn unresolved_dylink_needs(needs: &[String], lib: &ExtLibrary, others: &[ExtLibrary]) -> Vec<String> {
    let mut defined: HashSet<&str> = HashSet::new();
    for bytes in others
        .iter()
        .map(|l| &l.bytes[..])
        .chain([&lib.bytes[..], LIBC_PIC(), EXTERNAL_C_DYLINK(), LAPACK_DYLINK(), openmodelica_wasm_jit::RUNTIME_WASM()])
    {
        defined.extend(wasm_exports(bytes));
    }
    needs.iter().filter(|n| !defined.contains(n.as_str())).cloned().collect()
}

/// The `-L` directories of a linker flag string (`-Ldir`, `-L"dir"`, `-L dir`).
/// It is a shell command line, so quotes group rather than belong to the path.
fn ld_search_dirs(flags: &str) -> Vec<String> {
    let mut words: Vec<String> = Vec::new();
    let mut word = String::new();
    let mut quote: Option<char> = None;
    for c in flags.chars() {
        match (quote, c) {
            (Some(q), c) if c == q => quote = None,
            (Some(_), c) => word.push(c),
            (None, '"' | '\'') => quote = Some(c),
            (None, c) if c.is_whitespace() => {
                if !word.is_empty() {
                    words.push(std::mem::take(&mut word));
                }
            }
            (None, c) => word.push(c),
        }
    }
    if !word.is_empty() {
        words.push(word);
    }
    let mut dirs = Vec::new();
    let mut words = words.into_iter();
    while let Some(w) = words.next() {
        if w == "-L" {
            dirs.extend(words.next());
        } else if let Some(d) = w.strip_prefix("-L") {
            dirs.push(d.to_owned());
        }
    }
    dirs
}

/// A `Library` naming a C source file, which gcc compiles rather than links.
fn find_source_library(spec: &str, dirs: &[String]) -> Option<String> {
    if !spec.ends_with(".c") && !spec.ends_with(".cc") && !spec.ends_with(".cpp") && !spec.ends_with(".cxx") {
        return None;
    }
    dirs.iter().map(|d| format!("{d}{spec}")).find(|p| openmodelica_wasi::fs::exists(p))
}

/// What a host linker spec resolves to.
enum NativeLib {
    /// A shared object, which the loader opens as it is.
    Shared(String),
    /// A static archive or an object file, which [`ExtArchives`] has to link first.
    Archive(String),
    /// A soname no search directory held a file for, so only the platform's own
    /// loader can find it: a system dependency, not a file an export can ship.
    System(String),
}

fn is_link_input(name: &str) -> bool {
    // `gcc -c -o x.lib` spells an object file the MSVC way. On Windows the suffix
    // is a real static/import library, which no `cc -shared` makes loadable.
    name.ends_with(".a") || name.ends_with(".o") || (!cfg!(windows) && (name.ends_with(".lib") || name.ends_with(".obj")))
}

/// The platform library a host linker spec names. A `-lfoo` nothing under `dirs`
/// provides stays a plain soname, for the system loader to find the way the linker
/// would.
fn find_native_library(spec: &str, dirs: &[String]) -> Option<NativeLib> {
    if cfg!(target_arch = "wasm32") {
        return None; // no dynamic loader to fall back to
    }
    let (prefix, suffix) = (std::env::consts::DLL_PREFIX, std::env::consts::DLL_SUFFIX);
    let name = match spec.strip_prefix("-l") {
        Some(n) => n,
        // Any other linker flag (`-L`, `-Wl,…`, `-pthread`) names no library.
        None if spec.starts_with('-') => return None,
        None => spec,
    };
    // `.lib` is both spellings on Windows, with no `cc -shared` to sort them out.
    if cfg!(windows) && (name.ends_with(".obj") || name.ends_with(".lib")) {
        return None;
    }
    // A bare name is what the loader searches its own path for, not the working
    // directory `dirs[0]` matched it in.
    let found = |p: String| {
        let p = if p.contains(['/', '\\']) { p } else { format!("./{p}") };
        Some(if is_link_input(&p) { NativeLib::Archive(p) } else { NativeLib::Shared(p) })
    };
    if is_link_input(name) || name.contains(suffix) || name.contains(std::path::MAIN_SEPARATOR) {
        return dirs.iter().map(|d| format!("{d}{name}")).find(|p| std::path::Path::new(p).exists()).and_then(found);
    }
    // As ld searches: a directory at a time, the shared object before the archive.
    for dir in dirs {
        let candidates =
            [format!("{dir}{prefix}{name}{suffix}"), format!("{dir}{name}{suffix}"), format!("{dir}{prefix}{name}.a")];
        if let Some(p) = candidates.into_iter().find(|p| std::path::Path::new(p).exists()) {
            return found(p);
        }
    }
    (spec != name).then(|| NativeLib::System(format!("{prefix}{name}{suffix}")))
}

/// `<dir><name>` or `<dir>lib<name>`, the two spellings a `Library="foo"`
/// annotation is written with.
fn find_ext_library(name: &str, dirs: &[String]) -> Option<(String, Vec<u8>)> {
    let stem = name.strip_suffix(".wasm").unwrap_or(name);
    for dir in dirs {
        for candidate in [format!("{dir}{stem}.wasm"), format!("{dir}lib{stem}.wasm")] {
            if let Ok(bytes) = openmodelica_wasi::fs::read(&candidate) {
                return Some((candidate, bytes));
            }
        }
    }
    None
}

/// [`find_ext_library`] for a linker spec (`-lFoo`, `Foo`, `dir/Foo.wasm`).
fn find_wasm_library(spec: &str, dirs: &[String]) -> Option<(String, Vec<u8>)> {
    let name = match spec.strip_prefix("-l") {
        Some(n) => n,
        // Any other linker flag (`-L`, `-Wl,…`, `-pthread`) names no library.
        None if spec.starts_with('-') => return None,
        None => spec,
    };
    find_ext_library(name, dirs)
}

/// Whether the built-in ModelicaExternalC side module defines an `external "C"`
/// the model's own libraries leave open ([`SimModel::ext_builtin`]). It carries
/// the whole MSL C set, which no installed `.wasm` names, so it is matched by
/// symbol rather than by `Library` name.
///
/// It does not join `ext_libs`: those are the model's *own*, and the FMU link adds
/// this one itself.
pub(super) fn builtin_wasm_needed(ext_imports: &[ExtCallSig], libs: &[ExtLibrary]) -> bool {
    if EXTERNAL_C_DYLINK().is_empty() {
        return false;
    }
    let mut open: HashSet<&str> = ext_imports.iter().map(|s| s.name.as_str()).collect();
    for l in libs {
        for n in wasm_exports(&l.bytes) {
            open.remove(n);
        }
    }
    !open.is_empty() && wasm_exports(EXTERNAL_C_DYLINK()).any(|n| open.contains(n))
}
