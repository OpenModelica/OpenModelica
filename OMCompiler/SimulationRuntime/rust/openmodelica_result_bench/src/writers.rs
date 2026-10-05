//! Every writer behind one interface, each streaming to a real file so the
//! comparison includes the I/O they actually do.

use std::fs::File;
use std::io::{Seek, SeekFrom, Write};
use std::sync::mpsc::{self, Receiver, SyncSender};
use std::thread::JoinHandle;
use std::time::{Duration, Instant};

use openmodelica_arrow_writer as aw;
use openmodelica_hdf5_result as h5w;
use openmodelica_mat_writer as mw;

use crate::dataset::{Dataset, VarDesc};

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Format {
    Mat,
    /// The layout `.arrow` had for a few days before `arrow.modelica`: one IPC
    /// file with the variable table as JSON in its schema metadata. Never
    /// released; the product keeps it only behind the `json-layout` feature,
    /// and it is here only as the *before* of the comparison.
    ArrowJson,
    /// `arrow.modelica`, written by the product's `openmodelica_arrow_writer`;
    /// see `openmodelica_arrow_writer/SPECIFICATION.md`.
    Arrow,
    /// The same Arrow IPC bytes through minarrow + lightstream; see
    /// `crate::minarrow` for what it can and cannot carry.
    #[cfg(feature = "minarrow")]
    Minarrow,
    Sdf,
    Mtsf,
}

impl Format {
    #[cfg(not(feature = "minarrow"))]
    pub const ALL: &'static [Format] =
        &[Format::Mat, Format::ArrowJson, Format::Arrow, Format::Sdf, Format::Mtsf];
    #[cfg(feature = "minarrow")]
    pub const ALL: &'static [Format] = &[
        Format::Mat,
        Format::ArrowJson,
        Format::Arrow,
        Format::Minarrow,
        Format::Sdf,
        Format::Mtsf,
    ];

    pub fn name(self) -> &'static str {
        match self {
            Format::Mat => "mat",
            Format::ArrowJson => "arrow-json",
            Format::Arrow => "arrow",
            #[cfg(feature = "minarrow")]
            Format::Minarrow => "minarrow",
            Format::Sdf => "sdf",
            Format::Mtsf => "mtsf",
        }
    }

    pub fn suffix(self) -> &'static str {
        match self {
            Format::Mat => ".mat",
            Format::ArrowJson => ".arrow-json",
            Format::Arrow => ".arrow",
            #[cfg(feature = "minarrow")]
            Format::Minarrow => ".minarrow",
            Format::Sdf => ".sdf",
            Format::Mtsf => ".mtsf",
        }
    }

    /// Whether the format keeps a variable table, so aliases and parameters can
    /// be read back at all.
    pub fn has_variable_table(self) -> bool {
        #[cfg(feature = "minarrow")]
        if self == Format::Minarrow {
            return false;
        }
        true
    }
}

#[derive(Clone, Copy)]
pub struct WriteOpts {
    /// Rows per Arrow record batch, per HDF5 chunk and per HDF5 write.
    pub block_rows: usize,
    /// The run's length, which the HDF5 formats use to keep a chunk from
    /// running past the end of the data. A simulation knows it too.
    pub expected_rows: Option<usize>,
    /// gzip for the HDF5 formats, ZSTD for `arrow`; the `.mat` and `arrow-json`
    /// writers have no compression to turn on.
    pub deflate: Option<u8>,
    pub shuffle: bool,
    /// Columns per MTSF chunk; 0 = the whole matrix.
    pub chunk_cols: usize,
}

impl Default for WriteOpts {
    fn default() -> WriteOpts {
        WriteOpts { block_rows: 1024, expected_rows: None, deflate: None, shuffle: false, chunk_cols: 0 }
    }
}

/// A buffered sink for the two byte-stream writers. `write_at` is the `.mat`
/// row-count patch, which has to reach the file, so it flushes first.
pub struct FileOut {
    file: File,
    buf: Vec<u8>,
    pos: u64,
}

