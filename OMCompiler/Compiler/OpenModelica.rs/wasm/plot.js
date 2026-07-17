// The chart engine shared by the Modelica simulator and the FMI simulator: an
// SVG line plot per figure, with a hover cursor, a toggling legend, and Modelica
// unit rendering. The pages supply the curves; everything here is presentation.
//
// createCharts(container) owns the charts in one plot area. A chart spec is:
//   { curves:[{ label, unit, color, xs, ys }], title, xText, xUnit, yText, yUnit,
//     yLog, yMin, yMax, solo, note, xLabel, xIsTime }
// and `key` namespaces the legend's hidden-series memory across re-runs.

export const COLORS = ['#3987e5','#199e70','#c98500','#008300','#9085e9','#e66767','#d55181','#d95926'];

const SVGNS = 'http://www.w3.org/2000/svg';
function svg(tag, attrs) { const e = document.createElementNS(SVGNS, tag); for (const k in attrs) e.setAttribute(k, attrs[k]); return e; }
function niceStep(range, target) { const raw = range / target, mag = Math.pow(10, Math.floor(Math.log10(raw))), n = raw / mag;
  return (n < 1.5 ? 1 : n < 3 ? 2 : n < 7 ? 5 : 10) * mag; }
function fmt(v) { if (v === 0) return '0'; const a = Math.abs(v);
  return (a >= 1e4 || a < 1e-3) ? v.toExponential(1) : (+v.toPrecision(4)).toString(); }

