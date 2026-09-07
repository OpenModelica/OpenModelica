//! A minimal `wasi_snapshot_preview1` implementation over this crate's [`fs`]
//! facade, so a guest sees the same files omc does: real ones natively, the
//! in-memory store on the web.
//!
//! The ABI methods take a [`GuestMem`] (the guest's linear memory) and follow the
//! preview1 pointer/struct layout — for a guest wasm module driven by an engine.
//! The high-level methods at the bottom take and return plain Rust values, for a
//! host that reads/lists the store directly. Both share one fd table.

use std::cell::RefCell;
use std::collections::HashMap;

// ───────────────────────────── stdout/stderr capture ─────────────────────────

thread_local! {
    static STDOUT_CAPTURE: RefCell<Option<Vec<u8>>> = const { RefCell::new(None) };
}

/// Begin capturing fd 1/2 (stdout/stderr) writes into an in-memory buffer instead
/// of the host's real stdout/stderr. The JIT simulation run enables this so the
/// model's output (Modelica `Streams.print`, `ModelicaMessage`, …) is folded into
/// the caller's log rather than leaking to the process stdout — the browser
/// console on the web target.
pub fn start_stdout_capture() {
    STDOUT_CAPTURE.with(|c| *c.borrow_mut() = Some(Vec::new()));
    NATIVE_CAPTURE.with(|h| h.get().map(|n| (n.begin)()));
}

/// End capture and return the accumulated bytes as a lossy-UTF-8 string.
pub fn take_stdout_capture() -> String {
    let native = NATIVE_CAPTURE.with(|h| h.get().map(|n| (n.end)())).unwrap_or_default();
    STDOUT_CAPTURE
        .with(|c| c.borrow_mut().take())
        .map(|mut v| {
            v.extend_from_slice(&native);
            String::from_utf8_lossy(&v).into_owned()
        })
        .unwrap_or_default()
}

/// While the redirect is in place the process's fds *are* the capture, so
/// [`write_std`] writes there too and the run's log stays one stream, as the C
/// simulation executable's is. `write` is false with no redirect in place.
#[derive(Clone, Copy)]
pub struct NativeCapture {
    pub begin: fn(),
    pub write: fn(&[u8], bool) -> bool,
    pub end: fn() -> Vec<u8>,
}

thread_local! {
    static NATIVE_CAPTURE: std::cell::Cell<Option<NativeCapture>> = const { std::cell::Cell::new(None) };
}

/// Extend the capture over the *process's* stdout, which a `dlopen`ed external "C"
/// library's `printf` reaches directly — past the WASI shim, past `ModelicaMessage`.
/// C's simulation executable has a stdout of its own, so that output belongs in the
/// run's log too.
pub fn set_native_capture(n: NativeCapture) {
    NATIVE_CAPTURE.with(|h| h.set(Some(n)));
}

/// Write to stdout (fd 1) through the same capture/host routing as a guest
/// `fd_write` — for a host that emits model output (`print`) directly rather than
/// through the WASI ABI.
pub fn stdout_write(bytes: &[u8]) {
    write_std(bytes, false);
}

/// Route a stdout/stderr write to the redirected process fds, else to the capture
/// buffer if active, else to the host.
fn write_std(bytes: &[u8], is_err: bool) {
    if NATIVE_CAPTURE.with(|h| h.get()).is_some_and(|n| (n.write)(bytes, is_err)) {
        return;
    }
    let captured = STDOUT_CAPTURE.with(|c| match c.borrow_mut().as_mut() {
        Some(buf) => { buf.extend_from_slice(bytes); true }
        None => false,
    });
    if !captured {
        let s = String::from_utf8_lossy(bytes);
        if is_err { eprint!("{s}") } else { print!("{s}") }
    }
}

// ─────────────────────────────── WASI constants ──────────────────────────────

// errno (`__wasi_errno_t`): 0 is success.
pub const ERRNO_SUCCESS: i32 = 0;
pub const ERRNO_BADF: i32 = 8;
pub const ERRNO_FAULT: i32 = 21;
pub const ERRNO_INVAL: i32 = 28;
pub const ERRNO_EXIST: i32 = 20;
pub const ERRNO_NOENT: i32 = 44;
pub const ERRNO_ACCES: i32 = 2;
pub const ERRNO_IO: i32 = 29;
pub const ERRNO_SPIPE: i32 = 70;

// filetype (`__wasi_filetype_t`).
pub const FILETYPE_CHARACTER_DEVICE: u8 = 2;
pub const FILETYPE_DIRECTORY: u8 = 3;
pub const FILETYPE_REGULAR_FILE: u8 = 4;

// oflags (`__wasi_oflags_t`) bits passed to `path_open`.
pub const OFLAGS_CREAT: i32 = 1 << 0;
pub const OFLAGS_DIRECTORY: i32 = 1 << 1;
pub const OFLAGS_TRUNC: i32 = 1 << 3;

// rights (`__wasi_rights_t`) bit for `fd_write`; used to tell a write-open from a
// read-open in `path_open`.
pub const RIGHTS_FD_WRITE: u64 = 1 << 6;

// fdflags (`__wasi_fdflags_t`): `fopen(…, "a")`'s O_APPEND.
pub const FDFLAGS_APPEND: i32 = 1 << 0;

// `fd_seek` whence.
pub const WHENCE_SET: i32 = 0;
pub const WHENCE_CUR: i32 = 1;
pub const WHENCE_END: i32 = 2;

/// The first preopened directory fd. fds 0/1/2 are stdin/stdout/stderr; libc
/// scans upward from 3 calling `fd_prestat_get` until it gets `EBADF`.
pub const PREOPEN_FD: u32 = 3;

// ───────────────────────────────── fd table ──────────────────────────────────

/// One open file descriptor.
enum Fd {
    /// fd 1 / fd 2 — captured to the host's stdout/stderr.
    Stdout,
    Stderr,
    /// The single preopened directory (fd 3), exposed under `name` (`"."`).
    PreopenDir { name: String },
    /// A directory opened by name, enumerated by `fd_readdir` against `vfs_path`.
    Dir { vfs_path: String },
    /// A host file (native: the store is the filesystem itself).
    Native { file: std::fs::File, path: String },
    /// A regular file of the in-memory store, held whole in `buf` and written
    /// back as it grows.
    File {
        vfs_path: String,
        buf: Vec<u8>,
        pos: usize,
        writable: bool,
        dirty: bool,
        /// Every write goes to the end, whatever `pos` says (`O_APPEND`).
        append: bool,
        /// How much of `buf` is out already, so a sequential writer appends.
        flushed: usize,
    },
}

