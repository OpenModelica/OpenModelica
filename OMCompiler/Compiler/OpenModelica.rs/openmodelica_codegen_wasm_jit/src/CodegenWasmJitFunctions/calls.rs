//! Calls: user functions, profiling hooks, spatialDistribution, math events.

use super::*;

/// The profiling clock of the generated function `mangled`, in a simulation with
/// `+profiling`; C profiles every non-builtin call outside a function body.
pub(super) fn prof_fn_clock(ctx: &FnCtx, mangled: &str) -> Option<u32> {
    ctx.sim.as_ref()?.prof.as_ref()?.fn_index.get(mangled).copied()
}

/// `rt_prof_tick(clock)` / `rt_prof_acc(clock)` / …, when there is a clock.
pub(crate) fn emit_prof(ctx: &mut FnCtx, clock: Option<u32>, hook: &str) -> Result<()> {
    if let Some(c) = clock {
        ctx.emit(we::Instruction::I32Const(c as i32));
        ctx.emit(we::Instruction::Call(rt_index(hook)?));
    }
    Ok(())
}

/// `(out0, out1) = spatialDistribution(index, in0, in1, x, positiveVelocity,
/// initialPoints, initialValues)` — the backend's form, with the operator index
/// prepended — leaving both outputs on the stack, first result deepest.
/// `initialPoints`/`initialValues` are only used during initialization
/// (`functionInitSpatialDistribution`), as in C.
pub(super) fn compile_spatial_distribution(ctx: &mut FnCtx, args: &List<Arc<DAE::Exp>>) -> Result<()> {
    use we::Instruction as I;
    let argv: Vec<&Arc<DAE::Exp>> = (&**args).into_iter().collect();
    if argv.len() != 7 {
        return Err("CodegenWasmJit: `spatialDistribution` expects the backend's 7-argument form");
    }
    let DAE::Exp::ICONST { integer: index } = &**argv[0] else {
        return Err("CodegenWasmJit: `spatialDistribution` index must be an integer literal");
    };
    let (data, rel_fresh_off) = { let s = ctx.sim()?; (s.data_local, s.rel_fresh_off) };
    ctx.emit(I::I32Const(*index));
    ctx.emit(I::LocalGet(data)); // time (TIME_OFF = 0)
    ctx.emit(I::F64Load(mem_arg(0, 3)));
    for a in &argv[1..4] {
        let w = compile_exp(ctx, a)?; // in0, in1, x
        coerce(ctx, w, WTy::F64);
    }
    let w = compile_exp(ctx, argv[4])?; // positiveVelocity
    coerce(ctx, w, WTy::I32);
    // C's `simulationInfo->discreteCall`: the relation mode is nonzero for an event
    // update and for the initial system, zero during continuous integration.
    ctx.emit(I::LocalGet(data));
    ctx.emit(I::I32Load(mem_arg(rel_fresh_off, 2)));
    ctx.emit(I::Call(rt_index("rt_spatial_eval")?));
    ctx.emit(I::I32Const(*index));
    ctx.emit(I::Call(rt_index("rt_spatial_out1")?));
    Ok(())
}

/// Like [`compile_call`] but for statement position; returns the result types
/// left on the stack (to be released if heap, otherwise dropped).
pub(super) fn compile_call_drop(ctx: &mut FnCtx, exp: &DAE::Exp) -> Result<Vec<SigTy>> {
    let DAE::Exp::CALL { path, expLst, attr } = exp else {
        return Err("CodegenWasmJit: no-return statement is not a call");
    };
    compile_call(ctx, path, expLst, attr)
}

/// Emit `test(fresh operands)` as an f64 for a math-event crossing (fresh args).
pub(super) fn emit_math_test_fresh(
    ctx: &mut FnCtx,
    kind: crate::CodegenWasmJit::MathEventKind,
    ops: &[Arc<DAE::Exp>],
) -> Result<()> {
    use crate::CodegenWasmJit::MathEventKind as K;
    match kind {
        K::Floor | K::Ceil => {
            let w = compile_exp(ctx, &ops[0])?;
            coerce(ctx, w, WTy::F64);
            ctx.emit(if kind == K::Ceil { we::Instruction::F64Ceil } else { we::Instruction::F64Floor });
        }
        K::Div | K::Mod => {
            let a = compile_exp(ctx, &ops[0])?;
            coerce(ctx, a, WTy::F64);
            let b = compile_exp(ctx, &ops[1])?;
            coerce(ctx, b, WTy::F64);
            ctx.emit(we::Instruction::F64Div);
            ctx.emit(if kind == K::Div { we::Instruction::F64Trunc } else { we::Instruction::F64Floor });
        }
    }
    Ok(())
}

