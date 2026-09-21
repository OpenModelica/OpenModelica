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
    // A model whose `external "C"` reaches outside the omc process gets the
    // isolation C's simulation executable has: that code can crash, `exit()` or
    // hang, and in this process it takes the compiler with it.
    let outcome = match isolate_run(&model) {
        true => isolated_run(&model, &flags, result_file, log_stats),
        false => perform_run(&model, &flags, result_file, log_stats),
    };
    if let Some(c) = outcome.captured {
        capture_last_sim(&model, c.written, &c.params, &c.stats, &c.keep, &c.path);
    }
    (outcome.res, outcome.init_output, outcome.sim_output, outcome.post)
}

/// Whether this run goes into a child process. `OMC_WASM_ISOLATE_SIM=0/1`
/// overrides the model's own answer, which is how the two paths are compared.
fn isolate_run(model: &SimModel) -> bool {
    match std::env::var("OMC_WASM_ISOLATE_SIM").as_deref() {
        Ok("0") | Ok("false") => false,
        Ok(_) => true,
        Err(_) => model.ext_outside_process.load(std::sync::atomic::Ordering::Relaxed),
    }
}

/// What one run produced: the three log segments `runSimulation` assembles, and
/// what the session's signal registry needs. Everything here survives a run in a
/// child process ([`isolated_run`]); nothing else does.
struct RunOutcome {
    res: std::result::Result<(), String>,
    init_output: Option<String>,
    sim_output: String,
    post: String,
    /// `None` when the run never produced a result file to capture.
    captured: Option<Captured>,
}

/// [`capture_last_sim`]'s arguments.
struct Captured {
    written: Written,
    params: Vec<f64>,
    stats: SolveStats,
    keep: Vec<bool>,
    path: String,
}

