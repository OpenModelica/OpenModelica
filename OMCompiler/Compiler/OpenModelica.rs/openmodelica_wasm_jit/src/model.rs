//! The prepared model the codegen hands to the engine, and the driver-selection
//! knobs. `SimModel` is built by the codegen and consumed by [`crate::sim_runtime`].

use std::collections::HashMap;
use std::sync::Mutex;

use crate::sig::{ExtCallSig, WTy};
use openmodelica_sim_meta::{JacAInfo, Layout as SimLayout, MetaVar as ResultVar, SimMeta, StateSetInfo};

/// A pending model-module compile: a background-thread join handle natively, an
/// eager result on wasm (no threads).
#[cfg(not(target_arch = "wasm32"))]
pub type ModelCompileJob = std::thread::JoinHandle<Result<crate::sim_runtime::Module, String>>;
#[cfg(target_arch = "wasm32")]
pub type ModelCompileJob = Result<crate::sim_runtime::Module, String>;

/// The prepared, ready-to-run artifact for one model: the in-memory replacement
/// for the C target's `_init.xml` + `_info.json` + the built executable.
pub struct SimModel {
    pub wasm: Vec<u8>,
    pub layout: SimLayout,
    pub result_vars: Vec<ResultVar>,
    /// The `ext.<extName>` host imports (external "C" functions) with the full
    /// C-call shape, so the host trampoline can marshal strings/arrays/pointers.
    pub ext_imports: Vec<ExtCallSig>,
    /// The model's own `external "C"` libraries, loaded into the simulation's
    /// memory, where they define the `ext_imports` the runtime cannot resolve.
    pub ext_libs: Vec<ExtLibrary>,
    /// The same implementations as platform shared libraries, for a symbol no wasm
    /// library defines: a native host dlopens them and calls in through libffi.
    /// Empty in the browser.
    pub ext_native_libs: Vec<String>,
    /// The archives and object files among them ([`ExtArchives`]).
    pub ext_archives: Option<ExtArchives>,
    pub ext_includes: Option<ExtIncludes>,
    /// Why a `Library` or an `Include` yielded no wasm library; reported only if a
    /// symbol then turns out to be missing.
    pub ext_lib_notes: Vec<String>,
    pub model_name: String,
    pub start_time: f64,
    pub stop_time: f64,
    pub n_intervals: u32,
    pub output_format: String,
    /// Integration method (`"dassl"`, `"euler"`, …); selects the driver in [`crate::sim_runtime::run`].
    pub method: String,
    /// Relative/absolute tolerance for the adaptive integrators (DASSL).
    pub tolerance: f64,
    /// Background JIT job for the model module (joined by `finishCompile` or `runSimulation`).
    pub compiled: Mutex<Option<ModelCompileJob>>,
    /// The compiled model module once joined, so `runSimulation` need not recompile.
    pub prepared: Mutex<Option<crate::sim_runtime::Module>>,
    /// Dynamic state-selection metadata (one per `$STATESET`); empty otherwise.
    pub state_sets: Vec<StateSetInfo>,
    /// ODE state Jacobian ∂f/∂x sparsity + coloring; `None` ⇒ daskr's numerical Jacobian.
    pub jac_a: Option<JacAInfo>,
    /// User-settable initial conditions (changeable parameters), for `-override`.
    pub editable_params: Vec<EditableParam>,
    /// Result-variable display name -> unit, for a host to label plotted signals.
    pub var_units: HashMap<String, String>,
    /// Driver-facing metadata shared with the in-wasm driver (passed to `sim_driver::drive`).
    pub meta: SimMeta,
}

impl SimModel {
    /// C's `read_experiment`: this run's scalars, i.e. the model's metadata with the
    /// flags installed for the run applied. The model is shared between runs, so the
    /// run works off a copy.
    pub fn run_meta(&self) -> SimMeta {
        openmodelica_sim_meta::simflags::with_flags(|f| self.meta.with_flags(f))
    }
}

