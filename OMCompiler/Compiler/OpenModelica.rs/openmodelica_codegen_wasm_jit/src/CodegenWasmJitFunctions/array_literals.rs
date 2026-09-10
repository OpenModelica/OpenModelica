//! Array objects: element addressing, literals, constant runs, ranges.

use super::*;

/// Inline what `rt_array_elem_ptr` computes: the byte address of the element at
/// row-major linear position `index` (1-based), with the same out-of-range arm.
/// Stack is `[obj, index] -> [addr]`.
///
/// Inlined rather than called because element access is the hottest operation in
/// generated model code (an IF97 property evaluation does hundreds) and the
/// cross-module call dominated the per-evaluation cost. The stride follows the
/// element's wasm type, which the load/store that follows already assumes.
pub(super) fn emit_elem_ptr(ctx: &mut FnCtx, elem: &SigTy) -> Result<()> {
    use we::Instruction as I;
    let (ot, it) = ctx.elem_ptr_temps();
    let shift = match elem.wty() {
        WTy::F64 => 3,
        WTy::I32 => 2,
    };
    ctx.emit(I::LocalSet(it));
    ctx.emit(I::LocalSet(ot));
    ctx.emit(I::Block(we::BlockType::Result(we::ValType::I32)));
    // index < 1 || index > total -> the runtime's out-of-range arm.
    ctx.emit(I::LocalGet(it));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32LtS);
    ctx.emit(I::LocalGet(it));
    ctx.emit(I::LocalGet(ot));
    ctx.emit(I::I32Load(mem_arg(ARR_TOTAL_OFF, 2)));
    ctx.emit(I::I32GtS);
    ctx.emit(I::I32Or);
    ctx.emit(I::If(we::BlockType::Empty));
    ctx.emit(I::LocalGet(ot));
    ctx.emit(I::LocalGet(it));
    ctx.emit(I::Call(rt_index("rt_elem_ptr_oob")?));
    ctx.emit(I::Br(1));
    ctx.emit(I::End);
    // obj + align8(ARR_DIMS_OFF + ndims*4) + (index - 1) * stride
    ctx.emit(I::LocalGet(ot));
    ctx.emit(I::LocalGet(ot));
    ctx.emit(I::I32Load(mem_arg(ARR_NDIMS_OFF, 2)));
    ctx.emit(I::I32Const(2));
    ctx.emit(I::I32Shl);
    ctx.emit(I::I32Const(ARR_DIMS_OFF as i32 + 7));
    ctx.emit(I::I32Add);
    ctx.emit(I::I32Const(-8));
    ctx.emit(I::I32And);
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalGet(it));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Sub);
    ctx.emit(I::I32Const(shift));
    ctx.emit(I::I32Shl);
    ctx.emit(I::I32Add);
    ctx.emit(I::End);
    Ok(())
}

/// Inline `rt_array_dim` for a constant 1-based `axis`. Stack `[obj] -> [size]`.
pub(super) fn emit_array_dim(ctx: &mut FnCtx, axis: u32) -> Result<()> {
    if axis == 0 {
        return Err("CodegenWasmJit: array dimension axis is 1-based");
    }
    ctx.emit(we::Instruction::I32Load(mem_arg(ARR_DIMS_OFF + (axis - 1) * 4, 2)));
    Ok(())
}

/// Load one array element from the byte address on top of the stack, leaving its
/// value. The wasm load instruction (and natural alignment) follow the element
/// type.
pub(super) fn elem_load(ctx: &mut FnCtx, elem: &SigTy) {
    match elem.wty() {
        WTy::I32 => ctx.emit(we::Instruction::I32Load(we::MemArg { offset: 0, align: 2, memory_index: 0 })),
        WTy::F64 => ctx.emit(we::Instruction::F64Load(we::MemArg { offset: 0, align: 3, memory_index: 0 })),
    }
}

/// Store an array element: stack is `[addr, value]`.
pub(super) fn elem_store(ctx: &mut FnCtx, elem: &SigTy) {
    elem_store_off(ctx, elem, 0)
}