/// Per-run WASI state: the fd table, the directory relative paths resolve
/// against, the program arguments, and the exit code captured from `proc_exit`.
pub struct WasiCtx {
    /// Directory that `path_open` resolves relative names against. Empty leaves
    /// them as they are (matching how omc's `File` runtime keys files today, with
    /// no cwd on wasm).
    cwd: String,
    next_fd: u32,
    fds: HashMap<u32, Fd>,
    args: Vec<String>,
    /// Set by `proc_exit`; `Some(0)` is a normal exit. The run helper reads this
    /// after `_start` traps to distinguish a clean exit from a real trap.
    pub exit_code: Option<u32>,
}

/// Bounds-checked access to the guest's linear memory, abstracted so the same
/// WASI logic drives both the wasmtime backend (a `&mut [u8]` slice) and the
/// wasmer backend (a copy-based `MemoryView`, the only option on the js backend).
/// Returns `false`/`None` on an out-of-bounds access.
pub trait GuestMem {
    fn size(&self) -> usize;
    fn read(&self, addr: u32, buf: &mut [u8]) -> bool;
    fn write(&mut self, addr: u32, bytes: &[u8]) -> bool;
}

/// A `&mut [u8]` slice as guest memory (wasmtime backend — zero-copy).
pub struct SliceMem<'a>(pub &'a mut [u8]);
impl GuestMem for SliceMem<'_> {
    fn size(&self) -> usize {
        self.0.len()
    }
    fn read(&self, addr: u32, buf: &mut [u8]) -> bool {
        let a = addr as usize;
        match self.0.get(a..a + buf.len()) {
            Some(s) => { buf.copy_from_slice(s); true }
            None => false,
        }
    }
    fn write(&mut self, addr: u32, bytes: &[u8]) -> bool {
        let a = addr as usize;
        match self.0.get_mut(a..a + bytes.len()) {
            Some(s) => { s.copy_from_slice(bytes); true }
            None => false,
        }
    }
}

impl WasiCtx {
    /// A context whose preopen anchors the guest's paths at `cwd` (`""` for bare
    /// keys) and whose `argv` is `args`. wasi-libc strips the preopen name `"."` to
    /// the empty prefix, so what reaches the ABI has lost its leading `/`.
    pub fn new(cwd: impl Into<String>, args: Vec<String>) -> Self {
        let mut fds = HashMap::new();
        fds.insert(1, Fd::Stdout);
        fds.insert(2, Fd::Stderr);
        fds.insert(PREOPEN_FD, Fd::PreopenDir { name: ".".to_string() });
        // Natively a second preopen, "/", lets the guest name a host file outright.
        if !crate::fs::IN_MEMORY {
            fds.insert(PREOPEN_FD + 1, Fd::PreopenDir { name: "/".to_string() });
        }
        WasiCtx { cwd: cwd.into(), next_fd: PREOPEN_FD + 2, fds, args, exit_code: None }
    }

    /// The file a `path_*` call names, whose path is relative to `dirfd`. libc's
    /// `*at` family passes an open directory there -- `readdir` stats each entry
    /// through the directory's own fd -- so anything but the preopen has to
    /// contribute its path.
    fn resolve_at(&self, dirfd: u32, name: &str) -> String {
        let name = name.strip_prefix("./").unwrap_or(name);
        if name.starts_with('/') {
            return name.to_string();
        }
        let base = match self.fds.get(&dirfd) {
            Some(Fd::Dir { vfs_path }) => vfs_path.as_str(),
            Some(Fd::PreopenDir { name }) if name == "/" => "/",
            _ => self.cwd.as_str(),
        };
        if base.is_empty() {
            name.to_string()
        } else {
            format!("{}/{name}", base.trim_end_matches('/'))
        }
    }

    /// Write what a writable fd gained since the last flush: nothing tears a side
    /// module down, so a stream that is never closed must still reach the file.
    fn flush_file(vfs_path: &str, buf: &[u8], flushed: &mut usize) {
        let ok = if *flushed == 0 || *flushed > buf.len() {
            crate::fs::write(vfs_path, buf).is_ok()
        } else {
            crate::fs::append(vfs_path, &buf[*flushed..]).is_ok()
        };
        if ok {
            *flushed = buf.len();
        }
    }

    // ── memory helpers (little-endian, bounds-checked) ───────────────────────

    fn rd_u32<M: GuestMem>(mem: &M, addr: u32) -> Option<u32> {
        let mut b = [0u8; 4];
        mem.read(addr, &mut b).then(|| u32::from_le_bytes(b))
    }
    fn rd_bytes<M: GuestMem>(mem: &M, addr: u32, len: u32) -> Option<Vec<u8>> {
        let mut v = vec![0u8; len as usize];
        mem.read(addr, &mut v).then_some(v)
    }
    fn wr_u32<M: GuestMem>(mem: &mut M, addr: u32, v: u32) -> bool {
        mem.write(addr, &v.to_le_bytes())
    }
    fn wr_u64<M: GuestMem>(mem: &mut M, addr: u32, v: u64) -> bool {
        mem.write(addr, &v.to_le_bytes())
    }
    fn wr_u8<M: GuestMem>(mem: &mut M, addr: u32, v: u8) -> bool {
        mem.write(addr, &[v])
    }

    // ── file ops ─────────────────────────────────────────────────────────────

    /// `fd_write`: gather the iovecs and append/overwrite at the fd's position.
    pub fn fd_write<M: GuestMem>(&mut self, mem: &mut M, fd: u32, iovs: u32, iovs_len: u32, nwritten: u32) -> i32 {
        self.write_iovs(mem, fd, iovs, iovs_len, None, nwritten)
    }

    /// `fd_pwrite`: `fd_write` at an explicit offset, leaving the fd's position
    /// alone. `O_APPEND` does not apply, and a stream has no offset to write at.
    pub fn fd_pwrite<M: GuestMem>(&mut self, mem: &mut M, fd: u32, iovs: u32, iovs_len: u32, offset: i64, nwritten: u32) -> i32 {
        if offset < 0 {
            return ERRNO_INVAL;
        }
        self.write_iovs(mem, fd, iovs, iovs_len, Some(offset as usize), nwritten)
    }

