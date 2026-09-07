//! Reader for `arrow.modelica` result files, the layout
//! `openmodelica_arrow_writer/SPECIFICATION.md` describes: the streams are
//! walked and dispatched on `modelica.table`, the data batches decoded once into
//! per-field `f64` columns, and the variable table becomes the `.mat`-shaped
//! `MatVariable` list, so everything built on [`ResultTable`] reads both formats
//! alike. An alias with `scale: -1` is the `.mat`'s negative index; any other
//! `scale`/`offset` gets a column of its own, computed here, so the consumers of
//! the index convention need not know about affine aliases.
//!
//! A file without a trailer (a run still writing, or one that died) is read up
//! to its last complete record batch. A plain Arrow IPC stream or file without
//! the variable table is read as one variable per field, the first field (or
//! one named `time`) being time.

#![allow(non_snake_case)]

use std::collections::HashMap;
use std::io::Cursor;

use arrow_array::types::Int32Type;
use arrow_array::{Array, ArrayRef, BooleanArray, DictionaryArray, Float32Array, Float64Array, Int16Array, Int32Array, Int64Array, Int8Array, LargeStringArray, RecordBatch, RunArray, StringArray, UInt16Array, UInt32Array, UInt64Array, UInt8Array, UnionArray};
use arrow_ipc::reader::{FileReader, StreamReader};
use arrow_schema::{DataType, SchemaRef};
use openmodelica_arrow_writer::units::{self, BaseUnit, DisplayUnit, UnitDef};
use openmodelica_arrow_writer::{FORMAT_KEY, FORMAT_VERSION, START_TIME_KEY, STOP_TIME_KEY, TABLE_KEY, TRAILER_MAGIC};
use openmodelica_mat_reader::{MatVariable, ResultTable, find_closest_points, find_var_in, iws_cmp};

pub struct ArrowReader {
    /// Sorted by [`iws_cmp`], for [`find_var_in`].
    pub allInfo: Vec<MatVariable>,
    pub params: Vec<f64>,
    pub nrows: usize,
    /// Columns, time included: the stored fields and then one per affine alias.
    pub nvar: usize,
    pub nparam: usize,
    /// The String parameters' texts, by 0-based `params` slot.
    pub string_params: HashMap<usize, String>,
    /// `(unit, displayUnit, type, relativeQuantity)` per `allInfo` entry.
    meta: Vec<(String, String, String, bool)>,
    /// The literals per `allInfo` entry of an enumeration variable.
    enums: Vec<Option<Vec<String>>>,
    /// The run's start and stop from the variable table's metadata, else the
    /// time column's ends.
    span: (f64, f64),
    /// Decoded field columns, `cols[0]` the time; NaN-filled for a String field.
    /// Affine aliases follow the fields.
    cols: Vec<Vec<f64>>,
    /// The String and enumeration fields' texts, expanded to one per row.
    strs: Vec<Option<Vec<String>>>,
    /// A String field: no numeric trajectory.
    text_only: Vec<bool>,
    /// Run-end encoded, i.e. a discrete-time signal, per column of `cols`.
    ree: Vec<bool>,
    /// The file's own unit definitions; [`units::predefined`] answers the rest.
    units: Vec<UnitDef>,
}

/// One table of the file.
struct Table {
    schema: SchemaRef,
    batches: Vec<RecordBatch>,
}

impl Table {
    fn name(&self) -> &str {
        self.schema.metadata().get(TABLE_KEY).map_or("", String::as_str)
    }
}

/// The streams of the file, in order, up to the trailer or the last complete
/// batch. A plain IPC file (`ARROW1`) is one table.
fn read_streams(bytes: &[u8]) -> Result<Vec<Table>, String> {
    if bytes.starts_with(b"ARROW1") {
        let reader = FileReader::try_new(Cursor::new(bytes), None).map_err(|e| e.to_string())?;
        let schema = reader.schema();
        return Ok(vec![Table { schema, batches: reader.map_while(Result::ok).collect() }]);
    }
    let mut out = Vec::new();
    let mut cursor = Cursor::new(bytes);
    let end = bytes.len() as u64;
    let trailer = bytes.len() >= 16 && &bytes[bytes.len() - 8..] == TRAILER_MAGIC;
    let content_end = if trailer { end - 16 } else { end };
    while cursor.position() < content_end {
        let mut reader = match StreamReader::try_new(&mut cursor, None) {
            Ok(r) => r,
            Err(e) if out.is_empty() => return Err(e.to_string()),
            Err(_) => break,
        };
        let schema = reader.schema();
        let mut batches = Vec::new();
        let mut complete = true;
        for batch in reader.by_ref() {
            match batch {
                Ok(b) => batches.push(b),
                Err(_) => {
                    complete = false;
                    break;
                }
            }
        }
        drop(reader);
        out.push(Table { schema, batches });
        if !complete {
            break;
        }
    }
    Ok(out)
}