/// Store an array element at a constant byte `offset` from the address on the
/// stack: `[base, value]`.
fn elem_store_off(ctx: &mut FnCtx, elem: &SigTy, offset: u32) {
    match elem.wty() {
        WTy::I32 => ctx.emit(we::Instruction::I32Store(mem_arg(offset, 2))),
        WTy::F64 => ctx.emit(we::Instruction::F64Store(mem_arg(offset, 3))),
    }
}

/// Byte offset of the first element of an array object of known rank — the
/// runtime's `arr_data_off`. Constant here, so a construction's element address
/// is a plain offset off the object rather than the descriptor arithmetic (and
/// bounds check) [`emit_elem_ptr`] needs for a run-time index.
fn arr_data_off(rank: u32) -> u32 {
    (ARR_DIMS_OFF + rank * 4).next_multiple_of(8)
}

/// Byte size of one array element.
fn elem_stride(elem: &SigTy) -> u32 {
    match elem.wty() {
        WTy::F64 => 8,
        WTy::I32 => 4,
    }
}

/// A compile-time-constant numeric scalar, as the element bytes it occupies in an
/// array of element type `elem` — `None` when the expression is not such a
/// constant. Integer/Boolean/enumeration constants widen to `f64` in a `Real`
/// array, matching the [`coerce`] the element-wise path emits.
fn const_elem_bytes(e: &DAE::Exp, elem: &SigTy) -> Option<Vec<u8>> {
    match (const_num(e)?, elem.wty()) {
        (ConstNum::R(r), WTy::F64) => Some(r.to_le_bytes().to_vec()),
        (ConstNum::I(i), WTy::F64) => Some((i as f64).to_le_bytes().to_vec()),
        (ConstNum::I(i), WTy::I32) => Some(i.to_le_bytes().to_vec()),
        (ConstNum::R(_), WTy::I32) => None,
    }
}

pub(super) enum ConstNum {
    I(i32),
    R(f64),
}

/// The value of a compile-time-constant numeric/Boolean/enumeration expression.
pub(super) fn const_num(e: &DAE::Exp) -> Option<ConstNum> {
    use DAE::Exp as E;
    match e {
        E::ICONST { integer } => Some(ConstNum::I(*integer)),
        E::BCONST { bool } => Some(ConstNum::I(*bool as i32)),
        E::ENUM_LITERAL { index, .. } => Some(ConstNum::I(*index)),
        E::RCONST { real } => Some(ConstNum::R(real.into_inner())),
        E::SHARED_LITERAL { exp, .. } | E::CAST { exp, .. } => const_num(exp),
        E::UNARY { operator, exp } => match (operator, const_num(exp)?) {
            (DAE::Operator::UMINUS { .. }, ConstNum::I(i)) => Some(ConstNum::I(i.wrapping_neg())),
            (DAE::Operator::UMINUS { .. }, ConstNum::R(r)) => Some(ConstNum::R(-r)),
            _ => None,
        },
        _ => None,
    }
}

/// Materialize a run of constant elements collected by [`compile_array_literal`]
/// into the array object at `dest_off`. A run long enough to pay for the sequence
/// is copied from a passive data segment with `memory.init`, so a large constant
/// table costs a fixed handful of instructions rather than a store per element.
fn emit_const_run(
    ctx: &mut FnCtx,
    obj: u32,
    dest_off: u32,
    elem: &SigTy,
    run: &mut Vec<u8>,
) -> Result<()> {
    use we::Instruction as I;
    let bytes = core::mem::take(run);
    if bytes.is_empty() {
        return Ok(());
    }
    let stride = elem_stride(elem);
    if bytes.len() as u32 / stride < 4 {
        for (i, chunk) in bytes.chunks_exact(stride as usize).enumerate() {
            ctx.emit(I::LocalGet(obj));
            match elem.wty() {
                WTy::F64 => {
                    let v = f64::from_le_bytes(chunk.try_into().map_err(|_| "CodegenWasmJit: bad literal run")?);
                    ctx.emit(I::F64Const(v.into()));
                }
                WTy::I32 => {
                    let v = i32::from_le_bytes(chunk.try_into().map_err(|_| "CodegenWasmJit: bad literal run")?);
                    ctx.emit(I::I32Const(v));
                }
            }
            elem_store_off(ctx, elem, dest_off + i as u32 * stride);
        }
        return Ok(());
    }
    let len = bytes.len() as u32;
    // Nothing emits `data.drop`, so a table shared by several equation functions
    // stays readable.
    let off = ctx.literals.intern(&bytes);
    ctx.emit(I::LocalGet(obj));
    ctx.emit(I::I32Const(dest_off as i32));
    ctx.emit(I::I32Add);
    ctx.emit(I::I32Const(off as i32));
    ctx.emit(I::I32Const(len as i32));
    ctx.emit(I::MemoryInit { mem: 0, data_index: 0 });
    Ok(())
}

