// A minimal hand-written `wasi_snapshot_preview1` shim backed by
// `openmodelica_vfs`, for running the standalone wasm32-wasip1 *command* module
// the wasm-jit target will emit (its `_start` writes `<model>_res.mat` through
// WASI). The same module is meant to run two ways:
//   * natively under `wasmtime run model.wasm --dir .::.` (real WASI, real FS);
//   * in the OMEdit worker over this shim, where there is no OS filesystem and
//     files live in `openmodelica_vfs` instead.
// This file is the second path. Only the surface a result-writing command
// module actually touches is implemented (file create/write/close, the preopen
// dance libc does at startup, args/environ, exit); everything else returns a
// sane errno so a stray call fails gracefully rather than trapping.
//
// The `WasiCtx` logic is engine-independent — it accesses the guest's linear
// memory through the `GuestMem` trait (a zero-copy `&mut [u8]` slice for
// wasmtime, a copy-based `MemoryView` for wasmer's js backend) plus its own fd
// table — so both registrations (`wasmtime_impl::add_to_linker` and
// `wasmer_impl::add_to_imports`) share it verbatim. wasmtime is the native
// default (and the only one testable without a browser); wasmer drives the
// OMEdit worker and native-wasmer.

use std::collections::HashMap;

use anyhow::{Result, anyhow};

// ─────────────────────────────── WASI constants ──────────────────────────────

// errno (`__wasi_errno_t`): 0 is success.
const ERRNO_SUCCESS: i32 = 0;
const ERRNO_BADF: i32 = 8;
const ERRNO_FAULT: i32 = 21;
const ERRNO_INVAL: i32 = 28;
const ERRNO_NOENT: i32 = 44;

// filetype (`__wasi_filetype_t`).
const FILETYPE_CHARACTER_DEVICE: u8 = 2;
const FILETYPE_DIRECTORY: u8 = 3;
const FILETYPE_REGULAR_FILE: u8 = 4;

// oflags (`__wasi_oflags_t`) bits passed to `path_open`.
const OFLAGS_CREAT: i32 = 1 << 0;
const OFLAGS_TRUNC: i32 = 1 << 3;

// rights (`__wasi_rights_t`) bit for `fd_write`; used to tell a write-open from a
// read-open in `path_open`.
const RIGHTS_FD_WRITE: u64 = 1 << 6;

// `fd_seek` whence.
const WHENCE_SET: i32 = 0;
const WHENCE_CUR: i32 = 1;
const WHENCE_END: i32 = 2;

/// The first preopened directory fd. fds 0/1/2 are stdin/stdout/stderr; libc
/// scans upward from 3 calling `fd_prestat_get` until it gets `EBADF`.
const PREOPEN_FD: u32 = 3;

// ───────────────────────────────── fd table ──────────────────────────────────

/// One open file descriptor.
enum Fd {
    /// fd 1 / fd 2 — captured to the host's stdout/stderr.
    Stdout,
    Stderr,
    /// The single preopened directory (fd 3), exposed under `name` (`"."`).
    PreopenDir { name: String },
    /// A regular file. Writable files buffer in `buf` and flush to the VFS on
    /// close; read files are loaded from the VFS at `path_open`.
    File {
        vfs_path: String,
        buf: Vec<u8>,
        pos: usize,
        writable: bool,
        dirty: bool,
    },
}

