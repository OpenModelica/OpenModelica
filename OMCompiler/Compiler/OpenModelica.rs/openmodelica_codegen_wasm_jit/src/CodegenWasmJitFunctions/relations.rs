//! Relations: indexed (event) relations, hysteresis, nominal scaling.

use super::*;

pub(super) fn compile_relation(
    ctx: &mut FnCtx,
    e1: &Arc<DAE::Exp>,
    op: &DAE::Operator,
    e2: &Arc<DAE::Exp>,
    index: i32,
    asub: &Option<(Arc<DAE::Exp>, i32, i32)>,
) -> Result<WTy> {
    use DAE::Operator as O;
    // String comparisons go through the runtime: equality via `rt_streq`,
    // ordering via `rt_strcmp` (which returns -1/0/1) compared against 0. As for
    // the arithmetic operators, an untyped relation takes its operands' type.
    let sig = match relation_operand_sigty(op) {
        Ok(s) => s,
        Err(_) => operand_sigty(e1, e2)?,
    };
    if sig == SigTy::Str {
        match op {
            O::EQUAL { .. } => str_binop(ctx, e1, e2, "rt_streq")?,
            O::NEQUAL { .. } => {
                str_binop(ctx, e1, e2, "rt_streq")?;
                ctx.emit(we::Instruction::I32Eqz);
            }
            O::LESS { .. } | O::LESSEQ { .. } | O::GREATER { .. } | O::GREATEREQ { .. } => {
                str_binop(ctx, e1, e2, "rt_strcmp")?;
                ctx.emit(we::Instruction::I32Const(0));
                ctx.emit(match op {
                    O::LESS { .. } => we::Instruction::I32LtS,
                    O::LESSEQ { .. } => we::Instruction::I32LeS,
                    O::GREATER { .. } => we::Instruction::I32GtS,
                    _ => we::Instruction::I32GeS,
                });
            }
            other => return Err("CodegenWasmJit: unsupported String relation"),
        }
        return Ok(WTy::I32);
    }
    // An indexed relation is held during continuous integration (`rel_fresh == 0`)
    // and re-evaluated at events/init; the crossing function (`zc_context`) always
    // re-evaluates. A Real inequality gets a hysteresis band (`compile_relation_hyst`)
    // at events and in the crossing function, but stays exact at init (`rel_fresh == 2`)
    // so a start value like `v <= 0` at `v == 0` resolves as written.
    // A clocked partition is C's `contextOther`: plain relations.
    let indexed = matches!(ctx.sim(), Ok(s) if index >= 0 && (index as u32) < s.n_relations
        && s.sub_clock_off.is_none());
    if !indexed {
        return compile_relation_fresh(ctx, e1, op, e2);
    }
    compile_relation_indexed(ctx, e1, op, e2, index, asub)
}