impl FileOut {
    pub fn create(path: &str) -> std::io::Result<FileOut> {
        Ok(FileOut { file: File::create(path)?, buf: Vec::with_capacity(1 << 20), pos: 0 })
    }

    fn spill(&mut self) {
        if !self.buf.is_empty() {
            self.file.write_all(&self.buf).expect("write");
            self.pos += self.buf.len() as u64;
            self.buf.clear();
        }
    }

    fn done(mut self) -> File {
        self.spill();
        self.file
    }
}

impl mw::Out for FileOut {
    fn write(&mut self, bytes: &[u8]) {
        self.buf.extend_from_slice(bytes);
        if self.buf.len() >= 1 << 20 {
            self.spill();
        }
    }
    fn write_at(&mut self, pos: u64, bytes: &[u8]) {
        self.spill();
        let end = self.pos;
        self.file.seek(SeekFrom::Start(pos)).expect("seek");
        self.file.write_all(bytes).expect("write");
        self.file.seek(SeekFrom::Start(end)).expect("seek");
    }
}

impl aw::Out for FileOut {
    fn write(&mut self, bytes: &[u8]) {
        self.buf.extend_from_slice(bytes);
        if self.buf.len() >= 1 << 20 {
            self.spill();
        }
    }
    fn flush(&mut self) {
        self.spill();
        self.file.flush().expect("flush");
    }
}

pub struct Writer {
    kind: Kind,
    path: String,
}

enum Kind {
    Mat(mw::Mat4Stream, FileOut),
    ArrowJson(Box<aw::json::ArrowStream>, FileOut),
    Arrow(Box<aw::ArrowStream>, FileOut),
    #[cfg(feature = "minarrow")]
    Minarrow(Box<crate::minarrow::Stream>),
    Sdf(h5w::SdfStream),
    Mtsf(h5w::MtsfStream),
}

impl Writer {
    pub fn push_rows(&mut self, rows: &[f64]) {
        match &mut self.kind {
            Kind::Mat(s, out) => s.push_rows(out, rows),
            Kind::ArrowJson(s, out) => s.push_rows(out, rows),
            Kind::Arrow(s, out) => s.push_rows(out, rows),
            #[cfg(feature = "minarrow")]
            Kind::Minarrow(s) => s.push_rows(rows),
            Kind::Sdf(s) => s.push_rows(rows).expect("sdf push"),
            Kind::Mtsf(s) => s.push_rows(rows).expect("mtsf push"),
        }
    }

    /// Write the tail and close the file, leaving it complete but possibly
    /// still in the page cache. HDF5 closes its own file when the stream drops.
    pub fn finish(self) -> String {
        match self.kind {
            Kind::Mat(mut s, mut out) => {
                s.finish(&mut out);
                drop(out.done());
            }
            Kind::ArrowJson(mut s, mut out) => {
                s.finish(&mut out);
                drop(out.done());
            }
            Kind::Arrow(mut s, mut out) => {
                s.finish(&mut out);
                drop(out.done());
            }
            #[cfg(feature = "minarrow")]
            Kind::Minarrow(mut s) => s.finish(),
            Kind::Sdf(mut s) => s.finish().expect("sdf finish"),
            Kind::Mtsf(mut s) => s.finish().expect("mtsf finish"),
        }
        self.path
    }
}

/// Put the file on the device. Timed apart from the format's own finalisation,
/// because it is the same operating-system cost for every format and would
/// otherwise hide the difference between them.
pub fn sync(path: &str) {
    File::open(path).and_then(|f| f.sync_all()).expect("fsync");
}

