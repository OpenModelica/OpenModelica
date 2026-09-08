//! Tube comparison of two result trajectories: the algorithms of
//! [csv-compare](https://github.com/modelica-tools/csv-compare) plus the one
//! `diffSimulationResults` has always run.
//!
//! A tube of a given tolerance is built around the reference signal and the
//! signal under test has to stay inside it. Which tube, and on which timeline
//! the test happens, is [`Algorithm`]:
//!
//! | | tube | sized by | tested on |
//! | --- | --- | --- | --- |
//! | [`Algorithm::Rectangle`] | rectangles per reference point ([`rectangle`]) | [`tube_size`] | the curve under test |
//! | [`Algorithm::Ellipse`] | ellipses per reference point ([`ellipse`]) | [`tube_size`] | the curve under test |
//! | [`Algorithm::Ellipse2014`] | the 2014 ellipse ([`ellipse2014`]) | `tolerance * (tStop - tStart)` | the reference, plus `relTol` and event handling |
//!
//! `Rectangle` is what csv-compare itself uses; `Ellipse2014` is what omc's
//! `diffSimulationResults` uses. They do disagree on real files, mostly around
//! events and near-zero signals.

pub mod ellipse;
pub mod ellipse2014;
pub mod format;
pub mod html;
pub mod rectangle;
pub mod tube_size;
pub mod validate;

mod tubes;

pub use ellipse2014::{
    DOUBLEEQUAL_REL, DOUBLEEQUAL_TOTAL, TubeCmp, almost_equal_default, almost_equal_rel_abs,
    cmp_data_tubes,
};
pub use format::{format_g, format_g_prec, format_g_prec15};
pub use html::tube_html;
pub use tube_size::{DEFAULT_NOMINAL_VALUE, TubeSize};

/// A polyline: `x` and `y` of the same length.
#[derive(Clone, Debug, Default)]
pub struct Curve {
    pub x: Vec<f64>,
    pub y: Vec<f64>,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum Algorithm {
    /// csv-compare's default.
    #[default]
    Rectangle,
    /// csv-compare's `AlgorithmOptions.Ellipse`.
    Ellipse,
    /// `diffSimulationResults`, i.e. the 2014 ellipse plus a relative tolerance
    /// and event handling.
    Ellipse2014,
}

impl Algorithm {
    pub fn parse(s: &str) -> Result<Algorithm, String> {
        match s.to_ascii_lowercase().as_str() {
            "rectangle" => Ok(Algorithm::Rectangle),
            "ellipse" => Ok(Algorithm::Ellipse),
            "ellipse2014" | "openmodelica" => Ok(Algorithm::Ellipse2014),
            _ => Err(format!("unknown algorithm {s}: expected rectangle, ellipse or ellipse2014")),
        }
    }

    pub fn name(self) -> &'static str {
        match self {
            Algorithm::Rectangle => "rectangle",
            Algorithm::Ellipse => "ellipse",
            Algorithm::Ellipse2014 => "ellipse2014",
        }
    }
}

/// Everything [`compare`] needs besides the two curves. csv-compare's defaults,
/// except that the `Ellipse2014`-only ones are `diffSimulationResults`'s.
#[derive(Clone, Copy, Debug)]
pub struct Settings {
    pub algorithm: Algorithm,
    /// Tube width in x, relative to the time span: csv-compare's `--tolerance`,
    /// omc's `rangeDelta`.
    pub tolerance: f64,
    /// `Ellipse2014` only, omc's `relTol`.
    pub reltol: f64,
    /// `Ellipse2014` only, omc's `relTolDiffMinMax`.
    pub reltol_diff_min_max: f64,
    /// `Rectangle`/`Ellipse` only: floor on the tube height, standing in for the
    /// `nominal` attribute a result file does not carry.
    pub nominal_value: f64,
    /// `Rectangle`/`Ellipse` only: `SetFormerBaseAndRatio`, which is what
    /// csv-compare uses, rather than `SetStandardBaseAndRatio`.
    pub legacy_base: bool,
}

impl Default for Settings {
    fn default() -> Settings {
        Settings {
            algorithm: Algorithm::default(),
            tolerance: 0.002,
            reltol: 1e-3,
            reltol_diff_min_max: 1e-4,
            nominal_value: DEFAULT_NOMINAL_VALUE,
            legacy_base: true,
        }
    }
}

