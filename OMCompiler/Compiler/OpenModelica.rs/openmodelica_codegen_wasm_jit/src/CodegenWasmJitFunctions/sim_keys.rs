//! Model-variable keys: pre/der/clkpre crefs, `sim_cref_key`, array-ref
//! and slice decomposition.

use super::*;

/// Does `$PRE.<x>` have pre-storage — its own scalar slot, or a subscripted
/// element of a `$PRE` array group? A whole-array `pre(x)` deliberately does not
/// count: C's `daeExpCrefRhsSimContext` wraps the live `<type>Vars` region for it,
/// never `<type>VarsPre`.
pub(super) fn sim_pre_is_stored(ctx: &FnCtx, cref: &DAE::ComponentRef) -> Result<bool> {
    let sim = ctx.sim()?;
    if let Ok(key) = sim_cref_key(cref) {
        if sim.vars.contains_key(&key) {
            return Ok(true);
        }
    }
    if let Some((base, _)) = array_ref_of(cref)? {
        if sim.array_groups.contains_key(&base) || sim.scatter_groups.contains_key(&base) {
            return Ok(true);
        }
    }
    match sim_array_base_subs(cref)? {
        Some((base, _)) => {
            Ok(sim.array_groups.contains_key(&base) || sim.scatter_groups.contains_key(&base))
        }
        None => Ok(false),
    }
}

/// [`sim_pre_is_stored`] for an assignment *target*: a whole-array `$PRE.x := …`
/// keeps the prefix in C where its right-hand side drops it, so the write must
/// land on the pre-value mirror and not on the live array.
pub(super) fn sim_pre_is_stored_lhs(ctx: &FnCtx, cref: &DAE::ComponentRef) -> Result<bool> {
    if sim_pre_is_stored(ctx, cref)? {
        return Ok(true);
    }
    let sim = ctx.sim()?;
    match sim_cref_key(cref) {
        Ok(key) => Ok(sim.array_groups.contains_key(&key) || sim.scatter_groups.contains_key(&key)),
        Err(_) => Ok(false),
    }
}

/// The `previous(cr)` component reference: `cr` wrapped in `DAE.previousNamePrefix`,
/// the variable the backend introduced for it (key `$CLKPRE.<cr>`).
pub(super) fn clkpre_cref(cr: &DAE::ComponentRef) -> Arc<DAE::ComponentRef> {
    use DAE::ComponentRef as C;
    let identType = match cr {
        C::CREF_IDENT { identType, .. } | C::CREF_QUAL { identType, .. } => identType.clone(),
        _ => crate::CodegenWasmJit::t_real(),
    };
    Arc::new(C::CREF_QUAL {
        ident: arcstr::literal!("$CLKPRE"),
        identType,
        subscriptLst: metamodelica::nil(),
        componentRef: Arc::new(cr.clone()),
    })
}

/// Address of the sub-clock block `interval()`/`firstTick()` read.
pub(super) fn sub_clock_off(sim: &SimCtx, name: &str) -> Result<u32> {
    sim.sub_clock_off.ok_or_else(|| {
        crate::CodegenWasmJit::record_error(format!(
            "CodegenWasmJit: `{name}()` reads the active sub-clock, but the equation is not in a \
             clocked partition{}",
            fn_context()
        ));
        "CodegenWasmJit: clock builtin outside a clocked partition"
    })
}

/// The `der(cr)` component reference: `cr` wrapped in a `$DER` qualifier, as the
/// backend names the derivative variable (key `$DER.<cr>`).
pub(super) fn der_cref(cr: &DAE::ComponentRef) -> Arc<DAE::ComponentRef> {
    use DAE::ComponentRef as C;
    let identType = match cr {
        C::CREF_IDENT { identType, .. } | C::CREF_QUAL { identType, .. } => identType.clone(),
        _ => crate::CodegenWasmJit::t_real(),
    };
    Arc::new(C::CREF_QUAL {
        ident: arcstr::literal!("$DER"),
        identType,
        subscriptLst: metamodelica::nil(),
        componentRef: Arc::new(cr.clone()),
    })
}

pub(crate) fn sim_cref_key(cr: &DAE::ComponentRef) -> Result<String> {
    let mut s = String::new();
    sim_cref_key_into(cr, &mut s)?;
    Ok(s)
}

