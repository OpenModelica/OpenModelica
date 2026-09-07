//! `omplot`: result files from the command line, over the same
//! `openmodelica_result_files::ResultFile` the OMPlot web page and the C ABI use.

use std::process::ExitCode;

use openmodelica_result_files::file::{ResultFile, Tolerances, diff_all, diff_variable};

const USAGE: &str = "\
usage: omplot <command> [options] ...
  vars FILE                       one line per variable: name, type, unit, description
  info FILE                       rows, time span, variable counts
  traj FILE VAR...                CSV of time and the variables
  val FILE VAR TIME               the value of VAR at TIME (interpolated)
  diff ACTUAL REFERENCE [VAR...]  the variables that leave the tube (diffSimulationResults)
  tube ACTUAL REFERENCE VAR       CSV of the tube comparison of one variable
  convert IN OUT [VAR...]         write OUT (.mat/.arrow/.csv by suffix) from IN
options:
  --relTol X --relTolDiffMinMax X --rangeDelta X   tolerances for diff/tube
  --intervals N                   resample convert's output onto N equidistant steps
  --single                        convert: store the reals in single precision
FILE suffixes: .mat .arrow .csv .plt";

struct Opts {
    tol: Tolerances,
    intervals: u32,
    single: bool,
    args: Vec<String>,
}

fn parse(argv: &[String]) -> Result<Opts, String> {
    let mut o = Opts { tol: Tolerances::default(), intervals: 0, single: false, args: Vec::new() };
    let mut it = argv.iter();
    while let Some(a) = it.next() {
        let mut num = |what: &str| -> Result<f64, String> {
            it.next().ok_or_else(|| format!("{what} needs a value"))?.parse::<f64>().map_err(|e| format!("{what}: {e}"))
        };
        match a.as_str() {
            "--relTol" => o.tol.reltol = num(a)?,
            "--relTolDiffMinMax" => o.tol.reltol_diff_min_max = num(a)?,
            "--rangeDelta" => o.tol.range_delta = num(a)?,
            "--intervals" => o.intervals = num(a)? as u32,
            "--single" => o.single = true,
            _ if a.starts_with("--") => return Err(format!("unknown option {a}")),
            _ => o.args.push(a.clone()),
        }
    }
    Ok(o)
}

fn csv_row(out: &mut String, first: &str, rest: impl Iterator<Item = f64>) {
    out.push_str(first);
    for v in rest {
        out.push(',');
        out.push_str(&format!("{v}"));
    }
    out.push('\n');
}

fn run(o: Opts) -> Result<String, String> {
    let need = |n: usize| if o.args.len() < n + 1 { Err(USAGE.to_owned()) } else { Ok(()) };
    let cmd = o.args.first().map(String::as_str).unwrap_or("");
    let mut out = String::new();
    match cmd {
        "vars" => {
            need(1)?;
            let f = ResultFile::open(&o.args[1])?;
            for v in f.variables() {
                let kind = if f.is_parameter(&v) { "parameter" } else { "variable" };
                out.push_str(&format!("{v}\t{kind}\t{}\t{}\t{}\n", f.var_type(&v), f.unit(&v), f.description(&v)));
            }
        }
        "info" => {
            need(1)?;
            let mut f = ResultFile::open(&o.args[1])?;
            let vars = f.variables();
            let params = vars.iter().filter(|v| f.is_parameter(v)).count();
            let (start, stop) = (f.start_time(), f.stop_time());
            out.push_str(&format!("rows: {}\n", f.nrows()));
            out.push_str(&format!("time: {} from {start} to {stop}\n", f.time_name()));
            out.push_str(&format!("variables: {} ({} parameters, {} compared)\n", vars.len(), params, f.compared_variables().len()));
        }
        "traj" => {
            need(2)?;
            let mut f = ResultFile::open(&o.args[1])?;
            let vars = &o.args[2..];
            let time = f.time()?.to_vec();
            let mut cols = Vec::new();
            for v in vars {
                cols.push(f.trajectory(v).ok_or_else(|| format!("Could not read variable {v}"))?);
            }
            out.push_str("time");
            for v in vars {
                out.push_str(&format!(",\"{v}\""));
            }
            out.push('\n');
            for (r, t) in time.iter().enumerate() {
                csv_row(&mut out, &format!("{t}"), cols.iter().map(|c| c.get(r).copied().unwrap_or(f64::NAN)));
            }
        }
        "val" => {
            need(3)?;
            let mut f = ResultFile::open(&o.args[1])?;
            let t: f64 = o.args[3].parse().map_err(|e| format!("TIME: {e}"))?;
            let v = f.value_at(&o.args[2], t).ok_or_else(|| format!("Could not read variable {} at {t}", o.args[2]))?;
            out.push_str(&format!("{v}\n"));
        }
        "diff" => {
            need(2)?;
            let mut a = ResultFile::open(&o.args[1])?;
            let mut r = ResultFile::open(&o.args[2])?;
            for v in diff_all(&mut a, &mut r, o.args[3..].to_vec(), o.tol)? {
                out.push_str(&v);
                out.push('\n');
            }
        }
        "tube" => {
            need(3)?;
            let mut a = ResultFile::open(&o.args[1])?;
            let mut r = ResultFile::open(&o.args[2])?;
            let d = diff_variable(&mut a, &mut r, &o.args[3], o.tol)?;
            out.push_str(&format!("# differs: {}, abstol: {}\n", d.differs, d.abstol));
            out.push_str("time,reference,actual,high,low\n");
            for i in 0..d.time.len() {
                csv_row(&mut out, &format!("{}", d.time[i]), [d.reference[i], d.actual[i], d.high[i], d.low[i]].into_iter());
            }
        }
        "convert" => {
            need(2)?;
            let mut f = ResultFile::open(&o.args[1])?;
            let dest = &o.args[2];
            let suffix = dest.rsplit('.').next().unwrap_or("");
            let bytes = f.write(suffix, o.args[3..].to_vec(), o.intervals, o.single)?;
            std::fs::write(dest, &bytes).map_err(|e| format!("{dest}: {e}"))?;
            out.push_str(&format!("wrote {dest} ({} bytes)\n", bytes.len()));
        }
        _ => return Err(USAGE.to_owned()),
    }
    Ok(out)
}

fn main() -> ExitCode {
    let argv: Vec<String> = std::env::args().skip(1).collect();
    match parse(&argv).and_then(run) {
        Ok(out) => {
            print!("{out}");
            ExitCode::SUCCESS
        }
        Err(e) => {
            eprintln!("{e}");
            ExitCode::FAILURE
        }
    }
}