    fn write_iovs<M: GuestMem>(&mut self, mem: &mut M, fd: u32, iovs: u32, iovs_len: u32, at: Option<usize>, nwritten: u32) -> i32 {
        let mut gathered: Vec<u8> = Vec::new();
        for i in 0..iovs_len {
            let base = iovs + i * 8;
            let Some(buf) = Self::rd_u32(mem, base) else { return ERRNO_FAULT };
            let Some(len) = Self::rd_u32(mem, base + 4) else { return ERRNO_FAULT };
            let Some(slice) = Self::rd_bytes(mem, buf, len) else { return ERRNO_FAULT };
            gathered.extend_from_slice(&slice);
        }
        let total = gathered.len() as u32;
        match self.fds.get_mut(&fd) {
            Some(Fd::Stdout | Fd::Stderr) if at.is_some() => return ERRNO_SPIPE,
            Some(Fd::Stdout) => write_std(&gathered, false),
            Some(Fd::Stderr) => write_std(&gathered, true),
            Some(Fd::Native { file, .. }) => {
                use std::io::{Seek, SeekFrom, Write};
                // A positioned write leaves the fd's own position where it was.
                let mut resume = None;
                if let Some(off) = at {
                    let Ok(pos) = file.stream_position() else { return ERRNO_IO };
                    if file.seek(SeekFrom::Start(off as u64)).is_err() {
                        return ERRNO_IO;
                    }
                    resume = Some(pos);
                }
                if file.write_all(&gathered).is_err() {
                    return ERRNO_IO;
                }
                if let Some(pos) = resume {
                    if file.seek(SeekFrom::Start(pos)).is_err() {
                        return ERRNO_IO;
                    }
                }
            }
            Some(Fd::File { vfs_path, buf, pos, writable: true, dirty, append, flushed }) => {
                let start = match at {
                    Some(off) => off,
                    None => {
                        if *append {
                            *pos = buf.len();
                        }
                        *pos
                    }
                };
                let end = start + gathered.len();
                if buf.len() < end {
                    buf.resize(end, 0);
                }
                buf[start..end].copy_from_slice(&gathered);
                // Overwriting what is already out there: the file has to go again whole.
                if start < *flushed {
                    *flushed = 0;
                }
                if at.is_none() {
                    *pos = end;
                }
                *dirty = true;
                Self::flush_file(vfs_path, buf, flushed);
            }
            Some(_) => return ERRNO_BADF,
            None => return ERRNO_BADF,
        }
        if !Self::wr_u32(mem, nwritten, total) {
            return ERRNO_FAULT;
        }
        ERRNO_SUCCESS
    }

    /// `fd_read`: scatter from the fd's buffer at its position into the iovecs.
    pub fn fd_read<M: GuestMem>(&mut self, mem: &mut M, fd: u32, iovs: u32, iovs_len: u32, nread: u32) -> i32 {
        self.read_iovs(mem, fd, iovs, iovs_len, None, nread)
    }

    /// `fd_pread`: `fd_read` at an explicit offset, leaving the fd's position alone.
    pub fn fd_pread<M: GuestMem>(&mut self, mem: &mut M, fd: u32, iovs: u32, iovs_len: u32, offset: i64, nread: u32) -> i32 {
        if offset < 0 {
            return ERRNO_INVAL;
        }
        self.read_iovs(mem, fd, iovs, iovs_len, Some(offset as usize), nread)
    }

    fn read_iovs<M: GuestMem>(&mut self, mem: &mut M, fd: u32, iovs: u32, iovs_len: u32, at: Option<usize>, nread: u32) -> i32 {
        if let Some(Fd::Native { file, .. }) = self.fds.get_mut(&fd) {
            use std::io::{Read, Seek, SeekFrom};
            // A positioned read leaves the fd's own position where it was.
            let mut resume = None;
            if let Some(off) = at {
                let Ok(pos) = file.stream_position() else { return ERRNO_IO };
                if file.seek(SeekFrom::Start(off as u64)).is_err() {
                    return ERRNO_IO;
                }
                resume = Some(pos);
            }
            let mut total = 0u32;
            for i in 0..iovs_len {
                let base = iovs + i * 8;
                let Some(dst) = Self::rd_u32(mem, base) else { return ERRNO_FAULT };
                let Some(len) = Self::rd_u32(mem, base + 4) else { return ERRNO_FAULT };
                let mut tmp = vec![0u8; len as usize];
                let Ok(n) = file.read(&mut tmp) else { return ERRNO_IO };
                if n == 0 {
                    break;
                }
                if !mem.write(dst, &tmp[..n]) {
                    return ERRNO_FAULT;
                }
                total += n as u32;
                if n < len as usize {
                    break;
                }
            }
            if let Some(pos) = resume {
                if file.seek(SeekFrom::Start(pos)).is_err() {
                    return ERRNO_IO;
                }
            }
            return if Self::wr_u32(mem, nread, total) { ERRNO_SUCCESS } else { ERRNO_FAULT };
        }
        let Some(Fd::File { buf, pos, .. }) = self.fds.get_mut(&fd) else { return ERRNO_BADF };
        let mut cur = at.unwrap_or(*pos);
        let mut total = 0u32;
        for i in 0..iovs_len {
            let base = iovs + i * 8;
            let Some(dst) = Self::rd_u32(mem, base) else { return ERRNO_FAULT };
            let Some(len) = Self::rd_u32(mem, base + 4) else { return ERRNO_FAULT };
            let avail = buf.len().saturating_sub(cur);
            let n = (len as usize).min(avail);
            if n == 0 {
                continue;
            }
            if !mem.write(dst, &buf[cur..cur + n]) {
                return ERRNO_FAULT;
            }
            cur += n;
            total += n as u32;
        }
        if at.is_none() {
            *pos = cur;
        }
        if !Self::wr_u32(mem, nread, total) {
            return ERRNO_FAULT;
        }
        ERRNO_SUCCESS
    }

    /// `fd_seek`: reposition the fd and report the new offset.
    pub fn fd_seek<M: GuestMem>(&mut self, mem: &mut M, fd: u32, offset: i64, whence: i32, newoffset: u32) -> i32 {
        if let Some(Fd::Native { file, .. }) = self.fds.get_mut(&fd) {
            use std::io::{Seek, SeekFrom};
            let from = match whence {
                WHENCE_SET if offset >= 0 => SeekFrom::Start(offset as u64),
                WHENCE_CUR => SeekFrom::Current(offset),
                WHENCE_END => SeekFrom::End(offset),
                _ => return ERRNO_INVAL,
            };
            let Ok(np) = file.seek(from) else { return ERRNO_INVAL };
            return if Self::wr_u64(mem, newoffset, np) { ERRNO_SUCCESS } else { ERRNO_FAULT };
        }
        let Some(Fd::File { buf, pos, .. }) = self.fds.get_mut(&fd) else { return ERRNO_BADF };
        let base = match whence {
            WHENCE_SET => 0i64,
            WHENCE_CUR => *pos as i64,
            WHENCE_END => buf.len() as i64,
            _ => return ERRNO_INVAL,
        };
        let np = base + offset;
        if np < 0 {
            return ERRNO_INVAL;
        }
        *pos = np as usize;
        if !Self::wr_u64(mem, newoffset, np as u64) {
            return ERRNO_FAULT;
        }
        ERRNO_SUCCESS
    }

