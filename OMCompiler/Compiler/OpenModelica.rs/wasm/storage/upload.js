// Installs the packages of a picked .mo file, .zip file or folder into the
// library directory of the store, as OMEdit's Install Library From File does:
// an omc worker holds the upload, names each package with parseFile and moves
// it into place, and saves the store after each command.

const UPLOADS = '/uploads';

const esc = (s) => s.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
const unquote = (s) => (s || '').trim().replace(/^"|"$/g, '');

export class LibraryUpload {
  constructor() {
    this.worker = new Worker(new URL('../omc_worker.js', import.meta.url), { type: 'module' });
    this.nextId = 0;
    this.pending = new Map();
    this.replies = [];
    this.worker.onmessage = (e) => {
      const m = e.data;
      if (m.id !== undefined && this.pending.has(m.id)) {
        this.pending.get(m.id)(m);
        this.pending.delete(m.id);
      } else if (m.kind === 'ready' || m.kind === 'done') {
        this.replies.shift()?.(m);
      }
    };
    this.ready = this.reply({ cmd: 'init', installMsl: false }).then((m) => {
      if (!m.ok) throw new Error(m.error || 'omc did not start');
    });
  }

  // init and eval answer in order and without an id.
  reply(msg) {
    return new Promise((resolve) => {
      this.replies.push(resolve);
      this.worker.postMessage(msg);
    });
  }

  request(cmd, args = {}) {
    const id = ++this.nextId;
    return new Promise((resolve) => {
      this.pending.set(id, resolve);
      this.worker.postMessage({ cmd, id, ...args });
    });
  }

  async eval(src) {
    await this.ready;
    return (await this.reply({ cmd: 'eval', src })).result;
  }

  async librariesDirectory() {
    return `${unquote(await this.eval('getHomeDirectoryPath()'))}/.openmodelica/libraries`;
  }

  // One .mo or .zip file, or the files of a folder (with webkitRelativePath),
  // in the worker. Returns their path there.
  async stage(files) {
    await this.ready;
    if (files.length === 1 && !files[0].webkitRelativePath) {
      const file = files[0];
      const bytes = new Uint8Array(await file.arrayBuffer());
      if (/\.zip$/i.test(file.name)) {
        const mount = `${UPLOADS}/${file.name.replace(/\.zip$/i, '')}`;
        const r = await this.request('vfsLoadZip', { mount, bytes });
        if (!(r.written > 0)) throw new Error(r.error || `Nothing could be extracted from ${file.name}.`);
        return mount;
      }
      const path = `${UPLOADS}/${file.name}`;
      await this.request('vfsPut', { path, bytes });
      return path;
    }
    const entries = await Promise.all(
      [...files].map(async (f) => ({ path: `${UPLOADS}/${f.webkitRelativePath}`, bytes: new Uint8Array(await f.arrayBuffer()) })),
    );
    const r = await this.request('vfsPutMany', { entries });
    if (r.written !== entries.length) throw new Error('Could not read the folder.');
    return `${UPLOADS}/${files[0].webkitRelativePath.split('/')[0]}`;
  }

  // The packages in `path`: the directories with a package.mo that are not
  // inside another one, and the other .mo files, at most three levels down.
  // Each is { name, path, isFile }; `skipped` are the files without exactly
  // one top-level class.
  async find(path) {
    const found = [];
    const walk = async (dir, depth) => {
      const entries = (await this.request('vfsList', { path: dir })).entries || [];
      if (entries.some((e) => !e.isDir && e.name === 'package.mo')) {
        found.push({ path: dir, isFile: false });
        return;
      }
      for (const e of entries.sort((a, b) => a.name.localeCompare(b.name))) {
        if (e.isDir) {
          if (depth > 0) await walk(`${dir}/${e.name}`, depth - 1);
        } else if (e.name.endsWith('.mo')) {
          found.push({ path: `${dir}/${e.name}`, isFile: true });
        }
      }
    };
    if (path.endsWith('.mo')) found.push({ path, isFile: true });
    else await walk(path, 3);
    const packages = [];
    const skipped = [];
    for (const p of found) {
      const top = p.isFile ? p.path : `${p.path}/package.mo`;
      const names = (await this.eval(`parseFile("${esc(top)}")`)).trim().replace(/^\{|\}$/g, '').split(',').map((s) => s.trim()).filter(Boolean);
      await this.eval('getErrorString()');
      if (names.length === 1) packages.push({ ...p, name: names[0] });
      else skipped.push(p.path === path ? p.path.split('/').pop() : p.path.slice(path.length + 1));
    }
    return { packages, skipped };
  }

  // Moves `packages` into the library directory as Name or Name.mo, replacing
  // an installed one, and returns once the store is saved.
  async install(packages, libraries) {
    for (const p of packages) {
      const dir = `${libraries}/${p.name}`;
      await this.request('vfsRemove', { path: dir });
      await this.request('vfsRemove', { path: `${dir}.mo` });
      const r = await this.request('vfsRename', { from: p.path, to: p.isFile ? `${dir}.mo` : dir });
      if (!r.ok) throw new Error(`Could not install ${p.name}.`);
    }
    await this.eval('1');
  }

  close() {
    this.worker.terminate();
  }
}