/// Per-run WASI state: the fd table, the directory relative paths resolve
/// against, the program arguments, and the exit code captured from `proc_exit`.
pub struct WasiCtx {
    /// Directory that `path_open` resolves relative names against — the VFS key
    /// prefix. Empty means relative names map to bare VFS keys (matching how
    /// omc's `File` runtime keys files today, with no cwd on wasm).
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
struct SliceMem<'a>(&'a mut [u8]);
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
    /// A context whose preopen `"."` maps to `cwd` in the VFS (use `""` for bare
    /// keys) and whose `argv` is `args` (typically just the program name).
    pub fn new(cwd: impl Into<String>, args: Vec<String>) -> Self {
        let mut fds = HashMap::new();
        fds.insert(1, Fd::Stdout);
        fds.insert(2, Fd::Stderr);
        fds.insert(PREOPEN_FD, Fd::PreopenDir { name: ".".to_string() });
        WasiCtx { cwd: cwd.into(), next_fd: PREOPEN_FD + 1, fds, args, exit_code: None }
    }

    /// Map a guest-supplied relative path onto its VFS key.
    fn resolve(&self, name: &str) -> String {
        let name = name.strip_prefix("./").unwrap_or(name);
        if self.cwd.is_empty() {
            name.to_string()
        } else {
            format!("{}/{}", self.cwd, name)
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
            Some(Fd::Stdout) => print!("{}", String::from_utf8_lossy(&gathered)),
            Some(Fd::Stderr) => eprint!("{}", String::from_utf8_lossy(&gathered)),
            Some(Fd::File { buf, pos, writable: true, dirty, .. }) => {
                let end = *pos + gathered.len();
                if buf.len() < end {
                    buf.resize(end, 0);
                }
                buf[*pos..end].copy_from_slice(&gathered);
                *pos = end;
                *dirty = true;
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
        let Some(Fd::File { buf, pos, .. }) = self.fds.get_mut(&fd) else { return ERRNO_BADF };
        let mut total = 0u32;
        for i in 0..iovs_len {
            let base = iovs + i * 8;
            let Some(dst) = Self::rd_u32(mem, base) else { return ERRNO_FAULT };
            let Some(len) = Self::rd_u32(mem, base + 4) else { return ERRNO_FAULT };
            let avail = buf.len().saturating_sub(*pos);
            let n = (len as usize).min(avail);
            if n == 0 {
                continue;
            }
            if !mem.write(dst, &buf[*pos..*pos + n]) {
                return ERRNO_FAULT;
            }
            *pos += n;
            total += n as u32;
        }
        if !Self::wr_u32(mem, nread, total) {
            return ERRNO_FAULT;
        }
        ERRNO_SUCCESS
    }

    /// `fd_seek`: reposition the fd and report the new offset.
    pub fn fd_seek<M: GuestMem>(&mut self, mem: &mut M, fd: u32, offset: i64, whence: i32, newoffset: u32) -> i32 {
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

    /// `path_open`: open `path` (relative to a preopen dir fd) and return a fresh
    /// fd. A write-open (rights include `fd_write`, or `O_CREAT`/`O_TRUNC`)
    /// starts an empty buffer that flushes to the VFS on close; a read-open loads
    /// the file from the VFS (ENOENT if absent).
    #[allow(clippy::too_many_arguments)]
    pub fn path_open<M: GuestMem>(
        &mut self,
        mem: &mut M,
        _dirfd: u32,
        _dirflags: u32,
        path: u32,
        path_len: u32,
        oflags: i32,
        fs_rights_base: u64,
        _fs_rights_inheriting: u64,
        _fdflags: i32,
        opened_fd: u32,
    ) -> i32 {
        let Some(bytes) = Self::rd_bytes(mem, path, path_len) else { return ERRNO_FAULT };
        let name = String::from_utf8_lossy(&bytes).into_owned();
        let vfs_path = self.resolve(&name);

        let writable = (fs_rights_base & RIGHTS_FD_WRITE) != 0
            || (oflags & (OFLAGS_CREAT | OFLAGS_TRUNC)) != 0;
        let file = if writable {
            Fd::File { vfs_path, buf: Vec::new(), pos: 0, writable: true, dirty: true }
        } else {
            match openmodelica_vfs::read(&vfs_path) {
                Some(buf) => Fd::File { vfs_path, buf, pos: 0, writable: false, dirty: false },
                None => return ERRNO_NOENT,
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

    /// `fd_close`: flush a dirty writable file to the VFS and drop the fd.
    pub fn fd_close(&mut self, fd: u32) -> i32 {
        match self.fds.remove(&fd) {
            Some(Fd::File { vfs_path, buf, writable: true, dirty: true, .. }) => {
                openmodelica_vfs::write(&vfs_path, buf);
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
            Some(Fd::PreopenDir { .. }) => FILETYPE_DIRECTORY,
            Some(Fd::File { .. }) => FILETYPE_REGULAR_FILE,
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
        let (filetype, size) = match self.fds.get(&fd) {
            Some(Fd::File { buf, .. }) => (FILETYPE_REGULAR_FILE, buf.len() as u64),
            Some(Fd::PreopenDir { .. }) => (FILETYPE_DIRECTORY, 0),
            Some(Fd::Stdout | Fd::Stderr) => (FILETYPE_CHARACTER_DEVICE, 0),
            None => return ERRNO_BADF,
        };
        Self::write_filestat(mem, buf, filetype, size)
    }

    /// `path_filestat_get`: stat a file by name relative to a preopen dir.
    pub fn path_filestat_get<M: GuestMem>(&mut self, mem: &mut M, _dirfd: u32, _flags: u32, path: u32, path_len: u32, buf: u32) -> i32 {
        let Some(bytes) = Self::rd_bytes(mem, path, path_len) else { return ERRNO_FAULT };
        let vfs_path = self.resolve(&String::from_utf8_lossy(&bytes));
        match openmodelica_vfs::read(&vfs_path) {
            Some(b) => Self::write_filestat(mem, buf, FILETYPE_REGULAR_FILE, b.len() as u64),
            None => ERRNO_NOENT,
        }
    }

    fn write_filestat<M: GuestMem>(mem: &mut M, buf: u32, filetype: u8, size: u64) -> i32 {
        // dev(0) ino(8) filetype(16) nlink(24) size(32) atim(40) mtim(48) ctim(56)
        if mem.size() < buf as usize + 64 {
            return ERRNO_FAULT;
        }
        let _ = Self::wr_u64(mem, buf, 0);
        let _ = Self::wr_u64(mem, buf + 8, 0);
        let _ = Self::wr_u8(mem, buf + 16, filetype);
        let _ = Self::wr_u64(mem, buf + 24, 1); // nlink
        let _ = Self::wr_u64(mem, buf + 32, size);
        let _ = Self::wr_u64(mem, buf + 40, 0);
        let _ = Self::wr_u64(mem, buf + 48, 0);
        let _ = Self::wr_u64(mem, buf + 56, 0);
        ERRNO_SUCCESS
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

    pub fn clock_time_get<M: GuestMem>(&mut self, mem: &mut M, _id: u32, _precision: u64, time: u32) -> i32 {
        if !Self::wr_u64(mem, time, 0) {
            return ERRNO_FAULT;
        }
        ERRNO_SUCCESS
    }

    /// Deterministic "randomness": enough for libc's HashMap seeding without
    /// pulling in a host RNG (the simulation result is reproducible anyway).
    pub fn random_get<M: GuestMem>(&mut self, mem: &mut M, buf: u32, len: u32) -> i32 {
        for i in 0..len {
            if !Self::wr_u8(mem, buf + i, (i as u8).wrapping_mul(31).wrapping_add(17)) {
                return ERRNO_FAULT;
            }
        }
        ERRNO_SUCCESS
    }
}

// ─────────────────────────── wasmtime registration ───────────────────────────
//
// Native default engine. Host functions reach the guest memory and the fd table
// together via `Memory::data_and_store_mut`, which hands back
// `(&mut [u8], &mut WasiCtx)` from the `Caller`. `proc_exit` records its code and
// traps; `run_command` turns that trap back into the exit code.

#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
mod wasmtime_impl {
    use super::*;
    use wasmtime::Caller;

    type Linker = wasmtime::Linker<WasiCtx>;

    /// Borrow `(SliceMem, ctx)` from the caller, or return ERRNO_FAULT if the
    /// guest exports no `memory`.
    macro_rules! mem_ctx {
        ($caller:expr) => {{
            match $caller.get_export("memory").and_then(|e| e.into_memory()) {
                Some(m) => {
                    let (data, ctx) = m.data_and_store_mut(&mut $caller);
                    (SliceMem(data), ctx)
                }
                None => return ERRNO_FAULT,
            }
        }};
    }

    /// Register the `wasi_snapshot_preview1` imports into `linker`.
    pub fn add_to_linker(linker: &mut Linker) -> Result<()> {
        let m = "wasi_snapshot_preview1";
        let wt = |r: std::result::Result<&mut Linker, wasmtime::Error>| r.map(|_| ()).map_err(|e| anyhow!("{e:?}"));

        wt(linker.func_wrap(m, "fd_write", |mut c: Caller<'_, WasiCtx>, fd: i32, iovs: i32, n: i32, nw: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.fd_write(&mut mem, fd as u32, iovs as u32, n as u32, nw as u32)
        }))?;
        wt(linker.func_wrap(m, "fd_read", |mut c: Caller<'_, WasiCtx>, fd: i32, iovs: i32, n: i32, nr: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.fd_read(&mut mem, fd as u32, iovs as u32, n as u32, nr as u32)
        }))?;
        wt(linker.func_wrap(m, "fd_seek", |mut c: Caller<'_, WasiCtx>, fd: i32, off: i64, whence: i32, no: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.fd_seek(&mut mem, fd as u32, off, whence, no as u32)
        }))?;
        wt(linker.func_wrap(m, "path_open", |mut c: Caller<'_, WasiCtx>, dirfd: i32, dirflags: i32, path: i32, plen: i32, oflags: i32, rb: i64, ri: i64, fdflags: i32, ofd: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.path_open(&mut mem, dirfd as u32, dirflags as u32, path as u32, plen as u32, oflags, rb as u64, ri as u64, fdflags, ofd as u32)
        }))?;
        wt(linker.func_wrap(m, "path_filestat_get", |mut c: Caller<'_, WasiCtx>, dirfd: i32, flags: i32, path: i32, plen: i32, buf: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.path_filestat_get(&mut mem, dirfd as u32, flags as u32, path as u32, plen as u32, buf as u32)
        }))?;
        wt(linker.func_wrap(m, "fd_filestat_get", |mut c: Caller<'_, WasiCtx>, fd: i32, buf: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.fd_filestat_get(&mut mem, fd as u32, buf as u32)
        }))?;
        wt(linker.func_wrap(m, "fd_fdstat_get", |mut c: Caller<'_, WasiCtx>, fd: i32, buf: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.fd_fdstat_get(&mut mem, fd as u32, buf as u32)
        }))?;
        wt(linker.func_wrap(m, "fd_fdstat_set_flags", |_c: Caller<'_, WasiCtx>, _fd: i32, _flags: i32| -> i32 {
            ERRNO_SUCCESS
        }))?;
        wt(linker.func_wrap(m, "fd_close", |mut c: Caller<'_, WasiCtx>, fd: i32| -> i32 {
            c.data_mut().fd_close(fd as u32)
        }))?;
        wt(linker.func_wrap(m, "fd_prestat_get", |mut c: Caller<'_, WasiCtx>, fd: i32, buf: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.fd_prestat_get(&mut mem, fd as u32, buf as u32)
        }))?;
        wt(linker.func_wrap(m, "fd_prestat_dir_name", |mut c: Caller<'_, WasiCtx>, fd: i32, path: i32, plen: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.fd_prestat_dir_name(&mut mem, fd as u32, path as u32, plen as u32)
        }))?;
        wt(linker.func_wrap(m, "args_sizes_get", |mut c: Caller<'_, WasiCtx>, argc: i32, bs: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.args_sizes_get(&mut mem, argc as u32, bs as u32)
        }))?;
        wt(linker.func_wrap(m, "args_get", |mut c: Caller<'_, WasiCtx>, argv: i32, buf: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.args_get(&mut mem, argv as u32, buf as u32)
        }))?;
        wt(linker.func_wrap(m, "environ_sizes_get", |mut c: Caller<'_, WasiCtx>, count: i32, bs: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.environ_sizes_get(&mut mem, count as u32, bs as u32)
        }))?;
        wt(linker.func_wrap(m, "environ_get", |mut c: Caller<'_, WasiCtx>, env: i32, buf: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.environ_get(&mut mem, env as u32, buf as u32)
        }))?;
        wt(linker.func_wrap(m, "clock_time_get", |mut c: Caller<'_, WasiCtx>, id: i32, prec: i64, time: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.clock_time_get(&mut mem, id as u32, prec as u64, time as u32)
        }))?;
        wt(linker.func_wrap(m, "random_get", |mut c: Caller<'_, WasiCtx>, buf: i32, len: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.random_get(&mut mem, buf as u32, len as u32)
        }))?;
        // `proc_exit` is a normal termination: record the code and unwind via a
        // wasmtime error, which `run_command` turns back into the exit code.
        wt(linker.func_wrap(m, "proc_exit", |mut c: Caller<'_, WasiCtx>, code: i32| -> std::result::Result<(), wasmtime::Error> {
            c.data_mut().exit_code = Some(code as u32);
            Err(wasmtime::Error::msg("wasi proc_exit"))
        }))?;
        Ok(())
    }

    /// Instantiate `wasm` as a WASI command module and call `_start`, returning
    /// the process exit code (0 if `_start` returns normally). Files land in
    /// `openmodelica_vfs`, with relative paths keyed under `cwd`.
    pub fn run_command(wasm: &[u8], cwd: &str, args: Vec<String>) -> Result<u32> {
        let engine = wasmtime::Engine::default();
        let module = wasmtime::Module::new(&engine, wasm).map_err(|e| anyhow!("{e:?}"))?;
        let mut linker = Linker::new(&engine);
        add_to_linker(&mut linker)?;
        let mut store = wasmtime::Store::new(&engine, WasiCtx::new(cwd, args));
        let instance = linker.instantiate(&mut store, &module).map_err(|e| anyhow!("{e:?}"))?;
        let start = instance
            .get_typed_func::<(), ()>(&mut store, "_start")
            .map_err(|e| anyhow!("module has no `_start`: {e:?}"))?;
        match start.call(&mut store, ()) {
            Ok(()) => Ok(0),
            // A `proc_exit` unwinds as an error after setting `exit_code`; that is
            // a normal termination, not a trap.
            Err(e) => match store.data().exit_code {
                Some(code) => Ok(code),
                None => Err(anyhow!("wasi command trapped: {e:?}")),
            },
        }
    }
}

