// Animated raymarched gyroid with a cosine colour palette and volumetric glow.
// Geometry-free: a full-screen triangle plus all the work in the fragment shader.

struct Uniforms {
    time: f32,
    width: f32,
    height: f32,
    pad: f32,
};

@group(0) @binding(0)
var<uniform> u: Uniforms;

// Full-screen triangle: three vertices covering the viewport, no vertex buffer.
@vertex
fn vs_main(@builtin(vertex_index) vi: u32) -> @builtin(position) vec4<f32> {
    let p = vec2<f32>(f32((vi << 1u) & 2u), f32(vi & 2u)); // (0,0), (2,0), (0,2)
    return vec4<f32>(p * 2.0 - 1.0, 0.0, 1.0);             // (-1,-1), (3,-1), (-1,3)
}

// Inigo Quilez cosine palette.
fn palette(t: f32) -> vec3<f32> {
    let a = vec3<f32>(0.5, 0.5, 0.5);
    let b = vec3<f32>(0.5, 0.5, 0.5);
    let c = vec3<f32>(1.0, 1.0, 1.0);
    let d = vec3<f32>(0.0, 0.33, 0.67);
    return a + b * cos(6.28318 * (c * t + d));
}

fn rot_y(p: vec3<f32>, a: f32) -> vec3<f32> {
    let s = sin(a);
    let c = cos(a);
    return vec3<f32>(c * p.x + s * p.z, p.y, -s * p.x + c * p.z);
}

// Gyroid field. Not a strict distance function, so it is scaled down to keep the
// sphere-tracing stable.
fn map(p: vec3<f32>) -> f32 {
    let g = dot(sin(p), cos(p.zxy));
    return (abs(g) - 0.3) * 0.5;
}

@fragment
fn fs_main(@builtin(position) frag: vec4<f32>) -> @location(0) vec4<f32> {
    let res = vec2<f32>(u.width, u.height);
    var uv = (frag.xy * 2.0 - res) / min(res.x, res.y);
    uv.y = -uv.y;

    let t = u.time;
    let ro = vec3<f32>(0.0, 0.0, t * 1.2);          // fly forward through the field
    let rd = normalize(vec3<f32>(uv, 1.4));

    var dist = 0.0;
    var glow = 0.0;
    for (var i = 0; i < 90; i = i + 1) {
        var p = ro + rd * dist;
        p = rot_y(p, t * 0.15 + dist * 0.04);       // slow swirl + a twist with depth
        let d = map(p);
        glow = glow + 0.018 / (0.012 + d * d);      // accumulate volumetric glow
        if (d < 0.001 || dist > 24.0) {
            break;
        }
        dist = dist + max(d, 0.02);
    }

    var col = palette(dist * 0.06 + t * 0.05) * glow * 0.05;
    col = col / (col + vec3<f32>(1.0));             // Reinhard tone map
    col = pow(col, vec3<f32>(0.4545));              // gamma
    return vec4<f32>(col, 1.0);
}
