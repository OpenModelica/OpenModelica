//! Array operations: element-wise, dot/matmul, indexing, slicing, `size`,
//! the array builtins, coercion.

use super::*;

// Element-wise / broadcast op codes — must match the runtime's `OP_*`.
pub(super) const OP_ADD: i32 = 0;

pub(super) const OP_SUB: i32 = 1;

pub(super) const OP_MUL: i32 = 2;

pub(super) const OP_DIV: i32 = 3;

pub(super) const OP_POW: i32 = 4;

pub(super) const OP_AND: i32 = 5;

pub(super) const OP_OR: i32 = 6;

/// The element type of an array operation: the operator's own type, else an
/// operand's, since both frontends leave arithmetic operators `T_UNKNOWN`. A
/// *definite* scalar operator type over array operands is an inconsistent DAE, so
/// that case is named rather than lowered.
fn array_op_elem(ty: &DAE::Type, operands: [&DAE::Exp; 2]) -> Result<Arc<SigTy>> {
    match sig_ty(ty) {
        Ok(SigTy::Array { elem, .. }) => return Ok(elem),
        Ok(_) => {}
        Err(_) => {
            for e in operands {
                if let Ok(Some(elem)) = array_elem(e) {
                    return Ok(elem);
                }
            }
        }
    }
    let show = |x: &DAE::Exp| {
        openmodelica_frontend_dump::ExpressionBasics::printExpStr(Arc::new(x.clone()))
            .map(|s| s.to_string())
            .unwrap_or_default()
    };
    crate::CodegenWasmJit::record_error(format!(
        "CodegenWasmJit: array operator between `{}` and `{}` types neither as an array{}",
        show(operands[0]),
        show(operands[1]),
        fn_context()
    ));
    Err("CodegenWasmJit: array operator with non-array type")
}

/// `exp_sigty` is best-effort: an `Err` means "unknown", not "not an array".
fn is_array_exp(e: &DAE::Exp) -> bool {
    matches!(exp_sigty(e), Ok(SigTy::Array { .. }))
}

/// Element-wise `a op b` over two same-shape arrays: produces a fresh array; the
/// operand arrays are released after.
pub(super) fn compile_array_ew(ctx: &mut FnCtx, e1: &DAE::Exp, e2: &DAE::Exp, op_code: i32, ty: &DAE::Type) -> Result<WTy> {
    let elem = array_op_elem(ty, [e1, e2])?;
    let rt = if elem.wty() == WTy::F64 { "rt_array_ew_f64" } else { "rt_array_ew_i32" };
    compile_exp(ctx, e1)?;
    let at = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(at));
    compile_exp(ctx, e2)?;
    let bt = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(bt));
    ctx.emit(we::Instruction::LocalGet(at));
    ctx.emit(we::Instruction::LocalGet(bt));
    ctx.emit(we::Instruction::I32Const(op_code));
    ctx.emit(we::Instruction::Call(rt_index(rt)?));
    release_temp_array(ctx, at)?;
    release_temp_array(ctx, bt)?;
    Ok(WTy::I32)
}

/// `v1 * v2` scalar (dot) product of two numeric vectors → a scalar. Both
/// operand arrays are released; the scalar result is left on the stack.
pub(super) fn compile_dot(ctx: &mut FnCtx, e1: &DAE::Exp, e2: &DAE::Exp) -> Result<WTy> {
    let elem = array_elem(e1)?.ok_or_else(|| "CodegenWasmJit: scalar-product operand is not an array")?;
    let f64mode = elem.wty() == WTy::F64;
    let rt = if f64mode { "rt_array_dot_f64" } else { "rt_array_dot_i32" };
    compile_exp(ctx, e1)?;
    let at = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(at));
    compile_exp(ctx, e2)?;
    let bt = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(bt));
    ctx.emit(we::Instruction::LocalGet(at));
    ctx.emit(we::Instruction::LocalGet(bt));
    ctx.emit(we::Instruction::Call(rt_index(rt)?));
    release_temp_array(ctx, at)?;
    release_temp_array(ctx, bt)?;
    Ok(if f64mode { WTy::F64 } else { WTy::I32 })
}

/// `a * b` matrix product (matrix·matrix / matrix·vector / vector·matrix). The
/// runtime computes the result shape from the operand ranks; both operands are
/// released and the fresh result array handle is left on the stack.
pub(super) fn compile_matmul(ctx: &mut FnCtx, e1: &DAE::Exp, e2: &DAE::Exp) -> Result<WTy> {
    let elem = array_elem(e1)?.ok_or_else(|| "CodegenWasmJit: matrix-product operand is not an array")?;
    let rt = if elem.wty() == WTy::F64 { "rt_array_matmul_f64" } else { "rt_array_matmul_i32" };
    compile_exp(ctx, e1)?;
    let at = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(at));
    compile_exp(ctx, e2)?;
    let bt = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(bt));
    ctx.emit(we::Instruction::LocalGet(at));
    ctx.emit(we::Instruction::LocalGet(bt));
    ctx.emit(we::Instruction::Call(rt_index(rt)?));
    let result_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(result_t));
    release_temp_array(ctx, at)?;
    release_temp_array(ctx, bt)?;
    ctx.emit(we::Instruction::LocalGet(result_t));
    Ok(WTy::I32)
}

