// Small DOM helpers shared by the web clients.

// Hand `bytes` to the browser as a download named `name`. The object URL is
// revoked once the browser has had time to start the save.
export function downloadBlob(name, bytes) {
  const url = URL.createObjectURL(new Blob([bytes], { type: 'application/octet-stream' }));
  const a = Object.assign(document.createElement('a'), { href: url, download: name });
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 2000);
}

// Wire a `.modal-backdrop`: anything inside it marked `data-close` (the ✕ and
// Cancel), a click on the backdrop itself and Escape all dismiss the dialog.
// `onOpen` may return false to refuse to open.
export function bindModal(backdrop, { onOpen = null, onClose = null } = {}) {
  const close = () => {
    if (backdrop.hidden) return;
    backdrop.hidden = true;
    if (onClose) onClose();
  };
  const open = () => {
    if (onOpen && onOpen() === false) return;
    backdrop.hidden = false;
  };
  for (const b of backdrop.querySelectorAll('[data-close]')) b.addEventListener('click', close);
  backdrop.addEventListener('click', (e) => { if (e.target === backdrop) close(); });
  window.addEventListener('keydown', (e) => { if (e.key === 'Escape') close(); });
  return { open, close, get isOpen() { return !backdrop.hidden; } };
}
