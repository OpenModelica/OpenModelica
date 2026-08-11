//! Native platforms for a wasm FMU: `buildModelFMU(..., platforms={"wasm", "linux64"})`
//! adds, per platform, the component compiled ahead of time for that machine plus
//! the loader library that serves the FMI C API from it
//! (`openmodelica_fmi_ls_wasm_to_native`, which exports both 2.0 and 3.0).
//!
//! Compiling is pure computation — no linker, no toolchain, no host runtime — so
//! one machine cross-targets every platform, including from a browser: see
//! `precompile` below.

#[cfg(any(not(feature = "fmu-native"), target_arch = "wasm32"))]
use std::cell::Cell;

use metamodelica::Result;

pub struct Platform {
    /// FMI 3.0's platform tuple, i.e. the `binaries/<name>/` directory, and the
    /// name of the `.cwasm` in `resources/`.
    pub fmi: &'static str,
    /// FMI 2.0's `binaries/<name>/` directory. The names FMI 2.0 §2.1.1
    /// standardises cover 32- and 64-bit x86 only; every other platform uses the
    /// FMI 3.0 tuple, which is what [`Platform::fmi`] already is.
    pub fmi2: &'static str,
    /// What the user may write in `platforms={...}` besides `fmi`.
    pub aliases: &'static [&'static str],
    pub triple: &'static str,
    /// Shared-library extension, with the dot. FMI names the binary
    /// `<modelIdentifier><ext>` — no `lib` prefix, unlike the platform itself.
    pub ext: &'static str,
}

/// No 32-bit entries: the component is compiled by cranelift, whose only
/// backends are x86-64, aarch64, riscv64 and s390x.
pub const PLATFORMS: &[Platform] = &[
    Platform { fmi: "x86_64-linux", fmi2: "linux64", aliases: &["linux64", "x86_64-unknown-linux-gnu"], triple: "x86_64-unknown-linux-gnu", ext: ".so" },
    Platform { fmi: "aarch64-linux", fmi2: "aarch64-linux", aliases: &["linuxarm64", "aarch64-unknown-linux-gnu"], triple: "aarch64-unknown-linux-gnu", ext: ".so" },
    Platform { fmi: "x86_64-windows", fmi2: "win64", aliases: &["win64", "x86_64-pc-windows-msvc"], triple: "x86_64-pc-windows-msvc", ext: ".dll" },
    Platform { fmi: "aarch64-windows", fmi2: "aarch64-windows", aliases: &["winarm64", "aarch64-pc-windows-msvc"], triple: "aarch64-pc-windows-msvc", ext: ".dll" },
    Platform { fmi: "x86_64-darwin", fmi2: "darwin64", aliases: &["darwin64", "x86_64-apple-darwin"], triple: "x86_64-apple-darwin", ext: ".dylib" },
    Platform { fmi: "aarch64-darwin", fmi2: "aarch64-darwin", aliases: &["darwinarm64", "aarch64-apple-darwin"], triple: "aarch64-apple-darwin", ext: ".dylib" },
];

/// The `binaries/` directory this platform's loader goes in, for an FMU of
/// `version`.
pub fn fmi_dir(p: &Platform, version: &str) -> &'static str {
    if version == "2.0" {
        p.fmi2
    } else {
        p.fmi
    }
}

/// `"native"` is the platform omc runs on: the only one every build carries.
pub fn host_platform() -> Option<&'static Platform> {
    let want = match (std::env::consts::ARCH, std::env::consts::OS) {
        ("x86_64", "linux") => "x86_64-linux",
        ("aarch64", "linux") => "aarch64-linux",
        ("x86_64", "windows") => "x86_64-windows",
        ("aarch64", "windows") => "aarch64-windows",
        ("x86_64", "macos") => "x86_64-darwin",
        ("aarch64", "macos") => "aarch64-darwin",
        _ => return None,
    };
    PLATFORMS.iter().find(|p| p.fmi == want)
}

pub fn lookup(name: &str) -> Option<&'static Platform> {
    let name = name.trim();
    if name.eq_ignore_ascii_case("native") {
        return host_platform();
    }
    PLATFORMS
        .iter()
        .find(|p| p.fmi.eq_ignore_ascii_case(name) || p.aliases.iter().any(|a| a.eq_ignore_ascii_case(name)))
}

/// The loader for this platform, if this omc can reach one: from
/// `lib/omc/fmu-loaders/` natively, from the web bundle through the host on wasm
/// ([`set_loader_source`]). Which exist is decided by `OMC_FMU_NATIVE_TARGETS`
/// when omc is built.
pub fn loader(p: &Platform) -> Option<Vec<u8>> {
    host_loader(p.fmi)
}

pub fn loader_file_name(p: &Platform, model_id: &str) -> String {
    format!("{model_id}{}", p.ext)
}

pub fn available() -> Vec<String> {
    let mut names = host_platforms();
    names.sort();
    names
}

