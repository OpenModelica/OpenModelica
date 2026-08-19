//! The new backend's non-scalarized array equations: a `SimGenericCall` body
//! plus the iterators to run it over. C emits the body as `genericCall_<n>` and
//! calls it from the loops (`CodegenC.tpl:equationGenericAssign`); here it is
//! inlined, the way `SES_IFEQUATION` inlines its branches.

use std::sync::Arc;

use metamodelica::Result;

use openmodelica_backend_types::BackendDAE;
use openmodelica_frontend_types::DAE;
use openmodelica_simcode_types::SimCode;
use wasm_encoder as we;

use super::*;

/// `SES_RESIZABLE_ASSIGN`: run call `call_index` over the equation's `iters`.
pub(crate) fn emit_resizable_assign(
    ctx: &mut FnCtx,
    call_index: i32,
    iters: &Arc<List<BackendDAE::SimIterator>>,
) -> Result<()> {
    let call = lookup_call(ctx, call_index)?;
    let iters: Vec<&BackendDAE::SimIterator> = (&**iters).into_iter().collect();
    emit_loops(ctx, &iters, &mut |ctx| emit_call_body(ctx, &call))
}

/// `SES_GENERIC_ASSIGN`: run call `call_index` for each index in `scal_indices`.
pub(crate) fn emit_generic_assign(
    ctx: &mut FnCtx,
    call_index: i32,
    scal_indices: &Arc<List<i32>>,
) -> Result<()> {
    use we::Instruction as I;
    let call = lookup_call(ctx, call_index)?;
    let indices: Vec<i32> = (&**scal_indices).into_iter().copied().collect();
    if indices.is_empty() {
        return Ok(());
    }
    let table = emit_const_int_table(ctx, &indices)?;
    let k = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::I32Const(0));
    ctx.emit(I::LocalSet(k));
    ctx.emit(I::Block(we::BlockType::Empty));
    ctx.emit(I::Loop(we::BlockType::Empty));
    ctx.emit(I::LocalGet(k));
    ctx.emit(I::I32Const(indices.len() as i32));
    ctx.emit(I::I32GeS);
    ctx.emit(I::BrIf(1));
    let idx = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::LocalGet(table));
    ctx.emit(I::LocalGet(k));
    ctx.emit(I::I32Const(4));
    ctx.emit(I::I32Mul);
    ctx.emit(I::I32Add);
    ctx.emit(I::I32Load(mem_arg(0, 2)));
    ctx.emit(I::LocalSet(idx));
    emit_index_body(ctx, &call, idx)?;
    ctx.emit(I::LocalGet(k));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(k));
    ctx.emit(I::Br(0));
    ctx.emit(I::End); // loop
    ctx.emit(I::End); // block
    Ok(())
}

/// `SES_ENTWINED_ASSIGN`: calls interleaved in `call_order`, each consuming its
/// own index list in turn. The order is constant, so C's switch unrolls.
pub(crate) fn emit_entwined_assign(
    ctx: &mut FnCtx,
    call_order: &Arc<List<i32>>,
    single_calls: &Arc<List<Arc<SimCode::SimEqSystem>>>,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
) -> Result<()> {
    use SimCode::SimEqSystem as E;
    let calls: Vec<Arc<SimCode::SimEqSystem>> = (&**single_calls).into_iter().cloned().collect();
    let mut consumed = vec![0usize; calls.len()];
    for slot in (&**call_order).into_iter() {
        let eq = calls
            .get(usize::try_from(*slot).map_err(|_| "CodegenWasmJit: negative entwined call index")?)
            .ok_or("CodegenWasmJit: entwined call order names a missing call")?;
        match &**eq {
            E::SES_GENERIC_ASSIGN { call_index, scal_indices, .. } => {
                let n = &mut consumed[*slot as usize];
                let idx = (&**scal_indices)
                    .into_iter()
                    .nth(*n)
                    .ok_or("CodegenWasmJit: entwined call order overruns its index list")?;
                *n += 1;
                let call = lookup_call(ctx, *call_index)?;
                let local = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::I32Const(*idx));
                ctx.emit(we::Instruction::LocalSet(local));
                emit_index_body(ctx, &call, local)?;
            }
            // No index list: a turn runs the whole equation.
            other => crate::CodegenWasmJit::lower_equation(ctx, other, eq_index)?,
        }
    }
    Ok(())
}

fn lookup_call(ctx: &FnCtx, call_index: i32) -> Result<SimCode::SimGenericCall> {
    ctx.sim()?
        .generic_calls
        .get(&call_index)
        .cloned()
        .ok_or("CodegenWasmJit: for-equation names an unknown generic call")
}

