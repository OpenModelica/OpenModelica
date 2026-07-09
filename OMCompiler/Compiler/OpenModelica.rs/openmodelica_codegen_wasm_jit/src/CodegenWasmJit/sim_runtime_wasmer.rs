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

use anyhow::{Result, anyhow, bail};
use std::collections::HashMap;
use std::sync::OnceLock;

/// Monotonic instant over `openmodelica_wasi::monotonic_nanos` (wasm-safe;
/// `std::time::Instant::now()` panics on wasm32-unknown-unknown). Sharing this
/// one clock means the host bench timers and the WASI guest's
/// `clock_time_get(MONOTONIC)` measure against the same zero-point. Drop-in for
/// the `Instant::now()`/`.elapsed()` this module uses.
#[derive(Clone, Copy)]
struct Instant(u64);
impl Instant {
    fn now() -> Self {
        Instant(openmodelica_wasi::monotonic_nanos())
    }
    fn elapsed(&self) -> std::time::Duration {
        std::time::Duration::from_nanos(openmodelica_wasi::monotonic_nanos().saturating_sub(self.0))
    }
}

use super::sim_driver;
use super::SimModel;
use crate::CodegenWasmJitFunctions::WTy;
use crate::CodegenWasmJitFunctions::runtime::add_host_builtins;

/// The runtime module, embedded the same way the function half embeds it.
static RUNTIME_WASM: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/runtime.wasm"));

/// The ModelicaExternalC WASI side module (`build.rs`), providing the
/// `ext.Modelica*_*` external functions (table blocks, string scanning, …) on the
/// web target. Empty when `emcc` was unavailable at build time — these externals
/// are then reported as unavailable at run time (see [`define_external_imports`]).
static EXTERNAL_C_WASM: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/modelicaexternalc.wasm"));

thread_local! {
    /// Side-module offsets `env.ModelicaAllocateString` handed out during the
    /// current external "C" call (string outputs live in the side module's memory).
    /// Drained + freed by [`call_external_side`] once the results are copied into
    /// in-wasm strings — mirrors the native arena's per-call lifetime.
    static SIDE_STR_TEMPS: std::cell::RefCell<Vec<u32>> = const { std::cell::RefCell::new(Vec::new()) };
}

/// The compiled-module type for this backend; `CodegenWasmJit::SimModel` stores
/// it backend-agnostically as `sim_runtime::Module`.
pub(crate) type Module = wasmer::Module;

/// One process-wide wasmer `Engine` (native `sys`/cranelift backend), so the
/// (model-independent) runtime module can be JIT-compiled once and reused, and
/// so model modules built on background threads share the same engine the run
/// instantiates them on. Cloning an `Engine` is a cheap handle copy; a module
/// compiled with one clone instantiates in any `Store` built from another.
#[cfg(not(target_arch = "wasm32"))]
pub(super) fn sim_engine() -> &'static wasmer::Engine {
    use wasmer::sys::{Cranelift, CraneliftOptLevel, EngineBuilder};
    static ENGINE: OnceLock<wasmer::Engine> = OnceLock::new();
    ENGINE.get_or_init(|| {
        let mut compiler = Cranelift::default();
        // Experimental opt-level override; default is cranelift's `Speed`.
        // (wasmer compiles module functions in parallel by default.)
        match std::env::var("OMC_WASM_OPT_LEVEL").as_deref() {
            Ok("none") => { compiler.opt_level(CraneliftOptLevel::None); }
            Ok("speed_and_size") => { compiler.opt_level(CraneliftOptLevel::SpeedAndSize); }
            _ => {}
        }
        EngineBuilder::new(compiler).engine().into()
    })
}

/// wasm build: the `js` backend has no cranelift compiler to configure; module
/// compilation is forwarded to the host JS `WebAssembly` engine. `Engine` is the
/// default js engine.
#[cfg(target_arch = "wasm32")]
pub(super) fn sim_engine() -> &'static wasmer::Engine {
    static ENGINE: OnceLock<wasmer::Engine> = OnceLock::new();
    ENGINE.get_or_init(wasmer::Engine::default)
}