    /// `fd_tell`: report the current file offset (a seek by 0 from the current pos).
    pub fn fd_tell<M: GuestMem>(&mut self, mem: &mut M, fd: u32, out: u32) -> i32 {
        self.fd_seek(mem, fd, 0, WHENCE_CUR, out)
    }

    /// `clock_res_get`: report a (coarse) clock resolution — 1 µs, in nanoseconds.
    /// wasi-libc queries this during clock setup; the value only bounds precision.
    pub fn clock_res_get<M: GuestMem>(&self, mem: &mut M, _id: u32, out: u32) -> i32 {
        if !Self::wr_u64(mem, out, 1000) {
            return ERRNO_FAULT;
        }
        ERRNO_SUCCESS
    }

    /// `path_open`: open `path` (relative to a preopen dir fd) and return a fresh
    /// fd. A write-open (rights include `fd_write`, or `O_CREAT`/`O_TRUNC`) starts
    /// from what is there unless `O_TRUNC`, as `fopen(…, "a")` expects; a read-open
    /// loads the file (ENOENT if absent).
    #[allow(clippy::too_many_arguments)]
    pub fn path_open<M: GuestMem>(
        &mut self,
        mem: &mut M,
        dirfd: u32,
        _dirflags: u32,
        path: u32,
        path_len: u32,
        oflags: i32,
        fs_rights_base: u64,
        _fs_rights_inheriting: u64,
        fdflags: i32,
        opened_fd: u32,
    ) -> i32 {
        let Some(bytes) = Self::rd_bytes(mem, path, path_len) else { return ERRNO_FAULT };
        let name = String::from_utf8_lossy(&bytes).into_owned();
        let vfs_path = self.resolve_at(dirfd, &name);

        // Directory open (libc `opendir`); store directories are implicit.
        if oflags & OFLAGS_DIRECTORY != 0 {
            let fd = self.next_fd;
            self.next_fd += 1;
            self.fds.insert(fd, Fd::Dir { vfs_path });
            return if Self::wr_u32(mem, opened_fd, fd) { ERRNO_SUCCESS } else { ERRNO_FAULT };
        }

        let writable = (fs_rights_base & RIGHTS_FD_WRITE) != 0
            || (oflags & (OFLAGS_CREAT | OFLAGS_TRUNC)) != 0;
        let file = if !crate::fs::IN_MEMORY {
            let mut o = std::fs::OpenOptions::new();
            o.read(true);
            if writable {
                o.write(true).create(oflags & OFLAGS_CREAT != 0).truncate(oflags & OFLAGS_TRUNC != 0);
                if fdflags & FDFLAGS_APPEND != 0 {
                    o.append(true);
                }
            }
            match o.open(&vfs_path) {
                Ok(file) => Fd::Native { file, path: vfs_path },
                Err(e) => {
                    return match e.kind() {
                        std::io::ErrorKind::NotFound => ERRNO_NOENT,
                        std::io::ErrorKind::PermissionDenied => ERRNO_ACCES,
                        _ => ERRNO_IO,
                    };
                }
            }
        } else if writable {
            let buf = match oflags & OFLAGS_TRUNC {
                0 => crate::fs::read(&vfs_path).unwrap_or_default(),
                _ => Vec::new(),
            };
            let mut flushed = buf.len();
            // C creates (or truncates) the file at `fopen`, not at the first write.
            if flushed == 0 {
                Self::flush_file(&vfs_path, &buf, &mut flushed);
            }
            Fd::File {
                vfs_path, buf, pos: 0, writable: true, dirty: true,
                append: fdflags & FDFLAGS_APPEND != 0, flushed,
            }
        } else {
            match crate::fs::read(&vfs_path) {
                Ok(buf) => Fd::File {
                    vfs_path, buf, pos: 0, writable: false, dirty: false, append: false, flushed: 0,
                },
                Err(_) => return ERRNO_NOENT,
            }
        };
        let fd = self.next_fd;
        self.next_fd += 1;
        self.fds.insert(fd, file);
        if !Self::wr_u32(mem, opened_fd, fd) {
            return ERRNO_FAULT;
        }
        ERRNO_SUCCESS
    }

    /// `fd_close`: write out what the fd still holds and drop it.
    pub fn fd_close(&mut self, fd: u32) -> i32 {
        match self.fds.remove(&fd) {
            Some(Fd::File { vfs_path, buf, writable: true, dirty: true, mut flushed, .. }) => {
                Self::flush_file(&vfs_path, &buf, &mut flushed);
                ERRNO_SUCCESS
            }
            Some(_) => ERRNO_SUCCESS,
            None => ERRNO_BADF,
        }
    }

    // ── filestat / fdstat / prestat ──────────────────────────────────────────

    /// `fd_fdstat_get`: fill a 24-byte `fdstat` (filetype, flags, rights).
    pub fn fd_fdstat_get<M: GuestMem>(&mut self, mem: &mut M, fd: u32, buf: u32) -> i32 {
        let filetype = match self.fds.get(&fd) {
            Some(Fd::Stdout | Fd::Stderr) => FILETYPE_CHARACTER_DEVICE,
            Some(Fd::PreopenDir { .. } | Fd::Dir { .. }) => FILETYPE_DIRECTORY,
            Some(Fd::File { .. } | Fd::Native { .. }) => FILETYPE_REGULAR_FILE,
            None => return ERRNO_BADF,
        };
        if !Self::wr_u8(mem, buf, filetype) {
            return ERRNO_FAULT;
        }
        let _ = Self::wr_u8(mem, buf + 1, 0); // fs_flags low byte
        let _ = Self::wr_u8(mem, buf + 2, 0);
        let _ = Self::wr_u8(mem, buf + 3, 0);
        let _ = Self::wr_u64(mem, buf + 8, u64::MAX); // fs_rights_base
        let _ = Self::wr_u64(mem, buf + 16, u64::MAX); // fs_rights_inheriting
        ERRNO_SUCCESS
    }

    /// `fd_filestat_get`: fill a 64-byte `filestat` for an open fd.
    pub fn fd_filestat_get<M: GuestMem>(&mut self, mem: &mut M, fd: u32, buf: u32) -> i32 {
        let (filetype, size, mtime, ino) = match self.fds.get(&fd) {
            Some(Fd::File { buf, vfs_path, .. }) => {
                (FILETYPE_REGULAR_FILE, buf.len() as u64, file_mtime(vfs_path), path_ino(vfs_path))
            }
            Some(Fd::Native { file, path }) => (
                FILETYPE_REGULAR_FILE,
                file.metadata().map(|m| m.len()).unwrap_or(0),
                file_mtime(path),
                path_ino(path),
            ),
            Some(Fd::PreopenDir { .. } | Fd::Dir { .. }) => (FILETYPE_DIRECTORY, 0, 0, 0),
            Some(Fd::Stdout | Fd::Stderr) => (FILETYPE_CHARACTER_DEVICE, 0, 0, 0),
            None => return ERRNO_BADF,
        };
        Self::write_filestat(mem, buf, filetype, size, mtime, ino)
    }

