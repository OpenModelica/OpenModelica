//! Ranges, reductions, thread iterators and array comprehensions.

use super::*;

/// Bind a single Integer-range reduction/comprehension iterator: evaluate
/// `start`/`step`/`stop` into fresh locals, register `id` as the iterator local
/// (initialized to `start`), and return `(it, step_l, stop_l)`. A positive step
/// is assumed (matching `compile_for`).
fn emit_range_iter(
    ctx: &mut FnCtx,
    id: &ArcStr,
    start: &DAE::Exp,
    step: &Option<Arc<DAE::Exp>>,
    stop: &DAE::Exp,
) -> Result<(u32, u32, u32)> {
    let it = ctx.alloc_temp(WTy::I32);
    ctx.locals.insert(id.to_string(), (it, SigTy::Int));
    let step_l = ctx.alloc_temp(WTy::I32);
    let stop_l = ctx.alloc_temp(WTy::I32);
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
    Ok((it, step_l, stop_l))
}

fn const_step(step: &Option<Arc<DAE::Exp>>) -> Option<i32> {
    match step {
        None => Some(1),
        Some(e) => match &**e {
            DAE::Exp::ICONST { integer } => Some(*integer),
            _ => None,
        },
    }
}

/// Leave `it` has passed `stop` on the stack — which way, per C's
/// `in_range_integer`, is the step's sign.
pub(super) fn emit_range_done(ctx: &mut FnCtx, step: &Option<Arc<DAE::Exp>>, it: u32, step_l: u32, stop_l: u32) {
    ctx.emit(we::Instruction::LocalGet(it));
    ctx.emit(we::Instruction::LocalGet(stop_l));
    match const_step(step) {
        Some(k) if k < 0 => ctx.emit(we::Instruction::I32LtS),
        Some(_) => ctx.emit(we::Instruction::I32GtS),
        None => {
            ctx.emit(we::Instruction::I32GtS);
            ctx.emit(we::Instruction::LocalGet(it));
            ctx.emit(we::Instruction::LocalGet(stop_l));
            ctx.emit(we::Instruction::I32LtS);
            ctx.emit(we::Instruction::LocalGet(step_l));
            ctx.emit(we::Instruction::I32Const(0));
            ctx.emit(we::Instruction::I32GtS);
            ctx.emit(we::Instruction::Select);
        }
    }
}

const ZERO_STEP: &str = "assertion range step != 0 failed";

/// A zero step never reaches `stop`; C's generated code asserts on it.
pub(super) fn emit_step_check(ctx: &mut FnCtx, step: &Option<Arc<DAE::Exp>>, step_l: u32) -> Result<()> {
    match const_step(step) {
        Some(0) => emit_runtime_error(ctx, ZERO_STEP),
        Some(_) => Ok(()),
        None => {
            ctx.emit(we::Instruction::LocalGet(step_l));
            ctx.emit(we::Instruction::I32Eqz);
            ctx.emit(we::Instruction::If(we::BlockType::Empty));
            emit_runtime_error(ctx, ZERO_STEP)?;
            ctx.emit(we::Instruction::End);
            Ok(())
        }
    }
}

/// Evaluate an Integer range into a fresh local holding its element count,
/// `max(0, (stop - start)/step + 1)`. Used to size an array comprehension.
fn emit_range_count(
    ctx: &mut FnCtx,
    start: &DAE::Exp,
    step: &Option<Arc<DAE::Exp>>,
    stop: &DAE::Exp,
) -> Result<u32> {
    let cnt = ctx.alloc_temp(WTy::I32);
    // A zero step would divide by zero below, before any loop asserts on it.
    let step_l = match (const_step(step), step) {
        (Some(0), _) => {
            emit_runtime_error(ctx, ZERO_STEP)?;
            None
        }
        (None, Some(e)) => {
            let l = ctx.alloc_temp(WTy::I32);
            let w = compile_exp(ctx, e)?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::LocalSet(l));
            emit_step_check(ctx, step, l)?;
            Some(l)
        }
        _ => None,
    };
    let pw = compile_exp(ctx, stop)?;
    coerce(ctx, pw, WTy::I32);
    let sw = compile_exp(ctx, start)?;
    coerce(ctx, sw, WTy::I32);
    ctx.emit(we::Instruction::I32Sub);
    match (step_l, step) {
        (Some(l), _) => ctx.emit(we::Instruction::LocalGet(l)),
        (None, Some(e)) => {
            let w = compile_exp(ctx, e)?;
            coerce(ctx, w, WTy::I32);
        }
        (None, None) => ctx.emit(we::Instruction::I32Const(1)),
    }
    ctx.emit(we::Instruction::I32DivS);
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(cnt));
    // clamp a negative count (empty range) to 0.
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalGet(cnt));
    ctx.emit(we::Instruction::LocalGet(cnt));
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::I32LtS);
    ctx.emit(we::Instruction::Select);
    ctx.emit(we::Instruction::LocalSet(cnt));
    Ok(cnt)
}

