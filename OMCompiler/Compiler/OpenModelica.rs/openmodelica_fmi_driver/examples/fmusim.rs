//! `cargo run --example fmusim -- [options] <file.fmu>` — simulate an FMU with
//! the masters, natively.
//!
//! Options: `--me`/`--cs`, `--start`, `--stop`, `--step`, `--tolerance`,
//! `--solver <name>` (`Solver::all`), `--input vr=expr`, `--parameter vr=value`,
//! `--output file.mat`, `--csv` (the trajectory on stdout), `--log`,
//! `--difference-jacobian` (ignore what the FMU offers).

use openmodelica_fmi::{Fmu, InterfaceKind};
use openmodelica_fmi_driver::api::{Fmi3, Fmi3CoSimulation, Fmi3ModelExchange};
use openmodelica_fmi_driver::{Input, Options, Parameter, Solver, choose_interface, cs, expr, ffi, me};
use std::path::{Path, PathBuf};

fn main() {
    if let Err(e) = run() {
        eprintln!("fmusim: {e}");
        std::process::exit(1);
    }
}

struct Args {
    fmu: PathBuf,
    interface: Option<InterfaceKind>,
    start: Option<f64>,
    stop: Option<f64>,
    step: Option<f64>,
    tolerance: Option<f64>,
    solver: Solver,
    difference_jacobian: bool,
    log: bool,
    output: Option<PathBuf>,
    csv: bool,
    inputs: Vec<(u32, String)>,
    parameters: Vec<(u32, f64)>,
}