/// One variable compared. `time`/`values`/`low`/`high`/`error` share a length,
/// on whichever timeline the algorithm tested; `reference`/`lower`/`upper` are
/// the curves to plot.
pub struct Comparison {
    pub algorithm: Algorithm,
    /// As compared: the ellipse algorithms nudge its time to stay increasing.
    pub reference: Curve,
    pub lower: Curve,
    pub upper: Curve,
    pub time: Vec<f64>,
    pub values: Vec<f64>,
    pub low: Vec<f64>,
    pub high: Vec<f64>,
    /// Distance outside the tube, 0 inside, NaN where the point was excluded.
    pub error: Vec<f64>,
    pub error_count: usize,
    /// csv-compare's per-result "relative error": see [`validate::delta_error`].
    pub delta_error: f64,
    /// Absolute slack: `Ellipse2014`'s widening, or the tube half-height.
    pub abstol: f64,
}

impl Comparison {
    pub fn differs(&self) -> bool {
        self.error_count > 0
    }
}

/// Compare `(time, values)` against the reference `(reftime, refvalues)`.
pub fn compare(
    time: &[f64],
    values: &[f64],
    reftime: &[f64],
    refvalues: &[f64],
    settings: &Settings,
) -> Result<Comparison, String> {
    // A trajectory can be one value short of its timeline (a truncated last CSV
    // row); compare only as far as both go.
    let nref = reftime.len().min(refvalues.len());
    let n = time.len().min(values.len());
    if nref == 0 {
        return Err("the reference curve is empty".to_owned());
    }
    if n == 0 {
        return Err("the curve under test is empty".to_owned());
    }
    if settings.algorithm == Algorithm::Ellipse2014 && n < 2 {
        // calibrateValues resamples from this curve and needs a segment; the C
        // reads out of bounds here instead.
        return Err("the curve under test needs at least two points".to_owned());
    }
    let (time, values) = (&time[..n], &values[..n]);
    let mut reftime = reftime[..nref].to_vec();
    let refvalues = &refvalues[..nref];

    if settings.algorithm == Algorithm::Ellipse2014 {
        let mut cmp = cmp_data_tubes(
            time,
            &mut reftime,
            refvalues,
            values,
            settings.reltol,
            settings.tolerance,
            settings.reltol_diff_min_max,
        );
        let n = cmp.n;
        let error = cmp.error.take().unwrap_or_else(|| vec![0.0; n]);
        let error_count = error.iter().filter(|e| **e > 0.0).count();
        let time: Vec<f64> = reftime[..n].to_vec();
        cmp.calibrated.truncate(n);
        cmp.low.truncate(n);
        cmp.high.truncate(n);
        let delta_error = validate::delta_error(&time, &cmp.calibrated, &error);
        return Ok(Comparison {
            algorithm: settings.algorithm,
            reference: Curve { x: reftime.clone(), y: refvalues.to_vec() },
            lower: Curve { x: time.clone(), y: cmp.low.clone() },
            upper: Curve { x: time.clone(), y: cmp.high.clone() },
            time,
            values: cmp.calibrated,
            low: cmp.low,
            high: cmp.high,
            error,
            error_count,
            delta_error,
            abstol: cmp.abstol,
        });
    }

    let mut size = if settings.legacy_base {
        TubeSize::legacy(&reftime, refvalues, settings.nominal_value)
    } else {
        TubeSize::standard(&reftime, refvalues, settings.nominal_value)
    };
    size.calculate_relative_x(settings.tolerance)?;

    let (lower, upper) = match settings.algorithm {
        Algorithm::Rectangle => rectangle::rectangle_tube(&reftime, refvalues, &size),
        _ => ellipse::ellipse_tube(&mut reftime, refvalues, &size),
    };

    let v = validate::validate(time, values, &lower, &upper);
    let n = v.n;
    let time = time[..n.min(time.len())].to_vec();
    let values = values[..n.min(values.len())].to_vec();
    let delta_error = validate::delta_error(&time, &values, &v.error);
    Ok(Comparison {
        algorithm: settings.algorithm,
        reference: Curve { x: reftime, y: refvalues.to_vec() },
        lower,
        upper,
        time,
        values,
        low: v.low[..n].to_vec(),
        high: v.high[..n].to_vec(),
        error: v.error,
        error_count: v.error_count,
        delta_error,
        abstol: size.y,
    })
}
