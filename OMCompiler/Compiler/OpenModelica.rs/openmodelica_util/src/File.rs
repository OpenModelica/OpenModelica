// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/File.mo` and its companion C runtime
// `OMCompiler/Compiler/Util/omc_file_ext.h`.
//
// The MetaModelica source declares `File` as an ExternalObject whose runtime
// representation in C is `__OMC_FILE { FILE* file; mmc_sint_t cnt; const char*
// name; }` with manual reference counting. In Rust we model the same
// invariants more idiomatically:
//
//   * `pub struct File` is a clonable handle whose contents are shared via
//     `Arc<Mutex<FileInner>>`. Cloning the `Arc` *is* the reference count.
//   * `FileInner` owns an optional `std::fs::File` plus the on-disk file name
//     and current write escape mode. When the last `Arc` is dropped the
//     `std::fs::File` is dropped too — the C destructor's `fclose` happens
//     for free.
//
// Note on the constructor's `fromID: Option<Integer>` parameter: in the C
// runtime this is a void* pretending to be `Option<Integer>` — either NULL
// (meaning "make a new file") or a raw `__OMC_FILE*` whose reference count
// the constructor bumps. MetaModelica callers only ever produce that pointer
// via `getReference` / `noReference` and store it in `Tpl.Text.FILE_TEXT`'s
// `opaqueFile` field, reconstructing a `File` from it for every token
// written (`Tpl.tokFileText` etc.).
//
// Rust cannot pun a pointer through `Option<i32>`, so the opaque value is a
// small integer handle into a thread-local registry instead (see
// [`FILE_REGISTRY`]): `getReference` registers a clone of the `File` handle
// and returns the id, the constructor with `Some(id)` clones the registered
// handle back out, and `releaseReference` removes the registry entry (the
// `Arc` refcount then handles the actual close on last drop, mirroring the
// C destructor's `fclose` at refcount zero). The registry is thread-local
// for the same reason the rest of the per-task runtime state is
// (`ErrorExt.rs`, `BackendDAEEXT.rs`): the compiler runs each task on one
// thread (`System.launchParallelTasks` is a serial map in this port, and
// the MM payloads are not `Send`), and a thread-local keeps the per-token
// reconstruction on the Tpl hot path lock-free.

#![allow(non_snake_case)]

use std::cell::{Cell, RefCell};
use std::collections::HashMap;
#[cfg(not(target_arch = "wasm32"))]
use std::fs::OpenOptions;
#[cfg(not(target_arch = "wasm32"))]
use std::io::{Seek, SeekFrom, Write};
use std::sync::{Arc, Mutex};

use anyhow::{bail, Result};
use arcstr::{literal, ArcStr};

