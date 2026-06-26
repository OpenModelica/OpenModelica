// Manually written file.
//
// CSV and PLT (Ptolemy) result-file readers for `SimulationResults.rs`,
// porting `SimulationRuntime/c/util/read_csv.c` (+ libcsv parsing rules)
// and `Compiler/runtime/ptolemyio.cpp`. The MATLAB v4 reader lives in
// `read_matlab4.rs`; `SimulationResults.rs` dispatches between the three
// by file suffix exactly like `SimulationResultsImpl__openFile`.

#[cfg(not(target_arch = "wasm32"))]
use std::fs;

/// Read a result file's bytes: the OS filesystem natively, or the in-memory VFS
/// on wasm (where the simulation wrote its result there).
fn read_result_bytes(filename: &str) -> Result<Vec<u8>, String> {
    #[cfg(target_arch = "wasm32")]
    {
        openmodelica_wasi::read(filename).ok_or_else(|| format!("No such file: {filename}"))
    }
    #[cfg(not(target_arch = "wasm32"))]
    {
        fs::read(filename).map_err(|e| e.to_string())
    }
}

// ─────────────────────────────────── CSV ──────────────────────────────────

/// Parsed CSV result file (`struct csv_data` in read_csv.h): a header row of
/// variable names followed by one row of doubles per time step.
pub struct CsvReader {
    /// Header cells in document order. May contain empty names (a trailing
    /// delimiter on the header line produces one); they are kept so the
    /// column count lines up with the data rows, and filtered where the C
    /// code filters them (readVariables).
    pub variables: Vec<String>,
    /// Var-major trajectories: `data[var][step]`.
    data: Vec<Vec<f64>>,
    pub numsteps: usize,
}

impl CsvReader {
    /// `read_csv`: returns `Err` with a short reason wherever the C reader
    /// returns NULL (caller turns that into the scripting error message).
    pub fn open(filename: &str) -> Result<CsvReader, String> {
        let bytes = read_result_bytes(filename)?;
        // Optional `"sep=X"` first line selects the cell delimiter; the
        // data then starts at offset 8 (`"sep=X"␊`), as in read_csv.c.
        let (delim, offset) = if bytes.len() >= 8 && bytes.starts_with(b"\"sep=") {
            (bytes[5], 8)
        } else {
            (b',', 0)
        };
        let rows = parse_csv(&bytes[offset..], delim)?;
        let mut rows = rows.into_iter();
        let Some(variables) = rows.next() else {
            return Err("empty CSV result file".to_owned());
        };
        let numvars = variables.len();
        let mut data: Vec<Vec<f64>> = vec![Vec::new(); numvars];
        for (rownum, row) in rows.enumerate() {
            if row.len() != numvars {
                // Mirrors add_row's complaint (rows are 1-based and the
                // header counts, hence +2).
                eprintln!("Did not find time points for all variables for row: {}", rownum + 2);
                return Err("row length mismatch".to_owned());
            }
            for (col, cell) in row.iter().enumerate() {
                let Some(v) = parse_csv_cell(cell) else {
                    // add_cell prints the offending cell to stderr.
                    eprintln!("Found non-double data in csv result-file: {cell}");
                    return Err("non-double data".to_owned());
                };
                data[col].push(v);
            }
        }
        let numsteps = data.first().map(|c| c.len()).unwrap_or(0);
        Ok(CsvReader { variables, data, numsteps })
    }

    /// `read_csv_dataset`: the trajectory of `var` (exact name match), or
    /// `None` when the variable is not a column of the file.
    pub fn dataset(&self, var: &str) -> Option<&[f64]> {
        let idx = self.variables.iter().position(|v| v == var)?;
        Some(&self.data[idx])
    }
}

/// A CSV cell as a double: empty / pure-whitespace cells are 0.0 (strtod
/// consumes nothing and the C code accepts that); anything else must parse
/// completely (`*endptr` must be NUL), so trailing garbage — including
/// trailing whitespace — is an error. (C's strtod would additionally accept
/// hex floats; nothing writes those into result CSVs.)
fn parse_csv_cell(cell: &str) -> Option<f64> {
    let t = cell.trim_start();
    if t.is_empty() {
        return Some(0.0);
    }
    t.parse::<f64>().ok()
}

