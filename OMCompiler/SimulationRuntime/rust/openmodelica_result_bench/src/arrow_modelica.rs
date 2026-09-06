//! `arrow.modelica`, written and read: several Arrow IPC streams in one file,
//! specified in `openmodelica_arrow_writer/SPECIFICATION.md`.
//!
//! Enumerations are the one thing missing. A variable typed `enumeration` is
//! stored as `Int32` and its literals are dropped, because nothing here has
//! them: the input is a `.mat` and an `_init.xml`, and OpenModelica writes an
//! enumeration variable there as a plain `<Integer>`. They belong in a
//! `modelica.enumerations` stream, and their columns want the shared dictionary
//! `crate::ipc` exists to write.

use std::fs::File;
use std::io::{BufReader, BufWriter, Read, Seek, SeekFrom, Write};
use std::collections::HashMap;
use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering};

use arrow_array::{
    Array, ArrayRef, BooleanArray, Float64Array, Int32Array, RecordBatch, StringArray,
};
use arrow_ipc::CompressionType;
use arrow_ipc::reader::StreamReader;
use arrow_ipc::writer::{IpcWriteOptions, StreamWriter};
use arrow_schema::{DataType, Field, Schema, SchemaRef};

use crate::dataset::{Dataset, Kind, VarTy};

/// Last 16 bytes: where `modelica.index` starts, and a mark saying the run
/// finished. A file without it can still be read forward.
const MAGIC: &[u8; 8] = b"MODELICA";

/// Which of the file's streams this is, in every stream's schema metadata.
const TABLE_KEY: &str = "modelica.table";
const FORMAT_KEY: &str = "modelica.format";
const START_TIME_KEY: &str = "modelica.startTime";
const STOP_TIME_KEY: &str = "modelica.stopTime";

/// Unchanged by the layout: an entry of the variable table still either names a
/// column or carries a value, which is all the version has ever described.
const FORMAT_VERSION: &str = "1";

/// Bytes written so far, which is the offset of whatever comes next. Shared
/// out of the sink because the IPC writers own it while a stream is open.
#[derive(Clone)]
struct At(Arc<AtomicU64>);

struct Counting<W: Write> {
    inner: W,
    at: At,
}

impl<W: Write> Write for Counting<W> {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        let n = self.inner.write(buf)?;
        self.at.0.fetch_add(n as u64, Ordering::Relaxed);
        Ok(n)
    }
    fn flush(&mut self) -> std::io::Result<()> {
        self.inner.flush()
    }
}

type Sink = Counting<BufWriter<File>>;

pub struct Stream {
    /// The data stream goes through this crate's own IPC writer, not arrow-rs's
    /// - see `crate::ipc` for why. The three metadata tables have nulls in
    /// them, which that writer does not carry, so they stay with arrow-rs.
    data: Option<crate::ipc::StreamWriter<Sink>>,
    at: At,
    opts: IpcWriteOptions,
    /// Column buffers for the batch being filled.
    cols: Vec<Col>,
    rows: usize,
    block_rows: usize,
    /// Where each batch of stream 2 begins.
    batches: Vec<u64>,
}

enum Col {
    F64(Vec<f64>),
    I32(Vec<i32>),
    Bool(Vec<bool>),
}

impl Col {
    fn of(ty: crate::ipc::Ty, block_rows: usize) -> Col {
        match ty {
            crate::ipc::Ty::I32 | crate::ipc::Ty::Dict(_) => Col::I32(Vec::with_capacity(block_rows)),
            crate::ipc::Ty::Bool => Col::Bool(Vec::with_capacity(block_rows)),
            _ => Col::F64(Vec::with_capacity(block_rows)),
        }
    }

    fn push(&mut self, v: f64) {
        match self {
            Col::F64(b) => b.push(v),
            Col::I32(b) => b.push(v as i32),
            Col::Bool(b) => b.push(v != 0.0),
        }
    }