/// Run `body` once per iteration of a reduction's iterators: over their
/// cartesian product (`COMBINE`, first iterator outermost) or with every
/// iterator advancing together (`THREAD`).
fn emit_red_iteration(
    ctx: &mut FnCtx,
    thread: bool,
    iters: &[&Arc<DAE::ReductionIterator>],
    body: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    if thread && iters.len() > 1 {
        emit_red_thread(ctx, iters, body)
    } else {
        emit_red_nest(ctx, iters, body)
    }
}

/// `f(u, v)` vectorized over two unknown dimensions becomes
/// `array(f(x, y) thread for x in u, y in v)`.
fn red_is_thread(info: &DAE::ReductionInfo) -> bool {
    matches!(info.iterType, Absyn::ReductionIterType::THREAD)
}

const THREAD_LEN: &str = "thread reduction over iterators of different lengths";

/// One pass advances every iterator once. C's `endLoop` odometer throws when
/// only some can advance, so unequal lengths are a runtime error — checked up
/// front here, which leaves one counter to drive them all.
fn emit_red_thread(
    ctx: &mut FnCtx,
    iters: &[&Arc<DAE::ReductionIterator>],
    body: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    use we::Instruction as I;
    let saved: Vec<(String, Option<(u32, SigTy)>)> =
        iters.iter().map(|i| (i.id.to_string(), ctx.locals.get(i.id.as_str()).cloned())).collect();
    let mut binds = Vec::with_capacity(iters.len());
    for iter in iters {
        binds.push(bind_thread_iter(ctx, iter)?);
    }
    let n = binds[0].count();
    for b in &binds[1..] {
        ctx.emit(I::LocalGet(n));
        ctx.emit(I::LocalGet(b.count()));
        ctx.emit(I::I32Ne);
        ctx.emit(I::If(we::BlockType::Empty));
        emit_runtime_error(ctx, THREAD_LEN)?;
        ctx.emit(I::End);
    }
    let k = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::I32Const(0));
    ctx.emit(I::LocalSet(k));
    ctx.emit(I::Block(we::BlockType::Empty));
    ctx.emit(I::Loop(we::BlockType::Empty));
    ctx.emit(I::LocalGet(k));
    ctx.emit(I::LocalGet(n));
    ctx.emit(I::I32GeS);
    ctx.emit(I::BrIf(1));
    for b in &binds {
        if let ThreadIter::Array { arr, it, elem, .. } = b {
            ctx.emit(I::LocalGet(*arr));
            ctx.emit(I::LocalGet(k));
            ctx.emit(I::I32Const(1));
            ctx.emit(I::I32Add);
            emit_elem_ptr(ctx, elem)?;
            elem_load(ctx, elem);
            ctx.emit(I::LocalSet(*it));
        }
    }
    emit_red_thread_guarded(ctx, iters, body)?;
    for b in &binds {
        if let ThreadIter::Range { it, step_l, .. } = b {
            ctx.emit(I::LocalGet(*it));
            ctx.emit(I::LocalGet(*step_l));
            ctx.emit(I::I32Add);
            ctx.emit(I::LocalSet(*it));
        }
    }
    ctx.emit(I::LocalGet(k));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(k));
    ctx.emit(I::Br(0));
    ctx.emit(I::End); // loop
    ctx.emit(I::End); // block
    for b in &binds {
        if let ThreadIter::Array { arr, .. } = b {
            release_temp_array(ctx, *arr)?;
        }
    }
    for (name, prev) in saved {
        restore_local(ctx, &name, prev);
    }
    Ok(())
}

