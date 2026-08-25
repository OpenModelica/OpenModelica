//! `-reconcile` / `-reconcileBoundaryConditions` / `-reconcileState`: C's
//! `dataReconciliation/dataReconciliation.cpp`, the VDI 2048 procedures.
//!
//! The run is over by the time this starts: the model still holds the final point,
//! and the measured values from `-sx` are pushed into it, the equations re-solved
//! (`functionDAE`) and the auxiliary conditions read back (`setc_function`). The
//! Jacobians `F`/`H` come from the symbolic `reconJacF`/`reconJacH` exports.
//!
//! Reports (the HTML report, `_Outputs.csv`, `_debug.txt`, …) are written here, so
//! the entry point that owns the filesystem is whichever one the run used: real
//! files natively and under wasip1, the VFS in the browser.

use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec;
use alloc::vec::Vec;

use crate::driver::{Result, SimEngine, format_g, read_f64, write_f64};
use crate::{ReconInfo, ReconJac, ReconVar, SimMeta};
use crate::omclog;

/// C's `chisquaredvalue`: 199 tabulated values, the 200th left zero as its
/// `[200]` initializer does.
const CHI_SQUARED: [f64; 200] = [
    3.84146, 5.99146, 7.81473, 9.48773, 11.0705, 12.5916, 14.0671, 15.5073, 16.919, 18.307,
    19.6751, 21.0261, 22.362, 23.6848, 24.9958, 26.2962, 27.5871, 28.8693, 30.1435, 31.4104,
    32.6706, 33.9244, 35.1725, 36.415, 37.6525, 38.8851, 40.1133, 41.3371, 42.557, 43.773,
    44.9853, 46.1943, 47.3999, 48.6024, 49.8018, 50.9985, 52.1923, 53.3835, 54.5722, 55.7585,
    56.9424, 58.124, 59.3035, 60.4809, 61.6562, 62.8296, 64.0011, 65.1708, 66.3386, 67.5048,
    68.6693, 69.8322, 70.9935, 72.1532, 73.3115, 74.4683, 75.6237, 76.7778, 77.9305, 79.0819,
    80.2321, 81.381, 82.5287, 83.6753, 84.8206, 85.9649, 87.1081, 88.2502, 89.3912, 90.5312,
    91.6702, 92.8083, 93.9453, 95.0815, 96.2167, 97.351, 98.4844, 99.6169, 100.749, 101.879,
    103.01, 104.139, 105.267, 106.395, 107.522, 108.648, 109.773, 110.898, 112.022, 113.145,
    114.268, 115.39, 116.511, 117.632, 118.752, 119.871, 120.99, 122.108, 123.225, 124.342,
    125.458, 126.574, 127.689, 128.804, 129.918, 131.031, 132.144, 133.257, 134.369, 135.48,
    136.591, 137.701, 138.811, 139.921, 141.03, 142.138, 143.246, 144.354, 145.461, 146.567,
    147.674, 148.779, 149.885, 150.989, 152.094, 153.198, 154.302, 155.405, 156.508, 157.61,
    158.712, 159.814, 160.915, 162.016, 163.116, 164.216, 165.316, 166.415, 167.514, 168.613,
    169.711, 170.809, 171.907, 173.004, 174.101, 175.198, 176.294, 177.39, 178.485, 179.581,
    180.676, 181.77, 182.865, 183.959, 185.052, 186.146, 187.239, 188.332, 189.424, 190.516,
    191.608, 192.7, 193.791, 194.883, 195.973, 197.064, 198.154, 199.244, 200.334, 201.423,
    202.513, 203.602, 204.69, 205.779, 206.867, 207.955, 209.042, 210.13, 211.217, 212.304,
    213.391, 214.477, 215.563, 216.649, 217.735, 218.82, 219.906, 220.991, 222.076, 223.16,
    224.245, 225.329, 226.413, 227.496, 228.58, 229.663, 230.746, 231.829, 232.912, 0.0,
];

/// C's `lambda`, the 95% two-sided normal quantile.
const LAMBDA: f64 = 1.96;

// ───────────────────────────── matrices ─────────────────────────────

/// A column-major matrix, C's `matrixData`.
#[derive(Clone, Debug, Default)]
struct Matrix {
    rows: usize,
    cols: usize,
    data: Vec<f64>,
}

impl Matrix {
    fn zeros(rows: usize, cols: usize) -> Matrix {
        Matrix { rows, cols, data: vec![0.0; rows * cols] }
    }

    fn column(rows: usize, data: Vec<f64>) -> Matrix {
        Matrix { rows, cols: 1, data }
    }

    fn at(&self, i: usize, j: usize) -> f64 {
        self.data[i + j * self.rows]
    }

    /// C's `getTransposeMatrix`.
    fn transpose(&self) -> Matrix {
        let mut out = Matrix::zeros(self.cols, self.rows);
        let mut k = 0;
        for i in 0..self.rows {
            for j in 0..self.cols {
                out.data[k] = self.at(i, j);
                k += 1;
            }
        }
        out
    }

    /// C's `getDiagonalElements`.
    fn diagonal(&self) -> Matrix {
        let mut out = Vec::new();
        for i in 0..self.rows {
            for j in 0..self.cols {
                if i == j {
                    out.push(self.at(i, j));
                }
            }
        }
        Matrix::column(out.len(), out)
    }

    fn scale(&mut self, alpha: f64) {
        for v in &mut self.data {
            *v *= alpha;
        }
    }

    fn sqrt_elements(&mut self) {
        for v in &mut self.data {
            *v = libm::sqrt(*v);
        }
    }
}

/// C's `initColumnMatrix`: a row-major vector read out in column order.
fn init_column_matrix(data: &[f64], rows: usize, cols: usize) -> Matrix {
    let mut out = Matrix::zeros(rows, cols);
    for i in 0..rows {
        for j in 0..cols {
            out.data[j + i * rows] = data[i + j * rows];
        }
    }
    out
}

// ───────────────────────────── the report context ─────────────────────────────

/// C's error handling: every failure prints on `OMC_LOG_STDOUT`, appends to the
/// debug log, writes the error HTML report and calls `exit(1)`. The exit becomes
/// this error, which the caller turns into a failed run.
const ABORTED: &str = "dataReconciliation: aborted";

/// Which of the three procedures is running, C's three `omc_flag` tests.
#[derive(Clone, Copy, PartialEq, Eq)]
struct Mode {
    reconcile: bool,
    boundary: bool,
    state: bool,
}

/// Everything the procedures share: the model view, the flags' file names and the
/// debug log C keeps open across the whole run.
struct Ctx<'a> {
    model: &'a SimMeta,
    recon: &'a ReconInfo,
    sim_data: u32,
    mode: Mode,
    sx_file: Option<String>,
    cx_file: Option<String>,
    output_path: Option<String>,
    /// C's `ofstream logfile`; written out when the procedure ends, or aborts.
    log: String,
    /// Path of the debug log, so an abort can flush it.
    log_path: String,
}

impl Ctx<'_> {
    fn prefix(&self) -> &str {
        &self.model.prefix
    }

    /// C's `omc_flag[FLAG_OUTPUT_PATH] ? path + "/" + name : name`.
    fn out_path(&self, name: &str) -> String {
        match &self.output_path {
            Some(dir) => format!("{dir}/{name}"),
            None => name.to_string(),
        }
    }

    /// A file named after the model, under `-outputPath`.
    fn model_file(&self, suffix: &str) -> String {
        self.out_path(&format!("{}{suffix}", self.prefix()))
    }

    fn log_line(&mut self, level: &str, msg: &str) {
        self.log.push_str(&format!("|  {level}   |   {msg}\n"));
    }

    /// C's `errorStreamPrint(OMC_LOG_STDOUT, ...)` + the matching log line.
    fn error(&mut self, msg: &str) {
        omclog::error(omclog::STDOUT, false, msg);
        self.log_line("error", msg);
    }

    /// The same where C's `printf` text and its log line differ.
    fn error2(&mut self, out: &str, log: &str) {
        omclog::error(omclog::STDOUT, false, out);
        self.log_line("error", log);
    }

    /// C's `logfile.close(); createErrorHtmlReport(data); exit(1)`.
    fn abort(&mut self) -> &'static str {
        self.flush_log();
        if self.mode.boundary {
            create_error_html_report_boundary(self, 0);
        } else {
            create_error_html_report(self, 0);
        }
        ABORTED
    }

    /// C's `-eps`, defaulting to `1e-10`.
    fn sx_eps(&self) -> f64 {
        crate::simflags::with_flags(|f| f.recon_eps.clone())
            .map_or(0.0000000001, |v| atof(&v))
    }

    fn flush_log(&mut self) {
        let path = self.log_path.clone();
        write_file(&path, &self.log);
    }
}

/// Write a file, reporting nothing: C's `ofstream` failures are silent too.
fn write_file(path: &str, content: &str) {
    let _ = std::fs::write(path, content);
}

fn read_file(path: &str) -> Option<String> {
    std::fs::read(path).ok().map(|b| String::from_utf8_lossy(&b).into_owned())
}

/// C's `copyReferenceFile`: the code generator writes its reference HTML next to
/// the model, `-outputPath` wants a copy.
fn copy_reference_file(ctx: &Ctx, suffix: &str) {
    if ctx.output_path.is_none() {
        return;
    }
    let src = format!("{}{suffix}", ctx.prefix());
    if let Some(content) = read_file(&src) {
        write_file(&ctx.model_file(suffix), &content);
    }
}

// ───────────────────────────── formatting ─────────────────────────────

/// C++'s `ostream << double`: `%g` at the default precision of 6.
fn num(v: f64) -> String {
    format_g(v, 6)
}

/// `std::right << setw(n) << v`.
fn numw(v: f64, width: usize) -> String {
    pad(&num(v), width)
}

/// A header the file may not have supplied; C would read past the vector.
fn header(headers: &[String], i: usize) -> &str {
    headers.get(i).map_or("", |s| s.as_str())
}

fn pad(s: &str, width: usize) -> String {
    if s.len() >= width { s.to_string() } else { format!("{s:>width$}") }
}

// ───────────────────────────── linear algebra ─────────────────────────────

/// Reference BLAS `dgemm_('N','N', …, alpha=1, beta=0)`: `C = A*B`, column-major.
fn matmul(ctx: &mut Ctx, a: &Matrix, b: &Matrix) -> Result<Matrix> {
    if a.cols != b.rows {
        let msg = format!(
            "solveMatrixMultiplication() Failed!, Column of First Matrix not equal to Rows of Second Matrix {} != {}.",
            a.cols, b.rows
        );
        ctx.error(&msg);
        return Err(ctx.abort());
    }
    let mut out = Matrix::zeros(a.rows, b.cols);
    for j in 0..b.cols {
        for l in 0..a.cols {
            let t = b.at(l, j);
            if t == 0.0 {
                continue;
            }
            for i in 0..a.rows {
                out.data[i + j * a.rows] += t * a.at(i, l);
            }
        }
    }
    Ok(out)
}

