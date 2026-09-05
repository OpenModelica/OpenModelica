//! The masters against the Modelica Association's Reference FMUs, which are not
//! in this repository: point `OMC_FMI_REFERENCE_FMUS` at an unpacked
//! `Reference-FMUs-<version>.zip` (the directory holding `3.0/`) and these run;
//! without it they skip. `OMC_FMI_LS_DAE_FMUS` does the same for the fmi-ls-dae
//! repository's own FMUs (its `reference-FMUs/build/fmus`).
//!
//! What is checked is what a master can be wrong about on its own: the solution
//! an FMU's equations have, the time an event happens at, and the values around
//! it.

#![cfg(all(feature = "ffi", not(target_arch = "wasm32")))]

use openmodelica_fmi::{Fmu, InterfaceKind};
use openmodelica_fmi_driver::api::{Fmi3CoSimulation, Fmi3ModelExchange};
use openmodelica_fmi_driver::record::Recorder;
use openmodelica_fmi_driver::{Options, cs, ffi, me};
use std::path::PathBuf;

fn reference_fmu(name: &str) -> Option<PathBuf> {
    let root = std::env::var_os("OMC_FMI_REFERENCE_FMUS")?;
    let path = PathBuf::from(root).join("3.0").join(format!("{name}.fmu"));
    path.exists().then_some(path)
}

fn ls_dae_fmu(name: &str) -> Option<PathBuf> {
    let root = std::env::var_os("OMC_FMI_LS_DAE_FMUS")?;
    let path = PathBuf::from(root).join(format!("{name}.fmu"));
    path.exists().then_some(path)
}

struct Sim {
    rec: Recorder,
    events: u64,
    event_times: Vec<f64>,
}

impl Sim {
    /// The value of `name` at the last sample at or before `t`. A discontinuity
    /// leaves two rows at one time; this takes the later, i.e. after the event.
    fn at(&self, name: &str, t: f64) -> f64 {
        let column = self
            .rec
            .columns
            .iter()
            .position(|c| c.name == name)
            .unwrap_or_else(|| panic!("no column {name}"));
        let values: Vec<f64> = self.rec.values(column).collect();
        let mut out = f64::NAN;
        for (row, time) in self.rec.times().enumerate() {
            if time <= t + 1e-9 {
                out = values[row];
            }
        }
        out
    }
}

fn simulate(name: &str, kind: InterfaceKind, with: impl FnOnce(&mut Options)) -> Option<Sim> {
    run(&reference_fmu(name)?, name, kind, false, with)
}

/// The same, in fmi-ls-dae's DAE mode: the manifest out of the FMU decides the
/// unknowns and the residuals, so nothing about the form is written down here.
fn simulate_dae(name: &str, with: impl FnOnce(&mut Options)) -> Option<Sim> {
    run(&ls_dae_fmu(name)?, name, InterfaceKind::ModelExchange, true, with)
}

fn run(
    path: &std::path::Path,
    name: &str,
    kind: InterfaceKind,
    dae: bool,
    with: impl FnOnce(&mut Options),
) -> Option<Sim> {
    let fmu = Fmu::from_path(path).expect("read the FMU");
    let md = &fmu.model_description;
    let mut opts = Options::from_model_description(md);
    if dae {
        opts.solver = openmodelica_fmi_driver::Solver::Ida;
        opts.dae = Some(fmu.ls_dae_manifest().expect("no fmi-ls-dae manifest").expect("parse the manifest"));
    }
    with(&mut opts);

    // A directory of its own per run: the tests run in parallel, and two of them
    // unpacking the same binary while a third loads it is a crash.
    static RUN: std::sync::atomic::AtomicUsize = std::sync::atomic::AtomicUsize::new(0);
    let run = RUN.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
    let dir = std::env::temp_dir().join(format!("om-fmi-test-{}-{name}-{run}", std::process::id()));
    let (lib, resources) = ffi::open_fmu(&fmu, kind, &dir).expect("open the binary");
    let (token, model) = (&md.instantiation_token, &md.model_name);
    Some(match kind {
        InterfaceKind::CoSimulation => {
            let event_mode = md.interface(kind).is_some_and(|i| i.has_event_mode);
            let mut inst = lib
                .instantiate_co_simulation(model, token, resources.as_deref(), false, event_mode, true)
                .expect("instantiate");
            let run = cs::simulate(&mut inst as &mut dyn Fmi3CoSimulation, md, &opts).expect("run");
            Sim { rec: run.recorder, events: run.events, event_times: run.event_times }
        }
        _ => {
            let mut inst = lib
                .instantiate_model_exchange(model, token, resources.as_deref(), false)
                .expect("instantiate");
            let run = me::simulate(&mut inst as &mut dyn Fmi3ModelExchange, md, &opts).expect("run");
            Sim {
                rec: run.recorder,
                events: run.state_events + run.time_events,
                event_times: run.event_times,
            }
        }
    })
}

/// `der(x) = -k*x`, so `x(t) = exp(-k*t)`: the master's own accuracy, with
/// nothing an FMU could get wrong in between.
#[test]
fn model_exchange_integrates_to_the_analytic_solution() {
    let Some(sim) = simulate("Dahlquist", InterfaceKind::ModelExchange, |o| {
        o.tolerance = Some(1e-9);
        o.stop_time = 5.0;
    }) else {
        return;
    };
    for t in [1.0, 2.5, 5.0] {
        let x = sim.at("x", t);
        assert!(
            (x - (-t).exp()).abs() < 1e-7,
            "x({t}) = {x}, not {} — the integration drifted",
            (-t).exp()
        );
    }
}

