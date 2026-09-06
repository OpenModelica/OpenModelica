//! MTSF, the Modelica Association Time Series File format (Pfeiffer,
//! Bausch-Gall and Otter, *Proposal for a Standard Time Series File Format in
//! HDF5*, Modelica 2012), as `PySimulator`'s `pyMtsf` writes it.
//!
//! The opposite trade to [`crate::sdf`]: the trajectories are a handful of 2-D
//! matrices rather than one dataset per variable, and a variable is a row in the
//! `/ModelDescription/Variables` table naming the matrix (an object reference)
//! and its column. So an alias costs a table row and no data, and adding a
//! variable costs no HDF5 object.
//!
//! * `/ModelDescription` - `Variables`, `SimpleTypes`, `Units` and
//!   `Enumerations`, all compound datasets of one column.
//! * `/Results/<series>/<category>` - the data. A *series* is a sampling
//!   (`Fixed` once, `Continuous` per step, `Discrete` per event) and a
//!   *category* an HDF5 element type, so Reals and Booleans never share a
//!   matrix and a Boolean costs one byte per sample.

use std::collections::HashMap;
use std::ffi::CString;

use hdf5_metno_sys::h5r::hobj_ref_t;

use crate::h5::{self, Attrs, Dataset, File, Group, Layout, Type};
use crate::{Affine, Kind, Meta, Options, Var, VarTy};

pub const VERSION: &str = "0.33";

/// `/Results/<name>`: a sampling of the model's variables.
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
pub enum Series {
    /// Written once: parameters, constants and `unvarying` signals.
    Fixed,
    Continuous,
    Discrete,
}

impl Series {
    fn name(self) -> &'static str {
        match self {
            Series::Fixed => "Fixed",
            Series::Continuous => "Continuous",
            Series::Discrete => "Discrete",
        }
    }

    fn interpolation(self) -> &'static str {
        match self {
            Series::Fixed | Series::Discrete => "constant",
            Series::Continuous => "linear",
        }
    }
}

/// MTSF `/ModelDescription/Variables.causality`.
const CAUSALITY: [(&str, u8); 5] =
    [("parameter", 1), ("input", 2), ("output", 3), ("local", 4), ("option", 5)];
/// MTSF `/ModelDescription/Variables.variability`.
const VARIABILITY: [(&str, u8); 5] =
    [("constant", 1), ("fixed", 2), ("tunable", 3), ("discrete", 4), ("continuous", 5)];
const BOOL: [(&str, u8); 2] = [("false", 0), ("true", 1)];
const DATA_TYPE: [(&str, u8); 5] =
    [("Real", 1), ("Integer", 2), ("Boolean", 3), ("String", 4), ("Enumeration", 5)];
const UNIT_MODE: [(&str, u8); 3] = [("BaseUnit", 0), ("Unit", 1), ("DefaultDisplayUnit", 2)];

/// One row of `/ModelDescription/Variables`, laid out as HDF5 reads it.
#[repr(C)]
struct VarRow {
    name: *const i8,
    simple_type_row: u32,
    causality: u8,
    variability: u8,
    description: *const i8,
    object_id: hobj_ref_t,
    column: u32,
    negated: u8,
}

#[repr(C)]
struct SimpleTypeRow {
    name: *const i8,
    data_type: u8,
    quantity: *const i8,
    relative_quantity: u8,
    description: *const i8,
    unit_or_enumeration_row: i32,
}

#[repr(C)]
struct UnitRow {
    name: *const i8,
    factor: f64,
    offset: f64,
    mode: u8,
}

struct Matrix {
    ds: Dataset,
    ty: VarTy,
    n_cols: usize,
    n_rows: usize,
    /// Rows the dataset is currently sized for.
    extent: u64,
    /// Which result-row column feeds each of its columns, and how.
    src: Vec<(usize, Affine)>,
    buf: Vec<f64>,
}

pub struct MtsfStream {
    #[allow(dead_code)]
    file: File,
    #[allow(dead_code)]
    groups: Vec<Group>,
    continuous: Vec<Matrix>,
    /// Fed by [`MtsfStream::push_event_rows`], not by `push_rows`.
    discrete: Vec<Matrix>,
    n_reals: usize,
    n_rows: usize,
    n_event_rows: usize,
    pending: Vec<f64>,
    block_rows: usize,
    single: bool,
    finished: bool,
}

/// Where one variable ended up: which matrix and column, and whether it reads
/// that column negated.
struct Placement {
    series: Series,
    category: VarTy,
    column: usize,
    negated: bool,
}

