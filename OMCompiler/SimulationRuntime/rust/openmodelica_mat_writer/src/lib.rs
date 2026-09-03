//! MATLAB v4 (`.mat`) result-file writer for the `wasm-jit` simulation target.
//!
//! Produces the `Aclass`/`name`/`description`/`dataInfo`/`data_1`/`data_2`
//! matrices the OpenModelica C runtime writes (so OMPlot / `omc-diff` read the
//! file unchanged). [`Mat4Stream`] writes the file incrementally, one batch of
//! rows at a time, into any [`Out`]; [`write_mat4`] is the one-shot form over a
//! `Vec<u8>`. No I/O and no wasm intrinsics, so the same code serves the host,
//! the in-wasm session runtimes and the standalone `wasm32-wasip1` module.
//!
//! The caller supplies the per-signal metadata ([`MatVar`]), the time-variant
//! result rows (row-major, `n_reals` columns: `[time | realVars | ...]`) and the
//! scalar parameter values (`params`, in `MatKind::Param` order). How a signal
//! sources its value — a result-buffer column, a parameter slot, or a literal
//! constant — is [`MatKind`].

#![cfg_attr(not(test), no_std)]

extern crate alloc;

use alloc::vec;
use alloc::vec::Vec;

/// How a result signal sources its value in the `.mat`.
/// Mirrors `openmodelica_sim_meta::Neg`.
#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Neg {
    None,
    /// `-v`: shares the aliased row through a negative `dataInfo` index.
    Arith,
    /// `!v` = `1 - v`: not a sign, so it needs a row of its own.
    Not,
}

#[derive(Clone, Copy)]
pub enum MatKind {
    /// The independent variable (`time`): data_2 row 1.
    Time,
    /// A time-variant real signal reading result-buffer column `col` (0-based
    /// into the `[time | realVars]` row layout, so `col >= 1`). Several signals
    /// may share one column (aliases); `negate` flags a negated alias.
    Column { col: u32, negate: Neg },
    /// A time-invariant parameter; its value comes from the `params` slice in
    /// `Param` order. `negate` flags a negated alias of a parameter.
    Param { negate: Neg },
    /// A compile-time constant written directly to `data_1`.
    Const { value: f64 },
}

/// The precision of the real-valued result data (`data_1`/`data_2`). Mirrors C's
/// `MatVer4Type_t` for the real matrices; the `-single` flag selects
/// [`Precision::Single`].
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Precision {
    /// 8-byte IEEE double (C's `MatVer4Type_DOUBLE`).
    Double,
    /// 4-byte IEEE single (C's `MatVer4Type_SINGLE`).
    Single,
}

impl Precision {
    /// The mat v4 type code for the real matrices (C's `MatVer4Type_t`).
    fn type_code(self) -> i32 {
        match self {
            Precision::Double => 0,
            Precision::Single => 10,
        }
    }

    pub fn size(self) -> usize {
        match self {
            Precision::Double => 8,
            Precision::Single => 4,
        }
    }
}

/// One signal in the result file (C-compatible order: time, states, derivatives,
/// algebraics, then parameters). `name`/`comment` borrow the caller's strings.
/// `unvarying` is C's `time_unvarying`: a `Column` signal computed once during
/// initialization, stored in `data_1` rather than `data_2`.
pub struct MatVar<'a> {
    pub name: &'a str,
    pub comment: &'a str,
    pub kind: MatKind,
    pub unvarying: bool,
}

/// Where a [`Mat4Stream`] puts its bytes.
pub trait Out {
    fn write(&mut self, bytes: &[u8]);
    /// Overwrite `bytes` at absolute byte position `pos` (the `data_2` row count,
    /// patched once the last row is in).
    fn write_at(&mut self, pos: u64, bytes: &[u8]);
}

