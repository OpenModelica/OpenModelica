//! Standalone `wasm32-wasip1` simulation command (the `_start` half of the
//! wasm-jit standalone export). Compiled only for `target_os = "wasi"`.
//!
//! After `wasm-merge` joins a model module with this runtime, this module's
//! `_start` drives the whole run in-wasm and writes `<prefix>_res.mat` via WASI —
//! no host. It runs the **same** engine-independent driver as the interactive
//! path (`openmodelica_sim_meta::driver`), reaching the model through a
//! [`StandaloneEngine`] that calls the model's exports directly (imports resolved
//! by the merge) and accesses the one shared linear memory in place. So the
//! standalone command handles events, state sets, samples and homotopy exactly
//! like the host/in-wasm drivers — no divergent second integrator.
//!
//! ## Merge contract
//! - The model imports its runtime functions + `memory` + `rt_assert` from module
//!   **`rt`**, and exports every driver entry point (`functionParameters`,
//!   `functionInitStartValues`, `functionInitialEquations[_lambda0]`,
//!   `functionODE`, `functionAlgebraics`, `functionStateSetJacobians`,
//!   `functionZeroCrossings`, `initSample`, `callExternalObjectDestructors`,
//!   `simulate`) plus the metadata accessors `om_meta_ptr`/`om_meta_len`. The
//!   optional ones are always exported (empty stub when the feature is absent), so
//!   the merge always resolves.
//! - This runtime exports the `rt_*` functions + `memory` + `rt_assert` + `_start`
//!   and imports the model's exports from module **`model`**.
//! - `wasm-merge runtime.wasm rt model.wasm model` connects both directions,
//!   leaving only the WASI imports (satisfied by `wasmtime`/the worker shim).

use core::cell::UnsafeCell;

use openmodelica_mat_writer::Precision;
use openmodelica_sim_meta::driver::{self, SimEngine};
use openmodelica_sim_meta::result::ResultStream;
use openmodelica_sim_meta::simflags;
use openmodelica_sim_meta::{self as meta, SimMeta};

// Model exports, resolved by wasm-merge (module "model"). Calls are unsafe; a
// trap inside one aborts the command (surfaced as a failed run by the caller).
// The optional functions are always exported by the emitter (empty when the
// model lacks the feature), so every import resolves regardless of the model.
#[link(wasm_import_module = "model")]
unsafe extern "C" {
    fn functionParameters(sim_data: u32);
    fn functionInitStartValues(sim_data: u32);
    fn functionInitialEquations(sim_data: u32);
    fn functionInitialEquations_lambda0(sim_data: u32);
    fn functionODE(sim_data: u32);
    fn functionAlgebraics(sim_data: u32);
    fn functionStateSetJacobians(sim_data: u32);
    fn functionZeroCrossings(sim_data: u32, gout: u32);
    fn functionZeroCrossingsEquations(sim_data: u32);
    fn functionUpdateRelations(sim_data: u32);
    fn functionCheckAsserts(sim_data: u32);
    fn functionStoreDelayed(sim_data: u32);
    fn functionInitDelay(sim_data: u32);
    fn functionStoreSpatialDistribution(sim_data: u32);
    fn functionInitSpatialDistribution(sim_data: u32);
    fn functionUpdateBoundParameters(sim_data: u32);
    fn functionUpdateBoundVariableAttributes(sim_data: u32);
    fn functionRemovedInitialEquations(sim_data: u32);
    fn functionJacA_constantEqns(sim_data: u32);
    fn functionJacA_column(sim_data: u32);
    fn initSample(sim_data: u32);
    fn callExternalObjectDestructors(sim_data: u32);
    fn symbolicInlineSystem(sim_data: u32);
    fn functionDAE(sim_data: u32);
    fn linearJacA(sim_data: u32);
    fn linearJacB(sim_data: u32);
    fn linearJacC(sim_data: u32);
    fn linearJacD(sim_data: u32);
    fn simulate(sim_data: u32, start: f64, stop: f64, n_steps: u32) -> u32;
    /// Pointer to / length of the encoded `SimMeta` blob in linear memory.
    fn om_meta_ptr() -> u32;
    fn om_meta_len() -> u32;
}

// lld synthesises this (wasi-libc ctors: preopen/stdio init). A custom `_start`
// in a cdylib must call it before any std I/O, since std does not generate the
// `_start` that normally would.
unsafe extern "C" {
    fn __wasm_call_ctors();
}

/// Decode the model's embedded metadata blob.
fn read_meta() -> SimMeta {
    let ptr = unsafe { om_meta_ptr() };
    let len = unsafe { om_meta_len() } as usize;
    let bytes = unsafe { core::slice::from_raw_parts(ptr as *const u8, len) };
    meta::decode(bytes).expect("openmodelica_sim_meta: bad metadata blob")
}

