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
/// `keep` one flag per signal ([`SimMeta::output_keep`]).
pub fn write(
    meta: &SimMeta,
    format: &str,
    rows: &[f64],
    n_reals: u32,
    params: &[f64],
    keep: &[bool],
    precision: Precision,
) -> Option<Vec<u8>> {
    match format {
        "mat" => Some(mat(meta, rows, n_reals, params, keep, precision)),
        "csv" => Some(csv(meta, rows, n_reals, keep).into_bytes()),
        "plt" => Some(plt(meta, rows, n_reals, params, keep)),
        _ => None,
    }
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
    openmodelica_mat_writer::write_mat4(&vars, meta.start_time, meta.stop_time, rows, n_reals, &kept, precision)
}

/// C's `simulation_result_plt`, which omits integer and boolean parameters.
pub fn plt(meta: &SimMeta, rows: &[f64], n_reals: u32, params: &[f64], keep: &[bool]) -> Vec<u8> {
    let emit = |i: usize, k: &MetaKind| keep[i] && !matches!(k, MetaKind::Param { wty: WTy::I32, .. });
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
/// `%.16g` reals and `%i` integers/booleans. Time-invariant signals are not
/// columns.
pub fn csv(meta: &SimMeta, rows: &[f64], n_reals: u32, keep: &[bool]) -> String {
    let layout = &meta.layout;
    let int_col0 = layout.n_reals_row();
    let sens_col0 = layout.sens_col0();
    let cols: Vec<(&str, u32, crate::Neg, bool)> = meta
        .vars
        .iter()
        .zip(keep)
        .filter_map(|(v, &k)| match v.kind {
            MetaKind::Column { col, negate } if k => {
                Some((v.name.as_str(), col, negate, col >= int_col0 && col < sens_col0))
            }
            _ => None,
        })
        .collect();
    let mut out = String::from("\"time\"");
    for (name, ..) in &cols {
        out.push_str(&format!(",\"{}\"", name.replace('"', "\"\"")));
    }
    out.push('\n');
    let n_reals = n_reals.max(1) as usize;
    for row in rows.chunks_exact(n_reals) {
        out.push_str(&crate::driver::format_g(row[0], 16));
        for &(_, col, negate, is_int) in &cols {
            let v = negate.apply_f64(row.get(col as usize).copied().unwrap_or(0.0));
            out.push(',');
            if is_int {
                out.push_str(&format!("{}", v as i64));
            } else {
                out.push_str(&crate::driver::format_g(v, 16));
            }
        }
        out.push('\n');
    }
    out
}
