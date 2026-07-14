//! Vec3/Mat3 helpers, a faithful f32 port of OMEdit's Animation math so the web
//! renderer matches the desktop OSG one. Matrices are row-major `[f32; 9]`.

pub type Vec3 = [f32; 3];
pub type Mat3 = [f32; 9];

pub fn len(v: Vec3) -> f32 {
    (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]).sqrt()
}

pub fn cross(a: Vec3, b: Vec3) -> Vec3 {
    [
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    ]
}

pub fn dot(a: Vec3, b: Vec3) -> f32 {
    a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
}

pub fn add(a: Vec3, b: Vec3) -> Vec3 {
    [a[0] + b[0], a[1] + b[1], a[2] + b[2]]
}

pub fn scale(v: Vec3, s: f32) -> Vec3 {
    [v[0] * s, v[1] * s, v[2] * s]
}

/// OMEdit's `normalize`: guards against a zero-length direction.
pub fn normalize(v: Vec3) -> Vec3 {
    let l = len(v);
    let d = if l as f64 >= 100.0 * 1.0e-15 { l } else { 100.0 * 1.0e-15 } as f32;
    scale(v, 1.0 / d)
}

/// Row vector times matrix: `V · M` with M's columns (OMEdit `V3mulMat3`).
pub fn v3_mul_mat3(v: Vec3, m: Mat3) -> Vec3 {
    [
        m[0] * v[0] + m[3] * v[1] + m[6] * v[2],
        m[1] * v[0] + m[4] * v[1] + m[7] * v[2],
        m[2] * v[0] + m[5] * v[1] + m[8] * v[2],
    ]
}

/// Standard row-major 3×3 product (OMEdit `Mat3mulMat3`).
pub fn mat3_mul_mat3(a: Mat3, b: Mat3) -> Mat3 {
    let mut m = [0.0f32; 9];
    for i in 0..3 {
        for j in 0..3 {
            let mut x = 0.0;
            for k in 0..3 {
                x = a[i * 3 + k] * b[k * 3 + j] + x;
            }
            m[i * 3 + j] = x;
        }
    }
    m
}
