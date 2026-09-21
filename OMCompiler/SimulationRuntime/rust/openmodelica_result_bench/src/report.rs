//! The tables the benchmark prints, and the JSON behind them.
//!
//! A run sweeps whichever knobs it was given, so the markdown tables carry a
//! column for a knob only when it took more than one value: a default run reads
//! exactly as it did before `--writer`, `--threads` and the rest existed. The
//! JSON always carries every dimension, because the HTML report has to be able
//! to pivot on any of them.

use crate::bench::{Spinner, Stats};
use crate::dataset::Dataset;
use crate::readers::Access;
use crate::{Check, Config, ReadRun, Setting, Structure, WriteRun};

struct DatasetInfo {
    name: String,
    short: String,
    n_vars: usize,
    n_cols: usize,
    n_rows: usize,
    n_params: usize,
    n_aliases: usize,
    payload_bytes: u64,
}

/// Which knobs this run actually swept. A column for a knob with one value is
/// noise in every row.
#[derive(Default)]
struct Varies {
    gzip: bool,
    block_rows: bool,
    chunk_cols: bool,
    writer: bool,
    threads: bool,
}

pub struct Report {
    datasets: Vec<DatasetInfo>,
    structures: Vec<(String, Structure)>,
    writes: Vec<WriteRun>,
    reads: Vec<ReadRun>,
    checks: Vec<(String, Check)>,
    spin_iters_per_us: f64,
    settings: String,
    reps: usize,
    out: String,
    warm: bool,
    handoff: usize,
    queue: usize,
    varies: Varies,
}

impl Report {
    pub fn new(spinner: &Spinner, cfg: &Config, out: &str) -> Report {
        Report {
            datasets: Vec::new(),
            structures: Vec::new(),
            writes: Vec::new(),
            reads: Vec::new(),
            checks: Vec::new(),
            spin_iters_per_us: spinner.iters_per_us(),
            settings: cfg.describe(),
            reps: cfg.reps,
            out: out.to_owned(),
            warm: cfg.warm,
            handoff: cfg.handoff,
            queue: cfg.queue,
            varies: Varies {
                gzip: cfg.compression.len() > 1,
                block_rows: cfg.block_rows.len() > 1,
                chunk_cols: cfg.chunk_cols.len() > 1,
                writer: cfg.modes.len() > 1,
                threads: cfg.threads.len() > 1,
            },
        }
    }

    fn model(&self) -> String {
        self.datasets.last().map_or_else(String::new, |d| d.name.clone())
    }

    fn short(&self, model: &str) -> String {
        self.datasets.iter().find(|d| d.name == model).map_or_else(|| model.to_owned(), |d| d.short.clone())
    }

    pub fn add_dataset(&mut self, d: &Dataset) {
        self.datasets.push(DatasetInfo {
            name: d.name.clone(),
            short: d.short_name(),
            n_vars: d.vars.len(),
            n_cols: d.n_cols,
            n_rows: d.n_rows,
            n_params: d.n_params(),
            n_aliases: d.n_aliases(),
            payload_bytes: d.payload_bytes(),
        });
    }

    pub fn add_structure(&mut self, s: Structure) {
        let model = self.model();
        self.structures.push((model, s));
    }

    pub fn add_check(&mut self, check: Check) {
        let model = self.model();
        self.checks.push((model, check));
    }

    pub fn add_write(&mut self, run: WriteRun) {
        self.writes.push(run);
    }

    pub fn add_read(&mut self, run: ReadRun) {
        self.reads.push(run);
    }

    pub fn markdown(&self) -> String {
        let mut s = String::new();
        s.push_str("# Result-file formats: read and write\n\n");
        s.push_str(&self.environment());
        s.push_str(&self.datasets_table());
        s.push_str(&self.structure_table());
        s.push_str(&self.write_table());
        s.push_str(&self.check_table());
        s.push_str(&self.read_table());
        s
    }

