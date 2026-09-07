//! Simulation flags: solver capabilities, `-s` vocabulary, the FMU flag
//! vocabulary (`fmuAcceptsFlag`, CS solvers, platforms), simflags parsing.

use super::*;

// Runs the model and returns its captured stdout/stderr (the model's runtime
// output — Modelica `Streams.print`, `ModelicaMessage`, …) alongside the result.
// Capturing keeps that output out of the process stdout (the browser console on
// the web target) so the caller can fold it into the simulation log.
/// Whether the driver that will run the model has CVODE and IDA: the host one links
/// the native archives, the in-wasm one (always, on the web) the wasm archives in the
/// runtime blob.
const SUNDIALS_DRIVER: bool =
    openmodelica_sim_meta::IDA || (cfg!(target_arch = "wasm32") && openmodelica_wasm_jit::SUNDIALS);

/// What the wasm-jit runtimes can serve, for `simflags::check`. Checked at the host
/// parse, where a rejection still has a message channel to report on.
const CAPABILITIES: simflags::Capabilities = simflags::Capabilities {
    klu: openmodelica_wasm_jit::SUNDIALS,
    kinsol: openmodelica_wasm_jit::SUNDIALS,
    umfpack: openmodelica_wasm_jit::SUNDIALS,
    lis: openmodelica_wasm_jit::SUNDIALS,
    ida: SUNDIALS_DRIVER,
    cvode: SUNDIALS_DRIVER,
    // Served by the driver's per-step deadline, so every engine has it.
    alarm: true,
    // The `.mat` is written here, where a regex engine is available.
    variable_filter: true,
    // `optimize()`'s solver: the host-driven driver's Ipopt.
    optimization: openmodelica_sim_meta::optimization::AVAILABLE,
    // A `simulate()` run drives the whole trajectory, which is all QSS can do.
    qss: true,
};

/// The solver values a caller may offer for this build, so a menu built from it
/// cannot disagree with [`install_sim_flags`]'s check.
pub fn solver_options() -> Vec<(&'static str, Vec<&'static str>)> {
    simflags::supported(CAPABILITIES)
}

/// What an exported wasm FMU *could* serve: every solver, each a PIC side module the
/// FMU linker adds beside the model. What a given FMU carries is narrower —
/// [`fmu_solver_libraries`] picks from the flags it was exported with.
fn fmu_capabilities() -> simflags::Capabilities {
    simflags::Capabilities {
        klu: sundials_available(),
        kinsol: sundials_available(),
        umfpack: sundials_available(),
        lis: sundials_available(),
        ida: sundials_available(),
        cvode: sundials_available(),
        // The driver's per-step deadline comes along; a regex engine does not.
        alarm: true,
        variable_filter: false,
        // An FMU has no notion of an optimization problem.
        optimization: false,
        // A Co-Simulation FMU steps to communication points; QSS cannot be stepped.
        qss: false,
    }
}

/// Whether an FMU exported with `method` needs the SUNDIALS side module.
fn fmu_needs_sundials(method: &str) -> bool {
    matches!(method, "cvode" | "ida")
}

/// The simulation flags to hard-code into an FMU's metadata: the export's
/// `_flags.json` but `-s`, which [`SimMeta::cs_method`] carries. An importer has no
/// channel to pass simulation flags, so the FMU applies these when it instantiates.
/// `--fmiFlags` takes any name; like C's `parseFlags`, ignore what this FMU cannot
/// honour — `createFMISimulationFlags` has already warned about the name.
pub(super) fn fmu_solver_flags(flags_json: &str) -> String {
    fmi_flags(flags_json)
        .into_iter()
        .filter(|(name, _)| name != "s")
        .filter(|(name, value)| fmu_accepts_flag(name, value))
        .map(|(name, value)| if value.is_empty() { format!("-{name}") } else { format!("-{name}={value}") })
        .collect::<Vec<_>>()
        .join(" ")
}

/// `CodegenWasmJit.fmuAcceptsFlag`: whether a wasm FMU can honour `-name=value`
/// (an empty value for a flag that takes none). One it cannot is better dropped
/// where it comes from than baked into `_flags.json`, where it would only
/// surface at the importer's `instantiate`.
pub fn fmuAcceptsFlag(name: ArcStr, value: ArcStr) -> bool {
    fmu_accepts_flag(name.as_str(), value.as_str())
}

/// Flags the importer owns: it sets start values through `fmi3Set*` and decides
/// when the co-simulation ends. `-variableFilter` is refused by [`fmu_capabilities`].
const IMPORTER_FLAGS: &[&str] = &["override", "overrideFile", "steadyState", "steadyStateTol"];

fn fmu_accepts_flag(name: &str, value: &str) -> bool {
    if name == "s" {
        // Baked into the component rather than parsed at instantiation, so only
        // what it linked can serve it.
        return fmu_cs_solvers().contains(&value);
    }
    if IMPORTER_FLAGS.contains(&name) {
        return false;
    }
    let arg = if value.is_empty() { format!("-{name}") } else { format!("-{name}={value}") };
    match simflags::parse(&["model".to_string(), arg]) {
        Ok(f) => simflags::check(&f, fmu_capabilities()).is_ok(),
        Err(_) => false,
    }
}

