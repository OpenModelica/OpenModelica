//! Reading/writing model variables: scalars, slices, array/record gather and
//! scatter, constant stores, start values.

use super::*;

/// Gather the contiguous sub-array `group[leading, :, …]` from `SimData` into a
/// fresh (refcount-1) runtime array of the trailing dimensions, leaving the
/// owned handle on the stack.
fn emit_sim_slice_gather(ctx: &mut FnCtx, group: &ArrayGroup, leading: &[Arc<DAE::Exp>]) -> Result<()> {
    let (ek, stride) = sim_array_elem_kind_stride(group.wty);
    let trailing: Vec<u32> = group.dims[leading.len()..].to_vec();
    let trailing_total: u32 = trailing.iter().product();
    let obj = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(ek as i32));
    ctx.emit(we::Instruction::I32Const(trailing.len() as i32));
    ctx.emit(we::Instruction::I32Const(trailing_total as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")?));
    ctx.emit(we::Instruction::LocalSet(obj));
    for (axis, d) in trailing.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::I32Const(*d as i32));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")?));
    }
    // memory.copy(dst = obj data, src = slice addr, len = trailing_total * stride).
    ctx.emit(we::Instruction::LocalGet(obj));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")?));
    emit_sim_slice_addr(ctx, group, leading)?;
    ctx.emit(we::Instruction::I32Const((trailing_total * stride) as i32));
    ctx.emit(we::Instruction::MemoryCopy { src_mem: 0, dst_mem: 0 });
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(())
}

/// Scatter a runtime array `rhs` into the contiguous sub-array
/// `group[leading, :, …]` of `SimData` (the reverse of [`emit_sim_slice_gather`]).
fn emit_sim_slice_scatter(ctx: &mut FnCtx, group: &ArrayGroup, leading: &[Arc<DAE::Exp>], rhs: RhsSource) -> Result<()> {
    let (_, stride) = sim_array_elem_kind_stride(group.wty);
    let trailing_total: u32 = group.dims[leading.len()..].iter().product();
    let h = ctx.alloc_temp(WTy::I32);
    let rw = rhs.push(ctx)?;
    if rw != WTy::I32 {
        return Err("CodegenWasmJit: array-slice assignment rhs is not an array handle");
    }
    ctx.emit(we::Instruction::LocalSet(h));
    // memory.copy(dst = slice addr, src = rhs data, len = trailing_total * stride).
    emit_sim_slice_addr(ctx, group, leading)?;
    ctx.emit(we::Instruction::LocalGet(h));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")?));
    ctx.emit(we::Instruction::I32Const((trailing_total * stride) as i32));
    ctx.emit(we::Instruction::MemoryCopy { src_mem: 0, dst_mem: 0 });
    ctx.emit(we::Instruction::LocalGet(h));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_release")?));
    Ok(())
}

/// The value type of a component reference's leaf, after applying its final
/// subscripts (so `states[2]` of `states : ThermodynamicState[2]` yields the
/// record element type). Array dims are peeled one per index subscript.
fn cref_leaf_value_type(cr: &DAE::ComponentRef) -> Result<Arc<DAE::Type>> {
    use DAE::ComponentRef as C;
    let (identType, nsubs) = match cr {
        C::CREF_QUAL { componentRef, .. } => return cref_leaf_value_type(componentRef),
        C::CREF_IDENT { identType, subscriptLst, .. } => {
            (identType, (&**subscriptLst).into_iter().count())
        }
        _ => return Err("CodegenWasmJit: unsupported component reference"),
    };
    let mut ty = identType.clone();
    let mut remaining = nsubs;
    while remaining > 0 {
        let DAE::Type::T_ARRAY { ty: inner, dims } = &*ty else { break };
        let nd = (&**dims).into_iter().count();
        if remaining < nd {
            break;
        }
        remaining -= nd;
        ty = inner.clone();
    }
    Ok(ty)
}

/// Append `field` (of DAE type `field_ty`) to the leaf of `cr`, turning e.g.
/// `pipe.flowModel.states[2]` into `pipe.flowModel.states[2].field`.
fn cref_append_field(
    cr: &DAE::ComponentRef,
    field: &DAE::Ident,
    field_ty: Arc<DAE::Type>,
) -> Arc<DAE::ComponentRef> {
    use DAE::ComponentRef as C;
    match cr {
        C::CREF_IDENT { ident, identType, subscriptLst } => Arc::new(C::CREF_QUAL {
            ident: ident.clone(),
            identType: identType.clone(),
            subscriptLst: subscriptLst.clone(),
            componentRef: Arc::new(C::CREF_IDENT {
                ident: field.clone(),
                identType: field_ty,
                subscriptLst: metamodelica::nil(),
            }),
        }),
        C::CREF_QUAL { ident, identType, subscriptLst, componentRef } => Arc::new(C::CREF_QUAL {
            ident: ident.clone(),
            identType: identType.clone(),
            subscriptLst: subscriptLst.clone(),
            componentRef: cref_append_field(componentRef, field, field_ty),
        }),
        other => Arc::new(other.clone()),
    }
}

/// Push the byte address of array element `base[e1,…,en]` within `SimData` onto
/// the stack, for a `group` whose scalarized elements are contiguous row-major
/// (verified in `finalize_array_groups`). The row-major linear index is built at
/// run time (Horner: `acc = acc*dims[k] + (e_k - 1)`), so the subscripts may be
/// non-constant. Returns the element value type.
fn emit_sim_array_elem_addr(
    ctx: &mut FnCtx,
    group: &ArrayGroup,
    sub_exps: &[Arc<DAE::Exp>],
) -> Result<WTy> {
    if sub_exps.len() != group.dims.len() {
        return Err("error");
    }
    let (_, stride) = sim_array_elem_kind_stride(group.wty);
    let data = ctx.sim()?.data_local;
    emit_sim_flat_index(ctx, &group.dims, sub_exps)?;
    // addr = data + base_off + linear * stride
    ctx.emit(we::Instruction::I32Const(stride as i32));
    ctx.emit(we::Instruction::I32Mul);
    ctx.emit(we::Instruction::LocalGet(data));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::I32Const(group.base_off as i32));
    ctx.emit(we::Instruction::I32Add);
    Ok(group.wty)
}

/// Push the 0-based row-major index of element `[e1,…,en]` of an array shaped
/// `dims`, built at run time (Horner: `acc = acc*dims[k] + (e_k - 1)`).
fn emit_sim_flat_index(ctx: &mut FnCtx, dims: &[u32], sub_exps: &[Arc<DAE::Exp>]) -> Result<()> {
    ctx.emit(we::Instruction::I32Const(0));
    for (k, exp) in sub_exps.iter().enumerate() {
        ctx.emit(we::Instruction::I32Const(dims[k] as i32));
        ctx.emit(we::Instruction::I32Mul);
        let wt = compile_exp(ctx, exp)?;
        coerce(ctx, wt, WTy::I32);
        ctx.emit(we::Instruction::I32Const(1));
        ctx.emit(we::Instruction::I32Sub); // e_k - 1 (1-based -> 0-based)
        ctx.emit(we::Instruction::I32Add);
    }
    Ok(())
}