fn sim_cref_key_into(cr: &DAE::ComponentRef, s: &mut String) -> Result<()> {
    use DAE::ComponentRef as C;
    match cr {
        C::CREF_IDENT { ident, subscriptLst, .. } => {
            s.push_str(ident);
            sim_subs_into(subscriptLst, s)?;
        }
        C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
            s.push_str(ident);
            sim_subs_into(subscriptLst, s)?;
            s.push('.');
            sim_cref_key_into(componentRef, s)?;
        }
        other => return Err("CodegenWasmJit: unsupported component reference in simulation"),
    }
    Ok(())
}

/// [`sim_cref_key`] for the call sites with no fallback left: it names the cref in
/// a recorded message. The callers that recover must not record one.
pub(super) fn sim_cref_key_fatal(cr: &DAE::ComponentRef) -> Result<String> {
    sim_cref_key(cr).map_err(|e| {
        let shown = openmodelica_frontend_dump::ComponentReferenceBasics::printComponentRefStr(Arc::new(cr.clone()))
            .map(|s| s.to_string())
            .unwrap_or_default();
        crate::CodegenWasmJit::record_error(format!("CodegenWasmJit: cannot resolve `{shown}` to a simulation variable"));
        e
    })
}

fn sim_subs_into(subs: &List<Arc<DAE::Subscript>>, s: &mut String) -> Result<()> {
    for sub in &**subs {
        match &**sub {
            DAE::Subscript::INDEX { exp } => match &**exp {
                DAE::Exp::ICONST { integer } => {
                    s.push('[');
                    s.push_str(&integer.to_string());
                    s.push(']');
                }
                DAE::Exp::ENUM_LITERAL { index, .. } => {
                    s.push('[');
                    s.push_str(&index.to_string());
                    s.push(']');
                }
                _ => return Err("CodegenWasmJit: non-constant subscript in simulation cref"),
            },
            _ => return Err("CodegenWasmJit: unsupported subscript in simulation cref"),
        }
    }
    Ok(())
}

/// Append an intermediate component's subscripts to an array base key, spelled as
/// [`sim_cref_key`] spells them (`bodybox[1].body.R_start.T`). `false` when a
/// subscript is not a constant index, so there is no static base key.
pub(crate) fn push_qual_subs(subs: &List<Arc<DAE::Subscript>>, s: &mut String) -> bool {
    for sub in &**subs {
        match &**sub {
            DAE::Subscript::INDEX { exp } => match const_index_value(exp) {
                Some(ix) => {
                    s.push('[');
                    s.push_str(&ix.to_string());
                    s.push(']');
                }
                None => return false,
            },
            _ => return false,
        }
    }
    true
}

/// If `exp` is a constant index (`ICONST`/enum literal), its 1-based value.
/// A constant subscript outside the array's range, e.g. the `T[0]` scalarizing
/// `for i in 1:n loop ... T[i-1] ...` leaves in a branch the model never takes. C
/// emits that access too, so it lowers to the run-time error instead of failing the
/// translation. Leaves a value of the element type on the stack.
pub(super) fn emit_sim_const_index_error(ctx: &mut FnCtx, cref: &DAE::ComponentRef, key: &str) -> Result<Option<WTy>> {
    let Some((base, subs)) = array_ref_of(cref)? else { return Ok(None) };
    let Some(group) = ctx.sim()?.array_groups.get(&base).cloned() else { return Ok(None) };
    if subs.len() != group.dims.len() {
        return Ok(None);
    }
    let outside = subs
        .iter()
        .zip(&group.dims)
        .any(|(e, d)| matches!(const_index_value(e), Some(i) if i < 1 || i > *d as i32));
    if !outside {
        return Ok(None);
    }
    let dims = group.dims.iter().map(|d| d.to_string()).collect::<Vec<_>>().join(",");
    emit_runtime_error(ctx, &format!("Index out of bounds: `{key}` of array of size [{dims}]"))?;
    match group.wty {
        WTy::F64 => ctx.emit(we::Instruction::F64Const(0.0.into())),
        WTy::I32 => ctx.emit(we::Instruction::I32Const(0)),
    }
    Ok(Some(group.wty))
}

/// A Jacobian column array element (`x.$pDER<M>.dummyVar<M>[i]`) no column
/// equation defines: the backend kept only the elements that depend on the seeds,
/// so the rest are structurally zero.
pub(super) fn is_jac_column_elem_key(key: &str) -> bool {
    let Some(stem) = key.strip_suffix(']') else { return false };
    let Some((base, _)) = stem.rsplit_once('[') else { return false };
    let Some((qual, last)) = base.rsplit_once('.') else { return false };
    last.starts_with("dummyVar") && qual.rsplit('.').next().is_some_and(|m| m.starts_with("$pDER"))
}