/// Loop state for one iterator of a [`emit_red_thread`] pass.
enum ThreadIter {
    Range { it: u32, step_l: u32, count: u32 },
    Array { arr: u32, it: u32, elem: SigTy, count: u32 },
}

impl ThreadIter {
    fn count(&self) -> u32 {
        match self {
            ThreadIter::Range { count, .. } | ThreadIter::Array { count, .. } => *count,
        }
    }
}

/// Bind one `THREAD` iterator ahead of the loop: its iterator local and length.
fn bind_thread_iter(ctx: &mut FnCtx, iter: &Arc<DAE::ReductionIterator>) -> Result<ThreadIter> {
    use we::Instruction as I;
    if let DAE::Exp::RANGE { start, step, stop, .. } = &*iter.exp {
        let (it, step_l, stop_l) = emit_range_iter(ctx, &iter.id, start, step, stop)?;
        // `it` still holds `start`.
        let count = emit_range_count_locals(ctx, it, step_l, stop_l);
        return Ok(ThreadIter::Range { it, step_l, count });
    }
    let elem = red_iter_elem_sigty(iter)?;
    if compile_exp(ctx, &iter.exp)? != WTy::I32 {
        return Err("CodegenWasmJit: reduction over a non-array, non-range iterator not supported");
    }
    let arr = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::LocalSet(arr));
    let count = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::LocalGet(arr));
    ctx.emit(I::Call(rt_index("rt_array_total")?));
    ctx.emit(I::LocalSet(count));
    let it = ctx.alloc_temp(elem.wty());
    ctx.locals.insert(iter.id.to_string(), (it, elem.clone()));
    if elem.is_heap() {
        ctx.borrowed_locals.push(it);
    }
    Ok(ThreadIter::Array { arr, it, elem, count })
}

/// The `THREAD` body, run under every iterator's `guardExp`.
fn emit_red_thread_guarded(
    ctx: &mut FnCtx,
    iters: &[&Arc<DAE::ReductionIterator>],
    body: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    let Some((iter, rest)) = iters.split_first() else {
        return body(ctx);
    };
    match &iter.guardExp {
        Some(guard) => {
            let w = compile_exp(ctx, guard)?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::If(we::BlockType::Empty));
            emit_red_thread_guarded(ctx, rest, body)?;
            ctx.emit(we::Instruction::End);
            Ok(())
        }
        None => emit_red_thread_guarded(ctx, rest, body),
    }
}

/// Emit nested `for` loops over the given iterators (the first is the
/// outermost), running `body` at the innermost point. An iterator is either an
/// Integer range or an array expression (`for x in v`, C's non-`RANGE` arm of
/// `daeExpReduction`). Relative branch depths make the nesting compose.
fn emit_red_nest(
    ctx: &mut FnCtx,
    iters: &[&Arc<DAE::ReductionIterator>],
    body: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    let Some((iter, rest)) = iters.split_first() else {
        return body(ctx);
    };
    let DAE::Exp::RANGE { start, step, stop, .. } = &*iter.exp else {
        return emit_red_nest_array(ctx, iter, rest, body);
    };
    let prev = ctx.locals.get(iter.id.as_str()).cloned();
    let (it, step_l, stop_l) = emit_range_iter(ctx, &iter.id, start, step, stop)?;
    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
    emit_range_done(ctx, step, it, step_l, stop_l);
    ctx.emit(we::Instruction::BrIf(1));
    emit_red_guarded(ctx, iter, rest, body)?;
    ctx.emit(we::Instruction::LocalGet(it));
    ctx.emit(we::Instruction::LocalGet(step_l));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(it));
    ctx.emit(we::Instruction::Br(0));
    ctx.emit(we::Instruction::End); // loop
    ctx.emit(we::Instruction::End); // block
    restore_local(ctx, &iter.id, prev);
    Ok(())
}