/// The held/banded/exact indexed-relation evaluation (integration, event, init modes
/// selected on `rel_fresh`). Callers guarantee the relation is indexed
/// (`0 <= index < n_relations`).
fn compile_relation_indexed(
    ctx: &mut FnCtx,
    e1: &Arc<DAE::Exp>,
    op: &DAE::Operator,
    e2: &Arc<DAE::Exp>,
    index: i32,
    asub: &Option<(Arc<DAE::Exp>, i32, i32)>,
) -> Result<WTy> {
    use DAE::Operator as O;
    let real_ineq = operand_type_of_relation(op)? == WTy::F64
        && matches!(op, O::LESS { .. } | O::LESSEQ { .. } | O::GREATER { .. } | O::GREATEREQ { .. });
    let data = ctx.sim()?.data_local;
    // Region bases: `relations[]` (live), `relationsPre[]` (held) and the held
    // snapshot the hysteresis band's direction reads. Element `k` is at
    // `base + k*4`.
    let relations_off = ctx.sim()?.relations_off;
    let pre_off = ctx.sim()?.relations_pre_off;
    let dir_off = ctx.sim()?.stored_rel_off;
    let fresh_off = ctx.sim()?.rel_fresh_off;
    // The slot address `data + eff_index*4`. A relation inside a `for`-loop shares
    // one AST node across iterations, so its effective index is
    // `index + (iterator - i)/j` (C's `daeExpRelationSim`); otherwise it is `index`.
    // The crossing function evaluates the scalarized copies outside that loop, so
    // the iterator does not exist there and it keeps the base `index`, as C does.
    let zc_context = ctx.sim()?.zc_context;
    let slot = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalGet(data));
    ctx.emit(we::Instruction::I32Const(index));
    if let Some((iter, i, j)) = asub.as_ref().filter(|_| !zc_context) {
        let w = compile_exp(ctx, iter)?;
        coerce(ctx, w, WTy::I32);
        ctx.emit(we::Instruction::I32Const(*i));
        ctx.emit(we::Instruction::I32Sub);
        ctx.emit(we::Instruction::I32Const(*j));
        ctx.emit(we::Instruction::I32DivS);
        ctx.emit(we::Instruction::I32Add); // index + (iterator - i)/j
    }
    ctx.emit(we::Instruction::I32Const(4));
    ctx.emit(we::Instruction::I32Mul);
    ctx.emit(we::Instruction::I32Add); // data + eff_index*4
    ctx.emit(we::Instruction::LocalSet(slot));
    if zc_context {
        if real_ineq {
            compile_relation_hyst(ctx, e1, op, e2, slot, dir_off)?;
        } else {
            compile_relation_fresh(ctx, e1, op, e2)?;
        }
        return Ok(WTy::I32);
    }
    // Equation context: held / init-fresh / event-fresh selected on `rel_fresh`.
    ctx.emit(we::Instruction::LocalGet(data));
    ctx.emit(we::Instruction::I32Load(mem_arg(fresh_off, 2)));
    ctx.emit(we::Instruction::If(we::BlockType::Result(we::ValType::I32)));
    let v = ctx.alloc_temp(WTy::I32);
    if real_ineq {
        // rel_fresh == 2 (init): exact; else (event): hysteretic.
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::I32Load(mem_arg(fresh_off, 2)));
        ctx.emit(we::Instruction::I32Const(2));
        ctx.emit(we::Instruction::I32Eq);
        ctx.emit(we::Instruction::If(we::BlockType::Result(we::ValType::I32)));
        compile_relation_fresh(ctx, e1, op, e2)?;
        ctx.emit(we::Instruction::Else);
        compile_relation_hyst(ctx, e1, op, e2, slot, dir_off)?;
        ctx.emit(we::Instruction::End);
    } else {
        compile_relation_fresh(ctx, e1, op, e2)?;
    }
    ctx.emit(we::Instruction::LocalSet(v));
    ctx.emit(we::Instruction::LocalGet(slot)); // store relations[eff] = v
    ctx.emit(we::Instruction::LocalGet(v));
    ctx.emit(we::Instruction::I32Store(mem_arg(relations_off, 2)));
    ctx.emit(we::Instruction::LocalGet(v));
    ctx.emit(we::Instruction::Else);
    ctx.emit(we::Instruction::LocalGet(slot)); // held: relationsPre[eff]
    ctx.emit(we::Instruction::I32Load(mem_arg(pre_off, 2)));
    ctx.emit(we::Instruction::End);
    Ok(WTy::I32)
}

