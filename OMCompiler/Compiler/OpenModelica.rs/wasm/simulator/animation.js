// 3D animation view for MultiBody models. Consumes the scene + per-frame
// transform buffer produced by the omc module (omc_anim_* → openmodelica_animation
// crate) and renders it with three.js. The transform math lives in Rust so this
// file only builds meshes and plays them back.
//
// Frame buffer layout (STRIDE floats per shape, from the crate):
//   [0] kind, [1..9] rot (res._T, row-major), [10..12] pos, [13..15] size
//   (length,width,height), [16] extra, [17..19] color (0..255 RGB).
// rot/pos follow OMEdit's OSG "poke" convention: a local point p (length axis =
// local +Z) maps to world as p·rot + pos (row-vector), so the three.js matrix is
// the transpose (see _applyShape).

import * as THREE from 'three';
import { OrbitControls } from './OrbitControls.js';

// ShapeKind tags (openmodelica_animation::ShapeKind order).
const KIND = { BOX: 0, SPHERE: 1, CYLINDER: 2, CONE: 3, PIPECYLINDER: 4, PIPE: 5, BEAM: 6, GEARWHEEL: 7, SPRING: 8, CAD: 9 };

// Unit geometry per kind, with the shape's length axis along local +Z and its
// base at z=0 — matching OMEdit's osg primitives, so the crate's poke matrix
// places them identically. Real dimensions come from a per-frame non-uniform
// scale (see scaleFor). Radial kinds share a unit cylinder/cone/sphere.
function buildUnitGeometries() {
  const g = {};
  const box = new THREE.BoxGeometry(1, 1, 1); box.translate(0, 0, 0.5);
  g[KIND.BOX] = box; g[KIND.BEAM] = box;
  const cyl = new THREE.CylinderGeometry(0.5, 0.5, 1, 24); cyl.rotateX(Math.PI / 2); cyl.translate(0, 0, 0.5);
  g[KIND.CYLINDER] = cyl; g[KIND.PIPE] = cyl; g[KIND.PIPECYLINDER] = cyl; g[KIND.GEARWHEEL] = cyl; g[KIND.SPRING] = cyl;
  const cone = new THREE.ConeGeometry(0.5, 1, 24); cone.rotateX(Math.PI / 2); cone.translate(0, 0, 0.5);
  g[KIND.CONE] = cone;
  const sph = new THREE.SphereGeometry(0.5, 24, 16); sph.translate(0, 0, 0.5);
  g[KIND.SPHERE] = sph;
  return g;
}

// Local scale mapping unit geometry → real dimensions. Box/beam use all three
// dims; radial kinds use width for the radius (x,y) and length for the axis (z);
// a sphere is a length-diameter ball.
function scaleFor(kind, length, width, height) {
  switch (kind) {
    case KIND.BOX:
    case KIND.BEAM: return [width, height, length];
    case KIND.SPHERE: return [length, length, length];
    default: return [width, width, length];
  }
}

// Camera presets matching OMEdit (AbstractAnimationWindow::cameraPosition*): `dir`
// is the world direction from the target toward the camera, `up` the camera up.
// Side is OMEdit's default for Modelica models (x right, y up, z toward viewer).
const VIEWS = {
  iso:   { dir: [0.57735, 0.57735, 0.57735], up: [-0.409, 0.816, -0.409] },
  side:  { dir: [0, 0, 1], up: [0, 1, 0] },   // look -Z
  front: { dir: [1, 0, 0], up: [0, 1, 0] },   // look -X
  top:   { dir: [0, 1, 0], up: [1, 0, 0] },   // look -Y
};
const DEFAULT_VIEW = 'side';

export class Animator {
  constructor(container) {
    this.container = container;
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0xf2f2f2);   // OMEdit's animation clear colour
    this.camera = new THREE.PerspectiveCamera(45, 1, 1e-3, 1e5);
    this.camera.up.set(0, 0, 1);

    this.renderer = new THREE.WebGLRenderer({ antialias: true });
    this.renderer.setPixelRatio(window.devicePixelRatio || 1);
    container.appendChild(this.renderer.domElement);
    Object.assign(this.renderer.domElement.style, { width: '100%', height: '100%', display: 'block' });

    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    // No damping (which would need a continuous rAF loop); instead re-render on
    // every control change so orbiting works whether or not playback is running.
    this.controls.enableDamping = false;
    this.controls.addEventListener('change', () => this.renderOnce());

    this.scene.add(new THREE.HemisphereLight(0xffffff, 0x9a9a9a, 1.1));
    const key = new THREE.DirectionalLight(0xffffff, 1.4); key.position.set(1, 1, 2); this.scene.add(key);

