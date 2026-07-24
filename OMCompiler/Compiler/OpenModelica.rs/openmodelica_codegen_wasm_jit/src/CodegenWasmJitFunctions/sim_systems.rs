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

/// A nonlinear system residual: a scalar `SES_RESIDUAL`, or a `SES_FOR_RESIDUAL`
/// (a run `r[res_index + shift]` from iterating `exp` over integer ranges).
pub(crate) enum NlsResidual {
    Scalar { exp: Arc<DAE::Exp>, res_index: i32 },
    For {
        iterators: Vec<(Arc<DAE::ComponentRef>, Arc<DAE::Exp>)>,
        exp: Arc<DAE::Exp>,
        res_index: i32,
    },
}

/// Emit the body of a nonlinear system's `residual(sim_data, x, r)` callback
/// (wasm locals: 0 = `SimData`, 1 = `x` pointer, 2 = `r` pointer). Copies the
/// `n` unknowns from `x` into their `slots`, runs the inner (torn) equations via
/// `lower_inner`, then stores the residuals into `r`. Reached from `rt_solve_nls`
/// by `call_indirect`.
pub(crate) fn emit_nls_residual_body(
    ctx: &mut FnCtx,
    slots: &[u32],
    residuals: &[NlsResidual],
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
    // All-scalar systems keep sequential `r[i]` addressing; a for-residual forces
    // `res_index`-based addressing throughout (C's `res[res_index + shift]`).
    let all_scalar = residuals.iter().all(|r| matches!(r, NlsResidual::Scalar { .. }));
    for (i, res) in residuals.iter().enumerate() {
        match res {
            NlsResidual::Scalar { exp, res_index } => {
                let dest = if all_scalar { i as u32 } else { *res_index as u32 };
                ctx.emit(I::LocalGet(2)); // r
                let w = compile_exp(ctx, exp)?;
                coerce(ctx, w, WTy::F64);
                ctx.emit(I::F64Store(mem_arg(dest * 8, 3)));
            }
            NlsResidual::For { iterators, exp, res_index } => {
                emit_for_residual(ctx, iterators, exp, *res_index, &[])?;
            }
        }
    }
    Ok(())
}

/// Emit a `SES_FOR_RESIDUAL`: nested `for` loops (outermost first) storing
/// `r[res_index + Σ(iter_k - start_k)] = exp` (C's `indexShift`). Each iterator
/// registers as a wasm local so `compile_exp` resolves `x[$i]` and bare `$i`.
fn emit_for_residual(
    ctx: &mut FnCtx,
    iterators: &[(Arc<DAE::ComponentRef>, Arc<DAE::Exp>)],
    exp: &Arc<DAE::Exp>,
    res_index: i32,
    outer: &[(u32, u32)],
) -> Result<()> {
    use we::Instruction as I;
    let Some(((cref, range), rest)) = iterators.split_first() else {
        // addr = r + (res_index + Σ(it - start)) * 8
        ctx.emit(I::LocalGet(2)); // r
        ctx.emit(I::I32Const(res_index));
        for &(it, start_l) in outer {
            ctx.emit(I::LocalGet(it));
            ctx.emit(I::LocalGet(start_l));
            ctx.emit(I::I32Sub);
            ctx.emit(I::I32Add);
        }
        ctx.emit(I::I32Const(8));
        ctx.emit(I::I32Mul);
        ctx.emit(I::I32Add); // element address
        let w = compile_exp(ctx, exp)?;
        coerce(ctx, w, WTy::F64);
        ctx.emit(I::F64Store(mem_arg(0, 3)));
        return Ok(());
    };
    let DAE::Exp::RANGE { start, step, stop, .. } = &**range else {
        return Err("CodegenWasmJit: for-residual over a non-range iterator");
    };
    let id = cref_ident(cref)?;
    let it = ctx.alloc_temp(WTy::I32);
    ctx.locals.insert(id, (it, SigTy::Int));
    let start_l = ctx.alloc_temp(WTy::I32);
    let step_l = ctx.alloc_temp(WTy::I32);
    let stop_l = ctx.alloc_temp(WTy::I32);
    let sw = compile_exp(ctx, start)?;
    coerce(ctx, sw, WTy::I32);
    ctx.emit(I::LocalTee(start_l));
    ctx.emit(I::LocalSet(it));
    match step {
        Some(e) => {
            let w = compile_exp(ctx, e)?;
            coerce(ctx, w, WTy::I32);
        }
        None => ctx.emit(I::I32Const(1)),
    }
    ctx.emit(I::LocalSet(step_l));
    let pw = compile_exp(ctx, stop)?;
    coerce(ctx, pw, WTy::I32);
    ctx.emit(I::LocalSet(stop_l));
    ctx.emit(I::Block(we::BlockType::Empty));
    ctx.emit(I::Loop(we::BlockType::Empty));
    ctx.emit(I::LocalGet(it));
    ctx.emit(I::LocalGet(stop_l));
    ctx.emit(I::I32GtS);
    ctx.emit(I::BrIf(1));
    let mut inner = outer.to_vec();
    inner.push((it, start_l));
    emit_for_residual(ctx, rest, exp, res_index, &inner)?;
    ctx.emit(I::LocalGet(it));
    ctx.emit(I::LocalGet(step_l));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(it));
    ctx.emit(I::Br(0));
    ctx.emit(I::End); // loop
    ctx.emit(I::End); // block
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