enum Col {
    Num(Vec<f64>),
    Str(Vec<String>),
    /// An enumeration: the 1-based value and the literal per row.
    Enum(Vec<f64>, Vec<String>),
}

/// The literals of a dictionary-encoded column, when it is one.
fn literals(a: &dyn Array) -> Option<Vec<String>> {
    let values = a.as_any().downcast_ref::<DictionaryArray<Int32Type>>()?.values();
    match column(values.as_ref()).ok()? {
        Col::Str(l) => Some(l),
        _ => None,
    }
}

macro_rules! numeric {
    ($any:expr, $($t:ty),*) => {
        $(if let Some(x) = $any.downcast_ref::<$t>() {
            return Ok(Col::Num(x.values().iter().map(|&v| v as f64).collect()));
        })*
    };
}

/// One field of a batch as row values, run-end encoding expanded.
fn column(a: &dyn Array) -> Result<Col, String> {
    let any = a.as_any();
    numeric!(any, Float64Array, Float32Array, Int8Array, Int16Array, Int32Array, Int64Array, UInt8Array, UInt16Array, UInt32Array, UInt64Array);
    if let Some(x) = any.downcast_ref::<BooleanArray>() {
        Ok(Col::Num((0..x.len()).map(|i| if x.value(i) { 1.0 } else { 0.0 }).collect()))
    } else if let Some(x) = any.downcast_ref::<StringArray>() {
        Ok(Col::Str((0..x.len()).map(|i| x.value(i).to_owned()).collect()))
    } else if let Some(x) = any.downcast_ref::<LargeStringArray>() {
        Ok(Col::Str((0..x.len()).map(|i| x.value(i).to_owned()).collect()))
    } else if let Some(x) = any.downcast_ref::<DictionaryArray<Int32Type>>() {
        let Col::Str(literals) = column(x.values().as_ref())? else {
            return Err(format!("unsupported Arrow dictionary type {}", a.data_type()));
        };
        let keys = x.keys();
        let (mut nums, mut texts) = (Vec::with_capacity(keys.len()), Vec::with_capacity(keys.len()));
        for i in 0..keys.len() {
            let k = (!keys.is_null(i)).then(|| keys.value(i)).filter(|&k| k >= 0);
            nums.push(k.map_or(f64::NAN, |k| f64::from(k) + 1.0));
            texts.push(k.and_then(|k| literals.get(k as usize)).cloned().unwrap_or_default());
        }
        Ok(Col::Enum(nums, texts))
    } else if let Some(x) = any.downcast_ref::<RunArray<Int32Type>>() {
        // Runs start at 0 (or at the array's offset); each run end is exclusive.
        let ends = x.run_ends().values();
        let offset = x.run_ends().offset() as i32;
        let n = x.run_ends().len();
        let expand = |k: usize| -> usize {
            let start = if k == 0 { offset } else { ends[k - 1].max(offset) };
            (ends[k].min(offset + n as i32) - start).max(0) as usize
        };
        Ok(match column(x.values().as_ref())? {
            Col::Num(v) => Col::Num((0..ends.len()).flat_map(|k| std::iter::repeat_n(v[k], expand(k))).collect()),
            Col::Str(v) => Col::Str((0..ends.len()).flat_map(|k| std::iter::repeat_n(v[k].clone(), expand(k))).collect()),
            Col::Enum(n, t) => Col::Enum(
                (0..ends.len()).flat_map(|k| std::iter::repeat_n(n[k], expand(k))).collect(),
                (0..ends.len()).flat_map(|k| std::iter::repeat_n(t[k].clone(), expand(k))).collect(),
            ),
        })
    } else {
        Err(format!("unsupported Arrow column type {}", a.data_type()))
    }
}

/// The Arrow type name `var_type` maps to Modelica's, for a field or a union child.
fn type_name(dt: &DataType) -> String {
    match dt {
        DataType::RunEndEncoded(_, v) => type_name(v.data_type()),
        DataType::Dictionary(..) => "enumeration".to_owned(),
        other => other.to_string(),
    }
}