/// One resolved `external "C"` library, read at codegen time so a run needs no
/// filesystem.
#[derive(Clone)]
pub struct ExtLibrary {
    pub name: String,
    pub bytes: Vec<u8>,
}

/// The static archives and object files a `Library` annotation resolved to
/// (`libfmilib.a` and friends). No loader can open one, so they are linked into a
/// shared object with the model's `external "C"` functions as the undefined
/// symbols that pull the archive members in — the members the C target's own link
/// pulls in. What is left undefined (`ModelicaFormatError`, libc) resolves in the
/// global scope, as it would there.
#[derive(Clone, Default)]
pub struct ExtArchives {
    /// In link order.
    pub archives: Vec<String>,
    /// The `external "C"` functions to pull out of them.
    pub symbols: Vec<String>,
    pub ccompiler: String,
    pub dllext: String,
    pub prefix: String,
}

impl ExtArchives {
    /// Link them and return the shared object's path, once per process: the model
    /// can be resimulated, and the link is a compiler run.
    #[cfg(not(target_arch = "wasm32"))]
    pub fn link(&self) -> std::result::Result<String, String> {
        use std::sync::{LazyLock, Mutex};
        static LINKED: LazyLock<Mutex<HashMap<String, std::result::Result<String, String>>>> =
            LazyLock::new(|| Mutex::new(HashMap::new()));
        let key = format!("{}\n{}", self.archives.join("\n"), self.symbols.join(" "));
        LINKED.lock().unwrap().entry(key).or_insert_with(|| self.link_uncached()).clone()
    }

    #[cfg(not(target_arch = "wasm32"))]
    fn link_uncached(&self) -> std::result::Result<String, String> {
        use std::process::Command;
        let dir = std::env::temp_dir().join(format!("om-extc-{}", std::process::id()));
        std::fs::create_dir_all(&dir).map_err(|e| format!("cannot create {}: {e}", dir.display()))?;
        let out = dir.join(format!("{}_libs{}", self.prefix, self.dllext));
        let mut cmd = Command::new(&self.ccompiler);
        cmd.arg("-shared").arg("-o").arg(&out);
        for sym in &self.symbols {
            cmd.arg(format!("-Wl,-u,{sym}"));
        }
        cmd.args(&self.archives);
        let output = cmd
            .output()
            .map_err(|e| format!("`{}` could not be run to link the static libraries: {e}", self.ccompiler))?;
        if !output.status.success() {
            return Err(format!(
                "the static libraries ({}) did not link into a loadable one:\n{}",
                self.archives.join(", "),
                String::from_utf8_lossy(&output.stderr)
            ));
        }
        Ok(out.to_string_lossy().into_owned())
    }

    #[cfg(target_arch = "wasm32")]
    pub fn link(&self) -> std::result::Result<String, String> {
        Err("the implementation comes from a static library, which has to be linked — the browser \
             omc has no linker. Provide it as a `Library` built with \
             `clang --target=wasm32-wasip1 -fPIC -shared`"
            .to_string())
    }
}

/// The model's `Include` annotations, and what it takes to build them: host C source
/// the C target compiles into the simulation executable. Built only once a symbol
/// turns out to be missing from every library — an `Include` most often just declares
/// what a `Library` defines, and a header-only unit would produce nothing to load.
#[derive(Clone, Default)]
pub struct ExtIncludes {
    pub sources: Vec<String>,
    /// `IncludeDirectory` annotations, already `-I"…"` strings.
    pub include_dirs: Vec<String>,
    pub ccompiler: String,
    pub cflags: String,
    pub dllext: String,
    /// Names the object after the model, as the C target does.
    pub prefix: String,
}

impl ExtIncludes {
    /// Build the sources into a host shared library and return its path. Per-process
    /// temp directory: it stays mapped as long as the model can be resimulated.
    #[cfg(not(target_arch = "wasm32"))]
    pub fn compile(&self, missing: &[ExtCallSig]) -> std::result::Result<String, String> {
        let wrappers = ext_wrappers(missing);
        match self.compile_tu(&wrappers) {
            Err(e) if !wrappers.is_empty() => self.compile_tu("").map_err(|_| e),
            r => r,
        }
    }