/// Emit a nonlinear system's analytic-Jacobian `jac(sim_data, x, jptr)` callback
/// (wasm locals: 0 = `SimData`, 1 = `x`, 2 = `jptr` = column-major `n×n` output).
/// Copies `x` into the iteration slots and runs the inner (torn) equations to set
/// the intermediate variables, evaluates the constant equations once, then for each
/// seed column sets that seed to 1 (others 0), zeros the result slots, runs the
/// column equations, and stores the result slots as column `j` (`jptr[j*n + i] =
/// ∂f_i/∂x_j`). Zeroing the result slots first keeps structurally-zero rows at 0.
#[allow(clippy::too_many_arguments)]
pub(crate) fn emit_nls_jac_body(
    ctx: &mut FnCtx,
    iter_slots: &[u32],
    seed_offs: &[u32],
    result_offs: &[u32],
    lower_inner: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
    lower_constant: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
    lower_column: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    use we::Instruction as I;
    let n = iter_slots.len();
    for (j, &off) in iter_slots.iter().enumerate() {
        ctx.emit(I::LocalGet(0));
        ctx.emit(I::LocalGet(1));
        ctx.emit(I::F64Load(mem_arg((j as u32) * 8, 3)));
        ctx.emit(I::F64Store(mem_arg(off, 3)));
    }
    lower_inner(ctx)?;
    lower_constant(ctx)?;
    let store_const = |ctx: &mut FnCtx, off: u32, val: f64| {
        ctx.emit(I::LocalGet(0));
        ctx.emit(I::F64Const(val.into()));
        ctx.emit(I::F64Store(mem_arg(off, 3)));
    };
    for j in 0..n {
        for (k, &soff) in seed_offs.iter().enumerate() {
            store_const(ctx, soff, if k == j { 1.0 } else { 0.0 });
        }
        for &roff in result_offs {
            store_const(ctx, roff, 0.0);
        }
        lower_column(ctx)?;
        for (i, &roff) in result_offs.iter().enumerate() {
            ctx.emit(I::LocalGet(2));
            ctx.emit(I::LocalGet(0));
            ctx.emit(I::F64Load(mem_arg(roff, 3)));
            ctx.emit(I::F64Store(mem_arg(((j * n + i) as u32) * 8, 3)));
        }
    }
    Ok(())
}

/// Lower a torn linear system `A x = b` by residual probing (the fallback when the
/// system has no usable symbolic Jacobian; see `compile_linear_system_analytic`).
/// `r(x) = A x - b` for a linear system, so `b_i = -r_i(0)` and
/// `A[i][j] = r_i(e_j) - r_i(0)` recover `A`/`b` (C's numerical-Jacobian path). The
/// column probes share one emitted residual body run in a wasm loop (`n` unrolled
/// copies would explode the code). `use_sparse` picks `rt_solve_lin_dense_sparse`
/// over `rt_linsolve`, matching C's per-system choice.
pub(crate) fn compile_linear_system(
    ctx: &mut FnCtx,
    iter_vars: &[Arc<DAE::ComponentRef>],
    res_exps: &[&Arc<DAE::Exp>],
    lower_inner: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
    use_sparse: bool,
) -> Result<()> {
    let n = iter_vars.len();
    if n == 0 {
        return Ok(());
    }
    if res_exps.len() != n {
        return Err("CodegenWasmJit: linear system unknown/residual count mismatch");
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
            .ok_or_else(|| "CodegenWasmJit: linear-system unknown has no slot")?;
        if slot.wty != WTy::F64 {
            return Err("CodegenWasmJit: linear-system unknown is not a Real variable");
        }
        slots.push(slot.off);
    }
    let data = ctx.sim()?.data_local;

    // One scratch block: A (n*n, column-major) | b (n) | res0 (n) | rescol (n) |
    // offs (n i32 slot offsets, so the probe loop can index unknown `col` at run
    // time). The `n` column probes share a single emitted residual body run inside
    // a wasm loop — unrolling them (as `b`/recovery still are) is O(n) copies of
    // the inner equations, which explodes the code for large systems.
    let a_off: u32 = 0;
    let b_off: u32 = (n * n * 8) as u32;
    let res0_off: u32 = ((n * n + n) * 8) as u32;
    let rescol_off: u32 = ((n * n + 2 * n) * 8) as u32;
    let offs_off: u32 = ((n * n + 3 * n) * 8) as u32;
    let scratch_bytes: u32 = offs_off + (n * 4) as u32;

    let base = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(scratch_bytes as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_alloc")?));
    ctx.emit(we::Instruction::LocalSet(base));

    // Record each unknown's slot offset in the `offs` array for run-time indexing.
    for (j, &off) in slots.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(base));
        ctx.emit(we::Instruction::I32Const(off as i32));
        ctx.emit(we::Instruction::I32Store(mem_arg(offs_off + (j as u32) * 4, 2)));
    }

    // Set unknown `j` to a literal 0.0 / 1.0 in its SimData slot.
    let set_unknown = |ctx: &mut FnCtx, slot_off: u32, val: f64| {
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::F64Const(val.into()));
        ctx.emit(we::Instruction::F64Store(mem_arg(slot_off, 3)));
    };
    // Push the address of unknown `col` (SimData + offs[col]) onto the stack.
    let push_unknown_addr = |ctx: &mut FnCtx, col: u32| {
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::LocalGet(base));
        ctx.emit(we::Instruction::LocalGet(col));
        ctx.emit(we::Instruction::I32Const(4));
        ctx.emit(we::Instruction::I32Mul);
        ctx.emit(we::Instruction::I32Add);
        ctx.emit(we::Instruction::I32Load(mem_arg(offs_off, 2)));
        ctx.emit(we::Instruction::I32Add);
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

    // --- A columns: probe unknown `col` = 1 (rest still 0), A[:,col] = r(e_col) -
    // r(0), then reset it. All unknowns are 0 on entry (from the b probe) and left
    // 0 after each reset, so only `col` is toggled per iteration. ---
    let col = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalSet(col));
    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
    ctx.emit(we::Instruction::LocalGet(col));
    ctx.emit(we::Instruction::I32Const(n as i32));
    ctx.emit(we::Instruction::I32GeS);
    ctx.emit(we::Instruction::BrIf(1));
    push_unknown_addr(ctx, col);
    ctx.emit(we::Instruction::F64Const(1.0f64.into()));
    ctx.emit(we::Instruction::F64Store(mem_arg(0, 3)));
    emit_residual_eval(ctx, base, res_exps, rescol_off, lower_inner)?;
    // A[col*n + i] = rescol[i] - res0[i], the column address computed from `col`.
    for i in 0..n {
        let i_u = i as u32;
        ctx.emit(we::Instruction::LocalGet(base));
        ctx.emit(we::Instruction::LocalGet(col));
        ctx.emit(we::Instruction::I32Const(n as i32));
        ctx.emit(we::Instruction::I32Mul);
        ctx.emit(we::Instruction::I32Const(i_u as i32));
        ctx.emit(we::Instruction::I32Add);
        ctx.emit(we::Instruction::I32Const(8));
        ctx.emit(we::Instruction::I32Mul);
        ctx.emit(we::Instruction::I32Add);
        ctx.emit(we::Instruction::LocalGet(base));
        ctx.emit(we::Instruction::F64Load(mem_arg(rescol_off + i_u * 8, 3)));
        ctx.emit(we::Instruction::LocalGet(base));
        ctx.emit(we::Instruction::F64Load(mem_arg(res0_off + i_u * 8, 3)));
        ctx.emit(we::Instruction::F64Sub);
        ctx.emit(we::Instruction::F64Store(mem_arg(0, 3)));
    }
    push_unknown_addr(ctx, col);
    ctx.emit(we::Instruction::F64Const(0.0f64.into()));
    ctx.emit(we::Instruction::F64Store(mem_arg(0, 3)));
    ctx.emit(we::Instruction::LocalGet(col));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(col));
    ctx.emit(we::Instruction::Br(0));
    ctx.emit(we::Instruction::End); // loop
    ctx.emit(we::Instruction::End); // block

    // --- solve, scatter the solution into the unknown slots, recover the torn
    // variables (re-run inner at the solution), free the scratch. ---
    emit_lin_solve_scatter(ctx, base, b_off, n, &slots, use_sparse, lower_inner)
}

