//! `omc_result_writer_*`: the result-file writers of the Rust runtime
//! (`.mat`, `.arrow`, `.csv`, `.plt`) for a C simulation runtime, which
//! describes its signals once and then pushes one row of doubles per output
//! point. The C runtime's own writers are replaced by this under
//! `OM_RUST_RESULT_WRITERS` (simulation_result_rust.cpp).

#![allow(non_camel_case_types)]

use std::collections::HashMap;
use std::ffi::{CStr, c_char, c_double, c_int, c_uint};
use std::fs::File;
use std::io::{BufWriter, Seek, SeekFrom, Write};
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::ptr;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{LazyLock, Mutex};

use openmodelica_arrow_writer::{Affine, ArrowKind, ArrowStream, ArrowVar, ColTy, FileMeta, Resolve, VarTy};
use openmodelica_mat_writer::{Mat4Stream, MatKind, MatVar, Neg, Precision};
use openmodelica_plt_writer::{Neg as PltNeg, PltKind, PltVar, write_plt};
use openmodelica_result_files::threads;
use openmodelica_result_files::cmp::format_g_prec;

use crate::set_error;

pub const OMC_RESULT_TYPE_REAL: c_int = 0;
pub const OMC_RESULT_TYPE_INTEGER: c_int = 1;
pub const OMC_RESULT_TYPE_BOOLEAN: c_int = 2;
pub const OMC_RESULT_TYPE_STRING: c_int = 3;
pub const OMC_RESULT_KIND_TIME: c_int = 0;
pub const OMC_RESULT_KIND_COLUMN: c_int = 1;
pub const OMC_RESULT_KIND_PARAMETER: c_int = 2;
pub const OMC_RESULT_NEGATE_NONE: c_int = 0;
pub const OMC_RESULT_NEGATE_ARITHMETIC: c_int = 1;
pub const OMC_RESULT_NEGATE_LOGICAL: c_int = 2;

/// One result signal as the C runtime describes it (mirrored in omc_result.h).
#[repr(C)]
pub struct omc_result_signal {
    pub name: *const c_char,
    pub description: *const c_char,
    pub unit: *const c_char,
    pub display_unit: *const c_char,
    pub type_: c_int,
    pub discrete: c_int,
    pub kind: c_int,
    /// `OMC_RESULT_KIND_COLUMN`: the 0-based row column holding the value.
    pub column: c_uint,
    pub negate: c_int,
    /// `OMC_RESULT_KIND_COLUMN` computed once at initialization: stored like a parameter.
    pub unvarying: c_int,
    /// FMI's `relativeQuantity` (Modelica's `absoluteValue = false`).
    pub relative_quantity: c_int,
}

struct Signal {
    name: String,
    description: String,
    unit: String,
    display_unit: String,
    relative_quantity: bool,
    ty: VarTy,
    discrete: bool,
    kind: c_int,
    column: u32,
    negate: c_int,
    unvarying: bool,
}

fn cstr(p: *const c_char) -> String {
    if p.is_null() { String::new() } else { unsafe { CStr::from_ptr(p) }.to_string_lossy().into_owned() }
}

/// The String values the rows carry as ids (like `sim_meta::strings` in the
/// Rust runtime): shared by every open writer, dropped once the last one
/// closes, so a process that runs simulation after simulation does not grow.
#[derive(Default)]
struct Interned {
    by_id: Vec<String>,
    ids: HashMap<String, u32>,
}

static STRINGS: LazyLock<Mutex<Interned>> = LazyLock::new(Mutex::default);
static OPEN_WRITERS: AtomicUsize = AtomicUsize::new(0);

fn intern(s: &str) -> u32 {
    let mut t = STRINGS.lock().unwrap_or_else(|e| e.into_inner());
    if let Some(&id) = t.ids.get(s) {
        return id;
    }
    let id = t.by_id.len() as u32;
    t.by_id.push(s.to_owned());
    t.ids.insert(s.to_owned(), id);
    id
}

fn resolve() -> Resolve {
    Box::new(|id| STRINGS.lock().unwrap_or_else(|e| e.into_inner()).by_id.get(id as usize).cloned().unwrap_or_default())
}

