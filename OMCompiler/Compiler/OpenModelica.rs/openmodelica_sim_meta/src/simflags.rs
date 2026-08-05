//! Runtime simulation flags, parsed from an **argv-shaped** list.
//!
//! One parser for every entry point. A wasip1 standalone module is a WASI command:
//! its command line arrives through `args_sizes_get`/`args_get`, which
//! `std::env::args()` reads. The interactive runtime is instantiated once and
//! simulated many times, so its host hands the same argv over through
//! `rt_sim_set_args`, in the byte layout `args_get` itself writes (the strings
//! NUL-terminated back to back).
//!
//! Names and accepted values follow the C runtime's
//! (`SimulationRuntime/c/util/simulation_options.c`). Every selector is an
//! `Option`: `None` keeps the built-in default.

use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;

/// `-s`
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Solver {
    Dassl,
    Ida,
    Cvode,
    Gbode,
    Euler,
    RungeKutta,
    SymSolver,
    SymSolverSsc,
}

/// `-nls`. The discriminants are the wire codes [`SimFlags::solver_codes`] hands to
/// the wasm-jit runtime's `rt_set_solvers`, which mirrors them; 0 means unset, so
/// they start at 1 and must not be renumbered.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum Nls {
    Hybrid = 1,
    Kinsol = 2,
    Newton = 3,
    Mixed = 4,
    Homotopy = 5,
}

/// `-nlsLS`, the linear solver inside the nonlinear one. `Rsparse` is wasm-jit's
/// own solver, not a C runtime value.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum NlsLs {
    Default = 1,
    TotalPivot = 2,
    Lapack = 3,
    Klu = 4,
    Rsparse = 5,
}

/// `-ls`
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum Ls {
    Default = 1,
    Lapack = 2,
    TotalPivot = 3,
    Klu = 4,
}

/// `-lss`. `Rsparse` is wasm-jit's own solver, not a C runtime value.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum Lss {
    Default = 1,
    Klu = 2,
    Rsparse = 3,
}

/// `-idaLS`, the linear solver IDA's Newton iteration uses.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum IdaLs {
    Dense,
    /// C's default.
    Klu,
    Spgmr,
    Spbcg,
    Sptfqmr,
}

#[derive(Clone, Debug, Default, PartialEq)]
pub struct SimFlags {
    pub solver: Option<Solver>,
    pub nls: Option<Nls>,
    pub nls_ls: Option<NlsLs>,
    pub ls: Option<Ls>,
    pub lss: Option<Lss>,
    /// `-lv` streams, uppercased.
    pub log: Vec<String>,
    /// [`log`](Self::log) through C's `setGlobalVerboseLevel`, so an unrecognized
    /// name fails at parse time as in C and no reader re-derives the implications.
    /// [`parse`] fills it; a default-constructed `SimFlags` has no stream on.
    pub log_mask: crate::omclog::Mask,
    pub abort_slow: bool,
    /// `-alarm`: seconds after which the run is aborted (C's `FLAG_ALARM`, where
    /// it is a `SIGALRM` on the simulation executable). 0 disables it, as in C.
    pub alarm: Option<u32>,
    /// `-ils`: equidistant homotopy steps of the initial solve (C's
    /// `init_lambda_steps`, default 3).
    pub init_lambda_steps: Option<i32>,
    /// `-stepSize`: overrides what `SimMeta::step_size` derives from the model.
    pub step_size: Option<f64>,
    /// `-jacobianNominalFactor`: scales the ODE Jacobian's FD step floor.
    pub jacobian_nominal_factor: Option<f64>,
    /// `-idaLS`
    pub ida_ls: Option<IdaLs>,
    /// `-idaSensitivity`: IDAS forward sensitivities w.r.t. the parameters
    /// `--calculateSensitivities` selected.
    pub ida_sensitivity: bool,
    /// The `IDASet*` tunables (`-idaMaxErrorTestFails`, `-idaMaxNonLinIters`,
    /// `-idaMaxConvFails`, `-idaNonLinConvCoef`).
    pub ida_max_err_test_fails: Option<i32>,
    pub ida_max_nonlin_iters: Option<i32>,
    pub ida_max_conv_fails: Option<i32>,
    pub ida_nonlin_conv_coef: Option<f64>,
    /// `-noSuppressAlg`, which C reads inverted: setting it is what makes C call
    /// `IDASetSuppressAlg(TRUE)`.
    pub ida_no_suppress_alg: bool,
    /// `-maxIntegrationOrder`: caps the BDF order (5 by default).
    pub max_order: Option<i32>,
    /// `-initialStepSize`
    pub initial_step_size: Option<f64>,
    /// `-homotopyOnFirstTry` / `-noHomotopyOnFirstTry`. `None` is C's default,
    /// which sets `FLAG_HOMOTOPY_ON_FIRST_TRY` whenever the model supports
    /// homotopy.
    pub homotopy_on_first_try: Option<bool>,
    /// `-override=name=value,…` unresolved: mapping a name to its `SimData` slot
    /// needs the model, which only the caller has.
    pub overrides: Vec<(String, f64)>,
    /// `-output=a,b,c`: variables printed at the stop time (C's
    /// `outputVariablesAtEnd` / `writeOutputVars`).
    pub output_vars: Vec<String>,
    /// `-r=<file>`: where the result is written, overriding the name derived from
    /// the model.
    pub result_file: Option<String>,
    /// `-iif=<file>`: a result file whose values at the start time seed the start
    /// attributes and parameters (C's `importStartValues`).
    pub init_file: Option<String>,
    /// `-noEquidistantTimeGrid`: emit the integrator's own steps instead of
    /// interpolating onto the output grid.
    pub no_equidistant_grid: bool,
    /// `-noEquidistantOutputFrequency=n`: with the above, emit every n-th step.
    pub no_equidistant_freq: Option<u32>,
    /// `-noEquidistantOutputTime=t`: with the above, emit once `time > k*t`. C's
    /// dassl also caps its step at `t` (`RWORK(2)`, `INFO(7)`).
    pub no_equidistant_time: Option<f64>,
    /// `-maxStepSize=h`: DASKR's `INFO(7)` / `RWORK(2)`.
    pub max_step_size: Option<f64>,
    /// `-noEventEmit`: drop the result rows a step that handled an event produces.
    pub no_event_emit: bool,
    /// `-nlssMinSize=n` / `-nlssMaxDensity=d`: C's `nonlinearSparseSolverMinSize` /
    /// `nonlinearSparseSolverMaxDensity`, the rule that hands a system to kinsol+KLU.
    pub nlss_min_size: Option<u32>,
    pub nlss_max_density: Option<f64>,
    /// `-emit_protected`: keep `protected` variables in the result file.
    pub emit_protected: bool,
    /// `-ignoreHideResult`: keep `annotation(HideResult=true)` variables too.
    pub ignore_hide_result: bool,
    /// `-variableFilter=<regex>`: replaces the model's own filter. The caller
    /// compiles it — this crate is `no_std` and has no engine.
    pub variable_filter: Option<String>,
    /// `-noRestart`: keep integrating across an event instead of restarting.
    pub no_restart: bool,
    /// `-noRootFinding`: take the end of the step as the event time.
    pub no_root_finding: bool,
    /// The `-gb*` flags, `(name, value)`; a value-less one is stored as `""`.
    /// gbode reads these by name the way C reads `omc_flagValue`, so the whole
    /// family does not have to be mirrored as struct fields.
    pub gb: Vec<(String, String)>,
    /// Flags this runtime does not model, kept so a caller can report them.
    pub unknown: Vec<String>,
    /// The argv this was parsed from, so a host forwards the same bytes rather than
    /// re-serializing a parsed form.
    pub argv: Vec<String>,
}