/// C's `genericIterator`: recover each iterator from `idx` by mixed-radix
/// division (first listed iterator least significant), then run the body.
fn emit_index_body(ctx: &mut FnCtx, call: &SimCode::SimGenericCall, idx: u32) -> Result<()> {
    use we::Instruction as I;
    let iters: Vec<BackendDAE::SimIterator> = (&**call_iters(call)).into_iter().cloned().collect();
    let tmp = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::LocalGet(idx));
    ctx.emit(I::LocalSet(tmp));
    let mut bounds = Vec::new();
    for iter in &iters {
        let it = ctx.alloc_temp(WTy::I32);
        let (name, size) = match iter {
            BackendDAE::SimIterator::SIM_ITERATOR_RANGE { name, start, step, size, .. } => {
                // it = step * (tmp % size) + start
                let w = compile_exp(ctx, step)?;
                coerce(ctx, w, WTy::I32);
                ctx.emit(I::LocalGet(tmp));
                let w = compile_exp(ctx, size)?;
                coerce(ctx, w, WTy::I32);
                ctx.emit(I::I32RemS);
                ctx.emit(I::I32Mul);
                let w = compile_exp(ctx, start)?;
                coerce(ctx, w, WTy::I32);
                ctx.emit(I::I32Add);
                ctx.emit(I::LocalSet(it));
                (name, size.clone())
            }
            BackendDAE::SimIterator::SIM_ITERATOR_LIST { name, lst: values, size, .. } => {
                let table = emit_const_int_table(ctx, &int_list(values))?;
                ctx.emit(I::LocalGet(table));
                ctx.emit(I::LocalGet(tmp));
                ctx.emit(I::I32Const(*size));
                ctx.emit(I::I32RemS);
                ctx.emit(I::I32Const(4));
                ctx.emit(I::I32Mul);
                ctx.emit(I::I32Add);
                ctx.emit(I::I32Load(mem_arg(0, 2)));
                ctx.emit(I::LocalSet(it));
                (name, Arc::new(DAE::Exp::ICONST { integer: *size }))
            }
        };
        ctx.emit(I::LocalGet(tmp));
        let w = compile_exp(ctx, &size)?;
        coerce(ctx, w, WTy::I32);
        ctx.emit(I::I32DivS);
        ctx.emit(I::LocalSet(tmp));
        bounds.push(bind_iter(ctx, name, it, SigTy::Int)?);
        bounds.extend(emit_sub_iters(ctx, iter_sub_iter(iter), it)?);
    }
    emit_call_body(ctx, call)?;
    for b in bounds.into_iter().rev() {
        unbind_iter(ctx, b);
    }
    Ok(())
}

/// A constant `Integer[:]` table as a module-wide object; leaves its element-data
/// address in a fresh local.
fn emit_const_int_table(ctx: &mut FnCtx, values: &[i32]) -> Result<u32> {
    let array: List<Arc<DAE::Exp>> =
        values.iter().map(|&v| Arc::new(DAE::Exp::ICONST { integer: v })).collect();
    let ty = Arc::new(DAE::Type::T_ARRAY {
        ty: Arc::new(DAE::Type::T_INTEGER { varLst: metamodelica::nil() }),
        dims: metamodelica::list![Arc::new(DAE::Dimension::DIM_INTEGER {
            integer: values.len() as i32
        })],
    });
    let exp = DAE::Exp::ARRAY { ty, scalar: true, array: Arc::new(array) };
    let g = shared_lits::intern_const(&exp);
    let ptr = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::GlobalGet(g));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_data")?));
    ctx.emit(we::Instruction::LocalSet(ptr));
    Ok(ptr)
}

fn int_list(values: &Arc<List<i32>>) -> Vec<i32> {
    (&**values).into_iter().copied().collect()
}

fn call_iters(call: &SimCode::SimGenericCall) -> &Arc<List<BackendDAE::SimIterator>> {
    use SimCode::SimGenericCall as G;
    match call {
        G::SINGLE_GENERIC_CALL { iters, .. }
        | G::IF_GENERIC_CALL { iters, .. }
        | G::WHEN_GENERIC_CALL { iters, .. } => iters,
    }
}

type SubIters = Arc<List<(Arc<DAE::ComponentRef>, metamodelica::Array<Arc<DAE::Exp>>)>>;