/// [`const_dims`] keeping the non-constant dimensions.
pub(super) fn type_dims(ty: &DAE::Type) -> Vec<Arc<DAE::Dimension>> {
    let DAE::Type::T_ARRAY { ty: elem, dims } = ty else {
        return Vec::new();
    };
    let mut out: Vec<Arc<DAE::Dimension>> = (&**dims).into_iter().cloned().collect();
    out.extend(type_dims(elem));
    out
}

/// [`leaf_array_count`] without needing the size.
fn leaf_is_array(exp: &DAE::Exp) -> bool {
    matches!(exp_dae_type(exp).as_deref(), Some(DAE::Type::T_ARRAY { .. }))
}

/// [`compile_array_literal`] for sizes only known at run time (`Real m[2, n]`
/// with `n` a parameter): allocate from the evaluated dimensions and fill
/// through a running element index, a sub-array leaf's length being dynamic too.
fn compile_array_literal_dynamic(
    ctx: &mut FnCtx,
    ty: &DAE::Type,
    elem: &SigTy,
    rank: u32,
    whole: &DAE::Exp,
) -> Result<()> {
    use we::Instruction as I;
    let dims = type_dims(ty);
    if dims.len() as u32 != rank {
        return Err("CodegenWasmJit: array constructor rank does not match dimensions");
    }
    // `emit_dim_value` makes an unknown (`:`) axis 0; fail rather than mis-size.
    if dims.iter().any(|d| matches!(&**d, DAE::Dimension::DIM_UNKNOWN)) {
        return Err("CodegenWasmJit: array construction needs constant dimensions");
    }
    let mut dim_temps = Vec::with_capacity(dims.len());
    for d in &dims {
        let t = ctx.alloc_temp(WTy::I32);
        emit_dim_value(ctx, d)?;
        ctx.emit(I::LocalSet(t));
        dim_temps.push(t);
    }
    ctx.emit(I::LocalGet(dim_temps[0]));
    for t in &dim_temps[1..] {
        ctx.emit(I::LocalGet(*t));
        ctx.emit(I::I32Mul);
    }
    let total = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::LocalSet(total));
    let obj = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::I32Const(elem.elem_kind() as i32));
    ctx.emit(I::I32Const(rank as i32));
    ctx.emit(I::LocalGet(total));
    ctx.emit(I::Call(rt_index("rt_array_new")?));
    ctx.emit(I::LocalSet(obj));
    for (axis, t) in dim_temps.iter().enumerate() {
        ctx.emit(I::LocalGet(obj));
        ctx.emit(I::I32Const(axis as i32));
        ctx.emit(I::LocalGet(*t));
        ctx.emit(I::Call(rt_index("rt_array_set_dim")?));
    }
    let mut leaves = Vec::new();
    flatten_array_exp(whole, &mut leaves);
    let k = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::I32Const(0));
    ctx.emit(I::LocalSet(k));
    let data_off = arr_data_off(rank);
    let stride = elem_stride(elem);
    for leaf in &leaves {
        if leaf_is_array(leaf) {
            let h = ctx.alloc_temp(WTy::I32);
            compile_exp(ctx, leaf)?;
            ctx.emit(I::LocalSet(h));
            ctx.emit(I::LocalGet(obj));
            ctx.emit(I::LocalGet(k));
            ctx.emit(I::LocalGet(h));
            ctx.emit(I::Call(rt_index("rt_array_blit")?));
            ctx.emit(I::LocalGet(k));
            ctx.emit(I::LocalGet(h));
            ctx.emit(I::I32Load(mem_arg(ARR_TOTAL_OFF, 2)));
            ctx.emit(I::I32Add);
            ctx.emit(I::LocalSet(k));
            ctx.emit(I::LocalGet(h));
            ctx.emit(I::Call(rt_index("rt_array_release")?));
        } else {
            ctx.emit(I::LocalGet(obj));
            ctx.emit(I::LocalGet(k));
            ctx.emit(I::I32Const(stride as i32));
            ctx.emit(I::I32Mul);
            ctx.emit(I::I32Add);
            let w = compile_exp(ctx, leaf)?;
            coerce(ctx, w, elem.wty());
            elem_store_off(ctx, elem, data_off);
            ctx.emit(I::LocalGet(k));
            ctx.emit(I::I32Const(1));
            ctx.emit(I::I32Add);
            ctx.emit(I::LocalSet(k));
        }
    }
    ctx.emit(I::LocalGet(obj));
    Ok(())
}

