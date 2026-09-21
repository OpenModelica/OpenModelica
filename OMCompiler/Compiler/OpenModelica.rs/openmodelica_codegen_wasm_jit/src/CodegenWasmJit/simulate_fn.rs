//! The in-wasm `simulate` loop and the result-column selection.

use super::*;

/// Emit the in-wasm forward-Euler integrator loop:
/// `simulate(sim_data, start, stop, n_steps) -> result_buffer`. The caller
/// (`driver::run_wasm`) has initialized the model, so this starts at row 0.
/// `check_asserts` is `functionCheckAsserts` when the model has any min/max check.
pub(super) fn build_simulate(layout: &SimLayout, eqfn: &EqFnIdx, check_asserts: Option<u32>) -> Result<we::Function> {
    // Params: 0 sim_data(i32), 1 start(f64), 2 stop(f64), 3 n_steps(i32).
    // Locals: 4 buf(i32), 5 h(f64), 6 row(i32).
    const SIM_DATA: u32 = 0;
    const START: u32 = 1;
    const STOP: u32 = 2;
    const N_STEPS: u32 = 3;
    const BUF: u32 = 4;
    const H: u32 = 5;
    const ROW: u32 = 6;
    const DEST: u32 = 7;

    let n_reals = layout.n_reals_row();
    let n_total = layout.n_row_total();
    let n_states = layout.n_states;
    // locals: BUF(i32), H(f64), ROW(i32), DEST(i32)
    let mut f = we::Function::new([(1, we::ValType::I32), (1, we::ValType::F64), (2, we::ValType::I32)]);
    use we::Instruction as I;

    // buf = rt_alloc((n_steps + 1) * n_total * 8)
    f.instruction(&I::LocalGet(N_STEPS));
    f.instruction(&I::I32Const(1));
    f.instruction(&I::I32Add);
    f.instruction(&I::I32Const((n_total * 8) as i32));
    f.instruction(&I::I32Mul);
    f.instruction(&I::Call(rt_index("rt_alloc")?));
    f.instruction(&I::LocalSet(BUF));

    // h = (stop - start) / max(n_steps, 1): `stopTime <= startTime` takes no step.
    f.instruction(&I::LocalGet(STOP));
    f.instruction(&I::LocalGet(START));
    f.instruction(&I::F64Sub);
    f.instruction(&I::LocalGet(N_STEPS));
    f.instruction(&I::F64ConvertI32S);
    f.instruction(&I::F64Const(1.0.into()));
    f.instruction(&I::F64Max);
    f.instruction(&I::F64Div);
    f.instruction(&I::LocalSet(H));

    // row = 0
    f.instruction(&I::I32Const(0));
    f.instruction(&I::LocalSet(ROW));

    // block { loop {
    f.instruction(&I::Block(we::BlockType::Empty));
    f.instruction(&I::Loop(we::BlockType::Empty));

    // time = start + row * h
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::LocalGet(START));
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::F64ConvertI32S);
    f.instruction(&I::LocalGet(H));
    f.instruction(&I::F64Mul);
    f.instruction(&I::F64Add);
    f.instruction(&I::F64Store(crate::CodegenWasmJitFunctions::mem_arg(TIME_OFF, 3)));

    // Row 0 is the initialized point: capture it without re-evaluating, as C does
    // after `initializeModel` (a second pass would repeat the equations' side
    // effects). Every later row is evaluated at its time.
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::If(we::BlockType::Empty));

    // C's terminal step is a row of its own (`emit_terminal_row`), so no row here
    // raises the flag.

    // functionODE(sim_data); functionAlgebraics(sim_data)
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::Call(eqfn.ode));
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::Call(eqfn.algebraics));

    f.instruction(&I::End); // if row != 0

    // Store the row at dest = buf + row * n_total * 8:
    //   - copy the real part [time | realVars] (contiguous from sim_data[0])
    //   - then each integer / boolean algebraic slot, converted i32 -> f64
    f.instruction(&I::LocalGet(BUF));
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::I32Const((n_total * 8) as i32));
    f.instruction(&I::I32Mul);
    f.instruction(&I::I32Add);
    f.instruction(&I::LocalSet(DEST));
    // memory.copy(dest, sim_data, n_reals*8)
    f.instruction(&I::LocalGet(DEST));
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::I32Const((n_reals * 8) as i32));
    f.instruction(&I::MemoryCopy { src_mem: 0, dst_mem: 0 });
    let store_islot = |f: &mut we::Function, src_off: u32, dst_col: u32| {
        f.instruction(&I::LocalGet(DEST));
        f.instruction(&I::LocalGet(SIM_DATA));
        f.instruction(&I::I32Load(crate::CodegenWasmJitFunctions::mem_arg(src_off, 2)));
        f.instruction(&I::F64ConvertI32S);
        f.instruction(&I::F64Store(crate::CodegenWasmJitFunctions::mem_arg(dst_col * 8, 3)));
    };
    for i in 0..layout.n_int_alg() {
        store_islot(&mut f, layout.int_off + i * 4, n_reals + i);
    }
    for j in 0..layout.n_bool_alg() {
        store_islot(&mut f, layout.bool_off + j * 4, n_reals + layout.n_int_alg() + j);
    }
    // The raw String handles keep the row width; the driver never takes this path
    // with String results (they need interning at capture).
    for i in 0..layout.n_str_alg() {
        store_islot(&mut f, layout.str_off + i * 4, layout.str_col0() + i);
    }
    // Only IDA fills the sensitivity block, and this loop is Euler's.
    if layout.n_sens > 0 {
        f.instruction(&I::LocalGet(DEST));
        f.instruction(&I::I32Const((layout.sens_col0() * 8) as i32));
        f.instruction(&I::I32Add);
        f.instruction(&I::I32Const(0));
        f.instruction(&I::I32Const((layout.n_sens * 8) as i32));
        f.instruction(&I::MemoryFill(0));
    }

    // The driver's per-row `check_asserts`: evaluate the min/max checks, then let
    // the host format what they recorded while `time` still holds this row's.
    // Level `warning` for the first and the terminal row, `info` in between.
    if let Some(idx) = check_asserts {
        f.instruction(&I::LocalGet(SIM_DATA));
        f.instruction(&I::Call(idx));
    }
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::I32Eqz);
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::LocalGet(N_STEPS));
    f.instruction(&I::I32Eq);
    f.instruction(&I::I32Or);
    f.instruction(&I::Call(crate::CodegenWasmJitFunctions::env_extra_index("rt_row_asserts")?));
    f.instruction(&I::BrIf(1)); // a suppressed assert ends the run; `run_wasm` throws

    // if terminate() fired this step (functionAlgebraics raised the flag): break,
    // keeping the row just stored as the last one.
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::I32Load(crate::CodegenWasmJitFunctions::mem_arg(layout.terminate_off, 2)));
    f.instruction(&I::BrIf(1)); // branch out of the loop to the block end

    // if a nonlinear system failed to converge: break too (the host `run_wasm`
    // reads the flag afterward and reports it — Euler cannot back off the step).
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::I32Load(crate::CodegenWasmJitFunctions::mem_arg(layout.nls_fail_off, 2)));
    f.instruction(&I::BrIf(1));

    // if row >= n_steps: break (exit the block)
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::LocalGet(N_STEPS));
    f.instruction(&I::I32GeS);
    f.instruction(&I::BrIf(1)); // branch out of the loop to the block end

    // rt_euler_step(sim_data, n_states, h)
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::I32Const(n_states as i32));
    f.instruction(&I::LocalGet(H));
    f.instruction(&I::Call(rt_index("rt_euler_step")?));

    // row += 1; continue
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::I32Const(1));
    f.instruction(&I::I32Add);
    f.instruction(&I::LocalSet(ROW));
    f.instruction(&I::Br(0));

    f.instruction(&I::End); // loop
    f.instruction(&I::End); // block

    // Record how many rows were written (row + 1), so the host driver reads only
    // the produced rows after an early terminate (full run: n_steps + 1).
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::I32Const(1));
    f.instruction(&I::I32Add);
    f.instruction(&I::I32Store(crate::CodegenWasmJitFunctions::mem_arg(layout.n_out_off, 2)));

    // return buf
    f.instruction(&I::LocalGet(BUF));
    f.instruction(&I::End); // function
    Ok(f)
}

/// Write the simulation result as an OpenModelica MATLAB v4 (`.mat`) file.
/// Which result variables this run emits, one flag per [`SimModel::result_vars`]
/// entry. An uncompilable `-variableFilter` is C's "Defaulting to outputting all
/// variables": it has already replaced the model's filter, so nothing remains to
/// fall back on.
pub(super) fn output_selection(model: &SimModel) -> Vec<bool> {
    let Some(pattern) = simflags::with_flags(|f| f.variable_filter.clone()) else {
        return model.meta.output_keep(None);
    };
    match openmodelica_util::System::Regex::new(&format!("^({pattern})$")) {
        Ok(re) => model.meta.output_keep(Some(&|name: &str| re.is_match(name))),
        Err(e) => {
            eprintln!(
                "Failed to compile regular expression: {pattern} with error: {e}. \
                 Defaulting to outputting all variables."
            );
            model.meta.output_keep(Some(&|_: &str| true))
        }
    }
}