impl SimFlags {
    /// The value of a `-gb*` flag, or `None` when it was not given.
    pub fn gb_flag(&self, name: &str) -> Option<String> {
        self.gb.iter().find(|(n, _)| n == name).map(|(_, v)| v.clone())
    }

    /// Whether a value-less `-gb*` flag was given.
    pub fn gb_toggle(&self, name: &str) -> bool {
        self.gb.iter().any(|(n, _)| n == name)
    }

    pub fn has_log(&self, stream: &str) -> bool {
        crate::omclog::STREAM_NAME
            .iter()
            .position(|n| *n == stream)
            .is_some_and(|i| crate::omclog::mask_has(self.log_mask, i as crate::omclog::Stream))
    }

    /// `(-nls, -nlsLS, -ls, -lss)` as the wire codes the wasm-jit runtime's
    /// `rt_set_solvers` takes (0 = unset). Which solver each code selects is the
    /// runtime's business — it matches on them — so no policy lives here.
    pub fn solver_codes(&self) -> (u32, u32, u32, u32) {
        let code = |v: Option<u32>| v.unwrap_or(0);
        (
            code(self.nls.map(|v| v as u32)),
            code(self.nls_ls.map(|v| v as u32)),
            code(self.ls.map(|v| v as u32)),
            code(self.lss.map(|v| v as u32)),
        )
    }

    /// [`argv`](Self::argv) in the WASI `args_get` layout, for `rt_sim_set_args`.
    pub fn to_wasi_args(&self) -> Vec<u8> {
        let mut b = Vec::new();
        for a in &self.argv {
            b.extend_from_slice(a.as_bytes());
            b.push(0);
        }
        b
    }
}

/// What the runtime can serve, so [`check`] fails an unsupported request at startup
/// rather than running a different solver.
#[derive(Clone, Copy, Debug)]
pub struct Capabilities {
    /// The runtime's SUNDIALS archives, which hold KINSOL as well as KLU.
    pub klu: bool,
    pub ida: bool,
    pub cvode: bool,
    /// This runtime has a wall clock, so `-alarm` can be honoured.
    pub alarm: bool,
    /// This runtime can compile a regex, so `-variableFilter` can be honoured.
    pub variable_filter: bool,
}

/// Reject flag values this runtime cannot honour.
pub fn check(f: &SimFlags, cap: Capabilities) -> Result<(), String> {
    if !cap.klu {
        for (flag, requested) in [
            ("lss", f.lss == Some(Lss::Klu)),
            ("ls", f.ls == Some(Ls::Klu)),
            ("nlsLS", f.nls_ls == Some(NlsLs::Klu)),
        ] {
            if requested {
                return Err(format!("-{flag}=klu: this runtime has no KLU linear solver"));
            }
        }
    }
    if f.alarm.is_some() && !cap.alarm {
        return Err("-alarm: this runtime has no wall clock".to_string());
    }
    if f.variable_filter.is_some() && !cap.variable_filter {
        return Err("-variableFilter: this runtime has no regex engine".to_string());
    }
    let unsupported = match f.solver {
        Some(Solver::Ida) if !cap.ida => "ida",
        Some(Solver::Cvode) if !cap.cvode => "cvode",
        _ => return Ok(()),
    };
    let have: Vec<String> = supported(cap)
        .into_iter()
        .find(|(n, _)| *n == "s")
        .map(|(_, v)| v.iter().map(|n| alloc::format!("`{n}`")).collect())
        .unwrap_or_default();
    Err(format!("-s={unsupported}: this runtime supports {} only", have.join(", ")))
}

