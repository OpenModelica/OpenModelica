//! Minimal DXF reader for MultiBody CAD shapes.
//!
//! Extracts `3DFACE` entities into a renderable triangle mesh, faithful to
//! OMEdit's `ExtraShapes` DXFile: per-face AutoCAD Color Index resolved to RGB,
//! quads split into two triangles. Reusable by any animation client.

/// A triangle mesh. `positions` and `normals` hold 3 f32 per vertex, `colors`
/// 3 f32 (0..1 RGB) per vertex; vertices are grouped three-per-triangle.
#[derive(Clone, Debug, Default)]
pub struct CadMesh {
    pub positions: Vec<f32>,
    pub normals: Vec<f32>,
    pub colors: Vec<f32>,
}

impl CadMesh {
    pub fn triangles(&self) -> usize {
        self.positions.len() / 9
    }
}

#[derive(Default)]
struct Face {
    v: [[f32; 3]; 4],
    color: i32,
}

/// Parse the `3DFACE` entities of a DXF file into a triangle mesh.
pub fn parse_dxf(text: &str) -> CadMesh {
    let mut mesh = CadMesh::default();
    let mut lines = text.lines().map(str::trim);
    let mut cur: Option<Face> = None;
    // DXF is a stream of (group-code, value) line pairs; code 0 starts an entity.
    while let (Some(code_s), Some(val)) = (lines.next(), lines.next()) {
        let Ok(code) = code_s.parse::<i32>() else { continue };
        if code == 0 {
            if let Some(f) = cur.take() {
                emit_face(&f, &mut mesh);
            }
            if val == "3DFACE" {
                cur = Some(Face::default());
            }
            continue;
        }
        let Some(f) = cur.as_mut() else { continue };
        match code {
            62 => f.color = val.parse().unwrap_or(0),
            10 => f.v[0][0] = pf(val),
            20 => f.v[0][1] = pf(val),
            30 => f.v[0][2] = pf(val),
            11 => f.v[1][0] = pf(val),
            21 => f.v[1][1] = pf(val),
            31 => f.v[1][2] = pf(val),
            12 => f.v[2][0] = pf(val),
            22 => f.v[2][1] = pf(val),
            32 => f.v[2][2] = pf(val),
            13 => f.v[3][0] = pf(val),
            23 => f.v[3][1] = pf(val),
            33 => f.v[3][2] = pf(val),
            _ => {}
        }
    }
    if let Some(f) = cur.take() {
        emit_face(&f, &mut mesh);
    }
    mesh
}

fn pf(s: &str) -> f32 {
    s.parse().unwrap_or(0.0)
}

// A 3DFACE with coincident 1st and 4th corners is a triangle, otherwise a quad
// that splits into two triangles (matching OMEdit's DXFile primitive sets).
fn emit_face(f: &Face, m: &mut CadMesh) {
    let rgb = aci_rgb(f.color);
    let tris: &[[usize; 3]] =
        if f.v[0] == f.v[3] { &[[0, 1, 2]] } else { &[[0, 1, 2], [0, 2, 3]] };
    for t in tris {
        let n = normal(f.v[t[0]], f.v[t[1]], f.v[t[2]]);
        for &vi in t {
            m.positions.extend_from_slice(&f.v[vi]);
            m.normals.extend_from_slice(&n);
            m.colors.extend_from_slice(&rgb);
        }
    }
}

fn normal(a: [f32; 3], b: [f32; 3], c: [f32; 3]) -> [f32; 3] {
    let u = [b[0] - a[0], b[1] - a[1], b[2] - a[2]];
    let v = [c[0] - a[0], c[1] - a[1], c[2] - a[2]];
    let n = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]];
    let len = (n[0] * n[0] + n[1] * n[1] + n[2] * n[2]).sqrt();
    if len > 0.0 {
        [n[0] / len, n[1] / len, n[2] / len]
    } else {
        [0.0, 0.0, 1.0]
    }
}

fn aci_rgb(code: i32) -> [f32; 3] {
    let c = ACI[code.clamp(0, 255) as usize];
    [c[0] as f32 / 255.0, c[1] as f32 / 255.0, c[2] as f32 / 255.0]
}

