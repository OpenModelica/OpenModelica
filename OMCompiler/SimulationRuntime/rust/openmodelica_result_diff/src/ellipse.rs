//! Port of csv-compare's current `Ellipse.cs` (2014-12-04, still maintained):
//! around every reference point sits an ellipse of half-width `size.x`, and the
//! tube curves are the envelopes above / below all of them.
//!
//! It shares [`crate::tubes`] with [`crate::ellipse2014`], the version
//! OpenModelica ported. What changed since: the slope scale `S` and the tube
//! width come from a different formula (the one OpenModelica uses is the line
//! commented out at `Ellipse.cs:140`), a jump in the reference curve gets its own
//! first-interval and terminal geometry, and the consolidation loop reaches the
//! first interval.

use crate::Curve;
use crate::tube_size::TubeSize;
use crate::tubes::Tubes;

/// `Ellipse.Calculate`: the lower and upper tube polylines around `(x, y)`.
/// `x` is adjusted in place to stay strictly increasing, as the C# rewrites its
/// copy of the reference time.
pub fn ellipse_tube(x: &mut [f64], y: &[f64], size: &TubeSize) -> (Curve, Curve) {
    let length = x.len();
    // The jump branch appends two intervals in one iteration and the terminal
    // value another two.
    let cap = length + 4;
    let mut p = Tubes {
        mh: vec![0.0; cap],
        ml: vec![0.0; cap],
        x_high: vec![0.0; cap],
        x_low: vec![0.0; cap],
        y_high: vec![0.0; cap],
        y_low: vec![0.0; cap],
        i0h: vec![0; cap],
        i1h: vec![0; cap],
        i0l: vec![0; cap],
        i1l: vec![0; cap],
        t_start: x[0],
        t_stop: x[length - 1],
        x1: 0.0,
        y1: 0.0,
        x2: 0.0,
        y2: 0.0,
        current_slope: 0.0,
        slope_dif: 0.0,
        delta: size.x,
        s: 0.0,
        x_rel_eps: 1e-15,
        x_min_step: 0.0,
        min: y[0],
        max: y[0],
        count_low: 0,
        count_high: 0,
        min_index: 1,
    };
    p.x_min_step = ((p.t_stop - p.t_start) + p.t_start.abs()) * p.x_rel_eps;

    for i in 1..length {
        p.max = y[i].max(p.max);
        p.min = y[i].min(p.min);
    }
    let span = (p.t_stop - p.t_start).abs() + p.t_start.abs();
    p.s = ((p.max - p.min).abs() + p.min.abs()) / span;
    if p.s < 0.0004 / span {
        p.s = 0.0004 / span;
    }

    let mut jump = false;
    for i in 1..length {
        p.x1 = x[i];
        p.y1 = y[i];
        p.x2 = x[i - 1];
        p.y2 = y[i - 1];

        // catch jumps
        jump = false;
        if p.x1 <= p.x2 && p.y1 == p.y2 && p.count_high == 0 {
            continue;
        }
        if p.x1 <= p.x2 && p.y1 == p.y2 {
            p.x1 = p.x1.max(x[p.i1l[p.count_low - 1] as usize] + p.x_min_step);
            p.x1 = p.x1.max(x[p.i1h[p.count_high - 1] as usize] + p.x_min_step);
            x[i] = p.x1;
            p.current_slope = p.mh[p.count_high - 1];
        } else {
            if p.x1 <= p.x2 {
                jump = true;
                p.x1 = p.x2 + p.x_min_step;
                x[i] = p.x1;
            }
            p.current_slope = (p.y1 - p.y2) / (p.x1 - p.x2);
        }

        p.i0h[p.count_high] = i as i64;
        p.i1h[p.count_high] = (i - 1) as i64;
        p.mh[p.count_high] = p.current_slope;

        p.i0l[p.count_low] = i as i64;
        p.i1l[p.count_low] = (i - 1) as i64;
        if p.x1 <= p.x2 && p.y1 == p.y2 {
            p.current_slope = p.ml[p.count_low - 1];
        }
        p.ml[p.count_low] = p.current_slope;

        if p.count_high == 0 {
            let m = p.current_slope;
            let root = (m * m + p.s * p.s).sqrt();
            if jump {
                // The interval before the jump becomes a flat one, and the jump
                // itself gets an interval of its own.
                p.i0h[0] = (i - 1) as i64;
                p.mh[0] = 0.0;
                p.x_high[0] = p.x2 - p.delta - p.x_min_step;
                p.y_high[0] = p.y2 + p.delta * p.s;
                p.i0h[1] = i as i64;
                p.i1h[1] = (i - 1) as i64;
                p.mh[1] = m;
                p.x_high[1] = p.x2 - p.delta * m / (p.s + root);
                p.y_high[1] = p.y2 + p.delta * p.s;
                p.count_high = 2;

                p.i0l[0] = (i - 1) as i64;
                p.ml[0] = 0.0;
                p.x_low[0] = p.x2 - p.delta - p.x_min_step;
                p.y_low[0] = p.y2 - p.delta * p.s;
                p.i0l[1] = i as i64;
                p.i1l[1] = (i - 1) as i64;
                p.ml[1] = m;
                p.x_low[1] = p.x2 + p.delta * m / (p.s + root);
                p.y_low[1] = p.y2 - p.delta * p.s;
                p.count_low = 2;
            } else {
                p.x_high[0] = p.x2 - p.delta;
                p.y_high[0] = p.y2 - m * p.delta + p.delta * root;
                p.x_low[0] = p.x2 - p.delta;
                p.y_low[0] = p.y2 - m * p.delta - p.delta * root;
                p.count_high = 1;
                p.count_low = 1;
            }
        } else {
            p.x_high[p.count_high] = 1.0;
            p.y_high[p.count_high] = 1.0;
            p.x_low[p.count_low] = 1.0;
            p.y_low[p.count_low] = 1.0;
            p.count_high += 1;
            p.count_low += 1;
            p.generate_high_tube(x, y);
            p.generate_low_tube(x, y);
        }
    }

    // A single sample, or time that never advances: every iteration above took
    // the jump-continue and no interval was created, which is where the C#
    // indexes an empty list. Seed a flat tube at the first sample instead.
    if p.count_high == 0 {
        p.mh[0] = 0.0;
        p.ml[0] = 0.0;
        p.x_high[0] = x[0] - p.delta;
        p.y_high[0] = y[0] + p.delta * p.s;
        p.x_low[0] = x[0] - p.delta;
        p.y_low[0] = y[0] - p.delta * p.s;
        p.count_high = 1;
        p.count_low = 1;
    }

    // terminal value
    p.x2 = x[length - 1];
    if jump {
        p.y2 = y[length - 1];

        let m = p.mh[p.count_high - 1];
        p.x_high[p.count_high] = p.x2 - p.delta * m / (p.s + (m * m + p.s * p.s).sqrt());
        p.y_high[p.count_high] = p.y2 + p.delta * p.s;
        p.x_high[p.count_high + 1] = p.x2 + p.delta + p.x_min_step;
        p.y_high[p.count_high + 1] = p.y2 + p.delta * p.s;
        p.count_high += 2;

        let m = p.ml[p.count_low - 1];
        p.x_low[p.count_low] = p.x2 + p.delta * m / (p.s + (m * m + p.s * p.s).sqrt());
        p.y_low[p.count_low] = p.y2 - p.delta * p.s;
        p.x_low[p.count_low + 1] = p.x2 + p.delta + p.x_min_step;
        p.y_low[p.count_low + 1] = p.y2 - p.delta * p.s;
        p.count_low += 2;
    } else {
        p.x1 = p.x_high[p.count_high - 1];
        p.y1 = p.y_high[p.count_high - 1];
        p.current_slope = p.mh[p.count_high - 1];
        p.x_high[p.count_high] = p.x2 + p.delta;
        p.y_high[p.count_high] = p.y1 + p.current_slope * (p.x2 + p.delta - p.x1);
        p.count_high += 1;

        p.x1 = p.x_low[p.count_low - 1];
        p.y1 = p.y_low[p.count_low - 1];
        p.current_slope = p.ml[p.count_low - 1];
        p.x_low[p.count_low] = p.x2 + p.delta;
        p.y_low[p.count_low] = p.y1 + p.current_slope * (p.x2 + p.delta - p.x1);
        p.count_low += 1;
    }

    p.x_low.truncate(p.count_low);
    p.y_low.truncate(p.count_low);
    p.x_high.truncate(p.count_high);
    p.y_high.truncate(p.count_high);
    (Curve { x: p.x_low, y: p.y_low }, Curve { x: p.x_high, y: p.y_high })
}
