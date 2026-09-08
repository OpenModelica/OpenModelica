//! Where the result readers get their bytes: `openmodelica_wasi`'s in-memory
//! store with the `vfs` feature (what omc and the wasm modules need), plain
//! `std::fs` without it. The store is the *only* filesystem on
//! wasm32-unknown-unknown, hence the refusal below.

#[cfg(all(target_arch = "wasm32", not(target_os = "wasi"), not(feature = "vfs")))]
compile_error!(
    "wasm32-unknown-unknown has no OS filesystem: build openmodelica_mat_reader \
     with the `vfs` feature (its default) so the readers go through openmodelica_wasi's store"
);

#[cfg(feature = "vfs")]
pub use openmodelica_wasi::fs::{Reader, open_read, read};

#[cfg(not(feature = "vfs"))]
mod plain {
    use std::fs::File;
    use std::io::{self, Read, Seek, SeekFrom};

    /// Wrapped only so `try_clone` matches the facade's signature.
    pub struct Reader(File);

    impl Reader {
        pub fn try_clone(&self) -> io::Result<Reader> {
            self.0.try_clone().map(Reader)
        }
    }

    impl Read for Reader {
        fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
            self.0.read(buf)
        }
    }

    impl Seek for Reader {
        fn seek(&mut self, pos: SeekFrom) -> io::Result<u64> {
            self.0.seek(pos)
        }
    }

    pub fn open_read(path: &str) -> io::Result<Reader> {
        File::open(path).map(Reader)
    }

    pub fn read(path: &str) -> io::Result<Vec<u8>> {
        std::fs::read(path)
    }
}

#[cfg(not(feature = "vfs"))]
pub use plain::{Reader, open_read, read};
