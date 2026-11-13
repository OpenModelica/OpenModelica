//! The result-file functions of the scripting API (`val`,
//! `readSimulationResult`, `diffSimulationResults`, `filterSimulationResults`,
//! ...), shared by the C omc through libomc_result and by the Rust omc. They
//! report the way the C omc always has, through [`Messages`].

use std::sync::Mutex;
use std::time::SystemTime;

use crate::cmp::format_g;
use crate::{OpenError, PltVal, ResultReader, fs};

mod compare;
mod filter;

pub use compare::{compare, delta, diff, diff_html};
pub use filter::filter;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Severity {
    Error,
    Warning,
    Notification,
}

/// A scripting message: `format` has one `%s` per token, in order.
pub trait Messages {
    fn add(&mut self, severity: Severity, format: &str, tokens: &[&str]);

    fn error(&mut self, format: &str, tokens: &[&str]) {
        self.add(Severity::Error, format, tokens);
    }

    fn warning(&mut self, format: &str, tokens: &[&str]) {
        self.add(Severity::Warning, format, tokens);
    }
}

/// C `SystemImpl__basename`.
pub(crate) fn basename(path: &str) -> &str {
    path.rsplit(|c| c == '/' || (cfg!(windows) && c == '\\'))
        .next()
        .unwrap_or(path)
}

pub(crate) fn open_reporting(msgs: &mut dyn Messages, filename: &str) -> Option<ResultReader> {
    match ResultReader::open(filename) {
        Ok(r) => Some(r),
        Err(OpenError::UnknownSuffix) => {
            msgs.error("Unknown result-file suffix of file '%s'", &[filename]);
            None
        }
        Err(OpenError::Failed(e)) => {
            msgs.error("Failed to open simulation result %s: %s", &[filename, &e]);
            None
        }
    }
}

struct Cached {
    filename: String,
    mtime: Option<SystemTime>,
    reader: ResultReader,
}

/// The last file `val`, `readSimulationResult`, ... read, reused while it is
/// unchanged on disk.
static CACHE: Mutex<Option<Cached>> = Mutex::new(None);

fn with_reader<R>(
    msgs: &mut dyn Messages,
    filename: &str,
    f: impl FnOnce(&mut ResultReader, &mut dyn Messages) -> R,
) -> Option<R> {
    let mtime = fs::modified(filename).ok();
    let mut cache = CACHE.lock().unwrap_or_else(|e| e.into_inner());
    let reuse = matches!(&*cache, Some(c) if c.filename == filename && mtime.is_some() && c.mtime == mtime);
    if !reuse {
        *cache = None;
        let reader = open_reporting(msgs, filename)?;
        *cache = Some(Cached {
            filename: filename.to_owned(),
            mtime,
            reader,
        });
    }
    Some(f(&mut cache.as_mut().unwrap().reader, msgs))
}

/// Forget the cached file, e.g. before a simulation overwrites it.
pub fn close() {
    *CACHE.lock().unwrap_or_else(|e| e.into_inner()) = None;
}

/// `val`: NaN after a message when `var` has no value at `time`.
pub fn val(msgs: &mut dyn Messages, filename: &str, var: &str, time: f64) -> f64 {
    with_reader(msgs, filename, |reader, msgs| match reader {
        ResultReader::Plt(r) => match r.val(var, time) {
            PltVal::Value(v) => v,
            PltVal::NotFound => {
                msgs.error("%s not found in %s\n", &[var, filename]);
                f64::NAN
            }
            PltVal::NotDefined => {
                msgs.error("%s not defined at time %s\n", &[var, &format_g(time)]);
                f64::NAN
            }
        },
        ResultReader::Csv(_) => {
            msgs.error("val() not implemented for plot format: %s\n", &["CSV"]);
            f64::NAN
        }
        r => {
            let table = r.table_mut().unwrap();
            let Some(i) = table.find_var(var) else {
                msgs.error("%s not found in %s\n", &[var, filename]);
                return f64::NAN;
            };
            table.val(i, time).unwrap_or_else(|| {
                let (start, stop) = (table.start_time(), table.stop_time());
                msgs.error(
                    "%s not defined at time %s (startTime=%s, stopTime=%s).",
                    &[var, &format_g(time), &format_g(start), &format_g(stop)],
                );
                f64::NAN
            })
        }
    })
    .unwrap_or(f64::NAN)
}