/// Apply an alias negation to the value on the stack, as C's `crefToCStr` does.
fn emit_neg(ctx: &mut FnCtx, wty: WTy, neg: Neg) {
    match wty {
        WTy::F64 => {
            if neg != Neg::None {
                ctx.emit(we::Instruction::F64Neg);
            }
        }
        WTy::I32 => match neg {
            Neg::None => {}
            // wasm has no `i32.neg`.
            Neg::Arith => {
                ctx.emit(we::Instruction::I32Const(-1));
                ctx.emit(we::Instruction::I32Mul);
            }
            // A Boolean is stored as 0/1, so `!v` is `v == 0`.
            Neg::Not => ctx.emit(we::Instruction::I32Eqz),
        },
    }
}

/// Select element `[e1,…,en]` of a [`ScatterGroup`] with a chain of `select`s over
/// the run-time index, picking the element's offset — or its value, when the
/// elements carry different alias negations. Leaves the element's byte address on
/// the stack with `addr_only` (for a store), otherwise its value.
fn emit_sim_scatter_elem(
    ctx: &mut FnCtx,
    group: &ScatterGroup,
    sub_exps: &[Arc<DAE::Exp>],
    addr_only: bool,
) -> Result<WTy> {
    use we::Instruction as I;
    let negated = group.elems.iter().any(|(_, n)| *n != Neg::None);
    if addr_only && negated {
        return Err("CodegenWasmJit: assignment to negated alias");
    }
    let data = ctx.sim()?.data_local;
    emit_sim_flat_index(ctx, &group.dims, sub_exps)?;
    let flat = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::LocalSet(flat));
    // `acc = flat != k ? acc : <element k>`: one value on the stack, no branches.
    for (k, &(off, neg)) in group.elems.iter().enumerate() {
        if negated {
            ctx.emit(I::LocalGet(data));
            match group.wty {
                WTy::F64 => ctx.emit(I::F64Load(mem_arg(off, 3))),
                WTy::I32 => ctx.emit(I::I32Load(mem_arg(off, 2))),
            }
            emit_neg(ctx, group.wty, neg);
        } else {
            ctx.emit(I::I32Const(off as i32));
        }
        if k > 0 {
            ctx.emit(I::LocalGet(flat));
            ctx.emit(I::I32Const(k as i32));
            ctx.emit(I::I32Ne);
            ctx.emit(I::Select);
        }
    }
    if !negated {
        ctx.emit(I::LocalGet(data));
        ctx.emit(I::I32Add);
        if !addr_only {
            match group.wty {
                WTy::F64 => ctx.emit(I::F64Load(mem_arg(0, 3))),
                WTy::I32 => ctx.emit(I::I32Load(mem_arg(0, 2))),
            }
        }
    }
    Ok(group.wty)
}

/// In simulation mode, try to read a model variable from the `SimData` block.
/// Returns `Some(wty)` when `cref` resolved to a model variable (state,
/// derivative, algebraic, parameter, `time`, or a `$START`/`$PRE` access), or
/// `None` when it is an ordinary wasm local (a lowering temporary / iterator)
/// that the normal cref path should handle.
pub(super) fn compile_sim_cref_read(ctx: &mut FnCtx, cref: &DAE::ComponentRef) -> Result<Option<WTy>> {
    if ctx.sim.is_none() {
        return Ok(None);
    }
    // `time` lives at offset 0 of `SimData`; `__HOM_LAMBDA` is left behind by
    // differentiating `homotopy(a, s)` (C maps it to `simulationInfo->lambda`).
    if let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = cref {
        if subscriptLst.is_empty() {
            if ident.as_str() == "time" {
                let data = ctx.sim()?.data_local;
                ctx.emit(we::Instruction::LocalGet(data));
                ctx.emit(we::Instruction::F64Load(mem_arg(0, 3)));
                return Ok(Some(WTy::F64));
            }
            if ident.as_str() == openmodelica_backend_types::BackendDAE::homotopyLambda {
                let (data, lambda_off) = { let s = ctx.sim()?; (s.data_local, s.lambda_off) };
                ctx.emit(we::Instruction::LocalGet(data));
                ctx.emit(we::Instruction::F64Load(mem_arg(lambda_off, 3)));
                return Ok(Some(WTy::F64));
            }
            // A real wasm local (e.g. a `for` iterator) shadows model lookup.
            if ctx.locals.contains_key(ident.as_str()) {
                return Ok(None);
            }
        }
    }
    // `$START.<cref>`: read the variable's start-attribute expression (used by
    // the initial-equation system). `$PRE.<cref>`: the value at the last event,
    // read from the mirrored pre-slot the driver refreshes at every event.
    if let DAE::ComponentRef::CREF_QUAL { ident, componentRef, .. } = cref {
        match ident.as_str() {
            "$START" => {
                let key = sim_cref_key_fatal(componentRef)?;
                if let Some(wty) = emit_sim_start_scalar(ctx, &key)? {
                    return Ok(Some(wty));
                }
                // Whole-array `$START.y` (e.g. `y := $START.y`).
                if let Some(group) = ctx.sim()?.array_groups.get(&key).cloned() {
                    emit_sim_start_array_gather(ctx, &group, &key)?;
                    return Ok(Some(WTy::I32));
                }
                return Err("CodegenWasmJit: $START for unknown variable");
            }
            "$PRE" => {
                // No pre-storage (e.g. `pre()` of a parameter): read the live value.
                if !sim_pre_is_stored(ctx, cref)? {
                    return compile_sim_cref_read(ctx, componentRef);
                }
            }
            _ => {}
        }
    }
    // Array element with a non-constant subscript (e.g. a `for`-loop iterator):
    // resolve the element address at run time instead of via a static slot key.
    if let Some((base, sub_exps)) = array_ref_of(cref)? {
        if sub_exps.iter().any(|e| const_index_value(e).is_none()) {
            if let Some(group) = ctx.sim()?.array_groups.get(&base).filter(|g| g.dims.len() == sub_exps.len()).cloned() {
                let wty = emit_sim_array_elem_addr(ctx, &group, &sub_exps)?;
                match wty {
                    WTy::F64 => ctx.emit(we::Instruction::F64Load(mem_arg(0, 3))),
                    WTy::I32 => ctx.emit(we::Instruction::I32Load(mem_arg(0, 2))),
                }
                emit_retain_top(ctx, group.heap)?;
                return Ok(Some(wty));
            }
            if let Some(group) = ctx.sim()?.scatter_groups.get(&base).filter(|g| g.dims.len() == sub_exps.len()).cloned() {
                let wty = emit_sim_scatter_elem(ctx, &group, &sub_exps, false)?;
                emit_retain_top(ctx, group.heap)?;
                return Ok(Some(wty));
            }
        }
    }
    // Contiguous slice `base[i,…,:]`: gather the row-major block.
    for slice in [sim_slice_of(cref)?, flat_sim_slice_of(cref)?].into_iter().flatten() {
        let (base, leading) = slice;
        if let Some(group) =
            ctx.sim()?.array_groups.get(&base).filter(|g| leading.len() < g.dims.len()).cloned()
        {
            emit_sim_slice_gather(ctx, &group, &leading)?;
            return Ok(Some(WTy::I32));
        }
    }
    // Any other slice (a column `[:,1]`, a strided range): gather the whole array
    // and let the runtime slice handle it.
    for selection in [sim_array_base_subs(cref)?, flat_sim_array_base_subs(cref)?].into_iter().flatten() {
        let (base, subs) = selection;
        if let Some(group) = ctx.sim()?.array_groups.get(&base).cloned() {
            if subs_select_array(&subs, &group) {
                emit_sim_array_gather(ctx, &group)?;
                let wty = slice_loaded(ctx, &subs)?;
                return Ok(Some(wty));
            }
        }
    }
    if sim_cref_key(cref).is_err() {
        if let Some(wty) = try_emit_sim_array_box(ctx, cref)? {
            return Ok(Some(wty));
        }
    }
    let key = sim_cref_key_fatal(cref)?;
    let slot = match ctx.sim()?.vars.get(&key) {
        Some(s) => *s,
        None => {
            // Not a scalar slot: it may be a whole array-valued model variable,
            // whose scalarized elements occupy a contiguous slot range. Gather the
            // range into a fresh runtime array object.
            if let Some(group) = ctx.sim()?.array_groups.get(&key).cloned() {
                emit_sim_array_gather(ctx, &group)?;
                return Ok(Some(WTy::I32));
            }
            if let Some(exp) = ctx.sim()?.consts.get(&key).cloned() {
                return compile_exp(ctx, &exp).map(Some);
            }
            if ctx.sim()?.const_groups.contains_key(&key) {
                emit_const_array(ctx, &key)?;
                return Ok(Some(WTy::I32));
            }
            // A whole record model variable: gather its scalar field slots into a
            // fresh runtime record object.
            if try_emit_sim_record_gather(ctx, cref)? {
                return Ok(Some(WTy::I32));
            }
            if try_emit_empty_sim_array(ctx, cref)? {
                return Ok(Some(WTy::I32));
            }
            if let Some(wty) = try_emit_sim_array_box(ctx, cref)? {
                return Ok(Some(wty));
            }
            if let Some(wty) = emit_sim_const_index_error(ctx, cref, &key)? {
                return Ok(Some(wty));
            }
            if is_jac_column_elem_key(&key) {
                ctx.emit(we::Instruction::F64Const(0.0.into()));
                return Ok(Some(WTy::F64));
            }
            crate::CodegenWasmJit::record_error(format!(
                "CodegenWasmJit: simulation reference to unknown variable `{key}`{}",
                fn_context()
            ));
            return Err("CodegenWasmJit: simulation reference to unknown variable")
        }
    };
    let data = ctx.sim()?.data_local;
    ctx.emit(we::Instruction::LocalGet(data));
    match slot.wty {
        WTy::F64 => ctx.emit(we::Instruction::F64Load(mem_arg(slot.off, 3))),
        WTy::I32 => ctx.emit(we::Instruction::I32Load(mem_arg(slot.off, 2))),
    }
    emit_neg(ctx, slot.wty, slot.negate);
    if slot.heap {
        // Reading a heap (String) slot yields an owned reference, like reading a
        // heap local: retain so the slot keeps its reference while the value flows
        // into the consuming operation. (`rt_retain` is null-safe.)
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::I32Load(mem_arg(slot.off, 2)));
        ctx.emit(we::Instruction::Call(rt_index("rt_retain")?));
    }
    Ok(Some(slot.wty))
}

