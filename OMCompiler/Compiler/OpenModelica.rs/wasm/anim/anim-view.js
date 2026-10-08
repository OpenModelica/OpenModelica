// Reusable 3D animation panel: builds the view + playback controls and drives the
// three.js Animator. Both simulator pages feed it a run's { shapes, times, data,
// stride }. Chart-cursor sync is left to the host via the onTime callback + seek().

import { Animator } from './animation.js';

const LOOP_SVG = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 2l4 4-4 4"/><path d="M3 11V9a4 4 0 0 1 4-4h14"/><path d="M7 22l-4-4 4-4"/><path d="M21 13v2a4 4 0 0 1-4 4H3"/></svg>';

const SPEED_PRESETS = ['1e-9', '1e-6', '1e-3', '0.25', '0.5', '1', '2', '4', '10', '100', '1e3', '1e6'];

export class AnimView {
  // `onTime(t)` is called as playback advances (for a synced chart cursor).
  constructor(opts = {}) {
    this.onTime = opts.onTime || null;
    this.animator = null;
    this.info = null;          // last run's { shapes, times, data, stride }
    this.loopOn = false;       // repeat preference, persisted across runs

    const root = document.createElement('div');
    root.className = 'anim';
    root.hidden = true;
    root.innerHTML = `
      <div class="anim-view" title="Drag to rotate · right-drag to pan · wheel to zoom">
        <div class="anim-views">
          <button data-view="iso" title="Isometric">Iso</button>
          <button data-view="side" title="Side (look −Z; x→ right, y↑ up)">Side</button>
          <button data-view="front" title="Front (look −X)">Front</button>
          <button data-view="top" title="Top (look −Y)">Top</button>
          <button data-view="fit" title="Reset view">Fit</button>
        </div>
      </div>
      <div class="anim-bar">
        <button class="anim-play" title="Play/pause">▶</button>
        <button class="anim-loop" title="Repeat" aria-label="Repeat" aria-pressed="false">${LOOP_SVG}</button>
        <input type="range" class="anim-seek" min="0" max="1000" value="0" step="1" aria-label="Time" />
        <span class="t anim-time">0.000 s</span>
        <span class="anim-speed-wrap" title="Playback speed: simulated seconds per real second (any positive number, e.g. 1e-9 or 1e6)">
          <input class="anim-speed" list="animSpeedPresets" type="text" inputmode="decimal" value="1"
                 aria-label="Playback speed (simulated seconds per real second)" />
          <span class="anim-speed-x">×</span>
        </span>
        <datalist id="animSpeedPresets">${SPEED_PRESETS.map((v) => `<option value="${v}"></option>`).join('')}</datalist>
      </div>`;
    this.el = root;
    this.viewEl = root.querySelector('.anim-view');
    this.playBtn = root.querySelector('.anim-play');
    this.loopBtn = root.querySelector('.anim-loop');
    this.seekEl = root.querySelector('.anim-seek');
    this.timeEl = root.querySelector('.anim-time');
    this.speedEl = root.querySelector('.anim-speed');

    this.playBtn.addEventListener('click', () => {
      if (this.animator) { this.animator.toggle(); this._reflectPlay(); }
    });
    this.loopBtn.addEventListener('click', () => {
      this.loopOn = !this.loopOn;
      this.loopBtn.classList.toggle('active', this.loopOn);
      this.loopBtn.setAttribute('aria-pressed', String(this.loopOn));
      if (this.animator) {
        this.animator.loop = this.loopOn;
        if (this.loopOn && !this.animator.playing) { this.animator.play(); this._reflectPlay(); }
      }
    });
    this.seekEl.addEventListener('input', () => {
      if (!this.animator) return;
      const [s, e] = this._range();
      this.animator.pause();
      this.animator.seek(s + (e - s) * (+this.seekEl.value / 1000));
      this._reflectPlay();
    });
    this.speedEl.addEventListener('change', () => {
      const s = this._readSpeed();
      this.speedEl.value = String(s);
      if (this.animator) this.animator.speed = s;
    });
    root.querySelector('.anim-views').addEventListener('click', (ev) => {
      const v = ev.target && ev.target.dataset && ev.target.dataset.view;
      if (!v || !this.animator) return;
      if (v === 'fit') this.animator.fit(); else this.animator.setView(v);
    });
    this._onResize = () => { if (this.animator && !root.hidden) this.animator.resize(); };
    window.addEventListener('resize', this._onResize);
  }

  _readSpeed() { const s = parseFloat(this.speedEl.value); return (isFinite(s) && s > 0) ? s : 1; }
  _range() { const T = this.info && this.info.times; return (T && T.length) ? [T[0], T[T.length - 1]] : [0, 1]; }
  _reflectPlay() { if (this.animator) this.playBtn.textContent = this.animator.playing ? '❚❚' : '▶'; }

  _reflectTime(t) {
    this.timeEl.textContent = (+t).toFixed(3) + ' s';
    const [s, e] = this._range();
    this.seekEl.value = String(e > s ? Math.round((t - s) / (e - s) * 1000) : 0);
    this._reflectPlay();
    if (this.onTime) this.onTime(t);
  }

  // Install a run and reveal the panel. `info` = { shapes, times, data, stride };
  // shapes[i].mesh (from anim-core.dxfMesh) is honored for CAD shapes.
  setData(info) {
    this.info = info;
    this.el.hidden = false;
    if (!this.animator) {
      this.animator = new Animator(this.viewEl);
      this.animator.onTime = (t) => this._reflectTime(t);
    }
    this.animator.setData({ shapes: info.shapes }, info.times, info.data, info.stride);
    this.animator.speed = this._readSpeed();
    this.animator.loop = this.loopOn;
    this.playBtn.textContent = '▶';
    requestAnimationFrame(() => this.animator.resize());
    this._reflectTime(info.times && info.times.length ? info.times[0] : 0);
  }

  hide() { this.el.hidden = true; if (this.animator) this.animator.pause(); this.info = null; }

  // Seek from outside (e.g. a click on a time-based chart).
  seek(t) { if (this.animator) { this.animator.pause(); this.animator.seek(t); this._reflectPlay(); } }

  resize() { if (this.animator) this.animator.resize(); }

  dispose() {
    window.removeEventListener('resize', this._onResize);
    if (this.animator) this.animator.dispose();
    this.animator = null;
    if (this.el.parentNode) this.el.parentNode.removeChild(this.el);
  }
}
