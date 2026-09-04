//! One result file as the OMPlot page, the `omplot` command and the C ABI see
//! it: open by suffix, list and read variables, compare two files the way
//! `diffSimulationResults` does, write back out as `.mat`, `.arrow` or `.csv`.

use std::collections::HashMap;

use openmodelica_arrow_writer::units::{self, UnitDef};
use openmodelica_arrow_writer::{Affine, ArrowKind, ArrowVar, ColTy, FileMeta, VarTy};
use openmodelica_mat_writer::{MatKind, MatVar, Neg, Precision, write_mat4};

use crate::cmp::{cmp_data_tubes, format_g_prec15};
use crate::{OpenError, ResultReader, drop_leading_dups, leading_dup_count, time_var_name};

pub struct ResultFile {
    pub reader: ResultReader,
    time_name: &'static str,
    time: Option<Vec<f64>>,
}

impl ResultFile {
    /// `path` selects the format by suffix.
    pub fn open(path: &str) -> Result<ResultFile, String> {
        let base = path.rsplit(['/', '\\']).next().unwrap_or(path);
        let reader = ResultReader::open(path).map_err(|e| match e {
            OpenError::UnknownSuffix => format!("Unknown result-file suffix of file '{base}'"),
            OpenError::Failed(msg) => format!("Failed to open simulation result {base}: {msg}"),
        })?;
        let time_name = time_var_name(&reader.vars_filter_aliases());
        Ok(ResultFile { reader, time_name, time: None })
    }

    /// Every variable name in the file, parameters and aliases included.
    pub fn variables(&self) -> Vec<String> {
        match &self.reader {
            r @ (ResultReader::Mat(_) | ResultReader::Arrow(_)) => r.table().unwrap().all_info().iter().map(|v| v.name.clone()).collect(),
            ResultReader::Plt(r) => r.variables().into_iter().map(str::to_owned).collect(),
            ResultReader::Csv(r) => r.variables.iter().filter(|v| !v.is_empty()).cloned().collect(),
        }
    }

    /// The variables [`diff_all`] compares when given none: the reference's real
    /// (non-alias) variables and parameters.
    pub fn compared_variables(&self) -> Vec<String> {
        self.reader.vars_filter_aliases()
    }

    fn info<R>(&self, var: &str, f: impl FnOnce(&dyn crate::ResultTable, usize) -> R) -> Option<R> {
        let t = self.reader.table()?;
        Some(f(t, t.find_var(var)?))
    }

    pub fn has_variable(&self, var: &str) -> bool {
        match self.reader.table() {
            Some(t) => t.find_var(var).is_some(),
            None => self.variables().iter().any(|v| v == var),
        }
    }

    pub fn description(&self, var: &str) -> String {
        self.info(var, |t, i| t.all_info()[i].descr.clone()).unwrap_or_default()
    }

    /// The variable's unit (`.arrow` files carry one; the others give "").
    pub fn unit(&self, var: &str) -> String {
        self.info(var, |t, i| t.unit(i).0.to_owned()).unwrap_or_default()
    }

    pub fn display_unit(&self, var: &str) -> String {
        self.info(var, |t, i| t.unit(i).1.to_owned()).unwrap_or_default()
    }

    /// Every unit the file's variables name, defined — the conversions a plot
    /// needs to show a value in its display unit. Empty for a format with no
    /// unit table.
    pub fn unit_defs(&self) -> Vec<UnitDef> {
        match &self.reader {
            ResultReader::Arrow(r) => r.unit_defs(),
            _ => Vec::new(),
        }
    }

    /// The definition of one unit, the predefined set included.
    pub fn unit_def(&self, name: &str) -> Option<UnitDef> {
        match &self.reader {
            ResultReader::Arrow(r) => r.unit_def(name),
            _ => units::predefined(name),
        }
    }

    /// Whether the variable is a difference in its unit rather than an absolute
    /// value, so a display-unit conversion must not apply the offset.
    pub fn relative_quantity(&self, var: &str) -> bool {
        self.info(var, |t, i| t.relative_quantity(i)).unwrap_or(false)
    }

    /// Whether the variable is discrete-time, which in an `.arrow` file is the
    /// column's run-end encoding rather than a metadata key.
    pub fn discrete(&self, var: &str) -> bool {
        self.info(var, |t, i| t.discrete(i)).unwrap_or(false)
    }

    /// `Real`, `Integer`, `Boolean`, `String` or `enumeration`; `Real` for a
    /// format without types.
    pub fn var_type(&self, var: &str) -> String {
        self.info(var, |t, i| t.var_type(i).to_owned()).unwrap_or_else(|| "Real".to_owned())
    }