    /// `path_filestat_get`: stat a file by name relative to a preopen dir.
    pub fn path_filestat_get<M: GuestMem>(&mut self, mem: &mut M, dirfd: u32, _flags: u32, path: u32, path_len: u32, buf: u32) -> i32 {
        let Some(bytes) = Self::rd_bytes(mem, path, path_len) else { return ERRNO_FAULT };
        let vfs_path = self.resolve_at(dirfd, &String::from_utf8_lossy(&bytes));
        let mtime = file_mtime(&vfs_path);
        if crate::fs::is_dir(&vfs_path) {
            return Self::write_filestat(mem, buf, FILETYPE_DIRECTORY, 0, mtime, 0);
        }
        match crate::fs::len(&vfs_path) {
            Ok(n) => Self::write_filestat(mem, buf, FILETYPE_REGULAR_FILE, n, mtime, path_ino(&vfs_path)),
            Err(_) => ERRNO_NOENT,
        }
    }

    fn write_filestat<M: GuestMem>(mem: &mut M, buf: u32, filetype: u8, size: u64, mtime: u64, ino: u64) -> i32 {
        // dev(0) ino(8) filetype(16) nlink(24) size(32) atim(40) mtim(48) ctim(56)
        if mem.size() < buf as usize + 64 {
            return ERRNO_FAULT;
        }
        let _ = Self::wr_u64(mem, buf, 1); // every file is on the one device
        let _ = Self::wr_u64(mem, buf + 8, ino);
        let _ = Self::wr_u8(mem, buf + 16, filetype);
        let _ = Self::wr_u64(mem, buf + 24, 1); // nlink
        let _ = Self::wr_u64(mem, buf + 32, size);
        let _ = Self::wr_u64(mem, buf + 40, mtime);
        let _ = Self::wr_u64(mem, buf + 48, mtime);
        let _ = Self::wr_u64(mem, buf + 56, mtime);
        ERRNO_SUCCESS
    }

    // ── path mutations ───────────────────────────────────────────────────────

    pub fn path_create_directory<M: GuestMem>(&mut self, mem: &mut M, dirfd: u32, path: u32, path_len: u32) -> i32 {
        let Some(bytes) = Self::rd_bytes(mem, path, path_len) else { return ERRNO_FAULT };
        let dir = self.resolve_at(dirfd, &String::from_utf8_lossy(&bytes));
        // `mkdtemp` picks its name by the difference between EEXIST and a real error.
        if crate::fs::is_dir(&dir) || crate::fs::is_file(&dir) {
            return ERRNO_EXIST;
        }
        if crate::fs::create_dir_all(&dir).is_ok() { ERRNO_SUCCESS } else { ERRNO_NOENT }
    }

    /// `path_unlink_file`.
    pub fn path_unlink_file<M: GuestMem>(&mut self, mem: &mut M, dirfd: u32, path: u32, path_len: u32) -> i32 {
        let Some(bytes) = Self::rd_bytes(mem, path, path_len) else { return ERRNO_FAULT };
        let vfs_path = self.resolve_at(dirfd, &String::from_utf8_lossy(&bytes));
        if crate::fs::remove_file(&vfs_path).is_ok() { ERRNO_SUCCESS } else { ERRNO_NOENT }
    }

    /// `path_remove_directory`: the directory and everything under it.
    pub fn path_remove_directory<M: GuestMem>(&mut self, mem: &mut M, dirfd: u32, path: u32, path_len: u32) -> i32 {
        let Some(bytes) = Self::rd_bytes(mem, path, path_len) else { return ERRNO_FAULT };
        let dir = self.resolve_at(dirfd, &String::from_utf8_lossy(&bytes));
        if crate::fs::remove_dir_all(&dir).is_ok() { ERRNO_SUCCESS } else { ERRNO_NOENT }
    }

    /// `path_rename`: move a file or a whole subtree.
    #[allow(clippy::too_many_arguments)]
    pub fn path_rename<M: GuestMem>(&mut self, mem: &mut M, old_fd: u32, old_path: u32, old_len: u32, new_fd: u32, new_path: u32, new_len: u32) -> i32 {
        let Some(ob) = Self::rd_bytes(mem, old_path, old_len) else { return ERRNO_FAULT };
        let Some(nb) = Self::rd_bytes(mem, new_path, new_len) else { return ERRNO_FAULT };
        let from = self.resolve_at(old_fd, &String::from_utf8_lossy(&ob));
        let to = self.resolve_at(new_fd, &String::from_utf8_lossy(&nb));
        if crate::fs::rename(&from, &to).is_ok() { ERRNO_SUCCESS } else { ERRNO_NOENT }
    }

    /// `fd_prestat_get`: report the single preopen dir; EBADF for everything else
    /// so libc's startup scan terminates.
    pub fn fd_prestat_get<M: GuestMem>(&mut self, mem: &mut M, fd: u32, buf: u32) -> i32 {
        match self.fds.get(&fd) {
            Some(Fd::PreopenDir { name }) => {
                let _ = Self::wr_u8(mem, buf, 0); // prestat tag: dir
                if !Self::wr_u32(mem, buf + 4, name.len() as u32) {
                    return ERRNO_FAULT;
                }
                ERRNO_SUCCESS
            }
            _ => ERRNO_BADF,
        }
    }

    /// `fd_prestat_dir_name`: copy the preopen's name (`"."`) into the guest.
    pub fn fd_prestat_dir_name<M: GuestMem>(&mut self, mem: &mut M, fd: u32, path: u32, path_len: u32) -> i32 {
        let Some(Fd::PreopenDir { name }) = self.fds.get(&fd) else { return ERRNO_BADF };
        let bytes = name.as_bytes();
        let n = (path_len as usize).min(bytes.len());
        if !mem.write(path, &bytes[..n]) {
            return ERRNO_FAULT;
        }
        ERRNO_SUCCESS
    }

    // ── args / environ ───────────────────────────────────────────────────────

    pub fn args_sizes_get<M: GuestMem>(&mut self, mem: &mut M, argc: u32, buf_size: u32) -> i32 {
        let n = self.args.len() as u32;
        let size: u32 = self.args.iter().map(|a| a.len() as u32 + 1).sum();
        if !Self::wr_u32(mem, argc, n) || !Self::wr_u32(mem, buf_size, size) {
            return ERRNO_FAULT;
        }
        ERRNO_SUCCESS
    }

