//! Port of csv-compare's `Rectangle.cs`, the algorithm it uses by default:
//! a rectangle of half-width `size.x` and half-height `size.y` around every
//! reference point, and the tube curves run above / below all of them.
//!
//! Only the lower tube is implemented -- `Rectangle.cs`'s two halves are exact
//! mirrors, since corner choice, the dedup test and every comparison in
//! `RemoveLoop` all invert under `y -> -y`.

use crate::Curve;
use crate::tube_size::TubeSize;

/// The tube polylines. Their x is the reference's shifted by `±size.x`, so they
/// are not on the reference timeline.
pub fn rectangle_tube(x: &[f64], y: &[f64], size: &TubeSize) -> (Curve, Curve) {
    let lower = lower_tube(x, y, size);
    let negated: Vec<f64> = y.iter().map(|v| -v).collect();
    let mut upper = lower_tube(x, &negated, size);
    for v in &mut upper.y {
        *v = -*v;
    }
    (lower, upper)
}

/// `CalculateLower`: the rectangle corners, then `RemoveLoop` and
/// `FixBoundaries`.
fn lower_tube(x: &[f64], y: &[f64], size: &TubeSize) -> Curve {
    let n = x.len();
    let (sx, sy) = (size.x, size.y);
    let mut lx: Vec<f64> = Vec::with_capacity(2 * n);
    let mut ly: Vec<f64> = Vec::with_capacity(2 * n);

    // ignore identical points at the beginning
    let mut b = 0usize;
    while b + 1 < n && x[b] == x[b + 1] && y[b] == y[b + 1] {
        b += 1;
    }

    lx.push(x[b] - sx);
    ly.push(y[b] - sy);

    if b + 1 < n {
        let mut s0 = signum(y[b + 1] - y[b]);
        let mut m0 = slope(x[b], y[b], x[b + 1], y[b + 1], s0);

        if s0 == 1 {
            lx.push(x[b] + sx);
            ly.push(y[b] - sy);
        }

        for i in b + 1..n - 1 {
            if x[i] == x[i + 1] && y[i] == y[i + 1] {
                continue;
            }
            let s1 = signum(y[i + 1] - y[i]);
            let m1 = slope(x[i], y[i], x[i + 1], y[i + 1], s1);

            // no point for equal slopes of the reference curve
            if m0 != m1 {
                let mut corner = |dx: f64| {
                    lx.push(x[i] + dx);
                    ly.push(y[i] - sy);
                };
                if s0 != -1 && s1 != -1 {
                    corner(sx);
                } else if s0 != 1 && s1 != 1 {
                    corner(-sx);
                } else if s0 == -1 && s1 == 1 {
                    corner(-sx);
                    corner(sx);
                } else if s0 == 1 && s1 == -1 {
                    corner(sx);
                    corner(-sx);
                }
                // remove the points just added where the tube slope is zero
                let last = ly.len() - 1;
                if y[i + 1] - sy == ly[last] {
                    if s0 * s1 == -1 && last >= 2 && ly[last - 2] == ly[last] {
                        lx.truncate(last - 1);
                        ly.truncate(last - 1);
                    } else if s0 * s1 != -1 && last >= 1 && ly[last - 1] == ly[last] {
                        lx.truncate(last);
                        ly.truncate(last);
                    }
                }
            }
            s0 = s1;
            m0 = m1;
        }
        if s0 == -1 {
            lx.push(x[n - 1] - sx);
            ly.push(y[n - 1] - sy);
        }
    }

    lx.push(x[n - 1] + sx);
    ly.push(y[n - 1] - sy);

    remove_loop(&mut lx, &mut ly);
    fix_boundaries(&mut lx, &mut ly, x[0], x[n - 1]);

    Curve { x: lx, y: ly }
}

fn signum(d: f64) -> i32 {
    if d > 0.0 {
        1
    } else if d < 0.0 {
        -1
    } else {
        0
    }
}

fn slope(x0: f64, y0: f64, x1: f64, y1: f64, s: i32) -> f64 {
    if x1 != x0 {
        (y1 - y0) / (x1 - x0)
    } else if s > 0 {
        f64::INFINITY
    } else {
        f64::NEG_INFINITY
    }
}

