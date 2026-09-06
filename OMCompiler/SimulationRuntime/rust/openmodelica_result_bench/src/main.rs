//! Reading and writing OpenModelica result files, measured across five formats:
//! MATLAB v4, `arrow.modelica`, the `arrow-json` layout it replaces, SDF and
//! MTSF.
//!
//! The input is an existing `.mat`, read into memory once; every format is then
//! written from the same rows and the same variable table, so nothing but the
//! serialization differs. The write loop puts a calibrated busy-wait between
//! consecutive rows - one delay per row, which is what an integration step is -
//! so the reported overhead is the share of a step a result file costs rather
//! than a figure measured with the CPU otherwise idle.
//!
//!     cargo run --release -- --data <dir-with-_res.mat> [--out <dir>]
//!
//! See `--help` for the knobs, and README.md for what each column means.

mod bench;
mod dataset;
mod arrow_modelica;
mod html;
mod ipc;
#[cfg(feature = "minarrow")]
mod minarrow;
mod readers;
mod report;
mod writers;

use std::collections::HashMap;

use bench::{Spinner, timed};
use dataset::Dataset;
use readers::{Access, Reader};
use writers::{Format, Mode, WriteOpts};

struct Config {
    data: Vec<String>,
    out: String,
    reps: usize,
    /// Nanoseconds of busy-wait between two result rows - per row, not per
    /// value: a step produces one whole row at a time.
    delays: Vec<u64>,
    /// `usize::MAX` means every trajectory.
    reads: Vec<usize>,
    block_rows: Vec<usize>,
    /// The HDF5 filter pipelines to try.
    compression: Vec<Compression>,
    chunk_cols: Vec<usize>,
    /// Repeat each dataset's rows this many times; one entry per curve point.
    scales: Vec<usize>,
    /// Where the serialization runs: in the row loop, or on a thread of its own.
    modes: Vec<Mode>,
    /// Rows handed to the writer thread at a time, and how many such blocks may
    /// be in flight before the row loop has to wait.
    handoff: usize,
    queue: usize,
    /// Readers to divide a read over.
    threads: Vec<usize>,
    /// Read with the file already in the page cache as well as cold.
    warm: bool,
    json: Option<String>,
    html: Option<String>,
    keep: bool,
}

impl Config {
    /// The knobs that change what the numbers mean, for the report header.
    fn describe(&self) -> String {
        let cols = |c: &usize| if *c == 0 { "all".to_owned() } else { c.to_string() };
        format!(
            "Block size: {} rows (Arrow record batch, HDF5 chunk). MTSF chunk width: {} columns. \
             Writer thread: {} rows per handover, {} handovers in flight.\n",
            list(&self.block_rows, usize::to_string),
            list(&self.chunk_cols, cols),
            self.handoff,
            self.queue,
        )
    }

    fn opts(&self, s: Setting, rows: usize) -> WriteOpts {
        WriteOpts {
            block_rows: s.block_rows,
            expected_rows: Some(rows),
            deflate: s.compression.level,
            shuffle: s.compression.shuffle,
            chunk_cols: s.chunk_cols,
        }
    }
}

impl Default for Config {
    fn default() -> Config {
        Config {
            data: Vec::new(),
            out: String::new(),
            reps: 5,
            delays: vec![0, 10_000, 100_000, 1_000_000],
            reads: vec![1, 100, usize::MAX],
            block_rows: vec![1024],
            compression: vec![Compression::NONE],
            chunk_cols: vec![0],
            scales: vec![1],
            modes: vec![Mode::Sync],
            handoff: 64,
            queue: 4,
            threads: vec![1],
            warm: false,
            json: None,
            html: None,
            keep: false,
        }
    }
}