/// The id of `s` for a String row column or parameter value.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_intern(s: *const c_char) -> c_uint {
    intern(&cstr(s))
}

/// The numeric formats have no place for a String signal or parameter.
fn numeric<'a>(signals: &'a [Signal], params: &[f64]) -> (Vec<&'a Signal>, Vec<f64>) {
    let mut kept = Vec::new();
    let mut kept_params = Vec::new();
    let mut p = params.iter();
    for s in signals {
        let value = (s.kind == OMC_RESULT_KIND_PARAMETER).then(|| p.next().copied().unwrap_or(0.0));
        if s.ty == VarTy::String {
            continue;
        }
        kept_params.extend(value);
        kept.push(s);
    }
    (kept, kept_params)
}

impl Signal {
    fn from_c(s: &omc_result_signal) -> Signal {
        Signal {
            name: cstr(s.name),
            description: cstr(s.description),
            unit: cstr(s.unit),
            display_unit: cstr(s.display_unit),
            relative_quantity: s.relative_quantity != 0,
            ty: match s.type_ {
                OMC_RESULT_TYPE_INTEGER => VarTy::Integer,
                OMC_RESULT_TYPE_BOOLEAN => VarTy::Boolean,
                OMC_RESULT_TYPE_STRING => VarTy::String,
                _ => VarTy::Real,
            },
            discrete: s.discrete != 0,
            kind: if s.kind == OMC_RESULT_KIND_TIME && s.negate != OMC_RESULT_NEGATE_NONE { OMC_RESULT_KIND_COLUMN } else { s.kind },
            column: if s.kind == OMC_RESULT_KIND_TIME { 0 } else { s.column },
            negate: s.negate,
            unvarying: s.unvarying != 0,
        }
    }

    fn neg(&self) -> Neg {
        match self.negate {
            OMC_RESULT_NEGATE_ARITHMETIC => Neg::Arith,
            OMC_RESULT_NEGATE_LOGICAL => Neg::Not,
            _ => Neg::None,
        }
    }

    fn affine(&self) -> Affine {
        match self.negate {
            OMC_RESULT_NEGATE_ARITHMETIC => Affine::NEGATE,
            OMC_RESULT_NEGATE_LOGICAL => Affine::NOT,
            _ => Affine::IDENTITY,
        }
    }

    /// C's `.mat` description: `comment [unit]`.
    fn mat_comment(&self) -> String {
        if self.unit.is_empty() { self.description.clone() } else { format!("{} [{}]", self.description, self.unit) }
    }
}

struct FileOut(BufWriter<File>);

impl openmodelica_arrow_writer::Out for FileOut {
    fn write(&mut self, bytes: &[u8]) {
        let _ = self.0.write_all(bytes);
    }
    fn flush(&mut self) {
        let _ = self.0.flush();
    }
}

impl openmodelica_mat_writer::Out for FileOut {
    fn write(&mut self, bytes: &[u8]) {
        let _ = self.0.write_all(bytes);
    }
    fn write_at(&mut self, pos: u64, bytes: &[u8]) {
        let w = &mut self.0;
        let _ = (|| -> std::io::Result<()> {
            let end = w.seek(SeekFrom::End(0))?;
            w.seek(SeekFrom::Start(pos))?;
            w.write_all(bytes)?;
            w.seek(SeekFrom::Start(end.max(pos + bytes.len() as u64)))?;
            Ok(())
        })();
    }
}

enum Kind {
    Mat(Mat4Stream),
    Arrow(ArrowStream),
    /// `(column, negation, integer-valued)` per written column, time first.
    Csv(Vec<(usize, Neg, bool)>),
    Plt { rows: Vec<f64>, params: Vec<f64> },
}

pub struct omc_result_writer {
    sink: Sink,
    n_cols: usize,
}

/// The rows either go straight into the file, or over a queue to a thread that
/// serializes them while the simulation takes its next step. Which one is
/// [`threads::write`]'s decision.
enum Sink {
    Direct(Writer),
    Threaded(Threaded),
}

