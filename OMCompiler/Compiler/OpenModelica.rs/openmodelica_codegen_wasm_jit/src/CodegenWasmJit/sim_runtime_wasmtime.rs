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

use super::sim_driver;
use super::SimModel;
use crate::CodegenWasmJitFunctions::runtime::add_host_builtins;

/// The runtime module, embedded the same way the function half embeds it.
static RUNTIME_WASM: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/runtime.wasm"));

/// The compiled-module type for this backend; `CodegenWasmJit::SimModel` stores
/// it backend-agnostically as `sim_runtime::Module`.
pub(crate) type Module = wasmtime::Module;

/// One process-wide wasmtime `Engine`, so the (model-independent) runtime module
/// can be JIT-compiled once and reused, and so model modules built on background
/// threads share the same engine the run instantiates them on.
pub(super) fn sim_engine() -> &'static wasmtime::Engine {
    static ENGINE: OnceLock<wasmtime::Engine> = OnceLock::new();
    ENGINE.get_or_init(|| {
        let mut cfg = wasmtime::Config::new();
        // Compile module functions across threads (off by default with
        // default-features=false) — ~4x faster module compilation here.
        cfg.parallel_compilation(true);
        // Experimental opt-level override; default is wasmtime's `Speed`.
        match std::env::var("OMC_WASM_OPT_LEVEL").as_deref() {
            Ok("none") => { cfg.cranelift_opt_level(wasmtime::OptLevel::None); }
            Ok("speed_and_size") => { cfg.cranelift_opt_level(wasmtime::OptLevel::SpeedAndSize); }
            _ => {}
        }
        wasmtime::Engine::new(&cfg).expect("wasm-jit: failed to build wasmtime engine")
    })
}

/// The compiled runtime module, obtained once per process and shared across all
/// simulations. The runtime module is fixed, so its compiled form is cached
/// **on disk** (AOT): the first process to need it JIT-compiles and
/// `serialize`s it; every later process `deserialize`s the artifact in
/// microseconds. `deserialize` validates the artifact against the current
/// wasmtime version / engine config / target, so a stale or incompatible cache
/// is rejected and we transparently fall back to JIT (then refresh the cache).
pub(super) fn runtime_module() -> Result<&'static wasmtime::Module> {
    static MODULE: OnceLock<std::result::Result<wasmtime::Module, String>> = OnceLock::new();
    MODULE
        .get_or_init(|| load_or_compile_runtime().map_err(|e| format!("{e:?}")))
        .as_ref()
        .map_err(|e| "CodegenWasmJit: obtaining runtime module: {e}")
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

