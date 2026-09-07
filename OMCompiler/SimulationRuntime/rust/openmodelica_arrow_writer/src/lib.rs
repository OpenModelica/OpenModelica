//! `arrow.modelica` result files (`.arrow`): a sequence of Arrow IPC streams —
//! the variable table, the units, the parameters as one dense union column, the
//! trajectories, the batch index — and a 16-byte trailer. `SPECIFICATION.md`
//! beside this crate is the format.
//!
//! Writes bytes into a caller-owned [`Out`] and does no I/O of its own. The
//! data stream is written one record batch per block of rows, and the schema
//! is decided up front from the variable list: one field per *stored*
//! time-variant signal, `time` first, in the Arrow type of the variable's own
//! (`Float64`/`Float32`, `Int32`, `Boolean`, `Utf8`, or
//! `Dictionary<Int32, Utf8>` for an enumeration), run-end encoded when the
//! signal is discrete-time. Aliases share their column through the variable
//! table's `scale` and `offset`; time-invariant values go to the parameter
//! table, each in its own type.

use std::collections::HashMap;
use std::sync::Arc;

use arrow_array::types::Int32Type;
use arrow_array::{Array, ArrayRef, BooleanArray, DictionaryArray, Float32Array, Float64Array, Int8Array, Int32Array, Int64Array, RecordBatch, RunArray, StringArray, UnionArray};
use arrow_buffer::ScalarBuffer;
use arrow_ipc::writer::{DictionaryTracker, IpcDataGenerator, IpcWriteContext, IpcWriteOptions, write_message};
use arrow_schema::{ArrowError, DataType, Field, Schema, SchemaRef, UnionFields, UnionMode};

pub mod units;
#[cfg(feature = "json-layout")]
pub mod json;

pub use units::{BaseUnit, DisplayUnit, UnitDef};

/// Turns an interned String id (what a String column or parameter holds in the
/// result rows) back into its text. `Send`, so a writer holding one can be
/// handed to a thread of its own.
pub type Resolve = Box<dyn Fn(u32) -> String + Send>;

/// Schema metadata key naming a stream's table.
pub const TABLE_KEY: &str = "modelica.table";
/// Schema metadata key holding the layout version, on the variable table.
pub const FORMAT_KEY: &str = "modelica.format";
/// Schema metadata keys holding the run's start and stop time, on the variable
/// table; absent when the writer had no run.
pub const START_TIME_KEY: &str = "modelica.startTime";
pub const STOP_TIME_KEY: &str = "modelica.stopTime";
pub const FORMAT_VERSION: &str = "0.1";
/// The last 8 bytes of a finished file; the 8 before them are the byte offset
/// of the index stream.
pub const TRAILER_MAGIC: &[u8; 8] = b"MODELICA";

/// Rows per record batch when streaming.
pub const DEFAULT_BLOCK_ROWS: usize = 1024;

/// Rows per record batch: the default, or the `-mat_sync` interval when it is
/// smaller (each complete batch is readable in a file still being written).
pub fn block_rows(sync: usize) -> usize {
    if sync > 0 { sync.min(DEFAULT_BLOCK_ROWS) } else { DEFAULT_BLOCK_ROWS }
}

/// How an alias derives its value from the column it shares: `scale * v + offset`.
#[derive(Clone, Copy, PartialEq, Debug)]
pub struct Affine {
    pub scale: f64,
    pub offset: f64,
}

impl Affine {
    pub const IDENTITY: Affine = Affine { scale: 1.0, offset: 0.0 };
    /// `-v`
    pub const NEGATE: Affine = Affine { scale: -1.0, offset: 0.0 };
    /// `!v` over the 0/1 encoding.
    pub const NOT: Affine = Affine { scale: -1.0, offset: 1.0 };

    pub fn apply(self, v: f64) -> f64 {
        self.scale * v + self.offset
    }

    pub fn is_identity(self) -> bool {
        self == Affine::IDENTITY
    }

    /// `self` applied after the inverse of `base`: the map from a column stored
    /// as `base(v)` to `self(v)`.
    fn relative_to(self, base: Affine) -> Affine {
        let scale = self.scale / base.scale;
        Affine { scale, offset: self.offset - scale * base.offset }
    }
}

impl Default for Affine {
    fn default() -> Affine {
        Affine::IDENTITY
    }
}

/// The Modelica type of a result variable.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum VarTy {
    #[default]
    Real,
    Integer,
    Boolean,
    String,
}

impl VarTy {
    pub fn code(self) -> u8 {
        match self {
            VarTy::Real => 0,
            VarTy::Integer => 1,
            VarTy::Boolean => 2,
            VarTy::String => 3,
        }
    }
    pub fn from_code(c: u8) -> VarTy {
        match c {
            1 => VarTy::Integer,
            2 => VarTy::Boolean,
            3 => VarTy::String,
            _ => VarTy::Real,
        }
    }
    pub fn name(self) -> &'static str {
        match self {
            VarTy::Real => "Real",
            VarTy::Integer => "Integer",
            VarTy::Boolean => "Boolean",
            VarTy::String => "String",
        }
    }
    pub fn from_name(s: &str) -> VarTy {
        match s {
            "Integer" => VarTy::Integer,
            "Boolean" => VarTy::Boolean,
            "String" => VarTy::String,
            "enumeration" => VarTy::Integer,
            _ => VarTy::Real,
        }
    }
}

