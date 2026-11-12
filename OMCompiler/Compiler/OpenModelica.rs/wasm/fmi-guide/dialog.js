// The settings guide as a dialog for a page that exports FMUs. It asks the
// questions that matter for the settings the page can set and hands the
// recommended values to the page. omc holds the questions and decides
// (openmodelica_fmi_guide); this file only draws. Uses the modal classes of
// ../theme.css.

const answers = {};
let model = null;
let dialog = null;

const STYLE = `
.fg-modal { width:min(980px,100%); max-height:calc(100vh - 32px); display:flex; flex-direction:column; }
.fg-body { flex:1 1 auto; min-height:0; display:grid; grid-template-columns:minmax(0,1fr) minmax(0,1fr); }
.fg-col { min-height:0; overflow-y:auto; padding:14px; }
.fg-col + .fg-col { border-left:1px solid var(--border); }
@media (max-width:760px) {
  .fg-body { grid-template-columns:minmax(0,1fr); overflow-y:auto; }
  .fg-col { overflow:visible; }
  .fg-col + .fg-col { border-left:0; border-top:1px solid var(--border); }
}
.fg-group { font-size:11px; text-transform:uppercase; letter-spacing:.06em; color:var(--muted); margin:16px 0 8px; }
.fg-group:first-child { margin-top:0; }
.fg-q { margin-bottom:12px; }
.fg-q.off .fg-label { color:var(--muted); }
.fg-label { font-size:14px; margin-bottom:5px; }
.fg-opts { display:flex; flex-wrap:wrap; gap:5px; }
.fg-opt { position:relative; }
.fg-opt input { position:absolute; inset:0; width:100%; height:100%; opacity:0; margin:0; cursor:pointer; }
.fg-opt span { display:block; padding:3px 10px; font-size:13px; border:1px solid var(--border); border-radius:999px; background:var(--field); }
.fg-q[data-type="multi"] .fg-opt span { border-radius:4px; }
.fg-opt input:checked + span { background:var(--accent-2); border-color:var(--accent-2); color:#fff; }
.fg-opt input:focus-visible + span { outline:2px solid var(--accent); outline-offset:2px; }
.fg-opt input:disabled { cursor:default; }
.fg-opt input:disabled + span { opacity:.45; border-style:dashed; }
.fg-note { color:var(--muted); font-size:12px; margin-top:4px; }
.fg-row { padding:10px 0; border-top:1px solid var(--border); }
.fg-row:first-of-type { border-top:0; padding-top:0; }
.fg-name { color:var(--muted); font-size:12px; }
.fg-value { font-weight:650; }
.fg-msg { font-size:12.5px; margin-top:10px; padding:7px 9px; border:1px solid var(--border); border-radius:6px; }
.fg-msg.warn { border-color:var(--err); }
`;

function h(tag, attrs, ...kids) {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v === false || v === null || v === undefined) continue;
    if (k === 'class') node.className = v;
    else if (k.startsWith('on')) node.addEventListener(k.slice(2), v);
    else node.setAttribute(k, v === true ? '' : v);
  }
  for (const kid of kids.flat(Infinity)) {
    if (kid === null || kid === undefined || kid === false) continue;
    node.append(kid.nodeType ? kid : document.createTextNode(String(kid)));
  }
  return node;
}

function build() {
  document.head.append(h('style', {}, STYLE));
  const questions = h('div', { class: 'fg-col' });
  const result = h('div', { class: 'fg-col', 'aria-live': 'polite' });
  const applyBtn = h('button', { type: 'button' }, 'Apply');
  const cancelBtn = h('button', { class: 'ghost', type: 'button' }, 'Cancel');
  const closeBtn = h('button', { class: 'icon-btn', type: 'button', title: 'Close', 'aria-label': 'Close' }, '✕');
  const backdrop = h('div', { class: 'modal-backdrop', hidden: true },
    h('div', { class: 'modal fg-modal', role: 'dialog', 'aria-label': 'Recommend FMU settings', 'aria-modal': 'true' },
      h('div', { class: 'modal-head' }, h('span', {}, 'Recommend FMU settings'), closeBtn),
      h('div', { class: 'fg-body' }, questions, result),
      h('div', { class: 'modal-foot' }, cancelBtn, applyBtn)));
  document.body.append(backdrop);

  const close = () => { backdrop.hidden = true; };
  closeBtn.addEventListener('click', close);
  cancelBtn.addEventListener('click', close);
  backdrop.addEventListener('click', (e) => { if (e.target === backdrop) close(); });
  // Capture, so that Escape closes this dialog and not the one below it.
  window.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape' || backdrop.hidden) return;
    e.stopPropagation();
    close();
  }, true);
  return { backdrop, questions, result, applyBtn, close, host: null, ask: null, onApply: null, round: 0, values: {} };
}

const inputId = (input, value) => `fg-${input.id}-${String(value).replace(/[^a-z0-9]+/gi, '-')}`;