/// C's `solveSystemFstar`: `dgesv_`, `a` and `b` overwritten.
fn solve_system(ctx: &mut Ctx, n: usize, nrhs: usize, a: &mut Matrix, b: &mut Matrix) -> Result<()> {
    let mut ipiv = vec![0i32; n.max(1)];
    let info = openmodelica_lapack::lu::dgesv(n, nrhs, &mut a.data, n, &mut ipiv, &mut b.data, n);
    if info > 0 {
        let msg = format!(
            "solveSystemFstar() Failed !, The solution could not be computed, The info satus is {info} "
        );
        ctx.error(&msg);
        return Err(ctx.abort());
    }
    Ok(())
}

/// C's `solveMatrixSubtraction`, element-wise over the column-major storage.
fn sub(ctx: &mut Ctx, a: &Matrix, b: &Matrix) -> Result<Matrix> {
    if a.rows != b.rows && a.cols != b.cols {
        let msg = format!(
            "solveMatrixSubtraction() Failed !, The Matrix Dimensions are not equal to Compute ! {} != {}.",
            a.rows, b.rows
        );
        ctx.error(&msg);
        return Err(ctx.abort());
    }
    let data = a.data.iter().zip(&b.data).map(|(x, y)| x - y).collect();
    Ok(Matrix { rows: a.rows, cols: a.cols, data })
}

/// C's `solveMatrixAddition`.
fn add(ctx: &mut Ctx, a: &Matrix, b: &Matrix) -> Result<Matrix> {
    if a.rows != b.rows && a.cols != b.cols {
        let msg = format!(
            "solveMatrixAddition() Failed !, The Matrix Dimensions are not equal to Compute ! {} != {}.",
            a.rows, b.rows
        );
        ctx.error(&msg);
        return Err(ctx.abort());
    }
    let data = a.data.iter().zip(&b.data).map(|(x, y)| x + y).collect();
    Ok(Matrix { rows: a.rows, cols: a.cols, data })
}

// ───────────────────────────── debug-log printers ─────────────────────────────

/// C's `printMatrix`.
fn print_matrix(log: &mut String, m: &Matrix, name: &str) {
    log.push_str(&format!("\n************ {name} **********\n"));
    for i in 0..m.rows {
        for j in 0..m.cols {
            log.push_str(&numw(m.at(i, j), 15));
        }
        log.push('\n');
    }
    log.push('\n');
}

/// C's `printMatrixWithHeaders`.
fn print_matrix_headers(log: &mut String, m: &Matrix, headers: &[String], name: &str) {
    log.push_str(&format!("\n************ {name} **********\n"));
    for i in 0..m.rows {
        log.push_str(&pad(header(headers, i), 10));
        for j in 0..m.cols {
            log.push_str(&numw(m.at(i, j), 15));
        }
        log.push('\n');
    }
    log.push('\n');
}

/// C's `printVectorMatrixWithHeaders`; the vector is one column.
fn print_vector_headers(log: &mut String, v: &[f64], rows: usize, headers: &[String], name: &str) {
    log.push_str(&format!("\n************ {name} **********\n"));
    for i in 0..rows {
        log.push_str(&pad(header(headers, i), 10));
        log.push_str(&numw(v[i], 15));
        log.push('\n');
    }
    log.push('\n');
}

/// C's `printBoundaryConditionsResults`.
fn print_boundary_results(log: &mut String, a: &Matrix, b: &Matrix, headers: &[String], name: &str) {
    log.push_str(&format!("\n************ {name} **********\n"));
    log.push_str(&format!("\n Boundary conditions{}{}\n", pad("Values", 20), pad("Half-width Confidence Interval", 45)));
    for i in 0..a.rows.min(b.rows) {
        log.push_str(&pad(header(headers, i), 20));
        for j in 0..a.cols.min(b.cols) {
            log.push_str(&numw(a.at(i, j), 20));
            log.push_str(&numw(b.at(i, j), 25));
        }
        log.push('\n');
    }
    log.push('\n');
}

/// C's `printCorelationMatrix`, which also collects the entries it ignores.
fn print_correlation_matrix(log: &mut String, cx: &CorrelationData, name: &str, warn: &mut CorrelationWarnings) {
    if cx.data.is_empty() {
        return;
    }
    log.push_str(&format!("\n************ {name} **********\n"));
    let ncol = cx.column_headers.len();
    for i in 0..cx.row_headers.len() {
        log.push_str(&pad(&cx.row_headers[i], 10));
        for j in 0..ncol {
            let v = cx.data[ncol * i + j];
            if i == j && v != 0.0 {
                warn.diagonal.push(cx.row_headers[i].clone());
            } else if j > i && v != 0.0 {
                warn.above_diagonal.push(cx.row_headers[i].clone());
            }
            log.push_str(&numw(v, 15));
        }
        log.push('\n');
    }
    log.push('\n');
}

// ───────────────────────────── csv input ─────────────────────────────

/// C's `csvData`.
#[derive(Clone, Debug, Default)]
struct CsvData {
    rowcount: usize,
    xdata: Vec<f64>,
    sxdata: Vec<f64>,
    headers: Vec<String>,
}

/// C's `correlationData`.
#[derive(Clone, Debug, Default)]
struct CorrelationData {
    data: Vec<f64>,
    row_headers: Vec<String>,
    column_headers: Vec<String>,
}

/// C's `errorData`: the three columns an offending entry had.
#[derive(Clone, Debug)]
struct ErrorData {
    name: String,
    x: String,
    sx: String,
}

/// C's `correlationDataWarning`.
#[derive(Clone, Debug, Default)]
struct CorrelationWarnings {
    diagonal: Vec<String>,
    above_diagonal: Vec<String>,
    info: Vec<ErrorData>,
}

impl CorrelationWarnings {
    fn is_empty(&self) -> bool {
        self.diagonal.is_empty() && self.above_diagonal.is_empty() && self.info.is_empty()
    }
}

/// The lines `while (ip.good()) getline(ip, line)` yields: one per `\n`-terminated
/// line, plus the empty one the final failed extraction leaves behind.
fn getlines(text: &str) -> Vec<&str> {
    text.split('\n').collect()
}

/// The fields `while (getline(ss, temp, ','))` yields.
fn csv_fields(line: &str) -> Vec<&str> {
    if line.is_empty() {
        return Vec::new();
    }
    let mut f: Vec<&str> = line.split(',').collect();
    if line.ends_with(',') {
        f.pop();
    }
    f
}

/// C's `isStringValidDouble`: `[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?`, anchored.
fn is_valid_double(s: &str) -> bool {
    let b = s.as_bytes();
    let mut i = 0;
    if i < b.len() && (b[i] == b'-' || b[i] == b'+') {
        i += 1;
    }
    let int_start = i;
    while i < b.len() && b[i].is_ascii_digit() {
        i += 1;
    }
    let int_digits = i - int_start;
    let mut frac_digits = 0;
    if i < b.len() && b[i] == b'.' {
        i += 1;
        let start = i;
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
        }
        frac_digits = i - start;
        // `[0-9]*\.?[0-9]+` needs at least one digit after the point.
        if frac_digits == 0 {
            return false;
        }
    } else if int_digits == 0 {
        return false;
    }
    if int_digits == 0 && frac_digits == 0 {
        return false;
    }
    if i < b.len() && (b[i] == b'e' || b[i] == b'E') {
        i += 1;
        if i < b.len() && (b[i] == b'-' || b[i] == b'+') {
            i += 1;
        }
        let start = i;
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
        }
        if i == start {
            return false;
        }
    }
    i == b.len()
}

/// C's `isLineEmptyData`: a line that starts with `,`, `|` or `/`.
fn is_line_empty_data(line: &str) -> bool {
    matches!(line.as_bytes().first(), Some(b',' | b'|' | b'/'))
}

/// C's `atof`: leading numeric prefix, 0 when there is none.
fn atof(s: &str) -> f64 {
    let t = s.trim_start();
    let mut end = 0;
    let b = t.as_bytes();
    let mut i = 0;
    if i < b.len() && (b[i] == b'-' || b[i] == b'+') {
        i += 1;
    }
    while i < b.len() && b[i].is_ascii_digit() {
        i += 1;
        end = i;
    }
    if i < b.len() && b[i] == b'.' {
        i += 1;
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
            end = i;
        }
    }
    if end > 0 && i < b.len() && (b[i] == b'e' || b[i] == b'E') {
        let mut j = i + 1;
        if j < b.len() && (b[j] == b'-' || b[j] == b'+') {
            j += 1;
        }
        let start = j;
        while j < b.len() && b[j].is_ascii_digit() {
            j += 1;
        }
        if j > start {
            end = j;
        }
    }
    t[..end].parse().unwrap_or(0.0)
}

/// C's line preparation: `;` counts as a separator, and all whitespace is dropped.
fn normalize_line(line: &str) -> String {
    line.chars().filter(|c| !c.is_ascii_whitespace()).map(|c| if c == ';' { ',' } else { c }).collect()
}

/// C's `isUnmeasuredVariables`.
fn is_unmeasured(ctx: &Ctx, name: &str) -> bool {
    ctx.recon.setb_vars.iter().any(|v| v.name == name)
}

