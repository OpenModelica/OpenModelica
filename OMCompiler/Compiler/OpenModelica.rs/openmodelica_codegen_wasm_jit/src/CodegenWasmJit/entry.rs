//! MetaModelica-facing entry points: `translateModel`, `runSimulation`,
//! `finishCompile`, `emitStandalone`, `runSimulationWasmtime`.

use super::*;

/// Mirror `-n` into the engine, before anything reaches the JIT.
pub(super) fn sync_engine_threading() -> Result<()> {
    openmodelica_wasm_jit::model::set_single_threaded(openmodelica_util::Config::noProc()? == 1);
    Ok(())
}

/// `CodegenWasmJit.translateModel`: lower `simCode` to a model wasm module, write
/// `<prefix>.wasm`, and stash the prepared [`SimModel`] for the later
/// `runSimulation`. On a lowering error the message is recorded to the Error
/// buffer (so `getErrorString` / OMEdit show it) and the failure is returned so
/// translation fails — as the other codegen targets do — never a stderr print or
/// a panic (a panic would trap the wasm instance and lose the buffered message).
pub fn translateModel(simCode: SimCode::SimCode) -> Result<()> {
    sync_engine_threading()?;
    sim_runtime::start_runtime_compile();
    let prefix = simCode.fileNamePrefix.to_string();
    let _ = std::fs::remove_file(format!("{prefix}.wasm"));
    let errs_before = openmodelica_util::Error::getNumErrorMessages();
    let outcome = build_sim_model(&simCode, false, ExtHost::SIM, "", "").and_then(|model| {
        write_output(&format!("{prefix}.wasm"), &model.wasm).map_err(|_| "CodegenWasmJit: write failed")?;
        sim_models().lock().unwrap_or_else(|e| e.into_inner()).insert(prefix.clone(), Arc::new(model));
        Ok(())
    });
    if let Err(e) = &outcome {
        if openmodelica_util::Error::getNumErrorMessages() == errs_before {
            record_error(format!(
                "CodegenWasmJit: cannot build simulation module for `{prefix}`: {}",
                with_engine_detail(e)
            ));
        }
    }
    outcome
}

/// `CodegenWasmJit.runSimulation`: run the prepared model in-process and write
/// the result file. Returns 0 on success, 1 on failure (matching the exit code
/// the C target's executable would return, which `simulate` checks).
/// The initialization success line, from the homotopy-step count the last
/// `run_initialization` recorded (0 → "without homotopy method").
fn init_success_line() -> String {
    let steps = sim_driver::init_homotopy_steps();
    if steps == 0 {
        "LOG_SUCCESS       | info    | The initialization finished successfully without homotopy method.".to_string()
    } else {
        let local = if sim_driver::init_homotopy_local() { "local " } else { "" };
        format!("LOG_SUCCESS       | info    | The initialization finished successfully with {steps} {local}homotopy steps.")
    }
}

/// A run reports itself through `<prefix>.log` alone, which `simulate` returns as
/// `messages` — as C's separate simulation executable does. Whatever it left in the
/// Error buffer would also surface from `getErrorString()`, where C returns "".
const RUN_CHECKPOINT: ArcStr = arcstr::literal!("wasm-jit simulation run");

pub fn runSimulation(fileNamePrefix: ArcStr, resultFile: ArcStr, simflags: ArcStr) -> i32 {
    let (mut prefix, mut result_file) = (fileNamePrefix.to_string(), resultFile.to_string());
    // `resimulateExecutable` may name a wasm artifact: its own simulation is the
    // model this session exported, run the ordinary way, while an FMI face or an
    // artifact from elsewhere runs inside it.
    #[cfg(all(feature = "artifact", not(target_arch = "wasm32")))]
    if let Some(path) = artifact::locate(&fileNamePrefix) {
        match artifact::translated(&path, &simflags) {
            Some(p) => {
                prefix = p;
                result_file = artifact::plain_result_name(&resultFile);
            }
            None => return run_artifact(&path, &fileNamePrefix, &resultFile, &simflags),
        }
    }
    openmodelica_error::ErrorExt::setCheckpoint(RUN_CHECKPOINT);
    let (res, init_output, sim_output, post_output) = run_simulation_inner(&prefix, &result_file, &simflags);
    openmodelica_error::ErrorExt::rollBack(RUN_CHECKPOINT);
    // `simulate` reads `<prefix>.log` after a run; the model's captured stdout
    // (`print`, LOG_STATS, ...) is folded in so it shows in the log rather than the
    // process console.
    let init_line = init_success_line();
    // A failed run keeps the init line too, as C does.
    let init_done = init_output.is_some();
    let init_out = init_output.unwrap_or_default();
    let init_seg = if init_done { format!("{init_out}{init_line}\n") } else { init_out };
    let log = match &res {
        // Init prints, the init line, then the sim prints and the final success.
        Ok(()) => format!(
            "{init_seg}{sim_output}\
             LOG_SUCCESS       | info    | The simulation finished successfully.\n{post_output}"
        ),
        // Chattering abort (`-abortSlowSimulation`): the driver's output carries the
        // chattering + aborting lines.
        Err(e) if *e == sim_driver::CHATTER_ABORT_ERR => format!("{init_seg}{sim_output}"),
        // A failed assertion, initialization or integrator has logged its own
        // reason (`LOG_ASSERT` / `LOG_INIT` / `model terminate`).
        Err(e)
            if *e == sim_driver::ASSERT_ERR
                || *e == sim_driver::INIT_FAILED_ERR
                || *e == sim_driver::SOLVER_FAILED_ERR =>
        {
            format!("{init_seg}{sim_output}")
        }
        Err(e) => format!(
            "{init_seg}{sim_output}LOG_ERROR         | error   | wasm-jit simulation failed: {}\n",
            with_engine_detail(e)
        ),
    };
    // C's `freeNonlinearSystems`, the last thing a simulation executable logs.
    let log = if openmodelica_sim_meta::omclog::active(openmodelica_sim_meta::omclog::NLS) {
        format!("{log}LOG_NLS           | info    | free non-linear system solvers\n")
    } else {
        log
    };
    let _ = write_output(&format!("{fileNamePrefix}.log"), log.as_bytes());
    // Error is in `<prefix>.log` (hence the result `messages`); no stderr.
    match res {
        Ok(()) => 0,
        Err(_) => 1,
    }
}

