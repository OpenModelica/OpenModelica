//! In-wasm simulation session (`rt_sim_*` ABI), for the no_std JIT runtime
//! (`wasm32-unknown-unknown`).
//!
//! The host instantiates the runtime + model sharing one linear memory, appends
//! the model's equation-function exports to the shared `__indirect_function_table`
//! at a fixed slot order, and then drives the run entirely in-wasm through these
//! exports. The shared [`openmodelica_sim_meta::driver`] reaches the model via
//! `call_indirect` (wasm->wasm, no host boundary per residual) instead of the
//! host calling each `functionODE`/Jacobian column through the wasm engine.
//!
//! The result file is written here as the rows arrive (`rt_sim_set_result`):
//! through WASI on wasip1, through the `rt_host_result_*` imports on
//! `wasm32-unknown-unknown`. Params/stats are read back via the accessor exports.

use alloc::boxed::Box;
use alloc::vec::Vec;
use core::cell::UnsafeCell;

use alloc::string::String;
use openmodelica_mat_writer::Precision;
use openmodelica_sim_meta::WTy;
use openmodelica_sim_meta::driver::{self, Advance, Driver, SimEngine};
use openmodelica_sim_meta::result::ResultStream;
use openmodelica_sim_meta::simflags;
use openmodelica_sim_meta::{SimMeta, SolveStats};

// Host imports for the per-chunk budget clock and the cooperative cancel poll.
// Polled O(steps) times (per output row / DASSL segment), not per residual, so
// these few host crossings are negligible next to the ~35k model calls they
// replace with wasm->wasm `call_indirect`s.
#[link(wasm_import_module = "env")]
unsafe extern "C" {
    fn rt_host_now_ms() -> f64;
    fn rt_host_cancel() -> i32;
    /// Copy up to `max` of the violations the model left with the host's
    /// `rt_assert`/`rt_assert_warning` (which it imports either way) to `ptr`.
    fn rt_host_take_warnings(ptr: u32, max: u32) -> u32;
    /// Same for the `reinit`s the model recorded with `rt_reinit_note`.
    fn rt_host_take_reinits(ptr: u32, max: u32) -> u32;
    /// Open/close C's `noThrowAsserts` phase, on the host: that is where
    /// `rt_assert` lives, whichever driver runs.
    fn rt_host_set_no_throw(v: i32);
    /// Initialization is over; the host splits its output capture there.
    fn rt_host_init_done();
    /// C's `RHSFinalFlag`: the external "C" libraries are the host's, so is the flag.
    fn rt_host_rhs_final(v: i32);
}

fn init_done_hook() {
    unsafe { rt_host_init_done() };
}

pub(crate) fn now_ms_hook() -> f64 {
    unsafe { rt_host_now_ms() }
}
fn cancel_hook() -> bool {
    unsafe { rt_host_cancel() != 0 }
}

// Table-slot order the host populates (relative to `fn_base`): a function's slot is
// its index in `driver::MODEL_FNS`, the one list both sides derive from. The runtime
// reaches slot `s` via `call_indirect(fn_base + s)`; an export the model does not
// have gets a cleared `present_mask` bit.
/// Number of table slots the host must populate, in `MODEL_FNS` order.
#[allow(dead_code)]
pub const N_SLOTS: u32 = driver::MODEL_FNS.len() as u32;

/// `present_mask` is a `u64` on both sides, so the list cannot outgrow it.
const _: () = assert!(N_SLOTS <= 64);

fn slot_of(name: &str) -> Option<u32> {
    driver::MODEL_FNS.iter().position(|&n| n == name).map(|i| i as u32)
}

/// In-wasm [`SimEngine`]: linear memory is directly addressable (the runtime *is*
/// in it), and model functions are reached by `call_indirect` over the shared
/// table. A fn-pointer value is its table index on wasm, so a `transmute` + call
/// lowers to `call_indirect` of the matching type (as `rt_call1_indirect` /
/// `rt_solve_nls` already do).
struct InWasmEngine {
    fn_base: u32,
    present_mask: u64,
}

