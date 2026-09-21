//! Process-wide state: the translated models by prefix, the FMU kernels, and
//! the last run's captured result series (the web plot API reads them).

use super::*;

/// Process-wide table of prepared models, keyed by file-name prefix. Populated
/// by `translateModel` (during `callTargetTemplates`) and read by
/// `runSimulation` (during `simulate`) in the same process.
pub(super) fn sim_models() -> &'static Mutex<HashMap<String, Arc<SimModel>>> {
    static MODELS: OnceLock<Mutex<HashMap<String, Arc<SimModel>>>> = OnceLock::new();
    MODELS.get_or_init(|| Mutex::new(HashMap::new()))
}

/// A model kernel a wasm FMU can be built around. Only kernels an export can
/// actually use are kept, so finding one is the whole test.
pub(super) struct FmuKernel {
    pub(super) model: Arc<SimModel>,
    /// Reaches the kernel's embedded metadata, so a different one cannot reuse it.
    pub(super) cs_method: String,
    pub(super) fmi_solver_flags: String,
}

/// Kept by [`translateFmu`] so the export that follows links this kernel rather
/// than lowering it again. Keyed by file-name prefix.
pub(super) fn fmu_kernels() -> &'static Mutex<HashMap<String, Arc<FmuKernel>>> {
    static KERNELS: OnceLock<Mutex<HashMap<String, Arc<FmuKernel>>>> = OnceLock::new();
    KERNELS.get_or_init(|| Mutex::new(HashMap::new()))
}

/// Where a captured signal's values come from: the result file under the
/// signal's own name, or one time-invariant value.
#[derive(Clone, Copy)]
pub enum SeriesData {
    File,
    Scalar(f64),
}

/// One captured result signal. Its values are read out of the result file on
/// demand ([`CapturedSim::values`]).
pub struct SimSeries {
    pub name: String,
    pub comment: String,
    pub unit: String,
    /// The unit it is preferably plotted in, a display unit of `unit`.
    pub display_unit: String,
    /// FMI's `relativeQuantity`: a difference in the unit, so a conversion to a
    /// display unit scales it but adds no offset.
    pub relative_quantity: bool,
    /// Time-invariant (parameter, constant, or computed once at initialization) —
    /// the web simulator hides these from the default plot ("all non-constant vars").
    pub constant: bool,
    /// This signal aliases the same underlying data as an earlier series (e.g.
    /// `der(h)` and `v` when `v = der(h)`): plotting one of them suffices.
    pub alias: bool,
    pub data: SeriesData,
}

/// A parameter's value after the run, with the metadata a host needs to show it
/// as an editable initial condition.
pub struct CapturedParam {
    pub name: String,
    pub comment: String,
    pub unit: String,
    pub display_unit: String,
    pub relative_quantity: bool,
    pub value: f64,
    /// Enumeration literal names (1-based index → name), empty for non-enum.
    pub enum_names: Vec<String>,
}

/// The last run's results: the per-signal metadata over the result file the run
/// wrote, which a host (the web simulator) reads a signal out of by name.
/// `series` excludes `time`.
pub struct CapturedSim {
    pub model_name: String,
    pub start_time: f64,
    pub stop_time: f64,
    pub result_file: String,
    n_rows: usize,
    /// Opened on the first read and kept for the rest.
    reader: Mutex<Option<openmodelica_result_files::ResultFile>>,
    pub series: Vec<SimSeries>,
    pub params: Vec<CapturedParam>,
    /// The units the signals and parameters name, defined: what a host needs to
    /// plot or edit a value in its display unit.
    pub units: Vec<openmodelica_sim_meta::UnitDef>,
    /// Solver counters, so a host with no stdout can tell a run that did more work
    /// from one that did the same work slower.
    pub stats: SolveStats,
}

impl CapturedSim {
    pub fn n_rows(&self) -> usize {
        self.n_rows
    }

    /// Run `f` over the result file, opening it the first time.
    fn with_file<R>(&self, f: impl FnOnce(&mut openmodelica_result_files::ResultFile) -> R) -> Option<R> {
        let mut cell = self.reader.lock().unwrap_or_else(|e| e.into_inner());
        if cell.is_none() {
            *cell = openmodelica_result_files::ResultFile::open(&self.result_file).ok();
        }
        cell.as_mut().map(f)
    }

    /// The independent `time` column.
    pub fn time(&self) -> Vec<f64> {
        self.with_file(|r| r.time().map(<[f64]>::to_vec).unwrap_or_default()).unwrap_or_default()
    }

    /// The result file as `format`. Its own format is handed back unconverted,
    /// so that download loses nothing; the others drop the String variables they
    /// cannot hold.
    pub fn result_as(&self, format: &str) -> std::result::Result<Vec<u8>, String> {
        if self.result_file.rsplit_once('.').is_some_and(|(_, s)| s == format) {
            return openmodelica_wasi::fs::read(&self.result_file).map_err(|e| e.to_string());
        }
        self.with_file(|r| r.write(format, Vec::new(), 0, false))
            .unwrap_or_else(|| Err(format!("cannot read the result file {}", self.result_file)))
    }

    /// The values of `series[index]` over the run (length 1 for a time-invariant
    /// signal), or `None` when out of range.
    pub fn values(&self, index: usize) -> Option<Vec<f64>> {
        let v = self.series.get(index)?;
        Some(match v.data {
            SeriesData::File => {
                let name = v.name.clone();
                self.with_file(|r| r.trajectory(&name).unwrap_or_default()).unwrap_or_default()
            }
            SeriesData::Scalar(v) => vec![v],
        })
    }
}