    pub fn args_get<M: GuestMem>(&mut self, mem: &mut M, argv: u32, buf: u32) -> i32 {
        let mut p = buf;
        for (i, a) in self.args.iter().enumerate() {
            if !Self::wr_u32(mem, argv + i as u32 * 4, p) {
                return ERRNO_FAULT;
            }
            let bytes = a.as_bytes();
            if !mem.write(p, bytes) || !Self::wr_u8(mem, p + bytes.len() as u32, 0) {
                return ERRNO_FAULT;
            }
            p += bytes.len() as u32 + 1;
        }
        ERRNO_SUCCESS
    }

    /// No environment is exposed.
    pub fn environ_sizes_get<M: GuestMem>(&mut self, mem: &mut M, count: u32, buf_size: u32) -> i32 {
        if !Self::wr_u32(mem, count, 0) || !Self::wr_u32(mem, buf_size, 0) {
            return ERRNO_FAULT;
        }
        ERRNO_SUCCESS
    }
    pub fn environ_get<M: GuestMem>(&mut self, _mem: &mut M, _environ: u32, _buf: u32) -> i32 {
        ERRNO_SUCCESS
    }

    // ── misc ─────────────────────────────────────────────────────────────────

    /// `clock_time_get`: real time, so a guest sees a clock consistent with file
    /// mtimes. `MONOTONIC` reads an `Instant` (never backwards); everything else
    /// (`REALTIME` and the cputime clocks) reads the wall clock — the same source
    /// as the store's mtimes. Sim reproducibility is the seeded RNG's job, not a
    /// frozen clock.
    pub fn clock_time_get<M: GuestMem>(&mut self, mem: &mut M, id: u32, _precision: u64, time: u32) -> i32 {
        const CLOCKID_MONOTONIC: u32 = 1;
        let nanos = if id == CLOCKID_MONOTONIC {
            crate::monotonic_nanos()
        } else {
            crate::realtime_nanos()
        };
        if !Self::wr_u64(mem, time, nanos) {
            return ERRNO_FAULT;
        }
        ERRNO_SUCCESS
    }

    /// `random_get`: real entropy (OS RNG natively, Web Crypto on wasm via
    /// getrandom). Simulations that need reproducible draws use explicit seeds,
    /// so the host RNG here doesn't compromise that. Falls back to a deterministic
    /// fill if the host RNG is somehow unavailable, so libc HashMap seeding can't
    /// hard-fail at startup.
    pub fn random_get<M: GuestMem>(&mut self, mem: &mut M, buf: u32, len: u32) -> i32 {
        let mut bytes = vec![0u8; len as usize];
        if getrandom::fill(&mut bytes).is_err() {
            for (i, b) in bytes.iter_mut().enumerate() {
                *b = (i as u8).wrapping_mul(31).wrapping_add(17);
            }
        }
        for (i, b) in bytes.iter().enumerate() {
            if !Self::wr_u8(mem, buf + i as u32, *b) {
                return ERRNO_FAULT;
            }
        }
        ERRNO_SUCCESS
    }

    // ── fd_readdir (ABI) ─────────────────────────────────────────────────────

    /// `fd_readdir`: enumerate a directory fd into the guest buffer as a packed
    /// run of `dirent` headers (`d_next:u64, d_ino:u64, d_namlen:u32, d_type:u8`,
    /// 24-byte aligned) each followed by the entry name. `cookie` is the index to
    /// resume from (a header's `d_next`); `bufused < buf_len` means the directory
    /// was fully read. Only the preopen dir is enumerable (it maps to `cwd`).
    pub fn fd_readdir<M: GuestMem>(&mut self, mem: &mut M, fd: u32, buf: u32, buf_len: u32, cookie: u64, bufused: u32) -> i32 {
        let dir_key = match self.fds.get(&fd) {
            Some(Fd::PreopenDir { .. }) => self.cwd.clone(),
            Some(Fd::Dir { vfs_path }) => vfs_path.clone(),
            _ => return ERRNO_BADF,
        };
        let mut entries = crate::fs::read_dir(&dir_key).unwrap_or_default();
        entries.sort_by(|a, b| a.name.cmp(&b.name));
        const HDR: u32 = 24;
        let mut written = 0u32;
        let mut idx = cookie;
        while (idx as usize) < entries.len() {
            let e = &entries[idx as usize];
            let name = e.name.as_bytes();
            if written + HDR > buf_len {
                break; // not even the header fits; signal "more" via bufused == buf_len
            }
            let next = idx + 1;
            let _ = Self::wr_u64(mem, buf + written, next);
            let _ = Self::wr_u64(mem, buf + written + 8, 0); // d_ino (unused)
            let _ = Self::wr_u32(mem, buf + written + 16, name.len() as u32);
            let ty = if e.is_dir { FILETYPE_DIRECTORY } else { FILETYPE_REGULAR_FILE };
            let _ = Self::wr_u8(mem, buf + written + 20, ty);
            written += HDR;
            let avail = buf_len - written;
            let n = (name.len() as u32).min(avail);
            if n > 0 && !mem.write(buf + written, &name[..n as usize]) {
                return ERRNO_FAULT;
            }
            written += n;
            if n < name.len() as u32 {
                break; // name truncated; caller grows the buffer and retries
            }
            idx = next;
        }
        if !Self::wr_u32(mem, bufused, written) {
            return ERRNO_FAULT;
        }
        ERRNO_SUCCESS
    }

    // ── high-level helpers (plain Rust values; absolute keys) ────────────────
    //
    // A host read is the spec flow path_open → fd_read → fd_close, for a caller
    // that cannot pass guest pointers. Stat/listing by path are `stat_size` /
    // `readdir` below.

    /// preview1 `path_open` for a read-only open of the absolute key `path`.
    /// Returns the new fd, or `None` (ENOENT) if the file is absent.
    pub fn open_read(&mut self, path: &str) -> Option<u32> {
        let buf = crate::fs::read(path).ok()?;
        let fd = self.next_fd;
        self.next_fd += 1;
        self.fds.insert(fd, Fd::File {
            vfs_path: path.to_string(), buf, pos: 0, writable: false, dirty: false, append: false, flushed: 0,
        });
        Some(fd)
    }

    /// Whole contents of an open read fd (a one-shot `fd_read`), or `None` for a
    /// bad/non-file fd.
    pub fn read_all(&self, fd: u32) -> Option<Vec<u8>> {
        match self.fds.get(&fd) {
            Some(Fd::File { buf, .. }) => Some(buf.clone()),
            _ => None,
        }
    }

    /// preview1 `fd_close` for the high-level callers.
    pub fn close(&mut self, fd: u32) -> i32 {
        self.fd_close(fd)
    }
}

