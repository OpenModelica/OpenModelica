// The storage page's access to omc-store.js, which needs synchronous file handles.
import { contents, remove } from '../omc-store.js';

self.onmessage = async (e) => {
  const { id, cmd, prefixes } = e.data;
  try {
    const result = cmd === 'remove' ? { removed: await remove(prefixes) } : await contents();
    self.postMessage({ id, result });
  } catch (err) {
    self.postMessage({ id, error: String(err?.message || err) });
  }
};
