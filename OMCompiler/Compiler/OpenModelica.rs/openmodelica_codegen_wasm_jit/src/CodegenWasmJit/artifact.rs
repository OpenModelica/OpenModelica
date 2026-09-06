//! Simulating a **wasm artifact**: what one wasm FMU export produces and three
//! ways of running it.
//!
//! `buildModelFMU(M, fmuType="me_cs", version="3.0")` under
//! `--simCodeTarget=wasm-jit` writes `M.fmu`; `simulate(M,
//! resimulateExecutable="M.fmu", simflags=…)` runs it here, without translating
//! the model again:
//!
//! | `-s` | what runs |
//! | --- | --- |
//! | absent, or an ordinary solver | the artifact's own simulation runtime, in wasm |
//! | `fmi3:me[:solver]` | Model Exchange, this process integrating (DASKR by default; with `-daeMode`, IDA over the FMU's fmi-ls-dae residuals) |
//! | `fmi3:cs` | Co-Simulation, the artifact integrating itself |
//!
//! The export takes one of two forms. `--fmuDirectory` writes the model kernel
//! alone, unzipped, and the host links it against an adapter it compiled once
//! ([`super::dylink_fmi`]) — what the library testing uses. Otherwise it is an
//! fmi-ls-wasm component, which any FMI tool can also open. Every phase is timed
//! and reported in the run's log; `HANDOFF-wasm-artifact.md` has the numbers.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::{Arc, LazyLock, Mutex};
use std::time::Instant;

use openmodelica_fmi::{Fmu, InterfaceKind};
use openmodelica_fmi_driver::api::Fmi3;
use openmodelica_fmi_driver::component::WasmArtifact;
use openmodelica_fmi_driver::{cs, me, Options, Solver};
use openmodelica_wasm_jit::sim_runtime::ArtifactLib;

use super::dylink_fmi::DylinkInstance;

use super::{split_simflags, write_output};

/// Artifacts this omc has already compiled, by where they were written.
///
/// The export compiles the component to machine code; a run in the same session
/// would otherwise write that out, read it back and relocate it for nothing.
/// Keyed by path, so a re-export of the same name replaces it.
static COMPILED: LazyLock<Mutex<HashMap<PathBuf, Arc<WasmArtifact>>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

/// An absolute key for `path`, resolvable *before* it exists: the export
/// remembers what it compiled under the name it is about to write, and the run
/// that follows looks it up under the name it now finds.
fn canonical(path: &Path) -> PathBuf {
    let Some(name) = path.file_name() else { return path.to_path_buf() };
    let parent = match path.parent() {
        Some(p) if !p.as_os_str().is_empty() => p.to_path_buf(),
        _ => PathBuf::from("."),
    };
    std::fs::canonicalize(parent).map(|d| d.join(name)).unwrap_or_else(|_| path.to_path_buf())
}

pub fn remember(path: &Path, artifact: Arc<WasmArtifact>) {
    COMPILED.lock().unwrap_or_else(|e| e.into_inner()).insert(canonical(path), artifact);
}

fn recall(path: &Path) -> Option<Arc<WasmArtifact>> {
    COMPILED.lock().unwrap_or_else(|e| e.into_inner()).get(&canonical(path)).cloned()
}

/// Which of the artifact's three faces a run asked for.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Face {
    Simulation,
    /// The integrator named after `fmi3:me:`; `None` leaves the choice to the mode.
    ModelExchange(Option<Solver>),
    CoSimulation,
}

/// Read `-s fmi3:…` out of the flag list. Returns the face and the flags with
/// the selector removed, since `simflags::parse` knows nothing about it.
///
/// Both spellings C accepts are: `-s=<v>` and `-s <v>`.
pub fn select_face(simflags: &str) -> std::result::Result<(Face, String), String> {
    let args = split_simflags(simflags);
    let mut out: Vec<String> = Vec::with_capacity(args.len());
    let mut face = Face::Simulation;
    let mut i = 0;
    while i < args.len() {
        let a = &args[i];
        let value = if let Some(v) = a.strip_prefix("-s=") {
            Some(v.to_string())
        } else if a == "-s" && i + 1 < args.len() {
            Some(args[i + 1].clone())
        } else {
            None
        };
        match value {
            Some(v) if v.starts_with("fmi3:") => {
                face = parse_face(&v)?;
                i += if a == "-s" { 2 } else { 1 };
                continue;
            }
            _ => {}
        }
        out.push(a.clone());
        i += 1;
    }
    Ok((face, out.join(" ")))
}