/// The per-axis sizes of a constructor taken from its own shape, for a declared
/// type that has none (`Real t[:] = {...}`). Mirrors [`flatten_array_exp`]; the
/// first element supplies the axes below the node's own.
fn constructor_dims(exp: &DAE::Exp) -> Result<Vec<u32>> {
    use DAE::Exp as E;
    match exp {
        E::SHARED_LITERAL { exp, .. } => constructor_dims(exp),
        E::ARRAY { array, .. } => {
            let mut out = vec![(&**array).into_iter().count() as u32];
            if let Some(first) = (&**array).into_iter().next() {
                out.extend(constructor_dims(first)?);
            }
            Ok(out)
        }
        E::MATRIX { matrix, .. } => {
            let rows: Vec<_> = (&**matrix).into_iter().collect();
            let mut out = vec![rows.len() as u32, rows.first().map_or(0, |r| (&***r).into_iter().count()) as u32];
            if let Some(first) = rows.first().and_then(|r| (&***r).into_iter().next()) {
                out.extend(constructor_dims(first)?);
            }
            Ok(out)
        }
        other => match exp_dae_type(other) {
            Some(ty) => const_dims(&ty),
            None => Ok(Vec::new()),
        },
    }
}

/// The constant per-axis sizes of an array `DAE.Type`, flattening nested
/// `T_ARRAY`s (a rectangular array may be one `T_ARRAY` with several `dims` or a
/// nest of `T_ARRAY`s). Fails on a non-constant dimension (`:` / expression),
/// for which the constructor's own shape ([`constructor_dims`]) decides.
pub(super) fn const_dims(ty: &DAE::Type) -> Result<Vec<u32>> {
    let DAE::Type::T_ARRAY { ty: elem, dims } = ty else {
        return Ok(Vec::new());
    };
    let mut out = Vec::new();
    for d in &**dims {
        match &**d {
            DAE::Dimension::DIM_INTEGER { integer } if *integer >= 0 => out.push(*integer as u32),
            other => return Err("CodegenWasmJit: array construction needs constant dimensions"),
        }
    }
    out.extend(const_dims(elem)?);
    Ok(out)
}

/// Collect the scalar leaf expressions of a (possibly nested) array constructor
/// in row-major order. `ARRAY`/`MATRIX` nodes are the structure; anything else
/// is a leaf element.
fn flatten_array_exp<'a>(exp: &'a DAE::Exp, out: &mut Vec<&'a DAE::Exp>) {
    use DAE::Exp as E;
    match exp {
        E::ARRAY { array, .. } => {
            for e in &**array {
                flatten_array_exp(e, out);
            }
        }
        E::MATRIX { matrix, .. } => {
            for row in &**matrix {
                for e in &**row {
                    flatten_array_exp(e, out);
                }
            }
        }
        E::SHARED_LITERAL { exp, .. } => flatten_array_exp(exp, out),
        other => out.push(other),
    }
}

