//! Statements: if/when/else, loops and `for` over ranges and arrays.

use super::*;

pub(super) fn compile_stmt(ctx: &mut FnCtx, stmt: &DAE::Statement) -> Result<()> {
    use DAE::Statement as S;
    ctx.set_src_loc(&stmt_source(stmt).info);
    match stmt {
        S::STMT_ASSIGN { exp1, exp, .. } => compile_assign(ctx, exp1, exp),
        S::STMT_TUPLE_ASSIGN { expExpLst, exp, .. } => compile_tuple_assign(ctx, expExpLst, exp),
        // Whole-array assignment (`r := {...}`, `r := other`); `compile_assign`
        // copies when the source is a variable (value semantics) and moves a
        // fresh constructor/call result.
        S::STMT_ASSIGN_ARR { lhs, exp, .. } => compile_assign(ctx, lhs, exp),
        S::STMT_IF { exp, statementLst, else_, .. } => {
            let c = compile_exp(ctx, exp)?;
            coerce(ctx, c, WTy::I32);
            ctx.emit(we::Instruction::If(we::BlockType::Empty));
            compile_stmts(ctx, statementLst)?;
            compile_else(ctx, else_)?;
            ctx.emit(we::Instruction::End);
            Ok(())
        }
        S::STMT_WHILE { exp, statementLst, .. } => {
            // block { loop { <cond>; i32.eqz; br_if 1; block { <body> }; br 0 } }
            // The inner block is the `continue` target (fall through re-checks the
            // condition); the outer block is the `break` target.
            ctx.emit(we::Instruction::Block(we::BlockType::Empty));
            let break_level = ctx.ctrl_depth;
            ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
            let c = compile_exp(ctx, exp)?;
            coerce(ctx, c, WTy::I32);
            ctx.emit(we::Instruction::I32Eqz);
            ctx.emit(we::Instruction::BrIf(1));
            compile_loop_body(ctx, break_level, statementLst)?;
            ctx.emit(we::Instruction::Br(0));
            ctx.emit(we::Instruction::End); // loop
            ctx.emit(we::Instruction::End); // block
            Ok(())
        }
        S::STMT_RETURN { .. } => {
            release_heap_locals(ctx)?;
            push_outputs(ctx);
            ctx.emit(we::Instruction::Return);
            Ok(())
        }
        S::STMT_NORETCALL { exp, .. } => emit_noretcall(ctx, exp),
        S::STMT_ASSERT { cond, msg, level, source } => emit_assert(ctx, cond, msg, level, source),
        S::STMT_TERMINATE { msg, source } => emit_terminate(ctx, msg, source),
        // `reinit` in an algorithm: the assignment plus the note that the
        // `when`-body REINIT also leaves.
        S::STMT_REINIT { var, value, .. } => {
            let DAE::Exp::CREF { componentRef, .. } = &**var else {
                return Err("CodegenWasmJit: reinit of something other than a variable");
            };
            compile_assign(ctx, var, value)?;
            emit_reinit_note(ctx, componentRef)
        }
        S::STMT_FOR { iter, range, statementLst, type_, .. } => compile_for(ctx, iter, range, statementLst, type_),
        S::STMT_BREAK { .. } => {
            let (brk, _) = *ctx
                .loops
                .last()
                .ok_or_else(|| "CodegenWasmJit: `break` outside a loop")?;
            ctx.branch_to(brk);
            Ok(())
        }
        S::STMT_CONTINUE { .. } => {
            let (_, cont) = *ctx
                .loops
                .last()
                .ok_or_else(|| "CodegenWasmJit: `continue` outside a loop")?;
            ctx.branch_to(cont);
            Ok(())
        }
        S::STMT_WHEN { conditions, statementLst, elseWhen, .. } => {
            compile_stmt_when(ctx, conditions, statementLst, elseWhen)
        }
        other => {
            crate::CodegenWasmJit::record_error(format!(
                "CodegenWasmJit: statement not yet supported: {}", stmt_kind(other)
            ));
            Err("CodegenWasmJit: statement not yet supported")
        }
    }
}

