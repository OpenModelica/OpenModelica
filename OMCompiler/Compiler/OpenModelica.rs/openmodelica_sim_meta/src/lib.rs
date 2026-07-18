//! Per-model simulation metadata shared between the wasm-jit codegen (host) and
//! the in-wasm simulation driver.
//!
//! The wasm-jit codegen runs on the host and knows everything about a model's
//! `SimData` layout, its result variables, and its solver structure (Jacobian
//! sparsity/coloring, dynamic state sets, per-state nominals). The driver that
//! consumes that information must be able to run **in-wasm** (so `functionODE`
//! and the Jacobian are called wasm→wasm), where it can only see the model's
//! linear memory and an embedded metadata blob. This crate is the wire format
//! between the two: the codegen builds a [`SimMeta`], [`encode`]s it into a byte
//! blob emitted as a data segment of the model module, and the driver [`decode`]s
//! it. `no_std` + `alloc`, no I/O — **one** definition of every layout offset and
//! solver descriptor so the emitter and the driver cannot drift.
//!
//! It carries exactly what the driver, the per-step row capture, the parameter
//! read-back and the `.mat` writer need: the `SimData` [`Layout`], the run
//! scalars, the ordered result variables ([`MetaVar`]), and the solver metadata
//! ([`JacAInfo`], [`StateSetInfo`], state nominals).

#![cfg_attr(not(feature = "std"), no_std)]

extern crate alloc;

use alloc::string::String;
use alloc::vec::Vec;

pub mod driver;

/// Byte offset of `time` within `SimData`.
pub const TIME_OFF: u32 = 0;
/// Byte offset of the first real variable within `SimData`:
/// `[ time | states | ders | algs | params… ]`.
pub const REAL_OFF: u32 = 8;

/// The wasm value type a scalar occupies in `SimData` (4-byte `i32` for
/// Integer/Boolean, 8-byte `f64` for Real). The single definition used by both
/// the codegen and the driver.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum WTy {
    I32,
    F64,
}

/// Fully-resolved layout of one model's `SimData` block. All offsets are byte
/// offsets within the block; all are compile-time constants baked into the
/// generated module. This is the single source of truth: the codegen computes it
/// via [`Layout::new`] and the driver reads it back verbatim from the blob.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub struct Layout {
    pub n_states: u32,
    /// `algVars ++ discreteAlgVars` (the real algebraic variables emitted as
    /// time-variant result signals after the states and derivatives).
    pub n_real_alg: u32,
    /// `functionAlgebraics` also runs the discrete update / saves `pre`, so
    /// drivers call it only in the once-per-step order.
    pub has_when: bool,
    /// The model uses `homotopy()`, so a `functionInitialEquations_lambda0` is
    /// emitted and the driver may fall back to homotopy continuation.
    pub has_homotopy: bool,
    /// `SimData` offset of the homotopy parameter lambda (f64).
    pub lambda_off: u32,
    pub rparam_off: u32,
    pub int_off: u32,
    pub iparam_off: u32,
    pub bool_off: u32,
    pub bparam_off: u32,
    /// String algebraic variables (one i32 String handle each).
    pub str_off: u32,
    /// String parameters (one i32 String handle each).
    pub sparam_off: u32,
    /// External-object variables (one i32 pointer-registry handle each).
    pub eobj_off: u32,
    /// `pre()` regions parallel to the live variable regions.
    pub pre_real_off: u32,
    pub pre_int_off: u32,
    pub pre_bool_off: u32,
    /// `terminate(...)` flag (i32).
    pub terminate_off: u32,
    /// Number of result rows actually written (i32).
    pub n_out_off: u32,
    /// Nonlinear-solver failure flag (i32).
    pub nls_fail_off: u32,
    /// Number of `sample(...)` time events.
    pub n_samples: u32,
    /// Base of the sample parameter region (start/interval f64 pairs).
    pub sample_off: u32,
    /// Base of the per-sample `active` flags (one i32 each).
    pub sample_active_off: u32,
    /// Number of state-event zero-crossing functions.
    pub n_zc: u32,
    /// Base of the zero-crossing value region (one f64 per crossing).
    pub zc_off: u32,
    /// Number of indexed relations (hysteresis count).
    pub n_rel: u32,
    /// Base of the held relation values (one i32 per indexed relation).
    pub relations_off: u32,
    /// Relation evaluation mode (i32): 0 held, 1 event, 2 initialization.
    pub rel_fresh_off: u32,
    /// `storedRelations` snapshot (one i32 per relation).
    pub stored_rel_off: u32,
    /// `relationsPre` (one i32 per relation).
    pub relations_pre_off: u32,
    /// Base of the state-set Jacobian scratch region (f64).
    pub stateset_off: u32,
    /// `mathEventsValuePre` length.
    pub n_math: u32,
    /// Base of the held math-event values (f64 each).
    pub mathevents_off: u32,
    /// Zero-crossing hysteresis tolerance slot (f64).
    pub zctol_off: u32,
    /// Base of the overridable start-value region (one f64 per state).
    pub start_off: u32,
    pub total: u32,
}