/// One level of [`emit_red_nest`] for an iterator over an array expression:
/// evaluate it once, then loop `k = 1..total` binding the iterator to `arr[k]`.
/// As in [`compile_for_array`] the element is *borrowed*.
fn emit_red_nest_array(
    ctx: &mut FnCtx,
    iter: &Arc<DAE::ReductionIterator>,
    rest: &[&Arc<DAE::ReductionIterator>],
    body: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    let elem = red_iter_elem_sigty(iter)?;
    if compile_exp(ctx, &iter.exp)? != WTy::I32 {
        return Err("CodegenWasmJit: reduction over a non-array, non-range iterator not supported");
    }
    let arr = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(arr));
    let n = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalGet(arr));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_total")?));
    ctx.emit(we::Instruction::LocalSet(n));
    let k = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::LocalSet(k));
    let it = ctx.alloc_temp(elem.wty());
    let prev = ctx.locals.insert(iter.id.to_string(), (it, elem.clone()));
    if elem.is_heap() {
        ctx.borrowed_locals.push(it);
    }

    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
    ctx.emit(we::Instruction::LocalGet(k));
    ctx.emit(we::Instruction::LocalGet(n));
    ctx.emit(we::Instruction::I32GtS);
    ctx.emit(we::Instruction::BrIf(1));
    ctx.emit(we::Instruction::LocalGet(arr));
    ctx.emit(we::Instruction::LocalGet(k));
    emit_elem_ptr(ctx, &elem)?;
    elem_load(ctx, &elem);
    ctx.emit(we::Instruction::LocalSet(it));
    emit_red_guarded(ctx, iter, rest, body)?;
    ctx.emit(we::Instruction::LocalGet(k));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(k));
    ctx.emit(we::Instruction::Br(0));
    ctx.emit(we::Instruction::End); // loop
    ctx.emit(we::Instruction::End); // block
    release_temp_array(ctx, arr)?;
    restore_local(ctx, &iter.id, prev);
    Ok(())
}

/// The inner levels of [`emit_red_nest`], run under this iterator's `guardExp`.
fn emit_red_guarded(
    ctx: &mut FnCtx,
    iter: &Arc<DAE::ReductionIterator>,
    rest: &[&Arc<DAE::ReductionIterator>],
    body: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    match &iter.guardExp {
        Some(guard) => {
            let w = compile_exp(ctx, guard)?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::If(we::BlockType::Empty));
            emit_red_nest(ctx, rest, body)?;
            ctx.emit(we::Instruction::End);
            Ok(())
        }
        None => emit_red_nest(ctx, rest, body),
    }
}

/// The element type an array-expression iterator binds, from the iterable we
/// load out of, falling back to the iterator's declared type. A matrix would
/// bind a row, which C's flat `_get1` does not do either.
fn red_iter_elem_sigty(iter: &DAE::ReductionIterator) -> Result<SigTy> {
    match exp_sigty(&iter.exp) {
        Ok(SigTy::Array { elem, rank: 1 }) => Ok((*elem).clone()),
        Ok(SigTy::Array { .. }) => {
            Err("CodegenWasmJit: reduction over a multi-dimensional array iterator not supported")
        }
        _ => sig_ty(&iter.ty),
    }
}

/// `max(0, (stop - start)/step + 1)`, in a fresh local, from locals holding a
/// range's start, step and stop.
fn emit_range_count_locals(ctx: &mut FnCtx, start: u32, step_l: u32, stop_l: u32) -> u32 {
    use we::Instruction as I;
    let cnt = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::LocalGet(stop_l));
    ctx.emit(I::LocalGet(start));
    ctx.emit(I::I32Sub);
    ctx.emit(I::LocalGet(step_l));
    ctx.emit(I::I32DivS);
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(cnt));
    ctx.emit(I::I32Const(0));
    ctx.emit(I::LocalGet(cnt));
    ctx.emit(I::LocalGet(cnt));
    ctx.emit(I::I32Const(0));
    ctx.emit(I::I32LtS);
    ctx.emit(I::Select);
    ctx.emit(I::LocalSet(cnt));
    cnt
}

