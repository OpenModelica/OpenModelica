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

use crate::sim_driver;
use crate::model::SimModel;
use openmodelica_sim_meta::SimMeta;
use crate::sig::WTy;
use crate::host::add_host_builtins;

/// The runtime module, embedded the same way the function half embeds it.
use crate::{RUNTIME_WASM, RUNTIME_WASM_INTERACTIVE_WASIP1};

/// The std wasip1 interactive runtime (in-wasm rsparse) when it was produced, else
/// the no_std `RUNTIME_WASM` fallback (densifies). The interactive blob additionally
/// imports `wasi_snapshot_preview1`, served by `wasi_shim`.
fn runtime_blob() -> &'static [u8] {
    if RUNTIME_WASM_INTERACTIVE_WASIP1().is_empty() {
        RUNTIME_WASM()
    } else {
        RUNTIME_WASM_INTERACTIVE_WASIP1()
    }
}

/// The ModelicaExternalC WASI side module (`build.rs`), providing the
/// `ext.Modelica*_*` external functions (table blocks, string scanning, …) on the
/// web target. Empty when `emcc` was unavailable at build time — these externals
/// are then reported as unavailable at run time (see [`define_external_imports`]).

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
pub fn sim_engine() -> &'static wasmer::Engine {
    use wasmer::sys::{Cranelift, CraneliftOptLevel, EngineBuilder};
    static ENGINE: OnceLock<wasmer::Engine> = OnceLock::new();
    ENGINE.get_or_init(|| {
        let mut compiler = Cranelift::default();
        // Experimental opt-level override; default is cranelift's `Speed`.
        // (wasmer compiles module functions in parallel and exposes no knob for it,
        // so `-n=1` only stops the precompile, not this.)
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
pub fn sim_engine() -> &'static wasmer::Engine {
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
pub fn runtime_module() -> std::result::Result<&'static wasmer::Module, String> {
    static MODULE: OnceLock<std::result::Result<wasmer::Module, String>> = OnceLock::new();
    MODULE
        .get_or_init(|| load_or_compile_runtime())
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
#[cfg(not(target_arch = "wasm32"))]
fn runtime_cache_path() -> std::path::PathBuf {
    use std::hash::{Hash, Hasher};
    let mut h = std::collections::hash_map::DefaultHasher::new();
    runtime_blob().len().hash(&mut h);
    runtime_blob().hash(&mut h);
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

fn load_or_compile_runtime() -> std::result::Result<wasmer::Module, String> {
    let engine = sim_engine();
    // wasm has no filesystem for an on-disk AOT cache (and `temp_dir()` panics);
    // the in-memory OnceLock already caches the compiled module for the session,
    // so compile straight from the embedded bytes.
    #[cfg(target_arch = "wasm32")]
    return wts(wasmer::Module::from_binary(engine, runtime_blob()));
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
    let module = wts(wasmer::Module::from_binary(engine, runtime_blob()))?;
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
/// wasmer has no epoch interruption, so there is no hard `-alarm` to install.
pub fn set_alarm(_seconds: Option<u32>) {}

pub fn compile_model_module(wasm: &[u8]) -> std::result::Result<wasmer::Module, String> {
    wts(wasmer::Module::from_binary(sim_engine(), wasm))
}

/// Begin compiling the fixed runtime module on a background thread, once per
/// process. The runtime module does not depend on the model, so this can be
/// started as soon as we know a wasm-jit simulation is coming (`translateModel`
/// entry) — it then compiles while `build_sim_model` generates the model bytes,
/// and `run` only waits for whatever did not overlap. Idempotent.
pub fn start_runtime_compile() {
    // wasm has no threads; the runtime module is compiled synchronously on first
    // use (`runtime_module()` is called from finishCompile / run). Skipping the
    // prewarm only forgoes the native overlap optimisation.
    #[cfg(target_arch = "wasm32")]
    return;
    #[cfg(not(target_arch = "wasm32"))]
    {
        // Same under `-n=1`.
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
}

/// Take the model module compiled on the background thread `translateModel`
/// spawned (joining it), or compile inline if there is no pending job.
pub fn take_compiled_model(model: &SimModel) -> std::result::Result<wasmer::Module, String> {
    let job = model.compiled.lock().unwrap().take();
    match job {
        // Native: the job is a thread handle to join. wasm: the job is the
        // already-computed compile result.
        #[cfg(not(target_arch = "wasm32"))]
        Some(handle) => match handle.join() {
            Ok(Ok(m)) => Ok(m),
            Ok(Err(e)) => Err(format!("background model-module compile failed: {e}")),
            Err(_) => Err("CodegenWasmJit: background model-module compile thread panicked".to_string()),
        },
        #[cfg(target_arch = "wasm32")]
        Some(Ok(m)) => Ok(m),
        #[cfg(target_arch = "wasm32")]
        Some(Err(e)) => Err(format!("model-module compile failed: {e}")),
        None => compile_model_module(&model.wasm),
    }
}

/// Nothing to prepare: the `external "C"` implementations are in the
/// ModelicaExternalC side module, built into omc. Which is also why no run on
/// this engine is ever isolated, so [`ensure_prepared`] has nothing to do.
pub fn prepare_native_externals(_model: &SimModel, _sigs: &[crate::sig::ExtCallSig]) -> std::result::Result<(), String> {
    Ok(())
}

pub fn ensure_prepared(_model: &SimModel) {}

/// One engine, whatever the module: nothing to select.
pub fn select_engine_for(_wasm: &[u8]) {}

type Store = wasmer::Store;

/// `SimEngine`-trait / host-import errors: collapse to the crate `&'static str`
/// (a model `assert()` is decoded downstream by `enrich_trap`). wasmer's error
/// types don't share one convertible type, hence the generic `Debug` bound.
fn wt<T, E: std::fmt::Debug>(r: std::result::Result<T, E>) -> Result<T> {
    r.map_err(|e| {
        crate::set_engine_error_detail(format!("{e:?}"));
        "CodegenWasmJit: wasm engine error"
    })
}

/// Setup path: keep the real wasmer message as a `String` for the run log.
fn wts<T, E: std::fmt::Debug>(r: std::result::Result<T, E>) -> std::result::Result<T, String> {
    r.map_err(|e| format!("wasm engine error: {e:?}"))
}

/// Read a NUL-terminated C string from wasm memory at `ptr` (bounded).
pub(crate) fn read_cstr(mem: &wasmer::Memory, store: &impl wasmer::AsStoreRef, ptr: u32) -> String {
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

/// Wire the `ext.*` external "C" imports: load the model's own shared libraries,
/// and the ones omc carries that it reaches, into the **runtime's** memory with
/// [`crate::dylink_wasmer`], then bind each `ext.<name>` to what they define.
/// Sharing the memory is what makes an array argument the model's own elements
/// rather than a copy. Mirrors `sim_runtime_wasmtime`.
fn define_external_imports(
    store: &mut Store,
    imports: &mut wasmer::Imports,
    model: &SimModel,
    sim_mem: &wasmer::Memory,
    rt_inst: &wasmer::Instance,
    host_mem: &crate::host::HostMem,
    rt_str_new: &wasmer::TypedFunction<u32, u32>,
    rt_str_data: &wasmer::TypedFunction<u32, u32>,
    rt_release: &wasmer::TypedFunction<u32, ()>,
) -> Result<()> {
    use crate::dylink_wasmer::{self as dl, ExtRt, Library, NlsHooks};
    use wasmer::FunctionType;

    if crate::LIBC_PIC().is_empty() {
        crate::set_engine_error_detail(
            "  this omc carries no PIC libc, so no shared library can be loaded".to_owned(),
        );
        return Err("CodegenWasmJit: external \"C\" support was not built");
    }
    let table = wt(rt_inst.exports.get_table("__indirect_function_table"))?.clone();
    let rt = ExtRt {
        str_new: rt_str_new.clone(),
        str_data: rt_str_data.clone(),
        release: rt_release.clone(),
        alloc: wt(rt_inst.exports.get_typed_function(&*store, "rt_alloc"))?,
        free: wt(rt_inst.exports.get_typed_function(&*store, "rt_free"))?,
        record_new: wt(rt_inst.exports.get_typed_function(&*store, "rt_record_new"))?,
        nls: Some(NlsHooks {
            recovering: wt(rt_inst.exports.get_typed_function(&*store, "rt_nls_recovering"))?,
            note: wt(rt_inst.exports.get_typed_function(&*store, "rt_nls_note_assert"))?,
        }),
    };
    let (host_imports, util_env) = run_utilities_imports(store, rt_inst, sim_mem, &rt)?;

    // `libc.so` first and the rest dependency-first (see `dylink::libraries_for`).
    // The model's own come before the ones omc carries, so a shared symbol is
    // theirs; `usertab` last, so a model's own overrides the erroring default.
    let mut libs: Vec<Library> = vec![Library { name: "libc.so", bytes: crate::LIBC_PIC() }];
    libs.extend(model.ext_libs.iter().map(|l| Library { name: &l.name, bytes: &l.bytes }));
    let carried = crate::dylink::libraries_for(model.ext_imports.iter().map(|s| s.name.as_str()));
    for file in &carried {
        if let Some(bytes) = crate::ext_library(file) {
            libs.push(Library { name: file, bytes });
        }
    }
    libs.push(Library { name: "usertab", bytes: crate::USERTAB_DYLINK() });
    let loaded = dl::link_into(store, sim_mem.clone(), table, &rt.alloc, &libs, &host_imports)
        .map_err(|e| {
            crate::set_engine_error_detail(format!("  {e}"));
            "CodegenWasmJit: an external \"C\" library could not be loaded"
        })?;
    util_env.as_mut(store).vsnprintf = loaded.func("vsnprintf").and_then(|f| f.typed(&*store).ok());
    host_mem.set_side(store, sim_mem, loaded.stack_pointer.clone());

    for sig in &model.ext_imports {
        let name = &sig.name;
        let Some(target) = loaded.func_or_addr(store, name) else {
            crate::set_engine_error_detail(format!(
                "  no shared library defines `{name}` — the model's own `Library` \
                 annotations and the ModelicaExternalC omc carries were searched"
            ));
            return Err("CodegenWasmJit: external \"C\" function not in any library");
        };
        let functype = FunctionType::new(
            sig.wasm_params().iter().map(|s| valtype(s.wty())).collect::<Vec<_>>(),
            sig.wasm_results().iter().map(|s| valtype(s.wty())).collect::<Vec<_>>(),
        );
        let Some(ext) = dl::bind_in_wasm_external(
            store, sig, &functype, target, &rt, sim_mem, loaded.stack_pointer.clone(),
        ) else {
            crate::set_engine_error_detail(format!(
                "  `{name}` has a different wasm type than the model's call to it"
            ));
            return Err("CodegenWasmJit: external \"C\" function has the wrong signature");
        };
        imports.define("ext", name, ext);
    }
    Ok(())
}

/// What a `ModelicaUtilities` host import needs. The js backend takes only a
/// *non-capturing* closure for a typed host function, so it all lives here.
struct RunEnv {
    memory: wasmer::Memory,
    throw: wasmer::Function,
    alloc: wasmer::TypedFunction<u32, u32>,
    /// The guest's own `vsnprintf`, filled in once the libraries are placed, so a
    /// `Modelica*Format*` message is interpolated where its `va_list` lives.
    vsnprintf: Option<wasmer::TypedFunction<(u32, u32, u32, u32), u32>>,
}

/// `vsnprintf(buf, 2048, fmt, va)` in the guest, as C's `SIZE_LOG_BUFFER` does.
fn run_format(
    env: &mut wasmer::FunctionEnvMut<RunEnv>,
    fmt: i32,
    va: i32,
) -> std::result::Result<String, wasmer::RuntimeError> {
    const LOG_BUFFER: u32 = 2048;
    let (vsnprintf, alloc) = (env.data().vsnprintf.clone(), env.data().alloc.clone());
    let Some(vsnprintf) = vsnprintf else { return Ok(run_msg(env, fmt)) };
    let buf = alloc.call(&mut *env, LOG_BUFFER)?;
    vsnprintf.call(&mut *env, buf, LOG_BUFFER, fmt as u32, va as u32)?;
    Ok(run_msg(env, buf as i32))
}

fn run_msg(env: &wasmer::FunctionEnvMut<RunEnv>, ptr: i32) -> String {
    use wasmer::AsStoreRef;
    let mem = env.data().memory.clone();
    read_cstr(&mem, &env.as_store_ref(), ptr as u32)
}

/// The `ModelicaUtilities` a library calls during a run. `ModelicaError` goes to
/// the runtime's own `rt_ext_error`, bound wasm->wasm so its throw reaches the
/// model's `try_table`; the rest are host closures writing to the run's log.
fn run_utilities_imports(
    store: &mut Store,
    rt_inst: &wasmer::Instance,
    memory: &wasmer::Memory,
    rt: &crate::dylink_wasmer::ExtRt,
) -> Result<(std::collections::HashMap<String, wasmer::Function>, wasmer::FunctionEnv<RunEnv>)> {
    use openmodelica_sim_meta::omclog;
    use wasmer::{Function, FunctionEnv, FunctionEnvMut, RuntimeError, Value};

    let throw = wt(rt_inst.exports.get_function("rt_ext_error"))?.clone();
    let env = FunctionEnv::new(store, RunEnv {
        memory: memory.clone(),
        throw: throw.clone(),
        alloc: rt.alloc.clone(),
        vsnprintf: None,
    });
    let warning = Function::new_typed_with_env(store, &env, |env: FunctionEnvMut<RunEnv>, ptr: i32| {
        omclog::warning(omclog::STDOUT, false, &run_msg(&env, ptr));
    });
    let message = Function::new_typed_with_env(store, &env, |env: FunctionEnvMut<RunEnv>, ptr: i32| {
        omclog::info(omclog::STDOUT, false, &run_msg(&env, ptr));
    });
    // The varargs forms are interpolated by the guest's own `vsnprintf`; the error
    // one then throws through the runtime, so it reaches the model's `try_table`.
    let error_fmt = Function::new_typed_with_env(store, &env, |mut env: FunctionEnvMut<RunEnv>, fmt: i32, va: i32| -> std::result::Result<(), RuntimeError> {
        let msg = run_format(&mut env, fmt, va)?;
        let (throw, alloc) = (env.data().throw.clone(), env.data().alloc.clone());
        let cell = alloc.call(&mut env, msg.len() as u32 + 1)?;
        let mem = env.data().memory.clone();
        let mut bytes = msg.into_bytes();
        bytes.push(0);
        mem.view(&env).write(cell as u64, &bytes).map_err(|e| RuntimeError::new(format!("{e}")))?;
        throw.call(&mut env, &[Value::I32(cell as i32)])?;
        Ok(())
    });
    let warning_fmt = Function::new_typed_with_env(store, &env, |mut env: FunctionEnvMut<RunEnv>, fmt: i32, va: i32| -> std::result::Result<(), RuntimeError> {
        omclog::warning(omclog::STDOUT, false, &run_format(&mut env, fmt, va)?);
        Ok(())
    });
    let message_fmt = Function::new_typed_with_env(store, &env, |mut env: FunctionEnvMut<RunEnv>, fmt: i32, va: i32| -> std::result::Result<(), RuntimeError> {
        omclog::info(omclog::STDOUT, false, &run_format(&mut env, fmt, va)?);
        Ok(())
    });
    // The simulation's allocator, so a string the callee builds is readable from
    // the model's memory.
    let allocate = Function::new_typed_with_env(store, &env, |mut env: FunctionEnvMut<RunEnv>, len: i32| -> std::result::Result<i32, RuntimeError> {
        let (alloc, mem) = (env.data().alloc.clone(), env.data().memory.clone());
        let n = len.max(0) as u32 + 1;
        let p = alloc.call(&mut env, n)?;
        mem.view(&env).write(p as u64, &vec![0u8; n as usize])
            .map_err(|e| RuntimeError::new(format!("{e}")))?;
        Ok(p as i32)
    });
    // `ModelicaInternal_getTime` writes nothing (its seven int* outputs stay as
    // they are) and `getpid` is a constant; only ModelicaRandom's automatic global
    // seed uses them.
    let get_time = Function::new_typed(store, |_: i32, _: i32, _: i32, _: i32, _: i32, _: i32, _: i32| {});
    let getpid = Function::new_typed(store, || -> i32 { 1 });

    let mut m = std::collections::HashMap::new();
    for (names, f) in [
        (["rt_ext_error", "ModelicaError"], throw),
        (["rt_ext_warning", "ModelicaWarning"], warning),
        (["rt_ext_message", "ModelicaMessage"], message),
        (["ModelicaFormatError", "ModelicaVFormatError"], error_fmt),
        (["ModelicaFormatWarning", "ModelicaVFormatWarning"], warning_fmt),
        (["ModelicaFormatMessage", "ModelicaVFormatMessage"], message_fmt),
        (["ModelicaAllocateString", "ModelicaAllocateStringWithErrorReturn"], allocate),
    ] {
        for name in names {
            m.insert(name.to_owned(), f.clone());
        }
    }
    m.insert("ModelicaInternal_getTime".to_owned(), get_time);
    m.insert("ModelicaInternal_getpid".to_owned(), getpid);
    Ok((m, env))
}

fn valtype(w: WTy) -> wasmer::Type {
    match w {
        WTy::F64 => wasmer::Type::F64,
        WTy::I32 => wasmer::Type::I32,
    }
}
/// `rt.rt_print` for the web target: read the String handle's bytes from the
/// shared memory and write them to the model's captured stdout. The wasmer
/// counterpart of `sim_runtime_wasmtime::define_print_import`.
fn define_print_import(store: &mut Store, imports: &mut wasmer::Imports, memory: &wasmer::Memory) {
    use wasmer::{AsStoreRef, Function, FunctionEnv, FunctionEnvMut};
    let env = FunctionEnv::new(&mut *store, memory.clone());
    let f = Function::new_typed_with_env(
        &mut *store,
        &env,
        |env: FunctionEnvMut<wasmer::Memory>, handle: i32| {
            if handle == 0 {
                return;
            }
            // String layout: [refcount:u32][len:u32][utf8]; bytes start at handle + 8.
            let mem = env.data().clone();
            let store_ref = env.as_store_ref();
            let view = mem.view(&store_ref);
            let h = handle as u64;
            let mut lenb = [0u8; 4];
            if view.read(h + 4, &mut lenb).is_err() {
                return;
            }
            let mut bytes = vec![0u8; u32::from_le_bytes(lenb) as usize];
            if view.read(h + 8, &mut bytes).is_err() {
                return;
            }
            openmodelica_wasi::wasi::stdout_write(&bytes);
        },
    );
    imports.define("rt", "rt_print", f);
}

pub fn run(
    model: &SimModel,
    meta: &SimMeta,
    result: crate::result_sink::ResultTarget,
) -> std::result::Result<(sim_driver::RunResult, crate::result_sink::Written), String> {
    let bench = crate::model::sim_bench_enabled();
    if crate::model::inwasm_driver_enabled() {
        return run_inwasm(model, bench, result);
    }
    crate::result_sink::arm(result);
    let (mut engine, sim_data) = build_engine(model, meta)?;
    // `OMC_WASM_SIM_DRIVER=host` forces the native Euler loop over the in-wasm one.
    let host_driven = std::env::var("OMC_WASM_SIM_DRIVER").map(|v| v == "host").unwrap_or(false);
    let n_steps = meta.n_intervals;
    let n_rows = n_steps + 1;
    let t0 = Instant::now();
    let driven = sim_driver::drive(&mut *engine, meta, sim_data, meta.method.as_str(), host_driven, bench);
    let written = crate::result_sink::take();
    let (mut result, driver_label) = driven?;
    // The solves ran in-wasm, where the driver's stats cannot see them.
    result.stats.lin_solves = engine.lin_solves();
    if bench {
        let elapsed = t0.elapsed();
        eprintln!(
            "wasm-jit sim [{}]: integrate {:?} ({} intervals, {:.2} us/interval)",
            driver_label, elapsed, n_steps, elapsed.as_secs_f64() * 1e6 / (n_rows.max(1) as f64),
        );
    }
    Ok((result, written))
}

/// One-shot in-wasm run (used by [`run`] under `OMC_WASM_INWASM_DRIVER`): start,
/// pump to completion with an unbounded budget, read the result.
fn run_inwasm(
    model: &SimModel,
    bench: bool,
    target: crate::result_sink::ResultTarget,
) -> std::result::Result<(sim_driver::RunResult, crate::result_sink::Written), String> {
    let t0 = Instant::now();
    let mut sess = build_inwasm_session(model, Some(&target))?;
    loop {
        match sess.advance(f64::INFINITY)? {
            0 => continue,
            3 => return Err("CodegenWasmJit: in-wasm simulation cancelled".to_string()),
            _ => break, // 1 done, 2 terminated
        }
    }
    let result = sess.take_result()?;
    let written = sess.take_written()?;
    // The traces were collected in-wasm; the report is rendered here, once the
    // result file the run reports on has been written.
    let prof = sess.take_prof()?;
    if !prof.is_empty() {
        openmodelica_sim_meta::profiling::adopt(&model.meta, &prof);
    }
    if bench {
        eprintln!(
            "wasm-jit sim [in-wasm]: integrate {:?} ({} intervals), {} steps, {} residual evals",
            t0.elapsed(), model.n_intervals, result.stats.steps, result.stats.res_evals
        );
    }
    Ok((result, written))
}

/// A runtime+model pair instantiated into one store, sharing the runtime's linear
/// memory. Common to the host-driver path ([`build_engine`]) and the in-wasm
/// session ([`build_inwasm_session`]).
struct Instantiated {
    store: Store,
    rt_inst: wasmer::Instance,
    instance: wasmer::Instance,
    memory: wasmer::Memory,
    rt_alloc: wasmer::TypedFunction<u32, u32>,
}

/// Compile/join the modules and instantiate them (runtime first, then model,
/// sharing the runtime's `memory`).
fn instantiate_modules(model: &SimModel, meta: &SimMeta) -> std::result::Result<Instantiated, String> {
    let bench = crate::model::sim_bench_enabled();
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
    // Clone, not take: keep the module cached so a resimulate reuses it instead
    // of recompiling the whole model.
    let prepared = model.prepared.lock().unwrap().clone();
    let model_module = match prepared {
        Some(m) => m,
        None => take_compiled_model(model)?,
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

    // Phase 2: instantiate (sharing the runtime's linear memory). Host imports
    // are store-bound in wasmer, so they are built here (per run) rather than
    // cached; this is just function-handle creation, negligible next to compile.
    let t_inst = Instant::now();
    let mut store = wasmer::Store::new(engine.clone());
    let mut imports = wasmer::Imports::new();
    let host_mem = add_host_builtins(&mut store, &mut imports)?;
    // The interactive (std wasip1) runtime imports `wasi_snapshot_preview1`; serve it
    // from the same shim the ext-C side module uses, bound to the runtime's memory
    // (set after instantiation, once the export exists). No-op for the no_std fallback.
    let rt_wasi_env = wasmer::FunctionEnv::new(&mut store, crate::wasi_shim::Env::new("/"));
    crate::wasi_shim::add_to_imports(&mut store, &rt_wasi_env, &mut imports);
    let rt_inst = wts(wasmer::Instance::new(&mut store, runtime_module, &imports))?;
    // The generated module imports the runtime's exports under module name "rt".
    imports.register_namespace("rt", rt_inst.exports.iter().map(|(k, v)| (k.clone(), v.clone())));

    let memory = wts(rt_inst.exports.get_memory("memory"))?.clone();
    rt_wasi_env.as_mut(&mut store).set_memory(memory.clone());
    host_mem.set(&mut store, &memory);
    // A WASI reactor's `_initialize`, which the runtime exports on wasip1 only.
    if let Ok(init) = rt_inst.exports.get_typed_function::<(), ()>(&store, "_initialize") {
        wts(init.call(&mut store))?;
    }

    // External "C" functions (`ext.*`): resolved by the ModelicaExternalC WASI side
    // module (table blocks / external objects / string scanning). Must be wired
    // before the model instance, which imports them. The side trampolines build
    // in-wasm strings for `char*`/`char**` outputs via the runtime's constructors.
    if !model.ext_imports.is_empty() {
        let rt_str_new: wasmer::TypedFunction<u32, u32> = wts(rt_inst.exports.get_typed_function(&store, "rt_str_new"))?;
        let rt_str_data: wasmer::TypedFunction<u32, u32> = wts(rt_inst.exports.get_typed_function(&store, "rt_str_data"))?;
        let rt_release: wasmer::TypedFunction<u32, ()> = wts(rt_inst.exports.get_typed_function(&store, "rt_release"))?;
        define_external_imports(&mut store, &mut imports, model, &memory, &rt_inst, &host_mem, &rt_str_new, &rt_str_data, &rt_release)?;
    }
    define_print_import(&mut store, &mut imports, &memory);
    {
        let str_new: wasmer::TypedFunction<u32, u32> = wts(rt_inst.exports.get_typed_function(&store, "rt_str_new"))?;
        let str_data: wasmer::TypedFunction<u32, u32> = wts(rt_inst.exports.get_typed_function(&store, "rt_str_data"))?;
        crate::host::define_uri_import(&mut store, &mut imports, &memory, &str_new, &str_data);
    }

    let instance = wts(wasmer::Instance::new(&mut store, &model_module, &imports))?;
    let inst_time = t_inst.elapsed();
    // The runtime is instantiated first, so `rt_ext_error` reaches the model's
    // thrower only through the table.
    if !model.ext_imports.is_empty() {
        let throw = wts(instance.exports.get_function("om_throw_model_error"))?.clone();
        let table = wts(rt_inst.exports.get_table("__indirect_function_table"))?.clone();
        let slot = wts(table.grow(&mut store, 1, wasmer::Value::FuncRef(None)))?;
        wts(table.set(&mut store, slot, wasmer::Value::FuncRef(Some(throw))))?;
        let set: wasmer::TypedFunction<u32, ()> = wts(rt_inst.exports.get_typed_function(&store, "rt_set_ext_throw"))?;
        wts(set.call(&mut store, slot))?;
    }
    let rt_alloc: wasmer::TypedFunction<u32, u32> = wts(rt_inst.exports.get_typed_function(&store, "rt_alloc"))?;
    // Solver selectors; see the wasmtime runtime.
    if let Ok(set) = rt_inst.exports.get_typed_function::<(u32, u32, u32, u32), ()>(&store, "rt_set_solvers") {
        let (nls, nls_ls, ls, lss) = openmodelica_sim_meta::simflags::with_flags(|f| f.solver_codes());
        wts(set.call(&mut store, nls, nls_ls, ls, lss))?;
    }
    // See the wasmtime counterpart.
    if let Ok(set) = rt_inst.exports.get_typed_function::<(f64, f64, f64), ()>(&store, "rt_set_newton_tuning") {
        let (ftol, xtol, msf) = openmodelica_sim_meta::simflags::with_flags(|f| {
            openmodelica_sim_meta::simflags::newton_tuning(f)
        });
        wts(set.call(&mut store, ftol, xtol, msf))?;
    }
    // See the wasmtime counterpart.
    if let Ok(set) = rt_inst.exports.get_typed_function::<u32, ()>(&store, "rt_set_max_warn") {
        let n = openmodelica_sim_meta::simflags::with_flags(|f| f.max_warn.unwrap_or(3));
        wts(set.call(&mut store, n))?;
    }
    // See the wasmtime counterpart.
    if let Ok(set) =
        rt_inst.exports.get_typed_function::<(f64, f64), ()>(&store, "rt_set_jac_test_tolerances")
    {
        let t = openmodelica_sim_meta::simflags::with_flags(|f| {
            openmodelica_sim_meta::simflags::jac_test_tolerances(f)
        });
        wts(set.call(&mut store, t.0, t.1))?;
    }
    // See the wasmtime counterpart.
    if let Ok(set) = rt_inst.exports.get_typed_function::<(u32, f64, f64), ()>(&store, "rt_set_svd") {
        let (c, sigma, tol) = openmodelica_sim_meta::simflags::with_flags(|f| {
            openmodelica_sim_meta::simflags::svd_params(f)
        });
        wts(set.call(&mut store, c.max(0) as u32, sigma, tol))?;
    }
    // See the wasmtime counterpart.
    if let Ok(set) =
        rt_inst.exports.get_typed_function::<(i32, u32, u32), ()>(&store, "rt_set_save_initial_guess")
    {
        let req = openmodelica_sim_meta::simflags::with_flags(|f| f.save_initial_guess.clone());
        match req.map(|(p, i)| (format!("{p}\0{}", crate::host::absolute_path(&p)), i)) {
            Some((names, idx)) => {
                let ptr = wts(rt_alloc.call(&mut store, names.len() as u32))?;
                wts(memory.view(&store).write(ptr as u64, names.as_bytes()))?;
                wts(set.call(&mut store, idx, ptr, names.len() as u32))?;
            }
            None => wts(set.call(&mut store, -1, 0, 0))?,
        }
    }
    // See the wasmtime counterpart.
    if let Ok(set) = rt_inst.exports.get_typed_function::<(u32, u32), ()>(&store, "rt_set_homotopy") {
        let h = openmodelica_sim_meta::simflags::with_flags(|f| {
            openmodelica_sim_meta::simflags::homotopy_codes(f)
        });
        wts(set.call(&mut store, h.0, h.1))?;
    }
    // See the wasmtime counterpart.
    if let Ok(set) = rt_inst.exports.get_typed_function::<
        (f64, f64, f64, f64, f64, f64, f64, f64, f64, u32, u32, u32, u32, u32), ()>(
        &store, "rt_set_homotopy_tuning",
    ) {
        let h = openmodelica_sim_meta::simflags::with_flags(openmodelica_sim_meta::simflags::hom_tuning);
        wts(set.call(
            &mut store, h.adapt_bend, h.h_eps, h.tau_dec, h.tau_dec_pred, h.tau_inc,
            h.tau_inc_threshold, h.tau_max, h.tau_min, h.tau_start, h.max_lambda_steps,
            h.max_newton_steps, h.max_tries, h.orthogonal_backtrace as u32, h.neg_start_dir as u32,
        ))?;
    }
    let log_mask = openmodelica_sim_meta::simflags::with_flags(|f| f.log_mask);
    let active = openmodelica_sim_meta::omclog::mask();
    if let Ok(set) = rt_inst.exports.get_typed_function::<(u32, u32), ()>(&store, "rt_set_log_streams") {
        wts(set.call(&mut store, active as u32, (active >> 32) as u32))?;
    }
    // See the wasmtime counterpart.
    if let Ok(set) = rt_inst.exports.get_typed_function::<u32, ()>(&store, "rt_stats_start") {
        let on = openmodelica_sim_meta::omclog::mask_has(log_mask, openmodelica_sim_meta::omclog::STATS_V);
        wts(set.call(&mut store, on as u32))?;
    }
    if let Ok(set) = rt_inst.exports.get_typed_function::<(u32, u32, u32), ()>(&store, "rt_nls_set_names") {
        let free = rt_inst.exports.get_typed_function::<u32, ()>(&store, "rt_free").ok();
        wts(set.call(&mut store, u32::MAX, 0, 0))?;
        for sys in &meta.nls_vars {
            let mut blob = Vec::new();
            for n in &sys.names {
                blob.extend_from_slice(n.as_bytes());
                blob.push(0);
            }
            let ptr = wts(rt_alloc.call(&mut store, blob.len() as u32))?;
            wts(memory.view(&store).write(ptr as u64, &blob))?;
            wts(set.call(&mut store, sys.eq_index, ptr, blob.len() as u32))?;
            if let Some(f) = &free {
                wts(f.call(&mut store, ptr))?;
            }
        }
    }
    // See the wasmtime counterpart.
    if let Ok(set) = rt_inst.exports.get_typed_function::<(u32, u32, u32, u32, u32, u32, u32), ()>(&store, "rt_nls_set_diag") {
        let free = rt_inst.exports.get_typed_function::<u32, ()>(&store, "rt_free").ok();
        wts(set.call(&mut store, u32::MAX, 0, 0, 0, 0, 0, 0))?;
        for sys in &meta.nls_vars {
            let blob: Vec<u8> = sys.eqns.iter().flat_map(|i| (*i as u32).to_le_bytes()).collect();
            let ptr = wts(rt_alloc.call(&mut store, blob.len().max(1) as u32))?;
            wts(memory.view(&store).write(ptr as u64, &blob))?;
            let [ne, nv, nn] = sys.pattern;
            wts(set.call(&mut store, sys.eq_index, ne, nv, nn, sys.init_diag as u32, ptr, sys.eqns.len() as u32))?;
            if let Some(f) = &free {
                wts(f.call(&mut store, ptr))?;
            }
        }
    }
    if let Ok(set) = rt_inst.exports.get_typed_function::<f64, ()>(&store, "rt_set_step_size") {
        wts(set.call(&mut store, meta.step_size()))?;
    }
    // See the wasmtime counterpart.
    if let Ok(set) = rt_inst.exports.get_typed_function::<(u32, u32), ()>(&store, "rt_set_file_prefix") {
        let bytes = meta.prefix.as_bytes();
        let ptr = wts(rt_alloc.call(&mut store, bytes.len().max(1) as u32))?;
        wts(memory.view(&store).write(ptr as u64, bytes))?;
        wts(set.call(&mut store, ptr, bytes.len() as u32))?;
        if let Ok(free) = rt_inst.exports.get_typed_function::<u32, ()>(&store, "rt_free") {
            wts(free.call(&mut store, ptr))?;
        }
    }
    if bench {
        eprintln!("wasm-jit sim: compile {compile_time:?} | instantiate {inst_time:?}");
    }

    Ok(Instantiated { store, rt_inst, instance, memory, rt_alloc })
}

pub fn build_engine(model: &SimModel, meta: &SimMeta) -> std::result::Result<(Box<dyn sim_driver::SimEngine + 'static>, u32), String> {
    sim_driver::init_host_hooks(); // cancel poll + model-assertion routing (idempotent)
    let Instantiated { mut store, rt_inst, instance, memory, rt_alloc } = instantiate_modules(model, meta)?;

    let layout = &model.layout;
    // Allocate the shared SimData block.
    let sim_data_new =
        wts(rt_inst.exports.get_typed_function::<u32, u32>(&store, "rt_sim_data_new"))?;
    let sim_data = wts(sim_data_new.call(&mut store, layout.total))?;

    // See the wasmtime counterpart.
    if let Ok(set) =
        rt_inst.exports.get_typed_function::<(u32, u32, u32), i32>(&store, "rt_set_model_context")
    {
        let blob = openmodelica_sim_meta::encode(meta);
        let ptr = wts(rt_alloc.call(&mut store, blob.len() as u32))?;
        wts(memory.view(&store).write(ptr as u64, &blob))?;
        wts(set.call(&mut store, ptr, blob.len() as u32, sim_data))?;
    }

    let engine = WasmerEngine { store, memory, instance, rt_inst, funcs: HashMap::new(), funcs2: HashMap::new() };
    Ok((Box::new(engine), sim_data))
}

/// wasmer backend for the [`sim_driver::SimEngine`] drivers: owns the store, the
/// shared linear memory, the model instance, and a cache of resolved
/// `fn(u32) -> ()` equation functions.
struct WasmerEngine {
    store: Store,
    memory: wasmer::Memory,
    instance: wasmer::Instance,
    rt_inst: wasmer::Instance,
    funcs: HashMap<String, wasmer::TypedFunction<u32, ()>>,
    /// The DAE-mode residual, the one `fn(u32, u32) -> ()` entry point.
    /// Resolved two-argument exports by name (`evaluateDAEResiduals` and the
    /// synchronous dispatchers), so one cached entry cannot answer for another.
    funcs2: HashMap<String, wasmer::TypedFunction<(u32, u32), ()>>,
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
    fn set_log_mask(&mut self, mask: openmodelica_sim_meta::omclog::Mask) {
        if let Ok(set) = self.rt_inst.exports.get_typed_function::<(u32, u32), ()>(&self.store, "rt_set_log_streams") {
            let _ = set.call(&mut self.store, mask as u32, (mask >> 32) as u32);
        }
    }
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> Result<()> {
        self.memory.view(&self.store).read(addr as u64, buf).map_err(|e| "CodegenWasmJit: mem read")
    }
    fn write_bytes(&mut self, addr: u32, buf: &[u8]) -> Result<()> {
        self.memory.view(&self.store).write(addr as u64, buf).map_err(|e| "CodegenWasmJit: mem write")
    }
    fn call1_raw(&mut self, name: &str, arg: u32) -> Result<()> {
        let f = self.func(name)?;
        wt(f.call(&mut self.store, arg))
    }
    fn call1_if_present_raw(&mut self, name: &str, arg: u32) -> Result<()> {
        if self.instance.exports.get_extern(name).is_none() {
            return Ok(());
        }
        self.call1_raw(name, arg)
    }
    fn call2_raw(&mut self, name: &str, a: u32, b: u32) -> Result<()> {
        let f = match self.funcs2.get(name) {
            Some(f) => f.clone(),
            None => {
                let f = wt(self.instance.exports.get_typed_function::<(u32, u32), ()>(&self.store, name))?;
                self.funcs2.insert(name.to_string(), f.clone());
                f
            }
        };
        wt(f.call(&mut self.store, a, b))
    }
    fn call_simulate(&mut self, sim_data: u32, start: f64, stop: f64, n_steps: u32) -> Result<u32> {
        let f: wasmer::TypedFunction<(u32, f64, f64, u32), u32> =
            wt(self.instance.exports.get_typed_function(&self.store, "simulate"))?;
        wt(f.call(&mut self.store, sim_data, start, stop, n_steps))
    }
    fn has_simulate_entry(&mut self) -> bool {
        self.instance
            .exports
            .get_typed_function::<(u32, f64, f64, u32), u32>(&self.store, "simulate")
            .is_ok()
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
        match self.rt_inst.exports.get_typed_function::<(), u64>(&self.store, "rt_lin_solves") {
            Ok(f) => f.call(&mut self.store).unwrap_or(0),
            Err(_) => 0,
        }
    }
    fn sys_stats(&mut self) -> Vec<openmodelica_sim_meta::sysstat::SysStat> {
        let get = |name| self.rt_inst.exports.get_typed_function::<(), u32>(&self.store, name);
        let (Ok(ptr), Ok(len)) = (get("rt_sys_stats_ptr"), get("rt_sys_stats_len")) else {
            return Vec::new();
        };
        let (Ok(n), Ok(addr)) = (len.call(&mut self.store), ptr.call(&mut self.store)) else {
            return Vec::new();
        };
        let mut bytes = vec![0u8; n as usize * 8];
        if self.memory.view(&self.store).read(addr as u64, &mut bytes).is_err() {
            return Vec::new();
        }
        let words: Vec<f64> =
            bytes.chunks_exact(8).map(|c| f64::from_le_bytes(c.try_into().unwrap())).collect();
        openmodelica_sim_meta::sysstat::decode(&words)
    }
    fn prof_row(&mut self) -> u32 {
        match self.rt_inst.exports.get_typed_function::<(), u32>(&self.store, "rt_prof_row") {
            Ok(f) => f.call(&mut self.store).unwrap_or(0),
            Err(_) => 0,
        }
    }
    fn prof_dump(&mut self) -> u32 {
        match self.rt_inst.exports.get_typed_function::<(), u32>(&self.store, "rt_prof_dump") {
            Ok(f) => f.call(&mut self.store).unwrap_or(0),
            Err(_) => 0,
        }
    }
    fn prof_clear(&mut self) {
        if let Ok(f) = self.rt_inst.exports.get_typed_function::<u32, ()>(&self.store, "rt_prof_clear") {
            let _ = f.call(&mut self.store, 0);
        }
    }
    fn prof_init(&mut self, n: u32) {
        if let Ok(f) = self.rt_inst.exports.get_typed_function::<u32, ()>(&self.store, "rt_prof_init") {
            let _ = f.call(&mut self.store, n);
        }
    }
    fn context_addr(&mut self) -> u32 {
        match self.rt_inst.exports.get_typed_function::<(), u32>(&self.store, "rt_context_addr") {
            Ok(f) => f.call(&mut self.store).unwrap_or(0),
            Err(_) => 0,
        }
    }
    fn error_stage_addr(&mut self) -> u32 {
        match self.rt_inst.exports.get_typed_function::<(), u32>(&self.store, "rt_error_stage_addr") {
            Ok(f) => f.call(&mut self.store).unwrap_or(0),
            Err(_) => 0,
        }
    }
    fn no_throw_div_zero_addr(&mut self) -> u32 {
        match self.rt_inst.exports.get_typed_function::<(), u32>(&self.store, "rt_no_throw_div_zero_addr") {
            Ok(f) => f.call(&mut self.store).unwrap_or(0),
            Err(_) => 0,
        }
    }
    fn clean_nls_history(&mut self, time: f64) {
        if let Ok(f) = self.rt_inst.exports.get_typed_function::<f64, ()>(&self.store, "rt_nls_clean_history") {
            let _ = f.call(&mut self.store, time);
        }
    }
    fn set_string(&mut self, addr: u32, bytes: &[u8]) -> Result<()> {
        let exports = &self.rt_inst.exports;
        let str_new = wt(exports.get_typed_function::<u32, u32>(&self.store, "rt_str_new"))?;
        let str_data = wt(exports.get_typed_function::<u32, u32>(&self.store, "rt_str_data"))?;
        let release = wt(exports.get_typed_function::<u32, ()>(&self.store, "rt_release"))?;
        let mut old = [0u8; 4];
        self.read_bytes(addr, &mut old)?;
        let obj = wt(str_new.call(&mut self.store, bytes.len() as u32))?;
        let at = wt(str_data.call(&mut self.store, obj))?;
        self.write_bytes(at, bytes)?;
        self.write_bytes(addr, &obj.to_le_bytes())?;
        wt(release.call(&mut self.store, u32::from_le_bytes(old)))
    }
}

// ---------------------------------------------------------------------------
// In-wasm session driver (`rt_sim_*`): the shared driver runs *inside*
// `runtime.wasm`, reaching the model via the shared table (wasm->wasm). The host
// only starts it, pumps budgeted chunks, and reads the result buffers.
// ---------------------------------------------------------------------------

/// A running in-wasm simulation. `Drop` frees the in-wasm session.
pub struct InWasmSession {
    store: Store,
    memory: wasmer::Memory,
    advance: wasmer::TypedFunction<f64, i32>,
    rows_ptr: wasmer::TypedFunction<(), u32>,
    rows_len: wasmer::TypedFunction<(), u32>,
    n_rows_f: wasmer::TypedFunction<(), u32>,
    first_row_ptr: wasmer::TypedFunction<(), u32>,
    first_row_len: wasmer::TypedFunction<(), u32>,
    n_reals_f: wasmer::TypedFunction<(), u32>,
    params_ptr: wasmer::TypedFunction<(), u32>,
    params_len: wasmer::TypedFunction<(), u32>,
    stat_f: wasmer::TypedFunction<u32, u64>,
    lin_ptr: wasmer::TypedFunction<(), u32>,
    lin_len: wasmer::TypedFunction<(), u32>,
    prof_ptr: wasmer::TypedFunction<(), u32>,
    prof_len: wasmer::TypedFunction<(), u32>,
    sys_ptr: wasmer::TypedFunction<(), u32>,
    sys_len: wasmer::TypedFunction<(), u32>,
    free_f: wasmer::TypedFunction<(), ()>,
}

/// Instantiate, populate the shared table with the model's exports, write the
/// metadata blob, and `rt_sim_start` a resumable in-wasm run.
pub fn build_inwasm_session(
    model: &SimModel,
    result: Option<&crate::result_sink::ResultTarget>,
) -> std::result::Result<InWasmSession, String> {
    sim_driver::init_host_hooks(); // cancel poll + assertion routing (idempotent)
    let Instantiated { mut store, rt_inst, instance, memory, rt_alloc } = instantiate_modules(model, &model.meta)?;

    // Append N contiguous table slots and set each to the model's export funcref
    // (null + cleared mask bit if the model doesn't export it).
    let table = wts(rt_inst.exports.get_table("__indirect_function_table"))?.clone();
    let n_slots = crate::model::INWASM_SLOT_NAMES.len() as u32;
    let fn_base = wts(table.grow(&mut store, n_slots, wasmer::Value::FuncRef(None)))?;
    let mut present_mask: u64 = 0;
    for (slot, name) in crate::model::INWASM_SLOT_NAMES.iter().enumerate() {
        if let Ok(f) = instance.exports.get_function(name) {
            let f = f.clone();
            wts(table.set(&mut store, fn_base + slot as u32, wasmer::Value::FuncRef(Some(f))))?;
            present_mask |= 1u64 << slot;
        }
    }

    // Write the metadata blob into linear memory for the runtime to decode.
    let blob = openmodelica_sim_meta::encode(&model.meta);
    let meta_ptr = wts(rt_alloc.call(&mut store, blob.len() as u32))?;
    wts(memory.view(&store).write(meta_ptr as u64, &blob))?;

    // The runtime has its own override store; hand the host's across.
    let ov = crate::model::encode_overrides();
    let ov_ptr = wts(rt_alloc.call(&mut store, ov.len() as u32))?;
    wts(memory.view(&store).write(ov_ptr as u64, &ov))?;
    let set_ov: wasmer::TypedFunction<(u32, u32), i32> =
        wts(rt_inst.exports.get_typed_function(&store, "rt_sim_set_overrides"))?;
    if wts(set_ov.call(&mut store, ov_ptr, ov.len() as u32))? < 0 {
        return Err("CodegenWasmJit: rt_sim_set_overrides failed".to_string());
    }

    // Same for the runtime flags, as the argv bytes a WASI command would receive.
    let args = openmodelica_sim_meta::simflags::flags().to_wasi_args();
    let args_ptr = wts(rt_alloc.call(&mut store, args.len().max(1) as u32))?;
    wts(memory.view(&store).write(args_ptr as u64, &args))?;
    let set_args: wasmer::TypedFunction<(u32, u32), i32> =
        wts(rt_inst.exports.get_typed_function(&store, "rt_sim_set_args"))?;
    if wts(set_args.call(&mut store, args_ptr, args.len() as u32))? < 0 {
        return Err("CodegenWasmJit: the runtime rejected the simulation flags".to_string());
    }
    if let Some(t) = result {
        let keep: Vec<u8> = t.keep.iter().map(|&k| k as u8).collect();
        let path_ptr = wts(rt_alloc.call(&mut store, t.path.len().max(1) as u32))?;
        wts(memory.view(&store).write(path_ptr as u64, t.path.as_bytes()))?;
        let keep_ptr = wts(rt_alloc.call(&mut store, keep.len().max(1) as u32))?;
        wts(memory.view(&store).write(keep_ptr as u64, &keep))?;
        let set_result: wasmer::TypedFunction<(u32, u32, u32, u32, i32), i32> =
            wts(rt_inst.exports.get_typed_function(&store, "rt_sim_set_result"))?;
        if wts(set_result.call(&mut store, path_ptr, t.path.len() as u32, keep_ptr, keep.len() as u32, t.single as i32))? < 0 {
            return Err("CodegenWasmJit: rt_sim_set_result failed".to_string());
        }
    }

    let start: wasmer::TypedFunction<(u32, u32, u32, u64), i32> =
        wts(rt_inst.exports.get_typed_function(&store, "rt_sim_start"))?;
    let gf = |store: &Store, name: &'static str| -> std::result::Result<wasmer::TypedFunction<(), u32>, String> {
        wts(rt_inst.exports.get_typed_function(store, name))
    };
    // Assembled before the run starts so that an initialization `assert()`, which
    // traps out of `rt_sim_start`, is decoded through the same `SimEngine` as one
    // that trips later instead of surfacing as a bare wasm trap.
    let mut sess = InWasmSession {
        advance: wts(rt_inst.exports.get_typed_function(&store, "rt_sim_advance"))?,
        rows_ptr: gf(&store, "rt_sim_rows_ptr")?,
        rows_len: gf(&store, "rt_sim_rows_len")?,
        n_rows_f: gf(&store, "rt_sim_n_rows")?,
        first_row_ptr: gf(&store, "rt_sim_first_row_ptr")?,
        first_row_len: gf(&store, "rt_sim_first_row_len")?,
        n_reals_f: gf(&store, "rt_sim_n_reals")?,
        params_ptr: gf(&store, "rt_sim_params_ptr")?,
        params_len: gf(&store, "rt_sim_params_len")?,
        stat_f: wts(rt_inst.exports.get_typed_function(&store, "rt_sim_stat"))?,
        lin_ptr: gf(&store, "rt_sim_lin_ptr")?,
        lin_len: gf(&store, "rt_sim_lin_len")?,
        prof_ptr: gf(&store, "rt_sim_prof_ptr")?,
        prof_len: gf(&store, "rt_sim_prof_len")?,
        sys_ptr: gf(&store, "rt_sys_stats_ptr")?,
        sys_len: gf(&store, "rt_sys_stats_len")?,
        free_f: wts(rt_inst.exports.get_typed_function(&store, "rt_sim_free"))?,
        store,
        memory,
    };
    let started = start.call(&mut sess.store, meta_ptr, blob.len() as u32, fn_base, present_mask);
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
        self.memory.view(&self.store).read(addr as u64, buf).map_err(|_| "CodegenWasmJit: mem read")
    }
    fn write_bytes(&mut self, addr: u32, buf: &[u8]) -> Result<()> {
        self.memory.view(&self.store).write(addr as u64, buf).map_err(|_| "CodegenWasmJit: mem write")
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
        let n_reals = wt(self.n_reals_f.call(&mut self.store))?;
        let rp = wt(self.rows_ptr.call(&mut self.store))?;
        let rn = wt(self.rows_len.call(&mut self.store))? as usize;
        let pp = wt(self.params_ptr.call(&mut self.store))?;
        let pn = wt(self.params_len.call(&mut self.store))? as usize;
        let read_vec = |mem: &wasmer::Memory, store: &Store, ptr: u32, n: usize| -> Result<Vec<f64>> {
            let bytes = mem
                .view(store)
                .copy_range_to_vec(ptr as u64..ptr as u64 + n as u64 * 8)
                .map_err(|_| "CodegenWasmJit: result read")?;
            let mut out = Vec::with_capacity(n);
            out.extend(bytes.chunks_exact(8).map(|c| f64::from_le_bytes(c.try_into().unwrap())));
            Ok(out)
        };
        let rows = read_vec(&self.memory, &self.store, rp, rn)?;
        let params = read_vec(&self.memory, &self.store, pp, pn)?;
        let mut stats = openmodelica_sim_meta::SolveStats::default();
        let sp = wt(self.sys_ptr.call(&mut self.store))?;
        let sn = wt(self.sys_len.call(&mut self.store))? as usize;
        stats.systems =
            openmodelica_sim_meta::sysstat::decode(&read_vec(&self.memory, &self.store, sp, sn)?);
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

    /// What the runtime wrote to the result file it was given.
    pub fn take_written(&mut self) -> Result<crate::result_sink::Written> {
        let n_rows = wt(self.n_rows_f.call(&mut self.store))? as usize;
        let p = wt(self.first_row_ptr.call(&mut self.store))?;
        let n = wt(self.first_row_len.call(&mut self.store))? as usize;
        let mut bytes = vec![0u8; n];
        if n > 0 {
            self.memory.view(&self.store).read(p as u64, &mut bytes).map_err(|_| "CodegenWasmJit: first-row read")?;
        }
        Ok(crate::result_sink::Written {
            n_rows,
            first_row: openmodelica_sim_meta::result::decode_first_row(&bytes),
        })
    }

    /// `+profiling`'s collected state, for the host's `profiling::adopt`: the
    /// driver ran in-wasm, but the report is the host's to write.
    pub fn take_prof(&mut self) -> Result<Vec<u8>> {
        let p = wt(self.prof_ptr.call(&mut self.store))?;
        let n = wt(self.prof_len.call(&mut self.store))? as usize;
        let mut bytes = vec![0u8; n];
        if n > 0 {
            self.memory
                .view(&self.store)
                .read(p as u64, &mut bytes)
                .map_err(|_| "CodegenWasmJit: profiling read")?;
        }
        Ok(bytes)
    }

    /// The runtime's `-l` blob (`<file name>\0<content>`), empty when unasked.
    fn take_lin(&mut self) -> Result<Option<openmodelica_sim_meta::linearize::LinFile>> {
        let p = wt(self.lin_ptr.call(&mut self.store))?;
        let n = wt(self.lin_len.call(&mut self.store))? as usize;
        let mut bytes = vec![0u8; n];
        if n > 0 {
            self.memory
                .view(&self.store)
                .read(p as u64, &mut bytes)
                .map_err(|_| "CodegenWasmJit: linearization read")?;
        }
        Ok(crate::split_lin_blob(&bytes))
    }
}

impl Drop for InWasmSession {
    fn drop(&mut self) {
        let _ = self.free_f.call(&mut self.store);
    }
}

/// Only the wasmtime backend keeps an on-disk artifact cache.
pub fn precompile_fixed_blobs(_dir: &std::path::Path) -> std::result::Result<Vec<String>, String> {
    Ok(Vec::new())
}

/// No artifacts to keep, so nowhere to keep them.
pub fn aot_cache_dir() -> std::path::PathBuf {
    std::env::temp_dir()
}
