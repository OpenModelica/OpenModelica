//! Standalone `wasm32-wasip1` simulation command (the `_start` half of the
//! wasm-jit standalone export). Compiled only for `target_os = "wasi"`.
//!
//! After `wasm-merge` joins a model module with this runtime, this module's
//! `_start` drives the whole run in-wasm and writes `<prefix>_res.mat` via WASI —
//! no host. It mirrors the host drivers in
//! `openmodelica_codegen_wasm_jit/src/CodegenWasmJit/sim_runtime_wasmtime.rs`
//! (`run_host` = euler, `run_dassl` = DASSL via daskr), but instead of calling
//! the model through wasmtime and reading memory through a `Memory` handle, it
//! calls the model's exports directly (imports resolved by the merge) and
//! accesses the one shared linear memory through the runtime's own
//! `load_f64`/`store_f64`.
//!
//! ## Merge contract
//! - The model module imports its runtime functions + `memory` + `rt_assert`
//!   from module **`rt`**, and exports `functionParameters`,
//!   `functionInitialEquations`, `functionODE`, `functionAlgebraics`, and the
//!   metadata accessors `om_meta_ptr` / `om_meta_len` (a data segment holding the
//!   `openmodelica_sim_meta`-encoded [`SimMeta`]).
//! - This runtime exports the `rt_*` functions + `memory` + `rt_assert` + `_start`
//!   and imports the model's exports from module **`model`**.
//! - `wasm-merge runtime.wasm rt model.wasm model` connects both directions,
//!   leaving only the WASI imports (satisfied by `wasmtime`/the worker shim).

use openmodelica_mat_writer::{MatKind, MatVar};
use openmodelica_sim_meta::{self as meta, Layout, MetaKind, SimMeta, WTy, REAL_OFF, TIME_OFF};

