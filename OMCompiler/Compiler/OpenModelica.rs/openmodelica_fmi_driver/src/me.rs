//! The Model Exchange master: the FMU supplies the equations, the master
//! integrates them.
//!
//! The integrators are `openmodelica_solvers`, the same ones a compiled
//! OpenModelica model runs under, driven through [`openmodelica_solvers::Ode`]
//! — so an FMU is stepped, error-controlled and root-searched exactly like a
//! model, under the same `-s=…`/`-gb*` flags. Events come from three places:
//! the solver locating a sign change in the event indicators, the FMU asking
//! for Event Mode after a completed step, and the time events
//! `fmi3UpdateDiscreteStates` announces.
//!
//! An FMU with an fmi-ls-dae manifest can instead be run in DAE mode
//! ([`Options::dae`]): the master sets the states and the algebraic variables,
//! reads the residuals back, and IDA drives them to zero over
//! `y = [states | algebraic variables]` — with `IDACalcIC` making the point
//! consistent at the start and after every event, as a `--daeMode` model's own
//! runtime does. The manifest states the DAE in one of two forms (`DaeForm`),
//! which decides whether the derivatives go in as knowns as well.

use crate::api::{Fmi3, Fmi3ModelExchange};
use crate::common::{Inputs, event_iteration, initialize};
use crate::record::Recorder;
use crate::{Deadline, Error, Options, Result, Solver};
use openmodelica_fmi::{ModelDescription, VarType};
use openmodelica_solvers::dassl::{Dassl, DasslStep};
use openmodelica_solvers::events::StepEnd;
use openmodelica_solvers::fixedstep::{FixedKind, FixedStep};
use openmodelica_solvers::gbode::{GbStep, Gbode};
#[cfg(sundials)]
use openmodelica_solvers::sundials_ode::{CvodeOde, IdaDae, IdaOde, SunStep};
use openmodelica_solvers::{Dae, DaeSparsity, Ode};

pub struct Run {
    pub recorder: Recorder,
    pub terminated_at: Option<f64>,
    /// The host asked for the run to stop; the samples up to here are kept.
    pub cancelled: bool,
    /// Integrator steps.
    pub steps: u64,
    /// Right-hand-side evaluations.
    pub calls: u64,
    /// Jacobians assembled.
    pub jacobians: u64,
    pub state_events: u64,
    pub time_events: u64,
    /// When the events happened, in order — what a plot marks and a test checks.
    pub event_times: Vec<f64>,
    /// Discarded steps taken again at half the size.
    pub retries: u64,
}

/// The two shapes fmi-ls-dae's `<ModelStructure>` can state a DAE in.
#[derive(Clone, Copy, PartialEq, Eq)]
enum DaeForm {
    /// No `<ContinuousStateDerivative>`: the residuals cover every unknown, and
    /// `der(x)` goes into the FMU as a known of theirs.
    Implicit,
    /// One per state: the FMU answers with `der(x)`, the residuals constrain the
    /// algebraic variables alone, and the master closes the state rows itself.
    SemiExplicit,
}

/// The value references DAE mode works through, out of the fmi-ls-dae manifest.
struct DaeVrs {
    nx: usize,
    form: DaeForm,
    /// The algebraic variables, which follow the states in `y`.
    alg_vrs: Vec<u32>,
    /// The state derivatives in the FMU's own order: knowns of the residuals in
    /// the implicit form, and in the semi-explicit one the name of the column
    /// each belongs to.
    der_vrs: Vec<u32>,
    /// The residuals the FMU exposes, one per `<Residual>`.
    res_vrs: Vec<u32>,
    /// The residual Jacobian's sparsity, out of the manifest's `dependencies`;
    /// `None` when the manifest states none, which means a dense Jacobian.
    sparsity: Option<DaeSparsity>,
}

/// The FMU as an ODE: set the time and the states, then read the derivatives or
/// the event indicators back. In DAE mode the algebraic variables are set too —
/// and the derivatives, in the implicit form — and the residuals are read.
struct FmuOde<'a> {
    inst: &'a mut dyn Fmi3ModelExchange,
    inputs: &'a mut Inputs,
    opts: &'a Options<'a>,
    nominals: Vec<f64>,
    /// The ODE Jacobian's sparsity, out of `<ModelStructure>`: which states each
    /// state derivative depends on, coloured so one evaluation differences a
    /// whole group of columns.
    colors: Vec<Vec<u32>>,
    rows_by_col: Vec<Vec<u32>>,
    /// The value references the Jacobian is asked for, when the FMU can answer
    /// `fmi3GetDirectionalDerivative`: the state derivatives against the states.
    derivative_vrs: Vec<u32>,
    state_vrs: Vec<u32>,
    directional: bool,
    calls: u64,
    /// The point the FMU is standing at, so the same one is not set twice: an
    /// FMU treats every `fmi3SetContinuousStates` as a move and throws away what
    /// it cached for the old point — including its Jacobian, which a colour-by-
    /// colour assembly would then pay for again per colour. The derivatives are
    /// part of the point in the implicit DAE form only.
    committed: Option<(f64, Vec<f64>, Vec<f64>)>,
    dae: Option<DaeVrs>,
    /// What the FMU actually said, behind the static message the solvers carry.
    failure: Option<Error>,
    /// The last evaluation was answered `fmi3Discard`, so the solver may retry.
    discarded: bool,
    /// `-alarm`, polled here rather than only at the output points: a solver that
    /// stops converging never reaches them.
    deadline: Deadline,
    /// Calls into the FMU since the deadline was last read — every one, not just
    /// the derivatives: event indicators can cost what derivatives do.
    polls: u64,
}

