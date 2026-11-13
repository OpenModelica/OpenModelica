//! `compareSimulationResults`, `deltaSimulationResults`,
//! `diffSimulationResults` and `diffSimulationResultsHtml`.

use std::fmt::Write as _;

use super::{Messages, basename, open_reporting};
use crate::cmp::{Algorithm, DEFAULT_NOMINAL_VALUE, almost_equal_default, format_g_prec15, tube_csv, tube_html};
use crate::file::{Compared, Missing, ResultFile, Tolerances, diff_each};
use crate::{ResultReader, drop_leading_dups, fs, leading_dup_count, time_var_name};

fn display(running_testsuite: bool, file: &str) -> &str {
    if running_testsuite { basename(file) } else { file }
}

fn could_not_read(msgs: &mut dyn Messages, plt: bool, var: &str, file: &str) {
    if plt {
        msgs.error("Variable %s not found in simulation result.", &[var]);
    } else {
        msgs.error("Could not read variable %s in file %s.", &[var, file]);
    }
}

/// C `getData`: the trajectory, after a message when it cannot be read.
fn get_data(msgs: &mut dyn Messages, reader: &mut ResultReader, var: &str, file: &str) -> Option<Vec<f64>> {
    let data = reader.trajectory(var);
    if data.is_none() {
        could_not_read(msgs, matches!(reader, ResultReader::Plt(_)), var, file);
    }
    data.filter(|d| !d.is_empty())
}

fn has_time(msgs: &mut dyn Messages, file: &mut ResultFile, display: &str) -> bool {
    if file.time().is_ok() {
        return true;
    }
    let name = file.time_name().to_owned();
    if file.reader.trajectory(&name).is_none() {
        could_not_read(msgs, matches!(file.reader, ResultReader::Plt(_)), &name, display);
    }
    false
}

fn end_time_warning(msgs: &mut dyn Messages, time: &[f64], timeref: &[f64], reltol: f64) {
    let (last, last_ref) = (time[time.len() - 1], timeref[timeref.len() - 1]);
    if (last - last_ref).abs() > reltol * last_ref.abs() {
        let text = format!(
            "Resultfile and Reference have different end time points!\nReffile[{}]={:.6}\nFile[{}]={:.6}\n",
            timeref.len(),
            last_ref,
            time.len(),
            last
        );
        msgs.warning(&text, &[]);
    }
}

/// One point where `compareSimulationResults` found a difference.
struct DiffData {
    name: String,
    data: f64,
    dataref: f64,
    time: f64,
    timeref: f64,
    interpolate: bool,
}