/// Create the file and write everything that precedes the first row: this is
/// the fixed cost the benchmark reports separately.
pub fn begin(format: Format, path: &str, data: &Dataset, opts: &WriteOpts) -> Writer {
    let n_cols = data.n_cols as u32;
    match format {
        Format::Mat => {
            let vars: Vec<mw::MatVar> = data.vars.iter().map(mat_var).collect();
            let mut out = FileOut::create(path).expect("create");
            let s = mw::Mat4Stream::begin(
                &mut out,
                &vars,
                data.start_time,
                data.stop_time,
                data.first_row(),
                n_cols,
                &data.params,
                mw::Precision::Double,
            );
            Writer { kind: Kind::Mat(s, out), path: path.to_owned() }
        }
        Format::ArrowJson | Format::Arrow => {
            let vars: Vec<aw::ArrowVar> = data.vars.iter().map(arrow_var).collect();
            let col_types = column_types(data);
            let units = aw::units::declared(unit_defs(data));
            let meta = aw::FileMeta { span: Some((data.start_time, data.stop_time)), units: &units, zstd: opts.deflate.map(i32::from) };
            let mut out = FileOut::create(path).expect("create");
            let kind = if format == Format::Arrow {
                let s = aw::ArrowStream::begin(&mut out, &vars, &data.params, data.first_row(), n_cols, &col_types, opts.block_rows, aw::no_strings(), &meta);
                Kind::Arrow(Box::new(s), out)
            } else {
                let s = aw::json::ArrowStream::begin(&mut out, &vars, &data.params, data.first_row(), n_cols, &col_types, opts.block_rows, aw::no_strings(), &meta);
                Kind::ArrowJson(Box::new(s), out)
            };
            Writer { kind, path: path.to_owned() }
        }
        #[cfg(feature = "minarrow")]
        Format::Minarrow => Writer {
            kind: Kind::Minarrow(Box::new(crate::minarrow::Stream::begin(path, data, opts.block_rows))),
            path: path.to_owned(),
        },
        Format::Sdf => {
            let vars: Vec<h5w::Var> = data.vars.iter().map(h5_var).collect();
            let s = h5w::SdfStream::begin(path, &vars, &data.params, data.first_row(), n_cols, &meta(data), &h5_opts(opts))
                .expect("sdf begin");
            Writer { kind: Kind::Sdf(s), path: path.to_owned() }
        }
        Format::Mtsf => {
            let vars: Vec<h5w::Var> = data.vars.iter().map(h5_var).collect();
            let s = h5w::MtsfStream::begin(path, &vars, &data.params, data.first_row(), n_cols, &meta(data), &h5_opts(opts))
                .expect("mtsf begin");
            Writer { kind: Kind::Mtsf(s), path: path.to_owned() }
        }
    }
}

fn h5_opts(opts: &WriteOpts) -> h5w::Options {
    h5w::Options {
        deflate: opts.deflate,
        shuffle: opts.shuffle,
        chunk_rows: opts.block_rows,
        expected_rows: opts.expected_rows,
        chunk_cols: opts.chunk_cols,
        single: false,
    }
}

fn meta(data: &Dataset) -> h5w::Meta<'_> {
    h5w::Meta {
        model_name: &data.name,
        start_time: data.start_time,
        stop_time: data.stop_time,
        ..Default::default()
    }
}

/// A stored column takes the element type of the variable that owns it, so the
/// typed formats really do store an Integer as an int and a Boolean as a byte.
fn column_types(data: &Dataset) -> Vec<aw::ColTy> {
    let mut out = vec![aw::ColTy::F64; data.n_cols];
    let mut owned = vec![false; data.n_cols];
    for v in &data.vars {
        if let h5w::Kind::Column { col, .. } = v.kind {
            let c = col as usize;
            if c < out.len() && !owned[c] {
                owned[c] = true;
                out[c] = match v.ty {
                    h5w::VarTy::Integer | h5w::VarTy::Enumeration => aw::ColTy::I32,
                    h5w::VarTy::Boolean => aw::ColTy::Bool,
                    _ => aw::ColTy::F64,
                };
            }
        }
    }
    // Time is always a Float64 column, whatever aliases it.
    out[0] = aw::ColTy::F64;
    out
}

/// The units the arrow writer records once per file.
fn unit_defs(data: &Dataset) -> Vec<aw::UnitDef> {
    let mut seen = std::collections::HashSet::new();
    let mut out = Vec::new();
    for v in &data.vars {
        if v.unit.is_empty() || !seen.insert(v.unit.clone()) {
            continue;
        }
        out.push(aw::units::UnitDef::new(&v.unit));
    }
    out
}

