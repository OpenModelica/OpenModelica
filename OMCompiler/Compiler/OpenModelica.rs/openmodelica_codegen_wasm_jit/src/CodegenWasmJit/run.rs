//! Running a translated model in-process: experiment settings, overrides,
//! start-value imports, the result target and the one-shot `run_simulation_inner`.

use super::*;

/// C's `initializeResultData`: the formats this runtime has a writer for.
pub(super) fn check_output_format(format: &str) -> std::result::Result<(), String> {
    if openmodelica_sim_meta::result::known(format) {
        return Ok(());
    }
    Err(format!(
        "CodegenWasmJit: this runtime writes `mat`/`csv`/`plt`/`arrow` results, or `empty` for none (got `{format}`)"
    ))
}

/// C's result-file resolution (`simulation_runtime.cpp`): `-r` outright, else
/// `<prefix>_res.<format>` under `-outputPath`, else what the caller derived from
/// the model.
pub(super) fn result_path(flags: &simflags::SimFlags, meta: &SimMeta, derived: &str) -> String {
    match (&flags.result_file, &flags.output_path) {
        (Some(r), _) => r.clone(),
        (None, Some(dir)) => format!("{dir}/{}_res.{}", meta.prefix, meta.output_format),
        // C names the file after the format `-outputFormat` settled on, while the
        // caller keeps the name it derived from the model — swap the extension in
        // `derived` to land on C's name without losing its directory.
        (None, None) => match derived.rsplit_once('.') {
            Some((stem, _)) if flags.output_format.is_some() => {
                format!("{stem}.{}", meta.output_format)
            }
            _ => derived.to_string(),
        },
    }
}

/// The result file of a run: its resolved path, the writer that name asks for,
/// the `-variableFilter` decision per signal, and `-single`.
pub(super) fn result_target(model: &SimModel, meta: &SimMeta, flags: &simflags::SimFlags, derived: &str) -> ResultTarget {
    let path = result_path(flags, meta, derived);
    let format = openmodelica_sim_meta::result::format_of(&path, &meta.output_format).to_string();
    ResultTarget { path, format, keep: output_selection(model), single: flags.single_precision }
}

