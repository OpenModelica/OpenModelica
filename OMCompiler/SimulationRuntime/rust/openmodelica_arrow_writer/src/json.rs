//! The layout `openmodelica_arrow_writer` wrote before `arrow.modelica`: one
//! Arrow IPC *file* whose schema metadata carries the variable table as JSON
//! under [`VARIABLES_KEY`], the enumerations under [`ENUMERATIONS_KEY`] and the
//! unit definitions under [`UNITS_KEY`], each field named after the first
//! variable that mentioned its column and carrying `description`, `unit`,
//! `displayUnit` and `type` metadata. A time-invariant variable has a `value`
//! in its JSON entry instead of a `column`.
//!
//! It was never released and nothing in OpenModelica writes or reads it. It is
//! kept, behind the `json-layout` feature, as the *before* of the result-format
//! benchmark and for nothing else.

use std::collections::HashMap;
use std::sync::Arc;

use arrow_array::types::Int32Type;
use arrow_array::{ArrayRef, BooleanArray, Float32Array, Float64Array, Int32Array, RecordBatch, RunArray, StringArray};
use arrow_ipc::writer::FileWriter;
use arrow_schema::{DataType, Field, Schema, SchemaRef};

use crate::{Affine, ArrowKind, ArrowVar, ColTy, FileMeta, Out, Resolve, START_TIME_KEY, STOP_TIME_KEY, VarTy, DEFAULT_BLOCK_ROWS, ree_type, units};

/// Schema metadata key holding the variable table (JSON, see the module docs).
pub const VARIABLES_KEY: &str = "modelica.variables";
pub const FORMAT_KEY: &str = crate::FORMAT_KEY;
/// The distinct enumeration types: a JSON array of literal-name arrays, which
/// the `enumeration` of a variable indexes.
pub const ENUMERATIONS_KEY: &str = "modelica.enumerations";
/// The unit definitions a variable's `unit`/`displayUnit` names, for the units
/// [`units::predefined`] does not already define.
pub const UNITS_KEY: &str = "modelica.units";
pub const FORMAT_VERSION: &str = "1";

/// A stored column: which result-row column feeds it and how.
struct Stored {
    src: usize,
    ty: ColTy,
    affine: Affine,
    /// Run-end encoded (a discrete-time signal).
    ree: bool,
}


/// The distinct enumeration types of a file, [`ENUMERATIONS_KEY`]: Modelica
/// types an enumeration by its literals alone, so equal lists are one type.
#[derive(Default)]
struct Enumerations(Vec<Vec<String>>);

impl Enumerations {
    fn index(&mut self, literals: &[String]) -> usize {
        match self.0.iter().position(|l| l == literals) {
            Some(i) => i,
            None => {
                self.0.push(literals.to_vec());
                self.0.len() - 1
            }
        }
    }
    fn json(&self) -> String {
        let mut json = String::from("[");
        for (i, l) in self.0.iter().enumerate() {
            if i > 0 {
                json.push(',');
            }
            json_str_list(&mut json, l);
        }
        json.push(']');
        json
    }
}

fn json_str_list(out: &mut String, list: &[String]) {
    out.push('[');
    for (i, s) in list.iter().enumerate() {
        if i > 0 {
            out.push(',');
        }
        json_str(out, s);
    }
    out.push(']');
}

pub(crate) fn json_str(out: &mut String, s: &str) {
    out.push('"');
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out.push('"');
}

fn json_f64(out: &mut String, v: f64) {
    if v.is_finite() {
        // Round-trips exactly; JSON has no inf/nan, those become null.
        out.push_str(&format!("{v:?}"));
    } else {
        out.push_str("null");
    }
}

/// Only a stored signal is discrete-time; a parameter's variability is not.
/// A String changes only at events, whatever the model says.
fn is_discrete(v: &ArrowVar) -> bool {
    (v.discrete || v.ty == VarTy::String) && matches!(v.kind, ArrowKind::Column { .. }) && !v.unvarying
}