fn parse_face(v: &str) -> std::result::Result<Face, String> {
    let mut parts = v.split(':');
    parts.next(); // "fmi3"
    let kind = parts.next().unwrap_or("");
    let solver = parts.next().unwrap_or("");
    let unknown = |what: &str, name: &str| {
        format!(
            "wasm artifact: `-s {v}` names no interface this artifact serves: {what} `{name}`. \
             Use `fmi3:me[:<solver>]`, `fmi3:cs`, or a plain `-s=<solver>` for the artifact's own \
             simulation runtime."
        )
    };
    match kind {
        "me" => {
            let s = match solver {
                "" => None,
                // DASKR is the BDF integrator behind `-s=dassl`; both names reach it.
                "daskr" | "dassl" => Some(Solver::Dassl),
                name => Some(Solver::parse(name).ok_or_else(|| unknown("solver", name))?),
            };
            Ok(Face::ModelExchange(s))
        }
        // The FMU's own integrator is chosen when it is exported (`--fmiFlags=s:…`),
        // not here; naming it is allowed so the two spellings read alike.
        "cs" => Ok(Face::CoSimulation),
        name => Err(unknown("interface", name)),
    }
}

/// The artifact `resimulateExecutable` names, if it names one: a `.fmu`, zipped
/// or (`--fmuDirectory`) unzipped. It has to say `.fmu` outright — a bare prefix
/// is a model this session translated, and a leftover export of the same name
/// must not take a run away from it.
pub fn locate(prefix: &str) -> Option<PathBuf> {
    let path = Path::new(prefix);
    (path.extension().is_some_and(|e| e == "fmu") && path.exists()).then(|| path.to_path_buf())
}

/// The model this session translated for the export at `path`, when the run asks
/// for the artifact's own simulation: the ordinary simulation path runs it, with
/// the solvers and the `external "C"` ladder the runtime inside the artifact lacks.
pub fn translated(path: &Path, simflags: &str) -> Option<String> {
    if !matches!(select_face(simflags), Ok((Face::Simulation, _))) {
        return None;
    }
    let prefix = path.file_stem()?.to_str()?.to_string();
    super::sim_models().lock().unwrap_or_else(|e| e.into_inner()).contains_key(&prefix).then_some(prefix)
}

/// The result name `simulate` derived from `resimulateExecutable` (`M.fmu_res.mat`),
/// with the artifact's own extension taken out of it.
pub fn plain_result_name(derived: &str) -> String {
    derived.replace(".fmu_res.", "_res.")
}

/// Where the result goes: `-r=` outright, else what `simulate` derived.
fn result_path(flags: &openmodelica_sim_meta::simflags::SimFlags, derived: &str) -> String {
    if let Some(r) = &flags.result_file {
        return r.clone();
    }
    let cleaned = plain_result_name(derived);
    match &flags.output_path {
        Some(dir) => format!("{dir}/{}", Path::new(&cleaned).file_name().unwrap_or_default().to_string_lossy()),
        None => cleaned,
    }
}

/// Which form the export took: a component this omc instantiates, or a model
/// kernel it links against the adapter itself.
enum Form {
    Component(Arc<WasmArtifact>),
    Dylink { model: Vec<u8>, ext: Vec<ArtifactLib>, external_c: bool, lapack: bool },
}

struct Loaded {
    /// Where the artifact's files are: itself when it was exported unzipped, the
    /// directory it was unpacked into otherwise.
    dir: PathBuf,
    form: Form,
    how: String,
    load_ms: f64,
}