/// C's `readMeasurementInputFile`.
fn read_measurement_input_file(ctx: &mut Ctx) -> Result<CsvData> {
    let Some(filename) = ctx.sx_file.clone() else {
        let msg = if ctx.mode.boundary {
            "Reconciled values input file not provided (eg:-sx=filename.csv), Boundary conditions cannot be computed!."
        } else {
            "Measurement input file not provided (eg:-sx=filename.csv), DataReconciliation cannot be computed!."
        };
        ctx.error(msg);
        return Err(ctx.abort());
    };
    let path = crate::driver::uri_to_filename(&filename);
    let Some(text) = read_file(&path) else {
        let msg = if ctx.mode.boundary {
            format!("Reconciled values input file path not found {filename}.")
        } else {
            format!("Measurement input file path not found {filename}.")
        };
        ctx.error(&msg);
        return Err(ctx.abort());
    };

    let mut xdata = Vec::new();
    let mut sxdata = Vec::new();
    let mut names: Vec<String> = Vec::new();
    let mut row_count = 0usize;
    let mut linecount = 1usize;
    let mut error_info: Vec<ErrorData> = Vec::new();
    let mut error_headers: Vec<usize> = Vec::new();

    for raw in getlines(&text) {
        // Comments are allowed above the header row, and do not count as lines.
        if linecount == 1 && is_line_empty_data(raw) {
            continue;
        }
        if linecount > 1 && !raw.is_empty() && !is_line_empty_data(raw) {
            let line = normalize_line(raw);
            let (mut col0, mut col1, mut col2) = (false, false, false);
            for (column_count, field) in csv_fields(&line).into_iter().enumerate() {
                // A variable that is not measured is not read from this file.
                if column_count == 0 && is_unmeasured(ctx, field) {
                    col0 = true;
                    col1 = true;
                    col2 = true;
                    break;
                }
                if column_count == 0 {
                    if field.is_empty() {
                        error_headers.push(linecount);
                    }
                    col0 = true;
                    names.push(field.to_string());
                    row_count += 1;
                }
                if column_count == 1 && !field.is_empty() && is_valid_double(field) {
                    col1 = true;
                    xdata.push(atof(field));
                }
                if column_count == 2 && !field.is_empty() && is_valid_double(field) {
                    col2 = true;
                    sxdata.push(atof(field));
                }
                if column_count > 2 {
                    break;
                }
            }
            if !col0 || !col1 || !col2 {
                let bad = "(no-Value/wrong-Type)".to_string();
                error_info.push(ErrorData {
                    name: if col0 { names.last().cloned().unwrap_or_default() } else { bad.clone() },
                    x: if col1 { to_string_c(*xdata.last().unwrap_or(&0.0)) } else { bad.clone() },
                    sx: if col2 { to_string_c(*sxdata.last().unwrap_or(&0.0)) } else { bad },
                });
            }
        }
        linecount += 1;
    }

    if !error_headers.is_empty() {
        for line in &error_headers {
            ctx.error2(
                &format!("the name of the variable of interest in measurement input file  {filename} is missing in line #{line} "),
                &format!("the name of the variable of interest in measurement input file {filename} is missing in line #{line}"),
            );
        }
        return Err(ctx.abort());
    }
    if !error_info.is_empty() {
        for info in &error_info {
            let body = format!(
                "Entry for variable of interest {} in measurement input file {filename} is incorrect because of (no-Value/wrong-Type), with following data: [{}, {}, {}]",
                info.name, info.name, info.x, info.sx
            );
            ctx.error2(&format!("{body} "), &body);
        }
        return Err(ctx.abort());
    }
    Ok(CsvData { rowcount: row_count, xdata, sxdata, headers: names })
}

/// C++'s `std::to_string(double)`: `%f`, six decimals.
fn to_string_c(v: f64) -> String {
    format!("{v:.6}")
}

/// C's `validateCorelationInputs`: every header the correlation file names must be
/// a variable of interest, exactly once.
fn validate_correlation_inputs(
    ctx: &mut Ctx,
    sx: &CsvData,
    headers: &[String],
    comments: &str,
) -> Result<()> {
    let mut no_entry: Vec<String> = Vec::new();
    let mut multiple_entry: Vec<String> = Vec::new();
    let mut entry: Vec<String> = Vec::new();
    for h in headers {
        let mut flag = false;
        for other in &sx.headers {
            if h == other {
                flag = true;
                if entry.contains(h) {
                    multiple_entry.push(h.clone());
                } else {
                    entry.push(h.clone());
                }
            }
        }
        if !flag {
            no_entry.push(h.clone());
        }
    }
    let cx = ctx.cx_file.clone().unwrap_or_default();
    let what = if ctx.mode.boundary { "reconciled covariance matrix input file" } else { "correlation input file" };
    for name in &multiple_entry {
        ctx.error2(
            &format!("variable of interest {name}, at {comments} has multiple entries in {what} {cx} "),
            &format!("variable of interest {name} at {comments} has multiple entries in {what} {cx}"),
        );
    }
    for name in &no_entry {
        ctx.error2(
            &format!("variable of interest {name}, at {comments} entry in {what} {cx} does not correspond to a variable of interest "),
            &format!("variable of interest {name}, at {comments} entry in {what} {cx} does not correspond to a variable of interest"),
        );
    }
    if !no_entry.is_empty() || !multiple_entry.is_empty() {
        return Err(ctx.abort());
    }
    Ok(())
}

/// C's `validateCorelationInputsSquareMatrix`.
fn validate_correlation_square(ctx: &mut Ctx, rows: &[String], cols: &[String]) -> Result<()> {
    if rows == cols {
        return Ok(());
    }
    let cx = ctx.cx_file.clone().unwrap_or_default();
    let (what, kind) = if ctx.mode.boundary {
        ("reconciled covariance matrix input file", "covariance matrix")
    } else {
        ("correlation input file", "correlation matrix")
    };
    ctx.error2(
        &format!("Lines and columns of {kind} in {what}  {cx}, do not have identical names in the same order."),
        &format!("Lines and columns of {kind} in {what} {cx} do not have identical names in the same order."),
    );
    for name in cols {
        if !rows.contains(name) {
            ctx.error2(&format!("Line {name} is missing"), &format!("Line {name} is missing "));
        }
    }
    for name in rows {
        if !cols.contains(name) {
            ctx.error2(&format!("Column {name} is missing"), &format!("Column {name} is missing "));
        }
    }
    for (i, r) in rows.iter().enumerate() {
        if cols.get(i) != Some(r) {
            let c = cols.get(i).cloned().unwrap_or_default();
            ctx.error(&format!("Lines and columns are in different orders {r} Vs {c}"));
        }
    }
    Err(ctx.abort())
}

/// C's `readCorrelationCoefficientFile`.
fn read_correlation_file(
    ctx: &mut Ctx,
    sx: &CsvData,
    warn: &mut CorrelationWarnings,
) -> Result<CorrelationData> {
    let Some(filename) = ctx.cx_file.clone() else {
        if !ctx.mode.boundary {
            return Ok(CorrelationData::default());
        }
        ctx.error("Reconciled covariance matrix input file not provided (eg:-cx=filename.csv), Boundary conditions cannot be computed!.");
        return Err(ctx.abort());
    };
    let path = crate::driver::uri_to_filename(&filename);
    let Some(text) = read_file(&path) else {
        let msg = if ctx.mode.boundary {
            format!("Reconciled covariance matrix input file path not found {filename}.")
        } else {
            format!("correlation coefficient input file path not found {filename}.")
        };
        ctx.error(&msg);
        return Err(ctx.abort());
    };

    let mut column_headers: Vec<String> = Vec::new();
    let mut row_headers: Vec<String> = Vec::new();
    let mut cx_data: Vec<f64> = Vec::new();
    let mut error_info: Vec<ErrorData> = Vec::new();
    let mut error_headers: Vec<usize> = Vec::new();
    let mut linecount = 1usize;

    for raw in getlines(&text) {
        let line = normalize_line(raw);
        if linecount == 1 && is_line_empty_data(&line) {
            continue;
        }
        if linecount == 1 && !line.is_empty() {
            for (i, field) in csv_fields(&line).into_iter().enumerate() {
                if i > 0 {
                    column_headers.push(field.to_string());
                }
            }
        } else if linecount > 1 && !line.is_empty() && !is_line_empty_data(&line) {
            let fields = csv_fields(&line);
            let n = fields.len();
            for (i, field) in fields.into_iter().enumerate() {
                if i == 0 {
                    if field.is_empty() {
                        error_headers.push(linecount);
                    }
                    row_headers.push(field.to_string());
                } else if field.is_empty() {
                    cx_data.push(0.0);
                } else if !is_valid_double(field) {
                    error_info.push(ErrorData {
                        name: row_headers.last().cloned().unwrap_or_default(),
                        x: column_headers.get(i - 1).cloned().unwrap_or_default(),
                        sx: field.to_string(),
                    });
                } else if atof(field) > 0.99 && atof(field) < 1.01 {
                    warn.info.push(ErrorData {
                        name: row_headers.last().cloned().unwrap_or_default(),
                        x: column_headers.get(i - 1).cloned().unwrap_or_default(),
                        sx: field.to_string(),
                    });
                    cx_data.push(atof(field));
                } else {
                    cx_data.push(atof(field));
                }
            }
            // Short rows are filled with zeros.
            if n.saturating_sub(1) < column_headers.len() {
                for _ in 0..column_headers.len() - n.saturating_sub(1) {
                    cx_data.push(0.0);
                }
            }
        }
        linecount += 1;
    }

    let what = if ctx.mode.boundary { "reconciled covariance matrix input file" } else { "correlation input file" };
    if !error_headers.is_empty() {
        for line in &error_headers {
            ctx.error2(
                &format!("the name of the variable of interest in {what}  {filename} is missing in line #{line} "),
                &format!("the name of the variable of interest in {what} {filename} is missing in line #{line}"),
            );
        }
        return Err(ctx.abort());
    }
    if !error_info.is_empty() {
        for info in &error_info {
            let body = format!(
                "Entry for variable of interest {} and variable of interest {} in {what} {filename} is incorrect because of wrong-Type: [{}]",
                info.name, info.x, info.sx
            );
            ctx.error2(&format!("{body} "), &body);
        }
        return Err(ctx.abort());
    }
    for info in &warn.info {
        let msg = format!(
            "Entry for variable of interest {} and variable of interest {} in correlation input file {filename} is closer to 1: [{}] ",
            info.name, info.x, info.sx
        );
        omclog::warning(omclog::STDOUT, false, &msg);
    }

    validate_correlation_inputs(ctx, sx, &column_headers.clone(), "column headers")?;
    validate_correlation_inputs(ctx, sx, &row_headers.clone(), "row headers")?;
    validate_correlation_square(ctx, &row_headers, &column_headers)?;

    Ok(CorrelationData { data: cx_data, row_headers, column_headers })
}

/// C's `getVariableIndex`.
fn variable_index(ctx: &mut Ctx, headers: &[String], name: &str) -> Result<usize> {
    match headers.iter().position(|h| h == name) {
        Some(pos) => Ok(pos),
        None => {
            ctx.log_line("error", &format!("CoRelation-Coefficient Variable Name not Matched:  {name} ,getVariableIndex() failed!"));
            ctx.flush_log();
            Err(ABORTED)
        }
    }
}