/// Lower a `when {conditions} then body; elsewhen …` algorithm statement, C's
/// `algStmtWhen`: the body runs on the rising edge of any condition
/// (`cond && !pre(cond)`), the elsewhen clause as an `else if` on its own edge.
/// C's `discreteCall == 1` guard is subsumed by the per-step pre-value save, as
/// for when-equations ([`FnCtx::sim_when`]).
fn compile_stmt_when(
    ctx: &mut FnCtx,
    conditions: &List<Arc<DAE::ComponentRef>>,
    stmts: &List<Arc<DAE::Statement>>,
    else_when: &Option<Arc<DAE::Statement>>,
) -> Result<()> {
    use we::Instruction as I;
    let conds: Vec<&Arc<DAE::ComponentRef>> = (&**conditions).into_iter().collect();
    if conds.is_empty() {
        ctx.emit(I::I32Const(0));
    } else {
        for (i, c) in conds.iter().enumerate() {
            if compile_sim_cref_read(ctx, c)?.is_none() {
                return Err("CodegenWasmJit: when-statement condition is not a model variable");
            }
            let pre = pre_cref(c);
            compile_sim_cref_read(ctx, &pre)?;
            ctx.emit(I::I32Eqz); // !pre(cond)
            ctx.emit(I::I32And); // cond && !pre(cond)
            if i > 0 {
                ctx.emit(I::I32Or);
            }
        }
    }
    ctx.emit(I::If(we::BlockType::Empty));
    compile_stmts(ctx, stmts)?;
    if let Some(ew) = else_when {
        ctx.emit(I::Else);
        let DAE::Statement::STMT_WHEN { conditions, statementLst, elseWhen, .. } = &**ew else {
            return Err("CodegenWasmJit: elsewhen is not a when-statement");
        };
        compile_stmt_when(ctx, conditions, statementLst, elseWhen)?;
    }
    ctx.emit(I::End);
    Ok(())
}

/// The variant name of a statement, for diagnostics.
fn stmt_kind(stmt: &DAE::Statement) -> &'static str {
    use DAE::Statement as S;
    match stmt {
        S::STMT_ASSIGN { .. } => "STMT_ASSIGN",
        S::STMT_TUPLE_ASSIGN { .. } => "STMT_TUPLE_ASSIGN",
        S::STMT_ASSIGN_ARR { .. } => "STMT_ASSIGN_ARR",
        S::STMT_IF { .. } => "STMT_IF",
        S::STMT_FOR { .. } => "STMT_FOR",
        S::STMT_PARFOR { .. } => "STMT_PARFOR",
        S::STMT_WHILE { .. } => "STMT_WHILE",
        S::STMT_WHEN { .. } => "STMT_WHEN",
        S::STMT_ASSERT { .. } => "STMT_ASSERT",
        S::STMT_TERMINATE { .. } => "STMT_TERMINATE",
        S::STMT_REINIT { .. } => "STMT_REINIT",
        S::STMT_NORETCALL { .. } => "STMT_NORETCALL",
        S::STMT_RETURN { .. } => "STMT_RETURN",
        S::STMT_BREAK { .. } => "STMT_BREAK",
        S::STMT_CONTINUE { .. } => "STMT_CONTINUE",
        S::STMT_ARRAY_INIT { .. } => "STMT_ARRAY_INIT",
        S::STMT_FAILURE { .. } => "STMT_FAILURE",
    }
}

fn compile_else(ctx: &mut FnCtx, e: &DAE::Else) -> Result<()> {
    match e {
        DAE::Else::NOELSE => Ok(()),
        DAE::Else::ELSE { statementLst } => {
            ctx.emit(we::Instruction::Else);
            compile_stmts(ctx, statementLst)
        }
        DAE::Else::ELSEIF { exp, statementLst, else_ } => {
            ctx.emit(we::Instruction::Else);
            let c = compile_exp(ctx, exp)?;
            coerce(ctx, c, WTy::I32);
            ctx.emit(we::Instruction::If(we::BlockType::Empty));
            compile_stmts(ctx, statementLst)?;
            compile_else(ctx, else_)?;
            ctx.emit(we::Instruction::End);
            Ok(())
        }
    }
}

