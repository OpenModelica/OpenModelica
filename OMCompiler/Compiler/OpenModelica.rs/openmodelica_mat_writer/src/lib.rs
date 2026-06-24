//! MATLAB v4 (`.mat`) result-file writer for the `wasm-jit` simulation target.
//!
//! Produces the `Aclass`/`name`/`description`/`dataInfo`/`data_1`/`data_2`
//! matrices the OpenModelica C runtime writes (so OMPlot / `omc-diff` read the
//! file unchanged), as a `Vec<u8>`. It performs no I/O and uses no wasm
//! intrinsics, so the same code serves the host (writes the bytes to the VFS or
//! disk) and the standalone `wasm32-wasip1` runtime's `_start` (writes them via
//! WASI) — one serializer, no drift.
//!
//! The caller supplies the per-signal metadata ([`MatVar`]), the time-variant
//! result buffer (`rows`, row-major `n_reals` columns: `[time | realVars | ...]`)
//! and the scalar parameter values (`params`, in `MatKind::Param` order). How a
//! signal sources its value — a result-buffer column, a parameter slot, or a
//! literal constant — is [`MatKind`].

#![cfg_attr(not(test), no_std)]

extern crate alloc;

use alloc::vec;
use alloc::vec::Vec;

/// How a result signal sources its value in the `.mat`.
#[derive(Clone, Copy)]
pub enum MatKind {
    /// The independent variable (`time`): data_2 row 1.
    Time,
    /// A time-variant real signal reading result-buffer column `col` (0-based
    /// into the `[time | realVars]` row layout, so `col >= 1`). Several signals
    /// may share one column (aliases); `negate` flags a negated alias.
    Column { col: u32, negate: bool },
    /// A time-invariant parameter; its value comes from the `params` slice in
    /// `Param` order. `negate` flags a negated alias of a parameter.
    Param { negate: bool },
    /// A compile-time constant written directly to `data_1`.
    Const { value: f64 },
}

/// One signal in the result file (C-compatible order: time, states, derivatives,
/// algebraics, then parameters). `name`/`comment` borrow the caller's strings.
pub struct MatVar<'a> {
    pub name: &'a str,
    pub comment: &'a str,
    pub kind: MatKind,
}

