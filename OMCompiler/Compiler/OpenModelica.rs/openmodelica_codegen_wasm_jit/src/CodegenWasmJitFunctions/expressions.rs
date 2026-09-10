//! Expression compilation: `compile_exp`, type inference, unary/binary
//! operators, division guards.

use super::*;

pub(super) fn compile_exp(ctx: &mut FnCtx, exp: &DAE::Exp) -> Result<WTy> {
    use DAE::Exp as E;
    // A heap-valued constant is one module-wide object (C's `_OMC_LIT`).
    if let Some(w) = shared_lits::compile(ctx, exp)? {
        return Ok(w);
    }
    match exp {
        E::ICONST { integer } => {
            ctx.emit(we::Instruction::I32Const(*integer));
            Ok(WTy::I32)
        }
        E::BCONST { bool } => {
            ctx.emit(we::Instruction::I32Const(*bool as i32));
            Ok(WTy::I32)
        }
        E::RCONST { real } => {
            ctx.emit(we::Instruction::F64Const(real.into_inner().into()));
            Ok(WTy::F64)
        }
        E::ENUM_LITERAL { index, .. } => {
            ctx.emit(we::Instruction::I32Const(*index));
            Ok(WTy::I32)
        }
        // The frontend interns constant literals (strings, but also numeric
        // ones) into a shared pool; the wrapper carries the underlying constant
        // expression, which is what we lower.
        E::SHARED_LITERAL { exp, .. } => compile_exp(ctx, exp),
        // A String literal: materialize a fresh (refcount 1) String from its
        // passive data segment with `memory.init`, so the value is owned exactly
        // like any other heap-producing expression.
        E::SCONST { string } => {
            emit_str_literal(ctx, string.as_bytes())?;
            Ok(WTy::I32)
        }
        E::CREF { componentRef, ty } => {
            if let DAE::Type::T_FUNCTION_REFERENCE_FUNC { .. } = &**ty {
                closures::compile_fnref_cref(ctx, componentRef, ty)?;
                return Ok(WTy::I32);
            }
            // Simulation mode: model variables (states, derivatives, algebraics,
            // parameters, `time`, `$START`/`$PRE`) live in the shared `SimData`
            // block, not in wasm locals. Resolve those first; `None` means an
            // ordinary local that the normal path below handles.
            if let Some(wty) = compile_sim_cref_read(ctx, componentRef)? {
                return Ok(wty);
            }
            // A qualified cref `base[..].f1[..].….fn[..]`: descend through nested
            // records (and arrays of records) to the final field.
            if let DAE::ComponentRef::CREF_QUAL { .. } = &**componentRef {
                return compile_cref_read_qual(ctx, componentRef);
            }
            // A scalar/whole-value reference, or a subscripted array element.
            let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = &**componentRef else {
                return Err("CodegenWasmJit: unsupported component reference");
            };
            let name = ident.to_string();
            let (idx, sty) = ctx
                .locals
                .get(&name)
                .ok_or_else(|| unknown_variable(&name))?
                .clone();
            if subscriptLst.is_empty() {
                ctx.emit(we::Instruction::LocalGet(idx));
                // Reading a heap local yields an *owned* value: retain so the
                // local keeps its reference while the value flows into an
                // operation / assignment / call that will consume one reference.
                // `rt_retain` just bumps the refcount at offset 0, shared by
                // strings and arrays.
                if sty.is_heap() {
                    ctx.emit(we::Instruction::LocalGet(idx));
                    ctx.emit(we::Instruction::Call(rt_index("rt_retain")?));
                }
                Ok(sty.wty())
            } else {
                let SigTy::Array { elem, rank } = sty else {
                    return Err("CodegenWasmJit: subscripting non-array local");
                };
                // The local keeps the array alive for the whole expression, so read
                // the element straight out of it; only a heap element is retained.
                if is_scalar_index(subscriptLst, rank) {
                    let idx_exps = index_subscripts(subscriptLst, rank)?;
                    emit_elem_addr(ctx, idx, &elem, &idx_exps)?;
                    elem_load(ctx, &elem);
                    retain_on_stack(ctx, &elem)?;
                    Ok(elem.wty())
                } else {
                    // The slice path consumes an owned handle.
                    ctx.emit(we::Instruction::LocalGet(idx));
                    ctx.emit(we::Instruction::LocalGet(idx));
                    ctx.emit(we::Instruction::Call(rt_index("rt_retain")?));
                    slice_loaded(ctx, subscriptLst)
                }
            }
        }
        E::CAST { ty, exp } => {
            let target = sig_ty(ty)?;
            // Array casts: the only implicit numeric array cast is Integer[] ->
            // Real[] (e.g. `Real r := intArray`, mixed arithmetic, and division
            // which always yields Real). It must rebuild the array with f64
            // elements — a scalar `coerce` would leave the i32 data misread as
            // f64. Any other array cast is representationally a no-op (the handle
            // already has the right element layout).
            if let SigTy::Array { elem: tgt_elem, .. } = &target {
                let src_is_int = matches!(exp_sigty(exp), Ok(SigTy::Array { ref elem, .. }) if elem.wty() == WTy::I32);
                if tgt_elem.wty() == WTy::F64 && src_is_int {
                    compile_exp(ctx, exp)?; // owned Integer array
                    let at = ctx.alloc_temp(WTy::I32);
                    ctx.emit(we::Instruction::LocalSet(at));
                    ctx.emit(we::Instruction::LocalGet(at));
                    ctx.emit(we::Instruction::Call(rt_index("rt_array_int_to_real")?));
                    release_temp_array(ctx, at)?;
                } else {
                    compile_exp(ctx, exp)?;
                }
                return Ok(WTy::I32);
            }
            let from = compile_exp(ctx, exp)?;
            let to = target.wty();
            coerce(ctx, from, to);
            Ok(to)
        }
        E::UNARY { operator, exp } => compile_unary(ctx, operator, exp),
        E::LUNARY { operator, exp } => {
            // `not` — the only logical unary.
            let DAE::Operator::NOT { .. } = operator else {
                return Err("CodegenWasmJit: unsupported logical unary operator");
            };
            // Element-wise `not` over a Boolean array (`daeExpLunary`).
            if matches!(logical_operator_sigty(operator), Some(SigTy::Array { .. })) {
                emit_unary_array(ctx, exp, "rt_array_not_i32")?;
                return Ok(WTy::I32);
            }
            let w = compile_exp(ctx, exp)?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::I32Eqz);
            Ok(WTy::I32)
        }
        E::BINARY { exp1, operator, exp2 } => compile_binary(ctx, exp1, operator, exp2),
        E::LBINARY { exp1, operator, exp2 } => {
            // Element-wise `and`/`or` over Boolean arrays (operands are array
            // handles, not i32 truth values — a scalar I32And would corrupt them).
            if matches!(logical_operator_sigty(operator), Some(SigTy::Array { .. })) {
                let (op_code, ty) = match operator {
                    DAE::Operator::AND { ty } => (OP_AND, ty),
                    DAE::Operator::OR { ty } => (OP_OR, ty),
                    other => return Err("CodegenWasmJit: unsupported logical array operator"),
                };
                return compile_array_ew(ctx, exp1, exp2, op_code, ty);
            }
            compile_bool_operand(ctx, exp1)?;
            compile_bool_operand(ctx, exp2)?;
            match operator {
                DAE::Operator::AND { .. } => ctx.emit(we::Instruction::I32And),
                DAE::Operator::OR { .. } => ctx.emit(we::Instruction::I32Or),
                other => return Err("CodegenWasmJit: unsupported logical binary operator"),
            }
            Ok(WTy::I32)
        }
        E::RELATION { exp1, operator, exp2, index, optionExpisASUB } => {
            compile_relation(ctx, exp1, operator, exp2, *index, optionExpisASUB)
        }
        E::IFEXP { expCond, expThen, expElse } => {
            let c = compile_exp(ctx, expCond)?;
            coerce(ctx, c, WTy::I32);
            // Determine the result type from the then-branch; both branches are
            // coerced to it.
            let result_wty = exp_wty_hint(ctx, expThen)?;
            ctx.emit(we::Instruction::If(we::BlockType::Result(result_wty.val())));
            let t = compile_exp(ctx, expThen)?;
            coerce(ctx, t, result_wty);
            ctx.emit(we::Instruction::Else);
            let e = compile_exp(ctx, expElse)?;
            coerce(ctx, e, result_wty);
            ctx.emit(we::Instruction::End);
            Ok(result_wty)
        }
        E::CALL { path, expLst, attr } => {
            let results = compile_call(ctx, path, expLst, attr)?;
            if results.is_empty() {
                return Err("CodegenWasmJit: call to used in expression position returns no value");
            }
            // As a value a call is its first output (`daeExpCall`).
            keep_call_result(ctx, &results, 0)
        }
        // Array constructor `{e1, e2, ...}` or matrix `{{...}, {...}}`.
        E::ARRAY { ty, .. } | E::MATRIX { ty, .. } => {
            compile_array_literal(ctx, ty, exp)?;
            Ok(WTy::I32)
        }
        // A range used as an array value, e.g. `a := 1:n` or `1:2:m`.
        E::RANGE { ty, start, step, stop } => {
            compile_range_array(ctx, ty, start, step.as_deref(), stop)?;
            Ok(WTy::I32)
        }
        // Array subscription `a[i]` (single index into a 1-D array).
        E::ASUB { exp, sub } => compile_index(ctx, exp, sub),
        // `size(a)` / `size(a, d)`.
        E::SIZE { exp, sz } => {
            compile_size(ctx, exp, sz.as_deref())?;
            Ok(WTy::I32)
        }
        // Record constructor `R(field=…, …)`.
        E::RECORD { ty, exps, comp, .. } => {
            compile_record(ctx, ty, exps, comp)?;
            Ok(WTy::I32)
        }
        E::METARECORDCALL { path, args, fieldNames, .. } => {
            compile_metarecord(ctx, path, args, fieldNames)?;
            Ok(WTy::I32)
        }
        // Record field access on an expression result: `f().field`.
        E::RSUB { exp, fieldName, .. } => compile_rsub(ctx, exp, fieldName),
        E::REDUCTION { reductionInfo, expr, iterators } => {
            compile_reduction(ctx, reductionInfo, expr, iterators)
        }
        // `f(...)[ix]` — pick one value out of a multi-output call's result
        // tuple.
        E::TSUB { exp, ix, .. } => {
            let DAE::Exp::CALL { path, expLst, attr } = &**exp else {
                return Err("CodegenWasmJit: tuple subscript of a non-call expression");
            };
            let results = compile_call(ctx, path, expLst, attr)?;
            let want = (*ix as usize).checked_sub(1)
                .filter(|&i| i < results.len())
                .ok_or("CodegenWasmJit: tuple subscript index out of range")?;
            keep_call_result(ctx, &results, want)
        }
        // MetaModelica boxing around a call through a function reference; our
        // closures pass values unboxed, so both are the identity.
        E::BOX { exp } | E::UNBOX { exp, .. } => compile_exp(ctx, exp),
        // `function f(w=3)` — a closure over the applied arguments (`closures`).
        E::PARTEVALFUNCTION { .. } => {
            closures::compile_parteval(ctx, exp)?;
            Ok(WTy::I32)
        }
        other => return Err(unsupported_exp(other)),
    }
}

