//! C's `+profiling` output: the per-step `_prof.intdata` / `_prof.realdata`
//! (`fmtInit` / `fmtEmitStep` in `perform_simulation.c.inc`) and the report
//! `modelinfo.c` writes at the end — `_prof.xml`, `_prof.plt`, `_prof.json` — with
//! `gnuplot` and `xsltproc` run over them for `blocks+html`.
//!
//! The function and block clocks live in the runtime module (`prof.rs`), where the
//! instrumented code runs; the driver's own clocks are [`rtclock`]. The five files
//! go out through [`crate::files`], so an in-wasm driver reports as the host does.

use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec;
use alloc::vec::Vec;
use core::sync::atomic::{AtomicBool, AtomicUsize, Ordering};

use crate::driver::{format_g, SimEngine};
use crate::{files, omclog, rtclock, ProfInfo, SimMeta};

/// Bytes per clock in the runtime's `rt_prof_dump` record.
const DUMP_RECORD: usize = 40;

/// One clock's run totals, as `rt_prof_dump` hands them over.
#[derive(Clone, Copy, Default)]
struct Totals {
    total: f64,
    max: f64,
    ncall_total: u32,
    ncall_min: u32,
    ncall_max: u32,
}

struct Profiler {
    level: u8,
    n: usize,
    /// C's `MEASURE_TIME` streams, buffered: the report transposes them at the
    /// end, which needs the whole trace anyway, and a buffer is the one thing
    /// every target has (a `FILE*` is not).
    real: Vec<u8>,
    int: Vec<u8>,
    step: u32,
    /// `-outputPath` with its trailing separator, or empty.
    out: String,
    prefix: String,
    totals: Vec<Totals>,
}

#[cfg(feature = "std")]
mod state {
    use super::Profiler;
    use core::cell::RefCell;
    std::thread_local! {
        static PROF: RefCell<Option<Profiler>> = const { RefCell::new(None) };
    }
    pub fn with<R>(f: impl FnOnce(&mut Option<Profiler>) -> R) -> R {
        PROF.with(|c| f(&mut c.borrow_mut()))
    }
}

#[cfg(not(feature = "std"))]
mod state {
    use super::Profiler;
    use core::cell::UnsafeCell;
    // The in-wasm runtime is single-threaded, so a plain cell is sound.
    struct Store(UnsafeCell<Option<Profiler>>);
    unsafe impl Sync for Store {}
    static PROF: Store = Store(UnsafeCell::new(None));
    pub fn with<R>(f: impl FnOnce(&mut Option<Profiler>) -> R) -> R {
        f(unsafe { &mut *PROF.0.get() })
    }
}

static WALL_CLOCK: AtomicUsize = AtomicUsize::new(0);
static HOME: AtomicUsize = AtomicUsize::new(0);
static PLOTS_ON_HOST: AtomicBool = AtomicBool::new(false);

/// Install the wall clock C's `time(NULL)` reads for the report's `<date>`. Needed
/// wherever `std::time::SystemTime::now()` is not available: it panics in the web
/// omc, and the in-wasm runtime has no clock of its own at all.
pub fn set_wall_clock(f: fn() -> i64) {
    WALL_CLOCK.store(f as usize, Ordering::Relaxed);
}

/// Install the lookup for C's `simulationInfo->OPENMODELICAHOME`, which the report
/// needs to find `default_profiling.xsl`. omc knows its own installation root even
/// where the environment does not (the web build has no environment at all).
pub fn set_home(f: fn() -> Option<String>) {
    HOME.store(f as usize, Ordering::Relaxed);
}

/// The embedder runs `gnuplot` and `xsltproc` over the files it is handed, so this
/// run only writes them. For an artifact's in-wasm driver, which cannot spawn a
/// process and would otherwise report C's failure messages for something its
/// caller does on its behalf.
pub fn set_plots_on_host(v: bool) {
    PLOTS_ON_HOST.store(v, Ordering::Relaxed);
}