fn field_metadata(v: &ArrowVar) -> HashMap<String, String> {
    let mut md = HashMap::new();
    if !v.comment.is_empty() {
        md.insert("description".to_owned(), v.comment.to_owned());
    }
    if !v.unit.is_empty() {
        md.insert("unit".to_owned(), v.unit.to_owned());
    }
    if !v.display_unit.is_empty() {
        md.insert("displayUnit".to_owned(), v.display_unit.to_owned());
    }
    if v.relative_quantity {
        md.insert("relativeQuantity".to_owned(), "true".to_owned());
    }
    md.insert("type".to_owned(), type_name(v).to_owned());
    md
}

/// The type a variable has when its entry names none.
const DEFAULT_TYPE: &str = "Float64";

/// The declared type as its Arrow name — the file is an Arrow file, so it names
/// types the way Arrow does. It is the *declared* type, which the storage may
/// narrow: a `Float64` variable is a `Float32` column under `-single`, and a
/// discrete one is run-end encoded over this type. An enumeration is an ordinary
/// `Int32`; the `enumeration` key is what marks it as one.
fn type_name(v: &ArrowVar) -> &'static str {
    match v.ty {
        VarTy::Real => "Float64",
        VarTy::Integer => "Int32",
        VarTy::Boolean => "Boolean",
        VarTy::String => "Utf8",
    }
}

/// The schema and the variable table for `vars`; `stored[i]` feeds field `i + 1`.
fn plan(vars: &[ArrowVar], params: &[f64], first_row: &[f64], col_types: &[ColTy], resolve: &dyn Fn(u32) -> String, file: &FileMeta) -> (SchemaRef, Vec<Stored>) {
    let mut fields: Vec<Field> = Vec::new();
    let mut stored: Vec<Stored> = Vec::new();
    // Result-row column -> (field index, how the field derives from the row).
    let mut owner: HashMap<u32, (usize, Affine)> = HashMap::new();
    let mut json = String::from("[");
    let mut enumerations = Enumerations::default();
    let mut param_ix = 0usize;
    let mut first = true;
    let col_ty = |col: u32| col_types.get(col as usize).copied().unwrap_or(ColTy::F64);

    let field_for = |fields: &mut Vec<Field>, stored: &mut Vec<Stored>, enumerations: &mut Enumerations, v: &ArrowVar, src: u32, affine: Affine| -> usize {
        let ty = col_ty(src);
        let ree = is_discrete(v) || ty == ColTy::Str;
        let data_type = if ree { ree_type(ty.data_type()) } else { ty.data_type() };
        let mut md = field_metadata(v);
        if let Some(e) = v.enumeration {
            md.insert("enumeration".to_owned(), enumerations.index(e).to_string());
        }
        fields.push(Field::new(v.name, data_type, false).with_metadata(md));
        stored.push(Stored { src: src as usize, ty, affine, ree });
        fields.len() - 1
    };

    // `time` is field 0 whether or not the caller lists it (it always does).
    let time_var = vars.iter().find(|v| matches!(v.kind, ArrowKind::Time));
    let time_field = match time_var {
        Some(v) => Field::new("time", DataType::Float64, false).with_metadata(field_metadata(v)),
        None => Field::new("time", DataType::Float64, false)
            .with_metadata(HashMap::from([("unit".to_owned(), "s".to_owned()), ("type".to_owned(), DEFAULT_TYPE.to_owned())])),
    };
    fields.push(time_field);
    owner.insert(0, (0, Affine::IDENTITY));

    for v in vars {
        // (column, alias transform, time-invariant value)
        let (column, affine, value): (Option<usize>, Affine, Option<f64>) = match v.kind {
            ArrowKind::Time => (Some(0), Affine::IDENTITY, None),
            ArrowKind::Param { affine } => {
                let p = params.get(param_ix).copied().unwrap_or(0.0);
                param_ix += 1;
                (None, Affine::IDENTITY, Some(affine.apply(p)))
            }
            ArrowKind::Const { value } => (None, Affine::IDENTITY, Some(value)),
            ArrowKind::Column { col, affine } if v.unvarying => {
                let raw = first_row.get(col as usize).copied().unwrap_or(0.0);
                (None, Affine::IDENTITY, Some(affine.apply(raw)))
            }
            ArrowKind::Column { col, affine } => match owner.get(&col) {
                Some(&(f, base)) => (Some(f), affine.relative_to(base), None),
                None => {
                    let f = field_for(&mut fields, &mut stored, &mut enumerations, v, col, affine);
                    owner.insert(col, (f, affine));
                    (Some(f), Affine::IDENTITY, None)
                }
            },
        };
        if !first {
            json.push(',');
        }
        first = false;
        json.push_str("{\"name\":");
        json_str(&mut json, v.name);
        if let Some(c) = column {
            json.push_str(&format!(",\"column\":{c}"));
        }
        if affine.scale != 1.0 {
            json.push_str(",\"scale\":");
            json_f64(&mut json, affine.scale);
        }
        if affine.offset != 0.0 {
            json.push_str(",\"offset\":");
            json_f64(&mut json, affine.offset);
        }
        // Only a parameter has no column to carry its type and enumeration.
        if let Some(val) = value {
            json.push_str(",\"value\":");
            match v.ty {
                VarTy::String => json_str(&mut json, &resolve(val as u32)),
                VarTy::Boolean => json.push_str(if val != 0.0 { "true" } else { "false" }),
                VarTy::Integer if val.is_finite() => json.push_str(&(val as i64).to_string()),
                _ => json_f64(&mut json, val),
            }
            if type_name(v) != DEFAULT_TYPE {
                json.push_str(",\"type\":\"");
                json.push_str(type_name(v));
                json.push('"');
            }
            if let Some(e) = v.enumeration {
                json.push_str(&format!(",\"enumeration\":{}", enumerations.index(e)));
            }
        }
        if !v.comment.is_empty() {
            json.push_str(",\"description\":");
            json_str(&mut json, v.comment);
        }
        if !v.unit.is_empty() {
            json.push_str(",\"unit\":");
            json_str(&mut json, v.unit);
        }
        if !v.display_unit.is_empty() {
            json.push_str(",\"displayUnit\":");
            json_str(&mut json, v.display_unit);
        }
        if v.relative_quantity {
            json.push_str(",\"relativeQuantity\":true");
        }
        json.push('}');
    }
    json.push(']');
    let mut metadata = HashMap::from([(FORMAT_KEY.to_owned(), FORMAT_VERSION.to_owned()), (VARIABLES_KEY.to_owned(), json)]);
    if !enumerations.0.is_empty() {
        metadata.insert(ENUMERATIONS_KEY.to_owned(), enumerations.json());
    }
    if !file.units.is_empty() {
        metadata.insert(UNITS_KEY.to_owned(), units::units_json(file.units));
    }
    if let Some((start, stop)) = file.span {
        metadata.insert(START_TIME_KEY.to_owned(), format!("{start:?}"));
        metadata.insert(STOP_TIME_KEY.to_owned(), format!("{stop:?}"));
    }
    (Arc::new(Schema::new_with_metadata(fields, metadata)), stored)
}