/// The values each solver flag accepts on this build, in menu order. A UI offering
/// only these never builds a command line [`check`] rejects. `default` is left out:
/// omitting a flag selects it.
pub fn supported(cap: Capabilities) -> Vec<(&'static str, Vec<&'static str>)> {
    let mut menu = alloc::vec![
        ("s", offered(SOLVERS, cap)),
        ("nls", offered(NLS_VALUES, cap)),
        ("nlsLS", offered(NLS_LS_VALUES, cap)),
        ("ls", offered(LS_VALUES, cap)),
        ("lss", offered(LSS_VALUES, cap)),
    ];
    if cap.ida {
        menu.push(("idaLS", offered(IDA_LS_VALUES, cap)));
    }
    menu
}


/// C's `FLAG_NAME` / `FLAG_TYPE` (`util/simulation_options.c`): every flag the C
/// runtime knows, and whether it takes a value. A name outside it is C's
/// `invalid command line option`; one inside it that [`parse`] does not handle is a
/// flag this runtime cannot honour. Both are errors — ignoring either runs
/// something the caller did not ask for.
const C_FLAGS: &[(&str, bool)] = &[
    ("abortSlowSimulation", false),
    ("alarm", true),
    ("clock", true),
    ("cpu", false),
    ("csvOstep", true),
    ("cvodeNonlinearSolverIteration", true),
    ("cvodeLinearMultistepMethod", true),
    ("cx", true),
    ("daeMode", false),
    ("deltaXLinearize", true),
    ("deltaXSolver", true),
    ("embeddedServer", true),
    ("embeddedServerPort", true),
    ("mat_sync", true),
    ("emit_protected", false),
    ("eps", true),
    ("f", true),
    ("help", true),
    ("homAdaptBend", true),
    ("homBacktraceStrategy", true),
    ("homHEps", true),
    ("homMaxLambdaSteps", true),
    ("homMaxNewtonSteps", true),
    ("homMaxTries", true),
    ("homNegStartDir", false),
    ("homotopyOnFirstTry", false),
    ("noHomotopyOnFirstTry", false),
    ("homTauDecFac", true),
    ("homTauDecFacPredictor", true),
    ("homTauIncFac", true),
    ("homTauIncThreshold", true),
    ("homTauMax", true),
    ("homTauMin", true),
    ("homTauStart", true),
    ("idaMaxErrorTestFails", true),
    ("idaMaxNonLinIters", true),
    ("idaMaxConvFails", true),
    ("idaNonLinConvCoef", true),
    ("idaLS", true),
    ("idaScaling", false),
    ("idaSensitivity", false),
    ("ignoreHideResult", false),
    ("iif", true),
    ("iim", true),
    ("iit", true),
    ("ils", true),
    ("initialStepSize", true),
    ("csvInput", true),
    ("stateFile", true),
    ("inputPath", true),
    ("ipopt_hesse", true),
    ("ipopt_init", true),
    ("ipopt_jac", true),
    ("ipopt_max_iter", true),
    ("ipopt_warm_start", true),
    ("jacobian", true),
    ("jacobianNominalFactor", true),
    ("jacobianThreads", true),
    ("l", true),
    ("l_datarec", false),
    ("logFormat", true),
    ("ls", true),
    ("ls_ipopt", true),
    ("lss", true),
    ("lssMaxDensity", true),
    ("lssMinSize", true),
    ("lv", true),
    ("lvMaxWarn", true),
    ("lv_time", true),
    ("lv_system", true),
    ("mbi", true),
    ("mei", true),
    ("maxIntegrationOrder", true),
    ("maxStepSize", true),
    ("measureTimePlotFormat", true),
    ("moo", false),
    ("moo_l2bn_p1_it", true),
    ("moo_l2bn_p2_it", true),
    ("moo_l2bn_p2_lvl", true),
    ("newtonFTol", true),
    ("newtonMaxSteps", true),
    ("newtonMaxStepFactor", true),
    ("newtonXTol", true),
    ("newtonJacUpdates", true),
    ("newton", true),
    ("nls", true),
    ("nlsInfo", false),
    ("nlsLS", true),
    ("nlssMaxDensity", true),
    ("nlssMinSize", true),
    ("nlsJacTestATol", true),
    ("nlsJacTestRTol", true),
    ("noemit", false),
    ("noEquidistantTimeGrid", false),
    ("noEquidistantOutputFrequency", true),
    ("noEquidistantOutputTime", true),
    ("noEventEmit", false),
    ("noRestart", false),
    ("noRootFinding", false),
    ("noScaling", false),
    ("noSuppressAlg", false),
    ("optDebugJac", true),
    ("optimizerNP", true),
    ("optimizerTimeGrid", true),
    ("output", true),
    ("outputFormat", true),
    ("outputPath", true),
    ("override", true),
    ("overrideFile", true),
    ("port", true),
    ("r", true),
    ("reconcile", false),
    ("reconcileBoundaryConditions", false),
    ("reconcileState", false),
    ("gbm", true),
    ("gbctrl", true),
    ("gbctrl_evnt_reinit", false),
    ("gbctrl_filter", true),
    ("gbctrl_fhr", false),
    ("gberr", true),
    ("gbint", true),
    ("gbnls", true),
    ("gbnls_internal_damping", true),
    ("gbnls_internal_jackeep", true),
    ("gbfm", true),
    ("gbfctrl", true),
    ("gbferr", true),
    ("gbfint", true),
    ("gbfnls", true),
    ("gbratio", true),
    ("rt", true),
    ("s", true),
    ("saveInitialGuess_system", true),
    ("single", false),
    ("steps", false),
    ("startTime", true),
    ("steadyState", false),
    ("steadyStateTol", true),
    ("stepSize", true),
    ("stopAtSystem", true),
    ("stopTime", true),
    ("svdCount", true),
    ("svdSigma", true),
    ("sx", true),
    ("tolerance", true),
    ("keepHessian", true),
    ("variableFilter", true),
    ("w", false),
    ("parmodNumThreads", true),
    ("parmodScheduler", true),
    ("parmodClustering", true),
    ("parmodClustersPerLevel", true),
    ("parmodExportTaskGraph", true),
    ("parmodImportClustering", true),
    ("parmodDumpStages", true),
];