fn load_or_compile_runtime() -> Result<wasmtime::Module> {
    let engine = sim_engine();
    let path = runtime_cache_path();
    // Try the AOT artifact first (microseconds). `deserialize_file` is unsafe
    // because it trusts the artifact; it is one we produced under temp_dir, and
    // wasmtime validates version/config compatibility (erroring otherwise).
    if path.exists() {
        if let Ok(m) = unsafe { wasmtime::Module::deserialize_file(engine, &path) } {
            return Ok(m);
        }
        // Incompatible/corrupt cache (e.g. wasmtime upgrade): fall through to
        // recompile and overwrite it below.
    }
    let module = wasmtime::Module::new(engine, RUNTIME_WASM).map_err(|e| "{e:?}")?;
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

/// JIT-compile a generated model module on the shared engine. Called either on a
/// background thread from `translateModel` (overlapping the rest of the OMC
/// pipeline) or inline from `run` as a fallback.
pub(super) fn compile_model_module(wasm: &[u8]) -> Result<wasmtime::Module> {
    wasmtime::Module::new(sim_engine(), wasm).map_err(|e| "{e:?}")
}

/// Begin compiling the fixed runtime module on a background thread, once per
/// process. The runtime module does not depend on the model, so this can be
/// started as soon as we know a wasm-jit simulation is coming (`translateModel`
/// entry) — it then compiles while `build_sim_model` generates the model bytes,
/// and `run` only waits for whatever did not overlap. Idempotent.
pub(super) fn start_runtime_compile() {
    static STARTED: std::sync::Once = std::sync::Once::new();
    STARTED.call_once(|| {
        std::thread::spawn(|| {
            let _ = runtime_module(); // populates the OnceLock cache
        });
    });
}

/// Take the model module compiled on the background thread `translateModel`
/// spawned (joining it), or compile inline if there is no pending job.
pub(super) fn take_compiled_model(model: &SimModel) -> Result<wasmtime::Module> {
    let job = model.compiled.lock().unwrap().take();
    match job {
        Some(handle) => match handle.join() {
            Ok(Ok(m)) => Ok(m),
            Ok(Err(e)) => return Err("CodegenWasmJit: background model-module compile failed: {e}"),
            Err(_) => return Err("CodegenWasmJit: background model-module compile thread panicked"),
        },
        None => compile_model_module(&model.wasm),
    }
}

type Store = wasmtime::Store<()>;

fn wt<T>(r: std::result::Result<T, wasmtime::Error>) -> Result<T> {
    r.map_err(|e| "{e:?}")
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

fn wty_valtype(w: crate::CodegenWasmJitFunctions::WTy) -> wasmtime::ValType {
    match w {
        crate::CodegenWasmJitFunctions::WTy::I32 => wasmtime::ValType::I32,
        crate::CodegenWasmJitFunctions::WTy::F64 => wasmtime::ValType::F64,
    }
}

/// Define the model's external "C" function imports (wasm module `ext`) from the
/// host. Uses the model's `ext_imports` (the C-call `SigTy` signature) rather than
/// the wasm `FuncType`, because the latter can't distinguish an `i32` that is a
/// String/array/pointer handle from a plain Integer. Resolves each `extName`
/// natively and binds a marshalling trampoline sharing the runtime's linear
/// memory (`memory`).
fn define_external_imports(
    linker: &mut wasmtime::Linker<()>,
    model: &SimModel,
    memory: wasmtime::Memory,
    rt_str_new: wasmtime::TypedFunc<u32, u32>,
    rt_str_data: wasmtime::TypedFunc<u32, u32>,
) -> Result<()> {
    registry_reset();
    let engine = linker.engine().clone();
    for sig in &model.ext_imports {
        let functype = wasmtime::FuncType::new(
            &engine,
            sig.wasm_params().iter().map(|s| wty_valtype(s.wty())),
            sig.wasm_results().iter().map(|s| wty_valtype(s.wty())),
        );
        let addr = openmodelica_util::dynload::external_symbol(&sig.name)
            .ok_or_else(|| "external \"C\" function `{}` not found in any loaded library")?;
        let name = sig.name.clone();
        let sig = sig.clone();
        let rt_str_new = rt_str_new.clone();
        let rt_str_data = rt_str_data.clone();
        wt(linker.func_new("ext", &name, functype, move |mut caller, args, rets| {
            // Safety: `addr` resolves `sig.name`; the `Cif` matches the validated sig.
            unsafe { call_external(addr, &sig, &mut caller, memory, &rt_str_new, &rt_str_data, args, rets) }
                .map_err(|e| wasmtime::Error::msg(format!("{e}")))
        }))?;
    }
    Ok(())
}

/// Call native external `addr` through libffi, marshalling by the C-call
/// [`ExtCallSig`]. Input args (in `extArgs` order) come from the wasm parameters:
/// scalars (Real→f64, Integer/Boolean→i64) by value; `Str` as a NUL-terminated
/// `char*` copied from the wasm String; `Ptr` (external object) via the handle
/// registry; `Array` as a native pointer into the runtime array's row-major data.
/// Each `_Out_` pointer arg gets an 8-byte native scratch cell whose address is
/// passed to C. The wasm results are the C return value (if any) then each output
/// cell's written value, in order — scalars directly, external-object pointers via
/// the registry, and `char*` outputs copied into a fresh in-wasm String
/// (`rt_str_new`+`rt_str_data`). The whole call is bracketed by
/// `sim_external_begin/end` so any `ModelicaAllocateString` uses our arena.
unsafe fn call_external(
    addr: usize,
    sig: &crate::CodegenWasmJitFunctions::ExtCallSig,
    caller: &mut wasmtime::Caller<'_, ()>,
    memory: wasmtime::Memory,
    rt_str_new: &wasmtime::TypedFunc<u32, u32>,
    rt_str_data: &wasmtime::TypedFunc<u32, u32>,
    args: &[wasmtime::Val],
    rets: &mut [wasmtime::Val],
) -> Result<()> {
    use crate::CodegenWasmJitFunctions::SigTy;
    use core::ffi::c_void;
    use libffi::middle::{Cif, Type};
    use wasmtime::Val;

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

    enum Slot {
        I(i64),
        F(f64),
        P(*mut c_void),
    }
    let mut slots: Vec<Slot> = Vec::with_capacity(sig.args.len());
    let mut cstrings: Vec<std::ffi::CString> = Vec::new();
    let mut types: Vec<Type> = Vec::with_capacity(sig.args.len());
    // One 8-byte native cell per `_Out_` pointer arg (fits int/double/pointer),
    // in output order; the C call writes through the pointer we pass.
    let mut out_cells: Vec<(SigTy, Box<[u8; 8]>)> = Vec::new();
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
                let mut cell: Box<[u8; 8]> = Box::new([0u8; 8]);
                slots.push(Slot::P(cell.as_mut_ptr() as *mut c_void));
                types.push(Type::pointer());
                out_cells.push((ty.clone(), cell));
                continue;
            }
            let v = &args[in_i];
            in_i += 1;
            match ty {
                SigTy::Real => {
                    slots.push(Slot::F(v.unwrap_f64()));
                    types.push(Type::f64());
                }
                // Marshalled 64-bit: on SysV x86-64 every integer/pointer arg fills
                // a full 64-bit slot, correct for `int`/`long`/`size_t` alike.
                SigTy::Int | SigTy::Bool => {
                    slots.push(Slot::I(v.unwrap_i32() as i64));
                    types.push(Type::i64());
                }
                SigTy::Str => {
                    let off = v.unwrap_i32() as usize;
                    let len = u32::from_le_bytes(mem[off + 4..off + 8].try_into().unwrap()) as usize;
                    let cs = std::ffi::CString::new(&mem[off + 8..off + 8 + len])
                        .map_err(|_| "external \"C\" `{}`: string argument has an interior NUL")?;
                    slots.push(Slot::P(cs.as_ptr() as *mut c_void));
                    cstrings.push(cs);
                    types.push(Type::pointer());
                }
                SigTy::Ptr => {
                    slots.push(Slot::P(registry_get(v.unwrap_i32()) as *mut c_void));
                    types.push(Type::pointer());
                }
                // Array: a native pointer to the runtime array's contiguous
                // row-major data (`align8(16 + ndims*4)` past the header). The C
                // callee reads it in place; the memory can't grow during the call.
                SigTy::Array { .. } => {
                    let off = v.unwrap_i32() as usize;
                    let ndims = u32::from_le_bytes(mem[off + 8..off + 12].try_into().unwrap()) as usize;
                    let data_off = (16 + ndims * 4 + 7) & !7;
                    let native = mem.as_ptr() as usize + off + data_off;
                    slots.push(Slot::P(native as *mut c_void));
                    types.push(Type::pointer());
                }
                other => return Err("CodegenWasmJit: external \"C\" `{}`: input argument type {other:?} not yet marshalled"),
            }
        }
    }
    // libffi `avalue`: a pointer to each slot's stored value.
    let mut avalue: Vec<*mut c_void> = slots
        .iter_mut()
        .map(|s| match s {
            Slot::I(x) => x as *mut i64 as *mut c_void,
            Slot::F(x) => x as *mut f64 as *mut c_void,
            Slot::P(x) => x as *mut *mut c_void as *mut c_void,
        })
        .collect();
    let ret_type = match &sig.ret {
        None => Type::void(),
        Some(SigTy::Real) => Type::f64(),
        Some(SigTy::Int) | Some(SigTy::Bool) => Type::i32(),
        Some(SigTy::Str) | Some(SigTy::Ptr) => Type::pointer(),
        Some(other) => return Err("CodegenWasmJit: external \"C\" `{}`: return type {other:?} not yet marshalled"),
    };
    let cif = Cif::new(types, ret_type);
    let mut rvalue = [0u8; 8];
    let cif_ptr = cif.as_raw_ptr() as *mut c_void;
    let target = unsafe { std::mem::transmute::<usize, unsafe extern "C-unwind" fn()>(addr) };
    let rvalue_ptr = rvalue.as_mut_ptr() as *mut c_void;
    let avalue_ptr = avalue.as_mut_ptr();
    // Any `ModelicaAllocateString` the callee makes for a string result must come
    // from our arena (never the C runtime); freed by `sim_external_end` once the
    // results below are copied into in-wasm strings.
    openmodelica_modelica_utilities::sim_external_begin();
    let ok = openmodelica_error::ErrorExt::catch_runtime_error(|| unsafe {
        ffi_call(cif_ptr, Some(target), rvalue_ptr, avalue_ptr);
    });
    drop(cstrings); // char* input copies stay alive across the call
    if ok.is_err() {
        openmodelica_modelica_utilities::sim_external_end();
        // A `ModelicaError` recorded its message in the Error buffer and unwound
        // here as a panic; surface a failure to the host.
        return Err("CodegenWasmJit: external \"C\" `{}` raised a runtime error");
    }

    // Build an in-wasm String from a native `char*` (NUL-terminated), returning its
    // offset. Re-enters the runtime (`rt_str_new` may grow memory, so `data_mut` is
    // re-fetched after).
    let mut make_string = |cptr: *const std::os::raw::c_char| -> Result<u32> {
        let bytes: &[u8] = if cptr.is_null() { &[] } else { unsafe { std::ffi::CStr::from_ptr(cptr) }.to_bytes() };
        let soff = wt(rt_str_new.call(&mut *caller, bytes.len() as u32))?;
        let doff = wt(rt_str_data.call(&mut *caller, soff))? as usize;
        memory.data_mut(&mut *caller)[doff..doff + bytes.len()].copy_from_slice(bytes);
        Ok(soff)
    };
    let result_val = |ty: &SigTy, raw: [u8; 8], make: &mut dyn FnMut(*const std::os::raw::c_char) -> Result<u32>| -> Result<Val> {
        Ok(match ty {
            SigTy::Real => Val::F64(f64::from_le_bytes(raw).to_bits()),
            SigTy::Int | SigTy::Bool => Val::I32(i32::from_le_bytes(raw[..4].try_into().unwrap())),
            SigTy::Ptr => Val::I32(registry_put(usize::from_le_bytes(raw))),
            SigTy::Str => Val::I32(make(usize::from_le_bytes(raw) as *const std::os::raw::c_char)? as i32),
            other => return Err("external \"C\": result type {other:?} not marshalled"),
        })
    };

    let mut ri = 0usize;
    if let Some(ret_ty) = &sig.ret {
        rets[ri] = result_val(ret_ty, rvalue, &mut make_string)?;
        ri += 1;
    }
    for (ty, cell) in &out_cells {
        rets[ri] = result_val(ty, **cell, &mut make_string)?;
        ri += 1;
    }
    openmodelica_modelica_utilities::sim_external_end();
    Ok(())
}