/// Emit a Real inequality with a zero-crossing hysteresis band, leaving an i32
/// boolean on the stack. The comparison boundary is offset by
/// ±`eps = tolZC * (max(|a|,|b|) + max(nominal(a), nominal(b)))` in the direction
/// that resists a flip, using the held relation snapshot (`slot + dir_off`) as the
/// current side: once true the relation stays true until the operand clears the
/// band, and vice versa. `slot` addresses the relation's element (`data + eff*4`);
/// `tolZC` is read from `SimData` (`zctol_off`).
fn compile_relation_hyst(
    ctx: &mut FnCtx,
    e1: &Arc<DAE::Exp>,
    op: &DAE::Operator,
    e2: &Arc<DAE::Exp>,
    slot: u32,
    dir_off: u32,
) -> Result<()> {
    use we::Instruction as I;
    let data = ctx.sim()?.data_local;
    let zctol_off = ctx.sim()?.zctol_off;

    let nom = ctx.alloc_temp(WTy::F64);
    emit_relation_nominal(ctx, e1, e2)?;
    ctx.emit(I::LocalSet(nom));

    let a = ctx.alloc_temp(WTy::F64);
    let wa = compile_exp(ctx, e1)?;
    coerce(ctx, wa, WTy::F64);
    ctx.emit(I::LocalSet(a));
    let b = ctx.alloc_temp(WTy::F64);
    let wb = compile_exp(ctx, e2)?;
    coerce(ctx, wb, WTy::F64);
    ctx.emit(I::LocalSet(b));

    // eps = tolZC * (max(|a|,|b|) + nom)
    let eps = ctx.alloc_temp(WTy::F64);
    ctx.emit(I::LocalGet(a));
    ctx.emit(I::F64Abs);
    ctx.emit(I::LocalGet(b));
    ctx.emit(I::F64Abs);
    ctx.emit(I::F64Max);
    ctx.emit(I::LocalGet(nom));
    ctx.emit(I::F64Add);
    ctx.emit(I::LocalGet(data));
    ctx.emit(I::F64Load(mem_arg(zctol_off, 3)));
    ctx.emit(I::F64Mul);
    ctx.emit(I::LocalSet(eps));

    // diff = a - b
    let diff = ctx.alloc_temp(WTy::F64);
    ctx.emit(I::LocalGet(a));
    ctx.emit(I::LocalGet(b));
    ctx.emit(I::F64Sub);
    ctx.emit(I::LocalSet(diff));

    // The held snapshot (`slot + dir_off`) chooses which band edge applies.
    ctx.emit(I::LocalGet(slot));
    ctx.emit(I::I32Load(mem_arg(dir_off, 2)));
    ctx.emit(I::If(we::BlockType::Result(we::ValType::I32)));
    emit_hyst_cmp(ctx, op, diff, eps, true)?;
    ctx.emit(I::Else);
    emit_hyst_cmp(ctx, op, diff, eps, false)?;
    ctx.emit(I::End);
    Ok(())
}

/// Emit `diff <op> (±eps)`, leaving an i32 boolean. `dir` is the current relation
/// value; it selects which side of the band the boundary sits on so the relation
/// resists flipping.
fn emit_hyst_cmp(ctx: &mut FnCtx, op: &DAE::Operator, diff: u32, eps: u32, dir: bool) -> Result<()> {
    use DAE::Operator as O;
    use we::Instruction as I;
    // (comparison, whether the +eps edge applies for this direction).
    let (cmp, plus) = match op {
        O::LESSEQ { .. } => (I::F64Lt, dir),
        O::LESS { .. } => (I::F64Le, dir),
        O::GREATER { .. } => (I::F64Ge, !dir),
        O::GREATEREQ { .. } => (I::F64Gt, !dir),
        other => return Err("CodegenWasmJit: non-inequality in hysteresis path"),
    };
    ctx.emit(I::LocalGet(diff));
    ctx.emit(I::LocalGet(eps));
    if !plus {
        ctx.emit(I::F64Neg);
    }
    ctx.emit(cmp);
    Ok(())
}

/// Leave `max(|nominal(e1)|, |nominal(e2)|)` — the scale term of the hysteresis
/// band — on the stack as an f64, from the same `getExpNominal` derivation C's
/// `daeExpNominalTmp` uses.
fn emit_relation_nominal(ctx: &mut FnCtx, e1: &Arc<DAE::Exp>, e2: &Arc<DAE::Exp>) -> Result<()> {
    let n1 = nominal_exp(e1);
    let n2 = nominal_exp(e2);
    match (nominal_const(&n1), nominal_const(&n2)) {
        (Some(c1), Some(c2)) => ctx.emit(we::Instruction::F64Const(c1.max(c2).into())),
        _ => {
            let w1 = compile_exp(ctx, &n1)?;
            coerce(ctx, w1, WTy::F64);
            ctx.emit(we::Instruction::F64Abs);
            let w2 = compile_exp(ctx, &n2)?;
            coerce(ctx, w2, WTy::F64);
            ctx.emit(we::Instruction::F64Abs);
            ctx.emit(we::Instruction::F64Max);
        }
    }
    Ok(())
}

