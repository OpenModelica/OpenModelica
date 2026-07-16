//! Standalone `wasm32-wasip1` simulation command (the `_start` half of the
//! wasm-jit standalone export). Compiled only for `target_os = "wasi"`.
//!
//! After `wasm-merge` joins a model module with this runtime, this module's
//! `_start` drives the whole run in-wasm and writes `<prefix>_res.mat` via WASI —
//! no host. It runs the **same** engine-independent driver as the interactive
//! path (`openmodelica_sim_meta::driver`), reaching the model through a
//! [`StandaloneEngine`] that calls the model's exports directly (imports resolved
//! by the merge) and accesses the one shared linear memory in place. So the
//! standalone command handles events, state sets, samples and homotopy exactly
//! like the host/in-wasm drivers — no divergent second integrator.
//!
//! ## Merge contract
//! - The model imports its runtime functions + `memory` + `rt_assert` from module
//!   **`rt`**, and exports every driver entry point (`functionParameters`,
//!   `functionInitStartValues`, `functionInitialEquations[_lambda0]`,
//!   `functionODE`, `functionAlgebraics`, `functionStateSetJacobians`,
//!   `functionZeroCrossings`, `initSample`, `callExternalObjectDestructors`,
//!   `simulate`) plus the metadata accessors `om_meta_ptr`/`om_meta_len`. The
//!   optional ones are always exported (empty stub when the feature is absent), so
//!   the merge always resolves.
//! - This runtime exports the `rt_*` functions + `memory` + `rt_assert` + `_start`
//!   and imports the model's exports from module **`model`**.
//! - `wasm-merge runtime.wasm rt model.wasm model` connects both directions,
//!   leaving only the WASI imports (satisfied by `wasmtime`/the worker shim).

use openmodelica_mat_writer::{MatKind, MatVar};
use openmodelica_sim_meta::driver::{self, SimEngine};
use openmodelica_sim_meta::{self as meta, MetaKind, SimMeta};

// Model exports, resolved by wasm-merge (module "model"). Calls are unsafe; a
// trap inside one aborts the command (surfaced as a failed run by the caller).
// The optional functions are always exported by the emitter (empty when the
// model lacks the feature), so every import resolves regardless of the model.
#[link(wasm_import_module = "model")]
unsafe extern "C" {
    fn functionParameters(sim_data: u32);
    fn functionInitStartValues(sim_data: u32);
    fn functionInitialEquations(sim_data: u32);
    fn functionInitialEquations_lambda0(sim_data: u32);
    fn functionODE(sim_data: u32);
    fn functionAlgebraics(sim_data: u32);
    fn functionStateSetJacobians(sim_data: u32);
    fn functionZeroCrossings(sim_data: u32);
    fn initSample(sim_data: u32);
    fn callExternalObjectDestructors(sim_data: u32);
    fn simulate(sim_data: u32, start: f64, stop: f64, n_steps: u32) -> u32;
    /// Pointer to / length of the encoded `SimMeta` blob in linear memory.
    fn om_meta_ptr() -> u32;
    fn om_meta_len() -> u32;
}

// lld synthesises this (wasi-libc ctors: preopen/stdio init). A custom `_start`
// in a cdylib must call it before any std I/O, since std does not generate the
// `_start` that normally would.
unsafe extern "C" {
    fn __wasm_call_ctors();
}

/// Decode the model's embedded metadata blob.
fn read_meta() -> SimMeta {
    let ptr = unsafe { om_meta_ptr() };
    let len = unsafe { om_meta_len() } as usize;
    let bytes = unsafe { core::slice::from_raw_parts(ptr as *const u8, len) };
    meta::decode(bytes).expect("openmodelica_sim_meta: bad metadata blob")
}

/// [`SimEngine`] over the merged module: linear memory is directly addressable
/// (the runtime *is* in it), and the model's exports are called directly (the
/// merge resolved the `model` imports). Single-threaded WASI command.
struct StandaloneEngine;

