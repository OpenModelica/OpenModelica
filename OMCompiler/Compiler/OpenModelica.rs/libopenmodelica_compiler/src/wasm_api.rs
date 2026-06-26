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
}

// The compiler emits stdout/stderr in fragments (a `print` call need not end on
// a line boundary), but `console.log`/`console.error` each render one line. Hold
// a per-stream buffer and flush only complete lines, so multi-call output lands
// on one console line instead of many.
thread_local! {
    static OUT_BUF: RefCell<String> = const { RefCell::new(String::new()) };
    static ERR_BUF: RefCell<String> = const { RefCell::new(String::new()) };
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
        console_error(&format!("{info}"));
    }));
    // stdout/stderr → console. First binding wins, so this is a no-op if a
    // previous omc_init already bound them.
    metamodelica::setStdoutHook(stdout_sink);
    metamodelica::setStderrHook(stderr_sink);

    // Route `plot(...)` through the in-page charton renderer instead of spawning
    // the external OMPlot process (which does not exist on wasm).
    crate::wasm_plot::register();

    let args = [ArcStr::from("--simCodeTarget=wasm-jit")];
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

/// Evaluate one interactive command and return its reply — the same string the
/// `--interactive=zmq` server returns for a request. Evaluation errors and
/// panics are returned as `"Error: …"` text rather than thrown, so a REPL can
/// keep running.
#[wasm_bindgen]
pub fn omc_eval(command: &str) -> String {
    match catch_unwind(AssertUnwindSafe(|| capi::eval(ArcStr::from(command)))) {
        Ok(Ok((_keep, reply))) => reply.to_string(),
        Ok(Err(e)) => format!("Error: {e}"),
        Err(_) => "Error: evaluation panicked".to_owned(),
    }
}