/// Trap (runtime error) when the solver returned nonzero (singular) — consumes the
/// i32 result on the stack.
fn emit_singular_check(ctx: &mut FnCtx) -> Result<()> {
    ctx.emit(we::Instruction::If(we::BlockType::Empty));
    emit_runtime_error(ctx, "wasm-jit: linear system is singular (no unique solution)")?;
    ctx.emit(we::Instruction::End);
    Ok(())
}

/// Scatter the solution `x` (at `base+b_off`) into `slots`, recover the torn
/// variables (`lower_inner` at the solution), and free `base`.
fn emit_scatter_recover_free(
    ctx: &mut FnCtx,
    base: u32,
    b_off: u32,
    n: usize,
    slots: &[u32],
    lower_inner: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    use we::Instruction as I;
    let data = ctx.sim()?.data_local;
    for j in 0..n {
        ctx.emit(I::LocalGet(data));
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::F64Load(mem_arg(b_off + (j as u32) * 8, 3)));
        ctx.emit(I::F64Store(mem_arg(slots[j], 3)));
    }
    lower_inner(ctx)?;
    ctx.emit(I::LocalGet(base));
    ctx.emit(I::Call(rt_index("rt_free")?));
    Ok(())
}

/// Solve the assembled dense `A x = b` (column-major `A` at `base+0`, `b` at
/// `base+b_off`), then scatter/recover/free. `use_sparse` picks
/// `rt_solve_lin_dense_sparse` vs `rt_linsolve`.
fn emit_lin_solve_scatter(
    ctx: &mut FnCtx,
    base: u32,
    b_off: u32,
    n: usize,
    slots: &[u32],
    use_sparse: bool,
    lower_inner: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    use we::Instruction as I;
    ctx.emit(I::LocalGet(base)); // a_ptr (a_off == 0)
    ctx.emit(I::LocalGet(base));
    ctx.emit(I::I32Const(b_off as i32));
    ctx.emit(I::I32Add); // b_ptr
    ctx.emit(I::I32Const(n as i32));
    let solver = if use_sparse { "rt_solve_lin_dense_sparse" } else { "rt_linsolve" };
    ctx.emit(I::Call(rt_index(solver)?));
    emit_singular_check(ctx)?;
    emit_scatter_recover_free(ctx, base, b_off, n, slots, lower_inner)
}

