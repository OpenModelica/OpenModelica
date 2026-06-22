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
use std::cell::Cell;
use std::sync::OnceLock;
// `web-time` re-exports `std::time` on native (zero cost) and backs `Instant`
// with the JS monotonic clock on wasm, where `Instant::now()` panics.
use web_time::Instant;

use super::{REAL_OFF, ResultKind, SimModel, TIME_OFF};
use crate::CodegenWasmJitFunctions::WTy;
use crate::CodegenWasmJitFunctions::runtime::add_host_builtins;

/// The runtime module, embedded the same way the function half embeds it.
static RUNTIME_WASM: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/runtime.wasm"));

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

/// Result of a simulation run.
pub(super) struct RunResult {
    /// Row-major trajectory: `n_rows * n_reals` f64, each row
    /// `[time, realVars…, intAlg…, boolAlg…]` (integer/boolean algebraics
    /// captured per row, as f64).
    pub(super) rows: Vec<f64>,
    /// Columns per row = `SimLayout::n_row_total()`.
    pub(super) n_reals: u32,
    /// Parameter values (in result `Param` order), read from `SimData` after the run.
    pub(super) params: Vec<f64>,
}

/// Read one little-endian i32 from wasm linear memory at byte address `addr`.
fn read_i32(mem: &wasmer::Memory, store: &Store, addr: u32) -> Result<i32> {
    let mut b = [0u8; 4];
    mem.view(store).read(addr as u64, &mut b).map_err(|e| anyhow!("CodegenWasmJit: mem read: {e}"))?;
    Ok(i32::from_le_bytes(b))
}

/// Append one trajectory row to `rows`: the real part `[time | realVars]`
/// followed by the integer and boolean algebraic slots (converted to f64),
/// matching `SimLayout::n_row_total()` and the column layout `kind_from_slot`
/// assigns. Used by the host-driven drivers; the in-wasm `simulate` emits the
/// same layout.
fn capture_row(mem: &wasmer::Memory, store: &Store, rows: &mut Vec<f64>, sim_data: u32, layout: &super::SimLayout) -> Result<()> {
    for i in 0..layout.n_reals_row() {
        rows.push(read_f64(mem, store, sim_data + i * 8)?);
    }
    for i in 0..layout.n_int_alg() {
        rows.push(read_i32(mem, store, sim_data + layout.int_off + i * 4)? as f64);
    }
    for j in 0..layout.n_bool_alg() {
        rows.push(read_i32(mem, store, sim_data + layout.bool_off + j * 4)? as f64);
    }
    Ok(())
}

type Store = wasmer::Store;

/// Flatten any wasmer engine/runtime error into our `anyhow` (their error types
/// — `RuntimeError`, `InstantiationError`, `MemoryAccessError`, … — do not share
/// a single anyhow-convertible type, so we format via `Debug`).
fn wt<T, E: std::fmt::Debug>(r: std::result::Result<T, E>) -> Result<T> {
    r.map_err(|e| anyhow!("{e:?}"))
}

/// Read one little-endian f64 from wasm linear memory at byte address `addr`.
fn read_f64(mem: &wasmer::Memory, store: &Store, addr: u32) -> Result<f64> {
    let mut b = [0u8; 8];
    mem.view(store).read(addr as u64, &mut b).map_err(|e| anyhow!("CodegenWasmJit: mem read: {e}"))?;
    Ok(f64::from_le_bytes(b))
}

fn write_f64(mem: &wasmer::Memory, store: &mut Store, addr: u32, v: f64) -> Result<()> {
    mem.view(&*store).write(addr as u64, &v.to_le_bytes()).map_err(|e| anyhow!("CodegenWasmJit: mem write: {e}"))?;
    Ok(())
}

