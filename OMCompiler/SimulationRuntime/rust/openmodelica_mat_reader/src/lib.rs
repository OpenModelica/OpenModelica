//! Pure-Rust port of the parts of
//! `OMCompiler/SimulationRuntime/c/util/read_matlab4.c` that the compiler's
//! `SimulationResults` package and the simulation runtimes' `-iif` need: opening
//! an OpenModelica MATLAB v4 result file
//! (`Aclass`/`name`/`description`/`dataInfo`/`data_1`/`data_2`), looking up
//! variables, and reading their trajectories (with linear interpolation).
//
//! Both storage layouts are supported: `binTrans` (what the simulation runtimes
//! write, data_2 stored time-major) and `binNormal` (variable-major, as
//! `filterSimulationResults` writes).

#![allow(non_snake_case)]

use std::cmp::Ordering;
use std::io::{Read, Seek, SeekFrom};

pub mod fs;

// The result file is read lazily via the fs facade's `Read + Seek` handle: a real
// `std::fs::File` natively, an in-memory `Cursor` on the web target.
type Src = fs::Reader;

/// Bytes of data_2 read from the file at a time while loading or scanning it.
const CHUNK_BYTES: usize = if cfg!(test) { 32 } else { 1 << 20 };

/// One entry from the `name`/`description`/`dataInfo` metadata tables.
#[derive(Clone)]
pub struct MatVariable {
    pub name: String,
    pub descr: String,
    pub isParam: bool,
    /// 1-based index into data_1 (params) or data_2 (vars); negative selects the
    /// sign-inverted alias of that column.
    pub index: i32,
}

/// The C `omc_matlab4_find_var` lookup over a table sorted by [`iws_cmp`]:
/// exact match, then `time`/`Time`, then the Dymola / OpenModelica spelling of
/// array indices and `der()`.
pub fn find_var_in(allInfo: &[MatVariable], varName: &str) -> Option<usize> {
    if let Ok(idx) = allInfo.binary_search_by(|v| iws_cmp(&v.name, varName)) {
        return Some(idx);
    }
    if varName == "time" {
        return allInfo.binary_search_by(|v| iws_cmp(&v.name, "Time")).ok();
    } else if varName == "Time" {
        return allInfo.binary_search_by(|v| iws_cmp(&v.name, "time")).ok();
    }
    let converted = dymola_style_name(varName).or_else(|| openmodelica_style_name(varName))?;
    allInfo.binary_search_by(|v| iws_cmp(&v.name, &converted)).ok()
}

/// What every column-store result file offers: the `.mat`'s data model (a
/// variable table over stored columns and scalar parameters, aliases as signed
/// indices), so the scripting API serves `.mat` and `.arrow` through one path.
pub trait ResultTable {
    fn all_info(&self) -> &[MatVariable];
    fn params(&self) -> &[f64];
    fn nrows(&self) -> usize;
    /// Stored time-variant columns, `time` included (the `.mat`'s data_2 width).
    fn nvar(&self) -> usize;
    fn nparam(&self) -> usize;
    fn find_var(&self, name: &str) -> Option<usize>;
    /// The trajectory of 1-based column `index`, negated when it is negative.
    fn read_vals(&mut self, index: i32) -> Option<Vec<f64>>;
    fn val(&mut self, var_idx: usize, time: f64) -> Option<f64>;
    fn interp_val(&mut self, index: i32, time: f64) -> Option<f64>;
    fn start_time(&mut self) -> f64;
    fn stop_time(&mut self) -> f64;
    fn read_all(&mut self) -> bool;
    /// `(unit, displayUnit)` of `all_info()[idx]`; empty for a format without units.
    fn unit(&self, _idx: usize) -> (&str, &str) {
        ("", "")
    }
    /// The Modelica type name of `all_info()[idx]` (`Real` for a format without types).
    fn var_type(&self, _idx: usize) -> &str {
        "Real"
    }
    /// FMI's `relativeQuantity` for `all_info()[idx]`: the value is a difference in
    /// its unit, so a conversion scales it but adds no offset. False for a format
    /// that does not record it.
    fn relative_quantity(&self, _idx: usize) -> bool {
        false
    }
    /// The trajectory of a String column (1-based `index`); `None` unless the
    /// format stores Strings and the column is one.
    fn read_strings(&mut self, _index: i32) -> Option<Vec<String>> {
        None
    }
    /// Whether `all_info()[idx]` is a discrete-time variable. False for a format
    /// that does not record it.
    fn discrete(&self, _idx: usize) -> bool {
        false
    }
    /// The literals of the enumeration variable `all_info()[idx]`.
    fn enumeration(&self, _idx: usize) -> Option<Vec<String>> {
        None
    }
    /// The text of the String parameter `all_info()[idx]`.
    fn param_string(&self, _idx: usize) -> Option<String> {
        None
    }
}

