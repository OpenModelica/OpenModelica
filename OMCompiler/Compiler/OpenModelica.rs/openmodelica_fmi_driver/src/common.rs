//! What both masters do the same way: feed inputs, initialize, iterate events.

use crate::api::{DiscreteStates, Fmi3};
use crate::{Error, Options, Result};
use openmodelica_fmi::{ModelDescription, VarType};

/// C's `MAX_EVENT_ITER`: an event iteration that does not settle is a model
/// error, not something to spin on.
const MAX_EVENT_ITERATIONS: usize = 100;

/// The inputs, grouped by type so one `fmi3Set*` sets a whole group. Constant
/// expressions are separated out: FMI only wants them set once.
pub struct Inputs {
    groups: Vec<(VarType, Vec<u32>, Vec<usize>)>,
    values: Vec<f64>,
    time_varying: bool,
}

impl Inputs {
    pub fn new(opts: &Options<'_>) -> Inputs {
        let mut groups: Vec<(VarType, Vec<u32>, Vec<usize>)> = Vec::new();
        for (i, input) in opts.inputs.iter().enumerate() {
            let ty = input.ty.wire();
            match groups.iter_mut().find(|g| g.0 == ty) {
                Some(g) => {
                    g.1.push(input.value_reference);
                    g.2.push(i);
                }
                None => groups.push((ty, vec![input.value_reference], vec![i])),
            }
        }
        Inputs {
            time_varying: opts.inputs.iter().any(|i| !i.value.is_constant()),
            values: vec![0.0; opts.inputs.len()],
            groups,
        }
    }

    /// Whether any input has to be set again at the next time point.
    pub fn is_time_varying(&self) -> bool {
        self.time_varying
    }

    /// Evaluate every input at `time` and set it.
    pub fn apply(&mut self, inst: &mut dyn Fmi3, opts: &Options<'_>, time: f64) -> Result<()> {
        for (i, input) in opts.inputs.iter().enumerate() {
            self.values[i] = input.value.eval(time);
        }
        for (ty, vrs, indices) in &self.groups {
            let values: Vec<f64> = indices.iter().map(|&i| self.values[i]).collect();
            inst.set_numeric(*ty, vrs, &values)?;
        }
        Ok(())
    }
}

/// `fmi3EnterInitializationMode` … `fmi3ExitInitializationMode`, with the
/// parameters and the inputs at the start time in between — the only place FMI
/// lets a parameter be set.
pub fn initialize(
    inst: &mut dyn Fmi3,
    md: &ModelDescription,
    inputs: &mut Inputs,
    opts: &Options<'_>,
) -> Result<()> {
    // Without the full trace, still ask for the status categories: the message
    // behind an error status is the only account of what failed.
    let declared = |name: &str| md.log_categories.iter().any(|c| c.name == name);
    let mut categories: Vec<&str> = Vec::new();
    if !opts.logging_on {
        categories.extend(
            md.log_categories.iter().map(|c| c.name.as_str()).filter(|c| c.starts_with("logStatus")),
        );
    }
    categories.extend(opts.log_streams.iter().map(String::as_str).filter(|s| declared(s)));
    if !categories.is_empty() {
        inst.set_debug_logging(true, &categories)?;
    }
    inst.enter_initialization_mode(opts.tolerance, opts.start_time, Some(opts.stop_time))?;
    for p in &opts.parameters {
        inst.set_numeric(p.ty.wire(), &[p.value_reference], &[p.value])?;
    }
    inputs.apply(inst, opts, opts.start_time)?;
    inst.exit_initialization_mode()
}

/// C's event iteration: update the discrete states until they settle.
pub fn event_iteration(inst: &mut dyn Fmi3) -> Result<DiscreteStates> {
    for _ in 0..MAX_EVENT_ITERATIONS {
        let info = inst.update_discrete_states()?;
        if !info.need_update {
            return Ok(info);
        }
        if info.terminate {
            return Ok(info);
        }
    }
    Err(Error::Solver(
        "the event iteration did not converge after 100 updates of the discrete states",
    ))
}