thread_local! {
    /// The linked artifact this omc has standing, and where it came from.
    ///
    /// Linking is a relocation pass over the adapter and the model's libraries,
    /// proportional to their size — 75 ms for the adapter alone, 660 ms with
    /// `Modelica.Utilities`' tables. The three runs of one artifact are three
    /// `simulate` calls in one omc, so they share it: the FMI instance is freed
    /// and made again between them, which is what `fmi3FreeInstance` is for.
    static LINKED: std::cell::RefCell<Option<(PathBuf, DylinkInstance)>> =
        const { std::cell::RefCell::new(None) };
}

impl Loaded {
        fn resources(&self) -> String {
        let r = self.dir.join("resources");
        if r.is_dir() { r.to_string_lossy().into_owned() } else { "/".to_string() }
    }

    /// Run `f` against the linked artifact, standing or newly linked. The adapter
    /// it links against is a fixed library, so linking compiles only the model.
    fn with_dylink<R>(
        &self,
        f: impl FnOnce(&mut DylinkInstance) -> std::result::Result<R, String>,
    ) -> std::result::Result<R, String> {
        let Form::Dylink { model, ext, external_c, lapack } = &self.form else {
            return Err("wasm artifact: not a linkable artifact".to_string());
        };
        let standing = LINKED.with(|c| {
            let mut c = c.borrow_mut();
            match &*c {
                Some((p, _)) if *p == self.dir => c.take().map(|(_, i)| i),
                _ => None,
            }
        });
        let mut inst = match standing {
            Some(mut i) => {
                // A run of its own: the previous one's FMI instance goes first.
                i.free_instance();
                i
            }
            None => DylinkInstance::load(model, ext, *external_c, *lapack, &self.resources())
                .map_err(|e| e.to_string())?,
        };
        let out = f(&mut inst);
        LINKED.with(|c| *c.borrow_mut() = Some((self.dir.clone(), inst)));
        out
    }
}

impl Loaded {
    /// The model description, which only the FMI interfaces need — and which is
    /// megabytes of XML for a big model, so the artifact's own runtime never
    /// parses it.
    fn model_description(&self) -> std::result::Result<Fmu, String> {
        Fmu::from_dir(&self.dir).map_err(|e| format!("wasm artifact {}: {e}", self.dir.display()))
    }
}

/// The FMI platform tuple naming the `.cwasm` this machine can deserialize.
fn platform() -> Option<&'static str> {
    super::native_fmu::host_platform().map(|p| p.fmi)
}