// Model exports, resolved by wasm-merge (module "model"). Calls are unsafe; a
// trap inside one aborts the command (surfaced as a failed run by the caller).
#[link(wasm_import_module = "model")]
unsafe extern "C" {
    fn functionParameters(sim_data: u32);
    fn functionInitialEquations(sim_data: u32);
    fn functionODE(sim_data: u32);
    fn functionAlgebraics(sim_data: u32);
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

/// Append one result row — the `n_reals_row` f64 prefix, then the integer and
/// boolean algebraics (read as i32, stored as f64) — mirroring the host
/// `capture_row`.
fn capture_row(rows: &mut Vec<f64>, sim_data: u32, layout: &Layout) {
    for i in 0..layout.n_reals_row() {
        rows.push(unsafe { crate::load_f64(sim_data + i * 8) });
    }
    for i in 0..layout.n_int_alg() {
        rows.push((unsafe { crate::load_i32(sim_data + layout.int_off + i * 4) }) as f64);
    }
    for j in 0..layout.n_bool_alg() {
        rows.push((unsafe { crate::load_i32(sim_data + layout.bool_off + j * 4) }) as f64);
    }
}

/// Forward-Euler driver (port of `run_host`): set `time`, evaluate
/// `functionODE`/`functionAlgebraics`, capture, then step the states.
fn run_euler(m: &SimMeta, sim_data: u32, n_reals: u32, n_rows: u32) -> Vec<f64> {
    unsafe {
        functionParameters(sim_data);
        functionInitialEquations(sim_data);
    }
    let n_states = m.layout.n_states;
    let n_steps = n_rows - 1;
    let h = if n_steps == 0 { 0.0 } else { (m.stop_time - m.start_time) / n_steps as f64 };
    let states_base = sim_data + REAL_OFF;
    let ders_base = states_base + n_states * 8;

    let mut rows: Vec<f64> = Vec::with_capacity((n_rows * n_reals) as usize);
    for row in 0..n_rows {
        let time = m.start_time + row as f64 * h;
        unsafe {
            crate::store_f64(sim_data + TIME_OFF, time);
            functionODE(sim_data);
            functionAlgebraics(sim_data);
        }
        capture_row(&mut rows, sim_data, &m.layout);
        if row == n_steps {
            break;
        }
        for i in 0..n_states {
            let s = unsafe { crate::load_f64(states_base + i * 8) };
            let d = unsafe { crate::load_f64(ders_base + i * 8) };
            unsafe { crate::store_f64(states_base + i * 8, s + h * d) };
        }
    }
    rows
}

// DASSL residual context. wasm is single-threaded and `ddaskr`'s `RES` callback
// is a bare `unsafe fn` that cannot capture, so the few scalars it needs live in
// statics, set just before the integration. (Plain by-value reads/writes of
// `static mut` — never a reference — so no `static_mut_refs`.)
static mut RES_SIM_DATA: u32 = 0;
static mut RES_STATES_BASE: u32 = 0;
static mut RES_DERS_BASE: u32 = 0;
static mut RES_N_STATES: usize = 0;

/// DASSL residual `G(t, y, y') = y' - f(t, y)`: write `t` and the candidate
/// states into `SimData`, call `functionODE` to get `f` into the derivative
/// slots, then `delta := y' - f`. A model trap here aborts the command.
unsafe fn dassl_res(
    t: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    _cj: *mut f64,
    delta: *mut f64,
    _ires: *mut i32,
    _rpar: *mut f64,
    _ipar: *mut i32,
) {
    let sim_data = unsafe { RES_SIM_DATA };
    let states_base = unsafe { RES_STATES_BASE };
    let ders_base = unsafe { RES_DERS_BASE };
    let n = unsafe { RES_N_STATES };
    unsafe {
        crate::store_f64(sim_data + TIME_OFF, *t);
        for i in 0..n {
            crate::store_f64(states_base + (i as u32) * 8, *y.add(i));
        }
        functionODE(sim_data);
        for i in 0..n {
            let der = crate::load_f64(ders_base + (i as u32) * 8);
            *delta.add(i) = *yprime.add(i) - der;
        }
    }
}

/// DASSL driver (port of `run_dassl`): integrate with `daskr::solver::ddaskr`,
/// emitting a row at each output point.
fn run_dassl(m: &SimMeta, sim_data: u32, n_reals: u32, n_rows: u32) -> Vec<f64> {
    use daskr::solver;

    daskr::aux::xsetf(0); // silence DASKR's own printing
    unsafe {
        functionParameters(sim_data);
        functionInitialEquations(sim_data);
    }
    let n_states = m.layout.n_states as usize;
    let start = m.start_time;
    let stop = m.stop_time;
    let n_steps = n_rows - 1;
    let h = if n_steps == 0 { 0.0 } else { (stop - start) / n_steps as f64 };
    let states_base = sim_data + REAL_OFF;
    let ders_base = states_base + m.layout.n_states * 8;

    // Emit a row: set time, recompute ODE/algebraics, capture.
    let emit = |rows: &mut Vec<f64>, time: f64| {
        unsafe {
            crate::store_f64(sim_data + TIME_OFF, time);
            functionODE(sim_data);
            functionAlgebraics(sim_data);
        }
        capture_row(rows, sim_data, &m.layout);
    };

    let mut rows: Vec<f64> = Vec::with_capacity((n_rows * n_reals) as usize);
    emit(&mut rows, start); // row 0 at the start time

    // No states: just evaluate outputs on the grid.
    if n_states == 0 {
        for row in 1..n_rows {
            let time = if row == n_steps { stop } else { start + row as f64 * h };
            emit(&mut rows, time);
        }
        return rows;
    }

    // Initial y, y' from SimData (functionODE already wrote f(t0,y0) into ders).
    let mut y: Vec<f64> = (0..n_states).map(|i| unsafe { crate::load_f64(states_base + (i as u32) * 8) }).collect();
    let mut yp: Vec<f64> = (0..n_states).map(|i| unsafe { crate::load_f64(ders_base + (i as u32) * 8) }).collect();

    // DASKR work arrays / options (dense, numerical Jacobian), as the host driver.
    let neq = n_states as i32;
    let nrt = 0i32;
    let mut info = [0i32; 24];
    let tol = if m.tolerance > 0.0 { m.tolerance } else { 1e-6 };
    let mut rtol = [tol];
    let mut atol = [tol];
    let lrw = (60 + 9 * neq + neq * neq + 3 * nrt + 64) as usize;
    let liw = (40 + neq + 64) as usize;
    let mut rwork = vec![0.0f64; lrw];
    let mut iwork = vec![0i32; liw];
    let mut rpar = [0.0f64];
    let mut ipar = [0i32];
    let mut jroot = [0i32];
    let mut idid = 0i32;
    let mut t = start;

    unsafe {
        RES_SIM_DATA = sim_data;
        RES_STATES_BASE = states_base;
        RES_DERS_BASE = ders_base;
        RES_N_STATES = n_states;
    }

    for row in 1..n_rows {
        let mut tout = if row == n_steps { stop } else { start + row as f64 * h };
        unsafe {
            solver::ddaskr(
                dassl_res, neq, &mut t, y.as_mut_ptr(), yp.as_mut_ptr(), &mut tout, info.as_mut_ptr(),
                rtol.as_mut_ptr(), atol.as_mut_ptr(), &mut idid, rwork.as_mut_ptr(), lrw as i32,
                iwork.as_mut_ptr(), liw as i32, rpar.as_mut_ptr(), ipar.as_mut_ptr(),
                solver::dummy_jacd, solver::dummy_jack, solver::dummy_psol, solver::dummy_rt, nrt,
                jroot.as_mut_ptr(),
            );
        }
        if idid < 0 {
            panic!("wasm-jit standalone: DASSL (daskr) failed at t={t} (target {tout}), IDID={idid}");
        }
        // t == tout; write the interpolated state back and emit.
        for i in 0..n_states {
            unsafe { crate::store_f64(states_base + (i as u32) * 8, y[i]) };
        }
        emit(&mut rows, tout);
    }
    rows
}

/// Run the prepared model and write its result file. Returns nothing; a failure
/// traps (the command then exits nonzero).
fn run() {
    let m = read_meta();
    let n_reals = m.layout.n_row_total();
    let n_rows = m.n_intervals + 1;
    let sim_data = crate::rt_alloc(m.layout.total);

    let rows = match m.method.as_str() {
        "euler" => run_euler(&m, sim_data, n_reals, n_rows),
        // dassl is the default (empty method), matching the host driver dispatch.
        _ => run_dassl(&m, sim_data, n_reals, n_rows),
    };

    if m.output_format != "mat" {
        return; // "empty": run only (benchmarking), no file
    }

    // Parameter values, in `Param` order, read from SimData.
    let mut params: Vec<f64> = Vec::new();
    for v in &m.vars {
        if let MetaKind::Param { off, wty, .. } = &v.kind {
            let val = match wty {
                WTy::F64 => unsafe { crate::load_f64(sim_data + off) },
                WTy::I32 => (unsafe { crate::load_i32(sim_data + off) }) as f64,
            };
            params.push(val);
        }
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

    let bytes = openmodelica_mat_writer::write_mat4(&matvars, m.start_time, m.stop_time, &rows, n_reals, &params);
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
