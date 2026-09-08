//! `compile_math_builtin`: the curated scalar builtins.

use super::*;

/// Release a heap value held in scratch local `t` (used to free owned operands
/// after a borrowing runtime op consumed them off the stack).
pub(super) fn release_temp(ctx: &mut FnCtx, t: u32) -> Result<()> {
    ctx.emit(we::Instruction::LocalGet(t));
    ctx.emit(we::Instruction::Call(rt_index("rt_release")?));
    Ok(())
}

/// A runtime string op with two heap operands: each is an owned (+1) value, the
/// runtime only borrows them, so both are released after the call. Leaves the
/// op's result on the stack.
pub(super) fn str_binop(ctx: &mut FnCtx, e1: &DAE::Exp, e2: &DAE::Exp, rt_fn: &str) -> Result<()> {
    compile_exp(ctx, e1)?;
    let t1 = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(t1));
    compile_exp(ctx, e2)?;
    let t2 = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(t2));
    ctx.emit(we::Instruction::LocalGet(t1));
    ctx.emit(we::Instruction::LocalGet(t2));
    ctx.emit(we::Instruction::Call(rt_index(rt_fn)?));
    release_temp(ctx, t1)?;
    release_temp(ctx, t2)?;
    Ok(())
}