    pub fn is_parameter(&self, var: &str) -> bool {
        self.info(var, |t, i| t.all_info()[i].isParam).unwrap_or(false)
    }

    pub fn nrows(&self) -> usize {
        self.reader.nrows().unwrap_or(0)
    }

    pub fn time_name(&self) -> &str {
        self.time_name
    }

    pub fn start_time(&mut self) -> f64 {
        match self.reader.table_mut() {
            Some(t) => t.start_time(),
            None => self.time().map_or(f64::NAN, |t| t.first().copied().unwrap_or(f64::NAN)),
        }
    }

    pub fn stop_time(&mut self) -> f64 {
        match self.reader.table_mut() {
            Some(t) => t.stop_time(),
            None => self.time().map_or(f64::NAN, |t| t.last().copied().unwrap_or(f64::NAN)),
        }
    }

    pub fn time(&mut self) -> Result<&[f64], String> {
        if self.time.is_none() {
            let t = self.reader.trajectory(self.time_name).filter(|t| !t.is_empty()).ok_or("Error getting time")?;
            self.time = Some(t);
        }
        Ok(self.time.as_deref().unwrap())
    }

    pub fn trajectory(&mut self, var: &str) -> Option<Vec<f64>> {
        self.reader.trajectory(var)
    }

    /// A String or enumeration variable's text per row (`.arrow` only; a
    /// parameter repeats its value, an enumeration gives its literals).
    pub fn strings(&mut self, var: &str) -> Option<Vec<String>> {
        let nrows = self.nrows();
        let t = self.reader.table_mut()?;
        let i = t.find_var(var)?;
        let (is_param, index) = t.all_info().get(i).map(|info| (info.isParam, info.index))?;
        let literals = t.enumeration(i);
        if is_param {
            let text = match &literals {
                Some(l) => literal(l, *t.params().get(index.unsigned_abs() as usize - 1)?),
                None => t.param_string(i)?,
            };
            return Some(vec![text; nrows.max(1)]);
        }
        match (t.read_strings(index), literals) {
            (Some(s), _) => Some(s),
            (None, Some(l)) => Some(t.read_vals(index)?.into_iter().map(|v| literal(&l, v)).collect()),
            (None, None) => None,
        }
    }

    /// The text of String `var` at `time`: a String changes only at events, so
    /// it is the row at or before `time`.
    pub fn string_at(&mut self, var: &str, time: f64) -> Option<String> {
        let strings = self.strings(var)?;
        let row = self.time().ok()?.iter().rposition(|&t| t <= time).unwrap_or(0);
        strings.get(row).cloned()
    }

    /// `val(var, time)`: interpolated at `time`, a parameter's value anywhere.
    pub fn value_at(&mut self, var: &str, time: f64) -> Option<f64> {
        if let Some(t) = self.reader.table_mut() {
            let i = t.find_var(var)?;
            return t.val(i, time);
        }
        let times = self.time().ok()?.to_vec();
        let vals = self.trajectory(var)?;
        Some(resample(&times, &vals, &[time])[0])
    }

    /// The file written as the format `suffix` names (`mat`, `arrow`, `csv`),
    /// with `vars` (all of them when empty), optionally resampled onto
    /// `intervals` equidistant steps; `single` stores the reals as f32.
    pub fn write(&mut self, suffix: &str, vars: Vec<String>, intervals: u32, single: bool) -> Result<Vec<u8>, String> {
        match suffix.trim_start_matches('.') {
            "mat" => self.write_mat(vars, intervals, single),
            "arrow" => self.write_arrow(vars, intervals, single),
            "csv" => self.write_csv(vars, intervals).map(String::into_bytes),
            other => Err(format!("Unknown result-file suffix '{other}'")),
        }
    }

    /// The file as MATLAB v4. Aliases of one column in a `.mat` or `.arrow`
    /// source stay one column.
    pub fn write_mat(&mut self, vars: Vec<String>, intervals: u32, single: bool) -> Result<Vec<u8>, String> {
        let p = self.plan_columns(vars, intervals)?;
        let mat_vars: Vec<MatVar> = p.signals.iter().map(|sg| MatVar { name: &sg.name, comment: &sg.descr, kind: sg.kind, unvarying: false }).collect();
        let precision = if single { Precision::Single } else { Precision::Double };
        Ok(write_mat4(&mat_vars, p.start, p.stop, &p.rows, p.n_reals as u32, &p.params, precision))
    }