impl MtsfStream {
    /// `params` holds the `Param` values in `vars` order; they and `first_row`
    /// give the `Fixed` series its one row.
    #[allow(clippy::too_many_arguments)]
    pub fn begin(
        path: &str,
        vars: &[Var],
        params: &[f64],
        first_row: &[f64],
        n_reals: u32,
        meta: &Meta,
        opts: &Options,
    ) -> Result<MtsfStream, String> {
        h5::init();
        let n_reals = n_reals.max(1) as usize;
        let file = File::create(path)?;
        file.attr_str("mtsfVersion", VERSION)?;

        // Plan the columns before creating anything: a matrix's width is fixed
        // at creation, and an alias must find its target's column.
        let plan = plan(vars, params, first_row, n_reals);

        let results = Group::create(&file, "/Results")?;
        results.attr_str("ResultType", "Simulation")?;
        results.attr_str("startTime", &meta.start_time.to_string())?;
        results.attr_str("stopTime", &meta.stop_time.to_string())?;
        results.attr_str("relativeTolerance", &meta.tolerance.to_string())?;
        results.attr_str("algorithm", meta.algorithm)?;
        results.attr_str("author", meta.author)?;
        results.attr_str("description", meta.description)?;
        results.attr_str("generationTool", meta.generation_tool)?;
        results.attr_str("generationDateAndTime", meta.date_time)?;

        let mut groups = vec![results];
        let mut matrices: HashMap<(Series, VarTy), (Dataset, String)> = HashMap::new();
        for series in [Series::Fixed, Series::Continuous, Series::Discrete] {
            let used: Vec<VarTy> = plan
                .widths
                .iter()
                .filter(|((s, _), w)| *s == series && **w > 0)
                .map(|((_, t), _)| *t)
                .collect();
            if used.is_empty() {
                continue;
            }
            let g = Group::create(&file, &format!("/Results/{}", series.name()))?;
            g.attr_str("interpolationMethod", series.interpolation())?;
            for ty in used {
                let n_cols = plan.widths[&(series, ty)];
                // A chunked dataset allocates its chunks as they are written
                // whatever extent it declares, so reserving the known length
                // costs nothing and saves an `H5Dset_extent` per block.
                let rows0 = if series == Series::Fixed { 1 } else { opts.expected_rows.unwrap_or(0) as u64 };
                let max_rows = if series == Series::Fixed { Some(1) } else { None };
                let chunk_rows = if series == Series::Fixed { 1 } else { opts.chunk_height() };
                let chunk_cols = if opts.chunk_cols == 0 { n_cols } else { opts.chunk_cols.min(n_cols) };
                let layout = Layout {
                    chunk: Some([chunk_rows as u64, chunk_cols.max(1) as u64]),
                    deflate: opts.deflate,
                    shuffle: opts.shuffle,
                };
                let name = ty.category();
                let ds = Dataset::create(
                    &g,
                    name,
                    &elem_type(ty, opts.single),
                    &[rows0, n_cols as u64],
                    Some(&[max_rows.unwrap_or(u64::MAX), n_cols as u64]),
                    layout,
                )?;
                matrices.insert((series, ty), (ds, format!("/Results/{}/{name}", series.name())));
            }
            groups.push(g);
        }

        write_model_description(&file, vars, &plan.placement, &matrices, meta)?;

        for ((series, ty), (ds, _)) in &matrices {
            if *series != Series::Fixed {
                continue;
            }
            let row = &plan.fixed[ty];
            write_block(ds, *ty, opts.single, &[0, 0], &[1, row.len() as u64], row)?;
        }

        let build = |series: Series| -> Vec<Matrix> {
            let mut out = Vec::new();
            for ((s, ty), (ds, _)) in matrices.iter() {
                if *s != series {
                    continue;
                }
                let n_cols = plan.widths[&(series, *ty)];
                out.push(Matrix {
                    ds: Dataset::from_raw(dup(ds)),
                    ty: *ty,
                    n_cols,
                    n_rows: 0,
                    extent: if series == Series::Fixed { 1 } else { opts.expected_rows.unwrap_or(0) as u64 },
                    src: column_sources(&plan, series, *ty, n_cols),
                    buf: Vec::new(),
                });
            }
            out
        };
        let continuous = build(Series::Continuous);
        let discrete = build(Series::Discrete);

        Ok(MtsfStream {
            file,
            groups,
            continuous,
            discrete,
            n_reals,
            n_rows: 0,
            n_event_rows: 0,
            pending: Vec::new(),
            block_rows: opts.chunk_rows.max(1),
            single: opts.single,
            finished: false,
        })
    }