/// C `cmpData`: the event-aware pointwise comparison of
/// `compareSimulationResults`, with the reference interpolated onto `time`.
#[allow(clippy::too_many_arguments)]
fn cmp_data(
    varname: &str,
    time: &[f64],
    reftime: &[f64],
    data: &[f64],
    refdata: &[f64],
    reltol: f64,
    abstol: f64,
    ddf: &mut Vec<DiffData>,
) -> bool {
    let reftime_n = reftime.len() as isize;
    let data_n = data.len();
    let time_n = time.len();

    let mut average = 0.0;
    for &x in refdata {
        average += x.abs();
    }
    average /= refdata.len() as f64;
    average = reltol * average.abs() + abstol;

    let mut isdifferent = false;
    let mut j: isize = 0;
    let mut tr = reftime[0];
    let mut i: usize = 0;
    'outer: while i < data_n {
        let mut t = time[i];
        let d = data[i];
        let mut increased = false;
        while tr < t {
            if j + 1 < reftime_n {
                j += 1;
                tr = reftime[j as usize];
                increased = true;
                if tr == t {
                    break;
                }
            } else {
                break;
            }
        }
        if increased && (((t - tr) / tr).abs() > reltol || (t - tr).abs() > (t - reftime[(j - 1) as usize]).abs()) {
            j -= 1;
            tr = reftime[j as usize];
        }

        // At an event compare only the values left and right of it.
        if i + 1 < time_n && almost_equal_default(t, time[i + 1]) {
            let d_left = d;
            if i + 1 < data_n {
                while almost_equal_default(t, time[i + 1]) {
                    i += 1;
                    if i + 1 >= data_n {
                        break;
                    }
                }
            }
            t = time[i];
            let d_right = data[i];

            let mut refevent = false;
            let mut t_event = t + t * reltol * 0.1;
            if i < data_n {
                t_event = if t_event > time[i] { time[i] } else { t_event };
            } else {
                t_event = if t_event > time[i + 1] { time[i + 1] } else { t_event };
            }
            let j_event = j;
            let mut dr_left = 0.0;
            while tr < t_event {
                if j + 1 < reftime_n && almost_equal_default(tr, reftime[(j + 1) as usize]) {
                    dr_left = refdata[j as usize];
                    refevent = true;
                    loop {
                        j += 1;
                        if j + 1 >= reftime_n {
                            break;
                        }
                        if !almost_equal_default(tr, reftime[(j + 1) as usize]) {
                            break;
                        }
                    }
                }
                if !refevent {
                    j += 1;
                    if j >= reftime_n {
                        break;
                    }
                    tr = reftime[j as usize];
                } else {
                    break;
                }
            }
            if refevent {
                tr = reftime[j as usize];
                let dr_right = refdata[j as usize];
                if (d_left - dr_left).abs() < average && (d_right - dr_right).abs() < average {
                    i += 1;
                    continue 'outer;
                }
            } else {
                j = j_event;
                tr = reftime[j as usize];
                refevent = false;
                t_event = t - t * reltol * 0.1;
                let mut dr_right = 0.0;
                while tr > t_event {
                    if j > 1 && almost_equal_default(tr, reftime[(j - 1) as usize]) {
                        dr_right = refdata[j as usize];
                        refevent = true;
                        loop {
                            j -= 1;
                            if j <= 1 {
                                break;
                            }
                            if !almost_equal_default(tr, reftime[(j - 1) as usize]) {
                                break;
                            }
                        }
                    }
                    if !refevent {
                        j -= 1;
                        // C tests `j == 0`, and reads `reftime[-1]` when it started at 0.
                        if j <= 0 {
                            break;
                        }
                        tr = reftime[j as usize];
                    } else {
                        break;
                    }
                }
                if refevent {
                    dr_left = refdata[j as usize];
                    if (d_left - dr_left).abs() < average && (d_right - dr_right).abs() < average {
                        j = j_event;
                        tr = reftime[j as usize];
                        i += 1;
                        continue 'outer;
                    }
                }
                j = j_event;
                tr = reftime[j as usize];
            }
        }

        let interpolate = (t - tr).abs() > 0.00001;
        let mut dr = refdata[j as usize];
        if interpolate {
            if tr > t {
                let mut jj = j;
                if j > 1 {
                    jj = j - 1;
                    if reftime[jj as usize] == tr {
                        loop {
                            jj -= 1;
                            if jj <= 0 {
                                break;
                            }
                            if reftime[jj as usize] != tr {
                                break;
                            }
                        }
                    }
                }
                if reftime[jj as usize] != tr {
                    dr = refdata[jj as usize]
                        + ((dr - refdata[jj as usize]) / (tr - reftime[jj as usize])) * (t - reftime[jj as usize]);
                }
            } else {
                let mut jj = j;
                if j + 1 < reftime_n {
                    jj = j + 1;
                    if reftime[jj as usize] == tr {
                        loop {
                            jj += 1;
                            if jj >= reftime_n {
                                break;
                            }
                            if reftime[jj as usize] != tr {
                                break;
                            }
                        }
                    }
                }
                if reftime[jj as usize] != tr {
                    dr = dr + ((refdata[jj as usize] - dr) / (reftime[jj as usize] - tr)) * (t - tr);
                }
            }
        }

        let mut err = (d - dr).abs();
        if err > average {
            if j + 1 < reftime_n && reftime[(j + 1) as usize] == tr {
                dr = refdata[(j + 1) as usize];
                err = (d - dr).abs();
            }
            if err < average {
                i += 1;
                continue 'outer;
            }
            isdifferent = true;
            ddf.push(DiffData {
                name: varname.to_owned(),
                data: d,
                dataref: dr,
                time: t,
                timeref: tr,
                interpolate,
            });
        }
        i += 1;
    }
    isdifferent
}

fn write_log_file(
    filename: &str,
    ddf: &[DiffData],
    f: &str,
    reff: &str,
    reltol: f64,
    abstol: f64,
) -> std::io::Result<()> {
    let g = format_g_prec15;
    let mut s = String::new();
    let _ = writeln!(s, "\"Generated by OpenModelica\";;;;;");
    let _ = writeln!(
        s,
        "\"Compared Files\";;;\"absolute tolerance\";{};relative tolerance;{}",
        g(abstol),
        g(reltol)
    );
    let _ = writeln!(s, "\"{f}\";;;;;;");
    let _ = writeln!(s, "\"{reff}\";;;;;;");
    let _ = writeln!(
        s,
        "\"Name\";\"Time\";\"DataPoint\";\"RefTime\";\"RefDataPoint\";\"absolute error\";\"relative error\";interpolate;"
    );
    for dd in ddf {
        let _ = writeln!(
            s,
            "{};{};{};{};{};{};{};{};",
            dd.name,
            g(dd.time),
            g(dd.data),
            g(dd.timeref),
            g(dd.dataref),
            g((dd.data - dd.dataref).abs()),
            g(((dd.data - dd.dataref) / dd.dataref).abs()),
            if dd.interpolate { '1' } else { '0' }
        );
    }
    fs::write(filename, s.as_bytes())
}

