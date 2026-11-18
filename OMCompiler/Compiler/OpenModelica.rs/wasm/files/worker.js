// The Files page's access to /persist in omc-store.js, which needs synchronous
// file handles. Paths in messages are relative to /persist.
import { Store } from '../omc-store.js';

const ROOT = '/persist/';

function absolute(rel) {
  if (!rel || rel.split('/').some((p) => p === '' || p === '.' || p === '..')) {
    throw new Error(`"${rel}" is not a valid name`);
  }
  return ROOT + rel;
}

// Run `fn` on the stored files. Compaction is left to the clients, which do it
// when they start.
async function withStore(fn) {
  const store = new Store();
  try {
    return await store.backend.lock(async () => {
      await store.loadLocked(false);
      return await fn(store);
    });
  } finally {
    store.close();
  }
}

const below = (store, rel) => {
  const path = absolute(rel);
  return [...store.files.keys()].filter((p) => p === path || p.startsWith(path + '/'));
};

const mtime = (sec, nsec) => sec * 1000 + nsec / 1e6;

function bytes(store, path) {
  const [seg, , , off, len] = store.files.get(path);
  const buf = new Uint8Array(len);
  if (!store.read(seg, off, buf)) throw new Error(`Cannot read ${path}`);
  return buf;
}

const commands = {
  list: () => withStore((store) => [...store.files]
    .filter(([path]) => path.startsWith(ROOT))
    .map(([path, [seg, sec, nsec, off, len]]) => ({
      path: path.slice(ROOT.length), size: len, mtime: mtime(sec, nsec),
      segment: store.segments[seg].name, offset: off,
    }))),

  put: ({ entries }) => withStore(async (store) => {
    await store.appendBlobsLocked(entries.map((e) => [absolute(e.path), e.blob, e.mtime]));
    return entries.length;
  }),

  remove: ({ paths }) => withStore(async (store) => {
    const gone = [...new Set(paths.flatMap((p) => below(store, p)))];
    if (gone.length) await store.appendLocked([], new Uint8Array(0), gone);
    return gone.length;
  }),

  move: ({ from, to }) => withStore(async (store) => {
    absolute(to);
    if (to === from || to.startsWith(from + '/')) throw new Error(`Cannot move ${from} into itself`);
    const moving = below(store, from);
    if (moving.length === 0) throw new Error(`${from} does not exist`);
    const target = (p) => ROOT + to + p.slice(ROOT.length + from.length);
    const taken = moving.map(target).find((p) => store.files.has(p));
    if (taken) throw new Error(`${taken.slice(ROOT.length)} already exists`);
    const entries = moving.map((p) => {
      const [, sec, nsec] = store.files.get(p);
      return [target(p), new Blob([bytes(store, p)]), mtime(sec, nsec)];
    });
    await store.appendBlobsLocked(entries, moving);
    return moving.length;
  }),

  read: ({ path }) => withStore((store) => {
    if (!store.files.has(absolute(path))) throw new Error(`${path} does not exist`);
    return bytes(store, absolute(path)).buffer;
  }),
};

self.onmessage = async (e) => {
  const { id, cmd, ...args } = e.data;
  try {
    const result = await commands[cmd](args);
    self.postMessage({ id, result }, result instanceof ArrayBuffer ? [result] : []);
  } catch (err) {
    self.postMessage({ id, error: String(err?.message || err) });
  }
};
