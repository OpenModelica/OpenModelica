//! Strings: concatenation, comparison, substring, `String(...)` formatting,
//! enumeration names.

use super::*;

/// A runtime string op with one heap operand (e.g. `rt_str_len`): the owned
/// operand is released after the call. Leaves the op's result on the stack.
pub(super) fn str_unop(ctx: &mut FnCtx, e: &DAE::Exp, rt_fn: &str) -> Result<()> {
    compile_exp(ctx, e)?;
    let t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(t));
    ctx.emit(we::Instruction::LocalGet(t));
    ctx.emit(we::Instruction::Call(rt_index(rt_fn)?));
    release_temp(ctx, t)?;
    Ok(())
}

/// `substring(s, i, j)`: one heap operand `s` (released after) plus two scalar
/// indices. Leaves the new String handle on the stack.
pub(super) fn str_substring(ctx: &mut FnCtx, s: &DAE::Exp, i: &DAE::Exp, j: &DAE::Exp) -> Result<()> {
    compile_exp(ctx, s)?;
    let ts = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(ts));
    ctx.emit(we::Instruction::LocalGet(ts));
    let wi = compile_exp(ctx, i)?;
    coerce(ctx, wi, WTy::I32);
    let wj = compile_exp(ctx, j)?;
    coerce(ctx, wj, WTy::I32);
    ctx.emit(we::Instruction::Call(rt_index("rt_substring")?));
    release_temp(ctx, ts)?;
    Ok(())
}

/// `String(x[, significantDigits], minimumLength, leftJustified)` — the Modelica
/// builtin. The frontend (`Static.elabBuiltinString`) always fills the format
/// slots, so the argument shapes that reach here are:
///   * `String(Integer|Boolean|String, minimumLength, leftJustified)` (3 args)
///   * `String(Real, significantDigits, minimumLength, leftJustified)` (4 args)
/// matching `Ceval.cevalBuiltinString`. The Real form is the C `printf`
/// conversion `"%[-]{minimumLength}.{significantDigits}g"` (via `rt_real_format`,
/// NOT the shortest-round-trip `realString`); the others format the scalar and
/// then space-pad to `minimumLength` (`rt_str_pad`).
pub(super) fn emit_string_builtin(ctx: &mut FnCtx, argv: &[&Arc<DAE::Exp>]) -> Result<SigTy> {
    // `String(Enumeration)` must render the enumeration literal *name*
    // (`Ceval.cevalBuiltinString` uses `AbsynUtil.pathLastIdent`); the wasm-jit
    // value model carries only the Integer index, so reject rather than silently
    // stringify the index. Carrying enum names would need the literal table
    // threaded through from the DAE type into the sidecar/runtime.
    if exp_is_enumeration(argv[0]) {
        // `String(enum, format)` formats the 1-based index (C's `String(x, "d")`),
        // not the name, and does not trap on an out-of-range value.
        if argv.len() == 2 && exp_sigty(argv[1])? == SigTy::Str {
            return emit_string_format(ctx, argv[0], argv[1], &SigTy::Int);
        }
        let Some(names) = exp_enum_names(argv[0]) else {
            return Err("CodegenWasmJit: String(Enumeration) on an enum literal whose names are not in scope");
        };
        emit_enum_string(ctx, argv[0], &names)?;
        // String(e, minimumLength, leftJustified): pad the name like any scalar.
        if let [_, min_len, left_just] = argv {
            return apply_string_padding(ctx, min_len, left_just);
        }
        return Ok(SigTy::Str);
    }
    let vty = exp_sigty(argv[0])?;
    // `String(String, …)` is the identity: the C target ignores the
    // minimumLength/leftJustified arguments for a string value (see the
    // `"modelica_string"` arm of `CodegenCFunctions.tpl`'s String builtin —
    // `tvar = sExp`), so padding must NOT be applied here either.
    if vty == SigTy::Str {
        return format_scalar_string(ctx, argv[0], vty);
    }
    // The format-string variant `String(value, format)` (`elabBuiltinString`'s
    // second form): a 2-argument call whose second argument is a String. The
    // runtime parses the printf directive (mirroring the C runtime's
    // `modelica_*_to_modelica_string_format`).
    if argv.len() == 2 && exp_sigty(argv[1])? == SigTy::Str {
        return emit_string_format(ctx, argv[0], argv[1], &vty);
    }
    match (&vty, argv.len()) {
        // Bare `String(scalar)` (no format slots) — does not normally reach the
        // codegen (the frontend fills the slots), but is unambiguous.
        (SigTy::Int, 1) | (SigTy::Bool, 1) => format_scalar_string(ctx, argv[0], vty),
        // String(Integer|Boolean, minimumLength, leftJustified).
        (SigTy::Int, 3) | (SigTy::Bool, 3) => {
            emit_padded_scalar_string(ctx, argv[0], vty, argv[1], argv[2])
        }
        // String(Real, significantDigits, minimumLength, leftJustified).
        (SigTy::Real, 4) => emit_real_format(ctx, argv[0], argv[1], argv[2], argv[3]),
        other => return Err("CodegenWasmJit: unsupported String() argument shape"),
    }
}