pub(super) fn const_index_value(exp: &DAE::Exp) -> Option<i32> {
    match exp {
        DAE::Exp::ICONST { integer } => Some(*integer),
        DAE::Exp::ENUM_LITERAL { index, .. } => Some(*index),
        _ => None,
    }
}

/// If `cr` is `base[e1,…,en]` — subscripts on the *final* component — return
/// `(base cref key, subscript index expressions)`. Unlike [`sim_cref_key`], those
/// subscripts need not be constant; this backs the dynamic array-element path
/// (e.g. a `for`-loop iterator index). `None` for a plain scalar or a slice.
pub(super) fn array_ref_of(cr: &DAE::ComponentRef) -> Result<Option<(String, Vec<Arc<DAE::Exp>>)>> {
    use DAE::ComponentRef as C;
    let mut base = String::new();
    let mut exps = Vec::new();
    let mut node = cr;
    loop {
        let (ident, subscriptLst, next) = match node {
            C::CREF_IDENT { ident, subscriptLst, .. } => (ident, subscriptLst, None),
            C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
                (ident, subscriptLst, Some(componentRef))
            }
            _ => return Ok(None),
        };
        base.push_str(ident);
        for sub in &**subscriptLst {
            match &**sub {
                DAE::Subscript::INDEX { exp } => exps.push(exp.clone()),
                _ => return Ok(None), // slice / whole-dim: not an element access
            }
        }
        match next {
            Some(n) => {
                base.push('.');
                node = n;
            }
            None => return Ok(if exps.is_empty() { None } else { Some((base, exps)) }),
        }
    }
}

/// `base[i1,…,ik, :, …, :]` (leading `INDEX` subscripts, then whole dims, on the
/// final component) -> `(base key, leading index exprs)`. Such a selection is a
/// contiguous row-major block. `None` for a scalar, a `SLICE`, or an `INDEX` after
/// a whole dim.
pub(super) fn sim_slice_of(cr: &DAE::ComponentRef) -> Result<Option<(String, Vec<Arc<DAE::Exp>>)>> {
    use DAE::ComponentRef as C;
    let mut base = String::new();
    let mut node = cr;
    loop {
        match node {
            C::CREF_IDENT { ident, subscriptLst, .. } => {
                base.push_str(ident);
                let mut leading = Vec::new();
                let mut seen_whole = false;
                for sub in &**subscriptLst {
                    match &**sub {
                        DAE::Subscript::INDEX { exp } if !seen_whole => leading.push(exp.clone()),
                        DAE::Subscript::WHOLEDIM | DAE::Subscript::WHOLE_NONEXP { .. } => seen_whole = true,
                        _ => return Ok(None),
                    }
                }
                if !seen_whole {
                    return Ok(None);
                }
                return Ok(Some((base, leading)));
            }
            C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
                base.push_str(ident);
                if !push_qual_subs(subscriptLst, &mut base) {
                    return Ok(None);
                }
                base.push('.');
                node = componentRef;
            }
            _ => return Ok(None),
        }
    }
}

/// [`sim_slice_of`] for a slice indexed on *outer* components: `module[$i].x` is
/// a contiguous run inside the flattened `module.x` group, so every subscript
/// the cref carries is a leading index. `None` unless one of them is qualified.
pub(super) fn flat_sim_slice_of(cr: &DAE::ComponentRef) -> Result<Option<(String, Vec<Arc<DAE::Exp>>)>> {
    use DAE::ComponentRef as C;
    let mut base = String::new();
    let mut leading = Vec::new();
    let mut qualified_subs = false;
    let mut node = cr;
    loop {
        let (ident, subscriptLst, next) = match node {
            C::CREF_IDENT { ident, subscriptLst, .. } => (ident, subscriptLst, None),
            C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
                qualified_subs |= !subscriptLst.is_empty();
                (ident, subscriptLst, Some(componentRef))
            }
            _ => return Ok(None),
        };
        base.push_str(ident);
        for sub in &**subscriptLst {
            match &**sub {
                DAE::Subscript::INDEX { exp } => leading.push(exp.clone()),
                DAE::Subscript::WHOLEDIM | DAE::Subscript::WHOLE_NONEXP { .. } if next.is_none() => {}
                _ => return Ok(None),
            }
        }
        match next {
            Some(n) => {
                base.push('.');
                node = n;
            }
            None => return Ok((qualified_subs && !leading.is_empty()).then_some((base, leading))),
        }
    }
}