function renderQuestions(asked) {
  const inputs = model.inputs.filter((i) => asked.includes(i.id));
  const groups = model.inputGroups || [{ id: undefined, label: '' }];
  dialog.questions.replaceChildren(...groups.flatMap((group) => {
    const mine = inputs.filter((i) => i.group === group.id);
    if (mine.length === 0) return [];
    return [h('div', { class: 'fg-group' }, group.label), ...mine.map((input) =>
      h('div', { class: 'fg-q', id: 'fg-q-' + input.id, 'data-type': input.type, role: 'group', 'aria-labelledby': 'fg-l-' + input.id },
        h('div', { class: 'fg-label', id: 'fg-l-' + input.id }, input.label),
        h('div', { class: 'fg-opts' }, input.options.map((o) =>
          h('label', { class: 'fg-opt' },
            h('input', {
              type: input.type === 'multi' ? 'checkbox' : 'radio',
              name: 'fg-' + input.id, id: inputId(input, o.value), value: o.value,
              onchange: (e) => answer(input, o.value, e.target.checked),
            }),
            h('span', {}, o.label)))),
        h('div', { class: 'fg-note', hidden: true })))];
  }));
}

function answer(input, value, checked) {
  if (input.type === 'multi') {
    const chosen = new Set(answers[input.id] || input.default || []);
    if (checked) chosen.add(value); else chosen.delete(value);
    answers[input.id] = input.options.map((o) => o.value).filter((v) => chosen.has(v));
  } else {
    answers[input.id] = value;
  }
  refresh();
}

async function refresh() {
  const { host } = dialog;
  const round = ++dialog.round;
  const advice = await dialog.ask({ op: 'advise', answers, host });
  if (round !== dialog.round) return;
  if (!advice.ok) throw new Error(advice.error);
  const { today } = advice;
  if (dialog.questions.childElementCount === 0) renderQuestions(advice.asked);

  for (const input of model.inputs) {
    const box = document.getElementById('fg-q-' + input.id);
    if (!box) continue;
    const st = today.inputs[input.id];
    box.classList.toggle('off', !st.enabled);
    for (const o of input.options) {
      const node = document.getElementById(inputId(input, o.value));
      const on = st.enabled && st.options[o.value];
      node.disabled = !on;
      node.checked = on && (input.type === 'multi' ? st.value.includes(o.value) : st.value === o.value);
    }
    const text = st.enabled ? input.help : input.disabledNote;
    const note = box.querySelector('.fg-note');
    note.textContent = text || '';
    note.hidden = !text;
  }

  const setting = (id) => model.settings.find((s) => s.id === id);
  const label = (id, value) => setting(id).options.find((o) => o.value === value).label;
  const option = (s, value) => s.options.find((o) => o.value === value);
  const blocked = today.settings.filter((s) => s.relevant && s.blocked);
  const applied = today.settings.filter((s) => s.relevant && s.pick !== null && host.applies.includes(s.id));
  const kids = [];
  if (blocked.length) {
    kids.push(h('div', { class: 'fg-row' },
      h('div', { class: 'fg-value' }, `No FMU from ${host.name} fits these answers`),
      blocked.map((s) => s.options.filter((o) => o.support.available && o.excludedBy.length).map((o) =>
        h('div', { class: 'fg-note' }, `${setting(s.id).label}, ${label(s.id, o.value)}: ${o.excludedBy.map((x) => x.because).join(' ')}`)))));
  } else {
    for (const s of applied) {
      const pick = option(s, s.pick);
      const why = pick.reasons.filter((r) => r.points > 0).sort((a, b) => b.points - a.points)[0];
      const out = s.displaced.length ? option(s, s.displaced[0]) : null;
      const gap = advice.gaps.find((g) => g.setting === s.id);
      const better = gap && option(advice.ideal.settings.find((x) => x.id === s.id), gap.ideal);
      kids.push(h('div', { class: 'fg-row' },
        h('div', { class: 'fg-name' }, setting(s.id).label),
        h('div', { class: 'fg-value' }, label(s.id, s.pick)),
        why && h('div', { class: 'fg-note' }, why.because),
        !why && out && h('div', { class: 'fg-note' }, `${label(s.id, out.value)}: ${out.excludedBy[0].because}`),
        pick.support.note && h('div', { class: 'fg-note' }, pick.support.note),
        better && h('div', { class: 'fg-note' }, `Would fit better: ${label(s.id, gap.ideal)}. ${better.support.note}`)));
    }
    for (const n of today.notes.filter((x) => x.level === 'warn')) kids.push(h('div', { class: 'fg-msg warn' }, n.text));
    for (const n of today.notes.filter((x) => x.level !== 'warn')) kids.push(h('div', { class: 'fg-msg' }, n.text));
  }
  dialog.result.replaceChildren(...kids);
  dialog.applyBtn.disabled = blocked.length > 0;
  dialog.values = Object.fromEntries(applied.map((s) => [s.id, s.pick]));
}

// ask: (request) => Promise of the reply of omc's settings guide.
// host: { name, offers: { settingId: [values] }, applies: [settingId] }.
// onApply receives { settingId: value } for the settings in `applies`.
export async function openFmiGuide({ ask, host, onApply }) {
  if (!model) {
    const reply = await ask({ op: 'model' });
    if (!reply.ok) throw new Error(reply.error);
    model = reply.model;
  }
  if (!dialog) {
    dialog = build();
    dialog.applyBtn.addEventListener('click', () => { dialog.close(); dialog.onApply(dialog.values); });
  }
  Object.assign(dialog, { ask, host, onApply });
  dialog.questions.replaceChildren();
  await refresh();
  dialog.backdrop.hidden = false;
}