/// The file written incrementally: schema up front, one record batch per
/// `block_rows` rows, the footer at [`ArrowStream::finish`].
pub struct ArrowStream {
    schema: SchemaRef,
    stored: Vec<Stored>,
    resolve: Resolve,
    writer: FileWriter<Vec<u8>>,
    n_reals: usize,
    block_rows: usize,
    /// Row-major rows not yet written.
    pending: Vec<f64>,
    n_rows: usize,
    finished: bool,
    sync: bool,
}

impl ArrowStream {
    /// `rows` are `n_reals` wide (`[time | reals | ints | bools | ...]`, all as
    /// f64, a String column holding interned ids); `col_types[c]` says how column
    /// `c` is stored. `params` holds the `Param` values in `vars` order (a String
    /// parameter's interned id), `first_row` the initial row (for the `unvarying`
    /// columns), `resolve` the id-to-text lookup, `file` the file-level metadata.
    #[allow(clippy::too_many_arguments)]
    pub fn begin(
        out: &mut dyn Out,
        vars: &[ArrowVar],
        params: &[f64],
        first_row: &[f64],
        n_reals: u32,
        col_types: &[ColTy],
        block_rows: usize,
        resolve: Resolve,
        file: &FileMeta,
    ) -> ArrowStream {
        let (schema, stored) = plan(vars, params, first_row, col_types, &*resolve, file);
        let writer = FileWriter::try_new(Vec::with_capacity(1 << 16), &schema).expect("arrow schema");
        let mut s = ArrowStream {
            schema,
            stored,
            resolve,
            writer,
            n_reals: n_reals.max(1) as usize,
            block_rows: block_rows.max(1),
            pending: Vec::new(),
            n_rows: 0,
            finished: false,
            sync: false,
        };
        s.drain(out);
        s
    }