impl InWasmEngine {
    fn present(&self, slot: u32) -> bool {
        self.present_mask & (1u64 << slot) != 0
    }
}

impl SimEngine for InWasmEngine {
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
        let slot = slot_of(name).ok_or("in-wasm engine: unknown model function")?;
        if !self.present(slot) {
            return Err("in-wasm engine: required model function not exported");
        }
        let idx = self.fn_base + slot;
        let f: extern "C" fn(u32) = unsafe { core::mem::transmute(idx as usize) };
        f(arg);
        Ok(())
    }
    fn call1_if_present_raw(&mut self, name: &str, arg: u32) -> driver::Result<()> {
        let slot = match slot_of(name) {
            Some(s) => s,
            None => return Ok(()),
        };
        if self.present(slot) {
            self.call1_raw(name, arg)?;
        }
        Ok(())
    }
    fn call2_raw(&mut self, name: &str, a: u32, b: u32) -> driver::Result<()> {
        let slot = slot_of(name).ok_or("in-wasm engine: unknown model function")?;
        if !self.present(slot) {
            return Err("in-wasm engine: required model function not exported");
        }
        let f: extern "C" fn(u32, u32) = unsafe { core::mem::transmute((self.fn_base + slot) as usize) };
        f(a, b);
        Ok(())
    }
    fn call_simulate(&mut self, sim_data: u32, start: f64, stop: f64, n_steps: u32) -> driver::Result<u32> {
        let slot = slot_of("simulate").ok_or("in-wasm engine: `simulate` has no table slot")?;
        if !self.present(slot) {
            return Err("in-wasm engine: no `simulate` export");
        }
        let idx = self.fn_base + slot;
        let f: extern "C" fn(u32, f64, f64, u32) -> u32 = unsafe { core::mem::transmute(idx as usize) };
        Ok(f(sim_data, start, stop, n_steps))
    }
    fn has_simulate_entry(&mut self) -> bool {
        slot_of("simulate").is_some_and(|s| self.present(s))
    }
    fn take_pending_warnings(&mut self) -> Vec<[i32; 10]> {
        let mut out = Vec::new();
        loop {
            let mut buf = [[0i32; 10]; 8];
            let n = unsafe { rt_host_take_warnings(buf.as_mut_ptr() as u32, buf.len() as u32) } as usize;
            out.extend_from_slice(&buf[..n.min(buf.len())]);
            if n < buf.len() {
                return out;
            }
        }
    }
    fn take_pending_reinits(&mut self) -> Vec<(u32, f64)> {
        let mut out = Vec::new();
        loop {
            let mut buf = [(0u32, 0.0f64); 8];
            let n = unsafe { rt_host_take_reinits(buf.as_mut_ptr() as u32, buf.len() as u32) } as usize;
            out.extend_from_slice(&buf[..n.min(buf.len())]);
            if n < buf.len() {
                return out;
            }
        }
    }
    fn take_pending_assert(&mut self) -> Option<[i32; 9]> {
        // The model imports `rt_assert` from the host; a failed assert traps and
        // unwinds out of `rt_sim_advance` to the host, which reports it. Nothing
        // to take in-wasm.
        None
    }
    fn rt_stats(&mut self) -> [u64; driver::RT_STATS] {
        let mut out = [0u64; driver::RT_STATS];
        for (k, slot) in out.iter_mut().enumerate() {
            *slot = crate::rt_stat(k as u32);
        }
        out
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
    fn set_rhs_final(&mut self, final_eval: bool) {
        unsafe { rt_host_rhs_final(final_eval as i32) };
    }
}

