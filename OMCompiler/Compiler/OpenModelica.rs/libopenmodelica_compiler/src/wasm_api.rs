//! JavaScript bindings for a wasm build of the compiler (wasm-bindgen). Exposes
//! the same string-to-string command interface the interactive ZeroMQ server
//! uses: call [`omc_init`] once to start the runtime, then [`omc_eval`] to
//! evaluate each interactive command and get its reply. Counterpart of the
//! native C-ABI `omc_compiler_init`/`omc_compiler_eval` in `lib.rs`.

use std::cell::RefCell;
use std::panic::{AssertUnwindSafe, catch_unwind};

use arcstr::ArcStr;
use wasm_bindgen::prelude::*;

use openmodelica_backend_main::capi;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = console, js_name = log)]
    fn console_log(s: &str);
    #[wasm_bindgen(js_namespace = console, js_name = error)]
    fn console_error(s: &str);
    // Wall-clock (ms) for the simulation chunk budget; wasm has no `Instant`.
    #[wasm_bindgen(js_namespace = performance, js_name = now)]
    fn perf_now() -> f64;
    // Host cancel poll (control block index 0, a cross-thread `SharedArrayBuffer`
    // flag, OMEdit-wasm). Only called after `omc_enable_cancel_poll`, so the
    // global need not exist otherwise.
    #[wasm_bindgen(js_namespace = globalThis, js_name = __omcPollCancel)]
    fn omc_poll_cancel_js() -> i32;
    // Host progress sink (control block indices 1/2). Only called after
    // `omc_enable_progress_sink`, so the global need not exist otherwise.
    #[wasm_bindgen(js_namespace = globalThis, js_name = __omcReportProgress)]
    fn omc_report_progress_js(permille: i32, phase: i32);
}

fn wall_ms() -> f64 {
    perf_now()
}

fn poll_cancel() -> bool {
    omc_poll_cancel_js() != 0
}

fn report_progress(permille: i32, phase: i32) {
    omc_report_progress_js(permille, phase);
}

/// Enable the cross-thread cancel poll for any blocking omc call (simulate, and
/// the frontend/loader/backend chokepoints). The worker must define
/// `globalThis.__omcPollCancel` first (OMEdit-wasm); the standalone simulator
/// cancels via `omc_sim_free` instead and doesn't call this.
#[wasm_bindgen]
pub fn omc_enable_cancel_poll() {
    metamodelica::cancel::set_cancel_poll(poll_cancel);
}

/// Enable live progress reporting out of a blocking omc call: the runtime writes
/// permille + phase into the shared control block via `globalThis.__omcReportProgress`
/// (which the worker defines). The UI thread reads the block on its own timer.
#[wasm_bindgen]
pub fn omc_enable_progress_sink() {
    metamodelica::cancel::set_progress_sink(report_progress);
}

// The compiler emits stdout/stderr in fragments (a `print` call need not end on
// a line boundary), but `console.log`/`console.error` each render one line. Hold
// a per-stream buffer and flush only complete lines, so multi-call output lands
// on one console line instead of many.
thread_local! {
    static OUT_BUF: RefCell<String> = const { RefCell::new(String::new()) };
    static ERR_BUF: RefCell<String> = const { RefCell::new(String::new()) };
    /// The last panic message the hook saw, so [`omc_eval`] can report the real
    /// reason (location + message) instead of a bare "evaluation panicked".
    static LAST_PANIC: RefCell<Option<String>> = const { RefCell::new(None) };
}

fn buffer_lines(buf: &'static std::thread::LocalKey<RefCell<String>>, s: &str, emit: fn(&str)) {
    buf.with(|b| {
        let mut b = b.borrow_mut();
        b.push_str(s);
        while let Some(i) = b.find('\n') {
            // Emit the line without its trailing '\n' (console adds one).
            emit(&b[..i]);
            b.drain(..=i);
        }
    });
}

fn stdout_sink(s: &str) {
    buffer_lines(&OUT_BUF, s, console_log);
}

fn stderr_sink(s: &str) {
    buffer_lines(&ERR_BUF, s, console_error);
}

/// Seed an environment variable in the wasm in-process environment (there is no
/// OS environment on wasm). Call before [`omc_init`] to point the runtime at its
/// install dir, e.g. `omc_set_env("OPENMODELICAHOME", "/")`.
#[wasm_bindgen]
pub fn omc_set_env(name: &str, value: &str) {
    openmodelica_util::System::setEnv(ArcStr::from(name), ArcStr::from(value), true);
}

