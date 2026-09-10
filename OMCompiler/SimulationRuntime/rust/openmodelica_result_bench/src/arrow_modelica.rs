//! `arrow.modelica` read the way a tool that wants one trajectory would read
//! it: the variable table first and nothing else, then a projected pass over the
//! data stream per name, or the batches divided over threads through
//! `modelica.index`. The product's `ArrowReader` decodes the whole file at open,
//! which is the right thing behind `ResultTable` and the wrong thing to time.
//! The writer is the product's, `openmodelica_arrow_writer`.

use std::collections::HashMap;
use std::fs::File;
use std::io::{BufReader, Read, Seek, SeekFrom};

use arrow_array::{Array, ArrayRef, BooleanArray, Float64Array, Int32Array, Int64Array, RecordBatch, StringArray, UnionArray};
use arrow_ipc::reader::StreamReader;
use arrow_schema::SchemaRef;
use openmodelica_arrow_writer::{TABLE_KEY, TRAILER_MAGIC};

/// What a variable is, once the table has been read: a data column, or a row of
/// the parameter table.
struct Var {
    parameter: bool,
    column: usize,
    scale: f64,
    offset: f64,
}

pub struct Reader {
    path: String,
    params_at: Option<u64>,
    data_at: u64,
    vars: HashMap<String, Var>,
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
        let mut vars = HashMap::new();
        let mut n_vars = 0;
        {
            let mut r = StreamReader::try_new(&mut file, None).map_err(|e| e.to_string())?;
            for batch in r.by_ref() {
                let batch = batch.map_err(|e| e.to_string())?;
                n_vars += batch.num_rows();
                read_variables(&batch, &mut vars)?;
            }
        }
        // Step over the streams before the data without decoding them.
        let mut params_at = None;
        let data_at = loop {
            let at = file.stream_position().map_err(|e| e.to_string())?;
            let mut r = StreamReader::try_new(&mut file, Some(Vec::new())).map_err(|e| e.to_string())?;
            let table = r.schema().metadata().get(TABLE_KEY).cloned().unwrap_or_default();
            if table == "data" {
                break at;
            }
            if table == "parameters" {
                params_at = Some(at);
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
        if &trailer[8..] != TRAILER_MAGIC {
            return Err("no trailer: the run did not finish".into());
        }
        let at = i64::from_le_bytes(trailer[..8].try_into().unwrap());
        if at < 0 || at as u64 >= len {
            return Err("trailer points outside the file".into());
        }
        file.seek(SeekFrom::Start(at as u64)).map_err(|e| e.to_string())?;
        let mut out = Vec::new();
        let r = StreamReader::try_new(BufReader::new(file), None).map_err(|e| e.to_string())?;
        for batch in r {
            let batch = batch.map_err(|e| e.to_string())?;
            let col = batch.column(0).as_any().downcast_ref::<Int64Array>().ok_or("index column is not Int64")?;
            out.extend(col.values().iter().map(|v| *v as u64));
        }
        Ok(out)
    }

    /// The data-stream field indices `names` resolve to.
    fn projection(&self, names: &[String]) -> Vec<usize> {
        let mut p: Vec<usize> = names.iter().filter_map(|n| self.vars.get(n).filter(|v| !v.parameter).map(|v| v.column)).collect();
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

    /// One pass over the data stream with `names` projected.
    fn pass(&mut self, names: &[String]) -> usize {
        let projection = self.projection(names);
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
        let (parameter, column, scale, offset) = (var.parameter, var.column, var.scale, var.offset);
        if parameter {
            let v = *self.parameters().ok()?.get(column)?;
            let rows = self.rows()?;
            return Some(vec![scale * v + offset; rows]);
        }
        let r = self.stream(Some(vec![column])).ok()?;
        let mut out = Vec::new();
        for batch in r.map_while(Result::ok) {
            out.extend(as_f64(batch.column(0))?);
        }
        Some(out.into_iter().map(|v| scale * v + offset).collect())
    }

    /// The parameter values as `f64`, whichever child of the union carried
    /// them (a String is NaN), read at the first question about a parameter.
    fn parameters(&mut self) -> Result<&[f64], String> {
        if self.params.is_none() {
            let mut out = Vec::new();
            if let Some(at) = self.params_at {
                let mut file = File::open(&self.path).map_err(|e| e.to_string())?;
                file.seek(SeekFrom::Start(at)).map_err(|e| e.to_string())?;
                let r = StreamReader::try_new(BufReader::new(file), None).map_err(|e| e.to_string())?;
                for batch in r {
                    let batch = batch.map_err(|e| e.to_string())?;
                    let u = batch.column(0).as_any().downcast_ref::<UnionArray>().ok_or("parameter table is not a union")?;
                    let children: HashMap<i8, Option<Vec<f64>>> = u.type_ids().iter().map(|&id| (id, as_f64(u.child(id)))).collect();
                    for i in 0..u.len() {
                        out.push(children[&u.type_id(i)].as_ref().map_or(f64::NAN, |c| c[u.value_offset(i)]));
                    }
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
fn batch_at(file: &mut File, at: u64, schema: &SchemaRef, projection: &[usize]) -> Result<usize, String> {
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
        &HashMap::new(),
        Some(projection),
        &message.version(),
    )
    .map_err(|e| e.to_string())?;
    Ok(decoded.num_rows() * decoded.num_columns())
}

fn read_variables(batch: &RecordBatch, out: &mut HashMap<String, Var>) -> Result<(), String> {
    let names = num_col::<StringArray>(batch, "name").ok_or("variable table has no name column")?;
    let parameter = num_col::<BooleanArray>(batch, "parameter");
    let column = num_col::<Int32Array>(batch, "column");
    let scale = num_col::<Float64Array>(batch, "scale");
    let offset = num_col::<Float64Array>(batch, "offset");
    for i in 0..batch.num_rows() {
        out.insert(
            names.value(i).to_owned(),
            Var {
                parameter: parameter.is_some_and(|c| c.value(i)),
                column: column.map_or(0, |c| c.value(i).max(0) as usize),
                scale: scale.map_or(1.0, |c| c.value(i)),
                offset: offset.map_or(0.0, |c| c.value(i)),
            },
        );
    }
    Ok(())
}

fn num_col<'a, T: Array + 'static>(batch: &'a RecordBatch, name: &str) -> Option<&'a T> {
    batch.column_by_name(name)?.as_any().downcast_ref::<T>()
}

/// A numeric column as `f64`; `None` for a String or an enumeration, which
/// this reader carries no values for.
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
