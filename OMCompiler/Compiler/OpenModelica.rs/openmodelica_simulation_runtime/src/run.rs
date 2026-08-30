//! The entry points the generated `main` calls: `_main_initRuntimeAndSimulation`
//! and `_main_SimulationRuntime`.
//!
//! Together they are C's `initRuntimeAndSimulation` + `startNonInteractiveSimulation`:
//! parse the command line, read the init XML, allocate `DATA`, run the shared
//! driver and write the result file.

use core::ffi::{c_char, c_int};
use std::io::Write;

use openmodelica_mat_writer::{MatVar, Precision};
use openmodelica_sim_meta::{MetaKind, SimMeta, driver, omclog, simflags};

use crate::abi::*;
use crate::data::RtData;
use crate::engine::CEngine;
use crate::model_data::{self, InitXml};

/// What `_main_initRuntimeAndSimulation` prepares and `_main_SimulationRuntime`
/// consumes.
struct Run {
    rt: RtData,
    xml: InitXml,
    prefix: String,
}

/// A simulation executable runs one model on one thread, so the handover is a
/// file-scope value, as it is in the C runtime.
static RUN: RunCell = RunCell(core::cell::UnsafeCell::new(None));
struct RunCell(core::cell::UnsafeCell<Option<Box<Run>>>);
unsafe impl Sync for RunCell {}
impl RunCell {
    fn set(&self, r: Box<Run>) {
        unsafe { *self.0.get() = Some(r) };
    }
    fn take(&self) -> Option<Box<Run>> {
        unsafe { (*self.0.get()).take() }
    }
}

/// `-lv` lines and the model's own `print` share this stream, in call order.
fn log_sink(_stream: omclog::Stream, _ty: omclog::LogType, s: &str) {
    print_line(s);
}

fn print_line(s: &str) {
    let mut out = std::io::stdout();
    let _ = out.write_all(s.as_bytes());
    let _ = out.flush();
}

/// C's line at the end of `initializeModel`, naming the homotopy steps it took.
fn init_done() {
    let steps = driver::init_homotopy_steps();
    if steps == 0 {
        print_line("LOG_SUCCESS       | info    | The initialization finished successfully without homotopy method.\n");
    } else {
        let local = if driver::init_homotopy_local() { "local " } else { "" };
        print_line(&format!(
            "LOG_SUCCESS       | info    | The initialization finished successfully with {steps} {local}homotopy steps.\n"
        ));
    }
}

/// C prints this before the external objects are destroyed, so their own output
/// follows it.
fn teardown() {
    print_line("LOG_SUCCESS       | info    | The simulation finished successfully.\n");
}

fn argv_strings(argc: c_int, argv: *mut *mut c_char) -> Vec<String> {
    (0..argc.max(0) as usize)
        .map(|i| unsafe {
            let p = *argv.add(i);
            if p.is_null() {
                String::new()
            } else {
                core::ffi::CStr::from_ptr(p).to_string_lossy().into_owned()
            }
        })
        .collect()
}

/// The `enum _FLAG` entries the generated code and this runtime read out of
/// `omc_flag`/`omc_flagValue`, with the names `options.c` matches them by.
const C_FLAGS: &[(usize, &str)] = &[
    (FLAG_EMIT_PROTECTED, "emit_protected"),
    (FLAG_F, "f"),
    (FLAG_IDAS, "idaSensitivity"),
    (FLAG_IGNORE_HIDERESULT, "ignoreHideResult"),
    (FLAG_IIF, "iif"),
    (FLAG_INPUT_CSV, "csvInput"),
    (FLAG_INPUT_PATH, "inputPath"),
    (FLAG_LV, "lv"),
    (FLAG_MOO_OPTIMIZATION, "moo"),
    (FLAG_NOEMIT, "noemit"),
    (FLAG_OUTPUT_FORMAT, "outputFormat"),
    (FLAG_OUTPUT_PATH, "outputPath"),
    (FLAG_OVERRIDE, "override"),
    (FLAG_OVERRIDE_FILE, "overrideFile"),
    (FLAG_R, "r"),
    (FLAG_S, "s"),
];