/// The value stored into a simulation variable: an expression to evaluate, or
/// an already-computed owned value in a temp (a tuple assignment's result).
pub(super) enum RhsSource<'a> {
    Exp(&'a DAE::Exp),
    Temp { local: u32, wty: WTy },
}

impl RhsSource<'_> {
    pub(super) fn push(&self, ctx: &mut FnCtx) -> Result<WTy> {
        match self {
            RhsSource::Exp(e) => compile_exp(ctx, e),
            RhsSource::Temp { local, wty } => {
                ctx.emit(we::Instruction::LocalGet(*local));
                Ok(*wty)
            }
        }
    }
}

/// In simulation mode, try to assign to a model variable in the `SimData`
/// block. Returns `true` when `cref` resolved to a writable model variable.
/// Aliases are never assigned (they are removed by the backend); `$START`/`time`
/// are not assignment targets in the equation systems handled here.
pub(super) fn compile_sim_cref_assign(ctx: &mut FnCtx, cref: &DAE::ComponentRef, rhs: RhsSource) -> Result<bool> {
    if ctx.sim.is_none() {
        return Ok(false);
    }
    // `$START.x := expr` in the initial system: the C target sets `x`'s start
    // attribute *and* the live value `realVars[x] = start` (see the
    // `$START.<cref>`-LHS pattern in `_06inz`), so write both: the slot is what a
    // solver reads for its initial guess and what `LOG_SOTI` prints.
    if let DAE::ComponentRef::CREF_QUAL { ident, componentRef, .. } = cref {
        if ident.as_str() == "$START" {
            let start_off = sim_cref_key(componentRef)
                .ok()
                .and_then(|k| ctx.sim().ok()?.start_slots.get(&k).copied());
            let Some(off) = start_off else {
                return compile_sim_cref_assign(ctx, componentRef, rhs);
            };
            let data = ctx.sim()?.data_local;
            let w = rhs.push(ctx)?;
            coerce(ctx, w, WTy::F64);
            let tmp = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(tmp));
            ctx.emit(we::Instruction::LocalGet(data));
            ctx.emit(we::Instruction::LocalGet(tmp));
            ctx.emit(we::Instruction::F64Store(mem_arg(off, 3)));
            return compile_sim_cref_assign(ctx, componentRef, RhsSource::Temp { local: tmp, wty: WTy::F64 });
        }
        // `$PRE.x := e` targets x's pre-slot when one is registered; otherwise
        // (no pre-slot, e.g. a parameter) fall back to the live slot.
        if ident.as_str() == "$PRE" && !sim_pre_is_stored_lhs(ctx, cref)? {
            return compile_sim_cref_assign(ctx, componentRef, rhs);
        }
    }
    // Plain idents that are wasm locals are handled by the normal path.
    if let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = cref {
        if subscriptLst.is_empty() && ctx.locals.contains_key(ident.as_str()) {
            return Ok(false);
        }
    }
    // Array element with a non-constant subscript: store to the run-time address.
    if let Some((base, sub_exps)) = array_ref_of(cref)? {
        if sub_exps.iter().any(|e| const_index_value(e).is_none()) {
            // Either group leaves the element's address on the stack.
            let elem = match ctx.sim()?.array_groups.get(&base).filter(|g| g.dims.len() == sub_exps.len()).cloned() {
                Some(group) => Some(emit_sim_array_elem_addr(ctx, &group, &sub_exps)?),
                None => match ctx.sim()?.scatter_groups.get(&base).filter(|g| g.dims.len() == sub_exps.len()).cloned() {
                    Some(group) => Some(emit_sim_scatter_elem(ctx, &group, &sub_exps, true)?),
                    None => None,
                },
            };
            if let Some(wty) = elem {
                let rw = rhs.push(ctx)?;
                coerce(ctx, rw, wty);
                match wty {
                    WTy::F64 => ctx.emit(we::Instruction::F64Store(mem_arg(0, 3))),
                    WTy::I32 => ctx.emit(we::Instruction::I32Store(mem_arg(0, 2))),
                }
                return Ok(true);
            }
        }
    }
    // Contiguous slice `base[i,…,:] := arr`: scatter into the row-major block.
    for slice in [sim_slice_of(cref)?, flat_sim_slice_of(cref)?].into_iter().flatten() {
        let (base, leading) = slice;
        if let Some(group) =
            ctx.sim()?.array_groups.get(&base).filter(|g| leading.len() < g.dims.len()).cloned()
        {
            emit_sim_slice_scatter(ctx, &group, &leading, rhs)?;
            return Ok(true);
        }
    }
    // Any other selection (`base[lo:hi] := v`, a column, a partial index): apply it
    // to a gathered copy of the whole array and scatter that back.
    for selection in [sim_array_base_subs(cref)?, flat_sim_array_base_subs(cref)?].into_iter().flatten() {
        let (base, subs) = selection;
        if let Some(group) = ctx.sim()?.array_groups.get(&base).cloned() {
            if subs_select_array(&subs, &group) {
                let arr = ctx.alloc_temp(WTy::I32);
                emit_sim_array_gather(ctx, &group)?;
                ctx.emit(we::Instruction::LocalSet(arr));
                compile_slice_assign(ctx, arr, &subs, rhs)?;
                emit_sim_array_scatter(ctx, &group, RhsSource::Temp { local: arr, wty: WTy::I32 })?;
                return Ok(true);
            }
        }
    }
    let key = sim_cref_key_fatal(cref)?;
    let slot = match ctx.sim()?.vars.get(&key) {
        Some(s) => *s,
        None => {
            // A whole array-valued model variable: evaluate the rhs to a runtime
            // array and scatter its elements into the contiguous slot range.
            if let Some(group) = ctx.sim()?.array_groups.get(&key).cloned() {
                emit_sim_array_scatter(ctx, &group, rhs)?;
                return Ok(true);
            }
            // A whole record model variable: evaluate the rhs to a runtime record
            // and store each field into its own scalar slot.
            if try_emit_sim_record_scatter(ctx, cref, rhs)? {
                return Ok(true);
            }
            crate::CodegenWasmJit::record_error(format!(
                "CodegenWasmJit: simulation assignment to unknown variable `{key}`"
            ));
            return Err("CodegenWasmJit: simulation assignment to unknown variable")
        }
    };
    if slot.negate != Neg::None {
        return Err("CodegenWasmJit: assignment to negated alias");
    }
    // An array-valued rhs would `coerce` its handle into the slot: a pointer stored
    // as a Real. Reject only a type `exp_sigty` names: it is best-effort, and an
    // expression it cannot type is still one `compile_exp` lowers.
    if !slot.heap {
        if let RhsSource::Exp(e) = rhs {
            if matches!(exp_sigty(e), Ok(SigTy::Array { .. })) {
                crate::CodegenWasmJit::record_error(format!(
                    "CodegenWasmJit: array-valued expression assigned to the scalar slot `{key}`"
                ));
                return Err("CodegenWasmJit: array-valued expression assigned to a scalar slot");
            }
        }
    }
    let data = ctx.sim()?.data_local;
    if slot.heap {
        // Release-on-overwrite *after* the rhs: `s := s + x` reads the slot, so
        // releasing first would free a value the rhs still needs. The slot starts
        // null (zeroed `SimData`), and `rt_release` is null-safe.
        let rw = rhs.push(ctx)?;
        coerce(ctx, rw, slot.wty);
        let t = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalSet(t));
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::I32Load(mem_arg(slot.off, 2)));
        ctx.emit(we::Instruction::Call(rt_index("rt_release")?));
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::LocalGet(t));
        ctx.emit(we::Instruction::I32Store(mem_arg(slot.off, 2)));
        return Ok(true);
    }
    if let Some(dtor) = ctx.sim()?.extobj_dtors.get(&key).cloned() {
        if let RhsSource::Exp(e) = &rhs {
            let e: &DAE::Exp = e;
            if let DAE::Exp::CALL { expLst, .. } = e {
                return emit_extobj_construct(ctx, slot.off, &dtor, expLst, RhsSource::Exp(e));
            }
        }
    }
    // Stack order for a store is [addr, value]: push the base, evaluate the rhs,
    // coerce to the slot type, then store at the constant offset.
    ctx.emit(we::Instruction::LocalGet(data));
    let rw = rhs.push(ctx)?;
    coerce(ctx, rw, slot.wty);
    match slot.wty {
        WTy::F64 => ctx.emit(we::Instruction::F64Store(mem_arg(slot.off, 3))),
        WTy::I32 => ctx.emit(we::Instruction::I32Store(mem_arg(slot.off, 2))),
    }
    Ok(true)
}

