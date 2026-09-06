//! Sampling an FMU's variables and writing the result file.
//!
//! The columns are chosen the way a plot wants them: every numeric variable
//! that can change, grouped by type so one `fmi3Get*` call fetches a whole
//! group. Parameters and constants are read once, after initialization, and are
//! stored as the time-invariant values a simulated OpenModelica model writes, so
//! OMPlot and `omc-diff` read an FMU run unchanged. An alias (an FMI 3.0
//! `<Alias>` child, or an FMI 1.0 `alias` variable) shares its variable's
//! column. `.mat` and `.arrow` are written from the same columns; only the
//! latter has anywhere to put their types, units and `relativeQuantity`.
//!
//! With [`Recorder::stream_to`] each row goes to the file as it is sampled; a host
//! that reads the samples itself leaves it unset and uses [`Recorder::raw`].

use crate::api::Fmi3;
use crate::{Error, Result};
use openmodelica_fmi::{
    Alias, Causality, Dimension, ModelDescription, VarType, Variability, Variable,
};
use openmodelica_arrow_writer as arrow;
use openmodelica_fmi::description as fmi_unit;
use openmodelica_mat_writer as mat;
use std::collections::HashMap;
use std::io::{BufWriter, Seek, SeekFrom, Write};
use std::path::Path;

pub struct Column {
    pub name: String,
    pub description: String,
    pub unit: Option<String>,
    /// The unit it is preferably shown in, a display unit of `unit`.
    pub display_unit: Option<String>,
    /// FMI's `relativeQuantity`: a difference in the unit, so a conversion to a
    /// display unit scales it but adds no offset.
    pub relative_quantity: bool,
    pub ty: VarType,
    /// Changes only at events, so the Arrow file run-end encodes it.
    pub discrete: bool,
    pub causality: Causality,
    /// A continuous state (something differentiates it).
    pub is_state: bool,
}

/// A name that is not a column of its own: a time-invariant value, or an affine
/// function of a column. It carries the same metadata a column does, because the
/// result file records it per name.
pub struct Entry {
    pub name: String,
    pub description: String,
    pub unit: Option<String>,
    pub display_unit: Option<String>,
    pub relative_quantity: bool,
    pub ty: VarType,
    /// For an alias, the column (or parameter slot) it reads; unused otherwise.
    pub target: usize,
    pub negated: bool,
    /// A parameter's value, read once after initialization; 0 for an alias.
    pub value: f64,
}

/// Variables of one type, fetched together. An array variable is one value
/// reference but several values, so the columns it fills are a span.
struct Group {
    ty: VarType,
    vrs: Vec<u32>,
    /// Per value reference, where its first value lands (a column index inside
    /// a row, 1-based; 0 is time) and how many values it has.
    spans: Vec<(usize, usize)>,
    /// Total values the FMU returns for `vrs`.
    n_values: usize,
}

/// The result file the rows stream to, begun at the first sample (the writers
/// want the initial row).
struct Stream {
    out: FileOut,
    start_time: f64,
    stop_time: f64,
    units: Vec<fmi_unit::Unit>,
    kind: StreamKind,
}

enum StreamKind {
    Unbegun { arrow: bool },
    Mat(mat::Mat4Stream),
    Arrow(arrow::ArrowStream),
    Done,
}

/// The first write error is kept for `finish`.
struct FileOut {
    file: BufWriter<std::fs::File>,
    error: Option<std::io::Error>,
}

impl FileOut {
    fn note(&mut self, r: std::io::Result<()>) {
        if let Err(e) = r {
            self.error.get_or_insert(e);
        }
    }
}

impl mat::Out for FileOut {
    fn write(&mut self, bytes: &[u8]) {
        let r = self.file.write_all(bytes);
        self.note(r);
    }
    fn write_at(&mut self, pos: u64, bytes: &[u8]) {
        let r = (|| {
            let end = self.file.stream_position()?;
            self.file.seek(SeekFrom::Start(pos))?;
            self.file.write_all(bytes)?;
            self.file.seek(SeekFrom::Start(end))?;
            self.file.flush()
        })();
        self.note(r);
    }
}

impl arrow::Out for FileOut {
    fn write(&mut self, bytes: &[u8]) {
        let r = self.file.write_all(bytes);
        self.note(r);
    }
    fn flush(&mut self) {
        let r = self.file.flush();
        self.note(r);
    }
}