/// Lower an array constructor (`{...}`, possibly nested for a matrix) of the
/// given declared `ty`, leaving an owned (+1) array handle on the stack. Builds
/// the flat row-major runtime object and stores every scalar leaf; an owned heap
/// element's reference transfers into the array (released by `rt_array_release`).
pub(super) fn compile_array_literal(ctx: &mut FnCtx, ty: &DAE::Type, whole: &DAE::Exp) -> Result<()> {
    let SigTy::Array { elem, rank } = sig_ty(ty)? else {
        return Err("CodegenWasmJit: array constructor with non-array type");
    };
    // The top-level structure (`ARRAY`/`MATRIX` nodes) is flattened to its
    // outermost element expressions. Each is either a scalar (one element) or an
    // array-valued expression (a sub-array, e.g. `{v, w}` of vectors) whose
    // elements are blitted in. (Scalar leaves remain the common case.)
    let mut leaves = Vec::new();
    flatten_array_exp(whole, &mut leaves);
    // Static placement needs the axis sizes and every sub-array leaf's length as
    // constants; a parameter-sized axis is only known once parameters have run.
    let dims = match const_dims(ty).or_else(|_| constructor_dims(whole)) {
        Ok(d) if d.len() as u32 == rank && leaves.iter().all(|l| leaf_array_count(l).is_ok()) => d,
        _ => return compile_array_literal_dynamic(ctx, ty, &elem, rank, whole),
    };
    let total: u32 = dims.iter().product();

    // obj = rt_array_new(elem_kind, rank, total); set each dimension size.
    let obj = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(elem.elem_kind() as i32));
    ctx.emit(we::Instruction::I32Const(rank as i32));
    ctx.emit(we::Instruction::I32Const(total as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")?));
    ctx.emit(we::Instruction::LocalSet(obj));
    for (axis, d) in dims.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::I32Const(*d as i32));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")?));
    }
    // Store each leaf at its row-major position. A scalar leaf occupies one
    // element; an array-valued leaf contributes its whole (row-major) contents.
    // The position is known here, so the element address is `obj` plus a constant
    // offset — no descriptor arithmetic, no bounds check. Consecutive constant
    // elements accumulate into `run` and go out as a data segment.
    let data_off = arr_data_off(rank);
    let stride = elem_stride(&elem);
    let mut run: Vec<u8> = Vec::new();
    let mut run_start: u32 = 0;
    let mut k: u32 = 0; // running 0-based element index
    for leaf in &leaves {
        let count = leaf_array_count(leaf)?;
        if count.is_none() {
            if let Some(bytes) = const_elem_bytes(leaf, &elem) {
                if run.is_empty() {
                    run_start = k;
                }
                run.extend_from_slice(&bytes);
                k += 1;
                continue;
            }
        }
        emit_const_run(ctx, obj, data_off + run_start * stride, &elem, &mut run)?;
        match count {
            None => {
                // Scalar element.
                ctx.emit(we::Instruction::LocalGet(obj));
                let w = compile_exp(ctx, leaf)?;
                coerce(ctx, w, elem.wty());
                elem_store_off(ctx, &elem, data_off + k * stride);
                k += 1;
            }
            Some(n) => {
                // Array-valued element: evaluate to an owned handle, blit its
                // elements into the result at the running offset, then release it.
                let h = ctx.alloc_temp(WTy::I32);
                compile_exp(ctx, leaf)?;
                ctx.emit(we::Instruction::LocalSet(h));
                ctx.emit(we::Instruction::LocalGet(obj));
                ctx.emit(we::Instruction::I32Const(k as i32));
                ctx.emit(we::Instruction::LocalGet(h));
                ctx.emit(we::Instruction::Call(rt_index("rt_array_blit")?));
                ctx.emit(we::Instruction::LocalGet(h));
                ctx.emit(we::Instruction::Call(rt_index("rt_array_release")?));
                k += n;
            }
        }
    }
    emit_const_run(ctx, obj, data_off + run_start * stride, &elem, &mut run)?;
    if k != total {
        return Err("CodegenWasmJit: array constructor element/type count mismatch");
    }
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(())
}