/// Initialise the compiler runtime. Returns `true` on success. Must be called
/// once before [`omc_eval`]. Mirrors `omc_compiler_init`, but additionally:
///   * routes the compiler's stdout/stderr (and Rust panics) to the JS console,
///   * defaults the code-generation target to `wasm-jit` — the only simCode
///     target usable in-browser (the C/Cpp/FMU targets need an external
///     toolchain and are unavailable here).
#[wasm_bindgen]
pub fn omc_init() -> bool {
    // Panics → console.error (instead of the default unwinding into a wasm trap
    // with no message). Installed once; the hook is process-global.
    std::panic::set_hook(Box::new(|info| {
        let msg = format!("{info}");
        console_error(&msg);
        LAST_PANIC.with(|p| *p.borrow_mut() = Some(msg));
    }));
    // stdout/stderr → console. First binding wins, so this is a no-op if a
    // previous omc_init already bound them.
    metamodelica::setStdoutHook(stdout_sink);
    metamodelica::setStderrHook(stderr_sink);

    // Route `plot(...)` through the in-page charton renderer instead of spawning
    // the external OMPlot process (which does not exist on wasm).
    crate::wasm_plot::register();

    // wasm has no `Instant`; give the sim driver a wall-clock for the chunk budget.
    openmodelica_codegen_wasm_jit::CodegenWasmJit::set_clock(wall_ms);

    // `-d=-buildExternalLibs`: never try to *build* an external "C" library's
    // Resources/BuildProjects (autotools) — impossible in-browser, and it would
    // abort simcode elaboration of table functions. External functions are
    // provided at run time by the ModelicaStandardTables WASI side module (see
    // `sim_runtime_wasmer::define_external_imports`).
    let args = [
        ArcStr::from("--simCodeTarget=wasm-jit"),
        ArcStr::from("-d=-buildExternalLibs"),
    ];
    matches!(catch_unwind(AssertUnwindSafe(|| capi::init(&args))), Ok(Ok(())))
}

// ── WASI preview1 file surface for the host ───────────────────────────────────
//
// The host reads/lists the worker-owned store through a `wasi_snapshot_preview1`
// view (`openmodelica_wasi::wasi::WasiCtx`) — the same surface the standalone
// wasm-jit command module speaks — so the backing store is swappable. A read is
// the spec flow `path_open` → `fd_read` → `fd_close`; listing/stat are by path.

thread_local! {
    /// The host's WASI view of the store. cwd `"/"` so absolute paths and the
    /// store's keys agree (matching `openmodelica_wasi::normalize`'s default cwd).
    static WASI: RefCell<openmodelica_wasi::wasi::WasiCtx> =
        RefCell::new(openmodelica_wasi::wasi::WasiCtx::new("/", vec!["omc".to_string()]));
}

/// preview1 `path_open` (read-only) of absolute key `path`. Returns the new fd,
/// or `-1` if the file is absent.
#[wasm_bindgen]
pub fn wasi_path_open(path: &str) -> i32 {
    WASI.with(|w| match w.borrow_mut().open_read(path) {
        Some(fd) => fd as i32,
        None => -1,
    })
}

/// preview1 `fd_read` (whole file) of an fd from [`wasi_path_open`], or `None`.
#[wasm_bindgen]
pub fn wasi_fd_read(fd: u32) -> Option<Vec<u8>> {
    WASI.with(|w| w.borrow().read_all(fd))
}

/// preview1 `fd_close`.
#[wasm_bindgen]
pub fn wasi_fd_close(fd: u32) {
    WASI.with(|w| {
        w.borrow_mut().close(fd);
    });
}

/// preview1 `path_filestat_get`'s `size` for absolute key `path`, or `-1` if
/// absent (a JS number; sizes here are small config/result files).
#[wasm_bindgen]
pub fn wasi_path_filestat_get(path: &str) -> f64 {
    openmodelica_wasi::wasi::stat_size(path).map(|n| n as f64).unwrap_or(-1.0)
}

/// List directory `path` (absolute; `"/"` is the root) as an array of
/// `{ name: string, isDir: bool }`. The worker-side of preview1 `fd_readdir` for
/// a JS caller (which cannot pass guest dirent buffers): drives the engine's
/// `QDir` enumeration of worker-owned paths.
#[wasm_bindgen]
pub fn wasi_readdir(path: &str) -> JsValue {
    let arr = js_sys::Array::new();
    for e in openmodelica_wasi::wasi::readdir(path) {
        let item = js_sys::Object::new();
        let _ = js_sys::Reflect::set(&item, &JsValue::from_str("name"), &JsValue::from_str(&e.name));
        let _ = js_sys::Reflect::set(&item, &JsValue::from_str("isDir"), &JsValue::from_bool(e.is_dir));
        arr.push(&item);
    }
    arr.into()
}