/// Simulate an exported wasm artifact. The three faces (`-s fmi3:me[:solver]`,
/// `-s fmi3:cs`, and the artifact's own simulation runtime otherwise) all report
/// themselves through `<prefix>.log`, as a run of a translated model does.
#[cfg(all(feature = "artifact", not(target_arch = "wasm32")))]
fn run_artifact(path: &std::path::Path, prefix: &str, result_file: &str, simflags: &str) -> i32 {
    let (face, rest) = match artifact::select_face(simflags) {
        Ok(v) => v,
        Err(e) => {
            let _ = write_output(&format!("{prefix}.log"), format!("LOG_ERROR         | error   | {e}\n").as_bytes());
            return 1;
        }
    };
    let (res, mut log) = artifact::run(path, face, result_file, &rest);
    match &res {
        Ok(()) => log.push_str("LOG_SUCCESS       | info    | The simulation finished successfully.\n"),
        Err(e) => log.push_str(&format!("LOG_ERROR         | error   | {e}\n")),
    }
    let _ = write_output(&format!("{prefix}.log"), log.as_bytes());
    if res.is_ok() { 0 } else { 1 }
}

/// `CodegenWasmJit.finishCompile`: force the model's wasm modules to finish
/// compiling. Called from `buildModel`'s compile phase (the wasm-jit counterpart
/// of `compileModel` building the C executable) so the JIT-compile cost is
/// measured as `timeCompile` rather than leaking into `timeSimulation`. It joins
/// the background model-module compile (started by `translateModel`) and forces
/// the runtime module (compiled-once / AOT-cached), stashing the compiled model
/// module for `runSimulation`. A JIT-compile error is deferred — `runSimulation`
/// recompiles and reports it — but the `external "C"` implementations are resolved
/// here, so a broken `Include` fails the build rather than the run.
pub fn finishCompile(fileNamePrefix: ArcStr) -> Result<()> {
    let model = sim_models().lock().unwrap_or_else(|e| e.into_inner()).get(&fileNamePrefix.to_string()).cloned();
    let Some(model) = model else { return Ok(()) };
    // Force the runtime module (so its compile/cache-load is in `timeCompile`).
    // It has to be the copy on the engine this model's own module goes to.
    sim_runtime::select_engine_for(&model.wasm);
    let _ = sim_runtime::runtime_module();
    // Join the background model-module compile and stash the result.
    match sim_runtime::take_compiled_model(&model) {
        Ok(m) => *model.prepared.lock().unwrap_or_else(|e| e.into_inner()) = Some(m),
        // A cancelled wait is the build's answer: running would start it again.
        Err(e) if e == openmodelica_wasm_jit::COMPILE_CANCELLED => {
            record_error(e);
            return Err(openmodelica_wasm_jit::COMPILE_CANCELLED);
        }
        // Deferred: `runSimulation` recompiles and reports the error via the log.
        Err(_) => {}
    }
    let missing = missing_ext_symbols(&model.ext_imports, &model.ext_libs);
    if let Err(e) = sim_runtime::prepare_native_externals(&model, &missing) {
        record_error(format!("CodegenWasmJit: the model's `external \"C\"` implementations are unavailable:\n{e}"));
        return Err("CodegenWasmJit: external \"C\" implementation unavailable");
    }
    Ok(())
}

