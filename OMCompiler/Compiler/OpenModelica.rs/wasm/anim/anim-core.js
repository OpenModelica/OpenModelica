// Shared MultiBody-animation core: wraps the standalone openmodelica_animation
// wasm, so the Modelica and FMI simulators build frames from one code path
// regardless of where the result data comes from.

import init, { AnimScene, stride as wasmStride, dxf_mesh } from './openmodelica_animation_wasm.js';

let ready = null;
export function initAnim() { return ready || (ready = init()); }

const asF64 = (a) => (a instanceof Float64Array ? a : Float64Array.from(a));

// Build the renderer payload from the visual XML and the run's data. `lookup(cref)`
// returns a variable's values or undefined. Returns { shapes, times, data, stride,
// missing } (missing = crefs with no data), or null when there is no scene.
export async function buildAnimData(xmlText, time, lookup) {
  await initAnim();
  let scene;
  try { scene = new AnimScene(xmlText); } catch (_) { return null; }
  try {
    const shapes = scene.shapes();
    if (!shapes || !shapes.length) return null;
    const cols = {};
    const missing = [];
    for (const name of scene.crefs()) {
      const v = lookup(name);
      if (v && v.length) cols[name] = asF64(v);
      else missing.push(name);
    }
    const times = asF64(time);
    const data = scene.all_frames(times, cols);
    return { shapes, times, data, stride: wasmStride(), missing };
  } finally {
    scene.free();
  }
}

// Parse DXF CAD text into { positions, normals, colors } Float32Arrays.
export function dxfMesh(text) { return dxf_mesh(text); }

// Attach a triangle mesh to each CAD shape. `readCad(type)` returns the shape's
// DXF text (from the omc VFS, an FMU resource, …) or null; the caller owns the
// source. Only DXF is supported; other CAD is left unmeshed (and skipped).
export function attachCadMeshes(shapes, readCad) {
  for (const s of shapes) {
    if (s.kind !== 9 || !/\.dxf$/i.test(s.type || '')) continue;   // 9 = ShapeKind::Cad
    try {
      const text = readCad(s.type);
      if (!text) continue;
      const mesh = dxf_mesh(text);
      if (mesh && mesh.positions && mesh.positions.length) s.mesh = mesh;
    } catch (_) { /* unreadable/unsupported CAD: skip */ }
  }
}