    /// Flush the sink after every block, so a reader can open the file while it
    /// is written (the `-mat_sync` analogue; pair it with a small `block_rows`).
    pub fn set_sync(&mut self, on: bool) {
        self.sync = on;
    }

    fn drain(&mut self, out: &mut dyn Out) {
        let buf = self.writer.get_mut();
        if !buf.is_empty() {
            out.write(buf);
            buf.clear();
        }
    }

    /// The values of one stored column over the block, as an Arrow array: every
    /// row for a continuous signal, one per run (with the run ends) for a
    /// discrete one.
    fn column(&self, s: &Stored, rows: &[f64], n: usize) -> ArrayRef {
        let at = |r: usize| s.affine.apply(rows[r * self.n_reals + s.src]);
        let array = |picks: &dyn Fn() -> Vec<f64>| -> ArrayRef {
            let v = picks();
            match s.ty {
                ColTy::F64 => Arc::new(Float64Array::from(v)),
                ColTy::F32 => Arc::new(Float32Array::from_iter_values(v.into_iter().map(|x| x as f32))),
                ColTy::I32 => Arc::new(Int32Array::from_iter_values(v.into_iter().map(|x| x as i32))),
                ColTy::Bool => Arc::new(BooleanArray::from_iter(v.into_iter().map(|x| Some(x != 0.0)))),
                ColTy::Str => Arc::new(StringArray::from_iter_values(v.into_iter().map(|x| (self.resolve)(x as u32)))),
            }
        };
        if !s.ree {
            return array(&|| (0..n).map(at).collect());
        }
        let mut run_ends: Vec<i32> = Vec::new();
        let mut run_values: Vec<f64> = Vec::new();
        for r in 0..n {
            let v = at(r);
            match run_values.last() {
                Some(last) if last.to_bits() == v.to_bits() => *run_ends.last_mut().unwrap() = r as i32 + 1,
                _ => {
                    run_values.push(v);
                    run_ends.push(r as i32 + 1);
                }
            }
        }
        let values = array(&|| run_values.clone());
        Arc::new(RunArray::<Int32Type>::try_new(&Int32Array::from(run_ends), values.as_ref()).expect("arrow run array"))
    }

    fn batch(&self, rows: &[f64]) -> RecordBatch {
        let n = rows.len() / self.n_reals;
        let mut columns: Vec<ArrayRef> = Vec::with_capacity(1 + self.stored.len());
        columns.push(Arc::new(Float64Array::from_iter_values((0..n).map(|r| rows[r * self.n_reals]))));
        for s in &self.stored {
            columns.push(self.column(s, rows, n));
        }
        RecordBatch::try_new(self.schema.clone(), columns).expect("arrow batch")
    }

    fn flush_block(&mut self, out: &mut dyn Out, n: usize) {
        let take = n * self.n_reals;
        let batch = self.batch(&self.pending[..take]);
        self.pending.drain(..take);
        self.writer.write(&batch).expect("arrow write");
        self.drain(out);
        if self.sync {
            out.flush();
        }
    }

    /// Append `rows` (row-major, `n_reals` values each).
    pub fn push_rows(&mut self, out: &mut dyn Out, rows: &[f64]) {
        self.pending.extend_from_slice(rows);
        self.n_rows += rows.len() / self.n_reals;
        while self.pending.len() / self.n_reals >= self.block_rows {
            self.flush_block(out, self.block_rows);
        }
    }

