// Writing an FMU back out, and its documentation as DOM.
//
// Reading one is the driver's job: `openmodelica_fmi` unpacks the archive and
// parses `modelDescription.xml` in the worker. What is left here is the half no
// wasm entry point covers — the native repack writes a new archive — and the
// half that only means anything in a browser.

async function inflateRaw(bytes) {
  const s = new Blob([bytes]).stream().pipeThrough(new DecompressionStream('deflate-raw'));
  return new Uint8Array(await new Response(s).arrayBuffer());
}

// Minimal ZIP reader over the central directory, for the one path that needs
// every entry in hand: the native repack. Stored and deflated entries only.
export async function readZip(buf) {
  const dv = new DataView(buf), u8 = new Uint8Array(buf), dec = new TextDecoder();
  let eocd = -1;
  for (let i = buf.byteLength - 22; i >= 0 && i > buf.byteLength - 22 - 65536; i--) {
    if (dv.getUint32(i, true) === 0x06054b50) { eocd = i; break; }
  }
  if (eocd < 0) throw new Error('not a ZIP archive: no end-of-central-directory record');
  const count = dv.getUint16(eocd + 10, true);
  let p = dv.getUint32(eocd + 16, true);
  const files = new Map();
  for (let i = 0; i < count; i++) {
    if (dv.getUint32(p, true) !== 0x02014b50) throw new Error('corrupt ZIP central directory');
    const method = dv.getUint16(p + 10, true);
    const csize = dv.getUint32(p + 20, true);
    const nameLen = dv.getUint16(p + 28, true);
    const extraLen = dv.getUint16(p + 30, true);
    const cmtLen = dv.getUint16(p + 32, true);
    const lho = dv.getUint32(p + 42, true);
    const name = dec.decode(u8.subarray(p + 46, p + 46 + nameLen));
    if (csize === 0xffffffff || lho === 0xffffffff) throw new Error(`ZIP64 entry not supported: ${name}`);
    const start = lho + 30 + dv.getUint16(lho + 26, true) + dv.getUint16(lho + 28, true);
    const raw = u8.subarray(start, start + csize);
    if (!name.endsWith('/')) {
      if (method !== 0 && method !== 8) throw new Error(`unsupported ZIP compression method ${method}: ${name}`);
      files.set(name, method === 8 ? await inflateRaw(raw) : raw.slice());
    }
    p += 46 + nameLen + extraLen + cmtLen;
  }
  return files;
}

async function deflateRaw(bytes) {
  const s = new Blob([bytes]).stream().pipeThrough(new CompressionStream('deflate-raw'));
  return new Uint8Array(await new Response(s).arrayBuffer());
}

const CRC = Int32Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c;
});
function crc32(bytes) {
  let c = -1;
  for (const b of bytes) c = CRC[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ -1) >>> 0;
}

// Write a Map of name -> bytes back out as a deflated ZIP, so an FMU can be handed
// back with entries added. Counterpart of [`readZip`]; no ZIP64.
export async function writeZip(files) {
  const enc = new TextEncoder();
  const local = [];
  const central = [];
  let offset = 0;
  for (const [name, bytes] of files) {
    const nameBytes = enc.encode(name);
    const deflated = await deflateRaw(bytes);
    const stored = deflated.length >= bytes.length;
    const data = stored ? bytes : deflated;
    const head = new DataView(new ArrayBuffer(30));
    head.setUint32(0, 0x04034b50, true);
    head.setUint16(4, 20, true);
    head.setUint16(8, stored ? 0 : 8, true);
    head.setUint16(12, 33, true); // 1980-01-01, the epoch a ZIP date field can hold
    head.setUint32(14, crc32(bytes), true);
    head.setUint32(18, data.length, true);
    head.setUint32(22, bytes.length, true);
    head.setUint16(26, nameBytes.length, true);
    local.push(new Uint8Array(head.buffer), nameBytes, data);

    const dir = new DataView(new ArrayBuffer(46));
    dir.setUint32(0, 0x02014b50, true);
    dir.setUint16(4, 20, true);
    dir.setUint16(6, 20, true);
    dir.setUint16(10, stored ? 0 : 8, true);
    dir.setUint16(14, 33, true);
    dir.setUint32(16, crc32(bytes), true);
    dir.setUint32(20, data.length, true);
    dir.setUint32(24, bytes.length, true);
    dir.setUint16(28, nameBytes.length, true);
    dir.setUint32(42, offset, true);
    central.push(new Uint8Array(dir.buffer), nameBytes);
    offset += 30 + nameBytes.length + data.length;
  }
  const centralSize = central.reduce((n, p) => n + p.length, 0);
  const end = new DataView(new ArrayBuffer(22));
  end.setUint32(0, 0x06054b50, true);
  end.setUint16(8, files.size, true);
  end.setUint16(10, files.size, true);
  end.setUint32(12, centralSize, true);
  end.setUint32(16, offset, true);
  return new Blob([...local, ...central, new Uint8Array(end.buffer)]);
}