    #[cfg(not(target_arch = "wasm32"))]
    fn compile_tu(&self, wrappers: &str) -> std::result::Result<String, String> {
        use std::process::Command;
        let dir = std::env::temp_dir().join(format!("om-extc-{}", std::process::id()));
        std::fs::create_dir_all(&dir).map_err(|e| format!("cannot create {}: {e}", dir.display()))?;
        // The fallback build must not be handed the path it just failed to load.
        let stem = if wrappers.is_empty() { "includes_exports" } else { "includes" };
        let tu = dir.join(format!("{}_{stem}.c", self.prefix));
        let out = dir.join(format!("{}_{stem}{}", self.prefix, self.dllext));
        std::fs::write(&tu, INCLUDE_TU_PROLOGUE.to_owned() + &self.sources.join("\n") + "\n" + wrappers)
            .map_err(|e| format!("cannot write {}: {e}", tu.display()))?;

        let mut cmd = Command::new(&self.ccompiler);
        cmd.args(["-shared", "-fPIC", "-O1"]);
        // `--cflags`, minus the make variables it is written to be expanded with.
        cmd.args(self.cflags.split_whitespace().filter(|f| !f.starts_with("${") && !f.starts_with("$(")));
        // Compiled in a temporary directory, so `#include "x.h"` needs the model's own.
        if let Ok(cwd) = std::env::current_dir() {
            cmd.arg("-I").arg(cwd);
        }
        for dir in omc_c_include_dirs() {
            cmd.arg("-I").arg(dir);
        }
        for inc in &self.include_dirs {
            cmd.arg(inc.trim_matches('"'));
        }
        cmd.arg("-o").arg(&out).arg(&tu);
        let output = cmd
            .output()
            .map_err(|e| format!("`{}` could not be run to compile the `Include` C sources: {e}", self.ccompiler))?;
        if !output.status.success() {
            return Err(format!(
                "the `Include` C sources did not compile:\n{}",
                String::from_utf8_lossy(&output.stderr)
            ));
        }
        let _ = std::fs::remove_file(&tu);
        Ok(out.to_string_lossy().into_owned())
    }

    #[cfg(target_arch = "wasm32")]
    pub fn compile(&self, _missing: &[ExtCallSig]) -> std::result::Result<String, String> {
        Err("the implementation comes from an `Include` annotation with C source, which has to be \
             compiled — the browser omc has no compiler. Provide it as a `Library` built with \
             `clang --target=wasm32-wasip1 -fPIC -shared`"
            .to_string())
    }
}

/// A header-only `Include` may declare every function `static`, exporting nothing;
/// a wrapper handing back the address needs no prototype and reaches it anyway.
pub const EXT_ADDR_PREFIX: &str = "omc_ext_addr_";

/// A function-like macro has no address, so the *call* is what the unit provides
/// — which is all the C target ever compiles, expanding the macro at its own
/// call site.
pub const EXT_CALL_PREFIX: &str = "omc_ext_call_";

/// One wrapper per function still to be found. Taking the address of a function
/// the sources never declare does not compile, so the caller falls back to the
/// unit without these.
pub fn ext_wrappers(sigs: &[ExtCallSig]) -> String {
    let mut out = String::new();
    for sig in sigs {
        let name = &sig.name;
        match ext_call_wrapper(sig) {
            Some(call) => out.push_str(&format!(
                "#ifdef {name}\n{call}#else\n{}#endif\n",
                ext_addr_wrapper(name)
            )),
            None => out.push_str(&ext_addr_wrapper(name)),
        }
    }
    out
}

fn ext_addr_wrapper(name: &str) -> String {
    format!("void (*{EXT_ADDR_PREFIX}{name}(void))(void) {{ return (void (*)(void)) {name}; }}\n")
}