/// Lower a torn linear system `A x = b` by analytic-Jacobian assembly (C's method
/// 1). `A = ∂r/∂x` is constant, evaluated once from the symbolic Jacobian columns
/// (seed column `j`, run `lower_column`, read `result_offs[i]` = `∂r_i/∂x_j`);
/// `b = -r(0)` from a single residual eval. Both land in `res_index` row order
/// (`result_offs` placed by `jac_result_row`), so the solve is consistent. Replaces
/// the O(n) residual probe with O(n) cheaper column-equation evals.
#[allow(clippy::too_many_arguments)]
pub(crate) fn compile_linear_system_analytic(
    ctx: &mut FnCtx,
    iter_vars: &[Arc<DAE::ComponentRef>],
    res_exps: &[&Arc<DAE::Exp>],
    seed_offs: &[u32],
    result_offs: &[u32],
    lower_inner: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
    lower_constant: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
    lower_column: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
    use_sparse: bool,
) -> Result<()> {
    use we::Instruction as I;
    let n = iter_vars.len();
    if n == 0 {
        return Ok(());
    }
    if res_exps.len() != n || seed_offs.len() != n || result_offs.len() != n {
        return Err("CodegenWasmJit: analytic linear system size/Jacobian mismatch");
    }
    let mut slots: Vec<u32> = Vec::with_capacity(n);
    for cr in iter_vars {
        let key = sim_cref_key(cr)?;
        let slot = ctx.sim()?.vars.get(&key).copied()
            .ok_or_else(|| "CodegenWasmJit: linear-system unknown has no slot")?;
        if slot.wty != WTy::F64 {
            return Err("CodegenWasmJit: linear-system unknown is not a Real variable");
        }
        slots.push(slot.off);
    }
    let data = ctx.sim()?.data_local;

    // Scratch: A (n*n column-major f64) | b (n f64) | seed_tab (n i32) |
    // res_tab (n i32). The two i32 tables hold the seed/result slot offsets so the
    // column loop can index them at run time (the column-equation body is emitted
    // once inside a wasm loop — unrolling it n times explodes the code for large
    // systems, the same blow-up the residual probe avoids).
    let b_off: u32 = (n * n * 8) as u32;
    let seed_tab_off: u32 = b_off + (n * 8) as u32;
    let res_tab_off: u32 = seed_tab_off + (n * 4) as u32;
    let scratch_bytes: u32 = res_tab_off + (n * 4) as u32;
    let base = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::I32Const(scratch_bytes as i32));
    ctx.emit(I::Call(rt_index("rt_alloc")?));
    ctx.emit(I::LocalSet(base));

    // Seed/result slot offsets in run-time index tables (the column loop is a wasm
    // loop, so it indexes them rather than baking offsets in per column).
    for (k, &soff) in seed_offs.iter().enumerate() {
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::I32Const(soff as i32));
        ctx.emit(I::I32Store(mem_arg(seed_tab_off + (k as u32) * 4, 2)));
    }
    for (i, &roff) in result_offs.iter().enumerate() {
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::I32Const(roff as i32));
        ctx.emit(I::I32Store(mem_arg(res_tab_off + (i as u32) * 4, 2)));
    }

    let store_slot = |ctx: &mut FnCtx, off: u32, val: f64| {
        ctx.emit(I::LocalGet(data));
        ctx.emit(I::F64Const(val.into()));
        ctx.emit(I::F64Store(mem_arg(off, 3)));
    };
    // Evaluate at x = 0 (A is constant, so any point works).
    for &off in &slots {
        store_slot(ctx, off, 0.0);
    }
    for &soff in seed_offs {
        store_slot(ctx, soff, 0.0);
    }
    // b = -r(0): residual (inner at x=0 + res_exps) into b, then negate in place.
    emit_residual_eval(ctx, base, res_exps, b_off, lower_inner)?;
    for i in 0..n as u32 {
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::F64Load(mem_arg(b_off + i * 8, 3)));
        ctx.emit(I::F64Neg);
        ctx.emit(I::F64Store(mem_arg(b_off + i * 8, 3)));
    }

    // Constant Jacobian equations (evaluated once, at x=0 with the torn vars set).
    lower_constant(ctx)?;

    // `data + tab[idx*4 + tab_off]` — address of the slot named by index table
    // `tab_off` at run-time index `idx` (an i32 local).
    let push_tab_addr = |ctx: &mut FnCtx, tab_off: u32, idx: u32| {
        ctx.emit(I::LocalGet(data));
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::LocalGet(idx));
        ctx.emit(I::I32Const(4));
        ctx.emit(I::I32Mul);
        ctx.emit(I::I32Add);
        ctx.emit(I::I32Load(mem_arg(tab_off, 2)));
        ctx.emit(I::I32Add);
    };

    // for j in 0..n: seed[j]=1, zero results, run column eqns, A[j*n+i]=result[i],
    // reset seed[j]=0. Column body emitted once; the two inner loops keep code O(1).
    let jloc = ctx.alloc_temp(WTy::I32);
    let iloc = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::I32Const(0));
    ctx.emit(I::LocalSet(jloc));
    ctx.emit(I::Block(we::BlockType::Empty));
    ctx.emit(I::Loop(we::BlockType::Empty));
    ctx.emit(I::LocalGet(jloc));
    ctx.emit(I::I32Const(n as i32));
    ctx.emit(I::I32GeS);
    ctx.emit(I::BrIf(1));
    // seed[j] = 1.
    push_tab_addr(ctx, seed_tab_off, jloc);
    ctx.emit(I::F64Const(1.0f64.into()));
    ctx.emit(I::F64Store(mem_arg(0, 3)));
    // zero the result slots.
    ctx.emit(I::I32Const(0));
    ctx.emit(I::LocalSet(iloc));
    ctx.emit(I::Block(we::BlockType::Empty));
    ctx.emit(I::Loop(we::BlockType::Empty));
    ctx.emit(I::LocalGet(iloc));
    ctx.emit(I::I32Const(n as i32));
    ctx.emit(I::I32GeS);
    ctx.emit(I::BrIf(1));
    push_tab_addr(ctx, res_tab_off, iloc);
    ctx.emit(I::F64Const(0.0f64.into()));
    ctx.emit(I::F64Store(mem_arg(0, 3)));
    ctx.emit(I::LocalGet(iloc));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(iloc));
    ctx.emit(I::Br(0));
    ctx.emit(I::End);
    ctx.emit(I::End);
    // evaluate column j.
    lower_column(ctx)?;
    // A[j*n + i] = result slot i (column-major).
    ctx.emit(I::I32Const(0));
    ctx.emit(I::LocalSet(iloc));
    ctx.emit(I::Block(we::BlockType::Empty));
    ctx.emit(I::Loop(we::BlockType::Empty));
    ctx.emit(I::LocalGet(iloc));
    ctx.emit(I::I32Const(n as i32));
    ctx.emit(I::I32GeS);
    ctx.emit(I::BrIf(1));
    // A element address = base + (j*n + i)*8.
    ctx.emit(I::LocalGet(base));
    ctx.emit(I::LocalGet(jloc));
    ctx.emit(I::I32Const(n as i32));
    ctx.emit(I::I32Mul);
    ctx.emit(I::LocalGet(iloc));
    ctx.emit(I::I32Add);
    ctx.emit(I::I32Const(8));
    ctx.emit(I::I32Mul);
    ctx.emit(I::I32Add);
    push_tab_addr(ctx, res_tab_off, iloc);
    ctx.emit(I::F64Load(mem_arg(0, 3)));
    ctx.emit(I::F64Store(mem_arg(0, 3)));
    ctx.emit(I::LocalGet(iloc));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(iloc));
    ctx.emit(I::Br(0));
    ctx.emit(I::End);
    ctx.emit(I::End);
    // reset seed[j] = 0.
    push_tab_addr(ctx, seed_tab_off, jloc);
    ctx.emit(I::F64Const(0.0f64.into()));
    ctx.emit(I::F64Store(mem_arg(0, 3)));
    ctx.emit(I::LocalGet(jloc));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(jloc));
    ctx.emit(I::Br(0));
    ctx.emit(I::End);
    ctx.emit(I::End);

    emit_lin_solve_scatter(ctx, base, b_off, n, &slots, use_sparse, lower_inner)
}