/// Scalar broadcast over an array: `rev ? (s op a[i]) : (a[i] op s)`. The array
/// and scalar operands are found by type (so commutative forms accept either
/// order); the array operand is released after.
pub(super) fn compile_array_scalar(ctx: &mut FnCtx, e1: &DAE::Exp, e2: &DAE::Exp, op_code: i32, rev: bool, ty: &DAE::Type) -> Result<WTy> {
    let elem = array_op_elem(ty, [e1, e2])?;
    let elem_wty = elem.wty();
    let rt = if elem_wty == WTy::F64 { "rt_array_scalar_f64" } else { "rt_array_scalar_i32" };
    // By type where the frontend typed one, else by the operator's own convention:
    // `rev` marks the scalar-first forms.
    let arr_first = match (is_array_exp(e1), is_array_exp(e2)) {
        (a, b) if a != b => a,
        _ => !rev,
    };
    let (arr_e, scal_e) = if arr_first { (e1, e2) } else { (e2, e1) };
    compile_exp(ctx, arr_e)?;
    let at = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(at));
    let sw = compile_exp(ctx, scal_e)?;
    coerce(ctx, sw, elem_wty);
    let st = ctx.alloc_temp(elem_wty);
    ctx.emit(we::Instruction::LocalSet(st));
    ctx.emit(we::Instruction::LocalGet(at));
    ctx.emit(we::Instruction::LocalGet(st));
    ctx.emit(we::Instruction::I32Const(op_code));
    ctx.emit(we::Instruction::I32Const(rev as i32));
    ctx.emit(we::Instruction::Call(rt_index(rt)?));
    release_temp_array(ctx, at)?;
    Ok(WTy::I32)
}

/// Lower `a[i, j, ...]`: one `INDEX` per dimension reads a scalar element,
/// anything else slices to a lower-rank sub-array. `base` produces the owned
/// array handle. Returns the result's wasm type.
pub(super) fn compile_index(ctx: &mut FnCtx, base: &DAE::Exp, subs: &List<Arc<DAE::Subscript>>) -> Result<WTy> {
    let SigTy::Array { elem, rank } = exp_sigty(base)? else {
        return Err("CodegenWasmJit: subscripting a non-array expression");
    };
    compile_exp(ctx, base)?; // owned array handle
    if is_scalar_index(subs, rank) {
        let idx_exps = index_subscripts(subs, rank)?;
        index_loaded(ctx, &elem, &idx_exps)
    } else {
        slice_loaded(ctx, subs)
    }
}

/// Whether a subscript list is a full scalar index — exactly one `INDEX` per
/// dimension — and so yields a scalar element. Anything else (a `WHOLEDIM` /
/// `SLICE`, or fewer subscripts than the rank, i.e. trailing whole dimensions)
/// slices the array to a lower-rank sub-array and goes through [`slice_loaded`].
pub(super) fn is_scalar_index(subs: &List<Arc<DAE::Subscript>>, rank: u32) -> bool {
    let mut n = 0u32;
    let mut all_index = true;
    for s in &**subs {
        n += 1;
        if !matches!(&**s, DAE::Subscript::INDEX { .. }) {
            all_index = false;
        }
    }
    all_index && n == rank
}

/// Extract one `INDEX` expression per dimension from a subscript list. Callers
/// gate on [`is_scalar_index`] first, so anything else is a codegen bug.
pub(super) fn index_subscripts(subs: &List<Arc<DAE::Subscript>>, rank: u32) -> Result<Vec<Arc<DAE::Exp>>> {
    let subs: Vec<&Arc<DAE::Subscript>> = (&**subs).into_iter().collect();
    if subs.len() as u32 != rank {
        return Err("CodegenWasmJit: partial indexing on the scalar-index path");
    }
    let mut out = Vec::with_capacity(subs.len());
    for s in subs {
        match &**s {
            DAE::Subscript::INDEX { exp } => out.push(exp.clone()),
            other => return Err("CodegenWasmJit: non-scalar subscript on the scalar-index path"),
        }
    }
    Ok(out)
}

