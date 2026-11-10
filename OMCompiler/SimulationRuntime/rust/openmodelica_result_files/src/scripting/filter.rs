//! `filterSimulationResults`.

use super::{Messages, basename, open_reporting, with_reader};
use crate::cmp::format_g_prec15;
use crate::file::ResultFile;
use crate::{CsvReader, ResultReader, ResultTable, fs};

fn could_not_read(msgs: &mut dyn Messages, var: &str, in_file: &str) {
    msgs.error("Could not read variable %s in file %s.", &[var, basename(in_file)]);
}

fn write(msgs: &mut dyn Messages, out_file: &str, bytes: &[u8]) -> bool {
    let ok = fs::write(out_file, bytes).is_ok();
    if !ok {
        msgs.error("Failed to write to file %s.", &[out_file]);
    }
    ok
}

fn grid_time(j: i32, intervals: i32, start: f64, stop: f64) -> f64 {
    if j == intervals {
        stop
    } else {
        start + (stop - start) * (j as f64) / (intervals as f64)
    }
}

fn push_mat_header(out: &mut Vec<u8>, name: &str, rows: usize, cols: usize, elem_size: u32) {
    let ty: u32 = match elem_size {
        1 => 51,
        4 => 20,
        _ => 0,
    };
    for field in [ty, rows as u32, cols as u32, 0, name.len() as u32 + 1] {
        out.extend_from_slice(&field.to_le_bytes());
    }
    out.extend_from_slice(name.as_bytes());
    out.push(0);
}

/// A binNormal text matrix: one row per string, padded to `width`.
fn push_char_matrix(out: &mut Vec<u8>, name: &str, strings: &[&str], width: usize) {
    push_mat_header(out, name, strings.len(), width, 1);
    let rows = strings.len();
    let mut buf = vec![0u8; rows * width];
    for (i, s) in strings.iter().enumerate() {
        for (j, &b) in s.as_bytes().iter().enumerate() {
            buf[rows * j + i] = b;
        }
    }
    out.extend_from_slice(&buf);
}

/// Width 1 rather than 0, which older readers cannot read back.
fn push_empty_descriptions(out: &mut Vec<u8>, n: usize) {
    push_char_matrix(out, "description", &vec![""; n], 1);
}

fn push_aclass(out: &mut Vec<u8>) {
    push_mat_header(out, "Aclass", 4, 11, 1);
    out.extend_from_slice(b"A1 bt. ir1 na  Nj  oe  rc  mt  ao  lr   y   ");
}

fn push_data_info(out: &mut Vec<u8>, columns: &[(bool, i32)]) {
    push_mat_header(out, "dataInfo", columns.len(), 4, 4);
    for &(is_param, _) in columns {
        out.extend_from_slice(&(if is_param { 1i32 } else { 2 }).to_le_bytes());
    }
    for &(_, index) in columns {
        out.extend_from_slice(&index.to_le_bytes());
    }
    for _ in columns {
        out.extend_from_slice(&0i32.to_le_bytes());
    }
    for _ in columns {
        out.extend_from_slice(&(-1i32).to_le_bytes());
    }
}

fn csv_text(names: &[&str], time: &[f64], cols: &[&[f64]]) -> String {
    let mut text = String::from("time");
    for name in names {
        text.push_str(&format!(",\"{name}\""));
    }
    text.push('\n');
    for (row, t) in time.iter().enumerate() {
        text.push_str(&format_g_prec15(*t));
        for col in cols {
            text.push(',');
            text.push_str(&format_g_prec15(col[row]));
        }
        text.push('\n');
    }
    text
}

/// `filterSimulationResults`: `vars` (and time) of `in_file` written to
/// `out_file`, in the format its suffix names, resampled onto
/// `number_of_intervals` equidistant intervals unless 0.
pub fn filter(
    msgs: &mut dyn Messages,
    in_file: &str,
    out_file: &str,
    vars: &[String],
    number_of_intervals: i32,
    remove_description: bool,
) -> bool {
    if in_file.ends_with(".arrow") || out_file.ends_with(".arrow") {
        let Some(reader) = open_reporting(msgs, in_file) else {
            return false;
        };
        let suffix = out_file.rsplit('.').next().unwrap_or("");
        let bytes = ResultFile::from_reader(reader).write_described(
            suffix,
            vars.to_vec(),
            number_of_intervals.max(0) as u32,
            false,
            !remove_description,
        );
        return match bytes {
            Ok(bytes) => write(msgs, out_file, &bytes),
            Err(e) => {
                msgs.error("%s", &[&e]);
                false
            }
        };
    }
    let mut names: Vec<&str> = Vec::with_capacity(vars.len() + 1);
    names.push("time");
    names.extend(vars.iter().map(String::as_str));
    with_reader(msgs, in_file, |reader, msgs| match reader {
        ResultReader::Csv(r) => filter_csv(msgs, in_file, out_file, r, &names, number_of_intervals),
        ResultReader::Plt(_) => {
            msgs.error(
                "filterSimulationResults not implemented for plot format: %s\n",
                &["PLT"],
            );
            false
        }
        r => filter_table(
            msgs,
            in_file,
            out_file,
            r.table_mut().unwrap(),
            &names,
            number_of_intervals,
            remove_description,
        ),
    })
    .unwrap_or(false)
}