/// Name the expression we could not lower in a recorded message; the `Result`
/// error is a `&'static str`.
fn unsupported_exp(exp: &DAE::Exp) -> &'static str {
    let shown = openmodelica_frontend_dump::ExpressionBasics::printExpStr(Arc::new(exp.clone()))
        .map(|s| s.to_string())
        .unwrap_or_default();
    crate::CodegenWasmJit::record_error(format!(
        "CodegenWasmJit: expression not yet supported: `{shown}` ({}){}",
        exp_variant_name(exp),
        fn_context()
    ));
    "CodegenWasmJit: expression not yet supported"
}

/// The `DAE.Exp` constructor name, for diagnostics.
fn exp_variant_name(exp: &DAE::Exp) -> &'static str {
    use DAE::Exp as E;
    match exp {
        E::ICONST { .. } => "ICONST",
        E::RCONST { .. } => "RCONST",
        E::SCONST { .. } => "SCONST",
        E::BCONST { .. } => "BCONST",
        E::CLKCONST { .. } => "CLKCONST",
        E::ENUM_LITERAL { .. } => "ENUM_LITERAL",
        E::CREF { .. } => "CREF",
        E::BINARY { .. } => "BINARY",
        E::UNARY { .. } => "UNARY",
        E::LBINARY { .. } => "LBINARY",
        E::LUNARY { .. } => "LUNARY",
        E::RELATION { .. } => "RELATION",
        E::IFEXP { .. } => "IFEXP",
        E::CALL { .. } => "CALL",
        E::RECORD { .. } => "RECORD",
        E::PARTEVALFUNCTION { .. } => "PARTEVALFUNCTION",
        E::ARRAY { .. } => "ARRAY",
        E::MATRIX { .. } => "MATRIX",
        E::RANGE { .. } => "RANGE",
        E::TUPLE { .. } => "TUPLE",
        E::CAST { .. } => "CAST",
        E::ASUB { .. } => "ASUB",
        E::TSUB { .. } => "TSUB",
        E::RSUB { .. } => "RSUB",
        E::SIZE { .. } => "SIZE",
        E::CODE { .. } => "CODE",
        E::EMPTY { .. } => "EMPTY",
        E::REDUCTION { .. } => "REDUCTION",
        E::LIST { .. } => "LIST",
        E::CONS { .. } => "CONS",
        E::META_TUPLE { .. } => "META_TUPLE",
        E::META_OPTION { .. } => "META_OPTION",
        E::METARECORDCALL { .. } => "METARECORDCALL",
        E::MATCHEXPRESSION { .. } => "MATCHEXPRESSION",
        E::BOX { .. } => "BOX",
        E::UNBOX { .. } => "UNBOX",
        E::SHARED_LITERAL { .. } => "SHARED_LITERAL",
        E::PATTERN { .. } => "PATTERN",
    }
}