fn iter_sub_iter(iter: &BackendDAE::SimIterator) -> &SubIters {
    use BackendDAE::SimIterator as S;
    match iter {
        S::SIM_ITERATOR_RANGE { sub_iter, .. } | S::SIM_ITERATOR_LIST { sub_iter, .. } => sub_iter,
    }
}

/// C's `forIterator`: nested loops over `iters`, outermost first.
fn emit_loops(
    ctx: &mut FnCtx,
    iters: &[&BackendDAE::SimIterator],
    body: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    use we::Instruction as I;
    let Some((iter, rest)) = iters.split_first() else {
        return body(ctx);
    };
    let BackendDAE::SimIterator::SIM_ITERATOR_RANGE { name, start, step, stop, sub_iter, .. } = iter
    else {
        return emit_list_loop(ctx, iter, rest, body);
    };
    let it = ctx.alloc_temp(WTy::I32);
    let start_l = ctx.alloc_temp(WTy::I32);
    let step_l = ctx.alloc_temp(WTy::I32);
    let stop_l = ctx.alloc_temp(WTy::I32);
    let w = compile_exp(ctx, start)?;
    coerce(ctx, w, WTy::I32);
    ctx.emit(I::LocalTee(start_l));
    ctx.emit(I::LocalSet(it));
    let w = compile_exp(ctx, step)?;
    coerce(ctx, w, WTy::I32);
    ctx.emit(I::LocalSet(step_l));
    let w = compile_exp(ctx, stop)?;
    coerce(ctx, w, WTy::I32);
    ctx.emit(I::LocalSet(stop_l));

    let bound = bind_iter(ctx, name, it, SigTy::Int)?;
    ctx.emit(I::Block(we::BlockType::Empty));
    ctx.emit(I::Loop(we::BlockType::Empty));
    emit_in_range(ctx, it, start_l, stop_l);
    ctx.emit(I::I32Eqz);
    ctx.emit(I::BrIf(1));
    let sub_bounds = emit_sub_iters(ctx, sub_iter, it)?;
    emit_loops(ctx, rest, body)?;
    for b in sub_bounds.into_iter().rev() {
        unbind_iter(ctx, b);
    }
    ctx.emit(I::LocalGet(it));
    ctx.emit(I::LocalGet(step_l));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(it));
    ctx.emit(I::Br(0));
    ctx.emit(I::End); // loop
    ctx.emit(I::End); // block
    unbind_iter(ctx, bound);
    Ok(())
}

/// The index-list arm of [`emit_loops`]: `for (k = 0; k < size; k++) it = lst[k]`.
fn emit_list_loop(
    ctx: &mut FnCtx,
    iter: &BackendDAE::SimIterator,
    rest: &[&BackendDAE::SimIterator],
    body: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    use we::Instruction as I;
    let BackendDAE::SimIterator::SIM_ITERATOR_LIST { name, lst: values, size, sub_iter } = iter
    else {
        return Err("CodegenWasmJit: for-equation iterator is neither a range nor a list");
    };
    let table = emit_const_int_table(ctx, &int_list(values))?;
    let k = ctx.alloc_temp(WTy::I32);
    let it = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::I32Const(0));
    ctx.emit(I::LocalSet(k));
    let bound = bind_iter(ctx, name, it, SigTy::Int)?;
    ctx.emit(I::Block(we::BlockType::Empty));
    ctx.emit(I::Loop(we::BlockType::Empty));
    ctx.emit(I::LocalGet(k));
    ctx.emit(I::I32Const(*size));
    ctx.emit(I::I32GeS);
    ctx.emit(I::BrIf(1));
    ctx.emit(I::LocalGet(table));
    ctx.emit(I::LocalGet(k));
    ctx.emit(I::I32Const(4));
    ctx.emit(I::I32Mul);
    ctx.emit(I::I32Add);
    ctx.emit(I::I32Load(mem_arg(0, 2)));
    ctx.emit(I::LocalSet(it));
    // C indexes a list iterator's dependent tables by the counter + 1.
    let counter = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::LocalGet(k));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(counter));
    let sub_bounds = emit_sub_iters(ctx, sub_iter, counter)?;
    emit_loops(ctx, rest, body)?;
    for b in sub_bounds.into_iter().rev() {
        unbind_iter(ctx, b);
    }
    ctx.emit(I::LocalGet(k));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(k));
    ctx.emit(I::Br(0));
    ctx.emit(I::End); // loop
    ctx.emit(I::End); // block
    unbind_iter(ctx, bound);
    Ok(())
}