    /// Borrowed for the write, then emptied: nothing is converted or copied on
    /// the way out, which is the point of writing the IPC here.
    fn borrow(&self) -> crate::ipc::Col<'_> {
        match self {
            Col::F64(b) => crate::ipc::Col::F64(b),
            Col::I32(b) => crate::ipc::Col::I32(b),
            Col::Bool(b) => crate::ipc::Col::Bool(b),
        }
    }

    fn clear(&mut self) {
        match self {
            Col::F64(b) => b.clear(),
            Col::I32(b) => b.clear(),
            Col::Bool(b) => b.clear(),
        }
    }
}

impl Stream {
    /// `deflate` is a ZSTD level; both streams get it, because the point of the
    /// layout is that the variable table can be compressed at all.
    pub fn begin(path: &str, data: &Dataset, block_rows: usize, deflate: Option<u8>) -> Stream {
        let block_rows = block_rows.max(1);
        let at = At(Arc::new(AtomicU64::new(0)));
        let sink = Counting {
            inner: BufWriter::with_capacity(1 << 20, File::create(path).expect("create")),
            at: at.clone(),
        };
        let opts = write_options(deflate);

        let sink = write_one(sink, &variable_table(data), &opts, "variables");
        let units = units_table(data);
        let sink = match &units {
            Some(t) => write_one(sink, t, &opts, "units"),
            None => sink,
        };
        let sink = write_one(sink, &parameters_table(data), &opts, "parameters");

        let fields = data_schema(data);
        let cols = fields.iter().map(|f| Col::of(f.ty, block_rows)).collect();
        let zstd = deflate.map(i32::from);
        let data_writer = crate::ipc::StreamWriter::new(
            sink,
            &fields,
            &[(TABLE_KEY, "data".to_owned())],
            zstd,
        )
        .expect("arrow.modelica data");
        Stream {
            data: Some(data_writer),
            at,
            opts,
            cols,
            rows: 0,
            block_rows,
            batches: Vec::new(),
        }
    }

    pub fn push_rows(&mut self, rows: &[f64]) {
        let n = self.cols.len();
        for row in rows.chunks_exact(n) {
            for (col, v) in self.cols.iter_mut().zip(row) {
                col.push(*v);
            }
            self.rows += 1;
            if self.rows == self.block_rows {
                self.flush();
            }
        }
    }

    fn flush(&mut self) {
        if self.rows == 0 {
            return;
        }
        self.batches.push(self.at.0.load(Ordering::Relaxed));
        {
            let (data, cols) = (&mut self.data, &self.cols);
            let borrowed: Vec<crate::ipc::Col<'_>> = cols.iter().map(Col::borrow).collect();
            data.as_mut().expect("arrow.modelica open").batch(&borrowed).expect("arrow.modelica write");
        }
        for col in &mut self.cols {
            col.clear();
        }
        self.rows = 0;
    }

    pub fn finish(&mut self) {
        if self.data.is_none() {
            return;
        }
        self.flush();
        let data = self.data.take().expect("arrow.modelica open");
        let sink = data.finish().expect("arrow.modelica finish");

        // The index, then the trailer that points at it.
        let index_at = self.at.0.load(Ordering::Relaxed);
        let mut sink = write_one(sink, &index_table(&self.batches), &self.opts, "index");
        sink.write_all(&index_at.to_le_bytes()).expect("arrow.modelica trailer");
        sink.write_all(MAGIC).expect("arrow.modelica trailer");
        sink.flush().expect("arrow.modelica trailer");
    }
}