/// [`SimEngine`] over the merged module: linear memory is directly addressable
/// (the runtime *is* in it), and the model's exports are called directly (the
/// merge resolved the `model` imports). Single-threaded WASI command.
struct StandaloneEngine;

impl SimEngine for StandaloneEngine {
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> driver::Result<()> {
        let src = unsafe { core::slice::from_raw_parts(addr as *const u8, buf.len()) };
        buf.copy_from_slice(src);
        Ok(())
    }
    fn write_bytes(&mut self, addr: u32, buf: &[u8]) -> driver::Result<()> {
        let dst = unsafe { core::slice::from_raw_parts_mut(addr as *mut u8, buf.len()) };
        dst.copy_from_slice(buf);
        Ok(())
    }
    fn set_string(&mut self, addr: u32, bytes: &[u8]) -> driver::Result<()> {
        crate::set_string_slot(addr, bytes);
        Ok(())
    }
    fn call1_raw(&mut self, name: &str, arg: u32) -> driver::Result<()> {
        unsafe {
            match name {
                "functionParameters" => functionParameters(arg),
                "functionInitStartValues" => functionInitStartValues(arg),
                "functionInitialEquations" => functionInitialEquations(arg),
                "functionInitialEquations_lambda0" => functionInitialEquations_lambda0(arg),
                "functionODE" => functionODE(arg),
                "functionAlgebraics" => functionAlgebraics(arg),
                "functionStateSetJacobians" => functionStateSetJacobians(arg),
                "functionZeroCrossingsEquations" => functionZeroCrossingsEquations(arg),
                "functionUpdateRelations" => functionUpdateRelations(arg),
                "functionCheckAsserts" => functionCheckAsserts(arg),
                "functionStoreDelayed" => functionStoreDelayed(arg),
                "functionInitDelay" => functionInitDelay(arg),
                "functionStoreSpatialDistribution" => functionStoreSpatialDistribution(arg),
                "functionInitSpatialDistribution" => functionInitSpatialDistribution(arg),
                "functionUpdateBoundParameters" => functionUpdateBoundParameters(arg),
                "functionUpdateBoundVariableAttributes" => functionUpdateBoundVariableAttributes(arg),
                "functionRemovedInitialEquations" => functionRemovedInitialEquations(arg),
                "functionJacA_constantEqns" => functionJacA_constantEqns(arg),
                "functionJacA_column" => functionJacA_column(arg),
                "initSample" => initSample(arg),
                "callExternalObjectDestructors" => callExternalObjectDestructors(arg),
                "symbolicInlineSystem" => symbolicInlineSystem(arg),
                "functionDAE" => functionDAE(arg),
                "linearJacA" => linearJacA(arg),
                "linearJacB" => linearJacB(arg),
                "linearJacC" => linearJacC(arg),
                "linearJacD" => linearJacD(arg),
                "functionInitSynchronous" => return Err(SYNC_UNSUPPORTED),
                _ => return Err("wasm-jit standalone: unknown model function"),
            }
        }
        Ok(())
    }
    fn call1_if_present_raw(&mut self, name: &str, arg: u32) -> driver::Result<()> {
        // Every entry point is always exported (empty stub if unused), so a plain
        // call is a no-op when the feature is absent.
        self.call1_raw(name, arg)
    }
    fn call2_raw(&mut self, name: &str, a: u32, b: u32) -> driver::Result<()> {
        if name == driver::MODEL_FN_ZC {
            unsafe { functionZeroCrossings(a, b) };
            return Ok(());
        }
        // Importing `evaluateDAEResiduals` (or the two synchronous dispatchers) would
        // leave every model without that feature with an unresolved `model.*` import,
        // so the standalone export supports neither.
        Err(match name {
            driver::MODEL_FN_DAE => {
                "wasm-jit standalone: --daeMode models are not supported by the standalone export"
            }
            _ => SYNC_UNSUPPORTED,
        })
    }
    fn call_simulate(&mut self, sim_data: u32, start: f64, stop: f64, n_steps: u32) -> driver::Result<u32> {
        Ok(unsafe { simulate(sim_data, start, stop, n_steps) })
    }
    fn has_simulate_entry(&mut self) -> bool {
        true
    }
    fn take_pending_reinits(&mut self) -> Vec<(u32, f64)> {
        crate::take_reinit_notes()
    }
    fn take_pending_assert(&mut self) -> Option<[i32; 9]> {
        // No host to record it; a failed model assert traps (see `rt_assert`).
        None
    }
    fn context_addr(&mut self) -> u32 {
        crate::nls::rt_context_addr()
    }
    fn prof_row(&mut self) -> u32 {
        crate::prof::rt_prof_row()
    }
    fn prof_dump(&mut self) -> u32 {
        crate::prof::rt_prof_dump()
    }
    fn prof_clear(&mut self) {
        crate::prof::rt_prof_clear(0);
    }
    fn prof_init(&mut self, n: u32) {
        crate::prof::rt_prof_init(n);
    }
    fn error_stage_addr(&mut self) -> u32 {
        crate::nls::rt_error_stage_addr()
    }
    fn no_throw_div_zero_addr(&mut self) -> u32 {
        crate::nls::rt_no_throw_div_zero_addr()
    }
    fn clean_nls_history(&mut self, time: f64) {
        crate::nls::rt_nls_clean_history(time);
    }
}

