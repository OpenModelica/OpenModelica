//! A page to look at a run with, rather than read down a column of it.
//!
//! Everything the tables have is in the JSON already; what the page adds is the
//! pivot. Every measurement carries every dimension it was taken at - model,
//! format, filter pipeline, block size, writer, delay, threads, access - and
//! the controls choose which one goes along the x axis, which one separates the
//! lines, and what each of the rest is held at. Holding the settings and
//! colouring by format answers "which format is better here"; holding the
//! format and colouring by a setting answers "what is this format sensitive
//! to".
//!
//! Plotly comes off a CDN, so the page needs the network the first time it is
//! opened. The measurements are embedded, so nothing else does.

pub fn page(json: &str) -> String {
    TEMPLATE.replace("__DATA__", json)
}

const TEMPLATE: &str = r##"<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>OpenModelica result formats</title>
<script src="https://cdn.plot.ly/plotly-2.35.2.min.js" charset="utf-8"></script>
<style>
  :root { color-scheme: light dark; --line: #8883; }
  body { font: 14px/1.5 system-ui, sans-serif; margin: 0; padding: 1.5rem; }
  h1 { font-size: 1.3rem; margin: 0 0 .25rem; }
  .sub { opacity: .7; margin-bottom: 1rem; }
  .tabs { display: flex; gap: .25rem; margin-bottom: 1rem; }
  .tabs button { font: inherit; padding: .35rem .9rem; border: 1px solid var(--line);
                 background: transparent; border-radius: .4rem; cursor: pointer; }
  .tabs button[aria-selected=true] { background: #7772; font-weight: 600; }
  .panel { display: grid; grid-template-columns: 16rem 1fr; gap: 1.25rem; align-items: start; }
  .controls { display: flex; flex-direction: column; gap: .6rem; }
  .controls label { display: flex; flex-direction: column; gap: .15rem; font-size: .82rem; opacity: .85; }
  .controls select { font: inherit; padding: .25rem; }
  .presets { display: flex; flex-direction: column; gap: .35rem; margin-bottom: .5rem; }
  .presets button { font: inherit; font-size: .82rem; padding: .3rem; border: 1px solid var(--line);
                    background: transparent; border-radius: .3rem; cursor: pointer; text-align: left; }
  fieldset { border: 1px solid var(--line); border-radius: .4rem; padding: .5rem .6rem; margin: 0; }
  legend { font-size: .78rem; opacity: .7; }
  .chart { min-height: 460px; }
  table { border-collapse: collapse; font-size: .8rem; margin-top: 1rem; width: 100%; }
  th, td { border-bottom: 1px solid var(--line); padding: .2rem .5rem; text-align: right; }
  th:first-child, td:first-child, th.t, td.t { text-align: left; }
  .note { font-size: .82rem; opacity: .75; margin-top: .75rem; max-width: 60rem; }
</style>
</head>
<body>
<h1>OpenModelica result formats</h1>
<div class="sub" id="env"></div>
<div class="tabs" id="tabs"></div>
<div class="panel">
  <div class="controls" id="controls"></div>
  <div>
    <div class="chart" id="chart"></div>
    <div class="note" id="note"></div>
    <table id="table"></table>
  </div>
</div>
<script id="data" type="application/json">__DATA__</script>
<script>
const DATA = JSON.parse(document.getElementById("data").textContent);

const median = xs => {
  if (!xs || !xs.length) return NaN;
  const v = [...xs].sort((a, b) => a - b), n = v.length;
  return n % 2 ? v[(n - 1) / 2] : (v[n / 2 - 1] + v[n / 2]) / 2;
};
const lo = xs => (xs && xs.length ? Math.min(...xs) : NaN);
const hi = xs => (xs && xs.length ? Math.max(...xs) : NaN);
const perValue = r => Math.max(1, r.payload_bytes / 8);
const rate = (bytes, ms) => (ms > 0 ? bytes / 1e6 / (ms / 1e3) : NaN);
const totalMs = r => median(r.open_ms) + median(r.emit_ms) + median(r.close_ms) + median(r.fsync_ms);

// Each view names its rows, the dimensions they can be pivoted on, and the
// metrics that can go up the y axis. Everything else in the page is generic.
const VIEWS = {
  writing: {
    rows: DATA.writes,
    dims: [
      ["model", "model"], ["format", "format"], ["gzip", "gzip"],
      ["block_rows", "block rows"], ["chunk_cols", "chunk cols"],
      ["writer", "writer"], ["delay_ns", "delay per row (ns)"], ["rows", "rows"],
    ],
    metrics: {
      total_ms:  ["total ms (open+emit+close+fsync)", r => totalMs(r)],
      emit_ms:   ["emit ms (the row loop)", r => median(r.emit_ms)],
      open_ms:   ["open ms (the variable table)", r => median(r.open_ms)],
      close_ms:  ["close ms (finalisation)", r => median(r.close_ms)],
      fsync_ms:  ["fsync ms", r => median(r.fsync_ms)],
      stall_ms:  ["stall ms (row loop waiting for the writer thread)", r => median(r.stall_ms)],
      sys_ms:    ["sys ms (kernel time)", r => median(r.sys_ms)],
      step_pct:  ["% of a step", r => (r.delay_ns > 0 ? totalMs(r) / median(r.baseline_ms) * 100 : NaN)],
      ns_value:  ["ns per value emitted", r => median(r.emit_ms) * 1e6 / perValue(r)],
      emit_mbs:  ["MB/s written (open+emit+close)", r =>
        rate(r.payload_bytes, median(r.open_ms) + median(r.emit_ms) + median(r.close_ms))],
      file_mb:   ["file size (MB)", r => r.file_bytes / 1e6],
      file_ratio:["file size / payload", r => r.file_bytes / Math.max(1, r.payload_bytes)],
    },
    spread: (r, m) => (m === "total_ms" || m === "emit_ms"
      ? [median(r.emit_ms) - lo(r.emit_ms), hi(r.emit_ms) - median(r.emit_ms)] : null),
    defaults: { metric: "total_ms", x: "delay_ns", series: "format" },
  },
  reading: {
    rows: DATA.reads,
    dims: [
      ["model", "model"], ["format", "format"], ["gzip", "gzip"],
      ["block_rows", "block rows"], ["chunk_cols", "chunk cols"],
      ["access", "access"], ["threads", "threads"], ["cache", "cache"],
      ["variables", "variables read"],
    ],
    metrics: {
      total_ms: ["open + read ms", r => median(r.open_ms) + median(r.read_ms)],
      read_ms:  ["read ms", r => median(r.read_ms)],
      open_ms:  ["open ms", r => median(r.open_ms)],
      read_mbs: ["MB/s delivered (open+read)", r =>
        rate(r.delivered_bytes, median(r.open_ms) + median(r.read_ms))],
      held_mb:  ["memory still held (MB)", r => median(r.held_bytes) / 1e6],
      ms_var:   ["ms per variable", r => (median(r.open_ms) + median(r.read_ms)) / Math.max(1, r.variables)],
      file_mb:  ["file size (MB)", r => r.file_bytes / 1e6],
    },
    spread: (r, m) => (m === "read_ms" || m === "total_ms"
      ? [median(r.read_ms) - lo(r.read_ms), hi(r.read_ms) - median(r.read_ms)] : null),
    defaults: { metric: "total_ms", x: "variables", series: "format" },
  },
  structure: {
    rows: DATA.structure,
    dims: [["model", "model"], ["format", "format"], ["gzip", "gzip"],
           ["block_rows", "block rows"], ["chunk_cols", "chunk cols"]],
    metrics: {
      objects: ["objects in the file", r => r.objects],
      blocks:  ["independently stored blocks", r => r.blocks],
    },
    spread: () => null,
    defaults: { metric: "objects", x: "format", series: "model" },
  },
};

const NUMERIC = new Set(["delay_ns", "rows", "block_rows", "chunk_cols", "threads", "variables"]);
const state = {};
let view = "writing";

function values(rows, dim) {
  const seen = [...new Set(rows.map(r => r[dim]))];
  return NUMERIC.has(dim) ? seen.sort((a, b) => a - b) : seen.sort();
}

function label(dim, v) {
  if (dim === "delay_ns") return v === 0 ? "0" : v % 1e6 === 0 ? v / 1e6 + " ms"
    : v % 1e3 === 0 ? v / 1e3 + " us" : v + " ns";
  if (dim === "chunk_cols" && v === 0) return "all";
  if (dim === "variables" && v > 1e6) return "all";
  return String(v);
}

function init(name) {
  view = name;
  const v = VIEWS[name];
  if (!state[name]) {
    const s = { ...v.defaults, hold: {} };
    for (const [dim] of v.dims) {
      if (dim !== s.x && dim !== s.series) {
        // Pin every dimension that varies, so the first chart shown compares
        // one thing at a time; a dimension with a single value pins itself.
        const vals = values(v.rows, dim);
        s.hold[dim] = vals.length ? vals[0] : null;
      }
    }
    state[name] = s;
  }
  render();
}

function control(id, text, options, value, onchange) {
  const l = document.createElement("label");
  l.textContent = text;
  const sel = document.createElement("select");
  sel.id = id;
  for (const [val, name] of options) {
    const o = document.createElement("option");
    o.value = val; o.textContent = name;
    if (String(val) === String(value)) o.selected = true;
    sel.appendChild(o);
  }
  sel.onchange = () => onchange(sel.value);
  l.appendChild(sel);
  return l;
}

function render() {
  const v = VIEWS[view], s = state[view];
  const c = document.getElementById("controls");
  c.innerHTML = "";

  const presets = document.createElement("div");
  presets.className = "presets";
  presets.appendChild(button("Compare formats", () => {
    if (s.x === "format") s.x = firstVarying(["format"]);
    s.series = "format";
    repin(); render();
  }));
  presets.appendChild(button("Compare settings, one format", () => {
    const fmt = richestFormat();
    const mine = v.rows.filter(r => String(r.format) === String(fmt));
    if (s.x === "format") s.x = firstVaryingIn(mine, ["format"]);
    // The model is not a setting: it is the series of last resort, when the run
    // swept nothing else.
    s.series = firstVaryingIn(mine, ["format", s.x, "model"], true)
      || firstVaryingIn(mine, ["format", s.x]);
    repin();
    s.hold.format = fmt;
    render();
  }));
  c.appendChild(presets);

  c.appendChild(control("metric", "Metric",
    Object.entries(v.metrics).map(([k, m]) => [k, m[0]]), s.metric,
    val => { s.metric = val; render(); }));
  c.appendChild(control("x", "X axis", v.dims, s.x,
    val => { s.x = val; repin(); render(); }));
  c.appendChild(control("series", "One line per", [["", "(nothing)"], ...v.dims], s.series,
    val => { s.series = val; repin(); render(); }));

  const fs = document.createElement("fieldset");
  fs.appendChild(Object.assign(document.createElement("legend"), { textContent: "Held constant" }));
  for (const [dim, name] of v.dims) {
    if (dim === s.x || dim === s.series) continue;
    const vals = values(v.rows, dim);
    fs.appendChild(control("hold-" + dim, name,
      [["", "(all)"], ...vals.map(x => [x, label(dim, x)])],
      s.hold[dim] === null || s.hold[dim] === undefined ? "" : s.hold[dim],
      val => { s.hold[dim] = val === "" ? null : (NUMERIC.has(dim) ? Number(val) : val); render(); }));
  }
  c.appendChild(fs);

  draw();
}

/// The first dimension that actually varies, for the presets: pinning a
/// dimension with one value would leave the chart with a single bar.
function firstVarying(exclude) {
  return firstVaryingIn(VIEWS[view].rows, exclude);
}

function firstVaryingIn(rows, exclude, strict) {
  const dims = VIEWS[view].dims.map(([d]) => d).filter(d => !exclude.includes(d));
  const found = dims.find(d => new Set(rows.map(r => r[d])).size > 1);
  return found || (strict ? null : dims[0]);
}

/// The format with the most settings measured on it: `--deflate` and
/// `--chunk-cols` only reach the HDF5 formats, so pinning the alphabetically
/// first one would show a chart with nothing to compare.
function richestFormat() {
  const v = VIEWS[view];
  let best = null, score = -1;
  for (const f of values(v.rows, "format")) {
    const mine = v.rows.filter(r => String(r.format) === String(f));
    const n = v.dims.filter(([d]) => d !== "format")
      .reduce((acc, [d]) => acc * Math.max(1, new Set(mine.map(r => r[d])).size), 1);
    if (n > score) { score = n; best = f; }
  }
  return best;
}

function button(text, fn) {
  const b = document.createElement("button");
  b.textContent = text; b.onclick = fn;
  return b;
}

/// Anything that stops being the x axis or the series has to be pinned again,
/// or the chart silently averages over it.
function repin() {
  const v = VIEWS[view], s = state[view];
  for (const [dim] of v.dims) {
    if (dim === s.x || dim === s.series) { delete s.hold[dim]; continue; }
    if (s.hold[dim] === undefined) {
      const vals = values(v.rows, dim);
      s.hold[dim] = vals.length ? vals[0] : null;
    }
  }
}

function filtered() {
  const v = VIEWS[view], s = state[view];
  return v.rows.filter(r => Object.entries(s.hold).every(([d, val]) =>
    val === null || val === undefined || String(r[d]) === String(val)));
}

function draw() {
  const v = VIEWS[view], s = state[view];
  const rows = filtered();
  const metric = v.metrics[s.metric];
  const xs = values(rows, s.x);
  const groups = s.series ? values(rows, s.series) : [null];
  const numericX = NUMERIC.has(s.x);

  const traces = groups.map(g => {
    const mine = s.series ? rows.filter(r => String(r[s.series]) === String(g)) : rows;
    const y = [], plus = [], minus = [], text = [];
    for (const x of xs) {
      const cell = mine.filter(r => String(r[s.x]) === String(x));
      // Several rows in one cell mean a dimension is loose; the mean says so
      // without hiding it, and the "Held constant" panel is how to fix it.
      const vals = cell.map(metric[1]).filter(Number.isFinite);
      y.push(vals.length ? vals.reduce((a, b) => a + b, 0) / vals.length : null);
      const err = cell.length === 1 ? v.spread(cell[0], s.metric) : null;
      minus.push(err ? err[0] : 0);
      plus.push(err ? err[1] : 0);
      text.push(cell.length > 1 ? cell.length + " rows averaged" : "");
    }
    return {
      x: xs.map(x => label(s.x, x)),
      y, text,
      name: s.series ? label(s.series, g) : metric[0],
      type: numericX ? "scatter" : "bar",
      mode: "lines+markers",
      error_y: plus.some(p => p > 0) ? { type: "data", array: plus, arrayminus: minus, visible: true } : undefined,
    };
  });

  const dark = matchMedia("(prefers-color-scheme: dark)").matches;
  Plotly.newPlot("chart", traces, {
    margin: { t: 20, r: 20, b: 60, l: 70 },
    xaxis: { title: v.dims.find(([d]) => d === s.x)[1], type: "category" },
    yaxis: { title: metric[0], rangemode: "tozero" },
    barmode: "group",
    paper_bgcolor: "rgba(0,0,0,0)",
    plot_bgcolor: "rgba(0,0,0,0)",
    font: { color: dark ? "#ddd" : "#222" },
    legend: { orientation: "h", y: -0.2 },
  }, { responsive: true, displaylogo: false });

  table(rows, metric);
  document.getElementById("note").textContent = note(rows);
}

function note(rows) {
  const s = state[view];
  const loose = VIEWS[view].dims
    .filter(([d]) => d !== s.x && d !== s.series && (s.hold[d] === null || s.hold[d] === undefined))
    .map(([, n]) => n);
  const base = rows.length + " measurements shown, median of " + DATA.reps + " repetitions each.";
  return loose.length ? base + " Averaged over: " + loose.join(", ") + "." : base;
}

function table(rows, metric) {
  const v = VIEWS[view], s = state[view];
  const cols = v.dims.map(([d]) => d);
  let html = "<tr>" + v.dims.map(([, n]) => "<th class=t>" + n + "</th>").join("")
    + "<th>" + metric[0] + "</th></tr>";
  const sorted = [...rows].sort((a, b) => (metric[1](a) || 0) - (metric[1](b) || 0));
  for (const r of sorted.slice(0, 200)) {
    html += "<tr>" + cols.map(d => "<td class=t>" + label(d, r[d]) + "</td>").join("")
      + "<td>" + fmt(metric[1](r)) + "</td></tr>";
  }
  document.getElementById("table").innerHTML = html;
}

const fmt = x => (!Number.isFinite(x) ? "-" : Math.abs(x) >= 100 ? x.toFixed(0)
  : Math.abs(x) >= 1 ? x.toFixed(2) : x.toPrecision(3));

document.getElementById("env").textContent =
  "HDF5 " + DATA.hdf5 + " (" + DATA.hdf5_concurrency + "), arrow-rs " + DATA.arrow
  + ", files on " + DATA.filesystem + ", " + DATA.reps + " repetitions per cell, writer thread "
  + DATA.handoff + " rows per handover x " + DATA.queue + " in flight.";

const tabs = document.getElementById("tabs");
for (const name of Object.keys(VIEWS)) {
  const b = button(name[0].toUpperCase() + name.slice(1), () => {
    for (const other of tabs.children) other.setAttribute("aria-selected", other === b);
    init(name);
  });
  b.setAttribute("aria-selected", name === "writing");
  tabs.appendChild(b);
}
init("writing");
</script>
</body>
</html>
"##;
