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

  function renderLibraries() {
    const list = document.createElement('ul');
    list.className = 'om-tree';
    for (const library of libraries) {
      list.appendChild(libraryItem(library));
    }
    const target = nav();
    target.textContent = '';
    target.appendChild(list);
  }

  function libraryItem(library) {
    const item = document.createElement('li');
    const row = document.createElement('div');
    row.className = 'om-row';
    const toggle = document.createElement('button');
    toggle.className = 'om-twisty';
    toggle.type = 'button';
    toggle.textContent = '▸';
    toggle.setAttribute('aria-expanded', 'false');
    const link = document.createElement('a');
    link.href = pageHref(library.n);
    link.textContent = library.n;
    link.title = library.d || library.n;
    if (library.ic) {
      const img = document.createElement('img');
      img.className = 'om-icon-small';
      img.src = library.ic;
      img.alt = '';
      img.loading = 'lazy';
      link.prepend(img);
    }
    row.append(toggle, link);
    if (library.v) {
      const version = document.createElement('span');
      version.className = 'om-tree-version';
      version.textContent = library.v;
      row.appendChild(version);
    }
    item.appendChild(row);
    const kids = document.createElement('ul');
    kids.className = 'om-tree om-collapsed';
    item.appendChild(kids);
    toggle.addEventListener('click', () => toggleLibrary(library.n, toggle, kids));
    item.dataset.library = library.n;
    return item;
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
    const item = nav().querySelector(`li[data-library="${CSS.escape(library)}"]`);
    if (!item) return;
    await toggleLibrary(library, item.querySelector('.om-twisty'), item.querySelector('ul'));
    const segments = current.split('.');
    let container = item.querySelector('ul');
    for (let depth = 1; depth < segments.length; depth++) {
      const name = segments.slice(0, depth + 1).join('.');
      const link = container.querySelector(`:scope > li > .om-row > a[data-name="${CSS.escape(name)}"]`);
      if (!link) return;
      const row = link.parentElement;
      const next = row.parentElement.querySelector('ul');
      if (depth + 1 === segments.length) {
        link.classList.add('om-here');
        link.scrollIntoView({ block: 'center' });
        return;
      }
      const toggle = row.querySelector('.om-twisty');
      if (toggle && toggle.getAttribute('aria-expanded') === 'false') toggle.click();
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
    document.getElementById('om-theme')?.addEventListener('click', cycleTheme);
    document.getElementById('om-sidebar-toggle')?.addEventListener('click', () => {
      document.body.classList.toggle('om-sidebar-open');
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