/// C's `computeCovarianceMatrixSx`: `Sx = diag((Wx/1.96)^2)`, plus the correlated
/// off-diagonal entries the `-cx` file names.
fn compute_covariance_sx(ctx: &mut Ctx, sx: &CsvData, cx: &CorrelationData) -> Result<Matrix> {
    let n = sx.sxdata.len();
    let mut tmp = vec![0.0; n * n];
    for i in 0..n {
        let d = libm::pow(sx.sxdata[i] / LAMBDA, 2.0);
        for j in 0..n {
            tmp[i * n + j] = if i == j { d } else { 0.0 };
        }
    }
    if !cx.data.is_empty() {
        let ncol = cx.column_headers.len();
        for i in 0..cx.row_headers.len() {
            for j in 0..ncol {
                // Only entries strictly below the diagonal are read.
                if j < i && cx.data[ncol * i + j] != 0.0 {
                    let rowpos = variable_index(ctx, &sx.headers, &cx.row_headers[i].clone())?;
                    let colpos = variable_index(ctx, &sx.headers, &cx.column_headers[j].clone())?;
                    let xi = tmp[sx.rowcount * rowpos + rowpos];
                    let xk = tmp[sx.rowcount * colpos + colpos];
                    let v = cx.data[ncol * i + j] * libm::sqrt(xi) * libm::sqrt(xk);
                    tmp[sx.rowcount * rowpos + colpos] = v;
                    tmp[sx.rowcount * colpos + rowpos] = v;
                }
            }
        }
    }
    Ok(init_column_matrix(&tmp, sx.rowcount, sx.rowcount))
}

/// C's `validateMeasurementInputs`: the file must name every variable of interest
/// exactly once; the rows are then reordered into the model's order.
fn validate_measurement_inputs(ctx: &mut Ctx, mut sx: CsvData) -> Result<CsvData> {
    let n_recon = ctx.recon.input_vars.len();
    let sx_file = ctx.sx_file.clone().unwrap_or_default();
    if n_recon != sx.headers.len() {
        ctx.error2(
            &format!(
                "invalid input file {sx_file}, number of variable of interest({n_recon}) != ({})number of variables in measurement input file",
                sx.headers.len()
            ),
            &format!(
                "invalid input file {sx_file}, number of variable of interest({n_recon}) != ({})number of variables in measurement input file",
                sx.headers.len()
            ),
        );
        // C leaves this one without the trailing newline it gives the others.
        self_trim_last_newline(&mut ctx.log);
        return Err(ctx.abort());
    }

    let knowns: Vec<String> = ctx.recon.input_vars.iter().map(|v| v.name.clone()).collect();
    let mut no_entry: Vec<String> = Vec::new();
    let mut multiple_entry: Vec<String> = Vec::new();
    let mut mapindex: Vec<usize> = Vec::new();
    for known in &knowns {
        let mut count = 0;
        for (j, h) in sx.headers.iter().enumerate() {
            if known == h {
                mapindex.push(j);
                count += 1;
            }
        }
        if count == 0 {
            no_entry.push(known.clone());
        }
        if count > 1 {
            multiple_entry.push(known.clone());
        }
    }
    for name in &no_entry {
        ctx.error2(
            &format!("variable of interest {name}, has no entry in measurement input file {sx_file} "),
            &format!("variable of interest {name}, has no entry in measurement input file{sx_file}"),
        );
    }
    for name in &multiple_entry {
        ctx.error2(
            &format!("variable of interest {name}, has multiple entries in measurement input file {sx_file} "),
            &format!("variable of interest {name}, has multiple entries in measurement input file {sx_file}"),
        );
    }
    // C's user error #5, indexing the headers by the *model's* variable count.
    let mut user_error5 = false;
    for i in 0..n_recon {
        if !mapindex.contains(&i) {
            user_error5 = true;
            let name = sx.headers.get(i).cloned().unwrap_or_default();
            ctx.error2(
                &format!("variable of interest {name}, entry in measurement input file {sx_file} does not correspond to a variable of interest "),
                &format!("variable of interest {name}, entry in measurement input file {sx_file} does not correspond to a variable of interest"),
            );
        }
    }
    if !no_entry.is_empty() || !multiple_entry.is_empty() || user_error5 {
        return Err(ctx.abort());
    }

    let mapped_x: Vec<f64> = mapindex.iter().map(|&i| sx.xdata[i]).collect();
    let mapped_sx: Vec<f64> = mapindex.iter().map(|&i| sx.sxdata[i]).collect();
    let mapped_h: Vec<String> = mapindex.iter().map(|&i| sx.headers[i].clone()).collect();
    sx.xdata = mapped_x;
    sx.sxdata = mapped_sx;
    sx.headers = mapped_h;
    Ok(sx)
}

fn self_trim_last_newline(log: &mut String) {
    if log.ends_with('\n') {
        log.pop();
    }
}

// ───────────────────────────── the model ─────────────────────────────

fn read_var(e: &dyn SimEngine, sim_data: u32, v: &ReconVar) -> Result<f64> {
    Ok(v.negate.apply_f64(read_f64(e, sim_data + v.off)?))
}

fn write_var(e: &mut dyn SimEngine, sim_data: u32, v: &ReconVar, value: f64) -> Result<()> {
    write_f64(e, sim_data + v.off, v.negate.apply_f64(value))
}

/// C's `data_function` + `functionDAE`: publish the measured values and re-solve.
fn set_inputs_and_solve(e: &mut dyn SimEngine, ctx: &Ctx, x: &[f64]) -> Result<()> {
    for (v, value) in ctx.recon.input_vars.iter().zip(x) {
        write_var(e, ctx.sim_data, v, *value)?;
    }
    e.call1("functionDAE", ctx.sim_data)
}

/// C's `setc_function` / `setb_function`, read straight out of `SimData`.
fn read_set(e: &dyn SimEngine, sim_data: u32, vars: &[ReconVar]) -> Result<Vec<f64>> {
    vars.iter().map(|v| read_var(e, sim_data, v)).collect()
}

/// C's `getJacobianMatrixF` / `getJacobianMatrixH`: the export fills the whole
/// matrix, column-major, exactly as C's per-column seed loop does.
fn jacobian(ctx: &mut Ctx, e: &mut dyn SimEngine, which: char) -> Result<Matrix> {
    let (jac, export) = match which {
        'F' => (ctx.recon.jac_f.clone(), "reconJacF"),
        _ => (ctx.recon.jac_h.clone(), "reconJacH"),
    };
    let Some(ReconJac { rows, cols, off }) = jac.filter(|j| j.cols != 0) else {
        let msg = format!("Cannot Compute Jacobian Matrix {which}");
        ctx.error(&msg);
        return Err(ctx.abort());
    };
    e.call1(export, ctx.sim_data)?;
    let mut m = Matrix::zeros(rows as usize, cols as usize);
    for (i, slot) in m.data.iter_mut().enumerate() {
        *slot = read_f64(e, ctx.sim_data + off + (i as u32) * 8)?;
    }
    Ok(m)
}

// ───────────────────────────── the D.1 numerics ─────────────────────────────

fn log_jac() -> bool {
    omclog::active(omclog::JAC)
}

/// C's `solveReconciledX`: `recon_x = x - (Sx*Ft*f*)`.
fn solve_reconciled_x(ctx: &mut Ctx, x: &Matrix, sx: &Matrix, ft: &Matrix, fstar: &Matrix) -> Result<Matrix> {
    let a = matmul(ctx, sx, ft)?;
    let b = matmul(ctx, &a, fstar)?;
    let recon = sub(ctx, x, &b)?;
    if log_jac() {
        ctx.log.push_str("Calculations of Reconciled_x ==> (x - (Sx*Ft*f*))\n");
        ctx.log.push_str("====================================================");
        print_matrix(&mut ctx.log, &a, "Sx*Ft");
        print_matrix(&mut ctx.log, &b, "(Sx*Ft*f*)");
        print_matrix(&mut ctx.log, &recon, "x - (Sx*Ft*f*))");
        ctx.log.push_str("***** Completed ****** \n\n");
    }
    Ok(recon)
}

/// C's `solveReconciledSx`: `recon_Sx = Sx - (Sx*Ft*F*)`.
fn solve_reconciled_sx(ctx: &mut Ctx, sx: &Matrix, ft: &Matrix, fstar: &Matrix) -> Result<Matrix> {
    let a = matmul(ctx, sx, ft)?;
    let b = matmul(ctx, &a, fstar)?;
    let recon = sub(ctx, sx, &b)?;
    if log_jac() {
        ctx.log.push_str("Calculations of Reconciled_Sx ===> (Sx - (Sx*Ft*F*))\n");
        ctx.log.push_str("============================================");
        print_matrix(&mut ctx.log, &a, "(Sx*Ft)");
        print_matrix(&mut ctx.log, &b, "(Sx*Ft*F*)");
        print_matrix(&mut ctx.log, &recon, "Sx - (Sx*Ft*F*))");
        ctx.log.push_str("***** Completed ****** \n\n");
    }
    Ok(recon)
}

/// C's `solveConvergence`:
/// `J* = (recon_x-x)T*(Sx^-1)*(recon_x-x) + 2*[f+F*(recon_x-x)]T*f*`, over `r`.
#[allow(clippy::too_many_arguments)]
fn solve_convergence(
    ctx: &mut Ctx,
    recon_x: &Matrix,
    x: &Matrix,
    sx: &mut Matrix,
    jac_f: &Matrix,
    vector_c: &Matrix,
    fstar: &Matrix,
) -> Result<f64> {
    let mut d = sub(ctx, recon_x, x)?;
    let copy_d = d.clone();
    let dt = d.transpose();
    let n = sx.rows;
    solve_system(ctx, n, 1, sx, &mut d)?;
    let lhs = matmul(ctx, &dt, &d)?;

    let f_d = matmul(ctx, jac_f, &copy_d)?;
    let sum = add(ctx, vector_c, &f_d)?;
    let sum_t = sum.transpose();
    let mut rhs = matmul(ctx, &sum_t, fstar)?;
    rhs.scale(2.0);

    let mut jstar = add(ctx, &lhs, &rhs)?;
    let r = ctx.recon.setc_vars.len() as f64;
    jstar.scale(1.0 / r);
    Ok(jstar.data[0])
}