/// C's `fmtInit`, at the start of a run whose model was translated with
/// `+profiling`: open the step traces and start the step clock.
pub fn start(e: &mut dyn SimEngine, model: &SimMeta) {
    let Some(p) = &model.prof else {
        state::with(|c| *c = None);
        return;
    };
    let out = crate::simflags::with_flags(|f| f.output_path.clone()).map(|d| format!("{d}/")).unwrap_or_default();
    let n = p.functions.len() + p.blocks.len();
    // C's `rt_init` sizes every clock before the first tick; the model's own ticks
    // land in the runtime module, so the engine arms them there.
    e.prof_init(n as u32);
    rtclock::tick(rtclock::STEP);
    state::with(|c| {
        *c = Some(Profiler {
            level: p.level,
            n,
            real: Vec::new(),
            int: Vec::new(),
            step: 0,
            out,
            prefix: model.prefix.clone(),
            totals: vec![Totals::default(); n],
        })
    });
}

/// C's `fmtEmitStep` then `clear_rt_step`, once per emitted row.
pub fn on_row(e: &mut dyn SimEngine, time: f64) {
    state::with(|c| {
        if let Some(p) = c.as_mut() {
            p.emit_step(e, time);
            p.clear_step(e);
        }
    });
}

/// This run's collected state, for a driver that ran somewhere else: the in-wasm
/// session hands it over so the *host* renders the report, once the result file it
/// reports on — and its size — exists. Empty when the run was not profiled.
pub fn snapshot() -> Vec<u8> {
    state::with(|c| {
        let Some(p) = c.as_ref() else { return Vec::new() };
        let mut o = Vec::new();
        o.extend_from_slice(&p.step.to_le_bytes());
        o.extend_from_slice(&(p.totals.len() as u32).to_le_bytes());
        for t in &p.totals {
            o.extend_from_slice(&t.total.to_le_bytes());
            o.extend_from_slice(&t.max.to_le_bytes());
            o.extend_from_slice(&t.ncall_total.to_le_bytes());
            o.extend_from_slice(&t.ncall_min.to_le_bytes());
            o.extend_from_slice(&t.ncall_max.to_le_bytes());
        }
        for b in [&p.real, &p.int, &rtclock::pack()] {
            o.extend_from_slice(&(b.len() as u32).to_le_bytes());
            o.extend_from_slice(b);
        }
        o
    })
}

/// Adopt a [`snapshot`] taken by another driver: everything else about the run is
/// in `model`, as [`start`] reads it.
pub fn adopt(model: &SimMeta, bytes: &[u8]) {
    let Some(p) = &model.prof else { return };
    if bytes.len() < 8 {
        return;
    }
    let u32_at = |o: usize| u32::from_le_bytes(bytes[o..o + 4].try_into().unwrap());
    let f64_at = |o: usize| f64::from_le_bytes(bytes[o..o + 8].try_into().unwrap());
    let step = u32_at(0);
    let n = u32_at(4) as usize;
    let mut o = 8;
    if bytes.len() < o + n * 28 {
        return;
    }
    let mut totals = Vec::with_capacity(n);
    for _ in 0..n {
        totals.push(Totals {
            total: f64_at(o),
            max: f64_at(o + 8),
            ncall_total: u32_at(o + 16),
            ncall_min: u32_at(o + 20),
            ncall_max: u32_at(o + 24),
        });
        o += 28;
    }
    let take = |o: &mut usize| -> Vec<u8> {
        if bytes.len() < *o + 4 {
            return Vec::new();
        }
        let n = u32_at(*o) as usize;
        *o += 4;
        let end = (*o + n).min(bytes.len());
        let v = bytes[*o..end].to_vec();
        *o = end;
        v
    };
    let real = take(&mut o);
    let int = take(&mut o);
    // The driver's own clocks ran wherever the driver did; the report reads them
    // from this side's `rtclock`.
    rtclock::unpack(&take(&mut o));
    let out = crate::simflags::with_flags(|f| f.output_path.clone()).map(|d| format!("{d}/")).unwrap_or_default();
    state::with(|c| {
        *c = Some(Profiler {
            level: p.level,
            n: p.functions.len() + p.blocks.len(),
            real,
            int,
            step,
            out,
            prefix: model.prefix.clone(),
            totals,
        })
    });
}

/// The clocks' run totals, read while the engine is still up.
pub fn end_of_run(e: &mut dyn SimEngine) {
    state::with(|c| {
        if let Some(p) = c.as_mut() {
            p.totals = read_totals(e, p.n);
        }
    });
}