/// Create/overwrite absolute key `path` with `bytes` (preview1
/// `path_open`(O_CREAT|O_TRUNC) → `fd_write` → `fd_close` collapsed). Lets the JS
/// host stage downloaded library/result files into the store.
#[wasm_bindgen]
pub fn wasi_write_file(path: &str, bytes: &[u8]) {
    openmodelica_wasi::write(path, bytes.to_vec());
}

/// Drain the files the last command tried to download but did not find in the
/// VFS, as an array of `{ urls: string[], filename: string }`. `omc_eval` is
/// synchronous, so it cannot fetch over the network itself; instead the JS host
/// fetches each pending file (the browser streams it for download progress),
/// stages the bytes with [`wasi_write_file`], and re-runs the command, which then
/// finds them in the VFS. See `openmodelica_script_util::Curl` (Curl_wasm).
#[wasm_bindgen]
pub fn omc_take_pending_downloads() -> JsValue {
    let arr = js_sys::Array::new();
    for (urls, filename) in openmodelica_script_util::Curl::take_pending_downloads() {
        let item = js_sys::Object::new();
        let mirrors = js_sys::Array::new();
        for u in &urls {
            mirrors.push(&JsValue::from_str(u));
        }
        let _ = js_sys::Reflect::set(&item, &JsValue::from_str("urls"), &mirrors);
        let _ = js_sys::Reflect::set(
            &item,
            &JsValue::from_str("filename"),
            &JsValue::from_str(&filename),
        );
        arr.push(&item);
    }
    arr.into()
}

/// Drain the plot commands the last `omc_eval` recorded, as an array of string
/// arrays (each the 18 `PlotCallback` args in ABI order, result file at index 0).
/// A host with its own renderer (OMNotebook-qt) drains this, then reads each
/// result file from the VFS with [`wasi_path_open`]+[`wasi_fd_read`] and draws it.
#[wasm_bindgen]
pub fn omc_take_plot_commands() -> JsValue {
    let arr = js_sys::Array::new();
    for cmd in crate::wasm_plot::take_plot_commands() {
        let args = js_sys::Array::new();
        for a in &cmd {
            args.push(&JsValue::from_str(a));
        }
        arr.push(&args);
    }
    arr.into()
}

/// Unzip `data` into the VFS, mounting each entry under `mount` (e.g.
/// `mount="/lib"`, entry `Modelica 4.1.0/package.mo` → `/lib/Modelica 4.1.0/
/// package.mo`). One fetch + this call stages a whole Modelica library; point
/// MODELICAPATH at `mount` and `loadModel`. Returns the number of files written
/// or an error string.
#[wasm_bindgen]
pub fn omc_vfs_load_zip(mount: &str, data: &[u8]) -> Result<usize, String> {
    let reader = std::io::Cursor::new(data);
    let mut zip = zip::ZipArchive::new(reader).map_err(|e| format!("zip open: {e}"))?;
    let mut count = 0usize;
    for i in 0..zip.len() {
        let mut entry = zip.by_index(i).map_err(|e| format!("zip entry {i}: {e}"))?;
        if !entry.is_file() {
            continue;
        }
        // `enclosed_name` strips any `..`/absolute components (zip-slip safe).
        let Some(name) = entry.enclosed_name() else { continue };
        let path = format!("{}/{}", mount.trim_end_matches('/'), name.to_string_lossy());
        let mut buf = Vec::with_capacity(entry.size() as usize);
        std::io::Read::read_to_end(&mut entry, &mut buf).map_err(|e| format!("read {name:?}: {e}"))?;
        openmodelica_wasi::write(&path, buf);
        count += 1;
    }
    Ok(count)
}

/// Dispatch one typed OMEdit scripting call: the bridge posts
/// `{"fn": …, "args": […]}` and gets back `{"result": …}` or `{"error": …}`.
/// Present only with the `scripting_api` feature (the OMEdit C-ABI crate).
#[cfg(feature = "scripting_api")]
#[wasm_bindgen]
pub fn omc_abi(request: &str) -> String {
    openmodelica_scripting_qt::scripting_api_qt::omc_abi_dispatch(request)
}

// ── Direct simulation-result access (no intermediate result file) ─────────────
//
// After a `simulate(...)`, the wasm-jit runtime keeps the finished run's signals
// in memory. These read them straight out — the web simulator plots from these
// instead of parsing a `.mat`/`_init.xml`. Index order matches between
// [`omc_sim_series`] and [`omc_sim_column`].

