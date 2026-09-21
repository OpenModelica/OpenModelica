//! The resumable / cancellable simulation session.
//!
//! `runSimulation` runs a prepared model in one blocking call. For cooperative
//! cancellation the run is split into a persistent session: `sim_start` builds the
//! engine + driver (init + row 0), `sim_advance(budget_ms)` integrates a time-bounded
//! chunk and returns, `sim_free` drops it. A run short enough to finish in one
//! `advance` never yields. See HANDOFF-sim-cancel.md.

use super::*;

/// A resumable, cancellable simulation. One per thread (omc is single-threaded
/// per process).
pub(super) struct SimSession {
    model: Arc<SimModel>,
    /// This run's scalars: the model's metadata with the run's flags applied.
    meta: SimMeta,
    result_file: String,
    /// The `-variableFilter` decision per result signal.
    keep: Vec<bool>,
    backend: SessionBackend,
    /// Wall-clock inside `advance`, summed over chunks: excludes the yields
    /// between them, so it stays comparable to the one-shot `run()` timing.
    integrate_ms: f64,
    /// The model's output so far. `take_stdout_capture` ends the capture, so
    /// each chunk drains it here and re-arms.
    log: String,
    /// `-lv=LOG_STATS` was requested.
    log_stats: bool,
}

thread_local! {
    /// The last run's model output, for [`last_sim_log`]: `sim_advance` returns
    /// a status code and has no other channel for it.
    static LAST_SIM_LOG: std::cell::RefCell<String> = const { std::cell::RefCell::new(String::new()) };
}

/// The last session run's model output, including a failed run's.
pub fn last_sim_log() -> String {
    LAST_SIM_LOG.with(|c| c.borrow().clone())
}

/// Drain the capture into `dst` and re-arm it for the next chunk.
fn drain_capture(dst: &mut String) {
    dst.push_str(&openmodelica_wasi::wasi::take_stdout_capture());
    openmodelica_wasi::wasi::start_stdout_capture();
}

/// End the capture, fold everything the run produced into `log`, and publish it.
fn publish_log(mut log: String) {
    log.push_str(&openmodelica_wasi::wasi::take_stdout_capture());
    LAST_SIM_LOG.with(|c| *c.borrow_mut() = log);
}

/// Either the host driver (Rust driver calling the model through the wasm
/// engine) or the in-wasm session driver (`rt_sim_*`, the model reached
/// wasm->wasm), selected by `OMC_WASM_INWASM_DRIVER` at `sim_start`.
enum SessionBackend {
    Host {
        engine: Box<dyn sim_driver::SimEngine + 'static>,
        driver: Box<dyn sim_driver::Driver>,
        sim_data: u32,
    },
    InWasm(sim_runtime::InWasmSession),
}

thread_local! {
    static SIM_SESSION: std::cell::RefCell<Option<SimSession>> = const { std::cell::RefCell::new(None) };
}

/// Capture results for the `omc_sim_*` getters once the result file is written.
fn finalize_and_capture(
    model: &SimModel,
    meta: &SimMeta,
    result_file: &str,
    keep: &[bool],
    run: sim_driver::RunResult,
    written: Written,
) -> Result<String> {
    openmodelica_sim_meta::profiling::finish(meta, result_file, output_size(result_file));
    let lin = write_lin_file(meta, &run, &simflags::flags());
    capture_last_sim(model, written, &run.params, &run.stats, keep, result_file);
    Ok(lin)
}