fn compared_vars(
    msgs: &mut dyn Messages,
    vars: &[String],
    reference: &ResultReader,
    error: &str,
) -> Option<Vec<String>> {
    let vars = if vars.is_empty() {
        reference.vars_filter_aliases()
    } else {
        vars.to_vec()
    };
    if vars.is_empty() {
        msgs.error(error, &[]);
        return None;
    }
    Some(vars)
}

/// `compareSimulationResults`: `["Files Equal!"]`, or `"Files not Equal!"`
/// followed by the differing variables; the differing points go to `logfile`.
/// `None` after a message when the files cannot be compared at all.
#[allow(clippy::too_many_arguments)]
pub fn compare(
    msgs: &mut dyn Messages,
    running_testsuite: bool,
    filename: &str,
    reffilename: &str,
    logfile: &str,
    reltol: f64,
    abstol: f64,
    vars: &[String],
) -> Option<Vec<String>> {
    let Some(mut reader) = open_reporting(msgs, filename) else {
        msgs.error("Error opening file: %s", &[filename]);
        return None;
    };
    let Some(mut reader_ref) = open_reporting(msgs, reffilename) else {
        msgs.error("Error opening reference file: %s", &[reffilename]);
        return None;
    };
    let vars = compared_vars(msgs, vars, &reader_ref, "Error getting variables")?;
    if vars.len() > 1 {
        reader.read_all();
        reader_ref.read_all();
    }
    let (file, ref_file) = (
        display(running_testsuite, filename),
        display(running_testsuite, reffilename),
    );
    let time_name = time_var_name(&reader.vars_filter_aliases());
    let timeref_name = time_var_name(&reader_ref.vars_filter_aliases());
    let Some(time) = get_data(msgs, &mut reader, time_name, file) else {
        msgs.error("Error getting time", &[]);
        return None;
    };
    let Some(timeref) = get_data(msgs, &mut reader_ref, timeref_name, ref_file) else {
        msgs.error("Error getting time from reference file", &[]);
        return None;
    };
    end_time_warning(msgs, &time, &timeref, reltol);

    let offset = leading_dup_count(&time);
    let offset_ref = leading_dup_count(&timeref);
    let mut ddf = Vec::new();
    let mut differs = Vec::new();
    let mut nfailed = 0;
    for var in &vars {
        let var1 = var.replace('"', "");
        let Some(mut dataref) = get_data(msgs, &mut reader_ref, &var1, ref_file) else {
            msgs.warning("Get data of variable %s from file %s failed!\n", &[var, ref_file]);
            nfailed += 1;
            continue;
        };
        let Some(mut data) = get_data(msgs, &mut reader, &var1, file) else {
            msgs.warning("Get data of variable %s from file %s failed!\n", &[var, file]);
            nfailed += 1;
            continue;
        };
        drop_leading_dups(&mut data, offset);
        drop_leading_dups(&mut dataref, offset_ref);
        if cmp_data(var, &time, &timeref, &data, &dataref, reltol, abstol, &mut ddf) {
            differs.push(var.clone());
        }
    }

    if write_log_file(logfile, &ddf, filename, reffilename, reltol, abstol).is_err() {
        msgs.warning("Cannot write to the difference (.csv) file!\n", &[]);
    }
    if ddf.is_empty() && nfailed == 0 && differs.is_empty() {
        return Some(vec!["Files Equal!".to_owned()]);
    }
    msgs.warning("Files not Equal\n", &[]);
    let mut res = vec!["Files not Equal!".to_owned()];
    res.extend(differs.into_iter().rev());
    Some(res)
}

#[derive(Clone, Copy)]
enum ErrorMethod {
    Norm1,
    Norm2,
    MaxErr,
}