/// `RemoveLoop`: where the corner polyline runs backwards it self-intersects,
/// and the loop becomes its intersection point. The `i > 1` / `i + 1 < len`
/// bounds are ours; the C# reads out of range there.
fn remove_loop(x: &mut Vec<f64>, y: &mut Vec<f64>) {
    let mut j = 1usize;
    while j + 2 < x.len() {
        if x[j + 1] < x[j] {
            // 1. find i,k with i <= j < j+1 <= k-1 where (i-1,i) crosses (k-1,k)
            let mut i = j;
            let mut i_previous = i;
            while i > 1 && x[j + 1] < x[i - 1] {
                i -= 1;
            }

            let mut k_max = j + 1;
            while x[k_max] < x[j] && k_max + 1 < y.len() {
                k_max += 1;
            }

            let mut k = j + 1;
            let mut yi = y[i - 1];
            while yi < y[k] && k < k_max {
                i_previous = i;
                k += 1;
                while i < j
                    && (x[i] < x[k]
                        || (x[i] == x[k]
                            && y[i] < y[k]
                            && !(k + 1 < x.len() && x[k] == x[k + 1] && y[k + 1] < y[k])))
                {
                    i += 1;
                }
                yi = interpolate_on(x, y, i, x[k]);
            }
            // k located; i is somewhere on the polyline (i_previous - 1, i)
            i = if i_previous > 1 { i_previous - 1 } else { i_previous };
            if x[k] != x[k - 1] {
                yi = interpolate_on(x, y, k, x[i]);
            }
            while i + 1 < x.len()
                && ((x[k] != x[k - 1] && y[i] < yi) || (x[k] == x[k - 1] && x[i] < x[k]))
            {
                i += 1;
                if x[k] != x[k - 1] {
                    yi = interpolate_on(x, y, k, x[i]);
                }
            }

            // By construction i <= j < j+1 <= k-1. Where that breaks down,
            // removing nothing while `j` moves back to `i` would not terminate.
            if k <= i {
                j += 1;
                continue;
            }

            // 2. intersection point of (i-1,i) and (k-1,k)
            let mut add_point = true;
            let (mut ix, mut iy) = (0.0, 0.0);
            if x[i] == x[i - 1] && x[k] == x[k - 1] {
                add_point = false; // both branches vertical
            } else if x[i] == x[i - 1] {
                ix = x[i];
                iy = y[k - 1] + (x[i] - x[k - 1]) * (y[k] - y[k - 1]) / (x[k] - x[k - 1]);
            } else if x[k] == x[k - 1] {
                ix = x[k];
                iy = y[i - 1] + (x[k] - x[i - 1]) * (y[i] - y[i - 1]) / (x[i] - x[i - 1]);
            } else {
                let a1 = (y[i] - y[i - 1]) / (x[i] - x[i - 1]);
                let a2 = (y[k] - y[k - 1]) / (x[k] - x[k - 1]);
                if a1 != a2 {
                    ix = (a1 * x[i - 1] - a2 * x[k - 1] - y[i - 1] + y[k - 1]) / (a1 - a2);
                    iy = if a1.abs() > a2.abs() {
                        a2 * (ix - x[k - 1]) + y[k - 1]
                    } else {
                        a1 * (ix - x[i - 1]) + y[i - 1]
                    };
                } else {
                    add_point = false;
                }
            }

            // 3. delete points i up to and including k-1
            if k > i {
                x.drain(i..k);
                y.drain(i..k);
            }
            // 4. add the intersection point unless it is already there
            if add_point && (i >= x.len() || x[i] != ix || y[i] != iy) {
                x.insert(i, ix);
                y.insert(i, iy);
            }
            // 5./6. continue from i, dropping a doubled point
            j = i;
            if i >= 1 && i < x.len() && x[i - 1] == x[i] && y[i - 1] == y[i] {
                x.remove(i);
                y.remove(i);
                j = i - 1;
            }
        }
        j += 1;
    }
}

/// The tube's own segment `(idx-1, idx)`, interpolated at `at`.
fn interpolate_on(x: &[f64], y: &[f64], idx: usize, at: f64) -> f64 {
    if x[idx] == x[idx - 1] {
        y[idx]
    } else {
        (y[idx] - y[idx - 1]) / (x[idx] - x[idx - 1]) * (at - x[idx - 1]) + y[idx - 1]
    }
}

/// `FixBoundaries`: clip the tube to the reference's time span.
fn fix_boundaries(x: &mut Vec<f64>, y: &mut Vec<f64>, start: f64, stop: f64) {
    while !x.is_empty() && x[0] < start {
        if x.len() > 1 && x[1] >= start {
            y[0] += (y[1] - y[0]) * (start - x[0]) / (x[1] - x[0]);
            x[0] = start;
        } else {
            x.remove(0);
            y.remove(0);
        }
    }
    while !x.is_empty() && x[x.len() - 1] > stop {
        let last = x.len() - 1;
        if last >= 1 && x[last - 1] <= stop {
            y[last] -= (y[last] - y[last - 1]) * (x[last] - stop) / (x[last] - x[last - 1]);
            x[last] = stop;
        } else {
            x.pop();
            y.pop();
        }
    }
}
