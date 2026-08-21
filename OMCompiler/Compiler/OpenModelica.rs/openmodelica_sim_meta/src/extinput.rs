//! `-csvInput`: the external input trajectory, C's `simulation/solver/external_input.c`.
//!
//! Applied once at initialization, where C lets the file set the inputs' start
//! values (`initializeModel`), then armed for the integration loop and for the
//! optimizer's initial guess — but not for the Ipopt iterations, whose inputs
//! come from `vopt`.

use alloc::format;
use alloc::string::String;
use alloc::vec;
use alloc::vec::Vec;

use crate::omclog;

/// C's `simulationInfo->external_input`.
pub(crate) struct ExternalInput {
    /// Sample times, ascending.
    t: Vec<f64>,
    /// `u[step][input]`, 0 for an input the file has no column for.
    u: Vec<Vec<f64>>,
    /// The bracket `[i, i+1]` the last update used; the search continues from it.
    i: usize,
}

impl ExternalInput {
    /// C's `externalInputallocate`: read the csv and map its columns onto the input
    /// variables by name. `None` when there is no `-csvInput` (C's `active = 0`).
    pub(crate) fn load(file: &str, input_names: &[&str]) -> Option<Self> {
        // `-inputPath` is already folded in by `simflags::parse`.
        let path = String::from(file);
        let Some(text) = read_file(&path) else {
            omclog::error(omclog::STDOUT, false, &format!("Failed to read CSV-file {path}"));
            return None;
        };
        // C's `read_csv`: a leading `"sep=<c>"` names the delimiter and the data
        // starts at byte 8; without it the delimiter is a comma.
        let b = text.as_bytes();
        let (sep, body) = match b {
            [b'"', b's', b'e', b'p', b'=', c, ..] if b.len() > 8 => (*c as char, &text[8..]),
            _ => (',', &text[..]),
        };
        let mut lines = body.lines().filter(|l| !l.trim().is_empty());
        let header: Vec<String> = lines.next()?.split(sep).map(unquote).collect();
        // Which csv column feeds each input; -1 in C, `None` here.
        let col: Vec<Option<usize>> =
            input_names.iter().map(|n| header.iter().position(|h| h == n)).collect();
        let mut t = Vec::new();
        let mut u: Vec<Vec<f64>> = Vec::new();
        for line in lines {
            let row: Vec<f64> =
                line.split(sep).map(|v| unquote(v).parse::<f64>().unwrap_or(0.0)).collect();
            let Some(&time) = row.first() else { continue };
            t.push(time);
            u.push(col.iter().map(|c| c.and_then(|c| row.get(c).copied()).unwrap_or(0.0)).collect());
        }
        if t.is_empty() {
            return None;
        }
        if omclog::active(omclog::SIMULATION) {
            let mut out = String::from("\nExternal Input");
            out.push_str("\n========================================================");
            for (k, time) in t.iter().enumerate() {
                out.push_str(&format!("\nInput: t={time:.6}   \t"));
                for (j, v) in u[k].iter().enumerate() {
                    out.push_str(&format!("u{}(t)= {v:.6} \t", j + 1));
                }
            }
            out.push_str("\n========================================================\n");
            crate::driver::log_line(&out);
        }
        Some(ExternalInput { t, u, i: 0 })
    }

    /// C's `externalInputUpdate`: the inputs at `time`, linearly interpolated in the
    /// bracket the sample times give.
    pub(crate) fn update(&mut self, time: f64, inputs: &mut [f64]) {
        let n = self.t.len();
        if n < 2 {
            inputs.copy_from_slice(&self.u[0][..inputs.len()]);
            return;
        }
        while self.i > 0 && time < self.t[self.i] {
            self.i -= 1;
        }
        while time > self.t[self.i + 1] && self.i + 1 < n - 1 {
            self.i += 1;
        }
        let (t1, t2) = (self.t[self.i], self.t[self.i + 1]);
        if time == t1 {
            copy_row(&self.u[self.i], inputs);
            return;
        }
        if time == t2 {
            copy_row(&self.u[self.i + 1], inputs);
            return;
        }
        let dt = t2 - t1;
        for (k, out) in inputs.iter_mut().enumerate() {
            let (u1, u2) = (self.u[self.i][k], self.u[self.i + 1][k]);
            *out = if u1 == u2 { u1 } else { (u1 * (dt + t1 - time) + (time - t1) * u2) / dt };
        }
    }
}

/// One field as libcsv hands it to C's `read_csv`: unquoted, `""` collapsed.
fn unquote(field: &str) -> String {
    let f = field.trim();
    match f.strip_prefix('"').and_then(|f| f.strip_suffix('"')) {
        Some(inner) => inner.replace("\"\"", "\""),
        None => String::from(f),
    }
}