/// A parameter of the union: its `f64` value, its text for a String, its
/// literals for an enumeration.
struct Param {
    value: f64,
    text: Option<String>,
    literals: Option<Vec<String>>,
    ty: String,
}

fn parameters(table: Option<&Table>) -> Result<Vec<Param>, String> {
    let mut out = Vec::new();
    for batch in table.iter().flat_map(|t| &t.batches) {
        let Some(u) = batch.columns().first().and_then(|c| c.as_any().downcast_ref::<UnionArray>()) else {
            return Err("parameter table has no union column".into());
        };
        let DataType::Union(fields, _) = u.data_type() else { unreachable!() };
        let mut decoded: HashMap<i8, (Col, Option<Vec<String>>, String)> = HashMap::new();
        for (id, field) in fields.iter() {
            let child = u.child(id);
            decoded.insert(id, (column(child.as_ref())?, literals(child.as_ref()), type_name(field.data_type())));
        }
        for i in 0..u.len() {
            let (col, lits, ty) = &decoded[&u.type_id(i)];
            let at = u.value_offset(i);
            let (value, text) = match col {
                Col::Num(v) => (v[at], None),
                Col::Str(s) => (f64::NAN, Some(s[at].clone())),
                Col::Enum(v, _) => (v[at], None),
            };
            out.push(Param { value, text, literals: lits.clone(), ty: ty.clone() });
        }
    }
    Ok(out)
}

fn str_col<'a>(batch: &'a RecordBatch, name: &str) -> Option<&'a StringArray> {
    batch.column_by_name(name)?.as_any().downcast_ref::<StringArray>()
}

fn num_col<'a, T: Array + 'static>(batch: &'a RecordBatch, name: &str) -> Option<&'a T> {
    batch.column_by_name(name)?.as_any().downcast_ref::<T>()
}

fn f64_at(batch: &RecordBatch, name: &str, i: usize, dflt: f64) -> f64 {
    num_col::<Float64Array>(batch, name).filter(|c| c.is_valid(i)).map_or(dflt, |c| c.value(i))
}

fn bool_at(batch: &RecordBatch, name: &str, i: usize) -> bool {
    num_col::<BooleanArray>(batch, name).is_some_and(|c| c.is_valid(i) && c.value(i))
}

fn str_at<'a>(batch: &'a RecordBatch, name: &str, i: usize) -> &'a str {
    str_col(batch, name).filter(|c| c.is_valid(i)).map_or("", |c| c.value(i))
}

/// The `modelica.units` and `modelica.displayUnits` tables as definitions: a
/// display unit of a unit without a row of its own is one added to the
/// predefined unit of that name, which `unit_def` completes.
fn unit_defs(units: Option<&Table>, display: Option<&Table>) -> Vec<UnitDef> {
    let mut out: Vec<UnitDef> = Vec::new();
    for batch in units.iter().flat_map(|t| &t.batches) {
        for i in 0..batch.num_rows() {
            let name = str_at(batch, "name", i);
            if name.is_empty() {
                continue;
            }
            let mut exponents = [0i32; 8];
            for (e, k) in units::BASE_EXPONENTS.iter().enumerate() {
                exponents[e] = num_col::<Int8Array>(batch, k).filter(|c| c.is_valid(i)).map_or(0, |c| i32::from(c.value(i)));
            }
            let base = (num_col::<BooleanArray>(batch, "baseUnit").is_none_or(|c| c.value(i)))
                .then(|| BaseUnit { exponents, factor: f64_at(batch, "factor", i, 1.0), offset: f64_at(batch, "offset", i, 0.0) });
            out.push(UnitDef { name: name.to_owned(), base, display_units: Vec::new() });
        }
    }
    for batch in display.iter().flat_map(|t| &t.batches) {
        for i in 0..batch.num_rows() {
            let (unit, name) = (str_at(batch, "unit", i), str_at(batch, "name", i));
            if unit.is_empty() || name.is_empty() {
                continue;
            }
            let d = DisplayUnit { name: name.to_owned(), factor: f64_at(batch, "factor", i, 1.0), offset: f64_at(batch, "offset", i, 0.0), inverse: bool_at(batch, "inverse", i) };
            match out.iter_mut().find(|u| u.name == unit) {
                Some(u) => u.display_units.push(d),
                None => out.push(UnitDef { name: unit.to_owned(), base: None, display_units: vec![d] }),
            }
        }
    }
    out
}

impl ArrowReader {
    pub fn open(filename: &str) -> Result<ArrowReader, String> {
        let bytes = openmodelica_wasi::fs::read(filename).map_err(|e| e.to_string())?;
        ArrowReader::from_bytes(bytes)
    }