/// Run the model in this process: install the hooks, capture the model's stdout
/// and split it into the initialization and simulation segments.
fn perform_run(model: &SimModel, flags: &simflags::SimFlags, result_file: &str, log_stats: bool) -> RunOutcome {
    INIT_OUTPUT.with(|c| *c.borrow_mut() = None);
    sim_driver::set_init_done_hook(on_init_done);
    SIM_OUTPUT.with(|c| *c.borrow_mut() = None);
    sim_driver::set_teardown_hook(on_teardown);
    SPLIT_ARMED.with(|a| a.set(true));
    openmodelica_wasm_jit::host::native_stdout::install();
    sim_driver::init_host_hooks();
    sim_driver::set_result_file_reader(read_result_values);
    let (meta, experiment_log) = run_experiment(model, flags);
    openmodelica_wasi::wasi::start_stdout_capture();
    let (param_ov, start_ov, string_ov) = resolve_overrides(model, flags);
    sim_driver::set_param_overrides(param_ov, start_ov, string_ov);
    sim_driver::set_start_imports(resolve_start_imports(&meta, flags));
    // `-abortSlowSimulation`: stop the run when chattering is detected.
    sim_driver::set_abort_slow(flags.abort_slow);
    // The hard `-alarm`, if asked for: set before the modules are instantiated.
    sim_runtime::set_alarm(flags.alarm);
    let mut extra = String::new();
    let mut post = String::new();
    let mut captured = None;
    let res = (|| -> std::result::Result<(), String> {
        // `empty` (and `-noemit`) runs the integration but writes no result file —
        // useful for benchmarking the solver in isolation from the `.mat` writer.
        let target = result_target(model, &meta, flags, result_file);
        check_output_format(&target.format)?;
        let (path, keep) = (target.path.clone(), target.keep.clone());
        let (run, written) = sim_runtime::run(model, &meta, target)?;
        // The driver already printed the `-output` line that precedes this block.
        if log_stats {
            extra.push_str(&openmodelica_sim_meta::stats::log_stats_block(&run.stats));
        }
        // C's `printModelInfo`, after the result file is closed.
        openmodelica_sim_meta::profiling::finish(&meta, &path, output_size(&path));
        post = write_lin_file(&meta, &run, flags);
        captured = Some(Captured { written, params: run.params, stats: run.stats, keep, path });
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
    let head = format!("{experiment_log}{}", flag_change_log(flags));
    let init_output = if head.is_empty() {
        init_output
    } else {
        Some(format!("{head}{}", init_output.unwrap_or_default()))
    };
    RunOutcome { res, init_output, sim_output, post, captured }
}

/// [`perform_run`] in a child process, so that a crashing, exiting or wedged
/// `external "C"` ends the simulation and not omc. The child writes the result
/// file itself and hands back everything else through the pipe; a child that
/// never answers becomes the failure C would have reported for its executable.
fn isolated_run(model: &SimModel, flags: &simflags::SimFlags, result_file: &str, log_stats: bool) -> RunOutcome {
    // The child must not have to JIT-compile: it has no thread pool left, and the
    // work belongs to the compile phase anyway.
    sim_runtime::ensure_prepared(model);
    let run = || encode_outcome(&perform_run(model, flags, result_file, log_stats));
    let failed = |why: String| RunOutcome {
        res: Err(why),
        init_output: None,
        sim_output: String::new(),
        post: String::new(),
        captured: None,
    };
    match openmodelica_wasm_jit::isolate::run(flags.alarm, run) {
        Some(openmodelica_wasm_jit::isolate::Outcome::Answered(bytes)) => decode_outcome(&bytes)
            .unwrap_or_else(|| failed("the simulation process reported an unreadable result".to_string())),
        Some(openmodelica_wasm_jit::isolate::Outcome::Died(why)) => failed(why),
        Some(openmodelica_wasm_jit::isolate::Outcome::TimedOut) => {
            failed(sim_driver::ALARM_ABORT_ERR.to_string())
        }
        Some(openmodelica_wasm_jit::isolate::Outcome::Cancelled) => {
            failed("CodegenWasmJit: simulation cancelled".to_string())
        }
        // No child: run it here, as every other target does.
        None => perform_run(model, flags, result_file, log_stats),
    }
}

// --- The child's answer ---------------------------------------------------
//
// A [`RunOutcome`] as bytes. Both ends are in this file and the two processes
// are the same binary, so the encoding is private, unversioned and positional:
// little-endian scalars, `u32`-prefixed strings and `f64`/`u64` vectors.

fn put_str(b: &mut Vec<u8>, s: &str) {
    b.extend_from_slice(&(s.len() as u32).to_le_bytes());
    b.extend_from_slice(s.as_bytes());
}

fn put_f64s(b: &mut Vec<u8>, v: &[f64]) {
    b.extend_from_slice(&(v.len() as u32).to_le_bytes());
    v.iter().for_each(|x| b.extend_from_slice(&x.to_le_bytes()));
}

fn put_u64s(b: &mut Vec<u8>, v: &[u64]) {
    b.extend_from_slice(&(v.len() as u32).to_le_bytes());
    v.iter().for_each(|x| b.extend_from_slice(&x.to_le_bytes()));
}

fn encode_outcome(o: &RunOutcome) -> Vec<u8> {
    let mut b = Vec::new();
    match &o.res {
        Ok(()) => b.push(0),
        Err(e) => {
            b.push(1);
            put_str(&mut b, e);
        }
    }
    b.push(o.init_output.is_some() as u8);
    put_str(&mut b, o.init_output.as_deref().unwrap_or(""));
    put_str(&mut b, &o.sim_output);
    put_str(&mut b, &o.post);
    b.push(o.captured.is_some() as u8);
    if let Some(c) = &o.captured {
        b.extend_from_slice(&(c.written.n_rows as u64).to_le_bytes());
        put_f64s(&mut b, &c.written.first_row);
        put_f64s(&mut b, &c.params);
        b.extend_from_slice(&(c.keep.len() as u32).to_le_bytes());
        b.extend(c.keep.iter().map(|&k| k as u8));
        put_str(&mut b, &c.path);
        let s = &c.stats;
        put_str(&mut b, s.method);
        put_u64s(
            &mut b,
            &[
                s.steps, s.res_evals, s.jac_evals, s.err_test_fails, s.conv_test_fails,
                s.state_events, s.time_events, s.lin_solves,
            ],
        );
        put_f64s(&mut b, &s.timers);
        put_u64s(&mut b, &s.tcalls);
    }
    b
}

/// Reads what [`encode_outcome`] wrote; `None` for a truncated or malformed
/// frame, which the caller reports as a failed run.
fn decode_outcome(bytes: &[u8]) -> Option<RunOutcome> {
    let mut r = Reader(bytes);
    let res = match r.u8()? {
        0 => Ok(()),
        _ => Err(r.str()?),
    };
    let has_init = r.u8()? != 0;
    let init = r.str()?;
    let init_output = has_init.then_some(init);
    let sim_output = r.str()?;
    let post = r.str()?;
    let captured = match r.u8()? {
        0 => None,
        _ => {
            let n_rows = r.u64()? as usize;
            let first_row = r.f64s()?;
            let params = r.f64s()?;
            let keep = (0..r.u32()?).map(|_| r.u8().map(|k| k != 0)).collect::<Option<Vec<bool>>>()?;
            let path = r.str()?;
            let method = r.str()?;
            let c = r.u64s()?;
            let mut stats = SolveStats {
                // The counters travel; `method` is one of the driver's labels, and
                // interning the copy read back is cheaper than mapping every label.
                method: String::leak(method),
                ..Default::default()
            };
            [
                &mut stats.steps, &mut stats.res_evals, &mut stats.jac_evals,
                &mut stats.err_test_fails, &mut stats.conv_test_fails, &mut stats.state_events,
                &mut stats.time_events, &mut stats.lin_solves,
            ]
            .into_iter()
            .zip(c)
            .for_each(|(slot, v)| *slot = v);
            let timers = r.f64s()?;
            let tcalls = r.u64s()?;
            stats.timers.iter_mut().zip(timers).for_each(|(s, v)| *s = v);
            stats.tcalls.iter_mut().zip(tcalls).for_each(|(s, v)| *s = v);
            Some(Captured { written: Written { n_rows, first_row }, params, stats, keep, path })
        }
    };
    Some(RunOutcome { res, init_output, sim_output, post, captured })
}

struct Reader<'a>(&'a [u8]);

impl Reader<'_> {
    fn take(&mut self, n: usize) -> Option<&[u8]> {
        let (head, rest) = self.0.split_at_checked(n)?;
        self.0 = rest;
        Some(head)
    }
    fn u8(&mut self) -> Option<u8> {
        Some(self.take(1)?[0])
    }
    fn u32(&mut self) -> Option<u32> {
        Some(u32::from_le_bytes(self.take(4)?.try_into().ok()?))
    }
    fn u64(&mut self) -> Option<u64> {
        Some(u64::from_le_bytes(self.take(8)?.try_into().ok()?))
    }
    fn str(&mut self) -> Option<String> {
        let n = self.u32()? as usize;
        String::from_utf8(self.take(n)?.to_vec()).ok()
    }
    fn f64s(&mut self) -> Option<Vec<f64>> {
        let n = self.u32()? as usize;
        Some(self.take(8 * n)?.chunks_exact(8).map(|c| f64::from_le_bytes(c.try_into().unwrap())).collect())
    }
    fn u64s(&mut self) -> Option<Vec<u64>> {
        let n = self.u32()? as usize;
        Some(self.take(8 * n)?.chunks_exact(8).map(|c| u64::from_le_bytes(c.try_into().unwrap())).collect())
    }
}