/// `obj := Ctor(args)`: an external object is constructed once. The runtime keeps
/// the arguments the live object was built from (`rt_extobj_arg_*`, keyed by slot
/// and position); when every argument compares equal the object is kept, otherwise
/// the old one is destructed before the constructor runs. Strings compare by
/// content, arrays and records structurally; an argument of a type the runtime
/// cannot compare at all forces reconstruction.
fn emit_extobj_construct(
    ctx: &mut FnCtx,
    off: u32,
    dtor: &str,
    args: &List<Arc<DAE::Exp>>,
    rhs: RhsSource,
) -> Result<bool> {
    use we::Instruction as I;
    let didx = ctx.by_name.get(dtor).ok_or("CodegenWasmJit: external-object destructor was not compiled")?.index;
    let data = ctx.sim()?.data_local;
    let same = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::LocalGet(data));
    ctx.emit(I::I32Load(mem_arg(off, 2)));
    ctx.emit(I::I32Const(0));
    ctx.emit(I::I32Ne);
    ctx.emit(I::LocalSet(same));
    for (pos, arg) in args.iter().enumerate() {
        let (rt_fn, wty) = match exp_sigty(arg) {
            Ok(SigTy::Real) => ("rt_extobj_arg_f64", WTy::F64),
            Ok(SigTy::Int | SigTy::Bool | SigTy::Ptr) => ("rt_extobj_arg_i32", WTy::I32),
            Ok(SigTy::Str) => ("rt_extobj_arg_str", WTy::I32),
            Ok(SigTy::Array { .. }) => ("rt_extobj_arg_arr", WTy::I32),
            Ok(SigTy::Record { .. }) => ("rt_extobj_arg_rec", WTy::I32),
            _ => {
                ctx.emit(I::I32Const(0));
                ctx.emit(I::LocalSet(same));
                continue;
            }
        };
        ctx.emit(I::LocalGet(same));
        ctx.emit(I::I32Const(off as i32));
        ctx.emit(I::I32Const(pos as i32));
        let w = compile_exp(ctx, arg)?;
        coerce(ctx, w, wty);
        ctx.emit(I::Call(rt_index(rt_fn)?));
        ctx.emit(I::I32And);
        ctx.emit(I::LocalSet(same));
    }
    ctx.emit(I::LocalGet(same));
    ctx.emit(I::I32Eqz);
    ctx.emit(I::If(we::BlockType::Empty));
    let old = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::LocalGet(data));
    ctx.emit(I::I32Load(mem_arg(off, 2)));
    ctx.emit(I::LocalTee(old));
    ctx.emit(I::If(we::BlockType::Empty));
    ctx.emit(I::LocalGet(old));
    ctx.emit(I::Call(didx));
    ctx.emit(I::End);
    ctx.emit(I::LocalGet(data));
    let rw = rhs.push(ctx)?;
    coerce(ctx, rw, WTy::I32);
    ctx.emit(I::I32Store(mem_arg(off, 2)));
    ctx.emit(I::End);
    Ok(true)
}