/// The element count of one comprehension iterator, in a fresh local: an Integer
/// range's [`emit_range_count`], or the iterable array's element total.
fn emit_red_iter_count(ctx: &mut FnCtx, iter: &DAE::ReductionIterator) -> Result<u32> {
    if let DAE::Exp::RANGE { start, step, stop, .. } = &*iter.exp {
        return emit_range_count(ctx, start, step, stop);
    }
    if compile_exp(ctx, &iter.exp)? != WTy::I32 {
        return Err("CodegenWasmJit: array comprehension over a non-array, non-range iterator not supported");
    }
    let arr = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(arr));
    let cnt = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalGet(arr));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_total")?));
    ctx.emit(we::Instruction::LocalSet(cnt));
    release_temp_array(ctx, arr)?;
    Ok(cnt)
}

/// Lower an iterator reduction over Integer ranges or arrays. The folding forms
/// `sum/product/min/max(expr for i in A, j in B, ...)` (`foldExp` present) build
/// `acc = default; for i,j,... { acc = foldExp(acc, expr) }`, where `foldExp`
/// reads the accumulator (`resultName`) and per-iteration value (`foldName`) as
/// locals — so the same mechanism covers all four. The `array(...)`
/// comprehension (`foldExp` absent — `{expr for i in A, j in B}`) builds a fresh
/// array: its dimensions are the iterator counts in reverse order (the last
/// iterator is the outermost), filled row-major. An array-valued body flattens
/// into extra trailing dimensions ([`compile_array_comprehension_flat`]) and a
/// heap accumulator folds from the first value ([`compile_fold_heap`]).
/// Per-iterator `guardExp`s are honored in the folding forms; a guarded array
/// comprehension — a MetaModelica list form — bails loudly.
pub(super) fn compile_reduction(
    ctx: &mut FnCtx,
    info: &DAE::ReductionInfo,
    expr: &DAE::Exp,
    iterators: &DAE::ReductionIterators,
) -> Result<WTy> {
    let iters: Vec<&Arc<DAE::ReductionIterator>> = (&**iterators).into_iter().collect();
    if iters.is_empty() {
        return Err("CodegenWasmJit: reduction with no iterators");
    }
    let thread = red_is_thread(info);

    if let Some(fold) = &info.foldExp {
        // Folding reduction. `info.exprType` is the accumulator type.
        let elem_sty = sig_ty(&info.exprType)?;
        if elem_sty.is_heap() {
            return compile_fold_heap(ctx, info, fold, expr, &iters, elem_sty);
        }
        let elem_wty = elem_sty.wty();
        let Some(default) = &info.defaultValue else {
            return Err("CodegenWasmJit: reduction without a default value not supported");
        };
        let acc = ctx.alloc_temp(elem_wty);
        let foldval = ctx.alloc_temp(elem_wty);
        ctx.locals.insert(info.resultName.to_string(), (acc, elem_sty.clone()));
        ctx.locals.insert(info.foldName.to_string(), (foldval, elem_sty.clone()));
        emit_value_const(ctx, default, elem_wty)?;
        ctx.emit(we::Instruction::LocalSet(acc));
        emit_red_iteration(ctx, thread, &iters, &mut |ctx| {
            let w = compile_exp(ctx, expr)?;
            coerce(ctx, w, elem_wty);
            ctx.emit(we::Instruction::LocalSet(foldval));
            let fw = compile_exp(ctx, fold)?;
            coerce(ctx, fw, elem_wty);
            ctx.emit(we::Instruction::LocalSet(acc));
            Ok(())
        })?;
        ctx.emit(we::Instruction::LocalGet(acc));
        return Ok(elem_wty);
    }

    // `array(...)` comprehension. The element type is the per-iteration
    // expression's type (`info.exprType` is the whole array type here).
    if iters.iter().any(|it| it.guardExp.is_some()) {
        return Err("CodegenWasmJit: guarded array comprehension not supported");
    }
    let elem_sty = exp_sigty(expr)?;
    if let SigTy::Array { elem: base, rank: erank } = &elem_sty {
        return compile_array_comprehension_flat(ctx, expr, thread, &iters, base, *erank);
    }
    let elem_wty = elem_sty.wty();

    // The result's dimensions: one per iterator (forward order), or one shared
    // by iterators that advance together.
    let mut counts = Vec::with_capacity(iters.len());
    for it in &iters {
        counts.push(emit_red_iter_count(ctx, it)?);
    }
    if thread {
        counts.truncate(1);
    }
    let n = counts.len() as u32;
    // total = product of the counts.
    let total = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::LocalSet(total));
    for c in &counts {
        ctx.emit(we::Instruction::LocalGet(total));
        ctx.emit(we::Instruction::LocalGet(*c));
        ctx.emit(we::Instruction::I32Mul);
        ctx.emit(we::Instruction::LocalSet(total));
    }
    // Allocate the result; its dimensions are the counts in reverse iterator
    // order (the last iterator is the outermost / slowest-varying dimension).
    let res = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(elem_sty.elem_kind() as i32));
    ctx.emit(we::Instruction::I32Const(n as i32));
    ctx.emit(we::Instruction::LocalGet(total));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")?));
    ctx.emit(we::Instruction::LocalSet(res));
    for d in 0..n {
        let c = counts[(n - 1 - d) as usize];
        ctx.emit(we::Instruction::LocalGet(res));
        ctx.emit(we::Instruction::I32Const(d as i32));
        ctx.emit(we::Instruction::LocalGet(c));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")?));
    }
    // Fill row-major: nest with the last iterator outermost so the running index
    // advances with the first iterator fastest.
    let idx = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalSet(idx));
    let rev: Vec<&Arc<DAE::ReductionIterator>> = iters.iter().rev().cloned().collect();
    let store_sty = elem_sty.clone();
    emit_red_iteration(ctx, thread, &rev, &mut |ctx| {
        ctx.emit(we::Instruction::LocalGet(res));
        ctx.emit(we::Instruction::LocalGet(idx));
        ctx.emit(we::Instruction::I32Const(1));
        ctx.emit(we::Instruction::I32Add);
        emit_elem_ptr(ctx, &store_sty)?;
        let w = compile_exp(ctx, expr)?;
        coerce(ctx, w, elem_wty);
        elem_store(ctx, &store_sty);
        ctx.emit(we::Instruction::LocalGet(idx));
        ctx.emit(we::Instruction::I32Const(1));
        ctx.emit(we::Instruction::I32Add);
        ctx.emit(we::Instruction::LocalSet(idx));
        Ok(())
    })?;
    ctx.emit(we::Instruction::LocalGet(res));
    Ok(WTy::I32)
}