/// A CSV has no parameters and no descriptions, and a repeated name shares
/// its column.
fn filter_csv(
    msgs: &mut dyn Messages,
    in_file: &str,
    out_file: &str,
    reader: &CsvReader,
    names: &[&str],
    number_of_intervals: i32,
) -> bool {
    let mut cols: Vec<&[f64]> = Vec::new();
    let mut col_of: Vec<usize> = Vec::with_capacity(names.len());
    for (k, name) in names.iter().enumerate() {
        if let Some(prev) = names[..k].iter().position(|n| n == name) {
            col_of.push(col_of[prev]);
            continue;
        }
        // MAP-LIB reference files call it "Time", which the output renames.
        let found = reader
            .dataset(name)
            .or_else(|| if k == 0 { reader.dataset("Time") } else { None });
        let Some(vals) = found.filter(|_| reader.numsteps >= 2) else {
            could_not_read(msgs, name, in_file);
            return false;
        };
        col_of.push(cols.len());
        cols.push(vals);
    }
    let time = cols[col_of[0]];
    let (start, stop) = (time[0], time[time.len() - 1]);

    if out_file.ends_with(".csv") {
        let out_cols: Vec<&[f64]> = col_of[1..].iter().map(|&c| cols[c]).collect();
        return write(msgs, out_file, csv_text(&names[1..], time, &out_cols).as_bytes());
    }

    let out_rows = if number_of_intervals != 0 {
        number_of_intervals as usize + 1
    } else {
        time.len()
    };
    let mut out = Vec::new();
    push_aclass(&mut out);
    push_char_matrix(
        &mut out,
        "name",
        names,
        names.iter().map(|n| n.len()).max().unwrap_or(0),
    );
    push_empty_descriptions(&mut out, names.len());
    let info: Vec<(bool, i32)> = col_of.iter().map(|&c| (false, c as i32 + 1)).collect();
    push_data_info(&mut out, &info);
    push_mat_header(&mut out, "data_1", 2, 1, 8);
    out.extend_from_slice(&start.to_le_bytes());
    out.extend_from_slice(&stop.to_le_bytes());
    push_mat_header(&mut out, "data_2", out_rows, cols.len(), 8);
    for col in &cols {
        if number_of_intervals == 0 {
            for v in *col {
                out.extend_from_slice(&v.to_le_bytes());
            }
            continue;
        }
        let mut k = 0usize;
        for j in 0..out_rows as i32 {
            let t = grid_time(j, number_of_intervals, start, stop);
            while k + 2 < time.len() && time[k + 1] < t {
                k += 1;
            }
            let (t0, t1) = (time[k], time[k + 1]);
            let v = if t1 == t0 {
                col[k]
            } else {
                col[k] + (t - t0) / (t1 - t0) * (col[k + 1] - col[k])
            };
            out.extend_from_slice(&v.to_le_bytes());
        }
    }
    write(msgs, out_file, &out)
}

struct FilterVar {
    name: String,
    descr: String,
    is_param: bool,
    /// The data_1 (parameter) or data_2 column in the input, negative for a
    /// negated alias.
    index: i32,
}

