//! QSS1, the Quantized State System solver of C's
//! `simulation/solver/perform_qss_simulation.c.inc`.
//!
//! Every state carries its own quantum `dQ` (nominal·10⁻⁴), its own timestamp and
//! its own time of next change; the solver repeatedly advances the state that
//! changes first by one quantum and re-evaluates only the derivatives the ODE
//! Jacobian's sparsity says depend on it. There is no output grid: one result row
//! is emitted per accepted quantum change, at that change's own time.

use alloc::format;
use alloc::vec;
use alloc::vec::Vec;

use crate::driver::{
    Advance, Driver, Result, SimEngine, cancel_requested, capture_row, check_alarm, check_nls,
    deadline_from, emit_initial_row, eval_continuous, format_f, past_deadline, read_f64,
    store_operators, terminated, write_f64, write_i32,
};
use crate::omclog;
use crate::{JacAInfo, Layout as SimLayout, REAL_OFF, SimMeta as SimModel, SolveStats, TIME_OFF};

/// C's `enum error_msg` as this runtime's error strings. `OO_MEMORY` has no
/// counterpart: allocation failure aborts here.
const ISNAN: &str = "CodegenWasmJit: qss: the time of next change is NaN";
const UNKNOWN: &str = "CodegenWasmJit: qss: no ODE Jacobian sparse pattern";

const EPS: f64 = 1e-15;

/// C's `performQSSSimulation` locals, held across `advance` calls so a resumed
/// chunk continues the exact same continuation.
pub(crate) struct Qss {
    sim_data: u32,
    /// C's `solverInfo->currentTime`.
    current_time: f64,
    /// C's `simInfo->stopTime`, which `terminate()` moves to the current time.
    stop_time: f64,
    /// Approximation of states
    qik: Vec<f64>,
    /// states
    xik: Vec<f64>,
    /// Derivative of states
    der_xik: Vec<f64>,
    /// Time of approximation, because not all approximations are calculated at a
    /// specific time, each approx. has its own timestamp
    tq: Vec<f64>,
    /// Time of the states, because not all states are calculated at a specific
    /// time, each state has its own timestamp
    tx: Vec<f64>,
    /// Time of the next change in state
    tqp: Vec<f64>,
    /// next value of the state
    nqh: Vec<f64>,
    /// change in quantity of every state, default = nominal*10^-4
    dq: Vec<f64>,
    /// Derivatives which are influenced by the state being advanced, and how many
    /// of them there are (C's `der`/`numDer`).
    der: Vec<usize>,
    num_der: usize,
    /// `leadindex`/`index` of the ODE Jacobian's sparse pattern: the derivatives
    /// each state occurs in.
    rows_by_col: Vec<Vec<u32>>,
    curr_step_no: u64,
    rows: Vec<f64>,
}

impl Qss {
    pub(crate) fn new(e: &mut dyn SimEngine, model: &SimModel, sim_data: u32) -> Result<Self> {
        let layout = &model.layout;
        let states = layout.n_states as usize;

        crate::driver::run_initialization_model(e, sim_data, model)?;
        // C emits the initial row from `solver_main` before it enters the loop.
        let mut rows = Vec::new();
        emit_initial_row(e, &mut rows, sim_data, layout, model.start_time)?;

        omclog::warning(
            omclog::STDOUT,
            false,
            "This QSS method is under development and should not be used yet.",
        );

        // C's `initialAnalyticJacobianA`: without the pattern there is nothing to
        // tell which derivatives a state occurs in.
        let Some(jac) = model.jac_a.as_ref() else {
            omclog::info(
                omclog::STDOUT,
                false,
                "Jacobian or sparse pattern is not generated or failed to initialize.",
            );
            return Err(UNKNOWN);
        };
        print_sparse_structure(jac, omclog::SOLVER, "ODE sparse pattern");

        let mut qss = Qss {
            sim_data,
            current_time: model.start_time,
            stop_time: model.stop_time,
            qik: vec![0.0; states],
            xik: vec![0.0; states],
            der_xik: vec![0.0; states],
            tq: vec![0.0; states],
            tx: vec![0.0; states],
            tqp: vec![0.0; states],
            nqh: vec![0.0; states],
            dq: vec![0.0; states],
            // Transform the sparsity pattern into a data structure for an index
            // based access. (QSS2 or higher would also need the reverse map: which
            // states occur in each derivative.)
            der: vec![0; jac.rows_by_col.len()],
            num_der: 0,
            rows_by_col: jac.rows_by_col.clone(),
            curr_step_no: 0,
            rows,
        };

        // further initialization of local variables
        for i in 0..states {
            let nominal = read_f64(e, sim_data + layout.real_nominal_off(i as u32))?;
            qss.dq[i] = 0.0001 * nominal;
            qss.tx[i] = model.start_time;
            qss.tq[i] = model.start_time;
            qss.qik[i] = read_f64(e, state_addr(sim_data, i))?;
            qss.xik[i] = qss.qik[i];
            qss.der_xik[i] = read_f64(e, der_addr(sim_data, layout, i))?;
            let (d_tnext_q, next_q, _) = delta_q(e, sim_data, layout, qss.dq[i], i)?;
            qss.tqp[i] = qss.tq[i] + d_tnext_q;
            qss.nqh[i] = next_q;
        }
        Ok(qss)
    }