/// A whole stream in one go, for the tables that are known before the run.
fn write_one(sink: Sink, batch: &RecordBatch, opts: &IpcWriteOptions, what: &str) -> Sink {
    let mut w = StreamWriter::try_new_with_options(sink, batch.schema_ref(), opts.clone())
        .unwrap_or_else(|e| panic!("arrow.modelica {what}: {e}"));
    w.write(batch).unwrap_or_else(|e| panic!("arrow.modelica {what}: {e}"));
    w.finish().unwrap_or_else(|e| panic!("arrow.modelica {what}: {e}"));
    w.into_inner().unwrap_or_else(|e| panic!("arrow.modelica {what}: {e}"))
}

fn write_options(deflate: Option<u8>) -> IpcWriteOptions {
    let opts = IpcWriteOptions::default();
    match deflate {
        None => opts,
        Some(level) => opts
            .try_with_compression(Some(CompressionType::ZSTD))
            .and_then(|o| o.try_with_compression_level(Some(i32::from(level))))
            .expect("arrow.modelica zstd"),
    }
}

/// One field per stored column, named `c0`, `c1`, ... by position: the variable
/// table is the only naming authority, and a field name would be schema, which
/// no codec compresses.
fn data_schema(data: &Dataset) -> Vec<crate::ipc::FieldSpec> {
    use crate::ipc::{FieldSpec, Ty};
    let mut types = vec![Ty::F64; data.n_cols];
    let mut owned = vec![false; data.n_cols];
    let mut typed = vec![false; data.n_cols];
    for v in &data.vars {
        let Kind::Column { col, affine } = v.kind else { continue };
        let c = col as usize;
        if c >= types.len() || owned[c] || (typed[c] && !affine.is_identity()) {
            continue;
        }
        owned[c] = affine.is_identity();
        typed[c] = true;
        // An enumeration would be `Ty::Dict(id)` here, one id per Modelica
        // enumeration type, which is the whole reason for `crate::ipc`. The
        // benchmark never sees one: see the note at the top of this file.
        types[c] = match v.ty {
            VarTy::Integer | VarTy::Enumeration => Ty::I32,
            VarTy::Boolean => Ty::Bool,
            _ => Ty::F64,
        };
    }
    types[0] = Ty::F64;
    types
        .into_iter()
        .enumerate()
        .map(|(i, ty)| FieldSpec { name: format!("c{i}"), ty, nullable: false })
        .collect()
}

/// The variable table. An entry names a `column` or a `parameter` row;
/// `scale`/`offset` are null where they are 1 and 0.
fn variable_table(data: &Dataset) -> RecordBatch {
    let n = data.vars.len();
    let (mut name, mut descr, mut unit, mut display) =
        (Vec::with_capacity(n), Vec::with_capacity(n), Vec::with_capacity(n), Vec::with_capacity(n));
    let (mut column, mut scale, mut offset, mut parameter) =
        (Vec::with_capacity(n), Vec::with_capacity(n), Vec::with_capacity(n), Vec::with_capacity(n));
    let mut next_param = 0i32;
    for v in &data.vars {
        name.push(v.name.clone());
        descr.push(some(&v.comment));
        unit.push(some(&v.unit));
        display.push(some(&v.display_unit));
        match v.kind {
            Kind::Time => {
                column.push(Some(0));
                scale.push(None);
                offset.push(None);
                parameter.push(None);
            }
            Kind::Column { col, affine } => {
                column.push(Some(col as i32));
                scale.push((affine.scale != 1.0).then_some(affine.scale));
                offset.push((affine.offset != 0.0).then_some(affine.offset));
                parameter.push(None);
            }
            Kind::Param { .. } | Kind::Const { .. } => {
                column.push(None);
                scale.push(None);
                offset.push(None);
                parameter.push(Some(next_param));
                next_param += 1;
            }
        }
    }
    let cols: Vec<ArrayRef> = vec![
        Arc::new(StringArray::from(name)),
        Arc::new(StringArray::from(descr)),
        Arc::new(StringArray::from(unit)),
        Arc::new(StringArray::from(display)),
        Arc::new(Int32Array::from(column)),
        Arc::new(Float64Array::from(scale)),
        Arc::new(Float64Array::from(offset)),
        Arc::new(Int32Array::from(parameter)),
    ];
    RecordBatch::try_new(variable_schema(data), cols).expect("arrow.modelica variable table")
}

