//! The `om:sim/simulation` export: the model's own simulation runtime, inside
//! the same component that serves the FMI 3.0 interfaces.
//!
//! It runs `openmodelica_sim_meta::driver` — the driver a wasm-jit simulation
//! runs — over the adapter's [`Engine`](super::Engine), so an artifact can be
//! simulated the ordinary way without being translated a second time. The
//! result file is serialized here and handed back to the caller; the log goes
//! to the component's stdout, where the FMI interfaces' log goes.

use alloc::string::{String, ToString};
use alloc::vec;
use alloc::vec::Vec;

use openmodelica_mat_writer::{MatVar, Precision};
use openmodelica_sim_meta::driver;
use openmodelica_sim_meta::simflags;
use openmodelica_sim_meta::{self as meta, MetaKind};

use crate::exports::om::sim::simulation::{Guest as SimGuest, RunResult};
use crate::{log_sink, read_meta, Engine, Fmu};

impl SimGuest for Fmu {
    fn run(args: Vec<String>) -> Result<RunResult, String> {
        run(args)
    }
}

/// WASI's monotonic clock, in ms since the first reading. The driver's per-step
/// deadline (`-alarm`) and the `LOG_STATS` timings need one; the component gets
/// it from the same preview1 adapter its stdout comes from.
mod clock {
    #[link(wasm_import_module = "wasi_snapshot_preview1")]
    unsafe extern "C" {
        #[link_name = "clock_time_get"]
        fn clock_time_get(id: u32, precision: u64, out: *mut u64) -> i32;
    }

    const MONOTONIC: u32 = 1;

    fn now_ns() -> u64 {
        let mut t = 0u64;
        if unsafe { clock_time_get(MONOTONIC, 1_000, &mut t) } != 0 {
            return 0;
        }
        t
    }

    pub fn now_ms() -> f64 {
        static mut START: u64 = 0;
        let now = now_ns();
        let start = unsafe {
            if START == 0 {
                START = now;
            }
            START
        };
        now.saturating_sub(start) as f64 / 1.0e6
    }
}

pub(crate) fn run(args: Vec<String>) -> Result<RunResult, String> {
    // `parse` takes an argv, program name first, as a simulation executable's.
    let mut argv: Vec<String> = vec!["model".to_string()];
    argv.extend(args);
    let flags = simflags::parse(&argv)?;
    simflags::check(&flags, openmodelica_codegen_wasm_jit_runtime::sim_capabilities())?;
    openmodelica_codegen_wasm_jit_runtime::apply_sim_flags(&flags);
    // Installs the `-lv` log mask too, so the notices below are already filtered.
    simflags::set_flags(flags);

    let mut m = read_meta();
    if m.layout.total == 0 {
        return Err("wasm-jit: the artifact carries no model metadata".to_string());
    }
    driver::set_log_sink(log_sink);
    // What `OpenModelica_fmuLoadResource` resolves against, as at instantiation:
    // the host preopens the artifact's resources as this component's root.
    openmodelica_codegen_wasm_jit_runtime::set_resources_dir("/");
    simflags::with_flags(|f| {
        simflags::print_notices(f);
        m.apply_flags(f);
    });

    openmodelica_codegen_wasm_jit_runtime::rt_set_step_size(m.step_size());
    openmodelica_codegen_wasm_jit_runtime::set_nls_var_names(
        if meta::omclog::active(meta::omclog::NLS) {
            m.nls_vars.iter().map(|s| (s.eq_index, s.names.clone())).collect()
        } else {
            Vec::new()
        },
    );
    openmodelica_codegen_wasm_jit_runtime::enable_sys_stats(meta::omclog::active(meta::omclog::STATS_V));
    driver::set_clock(clock::now_ms);

    let sim_data = openmodelica_codegen_wasm_jit_runtime::rt_alloc(m.layout.total);
    unsafe { core::ptr::write_bytes(sim_data as *mut u8, 0, m.layout.total as usize) };
    let mut engine = Engine;
    let (result, label) = driver::drive(&mut engine, &m, sim_data, m.method.as_str(), false, false)
        .map_err(|e| e.to_string())?;

    let rows = if result.n_reals == 0 { 0 } else { result.rows.len() / result.n_reals as usize };
    let bytes = write_result_file(&m, &result);
    Ok(RunResult {
        file: bytes,
        linear_file: result.lin.as_ref().map(|f| (f.name.clone(), f.content.clone())),
        rows: rows as u32,
        solver: label.to_string(),
    })
}

/// The `.mat` / `.plt` bytes, exactly as the standalone export serializes them
/// (one writer, so the two cannot drift). `"empty"` writes nothing: the run was
/// only asked for its integration.
fn write_result_file(m: &meta::SimMeta, result: &driver::RunResult) -> Vec<u8> {
    if m.output_format != "mat" && m.output_format != "plt" {
        return Vec::new();
    }
    let keep = m.output_keep(None);
    // `params` is positional over the unfiltered `Param` signals; only the kept
    // ones are collected, in signal order, for the writer.
    let mut kept_params: Vec<f64> = Vec::new();
    let mut param_idx = 0usize;
    if m.output_format == "mat" {
        let mut matvars: Vec<MatVar> = Vec::new();
        for (v, &keep) in m.vars.iter().zip(&keep) {
            let is_param = matches!(v.kind, MetaKind::Param { .. });
            if is_param && keep {
                kept_params.push(result.params.get(param_idx).copied().unwrap_or(0.0));
            }
            param_idx += is_param as usize;
            if !keep {
                continue;
            }
            matvars.push(MatVar { name: &v.name, comment: &v.comment, kind: v.kind.mat() });
        }
        let precision = simflags::with_flags(|f| {
            if f.single_precision { Precision::Single } else { Precision::Double }
        });
        openmodelica_mat_writer::write_mat4(
            &matvars,
            m.start_time,
            m.stop_time,
            &result.rows,
            result.n_reals,
            &kept_params,
            precision,
        )
    } else {
        use openmodelica_plt_writer::{Neg as PltNeg, PltKind, PltVar};
        let neg = |n: &meta::Neg| match n {
            meta::Neg::None => PltNeg::None,
            meta::Neg::Arith => PltNeg::Arith,
            meta::Neg::Not => PltNeg::Not,
        };
        let to_plt = |k: &MetaKind| match k {
            MetaKind::Time => PltKind::Time,
            MetaKind::Column { col, negate } => PltKind::Column { col: *col, negate: neg(negate) },
            MetaKind::Param { negate, .. } => PltKind::Param { negate: neg(negate) },
            MetaKind::Const { value } => PltKind::Const { value: *value },
        };
        let mut signals: Vec<PltVar> = Vec::new();
        for (v, &keep) in m.vars.iter().zip(&keep) {
            let is_param = matches!(v.kind, MetaKind::Param { .. });
            // C's plt writer omits integer/boolean parameters (`nParameters*`).
            let is_int_bool_param = matches!(v.kind, MetaKind::Param { wty: meta::WTy::I32, .. });
            let emit = keep && !is_int_bool_param;
            if is_param && emit {
                kept_params.push(result.params.get(param_idx).copied().unwrap_or(0.0));
            }
            param_idx += is_param as usize;
            if !emit {
                continue;
            }
            signals.push(PltVar { name: &v.name, kind: to_plt(&v.kind) });
        }
        openmodelica_plt_writer::write_plt(&signals, &result.rows, result.n_reals, &kept_params)
    }
}