/// Load the artifact out of a directory of files.
///
/// That is what makes a run cheap: `Component::deserialize_file` **maps** the
/// `.cwasm` instead of reading it, and nothing is inflated. An export written
/// with `--fmuDirectory` already is such a directory and is used where it lies;
/// a zipped one is unpacked beside itself once, since inflating a ten-megabyte
/// `.cwasm` per run is most of what a short simulation would otherwise cost.
fn load(path: &Path) -> std::result::Result<Loaded, String> {
    let t = Instant::now();
    if let Some(artifact) = recall(path) {
        // Compiled before it was packed; its files are read from the unpacked copy.
        let dir = if path.is_dir() {
            path.to_path_buf()
        } else {
            let dir = unpacked_dir(path);
            unpack(path, &dir)?;
            let resources = dir.join("resources");
            if resources.is_dir() {
                artifact.use_resources(&resources);
            }
            dir
        };
        return Ok(Loaded {
            dir,
            form: Form::Component(artifact),
            how: "compiled by this omc".to_string(),
            load_ms: ms(t),
        });
    }
    let (dir, unpacked) = if path.is_dir() {
        (path.to_path_buf(), false)
    } else {
        let dir = unpacked_dir(path);
        let unpacked = unpack(path, &dir)?;
        (dir, unpacked)
    };
    // The linkable form: the model kernel alone, which this omc links against the
    // adapter it has already compiled. Nothing here is compiled but the model.
    if let Some(model) = dylink_model(&dir) {
        let manifest = std::fs::read_to_string(dir.join("resources/artifact.json")).unwrap_or_default();
        let flag = |k: &str| manifest.contains(&format!("\"{k}\": true"));
        let mut ext = Vec::new();
        if let Ok(rd) = std::fs::read_dir(dir.join("resources/ext")) {
            let mut paths: Vec<PathBuf> = rd.flatten().map(|e| e.path()).collect();
            paths.sort();
            for p in paths {
                let name = p.file_stem().map(|s| s.to_string_lossy().into_owned()).unwrap_or_default();
                if let Ok(bytes) = std::fs::read(&p) {
                    let fixed = name != super::NATIVE_STUB;
                    ext.push(ArtifactLib { name, bytes, fixed });
                }
            }
        }
        let size = model.len();
        return Ok(Loaded {
            dir,
            form: Form::Dylink { model, ext, external_c: flag("externalC"), lapack: flag("lapack") },
            how: format!(
                "model kernel linked against the cached adapter{}{}",
                mb(size as u64),
                if unpacked { ", unpacked here" } else { "" }
            ),
            load_ms: ms(t),
        });
    }
    // What `Modelica.Utilities.Files.loadResource` and a file-backed table read
    // through: the component sees this directory as its own root.
    let resources = dir.join("resources");
    let resources = resources.is_dir().then_some(resources);
    // Beside the platform's loader; `resources/<platform>.cwasm` in older exports.
    let cwasm = openmodelica_ext_native::binaries_dir(&dir)
        .and_then(|d| std::fs::read_dir(d).ok())
        .and_then(|rd| rd.flatten().map(|e| e.path()).find(|p| p.extension().is_some_and(|e| e == "cwasm")))
        .or_else(|| platform().map(|p| dir.join(format!("resources/{p}.cwasm"))).filter(|p| p.is_file()));
    // A `.cwasm` is tied to one wasmtime build and one engine configuration; if
    // this omc is not the one that wrote it, compiling the component still works.
    if let Some(cwasm) = &cwasm {
        // Safety: the artifact was written by an OpenModelica export; a mismatch is
        // rejected by wasmtime rather than trusted.
        if let Ok(artifact) = unsafe { WasmArtifact::from_cwasm_file(cwasm, resources.as_deref()) } {
            let size = std::fs::metadata(cwasm).map(|m| m.len()).unwrap_or(0);
            return Ok(Loaded {
                form: Form::Component(Arc::new(artifact)),
                how: format!(
                    "{}.cwasm{}, mapped{}",
                    platform().unwrap_or("?"),
                    mb(size),
                    if unpacked { ", unpacked here" } else { "" }
                ),
                load_ms: ms(t),
                dir,
            });
        }
    }
    let fmu = Fmu::from_dir(&dir).map_err(|e| format!("wasm artifact {}: {e}", dir.display()))?;
    let component = component_bytes(&fmu).ok_or_else(|| {
        format!(
            "wasm artifact {}: no artifact this omc can load. It carries no {} and no wasm \
             component to compile one from; export it again with this omc.",
            path.display(),
            cwasm.map(|p| p.display().to_string()).unwrap_or_else(|| "*.cwasm".to_string())
        )
    })?;
    let artifact = WasmArtifact::compile(&component, resources.as_deref())
        .map_err(|e| format!("wasm artifact {}: {e}", path.display()))?;
    Ok(Loaded {
        form: Form::Component(Arc::new(artifact)),
        how: format!("compiled from the component{}", mb(component.len() as u64)),
        load_ms: ms(t),
        dir,
    })
}

fn dylink_model(dir: &Path) -> Option<Vec<u8>> {
    let d = dir.join(super::DYLINK_DIR);
    let entry = std::fs::read_dir(d).ok()?.flatten().map(|e| e.path()).find(|p| p.extension().is_some_and(|e| e == "wasm"))?;
    std::fs::read(entry).ok()
}

/// Where the artifact is unpacked, beside itself so a second run finds it there.
fn unpacked_dir(path: &Path) -> PathBuf {
    let stem = path.file_stem().map(|s| s.to_string_lossy().into_owned()).unwrap_or_default();
    path.with_file_name(format!("{stem}_artifact"))
}