    /// Append `rows` (row-major, `n_reals` values each) to `Continuous`.
    pub fn push_rows(&mut self, rows: &[f64]) -> Result<(), String> {
        self.pending.extend_from_slice(rows);
        while self.pending.len() / self.n_reals >= self.block_rows {
            let n = self.block_rows;
            self.flush_block(n)?;
        }
        Ok(())
    }

    /// Append rows to the `Discrete` series, i.e. the values at an event.
    pub fn push_event_rows(&mut self, rows: &[f64]) -> Result<(), String> {
        let n = rows.len() / self.n_reals;
        if n == 0 {
            return Ok(());
        }
        let start = self.n_event_rows as u64;
        for m in &mut self.discrete {
            m.write(rows, n, self.n_reals, start, self.single)?;
        }
        self.n_event_rows += n;
        Ok(())
    }

    fn flush_block(&mut self, n: usize) -> Result<(), String> {
        let take = n * self.n_reals;
        let start = self.n_rows as u64;
        for m in &mut self.continuous {
            m.write(&self.pending[..take], n, self.n_reals, start, self.single)?;
        }
        self.pending.drain(..take);
        self.n_rows += n;
        Ok(())
    }

    /// Write the last block. Idempotent.
    pub fn finish(&mut self) -> Result<(), String> {
        if self.finished {
            return Ok(());
        }
        self.finished = true;
        let n = self.pending.len() / self.n_reals;
        if n > 0 {
            self.flush_block(n)?;
        }
        // A run that stopped early leaves the reserved rows unwritten.
        for m in self.continuous.iter().chain(&self.discrete) {
            if m.extent > m.n_rows as u64 {
                m.ds.set_extent(&[m.n_rows as u64, m.n_cols as u64])?;
            }
        }
        Ok(())
    }

    pub fn n_rows(&self) -> usize {
        self.n_rows
    }
}

impl Matrix {
    fn write(&mut self, rows: &[f64], n: usize, n_reals: usize, start: u64, single: bool) -> Result<(), String> {
        self.buf.clear();
        self.buf.reserve(n * self.n_cols);
        for r in 0..n {
            let row = &rows[r * n_reals..(r + 1) * n_reals];
            for (col, affine) in &self.src {
                self.buf.push(affine.apply(row[*col]));
            }
        }
        let end = start + n as u64;
        if end > self.extent {
            self.ds.set_extent(&[end, self.n_cols as u64])?;
            self.extent = end;
        }
        write_block(&self.ds, self.ty, single, &[start, 0], &[n as u64, self.n_cols as u64], &self.buf)?;
        self.n_rows += n;
        Ok(())
    }
}

/// Decide each variable's (series, category, column) and collect the `Fixed`
/// series' single row.
///
/// A column stores the result-row column unnegated, so an identity reference
/// and a `-x` reference to the same signal share it whichever of the two the
/// variable list mentions first; MTSF's table can say `negated` but nothing
/// else, so any other transform gets a column of its own.
fn plan(
    vars: &[Var],
    params: &[f64],
    first_row: &[f64],
    n_reals: usize,
) -> Plan {
    let mut widths: HashMap<(Series, VarTy), usize> = HashMap::new();
    let mut fixed: HashMap<VarTy, Vec<f64>> = HashMap::new();
    let mut placement: Vec<Option<Placement>> = Vec::with_capacity(vars.len());
    let mut sources: HashMap<(Series, VarTy, usize), (usize, Affine)> = HashMap::new();
    let mut owner: HashMap<(Series, VarTy, usize), usize> = HashMap::new();
    let mut next_param = 0usize;

    for v in vars {
        // Neither writer stores text yet; a String signal is dropped as the
        // numeric formats drop it, but it still owns its `params` slot.
        if v.ty == VarTy::String {
            next_param += usize::from(matches!(v.kind, Kind::Param { .. }));
            placement.push(None);
            continue;
        }
        let (series, value, col, affine) = match v.kind {
            Kind::Const { value } => (Series::Fixed, Some(value), usize::MAX, Affine::IDENTITY),
            Kind::Param { affine } => {
                let p = params.get(next_param).copied().unwrap_or(0.0);
                next_param += 1;
                (Series::Fixed, Some(affine.apply(p)), usize::MAX, Affine::IDENTITY)
            }
            Kind::Column { col, affine } if v.unvarying => {
                let c = col as usize;
                let raw = if c < n_reals { first_row.get(c).copied().unwrap_or(0.0) } else { 0.0 };
                (Series::Fixed, Some(affine.apply(raw)), usize::MAX, Affine::IDENTITY)
            }
            Kind::Time => (Series::Continuous, None, 0, Affine::IDENTITY),
            Kind::Column { col, affine } => {
                let s = if v.discrete { Series::Discrete } else { Series::Continuous };
                (s, None, col as usize, affine)
            }
        };
        let category = v.ty;
        let width = widths.entry((series, category)).or_insert(0);

        if let Some(value) = value {
            let row = fixed.entry(category).or_default();
            row.push(value);
            placement.push(Some(Placement { series, category, column: *width, negated: false }));
            *width += 1;
            continue;
        }

        let negated = affine.scale == -1.0 && affine.offset == 0.0;
        let key = (series, category, col);
        if affine.is_identity() || negated {
            if let Some(existing) = owner.get(&key) {
                placement.push(Some(Placement { series, category, column: *existing, negated }));
                continue;
            }
            owner.insert(key, *width);
            sources.insert((series, category, *width), (col, Affine::IDENTITY));
            placement.push(Some(Placement { series, category, column: *width, negated }));
        } else {
            sources.insert((series, category, *width), (col, affine));
            placement.push(Some(Placement { series, category, column: *width, negated: false }));
        }
        *width += 1;
    }
    Plan { placement, widths, fixed, sources }
}