/// A folding reduction whose accumulator is a heap value (`sum(v .^ i for i in
/// 3:N)` over vectors). C's `daeExpReduction` has no scalar default for these, so
/// it starts from the first value and throws on an empty range.
fn compile_fold_heap(
    ctx: &mut FnCtx,
    info: &DAE::ReductionInfo,
    fold: &DAE::Exp,
    expr: &DAE::Exp,
    iters: &[&Arc<DAE::ReductionIterator>],
    elem_sty: SigTy,
) -> Result<WTy> {
    use we::Instruction as I;
    let release_fn = elem_sty
        .release_fn()
        .ok_or("CodegenWasmJit: heap reduction accumulator without a release entry point")?;
    let acc = ctx.alloc_temp(WTy::I32);
    let foldval = ctx.alloc_temp(WTy::I32);
    let found = ctx.alloc_temp(WTy::I32);
    // Registered only for this reduction: left in `ctx.locals`, the function
    // epilogue would release the accumulator we hand back as an owned value.
    let res_name = info.resultName.to_string();
    let fold_name = info.foldName.to_string();
    let prev_res = ctx.locals.insert(res_name.clone(), (acc, elem_sty.clone()));
    let prev_fold = ctx.locals.insert(fold_name.clone(), (foldval, elem_sty.clone()));
    for l in [acc, foldval, found] {
        ctx.emit(I::I32Const(0));
        ctx.emit(I::LocalSet(l));
    }
    emit_red_iteration(ctx, red_is_thread(info), iters, &mut |ctx| {
        let nv = ctx.alloc_temp(WTy::I32);
        compile_exp(ctx, expr)?; // owned element
        ctx.emit(I::LocalSet(nv));
        ctx.emit(I::LocalGet(foldval));
        ctx.emit(I::Call(rt_index(release_fn)?));
        ctx.emit(I::LocalGet(nv));
        ctx.emit(I::LocalSet(foldval));
        ctx.emit(I::LocalGet(found));
        ctx.emit(I::If(we::BlockType::Empty));
        let folded = ctx.alloc_temp(WTy::I32);
        compile_exp(ctx, fold)?; // owned; reads both locals retained
        ctx.emit(I::LocalSet(folded));
        ctx.emit(I::LocalGet(acc));
        ctx.emit(I::Call(rt_index(release_fn)?));
        ctx.emit(I::LocalGet(folded));
        ctx.emit(I::LocalSet(acc));
        ctx.emit(I::Else);
        ctx.emit(I::LocalGet(foldval));
        ctx.emit(I::Call(rt_index("rt_retain")?));
        ctx.emit(I::LocalGet(foldval));
        ctx.emit(I::LocalSet(acc));
        ctx.emit(I::I32Const(1));
        ctx.emit(I::LocalSet(found));
        ctx.emit(I::End);
        Ok(())
    })?;
    ctx.emit(I::LocalGet(found));
    ctx.emit(I::I32Eqz);
    ctx.emit(I::If(we::BlockType::Empty));
    emit_runtime_error(ctx, "Reduction over an empty range has no value")?;
    ctx.emit(I::End);
    ctx.emit(I::LocalGet(foldval));
    ctx.emit(I::Call(rt_index(release_fn)?));
    match prev_res {
        Some(v) => ctx.locals.insert(res_name, v),
        None => ctx.locals.remove(&res_name),
    };
    match prev_fold {
        Some(v) => ctx.locals.insert(fold_name, v),
        None => ctx.locals.remove(&fold_name),
    };
    ctx.emit(I::LocalGet(acc));
    Ok(WTy::I32)
}