#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
#[repr(i32)]
pub enum Mode {
    Read = 1,
    Write = 2,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
#[repr(i32)]
pub enum Whence {
    Set = 1,
    Current = 2,
    End = 3,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
#[repr(i32)]
pub enum Escape {
    None = 1,
    C = 2,
    JSON = 3,
    XML = 4,
}

struct FileInner {
    #[cfg(not(target_arch = "wasm32"))]
    file: Option<std::fs::File>,
    // wasm has no OS filesystem: buffer the content in memory and flush it to the
    // VFS. `mode` (None = not open) gates writes/seek like the native `Option<File>`;
    // `pos` is the read/write cursor for seek/tell, so seek-then-write backpatching
    // works in the buffer. Flushed to the VFS on close (reopen) and on drop.
    #[cfg(target_arch = "wasm32")]
    buf: Vec<u8>,
    #[cfg(target_arch = "wasm32")]
    pos: usize,
    #[cfg(target_arch = "wasm32")]
    mode: Option<Mode>,
    name: ArcStr,
}

impl FileInner {
    fn write_bytes(&mut self, bytes: &[u8], what: &str) -> Result<()> {
        #[cfg(not(target_arch = "wasm32"))]
        {
            match self.file.as_mut() {
                Some(f) => f
                    .write_all(bytes)
                    .map_err(|e| anyhow::anyhow!("File.{what}: write to {}: {}", self.name, e)),
                None => bail!("File.{what}: Failed to write to file: {} (not open)", self.name),
            }
        }
        #[cfg(target_arch = "wasm32")]
        {
            if self.mode != Some(Mode::Write) {
                bail!("File.{what}: Failed to write to file: {} (not open)", self.name);
            }
            let end = self.pos + bytes.len();
            if self.buf.len() < end {
                self.buf.resize(end, 0);
            }
            self.buf[self.pos..end].copy_from_slice(bytes);
            self.pos = end;
            Ok(())
        }
    }
}

#[cfg(target_arch = "wasm32")]
impl FileInner {
    /// Persist the buffer to the VFS (Write-mode files only).
    fn flush_to_vfs(&self) {
        if self.mode == Some(Mode::Write) {
            openmodelica_wasi::write(self.name.as_str(), self.buf.clone());
        }
    }
}

#[cfg(target_arch = "wasm32")]
impl Drop for FileInner {
    fn drop(&mut self) {
        self.flush_to_vfs();
    }
}

/// A handle to an opaque MetaModelica `File` external object.
#[derive(Clone)]
pub struct File {
    inner: Arc<Mutex<FileInner>>,
}

impl std::fmt::Debug for File {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self.inner.lock() {
            Ok(g) => write!(f, "File({:?})", g.name),
            Err(_) => write!(f, "File(<poisoned>)"),
        }
    }
}

impl PartialEq for File {
    fn eq(&self, other: &Self) -> bool {
        Arc::ptr_eq(&self.inner, &other.inner)
    }
}
impl Eq for File {}

thread_local! {
    /// Opaque-reference registry backing `getReference` / the `Some(id)`
    /// constructor path — see the module-level comment. Maps the punned
    /// `Option<Integer>` handle to a clone of the `File`. Entries are
    /// created by [`getReference`] and removed by [`releaseReference`];
    /// a Text dropped without `Tpl.closeFile` leaks its entry, exactly as
    /// the C version leaks the un-decremented refcount (and never closes
    /// the file).
    static FILE_REGISTRY: RefCell<HashMap<i32, File>> = RefCell::new(HashMap::new());
    /// Next registry handle. Starts at 1 — the C side's NULL/None means
    /// "no reference", so 0 is never a valid handle.
    static NEXT_FILE_REF: Cell<i32> = const { Cell::new(1) };
}

impl File {
    /// Constructor. `fromID` mirrors the MM signature: `None` creates a new
    /// (unopened) file object; `Some(id)` reconstructs the `File` registered
    /// under `id` by [`getReference`] (the C runtime bumps the refcount on a
    /// raw pointer here; cloning the `Arc` handle is the Rust equivalent).
    pub fn new(fromID: Option<i32>) -> Result<File> {
        match fromID {
            None => Ok(File {
                inner: Arc::new(Mutex::new(FileInner {
                    #[cfg(not(target_arch = "wasm32"))]
                    file: None,
                    #[cfg(target_arch = "wasm32")]
                    buf: Vec::new(),
                    #[cfg(target_arch = "wasm32")]
                    pos: 0,
                    #[cfg(target_arch = "wasm32")]
                    mode: None,
                    name: literal!("[no open file]"),
                })),
            }),
            Some(id) => FILE_REGISTRY.with(|r| {
                r.borrow().get(&id).cloned().ok_or_else(|| {
                    anyhow::anyhow!(
                        "File.constructor: opaque file reference {id} is not registered \
                         (already released, or created on another thread)"
                    )
                })
            }),
        }
    }
}

/// Free-function shim with the class name so MetaModelica call sites that
/// spell the constructor as `File.File(...)` (i.e. `File::File(...)` in
/// generated Rust) resolve. Functions and types share no namespace in Rust,
/// so this happily coexists with the `File` struct.
pub fn File(fromID: Option<i32>) -> Result<File> {
    File::new(fromID)
}

/// Destructor stub. The MM destructor's job is to release the underlying
/// resource; in Rust that happens automatically when the last `Arc` is
/// dropped, so this is intentionally a no-op.
pub fn destructor(_file: File) {}

pub fn open(file: File, filename: ArcStr, mode: Mode) -> Result<()> {
    let mut guard = file.inner.lock().unwrap();
    #[cfg(not(target_arch = "wasm32"))]
    {
        // If a file is already open, close it (drop it) before opening a new one,
        // matching the C runtime's behavior.
        guard.file = None;
        let handle = match mode {
            Mode::Read => OpenOptions::new().read(true).open(filename.as_str()),
            Mode::Write => OpenOptions::new()
                .write(true)
                .create(true)
                .truncate(true)
                .open(filename.as_str()),
        }
        .map_err(|e| anyhow::anyhow!("File.open: Failed to open file {filename} with mode {mode:?}: {e}"))?;
        guard.file = Some(handle);
        guard.name = filename;
        Ok(())
    }
    #[cfg(target_arch = "wasm32")]
    {
        // Flush any previously-open Write file before repointing.
        guard.flush_to_vfs();
        match mode {
            Mode::Read => {
                let bytes = openmodelica_wasi::read(filename.as_str()).ok_or_else(|| {
                    anyhow::anyhow!("File.open: Failed to open file {filename} with mode {mode:?}: no such file")
                })?;
                guard.buf = bytes;
            }
            Mode::Write => {
                guard.buf = Vec::new();
                // Create/truncate now so the file exists even if nothing is written.
                openmodelica_wasi::write(filename.as_str(), Vec::new());
            }
        }
        guard.pos = 0;
        guard.mode = Some(mode);
        guard.name = filename;
        Ok(())
    }
}

pub fn write(file: File, data: ArcStr) -> Result<()> {
    let mut guard = file.inner.lock().unwrap();
    guard.write_bytes(data.as_bytes(), "write")
}

pub fn writeInt(file: File, data: i32, format: ArcStr) -> Result<()> {
    // The C runtime uses `fprintf` with a user-supplied format string. We
    // honor the common `%d` default with a fast path and fall through to a
    // simple substitution otherwise. Full printf-compatibility would require
    // a printf parser; callers in the OMC sources only use `%d` and `%ld`.
    let mut guard = file.inner.lock().unwrap();
    let s = match format.as_str() {
        "%d" | "%i" | "%ld" => data.to_string(),
        other => other.replace("%d", &data.to_string()).replace("%ld", &data.to_string()),
    };
    guard.write_bytes(s.as_bytes(), "writeInt")
}

pub fn writeReal(file: File, data: metamodelica::Real, format: ArcStr) -> Result<()> {
    // The MetaModelica formal is `input Real data`; `Real` maps to
    // `metamodelica::Real` (`OrderedFloat<f64>`) in generated code, so callers
    // pass that. Operate on the inner `f64` via `.0`.
    let data = data.0;
    let mut guard = file.inner.lock().unwrap();
    let s = match format.as_str() {
        "%.15g" => format!("{:.15e}", data).replace("e0", ""),
        // Generic fallback: just print using Rust's default Display.
        _ => data.to_string(),
    };
    guard.write_bytes(s.as_bytes(), "writeReal")
}

pub fn writeEscape(file: File, data: ArcStr, escape: Escape) -> Result<()> {
    let mut buf: Vec<u8> = Vec::with_capacity(data.len());
    match escape {
        Escape::None => buf.extend_from_slice(data.as_bytes()),
        Escape::C => {
            for &b in data.as_bytes() {
                match b {
                    b'\n' => buf.extend_from_slice(b"\\n"),
                    b'"' => buf.extend_from_slice(b"\\\""),
                    _ => buf.push(b),
                }
            }
        }
        Escape::JSON => {
            for &b in data.as_bytes() {
                match b {
                    b'"' => buf.extend_from_slice(b"\\\""),
                    b'\\' => buf.extend_from_slice(b"\\\\"),
                    b'\n' => buf.extend_from_slice(b"\\n"),
                    0x08 => buf.extend_from_slice(b"\\b"),
                    0x0C => buf.extend_from_slice(b"\\f"),
                    b'\r' => buf.extend_from_slice(b"\\r"),
                    b'\t' => buf.extend_from_slice(b"\\t"),
                    b if b < b' ' => {
                        // Other control characters are emitted as \uXXXX.
                        buf.extend_from_slice(format!("\\u{:04x}", b).as_bytes());
                    }
                    b => buf.push(b),
                }
            }
        }
        Escape::XML => {
            for &b in data.as_bytes() {
                match b {
                    b'<' => buf.extend_from_slice(b"&lt;"),
                    b'>' => buf.extend_from_slice(b"&gt;"),
                    b'"' => buf.extend_from_slice(b"&#34;"),
                    b'&' => buf.extend_from_slice(b"&amp;"),
                    b'\'' => buf.extend_from_slice(b"&#39;"),
                    b => buf.push(b),
                }
            }
        }
    }
    let mut guard = file.inner.lock().unwrap();
    guard.write_bytes(&buf, "writeEscape")
}

pub fn seek(file: File, offset: i32, whence: Whence) -> Result<bool> {
    let mut guard = file.inner.lock().unwrap();
    #[cfg(not(target_arch = "wasm32"))]
    {
        let Some(f) = guard.file.as_mut() else { return Ok(false) };
        let from = match whence {
            Whence::Set => SeekFrom::Start(offset as u64),
            Whence::Current => SeekFrom::Current(offset as i64),
            Whence::End => SeekFrom::End(offset as i64),
        };
        Ok(f.seek(from).is_ok())
    }
    #[cfg(target_arch = "wasm32")]
    {
        if guard.mode.is_none() {
            return Ok(false);
        }
        let base = match whence {
            Whence::Set => 0i64,
            Whence::Current => guard.pos as i64,
            Whence::End => guard.buf.len() as i64,
        };
        let np = base + offset as i64;
        if np < 0 {
            return Ok(false);
        }
        guard.pos = np as usize;
        Ok(true)
    }
}

pub fn tell(file: File) -> i32 {
    let mut guard = file.inner.lock().unwrap();
    #[cfg(not(target_arch = "wasm32"))]
    {
        match guard.file.as_mut() {
            Some(f) => match f.stream_position() {
                Ok(p) => p as i32,
                Err(_) => -1,
            },
            None => -1,
        }
    }
    #[cfg(target_arch = "wasm32")]
    {
        match guard.mode {
            Some(_) => guard.pos as i32,
            None => -1,
        }
    }
}

pub fn getFilename(file: Option<i32>) -> Result<ArcStr> {
    // `file` is the opaque registry handle produced by `getReference`.
    let file = File::new(file)?;
    let guard = file.inner.lock().unwrap();
    Ok(guard.name.clone())
}

pub fn noReference() -> Option<i32> {
    // In C this returns NULL — a void* the constructor recognizes as "make
    // a new file"; `None` is the registry-handle equivalent. The .mo
    // declares this `external "C"` without an error path, so we return the
    // bare value (not `Result<_>`) to match what the codegen expects.
    None
}

pub fn getReference(file: File) -> Option<i32> {
    // C: bump the refcount and hand out the raw pointer. Rust: register a
    // clone of the handle (the Arc refcount *is* the loan) under a fresh id
    // and hand out the id. Balanced by `releaseReference`.
    let id = NEXT_FILE_REF.with(|n| {
        let id = n.get();
        n.set(id + 1);
        id
    });
    FILE_REGISTRY.with(|r| r.borrow_mut().insert(id, file));
    Some(id)
}

pub fn releaseReference(file: File) -> Result<()> {
    // C: decrement the refcount taken by `getReference`. Rust: drop one
    // registry entry holding this same file object (callers reconstruct the
    // handle from the opaque id first, so an entry must exist; releasing a
    // file that was never registered is an accounting bug upstream).
    let released = FILE_REGISTRY.with(|r| {
        let mut reg = r.borrow_mut();
        match reg.iter().find(|(_, f)| Arc::ptr_eq(&f.inner, &file.inner)).map(|(id, _)| *id) {
            Some(id) => { reg.remove(&id); true }
            None => false,
        }
    });
    if !released {
        bail!("File.releaseReference: file is not registered (double release?)");
    }
    Ok(())
}

pub fn writeSpace(file: File, n: i32) -> Result<()> {
    for _ in 0..n {
        write(file.clone(), literal!(" "))?;
    }
    Ok(())
}
