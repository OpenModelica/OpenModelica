//! Assignments: scalar, tuple, fresh-value stores into locals, fields,
//! elements and crefs.

use super::*;

pub(super) fn compile_stmts(ctx: &mut FnCtx, stmts: &List<Arc<DAE::Statement>>) -> Result<()> {
    for s in &**stmts {
        compile_stmt(ctx, s)?;
    }
    Ok(())
}

/// Assign `rhs` to a lhs: a whole-variable (scalar / whole array / string) or a
/// subscripted array element (`a[i,...] := x`, written in place).
pub(super) fn compile_assign(ctx: &mut FnCtx, lhs: &DAE::Exp, rhs: &DAE::Exp) -> Result<()> {
    // `(l1, l2, …) = f(...)` in a when-equation (C's `whenOperators` ASSIGN-of-TUPLE).
    if let DAE::Exp::TUPLE { PR } = lhs {
        return compile_tuple_assign(ctx, PR, rhs);
    }
    let DAE::Exp::CREF { componentRef, .. } = lhs else {
        crate::CodegenWasmJit::record_error(format!(
            "CodegenWasmJit: assignment to non-cref lhs `{}`",
            dumped_exp(&Arc::new(lhs.clone()))?
        ));
        return Err("CodegenWasmJit: assignment to non-cref lhs not supported");
    };
    // Simulation mode: assigning to a model variable writes into the shared
    // `SimData` block. Returns false for an ordinary wasm local handled below.
    if compile_sim_cref_assign(ctx, componentRef, RhsSource::Exp(rhs))? {
        return Ok(());
    }
    // A qualified-cref assignment `base[..].f1[..].….fn[..] := rhs`: navigate to
    // the record holding the final field, then store into it.
    if let DAE::ComponentRef::CREF_QUAL { .. } = &**componentRef {
        return compile_cref_assign_qual(ctx, componentRef, rhs);
    }
    let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = &**componentRef else {
        return Err("CodegenWasmJit: assignment to qualified/record lhs not supported");
    };
    let name = ident.to_string();
    let (idx, dst_sty) = ctx
        .locals
        .get(&name)
        .ok_or_else(|| {
            crate::CodegenWasmJit::record_error(format!(
                "CodegenWasmJit: assignment to unknown variable `{name}`{}",
                fn_context()
            ));
            "CodegenWasmJit: assignment to unknown variable"
        })?
        .clone();

    if !subscriptLst.is_empty() {
        // Element assignment `a[i,...] := x` — written in place into the local's
        // own (private) array, so no copy-on-write is needed (Modelica arrays are
        // mutable value objects; aliasing is broken at whole-array assignment).
        let SigTy::Array { elem, rank } = dst_sty else {
            return Err("CodegenWasmJit: subscripting non-array local");
        };
        if !is_scalar_index(subscriptLst, rank) {
            return compile_slice_assign(ctx, idx, subscriptLst, RhsSource::Exp(rhs));
        }
        let idx_exps = index_subscripts(subscriptLst, rank)?;
        return compile_elem_assign(ctx, idx, &elem, &idx_exps, rhs);
    }

    let src_wty = compile_exp(ctx, rhs)?;
    // Value semantics for arrays and records: a whole-value assignment from
    // anything that is not a fresh constructor/call result would otherwise share
    // the source's mutable buffer (the rhs is a retained alias), so mutating the
    // destination later would corrupt the source — copy it to a private object.
    // A fresh rhs is already privately owned and is moved in. (Strings are
    // immutable, so they are shared via the retain on read — no copy.)
    if let Some((copy_fn, rel_fn)) = value_copy_fns(&dst_sty) {
        if !value_rhs_is_fresh(rhs) {
            let t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(t));
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::Call(rt_index(copy_fn)?));
            // Release the alias we copied from (the rhs's +1 reference).
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::Call(rt_index(rel_fn)?));
        }
    }
    if let Some(release_fn) = dst_sty.release_fn() {
        // Release-on-overwrite: free the previous value the local held *after*
        // computing the new one (which may read the old value, as in `s := s + x`),
        // then move the new owned value in. Stack: [new] -> release old -> store.
        ctx.emit(we::Instruction::LocalGet(idx));
        ctx.emit(we::Instruction::Call(rt_index(release_fn)?));
        ctx.emit(we::Instruction::LocalSet(idx));
    } else {
        coerce(ctx, src_wty, dst_sty.wty());
        ctx.emit(we::Instruction::LocalSet(idx));
    }
    Ok(())
}