/// Greedy distance-1 column coloring (Curtis-Powell-Reid) of the CSC pattern:
/// columns sharing a residual row get distinct colors, so every column of one color
/// can be seeded at once and its nonzeros read from a single column-eqn pass. Returns
/// `(color_ptr, color_cols)`: color `c` owns `color_cols[color_ptr[c]..color_ptr[c+1]]`.
/// Cuts the analytic-assembly passes from `n` to `#colors` (≈ max row degree).
fn lin_jac_coloring(colptr: &[i32], rowidx: &[i32], n: usize) -> (Vec<i32>, Vec<i32>) {
    let nrows = rowidx.iter().copied().max().map_or(0, |m| m as usize + 1);
    let mut row_cols: Vec<Vec<u32>> = vec![Vec::new(); nrows];
    for j in 0..n {
        for k in colptr[j] as usize..colptr[j + 1] as usize {
            row_cols[rowidx[k] as usize].push(j as u32);
        }
    }
    let mut color = vec![-1i32; n];
    let mut forbidden = vec![u32::MAX; n]; // forbidden[c] == j: color c taken near col j
    let mut ncolors = 0usize;
    for j in 0..n {
        for k in colptr[j] as usize..colptr[j + 1] as usize {
            for &c2 in &row_cols[rowidx[k] as usize] {
                let cc = color[c2 as usize];
                if cc >= 0 {
                    forbidden[cc as usize] = j as u32;
                }
            }
        }
        let mut chosen = 0usize;
        while chosen < ncolors && forbidden[chosen] == j as u32 {
            chosen += 1;
        }
        if chosen == ncolors {
            ncolors += 1;
        }
        color[j] = chosen as i32;
    }
    let mut color_ptr = vec![0i32; ncolors + 1];
    for &c in &color {
        color_ptr[c as usize + 1] += 1;
    }
    for c in 0..ncolors {
        color_ptr[c + 1] += color_ptr[c];
    }
    let mut color_cols = vec![0i32; n];
    let mut cursor = color_ptr[..ncolors].to_vec();
    for (j, &c) in color.iter().enumerate() {
        color_cols[cursor[c as usize] as usize] = j as i32;
        cursor[c as usize] += 1;
    }
    (color_ptr, color_cols)
}