/// One resumable in-wasm run: engine, driver, decoded model view, and the result
/// buffers filled on completion. Single-threaded, so a plain `static` cell holds
/// it across the `rt_sim_advance` calls.
struct Session {
    engine: InWasmEngine,
    driver: Box<dyn Driver>,
    model: SimMeta,
    sim_data: u32,
    n_reals: u32,
    finished: bool,
    rows: Vec<f64>,
    /// Rows the result stream took (0 when the host keeps the rows).
    rows_written: u32,
    params: Vec<f64>,
    stats: SolveStats,
    /// `-l`'s linearized model as `<file name>\0<content>`, for the host to write.
    lin: Vec<u8>,
    /// `+profiling`'s collected state (`profiling::snapshot`), for the host to
    /// render into the report once it has written the result file.
    prof: Vec<u8>,
    /// The initial result row, encoded for the host
    /// ([`openmodelica_sim_meta::result::decode_first_row`]).
    first_row: Vec<u8>,
}

/// The result file the next [`rt_sim_start`] writes.
struct ResultCfg {
    path: String,
    keep: Vec<bool>,
    precision: Precision,
}

struct ResultCell(UnsafeCell<(Option<ResultCfg>, Option<ResultStream>)>);
unsafe impl Sync for ResultCell {}
static RESULT: ResultCell = ResultCell(UnsafeCell::new((None, None)));

fn result_cfg() -> &'static mut Option<ResultCfg> {
    unsafe { &mut (*RESULT.0.get()).0 }
}
fn result_stream() -> &'static mut Option<ResultStream> {
    unsafe { &mut (*RESULT.0.get()).1 }
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

#[cfg(target_os = "wasi")]
use crate::result_out::open as open_result;

#[cfg(not(target_os = "wasi"))]
use openmodelica_sim_meta::result::ResultOut;

#[cfg(not(target_os = "wasi"))]
#[link(wasm_import_module = "env")]
unsafe extern "C" {
    fn rt_host_result_open(path: u32, len: u32) -> i32;
    fn rt_host_result_write(ptr: u32, len: u32) -> i32;
    fn rt_host_result_write_at(pos: u64, ptr: u32, len: u32) -> i32;
    fn rt_host_result_close();
}

/// The host's file, fed through `rt_host_result_*`; the buffer keeps the host
/// crossings to one per few hundred KB.
#[cfg(not(target_os = "wasi"))]
struct HostOut {
    buf: Vec<u8>,
    ok: bool,
    closed: bool,
}

#[cfg(not(target_os = "wasi"))]
impl HostOut {
    fn send(&mut self) {
        if !self.buf.is_empty() {
            self.ok &= unsafe { rt_host_result_write(self.buf.as_ptr() as u32, self.buf.len() as u32) } == 0;
            self.buf.clear();
        }
    }
}

#[cfg(not(target_os = "wasi"))]
impl ResultOut for HostOut {
    fn write(&mut self, bytes: &[u8]) -> bool {
        self.buf.extend_from_slice(bytes);
        if self.buf.len() >= 1 << 18 {
            self.send();
        }
        self.ok
    }
    fn write_at(&mut self, pos: u64, bytes: &[u8]) -> bool {
        self.send();
        self.ok &= unsafe { rt_host_result_write_at(pos, bytes.as_ptr() as u32, bytes.len() as u32) } == 0;
        self.ok
    }
    fn flush(&mut self) -> bool {
        self.send();
        self.ok
    }
    fn close(&mut self) -> bool {
        if !self.closed {
            self.send();
            unsafe { rt_host_result_close() };
            self.closed = true;
        }
        self.ok
    }
}

#[cfg(not(target_os = "wasi"))]
impl Drop for HostOut {
    fn drop(&mut self) {
        self.close();
    }
}

#[cfg(not(target_os = "wasi"))]
fn open_result(path: &str) -> Option<Box<dyn ResultOut>> {
    (unsafe { rt_host_result_open(path.as_ptr() as u32, path.len() as u32) } == 0).then(|| {
        Box::new(HostOut { buf: Vec::with_capacity(1 << 18), ok: true, closed: false }) as Box<dyn ResultOut>
    })
}