/// `T omc_ext_call_f(A a0, …) { return f(a0, …); }`. `None` when an argument has
/// no C spelling the declaration alone fixes (a record's struct).
fn ext_call_wrapper(sig: &ExtCallSig) -> Option<String> {
    let byref = sig.lang == crate::sig::ExtLang::Fortran77;
    let mut params = String::new();
    for (i, (ty, is_out)) in sig.args.iter().enumerate() {
        let ptr = *is_out || byref || matches!(ty, crate::sig::SigTy::Array { .. });
        params.push_str(&format!(
            "{}{}{} a{i}",
            if i == 0 { "" } else { ", " },
            ext_c_type(ty)?,
            if ptr { "*" } else { "" }
        ));
    }
    let args: Vec<String> = (0..sig.args.len()).map(|i| format!("a{i}")).collect();
    let (ret, call) = match &sig.ret {
        Some(ty) => (ext_c_type(ty)?.to_owned(), "return "),
        None => ("void".to_owned(), ""),
    };
    Some(format!(
        "{ret} {EXT_CALL_PREFIX}{}({}) {{ {call}{}({}); }}\n",
        sig.name,
        if params.is_empty() { "void".to_owned() } else { params },
        sig.name,
        args.join(", ")
    ))
}

/// The C type the language specification maps a Modelica type to; an array is its
/// element type, passed by pointer.
fn ext_c_type(ty: &crate::sig::SigTy) -> Option<&'static str> {
    use crate::sig::SigTy;
    Some(match ty {
        SigTy::Int | SigTy::Bool => "int",
        SigTy::Real => "double",
        SigTy::Str => "const char*",
        SigTy::Ptr => "void*",
        SigTy::Array { elem, .. } => ext_c_type(elem)?,
        SigTy::Record { .. } | SigTy::Func { .. } => return None,
    })
}

/// What the C target's generated `<prefix>_includes.h` opens with, so external C
/// source sees the same declarations wherever it is built.
pub const INCLUDE_TU_PROLOGUE: &str = "\
#include \"openmodelica.h\"       /* Defines OPENMODELICA_H_ for libraries to test if called from OpenModelica. */\n\
#include \"ModelicaUtilities.h\"  /* Make Modelica C util functions available for external includes. */\n";

/// The same for a wasm unit, where `openmodelica.h` cannot be opened — it reaches the
/// Boehm GC and `setjmp`. Name what external source uses it for instead. Nothing
/// omc-specific: source needing more than the specification's C interface includes
/// it itself.
pub const INCLUDE_TU_PROLOGUE_WASM: &str = "\
#include <stddef.h>\n\
#include <stdio.h>\n\
#include <stdlib.h>\n\
#include <string.h>\n\
#include <math.h>\n\
#include \"ModelicaUtilities.h\"\n";

/// omc's own C headers, plus the bundled `gc.h` that `openmodelica.h` reaches —
/// the `-I` set the C target's makefile compiles the same source with.
pub fn omc_c_include_dirs() -> [String; 2] {
    let home = openmodelica_util::Settings::getInstallationDirectoryPath()
        .map(|p| p.to_string())
        .unwrap_or_default();
    [format!("{home}/include/omc/c"), format!("{home}/include/omc")]
}

/// A user-settable parameter (an editable initial condition): display name, unit,
/// and `SimData` slot so an `-override=name=value` can write it.
#[derive(Clone)]
pub struct EditableParam {
    pub name: String,
    pub comment: String,
    pub unit: String,
    pub off: u32,
    pub wty: WTy,
    /// A state's start value (vs. a plain parameter): overridden after `functionInitStartValues`.
    pub is_start: bool,
    /// A Boolean quantity: reads an `-override` value C's `read_value_bool` way.
    pub is_bool: bool,
    /// Enumeration literal names (1-based index → name), empty for non-enum.
    pub enum_names: Vec<String>,
}

impl EditableParam {
    /// C's per-class `_init.xml` readers on an `-override` value: `read_value_bool`
    /// for a Boolean, else `read_value_real`/`_long`, whose `atof`/`atol` give 0 for junk.
    pub fn read_value(&self, s: &str) -> f64 {
        if self.is_bool {
            return if s == "true" { 1.0 } else { 0.0 };
        }
        match s {
            "true" => 1.0,
            "false" => 0.0,
            _ => s.parse::<f64>().unwrap_or(0.0),
        }
    }
}