/// How a result signal sources its value. Mirrors `MatKind`.
#[derive(Clone, Copy, Debug)]
pub enum ArrowKind {
    Time,
    /// Result-row column `col` (0 = time), transformed by `affine` for an alias.
    Column { col: u32, affine: Affine },
    /// A time-invariant value taken from the `params` slice, in `Param` order.
    Param { affine: Affine },
    Const { value: f64 },
}

/// The storage type of a result-row column.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum ColTy {
    F64,
    /// A Real under `-single`.
    F32,
    I32,
    Bool,
    /// An interned String id (see [`Resolve`]).
    Str,
}

impl ColTy {
    pub(crate) fn data_type(self) -> DataType {
        match self {
            ColTy::F64 => DataType::Float64,
            ColTy::F32 => DataType::Float32,
            ColTy::I32 => DataType::Int32,
            ColTy::Bool => DataType::Boolean,
            ColTy::Str => DataType::Utf8,
        }
    }
}

/// The type of a run-end encoded column, as `RunArray::try_new` builds it.
pub(crate) fn ree_type(values: DataType) -> DataType {
    DataType::RunEndEncoded(
        Arc::new(Field::new("run_ends", DataType::Int32, false)),
        Arc::new(Field::new("values", values, true)),
    )
}

fn dictionary_type() -> DataType {
    DataType::Dictionary(Box::new(DataType::Int32), Box::new(DataType::Utf8))
}

/// One result variable, borrowing the caller's strings.
pub struct ArrowVar<'a> {
    pub name: &'a str,
    pub comment: &'a str,
    pub unit: &'a str,
    pub display_unit: &'a str,
    /// FMI's `relativeQuantity`: a difference in the unit, so a conversion to the
    /// base unit or a display unit scales it but adds no offset.
    pub relative_quantity: bool,
    pub ty: VarTy,
    pub discrete: bool,
    pub kind: ArrowKind,
    /// C's `time_unvarying`: a `Column` computed once at initialization, stored as
    /// a time-invariant value.
    pub unvarying: bool,
    /// The literals of an enumeration variable (typed `Integer`; value `k` is
    /// `literals[k - 1]`), which become the dictionary of its column.
    pub enumeration: Option<&'a [String]>,
}

/// Where the file's bytes go.
pub trait Out {
    fn write(&mut self, bytes: &[u8]);
    /// Push buffered bytes to the file (after a block under `-mat_sync`).
    fn flush(&mut self) {}
}

impl Out for Vec<u8> {
    fn write(&mut self, bytes: &[u8]) {
        self.extend_from_slice(bytes);
    }
}

/// What the file says about itself rather than about one variable.
#[derive(Default)]
pub struct FileMeta<'a> {
    /// The run's start and stop time; `None` falls back to the ends of the time
    /// column.
    pub span: Option<(f64, f64)>,
    /// The units the variables name, minus the ones every reader of
    /// [`FORMAT_VERSION`] knows (see [`UnitDef::is_predefined`]).
    pub units: &'a [UnitDef],
    /// ZSTD level for every record batch. Needs the `zstd` feature; without it
    /// the file is written uncompressed.
    pub zstd: Option<i32>,
}

/// A stored column: which result-row column feeds it and how.
struct Stored {
    src: usize,
    ty: ColTy,
    affine: Affine,
    /// Run-end encoded (a discrete-time signal).
    ree: bool,
    /// An enumeration's literals, the dictionary of the column.
    literals: Option<Arc<StringArray>>,
}

/// Only a stored signal is discrete-time; a parameter's variability is not.
/// A String changes only at events, whatever the model says.
fn is_discrete(v: &ArrowVar) -> bool {
    (v.discrete || v.ty == VarTy::String) && matches!(v.kind, ArrowKind::Column { .. }) && !v.unvarying
}

/// The distinct enumeration types of a file: Modelica types an enumeration by
/// its literals alone, so equal lists are one type and share one dictionary.
#[derive(Default)]
struct Enumerations(Vec<Arc<StringArray>>);

impl Enumerations {
    fn index(&mut self, literals: &[String]) -> usize {
        let same = |a: &StringArray| a.len() == literals.len() && a.iter().zip(literals).all(|(x, y)| x == Some(y.as_str()));
        match self.0.iter().position(|l| same(l)) {
            Some(i) => i,
            None => {
                self.0.push(Arc::new(StringArray::from_iter_values(literals)));
                self.0.len() - 1
            }
        }
    }
}

/// A parameter's value, in its own type.
enum Value {
    Real(f64),
    Int(i32),
    Bool(bool),
    Str(String),
    /// `(enumeration type, key)`, the key being the Modelica value minus one.
    Enum(usize, i32),
}

fn table_schema(fields: Vec<Field>, table: &str) -> SchemaRef {
    Arc::new(Schema::new_with_metadata(fields, HashMap::from([(TABLE_KEY.to_owned(), table.to_owned())])))
}

/// Everything decided before the first row.
struct Plan {
    schema: SchemaRef,
    stored: Vec<Stored>,
    variables: RecordBatch,
    parameters: Option<RecordBatch>,
    units: Option<RecordBatch>,
    display_units: Option<RecordBatch>,
}