    this.unit = buildUnitGeometries();
    this.meshes = [];
    this.times = null; this.data = null; this.stride = 0; this.nshapes = 0;
    this.center = new THREE.Vector3(); this.radius = 1; this.extents = [1, 1, 1];

    this.time = 0; this.playing = false; this.speed = 1; this.loop = false;
    this._last = 0; this._raf = null; this._scratch = null;
    this._tmpScale = new THREE.Matrix4();
    this.onTime = null;
    this._loop = this._loop.bind(this);
    this._onResize = () => this.resize();
    window.addEventListener('resize', this._onResize);
  }

  // Install a run: scene description (shape kinds/ids), the result time column,
  // and the flat transform buffer (rows * nshapes * stride).
  setData(sceneDesc, times, data, stride) {
    this._clearMeshes();
    this.times = times; this.data = data; this.stride = stride;
    this.nshapes = sceneDesc.shapes.length;
    for (const s of sceneDesc.shapes) {
      let mesh;
      if (s.kind === KIND.CAD) {
        mesh = this._buildCadMesh(s);
        if (!mesh) { this.meshes.push(null); continue; }   // unsupported CAD (no dxf mesh)
      } else {
        const geom = this.unit[s.kind];
        if (!geom) { this.meshes.push(null); continue; }
        mesh = new THREE.Mesh(geom, new THREE.MeshStandardMaterial({ color: 0xcccccc, roughness: 0.55, metalness: 0.1 }));
      }
      mesh.matrixAutoUpdate = false; mesh.name = s.id;
      this.scene.add(mesh); this.meshes.push(mesh);
    }
    this._computeBounds();
    this.setView(DEFAULT_VIEW);
    this.time = times && times.length ? times[0] : 0;
    this.renderAt(this.time);
  }

  // Build a mesh from a CAD shape's triangle data (from omc_dxf_mesh, attached
  // by the worker). Vertices are in the file's own coordinates; the per-frame
  // transform (with the CAD orientation) and length/width/height scale place it.
  _buildCadMesh(s) {
    const m = s.mesh;
    if (!m || !m.positions || !m.positions.length) return null;
    const g = new THREE.BufferGeometry();
    g.setAttribute('position', new THREE.BufferAttribute(m.positions, 3));
    g.setAttribute('normal', new THREE.BufferAttribute(m.normals, 3));
    g.setAttribute('color', new THREE.BufferAttribute(m.colors, 3));
    const mesh = new THREE.Mesh(g, new THREE.MeshStandardMaterial(
      { vertexColors: true, roughness: 0.6, metalness: 0.15, side: THREE.DoubleSide }));
    mesh.userData.owned = true;                 // owns its geometry (dispose on clear)
    return mesh;
  }

  _computeBounds() {
    const bb = new THREE.Box3(), p = new THREE.Vector3();
    const rows = this.times ? this.times.length : 0;
    for (let f = 0; f < rows; f++)
      for (let s = 0; s < this.nshapes; s++) {
        const o = (f * this.nshapes + s) * this.stride;
        bb.expandByPoint(p.set(this.data[o + 10], this.data[o + 11], this.data[o + 12]));
      }
    if (bb.isEmpty()) bb.setFromCenterAndSize(new THREE.Vector3(), new THREE.Vector3(1, 1, 1));
    const size = bb.getSize(new THREE.Vector3());
    bb.getCenter(this.center);
    this.extents = [size.x, size.y, size.z];
    this.radius = Math.max(size.length() * 0.5, 0.05);
  }

  // Re-apply the current view, re-fitting the distance to the scene.
  fit() { this.setView(this._view || DEFAULT_VIEW); }

  setView(name) {
    const v = VIEWS[name] || VIEWS[DEFAULT_VIEW];
    this._view = VIEWS[name] ? name : DEFAULT_VIEW;
    const dir = new THREE.Vector3(...v.dir).normalize();
    const dist = this.radius / Math.tan((this.camera.fov * Math.PI / 180) / 2) * 1.3;
    this.camera.up.set(...v.up);
    this.camera.position.copy(this.center).addScaledVector(dir, dist);
    this.camera.near = dist / 100; this.camera.far = dist * 100;
    this.camera.updateProjectionMatrix();
    this.controls.target.copy(this.center);
    this.controls.update();
    this.renderOnce();
  }

  _applyShape(mesh, o) {
    const d = this.data;
    // rot = res._T (row-major); three.js needs the transpose (column-vector form)
    // with the translation in the 4th column.
    mesh.matrix.set(
      d[o + 1], d[o + 4], d[o + 7], d[o + 10],
      d[o + 2], d[o + 5], d[o + 8], d[o + 11],
      d[o + 3], d[o + 6], d[o + 9], d[o + 12],
      0, 0, 0, 1);
    const kind = d[o] | 0;
    // CAD meshes carry file coordinates: scale by length/width/height only when
    // the shape's `extra` flag is set (matching OMEdit's DXF scaleVertices).
    const sc = kind === KIND.CAD
      ? (d[o + 16] ? [d[o + 13], d[o + 14], d[o + 15]] : [1, 1, 1])
      : scaleFor(kind, d[o + 13], d[o + 14], d[o + 15]);
    this._tmpScale.makeScale(sc[0] || 1e-6, sc[1] || 1e-6, sc[2] || 1e-6);
    mesh.matrix.multiply(this._tmpScale);
    // CAD meshes are per-vertex coloured from the DXF; primitives use the shape colour.
    if (!mesh.material.vertexColors) mesh.material.color.setRGB(d[o + 17] / 255, d[o + 18] / 255, d[o + 19] / 255);
  }

  _locate(t) {
    const T = this.times, n = T.length;
    if (n === 0 || t <= T[0]) return [0, 0, 0];
    if (t >= T[n - 1]) return [n - 1, n - 1, 0];
    let lo = 0, hi = n - 1;
    while (hi - lo > 1) { const mid = (lo + hi) >> 1; if (T[mid] <= t) lo = mid; else hi = mid; }
    return [lo, hi, T[hi] > T[lo] ? (t - T[lo]) / (T[hi] - T[lo]) : 0];
  }

  renderAt(t) {
    if (!this.data || !this.times) { this.renderOnce(); return; }
    const [f0, f1, a] = this._locate(t), d = this.data, stride = this.stride, ns = this.nshapes;
    for (let s = 0; s < ns; s++) {
      const mesh = this.meshes[s]; if (!mesh) continue;
      const o0 = (f0 * ns + s) * stride;
      if (a === 0 || f0 === f1) { this._applyShape(mesh, o0); continue; }
      const o1 = (f1 * ns + s) * stride;
      const scratch = this._scratch || (this._scratch = new Float32Array(stride));
      for (let i = 0; i < stride; i++) scratch[i] = d[o0 + i] + (d[o1 + i] - d[o0 + i]) * a;
      const save = this.data; this.data = scratch; this._applyShape(mesh, 0); this.data = save;
    }
    this.renderOnce();
  }

  renderOnce() { this.renderer.render(this.scene, this.camera); }

  play() {
    if (this.playing || !this.times || this.times.length < 2) return;
    this.playing = true; this._last = performance.now();
    if (this.time >= this.times[this.times.length - 1]) this.time = this.times[0];
    this._raf = requestAnimationFrame(this._loop);
  }
  pause() { this.playing = false; if (this._raf) cancelAnimationFrame(this._raf); this._raf = null; }
  toggle() { this.playing ? this.pause() : this.play(); }
  seek(t) { this.time = t; this.renderAt(t); if (this.onTime) this.onTime(t); }

  _loop(now) {
    if (!this.playing) return;
    const dt = (now - this._last) / 1000; this._last = now;
    const end = this.times[this.times.length - 1];
    this.time += dt * this.speed;
    if (this.time >= end) {
      if (this.loop) { this.time = this.times[0]; this._last = now; }
      else { this.time = end; this.pause(); this.renderAt(this.time); if (this.onTime) this.onTime(this.time); return; }
    }
    this.renderAt(this.time);
    if (this.onTime) this.onTime(this.time);
    this._raf = requestAnimationFrame(this._loop);
  }

  resize() {
    const w = this.container.clientWidth || 1, h = this.container.clientHeight || 1;
    this.camera.aspect = w / h; this.camera.updateProjectionMatrix();
    this.renderer.setSize(w, h, false);
    this.renderOnce();
  }

  _clearMeshes() {
    for (const m of this.meshes) if (m) { this.scene.remove(m); m.material.dispose(); if (m.userData.owned) m.geometry.dispose(); }
    this.meshes = []; this._scratch = null;
  }

  dispose() {
    this.pause();
    window.removeEventListener('resize', this._onResize);
    this._clearMeshes();
    for (const k in this.unit) this.unit[k].dispose();
    this.controls.dispose();
    this.renderer.dispose();
    if (this.renderer.domElement.parentNode) this.renderer.domElement.parentNode.removeChild(this.renderer.domElement);
  }
}