/// C's `calculateQualityValue`:
/// `J = (recon_x - x)T * Sx^-1 * (recon_x - x)`.
fn calculate_quality_value(ctx: &mut Ctx, recon_x: &Matrix, sx: &Matrix, measured: &CsvData) -> Result<f64> {
    ctx.log.push_str("Calculations of Quality Value (J) \n");
    ctx.log.push_str("=================================\n");
    print_matrix(&mut ctx.log, recon_x, "reconciled_x");
    let measured_x = Matrix::column(measured.rowcount, measured.xdata.clone());
    print_matrix(&mut ctx.log, &measured_x, "measured_X");
    print_matrix(&mut ctx.log, sx, "Sx");
    let mut new_x = sub(ctx, recon_x, &measured_x)?;
    print_matrix(&mut ctx.log, &new_x, "x_reconciled - measured_X");
    let sub_copy = new_x.clone();
    let mut sx_copy = sx.clone();
    let n = sx.rows;
    solve_system(ctx, n, 1, &mut sx_copy, &mut new_x)?;
    print_matrix(&mut ctx.log, &new_x, "Sx-inverse");
    let jt = matmul(ctx, &sub_copy.transpose(), &new_x)?;
    print_matrix(&mut ctx.log, &jt, "J");
    Ok(jt.data[0])
}

/// What C's `dataReconciliationData` carries from D.1 into the state-estimation
/// report.
#[derive(Clone, Debug, Default)]
struct ReconciliationData {
    xdiag: Matrix,
    reconciled_x: Matrix,
    reconciled_sx: Matrix,
    recon_sx_diag: Matrix,
    new_x: Vec<f64>,
    iterations: i32,
    value: f64,
    j: f64,
}

/// C's `RunReconciliation`, its tail recursion written as the loop it is.
#[allow(clippy::too_many_arguments)]
fn run_reconciliation(
    ctx: &mut Ctx,
    e: &mut dyn SimEngine,
    x: &mut Matrix,
    sx: &Matrix,
    eps: f64,
    csvinputs: &CsvData,
    xdiag: &Matrix,
    sxdiag: &Matrix,
    warn: &CorrelationWarnings,
) -> Result<ReconciliationData> {
    let mut iterationcount = 1;
    loop {
        set_inputs_and_solve(e, ctx, &x.data)?;
        let setc_vars = ctx.recon.setc_vars.clone();
        let setc_raw = read_set(e, ctx.sim_data, &setc_vars)?;

        let jac_f = jacobian(ctx, e, 'F')?;
        let jac_ft = jac_f.transpose();
        print_matrix(&mut ctx.log, &jac_f, "F");
        print_matrix(&mut ctx.log, &jac_ft, "Ft");

        // C reads `setcVars` back to front.
        let nsetc = setc_raw.len();
        let setc: Vec<f64> = (0..nsetc).map(|t| setc_raw[nsetc - 1 - t]).collect();
        let vector_c = Matrix::column(nsetc, setc.clone());

        let matrix_c = matmul(ctx, &jac_f, sx)?;
        let matrix_d = matmul(ctx, &matrix_c, &jac_ft)?;
        let mut matrix_c1 = matrix_c.clone();
        let mut matrix_d1 = matrix_d.clone();

        if log_jac() {
            ctx.log.push_str("Calculations of Matrix (F*Sx*Ft) f* = c(x,y) \n");
            ctx.log.push_str("============================================\n");
            print_matrix(&mut ctx.log, &matrix_c, "F*Sx");
            print_matrix(&mut ctx.log, &matrix_d, "F*Sx*Ft");
            print_matrix(&mut ctx.log, &vector_c, "c(x,y)");
        }

        // (F*Sx*Ft) f* = c(x,y)
        let mut fstar = Matrix::column(nsetc, setc);
        let mut lhs = matrix_d;
        solve_system(ctx, jac_f.rows, 1, &mut lhs, &mut fstar)?;
        if log_jac() {
            print_matrix(&mut ctx.log, &fstar, "f*");
            ctx.log.push_str("***** Completed ****** \n\n");
        }

        let reconciled_x = solve_reconciled_x(ctx, x, sx, &jac_ft, &fstar)?;

        if log_jac() {
            ctx.log.push_str("Calculations of Matrix (F*Sx*Ft) F* = F*Sx \n");
            ctx.log.push_str("===============================================\n");
            print_matrix(&mut ctx.log, &matrix_c1, "F*Sx");
            print_matrix(&mut ctx.log, &matrix_d1, "F*Sx*Ft");
        }

        // (F*Sx*Ft) F* = (F*Sx)
        solve_system(ctx, jac_f.rows, sx.cols, &mut matrix_d1, &mut matrix_c1)?;
        if log_jac() {
            print_matrix(&mut ctx.log, &matrix_c1, "F*");
            ctx.log.push_str("***** Completed ****** \n\n");
        }

        let reconciled_sx = solve_reconciled_sx(ctx, sx, &jac_ft, &matrix_c1)?;

        let mut copy_sx = sx.clone();
        let value = solve_convergence(ctx, &reconciled_x, x, &mut copy_sx, &jac_f, &vector_c, &fstar)?;

        if value > eps {
            ctx.log.push_str(&format!("J*/r({}) > {}, Value not Converged \n", num(value), num(eps)));
            ctx.log.push_str("==========================================\n\n");
            ctx.log.push_str(&format!(
                "Running Convergence iteration: {iterationcount} with the following reconciled values:\n"
            ));
            ctx.log.push_str("========================================================================\n");
            print_matrix_headers(&mut ctx.log, &reconciled_x, &csvinputs.headers, "reconciled_X ===> (x - (Sx*Ft*fstar))");
            print_matrix_headers(&mut ctx.log, &reconciled_sx, &csvinputs.headers, "reconciled_Sx ===> (Sx - (Sx*Ft*Fstar))");
            x.data.copy_from_slice(&reconciled_x.data);
            iterationcount += 1;
            continue;
        }

        if value < eps && iterationcount == 1 {
            ctx.log.push_str(&format!(
                "J*/r({}) > {}, Convergence iteration not required \n\n",
                num(value),
                num(eps)
            ));
        } else {
            ctx.log.push_str("***** Value Converged, Convergence Completed******* \n\n");
        }

        let j = calculate_quality_value(ctx, &reconciled_x, sx, csvinputs)?;

        ctx.log.push_str("Final Results:\n");
        ctx.log.push_str("=============\n");
        ctx.log.push_str(&format!("Total Iteration to Converge               : {iterationcount}\n"));
        ctx.log.push_str(&format!("Final Converged Value(J*/r)               : {}\n", num(value)));
        ctx.log.push_str(&format!("Final value of the objective function (J) : {}\n", num(j)));
        ctx.log.push_str(&format!("Epsilon                                   : {}\n", num(eps)));
        print_matrix_headers(&mut ctx.log, &reconciled_x, &csvinputs.headers, "reconciled_X ===> (x - (Sx*Ft*fstar))");
        print_matrix_headers(&mut ctx.log, &reconciled_sx, &csvinputs.headers, "reconciled_Sx ===> (Sx - (Sx*Ft*Fstar))");

        dump_reconciled_sx_to_csv(ctx, &reconciled_sx, &csvinputs.headers);

        // W = 1.96*sqrt(diag(reconciled_Sx))
        let mut recon_sx_diag = reconciled_sx.diagonal();
        let sx_diag_copy = recon_sx_diag.clone();
        if log_jac() {
            ctx.log.push_str("Calculations of HalfWidth Confidence Interval \n");
            ctx.log.push_str("===============================================\n");
            print_matrix(&mut ctx.log, &recon_sx_diag, "reconciled-Sx_Diagonal");
        }
        recon_sx_diag.sqrt_elements();
        if log_jac() {
            print_matrix(&mut ctx.log, &recon_sx_diag, "reconciled-Sx_SquareRoot");
            ctx.log.push_str("*****Completed***********\n");
        }
        recon_sx_diag.scale(LAMBDA);
        print_matrix_headers(
            &mut ctx.log,
            &recon_sx_diag,
            &csvinputs.headers,
            "Wx-HalfWidth-Interval-(1.96)*sqrt(Sx_diagonal)",
        );

        // The individual tests: |recon_x - x| / sqrt(Sx - recon_Sx).
        let mut new_sx_diag = sub(ctx, sxdiag, &sx_diag_copy)?;
        if log_jac() {
            ctx.log.push_str("Calculations of Individual Tests \n");
            ctx.log.push_str("===============================================\n");
            print_matrix(&mut ctx.log, &new_sx_diag, "Sx-recon_Sx");
        }
        new_sx_diag.sqrt_elements();
        if log_jac() {
            print_matrix(&mut ctx.log, &new_sx_diag, "squareroot-newSx");
        }
        let mut new_x = sub(ctx, &reconciled_x, xdiag)?;
        for v in &mut new_x.data {
            *v = libm::fabs(*v);
        }
        if log_jac() {
            print_matrix(&mut ctx.log, &new_x, "recon_X - X");
            ctx.log.push_str("*********Completed***********\n");
        }
        for i in 0..xdiag.rows {
            let floor = libm::sqrt(sxdiag.data[i] / 10.0);
            new_x.data[i] /= if new_sx_diag.data[i] > floor { new_sx_diag.data[i] } else { floor };
        }
        print_matrix_headers(
            &mut ctx.log,
            &new_x,
            &csvinputs.headers,
            "IndividualTests_Value- (recon_x-x)/sqrt(Sx_diag)",
        );

        update_reconciled_mo(ctx, &csvinputs.headers, &reconciled_x.data);

        let data = ReconciliationData {
            xdiag: xdiag.clone(),
            reconciled_x,
            reconciled_sx,
            recon_sx_diag,
            new_x: new_x.data,
            iterations: iterationcount,
            value,
            j,
        };
        if ctx.mode.reconcile {
            create_html_report(ctx, csvinputs, &data, eps, warn, &BoundaryConditionData::default());
        }
        return Ok(data);
    }
}

/// C's `dumpReconciledSxToCSV`.
fn dump_reconciled_sx_to_csv(ctx: &Ctx, m: &Matrix, headers: &[String]) {
    let mut csv = String::from("Sxij,");
    for h in headers {
        csv.push_str(&format!("{h},"));
    }
    csv.push('\n');
    for i in 0..m.rows {
        csv.push_str(&format!("{},", headers[i]));
        for j in 0..m.cols {
            csv.push_str(&format!("{},", num(m.at(i, j))));
        }
        csv.push('\n');
    }
    write_file(&ctx.model_file("_Reconciled_Sx.csv"), &csv);
}

