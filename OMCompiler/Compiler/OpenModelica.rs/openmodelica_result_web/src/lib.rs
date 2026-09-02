//! Result files for the OMPlot web page, without omc: open, read, compare,
//! write back out.

use std::collections::HashMap;
use std::sync::atomic::{AtomicUsize, Ordering};

use openmodelica_mat_writer::{MatKind, MatVar, Neg, Precision, write_mat4};
use openmodelica_result_files::cmp::{cmp_data_tubes, format_g_prec15};
use openmodelica_result_files::{OpenError, ResultReader, drop_leading_dups, leading_dup_count, time_var_name};
use wasm_bindgen::prelude::*;

static NEXT_ID: AtomicUsize = AtomicUsize::new(0);

#[wasm_bindgen]
pub struct ResultFile {
    reader: ResultReader,
    path: String,
    time_name: &'static str,
    time: Option<Vec<f64>>,
}

impl Drop for ResultFile {
    fn drop(&mut self) {
        openmodelica_wasi::remove(&self.path);
    }
}

fn js_err(msg: impl Into<String>) -> JsError {
    JsError::new(&msg.into())
}

#[wasm_bindgen]
impl ResultFile {
    /// `name` selects the format by suffix; `bytes` is the file.
    #[wasm_bindgen(constructor)]
    pub fn new(name: &str, bytes: &[u8]) -> Result<ResultFile, JsError> {
        let base = name.rsplit(['/', '\\']).next().unwrap_or(name);
        let path = format!("/omplot/{}/{base}", NEXT_ID.fetch_add(1, Ordering::Relaxed));
        openmodelica_wasi::write(&path, bytes.to_vec());
        let reader = match ResultReader::open(&path) {
            Ok(r) => r,
            Err(e) => {
                openmodelica_wasi::remove(&path);
                return Err(match e {
                    OpenError::UnknownSuffix => js_err(format!("Unknown result-file suffix of file '{base}'")),
                    OpenError::Failed(msg) => js_err(format!("Failed to open simulation result {base}: {msg}")),
                });
            }
        };
        let time_name = time_var_name(&reader.vars_filter_aliases());
        Ok(ResultFile { reader, path, time_name, time: None })
    }

    /// Every variable name in the file, parameters and aliases included.
    pub fn variables(&self) -> Vec<String> {
        match &self.reader {
            ResultReader::Mat(r) => r.allInfo.iter().map(|v| v.name.clone()).collect(),
            ResultReader::Plt(r) => r.variables().into_iter().map(str::to_owned).collect(),
            ResultReader::Csv(r) => r.variables.iter().filter(|v| !v.is_empty()).cloned().collect(),
        }
    }

    /// The variables `diff_all` compares when given none: the reference's real
    /// (non-alias) variables and parameters.
    pub fn compared_variables(&self) -> Vec<String> {
        self.reader.vars_filter_aliases()
    }

    pub fn description(&self, var: &str) -> String {
        match &self.reader {
            ResultReader::Mat(r) => r.find_var(var).map(|i| r.allInfo[i].descr.clone()).unwrap_or_default(),
            _ => String::new(),
        }
    }

    pub fn is_parameter(&self, var: &str) -> bool {
        match &self.reader {
            ResultReader::Mat(r) => r.find_var(var).is_some_and(|i| r.allInfo[i].isParam),
            _ => false,
        }
    }

    pub fn nrows(&self) -> usize {
        self.reader.nrows().unwrap_or(0)
    }

    pub fn time_name(&self) -> String {
        self.time_name.to_owned()
    }

    pub fn time(&mut self) -> Result<Vec<f64>, JsError> {
        self.time_ref().map(<[f64]>::to_vec)
    }

    pub fn trajectory(&mut self, var: &str) -> Option<Vec<f64>> {
        self.reader.trajectory(var)
    }