/// Where a variable's values are: a data column, or a row of the parameter
/// table. Its type comes from whichever it names, so the table carries none.
fn variable_schema(data: &Dataset) -> SchemaRef {
    let meta = HashMap::from([
        (TABLE_KEY.to_owned(), "variables".to_owned()),
        (FORMAT_KEY.to_owned(), FORMAT_VERSION.to_owned()),
        (START_TIME_KEY.to_owned(), format!("{}", data.start_time)),
        (STOP_TIME_KEY.to_owned(), format!("{}", data.stop_time)),
    ]);
    Arc::new(Schema::new_with_metadata(
        vec![
            Field::new("name", DataType::Utf8, false),
            Field::new("description", DataType::Utf8, true),
            Field::new("unit", DataType::Utf8, true),
            Field::new("displayUnit", DataType::Utf8, true),
            Field::new("column", DataType::Int32, true),
            Field::new("scale", DataType::Float64, true),
            Field::new("offset", DataType::Float64, true),
            Field::new("parameter", DataType::Int32, true),
        ],
        meta,
    ))
}

/// The parameter values, in the order the variable table indexes them.
///
/// The rows this is driven from are `f64`, so an Integer or Boolean parameter is
/// narrowed back here and a String parameter has no text to carry.
fn parameters_table(data: &Dataset) -> RecordBatch {
    let n = data.n_params();
    let mut real: Vec<Option<f64>> = Vec::with_capacity(n);
    let mut int: Vec<Option<i32>> = Vec::with_capacity(n);
    let mut boolean: Vec<Option<bool>> = Vec::with_capacity(n);
    let mut string: Vec<Option<String>> = Vec::with_capacity(n);
    let mut params = data.params.iter();
    for v in &data.vars {
        let value = match v.kind {
            Kind::Param { affine } => affine.apply(params.next().copied().unwrap_or(0.0)),
            Kind::Const { value } => value,
            _ => continue,
        };
        let (mut r, mut i, mut b) = (None, None, None);
        match v.ty {
            VarTy::Boolean => b = Some(value != 0.0),
            VarTy::Integer | VarTy::Enumeration => i = Some(value as i32),
            VarTy::String => {}
            VarTy::Real => r = Some(value),
        }
        real.push(r);
        int.push(i);
        boolean.push(b);
        string.push(None);
    }
    let cols: Vec<ArrayRef> = vec![
        Arc::new(Float64Array::from(real)),
        Arc::new(Int32Array::from(int)),
        Arc::new(BooleanArray::from(boolean)),
        Arc::new(StringArray::from(string)),
    ];
    RecordBatch::try_new(parameters_schema(), cols).expect("arrow.modelica parameter table")
}

/// The units the format version does not already predefine; `None`, and no
/// stream at all, when there are none.
///
/// The input names units but defines none, so this writes names with every
/// definition column null - which is a shape a reader has to cope with anyway.
fn units_table(data: &Dataset) -> Option<RecordBatch> {
    let mut seen = std::collections::HashSet::new();
    let mut defs = Vec::new();
    for v in &data.vars {
        if !v.unit.is_empty() && seen.insert(v.unit.clone()) {
            defs.push(openmodelica_arrow_writer::units::UnitDef::new(&v.unit));
        }
    }
    let declared = openmodelica_arrow_writer::units::declared(defs);
    if declared.is_empty() {
        return None;
    }
    let n = declared.len();
    let names: Vec<String> = declared.iter().map(|u| u.name.clone()).collect();
    let mut exponents: Vec<Vec<Option<i32>>> = vec![Vec::with_capacity(n); 8];
    let (mut factor, mut offset) = (Vec::with_capacity(n), Vec::with_capacity(n));
    for u in &declared {
        for (i, e) in exponents.iter_mut().enumerate() {
            e.push(u.base.as_ref().map(|b| b.exponents[i]));
        }
        factor.push(u.base.as_ref().map(|b| b.factor));
        offset.push(u.base.as_ref().map(|b| b.offset));
    }
    let mut cols: Vec<ArrayRef> = vec![Arc::new(StringArray::from(names))];
    for e in exponents {
        cols.push(Arc::new(Int32Array::from(e)));
    }
    cols.push(Arc::new(Float64Array::from(factor)));
    cols.push(Arc::new(Float64Array::from(offset)));
    Some(RecordBatch::try_new(units_schema(), cols).expect("arrow.modelica unit table"))
}