/// Resolve each `-override=name=value` to its editable parameter's `SimData` slot.
/// Returns `(param_overrides, start_overrides, string_overrides)`: plain parameters
/// vs. state start values, applied at different points of initialization (see
/// `run_initialization`), and the String parameters, whose value is bytes.
///
/// C's `doOverride` also reports what it could not do, walking the `_init.xml`
/// quantities in class order. The result signals are that roster in that order,
/// with the editable parameters as its `isValueChangeable` subset.
pub(super) fn resolve_overrides(
    model: &SimModel,
    flags: &simflags::SimFlags,
) -> (Vec<(u32, WTy, f64)>, Vec<(u32, WTy, f64)>, Vec<(u32, String)>) {
    let raw = flags.override_raw.as_deref();
    let file = flags.override_file.as_ref();
    if let (Some(raw), Some((path, _))) = (raw, file) {
        omclog::info!(omclog::SOLVER, false, "using -override={raw} and -overrideFile={path}");
    }
    if let Some((path, _)) = file {
        omclog::info!(omclog::SOLVER, false, "read override values from file: {path}");
    }
    if raw.is_none() && file.is_none() {
        omclog::info(omclog::SOLVER, false, "NO override given on the command line.");
        return (Vec::new(), Vec::new(), Vec::new());
    }
    let given = |v: Option<&str>| v.unwrap_or("[not given]").to_string();
    omclog::info!(omclog::SOLVER, false, "-override={}", given(raw));
    omclog::info!(omclog::SOLVER, false, "-overrideFile={}", given(file.map(|(_, j)| j.as_str())));

    // C fills a hash map, so a repeated name keeps the last value and warns.
    let mut map: Vec<(&str, &str)> = Vec::new();
    for (name, val) in &flags.overrides {
        match map.iter_mut().find(|(n, _)| *n == name) {
            Some((_, old)) => {
                omclog::warning!(
                    omclog::STDOUT,
                    false,
                    "You are overriding variable: {name}={old} again with {name}={val}.",
                );
                *old = val;
            }
            None => map.push((name, val)),
        }
    }

    let mut params = Vec::new();
    let mut starts = Vec::new();
    let mut strings = Vec::new();
    let mut used: Vec<&str> = Vec::new();
    // C's `singleOverride` walks the `_init.xml` quantities in class order. The String
    // parameters are not result signals, so they follow, as `_init.xml` has them.
    let string_names = model.editable_params.iter().filter(|p| p.is_string).map(|p| p.name.as_str());
    for name in model.result_vars.iter().map(|v| v.name.as_str()).chain(string_names) {
        let Some(&(name, val)) = map.iter().find(|(n, _)| *n == name) else { continue };
        used.push(name);
        let Some(p) = model.editable_params.iter().find(|p| p.name == name) else {
            omclog::warning!(
                omclog::STDOUT,
                false,
                "It is not possible to override the following quantity: {name}\nIt seems to be \
                 structural, final, protected or evaluated or has a non-constant binding.",
            );
            continue;
        };
        omclog::info!(omclog::SOLVER, false, "override {name} = {val}");
        if p.is_string {
            strings.push((p.off, val.to_string()));
            continue;
        }
        // C warns only for the real and integer parameters (`warn_small_override`).
        let numeric_param = !p.is_start && (p.wty == WTy::F64 || !p.is_bool);
        if numeric_param && val.parse::<f64>().is_ok_and(|v| v.abs() < 1e-6) {
            omclog::warning!(
                omclog::STDOUT,
                false,
                "You are overriding {name} with a small value or zero.\nThis could lead to \
                 numerically dirty solutions or divisions by zero if not tearingStrictness=veryStrict.",
            );
        }
        let v = p.read_value(val);
        if p.is_start { &mut starts } else { &mut params }.push((p.off, p.wty, v));
    }
    for (name, _) in &map {
        if !used.contains(name) {
            omclog::warning!(
                omclog::STDOUT,
                false,
                "simulation_input_xml.c: override variable name not found in model: {name}\n",
            );
        }
    }
    omclog::info(omclog::SOLVER, false, "override done!");
    (params, starts, strings)
}

/// Resolve `-iif=<file>` against the model's [`SimMeta::import_roster`] at `-iit`
/// (the start time by default). Only the host can open the file — the browser reaches
/// it through the VFS — so the driver applies the values where C's
/// `importStartValues` does. A quantity `-override` names is left out so the command
/// line wins (ticket #15807); the driver reports the skip.
pub(super) fn resolve_start_imports(meta: &SimMeta, flags: &simflags::SimFlags) -> Option<sim_driver::StartImports> {
    let file = flags.init_file.as_ref()?;
    let time = flags.init_time.unwrap_or(meta.start_time);
    let mut reader = match openmodelica_mat_reader::MatReader::open(file) {
        Ok(r) => r,
        Err(e) => {
            record_error(format!("wasm-jit: unable to read input-file <{file}> [{e}]"));
            return None;
        }
    };
    let overridden = |n: &str| flags.overrides.iter().any(|(o, _)| o == n);
    let values = meta
        .import_roster()
        .iter()
        .flatten()
        .enumerate()
        .filter(|(_, (name, _, _))| !overridden(name))
        .filter_map(|(i, (name, _, _))| {
            let v = reader.find_var(name).and_then(|idx| reader.val(idx, time))?;
            Some((i as u32, v))
        })
        .collect();
    Some(sim_driver::StartImports { file: file.clone(), time, values })
}

/// The driver's [`sim_driver::ResultFileReader`]: C's `importStartValues` for the
/// real variables, which the optimizer's `-ipopt_init=file` repeats at every
/// collocation point. A name the file does not carry keeps the start it has.
pub(super) fn read_result_values(
    file: &str,
    names: &[&str],
    t: f64,
    out: &mut [f64],
) -> std::result::Result<(), String> {
    GUESS_READER.with(|c| {
        let mut c = c.borrow_mut();
        if c.as_ref().is_none_or(|(f, _)| f != file) {
            let r = openmodelica_mat_reader::MatReader::open(file)
                .map_err(|e| format!("unable to read input-file <{file}> [{e}]"))?;
            *c = Some((file.to_string(), r));
        }
        let (_, reader) = c.as_mut().expect("just filled");
        for (name, slot) in names.iter().zip(out) {
            if let Some(v) = reader.find_var(name).and_then(|i| reader.val(i, t)) {
                *slot = v;
            }
        }
        Ok(())
    })
}

