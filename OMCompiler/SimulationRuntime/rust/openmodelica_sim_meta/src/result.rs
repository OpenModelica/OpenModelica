//! The result-file writers over the driver's rows and [`SimMeta::vars`]. Bytes
//! only, so the wasm-jit host, the in-wasm runtimes, the standalone runtime and a
//! simulation executable share one serialization of each format.
//!
//! [`ResultStream`] writes the file as the rows arrive (C's `sim_result.emit`):
//! `.mat` and `.csv` row by row, `.arrow` in record batches of
//! [`openmodelica_arrow_writer::DEFAULT_BLOCK_ROWS`] rows, `.plt` at the end
//! (its blocks are per variable).

use alloc::boxed::Box;
use alloc::format;
use alloc::string::String;
use alloc::vec::Vec;

use openmodelica_arrow_writer::{ArrowStream, ArrowVar, ColTy, FileMeta};
use openmodelica_mat_writer::{Mat4Stream, MatVar};
pub use openmodelica_mat_writer::Precision;
use openmodelica_plt_writer::{PltKind, PltVar};

use crate::{MetaKind, Neg, SimMeta, VarTy, WTy};

/// The `-outputFormat` values a run can produce. `empty` is accepted and writes
/// nothing; the check happens before the run so a typo fails early, as C does.
pub fn known(format: &str) -> bool {
    matches!(format, "mat" | "csv" | "plt" | "arrow" | "empty")
}

/// The writer a result file's name asks for: its suffix when this runtime has
/// that writer, else `fallback` (the model's `outputFormat`). Diverges from C,
/// which always writes the `outputFormat` under whatever name it was given.
pub fn format_of<'a>(path: &'a str, fallback: &'a str) -> &'a str {
    match path.rsplit_once('.') {
        Some((_, suffix)) if known(suffix) => suffix,
        _ => fallback,
    }
}

/// Where a streamed result file's bytes go: a file, the web store, or a host
/// import from inside wasm. `false` reports a failed write.
pub trait ResultOut {
    fn write(&mut self, bytes: &[u8]) -> bool;
    /// Overwrite `bytes` at absolute position `pos` (the `.mat` row count) and
    /// flush, so the file is consistent afterwards.
    fn write_at(&mut self, pos: u64, bytes: &[u8]) -> bool;
    /// Push buffered bytes to the file (an `.arrow` block under `-mat_sync`).
    fn flush(&mut self) -> bool {
        true
    }
    /// Flush and close; the file is complete once this returns.
    fn close(&mut self) -> bool;
}

/// `-outputFormat=empty`: the rows go nowhere.
struct NullOut;

impl ResultOut for NullOut {
    fn write(&mut self, _bytes: &[u8]) -> bool {
        true
    }
    fn write_at(&mut self, _pos: u64, _bytes: &[u8]) -> bool {
        true
    }
    fn close(&mut self) -> bool {
        true
    }
}

/// Open the run's result stream once initialization has left `SimData`
/// consistent (C's `writeParameterData` point): the `Param` values and the initial
/// row are read here. `out` is called for the file unless `format` is `empty`.
pub fn open_stream(
    e: &mut dyn crate::driver::SimEngine,
    model: &SimMeta,
    sim_data: u32,
    format: &str,
    keep: &[bool],
    precision: Precision,
    out: impl FnOnce() -> Option<Box<dyn ResultOut>>,
) -> crate::driver::Result<ResultStream> {
    let out: Box<dyn ResultOut> = match format {
        "mat" | "csv" | "plt" | "arrow" => out().ok_or("CodegenWasmJit: cannot open the result file")?,
        _ => Box::new(NullOut),
    };
    let params = crate::driver::read_params(e, model, sim_data)?;
    let mut first = Vec::new();
    crate::driver::capture_row(e, &mut first, sim_data, &model.layout)?;
    Ok(ResultStream::open(model, format, keep, &params, &first, model.layout.n_row_total(), precision, out))
}

struct MatOut<'a> {
    out: &'a mut dyn ResultOut,
    ok: &'a mut bool,
}

impl openmodelica_mat_writer::Out for MatOut<'_> {
    fn write(&mut self, bytes: &[u8]) {
        *self.ok &= self.out.write(bytes);
    }
    fn write_at(&mut self, pos: u64, bytes: &[u8]) {
        *self.ok &= self.out.write_at(pos, bytes);
    }
}

struct ArrowOut<'a> {
    out: &'a mut dyn ResultOut,
    ok: &'a mut bool,
}

