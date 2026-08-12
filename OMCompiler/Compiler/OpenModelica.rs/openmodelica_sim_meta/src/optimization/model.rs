//! What the C optimizer does to `DATA` directly, done to the model's `SimData`.
//!
//! The C code swaps `data->localData[0..2]->realVars` between per-collocation-point
//! buffers and reads `data->simulationInfo->inputVars`. A wasm model has one live
//! real region (plus its `pre()` mirror), so a buffer swap becomes a copy in/out of
//! that region, and `inputVars` is a Vec here whose `input_function` writes the
//! input variables' slots.

use alloc::string::String;
use alloc::vec;
use alloc::vec::Vec;

use crate::driver::{self, SimEngine};
use crate::{Layout, OptInfo, OptJac, REAL_OFF, TIME_OFF};

/// The model handle the optimizer and its Ipopt callbacks evaluate through. Holds
/// the engine as a raw pointer because the callbacks reach it through Ipopt's
/// user-data pointer, exactly as the DASSL residual reaches its `ResCtx`.
pub struct Model {
    pub engine: *mut (dyn SimEngine + 'static),
    pub sim_data: u32,
    pub layout: Layout,
    /// Number of real variables (C's `nVariablesReal`): states, derivatives and
    /// algebraics, in that order — the same index space as C's `realVars`.
    pub n_real: usize,
    /// Live `inputVars` (C's `simulationInfo->inputVars`).
    pub inputs: Vec<f64>,
    /// Address of the runtime's evaluation-context word, for `setContext`.
    pub ctx_addr: u32,
    /// A wasm trap or memory error captured inside a callback, surfaced once Ipopt
    /// returns (the C-style callbacks cannot propagate a `Result`).
    pub err: Option<&'static str>,
}

impl Model {
    pub fn new(e: &mut (dyn SimEngine + 'static), sim_data: u32, layout: &Layout, n_inputs: usize) -> Self {
        let ctx_addr = e.context_addr();
        Model {
            engine: e as *mut _,
            sim_data,
            layout: *layout,
            n_real: (2 * layout.n_states + layout.n_real_alg) as usize,
            inputs: vec![0.0; n_inputs],
            ctx_addr,
            err: None,
        }
    }

    /// Borrow the engine. Sound for the lifetime of the optimizer run: the `&mut`
    /// it was built from outlives every callback Ipopt makes.
    #[allow(clippy::mut_from_ref)]
    fn e(&self) -> &mut (dyn SimEngine + 'static) {
        unsafe { &mut *self.engine }
    }

    /// Remember the first error and keep going, like the C callbacks do (they
    /// return TRUE regardless and let the next model call fail).
    fn note(&mut self, r: driver::Result<()>) {
        if let Err(e) = r
            && self.err.is_none()
        {
            self.err = Some(e);
        }
    }

    fn real_base(&self) -> u32 {
        self.sim_data + REAL_OFF
    }

    /// C's `memcpy(sData->realVars, …)` in both directions.
    pub fn read_reals(&mut self, out: &mut [f64]) {
        let base = self.real_base();
        let mut bytes = vec![0u8; out.len() * 8];
        let r = self.e().read_bytes(base, &mut bytes);
        self.note(r);
        for (v, c) in out.iter_mut().zip(bytes.chunks_exact(8)) {
            *v = f64::from_le_bytes(c.try_into().unwrap());
        }
    }

    pub fn write_reals(&mut self, vals: &[f64]) {
        let base = self.real_base();
        let bytes: Vec<u8> = vals.iter().flat_map(|v| v.to_le_bytes()).collect();
        let r = self.e().write_bytes(base, &bytes);
        self.note(r);
    }

    /// The `pre()` mirror of the real region, which `setLocalVars` seeds a
    /// collocation point's discrete variables from.
    pub fn read_pre_reals(&mut self, out: &mut [f64]) {
        let base = self.sim_data + self.layout.pre_real_off;
        let mut bytes = vec![0u8; out.len() * 8];
        let r = self.e().read_bytes(base, &mut bytes);
        self.note(r);
        for (v, c) in out.iter_mut().zip(bytes.chunks_exact(8)) {
            *v = f64::from_le_bytes(c.try_into().unwrap());
        }
    }

    pub fn read_real(&mut self, index: usize) -> f64 {
        let addr = self.real_base() + (index as u32) * 8;
        match driver::read_f64(self.e(), addr) {
            Ok(v) => v,
            Err(e) => {
                self.note(Err(e));
                0.0
            }
        }
    }

    pub fn write_real(&mut self, index: usize, v: f64) {
        let addr = self.real_base() + (index as u32) * 8;
        let r = driver::write_f64(self.e(), addr, v);
        self.note(r);
    }

    /// A raw `SimData` region, for the discrete-state snapshot.
    pub fn read_region(&mut self, off: u32, out: &mut [u8]) {
        let addr = self.sim_data + off;
        let r = self.e().read_bytes(addr, out);
        self.note(r);
    }

    pub fn write_region(&mut self, off: u32, bytes: &[u8]) {
        let addr = self.sim_data + off;
        let r = self.e().write_bytes(addr, bytes);
        self.note(r);
    }

    pub fn write_f64_at(&mut self, off: u32, v: f64) {
        let addr = self.sim_data + off;
        let r = driver::write_f64(self.e(), addr, v);
        self.note(r);
    }

    pub fn read_f64_at(&mut self, off: u32) -> f64 {
        let addr = self.sim_data + off;
        match driver::read_f64(self.e(), addr) {
            Ok(v) => v,
            Err(e) => {
                self.note(Err(e));
                0.0
            }
        }
    }

    pub fn read_i32_at(&mut self, off: u32) -> i32 {
        let addr = self.sim_data + off;
        match driver::read_i32(self.e(), addr) {
            Ok(v) => v,
            Err(e) => {
                self.note(Err(e));
                0
            }
        }
    }

    pub fn set_time(&mut self, t: f64) {
        let addr = self.sim_data + TIME_OFF;
        let r = driver::write_f64(self.e(), addr, t);
        self.note(r);
    }

    /// C's `input_function`: publish `inputVars` to the input variables' slots.
    pub fn input_function(&mut self, opt: &OptInfo) {
        for (k, &index) in opt.inputs.iter().enumerate() {
            let v = self.inputs[k];
            self.write_real(index as usize, v);
        }
    }

    /// C's generated `setInputData(data, file)`: read the input variables back into
    /// `inputVars`. With `from_file`, an `OPT_LOOP_INPUT` first takes the value of
    /// the variable that replaces it.
    pub fn set_input_data(&mut self, opt: &OptInfo, from_file: bool) {
        if from_file {
            for &(k, src) in &opt.loop_inputs {
                let v = self.read_real(src as usize);
                let dst = opt.inputs[k as usize] as usize;
                self.write_real(dst, v);
            }
        }
        for (k, &index) in opt.inputs.iter().enumerate() {
            self.inputs[k] = self.read_real(index as usize);
        }
    }

    /// C's `updateDiscreteSystem`: the discrete update run to a fixed point.
    pub fn update_discrete_system(&mut self) {
        let (sim_data, layout) = (self.sim_data, self.layout);
        let r = driver::iterate_discrete(self.e(), sim_data, &layout);
        self.note(r);
    }

    /// One symbolic Jacobian column set, C's `diffSynColoredOptimizerSystem` inner
    /// loop: seed the columns of one color with their nominal values, run the
    /// column equations, and read the rows the sparsity pattern lists.
    ///
    /// `out` is `n_rows × n_cols` row-major (C's `J[row][col]`), written only where
    /// the pattern has a nonzero — the caller keeps the rest.
    pub fn eval_jac_colored(
        &mut self,
        jac: &OptJac,
        vnom: &[f64],
        mut store: impl FnMut(usize, usize, f64),
    ) {
        let (sim_data, ctx) = (self.sim_data, self.ctx_addr);
        // C's `setContext(CONTEXT_SYM_JACOBIAN)`: a column is evaluated at perturbed
        // states, so the nonlinear solver must not record it as an initial guess.
        driver::set_context_jacobian(self.e(), ctx);
        if !jac.const_fn.is_empty() {
            let r = self.e().call1_if_present(&jac.const_fn, sim_data);
            self.note(r);
        }
        for color in &jac.colors {
            // Seeds: this color's columns at their nominal value, everything else 0.
            for (col, &off) in jac.seed_offs.iter().enumerate() {
                let v = if color.contains(&(col as u32)) { vnom[col] } else { 0.0 };
                let r = driver::write_f64(self.e(), sim_data + off, v);
                self.note(r);
            }
            let r = self.e().call1(&jac.column_fn, sim_data);
            self.note(r);
            for &col in color {
                for &row in &jac.rows_by_col[col as usize] {
                    let off = jac.result_offs[row as usize];
                    let v = self.read_f64_at(off);
                    store(row as usize, col as usize, v);
                }
            }
        }
        // C's `unsetContext` restores what the driver leaves standing between calls.
        driver::set_context_algebraic(self.e(), ctx);
    }

}