    /// The file as Arrow IPC; units and types carry over from an `.arrow` source.
    pub fn write_arrow(&mut self, vars: Vec<String>, intervals: u32, single: bool) -> Result<Vec<u8>, String> {
        let p = self.plan_columns(vars, intervals)?;
        let real = if single { ColTy::F32 } else { ColTy::F64 };
        let mut col_types = vec![real; p.n_reals];
        let arrow_vars: Vec<ArrowVar> = p
            .signals
            .iter()
            .map(|sg| {
                let ty = VarTy::from_name(&sg.ty);
                let affine = |n: Neg| match n {
                    Neg::None => Affine::IDENTITY,
                    Neg::Arith => Affine::NEGATE,
                    Neg::Not => Affine::NOT,
                };
                let kind = match sg.kind {
                    MatKind::Time => ArrowKind::Time,
                    MatKind::Column { col, negate } => {
                        if negate == Neg::None {
                            col_types[col as usize] = match ty {
                                VarTy::Integer => ColTy::I32,
                                VarTy::Boolean => ColTy::Bool,
                                _ => real,
                            };
                        }
                        ArrowKind::Column { col, affine: affine(negate) }
                    }
                    MatKind::Param { negate } => ArrowKind::Param { affine: affine(negate) },
                    MatKind::Const { value } => ArrowKind::Const { value },
                };
                ArrowVar { name: &sg.name, comment: &sg.descr, unit: &sg.unit, display_unit: &sg.display_unit, relative_quantity: sg.relative_quantity, ty, discrete: sg.discrete, kind, unvarying: false, enumeration: sg.enumeration.as_deref() }
            })
            .collect();
        let units = units::declared(self.unit_defs());
        Ok(openmodelica_arrow_writer::write_arrow(&arrow_vars, &p.rows, p.n_reals as u32, &p.params, &col_types, openmodelica_arrow_writer::no_strings(), &FileMeta { span: Some((p.start, p.stop)), units: &units }))
    }

    /// The selected signals over the distinct columns they read (time first),
    /// with the rows they need — the common part of the column-store writers.
    fn plan_columns(&mut self, vars: Vec<String>, intervals: u32) -> Result<ColumnPlan, String> {
        let vars = self.selection(vars);
        let time = self.time()?.to_vec();
        let (start, stop) = (time[0], time[time.len() - 1]);
        let grid = resample_grid(&time, intervals);
        let n_rows = grid.as_ref().map_or(time.len(), Vec::len);

        let time_unit = self.unit(self.time_name);
        let mut signals: Vec<Signal> = vec![Signal {
            name: self.time_name.to_owned(),
            descr: String::new(),
            unit: if time_unit.is_empty() { "s".to_owned() } else { time_unit },
            display_unit: String::new(),
            relative_quantity: false,
            discrete: false,
            ty: "Real".to_owned(),
            enumeration: None,
            kind: MatKind::Time,
        }];
        let mut columns: Vec<Vec<f64>> = Vec::new();
        let mut params: Vec<f64> = Vec::new();
        let mut column_of: HashMap<u32, u32> = HashMap::new();
        for var in &vars {
            let descr = self.description(var);
            let relative_quantity = self.relative_quantity(var);
            let discrete = self.discrete(var);
            let (storage, unit, display_unit, ty, enumeration) = match self.info(var, |t, i| {
                let (u, du) = t.unit(i);
                ((t.all_info()[i].isParam, t.all_info()[i].index), u.to_owned(), du.to_owned(), t.var_type(i).to_owned(), t.enumeration(i))
            }) {
                Some((st, u, du, ty, en)) => (Some(st), u, du, ty, en),
                None => (None, String::new(), String::new(), "Real".to_owned(), None),
            };
            let read = |me: &mut Self| me.reader.trajectory(var).ok_or_else(|| format!("Could not read variable {var}"));
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
            signals.push(Signal { name: var.clone(), descr, unit, display_unit, relative_quantity, discrete, ty, enumeration, kind });
        }
        let n_reals = 1 + columns.len();
        let mut rows = Vec::with_capacity(n_rows * n_reals);
        for r in 0..n_rows {
            rows.push(grid.as_ref().map_or(time[r], |g| g[r]));
            for c in &columns {
                rows.push(c[r]);
            }
        }
        Ok(ColumnPlan { signals, rows, n_reals, params, start, stop })
    }