impl SimEngine for StandaloneEngine {
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> driver::Result<()> {
        let src = unsafe { core::slice::from_raw_parts(addr as *const u8, buf.len()) };
        buf.copy_from_slice(src);
        Ok(())
    }
    fn write_bytes(&mut self, addr: u32, buf: &[u8]) -> driver::Result<()> {
        let dst = unsafe { core::slice::from_raw_parts_mut(addr as *mut u8, buf.len()) };
        dst.copy_from_slice(buf);
        Ok(())
    }
    fn call1(&mut self, name: &str, arg: u32) -> driver::Result<()> {
        unsafe {
            match name {
                "functionParameters" => functionParameters(arg),
                "functionInitStartValues" => functionInitStartValues(arg),
                "functionInitialEquations" => functionInitialEquations(arg),
                "functionInitialEquations_lambda0" => functionInitialEquations_lambda0(arg),
                "functionODE" => functionODE(arg),
                "functionAlgebraics" => functionAlgebraics(arg),
                "functionStateSetJacobians" => functionStateSetJacobians(arg),
                "functionZeroCrossings" => functionZeroCrossings(arg),
                "initSample" => initSample(arg),
                "callExternalObjectDestructors" => callExternalObjectDestructors(arg),
                _ => return Err("wasm-jit standalone: unknown model function"),
            }
        }
        Ok(())
    }
    fn call1_if_present(&mut self, name: &str, arg: u32) -> driver::Result<()> {
        // Every entry point is always exported (empty stub if unused), so a plain
        // call is a no-op when the feature is absent.
        self.call1(name, arg)
    }
    fn call_simulate(&mut self, sim_data: u32, start: f64, stop: f64, n_steps: u32) -> driver::Result<u32> {
        Ok(unsafe { simulate(sim_data, start, stop, n_steps) })
    }
    fn take_pending_assert(&mut self) -> Option<[i32; 7]> {
        // No host to record it; a failed model assert traps (see `rt_assert`).
        None
    }
}

/// Run the prepared model with the shared driver and write its result file.
/// A failure traps (the command then exits nonzero).
fn run() {
    let m = read_meta();
    let sim_data = crate::rt_alloc(m.layout.total);
    let mut engine = StandaloneEngine;

    // `+inf` budget = run to completion; no clock/cancel hooks needed (the driver
    // short-circuits the deadline and polls no cancel flag here).
    let (result, _label) = match driver::drive(&mut engine, &m, sim_data, m.method.as_str(), false, false) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("wasm-jit standalone: simulation failed: {e}");
            core::arch::wasm32::unreachable()
        }
    };

    if m.output_format != "mat" {
        return; // "empty": run only (benchmarking), no file
    }

    let matvars: Vec<MatVar> = m
        .vars
        .iter()
        .map(|v| MatVar {
            name: &v.name,
            comment: &v.comment,
            kind: match &v.kind {
                MetaKind::Time => MatKind::Time,
                MetaKind::Column { col, negate } => MatKind::Column { col: *col, negate: *negate },
                MetaKind::Param { negate, .. } => MatKind::Param { negate: *negate },
                MetaKind::Const { value } => MatKind::Const { value: *value },
            },
        })
        .collect();

    let bytes = openmodelica_mat_writer::write_mat4(
        &matvars,
        m.start_time,
        m.stop_time,
        &result.rows,
        result.n_reals,
        &result.params,
    );
    std::fs::write(format!("{}_res.mat", m.prefix), bytes).expect("wasm-jit standalone: cannot write result file");
}

/// The command entry point. Runs wasi-libc ctors (preopen/stdio init) then the
/// simulation. Exported by the cdylib; the merged module is a WASI command.
#[unsafe(no_mangle)]
pub extern "C" fn _start() {
    unsafe { __wasm_call_ctors() };
    run();
}

/// In-wasm `rt_assert`: the standalone has no host to record the failing
/// assertion, so print the message (`msg` is an `rt` String handle:
/// `[refcount:u32][len:u32][utf8…]`) and trap, which aborts the command.
#[unsafe(no_mangle)]
pub extern "C" fn rt_assert(msg: i32, _file: i32, _sline: i32, _scol: i32, _eline: i32, _ecol: i32, _read_only: i32) {
    if msg != 0 {
        let h = msg as u32;
        let len = unsafe { crate::load_u32(h + 4) } as usize;
        let bytes = unsafe { core::slice::from_raw_parts((h + 8) as *const u8, len) };
        if let Ok(s) = core::str::from_utf8(bytes) {
            eprintln!("wasm-jit standalone: assertion failed: {s}");
        }
    }
    core::arch::wasm32::unreachable()
}