impl ResultTable for MatReader {
    fn all_info(&self) -> &[MatVariable] {
        &self.allInfo
    }
    fn params(&self) -> &[f64] {
        &self.params
    }
    fn nrows(&self) -> usize {
        self.nrows
    }
    fn nvar(&self) -> usize {
        self.nvar
    }
    fn nparam(&self) -> usize {
        self.nparam
    }
    fn find_var(&self, name: &str) -> Option<usize> {
        MatReader::find_var(self, name)
    }
    fn read_vals(&mut self, index: i32) -> Option<Vec<f64>> {
        MatReader::read_vals(self, index)
    }
    fn val(&mut self, var_idx: usize, time: f64) -> Option<f64> {
        MatReader::val(self, var_idx, time)
    }
    fn interp_val(&mut self, index: i32, time: f64) -> Option<f64> {
        MatReader::interp_val(self, index, time)
    }
    fn start_time(&mut self) -> f64 {
        MatReader::start_time(self)
    }
    fn stop_time(&mut self) -> f64 {
        MatReader::stop_time(self)
    }
    fn read_all(&mut self) -> bool {
        MatReader::read_all(self)
    }
}

/// An opened MATLAB v4 result file.
pub struct MatReader {
    file: Src,
    /// Variable/parameter descriptors, sorted by [`iws_cmp`] for binary search.
    pub allInfo: Vec<MatVariable>,
    pub params: Vec<f64>,
    /// Number of parameter columns in data_1 (the C reader's `nparam`).
    pub nparam: usize,
    pub nvar: usize,
    pub nrows: usize,
    /// File offset (bytes) where the data_2 payload begins.
    var_offset: u64,
    /// data_2 stored time-major (`binTrans`) vs. variable-major (`binNormal`).
    binTrans: bool,
    /// True if data_2 is stored as IEEE double, false if single precision.
    doublePrecision: bool,
    /// data_2 in memory, variable-major: `data2[v*nrows + i]`.
    data2: Option<Vec<f64>>,
    /// Loading data_2 failed (too large for memory); not retried.
    data2Failed: bool,
    /// The time column, cached when data_2 is not in memory.
    time: Option<Vec<f64>>,
    startTime: Option<f64>,
    stopTime: Option<f64>,
}

/// MATLAB v4 matrix header (5 little-endian u32 fields).
struct MHeader {
    ty: u32,
    mrows: u32,
    ncols: u32,
    imagf: u32,
    namelen: u32,
}

/// Decode a fixed-width MATLAB char field. The runtime stores names/descriptions
/// NUL-terminated (C-string semantics) and space-padded, so cut at the first NUL
/// and trim surrounding whitespace, matching the C reader + `trimWhitespace`.
fn fixed_str(bytes: &[u8]) -> String {
    let end = bytes.iter().position(|&b| b == 0).unwrap_or(bytes.len());
    String::from_utf8_lossy(&bytes[..end]).trim().to_string()
}

/// Compare two names ignoring ASCII whitespace, matching the C `strcmp_iws`.
/// The metadata is sorted/searched with this so that e.g. "a [1, 2]" and
/// "a[1,2]" compare equal.
pub fn iws_cmp(a: &str, b: &str) -> Ordering {
    let mut ai = a.bytes().peekable();
    let mut bi = b.bytes().peekable();
    loop {
        match (ai.peek().copied(), bi.peek().copied()) {
            (Some(ca), _) if ca.is_ascii_whitespace() => {
                ai.next();
            }
            (_, Some(cb)) if cb.is_ascii_whitespace() => {
                bi.next();
            }
            (Some(ca), Some(cb)) => {
                if ca != cb {
                    return ca.cmp(&cb);
                }
                ai.next();
                bi.next();
            }
            (None, None) => return Ordering::Equal,
            (Some(_), None) => return Ordering::Greater,
            (None, Some(_)) => return Ordering::Less,
        }
    }
}

fn mat_element_length(ty: i32) -> Option<usize> {
    let m = ty / 1000;
    let o = (ty % 1000) / 100;
    let p = (ty % 100) / 10;
    let t = ty % 10;
    if m != 0 {
        return None; // require IEEE little-endian
    }
    if o != 0 {
        return None;
    }
    if t == 1 && p == 0 {
        return Some(8);
    }
    if t == 1 && p != 5 {
        return None;
    }
    if t == 2 {
        return None; // sparse
    }
    match p {
        0 => Some(8),
        1 => Some(4),
        2 => Some(4),
        3 => Some(2),
        4 => Some(2),
        5 => Some(1),
        _ => None,
    }
}

/// A second reader handle: the caller parses metadata with one copy and keeps the
/// other for lazy `seek`+read of the data payload.
fn clone_src(f: &Src) -> Result<Src, String> {
    f.try_clone().map_err(|e| e.to_string())
}

fn read_exact_vec(file: &mut Src, n: usize) -> Result<Vec<u8>, String> {
    let mut buf = vec![0u8; n];
    file.read_exact(&mut buf).map_err(|e| e.to_string())?;
    Ok(buf)
}

fn read_header(file: &mut Src) -> Result<MHeader, String> {
    let buf = read_exact_vec(file, 20)?;
    let g = |i: usize| u32::from_le_bytes([buf[i], buf[i + 1], buf[i + 2], buf[i + 3]]);
    Ok(MHeader {
        ty: g(0),
        mrows: g(4),
        ncols: g(8),
        imagf: g(12),
        namelen: g(16),
    })
}

