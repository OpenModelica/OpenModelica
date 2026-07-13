//! Torn linear/nonlinear *simulation-equation* system lowering, split out of the
//! function-body lowering in the parent module. `compile_linear_system` assembles
//! and solves `A x = b` by residual probing (`rt_linsolve`); the `rt_solve_nls`
//! wiring (`emit_solve_nls_call` at the call site, `emit_nls_residual_body` /
//! `emit_nls_load_body` for the callbacks) lowers nonlinear systems to the runtime
//! Newton solver. A child module of `CodegenWasmJitFunctions`, so it reaches the
//! shared lowering primitives (`FnCtx`, `compile_exp`, `coerce`, `mem_arg`, …)
//! through `super::*` without widening their visibility.

use std::sync::Arc;

use metamodelica::Result;

use openmodelica_frontend_types::DAE;
use wasm_encoder as we;

use super::*;

/// Emit one residual evaluation for a torn linear system: run the inner
/// constraint equations (`lower_inner`), then store each residual `r_k` as an f64
/// at `base + dest_off + k*8`. Used by [`compile_linear_system`] for each probe.
fn emit_residual_eval(
    ctx: &mut FnCtx,
    base: u32,
    res_exps: &[&Arc<DAE::Exp>],
    dest_off: u32,
    lower_inner: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    lower_inner(ctx)?;
    for (k, exp) in res_exps.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(base));
        let w = compile_exp(ctx, exp)?;
        coerce(ctx, w, WTy::F64);
        ctx.emit(we::Instruction::F64Store(mem_arg(dest_off + (k as u32) * 8, 3)));
    }
    Ok(())
}

/// Emit the body of a nonlinear system's `residual(sim_data, x, r)` callback
/// (wasm locals: 0 = `SimData`, 1 = `x` pointer, 2 = `r` pointer). Copies the
/// `n` unknowns from `x` into their `slots`, runs the inner (torn) equations via
/// `lower_inner`, then stores each residual as an f64 at `r[i]`. Reached from
/// `rt_solve_nls` by `call_indirect`.
pub(crate) fn emit_nls_residual_body(
    ctx: &mut FnCtx,
    slots: &[u32],
    res_exps: &[Arc<DAE::Exp>],
    lower_inner: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    use we::Instruction as I;
    for (j, &off) in slots.iter().enumerate() {
        ctx.emit(I::LocalGet(0)); // SimData
        ctx.emit(I::LocalGet(1)); // x
        ctx.emit(I::F64Load(mem_arg((j as u32) * 8, 3)));
        ctx.emit(I::F64Store(mem_arg(off, 3)));
    }
    lower_inner(ctx)?;
    for (i, exp) in res_exps.iter().enumerate() {
        ctx.emit(I::LocalGet(2)); // r
        let w = compile_exp(ctx, exp)?;
        coerce(ctx, w, WTy::F64);
        ctx.emit(I::F64Store(mem_arg((i as u32) * 8, 3)));
    }
    Ok(())
}

/// Emit the body of a nonlinear system's `load(sim_data, x)` callback (wasm
/// locals: 0 = `SimData`, 1 = `x` pointer): copy the current unknown `slots` into
/// `x`, the warm start `rt_solve_nls` reads.
pub(crate) fn emit_nls_load_body(ctx: &mut FnCtx, slots: &[u32]) -> Result<()> {
    use we::Instruction as I;
    for (j, &off) in slots.iter().enumerate() {
        ctx.emit(I::LocalGet(1)); // x
        ctx.emit(I::LocalGet(0)); // SimData
        ctx.emit(I::F64Load(mem_arg(off, 3)));
        ctx.emit(I::F64Store(mem_arg((j as u32) * 8, 3)));
    }
    Ok(())
}

