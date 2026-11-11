//! What both masters do the same way: feed inputs, initialize, iterate events.

use crate::api::{DiscreteStates, Fmi3};
use crate::{Error, Options, Result};
use openmodelica_fmi::{ModelDescription, VarType};
use openmodelica_solvers::omclog;

/// C's `MAX_EVENT_ITER`: an event iteration that does not settle is a model
/// error, not something to spin on.
const MAX_EVENT_ITERATIONS: usize = 100;

/// The inputs, grouped by type so one `fmi3Set*` sets a whole group. Constant
/// expressions are separated out: FMI only wants them set once.
pub struct Inputs {
    groups: Vec<(VarType, Vec<u32>, Vec<usize>)>,
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
            time_varying: opts.inputs.iter().any(|i| i.values.iter().any(|e| !e.is_constant())),
            groups,
        }
    }

    /// Whether any input has to be set again at the next time point.
    pub fn is_time_varying(&self) -> bool {
        self.time_varying
    }

    /// Evaluate the inputs at `time` and set them. Continuous-Time Mode takes only
    /// the real ones; the others wait for Event Mode.
    pub fn apply(&mut self, inst: &mut dyn Fmi3, opts: &Options<'_>, time: f64, discrete: bool) -> Result<()> {
        for (ty, vrs, indices) in &self.groups {
            if !discrete && !matches!(ty, VarType::Float32 | VarType::Float64) {
                continue;
            }
            let values: Vec<f64> = indices
                .iter()
                .flat_map(|&i| opts.inputs[i].values.iter().map(|e| e.eval(time)))
                .collect();
            inst.set_numeric(*ty, vrs, &values)?;
        }
        Ok(())
    }
}

/// `fmi3EnterInitializationMode` … `fmi3ExitInitializationMode`, with the
/// parameters and the inputs at the start time in between — the only place FMI
/// lets a parameter be set.
pub fn initialize(inst: &mut dyn Fmi3, md: &ModelDescription, inputs: &mut Inputs, opts: &Options<'_>) -> Result<()> {
    let categories = shown_log_categories(md, opts);
    if !opts.logging_on {
        // The host may have instantiated with loggingOn to hear the instantiation.
        inst.set_debug_logging(false, &[])?;
    }
    if !categories.is_empty() {
        inst.set_debug_logging(true, &categories)?;
    }
    inst.enter_initialization_mode(opts.tolerance, opts.start_time, Some(opts.stop_time))?;
    for p in &opts.parameters {
        inst.set_numeric(p.ty.wire(), &[p.value_reference], &p.values)?;
    }
    inputs.apply(inst, opts, opts.start_time, true)?;
    inst.exit_initialization_mode()
}

/// The categories [`initialize`] enables. Without the full trace, still the
/// status categories: the message behind an error status is the only account of
/// what failed. A simulation also shows the model's output and its asserts
/// without -lv. Then the categories of the -lv streams.
pub fn shown_log_categories<'m>(md: &'m ModelDescription, opts: &Options<'_>) -> Vec<&'m str> {
    let declared = |name: &str| {
        md.log_categories
            .iter()
            .find(|c| c.name == name)
            .map(|c| c.name.as_str())
    };
    let mut categories: Vec<&str> = Vec::new();
    if !opts.logging_on {
        categories.extend(
            md.log_categories
                .iter()
                .map(|c| c.name.as_str())
                .filter(|c| c.starts_with("logStatus") || *c == "LOG_STDOUT" || *c == "LOG_ASSERT"),
        );
    }
    categories.extend(opts.log_streams.iter().filter_map(|s| {
        let (_, cat) = omclog::FMI_CATEGORIES
            .iter()
            .find(|(stream, _)| omclog::STREAM_NAME[*stream as usize] == s.as_str())?;
        declared(cat)
    }));
    categories
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
