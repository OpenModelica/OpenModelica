//! `ellipse2014`: the tube comparison `diffSimulationResults` runs, ported from
//! `SimulationResultsCmpTubes.c` -- itself a port of ITI's 2014 `Ellipse.cs`.
//! A tolerance tube is built around the reference signal and the actual signal,
//! resampled onto the reference timeline, has to stay inside it. Unlike
//! csv-compare's own algorithms this widens the tube by a relative tolerance and
//! treats event points specially; see [`crate::Algorithm`]. The default
//! `rangeDelta` is non-zero, so the full `calculateTubes` geometry runs.

use crate::tubes::Tubes;

// almostEqualRelativeAndAbs default tolerances (SimulationResultsCmp.c).
pub const DOUBLEEQUAL_TOTAL: f64 = 0.0000000001;
pub const DOUBLEEQUAL_REL: f64 = 0.00001;

/// C `almostEqualRelativeAndAbs`.
pub fn almost_equal_rel_abs(a: f64, b: f64, reltol: f64, abstol: f64) -> bool {
    let diff = (a - b).abs();
    diff <= abstol || diff <= a.abs().max(b.abs()) * reltol
}

/// C `almostEqualWithDefaultTolerance`.
pub fn almost_equal_default(a: f64, b: f64) -> bool {
    almost_equal_rel_abs(a, b, DOUBLEEQUAL_REL, DOUBLEEQUAL_TOTAL)
}

/// C `calculateTubes`: build the upper/lower tolerance tube around `(x,y)`.
/// `x` (the reference timeline) is adjusted in place to keep it strictly
/// increasing, exactly as the C code mutates `ref.time`.
fn calculate_tubes(x: &mut [f64], y: &[f64], length: usize, r: f64) -> Tubes {
    let cap = length + 1;
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
        delta: 0.0,
        s: 0.0,
        x_rel_eps: 1e-15,
        x_min_step: 0.0,
        min: y[0],
        max: y[0],
        count_low: 0,
        count_high: 0,
        min_index: 2,
    };
    p.x_min_step = ((p.t_stop - p.t_start) + p.t_start.abs()) * p.x_rel_eps;
    p.delta = r * (p.t_stop - p.t_start);

    for i in 1..length {
        p.max = y[i].max(p.max);
        p.min = y[i].min(p.min);
    }
    p.s = (4.0 * (p.max - p.min) / (p.t_stop - p.t_start).abs()).abs();
    if p.s < 0.0004 / (p.t_stop - p.t_start).abs() {
        p.s = 0.0004 / (p.t_stop - p.t_start).abs();
    }

    for i in 1..length {
        p.x1 = x[i];
        p.y1 = y[i];
        p.x2 = x[i - 1];
        p.y2 = y[i - 1];
        // catch jumps
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
            p.x_high[p.count_high] = p.x2 - p.delta;
            p.y_high[p.count_high] = p.y2 - p.current_slope * p.delta
                + p.delta * (p.current_slope * p.current_slope + p.s * p.s).sqrt();
            p.x_low[p.count_low] = p.x2 - p.delta;
            p.y_low[p.count_low] = p.y2 - p.current_slope * p.delta
                - p.delta * (p.current_slope * p.current_slope + p.s * p.s).sqrt();
            p.count_high += 1;
            p.count_low += 1;
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

    // Degenerate series — a single sample, or time that never advances (a
    // start == stop run like the ModelicaTest function tests with
    // stopTime=0.0 produces the time column {0.0, 0.0}): every iteration
    // above took the jump-continue, no segment was created, and the
    // terminal extension below would index count-1 with count == 0 (the C
    // original, SimulationResultsCmpTubes.c, reads out of bounds here).
    // Seed a flat zero-slope tube at the first sample instead; the relative
    // tolerance the caller adds then makes the comparison pointwise.
    if p.count_high == 0 {
        p.mh[0] = 0.0;
        p.ml[0] = 0.0;
        p.x_high[0] = x[0] - p.delta;
        p.y_high[0] = y[0];
        p.x_low[0] = x[0] - p.delta;
        p.y_low[0] = y[0];
        p.count_high = 1;
        p.count_low = 1;
    }

    // terminal value, upper tube
    p.x1 = p.x_high[p.count_high - 1];
    p.y1 = p.y_high[p.count_high - 1];
    p.x2 = p.t_stop;
    p.current_slope = p.mh[p.count_high - 1];
    p.x_high[p.count_high] = p.x2 + p.delta;
    p.y_high[p.count_high] = p.y1 + p.current_slope * (p.x2 + p.delta - p.x1);
    p.count_high += 1;

    // terminal value, lower tube
    p.x1 = p.x_low[p.count_low - 1];
    p.y1 = p.y_low[p.count_low - 1];
    p.x2 = p.t_stop;
    p.current_slope = p.ml[p.count_low - 1];
    p.x_low[p.count_low] = p.x2 + p.delta;
    p.y_low[p.count_low] = p.y1 + p.current_slope * (p.x2 + p.delta - p.x1);
    p.count_low += 1;

    p
}