/// Read `n` character elements (stored either as doubles or raw bytes).
fn read_chars(ty: i32, n: usize, file: &mut Src) -> Result<Vec<u8>, String> {
    let p = (ty % 100) / 10;
    if p == 0 {
        let raw = read_exact_vec(file, n * 8)?;
        Ok((0..n)
            .map(|k| {
                let b: [u8; 8] = raw[k * 8..k * 8 + 8].try_into().unwrap();
                f64::from_le_bytes(b) as u8
            })
            .collect())
    } else if p == 5 {
        read_exact_vec(file, n)
    } else {
        Err("Could not read matrix as text".into())
    }
}

fn read_int32(ty: i32, n: usize, file: &mut Src) -> Result<Vec<i32>, String> {
    let p = (ty % 100) / 10;
    if p == 0 {
        let raw = read_exact_vec(file, n * 8)?;
        Ok((0..n)
            .map(|k| {
                let b: [u8; 8] = raw[k * 8..k * 8 + 8].try_into().unwrap();
                f64::from_le_bytes(b) as i32
            })
            .collect())
    } else if p == 2 {
        let raw = read_exact_vec(file, n * 4)?;
        Ok((0..n)
            .map(|k| {
                let b: [u8; 4] = raw[k * 4..k * 4 + 4].try_into().unwrap();
                i32::from_le_bytes(b)
            })
            .collect())
    } else {
        Err("Corrupt header: integer matrix".into())
    }
}

fn read_doubles(ty: i32, n: usize, file: &mut Src) -> Result<Vec<f64>, String> {
    let p = (ty % 100) / 10;
    if n == 0 {
        return Ok(Vec::new());
    }
    if p == 0 {
        let raw = read_exact_vec(file, n * 8)?;
        Ok((0..n)
            .map(|k| {
                let b: [u8; 8] = raw[k * 8..k * 8 + 8].try_into().unwrap();
                f64::from_le_bytes(b)
            })
            .collect())
    } else if p == 1 {
        let raw = read_exact_vec(file, n * 4)?;
        Ok((0..n)
            .map(|k| {
                let b: [u8; 4] = raw[k * 4..k * 4 + 4].try_into().unwrap();
                f32::from_le_bytes(b) as f64
            })
            .collect())
    } else {
        Err("Corrupt header: floating-point matrix".into())
    }
}

/// Element `k` of a data_2 buffer of doubles or floats.
fn decode(raw: &[u8], k: usize, double: bool) -> f64 {
    if double {
        f64::from_le_bytes(raw[k * 8..k * 8 + 8].try_into().unwrap())
    } else {
        f32::from_le_bytes(raw[k * 4..k * 4 + 4].try_into().unwrap()) as f64
    }
}

/// "der(a.b.c)" -> "a.b.der(c)" (Dymola style), or None if no conversion needed.
pub fn dymola_style_name(var: &str) -> Option<String> {
    if !var.starts_with("der(") {
        return None;
    }
    let dot = var.rfind('.')?;
    // prefix up to and including the last dot, then der( + tail-after-dot.
    Some(format!("{}der({}", &var[4..=dot], &var[dot + 1..]))
}

/// "a.b.der(c)" -> "der(a.b.c)" (OpenModelica style), or None if not applicable.
pub fn openmodelica_style_name(var: &str) -> Option<String> {
    let der = var.find("der(")?;
    if der == 0 {
        return None;
    }
    Some(format!("der({}{}", &var[..der], &var[der + 4..]))
}