impl FmuOde<'_> {
    /// Put `(t, y)` into the FMU, with the inputs of that time. Setting the
    /// point it already holds is skipped.
    fn commit(&mut self, t: f64, y: &[f64]) -> Result<()> {
        self.commit_point(t, y, &[])
    }

    /// [`commit`](Self::commit), with the derivatives too where the FMU takes
    /// them: the implicit form's residuals are a function of `(t, y, y')`.
    fn commit_point(&mut self, t: f64, y: &[f64], yp: &[f64]) -> Result<()> {
        let Some(dae) = self.dae.as_ref() else {
            if self.committed.as_ref().is_some_and(|(ct, cy, _)| *ct == t && cy == y) {
                return Ok(());
            }
            self.inst.set_time(t)?;
            self.inst.set_continuous_states(y)?;
            if self.inputs.is_time_varying() {
                let inst: &mut dyn Fmi3 = self.inst;
                self.inputs.apply(inst, self.opts, t)?;
            }
            self.committed = Some((t, y.to_vec(), Vec::new()));
            return Ok(());
        };
        let nx = dae.nx;
        // A semi-explicit FMU is not told its derivatives, so they are no part
        // of the point it stands at.
        let implicit = dae.form == DaeForm::Implicit;
        let ders = if implicit { &yp[..nx.min(yp.len())] } else { &[][..] };
        if self.committed.as_ref().is_some_and(|(ct, cy, cp)| *ct == t && cy == y && cp == ders) {
            return Ok(());
        }
        self.inst.set_time(t)?;
        self.inst.set_continuous_states(&y[..nx])?;
        if !dae.alg_vrs.is_empty() {
            let inst: &mut dyn Fmi3 = self.inst;
            inst.set_numeric(VarType::Float64, &dae.alg_vrs, &y[nx..])?;
        }
        if implicit && ders.len() == nx && nx > 0 {
            let inst: &mut dyn Fmi3 = self.inst;
            inst.set_numeric(VarType::Float64, &dae.der_vrs, ders)?;
        }
        if self.inputs.is_time_varying() {
            let inst: &mut dyn Fmi3 = self.inst;
            self.inputs.apply(inst, self.opts, t)?;
        }
        self.committed = Some((t, y.to_vec(), ders.to_vec()));
        Ok(())
    }

    /// DAE mode: the point the FMU holds — states, algebraic variables, state
    /// derivatives — after the FMU moved it (initialization, an event).
    fn read_dae_point(&mut self, y: &mut [f64], yp: &mut [f64]) -> Result<()> {
        let Some(dae) = self.dae.as_ref() else { return Ok(()) };
        let nx = dae.nx;
        if nx > 0 {
            self.inst.get_continuous_states(&mut y[..nx])?;
            self.inst.get_continuous_state_derivatives(&mut yp[..nx])?;
        }
        if !dae.alg_vrs.is_empty() {
            let inst: &mut dyn Fmi3 = self.inst;
            inst.get_numeric(VarType::Float64, &dae.alg_vrs, &mut y[nx..])?;
        }
        Ok(())
    }

    /// Anything that moves the FMU behind the master's back — an event, a mode
    /// change — makes the remembered point wrong.
    fn forget_point(&mut self) {
        self.committed = None;
    }

    /// Keep the FMU's error and hand the solvers the one static message they
    /// carry; [`Run`] surfaces the real one. `fmi3Discard` answers for the trial
    /// point, not the run, so it is flagged rather than kept.
    fn note(&mut self, e: Error) -> &'static str {
        self.discarded = matches!(e, Error::Status { status: crate::api::Status::Discard, .. });
        if self.discarded {
            return "the FMU discarded the point it was asked to evaluate";
        }
        self.failure.get_or_insert(e);
        "the FMU reported an error while being integrated"
    }

    /// `-alarm`, checked every 64th call: reading the clock on each would be most
    /// of a cheap model's evaluation.
    fn past_deadline(&mut self) -> bool {
        self.polls += 1;
        self.polls % 64 == 0 && self.deadline.expired()
    }
}