/// A cheap static guess of an expression's wasm type, used to pick the result
/// type of an `if`-expression block before compiling the branches.
fn exp_wty_hint(ctx: &FnCtx, exp: &DAE::Exp) -> Result<WTy> {
    use DAE::Exp as E;
    Ok(match exp {
        E::RCONST { .. } => WTy::F64,
        E::ICONST { .. } | E::BCONST { .. } | E::ENUM_LITERAL { .. } | E::SCONST { .. } | E::RELATION { .. } | E::LBINARY { .. } | E::LUNARY { .. } => WTy::I32,
        E::CAST { ty, .. } => sig_ty(ty)?.wty(),
        // The CREF carries its (possibly field) type directly — handles a plain
        // local and a `r.field` reference alike.
        E::CREF { ty, .. } => sig_ty(ty)?.wty(),
        // Through `exp_sigty` for its operand fallback: taking the operator's
        // own type made the hint fail on `T_UNKNOWN` operators that
        // `compile_binary` compiles fine.
        E::BINARY { .. } | E::UNARY { .. } => exp_sigty(exp)?.wty(),
        E::IFEXP { expThen, .. } => exp_wty_hint(ctx, expThen)?,
        E::CALL { attr, .. } => match identity_builtin_arg(exp) {
            Some(inner) if sig_ty_quiet(&call_value_ty(&attr.ty)).is_err() => exp_wty_hint(ctx, &inner)?,
            _ => sig_ty(&call_value_ty(&attr.ty))?.wty(),
        },
        E::SHARED_LITERAL { exp, .. } => exp_wty_hint(ctx, exp)?,
        // Array/record handles and `size(a, d)` are `i32`; an array element's /
        // record field's wasm type comes from its element / field type.
        E::ARRAY { .. } | E::MATRIX { .. } | E::RANGE { .. } | E::SIZE { .. } | E::RECORD { .. } => WTy::I32,
        E::REDUCTION { reductionInfo, .. } => sig_ty(&reductionInfo.exprType)?.wty(),
        E::RSUB { ty, .. } => sig_ty(ty)?.wty(),
        E::TSUB { ty, .. } => sig_ty(ty)?.wty(),
        E::ASUB { .. } => exp_sigty(exp).map(|s| s.wty()).unwrap_or(WTy::I32),
        E::BOX { exp } => exp_wty_hint(ctx, exp)?,
        E::UNBOX { ty, .. } => sig_ty(ty)?.wty(),
        _ => WTy::F64,
    })
}