impl MatReader {
    /// Open and parse `filename`. Returns a textual error on the first problem,
    /// mirroring `omc_new_matlab4_reader`.
    pub fn open(filename: &str) -> Result<MatReader, String> {
        let mut file = fs::open_read(filename).map_err(|e| e.to_string())?;
        const MATRIX_NAMES: [&str; 6] = ["Aclass", "name", "description", "dataInfo", "data_1", "data_2"];

        let mut reader = MatReader {
            file: clone_src(&file)?,
            allInfo: Vec::new(),
            params: Vec::new(),
            nparam: 0,
            nvar: 0,
            nrows: 0,
            var_offset: 0,
            binTrans: true,
            doublePrecision: true,
            data2: None,
            data2Failed: false,
            time: None,
            startTime: None,
            stopTime: None,
        };
        // Parse sequentially using `file`; `reader.file` is the clone kept for
        // the lazy data_2 read.
        let mut binTrans = true;

        // The six matrices in this order; others between them (`enumerations`)
        // are skipped.
        let mut i = 0;
        while i < 6 {
            let hdr = read_header(&mut file).map_err(|_| "Corrupt header (1)".to_string())?;
            if hdr.imagf > 1 {
                return Err("Matrix uses imaginary numbers".into());
            }
            let element_length =
                mat_element_length(hdr.ty as i32).ok_or("Could not determine size of matrix elements")?;
            let namelen = hdr.namelen as usize;
            let name_bytes = read_exact_vec(&mut file, namelen).map_err(|_| "Corrupt header (2)".to_string())?;
            if namelen == 0 || name_bytes[namelen - 1] != 0 {
                return Err("Corrupt header (3)".into());
            }
            let name = String::from_utf8_lossy(&name_bytes[..namelen - 1]).into_owned();
            let matrix_length = hdr.mrows as usize * hdr.ncols as usize * (1 + hdr.imagf as usize) * element_length;
            if name != MATRIX_NAMES[i] {
                if MATRIX_NAMES.contains(&name.as_str()) {
                    return Err(format!("Matrix name mismatch: {}", MATRIX_NAMES[i]));
                }
                file.seek(SeekFrom::Current(matrix_length as i64))
                    .map_err(|_| "Corrupt header (4)".to_string())?;
                continue;
            }
            match i {
                0 => {
                    // Aclass: 4x11 char matrix; row 3 encodes binTrans/binNormal.
                    if hdr.mrows != 4 {
                        return Err("Aclass matrix does not have 4 rows".into());
                    }
                    if hdr.ncols != 11 {
                        return Err("Aclass matrix does not have 11 cols".into());
                    }
                    let tmp = read_chars(hdr.ty as i32, (hdr.ncols * hdr.mrows) as usize, &mut file)?;
                    let mrows = hdr.mrows as usize;
                    let ncols = hdr.ncols as usize;
                    // Row 3 (0-based) selects the storage format.
                    let row3: Vec<u8> = (0..ncols).map(|j| tmp[j * mrows + 3]).collect();
                    if row3.starts_with(b"binTrans") {
                        binTrans = true;
                    } else if row3.starts_with(b"binNormal") {
                        binTrans = false;
                    } else {
                        return Err("Aclass matrix does not match binTrans or binNormal format".into());
                    }
                }
                1 => {
                    // name
                    let mrows = hdr.mrows as usize;
                    let ncols = hdr.ncols as usize;
                    let nall = if binTrans { ncols } else { mrows };
                    reader.allInfo = Vec::with_capacity(nall);
                    let tmp = read_chars(hdr.ty as i32, ncols * mrows, &mut file)?;
                    for k in 0..nall {
                        let bytes: Vec<u8> = if binTrans {
                            (0..mrows).map(|r| tmp[k * mrows + r]).collect()
                        } else {
                            (0..ncols).map(|j| tmp[j * mrows + k]).collect()
                        };
                        reader.allInfo.push(MatVariable {
                            name: fixed_str(&bytes),
                            descr: String::new(),
                            isParam: false,
                            index: -1,
                        });
                    }
                }
                2 => {
                    // description
                    let mrows = hdr.mrows as usize;
                    let ncols = hdr.ncols as usize;
                    let nall = reader.allInfo.len();
                    let tmp = read_chars(hdr.ty as i32, ncols * mrows, &mut file)?;
                    for k in 0..nall {
                        let bytes: Vec<u8> = if binTrans {
                            (0..mrows).map(|r| tmp[k * mrows + r]).collect()
                        } else {
                            (0..ncols).map(|j| tmp[j * mrows + k]).collect()
                        };
                        reader.allInfo[k].descr = fixed_str(&bytes);
                    }
                }
                3 => {
                    // dataInfo: per variable {isParam, index, interpolation, defined}
                    let mrows = hdr.mrows as usize;
                    let ncols = hdr.ncols as usize;
                    let tmp = read_int32(hdr.ty as i32, ncols * mrows, &mut file)
                        .map_err(|_| "Corrupt header: dataInfo matrix".to_string())?;
                    let nall = reader.allInfo.len();
                    for k in 0..nall {
                        let (isparam_cell, index_cell) = if binTrans {
                            (tmp[k * mrows], tmp[k * mrows + 1])
                        } else {
                            (tmp[k], tmp[k + mrows])
                        };
                        reader.allInfo[k].isParam = isparam_cell == 1;
                        reader.allInfo[k].index = index_cell;
                    }
                    reader.allInfo.sort_by(|a, b| iws_cmp(&a.name, &b.name));
                }
                4 => {
                    // data_1: parameter values (start/stop columns)
                    let mrows = hdr.mrows as usize;
                    let ncols = hdr.ncols as usize;
                    // nparam = parameter count: rows in binTrans, columns in binNormal.
                    reader.nparam = if binTrans { mrows } else { ncols };
                    if binTrans {
                        if (hdr.mrows != 0 || hdr.ncols != 0) && ncols != 2 && ncols != 1 {
                            return Err("data_1 matrix does not have 1 or 2 cols (or 0 rows/columns)".into());
                        }
                        reader.params = read_doubles(hdr.ty as i32, mrows * ncols, &mut file)
                            .map_err(|_| "Corrupt header: data_1 matrix".to_string())?;
                    } else {
                        if (hdr.mrows != 0 || hdr.ncols != 0) && mrows != 2 && mrows != 1 {
                            return Err("data_1 matrix does not have 1 or 2 rows (or 0 rows/columns)".into());
                        }
                        let tmp = read_doubles(hdr.ty as i32, mrows * ncols, &mut file)
                            .map_err(|_| "Corrupt header: data_1 matrix".to_string())?;
                        // Transpose to params[k*ncols + j] = tmp[k + j*mrows].
                        let mut params = vec![0f64; mrows * ncols];
                        for k in 0..mrows {
                            for j in 0..ncols {
                                params[k * ncols + j] = tmp[k + j * mrows];
                            }
                        }
                        reader.params = params;
                    }
                }
                5 => {
                    // data_2: the time series. Record the offset; load lazily.
                    let p = (hdr.ty as i32 / 10) % 10;
                    reader.doublePrecision = match p {
                        0 => true,
                        1 => false,
                        _ => return Err("data_2 matrix not in double/float representation".into()),
                    };
                    reader.binTrans = binTrans;
                    if binTrans {
                        reader.nrows = hdr.ncols as usize;
                        reader.nvar = hdr.mrows as usize;
                    } else {
                        reader.nrows = hdr.mrows as usize;
                        reader.nvar = hdr.ncols as usize;
                    }
                    reader.var_offset = file.stream_position().map_err(|e| e.to_string())?;
                    let _ = matrix_length; // data_2 is the final matrix; nothing follows.
                }
                _ => unreachable!(),
            }
            i += 1;
        }
        Ok(reader)
    }