fn units_schema() -> SchemaRef {
    let mut fields = vec![Field::new("name", DataType::Utf8, false)];
    for e in openmodelica_arrow_writer::units::BASE_EXPONENTS {
        fields.push(Field::new(e, DataType::Int32, true));
    }
    fields.push(Field::new("factor", DataType::Float64, true));
    fields.push(Field::new("offset", DataType::Float64, true));
    Arc::new(Schema::new_with_metadata(
        fields,
        HashMap::from([(TABLE_KEY.to_owned(), "units".to_owned())]),
    ))
}

fn parameters_schema() -> SchemaRef {
    Arc::new(Schema::new_with_metadata(
        vec![
            Field::new("real", DataType::Float64, true),
            Field::new("int", DataType::Int32, true),
            Field::new("bool", DataType::Boolean, true),
            Field::new("string", DataType::Utf8, true),
        ],
        HashMap::from([(TABLE_KEY.to_owned(), "parameters".to_owned())]),
    ))
}

fn index_table(offsets: &[u64]) -> RecordBatch {
    let schema = Arc::new(Schema::new_with_metadata(
        vec![Field::new("offset", DataType::Float64, false)],
        HashMap::from([(TABLE_KEY.to_owned(), "index".to_owned())]),
    ));
    let cols: Vec<ArrayRef> =
        vec![Arc::new(Float64Array::from(offsets.iter().map(|o| *o as f64).collect::<Vec<_>>()))];
    RecordBatch::try_new(schema, cols).expect("arrow.modelica index")
}

fn some(s: &str) -> Option<String> {
    (!s.is_empty()).then(|| s.to_owned())
}

/// What a variable is, once the table has been read: a data column, or a row of
/// the parameter table.
struct Var {
    column: Option<usize>,
    scale: f64,
    offset: f64,
    parameter: Option<usize>,
}

pub struct Reader {
    path: String,
    params_at: u64,
    data_at: u64,
    vars: std::collections::HashMap<String, Var>,
    /// Read when a parameter is first asked for, not when the file is opened:
    /// naming the variables does not need their values.
    params: Option<Vec<f64>>,
    n_vars: usize,
    n_rows: usize,
}

impl Reader {
    /// Reads the variable table and stops: the whole cost of answering "what is
    /// in this file", which is what the `list` access pattern measures.
    pub fn open(path: &str) -> Result<Reader, String> {
        let mut file = File::open(path).map_err(|e| e.to_string())?;
        let mut vars = std::collections::HashMap::new();
        let mut n_vars = 0;
        {
            let mut r = StreamReader::try_new(&mut file, None).map_err(|e| e.to_string())?;
            for batch in r.by_ref() {
                let batch = batch.map_err(|e| e.to_string())?;
                n_vars += batch.num_rows();
                read_variables(&batch, &mut vars)?;
            }
        }
        // Step over whatever lies between without decoding it, and stop at the
        // stream that says it is the data: which streams are present is exactly
        // what `modelica.table` is for.
        let mut params_at = file.stream_position().map_err(|e| e.to_string())?;
        let data_at = loop {
            let at = file.stream_position().map_err(|e| e.to_string())?;
            let mut r =
                StreamReader::try_new(&mut file, Some(Vec::new())).map_err(|e| e.to_string())?;
            let table = r
                .schema()
                .metadata()
                .get(TABLE_KEY)
                .cloned()
                .unwrap_or_default();
            if table == "data" {
                break at;
            }
            if table == "parameters" {
                params_at = at;
            }
            for batch in r.by_ref() {
                batch.map_err(|e| e.to_string())?;
            }
            drop(r);
        };
        Ok(Reader { path: path.to_owned(), params_at, data_at, vars, params: None, n_vars, n_rows: 0 })
    }

