//! Asserts, terminate, model errors, the initial flag, math domain guards.

use super::*;

/// `terminate(msg)`: raise the `SimData` terminate flag, which the drivers poll
/// after each communication point, and fill C's `TermMsg`/`TermInfo` slots.
/// Shared by `STMT_TERMINATE` and the `when`-body `TERMINATE`.
pub(super) fn emit_terminate(ctx: &mut FnCtx, message: &DAE::Exp, source: &DAE::ElementSource) -> Result<()> {
    let data = ctx.sim()?.data_local;
    let off = ctx.sim()?.terminate_off;
    let info_off = ctx.sim()?.term_info_off;
    let info = &source.info;
    let file = openmodelica_util::Testsuite::friendly(info.fileName.clone())?;
    ctx.emit(we::Instruction::LocalGet(data));
    let mw = compile_exp(ctx, message)?;
    if mw != WTy::I32 {
        return Err("CodegenWasmJit: terminate message is not a String");
    }
    ctx.emit(we::Instruction::I32Store(mem_arg(info_off, 2)));
    ctx.emit(we::Instruction::LocalGet(data));
    emit_str_literal(ctx, file.as_bytes())?;
    ctx.emit(we::Instruction::I32Store(mem_arg(info_off + 4, 2)));
    let pos = [
        info.lineNumberStart,
        info.columnNumberStart,
        info.lineNumberEnd,
        info.columnNumberEnd,
        info.isReadOnly as i32,
    ];
    for (i, v) in pos.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::I32Const(*v));
        ctx.emit(we::Instruction::I32Store(mem_arg(info_off + 8 + i as u32 * 4, 2)));
    }
    ctx.emit(we::Instruction::LocalGet(data));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Store(mem_arg(off, 2)));
    Ok(())
}