/// Have the next [`rt_sim_start`] write the result file to `path` (`-outputFormat`
/// picks the format): `keep` is one byte per result signal (the host's
/// `-variableFilter` decision), `single` selects 4-byte reals.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_set_result(path: u32, path_len: u32, keep: u32, keep_len: u32, single: i32) -> i32 {
    let path = unsafe { core::slice::from_raw_parts(path as *const u8, path_len as usize) };
    let keep = unsafe { core::slice::from_raw_parts(keep as *const u8, keep_len as usize) };
    *result_cfg() = Some(ResultCfg {
        path: String::from_utf8_lossy(path).into_owned(),
        keep: keep.iter().map(|&k| k != 0).collect(),
        precision: if single != 0 { Precision::Single } else { Precision::Double },
    });
    0
}

/// Open the run's result file once initialization has left `SimData` consistent
/// (C's `writeParameterData` point), and route the rows to it.
fn open_result_stream(engine: &mut InWasmEngine, model: &SimMeta, sim_data: u32) -> i32 {
    *result_stream() = None;
    let Some(cfg) = result_cfg().take() else {
        driver::set_row_sink(None, None);
        return 0;
    };
    let format = openmodelica_sim_meta::result::format_of(&cfg.path, &model.output_format);
    match openmodelica_sim_meta::result::open_stream(engine, model, sim_data, format, &cfg.keep, cfg.precision, || {
        open_result(&cfg.path)
    }) {
        Ok(st) => *result_stream() = Some(st),
        Err(_) => return -3,
    }
    driver::set_row_sink(Some(sink_rows), Some(sink_finish));
    0
}

struct SessionCell(UnsafeCell<Option<Session>>);
unsafe impl Sync for SessionCell {}
static SESSION: SessionCell = SessionCell(UnsafeCell::new(None));

fn session() -> &'static mut Option<Session> {
    unsafe { &mut *SESSION.0.get() }
}

/// Set the runtime flags for the next [`rt_sim_start`] from an argv blob in the
/// WASI `args_get` layout (NUL-terminated strings back to back, `argv[0]` the
/// program name). Returns 0, or -1 if a flag is malformed or asks for something
/// this runtime cannot do — the host parses the same argv with the same code, so
/// it reports *which* flag without a second error channel.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_set_args(ptr: u32, len: u32) -> i32 {
    let bytes = unsafe { core::slice::from_raw_parts(ptr as *const u8, len as usize) };
    let argv = simflags::argv_from_bytes(bytes);
    // The host resolves `-variableFilter` (`rt_sim_set_result`'s `keep`).
    match simflags::parse(&argv).and_then(|f| {
        let cap = simflags::Capabilities { variable_filter: true, ..crate::sundials::capabilities() };
        simflags::check(&f, cap).map(|()| f)
    }) {
        Ok(f) => {
            openmodelica_solvers::solverflags::apply_flags(&f);
            simflags::set_flags(f);
            0
        }
        Err(_) => -1,
    }
}

