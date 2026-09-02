//! The result-file writers over the driver's row buffer and [`SimMeta::vars`].
//! Bytes only, so the wasm-jit host, the standalone runtime and a simulation
//! executable share one serialization of each format.

use alloc::format;
use alloc::string::String;
use alloc::vec::Vec;

use openmodelica_mat_writer::{MatVar, Precision};
use openmodelica_plt_writer::PltVar;

use crate::{MetaKind, SimMeta, WTy};

/// The `-outputFormat` values a run can produce. `empty` is accepted and writes
/// nothing; the check happens before the run so a typo fails early, as C does.
pub fn known(format: &str) -> bool {
    matches!(format, "mat" | "csv" | "plt" | "empty")
}

/// The file for `format`, or `None` for `empty`. `rows` is row-major
/// `n_rows * n_reals`, `params` positional over the unfiltered `Param` signals,
/// `keep` one flag per signal ([`SimMeta::output_keep`]). `strings` is the
/// captured String text, row-major `n_rows * Layout::n_str_alg()` — the writers
/// pick out the kept [`MetaKind::StringColumn`] signals themselves.
pub fn write(
    meta: &SimMeta,
    format: &str,
    rows: &[f64],
    n_reals: u32,
    params: &[f64],
    keep: &[bool],
    strings: &[String],
    precision: Precision,
) -> Option<Vec<u8>> {
    match format {
        "mat" => Some(mat(meta, rows, n_reals, params, keep, strings, precision)),
        "csv" => Some(csv(meta, rows, n_reals, keep, strings).into_bytes()),
        "plt" => Some(plt(meta, rows, n_reals, params, keep)),
        _ => None,
    }
}

/// The string-algebraic slot indices of the kept `StringColumn` signals, in
/// signal order — the order the `.mat`'s string-signal numbering and the CSV's
/// String columns follow.
fn string_signals(meta: &SimMeta, keep: &[bool]) -> Vec<u32> {
    meta.vars
        .iter()
        .zip(keep)
        .filter_map(|(v, &k)| match v.kind {
            MetaKind::StringColumn { idx } if k => Some(idx),
            _ => None,
        })
        .collect()
}

/// The `.mat` `stringData` columns: one per (output row, kept String signal), in
/// that order — C appends the same group after every emit. Empty for a run with
/// no String signal.
pub fn string_columns<'a>(
    meta: &SimMeta,
    keep: &[bool],
    strings: &'a [String],
    n_rows: usize,
) -> Vec<&'a str> {
    let signals = string_signals(meta, keep);
    let n_str = meta.layout.n_str_alg() as usize;
    let mut out = Vec::with_capacity(n_rows * signals.len());
    for r in 0..n_rows {
        for &idx in &signals {
            out.push(cell(strings, r, n_str, idx));
        }
    }
    out
}

/// The kept parameters' values, in signal order, for a writer that lists them.
fn kept_params(meta: &SimMeta, params: &[f64], emit: impl Fn(usize, &MetaKind) -> bool) -> Vec<f64> {
    let mut out = Vec::new();
    let mut param_ix = 0usize;
    for (i, v) in meta.vars.iter().enumerate() {
        if matches!(v.kind, MetaKind::Param { .. }) {
            if emit(i, &v.kind) {
                out.push(params.get(param_ix).copied().unwrap_or(0.0));
            }
            param_ix += 1;
        }
    }
    out
}

pub fn mat(
    meta: &SimMeta,
    rows: &[f64],
    n_reals: u32,
    params: &[f64],
    keep: &[bool],
    strings: &[String],
    precision: Precision,
) -> Vec<u8> {
    let kept = kept_params(meta, params, |i, _| keep[i]);
    let vars: Vec<MatVar> = meta
        .vars
        .iter()
        .zip(keep)
        .filter(|(_, k)| **k)
        .map(|(v, _)| MatVar { name: &v.name, comment: &v.comment, kind: v.kind.mat() })
        .collect();
    let n_rows = if n_reals == 0 { 0 } else { rows.len() / n_reals as usize };
    let str_cols = string_columns(meta, keep, strings, n_rows);
    openmodelica_mat_writer::write_mat4(
        &vars,
        meta.start_time,
        meta.stop_time,
        rows,
        n_reals,
        &kept,
        &str_cols,
        precision,
    )
}