thread_local! {
    /// The result file `-ipopt_init=file` reads, opened once for the whole run.
    static GUESS_READER: std::cell::RefCell<
        Option<(String, openmodelica_mat_reader::MatReader)>,
    > = const { std::cell::RefCell::new(None) };
    /// Model stdout captured during initialization, split from the simulation-phase
    /// output so the log stays ordered. `None` until initialization completes.
    pub(super) static INIT_OUTPUT: std::cell::RefCell<Option<String>> = const { std::cell::RefCell::new(None) };
    /// Only [`run_simulation_inner`] wants the split; other `run_initialization`
    /// callers (the interactive session) share the hook but must not split. Armed
    /// for one firing.
    pub(super) static SPLIT_ARMED: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
    /// Taken when the teardown hook fires, so destructor output follows the
    /// success line.
    pub(super) static SIM_OUTPUT: std::cell::RefCell<Option<String>> = const { std::cell::RefCell::new(None) };
}

/// Init-done hook: take the initialization phase's output, then restart the
/// capture. A no-op unless [`run_simulation_inner`] armed it.
pub(super) fn on_init_done() {
    if !SPLIT_ARMED.with(|a| a.replace(false)) {
        return;
    }
    INIT_OUTPUT.with(|c| *c.borrow_mut() = Some(openmodelica_wasi::wasi::take_stdout_capture()));
    openmodelica_wasi::wasi::start_stdout_capture();
}

/// The same split for what the external objects' destructors print: C runs them
/// after "The simulation finished successfully.".
pub(super) fn on_teardown() {
    SIM_OUTPUT.with(|c| *c.borrow_mut() = Some(openmodelica_wasi::wasi::take_stdout_capture()));
    openmodelica_wasi::wasi::start_stdout_capture();
}

/// Run the model, returning the result and the model's stdout split into the
/// initialization segment (`Some` once init completed) and the simulation segment.
/// Write `-l`'s linearized model where C's `linearize` puts it and render its
/// notice, which the caller appends after the run's success line.
pub(super) fn write_lin_file(meta: &SimMeta, run: &sim_driver::RunResult, flags: &simflags::SimFlags) -> String {
    let (Some(f), Some(lin)) = (&run.lin, &meta.lin) else { return String::new() };
    let path = match &flags.output_path {
        Some(dir) => format!("{dir}/{}", f.name),
        None => f.name.clone(),
    };
    if write_output(&path, f.content.as_bytes()).is_err() {
        return openmodelica_modelica_utilities::format_log_stdout(
            &format!("Cannot open File {path}"),
            openmodelica_modelica_utilities::LOG_STDOUT_ERROR,
        );
    }
    let full = std::fs::canonicalize(&path).map(|p| p.display().to_string()).unwrap_or(path);
    let (msgs, is_error) = openmodelica_sim_meta::linearize::write_notice(lin, f, &full);
    let prefix = if is_error {
        openmodelica_modelica_utilities::LOG_STDOUT_ERROR
    } else {
        openmodelica_modelica_utilities::LOG_STDOUT_INFO
    };
    msgs.iter().map(|m| openmodelica_modelica_utilities::format_log_stdout(m, prefix)).collect()
}