    /// The file as MATLAB v4 with `vars` (all of them when empty), optionally
    /// resampled onto `intervals` equidistant steps. Aliases of one column in a
    /// `.mat` source stay one column.
    pub fn write_mat(&mut self, vars: Vec<String>, intervals: u32) -> Result<Vec<u8>, JsError> {
        let vars = self.selection(vars);
        let time = self.time()?;
        let (start, stop) = (time[0], time[time.len() - 1]);
        let grid = resample_grid(&time, intervals);
        let n_rows = grid.as_ref().map_or(time.len(), Vec::len);

        let mut signals: Vec<(String, String, MatKind)> = vec![(self.time_name.to_owned(), String::new(), MatKind::Time)];
        let mut columns: Vec<Vec<f64>> = Vec::new();
        let mut params: Vec<f64> = Vec::new();
        let mut column_of: HashMap<u32, u32> = HashMap::new();
        for var in &vars {
            let descr = self.description(var);
            let storage = match &self.reader {
                ResultReader::Mat(r) => r.find_var(var).map(|i| (r.allInfo[i].isParam, r.allInfo[i].index)),
                _ => None,
            };
            let read = |me: &mut Self| me.reader.trajectory(var).ok_or_else(|| js_err(format!("Could not read variable {var}")));
            let kind = match storage {
                Some((true, _)) => {
                    params.push(read(self)?[0]);
                    MatKind::Param { negate: Neg::None }
                }
                Some((false, index)) => {
                    let negate = if index < 0 { Neg::Arith } else { Neg::None };
                    let col = match column_of.get(&index.unsigned_abs()) {
                        Some(&c) => c,
                        None => {
                            let mut vals = read(self)?;
                            if index < 0 {
                                vals.iter_mut().for_each(|x| *x = -*x);
                            }
                            columns.push(match &grid {
                                Some(g) => resample(&time, &vals, g),
                                None => vals,
                            });
                            column_of.insert(index.unsigned_abs(), columns.len() as u32);
                            columns.len() as u32
                        }
                    };
                    MatKind::Column { col, negate }
                }
                None => {
                    let vals = read(self)?;
                    columns.push(match &grid {
                        Some(g) => resample(&time, &vals, g),
                        None => vals,
                    });
                    MatKind::Column { col: columns.len() as u32, negate: Neg::None }
                }
            };
            signals.push((var.clone(), descr, kind));
        }
        let n_reals = 1 + columns.len();
        let mut rows = Vec::with_capacity(n_rows * n_reals);
        for r in 0..n_rows {
            rows.push(grid.as_ref().map_or(time[r], |g| g[r]));
            for c in &columns {
                rows.push(c[r]);
            }
        }
        let mat_vars: Vec<MatVar> = signals.iter().map(|(name, comment, kind)| MatVar { name, comment, kind: *kind }).collect();
        // Resampled numeric channels only; a String signal has no numeric data
        // to resample, so it is not carried over.
        Ok(write_mat4(&mat_vars, start, stop, &rows, n_reals as u32, &params, &[], Precision::Double))
    }

    /// The file as CSV with `vars` (all of them when empty): one `time` column
    /// and one per variable, as `filterSimulationResults` writes it.
    pub fn write_csv(&mut self, vars: Vec<String>, intervals: u32) -> Result<String, JsError> {
        let vars = self.selection(vars);
        let time = self.time()?;
        let grid = resample_grid(&time, intervals);
        let mut cols = Vec::with_capacity(vars.len());
        for var in &vars {
            let vals = self.reader.trajectory(var).ok_or_else(|| js_err(format!("Could not read variable {var}")))?;
            cols.push(match &grid {
                Some(g) => resample(&time, &vals, g),
                None => vals,
            });
        }
        let time = grid.unwrap_or(time);
        let mut text = String::from("time");
        for var in &vars {
            text.push_str(",\"");
            text.push_str(var);
            text.push('"');
        }
        text.push('\n');
        for row in 0..time.len() {
            text.push_str(&format_g_prec15(time[row]));
            for col in &cols {
                text.push(',');
                text.push_str(&format_g_prec15(col[row]));
            }
            text.push('\n');
        }
        Ok(text)
    }
}

impl ResultFile {
    fn time_ref(&mut self) -> Result<&[f64], JsError> {
        if self.time.is_none() {
            let t = self.reader.trajectory(self.time_name).filter(|t| !t.is_empty()).ok_or_else(|| js_err("Error getting time"))?;
            self.time = Some(t);
        }
        Ok(self.time.as_deref().unwrap())
    }