/// C's `printModelInfo` and `printModelInfoJSON`, after the result file is
/// written. `result_size` is that file's size, which C reads back with `fileSize`.
pub fn finish(model: &SimMeta, result_file: &str, result_size: i64) {
    let Some(p) = state::with(|c| c.take()) else { return };
    let Some(info) = &model.prof else { return };
    write_traces(&p);
    print_model_info(&p, info, model, result_file, result_size);
    print_model_info_json(&p, info, model, result_file, result_size);
}

/// C's `fmtEmitStep` writes a record per step and `fmtClose` closes the streams;
/// the buffered run goes out in one piece here — before `gnuplot` reads it, and
/// still in the record-per-step layout its bindings expect.
fn write_traces(p: &Profiler) {
    for (suffix, bytes) in [("_prof.realdata", &p.real), ("_prof.intdata", &p.int)] {
        let name = format!("{}{}{suffix}", p.out, p.prefix);
        if !files::write(&name, bytes) {
            omclog::warning(omclog::STDOUT, false, &format!("Time measurements output file {name} could not be opened"));
        }
    }
}

fn read_totals(e: &mut dyn SimEngine, n: usize) -> Vec<Totals> {
    let ptr = e.prof_dump();
    let mut buf = vec![0u8; n * DUMP_RECORD];
    if ptr == 0 || e.read_bytes(ptr, &mut buf).is_err() {
        return vec![Totals::default(); n];
    }
    let f64_at = |o: usize| f64::from_le_bytes(buf[o..o + 8].try_into().unwrap());
    let u32_at = |o: usize| u32::from_le_bytes(buf[o..o + 4].try_into().unwrap());
    (0..n)
        .map(|i| {
            let o = i * DUMP_RECORD;
            Totals {
                total: f64_at(o),
                max: f64_at(o + 8),
                ncall_total: u32_at(o + 24),
                ncall_min: u32_at(o + 28),
                ncall_max: u32_at(o + 32),
            }
        })
        .collect()
}

impl Profiler {
    fn emit_step(&mut self, e: &mut dyn SimEngine, time: f64) {
        rtclock::accumulate(rtclock::STEP);
        rtclock::tick(rtclock::OVERHEAD);
        let n = self.n;
        let mut row = vec![0u8; n * 12];
        let ptr = e.prof_row();
        if ptr != 0 && e.read_bytes(ptr, &mut row).is_ok() {
            self.int.extend_from_slice(&self.step.to_le_bytes());
            self.step += 1;
            self.real.extend_from_slice(&time.to_le_bytes());
            self.real.extend_from_slice(&rtclock::accumulated(rtclock::STEP).to_le_bytes());
            // `rt_prof_row`'s record: the call counts, then the seconds.
            self.int.extend_from_slice(&row[..4 * n]);
            self.real.extend_from_slice(&row[4 * n..]);
        }
        rtclock::accumulate(rtclock::OVERHEAD);
    }

    /// C's `clear_rt_step`.
    fn clear_step(&mut self, e: &mut dyn SimEngine) {
        e.prof_clear();
        rtclock::clear(rtclock::STEP);
        rtclock::tick(rtclock::STEP);
    }
}

fn xml_escape(s: &str) -> String {
    let mut o = String::with_capacity(s.len());
    for c in s.chars() {
        match c {
            '<' => o.push_str("&lt;"),
            '>' => o.push_str("&gt;"),
            '\'' => o.push_str("&apos;"),
            '"' => o.push_str("&quot;"),
            c => o.push(c),
        }
    }
    o
}

fn json_escape(s: &str) -> String {
    let mut o = String::with_capacity(s.len());
    for c in s.chars() {
        match c {
            '"' => o.push_str("\\\""),
            '\\' => o.push_str("\\\\"),
            '\n' => o.push_str("\\n"),
            '\u{8}' => o.push_str("\\b"),
            '\u{c}' => o.push_str("\\f"),
            '\r' => o.push_str("\\r"),
            '\t' => o.push_str("\\t"),
            c if (c as u32) < 0x20 => o.push_str(&format!("\\u{:04x}", c as u32)),
            c => o.push(c),
        }
    }
    o
}