const MIME = {
  png: 'image/png', jpg: 'image/jpeg', jpeg: 'image/jpeg', gif: 'image/gif',
  svg: 'image/svg+xml', bmp: 'image/bmp', webp: 'image/webp', avif: 'image/avif',
};
const mimeOf = (name) => MIME[(name.split('.').pop() || '').toLowerCase()] || 'application/octet-stream';

function dataUri(bytes, name) {
  let s = '';
  for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return `data:${mimeOf(name)};base64,${btoa(s)}`;
}

// Resolve `href` against `base` (a directory inside the archive) the way a browser
// would, so `../terminalsAndIcons/icon.svg` in documentation/index.html reaches the
// icon. Null for anything that is not a path inside the archive.
function resolveInZip(base, href) {
  if (!href || /^[a-z][a-z0-9+.-]*:/i.test(href) || href.startsWith('#')) return null;
  const parts = href.startsWith('/') ? [] : base.split('/').filter(Boolean);
  for (const seg of href.replace(/^\//, '').split('/')) {
    if (seg === '' || seg === '.') continue;
    if (seg === '..') { if (!parts.length) return null; parts.pop(); }
    else parts.push(seg);
  }
  return parts.join('/');
}

// The icon the driver took out of terminalsAndIcons/, as a data URI for an <img>.
export function iconDataUri(icon) {
  return icon && icon.bytes ? dataUri(icon.bytes, icon.name) : null;
}

// The FMU's documentation as HTML, from what the driver handed over: the entry
// point and the files beside it. It may be a whole document or a bare fragment;
// only the body survives, since the FMU's <style> would restyle the page around
// it and its <script> is not ours to run. Images are inlined — nothing inside an
// archive the browser never unpacked has a URL.
export function documentationHtml(doc_) {
  if (!doc_) return null;
  const { entry, files } = doc_;
  if (!entry || !files || !files.get(entry)) return null;
  const base = entry.slice(0, entry.lastIndexOf('/'));
  const doc = new DOMParser().parseFromString(new TextDecoder().decode(files.get(entry)), 'text/html');
  doc.querySelectorAll('script, style, link, meta, base, iframe, object, embed').forEach((e) => e.remove());
  // Parsing is inert, but the result goes into the page through innerHTML, where an
  // `onerror=` the FMU wrote would run. The FMU is a file someone was handed.
  for (const e of doc.querySelectorAll('*')) {
    for (const a of [...e.attributes]) if (a.name.toLowerCase().startsWith('on')) e.removeAttributeNode(a);
  }
  for (const img of doc.querySelectorAll('img[src], source[src]')) {
    const src = img.getAttribute('src');
    if (/^(data|https?):/i.test(src)) continue;
    const name = resolveInZip(base, src);
    const bytes = name && files.get(name);
    if (bytes) img.setAttribute('src', dataUri(bytes, name));
    else img.remove();                       // an image that did not travel with the FMU
  }
  for (const a of doc.querySelectorAll('a[href]')) {
    if (/^https?:/i.test(a.getAttribute('href'))) { a.target = '_blank'; a.rel = 'noopener'; }
    else a.removeAttribute('href');          // modelica:// class links mean nothing here
  }
  const html = doc.body.innerHTML.trim();
  return html || null;
}