fn mat_var(v: &VarDesc) -> mw::MatVar<'_> {
    let kind = match v.kind {
        h5w::Kind::Time => mw::MatKind::Time,
        h5w::Kind::Column { col, affine } => {
            mw::MatKind::Column { col, negate: if affine.scale < 0.0 { mw::Neg::Arith } else { mw::Neg::None } }
        }
        h5w::Kind::Param { affine } => {
            mw::MatKind::Param { negate: if affine.scale < 0.0 { mw::Neg::Arith } else { mw::Neg::None } }
        }
        h5w::Kind::Const { value } => mw::MatKind::Const { value },
    };
    mw::MatVar { name: &v.name, comment: &v.comment, kind, unvarying: false }
}

fn arrow_var(v: &VarDesc) -> aw::ArrowVar<'_> {
    let affine = |a: h5w::Affine| aw::Affine { scale: a.scale, offset: a.offset };
    let kind = match v.kind {
        h5w::Kind::Time => aw::ArrowKind::Time,
        h5w::Kind::Column { col, affine: a } => aw::ArrowKind::Column { col, affine: affine(a) },
        h5w::Kind::Param { affine: a } => aw::ArrowKind::Param { affine: affine(a) },
        h5w::Kind::Const { value } => aw::ArrowKind::Const { value },
    };
    aw::ArrowVar {
        name: &v.name,
        comment: &v.comment,
        unit: &v.unit,
        display_unit: &v.display_unit,
        relative_quantity: false,
        ty: arrow_ty(v.ty),
        discrete: v.discrete,
        kind,
        unvarying: false,
        enumeration: None,
    }
}

fn arrow_ty(ty: h5w::VarTy) -> aw::VarTy {
    match ty {
        // An enumeration is a dictionary column when its literals are known;
        // the benchmark's input has none, so it is written as an Integer.
        h5w::VarTy::Integer | h5w::VarTy::Enumeration => aw::VarTy::Integer,
        h5w::VarTy::Boolean => aw::VarTy::Boolean,
        h5w::VarTy::String => aw::VarTy::String,
        h5w::VarTy::Real => aw::VarTy::Real,
    }
}

fn h5_var(v: &VarDesc) -> h5w::Var<'_> {
    h5w::Var {
        name: &v.name,
        comment: &v.comment,
        unit: &v.unit,
        display_unit: &v.display_unit,
        relative_quantity: false,
        ty: v.ty,
        discrete: v.discrete,
        kind: v.kind,
        unvarying: false,
    }
}

/// Where the serialization runs.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Mode {
    /// In the row loop, as a simulation's own thread does it today.
    Sync,
    /// On a thread of its own, so it overlaps the step that follows the row.
    Thread,
}

impl Mode {
    pub const ALL: [Mode; 2] = [Mode::Sync, Mode::Thread];

    pub fn name(self) -> &'static str {
        match self {
            Mode::Sync => "sync",
            Mode::Thread => "thread",
        }
    }

    pub fn parse(s: &str) -> Result<Mode, String> {
        match s {
            "sync" => Ok(Mode::Sync),
            "thread" => Ok(Mode::Thread),
            other => Err(format!("--writer wants `sync` or `thread`, not `{other}`")),
        }
    }
}

/// The row loop's end of a writer, either the writer itself or a queue in front
/// of one on a thread of its own.
pub enum Sink {
    Direct(Writer),
    Threaded(Threaded),
}

impl Sink {
    pub fn new(writer: Writer, mode: Mode, handoff: usize, depth: usize) -> Sink {
        match mode {
            Mode::Sync => Sink::Direct(writer),
            Mode::Thread => Sink::Threaded(Threaded::spawn(writer, handoff, depth)),
        }
    }

    pub fn push_rows(&mut self, rows: &[f64]) {
        match self {
            Sink::Direct(w) => w.push_rows(rows),
            Sink::Threaded(t) => t.push_rows(rows),
        }
    }