fn nominal_exp(e: &Arc<DAE::Exp>) -> Arc<DAE::Exp> {
    openmodelica_backend::SimCodeUtil::getExpNominal(Arc::clone(e))
        .unwrap_or_else(|_| Arc::new(DAE::Exp::RCONST { real: 1.0.into() }))
}

fn nominal_const(e: &DAE::Exp) -> Option<f64> {
    match e {
        DAE::Exp::RCONST { real } => Some(real.into_inner().abs()),
        DAE::Exp::ICONST { integer } => Some((*integer as f64).abs()),
        _ => None,
    }
}

/// Emit a plain (unheld) relational comparison, leaving an i32 boolean on the
/// stack. The hysteresis wrapper in [`compile_relation`] calls this for the fresh
/// branch; non-indexed relations use it directly.
pub(super) fn compile_relation_fresh(ctx: &mut FnCtx, e1: &DAE::Exp, op: &DAE::Operator, e2: &DAE::Exp) -> Result<WTy> {
    use DAE::Operator as O;
    let operand_wty = operand_type_of_relation(op)?;
    if matches!(relation_operand_sigty(op), Ok(SigTy::Bool)) {
        // C compares Booleans through `!`, so a value outside {0,1} still compares
        // by truth value.
        compile_bool_operand(ctx, e1)?;
        compile_bool_operand(ctx, e2)?;
    } else {
        let a = compile_exp(ctx, e1)?;
        coerce(ctx, a, operand_wty);
        let b = compile_exp(ctx, e2)?;
        coerce(ctx, b, operand_wty);
    }
    let instr = match (op, operand_wty) {
        (O::LESS { .. }, WTy::F64) => we::Instruction::F64Lt,
        (O::LESS { .. }, WTy::I32) => we::Instruction::I32LtS,
        (O::LESSEQ { .. }, WTy::F64) => we::Instruction::F64Le,
        (O::LESSEQ { .. }, WTy::I32) => we::Instruction::I32LeS,
        (O::GREATER { .. }, WTy::F64) => we::Instruction::F64Gt,
        (O::GREATER { .. }, WTy::I32) => we::Instruction::I32GtS,
        (O::GREATEREQ { .. }, WTy::F64) => we::Instruction::F64Ge,
        (O::GREATEREQ { .. }, WTy::I32) => we::Instruction::I32GeS,
        (O::EQUAL { .. }, WTy::F64) => we::Instruction::F64Eq,
        (O::EQUAL { .. }, WTy::I32) => we::Instruction::I32Eq,
        (O::NEQUAL { .. }, WTy::F64) => we::Instruction::F64Ne,
        (O::NEQUAL { .. }, WTy::I32) => we::Instruction::I32Ne,
        (other, _) => return Err("CodegenWasmJit: unsupported relational operator"),
    };
    ctx.emit(instr);
    Ok(WTy::I32)
}

fn operand_type_of_relation(op: &DAE::Operator) -> Result<WTy> {
    Ok(relation_operand_sigty(op)?.wty())
}

/// Compile a Boolean operand of `and`/`or`/a Boolean relation as a 0/1 i32. C's
/// `!e`/`e && f` take any nonzero as true and an `external "C"` output can be such
/// a value, so the truth value is materialized unless the form already gives it.
pub(super) fn compile_bool_operand(ctx: &mut FnCtx, e: &DAE::Exp) -> Result<()> {
    use DAE::Exp as E;
    let w = compile_exp(ctx, e)?;
    coerce(ctx, w, WTy::I32);
    if !matches!(e, E::BCONST { .. } | E::RELATION { .. } | E::LBINARY { .. } | E::LUNARY { .. }) {
        ctx.emit(we::Instruction::I32Const(0));
        ctx.emit(we::Instruction::I32Ne);
    }
    Ok(())
}