/// Emit a loop body wrapped in its `continue` block, with the loop registered on
/// `ctx.loops` so nested `break`/`continue` resolve to the right depths. The
/// enclosing `block` (break target) and `loop` frame must already be open;
/// `break_level` is the `ctrl_depth` recorded just after opening the break block.
/// On return the `continue` block is closed, so the caller emits the per-iteration
/// advance (increment / condition re-check) next — `continue` falls through to it.
fn compile_loop_body(
    ctx: &mut FnCtx,
    break_level: u32,
    body: &List<Arc<DAE::Statement>>,
) -> Result<()> {
    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    let continue_level = ctx.ctrl_depth;
    ctx.loops.push((break_level, continue_level));
    let r = compile_stmts(ctx, body);
    ctx.loops.pop();
    r?;
    ctx.emit(we::Instruction::End); // continue block
    Ok(())
}

/// Modelica scopes a loop or reduction iterator to its body, and the name may
/// shadow one the enclosing scope already binds: put that binding back.
pub(super) fn restore_local(ctx: &mut FnCtx, name: &str, prev: Option<(u32, SigTy)>) {
    match prev {
        Some(v) => {
            ctx.locals.insert(name.to_string(), v);
        }
        None => {
            ctx.locals.remove(name);
        }
    }
}

/// Lower a `for iter in range loop ...` statement. A scalar `start:stop` /
/// `start:step:stop` range counts in `i32` with no allocation — Integer,
/// enumeration and Boolean all step through consecutive values; any other
/// iterable — an array variable, an array literal, a slice — is evaluated to an
/// array once and iterated element by element ([`compile_for_array`]).
pub(super) fn compile_for(
    ctx: &mut FnCtx,
    iter: &ArcStr,
    range: &DAE::Exp,
    body: &List<Arc<DAE::Statement>>,
    ty: &DAE::Type,
) -> Result<()> {
    if let DAE::Exp::RANGE { .. } = range
        && let Ok(sty @ (SigTy::Int | SigTy::Bool)) = sig_ty_quiet(ty)
    {
        return compile_for_counting_range(ctx, iter, range, body, sty);
    }
    compile_for_array(ctx, iter, range, body)
}

/// The counter-loop lowering for a scalar counting range (see [`compile_for`]).
fn compile_for_counting_range(
    ctx: &mut FnCtx,
    iter: &ArcStr,
    range: &DAE::Exp,
    body: &List<Arc<DAE::Statement>>,
    sty: SigTy,
) -> Result<()> {
    let DAE::Exp::RANGE { start, step, stop, .. } = range else {
        return Err("CodegenWasmJit: for-loop over non-range expression not supported");
    };
    // Allocate the iterator local and stop/step locals.
    let it = ctx.alloc_temp(WTy::I32);
    let prev = ctx.locals.insert(iter.to_string(), (it, sty));
    let stop_l = ctx.alloc_temp(WTy::I32);
    let step_l = ctx.alloc_temp(WTy::I32);

    let sw = compile_exp(ctx, start)?;
    coerce(ctx, sw, WTy::I32);
    ctx.emit(we::Instruction::LocalSet(it));
    match step {
        Some(e) => {
            let w = compile_exp(ctx, e)?;
            coerce(ctx, w, WTy::I32);
        }
        None => ctx.emit(we::Instruction::I32Const(1)),
    }
    ctx.emit(we::Instruction::LocalSet(step_l));
    let pw = compile_exp(ctx, stop)?;
    coerce(ctx, pw, WTy::I32);
    ctx.emit(we::Instruction::LocalSet(stop_l));
    emit_step_check(ctx, step, step_l)?;

    // block { loop { past stop -> br 1; block { body }; it+=step; br 0 } }
    // The inner block is the `continue` target — falling through runs the increment.
    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    let break_level = ctx.ctrl_depth;
    ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
    emit_range_done(ctx, step, it, step_l, stop_l);
    ctx.emit(we::Instruction::BrIf(1));
    compile_loop_body(ctx, break_level, body)?;
    ctx.emit(we::Instruction::LocalGet(it));
    ctx.emit(we::Instruction::LocalGet(step_l));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(it));
    ctx.emit(we::Instruction::Br(0));
    ctx.emit(we::Instruction::End); // loop
    ctx.emit(we::Instruction::End); // block
    restore_local(ctx, iter, prev);
    Ok(())
}