/// The compiled runtime module, obtained once per process and shared across all
/// simulations. The runtime module is fixed, so its compiled form is cached
/// **on disk** (AOT): the first process to need it JIT-compiles and
/// `serialize`s it; every later process `deserialize`s the artifact in
/// microseconds. `deserialize` validates the artifact against the current
/// wasmer version / engine config / target, so a stale or incompatible cache
/// is rejected and we transparently fall back to JIT (then refresh the cache).
pub(super) fn runtime_module() -> Result<&'static wasmer::Module> {
    static MODULE: OnceLock<std::result::Result<wasmer::Module, String>> = OnceLock::new();
    MODULE
        .get_or_init(|| load_or_compile_runtime().map_err(|e| format!("{e:?}")))
        .as_ref()
        .map_err(|e| anyhow!("CodegenWasmJit: obtaining runtime module: {e}"))
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
#[cfg(not(target_arch = "wasm32"))]
fn runtime_cache_path() -> std::path::PathBuf {
    use std::hash::{Hash, Hasher};
    let mut h = std::collections::hash_map::DefaultHasher::new();
    RUNTIME_WASM.len().hash(&mut h);
    RUNTIME_WASM.hash(&mut h);
    std::env::var("OMC_WASM_OPT_LEVEL").unwrap_or_default().hash(&mut h);
    let key = h.finish();

    let home = openmodelica_util::Settings::getHomeDir(false);
    let dir = if home.is_empty() {
        Some(std::env::temp_dir())
    } else {
        let d = std::path::Path::new(&*home).join(".openmodelica").join("cache");
        std::fs::create_dir_all(&d).ok().map(|_| d)
    };
    let dir = dir.unwrap_or_else(std::env::temp_dir);
    dir.join(format!("wasmjit-runtime-{key:016x}.cwasm"))
}

