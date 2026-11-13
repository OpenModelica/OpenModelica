// Keeps omc's <home>/.openmodelica (installed libraries, the package index, the
// parse cache) across sessions, in segment files of the origin private file
// system. A segment is written once and never changed:
//
//   [file bytes][index, UTF-8 JSON][index length, u32 LE]["OMCSTOR1"]
//
// index = { files: [[path, mtime s, mtime ns, offset, length]], removed: [path],
// supersedes: [segment name] }. Segments apply in name order, so a later one
// replaces or removes files of an earlier one; one that supersedes others
// replaces them whole (a compaction). omc reads a file when it needs it, through
// a synchronous access handle on its segment. A page, which has no such handles,
// holds the segments in memory instead.

const DIR = 'omc-store';
const MAGIC = 'OMCSTOR1';
const TRAILER = 12;
const LOCK = 'omc-store';
const MB = 1 << 20;

const utf8 = new TextEncoder();

// The origin private file system. Read handles are shared where the browser
// allows it; a file another worker holds, or any file on a page, is read whole.
export function opfs() {
  let dir;
  const folder = async () => (dir ||= await (await navigator.storage.getDirectory()).getDirectoryHandle(DIR, { create: true }));
  const sync = typeof FileSystemFileHandle !== 'undefined' && 'createSyncAccessHandle' in FileSystemFileHandle.prototype;
  return {
    async list() {
      const names = [];
      for await (const [name, h] of (await folder()).entries()) if (h.kind === 'file') names.push(name);
      return names;
    },
    async open(name) {
      const file = await (await folder()).getFileHandle(name);
      if (sync) {
        try {
          const h = await file.createSyncAccessHandle({ mode: 'read-only' });
          return { size: h.getSize(), read: (buf, at) => h.read(buf, { at }), close: () => h.close() };
        } catch {}
      }
      const bytes = new Uint8Array(await (await file.getFile()).arrayBuffer());
      return { size: bytes.length, read: (buf, at) => copyOut(bytes, buf, at), close() {} };
    },
    async create(name) {
      const file = await (await folder()).getFileHandle(name, { create: true });
      if (sync) {
        const h = await file.createSyncAccessHandle();
        return { write: (bytes, at) => h.write(bytes, { at }), close: () => { h.flush(); h.close(); } };
      }
      const parts = [];
      return {
        write: (data, position) => parts.push({ type: 'write', position, data }),
        async close(complete) {
          if (!complete) return;
          const w = await file.createWritable();
          for (const part of parts) await w.write(part);
          await w.close();
        },
      };
    },
    async remove(name) {
      await (await folder()).removeEntry(name);
    },
    lock: (fn) => (navigator.locks ? navigator.locks.request(LOCK, fn) : fn()),
  };
}

function copyOut(bytes, buf, at) {
  const part = bytes.subarray(at, at + buf.length);
  buf.set(part);
  return part.length;
}

function trailer(indexLength) {
  const t = new Uint8Array(TRAILER);
  new DataView(t.buffer).setUint32(0, indexLength, true);
  t.set(utf8.encode(MAGIC), 4);
  return t;
}

// The index of a complete segment, or null for one cut short.
function readIndex(handle) {
  if (handle.size < TRAILER) return null;
  const t = new Uint8Array(TRAILER);
  handle.read(t, handle.size - TRAILER);
  if (new TextDecoder().decode(t.subarray(4)) !== MAGIC) return null;
  const length = new DataView(t.buffer).getUint32(0, true);
  if (length > handle.size - TRAILER) return null;
  const bytes = new Uint8Array(length);
  handle.read(bytes, handle.size - TRAILER - length);
  try {
    const index = JSON.parse(new TextDecoder().decode(bytes));
    return { files: index.files || [], removed: index.removed || [], supersedes: index.supersedes || [] };
  } catch {
    return null;
  }
}