/// The number of scalar elements an array constructor *leaf* contributes:
/// `None` for a scalar leaf, `Some(n)` for an array-valued leaf (a sub-array of
/// `n` elements, from its constant dimensions). Fails if the leaf is an array of
/// non-constant size (the dynamic case is not handled in a constructor).
fn leaf_array_count(exp: &DAE::Exp) -> Result<Option<u32>> {
    match exp_dae_type(exp) {
        Some(ty) if matches!(&*ty, DAE::Type::T_ARRAY { .. }) => {
            Ok(Some(const_dims(&ty)?.iter().product()))
        }
        _ => Ok(None),
    }
}

/// The DAE type an expression carries, for the cases that can appear as an
/// array-constructor leaf. `None` when no type annotation is readily available
/// (treated as a scalar leaf by [`leaf_array_count`]).
fn exp_dae_type(exp: &DAE::Exp) -> Option<Arc<DAE::Type>> {
    use DAE::Exp as E;
    match exp {
        E::CREF { ty, .. } | E::CAST { ty, .. } | E::ARRAY { ty, .. } | E::MATRIX { ty, .. } | E::RANGE { ty, .. } => {
            Some(ty.clone())
        }
        E::CALL { attr, .. } => Some(attr.ty.clone()),
        // The whole array type for an `array(...)` comprehension, the scalar
        // accumulator type for a fold (see `compile_reduction`).
        E::REDUCTION { reductionInfo, .. } => Some(reductionInfo.exprType.clone()),
        E::SHARED_LITERAL { exp, .. } => exp_dae_type(exp),
        E::BINARY { operator, .. } | E::UNARY { operator, .. } => operator_dae_type(operator),
        _ => None,
    }
}

/// The result DAE type carried by an arithmetic operator (for the array-valued
/// operators that can appear as a constructor leaf). `None` for operators that
/// do not carry a usable type here.
fn operator_dae_type(op: &DAE::Operator) -> Option<Arc<DAE::Type>> {
    use DAE::Operator as O;
    match op {
        O::ADD { ty } | O::SUB { ty } | O::MUL { ty } | O::DIV { ty } | O::POW { ty } | O::UMINUS { ty }
        | O::MUL_SCALAR_PRODUCT { ty } | O::MUL_MATRIX_PRODUCT { ty }
        | O::UMINUS_ARR { ty } | O::ADD_ARR { ty } | O::SUB_ARR { ty } | O::MUL_ARR { ty } | O::DIV_ARR { ty }
        | O::MUL_ARRAY_SCALAR { ty } | O::ADD_ARRAY_SCALAR { ty } | O::SUB_SCALAR_ARRAY { ty }
        | O::DIV_ARRAY_SCALAR { ty } | O::DIV_SCALAR_ARRAY { ty }
        | O::POW_ARRAY_SCALAR { ty } | O::POW_SCALAR_ARRAY { ty } | O::POW_ARR { ty } | O::POW_ARR2 { ty } => {
            Some(ty.clone())
        }
        _ => None,
    }
}