fn main() {
    let cfg = match parse_args() {
        Ok(cfg) => cfg,
        Err(msg) => {
            eprintln!("{msg}");
            std::process::exit(2);
        }
    };
    let out = if cfg.out.is_empty() {
        std::env::temp_dir().join("omc_result_bench").to_string_lossy().into_owned()
    } else {
        cfg.out.clone()
    };
    std::fs::create_dir_all(&out).expect("output directory");

    let spinner = Spinner::calibrate();
    let mut report = report::Report::new(&spinner, &cfg, &out);

    for path in &cfg.data {
        eprintln!("loading {path}");
        let (source, span) = timed(|| Dataset::load(path).unwrap_or_else(|e| panic!("{path}: {e}")));
        eprintln!(
            "  {} variables, {} stored columns, {} rows ({:.1} MB payload), loaded in {:.0} ms",
            source.vars.len(),
            source.n_cols,
            source.n_rows,
            source.payload_bytes() as f64 / 1e6,
            span.ms()
        );
        eprintln!("  {}", estimate(&source, &cfg));
        // A run shorter than one block emits nothing while it runs: every
        // format's work lands in `close`, where a writer thread cannot overlap
        // it, and there is one batch to divide a read over.
        if let Some(b) = cfg.block_rows.iter().find(|b| **b >= source.n_rows) {
            eprintln!(
                "  warning: --block-rows {b} is not smaller than the {} rows, so nothing is \
                 written until close",
                source.n_rows
            );
        }

        // One pass per `--scale`: the same variable table over a payload that
        // grows, which is what separates the fixed cost from the per-row cost
        // by measurement rather than by construction.
        for &scale in &cfg.scales {
            let data = if scale > 1 { source.with_rows_scaled(scale) } else { source.clone() };
            if scale > 1 {
                eprintln!("  x{scale}: {} rows ({:.1} MB payload)", data.n_rows, data.payload_bytes() as f64 / 1e6);
            }
            report.add_dataset(&data);
            for &format in Format::ALL {
                for setting in settings_for(&cfg, format) {
                    report.add_structure(structure(&data, format, setting, &cfg.opts(setting, data.n_rows)));
                }
            }

            run_writes(&data, &out, &cfg, &spinner, &mut report);
            for &format in Format::ALL {
                for setting in settings_for(&cfg, format) {
                    report.add_check(verify(&data, format, setting, &out, &cfg));
                }
            }
            run_reads(&data, &out, &cfg, &mut report);

            if !cfg.keep {
                for &format in Format::ALL {
                    for setting in settings_for(&cfg, format) {
                        let _ = std::fs::remove_file(file_path(&out, &data.name, format, setting, &cfg));
                    }
                }
            }
        }
    }

    print!("{}", report.markdown());
    if let Some(path) = &cfg.json {
        std::fs::write(path, report.json()).expect("write json");
        eprintln!("wrote {path}");
    }
    if let Some(path) = &cfg.html {
        std::fs::write(path, html::page(&report.json())).expect("write html");
        eprintln!("wrote {path}");
    }
}

/// An HDF5 filter pipeline: a gzip level, optionally with the byte-shuffle
/// filter ahead of it. Written `none`, `6` or `6s` on the command line.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Compression {
    pub level: Option<u8>,
    pub shuffle: bool,
}

impl Compression {
    pub const NONE: Compression = Compression { level: None, shuffle: false };

    pub fn label(self) -> String {
        match (self.level, self.shuffle) {
            (None, _) => "-".to_owned(),
            (Some(l), false) => l.to_string(),
            (Some(l), true) => format!("{l}+shuf"),
        }
    }

    fn suffix(self) -> String {
        match (self.level, self.shuffle) {
            (None, _) => String::new(),
            (Some(l), false) => format!("-gzip{l}"),
            (Some(l), true) => format!("-gzip{l}s"),
        }
    }

    fn parse(s: &str) -> Result<Compression, String> {
        if s == "none" {
            return Ok(Compression::NONE);
        }
        let (digits, shuffle) = match s.strip_suffix('s') {
            Some(d) => (d, true),
            None => (s, false),
        };
        let level = digits.parse().map_err(|_| "--deflate wants `none`, 0-9, or 0-9 with a trailing `s`".to_owned())?;
        Ok(Compression { level: Some(level), shuffle })
    }
}