struct Plan {
    /// `None` for a variable no matrix holds.
    placement: Vec<Option<Placement>>,
    widths: HashMap<(Series, VarTy), usize>,
    fixed: HashMap<VarTy, Vec<f64>>,
    /// Which result-row column feeds each `(series, category, column)`, and how.
    sources: HashMap<(Series, VarTy, usize), (usize, Affine)>,
}

fn column_sources(plan: &Plan, series: Series, category: VarTy, n_cols: usize) -> Vec<(usize, Affine)> {
    (0..n_cols)
        .map(|c| plan.sources.get(&(series, category, c)).copied().unwrap_or((0, Affine::IDENTITY)))
        .collect()
}

fn elem_type(ty: VarTy, single: bool) -> Type {
    match ty {
        VarTy::Real if single => Type::f32(),
        VarTy::Real => Type::f64(),
        VarTy::Boolean => Type::i8(),
        _ => Type::i32(),
    }
}

fn write_block(ds: &Dataset, ty: VarTy, single: bool, start: &[u64], count: &[u64], data: &[f64]) -> Result<(), String> {
    match ty {
        VarTy::Real if single => {
            let v: Vec<f32> = data.iter().map(|x| *x as f32).collect();
            ds.write_slab(&Type::f32(), start, count, &v)
        }
        VarTy::Real => ds.write_slab(&Type::f64(), start, count, data),
        VarTy::Boolean => {
            let v: Vec<i8> = data.iter().map(|x| (*x != 0.0) as i8).collect();
            ds.write_slab(&Type::i8(), start, count, &v)
        }
        _ => {
            let v: Vec<i32> = data.iter().map(|x| *x as i32).collect();
            ds.write_slab(&Type::i32(), start, count, &v)
        }
    }
}