pub struct Recorder {
    pub columns: Vec<Column>,
    groups: Vec<Group>,
    /// Row-major, `1 + columns.len()` values per row, starting with the time.
    /// Empty when the rows stream to a file instead.
    rows: Vec<f64>,
    stream: Option<Stream>,
    n_rows: usize,
    row: Vec<f64>,
    /// The time-invariant signals, and their values once initialization is over.
    parameters: Vec<Entry>,
    param_groups: Vec<Group>,
    /// Aliases, each naming the column it reads.
    aliases: Vec<Entry>,
    /// Aliases of parameters, each naming its slot in `parameters`.
    param_aliases: Vec<Entry>,
    scratch: Vec<f64>,
}

/// A variable worth sampling: numeric, not an alias, and able to change.
fn is_recorded(v: &Variable) -> bool {
    v.ty.is_numeric()
        && v.alias == Alias::NoAlias
        && v.causality != Causality::Independent
        && !matches!(v.variability, Variability::Constant | Variability::Fixed)
        && v.causality != Causality::Parameter
        && v.causality != Causality::StructuralParameter
}

/// A variable that keeps one value for the whole run.
fn is_parameter(v: &Variable) -> bool {
    v.ty.is_numeric() && v.alias == Alias::NoAlias && v.causality != Causality::Independent && !is_recorded(v)
}

/// The FMI 1.0 alias variables by the value reference they share.
fn fmi1_aliases(md: &ModelDescription) -> HashMap<u32, Vec<&Variable>> {
    let mut map: HashMap<u32, Vec<&Variable>> = HashMap::new();
    for a in md.variables.iter().filter(|a| a.alias != Alias::NoAlias) {
        map.entry(a.value_reference).or_default().push(a);
    }
    map
}

/// `(name, description, negated)` for the names of `v` and its aliases the filter
/// keeps; the first names the column (the variable's own, else a non-negated
/// alias), the rest alias it. `None` when the filter keeps none.
fn names_kept<'a>(
    v: &'a Variable,
    fmi1: &HashMap<u32, Vec<&'a Variable>>,
    keep: &dyn Fn(&str) -> bool,
) -> Option<Vec<(&'a str, &'a str, bool)>> {
    let mut names: Vec<(&str, &str, bool)> = Vec::new();
    if keep(&v.name) {
        names.push((&v.name, v.description.as_deref().unwrap_or_default(), false));
    }
    names.extend(
        v.aliases
            .iter()
            .filter(|a| keep(&a.name))
            .map(|a| (a.name.as_str(), a.description.as_deref().unwrap_or_default(), false)),
    );
    names.extend(
        fmi1.get(&v.value_reference)
            .into_iter()
            .flatten()
            .filter(|a| a.ty == v.ty && keep(&a.name))
            .map(|a| (a.name.as_str(), a.description.as_deref().unwrap_or_default(), a.alias == Alias::NegatedAlias)),
    );
    // A negated alias cannot name the column: it would carry the wrong sign.
    let column = names.iter().position(|(_, _, negated)| !negated)?;
    names.swap(0, column);
    Some(names)
}

fn group_by_type(vars: &[(&Variable, usize, usize)]) -> Vec<Group> {
    let mut groups: Vec<Group> = Vec::new();
    for (v, col, len) in vars {
        let ty = v.ty.wire();
        match groups.iter_mut().find(|g| g.ty == ty) {
            Some(g) => {
                g.vrs.push(v.value_reference);
                g.spans.push((*col, *len));
                g.n_values += len;
            }
            None => groups.push(Group {
                ty,
                vrs: vec![v.value_reference],
                spans: vec![(*col, *len)],
                n_values: *len,
            }),
        }
    }
    groups
}

/// The extent of each of a variable's dimensions. A dimension given by a value
/// reference is a structural parameter, whose start value is the extent — the
/// FMU is not instantiated yet when the columns are laid out.
fn extents(md: &ModelDescription, v: &Variable) -> Vec<usize> {
    v.dimensions
        .iter()
        .map(|d| match d {
            Dimension::Fixed(k) => *k as usize,
            Dimension::ValueReference(vr) => md
                .variable_by_vr(*vr)
                .and_then(|s| s.start.as_ref())
                .and_then(|s| s.first_f64())
                .unwrap_or(1.0) as usize,
        })
        .collect()
}

