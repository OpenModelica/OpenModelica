// A .zip file whose stored (not compressed) entries are the files' own Blobs, so
// it takes no memory however big they are. ZIP64 from 4 GB or 65535 entries.

const MAX16 = 0xffff;
const MAX32 = 0xffffffff;

const TABLE = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();

// The CRC-32 of `bytes`, continuing from the CRC-32 `crc` of what came before.
export function crc32(crc, bytes) {
  let c = ~crc;
  for (let i = 0; i < bytes.length; i++) c = TABLE[(c ^ bytes[i]) & 0xff] ^ (c >>> 8);
  return ~c >>> 0;
}

function u64(view, at, v) {
  view.setUint32(at, v % 2 ** 32, true);
  view.setUint32(at + 4, Math.floor(v / 2 ** 32), true);
}

// MS-DOS date and time, in local time as unzip tools read them.
function dosTime(ms) {
  const d = new Date(Math.max(ms || 0, new Date(1980, 0, 1).getTime()));
  return {
    time: (d.getHours() << 11) | (d.getMinutes() << 5) | (d.getSeconds() >> 1),
    date: ((d.getFullYear() - 1980) << 9) | ((d.getMonth() + 1) << 5) | d.getDate(),
  };
}

// `entries`: { name, blob, crc, mtime } for a file, { name: 'dir/', mtime } for
// a folder. Names use '/' and are relative to the root of the archive.
export function zipBlob(entries) {
  const utf8 = new TextEncoder();
  const parts = [];
  const central = [];
  let offset = 0;
  for (const e of entries) {
    const name = utf8.encode(e.name);
    const size = e.blob ? e.blob.size : 0;
    const big = size >= MAX32;
    const { time, date } = dosTime(e.mtime);
    const h = new DataView(new ArrayBuffer(30 + name.length + (big ? 20 : 0)));
    h.setUint32(0, 0x04034b50, true);
    h.setUint16(4, big ? 45 : 20, true);
    h.setUint16(6, 0x0800, true);
    h.setUint16(10, time, true);
    h.setUint16(12, date, true);
    h.setUint32(14, e.crc || 0, true);
    h.setUint32(18, big ? MAX32 : size, true);
    h.setUint32(22, big ? MAX32 : size, true);
    h.setUint16(26, name.length, true);
    h.setUint16(28, big ? 20 : 0, true);
    new Uint8Array(h.buffer).set(name, 30);
    if (big) {
      h.setUint16(30 + name.length, 1, true);
      h.setUint16(32 + name.length, 16, true);
      u64(h, 34 + name.length, size);
      u64(h, 42 + name.length, size);
    }
    parts.push(h);
    if (e.blob) parts.push(e.blob);
    central.push({ name, size, crc: e.crc || 0, time, date, offset, dir: !e.blob });
    offset += h.byteLength + size;
  }

  const start = offset;
  for (const c of central) {
    const extra = [];
    if (c.size >= MAX32) extra.push(c.size, c.size);
    if (c.offset >= MAX32) extra.push(c.offset);
    const xlen = extra.length ? 4 + 8 * extra.length : 0;
    const h = new DataView(new ArrayBuffer(46 + c.name.length + xlen));
    h.setUint32(0, 0x02014b50, true);
    h.setUint16(4, 45, true);
    h.setUint16(6, xlen ? 45 : 20, true);
    h.setUint16(8, 0x0800, true);
    h.setUint16(12, c.time, true);
    h.setUint16(14, c.date, true);
    h.setUint32(16, c.crc, true);
    h.setUint32(20, Math.min(c.size, MAX32), true);
    h.setUint32(24, Math.min(c.size, MAX32), true);
    h.setUint16(28, c.name.length, true);
    h.setUint16(30, xlen, true);
    h.setUint32(38, c.dir ? 0x10 : 0, true);
    h.setUint32(42, Math.min(c.offset, MAX32), true);
    new Uint8Array(h.buffer).set(c.name, 46);
    if (xlen) {
      h.setUint16(46 + c.name.length, 1, true);
      h.setUint16(48 + c.name.length, 8 * extra.length, true);
      extra.forEach((v, i) => u64(h, 50 + c.name.length + 8 * i, v));
    }
    parts.push(h);
    offset += h.byteLength;
  }

  const count = central.length;
  const length = offset - start;
  if (count >= MAX16 || start >= MAX32 || length >= MAX32) {
    const z = new DataView(new ArrayBuffer(76));
    z.setUint32(0, 0x06064b50, true);
    u64(z, 4, 44);
    z.setUint16(12, 45, true);
    z.setUint16(14, 45, true);
    u64(z, 24, count);
    u64(z, 32, count);
    u64(z, 40, length);
    u64(z, 48, start);
    z.setUint32(56, 0x07064b50, true);
    u64(z, 64, offset);
    z.setUint32(72, 1, true);
    parts.push(z);
  }
  const end = new DataView(new ArrayBuffer(22));
  end.setUint32(0, 0x06054b50, true);
  end.setUint16(8, Math.min(count, MAX16), true);
  end.setUint16(10, Math.min(count, MAX16), true);
  end.setUint32(12, Math.min(length, MAX32), true);
  end.setUint32(16, Math.min(start, MAX32), true);
  parts.push(end);
  return new Blob(parts, { type: 'application/zip' });
}