/// `base[subs]` (subscripts on the final component) -> `(base key, raw subscript
/// list)`. Unlike [`sim_slice_of`], any `INDEX`/`SLICE`/whole mix.
pub(super) fn sim_array_base_subs(cr: &DAE::ComponentRef) -> Result<Option<(String, List<Arc<DAE::Subscript>>)>> {
    use DAE::ComponentRef as C;
    let mut base = String::new();
    let mut node = cr;
    loop {
        match node {
            C::CREF_IDENT { ident, subscriptLst, .. } => {
                base.push_str(ident);
                if subscriptLst.is_empty() {
                    return Ok(None);
                }
                return Ok(Some((base, subscriptLst.clone())));
            }
            C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
                base.push_str(ident);
                if !push_qual_subs(subscriptLst, &mut base) {
                    return Ok(None);
                }
                base.push('.');
                node = componentRef;
            }
            _ => return Ok(None),
        }
    }
}

/// [`sim_array_base_subs`] over a flattened group: `module[$i].x[2:3]` selects from
/// `module.x`. `None` unless an outer component is subscripted.
pub(super) fn flat_sim_array_base_subs(cr: &DAE::ComponentRef) -> Result<Option<(String, List<Arc<DAE::Subscript>>)>> {
    use DAE::ComponentRef as C;
    let mut base = String::new();
    let mut subs: Vec<Arc<DAE::Subscript>> = Vec::new();
    let mut qualified_subs = false;
    let mut node = cr;
    loop {
        let (ident, subscriptLst, next) = match node {
            C::CREF_IDENT { ident, subscriptLst, .. } => (ident, subscriptLst, None),
            C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
                qualified_subs |= !subscriptLst.is_empty();
                (ident, subscriptLst, Some(componentRef))
            }
            _ => return Ok(None),
        };
        base.push_str(ident);
        subs.extend((&**subscriptLst).into_iter().cloned());
        match next {
            Some(n) => {
                base.push('.');
                node = n;
            }
            None => {
                return Ok(qualified_subs.then(|| (base, subs.into_iter().collect())));
            }
        }
    }
}

pub(super) fn subs_select_array(subs: &List<Arc<DAE::Subscript>>, group: &ArrayGroup) -> bool {
    let rank = group.dims.len() as u32;
    (&**subs).into_iter().count() as u32 <= rank && !is_scalar_index(subs, rank)
}

/// Push the byte address of element `group[leading, 1, …]` and return
/// `(trailing_element_count, element_stride)`; the block spans
/// `trailing_count * stride` contiguous bytes from there.
pub(super) fn emit_sim_slice_addr(ctx: &mut FnCtx, group: &ArrayGroup, leading: &[Arc<DAE::Exp>]) -> Result<(u32, u32)> {
    let (_, stride) = sim_array_elem_kind_stride(group.wty);
    let k = leading.len();
    if k >= group.dims.len() {
        return Err("CodegenWasmJit: array slice indexes all dimensions");
    }
    let trailing_total: u32 = group.dims[k..].iter().product();
    let data = ctx.sim()?.data_local;
    ctx.emit(we::Instruction::I32Const(0)); // acc = 0
    for (axis, exp) in leading.iter().enumerate() {
        ctx.emit(we::Instruction::I32Const(group.dims[axis] as i32));
        ctx.emit(we::Instruction::I32Mul); // acc * dims[axis]
        let wt = compile_exp(ctx, exp)?;
        coerce(ctx, wt, WTy::I32);
        ctx.emit(we::Instruction::I32Const(1));
        ctx.emit(we::Instruction::I32Sub); // e - 1
        ctx.emit(we::Instruction::I32Add); // acc = acc*dims[axis] + (e - 1)
    }
    // addr = data + base_off + acc * (trailing_total * stride)
    ctx.emit(we::Instruction::I32Const((trailing_total * stride) as i32));
    ctx.emit(we::Instruction::I32Mul);
    ctx.emit(we::Instruction::LocalGet(data));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::I32Const(group.base_off as i32));
    ctx.emit(we::Instruction::I32Add);
    Ok((trailing_total, stride))
}