impl Ode for FmuOde<'_> {
    fn eval(&mut self, t: f64, y: &[f64], f: &mut [f64]) -> openmodelica_solvers::Result<()> {
        self.calls += 1;
        if self.past_deadline() {
            return Err(self.note(Error::Alarm));
        }
        self.commit(t, y).map_err(|e| self.note(e))?;
        self.inst.get_continuous_state_derivatives(f).map_err(|e| self.note(e))
    }

    fn eval_zc(&mut self, t: f64, y: &[f64], zc: &mut [f64]) -> openmodelica_solvers::Result<()> {
        if zc.is_empty() {
            return Ok(());
        }
        if self.past_deadline() {
            return Err(self.note(Error::Alarm));
        }
        self.commit(t, y).map_err(|e| self.note(e))?;
        self.inst.get_event_indicators(zc).map_err(|e| self.note(e))
    }

    fn nominals(&self) -> &[f64] {
        &self.nominals
    }

    fn jac_colors(&self) -> &[Vec<u32>] {
        &self.colors
    }

    fn jac_rows_by_col(&self) -> &[Vec<u32>] {
        &self.rows_by_col
    }

    fn has_jacobian_vector(&self) -> bool {
        self.directional
    }

    fn jacobian_vector(&mut self, t: f64, y: &[f64], seed: &[f64], out: &mut [f64]) -> bool {
        if self.past_deadline() {
            self.failure.get_or_insert(Error::Alarm);
            return false;
        }
        if self.commit(t, y).is_err() {
            return false;
        }
        let (unknowns, knowns) = (self.derivative_vrs.clone(), self.state_vrs.clone());
        match self.inst.get_directional_derivative(&unknowns, &knowns, seed, out) {
            Ok(()) => true,
            Err(e) => {
                // Fall back to differencing rather than failing the run: an FMU
                // may advertise the call and still refuse this block.
                self.failure.get_or_insert(e);
                self.directional = false;
                false
            }
        }
    }

    fn calls(&self) -> u64 {
        self.calls
    }

    fn take_discard(&mut self) -> bool {
        core::mem::take(&mut self.discarded)
    }
}

fn is_discard(e: &Error) -> bool {
    matches!(e, Error::Status { status: crate::api::Status::Discard, .. })
}

impl Dae for FmuOde<'_> {
    fn sparsity(&self) -> Option<&DaeSparsity> {
        self.dae.as_ref().and_then(|d| d.sparsity.as_ref())
    }

    fn residual(&mut self, t: f64, y: &[f64], yp: &[f64], res: &mut [f64]) -> openmodelica_solvers::Result<()> {
        if self.past_deadline() {
            return Err(self.note(Error::Alarm));
        }
        self.commit_point(t, y, yp).map_err(|e| self.note(e))?;
        let Some(d) = self.dae.as_ref() else { return Ok(()) };
        let (form, nx) = (d.form, d.nx);
        if form == DaeForm::Implicit {
            let inst: &mut dyn Fmi3 = self.inst;
            let r = inst.get_numeric(VarType::Float64, &d.res_vrs, res);
            return r.map_err(|e| self.note(e));
        }
        // The state rows close der(x) = f(x, a, t) over y'; the FMU's residuals
        // are the constraints below them.
        if nx > 0 {
            self.inst.get_continuous_state_derivatives(&mut res[..nx]).map_err(|e| self.note(e))?;
            for (r, p) in res[..nx].iter_mut().zip(yp) {
                *r = *p - *r;
            }
        }
        let d = self.dae.as_ref().expect("checked above");
        if d.res_vrs.is_empty() {
            return Ok(());
        }
        let inst: &mut dyn Fmi3 = self.inst;
        let r = inst.get_numeric(VarType::Float64, &d.res_vrs, &mut res[nx..]);
        r.map_err(|e| self.note(e))
    }

    fn eval_zc(&mut self, t: f64, y: &[f64], yp: &[f64], zc: &mut [f64]) -> openmodelica_solvers::Result<()> {
        if zc.is_empty() {
            return Ok(());
        }
        if self.past_deadline() {
            return Err(self.note(Error::Alarm));
        }
        self.commit_point(t, y, yp).map_err(|e| self.note(e))?;
        self.inst.get_event_indicators(zc).map_err(|e| self.note(e))
    }

    fn nominals(&self) -> &[f64] {
        &self.nominals
    }

    fn note_call(&mut self) {
        self.calls += 1;
    }

    fn take_discard(&mut self) -> bool {
        core::mem::take(&mut self.discarded)
    }
}

/// The value references DAE mode needs, checked against the model description:
/// a manifest naming a variable the FMU does not have is a broken FMU, not a
/// broken run.
fn dae_vrs(md: &ModelDescription, m: &openmodelica_fmi::lsdae::Manifest, nx: usize) -> Result<DaeVrs> {
    let float64 = |vr: u32, what: &str| -> Result<u32> {
        match md.variable_by_vr(vr) {
            Some(v) if v.ty == VarType::Float64 => Ok(vr),
            _ => Err(Error::Unsupported(format!(
                "fmi-ls-dae: {what} value reference {vr} is not a Float64 variable of the FMU"
            ))),
        }
    };
    // The manifest's <ModelStructure> replaces the model description's, so its
    // <ContinuousStateDerivative> list decides the form; naming none states the
    // implicit one, whose derivatives the model description still has to name.
    let form = if m.continuous_state_derivatives.is_empty() { DaeForm::Implicit } else { DaeForm::SemiExplicit };
    // From the model description in either form: `continuous_states` and
    // `fmi3GetContinuousStates` follow this order, which is what pairs `y[i]`
    // with `y'[i]`. The manifest's own order does not get to decide that.
    let der_vrs: Vec<u32> =
        md.model_structure.continuous_state_derivatives.iter().map(|u| u.value_reference).collect();
    if der_vrs.len() != nx {
        return Err(Error::Unsupported(format!(
            "fmi-ls-dae: the FMU has {nx} continuous states but <ModelStructure> lists {} derivatives",
            der_vrs.len()
        )));
    }
    if form == DaeForm::SemiExplicit && m.continuous_state_derivatives.len() != nx {
        return Err(Error::Unsupported(format!(
            "fmi-ls-dae: the manifest states a semi-explicit DAE but gives {} of the FMU's {nx} state derivatives",
            m.continuous_state_derivatives.len()
        )));
    }
    let alg_vrs = m.algebraic_variables.iter().map(|&vr| float64(vr, "algebraic variable")).collect::<Result<Vec<_>>>()?;
    let res_vrs = m.residual_vrs().into_iter().map(|vr| float64(vr, "residual")).collect::<Result<Vec<_>>>()?;
    let wanted = match form {
        DaeForm::Implicit => nx + alg_vrs.len(),
        DaeForm::SemiExplicit => alg_vrs.len(),
    };
    if res_vrs.len() != wanted {
        let form = match form {
            DaeForm::Implicit => "implicit",
            DaeForm::SemiExplicit => "semi-explicit",
        };
        return Err(Error::Unsupported(format!(
            "fmi-ls-dae: the manifest states a {form} DAE with {} states and {} algebraic variables, which wants {wanted} residuals, but lists {}; only a square system can be integrated",
            nx,
            alg_vrs.len(),
            res_vrs.len()
        )));
    }
    let sparsity = dae_sparsity(md, m, nx, form, &alg_vrs, &der_vrs);
    Ok(DaeVrs { nx, form, alg_vrs, der_vrs, res_vrs, sparsity })
}