/// The captured text of string slot `idx` at output row `r`, or `""` when the
/// run recorded nothing for it (C emits an unassigned String as the empty one).
fn cell(strings: &[String], r: usize, n_str: usize, idx: u32) -> &str {
    if n_str == 0 {
        return "";
    }
    strings.get(r * n_str + idx as usize).map(String::as_str).unwrap_or("")
}

/// C's `simulation_result_plt`, which omits integer and boolean parameters.
pub fn plt(meta: &SimMeta, rows: &[f64], n_reals: u32, params: &[f64], keep: &[bool]) -> Vec<u8> {
    // C's plt writer has no String channel, so a String signal is not a column.
    let emit = |i: usize, k: &MetaKind| {
        keep[i]
            && !matches!(k, MetaKind::Param { wty: WTy::I32, .. })
            && !matches!(k, MetaKind::StringColumn { .. })
    };
    let kept = kept_params(meta, params, emit);
    let signals: Vec<PltVar> = meta
        .vars
        .iter()
        .enumerate()
        .filter(|(i, v)| emit(*i, &v.kind))
        .map(|(_, v)| PltVar { name: &v.name, kind: v.kind.plt() })
        .collect();
    openmodelica_plt_writer::write_plt(&signals, rows, n_reals, &kept)
}

/// C's `simulation_result_csv`: a quoted-name header, then one line per row with
/// `%.16g` reals, `%i` integers/booleans and quoted, escaped String values.
/// Time-invariant signals are not columns.
pub fn csv(meta: &SimMeta, rows: &[f64], n_reals: u32, keep: &[bool], strings: &[String]) -> String {
    let layout = &meta.layout;
    let int_col0 = layout.n_reals_row();
    let sens_col0 = layout.sens_col0();
    let n_str = layout.n_str_alg() as usize;
    /// A CSV column: a numeric one reading the row buffer, or a String one
    /// reading the captured text of a string slot.
    enum Col<'a> {
        Num { name: &'a str, col: u32, negate: crate::Neg, is_int: bool },
        Str { name: &'a str, idx: u32 },
    }
    let cols: Vec<Col> = meta
        .vars
        .iter()
        .zip(keep)
        .filter_map(|(v, &k)| {
            if !k {
                return None;
            }
            match v.kind {
                MetaKind::Column { col, negate } => Some(Col::Num {
                    name: v.name.as_str(),
                    col,
                    negate,
                    is_int: col >= int_col0 && col < sens_col0,
                }),
                MetaKind::StringColumn { idx } => Some(Col::Str { name: v.name.as_str(), idx }),
                _ => None,
            }
        })
        .collect();
    let mut out = String::from("\"time\"");
    for c in &cols {
        let name = match c {
            Col::Num { name, .. } | Col::Str { name, .. } => name,
        };
        out.push_str(&format!(",\"{}\"", escape(name)));
    }
    out.push('\n');
    let n_reals = n_reals.max(1) as usize;
    for (r, row) in rows.chunks_exact(n_reals).enumerate() {
        out.push_str(&crate::driver::format_g(row[0], 16));
        for c in &cols {
            out.push(',');
            match c {
                Col::Num { col, negate, is_int, .. } => {
                    let v = negate.apply_f64(row.get(*col as usize).copied().unwrap_or(0.0));
                    if *is_int {
                        out.push_str(&format!("{}", v as i64));
                    } else {
                        out.push_str(&crate::driver::format_g(v, 16));
                    }
                }
                // A String value is arbitrary text (it can come from a user
                // function), so it is always quoted and its quotes doubled.
                Col::Str { idx, .. } => {
                    out.push('"');
                    out.push_str(&escape(cell(strings, r, n_str, *idx)));
                    out.push('"');
                }
            }
        }
        out.push('\n');
    }
    out
}

/// C's `csvEscapedString`: a `"` inside a quoted CSV field is written twice.
fn escape(s: &str) -> String {
    s.replace('"', "\"\"")
}