/// Everything the serialization owns; it moves to the writer thread whole, so
/// no file handle is ever touched from two threads.
struct Writer {
    signals: Vec<Signal>,
    out: FileOut,
    kind: Kind,
    n_cols: usize,
    ok: bool,
}

/// Rows are handed over `HANDOFF` at a time. One row per handover would wake a
/// sleeping thread at every step boundary, and the futex costs more than the
/// writing it hides.
const HANDOFF: usize = 64;
/// Handovers that may be in flight before the caller has to wait.
const QUEUE: usize = 4;

struct Threaded {
    work: Option<std::sync::mpsc::SyncSender<Vec<f64>>>,
    free: std::sync::mpsc::Receiver<Vec<f64>>,
    worker: Option<std::thread::JoinHandle<bool>>,
    block: Vec<f64>,
    rows: usize,
    live: usize,
}

impl Threaded {
    fn spawn(writer: Writer, n_cols: usize) -> Threaded {
        let (work, jobs) = std::sync::mpsc::sync_channel::<Vec<f64>>(QUEUE);
        let (spent, free) = std::sync::mpsc::sync_channel::<Vec<f64>>(QUEUE);
        let worker = std::thread::spawn(move || {
            let mut w = writer;
            while let Ok(block) = jobs.recv() {
                for row in block.chunks_exact(n_cols.max(1)) {
                    w.emit(row);
                }
                let _ = spent.send(block);
            }
            w.finish()
        });
        Threaded {
            work: Some(work),
            free,
            worker: Some(worker),
            block: Vec::new(),
            rows: 0,
            live: 0,
        }
    }

    fn emit(&mut self, row: &[f64]) {
        // A zero-capacity block is one that has just been handed over. The
        // floor keeps that true for a zero-width row, which would otherwise
        // never take a buffer and spin acquiring one.
        if self.block.capacity() == 0 {
            self.block = self.buffer((row.len() * HANDOFF).max(1));
        }
        self.block.extend_from_slice(row);
        self.rows += 1;
        if self.rows == HANDOFF {
            self.hand_over();
        }
    }

    fn buffer(&mut self, capacity: usize) -> Vec<f64> {
        let mut b = match self.free.try_recv() {
            Ok(b) => b,
            Err(_) if self.live < QUEUE => {
                self.live += 1;
                Vec::with_capacity(capacity)
            }
            // Every buffer is still with the writer: wait for one back, which is
            // the only place the simulation pays for its result file.
            Err(_) => self.free.recv().unwrap_or_else(|_| Vec::with_capacity(capacity)),
        };
        b.clear();
        b
    }

    fn hand_over(&mut self) {
        if self.rows == 0 {
            return;
        }
        // The queue is as deep as the buffer pool, so holding a buffer
        // guarantees a slot and this cannot block.
        if let Some(work) = &self.work {
            let _ = work.send(std::mem::take(&mut self.block));
        }
        self.rows = 0;
    }

    fn finish(&mut self) -> bool {
        self.hand_over();
        // Dropping the sender is what ends the worker's `recv` loop.
        self.work = None;
        match self.worker.take() {
            Some(worker) => worker.join().unwrap_or(false),
            None => false,
        }
    }
}

fn csv_columns(signals: &[Signal], col_types: &[ColTy]) -> Vec<(usize, Neg, bool)> {
    // C's csv: time, every kept variable, then the aliases that are not of a parameter.
    signals
        .iter()
        .filter(|s| s.kind != OMC_RESULT_KIND_PARAMETER && s.ty != VarTy::String)
        .map(|s| {
            let col = if s.kind == OMC_RESULT_KIND_TIME { 0 } else { s.column as usize };
            let int = matches!(col_types.get(col), Some(ColTy::I32 | ColTy::Bool));
            (col, s.neg(), int)
        })
        .collect()
}

fn csv_header(signals: &[Signal]) -> String {
    let mut line = String::new();
    for (i, s) in signals.iter().filter(|s| s.kind != OMC_RESULT_KIND_PARAMETER && s.ty != VarTy::String).enumerate() {
        if i > 0 {
            line.push(',');
        }
        line.push('"');
        line.push_str(&s.name.replace('"', "\"\""));
        line.push('"');
    }
    line.push('\n');
    line
}

