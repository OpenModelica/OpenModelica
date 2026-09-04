//! Result files (`.mat` v4, `.arrow`, `.csv`, `.plt`) as one reader, and the
//! comparison `diffSimulationResults` runs on two of them.

pub mod arrow;
pub mod cmp;
pub mod file;
pub mod readers;

pub use arrow::ArrowReader;
pub use file::{ResultFile, Tolerances, TubeDiff};
pub use openmodelica_mat_reader::{MatReader, ResultTable};
pub use readers::{CsvReader, PltReader, PltVal};

/// The result-file reader behind every entry point, dispatched by file
/// suffix exactly like `SimulationResultsImpl__openFile` (.mat / .arrow / .plt /
/// .csv; anything else is the `Unknown result-file suffix` error).
pub enum ResultReader {
    Mat(MatReader),
    Arrow(ArrowReader),
    Plt(PltReader),
    Csv(CsvReader),
}

pub enum OpenError {
    UnknownSuffix,
    Failed(String),
}

impl ResultReader {
    pub fn open(filename: &str) -> Result<ResultReader, OpenError> {
        if filename.ends_with(".mat") {
            MatReader::open(filename).map(ResultReader::Mat).map_err(OpenError::Failed)
        } else if filename.ends_with(".arrow") {
            ArrowReader::open(filename).map(ResultReader::Arrow).map_err(OpenError::Failed)
        } else if filename.ends_with(".plt") {
            PltReader::open(filename).map(ResultReader::Plt).map_err(OpenError::Failed)
        } else if filename.ends_with(".csv") {
            CsvReader::open(filename).map(ResultReader::Csv).map_err(OpenError::Failed)
        } else {
            Err(OpenError::UnknownSuffix)
        }
    }

    /// The column-store view of a `.mat` or `.arrow` file; `None` for the others.
    pub fn table(&self) -> Option<&dyn ResultTable> {
        match self {
            ResultReader::Mat(r) => Some(r),
            ResultReader::Arrow(r) => Some(r),
            _ => None,
        }
    }

    pub fn table_mut(&mut self) -> Option<&mut dyn ResultTable> {
        match self {
            ResultReader::Mat(r) => Some(r),
            ResultReader::Arrow(r) => Some(r),
            _ => None,
        }
    }

    /// Sample-point count: `nrows` / `numsteps` / the PLT `#IntervalSize`
    /// (`None` when that line is missing or zero).
    pub fn nrows(&self) -> Option<usize> {
        match self {
            ResultReader::Mat(r) => Some(r.nrows),
            ResultReader::Arrow(r) => Some(r.nrows),
            ResultReader::Csv(r) => Some(r.numsteps),
            ResultReader::Plt(r) => r.interval_size(),
        }
    }

    /// Load the whole time-variant matrix before reading many of its columns
    /// (C's `omc_matlab4_read_all_vals`); the other formats are in memory already.
    pub fn read_all(&mut self) {
        if let ResultReader::Mat(reader) = self {
            reader.read_all();
        }
    }

    /// C `getData` → `SimulationResultsImpl__readDataset` for a single
    /// variable: its full trajectory over all sample points (a constant vector
    /// for a parameter), or `None` if the variable cannot be read.
    pub fn trajectory(&mut self, varname: &str) -> Option<Vec<f64>> {
        if let Some(reader) = self.table_mut() {
            let idx = reader.find_var(varname)?;
            let (is_param, index) = {
                let info = &reader.all_info()[idx];
                (info.isParam, info.index)
            };
            return if is_param {
                let absp = index.unsigned_abs() as usize;
                if absp == 0 || absp > reader.params().len() {
                    return None;
                }
                let p = reader.params()[absp - 1];
                Some(vec![if index < 0 { -p } else { p }; reader.nrows()])
            } else {
                reader.read_vals(index)
            };
        }
        match self {
            ResultReader::Mat(_) | ResultReader::Arrow(_) => unreachable!(),
            ResultReader::Plt(reader) => {
                let nrows = reader.interval_size().unwrap_or(0);
                reader.dataset(varname, nrows)
            }
            ResultReader::Csv(reader) => reader.dataset(varname).map(<[f64]>::to_vec),
        }
    }

    /// C `SimulationResultsImpl__readVarsFilterAliases`: for MATLAB4 the names
    /// of all real (non-negated-alias) variables and parameters, one per storage
    /// index, in `allInfo` order; the other formats fall through to
    /// `readVars(readParameters=0, omcStyle=0)`.
    pub fn vars_filter_aliases(&self) -> Vec<String> {
        if let Some(reader) = self.table() {
            let mut seen_param = std::collections::HashSet::new();
            let mut seen_var = std::collections::HashSet::new();
            let mut out = Vec::new();
            for (i, info) in reader.all_info().iter().enumerate().rev() {
                if info.index <= 0 || reader.var_type(i) == "String" {
                    continue; // a negated alias has a positive twin; a String has no trajectory to compare
                }
                let seen = if info.isParam { &mut seen_param } else { &mut seen_var };
                if !seen.insert(info.index) {
                    continue;
                }
                out.push(info.name.clone());
            }
            out.reverse();
            return out;
        }
        match self {
            ResultReader::Mat(_) | ResultReader::Arrow(_) => unreachable!(),
            // Reverse document order — see readVariables.
            ResultReader::Plt(reader) => reader.variables().into_iter().rev().map(str::to_owned).collect(),
            ResultReader::Csv(reader) => {
                reader.variables.iter().filter(|v| !v.is_empty()).cloned().collect()
            }
        }
    }
}

/// C `getTimeVarName`: `"time"` unless only `"Time"` is present.
pub fn time_var_name<S: AsRef<str>>(allvars: &[S]) -> &'static str {
    for v in allvars {
        match v.as_ref() {
            "time" => return "time",
            "Time" => return "Time",
            _ => {}
        }
    }
    "time"
}

/// Count of leading equal timestamps (C `offset`/`offsetRef`): duplicated
/// initial points that get overwritten with the next value before comparing.
pub fn leading_dup_count(time: &[f64]) -> usize {
    let mut o = 0;
    while o + 1 < time.len() && time[o] == time[o + 1] {
        o += 1;
    }
    o
}

/// Overwrite the `offset` duplicated initial points with the value after them.
pub fn drop_leading_dups(data: &mut [f64], offset: usize) {
    for j in (1..=offset).rev() {
        data[j - 1] = data[j];
    }
}