/// Set the parameter/start overrides and the `-iif` imports for the next
/// [`rt_sim_start`]. The host's own stores cannot reach this module's copies, so it
/// hands them over: `n_params: u32`, that many `(off: u32, wty: u32, val: f64)`, then
/// `n_starts: u32` and the same again (`wty` 0 = f64, 1 = i32); then the imports as
/// `n_values: u32`, `time: f64`, `file_len: u32`, the file name's UTF-8 bytes and
/// that many `(roster index: u32, val: f64)`. No imports is `n_values` absent.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_set_overrides(ptr: u32, len: u32) -> i32 {
    let bytes = unsafe { core::slice::from_raw_parts(ptr as *const u8, len as usize) };
    let mut p = 0usize;
    let u32_at = |p: &mut usize| -> Option<u32> {
        let v = bytes.get(*p..*p + 4)?;
        *p += 4;
        Some(u32::from_le_bytes(v.try_into().ok()?))
    };
    let f64_at = |p: &mut usize| -> Option<f64> {
        let v = bytes.get(*p..*p + 8)?;
        *p += 8;
        Some(f64::from_le_bytes(v.try_into().ok()?))
    };
    let group = |p: &mut usize| -> Option<Vec<(u32, WTy, f64)>> {
        let n = u32_at(p)? as usize;
        let mut out = Vec::with_capacity(n);
        for _ in 0..n {
            let off = u32_at(p)?;
            let wty = if u32_at(p)? == 0 { WTy::F64 } else { WTy::I32 };
            out.push((off, wty, f64_at(p)?));
        }
        Some(out)
    };
    let imports = |p: &mut usize| -> Option<openmodelica_sim_meta::driver::StartImports> {
        let n = u32_at(p)? as usize;
        let time = f64_at(p)?;
        let name_len = u32_at(p)? as usize;
        let file = alloc::string::String::from_utf8_lossy(bytes.get(*p..*p + name_len)?).into_owned();
        *p += name_len;
        let mut values = Vec::with_capacity(n);
        for _ in 0..n {
            values.push((u32_at(p)?, f64_at(p)?));
        }
        Some(openmodelica_sim_meta::driver::StartImports { file, time, values })
    };
    let strings = |p: &mut usize| -> Option<Vec<(u32, alloc::string::String)>> {
        let n = u32_at(p)? as usize;
        let mut out = Vec::with_capacity(n);
        for _ in 0..n {
            let off = u32_at(p)?;
            let len = u32_at(p)? as usize;
            let s = alloc::string::String::from_utf8_lossy(bytes.get(*p..*p + len)?).into_owned();
            *p += len;
            out.push((off, s));
        }
        Some(out)
    };
    match (group(&mut p), group(&mut p)) {
        (Some(params), Some(starts)) => {
            openmodelica_sim_meta::driver::set_param_overrides(params, starts, strings(&mut p).unwrap_or_default());
            openmodelica_sim_meta::driver::set_start_imports(imports(&mut p));
            0
        }
        _ => -1,
    }
}

/// Start a resumable in-wasm run. `meta_ptr`/`meta_len` point at the model's
/// encoded [`SimMeta`] blob (its `om_meta` segment); `fn_base` is the first table
/// slot the host populated with the model's exports (in `N_SLOTS` order);
/// `present_mask` bit `s` is set iff slot `s` holds a real funcref. Returns 0 on
/// success, <0 on error.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_start(meta_ptr: u32, meta_len: u32, fn_base: u32, present_mask: u64) -> i32 {
    // Any prior session is dropped (frees its buffers) before starting a new one.
    *session() = None;
    *result_stream() = None;
    crate::reset_lin_solves();
    crate::reset_ls_failures();
    crate::nls::set_no_throw_div_zero(false); // C's `initializeModel`
    crate::reset_stats();
    crate::sundials::reset_caches();

    let bytes = unsafe { core::slice::from_raw_parts(meta_ptr as *const u8, meta_len as usize) };
    let mut model = match openmodelica_sim_meta::decode(bytes) {
        Ok(m) => m,
        Err(_) => return -1,
    };
    // A session always has a host, which renders `read_experiment`'s notices from
    // the same flags; saying it again here would double every line.
    driver::set_log_sink(|_, _, _| {});
    simflags::with_flags(|f| model.apply_flags(f));
    driver::set_log_sink(crate::omclog::sink);

    crate::nls::rt_set_step_size(model.step_size());
    crate::files::set_prefix(&model.prefix);
    crate::nls::set_diag(&model.nls_vars);
    // `-lv=LOG_NLS` names the iteration variables; only the metadata has them.
    crate::nls::set_var_names(model.nls_vars.iter().map(|s| (s.eq_index, s.names.clone())).collect());

    driver::set_clock(now_ms_hook);
    // This session runs its own start/advance/finish instead of `drive`, so the
    // run's clocks start (and, in `finish`, stop) here.
    use openmodelica_sim_meta::rtclock;
    rtclock::reset(
        openmodelica_sim_meta::omclog::active(openmodelica_sim_meta::omclog::STATS)
            || openmodelica_sim_meta::omclog::active(openmodelica_sim_meta::omclog::STATS_V)
            // `+profiling` is C's other `measure_time_flag` source, as in `drive`.
            || model.prof.is_some(),
    );
    rtclock::tick(rtclock::TOTAL);
    rtclock::tick(rtclock::PREINIT);
    openmodelica_solvers::sysstat::enable(openmodelica_sim_meta::omclog::active(
        openmodelica_sim_meta::omclog::STATS_V,
    ));
    // `+profiling`: the traces are collected here and rendered by the host, which
    // is the side that knows what the result file it reports on ended up being
    // (`profiling::snapshot` / `rt_sim_prof_ptr`).
    openmodelica_sim_meta::profiling::start(&mut InWasmEngine { fn_base, present_mask }, &model);
    driver::set_cancel_hook(cancel_hook);
    driver::set_init_done_hook(init_done_hook);
    openmodelica_sim_meta::files::set_writer(|path, bytes| {
        crate::files::write_file(path, &alloc::string::String::from_utf8_lossy(bytes));
        true
    });
    driver::set_no_throw_hook(|v| unsafe { rt_host_set_no_throw(v as i32) });

    let mut engine = InWasmEngine { fn_base, present_mask };
    let sim_data = crate::rt_sim_data_new(model.layout.total);
    let n_reals = model.layout.n_row_total();

    let method = model.method.clone();
    let driver = match driver::make_driver(&mut engine, &model, sim_data, method.as_str()) {
        Ok((d, _label)) => d,
        Err(_) => return -2,
    };

    let rc = open_result_stream(&mut engine, &model, sim_data);
    if rc != 0 {
        return rc;
    }

    *session() = Some(Session {
        engine,
        driver,
        model,
        sim_data,
        n_reals,
        finished: false,
        rows: Vec::new(),
        rows_written: 0,
        params: Vec::new(),
        stats: SolveStats::default(),
        lin: Vec::new(),
        prof: Vec::new(),
        first_row: Vec::new(),
    });
    // What C's `NLS_USERDATA` carries as `DATA*`: the run's model and `SimData`,
    // for the analyses the nonlinear solver runs from inside a solve.
    #[cfg(sundials)]
    if let Some(s) = session().as_ref() {
        crate::model_ctx::set_context(&s.model, s.sim_data);
    }
    0
}