/// Analytic assembly directly into CSC (no dense `n²` buffer) for a sparse torn
/// linear system: `colptr`/`rowidx` are the compile-time pattern in `res_index` row
/// order (from `lin_jac_csc_pattern`). Columns are colored, then each color is seeded
/// as a group, the column equations run once, and `values[k] = result[rowidx[k]]` is
/// read for every column of the color (orthogonal rows → one seed per row). This is
/// `#colors` passes, not `n`. Row order matches `b = -r(0)` (both `res_index`).
#[allow(clippy::too_many_arguments)]
pub(crate) fn compile_linear_system_analytic_csc(
    ctx: &mut FnCtx,
    handle: i32,
    iter_vars: &[Arc<DAE::ComponentRef>],
    res_exps: &[&Arc<DAE::Exp>],
    seed_offs: &[u32],
    result_offs: &[u32],
    colptr: &[i32],
    rowidx: &[i32],
    lower_inner: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
    lower_constant: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
    lower_column: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    use we::Instruction as I;
    let n = iter_vars.len();
    if n == 0 {
        return Ok(());
    }
    if res_exps.len() != n || seed_offs.len() != n || result_offs.len() != n
        || colptr.len() != n + 1
    {
        return Err("CodegenWasmJit: analytic-CSC linear system size mismatch");
    }
    let nnz = rowidx.len();
    let (color_ptr, color_cols) = lin_jac_coloring(colptr, rowidx, n);
    let ncolors = color_ptr.len() - 1;
    let mut slots: Vec<u32> = Vec::with_capacity(n);
    for cr in iter_vars {
        let key = sim_cref_key(cr)?;
        let slot = ctx.sim()?.vars.get(&key).copied()
            .ok_or_else(|| "CodegenWasmJit: linear-system unknown has no slot")?;
        if slot.wty != WTy::F64 {
            return Err("CodegenWasmJit: linear-system unknown is not a Real variable");
        }
        slots.push(slot.off);
    }
    let data = ctx.sim()?.data_local;

    // Scratch (f64 regions first for 8-alignment): values (nnz) | b (n) | colptr
    // (n+1 i32) | rowidx (nnz i32) | seed_tab (n i32) | res_tab (n i32) |
    // color_ptr (ncolors+1 i32) | color_cols (n i32).
    let values_off: u32 = 0;
    let b_off: u32 = (nnz * 8) as u32;
    let colptr_off: u32 = b_off + (n * 8) as u32;
    let rowidx_off: u32 = colptr_off + ((n + 1) * 4) as u32;
    let seed_tab_off: u32 = rowidx_off + (nnz * 4) as u32;
    let res_tab_off: u32 = seed_tab_off + (n * 4) as u32;
    let colorptr_off: u32 = res_tab_off + (n * 4) as u32;
    let colorcols_off: u32 = colorptr_off + ((ncolors + 1) * 4) as u32;
    let scratch_bytes: u32 = colorcols_off + (n * 4) as u32;
    let base = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::I32Const(scratch_bytes as i32));
    ctx.emit(I::Call(rt_index("rt_alloc")?));
    ctx.emit(I::LocalSet(base));

    let store_i32 = |ctx: &mut FnCtx, off: u32, v: i32| {
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::I32Const(v));
        ctx.emit(I::I32Store(mem_arg(off, 2)));
    };
    for (k, &p) in colptr.iter().enumerate() {
        store_i32(ctx, colptr_off + (k as u32) * 4, p);
    }
    for (k, &r) in rowidx.iter().enumerate() {
        store_i32(ctx, rowidx_off + (k as u32) * 4, r);
    }
    for (k, &soff) in seed_offs.iter().enumerate() {
        store_i32(ctx, seed_tab_off + (k as u32) * 4, soff as i32);
    }
    for (i, &roff) in result_offs.iter().enumerate() {
        store_i32(ctx, res_tab_off + (i as u32) * 4, roff as i32);
    }
    for (k, &p) in color_ptr.iter().enumerate() {
        store_i32(ctx, colorptr_off + (k as u32) * 4, p);
    }
    for (k, &j) in color_cols.iter().enumerate() {
        store_i32(ctx, colorcols_off + (k as u32) * 4, j);
    }

    let store_slot = |ctx: &mut FnCtx, off: u32, val: f64| {
        ctx.emit(I::LocalGet(data));
        ctx.emit(I::F64Const(val.into()));
        ctx.emit(I::F64Store(mem_arg(off, 3)));
    };
    for &off in &slots {
        store_slot(ctx, off, 0.0);
    }
    for &soff in seed_offs {
        store_slot(ctx, soff, 0.0);
    }
    // b = -r(0).
    emit_residual_eval(ctx, base, res_exps, b_off, lower_inner)?;
    for i in 0..n as u32 {
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::F64Load(mem_arg(b_off + i * 8, 3)));
        ctx.emit(I::F64Neg);
        ctx.emit(I::F64Store(mem_arg(b_off + i * 8, 3)));
    }
    lower_constant(ctx)?;

    // Address `data + seed_tab[idx]` for run-time index `idx`.
    let push_seed_addr = |ctx: &mut FnCtx, idx: u32| {
        ctx.emit(I::LocalGet(data));
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::LocalGet(idx));
        ctx.emit(I::I32Const(4));
        ctx.emit(I::I32Mul);
        ctx.emit(I::I32Add);
        ctx.emit(I::I32Load(mem_arg(seed_tab_off, 2)));
        ctx.emit(I::I32Add);
    };

    let cloc = ctx.alloc_temp(WTy::I32);
    let mloc = ctx.alloc_temp(WTy::I32);
    let mend = ctx.alloc_temp(WTy::I32);
    let jloc = ctx.alloc_temp(WTy::I32);
    let kloc = ctx.alloc_temp(WTy::I32);
    let kend = ctx.alloc_temp(WTy::I32);
    // mloc/mend = color_ptr[cloc + addc].
    let load_colorptr = |ctx: &mut FnCtx, dst: u32, addc: i32| {
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::LocalGet(cloc));
        if addc != 0 {
            ctx.emit(I::I32Const(addc));
            ctx.emit(I::I32Add);
        }
        ctx.emit(I::I32Const(4));
        ctx.emit(I::I32Mul);
        ctx.emit(I::I32Add);
        ctx.emit(I::I32Load(mem_arg(colorptr_off, 2)));
        ctx.emit(I::LocalSet(dst));
    };
    let load_j = |ctx: &mut FnCtx| {
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::LocalGet(mloc));
        ctx.emit(I::I32Const(4));
        ctx.emit(I::I32Mul);
        ctx.emit(I::I32Add);
        ctx.emit(I::I32Load(mem_arg(colorcols_off, 2)));
        ctx.emit(I::LocalSet(jloc));
    };

    // for c in 0..ncolors: seed every column of the color, run the column eqns once,
    // then read each column's pattern nonzeros and clear its seed.
    ctx.emit(I::I32Const(0));
    ctx.emit(I::LocalSet(cloc));
    ctx.emit(I::Block(we::BlockType::Empty));
    ctx.emit(I::Loop(we::BlockType::Empty));
    ctx.emit(I::LocalGet(cloc));
    ctx.emit(I::I32Const(ncolors as i32));
    ctx.emit(I::I32GeS);
    ctx.emit(I::BrIf(1));
    // seed pass: for m in color_ptr[c]..color_ptr[c+1]: seed[color_cols[m]] = 1.
    load_colorptr(ctx, mloc, 0);
    load_colorptr(ctx, mend, 1);
    ctx.emit(I::Block(we::BlockType::Empty));
    ctx.emit(I::Loop(we::BlockType::Empty));
    ctx.emit(I::LocalGet(mloc));
    ctx.emit(I::LocalGet(mend));
    ctx.emit(I::I32GeS);
    ctx.emit(I::BrIf(1));
    load_j(ctx);
    push_seed_addr(ctx, jloc);
    ctx.emit(I::F64Const(1.0f64.into()));
    ctx.emit(I::F64Store(mem_arg(0, 3)));
    ctx.emit(I::LocalGet(mloc));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(mloc));
    ctx.emit(I::Br(0));
    ctx.emit(I::End);
    ctx.emit(I::End);
    lower_column(ctx)?;
    // read pass over the same color members.
    load_colorptr(ctx, mloc, 0);
    load_colorptr(ctx, mend, 1);
    ctx.emit(I::Block(we::BlockType::Empty));
    ctx.emit(I::Loop(we::BlockType::Empty));
    ctx.emit(I::LocalGet(mloc));
    ctx.emit(I::LocalGet(mend));
    ctx.emit(I::I32GeS);
    ctx.emit(I::BrIf(1));
    load_j(ctx);
    // k = colptr[j]; kend = colptr[j+1].
    ctx.emit(I::LocalGet(base));
    ctx.emit(I::LocalGet(jloc));
    ctx.emit(I::I32Const(4));
    ctx.emit(I::I32Mul);
    ctx.emit(I::I32Add);
    ctx.emit(I::I32Load(mem_arg(colptr_off, 2)));
    ctx.emit(I::LocalSet(kloc));
    ctx.emit(I::LocalGet(base));
    ctx.emit(I::LocalGet(jloc));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Add);
    ctx.emit(I::I32Const(4));
    ctx.emit(I::I32Mul);
    ctx.emit(I::I32Add);
    ctx.emit(I::I32Load(mem_arg(colptr_off, 2)));
    ctx.emit(I::LocalSet(kend));
    ctx.emit(I::Block(we::BlockType::Empty));
    ctx.emit(I::Loop(we::BlockType::Empty));
    ctx.emit(I::LocalGet(kloc));
    ctx.emit(I::LocalGet(kend));
    ctx.emit(I::I32GeS);
    ctx.emit(I::BrIf(1));
    // values[k] address = base + values_off + k*8.
    ctx.emit(I::LocalGet(base));
    ctx.emit(I::LocalGet(kloc));
    ctx.emit(I::I32Const(8));
    ctx.emit(I::I32Mul);
    ctx.emit(I::I32Add);
    // value = f64[data + res_tab[rowidx[k]]].
    ctx.emit(I::LocalGet(base));
    ctx.emit(I::LocalGet(kloc));
    ctx.emit(I::I32Const(4));
    ctx.emit(I::I32Mul);
    ctx.emit(I::I32Add);
    ctx.emit(I::I32Load(mem_arg(rowidx_off, 2))); // row
    ctx.emit(I::I32Const(4));
    ctx.emit(I::I32Mul);
    ctx.emit(I::LocalGet(base));
    ctx.emit(I::I32Add);
    ctx.emit(I::I32Load(mem_arg(res_tab_off, 2))); // result slot offset
    ctx.emit(I::LocalGet(data));
    ctx.emit(I::I32Add);
    ctx.emit(I::F64Load(mem_arg(0, 3)));
    ctx.emit(I::F64Store(mem_arg(values_off, 3)));
    ctx.emit(I::LocalGet(kloc));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(kloc));
    ctx.emit(I::Br(0));
    ctx.emit(I::End);
    ctx.emit(I::End);
    push_seed_addr(ctx, jloc);
    ctx.emit(I::F64Const(0.0f64.into()));
    ctx.emit(I::F64Store(mem_arg(0, 3)));
    ctx.emit(I::LocalGet(mloc));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(mloc));
    ctx.emit(I::Br(0));
    ctx.emit(I::End); // read loop
    ctx.emit(I::End); // read block
    ctx.emit(I::LocalGet(cloc));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(cloc));
    ctx.emit(I::Br(0));
    ctx.emit(I::End); // color loop
    ctx.emit(I::End); // color block

    // rt_solve_lin_sparse_cached(handle, colptr, rowidx, values, b, n, nnz).
    ctx.emit(I::I32Const(handle));
    ctx.emit(I::LocalGet(base));
    ctx.emit(I::I32Const(colptr_off as i32));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalGet(base));
    ctx.emit(I::I32Const(rowidx_off as i32));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalGet(base)); // values_off == 0
    ctx.emit(I::LocalGet(base));
    ctx.emit(I::I32Const(b_off as i32));
    ctx.emit(I::I32Add);
    ctx.emit(I::I32Const(n as i32));
    ctx.emit(I::I32Const(nnz as i32));
    ctx.emit(I::Call(rt_index("rt_solve_lin_sparse_cached")?));
    emit_singular_check(ctx)?;
    emit_scatter_recover_free(ctx, base, b_off, n, &slots, lower_inner)
}