fn plan(vars: &[ArrowVar], params: &[f64], first_row: &[f64], col_types: &[ColTy], resolve: &dyn Fn(u32) -> String, file: &FileMeta) -> Plan {
    let mut fields: Vec<Field> = vec![Field::new("", DataType::Float64, false)];
    let mut stored: Vec<Stored> = Vec::new();
    // Result-row column -> (field index, how the field derives from the row).
    let mut owner: HashMap<u32, (usize, Affine)> = HashMap::from([(0, (0, Affine::IDENTITY))]);
    let mut enumerations = Enumerations::default();
    let mut values: Vec<Value> = Vec::new();
    let mut param_ix = 0usize;
    let col_ty = |col: u32| col_types.get(col as usize).copied().unwrap_or(ColTy::F64);

    let n = vars.len();
    let mut name = Vec::with_capacity(n);
    let mut description = Vec::with_capacity(n);
    let mut unit = Vec::with_capacity(n);
    let mut display_unit = Vec::with_capacity(n);
    let mut parameter = Vec::with_capacity(n);
    let mut column = Vec::with_capacity(n);
    let mut scale = Vec::with_capacity(n);
    let mut offset = Vec::with_capacity(n);
    let mut relative = Vec::with_capacity(n);

    for v in vars {
        let value = |raw: f64, enumerations: &mut Enumerations| match (v.ty, v.enumeration) {
            (VarTy::String, _) => Value::Str(resolve(raw as u32)),
            (VarTy::Boolean, _) => Value::Bool(raw != 0.0),
            (VarTy::Integer, Some(e)) => Value::Enum(enumerations.index(e), (raw as i32 - 1).max(0)),
            (VarTy::Integer, None) => Value::Int(raw as i32),
            (VarTy::Real, _) => Value::Real(raw),
        };
        let param = |val: Value, values: &mut Vec<Value>| -> (bool, usize, Affine) {
            values.push(val);
            (true, values.len() - 1, Affine::IDENTITY)
        };
        let (is_param, index, affine) = match v.kind {
            ArrowKind::Time => (false, 0, Affine::IDENTITY),
            ArrowKind::Param { affine } => {
                let p = params.get(param_ix).copied().unwrap_or(0.0);
                param_ix += 1;
                param(value(affine.apply(p), &mut enumerations), &mut values)
            }
            ArrowKind::Const { value: c } => param(value(c, &mut enumerations), &mut values),
            ArrowKind::Column { col, affine } if v.unvarying => {
                let raw = first_row.get(col as usize).copied().unwrap_or(0.0);
                param(value(affine.apply(raw), &mut enumerations), &mut values)
            }
            ArrowKind::Column { col, affine } => match owner.get(&col) {
                Some(&(f, base)) => (false, f, affine.relative_to(base)),
                None => {
                    let ty = col_ty(col);
                    let literals = match (ty, v.enumeration) {
                        (ColTy::I32, Some(e)) => {
                            let ix = enumerations.index(e);
                            Some(enumerations.0[ix].clone())
                        }
                        _ => None,
                    };
                    let ree = is_discrete(v) || ty == ColTy::Str;
                    let base = if literals.is_some() { dictionary_type() } else { ty.data_type() };
                    fields.push(Field::new("", if ree { ree_type(base) } else { base }, false));
                    stored.push(Stored { src: col as usize, ty, affine, ree, literals });
                    let f = fields.len() - 1;
                    owner.insert(col, (f, affine));
                    (false, f, Affine::IDENTITY)
                }
            },
        };
        name.push(v.name);
        description.push(v.comment);
        unit.push(v.unit);
        display_unit.push(v.display_unit);
        parameter.push(is_param);
        column.push(index as i32);
        scale.push(affine.scale);
        offset.push(affine.offset);
        relative.push(v.relative_quantity);
    }

    let mut metadata = HashMap::from([(TABLE_KEY.to_owned(), "variables".to_owned()), (FORMAT_KEY.to_owned(), FORMAT_VERSION.to_owned())]);
    if let Some((start, stop)) = file.span {
        metadata.insert(START_TIME_KEY.to_owned(), format!("{start:?}"));
        metadata.insert(STOP_TIME_KEY.to_owned(), format!("{stop:?}"));
    }
    let variables_schema = Arc::new(Schema::new_with_metadata(
        vec![
            Field::new("name", DataType::Utf8, false),
            Field::new("description", DataType::Utf8, false),
            Field::new("unit", DataType::Utf8, false),
            Field::new("displayUnit", DataType::Utf8, false),
            Field::new("parameter", DataType::Boolean, false),
            Field::new("column", DataType::Int32, false),
            Field::new("scale", DataType::Float64, false),
            Field::new("offset", DataType::Float64, false),
            Field::new("relativeQuantity", DataType::Boolean, false),
        ],
        metadata,
    ));
    let variables = RecordBatch::try_new(
        variables_schema,
        vec![
            Arc::new(StringArray::from(name)),
            Arc::new(StringArray::from(description)),
            Arc::new(StringArray::from(unit)),
            Arc::new(StringArray::from(display_unit)),
            Arc::new(BooleanArray::from(parameter)),
            Arc::new(Int32Array::from(column)),
            Arc::new(Float64Array::from(scale)),
            Arc::new(Float64Array::from(offset)),
            Arc::new(BooleanArray::from(relative)),
        ],
    )
    .expect("arrow variable table");

    let (units, display_units) = units_tables(file.units);
    Plan { schema: table_schema(fields, "data"), stored, variables, parameters: parameters_table(&values, &enumerations), units, display_units }
}