fn write_model_description(
    file: &File,
    vars: &[Var],
    placement: &[Option<Placement>],
    matrices: &HashMap<(Series, VarTy), (Dataset, String)>,
    meta: &Meta,
) -> Result<(), String> {
    let group = Group::create(file, "/ModelDescription")?;
    group.attr_str("modelName", meta.model_name)?;
    group.attr_str("description", meta.description)?;
    group.attr_str("author", meta.author)?;
    group.attr_str("version", "")?;
    group.attr_str("generationTool", meta.generation_tool)?;
    group.attr_str("generationDateAndTime", meta.date_time)?;
    group.attr_str("variableNamingConvention", "structured")?;

    // Units, then the SimpleTypes that index them: Modelica types a variable by
    // (type, quantity, unit, relativeQuantity), and thousands of variables share
    // a handful of those.
    let mut units: Vec<(&str, &str)> = Vec::new();
    let mut unit_row: HashMap<(&str, &str), usize> = HashMap::new();
    let mut simple: Vec<(VarTy, &str, &str, bool, i32)> = Vec::new();
    let mut simple_row: HashMap<(VarTy, &str, &str, bool), usize> = HashMap::new();
    let mut var_type_row = Vec::with_capacity(vars.len());
    for v in vars {
        let key = (v.ty, v.unit, v.display_unit, v.relative_quantity);
        let row = match simple_row.get(&key) {
            Some(r) => *r,
            None => {
                let unit = if v.unit.is_empty() {
                    -1
                } else {
                    let uk = (v.unit, v.display_unit);
                    *unit_row.entry(uk).or_insert_with(|| {
                        units.push(uk);
                        units.len() - 1
                    }) as i32
                };
                simple.push((v.ty, v.unit, "", v.relative_quantity, unit));
                let r = simple.len() - 1;
                simple_row.insert(key, r);
                r
            }
        };
        var_type_row.push(row as u32);
    }

    let vlen = Type::vlen_str()?;
    let bool_ty = Type::enum_u8(&BOOL)?;

    if !units.is_empty() {
        let names: Vec<CString> = units.iter().map(|(n, _)| cstring(n)).collect();
        let rows: Vec<UnitRow> = names
            .iter()
            .map(|n| UnitRow { name: n.as_ptr(), factor: 1.0, offset: 0.0, mode: 1 })
            .collect();
        let ty = Type::compound(
            size_of::<UnitRow>(),
            &[
                ("name", std::mem::offset_of!(UnitRow, name), &vlen),
                ("factor", std::mem::offset_of!(UnitRow, factor), &Type::f64()),
                ("offset", std::mem::offset_of!(UnitRow, offset), &Type::f64()),
                ("mode", std::mem::offset_of!(UnitRow, mode), &Type::enum_u8(&UNIT_MODE)?),
            ],
        )?;
        table(&group, "Units", &ty, &rows)?;
    }

    {
        let names: Vec<CString> = simple.iter().map(|(t, ..)| cstring(t.name())).collect();
        let quantities: Vec<CString> = simple.iter().map(|(_, _, q, ..)| cstring(q)).collect();
        let empty = cstring("");
        let rows: Vec<SimpleTypeRow> = simple
            .iter()
            .enumerate()
            .map(|(i, (ty, _, _, rel, unit))| SimpleTypeRow {
                name: names[i].as_ptr(),
                data_type: ty.mtsf_code(),
                quantity: quantities[i].as_ptr(),
                relative_quantity: *rel as u8,
                description: empty.as_ptr(),
                unit_or_enumeration_row: *unit,
            })
            .collect();
        let ty = Type::compound(
            size_of::<SimpleTypeRow>(),
            &[
                ("name", std::mem::offset_of!(SimpleTypeRow, name), &vlen),
                ("dataType", std::mem::offset_of!(SimpleTypeRow, data_type), &Type::enum_u8(&DATA_TYPE)?),
                ("quantity", std::mem::offset_of!(SimpleTypeRow, quantity), &vlen),
                ("relativeQuantity", std::mem::offset_of!(SimpleTypeRow, relative_quantity), &bool_ty),
                ("description", std::mem::offset_of!(SimpleTypeRow, description), &vlen),
                ("unitOrEnumerationRow", std::mem::offset_of!(SimpleTypeRow, unit_or_enumeration_row), &Type::i32()),
            ],
        )?;
        table(&group, "SimpleTypes", &ty, &rows)?;
    }

    {
        let names: Vec<CString> = vars.iter().map(|v| cstring(v.name)).collect();
        let descs: Vec<CString> = vars.iter().map(|v| cstring(v.comment)).collect();
        let mut rows = Vec::with_capacity(vars.len());
        for (i, (v, p)) in vars.iter().zip(placement).enumerate() {
            let Some(p) = p else { continue };
            let (ds, path) = &matrices[&(p.series, p.category)];
            rows.push(VarRow {
                name: names[i].as_ptr(),
                simple_type_row: var_type_row[i],
                causality: causality_of(v),
                variability: variability_of(v),
                description: descs[i].as_ptr(),
                object_id: ds.reference(file, path)?,
                column: p.column as u32,
                negated: p.negated as u8,
            });
        }
        let ty = Type::compound(
            size_of::<VarRow>(),
            &[
                ("name", std::mem::offset_of!(VarRow, name), &vlen),
                ("simpleTypeRow", std::mem::offset_of!(VarRow, simple_type_row), &Type::u32()),
                ("causality", std::mem::offset_of!(VarRow, causality), &Type::enum_u8(&CAUSALITY)?),
                ("variability", std::mem::offset_of!(VarRow, variability), &Type::enum_u8(&VARIABILITY)?),
                ("description", std::mem::offset_of!(VarRow, description), &vlen),
                ("objectId", std::mem::offset_of!(VarRow, object_id), &Type::obj_ref()),
                ("column", std::mem::offset_of!(VarRow, column), &Type::u32()),
                ("negated", std::mem::offset_of!(VarRow, negated), &bool_ty),
            ],
        )?;
        table(&group, "Variables", &ty, &rows)?;
    }

    // `independentVariableRow` names the table row of the series' own clock.
    if let Some(time_row) = vars.iter().position(|v| matches!(v.kind, Kind::Time))
        && let Ok(g) = Group::open(file, "/Results/Continuous")
    {
        g.attr_i32("independentVariableRow", time_row as i32)?;
    }
    Ok(())
}