/// Store a freshly-owned value held in temp `vt` into simple local `idx` of type
/// `dst_sty`, releasing the local's previous value first (release-on-overwrite).
/// The value must already be privately owned (a call/constructor result), so no
/// value-semantics copy is made. Used by tuple assignment.
fn store_fresh_into_local(ctx: &mut FnCtx, idx: u32, dst_sty: &SigTy, vt: u32) -> Result<()> {
    if let Some(release_fn) = dst_sty.release_fn() {
        // [new] -> release old -> store new.
        ctx.emit(we::Instruction::LocalGet(vt));
        ctx.emit(we::Instruction::LocalGet(idx));
        ctx.emit(we::Instruction::Call(rt_index(release_fn)?));
        ctx.emit(we::Instruction::LocalSet(idx));
    } else {
        ctx.emit(we::Instruction::LocalGet(vt));
        ctx.emit(we::Instruction::LocalSet(idx));
    }
    Ok(())
}

/// Store a freshly-owned value held in temp `vt` into record field `name` of the
/// record whose handle is in local/temp `rec_idx`, releasing the previous field
/// value first. The value is already owned (a call result), so no copy is made.
pub(super) fn store_fresh_into_field(ctx: &mut FnCtx, rec_idx: u32, fields: &[(ArcStr, SigTy)], name: &str, vt: u32) -> Result<()> {
    let (off, fty) = record_field(fields, name)?;
    if let Some(release_fn) = fty.release_fn() {
        ctx.emit(we::Instruction::LocalGet(rec_idx));
        field_load(ctx, fty.wty(), off);
        ctx.emit(we::Instruction::Call(rt_index(release_fn)?));
    }
    ctx.emit(we::Instruction::LocalGet(rec_idx));
    ctx.emit(we::Instruction::LocalGet(vt));
    field_store(ctx, fty.wty(), off);
    Ok(())
}

/// Store a freshly-owned value held in temp `vt` into array element
/// `arr[idx_exps...]` (the array local privately owns its buffer), releasing the
/// previous element first. The value is already owned, so no copy is made.
fn store_fresh_into_elem(ctx: &mut FnCtx, arr_idx: u32, elem: &SigTy, idx_exps: &[Arc<DAE::Exp>], vt: u32) -> Result<()> {
    emit_elem_addr(ctx, arr_idx, elem, idx_exps)?;
    let addr_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(addr_t));
    if let Some(release_fn) = elem.release_fn() {
        ctx.emit(we::Instruction::LocalGet(addr_t));
        elem_load(ctx, elem);
        ctx.emit(we::Instruction::Call(rt_index(release_fn)?));
    }
    ctx.emit(we::Instruction::LocalGet(addr_t));
    ctx.emit(we::Instruction::LocalGet(vt));
    elem_store(ctx, elem);
    Ok(())
}