/// The residual Jacobian's sparsity out of the manifest's `dependencies`: for
/// each row of `F`, which of `y = [states | algebraic]` it reaches. A state's
/// column collects the rows reached through either `x` or `der(x)`, since one
/// difference quotient carries `∂F/∂x + cj·∂F/∂der(x)` together — which is why
/// the exporter lists both for a state column.
///
/// The semi-explicit form's state rows reach their own column through `y'`
/// whatever the manifest says, plus what the `<ContinuousStateDerivative>`
/// depends on.
///
/// `None` unless every row states its dependencies: one that does not means
/// "all of them", and a Jacobian with a dense row is no cheaper to difference
/// sparsely than to let IDA build itself.
fn dae_sparsity(
    md: &ModelDescription,
    m: &openmodelica_fmi::lsdae::Manifest,
    nx: usize,
    form: DaeForm,
    alg_vrs: &[u32],
    der_vrs: &[u32],
) -> Option<DaeSparsity> {
    let mut column_of: std::collections::HashMap<u32, usize> = std::collections::HashMap::new();
    for (col, vr) in md.continuous_states().iter().enumerate() {
        column_of.insert(*vr, col);
    }
    for (col, vr) in der_vrs.iter().enumerate() {
        column_of.insert(*vr, col);
    }
    for (k, vr) in alg_vrs.iter().enumerate() {
        column_of.insert(*vr, nx + k);
    }
    let n = nx + alg_vrs.len();
    if column_of.len() < n {
        return None; // a state without a value reference of its own
    }
    let mut rows_by_col: Vec<Vec<u32>> = vec![Vec::new(); n];
    let mark = |rows_by_col: &mut Vec<Vec<u32>>, row: usize, u: &openmodelica_fmi::description::Unknown| {
        let deps = u.dependencies.as_ref()?;
        for col in deps.iter().filter_map(|vr| column_of.get(vr)) {
            rows_by_col[*col].push(row as u32);
        }
        Some(())
    };
    let first_residual = if form == DaeForm::SemiExplicit {
        let row_of: std::collections::HashMap<u32, usize> =
            der_vrs.iter().enumerate().map(|(row, vr)| (*vr, row)).collect();
        for row in 0..nx {
            rows_by_col[row].push(row as u32);
        }
        for u in &m.continuous_state_derivatives {
            mark(&mut rows_by_col, *row_of.get(&u.value_reference)?, u)?;
        }
        nx
    } else {
        0
    };
    // The same order `Manifest::residual_vrs` uses, so the rows line up.
    for (i, u) in m.residuals.iter().enumerate() {
        mark(&mut rows_by_col, first_residual + i, u)?;
    }
    for rows in &mut rows_by_col {
        rows.sort_unstable();
        rows.dedup();
    }
    let colors = greedy_colors(&rows_by_col);
    Some(DaeSparsity { rows_by_col, colors })
}