    /// The setting columns this run needs, as a header fragment and a per-row
    /// closure, so every table agrees about which ones exist.
    fn setting_headers(&self) -> (String, String) {
        let mut head = String::new();
        let mut rule = String::new();
        if self.varies.gzip {
            head.push_str(" gzip |");
            rule.push_str("-----:|");
        }
        if self.varies.block_rows {
            head.push_str(" block |");
            rule.push_str("------:|");
        }
        if self.varies.chunk_cols {
            head.push_str(" cols |");
            rule.push_str("-----:|");
        }
        (head, rule)
    }

    fn setting_cells(&self, s: Setting) -> String {
        let mut out = String::new();
        if self.varies.gzip {
            out.push_str(&format!(" {} |", s.compression.label()));
        }
        if self.varies.block_rows {
            out.push_str(&format!(" {} |", s.block_rows));
        }
        if self.varies.chunk_cols {
            out.push_str(&format!(" {} |", if s.chunk_cols == 0 { "all".to_owned() } else { s.chunk_cols.to_string() }));
        }
        out
    }

    fn environment(&self) -> String {
        let cpu = proc_field("/proc/cpuinfo", "model name").unwrap_or_else(|| "unknown".into());
        let cores = std::thread::available_parallelism().map_or(0, std::num::NonZero::get);
        let kernel = std::fs::read_to_string("/proc/sys/kernel/osrelease")
            .map_or_else(|_| "unknown".into(), |s| s.trim().to_owned());
        let load = std::fs::read_to_string("/proc/loadavg")
            .ok()
            .and_then(|s| s.split_whitespace().next().map(str::to_owned))
            .unwrap_or_else(|| "unknown".into());
        format!(
            "CPU: {cpu} ({cores} threads). Linux {kernel}. HDF5 {} ({}), arrow-rs {ARROW_VERSION}, {}.\n\n\
             Files are written to `{}`, a {} filesystem. Every write figure depends on that, and \
             a container's overlay mount behaves nothing like the disk under it.\n\n\
             The one-minute load average when the report was written was {load}; anything much \
             above zero means the machine was shared and the absolute times are an upper bound.\n\n\
             {} repetitions per cell after one warm-up, the cells interleaved so a thermal or \
             scheduling transient spreads over all of them rather than landing on one. The median \
             is reported; `spread` is half the min-max range as a percentage of it. The busy-wait \
             between two rows is paid once per row, not once per value; its rate here is \
             {:.0} iterations/us.\n\n{}\n",
            openmodelica_hdf5_result::h5::version(),
            hdf5_concurrency(),
            rustc_version(),
            self.out,
            crate::bench::filesystem(&self.out),
            self.reps,
            self.spin_iters_per_us,
            self.settings,
        )
    }

    fn datasets_table(&self) -> String {
        let mut s = String::from("## Datasets\n\n");
        s.push_str("| model | variables | stored columns | aliases | parameters | rows | payload |\n");
        s.push_str("|-------|----------:|---------------:|--------:|-----------:|-----:|--------:|\n");
        for d in &self.datasets {
            s.push_str(&format!(
                "| {} | {} | {} | {} | {} | {} | {:.1} MB |\n",
                d.short, d.n_vars, d.n_cols, d.n_aliases, d.n_params, d.n_rows, d.payload_bytes as f64 / 1e6
            ));
        }
        s.push_str("\nThe tables below name each model by the tail of its path:\n\n");
        for d in &self.datasets {
            s.push_str(&format!("* `{}` - {}\n", d.short, d.name));
        }
        s
    }

    /// Counted from each format's own rules rather than measured. It is the
    /// shape of these numbers, not the timings, that explains the timings.
    fn structure_table(&self) -> String {
        let (head, rule) = self.setting_headers();
        let mut s = String::from("\n## What each format builds\n\n");
        s.push_str(
            "`objects` counts the named things in the file - HDF5 groups and datasets, Arrow \
             fields, MATLAB matrices - and `blocks` the independently stored (and, under gzip, \
             independently compressed) pieces of the data.\n\n",
        );
        s.push_str(&format!("| model | format |{head} objects | blocks |\n"));
        s.push_str(&format!("|-------|--------|{rule}--------:|-------:|\n"));
        for (model, t) in &self.structures {
            s.push_str(&format!(
                "| {} | {} |{} {} | {} |\n",
                self.short(model),
                t.format.name(),
                self.setting_cells(t.setting),
                t.objects,
                t.blocks
            ));
        }
        s
    }