/// C `deltaData`: the norm of `data - refdata` at the reference times, with
/// `data` interpolated linearly.
fn delta_data(method: ErrorMethod, time: &[f64], reftime: &[f64], data: &[f64], refdata: &[f64]) -> f64 {
    let mut res = 0.0;
    let mut i = 0usize;
    let tn = time.len();
    // C reads time[n], one past the end, for the largest time.
    let thr = (0.0001 * time[tn - 1]).max(1e-12);
    for (&t, &valref) in reftime.iter().zip(refdata) {
        while i < tn && time[i] < t {
            i += 1;
        }
        if i >= tn {
            break;
        }
        let i2 = i + 1;
        let val = if (time[i] - t).abs() <= thr || i2 >= tn {
            data[i]
        } else {
            (data[i2] - data[i]) / (time[i2] - time[i]) * (t - time[i]) + data[i]
        };
        match method {
            ErrorMethod::Norm1 => res += (valref - val).abs(),
            ErrorMethod::Norm2 => res += (valref - val).powi(2),
            ErrorMethod::MaxErr => res = (valref - val).abs().max(res),
        }
    }
    match method {
        ErrorMethod::Norm2 => res.sqrt(),
        _ => res,
    }
}

/// `deltaSimulationResults`: the summed `method` norm ("1norm", "2norm",
/// "maxerr") of the differences; -1 after a message.
pub fn delta(msgs: &mut dyn Messages, filename: &str, reffilename: &str, method: &str, vars: &[String]) -> f64 {
    let method = match method {
        "1norm" => ErrorMethod::Norm1,
        "2norm" => ErrorMethod::Norm2,
        "maxerr" => ErrorMethod::MaxErr,
        _ => {
            msgs.warning("Unknown method string: %s. 1-Norm is chosen.", &[method]);
            ErrorMethod::Norm1
        }
    };
    let Some(mut reader) = open_reporting(msgs, filename) else {
        msgs.error("Error opening file: %s.", &[filename]);
        return -1.0;
    };
    // The C names the result file here too.
    let Some(mut reader_ref) = open_reporting(msgs, reffilename) else {
        msgs.error("Error opening reference file: %s.", &[filename]);
        return -1.0;
    };
    let Some(vars) = compared_vars(msgs, vars, &reader_ref, "Error Getting Vars.") else {
        return -1.0;
    };
    if vars.len() > 1 {
        reader.read_all();
        reader_ref.read_all();
    }
    let time_name = time_var_name(&reader.vars_filter_aliases());
    let timeref_name = time_var_name(&reader_ref.vars_filter_aliases());
    let Some(time) = get_data(msgs, &mut reader, time_name, filename) else {
        msgs.error("Error get time!", &[]);
        return -1.0;
    };
    let Some(timeref) = get_data(msgs, &mut reader_ref, timeref_name, reffilename) else {
        msgs.error("Error get reference time!", &[]);
        return -1.0;
    };
    if time[0] > timeref[0] {
        msgs.error("The result file starts before the reference file.", &[]);
        return -1.0;
    }
    if time[time.len() - 1] < timeref[timeref.len() - 1] {
        msgs.error("The result file ends before the reference file.", &[]);
        return -1.0;
    }

    let offset = leading_dup_count(&time);
    let offset_ref = leading_dup_count(&timeref);
    let mut res = 0.0;
    for var in &vars {
        let var1 = var.replace('"', "");
        let Some(mut dataref) = get_data(msgs, &mut reader_ref, &var1, reffilename) else {
            continue;
        };
        let Some(mut data) = get_data(msgs, &mut reader, &var1, filename) else {
            continue;
        };
        drop_leading_dups(&mut data, offset);
        drop_leading_dups(&mut dataref, offset_ref);
        res += delta_data(method, &time, &timeref, &data, &dataref);
    }
    res
}

struct Diff<'a> {
    actual: ResultFile,
    reference: ResultFile,
    file: &'a str,
    ref_file: &'a str,
    vars: Vec<String>,
    tol: Tolerances,
}