/// The ODE Jacobian's sparsity as `<ModelStructure>` gives it: for each state
/// derivative, the `dependencies` that are themselves states. An FMU that lists
/// no dependencies for an entry is saying "everything", which is a dense column
/// — and an FMU with no `<ContinuousStateDerivative>` at all leaves the solvers
/// to difference the matrix themselves.
///
/// An FMI 3.0 entry can stand for a whole array: as many rows as the derivative
/// has elements, and a dependency on an array covers all of its columns. A
/// `<ModelStructure>` that does not account for all `nx` states the FMU reports
/// is left to the solver rather than half-assembled.
pub fn jacobian_sparsity(md: &ModelDescription, nx: usize) -> (Vec<Vec<u32>>, Vec<Vec<u32>>) {
    let none = (Vec::new(), Vec::new());
    let derivatives = &md.model_structure.continuous_state_derivatives;
    if derivatives.is_empty() || nx == 0 {
        return none;
    }
    // The states as the FMU holds them: one span of elements per entry.
    let mut spans: Vec<(usize, usize)> = Vec::with_capacity(derivatives.len());
    let mut column_of: std::collections::HashMap<u32, (usize, usize)> = Default::default();
    let mut n = 0usize;
    for unknown in derivatives {
        let Some(state) = md
            .variable_by_vr(unknown.value_reference)
            .and_then(|d| d.derivative)
            .and_then(|vr| md.variable_by_vr(vr))
        else {
            return none;
        };
        let Some(len) = state.fixed_len().filter(|&l| l > 0) else { return none };
        let span = (n, len as usize);
        spans.push(span);
        column_of.insert(state.value_reference, span);
        n += len as usize;
    }
    if n != nx {
        return none;
    }
    // Past this the row lists cost more than differencing the whole matrix.
    const MAX_NONZEROS: usize = 32 << 20;
    let mut nonzeros = 0usize;
    for (unknown, &(_, rows)) in derivatives.iter().zip(&spans) {
        let cols: usize = match unknown.dependencies.as_ref() {
            None => nx,
            Some(deps) => deps.iter().filter_map(|vr| column_of.get(vr)).map(|&(_, l)| l).sum(),
        };
        nonzeros = nonzeros.saturating_add(rows.saturating_mul(cols));
    }
    if nonzeros > MAX_NONZEROS {
        return none;
    }
    let mut rows_by_col: Vec<Vec<u32>> = vec![Vec::new(); nx];
    for (unknown, &(row, rows)) in derivatives.iter().zip(&spans) {
        let mut mark = |col: usize| rows_by_col[col].extend((row..row + rows).map(|r| r as u32));
        match unknown.dependencies.as_ref() {
            // Unstated dependencies mean all of them.
            None => (0..nx).for_each(&mut mark),
            Some(deps) => {
                for &(col, cols) in deps.iter().filter_map(|vr| column_of.get(vr)) {
                    (col..col + cols).for_each(&mut mark);
                }
            }
        }
    }
    let colors = greedy_colors(&rows_by_col);
    (colors, rows_by_col)
}

/// Greedy colouring: two columns share a colour when no row is nonzero in both,
/// so one perturbation differences them together.
fn greedy_colors(rows_by_col: &[Vec<u32>]) -> Vec<Vec<u32>> {
    let mut colors: Vec<Vec<u32>> = Vec::new();
    let mut used: Vec<std::collections::HashSet<u32>> = Vec::new();
    for (col, rows) in rows_by_col.iter().enumerate() {
        let free =
            colors.iter().enumerate().position(|(c, _)| !rows.iter().any(|row| used[c].contains(row)));
        let c = match free {
            Some(c) => c,
            None => {
                colors.push(Vec::new());
                used.push(std::collections::HashSet::new());
                colors.len() - 1
            }
        };
        colors[c].push(col as u32);
        used[c].extend(rows.iter().copied());
    }
    colors
}

/// The solvers a Model Exchange run can use. `gbode`, CVODE and IDA bring their
/// own step-size control and root search; the fixed-step ones step the output
/// grid and bisect afterwards.
enum Integrator {
    Dassl(Box<Dassl>),
    Gbode(Box<Gbode>),
    Fixed(FixedStep),
    #[cfg(sundials)]
    Cvode(Box<CvodeOde>),
    #[cfg(sundials)]
    Ida(Box<IdaOde>),
    /// DAE mode: IDA over the residuals, `y` carrying the algebraic variables too.
    #[cfg(sundials)]
    IdaDae(Box<IdaDae>),
}

impl Integrator {
    #[allow(clippy::too_many_arguments)]
    fn new(
        solver: Solver,
        nx: usize,
        nz: usize,
        tolerance: f64,
        nominals: &[f64],
        jac_colors: usize,
        directional: bool,
        n_alg: Option<usize>,
    ) -> Result<Integrator> {
        if let Some(n_alg) = n_alg {
            if solver != Solver::Ida {
                return Err(Error::Unsupported(format!(
                    "integrating in DAE mode with `{}`: only IDA takes a residual form",
                    solver.as_str()
                )));
            }
            #[cfg(sundials)]
            return Ok(Integrator::IdaDae(Box::new(IdaDae::new(nx, n_alg, nz, tolerance, nominals))));
            #[cfg(not(sundials))]
            return Err(Error::Unsupported("`ida`: this build has no SUNDIALS".to_string()));
        }
        // With no continuous states there is nothing to integrate and nothing
        // for gbode's Newton matrix to factor: every solver degenerates to
        // stepping from event to event, which the fixed-step one already does.
        let solver = if nx == 0 { Solver::Euler } else { solver };
        Ok(match solver {
            Solver::Dassl => Integrator::Dassl(Box::new(Dassl::new(nx, nz, tolerance, nominals))),
            Solver::Gbode => {
                let gb = Gbode::new(nx, tolerance, nz, jac_colors, directional)
                    .map_err(|e| Error::Unsupported(format!("this solver configuration: {e}")))?;
                Integrator::Gbode(Box::new(gb))
            }
            Solver::Euler => Integrator::Fixed(FixedStep::new(FixedKind::Euler, nx, nz)),
            Solver::RungeKutta => {
                Integrator::Fixed(FixedStep::new(FixedKind::RungeKutta, nx, nz))
            }
            #[cfg(sundials)]
            Solver::Cvode => {
                Integrator::Cvode(Box::new(CvodeOde::new(nx, nz, tolerance, nominals)))
            }
            #[cfg(sundials)]
            Solver::Ida => Integrator::Ida(Box::new(IdaOde::new(nx, nz, tolerance, nominals))),
            // Unreachable through `Solver::all`, which does not offer them here.
            #[cfg(not(sundials))]
            Solver::Cvode | Solver::Ida => {
                return Err(Error::Unsupported(format!(
                    "`{}`: this build has no SUNDIALS",
                    solver.as_str()
                )));
            }
        })
    }

