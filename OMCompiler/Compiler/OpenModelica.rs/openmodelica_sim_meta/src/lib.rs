//! Per-model simulation metadata for the `wasm-jit` standalone-export pipeline.
//!
//! The wasm-jit codegen runs on the host and knows everything about a model's
//! `SimData` layout and result variables; the standalone `wasm32-wasip1` command
//! module's `_start` runs in-wasm and needs that same information to drive the
//! integration and serialize the `.mat`. This crate is the wire format between
//! them: the codegen builds a [`SimMeta`], [`encode`]s it into a byte blob that
//! it emits as a data segment of the model module, and the wasip1 runtime
//! [`decode`]s it at startup. `no_std` + `alloc`, no I/O — one definition shared
//! by both sides so the encoder and decoder cannot drift.
//!
//! It carries exactly what the driver, the per-step row capture, the parameter
//! read-back and the `.mat` writer need: the `SimData` [`Layout`], the run
//! scalars, and the ordered result variables ([`MetaVar`]).

#![cfg_attr(not(test), no_std)]

extern crate alloc;

use alloc::string::String;
use alloc::vec::Vec;

/// Byte offset of `time` within `SimData` (mirrors `CodegenWasmJit::TIME_OFF`).
pub const TIME_OFF: u32 = 0;
/// Byte offset of the first real variable within `SimData` (mirrors
/// `CodegenWasmJit::REAL_OFF`): `[ time | states | ders | algs | params… ]`.
pub const REAL_OFF: u32 = 8;

/// The wasm value type a scalar occupies in `SimData` (4-byte `i32` for
/// Integer/Boolean, 8-byte `f64` for Real).
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum WTy {
    I32,
    F64,
}

/// How a result signal sources its value (the run-time superset of
/// `openmodelica_mat_writer::MatKind`: `Param` additionally carries the `SimData`
/// offset/type so the runtime can read the parameter's value back after the run).
#[derive(Clone, PartialEq, Debug)]
pub enum MetaKind {
    /// The independent variable, `time`.
    Time,
    /// A time-variant real signal at result-buffer column `col` (`negate` for a
    /// negated alias).
    Column { col: u32, negate: bool },
    /// A time-invariant parameter read from `SimData` at byte offset `off` as
    /// `wty` (`negate` for a negated alias).
    Param { off: u32, wty: WTy, negate: bool },
    /// A compile-time constant.
    Const { value: f64 },
}

/// One result signal (C-compatible order: time, states, derivatives, algebraics,
/// then parameters).
#[derive(Clone, PartialEq, Debug)]
pub struct MetaVar {
    pub name: String,
    pub comment: String,
    pub kind: MetaKind,
}

/// Fully-resolved `SimData` layout (byte offsets within the block). Mirrors
/// `CodegenWasmJit::SimLayout`; the derived widths must match it exactly.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub struct Layout {
    pub n_states: u32,
    /// `algVars ++ discreteAlgVars` (real algebraics, emitted as time-variant
    /// signals after states and derivatives).
    pub n_real_alg: u32,
    pub rparam_off: u32,
    pub int_off: u32,
    pub iparam_off: u32,
    pub bool_off: u32,
    pub bparam_off: u32,
    pub str_off: u32,
    pub sparam_off: u32,
    pub total: u32,
}

impl Layout {
    /// f64 in the real part of a result row: `time` + states + derivatives + real
    /// algebraics.
    pub fn n_reals_row(&self) -> u32 {
        1 + 2 * self.n_states + self.n_real_alg
    }
    /// Integer algebraic variables (between `int_off` and `iparam_off`).
    pub fn n_int_alg(&self) -> u32 {
        (self.iparam_off - self.int_off) / 4
    }
    /// Boolean algebraic variables (between `bool_off` and `bparam_off`).
    pub fn n_bool_alg(&self) -> u32 {
        (self.bparam_off - self.bool_off) / 4
    }
    /// Total f64 columns in a result row: the real part plus the integer and
    /// boolean algebraics (captured per row as f64).
    pub fn n_row_total(&self) -> u32 {
        self.n_reals_row() + self.n_int_alg() + self.n_bool_alg()
    }
}

/// Everything the standalone wasip1 `_start` needs about one model: its layout,
/// the run scalars, and the ordered result variables.
#[derive(Clone, PartialEq, Debug)]
pub struct SimMeta {
    pub layout: Layout,
    pub start_time: f64,
    pub stop_time: f64,
    pub n_intervals: u32,
    /// Integration method (`"dassl"`, `"euler"`, …; empty = the dassl default).
    pub method: String,
    /// Relative/absolute tolerance for the adaptive integrators.
    pub tolerance: f64,
    /// Result file format (`"mat"`, `"empty"`).
    pub output_format: String,
    /// File-name prefix; the result file is `<prefix>_res.mat`.
    pub prefix: String,
    /// The model's name (diagnostics).
    pub model_name: String,
    pub vars: Vec<MetaVar>,
}

