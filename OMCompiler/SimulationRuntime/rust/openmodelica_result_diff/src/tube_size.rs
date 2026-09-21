//! Port of csv-compare's `TubeSize.cs`: how a relative tolerance becomes the
//! half-width and half-height of the tube around the reference curve.

/// `x` is half the rectangle width, `y` half its height, `ratio` is `y/x` -- so
/// a tolerance on one axis fixes the other.
#[derive(Clone, Copy, Debug)]
pub struct TubeSize {
    pub x: f64,
    pub y: f64,
    pub base_x: f64,
    pub base_y: f64,
    pub ratio: f64,
}

/// Floor on `base_y`, so a near-zero reference does not get a near-zero tube;
/// result files carry no `nominal` attribute. See ModelicaStandardLibrary#4421.
pub const DEFAULT_NOMINAL_VALUE: f64 = 0.001;

impl TubeSize {
    /// `SetFormerBaseAndRatio`, the base csv-compare actually uses
    /// (`useLegacyBaseAndRatio = true` in `CsvFile.CompareFiles`).
    pub fn legacy(x: &[f64], y: &[f64], nominal_value: f64) -> TubeSize {
        const EPSILON: f64 = 1e-12; // guards a single time point, where the span is zero
        let (xmin, xmax) = min_max(x);
        let (ymin, ymax) = min_max(y);
        let base_x = (xmax - xmin).max(xmin.abs()).max(EPSILON);
        let base_y = (ymax - ymin).max(ymin.abs()).max(nominal_value);
        TubeSize { x: 0.0, y: 0.0, base_x, base_y, ratio: base_y / base_x }
    }

    /// `SetStandardBaseAndRatio`.
    pub fn standard(x: &[f64], y: &[f64], nominal_value: f64) -> TubeSize {
        let (xmin, xmax) = min_max(x);
        let (ymin, ymax) = min_max(y);
        let mut base_x = xmax - xmin;
        if base_x == 0.0 {
            base_x = xmax.abs();
        }
        if base_x == 0.0 {
            base_x = 1.0;
        }
        let base_y = (ymax - ymin).max(nominal_value);
        let ratio = if base_x != 0.0 { base_y / base_x } else { 0.0 };
        TubeSize { x: 0.0, y: 0.0, base_x, base_y, ratio }
    }

    /// `Calculate(value, Axes.X, Relativity.Relative)`: the tolerance as a
    /// fraction of the time span. Fails where the C# does.
    pub fn calculate_relative_x(&mut self, value: f64) -> Result<(), String> {
        if !(0.0..=1.0).contains(&value) {
            return Err("Relative value is out of expected range [0,1].".to_owned());
        }
        if self.ratio <= 0.0 || self.base_x <= 0.0 {
            return Err("Tube size cannot be calculated from this reference curve.".to_owned());
        }
        self.x = value * self.base_x;
        self.y = self.ratio * self.x;
        Ok(())
    }
}

fn min_max(v: &[f64]) -> (f64, f64) {
    v.iter().fold((f64::INFINITY, f64::NEG_INFINITY), |(lo, hi), &e| (lo.min(e), hi.max(e)))
}