/// Strict CSV parse mirroring the libcsv configuration in read_csv.c
/// (CSV_STRICT | CSV_REPALL_NL | CSV_STRICT_FINI | CSV_APPEND_NULL |
/// CSV_EMPTY_IS_NULL): quoted fields with `""` escapes, every newline ends
/// a row (an empty line is a row with one empty cell), `\r\n` counts once,
/// and a final row without trailing newline is submitted at EOF.
fn parse_csv(bytes: &[u8], delim: u8) -> Result<Vec<Vec<String>>, String> {
    let mut rows: Vec<Vec<String>> = Vec::new();
    let mut row: Vec<String> = Vec::new();
    let mut field: Vec<u8> = Vec::new();
    let mut i = 0;
    // True when `field` belongs to a started row even if empty (after a
    // delimiter, or after any field byte).
    let mut row_started = false;

    while i < bytes.len() {
        let b = bytes[i];
        // A quote opens a quoted field only at the field start; in strict
        // mode a quote later inside an unquoted field errors (below).
        if b == b'"' && field.is_empty() {
            // Quoted field.
            i += 1;
            loop {
                match bytes.get(i) {
                    None => return Err("unterminated quoted field".to_owned()),
                    Some(b'"') if bytes.get(i + 1) == Some(&b'"') => {
                        field.push(b'"');
                        i += 2;
                    }
                    Some(b'"') => {
                        i += 1;
                        break;
                    }
                    Some(&c) => {
                        field.push(c);
                        i += 1;
                    }
                }
            }
            // Strict mode: after the closing quote only a delimiter, a row
            // end, or EOF may follow.
            match bytes.get(i) {
                None => {}
                Some(&c) if c == delim || c == b'\n' || c == b'\r' => {}
                Some(_) => return Err("malformed quoted field".to_owned()),
            }
            row_started = true;
            continue;
        }
        if b == delim {
            row.push(String::from_utf8_lossy(&field).into_owned());
            field.clear();
            row_started = true;
            i += 1;
            continue;
        }
        if b == b'\n' || b == b'\r' {
            row.push(String::from_utf8_lossy(&field).into_owned());
            field.clear();
            rows.push(std::mem::take(&mut row));
            row_started = false;
            i += 1;
            if b == b'\r' && bytes.get(i) == Some(&b'\n') {
                i += 1; // CRLF is one row terminator
            }
            continue;
        }
        if b == b'"' {
            // Quote inside an unquoted field: CSV_STRICT error.
            return Err("quote in unquoted field".to_owned());
        }
        field.push(b);
        row_started = true;
        i += 1;
    }
    // csv_fini: submit a pending final row (no trailing newline).
    if row_started || !field.is_empty() {
        row.push(String::from_utf8_lossy(&field).into_owned());
        rows.push(row);
    }
    Ok(rows)
}

// ─────────────────────────────── PLT (Ptolemy) ────────────────────────────

/// A `.plt` result file held as lines; every operation rescans like the C
/// code rescans the kept `FILE*` (the files are small and this is script-
/// level code).
pub struct PltReader {
    lines: Vec<String>,
}

/// Outcome of [`PltReader::val`], so the caller can emit the exact
/// scripting error the C `SimulationResultsImpl__val` PLT branch produces.
pub enum PltVal {
    Value(f64),
    /// `%s not found in %s` — no `DataSet: <var>` line.
    NotFound,
    /// `%s not defined at time %s` — out of the sampled time range.
    NotDefined,
}

impl PltReader {
    pub fn open(filename: &str) -> Result<PltReader, String> {
        let bytes = read_result_bytes(filename)?;
        // .plt is ASCII; tolerate stray non-UTF8 bytes instead of failing.
        let text = String::from_utf8_lossy(&bytes);
        Ok(PltReader { lines: text.lines().map(str::to_owned).collect() })
    }

    /// `read_ptolemy_dataset_size`: the value after `#IntervalSize=`;
    /// `None` when the line is missing or atoi yields 0.
    pub fn interval_size(&self) -> Option<usize> {
        let line = self.lines.iter().find(|l| l.contains("#IntervalSize"))?;
        let (_, after) = line.split_once('=')?;
        let n = atoi_prefix(after);
        if n <= 0 { None } else { Some(n as usize) }
    }

    /// `read_ptolemy_variables`, in document order. NB the C version conses
    /// while scanning and never reverses, so `readVariables` on a .plt file
    /// returns the names in *reverse* document order — the caller applies
    /// that reversal.
    pub fn variables(&self) -> Vec<&str> {
        self.lines
            .iter()
            .filter_map(|l| {
                // sscanf("DataSet: %250s"): literal prefix, then the first
                // whitespace-delimited token (capped at 250 chars).
                let rest = l.strip_prefix("DataSet: ")?;
                let tok = rest.split_whitespace().next()?;
                Some(&tok[..tok.len().min(250)])
            })
            .collect()
    }