const SYNC_UNSUPPORTED: &str =
    "wasm-jit standalone: synchronous (clocked) models are not supported by the standalone export";

/// Run the prepared model with the shared driver and write its result file.
/// A failure traps (the command then exits nonzero).
fn run() {
    let mut m = read_meta();
    driver::set_log_sink(crate::omclog::sink);
    simflags::with_flags(|f| {
        simflags::print_notices(f);
        m.apply_flags(f);
    });
    let sim_data = crate::rt_sim_data_new(m.layout.total);
    let mut engine = StandaloneEngine;
    crate::nls::rt_set_step_size(m.step_size());
    crate::files::set_prefix(&m.prefix);

    // wasip1 has a monotonic clock, so `-alarm` works; nothing cancels a command.
    driver::set_clock(now_ms);
    // `+inf` budget = run to completion; the driver short-circuits that deadline.
    // See `session::rt_sim_start`.
    #[cfg(sundials)]
    crate::model_ctx::set_context(&m, sim_data);
    arm_result(&m);
    let (result, _label) = match driver::drive(&mut engine, &m, sim_data, m.method.as_str(), false, false) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("wasm-jit standalone: simulation failed: {e}");
            core::arch::wasm32::unreachable()
        }
    };

    if let Some(f) = &result.lin {
        let path = lin_file(&f.name);
        std::fs::write(&path, &f.content)
            .expect("wasm-jit standalone: cannot write the linearized model");
        if let Some(lin) = &m.lin {
            use openmodelica_sim_meta::omclog::{STDOUT, error, info};
            let (msgs, is_error) = openmodelica_sim_meta::linearize::write_notice(lin, f, &path);
            for msg in &msgs {
                if is_error { error(STDOUT, false, msg) } else { info(STDOUT, false, msg) }
            }
        }
    }

    if let Some(mut st) = result_stream().take() {
        st.finish();
    }
    if !openmodelica_sim_meta::result::known(&m.output_format) || m.output_format == "empty" {
        return; // "empty": run only (benchmarking), no file
    }
    let path = m.result_file();
    let size = std::fs::metadata(&path).map(|md| md.len() as i64).unwrap_or(-1);
    // C's `printModelInfo`, which the executable runs after closing the result.
    openmodelica_sim_meta::profiling::finish(&m, &path, size);
}

struct ResultCell(UnsafeCell<(Option<(Vec<bool>, Precision)>, Option<ResultStream>)>);
unsafe impl Sync for ResultCell {}
static RESULT: ResultCell = ResultCell(UnsafeCell::new((None, None)));

fn result_stream() -> &'static mut Option<ResultStream> {
    unsafe { &mut (*RESULT.0.get()).1 }
}

/// Route the run's rows to `<prefix>_res.<format>`, written as they arrive. A
/// run-time `-variableFilter` was refused at the flag check (no regex engine);
/// the model's own filter is the codegen's verdict.
fn arm_result(m: &SimMeta) {
    let keep = m.output_keep(None);
    // `-single` narrows the real data to 4-byte float (C's `FLAG_SINGLE_PRECISION`).
    let precision =
        simflags::with_flags(|f| if f.single_precision { Precision::Single } else { Precision::Double });
    unsafe { (*RESULT.0.get()).0 = Some((keep, precision)) };
    driver::set_result_opener(Some(open_result));
    driver::set_row_sink(Some(sink_rows), Some(sink_finish));
}

fn open_result(e: &mut dyn driver::SimEngine, m: &SimMeta, sim_data: u32) -> driver::Result<()> {
    let Some((keep, precision)) = (unsafe { (*RESULT.0.get()).0.take() }) else { return Ok(()) };
    let path = m.result_file();
    let format = openmodelica_sim_meta::result::format_of(&path, &m.output_format);
    let st = openmodelica_sim_meta::result::open_stream(e, m, sim_data, format, &keep, precision, || {
        crate::result_out::open(&path)
    })?;
    *result_stream() = Some(st);
    Ok(())
}

