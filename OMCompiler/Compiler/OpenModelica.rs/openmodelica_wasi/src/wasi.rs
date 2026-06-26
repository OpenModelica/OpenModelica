//! A minimal `wasi_snapshot_preview1` implementation backed by this crate's
//! in-memory store, so the backing store is swappable behind a standard surface.
//!
//! The ABI methods take a [`GuestMem`] (the guest's linear memory) and follow the
//! preview1 pointer/struct layout — for a guest wasm module driven by an engine.
//! The high-level methods at the bottom take and return plain Rust values, for a
//! host that reads/lists the store directly. Both share one fd table.

use std::collections::HashMap;

// ─────────────────────────────── WASI constants ──────────────────────────────

// errno (`__wasi_errno_t`): 0 is success.
pub const ERRNO_SUCCESS: i32 = 0;
pub const ERRNO_BADF: i32 = 8;
pub const ERRNO_FAULT: i32 = 21;
pub const ERRNO_INVAL: i32 = 28;
pub const ERRNO_NOENT: i32 = 44;

// filetype (`__wasi_filetype_t`).
pub const FILETYPE_CHARACTER_DEVICE: u8 = 2;
pub const FILETYPE_DIRECTORY: u8 = 3;
pub const FILETYPE_REGULAR_FILE: u8 = 4;

// oflags (`__wasi_oflags_t`) bits passed to `path_open`.
pub const OFLAGS_CREAT: i32 = 1 << 0;
pub const OFLAGS_TRUNC: i32 = 1 << 3;

// rights (`__wasi_rights_t`) bit for `fd_write`; used to tell a write-open from a
// read-open in `path_open`.
pub const RIGHTS_FD_WRITE: u64 = 1 << 6;

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
            match crate::read(&vfs_path) {
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
                crate::write(&vfs_path, buf);
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
        let (filetype, size, mtime) = match self.fds.get(&fd) {
            Some(Fd::File { buf, vfs_path, .. }) => (FILETYPE_REGULAR_FILE, buf.len() as u64, crate::mtime(vfs_path).map(|d| d.as_nanos() as u64).unwrap_or(0)),
            Some(Fd::PreopenDir { .. }) => (FILETYPE_DIRECTORY, 0, 0),
            Some(Fd::Stdout | Fd::Stderr) => (FILETYPE_CHARACTER_DEVICE, 0, 0),
            None => return ERRNO_BADF,
        };
        Self::write_filestat(mem, buf, filetype, size, mtime)
    }

    /// `path_filestat_get`: stat a file by name relative to a preopen dir.
    pub fn path_filestat_get<M: GuestMem>(&mut self, mem: &mut M, _dirfd: u32, _flags: u32, path: u32, path_len: u32, buf: u32) -> i32 {
        let Some(bytes) = Self::rd_bytes(mem, path, path_len) else { return ERRNO_FAULT };
        let vfs_path = self.resolve(&String::from_utf8_lossy(&bytes));
        match crate::read(&vfs_path) {
            Some(b) => Self::write_filestat(mem, buf, FILETYPE_REGULAR_FILE, b.len() as u64, crate::mtime(&vfs_path).map(|d| d.as_nanos() as u64).unwrap_or(0)),
            None => ERRNO_NOENT,
        }
    }

    fn write_filestat<M: GuestMem>(mem: &mut M, buf: u32, filetype: u8, size: u64, mtime: u64) -> i32 {
        // dev(0) ino(8) filetype(16) nlink(24) size(32) atim(40) mtim(48) ctim(56)
        if mem.size() < buf as usize + 64 {
            return ERRNO_FAULT;
        }
        let _ = Self::wr_u64(mem, buf, 0);
        let _ = Self::wr_u64(mem, buf + 8, 0);
        let _ = Self::wr_u8(mem, buf + 16, filetype);
        let _ = Self::wr_u64(mem, buf + 24, 1); // nlink
        let _ = Self::wr_u64(mem, buf + 32, size);
        let _ = Self::wr_u64(mem, buf + 40, mtime);
        let _ = Self::wr_u64(mem, buf + 48, mtime);
        let _ = Self::wr_u64(mem, buf + 56, mtime);
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
            _ => return ERRNO_BADF,
        };
        let entries = readdir(&dir_key);
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
        let buf = crate::read(path)?;
        let fd = self.next_fd;
        self.next_fd += 1;
        self.fds.insert(fd, Fd::File { vfs_path: path.to_string(), buf, pos: 0, writable: false, dirty: false });
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