pub(super) fn run(model: &SimModel) -> Result<sim_driver::RunResult> {
    let bench = super::sim_bench_enabled();
    // The in-wasm session driver (`rt_sim_*`) reaches the model wasm->wasm; see
    // `super::inwasm_driver_enabled` for when it is used.
    if super::inwasm_driver_enabled() {
        return run_inwasm(model, bench);
    }
    let (mut engine, sim_data) = build_engine(model)?;
    // `OMC_WASM_SIM_DRIVER=host` forces the native Euler loop over the in-wasm one.
    let host_driven = std::env::var("OMC_WASM_SIM_DRIVER").map(|v| v == "host").unwrap_or(false);
    let n_steps = model.n_intervals;
    let n_rows = n_steps + 1;
    let t0 = Instant::now();
    let (result, driver_label) =
        sim_driver::drive(&mut *engine, &model.meta, sim_data, model.method.as_str(), host_driven, bench)?;
    if bench {
        let elapsed = t0.elapsed();
        eprintln!(
            "wasm-jit sim [{}]: integrate {:?} ({} intervals, {:.2} us/interval)",
            driver_label, elapsed, n_steps, elapsed.as_secs_f64() * 1e6 / (n_rows.max(1) as f64),
        );
    }
    Ok(result)
}

/// One-shot in-wasm run (used by [`run`] under `OMC_WASM_INWASM_DRIVER`): start,
/// pump to completion with an unbounded budget, read the result.
fn run_inwasm(model: &SimModel, bench: bool) -> Result<sim_driver::RunResult> {
    let t0 = Instant::now();
    let mut sess = build_inwasm_session(model)?;
    loop {
        match sess.advance(f64::INFINITY)? {
            0 => continue,
            3 => return Err("CodegenWasmJit: in-wasm simulation cancelled"),
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
fn instantiate_modules(model: &SimModel) -> Result<Instantiated> {
    let bench = super::sim_bench_enabled();
    let engine = sim_engine();
    let mut linker = wasmtime::Linker::new(engine);
    add_host_builtins(&mut linker)?;

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
    let model_compile = t_model.elapsed();
    let compile_time = t_compile.elapsed();
    if bench {
        eprintln!(
            "wasm-jit sim: module fetch — runtime.wasm ({} KB) {:?} (cached/compiled), model.wasm ({} KB) {:?} (join/compile)",
            RUNTIME_WASM.len() / 1024, rt_compile, model.wasm.len() / 1024, model_compile,
        );
    }

    // Phase 2: instantiate (sharing the runtime's linear memory).
    let t_inst = Instant::now();
    let mut store = wasmtime::Store::new(engine, ());
    let rt_inst = wt(linker.instantiate(&mut store, runtime_module))?;
    // The generated module imports the runtime's exports under module name "rt".
    wt(linker.instance(&mut store, "rt", rt_inst))?;
    let memory = rt_inst
        .get_memory(&mut store, "memory")
        .ok_or_else(|| "CodegenWasmJit: runtime has no `memory` export")?;
    // External "C" functions (module `ext`) resolved from the host; they share the
    // runtime's linear memory for string/array/pointer marshalling, and re-enter
    // the runtime's `rt_str_new`/`rt_str_data` to build in-wasm strings for `char*`
    // outputs.
    let rt_str_new = wt(rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_str_new"))?;
    let rt_str_data = wt(rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_str_data"))?;
    define_external_imports(&mut linker, model, memory, rt_str_new, rt_str_data)?;
    let instance = wt(linker.instantiate(&mut store, &model_module))?;
    let inst_time = t_inst.elapsed();
    let rt_alloc = wt(rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_alloc"))?;
    if bench {
        eprintln!("wasm-jit sim: compile {compile_time:?} | instantiate {inst_time:?}");
    }

    Ok(Instantiated { store, rt_inst, instance, memory, rt_alloc })
}

/// Build the engine (compile/join modules, instantiate, allocate `SimData`), boxed
/// with the `SimData` pointer; owned by the session across `advance` calls, reused
/// by [`run`] one-shot.
pub(super) fn build_engine(model: &SimModel) -> Result<(Box<dyn sim_driver::SimEngine + 'static>, u32)> {
    sim_driver::init_host_hooks(); // cancel poll + model-assertion routing (idempotent)
    let Instantiated { mut store, rt_inst, instance, memory, rt_alloc } = instantiate_modules(model)?;

    let layout = &model.layout;
    // Allocate the shared SimData block.
    let sim_data = wt(rt_alloc.call(&mut store, layout.total))?;

    // M0 proof: the driver reaches the model wasm→wasm by appending a model
    // export to the shared table and `call_indirect`ing it from the runtime
    // (same path `rt_solve_nls` already uses). Verify host-side population works
    // before building the in-wasm driver on it.
    if std::env::var("OMC_WASM_SIM_PROBE").is_ok() {
        run_table_probe(&mut store, rt_inst, instance, memory, sim_data, layout.total)?;
    }

    let engine = WasmtimeEngine { store, memory, instance, funcs: HashMap::new() };
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
    funcs: HashMap<String, wasmtime::TypedFunc<u32, ()>>,
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
        self.memory.read(&self.store, addr as usize, buf).map_err(|e| "CodegenWasmJit: mem read: {e}")
    }
    fn write_bytes(&mut self, addr: u32, buf: &[u8]) -> Result<()> {
        self.memory.write(&mut self.store, addr as usize, buf).map_err(|e| "CodegenWasmJit: mem write: {e}")
    }
    fn call1(&mut self, name: &str, arg: u32) -> Result<()> {
        let f = self.func(name)?;
        wt(f.call(&mut self.store, arg))
    }
    fn call1_if_present(&mut self, name: &str, arg: u32) -> Result<()> {
        if self.instance.get_func(&mut self.store, name).is_none() {
            return Ok(());
        }
        self.call1(name, arg)
    }
    fn call_simulate(&mut self, sim_data: u32, start: f64, stop: f64, n_steps: u32) -> Result<u32> {
        let f = wt(self.instance.get_typed_func::<(u32, f64, f64, u32), u32>(&mut self.store, "simulate"))?;
        wt(f.call(&mut self.store, (sim_data, start, stop, n_steps)))
    }
    fn take_pending_assert(&mut self) -> Option<[i32; 7]> {
        crate::CodegenWasmJitFunctions::runtime::take_pending_assert()
    }
}

// ---------------------------------------------------------------------------
// In-wasm session driver (`rt_sim_*`): the shared driver runs *inside*
// `runtime.wasm`, reaching the model via the shared table (wasm->wasm), so the
// host only starts it, pumps budgeted chunks, and reads the result buffers —
// O(chunks) host<->wasm crossings instead of one per residual.
// ---------------------------------------------------------------------------

/// A running in-wasm simulation. `Drop` frees the in-wasm session.
pub(super) struct InWasmSession {
    store: Store,
    memory: wasmtime::Memory,
    advance: wasmtime::TypedFunc<f64, i32>,
    rows_ptr: wasmtime::TypedFunc<(), u32>,
    rows_len: wasmtime::TypedFunc<(), u32>,
    n_reals_f: wasmtime::TypedFunc<(), u32>,
    params_ptr: wasmtime::TypedFunc<(), u32>,
    params_len: wasmtime::TypedFunc<(), u32>,
    stat_f: wasmtime::TypedFunc<u32, u64>,
    free_f: wasmtime::TypedFunc<(), ()>,
}

/// Instantiate, populate the shared table with the model's exports, write the
/// metadata blob, and `rt_sim_start` a resumable in-wasm run.
pub(super) fn build_inwasm_session(model: &SimModel) -> Result<InWasmSession> {
    sim_driver::init_host_hooks(); // cancel poll + assertion routing (idempotent)
    let Instantiated { mut store, rt_inst, instance, memory, rt_alloc } = instantiate_modules(model)?;

    // Append N contiguous table slots and set each to the model's export funcref
    // (null + cleared mask bit if the model doesn't export it).
    let table = rt_inst
        .get_table(&mut store, "__indirect_function_table")
        .ok_or_else(|| "CodegenWasmJit: runtime has no __indirect_function_table export")?;
    let n_slots = super::INWASM_SLOT_NAMES.len() as u64;
    let fn_base = wt(table.grow(&mut store, n_slots, wasmtime::Ref::Func(None)))?;
    let mut present_mask: u32 = 0;
    for (slot, name) in super::INWASM_SLOT_NAMES.iter().enumerate() {
        if let Some(f) = instance.get_func(&mut store, name) {
            wt(table.set(&mut store, fn_base + slot as u64, wasmtime::Ref::Func(Some(f))))?;
            present_mask |= 1 << slot;
        }
    }

    // Write the metadata blob into linear memory for the runtime to decode.
    let blob = openmodelica_sim_meta::encode(&model.meta);
    let meta_ptr = wt(rt_alloc.call(&mut store, blob.len() as u32))?;
    memory.write(&mut store, meta_ptr as usize, &blob).map_err(|_| "CodegenWasmJit: meta blob write")?;

    // The runtime has its own override store; hand the host's across.
    let ov = super::encode_overrides();
    let ov_ptr = wt(rt_alloc.call(&mut store, ov.len() as u32))?;
    memory.write(&mut store, ov_ptr as usize, &ov).map_err(|_| "CodegenWasmJit: overrides write")?;
    let set_ov = wt(rt_inst.get_typed_func::<(u32, u32), i32>(&mut store, "rt_sim_set_overrides"))?;
    if wt(set_ov.call(&mut store, (ov_ptr, ov.len() as u32)))? < 0 {
        return Err("CodegenWasmJit: rt_sim_set_overrides failed");
    }

    let start = wt(rt_inst.get_typed_func::<(u32, u32, u32, u32), i32>(&mut store, "rt_sim_start"))?;
    let rc = wt(start.call(&mut store, (meta_ptr, blob.len() as u32, fn_base as u32, present_mask)))?;
    if rc < 0 {
        return Err("CodegenWasmJit: rt_sim_start failed");
    }

    let gf = |store: &mut Store, name: &'static str| wt(rt_inst.get_typed_func::<(), u32>(store, name));
    Ok(InWasmSession {
        advance: wt(rt_inst.get_typed_func::<f64, i32>(&mut store, "rt_sim_advance"))?,
        rows_ptr: gf(&mut store, "rt_sim_rows_ptr")?,
        rows_len: gf(&mut store, "rt_sim_rows_len")?,
        n_reals_f: gf(&mut store, "rt_sim_n_reals")?,
        params_ptr: gf(&mut store, "rt_sim_params_ptr")?,
        params_len: gf(&mut store, "rt_sim_params_len")?,
        stat_f: wt(rt_inst.get_typed_func::<u32, u64>(&mut store, "rt_sim_stat"))?,
        free_f: wt(rt_inst.get_typed_func::<(), ()>(&mut store, "rt_sim_free"))?,
        store,
        memory,
    })
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
    fn call1(&mut self, _name: &str, _arg: u32) -> Result<()> {
        Err("CodegenWasmJit: call1 on in-wasm session (unreachable)")
    }
    fn call1_if_present(&mut self, _name: &str, _arg: u32) -> Result<()> {
        Ok(())
    }
    fn call_simulate(&mut self, _s: u32, _a: f64, _b: f64, _n: u32) -> Result<u32> {
        Err("CodegenWasmJit: call_simulate on in-wasm session (unreachable)")
    }
    fn take_pending_assert(&mut self) -> Option<[i32; 7]> {
        crate::CodegenWasmJitFunctions::runtime::take_pending_assert()
    }
}

impl InWasmSession {
    /// One budgeted chunk. Returns the raw `rt_sim_advance` status (0 running,
    /// 1 done, 2 terminated, 3 cancelled). A model `assert()` traps out of
    /// `rt_sim_advance` (or the driver returns <0); either way decode the pending
    /// assertion and surface it like the host driver.
    pub(super) fn advance(&mut self, budget_ms: f64) -> Result<i32> {
        match self.advance.call(&mut self.store, budget_ms) {
            Ok(rc) if rc >= 0 => Ok(rc),
            _ => Err(sim_driver::enrich_trap(self, "CodegenWasmJit: in-wasm simulation failed")),
        }
    }

    /// Read the captured rows/params/stats after the run completed.
    pub(super) fn take_result(&mut self) -> Result<sim_driver::RunResult> {
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
        let mut stats = super::SolveStats::default();
        let mut stat = |i: u32| wt(self.stat_f.call(&mut self.store, i));
        stats.steps = stat(0)?;
        stats.res_evals = stat(1)?;
        stats.jac_evals = stat(2)?;
        stats.err_test_fails = stat(3)?;
        stats.conv_test_fails = stat(4)?;
        stats.state_events = stat(5)?;
        stats.time_events = stat(6)?;
        Ok(sim_driver::RunResult { rows, n_reals, params, stats })
    }
}

impl Drop for InWasmSession {
    fn drop(&mut self) {
        let _ = self.free_f.call(&mut self.store, ());
    }
}

