//! Tube-based result comparison, the port of `SimulationResultsCmpTubes.c`:
//! `diffSimulationResults` builds a tolerance "tube" around the reference signal
//! (the CSV-compare algorithm from ITI's Tubes.cs) and checks that the actual
//! signal, resampled onto the reference timeline, stays inside it. The default
//! `rangeDelta` is non-zero, so the full `calculateTubes` geometry runs.

pub fn format_g(x: f64) -> String {
    // Rust has no direct `%g`; this matches the common cases (finite values use
    // the shortest round-tripping representation, which is close enough for the
    // diagnostic text). Non-finite values print like C.
    if x.is_nan() {
        "nan".to_string()
    } else if x.is_infinite() {
        if x < 0.0 { "-inf".to_string() } else { "inf".to_string() }
    } else {
        format!("{x}")
    }
}

/// C `%.*g` with `sig` significant digits: fixed notation when the decimal
/// exponent is in `[-4, sig)`, exponential (`e±NN`, two-digit exponent)
/// otherwise, with trailing zeros stripped in both forms. Used for the data
/// values (sig=15, i.e. `%.15g`) and tolerance text (sig=2) of the HTML report.
pub fn format_g_prec(x: f64, sig: usize) -> String {
    if !x.is_finite() {
        return format_g(x);
    }
    if x == 0.0 {
        return "0".to_string();
    }
    let sig = sig.max(1);
    let exp = x.abs().log10().floor() as i32;
    if exp < -4 || exp >= sig as i32 {
        // Exponential. Rust prints `8.00e-7`; C `%g` prints `8e-07`: strip the
        // mantissa's trailing zeros and pad the exponent to two digits.
        let s = format!("{:.*e}", sig - 1, x);
        let (mant, e) = s.split_once('e').unwrap();
        let mant = if mant.contains('.') {
            mant.trim_end_matches('0').trim_end_matches('.')
        } else {
            mant
        };
        let e: i32 = e.parse().unwrap_or(0);
        format!("{mant}e{}{:02}", if e < 0 { '-' } else { '+' }, e.abs())
    } else {
        let decimals = (sig as i32 - 1 - exp).max(0) as usize;
        let s = format!("{:.*}", decimals, x);
        if s.contains('.') {
            s.trim_end_matches('0').trim_end_matches('.').to_string()
        } else {
            s
        }
    }
}

/// `%.15g`, the format C uses for the numeric data/time values in the report.
pub fn format_g_prec15(x: f64) -> String {
    format_g_prec(x, 15)
}


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

/// Port of the `privates` tube state in SimulationResultsCmpTubes.c.
struct Tubes {
    mh: Vec<f64>,
    ml: Vec<f64>,
    x_high: Vec<f64>,
    x_low: Vec<f64>,
    y_high: Vec<f64>,
    y_low: Vec<f64>,
    i0h: Vec<i64>,
    i1h: Vec<i64>,
    i0l: Vec<i64>,
    i1l: Vec<i64>,
    t_start: f64,
    t_stop: f64,
    x1: f64,
    y1: f64,
    x2: f64,
    y2: f64,
    current_slope: f64,
    slope_dif: f64,
    delta: f64,
    s: f64,
    x_rel_eps: f64,
    x_min_step: f64,
    min: f64,
    max: f64,
    count_low: usize,
    count_high: usize,
}