/// `a` for a scalar, `a[1]`, `a[2,3]`, … for the elements of an array, in the
/// row-major order FMI flattens them in.
fn element_names(name: &str, dimensions: &[usize]) -> Vec<String> {
    if dimensions.is_empty() {
        return vec![name.to_string()];
    }
    let mut out = vec![String::new()];
    for extent in dimensions {
        out = out
            .iter()
            .flat_map(|prefix| {
                (1..=*extent).map(move |i| {
                    if prefix.is_empty() { i.to_string() } else { format!("{prefix},{i}") }
                })
            })
            .collect();
    }
    out.into_iter().map(|index| format!("{name}[{index}]")).collect()
}

/// One non-column name, taking its metadata from the variable it belongs to.
fn entry(name: String, description: &str, v: &Variable, target: usize, negated: bool, value: f64) -> Entry {
    Entry {
        name,
        description: description.to_string(),
        unit: v.unit.clone(),
        display_unit: v.display_unit.clone(),
        relative_quantity: v.relative_quantity,
        ty: v.ty,
        target,
        negated,
        value,
    }
}

impl Recorder {
    pub fn new(md: &ModelDescription, keep: Option<&dyn Fn(&str) -> bool>) -> Recorder {
        // Dropped here, not at write time: the sampling is the cost.
        let keep = |name: &str| keep.is_none_or(|k| k(name));
        let states: Vec<u32> = md.continuous_states();
        let mut columns = Vec::new();
        let mut recorded = Vec::new();
        let mut aliases = Vec::new();
        let fmi1 = fmi1_aliases(md);
        for v in md.variables.iter().filter(|v| is_recorded(v)) {
            let Some(names) = names_kept(v, &fmi1, &keep) else { continue };
            let (name, description, _) = names[0];
            let extents = extents(md, v);
            let first = columns.len() + 1; // column 0 is time
            for element in element_names(name, &extents) {
                columns.push(Column {
                    name: element,
                    description: description.to_string(),
                    unit: v.unit.clone(),
                    display_unit: v.display_unit.clone(),
                    relative_quantity: v.relative_quantity,
                    ty: v.ty,
                    discrete: v.variability == Variability::Discrete,
                    causality: v.causality,
                    is_state: states.contains(&v.value_reference),
                });
            }
            for (alias, description, negated) in &names[1..] {
                for (k, element) in element_names(alias, &extents).into_iter().enumerate() {
                    aliases.push(entry(element, description, v, first + k, *negated, 0.0));
                }
            }
            recorded.push((v, first, columns.len() + 1 - first));
        }
        let mut parameters = Vec::new();
        let mut param_aliases = Vec::new();
        let mut params = Vec::new();
        for v in md.variables.iter().filter(|v| is_parameter(v)) {
            let Some(names) = names_kept(v, &fmi1, &keep) else { continue };
            let (name, description, _) = names[0];
            let extents = extents(md, v);
            let first = parameters.len();
            let starts = match &v.start {
                Some(openmodelica_fmi::Start::Reals(r)) => r.clone(),
                Some(openmodelica_fmi::Start::Ints(i)) => i.iter().map(|v| *v as f64).collect(),
                Some(openmodelica_fmi::Start::Bools(b)) => {
                    b.iter().map(|v| *v as u8 as f64).collect()
                }
                _ => Vec::new(),
            };
            for (k, element) in element_names(name, &extents).into_iter().enumerate() {
                let start = starts.get(k).copied().unwrap_or(0.0);
                parameters.push(entry(element, description, v, 0, false, start));
            }
            for (alias, description, negated) in &names[1..] {
                for (k, element) in element_names(alias, &extents).into_iter().enumerate() {
                    param_aliases.push(entry(element, description, v, first + k, *negated, 0.0));
                }
            }
            params.push((v, first, parameters.len() - first));
        }
        let n_values = columns.len();
        Recorder {
            groups: group_by_type(&recorded),
            param_groups: group_by_type(&params),
            columns,
            rows: Vec::new(),
            stream: None,
            n_rows: 0,
            row: vec![0.0; n_values + 1],
            parameters,
            aliases,
            param_aliases,
            scratch: vec![0.0; n_values.max(1)],
        }
    }

    /// Stream the rows to `path` (`.arrow` by suffix, else `.mat`); [`Recorder::finish`]
    /// completes the file. Created here, so an unwritable path fails before the run.
    pub fn stream_to(&mut self, path: &Path, start_time: f64, stop_time: f64, units: &[fmi_unit::Unit]) -> Result<()> {
        let file = std::fs::File::create(path).map_err(|e| Error::Io(format!("{}: {e}", path.display())))?;
        let arrow = path.extension().and_then(|e| e.to_str()) == Some("arrow");
        self.stream = Some(Stream {
            out: FileOut { file: BufWriter::new(file), error: None },
            start_time,
            stop_time,
            units: units.to_vec(),
            kind: StreamKind::Unbegun { arrow },
        });
        Ok(())
    }