/// Given an owned array handle on top of the stack plus the `INDEX` expressions
/// (one per dimension), compute the row-major linear index, load the scalar
/// element, release the array, and leave the (owned, if heap) element. Returns
/// the element's wasm type.
pub(super) fn index_loaded(ctx: &mut FnCtx, elem: &SigTy, idx_exps: &[Arc<DAE::Exp>]) -> Result<WTy> {
    let arr_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(arr_t));

    // acc = (i0 - 1); then acc = acc * dim(axis) + (i_axis - 1) row-major.
    let acc = ctx.alloc_temp(WTy::I32);
    let w = compile_exp(ctx, &idx_exps[0])?;
    coerce(ctx, w, WTy::I32);
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Sub);
    ctx.emit(we::Instruction::LocalSet(acc));
    for (axis0, ie) in idx_exps.iter().enumerate().skip(1) {
        ctx.emit(we::Instruction::LocalGet(acc));
        ctx.emit(we::Instruction::LocalGet(arr_t));
        emit_array_dim(ctx, axis0 as u32 + 1)?; // 1-based axis
        ctx.emit(we::Instruction::I32Mul);
        let w = compile_exp(ctx, ie)?;
        coerce(ctx, w, WTy::I32);
        ctx.emit(we::Instruction::I32Const(1));
        ctx.emit(we::Instruction::I32Sub);
        ctx.emit(we::Instruction::I32Add);
        ctx.emit(we::Instruction::LocalSet(acc));
    }
    ctx.emit(we::Instruction::LocalGet(arr_t));
    ctx.emit(we::Instruction::LocalGet(acc));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    emit_elem_ptr(ctx, elem)?;
    elem_load(ctx, elem);

    if elem.is_heap() {
        // The element is a borrowed handle into the array; retain it so it
        // outlives the array we now release, making it an owned (+1) result.
        let v = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalSet(v));
        ctx.emit(we::Instruction::LocalGet(v));
        ctx.emit(we::Instruction::Call(rt_index("rt_retain")?));
        release_temp_array(ctx, arr_t)?;
        ctx.emit(we::Instruction::LocalGet(v));
    } else {
        // Scalar value already on the stack; releasing the array (void) leaves it.
        release_temp_array(ctx, arr_t)?;
    }
    Ok(elem.wty())
}

/// Push the byte address of element `slot` (1-based) of the spec array held in
/// local `spec_t` onto the stack.
fn spec_elem_addr(ctx: &mut FnCtx, spec_t: u32, slot: i32) -> Result<()> {
    ctx.emit(we::Instruction::LocalGet(spec_t));
    ctx.emit(we::Instruction::I32Const(slot));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")?));
    Ok(())
}

/// Build the per-axis spec `rt_array_slice` / `rt_array_indexed_assign` read: an
/// `Integer[2*nspec]` of (kind, value) pairs, one pair per subscript. Returns the
/// temps holding the spec and the owned SLICE index arrays; the caller releases
/// both.
fn emit_slice_spec(ctx: &mut FnCtx, subs: &[&Arc<DAE::Subscript>]) -> Result<(u32, Vec<u32>)> {
    let spec_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(0)); // EK_INT
    ctx.emit(we::Instruction::I32Const(1)); // ndims
    ctx.emit(we::Instruction::I32Const(2 * subs.len() as i32)); // total
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")?));
    ctx.emit(we::Instruction::LocalSet(spec_t));

    let mut slice_idx_temps: Vec<u32> = Vec::new();
    for (ax, s) in subs.iter().enumerate() {
        let kind_slot = 2 * ax as i32 + 1;
        let val_slot = 2 * ax as i32 + 2;
        match &***s {
            DAE::Subscript::INDEX { exp } => {
                spec_elem_addr(ctx, spec_t, kind_slot)?;
                ctx.emit(we::Instruction::I32Const(0)); // INDEX
                ctx.emit(we::Instruction::I32Store(mem_arg(0, 2)));
                spec_elem_addr(ctx, spec_t, val_slot)?;
                let w = compile_exp(ctx, exp)?;
                coerce(ctx, w, WTy::I32);
                ctx.emit(we::Instruction::I32Store(mem_arg(0, 2)));
            }
            DAE::Subscript::WHOLEDIM | DAE::Subscript::WHOLE_NONEXP { .. } => {
                spec_elem_addr(ctx, spec_t, kind_slot)?;
                ctx.emit(we::Instruction::I32Const(1)); // WHOLE
                ctx.emit(we::Instruction::I32Store(mem_arg(0, 2)));
                // value slot stays 0 (rt_array_new zeroes the spec).
            }
            DAE::Subscript::SLICE { exp } => {
                spec_elem_addr(ctx, spec_t, kind_slot)?;
                ctx.emit(we::Instruction::I32Const(2)); // SLICE
                ctx.emit(we::Instruction::I32Store(mem_arg(0, 2)));
                spec_elem_addr(ctx, spec_t, val_slot)?;
                let w = compile_exp(ctx, exp)?; // owned Integer index array
                if w != WTy::I32 {
                    return Err("CodegenWasmJit: array slice subscript is not an integer index array");
                }
                let s_t = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalTee(s_t));
                ctx.emit(we::Instruction::I32Store(mem_arg(0, 2)));
                slice_idx_temps.push(s_t);
            }
        }
    }
    Ok((spec_t, slice_idx_temps))
}

