//! The `susan` binary: OpenModelica's Susan template compiler as a standalone
//! tool. It turns a `*.tpl` template into the corresponding `*.mo`
//! MetaModelica file — exactly what `omc -d=failtrace <file>.tpl` did in the C
//! build (see `template_compilation.cmake`). Building this as a native Rust
//! binary lets the build compile the code-generation templates without a C
//! `omc`/`bomc`.
//!
//! Usage:  `susan [flags] <file.tpl>`  (run with the template's directory as the
//! working directory; the `<file>.mo` is written next to the input, as omc did).
//! Leading `-…` flags (e.g. `-d=failtrace`, passed by the CMake template rule)
//! are accepted and ignored; the first non-flag argument is the template file.
//!
//! This is deliberately a thin wrapper over the single library entry point
//! `TplMain::main`: the flags global is valid by default (see
//! `openmodelica_util::Globals::flagsIndex`), so no runtime initialisation is
//! needed here.

use arcstr::ArcStr;
use std::io::Write;

use openmodelica_susan::TplMain;

/// The Susan template parser (`TplParser`) is deeply recursive — the C build
/// links `bomc` with a 32 MiB stack specifically so the `*CPP.tpl` files, which
/// have very long lines, do not overflow it while parsing. The Rust port's
/// frames are larger again, so reserve generously. The reservation is virtual
/// address space only (committed lazily), so the headroom is effectively free.
const DEFAULT_STACK_SIZE: usize = 64 * 1024 * 1024;

fn run() -> i32 {
    let Some(file) = std::env::args().skip(1).find(|a| !a.starts_with('-')).map(ArcStr::from) else {
        eprintln!("usage: susan [flags] <file.tpl>");
        return 1;
    };
    match TplMain::main(file) {
        Ok(()) => 0,
        Err(_) => {
            // `TplMain`/`translateFile` already printed the error buffer and the
            // "translation failed" banner before failing; just flush and report
            // a non-zero status so the build stops (and the `*.mo` is not used).
            let _ = std::io::stdout().flush();
            eprintln!("susan: template translation failed");
            1
        }
    }
}

fn main() -> std::process::ExitCode {
    let stack_size = std::env::var("OPENMODELICA_STACK_SIZE_KB")
        .ok()
        .and_then(|s| s.parse::<usize>().ok())
        .map(|kb| kb * 1024)
        .unwrap_or(DEFAULT_STACK_SIZE);
    match std::thread::Builder::new()
        .name("susan-main".to_owned())
        .stack_size(stack_size)
        .spawn(|| {
            let code = run();
            let _ = std::io::stdout().flush();
            let _ = std::io::stderr().flush();
            std::process::exit(code);
        }) {
        Ok(handle) => {
            let _ = handle.join();
            std::process::ExitCode::FAILURE
        }
        Err(_) => std::process::ExitCode::from(run() as u8),
    }
}