    /// Complete a streamed file; a no-op otherwise.
    pub fn finish(&mut self) -> Result<()> {
        let Some(stream) = self.stream.as_mut() else { return Ok(()) };
        match std::mem::replace(&mut stream.kind, StreamKind::Done) {
            StreamKind::Unbegun { arrow } => {
                // No row was sampled: the file still gets its header.
                let kind = self.begin_stream(arrow, &[]);
                let stream = self.stream.as_mut().expect("set above");
                stream.kind = kind;
                return self.finish();
            }
            StreamKind::Mat(mut s) => s.finish(&mut stream.out),
            StreamKind::Arrow(mut s) => s.finish(&mut stream.out),
            StreamKind::Done => {}
        }
        match stream.out.error.take() {
            Some(e) => Err(Error::Io(e.to_string())),
            None => Ok(()),
        }
    }

    fn begin_stream(&mut self, arrow: bool, first_row: &[f64]) -> StreamKind {
        let n_reals = self.columns.len() as u32 + 1;
        let stream = self.stream.as_mut().expect("a stream is open");
        let (start, stop) = (stream.start_time, stream.stop_time);
        if arrow {
            let (vars, params, col_types) = arrow_vars(&self.columns, &self.aliases, &self.parameters, &self.param_aliases);
            let defs = arrow::units::declared(stream.units.iter().map(unit_def));
            let s = arrow::ArrowStream::begin(
                &mut stream.out,
                &vars,
                &params,
                first_row,
                n_reals,
                &col_types,
                arrow::block_rows(0),
                arrow::no_strings(),
                &arrow::FileMeta { span: Some((start, stop)), units: &defs },
            );
            StreamKind::Arrow(s)
        } else {
            let (signals, params) = mat_signals(&self.columns, &self.aliases, &self.parameters, &self.param_aliases);
            let s = mat::Mat4Stream::begin(&mut stream.out, &signals, start, stop, first_row, n_reals, &params, mat::Precision::Double);
            StreamKind::Mat(s)
        }
    }

    fn push_row(&mut self) {
        self.n_rows += 1;
        if self.stream.is_none() {
            self.rows.extend_from_slice(&self.row);
            return;
        }
        let row = std::mem::take(&mut self.row);
        if let StreamKind::Unbegun { arrow } = self.stream.as_ref().expect("checked").kind {
            let kind = self.begin_stream(arrow, &row);
            self.stream.as_mut().expect("checked").kind = kind;
        }
        let stream = self.stream.as_mut().expect("checked");
        match &mut stream.kind {
            StreamKind::Mat(s) => s.push_rows(&mut stream.out, &row),
            StreamKind::Arrow(s) => s.push_rows(&mut stream.out, &row),
            StreamKind::Unbegun { .. } | StreamKind::Done => {}
        }
        self.row = row;
    }

    pub fn len(&self) -> usize {
        self.n_rows
    }

    pub fn is_empty(&self) -> bool {
        self.n_rows == 0
    }

    /// The time-invariant signals and the values they were read with, for a
    /// host that shows them beside the plot.
    pub fn parameters(&self) -> impl Iterator<Item = (&str, f64)> {
        self.parameters.iter().map(|p| (p.name.as_str(), p.value))
    }

    /// The samples as they are stored: `stride()` values per row, the time
    /// first. A host that plots reads them here rather than copying columns.
    pub fn raw(&self) -> &[f64] {
        &self.rows
    }

    pub fn stride(&self) -> usize {
        self.columns.len() + 1
    }