    fn write_table(&self) -> String {
        let (head, rule) = self.setting_headers();
        let mut s = String::from("\n## Writing\n\n");
        s.push_str(
            "`open` is the fixed cost: the file's variable table, written before the first row. \
             `emit` is the sum of the per-row calls and `close` the format's own finalisation; \
             a block size larger than the run leaves nothing for `emit` to do and puts it all in \
             `close`. `fsync` is timed apart because it is the same operating-system cost for \
             every format, `total` is all four together and `sys` the kernel time of them. \
             `ns/value` is `emit` over the values written. `MB/s` is the payload (rows x stored \
             columns x 8 B) over `open + emit + close`, not over `emit` alone: where the payload \
             is actually serialized differs per format, and a block bigger than the run leaves \
             `emit` doing nothing but copying, which would read as an enormous throughput for a \
             writer that had not yet written anything. `fsync` stays out of it because it is the \
             device rather than the format. `step %` is `total` as a fraction of the same loop \
             with no writer in it, so it reads as the price of the result file on a run whose \
             steps take that long.\n\n",
        );
        if self.varies.writer {
            s.push_str(&format!(
                "`writer` is where the serialization ran: `sync` in the row loop, `thread` on a \
                 thread of its own taking {} rows at a time with {} handovers in flight, which \
                 leaves `emit` holding little more than the row copy. `stall` is the part of \
                 `emit` the row loop spent waiting for that thread to give a buffer back - the \
                 writing it could not overlap - and whatever is left in the queue at the end is \
                 paid in `close`.\n\n",
                self.handoff, self.queue
            ));
        }
        s.push_str(&format!("| model | format |{head}"));
        if self.varies.writer {
            s.push_str(" writer |");
        }
        s.push_str(" delay | open ms | emit ms |");
        if self.varies.writer {
            s.push_str(" stall ms |");
        }
        s.push_str(" close ms | fsync ms | total ms | sys ms | ns/value | MB/s | file | vs payload | step % | spread |\n");
        s.push_str(&format!("|-------|--------|{rule}"));
        if self.varies.writer {
            s.push_str("--------|");
        }
        s.push_str("------:|--------:|--------:|");
        if self.varies.writer {
            s.push_str("---------:|");
        }
        s.push_str("---------:|---------:|---------:|-------:|---------:|-----:|-----:|-----------:|-------:|-------:|\n");
        for r in &self.writes {
            let open = Stats::of(&r.begin);
            let emit = Stats::of(&r.emit);
            let stall = Stats::of(&r.stall);
            let close = Stats::of(&r.finish);
            let fsync = Stats::of(&r.fsync);
            let sys = Stats::of(&r.sys);
            let base = Stats::of(&r.baseline);
            let total = open.median + emit.median + close.median + fsync.median;
            let values = (r.payload_bytes / 8).max(1) as f64;
            // Without a delay there is no step to be a fraction of.
            let step_pct = if r.delay_ns > 0 { total / base.median * 100.0 } else { f64::NAN };
            s.push_str(&format!("| {} | {} |{}", self.short(&r.model), r.format.name(), self.setting_cells(r.setting)));
            if self.varies.writer {
                s.push_str(&format!(" {} |", r.mode.name()));
            }
            s.push_str(&format!(" {} | {:.1} | {:.2} |", duration(r.delay_ns), open.median, emit.median));
            if self.varies.writer {
                s.push_str(&format!(" {:.2} |", stall.median));
            }
            s.push_str(&format!(
                " {:.1} | {:.1} | {:.1} | {:.2} | {:.1} | {} | {:.1} MB | {:.2} | {} | ±{:.0}% |\n",
                close.median,
                fsync.median,
                total,
                sys.median,
                emit.median * 1e6 / values,
                throughput(r.payload_bytes, open.median + emit.median + close.median),
                r.file_bytes as f64 / 1e6,
                r.file_bytes as f64 / r.payload_bytes.max(1) as f64,
                if step_pct.is_nan() { "-".to_owned() } else { format!("{step_pct:.1}") },
                emit.spread_pct(),
            ));
        }
        s
    }