/// `String(value, format)` — the format-string variant. Evaluate the value and
/// the (owned) format-string handle and dispatch to the runtime formatter, which
/// parses the printf directive at runtime (so the format need not be constant).
/// The runtime borrows the format handle; it is released here afterwards.
fn emit_string_format(ctx: &mut FnCtx, val: &DAE::Exp, fmt: &DAE::Exp, vty: &SigTy) -> Result<SigTy> {
    let rt_fn = match vty {
        SigTy::Real => "rt_string_format_real",
        // Integer and Boolean share the integer formatter (Booleans coerce to
        // 0/1). The String format variant (`%s`) is not yet ported.
        SigTy::Int | SigTy::Bool => "rt_string_format_int",
        other => return Err("CodegenWasmJit: String(value, format) not yet implemented for"),
    };
    let w = compile_exp(ctx, val)?;
    coerce(ctx, w, vty.wty());
    let fmt_t = ctx.alloc_temp(WTy::I32);
    let fw = compile_exp(ctx, fmt)?;
    if fw != WTy::I32 {
        return Err("CodegenWasmJit: String() format argument is not a string");
    }
    ctx.emit(we::Instruction::LocalTee(fmt_t)); // keep the handle, leave it on the stack
    ctx.emit(we::Instruction::Call(rt_index(rt_fn)?));
    // Release the (borrowed) format handle now that formatting is done.
    ctx.emit(we::Instruction::LocalGet(fmt_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_release")?));
    Ok(SigTy::Str)
}

/// Whether `exp` has an enumeration type (so `String(exp)` would need the
/// literal name). Covers the expression forms that carry a `DAE.Type`; anything
/// else is not an enumeration value.
/// Emit a String literal: materialize a fresh (refcount 1) String from a passive
/// data segment with `memory.init`, leaving the owned handle on the stack.
pub(super) fn emit_str_literal(ctx: &mut FnCtx, bytes: &[u8]) -> Result<()> {
    let len = bytes.len() as u32;
    let off = ctx.literals.intern(bytes);
    let obj = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(len as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_str_new")?));
    ctx.emit(we::Instruction::LocalTee(obj));
    // memory.init dest=rt_str_data(obj), src_offset=off, size=len
    ctx.emit(we::Instruction::Call(rt_index("rt_str_data")?));
    ctx.emit(we::Instruction::I32Const(off as i32));
    ctx.emit(we::Instruction::I32Const(len as i32));
    ctx.emit(we::Instruction::MemoryInit { mem: 0, data_index: 0 });
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(())
}

/// Hand the executed `reinit` to the driver for C's `reinit <var> = <value>` line.
/// The state's `SimData` offset names it; the value is re-read from the slot. A
/// state with no static offset (`reinit(x[i], …)`) still reinitializes, just
/// without the log line.
pub(super) fn emit_reinit_note(ctx: &mut FnCtx, stateVar: &DAE::ComponentRef) -> Result<()> {
    let Ok(key) = sim_cref_key(stateVar) else { return Ok(()) };
    let Some(slot) = ctx.sim()?.vars.get(&key).copied() else { return Ok(()) };
    if slot.wty != WTy::F64 {
        return Ok(());
    }
    let data = ctx.sim()?.data_local;
    ctx.emit(we::Instruction::I32Const(slot.off as i32));
    ctx.emit(we::Instruction::LocalGet(data));
    ctx.emit(we::Instruction::F64Load(mem_arg(slot.off, 3)));
    ctx.emit(we::Instruction::Call(env_extra_index("rt_reinit_note")?));
    Ok(())
}

/// Emit `rt_assert(msg, …) ; unreachable`: record a runtime-failure `msg` (via the
/// same host import a failed `assert()` uses, so the simulation drivers surface it
/// instead of a bare `unreachable` trap) then trap. For failures with no source
/// location (a singular/non-converged solver system, an invalid `sqrt`, an
/// out-of-range index) the source info is zeroed. C reports these with
/// `throwStreamPrint`, which a nonlinear solver catches, so the recoverable
/// escape comes first.
pub(super) fn emit_runtime_error(ctx: &mut FnCtx, msg: &str) -> Result<()> {
    emit_nls_recoverable_return(ctx)?;
    emit_str_literal(ctx, msg.as_bytes())?; // message String handle
    for _ in 0..6 {
        ctx.emit(we::Instruction::I32Const(0)); // file handle (null) + zeroed line/col
    }
    ctx.emit(we::Instruction::I32Const(0)); // no condition: never suppressed
    emit_initial_flag(ctx);
    emit_sim_data_or_zero(ctx);
    ctx.emit(we::Instruction::Call(env_extra_index("rt_assert")?));
    ctx.emit(we::Instruction::Drop);
    emit_assert_unwind(ctx);
    Ok(())
}

/// The enumeration literal names of `exp`'s type (unqualified, indexed 1-based
/// by the enum value), or `None` if `exp` is not an enumeration carried by a
/// type we can read the names from.
fn exp_enum_names(exp: &DAE::Exp) -> Option<Vec<ArcStr>> {
    use DAE::Exp as E;
    let names_of = |ty: &DAE::Type| match ty {
        DAE::Type::T_ENUMERATION { names, .. } => Some((&**names).into_iter().cloned().collect()),
        _ => None,
    };
    match exp {
        E::CREF { ty, .. } | E::CAST { ty, .. } => names_of(ty),
        E::CALL { attr, .. } => names_of(&attr.ty),
        E::SHARED_LITERAL { exp, .. } => exp_enum_names(exp),
        _ => None,
    }
}

/// `String(e)` for an enumeration value `e`: render the literal *name* (matching
/// `Ceval.cevalBuiltinString`). The value is the 1-based index; emit a switch
/// that materializes the matching name literal (an out-of-range index traps).
/// Leaves an owned (+1) String handle on the stack.
fn emit_enum_string(ctx: &mut FnCtx, arg: &DAE::Exp, names: &[ArcStr]) -> Result<()> {
    let idx_t = ctx.alloc_temp(WTy::I32);
    let w = compile_exp(ctx, arg)?;
    coerce(ctx, w, WTy::I32);
    ctx.emit(we::Instruction::LocalSet(idx_t));
    ctx.emit(we::Instruction::Block(we::BlockType::Result(we::ValType::I32)));
    for (k, name) in names.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(idx_t));
        ctx.emit(we::Instruction::I32Const(k as i32 + 1));
        ctx.emit(we::Instruction::I32Eq);
        ctx.emit(we::Instruction::If(we::BlockType::Empty));
        emit_str_literal(ctx, name.as_bytes())?;
        ctx.emit(we::Instruction::Br(1)); // break out of the Block with the handle
        ctx.emit(we::Instruction::End); // if
    }
    emit_runtime_error(ctx, "wasm-jit: array/enumeration index out of range")?; // no case matched
    ctx.emit(we::Instruction::End); // block (result = the handle)
    Ok(())
}

fn exp_is_enumeration(exp: &DAE::Exp) -> bool {
    use DAE::Exp as E;
    let is_enum = |ty: &DAE::Type| matches!(ty, DAE::Type::T_ENUMERATION { .. });
    match exp {
        E::ENUM_LITERAL { .. } => true,
        E::CREF { ty, .. } | E::CAST { ty, .. } => is_enum(ty),
        E::CALL { attr, .. } => is_enum(&attr.ty),
        E::SHARED_LITERAL { exp, .. } => exp_is_enumeration(exp),
        _ => false,
    }
}

/// `String(Integer|Boolean|String, minimumLength, leftJustified)`: format the
/// scalar to an owned String handle, then space-pad it to `minimumLength`.
/// A literal `minimumLength` of 0 never pads (`cevalBuiltinStringFormat` returns
/// the string unchanged), so the runtime call is skipped in that common default.
fn emit_padded_scalar_string(
    ctx: &mut FnCtx,
    val: &DAE::Exp,
    vty: SigTy,
    min_len: &DAE::Exp,
    left_just: &DAE::Exp,
) -> Result<SigTy> {
    // Leaves an owned (+1) string handle on the stack.
    format_scalar_string(ctx, val, vty)?;
    apply_string_padding(ctx, min_len, left_just)
}

/// Pad the owned String handle on the stack to `min_len` (space-padded,
/// left-justified per `left_just`), a no-op for a literal-zero `min_len`. The
/// unpadded handle is released; a fresh owned padded handle is left.
fn apply_string_padding(ctx: &mut FnCtx, min_len: &DAE::Exp, left_just: &DAE::Exp) -> Result<SigTy> {
    if let DAE::Exp::ICONST { integer: 0 } = min_len {
        return Ok(SigTy::Str);
    }
    // `rt_str_pad` borrows the unpadded handle and returns a fresh owned one, so
    // the unpadded one is released afterwards.
    let t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(t));
    ctx.emit(we::Instruction::LocalGet(t));
    let wl = compile_exp(ctx, min_len)?;
    coerce(ctx, wl, WTy::I32);
    let wj = compile_exp(ctx, left_just)?;
    coerce(ctx, wj, WTy::I32);
    ctx.emit(we::Instruction::Call(rt_index("rt_str_pad")?));
    release_temp(ctx, t)?;
    Ok(SigTy::Str)
}