/// C's linear sparse-solver selection: density below `lssMaxDensity` (default
/// 0.2) OR size above `lssMinSize` (default 1000). See
/// `SimulationRuntime/c/simulation/solver/linearSystem.c`.
pub(crate) const LSS_MAX_DENSITY: f64 = 0.2;
pub(crate) const LSS_MIN_SIZE: usize = 1000;
pub(crate) fn lin_use_sparse(size: usize, nnz: usize) -> bool {
    (nnz as f64) < LSS_MAX_DENSITY * (size * size) as f64 || size > LSS_MIN_SIZE
}

/// Lower a `SES_LINEAR` system given symbolically as `A x = b` from `simJac`/`beqs`
/// (the C runtime's `setLinearMatrixA`/`setLinearVectorb`): `a_entries` are the
/// nonzero elements `(row, col, exp)` (0-based, column-major); `b_exps` the dense
/// right-hand side; both evaluate directly from already-solved variables — no
/// residual probing. Solve `A x = b`, write each `x_j` back into its slot, then
/// (torn systems) run `inner` to recover the non-iteration torn variables.
///
/// Dense (`rt_linsolve`, LAPACK-like) or sparse (`rt_solve_lin_sparse`, KLU-like
/// AMD-ordered CSC LU) per [`lin_use_sparse`], matching C's per-system choice.
pub(crate) fn compile_linear_system_symbolic(
    ctx: &mut FnCtx,
    vars: &[Arc<DAE::ComponentRef>],
    n: usize,
    a_entries: &[(usize, usize, &Arc<DAE::Exp>)],
    b_exps: &[&Arc<DAE::Exp>],
    inner: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
    _index: i32,
) -> Result<()> {
    use we::Instruction as I;
    if n == 0 {
        return Ok(());
    }
    if b_exps.len() != n {
        return Err("CodegenWasmJit: SES_LINEAR unknown/b-entry count mismatch");
    }
    for &(row, col, _) in a_entries {
        if row >= n || col >= n {
            return Err("CodegenWasmJit: SES_LINEAR simJac entry out of range for size");
        }
    }
    let mut slots: Vec<u32> = Vec::with_capacity(n);
    for cr in vars {
        let key = sim_cref_key(cr)?;
        let slot = ctx
            .sim()?
            .vars
            .get(&key)
            .copied()
            .ok_or_else(|| "CodegenWasmJit: linear-system unknown has no slot")?;
        if slot.wty != WTy::F64 {
            return Err("CodegenWasmJit: linear-system unknown is not a Real variable");
        }
        slots.push(slot.off);
    }
    let data = ctx.sim()?.data_local;
    let use_sparse = lin_use_sparse(n, a_entries.len());

    let base = ctx.alloc_temp(WTy::I32);
    // `b` lives at the same offset in both layouts (after the matrix region), so
    // the scatter/solve `b` handling is shared.
    let b_off: u32;

    if use_sparse {
        // CSC layout: colptr (n+1 i32) | rowidx (nnz i32) | values (nnz f64) | b (n f64).
        let nnz = a_entries.len();
        // Column-major, row-sorted within a column (CSC requires it; simJac is
        // already column-major but re-sort defensively).
        let mut entries: Vec<(usize, usize, &Arc<DAE::Exp>)> = a_entries.to_vec();
        entries.sort_by_key(|&(row, col, _)| (col, row));
        let mut colptr = vec![0i32; n + 1];
        for &(_, col, _) in &entries {
            colptr[col + 1] += 1;
        }
        for c in 0..n {
            colptr[c + 1] += colptr[c];
        }
        let colptr_off: u32 = 0;
        let rowidx_off: u32 = ((n + 1) * 4) as u32;
        let values_off: u32 = rowidx_off + (nnz * 4) as u32;
        b_off = values_off + (nnz * 8) as u32;
        let scratch_bytes: u32 = b_off + (n * 8) as u32;
        ctx.emit(I::I32Const(scratch_bytes as i32));
        ctx.emit(I::Call(rt_index("rt_alloc")?));
        ctx.emit(I::LocalSet(base));
        // colptr + rowidx: compile-time constants.
        for (c, &p) in colptr.iter().enumerate() {
            ctx.emit(I::LocalGet(base));
            ctx.emit(I::I32Const(p));
            ctx.emit(I::I32Store(mem_arg(colptr_off + (c as u32) * 4, 2)));
        }
        for (k, &(row, _, _)) in entries.iter().enumerate() {
            ctx.emit(I::LocalGet(base));
            ctx.emit(I::I32Const(row as i32));
            ctx.emit(I::I32Store(mem_arg(rowidx_off + (k as u32) * 4, 2)));
        }
        // values: runtime-evaluated element expressions.
        for (k, &(_, _, exp)) in entries.iter().enumerate() {
            ctx.emit(I::LocalGet(base));
            let w = compile_exp(ctx, exp)?;
            coerce(ctx, w, WTy::F64);
            ctx.emit(I::F64Store(mem_arg(values_off + (k as u32) * 8, 3)));
        }
        emit_b_exps(ctx, base, b_off, b_exps)?;
        // rt_solve_lin_sparse(colptr, rowidx, values, b, n, nnz).
        ctx.emit(I::LocalGet(base)); // colptr (off 0)
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::I32Const(rowidx_off as i32));
        ctx.emit(I::I32Add);
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::I32Const(values_off as i32));
        ctx.emit(I::I32Add);
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::I32Const(b_off as i32));
        ctx.emit(I::I32Add);
        ctx.emit(I::I32Const(n as i32));
        ctx.emit(I::I32Const(nnz as i32));
        ctx.emit(I::Call(rt_index("rt_solve_lin_sparse")?));
    } else {
        // Dense layout: A (n*n column-major) | b (n).
        let a_off: u32 = 0;
        b_off = (n * n * 8) as u32;
        let scratch_bytes: u32 = ((n * n + n) * 8) as u32;
        ctx.emit(I::I32Const(scratch_bytes as i32));
        ctx.emit(I::Call(rt_index("rt_alloc")?));
        ctx.emit(I::LocalSet(base));
        // Zero A (simJac lists only nonzeros; rt_alloc does not zero).
        for idx in 0..(n * n) {
            ctx.emit(I::LocalGet(base));
            ctx.emit(I::F64Const(0.0f64.into()));
            ctx.emit(I::F64Store(mem_arg(a_off + (idx as u32) * 8, 3)));
        }
        // A[row + col*n] = element expression (column-major).
        for &(row, col, exp) in a_entries {
            let elem_off = a_off + ((col * n + row) as u32) * 8;
            ctx.emit(I::LocalGet(base));
            let w = compile_exp(ctx, exp)?;
            coerce(ctx, w, WTy::F64);
            ctx.emit(I::F64Store(mem_arg(elem_off, 3)));
        }
        emit_b_exps(ctx, base, b_off, b_exps)?;
        // rt_linsolve(a_ptr, b_ptr, n).
        ctx.emit(I::LocalGet(base)); // a_ptr (a_off == 0)
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::I32Const(b_off as i32));
        ctx.emit(I::I32Add);
        ctx.emit(I::I32Const(n as i32));
        ctx.emit(I::Call(rt_index("rt_linsolve")?));
    }

    ctx.emit(I::If(we::BlockType::Empty)); // nonzero => singular
    emit_runtime_error(ctx, "wasm-jit: linear system is singular (no unique solution)")?;
    ctx.emit(I::End);

    // Scatter the solution into the unknown slots.
    for j in 0..n {
        ctx.emit(I::LocalGet(data));
        ctx.emit(I::LocalGet(base));
        ctx.emit(I::F64Load(mem_arg(b_off + (j as u32) * 8, 3)));
        ctx.emit(I::F64Store(mem_arg(slots[j], 3)));
    }

    // Recover the non-iteration torn variables at the solution (no-op for the
    // non-torn form, whose `inner` is empty).
    inner(ctx)?;

    ctx.emit(I::LocalGet(base));
    ctx.emit(I::Call(rt_index("rt_free")?));
    Ok(())
}