// ─────────────────────────────── wire format ─────────────────────────────────
//
// A flat little-endian encoding behind a 4-byte magic + version. Strings are
// length-prefixed (u32 + utf8 bytes); `Vec` is a u32 count + elements; `MetaKind`
// is a u8 tag + payload. Hand-rolled (no serde) to keep the crate dependency-free
// and trivially buildable for every target.

const MAGIC: &[u8; 4] = b"OMSM";
const VERSION: u32 = 1;

fn put_u32(o: &mut Vec<u8>, v: u32) {
    o.extend_from_slice(&v.to_le_bytes());
}
fn put_f64(o: &mut Vec<u8>, v: f64) {
    o.extend_from_slice(&v.to_le_bytes());
}
fn put_str(o: &mut Vec<u8>, s: &str) {
    put_u32(o, s.len() as u32);
    o.extend_from_slice(s.as_bytes());
}
fn put_kind(o: &mut Vec<u8>, k: &MetaKind) {
    match k {
        MetaKind::Time => o.push(0),
        MetaKind::Column { col, negate } => {
            o.push(1);
            put_u32(o, *col);
            o.push(*negate as u8);
        }
        MetaKind::Param { off, wty, negate } => {
            o.push(2);
            put_u32(o, *off);
            o.push(matches!(wty, WTy::F64) as u8);
            o.push(*negate as u8);
        }
        MetaKind::Const { value } => {
            o.push(3);
            put_f64(o, *value);
        }
    }
}

/// Encode `m` into the byte blob the codegen emits and the runtime decodes.
pub fn encode(m: &SimMeta) -> Vec<u8> {
    let mut o = Vec::new();
    o.extend_from_slice(MAGIC);
    put_u32(&mut o, VERSION);
    let l = &m.layout;
    for v in [
        l.n_states, l.n_real_alg, l.rparam_off, l.int_off, l.iparam_off, l.bool_off, l.bparam_off,
        l.str_off, l.sparam_off, l.total,
    ] {
        put_u32(&mut o, v);
    }
    put_f64(&mut o, m.start_time);
    put_f64(&mut o, m.stop_time);
    put_u32(&mut o, m.n_intervals);
    put_str(&mut o, &m.method);
    put_f64(&mut o, m.tolerance);
    put_str(&mut o, &m.output_format);
    put_str(&mut o, &m.prefix);
    put_str(&mut o, &m.model_name);
    put_u32(&mut o, m.vars.len() as u32);
    for v in &m.vars {
        put_str(&mut o, &v.name);
        put_str(&mut o, &v.comment);
        put_kind(&mut o, &v.kind);
    }
    o
}

/// A cursor over the input with bounds-checked little-endian reads.
struct Reader<'a> {
    b: &'a [u8],
    p: usize,
}
impl<'a> Reader<'a> {
    fn take(&mut self, n: usize) -> Result<&'a [u8], &'static str> {
        let s = self.b.get(self.p..self.p + n).ok_or("sim_meta: truncated")?;
        self.p += n;
        Ok(s)
    }
    fn u32(&mut self) -> Result<u32, &'static str> {
        Ok(u32::from_le_bytes(self.take(4)?.try_into().unwrap()))
    }
    fn f64(&mut self) -> Result<f64, &'static str> {
        Ok(f64::from_le_bytes(self.take(8)?.try_into().unwrap()))
    }
    fn u8(&mut self) -> Result<u8, &'static str> {
        Ok(self.take(1)?[0])
    }
    fn string(&mut self) -> Result<String, &'static str> {
        let n = self.u32()? as usize;
        let s = self.take(n)?;
        Ok(String::from_utf8_lossy(s).into_owned())
    }
    fn kind(&mut self) -> Result<MetaKind, &'static str> {
        Ok(match self.u8()? {
            0 => MetaKind::Time,
            1 => MetaKind::Column { col: self.u32()?, negate: self.u8()? != 0 },
            2 => MetaKind::Param {
                off: self.u32()?,
                wty: if self.u8()? != 0 { WTy::F64 } else { WTy::I32 },
                negate: self.u8()? != 0,
            },
            3 => MetaKind::Const { value: self.f64()? },
            _ => return Err("sim_meta: bad MetaKind tag"),
        })
    }
}