/// Store a freshly-owned value held in temp `vt` into an arbitrary cref target
/// (simple local, array element, or record field — possibly a subscripted
/// field). Used by tuple assignment, where each result is already computed.
fn store_fresh_into_cref(ctx: &mut FnCtx, cref: &DAE::ComponentRef, wty: WTy, vt: u32) -> Result<()> {
    // A target naming a model variable (not a wasm local) stores into SimData;
    // `false` means an ordinary local, handled below.
    if compile_sim_cref_assign(ctx, cref, RhsSource::Temp { local: vt, wty })? {
        return Ok(());
    }
    if let DAE::ComponentRef::CREF_QUAL { .. } = cref {
        let (rec, fields, leaf, lsubs) = navigate_qual(ctx, cref)?;
        if lsubs.is_empty() {
            store_fresh_into_field(ctx, rec, &fields, leaf, vt)?;
        } else {
            let (off, fty) = record_field(&fields, leaf)?;
            let SigTy::Array { elem, rank } = fty else {
                return Err("CodegenWasmJit: subscripted field is not an array");
            };
            let arr_t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalGet(rec));
            field_load(ctx, WTy::I32, off);
            ctx.emit(we::Instruction::LocalSet(arr_t));
            if !is_scalar_index(lsubs, rank) {
                return compile_slice_assign(ctx, arr_t, lsubs, RhsSource::Temp { local: vt, wty });
            }
            let idx_exps = index_subscripts(lsubs, rank)?;
            store_fresh_into_elem(ctx, arr_t, &elem, &idx_exps, vt)?;
        }
        return Ok(());
    }
    let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = cref else {
        return Err("CodegenWasmJit: unsupported tuple-assignment target");
    };
    let name = ident.to_string();
    let (idx, dst_sty) = ctx
        .locals
        .get(&name)
        .ok_or_else(|| "CodegenWasmJit: tuple assignment to unknown variable")?
        .clone();
    if subscriptLst.is_empty() {
        return store_fresh_into_local(ctx, idx, &dst_sty, vt);
    }
    let SigTy::Array { elem, rank } = dst_sty else {
        return Err("CodegenWasmJit: subscripting non-array local");
    };
    if !is_scalar_index(subscriptLst, rank) {
        return compile_slice_assign(ctx, idx, subscriptLst, RhsSource::Temp { local: vt, wty });
    }
    let idx_exps = index_subscripts(subscriptLst, rank)?;
    store_fresh_into_elem(ctx, idx, &elem, &idx_exps, vt)
}

/// Lower `(l1, l2, …) := f(args)` (`STMT_TUPLE_ASSIGN`): call the multi-output
/// generated function (which leaves its results on the stack, first result
/// deepest), then move each owned result into its target local. A `_` (wildcard)
/// target discards its value (releasing it if heap).
pub(super) fn compile_tuple_assign(ctx: &mut FnCtx, lhs: &List<Arc<DAE::Exp>>, call: &DAE::Exp) -> Result<()> {
    let DAE::Exp::CALL { path, expLst, attr } = call else {
        return Err("CodegenWasmJit: tuple assignment rhs is not a function call");
    };
    let lhs_v: Vec<&Arc<DAE::Exp>> = (&**lhs).into_iter().collect();
    let results = compile_call(ctx, path, expLst, attr)?;
    // Trailing outputs the statement does not name are dropped, as in
    // `algStmtTupleAssign`.
    if results.len() < lhs_v.len() {
        return Err("CodegenWasmJit: tuple assignment names more targets than the call returns");
    }
    // Pop the results into temps (the last result is on top of the stack).
    let mut temps = vec![0u32; results.len()];
    for i in (0..results.len()).rev() {
        let vt = ctx.alloc_temp(results[i].wty());
        ctx.emit(we::Instruction::LocalSet(vt));
        temps[i] = vt;
    }
    for i in lhs_v.len()..results.len() {
        if let Some(release_fn) = results[i].release_fn() {
            ctx.emit(we::Instruction::LocalGet(temps[i]));
            ctx.emit(we::Instruction::Call(rt_index(release_fn)?));
        }
    }
    for (i, lhs_exp) in lhs_v.iter().enumerate() {
        store_fresh_into_tuple_target(ctx, lhs_exp, &results[i], temps[i])?;
    }
    Ok(())
}

/// Leave only result `want` of a call on the stack (first result deepest),
/// releasing the discarded ones.
pub(super) fn keep_call_result(ctx: &mut FnCtx, results: &[SigTy], want: usize) -> Result<WTy> {
    if results.len() == 1 {
        return Ok(results[0].wty());
    }
    let mut temps = vec![0u32; results.len()];
    for i in (0..results.len()).rev() {
        let vt = ctx.alloc_temp(results[i].wty());
        ctx.emit(we::Instruction::LocalSet(vt));
        temps[i] = vt;
    }
    for (i, sty) in results.iter().enumerate() {
        if i == want {
            continue;
        }
        if let Some(release_fn) = sty.release_fn() {
            ctx.emit(we::Instruction::LocalGet(temps[i]));
            ctx.emit(we::Instruction::Call(rt_index(release_fn)?));
        }
    }
    ctx.emit(we::Instruction::LocalGet(temps[want]));
    Ok(results[want].wty())
}