    /// Write the last block and the footer. A second call does nothing.
    pub fn finish(&mut self, out: &mut dyn Out) {
        if self.finished {
            return;
        }
        self.finished = true;
        let n = self.pending.len() / self.n_reals;
        if n > 0 {
            self.flush_block(out, n);
        }
        self.writer.finish().expect("arrow finish");
        self.drain(out);
    }

    pub fn n_rows(&self) -> usize {
        self.n_rows
    }
}

/// The whole file at once. `resolve` is needed only with String columns or
/// parameters; [`no_strings`] otherwise.
pub fn write_arrow(vars: &[ArrowVar], rows: &[f64], n_reals: u32, params: &[f64], col_types: &[ColTy], resolve: Resolve, file: &FileMeta) -> Vec<u8> {
    let mut out = Vec::new();
    let n_reals_u = n_reals.max(1) as usize;
    let first_row = rows.get(..n_reals_u).unwrap_or(&[]);
    let mut s = ArrowStream::begin(&mut out, vars, params, first_row, n_reals, col_types, DEFAULT_BLOCK_ROWS, resolve, file);
    s.push_rows(&mut out, rows);
    s.finish(&mut out);
    out
}


#[cfg(test)]
mod tests {
    use super::*;
    use crate::no_strings;
    use arrow_array::Array;
    use arrow_ipc::reader::FileReader;