/// Given an owned source-array handle on top of the stack and a subscript list
/// that slices / partially indexes it (any `WHOLEDIM`/`SLICE`, or fewer
/// subscripts than the rank), build the per-axis spec and call `rt_array_slice`,
/// leaving a fresh (owned) lower-rank sub-array handle. The source array and any
/// `SLICE` index arrays are released. Returns `WTy::I32` (an array handle).
pub(super) fn slice_loaded(ctx: &mut FnCtx, subs: &List<Arc<DAE::Subscript>>) -> Result<WTy> {
    let subs: Vec<&Arc<DAE::Subscript>> = (&**subs).into_iter().collect();
    let nspec = subs.len() as u32;

    let arr_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(arr_t));
    let (spec_t, slice_idx_temps) = emit_slice_spec(ctx, &subs)?;

    // result = rt_array_slice(src, nspec, spec)
    ctx.emit(we::Instruction::LocalGet(arr_t));
    ctx.emit(we::Instruction::I32Const(nspec as i32));
    ctx.emit(we::Instruction::LocalGet(spec_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_slice")?));
    let result_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(result_t));

    // Release the borrowed source, the per-axis SLICE index arrays, and the spec.
    release_temp_array(ctx, arr_t)?;
    for s_t in slice_idx_temps {
        release_temp_array(ctx, s_t)?;
    }
    release_temp_array(ctx, spec_t)?;

    ctx.emit(we::Instruction::LocalGet(result_t));
    Ok(WTy::I32)
}