/// Store one freshly-owned tuple result into its target expression.
fn store_fresh_into_tuple_target(ctx: &mut FnCtx, target: &DAE::Exp, sty: &SigTy, vt: u32) -> Result<()> {
    use DAE::Exp as E;
    match target {
        E::CREF { componentRef, ty } => {
            // `_` output: discard (release a heap value).
            if let DAE::ComponentRef::WILD = &**componentRef {
                if let Some(release_fn) = sty.release_fn() {
                    ctx.emit(we::Instruction::LocalGet(vt));
                    ctx.emit(we::Instruction::Call(rt_index(release_fn)?));
                }
                return Ok(());
            }
            // An `Integer` output can land in a `Real` target with no cast in the
            // statement (`Modelica.Math.Vectors.interpolate`'s `iNew`); C stores
            // through the target's own type, so convert to it here.
            let dst = sig_ty_quiet(ty).map(|s| s.wty()).unwrap_or_else(|_| sty.wty());
            let vt = if dst == sty.wty() {
                vt
            } else {
                let t = ctx.alloc_temp(dst);
                ctx.emit(we::Instruction::LocalGet(vt));
                coerce(ctx, sty.wty(), dst);
                ctx.emit(we::Instruction::LocalSet(t));
                t
            };
            store_fresh_into_cref(ctx, componentRef, dst, vt)
        }
        // Alias elimination replaces a record-valued target by its components, as a
        // constructor call or a `RECORD` (C's `tupleReturnVariableUpdates`).
        E::RECORD { exps, .. } => scatter_record_target(ctx, exps, sty, vt),
        E::CALL { expLst, .. } => scatter_record_target(ctx, expLst, sty, vt),
        _ => Err("CodegenWasmJit: unsupported tuple-assignment target"),
    }
}

/// Scatter the freshly-owned record in `vt` into `targets` (one per field, in
/// declaration order), then release it.
fn scatter_record_target(
    ctx: &mut FnCtx,
    targets: &List<Arc<DAE::Exp>>,
    sty: &SigTy,
    vt: u32,
) -> Result<()> {
    let SigTy::Record { fields, .. } = sty else {
        return Err("CodegenWasmJit: record-destructuring tuple target for a non-record output");
    };
    let targets: Vec<&Arc<DAE::Exp>> = targets.into_iter().collect();
    if targets.len() != fields.len() {
        return Err("CodegenWasmJit: record-destructuring tuple target has the wrong field count");
    }
    let layout = record_layout(fields);
    for (i, (_, fty)) in fields.iter().enumerate() {
        let ft = ctx.alloc_temp(fty.wty());
        ctx.emit(we::Instruction::LocalGet(vt));
        field_load(ctx, fty.wty(), layout.data_off + layout.field_off[i]);
        ctx.emit(we::Instruction::LocalSet(ft));
        if fty.is_heap() {
            // The record still holds its reference; the store consumes one.
            ctx.emit(we::Instruction::LocalGet(ft));
            ctx.emit(we::Instruction::Call(rt_index("rt_retain")?));
        }
        store_fresh_into_tuple_target(ctx, targets[i], fty, ft)?;
    }
    ctx.emit(we::Instruction::LocalGet(vt));
    ctx.emit(we::Instruction::Call(rt_index("rt_record_release")?));
    Ok(())
}

/// The (copy, release) runtime entry points for a mutable value type that needs
/// a private copy on aliasing assignment, or `None` for scalars and immutable
/// strings.
pub(super) fn value_copy_fns(ty: &SigTy) -> Option<(&'static str, &'static str)> {
    match ty {
        SigTy::Array { .. } => Some(("rt_array_copy", "rt_array_release")),
        SigTy::Record { .. } => Some(("rt_record_copy", "rt_record_release")),
        _ => None,
    }
}

/// Whether a whole-value rhs expression produces a freshly-owned array/record
/// (so it can be moved into the destination without copying). Constructors,
/// ranges and call results are fresh; a variable reference / shared literal
/// aliases an existing object.
pub(super) fn value_rhs_is_fresh(e: &DAE::Exp) -> bool {
    use DAE::Exp as E;
    if shared_lits::is_shared(e) {
        return false;
    }
    match e {
        E::ARRAY { .. } | E::MATRIX { .. } | E::RANGE { .. } | E::CALL { .. } | E::RECORD { .. } => true,
        E::SHARED_LITERAL { exp, .. } | E::CAST { exp, .. } => value_rhs_is_fresh(exp),
        _ => false,
    }
}