// --- Modelica unit rendering ------------------------------------------------
export function escapeHtml(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
// Parse a Modelica unit ("m/s2", "kg.m/s2", "W/(m.K)", "s-1") into numerator and
// denominator factors, each with a positive integer exponent. '.' multiplies,
// '/' starts the denominator, a trailing (signed) integer is the exponent.
function parseUnit(u) {
  if (!u) return null;
  const num = [], den = []; let denom = false;
  for (const tok of u.split(/([./()])/)) {
    if (tok === '/') { denom = true; continue; }
    if (tok === '' || tok === '.' || tok === '(' || tok === ')') continue;
    const m = tok.match(/^(.*?)([+-]?\d+)$/);
    let sym = tok, exp = 1;
    if (m && m[1]) { sym = m[1]; exp = parseInt(m[2], 10); }
    if (sym === '1') continue;
    const e = exp * (denom ? -1 : 1);
    (e < 0 ? den : num).push({ s: sym, e: Math.abs(e) });
  }
  return (num.length || den.length) ? { num, den } : null;
}
function factorsHTML(list) { return list.map((f) => escapeHtml(f.s) + (f.e !== 1 ? '<sup>' + f.e + '</sup>' : '')).join('·'); }
// A unit as HTML: superscript exponents, and a stacked fraction when it divides.
export function unitHTML(u) {
  const p = parseUnit(u); if (!p) return '';
  if (!p.den.length) return factorsHTML(p.num);
  return '<span class="frac"><span class="fn">' + (p.num.length ? factorsHTML(p.num) : '1') + '</span>'
    + '<span class="fd">' + factorsHTML(p.den) + '</span></span>';
}
export function labelHTML(text, unit) {
  const u = unit ? unitHTML(unit) : '', t = text ? escapeHtml(text) : '';
  return t && u ? t + ' ' + u : (t || u);
}

export function createCharts(container) {
  const charts = [];
  const hidden = new Set();   // "chartKey|label" of series toggled off (persists across runs)

  function add(spec, key) {
    const card = document.createElement('div'); card.className = 'chart-card' + (spec.solo ? ' solo' : '');
    if (spec.title) { const h = document.createElement('div'); h.className = 'plot-head'; h.textContent = spec.title; card.appendChild(h); }
    const wrap = document.createElement('div'); wrap.className = 'plot-wrap';
    const s = svg('svg', { class: 'plot', preserveAspectRatio: 'none' });
    const tip = document.createElement('div'); tip.className = 'tooltip';
    const note = document.createElement('div'); note.className = 'plot-note'; note.style.display = 'none';
    const xlab = document.createElement('div'); xlab.className = 'xlabel';
    const ylab = document.createElement('div'); ylab.className = 'ylabel';
    wrap.append(s, tip, note, xlab, ylab); card.appendChild(wrap);
    const legend = document.createElement('div'); legend.className = 'legend'; card.appendChild(legend);
    container.appendChild(card);

    const chart = { spec, key, svgEl: s, tip, wrap, note, xlabel: xlab, ylabel: ylab, state: null };
    charts.push(chart);

    legend.replaceChildren();
    if (!spec.curves.length) { legend.innerHTML = '<span class="empty">—</span>'; }
    for (const c of spec.curves) {
      const item = document.createElement('div');
      const k = key + '|' + c.label;
      item.className = 'item' + (hidden.has(k) ? ' off' : ''); item.title = c.label;
      item.innerHTML = '<span class="sw" style="background:' + c.color + '"></span>';
      item.append(c.label + ' ');
      if (c.unit) { const u = document.createElement('span'); u.className = 'u'; u.innerHTML = unitHTML(c.unit); item.append(u); }
      item.onclick = () => { if (hidden.has(k)) hidden.delete(k); else hidden.add(k);
        item.classList.toggle('off', hidden.has(k)); draw(chart); };
      legend.appendChild(item);
    }
    draw(chart);
  }

  function draw(chart) {
    const { spec, key, svgEl, tip, note } = chart;
    svgEl.replaceChildren(); tip.style.display = 'none';
    const active = spec.curves.filter((c) => !hidden.has(key + '|' + c.label));
    if (!active.length) { note.style.display = 'grid'; note.textContent = spec.note || (spec.curves.length ? 'No variables selected.' : 'No variables to plot.');
      chart.xlabel.innerHTML = ''; chart.ylabel.innerHTML = ''; chart.state = null; return; }
    note.style.display = 'none';

    const W = svgEl.clientWidth || 800, H = svgEl.clientHeight || 360;
    svgEl.setAttribute('viewBox', `0 0 ${W} ${H}`);
    const m = { l: 64, r: 14, t: 12, b: 30 }, iw = W - m.l - m.r, ih = H - m.t - m.b;
    let xMin = Infinity, xMax = -Infinity, yMin = Infinity, yMax = -Infinity;
    for (const c of active) { for (const v of c.xs) { if (v < xMin) xMin = v; if (v > xMax) xMax = v; }
      for (const v of c.ys) { if (v < yMin) yMin = v; if (v > yMax) yMax = v; } }
    if (!isFinite(xMin)) { xMin = 0; xMax = 1; } if (xMin === xMax) xMax = xMin + 1;
    if (spec.yMin != null) yMin = spec.yMin; if (spec.yMax != null) yMax = spec.yMax;
    if (!isFinite(yMin)) { yMin = 0; yMax = 1; } if (yMin === yMax) { yMin -= 1; yMax += 1; }
    const yLog = spec.yLog && yMin > 0 && yMax > 0;
    if (!yLog) { const pad = (yMax - yMin) * 0.05; yMin -= pad; yMax += pad; }
    const tY = yLog ? Math.log10 : (y) => y;
    const yLo = tY(yMin), yHi = tY(yMax);
    const px = (x) => m.l + (x - xMin) / (xMax - xMin) * iw;
    const py = (y) => m.t + (1 - (tY(y) - yLo) / (yHi - yLo)) * ih;

    const grid = svg('g', {});
    const gridline = (x1, y1, x2, y2, stroke) => grid.appendChild(svg('line', { x1, y1, x2, y2, stroke, 'stroke-width': 1 }));
    const label = (x, y, anchor, txt) => { const t = svg('text', { x, y, fill: '#8a8a8a', 'font-size': 11, 'text-anchor': anchor }); t.textContent = txt; grid.appendChild(t); };
    if (yLog) {
      for (let p = Math.floor(Math.log10(yMin)); p <= Math.ceil(Math.log10(yMax)); p++) {
        const v = Math.pow(10, p); if (v < yMin || v > yMax) continue; const y = py(v);
        gridline(m.l, y, W - m.r, y, '#333'); label(m.l - 6, y + 4, 'end', fmt(v));
      }
    } else {
      const yStep = niceStep(yMax - yMin, 5);
      for (let v = Math.ceil(yMin / yStep) * yStep; v <= yMax; v += yStep) { const y = py(v);
        gridline(m.l, y, W - m.r, y, '#333'); label(m.l - 6, y + 4, 'end', fmt(v)); }
    }
    const xStep = niceStep(xMax - xMin, 6);
    for (let v = Math.ceil(xMin / xStep) * xStep; v <= xMax; v += xStep) { const x = px(v);
      gridline(x, m.t, x, H - m.b, '#2a2a2a'); label(x, H - m.b + 16, 'middle', fmt(v)); }
    svgEl.appendChild(grid);
    svgEl.appendChild(svg('line', { x1: m.l, y1: m.t, x2: m.l, y2: H - m.b, stroke: '#555', 'stroke-width': 1 }));
    svgEl.appendChild(svg('line', { x1: m.l, y1: H - m.b, x2: W - m.r, y2: H - m.b, stroke: '#555', 'stroke-width': 1 }));

    for (const c of active) {
      let d = '';
      for (let i = 0; i < c.xs.length && i < c.ys.length; i++) d += (i ? 'L' : 'M') + px(c.xs[i]).toFixed(1) + ' ' + py(c.ys[i]).toFixed(1);
      svgEl.appendChild(svg('path', { d, fill: 'none', stroke: c.color, 'stroke-width': 1.6 }));
    }
    // Axis titles are HTML overlays (not SVG text) so units render as stacked fractions.
    let yUnit = spec.yUnit;
    if (!yUnit) { const us = [...new Set(active.map((c) => c.unit).filter(Boolean))]; if (us.length === 1) yUnit = us[0]; }
    chart.xlabel.innerHTML = labelHTML(spec.xText || '', spec.xUnit || '');
    const yl = labelHTML(spec.yText || '', yUnit || '');
    chart.ylabel.innerHTML = yl ? '<span class="rot">' + yl + '</span>' : '';

    const cursor = svg('g', { style: 'display:none' });
    const vline = svg('line', { y1: m.t, y2: H - m.b, stroke: '#888', 'stroke-width': 1, 'stroke-dasharray': '3 3' });
    cursor.appendChild(vline);
    const dots = active.map((c) => svg('circle', { r: 3.5, fill: c.color, stroke: '#1e1e1e', 'stroke-width': 1 }));
    dots.forEach((d) => cursor.appendChild(d));
    svgEl.appendChild(cursor);
    chart.state = { active, px, py, geom: { m, W, H }, cursor, vline, dots };
  }

  function hover(ev, chart) {
    const st = chart.state; if (!st) return;
    const { active, px, py, geom, cursor, vline, dots } = st;
    const rect = chart.svgEl.getBoundingClientRect();
    const vbX = (ev.clientX - rect.left) / rect.width * geom.W;
    if (vbX < geom.m.l || vbX > geom.W - geom.m.r) { cursor.setAttribute('style', 'display:none'); chart.tip.style.display = 'none'; return; }
    const idxNearest = (xs) => { let best = 0, bd = Infinity; for (let i = 0; i < xs.length; i++) { const d = Math.abs(px(xs[i]) - vbX); if (d < bd) { bd = d; best = i; } } return best; };
    const i0 = idxNearest(active[0].xs);
    cursor.setAttribute('style', ''); vline.setAttribute('x1', px(active[0].xs[i0])); vline.setAttribute('x2', px(active[0].xs[i0]));
    let html = '';
    active.forEach((c, k) => { const i = c.xs === active[0].xs ? i0 : idxNearest(c.xs);
      dots[k].setAttribute('cx', px(c.xs[i])); dots[k].setAttribute('cy', py(c.ys[i]));
      html += '<div class="row"><span class="sw" style="background:' + c.color + '"></span>'
        + escapeHtml(c.label) + ' = ' + (+c.ys[i].toPrecision(6)) + (c.unit ? ' ' + unitHTML(c.unit) : '') + '</div>'; });
    const xLbl = (chart.spec.xLabel || 'x').replace(/\s*\[.*\]$/, '');
    chart.tip.innerHTML = '<div class="t">' + xLbl + ' = ' + (+active[0].xs[i0].toPrecision(6)) + '</div>' + html;
    chart.tip.style.display = 'block';
    const wrap = chart.wrap.getBoundingClientRect();
    let tx = ev.clientX - wrap.left + 14, ty = ev.clientY - wrap.top + 12;
    if (tx + chart.tip.offsetWidth > wrap.width) tx = ev.clientX - wrap.left - chart.tip.offsetWidth - 14;
    if (ty + chart.tip.offsetHeight > wrap.height) ty = wrap.height - chart.tip.offsetHeight - 4;
    chart.tip.style.left = tx + 'px'; chart.tip.style.top = ty + 'px';
  }

  const at = (target) => charts.find((c) => c.svgEl === target || c.svgEl.contains(target));
  container.addEventListener('mousemove', (ev) => { const c = at(ev.target); if (c) hover(ev, c); });
  container.addEventListener('mouseleave', () => { for (const c of charts) { if (c.state) c.state.cursor.setAttribute('style', 'display:none'); c.tip.style.display = 'none'; } }, true);

  return {
    list: charts, hidden, add, at,
    redraw: () => { for (const c of charts) draw(c); },
    // Empties the plot area; any nodes passed are kept (the "no results" note).
    clear: (...keep) => { container.replaceChildren(...keep); charts.length = 0; },
  };
}
