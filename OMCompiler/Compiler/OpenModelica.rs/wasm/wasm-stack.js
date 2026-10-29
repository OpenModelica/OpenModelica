// Summarises the wasm frames of an error caught from the omc module (a trap or
// a stack overflow), for the message the page shows. A release build has no
// name section, so the frames are only function indices; the summary then
// links to symbolize.html, which maps them to names with the symbol map
// wasm-opt wrote next to the module. The map is only fetched on that page.

// The default of 10 frames would only show the innermost recursion.
Error.stackTraceLimit = 100000;

const MAX_TOKENS = 400;
const MAX_PERIOD = 32;

export function cleanName(name) {
  return name.replace(/^\S*?\.wasm\./, '').replace(/\[[0-9a-f]{12,16}\]/g, '');
}

// Consecutive frames in the same function form one run; the offsets within it
// tell recursive call sites apart.
function wasmRuns(stack) {
  const runs = [];
  for (const m of stack.matchAll(/(?:at ([^\n]+) \()?[^\s(]*wasm-function\[(\d+)\]:0x([0-9a-f]+)/g)) {
    const [, name, index, offset] = m;
    let run = runs[runs.length - 1];
    if (!run || run.index !== index) {
      run = { index, name, count: 0, offsets: new Map() };
      runs.push(run);
    }
    run.count++;
    run.offsets.set(offset, (run.offsets.get(offset) || 0) + 1);
  }
  return runs;
}

function encodeRun(run) {
  let s = run.index;
  for (const [offset, n] of run.offsets) s += '@' + offset + (n > 1 ? '*' + n : '');
  return s;
}

// Mutual recursion repeats a cycle of runs; write each repetition once.
function compressCycles(keys) {
  const out = [];
  const same = (a, b, k) => {
    for (let j = 0; j < k; j++) if (keys[a + j] !== keys[b + j]) return false;
    return true;
  };
  for (let i = 0; i < keys.length; ) {
    let best = { k: 0, r: 1 };
    for (let k = 1; k <= MAX_PERIOD && i + 2 * k <= keys.length; k++) {
      let r = 1;
      while (i + (r + 1) * k <= keys.length && same(i, i + r * k, k)) r++;
      if (r > 1 && k * r > best.k * best.r) best = { k, r };
    }
    if (best.k) {
      out.push(`(${keys.slice(i, i + best.k).join(';')})*${best.r}`);
      i += best.k * best.r;
    } else {
      out.push(keys[i++]);
    }
  }
  return out;
}

export function describeError(err, msg = String(err)) {
  const runs = wasmRuns(err && typeof err.stack === 'string' ? err.stack : '');
  if (!runs.length) return msg;
  const perFunction = new Map();
  for (const r of runs) perFunction.set(r.index, (perFunction.get(r.index) || 0) + r.count);
  const [topIndex, topCount] = [...perFunction].reduce((a, b) => (b[1] > a[1] ? b : a));
  const topName = runs.find((r) => r.index === topIndex).name;
  const frames = runs.reduce((n, r) => n + r.count, 0);
  let line = `${frames} wasm frames, ${topCount} in ${topName ? cleanName(topName) : `wasm-function[${topIndex}]`}.`;
  if (!runs.some((r) => r.name)) {
    let tokens = compressCycles(runs.map(encodeRun));
    if (tokens.length > MAX_TOKENS) {
      tokens = [...tokens.slice(0, MAX_TOKENS / 2), '~', ...tokens.slice(-MAX_TOKENS / 2)];
    }
    line += ` Function names: ${new URL('symbolize.html#' + tokens.join(','), import.meta.url)}`;
  }
  return `${msg}\n${line}`;
}

// Sets `text` as the content of `el`, with the symbolize.html link clickable.
export function setErrorText(el, text) {
  el.replaceChildren();
  let last = 0;
  for (const m of text.matchAll(/\S*symbolize\.html#\S*/g)) {
    el.append(text.slice(last, m.index));
    const a = document.createElement('a');
    a.href = a.textContent = m[0];
    a.target = '_blank';
    el.append(a);
    last = m.index + m[0].length;
  }
  el.append(text.slice(last));
}
