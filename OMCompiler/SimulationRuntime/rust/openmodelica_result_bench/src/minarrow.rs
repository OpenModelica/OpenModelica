//! The same Arrow IPC file written and read through minarrow + lightstream
//! instead of arrow-rs, so the two libraries can be measured against each other
//! on the same rows.
//!
//! It is not `arrow.modelica` and cannot be: lightstream's IPC encoder writes
//! `custom_metadata: None` for the schema and for every field, so the variable
//! table, the units and the enumerations have nowhere to live. What this column
//! measures is the two libraries' cost of moving the stored columns, not a file
//! OpenModelica could read back - and its file is smaller than the rest by the
//! whole variable table.

use std::fs::File;
use std::io::BufWriter;

use lightstream::enums::IPCMessageProtocol;
use lightstream::models::readers::ipc::file_table::FileTableReader;
use lightstream::models::writers::ipc::sync_table::SyncTableWriter;
use minarrow::{
    Array, ArrowType, BooleanArray, Field, FieldArray, FloatArray, IntegerArray, MaskedArray,
    NumericArray, Table, Vec64,
};

use crate::dataset::{Dataset, Kind, VarTy};

/// A column's element type, taken from the variable that owns it exactly as the
/// arrow-rs writer takes it.
enum Col {
    F64(Vec64<f64>),
    I32(Vec64<i32>),
    Bool(Vec<bool>),
}

impl Col {
    /// Sized for a whole block up front: `take` leaves an empty buffer behind,
    /// so growing one from nothing would put a realloc per block into `emit`
    /// and measure the benchmark rather than the library.
    fn of(ty: ArrowType, block_rows: usize) -> Col {
        match ty {
            ArrowType::Int32 => Col::I32(Vec64::with_capacity(block_rows)),
            ArrowType::Boolean => Col::Bool(Vec::with_capacity(block_rows)),
            _ => Col::F64(Vec64::with_capacity(block_rows)),
        }
    }

    fn push(&mut self, v: f64) {
        match self {
            Col::F64(b) => b.push(v),
            Col::I32(b) => b.push(v as i32),
            Col::Bool(b) => b.push(v != 0.0),
        }
    }

    fn take(&mut self, block_rows: usize) -> Array {
        match self {
            Col::F64(b) => Array::from_float64(FloatArray::<f64>::from_vec64(
                std::mem::replace(b, Vec64::with_capacity(block_rows)),
                None,
            )),
            Col::I32(b) => Array::from_int32(IntegerArray::<i32>::from_vec64(
                std::mem::replace(b, Vec64::with_capacity(block_rows)),
                None,
            )),
            Col::Bool(b) => {
                let a = Array::from_bool(BooleanArray::from_slice(b));
                b.clear();
                a
            }
        }
    }
}

pub struct Stream {
    writer: SyncTableWriter<BufWriter<File>, Vec64<u8>>,
    fields: Vec<Field>,
    cols: Vec<Col>,
    rows: usize,
    block_rows: usize,
}

impl Stream {
    pub fn begin(path: &str, data: &Dataset, block_rows: usize) -> Stream {
        let block_rows = block_rows.max(1);
        let fields = schema(data);
        let cols = fields.iter().map(|f| Col::of(f.dtype.clone(), block_rows)).collect();
        let file = BufWriter::with_capacity(1 << 20, File::create(path).expect("create"));
        let writer = SyncTableWriter::new(file, fields.clone(), IPCMessageProtocol::File, None);
        Stream { writer, fields, cols, rows: 0, block_rows }
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
        let cols: Vec<FieldArray> = self
            .fields
            .iter()
            .zip(&mut self.cols)
            .map(|(f, c)| FieldArray::new(f.clone(), c.take(self.block_rows)))
            .collect();
        self.writer.write_table(Table::new("result".to_owned(), Some(cols))).expect("minarrow write");
        self.rows = 0;
    }

    pub fn finish(&mut self) {
        self.flush();
        self.writer.finish().expect("minarrow finish");
    }
}

/// One field per stored column, named after the variable that owns it, so the
/// names the read benchmark asks every format for resolve here too.
fn schema(data: &Dataset) -> Vec<Field> {
    let mut names: Vec<Option<String>> = vec![None; data.n_cols];
    let mut types = vec![ArrowType::Float64; data.n_cols];
    // The first variable that owns a column outright names it, which is the
    // rule `Dataset::stored_names` follows, so the names the read benchmark
    // asks every format for resolve here unchanged. A column only aliases own
    // takes the first alias's name and is never asked for.
    let mut owned = vec![false; data.n_cols];
    for v in &data.vars {
        let Kind::Column { col, affine } = v.kind else { continue };
        let c = col as usize;
        if c >= names.len() || owned[c] || (names[c].is_some() && !affine.is_identity()) {
            continue;
        }
        owned[c] = affine.is_identity();
        names[c] = Some(v.name.clone());
        types[c] = match v.ty {
            VarTy::Integer | VarTy::Enumeration => ArrowType::Int32,
            VarTy::Boolean => ArrowType::Boolean,
            _ => ArrowType::Float64,
        };
    }
    // Time is column 0 and always a Float64, whatever aliases it.
    names[0] = Some("time".to_owned());
    types[0] = ArrowType::Float64;
    names
        .into_iter()
        .zip(types)
        .enumerate()
        .map(|(i, (name, ty))| Field::new(name.unwrap_or_else(|| format!("column{i}")), ty, false, None))
        .collect()
}

pub struct Reader {
    file: FileTableReader,
    names: std::collections::HashSet<String>,
}

impl Reader {
    pub fn open(path: &str) -> Result<Reader, String> {
        let file = FileTableReader::open(path).map_err(|e| e.to_string())?;
        let names = file.schema().iter().map(|f| f.name.clone()).collect();
        Ok(Reader { file, names })
    }

    /// `bulk` asks for every name in one projected read, which is what
    /// `ProjectedArrow` does with arrow-rs; otherwise one projected read per
    /// name, which is what a variable browser would do.
    pub fn read(&mut self, names: &[String], bulk: bool) -> usize {
        let mut n = 0;
        if bulk {
            let wanted: Vec<&str> = names.iter().filter(|s| self.has(s)).map(String::as_str).collect();
            if let Ok(t) = self.file.load_table_cols(&wanted) {
                n += t.n_rows * t.cols.len();
            }
            return n;
        }
        for name in names {
            if !self.has(name) {
                continue;
            }
            if let Ok(t) = self.file.load_table_cols(&[name.as_str()]) {
                n += t.n_rows * t.cols.len();
            }
        }
        n
    }

    pub fn n_variables(&self) -> usize {
        self.names.len()
    }

    pub fn trajectory(&mut self, name: &str) -> Option<Vec<f64>> {
        if !self.has(name) {
            return None;
        }
        let table = self.file.load_table_cols(&[name]).ok()?;
        values(table.cols.first()?)
    }

    fn has(&self, name: &str) -> bool {
        self.names.contains(name)
    }
}

/// Every column back as `f64`, the way every other reader here hands values
/// over.
fn values(col: &FieldArray) -> Option<Vec<f64>> {
    Some(match &col.array {
        Array::NumericArray(NumericArray::Float64(a)) => a.data.iter().copied().collect(),
        Array::NumericArray(NumericArray::Int32(a)) => a.data.iter().map(|v| f64::from(*v)).collect(),
        Array::BooleanArray(a) => (0..a.len()).map(|i| f64::from(a.get(i) == Some(true))).collect(),
        _ => return None,
    })
}