impl openmodelica_arrow_writer::Out for ArrowOut<'_> {
    fn write(&mut self, bytes: &[u8]) {
        *self.ok &= self.out.write(bytes);
    }
    fn flush(&mut self) {
        *self.ok &= self.out.flush();
    }
}

enum Kind {
    Mat(Mat4Stream),
    Arrow(ArrowStream),
    /// `(column, negation, integer-valued)` per kept signal.
    Csv(Vec<(u32, Neg, bool)>),
    Plt { signals: Vec<(String, PltKind)>, params: Vec<f64>, rows: Vec<f64> },
    Empty,
}

/// A result file written incrementally.
pub struct ResultStream {
    out: Box<dyn ResultOut>,
    kind: Kind,
    n_reals: usize,
    n_rows: usize,
    first_row: Vec<f64>,
    ok: bool,
}

impl ResultStream {
    /// Open the file for `format`, writing everything ahead of the rows. `params`
    /// are the unfiltered `Param` values as initialization left them, `first_row`
    /// the initial result row (its `unvarying` columns land in the `.mat`'s
    /// `data_1`), `keep` one flag per signal ([`SimMeta::output_keep`]).
    #[allow(clippy::too_many_arguments)]
    pub fn open(
        meta: &SimMeta,
        format: &str,
        keep: &[bool],
        params: &[f64],
        first_row: &[f64],
        n_reals: u32,
        precision: Precision,
        mut out: Box<dyn ResultOut>,
    ) -> ResultStream {
        let mut ok = true;
        let sync = crate::simflags::with_flags(|f| f.mat_sync).unwrap_or(0) as usize;
        // The numeric formats have no place for a String signal or parameter.
        let keep_num = numeric_keep(meta, keep);
        let kind = match format {
            "mat" => {
                let kept = kept_params(meta, params, |i, _| keep_num[i]);
                let vars = mat_vars(meta, &keep_num);
                let mut mo = MatOut { out: &mut *out, ok: &mut ok };
                let mut s = Mat4Stream::begin(
                    &mut mo,
                    &vars,
                    meta.start_time,
                    meta.stop_time,
                    first_row,
                    n_reals,
                    &kept,
                    precision,
                );
                s.set_sync(sync);
                Kind::Mat(s)
            }
            "arrow" => {
                let kept = kept_params(meta, params, |i, _| keep[i]);
                let vars = arrow_vars(meta, keep);
                let units = openmodelica_arrow_writer::units::declared(meta.units.iter().cloned());
                let mut ao = ArrowOut { out: &mut *out, ok: &mut ok };
                let mut s = ArrowStream::begin(
                    &mut ao,
                    &vars,
                    &kept,
                    first_row,
                    n_reals,
                    &col_types(meta, precision),
                    openmodelica_arrow_writer::block_rows(sync),
                    resolve_strings(),
                    &FileMeta { span: Some((meta.start_time, meta.stop_time)), units: &units },
                );
                s.set_sync(sync > 0);
                Kind::Arrow(s)
            }
            "csv" => {
                let cols = csv_cols(meta, &keep_num);
                let mut line = String::from("\"time\"");
                for (name, ..) in &cols {
                    line.push_str(&format!(",\"{}\"", name.replace('"', "\"\"")));
                }
                line.push('\n');
                ok &= out.write(line.as_bytes());
                Kind::Csv(cols.into_iter().map(|(_, c, n, i)| (c, n, i)).collect())
            }
            "plt" => {
                let emit = plt_emit(&keep_num);
                Kind::Plt {
                    signals: meta
                        .vars
                        .iter()
                        .enumerate()
                        .filter(|(i, v)| emit(*i, &v.kind))
                        .map(|(_, v)| (v.name.clone(), v.kind.plt()))
                        .collect(),
                    params: kept_params(meta, params, emit),
                    rows: Vec::new(),
                }
            }
            _ => Kind::Empty,
        };
        ResultStream { out, kind, n_reals: n_reals as usize, n_rows: 0, first_row: first_row.to_vec(), ok }
    }