/// C `linearInterpolation` (with the x-abs-tol NaN guards).
fn linear_interpolation(x: f64, x0: f64, x1: f64, y0: f64, y1: f64, xabstol: f64) -> f64 {
    if almost_equal_rel_abs(x0, x, 0.0, xabstol) {
        y0
    } else if almost_equal_rel_abs(x1, x, 0.0, xabstol) {
        y1
    } else if almost_equal_rel_abs(x1, x0, 0.0, xabstol) {
        y0
    } else {
        y0 + ((y1 - y0) / (x1 - x0)) * (x - x0)
    }
}

/// C `calibrateValues`: resample `(target_time, target_values)` onto the
/// `source_time` timeline. `nsource` may be shrunk to avoid extrapolation.
fn calibrate_values(
    source_time: &[f64],
    target_time: &[f64],
    target_values: &[f64],
    nsource: &mut usize,
    ntarget: usize,
    xabstol: f64,
) -> Vec<f64> {
    let n = *nsource;
    let mut out = vec![0.0; n];
    let (mut x0, mut x1, mut y0, mut y1) = (0.0, 0.0, 0.0, 0.0);
    let mut j = 1usize;
    for i in 0..n {
        let x = source_time[i];
        if target_time[j] > source_time[n - 1] && target_time[j - 1] > source_time[n - 1] {
            out[i] = linear_interpolation(x, x0, x1, y0, y1, xabstol);
            *nsource = i + 1;
            break;
        }
        x1 = target_time[j];
        y1 = target_values[j];
        while x1 <= x && (j + 1) < ntarget {
            j += 1;
            x1 = target_time[j];
            y1 = target_values[j];
            if almost_equal_rel_abs(x1, x, 0.0, xabstol) {
                break;
            }
        }
        x0 = target_time[j - 1];
        y0 = target_values[j - 1];
        if i > 0
            && almost_equal_rel_abs(source_time[i - 1], x0, 0.0, xabstol)
            && almost_equal_rel_abs(x0, x1, 0.0, xabstol)
        {
            out[i] = y1;
        } else {
            out[i] = linear_interpolation(x, x0, x1, y0, y1, xabstol);
        }
    }
    out
}

/// C `addRelativeTolerance`: widen the tube by a relative+absolute margin.
fn add_relative_tolerance(target: &mut [f64], source: &[f64], length: usize, reltol: f64, abstol: f64, direction: i32) {
    if direction > 0 {
        for i in 0..length {
            target[i] = (source[i] + (source[i] * reltol).abs().max(abstol)).max(target[i]);
        }
    } else {
        for i in 0..length {
            target[i] = (source[i] - (source[i] * reltol).abs().max(abstol)).min(target[i]);
        }
    }
}