/// Everything about how a file is laid out, as opposed to which format it is:
/// one point of the `--deflate` x `--block-rows` x `--chunk-cols` grid.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Setting {
    pub compression: Compression,
    pub block_rows: usize,
    pub chunk_cols: usize,
}

/// The distinct settings this format actually honours, so a sweep over a knob
/// one format ignores does not repeat the same measurement under two headings.
fn settings_for(cfg: &Config, format: Format) -> Vec<Setting> {
    let mut out: Vec<Setting> = Vec::new();
    for &compression in &cfg.compression {
        for &block_rows in &cfg.block_rows {
            for &chunk_cols in &cfg.chunk_cols {
                let s = Setting {
                    compression: match format {
                        // A gzip level for the HDF5 formats, the same number as
                        // a ZSTD level for `arrow`.
                        Format::Sdf | Format::Mtsf | Format::Arrow => compression,
                        _ => Compression::NONE,
                    },
                    // A `.mat` is one matrix, written row by row, with no block
                    // of any kind.
                    block_rows: if format == Format::Mat { cfg.block_rows[0] } else { block_rows },
                    chunk_cols: if format == Format::Mtsf { chunk_cols } else { cfg.chunk_cols[0] },
                };
                if !out.contains(&s) {
                    out.push(s);
                }
            }
        }
    }
    out
}

fn file_path(out: &str, model: &str, format: Format, s: Setting, cfg: &Config) -> String {
    let mut name = format!("{out}/{model}{}", s.compression.suffix());
    if cfg.block_rows.len() > 1 {
        name.push_str(&format!("-b{}", s.block_rows));
    }
    if cfg.chunk_cols.len() > 1 {
        name.push_str(&format!("-c{}", s.chunk_cols));
    }
    name + format.suffix()
}

pub struct WriteRun {
    pub model: String,
    pub format: Format,
    pub setting: Setting,
    pub mode: Mode,
    pub delay_ns: u64,
    /// Per repetition, in milliseconds.
    pub begin: Vec<f64>,
    /// Time inside the writer, summed over the rows.
    pub emit: Vec<f64>,
    /// Of `emit`, the part spent waiting for the writer thread to catch up.
    pub stall: Vec<f64>,
    pub finish: Vec<f64>,
    /// The fsync, timed apart because it is the same cost for every format.
    pub fsync: Vec<f64>,
    /// Kernel time of the whole write, which is where its I/O shows up.
    pub sys: Vec<f64>,
    /// The row loop without the writer, i.e. what `-noemit` would cost.
    pub baseline: Vec<f64>,
    pub file_bytes: u64,
    pub payload_bytes: u64,
    pub n_rows: usize,
}

/// The row loop with the busy-wait and the two clock reads but no writer.
///
/// One per delay per repetition, shared by every cell measured at that delay:
/// it does not depend on the format, and running it per cell doubled a run that
/// is already dominated by the delay.
struct Control {
    /// The clock-read overhead the measured pass has to have subtracted.
    clock_ns: u64,
    wall_ms: f64,
    sys_ms: f64,
}

fn control_pass(data: &Dataset, spinner: &Spinner, delay_ns: u64) -> Control {
    let (clock_ns, span) = timed(|| {
        let mut sum = 0u64;
        for r in 0..data.n_rows {
            spinner.spin(delay_ns);
            let t = std::time::Instant::now();
            std::hint::black_box(&data.rows[r * data.n_cols..(r + 1) * data.n_cols]);
            sum += t.elapsed().as_nanos() as u64;
        }
        sum
    });
    Control { clock_ns, wall_ms: span.ms(), sys_ms: span.sys_ms() }
}

