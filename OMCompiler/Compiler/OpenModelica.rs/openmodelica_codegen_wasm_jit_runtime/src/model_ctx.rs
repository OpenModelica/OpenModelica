//! The run's model and `SimData`, the way C's `NLS_USERDATA` carries its `DATA*`:
//! what the nonlinear solver's analyses need from inside a solve, where the driver
//! is out of reach.
//!
//! `-saveInitialGuess_system=<file.mat>,<nls index>` (C's
//! `B_save_initial_guess_system`) lives here because it needs both. Its request is
//! one-shot: C throws once it has written the file and never comes back.

use alloc::string::String;
use alloc::vec::Vec;

use openmodelica_mat_writer::{MatVar, Precision};
use openmodelica_sim_meta::{MetaKind, SimMeta, WTy, driver};

/// `model` points at the session's own copy, which outlives every solve it drives
/// and is not written to while one runs.
struct Ctx {
    model: *const SimMeta,
    /// The decoded copy [`rt_set_model_context`] made, which `model` points into;
    /// a run whose driver lives in this module points at its own instead.
    owned: Option<alloc::boxed::Box<SimMeta>>,
    sim_data: u32,
    /// `(the name the flag gave, the name to open, system index)`. The two differ
    /// for a host-driven run, whose guest paths are anchored at the preopen root:
    /// the messages quote the flag, the file lands where C's executable put it.
    request: Option<(String, String, i32)>,
}

mod store {
    use super::Ctx;
    use core::cell::UnsafeCell;

    struct Store(UnsafeCell<Ctx>);
    unsafe impl Sync for Store {}
    static CTX: Store = Store(UnsafeCell::new(Ctx {
        model: core::ptr::null(),
        owned: None,
        sim_data: 0,
        request: None,
    }));

    pub fn with<R>(f: impl FnOnce(&mut Ctx) -> R) -> R {
        f(unsafe { &mut *CTX.0.get() })
    }
}

/// Point the writer at the run's model. Cleared with a null `model` at teardown.
pub(crate) fn set_context(model: *const SimMeta, sim_data: u32) {
    store::with(|c| {
        c.owned = None;
        c.model = model;
        c.sim_data = sim_data;
    });
}

/// [`set_context`] for a host-driven run, whose driver and metadata are outside
/// this module: `ptr`/`len` are the model's encoded [`SimMeta`] blob.
#[unsafe(no_mangle)]
pub extern "C" fn rt_set_model_context(meta_ptr: u32, meta_len: u32, sim_data: u32) -> i32 {
    let bytes = unsafe { core::slice::from_raw_parts(meta_ptr as *const u8, meta_len as usize) };
    let Ok(model) = openmodelica_sim_meta::decode(bytes) else { return -1 };
    store::with(|c| {
        let boxed = alloc::boxed::Box::new(model);
        c.model = &*boxed as *const SimMeta;
        c.owned = Some(boxed);
        c.sim_data = sim_data;
    });
    0
}

/// Install `-saveInitialGuess_system`'s file and system index for this run.
pub(crate) fn set_request(request: Option<(String, i32)>) {
    store::with(|c| c.request = request.map(|(p, i)| (p.clone(), p, i)));
}

/// [`set_request`] for a host-driven run, whose runtime has no flag store of its
/// own: `idx < 0` clears it, otherwise `ptr`/`len` are the flag's file name and the
/// name to open, NUL-separated.
#[unsafe(no_mangle)]
pub extern "C" fn rt_set_save_initial_guess(idx: i32, ptr: u32, len: u32) {
    if idx < 0 {
        return store::with(|c| c.request = None);
    }
    let bytes = unsafe { core::slice::from_raw_parts(ptr as *const u8, len as usize) };
    let mut names = bytes.split(|b| *b == 0).map(|s| String::from_utf8_lossy(s).into_owned());
    let shown = names.next().unwrap_or_default();
    let open = names.next().unwrap_or_else(|| shown.clone());
    store::with(|c| c.request = Some((shown, open, idx)));
}

/// The `(name to quote, name to open)` if `eq_index` is the system the flag named,
/// taken so a later solve of the same system does not write it again.
pub(crate) fn take_request(eq_index: u32) -> Option<(String, String)> {
    store::with(|c| match &c.request {
        Some((_, _, idx)) if *idx == eq_index as i32 => {
            c.request.take().map(|(shown, open, _)| (shown, open))
        }
        _ => None,
    })
}

/// The run's model, once it has been installed.
pub(crate) fn with_model<R>(f: impl FnOnce(&SimMeta) -> R) -> Option<R> {
    let model = store::with(|c| c.model);
    (!model.is_null()).then(|| f(unsafe { &*model }))
}

/// C's `mat4_init4` + `mat4_writeParameterData4` + `mat4_emit4`.
pub(crate) fn write(path: &str) -> Result<(), &'static str> {
    let (model, sim_data) = store::with(|c| (c.model, c.sim_data));
    if model.is_null() {
        return Err("no model to write the initial guess from");
    }
    let model: &SimMeta = unsafe { &*model };
    let engine = ReadOnly;
    let mut rows = Vec::new();
    driver::capture_row(&engine, &mut rows, sim_data, &model.layout)?;
    let keep = model.output_keep(None);
    let mut vars: Vec<MatVar> = Vec::new();
    let mut params: Vec<f64> = Vec::new();
    for (v, &keep) in model.vars.iter().zip(&keep) {
        if let MetaKind::Param { off, wty, .. } = &v.kind
            && keep
        {
            params.push(match wty {
                WTy::F64 => driver::read_f64(&engine, sim_data + off)?,
                WTy::I32 => driver::read_i32(&engine, sim_data + off)? as f64,
            });
        }
        if keep {
            vars.push(MatVar { name: &v.name, comment: &v.comment, kind: v.kind.mat() });
        }
    }
    let bytes = openmodelica_mat_writer::write_mat4(
        &vars,
        model.start_time,
        model.stop_time,
        &rows,
        model.layout.n_row_total(),
        &params,
        // One guessed point, no run: nothing captured a String value.
        &[],
        Precision::Double,
    );
    std::fs::write(path, bytes).map_err(|_| "cannot write the initial guess file")
}

/// Reading `SimData` needs no model call, and the engine that makes them is busy
/// driving the solve this runs inside.
struct ReadOnly;

impl driver::SimEngine for ReadOnly {
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> driver::Result<()> {
        buf.copy_from_slice(unsafe { core::slice::from_raw_parts(addr as *const u8, buf.len()) });
        Ok(())
    }
    fn write_bytes(&mut self, _addr: u32, _buf: &[u8]) -> driver::Result<()> {
        Err("initial-guess writer does not write SimData")
    }
    fn call1_raw(&mut self, _name: &str, _arg: u32) -> driver::Result<()> {
        Err("initial-guess writer does not call the model")
    }
    fn call1_if_present_raw(&mut self, _name: &str, _arg: u32) -> driver::Result<()> {
        Ok(())
    }
    fn call2_raw(&mut self, _name: &str, _a: u32, _b: u32) -> driver::Result<()> {
        Err("initial-guess writer does not call the model")
    }
    fn call_simulate(&mut self, _sim_data: u32, _start: f64, _stop: f64, _n: u32) -> driver::Result<u32> {
        Err("initial-guess writer does not call the model")
    }
    fn take_pending_assert(&mut self) -> Option<[i32; 9]> {
        None
    }
}