/// Integrate for about `budget_ms` of wall-clock (`+inf` runs to completion),
/// then return. Status: 0 running, 1 done, 2 terminated, 3 cancelled, <0 error.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_advance(budget_ms: f64) -> i32 {
    let Some(s) = session().as_mut() else {
        return -1;
    };
    if s.finished {
        return 1;
    }
    let mut adv = {
        let Session { engine, driver, model, .. } = &mut *s;
        driver.advance(engine, model, budget_ms)
    };
    // C's `performSimulation` catch, here rather than in the host loop: only
    // `advance` knows where the step boundary is.
    while let Err(err) = adv {
        let Session { engine, driver, model, .. } = &mut *s;
        if !driver::is_model_throw(err) || !driver.retry_step(engine, model).unwrap_or(false) {
            return -2;
        }
        adv = driver.advance(engine, model, budget_ms);
    }
    match adv {
        Ok(Advance::Running) => 0,
        Ok(done @ (Advance::Done | Advance::Terminated)) => {
            finish(s);
            if matches!(done, Advance::Terminated) { 2 } else { 1 }
        }
        Ok(Advance::Cancelled) => {
            let _ = driver::finalize_run(&mut s.engine, &s.model, s.sim_data);
            3
        }
        Err(_) => -2,
    }
}