impl Layout {
    /// Compute the `SimData` layout from a model's variable/solver counts. The
    /// codegen's single call site; the byte offsets it derives are exactly what
    /// the emitted module bakes in and the driver reads back.
    #[allow(clippy::too_many_arguments)]
    pub fn new(
        n_states: u32,
        n_real_alg: u32,
        n_real_param: u32,
        n_int_alg: u32,
        n_int_param: u32,
        n_bool_alg: u32,
        n_bool_param: u32,
        n_str_alg: u32,
        n_str_param: u32,
        n_eobj: u32,
        n_samples: u32,
        n_zc: u32,
        n_rel: u32,
        n_stateset_f64: u32,
        n_math: u32,
        has_when: bool,
        has_homotopy: bool,
    ) -> Self {
        let n_real = 2 * n_states + n_real_alg; // states | ders | algs
        let rparam_off = REAL_OFF + n_real * 8;
        let int_off = rparam_off + n_real_param * 8;
        let iparam_off = int_off + n_int_alg * 4;
        let bool_off = iparam_off + n_int_param * 4;
        let bparam_off = bool_off + n_bool_alg * 4;
        let str_off = bparam_off + n_bool_param * 4;
        let sparam_off = str_off + n_str_alg * 4;
        let eobj_off = sparam_off + n_str_param * 4;
        // pre() region, 8-aligned so the real pre-slots are naturally aligned.
        let pre_real_off = (eobj_off + n_eobj * 4 + 7) & !7;
        let pre_int_off = pre_real_off + n_real * 8;
        let pre_bool_off = pre_int_off + n_int_alg * 4;
        let terminate_off = pre_bool_off + n_bool_alg * 4;
        let n_out_off = terminate_off + 4;
        let nls_fail_off = n_out_off + 4;
        let lambda_off = (nls_fail_off + 4 + 7) & !7;
        let sample_off = (lambda_off + 8 + 7) & !7;
        let sample_active_off = sample_off + n_samples * 16;
        let zc_off = (sample_active_off + n_samples * 4 + 7) & !7;
        let relations_off = zc_off + n_zc * 8;
        let rel_fresh_off = relations_off + n_rel * 4;
        let stored_rel_off = rel_fresh_off + 4;
        let relations_pre_off = stored_rel_off + n_rel * 4;
        let stateset_off = (relations_pre_off + n_rel * 4 + 7) & !7;
        let mathevents_off = stateset_off + n_stateset_f64 * 8;
        let n_math_slots = if n_math > 0 { n_math + 2 } else { 0 };
        let zctol_off = mathevents_off + n_math_slots * 8;
        let start_off = zctol_off + 8;
        let total = start_off + n_states * 8;
        Layout {
            n_states, n_real_alg, has_when, has_homotopy, lambda_off, rparam_off, int_off, iparam_off,
            bool_off, bparam_off, str_off, sparam_off, eobj_off, pre_real_off, pre_int_off, pre_bool_off,
            terminate_off, n_out_off, nls_fail_off, n_samples, sample_off, sample_active_off, n_zc, zc_off,
            n_rel, relations_off, rel_fresh_off, stored_rel_off, relations_pre_off, stateset_off, n_math,
            mathevents_off, zctol_off, start_off, total,
        }
    }

    /// Byte offset of state `i`'s overridable start-value slot.
    pub fn state_start_off(&self, i: u32) -> u32 {
        self.start_off + i * 8
    }