/// Unpack the archive into `dir` unless a previous run already did. Returns
/// whether this call was the one that unpacked it.
fn unpack(path: &Path, dir: &Path) -> std::result::Result<bool, String> {
    let stamp = dir.join(".unpacked");
    let exported = std::fs::metadata(path).and_then(|m| m.modified()).ok();
    let ours = std::fs::metadata(&stamp).and_then(|m| m.modified()).ok();
    if let (Some(exported), Some(ours)) = (exported, ours)
        && ours >= exported
    {
        return Ok(false);
    }
    let fmu = Fmu::from_path(path).map_err(|e| format!("wasm artifact {}: {e}", path.display()))?;
    let io = |e: std::io::Error| format!("wasm artifact {}: {e}", dir.display());
    for name in fmu.names().to_vec() {
        let Some(data) = fmu.read(&name) else { continue };
        let out = dir.join(&name);
        if let Some(parent) = out.parent() {
            std::fs::create_dir_all(parent).map_err(io)?;
        }
        std::fs::write(&out, &*data).map_err(io)?;
    }
    std::fs::write(&stamp, b"").map_err(io)?;
    Ok(true)
}

fn component_bytes(fmu: &Fmu) -> Option<Vec<u8>> {
    let name = fmu
        .names()
        .iter()
        .find(|n| n.starts_with("binaries/wasm32-wasip2/") && n.ends_with(".wasm"))
        .or_else(|| fmu.names().iter().find(|n| n.starts_with("resources/") && n.ends_with(".wasm")))?
        .clone();
    fmu.read(&name).map(|b| b.into_owned())
}

fn ms(t: Instant) -> f64 {
    t.elapsed().as_secs_f64() * 1.0e3
}

/// Run `path` the way `face` says, writing the result file and returning the log
/// the caller puts in `<prefix>.log`.
pub fn run(
    path: &Path,
    face: Face,
    result_file: &str,
    simflags: &str,
) -> (std::result::Result<(), String>, String) {
    let mut log = String::new();
    let loaded = match load(path) {
        Ok(l) => l,
        Err(e) => return (Err(e), log),
    };
    log.push_str(&format!(
        "LOG_STDOUT        | info    | wasm artifact loaded{} ({})\n",
        took(loaded.load_ms),
        loaded.how
    ));
    let flags = match super::install_sim_flags(simflags) {
        Ok(f) => f,
        Err(e) => return (Err(e), log),
    };
    // Neither the in-wasm runtime nor the FMI driver has a regex engine, so the
    // pattern is compiled here: the runtime asks per name through
    // `rt_host_name_matches`, the masters filter their columns. `Regex` is not
    // `Clone`, hence one compile per consumer.
    openmodelica_wasm_jit::host::set_output_filter(compile_output_filter(&flags, &mut log));
    let out = result_path(&flags, result_file);
    let res = match face {
        Face::Simulation => run_simulation(&loaded, &flags, &out, simflags, &mut log),
        Face::ModelExchange(solver) => {
            let solver = match (solver, flags.dae_mode) {
                (None, false) => Solver::Dassl,
                (None, true) | (Some(Solver::Ida), true) => Solver::Ida,
                (Some(s), false) => s,
                (Some(s), true) => {
                    return (
                        Err(format!(
                            "wasm artifact: -daeMode integrates with IDA; `-s fmi3:me:{}` cannot serve a residual form",
                            s.as_str()
                        )),
                        log,
                    )
                }
            };
            run_fmi(&loaded, &flags, &out, Some(solver), &mut log)
        }
        Face::CoSimulation => run_fmi(&loaded, &flags, &out, None, &mut log),
    };
    (res, log)
}

/// The run's `-variableFilter`, compiled. `None` keeps everything: an absent,
/// empty or `.*` pattern, or C's "Defaulting to outputting all variables".
fn compile_output_filter(
    flags: &openmodelica_sim_meta::simflags::SimFlags,
    log: &mut String,
) -> Option<openmodelica_util::System::Regex> {
    let pattern = flags.variable_filter.as_deref().filter(|p| !p.is_empty() && *p != ".*")?;
    match openmodelica_util::System::Regex::new(&format!("^({pattern})$")) {
        Ok(re) => Some(re),
        Err(e) => {
            log.push_str(&format!(
                "LOG_STDOUT        | warning | Failed to compile regular expression: {pattern} \
                 with error: {e}. Defaulting to outputting all variables.\n"
            ));
            None
        }
    }
}