/// Lower a range used as an array value (`start:step:stop`, step default 1).
/// The element count is `(stop - start) / step + 1`, clamped to ≥ 0 (an empty
/// range yields a zero-length array), and a fill loop writes each element. Only
/// Integer-element ranges are handled; Real ranges need the C runtime's
/// element-count rounding to stay byte-identical, so they fail loudly.
pub(super) fn compile_range_array(ctx: &mut FnCtx, ty: &DAE::Type, start: &DAE::Exp, step: Option<&DAE::Exp>, stop: &DAE::Exp) -> Result<()> {
    let SigTy::Array { elem, .. } = sig_ty(ty)? else {
        return Err("CodegenWasmJit: range with non-array type");
    };
    match &*elem {
        // Integer and enumeration ranges (enum literals are their i32 index).
        SigTy::Int => compile_int_range_array(ctx, start, step, stop),
        SigTy::Real => compile_real_range_array(ctx, start, step, stop),
        other => return Err("CodegenWasmJit: only Integer/Real ranges are supported as array values"),
    }
}

/// `start:step:stop` over Integers — `n = max(0, (stop-start)/step + 1)`
/// elements (integer division naturally handles either step direction), filled
/// `arr[k] = start + k*step`.
fn compile_int_range_array(ctx: &mut FnCtx, start: &DAE::Exp, step: Option<&DAE::Exp>, stop: &DAE::Exp) -> Result<()> {
    let start_t = ctx.alloc_temp(WTy::I32);
    let w = compile_exp(ctx, start)?;
    coerce(ctx, w, WTy::I32);
    ctx.emit(we::Instruction::LocalSet(start_t));
    let step_t = ctx.alloc_temp(WTy::I32);
    match step {
        Some(e) => {
            let w = compile_exp(ctx, e)?;
            coerce(ctx, w, WTy::I32);
        }
        None => ctx.emit(we::Instruction::I32Const(1)),
    }
    ctx.emit(we::Instruction::LocalSet(step_t));
    let stop_t = ctx.alloc_temp(WTy::I32);
    let w = compile_exp(ctx, stop)?;
    coerce(ctx, w, WTy::I32);
    ctx.emit(we::Instruction::LocalSet(stop_t));

    // n = (stop - start) / step + 1, then n = max(n, 0).
    let n_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalGet(stop_t));
    ctx.emit(we::Instruction::LocalGet(start_t));
    ctx.emit(we::Instruction::I32Sub);
    ctx.emit(we::Instruction::LocalGet(step_t));
    ctx.emit(we::Instruction::I32DivS);
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(n_t));
    // n = (n > 0) ? n : 0
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::I32GtS);
    ctx.emit(we::Instruction::Select);
    ctx.emit(we::Instruction::LocalSet(n_t));

    let arr = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(SigTy::Int.elem_kind() as i32));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")?));
    ctx.emit(we::Instruction::LocalSet(arr));
    ctx.emit(we::Instruction::LocalGet(arr));
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")?));

    // for k in 0..n: arr[k] = start + k*step
    let k_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalSet(k_t));
    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
    ctx.emit(we::Instruction::LocalGet(k_t));
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::I32GeS);
    ctx.emit(we::Instruction::BrIf(1));
    ctx.emit(we::Instruction::LocalGet(arr));
    ctx.emit(we::Instruction::LocalGet(k_t));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    emit_elem_ptr(ctx, &SigTy::Int)?;
    ctx.emit(we::Instruction::LocalGet(start_t));
    ctx.emit(we::Instruction::LocalGet(k_t));
    ctx.emit(we::Instruction::LocalGet(step_t));
    ctx.emit(we::Instruction::I32Mul);
    ctx.emit(we::Instruction::I32Add);
    elem_store(ctx, &SigTy::Int);
    ctx.emit(we::Instruction::LocalGet(k_t));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(k_t));
    ctx.emit(we::Instruction::Br(0));
    ctx.emit(we::Instruction::End); // loop
    ctx.emit(we::Instruction::End); // block
    ctx.emit(we::Instruction::LocalGet(arr));
    Ok(())
}