/// Every (format, setting, writer, delay) cell, repeated round-robin: a thermal
/// or scheduling transient then spreads over all of them instead of landing on
/// whichever cell happened to be running, which is what makes the medians
/// comparable across a run that takes minutes.
fn run_writes(data: &Dataset, out: &str, cfg: &Config, spinner: &Spinner, report: &mut report::Report) {
    let mut runs: Vec<WriteRun> = Vec::new();
    for &format in Format::ALL {
        for setting in settings_for(cfg, format) {
            for &mode in &cfg.modes {
                for &delay_ns in &cfg.delays {
                    runs.push(WriteRun {
                        model: data.name.clone(),
                        format,
                        setting,
                        mode,
                        delay_ns,
                        begin: Vec::new(),
                        emit: Vec::new(),
                        stall: Vec::new(),
                        finish: Vec::new(),
                        fsync: Vec::new(),
                        sys: Vec::new(),
                        baseline: Vec::new(),
                        file_bytes: 0,
                        payload_bytes: data.payload_bytes(),
                        n_rows: data.n_rows,
                    });
                }
            }
        }
    }
    // The first pass pays for the file system's first allocation of each file
    // and for HDF5's one-time initialisation.
    for rep in 0..cfg.reps + 1 {
        let control: HashMap<u64, Control> =
            cfg.delays.iter().map(|&d| (d, control_pass(data, spinner, d))).collect();
        for run in &mut runs {
            let path = file_path(out, &data.name, run.format, run.setting, cfg);
            let opts = cfg.opts(run.setting, data.n_rows);
            write_sample(data, run, &path, &opts, spinner, &control[&run.delay_ns], cfg, rep > 0);
        }
    }
    for run in runs {
        report.add_write(run);
    }
}

/// One repetition of one cell.
///
/// The measured row loop is the same loop as [`control_pass`] with the writer
/// between the same two clock reads; subtracting the two clock sums cancels the
/// cost of reading the clock exactly, including the part of it that depends on
/// having just come out of the busy-wait, which a separately calibrated
/// constant would not. The control pass is also the `-noemit` baseline the
/// `step %` column divides by.
#[allow(clippy::too_many_arguments)]
fn write_sample(
    data: &Dataset,
    run: &mut WriteRun,
    path: &str,
    opts: &WriteOpts,
    spinner: &Spinner,
    control: &Control,
    cfg: &Config,
    record: bool,
) {
    let delay_ns = run.delay_ns;
    let (writer, begin) = timed(|| {
        writers::Sink::new(writers::begin(run.format, path, data, opts), run.mode, cfg.handoff, cfg.queue)
    });
    let mut writer = writer;
    let (measured_ns, full) = timed(|| {
        let mut sum = 0u64;
        for r in 0..data.n_rows {
            spinner.spin(delay_ns);
            let t = std::time::Instant::now();
            writer.push_rows(&data.rows[r * data.n_cols..(r + 1) * data.n_cols]);
            sum += t.elapsed().as_nanos() as u64;
        }
        sum
    });
    let stall = writer.stall();
    let (written, finish) = timed(|| writer.finish());
    let ((), fsync) = timed(|| writers::sync(&written));

    if !record {
        return;
    }
    run.begin.push(begin.ms());
    run.emit.push((measured_ns as f64 - control.clock_ns as f64).max(0.0) / 1e6);
    run.stall.push(stall.as_secs_f64() * 1e3);
    run.finish.push(finish.ms());
    run.fsync.push(fsync.ms());
    run.sys.push((begin.sys_ms() + full.sys_ms() + finish.sys_ms() + fsync.sys_ms() - control.sys_ms).max(0.0));
    run.baseline.push(control.wall_ms);
    run.file_bytes = std::fs::metadata(path).map(|m| m.len()).unwrap_or(0);
}

pub struct ReadRun {
    pub model: String,
    pub format: Format,
    pub setting: Setting,
    pub access: Access,
    pub threads: usize,
    pub cold: bool,
    /// Variables asked for; `usize::MAX` means every one.
    pub n_read_request: usize,
    /// Variables actually asked for, once the request has met the file.
    pub n_read: usize,
    pub open: Vec<f64>,
    pub read: Vec<f64>,
    /// Bytes the reader is still holding when it has answered.
    pub held: Vec<f64>,
    pub delivered_bytes: u64,
    pub file_bytes: u64,
}