/// Emit `b[i] = exp` into the solve scratch at `base + b_off + i*8`.
fn emit_b_exps(
    ctx: &mut FnCtx,
    base: u32,
    b_off: u32,
    b_exps: &[&Arc<DAE::Exp>],
) -> Result<()> {
    for (i, exp) in b_exps.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(base));
        let w = compile_exp(ctx, exp)?;
        coerce(ctx, w, WTy::F64);
        ctx.emit(we::Instruction::F64Store(mem_arg(b_off + (i as u32) * 8, 3)));
    }
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
    ctx.emit(I::I32Const((3 * job.k) as i32));
    ctx.emit(I::I32Add); // residual table index
    ctx.emit(I::GlobalGet(NLS_BASE_GLOBAL));
    ctx.emit(I::I32Const((3 * job.k + 1) as i32));
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
    // nominal block address (x-scaling).
    ctx.emit(I::GlobalGet(NLS_NOMINAL_GLOBAL));
    ctx.emit(I::I32Const(job.nominal_off as i32));
    ctx.emit(I::I32Add);
    // analytic-Jacobian table index, or `u32::MAX` when the system has none.
    if job.has_jac {
        ctx.emit(I::GlobalGet(NLS_BASE_GLOBAL));
        ctx.emit(I::I32Const((3 * job.k + 2) as i32));
        ctx.emit(I::I32Add);
    } else {
        ctx.emit(I::I32Const(-1)); // u32::MAX sentinel
    }
    ctx.emit(I::Call(rt_index("rt_solve_nls")?));
    ctx.emit(I::Drop);
    Ok(())
}