/// The parameter table: one dense union column with a child per value type in
/// use, so a row is a type id and an offset into the child of that type.
fn parameters_table(values: &[Value], enumerations: &Enumerations) -> Option<RecordBatch> {
    if values.is_empty() {
        return None;
    }
    let (mut reals, mut ints, mut bools, mut strs) = (Vec::new(), Vec::new(), Vec::new(), Vec::new());
    let mut enums: Vec<Vec<i32>> = vec![Vec::new(); enumerations.0.len()];
    // (child, offset) per row, children numbered as below.
    let n_basic = 4;
    let mut rows: Vec<(usize, i32)> = Vec::with_capacity(values.len());
    for v in values {
        let (child, len) = match v {
            Value::Real(x) => {
                reals.push(*x);
                (0, reals.len())
            }
            Value::Int(x) => {
                ints.push(*x);
                (1, ints.len())
            }
            Value::Bool(x) => {
                bools.push(*x);
                (2, bools.len())
            }
            Value::Str(x) => {
                strs.push(x.as_str());
                (3, strs.len())
            }
            Value::Enum(e, k) => {
                enums[*e].push(*k);
                (n_basic + e, enums[*e].len())
            }
        };
        rows.push((child, len as i32 - 1));
    }
    let mut children: Vec<(usize, Field, ArrayRef)> = Vec::new();
    if !reals.is_empty() {
        children.push((0, Field::new("Float64", DataType::Float64, false), Arc::new(Float64Array::from(reals))));
    }
    if !ints.is_empty() {
        children.push((1, Field::new("Int32", DataType::Int32, false), Arc::new(Int32Array::from(ints))));
    }
    if !bools.is_empty() {
        children.push((2, Field::new("Boolean", DataType::Boolean, false), Arc::new(BooleanArray::from(bools))));
    }
    if !strs.is_empty() {
        children.push((3, Field::new("Utf8", DataType::Utf8, false), Arc::new(StringArray::from(strs))));
    }
    for (e, keys) in enums.into_iter().enumerate() {
        if !keys.is_empty() {
            let dict = DictionaryArray::<Int32Type>::try_new(Int32Array::from(keys), enumerations.0[e].clone()).expect("arrow enumeration");
            children.push((n_basic + e, Field::new("enumeration", dictionary_type(), false), Arc::new(dict)));
        }
    }
    // Type ids count the children present, in order.
    let type_of: HashMap<usize, i8> = children.iter().enumerate().map(|(i, c)| (c.0, i as i8)).collect();
    let type_ids: Vec<i8> = rows.iter().map(|(c, _)| type_of[c]).collect();
    let offsets: Vec<i32> = rows.iter().map(|(_, o)| *o).collect();
    let fields = UnionFields::try_new((0..children.len() as i8).collect::<Vec<_>>(), children.iter().map(|c| c.1.clone()).collect::<Vec<_>>()).expect("arrow union fields");
    let union = UnionArray::try_new(fields.clone(), ScalarBuffer::from(type_ids), Some(ScalarBuffer::from(offsets)), children.into_iter().map(|c| c.2).collect()).expect("arrow union");
    let schema = table_schema(vec![Field::new("value", DataType::Union(fields, UnionMode::Dense), false)], "parameters");
    Some(RecordBatch::try_new(schema, vec![Arc::new(union)]).expect("arrow parameter table"))
}

/// `modelica.units` and `modelica.displayUnits` for the units a file spells
/// out: a unit row where the unit is not the predefined one of its name, and a
/// display-unit row for every display unit the predefined set lacks.
fn units_tables(defs: &[UnitDef]) -> (Option<RecordBatch>, Option<RecordBatch>) {
    let mut name = Vec::new();
    let mut has_base = Vec::new();
    let mut exponents: Vec<Vec<i8>> = vec![Vec::new(); units::BASE_EXPONENTS.len()];
    let (mut factor, mut offset) = (Vec::new(), Vec::new());
    let (mut d_unit, mut d_name, mut d_factor, mut d_offset, mut d_inverse) = (Vec::new(), Vec::new(), Vec::new(), Vec::new(), Vec::new());
    for u in defs {
        let predefined = u.same_base_as_predefined();
        if predefined.is_none() {
            name.push(u.name.as_str());
            has_base.push(u.base.is_some());
            let base = u.base.clone().unwrap_or_default();
            for (e, out) in exponents.iter_mut().enumerate() {
                out.push(base.exponents[e] as i8);
            }
            factor.push(base.factor);
            offset.push(base.offset);
        }
        for d in &u.display_units {
            if predefined.as_ref().is_some_and(|p| p.display_unit(&d.name) == Some(d)) {
                continue;
            }
            d_unit.push(u.name.as_str());
            d_name.push(d.name.as_str());
            d_factor.push(d.factor);
            d_offset.push(d.offset);
            d_inverse.push(d.inverse);
        }
    }
    let units = (!name.is_empty()).then(|| {
        let mut fields = vec![Field::new("name", DataType::Utf8, false), Field::new("baseUnit", DataType::Boolean, false)];
        let mut cols: Vec<ArrayRef> = vec![Arc::new(StringArray::from(name)), Arc::new(BooleanArray::from(has_base))];
        for (e, values) in units::BASE_EXPONENTS.iter().zip(exponents) {
            fields.push(Field::new(*e, DataType::Int8, false));
            cols.push(Arc::new(Int8Array::from(values)));
        }
        fields.push(Field::new("factor", DataType::Float64, false));
        fields.push(Field::new("offset", DataType::Float64, false));
        cols.push(Arc::new(Float64Array::from(factor)));
        cols.push(Arc::new(Float64Array::from(offset)));
        RecordBatch::try_new(table_schema(fields, "units"), cols).expect("arrow unit table")
    });
    let display_units = (!d_name.is_empty()).then(|| {
        let fields = vec![
            Field::new("unit", DataType::Utf8, false),
            Field::new("name", DataType::Utf8, false),
            Field::new("factor", DataType::Float64, false),
            Field::new("offset", DataType::Float64, false),
            Field::new("inverse", DataType::Boolean, false),
        ];
        let cols: Vec<ArrayRef> = vec![
            Arc::new(StringArray::from(d_unit)),
            Arc::new(StringArray::from(d_name)),
            Arc::new(Float64Array::from(d_factor)),
            Arc::new(Float64Array::from(d_offset)),
            Arc::new(BooleanArray::from(d_inverse)),
        ];
        RecordBatch::try_new(table_schema(fields, "displayUnits"), cols).expect("arrow display unit table")
    });
    (units, display_units)
}

