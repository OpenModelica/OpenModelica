//! The read side: opening a file (metadata only) and then fetching 1, 100 or
//! every trajectory, per format.
//!
//! Three access patterns, because they cost very different things:
//!
//! * *per variable* - what `readSimulationResult`, OMPlot and OMEdit's variable
//!   browser do, one `read_vals` per name;
//! * *bulk* - fetch the backing store once and slice, which only some formats
//!   can do: the `.mat`'s `read_all`, MTSF's whole-matrix read and Arrow's
//!   column projection. SDF has no bulk path at all, since each variable is a
//!   dataset of its own;
//! * *list* - name every variable and read no values, which is what a variable
//!   browser does when a file is opened.

use std::collections::HashMap;
use std::sync::{Arc, Barrier};

use arrow_array::Array;
use arrow_ipc::reader::FileReader;
use openmodelica_mat_reader::{MatReader, ResultTable};
use openmodelica_result_files::{ArrowJsonReader, MtsfReader, SdfReader};

use crate::bench::{Span, Stopwatch};
use crate::writers::Format;

/// How the reader is asked to fetch the trajectories.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Access {
    /// One `read_vals` per variable.
    PerVar,
    /// Fetch the store once, then slice.
    Bulk,
    /// Enumerate the variables and read no values. Every format is asked
    /// through the cheapest reader it has that can answer, which for
    /// `arrow-json` is the projected one - the `ResultTable` reader decodes
    /// every column before it will answer.
    List,
}

pub enum Reader {
    Mat(MatReader),
    ArrowJson(ArrowJsonReader),
    Arrow(crate::arrow_modelica::Reader),
    #[cfg(feature = "minarrow")]
    Minarrow(crate::minarrow::Reader),
    Sdf(SdfReader),
    Mtsf(MtsfReader),
    /// `arrow-json` read through `arrow-ipc`'s own projection rather than
    /// `ArrowJsonReader`, which decodes every column at open.
    ArrowProjected(ProjectedArrow),
}

impl Reader {
    pub fn open(format: Format, path: &str, access: Access) -> Result<Reader, String> {
        Ok(match (format, access) {
            (Format::Mat, _) => Reader::Mat(MatReader::open(path)?),
            (Format::ArrowJson, Access::PerVar) => Reader::ArrowJson(ArrowJsonReader::open(path)?),
            (Format::ArrowJson, Access::Bulk | Access::List) => {
                Reader::ArrowProjected(ProjectedArrow::open(path)?)
            }
            (Format::Arrow, _) => Reader::Arrow(crate::arrow_modelica::Reader::open(path)?),
            #[cfg(feature = "minarrow")]
            (Format::Minarrow, _) => Reader::Minarrow(crate::minarrow::Reader::open(path)?),
            (Format::Sdf, _) => Reader::Sdf(SdfReader::open(path)?),
            (Format::Mtsf, _) => Reader::Mtsf(MtsfReader::open(path)?),
        })
    }

    /// Whatever else the format can check about itself once the values have
    /// been compared: `arrow.modelica` follows its trailer to its batch index.
    pub fn self_check(&self) -> Option<String> {
        match self {
            Reader::Arrow(r) => r.check_index().err(),
            _ => None,
        }
    }

    /// How many variables the reader can name once it has opened.
    pub fn n_variables(&mut self) -> usize {
        match self {
            Reader::ArrowProjected(p) => p.n_variables(),
            Reader::Arrow(r) => r.n_variables(),
            #[cfg(feature = "minarrow")]
            Reader::Minarrow(r) => r.n_variables(),
            _ => self.table_mut().all_info().len(),
        }
    }

    fn table_mut(&mut self) -> &mut dyn ResultTable {
        match self {
            Reader::Mat(r) => r,
            Reader::ArrowJson(r) => r,
            Reader::Sdf(r) => r,
            Reader::Mtsf(r) => r,
            Reader::Arrow(_) => unreachable!("arrow.modelica has no ResultTable"),
            #[cfg(feature = "minarrow")]
            Reader::Minarrow(_) => unreachable!("minarrow has no ResultTable"),
            Reader::ArrowProjected(_) => unreachable!("projected arrow has no ResultTable"),
        }
    }

    /// One variable by name, parameters expanded over the rows as
    /// `ResultReader::trajectory` does.
    pub fn trajectory(&mut self, name: &str) -> Option<Vec<f64>> {
        if let Reader::Arrow(r) = self {
            return r.trajectory(name);
        }
        #[cfg(feature = "minarrow")]
        if let Reader::Minarrow(r) = self {
            return r.trajectory(name);
        }
        if let Reader::ArrowProjected(_) = self {
            return None;
        }
        let t = self.table_mut();
        let idx = t.find_var(name)?;
        let info = &t.all_info()[idx];
        let (is_param, index) = (info.isParam, info.index);
        if !is_param {
            return t.read_vals(index);
        }
        let slot = index.unsigned_abs() as usize;
        let p = *t.params().get(slot.checked_sub(1)?)?;
        Some(vec![if index < 0 { -p } else { p }; t.nrows()])
    }

