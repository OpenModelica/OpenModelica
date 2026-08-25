// Host side of the `wasm-jit` simulation target: JIT the precompiled runtime
// module and the generated model module (sharing one linear memory), then run
// the integration and return the result trajectory. The driver is selected by
// the model's integration `method`:
//
//   * `method="euler"` — forward Euler. Two variants:
//       - in-wasm (default): a single call to the model's `simulate` export,
//         whose emitted loop calls `functionODE`/`functionAlgebraics` and the
//         runtime's `rt_euler_step`/`rt_sim_store_row` with no host boundary
//         crossing per step.
//       - host-driven (`OMC_WASM_SIM_DRIVER=host`, for benchmarking): the Euler
//         loop runs in native Rust, one wasm call per step.
//   * `method="dassl"` (the OpenModelica default) — the variable-order,
//     variable-step BDF DAE solver from the `daskr` crate, driven from the host.
//     `daskr` integrates natively; its residual callback `G(t,y,y') = y' - f(t,y)`
//     drives the wasm `functionODE` once per evaluation. DASSL chooses its own
//     internal steps and interpolates back to each output point.
//
// All drivers share the same generated model module and `SimData` layout.

use metamodelica::Result;
use std::collections::HashMap;
use std::sync::OnceLock;
use std::time::Instant;

use crate::sim_driver;
use crate::dylink_engine::{NlsHooks, zero_results};
use crate::model::{self, SimModel};
use openmodelica_sim_meta::SimMeta;
use crate::host::add_host_builtins;

/// The runtime module, embedded the same way the function half embeds it.
use crate::{RUNTIME_WASM, RUNTIME_WASM_INTERACTIVE_WASIP1};
use crate::wasi_shim;
use openmodelica_wasi::wasi::WasiCtx;

/// The runtime module the interactive host instantiates: the std wasip1 build
/// (so the sparse solver links in) when it was produced, else the no_std
/// `RUNTIME_WASM` fallback. Both export the same `rt_*`+`memory`+table interface;
/// the wasip1 one additionally imports `wasi_snapshot_preview1` (served by the
/// `wasi_shim`).
fn runtime_blob() -> &'static [u8] {
    if RUNTIME_WASM_INTERACTIVE_WASIP1.is_empty() {
        RUNTIME_WASM
    } else {
        RUNTIME_WASM_INTERACTIVE_WASIP1
    }
}

/// The compiled-module type for this backend; `CodegenWasmJit::SimModel` stores
/// it backend-agnostically as `sim_runtime::Module`.
pub(crate) type Module = wasmtime::Module;

/// Seconds before wasm is interrupted, 0 = no hard alarm. `-alarm` is normally
/// served by the driver's per-step deadline; this is the bound C gets from
/// `SIGALRM`, for a run wedged inside one call into wasm. The epoch checks
/// Cranelift then emits cost ~20% of the integration, hence the env var.
static ALARM_SECS: std::sync::atomic::AtomicU32 = std::sync::atomic::AtomicU32::new(0);

/// Install the run's `-alarm`, before the modules are instantiated: a hard alarm
/// selects the other engine.
pub fn set_alarm(seconds: Option<u32>) {
    let hard = seconds.filter(|_| std::env::var("OMC_WASM_HARD_ALARM").is_ok());
    ALARM_SECS.store(hard.unwrap_or(0), std::sync::atomic::Ordering::Relaxed);
}

fn alarm_secs() -> u32 {
    ALARM_SECS.load(std::sync::atomic::Ordering::Relaxed)
}

/// Report an expired alarm as the driver's own deadline does; the trap it unwinds
/// as no longer says. The engine detail stays: its backtrace is where it stuck.
fn map_alarm(e: String) -> String {
    match ALARM_FIRED.with(|f| f.replace(false)) {
        true => sim_driver::ALARM_ABORT_ERR.to_string(),
        false => e,
    }
}

std::thread_local! {
    /// Set by the epoch-deadline callback, for [`map_alarm`].
    static ALARM_FIRED: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
}

/// Bump the alarm engine's epoch once a second, so a deadline is a second count.
fn start_epoch_ticker(engine: wasmtime::Engine) {
    std::thread::spawn(move || loop {
        std::thread::sleep(std::time::Duration::from_secs(1));
        engine.increment_epoch();
    });
}

/// One process-wide wasmtime `Engine`, so the (model-independent) runtime module
/// can be JIT-compiled once and reused, and so model modules built on background
/// threads share the same engine the run instantiates them on.
/// Two of them: see [`ALARM_SECS`].
pub fn sim_engine() -> &'static wasmtime::Engine {
    if alarm_secs() != 0 { alarm_engine() } else { plain_engine() }
}

fn alarm_engine() -> &'static wasmtime::Engine {
    static ENGINE: OnceLock<wasmtime::Engine> = OnceLock::new();
    ENGINE.get_or_init(|| {
        let engine = build_engine_cfg(|cfg| {
            cfg.epoch_interruption(true);
        });
        start_epoch_ticker(engine.clone());
        engine
    })
}

fn plain_engine() -> &'static wasmtime::Engine {
    static ENGINE: OnceLock<wasmtime::Engine> = OnceLock::new();
    ENGINE.get_or_init(|| build_engine_cfg(|_| {}))
}

fn build_engine_cfg(extra: impl FnOnce(&mut wasmtime::Config)) -> wasmtime::Engine {
    let mut cfg = wasmtime::Config::new();
    crate::tune_memory(&mut cfg);
    // A model with external "C" carries the `model_error` tag its `ext` call sites
    // catch, so the module does not validate without this.
    cfg.wasm_exceptions(true);
    // Compile module functions across threads (off by default with
    // default-features=false) — ~4x faster module compilation here.
    cfg.parallel_compilation(!crate::model::single_threaded());
    // Experimental opt-level override; default is wasmtime's `Speed`.
    match std::env::var("OMC_WASM_OPT_LEVEL").as_deref() {
        Ok("none") => { cfg.cranelift_opt_level(wasmtime::OptLevel::None); }
        Ok("speed_and_size") => { cfg.cranelift_opt_level(wasmtime::OptLevel::SpeedAndSize); }
        _ => {}
    }
    // Inline across the model/runtime boundary. Generated code reaches the
    // `rt_*` helpers as *imported* functions, and wasmtime's default is no
    // inlining at all, so a handful of instructions cost a call; `Yes` also
    // covers inter-module. Costs module compilation time, which the on-disk
    // AOT cache pays once for the runtime.
    if std::env::var("OMC_WASM_NO_INLINE").is_err() {
        cfg.compiler_inlining(wasmtime::Inlining::Yes);
    }
    extra(&mut cfg);
    wasmtime::Engine::new(&cfg).expect("wasm-jit: failed to build wasmtime engine")
}

/// The compiled runtime module, obtained once per process and shared across all
/// simulations. The runtime module is fixed, so its compiled form is cached
/// **on disk** (AOT): the first process to need it JIT-compiles and
/// `serialize`s it; every later process `deserialize`s the artifact in
/// microseconds. `deserialize` validates the artifact against the current
/// wasmtime version / engine config / target, so a stale or incompatible cache
/// is rejected and we transparently fall back to JIT (then refresh the cache).
/// One cache per engine: a module belongs to the engine that compiled it.
pub fn runtime_module() -> std::result::Result<&'static wasmtime::Module, String> {
    static PLAIN: OnceLock<std::result::Result<wasmtime::Module, String>> = OnceLock::new();
    static ALARM: OnceLock<std::result::Result<wasmtime::Module, String>> = OnceLock::new();
    let armed = alarm_secs() != 0;
    if armed { &ALARM } else { &PLAIN }
        .get_or_init(|| load_or_compile_runtime(armed))
        .as_ref()
        .map_err(|e| format!("obtaining runtime module: {e}"))
}

/// Path of the on-disk AOT cache for the runtime module. Keyed by a hash of the
/// runtime bytes + the engine opt-level so different builds/configs don't
/// collide; `deserialize` itself is the authoritative compatibility guard.
///
/// Stored under the per-user OpenModelica home (`$HOME/.openmodelica/cache`,
/// the same convention as `…/.openmodelica/binaries`): persistent across
/// reboots and not shared between users (unlike a world-writable temp dir, where
/// the sticky bit would stop other users refreshing it). Falls back to the
/// system temp dir if `$HOME` is unset or the cache dir can't be created.
fn aot_cache_key(blob: &[u8], epoch: bool) -> u64 {
    use std::hash::{Hash, Hasher};
    let mut h = std::collections::hash_map::DefaultHasher::new();
    blob.len().hash(&mut h);
    blob.hash(&mut h);
    std::env::var("OMC_WASM_OPT_LEVEL").unwrap_or_default().hash(&mut h);
    std::env::var("OMC_WASM_NO_INLINE").is_ok().hash(&mut h);
    epoch.hash(&mut h);
    h.finish()
}

fn aot_cache_path(tag: &str, key: u64) -> std::path::PathBuf {
    let home = openmodelica_util::Settings::getHomeDir(false);
    let dir = if home.is_empty() {
        Some(std::env::temp_dir())
    } else {
        let d = std::path::Path::new(&*home).join(".openmodelica").join("cache");
        std::fs::create_dir_all(&d).ok().map(|_| d)
    };
    let dir = dir.unwrap_or_else(std::env::temp_dir);
    dir.join(format!("wasmjit-{tag}-{key:016x}.cwasm"))
}

/// Compile a *fixed* wasm blob through the on-disk AOT cache: the `external "C"`
/// side libraries take ~0.7 s to compile against ~6 ms to load the artifact.
fn aot_module(engine: &wasmtime::Engine, tag: &str, blob: &[u8], epoch: bool) -> std::result::Result<wasmtime::Module, String> {
    let path = aot_cache_path(tag, aot_cache_key(blob, epoch));
    // Try the AOT artifact first (microseconds). `deserialize_file` is unsafe
    // because it trusts the artifact; it is one we produced under the cache dir,
    // and wasmtime validates version/config compatibility (erroring otherwise).
    if path.exists()
        && let Ok(m) = unsafe { wasmtime::Module::deserialize_file(engine, &path) }
    {
        return Ok(m);
    }
    // Incompatible/corrupt cache (e.g. a wasmtime upgrade): recompile over it.
    let module = wts(wasmtime::Module::new(engine, blob))?;
    // Best-effort: persist the compiled artifact for the next process. Write to
    // a temp sibling then rename, so a concurrent reader never sees a partial file.
    if let Ok(bytes) = module.serialize() {
        let tmp = path.with_extension(format!("cwasm.tmp{}", std::process::id()));
        if std::fs::write(&tmp, &bytes).is_ok() && std::fs::rename(&tmp, &path).is_err() {
            let _ = std::fs::remove_file(&tmp);
        }
    }
    Ok(module)
}