/// The `SimData` slot and little-endian value bytes of an assignment
/// `cref := <compile-time constant>` that [`compile_sim_cref_assign`] would lower
/// to a single plain store — `None` when either side needs its general path.
/// Resolving the slot without emitting anything is what lets
/// [`emit_sim_const_stores`] group runs of them into data segments.
pub(crate) fn sim_const_store(
    ctx: &FnCtx,
    cref: &DAE::ComponentRef,
    exp: &DAE::Exp,
) -> Result<Option<(u32, Vec<u8>)>> {
    let Some(sim) = &ctx.sim else { return Ok(None) };
    // Mirror the LHS redirections of `compile_sim_cref_assign`.
    if let DAE::ComponentRef::CREF_QUAL { ident, componentRef, .. } = cref {
        if ident.as_str() == "$START" {
            return sim_const_store(ctx, componentRef, exp);
        }
        if ident.as_str() == "$PRE" && !sim_pre_is_stored_lhs(ctx, cref)? {
            return sim_const_store(ctx, componentRef, exp);
        }
    }
    if let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = cref {
        if subscriptLst.is_empty() && ctx.locals.contains_key(ident.as_str()) {
            return Ok(None);
        }
    }
    if let Some((_, sub_exps)) = array_ref_of(cref)? {
        if sub_exps.iter().any(|e| const_index_value(e).is_none()) {
            return Ok(None);
        }
    }
    if sim_slice_of(cref)?.is_some() {
        return Ok(None);
    }
    if let Some((base, subs)) = sim_array_base_subs(cref)? {
        if let Some(group) = sim.array_groups.get(&base) {
            if !is_scalar_index(&subs, group.dims.len() as u32) {
                return Ok(None);
            }
        }
    }
    let Some(slot) = sim.vars.get(&sim_cref_key(cref)?) else { return Ok(None) };
    if slot.negate != Neg::None || slot.heap {
        return Ok(None);
    }
    let bytes = match (const_num(exp), slot.wty) {
        (Some(ConstNum::R(r)), WTy::F64) => r.to_le_bytes().to_vec(),
        (Some(ConstNum::I(i)), WTy::F64) => (i as f64).to_le_bytes().to_vec(),
        (Some(ConstNum::I(i)), WTy::I32) => i.to_le_bytes().to_vec(),
        _ => return Ok(None),
    };
    Ok(Some((slot.off, bytes)))
}

/// Store the constant values collected by [`sim_const_store`] into their
/// `SimData` slots. Adjacent slots — an evaluated parameter array is one
/// contiguous block — are copied from a passive data segment with `memory.init`;
/// short groups stay individual stores. All groups of one call share a single
/// segment (each `memory.init` reads it at its own source offset).
pub(crate) fn emit_sim_const_stores(
    ctx: &mut FnCtx,
    stores: &std::collections::BTreeMap<u32, Vec<u8>>,
) -> Result<()> {
    use we::Instruction as I;
    if stores.is_empty() {
        return Ok(());
    }
    // Split into maximal adjacent groups.
    let mut groups: Vec<Vec<(u32, &Vec<u8>)>> = Vec::new();
    for (&off, bytes) in stores {
        match groups.last_mut() {
            Some(g) if g.last().is_some_and(|(o, b)| o + b.len() as u32 == off) => g.push((off, bytes)),
            _ => groups.push(vec![(off, bytes)]),
        }
    }
    // A group of fewer than four values costs less as stores than as a segment
    // copy; the rest go into the shared blob as (dest, src, len).
    let mut blob: Vec<u8> = Vec::new();
    let mut copies: Vec<(u32, u32, u32)> = Vec::new();
    let data = ctx.sim()?.data_local;
    for g in &groups {
        if g.len() < 4 {
            for (off, bytes) in g {
                ctx.emit(I::LocalGet(data));
                match bytes.len() {
                    8 => {
                        let v = f64::from_le_bytes((&bytes[..]).try_into().map_err(|_| "CodegenWasmJit: bad constant slot value")?);
                        ctx.emit(I::F64Const(v.into()));
                        ctx.emit(I::F64Store(mem_arg(*off, 3)));
                    }
                    4 => {
                        let v = i32::from_le_bytes((&bytes[..]).try_into().map_err(|_| "CodegenWasmJit: bad constant slot value")?);
                        ctx.emit(I::I32Const(v));
                        ctx.emit(I::I32Store(mem_arg(*off, 2)));
                    }
                    _ => return Err("CodegenWasmJit: constant slot value of unexpected width"),
                }
            }
            continue;
        }
        let src = blob.len() as u32;
        for (_, bytes) in g {
            blob.extend_from_slice(bytes);
        }
        copies.push((g[0].0, src, blob.len() as u32 - src));
    }
    if copies.is_empty() {
        return Ok(());
    }
    let base = ctx.literals.intern(&blob);
    for (dest, src, len) in copies {
        ctx.emit(I::LocalGet(data));
        ctx.emit(I::I32Const(dest as i32));
        ctx.emit(I::I32Add);
        ctx.emit(I::I32Const((base + src) as i32));
        ctx.emit(I::I32Const(len as i32));
        ctx.emit(I::MemoryInit { mem: 0, data_index: 0 });
    }
    Ok(())
}

/// The `(elem_kind, byte_stride)` pair for an array of `wty` scalars: Real maps
/// to `EK_REAL`/8, Integer/Boolean to `EK_INT`/4. (A whole-array Boolean model
/// variable is tagged `EK_INT`; the two share 4-byte storage and no in-scope
/// builtin distinguishes them — revisit if a Boolean-array external appears.)
pub(super) fn sim_array_elem_kind_stride(wty: WTy) -> (u32, u32) {
    match wty {
        WTy::F64 => (SigTy::Real.elem_kind(), 8),
        WTy::I32 => (SigTy::Int.elem_kind(), 4),
    }
}