/// Slice assignment `a[i, :, lo:hi, …] := rhs`, written in place into the array
/// in `arr_idx` (which privately owns its buffer, as for element assignment).
/// The rhs is an array holding the selected positions in selection order;
/// `rt_array_indexed_assign` copies it in, so the rhs reference is released.
pub(super) fn compile_slice_assign(
    ctx: &mut FnCtx,
    arr_idx: u32,
    subs: &List<Arc<DAE::Subscript>>,
    rhs: RhsSource,
) -> Result<()> {
    let subs: Vec<&Arc<DAE::Subscript>> = (&**subs).into_iter().collect();
    let nspec = subs.len() as u32;
    let (spec_t, slice_idx_temps) = emit_slice_spec(ctx, &subs)?;

    let src_t = ctx.alloc_temp(WTy::I32);
    if rhs.push(ctx)? != WTy::I32 {
        return Err("CodegenWasmJit: slice assignment rhs is not an array");
    }
    ctx.emit(we::Instruction::LocalSet(src_t));

    ctx.emit(we::Instruction::LocalGet(arr_idx));
    ctx.emit(we::Instruction::I32Const(nspec as i32));
    ctx.emit(we::Instruction::LocalGet(spec_t));
    ctx.emit(we::Instruction::LocalGet(src_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_indexed_assign")?));

    release_temp_array(ctx, src_t)?;
    for s_t in slice_idx_temps {
        release_temp_array(ctx, s_t)?;
    }
    release_temp_array(ctx, spec_t)?;
    Ok(())
}

/// Release an owned array handle held in scratch local `t`.
pub(super) fn release_temp_array(ctx: &mut FnCtx, t: u32) -> Result<()> {
    ctx.emit(we::Instruction::LocalGet(t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_release")?));
    Ok(())
}

/// The wasm local and rank of a whole array local (not a model variable), which
/// a read can borrow: the local outlives the expression.
fn array_local(ctx: &FnCtx, e: &DAE::Exp) -> Option<(u32, u32)> {
    if ctx.sim.is_some() {
        return None;
    }
    let DAE::Exp::CREF { componentRef, .. } = e else { return None };
    let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = &**componentRef else { return None };
    if !subscriptLst.is_empty() {
        return None;
    }
    match ctx.locals.get(ident.as_str()) {
        Some((idx, SigTy::Array { rank, .. })) => Some((*idx, *rank)),
        _ => None,
    }
}

/// Lower `size(a, d)` (a single dimension size, scalar Integer) or `size(a)`
/// (the whole dimension vector, an `Integer[ndims]`). A local `a` is borrowed;
/// any other operand's owned handle is released after.
pub(super) fn compile_size(ctx: &mut FnCtx, exp: &DAE::Exp, sz: Option<&DAE::Exp>) -> Result<()> {
    let local = array_local(ctx, exp);
    // Only the whole-vector form needs the rank statically — as well, since the
    // frontend leaves a dimension expression's operand `T_UNKNOWN`.
    let rank = match (sz, local) {
        (Some(_), _) => 0,
        (None, Some((_, rank))) => rank,
        (None, None) => match exp_sigty(exp)? {
            SigTy::Array { rank, .. } => rank,
            _ => return Err("CodegenWasmJit: size() of a non-array expression"),
        },
    };
    let arr_t = match local {
        Some((idx, _)) => idx,
        None => {
            compile_exp(ctx, exp)?; // owned array handle
            let t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(t));
            t
        }
    };

    if let Some(d) = sz {
        // size(a, d): one dimension; a constant axis of a local is a header load.
        ctx.emit(we::Instruction::LocalGet(arr_t));
        match (local, const_index_value(d)) {
            (Some((_, rank)), Some(axis)) if axis >= 1 && axis as u32 <= rank => {
                ctx.emit(we::Instruction::I32Load(mem_arg(ARR_DIMS_OFF + 4 * (axis as u32 - 1), 2)));
            }
            _ => {
                let w = compile_exp(ctx, d)?;
                coerce(ctx, w, WTy::I32);
                ctx.emit(we::Instruction::Call(rt_index("rt_array_dim")?));
            }
        }
        if local.is_none() {
            release_temp_array(ctx, arr_t)?; // leaves the dim value
        }
        return Ok(());
    }

    // size(a): build a fresh Integer[rank] whose element i is size(a, i). The
    // result rank equals `a`'s number of dimensions, known statically.
    let res = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(SigTy::Int.elem_kind() as i32));
    ctx.emit(we::Instruction::I32Const(1)); // ndims of the result vector
    ctx.emit(we::Instruction::I32Const(rank as i32)); // total = number of axes
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")?));
    ctx.emit(we::Instruction::LocalSet(res));
    ctx.emit(we::Instruction::LocalGet(res));
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::I32Const(rank as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")?));
    for axis in 1..=rank {
        ctx.emit(we::Instruction::LocalGet(res));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")?));
        ctx.emit(we::Instruction::LocalGet(arr_t));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_dim")?));
        elem_store(ctx, &SigTy::Int);
    }
    if local.is_none() {
        release_temp_array(ctx, arr_t)?;
    }
    ctx.emit(we::Instruction::LocalGet(res));
    Ok(())
}

/// The scalar element type of an array-typed expression, or `None` if it is not
/// an array (so an overloaded builtin can fall through to its scalar form).
fn array_elem(e: &DAE::Exp) -> Result<Option<Arc<SigTy>>> {
    Ok(match exp_sigty(e)? {
        SigTy::Array { elem, .. } => Some(elem),
        _ => None,
    })
}

/// Lower the array builtins. Returns `Some(result type)` if `name` is one of
/// them (with the right argument shape), else `None` so the scalar math handler
/// runs. Numeric only (Integer/Boolean/Real elements); a heap-element array
/// (e.g. `sum` of a `String[]`, which is not valid Modelica anyway) is rejected
/// by the runtime dispatch picking an i32/f64 path.
pub(super) fn compile_array_builtin(
    ctx: &mut FnCtx,
    name: &str,
    argv: &[&Arc<DAE::Exp>],
    attr: &DAE::CallAttributes,
) -> Result<Option<SigTy>> {
    match name {
        // fill(s, d1, ..., dk): array of the given dims, every element = s.
        "fill" => {
            if argv.len() < 2 {
                return Err("CodegenWasmJit: fill expects a value and at least one dimension");
            }
            let arr_ty = sig_ty(&attr.ty)?;
            let SigTy::Array { elem, .. } = &arr_ty else {
                return Err("CodegenWasmJit: fill result is not an array");
            };
            let obj = emit_alloc_from_exprs(ctx, elem, &argv[1..])?;
            emit_fill_value(ctx, obj, elem, argv[0])?;
            ctx.emit(we::Instruction::LocalGet(obj));
            Ok(Some(arr_ty))
        }
        // zeros(d...) / ones(d...): like fill with a constant 0 / 1.
        "zeros" | "ones" => {
            if argv.is_empty() {
                return Err("CodegenWasmJit: expects at least one dimension");
            }
            let arr_ty = sig_ty(&attr.ty)?;
            let SigTy::Array { elem, .. } = &arr_ty else {
                return Err("CodegenWasmJit: result is not an array");
            };
            let obj = emit_alloc_from_exprs(ctx, elem, argv)?;
            emit_fill_const(ctx, obj, elem, if name == "ones" { 1 } else { 0 })?;
            ctx.emit(we::Instruction::LocalGet(obj));
            Ok(Some(arr_ty))
        }
        // sum(a) / product(a) over all elements -> scalar of the element type.
        "sum" | "product" if argv.len() == 1 => match array_elem(argv[0])? {
            None => Ok(None),
            Some(elem) => {
                let rt = match (name, elem.wty()) {
                    ("sum", WTy::F64) => "rt_array_sum_f64",
                    ("sum", WTy::I32) => "rt_array_sum_i32",
                    (_, WTy::F64) => "rt_array_product_f64",
                    (_, WTy::I32) => "rt_array_product_i32",
                };
                emit_array_reduce(ctx, argv[0], rt, None)?;
                Ok(Some((*elem).clone()))
            }
        },
        // min(a) / max(a) of a single array (the two-argument forms are scalar
        // and handled by the math builtins).
        "min" | "max" if argv.len() == 1 => match array_elem(argv[0])? {
            None => Ok(None),
            Some(elem) => {
                let rt = if elem.wty() == WTy::F64 { "rt_array_extreme_f64" } else { "rt_array_extreme_i32" };
                emit_array_reduce(ctx, argv[0], rt, Some(if name == "max" { 1 } else { 0 }))?;
                Ok(Some((*elem).clone()))
            }
        },
        // identity(n): n×n Integer identity matrix.
        "identity" if argv.len() == 1 => {
            let w = compile_exp(ctx, argv[0])?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::Call(rt_index("rt_array_identity")?));
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // diagonal(v): n×n matrix with the vector v on the diagonal.
        "diagonal" if argv.len() == 1 => {
            if array_elem(argv[0])?.is_none() {
                return Err("CodegenWasmJit: diagonal of a non-array expression");
            }
            compile_exp(ctx, argv[0])?;
            let vt = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(vt));
            ctx.emit(we::Instruction::LocalGet(vt));
            ctx.emit(we::Instruction::Call(rt_index("rt_array_diagonal")?));
            release_temp_array(ctx, vt)?;
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // linspace(x1, x2, n): n evenly-spaced Reals from x1 to x2.
        "linspace" if argv.len() == 3 => {
            let w = compile_exp(ctx, argv[0])?;
            coerce(ctx, w, WTy::F64);
            let w = compile_exp(ctx, argv[1])?;
            coerce(ctx, w, WTy::F64);
            let w = compile_exp(ctx, argv[2])?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::Call(rt_index("rt_array_linspace")?));
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // transpose(a): a fresh n×m array (the operand 2-D array is released).
        "transpose" if argv.len() == 1 => {
            if array_elem(argv[0])?.is_none() {
                return Err("CodegenWasmJit: transpose of a non-array expression");
            }
            compile_exp(ctx, argv[0])?;
            let at = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(at));
            ctx.emit(we::Instruction::LocalGet(at));
            ctx.emit(we::Instruction::Call(rt_index("rt_array_transpose")?));
            release_temp_array(ctx, at)?;
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // cat(dim, a1, ..., an): concatenate arrays along dimension `dim` into a
        // fresh array. The inputs are passed to the runtime as an Integer array
        // of handles; both the handle array and the inputs are released after.
        "cat" if argv.len() >= 2 => {
            let n = (argv.len() - 1) as u32;
            let dim_t = ctx.alloc_temp(WTy::I32);
            let w = compile_exp(ctx, argv[0])?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::LocalSet(dim_t));
            // Integer[n] array of the input handles.
            let handles_t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::I32Const(0)); // EK_INT
            ctx.emit(we::Instruction::I32Const(1)); // ndims
            ctx.emit(we::Instruction::I32Const(n as i32)); // total
            ctx.emit(we::Instruction::Call(rt_index("rt_array_new")?));
            ctx.emit(we::Instruction::LocalSet(handles_t));
            let mut in_temps = Vec::with_capacity(n as usize);
            for (i, a) in argv[1..].iter().enumerate() {
                if array_elem(a)?.is_none() {
                    return Err("CodegenWasmJit: cat argument is not an array");
                }
                ctx.emit(we::Instruction::LocalGet(handles_t));
                ctx.emit(we::Instruction::I32Const(i as i32 + 1));
                ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")?));
                compile_exp(ctx, a)?; // owned input array handle
                let t = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalTee(t));
                ctx.emit(we::Instruction::I32Store(mem_arg(0, 2)));
                in_temps.push(t);
            }
            ctx.emit(we::Instruction::LocalGet(dim_t));
            ctx.emit(we::Instruction::I32Const(n as i32));
            ctx.emit(we::Instruction::LocalGet(handles_t));
            ctx.emit(we::Instruction::Call(rt_index("rt_array_cat")?));
            let result_t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(result_t));
            for t in in_temps {
                release_temp_array(ctx, t)?;
            }
            release_temp_array(ctx, handles_t)?;
            ctx.emit(we::Instruction::LocalGet(result_t));
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // ndims(a) -> Integer.
        "ndims" if argv.len() == 1 => {
            if array_elem(argv[0])?.is_none() {
                return Err("CodegenWasmJit: ndims of a non-array expression");
            }
            emit_array_reduce(ctx, argv[0], "rt_array_ndims", None)?;
            Ok(Some(SigTy::Int))
        }
        // scalar(a): the single element of an array whose dimensions are all 1.
        "scalar" if argv.len() == 1 => {
            let elem = array_elem(argv[0])?
                .ok_or_else(|| "CodegenWasmJit: scalar() of a non-array expression")?;
            compile_exp(ctx, argv[0])?; // owned array
            let arr_t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(arr_t));
            ctx.emit(we::Instruction::LocalGet(arr_t));
            ctx.emit(we::Instruction::I32Const(1));
            emit_elem_ptr(ctx, &elem)?;
            elem_load(ctx, &elem);
            if elem.is_heap() {
                // Retain the borrowed handle so it outlives the array release.
                let v = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalSet(v));
                ctx.emit(we::Instruction::LocalGet(v));
                ctx.emit(we::Instruction::Call(rt_index("rt_retain")?));
                release_temp_array(ctx, arr_t)?;
                ctx.emit(we::Instruction::LocalGet(v));
            } else {
                release_temp_array(ctx, arr_t)?;
            }
            Ok(Some((*elem).clone()))
        }
        // vector(a) / matrix(a): reshape to rank 1 / rank 2; symmetric(a):
        // mirror the upper triangle into the lower. Element-kind generic.
        "vector" if argv.len() == 1 => {
            emit_unary_array(ctx, argv[0], "rt_array_vector")?;
            Ok(Some(sig_ty(&attr.ty)?))
        }
        "matrix" if argv.len() == 1 => {
            emit_unary_array(ctx, argv[0], "rt_array_matrix")?;
            Ok(Some(sig_ty(&attr.ty)?))
        }
        "symmetric" if argv.len() == 1 => {
            emit_unary_array(ctx, argv[0], "rt_array_symmetric")?;
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // cross(a,b): Real 3-vector cross product. skew(x): 3x3 skew matrix.
        "cross" if argv.len() == 2 => {
            emit_binary_array(ctx, argv[0], argv[1], "rt_array_cross_f64")?;
            Ok(Some(sig_ty(&attr.ty)?))
        }
        "skew" if argv.len() == 1 => {
            emit_unary_array(ctx, argv[0], "rt_array_skew_f64")?;
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // outerProduct(a,b): r[i,j] = a[i]*b[j]. Always Real (the operands are
        // promoted to Real by the frontend, like `cross`).
        "outerProduct" if argv.len() == 2 => {
            emit_binary_array(ctx, argv[0], argv[1], "rt_array_outer_f64")?;
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // promote(a, n): add trailing size-1 dimensions to reach rank `n`.
        "promote" if argv.len() == 2 => {
            if array_elem(argv[0])?.is_none() {
                return Err("CodegenWasmJit: promote of a non-array expression");
            }
            compile_exp(ctx, argv[0])?;
            let at = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(at));
            ctx.emit(we::Instruction::LocalGet(at));
            let w = compile_exp(ctx, argv[1])?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::Call(rt_index("rt_array_promote")?));
            let res_t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(res_t));
            release_temp_array(ctx, at)?;
            ctx.emit(we::Instruction::LocalGet(res_t));
            Ok(Some(sig_ty(&attr.ty)?))
        }
        _ => Ok(None),
    }
}