    fn set_experiment(&mut self, opts: &Options<'_>) {
        if let Integrator::Gbode(gb) = self {
            gb.set_experiment(opts.start_time, opts.stop_time, opts.step_size);
        }
    }

    /// The derivatives DASKR sizes its first step against.
    fn set_derivatives(&mut self, yp: &[f64]) {
        if let Integrator::Dassl(d) = self {
            d.set_derivatives(yp);
        }
    }

    fn set_nominals(&mut self, nominals: &[f64]) {
        match self {
            Integrator::Gbode(gb) => gb.set_nominals(nominals),
            #[cfg(sundials)]
            Integrator::Cvode(cv) => cv.set_nominals(nominals),
            #[cfg(sundials)]
            Integrator::Ida(ida) => ida.set_nominals(nominals),
            #[cfg(sundials)]
            Integrator::IdaDae(ida) => ida.set_nominals(nominals),
            _ => {}
        }
    }

    /// DAE mode: make `(y, y')` consistent at `t` (`IDACalcIC`), so the point
    /// reported next is one the residuals hold at. Nothing for an ODE.
    fn make_consistent(&mut self, ode: &mut FmuOde, t: f64, y: &mut [f64], yp: &mut [f64]) -> Result<()> {
        #[cfg(sundials)]
        if let Integrator::IdaDae(ida) = self {
            ida.make_consistent(ode, t, y, yp).map_err(|e| ode.failure.take().unwrap_or(Error::Solver(e)))?;
        }
        #[cfg(not(sundials))]
        let _ = (ode, t, y, yp);
        Ok(())
    }

    /// Integrate toward `target`, stopping at `limit` (the next time event) or
    /// at a state event.
    fn step(
        &mut self,
        ode: &mut FmuOde,
        target: f64,
        limit: f64,
        t: &mut f64,
        y: &mut [f64],
        yp: &mut [f64],
    ) -> openmodelica_solvers::Result<Option<f64>> {
        match self {
            Integrator::Dassl(d) => match d.step(ode, target.min(limit), t, y)? {
                DasslStep::Root(te) => Ok(Some(te)),
                DasslStep::Reached | DasslStep::Stepped => Ok(None),
            },
            Integrator::Gbode(gb) => match gb.step(ode, target, limit, t, y)? {
                GbStep::Root(te) => Ok(Some(te)),
                GbStep::Reached | GbStep::Stepped => Ok(None),
            },
            Integrator::Fixed(fs) => match fs.step(ode, t, y, yp, target.min(limit))? {
                StepEnd::Root(te) => Ok(Some(te)),
                StepEnd::Reached => Ok(None),
            },
            #[cfg(sundials)]
            Integrator::Cvode(cv) => match cv.step(ode, target.min(limit), t, y)? {
                SunStep::Root(te) => Ok(Some(te)),
                SunStep::Reached => Ok(None),
            },
            #[cfg(sundials)]
            Integrator::Ida(ida) => match ida.step(ode, target.min(limit), t, y)? {
                SunStep::Root(te) => Ok(Some(te)),
                SunStep::Reached => Ok(None),
            },
            #[cfg(sundials)]
            Integrator::IdaDae(ida) => match ida.step(ode, target.min(limit), t, y, yp)? {
                SunStep::Root(te) => Ok(Some(te)),
                SunStep::Reached => Ok(None),
            },
        }
    }

    /// The step history is invalid after an event changed the states.
    fn restart(&mut self) {
        match self {
            Integrator::Dassl(d) => d.restart(),
            Integrator::Gbode(gb) => gb.restart(),
            Integrator::Fixed(_) => {}
            #[cfg(sundials)]
            Integrator::Cvode(cv) => cv.restart(),
            #[cfg(sundials)]
            Integrator::Ida(ida) => ida.restart(),
            #[cfg(sundials)]
            Integrator::IdaDae(ida) => ida.restart(),
        }
    }

    /// Iteration matrices assembled, for the solvers that assemble one.
    fn jacobians(&self) -> u64 {
        match self {
            Integrator::Dassl(d) => d.jacobians,
            Integrator::Gbode(gb) => gb.stats().calls_jacobian,
            Integrator::Fixed(_) => 0,
            #[cfg(sundials)]
            Integrator::Cvode(cv) => cv.counters().jac_evals,
            #[cfg(sundials)]
            Integrator::Ida(ida) => ida.counters().jac_evals,
            #[cfg(sundials)]
            Integrator::IdaDae(ida) => ida.counters().jac_evals,
        }
    }

    fn steps(&self) -> u64 {
        match self {
            Integrator::Dassl(d) => d.steps,
            Integrator::Gbode(gb) => gb.stats().steps,
            Integrator::Fixed(fs) => fs.steps,
            #[cfg(sundials)]
            Integrator::Cvode(cv) => cv.counters().steps,
            #[cfg(sundials)]
            Integrator::Ida(ida) => ida.counters().steps,
            #[cfg(sundials)]
            Integrator::IdaDae(ida) => ida.counters().steps,
        }
    }
}