/// The integer value of a `Real` literal exponent, or `None` if it is not an
/// integral `RCONST` — mirrors the frontend's `Expression.realExpIntLit`, which
/// the C target uses to pick the `real_int_pow` (repeated-multiply) path for
/// scalar integer powers. Matching it exactly keeps the choice (and the output)
/// in lockstep with the C target.
fn real_exp_int_lit(e: &DAE::Exp) -> Option<i32> {
    if let DAE::Exp::RCONST { real } = e {
        let r = real.into_inner();
        let i = r.floor() as i32;
        if r == i as f64 { Some(i) } else { None }
    } else {
        None
    }
}

/// Whether a `Real` literal exponent is exactly `0.5` — mirrors the frontend's
/// `Expression.isHalf`, which the C target uses to lower `x ^ 0.5` to `sqrt`.
fn exp_is_half(e: &DAE::Exp) -> bool {
    matches!(e, DAE::Exp::RCONST { real } if real.into_inner() == 0.5)
}

/// The `SigTy` an arithmetic operator works on / produces. Unlike a bare
/// `WTy` this distinguishes Integer/Boolean and, crucially, String (so `+` on
/// Strings can be lowered to `rt_concat` rather than `i32.add`).
fn operator_sigty(op: &DAE::Operator) -> Result<SigTy> {
    use DAE::Operator as O;
    let ty = match op {
        O::ADD { ty } | O::SUB { ty } | O::MUL { ty } | O::DIV { ty } | O::POW { ty } | O::UMINUS { ty } => ty,
        // Scalar/matrix products carry the element (scalar-product) or result
        // (matrix-product) type; `sig_ty` yields the produced value's `SigTy`.
        O::MUL_SCALAR_PRODUCT { ty } | O::MUL_MATRIX_PRODUCT { ty } => ty,
        // Element-wise and array/scalar operators all carry the (array) result
        // type. `sig_ty` turns it into the `SigTy::Array { .. }` value type.
        O::UMINUS_ARR { ty }
        | O::ADD_ARR { ty }
        | O::SUB_ARR { ty }
        | O::MUL_ARR { ty }
        | O::DIV_ARR { ty }
        | O::MUL_ARRAY_SCALAR { ty }
        | O::ADD_ARRAY_SCALAR { ty }
        | O::SUB_SCALAR_ARRAY { ty }
        | O::DIV_ARRAY_SCALAR { ty }
        | O::DIV_SCALAR_ARRAY { ty }
        | O::POW_ARRAY_SCALAR { ty }
        | O::POW_SCALAR_ARRAY { ty }
        | O::POW_ARR { ty }
        | O::POW_ARR2 { ty } => ty,
        _ => return Err("CodegenWasmJit: cannot determine type of operator"),
    };
    sig_ty_quiet(ty)
}

/// The result type of `and`/`or`/`not`: `Bool`, or a Boolean array when the
/// operands are arrays. Only the operator records this — a nested logical
/// operand's own type annotation is just the element type.
fn logical_operator_sigty(op: &DAE::Operator) -> Option<SigTy> {
    use DAE::Operator as O;
    let (O::AND { ty } | O::OR { ty } | O::NOT { ty }) = op else { return None };
    sig_ty_quiet(ty).ok()
}