    pub fn n_variables(&self) -> usize {
        self.n_vars
    }

    /// The offsets `modelica.index` records, and the check that the trailer
    /// leads to them.
    pub fn batch_offsets(&self) -> Result<Vec<u64>, String> {
        let mut file = File::open(&self.path).map_err(|e| e.to_string())?;
        let len = file.seek(SeekFrom::End(-16)).map_err(|e| e.to_string())?;
        let mut trailer = [0u8; 16];
        file.read_exact(&mut trailer).map_err(|e| e.to_string())?;
        if &trailer[8..] != MAGIC {
            return Err("no trailer: the run did not finish".into());
        }
        let at = u64::from_le_bytes(trailer[..8].try_into().unwrap());
        if at >= len {
            return Err("trailer points past the file".into());
        }
        file.seek(SeekFrom::Start(at)).map_err(|e| e.to_string())?;
        let mut out = Vec::new();
        let r = StreamReader::try_new(BufReader::new(file), None).map_err(|e| e.to_string())?;
        for batch in r {
            let batch = batch.map_err(|e| e.to_string())?;
            let col = batch
                .column(0)
                .as_any()
                .downcast_ref::<Float64Array>()
                .ok_or("index column is not f64")?;
            out.extend(col.values().iter().map(|v| *v as u64));
        }
        Ok(out)
    }

    /// The data-stream field indices `names` resolve to.
    fn projection(&self, names: &[String]) -> Vec<usize> {
        let mut p: Vec<usize> =
            names.iter().filter_map(|n| self.vars.get(n).and_then(|v| v.column)).collect();
        p.sort_unstable();
        p.dedup();
        p
    }

    /// The data stream's schema, which costs one message to read.
    fn data_schema(&self) -> Result<SchemaRef, String> {
        Ok(self.stream(Some(Vec::new()))?.schema())
    }

    /// The same read, split by **batch range** rather than by variable.
    ///
    /// Splitting by variable cannot divide anything: a projected read pulls
    /// every batch body it crosses whole, so n threads read the file n times.
    /// Batch ranges are disjoint, and `modelica.index` is what makes them
    /// addressable without walking to them.
    pub fn split_read(&self, names: &[String], threads: usize) -> Result<usize, String> {
        let projection = self.projection(names);
        if projection.is_empty() {
            return Ok(0);
        }
        let offsets = self.batch_offsets()?;
        let schema = self.data_schema()?;
        let per = offsets.len().div_ceil(threads.max(1));
        let total: usize = std::thread::scope(|s| {
            let handles: Vec<_> = offsets
                .chunks(per.max(1))
                .map(|mine| {
                    let (schema, projection, path) = (schema.clone(), &projection, self.path.as_str());
                    s.spawn(move || {
                        let mut file = File::open(path).map_err(|e| e.to_string())?;
                        let mut n = 0;
                        for at in mine {
                            n += batch_at(&mut file, *at, &schema, projection)?;
                        }
                        Ok::<usize, String>(n)
                    })
                })
                .collect();
            handles.into_iter().map(|h| h.join().expect("reader thread").unwrap_or(0)).sum()
        });
        Ok(total)
    }