/// Start a resumable run of a model already prepared by `buildModel`
/// (`translateModel` + `finishCompile`). Mirrors `run_simulation_inner`'s setup
/// but stops before integrating. One session at a time — any prior one is freed.
pub fn sim_start(prefix: &str, result_file: &str, simflags: &str) -> Result<()> {
    sim_free();
    let model = sim_models()
        .lock()
        .unwrap_or_else(|e| e.into_inner())
        .get(prefix)
        .cloned()
        .ok_or_else(|| "no prepared wasm-jit model for (translateModel not run?)")?;
    let flags = install_sim_flags(simflags).map_err(|e| {
        record_error(format!("wasm-jit: {e}"));
        "CodegenWasmJit: unusable simulation flags"
    })?;
    sim_driver::clear_cancel();
    // Split init from simulation output as `run_simulation_inner` does; the
    // hook fires while the backend below is built, which is what initializes.
    LAST_SIM_LOG.with(|c| c.borrow_mut().clear());
    INIT_OUTPUT.with(|c| *c.borrow_mut() = None);
    sim_driver::set_init_done_hook(on_init_done);
SIM_OUTPUT.with(|c| *c.borrow_mut() = None);
sim_driver::set_teardown_hook(on_teardown);
    SPLIT_ARMED.with(|a| a.set(true));
    openmodelica_wasm_jit::host::native_stdout::install();
    sim_driver::init_host_hooks();
    sim_driver::set_result_file_reader(read_result_values);
    let (meta, experiment_log) = run_experiment(&model, &flags);
    let target = result_target(&model, &meta, &flags, result_file);
    check_output_format(&target.format).map_err(|e| {
        record_error(e);
        "CodegenWasmJit: unsupported output format"
    })?;
    openmodelica_wasi::wasi::start_stdout_capture();
    let (param_ov, start_ov, string_ov) = resolve_overrides(&model, &flags);
    sim_driver::set_param_overrides(param_ov, start_ov, string_ov);
    sim_driver::set_start_imports(resolve_start_imports(&meta, &flags));
    // Build the backend (instantiate, init, emit row 0). An init trap is usually
    // a failed `assert()`; the host driver routes it via `enrich_trap`.
    let inwasm = inwasm_driver_enabled();
    let (path, keep) = (target.path.clone(), target.keep.clone());
    let built = (|| -> std::result::Result<SessionBackend, String> {
        if inwasm {
            Ok(SessionBackend::InWasm(sim_runtime::build_inwasm_session(&model, Some(&target))?))
        } else {
            let (mut engine, sim_data) = sim_runtime::build_engine(&model, &meta)?;
            let made = sim_driver::make_driver(&mut *engine, &meta, sim_data, meta.method.as_str())
                .map_err(|err| sim_driver::enrich_trap_init(&mut *engine, err, meta.start_time));
            let (driver, _label) = match made {
                Ok(v) => v,
                Err(e) => {
                    return Err(e.to_string());
                }
            };
            // `make_driver` initialized, so the file opens here rather than from
            // inside `drive`.
            openmodelica_wasm_jit::result_sink::arm(target);
            sim_driver::open_result(&mut *engine, &meta, sim_data).map_err(|e| e.to_string())?;
            Ok(SessionBackend::Host { engine, driver, sim_data })
        }
    })();
    // Disarm in case init failed before the hook fired.
    SPLIT_ARMED.with(|a| a.set(false));
    let flags = simflags::flags();
    let init_log = format!(
        "{experiment_log}{}{}",
        flag_change_log(&flags),
        INIT_OUTPUT.with(|c| c.borrow_mut().take()).unwrap_or_default()
    );
    let backend = match built {
        Ok(v) => v,
        Err(e) => {
            publish_log(init_log);
            record_error(format!("wasm-jit simulation failed: {}", with_engine_detail(&e)));
            return Err("CodegenWasmJit: wasm-jit simulation failed");
        }
    };
    SIM_SESSION.with(|s| {
        *s.borrow_mut() = Some(SimSession {
            model,
            result_file: path,
            keep,
            meta,
            backend,
            integrate_ms: 0.0,
            log: init_log,
            log_stats: flags.has_log("LOG_STATS"),
        })
    });
    Ok(())
}