pub(super) fn run(model: &SimModel) -> Result<RunResult> {
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
    let instance = wt(wasmer::Instance::new(&mut store, &model_module, &imports))?;
    let inst_time = t_inst.elapsed();

    let memory = rt_inst
        .exports
        .get_memory("memory")
        .map_err(|e| anyhow!("CodegenWasmJit: runtime has no `memory` export: {e:?}"))?
        .clone();
    let rt_alloc: wasmer::TypedFunction<u32, u32> = wt(rt_inst.exports.get_typed_function(&store, "rt_alloc"))?;

    let layout = &model.layout;
    let n_reals = layout.n_row_total(); // total result-row width (reals + int/bool algebraics)
    let n_steps = model.n_intervals;
    let n_rows = n_steps + 1;

    // Allocate the shared SimData block.
    let sim_data = wt(rt_alloc.call(&mut store, layout.total))?;

    let start = model.start_time;
    let stop = model.stop_time;

    // Select the integrator by `method`. `dassl` is OpenModelica's default; an
    // empty method (no `experiment` annotation / `method=` argument) means the
    // default too. `euler` keeps the existing forward-Euler drivers.
    let host_driven = std::env::var("OMC_WASM_SIM_DRIVER").map(|v| v == "host").unwrap_or(false);
    let method = model.method.as_str();
    let driver_label;
    let t0 = Instant::now();
    let rows: Vec<f64> = match method {
        "dassl" | "dasslrt" | "ida" | "" => {
            driver_label = "dassl";
            run_dassl(&mut store, &instance, &memory, model, sim_data, n_reals, n_rows, start, stop)?
        }
        "euler" => {
            if host_driven {
                driver_label = "euler-host";
                run_host(&mut store, &instance, &memory, model, sim_data, n_reals, n_rows, start, stop)?
            } else {
                driver_label = "euler-wasm";
                run_wasm(&mut store, &instance, &memory, sim_data, n_reals, n_rows, start, stop)?
            }
        }
        other => bail!(
            "CodegenWasmJit: unsupported integration method `{other}` (supported: `dassl`, `euler`)"
        ),
    };
    let elapsed = t0.elapsed();
    if bench {
        eprintln!(
            "wasm-jit sim [{}]: compile {:?} | instantiate {:?} | integrate {:?} ({} intervals, {:.2} us/interval)",
            driver_label,
            compile_time,
            inst_time,
            elapsed,
            n_steps,
            elapsed.as_secs_f64() * 1e6 / (n_rows.max(1) as f64),
        );
    }

    // Read parameter values from SimData (result `Param` order).
    let mut params = Vec::new();
    for v in &model.result_vars {
        if let ResultKind::Param { off, wty, .. } = &v.kind {
            let val = match wty {
                WTy::F64 => read_f64(&memory, &store, sim_data + off)?,
                WTy::I32 => {
                    let mut b = [0u8; 4];
                    memory.view(&store).read((sim_data + off) as u64, &mut b).map_err(|e| anyhow!("{e}"))?;
                    i32::from_le_bytes(b) as f64
                }
            };
            params.push(val);
        }
    }

    Ok(RunResult { rows, n_reals, params })
}

/// In-wasm driver: one call to `simulate`, then read the result buffer.
fn run_wasm(
    store: &mut Store,
    instance: &wasmer::Instance,
    memory: &wasmer::Memory,
    sim_data: u32,
    n_reals: u32,
    n_rows: u32,
    start: f64,
    stop: f64,
) -> Result<Vec<f64>> {
    let simulate = wt(instance.exports.get_typed_function::<(u32, f64, f64, u32), u32>(&store, "simulate"))?;
    let buf = wt(simulate.call(&mut *store, sim_data, start, stop, n_rows - 1))?;
    let count = (n_rows * n_reals) as usize;
    let mut bytes = vec![0u8; count * 8];
    memory.view(&*store).read(buf as u64, &mut bytes).map_err(|e| anyhow!("CodegenWasmJit: result read: {e}"))?;
    Ok(bytes.chunks_exact(8).map(|c| f64::from_le_bytes(c.try_into().unwrap())).collect())
}

/// Host-driven driver: the forward-Euler loop in native Rust.
fn run_host(
    store: &mut Store,
    instance: &wasmer::Instance,
    memory: &wasmer::Memory,
    model: &SimModel,
    sim_data: u32,
    n_reals: u32,
    n_rows: u32,
    start: f64,
    stop: f64,
) -> Result<Vec<f64>> {
    let f_params = wt(instance.exports.get_typed_function::<u32, ()>(&store, "functionParameters"))?;
    let f_init = wt(instance.exports.get_typed_function::<u32, ()>(&store, "functionInitialEquations"))?;
    let f_ode = wt(instance.exports.get_typed_function::<u32, ()>(&store, "functionODE"))?;
    let f_alg = wt(instance.exports.get_typed_function::<u32, ()>(&store, "functionAlgebraics"))?;

    wt(f_params.call(&mut *store, sim_data))?;
    wt(f_init.call(&mut *store, sim_data))?;

    let n_states = model.layout.n_states;
    let n_steps = n_rows - 1;
    let h = if n_steps == 0 { 0.0 } else { (stop - start) / n_steps as f64 };
    let states_base = sim_data + REAL_OFF;
    let ders_base = states_base + n_states * 8;

    let mut rows: Vec<f64> = Vec::with_capacity((n_rows * n_reals) as usize);
    for row in 0..n_rows {
        let time = start + row as f64 * h;
        write_f64(memory, store, sim_data + TIME_OFF, time)?;
        wt(f_ode.call(&mut *store, sim_data))?;
        wt(f_alg.call(&mut *store, sim_data))?;
        capture_row(memory, store, &mut rows, sim_data, &model.layout)?;
        if row == n_steps {
            break;
        }
        // Forward-Euler update of the states.
        for i in 0..n_states {
            let s = read_f64(memory, store, states_base + i * 8)?;
            let d = read_f64(memory, store, ders_base + i * 8)?;
            write_f64(memory, store, states_base + i * 8, s + h * d)?;
        }
    }
    Ok(rows)
}