/// A regular file's `st_ino`, from its path so the same file keeps it across
/// opens. HDF5's sec2 driver identifies an open file by `st_dev`/`st_ino`, so
/// the pair has to differ between files. Never 0, which means "no inode".
fn path_ino(path: &str) -> u64 {
    use std::hash::{Hash, Hasher};
    let mut h = std::collections::hash_map::DefaultHasher::new();
    path.hash(&mut h);
    h.finish() | 1
}

/// `filestat`'s `mtim`: nanoseconds since the epoch, 0 for anything without one.
fn file_mtime(path: &str) -> u64 {
    crate::fs::modified(path)
        .ok()
        .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
        .map(|d| d.as_nanos() as u64)
        .unwrap_or(0)
}

/// One directory entry from [`readdir`].
#[derive(Clone, Debug)]
pub struct DirEntry {
    pub name: String,
    pub is_dir: bool,
}

/// Immediate children of directory `dir` (an absolute VFS path; `"/"` is the
/// root), deduplicated and sorted. Robust to the root prefix, which the raw
/// [`crate::list_dir`] mishandles.
pub fn readdir(dir: &str) -> Vec<DirEntry> {
    let norm = crate::normalize(dir);
    let prefix = if norm == "/" { String::from("/") } else { format!("{norm}/") };
    let mut seen: std::collections::BTreeMap<String, bool> = std::collections::BTreeMap::new();
    for key in crate::list() {
        let Some(rest) = key.strip_prefix(&prefix) else { continue };
        if rest.is_empty() {
            continue;
        }
        match rest.split_once('/') {
            Some((child, _)) => {
                seen.insert(child.to_string(), true);
            }
            None => {
                seen.entry(rest.to_string()).or_insert(false);
            }
        }
    }
    seen.into_iter().map(|(name, is_dir)| DirEntry { name, is_dir }).collect()
}

/// Size in bytes of the file at absolute key `path`, or `None` if absent —
/// preview1 `path_filestat_get`'s `size` field, by path.
pub fn stat_size(path: &str) -> Option<u64> {
    crate::read(path).map(|b| b.len() as u64)
}

#[cfg(test)]
mod path_ops_tests {
    use super::*;

    fn put(mem: &mut [u8], at: usize, s: &str) -> (u32, u32) {
        mem[at..at + s.len()].copy_from_slice(s.as_bytes());
        (at as u32, s.len() as u32)
    }

    #[test]
    fn path_mutations_and_dir_fd() {
        let root = if crate::fs::IN_MEMORY {
            "/wasi_pathops".to_string()
        } else {
            format!("{}/om-wasi-pathops-{}", std::env::temp_dir().display(), std::process::id())
        };
        crate::fs::create_dir_all(&root).unwrap();
        crate::fs::write(&format!("{root}/a.txt"), b"AAA").unwrap();
        crate::fs::write(&format!("{root}/b.txt"), b"BBB").unwrap();

        let mut ctx = WasiCtx::new("", vec!["t".into()]);
        let mut buf = vec![0u8; 8192];
        let mut mem = SliceMem(&mut buf);

        let (op, ol) = put(mem.0, 0, &format!("{root}/a.txt"));
        let (np, nl) = put(mem.0, 1024, &format!("{root}/c.txt"));
        assert_eq!(ctx.path_rename(&mut mem, 3, op, ol, 3, np, nl), ERRNO_SUCCESS);
        assert_eq!(crate::fs::read(&format!("{root}/c.txt")).unwrap(), b"AAA");
        assert!(crate::fs::read(&format!("{root}/a.txt")).is_err());

        let (p, l) = put(mem.0, 2048, &format!("{root}/b.txt"));
        assert_eq!(ctx.path_unlink_file(&mut mem, 3, p, l), ERRNO_SUCCESS);
        assert_eq!(ctx.path_unlink_file(&mut mem, 3, p, l), ERRNO_NOENT);

        let (dp, dl) = put(mem.0, 3072, &root);
        assert_eq!(ctx.path_open(&mut mem, 3, 0, dp, dl, OFLAGS_DIRECTORY, 0, 0, 0, 4000), ERRNO_SUCCESS);
        let dfd = WasiCtx::rd_u32(&mem, 4000).unwrap();
        assert_eq!(ctx.fd_readdir(&mut mem, dfd, 4096, 512, 0, 4004), ERRNO_SUCCESS);
        let used = WasiCtx::rd_u32(&mem, 4004).unwrap() as usize;
        assert!(mem.0[4096..4096 + used].windows(5).any(|w| w == b"c.txt"));

        // A directory stats as one, and `fopen(…, "a")` keeps what is there.
        assert_eq!(ctx.path_filestat_get(&mut mem, 3, 0, dp, dl, 5000), ERRNO_SUCCESS);
        assert_eq!(mem.0[5000 + 16], FILETYPE_DIRECTORY);
        let (ap, al) = put(mem.0, 6000, &format!("{root}/c.txt"));
        assert_eq!(
            ctx.path_open(&mut mem, 3, 0, ap, al, OFLAGS_CREAT, RIGHTS_FD_WRITE, 0, FDFLAGS_APPEND, 6100),
            ERRNO_SUCCESS
        );
        let afd = WasiCtx::rd_u32(&mem, 6100).unwrap();
        let (wp, wl) = put(mem.0, 6200, "BBB");
        let _ = WasiCtx::wr_u32(&mut mem, 6300, wp);
        let _ = WasiCtx::wr_u32(&mut mem, 6304, wl);
        assert_eq!(ctx.fd_write(&mut mem, afd, 6300, 1, 6400), ERRNO_SUCCESS);
        assert_eq!(ctx.fd_close(afd), ERRNO_SUCCESS);
        assert_eq!(crate::fs::read(&format!("{root}/c.txt")).unwrap(), b"AAABBB");

        let (rp, rl) = put(mem.0, 7000, &root);
        assert_eq!(ctx.path_remove_directory(&mut mem, 3, rp, rl), ERRNO_SUCCESS);
        assert!(crate::fs::read(&format!("{root}/c.txt")).is_err());

        let (cp, cl) = put(mem.0, 7200, &format!("{root}/newdir"));
        assert_eq!(ctx.path_create_directory(&mut mem, 3, cp, cl), ERRNO_SUCCESS);
        assert!(crate::fs::is_dir(&format!("{root}/newdir")) || crate::fs::IN_MEMORY);
        let _ = crate::fs::remove_dir_all(&root);
    }