    fn check_table(&self) -> String {
        let (head, rule) = self.setting_headers();
        let mut s = String::from("\n## Round-trip check\n\n");
        s.push_str(
            "Every trajectory and every parameter read back from the written file and compared \
             with what the writer was given. A non-zero `mismatches` invalidates the timings \
             above it.\n\n",
        );
        s.push_str(&format!("| model | format |{head} trajectories | parameters | mismatches | max relative error |\n"));
        s.push_str(&format!("|-------|--------|{rule}-------------:|-----------:|-----------:|-------------------:|\n"));
        for (model, c) in &self.checks {
            s.push_str(&format!(
                "| {} | {} |{} {} | {} | {} | {:.1e}{} |\n",
                self.short(model),
                c.format.name(),
                self.setting_cells(c.setting),
                c.variables,
                c.parameters,
                c.mismatches,
                c.max_rel_error,
                if c.note.is_empty() { String::new() } else { format!(" ({})", c.note) }
            ));
        }
        s
    }

    fn read_table(&self) -> String {
        let (head, rule) = self.setting_headers();
        let mut s = String::from("\n## Reading\n\n");
        s.push_str(
            "`open` is again the fixed cost: whatever the reader must read before it can answer \
             a question about any variable. `per var` fetches one trajectory per name, as \
             `readSimulationResult`, OMPlot and OMEdit's variable browser do; `bulk` uses the \
             best path the format offers for a known set - the `.mat`'s `read_all`, MTSF's \
             whole-matrix read, Arrow's column projection - and is the same as `per var` for \
             SDF, which has none. `list` reads no values at all: it is what a variable browser \
             does when a file is opened, so its `vars` is every variable the file names and its \
             `read` is zero by construction. The same variable names are asked of every format, so \
             `delivered` is comparable across rows. `MB/s` is `delivered` over `open + read`, \
             not over `read` alone: the formats disagree about which of the two moves the data - \
             `ArrowReader` decodes every column while it opens, and its `read` is then only a \
             lookup - so dividing by `read` would rank the readers by where they do the work \
             rather than by how long the answer took. `held` is the memory the reader is still \
             holding when it has answered.\n\n",
        );
        if self.varies.threads {
            s.push_str(
                "`threads` readers of the same file each take every n-th name and open a handle \
                 of their own; `open` is when the slowest of them is ready and `read` the wall \
                 time from there. The `.mat`'s and MTSF's bulk paths are one fetch of the whole \
                 store, which does not divide by variable, so they are measured on one thread \
                 only.\n\n",
            );
        }
        if self.warm {
            s.push_str(
                "A `cold` row dropped the file's page cache first; the `warm` row under it \
                 repeats the identical read straight afterwards, so what it finds cached is \
                 exactly what that read needs - a second plot of the same variable, not a \
                 second pass over the whole file.\n\n",
            );
        } else {
            s.push_str("The page cache is dropped before every repetition.\n\n");
        }
        s.push_str(&format!("| model | format |{head} access |"));
        if self.varies.threads {
            s.push_str(" threads |");
        }
        if self.warm {
            s.push_str(" cache |");
        }
        s.push_str(" vars | open ms | read ms | MB/s | delivered | held | spread |\n");
        s.push_str(&format!("|-------|--------|{rule}--------|"));
        if self.varies.threads {
            s.push_str("--------:|");
        }
        if self.warm {
            s.push_str("-------|");
        }
        s.push_str("-----:|--------:|--------:|-----:|----------:|----:|-------:|\n");
        for r in &self.reads {
            let open = Stats::of(&r.open);
            let read = Stats::of(&r.read);
            let held = Stats::of(&r.held);
            let access = access_name(r.access);
            s.push_str(&format!(
                "| {} | {} |{} {access} |",
                self.short(&r.model),
                r.format.name(),
                self.setting_cells(r.setting)
            ));
            if self.varies.threads {
                s.push_str(&format!(" {} |", r.threads));
            }
            if self.warm {
                s.push_str(if r.cold { " cold |" } else { " warm |" });
            }
            s.push_str(&format!(
                " {} | {:.2} | {:.2} | {} | {:.1} MB | {:.1} MB | ±{:.0}% |\n",
                r.n_read,
                open.median,
                read.median,
                throughput(r.delivered_bytes, open.median + read.median),
                r.delivered_bytes as f64 / 1e6,
                held.median / 1e6,
                read.spread_pct(),
            ));
        }
        s
    }