/// C's `JACOBIAN_METHOD_NAME` (`simulation_options.c`).
const JACOBIAN_METHODS: &[&str] = &[
    "coloredNumerical",
    "internalNumerical",
    "coloredSymbolical",
    "coloredSymbolicalAdjoint",
    "numerical",
    "symbolical",
    "bicoloredSymbolical",
];

/// C flags deliberately let through.
const IGNORED_FLAGS: &[&str] = &[];

/// Parse an argv slice (`argv[0]` is the program name and is skipped).
/// `-flag=value` and `-flag value` are both accepted, as in the C runtime.
/// An unrecognized *value* for a recognized flag is an error listing what is
/// accepted; so is a flag this runtime does not implement (see [`C_FLAGS`]).
pub fn parse<S: AsRef<str>>(argv: &[S]) -> Result<SimFlags, String> {
    let mut f = SimFlags {
        argv: argv.iter().map(|a| a.as_ref().to_string()).collect(),
        ..SimFlags::default()
    };
    let mut i = 1;
    while i < argv.len() {
        let arg = argv[i].as_ref();
        i += 1;
        let Some(body) = arg.strip_prefix('-') else { continue };
        let (name, inline) = match body.split_once('=') {
            Some((n, v)) => (n, Some(v)),
            None => (body, None),
        };
        // A value-taking flag may carry it inline or as the next argument.
        let mut value = |name: &str| -> Result<String, String> {
            if let Some(v) = inline {
                return Ok(v.to_string());
            }
            let v = argv.get(i).ok_or_else(|| format!("-{name} needs a value"))?;
            i += 1;
            Ok(v.as_ref().to_string())
        };
        match name {
            "s" | "solver" => f.solver = Some(pick("s", &value(name)?, SOLVERS)?),
            "nls" => f.nls = Some(pick("nls", &value(name)?, NLS_VALUES)?),
            "nlsLS" => f.nls_ls = Some(pick("nlsLS", &value(name)?, NLS_LS_VALUES)?),
            "ls" => f.ls = Some(pick("ls", &value(name)?, LS_VALUES)?),
            "lss" => f.lss = Some(pick("lss", &value(name)?, LSS_VALUES)?),
            "lv" => {
                for s in value(name)?.split(',') {
                    let s = s.trim();
                    if !s.is_empty() {
                        f.log.push(s.to_uppercase());
                    }
                }
            }
            "override" => {
                for item in value(name)?.split(',') {
                    // An unparsable or unknown override is a no-op, as in C.
                    if let Some((n, v)) = item.split_once('=') {
                        if let Ok(val) = v.trim().parse::<f64>() {
                            f.overrides.push((n.trim().to_string(), val));
                        }
                    }
                }
            }
            "output" => f.output_vars = split_top_level(&value(name)?),
            "emit_protected" => f.emit_protected = true,
            "ignoreHideResult" => f.ignore_hide_result = true,
            "variableFilter" => f.variable_filter = Some(value(name)?),
            "r" => f.result_file = Some(value(name)?),
            "iif" => f.init_file = Some(value(name)?),
            "noEquidistantTimeGrid" => f.no_equidistant_grid = true,
            "noEquidistantOutputFrequency" => {
                f.no_equidistant_freq = Some(
                    value(name)?
                        .parse::<u32>()
                        .map_err(|_| "-noEquidistantOutputFrequency needs an integer".to_string())?,
                )
            }
            "noEventEmit" => f.no_event_emit = true,
            // Every value this runtime can serve is the colored numerical one, which
            // is also C's `setJacobianMethod` fallback where only the sparsity
            // pattern is available -- which is all the wasm-jit backend emits.
            "jacobian" => {
                let v = value(name)?;
                if !JACOBIAN_METHODS.contains(&v.as_str()) {
                    return Err(format!("Unknown value `{v}` for flag `-jacobian`"));
                }
            }
            "nlssMinSize" => f.nlss_min_size = Some(int(name, &value(name)?)?.max(0) as u32),
            "nlssMaxDensity" => f.nlss_max_density = Some(real(name, &value(name)?)?),
            "maxStepSize" => f.max_step_size = Some(real(name, &value(name)?)?),
            "noEquidistantOutputTime" => {
                f.no_equidistant_time = Some(
                    value(name)?
                        .parse::<f64>()
                        .map_err(|_| "-noEquidistantOutputTime needs a number".to_string())?,
                )
            }
            // The only method this runtime has is C's default.
            "iim" => {
                let v = value(name)?;
                if v != "symbolic" {
                    return Err(format!("-iim={v}: this runtime only has the symbolic method"));
                }
            }
            "abortSlowSimulation" => f.abort_slow = true,
            "alarm" => {
                let secs = value(name)?
                    .parse::<u32>()
                    .map_err(|_| "-alarm takes an integer argument".to_string())?;
                f.alarm = (secs > 0).then_some(secs);
            }
            "ils" => {
                f.init_lambda_steps =
                    Some(value(name)?.parse::<i32>().map_err(|_| "-ils needs an integer".to_string())?)
            }
            "stepSize" => {
                f.step_size = Some(
                    value(name)?.parse::<f64>().map_err(|_| "-stepSize needs a number".to_string())?,
                )
            }
            "jacobianNominalFactor" => {
                f.jacobian_nominal_factor = Some(
                    value(name)?
                        .parse::<f64>()
                        .map_err(|_| "-jacobianNominalFactor needs a number".to_string())?,
                )
            }
            "idaLS" => f.ida_ls = Some(pick("idaLS", &value(name)?, IDA_LS_VALUES)?),
            "idaSensitivity" => f.ida_sensitivity = true,
            "idaMaxErrorTestFails" => f.ida_max_err_test_fails = Some(int(name, &value(name)?)?),
            "idaMaxNonLinIters" => f.ida_max_nonlin_iters = Some(int(name, &value(name)?)?),
            "idaMaxConvFails" => f.ida_max_conv_fails = Some(int(name, &value(name)?)?),
            "idaNonLinConvCoef" => f.ida_nonlin_conv_coef = Some(real(name, &value(name)?)?),
            "noSuppressAlg" => f.ida_no_suppress_alg = true,
            "maxIntegrationOrder" => f.max_order = Some(int(name, &value(name)?)?),
            "initialStepSize" => f.initial_step_size = Some(real(name, &value(name)?)?),
            "homotopyOnFirstTry" => f.homotopy_on_first_try = Some(true),
            "noHomotopyOnFirstTry" => f.homotopy_on_first_try = Some(false),
            "noRestart" => f.no_restart = true,
            "noRootFinding" => f.no_root_finding = true,
            // The `-gb*` family is stored by name; gbode validates the values when
            // it is built, so an unused one is still rejected (C ignores it).
            _ if name.starts_with("gb") && C_FLAGS.iter().any(|(n, _)| *n == name) => {
                let takes_value =
                    C_FLAGS.iter().find(|(n, _)| *n == name).is_some_and(|(_, v)| *v);
                let v = if takes_value { value(name)? } else { String::new() };
                f.gb.push((name.to_string(), v));
            }
            _ => {
                let known = C_FLAGS.iter().find(|(n, _)| *n == name);
                if known.is_some_and(|(_, takes_value)| *takes_value) && inline.is_none() {
                    // Consume the separate value, so it is not read as a flag itself.
                    i += 1;
                }
                match known {
                    None => return Err(format!("invalid command line option: {arg}")),
                    Some((n, _)) if !IGNORED_FLAGS.contains(n) => {
                        f.unknown.push(arg.to_string());
                        return Err(format!(
                            "-{n}: this runtime does not implement the flag, so the run would \
                             silently ignore it"
                        ));
                    }
                    Some(_) => {}
                }
            }
        }
    }
    f.log_mask = crate::omclog::mask_from_streams(&f.log)?;
    Ok(f)
}