// ──────────────────────────── wasmer registration ────────────────────────────
//
// Drives the OMEdit worker (wasmer's js backend) and native-wasmer. Host
// functions reach the guest memory + fd table via `FunctionEnvMut`'s
// `data_and_store_mut`; the memory is a `MemoryView` (copy-based, the only option
// on the js backend), set into the env after instantiation since the command
// module exports its own `memory`. `proc_exit` records its code and unwinds via
// a `RuntimeError`, which `run_command` turns back into the exit code.

#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
mod wasmer_impl {
    use super::*;
    use wasmer::{Function, FunctionEnv, FunctionEnvMut, Imports, Instance, Memory, Module, RuntimeError, Store};

    /// Host-function environment: the WASI state plus the guest memory, which is
    /// filled in after instantiation (the command module exports its own `memory`).
    pub struct Env {
        ctx: WasiCtx,
        memory: Option<Memory>,
    }

    /// A wasmer `MemoryView` as `GuestMem`. Reads/writes copy (the js backend has
    /// no Rust slice into linear memory), matching the trait's copy-based contract.
    struct ViewMem<'a>(wasmer::MemoryView<'a>);
    impl GuestMem for ViewMem<'_> {
        fn size(&self) -> usize {
            self.0.data_size() as usize
        }
        fn read(&self, addr: u32, buf: &mut [u8]) -> bool {
            self.0.read(addr as u64, buf).is_ok()
        }
        fn write(&mut self, addr: u32, bytes: &[u8]) -> bool {
            self.0.write(addr as u64, bytes).is_ok()
        }
    }

    /// Bind `$mem` (a `ViewMem` over the guest memory) and `$ctx` (`&mut WasiCtx`)
    /// from the function env, or `return ERRNO_FAULT` if memory is not set yet.
    macro_rules! view_ctx {
        ($env:ident, $mem:ident, $ctx:ident) => {
            let (data, store) = $env.data_and_store_mut();
            let memory = match &data.memory {
                Some(m) => m.clone(),
                None => return ERRNO_FAULT,
            };
            let mut $mem = ViewMem(memory.view(&store));
            let $ctx = &mut data.ctx;
        };
    }

    /// Register the `wasi_snapshot_preview1` imports into `imports`.
    pub fn add_to_imports(store: &mut Store, env: &FunctionEnv<Env>, imports: &mut Imports) {
        let m = "wasi_snapshot_preview1";
        let mut def = |name: &str, f: Function| {
            imports.define(m, name, f);
        };

        def("fd_write", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32, iovs: i32, n: i32, nw: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.fd_write(&mut mem, fd as u32, iovs as u32, n as u32, nw as u32)
        }));
        def("fd_read", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32, iovs: i32, n: i32, nr: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.fd_read(&mut mem, fd as u32, iovs as u32, n as u32, nr as u32)
        }));
        def("fd_seek", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32, off: i64, whence: i32, no: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.fd_seek(&mut mem, fd as u32, off, whence, no as u32)
        }));
        def("path_open", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, dirfd: i32, dirflags: i32, path: i32, plen: i32, oflags: i32, rb: i64, ri: i64, fdflags: i32, ofd: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.path_open(&mut mem, dirfd as u32, dirflags as u32, path as u32, plen as u32, oflags, rb as u64, ri as u64, fdflags, ofd as u32)
        }));
        def("path_filestat_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, dirfd: i32, flags: i32, path: i32, plen: i32, buf: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.path_filestat_get(&mut mem, dirfd as u32, flags as u32, path as u32, plen as u32, buf as u32)
        }));
        def("fd_filestat_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32, buf: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.fd_filestat_get(&mut mem, fd as u32, buf as u32)
        }));
        def("fd_fdstat_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32, buf: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.fd_fdstat_get(&mut mem, fd as u32, buf as u32)
        }));
        def("fd_fdstat_set_flags", Function::new_typed_with_env(store, env, |_env: FunctionEnvMut<Env>, _fd: i32, _flags: i32| -> i32 {
            ERRNO_SUCCESS
        }));
        def("fd_close", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32| -> i32 {
            env.data_mut().ctx.fd_close(fd as u32)
        }));
        def("fd_prestat_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32, buf: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.fd_prestat_get(&mut mem, fd as u32, buf as u32)
        }));
        def("fd_prestat_dir_name", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32, path: i32, plen: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.fd_prestat_dir_name(&mut mem, fd as u32, path as u32, plen as u32)
        }));
        def("args_sizes_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, argc: i32, bs: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.args_sizes_get(&mut mem, argc as u32, bs as u32)
        }));
        def("args_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, argv: i32, buf: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.args_get(&mut mem, argv as u32, buf as u32)
        }));
        def("environ_sizes_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, count: i32, bs: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.environ_sizes_get(&mut mem, count as u32, bs as u32)
        }));
        def("environ_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, e: i32, buf: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.environ_get(&mut mem, e as u32, buf as u32)
        }));
        def("clock_time_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, id: i32, prec: i64, time: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.clock_time_get(&mut mem, id as u32, prec as u64, time as u32)
        }));
        def("random_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, buf: i32, len: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.random_get(&mut mem, buf as u32, len as u32)
        }));
        def("proc_exit", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, code: i32| -> std::result::Result<(), RuntimeError> {
            env.data_mut().ctx.exit_code = Some(code as u32);
            Err(RuntimeError::new("wasi proc_exit"))
        }));
    }

    /// Instantiate `wasm` as a WASI command module and call `_start`, returning
    /// the exit code (0 if `_start` returns normally). Files land in
    /// `openmodelica_vfs`, with relative paths keyed under `cwd`.
    pub fn run_command(wasm: &[u8], cwd: &str, args: Vec<String>) -> Result<u32> {
        // Match the engine/store construction the rest of the wasmer paths use
        // (works on both the native `sys` and the worker `js` backends, where
        // `Store::default()` is not available).
        let engine = wasmer::Engine::default();
        let module = Module::new(&engine, wasm).map_err(|e| anyhow!("{e:?}"))?;
        let mut store = Store::new(engine);
        let env = FunctionEnv::new(&mut store, Env { ctx: WasiCtx::new(cwd, args), memory: None });
        let mut imports = Imports::new();
        add_to_imports(&mut store, &env, &mut imports);
        let instance = Instance::new(&mut store, &module, &imports).map_err(|e| anyhow!("{e:?}"))?;
        let memory = instance.exports.get_memory("memory").map_err(|e| anyhow!("no `memory` export: {e:?}"))?.clone();
        env.as_mut(&mut store).memory = Some(memory);
        let start = instance
            .exports
            .get_typed_function::<(), ()>(&store, "_start")
            .map_err(|e| anyhow!("module has no `_start`: {e:?}"))?;
        match start.call(&mut store) {
            Ok(()) => Ok(0),
            Err(e) => match env.as_ref(&store).ctx.exit_code {
                Some(code) => Ok(code),
                None => Err(anyhow!("wasi command trapped: {e:?}")),
            },
        }
    }
}