/// `start:step:stop` over Reals, byte-identical to the C runtime's
/// `create_real_array_from_range`: the element count is
/// `(step>0 ? start<=stop : start>=stop) ? (size_t)((stop-start)/step + 1) : 0`,
/// and the elements are produced by **accumulation** (`val += step`), not
/// `start + k*step`, so the rounding matches exactly.
fn compile_real_range_array(ctx: &mut FnCtx, start: &DAE::Exp, step: Option<&DAE::Exp>, stop: &DAE::Exp) -> Result<()> {
    // `val` doubles as the running accumulator (starts at `start`).
    let val_t = ctx.alloc_temp(WTy::F64);
    let w = compile_exp(ctx, start)?;
    coerce(ctx, w, WTy::F64);
    ctx.emit(we::Instruction::LocalSet(val_t));
    let step_t = ctx.alloc_temp(WTy::F64);
    match step {
        Some(e) => {
            let w = compile_exp(ctx, e)?;
            coerce(ctx, w, WTy::F64);
        }
        None => ctx.emit(we::Instruction::F64Const(1.0f64.into())),
    }
    ctx.emit(we::Instruction::LocalSet(step_t));
    let stop_t = ctx.alloc_temp(WTy::F64);
    let w = compile_exp(ctx, stop)?;
    coerce(ctx, w, WTy::F64);
    ctx.emit(we::Instruction::LocalSet(stop_t));

    // n = 0; if (step>0 ? start<=stop : start>=stop) n = trunc((stop-start)/step + 1)
    let n_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalSet(n_t));
    // cond on the stack:
    ctx.emit(we::Instruction::LocalGet(step_t));
    ctx.emit(we::Instruction::F64Const(0.0f64.into()));
    ctx.emit(we::Instruction::F64Gt);
    ctx.emit(we::Instruction::If(we::BlockType::Result(we::ValType::I32)));
    ctx.emit(we::Instruction::LocalGet(val_t));
    ctx.emit(we::Instruction::LocalGet(stop_t));
    ctx.emit(we::Instruction::F64Le);
    ctx.emit(we::Instruction::Else);
    ctx.emit(we::Instruction::LocalGet(val_t));
    ctx.emit(we::Instruction::LocalGet(stop_t));
    ctx.emit(we::Instruction::F64Ge);
    ctx.emit(we::Instruction::End);
    ctx.emit(we::Instruction::If(we::BlockType::Empty));
    ctx.emit(we::Instruction::LocalGet(stop_t));
    ctx.emit(we::Instruction::LocalGet(val_t));
    ctx.emit(we::Instruction::F64Sub);
    ctx.emit(we::Instruction::LocalGet(step_t));
    ctx.emit(we::Instruction::F64Div);
    ctx.emit(we::Instruction::F64Const(1.0f64.into()));
    ctx.emit(we::Instruction::F64Add);
    ctx.emit(we::Instruction::I32TruncF64S); // truncate toward zero, like (size_t)
    ctx.emit(we::Instruction::LocalSet(n_t));
    ctx.emit(we::Instruction::End);

    let arr = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(SigTy::Real.elem_kind() as i32));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")?));
    ctx.emit(we::Instruction::LocalSet(arr));
    ctx.emit(we::Instruction::LocalGet(arr));
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")?));

    // for k in 0..n: arr[k] = val; val += step
    let k_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalSet(k_t));
    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
    ctx.emit(we::Instruction::LocalGet(k_t));
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::I32GeS);
    ctx.emit(we::Instruction::BrIf(1));
    ctx.emit(we::Instruction::LocalGet(arr));
    ctx.emit(we::Instruction::LocalGet(k_t));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    emit_elem_ptr(ctx, &SigTy::Real)?;
    ctx.emit(we::Instruction::LocalGet(val_t));
    elem_store(ctx, &SigTy::Real);
    ctx.emit(we::Instruction::LocalGet(val_t));
    ctx.emit(we::Instruction::LocalGet(step_t));
    ctx.emit(we::Instruction::F64Add);
    ctx.emit(we::Instruction::LocalSet(val_t));
    ctx.emit(we::Instruction::LocalGet(k_t));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(k_t));
    ctx.emit(we::Instruction::Br(0));
    ctx.emit(we::Instruction::End); // loop
    ctx.emit(we::Instruction::End); // block
    ctx.emit(we::Instruction::LocalGet(arr));
    Ok(())
}