/// Lower a one-array-argument runtime builtin: evaluate the operand, call `rt`
/// (which returns a fresh array handle), then release the operand. Leaves the
/// result handle on the stack.
pub(super) fn emit_unary_array(ctx: &mut FnCtx, arg: &DAE::Exp, rt: &str) -> Result<()> {
    if array_elem(arg)?.is_none() {
        return Err("CodegenWasmJit: of a non-array expression");
    }
    compile_exp(ctx, arg)?;
    let at = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(at));
    ctx.emit(we::Instruction::LocalGet(at));
    ctx.emit(we::Instruction::Call(rt_index(rt)?));
    release_temp_array(ctx, at)?;
    Ok(())
}

/// Lower a two-array-argument runtime builtin: evaluate both operands, call
/// `rt`, then release both operands. Leaves the result handle on the stack.
fn emit_binary_array(ctx: &mut FnCtx, e1: &DAE::Exp, e2: &DAE::Exp, rt: &str) -> Result<()> {
    compile_exp(ctx, e1)?;
    let at = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(at));
    compile_exp(ctx, e2)?;
    let bt = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(bt));
    ctx.emit(we::Instruction::LocalGet(at));
    ctx.emit(we::Instruction::LocalGet(bt));
    ctx.emit(we::Instruction::Call(rt_index(rt)?));
    release_temp_array(ctx, at)?;
    release_temp_array(ctx, bt)?;
    Ok(())
}