/// Emit `test(mathEventsValuePre[idx])` as an f64 (held-value counterpart).
pub(super) fn emit_math_test_pre(
    ctx: &mut FnCtx,
    kind: crate::CodegenWasmJit::MathEventKind,
    idx: u32,
) -> Result<()> {
    use crate::CodegenWasmJit::MathEventKind as K;
    let (data, base) = { let s = ctx.sim()?; (s.data_local, s.mathevents_off + idx * 8) };
    ctx.emit(we::Instruction::LocalGet(data));
    ctx.emit(we::Instruction::F64Load(mem_arg(base, 3)));
    match kind {
        K::Floor => ctx.emit(we::Instruction::F64Floor),
        K::Ceil => ctx.emit(we::Instruction::F64Ceil),
        K::Div | K::Mod => {
            ctx.emit(we::Instruction::LocalGet(data));
            ctx.emit(we::Instruction::F64Load(mem_arg(base + 8, 3)));
            ctx.emit(we::Instruction::F64Div);
            ctx.emit(if kind == K::Div { we::Instruction::F64Trunc } else { we::Instruction::F64Floor });
        }
    }
    Ok(())
}

/// Compile a math-event builtin's value in an equation body (C's `_event_*`):
/// refresh `mathEventsValuePre[idx..]` from the current operands when `rel_fresh !=
/// 0` (event/init), else use the held value; return the discretized result.
fn compile_math_event(
    ctx: &mut FnCtx,
    name: &str,
    ops: &[&Arc<DAE::Exp>],
    idx: u32,
    result_wty: WTy,
) -> Result<SigTy> {
    use we::Instruction as I;
    let (data, base, fresh_off) = {
        let s = ctx.sim()?;
        if idx >= s.n_mathevents {
            return Err("CodegenWasmJit: math-event index out of range");
        }
        (s.data_local, s.mathevents_off + idx * 8, s.rel_fresh_off)
    };
    match name {
        // integer(x): store floor(x), return (int)pre. floor/ceil: store x, return
        // floor/ceil(pre). (C's _event_integer / _event_floor / _event_ceil.)
        "integer" | "floor" | "ceil" => {
            let w = compile_exp(ctx, ops[0])?;
            coerce(ctx, w, WTy::F64);
            let xt = ctx.alloc_temp(WTy::F64);
            ctx.emit(I::LocalSet(xt));
            ctx.emit(I::LocalGet(data));
            ctx.emit(I::I32Load(mem_arg(fresh_off, 2)));
            ctx.emit(I::If(we::BlockType::Empty));
            ctx.emit(I::LocalGet(data));
            ctx.emit(I::LocalGet(xt));
            if name == "integer" { ctx.emit(I::F64Floor); }
            ctx.emit(I::F64Store(mem_arg(base, 3)));
            ctx.emit(I::End);
            ctx.emit(I::LocalGet(data));
            ctx.emit(I::F64Load(mem_arg(base, 3)));
            match name {
                "integer" => { ctx.emit(I::I32TruncSatF64S); Ok(SigTy::Int) }
                "ceil" => { ctx.emit(I::F64Ceil); Ok(SigTy::Real) }
                _ => { ctx.emit(I::F64Floor); Ok(SigTy::Real) }
            }
        }
        // div(a,b)/mod(a,b): store the operands, return the held quotient/modulo.
        // (C's _event_div_*/_event_mod_*.)
        "div" | "mod" => {
            let is_int = result_wty == WTy::I32;
            let wt = if is_int { WTy::I32 } else { WTy::F64 };
            let a = compile_exp(ctx, ops[0])?;
            coerce(ctx, a, wt);
            let at = ctx.alloc_temp(wt);
            ctx.emit(I::LocalSet(at));
            let b = compile_exp(ctx, ops[1])?;
            coerce(ctx, b, wt);
            let bt = ctx.alloc_temp(wt);
            ctx.emit(I::LocalSet(bt));
            ctx.emit(I::LocalGet(data));
            ctx.emit(I::I32Load(mem_arg(fresh_off, 2)));
            ctx.emit(I::If(we::BlockType::Empty));
            ctx.emit(I::LocalGet(data));
            ctx.emit(I::LocalGet(at));
            if is_int { ctx.emit(I::F64ConvertI32S); }
            ctx.emit(I::F64Store(mem_arg(base, 3)));
            ctx.emit(I::LocalGet(data));
            ctx.emit(I::LocalGet(bt));
            if is_int { ctx.emit(I::F64ConvertI32S); }
            ctx.emit(I::F64Store(mem_arg(base + 8, 3)));
            // mod on Reals uses a third slot for the held floor of the ratio
            // (C's _event_mod_real calls _event_floor(x1/x2, index+2)).
            if name == "mod" && !is_int {
                ctx.emit(I::LocalGet(data));
                ctx.emit(I::LocalGet(at));
                ctx.emit(I::LocalGet(bt));
                ctx.emit(I::F64Div);
                ctx.emit(I::F64Store(mem_arg(base + 16, 3)));
            }
            ctx.emit(I::End);
            match (name, is_int) {
                ("div", true) => {
                    ctx.emit(I::LocalGet(data));
                    ctx.emit(I::F64Load(mem_arg(base, 3)));
                    ctx.emit(I::I32TruncF64S);
                    ctx.emit(I::LocalGet(data));
                    ctx.emit(I::F64Load(mem_arg(base + 8, 3)));
                    ctx.emit(I::I32TruncF64S);
                    ctx.emit(I::I32DivS);
                    Ok(SigTy::Int)
                }
                ("div", false) => {
                    ctx.emit(I::LocalGet(data));
                    ctx.emit(I::F64Load(mem_arg(base, 3)));
                    ctx.emit(I::LocalGet(data));
                    ctx.emit(I::F64Load(mem_arg(base + 8, 3)));
                    ctx.emit(I::F64Div);
                    ctx.emit(I::F64Trunc);
                    Ok(SigTy::Real)
                }
                // _event_mod_integer returns the floored modulo of the *current*
                // operands (only the pre-slots are held, for the crossing).
                ("mod", true) => {
                    ctx.emit(I::LocalGet(at));
                    ctx.emit(I::LocalGet(bt));
                    ctx.emit(I::Call(rt_index("rt_mod_int")?));
                    Ok(SigTy::Int)
                }
                // _event_mod_real: current a - floor(held a/b) * current b.
                _ => {
                    ctx.emit(I::LocalGet(at));
                    ctx.emit(I::LocalGet(data));
                    ctx.emit(I::F64Load(mem_arg(base + 16, 3)));
                    ctx.emit(I::F64Floor);
                    ctx.emit(I::LocalGet(bt));
                    ctx.emit(I::F64Mul);
                    ctx.emit(I::F64Sub);
                    Ok(SigTy::Real)
                }
            }
        }
        _ => return Err("CodegenWasmJit: not a math-event builtin"),
    }
}