    /// The same numbers without the rounding, every dimension named, for the
    /// HTML report or for diffing two runs.
    pub fn json(&self) -> String {
        let mut s = String::from("{\n");
        s.push_str(&format!("  \"spin_iters_per_us\": {:.3},\n", self.spin_iters_per_us));
        s.push_str(&format!("  \"filesystem\": {},\n", quote(&crate::bench::filesystem(&self.out))));
        s.push_str(&format!("  \"hdf5\": {},\n", quote(&openmodelica_hdf5_result::h5::version())));
        s.push_str(&format!("  \"hdf5_concurrency\": {},\n", quote(hdf5_concurrency())));
        s.push_str(&format!("  \"arrow\": {},\n", quote(ARROW_VERSION)));
        s.push_str(&format!("  \"reps\": {},\n", self.reps));
        s.push_str(&format!("  \"handoff\": {},\n", self.handoff));
        s.push_str(&format!("  \"queue\": {},\n", self.queue));
        s.push_str("  \"datasets\": [\n");
        for (i, d) in self.datasets.iter().enumerate() {
            s.push_str(&format!(
                "    {{\"model\": {}, \"short\": {}, \"variables\": {}, \"columns\": {}, \"aliases\": {}, \"parameters\": {}, \"rows\": {}, \"payload_bytes\": {}}}{}\n",
                quote(&d.name), quote(&d.short), d.n_vars, d.n_cols, d.n_aliases, d.n_params, d.n_rows, d.payload_bytes,
                comma(i, self.datasets.len())
            ));
        }
        s.push_str("  ],\n  \"structure\": [\n");
        for (i, (model, t)) in self.structures.iter().enumerate() {
            s.push_str(&format!(
                "    {{\"model\": {}, \"format\": {}, {}, \"objects\": {}, \"blocks\": {}}}{}\n",
                quote(&self.short(model)), quote(t.format.name()), setting_json(t.setting), t.objects, t.blocks,
                comma(i, self.structures.len())
            ));
        }
        s.push_str("  ],\n  \"writes\": [\n");
        for (i, r) in self.writes.iter().enumerate() {
            s.push_str(&format!(
                "    {{\"model\": {}, \"format\": {}, {}, \"writer\": {}, \"delay_ns\": {}, \"rows\": {}, \"file_bytes\": {}, \"payload_bytes\": {}, \"open_ms\": {}, \"emit_ms\": {}, \"stall_ms\": {}, \"close_ms\": {}, \"fsync_ms\": {}, \"sys_ms\": {}, \"baseline_ms\": {}}}{}\n",
                quote(&self.short(&r.model)), quote(r.format.name()), setting_json(r.setting), quote(r.mode.name()),
                r.delay_ns, r.n_rows, r.file_bytes, r.payload_bytes,
                array(&r.begin), array(&r.emit), array(&r.stall), array(&r.finish),
                array(&r.fsync), array(&r.sys), array(&r.baseline),
                comma(i, self.writes.len())
            ));
        }
        s.push_str("  ],\n  \"reads\": [\n");
        for (i, r) in self.reads.iter().enumerate() {
            s.push_str(&format!(
                "    {{\"model\": {}, \"format\": {}, {}, \"access\": {}, \"threads\": {}, \"cache\": {}, \"variables\": {}, \"delivered_bytes\": {}, \"file_bytes\": {}, \"open_ms\": {}, \"read_ms\": {}, \"held_bytes\": {}}}{}\n",
                quote(&self.short(&r.model)), quote(r.format.name()), setting_json(r.setting),
                quote(access_name(r.access)), r.threads,
                quote(if r.cold { "cold" } else { "warm" }),
                r.n_read, r.delivered_bytes, r.file_bytes, array(&r.open), array(&r.read), array(&r.held),
                comma(i, self.reads.len())
            ));
        }
        s.push_str("  ],\n  \"checks\": [\n");
        for (i, (model, c)) in self.checks.iter().enumerate() {
            s.push_str(&format!(
                "    {{\"model\": {}, \"format\": {}, {}, \"trajectories\": {}, \"parameters\": {}, \"mismatches\": {}, \"max_rel_error\": {:.3e}}}{}\n",
                quote(&self.short(model)), quote(c.format.name()), setting_json(c.setting), c.variables, c.parameters,
                c.mismatches, c.max_rel_error,
                comma(i, self.checks.len())
            ));
        }
        s.push_str("  ]\n}\n");
        s
    }
}