/// IPC messages into a buffer that is drained to the [`Out`] as they complete,
/// counting the bytes so a record batch's offset in the file is known.
struct Ipc {
    generator: IpcDataGenerator,
    options: IpcWriteOptions,
    context: IpcWriteContext,
    buf: Vec<u8>,
    written: u64,
}

impl Ipc {
    fn new(zstd: Option<i32>) -> Ipc {
        let mut options = IpcWriteOptions::default();
        if let Some(level) = zstd.filter(|_| cfg!(feature = "zstd")) {
            options = options
                .try_with_compression(Some(arrow_ipc::CompressionType::ZSTD))
                .and_then(|o| o.try_with_compression_level(Some(level)))
                .expect("arrow zstd");
        }
        Ipc { generator: IpcDataGenerator::default(), options, context: IpcWriteContext::default(), buf: Vec::with_capacity(1 << 16), written: 0 }
    }

    fn schema(&mut self, schema: &Schema, tracker: &mut DictionaryTracker) -> Result<(), ArrowError> {
        let encoded = self.generator.schema_to_bytes_with_dictionary_tracker(schema, tracker, &self.options);
        write_message(&mut self.buf, encoded, &self.options)?;
        Ok(())
    }

    /// Writes the batch (its dictionaries first) and returns the file offset of
    /// the record batch message.
    fn batch(&mut self, batch: &RecordBatch, tracker: &mut DictionaryTracker) -> Result<u64, ArrowError> {
        let (dictionaries, data) = self.generator.encode(batch, tracker, &self.options, &mut self.context)?;
        for d in dictionaries {
            write_message(&mut self.buf, d, &self.options)?;
        }
        let at = self.written + self.buf.len() as u64;
        write_message(&mut self.buf, data, &self.options)?;
        Ok(at)
    }

    fn end_of_stream(&mut self) {
        self.buf.extend_from_slice(&[0xff, 0xff, 0xff, 0xff, 0, 0, 0, 0]);
    }

    /// A whole stream for a table known in advance.
    fn table(&mut self, batch: &RecordBatch) -> Result<(), ArrowError> {
        let mut tracker = DictionaryTracker::new(false);
        self.schema(batch.schema_ref(), &mut tracker)?;
        self.batch(batch, &mut tracker)?;
        self.end_of_stream();
        Ok(())
    }

    fn drain(&mut self, out: &mut dyn Out) {
        if !self.buf.is_empty() {
            out.write(&self.buf);
            self.written += self.buf.len() as u64;
            self.buf.clear();
        }
    }
}