/// `readSimulationResultVars`; `omc_style` turns `der(a.b)` into `a.der(b)`.
pub fn read_variables(msgs: &mut dyn Messages, filename: &str, read_parameters: bool, omc_style: bool) -> Vec<String> {
    let style = |name: &str| -> String {
        if omc_style {
            openmodelica_mat_reader::openmodelica_style_name(name)
                .unwrap_or_else(|| name.to_owned())
                .replace(' ', "")
        } else {
            name.to_owned()
        }
    };
    with_reader(msgs, filename, |reader, _| match reader {
        // Already in OMC style.
        ResultReader::Plt(r) => r.variables().into_iter().rev().map(str::to_owned).collect(),
        ResultReader::Csv(r) => r.variables.iter().filter(|v| !v.is_empty()).map(|v| style(v)).collect(),
        r => r
            .table()
            .unwrap()
            .all_info()
            .iter()
            .filter(|info| read_parameters || !info.isParam)
            .map(|info| style(&info.name))
            .collect(),
    })
    .unwrap_or_default()
}

/// `readSimulationResultSize`: -1 after a message when unknown.
pub fn read_size(msgs: &mut dyn Messages, filename: &str) -> i32 {
    with_reader(msgs, filename, |reader, msgs| match reader.nrows() {
        Some(n) => n as i32,
        None => {
            msgs.error("Failed to read readSimulationResultSize from file: %s\n", &[filename]);
            -1
        }
    })
    .unwrap_or(-1)
}

/// `readSimulationResult`: one row of `dimsize` values per variable (the
/// file's row count when `dimsize` is 0); `None` after a message.
pub fn read_dataset(msgs: &mut dyn Messages, filename: &str, vars: &[String], dimsize: i32) -> Option<Vec<Vec<f64>>> {
    let could_not_read = |msgs: &mut dyn Messages, var: &str| {
        msgs.error("Could not read variable %s in file %s.", &[var, filename]);
    };
    with_reader(msgs, filename, |reader, msgs| match reader {
        ResultReader::Plt(r) => {
            let interval = r.interval_size();
            let dim = if dimsize == 0 {
                interval.unwrap_or(0)
            } else {
                let Some(interval) = interval else {
                    msgs.error("could not read interval size.", &[]);
                    return None;
                };
                if interval as i32 != dimsize {
                    msgs.error("interval size not matching data size.", &[]);
                    return None;
                }
                interval
            };
            let mut rows = Vec::with_capacity(vars.len());
            for var in vars {
                let Some(vals) = r.dataset(var, dim) else {
                    msgs.error("Variable %s not found in simulation result.", &[var]);
                    return None;
                };
                rows.push(vals);
            }
            Some(rows)
        }
        ResultReader::Csv(r) => {
            let dim = dimsize.max(0) as usize;
            let mut rows = Vec::with_capacity(vars.len());
            for var in vars {
                match r.dataset(var) {
                    Some(c) if dim <= c.len() => rows.push(c[..dim].to_vec()),
                    _ => {
                        could_not_read(msgs, var);
                        return None;
                    }
                }
            }
            Some(rows)
        }
        r => {
            let nrows = r.nrows().unwrap_or(0);
            let dim = if dimsize == 0 {
                nrows
            } else if nrows as i32 != dimsize {
                msgs.error(
                    "readDataset(...): Expected and actual dimension sizes do not match.",
                    &[],
                );
                return None;
            } else {
                nrows
            };
            let mut rows = Vec::with_capacity(vars.len());
            for var in vars {
                match r.trajectory(var) {
                    Some(mut v) if v.len() >= dim => {
                        v.truncate(dim);
                        rows.push(v);
                    }
                    _ => {
                        could_not_read(msgs, var);
                        return None;
                    }
                }
            }
            Some(rows)
        }
    })
    .flatten()
}