/// The artifact's own simulation runtime.
fn run_simulation(
    loaded: &Loaded,
    flags: &openmodelica_sim_meta::simflags::SimFlags,
    out: &str,
    simflags: &str,
    log: &mut String,
) -> std::result::Result<(), String> {
    let args = split_simflags(simflags);
    let t = Instant::now();
    let run = match &loaded.form {
        Form::Component(a) => {
            let r = a.run_simulation(&args).map_err(|e| e.to_string())?;
            log.push_str(&r.output);
            for (_, category, message) in &r.log {
                log.push_str(&format!("LOG_STDOUT        | info    | {category}: {message}\n"));
            }
            super::dylink_fmi::SimRun {
                file: r.file,
                linear_file: r.linear_file,
                prof_files: r.prof_files,
                prof_html: r.prof_html,
                rows: r.rows,
                solver: r.solver,
            }
        }
        Form::Dylink { .. } => {
            // The model's `LOG_*`/asserts/`Streams.print` go to the artifact's
            // WASI stdout; fold them into the run's log as the other forms do.
            openmodelica_wasi::wasi::start_stdout_capture();
            let r = loaded.with_dylink(|i| i.run_simulation(&args).map_err(|e| e.to_string()));
            log.push_str(&openmodelica_wasi::wasi::take_stdout_capture());
            r?
        }
    };
    let elapsed = ms(t);
    log.push_str(&format!(
        "LOG_STDOUT        | info    | in-wasm simulation ({}) wrote {} rows{}\n",
        run.solver,
        run.rows,
        took(elapsed)
    ));
    if let Some((name, content)) = &run.linear_file {
        let path = match &flags.output_path {
            Some(dir) => format!("{dir}/{name}"),
            None => name.clone(),
        };
        write_output(&path, content.as_bytes()).map_err(|e| format!("cannot write {path}: {e}"))?;
    }
    place_prof_files(&run, log);
    if run.file.is_empty() {
        return Ok(());
    }
    write_output(out, &run.file).map_err(|e| format!("cannot write {out}: {e}"))
}

/// `+profiling`'s report: the run generated the five files inside the artifact
/// (their names already carry `-outputPath`, as C's do), so they only need placing
/// here — and `gnuplot` and `xsltproc` running over them for `blocks+html`, which
/// a wasm module cannot do itself.
fn place_prof_files(run: &super::dylink_fmi::SimRun, log: &mut String) {
    let mut prefix = String::new();
    for (name, content) in &run.prof_files {
        if let Err(e) = write_output(name, content) {
            log.push_str(&format!("LOG_STDOUT        | warning | cannot write {name}: {e}\n"));
            return;
        }
        if let Some(p) = name.strip_suffix("_prof.xml") {
            prefix = p.to_string();
        }
    }
    if prefix.is_empty() || !run.prof_html {
        return;
    }
    let cmd = format!("gnuplot {prefix}_prof.plt");
    if !run_shell(&cmd) {
        log.push_str(&format!("LOG_STDOUT        | warning | Plot command failed: {cmd}\n"));
    }
    let failure = match openmodelica_util::Settings::getInstallationDirectoryPath() {
        Ok(home) => {
            let xsl = format!("{home}/share/omc/scripts/default_profiling.xsl");
            let cmd = format!("xsltproc -o {prefix}_prof.html {xsl} {prefix}_prof.xml");
            (!run_shell(&cmd)).then_some(cmd)
        }
        Err(_) => Some("OPENMODELICAHOME missing".to_string()),
    };
    if let Some(cmd) = failure {
        log.push_str(&format!(
            "LOG_STDOUT        | warning | Failed to generate html version of profiling results: {cmd}\n"
        ));
    }
}

/// C's `system(cmd)`, for the two commands above. The wasm omc build has no
/// processes to run, so the plots stay undrawn there — as they do for the C target
/// on a machine without gnuplot.
fn run_shell(cmd: &str) -> bool {
    #[cfg(not(target_arch = "wasm32"))]
    {
        std::process::Command::new("sh").arg("-c").arg(cmd).status().map(|s| s.success()).unwrap_or(false)
    }
    #[cfg(target_arch = "wasm32")]
    {
        let _ = cmd;
        false
    }
}