/// Emit code that gathers a whole array-valued model variable from its
/// contiguous `SimData` slot range into a fresh (refcount-1) runtime array
/// object, leaving the owned handle on the stack. The slots are stored
/// row-major and contiguously (verified at layout time), so the element data is
/// one `memory.copy` from the slot range into the new object's data area.
fn emit_sim_array_gather(ctx: &mut FnCtx, group: &ArrayGroup) -> Result<()> {
    let (ek, stride) = sim_array_elem_kind_stride(group.wty);
    let ndims = group.dims.len() as u32;
    let data = ctx.sim()?.data_local;
    let obj = ctx.alloc_temp(WTy::I32);
    // obj = rt_array_new(elem_kind, ndims, total); set each dimension.
    ctx.emit(we::Instruction::I32Const(ek as i32));
    ctx.emit(we::Instruction::I32Const(ndims as i32));
    ctx.emit(we::Instruction::I32Const(group.total as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")?));
    ctx.emit(we::Instruction::LocalSet(obj));
    for (axis, d) in group.dims.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::I32Const(*d as i32));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")?));
    }
    // memory.copy(dst = obj data, src = SimData + base_off, len = total * stride).
    ctx.emit(we::Instruction::LocalGet(obj));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")?));
    ctx.emit(we::Instruction::LocalGet(data));
    ctx.emit(we::Instruction::I32Const(group.base_off as i32));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::I32Const((group.total * stride) as i32));
    ctx.emit(we::Instruction::MemoryCopy { src_mem: 0, dst_mem: 0 });
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(())
}

/// Retain the heap handle on top of the stack, leaving it there: a slot read
/// borrows, and the consuming operation releases what it is given.
fn emit_retain_top(ctx: &mut FnCtx, heap: bool) -> Result<()> {
    if !heap {
        return Ok(());
    }
    let t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalTee(t));
    ctx.emit(we::Instruction::LocalGet(t));
    ctx.emit(we::Instruction::Call(rt_index("rt_retain")?));
    Ok(())
}

/// An array with a zero dimension scalarizes to nothing, so no slot range holds
/// it and no `SimVar` names it: build it from the declared shape alone, as C's
/// `hasZeroDimension` arm of `daeExpCrefRhs` does.
fn try_emit_empty_sim_array(ctx: &mut FnCtx, cref: &DAE::ComponentRef) -> Result<bool> {
    let ty = cref_leaf_value_type(cref)?;
    let dims = type_array_dims(&ty);
    if !dims.iter().any(|d| dim_is_zero(d)) {
        return Ok(false);
    }
    let SigTy::Array { elem, .. } = sig_ty(&ty)? else { return Ok(false) };
    let obj = ctx.alloc_temp(WTy::I32);
    emit_array_alloc(ctx, obj, &elem, &dims)?;
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(true)
}

/// A whole array or slice whose elements have slots but no group (mixed variable
/// kinds, Jacobian seed/pDER scratch): C's `daeExpCrefRhsArrayBox`. A constant
/// selection is boxed directly; run-time subscripts box the whole array and index
/// or slice it at run time.
fn try_emit_sim_array_box(ctx: &mut FnCtx, cref: &DAE::ComponentRef) -> Result<Option<WTy>> {
    let Some((leaf_ty, leaf_subs)) = cref_leaf(cref) else { return Ok(None) };
    let Ok(dims) = const_dims(leaf_ty) else { return Ok(None) };
    let elem = match sig_ty_quiet(array_elem_type(leaf_ty)) {
        Ok(s @ (SigTy::Real | SigTy::Int | SigTy::Bool | SigTy::Str | SigTy::Record { .. })) => s,
        _ => return Ok(None),
    };
    let subs: Vec<&Arc<DAE::Subscript>> = (&**leaf_subs).into_iter().collect();
    if dims.is_empty() || subs.len() > dims.len() {
        return Ok(None);
    }
    // Per axis: the selected 1-based indices, and whether the axis survives.
    let mut axes: Vec<(Vec<i32>, bool)> = Vec::with_capacity(dims.len());
    for (k, &d) in dims.iter().enumerate() {
        let whole = ((1..=d as i32).collect(), true);
        axes.push(match subs.get(k).map(|s| &***s) {
            None | Some(DAE::Subscript::WHOLEDIM) | Some(DAE::Subscript::WHOLE_NONEXP { .. }) => whole,
            Some(DAE::Subscript::INDEX { exp }) => match const_index_value(exp) {
                Some(i) => (vec![i], false),
                None => return box_then_select(ctx, cref, &dims, &elem, leaf_subs),
            },
            Some(DAE::Subscript::SLICE { exp }) => match const_index_list(exp) {
                Some(v) => (v, true),
                None => return box_then_select(ctx, cref, &dims, &elem, leaf_subs),
            },
        });
    }
    if axes.iter().all(|(_, keep)| !keep) {
        return Ok(None);
    }
    emit_sim_array_box(ctx, cref, &axes, &elem)?;
    Ok(Some(WTy::I32))
}

/// Box the whole array, then apply the run-time subscripts to the boxed value.
fn box_then_select(
    ctx: &mut FnCtx,
    cref: &DAE::ComponentRef,
    dims: &[u32],
    elem: &SigTy,
    subs: &List<Arc<DAE::Subscript>>,
) -> Result<Option<WTy>> {
    let axes: Vec<(Vec<i32>, bool)> = dims.iter().map(|&d| ((1..=d as i32).collect(), true)).collect();
    emit_sim_array_box(ctx, cref, &axes, elem)?;
    let rank = dims.len() as u32;
    if !is_scalar_index(subs, rank) {
        return slice_loaded(ctx, subs).map(Some);
    }
    let obj = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(obj));
    ctx.emit(we::Instruction::LocalGet(obj));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")?));
    emit_sim_flat_index(ctx, dims, &index_subscripts(subs, rank)?)?;
    let (_, stride) = sim_array_elem_kind_stride(elem.wty());
    ctx.emit(we::Instruction::I32Const(stride as i32));
    ctx.emit(we::Instruction::I32Mul);
    ctx.emit(we::Instruction::I32Add);
    let wty = elem.wty();
    match wty {
        WTy::F64 => ctx.emit(we::Instruction::F64Load(mem_arg(0, 3))),
        WTy::I32 => ctx.emit(we::Instruction::I32Load(mem_arg(0, 2))),
    }
    emit_retain_top(ctx, elem.is_heap())?;
    release_temp_array(ctx, obj)?;
    Ok(Some(wty))
}

/// A fresh array of the elements `axes` select, row-major, each read through its
/// own cref (a record element gathers its fields). Leaves the owned handle.
fn emit_sim_array_box(
    ctx: &mut FnCtx,
    cref: &DAE::ComponentRef,
    axes: &[(Vec<i32>, bool)],
    elem: &SigTy,
) -> Result<()> {
    let out_dims: Vec<u32> = axes.iter().filter(|(_, keep)| *keep).map(|(v, _)| v.len() as u32).collect();
    let total: u32 = out_dims.iter().product();
    let (ek, stride) = (elem.elem_kind(), sim_array_elem_kind_stride(elem.wty()).1);
    let obj = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(ek as i32));
    ctx.emit(we::Instruction::I32Const(out_dims.len() as i32));
    ctx.emit(we::Instruction::I32Const(total as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")?));
    ctx.emit(we::Instruction::LocalSet(obj));
    for (axis, d) in out_dims.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::I32Const(*d as i32));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")?));
    }
    let data = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalGet(obj));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")?));
    ctx.emit(we::Instruction::LocalSet(data));
    for k in 0..total {
        let mut rem = k as usize;
        let mut index = vec![0i32; axes.len()];
        for (axis, (sel, _)) in axes.iter().enumerate().rev() {
            index[axis] = sel[rem % sel.len()];
            rem /= sel.len();
        }
        let elem_cref = cref_with_leaf_subs(cref, &index);
        ctx.emit(we::Instruction::LocalGet(data));
        let w = if matches!(elem, SigTy::Record { .. }) {
            if !try_emit_sim_record_gather(ctx, &elem_cref)? {
                return Err("CodegenWasmJit: array element is not a record variable");
            }
            WTy::I32
        } else {
            compile_sim_cref_read(ctx, &elem_cref)?
                .ok_or("CodegenWasmJit: array element is not a simulation variable")?
        };
        coerce(ctx, w, elem.wty());
        let off = k * stride;
        match elem.wty() {
            WTy::F64 => ctx.emit(we::Instruction::F64Store(mem_arg(off, 3))),
            WTy::I32 => ctx.emit(we::Instruction::I32Store(mem_arg(off, 2))),
        }
    }
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(())
}