    /// `bulk` projects every name in one pass over the batches; otherwise one
    /// pass per name, which is what a variable browser does.
    pub fn read(&mut self, names: &[String], bulk: bool) -> usize {
        if bulk {
            return self.pass(names);
        }
        names.iter().map(|n| self.pass(std::slice::from_ref(n))).sum()
    }

    /// One pass over stream 2 with `names` projected.
    fn pass(&mut self, names: &[String]) -> usize {
        let mut projection: Vec<usize> = names
            .iter()
            .filter_map(|n| self.vars.get(n).and_then(|v| v.column))
            .collect();
        projection.sort_unstable();
        projection.dedup();
        if projection.is_empty() {
            return 0;
        }
        let Ok(r) = self.stream(Some(projection)) else { return 0 };
        let mut n = 0;
        for batch in r.map_while(Result::ok) {
            n += batch.num_rows() * batch.num_columns();
        }
        n
    }

    fn stream(&self, projection: Option<Vec<usize>>) -> Result<StreamReader<BufReader<File>>, String> {
        let mut file = File::open(&self.path).map_err(|e| e.to_string())?;
        file.seek(SeekFrom::Start(self.data_at)).map_err(|e| e.to_string())?;
        StreamReader::try_new(BufReader::new(file), projection).map_err(|e| e.to_string())
    }

    /// One variable as `f64`, aliases and parameters included - the variable
    /// table is what makes that possible.
    pub fn trajectory(&mut self, name: &str) -> Option<Vec<f64>> {
        let var = self.vars.get(name)?;
        let (column, scale, offset, parameter) = (var.column, var.scale, var.offset, var.parameter);
        if let Some(slot) = parameter {
            let v = *self.parameters().ok()?.get(slot)?;
            let rows = self.rows()?;
            return Some(vec![v; rows]);
        }
        let column = column?;
        let r = self.stream(Some(vec![column])).ok()?;
        let mut out = Vec::new();
        for batch in r.map_while(Result::ok) {
            let col = batch.column(0);
            out.extend(as_f64(col)?);
        }
        Some(out.into_iter().map(|v| scale * v + offset).collect())
    }

    /// The parameter values as `f64`, whatever column carried them, read at the
    /// first question about a parameter.
    fn parameters(&mut self) -> Result<&[f64], String> {
        if self.params.is_none() {
            let mut file = File::open(&self.path).map_err(|e| e.to_string())?;
            file.seek(SeekFrom::Start(self.params_at)).map_err(|e| e.to_string())?;
            let r = StreamReader::try_new(BufReader::new(file), None).map_err(|e| e.to_string())?;
            let mut out = Vec::new();
            for batch in r {
                let batch = batch.map_err(|e| e.to_string())?;
                // Exactly one column is non-null per row, and which one it is is
                // the variable's type.
                let typed: Vec<Option<Vec<f64>>> =
                    batch.columns().iter().map(|c| as_f64_opt(c)).collect();
                for i in 0..batch.num_rows() {
                    out.push(
                        typed
                            .iter()
                            .zip(batch.columns())
                            .find(|(_, c)| c.is_valid(i))
                            .and_then(|(v, _)| v.as_ref().map(|v| v[i]))
                            .unwrap_or(0.0),
                    );
                }
            }
            self.params = Some(out);
        }
        Ok(self.params.as_deref().expect("parameters"))
    }

    /// The row count, which only the data stream knows.
    fn rows(&mut self) -> Option<usize> {
        if self.n_rows == 0 {
            let r = self.stream(Some(vec![0])).ok()?;
            self.n_rows = r.map_while(Result::ok).map(|b| b.num_rows()).sum();
        }
        Some(self.n_rows)
    }

    /// The trailer and the index, against the batches actually in the data
    /// stream. Part of the round-trip check, so an index nobody can follow does
    /// not pass unnoticed.
    pub fn check_index(&self) -> Result<(), String> {
        let offsets = self.batch_offsets()?;
        let r = self.stream(Some(Vec::new()))?;
        let batches = r.map_while(Result::ok).count();
        if offsets.len() != batches {
            return Err(format!("index names {} batches, the stream has {batches}", offsets.len()));
        }
        if offsets.first().is_some_and(|o| *o < self.data_at) {
            return Err("index points before the data stream".into());
        }
        Ok(())
    }
}

