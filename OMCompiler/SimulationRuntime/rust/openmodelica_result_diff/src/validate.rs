//! Port of csv-compare's `Tube.cs`: the tube is interpolated onto the curve
//! under test and each of its points has to lie between the two curves. Note the
//! direction -- [`crate::ellipse2014`] resamples the other way.

/// `low`/`high` are the tube on `time`, `error` the distance outside it (0
/// inside), `n` how many points could be tested before the tube ran out.
pub struct Validation {
    pub low: Vec<f64>,
    pub high: Vec<f64>,
    pub error: Vec<f64>,
    pub error_count: usize,
    pub n: usize,
}

pub fn validate(time: &[f64], values: &[f64], lower: &crate::Curve, upper: &crate::Curve) -> Validation {
    let low = interpolate_values(&lower.x, &lower.y, time);
    let high = interpolate_values(&upper.x, &upper.y, time);
    let n = values.len().min(low.len()).min(high.len());
    let mut error = vec![0.0; n];
    let mut error_count = 0;
    for i in 0..n {
        if values[i] < low[i] {
            error[i] = (low[i] - values[i]).abs();
            error_count += 1;
        } else if values[i] > high[i] {
            error[i] = (high[i] - values[i]).abs();
            error_count += 1;
        }
    }
    Validation { low, high, error, error_count, n }
}

/// `InterpolateValues`: linear interpolation of the tube onto `target`,
/// truncated rather than extrapolated past the tube's last point.
fn interpolate_values(source_time: &[f64], source_values: &[f64], target: &[f64]) -> Vec<f64> {
    if source_values.is_empty() || source_time.len() < 2 {
        return Vec::new();
    }
    let mut out = Vec::with_capacity(target.len());
    let mut j = 1usize;
    for &x in target {
        if x > source_time[source_time.len() - 1] {
            break;
        }
        let mut x1 = source_time[j];
        let mut y1 = source_values[j];
        while x1 < x && j + 1 < source_time.len() && j + 1 < source_values.len() {
            j += 1;
            x1 = source_time[j];
            y1 = source_values[j];
        }
        let x0 = source_time[j - 1];
        let y0 = source_values[j - 1];
        out.push(if (x1 - x0) * (x - x0) != 0.0 { y0 + (y1 - y0) / (x1 - x0) * (x - x0) } else { y0 });
    }
    out
}

/// csv-compare's per-result "relative error" (`CsvFile.PrepareCharts`): the
/// error integrated over time, normalised by the peak of the tested curve.
pub fn delta_error(time: &[f64], values: &[f64], error: &[f64]) -> f64 {
    if error.iter().all(|e| *e == 0.0) {
        return 0.0;
    }
    let mut sum = 0.0;
    for i in 1..time.len().min(error.len()).saturating_sub(1) {
        if error[i] == 0.0 {
            continue;
        }
        let dt = (time[i] - time[i - 1]).abs() + (time[i + 1] - time[i]).abs();
        sum += error[i].abs() * dt / 2.0;
    }
    let peak = values.iter().fold(0.0f64, |m, v| m.max(v.abs()));
    sum / (1e-3 + peak)
}