fn run_reads(data: &Dataset, out: &str, cfg: &Config, report: &mut report::Report) {
    // One variable set for every format, taken from the source: the formats
    // disagree about which names are aliases, and a per-format set would make
    // the throughput columns incomparable.
    let names = data.stored_names();
    let mut runs: Vec<ReadRun> = Vec::new();
    for &format in Format::ALL {
        for setting in settings_for(cfg, format) {
            for access in [Access::PerVar, Access::Bulk, Access::List] {
                for &threads in &cfg.threads {
                    if threads > 1 && !readers::splits(format, access) {
                        continue;
                    }
                    for &k in &cfg.reads {
                        // Listing does not take a variable count; running it
                        // once per `--reads` entry would repeat one number.
                        if access == Access::List && k != cfg.reads[0] {
                            continue;
                        }
                        for cold in [true, false] {
                            if !cold && !cfg.warm {
                                continue;
                            }
                            runs.push(ReadRun {
                                model: data.name.clone(),
                                format,
                                setting,
                                access,
                                threads,
                                cold,
                                n_read_request: k,
                                n_read: 0,
                                open: Vec::new(),
                                read: Vec::new(),
                                held: Vec::new(),
                                delivered_bytes: 0,
                                file_bytes: 0,
                            });
                        }
                    }
                }
            }
        }
    }
    for rep in 0..cfg.reps + 1 {
        for run in &mut runs {
            let path = file_path(out, &data.name, run.format, run.setting, cfg);
            if !std::path::Path::new(&path).exists() {
                let mut w = writers::begin(run.format, &path, data, &cfg.opts(run.setting, data.n_rows));
                w.push_rows(&data.rows);
                writers::sync(&w.finish());
            }
            read_sample(&path, &names, run, rep > 0);
        }
    }
    runs.retain(|r| !r.open.is_empty());
    for run in runs {
        report.add_read(run);
    }
}

fn read_sample(path: &str, names: &[String], run: &mut ReadRun, record: bool) {
    if run.cold {
        readers::evict(path);
    }
    let picked =
        if run.access == Access::List { Vec::new() } else { pick(names, run.n_read_request) };
    let measured = if run.threads > 1 {
        readers::read_parallel(run.format, path, &picked, run.access, run.threads)
    } else {
        let before = bench::heap_in_use_bytes();
        let (reader, open) = timed(|| Reader::open(run.format, path, run.access));
        reader.map(|mut r| {
            let (values, read) = timed(|| r.read(&picked, run.access));
            let held = bench::heap_in_use_bytes().saturating_sub(before);
            (open, read, values, held)
        })
    };
    let (open, read, values, held) = match measured {
        Ok(m) => m,
        Err(e) => {
            eprintln!("  {} read failed: {e}", run.format.name());
            return;
        }
    };

    // Listing delivers names, not values: `vars` is how many the file could
    // name and there is no payload to divide by the time.
    if run.access == Access::List {
        run.n_read = values;
        run.delivered_bytes = 0;
    } else {
        run.n_read = picked.len();
        run.delivered_bytes = values as u64 * 8;
    }
    run.file_bytes = std::fs::metadata(path).map(|m| m.len()).unwrap_or(0);
    if !record {
        return;
    }
    run.open.push(open.ms());
    run.read.push(read.ms());
    run.held.push(held as f64);
}

pub struct Check {
    pub format: Format,
    pub setting: Setting,
    pub variables: usize,
    pub parameters: usize,
    pub mismatches: usize,
    pub max_rel_error: f64,
    pub note: String,
}