/// pyMtsf's tables are `(n, 1)`, not `(n,)`.
fn table<T>(group: &Group, name: &str, ty: &Type, rows: &[T]) -> Result<(), String> {
    let ds = Dataset::create(group, name, ty, &[rows.len() as u64, 1], None, Layout::CONTIGUOUS)?;
    ds.write_all(ty, rows)
}

fn causality_of(v: &Var) -> u8 {
    match v.kind {
        Kind::Param { .. } | Kind::Const { .. } => 1,
        Kind::Time => 2,
        _ => 4,
    }
}

fn variability_of(v: &Var) -> u8 {
    match v.kind {
        Kind::Const { .. } => 1,
        Kind::Param { .. } => 2,
        _ if v.discrete => 4,
        _ => 5,
    }
}

fn cstring(s: &str) -> CString {
    CString::new(s.replace('\0', " ")).expect("no interior NUL")
}

/// A second owned handle, so the planning map and the streaming matrices can
/// both hold one.
fn dup(ds: &Dataset) -> hdf5_metno_sys::h5i::hid_t {
    unsafe { hdf5_metno_sys::h5o::H5Oopen(ds.id(), c".".as_ptr(), hdf5_metno_sys::h5p::H5P_DEFAULT) }
}

/// The `/ModelDescription` tables read once; the matrices stay on disk.
pub struct MtsfFile {
    file: File,
    pub vars: Vec<Info>,
    pub matrices: Vec<MatrixInfo>,
    /// Rows of the `Continuous` series.
    pub n_rows: usize,
    /// Index into `vars` of the independent variable.
    pub time: Option<usize>,
}

pub struct MatrixInfo {
    pub path: String,
    pub series: Series,
    pub ty: VarTy,
    pub n_rows: usize,
    pub n_cols: usize,
}

pub struct Info {
    pub name: String,
    pub comment: String,
    pub unit: String,
    pub display_unit: String,
    pub relative_quantity: bool,
    pub ty: VarTy,
    pub matrix: usize,
    pub column: usize,
    pub negated: bool,
    pub variability: u8,
}

impl Info {
    /// A `Fixed`-series variable, i.e. what the `.mat` calls a parameter.
    pub fn is_fixed(&self, file: &MtsfFile) -> bool {
        file.matrices[self.matrix].series == Series::Fixed
    }
}

impl MtsfFile {
    pub fn open(path: &str) -> Result<MtsfFile, String> {
        h5::init();
        let file = File::open_ro(path)?;
        let md = Group::open(&file, "/ModelDescription")?;

        let units = read_units(&md)?;
        let simple = read_simple_types(&md)?;

        // Discover the matrices first, so a variable's object reference can be
        // matched to one by identity of the dataset it names.
        let mut matrices = Vec::new();
        let results = Group::open(&file, "/Results")?;
        for (sname, kind) in results.links()? {
            if kind != h5::LinkKind::Group {
                continue;
            }
            let series = match sname.as_str() {
                "Fixed" => Series::Fixed,
                "Continuous" => Series::Continuous,
                "Discrete" => Series::Discrete,
                _ => continue,
            };
            let g = Group::open(&results, &sname)?;
            for (cname, kind) in g.links()? {
                if kind != h5::LinkKind::Dataset {
                    continue;
                }
                let ds = Dataset::open(&g, &cname)?;
                let dims = ds.space()?.dims()?;
                matrices.push(MatrixInfo {
                    path: format!("/Results/{sname}/{cname}"),
                    series,
                    ty: category_type(&cname),
                    n_rows: dims.first().copied().unwrap_or(0) as usize,
                    n_cols: dims.get(1).copied().unwrap_or(0) as usize,
                });
            }
        }

        let vars = read_variables(&file, &md, &matrices, &simple, &units)?;
        let n_rows = matrices
            .iter()
            .find(|m| m.series == Series::Continuous)
            .map_or(0, |m| m.n_rows);
        let time = md
            .read_attr_i32("independentVariableRow")
            .or_else(|| Group::open(&file, "/Results/Continuous").ok()?.read_attr_i32("independentVariableRow"))
            .and_then(|r| usize::try_from(r).ok())
            .filter(|r| *r < vars.len())
            .or_else(|| vars.iter().position(|v| v.name == "time" || v.name == "Time"));
        Ok(MtsfFile { file, vars, matrices, n_rows, time })
    }