/// Compile an `external "C"` side library, memoized for the process so
/// re-simulating a model does not recompile it. A [`Library::fixed`] one also
/// takes the on-disk artifact.
pub fn library_module(
    engine: &wasmtime::Engine,
    name: &str,
    blob: &[u8],
    fixed: bool,
) -> std::result::Result<wasmtime::Module, String> {
    let key = aot_cache_key(blob, alarm_secs() != 0);
    static MEMO: OnceLock<std::sync::Mutex<HashMap<u64, wasmtime::Module>>> = OnceLock::new();
    let memo = MEMO.get_or_init(Default::default);
    if let Some(m) = memo.lock().unwrap_or_else(|e| e.into_inner()).get(&key) {
        return Ok(m.clone());
    }
    let m = match fixed {
        true => aot_module(engine, &format!("lib-{name}"), blob, alarm_secs() != 0)?,
        false => wts(wasmtime::Module::new(engine, blob))?,
    };
    memo.lock().unwrap_or_else(|e| e.into_inner()).insert(key, m.clone());
    Ok(m)
}

fn load_or_compile_runtime(epoch: bool) -> std::result::Result<wasmtime::Module, String> {
    let engine = if epoch { alarm_engine() } else { plain_engine() };
    aot_module(engine, "runtime", runtime_blob(), epoch)
}

/// JIT-compile a generated model module on the shared engine. Called either on a
/// background thread from `translateModel` (overlapping the rest of the OMC
/// pipeline) or inline from `run` as a fallback.
pub fn compile_model_module(wasm: &[u8]) -> std::result::Result<wasmtime::Module, String> {
    wts(wasmtime::Module::new(sim_engine(), wasm))
}

/// Begin compiling the fixed runtime module on a background thread, once per
/// process. The runtime module does not depend on the model, so this can be
/// started as soon as we know a wasm-jit simulation is coming (`translateModel`
/// entry) — it then compiles while `build_sim_model` generates the model bytes,
/// and `run` only waits for whatever did not overlap. Idempotent.
pub fn start_runtime_compile() {
    // Under `-n=1` compile it on first use instead, where it is timed.
    if crate::model::single_threaded() {
        return;
    }
    static STARTED: std::sync::Once = std::sync::Once::new();
    STARTED.call_once(|| {
        std::thread::spawn(|| {
            let _ = runtime_module(); // populates the OnceLock cache
        });
    });
}

/// Take the model module compiled on the background thread `translateModel`
/// spawned (joining it), or compile inline if there is no pending job.
pub fn take_compiled_model(model: &SimModel) -> std::result::Result<wasmtime::Module, String> {
    let job = model.compiled.lock().unwrap().take();
    match job {
        Some(handle) => match handle.join() {
            Ok(Ok(m)) => Ok(m),
            Ok(Err(e)) => Err(format!("background model-module compile failed: {e}")),
            Err(_) => Err("CodegenWasmJit: background model-module compile thread panicked".to_string()),
        },
        None => compile_model_module(&model.wasm),
    }
}

type Store = wasmtime::Store<WasiCtx>;

/// `SimEngine`-trait errors: collapse to the crate `&'static str` (a model
/// `assert()` is decoded downstream by `enrich_trap`).
fn wt<T>(r: std::result::Result<T, wasmtime::Error>) -> Result<T> {
    r.map_err(|e| {
        crate::set_engine_error_detail(format!("{e:?}"));
        "CodegenWasmJit: wasm engine error"
    })
}

/// Setup path: keep the real wasmtime message as a `String` for the run log.
fn wts<T, E: std::fmt::Debug>(r: std::result::Result<T, E>) -> std::result::Result<T, String> {
    r.map_err(|e| format!("wasm engine error: {e:?}"))
}

// External objects are native `void*` (e.g. a table `tableID`) that must survive
// a round-trip through 32-bit wasm variables. The host keeps them in a per-run
// registry, hands wasm an `i32` handle (index; 0 = null), and translates back on
// later calls. Simulation runs single-threaded on the host driver.
thread_local! {
    static PTR_REGISTRY: std::cell::RefCell<Vec<usize>> = const { std::cell::RefCell::new(Vec::new()) };
}
fn registry_reset() {
    PTR_REGISTRY.with(|r| {
        let mut v = r.borrow_mut();
        v.clear();
        v.push(0); // index 0 = null pointer / null handle
    });
}
fn registry_put(p: usize) -> i32 {
    if p == 0 {
        return 0;
    }
    PTR_REGISTRY.with(|r| {
        let mut v = r.borrow_mut();
        let h = v.len() as i32;
        v.push(p);
        h
    })
}
fn registry_get(h: i32) -> usize {
    if h <= 0 {
        return 0;
    }
    PTR_REGISTRY.with(|r| r.borrow().get(h as usize).copied().unwrap_or(0))
}

fn wty_valtype(w: crate::sig::WTy) -> wasmtime::ValType {
    match w {
        crate::sig::WTy::I32 => wasmtime::ValType::I32,
        crate::sig::WTy::F64 => wasmtime::ValType::F64,
    }
}

/// Why an `external "C"` function could not be found, and what to do about it. The
/// codegen's notes come out here, where a library that yielded nothing has become a
/// missing symbol.
fn unresolved_external_detail(name: &str, model: &SimModel, load_errors: &[String]) -> String {
    let searched: Vec<&str> = model
        .ext_libs
        .iter()
        .map(|l| l.name.as_str())
        .chain(model.ext_native_libs.iter().map(|s| s.as_str()))
        .chain(model.ext_archives.iter().flat_map(|a| a.archives.iter().map(|s| s.as_str())))
        .collect();
    let mut s = if searched.is_empty() {
        format!(
            "  `{name}` is in none of the model's libraries — the model declares no `Library` \
             annotation that resolves to one. Name a wasm module built with \
             `clang --target=wasm32-wasip1 -fPIC -shared`, or, for a native run, the platform \
             shared library the C target would link."
        )
    } else {
        format!(
            "  `{name}` is in none of the model's libraries ({}). Check that the library exports it \
             (`-Wl,--export-all`, or `-Wl,--export={name}`).",
            searched.join(", "),
        )
    };
    for note in model.ext_lib_notes.iter().chain(load_errors) {
        s.push_str("\n  ");
        s.push_str(note);
    }
    s
}

/// Load the libraries `sigs` are to be found in, link the model's archives and
/// build its `Include` sources. Called from `buildModel`'s compile phase; the
/// builds are cached, so instantiation reuses them.
pub fn prepare_native_externals(model: &SimModel, sigs: &[crate::sig::ExtCallSig]) -> std::result::Result<(), String> {
    let mut native = NativeExternals::default();
    for sig in sigs {
        if native.resolve(&sig.name, model).is_none() {
            return Err(unresolved_external_detail(&sig.name, model, &native.errors));
        }
    }
    Ok(())
}

/// The model's `external "C"` implementations outside wasm, resolved on demand: the
/// platform libraries its `Library` annotations name (its archives linked into
/// one), then — only once those and the process image have come up short — its
/// `Include` C source.
#[derive(Default)]
struct NativeExternals {
    handles: Vec<usize>,
    loaded: bool,
    built_includes: bool,
    errors: Vec<String>,
}

impl NativeExternals {
    fn ensure_loaded(&mut self, model: &SimModel) {
        if self.loaded {
            return;
        }
        self.loaded = true;
        let (handles, errors) = openmodelica_util::dynload::load_external_libraries(&model.ext_native_libs);
        self.handles = handles;
        self.errors = errors;
        if let Some(archives) = &model.ext_archives {
            match archives.link() {
                Ok(path) => {
                    let (h, errors) = openmodelica_util::dynload::load_external_libraries(&[path]);
                    self.handles.extend(h);
                    self.errors.extend(errors);
                }
                Err(e) => self.errors.push(e),
            }
        }
    }

    fn resolve(&mut self, name: &str, model: &SimModel) -> Option<usize> {
        self.ensure_loaded(model);
        if let Some(addr) = self.symbol(name) {
            return Some(addr);
        }
        if !self.built_includes {
            self.built_includes = true;
            if let Some(inc) = &model.ext_includes {
                let missing: Vec<crate::sig::ExtCallSig> = model
                    .ext_imports
                    .iter()
                    .filter(|s| self.symbol(&s.name).is_none())
                    .cloned()
                    .collect();
                let errors = self.errors.len();
                // A wrapper for a function the sources only declare leaves an
                // address the loader cannot resolve.
                if !self.load_includes(inc, &missing) && !missing.is_empty() {
                    self.errors.truncate(errors);
                    self.load_includes(inc, &[]);
                }
                return self.symbol(name);
            }
        }
        None
    }

    /// Build the `Include` sources with `missing` reachable, and load the result.
    /// Searched first: it is the model's own source.
    fn load_includes(&mut self, inc: &model::ExtIncludes, missing: &[crate::sig::ExtCallSig]) -> bool {
        let path = match inc.compile(missing) {
            Ok(p) => p,
            Err(e) => {
                self.errors.push(e);
                return false;
            }
        };
        let (handles, errors) = openmodelica_util::dynload::load_external_libraries(&[path]);
        let loaded = !handles.is_empty();
        self.handles.splice(0..0, handles);
        self.errors.extend(errors);
        loaded
    }

    fn symbol(&self, name: &str) -> Option<usize> {
        model::external_symbol_or_wrapper(&self.handles, name)
    }

    /// The model's own `usertab`: no `external "C"`, so never among `ext_imports`.
    fn usertab(&mut self, model: &SimModel) -> Option<usize> {
        use openmodelica_util::dynload::symbol_in;
        self.ensure_loaded(model);
        if let Some(addr) = symbol_in(&self.handles, USERTAB) {
            return Some(addr);
        }
        // Building an `Include` that defines none is a compiler run for nothing.
        let inc = model.ext_includes.as_ref()?;
        if self.built_includes || !inc.sources.iter().any(|s| s.contains(USERTAB)) {
            return None;
        }
        self.built_includes = true;
        self.load_includes(inc, &[]);
        symbol_in(&self.handles, USERTAB)
    }
}

const USERTAB: &str = "usertab";