    /// Fetch `names`; the returned value count also keeps the reads from being
    /// optimised away.
    pub fn read(&mut self, names: &[String], access: Access) -> usize {
        if access == Access::List {
            return self.n_variables();
        }
        if let Reader::Arrow(r) = self {
            return r.read(names, access == Access::Bulk);
        }
        #[cfg(feature = "minarrow")]
        if let Reader::Minarrow(r) = self {
            return r.read(names, access == Access::Bulk);
        }
        if let Reader::ArrowProjected(p) = self {
            return p.read(names);
        }
        if access == Access::Bulk {
            match self {
                Reader::Mat(r) => {
                    r.read_all();
                }
                Reader::Mtsf(r) => r.prefetch(),
                // SDF has nothing to prefetch, Arrow decoded at open.
                _ => {}
            }
        }
        let mut n = 0;
        for name in names {
            let t = self.table_mut();
            let Some(idx) = t.find_var(name) else { continue };
            let index = t.all_info()[idx].index;
            if let Some(v) = t.read_vals(index) {
                n += v.len();
            }
        }
        n
    }
}

/// Arrow's own column projection: the schema and the variable table come from
/// the footer, and only the fields the caller asked for are read off the file.
///
/// A name has to be resolved through `modelica.variables` rather than against
/// the field names: a field is named after the first variable that mentioned
/// its column, which for an aliased signal may be any member of the alias set.
pub struct ProjectedArrow {
    path: String,
    /// Variable name -> field index, aliases included. Parameters are not in
    /// it: they carry a value rather than a column.
    columns: HashMap<String, usize>,
    /// Entries in `modelica.variables`, parameters included, so `list` compares
    /// like with like against a format that can name them.
    entries: usize,
}

impl ProjectedArrow {
    pub fn open(path: &str) -> Result<ProjectedArrow, String> {
        // An empty projection walks the footer and the batch metadata without
        // touching a column.
        let file = std::fs::File::open(path).map_err(|e| e.to_string())?;
        let reader = FileReader::try_new(file, Some(Vec::new())).map_err(|e| e.to_string())?;
        let schema = reader.schema();
        let mut columns: HashMap<String, usize> = schema
            .fields()
            .iter()
            .enumerate()
            .map(|(i, f)| (f.name().clone(), i))
            .collect();
        let mut entries = 0;
        if let Some(table) = schema.metadata().get(openmodelica_arrow_writer::json::VARIABLES_KEY) {
            let (named, total) = variable_columns(table);
            entries = total;
            columns.extend(named);
        }
        for _ in reader.map_while(Result::ok) {}
        let entries = entries.max(columns.len());
        Ok(ProjectedArrow { path: path.to_owned(), columns, entries })
    }

    fn n_variables(&self) -> usize {
        self.entries
    }

    fn read(&mut self, names: &[String]) -> usize {
        let mut projection: Vec<usize> = names.iter().filter_map(|n| self.columns.get(n).copied()).collect();
        projection.sort_unstable();
        projection.dedup();
        let file = std::fs::File::open(&self.path).expect("arrow open");
        let reader = FileReader::try_new(file, Some(projection)).expect("arrow open");
        let mut n = 0;
        for batch in reader.map_while(Result::ok) {
            for col in batch.columns() {
                n += col.len();
            }
        }
        n
    }
}

/// `[{"name":"a.x","column":3}, ...]` -> the name/column pairs, and how many
/// entries there were in all. The table is machine-written, so the scan need
/// only know that a string is `"`-delimited with backslash escapes.
fn variable_columns(json: &str) -> (Vec<(String, usize)>, usize) {
    let mut out = Vec::new();
    let mut entries = 0;
    for entry in json.split("{\"name\":").skip(1) {
        entries += 1;
        let Some(rest) = entry.strip_prefix('"') else { continue };
        let mut name = String::new();
        let mut chars = rest.char_indices();
        let mut end = 0;
        while let Some((i, c)) = chars.next() {
            match c {
                '\\' => {
                    if let Some((_, esc)) = chars.next() {
                        name.push(match esc {
                            'n' => '\n',
                            't' => '\t',
                            other => other,
                        });
                    }
                }
                '"' => {
                    end = i;
                    break;
                }
                other => name.push(other),
            }
        }
        let tail = &rest[end..];
        let Some(at) = tail.find("\"column\":") else { continue };
        let digits: String = tail[at + 9..].chars().take_while(char::is_ascii_digit).collect();
        if let Ok(column) = digits.parse() {
            out.push((name, column));
        }
    }
    (out, entries)
}