fn csv_line(out: &mut String, row: &[f64], cols: &[(usize, Neg, bool)]) {
    for (i, &(col, neg, int)) in cols.iter().enumerate() {
        if i > 0 {
            out.push(',');
        }
        let v = neg.apply(row.get(col).copied().unwrap_or(0.0));
        if int {
            out.push_str(&format!("{}", v as i64));
        } else {
            out.push_str(&format_g_prec(v, 16));
        }
    }
    out.push('\n');
}

trait ApplyNeg {
    fn apply(self, v: f64) -> f64;
}

impl ApplyNeg for Neg {
    fn apply(self, v: f64) -> f64 {
        match self {
            Neg::None => v,
            Neg::Arith => -v,
            Neg::Not => 1.0 - v,
        }
    }
}

#[allow(clippy::too_many_arguments)]
/// A thread only when `omc` allows one, so `-n=1` and the testsuite write as
/// they always did.
fn open(
    path: &str,
    format: &str,
    signals: Vec<Signal>,
    col_types: &[ColTy],
    params: &[f64],
    first_row: &[f64],
    start: f64,
    stop: f64,
    single: bool,
    sync: usize,
) -> Result<omc_result_writer, String> {
    open_where(path, format, signals, col_types, params, first_row, start, stop, single, sync, threads::write())
}

#[allow(clippy::too_many_arguments)]
fn open_where(
    path: &str,
    format: &str,
    signals: Vec<Signal>,
    col_types: &[ColTy],
    params: &[f64],
    first_row: &[f64],
    start: f64,
    stop: f64,
    single: bool,
    sync: usize,
    threaded: bool,
) -> Result<omc_result_writer, String> {
    let n_cols = col_types.len().max(1);
    let file = File::create(path).map_err(|e| format!("Cannot open file {path} for writing: {e}"))?;
    let mut out = FileOut(BufWriter::with_capacity(1 << 20, file));
    let precision = if single { Precision::Single } else { Precision::Double };
    let kind = match format {
        "mat" => {
            let (signals, params) = numeric(&signals, params);
            let comments: Vec<String> = signals.iter().map(|s| s.mat_comment()).collect();
            let vars: Vec<MatVar> = signals
                .iter()
                .zip(&comments)
                .map(|(s, c)| MatVar {
                    name: &s.name,
                    comment: c,
                    kind: match s.kind {
                        OMC_RESULT_KIND_TIME => MatKind::Time,
                        OMC_RESULT_KIND_PARAMETER => MatKind::Param { negate: s.neg() },
                        _ => MatKind::Column { col: s.column, negate: s.neg() },
                    },
                    unvarying: s.unvarying,
                })
                .collect();
            let mut s = Mat4Stream::begin(&mut out, &vars, start, stop, first_row, n_cols as u32, &params, precision);
            s.set_sync(sync);
            Kind::Mat(s)
        }
        "arrow" => {
            let vars: Vec<ArrowVar> = signals
                .iter()
                .map(|s| ArrowVar {
                    name: &s.name,
                    comment: &s.description,
                    unit: &s.unit,
                    display_unit: &s.display_unit,
                    relative_quantity: s.relative_quantity,
                    ty: s.ty,
                    discrete: s.discrete,
                    kind: match s.kind {
                        OMC_RESULT_KIND_TIME => ArrowKind::Time,
                        OMC_RESULT_KIND_PARAMETER => ArrowKind::Param { affine: s.affine() },
                        _ => ArrowKind::Column { col: s.column, affine: s.affine() },
                    },
                    unvarying: s.unvarying,
                    enumeration: None,
                })
                .collect();
            let types: Vec<ColTy> = col_types.iter().map(|&t| if t == ColTy::F64 && single { ColTy::F32 } else { t }).collect();
            let mut s = ArrowStream::begin(
                &mut out,
                &vars,
                params,
                first_row,
                n_cols as u32,
                &types,
                openmodelica_arrow_writer::block_rows(sync),
                resolve(),
                // The C runtime reads its variable attributes from `_init.xml`,
                // which carries no unit definitions: a file it writes leans on
                // the predefined units alone.
                &FileMeta { span: Some((start, stop)), units: &[], zstd: None },
            );
            s.set_sync(sync > 0);
            Kind::Arrow(s)
        }
        "csv" => {
            let _ = out.0.write_all(csv_header(&signals).as_bytes());
            Kind::Csv(csv_columns(&signals, col_types))
        }
        "plt" => Kind::Plt { rows: Vec::new(), params: numeric(&signals, params).1 },
        other => return Err(format!("Unknown output format: {other}")),
    };
    let writer = Writer { signals, out, kind, n_cols, ok: true };
    let sink = if threaded {
        Sink::Threaded(Threaded::spawn(writer, n_cols))
    } else {
        Sink::Direct(writer)
    };
    Ok(omc_result_writer { sink, n_cols })
}