/// Capture rows, stats and parameter values after the run completes.
fn finish(s: &mut Session) {
    s.stats = SolveStats::default();
    s.driver.fill_stats(&s.model, &mut s.stats);
    s.rows = s.driver.take_rows();
    let at = s.driver.terminal_time();
    let _ = driver::emit_terminal_row(
        &mut s.engine,
        &mut s.rows,
        s.sim_data,
        &s.model.layout,
        s.n_reals,
        at,
    );
    if let Ok(Some(f)) = openmodelica_sim_meta::linearize::linearize(&mut s.engine, &s.model, s.sim_data) {
        s.lin.extend_from_slice(f.name.as_bytes());
        s.lin.push(0);
        s.lin.extend_from_slice(f.content.as_bytes());
    }
    s.params = driver::finalize_run(&mut s.engine, &s.model, s.sim_data).unwrap_or_default();
    use openmodelica_sim_meta::rtclock;
    openmodelica_sim_meta::parmod::finish();
    driver::finish_rows(&mut s.rows);
    if let Some(st) = result_stream().take() {
        s.first_row = st.first_row_blob();
        s.rows_written = st.n_rows() as u32;
    }
    rtclock::accumulate(rtclock::TOTAL);
    openmodelica_sim_meta::profiling::end_of_run(&mut s.engine);
    s.prof = openmodelica_sim_meta::profiling::snapshot();
    (s.stats.timers, s.stats.tcalls) = rtclock::snapshot();
    s.finished = true;
}

/// Drop the active session (frees its buffers). Safe with no session.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_free() {
    *session() = None;
    if let Some(mut st) = result_stream().take() {
        st.finish();
    }
}

// Result accessors — valid only once `rt_sim_advance` returned done/terminated
// and until `rt_sim_free`. Pointers are linear-memory offsets into `rt_alloc`'d
// buffers the host reads directly.

#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_rows_ptr() -> u32 {
    session().as_ref().map_or(0, |s| s.rows.as_ptr() as u32)
}
/// Number of `f64` elements in the rows buffer (`n_rows * n_reals`).
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_rows_len() -> u32 {
    session().as_ref().map_or(0, |s| s.rows.len() as u32)
}
/// Columns per row (`SimLayout::n_row_total`).
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_n_reals() -> u32 {
    session().as_ref().map_or(0, |s| s.n_reals)
}
/// Rows the run produced, whether streamed to the result file or kept in the buffer.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_n_rows() -> u32 {
    session().as_ref().map_or(0, |s| s.rows_written + (s.rows.len() as u32) / s.n_reals.max(1))
}
/// The initial result row (`result::decode_first_row`); empty when the run was
/// given no result file to write.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_first_row_ptr() -> u32 {
    session().as_ref().map_or(0, |s| s.first_row.as_ptr() as u32)
}
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_first_row_len() -> u32 {
    session().as_ref().map_or(0, |s| s.first_row.len() as u32)
}
/// `-l`'s linearized model as `<file name>\0<content>`; the host writes the file
/// (this runtime's WASI is the browser's VFS).
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_lin_ptr() -> u32 {
    session().as_ref().map_or(0, |s| s.lin.as_ptr() as u32)
}
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_lin_len() -> u32 {
    session().as_ref().map_or(0, |s| s.lin.len() as u32)
}

/// `+profiling`'s collected state, valid once the run is done.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_prof_ptr() -> u32 {
    session().as_ref().map_or(0, |s| s.prof.as_ptr() as u32)
}

#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_prof_len() -> u32 {
    session().as_ref().map_or(0, |s| s.prof.len() as u32)
}

#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_params_ptr() -> u32 {
    session().as_ref().map_or(0, |s| s.params.as_ptr() as u32)
}
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_params_len() -> u32 {
    session().as_ref().map_or(0, |s| s.params.len() as u32)
}

// Solver statistics, for the host bench line (steps, evals, events).
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_stat(which: u32) -> u64 {
    session().as_ref().map_or(0, |s| match which {
        0 => s.stats.steps,
        1 => s.stats.res_evals,
        2 => s.stats.jac_evals,
        3 => s.stats.err_test_fails,
        4 => s.stats.conv_test_fails,
        5 => s.stats.state_events,
        6 => s.stats.time_events,
        7 => crate::lin_solves(),
        // The `LOG_STATS` timers: seconds as `f64` bits, then the call counts.
        n => {
            use openmodelica_sim_meta::rtclock::{N, STAT_SLOT_BASE};
            match (n - STAT_SLOT_BASE) as usize {
                i if i < N => s.stats.timers[i].to_bits(),
                i if i < 2 * N => s.stats.tcalls[i - N],
                _ => 0,
            }
        }
    })
}