    pub fn times(&self) -> impl Iterator<Item = f64> + '_ {
        self.rows.chunks(self.columns.len() + 1).map(|r| r[0])
    }

    pub fn values(&self, column: usize) -> impl Iterator<Item = f64> + '_ {
        self.rows.chunks(self.columns.len() + 1).map(move |r| r[column + 1])
    }

    /// Read every recorded variable at `time` and append a row.
    pub fn sample(&mut self, inst: &mut dyn Fmi3, time: f64) -> Result<()> {
        self.row[0] = time;
        for g in &self.groups {
            let out = &mut self.scratch[..g.n_values];
            inst.get_numeric(g.ty, &g.vrs, out)?;
            let mut k = 0;
            for (col, len) in &g.spans {
                self.row[*col..col + len].copy_from_slice(&out[k..k + len]);
                k += len;
            }
        }
        self.push_row();
        Ok(())
    }

    /// Read the parameters and constants, which FMI only lets a master see once
    /// the FMU has been initialized.
    pub fn snapshot_parameters(&mut self, inst: &mut dyn Fmi3) -> Result<()> {
        for g in &self.param_groups {
            let mut out = vec![0.0; g.n_values];
            // A parameter the FMU refuses to hand out keeps its start value
            // rather than failing the run.
            if inst.get_numeric(g.ty, &g.vrs, &mut out).is_err() {
                continue;
            }
            let mut k = 0;
            for (slot, len) in &g.spans {
                for j in 0..*len {
                    self.parameters[slot + j].value = out[k + j];
                }
                k += len;
            }
        }
        Ok(())
    }

    /// The buffered rows as the MATLAB v4 result file the OpenModelica tools read.
    pub fn to_mat(&self, start_time: f64, stop_time: f64) -> Vec<u8> {
        let (signals, params) = mat_signals(&self.columns, &self.aliases, &self.parameters, &self.param_aliases);
        mat::write_mat4(
            &signals,
            start_time,
            stop_time,
            &self.rows,
            self.columns.len() as u32 + 1,
            &params,
            mat::Precision::Double,
        )
    }

    /// The buffered rows as the Arrow result file, which unlike the `.mat` keeps the
    /// column types, the discrete-time encoding, the units and `relativeQuantity`.
    pub fn to_arrow(&self, start_time: f64, stop_time: f64, units: &[fmi_unit::Unit]) -> Vec<u8> {
        let n_reals = self.columns.len() as u32 + 1;
        let (vars, params, col_types) = arrow_vars(&self.columns, &self.aliases, &self.parameters, &self.param_aliases);
        let defs = arrow::units::declared(units.iter().map(unit_def));
        arrow::write_arrow(
            &vars,
            &self.rows,
            n_reals,
            &params,
            &col_types,
            arrow::no_strings(),
            &arrow::FileMeta { span: Some((start_time, stop_time)), units: &defs },
        )
    }

    /// Write the buffered rows as the result file the suffix asks for (`.arrow` or
    /// `.mat`).
    pub fn write(&self, path: &std::path::Path, start_time: f64, stop_time: f64, units: &[fmi_unit::Unit]) -> Result<()> {
        let bytes = match path.extension().and_then(|e| e.to_str()) {
            Some("arrow") => self.to_arrow(start_time, stop_time, units),
            _ => self.to_mat(start_time, stop_time),
        };
        std::fs::write(path, bytes).map_err(|e| Error::Io(format!("{}: {e}", path.display())))
    }
}

impl Drop for Recorder {
    /// A failed run still leaves a readable file.
    fn drop(&mut self) {
        let _ = self.finish();
    }
}

/// The `.mat` signal table and the parameter values in its `Param` order.
fn mat_signals<'a>(
    columns: &'a [Column],
    aliases: &'a [Entry],
    parameters: &'a [Entry],
    param_aliases: &'a [Entry],
) -> (Vec<mat::MatVar<'a>>, Vec<f64>) {
    let mut signals = vec![mat::MatVar {
        name: "time",
        comment: "Simulation time [s]",
        kind: mat::MatKind::Time,
        unvarying: false,
    }];
    for (i, c) in columns.iter().enumerate() {
        signals.push(mat::MatVar {
            name: &c.name,
            comment: &c.description,
            kind: mat::MatKind::Column { col: i as u32 + 1, negate: mat::Neg::None },
            unvarying: false,
        });
    }
    for a in aliases {
        signals.push(mat::MatVar {
            name: &a.name,
            comment: &a.description,
            kind: mat::MatKind::Column {
                col: a.target as u32,
                negate: if a.negated { mat::Neg::Arith } else { mat::Neg::None },
            },
            unvarying: false,
        });
    }
    let mut params: Vec<f64> = Vec::with_capacity(parameters.len() + param_aliases.len());
    for p in parameters {
        signals.push(mat::MatVar {
            name: &p.name,
            comment: &p.description,
            kind: mat::MatKind::Param { negate: mat::Neg::None },
            unvarying: false,
        });
        params.push(p.value);
    }
    for a in param_aliases {
        signals.push(mat::MatVar {
            name: &a.name,
            comment: &a.description,
            kind: mat::MatKind::Param { negate: if a.negated { mat::Neg::Arith } else { mat::Neg::None } },
            unvarying: false,
        });
        params.push(parameters[a.target].value);
    }
    (signals, params)
}