    pub fn from_bytes(bytes: Vec<u8>) -> Result<ArrowReader, String> {
        let tables = read_streams(&bytes)?;
        let find = |name: &str| tables.iter().find(|t| t.name() == name);
        let (variables, data) = match (find("variables"), find("data")) {
            (Some(v), Some(d)) => (Some(v), d),
            // A plain Arrow stream or file: no tables, one variable per field.
            (None, _) if tables.len() == 1 && tables[0].name().is_empty() => (None, &tables[0]),
            (Some(_), None) => return Err("arrow.modelica file has no data stream".into()),
            _ => return Err("not an arrow.modelica file: no variable table".into()),
        };
        // Major version 0 is development: only the exact version is read.
        if let Some(v) = variables.and_then(|t| t.schema.metadata().get(FORMAT_KEY)) {
            if v != FORMAT_VERSION && (v.starts_with("0.") || !v.starts_with(FORMAT_VERSION.split('.').next().unwrap_or(""))) {
                return Err(format!("arrow.modelica format {v}; this reader knows {FORMAT_VERSION}"));
            }
        }
        let units = unit_defs(find("units"), find("displayUnits"));
        let params_in = parameters(find("parameters"))?;

        let schema = &data.schema;
        let nfields = schema.fields().len();
        let mut cols: Vec<Vec<f64>> = vec![Vec::new(); nfields];
        let mut strs: Vec<Option<Vec<String>>> = vec![None; nfields];
        let mut text_only = vec![false; nfields];
        let mut literals: Vec<Option<Vec<String>>> = vec![None; nfields];
        let mut ree: Vec<bool> = schema.fields().iter().map(|f| matches!(f.data_type(), DataType::RunEndEncoded(..))).collect();
        for batch in &data.batches {
            for (c, col) in batch.columns().iter().enumerate() {
                match column(col.as_ref())? {
                    Col::Num(v) => cols[c].extend(v),
                    Col::Str(v) => {
                        cols[c].extend(std::iter::repeat_n(f64::NAN, v.len()));
                        strs[c].get_or_insert_with(Vec::new).extend(v);
                        text_only[c] = true;
                    }
                    Col::Enum(n, t) => {
                        cols[c].extend(n);
                        strs[c].get_or_insert_with(Vec::new).extend(t);
                        if literals[c].is_none() {
                            let values: &ArrayRef = match col.as_any().downcast_ref::<RunArray<Int32Type>>() {
                                Some(r) => r.values(),
                                None => col,
                            };
                            literals[c] = self::literals(values.as_ref());
                        }
                    }
                }
            }
        }
        let field_types: Vec<String> = schema.fields().iter().map(|f| type_name(f.data_type())).collect();
        // A foreign file's time column need not be first: it is swapped into
        // place, and the field it displaces takes its slot.
        let is_time = |f: &arrow_schema::Field| f.name() == "time" || f.name() == "Time";
        let time_at = schema.fields().iter().position(|f| is_time(f)).filter(|_| variables.is_none()).unwrap_or(0);
        if time_at != 0 {
            cols.swap(0, time_at);
            strs.swap(0, time_at);
            text_only.swap(0, time_at);
            ree.swap(0, time_at);
        }
        let nrows = cols.first().map_or(0, Vec::len);

        let mut allInfo = Vec::new();
        let mut params = Vec::new();
        let mut meta = Vec::new();
        let mut enums = Vec::new();
        let mut string_params: HashMap<usize, String> = HashMap::new();
        match variables {
            Some(table) => {
                for batch in &table.batches {
                    let Some(names) = str_col(batch, "name") else { return Err("variable table has no name column".into()) };
                    let column_ix = num_col::<Int32Array>(batch, "column");
                    for i in 0..batch.num_rows() {
                        let name = names.value(i);
                        if name.is_empty() {
                            continue;
                        }
                        let is_param = bool_at(batch, "parameter", i);
                        let at = column_ix.map_or(0, |c| c.value(i)).max(0) as usize;
                        let (scale, offset) = (f64_at(batch, "scale", i, 1.0), f64_at(batch, "offset", i, 0.0));
                        let (ty, literals_of, index) = if is_param {
                            let p = params_in.get(at).ok_or_else(|| format!("{name}: parameter row {at} is not in the file"))?;
                            params.push(scale * p.value + offset);
                            if let Some(text) = &p.text {
                                string_params.insert(params.len() - 1, text.clone());
                            }
                            (p.ty.clone(), p.literals.clone(), params.len() as i32)
                        } else {
                            let ix = at as i32 + 1;
                            let index = if scale == 1.0 && offset == 0.0 {
                                ix
                            } else if scale == -1.0 && offset == 0.0 {
                                -ix
                            } else {
                                let derived = cols.get(at).map(|c| c.iter().map(|v| scale * v + offset).collect()).unwrap_or_default();
                                cols.push(derived);
                                strs.push(None);
                                text_only.push(false);
                                ree.push(ree.get(at).copied().unwrap_or(false));
                                cols.len() as i32
                            };
                            (field_types.get(at).cloned().unwrap_or_default(), literals.get(at).cloned().flatten(), index)
                        };
                        allInfo.push(MatVariable { name: name.to_owned(), descr: str_at(batch, "description", i).to_owned(), isParam: is_param, index });
                        meta.push((str_at(batch, "unit", i).to_owned(), str_at(batch, "displayUnit", i).to_owned(), ty, bool_at(batch, "relativeQuantity", i)));
                        enums.push(literals_of);
                    }
                }
            }
            None => {
                for (i, f) in schema.fields().iter().enumerate() {
                    let md = f.metadata();
                    let get = |k: &str| md.get(k).cloned().unwrap_or_default();
                    let ix = if is_time(f) { 1 } else if i == 0 { time_at as i32 + 1 } else { i as i32 + 1 };
                    allInfo.push(MatVariable { name: f.name().clone(), descr: get("description"), isParam: false, index: ix });
                    meta.push((get("unit"), get("displayUnit"), field_types[i].clone(), get("relativeQuantity") == "true"));
                    enums.push(literals[i].clone());
                }
            }
        }
        let mut order: Vec<usize> = (0..allInfo.len()).collect();
        order.sort_by(|&a, &b| iws_cmp(&allInfo[a].name, &allInfo[b].name));
        let allInfo: Vec<MatVariable> = order.iter().map(|&i| allInfo[i].clone()).collect();
        let meta: Vec<(String, String, String, bool)> = order.iter().map(|&i| meta[i].clone()).collect();
        let enums: Vec<Option<Vec<String>>> = order.iter().map(|&i| enums[i].clone()).collect();
        let ends = (cols.first().and_then(|c| c.first()).copied().unwrap_or(f64::NAN), cols.first().and_then(|c| c.last()).copied().unwrap_or(f64::NAN));
        let time_md = |k: &str| variables.and_then(|t| t.schema.metadata().get(k)).and_then(|v| v.parse::<f64>().ok());
        let span = (time_md(START_TIME_KEY).unwrap_or(ends.0), time_md(STOP_TIME_KEY).unwrap_or(ends.1));
        Ok(ArrowReader { allInfo, nparam: params.len(), params, string_params, nrows, nvar: cols.len(), span, meta, enums, cols, strs, text_only, ree, units })
    }