/// Model Exchange (this process integrates) or Co-Simulation (the FMU does).
fn run_fmi(
    loaded: &Loaded,
    flags: &openmodelica_sim_meta::simflags::SimFlags,
    out: &str,
    me_solver: Option<Solver>,
    log: &mut String,
) -> std::result::Result<(), String> {
    let fmu = loaded.model_description()?;
    let md = &fmu.model_description;
    let kind =
        if me_solver.is_some() { InterfaceKind::ModelExchange } else { InterfaceKind::CoSimulation };
    if md.interface(kind).is_none() {
        return Err(format!(
            "wasm artifact: it has no {} interface; export it with fmuType=\"me_cs\"",
            kind.as_str()
        ));
    }
    let mut opts = Options::from_model_description(md);
    // C's `read_experiment`: the run's flags win over what the export baked in.
    if let Some(v) = flags.start_time {
        opts.start_time = v;
    }
    if let Some(v) = flags.stop_time {
        opts.stop_time = v;
    }
    if let Some(v) = flags.tolerance {
        opts.tolerance = Some(v);
    }
    if let Some(v) = flags.step_size.filter(|h| *h > 0.0) {
        opts.step_size = v;
    }
    // The FMU's own `FILTERED_LOG` categories, which are not the `-lv` streams:
    // `-lv=LOG_STATS` asks the *runtime* for a block, not the FMU for a trace of
    // every event, so it alone leaves the FMI logger off.
    opts.logging_on = flags.has_log("LOG_EVENTS") || flags.has_log("LOG_NLS") || flags.has_log("LOG_DSS");
    opts.log_streams = flags.log.clone();
    opts.alarm = flags.alarm;
    // A run wedged inside one call into wasm never reaches the master's deadline;
    // the epoch alarm interrupts that (`OMC_WASM_HARD_ALARM`).
    openmodelica_wasm_jit::sim_runtime::set_alarm(flags.alarm);
    if let Some(s) = me_solver {
        opts.solver = s;
        if flags.dae_mode {
            opts.dae = Some(match fmu.ls_dae_manifest() {
                Some(Ok(m)) => m,
                Some(Err(e)) => return Err(format!("wasm artifact: fmi-ls-dae manifest: {e}")),
                None => {
                    return Err(
                        "wasm artifact: -daeMode asks for fmi-ls-dae, which this FMU does not declare \
                         (export the model with --daeMode)"
                            .to_string(),
                    )
                }
            });
        }
    }
    // C's `doOverride`, as far as FMI reaches: a parameter is settable in
    // Initialization Mode and nothing else is.
    for (name, value) in &flags.overrides {
        if matches!(name.as_str(), "startTime" | "stopTime" | "stepSize" | "tolerance") {
            continue;
        }
        let Some(v) = md.variables.iter().find(|v| v.name == *name) else {
            return Err(format!("wasm artifact: -override names no variable `{name}`"));
        };
        let Ok(value) = value.parse::<f64>() else {
            return Err(format!("wasm artifact: -override={name}={value} is not a number"));
        };
        opts.parameters.push(openmodelica_fmi_driver::Parameter {
            value_reference: v.value_reference,
            ty: v.ty,
            value,
        });
    }

    // The masters record here, so the columns the filter rejects are never sampled.
    let re = compile_output_filter(flags, &mut String::new());
    let keep = |name: &str| re.as_ref().is_none_or(|r| r.is_match(name));
    if re.is_some() {
        opts.keep = Some(&keep);
    }
    let t = Instant::now();
    let (recorder, summary, elapsed) = match &loaded.form {
        Form::Component(a) => {
            let mut inst = match kind {
                InterfaceKind::ModelExchange => a.model_exchange(&instance_name(md), opts.logging_on),
                _ => a.co_simulation(&instance_name(md), opts.logging_on, opts.event_mode),
            }
            .map_err(|e| e.to_string())?;
            log.push_str(&format!(
                "LOG_STDOUT        | info    | {} instantiated{}\n",
                kind.as_str(),
                took(ms(t))
            ));
            let t = Instant::now();
            // Drained before the failure propagates: what the FMU printed on the
            // way to it is the only account of why.
            let driven = drive(&mut inst, kind, md, &opts);
            let elapsed = ms(t);
            log.push_str(&inst.output());
            for (_, category, message) in inst.take_log() {
                log.push_str(&format!("LOG_STDOUT        | info    | {category}: {message}\n"));
            }
            let (r, s) = driven?;
            (r, s, elapsed)
        }
        Form::Dylink { .. } => {
            let mut linked_ms = 0.0;
            openmodelica_wasi::wasi::start_stdout_capture();
            let driven = loaded.with_dylink(|inst| {
                match kind {
                    InterfaceKind::ModelExchange => inst.instantiate_me(&instance_name(md), opts.logging_on),
                    _ => inst.instantiate_cs(&instance_name(md), opts.logging_on, opts.event_mode),
                }
                .map_err(|e| e.to_string())?;
                linked_ms = ms(t);
                let t = Instant::now();
                let (r, s) = drive(inst, kind, md, &opts)?;
                Ok((r, s, ms(t)))
            });
            log.push_str(&openmodelica_wasi::wasi::take_stdout_capture());
            let (r, s, e) = driven?;
            log.push_str(&format!(
                "LOG_STDOUT        | info    | {} instantiated{}\n",
                kind.as_str(),
                took(linked_ms)
            ));
            (r, s, e)
        }
    };
    log.push_str(&format!(
        "LOG_STDOUT        | info    | {} run: {summary}, {} samples{}\n",
        kind.as_str(),
        recorder.len(),
        took(elapsed)
    ));
    if flags.noemit || flags.output_format.as_deref() == Some("empty") {
        return Ok(());
    }
    recorder
        .write(Path::new(out), opts.start_time, opts.stop_time, &md.units)
        .map_err(|e| format!("cannot write {out}: {e}"))
}