fn load_or_compile_runtime() -> Result<wasmer::Module> {
    let engine = sim_engine();
    // wasm has no filesystem for an on-disk AOT cache (and `temp_dir()` panics);
    // the in-memory OnceLock already caches the compiled module for the session,
    // so compile straight from the embedded bytes.
    #[cfg(target_arch = "wasm32")]
    return wasmer::Module::from_binary(engine, RUNTIME_WASM).map_err(|e| anyhow!("{e:?}"));
    #[cfg(not(target_arch = "wasm32"))]
    {
    let path = runtime_cache_path();
    // Try the AOT artifact first (microseconds). `deserialize_from_file` is
    // unsafe because it trusts the artifact; it is one we produced under
    // temp_dir, and wasmer validates version/config compatibility (erroring
    // otherwise).
    if path.exists() {
        if let Ok(m) = unsafe { wasmer::Module::deserialize_from_file(engine, &path) } {
            return Ok(m);
        }
        // Incompatible/corrupt cache (e.g. wasmer upgrade): fall through to
        // recompile and overwrite it below.
    }
    let module = wasmer::Module::from_binary(engine, RUNTIME_WASM).map_err(|e| anyhow!("{e:?}"))?;
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
}

/// JIT-compile a generated model module on the shared engine. Called either on a
/// background thread from `translateModel` (overlapping the rest of the OMC
/// pipeline) or inline from `run` as a fallback.
pub(super) fn compile_model_module(wasm: &[u8]) -> Result<wasmer::Module> {
    wasmer::Module::from_binary(sim_engine(), wasm).map_err(|e| anyhow!("{e:?}"))
}

/// Begin compiling the fixed runtime module on a background thread, once per
/// process. The runtime module does not depend on the model, so this can be
/// started as soon as we know a wasm-jit simulation is coming (`translateModel`
/// entry) — it then compiles while `build_sim_model` generates the model bytes,
/// and `run` only waits for whatever did not overlap. Idempotent.
pub(super) fn start_runtime_compile() {
    // wasm has no threads; the runtime module is compiled synchronously on first
    // use (`runtime_module()` is called from finishCompile / run). Skipping the
    // prewarm only forgoes the native overlap optimisation.
    #[cfg(target_arch = "wasm32")]
    return;
    #[cfg(not(target_arch = "wasm32"))]
    {
        static STARTED: std::sync::Once = std::sync::Once::new();
        STARTED.call_once(|| {
            std::thread::spawn(|| {
                let _ = runtime_module(); // populates the OnceLock cache
            });
        });
    }
}

/// Take the model module compiled on the background thread `translateModel`
/// spawned (joining it), or compile inline if there is no pending job.
pub(super) fn take_compiled_model(model: &SimModel) -> Result<wasmer::Module> {
    let job = model.compiled.lock().unwrap().take();
    match job {
        // Native: the job is a thread handle to join. wasm: the job is the
        // already-computed compile result.
        #[cfg(not(target_arch = "wasm32"))]
        Some(handle) => match handle.join() {
            Ok(Ok(m)) => Ok(m),
            Ok(Err(e)) => bail!("CodegenWasmJit: background model-module compile failed: {e}"),
            Err(_) => bail!("CodegenWasmJit: background model-module compile thread panicked"),
        },
        #[cfg(target_arch = "wasm32")]
        Some(Ok(m)) => Ok(m),
        #[cfg(target_arch = "wasm32")]
        Some(Err(e)) => bail!("CodegenWasmJit: model-module compile failed: {e}"),
        None => compile_model_module(&model.wasm),
    }
}

type Store = wasmer::Store;

/// Flatten any wasmer engine/runtime error into our `anyhow` (their error types
/// — `RuntimeError`, `InstantiationError`, `MemoryAccessError`, … — do not share
/// a single anyhow-convertible type, so we format via `Debug`).
fn wt<T, E: std::fmt::Debug>(r: std::result::Result<T, E>) -> Result<T> {
    r.map_err(|e| anyhow!("{e:?}"))
}

/// Read a NUL-terminated C string from wasm memory at `ptr` (bounded).
fn read_cstr(mem: &wasmer::Memory, store: &impl wasmer::AsStoreRef, ptr: u32) -> String {
    let view = mem.view(store);
    let mut bytes = Vec::new();
    let mut a = ptr as u64;
    let mut b = [0u8; 1];
    while bytes.len() < 65536 && view.read(a, &mut b).is_ok() && b[0] != 0 {
        bytes.push(b[0]);
        a += 1;
    }
    String::from_utf8_lossy(&bytes).into_owned()
}

fn read_u32_mem(mem: &wasmer::Memory, store: &impl wasmer::AsStoreRef, addr: u32) -> Result<u32> {
    let mut b = [0u8; 4];
    mem.view(store).read(addr as u64, &mut b).map_err(|e| anyhow!("CodegenWasmJit: mem read: {e}"))?;
    Ok(u32::from_le_bytes(b))
}

/// Host state for the side module's `env.Modelica*Error` imports: its memory
/// (filled in after instantiation) to read the message from.
struct SideErrEnv {
    mem: Option<wasmer::Memory>,
}

/// Host state for the side module's `env.ModelicaAllocateString` import: its
/// `malloc` (filled in after instantiation). Every buffer handed out is recorded in
/// [`SIDE_STR_TEMPS`] so the trampoline can free it after copying the result out.
struct AllocEnv {
    malloc: Option<wasmer::TypedFunction<u32, u32>>,
}

/// Per-`ext.<name>` host state: the sim/rt shared memory (source of String/array
/// args and destination of string outputs), the side module's memory + allocator,
/// the target export, the runtime's string constructors (to build in-wasm strings
/// for `char*`/`char**` outputs), and the C-call signature to marshal by.
struct ExtEnv {
    sim_mem: wasmer::Memory,
    side_mem: wasmer::Memory,
    malloc: wasmer::TypedFunction<u32, u32>,
    free: wasmer::TypedFunction<u32, ()>,
    rt_str_new: wasmer::TypedFunction<u32, u32>,
    rt_str_data: wasmer::TypedFunction<u32, u32>,
    func: wasmer::Function,
    sig: crate::CodegenWasmJitFunctions::ExtCallSig,
}

/// Wire the `ext.*` external "C" imports for the web target by instantiating the
/// ModelicaExternalC WASI side module (`EXTERNAL_C_WASM`, its own memory) and
/// binding each `ext.<name>` to a host trampoline that marshals String/array
/// arguments from the sim memory into the side module's memory (via its `malloc`),
/// calls the corresponding export, and copies the C return value and any `_Out_`
/// pointer outputs (scalars, and `char*`/`char**` strings) back — the latter into
/// fresh in-wasm strings (`rt_str_new`/`rt_str_data`). External-object handles
/// (`tableID`) are the side module's own pointers, passed straight through as `i32`.
/// A `ModelicaError` inside the side module records to the Error buffer and traps
/// (surfaced like the native path). Mirrors
/// `sim_runtime_wasmtime::define_external_imports`.
fn define_external_imports(
    store: &mut Store,
    imports: &mut wasmer::Imports,
    model: &SimModel,
    sim_mem: &wasmer::Memory,
    rt_str_new: &wasmer::TypedFunction<u32, u32>,
    rt_str_data: &wasmer::TypedFunction<u32, u32>,
) -> Result<()> {
    use wasmer::{AsStoreRef, Function, FunctionEnv, FunctionEnvMut, FunctionType, RuntimeError, Value};

    if EXTERNAL_C_WASM.is_empty() {
        bail!(
            "CodegenWasmJit: this model uses external \"C\" functions (e.g. table blocks, \
             string scanning), which need the ModelicaExternalC side module — unavailable in \
             this web build (build.rs could not compile modelicaexternalc.wasm; install the \
             apt packages `clang`, `lld`, `wasi-libc`, and `libclang-rt-dev-wasm32`)"
        );
    }

    // Instantiate the side module with its `env.Modelica*Error`/`usertab`/
    // `ModelicaAllocateString` imports.
    let side_module = wasmer::Module::from_binary(store.engine(), EXTERNAL_C_WASM).map_err(|e| anyhow!("{e:?}"))?;
    let err_env = FunctionEnv::new(&mut *store, SideErrEnv { mem: None });
    let modelica_error = Function::new_typed_with_env(
        &mut *store, &err_env,
        |env: FunctionEnvMut<SideErrEnv>, ptr: i32| -> std::result::Result<(), RuntimeError> {
            let mem = env.data().mem.clone();
            let msg = mem.map(|m| read_cstr(&m, &env.as_store_ref(), ptr as u32)).unwrap_or_default();
            openmodelica_error::ErrorExt::runtime_error(&msg);
            Err(RuntimeError::new(format!("ModelicaError: {msg}")))
        },
    );
    let modelica_format_error = Function::new_typed_with_env(
        &mut *store, &err_env,
        |env: FunctionEnvMut<SideErrEnv>, fmt: i32, _args: i32| -> std::result::Result<(), RuntimeError> {
            let mem = env.data().mem.clone();
            let msg = mem.map(|m| read_cstr(&m, &env.as_store_ref(), fmt as u32)).unwrap_or_default();
            openmodelica_error::ErrorExt::runtime_error(&msg);
            Err(RuntimeError::new(format!("ModelicaError: {msg}")))
        },
    );
    // `usertab` (user-defined table callback) is never used by the standard table
    // blocks; provide a stub that reports "not found".
    let usertab = Function::new_typed(&mut *store, |_: i32, _: i32, _: i32, _: i32, _: i32| -> i32 { 1 });
    // `ModelicaAllocateString(len)` — allocate the returned string buffer in the
    // side module's own memory (its `malloc`, filled in after instantiation) and
    // record the offset so the trampoline can free it after copying the result out.
    let alloc_env = FunctionEnv::new(&mut *store, AllocEnv { malloc: None });
    let modelica_alloc_string = Function::new_typed_with_env(
        &mut *store, &alloc_env,
        |mut env: FunctionEnvMut<AllocEnv>, len: i32| -> std::result::Result<i32, RuntimeError> {
            let malloc = env.data().malloc.clone()
                .ok_or_else(|| RuntimeError::new("ModelicaAllocateString before side-module init"))?;
            let off = malloc.call(&mut env, (len as u32) + 1)?;
            SIDE_STR_TEMPS.with(|t| t.borrow_mut().push(off));
            Ok(off as i32)
        },
    );

    // `ModelicaFormatWarning`/`ModelicaVFormatWarning`/`ModelicaFormatMessage` (fmt,
    // args) — non-fatal; record the (unformatted) format string. `ModelicaVFormatError`
    // is the noreturn va_list error: trap like `ModelicaError`. All are `(i32,i32)->()`;
    // ModelicaIO/MatIO pull the extra three (the base three come from tables/strings).
    let warn_fn = |store: &mut wasmer::Store, err_env: &FunctionEnv<SideErrEnv>| Function::new_typed_with_env(
        store, err_env,
        |env: FunctionEnvMut<SideErrEnv>, fmt: i32, _args: i32| {
            let mem = env.data().mem.clone();
            let msg = mem.map(|m| read_cstr(&m, &env.as_store_ref(), fmt as u32)).unwrap_or_default();
            openmodelica_error::ErrorExt::runtime_warning(&msg);
        },
    );
    let modelica_format_warning = warn_fn(&mut *store, &err_env);
    let modelica_vformat_warning = warn_fn(&mut *store, &err_env);
    let modelica_format_message = warn_fn(&mut *store, &err_env);
    let modelica_vformat_error = Function::new_typed_with_env(
        &mut *store, &err_env,
        |env: FunctionEnvMut<SideErrEnv>, fmt: i32, _args: i32| -> std::result::Result<(), RuntimeError> {
            let mem = env.data().mem.clone();
            let msg = mem.map(|m| read_cstr(&m, &env.as_store_ref(), fmt as u32)).unwrap_or_default();
            openmodelica_error::ErrorExt::runtime_error(&msg);
            Err(RuntimeError::new(format!("ModelicaError: {msg}")))
        },
    );
    // `ModelicaInternal_get*`: seeding helpers ModelicaRandom pulls in. `getTime`
    // writes nothing (7 int* outs left as-is); `getpid` returns a constant. (Only
    // ModelicaRandom's automatic global seed uses them; explicit-seed RNG does not.)
    let modelica_get_time = Function::new_typed(&mut *store,
        |_: i32, _: i32, _: i32, _: i32, _: i32, _: i32, _: i32| {});
    let modelica_getpid = Function::new_typed(&mut *store, || -> i32 { 1 });

    let mut side_imports = wasmer::Imports::new();
    side_imports.define("env", "ModelicaError", modelica_error);
    side_imports.define("env", "ModelicaFormatError", modelica_format_error);
    side_imports.define("env", "ModelicaFormatWarning", modelica_format_warning);
    side_imports.define("env", "ModelicaVFormatWarning", modelica_vformat_warning);
    side_imports.define("env", "ModelicaFormatMessage", modelica_format_message);
    side_imports.define("env", "ModelicaVFormatError", modelica_vformat_error);
    side_imports.define("env", "usertab", usertab);
    side_imports.define("env", "ModelicaAllocateString", modelica_alloc_string.clone());
    // ModelicaInternal uses the error-returning variant; same malloc-backed impl
    // (our alloc never traps — a failed malloc just yields offset 0, i.e. NULL).
    side_imports.define("env", "ModelicaAllocateStringWithErrorReturn", modelica_alloc_string);
    side_imports.define("env", "ModelicaInternal_getTime", modelica_get_time);
    side_imports.define("env", "ModelicaInternal_getpid", modelica_getpid);
    // WASI preview1: real file I/O over the same VFS the omc uses (`openmodelica_wasi`),
    // so file-based externals (file tables, ModelicaIO readers) read staged files.
    // `proc_exit` unwinds via `Err` (ends this external call / the sim), never the
    // whole process. The side module has its own memory, set below before any call.
    let wasi_env = FunctionEnv::new(&mut *store, super::wasi_shim::Env::new("/"));
    super::wasi_shim::add_to_imports(&mut *store, &wasi_env, &mut side_imports);
    let side_inst = wt(wasmer::Instance::new(&mut *store, &side_module, &side_imports))?;

    let side_mem = side_inst.exports.get_memory("memory")
        .map_err(|e| anyhow!("CodegenWasmJit: modelicaexternalc.wasm has no `memory`: {e:?}"))?.clone();
    // Let the error hooks + WASI calls read/write the side module's memory.
    err_env.as_mut(&mut *store).mem = Some(side_mem.clone());
    wasi_env.as_mut(&mut *store).set_memory(side_mem.clone());
    // WASI reactor initialization (sets up the C runtime state).
    if let Ok(init) = side_inst.exports.get_typed_function::<(), ()>(&*store, "_initialize") {
        wt(init.call(&mut *store))?;
    }
    let malloc: wasmer::TypedFunction<u32, u32> = wt(side_inst.exports.get_typed_function(&*store, "malloc"))?;
    let free: wasmer::TypedFunction<u32, ()> = wt(side_inst.exports.get_typed_function(&*store, "free"))?;
    // Now the allocator import can reach the side module's `malloc`.
    alloc_env.as_mut(&mut *store).malloc = Some(malloc.clone());

    for sig in &model.ext_imports {
        let name = &sig.name;
        let func = side_inst.exports.get_function(name)
            .map_err(|e| anyhow!("CodegenWasmJit: ModelicaExternalC side module has no `{name}`: {e:?}"))?
            .clone();
        let functype = FunctionType::new(
            sig.wasm_params().iter().map(|s| valtype(s.wty())).collect::<Vec<_>>(),
            sig.wasm_results().iter().map(|s| valtype(s.wty())).collect::<Vec<_>>(),
        );
        let env = FunctionEnv::new(&mut *store, ExtEnv {
            sim_mem: sim_mem.clone(),
            side_mem: side_mem.clone(),
            malloc: malloc.clone(),
            free: free.clone(),
            rt_str_new: rt_str_new.clone(),
            rt_str_data: rt_str_data.clone(),
            func,
            sig: sig.clone(),
        });
        let nm = name.clone();
        let host = Function::new_with_env(&mut *store, &env, functype,
            move |mut fenv: FunctionEnvMut<ExtEnv>, args: &[Value]| -> std::result::Result<Vec<Value>, RuntimeError> {
                call_external_side(&mut fenv, args).map_err(|e| RuntimeError::new(format!("external \"C\" `{nm}`: {e}")))
            });
        imports.define("ext", name, host);
    }
    Ok(())
}

fn valtype(w: WTy) -> wasmer::Type {
    match w {
        WTy::F64 => wasmer::Type::F64,
        WTy::I32 => wasmer::Type::I32,
    }
}

/// Marshal `args` (the import's input params) into the side module's memory per the
/// C-call signature, call the target export with the full C argument list (inputs +
/// an `_Out_` scratch cell per output pointer), then read the C return value and
/// each output back into the import's results, freeing the temporaries. Real/Int/
/// Bool and external-object `Ptr` handles pass straight through; input `Str`/`Array`
/// are copied into freshly `malloc`'d side-module memory; output scalars are read
/// from their scratch cell; output `char*`/`char**` strings are copied out of the
/// side module's memory into a fresh in-wasm string (`rt_str_new`/`rt_str_data`).
/// Mirrors `sim_runtime_wasmtime::call_external`.
fn call_external_side(fenv: &mut wasmer::FunctionEnvMut<ExtEnv>, args: &[wasmer::Value]) -> Result<Vec<wasmer::Value>> {
    use crate::CodegenWasmJitFunctions::SigTy;
    use wasmer::Value;
    let (data, mut store) = fenv.data_and_store_mut();
    let sim_mem = data.sim_mem.clone();
    let side_mem = data.side_mem.clone();
    let malloc = data.malloc.clone();
    let free = data.free.clone();
    let rt_str_new = data.rt_str_new.clone();
    let rt_str_data = data.rt_str_data.clone();
    let func = data.func.clone();
    let sig = data.sig.clone();

    // The `ModelicaAllocateString` buffers this call produces are recorded fresh.
    SIDE_STR_TEMPS.with(|t| t.borrow_mut().clear());

    // Full C argument list, in `extArgs` order: inputs marshalled from the import's
    // params, outputs an 8-byte scratch cell (fits int/double/pointer) in side mem.
    let mut call_args: Vec<Value> = Vec::with_capacity(sig.args.len());
    let mut temps: Vec<u32> = Vec::new();
    // (output SigTy, scratch offset), in output order — matches the import's results.
    let mut out_cells: Vec<(SigTy, u32)> = Vec::new();
    // Output arrays to copy back after the call: (sim array offset, side scratch
    // offset, byte length, header data offset).
    let mut out_arrays: Vec<(u32, u32, usize, u32)> = Vec::new();
    let mut in_i = 0usize;
    for (ty, is_out) in &sig.args {
        // Scalar/string outputs get an `_Out_` scratch cell (returned as a result);
        // array outputs are pre-allocated on the wasm side and marshalled by the
        // `Array` arm below (passed by pointer, copied back after the call).
        if *is_out && !matches!(ty, SigTy::Array { .. }) {
            let cell = malloc.call(&mut store, 8).map_err(|e| anyhow!("{e:?}"))?;
            side_mem.view(&store).write(cell as u64, &[0u8; 8]).map_err(|e| anyhow!("{e}"))?;
            temps.push(cell);
            out_cells.push((ty.clone(), cell));
            call_args.push(Value::I32(cell as i32));
            continue;
        }
        let v = &args[in_i];
        in_i += 1;
        match ty {
            SigTy::Real => call_args.push(Value::F64(v.f64().ok_or_else(|| anyhow!("expected f64 arg {in_i}"))?)),
            SigTy::Int | SigTy::Bool | SigTy::Ptr => {
                call_args.push(Value::I32(v.i32().ok_or_else(|| anyhow!("expected i32 arg {in_i}"))?))
            }
            SigTy::Str => {
                let off = v.i32().ok_or_else(|| anyhow!("expected i32 String handle arg {in_i}"))? as u32;
                let len = read_u32_mem(&sim_mem, &store, off + 4)? as usize;
                let mut buf = vec![0u8; len + 1]; // + NUL
                sim_mem.view(&store).read((off + 8) as u64, &mut buf[..len]).map_err(|e| anyhow!("{e}"))?;
                let dst = malloc.call(&mut store, (len + 1) as u32).map_err(|e| anyhow!("{e:?}"))?;
                side_mem.view(&store).write(dst as u64, &buf).map_err(|e| anyhow!("{e}"))?;
                temps.push(dst);
                call_args.push(Value::I32(dst as i32));
            }
            SigTy::Array { elem, .. } => {
                let off = v.i32().ok_or_else(|| anyhow!("expected i32 array handle arg {in_i}"))? as u32;
                let ndims = read_u32_mem(&sim_mem, &store, off + 8)?;
                let total = read_u32_mem(&sim_mem, &store, off + 12)? as usize;
                let elem_size = if matches!(**elem, SigTy::Real) { 8 } else { 4 };
                let data_off = (16 + ndims * 4 + 7) & !7;
                let bytes = total * elem_size;
                let mut buf = vec![0u8; bytes];
                sim_mem.view(&store).read((off + data_off) as u64, &mut buf).map_err(|e| anyhow!("{e}"))?;
                let dst = malloc.call(&mut store, bytes as u32).map_err(|e| anyhow!("{e:?}"))?;
                side_mem.view(&store).write(dst as u64, &buf).map_err(|e| anyhow!("{e}"))?;
                temps.push(dst);
                call_args.push(Value::I32(dst as i32));
                // An output array is filled by the callee in side memory; copy it
                // back into the pre-allocated wasm array after the call.
                if *is_out {
                    out_arrays.push((off, dst, bytes, data_off));
                }
            }
            other => bail!("input argument type {other:?} not marshalled for the web target"),
        }
    }

    let rets = func.call(&mut store, &call_args).map_err(|e| anyhow!("{e:?}"))?;

    // Copy each output array back from the side module's memory into its
    // pre-allocated wasm array (the callee filled the side scratch in place).
    for (woff, dst, bytes, data_off) in &out_arrays {
        let mut buf = vec![0u8; *bytes];
        side_mem.view(&store).read(*dst as u64, &mut buf).map_err(|e| anyhow!("{e}"))?;
        sim_mem.view(&store).write((*woff + *data_off) as u64, &buf).map_err(|e| anyhow!("{e}"))?;
    }

    // Build an in-wasm String (in the sim memory) from a NUL-terminated `char*` at
    // `coff` in the side module's memory; returns its sim-memory offset.
    let mut make_string = |store: &mut wasmer::StoreMut, coff: u32| -> Result<u32> {
        let bytes = read_side_cstr(&side_mem, &*store, coff)?;
        let soff = rt_str_new.call(&mut *store, bytes.len() as u32).map_err(|e| anyhow!("{e:?}"))?;
        let doff = rt_str_data.call(&mut *store, soff).map_err(|e| anyhow!("{e:?}"))?;
        sim_mem.view(&*store).write(doff as u64, &bytes).map_err(|e| anyhow!("{e}"))?;
        Ok(soff)
    };
    let result_val = |store: &mut wasmer::StoreMut, ty: &SigTy, raw: [u8; 8],
                      make: &mut dyn FnMut(&mut wasmer::StoreMut, u32) -> Result<u32>| -> Result<Value> {
        Ok(match ty {
            SigTy::Real => Value::F64(f64::from_le_bytes(raw)),
            SigTy::Int | SigTy::Bool | SigTy::Ptr => Value::I32(i32::from_le_bytes(raw[..4].try_into().unwrap())),
            SigTy::Str => Value::I32(make(store, u32::from_le_bytes(raw[..4].try_into().unwrap()))? as i32),
            other => bail!("output type {other:?} not marshalled for the web target"),
        })
    };

    let mut results: Vec<Value> = Vec::new();
    if let Some(ret_ty) = &sig.ret {
        // The C return value (from the wasm export's own result).
        let raw = match ret_ty {
            SigTy::Real => rets.first().and_then(|v| v.f64()).ok_or_else(|| anyhow!("expected f64 return"))?.to_le_bytes(),
            _ => {
                let x = rets.first().and_then(|v| v.i32()).ok_or_else(|| anyhow!("expected i32 return"))?;
                let mut b = [0u8; 8];
                b[..4].copy_from_slice(&x.to_le_bytes());
                b
            }
        };
        results.push(result_val(&mut store, ret_ty, raw, &mut make_string)?);
    }
    for (ty, cell) in &out_cells {
        let mut raw = [0u8; 8];
        side_mem.view(&store).read(*cell as u64, &mut raw).map_err(|e| anyhow!("{e}"))?;
        results.push(result_val(&mut store, ty, raw, &mut make_string)?);
    }

    for t in temps {
        let _ = free.call(&mut store, t);
    }
    SIDE_STR_TEMPS.with(|t| {
        for off in t.borrow_mut().drain(..) {
            let _ = free.call(&mut store, off);
        }
    });
    Ok(results)
}

/// Read a NUL-terminated C string from the side module's memory at `off`.
fn read_side_cstr(mem: &wasmer::Memory, store: &impl wasmer::AsStoreRef, off: u32) -> Result<Vec<u8>> {
    let view = mem.view(store);
    let mut out = Vec::new();
    let mut a = off as u64;
    loop {
        let mut b = [0u8; 1];
        view.read(a, &mut b).map_err(|e| anyhow!("{e}"))?;
        if b[0] == 0 { break; }
        out.push(b[0]);
        a += 1;
    }
    Ok(out)
}

pub(super) fn run(model: &SimModel) -> Result<sim_driver::RunResult> {
    let bench = std::env::var("OMC_WASM_SIM_BENCH").is_ok();
    let (mut engine, sim_data) = build_engine(model)?;
    // `OMC_WASM_SIM_DRIVER=host` forces the native Euler loop over the in-wasm one.
    let host_driven = std::env::var("OMC_WASM_SIM_DRIVER").map(|v| v == "host").unwrap_or(false);
    let n_steps = model.n_intervals;
    let n_rows = n_steps + 1;
    let t0 = Instant::now();
    let (result, driver_label) =
        sim_driver::drive(&mut *engine, model, sim_data, model.method.as_str(), host_driven, bench)?;
    if bench {
        let elapsed = t0.elapsed();
        eprintln!(
            "wasm-jit sim [{}]: integrate {:?} ({} intervals, {:.2} us/interval)",
            driver_label, elapsed, n_steps, elapsed.as_secs_f64() * 1e6 / (n_rows.max(1) as f64),
        );
    }
    Ok(result)
}

/// Build the engine (compile/join modules, instantiate, allocate `SimData`), boxed
/// with the `SimData` pointer; owned by the session across `advance` calls, reused
/// by [`run`] one-shot.
pub(super) fn build_engine(model: &SimModel) -> Result<(Box<dyn sim_driver::SimEngine + 'static>, u32)> {
    let bench = std::env::var("OMC_WASM_SIM_BENCH").is_ok();
    let engine = sim_engine();

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
    let prepared = model.prepared.lock().unwrap().take();
    let model_module = match prepared {
        Some(m) => m,
        None => take_compiled_model(model)?,
    };
    let model_compile = t_model.elapsed();
    let compile_time = t_compile.elapsed();
    if bench {
        eprintln!(
            "wasm-jit sim: module fetch — runtime.wasm ({} KB) {:?} (cached/compiled), model.wasm ({} KB) {:?} (join/compile)",
            RUNTIME_WASM.len() / 1024, rt_compile, model.wasm.len() / 1024, model_compile,
        );
    }

    // Phase 2: instantiate (sharing the runtime's linear memory). Host imports
    // are store-bound in wasmer, so they are built here (per run) rather than
    // cached; this is just function-handle creation, negligible next to compile.
    let t_inst = Instant::now();
    let mut store = wasmer::Store::new(engine.clone());
    let mut imports = wasmer::Imports::new();
    add_host_builtins(&mut store, &mut imports)?;
    let rt_inst = wt(wasmer::Instance::new(&mut store, runtime_module, &imports))?;
    // The generated module imports the runtime's exports under module name "rt".
    imports.register_namespace("rt", rt_inst.exports.iter().map(|(k, v)| (k.clone(), v.clone())));

    let memory = rt_inst
        .exports
        .get_memory("memory")
        .map_err(|e| anyhow!("CodegenWasmJit: runtime has no `memory` export: {e:?}"))?
        .clone();

    // External "C" functions (`ext.*`): resolved by the ModelicaExternalC WASI side
    // module (table blocks / external objects / string scanning). Must be wired
    // before the model instance, which imports them. The side trampolines build
    // in-wasm strings for `char*`/`char**` outputs via the runtime's constructors.
    if !model.ext_imports.is_empty() {
        let rt_str_new: wasmer::TypedFunction<u32, u32> = wt(rt_inst.exports.get_typed_function(&store, "rt_str_new"))?;
        let rt_str_data: wasmer::TypedFunction<u32, u32> = wt(rt_inst.exports.get_typed_function(&store, "rt_str_data"))?;
        define_external_imports(&mut store, &mut imports, model, &memory, &rt_str_new, &rt_str_data)?;
    }

    let instance = wt(wasmer::Instance::new(&mut store, &model_module, &imports))?;
    let inst_time = t_inst.elapsed();
    let rt_alloc: wasmer::TypedFunction<u32, u32> = wt(rt_inst.exports.get_typed_function(&store, "rt_alloc"))?;

    let layout = &model.layout;

    // Allocate the shared SimData block.
    let sim_data = wt(rt_alloc.call(&mut store, layout.total))?;

    if bench {
        eprintln!("wasm-jit sim: compile {compile_time:?} | instantiate {inst_time:?}");
    }
    let engine = WasmerEngine { store, memory, instance, funcs: HashMap::new() };
    Ok((Box::new(engine), sim_data))
}

/// wasmer backend for the [`sim_driver::SimEngine`] drivers: owns the store, the
/// shared linear memory, the model instance, and a cache of resolved
/// `fn(u32) -> ()` equation functions.
struct WasmerEngine {
    store: Store,
    memory: wasmer::Memory,
    instance: wasmer::Instance,
    funcs: HashMap<String, wasmer::TypedFunction<u32, ()>>,
}

impl WasmerEngine {
    fn func(&mut self, name: &str) -> Result<wasmer::TypedFunction<u32, ()>> {
        if let Some(f) = self.funcs.get(name) {
            return Ok(f.clone());
        }
        let f = wt(self.instance.exports.get_typed_function::<u32, ()>(&self.store, name))?;
        self.funcs.insert(name.to_string(), f.clone());
        Ok(f)
    }
}

impl sim_driver::SimEngine for WasmerEngine {
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> Result<()> {
        self.memory.view(&self.store).read(addr as u64, buf).map_err(|e| anyhow!("CodegenWasmJit: mem read: {e}"))
    }
    fn write_bytes(&mut self, addr: u32, buf: &[u8]) -> Result<()> {
        self.memory.view(&self.store).write(addr as u64, buf).map_err(|e| anyhow!("CodegenWasmJit: mem write: {e}"))
    }
    fn call1(&mut self, name: &str, arg: u32) -> Result<()> {
        let f = self.func(name)?;
        wt(f.call(&mut self.store, arg))
    }
    fn call1_if_present(&mut self, name: &str, arg: u32) -> Result<()> {
        if self.instance.exports.get_extern(name).is_none() {
            return Ok(());
        }
        self.call1(name, arg)
    }
    fn call_simulate(&mut self, sim_data: u32, start: f64, stop: f64, n_steps: u32) -> Result<u32> {
        let f: wasmer::TypedFunction<(u32, f64, f64, u32), u32> =
            wt(self.instance.exports.get_typed_function(&self.store, "simulate"))?;
        wt(f.call(&mut self.store, sim_data, start, stop, n_steps))
    }
    fn take_pending_assert(&mut self) -> Option<[i32; 7]> {
        crate::CodegenWasmJitFunctions::runtime::take_pending_assert()
    }
}