fn access_name(a: Access) -> &'static str {
    match a {
        Access::PerVar => "per var",
        Access::Bulk => "bulk",
        Access::List => "list",
    }
}

fn setting_json(s: Setting) -> String {
    format!(
        "\"gzip\": {}, \"block_rows\": {}, \"chunk_cols\": {}",
        quote(&s.compression.label()),
        s.block_rows,
        s.chunk_cols
    )
}

/// The arrow-rs major version the writers are pinned to; there is no runtime
/// constant for it.
const ARROW_VERSION: &str = "59";

/// What the HDF5 this was linked against does about concurrency. Both answers
/// matter to the `threads` column: without thread safety a second thread is
/// undefined behaviour, and with it every call still goes through one global
/// lock, so more readers cannot make the library itself go faster.
fn hdf5_concurrency() -> &'static str {
    if openmodelica_hdf5_result::h5::is_threadsafe() {
        "thread-safe, one global lock"
    } else {
        "not thread-safe"
    }
}

fn rustc_version() -> String {
    std::process::Command::new(std::env::var("RUSTC").unwrap_or_else(|_| "rustc".into()))
        .arg("--version")
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map_or_else(|| "rustc unknown".into(), |s| s.trim().to_owned())
}

fn proc_field(path: &str, key: &str) -> Option<String> {
    let text = std::fs::read_to_string(path).ok()?;
    let line = text.lines().find(|l| l.starts_with(key))?;
    Some(line.split_once(':')?.1.trim().to_owned())
}

/// MB/s, or `-` when the measured interval is too short to divide by.
fn throughput(bytes: u64, ms: f64) -> String {
    if ms < 1e-3 || bytes == 0 {
        return "-".to_owned();
    }
    format!("{:.0}", bytes as f64 / 1e6 / (ms / 1e3))
}

fn comma(i: usize, n: usize) -> &'static str {
    if i + 1 == n { "" } else { "," }
}

fn quote(s: &str) -> String {
    format!("\"{}\"", s.replace('\\', "\\\\").replace('"', "\\\""))
}

fn array(v: &[f64]) -> String {
    let items: Vec<String> = v.iter().map(|x| format!("{x:.4}")).collect();
    format!("[{}]", items.join(", "))
}

fn duration(ns: u64) -> String {
    match ns {
        0 => "0".to_owned(),
        n if n % 1_000_000 == 0 => format!("{}ms", n / 1_000_000),
        n if n % 1_000 == 0 => format!("{}us", n / 1_000),
        n => format!("{n}ns"),
    }
}