/// Lower a torn linear system `A x = b` (the `SES_LINEAR` residual form) into the
/// current simulation equation function.
///
/// The system solves `iter_vars` (the `n` tearing unknowns). `lower_inner` lowers
/// the inner "local constraint" equations, which compute the torn variables (and
/// any intermediates) from the current values of `iter_vars`; `res_exps` are the
/// `n` residual expressions `r_i`, where the system is `r(x) = 0`. Because the
/// system is linear, `r(x) = A x - b`, so we recover `A` and `b` exactly by
/// probing the residual (the numerical-Jacobian approach the C runtime uses when
/// `setA == NULL`):
///   * `b_i = -r_i(0)` — residual with all unknowns set to 0;
///   * `A[i][j] = r_i(e_j) - r_i(0)` — residual with unknown `j` set to 1.
/// Then `rt_linsolve` (LU with partial pivoting) solves `A x = b` in place, the
/// solution is scattered back into `iter_vars`, and the inner equations are run
/// once more so the torn variables are consistent with the solution.
///
/// `lower_inner` is invoked `n + 2` times (once per probe + once to recover); the
/// inner equations read the unknowns from their `SimData` slots, which this code
/// sets before each invocation.
pub(crate) fn compile_linear_system(
    ctx: &mut FnCtx,
    iter_vars: &[Arc<DAE::ComponentRef>],
    res_exps: &[&Arc<DAE::Exp>],
    lower_inner: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    let n = iter_vars.len();
    if n == 0 {
        return Ok(());
    }
    if res_exps.len() != n {
        return Err("CodegenWasmJit: linear system has {n} unknowns but {} residuals");
    }
    // Resolve each unknown to its (real) SimData slot offset.
    let mut slots: Vec<u32> = Vec::with_capacity(n);
    for cr in iter_vars {
        let key = sim_cref_key(cr)?;
        let slot = ctx
            .sim()?
            .vars
            .get(&key)
            .copied()
            .ok_or_else(|| "CodegenWasmJit: linear-system unknown `{key}` has no slot")?;
        if slot.wty != WTy::F64 {
            return Err("CodegenWasmJit: linear-system unknown `{key}` is not a Real variable");
        }
        slots.push(slot.off);
    }
    let data = ctx.sim()?.data_local;

    // One scratch block: A (n*n, column-major) | b (n) | res0 (n) | rescol (n).
    let a_off: u32 = 0;
    let b_off: u32 = (n * n * 8) as u32;
    let res0_off: u32 = ((n * n + n) * 8) as u32;
    let rescol_off: u32 = ((n * n + 2 * n) * 8) as u32;
    let scratch_bytes: u32 = ((n * n + 3 * n) * 8) as u32;

    let base = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(scratch_bytes as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_alloc")?));
    ctx.emit(we::Instruction::LocalSet(base));

    // Set unknown `j` to a literal 0.0 / 1.0 in its SimData slot.
    let set_unknown = |ctx: &mut FnCtx, slot_off: u32, val: f64| {
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::F64Const(val.into()));
        ctx.emit(we::Instruction::F64Store(mem_arg(slot_off, 3)));
    };

    // --- b = -r(0): all unknowns 0, residual into res0, then negate into b. ---
    for &off in &slots {
        set_unknown(ctx, off, 0.0);
    }
    emit_residual_eval(ctx, base, res_exps, res0_off, lower_inner)?;
    for i in 0..n {
        let i = i as u32;
        ctx.emit(we::Instruction::LocalGet(base));
        ctx.emit(we::Instruction::LocalGet(base));
        ctx.emit(we::Instruction::F64Load(mem_arg(res0_off + i * 8, 3)));
        ctx.emit(we::Instruction::F64Neg);
        ctx.emit(we::Instruction::F64Store(mem_arg(b_off + i * 8, 3)));
    }

    // --- A columns: unknown `col` set to 1, the rest 0; A[:,col] = r(e_col) - r(0). ---
    for col in 0..n {
        for (j, &off) in slots.iter().enumerate() {
            set_unknown(ctx, off, if j == col { 1.0 } else { 0.0 });
        }
        emit_residual_eval(ctx, base, res_exps, rescol_off, lower_inner)?;
        for i in 0..n {
            let i_u = i as u32;
            let elem_off = a_off + ((col * n + i) as u32) * 8; // column-major
            ctx.emit(we::Instruction::LocalGet(base));
            ctx.emit(we::Instruction::LocalGet(base));
            ctx.emit(we::Instruction::F64Load(mem_arg(rescol_off + i_u * 8, 3)));
            ctx.emit(we::Instruction::LocalGet(base));
            ctx.emit(we::Instruction::F64Load(mem_arg(res0_off + i_u * 8, 3)));
            ctx.emit(we::Instruction::F64Sub);
            ctx.emit(we::Instruction::F64Store(mem_arg(elem_off, 3)));
        }
    }

    // --- solve A x = b in place (b <- x); trap on a singular system. ---
    ctx.emit(we::Instruction::LocalGet(base)); // a_ptr (a_off == 0)
    ctx.emit(we::Instruction::LocalGet(base));
    ctx.emit(we::Instruction::I32Const(b_off as i32));
    ctx.emit(we::Instruction::I32Add); // b_ptr
    ctx.emit(we::Instruction::I32Const(n as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_linsolve")?));
    ctx.emit(we::Instruction::If(we::BlockType::Empty)); // nonzero => singular
    emit_runtime_error(ctx, "wasm-jit: linear system is singular (no unique solution)")?;
    ctx.emit(we::Instruction::End);

    // --- scatter the solution into the unknown slots. ---
    for j in 0..n {
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::LocalGet(base));
        ctx.emit(we::Instruction::F64Load(mem_arg(b_off + (j as u32) * 8, 3)));
        ctx.emit(we::Instruction::F64Store(mem_arg(slots[j], 3)));
    }

    // --- recover the torn variables: re-run the inner equations at the solution. ---
    lower_inner(ctx)?;

    // --- free the scratch block. ---
    ctx.emit(we::Instruction::LocalGet(base));
    ctx.emit(we::Instruction::Call(rt_index("rt_free")?));
    Ok(())
}

/// Lower a non-torn `SES_LINEAR` system given symbolically as `A x = b`.
///
/// `a_entries` are the sparse matrix elements `(row, col, exp)` (0-based,
/// stored column-major); `b_exps` is the dense right-hand side (one expression
/// per row). Both are functions of already-solved variables, so they evaluate
/// directly — no residual probing. Faithful to the C runtime's `solveLapack`
/// with `method == 0`: zero A, fill it from `setA`, fill b from `setb`, solve
/// `A x = b` in place, then write each `x_j` back into its unknown's slot.
pub(crate) fn compile_linear_system_symbolic(
    ctx: &mut FnCtx,
    vars: &[Arc<DAE::ComponentRef>],
    n: usize,
    a_entries: &[(usize, usize, &Arc<DAE::Exp>)],
    b_exps: &[&Arc<DAE::Exp>],
    index: i32,
) -> Result<()> {
    if n == 0 {
        return Ok(());
    }
    if b_exps.len() != n {
        return Err("CodegenWasmJit: SES_LINEAR (index {index}) has {n} unknowns but {} b entries");
    }
    let mut slots: Vec<u32> = Vec::with_capacity(n);
    for cr in vars {
        let key = sim_cref_key(cr)?;
        let slot = ctx
            .sim()?
            .vars
            .get(&key)
            .copied()
            .ok_or_else(|| "CodegenWasmJit: linear-system unknown `{key}` has no slot")?;
        if slot.wty != WTy::F64 {
            return Err("CodegenWasmJit: linear-system unknown `{key}` is not a Real variable");
        }
        slots.push(slot.off);
    }
    let data = ctx.sim()?.data_local;

    // Scratch: A (n*n, column-major) | b (n).
    let a_off: u32 = 0;
    let b_off: u32 = (n * n * 8) as u32;
    let scratch_bytes: u32 = ((n * n + n) * 8) as u32;

    let base = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(scratch_bytes as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_alloc")?));
    ctx.emit(we::Instruction::LocalSet(base));

    // Zero A: simJac lists only the nonzero entries and rt_alloc does not zero.
    for idx in 0..(n * n) {
        ctx.emit(we::Instruction::LocalGet(base));
        ctx.emit(we::Instruction::F64Const(0.0f64.into()));
        ctx.emit(we::Instruction::F64Store(mem_arg(a_off + (idx as u32) * 8, 3)));
    }

    // A[row + col*n] = element expression (column-major).
    for &(row, col, exp) in a_entries {
        if row >= n || col >= n {
            return Err("CodegenWasmJit: SES_LINEAR (index {index}) simJac entry ({row},{col}) out of range for size {n}");
        }
        let elem_off = a_off + ((col * n + row) as u32) * 8;
        ctx.emit(we::Instruction::LocalGet(base));
        let w = compile_exp(ctx, exp)?;
        coerce(ctx, w, WTy::F64);
        ctx.emit(we::Instruction::F64Store(mem_arg(elem_off, 3)));
    }

    // b[i] = right-hand-side expression.
    for (i, exp) in b_exps.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(base));
        let w = compile_exp(ctx, exp)?;
        coerce(ctx, w, WTy::F64);
        ctx.emit(we::Instruction::F64Store(mem_arg(b_off + (i as u32) * 8, 3)));
    }

    // Solve A x = b in place (b <- x); trap on a singular system.
    ctx.emit(we::Instruction::LocalGet(base)); // a_ptr (a_off == 0)
    ctx.emit(we::Instruction::LocalGet(base));
    ctx.emit(we::Instruction::I32Const(b_off as i32));
    ctx.emit(we::Instruction::I32Add); // b_ptr
    ctx.emit(we::Instruction::I32Const(n as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_linsolve")?));
    ctx.emit(we::Instruction::If(we::BlockType::Empty)); // nonzero => singular
    emit_runtime_error(ctx, "wasm-jit: linear system is singular (no unique solution)")?;
    ctx.emit(we::Instruction::End);

    // Scatter the solution into the unknown slots.
    for j in 0..n {
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::LocalGet(base));
        ctx.emit(we::Instruction::F64Load(mem_arg(b_off + (j as u32) * 8, 3)));
        ctx.emit(we::Instruction::F64Store(mem_arg(slots[j], 3)));
    }

    ctx.emit(we::Instruction::LocalGet(base));
    ctx.emit(we::Instruction::Call(rt_index("rt_free")?));
    Ok(())
}

/// Emit the call to the runtime nonlinear solver `rt_solve_nls` for one
/// `SES_NONLINEAR` system. The Newton driver (forward-difference Jacobian +
/// `rt_linsolve` + damped line search) lives in the runtime (`nls.rs`); this
/// passes the `SimData` pointer, the system's `residual`/`load` shared-table
/// indices (`nls_base + 2k` / `+ 2k + 1`), the unknown count, and the address of
/// the recoverable-failure flag. The 0/1 return is dropped — a failure surfaces
/// through the `nls_fail` flag (the DASSL residual turns it into `IRES = -1`;
/// init / Euler / output callers report it as a hard error).
pub(crate) fn emit_solve_nls_call(ctx: &mut FnCtx, job: NlsJob) -> Result<()> {
    use we::Instruction as I;
    let data = ctx.sim()?.data_local;
    let nls_fail_off = ctx.sim()?.nls_fail_off;
    let rel_fresh_off = ctx.sim()?.rel_fresh_off;
    ctx.emit(I::LocalGet(data));
    ctx.emit(I::GlobalGet(NLS_BASE_GLOBAL));
    ctx.emit(I::I32Const((2 * job.k) as i32));
    ctx.emit(I::I32Add); // residual table index
    ctx.emit(I::GlobalGet(NLS_BASE_GLOBAL));
    ctx.emit(I::I32Const((2 * job.k + 1) as i32));
    ctx.emit(I::I32Add); // load table index
    ctx.emit(I::I32Const(job.n as i32));
    ctx.emit(I::LocalGet(data));
    ctx.emit(I::I32Const(nls_fail_off as i32));
    ctx.emit(I::I32Add); // nls_fail flag address
    // history block address for this system, and the current time (SimData+0),
    // for the extrapolated initial guess.
    ctx.emit(I::GlobalGet(NLS_HIST_GLOBAL));
    ctx.emit(I::I32Const(job.hist_off as i32));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalGet(data));
    ctx.emit(I::F64Load(mem_arg(0, 3))); // time at SimData offset 0
    // relation-mode flag address: the solver holds relations around the Newton
    // solve so the residual stays smooth.
    ctx.emit(I::LocalGet(data));
    ctx.emit(I::I32Const(rel_fresh_off as i32));
    ctx.emit(I::I32Add);
    ctx.emit(I::Call(rt_index("rt_solve_nls")?));
    ctx.emit(I::Drop);
    Ok(())
}