/// Define the model's external "C" function imports (wasm module `ext`) from the
/// host. Uses the model's `ext_imports` (the C-call `SigTy` signature) rather than
/// the wasm `FuncType`, because the latter can't distinguish an `i32` that is a
/// String/array/pointer handle from a plain Integer. Resolves each `extName`
/// natively and binds a marshalling trampoline sharing the runtime's linear
/// memory (`memory`).
fn define_external_imports(
    linker: &mut wasmtime::Linker<WasiCtx>,
    store: &mut wasmtime::Store<WasiCtx>,
    model: &SimModel,
    memory: wasmtime::Memory,
    rt: &crate::dylink_engine::ExtRt,
    libs: &crate::dylink_engine::Loaded,
) -> Result<()> {
    registry_reset();
    sim_driver::clear_runtime_error();
    openmodelica_util::dynload::install_modelica_message_interception(
        openmodelica_modelica_utilities::modelica_message_hook,
        openmodelica_modelica_utilities::modelica_warning_hook,
    );
    let engine = linker.engine().clone();
    let mut native = NativeExternals::default();
    for sig in &model.ext_imports {
        let functype = wasmtime::FuncType::new(
            &engine,
            sig.wasm_params().iter().map(|s| wty_valtype(s.wty())),
            sig.wasm_results().iter().map(|s| wty_valtype(s.wty())),
        );
        // The model's own libraries shadow a same-named symbol in the process.
        if let Some(target) = libs.func_or_addr(&mut *store, &sig.name) {
            if let Some(f) = crate::dylink_engine::bind_in_wasm_external(store, sig, &functype, target, rt)
                .map_err(|_| "external \"C\": cannot bind a library function")?
            {
                wt(linker.define(&mut *store, "ext", &sig.name, f))?;
                continue;
            }
        }
        let addr = native.resolve(&sig.name, model).ok_or_else(|| {
            crate::set_engine_error_detail(unresolved_external_detail(&sig.name, model, &native.errors));
            "external \"C\" function not found in any loaded library"
        })?;
        define_native_external(linker, sig, functype, addr, memory, rt)?;
    }
    // No `external "C"` means no `Include`/`Library`, hence no `usertab`.
    let usertab = (!model.ext_imports.is_empty()).then(|| native.usertab(model)).flatten();
    openmodelica_util::dynload::set_usertab(usertab);
    // A library that had to define its own `RHSFinalFlag` reads that copy.
    openmodelica_util::dynload::register_rhs_final_flag(&native.handles);
    Ok(())
}

/// One C argument, held by value so `avalue` can point at it.
enum Slot {
    I(i64),
    F(f64),
    P(*mut core::ffi::c_void),
}

// Scratch for [`call_external`]'s argument list, taken and put back so a nested
// call (or one that unwound) just allocates its own.
thread_local! {
    static SLOT_SCRATCH: std::cell::Cell<Vec<Slot>> = const { std::cell::Cell::new(Vec::new()) };
    static AVALUE_SCRATCH: std::cell::Cell<Vec<*mut core::ffi::c_void>> =
        const { std::cell::Cell::new(Vec::new()) };
}

/// libffi's prepared call interface for one external, built once when the import
/// is bound rather than per call — `ffi_prep_cif` classifies the whole argument
/// list.
///
/// A prepared `ffi_cif` is immutable and `ffi_call` only reads it, so sharing it
/// is sound even though it holds pointers into the type list it owns.
struct PreparedCif {
    cif: libffi::middle::Cif,
    /// libffi widens a return narrower than `ffi_arg`, so never under 8 bytes.
    ret_size: usize,
}
unsafe impl Send for PreparedCif {}
unsafe impl Sync for PreparedCif {}

/// The C type of each argument in `ffi_call` order — the classification
/// [`call_external`]'s phase 1 marshals into, derived from the signature alone.
fn ffi_arg_types(sig: &crate::sig::ExtCallSig) -> Vec<libffi::middle::Type> {
    use crate::sig::SigTy;
    use libffi::middle::Type;
    let fortran = sig.lang == crate::sig::ExtLang::Fortran77;
    sig.args
        .iter()
        .map(|(ty, is_out)| match ty {
            // An `_Out_` scalar/string/record gets a scratch cell passed by pointer;
            // an output array is filled in place, like an input one.
            _ if *is_out && !matches!(ty, SigTy::Array { .. }) => Type::pointer(),
            // FORTRAN 77 takes every argument by reference.
            SigTy::Real if !fortran => Type::f64(),
            SigTy::Int | SigTy::Bool if !fortran => Type::i64(),
            _ => Type::pointer(),
        })
        .collect()
}

/// Prepare the call interface, or `None` for a return type [`call_external`]
/// refuses — it reports that per call, as before.
fn prepare_cif(sig: &crate::sig::ExtCallSig) -> Option<PreparedCif> {
    use crate::sig::SigTy;
    use libffi::middle::{Cif, Type};
    let (ret_type, ret_size) = match &sig.ret {
        None => (Type::void(), 8),
        Some(SigTy::Real) => (Type::f64(), 8),
        Some(SigTy::Int) | Some(SigTy::Bool) => (Type::i32(), 8),
        Some(SigTy::Str) | Some(SigTy::Ptr) => (Type::pointer(), 8),
        // A member-less struct is no C type `ffi_prep_cif` accepts.
        Some(SigTy::Record { fields, .. }) if !fields.is_empty() => {
            (c_record_ffi_type(fields), c_record_layout(fields).size as usize)
        }
        Some(_) => return None,
    };
    Some(PreparedCif { cif: Cif::new(ffi_arg_types(sig), ret_type), ret_size })
}

/// Bind `ext.<sig.name>` to native `addr` through the libffi trampoline. Shared
/// with the `-d=gen` function JIT, whose externals resolve the same way.
pub fn define_native_external(
    linker: &mut wasmtime::Linker<WasiCtx>,
    sig: &crate::sig::ExtCallSig,
    functype: wasmtime::FuncType,
    addr: usize,
    memory: wasmtime::Memory,
    rt: &crate::dylink_engine::ExtRt,
) -> Result<()> {
    let name = sig.name.clone();
    let sig = sig.clone();
    let rt = rt.clone();
    let prepared = prepare_cif(&sig);
    wt(linker.func_new("ext", &name, functype, move |mut caller, args, rets| {
        // Safety: `addr` resolves `sig.name`; the `Cif` matches the validated sig.
        unsafe { call_external(addr, &sig, prepared.as_ref(), &mut caller, memory, &rt, args, rets) }
            .map_err(|e| wasmtime::Error::msg(format!("{e}")))
    }))?;
    Ok(())
}

/// The `print` builtin's host import (`rt.rt_print`): read the String handle's
/// bytes from the shared linear memory and write them to the model's captured
/// stdout. The handle stays owned by the generated code, which releases it after.
fn define_print_import(linker: &mut wasmtime::Linker<WasiCtx>, memory: wasmtime::Memory) -> Result<()> {
    wt(linker.func_wrap("rt", "rt_print", move |caller: wasmtime::Caller<'_, WasiCtx>, handle: i32| {
        if handle == 0 {
            return;
        }
        // String layout: [refcount:u32][len:u32][utf8]; bytes start at handle + 8.
        let data = memory.data(&caller);
        let h = handle as usize;
        let Some(lenb) = data.get(h + 4..h + 8) else { return };
        let len = u32::from_le_bytes(lenb.try_into().unwrap()) as usize;
        if let Some(bytes) = data.get(h + 8..h + 8 + len) {
            openmodelica_wasi::wasi::stdout_write(bytes);
        }
    }))?;
    Ok(())
}

/// Checkpoint bracketing one external "C" call, so a `ModelicaError` the
/// nonlinear solver recovers from leaves no message behind.
const EXT_CHECKPOINT: arcstr::ArcStr = arcstr::literal!("wasm-jit external \"C\"");