fn parse_args() -> Result<Args, String> {
    let mut a = Args {
        fmu: PathBuf::new(),
        interface: None,
        start: None,
        stop: None,
        step: None,
        tolerance: None,
        solver: Solver::default(),
        difference_jacobian: false,
        log: false,
        output: None,
        csv: false,
        inputs: Vec::new(),
        parameters: Vec::new(),
    };
    let mut it = std::env::args().skip(1);
    while let Some(arg) = it.next() {
        let mut value = || it.next().ok_or_else(|| format!("{arg} needs a value"));
        match arg.as_str() {
            "--me" => a.interface = Some(InterfaceKind::ModelExchange),
            "--cs" => a.interface = Some(InterfaceKind::CoSimulation),
            "--log" => a.log = true,
            "--difference-jacobian" => a.difference_jacobian = true,
            "--csv" => a.csv = true,
            "--start" => a.start = Some(value()?.parse().map_err(|_| "bad --start")?),
            "--stop" => a.stop = Some(value()?.parse().map_err(|_| "bad --stop")?),
            "--step" => a.step = Some(value()?.parse().map_err(|_| "bad --step")?),
            "--tolerance" => a.tolerance = Some(value()?.parse().map_err(|_| "bad --tolerance")?),
            "--output" => a.output = Some(PathBuf::from(value()?)),
            "--solver" => {
                let name = value()?;
                a.solver = Solver::parse(&name).ok_or_else(|| {
                    let have: Vec<&str> = Solver::all().iter().map(|s| s.as_str()).collect();
                    format!("unknown solver `{name}`; this build has {}", have.join(", "))
                })?;
            }
            "--input" | "--parameter" => {
                let v = value()?;
                let (vr, rest) = v.split_once('=').ok_or("expected <vr>=<value>")?;
                let vr: u32 = vr.trim().parse().map_err(|_| "the value reference is a number")?;
                if arg == "--input" {
                    a.inputs.push((vr, rest.to_string()));
                } else {
                    a.parameters.push((vr, rest.trim().parse().map_err(|_| "bad parameter value")?));
                }
            }
            _ if arg.starts_with("--") => return Err(format!("unknown option {arg}")),
            _ => a.fmu = PathBuf::from(arg),
        }
    }
    if a.fmu.as_os_str().is_empty() {
        return Err("no FMU given".into());
    }
    Ok(a)
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let args = parse_args()?;
    let fmu = Fmu::from_path(&args.fmu)?;
    let md = &fmu.model_description;
    let kind = choose_interface(md, args.interface)?;

    let mut opts = Options::from_model_description(md);
    opts.start_time = args.start.unwrap_or(opts.start_time);
    opts.stop_time = args.stop.unwrap_or(opts.stop_time);
    opts.step_size = args.step.unwrap_or(opts.step_size);
    opts.tolerance = args.tolerance.or(opts.tolerance);
    opts.solver = args.solver;
    opts.directional_derivatives = !args.difference_jacobian;
    opts.logging_on = args.log;
    for (vr, text) in &args.inputs {
        let v = md
            .variable_by_vr(*vr)
            .ok_or_else(|| format!("no variable has value reference {vr}"))?;
        opts.inputs.push(Input {
            value_reference: *vr,
            ty: v.ty,
            value: expr::Expr::parse(text)?,
        });
    }
    for (vr, value) in &args.parameters {
        let v = md
            .variable_by_vr(*vr)
            .ok_or_else(|| format!("no variable has value reference {vr}"))?;
        opts.parameters.push(Parameter { value_reference: *vr, ty: v.ty, value: *value });
    }

    // The FMU is unpacked next to itself; a native binary has to exist on disk
    // to be loaded, and its resources have to be reachable by path.
    let dir = unpack_dir(&args.fmu);
    let (lib, resources) = ffi::open_fmu(&fmu, kind, &dir)?;
    let name = &md.model_name;
    let token = &md.instantiation_token;

    let (rec, summary) = match kind {
        InterfaceKind::CoSimulation => {
            let event_mode = md.interface(kind).is_some_and(|i| i.has_event_mode);
            let mut inst = lib.instantiate_co_simulation(
                name,
                token,
                resources.as_deref(),
                args.log,
                event_mode,
                true,
            )?;
            let r = cs::simulate(&mut inst as &mut dyn Fmi3CoSimulation, md, &opts)?;
            report_log(&mut inst);
            (
                r.recorder,
                format!(
                    "{} communication steps, {} events, {} early returns",
                    r.steps, r.events, r.early_returns
                ),
            )
        }
        InterfaceKind::ModelExchange => {
            let mut inst =
                lib.instantiate_model_exchange(name, token, resources.as_deref(), args.log)?;
            let r = me::simulate(&mut inst as &mut dyn Fmi3ModelExchange, md, &opts)?;
            report_log(&mut inst);
            (
                r.recorder,
                format!(
                    "{} steps, {} derivative evaluations, {} Jacobians, {} state events, {} time events",
                    r.steps, r.calls, r.jacobians, r.state_events, r.time_events
                ),
            )
        }
        InterfaceKind::ScheduledExecution => {
            return Err("Scheduled Execution is not driven".into());
        }
    };

    println!(
        "{}: {} {} — {} rows, {summary}",
        md.model_name,
        md.fmi_version_string,
        kind.as_str(),
        rec.len()
    );
    if args.csv {
        print!("time");
        for c in &rec.columns {
            print!(",{}", c.name);
        }
        println!();
        let mut columns: Vec<Vec<f64>> = rec.columns.iter().enumerate().map(|(i, _)| rec.values(i).collect()).collect();
        for (row, t) in rec.times().enumerate() {
            print!("{t}");
            for c in &mut columns {
                print!(",{}", c[row]);
            }
            println!();
        }
    }
    let output = args
        .output
        .unwrap_or_else(|| PathBuf::from(format!("{}_res.mat", md.model_name)));
    rec.write(&output, opts.start_time, opts.stop_time, &md.units)?;
    println!("wrote {}", output.display());
    for (i, c) in rec.columns.iter().enumerate() {
        let last = rec.values(i).last().unwrap_or(f64::NAN);
        println!("  {} = {last}{}", c.name, c.unit.as_deref().unwrap_or(""));
    }
    Ok(())
}

fn report_log(inst: &mut dyn Fmi3) {
    for (status, category, message) in inst.take_log() {
        eprintln!("[{} {category}] {message}", status.as_str());
    }
}

/// Where an FMU is unpacked: `<name>.fmu.d` beside the archive, reused between
/// runs so a second run does not pay for the extraction.
fn unpack_dir(fmu: &Path) -> PathBuf {
    let mut dir = fmu.as_os_str().to_os_string();
    dir.push(".d");
    PathBuf::from(dir)
}