/// C's `checkCommandLineArguments`, for the entries the generated code reads.
fn fill_omc_flags(argv: &[String]) {
    for (ix, name) in C_FLAGS {
        let mut seen = None;
        let mut i = 1;
        while i < argv.len() {
            let a = &argv[i];
            let body = a.strip_prefix("-").unwrap_or(a);
            if body == *name {
                seen = Some(argv.get(i + 1).cloned().unwrap_or_default());
            } else if let Some(v) = body.strip_prefix(&format!("{name}=")) {
                seen = Some(v.to_string());
            }
            i += 1;
        }
        if let Some(value) = seen {
            unsafe {
                crate::support::omc_flag[*ix] = 1;
                crate::support::omc_flagValue[*ix] = model_data::strdup(&value);
            }
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn _main_initRuntimeAndSimulation(
    argc: c_int,
    argv: *mut *mut c_char,
    data: *mut DATA,
    thread_data: *mut threadData_t,
) -> c_int {
    let args = argv_strings(argc, argv);
    driver::set_log_sink(log_sink);
    driver::set_log_sink_is_stdout(true);
    driver::set_init_done_hook(init_done);
    driver::set_teardown_hook(teardown);
    fill_omc_flags(&args);

    let flags = match simflags::parse(&args) {
        Ok(f) => f,
        Err(e) => {
            omclog::error(omclog::STDOUT, false, &e);
            return 1;
        }
    };
    // `-abortSlowSimulation`: without this a chattering model runs to the stop time.
    driver::set_abort_slow(flags.abort_slow);
    simflags::set_flags(flags);
    crate::support::publish_log_streams();
    simflags::with_flags(simflags::print_notices);

    let md: &mut MODEL_DATA = unsafe { &mut *(*data).modelData };
    let si: &mut SIMULATION_INFO = unsafe { &mut *(*data).simulationInfo };
    let prefix = cstr(md.modelFilePrefix);

    // C reads `<prefix>_init.xml` from the working directory unless `-f` names
    // another file; the model may also carry the contents compiled in.
    let xml_path = flag_value(FLAG_F).unwrap_or_else(|| format!("{prefix}_init.xml"));
    let xml = if !md.initXMLData.is_null() {
        model_data::parse_str(&cstr(md.initXMLData))
    } else {
        model_data::parse(&xml_path)
    };
    let mut xml = match xml {
        Ok(x) => x,
        Err(e) => {
            omclog::error(omclog::STDOUT, false, &e);
            return 1;
        }
    };
    // Before any of the reads below look at a `start`.
    simflags::with_flags(|f| model_data::do_override(&mut xml, f));

    model_data::read_sizes(&xml, md);
    model_data::read_experiment(&xml, si);
    si.OPENMODELICAHOME = model_data::strdup(xml.md("OPENMODELICAHOME"));
    model_data::read_variables(&xml, md);

    crate::nls::install_hooks(data, thread_data, &prefix);
    // The per-system clocks cost two clock reads per solve, so they are only armed
    // where `LOG_STATS_V` will print them (C's `measure_time_flag` equivalent).
    openmodelica_solvers::sysstat::enable(omclog::active(omclog::STATS_V));
    crate::nls::warn_once_unsupported_nls();
    let rt = crate::data::initialize(data, thread_data);
    // `samplesInfo[i].index` names the sample in the `LOG_EVENTS` time-event line,
    // and the metadata is built before the driver's own `initSample` call. The
    // indices are compile-time constants, so filling the array now is enough; the
    // start/interval it also writes are recomputed once the parameters are known.
    if let Some(f) = unsafe { (*(*data).callback).function_initSample } {
        unsafe { f(data, thread_data) };
    }
    si.minStepSize = 4.0 * f64::EPSILON * si.startTime.abs().max(si.stopTime.abs());
    RUN.set(Box::new(Run { rt, xml, prefix }));
    0
}

/// The value `-<name>` was given, if it was.
fn flag_value(ix: usize) -> Option<String> {
    unsafe {
        (crate::support::omc_flag[ix] != 0).then(|| cstr(crate::support::omc_flagValue[ix]))
    }
}

fn cstr(p: *const c_char) -> String {
    if p.is_null() {
        String::new()
    } else {
        unsafe { core::ffi::CStr::from_ptr(p) }.to_string_lossy().into_owned()
    }
}

/// C's `_main_SimulationRuntime`: `startNonInteractiveSimulation` under
/// `MMC_TRY_INTERNAL(globalJumpBuffer)`, so a model error nothing absorbed leaves
/// through this frame and not through the generated `main`'s top-level catch.
#[unsafe(no_mangle)]
pub extern "C" fn _main_SimulationRuntime(
    argc: c_int,
    argv: *mut *mut c_char,
    data: *mut DATA,
    thread_data: *mut threadData_t,
) -> c_int {
    let mut ret = -1;
    let ok = crate::support::protected_global(thread_data, || {
        ret = start_non_interactive_simulation(argc, argv, data, thread_data);
    });
    // C's `MMC_CATCH_INTERNAL` leaves the run here without the frees below it.
    if !ok {
        unsafe { (*(*data).simulationInfo).simulationSuccess = 1 };
        return -1;
    }
    ret
}

fn start_non_interactive_simulation(
    _argc: c_int,
    _argv: *mut *mut c_char,
    data: *mut DATA,
    _thread_data: *mut threadData_t,
) -> c_int {
    let run = match RUN.take() {
        Some(r) => r,
        None => {
            omclog::error(omclog::STDOUT, false, "the simulation runtime was not initialized");
            return -1;
        }
    };
    let Run { rt, xml, prefix } = *run;
    let layout = rt.layout;
    let mut meta = crate::meta::build(data, &xml, &layout, &prefix);
    simflags::with_flags(|f| meta.apply_flags(f));

    let mut engine = CEngine::new(rt);
    // The attribute mirrors start from what the XML gave; the generated
    // `updateBoundVariableAttributes` refreshes them during initialization.
    engine.sync_attributes();
    engine.seed_string_vars();

    let method = meta.method.clone();
    let (result, _label) = match driver::drive(&mut engine, &meta, 0, &method, false, false) {
        Ok(v) => v,
        Err(e) => {
            free_systems();
            // The driver already reported these; a second line here is one C never
            // prints.
            if !matches!(
                e,
                driver::ASSERT_ERR
                    | driver::INIT_FAILED_ERR
                    | driver::SOLVER_FAILED_ERR
                    | driver::CHATTER_ABORT_ERR
            ) {
                omclog::error(omclog::STDOUT, false, e);
            }
            unsafe { (*(*data).simulationInfo).simulationSuccess = 1 };
            // C's `_main_SimulationRuntime` leaves `retVal` at -1 when the run
            // left through the global jump buffer, which is what a model error
            // that nothing absorbed is.
            return -1;
        }
    };

    if omclog::active(omclog::STATS) {
        print_line(&openmodelica_sim_meta::stats::log_stats_block(&result.stats));
    }
    if let Some(file) = &result.lin {
        let path = simflags::with_flags(|f| match &f.output_path {
            Some(dir) => format!("{dir}/{}", file.name),
            None => file.name.clone(),
        });
        if let Err(e) = std::fs::write(&path, &file.content) {
            omclog::error(omclog::STDOUT, false, &format!("Cannot open File {path}: {e}"));
            return -1;
        }
        if let Some(lin) = &meta.lin {
            // C names `-outputPath`'s path as given, and otherwise prefixes the
            // working directory.
            let shown = match simflags::with_flags(|f| f.output_path.is_some()) {
                true => path.clone(),
                false => match std::env::current_dir() {
                    Ok(cwd) => format!("{}/{path}", cwd.display()),
                    Err(_) => path.clone(),
                },
            };
            let (msgs, is_error) =
                openmodelica_sim_meta::linearize::write_notice(lin, file, &shown);
            for msg in &msgs {
                if is_error {
                    omclog::error(omclog::STDOUT, false, msg)
                } else {
                    omclog::info(omclog::STDOUT, false, msg)
                }
            }
        }
    }
    if let Err(e) = write_result(&meta, &result, data) {
        omclog::error(omclog::STDOUT, false, &e);
        return -1;
    }
    unsafe { (*(*data).simulationInfo).simulationSuccess = 0 };
    free_systems();
    0
}

/// C's `freeMixedSystems` / `freeLinearSystems` / `freeNonlinearSystems`, of which
/// only the headers are observable: the solver data is Rust-owned and dropped with
/// the process, as C's is.
fn free_systems() {
    for (stream, what) in [
        (omclog::MIXED, "free mixed system solvers"),
        (omclog::LS_V, "free linear system solvers"),
        (omclog::NLS, "free non-linear system solvers"),
    ] {
        omclog::info(stream, true, what);
        omclog::close(stream);
    }
}

/// `method="optimization"` and `-moo` are not served yet; C's entry point exists
/// so the generated `main` links.
#[unsafe(no_mangle)]
pub extern "C" fn _main_OptimizationRuntime(
    _argc: c_int,
    _argv: *mut *mut c_char,
    _data: *mut DATA,
    _thread_data: *mut threadData_t,
) -> c_int {
    omclog::error(
        omclog::STDOUT,
        false,
        "the Rust simulation runtime does not serve -moo yet; build with --simCodeTarget=C",
    );
    1
}

/// C's `sim_result.writeParameterData` + `emit`, deferred to the end: the driver
/// hands back every row at once. `-r` names the file, else `modelData`'s
/// `resultFileName`, else `<prefix>_res.mat`.
fn write_result(meta: &SimMeta, result: &driver::RunResult, data: *mut DATA) -> Result<(), String> {
    if meta.output_format != "mat" {
        if meta.output_format == "empty" {
            return Ok(());
        }
        return Err(format!("the Rust simulation runtime cannot write '{}' yet", meta.output_format));
    }
    let md: &MODEL_DATA = unsafe { &*(*data).modelData };
    let name = if md.resultFileName.is_null() {
        format!("{}_res.mat", meta.prefix)
    } else {
        cstr(md.resultFileName)
    };
    let path = simflags::with_flags(|f| f.result_file.clone()).unwrap_or(name);

    let keep = meta.output_keep(None);
    let mut matvars: Vec<MatVar> = Vec::new();
    let mut kept_params: Vec<f64> = Vec::new();
    let mut param_ix = 0usize;
    for (v, &keep) in meta.vars.iter().zip(&keep) {
        let is_param = matches!(v.kind, MetaKind::Param { .. });
        if is_param && keep {
            kept_params.push(result.params.get(param_ix).copied().unwrap_or(0.0));
        }
        param_ix += is_param as usize;
        if !keep {
            continue;
        }
        matvars.push(MatVar { name: &v.name, comment: &v.comment, kind: v.kind.mat() });
    }
    let precision =
        simflags::with_flags(|f| if f.single_precision { Precision::Single } else { Precision::Double });
    let bytes = openmodelica_mat_writer::write_mat4(
        &matvars,
        meta.start_time,
        meta.stop_time,
        &result.rows,
        result.n_reals,
        &kept_params,
        precision,
    );
    std::fs::write(&path, bytes).map_err(|e| format!("cannot write {path}: {e}"))
}