    pub fn read_column(&self, idx: usize) -> Result<Vec<f64>, String> {
        let v = self.vars.get(idx).ok_or("MTSF: no such variable")?;
        let mut out = self.read_matrix_column(v.matrix, v.column)?;
        if v.negated {
            for x in &mut out {
                *x = -*x;
            }
        }
        Ok(out)
    }

    /// One column of one matrix, exactly as stored.
    pub fn read_matrix_column(&self, matrix: usize, column: usize) -> Result<Vec<f64>, String> {
        let m = self.matrices.get(matrix).ok_or("MTSF: no such matrix")?;
        let ds = Dataset::open(&self.file, &m.path)?;
        let mut out = vec![0.0f64; m.n_rows];
        ds.read_slab(&Type::f64(), &[0, column as u64], &[m.n_rows as u64, 1], &mut out)?;
        Ok(out)
    }
}

impl MtsfFile {
    /// A whole matrix, row-major: the bulk path, which decompresses each chunk
    /// once however many of its columns the caller wants.
    pub fn read_matrix(&self, matrix: usize) -> Result<Vec<f64>, String> {
        let m = self.matrices.get(matrix).ok_or("MTSF: no such matrix")?;
        let ds = Dataset::open(&self.file, &m.path)?;
        let mut out = vec![0.0f64; m.n_rows * m.n_cols];
        ds.read_all(&Type::f64(), &mut out)?;
        Ok(out)
    }

    /// One row of one matrix, which is how the `Fixed` series is read.
    pub fn read_row(&self, matrix: usize, row: usize) -> Result<Vec<f64>, String> {
        let m = self.matrices.get(matrix).ok_or("MTSF: no such matrix")?;
        let ds = Dataset::open(&self.file, &m.path)?;
        let mut out = vec![0.0f64; m.n_cols];
        ds.read_slab(&Type::f64(), &[row as u64, 0], &[1, m.n_cols as u64], &mut out)?;
        Ok(out)
    }
}

fn category_type(name: &str) -> VarTy {
    match name {
        "H5T_NATIVE_INT8" => VarTy::Boolean,
        "H5T_NATIVE_INT32" => VarTy::Integer,
        "H5T_C_S1" => VarTy::String,
        _ => VarTy::Real,
    }
}

/// Read a `(n, 1)` compound table into `rows`, then hand back the vlen strings
/// HDF5 allocated so the caller can copy them before they are reclaimed.
fn read_table<T>(group: &Group, name: &str, ty: &Type) -> Result<(Vec<T>, Type, h5::Space), String> {
    let ds = Dataset::open(group, name)?;
    let space = ds.space()?;
    let n: usize = space.dims()?.iter().product::<u64>() as usize;
    // All-zero is a valid value of every row type here (a null pointer for the
    // vlen fields), so a failed read leaves nothing dangling.
    let mut rows: Vec<T> = (0..n).map(|_| unsafe { std::mem::zeroed() }).collect();
    ds.read_all(ty, &mut rows)?;
    Ok((rows, Type::from_raw(unsafe { hdf5_metno_sys::h5t::H5Tcopy(ty.id()) }), space))
}

fn owned(p: *const i8) -> String {
    if p.is_null() {
        return String::new();
    }
    unsafe { std::ffi::CStr::from_ptr(p) }.to_string_lossy().into_owned()
}

fn units_type(vlen: &Type) -> Result<Type, String> {
    Type::compound(
        size_of::<UnitRow>(),
        &[
            ("name", std::mem::offset_of!(UnitRow, name), vlen),
            ("factor", std::mem::offset_of!(UnitRow, factor), &Type::f64()),
            ("offset", std::mem::offset_of!(UnitRow, offset), &Type::f64()),
            ("mode", std::mem::offset_of!(UnitRow, mode), &Type::enum_u8(&UNIT_MODE)?),
        ],
    )
}