/// Metadata for the last run's signals (excluding `time`): an array of
/// `{ name, comment, constant, alias }`. `constant` marks parameters/constants and
/// signals that never change; `alias` marks a signal that reads the *same stored
/// column* as an earlier one (the `.mat`'s `dataInfo` aliasing — distinct columns
/// are distinct signals). The plot shows only `!constant && !alias`. Empty if no run.
#[wasm_bindgen]
pub fn omc_sim_series() -> JsValue {
    let arr = js_sys::Array::new();
    openmodelica_codegen_wasm_jit::CodegenWasmJit::with_last_sim(|sim| {
        for s in &sim.series {
            let item = js_sys::Object::new();
            let _ = js_sys::Reflect::set(&item, &JsValue::from_str("name"), &JsValue::from_str(&s.name));
            let _ = js_sys::Reflect::set(&item, &JsValue::from_str("comment"), &JsValue::from_str(&s.comment));
            let _ = js_sys::Reflect::set(&item, &JsValue::from_str("unit"), &JsValue::from_str(&s.unit));
            let _ = js_sys::Reflect::set(&item, &JsValue::from_str("constant"), &JsValue::from_bool(s.constant));
            let _ = js_sys::Reflect::set(&item, &JsValue::from_str("alias"), &JsValue::from_bool(s.alias));
            arr.push(&item);
        }
    });
    arr.into()
}

/// The last run's editable initial conditions: an array of `{ name, comment,
/// unit, value }`, plus `enumNames` for an enumeration (its value is the 1-based
/// index). Feed edits back via `-override=name=value` on the next simulate.
#[wasm_bindgen]
pub fn omc_sim_parameters() -> JsValue {
    let arr = js_sys::Array::new();
    openmodelica_codegen_wasm_jit::CodegenWasmJit::with_last_sim(|sim| {
        for p in &sim.params {
            let item = js_sys::Object::new();
            let _ = js_sys::Reflect::set(&item, &JsValue::from_str("name"), &JsValue::from_str(&p.name));
            let _ = js_sys::Reflect::set(&item, &JsValue::from_str("comment"), &JsValue::from_str(&p.comment));
            let _ = js_sys::Reflect::set(&item, &JsValue::from_str("unit"), &JsValue::from_str(&p.unit));
            let _ = js_sys::Reflect::set(&item, &JsValue::from_str("value"), &JsValue::from_f64(p.value));
            if !p.enum_names.is_empty() {
                let names = js_sys::Array::new();
                for n in &p.enum_names {
                    names.push(&JsValue::from_str(n));
                }
                let _ = js_sys::Reflect::set(&item, &JsValue::from_str("enumNames"), &names);
            }
            arr.push(&item);
        }
    });
    arr.into()
}

/// `{ model, start, stop, rows }` for the last run, or `null` if none.
#[wasm_bindgen]
pub fn omc_sim_info() -> JsValue {
    openmodelica_codegen_wasm_jit::CodegenWasmJit::with_last_sim(|sim| {
        let o = js_sys::Object::new();
        let _ = js_sys::Reflect::set(&o, &JsValue::from_str("model"), &JsValue::from_str(&sim.model_name));
        let _ = js_sys::Reflect::set(&o, &JsValue::from_str("start"), &JsValue::from_f64(sim.start_time));
        let _ = js_sys::Reflect::set(&o, &JsValue::from_str("stop"), &JsValue::from_f64(sim.stop_time));
        let _ = js_sys::Reflect::set(&o, &JsValue::from_str("rows"), &JsValue::from_f64(sim.time.len() as f64));
        o.into()
    })
    .unwrap_or(JsValue::NULL)
}

/// The independent `time` column of the last run as a `Float64Array`, or `None`.
#[wasm_bindgen]
pub fn omc_sim_time() -> Option<Vec<f64>> {
    openmodelica_codegen_wasm_jit::CodegenWasmJit::with_last_sim(|sim| sim.time.clone())
}

/// The values of series `index` (as in [`omc_sim_series`]) as a `Float64Array`.
/// A time-invariant signal returns a length-1 array. `None` if out of range /
/// no run.
#[wasm_bindgen]
pub fn omc_sim_column(index: usize) -> Option<Vec<f64>> {
    openmodelica_codegen_wasm_jit::CodegenWasmJit::with_last_sim(|sim| {
        sim.series.get(index).map(|s| s.values.clone())
    })
    .flatten()
}