// ===========================================================================
// DASSL (daskr) driver
// ===========================================================================
//
// The model is an explicit ODE `der(y) = f(t, y)` (the wasm `functionODE`
// computes `f` into the derivative slots given `time` + state slots). DASSL
// solves the equivalent DAE residual `G(t, y, y') = y' - f(t, y) = 0` with its
// numerical Jacobian, choosing internal steps adaptively and interpolating back
// to each output point. `daskr` runs natively; its `RES` callback is a bare
// `unsafe fn` (Fortran calling convention) that cannot capture, so the wasm
// context is passed through a thread-local raw pointer set for the duration of
// the integration (single-threaded; `RES` only runs nested inside `ddaskr`).

/// Context the `RES` callback needs to evaluate `f(t, y)` through wasm.
struct ResCtx {
    store: *mut Store,
    memory: wasmer::Memory,
    f_ode: wasmer::TypedFunction<u32, ()>,
    sim_data: u32,
    states_base: u32,
    ders_base: u32,
    n_states: usize,
    /// Number of residual (right-hand-side) evaluations, for the bench line.
    nfe: u64,
    /// Cumulative wall time spent inside the wasm `functionODE` call (the model
    /// RHS, incl. any `SES_LINEAR` numerical probing). Only accumulated when
    /// `bench` is set, to keep the hot path free of `Instant::now()`.
    wasm_ode: std::time::Duration,
    bench: bool,
    /// A wasm trap / memory error captured inside the callback, surfaced after
    /// `ddaskr` returns (the C-style callback cannot return a `Result`).
    err: Option<anyhow::Error>,
}

thread_local! {
    static RES_CTX: Cell<*mut ResCtx> = const { Cell::new(std::ptr::null_mut()) };
}

/// Clears the thread-local `RES_CTX` on drop so a stale pointer never leaks into
/// a later run on the same thread (even if `ddaskr` bails early).
struct ResCtxGuard;
impl Drop for ResCtxGuard {
    fn drop(&mut self) {
        RES_CTX.with(|c| c.set(std::ptr::null_mut()));
    }
}

/// DASSL residual `G(t, y, y') = y' - f(t, y)`. Writes `t` and the candidate
/// states `y` into `SimData`, calls the wasm `functionODE` to get `f` into the
/// derivative slots, then `delta := y' - f`. On any wasm error sets `IRES = -2`
/// (DASKR treats this as unrecoverable and returns a negative `IDID`).
unsafe fn dassl_res(
    t: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    _cj: *mut f64,
    delta: *mut f64,
    ires: *mut i32,
    _rpar: *mut f64,
    _ipar: *mut i32,
) {
    let ctx_ptr = RES_CTX.with(|c| c.get());
    if ctx_ptr.is_null() {
        unsafe { *ires = -2 };
        return;
    }
    let ctx = unsafe { &mut *ctx_ptr };
    if ctx.err.is_some() {
        unsafe { *ires = -2 };
        return;
    }
    let store = unsafe { &mut *ctx.store };
    let bail = |ctx: &mut ResCtx, e: anyhow::Error| {
        ctx.err = Some(e);
        unsafe { *ires = -2 };
    };
    // time + candidate states into SimData.
    if let Err(e) = write_f64(&ctx.memory, store, ctx.sim_data + TIME_OFF, unsafe { *t }) {
        return bail(ctx, e);
    }
    for i in 0..ctx.n_states {
        let yi = unsafe { *y.add(i) };
        if let Err(e) = write_f64(&ctx.memory, store, ctx.states_base + (i as u32) * 8, yi) {
            return bail(ctx, e);
        }
    }
    // f(t, y) -> derivative slots.
    let t_ode = if ctx.bench { Some(Instant::now()) } else { None };
    let ode_res = ctx.f_ode.call(&mut *store, ctx.sim_data).map_err(|e| anyhow!("{e:?}"));
    if let Some(t) = t_ode {
        ctx.wasm_ode += t.elapsed();
    }
    if let Err(e) = ode_res {
        return bail(ctx, e);
    }
    ctx.nfe += 1;
    // delta = y' - f.
    for i in 0..ctx.n_states {
        match read_f64(&ctx.memory, store, ctx.ders_base + (i as u32) * 8) {
            Ok(der) => unsafe { *delta.add(i) = *yprime.add(i) - der },
            Err(e) => return bail(ctx, e),
        }
    }
}