/// Every `"name" : "value"` pair of a `_flags.json`, in file order.
fn fmi_flags(json: &str) -> Vec<(String, String)> {
    let mut out = Vec::new();
    let mut rest = json;
    while let Some(start) = rest.find('"') {
        let Some(len) = rest[start + 1..].find('"') else { break };
        let name = &rest[start + 1..start + 1 + len];
        let after = rest[start + 1 + len + 1..].trim_start();
        let Some(value_part) = after.strip_prefix(':').map(str::trim_start).and_then(|a| a.strip_prefix('"')) else {
            rest = &rest[start + 1 + len + 1..];
            continue;
        };
        let Some(vlen) = value_part.find('"') else { break };
        out.push((name.to_string(), value_part[..vlen].to_string()));
        rest = &value_part[vlen + 1..];
    }
    out
}

/// Which solver libraries an FMU exported with these `--fmiFlags` and this
/// Co-Simulation method can reach; the rest are linked as stubs. Both are fixed
/// at export, so this is the whole set the FMU will ever select from. `klu` comes
/// along with any of the others: the shared SUNDIALS core they call into, and
/// IDA's default linear solver.
///
/// `cs` gates only the integrator: Model Exchange never integrates, but its
/// initialisation and residuals run the same nonlinear and linear solvers.
///
/// `sparse_nls` is the one selection no flag records: C's density/size rule sends a
/// large sparse nonlinear system to kinsol+KLU whatever the flags say, so a model
/// carrying one needs both however it was exported.
pub(super) fn fmu_solver_libraries(
    flags_json: &str,
    cs_method: &str,
    cs: bool,
    sparse_nls: bool,
) -> Vec<&'static str> {
    let flag = |name: &str| fmi_flag(flags_json, name).unwrap_or_default();
    let (nls, ls, lss) = (flag("nls"), flag("ls"), flag("lss"));
    let named = |v: &str| ls == v || lss == v;
    let mut wanted = Vec::new();
    if cs && fmu_needs_sundials(cs_method) {
        wanted.push("sundials_driver");
    }
    if sparse_nls || matches!(nls.as_str(), "kinsol" | "experimental-kinsol") {
        wanted.push("kinsol");
    }
    if named("umfpack") {
        wanted.push("umfpack");
    }
    if named("lis") {
        wanted.push("lis");
    }
    if !wanted.is_empty() || named("klu") || flag("nlsLS") == "klu" || (cs && flag("idaLS") == "klu")
    {
        wanted.push("klu");
    }
    wanted
}

/// The `method=` values `buildModelFMU` accepts for a `cs`/`me_cs` wasm FMU.
pub fn fmu_cs_solvers() -> Vec<&'static str> {
    simflags::supported(fmu_capabilities())
        .into_iter()
        .find(|(flag, _)| *flag == "s")
        .map(|(_, v)| v)
        .unwrap_or_default()
}

/// `CodegenWasmJit.fmuCsSolvers`: [`fmu_cs_solvers`] for the MetaModelica side,
/// which folds an accepted `method=` into the FMU's `_flags.json`.
pub fn fmuCsSolvers() -> List<ArcStr> {
    fmu_cs_solvers().into_iter().map(ArcStr::from).collect()
}

/// The `platforms=` values `buildModelFMU` can serve besides `"wasm"`: those this
/// omc has a loader library for.
pub fn fmu_platforms() -> Vec<String> {
    native_fmu::available()
}

/// Parse `simflags` as an argv and install the result for this run. omc hands the
/// flags over as one string, which for every other target a shell splits into the
/// executable's argv; `argv[0]` stands in for the program name a WASI command would
/// see, so the same parser serves this path and a standalone `wasmtime model.wasm …`
/// run.
pub(super) fn install_sim_flags(simflags: &str) -> std::result::Result<simflags::SimFlags, String> {
    let argv: Vec<String> = core::iter::once("model".to_string()).chain(split_simflags(simflags)).collect();
    let f = simflags::parse(&argv)?;
    simflags::check(&f, CAPABILITIES)?;
    simflags::set_flags(f.clone());
    Ok(f)
}

/// Split `simflags` as the shell splits `CevalScriptBackend`'s `sim_call` for every
/// other target: on whitespace outside quotes, `'…'`/`"…"` removed.
pub(super) fn split_simflags(s: &str) -> Vec<String> {
    let mut out = Vec::new();
    let mut cur = String::new();
    let mut quote: Option<char> = None;
    let mut started = false;
    for c in s.chars() {
        match (quote, c) {
            (Some(q), c) if c == q => quote = None,
            (Some(_), c) => cur.push(c),
            (None, '\'' | '"') => {
                quote = Some(c);
                started = true;
            }
            (None, c) if c.is_whitespace() => {
                if started {
                    out.push(core::mem::take(&mut cur));
                    started = false;
                }
            }
            (None, c) => {
                cur.push(c);
                started = true;
            }
        }
    }
    if started {
        out.push(cur);
    }
    out
}

/// This run's scalars, and what `read_experiment` printed getting them — captured
/// separately because C prints it ahead of every other startup notice.
pub(super) fn run_experiment(model: &SimModel, flags: &simflags::SimFlags) -> (SimMeta, String) {
    openmodelica_wasi::wasi::start_stdout_capture();
    let meta = model.meta.with_flags(flags);
    (meta, openmodelica_wasi::wasi::take_stdout_capture())
}