    /// `fd_pread`/`fd_pwrite`: HDF5's sec2 driver does every access this way.
    #[test]
    fn positioned_read_write() {
        let root = if crate::fs::IN_MEMORY {
            "/wasi_pio".to_string()
        } else {
            format!("{}/om-wasi-pio-{}", std::env::temp_dir().display(), std::process::id())
        };
        crate::fs::create_dir_all(&root).unwrap();

        let mut ctx = WasiCtx::new("", vec!["t".into()]);
        let mut buf = vec![0u8; 8192];
        let mut mem = SliceMem(&mut buf);

        let (p, l) = put(mem.0, 0, &format!("{root}/h5.bin"));
        assert_eq!(ctx.path_open(&mut mem, 3, 0, p, l, OFLAGS_CREAT, RIGHTS_FD_WRITE, 0, 0, 512), ERRNO_SUCCESS);
        let fd = WasiCtx::rd_u32(&mem, 512).unwrap();

        // One iovec at 600 pointing at the payload at 700.
        let iov = |mem: &mut SliceMem, s: &str| {
            let (dp, dl) = put(mem.0, 700, s);
            let _ = WasiCtx::wr_u32(mem, 600, dp);
            let _ = WasiCtx::wr_u32(mem, 604, dl);
        };

        // Writing past the end zero-fills and leaves the offset where it was.
        iov(&mut mem, "HELLO");
        assert_eq!(ctx.fd_pwrite(&mut mem, fd, 600, 1, 2048, 800), ERRNO_SUCCESS);
        assert_eq!(WasiCtx::rd_u32(&mem, 800), Some(5));
        assert_eq!(ctx.fd_tell(&mut mem, fd, 804), ERRNO_SUCCESS);
        assert_eq!(WasiCtx::rd_u32(&mem, 804), Some(0));

        // A plain write still advances it, and does not disturb the far data.
        iov(&mut mem, "abc");
        assert_eq!(ctx.fd_write(&mut mem, fd, 600, 1, 800), ERRNO_SUCCESS);
        assert_eq!(ctx.fd_tell(&mut mem, fd, 804), ERRNO_SUCCESS);
        assert_eq!(WasiCtx::rd_u32(&mem, 804), Some(3));

        // Reading back leaves the position put; past the end is short, not an error.
        let _ = WasiCtx::wr_u32(&mut mem, 600, 900);
        let _ = WasiCtx::wr_u32(&mut mem, 604, 5);
        assert_eq!(ctx.fd_pread(&mut mem, fd, 600, 1, 2048, 800), ERRNO_SUCCESS);
        assert_eq!(WasiCtx::rd_u32(&mem, 800), Some(5));
        assert_eq!(&mem.0[900..905], b"HELLO");
        assert_eq!(ctx.fd_tell(&mut mem, fd, 804), ERRNO_SUCCESS);
        assert_eq!(WasiCtx::rd_u32(&mem, 804), Some(3));
        assert_eq!(ctx.fd_pread(&mut mem, fd, 600, 1, 2051, 800), ERRNO_SUCCESS);
        assert_eq!(WasiCtx::rd_u32(&mem, 800), Some(2));

        assert_eq!(ctx.fd_pwrite(&mut mem, fd, 600, 1, -1, 800), ERRNO_INVAL);
        assert_eq!(ctx.fd_pwrite(&mut mem, 1, 600, 1, 0, 800), ERRNO_SPIPE);
        assert_eq!(ctx.fd_pread(&mut mem, 99, 600, 1, 0, 800), ERRNO_BADF);

        assert_eq!(ctx.fd_close(fd), ERRNO_SUCCESS);
        let out = crate::fs::read(&format!("{root}/h5.bin")).unwrap();
        assert_eq!(out.len(), 2053);
        assert_eq!(&out[0..3], b"abc");
        assert_eq!(&out[3..2048], &vec![0u8; 2045][..]);
        assert_eq!(&out[2048..], b"HELLO");
        let _ = crate::fs::remove_dir_all(&root);
    }

    /// `st_dev`/`st_ino` have to tell two files apart and survive a reopen.
    #[test]
    fn filestat_identity() {
        let root = if crate::fs::IN_MEMORY {
            "/wasi_ino".to_string()
        } else {
            format!("{}/om-wasi-ino-{}", std::env::temp_dir().display(), std::process::id())
        };
        crate::fs::create_dir_all(&root).unwrap();
        crate::fs::write(&format!("{root}/a.bin"), b"A").unwrap();
        crate::fs::write(&format!("{root}/b.bin"), b"B").unwrap();

        let mut ctx = WasiCtx::new("", vec!["t".into()]);
        let mut buf = vec![0u8; 8192];
        let mut mem = SliceMem(&mut buf);

        let stat = |ctx: &mut WasiCtx, mem: &mut SliceMem, name: &str, at: usize| -> (u64, u64) {
            let (p, l) = put(mem.0, at, &format!("{root}/{name}"));
            assert_eq!(ctx.path_filestat_get(mem, 3, 0, p, l, 4096), ERRNO_SUCCESS);
            let dev = u64::from_le_bytes(mem.0[4096..4104].try_into().unwrap());
            let ino = u64::from_le_bytes(mem.0[4104..4112].try_into().unwrap());
            (dev, ino)
        };

        let (dev_a, ino_a) = stat(&mut ctx, &mut mem, "a.bin", 0);
        let (dev_b, ino_b) = stat(&mut ctx, &mut mem, "b.bin", 512);
        let (_, ino_a2) = stat(&mut ctx, &mut mem, "a.bin", 1024);
        assert_ne!(dev_a, 0);
        assert_eq!(dev_a, dev_b);
        assert_ne!(ino_a, 0);
        assert_ne!(ino_a, ino_b);
        assert_eq!(ino_a, ino_a2);

        // An open fd reports the same identity as the name does.
        let (p, l) = put(mem.0, 2048, &format!("{root}/a.bin"));
        assert_eq!(ctx.path_open(&mut mem, 3, 0, p, l, 0, 0, 0, 0, 2200), ERRNO_SUCCESS);
        let fd = WasiCtx::rd_u32(&mem, 2200).unwrap();
        assert_eq!(ctx.fd_filestat_get(&mut mem, fd, 4096), ERRNO_SUCCESS);
        assert_eq!(u64::from_le_bytes(mem.0[4104..4112].try_into().unwrap()), ino_a);

        // A directory has no inode either way round, so the two never disagree.
        crate::fs::create_dir_all(&format!("{root}/sub")).unwrap();
        let (_, ino_dir) = stat(&mut ctx, &mut mem, "sub", 3072);
        assert_eq!(ino_dir, 0);
        assert_eq!(ctx.fd_filestat_get(&mut mem, 3, 4096), ERRNO_SUCCESS);
        assert_eq!(u64::from_le_bytes(mem.0[4104..4112].try_into().unwrap()), 0);
        let _ = crate::fs::remove_dir_all(&root);
    }
}
