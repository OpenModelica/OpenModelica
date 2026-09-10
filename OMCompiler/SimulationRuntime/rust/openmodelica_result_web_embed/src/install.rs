//! `install-result-web <DIR>`: write the browser module into a directory.
//!
//! For a build system that wants the files on disk rather than embedded — the
//! one recipe, in one place, whether the caller is CMake or a Rust program.

fn main() -> std::process::ExitCode {
    let mut args = std::env::args_os().skip(1);
    let Some(dir) = args.next().filter(|_| args.next().is_none()) else {
        eprintln!("usage: install-result-web <DIR>");
        return std::process::ExitCode::from(2);
    };
    let dir = std::path::PathBuf::from(dir);
    match openmodelica_result_web_embed::write_into(&dir) {
        Ok(()) => {
            println!(
                "{} and {} -> {}",
                openmodelica_result_web_embed::GLUE_NAME,
                openmodelica_result_web_embed::WASM_NAME,
                dir.display()
            );
            std::process::ExitCode::SUCCESS
        }
        Err(e) => {
            eprintln!("install-result-web: {}: {e}", dir.display());
            std::process::ExitCode::FAILURE
        }
    }
}