impl Out for Vec<u8> {
    fn write(&mut self, bytes: &[u8]) {
        self.extend_from_slice(bytes);
    }
    fn write_at(&mut self, pos: u64, bytes: &[u8]) {
        let p = pos as usize;
        if let Some(dst) = self.get_mut(p..p + bytes.len()) {
            dst.copy_from_slice(bytes);
        }
    }
}

/// An incremental `.mat` writer: [`Mat4Stream::begin`] writes every matrix up to
/// and including the `data_2` header, [`Mat4Stream::push_rows`] appends rows to
/// `data_2`, and [`Mat4Stream::finish`] patches the row count into that header,
/// as C's `updateHeader_matVer4` does.
pub struct Mat4Stream {
    /// The `data_2` columns after time: `(row column, negation)`.
    varying: Vec<(usize, Neg)>,
    n_reals: usize,
    precision: Precision,
    n_rows: usize,
    /// Absolute position of the `data_2` header's `ncols` field.
    ncols_pos: u64,
    /// Absolute position of the first `data_2` element.
    data2_pos: u64,
    /// `dataInfo` per signal: `[channel, index, interp, extrap]`.
    data_info: Vec<[i32; 4]>,
    /// `data_1`'s first column (row 1 = start time).
    data_1: Vec<f64>,
    buf: Vec<u8>,
}