    /// Bytes one element of data_2 occupies on disk.
    fn elem_size(&self) -> u64 {
        if self.doublePrecision { 8 } else { 4 }
    }

    /// One element straight off the disk, without holding the matrix.
    fn disk_val(&mut self, row: usize, col: usize) -> Option<f64> {
        let elem = self.elem_size();
        let at = match self.binTrans {
            // Time-major on disk: row `row` is `nvar` elements, `col` into it.
            true => row as u64 * self.nvar as u64 + col as u64,
            // Variable-major: column `col` is `nrows` elements.
            false => col as u64 * self.nrows as u64 + row as u64,
        };
        self.file.seek(SeekFrom::Start(self.var_offset + at * elem)).ok()?;
        let ty = if self.doublePrecision { 0 } else { 10 };
        read_doubles(ty, 1, &mut self.file).ok()?.first().copied()
    }

    /// Decode data_2 into memory, variable-major, a chunk of the file at a
    /// time. False if it does not fit in memory or cannot be read.
    fn load_data2(&mut self) -> bool {
        if self.data2.is_some() {
            return true;
        }
        if self.data2Failed || self.nrows == 0 || self.nvar == 0 {
            return false;
        }
        self.data2 = self.read_data2();
        self.data2Failed = self.data2.is_none();
        self.data2.is_some()
    }

    fn read_data2(&mut self) -> Option<Vec<f64>> {
        let (nrows, nvar) = (self.nrows, self.nvar);
        let mut data2 = Vec::new();
        data2.try_reserve_exact(nrows.checked_mul(nvar)?).ok()?;
        data2.resize(nrows * nvar, 0.0);
        let elem = self.elem_size() as usize;
        let double = self.doublePrecision;
        // A chunk holds whole rows (binTrans) or whole columns (binNormal).
        let (lines, line_len) = if self.binTrans { (nrows, nvar) } else { (nvar, nrows) };
        let per_chunk = (CHUNK_BYTES / (line_len * elem)).max(1);
        let mut raw = Vec::new();
        raw.try_reserve_exact(per_chunk * line_len * elem).ok()?;
        self.file.seek(SeekFrom::Start(self.var_offset)).ok()?;
        for first in (0..lines).step_by(per_chunk) {
            let count = per_chunk.min(lines - first);
            raw.resize(count * line_len * elem, 0);
            self.file.read_exact(&mut raw).ok()?;
            if self.binTrans {
                for v in 0..nvar {
                    for (r, d) in data2[v * nrows + first..][..count].iter_mut().enumerate() {
                        *d = decode(&raw, r * nvar + v, double);
                    }
                }
            } else {
                for (k, d) in data2[first * nrows..][..count * nrows].iter_mut().enumerate() {
                    *d = decode(&raw, k, double);
                }
            }
        }
        Some(data2)
    }

    /// Whether data_2 is in memory. A binTrans file is loaded: reading any one
    /// of its columns already reads all of it.
    fn columns_in_memory(&mut self) -> bool {
        if self.binTrans {
            self.load_data2()
        } else {
            self.data2.is_some()
        }
    }

    /// C's `omc_matlab4_read_all_vals`, for a caller that will read most columns.
    pub fn read_all(&mut self) -> bool {
        self.load_data2()
    }