/// Decode a blob produced by [`encode`]. Errors on a bad magic/version or a
/// truncated/corrupt stream.
pub fn decode(bytes: &[u8]) -> Result<SimMeta, &'static str> {
    let mut r = Reader { b: bytes, p: 0 };
    if r.take(4)? != MAGIC {
        return Err("sim_meta: bad magic");
    }
    if r.u32()? != VERSION {
        return Err("sim_meta: unsupported version");
    }
    let layout = Layout {
        n_states: r.u32()?,
        n_real_alg: r.u32()?,
        rparam_off: r.u32()?,
        int_off: r.u32()?,
        iparam_off: r.u32()?,
        bool_off: r.u32()?,
        bparam_off: r.u32()?,
        str_off: r.u32()?,
        sparam_off: r.u32()?,
        total: r.u32()?,
    };
    let start_time = r.f64()?;
    let stop_time = r.f64()?;
    let n_intervals = r.u32()?;
    let method = r.string()?;
    let tolerance = r.f64()?;
    let output_format = r.string()?;
    let prefix = r.string()?;
    let model_name = r.string()?;
    let nvars = r.u32()? as usize;
    let mut vars = Vec::with_capacity(nvars);
    for _ in 0..nvars {
        vars.push(MetaVar { name: r.string()?, comment: r.string()?, kind: r.kind()? });
    }
    Ok(SimMeta {
        layout, start_time, stop_time, n_intervals, method, tolerance, output_format, prefix,
        model_name, vars,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use alloc::string::ToString;
    use alloc::vec;

    fn sample() -> SimMeta {
        SimMeta {
            layout: Layout {
                n_states: 2,
                n_real_alg: 1,
                rparam_off: 8 + (2 * 2 + 1) * 8,
                int_off: 8 + (2 * 2 + 1) * 8 + 2 * 8,
                iparam_off: 8 + (2 * 2 + 1) * 8 + 2 * 8 + 1 * 4,
                bool_off: 8 + (2 * 2 + 1) * 8 + 2 * 8 + 2 * 4,
                bparam_off: 8 + (2 * 2 + 1) * 8 + 2 * 8 + 3 * 4,
                str_off: 8 + (2 * 2 + 1) * 8 + 2 * 8 + 3 * 4,
                sparam_off: 8 + (2 * 2 + 1) * 8 + 2 * 8 + 3 * 4,
                total: 8 + (2 * 2 + 1) * 8 + 2 * 8 + 3 * 4,
            },
            start_time: 0.0,
            stop_time: 1.0,
            n_intervals: 500,
            method: "dassl".to_string(),
            tolerance: 1e-6,
            output_format: "mat".to_string(),
            prefix: "MyModel".to_string(),
            model_name: "MyModel".to_string(),
            vars: vec![
                MetaVar { name: "time".to_string(), comment: "Time in s".to_string(), kind: MetaKind::Time },
                MetaVar { name: "x".to_string(), comment: "".to_string(), kind: MetaKind::Column { col: 1, negate: false } },
                MetaVar { name: "y".to_string(), comment: "neg alias".to_string(), kind: MetaKind::Column { col: 1, negate: true } },
                MetaVar { name: "p".to_string(), comment: "a param".to_string(), kind: MetaKind::Param { off: 88, wty: WTy::F64, negate: false } },
                MetaVar { name: "n".to_string(), comment: "".to_string(), kind: MetaKind::Param { off: 92, wty: WTy::I32, negate: false } },
                MetaVar { name: "k".to_string(), comment: "".to_string(), kind: MetaKind::Const { value: 9.5 } },
            ],
        }
    }

    #[test]
    fn round_trips() {
        let m = sample();
        let blob = encode(&m);
        let back = decode(&blob).expect("decode");
        assert_eq!(m, back);
        // Re-encoding the decoded value is byte-identical (canonical).
        assert_eq!(blob, encode(&back));
    }

    #[test]
    fn layout_widths() {
        let l = sample().layout;
        assert_eq!(l.n_reals_row(), 1 + 2 * 2 + 1); // time + 2 states + 2 ders + 1 alg
        assert_eq!(l.n_int_alg(), 1);
        assert_eq!(l.n_bool_alg(), 1);
        assert_eq!(l.n_row_total(), 6 + 1 + 1);
    }

    #[test]
    fn rejects_bad_input() {
        assert!(decode(b"nope").is_err());
        assert!(decode(&[]).is_err());
        let mut blob = encode(&sample());
        blob.truncate(blob.len() - 1); // chop the last byte
        assert!(decode(&blob).is_err());
    }
}