/// `String(Real, significantDigits, minimumLength, leftJustified)` → the C `%g`
/// conversion via `rt_real_format`. All four operands are scalars (no heap
/// operands to release); the result is a fresh owned String handle.
fn emit_real_format(
    ctx: &mut FnCtx,
    r: &DAE::Exp,
    sig: &DAE::Exp,
    min_len: &DAE::Exp,
    left_just: &DAE::Exp,
) -> Result<SigTy> {
    let wr = compile_exp(ctx, r)?;
    coerce(ctx, wr, WTy::F64);
    let ws = compile_exp(ctx, sig)?;
    coerce(ctx, ws, WTy::I32);
    let wl = compile_exp(ctx, min_len)?;
    coerce(ctx, wl, WTy::I32);
    let wj = compile_exp(ctx, left_just)?;
    coerce(ctx, wj, WTy::I32);
    ctx.emit(we::Instruction::Call(rt_index("rt_real_format")?));
    Ok(SigTy::Str)
}

/// Format a scalar of the given `SigTy` to an owned String handle via the
/// runtime.
pub(super) fn format_scalar_string(ctx: &mut FnCtx, arg: &DAE::Exp, ty: SigTy) -> Result<SigTy> {
    match ty {
        SigTy::Int => {
            let w = compile_exp(ctx, arg)?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::Call(rt_index("rt_int_string")?));
            Ok(SigTy::Str)
        }
        SigTy::Bool => {
            let w = compile_exp(ctx, arg)?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::Call(rt_index("rt_bool_string")?));
            Ok(SigTy::Str)
        }
        SigTy::Real => emit_real_string(ctx, arg),
        // String(s) is the identity; `compile_exp` already returns an owned copy.
        SigTy::Str => {
            compile_exp(ctx, arg)?;
            Ok(SigTy::Str)
        }
        // `String(array)` / `String(record)` are not scalar conversions (the
        // frontend would not produce them here); reject rather than mis-format.
        SigTy::Array { .. } | SigTy::Record { .. } | SigTy::Ptr | SigTy::Func { .. } => {
            return Err("CodegenWasmJit: String() of an array/record/external-object is not supported")
        }
    }
}

/// `realString(r)` / `String(r)` with default formatting.
pub(super) fn emit_real_string(ctx: &mut FnCtx, arg: &DAE::Exp) -> Result<SigTy> {
    let w = compile_exp(ctx, arg)?;
    coerce(ctx, w, WTy::F64);
    ctx.emit(we::Instruction::Call(rt_index("rt_real_string")?));
    Ok(SigTy::Str)
}