    /// Returns the indices of all derivatives with state k inside.
    fn get_der_with_state_k(&mut self, k: usize) {
        let mut j = 0;
        for &row in &self.rows_by_col[k] {
            self.der[j] = row as usize;
            j += 1;
        }
        self.num_der = j;
    }
}

impl Driver for Qss {
    fn advance(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        budget_ms: f64,
    ) -> Result<Advance> {
        let layout = &model.layout;
        let sim_data = self.sim_data;
        let states = layout.n_states as usize;
        let deadline = deadline_from(budget_ms);
        let mut did_step = false;

        // Start main simulation loop
        while self.current_time < self.stop_time {
            if did_step && past_deadline(deadline) {
                return Ok(Advance::Running);
            }
            check_alarm()?;
            if cancel_requested() {
                return Ok(Advance::Cancelled);
            }
            did_step = true;
            self.curr_step_no += 1;

            let ind = min_step(&self.tqp);

            if self.tqp[ind].is_nan() {
                return Err(ISNAN);
            }
            if self.tqp[ind].is_infinite() {
                // If all derivatives are zero, the states stay constant and only
                // the time propagates till stop->time.
                omclog::warning(
                    omclog::STDOUT,
                    false,
                    &format!(
                        "All derivatives are zero at time {}!.",
                        format_f(read_f64(e, sim_data + TIME_OFF)?)
                    ),
                );
                self.current_time = self.stop_time;
                write_f64(e, sim_data + TIME_OFF, self.current_time)?;

                continue;
            }

            self.qik[ind] = self.nqh[ind];

            self.xik[ind] = self.qik[ind];
            write_f64(e, state_addr(sim_data, ind), self.qik[ind])?;

            self.tx[ind] = self.tqp[ind];
            self.tq[ind] = self.tqp[ind];

            self.current_time = self.tqp[ind];

            // the state[ind] will change again in dTnextQ
            let (d_tnext_q, next_q, _) = delta_q(e, sim_data, layout, self.dq[ind], ind)?;
            self.tqp[ind] = self.tq[ind] + d_tnext_q;
            self.nqh[ind] = next_q;

            // get the derivatives depending on state[ind]
            self.get_der_with_state_k(ind);

            for k in 0..self.num_der {
                let j = self.der[k];
                if j != ind {
                    self.xik[j] += self.der_xik[j] * (self.current_time - self.tx[j]);
                    write_f64(e, state_addr(sim_data, j), self.xik[j])?;
                    self.tx[j] = self.current_time;
                }
            }

            // Recalculate all equations which are affected by state[ind].
            // Unfortunately all equations will be calculated up to now. And we need
            // to evaluate the equations as f(t,q) and not f(t,x). So all states were
            // saved onto a local stack and overwritten by q. After evaluating the
            // equations the states are written back.
            for i in 0..states {
                self.xik[i] = read_f64(e, state_addr(sim_data, i))?; // save current state
                // overwrite current state for dx/dt = f(t,q)
                write_f64(e, state_addr(sim_data, i), self.qik[i])?;
            }

            // update continous system. The QSS loop does not open C's
            // `noThrowAsserts` window, so a violated assert ends the run here.
            // `nls_fail` is C's per-solve `solved` flag: only this point's solve
            // may fail the step.
            write_i32(e, sim_data + layout.nls_fail_off, 0)?;
            write_f64(e, sim_data + TIME_OFF, self.current_time)?;
            eval_continuous(e, sim_data, layout)?;
            store_operators(e, sim_data, layout)?;

            for i in 0..states {
                write_f64(e, state_addr(sim_data, i), self.xik[i])?; // restore current state
            }

            // Get derivatives affected by state[ind] and write back ALL
            // derivatives. After that we have states and derivatives for different
            // times tx.
            for k in 0..self.num_der {
                let j = self.der[k];
                self.der_xik[j] = read_f64(e, der_addr(sim_data, layout, j))?;
            }
            // not in every case part of the above derivatives
            self.der_xik[ind] = read_f64(e, der_addr(sim_data, layout, ind))?;

            for i in 0..states {
                // write back all derivatives
                write_f64(e, der_addr(sim_data, layout, i), self.der_xik[i])?;
            }

            // recalculate the time of next change only for the affected states
            for k in 0..self.num_der {
                let j = self.der[k];
                let (d_tnext_q, next_q, _) = delta_q(e, sim_data, layout, self.dq[j], j)?;
                self.tqp[j] = self.current_time + d_tnext_q;
                self.nqh[j] = next_q;
            }

            capture_row(e, &mut self.rows, sim_data, layout)?;

            // check if terminate()=true
            if terminated(e, sim_data, layout)? {
                self.stop_time = self.current_time;
                return Ok(Advance::Terminated);
            }

            // terminate for some cases:
            // - non-linear system failed to solve
            // - assert was called
            check_nls(e, sim_data, layout)?;
        }
        // End of main loop
        Ok(Advance::Done)
    }

