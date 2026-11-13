//! Where the scripting functions write: `std::fs`, or openmodelica_wasi's store
//! with the `vfs` feature (see openmodelica_mat_reader's fs facade).

#[cfg(feature = "vfs")]
pub use openmodelica_wasi::fs::{modified, write};

#[cfg(not(feature = "vfs"))]
pub use std::fs::write;

#[cfg(not(feature = "vfs"))]
pub fn modified(path: &str) -> std::io::Result<std::time::SystemTime> {
    std::fs::metadata(path)?.modified()
}