/// Serialize the MATLAB v4 result file for `signals`. `rows` is the row-major
/// time-variant buffer (`n_reals` columns per row, column 0 = time); `params`
/// holds the scalar parameter values in `MatKind::Param` order. Returns the file
/// bytes.
pub fn write_mat4(
    signals: &[MatVar],
    start_time: f64,
    stop_time: f64,
    rows: &[f64],
    n_reals: u32,
    params: &[f64],
) -> Vec<u8> {
    let n_reals = n_reals as usize;
    let n_rows = if n_reals == 0 { 0 } else { rows.len() / n_reals };

    let mut out: Vec<u8> = Vec::new();

    // Aclass (4 x 11 char), rows: "Atrajectory","1.1","","binTrans".
    let aclass_rows = ["Atrajectory", "1.1", "", "binTrans"];
    write_char_matrix_rows(&mut out, "Aclass", &aclass_rows, 11);

    // name / description: each signal occupies one column.
    let names: Vec<&str> = signals.iter().map(|v| v.name).collect();
    let descs: Vec<&str> = signals.iter().map(|v| v.comment).collect();
    write_char_matrix_cols(&mut out, "name", &names);
    write_char_matrix_cols(&mut out, "description", &descs);

    // Build data_2 / data_1 like the C runtime: each `Column` signal references
    // a result-buffer column; several names can share one column (alias dedup).
    // A referenced column that is constant over the whole run is stored once in
    // data_1; varying ones go to data_2. Parameters (and constant aliases of
    // them) go to data_1. Negated aliases get a negative dataInfo index.
    let demote = n_rows >= 2;

    // Which buffer columns does any signal reference, and is each constant?
    let mut referenced = vec![false; n_reals];
    for v in signals {
        if let MatKind::Column { col, .. } = &v.kind {
            let c = *col as usize;
            if c < n_reals {
                referenced[c] = true;
            }
        }
    }
    let mut col_is_const = vec![false; n_reals];
    if demote {
        for c in 1..n_reals {
            if referenced[c] {
                let first = rows[c];
                col_is_const[c] = (1..n_rows).all(|r| rows[r * n_reals + c] == first);
            }
        }
    }
    // data_1 holds (after the reserved [start,stop] row) one row per scalar
    // signal — `Param` and `Const` — in signal order, then one row per demoted
    // constant column.
    let n_scalars = signals
        .iter()
        .filter(|v| matches!(v.kind, MatKind::Param { .. } | MatKind::Const { .. }))
        .count();

    // Assign data_2 rows to varying referenced columns; data_1 rows to constant
    // referenced columns (after [start,stop] and the scalar signals).
    let mut col_data2_row = vec![0i32; n_reals];
    let mut col_data1_row = vec![0i32; n_reals];
    let mut varying_cols: Vec<usize> = Vec::new();
    let mut const_cols: Vec<usize> = Vec::new();
    let mut next_const_row: i32 = 2 + n_scalars as i32;
    for c in 1..n_reals {
        if !referenced[c] {
            continue; // column belongs to a filtered-out variable — drop it
        }
        if col_is_const[c] {
            const_cols.push(c);
            col_data1_row[c] = next_const_row;
            next_const_row += 1;
        } else {
            varying_cols.push(c);
            col_data2_row[c] = 1 + varying_cols.len() as i32;
        }
    }

    // dataInfo (4 x nSignals int32, column-major): [channel, index, interp, extrap].
    let mut data_info: Vec<i32> = Vec::with_capacity(signals.len() * 4);
    let mut next_scalar_row: i32 = 2;
    for v in signals {
        let info = match &v.kind {
            MatKind::Time => [0, 1, 0, -1],
            MatKind::Column { col, negate } => {
                let c = *col as usize;
                let sgn = if *negate { -1 } else { 1 };
                if c < n_reals && col_data1_row[c] != 0 {
                    [1, sgn * col_data1_row[c], 0, 0]
                } else if c < n_reals && col_data2_row[c] != 0 {
                    [2, sgn * col_data2_row[c], 0, 0]
                } else {
                    [0, 1, 0, -1] // unreachable (every Column is referenced); alias time
                }
            }
            MatKind::Param { negate } => {
                let r = next_scalar_row;
                next_scalar_row += 1;
                [1, if *negate { -r } else { r }, 0, 0]
            }
            MatKind::Const { .. } => {
                let r = next_scalar_row;
                next_scalar_row += 1;
                [1, r, 0, 0]
            }
        };
        data_info.extend_from_slice(&info);
    }
    write_int_matrix(&mut out, "dataInfo", 4, signals.len(), &data_info);

    // data_1 (nData1 x 2 double, column-major): row 1 = [start, stop]; then the
    // scalar signals (Param values, Const literals), then the demoted constant
    // columns. `params` is in `Param`-signal order.
    let n_data1 = 1 + n_scalars + const_cols.len();
    let mut data_1: Vec<f64> = vec![0.0; n_data1 * 2];
    data_1[0] = start_time;
    data_1[n_data1] = stop_time;
    let mut row_idx = 1usize; // 0-based index of data_1 row 2
    let mut param_idx = 0usize;
    for v in signals {
        let val = match &v.kind {
            MatKind::Param { .. } => {
                let v = params.get(param_idx).copied().unwrap_or(0.0);
                param_idx += 1;
                v
            }
            MatKind::Const { value } => *value,
            _ => continue,
        };
        data_1[row_idx] = val;
        data_1[n_data1 + row_idx] = val;
        row_idx += 1;
    }
    for &c in &const_cols {
        let idx = (col_data1_row[c] - 1) as usize; // 1-based row -> 0-based index
        data_1[idx] = rows[c];
        data_1[n_data1 + idx] = rows[c];
    }
    write_double_matrix(&mut out, "data_1", n_data1, 2, &data_1);

    // data_2 (n_reals2 x n_rows double, column-major): time + the varying columns.
    let n_reals2 = 1 + varying_cols.len();
    let mut data_2: Vec<f64> = Vec::with_capacity(n_rows * n_reals2);
    for r in 0..n_rows {
        data_2.push(rows[r * n_reals]); // time
        for &c in &varying_cols {
            data_2.push(rows[r * n_reals + c]);
        }
    }
    write_double_matrix(&mut out, "data_2", n_reals2, n_rows, &data_2);

    out
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

fn write_double_matrix(out: &mut Vec<u8>, name: &str, mrows: usize, ncols: usize, data: &[f64]) {
    write_mat_header(out, name, mat_type(0, false), mrows, ncols);
    for v in data {
        out.extend_from_slice(&v.to_le_bytes());
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
    fn i32s(payload: &[u8]) -> Vec<i32> {
        payload.chunks_exact(4).map(|c| i32::from_le_bytes(c.try_into().unwrap())).collect()
    }

    /// time + one varying real state + one parameter + one constant, 3 rows.
    /// Row layout `n_reals = 2`: column 0 = time, column 1 = the state `x`.
    #[test]
    fn writes_expected_matrices() {
        let vars = [
            MatVar { name: "time", comment: "Time in s", kind: MatKind::Time },
            MatVar { name: "x", comment: "", kind: MatKind::Column { col: 1, negate: false } },
            MatVar { name: "p", comment: "a param", kind: MatKind::Param { negate: false } },
            MatVar { name: "k", comment: "", kind: MatKind::Const { value: 9.0 } },
        ];
        // 3 communication points; x ramps 0,1,2.
        let rows = [0.0, 0.0, /*r1*/ 0.5, 1.0, /*r2*/ 1.0, 2.0];
        let params = [7.0]; // p = 7
        let buf = write_mat4(&vars, 0.0, 1.0, &rows, 2, &params);

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
}