fn cref_leaf(cr: &DAE::ComponentRef) -> Option<(&DAE::Type, &List<Arc<DAE::Subscript>>)> {
    use DAE::ComponentRef as C;
    match cr {
        C::CREF_QUAL { componentRef, .. } => cref_leaf(componentRef),
        C::CREF_IDENT { identType, subscriptLst, .. } => Some((identType, subscriptLst)),
        _ => None,
    }
}

fn array_elem_type(ty: &DAE::Type) -> &DAE::Type {
    match ty {
        DAE::Type::T_ARRAY { ty, .. } => array_elem_type(ty),
        other => other,
    }
}

/// `cr` with its leaf subscripts replaced by the constant element index.
fn cref_with_leaf_subs(cr: &DAE::ComponentRef, index: &[i32]) -> Arc<DAE::ComponentRef> {
    use DAE::ComponentRef as C;
    match cr {
        C::CREF_IDENT { ident, identType, .. } => Arc::new(C::CREF_IDENT {
            ident: ident.clone(),
            identType: identType.clone(),
            subscriptLst: index
                .iter()
                .map(|i| Arc::new(DAE::Subscript::INDEX { exp: Arc::new(DAE::Exp::ICONST { integer: *i }) }))
                .collect(),
        }),
        C::CREF_QUAL { ident, identType, subscriptLst, componentRef } => Arc::new(C::CREF_QUAL {
            ident: ident.clone(),
            identType: identType.clone(),
            subscriptLst: subscriptLst.clone(),
            componentRef: cref_with_leaf_subs(componentRef, index),
        }),
        other => Arc::new(other.clone()),
    }
}

/// The 1-based indices a constant `SLICE` subscript selects: `lo:hi`, `lo:s:hi`
/// or `{i, j, …}` of literals.
fn const_index_list(exp: &DAE::Exp) -> Option<Vec<i32>> {
    match exp {
        DAE::Exp::RANGE { start, step, stop, .. } => {
            let lo = const_index_value(start)?;
            let hi = const_index_value(stop)?;
            let step = step.as_ref().map_or(Some(1), |e| const_index_value(e))?;
            if step == 0 {
                return None;
            }
            let mut out = Vec::new();
            let mut i = lo;
            while if step > 0 { i <= hi } else { i >= hi } {
                out.push(i);
                i += step;
            }
            Some(out)
        }
        DAE::Exp::ARRAY { array, .. } => (&**array).into_iter().map(|e| const_index_value(e)).collect(),
        _ => None,
    }
}

/// C's `Expression.hasZeroDimension` for one dimension: a size known to be zero.
/// An unknown (`:`) dimension is not one — it says nothing about the shape.
fn dim_is_zero(dim: &DAE::Dimension) -> bool {
    match dim {
        DAE::Dimension::DIM_INTEGER { integer } => *integer == 0,
        DAE::Dimension::DIM_ENUM { size, .. } => *size == 0,
        DAE::Dimension::DIM_EXP { exp } => matches!(&**exp, DAE::Exp::ICONST { integer: 0 }),
        _ => false,
    }
}

/// [`emit_sim_array_gather`] for a constant array: nothing to copy from, each
/// element is its own literal.
fn emit_const_array(ctx: &mut FnCtx, key: &str) -> Result<()> {
    let group = ctx.sim()?.const_groups.get(key).ok_or("CodegenWasmJit: not a constant array")?;
    let (wty, dims, values) = (group.wty, group.dims.clone(), group.values.clone());
    let (ek, stride) = sim_array_elem_kind_stride(wty);
    let obj = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(ek as i32));
    ctx.emit(we::Instruction::I32Const(dims.len() as i32));
    ctx.emit(we::Instruction::I32Const(values.len() as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")?));
    ctx.emit(we::Instruction::LocalSet(obj));
    for (axis, d) in dims.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::I32Const(*d as i32));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")?));
    }
    let data = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalGet(obj));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")?));
    ctx.emit(we::Instruction::LocalSet(data));
    for (i, exp) in values.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(data));
        let w = compile_exp(ctx, exp)?;
        coerce(ctx, w, wty);
        let off = i as u32 * stride;
        match wty {
            WTy::F64 => ctx.emit(we::Instruction::F64Store(mem_arg(off, 3))),
            WTy::I32 => ctx.emit(we::Instruction::I32Store(mem_arg(off, 2))),
        }
    }
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(())
}

/// If `cref` names a whole record model variable (its leaf, after subscripts, is
/// a record), build a fresh runtime record from the scalar `SimData` slots of
/// its fields and leave the owned handle on the stack. Each field is read through
/// its own extended cref, so nested records / arrays-of-records gather
/// recursively. Returns `Ok(true)` when it handled the reference.
fn try_emit_sim_record_gather(ctx: &mut FnCtx, cref: &DAE::ComponentRef) -> Result<bool> {
    let leaf_ty = cref_leaf_value_type(cref)?;
    let Some(fields) = record_fields(&leaf_ty)? else {
        return Ok(false);
    };
    let layout = rec_layout(&fields);
    let obj = emit_record_alloc(ctx, &layout)?;
    for (i, f) in fields.iter().enumerate() {
        let fty = f.sig.clone();
        let field_cref = cref_append_field(cref, &f.name, f.ty.clone());
        let wty = compile_sim_cref_read(ctx, &field_cref)?
            .ok_or("CodegenWasmJit: record field is not a simulation variable")?;
        coerce(ctx, wty, fty.wty());
        let vt = ctx.alloc_temp(fty.wty());
        ctx.emit(we::Instruction::LocalSet(vt));
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::LocalGet(vt));
        field_store(ctx, fty.wty(), layout.data_off + layout.field_off[i]);
    }
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(true)
}