/// The `SigTy` of a relational operator's operands (distinguishes String, whose
/// comparisons go through the runtime, from numeric ones).
fn relation_operand_sigty(op: &DAE::Operator) -> Result<SigTy> {
    use DAE::Operator as O;
    let ty = match op {
        O::LESS { ty } | O::LESSEQ { ty } | O::GREATER { ty } | O::GREATEREQ { ty } | O::EQUAL { ty } | O::NEQUAL { ty } => ty,
        _ => return Err("CodegenWasmJit: not a relational operator"),
    };
    sig_ty_quiet(ty)
}

/// Compile a `CALL`, leaving its result value(s) on the stack; returns their
/// types. Resolves to another generated function, an inline math builtin, or a
/// host-imported builtin.
pub(super) fn compile_call(
    ctx: &mut FnCtx,
    path: &Absyn::Path,
    args: &List<Arc<DAE::Exp>>,
    attr: &DAE::CallAttributes,
) -> Result<Vec<SigTy>> {
    // A call through a function-reference variable: `call_indirect` on the
    // closure it holds. C likewise dispatches on the variable, not the path.
    if attr.isFunctionPointerCall {
        let Absyn::Path::IDENT { name } = path else {
            return Err("CodegenWasmJit: function-pointer calls are only supported through a local variable");
        };
        return closures::compile_fnptr_call(ctx, name, args);
    }
    let mangled = mangle(path)?;
    // A call to another generated function. Heap arguments are passed as owned
    // (+1) references — a generated function *consumes* its heap parameters
    // (they are released at its scope exit), so the caller does not release them
    // after the call.
    if let Some(info) = ctx.by_name.get(&mangled) {
        let params = info.sig.params.clone();
        let results = info.sig.results.clone();
        let index = info.index;
        let argv: Vec<&Arc<DAE::Exp>> = (&**args).into_iter().collect();
        if argv.len() != params.len() {
            return Err("CodegenWasmJit: call argument count mismatch");
        }
        for (a, p) in argv.iter().zip(params.iter()) {
            let w = compile_exp(ctx, a)?;
            coerce(ctx, w, p.wty());
        }
        // C's `SIM_PROF_TICK_FN` / `SIM_PROF_ACC_FN` around a profiled call.
        let clock = prof_fn_clock(ctx, &mangled);
        emit_prof(ctx, clock, "rt_prof_tick")?;
        ctx.emit(we::Instruction::Call(index));
        emit_prof(ctx, clock, "rt_prof_acc")?;
        return Ok(results);
    }
    // A call whose result is a record and which is not a generated function is a
    // record constructor `R(v1, …)` (the constructor function itself is not
    // emitted — construction is lowered inline).
    if let Ok(rty @ SigTy::Record { .. }) = sig_ty_quiet(&attr.ty) {
        let clock = prof_fn_clock(ctx, &mangled);
        emit_prof(ctx, clock, "rt_prof_tick")?;
        compile_record_call(ctx, &attr.ty, args)?;
        emit_prof(ctx, clock, "rt_prof_acc")?;
        return Ok(vec![rty]);
    }
    // Otherwise it must be a (builtin) math/string function.
    let name = AbsynUtil::pathLastIdent(Arc::new(path.clone())).to_string();
    // `print(s)`: write the String to the model's stdout via the host `rt_print`.
    // A void procedure, so it yields no result; the owned handle is released after.
    if name == "print" {
        let argv: Vec<&Arc<DAE::Exp>> = (&**args).into_iter().collect();
        if argv.len() != 1 {
            return Err("CodegenWasmJit: print expects one argument");
        }
        let w = compile_exp(ctx, argv[0])?;
        if w != WTy::I32 {
            return Err("CodegenWasmJit: print expects a String");
        }
        let t = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalSet(t));
        ctx.emit(we::Instruction::LocalGet(t));
        ctx.emit(we::Instruction::Call(env_extra_index("rt_print")?));
        release_temp(ctx, t)?;
        return Ok(Vec::new());
    }
    // The only two-output builtin: the transported profile lives in the runtime, so
    // the tuple is one call for `out0` plus a read-back of that call's `out1`.
    if name == "spatialDistribution" {
        return compile_spatial_distribution(ctx, args).map(|_| vec![SigTy::Real, SigTy::Real]);
    }
    compile_math_builtin(ctx, &name, args, attr).map(|s| vec![s])
}