/// Call native external `addr` through libffi, marshalling by the C-call
/// [`ExtCallSig`]. Input args (in `extArgs` order) come from the wasm parameters:
/// scalars (Real→f64, Integer/Boolean→i64) by value; `Str` as a NUL-terminated
/// `char*` copied from the wasm String; `Ptr` (external object) via the handle
/// registry; `Array` as a native pointer into the runtime array's row-major data.
/// A record goes as a pointer to a native copy of C's `<record>_external` struct.
/// Each `_Out_` pointer arg gets a native scratch cell — one C value wide, or the
/// record's whole struct — whose address is passed to C. The wasm results are the
/// C return value (if any) then each output cell's written value, in order —
/// scalars directly, external-object pointers via the registry, `char*` outputs
/// copied into a fresh in-wasm String (`rt_str_new`+`rt_str_data`) and a struct
/// into a fresh record object. A `String[…]` output array is written back
/// element by element (C's `unpack_string_array`). The whole call is bracketed by
/// `sim_external_begin/end` so any `ModelicaAllocateString` uses our arena.
///
/// A `FORTRAN 77` external takes every argument by reference and its arrays
/// column-major — the marshalling `extFunCallF77` puts in the generated wrapper.
unsafe fn call_external(
    addr: usize,
    sig: &crate::sig::ExtCallSig,
    prepared: Option<&PreparedCif>,
    caller: &mut wasmtime::Caller<'_, WasiCtx>,
    memory: wasmtime::Memory,
    rt: &crate::dylink_engine::ExtRt,
    args: &[wasmtime::Val],
    rets: &mut [wasmtime::Val],
) -> Result<()> {
    use crate::sig::SigTy;
    use core::ffi::c_void;

    // Raw libffi call, declared `C-unwind` so a Rust panic raised by the
    // ModelicaError interception (`omrs_runtime_abort`) can unwind back through
    // the external C frames to the `catch_runtime_error` below, rather than the
    // runtime's simulation-side `longjmp` (into an unset jump buffer → segfault).
    unsafe extern "C-unwind" {
        fn ffi_call(
            cif: *mut c_void,
            f: Option<unsafe extern "C-unwind" fn()>,
            rvalue: *mut c_void,
            avalue: *mut *mut c_void,
        );
    }

    let fortran = sig.lang == crate::sig::ExtLang::Fortran77;
    // Reused across calls (put back below): one heap allocation each otherwise.
    let mut slots: Vec<Slot> = SLOT_SCRATCH.with(|c| c.take());
    let mut avalue: Vec<*mut c_void> = AVALUE_SCRATCH.with(|c| c.take());
    slots.clear();
    avalue.clear();
    let mut cstrings: Vec<std::ffi::CString> = Vec::new();
    // `const char**` argument vectors, kept alive alongside the strings they point at.
    let mut str_arrays: Vec<Vec<*const std::os::raw::c_char>> = Vec::new();
    // Output `String[…]`: (index into `str_arrays`, wasm element-area offset).
    let mut str_out_arrays: Vec<(usize, usize)> = Vec::new();
    // One native cell per `_Out_` pointer arg, in output order; the C call writes
    // through the pointer we pass.
    let mut out_cells: Vec<(SigTy, Cell)> = Vec::new();
    // Input cells kept alive for the call: record structs, Fortran scalars.
    let mut in_cells: Vec<Cell> = Vec::new();
    // (buffer, wasm element-area offset, dims, element size, is output).
    let mut f77_arrays: Vec<(Vec<u8>, usize, Vec<usize>, usize, bool)> = Vec::new();
    let mut in_i = 0usize;
    // Phase 1: build the C argument list. Reads wasm memory for Str/Array inputs;
    // the borrow ends with this block (only owned copies / raw addresses escape).
    {
        let mem = memory.data(&*caller);
        for (ty, is_out) in &sig.args {
            // Scalar/string outputs get an `_Out_` scratch cell; array outputs are
            // pre-allocated on the wasm side and passed by pointer (filled in place,
            // like an input array — handled by the `Array` arm below).
            if *is_out && !matches!(ty, SigTy::Array { .. }) {
                let mut cell = match ty {
                    SigTy::Real | SigTy::Int | SigTy::Bool | SigTy::Str | SigTy::Ptr => Cell::new(8),
                    SigTy::Record { fields, .. } => Cell::new(c_record_layout(fields).size as usize),
                    _ => return Err("CodegenWasmJit: external \"C\" : output argument type not marshalled"),
                };
                slots.push(Slot::P(cell.ptr()));
                out_cells.push((ty.clone(), cell));
                continue;
            }
            let v = &args[in_i];
            in_i += 1;
            // Fortran passes scalars by reference; give each one a native cell.
            if fortran && matches!(ty, SigTy::Real | SigTy::Int | SigTy::Bool) {
                let mut cell = Cell::new(8);
                match ty {
                    SigTy::Real => cell.bytes_mut()[..8].copy_from_slice(&v.unwrap_f64().to_le_bytes()),
                    _ => cell.bytes_mut()[..4].copy_from_slice(&v.unwrap_i32().to_le_bytes()),
                }
                slots.push(Slot::P(cell.ptr()));
                in_cells.push(cell);
                continue;
            }
            match ty {
                SigTy::Real => {
                    slots.push(Slot::F(v.unwrap_f64()));
                }
                // Marshalled 64-bit: on SysV x86-64 every integer/pointer arg fills
                // a full 64-bit slot, correct for `int`/`long`/`size_t` alike.
                SigTy::Int | SigTy::Bool => {
                    slots.push(Slot::I(v.unwrap_i32() as i64));
                }
                SigTy::Str => {
                    let off = v.unwrap_i32() as usize;
                    let len = u32::from_le_bytes(mem[off + 4..off + 8].try_into().unwrap()) as usize;
                    let cs = std::ffi::CString::new(&mem[off + 8..off + 8 + len])
                        .map_err(|_| "external \"C\" : string argument has an interior NUL")?;
                    slots.push(Slot::P(cs.as_ptr() as *mut c_void));
                    cstrings.push(cs);
                }
                SigTy::Ptr => {
                    slots.push(Slot::P(registry_get(v.unwrap_i32()) as *mut c_void));
                }
                // Array: a native pointer to the runtime array's contiguous
                // row-major data (`align8(16 + ndims*4)` past the header). The C
                // callee reads it in place; the memory can't grow during the call.
                // A rank-2-or-higher Fortran array goes as a column-major copy.
                SigTy::Array { elem, .. } => {
                    let off = v.unwrap_i32() as usize;
                    let (dims, data_off) = crate::host::array_abi::dims_and_data(mem, off)
                        .ok_or("external \"C\" : malformed array argument")?;
                    let base = off + data_off;
                    // Only scalar elements are already a native array. A `String[:]`
                    // is in-wasm handles, not the `const char**` C declares, so it
                    // is rebuilt (C's `data_of_string_c89_array`); anything else has
                    // no C form at all.
                    if let SigTy::Str = &**elem {
                        let n = dims.iter().product::<usize>();
                        let mut ptrs: Vec<*const std::os::raw::c_char> = Vec::with_capacity(n);
                        for k in 0..n {
                            let h = u32::from_le_bytes(mem[base + k * 4..base + k * 4 + 4].try_into().unwrap()) as usize;
                            // Never filled (a fresh output array): C sees "".
                            let bytes: &[u8] = if h == 0 {
                                &[]
                            } else {
                                let len = u32::from_le_bytes(mem[h + 4..h + 8].try_into().unwrap()) as usize;
                                &mem[h + 8..h + 8 + len]
                            };
                            let cs = std::ffi::CString::new(bytes)
                                .map_err(|_| "external \"C\" : string argument has an interior NUL")?;
                            ptrs.push(cs.as_ptr());
                            cstrings.push(cs);
                        }
                        slots.push(Slot::P(ptrs.as_mut_ptr() as *mut c_void));
                        if *is_out {
                            str_out_arrays.push((str_arrays.len(), base));
                        }
                        str_arrays.push(ptrs);
                        continue;
                    }
                    if !matches!(&**elem, SigTy::Real | SigTy::Int | SigTy::Bool) {
                        return Err("CodegenWasmJit: external \"C\" : array element type not marshalled");
                    }
                    if fortran && dims.len() > 1 {
                        let esz = crate::host::array_abi::elem_size(elem);
                        let n = dims.iter().product::<usize>() * esz;
                        let mut buf = vec![0u8; n];
                        crate::host::array_abi::reorder(&mem[base..base + n], &mut buf, &dims, esz, true);
                        slots.push(Slot::P(buf.as_mut_ptr() as *mut c_void));
                        f77_arrays.push((buf, base, dims, esz, *is_out));
                    } else {
                        slots.push(Slot::P((mem.as_ptr() as usize + base) as *mut c_void));
                    }
                }
                // By pointer, as C's `_copy_to_external` builds it.
                SigTy::Record { fields, .. } => {
                    let mut cell = Cell::new(c_record_layout(fields).size as usize);
                    record_to_native(mem, fields, v.unwrap_i32() as usize, cell.bytes_mut(), &mut cstrings)?;
                    slots.push(Slot::P(cell.ptr()));
                    in_cells.push(cell);
                }
                other => return Err("CodegenWasmJit: external \"C\" : input argument type not yet marshalled"),
            }
        }
    }
    // libffi `avalue`: a pointer to each slot's stored value.
    avalue.extend(slots.iter_mut().map(|s| match s {
        Slot::I(x) => x as *mut i64 as *mut c_void,
        Slot::F(x) => x as *mut f64 as *mut c_void,
        Slot::P(x) => x as *mut *mut c_void as *mut c_void,
    }));
    // Prepared when the import was bound; `None` is a return type not marshalled.
    let Some(prepared) = prepared else {
        return Err("CodegenWasmJit: external \"C\" : return type not yet marshalled");
    };
    let mut rvalue = Cell::new(prepared.ret_size);
    let cif_ptr = prepared.cif.as_raw_ptr() as *mut c_void;
    let target = unsafe { std::mem::transmute::<usize, unsafe extern "C-unwind" fn()>(addr) };
    let rvalue_ptr = rvalue.ptr();
    let avalue_ptr = avalue.as_mut_ptr();
    // Any `ModelicaAllocateString` the callee makes for a string result must come
    // from our arena (never the C runtime); freed by `sim_external_end` once the
    // results below are copied into in-wasm strings.
    openmodelica_modelica_utilities::sim_external_begin();
    openmodelica_error::ErrorExt::setCheckpoint(EXT_CHECKPOINT);
    let ok = openmodelica_error::ErrorExt::catch_runtime_error(|| unsafe {
        ffi_call(cif_ptr, Some(target), rvalue_ptr, avalue_ptr);
    });
    if ok.is_err() {
        openmodelica_modelica_utilities::sim_external_end();
        // A `ModelicaError` recorded its message in the Error buffer and unwound
        // here as a panic. C's `throwStreamPrint` is caught by a nonlinear solver,
        // so back the trial off first, dropping the message it will not fail on.
        if let Some(nls) = &rt.nls
            && wt(nls.recovering(caller))?
        {
            openmodelica_error::ErrorExt::rollBack(EXT_CHECKPOINT);
            wt(nls.note(caller))?;
            return wt(zero_results(sig, caller, &rt.str_new, rets));
        }
        let msg = openmodelica_error::ErrorExt::take_last_runtime_error();
        // A run reports itself through its log alone, as C's separate executable
        // does. The `-d=gen` function JIT (no solver, hence no `nls`) has no log:
        // there the buffer is how the error reaches `getErrorString`.
        if rt.nls.is_some() {
            openmodelica_error::ErrorExt::rollBack(EXT_CHECKPOINT);
            sim_driver::note_runtime_error(&msg.unwrap_or_else(|| format!("external \"C\" `{}` failed", sig.name)));
        } else {
            openmodelica_error::ErrorExt::delCheckpoint(EXT_CHECKPOINT);
        }
        return Err("CodegenWasmJit: external \"C\" raised a runtime error");
    }
    openmodelica_error::ErrorExt::delCheckpoint(EXT_CHECKPOINT);

    // C's `convert_alloc_*_from_f77`.
    {
        let mem = memory.data_mut(&mut *caller);
        for (buf, base, dims, esz, is_out) in &f77_arrays {
            if *is_out {
                crate::host::array_abi::reorder(buf, &mut mem[*base..*base + buf.len()], dims, *esz, false);
            }
        }
    }

    // C's `unpack_string_array`. An element the callee did not write still points
    // at our own input copy, so `cstrings` outlives this.
    for (k, base) in &str_out_arrays {
        for (i, cptr) in str_arrays[*k].iter().enumerate() {
            let bytes: &[u8] =
                if cptr.is_null() { &[] } else { unsafe { std::ffi::CStr::from_ptr(*cptr) }.to_bytes() };
            let soff = wt(rt.str_new.call(&mut *caller, bytes.len() as u32))?;
            let doff = wt(rt.str_data.call(&mut *caller, soff))? as usize;
            let slot = base + i * 4;
            let old = {
                let mem = memory.data_mut(&mut *caller);
                mem[doff..doff + bytes.len()].copy_from_slice(bytes);
                let old = u32::from_le_bytes(mem[slot..slot + 4].try_into().unwrap());
                mem[slot..slot + 4].copy_from_slice(&soff.to_le_bytes());
                old
            };
            if old != 0 {
                wt(rt.release.call(&mut *caller, old))?;
            }
        }
    }

    let mut ri = 0usize;
    if let Some(ret_ty) = &sig.ret {
        rets[ri] = ext_result(ret_ty, rvalue.bytes(), caller, memory, rt)?;
        ri += 1;
    }
    for (ty, cell) in &out_cells {
        rets[ri] = ext_result(ty, cell.bytes(), caller, memory, rt)?;
        ri += 1;
    }
    // A `char*` an output still points at is one the callee never wrote.
    drop(cstrings);
    openmodelica_modelica_utilities::sim_external_end();
    // Hand the buffers back for the next call, emptied so no stale pointer is kept.
    slots.clear();
    avalue.clear();
    SLOT_SCRATCH.with(|c| c.set(slots));
    AVALUE_SCRATCH.with(|c| c.set(avalue));
    Ok(())
}

/// An 8-aligned native scratch cell: one C value, or one record's C struct.
struct Cell(Vec<u64>);

impl Cell {
    fn new(size: usize) -> Self {
        Cell(vec![0; size.div_ceil(8).max(1)])
    }
    fn ptr(&mut self) -> *mut core::ffi::c_void {
        self.0.as_mut_ptr().cast()
    }
    fn bytes(&self) -> &[u8] {
        // Safety: an initialized `Vec<u64>` is `len * 8` initialized bytes.
        unsafe { std::slice::from_raw_parts(self.0.as_ptr().cast(), self.0.len() * 8) }
    }
    fn bytes_mut(&mut self) -> &mut [u8] {
        // Safety: as `bytes`; `u64` has no invalid bit pattern.
        unsafe { std::slice::from_raw_parts_mut(self.0.as_mut_ptr().cast(), self.0.len() * 8) }
    }
}