    /// `vars` (every variable when empty), without time, which is always written.
    fn selection(&self, vars: Vec<String>) -> Vec<String> {
        let vars = if vars.is_empty() { self.variables() } else { vars };
        vars.into_iter().filter(|v| v != self.time_name).collect()
    }
}

/// `intervals + 1` equidistant points over the time span, or `None` to keep
/// the file's own sample points.
fn resample_grid(time: &[f64], intervals: u32) -> Option<Vec<f64>> {
    if intervals == 0 {
        return None;
    }
    let (start, stop) = (time[0], time[time.len() - 1]);
    Some((0..=intervals).map(|j| if j == intervals { stop } else { start + (stop - start) * f64::from(j) / f64::from(intervals) }).collect())
}

/// Linear interpolation of `vals` (over the monotonic `time`) at each grid point.
fn resample(time: &[f64], vals: &[f64], grid: &[f64]) -> Vec<f64> {
    if vals.len() < 2 {
        return vec![vals.first().copied().unwrap_or(0.0); grid.len()];
    }
    let mut k = 0usize;
    grid.iter()
        .map(|&t| {
            while k + 2 < time.len() && time[k + 1] < t {
                k += 1;
            }
            let (t0, t1) = (time[k], time[k + 1]);
            if t1 == t0 { vals[k] } else { vals[k] + (t - t0) / (t1 - t0) * (vals[k + 1] - vals[k]) }
        })
        .collect()
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

struct Pair<'a> {
    actual: &'a mut ResultFile,
    reference: &'a mut ResultFile,
    offset: usize,
    offset_ref: usize,
}

impl Pair<'_> {
    fn new<'a>(actual: &'a mut ResultFile, reference: &'a mut ResultFile) -> Result<Pair<'a>, JsError> {
        let offset = leading_dup_count(actual.time_ref()?);
        let offset_ref = leading_dup_count(reference.time_ref()?);
        Ok(Pair { actual, reference, offset, offset_ref })
    }

    /// Both trajectories of `var`, leading duplicates dropped; `None` when
    /// either file lacks it.
    fn data(&mut self, var: &str) -> Option<(Vec<f64>, Vec<f64>)> {
        let var = var.replace('"', "");
        let mut dataref = self.reference.reader.trajectory(&var).filter(|d| !d.is_empty())?;
        let mut data = self.actual.reader.trajectory(&var).filter(|d| !d.is_empty())?;
        drop_leading_dups(&mut data, self.offset);
        drop_leading_dups(&mut dataref, self.offset_ref);
        Some((data, dataref))
    }
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
    let vars = if vars.is_empty() { reference.reader.vars_filter_aliases() } else { vars };
    let mut pair = Pair::new(actual, reference)?;
    let mut out = Vec::new();
    for var in vars {
        let Some((data, dataref)) = pair.data(&var) else { continue };
        let mut timeref = pair.reference.time.clone().unwrap();
        let cmp = cmp_data_tubes(pair.actual.time.as_ref().unwrap(), &mut timeref, &dataref, &data, reltol, range_delta, reltol_diff_min_max);
        if cmp.differs() {
            out.push(var);
        }
    }
    Ok(out)
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
    let mut pair = Pair::new(actual, reference)?;
    let (data, dataref) = pair.data(var).ok_or_else(|| js_err(format!("{var} is not in both files")))?;
    let time = pair.actual.time.clone().unwrap();
    let mut timeref = pair.reference.time.clone().unwrap();
    let cmp = cmp_data_tubes(&time, &mut timeref, &dataref, &data, reltol, range_delta, reltol_diff_min_max);
    let n = cmp.n;
    let cut = |mut v: Vec<f64>| {
        v.truncate(n);
        v
    };
    Ok(TubeDiff {
        differs: cmp.differs(),
        time: cut(timeref),
        reference: cut(dataref),
        actual: cut(cmp.calibrated),
        high: cut(cmp.high),
        low: cut(cmp.low),
        error: cmp.error.unwrap_or_default(),
        actual_time: time,
        actual_original: data,
        abstol: cmp.abstol,
    })
}