/// Tell the kernel to drop this file's clean page cache, so a read benchmark
/// can start cold. Best effort: it is advisory, and only clean pages go.
pub fn evict(path: &str) {
    use std::os::unix::ffi::OsStrExt;
    let Ok(c) = std::ffi::CString::new(std::path::Path::new(path).as_os_str().as_bytes()) else { return };
    unsafe {
        let fd = libc::open(c.as_ptr(), libc::O_RDONLY);
        if fd < 0 {
            return;
        }
        libc::posix_fadvise(fd, 0, 0, libc::POSIX_FADV_DONTNEED);
        libc::close(fd);
    }
}

/// Whether asking for more threads can mean anything for this (format, access).
///
/// Splitting the variable set gives every thread its own reader and its own
/// file handle, which is a real division of labour whenever the format answers
/// one variable at a time - SDF's dataset per variable, Arrow's column
/// projection, a `read_vals` per name. The `.mat`'s `read_all` and MTSF's
/// whole-matrix read are one fetch of the whole store, which does not divide by
/// variable: n threads would each read all of it.
pub fn splits(format: Format, access: Access) -> bool {
    match (format, access) {
        // Listing is one read of one table; there is nothing to divide.
        (_, Access::List) => false,
        // Measured and settled, so a run does not pay for it again. HDF5
        // serialises every call on one global lock and its per-thread opens
        // convoy on top of that: four readers of `RobotR3.FullRobot` cost 12x
        // one, eight cost 34x. `arrow-json` re-reads every batch body it
        // crosses in each thread, whichever way it is split, so eight readers
        // cost 3.6x one.
        (Format::Sdf | Format::Mtsf | Format::ArrowJson, _) => false,
        // Disjoint by construction: one `read_vals` per name reads its own row.
        (Format::Mat, Access::PerVar) => true,
        // One whole-store fetch, which does not divide by variable.
        (Format::Mat, Access::Bulk) => false,
        // A pass over the stream per name, so the names divide the passes; and
        // in bulk, batch ranges through `modelica.index` divide the batches.
        (Format::Arrow, _) => true,
        #[cfg(feature = "minarrow")]
        (Format::Minarrow, _) => true,
    }
}

/// The read, divided over `threads` readers of the same file.
///
/// Each thread opens its own reader and takes every `threads`-th name, so no
/// two threads share a chunk boundary by construction - a contiguous split
/// would give each thread a run of adjacent columns and flatter every blocked
/// format. `open` is when the slowest reader is ready and `read` the wall time
/// from there, so both are what a caller with this many cores would wait.
pub fn read_parallel(
    format: Format,
    path: &str,
    names: &[String],
    access: Access,
    threads: usize,
) -> Result<(Span, Span, usize, u64), String> {
    // The one split that divides the work rather than repeating it: batch
    // ranges of `arrow.modelica`'s data stream, addressed through its index.
    if format == Format::Arrow && access == Access::Bulk {
        let before = crate::bench::heap_in_use_bytes();
        let w = Stopwatch::start();
        let reader = crate::arrow_modelica::Reader::open(path)?;
        let open = w.stop();
        let w = Stopwatch::start();
        let values = reader.split_read(names, threads)?;
        let read = w.stop();
        let held = crate::bench::heap_in_use_bytes().saturating_sub(before);
        drop(reader);
        return Ok((open, read, values, held));
    }
    let opened = Arc::new(Barrier::new(threads + 1));
    let go = Arc::new(Barrier::new(threads + 1));
    let mut handles = Vec::with_capacity(threads);
    // Started before the threads are, so `open` counts the spawn as a caller
    // with this many readers would have to.
    let before = crate::bench::heap_in_use_bytes();
    let w = Stopwatch::start();
    for t in 0..threads {
        let (opened, go) = (Arc::clone(&opened), Arc::clone(&go));
        let path = path.to_owned();
        let mine: Vec<String> = names.iter().skip(t).step_by(threads).cloned().collect();
        handles.push(std::thread::spawn(move || {
            let reader = Reader::open(format, &path, access);
            opened.wait();
            go.wait();
            match reader {
                Ok(mut r) => {
                    let n = r.read(&mine, access);
                    (Ok(r), n)
                }
                Err(e) => (Err(e), 0),
            }
        }));
    }
    opened.wait();
    let open = w.stop();
    let w = Stopwatch::start();
    go.wait();
    let mut readers = Vec::with_capacity(threads);
    let mut values = 0;
    let mut error = None;
    for h in handles {
        let (reader, n) = h.join().expect("reader thread");
        values += n;
        match reader {
            Ok(r) => readers.push(r),
            Err(e) => error = Some(e),
        }
    }
    let read = w.stop();
    let held = crate::bench::heap_in_use_bytes().saturating_sub(before);
    drop(readers);
    match error {
        Some(e) => Err(e),
        None => Ok((open, read, values, held)),
    }
}