/// The record's `<record>_external` in the host ABI.
fn c_record_layout(fields: &[(arcstr::ArcStr, crate::sig::SigTy)]) -> crate::sig::CRecordLayout {
    crate::sig::c_record_layout(fields, size_of::<usize>() as u32)
}

/// The same struct as a libffi type, for a by-value return.
fn c_record_ffi_type(fields: &[(arcstr::ArcStr, crate::sig::SigTy)]) -> libffi::middle::Type {
    use crate::sig::SigTy;
    use libffi::middle::Type;
    Type::structure(fields.iter().map(|(_, t)| match t {
        SigTy::Real => Type::f64(),
        SigTy::Int | SigTy::Bool => Type::i32(),
        SigTy::Record { fields, .. } => c_record_ffi_type(fields),
        _ => Type::pointer(),
    }))
}

/// Write the record object at `handle` into the C struct `dst`, as C's
/// `_copy_to_external` does. A String member becomes a NUL-terminated copy kept in
/// `cstrings`; an array member passes its elements, so the callee writes the
/// model's own array in place.
fn record_to_native(
    mem: &[u8],
    fields: &[(arcstr::ArcStr, crate::sig::SigTy)],
    handle: usize,
    dst: &mut [u8],
    cstrings: &mut Vec<std::ffi::CString>,
) -> Result<()> {
    use crate::sig::SigTy;
    let layout = crate::sig::record_layout(fields);
    let c = c_record_layout(fields);
    let word = |at: usize| u32::from_le_bytes(mem[at..at + 4].try_into().unwrap()) as usize;
    let ptr = |dst: &mut [u8], at: usize, p: usize| dst[at..at + size_of::<usize>()].copy_from_slice(&p.to_le_bytes());
    for (i, (_, ty)) in fields.iter().enumerate() {
        let src = handle + (layout.data_off + layout.field_off[i]) as usize;
        let at = c.offsets[i] as usize;
        match ty {
            SigTy::Real => dst[at..at + 8].copy_from_slice(&mem[src..src + 8]),
            SigTy::Int | SigTy::Bool => dst[at..at + 4].copy_from_slice(&mem[src..src + 4]),
            SigTy::Ptr => ptr(dst, at, registry_get(word(src) as i32)),
            SigTy::Str => {
                let h = word(src);
                // Never filled (a fresh record): C sees "".
                let bytes: &[u8] = if h == 0 { &[] } else { &mem[h + 8..h + 8 + word(h + 4)] };
                let cs = std::ffi::CString::new(bytes)
                    .map_err(|_| "external \"C\" : string argument has an interior NUL")?;
                ptr(dst, at, cs.as_ptr() as usize);
                cstrings.push(cs);
            }
            SigTy::Array { .. } => {
                let h = word(src);
                let (_, data_off) = crate::host::array_abi::dims_and_data(mem, h)
                    .ok_or("external \"C\" : malformed array field")?;
                ptr(dst, at, mem.as_ptr() as usize + h + data_off);
            }
            SigTy::Record { fields: inner, .. } => {
                let end = at + c_record_layout(inner).size as usize;
                record_to_native(mem, inner, word(src), &mut dst[at..end], cstrings)?;
            }
            other => return Err("CodegenWasmJit: external \"C\" : record field type not marshalled"),
        }
    }
    Ok(())
}

/// The inverse (C's `_copy_from_external`): a fresh record object holding what the
/// callee wrote into `src`. An array member has no inverse — this record is a new
/// one, and the callee wrote the model's array in place — as in C, which asserts.
fn record_from_native(
    caller: &mut wasmtime::Caller<'_, WasiCtx>,
    memory: wasmtime::Memory,
    rt: &crate::dylink_engine::ExtRt,
    fields: &[(arcstr::ArcStr, crate::sig::SigTy)],
    src: &[u8],
) -> Result<u32> {
    use crate::sig::SigTy;
    let layout = crate::sig::record_layout(fields);
    let c = c_record_layout(fields);
    let handle = wt(rt.record_new.call(&mut *caller, (layout.heap.len() as u32, layout.size)))?;
    // The inline table the runtime releases the record's heap fields by.
    for (k, (kind, off)) in layout.heap.iter().enumerate() {
        let at = handle as usize + 8 + k * 8;
        let mem = memory.data_mut(&mut *caller);
        mem[at..at + 4].copy_from_slice(&kind.to_le_bytes());
        mem[at + 4..at + 8].copy_from_slice(&off.to_le_bytes());
    }
    let word = |src: &[u8], at: usize| usize::from_le_bytes(src[at..at + size_of::<usize>()].try_into().unwrap());
    for (i, (_, ty)) in fields.iter().enumerate() {
        let at = c.offsets[i] as usize;
        let dst = (handle + layout.data_off + layout.field_off[i]) as usize;
        // Taken before the store: a String/record member re-enters the runtime,
        // which may grow the memory `data_mut` hands out.
        let value: [u8; 4] = match ty {
            SigTy::Real => {
                memory.data_mut(&mut *caller)[dst..dst + 8].copy_from_slice(&src[at..at + 8]);
                continue;
            }
            SigTy::Int | SigTy::Bool => src[at..at + 4].try_into().unwrap(),
            SigTy::Ptr => registry_put(word(src, at)).to_le_bytes(),
            SigTy::Str => wasm_string(caller, memory, rt, word(src, at) as *const std::os::raw::c_char)?.to_le_bytes(),
            SigTy::Record { fields: inner, .. } => {
                record_from_native(caller, memory, rt, inner, &src[at..])?.to_le_bytes()
            }
            other => return Err("CodegenWasmJit: external \"C\" : record field type not marshalled"),
        };
        memory.data_mut(&mut *caller)[dst..dst + 4].copy_from_slice(&value);
    }
    Ok(handle)
}

/// Build an in-wasm String from a native `char*` (NUL-terminated), returning its
/// offset. Re-enters the runtime (`rt_str_new` may grow memory, so `data_mut` is
/// re-fetched after).
fn wasm_string(
    caller: &mut wasmtime::Caller<'_, WasiCtx>,
    memory: wasmtime::Memory,
    rt: &crate::dylink_engine::ExtRt,
    cptr: *const std::os::raw::c_char,
) -> Result<u32> {
    let bytes: &[u8] = if cptr.is_null() { &[] } else { unsafe { std::ffi::CStr::from_ptr(cptr) }.to_bytes() };
    let soff = wt(rt.str_new.call(&mut *caller, bytes.len() as u32))?;
    let doff = wt(rt.str_data.call(&mut *caller, soff))? as usize;
    memory.data_mut(&mut *caller)[doff..doff + bytes.len()].copy_from_slice(bytes);
    Ok(soff)
}

/// One C result — the return value or an `_Out_` cell — as its wasm value.
fn ext_result(
    ty: &crate::sig::SigTy,
    cell: &[u8],
    caller: &mut wasmtime::Caller<'_, WasiCtx>,
    memory: wasmtime::Memory,
    rt: &crate::dylink_engine::ExtRt,
) -> Result<wasmtime::Val> {
    use crate::sig::SigTy;
    use wasmtime::Val;
    let word = || usize::from_le_bytes(cell[..8].try_into().unwrap());
    Ok(match ty {
        SigTy::Real => Val::F64(f64::from_le_bytes(cell[..8].try_into().unwrap()).to_bits()),
        SigTy::Int | SigTy::Bool => Val::I32(i32::from_le_bytes(cell[..4].try_into().unwrap())),
        SigTy::Ptr => Val::I32(registry_put(word())),
        SigTy::Str => Val::I32(wasm_string(caller, memory, rt, word() as *const std::os::raw::c_char)? as i32),
        SigTy::Record { fields, .. } => Val::I32(record_from_native(caller, memory, rt, fields, cell)? as i32),
        other => return Err("external \"C\": result type not marshalled"),
    })
}


pub fn run(model: &SimModel, meta: &SimMeta) -> std::result::Result<sim_driver::RunResult, String> {
    let bench = crate::model::sim_bench_enabled();
    // The in-wasm session driver (`rt_sim_*`) reaches the model wasm->wasm; see
    // `crate::model::inwasm_driver_enabled` for when it is used.
    if crate::model::inwasm_driver_enabled() {
        return run_inwasm(model, bench);
    }
    let (mut engine, sim_data) = build_engine(model, meta)?;
    // `OMC_WASM_SIM_DRIVER=host` forces the native Euler loop over the in-wasm one.
    let host_driven = std::env::var("OMC_WASM_SIM_DRIVER").map(|v| v == "host").unwrap_or(false);
    let n_steps = meta.n_intervals;
    let n_rows = n_steps + 1;
    let t0 = Instant::now();
    let (mut result, driver_label) =
        match sim_driver::drive(&mut *engine, meta, sim_data, meta.method.as_str(), host_driven, bench) {
            Ok(v) => v,
            Err(e) => {
                return Err(map_alarm(e.to_string()));
            }
        };
    // The solves ran host-side (`rt_host_lin_solve`) or in-wasm (KLU/rsparse);
    // either way the driver's stats don't see them, so surface both counters.
    result.stats.lin_solves = crate::host::lin_solve::count() + engine.lin_solves();
    if bench {
        let elapsed = t0.elapsed();
        eprintln!(
            "wasm-jit sim [{}]: integrate {:?} ({} intervals, {:.2} us/interval)",
            driver_label, elapsed, n_steps, elapsed.as_secs_f64() * 1e6 / (n_rows.max(1) as f64),
        );
    }
    Ok(result)
}

/// The runtime's `LOG_STATS_V` per-system table, decoded out of linear memory.
/// Empty when the runtime never armed it (`rt_stats_start`).
fn read_sys_stats(
    store: &mut Store,
    rt_inst: &wasmtime::Instance,
    memory: &wasmtime::Memory,
) -> Vec<openmodelica_sim_meta::sysstat::SysStat> {
    let (Ok(ptr), Ok(len)) = (
        rt_inst.get_typed_func::<(), u32>(&mut *store, "rt_sys_stats_ptr"),
        rt_inst.get_typed_func::<(), u32>(&mut *store, "rt_sys_stats_len"),
    ) else {
        return Vec::new();
    };
    let (Ok(n), Ok(addr)) = (len.call(&mut *store, ()), ptr.call(&mut *store, ())) else {
        return Vec::new();
    };
    let mut bytes = vec![0u8; n as usize * 8];
    if memory.read(&*store, addr as usize, &mut bytes).is_err() {
        return Vec::new();
    }
    let words: Vec<f64> =
        bytes.chunks_exact(8).map(|c| f64::from_le_bytes(c.try_into().unwrap())).collect();
    openmodelica_sim_meta::sysstat::decode(&words)
}

