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

/// Write one file into the in-memory VFS at `path`. Lets the JS host stage files
/// the compiler will read — e.g. download a Modelica library file-by-file (a
/// manifest of paths, each fetched and put here) before `loadModel`.
#[wasm_bindgen]
pub fn omc_vfs_put(path: &str, bytes: &[u8]) {
    openmodelica_vfs::write(path, bytes.to_vec());
}

/// Read a file back out of the VFS (e.g. a simulation result the run wrote), or
/// `None` if absent.
#[wasm_bindgen]
pub fn omc_vfs_get(path: &str) -> Option<Vec<u8>> {
    openmodelica_vfs::read(path)
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
        openmodelica_vfs::write(&path, buf);
        count += 1;
    }
    Ok(count)
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