/// C's `updateReconciledMo`: the generated `_Reconciled_tmp.mo` with the
/// reconciled values substituted for its parameter bindings.
fn update_reconciled_mo(ctx: &mut Ctx, headers: &[String], reconciled_x: &[f64]) {
    let model_prefix = ctx.prefix().replace('.', "_");
    let tmp_mo = ctx.model_file("_Reconciled_tmp.mo");
    let out_mo = ctx.out_path(&format!("Reconciled_{model_prefix}.mo"));
    copy_reference_file(ctx, "_Reconciled_tmp.mo");

    let text = match read_file(&tmp_mo) {
        Some(t) => t,
        None => {
            // Optional: the user may not want the file, so this is only a warning.
            let msg = format!("Reconciled modelica file path not found {tmp_mo}.");
            omclog::warning(omclog::STDOUT, false, &msg);
            ctx.log.push_str(&format!("|  warning   |   Measurement input file path not found {tmp_mo}\n"));
            String::new()
        }
    };

    let mut out = String::new();
    let mut count = 1;
    let mut var_count = 1usize;
    for line in text.lines() {
        if count > 3 && var_count <= ctx.recon.input_vars.len() {
            let name = headers[var_count - 1].replace('.', "_");
            out.push_str(&format!("  parameter Real {name} = {};\n", num(reconciled_x[var_count - 1])));
            var_count += 1;
        } else {
            count += 1;
            out.push_str(line);
            out.push('\n');
        }
    }
    write_file(&out_mo, &out);
    let _ = std::fs::remove_file(&tmp_mo);
    ctx.log.push_str(&format!("|  info    |   Reconciled modelica file updated successfully {out_mo}\n"));
}

// ───────────────────────────── html reports ─────────────────────────────

/// C's `ctime(&now)`, trailing newline included: the reports splice it in raw.
fn ctime_now() -> String {
    let secs = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0);
    let days = secs.div_euclid(86400);
    let rem = secs.rem_euclid(86400);
    let (hour, min, sec) = (rem / 3600, (rem % 3600) / 60, rem % 60);
    // Howard Hinnant's `civil_from_days`.
    let z = days + 719468;
    let era = z.div_euclid(146097);
    let doe = z.rem_euclid(146097);
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let mday = doy - (153 * mp + 2) / 5 + 1;
    let mon = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = if mon <= 2 { y + 1 } else { y };
    let mon_name = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        [mon as usize - 1];
    let dow = ["Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed"][days.rem_euclid(7) as usize];
    format!("{dow} {mon_name} {mday:2} {hour:02}:{min:02}:{sec:02} {year:04}\n")
}

/// The `<tr><th align=right>…</th><td>…</td></tr>` row every overview table is
/// built from.
fn row(label: &str, value: &str) -> String {
    format!("<tr> \n<th align=right> {label}: </th> \n<td>{value}</td> </tr>\n")
}

fn row_red(label: &str, value: &str) -> String {
    format!("<tr> \n<th align=right> {label}: </th> \n<td style=color:red>{value}</td> </tr>\n")
}

/// C's `createCorrelationWarningReport`: the link, and the warning file itself.
fn correlation_warning_report(ctx: &Ctx, html: &mut String, warn: &CorrelationWarnings) {
    if warn.is_empty() {
        return;
    }
    html.push_str(&format!(
        "<h3> <a href={}_warning.txt target=_blank> Warnings </a> </h3>\n",
        ctx.prefix()
    ));
    let cx = ctx.cx_file.clone().unwrap_or_default();
    let mut out = String::new();
    for name in &warn.diagonal {
        out.push_str(&format!(
            "|  warning  |   Diagonal entry for variable of interest {name} in correlation input file {cx} is ignored\n"
        ));
    }
    for name in &warn.above_diagonal {
        out.push_str(&format!(
            "|  warning  |   Above diagonal entry for variable of interest {name} in correlation input file {cx} is ignored\n"
        ));
    }
    for info in &warn.info {
        out.push_str(&format!(
            "|  warning  |   Entry for variable of interest {} and variable of interest {} in correlation input file {cx} is closer to 1: [{}]\n",
            info.name, info.x, info.sx
        ));
    }
    write_file(&ctx.model_file("_warning.txt"), &out);
}

/// The overview table the four reports share.
fn overview(ctx: &Ctx, title: &str) -> String {
    let mut h = format!(
        "<!DOCTYPE html><html>\n <head> <h1> {title}</h1></head> \n <body> \n <h2> Overview: </h2>\n<table> \n"
    );
    h.push_str(&row("Model file", &ctx.recon.model_file));
    h.push_str(&row("Model name", &ctx.model.model_name));
    h.push_str(&row("Model directory", &ctx.recon.model_dir));
    h
}

fn generated_row(ctx: &Ctx) -> String {
    format!(
        "<tr> \n<th align=right> Generated: </th> \n<td>{} by <b>{}</b></td> </tr>\n</table>\n",
        ctime_now(),
        ctx.recon.version
    )
}

/// The links every D.1 report ends with.
fn analysis_links(ctx: &Ctx, html: &mut String, measured_label: &str) {
    let p = ctx.prefix();
    html.push_str(&format!(
        "<h3> <a href={p}_AuxiliaryConditions.html target=_blank> Auxiliary conditions </a> </h3>\n"
    ));
    html.push_str(&format!(
        "<h3> <a href={p}_IntermediateEquations.html target=_blank> {measured_label} </a> </h3>\n"
    ));
    if !ctx.recon.setb_vars.is_empty() {
        html.push_str(&format!(
            "<h3> <a href={p}_BoundaryConditionIntermediateEquations.html target=_blank> Intermediate equations for unmeasured variables </a> </h3>\n"
        ));
    }
    if ctx.recon.n_related_boundary > 0 {
        html.push_str(&format!(
            "<h3> <a href={p}_relatedBoundaryConditionsEquations.html target=_blank> Related boundary conditions </a> </h3>\n"
        ));
    }
}

/// C's `createErrorHtmlReport`.
fn create_error_html_report(ctx: &Ctx, status: i32) {
    let p = ctx.prefix().to_string();
    let mut h = overview(ctx, "Data Reconciliation Report");
    match &ctx.sx_file {
        Some(f) => h.push_str(&row("Measurement input file", f)),
        None => h.push_str(&row_red("Measurement input file", "no file provided")),
    }
    h.push_str(&row("Correlation matrix input file", "no file provided"));
    h.push_str(&generated_row(ctx));

    h.push_str("<h2> Analysis: </h2>\n<table> \n");
    h.push_str(&row("Number of auxiliary conditions", &ctx.recon.setc_vars.len().to_string()));
    h.push_str(&row("Number of measured variables", &ctx.recon.input_vars.len().to_string()));
    h.push_str(&row("Number of unmeasured variables", &ctx.recon.setb_vars.len().to_string()));
    h.push_str(&row("Number of related boundary conditions", &ctx.recon.n_related_boundary.to_string()));
    h.push_str("</table> \n");

    analysis_links(ctx, &mut h, "Intermediate equations");
    h.push_str(&format!("<h2> <a href={p}.log target=_blank> Errors </a> </h2>\n"));
    copy_reference_file(ctx, ".log");
    if status == 0 {
        h.push_str(&format!("<h2> <a href={p}_iterationVars.txt target=_blank> Iteration vars </a> </h2>\n"));
        h.push_str(&format!("<h2> <a href={p}_debug.txt target=_blank> Debug log </a> </h2>\n"));
    }
    h.push_str("</table>\n</body>\n</html>");
    write_file(&ctx.model_file(".html"), &h);
}

/// C's `createErrorHtmlReportForBoundaryConditions`.
fn create_error_html_report_boundary(ctx: &Ctx, status: i32) {
    let p = ctx.prefix().to_string();
    let mut h = overview(ctx, "Boundary Conditions Report ");
    match &ctx.sx_file {
        Some(f) => h.push_str(&row("Reconciled values input file", f)),
        None => h.push_str(&row_red("Reconciled values input file", "no file provided")),
    }
    match &ctx.cx_file {
        Some(f) => h.push_str(&row("Reconciled covariance matrix input file", f)),
        None => h.push_str(&row_red("Reconciled covariance matrix input file", "no file provided")),
    }
    h.push_str(&generated_row(ctx));

    h.push_str("<h2> Analysis: </h2>\n<table> \n");
    h.push_str(&row("Number of boundary conditions", &ctx.recon.setc_vars.len().to_string()));
    h.push_str(&row("Number of variables to be reconciled", &ctx.recon.input_vars.len().to_string()));
    h.push_str("</table> \n");

    h.push_str(&format!(
        "<h3> <a href={p}_BoundaryConditionsEquations.html target=_blank> Boundary conditions </a> </h3>\n"
    ));
    h.push_str(&format!(
        "<h3> <a href={p}_BoundaryConditionIntermediateEquations.html target=_blank> Intermediate equations </a> </h3>\n"
    ));
    h.push_str(&format!("<h2> <a href={p}.log target=_blank> Errors </a> </h2>\n"));
    copy_reference_file(ctx, ".log");
    if status == 0 {
        h.push_str(&format!("<h2> <a href={p}_iterationVars.txt target=_blank> Iteration vars </a> </h2>\n"));
        h.push_str(&format!(
            "<h2> <a href={p}_BoundaryConditions_debug.txt target=_blank> Debug log </a> </h2>\n"
        ));
    }
    h.push_str("</table>\n</body>\n</html>");
    write_file(&ctx.model_file("_BoundaryConditions.html"), &h);
}

/// C's `boundaryConditionData`.
#[derive(Clone, Debug, Default)]
struct BoundaryConditionData {
    vars: Vec<String>,
    results: Vec<f64>,
    recon_st_diag: Vec<f64>,
}