/// One-shot in-wasm run (used by [`run`] under `OMC_WASM_INWASM_DRIVER`): start,
/// pump to completion with an unbounded budget, read the result.
fn run_inwasm(model: &SimModel, bench: bool) -> std::result::Result<sim_driver::RunResult, String> {
    let t0 = Instant::now();
    let mut sess = build_inwasm_session(model)?;
    loop {
        match sess.advance(f64::INFINITY).map_err(|e| map_alarm(e.to_string()))? {
            0 => continue,
            3 => return Err("CodegenWasmJit: in-wasm simulation cancelled".to_string()),
            _ => break, // 1 done, 2 terminated
        }
    }
    let result = sess.take_result()?;
    if bench {
        let n = model.n_intervals;
        eprintln!(
            "wasm-jit sim [in-wasm]: integrate {:?} ({} intervals), {} steps, {} residual evals",
            t0.elapsed(), n, result.stats.steps, result.stats.res_evals
        );
    }
    Ok(result)
}

/// A runtime+model pair instantiated into one store, sharing the runtime's linear
/// memory. Common to the host-driver path ([`build_engine`]) and the in-wasm
/// session ([`build_inwasm_session`]).
struct Instantiated {
    store: Store,
    rt_inst: wasmtime::Instance,
    instance: wasmtime::Instance,
    memory: wasmtime::Memory,
    rt_alloc: wasmtime::TypedFunc<u32, u32>,
}