function sequence(name) {
  const n = parseInt(name, 10);
  return Number.isFinite(n) ? n : 0;
}

function newName(names) {
  const next = names.reduce((m, n) => Math.max(m, sequence(n)), 0) + 1;
  const random = crypto.getRandomValues(new Uint32Array(1))[0].toString(16).padStart(8, '0');
  return `${String(next).padStart(12, '0')}-${random}.seg`;
}

// `body(out)` writes the file bytes from offset 0 and returns where they end.
async function writeSegment(backend, name, index, body) {
  const out = await backend.create(name);
  let complete = false;
  try {
    const at = body(out);
    const json = utf8.encode(JSON.stringify(index));
    out.write(json, at);
    out.write(trailer(json.length), at + json.length);
    complete = true;
  } finally {
    await out.close(complete);
  }
}

export class Store {
  constructor(backend = opfs()) {
    this.backend = backend;
    this.segments = [];
    // path -> [segment, mtime s, mtime ns, offset, length]
    this.files = new Map();
    this.failed = false;
  }

  load() {
    return this.backend.lock(() => this.loadLocked());
  }

  // Open every segment and work out which files are live. Under the lock, so
  // a segment without a trailer is one whose writer died, not one being written.
  async loadLocked() {
    const found = [];
    const broken = [];
    for (const name of (await this.backend.list()).sort()) {
      const handle = await this.backend.open(name);
      const index = readIndex(handle);
      if (index) {
        found.push({ name, handle, index });
      } else {
        handle.close();
        broken.push(name);
      }
    }
    const superseded = new Set(found.flatMap((s) => s.index.supersedes));
    for (const s of found) {
      if (superseded.has(s.name)) {
        s.handle.close();
        broken.push(s.name);
        continue;
      }
      const id = this.segments.push(s) - 1;
      for (const path of s.index.removed) this.files.delete(path);
      for (const [path, sec, nsec, off, len] of s.index.files) this.files.set(path, [id, sec, nsec, off, len]);
      s.index = null;
    }
    for (const name of broken) await this.backend.remove(name).catch(() => {});
    if (this.needsCompaction()) await this.compactLocked();
  }

  size() {
    return this.segments.reduce((n, s) => n + (s ? s.handle.size : 0), 0);
  }

  liveSize() {
    let n = 0;
    for (const f of this.files.values()) n += f[4];
    return n;
  }

  needsCompaction() {
    const garbage = this.size() - this.liveSize();
    return this.segments.filter(Boolean).length > 32 || garbage > Math.max(32 * MB, this.size() / 4);
  }

  read(seg, off, buf) {
    const s = this.segments[seg];
    return !!s && s.handle.read(buf, off) === buf.length;
  }

  // Rewrite the live files into one segment that supersedes all the others.
  async compactLocked() {
    const old = this.segments.filter(Boolean);
    const name = newName(await this.backend.list());
    const entries = [...this.files].sort((a, b) => a[1][0] - b[1][0] || a[1][3] - b[1][3]);
    const files = [];
    await writeSegment(this.backend, name, { files, removed: [], supersedes: old.map((s) => s.name) }, (out) => {
      let at = 0;
      for (const [path, [seg, sec, nsec, off, len]] of entries) {
        const buf = new Uint8Array(len);
        if (!this.read(seg, off, buf)) throw new Error(`cannot read ${path}`);
        out.write(buf, at);
        files.push([path, sec, nsec, at, len]);
        at += len;
      }
      return at;
    });
    const handle = await this.backend.open(name);
    for (const s of old) s.handle.close();
    this.segments = [{ name, handle }];
    this.files = new Map(files.map(([path, sec, nsec, off, len]) => [path, [0, sec, nsec, off, len]]));
    for (const s of old) await this.backend.remove(s.name).catch(() => {});
  }