/// The type an operator the frontend left untyped works on: whichever of String,
/// Real or Integer an operand carries, in Modelica's promotion order.
pub(super) fn operand_sigty(e1: &DAE::Exp, e2: &DAE::Exp) -> Result<SigTy> {
    let ops = [exp_sigty(e1).ok(), exp_sigty(e2).ok()];
    for want in [SigTy::Str, SigTy::Real, SigTy::Int] {
        if ops.iter().flatten().any(|s| *s == want) {
            return Ok(want);
        }
    }
    Err("CodegenWasmJit: cannot determine type of operator")
}

/// The value expression an identity builtin wraps. C's `daeExpCall` returns the
/// argument's own expression for these, so the call's type *is* the argument's --
/// which matters where the frontend left the call itself untyped.
fn identity_builtin_arg(exp: &DAE::Exp) -> Option<Arc<DAE::Exp>> {
    let DAE::Exp::CALL { path, expLst, .. } = exp else { return None };
    let name = AbsynUtil::pathLastIdent(path.clone());
    let args: Vec<&Arc<DAE::Exp>> = (&**expLst).into_iter().collect();
    match (name.as_str(), args.len()) {
        ("smooth", 2) => Some(args[1].clone()),
        ("noEvent", 1) | ("$getPart", 1) => Some(args[0].clone()),
        _ => None,
    }
}

/// The type of a call *as a value*: its first output (`daeExpCall`).
fn call_value_ty(ty: &Arc<DAE::Type>) -> Arc<DAE::Type> {
    match &**ty {
        DAE::Type::T_TUPLE { types, .. } => {
            (&**types).into_iter().next().cloned().unwrap_or_else(|| ty.clone())
        }
        _ => ty.clone(),
    }
}

/// The `SigTy` of an expression, from the DAE type annotations it carries (the
/// component reference's `ty`, a call's result `attr.ty`, a literal's kind, …).
/// Used where the *Modelica* type matters beyond the wasm representation — e.g.
/// dispatching `String(x)` on the argument type, or telling an Integer `i32`
/// from a String handle `i32`.
pub(super) fn exp_sigty(exp: &DAE::Exp) -> Result<SigTy> {
    use DAE::Exp as E;
    Ok(match exp {
        E::ICONST { .. } | E::ENUM_LITERAL { .. } => SigTy::Int,
        E::BCONST { .. } => SigTy::Bool,
        E::RCONST { .. } => SigTy::Real,
        E::SCONST { .. } => SigTy::Str,
        E::CREF { ty, .. } => sig_ty_quiet(ty)?,
        E::CALL { attr, .. } => match sig_ty_quiet(&call_value_ty(&attr.ty)) {
            Ok(s) => s,
            Err(e) => match identity_builtin_arg(exp) {
                Some(inner) => exp_sigty(&inner)?,
                None => return Err(e),
            },
        },
        E::CAST { ty, .. } => sig_ty_quiet(ty)?,
        // The new frontend leaves some operators `T_UNKNOWN`; read the operands
        // instead, as `compile_binary` does.
        E::BINARY { exp1, operator, exp2 } => match operator_sigty(operator) {
            Ok(s) => s,
            Err(_) => operand_sigty(exp1, exp2)?,
        },
        E::UNARY { operator, exp } => match operator_sigty(operator) {
            Ok(s) => s,
            Err(_) => exp_sigty(exp)?,
        },
        E::LBINARY { operator, .. } | E::LUNARY { operator, .. } => {
            logical_operator_sigty(operator).unwrap_or(SigTy::Bool)
        }
        E::RELATION { .. } => SigTy::Bool,
        E::IFEXP { expThen, .. } => exp_sigty(expThen)?,
        E::SHARED_LITERAL { exp, .. } => exp_sigty(exp)?,
        // Array-valued expressions carry their (array) type directly.
        E::ARRAY { ty, .. } | E::MATRIX { ty, .. } | E::RANGE { ty, .. } => sig_ty_quiet(ty)?,
        // A reduction's result type is its element/fold type.
        E::REDUCTION { reductionInfo, .. } => sig_ty_quiet(&reductionInfo.exprType)?,
        // `a[subs]`: subscripting reduces the rank by the number of subscripts
        // (a full index yields the scalar element).
        E::ASUB { exp, sub } => {
            let SigTy::Array { elem, rank } = exp_sigty(exp)? else {
                return Err("CodegenWasmJit: subscripting a non-array expression");
            };
            let n = (&**sub).into_iter().count() as u32;
            match rank.checked_sub(n) {
                Some(0) | None => (*elem).clone(),
                Some(left) => SigTy::Array { elem, rank: left },
            }
        }
        // `size(a, d)` is a scalar Integer; `size(a)` is the dimension vector.
        E::SIZE { sz: Some(_), .. } => SigTy::Int,
        E::SIZE { sz: None, .. } => SigTy::Array { elem: Arc::new(SigTy::Int), rank: 1 },
        // A record constructor / field access carry their type directly.
        E::RECORD { ty, .. } | E::RSUB { ty, .. } => sig_ty_quiet(ty)?,
        E::METARECORDCALL { path, .. } => metarecord_sigty(path)?,
        E::TSUB { ty, .. } => sig_ty_quiet(ty)?,
        // A function reference: what the value it produces may be called with.
        E::PARTEVALFUNCTION { ty, .. } => closures::reference_sigty(ty)?,
        E::BOX { exp } => exp_sigty(exp)?,
        E::UNBOX { ty, .. } => sig_ty_quiet(ty)?,
        other => return Err("CodegenWasmJit: cannot determine type of expression"),
    })
}

