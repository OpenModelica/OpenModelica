//! Reader for the `.arrow` result files `openmodelica_arrow_writer` produces:
//! the record batches are decoded once into per-field `f64` columns and the
//! variable table (schema metadata) becomes the `.mat`-shaped `MatVariable`
//! list, so everything built on [`ResultTable`] reads both formats alike. An
//! alias with `scale: -1` is the `.mat`'s negative index; any other
//! `scale`/`offset` gets a column of its own, computed here, so the consumers
//! of the index convention need not know about affine aliases. A plain Arrow
//! IPC file without the variable table is read as one variable per field, the
//! first field (or one named `time`) being time.

#![allow(non_snake_case)]

use std::io::Cursor;

use arrow_array::types::Int32Type;
use arrow_array::{Array, BooleanArray, DictionaryArray, Float32Array, Float64Array, Int32Array, Int64Array, LargeStringArray, RecordBatch, RunArray, StringArray};
use arrow_ipc::reader::{FileReader, StreamReader};
use arrow_schema::SchemaRef;
use openmodelica_arrow_writer::units::{self, BaseUnit, DisplayUnit, UnitDef};
use openmodelica_arrow_writer::{ENUMERATIONS_KEY, START_TIME_KEY, STOP_TIME_KEY, UNITS_KEY, VARIABLES_KEY};
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
    pub string_params: std::collections::HashMap<usize, String>,
    /// `(unit, displayUnit, type, relativeQuantity)` per `allInfo` entry.
    meta: Vec<(String, String, String, bool)>,
    /// The literals per `allInfo` entry of an enumeration variable.
    enums: Vec<Option<Vec<String>>>,
    /// The run's start and stop from the schema metadata, else the time column's ends.
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

enum Col {
    Num(Vec<f64>),
    Str(Vec<String>),
    /// An enumeration: the 1-based value and the literal per row.
    Enum(Vec<f64>, Vec<String>),
}

/// The file's schema and record batches. A file without a footer (a run still
/// writing under `-mat_sync`, or one that died) is read as the IPC stream from
/// the first continuation marker after the magic, up to the last complete batch.
fn read_batches(bytes: &[u8]) -> Result<(SchemaRef, Vec<RecordBatch>), String> {
    match FileReader::try_new(Cursor::new(bytes), None) {
        Ok(reader) => {
            let schema = reader.schema();
            let batches = reader.collect::<Result<Vec<_>, _>>().map_err(|e| e.to_string())?;
            Ok((schema, batches))
        }
        Err(e) => {
            let body = bytes
                .strip_prefix(b"ARROW1")
                .and_then(|rest| rest.windows(4).position(|w| w == [0xff; 4]).map(|at| &rest[at..]))
                .ok_or_else(|| e.to_string())?;
            let reader = StreamReader::try_new(Cursor::new(body), None).map_err(|_| e.to_string())?;
            let schema = reader.schema();
            Ok((schema, reader.map_while(Result::ok).collect()))
        }
    }
}

/// The `modelica.units` table. A malformed entry is dropped rather than failing
/// the file: it costs a display unit, not the data.
fn parse_units(json: &str) -> Vec<UnitDef> {
    let Ok(serde_json::Value::Array(entries)) = serde_json::from_str::<serde_json::Value>(json) else {
        return Vec::new();
    };
    let num = |v: &serde_json::Value, k: &str, dflt: f64| v.get(k).and_then(serde_json::Value::as_f64).unwrap_or(dflt);
    let mut out = Vec::new();
    for e in &entries {
        let Some(name) = e.get("name").and_then(|v| v.as_str()).filter(|n| !n.is_empty()) else { continue };
        let base = e.get("baseUnit").map(|b| {
            let mut exponents = [0i32; 8];
            for (i, k) in units::BASE_EXPONENTS.iter().enumerate() {
                exponents[i] = b.get(k).and_then(serde_json::Value::as_i64).unwrap_or(0) as i32;
            }
            BaseUnit { exponents, factor: num(b, "factor", 1.0), offset: num(b, "offset", 0.0) }
        });
        let display_units = match e.get("displayUnits") {
            Some(serde_json::Value::Array(ds)) => ds
                .iter()
                .filter_map(|d| {
                    let n = d.get("name").and_then(|v| v.as_str()).filter(|n| !n.is_empty())?;
                    Some(DisplayUnit {
                        name: n.to_owned(),
                        factor: num(d, "factor", 1.0),
                        offset: num(d, "offset", 0.0),
                        inverse: d.get("inverse").and_then(serde_json::Value::as_bool).unwrap_or(false),
                    })
                })
                .collect(),
            _ => Vec::new(),
        };
        out.push(UnitDef { name: name.to_owned(), base, display_units });
    }
    out
}