    /// The definition of `name`: the file's own entry over the predefined one.
    ///
    /// An entry carries only what it declares, so the predefined display units
    /// of the same name are added to it — a file that spells a unit out for one
    /// display unit does not repeat the twenty a reader already knows. Where the
    /// two disagree about the dimensions they are different units that share a
    /// name, and the file's stands alone.
    pub fn unit_def(&self, name: &str) -> Option<UnitDef> {
        let own = self.units.iter().find(|u| u.name == name).cloned();
        match own {
            Some(mut u) => {
                u.add_predefined_display_units();
                Some(u)
            }
            None => units::predefined(name),
        }
    }

    /// Every unit the file's variables name, defined. A display unit is not one:
    /// it lives inside the definition of the unit it displays.
    pub fn unit_defs(&self) -> Vec<UnitDef> {
        let mut names: Vec<&str> = Vec::new();
        for (u, _, _, _) in &self.meta {
            if !u.is_empty() && !names.contains(&u.as_str()) {
                names.push(u);
            }
        }
        names.iter().filter_map(|n| self.unit_def(n)).collect()
    }

    fn single_val(&self, index: i32, row: usize) -> Option<f64> {
        let col = self.cols.get(index.unsigned_abs() as usize - 1)?;
        let v = *col.get(row)?;
        Some(if index < 0 { -v } else { v })
    }
}