impl Mat4Stream {
    /// Write the leading matrices for `signals`. `first_row` (the initial result
    /// row, `n_reals` values; empty when the run produced none) gives the
    /// `unvarying` columns their `data_1` value; `params` holds the scalar
    /// parameter values in `MatKind::Param` order.
    #[allow(clippy::too_many_arguments)]
    pub fn begin(
        out: &mut dyn Out,
        signals: &[MatVar],
        start_time: f64,
        stop_time: f64,
        first_row: &[f64],
        n_reals: u32,
        params: &[f64],
        precision: Precision,
    ) -> Mat4Stream {
        let n_reals = n_reals as usize;
        let mut head: Vec<u8> = Vec::new();

        // Aclass (4 x 11 char), rows: "Atrajectory","1.1","","binTrans".
        let aclass_rows = ["Atrajectory", "1.1", "", "binTrans"];
        write_char_matrix_rows(&mut head, "Aclass", &aclass_rows, 11);

        // name / description: each signal occupies one column.
        let names: Vec<&str> = signals.iter().map(|v| v.name).collect();
        let descs: Vec<&str> = signals.iter().map(|v| v.comment).collect();
        write_char_matrix_cols(&mut head, "name", &names);
        write_char_matrix_cols(&mut head, "description", &descs);

        // Names can share a column, an arithmetic negation reading it through a
        // negative dataInfo index; a Boolean one needs the `1 - v` row C's
        // `mat4_emit4` adds.
        let mut referenced = vec![false; n_reals];
        let mut referenced_not = vec![false; n_reals];
        let mut col_unvarying = vec![false; n_reals];
        for v in signals {
            if let MatKind::Column { col, negate } = &v.kind {
                let c = *col as usize;
                if c < n_reals {
                    match negate {
                        Neg::Not => referenced_not[c] = true,
                        _ => referenced[c] = true,
                    }
                    col_unvarying[c] |= v.unvarying;
                }
            }
        }
        // data_1 holds (after the reserved [start,stop] row) one row per scalar
        // signal — `Param` and `Const` — in signal order, then one row per
        // unvarying column.
        let n_scalars = signals
            .iter()
            .filter(|v| matches!(v.kind, MatKind::Param { .. } | MatKind::Const { .. }))
            .count();

        // Assign data_2 rows to varying referenced columns; data_1 rows to
        // unvarying referenced columns (after [start,stop] and the scalar signals).
        let mut col_data2_row = vec![0i32; n_reals];
        let mut col_data1_row = vec![0i32; n_reals];
        let mut not_data2_row = vec![0i32; n_reals];
        let mut not_data1_row = vec![0i32; n_reals];
        let mut varying: Vec<(usize, Neg)> = Vec::new();
        let mut const_cols: Vec<(usize, Neg)> = Vec::new();
        let mut next_const_row: i32 = 2 + n_scalars as i32;
        for c in 1..n_reals {
            for neg in [Neg::None, Neg::Not] {
                let (wanted, d1, d2) = if neg == Neg::Not {
                    (referenced_not[c], &mut not_data1_row, &mut not_data2_row)
                } else {
                    (referenced[c], &mut col_data1_row, &mut col_data2_row)
                };
                if !wanted {
                    continue; // filtered-out variable
                }
                if col_unvarying[c] {
                    const_cols.push((c, neg));
                    d1[c] = next_const_row;
                    next_const_row += 1;
                } else {
                    varying.push((c, neg));
                    d2[c] = 1 + varying.len() as i32;
                }
            }
        }

        // dataInfo (4 x nSignals int32, column-major): [channel, index, interp, extrap].
        let mut data_info: Vec<[i32; 4]> = Vec::with_capacity(signals.len());
        let mut next_scalar_row: i32 = 2;
        for v in signals {
            let info = match &v.kind {
                MatKind::Time => [0, 1, 0, -1],
                MatKind::Column { col, negate } => {
                    let c = *col as usize;
                    let (d1, d2, sgn) = match negate {
                        Neg::Not => (&not_data1_row, &not_data2_row, 1),
                        Neg::Arith => (&col_data1_row, &col_data2_row, -1),
                        Neg::None => (&col_data1_row, &col_data2_row, 1),
                    };
                    if c < n_reals && d1[c] != 0 {
                        [1, sgn * d1[c], 0, 0]
                    } else if c < n_reals && d2[c] != 0 {
                        [2, sgn * d2[c], 0, 0]
                    } else {
                        [0, 1, 0, -1] // unreachable (every Column is referenced); alias time
                    }
                }
                MatKind::Param { negate } => {
                    let r = next_scalar_row;
                    next_scalar_row += 1;
                    [1, if *negate == Neg::Arith { -r } else { r }, 0, 0]
                }
                MatKind::Const { .. } => {
                    let r = next_scalar_row;
                    next_scalar_row += 1;
                    [1, r, 0, 0]
                }
            };
            data_info.push(info);
        }
        let flat: Vec<i32> = data_info.iter().flatten().copied().collect();
        write_int_matrix(&mut head, "dataInfo", 4, signals.len(), &flat);

        // data_1 (nData1 x 2 double, column-major): row 1 = [start, stop]; then the
        // scalar signals (Param values, Const literals), then the unvarying
        // columns. `params` is in `Param`-signal order.
        let n_data1 = 1 + n_scalars + const_cols.len();
        let mut data_1: Vec<f64> = vec![0.0; n_data1 * 2];
        data_1[0] = start_time;
        data_1[n_data1] = stop_time;
        let mut row_idx = 1usize; // 0-based index of data_1 row 2
        let mut param_idx = 0usize;
        for v in signals {
            let val = match &v.kind {
                MatKind::Param { negate } => {
                    let v = params.get(param_idx).copied().unwrap_or(0.0);
                    param_idx += 1;
                    if *negate == Neg::Not { 1.0 - v } else { v }
                }
                MatKind::Const { value } => *value,
                _ => continue,
            };
            data_1[row_idx] = val;
            data_1[n_data1 + row_idx] = val;
            row_idx += 1;
        }
        for &(c, neg) in &const_cols {
            let row = if neg == Neg::Not { not_data1_row[c] } else { col_data1_row[c] };
            let idx = (row - 1) as usize;
            let v = first_row.get(c).copied().unwrap_or(0.0);
            let v = if neg == Neg::Not { 1.0 - v } else { v };
            data_1[idx] = v;
            data_1[n_data1 + idx] = v;
        }
        write_real_matrix(&mut head, "data_1", n_data1, 2, &data_1, precision);
        data_1.truncate(n_data1);

        // data_2 (n_reals2 x n_rows, column-major): time + the varying columns. The
        // row count is patched in by `finish`.
        let n_reals2 = 1 + varying.len();
        let ncols_pos = head.len() as u64 + 8;
        write_mat_header(&mut head, "data_2", precision.type_code(), n_reals2, 0);
        let data2_pos = head.len() as u64;
        out.write(&head);

        Mat4Stream { varying, n_reals, precision, n_rows: 0, ncols_pos, data2_pos, data_info, data_1, buf: Vec::new() }
    }