/// C's `nonlinearSparseSolverMinSize` / `nonlinearSparseSolverMaxDensity`, with
/// C's defaults (`simulation_options.h`) where the flags are absent.
pub fn nlss_thresholds(f: &SimFlags) -> (u32, f64) {
    (f.nlss_min_size.unwrap_or(1000), f.nlss_max_density.unwrap_or(0.1))
}

/// C's `parseVariableStr`: split on commas outside `[...]`, so `x[1,2]` stays one name.
fn split_top_level(s: &str) -> Vec<String> {
    let mut out = Vec::new();
    let mut depth = 0i32;
    let mut cur = String::new();
    for c in s.chars() {
        match c {
            '[' => depth += 1,
            ']' => depth -= 1,
            ',' if depth == 0 => {
                out.push(core::mem::take(&mut cur));
                continue;
            }
            _ => {}
        }
        cur.push(c);
    }
    out.push(cur);
    out.retain(|v| !v.is_empty());
    out
}

fn bad(flag: &str, got: &str, accepted: &str) -> String {
    format!("unrecognized value `{got}` for -{flag} (accepted: {accepted})")
}

fn int(flag: &str, v: &str) -> Result<i32, String> {
    v.parse().map_err(|_| format!("-{flag} needs an integer"))
}

fn real(flag: &str, v: &str) -> Result<f64, String> {
    v.parse().map_err(|_| format!("-{flag} needs a number"))
}