/// Drive a Model Exchange FMU from `start_time` to `stop_time`.
pub fn simulate(
    inst: &mut dyn Fmi3ModelExchange,
    md: &ModelDescription,
    opts: &Options<'_>,
) -> Result<Run> {
    let mut inputs = Inputs::new(opts);
    let mut rec = Recorder::new(md, opts.keep);
    if let Some(m) = &opts.dae {
        let common: &mut dyn Fmi3 = inst;
        common.enter_configuration_mode()?;
        common.set_numeric(VarType::Boolean, &[m.enable_vr], &[1.0])?;
        common.exit_configuration_mode()?;
    }
    {
        let common: &mut dyn Fmi3 = inst;
        initialize(common, md, &mut inputs, opts)?;
    }
    // Exiting Initialization Mode leaves a Model Exchange FMU in Event Mode.
    let mut info = {
        let common: &mut dyn Fmi3 = inst;
        event_iteration(common)?
    };
    if info.terminate {
        return Err(Error::TerminatedAtInit);
    }
    inst.enter_continuous_time_mode()?;

    // The FMU's own counts win over the model description's, since an FMU with
    // structural parameters can have fewer states than the description lists.
    let nx = inst
        .get_number_of_continuous_states()
        .unwrap_or(md.number_of_continuous_states() as usize);
    let nz = inst
        .get_number_of_event_indicators()
        .unwrap_or(md.number_of_event_indicators as usize);

    let dae = opts.dae.as_ref().map(|m| dae_vrs(md, m, nx)).transpose()?;
    let n_alg = dae.as_ref().map(|d| d.alg_vrs.len());
    let ny = nx + n_alg.unwrap_or(0);
    let mut x = vec![0.0; ny];
    // Where the fixed-step solvers and IDA in DAE mode leave the derivatives.
    let mut xp = vec![0.0; ny];
    inst.get_continuous_states(&mut x[..nx])?;
    let mut nominals = vec![1.0; nx];
    if inst.get_nominals_of_continuous_states(&mut nominals).is_err() {
        nominals.fill(1.0);
    }
    if let Some(d) = &dae {
        for &vr in &d.alg_vrs {
            let nom = md.variable_by_vr(vr).and_then(|v| v.nominal).map(f64::abs).filter(|n| *n > 0.0);
            nominals.push(nom.unwrap_or(1.0));
        }
    }

    let states = md.continuous_states();
    let (colors, rows_by_col) = jacobian_sparsity(md, nx);
    // `<ContinuousStateDerivative valueReference=…>` lists the derivatives in
    // the order the states are in, which is the order the Jacobian's rows are.
    let derivative_vrs: Vec<u32> = md
        .model_structure
        .continuous_state_derivatives
        .iter()
        .map(|u| u.value_reference)
        .collect();
    let directional = opts.directional_derivatives
        && dae.is_none()
        && md
            .interface(openmodelica_fmi::InterfaceKind::ModelExchange)
            .is_some_and(|i| i.provides_directional_derivatives)
        && derivative_vrs.len() == states.len()
        && !states.is_empty();

    let tolerance = opts.tolerance.unwrap_or(1e-6);
    let mut integrator =
        Integrator::new(opts.solver, nx, nz, tolerance, &nominals, colors.len(), directional, n_alg)?;
    integrator.set_experiment(opts);
    integrator.set_nominals(&nominals);

    let needs_completed_step = md
        .interface(openmodelica_fmi::InterfaceKind::ModelExchange)
        .is_some_and(|i| i.needs_completed_integrator_step);
    let mut ode = FmuOde {
        inst,
        inputs: &mut inputs,
        opts,
        nominals,
        colors,
        rows_by_col,
        derivative_vrs,
        state_vrs: states,
        directional,
        calls: 0,
        committed: None,
        dae,
        failure: None,
        discarded: false,
        deadline: Deadline::arm(opts),
        polls: 0,
    };
    let mut t = opts.start_time;
    if ode.dae.is_some() {
        ode.read_dae_point(&mut x, &mut xp)?;
        integrator.make_consistent(&mut ode, t, &mut x, &mut xp)?;
        ode.commit_point(t, &x, &xp)?;
    } else if nx > 0 {
        ode.inst.get_continuous_state_derivatives(&mut xp[..nx])?;
        integrator.set_derivatives(&xp[..nx]);
    }
    {
        let common: &mut dyn Fmi3 = ode.inst;
        rec.snapshot_parameters(common)?;
        rec.sample(common, t)?;
    }
    let mut next_event = info.next_event_time.unwrap_or(f64::INFINITY);
    let (mut state_events, mut time_events) = (0u64, 0u64);
    let mut event_times = Vec::new();
    let mut cancelled = false;
    let mut terminated_at = None;
    // C's `storeOldValues`.
    let mut x_old = vec![0.0; ny];
    let mut xp_old = vec![0.0; ny];
    let mut retries = 0u64;

    'grid: for target in opts.output_times().skip(1) {
        // C's `retry`: a discarded step is taken again to half way, that end is the
        // row, and the grid point is skipped.
        let mut halved: Option<f64> = None;
        let mut sampled = false;
        while t < target - grid_epsilon(opts) {
            // A time event caps the step: the FMU must be asked at exactly that
            // time, never stepped past it.
            let limit = next_event.max(t);
            let end = halved.unwrap_or(target);
            let t_old = t;
            x_old.copy_from_slice(&x);
            xp_old.copy_from_slice(&xp);
            ode.discarded = false;
            // DASKR refuses a `tout` it is standing on, so a time event already
            // due is handled where it stands.
            let due = next_event <= t + grid_epsilon(opts);
            let stepped = (|| -> Result<(Option<f64>, bool, bool)> {
                if due {
                    return Ok((None, false, false));
                }
                let root = integrator
                    .step(&mut ode, end, limit, &mut t, &mut x, &mut xp)
                    .map_err(|e| ode.failure.take().unwrap_or(Error::Solver(e)))?;
                let mut event_at = root;
                let mut terminate = false;
                // C's `completedIntegratorStep`: the FMU may want Event Mode for a
                // reason the indicators do not show.
                if needs_completed_step {
                    ode.commit_point(t, &x, &xp)?;
                    let done = ode.inst.completed_integrator_step(true)?;
                    terminate = done.terminate;
                    if done.enter_event_mode {
                        event_at = Some(t);
                    }
                }
                // The end of an event-free step is a row (C's `simulationUpdate`).
                let reached = event_at.is_none()
                    && next_event > t + grid_epsilon(opts)
                    && t >= end - grid_epsilon(opts);
                if reached {
                    ode.commit_point(end, &x, &xp)?;
                    t = end;
                    let common: &mut dyn Fmi3 = ode.inst;
                    rec.sample(common, t)?;
                }
                Ok((event_at, terminate, reached))
            })();
            let (mut event_at, terminate, reached) = match stepped {
                Ok(v) => v,
                Err(e) if halved.is_none() && (ode.discarded || is_discard(&e)) => {
                    // C's `retrySimulationStep`: back to the accepted point.
                    retries += 1;
                    t = t_old;
                    x.copy_from_slice(&x_old);
                    xp.copy_from_slice(&xp_old);
                    ode.forget_point();
                    integrator.restart();
                    halved = Some(t + 0.5 * (end - t));
                    continue;
                }
                Err(e) if ode.discarded || is_discard(&e) => {
                    // C's catch with `retry` already spent.
                    return Err(Error::Simulation(format!(
                        "model terminate | Simulation terminated by an assert at time: {t_old}"
                    )));
                }
                Err(e) => return Err(e),
            };
            if terminate {
                terminated_at = Some(t);
                break 'grid;
            }
            if event_at.is_none() && next_event <= t + grid_epsilon(opts) {
                event_at = Some(next_event);
                time_events += 1;
            } else if event_at.is_some() {
                state_events += 1;
            }

            let Some(te) = event_at else {
                if reached {
                    sampled = true;
                    break;
                }
                continue;
            };
            // C clears `retry` with every accepted step, an event step included.
            halved = None;
            t = te;
            event_times.push(te);
            ode.commit_point(t, &x, &xp)?;
            ode.forget_point();
            {
                let common: &mut dyn Fmi3 = ode.inst;
                rec.sample(common, t)?;
                common.enter_event_mode()?;
                info = event_iteration(common)?;
                if ode.dae.is_none() {
                    rec.sample(common, t)?;
                }
            }
            if info.states_changed && nx > 0 {
                ode.inst.get_continuous_states(&mut x[..nx])?;
            }
            if info.nominals_changed && nx > 0 {
                let mut n = vec![1.0; nx];
                if ode.inst.get_nominals_of_continuous_states(&mut n).is_ok() {
                    integrator.set_nominals(&n);
                    ode.nominals = n;
                }
            }
            next_event = info.next_event_time.unwrap_or(f64::INFINITY);
            ode.inst.enter_continuous_time_mode()?;
            ode.forget_point();
            integrator.restart();
            if ode.dae.is_some() {
                // C's `ida_event_update`, before the row after the event.
                ode.read_dae_point(&mut x, &mut xp)?;
                integrator.make_consistent(&mut ode, t, &mut x, &mut xp)?;
                ode.commit_point(t, &x, &xp)?;
                let common: &mut dyn Fmi3 = ode.inst;
                rec.sample(common, t)?;
            } else if nx > 0 {
                ode.inst.get_continuous_state_derivatives(&mut xp[..nx])?;
                integrator.set_derivatives(&xp[..nx]);
            }
            if info.terminate {
                terminated_at = Some(t);
                break 'grid;
            }
        }
        if !sampled {
            // The grid point itself: the solver interpolated the states onto it.
            ode.commit_point(target, &x, &xp)?;
            t = target;
            let common: &mut dyn Fmi3 = ode.inst;
            rec.sample(common, t)?;
        }
        if let Some(report) = opts.progress {
            report(t, &rec);
        }
        if opts.cancelled.is_some_and(|stop| stop()) {
            cancelled = true;
            break 'grid;
        }
        if ode.deadline.expired() {
            return Err(Error::Alarm);
        }
    }

    let calls = ode.calls;
    let (steps, jacobians) = (integrator.steps(), integrator.jacobians());
    let common: &mut dyn Fmi3 = ode.inst;
    common.terminate()?;
    Ok(Run {
        recorder: rec,
        terminated_at,
        cancelled,
        steps,
        calls,
        jacobians,
        state_events,
        time_events,
        event_times,
        retries,
    })
}

/// Times this close to an output point count as having reached it.
fn grid_epsilon(opts: &Options<'_>) -> f64 {
    (opts.stop_time - opts.start_time).abs() * 1e-12
}