/// C's `in_range_integer`: brackets the range whichever way the step runs.
fn emit_in_range(ctx: &mut FnCtx, it: u32, start_l: u32, stop_l: u32) {
    use we::Instruction as I;
    for (lo, hi) in [(start_l, stop_l), (stop_l, start_l)] {
        ctx.emit(I::LocalGet(it));
        ctx.emit(I::LocalGet(lo));
        ctx.emit(I::I32GeS);
        ctx.emit(I::LocalGet(it));
        ctx.emit(I::LocalGet(hi));
        ctx.emit(I::I32LeS);
        ctx.emit(I::I32And);
    }
    ctx.emit(I::I32Or);
}

/// C's `subIterator`: `name = name_arr[parent - 1]`.
fn emit_sub_iters(
    ctx: &mut FnCtx,
    sub_iter: &Arc<List<(Arc<DAE::ComponentRef>, metamodelica::Array<Arc<DAE::Exp>>)>>,
    parent: u32,
) -> Result<Vec<IterBinding>> {
    use we::Instruction as I;
    let mut bounds = Vec::new();
    for (name, range) in &**sub_iter {
        let elems: Vec<Arc<DAE::Exp>> = range.borrow().clone();
        if elems.is_empty() {
            return Err("CodegenWasmJit: dependent for-equation iterator over an empty range");
        }
        let ty = exp_sigty(&elems[0])?;
        let wty = ty.wty();
        let local = ctx.alloc_temp(wty);
        // Constant table: select with a chain of `if`s rather than
        // materializing it.
        for (k, exp) in elems.iter().enumerate() {
            let w = compile_exp(ctx, exp)?;
            coerce(ctx, w, wty);
            ctx.emit(I::LocalSet(local));
            if k + 1 == elems.len() {
                break;
            }
            ctx.emit(I::LocalGet(parent));
            ctx.emit(I::I32Const(k as i32 + 1));
            ctx.emit(I::I32Ne);
            ctx.emit(I::If(we::BlockType::Empty));
        }
        for _ in 0..elems.len() - 1 {
            ctx.emit(I::End);
        }
        bounds.push(bind_iter(ctx, name, local, ty)?);
    }
    Ok(bounds)
}

/// An iterator bound as a wasm local, with whatever binding it displaced.
struct IterBinding {
    ident: String,
    prev: Option<(u32, SigTy)>,
}

/// Bind `name` to `local`, shadowing a model variable of the same name.
fn bind_iter(ctx: &mut FnCtx, name: &DAE::ComponentRef, local: u32, ty: SigTy) -> Result<IterBinding> {
    let ident = cref_ident(name)?;
    let prev = ctx.locals.insert(ident.clone(), (local, ty));
    Ok(IterBinding { ident, prev })
}

fn unbind_iter(ctx: &mut FnCtx, b: IterBinding) {
    match b.prev {
        Some(p) => {
            ctx.locals.insert(b.ident, p);
        }
        None => {
            ctx.locals.remove(&b.ident);
        }
    }
}

/// The shared loop body: C's `genericCallBodies`.
fn emit_call_body(ctx: &mut FnCtx, call: &SimCode::SimGenericCall) -> Result<()> {
    use SimCode::SimGenericCall as G;
    match call {
        G::SINGLE_GENERIC_CALL { lhs, rhs, .. } => ctx.sim_assign(lhs, rhs),
        G::IF_GENERIC_CALL { branches, .. } | G::WHEN_GENERIC_CALL { branches, .. } => {
            emit_branches(ctx, branches)
        }
    }
}

/// C's `genericBranch` chain; a branch with no condition is the trailing `else`.
fn emit_branches(ctx: &mut FnCtx, branches: &Arc<List<SimCode::SimBranch>>) -> Result<()> {
    use SimCode::SimBranch as B;
    let mut depth = 0;
    for branch in &**branches {
        let cond = match branch {
            B::SIM_BRANCH { condition, .. } | B::SIM_BRANCH_STMT { condition, .. } => condition,
        };
        if let Some(c) = cond {
            ctx.sim_if_cond(c)?;
        }
        match branch {
            B::SIM_BRANCH { body, .. } => {
                for (lhs, rhs) in &**body {
                    ctx.sim_assign(lhs, rhs)?;
                }
            }
            B::SIM_BRANCH_STMT { body, .. } => ctx.sim_stmts(body)?,
        }
        if cond.is_none() {
            break;
        }
        ctx.sim_else();
        depth += 1;
    }
    for _ in 0..depth {
        ctx.sim_end_block();
    }
    Ok(())
}