/// C's `time(NULL)`: seconds since the Unix epoch, from the installed
/// [`set_wall_clock`] or, natively, the std wall clock.
fn epoch_secs() -> i64 {
    let p = WALL_CLOCK.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn() -> i64 = unsafe { core::mem::transmute(p) };
        return f();
    }
    // `SystemTime::now()` panics in the web build (wasm32 without WASI); every
    // other `std` target, wasip1 included, has a real wall clock.
    #[cfg(all(feature = "std", any(not(target_arch = "wasm32"), target_os = "wasi")))]
    return std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0);
    #[cfg(not(all(feature = "std", any(not(target_arch = "wasm32"), target_os = "wasi"))))]
    0
}

/// C's `strftime("%Y-%m-%d %H:%M:%S")` of `localtime(time(NULL))`; UTC here,
/// there being no tz database in wasm.
fn date_string() -> String {
    let secs = epoch_secs();
    let days = secs.div_euclid(86400);
    let rem = secs.rem_euclid(86400);
    // Howard Hinnant's civil-from-days.
    let z = days + 719468;
    let era = z.div_euclid(146097);
    let doe = z.rem_euclid(146097);
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if m <= 2 { y + 1 } else { y };
    format!("{y:04}-{m:02}-{d:02} {:02}:{:02}:{:02}", rem / 3600, (rem / 60) % 60, rem % 60)
}

fn info_tag(out: &mut String, level: usize, info: &crate::SrcInfo) {
    out.push_str(&" ".repeat(level));
    out.push_str(&format!(
        "<info filename=\"{}\" startline=\"{}\" startcol=\"{}\" endline=\"{}\" endcol=\"{}\" readonly=\"{}\" />\n",
        xml_escape(&info.file),
        info.line_start,
        info.col_start,
        info.line_end,
        info.col_end,
        if info.read_only { "readonly" } else { "writable" }
    ));
}

/// C's `printPlotCommand`: the gnuplot script for one clock (`i < 0`: the step
/// clock) — an SVG thumbnail, then the full plot, each with a call-count twin.
fn plot_command(
    plt: &mut String,
    p: &Profiler,
    plot_format: &str,
    title: &str,
    n_all: usize,
    i: isize,
    id: u32,
    id_prefix: &str,
) {
    let (out, prefix) = (&p.out, &p.prefix);
    let time_plot = |lw: u32| {
        format!(
            "plot \"{out}{prefix}_prof.realdata\" binary format=\"%{}double\" using 1:(${}>1e-9 ? ${} : 1e-30) w l lw {lw}\n",
            2 + n_all,
            3 + i,
            3 + i
        )
    };
    let count_plot =
        |lw: u32| format!("plot \"{out}{prefix}_prof.intdata\" binary format=\"%{}uint32\" using {} w l lw {lw}\n", 1 + n_all, 2 + i);
    let (mut nmin, mut nmax) = (0u32, 0u32);
    let (mut ymin, mut ymax) = (0.0f64, 0.0f64);
    let mut ygraphmax = 0.0f64;
    if i >= 0 {
        let t = p.totals[i as usize];
        nmin = t.ncall_min;
        nmax = t.ncall_max;
        ymin = if nmin == 0 { -0.01 } else { nmin as f64 * 0.95 };
        ymax = if nmax == 0 { 0.01 } else { nmax as f64 * 1.05 };
        ygraphmax = t.max * 1.01 + 1e-30;
    }
    let yrange = |plt: &mut String| {
        if i >= 0 {
            plt.push_str(&format!("set yrange [*:{}]\n", format_g(ygraphmax, 6)));
        } else {
            plt.push_str("set yrange [*:*]\n");
        }
    };
    let count_range = |plt: &mut String| {
        if nmin == nmax {
            plt.push_str(&format!("set yrange [{}:{}]\n", format_g(ymin, 6), format_g(ymax, 6)));
        } else {
            plt.push_str("set yrange [*:*]\n");
        }
    };
    plt.push_str("set terminal svg\n");
    plt.push_str("unset xtics\n");
    plt.push_str("unset ytics\n");
    plt.push_str("unset border\n");
    plt.push_str(&format!("set output \"{out}{prefix}_prof.{id_prefix}{id}.thumb.svg\"\n"));
    plt.push_str("set title\n");
    plt.push_str("set xlabel\n");
    plt.push_str("set ylabel\n");
    plt.push_str("set log y\n");
    yrange(plt);
    plt.push_str(&time_plot(4));
    plt.push_str("set nolog xy\n");
    if i >= 0 {
        plt.push_str("unset ytics\n");
        count_range(plt);
        plt.push_str(&format!("set output \"{out}{prefix}_prof.{id_prefix}{id}_count.thumb.svg\"\n"));
        plt.push_str(&count_plot(4));
        plt.push_str("set ytics\n");
    }
    plt.push_str("set xtics\n");
    plt.push_str("set ytics\n");
    plt.push_str("set border\n");
    plt.push_str(&format!("set terminal {plot_format}\n"));
    plt.push_str(&format!("set title \"{title}\"\n"));
    plt.push_str("set xlabel \"Global step at time\"\n");
    plt.push_str("set ylabel \"Execution time [s]\"\n");
    plt.push_str(&format!("set output \"{out}{prefix}_prof.{id_prefix}{id}.{plot_format}\"\n"));
    plt.push_str("set log y\n");
    yrange(plt);
    plt.push_str(&time_plot(2));
    plt.push_str("set nolog xy\n");
    if i >= 0 {
        count_range(plt);
        plt.push_str("set xlabel \"Global step number\"\n");
        plt.push_str("set ylabel \"Execution count\"\n");
        plt.push_str(&format!("set output \"{out}{prefix}_prof.{id_prefix}{id}_count.{plot_format}\"\n"));
        plt.push_str(&count_plot(2));
    }
}

