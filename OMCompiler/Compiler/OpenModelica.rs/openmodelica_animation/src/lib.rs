//! MultiBody visualization core shared by OpenModelica clients.
//!
//! Turns the `<model>_visual.xml` that `-d=visxml` emits, plus a simulation
//! result, into per-shape world transforms. The transform math is a faithful
//! f32 port of OMEdit's `Animation` code so the web renderer matches desktop.
//! No GPU or platform dependency: a client supplies a [`Resolver`] over its own
//! result data (wasm-jit in the browser, a MAT reader natively).

pub mod dxf;
mod math;
mod scene;

use math::{add, cross, dot, len, mat3_mul_mat3, normalize, scale, v3_mul_mat3, Mat3, Vec3};
pub use dxf::{parse_dxf, CadMesh};
pub use scene::{Attr, Scene, Shape, ShapeKind};

/// Looks up a result variable's value at time `t`. Values are expected already
/// sign-corrected for negated aliases (the wasm-jit result store does this).
pub trait Resolver {
    fn value(&self, cref: &str, t: f64) -> f64;
}

/// One shape placed for a single time point. `rot`/`pos` follow OMEdit's OSG
/// "poke" convention: a local point `p` (length axis = local +Z) maps to world
/// as `p·rot + pos` (row-vector). `size` is (length, width, height); `color` is
/// Modelica's 0–255 RGB.
#[derive(Clone, Debug, PartialEq)]
pub struct ShapeInstance {
    pub kind: u8,
    pub rot: Mat3,
    pub pos: Vec3,
    pub size: Vec3,
    pub extra: f32,
    pub color: Vec3,
}

/// f32s per shape in [`Scene::frame_flat`]: kind, rot[9], pos[3], size[3], extra, color[3].
pub const STRIDE: usize = 20;

struct Directions {
    l: Vec3,
    w: Vec3,
}

/// OMEdit `fixDirections`: orthonormal length/width axes from the raw directions.
fn fix_directions(l_dir: Vec3, w_dir: Vec3) -> Directions {
    let abs_n_x = len(l_dir) as f64;
    let e_x = if abs_n_x < 1e-10 {
        [1.0, 0.0, 0.0]
    } else {
        scale(l_dir, (1.0 / abs_n_x) as f32)
    };
    let n_z_aux = cross(e_x, w_dir);
    let e_y_aux = if dot(n_z_aux, n_z_aux) > 1e-6 {
        w_dir
    } else if e_x[0].abs() > 1e-6 {
        [0.0, 1.0, 0.0]
    } else {
        [1.0, 0.0, 0.0]
    };
    let e_y = cross(normalize(cross(e_x, e_y_aux)), e_x);
    Directions { l: e_x, w: e_y }
}

/// OMEdit `rotateModelica2OSG`: base-frame (T, r) plus shape offset/directions
/// → the shape's world rotation and position.
fn rotate_modelica_to_osg(
    t: Mat3,
    r: Vec3,
    r_shape: Vec3,
    l_dir: Vec3,
    w_dir: Vec3,
    cad: bool,
) -> (Mat3, Vec3) {
    let d = fix_directions(l_dir, w_dir);
    let h = cross(d.l, d.w);
    let t0: Mat3 = if cad {
        [d.l[0], d.l[1], d.l[2], d.w[0], d.w[1], d.w[2], h[0], h[1], h[2]]
    } else {
        [d.w[0], d.w[1], d.w[2], h[0], h[1], h[2], d.l[0], d.l[1], d.l[2]]
    };
    let res_r = add(v3_mul_mat3(r_shape, t), r);
    let res_t = mat3_mul_mat3(t0, t);
    (res_t, res_r)
}

fn resolve3(a: &[Attr; 3], r: &dyn Resolver, t: f64) -> Vec3 {
    [
        a[0].resolve(r, t) as f32,
        a[1].resolve(r, t) as f32,
        a[2].resolve(r, t) as f32,
    ]
}

fn resolve9(a: &[Attr; 9], r: &dyn Resolver, t: f64) -> Mat3 {
    std::array::from_fn(|i| a[i].resolve(r, t) as f32)
}

impl Shape {
    /// Place this shape at time `t`.
    pub fn instance(&self, res: &dyn Resolver, t: f64) -> ShapeInstance {
        let (rot, pos) = rotate_modelica_to_osg(
            resolve9(&self.t, res, t),
            resolve3(&self.r, res, t),
            resolve3(&self.r_shape, res, t),
            resolve3(&self.length_dir, res, t),
            resolve3(&self.width_dir, res, t),
            self.kind == ShapeKind::Cad,
        );
        ShapeInstance {
            kind: self.kind.tag(),
            rot,
            pos,
            size: [
                self.length.resolve(res, t) as f32,
                self.width.resolve(res, t) as f32,
                self.height.resolve(res, t) as f32,
            ],
            extra: self.extra.resolve(res, t) as f32,
            color: resolve3(&self.color, res, t),
        }
    }
}