/// Lower a scalar math builtin. Single-instruction builtins are emitted inline;
/// transcendental ones go through the host imports in [`BUILTINS`].
pub(super) fn compile_math_builtin(
    ctx: &mut FnCtx,
    name: &str,
    args: &List<Arc<DAE::Exp>>,
    attr: &DAE::CallAttributes,
) -> Result<SigTy> {
    let argv: Vec<&Arc<DAE::Exp>> = (&**args).into_iter().collect();

    // Array-valued / array-reducing builtins (fill/zeros/ones, sum/product, the
    // one-array forms of min/max, ndims) take precedence over the scalar math
    // handling below (which also defines the two-argument min/max).
    if let Some(sig) = compile_array_builtin(ctx, name, &argv, attr)? {
        return Ok(sig);
    }

    let result_sig = sig_ty_quiet(&attr.ty).unwrap_or(SigTy::Real);
    let result_wty = result_sig.wty();

    // Event forms (trailing index) get held/refresh semantics; plain arities fall
    // through to the value handling below.
    if crate::CodegenWasmJit::math_event_kind(name, argv.len()).is_some() {
        let idx = crate::CodegenWasmJit::math_event_index(argv[argv.len() - 1])?;
        return compile_math_event(ctx, name, &argv[..argv.len() - 1], idx, result_wty);
    }

    // Host-imported transcendentals (all operate on and return f64).
    if let Some(bi) = builtin_index(name) {
        let (_, params, _) = BUILTINS[bi as usize];
        if argv.len() != params.len() {
            return Err("CodegenWasmJit: builtin expects args");
        }
        match math_domain(name) {
            Some(d) => emit_math_domain_guard(ctx, name, argv[0], &d)?,
            None => {
                for (a, p) in argv.iter().zip(params.iter()) {
                    let w = compile_exp(ctx, a)?;
                    coerce(ctx, w, *p);
                }
            }
        }
        ctx.emit(we::Instruction::Call(bi));
        return Ok(SigTy::Real);
    }

    match name {
        "sqrt" => {
            need_args(&argv, 1, name)?;
            // C skips the guard where the argument is provably non-negative.
            let guarded = !Expression::isPositiveOrZero(argv[0].clone())?;
            match math_domain(name).filter(|_| guarded) {
                Some(d) => emit_math_domain_guard(ctx, name, argv[0], &d)?,
                None => {
                    let w = compile_exp(ctx, argv[0])?;
                    coerce(ctx, w, WTy::F64);
                }
            }
            ctx.emit(we::Instruction::F64Sqrt);
            Ok(SigTy::Real)
        }
        "nthRoot" => emit_nth_root(ctx, &argv, name),
        // C's `(modelica_integer)round(r)`: half-*away*-from-zero, which wasm's
        // `nearest` (half-to-even) is not. Left as a Real — C's cast only narrows an
        // already integral value, and the surrounding expression wants the Real.
        "$_round" => {
            need_args(&argv, 1, name)?;
            let w = compile_exp(ctx, argv[0])?;
            coerce(ctx, w, WTy::F64);
            let v = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalTee(v));
            ctx.emit(we::Instruction::F64Trunc);
            let t = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalTee(t));
            // + copysign(1, v) * (|v - trunc(v)| >= 0.5)
            ctx.emit(we::Instruction::F64Const(1.0f64.into()));
            ctx.emit(we::Instruction::LocalGet(v));
            ctx.emit(we::Instruction::F64Copysign);
            ctx.emit(we::Instruction::LocalGet(v));
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::F64Sub);
            ctx.emit(we::Instruction::F64Abs);
            ctx.emit(we::Instruction::F64Const(0.5f64.into()));
            ctx.emit(we::Instruction::F64Ge);
            ctx.emit(we::Instruction::F64ConvertI32S);
            ctx.emit(we::Instruction::F64Mul);
            ctx.emit(we::Instruction::F64Add);
            Ok(SigTy::Real)
        }
        "floor" => {
            unary_f64(ctx, &argv, we::Instruction::F64Floor)?;
            Ok(SigTy::Real)
        }
        "ceil" => {
            unary_f64(ctx, &argv, we::Instruction::F64Ceil)?;
            Ok(SigTy::Real)
        }
        // integer(r): largest Integer <= r.
        "integer" => {
            unary_f64(ctx, &argv, we::Instruction::F64Floor)?;
            ctx.emit(we::Instruction::I32TruncSatF64S);
            Ok(SigTy::Int)
        }
        // `Integer(e)` — the ordinal of an enumeration value. Enum values are
        // already stored as their 1-based index (an i32), so this is identity.
        "Integer" => {
            need_args(&argv, 1, name)?;
            let w = compile_exp(ctx, argv[0])?;
            coerce(ctx, w, WTy::I32);
            Ok(SigTy::Int)
        }
        "abs" => {
            need_args(&argv, 1, name)?;
            if result_wty == WTy::F64 {
                let w = compile_exp(ctx, argv[0])?;
                coerce(ctx, w, WTy::F64);
                ctx.emit(we::Instruction::F64Abs);
                Ok(SigTy::Real)
            } else {
                let w = compile_exp(ctx, argv[0])?;
                coerce(ctx, w, WTy::I32);
                let t = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalSet(t));
                // select(-x, x, x<0)
                ctx.emit(we::Instruction::I32Const(0));
                ctx.emit(we::Instruction::LocalGet(t));
                ctx.emit(we::Instruction::I32Sub); // -x
                ctx.emit(we::Instruction::LocalGet(t)); // x
                ctx.emit(we::Instruction::LocalGet(t));
                ctx.emit(we::Instruction::I32Const(0));
                ctx.emit(we::Instruction::I32LtS); // x<0
                ctx.emit(we::Instruction::Select);
                Ok(result_sig)
            }
        }
        "max" | "min" => {
            need_args(&argv, 2, name)?;
            if result_wty == WTy::F64 {
                let a = compile_exp(ctx, argv[0])?;
                coerce(ctx, a, WTy::F64);
                let b = compile_exp(ctx, argv[1])?;
                coerce(ctx, b, WTy::F64);
                ctx.emit(if name == "max" { we::Instruction::F64Max } else { we::Instruction::F64Min });
                Ok(SigTy::Real)
            } else {
                let a = compile_exp(ctx, argv[0])?;
                coerce(ctx, a, WTy::I32);
                let b = compile_exp(ctx, argv[1])?;
                coerce(ctx, b, WTy::I32);
                let tb = ctx.alloc_temp(WTy::I32);
                let ta = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalSet(tb));
                ctx.emit(we::Instruction::LocalSet(ta));
                ctx.emit(we::Instruction::LocalGet(ta));
                ctx.emit(we::Instruction::LocalGet(tb));
                ctx.emit(we::Instruction::LocalGet(ta));
                ctx.emit(we::Instruction::LocalGet(tb));
                ctx.emit(if name == "max" { we::Instruction::I32GtS } else { we::Instruction::I32LtS });
                ctx.emit(we::Instruction::Select);
                Ok(result_sig)
            }
        }
        // div(a,b): integer division truncating toward zero.
        "div" if result_wty == WTy::I32 => {
            need_args(&argv, 2, name)?;
            let a = compile_exp(ctx, argv[0])?;
            coerce(ctx, a, WTy::I32);
            let b = compile_exp(ctx, argv[1])?;
            coerce(ctx, b, WTy::I32);
            ctx.emit(we::Instruction::I32DivS);
            Ok(SigTy::Int)
        }
        // div(a,b) for Reals: `trunc(a/b)` (truncate toward zero, Real result).
        // The frontend also expands Real `rem` into `a - b*div(a,b)`.
        "div" => {
            need_args(&argv, 2, name)?;
            let a = compile_exp(ctx, argv[0])?;
            coerce(ctx, a, WTy::F64);
            let b = compile_exp(ctx, argv[1])?;
            coerce(ctx, b, WTy::F64);
            ctx.emit(we::Instruction::F64Div);
            ctx.emit(we::Instruction::F64Trunc);
            Ok(SigTy::Real)
        }
        // rem(a,b): integer remainder truncating toward zero.
        "rem" if result_wty == WTy::I32 => {
            need_args(&argv, 2, name)?;
            let a = compile_exp(ctx, argv[0])?;
            coerce(ctx, a, WTy::I32);
            let b = compile_exp(ctx, argv[1])?;
            coerce(ctx, b, WTy::I32);
            ctx.emit(we::Instruction::I32RemS);
            Ok(SigTy::Int)
        }
        // rem(a,b) for Reals: `a - b*trunc(a/b)` (truncated remainder).
        "rem" => {
            need_args(&argv, 2, name)?;
            let a = compile_exp(ctx, argv[0])?;
            coerce(ctx, a, WTy::F64);
            let at = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(at));
            let b = compile_exp(ctx, argv[1])?;
            coerce(ctx, b, WTy::F64);
            let bt = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(bt));
            ctx.emit(we::Instruction::LocalGet(at)); // a
            ctx.emit(we::Instruction::LocalGet(bt)); // b * trunc(a/b)
            ctx.emit(we::Instruction::LocalGet(at));
            ctx.emit(we::Instruction::LocalGet(bt));
            ctx.emit(we::Instruction::F64Div);
            ctx.emit(we::Instruction::F64Trunc);
            ctx.emit(we::Instruction::F64Mul);
            ctx.emit(we::Instruction::F64Sub);
            Ok(SigTy::Real)
        }
        // mod(a,b): Modelica floored modulo `a - floor(a/b)*b`. Integer goes
        // through the runtime (floored, result takes the divisor's sign);
        // Real is inlined with `floor`.
        "mod" if result_wty == WTy::I32 => {
            need_args(&argv, 2, name)?;
            let a = compile_exp(ctx, argv[0])?;
            coerce(ctx, a, WTy::I32);
            let b = compile_exp(ctx, argv[1])?;
            coerce(ctx, b, WTy::I32);
            ctx.emit(we::Instruction::Call(rt_index("rt_mod_int")?));
            Ok(SigTy::Int)
        }
        "mod" => {
            need_args(&argv, 2, name)?;
            let a = compile_exp(ctx, argv[0])?;
            coerce(ctx, a, WTy::F64);
            let at = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(at));
            let b = compile_exp(ctx, argv[1])?;
            coerce(ctx, b, WTy::F64);
            let bt = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(bt));
            ctx.emit(we::Instruction::LocalGet(at)); // a
            ctx.emit(we::Instruction::LocalGet(at)); // floor(a/b) * b
            ctx.emit(we::Instruction::LocalGet(bt));
            ctx.emit(we::Instruction::F64Div);
            ctx.emit(we::Instruction::F64Floor);
            ctx.emit(we::Instruction::LocalGet(bt));
            ctx.emit(we::Instruction::F64Mul);
            ctx.emit(we::Instruction::F64Sub);
            Ok(SigTy::Real)
        }
        // sign(x): -1 / 0 / 1 (Integer), `(x > 0) - (x < 0)`.
        "sign" => {
            need_args(&argv, 1, name)?;
            let w = compile_exp(ctx, argv[0])?;
            coerce(ctx, w, WTy::F64);
            let t = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(t));
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::F64Const(0.0f64.into()));
            ctx.emit(we::Instruction::F64Gt); // (x > 0) -> i32
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::F64Const(0.0f64.into()));
            ctx.emit(we::Instruction::F64Lt); // (x < 0) -> i32
            ctx.emit(we::Instruction::I32Sub);
            Ok(SigTy::Int)
        }
        // `$_signNoNull(x)` = (x >= 0.0 ? 1.0 : -1.0); a division-guard helper the
        // backend's `ExpressionSolve` emits when solving torn equations.
        "$_signNoNull" => {
            need_args(&argv, 1, name)?;
            ctx.emit(we::Instruction::F64Const(1.0f64.into()));
            ctx.emit(we::Instruction::F64Const((-1.0f64).into()));
            let w = compile_exp(ctx, argv[0])?;
            coerce(ctx, w, WTy::F64);
            ctx.emit(we::Instruction::F64Const(0.0f64.into()));
            ctx.emit(we::Instruction::F64Ge);
            ctx.emit(we::Instruction::Select);
            Ok(SigTy::Real)
        }
        // semiLinear(x, positiveSlope, negativeSlope) = x * (x >= 0 ? ps : ns).
        "semiLinear" => {
            need_args(&argv, 3, name)?;
            let w = compile_exp(ctx, argv[0])?;
            coerce(ctx, w, WTy::F64);
            let t = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(t));
            ctx.emit(we::Instruction::LocalGet(t));
            let p = compile_exp(ctx, argv[1])?;
            coerce(ctx, p, WTy::F64);
            let n = compile_exp(ctx, argv[2])?;
            coerce(ctx, n, WTy::F64);
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::F64Const(0.0f64.into()));
            ctx.emit(we::Instruction::F64Ge);
            ctx.emit(we::Instruction::Select);
            ctx.emit(we::Instruction::F64Mul);
            Ok(SigTy::Real)
        }
        // Number → String formatting via the runtime: a scalar becomes a freshly
        // allocated (refcount 1) String handle. The typed builtin names are
        // unambiguous; `String(x)` dispatches on the argument's Modelica type.
        "intString" => {
            need_args(&argv, 1, name)?;
            format_scalar_string(ctx, argv[0], SigTy::Int)
        }
        "boolString" => {
            need_args(&argv, 1, name)?;
            format_scalar_string(ctx, argv[0], SigTy::Bool)
        }
        "realString" if argv.len() == 1 => emit_real_string(ctx, argv[0]),
        "String" => emit_string_builtin(ctx, &argv),
        // `s1 + s2` arrives as a BINARY ADD (handled in `compile_binary`); the
        // explicit builtin form is `stringAppend`.
        "stringAppend" => {
            need_args(&argv, 2, name)?;
            str_binop(ctx, argv[0], argv[1], "rt_concat")?;
            Ok(SigTy::Str)
        }
        "stringLength" => {
            need_args(&argv, 1, name)?;
            str_unop(ctx, argv[0], "rt_str_len")?;
            Ok(SigTy::Int)
        }
        "stringEqual" => {
            need_args(&argv, 2, name)?;
            str_binop(ctx, argv[0], argv[1], "rt_streq")?;
            Ok(SigTy::Bool)
        }
        // `substring(s, i, j)` — 1-based inclusive.
        "substring" => {
            need_args(&argv, 3, name)?;
            str_substring(ctx, argv[0], argv[1], argv[2])?;
            Ok(SigTy::Str)
        }
        // `smooth(p, expr)` and `noEvent(expr)` are smoothness/event annotations
        // that are the identity on the value expression at runtime (the C target
        // likewise just evaluates the expression). The returned `SigTy` is
        // derived from the emitted wasm type so it always matches the stack.
        "smooth" => {
            need_args(&argv, 2, name)?;
            let w = compile_exp(ctx, argv[1])?;
            Ok(if w == WTy::F64 { SigTy::Real } else { SigTy::Int })
        }
        "noEvent" => {
            need_args(&argv, 1, name)?;
            let w = compile_exp(ctx, argv[0])?;
            Ok(if w == WTy::F64 { SigTy::Real } else { SigTy::Int })
        }
        // C's macro, and not interchangeable with the algebraically equal
        // `s + lambda*(a - s)`: that rounds `a - s` to the ulp of the larger operand,
        // quantizing a residual whose simplified branch is much bigger than itself.
        "homotopy" => {
            need_args(&argv, 2, name)?;
            let (data, lambda_off) = { let s = ctx.sim()?; (s.data_local, s.lambda_off) };
            let a = compile_exp(ctx, argv[0])?;
            coerce(ctx, a, WTy::F64);
            let at = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(at));
            let s = compile_exp(ctx, argv[1])?;
            coerce(ctx, s, WTy::F64);
            let st = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(st));
            let lam = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalGet(data));
            ctx.emit(we::Instruction::F64Load(mem_arg(lambda_off, 3)));
            ctx.emit(we::Instruction::LocalSet(lam));
            ctx.emit(we::Instruction::LocalGet(st));
            ctx.emit(we::Instruction::F64Const(1.0.into()));
            ctx.emit(we::Instruction::LocalGet(lam));
            ctx.emit(we::Instruction::F64Sub);
            ctx.emit(we::Instruction::F64Mul);
            ctx.emit(we::Instruction::LocalGet(at));
            ctx.emit(we::Instruction::LocalGet(lam));
            ctx.emit(we::Instruction::F64Mul);
            ctx.emit(we::Instruction::F64Add);
            Ok(SigTy::Real)
        }
        // `pre(x)` reads x's pre-value slot (C's `*VarsPre`), populated by
        // savePreValues after each step. In simulation mode the argument is a
        // variable reference; read `$PRE.x`.
        "pre" => {
            need_args(&argv, 1, name)?;
            let DAE::Exp::CREF { componentRef, .. } = &**argv[0] else {
                return Err("CodegenWasmJit: `pre` expects a variable reference");
            };
            let pre = pre_cref(componentRef);
            match compile_sim_cref_read(ctx, &pre)? {
                Some(WTy::F64) => Ok(SigTy::Real),
                Some(WTy::I32) => Ok(SigTy::Int),
                None => return Err("CodegenWasmJit: `pre` of a non-model variable"),
            }
        }
        // `sample(index, start, interval)` (the backend's 3-arg internal form,
        // index first): true exactly at the sample's firing times. The driver
        // raises `active[k]` for the firing sample before the discrete update, so
        // this reads that i32 flag. `start`/`interval` are handled by `initSample`
        // and the driver, not evaluated here.
        // delay(index, e, d, delayMax): `e` at `time - d` from buffer `index`.
        "delay" => {
            need_args(&argv, 4, name)?;
            let DAE::Exp::ICONST { integer: index } = &**argv[0] else {
                return Err("CodegenWasmJit: `delay` index must be an integer literal");
            };
            let data = ctx.sim()?.data_local;
            ctx.emit(we::Instruction::I32Const(*index));
            ctx.emit(we::Instruction::LocalGet(data)); // time (TIME_OFF = 0)
            ctx.emit(we::Instruction::F64Load(mem_arg(0, 3)));
            for a in &argv[1..4] {
                let w = compile_exp(ctx, a)?;
                coerce(ctx, w, WTy::F64);
            }
            ctx.emit(we::Instruction::Call(rt_index("rt_delay_eval")?));
            Ok(SigTy::Real)
        }
        // delayZeroCrossing(index, rindex, d): zeroCrossingsPre[rindex], sign-
        // flipped when a buffered event lies in the (time - d) window.
        "delayZeroCrossing" => {
            need_args(&argv, 3, name)?;
            if !ctx.sim()?.zc_context {
                return Err("CodegenWasmJit: delayZeroCrossing outside a zero-crossing context");
            }
            let DAE::Exp::ICONST { integer: index } = &**argv[0] else {
                return Err("CodegenWasmJit: `delayZeroCrossing` index must be an integer literal");
            };
            let DAE::Exp::ICONST { integer: rindex } = &**argv[1] else {
                return Err("CodegenWasmJit: `delayZeroCrossing` relation index must be an integer literal");
            };
            let (data, zc_pre_off) = { let s = ctx.sim()?; (s.data_local, s.zc_pre_off) };
            ctx.emit(we::Instruction::I32Const(*index));
            ctx.emit(we::Instruction::LocalGet(data)); // time (TIME_OFF = 0)
            ctx.emit(we::Instruction::F64Load(mem_arg(0, 3)));
            let w = compile_exp(ctx, argv[2])?; // delay time
            coerce(ctx, w, WTy::F64);
            ctx.emit(we::Instruction::LocalGet(data)); // zeroCrossingsPre[rindex]
            ctx.emit(we::Instruction::F64Load(mem_arg(zc_pre_off + *rindex as u32 * 8, 3)));
            ctx.emit(we::Instruction::Call(rt_index("rt_delay_zc")?));
            Ok(SigTy::Real)
        }
        // spatialDistributionZeroCrossing(index, rindex, x, positiveVelocity): flips
        // sign each time a stored discontinuity passes the operator's output edge,
        // holding `zeroCrossingsPre[rindex]` while there is none.
        "spatialDistributionZeroCrossing" => {
            need_args(&argv, 4, name)?;
            if !ctx.sim()?.zc_context {
                return Err("CodegenWasmJit: spatialDistributionZeroCrossing outside a zero-crossing context");
            }
            let DAE::Exp::ICONST { integer: index } = &**argv[0] else {
                return Err("CodegenWasmJit: `spatialDistributionZeroCrossing` index must be an integer literal");
            };
            let DAE::Exp::ICONST { integer: rindex } = &**argv[1] else {
                return Err("CodegenWasmJit: `spatialDistributionZeroCrossing` relation index must be an integer literal");
            };
            let (data, zc_pre_off) = { let s = ctx.sim()?; (s.data_local, s.zc_pre_off) };
            ctx.emit(we::Instruction::I32Const(*index));
            let w = compile_exp(ctx, argv[2])?; // x
            coerce(ctx, w, WTy::F64);
            let w = compile_exp(ctx, argv[3])?; // positiveVelocity
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::LocalGet(data)); // zeroCrossingsPre[rindex]
            ctx.emit(we::Instruction::F64Load(mem_arg(zc_pre_off + *rindex as u32 * 8, 3)));
            ctx.emit(we::Instruction::Call(rt_index("rt_spatial_zc")?));
            Ok(SigTy::Real)
        }
        // `terminal()` — C's `simulationInfo->terminal`, true only during the
        // run's final discrete update.
        "terminal" => {
            need_args(&argv, 0, name)?;
            let (data, off) = { let s = ctx.sim()?; (s.data_local, s.terminal_off) };
            ctx.emit(we::Instruction::LocalGet(data));
            ctx.emit(we::Instruction::I32Load(mem_arg(off, 2)));
            Ok(SigTy::Bool)
        }
        // `initial()` — C's `simulationInfo->initial`, true for the whole
        // initialization phase.
        "initial" => {
            need_args(&argv, 0, name)?;
            let (data, off) = { let s = ctx.sim()?; (s.data_local, s.initial_off) };
            ctx.emit(we::Instruction::LocalGet(data));
            ctx.emit(we::Instruction::I32Load(mem_arg(off, 2)));
            Ok(SigTy::Bool)
        }
        "sample" => {
            need_args(&argv, 3, name)?;
            let DAE::Exp::ICONST { integer } = &**argv[0] else {
                return Err("CodegenWasmJit: `sample` index must be an integer literal");
            };
            // C's `samples[index - 1]`: the expression's index is 1-based into
            // the samples array, which the driver fills in `timeEvents` order.
            let n_samples = ctx.sim()?.n_samples;
            let k = u32::try_from(*integer - 1)
                .ok()
                .filter(|k| *k < n_samples)
                .ok_or_else(|| "CodegenWasmJit: `sample` index out of range")?;
            let data = ctx.sim()?.data_local;
            let off = ctx.sim()?.sample_active_off + k * 4;
            ctx.emit(we::Instruction::LocalGet(data));
            ctx.emit(we::Instruction::I32Load(mem_arg(off, 2)));
            Ok(SigTy::Bool)
        }
        // `interval()` and `interval(clk)` alike read the active sub-clock, as C's
        // `daeExpCall` does: the backend already put the reference in that partition.
        "interval" if argv.len() <= 1 => {
            let (data, off) = { let s = ctx.sim()?; (s.data_local, sub_clock_off(s, "interval")?) };
            ctx.emit(we::Instruction::LocalGet(data));
            ctx.emit(we::Instruction::F64Load(mem_arg(off + clock_field::SUB_PREV_INTERVAL, 3)));
            Ok(SigTy::Real)
        }
        "firstTick" if argv.len() <= 1 => {
            let (data, off) = { let s = ctx.sim()?; (s.data_local, sub_clock_off(s, "firstTick")?) };
            ctx.emit(we::Instruction::LocalGet(data));
            ctx.emit(we::Instruction::I32Load(mem_arg(off + clock_field::SUB_COUNT, 2)));
            ctx.emit(we::Instruction::I32Const(1));
            ctx.emit(we::Instruction::I32Eq);
            Ok(SigTy::Bool)
        }
        // C's `crefPrefixPrevious`: the `$CLKPRE.x` variable the partition assigns.
        "previous" => {
            need_args(&argv, 1, name)?;
            let DAE::Exp::CREF { componentRef, .. } = &**argv[0] else {
                return Err("CodegenWasmJit: `previous` expects a variable reference");
            };
            let prev = clkpre_cref(componentRef);
            match compile_sim_cref_read(ctx, &prev)? {
                Some(WTy::F64) => Ok(SigTy::Real),
                Some(WTy::I32) => Ok(SigTy::Int),
                None => return Err("CodegenWasmJit: `previous` of a non-model variable"),
            }
        }
        // C's `handleBaseClock(data, threadData, i-1, time)`. The timer list is on
        // the driver's side of the wasm boundary, so raise the clock's flag instead
        // and let the driver fire it when the model call returns.
        "$_clkfire" => {
            need_args(&argv, 1, name)?;
            let DAE::Exp::ICONST { integer } = &**argv[0] else {
                return Err("CodegenWasmJit: `$_clkfire` index must be an integer literal");
            };
            let base = (*integer - 1).max(0) as u32;
            let (data, off) = { let s = ctx.sim()?; (s.data_local, s.clock_fire_off) };
            ctx.emit(we::Instruction::LocalGet(data));
            ctx.emit(we::Instruction::I32Const(1));
            ctx.emit(we::Instruction::I32Store(mem_arg(off + base * 4, 2)));
            // Only ever reached through `noReturnCall`, which drops one result.
            ctx.emit(we::Instruction::I32Const(0));
            Ok(SigTy::Bool)
        }
        // `hold(e)` / `sample(e, clk)` after partitioning: just `e` here.
        "$getPart" => {
            need_args(&argv, 1, name)?;
            let w = compile_exp(ctx, argv[0])?;
            Ok(exp_sigty(argv[0])
                .unwrap_or(if w == WTy::F64 { SigTy::Real } else { SigTy::Int }))
        }
        // The frontend folds a literal URI, so the argument here is computed.
        "OpenModelica_uriToFilename" | "OpenModelica_fmuLoadResource" => {
            need_args(&argv, 1, name)?;
            compile_exp(ctx, argv[0])?;
            let t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(t));
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::I32Const(i32::from(name == "OpenModelica_fmuLoadResource")));
            ctx.emit(we::Instruction::Call(env_extra_index("rt_uri_to_filename")?));
            release_temp(ctx, t)?;
            Ok(SigTy::Str)
        }
        // der(cref): an explicit derivative left in an equation. Read the
        // derivative variable's slot ($DER.<cref>), as the C target does.
        "der" => {
            need_args(&argv, 1, name)?;
            let DAE::Exp::CREF { componentRef, .. } = &**argv[0] else {
                return Err("CodegenWasmJit: der() of a non-reference expression not supported");
            };
            let dcref = der_cref(componentRef);
            match compile_sim_cref_read(ctx, &dcref)? {
                Some(_) => Ok(SigTy::Real),
                None => return Err("CodegenWasmJit: der() is only supported in simulation mode"),
            }
        }
        other => match declined_external_reason(other) {
            Some(why) => {
                crate::CodegenWasmJit::record_error(format!(
                    "CodegenWasmJit: external function not lowered: {other} ({why})"
                ));
                Err("CodegenWasmJit: external function not lowered")
            }
            None => {
                crate::CodegenWasmJit::record_error(format!(
                    "CodegenWasmJit: builtin function not yet supported: {other}"
                ));
                Err("CodegenWasmJit: builtin function not yet supported")
            }
        },
    }
}