/// Lower `for x in <array> loop ...`: evaluate the iterable to an array once,
/// then loop `k = 1..total`, binding `x` to `arr[k]` each pass. Handles array
/// literals, array variables and slices — any rank-1 vector.
///
/// The iterator binds a *borrowed* element: the array (`arr_t`) is held for the
/// whole loop, so `x` need not own a reference — the body's heap reads retain on
/// read and release on consume, staying balanced. The slot is recorded in
/// `borrowed_locals` so `release_heap_locals` skips it (it owns nothing), which
/// also makes `break`/early-`return` leak-safe.
pub(super) fn compile_for_array(
    ctx: &mut FnCtx,
    iter: &ArcStr,
    range: &DAE::Exp,
    body: &List<Arc<DAE::Statement>>,
) -> Result<()> {
    let SigTy::Array { elem, rank } = exp_sigty(range)? else {
        return Err("CodegenWasmJit: for-loop over non-array, non-range expression not supported");
    };
    if rank != 1 {
        return Err("CodegenWasmJit: for-loop over a multi-dimensional array not yet supported");
    }
    let elem = (*elem).clone();
    // Evaluate the iterable to an owned array handle.
    compile_exp(ctx, range)?;
    let arr_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(arr_t));
    // n = total element count; k = 1-based counter.
    let n = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalGet(arr_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_total")?));
    ctx.emit(we::Instruction::LocalSet(n));
    let k = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::LocalSet(k));
    let it = ctx.alloc_temp(elem.wty());
    let prev = ctx.locals.insert(iter.to_string(), (it, elem.clone()));
    if elem.is_heap() {
        ctx.borrowed_locals.push(it);
    }

    // block { loop { k>n -> br 1; it = arr[k]; block { body }; k++; br 0 } }
    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    let break_level = ctx.ctrl_depth;
    ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
    ctx.emit(we::Instruction::LocalGet(k));
    ctx.emit(we::Instruction::LocalGet(n));
    ctx.emit(we::Instruction::I32GtS);
    ctx.emit(we::Instruction::BrIf(1));
    // it = arr[k] (borrowed; the array outlives the loop).
    ctx.emit(we::Instruction::LocalGet(arr_t));
    ctx.emit(we::Instruction::LocalGet(k));
    emit_elem_ptr(ctx, &elem)?;
    elem_load(ctx, &elem);
    ctx.emit(we::Instruction::LocalSet(it));
    compile_loop_body(ctx, break_level, body)?;
    ctx.emit(we::Instruction::LocalGet(k));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(k));
    ctx.emit(we::Instruction::Br(0));
    ctx.emit(we::Instruction::End); // loop
    ctx.emit(we::Instruction::End); // block
    release_temp_array(ctx, arr_t)?;
    restore_local(ctx, iter, prev);
    Ok(())
}

/// Emit a constant from a (scalar) `Values.Value` and coerce it to `wty`. Used
/// for a reduction's default/identity value.
pub(super) fn emit_value_const(ctx: &mut FnCtx, v: &Values::Value, wty: WTy) -> Result<()> {
    let from = match v {
        Values::Value::INTEGER { integer } => {
            ctx.emit(we::Instruction::I32Const(*integer));
            WTy::I32
        }
        Values::Value::BOOL { boolean } => {
            ctx.emit(we::Instruction::I32Const(*boolean as i32));
            WTy::I32
        }
        Values::Value::REAL { real } => {
            ctx.emit(we::Instruction::F64Const(real.into_inner().into()));
            WTy::F64
        }
        other => return Err("CodegenWasmJit: unsupported reduction default value"),
    };
    coerce(ctx, from, wty);
    Ok(())
}