fn print_model_info(p: &Profiler, info: &ProfInfo, model: &SimMeta, result_file: &str, result_size: i64) {
    let (out, prefix) = (&p.out, &p.prefix);
    let plot_format = crate::simflags::with_flags(|f| f.measure_time_plot_format.clone()).unwrap_or_else(|| "svg".to_string());
    let n_fn = info.functions.len();
    let n_all = n_fn + info.blocks.len();
    let mut x = String::new();
    let mut plt = String::new();
    plt.push_str("set terminal svg\n");
    plt.push_str("set nokey\n");
    plt.push_str("set format y \"%g\"\n");
    plot_command(&mut plt, p, &plot_format, "Execution time of global steps", n_all, -1, 999, "");
    x.push_str(
        "<!DOCTYPE doc [  <!ELEMENT simulation (modelinfo, variables, functions, equations)>  \
         <!ATTLIST variable id ID #REQUIRED>  <!ELEMENT equation (refs)>  <!ATTLIST equation id ID #REQUIRED>  \
         <!ELEMENT profileblocks (profileblock*)>  <!ELEMENT profileblock (refs, ncall, time, maxTime)>  \
         <!ELEMENT refs (ref*)>  <!ATTLIST ref refid IDREF #REQUIRED>  ]>\n",
    );
    let f6 = |v: f64| format!("{v:.6}");
    let f9 = |v: f64| format!("{v:.9}");
    x.push_str("<simulation>\n<modelinfo>\n");
    x.push_str(&format!("  <name>{}</name>\n", xml_escape(&model.model_name)));
    x.push_str(&format!("  <prefix>{}</prefix>\n", xml_escape(prefix)));
    x.push_str(&format!("  <date>{}</date>\n", xml_escape(&date_string())));
    x.push_str(&format!("  <method>{}</method>\n", xml_escape(&model.method)));
    x.push_str(&format!("  <outputFormat>{}</outputFormat>\n", xml_escape(&model.output_format)));
    x.push_str(&format!("  <outputFilename>{}</outputFilename>\n", xml_escape(result_file)));
    x.push_str(&format!("  <outputFilesize>{result_size}</outputFilesize>\n"));
    x.push_str(&format!("  <overheadTime>{}</overheadTime>\n", f6(rtclock::accumulated(rtclock::OVERHEAD))));
    x.push_str(&format!("  <preinitTime>{}</preinitTime>\n", f6(rtclock::accumulated(rtclock::PREINIT))));
    x.push_str(&format!("  <initTime>{}</initTime>\n", f6(rtclock::accumulated(rtclock::INIT))));
    x.push_str(&format!("  <eventTime>{}</eventTime>\n", f6(rtclock::accumulated(rtclock::EVENT))));
    x.push_str(&format!("  <outputTime>{}</outputTime>\n", f6(rtclock::accumulated(rtclock::OUTPUT))));
    x.push_str(&format!("  <jacobianTime>{}</jacobianTime>\n", f6(rtclock::accumulated(rtclock::JACOBIAN))));
    x.push_str(&format!("  <totalTime>{}</totalTime>\n", f6(rtclock::accumulated(rtclock::TOTAL))));
    x.push_str(&format!("  <totalStepsTime>{}</totalStepsTime>\n", f6(rtclock::total(rtclock::STEP))));
    x.push_str(&format!("  <numStep>{}</numStep>\n", rtclock::ncall_total(rtclock::STEP)));
    x.push_str(&format!("  <maxTime>{}</maxTime>\n", f9(rtclock::max_accumulated(rtclock::STEP))));
    x.push_str("</modelinfo>\n<modelinfo_ext>\n");
    x.push_str(&format!("  <odeTime>{}</odeTime>\n", f6(rtclock::accumulated(rtclock::FUNCTION_ODE))));
    x.push_str(&format!("  <odeTimeTicks>{}</odeTimeTicks>\n", rtclock::ncall(rtclock::FUNCTION_ODE)));
    x.push_str("</modelinfo_ext>\n<profilingdataheader>\n");
    // C reports on a `_prof.data` no runtime has written for a long time, so its
    // `fileSize` is the missing-file `-1`.
    x.push_str(&format!("  <filename>{}_prof.data</filename>\n", xml_escape(prefix)));
    x.push_str("  <filesize>-1</filesize>\n");
    x.push_str("  <format>\n    <uint32>step</uint32>\n    <double>time</double>\n    <double>cpu time</double>\n");
    for f in &info.functions {
        x.push_str(&format!("    <uint32>{} (calls)</uint32>\n", xml_escape(&f.name)));
    }
    for id in &info.blocks {
        x.push_str(&format!("    <uint32>Equation {id} (calls)</uint32>\n"));
    }
    for f in &info.functions {
        x.push_str(&format!("    <double>{} (cpu time)</double>\n", xml_escape(&f.name)));
    }
    for id in &info.blocks {
        x.push_str(&format!("    <double>Equation {id} (cpu time)</double>\n"));
    }
    x.push_str("  </format>\n</profilingdataheader>\n<variables>\n");
    for v in &info.vars {
        x.push_str(&format!("  <variable id=\"var{}\" name=\"{}\" comment=\"{}\">\n", v.id, xml_escape(&v.name), xml_escape(&v.comment)));
        info_tag(&mut x, 4, &v.info);
        x.push_str("  </variable>\n");
    }
    x.push_str("</variables>\n<functions>\n");
    for (i, f) in info.functions.iter().enumerate() {
        plot_command(&mut plt, p, &plot_format, &f.name, n_all, i as isize, i as u32, "fun");
        let t = p.totals[i];
        x.push_str(&format!("  <function id=\"fun{i}\">\n"));
        x.push_str(&format!("    <name>{}</name>\n", xml_escape(&f.name)));
        x.push_str(&format!("    <ncall>{}</ncall>\n", t.ncall_total));
        x.push_str(&format!("    <time>{}</time>\n", f9(t.total)));
        x.push_str(&format!("    <maxTime>{}</maxTime>\n", f9(t.max)));
        info_tag(&mut x, 6, &f.info);
        x.push_str("  </function>\n");
    }
    x.push_str("</functions>\n<equations>\n");
    let var_id = |name: &str| info.vars.iter().find(|v| v.name == name).map_or(0, |v| v.id);
    for eq in &info.equations {
        x.push_str(&format!("  <equation id=\"eq{}\">\n    <refs>\n", eq.id));
        for d in &eq.defines {
            x.push_str(&format!("      <ref refid=\"var{}\" />\n", var_id(d)));
        }
        x.push_str("    </refs>\n");
        x.push_str("    <calcinfo time=\"0.000000\" count=\"0\"/>\n");
        x.push_str("  </equation>\n");
    }
    x.push_str("</equations>\n<profileblocks>\n");
    for (k, id) in info.blocks.iter().enumerate() {
        let i = n_fn + k;
        plot_command(&mut plt, p, &plot_format, "equation", n_all, i as isize, *id, "eq");
        let t = p.totals[i];
        x.push_str("  <profileblock>\n");
        x.push_str(&format!("    <ref refid=\"eq{id}\"/>\n"));
        x.push_str(&format!("    <ncall>{}</ncall>\n", t.ncall_total));
        x.push_str(&format!("    <time>{}</time>\n", f9(t.total)));
        x.push_str(&format!("    <maxTime>{}</maxTime>\n", f9(t.max)));
        x.push_str("  </profileblock>\n");
    }
    x.push_str("</profileblocks>\n</simulation>\n");
    let xml_name = format!("{out}{prefix}_prof.xml");
    let plt_name = format!("{out}{prefix}_prof.plt");
    if !files::write(&xml_name, x.as_bytes()) {
        omclog::warning(omclog::STDOUT, false, &format!("Failed to open {xml_name}"));
        return;
    }
    if !files::write(&plt_name, plt.as_bytes()) {
        omclog::warning(omclog::DIVISION, false, "Plots of profiling data were disabled\n");
        return;
    }
    let html = p.level & 4 != 0;
    if !PLOTS_ON_HOST.load(Ordering::Relaxed) {
        if html {
            let cmd = format!("gnuplot {plt_name}");
            if !run_shell(&cmd) {
                omclog::warning(omclog::DIVISION, false, &format!("Plot command failed: {cmd}\n"));
            }
        }
        let (gen_html_failed, cmd) = match openmodelica_home() {
            Some(omhome) => {
                let cmd = format!(
                    "xsltproc -o {out}{prefix}_prof.html {omhome}/share/omc/scripts/default_profiling.xsl {out}{prefix}_prof.xml"
                );
                (html && !run_shell(&cmd), cmd)
            }
            None => (true, "OPENMODELICAHOME missing".to_string()),
        };
        if gen_html_failed {
            omclog::warning(omclog::STDOUT, false, &format!("Failed to generate html version of profiling results: {cmd}\n"));
        }
    }
    if html {
        omclog::info(
            omclog::STDOUT,
            false,
            &format!(
                "Time measurements are stored in {out}{prefix}_prof.html (human-readable) and {out}{prefix}_prof.xml (for XSL transforms or more details)"
            ),
        );
    } else {
        omclog::info(omclog::STDOUT, false, &format!("Time measurements are stored in {out}{prefix}_prof.json"));
    }
}

