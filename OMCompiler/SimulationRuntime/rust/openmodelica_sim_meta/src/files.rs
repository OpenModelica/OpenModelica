//! The files a run writes beside its result: `+profiling`'s traces and report and
//! the homotopy path CSVs. C's runtime has `fopen`, but the same driver runs in
//! three places with three different notions of a file — the native host, the web
//! omc (whose files live in an in-memory store) and an in-wasm artifact (whose
//! caller takes the bytes) — so the writer is installed by the embedder.

use core::sync::atomic::{AtomicUsize, Ordering};

static WRITE: AtomicUsize = AtomicUsize::new(0);
static READ: AtomicUsize = AtomicUsize::new(0);

/// Install the writer every side file goes through. Unset, a `std` build writes
/// with `std::fs` and the in-wasm runtime drops the file.
pub fn set_writer(f: fn(&str, &[u8]) -> bool) {
    WRITE.store(f as usize, Ordering::Relaxed);
}

/// C's `fopen(path, "wb")` and `fwrite`; `false` when the file could not be
/// written, which every caller reports as C does.
pub fn write(path: &str, bytes: &[u8]) -> bool {
    let p = WRITE.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn(&str, &[u8]) -> bool = unsafe { core::mem::transmute(p) };
        return f(path, bytes);
    }
    #[cfg(feature = "std")]
    return std::fs::write(path, bytes).is_ok();
    #[cfg(not(feature = "std"))]
    false
}

/// Install the reader a run's input side file (`-parmodImportClustering`) goes
/// through. Unset, a `std` build reads with `std::fs` and the in-wasm runtime has
/// no file.
pub fn set_reader(f: fn(&str) -> Option<alloc::vec::Vec<u8>>) {
    READ.store(f as usize, Ordering::Relaxed);
}

/// C's `fopen(path, "rb")` + read to end; `None` when the file could not be read.
pub fn read(path: &str) -> Option<alloc::vec::Vec<u8>> {
    let p = READ.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn(&str) -> Option<alloc::vec::Vec<u8>> = unsafe { core::mem::transmute(p) };
        return f(path);
    }
    #[cfg(feature = "std")]
    return std::fs::read(path).ok();
    #[cfg(not(feature = "std"))]
    None
}