/// C's `assertCommon`: `if (!cond) { rt_assert(msg, assert_cond, file, line/col…);
/// unreachable }`, the host formatting the three as `omc_assert` does. A warning-level
/// assert (`AssertionLevel.warning`, `level` enum index 1 — the min/max attribute
/// checks) calls `rt_assert_warning` and continues instead, as C's
/// `omc_assert_warning`, and latches a per-site flag so it reports once — C's
/// `if(!warningTriggered)` around the whole test. Shared by `STMT_ASSERT` and the
/// `when`-body `ASSERT`.
pub(super) fn emit_assert(
    ctx: &mut FnCtx,
    cond: &Arc<DAE::Exp>,
    msg: &DAE::Exp,
    level: &DAE::Exp,
    source: &DAE::ElementSource,
) -> Result<()> {
    let is_warning = matches!(level, DAE::Exp::ENUM_LITERAL { index: 1, .. });
    // C's `FUNCTION_CONTEXT` arm reports the message alone, with no dumped condition.
    let in_function = ctx.sim().is_err();
    let warn_flag = is_warning.then(shared_lits::new_flag);
    if let Some(g) = warn_flag {
        ctx.emit(we::Instruction::GlobalGet(g));
        ctx.emit(we::Instruction::I32Eqz);
        ctx.emit(we::Instruction::If(we::BlockType::Empty));
    }
    let c = compile_exp(ctx, cond)?;
    coerce(ctx, c, WTy::I32);
    ctx.emit(we::Instruction::I32Eqz);
    ctx.emit(we::Instruction::If(we::BlockType::Empty));
    let info = &source.info;
    let file = openmodelica_util::Testsuite::friendly(info.fileName.clone())?;
    if let Some(g) = warn_flag {
        // The dumped condition (C's `assert_cond`), then the message, then the
        // source position — all consumed by `rt_assert_warning`; execution
        // continues afterwards (no trap).
        let dumped = if in_function { String::new() } else { dumped_exp(cond)? };
        emit_str_literal(ctx, dumped.as_bytes())?; // dumped condition
        let mw = compile_exp(ctx, msg)?; // owned message String handle
        if mw != WTy::I32 {
            return Err("CodegenWasmJit: assert message is not a String");
        }
        emit_str_literal(ctx, file.as_bytes())?; // file String handle
        ctx.emit(we::Instruction::I32Const(info.lineNumberStart));
        ctx.emit(we::Instruction::I32Const(info.columnNumberStart));
        ctx.emit(we::Instruction::I32Const(info.lineNumberEnd));
        ctx.emit(we::Instruction::I32Const(info.columnNumberEnd));
        ctx.emit(we::Instruction::I32Const(info.isReadOnly as i32));
        emit_initial_flag(ctx);
        ctx.emit(we::Instruction::Call(env_extra_index("rt_assert_warning")?));
        ctx.emit(we::Instruction::I32Const(1));
        ctx.emit(we::Instruction::GlobalSet(g));
        ctx.emit(we::Instruction::End); // if (!cond)
        ctx.emit(we::Instruction::End); // if (!warningTriggered)
        return Ok(());
    }
    // C evaluates the message (`preExpMsg`) once, ahead of either arm.
    let mw = compile_exp(ctx, msg)?; // owned message String handle
    if mw != WTy::I32 {
        return Err("CodegenWasmJit: assert message is not a String");
    }
    let msg_h = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(msg_h));
    // Both arms take these; `initial` and `sim_data` follow.
    let mut report_args = |ctx: &mut FnCtx| -> Result<()> {
        ctx.emit(we::Instruction::LocalGet(msg_h));
        emit_str_literal(ctx, file.as_bytes())?; // file String handle
        ctx.emit(we::Instruction::I32Const(info.lineNumberStart));
        ctx.emit(we::Instruction::I32Const(info.columnNumberStart));
        ctx.emit(we::Instruction::I32Const(info.lineNumberEnd));
        ctx.emit(we::Instruction::I32Const(info.columnNumberEnd));
        ctx.emit(we::Instruction::I32Const(info.isReadOnly as i32));
        if in_function {
            ctx.emit(we::Instruction::I32Const(0));
        } else {
            emit_str_literal(ctx, dumped_exp(cond)?.as_bytes())?; // dumped condition, for the report
        }
        Ok(())
    };
    // A residual's own assert is C's `ERROR_NONLINEARSOLVER`: logged where it fires,
    // then unwound into the solver — unless the `noThrowAsserts` window is open,
    // which C checks first; `rt_assert` then records it and the evaluation goes on.
    // C's `FUNCTION_CONTEXT` arm has no such check, so a function's assert throws
    // whatever the window says (a domain guard the solver must back off from).
    ctx.emit(we::Instruction::Call(rt_index("rt_nls_recovering")?));
    if !in_function {
        ctx.emit(we::Instruction::Call(rt_index("rt_assert_suppressed")?));
        ctx.emit(we::Instruction::I32Eqz);
        ctx.emit(we::Instruction::I32And);
    }
    ctx.emit(we::Instruction::If(we::BlockType::Empty));
    report_args(ctx)?;
    emit_initial_flag(ctx);
    emit_sim_data_or_zero(ctx);
    ctx.emit(we::Instruction::Call(rt_index("rt_nls_assert_failed")?));
    release_heap_locals(ctx)?;
    push_outputs(ctx);
    ctx.emit(we::Instruction::Return);
    ctx.emit(we::Instruction::End);
    report_args(ctx)?;
    emit_initial_flag(ctx);
    emit_sim_data_or_zero(ctx);
    ctx.emit(we::Instruction::Call(env_extra_index("rt_assert")?));
    // Unwind unless the driver took it (suppressed during the event search).
    ctx.emit(we::Instruction::If(we::BlockType::Empty));
    emit_assert_unwind(ctx);
    ctx.emit(we::Instruction::End);
    ctx.emit(we::Instruction::End);
    Ok(())
}

/// The running `SimData` pointer, or 0 outside a simulation.
pub(super) fn emit_sim_data_or_zero(ctx: &mut FnCtx) {
    match ctx.sim.as_ref().map(|s| s.data_local) {
        Some(data) => ctx.emit(we::Instruction::LocalGet(data)),
        None => ctx.emit(we::Instruction::I32Const(0)),
    }
}