/// An `array(...)` comprehension whose body is itself an array: one flat array of
/// rank `iterators + erank`, leading axes the iterator counts (last iterator
/// outermost) and trailing ones the body's own — C's `alloc_<t>(&res, 1 + |dims|,
/// length, dims…)`. C takes those trailing dims from the body's type and bails
/// when they are not resolvable; they are read off the first value here.
fn compile_array_comprehension_flat(
    ctx: &mut FnCtx,
    expr: &DAE::Exp,
    thread: bool,
    iters: &[&Arc<DAE::ReductionIterator>],
    base: &SigTy,
    erank: u32,
) -> Result<WTy> {
    use we::Instruction as I;
    let mut counts = Vec::with_capacity(iters.len());
    for it in iters {
        counts.push(emit_red_iter_count(ctx, it)?);
    }
    if thread {
        counts.truncate(1);
    }
    let n = counts.len() as u32;
    let outer = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::I32Const(1));
    ctx.emit(I::LocalSet(outer));
    for c in &counts {
        ctx.emit(I::LocalGet(outer));
        ctx.emit(I::LocalGet(*c));
        ctx.emit(I::I32Mul);
        ctx.emit(I::LocalSet(outer));
    }
    let res = ctx.alloc_temp(WTy::I32);
    let idx = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::I32Const(0));
    ctx.emit(I::LocalSet(res));
    ctx.emit(I::I32Const(0));
    ctx.emit(I::LocalSet(idx));
    let kind = base.elem_kind() as i32;
    let set_outer_dims = |ctx: &mut FnCtx| -> Result<()> {
        for d in 0..n {
            ctx.emit(I::LocalGet(res));
            ctx.emit(I::I32Const(d as i32));
            ctx.emit(I::LocalGet(counts[(n - 1 - d) as usize]));
            ctx.emit(I::Call(rt_index("rt_array_set_dim")?));
        }
        Ok(())
    };
    let rev: Vec<&Arc<DAE::ReductionIterator>> = iters.iter().rev().cloned().collect();
    emit_red_iteration(ctx, thread, &rev, &mut |ctx| {
        let h = ctx.alloc_temp(WTy::I32);
        compile_exp(ctx, expr)?; // owned element array
        ctx.emit(I::LocalSet(h));
        ctx.emit(I::LocalGet(res));
        ctx.emit(I::I32Eqz);
        ctx.emit(I::If(we::BlockType::Empty));
        ctx.emit(I::I32Const(kind));
        ctx.emit(I::I32Const((n + erank) as i32));
        ctx.emit(I::LocalGet(outer));
        ctx.emit(I::LocalGet(h));
        ctx.emit(I::I32Load(mem_arg(ARR_TOTAL_OFF, 2)));
        ctx.emit(I::I32Mul);
        ctx.emit(I::Call(rt_index("rt_array_new")?));
        ctx.emit(I::LocalSet(res));
        set_outer_dims(ctx)?;
        for k in 0..erank {
            ctx.emit(I::LocalGet(res));
            ctx.emit(I::I32Const((n + k) as i32)); // rt_array_set_dim: 0-based
            ctx.emit(I::LocalGet(h));
            ctx.emit(I::I32Const((k + 1) as i32)); // rt_array_dim: 1-based
            ctx.emit(I::Call(rt_index("rt_array_dim")?));
            ctx.emit(I::Call(rt_index("rt_array_set_dim")?));
        }
        ctx.emit(I::End);
        ctx.emit(I::LocalGet(res));
        ctx.emit(I::LocalGet(idx));
        ctx.emit(I::LocalGet(h));
        ctx.emit(I::Call(rt_index("rt_array_blit")?));
        ctx.emit(I::LocalGet(idx));
        ctx.emit(I::LocalGet(h));
        ctx.emit(I::I32Load(mem_arg(ARR_TOTAL_OFF, 2)));
        ctx.emit(I::I32Add);
        ctx.emit(I::LocalSet(idx));
        ctx.emit(I::LocalGet(h));
        ctx.emit(I::Call(rt_index("rt_array_release")?));
        Ok(())
    })?;
    // An empty range produced no value to take the body's shape from; the result
    // is empty either way, so those axes stay zero.
    ctx.emit(I::LocalGet(res));
    ctx.emit(I::I32Eqz);
    ctx.emit(I::If(we::BlockType::Empty));
    ctx.emit(I::I32Const(kind));
    ctx.emit(I::I32Const((n + erank) as i32));
    ctx.emit(I::I32Const(0));
    ctx.emit(I::Call(rt_index("rt_array_new")?));
    ctx.emit(I::LocalSet(res));
    set_outer_dims(ctx)?;
    ctx.emit(I::End);
    ctx.emit(I::LocalGet(res));
    Ok(WTy::I32)
}