fn compile_unary(ctx: &mut FnCtx, op: &DAE::Operator, exp: &DAE::Exp) -> Result<WTy> {
    // Array negation `-a`: negate every element into a fresh array.
    if let DAE::Operator::UMINUS_ARR { ty } = op {
        let SigTy::Array { elem, .. } = sig_ty_quiet(ty)? else {
            return Err("CodegenWasmJit: UMINUS_ARR with non-array type");
        };
        let rt = if elem.wty() == WTy::F64 { "rt_array_neg_f64" } else { "rt_array_neg_i32" };
        compile_exp(ctx, exp)?; // owned array
        let at = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalSet(at));
        ctx.emit(we::Instruction::LocalGet(at));
        ctx.emit(we::Instruction::Call(rt_index(rt)?));
        release_temp_array(ctx, at)?;
        return Ok(WTy::I32);
    }
    let DAE::Operator::UMINUS { ty } = op else {
        return Err("CodegenWasmJit: unsupported unary operator");
    };
    // C's `daeExpUnary` lets the operand's type decide; fall back the same way
    // `compile_binary` does when the frontend left the operator `T_UNKNOWN`.
    let wty = match sig_ty_quiet(ty) {
        Ok(s) => s.wty(),
        Err(_) => exp_sigty(exp)?.wty(),
    };
    let w = compile_exp(ctx, exp)?;
    coerce(ctx, w, wty);
    match wty {
        WTy::F64 => ctx.emit(we::Instruction::F64Neg),
        WTy::I32 => {
            // 0 - x: reorder via a temp so the constant 0 is below x.
            let t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(t));
            ctx.emit(we::Instruction::I32Const(0));
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::I32Sub);
        }
    }
    Ok(wty)
}