// AutoCAD Color Index → RGB, ported from OMEdit's getAutoCADRGB.
#[rustfmt::skip]
static ACI: [[u8; 3]; 256] = [
    [0, 0, 0],
    [255, 0, 0],
    [255, 255, 0],
    [0, 255, 0],
    [0, 255, 255],
    [0, 0, 255],
    [255, 0, 255],
    [255, 255, 255],
    [65, 65, 65],
    [128, 128, 128],
    [255, 0, 0],
    [255, 170, 170],
    [189, 0, 0],
    [189, 126, 126],
    [129, 0, 0],
    [129, 86, 86],
    [104, 0, 0],
    [104, 69, 69],
    [79, 0, 0],
    [79, 53, 53],
    [255, 63, 0],
    [255, 191, 170],
    [189, 46, 0],
    [189, 141, 126],
    [129, 31, 0],
    [129, 96, 86],
    [104, 25, 0],
    [104, 78, 69],
    [79, 19, 0],
    [79, 59, 53],
    [255, 127, 0],
    [255, 212, 170],
    [189, 94, 0],
    [189, 157, 126],
    [129, 64, 0],
    [129, 107, 86],
    [104, 52, 0],
    [104, 86, 69],
    [79, 39, 0],
    [79, 66, 53],
    [255, 191, 0],
    [255, 234, 170],
    [189, 141, 0],
    [189, 173, 126],
    [129, 96, 0],
    [129, 118, 86],
    [104, 78, 0],
    [104, 95, 69],
    [79, 59, 0],
    [79, 73, 53],
    [255, 255, 0],
    [255, 255, 170],
    [189, 189, 0],
    [189, 189, 126],
    [129, 129, 0],
    [129, 129, 86],
    [104, 104, 0],
    [104, 104, 69],
    [79, 79, 0],
    [79, 79, 53],
    [191, 255, 0],
    [234, 255, 170],
    [141, 189, 0],
    [173, 189, 126],
    [96, 129, 0],
    [118, 129, 86],
    [78, 104, 0],
    [95, 104, 69],
    [59, 79, 0],
    [73, 79, 53],
    [127, 255, 0],
    [212, 255, 170],
    [94, 189, 0],
    [157, 189, 126],
    [64, 129, 0],
    [107, 129, 86],
    [52, 104, 0],
    [86, 104, 69],
    [39, 79, 0],
    [66, 79, 53],
    [63, 255, 0],
    [191, 255, 170],
    [46, 189, 0],
    [141, 189, 126],
    [31, 129, 0],
    [96, 129, 86],
    [25, 104, 0],
    [78, 104, 69],
    [19, 79, 0],
    [59, 79, 53],
    [0, 255, 0],
    [170, 255, 170],
    [0, 189, 0],
    [126, 189, 126],
    [0, 129, 0],
    [86, 129, 86],
    [0, 104, 0],
    [69, 104, 69],
    [0, 79, 0],
    [53, 79, 53],
    [0, 255, 63],
    [170, 255, 191],
    [0, 189, 46],
    [126, 189, 141],
    [0, 129, 31],
    [86, 129, 96],
    [0, 104, 25],
    [69, 104, 78],
    [0, 79, 19],
    [53, 79, 59],
    [0, 255, 127],
    [170, 255, 212],
    [0, 189, 94],
    [126, 189, 157],
    [0, 129, 64],
    [86, 129, 107],
    [0, 104, 52],
    [69, 104, 86],
    [0, 79, 39],
    [53, 79, 66],
    [0, 255, 191],
    [170, 255, 234],
    [0, 189, 141],
    [126, 189, 173],
    [0, 129, 96],
    [86, 129, 118],
    [0, 104, 78],
    [69, 104, 95],
    [0, 79, 59],
    [53, 79, 73],
    [0, 255, 255],
    [170, 255, 255],
    [0, 189, 189],
    [126, 189, 189],
    [0, 129, 129],
    [86, 129, 129],
    [0, 104, 104],
    [69, 104, 104],
    [0, 79, 79],
    [53, 79, 79],
    [0, 191, 255],
    [170, 234, 255],
    [0, 141, 189],
    [126, 173, 189],
    [0, 96, 129],
    [86, 118, 129],
    [0, 78, 104],
    [69, 95, 104],
    [0, 59, 79],
    [53, 73, 79],
    [0, 127, 255],
    [170, 212, 255],
    [0, 94, 189],
    [126, 157, 189],
    [0, 64, 129],
    [86, 107, 129],
    [0, 52, 104],
    [69, 86, 104],
    [0, 39, 79],
    [53, 66, 79],
    [0, 63, 255],
    [170, 191, 255],
    [0, 46, 189],
    [126, 141, 189],
    [0, 31, 129],
    [86, 96, 129],
    [0, 25, 104],
    [69, 78, 104],
    [0, 19, 79],
    [53, 59, 79],
    [0, 0, 255],
    [170, 170, 255],
    [0, 0, 189],
    [126, 126, 189],
    [0, 0, 129],
    [86, 86, 129],
    [0, 0, 104],
    [69, 69, 104],
    [0, 0, 79],
    [53, 53, 79],
    [63, 0, 255],
    [191, 170, 255],
    [46, 0, 189],
    [141, 126, 189],
    [31, 0, 129],
    [96, 86, 129],
    [25, 0, 104],
    [78, 69, 104],
    [19, 0, 79],
    [59, 53, 79],
    [127, 0, 255],
    [212, 170, 255],
    [94, 0, 189],
    [157, 126, 189],
    [64, 0, 129],
    [107, 86, 129],
    [52, 0, 104],
    [86, 69, 104],
    [39, 0, 79],
    [66, 53, 79],
    [191, 0, 255],
    [234, 170, 255],
    [141, 0, 189],
    [173, 126, 189],
    [96, 0, 129],
    [118, 86, 129],
    [78, 0, 104],
    [95, 69, 104],
    [59, 0, 79],
    [73, 53, 79],
    [255, 0, 255],
    [255, 170, 255],
    [189, 0, 189],
    [189, 126, 189],
    [129, 0, 129],
    [129, 86, 129],
    [104, 0, 104],
    [104, 69, 104],
    [79, 0, 79],
    [79, 53, 79],
    [255, 0, 191],
    [255, 170, 234],
    [189, 0, 141],
    [189, 126, 173],
    [129, 0, 96],
    [129, 86, 118],
    [104, 0, 78],
    [104, 69, 95],
    [79, 0, 59],
    [79, 53, 73],
    [255, 0, 127],
    [255, 170, 212],
    [189, 0, 94],
    [189, 126, 157],
    [129, 0, 64],
    [129, 86, 107],
    [104, 0, 52],
    [104, 69, 86],
    [79, 0, 39],
    [79, 53, 66],
    [255, 0, 63],
    [255, 170, 191],
    [189, 0, 46],
    [189, 126, 141],
    [129, 0, 31],
    [129, 86, 96],
    [104, 0, 25],
    [104, 69, 78],
    [79, 0, 19],
    [79, 53, 59],
    [51, 51, 51],
    [80, 80, 80],
    [105, 105, 105],
    [130, 130, 130],
    [190, 190, 190],
    [255, 255, 255],
];

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_a_triangle_and_a_quad() {
        // A red triangle (v1==v4) and a green quad.
        let dxf = "\
0\nSECTION\n2\nENTITIES\n\
0\n3DFACE\n8\ndefault\n62\n1\n\
10\n0\n20\n0\n30\n0\n\
11\n1\n21\n0\n31\n0\n\
12\n0\n22\n1\n32\n0\n\
13\n0\n23\n0\n33\n0\n\
0\n3DFACE\n8\ndefault\n62\n3\n\
10\n0\n20\n0\n30\n0\n\
11\n1\n21\n0\n31\n0\n\
12\n1\n22\n1\n32\n0\n\
13\n0\n23\n1\n33\n0\n\
0\nENDSEC\n0\nEOF\n";
        let m = parse_dxf(dxf);
        // triangle = 1 tri, quad = 2 tris => 3 triangles => 9 vertices.
        assert_eq!(m.triangles(), 3);
        assert_eq!(m.positions.len(), 27);
        assert_eq!(m.colors.len(), 27);
        // first face is ACI 1 = pure red.
        assert_eq!(&m.colors[0..3], &[1.0, 0.0, 0.0]);
        // second face is ACI 3 = pure green.
        assert_eq!(&m.colors[9..12], &[0.0, 1.0, 0.0]);
    }
}