// ─────────────────────────── driver selection ───────────────────────────

#[cfg(feature = "jit")]
static INWASM_OVERRIDE: std::sync::atomic::AtomicI8 = std::sync::atomic::AtomicI8::new(-1);
#[cfg(feature = "jit")]
static SIM_BENCH_FORCE: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);
#[cfg(feature = "jit")]
static SINGLE_THREADED: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);

/// Force the driver choice: `1` in-wasm, `0` host, `-1` default. Wins over the env
/// var and the target default — wasm has no environment.
#[cfg(feature = "jit")]
pub fn set_inwasm_driver_override(mode: i32) {
    INWASM_OVERRIDE.store(mode.clamp(-1, 1) as i8, std::sync::atomic::Ordering::Relaxed);
}

/// Force the bench lines on, for hosts with no `OMC_WASM_SIM_BENCH` to set.
#[cfg(feature = "jit")]
pub fn set_sim_bench(on: bool) {
    SIM_BENCH_FORCE.store(on, std::sync::atomic::Ordering::Relaxed);
}

#[cfg(feature = "jit")]
pub fn sim_bench_enabled() -> bool {
    SIM_BENCH_FORCE.load(std::sync::atomic::Ordering::Relaxed)
        || std::env::var("OMC_WASM_SIM_BENCH").is_ok()
}

/// Set from `-n`: one processor means no background precompile and no parallel
/// module compilation, so each phase is timed where it runs.
#[cfg(feature = "jit")]
pub fn set_single_threaded(on: bool) {
    SINGLE_THREADED.store(on, std::sync::atomic::Ordering::Relaxed);
}

#[cfg(feature = "jit")]
pub fn single_threaded() -> bool {
    SINGLE_THREADED.load(std::sync::atomic::Ordering::Relaxed)
}

/// Whether to run through the in-wasm session driver (`rt_sim_*`) instead of the
/// host driver. wasm32 defaults on; native defaults off (the host driver is the
/// faster parity oracle).
#[cfg(feature = "jit")]
pub fn inwasm_driver_enabled() -> bool {
    match INWASM_OVERRIDE.load(std::sync::atomic::Ordering::Relaxed) {
        0 => return false,
        1 => return true,
        _ => {}
    }
    match std::env::var("OMC_WASM_INWASM_DRIVER").ok().as_deref() {
        Some("0") | Some("false") => false,
        Some(_) => true,
        None => cfg!(target_arch = "wasm32"),
    }
}

/// Encode the host's parameter/start overrides and `-iif` imports for
/// `rt_sim_set_overrides`.
#[cfg(feature = "jit")]
pub fn encode_overrides() -> Vec<u8> {
    let (params, starts) = crate::sim_driver::param_overrides();
    let mut b = Vec::new();
    for group in [&params, &starts] {
        b.extend_from_slice(&(group.len() as u32).to_le_bytes());
        for &(off, wty, val) in group.iter() {
            b.extend_from_slice(&off.to_le_bytes());
            b.extend_from_slice(&(if matches!(wty, WTy::F64) { 0u32 } else { 1u32 }).to_le_bytes());
            b.extend_from_slice(&val.to_le_bytes());
        }
    }
    if let Some(i) = crate::sim_driver::start_imports() {
        b.extend_from_slice(&(i.values.len() as u32).to_le_bytes());
        b.extend_from_slice(&i.time.to_le_bytes());
        b.extend_from_slice(&(i.file.len() as u32).to_le_bytes());
        b.extend_from_slice(i.file.as_bytes());
        for &(idx, val) in &i.values {
            b.extend_from_slice(&idx.to_le_bytes());
            b.extend_from_slice(&val.to_le_bytes());
        }
    }
    b
}

/// Model export names in table-slot order. The runtime's `session::slot_of` derives
/// from the same list, so the two sides cannot drift.
#[cfg(feature = "jit")]
pub const INWASM_SLOT_NAMES: &[&str] = openmodelica_sim_meta::driver::MODEL_FNS;