/// One accepted value of a solver-selection flag: C's name, what it selects, and
/// whether to offer it.
type Value<T> = (&'static str, T, Offer);

/// Whether [`supported`] may offer a value. [`parse`] accepts every value C accepts
/// regardless, so this only decides what to advertise.
#[derive(Clone, Copy, PartialEq, Eq)]
enum Offer {
    Always,
    WithSundials,
    WithIda,
    WithCvode,
    /// `default`, an alias of a listed value, or one this runtime substitutes for.
    Never,
}

impl Offer {
    fn available(self, cap: Capabilities) -> bool {
        match self {
            Offer::Always => true,
            Offer::WithSundials => cap.klu,
            Offer::WithIda => cap.ida,
            Offer::WithCvode => cap.cvode,
            Offer::Never => false,
        }
    }
}

/// `-s`. `symSolver*` parse so the unsupported-*method* error reports them, not the
/// flag parser.
const SOLVERS: &[Value<Solver>] = &[
    ("dassl", Solver::Dassl, Offer::Always),
    ("dasslrt", Solver::Dassl, Offer::Never),
    ("euler", Solver::Euler, Offer::Always),
    ("rungekutta", Solver::RungeKutta, Offer::Always),
    ("gbode", Solver::Gbode, Offer::Always),
    ("ida", Solver::Ida, Offer::WithIda),
    ("cvode", Solver::Cvode, Offer::WithCvode),
    ("symSolver", Solver::SymSolver, Offer::Never),
    ("symSolverSsc", Solver::SymSolverSsc, Offer::Never),
];

/// `-nls`. Without the archives `kinsol` runs the runtime's own sparse Newton.
const NLS_VALUES: &[Value<Nls>] = &[
    ("hybrid", Nls::Hybrid, Offer::Always),
    ("kinsol", Nls::Kinsol, Offer::WithSundials),
    ("newton", Nls::Newton, Offer::Always),
    ("mixed", Nls::Mixed, Offer::Always),
    ("homotopy", Nls::Homotopy, Offer::Always),
];

/// `-nlsLS`. Only KLU and `rsparse` exist here; C's dense values fall to `rsparse`.
const NLS_LS_VALUES: &[Value<NlsLs>] = &[
    ("default", NlsLs::Default, Offer::Never),
    ("totalpivot", NlsLs::TotalPivot, Offer::Never),
    ("lapack", NlsLs::Lapack, Offer::Never),
    ("rsparse", NlsLs::Rsparse, Offer::Always),
    ("klu", NlsLs::Klu, Offer::WithSundials),
];

/// `-ls`. `lapack` is partial-pivot LU falling back to the total-pivot search,
/// which `totalpivot` goes straight to.
const LS_VALUES: &[Value<Ls>] = &[
    ("default", Ls::Default, Offer::Never),
    ("lapack", Ls::Lapack, Offer::Always),
    ("totalpivot", Ls::TotalPivot, Offer::Always),
    ("klu", Ls::Klu, Offer::WithSundials),
];

/// `-lss`
const LSS_VALUES: &[Value<Lss>] = &[
    ("default", Lss::Default, Offer::Never),
    ("rsparse", Lss::Rsparse, Offer::Always),
    ("klu", Lss::Klu, Offer::WithSundials),
];

/// `-idaLS`. All five reach a SUNLinearSolver; the whole entry rides on `cap.ida`.
const IDA_LS_VALUES: &[Value<IdaLs>] = &[
    ("klu", IdaLs::Klu, Offer::Always),
    ("dense", IdaLs::Dense, Offer::Always),
    ("spgmr", IdaLs::Spgmr, Offer::Always),
    ("spbcg", IdaLs::Spbcg, Offer::Always),
    ("sptfqmr", IdaLs::Sptfqmr, Offer::Always),
];

/// Every value the parser accepts, offered or not.
fn names<T: Copy>(table: &[Value<T>]) -> Vec<&'static str> {
    table.iter().map(|&(n, ..)| n).collect()
}

/// Look a value up, naming every accepted one on a miss.
fn pick<T: Copy>(flag: &str, v: &str, table: &[Value<T>]) -> Result<T, String> {
    match table.iter().find(|(name, ..)| *name == v) {
        Some(&(_, val, _)) => Ok(val),
        None => Err(bad(flag, v, &names(table).join(", "))),
    }
}

/// The values this build may offer, in table order.
fn offered<T: Copy>(table: &[Value<T>], cap: Capabilities) -> Vec<&'static str> {
    table.iter().filter(|&&(.., o)| o.available(cap)).map(|&(n, ..)| n).collect()
}

/// Set once per run before the driver starts; read from anywhere, since the NLS/LS
/// entry points take no flag arguments.
mod store {
    use super::SimFlags;

    #[cfg(feature = "std")]
    mod imp {
        use super::SimFlags;
        use core::cell::RefCell;
        std::thread_local! {
            static FLAGS: RefCell<SimFlags> = RefCell::new(SimFlags::default());
        }
        pub fn set(f: SimFlags) {
            FLAGS.with(|c| *c.borrow_mut() = f);
        }
        pub fn get() -> SimFlags {
            FLAGS.with(|c| c.borrow().clone())
        }
        pub fn with<R>(g: impl FnOnce(&SimFlags) -> R) -> R {
            FLAGS.with(|c| g(&c.borrow()))
        }
    }