impl Tubes {
    /// C `generateHighTube`.
    fn generate_high_tube(&mut self, x: &[f64], y: &[f64]) {
        let mut index = self.count_high as isize - 1;
        let m1 = self.mh[index as usize];
        let mut m2 = self.mh[(index - 1) as usize];
        self.slope_dif = (m1 - m2).abs();

        if self.slope_dif == 0.0
            || (self.slope_dif < 2e-15 * m1.abs().max(m2.abs())
                && self.i0h[self.count_high - 1] - self.i1h[self.count_high - 2] < 100)
        {
            self.i0h[(index - 1) as usize] = self.i0h[index as usize];
            self.count_high -= 1;
            let x3 = x[self.i0h[(index - 1) as usize] as usize];
            let y3 = y[self.i0h[(index - 1) as usize] as usize];
            let x4 = x[self.i1h[(index - 1) as usize] as usize];
            let y4 = y[self.i1h[(index - 1) as usize] as usize];
            self.mh[(index - 1) as usize] = (y3 - y4) / (x3 - x4);
        } else {
            self.x_high[index as usize] = self.x2
                - (self.delta * (m1 + m2)
                    / ((m2 * m2 + self.s * self.s).sqrt() + (m1 * m1 + self.s * self.s).sqrt()));
            if m1 * m2 < 0.0 {
                self.y_high[index as usize] = self.y2
                    + (self.delta
                        * (m1 * (m2 * m2 + self.s * self.s).sqrt()
                            - m2 * (m1 * m1 + self.s * self.s).sqrt()))
                        / (m1 - m2);
            } else {
                self.y_high[index as usize] = self.y2
                    + (self.s * self.s * self.delta * (m1 + m2)
                        / (m1 * (m2 * m2 + self.s * self.s).sqrt()
                            + m2 * (m1 * m1 + self.s * self.s).sqrt()));
            }

            if self.x_high[index as usize] == self.x_high[(index - 1) as usize]
                && self.y_high[index as usize] != self.y_high[(index - 1) as usize]
            {
                self.x_high[index as usize] = self.x_high[(index - 1) as usize] + self.x_min_step;
                self.y_high[index as usize] = self.y2
                    + m1 * (self.x_high[index as usize] - self.x2)
                    + self.delta * (m1 * m1 + self.s * self.s).sqrt();
                self.mh[(index - 1) as usize] =
                    (self.y_high[index as usize] - self.y_high[(index - 1) as usize]) / self.x_min_step;
            }

            while index > 1 && self.x_high[index as usize] <= self.x_high[(index - 1) as usize] {
                self.i0h[(index - 1) as usize] = self.i0h[index as usize];
                self.i1h[(index - 1) as usize] = self.i1h[index as usize];
                self.mh[(index - 1) as usize] = self.mh[index as usize];
                index -= 1;
                self.count_high -= 1;

                if index == 0 {
                    let x3 = x[0];
                    self.x_high[index as usize] = x3 - self.delta;
                    self.y_high[index as usize] = self.y2
                        + m1 * (self.x_high[index as usize] - self.x2)
                        + self.delta * (m1 * m1 + self.s * self.s).sqrt();
                } else {
                    let x3 = self.x_high[(index - 1) as usize];
                    let y3 = self.y_high[(index - 1) as usize];
                    m2 = self.mh[(index - 1) as usize];
                    self.x_high[index as usize] = (m2 * x3 - m1 * self.x2 + self.y2 - y3
                        + self.delta * (m1 * m1 + self.s * self.s).sqrt())
                        / (m2 - m1);
                    self.y_high[index as usize] = (m2 * m1 * (x3 - self.x2)
                        + m2 * (self.y2 + self.delta * (m1 * m1 + self.s * self.s).sqrt())
                        - m1 * y3)
                        / (m2 - m1);
                }
            }
        }
    }