/// Compile/join the modules and instantiate them (runtime first, then model,
/// sharing the runtime's `memory`).
fn instantiate_modules(model: &SimModel, meta: &SimMeta) -> std::result::Result<Instantiated, String> {
    let bench = crate::model::sim_bench_enabled();
    crate::host::lin_solve::reset(); // drop the previous run's host-side LSS cache
    let engine = sim_engine();
    let mut linker = wasmtime::Linker::new(engine);
    add_host_builtins(&mut linker)?;
    // The interactive runtime is the std wasip1 build; its `wasi_snapshot_preview1`
    // imports (panic `fd_write`, `proc_exit`, `environ_*`) are served by the shared
    // shim. Harmless for the no_std fallback, which imports none of them.
    wasi_shim::add_to_linker(&mut linker)?;

    // Phase 1: obtain the compiled modules. The runtime module is compiled once
    // per process (cached); the model module was JIT-compiled on a background
    // thread spawned by `translateModel` (overlapping the rest of the OMC
    // pipeline) — here we just join it. If no background job is present (e.g. a
    // direct call), compile inline as a fallback.
    let t_compile = Instant::now();
    let runtime_module = runtime_module()?;
    let rt_compile = t_compile.elapsed();
    // Prefer the module already prepared by `finishCompile` (buildModel's
    // compile phase, counted as `timeCompile`); otherwise join/compile here.
    let t_model = Instant::now();
    // Clone, not take: keep the module cached so a resimulate reuses it instead
    // of recompiling the whole model.
    let prepared = model.prepared.lock().unwrap().clone();
    let model_module = match prepared {
        Some(m) => m,
        None => take_compiled_model(model)?,
    };
    // A hard alarm armed after the compile switches engines under the module.
    let model_module = if wasmtime::Engine::same(model_module.engine(), engine) {
        model_module
    } else {
        wts(wasmtime::Module::new(engine, &model.wasm))?
    };
    // `take_compiled_model` consumes the job, so cache it here too: `finishCompile`
    // does not run for a resimulate, which would then recompile on every run.
    *model.prepared.lock().unwrap() = Some(model_module.clone());
    let model_compile = t_model.elapsed();
    let compile_time = t_compile.elapsed();
    if bench {
        eprintln!(
            "wasm-jit sim: module fetch — runtime.wasm ({} KB) {:?} (cached/compiled), model.wasm ({} KB) {:?} (join/compile)",
            runtime_blob().len() / 1024, rt_compile, model.wasm.len() / 1024, model_compile,
        );
    }

    // Phase 2: instantiate (sharing the runtime's linear memory).
    let t_inst = Instant::now();
    let mut store = wasmtime::Store::new(engine, WasiCtx::new("/", Vec::new()));
    if let secs @ 1.. = alarm_secs() {
        ALARM_FIRED.with(|f| f.set(false));
        store.set_epoch_deadline(secs as u64);
        store.epoch_deadline_callback(move |_| {
            ALARM_FIRED.with(|f| f.set(true));
            Err(wasmtime::Error::msg(sim_driver::ALARM_ABORT_ERR))
        });
    }
    let rt_inst = wts(linker.instantiate(&mut store, runtime_module))?;
    // The generated module imports the runtime's exports under module name "rt".
    wts(linker.instance(&mut store, "rt", rt_inst))?;
    let memory = rt_inst
        .get_memory(&mut store, "memory")
        .ok_or_else(|| "CodegenWasmJit: runtime has no `memory` export")?;
    // External "C" functions (module `ext`) resolved from the host; they share the
    // runtime's linear memory for string/array/pointer marshalling, and re-enter
    // the runtime's `rt_str_new`/`rt_str_data` to build in-wasm strings for `char*`
    // outputs.
    let rt_str_new = wts(rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_str_new"))?;
    let rt_str_data = wts(rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_str_data"))?;
    let nls = NlsHooks {
        recovering: wts(rt_inst.get_typed_func::<(), i32>(&mut store, "rt_nls_recovering"))?,
        note: wts(rt_inst.get_typed_func::<(), ()>(&mut store, "rt_nls_note_assert"))?,
    };
    // `rt_row_asserts` is called by the model, which only imports `memory`.
    crate::host::set_sim_memory(memory);
    let ext_rt = crate::dylink_engine::ExtRt {
        str_new: rt_str_new,
        str_data: rt_str_data,
        release: wts(rt_inst.get_typed_func::<u32, ()>(&mut store, "rt_release"))?,
        alloc: wts(rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_alloc"))?,
        free: wts(rt_inst.get_typed_func::<u32, ()>(&mut store, "rt_free"))?,
        record_new: wts(rt_inst.get_typed_func::<(u32, u32), u32>(&mut store, "rt_record_new"))?,
        nls: Some(nls),
    };
    let ext_libs = crate::dylink_engine::load_ext_libraries(&mut store, engine, rt_inst, memory, model, &ext_rt)?;
    crate::host::set_shadow_stack(ext_libs.shadow_stack());
    wts(crate::host::set_model_error_tag(&mut store, None))?;
    define_external_imports(&mut linker, &mut store, model, memory, &ext_rt, &ext_libs)?;
    define_print_import(&mut linker, memory)?;
    crate::host::define_uri_import(&mut linker, memory, ext_rt.str_new.clone(), ext_rt.str_data.clone())?;
    let instance = wts(linker.instantiate(&mut store, &model_module))?;
    // What a library's `ModelicaError` throws, now that the module defining the
    // tag exists. Only a model with external "C" carries one.
    if let Some(wasmtime::Extern::Tag(tag)) = instance.get_export(&mut store, "model_error") {
        wts(crate::host::set_model_error_tag(&mut store, Some(tag)))?;
    }
    let inst_time = t_inst.elapsed();
    let rt_alloc = wts(rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_alloc"))?;
    // `-nls`/`-nlsLS`/`-ls`/`-lss`: the host-driven runtime links no flag store of
    // its own, so hand it the selectors. The session sets the same ones from the
    // argv it receives.
    if let Ok(set) = rt_inst.get_typed_func::<(u32, u32, u32, u32), ()>(&mut store, "rt_set_solvers") {
        let codes = openmodelica_sim_meta::simflags::with_flags(|f| f.solver_codes());
        wts(set.call(&mut store, codes))?;
    }
    // `-newtonFTol`/`-newtonXTol`/`-newtonMaxStepFactor`: the nonlinear solvers that
    // read them run in-wasm whichever driver owns the run.
    if let Ok(set) = rt_inst.get_typed_func::<(f64, f64, f64), ()>(&mut store, "rt_set_newton_tuning") {
        let t = openmodelica_sim_meta::simflags::with_flags(|f| {
            openmodelica_sim_meta::simflags::newton_tuning(f)
        });
        wts(set.call(&mut store, t))?;
    }
    // `-lvMaxWarn`: the warnings it caps are printed in-wasm.
    if let Ok(set) = rt_inst.get_typed_func::<u32, ()>(&mut store, "rt_set_max_warn") {
        let n = openmodelica_sim_meta::simflags::with_flags(|f| f.max_warn.unwrap_or(3));
        wts(set.call(&mut store, n))?;
    }
    // `-ils` / `-homotopyOnFirstTry`: a local approach sweeps inside `rt_solve_nls`.
    if let Ok(set) = rt_inst.get_typed_func::<(u32, u32), ()>(&mut store, "rt_set_homotopy") {
        let h = openmodelica_sim_meta::simflags::with_flags(|f| {
            openmodelica_sim_meta::simflags::homotopy_codes(f)
        });
        wts(set.call(&mut store, h))?;
    }
    // The arc-length solver's `-hom*` constants.
    if let Ok(set) = rt_inst
        .get_typed_func::<(f64, f64, f64, f64, f64, f64, f64, f64, f64, u32, u32, u32, u32, u32), ()>(
            &mut store, "rt_set_homotopy_tuning",
        )
    {
        let h = openmodelica_sim_meta::simflags::with_flags(openmodelica_sim_meta::simflags::hom_tuning);
        wts(set.call(&mut store, (
            h.adapt_bend, h.h_eps, h.tau_dec, h.tau_dec_pred, h.tau_inc, h.tau_inc_threshold,
            h.tau_max, h.tau_min, h.tau_start, h.max_lambda_steps, h.max_newton_steps, h.max_tries,
            h.orthogonal_backtrace as u32, h.neg_start_dir as u32,
        )))?;
    }
    // Same for `-lv`: the nonlinear solver logs from inside the module.
    let log_mask = openmodelica_sim_meta::simflags::with_flags(|f| f.log_mask);
    if let Ok(set) = rt_inst.get_typed_func::<(u32, u32), ()>(&mut store, "rt_set_log_streams") {
        wts(set.call(&mut store, (log_mask as u32, (log_mask >> 32) as u32)))?;
    }
    // The linear/nonlinear systems are solved in-wasm, so their `LOG_STATS_V`
    // statistics are measured there; hand the module the host clock and arm them.
    if let Ok(set) = rt_inst.get_typed_func::<u32, ()>(&mut store, "rt_stats_start") {
        let on = openmodelica_sim_meta::omclog::mask_has(log_mask, openmodelica_sim_meta::omclog::STATS_V);
        wts(set.call(&mut store, on as u32))?;
    }
    // `-lv=LOG_NLS` names the iteration variables, which only the metadata has. The
    // roster is per model, so it is cleared first and pushed only when the stream is
    // on: an ordinary run carries no names.
    if openmodelica_sim_meta::omclog::mask_has(log_mask, openmodelica_sim_meta::omclog::NLS)
        && let Ok(set) = rt_inst.get_typed_func::<(u32, u32, u32), ()>(&mut store, "rt_nls_set_names")
    {
        let free = rt_inst.get_typed_func::<u32, ()>(&mut store, "rt_free").ok();
        wts(set.call(&mut store, (u32::MAX, 0, 0)))?;
        for sys in &meta.nls_vars {
            let mut blob = Vec::new();
            for n in &sys.names {
                blob.extend_from_slice(n.as_bytes());
                blob.push(0);
            }
            let ptr = wts(rt_alloc.call(&mut store, blob.len() as u32))?;
            wts(memory.write(&mut store, ptr as usize, &blob))?;
            wts(set.call(&mut store, (sys.eq_index, ptr, blob.len() as u32)))?;
            if let Some(f) = &free {
                wts(f.call(&mut store, ptr))?;
            }
        }
    }
    // The driver that owns the `SimMeta` stays on the host in this build.
    if let Ok(set) = rt_inst.get_typed_func::<f64, ()>(&mut store, "rt_set_step_size") {
        wts(set.call(&mut store, meta.step_size()))?;
    }
    if bench {
        eprintln!("wasm-jit sim: compile {compile_time:?} | instantiate {inst_time:?}");
    }

    Ok(Instantiated { store, rt_inst, instance, memory, rt_alloc })
}

/// Build the engine (compile/join modules, instantiate, allocate `SimData`), boxed
/// with the `SimData` pointer; owned by the session across `advance` calls, reused
/// by [`run`] one-shot.
pub fn build_engine(model: &SimModel, meta: &SimMeta) -> std::result::Result<(Box<dyn sim_driver::SimEngine + 'static>, u32), String> {
    sim_driver::init_host_hooks(); // cancel poll + model-assertion routing (idempotent)
    let Instantiated { mut store, rt_inst, instance, memory, rt_alloc } = instantiate_modules(model, meta)?;

    let layout = &model.layout;
    // Allocate the shared SimData block.
    let sim_data = wts(rt_alloc.call(&mut store, layout.total))?;

    // M0 proof: the driver reaches the model wasm→wasm by appending a model
    // export to the shared table and `call_indirect`ing it from the runtime
    // (same path `rt_solve_nls` already uses). Verify host-side population works
    // before building the in-wasm driver on it.
    if std::env::var("OMC_WASM_SIM_PROBE").is_ok() {
        run_table_probe(&mut store, rt_inst, instance, memory, sim_data, layout.total)?;
    }

    let engine = WasmtimeEngine { store, memory, instance, rt_inst, funcs: HashMap::new(), funcs2: HashMap::new() };
    Ok((Box::new(engine), sim_data))
}

/// Prove the in-wasm-driver call path: append the model's `functionParameters`
/// to the runtime's shared `__indirect_function_table`, then invoke it two ways
/// from a zeroed `SimData` — directly, and via the runtime's `rt_call1_indirect`
/// (`call_indirect` on the table index) — and require byte-identical results.
fn run_table_probe(
    store: &mut Store,
    rt_inst: wasmtime::Instance,
    instance: wasmtime::Instance,
    memory: wasmtime::Memory,
    sim_data: u32,
    total: u32,
) -> Result<()> {
    let table = rt_inst
        .get_table(&mut *store, "__indirect_function_table")
        .ok_or_else(|| "wasm-jit sim PROBE: runtime has no __indirect_function_table export")?;
    let func = instance
        .get_func(&mut *store, "functionParameters")
        .ok_or_else(|| "wasm-jit sim PROBE: model has no functionParameters export")?;
    let idx = wt(table.grow(&mut *store, 1, wasmtime::Ref::Func(Some(func))))? as u32;
    let probe = wt(rt_inst.get_typed_func::<(u32, u32), ()>(&mut *store, "rt_call1_indirect"))?;
    let direct = wt(instance.get_typed_func::<u32, ()>(&mut *store, "functionParameters"))?;

    let zero = vec![0u8; total as usize];
    let snapshot = |store: &mut Store| -> Result<Vec<u8>> {
        let mut b = vec![0u8; total as usize];
        memory.read(&*store, sim_data as usize, &mut b).map_err(|_| "wasm-jit sim PROBE: mem read")?;
        Ok(b)
    };
    let zero_sim = |store: &mut Store| -> Result<()> {
        memory.write(&mut *store, sim_data as usize, &zero).map_err(|_| "wasm-jit sim PROBE: mem zero")
    };

    zero_sim(store)?;
    wt(direct.call(&mut *store, sim_data))?;
    let a = snapshot(store)?;

    zero_sim(store)?;
    wt(probe.call(&mut *store, (idx, sim_data)))?;
    let b = snapshot(store)?;

    if a == b && a != zero {
        eprintln!(
            "wasm-jit sim PROBE: call_indirect(functionParameters) at table[{idx}] MATCHES direct call ({total} bytes) — PASS"
        );
        Ok(())
    } else {
        Err("wasm-jit sim PROBE: call_indirect result differs from direct call — FAIL")
    }
}

/// wasmtime backend for the [`sim_driver::SimEngine`] drivers: owns the store,
/// the shared linear memory, the model instance, and a cache of resolved
/// `fn(u32) -> ()` equation functions.
struct WasmtimeEngine {
    store: Store,
    memory: wasmtime::Memory,
    instance: wasmtime::Instance,
    rt_inst: wasmtime::Instance,
    funcs: HashMap<String, wasmtime::TypedFunc<u32, ()>>,
    /// The DAE-mode residual, the one `fn(u32, u32) -> ()` entry point.
    /// Resolved two-argument exports by name (`evaluateDAEResiduals` and the
    /// synchronous dispatchers), so one cached entry cannot answer for another.
    funcs2: HashMap<String, wasmtime::TypedFunc<(u32, u32), ()>>,
}

impl WasmtimeEngine {
    fn func(&mut self, name: &str) -> Result<wasmtime::TypedFunc<u32, ()>> {
        if let Some(f) = self.funcs.get(name) {
            return Ok(f.clone());
        }
        let f = wt(self.instance.get_typed_func::<u32, ()>(&mut self.store, name))?;
        self.funcs.insert(name.to_string(), f.clone());
        Ok(f)
    }
}

impl sim_driver::SimEngine for WasmtimeEngine {
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> Result<()> {
        self.memory.read(&self.store, addr as usize, buf).map_err(|e| "CodegenWasmJit: mem read")
    }
    fn write_bytes(&mut self, addr: u32, buf: &[u8]) -> Result<()> {
        self.memory.write(&mut self.store, addr as usize, buf).map_err(|e| "CodegenWasmJit: mem write")
    }
    fn call1_raw(&mut self, name: &str, arg: u32) -> Result<()> {
        let f = self.func(name)?;
        wt(f.call(&mut self.store, arg))
    }
    fn call1_if_present_raw(&mut self, name: &str, arg: u32) -> Result<()> {
        if self.instance.get_func(&mut self.store, name).is_none() {
            return Ok(());
        }
        self.call1_raw(name, arg)
    }
    fn call2_raw(&mut self, name: &str, a: u32, b: u32) -> Result<()> {
        let f = match self.funcs2.get(name) {
            Some(f) => f.clone(),
            None => {
                let f = wt(self.instance.get_typed_func::<(u32, u32), ()>(&mut self.store, name))?;
                self.funcs2.insert(name.to_string(), f.clone());
                f
            }
        };
        wt(f.call(&mut self.store, (a, b)))
    }
    fn call_simulate(&mut self, sim_data: u32, start: f64, stop: f64, n_steps: u32) -> Result<u32> {
        let f = wt(self.instance.get_typed_func::<(u32, f64, f64, u32), u32>(&mut self.store, "simulate"))?;
        wt(f.call(&mut self.store, (sim_data, start, stop, n_steps)))
    }
    fn take_pending_assert(&mut self) -> Option<[i32; 9]> {
        crate::host::take_pending_assert()
    }
    fn take_pending_warnings(&mut self) -> Vec<[i32; 10]> {
        crate::host::take_pending_warnings()
    }
    fn take_pending_reinits(&mut self) -> Vec<(u32, f64)> {
        crate::host::take_pending_reinits()
    }
    fn lin_solves(&mut self) -> u64 {
        match self.rt_inst.get_typed_func::<(), u64>(&mut self.store, "rt_lin_solves") {
            Ok(f) => f.call(&mut self.store, ()).unwrap_or(0),
            Err(_) => 0,
        }
    }
    fn sys_stats(&mut self) -> Vec<openmodelica_sim_meta::sysstat::SysStat> {
        let out = read_sys_stats(&mut self.store, &self.rt_inst, &self.memory);
        out
    }
    fn rt_stats(&mut self) -> [u64; sim_driver::RT_STATS] {
        let mut out = [0u64; sim_driver::RT_STATS];
        if let Ok(f) = self.rt_inst.get_typed_func::<u32, u64>(&mut self.store, "rt_stat") {
            for (k, slot) in out.iter_mut().enumerate() {
                *slot = f.call(&mut self.store, k as u32).unwrap_or(0);
            }
        }
        out
    }
    fn context_addr(&mut self) -> u32 {
        self.rt_inst
            .get_typed_func::<(), u32>(&mut self.store, "rt_context_addr")
            .ok()
            .and_then(|f| f.call(&mut self.store, ()).ok())
            .unwrap_or(0)
    }
    fn error_stage_addr(&mut self) -> u32 {
        self.rt_inst
            .get_typed_func::<(), u32>(&mut self.store, "rt_error_stage_addr")
            .ok()
            .and_then(|f| f.call(&mut self.store, ()).ok())
            .unwrap_or(0)
    }
    fn no_throw_div_zero_addr(&mut self) -> u32 {
        self.rt_inst
            .get_typed_func::<(), u32>(&mut self.store, "rt_no_throw_div_zero_addr")
            .ok()
            .and_then(|f| f.call(&mut self.store, ()).ok())
            .unwrap_or(0)
    }
    fn clean_nls_history(&mut self, time: f64) {
        if let Ok(f) = self.rt_inst.get_typed_func::<f64, ()>(&mut self.store, "rt_nls_clean_history") {
            let _ = f.call(&mut self.store, time);
        }
    }
    fn set_rhs_final(&mut self, final_eval: bool) {
        openmodelica_util::dynload::set_rhs_final_flag(final_eval);
    }
}

// ---------------------------------------------------------------------------
// In-wasm session driver (`rt_sim_*`): the shared driver runs *inside*
// `runtime.wasm`, reaching the model via the shared table (wasm->wasm), so the
// host only starts it, pumps budgeted chunks, and reads the result buffers —
// O(chunks) host<->wasm crossings instead of one per residual.
// ---------------------------------------------------------------------------

/// A running in-wasm simulation. `Drop` frees the in-wasm session.
pub struct InWasmSession {
    store: Store,
    memory: wasmtime::Memory,
    advance: wasmtime::TypedFunc<f64, i32>,
    rows_ptr: wasmtime::TypedFunc<(), u32>,
    rows_len: wasmtime::TypedFunc<(), u32>,
    n_reals_f: wasmtime::TypedFunc<(), u32>,
    params_ptr: wasmtime::TypedFunc<(), u32>,
    params_len: wasmtime::TypedFunc<(), u32>,
    stat_f: wasmtime::TypedFunc<u32, u64>,
    lin_ptr: wasmtime::TypedFunc<(), u32>,
    lin_len: wasmtime::TypedFunc<(), u32>,
    sys_ptr: wasmtime::TypedFunc<(), u32>,
    sys_len: wasmtime::TypedFunc<(), u32>,
    free_f: wasmtime::TypedFunc<(), ()>,
}

/// Instantiate, populate the shared table with the model's exports, write the
/// metadata blob, and `rt_sim_start` a resumable in-wasm run.
pub fn build_inwasm_session(model: &SimModel) -> std::result::Result<InWasmSession, String> {
    sim_driver::init_host_hooks(); // cancel poll + assertion routing (idempotent)
    let Instantiated { mut store, rt_inst, instance, memory, rt_alloc } = instantiate_modules(model, &model.meta)?;

    // Append N contiguous table slots and set each to the model's export funcref
    // (null + cleared mask bit if the model doesn't export it).
    let table = rt_inst
        .get_table(&mut store, "__indirect_function_table")
        .ok_or_else(|| "CodegenWasmJit: runtime has no __indirect_function_table export")?;
    let n_slots = crate::model::INWASM_SLOT_NAMES.len() as u64;
    let fn_base = wts(table.grow(&mut store, n_slots, wasmtime::Ref::Func(None)))?;
    let mut present_mask: u64 = 0;
    for (slot, name) in crate::model::INWASM_SLOT_NAMES.iter().enumerate() {
        if let Some(f) = instance.get_func(&mut store, name) {
            wts(table.set(&mut store, fn_base + slot as u64, wasmtime::Ref::Func(Some(f))))?;
            present_mask |= 1u64 << slot;
        }
    }

    // Write the metadata blob into linear memory for the runtime to decode.
    let blob = openmodelica_sim_meta::encode(&model.meta);
    let meta_ptr = wts(rt_alloc.call(&mut store, blob.len() as u32))?;
    wts(memory.write(&mut store, meta_ptr as usize, &blob))?;

    // The runtime has its own override store; hand the host's across.
    let ov = crate::model::encode_overrides();
    let ov_ptr = wts(rt_alloc.call(&mut store, ov.len() as u32))?;
    wts(memory.write(&mut store, ov_ptr as usize, &ov))?;
    let set_ov = wts(rt_inst.get_typed_func::<(u32, u32), i32>(&mut store, "rt_sim_set_overrides"))?;
    if wts(set_ov.call(&mut store, (ov_ptr, ov.len() as u32)))? < 0 {
        return Err("CodegenWasmJit: rt_sim_set_overrides failed".to_string());
    }

    // Same for the runtime flags, as the argv bytes a WASI command would receive.
    let args = openmodelica_sim_meta::simflags::flags().to_wasi_args();
    let args_ptr = wts(rt_alloc.call(&mut store, args.len().max(1) as u32))?;
    wts(memory.write(&mut store, args_ptr as usize, &args))?;
    let set_args = wts(rt_inst.get_typed_func::<(u32, u32), i32>(&mut store, "rt_sim_set_args"))?;
    if wts(set_args.call(&mut store, (args_ptr, args.len() as u32)))? < 0 {
        return Err("CodegenWasmJit: the runtime rejected the simulation flags".to_string());
    }

    let start = wts(rt_inst.get_typed_func::<(u32, u32, u32, u64), i32>(&mut store, "rt_sim_start"))?;
    let gf = |store: &mut Store, name: &'static str| wts(rt_inst.get_typed_func::<(), u32>(store, name));
    // Assembled before the run starts so that an initialization `assert()`, which
    // traps out of `rt_sim_start`, is decoded through the same `SimEngine` as one
    // that trips later instead of surfacing as a bare wasm trap.
    let mut sess = InWasmSession {
        advance: wts(rt_inst.get_typed_func::<f64, i32>(&mut store, "rt_sim_advance"))?,
        rows_ptr: gf(&mut store, "rt_sim_rows_ptr")?,
        rows_len: gf(&mut store, "rt_sim_rows_len")?,
        n_reals_f: gf(&mut store, "rt_sim_n_reals")?,
        params_ptr: gf(&mut store, "rt_sim_params_ptr")?,
        params_len: gf(&mut store, "rt_sim_params_len")?,
        stat_f: wts(rt_inst.get_typed_func::<u32, u64>(&mut store, "rt_sim_stat"))?,
        lin_ptr: gf(&mut store, "rt_sim_lin_ptr")?,
        lin_len: gf(&mut store, "rt_sim_lin_len")?,
        sys_ptr: gf(&mut store, "rt_sys_stats_ptr")?,
        sys_len: gf(&mut store, "rt_sys_stats_len")?,
        free_f: wts(rt_inst.get_typed_func::<(), ()>(&mut store, "rt_sim_free"))?,
        store,
        memory,
    };
    let started = start.call(&mut sess.store, (meta_ptr, blob.len() as u32, fn_base as u32, present_mask));
    match started {
        Ok(rc) if rc >= 0 => Ok(sess),
        Ok(_) => Err("CodegenWasmJit: rt_sim_start failed".to_string()),
        Err(_) => Err(sim_driver::enrich_trap_init(
            &mut sess,
            "CodegenWasmJit: in-wasm initialization failed",
            model.start_time,
        )
        .to_string()),
    }
}

// Memory access + pending-assert only; the model-call methods are never reached
// (they run in-wasm), but `SimEngine` lets `enrich_trap` decode a failed `assert()`
// out of the shared memory exactly as the host driver does.
impl sim_driver::SimEngine for InWasmSession {
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> Result<()> {
        self.memory.read(&self.store, addr as usize, buf).map_err(|_| "CodegenWasmJit: mem read")
    }
    fn write_bytes(&mut self, addr: u32, buf: &[u8]) -> Result<()> {
        self.memory.write(&mut self.store, addr as usize, buf).map_err(|_| "CodegenWasmJit: mem write")
    }
    fn call1_raw(&mut self, _name: &str, _arg: u32) -> Result<()> {
        Err("CodegenWasmJit: call1 on in-wasm session (unreachable)")
    }
    fn call1_if_present_raw(&mut self, _name: &str, _arg: u32) -> Result<()> {
        Ok(())
    }
    fn call2_raw(&mut self, _name: &str, _a: u32, _b: u32) -> Result<()> {
        Err("CodegenWasmJit: call2 on in-wasm session (unreachable)")
    }
    fn call_simulate(&mut self, _s: u32, _a: f64, _b: f64, _n: u32) -> Result<u32> {
        Err("CodegenWasmJit: call_simulate on in-wasm session (unreachable)")
    }
    fn take_pending_assert(&mut self) -> Option<[i32; 9]> {
        crate::host::take_pending_assert()
    }
    fn take_pending_warnings(&mut self) -> Vec<[i32; 10]> {
        crate::host::take_pending_warnings()
    }
    fn take_pending_reinits(&mut self) -> Vec<(u32, f64)> {
        crate::host::take_pending_reinits()
    }
}

impl InWasmSession {
    /// One budgeted chunk. Returns the raw `rt_sim_advance` status (0 running,
    /// 1 done, 2 terminated, 3 cancelled). A model `assert()` traps out of
    /// `rt_sim_advance` (or the driver returns <0); either way decode the pending
    /// assertion and surface it like the host driver.
    pub fn advance(&mut self, budget_ms: f64) -> Result<i32> {
        match self.advance.call(&mut self.store, budget_ms) {
            Ok(rc) if rc >= 0 => Ok(rc),
            _ => Err(sim_driver::enrich_trap(self, "CodegenWasmJit: in-wasm simulation failed")),
        }
    }

    /// Read the captured rows/params/stats after the run completed.
    pub fn take_result(&mut self) -> Result<sim_driver::RunResult> {
        let read_vec = |store: &mut Store,
                        mem: &wasmtime::Memory,
                        ptr: &wasmtime::TypedFunc<(), u32>,
                        len: &wasmtime::TypedFunc<(), u32>|
         -> Result<Vec<f64>> {
            let p = wt(ptr.call(&mut *store, ()))?;
            let n = wt(len.call(&mut *store, ()))? as usize;
            let mut bytes = vec![0u8; n * 8];
            mem.read(&*store, p as usize, &mut bytes).map_err(|_| "CodegenWasmJit: rows read")?;
            Ok(bytes.chunks_exact(8).map(|c| f64::from_le_bytes(c.try_into().unwrap())).collect())
        };
        let n_reals = wt(self.n_reals_f.call(&mut self.store, ()))?;
        let rows = read_vec(&mut self.store, &self.memory, &self.rows_ptr, &self.rows_len)?;
        let params = read_vec(&mut self.store, &self.memory, &self.params_ptr, &self.params_len)?;
        let mut stats = openmodelica_sim_meta::SolveStats::default();
        stats.systems = openmodelica_sim_meta::sysstat::decode(&read_vec(
            &mut self.store, &self.memory, &self.sys_ptr, &self.sys_len,
        )?);
        let mut stat = |i: u32| wt(self.stat_f.call(&mut self.store, i));
        stats.steps = stat(0)?;
        stats.res_evals = stat(1)?;
        stats.jac_evals = stat(2)?;
        stats.err_test_fails = stat(3)?;
        stats.conv_test_fails = stat(4)?;
        stats.state_events = stat(5)?;
        stats.time_events = stat(6)?;
        stats.lin_solves = stat(7)?;
        openmodelica_sim_meta::rtclock::read_stat_slots(&mut stats, &mut stat)?;
        let lin = self.take_lin()?;
        Ok(sim_driver::RunResult { rows, n_reals, params, stats, lin })
    }

    /// The runtime's `-l` blob (`<file name>\0<content>`), empty when unasked.
    fn take_lin(&mut self) -> Result<Option<openmodelica_sim_meta::linearize::LinFile>> {
        let p = wt(self.lin_ptr.call(&mut self.store, ()))?;
        let n = wt(self.lin_len.call(&mut self.store, ()))? as usize;
        let mut bytes = vec![0u8; n];
        if n > 0 {
            self.memory
                .read(&self.store, p as usize, &mut bytes)
                .map_err(|_| "CodegenWasmJit: linearization read")?;
        }
        Ok(crate::split_lin_blob(&bytes))
    }
}

impl Drop for InWasmSession {
    fn drop(&mut self) {
        let _ = self.free_f.call(&mut self.store, ());
    }
}