impl omc_result_writer {
    fn emit(&mut self, row: &[f64]) {
        match &mut self.sink {
            Sink::Direct(w) => w.emit(row),
            Sink::Threaded(t) => t.emit(row),
        }
    }

    fn finish(&mut self) -> bool {
        match &mut self.sink {
            Sink::Direct(w) => w.finish(),
            Sink::Threaded(t) => t.finish(),
        }
    }
}

impl Writer {
    fn emit(&mut self, row: &[f64]) {
        match &mut self.kind {
            Kind::Mat(s) => s.push_rows(&mut self.out, row),
            Kind::Arrow(s) => s.push_rows(&mut self.out, row),
            Kind::Csv(cols) => {
                let mut line = String::new();
                csv_line(&mut line, row, cols);
                self.ok &= self.out.0.write_all(line.as_bytes()).is_ok();
            }
            Kind::Plt { rows, .. } => rows.extend_from_slice(row),
        }
    }

    fn finish(&mut self) -> bool {
        match &mut self.kind {
            Kind::Mat(s) => s.finish(&mut self.out),
            Kind::Arrow(s) => s.finish(&mut self.out),
            Kind::Csv(_) => {}
            Kind::Plt { rows, params } => {
                let plt_neg = |n: Neg| match n {
                    Neg::None => PltNeg::None,
                    Neg::Arith => PltNeg::Arith,
                    Neg::Not => PltNeg::Not,
                };
                let vars: Vec<PltVar> = self
                    .signals
                    .iter()
                    .filter(|s| s.ty != VarTy::String)
                    .map(|s| PltVar {
                        name: &s.name,
                        kind: match s.kind {
                            OMC_RESULT_KIND_TIME => PltKind::Time,
                            OMC_RESULT_KIND_PARAMETER => PltKind::Param { negate: plt_neg(s.neg()) },
                            _ => PltKind::Column { col: s.column, negate: plt_neg(s.neg()) },
                        },
                    })
                    .collect();
                let bytes = write_plt(&vars, rows, self.n_cols as u32, params);
                self.ok &= self.out.0.write_all(&bytes).is_ok();
            }
        }
        self.ok &= self.out.0.flush().is_ok();
        self.ok
    }
}