// ── reading ──────────────────────────────────────────────────────────────────

const view = async (blob, at, length) => new DataView(await blob.slice(at, at + length).arrayBuffer());
const get64 = (v, at) => v.getUint32(at, true) + v.getUint32(at + 4, true) * 2 ** 32;

function fromDos(date, time) {
  return new Date((date >> 9) + 1980, ((date >> 5) & 15) - 1, date & 31,
    time >> 11, (time >> 5) & 63, (time & 31) * 2).getTime();
}

function decodeName(bytes, utf8Flag) {
  if (!utf8Flag) {
    try {
      return new TextDecoder('utf-8', { fatal: true }).decode(bytes);
    } catch {
      return new TextDecoder('latin1').decode(bytes);
    }
  }
  return new TextDecoder().decode(bytes);
}

// The entries of the archive `blob`: { name, dir, size, mtime } and what
// entryData needs. Throws for what is not a .zip file.
export async function readZip(blob) {
  const tailLength = Math.min(blob.size, 22 + MAX16);
  const tail = await view(blob, blob.size - tailLength, tailLength);
  let end = -1;
  for (let i = tailLength - 22; i >= 0; i--) {
    if (tail.getUint32(i, true) === 0x06054b50) { end = i; break; }
  }
  if (end < 0) throw new Error('This is not a .zip file.');
  let count = tail.getUint16(end + 10, true);
  let length = tail.getUint32(end + 12, true);
  let start = tail.getUint32(end + 16, true);
  if (count === MAX16 || length === MAX32 || start === MAX32) {
    const locator = end - 20;
    if (locator < 0 || tail.getUint32(locator, true) !== 0x07064b50) throw new Error('The ZIP64 end record is missing.');
    const z = await view(blob, get64(tail, locator + 8), 56);
    if (z.getUint32(0, true) !== 0x06064b50) throw new Error('The ZIP64 end record is damaged.');
    count = get64(z, 32);
    length = get64(z, 40);
    start = get64(z, 48);
  }
  const cd = await view(blob, start, length);
  const entries = [];
  for (let at = 0, i = 0; i < count; i++) {
    if (cd.getUint32(at, true) !== 0x02014b50) throw new Error('The .zip file is damaged.');
    const flags = cd.getUint16(at + 8, true);
    const nameLength = cd.getUint16(at + 28, true);
    const extraLength = cd.getUint16(at + 30, true);
    const name = decodeName(new Uint8Array(cd.buffer, cd.byteOffset + at + 46, nameLength), flags & 0x800);
    const e = {
      name, dir: name.endsWith('/'), encrypted: !!(flags & 1), method: cd.getUint16(at + 10, true),
      mtime: fromDos(cd.getUint16(at + 14, true), cd.getUint16(at + 12, true)), crc: cd.getUint32(at + 16, true),
      packed: cd.getUint32(at + 20, true), size: cd.getUint32(at + 24, true), offset: cd.getUint32(at + 42, true),
    };
    for (let x = at + 46 + nameLength; x + 4 <= at + 46 + nameLength + extraLength;) {
      const id = cd.getUint16(x, true);
      const n = cd.getUint16(x + 2, true);
      if (id === 1) {
        let f = x + 4;
        for (const key of ['size', 'packed', 'offset']) {
          if (e[key] === MAX32 && f + 8 <= x + 4 + n) { e[key] = get64(cd, f); f += 8; }
        }
      }
      x += 4 + n;
    }
    entries.push(e);
    at += 46 + nameLength + extraLength + cd.getUint16(at + 32, true);
  }
  return entries;
}

// The contents of entry `e` of the archive `blob`.
export async function entryData(blob, e) {
  if (e.encrypted) throw new Error(`${e.name} is encrypted.`);
  const local = await view(blob, e.offset, 30);
  if (local.getUint32(0, true) !== 0x04034b50) throw new Error('The .zip file is damaged.');
  const at = e.offset + 30 + local.getUint16(26, true) + local.getUint16(28, true);
  const data = blob.slice(at, at + e.packed);
  if (e.method === 0) return data;
  if (e.method !== 8) throw new Error(`${e.name} uses compression method ${e.method}, which cannot be read here.`);
  return new Response(data.stream().pipeThrough(new DecompressionStream('deflate-raw'))).blob();
}