    /// One variable's trajectory from `read_ptolemy_dataset`: exactly the
    /// `datasize` lines after the `DataSet: <var>` header, taking the value
    /// after the first comma of each line. A line that does not parse (e.g.
    /// the next `DataSet:` header when the set is shorter than `datasize`)
    /// contributes ±inf for `Inf` spellings and NaN otherwise, mirroring
    /// the C fallback. Returns `None` when the variable has no DataSet.
    pub fn dataset(&self, var: &str, datasize: usize) -> Option<Vec<f64>> {
        let header = format!("DataSet: {var}");
        let start = self.lines.iter().position(|l| *l == header)? + 1;
        let mut out = Vec::with_capacity(datasize);
        for j in 0..datasize {
            let line = self.lines.get(start + j).map(String::as_str).unwrap_or("");
            // Value after the first comma; std::string::substr(npos+1)
            // wraps to the whole line when there is no comma.
            let value_text = match line.split_once(',') {
                Some((_, v)) => v,
                None => line,
            };
            let v = match strtod_prefix(value_text) {
                Some(v) => v,
                None => {
                    let t = value_text.trim_start();
                    if t.starts_with("Inf") || t.starts_with("inf") {
                        f64::INFINITY
                    } else if t.starts_with("-Inf") || t.starts_with("-inf") {
                        f64::NEG_INFINITY
                    } else {
                        f64::NAN
                    }
                }
            };
            out.push(v);
        }
        Some(out)
    }

    /// The PLT branch of `SimulationResultsImpl__val`: scan the variable's
    /// `t, v` lines (stopping at the first non-matching line, like fscanf)
    /// and linearly interpolate at `time_stamp`.
    pub fn val(&self, var: &str, time_stamp: f64) -> PltVal {
        let header = format!("DataSet: {var}");
        let Some(start) = self.lines.iter().position(|l| *l == header) else {
            return PltVal::NotFound;
        };
        let (mut pt, mut pv) = (f64::NAN, f64::NAN);
        let (mut t, mut v) = (f64::NAN, f64::NAN);
        let mut nread = 0usize;
        for line in &self.lines[start + 1..] {
            // fscanf("%lg, %lg"): double, literal comma (with optional
            // surrounding whitespace), double.
            let Some((ts, vs)) = line.split_once(',') else { break };
            let (Some(tp), Some(vp)) = (parse_full_double(ts), parse_full_double(vs)) else {
                break;
            };
            nread += 1;
            (t, v) = (tp, vp);
            if t > time_stamp {
                break;
            }
            (pt, pv) = (t, v);
        }
        if nread == 0 || nread == 1 || t < time_stamp {
            return PltVal::NotDefined;
        }
        if t - pt == 0.0 {
            return PltVal::Value(v);
        }
        let w1 = (time_stamp - pt) / (t - pt);
        PltVal::Value(pv * (1.0 - w1) + v * w1)
    }
}

/// `atoi`: optional leading whitespace and sign, then the longest digit
/// prefix; 0 when nothing parses.
fn atoi_prefix(s: &str) -> i64 {
    let t = s.trim_start();
    let (sign, digits) = match t.strip_prefix('-') {
        Some(rest) => (-1, rest),
        None => (1, t.strip_prefix('+').unwrap_or(t)),
    };
    let end = digits.bytes().take_while(|b| b.is_ascii_digit()).count();
    digits[..end].parse::<i64>().map(|n| sign * n).unwrap_or(0)
}

/// A whole-token double (both `%lg` conversions of the PLT line scan):
/// leading/trailing whitespace allowed, nothing else may remain.
fn parse_full_double(s: &str) -> Option<f64> {
    let t = s.trim();
    if t.is_empty() {
        return None;
    }
    t.parse::<f64>().ok()
}

/// `strtod` prefix semantics: parse the longest valid double prefix after
/// optional whitespace, ignoring whatever follows; `None` if no conversion
/// is possible at all.
fn strtod_prefix(s: &str) -> Option<f64> {
    let t = s.trim_start();
    let b = t.as_bytes();
    let mut i = 0;
    if i < b.len() && (b[i] == b'+' || b[i] == b'-') {
        i += 1;
    }
    let mantissa_start = i;
    while i < b.len() && b[i].is_ascii_digit() {
        i += 1;
    }
    if i < b.len() && b[i] == b'.' {
        i += 1;
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
        }
    }
    if i == mantissa_start || !t[mantissa_start..i].bytes().any(|c| c.is_ascii_digit()) {
        return None; // no digits at all
    }
    // Exponent only counts when at least one digit follows.
    if i < b.len() && (b[i] == b'e' || b[i] == b'E') {
        let mut j = i + 1;
        if j < b.len() && (b[j] == b'+' || b[j] == b'-') {
            j += 1;
        }
        let dstart = j;
        while j < b.len() && b[j].is_ascii_digit() {
            j += 1;
        }
        if j > dstart {
            i = j;
        }
    }
    t[..i].parse::<f64>().ok()
}