/// C `validate`: returns the per-point error vector if the actual signal leaves
/// the tube anywhere, or `None` when it stays inside. Adjusts `low`/`high` at
/// event points (as the C code does in place).
fn validate(
    n: usize,
    ref_time: &[f64],
    ref_values: &[f64],
    low: &mut [f64],
    high: &mut [f64],
    calibrated_values: &[f64],
    reltol: f64,
    abstol: f64,
    xabstol: f64,
) -> Option<Vec<f64>> {
    let mut error = vec![0.0; n];
    let mut isdifferent = 0u32;
    let mut last_step_error = true;
    for i in 0..n {
        let mut this_step_error = false;
        let is_event = (i > 0 && almost_equal_rel_abs(ref_time[i], ref_time[i - 1], 0.0, xabstol))
            || (i + 1 < n && almost_equal_rel_abs(ref_time[i], ref_time[i + 1], 0.0, xabstol));
        if is_event {
            let refv = ref_values[i];
            let val = calibrated_values[i];
            let tol = (abstol * 10.0).max(refv.abs().max(val.abs()) * reltol * 10.0);
            high[i] = (if last_step_error { refv } else { refv.max(val) }) + tol;
            low[i] = (if last_step_error { refv } else { refv.min(val) }) - tol;
            error[i] = f64::NAN;
        } else {
            error[i] = 0.0;
            this_step_error = last_step_error;
            if calibrated_values[i] < low[i] {
                error[i] = low[i] - calibrated_values[i];
                isdifferent += 1;
                this_step_error = true;
            } else if calibrated_values[i] > high[i] {
                error[i] = calibrated_values[i] - high[i];
                isdifferent += 1;
                this_step_error = true;
            }
        }
        last_step_error = this_step_error;
    }
    if isdifferent > 0 {
        Some(error)
    } else {
        None
    }
}

/// The outcome of [`cmp_data_tubes`] for one variable: everything on the
/// reference timeline (`n` points of it), `error` only when the signal left the
/// tube. `abstol` is the absolute tolerance the tube was widened by.
pub struct TubeCmp {
    pub calibrated: Vec<f64>,
    pub high: Vec<f64>,
    pub low: Vec<f64>,
    pub error: Option<Vec<f64>>,
    pub n: usize,
    pub abstol: f64,
}

impl TubeCmp {
    pub fn differs(&self) -> bool {
        self.error.is_some()
    }
}

/// C `cmpDataTubes` for the `isResultCmp=0` path. `time`/`data` are the actual
/// trajectory, `reftime`/`refdata` the reference (mutated in place by the tube
/// construction, as in the C code).
pub fn cmp_data_tubes(
    time: &[f64],
    reftime: &mut [f64],
    refdata: &[f64],
    data: &[f64],
    reltol: f64,
    range_delta: f64,
    reltol_diff_max_min: f64,
) -> TubeCmp {
    let with_tubes = range_delta == 0.0;
    let ref_size = reftime.len();
    let xabstol = (reftime[ref_size - 1] - reftime[0])
        * (if with_tubes { range_delta } else { 1e-3 })
        / (time.len().max(ref_size) as f64);

    // Only the (default) non-zero rangeDelta path is exercised; build the tube.
    let priv_ = calculate_tubes(reftime, refdata, ref_size, range_delta);

    let mut n = ref_size;
    let calibrated_values =
        calibrate_values(reftime, time, data, &mut n, time.len(), xabstol);
    let mut high = calibrate_values(reftime, &priv_.x_high, &priv_.y_high, &mut n, priv_.count_high, xabstol);
    let mut low = calibrate_values(reftime, &priv_.x_low, &priv_.y_low, &mut n, priv_.count_low, xabstol);

    let abstol = if priv_.max - priv_.min == 0.0 && priv_.max < reltol_diff_max_min * reltol_diff_max_min {
        reltol_diff_max_min * reltol_diff_max_min
    } else {
        ((priv_.max - priv_.min) * reltol_diff_max_min).abs()
    };
    add_relative_tolerance(&mut high, refdata, n, reltol, abstol, 1);
    add_relative_tolerance(&mut low, refdata, n, reltol, abstol, -1);

    let error = validate(n, reftime, refdata, &mut low, &mut high, &calibrated_values, reltol, abstol, xabstol);
    TubeCmp { calibrated: calibrated_values, high, low, error, n, abstol }
}