/// C's `system(cmd)` through `/bin/sh`; `true` on exit status 0. A wasm build
/// has no processes to run.
fn run_shell(cmd: &str) -> bool {
    #[cfg(all(feature = "std", not(target_arch = "wasm32")))]  // no processes in wasm
    {
        std::process::Command::new("sh").arg("-c").arg(cmd).status().map(|s| s.success()).unwrap_or(false)
    }
    #[cfg(not(all(feature = "std", not(target_arch = "wasm32"))))]
    {
        let _ = cmd;
        false
    }
}

/// C reads `OPENMODELICAHOME` out of `simulationInfo`; here it is [`set_home`]'s,
/// or the environment where nobody installed one.
fn openmodelica_home() -> Option<String> {
    let p = HOME.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn() -> Option<String> = unsafe { core::mem::transmute(p) };
        return f();
    }
    #[cfg(feature = "std")]
    return std::env::var("OPENMODELICAHOME").ok();
    #[cfg(not(feature = "std"))]
    None
}

/// C's `convertProfileData`: rewrite the step files from one record per step to
/// one series per column. C mmaps and transposes them in place, after `gnuplot`
/// has read the record-per-step layout its bindings name.
fn convert_profile_data(p: &Profiler) {
    let (out, prefix) = (&p.out, &p.prefix);
    for (suffix, bytes, elem, cols) in [
        ("_prof.intdata", &p.int, 4usize, 1 + p.n),
        ("_prof.realdata", &p.real, 8usize, 2 + p.n),
    ] {
        let row = elem * cols;
        if bytes.is_empty() || bytes.len() % row != 0 {
            continue;
        }
        let rows = bytes.len() / row;
        let mut t = vec![0u8; bytes.len()];
        for r in 0..rows {
            for c in 0..cols {
                let src = r * row + c * elem;
                let dst = (c * rows + r) * elem;
                t[dst..dst + elem].copy_from_slice(&bytes[src..src + elem]);
            }
        }
        files::write(&format!("{out}{prefix}{suffix}"), &t);
    }
}