/// Read every trajectory and every parameter back and compare with what the
/// writer was given. Nothing in the timings means anything if the formats do
/// not agree on the values.
fn verify(data: &Dataset, format: Format, setting: Setting, out: &str, cfg: &Config) -> Check {
    let path = file_path(out, &data.name, format, setting, cfg);
    let mut check = Check {
        format,
        setting,
        variables: 0,
        parameters: 0,
        mismatches: 0,
        max_rel_error: 0.0,
        note: String::new(),
    };
    let mut reader = match Reader::open(format, &path, Access::PerVar) {
        Ok(r) => r,
        Err(e) => {
            check.note = e;
            return check;
        }
    };
    // A format with no variable table can only answer for its stored columns;
    // its aliases and parameters are not mismatches, they were never written.
    let stored: std::collections::HashSet<String> =
        data.stored_names().into_iter().chain(["time".to_owned()]).collect();
    if !format.has_variable_table() {
        check.note = "no variable table: aliases and parameters are not stored".to_owned();
    }
    let mut next_param = 0;
    for v in &data.vars {
        if !format.has_variable_table() && !stored.contains(&v.name) {
            continue;
        }
        let expect: Vec<f64> = match v.kind {
            dataset::Kind::Time => (0..data.n_rows).map(|r| data.rows[r * data.n_cols]).collect(),
            dataset::Kind::Column { col, affine } => (0..data.n_rows)
                .map(|r| affine.apply(data.rows[r * data.n_cols + col as usize]))
                .collect(),
            // A parameter is one value, which the readers expand over the rows.
            dataset::Kind::Param { affine } => {
                let value = affine.apply(data.params.get(next_param).copied().unwrap_or(0.0));
                next_param += 1;
                check.parameters += 1;
                vec![value; data.n_rows]
            }
            dataset::Kind::Const { value } => vec![value; data.n_rows],
        };
        if matches!(v.kind, dataset::Kind::Time | dataset::Kind::Column { .. }) {
            check.variables += 1;
        }
        let Some(got) = reader.trajectory(&v.name) else {
            check.mismatches += 1;
            continue;
        };
        if got.len() != expect.len() {
            check.mismatches += 1;
            continue;
        }
        let mut bad = false;
        for (a, b) in got.iter().zip(&expect) {
            let scale = a.abs().max(b.abs()).max(1e-300);
            let rel = (a - b).abs() / scale;
            if rel > check.max_rel_error {
                check.max_rel_error = rel;
            }
            bad |= rel > 1e-12;
        }
        check.mismatches += usize::from(bad);
    }
    if let Some(e) = reader.self_check() {
        check.mismatches += 1;
        check.note = e;
    }
    check
}

pub struct Structure {
    pub format: Format,
    pub setting: Setting,
    /// Named things the format creates: HDF5 groups and datasets, Arrow fields,
    /// MATLAB matrices.
    pub objects: usize,
    /// Independently stored and (where enabled) compressed pieces of the data:
    /// HDF5 chunks, Arrow record batches, the `.mat`'s single `data_2`.
    pub blocks: usize,
}

/// What each format has to build for this dataset, counted from the format's
/// own rules. It is the shape of these numbers, not the timings, that explains
/// the timings.
fn structure(data: &Dataset, format: Format, setting: Setting, opts: &WriteOpts) -> Structure {
    let rows = data.n_rows.max(1);
    let chunk = opts.expected_rows.unwrap_or(usize::MAX).min(opts.block_rows).max(1);
    let row_blocks = rows.div_ceil(chunk);
    let (objects, blocks) = match format {
        // Aclass, name, description, dataInfo, data_1, data_2.
        Format::Mat => (6, 1),
        // One field per stored column, `time` included; a parameter is schema
        // metadata rather than a field (and in minarrow's file, nowhere).
        Format::ArrowJson => (data.n_cols, rows.div_ceil(opts.block_rows.max(1))),
        // The data fields, plus the variable table's eight, the parameter
        // table's four and the index's one; a block each for those three.
        Format::Arrow => (data.n_cols + 13, rows.div_ceil(opts.block_rows.max(1)) + 3),
        #[cfg(feature = "minarrow")]
        Format::Minarrow => (data.n_cols, rows.div_ceil(opts.block_rows.max(1))),
        Format::Sdf => {
            let mut groups = std::collections::HashSet::new();
            for v in &data.vars {
                let segments: Vec<&str> = v.name.split('.').collect();
                for end in 1..segments.len() {
                    groups.insert(segments[..end].join("."));
                }
            }
            let trajectories = data.vars.len() - data.n_params();
            (groups.len() + data.vars.len(), trajectories * row_blocks)
        }
        Format::Mtsf => {
            let mut series = std::collections::HashSet::new();
            let mut matrices = std::collections::HashSet::new();
            for v in &data.vars {
                let s = match v.kind {
                    dataset::Kind::Param { .. } | dataset::Kind::Const { .. } => "Fixed",
                    _ if v.discrete => "Discrete",
                    _ => "Continuous",
                };
                series.insert(s);
                matrices.insert((s, v.ty.category()));
            }
            let col_blocks = if opts.chunk_cols == 0 { 1 } else { data.n_cols.div_ceil(opts.chunk_cols) };
            let time_varying = matrices.iter().filter(|(s, _)| *s != "Fixed").count();
            // /ModelDescription and its three tables, /Results, one group per
            // series, one dataset per (series, element type).
            (4 + 1 + series.len() + matrices.len(), time_varying * row_blocks * col_blocks + (matrices.len() - time_varying))
        }
    };
    Structure { format, setting, objects, blocks }
}