/// C's `createHtmlReportFordataReconciliation`, plus the `_Outputs.csv` it writes
/// alongside.
fn create_html_report(
    ctx: &Ctx,
    csvinputs: &CsvData,
    d: &ReconciliationData,
    eps: f64,
    warn: &CorrelationWarnings,
    bc: &BoundaryConditionData,
) {
    let p = ctx.prefix().to_string();
    // Variables the extraction algorithm could not reconcile.
    let non_reconciled: Vec<String> = read_file(&format!("{p}_NonReconcilcedVars.txt"))
        .map(|t| t.lines().filter(|l| !l.is_empty()).map(|l| l.to_string()).collect())
        .unwrap_or_default();

    let mut h = overview(ctx, "Data Reconciliation Report");
    h.push_str(&row("Measurement input file", ctx.sx_file.as_deref().unwrap_or("")));
    match &ctx.cx_file {
        Some(f) => h.push_str(&row("Correlation matrix input file", f)),
        None => h.push_str(&row("Correlation matrix input file", "no file provided")),
    }
    h.push_str(&generated_row(ctx));

    let n_setc = ctx.recon.setc_vars.len();
    h.push_str("<h2> Analysis: </h2>\n<table> \n");
    h.push_str(&row("Number of auxiliary conditions", &n_setc.to_string()));
    h.push_str(&row("Number of measured variables", &ctx.recon.input_vars.len().to_string()));
    h.push_str(&row("Number of unmeasured variables", &ctx.recon.setb_vars.len().to_string()));
    h.push_str(&row("Number of related boundary conditions", &ctx.recon.n_related_boundary.to_string()));
    h.push_str(&row("Number of iterations to convergence", &d.iterations.to_string()));
    h.push_str(&row("Final value of (J*/r) ", &num(d.value)));
    h.push_str(&row("Epsilon ", &num(eps)));
    h.push_str(&row("Final value of the objective function (J) ", &num(d.j)));
    let chi = CHI_SQUARED[n_setc.saturating_sub(1).min(CHI_SQUARED.len() - 1)];
    if n_setc > 200 {
        h.push_str(&row("Chi-square value ", "NOT Available for equations > 200 in setC"));
    } else {
        h.push_str(&row("Chi-square value ", &num(chi)));
    }
    h.push_str(&row("Result of global test ", if d.j <= chi { "TRUE" } else { "FALSE" }));
    h.push_str(&row("Quality (J/Chi-square) ", &num(d.j / chi)));
    h.push_str("</table>\n");

    analysis_links(ctx, &mut h, "Intermediate equations for measured variables");
    h.push_str(&format!("<h3> <a href={p}_iterationVars.txt target=_blank> Iteration vars </a> </h3>\n"));
    h.push_str(&format!("<h3> <a href={p}_debug.txt target=_blank> Debug log </a> </h3>\n"));
    correlation_warning_report(ctx, &mut h, warn);

    h.push_str("<h2> Results: </h2>\n<table border=2>\n");
    h.push_str("<tr>\n<th> Variable to be Estimated </th>\n<th> Unit </th>\n<th> Description </th>\n<th> Initial Measured Value </th>\n<th> Estimated Value </th>\n<th> Initial Uncertainty </th>\n<th> Estimated Uncertainty </th>\n");
    h.push_str("<th> Result of Local Test </th>\n<th> Local Quality  </th>\n<th> Comment </th>\n</tr>\n");
    let mut csv = String::from(
        "Variable to be Estimated ,Initial Measured Value ,Estimated Value ,Initial Uncertainty ,Estimated Uncertainty,",
    );
    csv.push_str("Result of Local Test ,Local Quality  ,\n");

    let unmeasured: Vec<&ReconVar> = ctx.recon.setb_vars.iter().collect();
    for (r, header) in csvinputs.headers.iter().enumerate() {
        let reconciled = !non_reconciled.contains(header);
        let var = ctx.recon.input_vars.iter().find(|v| &v.name == header);
        let (unit, desc) = var.map_or(("", ""), |v| (v.unit.as_str(), v.comment.as_str()));
        h.push_str("<tr>\n");
        h.push_str(&format!("<td>{header}</td>\n"));
        csv.push_str(&format!("{header},"));
        h.push_str(&format!("<td>{unit}</td>\n"));
        h.push_str(&format!("<td>{desc}</td>\n"));
        h.push_str(&format!("<td>{}</td>\n", num(d.xdiag.data[r])));
        csv.push_str(&format!("{},", num(d.xdiag.data[r])));
        h.push_str(&format!("<td>{}</td>\n", num(d.reconciled_x.data[r])));
        csv.push_str(&format!("{},", num(d.reconciled_x.data[r])));
        h.push_str(&format!("<td>{}</td>\n", num(csvinputs.sxdata[r])));
        csv.push_str(&format!("{},", num(csvinputs.sxdata[r])));
        h.push_str(&format!("<td>{}</td>\n", num(d.recon_sx_diag.data[r])));
        csv.push_str(&format!("{},", num(d.recon_sx_diag.data[r])));
        let local = if d.new_x[r] < LAMBDA { "TRUE" } else { "FALSE" };
        h.push_str(&format!("<td>{local}</td>\n"));
        csv.push_str(&format!("{local},"));
        h.push_str(&format!("<td>{}</td>\n", num(d.new_x[r] / LAMBDA)));
        csv.push_str(&format!("{},\n", num(d.new_x[r] / LAMBDA)));
        if reconciled {
            h.push_str("<td></td>\n");
        } else {
            h.push_str("<td style=color:red>Not reconciled</td>\n");
        }
        h.push_str("</tr>\n");
    }

    for (i, name) in bc.vars.iter().enumerate() {
        let (unit, desc) = unmeasured
            .get(i)
            .map_or(("", ""), |v| (v.unit.as_str(), v.comment.as_str()));
        h.push_str("<tr>\n");
        h.push_str(&format!("<td>{name}</td>\n"));
        csv.push_str(&format!("{name},"));
        h.push_str(&format!("<td>{unit}</td>\n"));
        h.push_str(&format!("<td>{desc}</td>\n"));
        h.push_str("<td> </td>\n");
        csv.push(',');
        let value = bc.results.get(i).copied().unwrap_or(0.0);
        h.push_str(&format!("<td>{}</td>\n", num(value)));
        csv.push_str(&format!("{},", num(value)));
        h.push_str("<td></td>\n");
        csv.push(',');
        let width = bc.recon_st_diag.get(i).copied().unwrap_or(0.0);
        h.push_str(&format!("<td>{}</td>\n", num(width)));
        csv.push_str(&format!("{},", num(width)));
        h.push_str("<td></td>\n");
        csv.push(',');
        h.push_str("<td></td>\n");
        csv.push_str(",\n");
        h.push_str("<td></td>\n");
        h.push_str("</tr>\n");
    }

    write_file(&ctx.model_file("_Outputs.csv"), &csv);
    h.push_str("</table>\n</body>\n</html>");
    write_file(&ctx.model_file(".html"), &h);
}

/// C's `createHtmlReportForBoundaryConditions`.
fn create_html_report_boundary(ctx: &Ctx, bc: &BoundaryConditionData, warn: &CorrelationWarnings) {
    let p = ctx.prefix().to_string();
    let mut h = overview(ctx, "Boundary Conditions Report ");
    h.push_str(&row("Reconciled values input file", ctx.sx_file.as_deref().unwrap_or("")));
    match &ctx.cx_file {
        Some(f) => h.push_str(&row("Reconciled covariance matrix input file", f)),
        None => h.push_str(&row("Correlation matrix input file", "no file provided")),
    }
    h.push_str(&generated_row(ctx));

    h.push_str("<h2> Analysis: </h2>\n<table> \n");
    h.push_str(&row("Number of boundary conditions", &ctx.recon.setc_vars.len().to_string()));
    h.push_str(&row("Number of variables to be reconciled", &ctx.recon.input_vars.len().to_string()));
    h.push_str("</table>\n");

    h.push_str(&format!(
        "<h3> <a href={p}_BoundaryConditionsEquations.html target=_blank> Boundary conditions </a> </h3>\n"
    ));
    h.push_str(&format!(
        "<h3> <a href={p}_BoundaryConditionIntermediateEquations.html target=_blank> Intermediate equations </a> </h3>\n"
    ));
    h.push_str(&format!("<h3> <a href={p}_iterationVars.txt target=_blank> Iteration vars </a> </h3>\n"));
    h.push_str(&format!(
        "<h3> <a href={p}_BoundaryConditions_debug.txt target=_blank> Debug log </a> </h3>\n"
    ));
    correlation_warning_report(ctx, &mut h, warn);

    h.push_str("<h2> Results: </h2>\n<table border=2>\n");
    h.push_str("<tr>\n<th> Boundary conditions </th>\n<th> Values </th>\n<th> Reconciled Half-width Confidence Intervals </th> </tr>\n");
    let mut csv = String::from("Boundary conditions ,Values ,Reconciled Half-width Confidence Intervals,\n");
    for (r, name) in bc.vars.iter().enumerate() {
        h.push_str("<tr>\n");
        h.push_str(&format!("<td>{name}</td>\n"));
        csv.push_str(&format!("{name},"));
        let value = bc.results.get(r).copied().unwrap_or(0.0);
        let width = bc.recon_st_diag.get(r).copied().unwrap_or(0.0);
        h.push_str(&format!("<td>{}</td>\n", num(value)));
        csv.push_str(&format!("{},", num(value)));
        h.push_str(&format!("<td>{}</td>\n", num(width)));
        h.push_str("</tr>\n");
        csv.push_str(&format!("{},\n", num(width)));
    }
    h.push_str("</table>\n</html>");
    write_file(&ctx.model_file("_BoundaryConditions.html"), &h);
    write_file(&ctx.model_file("_BoundaryConditions_Outputs.csv"), &csv);
}

// ───────────────────────────── D.2 / state estimation ─────────────────────────────

/// C's `reconcileBoundaryConditions`: the half-width confidence intervals of the
/// boundary conditions, from the reconciled covariance matrix.
fn reconcile_boundary_conditions(
    ctx: &mut Ctx,
    e: &mut dyn SimEngine,
    reconciled_x: &Matrix,
    reconciled_sx: &Matrix,
    warn: &CorrelationWarnings,
) -> Result<BoundaryConditionData> {
    set_inputs_and_solve(e, ctx, &reconciled_x.data)?;

    let jac_f = jacobian(ctx, e, if ctx.mode.boundary { 'F' } else { 'H' })?;
    print_matrix(&mut ctx.log, &jac_f, "F");
    let jac_ft = jac_f.transpose();
    print_matrix(&mut ctx.log, &jac_ft, "Ft");

    let af = matmul(ctx, &jac_f, reconciled_sx)?;
    print_matrix(&mut ctx.log, &af, "F*reconciled_Sx");
    let s_t = matmul(ctx, &af, &jac_ft)?;
    print_matrix(&mut ctx.log, &s_t, "(s_t = F*reconciled_Sx*Ft)");

    let mut recon_st_diag = s_t.diagonal();
    if log_jac() {
        ctx.log.push_str("Calculations of half-width confidence interval\n");
        ctx.log.push_str("===============================================\n");
        print_matrix(&mut ctx.log, &recon_st_diag, "S_t_Diagonal");
    }
    recon_st_diag.sqrt_elements();
    if log_jac() {
        print_matrix(&mut ctx.log, &recon_st_diag, "S_t_SquareRoot");
    }
    recon_st_diag.scale(LAMBDA);

    let vars_file = ctx.model_file("_BoundaryConditionVars.txt");
    copy_reference_file(ctx, "_BoundaryConditionVars.txt");
    let Some(text) = read_file(&vars_file) else {
        let msg = format!("Boundary conditions vars filename not found: {vars_file}.");
        ctx.error2(&msg, &format!("Boundary conditions vars filename not found: {vars_file}"));
        return Err(ctx.abort());
    };
    let vars: Vec<String> = text.lines().filter(|l| !l.is_empty()).map(|l| l.to_string()).collect();

    print_matrix_headers(
        &mut ctx.log,
        &recon_st_diag,
        &vars,
        "Half-width Confidence Interval(1.96*S_t_SquareRoot)",
    );

    // C reads the result array back to front, as `RunReconciliation` does.
    let set = if ctx.mode.boundary { ctx.recon.setc_vars.clone() } else { ctx.recon.setb_vars.clone() };
    let raw = read_set(e, ctx.sim_data, &set)?;
    let results: Vec<f64> = (0..raw.len()).map(|t| raw[raw.len() - 1 - t]).collect();

    let results_m = Matrix::column(results.len(), results.clone());
    print_boundary_results(&mut ctx.log, &results_m, &recon_st_diag, &vars, "Final Results");

    let bc = BoundaryConditionData { vars, results, recon_st_diag: recon_st_diag.data };
    if ctx.mode.boundary {
        create_html_report_boundary(ctx, &bc, warn);
    }
    Ok(bc)
}