/// Open `path` for `format` (`mat`, `arrow`, `csv`, `plt`). `signals` describe
/// the result variables in file order; `column_types[c]` (an `OMC_RESULT_TYPE_*`)
/// says how row column `c` is stored; `params` holds the `OMC_RESULT_KIND_PARAMETER`
/// values in signal order; `first_row` is the row at open (for the `unvarying`
/// columns). Null with `*error` set on failure.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_writer_open(
    path: *const c_char,
    format: *const c_char,
    signals: *const omc_result_signal,
    n_signals: usize,
    column_types: *const c_int,
    n_columns: usize,
    params: *const c_double,
    n_params: usize,
    first_row: *const c_double,
    start_time: c_double,
    stop_time: c_double,
    single: c_int,
    mat_sync: c_int,
    error: *mut *mut c_char,
) -> *mut omc_result_writer {
    catch_unwind(AssertUnwindSafe(|| {
        let signals: Vec<Signal> = if signals.is_null() { Vec::new() } else { unsafe { std::slice::from_raw_parts(signals, n_signals) }.iter().map(Signal::from_c).collect() };
        let types: Vec<ColTy> = if column_types.is_null() {
            Vec::new()
        } else {
            unsafe { std::slice::from_raw_parts(column_types, n_columns) }
                .iter()
                .map(|&t| match t {
                    OMC_RESULT_TYPE_INTEGER => ColTy::I32,
                    OMC_RESULT_TYPE_BOOLEAN => ColTy::Bool,
                    OMC_RESULT_TYPE_STRING => ColTy::Str,
                    _ => ColTy::F64,
                })
                .collect()
        };
        let params: &[f64] = if params.is_null() { &[] } else { unsafe { std::slice::from_raw_parts(params, n_params) } };
        let first: &[f64] = if first_row.is_null() { &[] } else { unsafe { std::slice::from_raw_parts(first_row, n_columns) } };
        match open(&cstr(path), &cstr(format), signals, &types, params, first, start_time, stop_time, single != 0, mat_sync.max(0) as usize) {
            Ok(w) => {
                OPEN_WRITERS.fetch_add(1, Ordering::AcqRel);
                Box::into_raw(Box::new(w))
            }
            Err(e) => {
                set_error(error, &e);
                ptr::null_mut()
            }
        }
    }))
    .unwrap_or(ptr::null_mut())
}

/// Append one row of `n_columns` doubles.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_writer_emit(w: *mut omc_result_writer, row: *const c_double) {
    if w.is_null() || row.is_null() {
        return;
    }
    let _ = catch_unwind(AssertUnwindSafe(|| {
        let w = unsafe { &mut *w };
        let row = unsafe { std::slice::from_raw_parts(row, w.n_cols) };
        w.emit(row);
    }));
}

/// Write what is pending and close the file. 1 if every write succeeded.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_writer_close(w: *mut omc_result_writer) -> c_int {
    if w.is_null() {
        return 0;
    }
    let mut w = unsafe { Box::from_raw(w) };
    let ok = catch_unwind(AssertUnwindSafe(|| w.finish())).unwrap_or(false);
    drop(w);
    // finish() has joined the writer thread, so no id is resolved after this.
    if OPEN_WRITERS.fetch_sub(1, Ordering::AcqRel) == 1 {
        *STRINGS.lock().unwrap_or_else(|e| e.into_inner()) = Interned::default();
    }
    c_int::from(ok)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn signals() -> Vec<Signal> {
        ["time", "x"]
            .iter()
            .enumerate()
            .map(|(i, name)| Signal {
                name: (*name).to_owned(),
                description: String::new(),
                unit: String::new(),
                display_unit: String::new(),
                relative_quantity: false,
                ty: VarTy::Real,
                discrete: false,
                kind: if i == 0 { OMC_RESULT_KIND_TIME } else { OMC_RESULT_KIND_COLUMN },
                column: i as u32,
                negate: 0,
                unvarying: false,
            })
            .collect()
    }

    /// The writer thread must leave byte for byte the file the direct path
    /// leaves, and the testsuite cannot check that: it runs at `-n=1`, where
    /// the threaded path is never taken.
    #[test]
    fn a_writer_thread_writes_the_same_file() {
        let rows: Vec<f64> =
            (0..500).flat_map(|i| [f64::from(i) * 0.01, f64::from(i * i)]).collect();
        let types = [ColTy::F64, ColTy::F64];
        for format in ["mat", "arrow", "csv", "plt"] {
            let mut written = Vec::new();
            for threaded in [false, true] {
                let path = std::env::temp_dir()
                    .join(format!("omc_capi_{format}_{threaded}.out"))
                    .to_string_lossy()
                    .into_owned();
                let mut w = open_where(
                    &path, format, signals(), &types, &[], &rows[..2], 0.0, 4.99, false, 0, threaded,
                )
                .expect("open");
                for row in rows.chunks_exact(2) {
                    w.emit(row);
                }
                assert!(w.finish(), "{format}, threaded {threaded}: finish failed");
                written.push(std::fs::read(&path).expect("read back"));
                let _ = std::fs::remove_file(&path);
            }
            assert_eq!(written[0], written[1], "{format}: the two paths disagree");
        }
    }
}