fn sink_rows(rows: &[f64]) -> bool {
    match result_stream() {
        Some(s) => {
            s.push_rows(rows);
            true
        }
        None => false,
    }
}

fn sink_finish() {
    if let Some(s) = result_stream() {
        s.finish();
    }
}

/// C's `linearize`: `linearized_model.<ext>` under `-outputPath`.
fn lin_file(name: &str) -> String {
    simflags::with_flags(|f| match &f.output_path {
        Some(dir) => format!("{dir}/{name}"),
        None => name.to_string(),
    })
}

/// Wall clock for the driver, in ms since the first reading.
fn now_ms() -> f64 {
    use std::time::Instant;
    static START: std::sync::OnceLock<Instant> = std::sync::OnceLock::new();
    START.get_or_init(Instant::now).elapsed().as_secs_f64() * 1000.0
}

/// The command entry point. Runs wasi-libc ctors (preopen/stdio init), takes the
/// runtime flags off the command line, then simulates. The merged module is a WASI
/// command, so `wasmtime model.wasm -nls=kinsol` arrives through `args_get`.
#[unsafe(no_mangle)]
pub extern "C" fn _start() {
    unsafe { __wasm_call_ctors() };
    let argv: Vec<String> = std::env::args().collect();
    match simflags::parse(&argv).and_then(|f| {
        simflags::check(&f, crate::sundials::capabilities()).map(|()| f)
    }) {
        Ok(f) => {
            openmodelica_solvers::solverflags::apply_flags(&f);
            simflags::set_flags(f);
        }
        Err(e) => {
            eprintln!("wasm-jit standalone: {e}");
            core::arch::wasm32::unreachable()
        }
    }
    run();
}

/// In-wasm `rt_assert`: the standalone has no host to record the failing
/// assertion, so print the message (`msg` is an `rt` String handle:
/// `[refcount:u32][len:u32][utf8…]`) and trap, which aborts the command.
#[unsafe(no_mangle)]
pub extern "C" fn rt_assert(msg: i32, _file: i32, _sline: i32, _scol: i32, _eline: i32, _ecol: i32, _read_only: i32, _cond: i32, _initial: i32, _sim_data: i32) -> i32 {
    if msg != 0 {
        let h = msg as u32;
        let len = unsafe { crate::load_u32(h + 4) } as usize;
        let bytes = unsafe { core::slice::from_raw_parts((h + 8) as *const u8, len) };
        if let Ok(s) = core::str::from_utf8(bytes) {
            eprintln!("wasm-jit standalone: assertion failed: {s}");
        }
    }
    core::arch::wasm32::unreachable()
}

/// In-wasm `rt_print`: the `print` builtin. Write the String handle's bytes to
/// stdout, flushed so the captured output stays ordered.
#[unsafe(no_mangle)]
pub extern "C" fn rt_print(handle: i32) {
    if handle != 0 {
        let h = handle as u32;
        let len = unsafe { crate::load_u32(h + 4) } as usize;
        let bytes = unsafe { core::slice::from_raw_parts((h + 8) as *const u8, len) };
        use std::io::Write;
        let mut out = std::io::stdout();
        let _ = out.write_all(bytes);
        let _ = out.flush();
    }
}

/// In-wasm `rt_row_asserts`: nothing to format — `rt_assert_warning` below has
/// already printed the message.
#[unsafe(no_mangle)]
pub extern "C" fn rt_row_asserts(_sim_data: i32, _warn: i32) -> i32 {
    0
}

/// In-wasm `rt_assert_warning`: a non-fatal (AssertionLevel.warning) violation.
/// The standalone has no host driver to format a `LOG_ASSERT` block, so print the
/// message (`msg` is an `rt` String handle) and continue — no trap.
#[unsafe(no_mangle)]
pub extern "C" fn rt_assert_warning(
    _cond: i32,
    msg: i32,
    _file: i32,
    _sline: i32,
    _scol: i32,
    _eline: i32,
    _ecol: i32,
    _read_only: i32,
    _initial: i32,
) {
    if msg != 0 {
        let h = msg as u32;
        let len = unsafe { crate::load_u32(h + 4) } as usize;
        let bytes = unsafe { core::slice::from_raw_parts((h + 8) as *const u8, len) };
        if let Ok(s) = core::str::from_utf8(bytes) {
            eprintln!("wasm-jit standalone: assertion warning: {s}");
        }
    }
}
