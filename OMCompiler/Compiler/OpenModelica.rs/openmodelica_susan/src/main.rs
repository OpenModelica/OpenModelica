//! The `susan` binary: OpenModelica's Susan template compiler as a standalone
//! tool. It turns a `*.tpl` template into the corresponding `*.mo`
//! MetaModelica file — exactly what `omc -d=failtrace <file>.tpl` did in the C
//! build (see `template_compilation.cmake`). Building this as a native Rust
//! binary lets the build compile the code-generation templates without a C
//! `omc`/`bomc`.
//!
//! Usage:  `susan [flags] <file.tpl>`  (run with the template's directory as the
//! working directory). `--tplOutputDir=<dir>` writes the `<file>.mo` there —
//! the same omc config flag, which the build rules use to keep the generated
//! sources out of the source tree; without it the `.mo` is written next to the
//! input, as omc did. `--tplInterfaceDir=<dir>` is searched before the current
//! directory for `import interface` files. `--tplRustIndex=<json>` selects the
//! Rust backend (see `run_rust`). Other leading `-…` flags (e.g.
//! `-d=failtrace`, passed by the CMake template rule) are accepted and
//! ignored; the first non-flag argument is the template file.
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

const OUTPUT_DIR_FLAG: &str = "--tplOutputDir=";
const INTERFACE_DIR_FLAG: &str = "--tplInterfaceDir=";
const RUST_INDEX_FLAG: &str = "--tplRustIndex=";

mod rust_backend;

fn write_if_changed(path: &std::path::Path, content: &str) -> std::io::Result<()> {
    if std::fs::read_to_string(path).is_ok_and(|old| old == content) {
        return Ok(());
    }
    std::fs::write(path, content)
}

/// Translates `file` to `<out_dir>/<crate>/src/<Package>.rs` with Susan's Rust
/// backend; the crate comes from the template's `__OpenModelica_Interface`.
fn run_rust(file: ArcStr, out_dir: &str, interface_dir: ArcStr, index: &str) -> i32 {
    let idx = match std::fs::read_to_string(index)
        .map_err(|e| e.to_string())
        .and_then(|s| serde_json::from_str::<serde_json::Value>(&s).map_err(|e| e.to_string()))
        .and_then(|v| openmodelica_susan_index::Index::from_json(&v))
    {
        Ok(i) => i,
        Err(e) => {
            eprintln!("susan: {index}: {e}");
            return 1;
        }
    };
    let (tpl, mm) = match TplMain::transformFile(file.clone(), interface_dir) {
        Ok(x) => x,
        Err(_) => {
            print!("{}", openmodelica_error::ErrorExt::printMessagesStr(false));
            eprintln!("susan: template translation failed");
            return 1;
        }
    };
    match rust_backend::print(&tpl, &mm, &idx, std::path::Path::new(".")) {
        Ok((krate, code)) => {
            let name = std::path::Path::new(file.as_str()).file_stem().unwrap().to_string_lossy().into_owned();
            let dir = if out_dir.is_empty() { "." } else { out_dir };
            let dest = std::path::Path::new(dir).join(krate).join("src").join(format!("{name}.rs"));
            if let Err(e) = write_if_changed(&dest, &code) {
                eprintln!("susan: {}: {e}", dest.display());
                return 1;
            }
            0
        }
        Err(errs) => {
            for e in errs {
                eprintln!("{file}: {e}");
            }
            1
        }
    }
}

fn run() -> i32 {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let Some(file) = args.iter().find(|a| !a.starts_with('-')).map(ArcStr::from) else {
        eprintln!("usage: susan [--tplOutputDir=<dir>] [flags] <file.tpl>");
        return 1;
    };
    // Last one wins, like omc's own flag parsing.
    let out_dir = args
        .iter()
        .filter_map(|a| a.strip_prefix(OUTPUT_DIR_FLAG))
        .next_back()
        .map(ArcStr::from)
        .unwrap_or_default();
    let interface_dir = args
        .iter()
        .filter_map(|a| a.strip_prefix(INTERFACE_DIR_FLAG))
        .next_back()
        .map(ArcStr::from)
        .unwrap_or_default();
    if let Some(index) = args.iter().filter_map(|a| a.strip_prefix(RUST_INDEX_FLAG)).next_back() {
        return run_rust(file, &out_dir, interface_dir, index);
    }
    match TplMain::main(file, &out_dir, interface_dir) {
        Ok(()) => 0,
        Err(_) => {
            // `translateFile` prints the Print-module buffer, which Susan's own
            // diagnostics do not use: they go to the Error module.
            print!("{}", openmodelica_error::ErrorExt::printMessagesStr(false));
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