    /// Offset of the `pre()` slot mirroring a live variable slot at byte offset
    /// `off`, if `off` is in a variable region that carries pre-values.
    pub fn pre_slot_off(&self, off: u32) -> Option<u32> {
        if off >= REAL_OFF && off < self.rparam_off {
            Some(self.pre_real_off + (off - REAL_OFF))
        } else if off >= self.int_off && off < self.iparam_off {
            Some(self.pre_int_off + (off - self.int_off))
        } else if off >= self.bool_off && off < self.bparam_off {
            Some(self.pre_bool_off + (off - self.bool_off))
        } else {
            None
        }
    }

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

/// How a result signal sources its value (the run-time superset of
/// `openmodelica_mat_writer::MatKind`: `Param` additionally carries the `SimData`
/// offset/type so the driver can read the parameter's value back after the run).
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

/// ODE state-Jacobian ∂f/∂x ("A") sparsity + coloring for the colored-FD path.
#[derive(Clone, PartialEq, Debug)]
pub struct JacAInfo {
    pub n: u32,
    /// Each color: the 0-based column (state) indices perturbed together.
    pub colors: Vec<Vec<u32>>,
    /// `rows_by_col[col]` = 0-based rows nonzero in column `col` (CSC).
    pub rows_by_col: Vec<Vec<u32>>,
}

/// Dynamic state-selection metadata for one `$STATESET`. All offsets are
/// SimData-relative bytes.
#[derive(Clone, PartialEq, Debug)]
pub struct StateSetInfo {
    pub n_candidates: u32,
    pub n_states: u32,
    pub n_dummy: u32,
    /// Candidate variable slots (real), candidate order (matches the seeds).
    pub candidate_offs: Vec<u32>,
    /// State variable slots (real), state order.
    pub state_offs: Vec<u32>,
    /// `A[row][col]` integer slots, row-major (`a_offs[row*n_candidates + col]`).
    pub a_offs: Vec<u32>,
    /// Jacobian seed slots (f64), candidate order: set one to 1 to pick a column.
    pub seed_offs: Vec<u32>,
    /// Jacobian result slots (f64), row order (`n_dummy` of them) — column output.
    pub result_offs: Vec<u32>,
}

/// Solver statistics filled by the driver and rendered into the simulation log by
/// the host (`LOG_STATS`, mirroring the C runtime's `### STATISTICS ###`).
#[derive(Default, Clone, Debug)]
pub struct SolveStats {
    pub method: &'static str,
    pub steps: u64,
    pub res_evals: u64,
    pub jac_evals: u64,
    pub err_test_fails: u64,
    pub conv_test_fails: u64,
    pub state_events: u64,
    pub time_events: u64,
}

/// One FMI value reference and the `SimData` slot it names. The value references
/// are `SimCodeUtil.getFMI3ValueReference`'s, so they cannot be derived from the
/// layout geometry -- the codegen records the mapping here instead.
#[derive(Clone, Copy, PartialEq, Debug)]
pub struct FmiVr {
    pub vr: u32,
    pub off: u32,
    pub wty: WTy,
    /// The variable is a negated alias of the slot at `off`; a read negates it.
    pub negate: bool,
    /// A state's start-value slot, 0 for everything else. An Initialization Mode
    /// set must land here: `functionInitStartValues` runs after the parameter
    /// overrides and would overwrite `off` from `$START`.
    pub start_off: u32,
    /// The variable is a String: `off` is its i32 runtime-String-handle slot, so
    /// the adapter reads/writes it through `rt_str_*` rather than as a number.
    pub is_string: bool,
}

/// Everything the driver and the `.mat` writer need about one model: its layout,
/// the run scalars, the ordered result variables, and the solver metadata.
#[derive(Clone, PartialEq, Debug, Default)]
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
    /// ODE state Jacobian sparsity + coloring; `None` ⇒ numerical Jacobian.
    pub jac_a: Option<JacAInfo>,
    /// Dynamic state selection metadata (one per `$STATESET`); empty otherwise.
    pub state_sets: Vec<StateSetInfo>,
    /// Per-state nominal magnitude `max(|nominal|, 1e-32)` for per-state atol;
    /// `1.0` if absent. Empty ⇒ all-ones.
    pub state_nominals: Vec<f64>,
    /// FMI value reference -> `SimData` slot, sorted by `vr`. Only filled for the
    /// FMU export; empty for a plain simulation.
    pub fmi_vrs: Vec<FmiVr>,
    /// Per-zero-crossing description (Modelica source of the relation, e.g.
    /// `x > 0.0`), 1:1 with the layout's zero-crossings — the driver names the
    /// culprit crossing in the chattering message. Empty ⇒ descriptions absent.
    pub zc_desc: Vec<String>,
}