impl<'a> Diff<'a> {
    #[allow(clippy::too_many_arguments)]
    fn open(
        msgs: &mut dyn Messages,
        running_testsuite: bool,
        filename: &'a str,
        reffilename: &'a str,
        vars: &[String],
        reltol: f64,
        reltol_diff_max_min: f64,
        range_delta: f64,
    ) -> Option<Diff<'a>> {
        let Some(actual) = open_reporting(msgs, filename) else {
            msgs.error("Error opening file: %s", &[filename]);
            return None;
        };
        let Some(reference) = open_reporting(msgs, reffilename) else {
            msgs.error("Error opening reference file: %s", &[reffilename]);
            return None;
        };
        let vars = compared_vars(msgs, vars, &reference, "Error getting variables")?;
        let mut d = Diff {
            actual: ResultFile::from_reader(actual),
            reference: ResultFile::from_reader(reference),
            file: display(running_testsuite, filename),
            ref_file: display(running_testsuite, reffilename),
            vars,
            tol: Tolerances {
                reltol,
                reltol_diff_min_max: reltol_diff_max_min,
                range_delta,
                algorithm: Algorithm::Ellipse2014,
                nominal_value: DEFAULT_NOMINAL_VALUE,
            },
        };
        if !has_time(msgs, &mut d.actual, d.file) {
            msgs.error("Error getting time", &[]);
            return None;
        }
        if !has_time(msgs, &mut d.reference, d.ref_file) {
            msgs.error("Error getting time from reference file", &[]);
            return None;
        }
        end_time_warning(msgs, d.actual.time().unwrap(), d.reference.time().unwrap(), reltol);
        Some(d)
    }

    /// Compare each variable for `f`; one that cannot be read or compared is
    /// reported here and fails.
    fn run(mut self, msgs: &mut dyn Messages, mut f: impl FnMut(&mut dyn Messages, &str, Compared)) {
        let plt = matches!(self.actual.reader, ResultReader::Plt(_));
        let plt_ref = matches!(self.reference.reader, ResultReader::Plt(_));
        let (file, ref_file) = (self.file, self.ref_file);
        let vars = std::mem::take(&mut self.vars);
        let _ = diff_each(
            &mut self.actual,
            &mut self.reference,
            vars,
            self.tol,
            |var, c| match c {
                Ok(c) => {
                    if let Err(e) = &c.cmp {
                        msgs.warning("Could not compare variable %s: %s", &[var, e]);
                    }
                    f(msgs, var, c);
                }
                Err(missing) => {
                    let (file, plt) = match missing {
                        Missing::Reference => (ref_file, plt_ref),
                        Missing::Actual => (file, plt),
                    };
                    could_not_read(msgs, plt, &var.replace('"', ""), file);
                    msgs.warning("Get data of variable %s from file %s failed!\n", &[var, file]);
                    f(
                        msgs,
                        var,
                        Compared {
                            time: Vec::new(),
                            data: Vec::new(),
                            cmp: Err(String::new()),
                        },
                    );
                }
            },
        );
    }
}

/// `diffSimulationResults`: whether every variable stays in its tube, and the
/// variables that do not or are missing. With a `prefix`, each of those (all
/// of them with `keep_equal_results`) gets a `<prefix>.<var>.csv` file.
#[allow(clippy::too_many_arguments)]
pub fn diff(
    msgs: &mut dyn Messages,
    running_testsuite: bool,
    filename: &str,
    reffilename: &str,
    prefix: &str,
    reltol: f64,
    reltol_diff_max_min: f64,
    range_delta: f64,
    vars: &[String],
    keep_equal_results: bool,
) -> (bool, Vec<String>) {
    let Some(d) = Diff::open(
        msgs,
        running_testsuite,
        filename,
        reffilename,
        vars,
        reltol,
        reltol_diff_max_min,
        range_delta,
    ) else {
        return (false, Vec::new());
    };
    let mut differs = Vec::new();
    d.run(msgs, |_, var, c| {
        let failed = c.differs();
        if let Ok(cmp) = &c.cmp
            && (failed || keep_equal_results)
            && !prefix.is_empty()
        {
            let _ = fs::write(
                &format!("{prefix}.{var}.csv"),
                tube_csv(&c.time, &c.data, cmp).as_bytes(),
            );
        }
        if failed {
            differs.push(var.to_owned());
        }
    });
    differs.reverse();
    (differs.is_empty(), differs)
}

/// `diffSimulationResultsHtml`: the dygraph page of `var`'s comparison, ""
/// when it cannot be compared, `None` when the files cannot be.
#[allow(clippy::too_many_arguments)]
pub fn diff_html(
    msgs: &mut dyn Messages,
    running_testsuite: bool,
    var: &str,
    filename: &str,
    reffilename: &str,
    reltol: f64,
    reltol_diff_max_min: f64,
    range_delta: f64,
) -> Option<String> {
    let vars = [var.to_owned()];
    let d = Diff::open(
        msgs,
        running_testsuite,
        filename,
        reffilename,
        &vars,
        reltol,
        reltol_diff_max_min,
        range_delta,
    )?;
    let mut html = String::new();
    d.run(msgs, |_, var, c| {
        if let Ok(cmp) = &c.cmp {
            html = tube_html(var, &c.time, &c.data, cmp, reltol, reltol_diff_max_min, range_delta);
        }
    });
    Some(html)
}