/// Compile `component` to machine code for `p`. The engine configuration must be
/// the loader's — a mismatch is rejected at load time, not here.
#[cfg(all(feature = "fmu-native", not(target_arch = "wasm32")))]
pub fn precompile(component: &[u8], p: &Platform) -> Result<Vec<u8>> {
    let mut cfg = wasmtime::Config::new();
    cfg.wasm_component_model(true);
    cfg.target(p.triple).map_err(|_| "CodegenWasmJit: unknown target for the FMU platform")?;
    let engine = wasmtime::Engine::new(&cfg)
        .map_err(|_| "CodegenWasmJit: cannot configure the FMU cross-compiler")?;
    engine
        .precompile_component(component)
        .map_err(|_| "CodegenWasmJit: cannot compile the component for the FMU platform")
}

/// Nothing to announce: this omc compiles in process.
#[cfg(all(feature = "fmu-native", not(target_arch = "wasm32")))]
pub fn preload_aot_compiler() {}

#[cfg(target_arch = "wasm32")]
thread_local! {
    static LOADER_FETCH: Cell<Option<fn(&str) -> Option<Vec<u8>>>> = const { Cell::new(None) };
    static LOADER_PLATFORMS: std::cell::RefCell<Vec<String>> =
        const { std::cell::RefCell::new(Vec::new()) };
}

#[cfg(target_arch = "wasm32")]
pub fn set_loader_source(fetch: fn(&str) -> Option<Vec<u8>>, platforms: Vec<String>) {
    LOADER_FETCH.with(|f| f.set(Some(fetch)));
    LOADER_PLATFORMS.with(|p| *p.borrow_mut() = platforms);
}

#[cfg(target_arch = "wasm32")]
fn host_loader(platform: &str) -> Option<Vec<u8>> {
    LOADER_FETCH.with(|f| f.get())?(platform)
}

#[cfg(target_arch = "wasm32")]
fn host_platforms() -> Vec<String> {
    LOADER_PLATFORMS.with(|p| p.borrow().clone())
}

/// Where `make install` puts the loader libraries, one `<platform><ext>` each.
#[cfg(not(target_arch = "wasm32"))]
fn loaders_dir() -> std::path::PathBuf {
    let home = openmodelica_util::Settings::getInstallationDirectoryPath()
        .map(|p| p.to_string())
        .unwrap_or_default();
    std::path::PathBuf::from(home).join("lib/omc/fmu-loaders")
}

#[cfg(not(target_arch = "wasm32"))]
fn host_loader(platform: &str) -> Option<Vec<u8>> {
    let p = PLATFORMS.iter().find(|p| p.fmi == platform)?;
    std::fs::read(loaders_dir().join(format!("{platform}{}", p.ext))).ok()
}

#[cfg(not(target_arch = "wasm32"))]
fn host_platforms() -> Vec<String> {
    PLATFORMS
        .iter()
        .filter(|p| loaders_dir().join(format!("{}{}", p.fmi, p.ext)).is_file())
        .map(|p| p.fmi.to_owned())
        .collect()
}

/// An out-of-process compiler, for an omc that cannot link wasmtime in: the
/// browser one runs the same wasmtime built for wasm32-wasip1 in a worker,
/// because cranelift's `timing` reaches `Instant::now()`, which panics on
/// wasm32-unknown-unknown.
#[cfg(any(not(feature = "fmu-native"), target_arch = "wasm32"))]
type AotCompiler = fn(&[u8], &str) -> std::result::Result<Vec<u8>, String>;

#[cfg(any(not(feature = "fmu-native"), target_arch = "wasm32"))]
thread_local! {
    static AOT: Cell<Option<AotCompiler>> = const { Cell::new(None) };
    static AOT_PRELOAD: Cell<Option<fn()>> = const { Cell::new(None) };
}

#[cfg(any(not(feature = "fmu-native"), target_arch = "wasm32"))]
pub fn set_aot_compiler(compile: AotCompiler, preload: fn()) {
    AOT.with(|a| a.set(Some(compile)));
    AOT_PRELOAD.with(|p| p.set(Some(preload)));
}

/// Tell the host a native platform is coming, so it can start loading its
/// compiler while the model still builds. Idempotent.
#[cfg(any(not(feature = "fmu-native"), target_arch = "wasm32"))]
pub fn preload_aot_compiler() {
    if let Some(f) = AOT_PRELOAD.with(|p| p.get()) {
        f();
    }
}

#[cfg(any(not(feature = "fmu-native"), target_arch = "wasm32"))]
pub fn precompile(component: &[u8], p: &Platform) -> Result<Vec<u8>> {
    let Some(compile) = AOT.with(|a| a.get()) else {
        return Err("CodegenWasmJit: this omc cannot compile an FMU for a native platform; \
                    export it with a native omc, or ask only for platforms={\"wasm\"}");
    };
    compile(component, p.triple).map_err(|e| {
        super::record_error(format!("CodegenWasmJit: compiling the FMU for {}: {e}", p.fmi));
        "CodegenWasmJit: cannot compile the component for the FMU platform"
    })
}
