//! MultiBody animation bindings for the web simulator.
//!
//! After a `simulate(...)` run with `-d=visxml`, the backend leaves a
//! `<model>_visual.xml` in the VFS describing the scene's shapes. `omc_anim_scene`
//! parses it (via `openmodelica_animation`) and caches the shapes plus just the
//! result columns they reference; `omc_anim_frame(t)` then resolves every shape's
//! world transform at time `t` with no re-parsing. Rendering is the JS client's job.

use std::cell::RefCell;
use std::collections::HashMap;

use openmodelica_animation::{Resolver, Scene};
use openmodelica_codegen_wasm_jit::CodegenWasmJit;
use wasm_bindgen::prelude::*;

/// Parsed scene plus the subset of result data its crefs need, for one run.
struct AnimCache {
    scene: Scene,
    time: Vec<f64>,
    cols: HashMap<String, Vec<f64>>,
}

thread_local! {
    static CACHE: RefCell<Option<AnimCache>> = const { RefCell::new(None) };
}

struct CacheResolver<'a> {
    time: &'a [f64],
    cols: &'a HashMap<String, Vec<f64>>,
}

impl Resolver for CacheResolver<'_> {
    fn value(&self, cref: &str, t: f64) -> f64 {
        match self.cols.get(cref) {
            Some(vals) => interp(vals, self.time, t),
            None => 0.0,
        }
    }
}

/// Linear interpolation of `vals` (aligned to monotonic `time`) at `t`; a
/// length-1 series is a constant, and `t` outside the range clamps to the ends.
fn interp(vals: &[f64], time: &[f64], t: f64) -> f64 {
    match vals.len() {
        0 => 0.0,
        1 => vals[0],
        n => {
            let last = time.len().min(n) - 1;
            if t <= time[0] {
                return vals[0];
            }
            if t >= time[last] {
                return vals[last];
            }
            let (mut lo, mut hi) = (0usize, last);
            while hi - lo > 1 {
                let mid = (lo + hi) / 2;
                if time[mid] <= t {
                    lo = mid;
                } else {
                    hi = mid;
                }
            }
            let (t0, t1) = (time[lo], time[hi]);
            let f = if t1 > t0 { (t - t0) / (t1 - t0) } else { 0.0 };
            vals[lo] + (vals[hi] - vals[lo]) * f
        }
    }
}

/// The `<model>_visual.xml` for the last run, if `-d=visxml` produced one. Tries
/// the exact `<model>_visual.xml` name, then falls back to any `*_visual.xml` in
/// the VFS (the file prefix does not always equal the run's model name).
fn read_visual_xml(model: &str) -> Option<String> {
    let bytes = openmodelica_wasi::read(&format!("{model}_visual.xml")).or_else(|| {
        let path = openmodelica_wasi::list().into_iter().find(|p| p.ends_with("_visual.xml"))?;
        openmodelica_wasi::read(&path)
    })?;
    String::from_utf8(bytes).ok()
}

/// Parse the last run's visual XML and cache it with the result columns its
/// crefs reference. Returns a `{ model, start, stop, shapes:[{id,kind,type}] }`
/// object, or `null` when the run produced no visualization.
#[wasm_bindgen]
pub fn omc_anim_scene() -> JsValue {
    let Some((model, start, stop)) =
        CodegenWasmJit::with_last_sim(|s| (s.model_name.clone(), s.start_time, s.stop_time))
    else {
        return JsValue::NULL;
    };
    let Some(xml) = read_visual_xml(&model) else {
        return JsValue::NULL;
    };
    let Ok(scene) = Scene::parse(&xml) else {
        return JsValue::NULL;
    };

    // Clone only the columns the scene references (and time).
    let needed = scene.crefs();
    let built = CodegenWasmJit::with_last_sim(|sim| {
        let mut cols = HashMap::new();
        for name in &needed {
            if let Some(s) = sim.series.iter().find(|s| &s.name == name) {
                cols.insert(name.clone(), s.values.clone());
            }
        }
        (sim.time.clone(), cols)
    });
    let Some((time, cols)) = built else {
        return JsValue::NULL;
    };

    let shapes = js_sys::Array::new();
    for s in &scene.shapes {
        let o = js_sys::Object::new();
        let _ = js_sys::Reflect::set(&o, &JsValue::from_str("id"), &JsValue::from_str(&s.id));
        let _ = js_sys::Reflect::set(&o, &JsValue::from_str("kind"), &JsValue::from_f64(s.kind.tag() as f64));
        let _ = js_sys::Reflect::set(&o, &JsValue::from_str("type"), &JsValue::from_str(&s.type_text));
        shapes.push(&o);
    }
    let out = js_sys::Object::new();
    let _ = js_sys::Reflect::set(&out, &JsValue::from_str("model"), &JsValue::from_str(&model));
    let _ = js_sys::Reflect::set(&out, &JsValue::from_str("start"), &JsValue::from_f64(start));
    let _ = js_sys::Reflect::set(&out, &JsValue::from_str("stop"), &JsValue::from_f64(stop));
    let _ = js_sys::Reflect::set(&out, &JsValue::from_str("shapes"), &shapes);

    CACHE.with(|c| *c.borrow_mut() = Some(AnimCache { scene, time, cols }));
    out.into()
}

/// Per-shape world transforms at time `t`, flattened to `shapes.len() *
/// STRIDE` f32s (see `openmodelica_animation::STRIDE`). `None` until
/// [`omc_anim_scene`] has cached a scene.
#[wasm_bindgen]
pub fn omc_anim_frame(t: f64) -> Option<Vec<f32>> {
    CACHE.with(|c| {
        c.borrow().as_ref().map(|cache| {
            let res = CacheResolver { time: &cache.time, cols: &cache.cols };
            cache.scene.frame_flat(&res, t)
        })
    })
}

/// Every shape's transform at every result time row, concatenated:
/// `rows * shapes * STRIDE` f32s (row-major over time). Lets the client fetch
/// the whole animation in one call instead of per-frame round-trips. `None`
/// until [`omc_anim_scene`] has cached a scene.
#[wasm_bindgen]
pub fn omc_anim_all_frames() -> Option<Vec<f32>> {
    CACHE.with(|c| {
        c.borrow().as_ref().map(|cache| {
            let res = CacheResolver { time: &cache.time, cols: &cache.cols };
            let mut out =
                Vec::with_capacity(cache.time.len() * cache.scene.shapes.len() * openmodelica_animation::STRIDE);
            for &t in &cache.time {
                out.extend_from_slice(&cache.scene.frame_flat(&res, t));
            }
            out
        })
    })
}

/// f32s per shape in an [`omc_anim_frame`] buffer.
#[wasm_bindgen]
pub fn omc_anim_stride() -> usize {
    openmodelica_animation::STRIDE
}

/// Parse a DXF CAD file (as text) into a renderable triangle mesh:
/// `{ positions, normals, colors }`, each a `Float32Array` (3 per vertex,
/// vertices grouped three-per-triangle; colors are 0..1 RGB). The client
/// resolves the shape's `modelica://` URI to file text and hands it here; the
/// mesh is placed by the same per-shape transform the primitives use.
#[wasm_bindgen]
pub fn omc_dxf_mesh(text: &str) -> JsValue {
    let mesh = openmodelica_animation::parse_dxf(text);
    let out = js_sys::Object::new();
    let set = |k: &str, v: &[f32]| {
        let _ = js_sys::Reflect::set(&out, &JsValue::from_str(k), &js_sys::Float32Array::from(v));
    };
    set("positions", &mesh.positions);
    set("normals", &mesh.normals);
    set("colors", &mesh.colors);
    out.into()
}