/// Integrate for about `budget_ms` of wall-clock, then return. On completion
/// finalizes exactly as `run_simulation_inner` (capture results for the
/// `omc_sim_*` getters + write the `.mat`) and frees the session.
pub fn sim_advance(budget_ms: f64) -> Result<SimStatus> {
    SIM_SESSION.with(|s| {
        let mut guard = s.borrow_mut();
        let Some(sess) = guard.as_mut() else {
            return Err("no active simulation session");
        };
        // Clone the cheap identity fields so the `sess` borrow can end before we
        // touch `guard` again (to clear it on completion/error).
        let model = sess.model.clone();
        let result_file = sess.result_file.clone();
        let keep = sess.keep.clone();
        let log_stats = sess.log_stats;
        let n_intervals = sess.meta.n_intervals;
        // Stopped before the finalize/`.mat` work in each arm below.
        let mut adv_ms = 0.0f64;
        // Filled by whichever arm finishes the run, appended to the log below.
        let mut stats_block = String::new();

        // Advance one chunk. All `sess` borrows end when this block returns its
        // status value.
        let outcome: Result<SimStatus> = match &mut sess.backend {
            SessionBackend::Host { engine, driver, sim_data } => {
                let t = sim_driver::now_ms_host();
                let advanced = driver
                    .advance(&mut **engine, &sess.meta, budget_ms)
                    .map_err(|err| sim_driver::enrich_trap(&mut **engine, err));
                adv_ms = sim_driver::now_ms_host() - t;
                match advanced {
                    Ok(sim_driver::Advance::Running) => Ok(SimStatus::Running),
                    Ok(sim_driver::Advance::Cancelled) => {
                        // Free external objects so the cancelled run leaks nothing.
                        let _ = sim_driver::finalize_run(&mut **engine, &sess.meta, *sim_data);
                        Ok(SimStatus::Cancelled)
                    }
                    Ok(done) => {
                        let mut rows = driver.take_rows();
                        sim_driver::finish_rows(&mut rows);
                        let written = openmodelica_wasm_jit::result_sink::take();
                        let mut stats = SolveStats::default();
                        driver.fill_stats(&sess.meta, &mut stats);
                        // C's order: the `-reconcile*` procedures, then `-l`.
                        let (recon_log, recon_res) =
                            sim_driver::reconcile(&mut **engine, &sess.meta, *sim_data);
                        let lin = match recon_res.is_ok() {
                            true => openmodelica_sim_meta::linearize::linearize(
                                &mut **engine,
                                &sess.meta,
                                *sim_data,
                            )?,
                            false => None,
                        };
                        let params = sim_driver::finalize_run(&mut **engine, &sess.meta, *sim_data)?;
                        stats_block.push_str(&recon_log);
                        recon_res?;
                        let run = sim_driver::RunResult {
                            rows,
                            n_reals: model.layout.n_row_total(),
                            params,
                            stats,
                            lin,
                        };
                        if log_stats {
                            stats_block = openmodelica_sim_meta::stats::log_stats_block(&run.stats);
                        }
                        stats_block
                            .push_str(&finalize_and_capture(&model, &sess.meta, &result_file, &keep, run, written)?);
                        Ok(if matches!(done, sim_driver::Advance::Terminated) {
                            SimStatus::Terminated
                        } else {
                            SimStatus::Done
                        })
                    }
                    Err(e) => Err(e),
                }
            }
            SessionBackend::InWasm(inwasm) => {
                let t = sim_driver::now_ms_host();
                let advanced = inwasm.advance(budget_ms);
                adv_ms = sim_driver::now_ms_host() - t;
                match advanced {
                    Ok(0) => Ok(SimStatus::Running),
                    Ok(3) => Ok(SimStatus::Cancelled),
                    Ok(rc) => {
                        // 1 done, 2 terminated
                        let run = inwasm.take_result()?;
                        let written = inwasm.take_written()?;
                        if log_stats {
                            stats_block = openmodelica_sim_meta::stats::log_stats_block(&run.stats);
                        }
                        stats_block
                            .push_str(&finalize_and_capture(&model, &sess.meta, &result_file, &keep, run, written)?);
                        Ok(if rc == 2 { SimStatus::Terminated } else { SimStatus::Done })
                    }
                    Err(e) => Err(e),
                }
            }
        };
        sess.integrate_ms += adv_ms;
        let integrate_ms = sess.integrate_ms;
        drain_capture(&mut sess.log);
        sess.log.push_str(&stats_block);
        // The run is over unless it asked for another chunk, so hand the log on.
        let run_log = match outcome {
            Ok(SimStatus::Running) => None,
            _ => Some(core::mem::take(&mut sess.log)),
        };

        match outcome {
            Ok(SimStatus::Running) => Ok(SimStatus::Running),
            Ok(st) => {
                if sim_bench_enabled() {
                    eprintln!(
                        "wasm-jit session [{}]: integrate {integrate_ms:.1} ms ({} intervals)",
                        if inwasm_driver_enabled() { "in-wasm" } else { "host" },
                        n_intervals,
                    );
                }
                publish_log(run_log.unwrap_or_default());
                *guard = None;
                Ok(st)
            }
            Err(e) => {
                publish_log(run_log.unwrap_or_default());
                record_error(format!("wasm-jit simulation failed: {}", with_engine_detail(e)));
                *guard = None;
                Err(e)
            }
        }
    })
}

/// Drop the active session, freeing its external objects. Safe to call with no
/// session (the cancel path and `sim_start`'s reset both use it).
pub fn sim_free() {
    SIM_SESSION.with(|s| {
        if let Some(mut sess) = s.borrow_mut().take() {
            // Cancel path: end the capture, keeping what was printed.
            publish_log(core::mem::take(&mut sess.log));
            // The in-wasm session frees itself on `Drop` (`rt_sim_free`).
            let SimSession { meta, backend, .. } = &mut sess;
            if let SessionBackend::Host { engine, sim_data, .. } = backend {
                let _ = sim_driver::finalize_run(&mut **engine, meta, *sim_data);
                openmodelica_wasm_jit::result_sink::take();
            }
        }
    });
}