    /// C `generateLowTube`.
    fn generate_low_tube(&mut self, x: &[f64], y: &[f64]) {
        let mut index = self.count_low as isize - 1;
        let m1 = self.ml[index as usize];
        let mut m2 = self.ml[(index - 1) as usize];
        self.slope_dif = (m1 - m2).abs();

        if self.slope_dif == 0.0
            || (self.slope_dif < 2e-15 * m1.abs().max(m2.abs())
                && self.i0l[self.count_low - 1] - self.i1l[self.count_low - 2] < 100)
        {
            self.i0l[(index - 1) as usize] = self.i0l[index as usize];
            self.count_low -= 1;
            let x3 = x[self.i0l[(index - 1) as usize] as usize];
            let y3 = y[self.i0l[(index - 1) as usize] as usize];
            let x4 = x[self.i1l[(index - 1) as usize] as usize];
            let y4 = y[self.i1l[(index - 1) as usize] as usize];
            self.ml[(index - 1) as usize] = (y3 - y4) / (x3 - x4);
        } else {
            self.x_low[index as usize] = self.x2
                + (self.delta * (m1 + m2)
                    / ((m2 * m2 + self.s * self.s).sqrt() + (m1 * m1 + self.s * self.s).sqrt()));
            if m1 * m2 < 0.0 {
                self.y_low[index as usize] = self.y2
                    - (self.delta
                        * (m1 * (m2 * m2 + self.s * self.s).sqrt()
                            - m2 * (m1 * m1 + self.s * self.s).sqrt()))
                        / (m1 - m2);
            } else {
                self.y_low[index as usize] = self.y2
                    - (self.s * self.s * self.delta * (m1 + m2)
                        / (m1 * (m2 * m2 + self.s * self.s).sqrt()
                            + m2 * (m1 * m1 + self.s * self.s).sqrt()));
            }

            if self.x_low[index as usize] == self.x_low[(index - 1) as usize]
                && self.y_low[index as usize] != self.y_low[(index - 1) as usize]
            {
                self.x_low[index as usize] = self.x_low[(index - 1) as usize] + self.x_min_step;
                self.y_low[index as usize] = self.y2
                    + m1 * (self.x_low[index as usize] - self.x2)
                    - self.delta * (m1 * m1 + self.s * self.s).sqrt();
                self.ml[(index - 1) as usize] =
                    (self.y_low[index as usize] - self.y_low[(index - 1) as usize]) / self.x_min_step;
            }

            while index > 1 && self.x_low[index as usize] <= self.x_low[(index - 1) as usize] {
                self.i0l[(index - 1) as usize] = self.i0l[index as usize];
                self.i1l[(index - 1) as usize] = self.i1l[index as usize];
                self.ml[(index - 1) as usize] = self.ml[index as usize];
                index -= 1;
                self.count_low -= 1;

                if index == 0 {
                    let x3 = x[0];
                    self.x_low[index as usize] = x3 - self.delta;
                    self.y_low[index as usize] = self.y2
                        + m1 * (self.x_low[index as usize] - self.x2)
                        - self.delta * (m1 * m1 + self.s * self.s).sqrt();
                } else {
                    let x3 = self.x_low[(index - 1) as usize];
                    let y3 = self.y_low[(index - 1) as usize];
                    m2 = self.ml[(index - 1) as usize];
                    self.x_low[index as usize] = (m2 * x3 - m1 * self.x2 + self.y2 - y3
                        - self.delta * (m1 * m1 + self.s * self.s).sqrt())
                        / (m2 - m1);
                    self.y_low[index as usize] = (m2 * m1 * (x3 - self.x2)
                        + m2 * (self.y2 - self.delta * (m1 * m1 + self.s * self.s).sqrt())
                        - m1 * y3)
                        / (m2 - m1);
                }
            }
        }
    }
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

/// The dygraph HTML report for one variable, mirroring the `isHtml=1` output of
/// C `cmpDataTubes`: a `<html>` page embedding a Dygraph fed an array of
/// `[time,reference,actual,high,low,error,actual(original)]` rows.
#[allow(clippy::too_many_arguments)]
pub fn tube_html(
    var_name: &str,
    time: &[f64],
    reftime: &[f64],
    refdata: &[f64],
    data: &[f64],
    cmp: &TubeCmp,
    reltol: f64,
    reltol_diff_max_min: f64,
    range_delta: f64,
) -> String {
    let TubeCmp { calibrated: calibrated_values, high, low, error, n, abstol } = cmp;
    let (n, abstol) = (*n, *abstol);
    let error = error.as_deref();
    let mut html = String::new();
    let ref_size = reftime.len();
    // `concat!` preserves the exact leading whitespace of each line (the CSS
    // block is indented); a `\`-continued string literal would strip it.
    html.push_str(concat!(
        "<html>\n",
        "<head>\n",
        "<script type=\"text/javascript\" src=\"dygraph-combined.js\"></script>\n",
        "    <style type=\"text/css\">\n",
        "    #graphdiv {\n",
        "      position: absolute;\n",
        "      left: 10px;\n",
        "      right: 10px;\n",
        "      top: 40px;\n",
        "      bottom: 10px;\n",
        "    }\n",
        "    </style>\n",
        "</head>\n",
        "<body>\n",
        "<div id=\"graphdiv\"></div>\n",
        "<p><input type=checkbox id=\"0\" checked onClick=\"change(this)\">\n",
        "<label for=\"0\">reference</label>\n",
        "<input type=checkbox id=\"1\" checked onClick=\"change(this)\">\n",
        "<label for=\"1\">actual</label>\n",
        "<input type=checkbox id=\"2\" checked onClick=\"change(this)\">\n",
        "<label for=\"2\">high</label>\n",
        "<input type=checkbox id=\"3\" checked onClick=\"change(this)\">\n",
        "<label for=\"3\">low</label>\n",
        "<input type=checkbox id=\"4\" checked onClick=\"change(this)\">\n",
        "<label for=\"4\">error</label>\n",
        "<input type=checkbox id=\"5\" onClick=\"change(this)\">\n",
        "<label for=\"5\">actual (original)</label>\n",
    ));
    html.push_str(&format!(
        "Reference time: {} to {}, actual time: {} to {}. Parameters used for the comparison: \
Relative tolerance {}. Absolute tolerance {} ({} relative). Range delta {}.",
        format_g_prec15(reftime[0]),
        format_g_prec15(reftime[ref_size - 1]),
        format_g_prec15(time[0]),
        format_g_prec15(time[time.len() - 1]),
        format_g_prec(reltol, 2),
        format_g_prec(abstol, 2),
        format_g_prec(reltol_diff_max_min, 2),
        format_g_prec(range_delta, 2),
    ));
    html.push_str(
        "</p>\n\
<script type=\"text/javascript\">\n\
g = new Dygraph(document.getElementById(\"graphdiv\"),\n\
[\n",
    );

    let mut j = 0usize;
    for i in 0..ref_size {
        html.push_str(&format!("[{},{},", format_g_prec15(reftime[i]), format_g_prec15(refdata[i])));
        if i < n {
            match error {
                Some(e) if !e[i].is_nan() => html.push_str(&format!(
                    "{},{},{},{}",
                    format_g_prec15(calibrated_values[i]), format_g_prec15(high[i]), format_g_prec15(low[i]), format_g_prec15(e[i])
                )),
                _ => html.push_str(&format!(
                    "{},{},{},null",
                    format_g_prec15(calibrated_values[i]), format_g_prec15(high[i]), format_g_prec15(low[i])
                )),
            }
            if j < data.len() && reftime[i] == time[j] {
                html.push_str(&format!(",{}],\n", format_g_prec15(data[j])));
                j += 1;
            } else {
                html.push_str(",null],\n");
            }
        } else {
            html.push_str("null,null,null,null,null],\n");
        }
        while j < data.len() && reftime[i] > time[j] {
            html.push_str(&format!(
                "[{},null,null,null,null,null,{}],\n",
                format_g_prec15(time[j]), format_g_prec15(data[j])
            ));
            j += 1;
        }
    }
    html.push_str("],\n");
    html.push_str(&format!(
        "{{title: '{var_name}',\n\
legend: 'always',\n\
xlabel: ['time'],\n\
connectSeparatedPoints: true,\n\
labels: ['time','reference','actual','high','low','error','actual (original)'],\n\
y2label: ['error'],\n\
series : {{ 'error': {{ axis: 'y2' }} }},\n\
colors: ['blue','red','teal','lightblue','orange','black'],\n\
visibility: [true,true,true,true,true,false]\n\
}});\n\
function change(el) {{\n  g.setVisibility(parseInt(el.id), el.checked);\n\
}}\n\
</script>\n\
</body>\n\
</html>\n"
    ));
    html
}