/// A model error inside a nonlinear-solver residual is recoverable in C
/// (`ERROR_NONLINEARSOLVER` longjmps out and the solver shortens the step): note it
/// and return, leaving the outputs at their entry values.
pub(super) fn emit_nls_recoverable_return(ctx: &mut FnCtx) -> Result<()> {
    ctx.emit(we::Instruction::Call(rt_index("rt_nls_recovering")?));
    ctx.emit(we::Instruction::If(we::BlockType::Empty));
    ctx.emit(we::Instruction::Call(rt_index("rt_nls_note_assert")?));
    release_heap_locals(ctx)?;
    push_outputs(ctx);
    ctx.emit(we::Instruction::Return);
    ctx.emit(we::Instruction::End);
    Ok(())
}

/// C's `assertCommonVar` for a model error whose message String handle is on the
/// stack. Where a solver or the step catches the unwind, the evaluation returns with
/// its outputs untouched, as [`emit_nls_recoverable_return`] does.
fn emit_model_error(ctx: &mut FnCtx) -> Result<()> {
    use we::Instruction as I;
    // C's `FUNCTION_CONTEXT` arm is `omc_assert(threadData, omc_dummyFileInfo, msg)`,
    // which a simulation binds to `omc_assert_simulation` — `emit_assert`'s two arms.
    if ctx.sim.is_none() {
        let msg = ctx.alloc_temp(WTy::I32);
        ctx.emit(I::LocalSet(msg));
        let mut report_args = |ctx: &mut FnCtx| -> Result<()> {
            ctx.emit(I::LocalGet(msg));
            emit_str_literal(ctx, b"")?; // file
            for _ in 0..5 {
                ctx.emit(I::I32Const(0)); // line/col start+end, isReadOnly
            }
            ctx.emit(I::I32Const(0)); // no condition: never suppressed
            emit_initial_flag(ctx);
            emit_sim_data_or_zero(ctx);
            Ok(())
        };
        ctx.emit(I::Call(rt_index("rt_nls_recovering")?));
        ctx.emit(I::If(we::BlockType::Empty));
        report_args(ctx)?;
        ctx.emit(I::Call(rt_index("rt_nls_assert_failed")?));
        release_heap_locals(ctx)?;
        push_outputs(ctx);
        ctx.emit(I::Return);
        ctx.emit(I::End);
        report_args(ctx)?;
        ctx.emit(I::Call(env_extra_index("rt_assert")?));
        ctx.emit(I::Drop); // a model error is never suppressed
        emit_assert_unwind(ctx);
        return Ok(());
    }
    emit_sim_data_or_zero(ctx);
    emit_initial_flag(ctx);
    ctx.emit(I::Call(rt_index("rt_assert_common")?));
    let taken = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::LocalSet(taken));
    ctx.emit(I::LocalGet(taken));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Eq);
    ctx.emit(I::If(we::BlockType::Empty));
    release_heap_locals(ctx)?;
    push_outputs(ctx);
    ctx.emit(I::Return);
    ctx.emit(I::End);
    // 2 is C's `noThrowAsserts`: fall through and use the out-of-domain value.
    ctx.emit(I::LocalGet(taken));
    ctx.emit(I::I32Eqz);
    ctx.emit(I::If(we::BlockType::Empty));
    emit_assert_unwind(ctx);
    ctx.emit(I::End);
    Ok(())
}

/// 0 outside a simulation: C's `FUNCTION_CONTEXT` arm prints no header at all.
pub(super) fn emit_initial_flag(ctx: &mut FnCtx) {
    match ctx.sim.as_ref().map(|s| (s.data_local, s.initial_off)) {
        Some((data, off)) => {
            ctx.emit(we::Instruction::LocalGet(data));
            ctx.emit(we::Instruction::I32Load(mem_arg(off, 2)));
        }
        None => ctx.emit(we::Instruction::I32Const(0)),
    }
}