    /// Time the row loop spent waiting for the writer to give a buffer back;
    /// zero without a writer thread, since there is nothing to wait for.
    pub fn stall(&self) -> Duration {
        match self {
            Sink::Direct(_) => Duration::ZERO,
            Sink::Threaded(t) => t.stall,
        }
    }

    pub fn finish(self) -> String {
        match self {
            Sink::Direct(w) => w.finish(),
            Sink::Threaded(t) => t.finish(),
        }
    }
}

/// A writer on a thread of its own: the row loop hands rows over and returns,
/// and the serialization runs while the caller integrates the next step.
///
/// Rows are handed over `handoff` at a time. One row per handover is the
/// obvious design and the wrong one: the writer is asleep between two steps, so
/// every row would pay a futex wake, which at a 100 us step cost more than the
/// writing it was hiding. The buffers circulate between the two threads, so a
/// steady state allocates nothing, and the producer blocks only when every
/// buffer is still with the writer - that wait is the one number worth having
/// here, because it is time a simulation would spend waiting for its result
/// file rather than solving.
pub struct Threaded {
    work: SyncSender<Job>,
    free: Receiver<Vec<f64>>,
    handle: Option<JoinHandle<String>>,
    /// The block being filled, and how many rows are in it.
    block: Vec<f64>,
    rows: usize,
    handoff: usize,
    /// Buffers handed out so far; at `depth` the producer has to wait.
    live: usize,
    depth: usize,
    stall: Duration,
}

enum Job {
    Rows(Vec<f64>),
    Finish,
}

impl Threaded {
    /// The writer moves to the thread whole, so no HDF5 handle is ever touched
    /// from two threads.
    fn spawn(writer: Writer, handoff: usize, depth: usize) -> Threaded {
        let (work, jobs) = mpsc::sync_channel::<Job>(depth);
        let (spent, free) = mpsc::sync_channel::<Vec<f64>>(depth);
        let handle = std::thread::spawn(move || {
            // HDF5 keeps an error stack per thread, and the automatic printing
            // is off only on threads that have said so.
            h5w::h5::init();
            let mut writer = writer;
            while let Ok(Job::Rows(buf)) = jobs.recv() {
                writer.push_rows(&buf);
                let _ = spent.send(buf);
            }
            writer.finish()
        });
        Threaded {
            work,
            free,
            handle: Some(handle),
            block: Vec::new(),
            rows: 0,
            handoff: handoff.max(1),
            live: 0,
            depth,
            stall: Duration::ZERO,
        }
    }

    fn push_rows(&mut self, rows: &[f64]) {
        if self.block.capacity() == 0 {
            self.block = self.buffer(rows.len() * self.handoff);
        }
        self.block.extend_from_slice(rows);
        self.rows += 1;
        if self.rows == self.handoff {
            self.hand_over();
        }
    }

    /// A free buffer, waiting for one if every buffer is still with the writer.
    fn buffer(&mut self, capacity: usize) -> Vec<f64> {
        let mut buf = match self.free.try_recv() {
            Ok(buf) => buf,
            Err(_) if self.live < self.depth => {
                self.live += 1;
                Vec::with_capacity(capacity)
            }
            Err(_) => {
                let t = Instant::now();
                let buf = self.free.recv().expect("writer thread died");
                self.stall += t.elapsed();
                buf
            }
        };
        buf.clear();
        buf
    }

    fn hand_over(&mut self) {
        if self.rows == 0 {
            return;
        }
        // The work queue is as deep as the buffer pool, so holding a buffer
        // guarantees a free slot and this send never blocks.
        self.work.send(Job::Rows(std::mem::take(&mut self.block))).expect("writer thread died");
        self.rows = 0;
    }

    /// Drain the queue and close the file: what this costs is the part of the
    /// writing the run did not manage to overlap.
    fn finish(mut self) -> String {
        self.hand_over();
        let _ = self.work.send(Job::Finish);
        self.handle.take().expect("writer thread").join().expect("writer thread")
    }
}