pub(super) fn run_simulation_inner(prefix: &str, result_file: &str, simflags: &str) -> (std::result::Result<(), String>, Option<String>, String, String) {
    let model = sim_models()
        .lock()
        .unwrap_or_else(|e| e.into_inner())
        .get(prefix)
        .cloned();
    let Some(model) = model else {
        return (
            Err("no prepared wasm-jit model for (translateModel not run?)".to_string()),
            None,
            String::new(),
            String::new(),
        );
    };
    // The caller prefixes the failure, so this is the bare reason.
    let flags = match install_sim_flags(simflags) {
        Ok(f) => f,
        Err(e) => return (Err(e), None, String::new(), String::new()),
    };
    // The `-lv=` runtime flag list selects log streams, as for the C executable.
    let log_stats = flags.has_log("LOG_STATS");
    // C refuses to seed a run from the file it is about to overwrite.
    if let Some(init) = &flags.init_file
        && init == flags.result_file.as_deref().unwrap_or(result_file)
    {
        return (
            Err(format!(
                "Cannot import a result file for initialization that is also the current output \
                 file <{init}>.\nConsider redirecting the output result file (-r=<new_res.mat>) or \
                 renaming the result file that is used for initialization import."
            )
            ),
            None,
            String::new(),
            String::new(),
        );
    }
    INIT_OUTPUT.with(|c| *c.borrow_mut() = None);
    sim_driver::set_init_done_hook(on_init_done);
    SIM_OUTPUT.with(|c| *c.borrow_mut() = None);
    sim_driver::set_teardown_hook(on_teardown);
    SPLIT_ARMED.with(|a| a.set(true));
    openmodelica_wasm_jit::host::native_stdout::install();
    sim_driver::init_host_hooks();
    sim_driver::set_result_file_reader(read_result_values);
    let (meta, experiment_log) = run_experiment(&model, &flags);
    openmodelica_wasi::wasi::start_stdout_capture();
    let (param_ov, start_ov, string_ov) = resolve_overrides(&model, &flags);
    sim_driver::set_param_overrides(param_ov, start_ov, string_ov);
    sim_driver::set_start_imports(resolve_start_imports(&meta, &flags));
    // `-abortSlowSimulation`: stop the run when chattering is detected.
    sim_driver::set_abort_slow(flags.abort_slow);
    // The hard `-alarm`, if asked for: set before the modules are instantiated.
    sim_runtime::set_alarm(flags.alarm);
    let mut extra = String::new();
    let mut post = String::new();
    let res = (|| -> std::result::Result<(), String> {
        // `empty` (and `-noemit`) runs the integration but writes no result file —
        // useful for benchmarking the solver in isolation from the `.mat` writer.
        let target = result_target(&model, &meta, &flags, result_file);
        check_output_format(&target.format)?;
        let (path, keep) = (target.path.clone(), target.keep.clone());
        let (run, written) = sim_runtime::run(&model, &meta, target)?;
        // The driver already printed the `-output` line that precedes this block.
        if log_stats {
            extra.push_str(&openmodelica_sim_meta::stats::log_stats_block(&run.stats));
        }
        // C's `printModelInfo`, after the result file is closed.
        openmodelica_sim_meta::profiling::finish(&meta, &path, output_size(&path));
        post = write_lin_file(&meta, &run, &flags);
        capture_last_sim(&model, written, &run.params, &run.stats, &keep, &path);
        Ok(())
    })();
    // Disarm in case init failed before the hook fired.
    SPLIT_ARMED.with(|a| a.set(false));
    // Everything captured after the split is the simulation phase (plus `extra`:
    // LOG_STATS / chattering lines). `INIT_OUTPUT` is `None` when init failed.
    // With the hook fired, the capture holds the destructors' output instead.
    let teardown_output = SIM_OUTPUT.with(|c| c.borrow_mut().take());
    let tail = openmodelica_wasi::wasi::take_stdout_capture();
    let (sim_capture, post_capture) = match teardown_output {
        Some(sim) => (sim, tail),
        None => (tail, String::new()),
    };
    let post = format!("{post_capture}{post}");
    let sim_output = format!("{sim_capture}{extra}");
    let init_output = INIT_OUTPUT.with(|c| c.borrow_mut().take());
    // C prints the sparse-solver announcements (initializeLinear/NonlinearSystems)
    // ahead of the init-success line; prepend our pre-rendered copy to the init output.
    let head = format!("{experiment_log}{}", flag_change_log(&flags));
    let init_output = if head.is_empty() {
        init_output
    } else {
        Some(format!("{head}{}", init_output.unwrap_or_default()))
    };
    (res, init_output, sim_output, post)
}
