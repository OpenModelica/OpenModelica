//! C's `+profiling` output: the per-step `_prof.intdata` / `_prof.realdata`
//! (`fmtInit` / `fmtEmitStep` in `perform_simulation.c.inc`) and the report
//! `modelinfo.c` writes at the end — `_prof.xml`, `_prof.plt`, `_prof.json` — with
//! `gnuplot` and `xsltproc` run over them for `blocks+html`.
//!
//! The function and block clocks live in the runtime module (`prof.rs`), where the
//! instrumented code runs; the driver's own clocks are [`rtclock`].

use std::cell::RefCell;
use std::fs::File;
use std::io::Write;

use crate::driver::{format_g, SimEngine};
use crate::{omclog, rtclock, ProfInfo, SimMeta};

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
    real: Option<File>,
    int: Option<File>,
    step: u32,
    /// `-outputPath` with its trailing separator, or empty.
    out: String,
    prefix: String,
    totals: Vec<Totals>,
}

thread_local! {
    static PROF: RefCell<Option<Profiler>> = const { RefCell::new(None) };
}

/// C's `fmtInit`, at the start of a run whose model was translated with
/// `+profiling`: open the step files and start the step clock.
pub fn start(model: &SimMeta) {
    let Some(p) = &model.prof else {
        PROF.with(|c| *c.borrow_mut() = None);
        return;
    };
    let out = crate::simflags::with_flags(|f| f.output_path.clone()).map(|d| format!("{d}/")).unwrap_or_default();
    let n = p.functions.len() + p.blocks.len();
    let open = |suffix: &str| -> Option<File> {
        let name = format!("{out}{}{suffix}", model.prefix);
        match File::create(&name) {
            Ok(f) => Some(f),
            Err(e) => {
                omclog::warning(
                    omclog::STDOUT,
                    false,
                    &format!("Time measurements output file {name} could not be opened: {e}"),
                );
                None
            }
        }
    };
    let real = open("_prof.realdata");
    let int = if real.is_some() { open("_prof.intdata") } else { None };
    let (real, int) = if int.is_none() { (None, None) } else { (real, int) };
    rtclock::tick(rtclock::STEP);
    PROF.with(|c| {
        *c.borrow_mut() = Some(Profiler {
            level: p.level,
            n,
            real,
            int,
            step: 0,
            out,
            prefix: model.prefix.clone(),
            totals: vec![Totals::default(); n],
        })
    });
}

/// C's `fmtEmitStep` then `clear_rt_step`, once per emitted row.
pub fn on_row(e: &mut dyn SimEngine, time: f64) {
    PROF.with(|c| {
        if let Some(p) = c.borrow_mut().as_mut() {
            p.emit_step(e, time);
            p.clear_step(e);
        }
    });
}

/// The clocks' run totals, read while the engine is still up.
pub fn end_of_run(e: &mut dyn SimEngine) {
    PROF.with(|c| {
        if let Some(p) = c.borrow_mut().as_mut() {
            p.totals = read_totals(e, p.n);
        }
    });
}

/// C's `printModelInfo` and `printModelInfoJSON`, after the result file is written.
pub fn finish(model: &SimMeta, result_file: &str) {
    let Some(mut p) = PROF.with(|c| c.borrow_mut().take()) else { return };
    let Some(info) = &model.prof else { return };
    p.real = None;
    p.int = None;
    print_model_info(&p, info, model, result_file);
    print_model_info_json(&p, info, model, result_file);
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
        let (Some(real), Some(int)) = (self.real.as_mut(), self.int.as_mut()) else { return };
        rtclock::accumulate(rtclock::STEP);
        rtclock::tick(rtclock::OVERHEAD);
        let n = self.n;
        let mut row = vec![0u8; n * 12];
        let ptr = e.prof_row();
        let ok = ptr != 0 && e.read_bytes(ptr, &mut row).is_ok();
        let mut ok = ok && int.write_all(&self.step.to_le_bytes()).is_ok();
        self.step += 1;
        ok = ok && real.write_all(&time.to_le_bytes()).is_ok();
        ok = ok && real.write_all(&rtclock::accumulated(rtclock::STEP).to_le_bytes()).is_ok();
        ok = ok && int.write_all(&row[..4 * n]).is_ok();
        ok = ok && real.write_all(&row[4 * n..]).is_ok();
        rtclock::accumulate(rtclock::OVERHEAD);
        if !ok {
            omclog::warning(
                omclog::SOLVER,
                false,
                "Disabled time measurements because the output file could not be generated",
            );
            self.real = None;
            self.int = None;
        }
    }

    /// C's `clear_rt_step`.
    fn clear_step(&mut self, e: &mut dyn SimEngine) {
        let _ = e.call1_if_present_raw("rt_prof_clear", 0);
        rtclock::clear(rtclock::STEP);
        rtclock::tick(rtclock::STEP);
    }
}