    fn take_rows(&mut self) -> Vec<f64> {
        core::mem::take(&mut self.rows)
    }

    fn fill_stats(&mut self, _model: &SimModel, stats: &mut SolveStats) {
        stats.steps = self.curr_step_no;
    }

    /// `timeValue` at the end of the loop, which the all-derivatives-are-zero
    /// shortcut leaves at `stopTime` while the last emitted row is older.
    fn terminal_time(&self) -> Option<f64> {
        Some(self.current_time)
    }
}

/// `SimData` address of state `i`.
fn state_addr(sim_data: u32, i: usize) -> u32 {
    sim_data + REAL_OFF + i as u32 * 8
}

/// `SimData` address of `der(state i)`.
fn der_addr(sim_data: u32, layout: &SimLayout, i: usize) -> u32 {
    sim_data + REAL_OFF + (layout.n_states + i as u32) * 8
}

/// Computes the next step in time and quantity for `state[index]`.
///
/// `dq` is the change of quantity for `state[index]`, (nominal value) * 10^-4.
/// Returns `dTnextQ` (the state will change after that many seconds), `nextQ` (the
/// next quantity reached by the state) and `diffQ` (the difference between the
/// state's current and future value).
fn delta_q(
    e: &dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    dq: f64,
    index: usize,
) -> Result<(f64, f64, f64)> {
    let x = read_f64(e, state_addr(sim_data, index))?;
    let state_der = read_f64(e, der_addr(sim_data, layout, index))?;

    let mut next_q;
    if state_der >= 0.0 {
        // quantity of the state will increase
        next_q = (libm::floor(x / dq) + 1.0) * dq;
        if next_q <= x + EPS {
            next_q += dq;
        }
    } else {
        next_q = libm::floor(x / dq) * dq;
        if next_q >= x - EPS {
            next_q -= dq;
        }
    }

    let diff_q = libm::fabs(next_q - x);
    let d_tnext_q = libm::fabs(diff_q / state_der);

    Ok((d_tnext_q, next_q, diff_q))
}

/// Finds the index of the state which will change first: `state[i]` will change in
/// time `tqp[i]`.
fn min_step(tqp: &[f64]) -> usize {
    let mut ind = 0;
    // We can have a QNAN at any index and tqp[i] < QNAN will fail in every case.
    let mut tmin = f64::INFINITY;

    for (i, &t) in tqp.iter().enumerate() {
        if t < tmin && !t.is_nan() {
            ind = i;
            tmin = t;
        }
    }
    ind
}

/// C's `printSparseStructure` (`model_help.c`) for a square Jacobian pattern.
fn print_sparse_structure(jac: &JacAInfo, stream: omclog::Stream, name: &str) {
    if !omclog::active(stream) {
        return;
    }
    let nnz: usize = jac.rows_by_col.iter().map(|r| r.len()).sum();
    omclog::info(stream, true, &format!("Sparse structure of {name} [size: {0}x{0}]", jac.n));
    omclog::info(stream, false, &format!("{nnz} non-zero elements"));

    omclog::info(stream, true, "Transposed sparse structure (rows: states)");
    for rows in &jac.rows_by_col {
        let mut buffer = alloc::string::String::new();
        for col in 0..rows.last().map_or(0, |&r| r + 1) {
            buffer.push(if rows.contains(&col) { '*' } else { ' ' });
            buffer.push(' ');
        }
        omclog::info(stream, false, &buffer);
    }
    omclog::close(stream);
    omclog::close(stream);
}