impl Scene {
    /// Place every shape at time `t`.
    pub fn frame(&self, res: &dyn Resolver, t: f64) -> Vec<ShapeInstance> {
        self.shapes.iter().map(|s| s.instance(res, t)).collect()
    }

    /// [`Scene::frame`] flattened to `shapes.len() * STRIDE` f32s for FFI.
    pub fn frame_flat(&self, res: &dyn Resolver, t: f64) -> Vec<f32> {
        let mut out = Vec::with_capacity(self.shapes.len() * STRIDE);
        for inst in self.frame(res, t) {
            out.push(inst.kind as f32);
            out.extend_from_slice(&inst.rot);
            out.extend_from_slice(&inst.pos);
            out.extend_from_slice(&inst.size);
            out.push(inst.extra);
            out.extend_from_slice(&inst.color);
        }
        out
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const DP: &str = include_str!("../tests/DoublePendulum_visual.xml");

    struct Zero;
    impl Resolver for Zero {
        fn value(&self, _: &str, _: f64) -> f64 {
            0.0
        }
    }

    /// A resolver backed by a fixed name→value table.
    struct Table(std::collections::HashMap<&'static str, f64>);
    impl Resolver for Table {
        fn value(&self, cref: &str, _: f64) -> f64 {
            *self.0.get(cref).unwrap_or(&0.0)
        }
    }

    #[test]
    fn parses_double_pendulum() {
        let s = Scene::parse(DP).unwrap();
        assert_eq!(s.shapes.len(), 19);
        let first = &s.shapes[0];
        assert_eq!(first.id, "world.x_arrowHead");
        assert_eq!(first.kind, ShapeKind::Cone);
        // T is the identity constant; r[0] is a cref, r[1]/r[2] constants.
        assert_eq!(first.t[0], Attr::Const(1.0));
        assert!(matches!(first.r[0], Attr::Cref(_)));
        assert_eq!(first.r[1], Attr::Const(0.0));
    }

    #[test]
    fn crefs_are_unique_and_present() {
        let s = Scene::parse(DP).unwrap();
        let crefs = s.crefs();
        assert!(crefs.iter().any(|c| c == "world.x_arrowHead.r[1]"));
        let mut sorted = crefs.clone();
        sorted.sort();
        sorted.dedup();
        assert_eq!(sorted.len(), crefs.len(), "crefs must be unique");
    }

    #[test]
    fn frame_flat_has_expected_stride() {
        let s = Scene::parse(DP).unwrap();
        let flat = s.frame_flat(&Zero, 0.0);
        assert_eq!(flat.len(), s.shapes.len() * STRIDE);
        assert!(flat.iter().all(|v| v.is_finite()));
    }

    #[test]
    fn identity_frame_places_shape_at_origin_position() {
        // Identity T, unit x/y directions, position r = (1,2,3), no shape offset.
        let xml = r#"<visualization><shape>
            <ident>s</ident><type>box</type>
            <T><exp>1</exp><exp>0</exp><exp>0</exp><exp>0</exp><exp>1</exp><exp>0</exp><exp>0</exp><exp>0</exp><exp>1</exp></T>
            <r><exp>1</exp><exp>2</exp><exp>3</exp></r>
            <r_shape><exp>0</exp><exp>0</exp><exp>0</exp></r_shape>
            <lengthDir><exp>1</exp><exp>0</exp><exp>0</exp></lengthDir>
            <widthDir><exp>0</exp><exp>1</exp><exp>0</exp></widthDir>
            <length><exp>0.5</exp></length><width><exp>0.1</exp></width><height><exp>0.2</exp></height>
            <extra><exp>0</exp></extra>
            <color><exp>255</exp><exp>0</exp><exp>0</exp></color>
            <specCoeff><exp>0.7</exp></specCoeff>
        </shape></visualization>"#;
        let s = Scene::parse(xml).unwrap();
        let inst = &s.frame(&Zero, 0.0)[0];
        assert_eq!(inst.pos, [1.0, 2.0, 3.0]);
        assert_eq!(inst.size, [0.5, 0.1, 0.2]);
        assert_eq!(inst.color, [255.0, 0.0, 0.0]);
        // lengthDir=x, widthDir=y → local +Z maps to world x (length axis).
        // rot row 2 (local Z) should equal lengthDir = (1,0,0).
        assert!((inst.rot[6] - 1.0).abs() < 1e-6);
        assert!(inst.rot[7].abs() < 1e-6 && inst.rot[8].abs() < 1e-6);
    }

    #[test]
    fn cref_position_resolves_from_table() {
        let s = Scene::parse(DP).unwrap();
        let mut t = std::collections::HashMap::new();
        t.insert("world.x_arrowHead.r[1]", 0.75);
        let inst = &s.frame(&Table(t), 0.0)[0];
        assert!((inst.pos[0] - 0.75).abs() < 1e-6);
    }
}