/// `k` names spread evenly over the file rather than the first `k`: a run of
/// adjacent variables shares chunks and pages, which would flatter every
/// blocked format.
fn pick(names: &[String], k: usize) -> Vec<String> {
    if k >= names.len() {
        return names.to_vec();
    }
    (0..k).map(|i| names[i * names.len() / k].clone()).collect()
}

/// Roughly how long this configuration will take on this dataset, so a run that
/// is going to take an hour says so before it starts rather than after.
///
/// The delay dominates everything else: it is paid once per row, once per cell
/// and once more per repetition for the control pass every cell subtracts.
fn estimate(data: &Dataset, cfg: &Config) -> String {
    let cells: usize = Format::ALL
        .iter()
        .map(|&f| settings_for(cfg, f).len())
        .sum::<usize>()
        * cfg.modes.len();
    let scale_rows: usize = cfg.scales.iter().sum();
    // One control pass per delay per repetition on top of the cells themselves.
    let delay_total: f64 = cfg.delays.iter().map(|&d| d as f64).sum();
    let secs = delay_total * (cells + 1) as f64 * (data.n_rows * scale_rows) as f64
        * (cfg.reps + 1) as f64
        / 1e9;
    format!(
        "{cells} write cells x {} delays x {} repetitions: at least {} of busy-wait alone",
        cfg.delays.len(),
        cfg.reps + 1,
        human_secs(secs)
    )
}

fn human_secs(s: f64) -> String {
    match s {
        s if s < 90.0 => format!("{s:.0} s"),
        s if s < 5400.0 => format!("{:.0} min", s / 60.0),
        s => format!("{:.1} h", s / 3600.0),
    }
}

fn list<T>(items: &[T], show: impl Fn(&T) -> String) -> String {
    items.iter().map(show).collect::<Vec<_>>().join(",")
}

fn parse_args() -> Result<Config, String> {
    let mut cfg = Config::default();
    let mut args = std::env::args().skip(1);
    while let Some(arg) = args.next() {
        let mut value = || args.next().ok_or_else(|| format!("{arg} needs a value"));
        match arg.as_str() {
            "--data" => {
                let v = value()?;
                cfg.data.extend(expand(&v));
            }
            "--out" => cfg.out = value()?,
            "--reps" => cfg.reps = value()?.parse().map_err(|_| "--reps wants a number")?,
            "--delays" => cfg.delays = value()?.split(',').map(parse_duration).collect::<Result<_, _>>()?,
            "--reads" => {
                cfg.reads = value()?
                    .split(',')
                    .map(|s| if s == "all" { Ok(usize::MAX) } else { s.parse().map_err(|_| "--reads wants numbers or `all`".to_owned()) })
                    .collect::<Result<_, _>>()?;
            }
            "--block-rows" => cfg.block_rows = numbers(&value()?, "--block-rows")?,
            "--deflate" => {
                cfg.compression = value()?.split(',').map(Compression::parse).collect::<Result<_, _>>()?;
            }
            "--chunk-cols" => cfg.chunk_cols = numbers(&value()?, "--chunk-cols")?,
            "--scale" => cfg.scales = numbers(&value()?, "--scale")?,
            "--writer" => cfg.modes = value()?.split(',').map(Mode::parse).collect::<Result<_, _>>()?,
            "--handoff" => cfg.handoff = value()?.parse().map_err(|_| "--handoff wants a number")?,
            "--queue" => cfg.queue = value()?.parse().map_err(|_| "--queue wants a number")?,
            "--threads" => cfg.threads = numbers(&value()?, "--threads")?,
            "--warm" => cfg.warm = true,
            "--json" => cfg.json = Some(value()?),
            "--html" => cfg.html = Some(value()?),
            "--keep" => cfg.keep = true,
            "-h" | "--help" => {
                println!("{USAGE}");
                std::process::exit(0);
            }
            other => return Err(format!("unknown argument {other}\n\n{USAGE}")),
        }
    }
    if cfg.data.is_empty() {
        return Err(format!("no --data given\n\n{USAGE}"));
    }
    if cfg.compression.is_empty() {
        return Err("--deflate needs at least one setting".into());
    }
    if cfg.queue == 0 || cfg.handoff == 0 {
        return Err("--queue and --handoff need at least one".into());
    }
    if cfg.threads.iter().any(|&t| t == 0) {
        return Err("--threads wants at least one reader".into());
    }
    Ok(cfg)
}