    #[cfg(not(feature = "std"))]
    mod imp {
        use super::SimFlags;
        use core::cell::UnsafeCell;
        // Single-threaded in-wasm runtime, so a plain cell is sound (as in
        // `driver::overrides_store`).
        struct Store(UnsafeCell<Option<SimFlags>>);
        unsafe impl Sync for Store {}
        static STORE: Store = Store(UnsafeCell::new(None));
        pub fn set(f: SimFlags) {
            unsafe { *STORE.0.get() = Some(f) };
        }
        pub fn get() -> SimFlags {
            unsafe { (*STORE.0.get()).clone().unwrap_or_default() }
        }
        pub fn with<R>(g: impl FnOnce(&SimFlags) -> R) -> R {
            match unsafe { &*STORE.0.get() } {
                Some(f) => g(f),
                None => g(&SimFlags::default()),
            }
        }
    }

    pub use imp::{get, set, with};
}

pub fn set_flags(f: SimFlags) {
    crate::omclog::set_mask(f.log_mask);
    store::set(f);
}

pub fn flags() -> SimFlags {
    store::get()
}

/// Read the flags in place. [`flags`] clones, and `-override=` carries one `String`
/// per parameter — hundreds on a re-simulation from the web simulator's initial
/// conditions — so a solver hot path must read through this.
pub fn with_flags<R>(f: impl FnOnce(&SimFlags) -> R) -> R {
    store::with(f)
}