    /// 0-based column `col` read from the file: one contiguous read (binNormal)
    /// or one pass over data_2 (binTrans).
    fn disk_column(&mut self, col: usize) -> Option<Vec<f64>> {
        let (nrows, nvar) = (self.nrows, self.nvar);
        let elem = self.elem_size();
        let ty = if self.doublePrecision { 0 } else { 10 };
        if !self.binTrans {
            self.file
                .seek(SeekFrom::Start(self.var_offset + col as u64 * nrows as u64 * elem))
                .ok()?;
            return read_doubles(ty, nrows, &mut self.file).ok();
        }
        let row_len = nvar.checked_mul(elem as usize)?;
        let per_chunk = (CHUNK_BYTES / row_len).max(1);
        let mut raw = Vec::new();
        raw.try_reserve_exact(per_chunk.checked_mul(row_len)?).ok()?;
        let mut out = Vec::new();
        out.try_reserve_exact(nrows).ok()?;
        self.file.seek(SeekFrom::Start(self.var_offset)).ok()?;
        for first in (0..nrows).step_by(per_chunk) {
            let count = per_chunk.min(nrows - first);
            raw.resize(count * row_len, 0);
            self.file.read_exact(&mut raw).ok()?;
            out.extend((0..count).map(|r| decode(&raw, r * nvar + col, self.doublePrecision)));
        }
        Some(out)
    }

    fn time_column(&mut self) -> Option<&[f64]> {
        if self.nrows == 0 || self.nvar == 0 {
            return None;
        }
        if self.columns_in_memory() {
            return self.data2.as_deref().map(|d| &d[..self.nrows]);
        }
        if self.time.is_none() {
            self.time = Some(self.disk_column(0)?);
        }
        self.time.as_deref()
    }

    /// Single value of `varIndex` (1-based, sign for negative alias) at row
    /// `timeIndex`. Returns None on read error.
    fn single_val(&mut self, varIndex: i32, timeIndex: usize) -> Option<f64> {
        let absv = varIndex.unsigned_abs() as usize;
        if absv == 0 || absv > self.nvar || timeIndex >= self.nrows {
            return None;
        }
        let v = match (&self.data2, &self.time) {
            (Some(d), _) => d[(absv - 1) * self.nrows + timeIndex],
            (None, Some(t)) if absv == 1 => t[timeIndex],
            _ => self.disk_val(timeIndex, absv - 1)?,
        };
        Some(if varIndex < 0 { -v } else { v })
    }

    /// Full trajectory of a variable column (1-based index, sign for alias).
    pub fn read_vals(&mut self, varIndex: i32) -> Option<Vec<f64>> {
        let absv = varIndex.unsigned_abs() as usize;
        if absv == 0 || absv > self.nvar || self.nrows == 0 {
            return None;
        }
        let col = absv - 1;
        let mut v = if self.columns_in_memory() {
            self.data2.as_ref()?[col * self.nrows..][..self.nrows].to_vec()
        } else if col == 0 {
            self.time_column()?.to_vec()
        } else {
            self.disk_column(col)?
        };
        if varIndex < 0 {
            v.iter_mut().for_each(|x| *x = -*x);
        }
        Some(v)
    }

    pub fn start_time(&mut self) -> f64 {
        if self.startTime.is_none() {
            self.startTime = self.single_val(1, 0).or(Some(f64::NAN));
        }
        self.startTime.unwrap()
    }

    pub fn stop_time(&mut self) -> f64 {
        if self.stopTime.is_none() {
            let last = self.nrows.saturating_sub(1);
            self.stopTime = self.single_val(1, last).or(Some(f64::NAN));
        }
        self.stopTime.unwrap()
    }

    /// Look up a variable by name, with the same fallbacks as
    /// `omc_matlab4_find_var` (time/Time, Dymola/OMC der-style). Returns the
    /// index into `allInfo`.
    pub fn find_var(&self, varName: &str) -> Option<usize> {
        find_var_in(&self.allInfo, varName)
    }

    pub fn val(&mut self, varIdx: usize, time: f64) -> Option<f64> {
        let isParam = self.allInfo[varIdx].isParam;
        let index = self.allInfo[varIdx].index;
        if isParam {
            return Some(if index < 0 {
                -self.params[(index.unsigned_abs() as usize) - 1]
            } else {
                self.params[(index as usize) - 1]
            });
        }
        if time > self.stop_time() || time < self.start_time() {
            return None;
        }
        self.interp_val(index, time)
    }

    /// Interpolate a data_2 column directly by its 1-based index (sign selects
    /// the negated alias) at `time`, mirroring the variable branch of
    /// `omc_matlab4_val`. Used by the resampling path of filterSimulationResults,
    /// which works with raw column indices rather than `allInfo` entries.
    pub fn interp_val(&mut self, index: i32, time: f64) -> Option<f64> {
        let (i1, w1, i2, w2) = find_closest_points(time, self.time_column()?);
        if i2 < 0 {
            self.single_val(index, i1 as usize)
        } else if i1 < 0 {
            self.single_val(index, i2 as usize)
        } else {
            let y1 = self.single_val(index, i1 as usize)?;
            let y2 = self.single_val(index, i2 as usize)?;
            Some(w1 * y1 + w2 * y2)
        }
    }
}