/// The inverse of [`try_emit_sim_record_gather`]: evaluate `rhs` to an owned
/// record and store each field into its own `SimData` slot, as the C target does
/// for `$cse1 := f(...)`. Fields go through their own cref, so nested records and
/// array fields scatter recursively.
fn try_emit_sim_record_scatter(ctx: &mut FnCtx, cref: &DAE::ComponentRef, rhs: RhsSource) -> Result<bool> {
    let leaf_ty = cref_leaf_value_type(cref)?;
    let Some(fields) = record_fields(&leaf_ty)? else {
        return Ok(false);
    };
    let layout = rec_layout(&fields);
    let obj = ctx.alloc_temp(WTy::I32);
    let rw = rhs.push(ctx)?;
    if rw != WTy::I32 {
        return Err("CodegenWasmJit: whole-record assignment rhs is not a record handle");
    }
    ctx.emit(we::Instruction::LocalSet(obj));
    for (i, f) in fields.iter().enumerate() {
        let fty = f.sig.clone();
        let vt = ctx.alloc_temp(fty.wty());
        ctx.emit(we::Instruction::LocalGet(obj));
        field_load(ctx, fty.wty(), layout.data_off + layout.field_off[i]);
        ctx.emit(we::Instruction::LocalSet(vt));
        if fty.is_heap() {
            // The record keeps its reference; the assignment consumes one.
            ctx.emit(we::Instruction::LocalGet(vt));
            ctx.emit(we::Instruction::Call(rt_index("rt_retain")?));
        }
        let field_cref = cref_append_field(cref, &f.name, f.ty.clone());
        if !compile_sim_cref_assign(ctx, &field_cref, RhsSource::Temp { local: vt, wty: fty.wty() })? {
            return Err("CodegenWasmJit: record field is not a simulation variable");
        }
    }
    ctx.emit(we::Instruction::LocalGet(obj));
    ctx.emit(we::Instruction::Call(rt_index("rt_record_release")?));
    Ok(true)
}

/// Emit code that scatters a whole-array assignment into a model variable's
/// contiguous `SimData` slot range: evaluate `rhs` to an owned runtime array,
/// `memory.copy` its (row-major, scalar) element data over the slots, then
/// release the handle. Real/Integer elements are flat scalars, so the bulk copy
/// is a complete (deep) value copy — no per-element retain is needed.
fn emit_sim_array_scatter(ctx: &mut FnCtx, group: &ArrayGroup, rhs: RhsSource) -> Result<()> {
    let (_, stride) = sim_array_elem_kind_stride(group.wty);
    let data = ctx.sim()?.data_local;
    let h = ctx.alloc_temp(WTy::I32);
    let rw = rhs.push(ctx)?;
    if rw != WTy::I32 {
        return Err("CodegenWasmJit: whole-array assignment rhs is not an array handle");
    }
    ctx.emit(we::Instruction::LocalSet(h));
    // A String array's slots own their handles: drop what they held before the
    // copy overwrites them.
    emit_slot_range_refcount(ctx, group, "rt_release")?;
    // memory.copy(dst = SimData + base_off, src = rhs data, len = total * stride).
    ctx.emit(we::Instruction::LocalGet(data));
    ctx.emit(we::Instruction::I32Const(group.base_off as i32));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalGet(h));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")?));
    ctx.emit(we::Instruction::I32Const((group.total * stride) as i32));
    ctx.emit(we::Instruction::MemoryCopy { src_mem: 0, dst_mem: 0 });
    // …and take one on what it handed over, since the release below frees the
    // rhs array's own references to them.
    emit_slot_range_refcount(ctx, group, "rt_retain")?;
    // Consume the rhs reference (we copied out the element data, not the handle).
    ctx.emit(we::Instruction::LocalGet(h));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_release")?));
    Ok(())
}

/// Call `f` on every slot of a heap-element array group; nothing for a value type.
fn emit_slot_range_refcount(ctx: &mut FnCtx, group: &ArrayGroup, f: &str) -> Result<()> {
    use we::Instruction as I;
    if !group.heap {
        return Ok(());
    }
    let data = ctx.sim()?.data_local;
    let i = ctx.alloc_temp(WTy::I32);
    ctx.emit(I::I32Const(0));
    ctx.emit(I::LocalSet(i));
    ctx.emit(I::Block(we::BlockType::Empty));
    ctx.emit(I::Loop(we::BlockType::Empty));
    ctx.emit(I::LocalGet(i));
    ctx.emit(I::I32Const(group.total as i32));
    ctx.emit(I::I32GeU);
    ctx.emit(I::BrIf(1));
    ctx.emit(I::LocalGet(data));
    ctx.emit(I::LocalGet(i));
    ctx.emit(I::I32Const(4));
    ctx.emit(I::I32Mul);
    ctx.emit(I::I32Add);
    ctx.emit(I::I32Load(mem_arg(group.base_off, 2)));
    ctx.emit(I::Call(rt_index(f)?));
    ctx.emit(I::LocalGet(i));
    ctx.emit(I::I32Const(1));
    ctx.emit(I::I32Add);
    ctx.emit(I::LocalSet(i));
    ctx.emit(I::Br(0));
    ctx.emit(I::End);
    ctx.emit(I::End);
    Ok(())
}

/// Push a scalar variable's `$START` value: its overridable start slot, else its
/// start expression, else `0.0`. `None` (nothing emitted) if `key` has no start.
fn emit_sim_start_scalar(ctx: &mut FnCtx, key: &str) -> Result<Option<WTy>> {
    if let Some(&off) = ctx.sim()?.start_slots.get(key) {
        let data = ctx.sim()?.data_local;
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::F64Load(mem_arg(off, 3)));
        return Ok(Some(WTy::F64));
    }
    match ctx.sim()?.starts.get(key).cloned() {
        Some(Some(exp)) => Ok(Some(compile_exp(ctx, &exp)?)),
        Some(None) => {
            ctx.emit(we::Instruction::F64Const(0.0.into()));
            Ok(Some(WTy::F64))
        }
        None => Ok(None),
    }
}

/// Gather a whole array's per-element `$START` values into a fresh (refcount-1)
/// runtime array object, leaving the owned handle on the stack.
fn emit_sim_start_array_gather(ctx: &mut FnCtx, group: &ArrayGroup, base_key: &str) -> Result<()> {
    let (ek, stride) = sim_array_elem_kind_stride(group.wty);
    let ndims = group.dims.len() as u32;
    let obj = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(ek as i32));
    ctx.emit(we::Instruction::I32Const(ndims as i32));
    ctx.emit(we::Instruction::I32Const(group.total as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")?));
    ctx.emit(we::Instruction::LocalSet(obj));
    for (axis, d) in group.dims.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::I32Const(*d as i32));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")?));
    }
    for (lin, idx) in crate::CodegenWasmJit::row_major_indices(&group.dims).into_iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(1));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")?));
        if lin > 0 {
            ctx.emit(we::Instruction::I32Const((lin as u32 * stride) as i32));
            ctx.emit(we::Instruction::I32Add);
        }
        let wty = emit_sim_start_scalar(ctx, &group.elem_key(&idx))?
            .ok_or("CodegenWasmJit: $START for unknown array element")?;
        coerce(ctx, wty, group.wty);
        match group.wty {
            WTy::F64 => ctx.emit(we::Instruction::F64Store(mem_arg(0, 3))),
            WTy::I32 => ctx.emit(we::Instruction::I32Store(mem_arg(0, 2))),
        }
    }
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(())
}
