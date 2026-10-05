// Sidebar, theme switch and search for the generated documentation.
//
// The index files are <script> tags rather than fetch(), so the offline tarball
// works from file:// where fetch is blocked by CORS.

(() => {
  const THEME_KEY = 'omdoc-theme';
  const THEMES = ['light', 'dark', 'auto'];

  const trees = new Map();
  const texts = new Map();
  const pending = new Map();
  let libraries = null;

  window.omdoc = {
    libraries: (data) => resolve('libraries', (libraries = data)),
    tree: (name, data) => resolve('tree/' + name, trees.set(name, data)),
    text: (name, data) => resolve('text/' + name, texts.set(name, data)),
  };

  function resolve(key, value) {
    const entry = pending.get(key);
    if (entry) {
      entry.done(value);
      pending.delete(key);
    }
  }

  function load(key) {
    if (key === 'libraries' && libraries) return Promise.resolve(libraries);
    if (key.startsWith('tree/') && trees.has(key.slice(5))) return Promise.resolve();
    if (key.startsWith('text/') && texts.has(key.slice(5))) return Promise.resolve();
    const existing = pending.get(key);
    if (existing) return existing.promise;
    let done;
    const promise = new Promise((ok) => {
      done = ok;
    });
    pending.set(key, { promise, done });
    const script = document.createElement('script');
    script.src = 'index/' + key + '.js';
    script.onerror = () => resolve(key, null);
    document.head.appendChild(script);
    return promise;
  }

  // ── theme ──────────────────────────────────────────────────────────────────

  function applyTheme(theme) {
    if (theme === 'auto') document.documentElement.removeAttribute('data-theme');
    else document.documentElement.setAttribute('data-theme', theme);
    const button = document.getElementById('om-theme');
    if (button) {
      button.textContent = { light: '☀', dark: '☾', auto: '◐' }[theme];
      button.title = 'Theme: ' + theme + ' (click to change)';
      button.setAttribute('aria-label', 'Theme: ' + theme);
    }
  }

  function currentTheme() {
    try {
      const stored = localStorage.getItem(THEME_KEY);
      if (THEMES.includes(stored)) return stored;
    } catch (e) {
      /* private mode */
    }
    return 'light';
  }

  function cycleTheme() {
    const next = THEMES[(THEMES.indexOf(currentTheme()) + 1) % THEMES.length];
    try {
      localStorage.setItem(THEME_KEY, next);
    } catch (e) {
      /* private mode */
    }
    applyTheme(next);
    simulator
      ?.querySelector('iframe')
      ?.contentWindow.postMessage({ type: 'om-theme', theme: effectiveTheme() }, '*');
  }

  // ── names ──────────────────────────────────────────────────────────────────

  function qualifiedName(tree, index) {
    const parts = [];
    for (let i = index; i >= 0; i = tree.p[i]) parts.unshift(tree.n[i]);
    return parts.join('.');
  }

  function pageHref(name) {
    const aliases = window.omdocAliases || {};
    const stem = (aliases[name] !== undefined ? aliases[name] : name)
      .replace(/\//g, 'Division')
      .replace(/\*/g, 'Multiplication')
      .replace(/</g, 'x3C')
      .replace(/>/g, 'x3E');
    return stem.replace(/ /g, '%20').replace(/'/g, '%27') + '.html';
  }

  function childrenOf(tree) {
    if (tree.kids) return tree.kids;
    const kids = tree.n.map(() => []);
    const roots = [];
    for (let i = 0; i < tree.p.length; i++) {
      if (tree.p[i] < 0) roots.push(i);
      else kids[tree.p[i]].push(i);
    }
    tree.kids = kids;
    tree.roots = roots;
    return kids;
  }

  // ── tree ───────────────────────────────────────────────────────────────────

  const nav = () => document.getElementById('om-nav');

  // Two copies of a library are one library to a reader: the tree lists it
  // once and the version beside it says which copy is open.
  const groupOf = (name) => name.split('@')[0];

  function libraryGroups() {
    const groups = new Map();
    for (const library of libraries) {
      const group = groupOf(library.n);
      if (!groups.has(group)) groups.set(group, []);
      groups.get(group).push(library);
    }
    return groups;
  }

  function renderLibraries() {
    const list = document.createElement('ul');
    list.className = 'om-tree';
    for (const [group, copies] of libraryGroups()) {
      list.appendChild(libraryItem(group, copies));
    }
    const target = nav();
    target.textContent = '';
    target.appendChild(list);
  }

  function libraryItem(group, copies) {
    const item = document.createElement('li');
    item.dataset.group = group;
    const row = document.createElement('div');
    row.className = 'om-row';
    const toggle = document.createElement('button');
    toggle.className = 'om-twisty';
    toggle.type = 'button';
    toggle.textContent = '\u25b8';
    toggle.setAttribute('aria-expanded', 'false');
    const link = document.createElement('a');
    link.textContent = group;
    link.title = copies[0].d || group;
    if (copies[0].ic) {
      const img = document.createElement('img');
      img.className = 'om-icon-small';
      img.src = copies[0].ic;
      img.alt = '';
      img.loading = 'lazy';
      link.prepend(img);
    }
    row.append(toggle, link);
    if (copies.length > 1) {
      const pick = document.createElement('select');
      pick.className = 'om-tree-version';
      pick.setAttribute('aria-label', group + ' version');
      for (const copy of copies) {
        const option = document.createElement('option');
        option.value = copy.n;
        option.textContent = copy.v || copy.n;
        pick.appendChild(option);
      }
      pick.addEventListener('change', () => switchLibraryVersion(item, pick.value));
      row.appendChild(pick);
    } else if (copies[0].v) {
      const version = document.createElement('span');
      version.className = 'om-tree-version';
      version.textContent = copies[0].v;
      row.appendChild(version);
    }
    item.appendChild(row);
    const kids = document.createElement('ul');
    kids.className = 'om-tree om-collapsed';
    item.appendChild(kids);
    toggle.addEventListener('click', () => toggleLibrary(item.dataset.library, toggle, kids));
    setLibraryVersion(item, copies[0].n);
    return item;
  }

  function setLibraryVersion(item, name) {
    item.dataset.library = name;
    item.querySelector('.om-row a').href = pageHref(name);
    const pick = item.querySelector('select.om-tree-version');
    if (pick) pick.value = name;
  }

  // Picking a version in the tree means reading it. The page picker already
  // knows where this class lands there, so follow it when the page belongs to
  // this library; otherwise just show the other tree.
  function switchLibraryVersion(item, name) {
    const page = document.getElementById('om-version');
    const here = document.body.dataset.library;
    if (page && here && groupOf(here) === item.dataset.group) {
      const option = [...page.options].find((o) => o.text === versionOf(name));
      if (option) {
        page.value = option.value;
        return void navigate(new URL(option.value, location.href), true).then((done) => {
          if (!done) location.href = option.value;
        });
      }
    }
    openLibrary(item, name, true);
  }

  const versionOf = (name) =>
    (libraries.find((l) => l.n === name) || {}).v || name.split('@')[1] || '';

  // A different version is a different tree, so what was loaded is dropped.
  async function openLibrary(item, name, expand) {
    setLibraryVersion(item, name);
    const kids = item.querySelector('ul');
    const toggle = item.querySelector('.om-twisty');
    kids.textContent = '';
    delete kids.dataset.filled;
    kids.classList.add('om-collapsed');
    toggle.setAttribute('aria-expanded', 'false');
    toggle.textContent = '\u25b8';
    if (expand) await toggleLibrary(name, toggle, kids);
  }

  async function toggleLibrary(name, toggle, container) {
    const open = toggle.getAttribute('aria-expanded') === 'true';
    if (open) {
      toggle.setAttribute('aria-expanded', 'false');
      toggle.textContent = '▸';
      container.classList.add('om-collapsed');
      return;
    }
    toggle.setAttribute('aria-expanded', 'true');
    toggle.textContent = '▾';
    container.classList.remove('om-collapsed');
    if (!container.dataset.filled) {
      container.innerHTML = '<li class="om-loading">loading…</li>';
      await load('tree/' + name);
      const tree = trees.get(name);
      container.textContent = '';
      if (!tree) {
        container.innerHTML = '<li class="om-loading">index unavailable</li>';
        return;
      }
      childrenOf(tree);
      for (const root of tree.roots) {
        for (const child of tree.kids[root]) {
          container.appendChild(nodeItem(name, tree, child));
        }
      }
      container.dataset.filled = '1';
    }
  }

  // The class' icon, when it has one.
  function iconFor(tree, index) {
    const url = tree.ic && tree.ic[index];
    if (!url) return null;
    const img = document.createElement('img');
    img.className = 'om-icon-small';
    img.src = url;
    img.alt = '';
    img.loading = 'lazy';
    return img;
  }

  function nodeItem(library, tree, index) {
    const item = document.createElement('li');
    const row = document.createElement('div');
    row.className = 'om-row';
    const kids = tree.kids[index];
    const toggle = document.createElement('button');
    toggle.className = 'om-twisty';
    toggle.type = 'button';
    toggle.textContent = kids.length ? '▸' : '';
    toggle.disabled = !kids.length;
    toggle.setAttribute('aria-expanded', 'false');
    const name = qualifiedName(tree, index);
    const link = document.createElement('a');
    link.href = pageHref(name);
    link.textContent = tree.n[index];
    link.title = tree.d[index] || name;
    link.dataset.name = name;
    const icon = iconFor(tree, index);
    if (icon) link.prepend(icon);
    row.append(toggle, link);
    item.appendChild(row);
    const container = document.createElement('ul');
    container.className = 'om-tree om-collapsed';
    item.appendChild(container);
    if (kids.length) {
      toggle.addEventListener('click', () => {
        const open = toggle.getAttribute('aria-expanded') === 'true';
        toggle.setAttribute('aria-expanded', open ? 'false' : 'true');
        toggle.textContent = open ? '▸' : '▾';
        container.classList.toggle('om-collapsed', open);
        if (!open && !container.dataset.filled) {
          for (const child of kids) container.appendChild(nodeItem(library, tree, child));
          container.dataset.filled = '1';
        }
      });
    }
    return item;
  }

  // Open the tree down to the page being read and scroll it into view.
  async function revealCurrent() {
    const current = document.body.dataset.class;
    const library = document.body.dataset.library;
    if (!current || !library) return;
    const item = nav().querySelector(`li[data-group="${CSS.escape(groupOf(library))}"]`);
    if (!item) return;
    if (item.dataset.library !== library) await openLibrary(item, library, false);
    // Open, not toggle: arriving from a page that already had the library
    // open would otherwise shut it.
    const root = item.querySelector('.om-twisty');
    if (root.getAttribute('aria-expanded') === 'false') {
      await toggleLibrary(library, root, item.querySelector('ul'));
    }
    const segments = current.split('.');
    if (segments.length === 1) {
      item.querySelector('.om-row a')?.classList.add('om-here');
      return;
    }
    let container = item.querySelector('ul');
    for (let depth = 1; depth < segments.length; depth++) {
      const name = segments.slice(0, depth + 1).join('.');
      const link = container.querySelector(`:scope > li > .om-row > a[data-name="${CSS.escape(name)}"]`);
      if (!link) return;
      const row = link.parentElement;
      const next = row.parentElement.querySelector('ul');
      const toggle = row.querySelector('.om-twisty');
      if (toggle && !toggle.disabled && toggle.getAttribute('aria-expanded') === 'false') {
        toggle.click();
      }
      if (depth + 1 === segments.length) {
        link.classList.add('om-here');
        link.scrollIntoView({ block: 'center' });
        return;
      }
      container = next;
    }
  }

  // ── search ─────────────────────────────────────────────────────────────────

  function tokenize(text) {
    return (text.toLowerCase().match(/[a-z0-9_]{3,32}/g) || []).filter(
      (t) => t.length >= 3 && t.length <= 32
    );
  }

  function decodePostings(encoded) {
    const out = [];
    let previous = 0;
    for (const gap of encoded.split('.')) {
      previous += parseInt(gap, 36);
      out.push(previous);
    }
    return out;
  }

  function nameMatches(query, limit) {
    const needle = query.toLowerCase();
    const results = [];
    for (const [library, tree] of trees) {
      for (let i = 0; i < tree.n.length; i++) {
        const segment = tree.n[i].toLowerCase();
        let score;
        if (segment === needle) score = 0;
        else if (segment.startsWith(needle)) score = 1;
        else if (segment.includes(needle)) score = 2;
        else if ((tree.d[i] || '').toLowerCase().includes(needle)) score = 4;
        else continue;
        results.push({ library, tree, index: i, score: score + depthOf(tree, i) / 100 });
        if (results.length > limit * 20) break;
      }
    }
    results.sort((a, b) => a.score - b.score);
    return results.slice(0, limit);
  }

  function depthOf(tree, index) {
    let depth = 0;
    for (let i = index; tree.p[i] >= 0; i = tree.p[i]) depth++;
    return depth;
  }

  function textMatches(query, limit) {
    const wanted = tokenize(query);
    if (!wanted.length) return [];
    const results = [];
    for (const [library, index] of texts) {
      const tree = trees.get(library);
      if (!tree) continue;
      let hits = null;
      for (const token of wanted) {
        const found = new Set();
        for (const term of Object.keys(index)) {
          if (term === token || term.startsWith(token)) {
            for (const id of decodePostings(index[term])) found.add(id);
          }
        }
        hits = hits === null ? found : new Set([...hits].filter((id) => found.has(id)));
        if (!hits.size) break;
      }
      for (const id of hits || []) {
        results.push({ library, tree, index: id, score: depthOf(tree, id) });
        if (results.length >= limit * 4) break;
      }
    }
    results.sort((a, b) => a.score - b.score);
    return results.slice(0, limit);
  }

  function resultList(matches, seen) {
    const list = document.createElement('ul');
    list.className = 'om-results';
    for (const match of matches) {
      const name = qualifiedName(match.tree, match.index);
      if (seen.has(name)) continue;
      seen.add(name);
      const item = document.createElement('li');
      const link = document.createElement('a');
      link.href = pageHref(name);
      const leaf = document.createElement('span');
      leaf.className = 'om-result-name';
      const icon = iconFor(match.tree, match.index);
      if (icon) leaf.appendChild(icon);
      leaf.appendChild(document.createTextNode(match.tree.n[match.index]));
      const path = document.createElement('span');
      path.className = 'om-result-path';
      path.textContent = name;
      link.append(leaf, path);
      const description = match.tree.d[match.index];
      if (description) {
        const text = document.createElement('span');
        text.className = 'om-result-desc';
        text.textContent = description;
        link.appendChild(text);
      }
      item.appendChild(link);
      list.appendChild(item);
    }
    return list;
  }

  let searchToken = 0;

  async function runSearch(query) {
    const token = ++searchToken;
    const target = nav();
    if (!query) {
      target.textContent = '';
      renderLibraries();
      revealCurrent();
      return;
    }
    target.textContent = '';
    const status = document.createElement('p');
    status.className = 'om-loading';
    status.textContent = 'loading index…';
    target.appendChild(status);

    await Promise.all(libraries.map((l) => load('tree/' + l.n)));
    if (token !== searchToken) return;

    const seen = new Set();
    target.textContent = '';
    const names = nameMatches(query, 60);
    target.appendChild(heading(`${names.length ? names.length : 'no'} name matches`));
    target.appendChild(resultList(names, seen));

    const body = textMatches(query, 40);
    const scope =
      texts.size < libraries.length ? ` (${texts.size} of ${libraries.length} libraries)` : '';
    target.appendChild(
      heading(`${body.length ? body.length : 'no'} documentation matches${scope}`)
    );
    target.appendChild(resultList(body, seen));

    if (texts.size < libraries.length) {
      const more = document.createElement('button');
      more.type = 'button';
      more.className = 'om-more';
      more.textContent = `Search the documentation of all ${libraries.length} libraries`;
      more.addEventListener('click', async () => {
        more.disabled = true;
        more.textContent = 'loading…';
        await Promise.all(libraries.map((l) => load('text/' + l.n)));
        runSearch(query);
      });
      target.appendChild(more);
    }
  }

  function heading(text) {
    const element = document.createElement('h2');
    element.className = 'om-results-heading';
    element.textContent = text;
    return element;
  }

  // ── diagram ────────────────────────────────────────────────────────────────

  // Swap the <img> for the SVG itself, so a component can be clicked through
  // to its row. fetch() fails from file://, where the <img> stays.
  async function startDiagram() {
    const frame = document.querySelector('.om-graphics[data-diagram]');
    if (!frame) return;
    let markup;
    try {
      const response = await fetch(frame.dataset.diagram);
      if (!response.ok) return;
      markup = await response.text();
    } catch (e) {
      return;
    }
    const svg = new DOMParser().parseFromString(markup, 'image/svg+xml').documentElement;
    if (svg.nodeName !== 'svg') return;
    svg.setAttribute('class', 'om-diagram');
    for (const group of svg.querySelectorAll('[data-component]')) {
      const name = group.getAttribute('data-component');
      const row = document.getElementById('c-' + name);
      if (!row) continue;
      group.setAttribute('class', 'om-comp');
      const title = document.createElementNS(svg.namespaceURI, 'title');
      title.textContent = name;
      group.prepend(title);
      group.addEventListener('click', () => {
        location.hash = 'c-' + encodeURIComponent(name);
        row.scrollIntoView({ block: 'center', behavior: 'smooth' });
      });
    }
    // Replaces the <img>, not the box: the link that opens the file stays.
    frame.querySelector('img')?.replaceWith(svg);
  }

  // ── playground ─────────────────────────────────────────────────────────────

  // One iframe for the whole visit: booting the compiler and installing a
  // library costs seconds, so a second class is sent to the live frame.
  const BUILD_KEY = 'omdoc-playground';

  let simulator = null;       // the card holding the live iframe, or null
  let simulatorClass = null;  // the class that frame is showing
  let simulatorKey = null;    // class, library version and action together
  let simulatorBuild = null;  // the playground build it was loaded from

  // The header's picker, remembered so a choice carries from page to page.
  function build(card) {
    const offered = (card.dataset.versions || '').split(',').filter(Boolean);
    let chosen = document.getElementById('om-build')?.value;
    if (!offered.includes(chosen)) {
      try {
        chosen = localStorage.getItem(BUILD_KEY);
      } catch (e) {
        /* private mode */
      }
    }
    return offered.includes(chosen) ? chosen : offered[0] || '';
  }

  // What the reader is looking at, so the frame is not a hole in the page.
  const effectiveTheme = () => {
    const theme = currentTheme();
    if (theme !== 'auto') return theme;
    return matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  };

  const simulatorUrl = (card, version) =>
    card.dataset.playground.replace('{version}', version) +
    '?' + card.dataset.query + '&theme=' + effectiveTheme();

  const askedOf = (card) => new URLSearchParams(card.dataset.query);

  // What the frame is showing. The same class in another version of the
  // library is another model, so the name alone does not identify it.
  const keyOf = (asked) =>
    ['class', 'package', 'version', 'action'].map((k) => asked.get(k) || '').join('\u0000');

  const message = (asked) => ({
    type: 'om-load',
    class: asked.get('class'),
    package: asked.get('package'),
    version: asked.get('version'),
    action: asked.get('action'),
  });

  function startSimulator(card) {
    if (!card || !card.dataset.playground) return;
    const version = build(card);
    const asked = askedOf(card);
    // A live frame takes the next class by message; a different build is a
    // different compiler, so that one does reload.
    if (simulator && simulator.isConnected && simulator !== card && version === simulatorBuild) {
      simulator.querySelector('iframe').contentWindow.postMessage(message(asked), '*');
      simulatorClass = asked.get('class');
      simulatorKey = keyOf(asked);
      simulator.classList.toggle('om-run-check', asked.get('action') === 'check');
      simulator.scrollIntoView({ block: 'nearest' });
      return;
    }
    const existing = card.querySelector('iframe');
    if (existing && version === simulatorBuild) {
      // Parked on this page: hidden, but the same booted frame.
      existing.contentWindow.postMessage(message(asked), '*');
      simulator = card;
      simulatorClass = asked.get('class');
      simulatorKey = keyOf(asked);
      card.classList.add('om-run-open');
      card.classList.toggle('om-run-check', asked.get('action') === 'check');
      return;
    }
    const frame = existing || document.createElement('iframe');
    frame.className = 'om-sim';
    frame.src = simulatorUrl(card, version);
    frame.title = 'OpenModelica simulator';
    if (!existing) card.appendChild(frame);
    card.classList.add('om-run-open');
    card.classList.toggle('om-run-check', asked.get('action') === 'check');
    simulator = card;
    simulatorClass = asked.get('class');
    simulatorKey = keyOf(asked);
    simulatorBuild = version;
  }

  // Moving to another class puts the frame away: its results belong to the
  // model it ran. Hidden, not detached -- detaching reloads the compiler.
  function parkSimulator(card) {
    if (keyOf(askedOf(card)) === simulatorKey) {
      card.classList.add('om-run-open');
      return;
    }
    card.classList.remove('om-run-open');
    if (simulatorClass) {
      card.title = 'The simulator is loaded, with ' + simulatorClass;
    }
  }

  // The page is generated with the first build in its link and its picker.
  function syncRunCard(root) {
    let chosen;
    try {
      chosen = localStorage.getItem(BUILD_KEY);
    } catch (e) {
      /* private mode */
    }
    const pick = document.getElementById('om-build');
    if (pick && [...pick.options].some((o) => o.value === chosen)) pick.value = chosen;
    const card = root.querySelector('.om-run:not(.om-run-open)');
    if (!card) return;
    card.querySelector('.om-run-start')?.setAttribute('href', simulatorUrl(card, build(card)));
  }

  // ── navigation ─────────────────────────────────────────────────────────────

  // Swapping the page's contents rather than loading it keeps the simulator
  // frame alive across links: detaching the frame would reload it.
  const internal = (link) => {
    if (link.target || link.hasAttribute('download')) return null;
    const url = new URL(link.href, location.href);
    if (url.origin !== location.origin) return null;
    if (!url.pathname.endsWith('.html')) return null;
    return url;
  };

  // What the page's library put in <head>, which is everything after the
  // theme bootstrap. Read once, before anything of ours is appended, so a
  // swap only ever takes away what a page declared.
  const headExtra = (root) => {
    const children = [...root.head.children];
    const bootstrap = children.findIndex((n) => n.tagName === 'SCRIPT');
    return bootstrap < 0 ? [] : children.slice(bootstrap + 1);
  };
  let headNodes = headExtra(document);
  // A `popstate` that leaves this alone is a fragment change -- a diagram
  // component picking out its row -- and re-rendering would replace that row.
  let shown = location.pathname;

  function swapHeadExtra(doc) {
    const wanted = headExtra(doc);
    if (
      headNodes.length === wanted.length &&
      headNodes.every((node, i) => node.outerHTML === wanted[i].outerHTML)
    ) {
      return;
    }
    for (const node of headNodes) node.remove();
    // Re-created rather than adopted, so a <script> among them runs.
    headNodes = wanted.map((node) => {
      const copy = document.createElement(node.tagName);
      for (const attribute of node.attributes) copy.setAttribute(attribute.name, attribute.value);
      copy.textContent = node.textContent;
      document.head.appendChild(copy);
      return copy;
    });
  }

  // The new page's diagram and run button around the frame already there,
  // detaching neither it nor anything above it.
  function refillFigure(kept, figure) {
    const card = kept.querySelector('.om-run');
    const frame = card.querySelector('iframe');
    const fresh = figure.querySelector('.om-run');
    for (const child of [...card.childNodes]) {
      if (child !== frame) child.remove();
    }
    if (fresh) {
      for (const attribute of fresh.attributes) {
        if (attribute.name !== 'class') card.setAttribute(attribute.name, attribute.value);
      }
      for (const child of [...fresh.childNodes]) card.insertBefore(child, frame);
    }
    // Nothing to run here: keep the frame alive but out of the way, and drop
    // what it was asked for so nothing stale is offered.
    card.classList.toggle('om-run-idle', !fresh);
    if (!fresh) {
      card.classList.remove('om-run-open');
      delete card.dataset.query;
    }
    for (const child of [...kept.childNodes]) {
      if (child !== card) child.remove();
    }
    for (const child of [...figure.childNodes]) {
      if (child !== fresh) kept.insertBefore(child, card);
    }
  }

  // A maths typesetter loaded from `__OpenModelica_infoHeader` does its pass
  // when it loads, which swapped-in content never saw.
  function retypeset(root) {
    try {
      const mathjax = window.MathJax;
      if (mathjax && mathjax.typesetPromise) mathjax.typesetPromise([root]).catch(() => {});
      else if (mathjax && mathjax.Hub && mathjax.Hub.Queue) {
        mathjax.Hub.Queue(['Typeset', mathjax.Hub, root]);
      } else if (window.renderMathInElement) window.renderMathInElement(root);
    } catch (e) {
      /* the page's own script; its failure is not ours */
    }
  }

  async function navigate(url, push) {
    let doc;
    try {
      const response = await fetch(url, { cache: 'no-cache' });
      if (!response.ok) return false;
      doc = new DOMParser().parseFromString(await response.text(), 'text/html');
    } catch (e) {
      return false;
    }
    const main = document.getElementById('om-main');
    const incoming = doc.getElementById('om-main');
    const header = doc.querySelector('.om-header');
    if (!main || !incoming || !header) return false;

    document.querySelector('.om-header').replaceWith(header);
    // The figure holding the live frame stays put; the rest is replaced.
    const kept = simulator && simulator.isConnected && main.contains(simulator)
      ? simulator.closest('.om-figure')
      : null;
    const nodes = [...incoming.childNodes];
    const at = nodes.findIndex((n) => n.nodeType === 1 && n.classList.contains('om-figure'));
    for (const child of [...main.childNodes]) {
      if (child !== kept) child.remove();
    }
    for (let i = 0; i < nodes.length; i++) {
      if (i === at && kept) {
        refillFigure(kept, nodes[i]);
        continue;
      }
      // `kept` last: everything before the figure goes in front of it, the
      // rest after. With no kept figure `insertBefore(_, null)` appends.
      if (at < 0 || i < at) main.insertBefore(nodes[i], kept);
      else main.appendChild(nodes[i]);
    }
    if (kept) {
      if (at < 0) {
        // No figure on this page: the frame stays, emptied of the last one's
        // drawing and button.
        main.appendChild(kept);
        refillFigure(kept, document.createElement('div'));
      }
      parkSimulator(simulator);
    }

    shown = url.pathname;
    document.title = doc.title;
    swapHeadExtra(doc);
    document.body.dataset.library = doc.body.dataset.library || '';
    document.body.dataset.class = doc.body.dataset.class || '';
    document.body.classList.remove('om-sidebar-open');
    if (push) history.pushState(null, '', url);
    if (url.hash) document.getElementById(url.hash.slice(1))?.scrollIntoView();
    else window.scrollTo(0, 0);
    startDiagram();
    startFilter();
    syncRunCard(main);
    retypeset(main);
    for (const here of nav().querySelectorAll('.om-here')) here.classList.remove('om-here');
    const library = document.body.dataset.library;
    if (library) {
      await load('text/' + library);
      revealCurrent();
    }
    return true;
  }

  // ── library index ──────────────────────────────────────────────────────────

  // Single choice: a reader wants one level at a time, and `All` comes back.
  function startFilter() {
    const filter = document.getElementById('om-filter');
    if (!filter) return;
    const rows = [...document.querySelectorAll('.om-libraries tbody tr')];
    filter.addEventListener('click', (event) => {
      const chip = event.target.closest('.om-chip');
      if (!chip) return;
      for (const other of filter.querySelectorAll('.om-chip')) {
        other.classList.toggle('om-chip-on', other === chip);
      }
      const wanted = chip.dataset.support;
      for (const row of rows) row.hidden = wanted !== '' && row.dataset.support !== wanted;
    });
  }

  // ── start ──────────────────────────────────────────────────────────────────

  function debounce(fn, ms) {
    let timer;
    return (...args) => {
      clearTimeout(timer);
      timer = setTimeout(() => fn(...args), ms);
    };
  }

  async function start() {
    applyTheme(currentTheme());
    startFilter();
    startDiagram();
    syncRunCard(document);

    // Delegated, because a page swap replaces the header these live in.
    const sidebar = (open) => document.body.classList.toggle('om-sidebar-open', open);
    const go = (url) => navigate(url, true).then((done) => {
      if (!done) location.href = url;
    });
    document.addEventListener('click', (event) => {
      if (event.button !== 0) return;
      if (event.target.closest('#om-sidebar-toggle')) {
        return void document.body.classList.toggle('om-sidebar-open');
      }
      if (event.target.closest('#om-theme')) return void cycleTheme();
      if (event.target.closest('#om-backdrop')) return void sidebar(false);
      const start = event.target.closest('.om-run-start');
      if (start) {
        // A modifier still opens the playground in its own tab.
        if (event.metaKey || event.ctrlKey || event.shiftKey) return;
        event.preventDefault();
        return void startSimulator(start.closest('.om-run'));
      }
      const link = event.target.closest('a[href]');
      if (!link || event.metaKey || event.ctrlKey || event.shiftKey || event.defaultPrevented) {
        return;
      }
      const url = internal(link);
      if (!url) return;
      event.preventDefault();
      go(url);
    });
    document.addEventListener('change', (event) => {
      if (event.target.id === 'om-version') return void go(new URL(event.target.value, location.href));
      if (event.target.id !== 'om-build') return;
      try {
        localStorage.setItem(BUILD_KEY, event.target.value);
      } catch (e) {
        /* private mode */
      }
      syncRunCard(document);
      // An open frame is the old build's compiler; the choice was deliberate.
      if (simulator && simulator.isConnected) {
        const card = simulator;
        simulator = simulatorClass = simulatorKey = simulatorBuild = null;
        card.querySelector('iframe')?.remove();
        card.classList.remove('om-run-open');
        startSimulator(card);
      }
    });
    window.addEventListener('popstate', () => {
      if (location.pathname === shown) return;
      navigate(new URL(location.href), false).then((done) => {
        if (!done) location.reload();
      });
    });

    const input = document.getElementById('om-q');
    if (input) {
      input.addEventListener(
        'input',
        debounce(() => {
          const query = input.value.trim();
          runSearch(query);
          const url = query ? '?q=' + encodeURIComponent(query) : location.pathname;
          history.replaceState(null, '', url);
        }, 150)
      );
      input.disabled = false;
      document.addEventListener('keydown', (event) => {
        if (event.key === '/' && event.target === document.body) {
          event.preventDefault();
          input.focus();
        } else if (event.key === 'Escape' && event.target === input) {
          input.blur();
        } else if (event.key === 'Escape') {
          sidebar(false);
        }
      });
    }

    await load('libraries');
    if (!libraries) {
      nav().innerHTML = '<p class="om-loading">index unavailable</p>';
      return;
    }
    renderLibraries();
    const library = document.body.dataset.library;
    if (library) await load('text/' + library);

    // `?q=…` makes a search linkable, and is what the sidebar writes back as
    // you type.
    const query = new URLSearchParams(location.search).get('q');
    if (query && input) {
      input.value = query;
      await runSearch(query.trim());
    } else if (library) {
      await revealCurrent();
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