/// The file written incrementally: the tables up front, one record batch of
/// the data stream per `block_rows` rows, the index and the trailer at
/// [`ArrowStream::finish`].
pub struct ArrowStream {
    schema: SchemaRef,
    stored: Vec<Stored>,
    resolve: Resolve,
    ipc: Ipc,
    tracker: DictionaryTracker,
    /// File offset of every record batch of the data stream.
    batches: Vec<i64>,
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
        let plan = plan(vars, params, first_row, col_types, &*resolve, file);
        let mut ipc = Ipc::new(file.zstd);
        for table in [Some(&plan.variables), plan.units.as_ref(), plan.display_units.as_ref(), plan.parameters.as_ref()].into_iter().flatten() {
            ipc.table(table).expect("arrow table");
        }
        let mut tracker = DictionaryTracker::new(false);
        ipc.schema(&plan.schema, &mut tracker).expect("arrow schema");
        ipc.drain(out);
        ArrowStream {
            schema: plan.schema,
            stored: plan.stored,
            resolve,
            ipc,
            tracker,
            batches: Vec::new(),
            n_reals: n_reals.max(1) as usize,
            block_rows: block_rows.max(1),
            pending: Vec::new(),
            n_rows: 0,
            finished: false,
            sync: false,
        }
    }

    /// Flush the sink after every block, so a reader can open the file while it
    /// is written (the `-mat_sync` analogue; pair it with a small `block_rows`).
    pub fn set_sync(&mut self, on: bool) {
        self.sync = on;
    }

    /// The values of one stored column over the block, as an Arrow array: every
    /// row for a continuous signal, one per run (with the run ends) for a
    /// discrete one.
    fn column(&self, s: &Stored, rows: &[f64], n: usize) -> ArrayRef {
        let at = |r: usize| s.affine.apply(rows[r * self.n_reals + s.src]);
        let array = |v: Vec<f64>| -> ArrayRef {
            if let Some(literals) = &s.literals {
                let keys = Int32Array::from_iter_values(v.into_iter().map(|x| (x as i32 - 1).max(0)));
                return Arc::new(DictionaryArray::<Int32Type>::try_new(keys, literals.clone()).expect("arrow enumeration"));
            }
            match s.ty {
                ColTy::F64 => Arc::new(Float64Array::from(v)),
                ColTy::F32 => Arc::new(Float32Array::from_iter_values(v.into_iter().map(|x| x as f32))),
                ColTy::I32 => Arc::new(Int32Array::from_iter_values(v.into_iter().map(|x| x as i32))),
                ColTy::Bool => Arc::new(BooleanArray::from_iter(v.into_iter().map(|x| Some(x != 0.0)))),
                ColTy::Str => Arc::new(StringArray::from_iter_values(v.into_iter().map(|x| (self.resolve)(x as u32)))),
            }
        };
        if !s.ree {
            return array((0..n).map(at).collect());
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
        let values = array(run_values);
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
        let at = self.ipc.batch(&batch, &mut self.tracker).expect("arrow write");
        self.batches.push(at as i64);
        self.ipc.drain(out);
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

    /// Write the last block, the index and the trailer. A second call does nothing.
    pub fn finish(&mut self, out: &mut dyn Out) {
        if self.finished {
            return;
        }
        self.finished = true;
        let n = self.pending.len() / self.n_reals;
        if n > 0 {
            self.flush_block(out, n);
        }
        self.ipc.end_of_stream();
        self.ipc.drain(out);
        let index_at = self.ipc.written;
        let index = RecordBatch::try_new(table_schema(vec![Field::new("offset", DataType::Int64, false)], "index"), vec![Arc::new(Int64Array::from(std::mem::take(&mut self.batches)))])
            .expect("arrow index");
        self.ipc.table(&index).expect("arrow index");
        self.ipc.buf.extend_from_slice(&(index_at as i64).to_le_bytes());
        self.ipc.buf.extend_from_slice(TRAILER_MAGIC);
        self.ipc.drain(out);
        out.flush();
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

/// The resolver for a file without String data.
pub fn no_strings() -> Resolve {
    Box::new(|_| String::new())
}

#[cfg(test)]
mod tests {
    use super::*;
    use arrow_array::cast::AsArray;
    use arrow_array::Array;
    use arrow_ipc::reader::StreamReader;
    use std::io::Cursor;

    /// The streams of a file, by table name, up to the trailer.
    fn tables(bytes: &[u8]) -> HashMap<String, (SchemaRef, Vec<RecordBatch>)> {
        let mut out = HashMap::new();
        let mut cursor = Cursor::new(bytes);
        while (bytes.len() as u64 - cursor.position()) > 16 {
            let mut r = StreamReader::try_new(&mut cursor, None).expect("stream");
            let schema = r.schema();
            let batches: Vec<RecordBatch> = r.by_ref().map(|b| b.expect("batch")).collect();
            out.insert(schema.metadata()[TABLE_KEY].clone(), (schema, batches));
        }
        assert_eq!(&bytes[bytes.len() - 8..], TRAILER_MAGIC);
        out
    }

    fn var<'a>(name: &'a str, ty: VarTy, kind: ArrowKind) -> ArrowVar<'a> {
        ArrowVar { name, comment: "", unit: "", display_unit: "", relative_quantity: false, ty, discrete: false, kind, unvarying: false, enumeration: None }
    }

    fn time() -> ArrowVar<'static> {
        ArrowVar { unit: "s", ..var("time", VarTy::Real, ArrowKind::Time) }
    }

    fn column(col: u32, affine: Affine) -> ArrowKind {
        ArrowKind::Column { col, affine }
    }

    #[test]
    fn aliases_share_a_column_and_parameters_are_a_union() {
        let vars = [
            time(),
            ArrowVar { comment: "a state", unit: "m", display_unit: "mm", ..var("x", VarTy::Real, column(1, Affine::IDENTITY)) },
            var("mx", VarTy::Real, column(1, Affine::NEGATE)),
            ArrowVar { discrete: true, ..var("b", VarTy::Boolean, column(2, Affine::IDENTITY)) },
            ArrowVar { discrete: true, ..var("nb", VarTy::Boolean, column(2, Affine::NOT)) },
            var("p", VarTy::Real, ArrowKind::Param { affine: Affine::NEGATE }),
            var("bp", VarTy::Boolean, ArrowKind::Param { affine: Affine::IDENTITY }),
            ArrowVar { unvarying: true, ..var("u", VarTy::Real, column(3, Affine::IDENTITY)) },
        ];
        let rows = [0.0, 1.0, 1.0, 7.0, 0.5, 2.0, 0.0, 7.0, 1.0, 3.0, 1.0, 7.0];
        let bytes = write_arrow(&vars, &rows, 4, &[2.5, 1.0], &[ColTy::F64, ColTy::F64, ColTy::Bool, ColTy::F64], no_strings(), &FileMeta { span: Some((0.0, 1.0)), ..FileMeta::default() });
        let t = tables(&bytes);
        assert_eq!(t.len(), 4, "{:?}", t.keys());

        let (schema, v) = &t["variables"];
        assert_eq!(schema.metadata()[FORMAT_KEY], FORMAT_VERSION);
        assert_eq!(schema.metadata()[STOP_TIME_KEY], "1.0");
        let v = &v[0];
        assert_eq!(v.num_rows(), 8);
        assert!(schema.fields().iter().all(|f| !f.is_nullable()));
        let names: Vec<&str> = v.column_by_name("name").unwrap().as_string::<i32>().iter().flatten().collect();
        assert_eq!(names, ["time", "x", "mx", "b", "nb", "p", "bp", "u"]);
        let col = v.column_by_name("column").unwrap().as_primitive::<Int32Type>().values();
        assert_eq!(col, &[0, 1, 1, 2, 2, 0, 1, 2]);
        let param = v.column_by_name("parameter").unwrap().as_boolean();
        assert_eq!((0..8).map(|i| param.value(i)).collect::<Vec<_>>(), [false, false, false, false, false, true, true, true]);
        assert_eq!(v.column_by_name("scale").unwrap().as_primitive::<arrow_array::types::Float64Type>().values(), &[1.0, 1.0, -1.0, 1.0, -1.0, 1.0, 1.0, 1.0]);
        assert_eq!(v.column_by_name("offset").unwrap().as_primitive::<arrow_array::types::Float64Type>().values(), &[0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0]);
        assert_eq!(v.column_by_name("displayUnit").unwrap().as_string::<i32>().value(1), "mm");

        let (_, p) = &t["parameters"];
        let u = p[0].column(0).as_any().downcast_ref::<UnionArray>().unwrap();
        assert_eq!(u.len(), 3);
        // p = -2.5 and u = 7.0 in the Float64 child, bp in the Boolean one.
        assert_eq!(u.type_id(0), u.type_id(2));
        assert_ne!(u.type_id(0), u.type_id(1));
        let reals = u.child(u.type_id(0)).as_primitive::<arrow_array::types::Float64Type>();
        assert_eq!(reals.value(u.value_offset(0)), -2.5);
        assert_eq!(reals.value(u.value_offset(2)), 7.0);
        assert!(u.child(u.type_id(1)).as_boolean().value(u.value_offset(1)));

        let (schema, d) = &t["data"];
        assert_eq!(schema.fields().len(), 3);
        assert!(schema.fields().iter().all(|f| f.name().is_empty()));
        assert_eq!(d.iter().map(|b| b.num_rows()).sum::<usize>(), 3);
        // `b` is discrete: run-end encoded, [true, false, true] in three runs.
        let b = d[0].column(2).as_any().downcast_ref::<RunArray<Int32Type>>().unwrap();
        assert_eq!(b.run_ends().values(), &[1, 2, 3]);
        assert_eq!((0..3).map(|i| b.values().as_boolean().value(i)).collect::<Vec<_>>(), [true, false, true]);

        let (_, ix) = &t["index"];
        let offsets = ix[0].column(0).as_primitive::<arrow_array::types::Int64Type>().values();
        assert_eq!(offsets.len(), 1);
        // The trailer points at the index stream, and the index at a record batch message.
        let index_at = i64::from_le_bytes(bytes[bytes.len() - 16..bytes.len() - 8].try_into().unwrap()) as usize;
        assert_eq!(&bytes[index_at..index_at + 4], &[0xff; 4]);
        let at = offsets[0] as usize;
        assert_eq!(&bytes[at..at + 4], &[0xff; 4]);
        let len = i32::from_le_bytes(bytes[at + 4..at + 8].try_into().unwrap()) as usize;
        let message = arrow_ipc::root_as_message(&bytes[at + 8..at + 8 + len]).unwrap();
        assert_eq!(message.header_type(), arrow_ipc::MessageHeader::RecordBatch);
    }

    #[test]
    fn enumerations_are_dictionaries_with_one_child_per_type() {
        let e: Vec<String> = ["one", "two", "three"].map(String::from).to_vec();
        let f: Vec<String> = ["on", "off"].map(String::from).to_vec();
        let vars = [
            time(),
            ArrowVar { discrete: true, enumeration: Some(&e), ..var("e", VarTy::Integer, column(1, Affine::IDENTITY)) },
            ArrowVar { enumeration: Some(&e), ..var("ep", VarTy::Integer, ArrowKind::Param { affine: Affine::IDENTITY }) },
            ArrowVar { enumeration: Some(&f), ..var("fp", VarTy::Integer, ArrowKind::Param { affine: Affine::IDENTITY }) },
            ArrowVar { enumeration: Some(&e), ..var("ep2", VarTy::Integer, ArrowKind::Param { affine: Affine::IDENTITY }) },
            var("n", VarTy::Integer, ArrowKind::Param { affine: Affine::IDENTITY }),
        ];
        let rows = [0.0, 1.0, 0.5, 1.0, 1.0, 3.0];
        let bytes = write_arrow(&vars, &rows, 2, &[2.0, 1.0, 3.0, 5.0], &[ColTy::F64, ColTy::I32], no_strings(), &FileMeta::default());
        let t = tables(&bytes);
        let (schema, d) = &t["data"];
        assert_eq!(*schema.field(1).data_type(), ree_type(dictionary_type()));
        let ree = d[0].column(1).as_any().downcast_ref::<RunArray<Int32Type>>().unwrap();
        let dict = ree.values().as_dictionary::<Int32Type>();
        assert_eq!(dict.keys().values(), &[0, 2]);
        assert_eq!(dict.values().as_string::<i32>().value(2), "three");

        let (_, p) = &t["parameters"];
        let u = p[0].column(0).as_any().downcast_ref::<UnionArray>().unwrap();
        let DataType::Union(fields, UnionMode::Dense) = p[0].schema().field(0).data_type().clone() else { panic!() };
        // Int32, then the two enumeration types: ep and ep2 share a child.
        assert_eq!(fields.len(), 3);
        assert_eq!(u.type_id(0), u.type_id(2));
        assert_ne!(u.type_id(0), u.type_id(1));
        let ed = u.child(u.type_id(0)).as_dictionary::<Int32Type>();
        assert_eq!(ed.keys().values(), &[1, 2]);
        assert_eq!(ed.values().as_string::<i32>().value(0), "one");
        let fd = u.child(u.type_id(1)).as_dictionary::<Int32Type>();
        assert_eq!(fd.values().as_string::<i32>().value(1), "off");
        assert_eq!(u.child(u.type_id(3)).as_primitive::<Int32Type>().value(u.value_offset(3)), 5);
    }

    /// The first variable to reach a column decides how it is stored; the others
    /// are expressed relative to it.
    #[test]
    fn alias_relative_to_a_negated_owner() {
        let vars = [
            time(),
            var("mx", VarTy::Real, column(1, Affine::NEGATE)),
            var("x", VarTy::Real, column(1, Affine::IDENTITY)),
            var("y", VarTy::Real, column(1, Affine { scale: 2.0, offset: 3.0 })),
        ];
        let rows = [0.0, 1.0, 0.5, 2.0];
        let bytes = write_arrow(&vars, &rows, 2, &[], &[ColTy::F32, ColTy::F32], no_strings(), &FileMeta::default());
        let t = tables(&bytes);
        assert!(!t.contains_key("parameters"));
        let (_, v) = &t["variables"];
        assert_eq!(v[0].column_by_name("scale").unwrap().as_primitive::<arrow_array::types::Float64Type>().values(), &[1.0, 1.0, -1.0, -2.0]);
        assert_eq!(v[0].column_by_name("offset").unwrap().as_primitive::<arrow_array::types::Float64Type>().values(), &[0.0, 0.0, 0.0, 3.0]);
        let (_, d) = &t["data"];
        assert_eq!(d[0].column(1).as_primitive::<arrow_array::types::Float32Type>().values(), &[-1.0f32, -2.0]);
    }

    #[test]
    fn strings_and_runs() {
        let table = ["off", "on"];
        let resolve: Resolve = Box::new(move |id| table[id as usize].to_owned());
        let vars = [
            time(),
            ArrowVar { discrete: true, ..var("s", VarTy::String, column(1, Affine::IDENTITY)) },
            ArrowVar { discrete: true, ..var("n", VarTy::Integer, column(2, Affine::IDENTITY)) },
            var("sp", VarTy::String, ArrowKind::Param { affine: Affine::IDENTITY }),
        ];
        // rows: time, s (id), n
        let rows = [0.0, 0.0, 1.0, 0.5, 0.0, 1.0, 1.0, 1.0, 2.0, 1.5, 1.0, 2.0];
        let bytes = write_arrow(&vars, &rows, 3, &[1.0], &[ColTy::F64, ColTy::Str, ColTy::I32], resolve, &FileMeta::default());
        let t = tables(&bytes);
        let (schema, d) = &t["data"];
        assert!(matches!(schema.field(1).data_type(), DataType::RunEndEncoded(_, v) if *v.data_type() == DataType::Utf8));
        let s = d[0].column(1).as_any().downcast_ref::<RunArray<Int32Type>>().unwrap();
        assert_eq!(s.run_ends().values(), &[2, 4]);
        assert_eq!((0..2).map(|i| s.values().as_string::<i32>().value(i)).collect::<Vec<_>>(), ["off", "on"]);
        let n = d[0].column(2).as_any().downcast_ref::<RunArray<Int32Type>>().unwrap();
        assert_eq!(n.run_ends().values(), &[2, 4]);
        let u = t["parameters"].1[0].column(0).as_any().downcast_ref::<UnionArray>().unwrap();
        assert_eq!(u.child(u.type_id(0)).as_string::<i32>().value(u.value_offset(0)), "on");
    }

    #[test]
    fn units_carry_only_what_is_not_predefined() {
        let mut k = UnitDef::new("K");
        k.base = Some(BaseUnit { exponents: [0, 0, 0, 0, 1, 0, 0, 0], ..BaseUnit::default() });
        k.display_units.push(DisplayUnit::new("degC", 1.0, -273.15));
        k.display_units.push(DisplayUnit::new("degF", 1.8, -459.67));
        let mut thing = UnitDef::new("thing");
        thing.display_units.push(DisplayUnit::new("kthing", 1e-3, 0.0));
        let (units, display) = units_tables(&[k, thing]);
        let units = units.unwrap();
        assert_eq!(units.num_rows(), 1, "K is the predefined kelvin; only thing needs a row");
        assert_eq!(units.column_by_name("name").unwrap().as_string::<i32>().value(0), "thing");
        assert!(!units.column_by_name("baseUnit").unwrap().as_boolean().value(0));
        let display = display.unwrap();
        let unit: Vec<&str> = display.column_by_name("unit").unwrap().as_string::<i32>().iter().flatten().collect();
        let name: Vec<&str> = display.column_by_name("name").unwrap().as_string::<i32>().iter().flatten().collect();
        assert_eq!(unit, ["K", "thing"]);
        assert_eq!(name, ["degF", "kthing"]);
    }

    /// Many blocks: every batch offset in the index leads to a record batch.
    #[test]
    fn the_index_names_every_batch() {
        let vars = [time(), var("x", VarTy::Real, column(1, Affine::IDENTITY))];
        let rows: Vec<f64> = (0..10).flat_map(|i| [i as f64, 10.0 * i as f64]).collect();
        let mut out = Vec::new();
        let mut s = ArrowStream::begin(&mut out, &vars, &[], &rows[..2], 2, &[ColTy::F64, ColTy::F64], 3, no_strings(), &FileMeta::default());
        s.push_rows(&mut out, &rows);
        s.finish(&mut out);
        let t = tables(&out);
        let offsets = t["index"].1[0].column(0).as_primitive::<arrow_array::types::Int64Type>().values().to_vec();
        assert_eq!(offsets.len(), 4);
        assert_eq!(t["data"].1.len(), 4);
        for at in offsets {
            let at = at as usize;
            let len = i32::from_le_bytes(out[at + 4..at + 8].try_into().unwrap()) as usize;
            let message = arrow_ipc::root_as_message(&out[at + 8..at + 8 + len]).unwrap();
            assert_eq!(message.header_type(), arrow_ipc::MessageHeader::RecordBatch);
        }
    }
}