// ───────────────────────────── entry points ─────────────────────────────

/// Run whichever `-reconcile*` procedure the flags select, C's three blocks in
/// `simulation_runtime.cpp`. Returns the log lines C prints around them (already
/// rendered, for the caller to place after the run's success line) and whether the
/// procedure would have `exit(1)`ed.
pub fn reconcile(e: &mut dyn SimEngine, model: &SimMeta, sim_data: u32) -> (String, Result<()>) {
    let mode = crate::simflags::with_flags(|f| Mode {
        reconcile: f.reconcile,
        boundary: f.reconcile_boundary,
        state: f.reconcile_state,
    });
    if !(mode.reconcile || mode.boundary || mode.state) {
        return (String::new(), Ok(()));
    }
    omclog::start_capture();
    let res = run_modes(e, model, sim_data, mode);
    (omclog::take_capture(), res)
}

/// C's `dataReconciliation(data, threadData, status)` with `status != 0`: the run
/// itself failed, so only the error report is written.
pub fn report_run_failure(model: &SimMeta) {
    let mode = crate::simflags::with_flags(|f| Mode {
        reconcile: f.reconcile,
        boundary: f.reconcile_boundary,
        state: f.reconcile_state,
    });
    if !(mode.reconcile || mode.boundary || mode.state) {
        return;
    }
    let Some(recon) = model.recon.as_ref() else { return };
    let (sx_file, cx_file, output_path) =
        crate::simflags::with_flags(|f| (f.recon_sx.clone(), f.recon_cx.clone(), f.output_path.clone()));
    let ctx = Ctx {
        model,
        recon,
        sim_data: 0,
        mode,
        sx_file,
        cx_file,
        output_path,
        log: String::new(),
        log_path: String::new(),
    };
    if mode.boundary {
        create_error_html_report_boundary(&ctx, 1);
    } else {
        create_error_html_report(&ctx, 1);
    }
}

fn run_modes(e: &mut dyn SimEngine, model: &SimMeta, sim_data: u32, mode: Mode) -> Result<()> {
    let (sx_file, cx_file, output_path) =
        crate::simflags::with_flags(|f| (f.recon_sx.clone(), f.recon_cx.clone(), f.output_path.clone()));
    let Some(recon) = model.recon.as_ref() else {
        omclog::error(
            omclog::STDOUT,
            false,
            "-reconcile: the model was not translated with --preOptModules+=dataReconciliation",
        );
        return Err(ABORTED);
    };
    let mut ctx = Ctx {
        model,
        recon,
        sim_data,
        mode,
        sx_file,
        cx_file,
        output_path,
        log: String::new(),
        log_path: String::new(),
    };
    if mode.reconcile {
        starting(&ctx, "DataReconciliation Starting!");
        let r = data_reconciliation(&mut ctx, e);
        omclog::info(omclog::STDOUT, false, "DataReconciliation Completed!");
        r?;
    }
    if mode.boundary {
        starting(&ctx, "Reconcile Boundary Conditions Starting!");
        let r = boundary_conditions(&mut ctx, e);
        omclog::info(omclog::STDOUT, false, "Reconcile Boundary Conditions Completed!");
        r?;
    }
    if mode.state {
        starting(&ctx, "Reconcile State Estimation Starting!");
        let r = data_reconciliation(&mut ctx, e);
        omclog::info(omclog::STDOUT, false, "Reconcile State Estimation Completed!");
        r?;
    }
    Ok(())
}

/// C prints the model name right after the opening banner.
fn starting(ctx: &Ctx, msg: &str) {
    omclog::info(omclog::STDOUT, false, msg);
    omclog::info(omclog::STDOUT, false, &ctx.model.model_name);
}

/// C's `dataReconciliation`: D.1, and D.1 + D.2 under `-reconcileState`.
fn data_reconciliation(ctx: &mut Ctx, e: &mut dyn SimEngine) -> Result<()> {
    for f in [
        "_AuxiliaryConditions.html",
        "_IntermediateEquations.html",
        "_relatedBoundaryConditionsEquations.html",
        "_iterationVars.txt",
    ] {
        copy_reference_file(ctx, f);
    }
    ctx.log_path = ctx.model_file("_debug.txt");
    ctx.log.clear();
    if ctx.mode.reconcile {
        ctx.log.push_str("|  info    |   DataReconciliation Starting!\n");
        ctx.log.push_str(&format!("|  info    |   {}\n", ctx.model.model_name));
    }
    if ctx.mode.state {
        ctx.log.push_str("|  info    |   State Estimation Starting!\n");
        ctx.log.push_str(&format!("|  info    |   {}\n", ctx.model.model_name));
    }
    // C's default epsilon.
    let eps = ctx.sx_eps();

    let csvdata = read_measurement_input_file(ctx)?;
    let sx_data = validate_measurement_inputs(ctx, csvdata)?;
    let x = Matrix::column(sx_data.rowcount, sx_data.xdata.clone());

    let mut warn = CorrelationWarnings::default();
    let cx_data = read_correlation_file(ctx, &sx_data, &mut warn)?;
    let sx = compute_covariance_sx(ctx, &sx_data, &cx_data)?;
    // C computes `F` here and passes it into `RunReconciliation`, which recomputes
    // it; only the "cannot compute" error it can raise reaches this far.
    jacobian(ctx, e, 'F')?;

    let sx_diag = sx.diagonal();
    let xdiag = x.clone();

    ctx.log.push_str("\n\nInitial Data \n=============\n");
    print_matrix_headers(&mut ctx.log, &x, &sx_data.headers, "X");
    let sxdata = sx_data.sxdata.clone();
    print_vector_headers(&mut ctx.log, &sxdata, sx_data.rowcount, &sx_data.headers, "Half-WidthConfidenceInterval");
    print_correlation_matrix(&mut ctx.log, &cx_data, "Co-Relation_Coefficient", &mut warn);
    print_matrix_headers(&mut ctx.log, &sx, &sx_data.headers, "Sx");

    let mut work_x = x;
    if ctx.mode.reconcile {
        run_reconciliation(ctx, e, &mut work_x, &sx, eps, &sx_data, &xdiag, &sx_diag, &warn)?;
        ctx.log.push_str("|  info    |   DataReconciliation Completed! \n");
    }
    if ctx.mode.state {
        state_estimation(ctx, e, &mut work_x, &sx, eps, &sx_data, &xdiag, &sx_diag, &warn)?;
        ctx.log.push_str("|  info    |   state estimation Completed! \n");
    }
    ctx.flush_log();
    Ok(())
}

/// C's `stateEstimation`: D.1, then D.2 when the model has unmeasured variables,
/// and one combined report.
#[allow(clippy::too_many_arguments)]
fn state_estimation(
    ctx: &mut Ctx,
    e: &mut dyn SimEngine,
    x: &mut Matrix,
    sx: &Matrix,
    eps: f64,
    csvinputs: &CsvData,
    xdiag: &Matrix,
    sxdiag: &Matrix,
    warn: &CorrelationWarnings,
) -> Result<()> {
    let d = run_reconciliation(ctx, e, x, sx, eps, csvinputs, xdiag, sxdiag, warn)?;
    let mut bc = BoundaryConditionData::default();
    if !ctx.recon.setb_vars.is_empty() {
        copy_reference_file(ctx, "_BoundaryConditionIntermediateEquations.html");
        ctx.log.push_str("\n\nCalculation of Boundary condition \n====================================\n");
        bc = reconcile_boundary_conditions(ctx, e, &d.reconciled_x, &d.reconciled_sx, warn)?;
    }
    create_html_report(ctx, csvinputs, &d, eps, warn, &bc);
    Ok(())
}

/// C's `boundaryConditions`: D.2 on its own, seeded from D.1's output files.
fn boundary_conditions(ctx: &mut Ctx, e: &mut dyn SimEngine) -> Result<()> {
    for f in [
        "_BoundaryConditionsEquations.html",
        "_BoundaryConditionIntermediateEquations.html",
        "_iterationVars.txt",
    ] {
        copy_reference_file(ctx, f);
    }
    ctx.log_path = ctx.model_file("_BoundaryConditions_debug.txt");
    ctx.log.clear();
    ctx.log.push_str("|  info    |   Reconcile Boundary Conditions Starting!\n");
    ctx.log.push_str(&format!("|  info    |   {}\n", ctx.model.model_name));

    let csvdata = read_measurement_input_file(ctx)?;
    let sx_data = validate_measurement_inputs(ctx, csvdata)?;
    // D.1's `_Outputs.csv` carries the reconciled values in the third column.
    let reconciled_x = Matrix::column(sx_data.rowcount, sx_data.sxdata.clone());

    let mut warn = CorrelationWarnings::default();
    let cx_data = read_correlation_file(ctx, &sx_data, &mut warn)?;
    let reconciled_sx = init_column_matrix(
        &cx_data.data,
        cx_data.row_headers.len(),
        cx_data.column_headers.len(),
    );

    ctx.log.push_str("\n\nInitial Data \n=============\n");
    print_matrix_headers(&mut ctx.log, &reconciled_x, &sx_data.headers, "Reconciled_X");
    print_matrix_headers(&mut ctx.log, &reconciled_sx, &sx_data.headers, "Reconciled_Sx");

    reconcile_boundary_conditions(ctx, e, &reconciled_x, &reconciled_sx, &warn)?;
    let headers = sx_data.headers.clone();
    update_reconciled_mo(ctx, &headers, &reconciled_x.data);

    ctx.log.push_str("*****Completed***********\n");
    ctx.log.push_str("|  info    |   Reconcile Boundary Conditions Completed! \n");
    ctx.flush_log();
    Ok(())
}