/// `CodegenWasmJit.emitStandalone`: the `wasm` simCodeTarget's counterpart of
/// [`translateModel`]. Lower the model and `wasm-merge` it with the wasip1 runtime
/// into a self-contained WASI *command* module written to `<prefix>.wasm`, runnable
/// with `wasmtime run <prefix>.wasm --dir .::.` ([`runSimulationWasmtime`]). Unlike
/// `translateModel` it neither JIT-compiles nor stashes the model — the run is a
/// separate `wasmtime` process. Native only (the omc wasm build cannot `wasm-merge`).
/// A failure is recorded to the Error buffer and returned so translation fails.
#[cfg(not(target_arch = "wasm32"))]
pub fn emitStandalone(simCode: SimCode::SimCode) -> Result<()> {
    let prefix = simCode.fileNamePrefix.to_string();
    let _ = std::fs::remove_file(format!("{prefix}.wasm"));
    let bytes = emit_standalone_module(&simCode).map_err(|e| {
        record_error(format!("CodegenWasmJit: cannot build standalone module for `{prefix}`: {e:#}"));
        e
    })?;
    write_output(&format!("{prefix}.wasm"), &bytes).map_err(|e| {
        record_error(format!("CodegenWasmJit: cannot write {prefix}.wasm: {e:#}"));
        "CodegenWasmJit: cannot write standalone wasm"
    })?;
    Ok(())
}

/// The omc wasm build cannot `wasm-merge` the standalone module; record why and
/// fail so translation reports it rather than emitting a silent empty module.
#[cfg(target_arch = "wasm32")]
pub fn emitStandalone(simCode: SimCode::SimCode) -> Result<()> {
    let _ = simCode;
    let msg = "CodegenWasmJit: simCodeTarget=wasm (standalone export) is unavailable in the wasm omc build";
    record_error(msg.to_string());
    return Err(msg)
}

/// `CodegenWasmJit.runSimulationWasmtime`: run the standalone module emitted by
/// [`emitStandalone`] in a `wasmtime` subprocess (the `wasm` target's counterpart
/// of [`runSimulation`]). The module's `_start` writes `<prefix>_res.mat` via WASI;
/// returns 0 on success, 1 on failure (matching the C executable's exit code).
pub fn runSimulationWasmtime(fileNamePrefix: ArcStr, resultFile: ArcStr, simflags: ArcStr) -> i32 {
    let res = run_wasmtime_inner(&fileNamePrefix, &resultFile, &simflags);
    // The simulate flow reads `<prefix>.log` after a run (the C target's executable
    // writes one); mirror runSimulation so the success path is taken.
    let log = match &res {
        Ok(()) => "LOG_SUCCESS       | info    | The initialization finished successfully without homotopy method.\n\
                    LOG_SUCCESS       | info    | The simulation finished successfully.\n"
            .to_string(),
        Err(e) => format!("LOG_ERROR         | error   | wasm standalone simulation failed: {e:#}\n"),
    };
    let _ = write_output(&format!("{fileNamePrefix}.log"), log.as_bytes());
    // Error already captured in `<prefix>.log` / the result `messages`; no stderr.
    match res {
        Ok(()) => 0,
        Err(_) => 1,
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn run_wasmtime_inner(prefix: &str, result_file: &str, _simflags: &str) -> Result<()> {
    use std::process::Command;
    let module = format!("{prefix}.wasm");
    if !std::path::Path::new(&module).exists() {
        return Err("standalone module not found (emitStandalone not run?)");
    }
    let wasmtime = std::env::var("OMC_WASMTIME").unwrap_or_else(|_| "wasmtime".to_owned());
    // `--dir .::.` preopens the cwd as the guest `.`; the module writes the result
    // file there with a relative path. `-W all-proposals=y` matches the `-all` given
    // to `wasm-merge`: models with nonlinear systems use a funcref table + `ref.func`
    // (reference-types / function-references), which the CLI otherwise rejects with
    // "heap types not supported without the gc feature". (The interactive wasmtime
    // crate enables these by default.)
    let status = Command::new(&wasmtime)
        .arg("run")
        .arg("-W")
        .arg("all-proposals=y")
        .arg("--dir")
        .arg(".::.")
        .arg(&module)
        .status()
        .map_err(|e| "cannot run (is it on PATH? override with OMC_WASMTIME)")?;
    if !status.success() {
        return Err("` run ` failed with");
    }
    // The module writes `<prefix>_res.mat`; rename if omc selected another name.
    let produced = format!("{prefix}_res.mat");
    if result_file != produced && std::path::Path::new(&produced).exists() {
        std::fs::rename(&produced, result_file)
            .map_err(|e| "cannot rename ->")?;
    }
    Ok(())
}

#[cfg(target_arch = "wasm32")]
fn run_wasmtime_inner(_prefix: &str, _result_file: &str, _simflags: &str) -> Result<()> {
    return Err("CodegenWasmJit: simCodeTarget=wasm is unavailable in the wasm omc build")
}