fn filter_table(
    msgs: &mut dyn Messages,
    in_file: &str,
    out_file: &str,
    reader: &mut dyn ResultTable,
    names: &[&str],
    number_of_intervals: i32,
    remove_description: bool,
) -> bool {
    let mut fvars: Vec<FilterVar> = Vec::with_capacity(names.len());
    for name in names {
        let Some(i) = reader.find_var(name) else {
            could_not_read(msgs, name, in_file);
            return false;
        };
        let info = &reader.all_info()[i];
        fvars.push(FilterVar {
            name: info.name.clone(),
            descr: info.descr.clone(),
            is_param: info.isParam,
            index: info.index,
        });
    }
    let (start, stop) = (reader.start_time(), reader.stop_time());

    if out_file.ends_with(".csv") {
        let mut cols = Vec::with_capacity(fvars.len());
        for fv in &fvars {
            if fv.is_param {
                msgs.error(
                    "Could not filter parameter %s since the output format is CSV (only variables are allowed).",
                    &[&fv.name],
                );
                return false;
            }
            let Some(vals) = reader.read_vals(fv.index) else {
                could_not_read(msgs, &fv.name, in_file);
                return false;
            };
            cols.push(vals);
        }
        let out_names: Vec<&str> = fvars[1..].iter().map(|f| f.name.as_str()).collect();
        let out_cols: Vec<&[f64]> = cols[1..].iter().map(Vec::as_slice).collect();
        return write(msgs, out_file, csv_text(&out_names, &cols[0], &out_cols).as_bytes());
    }

    // Old to new column numbers; data_1 column 1 holds start and stop time.
    let mut indexes = vec![0i32; reader.nvar()];
    let mut parameter_indexes = vec![0i32; reader.nparam()];
    if let Some(first) = parameter_indexes.first_mut() {
        *first = 1;
    }
    for fv in &fvars {
        let slot = fv.index.unsigned_abs() as usize - 1;
        if fv.is_param {
            parameter_indexes[slot] += 1;
        } else {
            indexes[slot] += 1;
        }
    }
    let renumber = |counts: &mut [i32]| -> Vec<i32> {
        let mut used = Vec::new();
        for (i, c) in counts.iter_mut().enumerate() {
            if *c != 0 {
                used.push(i as i32 + 1);
            }
            *c = used.len() as i32;
        }
        used
    };
    let columns_used = renumber(&mut indexes);
    let mut params_used = renumber(&mut parameter_indexes);
    if params_used.first() != Some(&1) {
        params_used.insert(0, 1);
    }

    let mut out = Vec::new();
    push_aclass(&mut out);
    let out_names: Vec<&str> = fvars.iter().map(|f| f.name.as_str()).collect();
    push_char_matrix(
        &mut out,
        "name",
        &out_names,
        out_names.iter().map(|n| n.len()).max().unwrap_or(0),
    );
    if remove_description {
        push_empty_descriptions(&mut out, fvars.len());
    } else {
        let descrs: Vec<&str> = fvars.iter().map(|f| f.descr.as_str()).collect();
        push_char_matrix(
            &mut out,
            "description",
            &descrs,
            descrs.iter().map(|d| d.len()).max().unwrap_or(0),
        );
    }
    let info: Vec<(bool, i32)> = fvars
        .iter()
        .map(|fv| {
            let slot = fv.index.unsigned_abs() as usize - 1;
            let new = if fv.is_param {
                parameter_indexes[slot]
            } else {
                indexes[slot]
            };
            (fv.is_param, if fv.index < 0 { -new } else { new })
        })
        .collect();
    push_data_info(&mut out, &info);

    push_mat_header(&mut out, "data_1", 2, params_used.len(), 8);
    out.extend_from_slice(&start.to_le_bytes());
    out.extend_from_slice(&stop.to_le_bytes());
    for &p in &params_used[1..] {
        let v = reader.params()[p as usize - 1];
        out.extend_from_slice(&v.to_le_bytes());
        out.extend_from_slice(&v.to_le_bytes());
    }

    if number_of_intervals != 0 {
        let timevals = reader.read_vals(1).unwrap_or_default();
        let (mut nevents, mut neventpoints, mut k) = (0, 0, 0usize);
        for i in 1..number_of_intervals {
            let t = grid_time(i, number_of_intervals, start, stop);
            while k < timevals.len() && timevals[k] <= t {
                if k + 1 < timevals.len() && timevals[k] == timevals[k + 1] {
                    while k + 1 < timevals.len() && timevals[k] == timevals[k + 1] {
                        k += 1;
                        neventpoints += 1;
                    }
                    nevents += 1;
                }
                k += 1;
            }
        }
        msgs.add(
            super::Severity::Notification,
            "Resampling %s from %s points to %s points, removing %s events stored in %s points.\n",
            &[
                in_file,
                &reader.nrows().to_string(),
                &number_of_intervals.to_string(),
                &nevents.to_string(),
                &neventpoints.to_string(),
            ],
        );
    }

    let out_rows = if number_of_intervals != 0 {
        number_of_intervals as usize + 1
    } else {
        reader.nrows()
    };
    push_mat_header(&mut out, "data_2", out_rows, columns_used.len(), 8);
    for &col in &columns_used {
        if number_of_intervals != 0 {
            for j in 0..=number_of_intervals {
                let t = grid_time(j, number_of_intervals, start, stop);
                let Some(v) = reader.interp_val(col, t) else {
                    msgs.error(
                        "Resampling %s failed to get variable %s at time %s.\n",
                        &[in_file, &col.to_string(), &format_g_prec15(t)],
                    );
                    return false;
                };
                out.extend_from_slice(&v.to_le_bytes());
            }
        } else {
            let Some(vals) = reader.read_vals(col) else {
                could_not_read(msgs, "data_2", in_file);
                return false;
            };
            for v in vals {
                out.extend_from_slice(&v.to_le_bytes());
            }
        }
    }
    write(msgs, out_file, &out)
}
