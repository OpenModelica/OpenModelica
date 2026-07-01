//! Filesystem facade: every omc file op routes through here so one place picks
//! the backend. `std::fs` for native and the wasip1 standalone (there it *is*
//! WASI), the in-memory store for the web target. Split on `target_os = "wasi"`
//! so a `wasmtime`-run command module uses host files, not the store.

use std::io::{self, Read, Seek, SeekFrom};
use std::time::SystemTime;

pub const IN_MEMORY: bool = cfg!(all(target_arch = "wasm32", not(target_os = "wasi")));

fn not_found(path: &str) -> io::Error {
    io::Error::new(io::ErrorKind::NotFound, format!("no such file: {path}"))
}

/// A seekable reader for `Read + Seek` consumers: a `std::fs::File` natively, an
/// in-memory `Cursor` on the web target.
pub enum Reader {
    Disk(std::fs::File),
    Mem(io::Cursor<Vec<u8>>),
}

pub fn open_read(path: &str) -> io::Result<Reader> {
    if IN_MEMORY {
        Ok(Reader::Mem(io::Cursor::new(crate::read(path).ok_or_else(|| not_found(path))?)))
    } else {
        Ok(Reader::Disk(std::fs::File::open(path)?))
    }
}

impl Reader {
    /// A second independent handle: `try_clone` natively, a byte copy in memory.
    pub fn try_clone(&self) -> io::Result<Reader> {
        match self {
            Reader::Disk(f) => Ok(Reader::Disk(f.try_clone()?)),
            Reader::Mem(c) => Ok(Reader::Mem(c.clone())),
        }
    }
}

impl Read for Reader {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        match self {
            Reader::Disk(f) => f.read(buf),
            Reader::Mem(c) => c.read(buf),
        }
    }
}

impl Seek for Reader {
    fn seek(&mut self, pos: SeekFrom) -> io::Result<u64> {
        match self {
            Reader::Disk(f) => f.seek(pos),
            Reader::Mem(c) => c.seek(pos),
        }
    }
}

#[derive(Clone, Debug)]
pub struct DirEntry {
    pub name: String,
    pub is_dir: bool,
}

pub fn read(path: &str) -> io::Result<Vec<u8>> {
    if IN_MEMORY {
        crate::read(path).ok_or_else(|| not_found(path))
    } else {
        std::fs::read(path)
    }
}

pub fn read_to_string(path: &str) -> io::Result<String> {
    if IN_MEMORY {
        let bytes = crate::read(path).ok_or_else(|| not_found(path))?;
        String::from_utf8(bytes).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))
    } else {
        std::fs::read_to_string(path)
    }
}

pub fn write(path: &str, bytes: &[u8]) -> io::Result<()> {
    if IN_MEMORY {
        crate::write(path, bytes.to_vec());
        Ok(())
    } else {
        std::fs::write(path, bytes)
    }
}

pub fn append(path: &str, bytes: &[u8]) -> io::Result<()> {
    if IN_MEMORY {
        crate::append(path, bytes);
        Ok(())
    } else {
        use std::io::Write as _;
        let mut f = std::fs::OpenOptions::new().create(true).append(true).open(path)?;
        f.write_all(bytes)
    }
}

pub fn exists(path: &str) -> bool {
    if IN_MEMORY {
        crate::exists(path) || crate::is_dir(path)
    } else {
        std::fs::metadata(path).is_ok()
    }
}

pub fn is_dir(path: &str) -> bool {
    if IN_MEMORY {
        crate::is_dir(path)
    } else {
        std::fs::metadata(path).map(|m| m.is_dir()).unwrap_or(false)
    }
}

pub fn is_file(path: &str) -> bool {
    if IN_MEMORY {
        crate::exists(path) && !crate::is_dir(path)
    } else {
        std::fs::metadata(path).map(|m| m.is_file()).unwrap_or(false)
    }
}

pub fn is_readable(path: &str) -> bool {
    if IN_MEMORY {
        crate::exists(path)
    } else {
        std::fs::File::open(path).is_ok()
    }
}

pub fn is_writable(path: &str) -> bool {
    if IN_MEMORY {
        crate::exists(path)
    } else {
        std::fs::OpenOptions::new().write(true).open(path).is_ok()
    }
}

pub fn remove_file(path: &str) -> io::Result<()> {
    if IN_MEMORY {
        if crate::remove(path) { Ok(()) } else { Err(not_found(path)) }
    } else {
        std::fs::remove_file(path)
    }
}

pub fn remove_dir_all(path: &str) -> io::Result<()> {
    if IN_MEMORY {
        let prefix = format!("{}/", path.trim_end_matches('/'));
        for key in crate::list() {
            if key == path || key.starts_with(&prefix) {
                crate::remove(&key);
            }
        }
        Ok(())
    } else {
        std::fs::remove_dir_all(path)
    }
}

pub fn create_dir_all(path: &str) -> io::Result<()> {
    if IN_MEMORY {
        let _ = path; // store directories are implicit
        Ok(())
    } else {
        std::fs::create_dir_all(path)
    }
}

pub fn rename(from: &str, to: &str) -> io::Result<()> {
    if IN_MEMORY {
        let bytes = crate::read(from).ok_or_else(|| not_found(from))?;
        crate::write(to, bytes);
        crate::remove(from);
        Ok(())
    } else {
        std::fs::rename(from, to)
    }
}

pub fn copy(from: &str, to: &str) -> io::Result<u64> {
    if IN_MEMORY {
        let bytes = crate::read(from).ok_or_else(|| not_found(from))?;
        let n = bytes.len() as u64;
        crate::write(to, bytes);
        Ok(n)
    } else {
        std::fs::copy(from, to)
    }
}

pub fn read_dir(dir: &str) -> io::Result<Vec<DirEntry>> {
    if IN_MEMORY {
        Ok(crate::list_dir(dir)
            .into_iter()
            .map(|(name, is_dir)| DirEntry { name, is_dir })
            .collect())
    } else {
        let mut out = Vec::new();
        for entry in std::fs::read_dir(dir)? {
            let entry = entry?;
            let is_dir = entry.file_type().map(|t| t.is_dir()).unwrap_or(false);
            out.push(DirEntry { name: entry.file_name().to_string_lossy().into_owned(), is_dir });
        }
        Ok(out)
    }
}

pub fn len(path: &str) -> io::Result<u64> {
    if IN_MEMORY {
        crate::read(path).map(|b| b.len() as u64).ok_or_else(|| not_found(path))
    } else {
        std::fs::metadata(path).map(|m| m.len())
    }
}

pub fn modified(path: &str) -> io::Result<SystemTime> {
    if IN_MEMORY {
        // The store keeps the write time as a duration since the epoch (real
        // wall clock via the JS `Date.now` on web); rebuild a SystemTime from it.
        crate::mtime(path)
            .map(|d| SystemTime::UNIX_EPOCH + d)
            .ok_or_else(|| not_found(path))
    } else {
        std::fs::metadata(path)?.modified()
    }
}

pub fn set_cwd(dir: &str) -> io::Result<()> {
    if IN_MEMORY {
        crate::set_cwd(dir);
        Ok(())
    } else {
        std::env::set_current_dir(dir)
    }
}

pub fn cwd() -> io::Result<String> {
    if IN_MEMORY {
        Ok(crate::cwd())
    } else {
        Ok(std::env::current_dir()?.to_string_lossy().into_owned())
    }
}