/// The Arrow variable table, the parameter values in its `Param` order, and the
/// stored column types.
fn arrow_vars<'a>(
    columns: &'a [Column],
    aliases: &'a [Entry],
    parameters: &'a [Entry],
    param_aliases: &'a [Entry],
) -> (Vec<arrow::ArrowVar<'a>>, Vec<f64>, Vec<arrow::ColTy>) {
    let mut vars = vec![arrow::ArrowVar {
        name: "time",
        comment: "Simulation time [s]",
        unit: "s",
        display_unit: "",
        relative_quantity: false,
        ty: arrow::VarTy::Real,
        discrete: false,
        kind: arrow::ArrowKind::Time,
        unvarying: false,
        enumeration: None,
    }];
    for (i, c) in columns.iter().enumerate() {
        vars.push(arrow::ArrowVar {
            name: &c.name,
            comment: &c.description,
            unit: c.unit.as_deref().unwrap_or_default(),
            display_unit: c.display_unit.as_deref().unwrap_or_default(),
            relative_quantity: c.relative_quantity,
            ty: arrow_ty(c.ty),
            discrete: c.discrete,
            kind: arrow::ArrowKind::Column { col: i as u32 + 1, affine: arrow::Affine::IDENTITY },
            unvarying: false,
            enumeration: None,
        });
    }
    let affine = |e: &Entry| {
        if !e.negated {
            arrow::Affine::IDENTITY
        } else if arrow_ty(e.ty) == arrow::VarTy::Boolean {
            arrow::Affine::NOT
        } else {
            arrow::Affine::NEGATE
        }
    };
    for a in aliases {
        vars.push(entry_var(a, arrow::ArrowKind::Column { col: a.target as u32, affine: affine(a) }));
    }
    let mut params: Vec<f64> = Vec::with_capacity(parameters.len() + param_aliases.len());
    for p in parameters {
        vars.push(entry_var(p, arrow::ArrowKind::Param { affine: arrow::Affine::IDENTITY }));
        params.push(p.value);
    }
    for a in param_aliases {
        vars.push(entry_var(a, arrow::ArrowKind::Param { affine: affine(a) }));
        params.push(parameters[a.target].value);
    }
    let mut col_types = vec![arrow::ColTy::F64];
    col_types.extend(columns.iter().map(|c| match arrow_ty(c.ty) {
        arrow::VarTy::Integer => arrow::ColTy::I32,
        arrow::VarTy::Boolean => arrow::ColTy::Bool,
        _ => arrow::ColTy::F64,
    }));
    (vars, params, col_types)
}

fn entry_var<'a>(e: &'a Entry, kind: arrow::ArrowKind) -> arrow::ArrowVar<'a> {
    arrow::ArrowVar {
        name: &e.name,
        comment: &e.description,
        unit: e.unit.as_deref().unwrap_or_default(),
        display_unit: e.display_unit.as_deref().unwrap_or_default(),
        relative_quantity: e.relative_quantity,
        ty: arrow_ty(e.ty),
        discrete: false,
        kind,
        unvarying: false,
        enumeration: None,
    }
}

/// An FMI variable type as the result file's Modelica type. An enumeration is
/// stored as its Integer value; the FMU's literal names are not carried.
fn arrow_ty(ty: VarType) -> arrow::VarTy {
    match ty {
        VarType::Boolean => arrow::VarTy::Boolean,
        VarType::String | VarType::Binary => arrow::VarTy::String,
        VarType::Float32 | VarType::Float64 => arrow::VarTy::Real,
        _ => arrow::VarTy::Integer,
    }
}

/// An FMU's `<Unit>` as a `modelica.units` entry; the two are FMI 3.0's own
/// definitions, so this only reshapes the base exponents into their array.
fn unit_def(u: &fmi_unit::Unit) -> arrow::units::UnitDef {
    arrow::units::UnitDef {
        name: u.name.clone(),
        base: u.base_unit.as_ref().map(|b| arrow::units::BaseUnit {
            exponents: [b.kg, b.m, b.s, b.a, b.k, b.mol, b.cd, b.rad],
            factor: b.factor,
            offset: b.offset,
        }),
        display_units: u
            .display_units
            .iter()
            .map(|d| arrow::units::DisplayUnit {
                name: d.name.clone(),
                factor: d.factor,
                offset: d.offset,
                inverse: d.inverse,
            })
            .collect(),
    }
}