  // Store what changed as a new segment: `data` holds the files' bytes at the
  // offsets in `files`. Returns the segment's id.
  async appendLocked(files, data, removed) {
    const name = newName(await this.backend.list());
    await writeSegment(this.backend, name, { files, removed }, (out) => {
      out.write(data, 0);
      return data.length;
    });
    const id = this.segments.push({ name, handle: await this.backend.open(name) }) - 1;
    for (const path of removed) this.files.delete(path);
    for (const [path, sec, nsec, off, len] of files) this.files.set(path, [id, sec, nsec, off, len]);
    return id;
  }

  close() {
    for (const s of this.segments) s?.handle.close();
    this.segments = [];
  }

  // ── an omc instance ────────────────────────────────────────────────────────

  // Mount the stored tree into omc. Call before omc_init.
  attach(omc) {
    this.omc = omc;
    globalThis.__omcStoreRead = (seg, off, buf) => this.read(seg, off, buf);
    omc.omc_store_enable();
    const paths = [];
    const nums = new Float64Array(this.files.size * 5);
    let i = 0;
    for (const [path, f] of this.files) {
      paths.push(path);
      nums.set(f, 5 * i++);
    }
    omc.omc_store_mount(paths.join('\0'), nums);
  }

  // Save what omc changed below the root since the last call.
  async flush() {
    if (this.failed) return;
    const snap = this.omc.omc_store_snapshot();
    if (!snap) return;
    const paths = snap.paths ? snap.paths.split('\0') : [];
    const removed = snap.removed ? snap.removed.split('\0') : [];
    const files = [];
    const offsets = new Float64Array(paths.length);
    let at = 0;
    paths.forEach((path, i) => {
      const len = snap.nums[3 * i + 2];
      files.push([path, snap.nums[3 * i], snap.nums[3 * i + 1], at, len]);
      offsets[i] = at;
      at += len;
    });
    try {
      const seg = await this.backend.lock(() => this.appendLocked(files, snap.data, removed));
      this.omc.omc_store_commit(seg, offsets);
    } catch (e) {
      this.failed = true;
      this.omc.omc_store_disable();
      console.warn('[omc-store] cannot save to browser storage; changes last for this session only', e);
    }
  }
}

// The store, mounted in `omc` (the OpenModelicaCompiler module); null where the
// browser has no storage for it (no OPFS, or a private window), and the session
// is not saved.
export async function openStore(omc, backend) {
  if (typeof omc.omc_store_enable !== 'function') return null;
  if (!backend && !globalThis.navigator?.storage?.getDirectory) return null;
  const store = new Store(backend);
  try {
    await store.load();
  } catch (e) {
    store.close();
    console.warn('[omc-store] browser storage unavailable; this session is not saved', e);
    return null;
  }
  store.attach(omc);
  return store;
}

// ── the storage page ─────────────────────────────────────────────────────────

// Every live file as { path, size, mtime (ms) }, and the bytes the segments take.
export async function contents(backend = opfs()) {
  const store = new Store(backend);
  try {
    await store.load();
    const files = [...store.files].map(([path, [, sec, nsec, , len]]) => ({ path, size: len, mtime: sec * 1000 + nsec / 1e6 }));
    return { files, used: store.size(), live: store.liveSize() };
  } finally {
    store.close();
  }
}

// Remove every live file below one of `prefixes`, then give the space back.
// Workers that have the store open keep their view until they are restarted.
export async function remove(prefixes, backend = opfs()) {
  const store = new Store(backend);
  try {
    return await backend.lock(async () => {
      await store.loadLocked();
      const below = prefixes.map((p) => p.replace(/\/?$/, '/'));
      const gone = [...store.files.keys()].filter((p) => prefixes.includes(p) || below.some((b) => p.startsWith(b)));
      if (gone.length === 0) return 0;
      await store.appendLocked([], new Uint8Array(0), gone);
      await store.compactLocked();
      return gone.length;
    });
  } finally {
    store.close();
  }
}