/// Port of `find_closest_points`: returns `(index1, weight1, index2, weight2)`
/// such that `value(key) = weight1*vec[index1] + weight2*vec[index2]`. On an
/// exact match `index2` is -1 and `weight1` is 1.
pub fn find_closest_points(key: f64, vec: &[f64]) -> (i32, f64, i32, f64) {
    let mut min: i32 = 0;
    let mut max: i32 = vec.len() as i32 - 1;
    loop {
        let mid = min + (max - min) / 2;
        if key == vec[mid as usize] {
            // On repeated timestamps (events) take the right limit.
            let mut mid = mid;
            while mid < max && vec[mid as usize] == vec[(mid + 1) as usize] {
                mid += 1;
            }
            return (mid, 1.0, -1, 0.0);
        } else if key > vec[mid as usize] {
            min = mid + 1;
        } else {
            max = mid - 1;
        }
        if max <= min {
            break;
        }
    }
    if max == min {
        if key > vec[max as usize] {
            max += 1;
        } else {
            min -= 1;
        }
    }
    // When the key lies outside the sampled range one of the indices walks
    // off the vector (`min == -1` before the first point, `max == len`
    // after the last). The C version still computes the weights from the
    // out-of-bounds neighbour — a garbage read whose result the caller
    // never uses, because it only reads the in-range index when the other
    // one is -1. In Rust that read panics, so report the out-of-range side
    // as -1 with the full weight on the valid index instead.
    if min < 0 {
        return (max, 1.0, -1, 0.0);
    }
    if max >= vec.len() as i32 {
        return (min, 1.0, -1, 0.0);
    }
    let w1 = (key - vec[min as usize]) / (vec[max as usize] - vec[min as usize]);
    (max, w1, min, 1.0 - w1)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn matrix(out: &mut Vec<u8>, name: &str, ty: u32, mrows: usize, ncols: usize, data: &[u8]) {
        for v in [ty, mrows as u32, ncols as u32, 0, name.len() as u32 + 1] {
            out.extend_from_slice(&v.to_le_bytes());
        }
        out.extend_from_slice(name.as_bytes());
        out.push(0);
        out.extend_from_slice(data);
    }

    fn text(out: &mut Vec<u8>, name: &str, cols: &[&str]) {
        let mrows = cols.iter().map(|c| c.len()).max().unwrap_or(0) + 1;
        let data: Vec<u8> = cols
            .iter()
            .flat_map(|c| c.bytes().chain(std::iter::repeat(0)).take(mrows))
            .collect();
        matrix(out, name, 51, mrows, cols.len(), &data);
    }

    fn doubles(v: &[f64]) -> Vec<u8> {
        v.iter().flat_map(|x| x.to_le_bytes()).collect()
    }

    /// time and x over two rows, with `extra` text matrices written right
    /// before the matrix named by their first element.
    fn result_file(path: &std::path::Path, extra: &[(&str, &str)]) {
        let mut out = Vec::new();
        let mut before = |out: &mut Vec<u8>, name: &str| {
            for (at, extra) in extra {
                if *at == name {
                    text(out, extra, &["P.Mode(Off, Heat, Cool)"]);
                }
            }
        };
        before(&mut out, "Aclass");
        let aclass: Vec<u8> = (0..11)
            .flat_map(|c| ["Atrajectory", "1.1", "", "binTrans"].map(|r| *r.as_bytes().get(c).unwrap_or(&0)))
            .collect();
        matrix(&mut out, "Aclass", 51, 4, 11, &aclass);
        before(&mut out, "name");
        text(&mut out, "name", &["time", "x"]);
        before(&mut out, "description");
        text(&mut out, "description", &["Simulation time [s]", "a real"]);
        before(&mut out, "dataInfo");
        let info: Vec<u8> = [0, 1, 0, -1, 2, 2, 0, 0]
            .iter()
            .flat_map(|v: &i32| v.to_le_bytes())
            .collect();
        matrix(&mut out, "dataInfo", 20, 4, 2, &info);
        before(&mut out, "data_1");
        matrix(&mut out, "data_1", 0, 1, 2, &doubles(&[0.0, 1.0]));
        before(&mut out, "data_2");
        matrix(&mut out, "data_2", 0, 2, 2, &doubles(&[0.0, 5.0, 1.0, 7.0]));
        std::fs::write(path, out).unwrap();
    }

    /// A matrix the reader does not know is skipped wherever it is; one of the
    /// six out of its place is still an error.
    #[test]
    fn other_matrices_are_skipped() {
        let path = std::env::temp_dir().join(format!("omc_mat_reader_skip_{}.mat", std::process::id()));
        for at in ["Aclass", "description", "data_1", "data_2"] {
            result_file(&path, &[(at, "enumerations")]);
            let mut r = MatReader::open(path.to_str().unwrap()).unwrap_or_else(|e| panic!("before {at}: {e}"));
            assert_eq!(r.nrows, 2, "before {at}");
            let x = r.allInfo[r.find_var("x").unwrap()].index;
            assert_eq!(r.read_vals(x).as_deref(), Some(&[5.0, 7.0][..]), "before {at}");
        }
        result_file(&path, &[("dataInfo", "data_1")]);
        assert_eq!(
            MatReader::open(path.to_str().unwrap()).err().as_deref(),
            Some("Matrix name mismatch: dataInfo")
        );
        let _ = std::fs::remove_file(&path);
    }

    /// time, x, its negated alias y and a parameter p over five rows with an
    /// event at t=1, in either storage order and precision.
    fn table_file(path: &std::path::Path, bin_trans: bool, single: bool) {
        let names = ["time", "x", "y", "p"];
        let info = [[0, 1, 0, -1], [2, 2, 0, 0], [2, -2, 0, 0], [1, 2, 0, 0]];
        let time = [0.0, 1.0, 1.0, 2.0, 3.0];
        let x = [5.0, 7.0, 8.0, 11.0, 13.0];
        let data_2: Vec<f64> = if bin_trans {
            (0..5).flat_map(|i| [time[i], x[i]]).collect()
        } else {
            time.iter().chain(&x).copied().collect()
        };
        let reals = |v: &[f64]| -> Vec<u8> {
            if single {
                v.iter().flat_map(|x| (*x as f32).to_le_bytes()).collect()
            } else {
                doubles(v)
            }
        };
        let len = 1 + names.iter().map(|n| n.len()).max().unwrap();
        let chars = |strs: &[&str]| -> Vec<u8> {
            let padded: Vec<Vec<u8>> = strs
                .iter()
                .map(|s| s.bytes().chain(std::iter::repeat(0)).take(len).collect())
                .collect();
            if bin_trans {
                padded.concat()
            } else {
                (0..len).flat_map(|c| padded.iter().map(move |s| s[c])).collect()
            }
        };
        let order = if bin_trans { "binTrans" } else { "binNormal" };
        let mut out = Vec::new();
        let aclass: Vec<u8> = (0..11)
            .flat_map(|c| ["Atrajectory", "1.1", "", order].map(|r| *r.as_bytes().get(c).unwrap_or(&0)))
            .collect();
        matrix(&mut out, "Aclass", 51, 4, 11, &aclass);
        let n = names.len();
        let dims = |a: usize, b: usize| if bin_trans { (a, b) } else { (b, a) };
        let (r, c) = dims(len, n);
        matrix(&mut out, "name", 51, r, c, &chars(&names));
        matrix(&mut out, "description", 51, r, c, &chars(&["", "", "", ""]));
        let info: Vec<i32> = if bin_trans {
            info.concat()
        } else {
            (0..4).flat_map(|k| info.iter().map(move |i| i[k])).collect()
        };
        let (r, c) = dims(4, n);
        matrix(
            &mut out,
            "dataInfo",
            20,
            r,
            c,
            &info.iter().flat_map(|v| v.to_le_bytes()).collect::<Vec<u8>>(),
        );
        // Both orders store [start, stop] of time, then of p.
        matrix(&mut out, "data_1", 0, 2, 2, &doubles(&[0.0, 3.0, 3.0, 3.0]));
        let (r, c) = dims(2, 5);
        matrix(&mut out, "data_2", if single { 10 } else { 0 }, r, c, &reals(&data_2));
        std::fs::write(path, out).unwrap();
    }

    /// Every storage order and precision gives the same values, with data_2 in
    /// memory and read from the file in chunks.
    #[test]
    fn layouts_and_paths_agree() {
        let path = std::env::temp_dir().join(format!("omc_mat_reader_layouts_{}.mat", std::process::id()));
        for bin_trans in [true, false] {
            for single in [false, true] {
                for in_memory in [true, false] {
                    let case = format!("binTrans={bin_trans} single={single} in_memory={in_memory}");
                    table_file(&path, bin_trans, single);
                    let mut r = MatReader::open(path.to_str().unwrap()).unwrap_or_else(|e| panic!("{case}: {e}"));
                    if in_memory {
                        assert!(r.read_all(), "{case}");
                    } else {
                        r.data2Failed = true;
                    }
                    let var = |r: &MatReader, n: &str| r.find_var(n).unwrap();
                    let x = r.allInfo[var(&r, "x")].index;
                    assert_eq!(
                        r.read_vals(1).as_deref(),
                        Some(&[0.0, 1.0, 1.0, 2.0, 3.0][..]),
                        "{case}"
                    );
                    assert_eq!(
                        r.read_vals(x).as_deref(),
                        Some(&[5.0, 7.0, 8.0, 11.0, 13.0][..]),
                        "{case}"
                    );
                    assert_eq!(
                        r.read_vals(-x).as_deref(),
                        Some(&[-5.0, -7.0, -8.0, -11.0, -13.0][..]),
                        "{case}"
                    );
                    assert_eq!((r.start_time(), r.stop_time()), (0.0, 3.0), "{case}");
                    let (ix, iy, ip) = (var(&r, "x"), var(&r, "y"), var(&r, "p"));
                    assert_eq!(r.val(ix, 0.5), Some(6.0), "{case}");
                    assert_eq!(r.val(ix, 1.0), Some(8.0), "{case}");
                    assert_eq!(r.val(ix, 2.5), Some(12.0), "{case}");
                    assert_eq!(r.val(iy, 2.5), Some(-12.0), "{case}");
                    assert_eq!(r.val(ip, 1.5), Some(3.0), "{case}");
                    assert_eq!(r.val(ix, 3.5), None, "{case}");
                    assert_eq!(r.data2.is_some(), in_memory || (bin_trans && !r.data2Failed), "{case}");
                }
            }
        }
        let _ = std::fs::remove_file(&path);
    }
}