/// Allocate a fresh array of element type `elem` whose dimensions are the given
/// expressions (evaluated at runtime). Returns the scratch local holding the
/// owned array handle.
fn emit_alloc_from_exprs(ctx: &mut FnCtx, elem: &SigTy, dim_exprs: &[&Arc<DAE::Exp>]) -> Result<u32> {
    let rank = dim_exprs.len() as u32;
    let mut dim_temps = Vec::with_capacity(dim_exprs.len());
    for de in dim_exprs {
        let t = ctx.alloc_temp(WTy::I32);
        let w = compile_exp(ctx, de)?;
        coerce(ctx, w, WTy::I32);
        ctx.emit(we::Instruction::LocalSet(t));
        dim_temps.push(t);
    }
    ctx.emit(we::Instruction::LocalGet(dim_temps[0]));
    for t in &dim_temps[1..] {
        ctx.emit(we::Instruction::LocalGet(*t));
        ctx.emit(we::Instruction::I32Mul);
    }
    let total_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(total_t));
    let obj = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(elem.elem_kind() as i32));
    ctx.emit(we::Instruction::I32Const(rank as i32));
    ctx.emit(we::Instruction::LocalGet(total_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")?));
    ctx.emit(we::Instruction::LocalSet(obj));
    for (axis, t) in dim_temps.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::LocalGet(*t));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")?));
    }
    Ok(obj)
}

