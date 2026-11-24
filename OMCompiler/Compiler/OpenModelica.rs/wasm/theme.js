// The colour scheme of the web clients. The launcher stores the choice of the
// user under om-theme ('light' or 'dark'; no value follows the system), and
// each page sets data-theme on <html> to the scheme that results. A classic
// script, loaded in <head>, so the first paint has the right colours.
// A page embedded in another site takes the scheme of that site instead:
// ?theme=light|dark, then pin().
(() => {
  const KEY = 'om-theme';
  const SCHEMES = ['light', 'dark'];
  const system = matchMedia('(prefers-color-scheme: dark)');
  const scheme = (value) => (SCHEMES.includes(value) ? value : null);
  let pinned = scheme(new URLSearchParams(location.search).get('theme'));

  const stored = () => {
    try {
      return scheme(localStorage.getItem(KEY)) || 'system';
    } catch (e) {
      return 'system';
    }
  };
  const apply = () => {
    const choice = pinned || stored();
    document.documentElement.dataset.theme = choice === 'system' ? (system.matches ? 'dark' : 'light') : choice;
  };

  window.omTheme = {
    get: stored,
    set(choice) {
      try {
        if (scheme(choice)) localStorage.setItem(KEY, choice);
        else localStorage.removeItem(KEY);
      } catch (e) {
        /* private mode */
      }
      apply();
    },
    pin(value) {
      pinned = scheme(value);
      apply();
    },
  };
  system.addEventListener('change', apply);
  addEventListener('storage', (event) => {
    if (event.key === KEY || event.key === null) apply();
  });
  apply();
})();
