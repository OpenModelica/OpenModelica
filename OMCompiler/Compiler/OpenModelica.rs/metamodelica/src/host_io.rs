//! Host stdout/stderr hooks and the `print` builtin.

use arcstr::ArcStr;

/// MetaModelica `print` builtin: `fputs(s, stdout)`, like the C runtime.
pub fn print(s: ArcStr) {
    let _ = host_print(s.as_str());
}

// Host output hooks. The native build writes to C's stdout/stderr; on wasm
// there is no OS console, so the JS host binds these (console.log /
// console.error) at startup. Mirrors the `ASSERT_HOOK` pattern.
static STDOUT_HOOK: std::sync::OnceLock<fn(&str)> = std::sync::OnceLock::new();
static STDERR_HOOK: std::sync::OnceLock<fn(&str)> = std::sync::OnceLock::new();

/// Bind the stdout sink used by [`print`] (first binding wins).
pub fn setStdoutHook(hook: fn(&str)) {
    let _ = STDOUT_HOOK.set(hook);
}

/// Bind the stderr sink used by [`host_eprint`] (first binding wins).
pub fn setStderrHook(hook: fn(&str)) {
    let _ = STDERR_HOOK.set(hook);
}

/// Write `s` to C's `stdout` FILE ([`openmodelica_wasi::stdio`]), or the bound
/// stdout hook on wasm. False if the write failed.
pub fn host_print(s: &str) -> bool {
    #[cfg(target_arch = "wasm32")]
    {
        if let Some(hook) = STDOUT_HOOK.get() {
            hook(s);
        }
        return true;
    }
    #[cfg(not(target_arch = "wasm32"))]
    return openmodelica_wasi::stdio::write(1, s.as_bytes());
}

/// Write `s` to C's `stderr` FILE, or the bound stderr hook on wasm. Use instead
/// of a bare `eprintln!` wherever the output must reach the JS console on wasm
/// (e.g. the `showErrorMessages` echo).
pub fn host_eprint(s: &str) -> bool {
    #[cfg(target_arch = "wasm32")]
    {
        if let Some(hook) = STDERR_HOOK.get() {
            hook(s);
        }
        return true;
    }
    #[cfg(not(target_arch = "wasm32"))]
    return openmodelica_wasi::stdio::write(2, s.as_bytes());
}

/// `fflush(NULL)`, and the same for Rust's own stdout/stderr.
pub fn host_flush() {
    #[cfg(not(target_arch = "wasm32"))]
    {
        use std::io::Write;
        let _ = std::io::stdout().flush();
        let _ = std::io::stderr().flush();
        openmodelica_wasi::stdio::flush();
    }
}

#[cfg(all(test, target_os = "linux"))]
mod tests {
    unsafe extern "C" {
        static mut stdout: *mut libc::FILE;
    }

    /// OMEdit `freopen`s C's `stdout` to show what omc prints. In a Windows GUI
    /// app that leaves the Win32 handle Rust's `std::io::stdout` writes to
    /// alone, so swap the FILE without touching fd 1 here.
    #[test]
    fn print_goes_to_c_stdout() {
        let path = std::env::temp_dir().join(format!("metamodelica-print-{}.txt", std::process::id()));
        let cpath = std::ffi::CString::new(path.to_str().unwrap()).unwrap();
        unsafe {
            let f = libc::fopen(cpath.as_ptr(), c"w".as_ptr());
            assert!(!f.is_null());
            let saved = stdout;
            libc::fflush(saved);
            stdout = f;
            super::print(arcstr::literal!("Number of classes to check: 3\n"));
            stdout = saved;
            libc::fclose(f);
        }
        let text = std::fs::read_to_string(&path).unwrap();
        let _ = std::fs::remove_file(&path);
        assert_eq!(text, "Number of classes to check: 3\n");
    }
}