/// Fill every element of array `obj` with the value of `val` (the `fill` value).
fn emit_fill_value(ctx: &mut FnCtx, obj: u32, elem: &SigTy, val: &DAE::Exp) -> Result<()> {
    ctx.emit(we::Instruction::LocalGet(obj));
    let w = compile_exp(ctx, val)?;
    coerce(ctx, w, elem.wty());
    ctx.emit(we::Instruction::Call(rt_index(fill_fn(elem))?));
    Ok(())
}

/// Fill every element of array `obj` with the integer constant `k` (for
/// `zeros`/`ones`), converted to the element's wasm type.
fn emit_fill_const(ctx: &mut FnCtx, obj: u32, elem: &SigTy, k: i32) -> Result<()> {
    ctx.emit(we::Instruction::LocalGet(obj));
    match elem.wty() {
        WTy::I32 => ctx.emit(we::Instruction::I32Const(k)),
        WTy::F64 => ctx.emit(we::Instruction::F64Const((k as f64).into())),
    }
    ctx.emit(we::Instruction::Call(rt_index(fill_fn(elem))?));
    Ok(())
}

fn fill_fn(elem: &SigTy) -> &'static str {
    match elem.wty() {
        WTy::F64 => "rt_array_fill_f64",
        WTy::I32 => "rt_array_fill_i32",
    }
}

/// Reduce an array to a scalar via runtime function `rt_fn` (optionally with an
/// extra `i32` argument, e.g. the min/max selector). The array operand is owned
/// (released after); the scalar result is left on the stack.
fn emit_array_reduce(ctx: &mut FnCtx, arr: &DAE::Exp, rt_fn: &str, extra: Option<i32>) -> Result<()> {
    compile_exp(ctx, arr)?; // owned array handle
    let a_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(a_t));
    ctx.emit(we::Instruction::LocalGet(a_t));
    if let Some(k) = extra {
        ctx.emit(we::Instruction::I32Const(k));
    }
    ctx.emit(we::Instruction::Call(rt_index(rt_fn)?));
    release_temp_array(ctx, a_t)?; // leaves the scalar result
    Ok(())
}

pub(super) fn unary_f64(ctx: &mut FnCtx, argv: &[&Arc<DAE::Exp>], instr: we::Instruction<'static>) -> Result<()> {
    need_args(argv, 1, "<f64 builtin>")?;
    let w = compile_exp(ctx, argv[0])?;
    coerce(ctx, w, WTy::F64);
    ctx.emit(instr);
    Ok(())
}

pub(super) fn need_args(argv: &[&Arc<DAE::Exp>], n: usize, name: &str) -> Result<()> {
    if argv.len() != n {
        return Err("CodegenWasmJit: builtin argument count mismatch");
    }
    Ok(())
}

/// Emit a numeric conversion if the value on the stack is not already the
/// wanted type. Integer/Boolean both live in `i32`, so I32<->I32 is a no-op.
pub(super) fn coerce(ctx: &mut FnCtx, from: WTy, to: WTy) {
    match (from, to) {
        (WTy::I32, WTy::F64) => ctx.emit(we::Instruction::F64ConvertI32S),
        // Saturating (non-trapping): a transient NaN/out-of-range value from an NLS
        // probe must not trap the module.
        (WTy::F64, WTy::I32) => ctx.emit(we::Instruction::I32TruncSatF64S),
        _ => {}
    }
}