fn last_sim() -> &'static Mutex<Option<CapturedSim>> {
    static LAST: OnceLock<Mutex<Option<CapturedSim>>> = OnceLock::new();
    LAST.get_or_init(|| Mutex::new(None))
}

/// Stash a finished run's per-signal metadata and the result file's layout for
/// the host to read directly.
pub(super) fn capture_last_sim(
    model: &SimModel,
    written: Written,
    params: &[f64],
    stats: &SolveStats,
    keep: &[bool],
    result_file: &str,
) {
    let Written { n_rows, first_row } = written;
    let unit_of = |name: &str| model.var_units.get(name).cloned().unwrap_or_default();
    let mut series = Vec::new();
    let mut param_idx = 0usize;
    // A signal aliases an earlier one when it reads the same underlying data: the
    // same result column, or the same parameter slot (the `.mat`'s `dataInfo`
    // aliasing — several names, one stored column). Distinct columns are distinct
    // signals even when an equation keeps them near-equal (`der(h) = v` differs at
    // event rows), so both are plotted. First occurrence is canonical.
    let mut seen_cols = HashSet::new();
    let mut seen_param_offs = HashSet::new();
    let mut param_value_by_off: HashMap<u32, f64> = HashMap::new();
    // Row 0 of every signal, for the start values of the editable parameters.
    let mut row0_by_name: HashMap<&str, f64> = HashMap::new();
    for (v, &kept) in model.result_vars.iter().zip(keep) {
        let (alias, row0, data) = match &v.kind {
            ResultKind::Time => continue,
            ResultKind::Column { col, negate } => {
                let col = *col as usize;
                let row0 = negate.apply_f64(first_row.get(col).copied().unwrap_or(0.0));
                // Both writers store an `unvarying` column as a parameter, so it
                // is its row-0 value rather than a trajectory.
                let data = Some(if v.unvarying { SeriesData::Scalar(row0) } else { SeriesData::File });
                (!seen_cols.insert(col), row0, data)
            }
            ResultKind::Param { off, negate, .. } => {
                let raw = params.get(param_idx).copied().unwrap_or(0.0);
                param_idx += 1;
                param_value_by_off.entry(*off).or_insert(raw);
                let value = negate.apply_f64(raw);
                (!seen_param_offs.insert(*off), value, Some(SeriesData::Scalar(value)))
            }
            ResultKind::Const { value } => (false, *value, Some(SeriesData::Scalar(*value))),
        };
        row0_by_name.entry(v.name.as_str()).or_insert(row0);
        if let (true, Some(data)) = (kept, data) {
            series.push(SimSeries {
                name: v.name.clone(),
                comment: v.comment.clone(),
                unit: unit_of(&v.name),
                display_unit: v.display_unit.clone(),
                relative_quantity: v.relative_quantity,
                constant: matches!(data, SeriesData::Scalar(_)),
                alias,
                data,
            });
        }
    }
    // A start value shows the state's t0 value; a plain parameter shows its slot.
    let params: Vec<CapturedParam> = model
        .editable_params
        .iter()
        .filter(|p| !p.is_string)
        .map(|p| CapturedParam {
            name: p.name.clone(),
            comment: p.comment.clone(),
            unit: p.unit.clone(),
            display_unit: p.display_unit.clone(),
            relative_quantity: p.relative_quantity,
            value: if p.is_start {
                row0_by_name.get(p.name.as_str()).copied().unwrap_or(0.0)
            } else {
                param_value_by_off.get(&p.off).copied().unwrap_or(0.0)
            },
            enum_names: p.enum_names.clone(),
        })
        .collect();
    *last_sim().lock().unwrap_or_else(|e| e.into_inner()) = Some(CapturedSim {
        model_name: model.model_name.clone(),
        start_time: model.start_time,
        stop_time: model.stop_time,
        result_file: result_file.to_string(),
        n_rows,
        reader: Mutex::new(None),
        series,
        params,
        // Only what the model declares: a reader merges in the predefined
        // display units of the same name.
        units: model.meta.units.clone(),
        stats: stats.clone(),
    });
}

/// [`CapturedSim::result_as`] for a host, recording a failure for
/// `getErrorString()`.
pub fn last_sim_result_as(format: &str) -> Option<Vec<u8>> {
    match with_last_sim(|sim| sim.result_as(format))? {
        Ok(bytes) => Some(bytes),
        Err(e) => {
            record_error(format!("wasm-jit: {e}"));
            None
        }
    }
}

/// Run `f` with the last captured simulation results, if any. Lets a host read
/// signal data directly out of the runtime instead of parsing a result file.
pub fn with_last_sim<R>(f: impl FnOnce(&CapturedSim) -> R) -> Option<R> {
    last_sim().lock().unwrap_or_else(|e| e.into_inner()).as_ref().map(f)
}

/// Write `bytes` to `path`: the OS filesystem natively, or the in-memory VFS on
/// wasm (where there is no filesystem — the `.wasm` dump, `.log` and result file
/// land there for the JS host / `getSimulationResult` to read back).
pub(super) fn write_output(path: &str, bytes: &[u8]) -> std::io::Result<()> {
    openmodelica_wasi::fs::write(path, bytes)
}

/// C's `fileSize(outputFilename)`, which the `+profiling` report quotes: `-1` when
/// the file is not there.
pub(super) fn output_size(path: &str) -> i64 {
    openmodelica_wasi::fs::len(path).map(|n| n as i64).unwrap_or(-1)
}