/// Evaluate one interactive command and return its reply — the same string the
/// `--interactive=zmq` server returns for a request. Evaluation errors and
/// panics are returned as `"Error: …"` text rather than thrown, so a REPL can
/// keep running.
#[wasm_bindgen]
pub fn omc_eval(command: &str) -> String {
    LAST_PANIC.with(|p| *p.borrow_mut() = None);
    match catch_unwind(AssertUnwindSafe(|| capi::eval(ArcStr::from(command)))) {
        Ok(Ok((_keep, reply))) => reply.to_string(),
        Ok(Err(e)) => format!("Error: {e}"),
        Err(_) => match LAST_PANIC.with(|p| p.borrow_mut().take()) {
            Some(msg) => format!("Error: evaluation panicked: {msg}"),
            None => "Error: evaluation panicked".to_owned(),
        },
    }
}

/// `simulate(...)` without the string command's O(program) env build; errors returned as `"Error: …"`.
#[wasm_bindgen]
pub fn omc_simulate(
    class_name: &str,
    stop_time: f64,
    number_of_intervals: i32,
    tolerance: f64,
    method: &str,
    simflags: &str,
) -> String {
    LAST_PANIC.with(|p| *p.borrow_mut() = None);
    let run = || {
        capi::simulate(
            ArcStr::from(class_name),
            stop_time,
            number_of_intervals,
            tolerance,
            ArcStr::from(method),
            ArcStr::from(simflags),
        )
    };
    match catch_unwind(AssertUnwindSafe(run)) {
        Ok(reply) => reply.to_string(),
        Err(_) => match LAST_PANIC.with(|p| p.borrow_mut().take()) {
            Some(msg) => format!("Error: simulation panicked: {msg}"),
            None => "Error: simulation panicked".to_owned(),
        },
    }
}

// --- resumable / cancellable simulation --------------------------------------
// The blocking `omc_simulate` can't be interrupted, and killing the worker loses the
// loaded library + warmed JIT. Instead the worker builds the model then drives the
// run in time-bounded chunks (`omc_sim_start`/`omc_sim_advance`/`omc_sim_free`),
// draining a cancel between chunks; results reach the page via the `omc_sim_*`
// getters. See HANDOFF-sim-cancel.md.

/// Start a resumable run of a model already built by `buildModel` (keyed by its
/// `prefix`; `result_file` is where the `.mat` goes). `false` on failure — read
/// `getErrorString()`.
#[wasm_bindgen]
pub fn omc_sim_start(prefix: &str, result_file: &str, simflags: &str) -> bool {
    LAST_PANIC.with(|p| *p.borrow_mut() = None);
    let run = || openmodelica_codegen_wasm_jit::CodegenWasmJit::sim_start(prefix, result_file, simflags);
    matches!(catch_unwind(AssertUnwindSafe(run)), Ok(Ok(())))
}

/// Integrate for about `budget_ms` of wall-clock, then return so the worker can
/// yield. Codes: `0` running (call again), `1` done, `2` terminated (`terminate()`),
/// `3` cancelled, `-1` error (read `getErrorString()`). On `1`/`2` the results are
/// ready via the `omc_sim_*` getters and the `.mat` is written; on `3`/`-1`/`1`/`2`
/// the session is freed.
#[wasm_bindgen]
pub fn omc_sim_advance(budget_ms: f64) -> i32 {
    use openmodelica_codegen_wasm_jit::CodegenWasmJit::SimStatus;
    LAST_PANIC.with(|p| *p.borrow_mut() = None);
    let run = || openmodelica_codegen_wasm_jit::CodegenWasmJit::sim_advance(budget_ms);
    match catch_unwind(AssertUnwindSafe(run)) {
        Ok(Ok(SimStatus::Running)) => 0,
        Ok(Ok(SimStatus::Done)) => 1,
        Ok(Ok(SimStatus::Terminated)) => 2,
        Ok(Ok(SimStatus::Cancelled)) => 3,
        _ => -1,
    }
}

/// Drop the active simulation session (freeing its external objects). Used by the
/// worker's Cancel path; safe with no active session.
#[wasm_bindgen]
pub fn omc_sim_free() {
    let _ = catch_unwind(AssertUnwindSafe(openmodelica_codegen_wasm_jit::CodegenWasmJit::sim_free));
}

/// Request cancellation of the running simulation (mirrors the native C ABI). The
/// simulator cancels via `omc_sim_free` instead; this is used by the SAB cancel path.
#[wasm_bindgen]
pub fn omc_request_cancel() {
    openmodelica_codegen_wasm_jit::CodegenWasmJit::request_cancel();
}
