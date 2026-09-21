//! Standalone MultiBody-animation bindings for web clients that do not embed omc.
//!
//! `AnimScene::new` parses a `<model>_visual.xml`; the client supplies the result
//! columns the scene references and gets back the flat per-shape transform buffer
//! `animation.js` plays. The transform math is `openmodelica_animation`.

use std::collections::HashMap;

use openmodelica_animation::{Resolver, Scene, STRIDE};
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct AnimScene {
    scene: Scene,
}

struct MapResolver<'a> {
    time: &'a [f64],
    cols: &'a HashMap<String, Vec<f64>>,
}

impl Resolver for MapResolver<'_> {
    fn value(&self, cref: &str, t: f64) -> f64 {
        match self.cols.get(cref) {
            Some(vals) => interp(vals, self.time, t),
            None => 0.0,
        }
    }
}

/// Linear interpolation of `vals` (aligned to monotonic `time`) at `t`; a
/// length-1 series is a constant and out-of-range `t` clamps to the ends.
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

/// Turn the client's `{ cref: Float64Array }` object into a lookup map.
fn read_cols(cols: &JsValue) -> HashMap<String, Vec<f64>> {
    let mut map = HashMap::new();
    if let Ok(obj) = cols.clone().dyn_into::<js_sys::Object>() {
        for key in js_sys::Object::keys(&obj).iter() {
            let Some(name) = key.as_string() else { continue };
            if let Ok(val) = js_sys::Reflect::get(&obj, &key) {
                if let Ok(arr) = val.dyn_into::<js_sys::Float64Array>() {
                    map.insert(name, arr.to_vec());
                }
            }
        }
    }
    map
}

#[wasm_bindgen]
impl AnimScene {
    /// Parse a `<model>_visual.xml`; throws if it is not valid visualization XML.
    #[wasm_bindgen(constructor)]
    pub fn new(xml: &str) -> Result<AnimScene, JsError> {
        Scene::parse(xml)
            .map(|scene| AnimScene { scene })
            .map_err(|e| JsError::new(&e))
    }

    /// The shapes as `[{ id, kind, type }]` (kind is the `ShapeKind` tag), for
    /// the renderer to build meshes and resolve CAD (`type` is the DXF URI).
    pub fn shapes(&self) -> JsValue {
        let out = js_sys::Array::new();
        for s in &self.scene.shapes {
            let o = js_sys::Object::new();
            let _ = js_sys::Reflect::set(&o, &JsValue::from_str("id"), &JsValue::from_str(&s.id));
            let _ = js_sys::Reflect::set(&o, &JsValue::from_str("kind"), &JsValue::from_f64(s.kind.tag() as f64));
            let _ = js_sys::Reflect::set(&o, &JsValue::from_str("type"), &JsValue::from_str(&s.type_text));
            out.push(&o);
        }
        out.into()
    }

    /// Names of the result variables the scene references, so the client can hand
    /// back just those columns to [`AnimScene::all_frames`].
    pub fn crefs(&self) -> Vec<String> {
        self.scene.crefs()
    }

    /// Every shape's transform at every `time` row: `time.len() * shapes *
    /// STRIDE` f32s (row-major over time). `cols` is `{ cref: Float64Array }`
    /// aligned to `time`; missing crefs resolve to 0.
    pub fn all_frames(&self, time: &[f64], cols: JsValue) -> Vec<f32> {
        let cols = read_cols(&cols);
        let res = MapResolver { time, cols: &cols };
        let mut out = Vec::with_capacity(time.len() * self.scene.shapes.len() * STRIDE);
        for &t in time {
            out.extend_from_slice(&self.scene.frame_flat(&res, t));
        }
        out
    }
}

/// f32s per shape in an [`AnimScene::all_frames`] buffer.
#[wasm_bindgen]
pub fn stride() -> usize {
    STRIDE
}

/// Parse DXF CAD text into `{ positions, normals, colors }` Float32Arrays (3 per
/// vertex, three vertices per triangle; colors 0..1 RGB).
#[wasm_bindgen]
pub fn dxf_mesh(text: &str) -> JsValue {
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