pub(super) fn compile_binary(ctx: &mut FnCtx, e1: &DAE::Exp, op: &DAE::Operator, e2: &DAE::Exp) -> Result<WTy> {
    use DAE::Operator as O;
    // Element-wise array arithmetic (same-shape arrays) and scalar broadcast.
    // Handled before the scalar paths because `operator_sigty` does not classify
    // the array operators.
    match op {
        O::ADD_ARR { ty } => return compile_array_ew(ctx, e1, e2, OP_ADD, ty),
        O::SUB_ARR { ty } => return compile_array_ew(ctx, e1, e2, OP_SUB, ty),
        O::MUL_ARR { ty } => return compile_array_ew(ctx, e1, e2, OP_MUL, ty),
        O::DIV_ARR { ty } => return compile_array_ew(ctx, e1, e2, OP_DIV, ty),
        // `a + s` / `a * s` (commutative — the array operand is found by type).
        O::ADD_ARRAY_SCALAR { ty } => return compile_array_scalar(ctx, e1, e2, OP_ADD, false, ty),
        O::MUL_ARRAY_SCALAR { ty } => return compile_array_scalar(ctx, e1, e2, OP_MUL, false, ty),
        // `s - a`, `a / s`, `s / a`.
        O::SUB_SCALAR_ARRAY { ty } => return compile_array_scalar(ctx, e1, e2, OP_SUB, true, ty),
        O::DIV_ARRAY_SCALAR { ty } => return compile_array_scalar(ctx, e1, e2, OP_DIV, false, ty),
        O::DIV_SCALAR_ARRAY { ty } => return compile_array_scalar(ctx, e1, e2, OP_DIV, true, ty),
        // `v1 * v2` dot product (scalar result) and `a * b` matrix product
        // (matrix·matrix / matrix·vector / vector·matrix → a fresh array).
        O::MUL_SCALAR_PRODUCT { .. } => return compile_dot(ctx, e1, e2),
        O::MUL_MATRIX_PRODUCT { .. } => return compile_matmul(ctx, e1, e2),
        // Element-wise power: `a .^ b` (POW_ARR2), `a .^ s` (POW_ARRAY_SCALAR)
        // and `s .^ a` (POW_SCALAR_ARRAY). The per-element `pow` runs in-wasm.
        O::POW_ARR2 { ty } => return compile_array_ew(ctx, e1, e2, OP_POW, ty),
        O::POW_ARRAY_SCALAR { ty } => return compile_array_scalar(ctx, e1, e2, OP_POW, false, ty),
        O::POW_SCALAR_ARRAY { ty } => return compile_array_scalar(ctx, e1, e2, OP_POW, true, ty),
        _ => {}
    }
    // C's `daeExpBinary` reads the operator's own type only to tell a String `+`
    // from arithmetic, and otherwise works off the operands' C types; the new
    // frontend leaves some operators `T_UNKNOWN`, so fall back the same way.
    let sig = match operator_sigty(op) {
        Ok(s) => s,
        Err(_) => operand_sigty(e1, e2).map_err(|e| {
            let show = |x: &DAE::Exp| {
                openmodelica_frontend_dump::ExpressionBasics::printExpStr(Arc::new(x.clone()))
                    .map(|s| s.to_string())
                    .unwrap_or_default()
            };
            crate::CodegenWasmJit::record_error(format!(
                "CodegenWasmJit: untyped binary operator between `{}` and `{}`",
                show(e1),
                show(e2)
            ));
            e
        })?,
    };
    // String `+` is concatenation: both operands are String handles, the result
    // is a fresh String handle from the runtime.
    if sig == SigTy::Str {
        let O::ADD { .. } = op else {
            return Err("CodegenWasmJit: unsupported String operator");
        };
        str_binop(ctx, e1, e2, "rt_concat")?;
        return Ok(WTy::I32);
    }
    let wty = sig.wty();
    // POW has no wasm instruction. Mirror the C target's scalar-power dispatch
    // exactly: a literal `0.5` exponent is `sqrt` (with a negative-base check),
    // an integer-literal exponent is exponentiation by squaring
    // (`rt_real_int_pow`), and everything else is the generic `rt_real_pow`
    // (negative-base / odd-root / nan-inf handling). Keeping the same three-way
    // choice as C keeps the output byte-identical.
    if matches!(op, O::POW { .. }) {
        if exp_is_half(e2) {
            // sqrt(base); a negative base is an invalid root. `rt_invalid_root`
            // returns only where the throw is recoverable, as `emit_div_zero_guard`.
            let a = compile_exp(ctx, e1)?;
            coerce(ctx, a, WTy::F64);
            let bt = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalTee(bt));
            ctx.emit(we::Instruction::F64Const(0.0f64.into()));
            ctx.emit(we::Instruction::F64Lt);
            ctx.emit(we::Instruction::If(we::BlockType::Empty));
            ctx.emit(we::Instruction::LocalGet(bt));
            ctx.emit(we::Instruction::F64Const(0.5f64.into()));
            emit_src_loc(ctx);
            ctx.emit(we::Instruction::Call(rt_index("rt_invalid_root")?));
            release_heap_locals(ctx)?;
            push_outputs(ctx);
            ctx.emit(we::Instruction::Return);
            ctx.emit(we::Instruction::End);
            ctx.emit(we::Instruction::LocalGet(bt));
            ctx.emit(we::Instruction::F64Sqrt);
            return Ok(WTy::F64);
        }
        let rt = if let Some(n) = real_exp_int_lit(e2) {
            let a = compile_exp(ctx, e1)?;
            coerce(ctx, a, WTy::F64);
            ctx.emit(we::Instruction::I32Const(n));
            "rt_real_int_pow"
        } else {
            let a = compile_exp(ctx, e1)?;
            coerce(ctx, a, WTy::F64);
            let b = compile_exp(ctx, e2)?;
            coerce(ctx, b, WTy::F64);
            emit_src_loc(ctx);
            "rt_real_pow"
        };
        ctx.emit(we::Instruction::Call(rt_index(rt)?));
        // Integer power keeps Integer type in Modelica: truncate back.
        if wty == WTy::I32 {
            ctx.emit(we::Instruction::I32TruncF64S);
            return Ok(WTy::I32);
        }
        return Ok(WTy::F64);
    }
    let a = compile_exp(ctx, e1)?;
    coerce(ctx, a, wty);
    let b = compile_exp(ctx, e2)?;
    coerce(ctx, b, wty);
    // C's `daeExpBinary` guards every division: `FUNCTION_CONTEXT` throws outright,
    // an equation's is `DIVISION_SIM`.
    if matches!(op, O::DIV { .. }) {
        if ctx.sim.is_none() {
            emit_div_zero_guard(ctx, e1, op, e2, wty)?;
        } else if wty == WTy::F64 {
            return emit_div_sim(ctx, e2);
        }
    }
    match (op, wty) {
        (O::ADD { .. }, WTy::F64) => ctx.emit(we::Instruction::F64Add),
        (O::ADD { .. }, WTy::I32) => ctx.emit(we::Instruction::I32Add),
        (O::SUB { .. }, WTy::F64) => ctx.emit(we::Instruction::F64Sub),
        (O::SUB { .. }, WTy::I32) => ctx.emit(we::Instruction::I32Sub),
        (O::MUL { .. }, WTy::F64) => ctx.emit(we::Instruction::F64Mul),
        (O::MUL { .. }, WTy::I32) => ctx.emit(we::Instruction::I32Mul),
        (O::DIV { .. }, WTy::F64) => ctx.emit(we::Instruction::F64Div),
        (O::DIV { .. }, WTy::I32) => ctx.emit(we::Instruction::I32DivS),
        (other, _) => return Err("CodegenWasmJit: unsupported binary operator"),
    }
    Ok(wty)
}