fn numbers(s: &str, flag: &str) -> Result<Vec<usize>, String> {
    let out: Vec<usize> = s
        .split(',')
        .map(|s| s.trim().parse().map_err(|_| format!("{flag} wants numbers")))
        .collect::<Result<_, _>>()?;
    if out.is_empty() { Err(format!("{flag} needs a value")) } else { Ok(out) }
}

/// A `.mat` path, or a directory whose `*.mat` files are all taken.
fn expand(arg: &str) -> Vec<String> {
    let p = std::path::Path::new(arg);
    if !p.is_dir() {
        return vec![arg.to_owned()];
    }
    let mut out: Vec<String> = std::fs::read_dir(p)
        .into_iter()
        .flatten()
        .flatten()
        .map(|e| e.path().to_string_lossy().into_owned())
        .filter(|s| s.ends_with(".mat"))
        .collect();
    out.sort();
    out
}

fn parse_duration(s: &str) -> Result<u64, String> {
    let s = s.trim();
    let (num, scale) = match () {
        _ if s.ends_with("ms") => (&s[..s.len() - 2], 1_000_000.0),
        _ if s.ends_with("us") => (&s[..s.len() - 2], 1_000.0),
        _ if s.ends_with("ns") => (&s[..s.len() - 2], 1.0),
        _ if s.ends_with('s') => (&s[..s.len() - 1], 1e9),
        _ => (s, 1.0),
    };
    let v: f64 = num.trim().parse().map_err(|_| format!("bad duration {s}"))?;
    Ok((v * scale) as u64)
}

const USAGE: &str = "\
openmodelica_result_bench --data <path|dir> [options]

  --data <path|dir>   an OpenModelica _res.mat, or a directory of them (repeatable)
  --out <dir>         where the written files go (default: a temp directory)
  --reps <n>          repetitions per measurement (default 5)
  --delays <list>     busy-wait between rows, e.g. 0,10us,100us,1ms (one delay per row)
  --reads <list>      variables per read, e.g. 1,100,all
  --block-rows <list> rows per Arrow batch / HDF5 chunk (default 1024)
  --deflate <list>    HDF5 filter pipelines, e.g. none,6,6s (`s` = byte shuffle)
  --chunk-cols <list> columns per MTSF chunk (default: 0, the whole matrix)
  --scale <list>      repeat each dataset's rows n times, e.g. 1,4,16
  --writer <list>     sync, thread, or both: where the serialization runs
  --handoff <n>       rows handed to the writer thread at a time (default 64)
  --queue <n>         handovers in flight before the row loop waits (default 4)
  --threads <list>    readers to divide a read over, e.g. 1,2,4,8
  --warm              also read with the file already in the page cache
  --json <path>       also write the raw measurements as JSON
  --html <path>       also write an interactive page over those measurements
  --keep              do not delete the written files
";