    /// Append `rows` (row-major, `n_reals` values each).
    pub fn push_rows(&mut self, rows: &[f64]) {
        let n_reals = self.n_reals.max(1);
        self.n_rows += rows.len() / n_reals;
        match &mut self.kind {
            Kind::Mat(s) => {
                let mut mo = MatOut { out: &mut *self.out, ok: &mut self.ok };
                s.push_rows(&mut mo, rows);
            }
            Kind::Arrow(s) => {
                let mut ao = ArrowOut { out: &mut *self.out, ok: &mut self.ok };
                s.push_rows(&mut ao, rows);
            }
            Kind::Csv(cols) => {
                let mut text = String::new();
                for row in rows.chunks_exact(n_reals) {
                    csv_line(&mut text, row, cols);
                }
                self.ok &= self.out.write(text.as_bytes());
            }
            Kind::Plt { rows: all, .. } => all.extend_from_slice(rows),
            Kind::Empty => {}
        }
    }

    /// Complete the file. `false` if any write failed.
    pub fn finish(&mut self) -> bool {
        match &mut self.kind {
            Kind::Mat(s) => {
                let mut mo = MatOut { out: &mut *self.out, ok: &mut self.ok };
                s.finish(&mut mo);
            }
            Kind::Arrow(s) => {
                let mut ao = ArrowOut { out: &mut *self.out, ok: &mut self.ok };
                s.finish(&mut ao);
            }
            Kind::Plt { signals, params, rows } => {
                let vars: Vec<PltVar> = signals.iter().map(|(n, k)| PltVar { name: n, kind: *k }).collect();
                let bytes = openmodelica_plt_writer::write_plt(&vars, rows, self.n_reals as u32, params);
                self.ok &= self.out.write(&bytes);
                rows.clear();
            }
            Kind::Csv(_) | Kind::Empty => {}
        }
        self.ok &= self.out.close();
        self.ok
    }

    pub fn n_rows(&self) -> usize {
        self.n_rows
    }

    /// The initial result row (`n_reals` values).
    pub fn first_row(&self) -> &[f64] {
        &self.first_row
    }

    /// The initial result row encoded for a host across the wasm boundary
    /// ([`decode_first_row`]).
    pub fn first_row_blob(&self) -> Vec<u8> {
        let mut o = Vec::with_capacity(4 + self.first_row.len() * 8);
        o.extend_from_slice(&(self.first_row.len() as u32).to_le_bytes());
        for v in &self.first_row {
            o.extend_from_slice(&v.to_le_bytes());
        }
        o
    }
}

/// Decode what [`ResultStream::first_row_blob`] wrote.
pub fn decode_first_row(b: &[u8]) -> Vec<f64> {
    let Some(head) = b.get(..4) else { return Vec::new() };
    let n = u32::from_le_bytes(head.try_into().expect("4 bytes")) as usize;
    (0..n)
        .map_while(|i| b.get(4 + i * 8..12 + i * 8).map(|w| f64::from_le_bytes(w.try_into().expect("8 bytes"))))
        .collect()
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
    let keep_num = numeric_keep(meta, keep);
    match format {
        "mat" => Some(mat(meta, rows, n_reals, params, &keep_num, precision)),
        "arrow" => Some(arrow(meta, rows, n_reals, params, keep, precision)),
        "csv" => Some(csv(meta, rows, n_reals, &keep_num).into_bytes()),
        "plt" => Some(plt(meta, rows, n_reals, params, &keep_num)),
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

fn mat_vars<'a>(meta: &'a SimMeta, keep: &[bool]) -> Vec<MatVar<'a>> {
    meta.vars
        .iter()
        .zip(keep)
        .filter(|(_, k)| **k)
        .map(|(v, _)| MatVar { name: &v.name, comment: &v.comment, kind: v.kind.mat(), unvarying: v.unvarying })
        .collect()
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
    let vars = mat_vars(meta, keep);
    openmodelica_mat_writer::write_mat4(&vars, meta.start_time, meta.stop_time, rows, n_reals, &kept, precision)
}

/// `keep` without the String signals, for the formats that cannot hold them.
fn numeric_keep(meta: &SimMeta, keep: &[bool]) -> Vec<bool> {
    meta.vars.iter().zip(keep).map(|(v, &k)| k && v.ty != VarTy::String).collect()
}

fn resolve_strings() -> openmodelica_arrow_writer::Resolve {
    Box::new(|id| crate::strings::lookup(id).unwrap_or_default())
}