    #[test]
    fn enumerations_index_one_table() {
        let e: Vec<String> = ["one", "two", "three"].map(String::from).to_vec();
        let f: Vec<String> = ["on", "off"].map(String::from).to_vec();
        let vars = [
            ArrowVar { name: "time", comment: "", unit: "s", display_unit: "", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Time, unvarying: false, enumeration: None },
            ArrowVar { name: "e", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Integer, discrete: true, kind: ArrowKind::Column { col: 1, affine: Affine::IDENTITY }, unvarying: false, enumeration: Some(&e) },
            ArrowVar { name: "ep", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Integer, discrete: false, kind: ArrowKind::Param { affine: Affine::IDENTITY }, unvarying: false, enumeration: Some(&e) },
            ArrowVar { name: "fp", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Integer, discrete: false, kind: ArrowKind::Param { affine: Affine::IDENTITY }, unvarying: false, enumeration: Some(&f) },
        ];
        let rows = [0.0, 1.0, 0.5, 1.0, 1.0, 3.0];
        let bytes = write_arrow(&vars, &rows, 2, &[2.0, 1.0], &[ColTy::F64, ColTy::I32], no_strings(), &FileMeta::default());
        let reader = FileReader::try_new(std::io::Cursor::new(bytes), None).expect("readable");
        let schema = reader.schema();
        let f = &schema.fields()[1];
        assert_eq!(f.metadata()["type"], "Int32");
        assert_eq!(f.metadata()["enumeration"], "0");
        assert_eq!(*f.data_type(), ree_type(DataType::Int32));
        assert_eq!(schema.metadata()[ENUMERATIONS_KEY], r#"[["one","two","three"],["on","off"]]"#);
        let json = &schema.metadata()[VARIABLES_KEY];
        assert!(json.contains(r#""name":"ep","value":2,"type":"Int32","enumeration":0"#), "{json}");
        assert!(json.contains(r#""name":"fp","value":1,"type":"Int32","enumeration":1"#), "{json}");
        let batch = reader.into_iter().next().expect("a batch").expect("ok");
        let ree = batch.column(1).as_any().downcast_ref::<RunArray<Int32Type>>().expect("run-end encoded");
        assert_eq!(ree.values().as_any().downcast_ref::<Int32Array>().expect("int32").values(), &[1, 3]);
    }

    #[test]
    fn aliases_share_a_column() {
        let vars = [
            ArrowVar { name: "time", comment: "", unit: "s", display_unit: "", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Time, unvarying: false, enumeration: None },
            ArrowVar { name: "x", comment: "a state", unit: "m", display_unit: "mm", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Column { col: 1, affine: Affine::IDENTITY }, unvarying: false, enumeration: None },
            ArrowVar { name: "mx", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Column { col: 1, affine: Affine::NEGATE }, unvarying: false, enumeration: None },
            ArrowVar { name: "b", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Boolean, discrete: true, kind: ArrowKind::Column { col: 2, affine: Affine::IDENTITY }, unvarying: false, enumeration: None },
            ArrowVar { name: "nb", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Boolean, discrete: true, kind: ArrowKind::Column { col: 2, affine: Affine::NOT }, unvarying: false, enumeration: None },
            ArrowVar { name: "p", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Param { affine: Affine::NEGATE }, unvarying: false, enumeration: None },
            ArrowVar { name: "u", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Column { col: 3, affine: Affine::IDENTITY }, unvarying: true, enumeration: None },
        ];
        let rows = [0.0, 1.0, 1.0, 7.0, 0.5, 2.0, 0.0, 7.0, 1.0, 3.0, 1.0, 7.0];
        let bytes = write_arrow(&vars, &rows, 4, &[2.5], &[ColTy::F64, ColTy::F64, ColTy::Bool, ColTy::F64], no_strings(), &FileMeta { span: Some((0.0, 1.0)), ..FileMeta::default() });
        let r = FileReader::try_new(std::io::Cursor::new(bytes), None).unwrap();
        let schema = r.schema();
        assert_eq!(schema.fields().iter().map(|f| f.name().as_str()).collect::<Vec<_>>(), ["time", "x", "b"]);
        assert_eq!(schema.field(1).metadata()["unit"], "m");
        assert_eq!(schema.metadata()[STOP_TIME_KEY], "1.0");
        let json = &schema.metadata()[VARIABLES_KEY];
        assert!(json.contains(r#"{"name":"mx","column":1,"scale":-1.0}"#), "{json}");
        assert!(json.contains(r#"{"name":"nb","column":2,"scale":-1.0,"offset":1.0}"#), "{json}");
        assert!(json.contains(r#"{"name":"p","value":-2.5}"#), "{json}");
        assert!(json.contains(r#"{"name":"u","value":7.0}"#), "{json}");
        let batches: Vec<RecordBatch> = r.map(|b| b.unwrap()).collect();
        assert_eq!(batches.iter().map(|b| b.num_rows()).sum::<usize>(), 3);
        // `b` is discrete: run-end encoded, [true, false, true] in three runs.
        let b = batches[0].column(2).as_any().downcast_ref::<RunArray<Int32Type>>().unwrap();
        assert_eq!(b.run_ends().values(), &[1, 2, 3]);
        let bv = b.values().as_any().downcast_ref::<BooleanArray>().unwrap();
        assert_eq!((0..3).map(|i| bv.value(i)).collect::<Vec<_>>(), [true, false, true]);
    }

    /// A time-invariant value is written in the JSON type its own type calls for.
    #[test]
    fn parameter_values_are_typed_json() {
        let param = |name, ty, affine| ArrowVar {
            name,
            comment: "",
            unit: "",
            display_unit: "",
            relative_quantity: false,
            ty,
            discrete: false,
            kind: ArrowKind::Param { affine },
            unvarying: false,
            enumeration: None,
        };
        let vars = [
            ArrowVar { name: "time", comment: "", unit: "s", display_unit: "", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Time, unvarying: false, enumeration: None },
            param("b", VarTy::Boolean, Affine::IDENTITY),
            param("nb", VarTy::Boolean, Affine::NOT),
            param("n", VarTy::Integer, Affine::NEGATE),
            param("x", VarTy::Real, Affine::IDENTITY),
        ];
        let bytes = write_arrow(&vars, &[0.0, 1.0], 1, &[1.0, 1.0, 3.0, 2.5], &[ColTy::F64], no_strings(), &FileMeta::default());
        let schema = FileReader::try_new(std::io::Cursor::new(bytes), None).unwrap().schema();
        let json = &schema.metadata()[VARIABLES_KEY];
        assert!(json.contains(r#"{"name":"b","value":true,"type":"Boolean"}"#), "{json}");
        assert!(json.contains(r#"{"name":"nb","value":false,"type":"Boolean"}"#), "{json}");
        assert!(json.contains(r#"{"name":"n","value":-3,"type":"Int32"}"#), "{json}");
        assert!(json.contains(r#"{"name":"x","value":2.5}"#), "{json}");
    }

    /// The first variable to reach a column decides how it is stored; the others
    /// are expressed relative to it.
    #[test]
    fn alias_relative_to_a_negated_owner() {
        let vars = [
            ArrowVar { name: "time", comment: "", unit: "s", display_unit: "", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Time, unvarying: false, enumeration: None },
            ArrowVar { name: "mx", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Column { col: 1, affine: Affine::NEGATE }, unvarying: false, enumeration: None },
            ArrowVar { name: "x", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Column { col: 1, affine: Affine::IDENTITY }, unvarying: false, enumeration: None },
            ArrowVar { name: "y", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Column { col: 1, affine: Affine { scale: 2.0, offset: 3.0 } }, unvarying: false, enumeration: None },
        ];
        let rows = [0.0, 1.0, 0.5, 2.0];
        let bytes = write_arrow(&vars, &rows, 2, &[], &[ColTy::F32, ColTy::F32], no_strings(), &FileMeta::default());
        let r = FileReader::try_new(std::io::Cursor::new(bytes), None).unwrap();
        let schema = r.schema();
        let json = &schema.metadata()[VARIABLES_KEY];
        assert!(json.contains(r#"{"name":"mx","column":1}"#), "{json}");
        assert!(json.contains(r#"{"name":"x","column":1,"scale":-1.0}"#), "{json}");
        assert!(json.contains(r#"{"name":"y","column":1,"scale":-2.0,"offset":3.0}"#), "{json}");
        let b = r.map(|b| b.unwrap()).next().unwrap();
        let mx = b.column(1).as_any().downcast_ref::<Float32Array>().unwrap();
        assert_eq!(mx.values(), &[-1.0f32, -2.0]);
    }

    #[test]
    fn strings_and_runs() {
        let table = ["off", "on"];
        let resolve: Resolve = Box::new(move |id| table[id as usize].to_owned());
        let vars = [
            ArrowVar { name: "time", comment: "", unit: "s", display_unit: "", relative_quantity: false, ty: VarTy::Real, discrete: false, kind: ArrowKind::Time, unvarying: false, enumeration: None },
            ArrowVar { name: "s", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::String, discrete: true, kind: ArrowKind::Column { col: 1, affine: Affine::IDENTITY }, unvarying: false, enumeration: None },
            ArrowVar { name: "n", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::Integer, discrete: true, kind: ArrowKind::Column { col: 2, affine: Affine::IDENTITY }, unvarying: false, enumeration: None },
            ArrowVar { name: "sp", comment: "", unit: "", display_unit: "", relative_quantity: false, ty: VarTy::String, discrete: false, kind: ArrowKind::Param { affine: Affine::IDENTITY }, unvarying: false, enumeration: None },
        ];
        // rows: time, s (id), n
        let rows = [0.0, 0.0, 1.0, 0.5, 0.0, 1.0, 1.0, 1.0, 2.0, 1.5, 1.0, 2.0];
        let bytes = write_arrow(&vars, &rows, 3, &[1.0], &[ColTy::F64, ColTy::Str, ColTy::I32], resolve, &FileMeta::default());
        let r = FileReader::try_new(std::io::Cursor::new(bytes), None).unwrap();
        let schema = r.schema();
        assert!(matches!(schema.field(1).data_type(), DataType::RunEndEncoded(_, v) if *v.data_type() == DataType::Utf8));
        assert!(schema.metadata()[VARIABLES_KEY].contains(r#"{"name":"sp","value":"on","type":"Utf8"}"#));
        let b = r.map(|b| b.unwrap()).next().unwrap();
        let s = b.column(1).as_any().downcast_ref::<RunArray<Int32Type>>().unwrap();
        assert_eq!(s.run_ends().values(), &[2, 4]);
        let sv = s.values().as_any().downcast_ref::<StringArray>().unwrap();
        assert_eq!((0..2).map(|i| sv.value(i)).collect::<Vec<_>>(), ["off", "on"]);
        let n = b.column(2).as_any().downcast_ref::<RunArray<Int32Type>>().unwrap();
        assert_eq!(n.run_ends().values(), &[2, 4]);
    }
}
