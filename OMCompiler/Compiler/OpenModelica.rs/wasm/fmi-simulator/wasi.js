// A WASI preview1 host for the driver module, with the files kept in memory.
//
// The driver writes its result file the way every other OpenModelica simulation
// does — `std::fs`, which on `wasm32-wasip1` is WASI — so the page has to be the
// filesystem. Only what the driver actually calls is implemented; everything
// else reports ENOSYS rather than pretending.

const ERRNO = { success: 0, badf: 8, exist: 20, inval: 28, isdir: 31, noent: 44, nosys: 52, notdir: 54 };
const FILETYPE = { directory: 3, regular: 4 };
const PREOPEN_FD = 3;
const FIRST_FD = 4;

export class Wasi {
  constructor({ onOutput = () => {} } = {}) {
    this.onOutput = onOutput;
    // Absolute path (without the leading slash) → contents.
    this.files = new Map();
    this.fds = new Map();
    this.nextFd = FIRST_FD;
    this.memory = null;
    this.decoder = new TextDecoder();
    this.encoder = new TextEncoder();
  }

  // Called once the module is instantiated; every call reads memory through it.
  bind(memory) {
    this.memory = memory;
  }

  view() {
    return new DataView(this.memory.buffer);
  }

  bytes() {
    return new Uint8Array(this.memory.buffer);
  }

  string(ptr, len) {
    return this.decoder.decode(this.bytes().subarray(ptr, ptr + len));
  }

