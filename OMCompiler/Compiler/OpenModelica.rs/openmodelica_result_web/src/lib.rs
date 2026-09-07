//! Result files for the OMPlot web page, without omc: the JS bindings over
//! `openmodelica_result_files::ResultFile`. The bytes handed in from the page
//! are parked in the in-memory VFS for the reader's lifetime.

use std::sync::atomic::{AtomicUsize, Ordering};

use openmodelica_result_files::{Tolerances, file};
use wasm_bindgen::prelude::*;

static NEXT_ID: AtomicUsize = AtomicUsize::new(0);

#[wasm_bindgen]
pub struct ResultFile {
    inner: file::ResultFile,
    path: String,
}

impl Drop for ResultFile {
    fn drop(&mut self) {
        openmodelica_wasi::remove(&self.path);
    }
}

fn json_str(out: &mut String, s: &str) {
    out.push('"');
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out.push('"');
}

fn js_err(msg: String) -> JsError {
    JsError::new(&msg)
}

fn tol(reltol: f64, reltol_diff_min_max: f64, range_delta: f64) -> Tolerances {
    Tolerances { reltol, reltol_diff_min_max, range_delta }
}

#[wasm_bindgen]
impl ResultFile {
    /// `name` selects the format by suffix; `bytes` is the file.
    #[wasm_bindgen(constructor)]
    pub fn new(name: &str, bytes: &[u8]) -> Result<ResultFile, JsError> {
        let base = name.rsplit(['/', '\\']).next().unwrap_or(name);
        let path = format!("/omplot/{}/{base}", NEXT_ID.fetch_add(1, Ordering::Relaxed));
        openmodelica_wasi::write(&path, bytes.to_vec());
        match file::ResultFile::open(&path) {
            Ok(inner) => Ok(ResultFile { inner, path }),
            Err(e) => {
                openmodelica_wasi::remove(&path);
                Err(js_err(e))
            }
        }
    }

    /// Every variable name in the file, parameters and aliases included.
    pub fn variables(&self) -> Vec<String> {
        self.inner.variables()
    }

    /// The variables `diff_all` compares when given none: the reference's real
    /// (non-alias) variables and parameters.
    pub fn compared_variables(&self) -> Vec<String> {
        self.inner.compared_variables()
    }

    pub fn description(&self, var: &str) -> String {
        self.inner.description(var)
    }

    /// The variable's unit (`.arrow` files carry one; the others give "").
    pub fn unit(&self, var: &str) -> String {
        self.inner.unit(var)
    }

    /// The unit it is preferably plotted in, a display unit of [`Self::unit`].
    pub fn display_unit(&self, var: &str) -> String {
        self.inner.display_unit(var)
    }

    /// FMI's `relativeQuantity`: a difference in the unit, so a conversion to a
    /// display unit scales it but adds no offset.
    pub fn relative_quantity(&self, var: &str) -> bool {
        self.inner.relative_quantity(var)
    }

    /// The display units of every unit the file names, as the JSON object
    /// `{"K":[{"name","factor","offset","inverse"}],...}` — the shape
    /// `omc_sim_units()` hands the simulator. `JSON.parse` it.
    pub fn unit_defs_json(&self) -> String {
        let mut o = String::from("{");
        for (i, u) in self.inner.unit_defs().iter().enumerate() {
            if i > 0 {
                o.push(',');
            }
            json_str(&mut o, &u.name);
            o.push_str(":[");
            for (j, d) in u.display_units.iter().enumerate() {
                if j > 0 {
                    o.push(',');
                }
                o.push_str("{\"name\":");
                json_str(&mut o, &d.name);
                o.push_str(&format!(
                    ",\"factor\":{},\"offset\":{},\"inverse\":{}}}",
                    d.factor, d.offset, d.inverse
                ));
            }
            o.push(']');
        }
        o.push('}');
        o
    }

    pub fn is_parameter(&self, var: &str) -> bool {
        self.inner.is_parameter(var)
    }

    pub fn nrows(&self) -> usize {
        self.inner.nrows()
    }

    pub fn time_name(&self) -> String {
        self.inner.time_name().to_owned()
    }

    pub fn time(&mut self) -> Result<Vec<f64>, JsError> {
        self.inner.time().map(<[f64]>::to_vec).map_err(js_err)
    }

    pub fn trajectory(&mut self, var: &str) -> Option<Vec<f64>> {
        self.inner.trajectory(var)
    }

    /// The file as MATLAB v4 with `vars` (all of them when empty), optionally
    /// resampled onto `intervals` equidistant steps.
    pub fn write_mat(&mut self, vars: Vec<String>, intervals: u32) -> Result<Vec<u8>, JsError> {
        self.inner.write_mat(vars, intervals, false).map_err(js_err)
    }

    /// The file as Arrow IPC, selected and resampled like [`Self::write_mat`].
    pub fn write_arrow(&mut self, vars: Vec<String>, intervals: u32) -> Result<Vec<u8>, JsError> {
        self.inner.write_arrow(vars, intervals, false).map_err(js_err)
    }

    /// The file as CSV, selected and resampled like [`Self::write_mat`].
    pub fn write_csv(&mut self, vars: Vec<String>, intervals: u32) -> Result<String, JsError> {
        self.inner.write_csv(vars, intervals).map_err(js_err)
    }
}

/// One variable's comparison, on the reference timeline (`n` points of it are
/// compared; `error` is empty when the signal stayed inside the tube).
#[wasm_bindgen(getter_with_clone)]
pub struct TubeDiff {
    pub differs: bool,
    pub time: Vec<f64>,
    pub reference: Vec<f64>,
    pub actual: Vec<f64>,
    pub high: Vec<f64>,
    pub low: Vec<f64>,
    pub error: Vec<f64>,
    pub actual_time: Vec<f64>,
    pub actual_original: Vec<f64>,
    pub abstol: f64,
}

/// `diffSimulationResults`: the variables of `vars` (every reference variable
/// when empty) whose trajectory in `actual` leaves the tube around `reference`.
#[wasm_bindgen]
pub fn diff_all(
    actual: &mut ResultFile,
    reference: &mut ResultFile,
    vars: Vec<String>,
    reltol: f64,
    reltol_diff_min_max: f64,
    range_delta: f64,
) -> Result<Vec<String>, JsError> {
    file::diff_all(&mut actual.inner, &mut reference.inner, vars, tol(reltol, reltol_diff_min_max, range_delta)).map_err(js_err)
}

/// `diffSimulationResultsHtml` as data: one variable's tube comparison.
#[wasm_bindgen]
pub fn diff_variable(
    actual: &mut ResultFile,
    reference: &mut ResultFile,
    var: &str,
    reltol: f64,
    reltol_diff_min_max: f64,
    range_delta: f64,
) -> Result<TubeDiff, JsError> {
    let d = file::diff_variable(&mut actual.inner, &mut reference.inner, var, tol(reltol, reltol_diff_min_max, range_delta)).map_err(js_err)?;
    Ok(TubeDiff {
        differs: d.differs,
        time: d.time,
        reference: d.reference,
        actual: d.actual,
        high: d.high,
        low: d.low,
        error: d.error,
        actual_time: d.actual_time,
        actual_original: d.actual_original,
        abstol: d.abstol,
    })
}