/// One record batch, decoded straight out of the file at a known offset.
fn batch_at(
    file: &mut File,
    at: u64,
    schema: &SchemaRef,
    projection: &[usize],
) -> Result<usize, String> {
    file.seek(SeekFrom::Start(at)).map_err(|e| e.to_string())?;
    let mut prefix = [0u8; 8];
    file.read_exact(&mut prefix).map_err(|e| e.to_string())?;
    if prefix[..4] != [0xff; 4] {
        return Err(format!("no message at {at}"));
    }
    let meta_len = i32::from_le_bytes(prefix[4..].try_into().expect("4 bytes")) as usize;
    let mut meta = vec![0u8; meta_len];
    file.read_exact(&mut meta).map_err(|e| e.to_string())?;
    let message = arrow_ipc::root_as_message(&meta).map_err(|e| e.to_string())?;
    let batch = message.header_as_record_batch().ok_or("not a record batch")?;
    let mut body = vec![0u8; message.bodyLength() as usize];
    file.read_exact(&mut body).map_err(|e| e.to_string())?;
    let decoded = arrow_ipc::reader::read_record_batch(
        &arrow_buffer::Buffer::from_vec(body),
        batch,
        schema.clone(),
        &std::collections::HashMap::new(),
        Some(projection),
        &message.version(),
    )
    .map_err(|e| e.to_string())?;
    Ok(decoded.num_rows() * decoded.num_columns())
}

fn read_variables(
    batch: &RecordBatch,
    out: &mut std::collections::HashMap<String, Var>,
) -> Result<(), String> {
    let names = batch
        .column_by_name("name")
        .and_then(|c| c.as_any().downcast_ref::<StringArray>())
        .ok_or("variable table has no name column")?;
    let col = num_col::<Int32Array>(batch, "column");
    let scale = num_col::<Float64Array>(batch, "scale");
    let offset = num_col::<Float64Array>(batch, "offset");
    let parameter = num_col::<Int32Array>(batch, "parameter");
    for i in 0..batch.num_rows() {
        out.insert(
            names.value(i).to_owned(),
            Var {
                column: col.and_then(|c| c.is_valid(i).then(|| c.value(i) as usize)),
                scale: scale.and_then(|c| c.is_valid(i).then(|| c.value(i))).unwrap_or(1.0),
                offset: offset.and_then(|c| c.is_valid(i).then(|| c.value(i))).unwrap_or(0.0),
                parameter: parameter.and_then(|c| c.is_valid(i).then(|| c.value(i) as usize)),
            },
        );
    }
    Ok(())
}

fn num_col<'a, T: Array + 'static>(batch: &'a RecordBatch, name: &str) -> Option<&'a T> {
    batch.column_by_name(name)?.as_any().downcast_ref::<T>()
}

/// Like [`as_f64`], but a column of a type this reader does not carry values
/// for - a String parameter - is `None` rather than an error.
fn as_f64_opt(col: &ArrayRef) -> Option<Vec<f64>> {
    as_f64(col)
}

fn as_f64(col: &ArrayRef) -> Option<Vec<f64>> {
    if let Some(a) = col.as_any().downcast_ref::<Float64Array>() {
        return Some(a.values().to_vec());
    }
    if let Some(a) = col.as_any().downcast_ref::<Int32Array>() {
        return Some(a.values().iter().map(|v| f64::from(*v)).collect());
    }
    if let Some(a) = col.as_any().downcast_ref::<BooleanArray>() {
        return Some((0..a.len()).map(|i| f64::from(a.value(i))).collect());
    }
    None
}
