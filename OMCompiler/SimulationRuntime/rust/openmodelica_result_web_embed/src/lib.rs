//! `openmodelica_result_web` as bytes, for a host program that serves or embeds
//! it: the wasm-bindgen glue and the module, built by this crate's `build.rs`.
//!
//! The glue imports the module by the file name below, so both must be written
//! into the same directory under these names — [`write_into`] does that.

use std::io;
use std::path::Path;

/// The ES module the page imports; it fetches [`WASM_NAME`] beside itself.
pub const GLUE_NAME: &str = "openmodelica_result_web.js";
pub const WASM_NAME: &str = "openmodelica_result_web_bg.wasm";

pub const GLUE: &str = include_str!(concat!(env!("OPENMODELICA_RESULT_WEB_PKG"), "/openmodelica_result_web.js"));
pub const WASM: &[u8] =
    include_bytes!(concat!(env!("OPENMODELICA_RESULT_WEB_PKG"), "/openmodelica_result_web_bg.wasm"));

/// Write both files into `dir`, which is created if needed. A file already there
/// with the right size is left alone, so serving many reports out of one
/// directory does not rewrite several megabytes each time.
pub fn write_into(dir: &Path) -> io::Result<()> {
    std::fs::create_dir_all(dir)?;
    for (name, bytes) in [(GLUE_NAME, GLUE.as_bytes()), (WASM_NAME, WASM)] {
        let to = dir.join(name);
        if to.metadata().is_ok_and(|m| m.len() == bytes.len() as u64) {
            continue;
        }
        std::fs::write(to, bytes)?;
    }
    Ok(())
}