/// One field of a batch as row values, run-end encoding expanded.
fn column(a: &dyn Array) -> Result<Col, String> {
    let any = a.as_any();
    if let Some(x) = any.downcast_ref::<Float64Array>() {
        Ok(Col::Num(x.values().to_vec()))
    } else if let Some(x) = any.downcast_ref::<Float32Array>() {
        Ok(Col::Num(x.values().iter().map(|&v| f64::from(v)).collect()))
    } else if let Some(x) = any.downcast_ref::<Int32Array>() {
        Ok(Col::Num(x.values().iter().map(|&v| f64::from(v)).collect()))
    } else if let Some(x) = any.downcast_ref::<Int64Array>() {
        Ok(Col::Num(x.values().iter().map(|&v| v as f64).collect()))
    } else if let Some(x) = any.downcast_ref::<BooleanArray>() {
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

impl ArrowReader {
    pub fn open(filename: &str) -> Result<ArrowReader, String> {
        let bytes = openmodelica_wasi::fs::read(filename).map_err(|e| e.to_string())?;
        ArrowReader::from_bytes(bytes)
    }

    pub fn from_bytes(bytes: Vec<u8>) -> Result<ArrowReader, String> {
        let (schema, batches) = read_batches(&bytes)?;
        let units = schema.metadata().get(UNITS_KEY).map_or_else(Vec::new, |s| parse_units(s));
        let nfields = schema.fields().len();
        let mut cols: Vec<Vec<f64>> = vec![Vec::new(); nfields];
        let mut strs: Vec<Option<Vec<String>>> = vec![None; nfields];
        let mut text_only = vec![false; nfields];
        let mut ree: Vec<bool> = schema.fields().iter().map(|f| matches!(f.data_type(), arrow_schema::DataType::RunEndEncoded(..))).collect();
        for batch in batches {
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
                    }
                }
            }
        }
        // A foreign file's time column need not be first.
        if let Some(t) = schema.fields().iter().position(|f| f.name() == "time" || f.name() == "Time") {
            if t != 0 {
                cols.swap(0, t);
                strs.swap(0, t);
                text_only.swap(0, t);
                ree.swap(0, t);
            }
        }
        let nrows = cols.first().map_or(0, Vec::len);
        let mut allInfo = Vec::new();
        let mut params = Vec::new();
        let mut meta = Vec::new();
        let mut enums = Vec::new();
        let enum_types: Vec<Vec<String>> = schema
            .metadata()
            .get(ENUMERATIONS_KEY)
            .and_then(|s| serde_json::from_str(s).ok())
            .unwrap_or_default();
        let mut string_params: std::collections::HashMap<usize, String> = std::collections::HashMap::new();
        let field_pos = |name: &str| schema.fields().iter().position(|f| f.name() == name);
        match schema.metadata().get(VARIABLES_KEY).map(|s| serde_json::from_str::<serde_json::Value>(s)) {
            Some(Ok(serde_json::Value::Array(entries))) => {
                for e in &entries {
                    let str_of = |k: &str| e.get(k).and_then(|v| v.as_str()).unwrap_or("").to_owned();
                    let name = str_of("name");
                    if name.is_empty() {
                        continue;
                    }
                    let (isParam, index) = match e.get("kind").and_then(|v| v.as_str()).unwrap_or("variable") {
                        "parameter" => {
                            params.push(e.get("value").and_then(|v| v.as_f64()).unwrap_or(f64::NAN));
                            if let Some(text) = e.get("value").and_then(|v| v.as_str()) {
                                string_params.insert(params.len() - 1, text.to_owned());
                            }
                            (true, params.len() as i32)
                        }
                        _ => {
                            let field = e.get("column").and_then(|v| v.as_u64()).unwrap_or(0) as usize;
                            // The time column was moved to 0 above.
                            let field = match schema.fields().get(field) {
                                Some(f) if f.name() == "time" || f.name() == "Time" => 0,
                                _ if field == 0 => field_pos("time").or_else(|| field_pos("Time")).unwrap_or(0),
                                _ => field,
                            };
                            let num = |k: &str, dflt: f64| e.get(k).and_then(|v| v.as_f64()).unwrap_or(dflt);
                            let (scale, offset) = (num("scale", 1.0), num("offset", 0.0));
                            let ix = field as i32 + 1;
                            if scale == 1.0 && offset == 0.0 {
                                (false, ix)
                            } else if scale == -1.0 && offset == 0.0 {
                                (false, -ix)
                            } else {
                                let derived = cols.get(field).map(|c| c.iter().map(|v| scale * v + offset).collect()).unwrap_or_default();
                                cols.push(derived);
                                strs.push(None);
                                text_only.push(false);
                                ree.push(ree.get(field).copied().unwrap_or(false));
                                (false, cols.len() as i32)
                            }
                        }
                    };
                    allInfo.push(MatVariable { name, descr: str_of("description"), isParam, index });
                    meta.push((str_of("unit"), str_of("displayUnit"), {
                        let t = str_of("type");
                        if t.is_empty() { "Real".to_owned() } else { t }
                    }, e.get("relativeQuantity").and_then(|v| v.as_bool()).unwrap_or(false)));
                    enums.push(e.get("enumeration").and_then(|v| v.as_u64()).and_then(|i| enum_types.get(i as usize).cloned()));
                }
            }
            Some(Err(e)) => return Err(format!("bad {VARIABLES_KEY} metadata: {e}")),
            _ => {
                for (i, f) in schema.fields().iter().enumerate() {
                    let md = f.metadata();
                    let get = |k: &str| md.get(k).cloned().unwrap_or_default();
                    let ix = if f.name() == "time" || f.name() == "Time" { 1 } else if i == 0 { 1 } else { i as i32 + 1 };
                    allInfo.push(MatVariable { name: f.name().clone(), descr: get("description"), isParam: false, index: ix });
                    meta.push((get("unit"), get("displayUnit"), get("type"), get("relativeQuantity") == "true"));
                    enums.push(None);
                }
            }
        }
        let mut order: Vec<usize> = (0..allInfo.len()).collect();
        order.sort_by(|&a, &b| iws_cmp(&allInfo[a].name, &allInfo[b].name));
        let allInfo: Vec<MatVariable> = order.iter().map(|&i| allInfo[i].clone()).collect();
        let meta: Vec<(String, String, String, bool)> = order.iter().map(|&i| meta[i].clone()).collect();
        let enums: Vec<Option<Vec<String>>> = order.iter().map(|&i| enums[i].clone()).collect();
        let ends = (cols.first().and_then(|c| c.first()).copied().unwrap_or(f64::NAN), cols.first().and_then(|c| c.last()).copied().unwrap_or(f64::NAN));
        let time_md = |k: &str| schema.metadata().get(k).and_then(|v| v.parse::<f64>().ok());
        let span = (time_md(START_TIME_KEY).unwrap_or(ends.0), time_md(STOP_TIME_KEY).unwrap_or(ends.1));
        Ok(ArrowReader { allInfo, nparam: params.len(), params, string_params, nrows, nvar: cols.len(), span, meta, enums, cols, strs, text_only, ree, units })
    }

    /// The definition of `name`: the file's own entry, else the predefined one.
    pub fn unit_def(&self, name: &str) -> Option<UnitDef> {
        self.units.iter().find(|u| u.name == name).cloned().or_else(|| units::predefined(name))
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
    /// agree. An enumeration is an `Int32` column that names a literal table.
    fn var_type(&self, idx: usize) -> &str {
        if self.enums.get(idx).is_some_and(Option::is_some) {
            return "enumeration";
        }
        match self.meta.get(idx).map_or("", |m| m.2.as_str()) {
            "Utf8" | "LargeUtf8" | "Binary" | "LargeBinary" | "String" => "String",
            "Boolean" => "Boolean",
            "Float32" | "Float64" | "Real" | "" => "Real",
            // Every Arrow integer width, and the older `Integer` spelling.
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

    /// A file another tool wrote with the enumeration as `Dictionary<Int32, Utf8>`
    /// (key = value - 1) reads like the `Int32` layout OpenModelica writes.
    #[test]
    fn a_dictionary_encoded_enumeration_reads_the_same() {
        use arrow_array::types::Int32Type;
        use arrow_array::{DictionaryArray, Float64Array, Int32Array, StringArray};
        use arrow_ipc::writer::FileWriter;
        use arrow_schema::{DataType, Field, Schema};
        use std::collections::HashMap;
        use std::sync::Arc;
        let dict_type = DataType::Dictionary(Box::new(DataType::Int32), Box::new(DataType::Utf8));
        let e_md = HashMap::from([("type".to_owned(), "enumeration".to_owned()), ("enumeration".to_owned(), "0".to_owned())]);
        let schema = Schema::new_with_metadata(
            vec![Field::new("time", DataType::Float64, false), Field::new("e", dict_type, false).with_metadata(e_md)],
            HashMap::from([
                (VARIABLES_KEY.to_owned(), r#"[{"name":"time","kind":"time","column":0},{"name":"e","kind":"variable","column":1,"type":"enumeration","enumeration":0}]"#.to_owned()),
                (ENUMERATIONS_KEY.to_owned(), r#"[["one","two","three"]]"#.to_owned()),
            ]),
        );
        let keys = Int32Array::from(vec![0, 0, 2]);
        let dict = DictionaryArray::<Int32Type>::try_new(keys, Arc::new(StringArray::from(vec!["one", "two", "three"]))).expect("dictionary");
        let batch = RecordBatch::try_new(Arc::new(schema.clone()), vec![Arc::new(Float64Array::from(vec![0.0, 0.5, 1.0])), Arc::new(dict)]).expect("batch");
        let mut out = Vec::new();
        let mut w = FileWriter::try_new(&mut out, &schema).expect("writer");
        w.write(&batch).expect("write");
        w.finish().expect("finish");
        drop(w);
        let mut r = ArrowReader::from_bytes(out).expect("readable");
        let v = r.find_var("e").expect("e");
        let index = r.all_info()[v].index;
        assert_eq!(r.read_vals(index), Some(vec![1.0, 1.0, 3.0]));
        assert_eq!(r.read_strings(index), Some(["one", "one", "three"].map(String::from).to_vec()));
        assert_eq!(r.enumeration(v), Some(["one", "two", "three"].map(String::from).to_vec()));
    }

    #[test]
    fn enumerations_read_as_values_and_literals() {
        let e: Vec<String> = ["one", "two", "three"].map(String::from).to_vec();
        let vars = [
            ArrowVar { name: "time", comment: "", unit: "s", display_unit: "", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Time, unvarying: false, enumeration: None },
            ArrowVar { name: "e", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Integer, discrete: true, kind: ArrowKind::Column { col: 1, affine: Affine::IDENTITY }, unvarying: false, enumeration: Some(&e) },
            ArrowVar { name: "ep", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Integer, discrete: false, kind: ArrowKind::Param { affine: Affine::IDENTITY }, unvarying: false, enumeration: Some(&e) },
        ];
        let rows = [0.0, 1.0, 0.5, 1.0, 1.0, 3.0];
        let bytes = write_arrow(&vars, &rows, 2, &[2.0], &[ColTy::F64, ColTy::I32], no_strings(), &FileMeta::default());
        let mut r = ArrowReader::from_bytes(bytes).expect("readable");
        let v = r.find_var("e").expect("e");
        assert_eq!(r.var_type(v), "enumeration");
        assert_eq!(r.enumeration(v), Some(e));
        let index = r.all_info()[v].index;
        assert_eq!(r.read_vals(index), Some(vec![1.0, 1.0, 3.0]));
        assert_eq!(r.read_strings(index), None, "an Int32 column carries no texts; ResultFile::strings maps the literals");
        let p = r.find_var("ep").expect("ep");
        assert_eq!(r.val(p, 0.0), Some(2.0));
    }

    #[test]
    fn a_file_without_footer_reads_up_to_the_last_block() {
        let vars = [
            ArrowVar { name: "time", comment: "", unit: "s", display_unit: "", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Time, unvarying: false, enumeration: None },
            ArrowVar { name: "x", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Column { col: 1, affine: Affine::IDENTITY }, unvarying: false, enumeration: None },
        ];
        let rows: Vec<f64> = (0..7).flat_map(|i| [i as f64, 10.0 * i as f64]).collect();
        let mut out = Vec::new();
        let mut s = ArrowStream::begin(&mut out, &vars, &[], &rows[..2], 2, &[ColTy::F64, ColTy::F64], 3, no_strings(), &FileMeta { span: Some((0.0, 6.0)), ..FileMeta::default() });
        s.push_rows(&mut out, &rows);
        // Two complete blocks (6 rows) are on disk; the seventh row is pending, no footer.
        let mut r = ArrowReader::from_bytes(out.clone()).expect("footerless file");
        assert_eq!(r.nrows, 6);
        let x = r.find_var("x").expect("x");
        assert_eq!(r.val(x, 5.0), Some(50.0));
        // A partially written batch is dropped too.
        out.truncate(out.len() - 5);
        assert_eq!(ArrowReader::from_bytes(out).expect("truncated file").nrows, 3);
    }
}