fn print_model_info_json(p: &Profiler, info: &ProfInfo, model: &SimMeta, result_file: &str, result_size: i64) {
    let (out, prefix) = (&p.out, &p.prefix);
    convert_profile_data(p);
    let n_fn = info.functions.len();
    let g = |v: f64| format_g(v, 6);
    let mut j = String::new();
    // C sums the blocks whose equation has no parent -- which is every block: its
    // `readEquation` skips the `parent` field of `_info.json` and leaves the
    // `calloc`ed zero behind.
    // `fold` from `0.0`, not `sum()`: its identity is `-0.0`, and C prints `0`.
    let total_eqs = (0..info.blocks.len()).map(|k| p.totals[n_fn + k].total).fold(0.0, |a, b| a + b);
    j.push_str(&format!("{{\n\"name\":\"{}\"", json_escape(&model.model_name)));
    j.push_str(&format!(",\n\"prefix\":\"{}\"", json_escape(prefix)));
    j.push_str(&format!(",\n\"date\":\"{}\"", json_escape(&date_string())));
    j.push_str(&format!(",\n\"method\":\"{}\"", json_escape(&model.method)));
    j.push_str(&format!(",\n\"outputFormat\":\"{}\"", json_escape(&model.output_format)));
    j.push_str(&format!(",\n\"outputFilename\":\"{}\"", json_escape(result_file)));
    j.push_str(&format!(",\n\"outputFilesize\":{result_size}"));
    j.push_str(&format!(",\n\"overheadTime\":{}", g(rtclock::accumulated(rtclock::OVERHEAD))));
    j.push_str(&format!(",\n\"preinitTime\":{}", g(rtclock::accumulated(rtclock::PREINIT))));
    j.push_str(&format!(",\n\"initTime\":{}", g(rtclock::accumulated(rtclock::INIT))));
    j.push_str(&format!(",\n\"eventTime\":{}", g(rtclock::accumulated(rtclock::EVENT))));
    j.push_str(&format!(",\n\"outputTime\":{}", g(rtclock::accumulated(rtclock::OUTPUT))));
    j.push_str(&format!(",\n\"jacobianTime\":{}", g(rtclock::accumulated(rtclock::JACOBIAN))));
    j.push_str(&format!(",\n\"totalTime\":{}", g(rtclock::accumulated(rtclock::TOTAL))));
    j.push_str(&format!(",\n\"totalStepsTime\":{}", g(rtclock::accumulated(rtclock::STEP))));
    j.push_str(&format!(",\n\"totalTimeProfileBlocks\":{}", g(total_eqs)));
    j.push_str(&format!(",\n\"numStep\":{}", rtclock::ncall_total(rtclock::STEP)));
    j.push_str(&format!(",\n\"maxTime\":{}", format_g(rtclock::max_accumulated(rtclock::STEP), 9)));
    j.push_str(",\n\"functions\":[");
    for (i, f) in info.functions.iter().enumerate() {
        let t = p.totals[i];
        j.push_str(if i == 0 { "\n" } else { ",\n" });
        j.push_str(&format!(
            "{{\"name\":\"{}\",\"ncall\":{},\"time\":{:.9},\"maxTime\":{:.9}}}",
            json_escape(&f.name),
            t.ncall_total,
            t.total,
            t.max
        ));
    }
    j.push_str("\n],\n\"profileBlocks\":[");
    for (k, id) in info.blocks.iter().enumerate() {
        let t = p.totals[n_fn + k];
        j.push_str(if k == 0 { "\n" } else { ",\n" });
        j.push_str(&format!("{{\"id\":{id},\"ncall\":{},\"time\":{:.9},\"maxTime\":{:.9}}}", t.ncall_total, t.total, t.max));
    }
    j.push_str("\n]\n}");
    let name = format!("{out}{prefix}_prof.json");
    if !files::write(&name, j.as_bytes()) {
        omclog::warning(omclog::STDOUT, false, &format!("Failed to open file {name} for writing"));
    }
}