    /// Append `rows` (row-major, `n_reals` values each) to `data_2`.
    pub fn push_rows(&mut self, out: &mut dyn Out, rows: &[f64]) {
        let n_reals = self.n_reals.max(1);
        let n = rows.len() / n_reals;
        if n == 0 {
            return;
        }
        self.buf.clear();
        self.buf.reserve(n * (1 + self.varying.len()) * self.precision.size());
        for row in rows.chunks_exact(n_reals) {
            push_real(&mut self.buf, row[0], self.precision); // time
            for &(c, neg) in &self.varying {
                let v = row[c];
                push_real(&mut self.buf, if neg == Neg::Not { 1.0 - v } else { v }, self.precision);
            }
        }
        out.write(&self.buf);
        self.n_rows += n;
    }

    /// Patch the `data_2` row count. Safe to call more than once.
    pub fn finish(&mut self, out: &mut dyn Out) {
        out.write_at(self.ncols_pos, &(self.n_rows as i32).to_le_bytes());
    }

    pub fn n_rows(&self) -> usize {
        self.n_rows
    }

    /// Columns per `data_2` row (time included).
    pub fn n_reals2(&self) -> usize {
        1 + self.varying.len()
    }

    /// Absolute byte position of the first `data_2` element.
    pub fn data2_pos(&self) -> u64 {
        self.data2_pos
    }

    pub fn precision(&self) -> Precision {
        self.precision
    }

    /// `dataInfo` per signal: `[channel, index, interp, extrap]`, channel 1 =
    /// `data_1`, 2 = `data_2`, a negative index a negated alias.
    pub fn data_info(&self) -> &[[i32; 4]] {
        &self.data_info
    }

    /// `data_1`'s values (its first column): index `dataInfo` channel-1 entries
    /// with `index - 1`.
    pub fn data_1(&self) -> &[f64] {
        &self.data_1
    }
}

/// Serialize the whole MATLAB v4 result file for `signals`. `rows` is the
/// row-major time-variant buffer (`n_reals` columns per row, column 0 = time);
/// `params` holds the scalar parameter values in `MatKind::Param` order.
pub fn write_mat4(
    signals: &[MatVar],
    start_time: f64,
    stop_time: f64,
    rows: &[f64],
    n_reals: u32,
    params: &[f64],
    precision: Precision,
) -> Vec<u8> {
    let mut out: Vec<u8> = Vec::new();
    let first_row = rows.get(..n_reals as usize).unwrap_or(&[]);
    let mut s = Mat4Stream::begin(&mut out, signals, start_time, stop_time, first_row, n_reals, params, precision);
    out.reserve(rows.len() / (n_reals as usize).max(1) * s.n_reals2() * precision.size());
    s.push_rows(&mut out, rows);
    s.finish(&mut out);
    out
}

fn push_real(out: &mut Vec<u8>, v: f64, precision: Precision) {
    match precision {
        Precision::Double => out.extend_from_slice(&v.to_le_bytes()),
        Precision::Single => out.extend_from_slice(&(v as f32).to_le_bytes()),
    }
}

/// MATLAB v4 matrix type code: `1000*M + 100*O + 10*P + T`. M=0 (little-endian
/// IEEE), O=0; P selects the element type (0 double, 2 int32, 5 uint8); T=1 for
/// a text (char) matrix, 0 for numeric.
fn mat_type(p: i32, text: bool) -> i32 {
    10 * p + if text { 1 } else { 0 }
}