    /// The file as CSV with `vars` (all of them when empty): one `time` column
    /// and one per variable, as `filterSimulationResults` writes it.
    pub fn write_csv(&mut self, vars: Vec<String>, intervals: u32) -> Result<String, String> {
        let vars = self.selection(vars);
        let time = self.time()?.to_vec();
        let grid = resample_grid(&time, intervals);
        let mut cols = Vec::with_capacity(vars.len());
        for var in &vars {
            let vals = self.reader.trajectory(var).ok_or_else(|| format!("Could not read variable {var}"))?;
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

    /// `vars` (every variable when empty), without time, which is always written.
    fn selection(&self, vars: Vec<String>) -> Vec<String> {
        let vars = if vars.is_empty() { self.variables() } else { vars };
        vars.into_iter().filter(|v| v != self.time_name).collect()
    }
}

/// One output signal of [`ResultFile::plan_columns`].
struct Signal {
    name: String,
    descr: String,
    unit: String,
    display_unit: String,
    relative_quantity: bool,
    discrete: bool,
    ty: String,
    enumeration: Option<Vec<String>>,
    kind: MatKind,
}

struct ColumnPlan {
    signals: Vec<Signal>,
    /// Row-major, `n_reals` wide, time first.
    rows: Vec<f64>,
    n_reals: usize,
    params: Vec<f64>,
    start: f64,
    stop: f64,
}

/// `intervals + 1` equidistant points over the time span, or `None` to keep
/// the file's own sample points.
pub fn resample_grid(time: &[f64], intervals: u32) -> Option<Vec<f64>> {
    if intervals == 0 {
        return None;
    }
    let (start, stop) = (time[0], time[time.len() - 1]);
    Some((0..=intervals).map(|j| if j == intervals { stop } else { start + (stop - start) * f64::from(j) / f64::from(intervals) }).collect())
}

/// Linear interpolation of `vals` (over the monotonic `time`) at each grid point.
pub fn resample(time: &[f64], vals: &[f64], grid: &[f64]) -> Vec<f64> {
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

/// The tolerances of `diffSimulationResults`, with its defaults.
#[derive(Clone, Copy, Debug)]
pub struct Tolerances {
    pub reltol: f64,
    pub reltol_diff_min_max: f64,
    pub range_delta: f64,
}

impl Default for Tolerances {
    fn default() -> Tolerances {
        Tolerances { reltol: 1e-3, reltol_diff_min_max: 1e-4, range_delta: 0.002 }
    }
}

/// One variable's comparison, on the reference timeline (`n` points of it are
/// compared; `error` is empty when the signal stayed inside the tube).
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
    fn new<'a>(actual: &'a mut ResultFile, reference: &'a mut ResultFile) -> Result<Pair<'a>, String> {
        let offset = leading_dup_count(actual.time()?);
        let offset_ref = leading_dup_count(reference.time()?);
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
pub fn diff_all(actual: &mut ResultFile, reference: &mut ResultFile, vars: Vec<String>, tol: Tolerances) -> Result<Vec<String>, String> {
    let vars = if vars.is_empty() { reference.reader.vars_filter_aliases() } else { vars };
    let mut pair = Pair::new(actual, reference)?;
    let mut out = Vec::new();
    for var in vars {
        let Some((data, dataref)) = pair.data(&var) else { continue };
        let mut timeref = pair.reference.time.clone().unwrap();
        let cmp = cmp_data_tubes(pair.actual.time.as_ref().unwrap(), &mut timeref, &dataref, &data, tol.reltol, tol.range_delta, tol.reltol_diff_min_max);
        if cmp.differs() {
            out.push(var);
        }
    }
    Ok(out)
}

/// `diffSimulationResultsHtml` as data: one variable's tube comparison.
pub fn diff_variable(actual: &mut ResultFile, reference: &mut ResultFile, var: &str, tol: Tolerances) -> Result<TubeDiff, String> {
    let mut pair = Pair::new(actual, reference)?;
    let (data, dataref) = pair.data(var).ok_or_else(|| format!("{var} is not in both files"))?;
    let time = pair.actual.time.clone().unwrap();
    let mut timeref = pair.reference.time.clone().unwrap();
    let cmp = cmp_data_tubes(&time, &mut timeref, &dataref, &data, tol.reltol, tol.range_delta, tol.reltol_diff_min_max);
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

/// The literal a 1-based enumeration value names ("" outside the range).
fn literal(literals: &[String], value: f64) -> String {
    let k = value as i64 - 1;
    (k >= 0).then(|| literals.get(k as usize)).flatten().cloned().unwrap_or_default()
}