/// Split the WASI `args_get` byte layout — NUL-terminated strings back to back —
/// into an argv vector. A trailing unterminated tail is taken as a final argument
/// so a caller that forgot the last NUL loses nothing.
pub fn argv_from_bytes(bytes: &[u8]) -> Vec<String> {
    let mut out = Vec::new();
    for part in bytes.split(|&b| b == 0) {
        if !part.is_empty() {
            out.push(String::from_utf8_lossy(part).into_owned());
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn argv(s: &[&str]) -> Vec<String> {
        core::iter::once("model".to_string()).chain(s.iter().map(|x| x.to_string())).collect()
    }

    const NOTHING: Capabilities =
        Capabilities { klu: false, ida: false, cvode: false, alarm: false, variable_filter: false };
    const EVERYTHING: Capabilities =
        Capabilities { klu: true, ida: true, cvode: true, alarm: true, variable_filter: true };

    #[test]
    fn defaults_are_all_unset() {
        let f = parse(&argv(&[])).expect("empty argv parses");
        assert_eq!(f.solver, None);
        assert_eq!((f.nls, f.nls_ls, f.ls, f.lss), (None, None, None, None));
        assert!(f.log.is_empty() && f.overrides.is_empty() && !f.abort_slow);
        assert!(check(&f, NOTHING).is_ok());
    }

    #[test]
    fn argv_survives_a_round_trip_through_the_wasi_layout() {
        let f = parse(&argv(&["-nls=newton", "-lv=LOG_STATS"])).expect("parses");
        let back = parse(&argv_from_bytes(&f.to_wasi_args())).expect("re-parses");
        assert_eq!(back, f);
    }

    #[test]
    fn unavailable_solvers_are_rejected_with_the_flag_named() {
        for (arg, needle) in [("-lss=klu", "KLU"), ("-ls=klu", "KLU"), ("-nlsLS=klu", "KLU"),
                              ("-s=ida", "dassl"), ("-s=cvode", "dassl")] {
            let f = parse(&argv(&[arg])).expect("parses");
            let e = check(&f, NOTHING).expect_err("must reject");
            assert!(e.contains(needle), "{arg}: {e}");
        }
        // With the capability present the same request is fine, and the rejection
        // of another solver then offers it.
        let f = parse(&argv(&["-lss=klu"])).expect("parses");
        assert!(check(&f, Capabilities { klu: true, ..NOTHING }).is_ok());
        let f = parse(&argv(&["-s=ida"])).expect("parses");
        let e = check(&f, Capabilities { cvode: true, ..NOTHING }).expect_err("must reject");
        assert!(e.contains("`cvode`"), "{e}");
    }

    #[test]
    fn selectable_solvers_need_no_capability() {
        for arg in
            ["-nls=kinsol", "-nls=hybrid", "-lss=rsparse", "-s=euler", "-s=dassl", "-s=gbode",
             "-s=rungekutta"]
        {
            let f = parse(&argv(&[arg])).expect("parses");
            assert!(check(&f, NOTHING).is_ok(), "{arg}");
        }
    }

    // `supported` feeds the web UI's solver menus, so an offered value must survive
    // both the parser and the capability check of the build that offered it.
    #[test]
    fn everything_supported_parses_and_checks() {
        for cap in [NOTHING, EVERYTHING] {
            for (flag, values) in supported(cap) {
                for v in values {
                    let f = parse(&argv(&[&format!("-{flag}={v}")])).expect(&format!("-{flag}={v}"));
                    assert!(check(&f, cap).is_ok(), "-{flag}={v}");
                }
            }
        }
        // KLU and KINSOL come from the archives, so neither shows up above.
        assert!(!supported(NOTHING).iter().any(|(_, v)| v.contains(&"klu")));
        assert!(!supported(NOTHING).iter().any(|(_, v)| v.contains(&"kinsol")));
    }

    /// The other direction: a value [`check`] rejects must not be offered.
    #[test]
    fn rejected_values_are_never_offered() {
        let all = [
            ("s", names(SOLVERS)),
            ("nls", names(NLS_VALUES)),
            ("nlsLS", names(NLS_LS_VALUES)),
            ("ls", names(LS_VALUES)),
            ("lss", names(LSS_VALUES)),
            ("idaLS", names(IDA_LS_VALUES)),
        ];
        for cap in [NOTHING, Capabilities { klu: true, ..NOTHING }, EVERYTHING] {
            let menu = supported(cap);
            for (flag, values) in &all {
                for v in values {
                    let f = parse(&argv(&[&format!("-{flag}={v}")])).expect("parses");
                    if check(&f, cap).is_ok() {
                        continue;
                    }
                    let offered = menu.iter().any(|(n, vals)| n == flag && vals.contains(v));
                    assert!(!offered, "-{flag}={v} is offered but rejected");
                }
            }
        }
    }

    // The wire codes the wasm-jit runtime decodes: unset is 0, and the values are
    // fixed. Renumbering here without renumbering `solvers.rs` picks a wrong solver.
    #[test]
    fn solver_codes_are_stable() {
        assert_eq!(parse(&argv(&[])).expect("parses").solver_codes(), (0, 0, 0, 0));
        let f = parse(&argv(&["-nls=kinsol", "-nlsLS=totalpivot", "-ls=klu", "-lss=rsparse"]))
            .expect("parses");
        assert_eq!(f.solver_codes(), (2, 2, 4, 3));
    }

    #[test]
    fn inline_and_separate_values_agree() {
        let a = parse(&argv(&["-nls=kinsol", "-lss=klu"])).expect("inline");
        let b = parse(&argv(&["-nls", "kinsol", "-lss", "klu"])).expect("separate");
        // `argv` differs by construction; the parsed selectors must not.
        assert_eq!((a.nls, a.lss), (b.nls, b.lss));
        assert_eq!(a.nls, Some(Nls::Kinsol));
        assert_eq!(a.lss, Some(Lss::Klu));
    }

    #[test]
    fn program_name_is_not_a_flag() {
        // argv[0] is skipped even when it looks like one.
        let f = parse(&["-nls=kinsol", "-lss=klu"]).expect("parses");
        assert_eq!(f.nls, None);
        assert_eq!(f.lss, Some(Lss::Klu));
    }

    #[test]
    fn bad_value_is_an_error_listing_the_accepted_ones() {
        let e = parse(&argv(&["-nls=nope"])).expect_err("must reject");
        assert!(e.contains("nope") && e.contains("kinsol"), "{e}");
    }

    #[test]
    fn unimplemented_and_invalid_flags_are_rejected() {
        let e = parse(&argv(&["-noSuchFlag"])).expect_err("must reject");
        assert!(e.contains("invalid command line option"), "{e}");
        let f = parse(&argv(&["-emit_protected", "-lv=LOG_STATS"])).expect("parses");
        assert!(f.emit_protected && f.has_log("LOG_STATS"));
    }

    // The value of a rejected option must not be read as a flag of its own.
    #[test]
    fn the_no_equidistant_grid_family_parses() {
        let f = parse(&argv(&["-noEquidistantTimeGrid", "-noEquidistantOutputFrequency=5"]))
            .expect("parses");
        assert!(f.no_equidistant_grid && f.no_equidistant_freq == Some(5));
        let f = parse(&argv(&["-noEquidistantTimeGrid", "-noEquidistantOutputTime=0.5"]))
            .expect("parses");
        assert_eq!(f.no_equidistant_time, Some(0.5));
    }

    #[test]
    fn a_rejected_options_value_is_not_read_as_a_flag() {
        let e = parse(&argv(&["-csvInput", "in.csv"])).expect_err("must reject");
        assert!(e.contains("csvInput"), "{e}");
    }

    #[test]
    fn log_all_implies_every_stream() {
        let f = parse(&argv(&["-lv=LOG_ALL"])).expect("parses");
        assert!(f.has_log("LOG_NLS_V"));
    }

    #[test]
    fn overrides_keep_order_and_skip_junk() {
        let f = parse(&argv(&["-override=a=1,bad,b=2.5,c=x"])).expect("parses");
        assert_eq!(f.overrides, [("a".to_string(), 1.0), ("b".to_string(), 2.5)]);
    }

    #[test]
    fn missing_value_is_an_error() {
        assert!(parse(&argv(&["-nls"])).is_err());
    }

    // C's `-alarm=0` disables the alarm rather than setting a zero-second one.
    #[test]
    fn alarm_zero_disables() {
        assert_eq!(parse(&argv(&["-alarm=30"])).expect("parses").alarm, Some(30));
        assert_eq!(parse(&argv(&["-alarm=0"])).expect("parses").alarm, None);
        assert!(parse(&argv(&["-alarm=soon"])).is_err());
    }

    #[test]
    fn wasi_args_layout_round_trips() {
        let bytes = b"model\0-nls=kinsol\0-lv=LOG_STATS\0";
        let a = argv_from_bytes(bytes);
        assert_eq!(a, ["model", "-nls=kinsol", "-lv=LOG_STATS"]);
        assert_eq!(parse(&a).expect("parses").nls, Some(Nls::Kinsol));
        // A missing final NUL must not drop the last argument.
        assert_eq!(argv_from_bytes(b"model\0-nls=newton"), ["model", "-nls=newton"]);
    }
}