/// A ball dropped from h = 1 bounces at `sqrt(2/g)`, and leaves with `-e` times
/// the velocity it arrived with. Both come out of the master's root search, not
/// out of the FMU.
#[test]
fn model_exchange_lands_on_the_bounce() {
    let Some(sim) = simulate("BouncingBall", InterfaceKind::ModelExchange, |o| {
        o.tolerance = Some(1e-10);
        o.stop_time = 1.0;
        o.step_size = 0.01;
    }) else {
        return;
    };
    let bounce = (2.0f64 / 9.81).sqrt();
    let located = *sim.event_times.first().expect("no event was located");
    assert!(
        (located - bounce).abs() < 1e-6,
        "the bounce was located at {located}, not at {bounce}"
    );
    // Right after it, the ball rises at 0.7 of the speed it arrived with.
    let v_after = sim.at("v", located + 1e-9);
    assert!(
        (v_after - 0.7 * 9.81 * bounce).abs() < 1e-3,
        "v just after the bounce is {v_after}, not {}",
        0.7 * 9.81 * bounce
    );
}

/// The FMU counts up by one every second; the master must land on each of those
/// time events rather than stepping over them.
#[test]
fn time_events_are_hit_exactly() {
    for kind in [InterfaceKind::ModelExchange, InterfaceKind::CoSimulation] {
        let Some(sim) = simulate("Stair", kind, |o| o.stop_time = 5.0) else { return };
        assert_eq!(sim.events, 5, "{}: wrong number of events", kind.as_str());
        for k in 1..=5 {
            let counter = sim.at("counter", k as f64);
            assert_eq!(counter, k as f64 + 1.0, "{}: counter at t={k}", kind.as_str());
        }
    }
}

/// Both interfaces solve the same equations, so they must agree — as far as the
/// FMU's own solver is accurate, which is why this uses the model with the
/// gentlest solution rather than the limit cycle.
#[test]
fn model_exchange_and_co_simulation_agree() {
    let opts = |o: &mut Options| {
        o.tolerance = Some(1e-8);
        o.stop_time = 5.0;
        o.step_size = 0.01;
    };
    let (Some(me), Some(cs)) = (
        simulate("Dahlquist", InterfaceKind::ModelExchange, opts),
        simulate("Dahlquist", InterfaceKind::CoSimulation, opts),
    ) else {
        return;
    };
    // The Co-Simulation half is only as accurate as the FMU's own solver, which
    // for this one is a fixed-step forward Euler — hence the loose bound; what
    // is being checked is that the two follow the same solution, not that they
    // agree to the master's tolerance.
    for t in [1.0, 2.5, 5.0] {
        let (a, b) = (me.at("x", t), cs.at("x", t));
        assert!((a - b).abs() < 5e-2, "x({t}): Model Exchange {a}, Co-Simulation {b}");
    }
}

/// An FMU whose `<Dimension>` makes a variable an array: every element gets its
/// own column, so nothing is silently dropped.
#[test]
fn array_variables_get_a_column_each() {
    let Some(sim) = simulate("StateSpace", InterfaceKind::CoSimulation, |_| {}) else { return };
    let names: Vec<&str> = sim.rec.columns.iter().map(|c| c.name.as_str()).collect();
    assert!(names.contains(&"x[1]"), "no element columns: {names:?}");
}

/// The Co-Simulation master must take the FMU up on early return: the FMU stops
/// at its own event, the master handles it there, and the run still ends at the
/// stop time.
#[test]
fn co_simulation_handles_events_at_the_time_they_happen() {
    let Some(sim) = simulate("BouncingBall", InterfaceKind::CoSimulation, |o| {
        o.stop_time = 1.0;
    }) else {
        return;
    };
    assert!(sim.events >= 1, "no event was handled");
    let bounce = (2.0f64 / 9.81).sqrt();
    // The FMU stopped inside a communication interval to report the bounce, so
    // the run carries a sample there — a master that ignored early return would
    // only have the grid, with the ball still falling.
    let handled = *sim.event_times.first().expect("no event time");
    assert!(
        (handled - bounce).abs() < 1e-2 && handled < 0.5,
        "the bounce was handled at {handled}, not near {bounce}"
    );
    let v = sim.at("v", handled + 1e-9);
    assert!(v > 0.0, "the ball is still falling after the bounce (v = {v})");
    assert!(sim.rec.times().last().unwrap_or(0.0) >= 1.0 - 1e-9, "the run stopped early");
}

/// fmi-ls-dae's own reference FMU states a *semi-explicit* DAE, so the master
/// closes the system itself over `y = [x1 x2 z1 z2]`. With both inputs left at
/// zero the constraints come out as `tanh(3*z1) = 0` and `1/3 = sin(z2*x2)`, and
/// `der(x1) = sin(x1)` integrates to `x1 = 2*atan(tan(x1(0)/2)*e^t)`.
#[test]
fn dae_mode_solves_a_semi_explicit_dae() {
    let Some(sim) = simulate_dae("SimpleDAE", |o| {
        o.tolerance = Some(1e-10);
        o.stop_time = 2.0;
    }) else {
        return;
    };
    for t in [0.5, 1.0, 2.0] {
        let (x1, x2, z1, z2) = (sim.at("x1", t), sim.at("x2", t), sim.at("z1", t), sim.at("z2", t));
        let want_x1 = 2.0 * ((0.25f64).tan() * t.exp()).atan();
        assert!((x1 - want_x1).abs() < 1e-6, "x1({t}) = {x1}, not {want_x1}");
        assert!(z1.abs() < 1e-6, "z1({t}) = {z1}, not 0 — the first constraint is not held");
        let g = (z2 * x2).sin() - 1.0 / 3.0;
        assert!(g.abs() < 1e-6, "the second constraint is off by {g} at t = {t}");
    }
}