/// Compile an expression, leaving exactly one value on the wasm stack; returns
/// its type.
/// Canonical string key for a component reference, used to match equation crefs
/// against the `SimVars` model-variable names (`CodegenWasmJit`). Identifiers
/// are joined with `.`; constant integer subscripts are appended as `[i]` (the
/// SimCode is scalarized, so a scalar element's subscripts are part of its
/// identity). The `$DER`/`$PRE`/`$START` qualifier idents are kept verbatim so
/// `der(x)` (cref `$DER.x`) keys distinctly from `x`.
/// The `pre(cr)` component reference: `cr` wrapped in a `$PRE` qualifier, as the
/// backend emits it. Reused for reading a variable's pre-value.
pub(super) fn pre_cref(cr: &DAE::ComponentRef) -> Arc<DAE::ComponentRef> {
    use DAE::ComponentRef as C;
    let identType = match cr {
        C::CREF_IDENT { identType, .. } | C::CREF_QUAL { identType, .. } => identType.clone(),
        _ => crate::CodegenWasmJit::t_real(),
    };
    Arc::new(C::CREF_QUAL {
        ident: arcstr::literal!("$PRE"),
        identType,
        subscriptLst: metamodelica::nil(),
        componentRef: Arc::new(cr.clone()),
    })
}