#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
#[allow(unused_imports)] // wired into the run path in a later step
pub use wasmtime_impl::{add_to_linker, run_command};

#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
#[allow(unused_imports)] // wired into the run path in a later step
pub use wasmer_impl::{add_to_imports, run_command};

#[cfg(test)]
#[cfg(all(feature = "jit", not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use wasm_encoder as we;

    /// Build a tiny wasip1 command module that, from `_start`:
    ///   * `path_open`s a relative name for writing (CREAT|TRUNC, write rights),
    ///   * `fd_write`s a fixed payload,
    ///   * `fd_close`s (flushing to the VFS),
    ///   * `proc_exit(0)`.
    /// The data segment lays out, from address 0:
    ///   [0]   the path string         (`path_bytes`)
    ///   [64]  the payload string      (`data_bytes`)
    ///   [128] iovec { buf=64, len }
    ///   [136] scratch: opened-fd out  (u32)
    ///   [140] scratch: nwritten out   (u32)
    fn build_writer_module(path: &str, data: &str) -> Vec<u8> {
        use we::Instruction as I;
        const PATH_OFF: i32 = 0;
        const DATA_OFF: i32 = 64;
        const IOVEC_OFF: i32 = 128;
        const OPENED_FD_OFF: i32 = 136;
        const NWRITTEN_OFF: i32 = 140;
        const WASI: &str = "wasi_snapshot_preview1";

        let mut m = we::Module::new();

        // Types: each import + _start. Index them as we add.
        let mut types = we::TypeSection::new();
        // 0: path_open (i32 x4, i32 oflags, i64, i64, i32 fdflags, i32) -> i32  => 9 params
        types.ty().function(
            [we::ValType::I32, we::ValType::I32, we::ValType::I32, we::ValType::I32, we::ValType::I32, we::ValType::I64, we::ValType::I64, we::ValType::I32, we::ValType::I32],
            [we::ValType::I32],
        );
        // 1: fd_write (i32,i32,i32,i32) -> i32
        types.ty().function([we::ValType::I32; 4], [we::ValType::I32]);
        // 2: fd_close (i32) -> i32
        types.ty().function([we::ValType::I32], [we::ValType::I32]);
        // 3: proc_exit (i32) -> ()
        types.ty().function([we::ValType::I32], []);
        // 4: _start () -> ()
        types.ty().function([], []);
        m.section(&types);

        let mut imports = we::ImportSection::new();
        imports.import(WASI, "path_open", we::EntityType::Function(0));
        imports.import(WASI, "fd_write", we::EntityType::Function(1));
        imports.import(WASI, "fd_close", we::EntityType::Function(2));
        imports.import(WASI, "proc_exit", we::EntityType::Function(3));
        m.section(&imports);
        // Import function indices: path_open=0, fd_write=1, fd_close=2, proc_exit=3.

        let mut funcs = we::FunctionSection::new();
        funcs.function(4); // _start uses type 4
        m.section(&funcs);

        let mut mems = we::MemorySection::new();
        mems.memory(we::MemoryType { minimum: 1, maximum: None, memory64: false, shared: false, page_size_log2: None });
        m.section(&mems);

        let mut exports = we::ExportSection::new();
        exports.export("memory", we::ExportKind::Memory, 0);
        exports.export("_start", we::ExportKind::Func, 4); // after 4 imported funcs
        m.section(&exports);

        let mut code = we::CodeSection::new();
        let mut f = we::Function::new([]);
        // path_open(dirfd=3, dirflags=0, path=PATH_OFF, path_len, oflags=CREAT|TRUNC,
        //           rights_base=FD_WRITE, rights_inheriting=0, fdflags=0, &opened_fd)
        f.instruction(&I::I32Const(3));
        f.instruction(&I::I32Const(0));
        f.instruction(&I::I32Const(PATH_OFF));
        f.instruction(&I::I32Const(path.len() as i32));
        f.instruction(&I::I32Const(OFLAGS_CREAT | OFLAGS_TRUNC));
        f.instruction(&I::I64Const(RIGHTS_FD_WRITE as i64));
        f.instruction(&I::I64Const(0));
        f.instruction(&I::I32Const(0));
        f.instruction(&I::I32Const(OPENED_FD_OFF));
        f.instruction(&I::Call(0));
        f.instruction(&I::Drop);
        // fd_write(opened_fd, iovec=IOVEC_OFF, iovs_len=1, &nwritten)
        f.instruction(&I::I32Const(OPENED_FD_OFF));
        f.instruction(&I::I32Load(we::MemArg { offset: 0, align: 2, memory_index: 0 }));
        f.instruction(&I::I32Const(IOVEC_OFF));
        f.instruction(&I::I32Const(1));
        f.instruction(&I::I32Const(NWRITTEN_OFF));
        f.instruction(&I::Call(1));
        f.instruction(&I::Drop);
        // fd_close(opened_fd)
        f.instruction(&I::I32Const(OPENED_FD_OFF));
        f.instruction(&I::I32Load(we::MemArg { offset: 0, align: 2, memory_index: 0 }));
        f.instruction(&I::Call(2));
        f.instruction(&I::Drop);
        // proc_exit(0)
        f.instruction(&I::I32Const(0));
        f.instruction(&I::Call(3));
        f.instruction(&I::End);
        code.function(&f);
        m.section(&code);

        // Active data: path, payload, and the iovec {buf=DATA_OFF, len=data.len}.
        let mut iovec = Vec::new();
        iovec.extend_from_slice(&(DATA_OFF as u32).to_le_bytes());
        iovec.extend_from_slice(&(data.len() as u32).to_le_bytes());
        let off = |o: i32| we::ConstExpr::i32_const(o);
        let mut dsec = we::DataSection::new();
        dsec.active(0, &off(PATH_OFF), path.as_bytes().iter().copied());
        dsec.active(0, &off(DATA_OFF), data.as_bytes().iter().copied());
        dsec.active(0, &off(IOVEC_OFF), iovec.iter().copied());
        m.section(&dsec);

        m.finish()
    }

    #[test]
    fn wasi_writes_through_vfs() {
        let path = "wasi_shim_test_out.txt";
        let payload = "hello from wasi over the vfs\n";
        let wasm = build_writer_module(path, payload);
        let code = run_command(&wasm, "", vec!["sim".to_string()]).unwrap();
        assert_eq!(code, 0);
        let got = openmodelica_vfs::read(path).expect("file should exist in the VFS");
        assert_eq!(String::from_utf8(got).unwrap(), payload);
        openmodelica_vfs::remove(path);
    }

    #[test]
    fn wasi_writes_under_cwd_prefix() {
        let path = "res.mat";
        let payload = "MATDATA";
        let wasm = build_writer_module(path, payload);
        let code = run_command(&wasm, "rundir", vec!["sim".to_string()]).unwrap();
        assert_eq!(code, 0);
        // cwd "rundir" + relative "res.mat" -> VFS key "rundir/res.mat".
        let got = openmodelica_vfs::read("rundir/res.mat").expect("file under cwd prefix");
        assert_eq!(String::from_utf8(got).unwrap(), payload);
        openmodelica_vfs::remove("rundir/res.mat");
    }
}