impl ResultTable for ArrowReader {
    fn all_info(&self) -> &[MatVariable] {
        &self.allInfo
    }
    fn params(&self) -> &[f64] {
        &self.params
    }
    fn nrows(&self) -> usize {
        self.nrows
    }
    fn nvar(&self) -> usize {
        self.nvar
    }
    fn nparam(&self) -> usize {
        self.nparam
    }
    fn find_var(&self, name: &str) -> Option<usize> {
        find_var_in(&self.allInfo, name)
    }
    fn read_vals(&mut self, index: i32) -> Option<Vec<f64>> {
        if index == 0 {
            return None;
        }
        let field = index.unsigned_abs() as usize - 1;
        if self.text_only.get(field).copied().unwrap_or(false) {
            return None;
        }
        let col = self.cols.get(field)?;
        Some(if index < 0 { col.iter().map(|v| -v).collect() } else { col.clone() })
    }
    fn read_strings(&mut self, index: i32) -> Option<Vec<String>> {
        if index == 0 {
            return None;
        }
        self.strs.get(index.unsigned_abs() as usize - 1)?.clone()
    }
    fn val(&mut self, var_idx: usize, time: f64) -> Option<f64> {
        let (is_param, index) = self.allInfo.get(var_idx).map(|i| (i.isParam, i.index))?;
        if is_param {
            let p = *self.params.get(index.unsigned_abs() as usize - 1)?;
            return Some(if index < 0 { -p } else { p });
        }
        if time > self.stop_time() || time < self.start_time() {
            return None;
        }
        self.interp_val(index, time)
    }
    fn interp_val(&mut self, index: i32, time: f64) -> Option<f64> {
        let timevec = self.cols.first()?;
        let (i1, w1, i2, w2) = find_closest_points(time, timevec);
        if i2 < 0 {
            self.single_val(index, i1 as usize)
        } else if i1 < 0 {
            self.single_val(index, i2 as usize)
        } else {
            let y1 = self.single_val(index, i1 as usize)?;
            let y2 = self.single_val(index, i2 as usize)?;
            Some(w1 * y1 + w2 * y2)
        }
    }
    fn start_time(&mut self) -> f64 {
        self.span.0
    }
    fn stop_time(&mut self) -> f64 {
        self.span.1
    }
    fn read_all(&mut self) -> bool {
        true
    }
    fn unit(&self, idx: usize) -> (&str, &str) {
        self.meta.get(idx).map_or(("", ""), |m| (m.0.as_str(), m.1.as_str()))
    }
    /// The file names types the way Arrow does; `ResultTable` answers in the
    /// Modelica names its callers and the `.mat` reader use, so the two formats
    /// agree.
    fn var_type(&self, idx: usize) -> &str {
        if self.enums.get(idx).is_some_and(Option::is_some) {
            return "enumeration";
        }
        match self.meta.get(idx).map_or("", |m| m.2.as_str()) {
            "Utf8" | "LargeUtf8" | "Utf8View" | "Binary" | "LargeBinary" | "String" => "String",
            "Boolean" => "Boolean",
            "Float32" | "Float64" | "Float16" | "Real" | "" => "Real",
            "enumeration" => "enumeration",
            // Every Arrow integer width.
            _ => "Integer",
        }
    }
    fn relative_quantity(&self, idx: usize) -> bool {
        self.meta.get(idx).is_some_and(|m| m.3)
    }
    /// The encoding is the statement: a run-end encoded column is discrete-time.
    fn discrete(&self, idx: usize) -> bool {
        let Some(i) = self.allInfo.get(idx).filter(|i| !i.isParam && i.index != 0) else { return false };
        self.ree.get(i.index.unsigned_abs() as usize - 1).copied().unwrap_or(false)
    }
    fn enumeration(&self, idx: usize) -> Option<Vec<String>> {
        self.enums.get(idx).cloned().flatten()
    }
    fn param_string(&self, idx: usize) -> Option<String> {
        let i = self.allInfo.get(idx)?;
        if !i.isParam {
            return None;
        }
        self.string_params.get(&(i.index.unsigned_abs() as usize - 1)).cloned()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use openmodelica_arrow_writer::{Affine, ArrowKind, ArrowStream, ArrowVar, ColTy, FileMeta, VarTy, no_strings, write_arrow};

    fn var<'a>(name: &'a str, ty: VarTy, kind: ArrowKind) -> ArrowVar<'a> {
        ArrowVar { name, comment: "", unit: "", display_unit: "", relative_quantity: false, ty, discrete: false, kind, unvarying: false, enumeration: None }
    }

    fn time() -> ArrowVar<'static> {
        ArrowVar { unit: "s", ..var("time", VarTy::Real, ArrowKind::Time) }
    }

    #[test]
    fn enumerations_read_as_values_and_literals() {
        let e: Vec<String> = ["one", "two", "three"].map(String::from).to_vec();
        let vars = [
            time(),
            ArrowVar { discrete: true, enumeration: Some(&e), ..var("e", VarTy::Integer, ArrowKind::Column { col: 1, affine: Affine::IDENTITY }) },
            ArrowVar { enumeration: Some(&e), ..var("ep", VarTy::Integer, ArrowKind::Param { affine: Affine::IDENTITY }) },
        ];
        let rows = [0.0, 1.0, 0.5, 1.0, 1.0, 3.0];
        let bytes = write_arrow(&vars, &rows, 2, &[2.0], &[ColTy::F64, ColTy::I32], no_strings(), &FileMeta::default());
        let mut r = ArrowReader::from_bytes(bytes).expect("readable");
        let v = r.find_var("e").expect("e");
        assert_eq!(r.var_type(v), "enumeration");
        assert_eq!(r.enumeration(v), Some(e.clone()));
        assert!(r.discrete(v));
        let index = r.all_info()[v].index;
        assert_eq!(r.read_vals(index), Some(vec![1.0, 1.0, 3.0]));
        assert_eq!(r.read_strings(index), Some(["one", "one", "three"].map(String::from).to_vec()));
        let p = r.find_var("ep").expect("ep");
        assert_eq!(r.val(p, 0.0), Some(2.0));
        assert_eq!(r.var_type(p), "enumeration");
        assert_eq!(r.enumeration(p), Some(e));
    }

    #[test]
    fn typed_parameters_and_aliases_read_back() {
        let param = |name, ty, affine| var(name, ty, ArrowKind::Param { affine });
        let vars = [
            time(),
            ArrowVar { unit: "m", display_unit: "mm", comment: "a state", ..var("x", VarTy::Real, ArrowKind::Column { col: 1, affine: Affine::IDENTITY }) },
            var("mx", VarTy::Real, ArrowKind::Column { col: 1, affine: Affine::NEGATE }),
            var("y", VarTy::Real, ArrowKind::Column { col: 1, affine: Affine { scale: 2.0, offset: 3.0 } }),
            ArrowVar { discrete: true, ..var("b", VarTy::Boolean, ArrowKind::Column { col: 2, affine: Affine::IDENTITY }) },
            ArrowVar { discrete: true, ..var("nb", VarTy::Boolean, ArrowKind::Column { col: 2, affine: Affine::NOT }) },
            param("bp", VarTy::Boolean, Affine::IDENTITY),
            param("n", VarTy::Integer, Affine::NEGATE),
            param("p", VarTy::Real, Affine::IDENTITY),
            param("sp", VarTy::String, Affine::IDENTITY),
        ];
        let rows = [0.0, 1.0, 1.0, 0.5, 2.0, 0.0, 1.0, 3.0, 1.0];
        let resolve: openmodelica_arrow_writer::Resolve = Box::new(|_| "hello".to_owned());
        let bytes = write_arrow(&vars, &rows, 3, &[1.0, 3.0, 2.5, 0.0], &[ColTy::F64, ColTy::F64, ColTy::Bool], resolve, &FileMeta { span: Some((0.0, 1.0)), ..FileMeta::default() });
        let mut r = ArrowReader::from_bytes(bytes).expect("readable");
        assert_eq!(r.nrows, 3);
        assert_eq!(r.nparam, 4);
        let get = |r: &mut ArrowReader, name: &str, t: f64| {
            let i = r.find_var(name).unwrap_or_else(|| panic!("{name}"));
            r.val(i, t)
        };
        assert_eq!(get(&mut r, "x", 0.5), Some(2.0));
        assert_eq!(get(&mut r, "mx", 0.5), Some(-2.0));
        assert_eq!(get(&mut r, "y", 0.5), Some(7.0));
        assert_eq!(get(&mut r, "b", 0.5), Some(0.0));
        assert_eq!(get(&mut r, "nb", 0.5), Some(1.0));
        assert_eq!(get(&mut r, "bp", 0.0), Some(1.0));
        assert_eq!(get(&mut r, "n", 0.0), Some(-3.0));
        assert_eq!(get(&mut r, "p", 0.0), Some(2.5));
        let sp = r.find_var("sp").unwrap();
        assert_eq!(r.param_string(sp), Some("hello".to_owned()));
        assert_eq!(r.var_type(sp), "String");
        let x = r.find_var("x").unwrap();
        assert_eq!(r.unit(x), ("m", "mm"));
        assert_eq!(r.var_type(x), "Real");
        assert_eq!(r.all_info()[x].descr, "a state");
        assert!(!r.discrete(x));
        let b = r.find_var("b").unwrap();
        assert_eq!(r.var_type(b), "Boolean");
        assert!(r.discrete(b));
        assert_eq!(r.var_type(r.find_var("n").unwrap()), "Integer");
        assert_eq!(r.stop_time(), 1.0);
    }

    #[test]
    fn a_file_without_trailer_reads_up_to_the_last_block() {
        let vars = [time(), var("x", VarTy::Real, ArrowKind::Column { col: 1, affine: Affine::IDENTITY })];
        let rows: Vec<f64> = (0..7).flat_map(|i| [i as f64, 10.0 * i as f64]).collect();
        let mut out = Vec::new();
        let mut s = ArrowStream::begin(&mut out, &vars, &[], &rows[..2], 2, &[ColTy::F64, ColTy::F64], 3, no_strings(), &FileMeta { span: Some((0.0, 6.0)), ..FileMeta::default() });
        s.push_rows(&mut out, &rows);
        // Two complete blocks (6 rows) are on disk; the seventh row is pending, no trailer.
        let mut r = ArrowReader::from_bytes(out.clone()).expect("unfinished file");
        assert_eq!(r.nrows, 6);
        let x = r.find_var("x").expect("x");
        assert_eq!(r.val(x, 5.0), Some(50.0));
        // A partially written batch is dropped too.
        out.truncate(out.len() - 5);
        assert_eq!(ArrowReader::from_bytes(out).expect("truncated file").nrows, 3);
    }

    #[test]
    fn units_come_back_merged_with_the_predefined_ones() {
        let mut k = UnitDef::new("K");
        k.base = Some(BaseUnit { exponents: [0, 0, 0, 0, 1, 0, 0, 0], ..BaseUnit::default() });
        k.display_units.push(DisplayUnit::new("degF", 1.8, -459.67));
        let mut thing = UnitDef::new("thing");
        thing.base = Some(BaseUnit { exponents: [0, 0, 0, 0, 0, 0, 0, 3], ..BaseUnit::default() });
        thing.display_units.push(DisplayUnit::new("kthing", 1e-3, 0.0));
        let vars = [
            time(),
            ArrowVar { unit: "K", display_unit: "degF", ..var("t", VarTy::Real, ArrowKind::Column { col: 1, affine: Affine::IDENTITY }) },
            ArrowVar { unit: "thing", ..var("w", VarTy::Real, ArrowKind::Column { col: 2, affine: Affine::IDENTITY }) },
        ];
        let bytes = write_arrow(&vars, &[0.0, 300.0, 1.0], 3, &[], &[ColTy::F64; 3], no_strings(), &FileMeta { units: &[k, thing], ..FileMeta::default() });
        let r = ArrowReader::from_bytes(bytes).expect("readable");
        let k = r.unit_def("K").expect("K");
        assert_eq!(k.base.as_ref().map(|b| b.exponents[4]), Some(1));
        assert_eq!(k.display_unit("degF").map(|d| d.offset), Some(-459.67), "the file's own");
        assert_eq!(k.display_unit("degC").map(|d| d.offset), Some(-273.15), "the predefined one");
        let thing = r.unit_def("thing").expect("thing");
        assert_eq!(thing.base.as_ref().map(|b| b.exponents[7]), Some(3));
        assert_eq!(thing.display_units.len(), 1);
        assert_eq!(r.unit_defs().len(), 3);
    }

    /// A plain Arrow IPC stream from another tool, without the variable table.
    #[test]
    fn a_plain_stream_reads_one_variable_per_field() {
        use arrow_ipc::writer::StreamWriter;
        use arrow_schema::{Field, Schema};
        use std::sync::Arc;
        let schema = Schema::new(vec![Field::new("y", DataType::Float64, false), Field::new("time", DataType::Float64, false)]);
        let batch = RecordBatch::try_new(Arc::new(schema.clone()), vec![Arc::new(Float64Array::from(vec![5.0, 6.0])), Arc::new(Float64Array::from(vec![0.0, 1.0]))]).unwrap();
        let mut out = Vec::new();
        let mut w = StreamWriter::try_new(&mut out, &schema).unwrap();
        w.write(&batch).unwrap();
        w.finish().unwrap();
        drop(w);
        let mut r = ArrowReader::from_bytes(out).expect("readable");
        let y = r.find_var("y").expect("y");
        assert_eq!(r.val(y, 0.5), Some(5.5));
    }
}