  // The file the driver wrote, for the page to offer as a download.
  read(path) {
    return this.files.get(path.replace(/^\//, ''));
  }

  write(path, bytes) {
    this.files.set(path.replace(/^\//, ''), bytes);
  }

  // The `wasi_snapshot_preview1` import object.
  imports() {
    const view = () => this.view();
    const self = this;
    const iovecs = (ptr, count, each) => {
      let total = 0;
      for (let i = 0; i < count; i++) {
        const base = view().getUint32(ptr + i * 8, true);
        const len = view().getUint32(ptr + i * 8 + 4, true);
        total += each(base, len);
      }
      return total;
    };
    return {
      proc_exit(code) {
        throw new Error(`the driver called proc_exit(${code})`);
      },
      fd_write(fd, iovsPtr, iovsLen, writtenPtr) {
        let written = 0;
        if (fd === 1 || fd === 2) {
          const parts = [];
          written = iovecs(iovsPtr, iovsLen, (base, len) => {
            parts.push(self.bytes().slice(base, base + len));
            return len;
          });
          const text = parts.map((p) => self.decoder.decode(p)).join('');
          if (text) self.onOutput(fd === 1 ? 'stdout' : 'stderr', text.replace(/\n$/, ''));
        } else {
          const open = self.fds.get(fd);
          if (!open) return ERRNO.badf;
          const chunks = [];
          written = iovecs(iovsPtr, iovsLen, (base, len) => {
            chunks.push(self.bytes().slice(base, base + len));
            return len;
          });
          const before = self.files.get(open.path) ?? new Uint8Array(0);
          const out = new Uint8Array(Math.max(before.length, open.offset + written));
          out.set(before);
          let at = open.offset;
          for (const c of chunks) {
            out.set(c, at);
            at += c.length;
          }
          open.offset = at;
          self.files.set(open.path, out);
        }
        view().setUint32(writtenPtr, written, true);
        return ERRNO.success;
      },
      fd_read(fd, iovsPtr, iovsLen, readPtr) {
        const open = self.fds.get(fd);
        if (!open) return ERRNO.badf;
        const data = self.files.get(open.path) ?? new Uint8Array(0);
        let read = 0;
        iovecs(iovsPtr, iovsLen, (base, len) => {
          const chunk = data.subarray(open.offset, open.offset + len);
          self.bytes().set(chunk, base);
          open.offset += chunk.length;
          read += chunk.length;
          return chunk.length;
        });
        view().setUint32(readPtr, read, true);
        return ERRNO.success;
      },
      fd_close(fd) {
        return self.fds.delete(fd) ? ERRNO.success : ERRNO.badf;
      },
      fd_seek(fd, offset, whence, resultPtr) {
        const open = self.fds.get(fd);
        if (!open) return ERRNO.badf;
        const size = (self.files.get(open.path) ?? new Uint8Array(0)).length;
        const from = whence === 1 ? open.offset : whence === 2 ? size : 0;
        open.offset = from + Number(offset);
        view().setBigUint64(resultPtr, BigInt(open.offset), true);
        return ERRNO.success;
      },
      fd_tell(fd, resultPtr) {
        const open = self.fds.get(fd);
        if (!open) return ERRNO.badf;
        view().setBigUint64(resultPtr, BigInt(open.offset), true);
        return ERRNO.success;
      },
      fd_fdstat_get(fd, statPtr) {
        const isDir = fd === PREOPEN_FD;
        view().setUint8(statPtr, isDir ? FILETYPE.directory : FILETYPE.regular);
        view().setUint16(statPtr + 2, 0, true);
        view().setBigUint64(statPtr + 8, 0xffffffffffffffffn, true);
        view().setBigUint64(statPtr + 16, 0xffffffffffffffffn, true);
        return ERRNO.success;
      },
      fd_fdstat_set_flags: () => ERRNO.success,
      fd_prestat_get(fd, prestatPtr) {
        if (fd !== PREOPEN_FD) return ERRNO.badf;
        view().setUint8(prestatPtr, 0);              // preopentype: dir
        view().setUint32(prestatPtr + 4, 1, true);   // the name is "/"
        return ERRNO.success;
      },
      fd_prestat_dir_name(fd, pathPtr, pathLen) {
        if (fd !== PREOPEN_FD) return ERRNO.badf;
        self.bytes().set(self.encoder.encode('/'.slice(0, pathLen)), pathPtr);
        return ERRNO.success;
      },
      fd_filestat_get(fd, statPtr) {
        const open = self.fds.get(fd);
        const size = open ? (self.files.get(open.path) ?? new Uint8Array(0)).length : 0;
        view().setBigUint64(statPtr + 16, BigInt(fd === PREOPEN_FD ? 0 : FILETYPE.regular), true);
        view().setBigUint64(statPtr + 32, BigInt(size), true);
        return ERRNO.success;
      },
      path_open(dirFd, dirFlags, pathPtr, pathLen, oflags, rights, rightsInheriting, fdFlags, fdPtr) {
        const path = self.string(pathPtr, pathLen).replace(/^\.?\//, '');
        const exists = self.files.has(path);
        const create = (oflags & 1) !== 0;
        const exclusive = (oflags & 2) !== 0;
        const truncate = (oflags & 8) !== 0;
        if (!exists && !create) return ERRNO.noent;
        if (exists && exclusive) return ERRNO.exist;
        if (!exists || truncate) self.files.set(path, new Uint8Array(0));
        const fd = self.nextFd++;
        // append (fdflags bit 0) starts at the end, everything else at the front
        const append = (fdFlags & 1) !== 0;
        self.fds.set(fd, { path, offset: append ? (self.files.get(path)?.length ?? 0) : 0 });
        view().setUint32(fdPtr, fd, true);
        return ERRNO.success;
      },
      path_filestat_get(dirFd, flags, pathPtr, pathLen, statPtr) {
        const path = self.string(pathPtr, pathLen).replace(/^\.?\//, '');
        const data = self.files.get(path);
        if (!data) return ERRNO.noent;
        view().setBigUint64(statPtr + 16, BigInt(FILETYPE.regular), true);
        view().setBigUint64(statPtr + 32, BigInt(data.length), true);
        return ERRNO.success;
      },
      path_unlink_file(dirFd, pathPtr, pathLen) {
        const path = self.string(pathPtr, pathLen).replace(/^\.?\//, '');
        return self.files.delete(path) ? ERRNO.success : ERRNO.noent;
      },
      path_create_directory: () => ERRNO.success,
      path_remove_directory: () => ERRNO.success,
      path_rename(oldFd, oldPtr, oldLen, newFd, newPtr, newLen) {
        const from = self.string(oldPtr, oldLen).replace(/^\.?\//, '');
        const to = self.string(newPtr, newLen).replace(/^\.?\//, '');
        const data = self.files.get(from);
        if (!data) return ERRNO.noent;
        self.files.set(to, data);
        self.files.delete(from);
        return ERRNO.success;
      },
      environ_sizes_get(countPtr, sizePtr) {
        view().setUint32(countPtr, 0, true);
        view().setUint32(sizePtr, 0, true);
        return ERRNO.success;
      },
      environ_get: () => ERRNO.success,
      args_sizes_get(countPtr, sizePtr) {
        view().setUint32(countPtr, 0, true);
        view().setUint32(sizePtr, 0, true);
        return ERRNO.success;
      },
      args_get: () => ERRNO.success,
      clock_time_get(id, precision, timePtr) {
        view().setBigUint64(timePtr, BigInt(Math.round(Date.now() * 1e6)), true);
        return ERRNO.success;
      },
      clock_res_get(id, resPtr) {
        view().setBigUint64(resPtr, 1000n, true);
        return ERRNO.success;
      },
      random_get(ptr, len) {
        const out = self.bytes().subarray(ptr, ptr + len);
        if (globalThis.crypto?.getRandomValues) globalThis.crypto.getRandomValues(out);
        else for (let i = 0; i < len; i++) out[i] = (Math.random() * 256) | 0;
        return ERRNO.success;
      },
      sched_yield: () => ERRNO.success,
      poll_oneoff: () => ERRNO.nosys,
      fd_readdir: () => ERRNO.nosys,
      fd_sync: () => ERRNO.success,
      fd_datasync: () => ERRNO.success,
      fd_advise: () => ERRNO.success,
      fd_allocate: () => ERRNO.success,
      fd_pread: () => ERRNO.nosys,
      fd_pwrite: () => ERRNO.nosys,
      fd_renumber: () => ERRNO.nosys,
      path_link: () => ERRNO.nosys,
      path_readlink: () => ERRNO.nosys,
      path_symlink: () => ERRNO.nosys,
      path_filestat_set_times: () => ERRNO.success,
      fd_filestat_set_size: () => ERRNO.success,
      fd_filestat_set_times: () => ERRNO.success,
      sock_accept: () => ERRNO.nosys,
    };
  }
}