// ─────────────────────────────── wire format ─────────────────────────────────
//
// A flat little-endian encoding behind a 4-byte magic + version. Strings are
// length-prefixed (u32 + utf8 bytes); a `Vec` is a u32 count + elements;
// `MetaKind` / `Option` are a u8 tag + payload. Hand-rolled (no serde) to keep
// the crate dependency-free and trivially buildable for every target.

const MAGIC: &[u8; 4] = b"OMSM";
const VERSION: u32 = 4;

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
fn put_u32s(o: &mut Vec<u8>, v: &[u32]) {
    put_u32(o, v.len() as u32);
    for &x in v {
        put_u32(o, x);
    }
}
fn put_u32s2(o: &mut Vec<u8>, v: &[Vec<u32>]) {
    put_u32(o, v.len() as u32);
    for row in v {
        put_u32s(o, row);
    }
}
fn put_layout(o: &mut Vec<u8>, l: &Layout) {
    for v in [
        l.n_states, l.n_real_alg, l.lambda_off, l.rparam_off, l.int_off, l.iparam_off, l.bool_off,
        l.bparam_off, l.str_off, l.sparam_off, l.eobj_off, l.pre_real_off, l.pre_int_off, l.pre_bool_off,
        l.terminate_off, l.n_out_off, l.nls_fail_off, l.n_samples, l.sample_off, l.sample_active_off,
        l.n_zc, l.zc_off, l.n_rel, l.relations_off, l.rel_fresh_off, l.stored_rel_off, l.relations_pre_off,
        l.stateset_off, l.n_math, l.mathevents_off, l.zctol_off, l.start_off, l.total,
    ] {
        put_u32(o, v);
    }
    o.push(l.has_when as u8);
    o.push(l.has_homotopy as u8);
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

/// Encode `m` into the byte blob the codegen emits and the driver decodes.
pub fn encode(m: &SimMeta) -> Vec<u8> {
    let mut o = Vec::new();
    o.extend_from_slice(MAGIC);
    put_u32(&mut o, VERSION);
    put_layout(&mut o, &m.layout);
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
    match &m.jac_a {
        None => o.push(0),
        Some(j) => {
            o.push(1);
            put_u32(&mut o, j.n);
            put_u32s2(&mut o, &j.colors);
            put_u32s2(&mut o, &j.rows_by_col);
        }
    }
    put_u32(&mut o, m.state_sets.len() as u32);
    for s in &m.state_sets {
        put_u32(&mut o, s.n_candidates);
        put_u32(&mut o, s.n_states);
        put_u32(&mut o, s.n_dummy);
        put_u32s(&mut o, &s.candidate_offs);
        put_u32s(&mut o, &s.state_offs);
        put_u32s(&mut o, &s.a_offs);
        put_u32s(&mut o, &s.seed_offs);
        put_u32s(&mut o, &s.result_offs);
    }
    put_u32(&mut o, m.state_nominals.len() as u32);
    for &v in &m.state_nominals {
        put_f64(&mut o, v);
    }
    put_u32(&mut o, m.fmi_vrs.len() as u32);
    for v in &m.fmi_vrs {
        put_u32(&mut o, v.vr);
        put_u32(&mut o, v.off);
        o.push(matches!(v.wty, WTy::F64) as u8);
        o.push(v.negate as u8);
        put_u32(&mut o, v.start_off);
        o.push(v.is_string as u8);
    }
    put_u32(&mut o, m.zc_desc.len() as u32);
    for d in &m.zc_desc {
        put_str(&mut o, d);
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
    fn u32s(&mut self) -> Result<Vec<u32>, &'static str> {
        let n = self.u32()? as usize;
        let mut v = Vec::with_capacity(n);
        for _ in 0..n {
            v.push(self.u32()?);
        }
        Ok(v)
    }
    fn u32s2(&mut self) -> Result<Vec<Vec<u32>>, &'static str> {
        let n = self.u32()? as usize;
        let mut v = Vec::with_capacity(n);
        for _ in 0..n {
            v.push(self.u32s()?);
        }
        Ok(v)
    }
    fn layout(&mut self) -> Result<Layout, &'static str> {
        let mut l = Layout {
            n_states: self.u32()?,
            n_real_alg: self.u32()?,
            lambda_off: self.u32()?,
            rparam_off: self.u32()?,
            int_off: self.u32()?,
            iparam_off: self.u32()?,
            bool_off: self.u32()?,
            bparam_off: self.u32()?,
            str_off: self.u32()?,
            sparam_off: self.u32()?,
            eobj_off: self.u32()?,
            pre_real_off: self.u32()?,
            pre_int_off: self.u32()?,
            pre_bool_off: self.u32()?,
            terminate_off: self.u32()?,
            n_out_off: self.u32()?,
            nls_fail_off: self.u32()?,
            n_samples: self.u32()?,
            sample_off: self.u32()?,
            sample_active_off: self.u32()?,
            n_zc: self.u32()?,
            zc_off: self.u32()?,
            n_rel: self.u32()?,
            relations_off: self.u32()?,
            rel_fresh_off: self.u32()?,
            stored_rel_off: self.u32()?,
            relations_pre_off: self.u32()?,
            stateset_off: self.u32()?,
            n_math: self.u32()?,
            mathevents_off: self.u32()?,
            zctol_off: self.u32()?,
            start_off: self.u32()?,
            total: self.u32()?,
            has_when: false,
            has_homotopy: false,
        };
        l.has_when = self.u8()? != 0;
        l.has_homotopy = self.u8()? != 0;
        Ok(l)
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
    let layout = r.layout()?;
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
    let jac_a = match r.u8()? {
        0 => None,
        _ => Some(JacAInfo { n: r.u32()?, colors: r.u32s2()?, rows_by_col: r.u32s2()? }),
    };
    let nsets = r.u32()? as usize;
    let mut state_sets = Vec::with_capacity(nsets);
    for _ in 0..nsets {
        state_sets.push(StateSetInfo {
            n_candidates: r.u32()?,
            n_states: r.u32()?,
            n_dummy: r.u32()?,
            candidate_offs: r.u32s()?,
            state_offs: r.u32s()?,
            a_offs: r.u32s()?,
            seed_offs: r.u32s()?,
            result_offs: r.u32s()?,
        });
    }
    let nnom = r.u32()? as usize;
    let mut state_nominals = Vec::with_capacity(nnom);
    for _ in 0..nnom {
        state_nominals.push(r.f64()?);
    }
    let nvr = r.u32()? as usize;
    let mut fmi_vrs = Vec::with_capacity(nvr);
    for _ in 0..nvr {
        let vr = r.u32()?;
        let off = r.u32()?;
        let wty = if r.u8()? != 0 { WTy::F64 } else { WTy::I32 };
        let negate = r.u8()? != 0;
        let start_off = r.u32()?;
        let is_string = r.u8()? != 0;
        fmi_vrs.push(FmiVr { vr, off, wty, negate, start_off, is_string });
    }
    let ndesc = r.u32()? as usize;
    let mut zc_desc = Vec::with_capacity(ndesc);
    for _ in 0..ndesc {
        zc_desc.push(r.string()?);
    }
    Ok(SimMeta {
        layout, start_time, stop_time, n_intervals, method, tolerance, output_format, prefix,
        model_name, vars, jac_a, state_sets, state_nominals, fmi_vrs, zc_desc,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use alloc::string::ToString;
    use alloc::vec;

    fn sample() -> SimMeta {
        SimMeta {
            layout: Layout::new(2, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, false),
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
            jac_a: Some(JacAInfo {
                n: 2,
                colors: vec![vec![0], vec![1]],
                rows_by_col: vec![vec![0, 1], vec![1]],
            }),
            state_sets: vec![StateSetInfo {
                n_candidates: 3,
                n_states: 2,
                n_dummy: 1,
                candidate_offs: vec![8, 16, 24],
                state_offs: vec![8, 16],
                a_offs: vec![100, 104, 108, 112, 116, 120],
                seed_offs: vec![200, 208, 216],
                result_offs: vec![224],
            }],
            state_nominals: vec![1.0, 2.5],
            fmi_vrs: vec![
                FmiVr { vr: 0, off: 8, wty: WTy::F64, negate: false, start_off: 96, is_string: false },
                FmiVr { vr: 7, off: 64, wty: WTy::I32, negate: true, start_off: 0, is_string: true },
            ],
            zc_desc: vec!["x > 0.0".to_string(), "y < 1.0".to_string()],
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