fn read_units(md: &Group) -> Result<Vec<String>, String> {
    if !Group::exists(md, "Units") {
        return Ok(Vec::new());
    }
    let vlen = Type::vlen_str()?;
    let ty = units_type(&vlen)?;
    let (mut rows, mem, space) = read_table::<UnitRow>(md, "Units", &ty)?;
    let out = rows.iter().map(|r| owned(r.name)).collect();
    h5::reclaim_vlen(&mem, &space, &mut rows);
    Ok(out)
}

/// `(type, relativeQuantity, unit)` per SimpleTypes row.
fn read_simple_types(md: &Group) -> Result<Vec<(VarTy, bool, i32)>, String> {
    if !Group::exists(md, "SimpleTypes") {
        return Ok(Vec::new());
    }
    let vlen = Type::vlen_str()?;
    let ty = Type::compound(
        size_of::<SimpleTypeRow>(),
        &[
            ("name", std::mem::offset_of!(SimpleTypeRow, name), &vlen),
            ("dataType", std::mem::offset_of!(SimpleTypeRow, data_type), &Type::enum_u8(&DATA_TYPE)?),
            ("quantity", std::mem::offset_of!(SimpleTypeRow, quantity), &vlen),
            ("relativeQuantity", std::mem::offset_of!(SimpleTypeRow, relative_quantity), &Type::enum_u8(&BOOL)?),
            ("description", std::mem::offset_of!(SimpleTypeRow, description), &vlen),
            ("unitOrEnumerationRow", std::mem::offset_of!(SimpleTypeRow, unit_or_enumeration_row), &Type::i32()),
        ],
    )?;
    let (mut rows, mem, space) = read_table::<SimpleTypeRow>(md, "SimpleTypes", &ty)?;
    let out = rows
        .iter()
        .map(|r| {
            let ty = match r.data_type {
                2 => VarTy::Integer,
                3 => VarTy::Boolean,
                4 => VarTy::String,
                5 => VarTy::Enumeration,
                _ => VarTy::Real,
            };
            (ty, r.relative_quantity != 0, r.unit_or_enumeration_row)
        })
        .collect();
    h5::reclaim_vlen(&mem, &space, &mut rows);
    Ok(out)
}

fn read_variables(
    file: &File,
    md: &Group,
    matrices: &[MatrixInfo],
    simple: &[(VarTy, bool, i32)],
    units: &[String],
) -> Result<Vec<Info>, String> {
    let vlen = Type::vlen_str()?;
    let bool_ty = Type::enum_u8(&BOOL)?;
    let ty = Type::compound(
        size_of::<VarRow>(),
        &[
            ("name", std::mem::offset_of!(VarRow, name), &vlen),
            ("simpleTypeRow", std::mem::offset_of!(VarRow, simple_type_row), &Type::u32()),
            ("causality", std::mem::offset_of!(VarRow, causality), &Type::enum_u8(&CAUSALITY)?),
            ("variability", std::mem::offset_of!(VarRow, variability), &Type::enum_u8(&VARIABILITY)?),
            ("description", std::mem::offset_of!(VarRow, description), &vlen),
            ("objectId", std::mem::offset_of!(VarRow, object_id), &Type::obj_ref()),
            ("column", std::mem::offset_of!(VarRow, column), &Type::u32()),
            ("negated", std::mem::offset_of!(VarRow, negated), &bool_ty),
        ],
    )?;
    let (mut rows, mem, space) = read_table::<VarRow>(md, "Variables", &ty)?;

    // An object reference resolves to a dataset; match it to a matrix by the
    // shape and element type the two agree on, then by name.
    let mut by_ref: std::collections::HashMap<u64, usize> = std::collections::HashMap::new();
    for (i, m) in matrices.iter().enumerate() {
        if let Ok(ds) = Dataset::open(file, &m.path)
            && let Ok(r) = ds.reference(file, &m.path)
        {
            by_ref.insert(r, i);
        }
    }

    let out = rows
        .iter()
        .map(|r| {
            let matrix = by_ref.get(&r.object_id).copied().unwrap_or(0);
            let (ty, relative_quantity, unit_row) =
                simple.get(r.simple_type_row as usize).copied().unwrap_or((VarTy::Real, false, -1));
            let unit = usize::try_from(unit_row).ok().and_then(|u| units.get(u)).cloned().unwrap_or_default();
            Info {
                name: owned(r.name),
                comment: owned(r.description),
                display_unit: unit.clone(),
                unit,
                relative_quantity,
                ty,
                matrix,
                column: r.column as usize,
                negated: r.negated != 0,
                variability: r.variability,
            }
        })
        .collect();
    h5::reclaim_vlen(&mem, &space, &mut rows);
    Ok(out)
}