fn arrow_vars<'a>(meta: &'a SimMeta, keep: &[bool]) -> Vec<ArrowVar<'a>> {
    meta.vars
        .iter()
        .zip(keep)
        .filter(|(_, k)| **k)
        .map(|(v, _)| ArrowVar {
            name: &v.name,
            comment: &v.comment,
            unit: &v.unit,
            display_unit: &v.display_unit,
            relative_quantity: v.relative_quantity,
            ty: v.ty,
            discrete: v.discrete,
            kind: v.kind.arrow(),
            unvarying: v.unvarying,
            enumeration: v.enumeration.as_deref(),
        })
        .collect()
}

/// The storage type of each result-row column: reals, then the integer and
/// boolean algebraics, then the sensitivities. `-single` stores the reals as f32.
fn col_types(meta: &SimMeta, precision: Precision) -> Vec<ColTy> {
    let real = match precision {
        Precision::Double => ColTy::F64,
        Precision::Single => ColTy::F32,
    };
    let l = &meta.layout;
    let mut t = Vec::with_capacity(l.n_row_total() as usize);
    t.extend(core::iter::repeat_n(real, l.n_reals_row() as usize));
    t.extend(core::iter::repeat_n(ColTy::I32, l.n_int_alg() as usize));
    t.extend(core::iter::repeat_n(ColTy::Bool, l.n_bool_alg() as usize));
    t.extend(core::iter::repeat_n(real, l.n_sens as usize));
    t.extend(core::iter::repeat_n(ColTy::Str, l.n_str_alg() as usize));
    t
}

pub fn arrow(meta: &SimMeta, rows: &[f64], n_reals: u32, params: &[f64], keep: &[bool], precision: Precision) -> Vec<u8> {
    let kept = kept_params(meta, params, |i, _| keep[i]);
    let vars = arrow_vars(meta, keep);
    let units = openmodelica_arrow_writer::units::declared(meta.units.iter().cloned());
    openmodelica_arrow_writer::write_arrow(&vars, rows, n_reals, &kept, &col_types(meta, precision), resolve_strings(), &FileMeta { span: Some((meta.start_time, meta.stop_time)), units: &units })
}

/// C's `simulation_result_plt` omits integer and boolean parameters.
fn plt_emit(keep: &[bool]) -> impl Fn(usize, &MetaKind) -> bool {
    |i: usize, k: &MetaKind| keep[i] && !matches!(k, MetaKind::Param { wty: WTy::I32, .. })
}

pub fn plt(meta: &SimMeta, rows: &[f64], n_reals: u32, params: &[f64], keep: &[bool]) -> Vec<u8> {
    let emit = plt_emit(keep);
    let kept = kept_params(meta, params, &emit);
    let signals: Vec<PltVar> = meta
        .vars
        .iter()
        .enumerate()
        .filter(|(i, v)| emit(*i, &v.kind))
        .map(|(_, v)| PltVar { name: &v.name, kind: v.kind.plt() })
        .collect();
    openmodelica_plt_writer::write_plt(&signals, rows, n_reals, &kept)
}

/// The `.csv` columns: `(name, column, negation, integer-valued)`. Time-invariant
/// signals are not columns.
fn csv_cols<'a>(meta: &'a SimMeta, keep: &[bool]) -> Vec<(&'a str, u32, Neg, bool)> {
    let layout = &meta.layout;
    let int_col0 = layout.n_reals_row();
    let sens_col0 = layout.sens_col0();
    meta.vars
        .iter()
        .zip(keep)
        .filter_map(|(v, &k)| match v.kind {
            MetaKind::Column { col, negate } if k => {
                Some((v.name.as_str(), col, negate, col >= int_col0 && col < sens_col0))
            }
            _ => None,
        })
        .collect()
}

/// One `%.16g` row line: time, then each column's value (`%i` for integers/booleans).
fn csv_line(out: &mut String, row: &[f64], cols: &[(u32, Neg, bool)]) {
    out.push_str(&crate::driver::format_g(row[0], 16));
    for &(col, negate, is_int) in cols {
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

/// C's `simulation_result_csv`: a quoted-name header, then one line per row.
pub fn csv(meta: &SimMeta, rows: &[f64], n_reals: u32, keep: &[bool]) -> String {
    let cols = csv_cols(meta, keep);
    let mut out = String::from("\"time\"");
    for (name, ..) in &cols {
        out.push_str(&format!(",\"{}\"", name.replace('"', "\"\"")));
    }
    out.push('\n');
    let plain: Vec<(u32, Neg, bool)> = cols.iter().map(|&(_, c, n, i)| (c, n, i)).collect();
    for row in rows.chunks_exact(n_reals.max(1) as usize) {
        csv_line(&mut out, row, &plain);
    }
    out
}