fn copy_row(row: &[f64], out: &mut [f64]) {
    for (o, v) in out.iter_mut().zip(row) {
        *o = *v;
    }
}

/// A whole file as text. Host-only: the in-wasm runtime has no `std::fs`, and
/// [`crate::simflags::check`] rejects the flag there.
pub(crate) fn read_file(path: &str) -> Option<String> {
    std::fs::read_to_string(path).ok()
}

/// Zeroed inputs, so a `-csvInput` with fewer columns than inputs behaves like C's
/// `calloc`ed rows.
pub(crate) fn empty(n: usize) -> Vec<f64> {
    vec![0.0; n]
}

/// Which slot of an input the file's value goes to.
#[derive(Clone, Copy, PartialEq, Eq)]
pub(crate) enum Slot {
    Start,
    Live,
}

/// C's `externalInputUpdate` + `input_function` as one step.
pub(crate) struct ExtInputHook {
    pub(crate) ext: ExternalInput,
    /// `SimData` offset and width of each input variable, in input order.
    slots: Vec<(u32, crate::WTy)>,
    /// Scratch mirroring C's `simulationInfo->inputVars`.
    inputs: Vec<f64>,
}

impl ExtInputHook {
    /// `None` when the flag is absent, the file unreadable or the model has no
    /// input.
    pub(crate) fn load(inputs: &[crate::InputVar], slot: Slot) -> Option<alloc::boxed::Box<Self>> {
        if inputs.is_empty() {
            return None;
        }
        let file = crate::simflags::with_flags(|f| f.csv_input.clone())?;
        let names: Vec<&str> = inputs.iter().map(|v| v.name.as_str()).collect();
        let ext = ExternalInput::load(&file, &names)?;
        let slots = inputs
            .iter()
            .map(|v| (if slot == Slot::Start { v.start_off } else { v.off }, v.wty))
            .collect();
        Some(alloc::boxed::Box::new(ExtInputHook { ext, slots, inputs: empty(inputs.len()) }))
    }

    /// The same for the optimizer, whose inputs are real `SimData` indices.
    pub(crate) fn load_reals(indices: &[u32], names: &[&str]) -> Option<alloc::boxed::Box<Self>> {
        let file = crate::simflags::with_flags(|f| f.csv_input.clone())?;
        let ext = ExternalInput::load(&file, names)?;
        Some(alloc::boxed::Box::new(ExtInputHook {
            ext,
            slots: indices.iter().map(|&i| (crate::REAL_OFF + i * 8, crate::WTy::F64)).collect(),
            inputs: empty(indices.len()),
        }))
    }

    /// C's `externalInputUpdate` + `input_function` at time `t`.
    pub(crate) fn apply(&mut self, e: &mut dyn crate::driver::SimEngine, sim_data: u32, t: f64) {
        self.ext.update(t, &mut self.inputs);
        for (&(off, wty), &v) in self.slots.iter().zip(&self.inputs) {
            let _ = match wty {
                crate::WTy::F64 => crate::driver::write_f64(e, sim_data + off, v),
                crate::WTy::I32 => crate::driver::write_i32(e, sim_data + off, v as i32),
            };
        }
    }
}

/// The armed hook, consulted by every write of the model clock. A single global
/// for the reason `RES_CTX` is one: runs are serialized per process.
static ACTIVE: core::sync::atomic::AtomicPtr<ExtInputHook> =
    core::sync::atomic::AtomicPtr::new(core::ptr::null_mut());

/// C's `externalInputallocate` .. `externalInputFree` bracket. Boxed rather than
/// borrowed because the caller keeps reading the trajectory while it is armed.
pub(crate) struct Armed;

pub(crate) fn arm(hook: &mut alloc::boxed::Box<ExtInputHook>) -> Armed {
    ACTIVE.store(&mut **hook as *mut ExtInputHook, core::sync::atomic::Ordering::Relaxed);
    Armed
}

impl Drop for Armed {
    fn drop(&mut self) {
        ACTIVE.store(core::ptr::null_mut(), core::sync::atomic::Ordering::Relaxed);
    }
}

/// C's `externalInputUpdate` + `input_function`; nothing without `-csvInput`.
pub(crate) fn apply(e: &mut dyn crate::driver::SimEngine, sim_data: u32, t: f64) {
    let hook = ACTIVE.load(core::sync::atomic::Ordering::Relaxed);
    if !hook.is_null() {
        unsafe { (*hook).apply(e, sim_data, t) };
    }
}