/// The dumped source form of `e`, for embedding in an assertion message.
pub(crate) fn dumped_exp(e: &Arc<DAE::Exp>) -> Result<String> {
    Ok(Tpl::textString(ExpressionDumpTpl::dumpExp(Tpl::emptyTxt.clone(), e.clone(), arcstr::literal!("\""))?)?.to_string())
}

/// A math builtin's accepted interval and the message text around the `%g`.
pub(super) struct Domain {
    low: f64,
    low_strict: bool,
    high: Option<f64>,
    head: &'static str,
    tail: &'static str,
}

/// The guard C's `daeExpCall` emits for `name`, `None` where the whole range is valid.
pub(super) fn math_domain(name: &str) -> Option<Domain> {
    match name {
        "asin" | "acos" => Some(Domain {
            low: -1.0,
            low_strict: false,
            high: Some(1.0),
            head: "outside the domain -1.0 <= ",
            tail: " <= 1.0",
        }),
        "log" | "log10" => Some(Domain {
            low: 0.0,
            low_strict: true,
            high: None,
            head: "was ",
            tail: " should be > 0",
        }),
        "sqrt" => Some(Domain {
            low: 0.0,
            low_strict: false,
            high: None,
            head: "was ",
            tail: " should be >= 0",
        }),
        _ => None,
    }
}

/// C's `daeExpCall` guard (`CodegenCFunctions.tpl`): evaluate `arg` into a temp,
/// assert its domain, leave it on the stack for the caller's call.
pub(super) fn emit_math_domain_guard(ctx: &mut FnCtx, name: &str, arg: &Arc<DAE::Exp>, d: &Domain) -> Result<()> {
    use we::Instruction as I;
    let w = compile_exp(ctx, arg)?;
    coerce(ctx, w, WTy::F64);
    let t = ctx.alloc_temp(WTy::F64);
    ctx.emit(I::LocalTee(t));
    ctx.emit(I::F64Const(d.low.into()));
    ctx.emit(if d.low_strict { I::F64Gt } else { I::F64Ge });
    if let Some(high) = d.high {
        ctx.emit(I::LocalGet(t));
        ctx.emit(I::F64Const(high.into()));
        ctx.emit(I::F64Le);
        ctx.emit(I::I32And);
    }
    ctx.emit(I::I32Eqz);
    ctx.emit(I::If(we::BlockType::Empty));
    let call = format!("{name}({})", dumped_exp(arg)?);
    emit_str_literal(ctx, format!("Model error: Argument of {call} {}", d.head).as_bytes())?;
    ctx.emit(I::LocalGet(t));
    ctx.emit(I::I32Const(6)); // significant digits (C's `%g`)
    ctx.emit(I::I32Const(0)); // minimum length
    ctx.emit(I::I32Const(0)); // left justified
    ctx.emit(I::Call(rt_index("rt_real_format")?));
    ctx.emit(I::Call(rt_index("rt_concat")?));
    emit_str_literal(ctx, d.tail.as_bytes())?;
    ctx.emit(I::Call(rt_index("rt_concat")?));
    emit_model_error(ctx)?;
    ctx.emit(I::End);

    ctx.emit(I::LocalGet(t));
    Ok(())
}