fn write_mat_header(out: &mut Vec<u8>, name: &str, ty: i32, mrows: usize, ncols: usize) {
    out.extend_from_slice(&ty.to_le_bytes());
    out.extend_from_slice(&(mrows as i32).to_le_bytes());
    out.extend_from_slice(&(ncols as i32).to_le_bytes());
    out.extend_from_slice(&0i32.to_le_bytes()); // imagf
    out.extend_from_slice(&((name.len() + 1) as i32).to_le_bytes());
    out.extend_from_slice(name.as_bytes());
    out.push(0);
}

fn write_real_matrix(out: &mut Vec<u8>, name: &str, mrows: usize, ncols: usize, data: &[f64], precision: Precision) {
    write_mat_header(out, name, precision.type_code(), mrows, ncols);
    for v in data {
        push_real(out, *v, precision);
    }
}

fn write_int_matrix(out: &mut Vec<u8>, name: &str, mrows: usize, ncols: usize, data: &[i32]) {
    write_mat_header(out, name, mat_type(2, false), mrows, ncols);
    for v in data {
        out.extend_from_slice(&v.to_le_bytes());
    }
}

/// Write a char matrix whose columns are `cols` (each string null-padded to the
/// longest length + 1). Column-major storage: element (r,c) at `c*mrows + r`.
fn write_char_matrix_cols(out: &mut Vec<u8>, name: &str, cols: &[&str]) {
    let mrows = cols.iter().map(|s| s.len()).max().unwrap_or(0) + 1;
    let ncols = cols.len();
    write_mat_header(out, name, mat_type(5, true), mrows, ncols);
    for c in cols {
        let bytes = c.as_bytes();
        for r in 0..mrows {
            out.push(if r < bytes.len() { bytes[r] } else { 0 });
        }
    }
}

