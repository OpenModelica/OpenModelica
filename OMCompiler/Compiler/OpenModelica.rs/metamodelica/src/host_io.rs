//! Host stdout/stderr hooks and the `print` builtin.

use arcstr::ArcStr;

/// MetaModelica `print` builtin: writes the argument to stdout *without*
/// adding a trailing newline (matches the C runtime's `print`). This exists
/// alongside the inline `println!` lowering used at direct call sites so that
/// passing `print` as a value (e.g. `List.map_0(strs, print)`) resolves to a
/// real function item that can be wrapped by `fnptr!`. The codegen prefers the
/// inline lowering for direct calls because it avoids an extra trait-object
/// hop and keeps the formatting macro behaviour identical to the prior
/// generated code.
pub fn print(s: ArcStr) {
    // On wasm there is no OS stdout; route through the host hook (the JS host
    // binds it to console.log — see libopenmodelica_compiler). With no hook
    // bound the output is dropped, matching the prior wasm behaviour.
    #[cfg(target_arch = "wasm32")]
    {
        if let Some(hook) = STDOUT_HOOK.get() {
            hook(s.as_str());
        }
        return;
    }
    #[cfg(not(target_arch = "wasm32"))]
    {
        use std::io::Write;
        let stdout = std::io::stdout();
        let mut handle = stdout.lock();
        handle.write_all(s.as_bytes()).ok();
    }
}

// Host output hooks. The native build writes straight to the process
// stdout/stderr; on wasm there is no OS console, so the JS host binds these
// (console.log / console.error) at startup. Mirrors the `ASSERT_HOOK` pattern.
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

/// Write `s` to the host's stderr: the process stderr natively, or the bound
/// stderr hook on wasm. Use instead of a bare `eprintln!` wherever the output
/// must reach the JS console on wasm (e.g. the `showErrorMessages` echo).
pub fn host_eprint(s: &str) {
    #[cfg(target_arch = "wasm32")]
    {
        if let Some(hook) = STDERR_HOOK.get() {
            hook(s);
        }
    }
    #[cfg(not(target_arch = "wasm32"))]
    {
        eprint!("{s}");
    }
}