/// Run one of the two FMI interfaces to the end, whichever backend serves it.
fn drive<T>(
    inst: &mut T,
    kind: InterfaceKind,
    md: &openmodelica_fmi::ModelDescription,
    opts: &Options,
) -> std::result::Result<(openmodelica_fmi_driver::record::Recorder, String), String>
where
    T: openmodelica_fmi_driver::api::Fmi3ModelExchange + openmodelica_fmi_driver::api::Fmi3CoSimulation,
{
    match kind {
        InterfaceKind::ModelExchange => {
            let run = me::simulate(inst, md, opts).map_err(|e| e.to_string())?;
            let retried = match run.retries {
                0 => String::new(),
                n => format!(", {n} retried steps"),
            };
            let s = format!(
                "{} steps, {} evaluations, {} Jacobians, {} state events, {} time events{retried}",
                run.steps, run.calls, run.jacobians, run.state_events, run.time_events
            );
            Ok((run.recorder, s))
        }
        _ => {
            let run = cs::simulate(inst, md, opts).map_err(|e| e.to_string())?;
            let s = format!(
                "{} communication steps, {} events, {} early returns",
                run.steps, run.events, run.early_returns
            );
            Ok((run.recorder, s))
        }
    }
}

/// ` in 4.2 ms`, or nothing under the testsuite: these lines reach a `simulate()`
/// record, where a timing would make the baseline depend on the clock.
fn took(ms: f64) -> String {
    match openmodelica_util::Testsuite::isRunning() {
        Ok(true) => String::new(),
        _ => format!(" in {ms:.1} ms"),
    }
}

/// How big the artifact was, left out of a testsuite run for the same reason the
/// timing is: it moves whenever the adapter or the model kernel is rebuilt, and a
/// baseline that records it fails on changes that are not about this test.
fn mb(bytes: u64) -> String {
    match openmodelica_util::Testsuite::isRunning() {
        Ok(true) => String::new(),
        _ => format!(", {:.1} MB", bytes as f64 / 1.0e6),
    }
}

fn instance_name(md: &openmodelica_fmi::ModelDescription) -> String {
    if md.model_name.is_empty() { "model".to_string() } else { md.model_name.clone() }
}