/// Write a char matrix from explicit rows (each padded to `ncols`). Column-major
/// storage: element (r,c) at `c*mrows + r`.
fn write_char_matrix_rows(out: &mut Vec<u8>, name: &str, rows: &[&str], ncols: usize) {
    let mrows = rows.len();
    write_mat_header(out, name, mat_type(5, true), mrows, ncols);
    for c in 0..ncols {
        for r in rows {
            let bytes = r.as_bytes();
            out.push(if c < bytes.len() { bytes[c] } else { 0 });
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn var<'a>(name: &'a str, comment: &'a str, kind: MatKind) -> MatVar<'a> {
        MatVar { name, comment, kind, unvarying: false }
    }

    /// Locate a named matrix in the v4 stream and return (mrows, ncols, payload).
    fn find_matrix<'a>(buf: &'a [u8], want: &str) -> (usize, usize, &'a [u8]) {
        let mut p = 0;
        while p + 20 <= buf.len() {
            let ty = i32::from_le_bytes(buf[p..p + 4].try_into().unwrap());
            let mrows = i32::from_le_bytes(buf[p + 4..p + 8].try_into().unwrap()) as usize;
            let ncols = i32::from_le_bytes(buf[p + 8..p + 12].try_into().unwrap()) as usize;
            let namelen = i32::from_le_bytes(buf[p + 16..p + 20].try_into().unwrap()) as usize;
            let name = core::str::from_utf8(&buf[p + 20..p + 20 + namelen - 1]).unwrap();
            let p_elt = if ty % 10 == 1 {
                1 // char/uint8
            } else if (ty / 10) % 10 == 2 {
                4 // int32
            } else if (ty / 10) % 10 == 1 {
                4 // single
            } else {
                8 // double
            };
            let data_off = p + 20 + namelen;
            let data_len = mrows * ncols * p_elt;
            if name == want {
                return (mrows, ncols, &buf[data_off..data_off + data_len]);
            }
            p = data_off + data_len;
        }
        panic!("matrix `{want}` not found");
    }

    fn f64s(payload: &[u8]) -> Vec<f64> {
        payload.chunks_exact(8).map(|c| f64::from_le_bytes(c.try_into().unwrap())).collect()
    }
    fn f32s(payload: &[u8]) -> Vec<f32> {
        payload.chunks_exact(4).map(|c| f32::from_le_bytes(c.try_into().unwrap())).collect()
    }
    fn i32s(payload: &[u8]) -> Vec<i32> {
        payload.chunks_exact(4).map(|c| i32::from_le_bytes(c.try_into().unwrap())).collect()
    }

    /// time + one varying real state + one parameter + one constant, 3 rows.
    /// Row layout `n_reals = 2`: column 0 = time, column 1 = the state `x`.
    #[test]
    fn writes_expected_matrices() {
        let vars = [
            var("time", "Time in s", MatKind::Time),
            var("x", "", MatKind::Column { col: 1, negate: Neg::None }),
            var("p", "a param", MatKind::Param { negate: Neg::None }),
            var("k", "", MatKind::Const { value: 9.0 }),
        ];
        // 3 communication points; x ramps 0,1,2.
        let rows = [0.0, 0.0, /*r1*/ 0.5, 1.0, /*r2*/ 1.0, 2.0];
        let params = [7.0]; // p = 7
        let buf = write_mat4(&vars, 0.0, 1.0, &rows, 2, &params, Precision::Double);

        // name matrix: 4 columns, one per signal, column-major null-padded.
        let (mrows, ncols, name_payload) = find_matrix(&buf, "name");
        assert_eq!(ncols, 4);
        let col0 = &name_payload[0..mrows];
        assert_eq!(&col0[..4], b"time");
        assert_eq!(col0[4], 0); // null terminator/pad

        // dataInfo: 4 x 4 int32, column-major. time -> [0,1,0,-1]; x varying ->
        // channel 2 (data_2) index 2; p -> channel 1 (data_1) index 2; k -> [1,3].
        let (_r, _c, di) = find_matrix(&buf, "dataInfo");
        let di = i32s(di);
        assert_eq!(&di[0..4], &[0, 1, 0, -1]); // time
        assert_eq!(&di[4..8], &[2, 2, 0, 0]); // x: data_2 col 2 (after time)
        assert_eq!(&di[8..12], &[1, 2, 0, 0]); // p: data_1 row 2
        assert_eq!(&di[12..16], &[1, 3, 0, 0]); // k: data_1 row 3

        // data_1: (1 + 2 scalars) x 2, column-major. Row1 [start,stop]=[0,1];
        // row2 = p = 7; row3 = k = 9. Both columns identical.
        let (m1, n1, d1) = find_matrix(&buf, "data_1");
        assert_eq!((m1, n1), (3, 2));
        let d1 = f64s(d1);
        assert_eq!(d1, vec![0.0, 7.0, 9.0, 1.0, 7.0, 9.0]);

        // data_2: (1 + 1 varying) x 3 rows, column-major: [t0,x0, t1,x1, t2,x2].
        let (m2, n2, d2) = find_matrix(&buf, "data_2");
        assert_eq!((m2, n2), (2, 3));
        let d2 = f64s(d2);
        assert_eq!(d2, vec![0.0, 0.0, 0.5, 1.0, 1.0, 2.0]);
    }

    /// Rows pushed in several batches produce the same file as one batch, and the
    /// row count lands in the header only at `finish`.
    #[test]
    fn streams_in_batches() {
        let vars = [
            var("time", "", MatKind::Time),
            var("x", "", MatKind::Column { col: 1, negate: Neg::None }),
        ];
        let rows = [0.0, 0.0, 0.5, 1.0, 1.0, 2.0, 1.5, 3.0];
        let whole = write_mat4(&vars, 0.0, 1.5, &rows, 2, &[], Precision::Double);

        let mut out: Vec<u8> = Vec::new();
        let mut s = Mat4Stream::begin(&mut out, &vars, 0.0, 1.5, &rows[..2], 2, &[], Precision::Double);
        s.push_rows(&mut out, &rows[..2]);
        s.push_rows(&mut out, &rows[2..6]);
        assert_eq!(find_matrix(&out, "data_2").1, 0);
        s.push_rows(&mut out, &rows[6..]);
        s.finish(&mut out);
        assert_eq!(out, whole);
        assert_eq!(s.n_rows(), 4);
        assert_eq!(s.data2_pos() as usize, out.len() - 4 * 2 * 8);
    }

    /// An `unvarying` column goes to `data_1` with its initial value; an alias of
    /// it follows.
    #[test]
    fn unvarying_column_in_data_1() {
        let vars = [
            var("time", "", MatKind::Time),
            var("x", "", MatKind::Column { col: 1, negate: Neg::None }),
            MatVar { name: "c", comment: "", kind: MatKind::Column { col: 2, negate: Neg::None }, unvarying: true },
            var("mc", "", MatKind::Column { col: 2, negate: Neg::Arith }),
        ];
        let rows = [0.0, 0.0, 4.0, /*r1*/ 1.0, 1.0, 4.0];
        let buf = write_mat4(&vars, 0.0, 1.0, &rows, 3, &[], Precision::Double);
        let di = i32s(find_matrix(&buf, "dataInfo").2);
        assert_eq!(&di[4..8], &[2, 2, 0, 0]);
        assert_eq!(&di[8..12], &[1, 2, 0, 0]);
        assert_eq!(&di[12..16], &[1, -2, 0, 0]);
        let (m1, _, d1) = find_matrix(&buf, "data_1");
        assert_eq!(m1, 2);
        assert_eq!(f64s(d1), vec![0.0, 4.0, 1.0, 4.0]);
        let (m2, n2, _) = find_matrix(&buf, "data_2");
        assert_eq!((m2, n2), (2, 2));
    }

    /// Arithmetic negation shares the target's row; a Boolean one gets its own.
    #[test]
    fn negated_aliases() {
        let vars = [
            var("time", "", MatKind::Time),
            var("x", "", MatKind::Column { col: 1, negate: Neg::None }),
            var("mx", "", MatKind::Column { col: 1, negate: Neg::Arith }),
            var("b", "", MatKind::Column { col: 2, negate: Neg::None }),
            var("nb", "", MatKind::Column { col: 2, negate: Neg::Not }),
            var("np", "", MatKind::Param { negate: Neg::Not }),
        ];
        // n_reals = 3: [time, x, b].
        let rows = [0.0, 1.0, 0.0, /*r1*/ 0.5, 2.0, 1.0];
        let buf = write_mat4(&vars, 0.0, 0.5, &rows, 3, &[1.0], Precision::Double);

        let (_r, _c, di) = find_matrix(&buf, "dataInfo");
        let di = i32s(di);
        assert_eq!(&di[4..8], &[2, 2, 0, 0]); // x -> data_2 row 2
        assert_eq!(&di[8..12], &[2, -2, 0, 0]); // mx -> same row, negated
        assert_eq!(&di[12..16], &[2, 3, 0, 0]); // b -> data_2 row 3
        assert_eq!(&di[16..20], &[2, 4, 0, 0]); // nb -> its own derived row
        assert_eq!(&di[20..24], &[1, 2, 0, 0]); // np -> data_1 row 2, not negated

        let (m1, _n1, d1) = find_matrix(&buf, "data_1");
        assert_eq!(f64s(d1)[1], 0.0);
        assert_eq!(m1, 2);

        let (m2, n2, d2) = find_matrix(&buf, "data_2");
        assert_eq!((m2, n2), (4, 2));
        assert_eq!(f64s(d2), vec![0.0, 1.0, 0.0, 1.0, 0.5, 2.0, 1.0, 0.0]);
    }

    /// The type code of a named matrix's header (to assert `-single`'s 10).
    fn matrix_type(buf: &[u8], want: &str) -> i32 {
        let mut p = 0;
        while p + 20 <= buf.len() {
            let ty = i32::from_le_bytes(buf[p..p + 4].try_into().unwrap());
            let mrows = i32::from_le_bytes(buf[p + 4..p + 8].try_into().unwrap()) as usize;
            let ncols = i32::from_le_bytes(buf[p + 8..p + 12].try_into().unwrap()) as usize;
            let namelen = i32::from_le_bytes(buf[p + 16..p + 20].try_into().unwrap()) as usize;
            let name = core::str::from_utf8(&buf[p + 20..p + 20 + namelen - 1]).unwrap();
            let p_elt = if ty % 10 == 1 { 1 } else if (ty / 10) % 10 == 2 { 4 } else if (ty / 10) % 10 == 1 { 4 } else { 8 };
            let data_off = p + 20 + namelen;
            if name == want {
                return ty;
            }
            p = data_off + mrows * ncols * p_elt;
        }
        panic!("matrix `{want}` not found");
    }

    /// `-single`: the real matrices carry type code 10 and 4-byte elements, and
    /// the values round-trip as `f32`.
    #[test]
    fn single_precision() {
        let vars = [
            var("time", "", MatKind::Time),
            var("x", "", MatKind::Column { col: 1, negate: Neg::None }),
            var("p", "", MatKind::Param { negate: Neg::None }),
        ];
        // 2 rows; x is 0.5 and 1.5 (exact in f32), p = 7 (exact in f32).
        let rows = [0.0, 0.5, 1.0, 1.5];
        let buf = write_mat4(&vars, 0.0, 1.0, &rows, 2, &[7.0], Precision::Single);

        assert_eq!(matrix_type(&buf, "data_1"), 10);
        assert_eq!(matrix_type(&buf, "data_2"), 10);

        let (m1, n1, d1) = find_matrix(&buf, "data_1");
        assert_eq!(d1.len(), m1 * n1 * 4); // 4-byte elements
        assert_eq!(f32s(d1), vec![0.0, 7.0, 1.0, 7.0]);
        let (m2, n2, d2) = find_matrix(&buf, "data_2");
        assert_eq!(d2.len(), m2 * n2 * 4);
        assert_eq!(f32s(d2), vec![0.0, 0.5, 1.0, 1.5]);
    }

    /// A value not exact in `f32` rounds to the nearest single, as C's cast does.
    #[test]
    fn single_precision_rounds() {
        let vars = [
            var("time", "", MatKind::Time),
            var("x", "", MatKind::Column { col: 1, negate: Neg::None }),
        ];
        // 1/3 is not exact in f32; the stored value must equal the f32 rounding.
        let rows = [0.0, 1.0 / 3.0];
        let buf = write_mat4(&vars, 0.0, 0.0, &rows, 2, &[], Precision::Single);
        let (_r, _c, d2) = find_matrix(&buf, "data_2");
        let d2 = f32s(d2);
        assert_eq!(d2[1], (1.0 / 3.0) as f32);
    }

    /// The single-precision file is smaller than the double one, as the test
    /// `s2 > s1` checks.
    #[test]
    fn single_precision_is_smaller() {
        let vars = [
            var("time", "", MatKind::Time),
            var("x", "", MatKind::Column { col: 1, negate: Neg::None }),
        ];
        let rows = [0.0, 0.0, 1.0, 0.5, 2.0, 1.5];
        let single = write_mat4(&vars, 0.0, 2.0, &rows, 2, &[], Precision::Single);
        let double = write_mat4(&vars, 0.0, 2.0, &rows, 2, &[], Precision::Double);
        assert!(single.len() < double.len());
    }
}