fn file_size(name: &str) -> i64 {
    std::fs::metadata(name).map(|m| m.len() as i64).unwrap_or(-1)
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

/// C's `strftime("%Y-%m-%d %H:%M:%S")` of `localtime(time(NULL))`; UTC here,
/// there being no tz database in wasm.
fn date_string() -> String {
    let secs = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0);
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

fn print_model_info(p: &Profiler, info: &ProfInfo, model: &SimMeta, result_file: &str) {
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
    x.push_str(&format!("  <outputFilesize>{}</outputFilesize>\n", file_size(result_file)));
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
    let data_name = format!("{prefix}_prof.data");
    x.push_str(&format!("  <filename>{}</filename>\n", xml_escape(&data_name)));
    x.push_str(&format!("  <filesize>{}</filesize>\n", file_size(&data_name)));
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
    if let Err(e) = std::fs::write(&xml_name, x) {
        omclog::warning(omclog::STDOUT, false, &format!("Failed to open {xml_name}: {e}"));
        return;
    }
    if let Err(e) = std::fs::write(&plt_name, plt) {
        omclog::warning(omclog::DIVISION, false, &format!("Plots of profiling data were disabled: {e}\n"));
        return;
    }
    let html = p.level & 4 != 0;
    if html {
        let cmd = format!("gnuplot {plt_name}");
        if !run_shell(&cmd) {
            omclog::warning(omclog::DIVISION, false, &format!("Plot command failed: {cmd}\n"));
        }
    }
    let (gen_html_failed, cmd) = match std::env::var("OPENMODELICAHOME") {
        Ok(omhome) => {
            let cmd = format!(
                "xsltproc -o {out}{prefix}_prof.html {omhome}/share/omc/scripts/default_profiling.xsl {out}{prefix}_prof.xml"
            );
            (html && !run_shell(&cmd), cmd)
        }
        Err(_) => (true, "OPENMODELICAHOME missing".to_string()),
    };
    if gen_html_failed {
        omclog::warning(omclog::STDOUT, false, &format!("Failed to generate html version of profiling results: {cmd}\n"));
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
    #[cfg(not(target_arch = "wasm32"))]
    {
        std::process::Command::new("sh").arg("-c").arg(cmd).status().map(|s| s.success()).unwrap_or(false)
    }
    #[cfg(target_arch = "wasm32")]
    {
        let _ = cmd;
        false
    }
}

/// C's `convertProfileData`: transpose the step files in place from one record
/// per step to one series per column.
fn convert_profile_data(p: &Profiler) {
    let n_all = p.n;
    let (out, prefix) = (&p.out, &p.prefix);
    fn transpose(path: &str, elem: usize, cols: usize) {
        let Ok(bytes) = std::fs::read(path) else { return };
        let row = elem * cols;
        if row == 0 || bytes.len() % row != 0 {
            return;
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
        let _ = std::fs::write(path, t);
    }
    transpose(&format!("{out}{prefix}_prof.intdata"), 4, 1 + n_all);
    transpose(&format!("{out}{prefix}_prof.realdata"), 8, 2 + n_all);
}

fn print_model_info_json(p: &Profiler, info: &ProfInfo, model: &SimMeta, result_file: &str) {
    let (out, prefix) = (&p.out, &p.prefix);
    convert_profile_data(p);
    let n_fn = info.functions.len();
    let g = |v: f64| format_g(v, 6);
    let mut j = String::new();
    // C sums the top-level blocks only; the equation table has no parents here, so
    // every block counts.
    let total_eqs: f64 = (0..info.blocks.len()).map(|k| p.totals[n_fn + k].total).sum();
    j.push_str(&format!("{{\n\"name\":\"{}\"", json_escape(&model.model_name)));
    j.push_str(&format!(",\n\"prefix\":\"{}\"", json_escape(prefix)));
    j.push_str(&format!(",\n\"date\":\"{}\"", json_escape(&date_string())));
    j.push_str(&format!(",\n\"method\":\"{}\"", json_escape(&model.method)));
    j.push_str(&format!(",\n\"outputFormat\":\"{}\"", json_escape(&model.output_format)));
    j.push_str(&format!(",\n\"outputFilename\":\"{}\"", json_escape(result_file)));
    j.push_str(&format!(",\n\"outputFilesize\":{}", file_size(result_file)));
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
    if let Err(e) = std::fs::write(&name, j) {
        omclog::warning(omclog::STDOUT, false, &format!("Failed to open file {name} for writing: {e}"));
    }
}