/// `nthRoot(v, n) = copysign(pow(|v|, 1/n), v)` — the real n-th root,
/// sign-preserving for odd n — guarded by two model-error assertions: n must be
/// > 0, and even n requires v >= 0.
pub(super) fn emit_nth_root(ctx: &mut FnCtx, argv: &[&Arc<DAE::Exp>], name: &str) -> Result<SigTy> {
    need_args(argv, 2, name)?;
    let vw = compile_exp(ctx, argv[0])?;
    coerce(ctx, vw, WTy::F64);
    let vt = ctx.alloc_temp(WTy::F64);
    ctx.emit(we::Instruction::LocalSet(vt));
    let nw = compile_exp(ctx, argv[1])?;
    coerce(ctx, nw, WTy::I32);
    let nt = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(nt));

    let (vstr, nstr) = (dumped_exp(argv[0])?, dumped_exp(argv[1])?);

    // assert(n > 0, "…must be > 0, got <n>")
    ctx.emit(we::Instruction::LocalGet(nt));
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::I32GtS);
    ctx.emit(we::Instruction::I32Eqz);
    ctx.emit(we::Instruction::If(we::BlockType::Empty));
    emit_str_literal(ctx, format!("Model error: Second argument of nthRoot({vstr}, {nstr}) must be > 0, got ").as_bytes())?;
    ctx.emit(we::Instruction::LocalGet(nt));
    ctx.emit(we::Instruction::Call(rt_index("rt_int_string")?));
    ctx.emit(we::Instruction::Call(rt_index("rt_concat")?));
    emit_model_error(ctx)?;
    ctx.emit(we::Instruction::End);

    // assert(mod(n, 2) != 0 or v >= 0, "…must be >= 0 if the second is even, got <v>")
    ctx.emit(we::Instruction::LocalGet(nt));
    ctx.emit(we::Instruction::I32Const(2));
    ctx.emit(we::Instruction::I32RemS);
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::I32Ne);
    ctx.emit(we::Instruction::LocalGet(vt));
    ctx.emit(we::Instruction::F64Const(0.0f64.into()));
    ctx.emit(we::Instruction::F64Ge);
    ctx.emit(we::Instruction::I32Or);
    ctx.emit(we::Instruction::I32Eqz);
    ctx.emit(we::Instruction::If(we::BlockType::Empty));
    emit_str_literal(ctx, format!("Model error: First argument of nthRoot({vstr}, {nstr}) must be >= 0 if the second is even, got ").as_bytes())?;
    ctx.emit(we::Instruction::LocalGet(vt));
    ctx.emit(we::Instruction::I32Const(6)); // significant digits
    ctx.emit(we::Instruction::I32Const(0)); // minimum length
    ctx.emit(we::Instruction::I32Const(0)); // left justified
    ctx.emit(we::Instruction::Call(rt_index("rt_real_format")?));
    ctx.emit(we::Instruction::Call(rt_index("rt_concat")?));
    emit_model_error(ctx)?;
    ctx.emit(we::Instruction::End);

    // copysign(pow(|v|, 1/n), v)
    ctx.emit(we::Instruction::LocalGet(vt));
    ctx.emit(we::Instruction::F64Abs);
    ctx.emit(we::Instruction::F64Const(1.0f64.into()));
    ctx.emit(we::Instruction::LocalGet(nt));
    coerce(ctx, WTy::I32, WTy::F64);
    ctx.emit(we::Instruction::F64Div);
    ctx.emit(we::Instruction::Call(builtin_index("pow").ok_or("CodegenWasmJit: pow builtin missing")?));
    ctx.emit(we::Instruction::LocalGet(vt));
    ctx.emit(we::Instruction::F64Copysign);
    Ok(SigTy::Real)
}

/// `DAEUtil.getStatementSource`.
pub(super) fn stmt_source(stmt: &DAE::Statement) -> &Arc<DAE::ElementSource> {
    use DAE::Statement as S;
    match stmt {
        S::STMT_ASSIGN { source, .. }
        | S::STMT_TUPLE_ASSIGN { source, .. }
        | S::STMT_ASSIGN_ARR { source, .. }
        | S::STMT_IF { source, .. }
        | S::STMT_FOR { source, .. }
        | S::STMT_PARFOR { source, .. }
        | S::STMT_WHILE { source, .. }
        | S::STMT_WHEN { source, .. }
        | S::STMT_ASSERT { source, .. }
        | S::STMT_TERMINATE { source, .. }
        | S::STMT_REINIT { source, .. }
        | S::STMT_NORETCALL { source, .. }
        | S::STMT_RETURN { source, .. }
        | S::STMT_BREAK { source, .. }
        | S::STMT_CONTINUE { source, .. }
        | S::STMT_ARRAY_INIT { source, .. }
        | S::STMT_FAILURE { source, .. } => source,
    }
}