/// A borrowed handle to a module-wide String literal (C's `_OMC_LIT`), so a guard's
/// message allocates nothing when it fires.
pub(super) fn emit_shared_str(ctx: &mut FnCtx, s: &str) {
    let g = shared_lits::intern_const(&DAE::Exp::SCONST { string: s.into() });
    ctx.emit(we::Instruction::GlobalGet(g));
}

/// Push the `"<file>:<line>: "` prefix a model error raised here reports.
pub(super) fn emit_src_loc(ctx: &mut FnCtx) {
    let s = match &ctx.src_loc {
        Some(i) if i.lineNumberStart > 0 && !i.fileName.is_empty() => {
            let file = openmodelica_util::Testsuite::friendly(i.fileName.clone()).unwrap_or_else(|_| i.fileName.clone());
            format!("{file}:{}: ", i.lineNumberStart)
        }
        _ => String::new(),
    };
    emit_shared_str(ctx, &s);
}

/// The divisor is on the stack: hold it in a temp, and where it is zero throw as
/// C's generated `if (tvar == 0) {throwStreamPrint(…)}` does. The throw returns
/// inside a nonlinear-solver residual, so the function leaves its outputs where
/// they were, as [`emit_nls_recoverable_return`].
fn emit_div_zero_guard(
    ctx: &mut FnCtx,
    e1: &DAE::Exp,
    op: &DAE::Operator,
    e2: &DAE::Exp,
    wty: WTy,
) -> Result<()> {
    use we::Instruction as I;
    let t = ctx.alloc_temp(wty);
    ctx.emit(I::LocalTee(t));
    if wty == WTy::F64 {
        ctx.emit(I::F64Const(0.0f64.into()));
        ctx.emit(I::F64Eq);
    } else {
        ctx.emit(I::I32Const(0));
        ctx.emit(I::I32Eq);
    }
    ctx.emit(I::If(we::BlockType::Empty));
    let exp = Arc::new(DAE::Exp::BINARY {
        exp1: Arc::new(e1.clone()),
        operator: op.clone(),
        exp2: Arc::new(e2.clone()),
    });
    emit_shared_str(ctx, &format!("Division by zero {} in function context", dumped_exp(&exp)?));
    ctx.emit(I::Call(rt_index("rt_throw_stream")?));
    release_heap_locals(ctx)?;
    push_outputs(ctx);
    ctx.emit(I::Return);
    ctx.emit(I::End);
    ctx.emit(I::LocalGet(t));
    Ok(())
}

/// C's `DIVISION_SIM` (`__OMC_DIV_SIM`), with `a` and `b` on the stack. The quotient
/// stands unless the divisor was zero or it came out inf/nan; `rt_div_sim` (nls.rs)
/// has what C does with those.
fn emit_div_sim(ctx: &mut FnCtx, e2: &DAE::Exp) -> Result<WTy> {
    use we::Instruction as I;
    let (ta, tb, res) = (ctx.alloc_temp(WTy::F64), ctx.alloc_temp(WTy::F64), ctx.alloc_temp(WTy::F64));
    ctx.emit(I::LocalSet(tb));
    ctx.emit(I::LocalSet(ta));
    ctx.emit(I::LocalGet(ta));
    ctx.emit(I::LocalGet(tb));
    ctx.emit(I::F64Div);
    // `res - res != 0` is C's `!valid_number(res)`: inf and nan both fail it.
    ctx.emit(I::LocalTee(res));
    ctx.emit(I::LocalGet(res));
    ctx.emit(I::F64Sub);
    ctx.emit(I::F64Const(0.0f64.into()));
    ctx.emit(I::F64Ne);
    ctx.emit(I::LocalGet(tb));
    ctx.emit(I::F64Const(0.0f64.into()));
    ctx.emit(I::F64Eq);
    ctx.emit(I::I32Or);
    ctx.emit(I::If(we::BlockType::Result(we::ValType::F64)));
    ctx.emit(I::LocalGet(ta));
    ctx.emit(I::LocalGet(tb));
    emit_shared_str(ctx, &dumped_exp(&Arc::new(e2.clone()))?);
    let data = ctx.sim()?.data_local;
    ctx.emit(I::LocalGet(data));
    ctx.emit(I::F64Load(mem_arg(0, 3))); // `time` — `SimData` offset 0
    emit_initial_flag(ctx);
    ctx.emit(I::Call(rt_index("rt_div_sim")?));
    ctx.emit(I::Else);
    ctx.emit(I::LocalGet(res));
    ctx.emit(I::End);
    Ok(WTy::F64)
}