/// DASSL driver: integrate with `daskr::solver::ddaskr`, emitting a result row
/// at each of the `n_rows` output points (`start` plus the interval grid).
#[allow(clippy::too_many_arguments)]
fn run_dassl(
    store: &mut Store,
    instance: &wasmer::Instance,
    memory: &wasmer::Memory,
    model: &SimModel,
    sim_data: u32,
    n_reals: u32,
    n_rows: u32,
    start: f64,
    stop: f64,
) -> Result<Vec<f64>> {
    use daskr::solver;

    // Silence DASKR's own diagnostic printing (it would go to stdout and corrupt
    // the omc result record); failures are surfaced here via IDID instead.
    daskr::aux::xsetf(0);

    let f_params = wt(instance.exports.get_typed_function::<u32, ()>(&store, "functionParameters"))?;
    let f_init = wt(instance.exports.get_typed_function::<u32, ()>(&store, "functionInitialEquations"))?;
    let f_ode = wt(instance.exports.get_typed_function::<u32, ()>(&store, "functionODE"))?;
    let f_alg = wt(instance.exports.get_typed_function::<u32, ()>(&store, "functionAlgebraics"))?;

    wt(f_params.call(&mut *store, sim_data))?;
    wt(f_init.call(&mut *store, sim_data))?;

    let n_states = model.layout.n_states as usize;
    let states_base = sim_data + REAL_OFF;
    let ders_base = states_base + model.layout.n_states * 8;
    let n_steps = n_rows - 1;
    let h = if n_steps == 0 { 0.0 } else { (stop - start) / n_steps as f64 };

    let bench = std::env::var("OMC_WASM_SIM_BENCH").is_ok();
    // Cumulative wasm time spent emitting output rows (functionODE +
    // functionAlgebraics at each communication point), kept separate from the
    // RES-callback wasm time so the bench can attribute the integrate phase to
    // RES / output / daskr-core.
    let output_wasm = std::cell::Cell::new(std::time::Duration::ZERO);

    // Emit one result row (`[time, realVars…]`) from the current SimData, after
    // setting `time` and recomputing `functionODE`/`functionAlgebraics` so the
    // reported derivatives and algebraics are consistent with the states.
    let emit_row =
        |store: &mut Store, rows: &mut Vec<f64>, time: f64| -> Result<()> {
            write_f64(memory, store, sim_data + TIME_OFF, time)?;
            let t = if bench { Some(Instant::now()) } else { None };
            wt(f_ode.call(&mut *store, sim_data))?;
            wt(f_alg.call(&mut *store, sim_data))?;
            if let Some(t) = t {
                output_wasm.set(output_wasm.get() + t.elapsed());
            }
            capture_row(memory, store, rows, sim_data, &model.layout)?;
            Ok(())
        };

    let mut rows: Vec<f64> = Vec::with_capacity((n_rows * n_reals) as usize);
    // Row 0 at the start time.
    emit_row(store, &mut rows, start)?;

    // No states: nothing to integrate — just evaluate outputs on the grid.
    if n_states == 0 {
        for row in 1..n_rows {
            let time = if row == n_steps { stop } else { start + row as f64 * h };
            emit_row(store, &mut rows, time)?;
        }
        return Ok(rows);
    }

    // Initial y, y' from SimData. For an explicit ODE the consistent initial
    // derivative is exactly f(t0, y0), which `functionODE` (already called by
    // `emit_row`) has written into the derivative slots — so INFO(11)=0.
    let mut y: Vec<f64> = (0..n_states)
        .map(|i| read_f64(memory, store, states_base + (i as u32) * 8))
        .collect::<Result<_>>()?;
    let mut yp: Vec<f64> = (0..n_states)
        .map(|i| read_f64(memory, store, ders_base + (i as u32) * 8))
        .collect::<Result<_>>()?;

    // --- DASKR work arrays / options (dense, numerical Jacobian). ---
    let neq = n_states as i32;
    let nrt = 0i32;
    let mut info = [0i32; 24]; // all defaults: dense direct method, numerical Jac,
                               // scalar tolerances, interpolating output, no IC calc.
    let tol = if model.tolerance > 0.0 { model.tolerance } else { 1e-6 };
    let mut rtol = [tol];
    let mut atol = [tol];
    // Dense direct method storage (MAXORD=5): RWORK base 60 + 9*NEQ + NEQ^2,
    // IWORK base 40 + NEQ; pad generously.
    let lrw = (60 + 9 * neq + neq * neq + 3 * nrt + 64) as usize;
    let liw = (40 + neq + 64) as usize;
    let mut rwork = vec![0.0f64; lrw];
    let mut iwork = vec![0i32; liw];
    let mut rpar = [0.0f64];
    let mut ipar = [0i32];
    let mut jroot = [0i32];
    let mut idid = 0i32;
    let mut t = start;

    // Install the wasm context for the residual callback.
    let mut ctx = ResCtx {
        store: store as *mut Store,
        memory: memory.clone(),
        f_ode: f_ode.clone(),
        sim_data,
        states_base,
        ders_base,
        n_states,
        nfe: 0,
        wasm_ode: std::time::Duration::ZERO,
        bench,
        err: None,
    };
    let _guard = ResCtxGuard;
    RES_CTX.with(|c| c.set(&mut ctx as *mut ResCtx));

    for row in 1..n_rows {
        let mut tout = if row == n_steps { stop } else { start + row as f64 * h };
        // DASKR integrates past TOUT and interpolates back to T = TOUT
        // (INFO(3)=0), updating t, y, yp in place. INFO(1) stays 0 across
        // continuation calls (DASKR tracks state in rwork/iwork).
        unsafe {
            solver::ddaskr(
                dassl_res,
                neq,
                &mut t,
                y.as_mut_ptr(),
                yp.as_mut_ptr(),
                &mut tout,
                info.as_mut_ptr(),
                rtol.as_mut_ptr(),
                atol.as_mut_ptr(),
                &mut idid,
                rwork.as_mut_ptr(),
                lrw as i32,
                iwork.as_mut_ptr(),
                liw as i32,
                rpar.as_mut_ptr(),
                ipar.as_mut_ptr(),
                solver::dummy_jacd,
                solver::dummy_jack,
                solver::dummy_psol,
                solver::dummy_rt,
                nrt,
                jroot.as_mut_ptr(),
            );
        }
        // Surface a wasm error captured in the callback, then DASSL failures.
        if let Some(e) = ctx.err.take() {
            return Err(e.context(format!("in DASSL residual at t={t}")));
        }
        if idid < 0 {
            bail!("CodegenWasmJit: DASSL (daskr) failed at t={t} (target {tout}), IDID={idid}");
        }
        // t == tout now; write the interpolated state back and emit the row.
        for i in 0..n_states {
            write_f64(memory, store, states_base + (i as u32) * 8, y[i])?;
        }
        emit_row(store, &mut rows, tout)?;
    }

    if ctx.bench {
        let nst = iwork.get(10).copied().unwrap_or(0); // IWORK(11) = number of steps
        let nje = iwork.get(12).copied().unwrap_or(0);  // IWORK(13) = number of Jacobian evals
        eprintln!(
            "wasm-jit sim [dassl] DASKR stats: {nst} steps, {} residual evals (={:.1}/step), {nje} Jacobian evals",
            ctx.nfe,
            ctx.nfe as f64 / (nst.max(1) as f64),
        );
        eprintln!(
            "wasm-jit sim [dassl] integrate breakdown: RES wasm {:?} ({:.2} us/eval) | output wasm {:?} ({} pts) | daskr core (host, rest)",
            ctx.wasm_ode,
            ctx.wasm_ode.as_secs_f64() * 1e6 / (ctx.nfe.max(1) as f64),
            output_wasm.get(),
            n_rows,
        );
    }
    Ok(rows)
}
