//! Records: declared record fields, object layout, construction, defaults,
//! field access and assignment, qualified crefs, element addresses.

use super::*;

/// One field of a record *declaration* (C's `RECORD_DECL_FULL` variables), which
/// is what [`emit_record_default`] builds the default constructor from.
pub(crate) struct RecDeclField {
    pub(super) name: ArcStr,
    pub(super) ty: Arc<DAE::Type>,
    /// The declared binding, evaluated in the record's own scope.
    value: Option<Arc<DAE::Exp>>,
    /// The binding came from a derived record (`record A = B(k=exp)`) and is
    /// evaluated in the using scope instead.
    bind_outside: bool,
}

std::thread_local! {
    /// One field list per record class (the C target's one `<Rec>` struct), keyed
    /// by definition path. A record *expression*'s `T_COMPLEX` can disagree with
    /// its consumer's about a field type, which would give the two ends different
    /// field offsets; the declaration decides for both.
    static RECORD_DECLS: std::cell::RefCell<HashMap<String, Arc<Vec<RecDeclField>>>> =
        std::cell::RefCell::new(HashMap::new());
}

/// Install the module's record declarations (see [`RECORD_DECLS`]).
pub(crate) fn set_record_decls(
    decls: &List<SimCodeFunction::RecordDeclaration>,
) -> Result<()> {
    let mut map = HashMap::new();
    for d in decls {
        // Only `RECORD_DECL_FULL` declares a layout.
        let SimCodeFunction::RecordDeclaration::RECORD_DECL_FULL { defPath, variables, .. } = d else {
            continue;
        };
        let path = AbsynUtil::pathString(defPath.clone(), arcstr::literal!("."), true, false)?;
        let mut fields = Vec::new();
        for v in &**variables {
            let SimCodeFunction::Variable::Variable::VARIABLE { name, ty, value, bind_from_outside, .. } = &**v
            else {
                continue;
            };
            fields.push(RecDeclField {
                name: ArcStr::from(cref_ident(name)?),
                ty: ty.clone(),
                value: value.clone(),
                bind_outside: *bind_from_outside,
            });
        }
        map.insert(path.to_string(), Arc::new(fields));
    }
    RECORD_DECLS.with(|r| *r.borrow_mut() = map);
    Ok(())
}

pub(super) fn record_decl_fields(path: &str) -> Option<Arc<Vec<RecDeclField>>> {
    RECORD_DECLS.with(|r| r.borrow().get(path).cloned())
}

/// The declaration of record type `ty`, if the module declares one.
fn record_decl_of(ty: &DAE::Type) -> Result<Option<Arc<Vec<RecDeclField>>>> {
    let DAE::Type::T_COMPLEX { complexClassType: ClassInf::State::RECORD { path }, .. } = ty else {
        return Ok(None);
    };
    let path_str = AbsynUtil::pathString(path.clone(), arcstr::literal!("."), true, false)?;
    Ok(record_decl_fields(&path_str))
}

/// Array-object header offsets, matching the runtime's `ARR_*`.
pub(super) const ARR_NDIMS_OFF: u32 = 8;

pub(super) const ARR_TOTAL_OFF: u32 = 12;

pub(super) const ARR_DIMS_OFF: u32 = 16;

/// Resolve a record field by name to `(absolute offset from the object base,
/// field type)`.
pub(super) fn record_field(fields: &[(ArcStr, SigTy)], name: &str) -> Result<(u32, SigTy)> {
    let layout = record_layout(fields);
    for (i, (fname, fty)) in fields.iter().enumerate() {
        if fname.as_str() == name {
            return Ok((layout.data_off + layout.field_off[i], fty.clone()));
        }
    }
    return Err("CodegenWasmJit: record has no field");
}

pub(crate) fn mem_arg(offset: u32, align_log2: u32) -> we::MemArg {
    we::MemArg { offset: offset as u64, align: align_log2, memory_index: 0 }
}

/// Load a `wty` value from `(address on stack) + offset` (record field read).
pub(super) fn field_load(ctx: &mut FnCtx, wty: WTy, offset: u32) {
    match wty {
        WTy::I32 => ctx.emit(we::Instruction::I32Load(mem_arg(offset, 2))),
        WTy::F64 => ctx.emit(we::Instruction::F64Load(mem_arg(offset, 3))),
    }
}

/// Store a `wty` value to `(address on stack) + offset` (record field write).
pub(super) fn field_store(ctx: &mut FnCtx, wty: WTy, offset: u32) {
    match wty {
        WTy::I32 => ctx.emit(we::Instruction::I32Store(mem_arg(offset, 2))),
        WTy::F64 => ctx.emit(we::Instruction::F64Store(mem_arg(offset, 3))),
    }
}

/// Allocate a record object and fill its inline heap-field table, returning the
/// temp holding the owned (+1) handle. The field data is left zeroed.
pub(super) fn emit_record_alloc(ctx: &mut FnCtx, layout: &RecordLayout) -> Result<u32> {
    ctx.emit(we::Instruction::I32Const(layout.heap.len() as i32));
    ctx.emit(we::Instruction::I32Const(layout.size as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_record_new")?));
    let obj = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(obj));
    for (k, (kind, foff)) in layout.heap.iter().enumerate() {
        let base = 8 + k as u32 * 8;
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(*kind as i32));
        ctx.emit(we::Instruction::I32Store(mem_arg(base, 2)));
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(*foff as i32));
        ctx.emit(we::Instruction::I32Store(mem_arg(base + 4, 2)));
    }
    Ok(obj)
}

/// Emit a record construction: allocate the object, fill the inline heap-field
/// table, then store each field value (`field_exps` in declaration order). The
/// record owns heap field values. Leaves the owned (+1) record handle on the
/// stack.
pub(super) fn emit_record_construction(ctx: &mut FnCtx, fields: &[(ArcStr, SigTy)], field_exps: &[&Arc<DAE::Exp>]) -> Result<()> {
    let layout = record_layout(fields);
    let obj = emit_record_alloc(ctx, &layout)?;
    for (i, (_, fty)) in fields.iter().enumerate() {
        let w = compile_exp(ctx, field_exps[i])?;
        coerce(ctx, w, fty.wty());
        // Value semantics: a record/array field built from a non-fresh source
        // (a variable, a field read) aliases that source's mutable object — copy
        // it so the record owns a private value. Fresh constructors/calls/ranges
        // are already privately owned and move in. (Strings are immutable.)
        if let Some((copy_fn, rel_fn)) = value_copy_fns(fty) {
            if !value_rhs_is_fresh(field_exps[i]) {
                let t = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalSet(t));
                ctx.emit(we::Instruction::LocalGet(t));
                ctx.emit(we::Instruction::Call(rt_index(copy_fn)?));
                ctx.emit(we::Instruction::LocalGet(t));
                ctx.emit(we::Instruction::Call(rt_index(rel_fn)?));
            }
        }
        // Store the owned (private) value into the field: address then value.
        let vt = ctx.alloc_temp(fty.wty());
        ctx.emit(we::Instruction::LocalSet(vt));
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::LocalGet(vt));
        field_store(ctx, fty.wty(), layout.data_off + layout.field_off[i]);
    }
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(())
}

/// The class default of record field `v` — the C target's `<Rec>_construct_p`
/// field init plus `recordInitOutsideBindings`. A binding synthesized from a
/// variable's own submods (`R r(i=2)`) is applied at its declaration, not here.
fn record_field_default(v: &DAE::Var) -> Option<Arc<DAE::Exp>> {
    match &*v.binding {
        DAE::Binding::EQBOUND { source: DAE::BindingSource::BINDING_FROM_RECORD_SUBMODS, .. }
            if !v.bind_from_outside => None,
        DAE::Binding::EQBOUND { exp, .. } => Some(exp.clone()),
        _ => None,
    }
}

/// A record field: the list comes from the declaration (see [`RECORD_DECLS`]) so
/// every site lays the record out alike, the default from the type's `varLst`.
pub(super) struct RecField {
    pub(super) name: ArcStr,
    pub(super) sig: SigTy,
    pub(super) ty: Arc<DAE::Type>,
    default: Option<Arc<DAE::Exp>>,
    /// This use site binds the field from outside, so `default` belongs to the
    /// using scope (see [`RecDeclField::bind_outside`]).
    bind_outside: bool,
}

/// The canonical fields of record type `ty`, or `None` if `ty` is not a record.
pub(super) fn record_fields(ty: &DAE::Type) -> Result<Option<Vec<RecField>>> {
    let DAE::Type::T_COMPLEX { complexClassType: ClassInf::State::RECORD { path }, varLst, .. } = ty
    else {
        return Ok(None);
    };
    let path_str = AbsynUtil::pathString(path.clone(), arcstr::literal!("."), true, false)?;
    let vars: Vec<&Arc<DAE::Var>> = (&**varLst).into_iter().collect();
    let declared: Vec<(ArcStr, Arc<DAE::Type>)> = match record_decl_fields(&path_str) {
        Some(d) => d.iter().map(|f| (f.name.clone(), f.ty.clone())).collect(),
        None => vars.iter().map(|v| (v.name.clone(), v.ty.clone())).collect(),
    };
    let mut out = Vec::with_capacity(declared.len());
    for (name, fty) in declared {
        let var = vars.iter().find(|v| v.name == name);
        // A `[:,:]` field has its shape only at the use site, which is where C
        // reads it (`var_lst |> v => constVarOrDaeExp(v, ...)`).
        let fty = match var {
            Some(v) if type_array_dims(&fty).iter().any(|d| matches!(&**d, DAE::Dimension::DIM_UNKNOWN)) => v.ty.clone(),
            _ => fty,
        };
        out.push(RecField {
            sig: sig_ty(&fty)?,
            default: var.and_then(|v| record_field_default(v)),
            bind_outside: var.is_some_and(|v| v.bind_from_outside),
            ty: fty,
            name,
        });
    }
    Ok(Some(out))
}

pub(super) fn rec_layout(fields: &[RecField]) -> RecordLayout {
    record_layout(&fields.iter().map(|f| (f.name.clone(), f.sig.clone())).collect::<Vec<_>>())
}

/// Default-construct a record value of type `ty` (the C target's
/// `<Rec>_construct`), leaving the owned handle on the stack. A declared field
/// binding is evaluated in the record's own scope (C's `ths->_x`), a
/// `bind_from_outside` one in this scope; the constructor is inlined here, so
/// the first scope is made by binding each finished field under its own name.
pub(super) fn emit_record_default(ctx: &mut FnCtx, ty: &DAE::Type) -> Result<()> {
    let Some(fields) = record_fields(ty)? else {
        return Err("CodegenWasmJit: default construction of a non-record type");
    };
    let decl = record_decl_of(ty)?;
    let decl_of = |name: &ArcStr| decl.as_ref().and_then(|d| d.iter().find(|f| &f.name == name));
    let layout = rec_layout(&fields);
    // Evaluated before any field name is shadowed below.
    let mut outside: Vec<Option<u32>> = Vec::with_capacity(fields.len());
    for f in &fields {
        outside.push(match (f.bind_outside, &f.default) {
            (true, Some(exp)) => {
                emit_field_value(ctx, &f.sig, exp)?;
                let t = ctx.alloc_temp(f.sig.wty());
                ctx.emit(we::Instruction::LocalSet(t));
                Some(t)
            }
            _ => None,
        });
    }
    let obj = emit_record_alloc(ctx, &layout)?;
    let mut shadowed: Vec<(String, Option<(u32, SigTy)>)> = Vec::new();
    let result = (|ctx: &mut FnCtx| -> Result<()> {
        for (i, f) in fields.iter().enumerate() {
            let fty = f.sig.clone();
            // A record with no declaration has only the use site's binding.
            let bound = match decl_of(&f.name) {
                Some(d) if !d.bind_outside => d.value.clone().or_else(|| f.default.clone()),
                _ => f.default.clone(),
            };
            match (outside[i], &bound) {
                (Some(t), _) => ctx.emit(we::Instruction::LocalGet(t)),
                (None, Some(exp)) => {
                    let _g = PartGuard::new(format!("the default of record field `{}`", f.name));
                    emit_field_value(ctx, &fty, exp)?;
                }
                (None, None) => emit_type_default(ctx, &f.ty)?,
            }
            let vt = ctx.alloc_temp(fty.wty());
            ctx.emit(we::Instruction::LocalSet(vt));
            ctx.emit(we::Instruction::LocalGet(obj));
            ctx.emit(we::Instruction::LocalGet(vt));
            field_store(ctx, fty.wty(), layout.data_off + layout.field_off[i]);
            let name = f.name.to_string();
            let prev = ctx.locals.insert(name.clone(), (vt, fty));
            shadowed.push((name, prev));
        }
        Ok(())
    })(ctx);
    for (name, prev) in shadowed {
        match prev {
            Some(v) => ctx.locals.insert(name, v),
            None => ctx.locals.remove(&name),
        };
    }
    result?;
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(())
}

/// One record-field binding, copied if it came from an alias (value semantics).
fn emit_field_value(ctx: &mut FnCtx, fty: &SigTy, exp: &DAE::Exp) -> Result<()> {
    let w = compile_exp(ctx, exp)?;
    coerce(ctx, w, fty.wty());
    if let Some((copy_fn, rel_fn)) = value_copy_fns(fty) {
        if !value_rhs_is_fresh(exp) {
            let t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(t));
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::Call(rt_index(copy_fn)?));
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::Call(rt_index(rel_fn)?));
        }
    }
    Ok(())
}

/// The value a variable of type `ty` has before anything is assigned to it: zero,
/// an allocated (zeroed) array descriptor, or a default-built record.
fn emit_type_default(ctx: &mut FnCtx, ty: &DAE::Type) -> Result<()> {
    match ty {
        DAE::Type::T_REAL { .. } => ctx.emit(we::Instruction::F64Const(0.0f64.into())),
        DAE::Type::T_STRING { .. } => {
            let exp = DAE::Exp::SCONST { string: arcstr::literal!("") };
            compile_exp(ctx, &exp)?;
        }
        DAE::Type::T_ARRAY { ty: elem, .. } => {
            let SigTy::Array { elem: esig, .. } = sig_ty(ty)? else {
                return Err("CodegenWasmJit: array type did not lower to an array");
            };
            let dims = type_array_dims(ty);
            let slot = ctx.alloc_temp(WTy::I32);
            emit_array_alloc(ctx, slot, &esig, &dims)?;
            if matches!(&*esig, SigTy::Record { .. }) {
                emit_array_record_defaults(ctx, slot, elem)?;
            }
            ctx.emit(we::Instruction::LocalGet(slot));
        }
        DAE::Type::T_COMPLEX { complexClassType: ClassInf::State::RECORD { .. }, .. } => {
            emit_record_default(ctx, ty)?;
        }
        _ => ctx.emit(we::Instruction::I32Const(0)),
    }
    Ok(())
}

/// Fill the freshly allocated array in `slot` with default-constructed `elem`
/// records (the C target's `generic_array_create` with the record constructor).
pub(super) fn emit_array_record_defaults(ctx: &mut FnCtx, slot: u32, elem: &DAE::Type) -> Result<()> {
    let total = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalGet(slot));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_total")?));
    ctx.emit(we::Instruction::LocalSet(total));
    let i = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::LocalSet(i));
    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
    ctx.emit(we::Instruction::LocalGet(i));
    ctx.emit(we::Instruction::LocalGet(total));
    ctx.emit(we::Instruction::I32GtS);
    ctx.emit(we::Instruction::BrIf(1));
    ctx.emit(we::Instruction::LocalGet(slot));
    ctx.emit(we::Instruction::LocalGet(i));
    emit_elem_ptr(ctx, &sig_ty(elem)?)?;
    emit_record_default(ctx, elem)?;
    ctx.emit(we::Instruction::I32Store(mem_arg(0, 2)));
    ctx.emit(we::Instruction::LocalGet(i));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(i));
    ctx.emit(we::Instruction::Br(0));
    ctx.emit(we::Instruction::End);
    ctx.emit(we::Instruction::End);
    Ok(())
}

/// A record literal `R(field=…, …)` (`E::RECORD`): the field values are matched
/// to the type's declaration order by component name.
pub(super) fn compile_record(ctx: &mut FnCtx, ty: &DAE::Type, exps: &List<Arc<DAE::Exp>>, comp: &List<ArcStr>) -> Result<()> {
    let SigTy::Record { fields, .. } = sig_ty(ty)? else {
        return Err("CodegenWasmJit: record constructor with non-record type");
    };
    let expv: Vec<&Arc<DAE::Exp>> = (&**exps).into_iter().collect();
    let compv: Vec<&ArcStr> = (&**comp).into_iter().collect();
    if expv.len() != compv.len() || expv.len() != fields.len() {
        return Err("CodegenWasmJit: record constructor arity mismatch");
    }
    let mut field_exps = Vec::with_capacity(fields.len());
    for (fname, _) in fields.iter() {
        let pos = compv
            .iter()
            .position(|n| n.as_str() == fname.as_str())
            .ok_or_else(|| "CodegenWasmJit: record constructor missing field")?;
        field_exps.push(expv[pos]);
    }
    emit_record_construction(ctx, &fields, &field_exps)
}

/// A `METARECORDCALL` carries no `T_COMPLEX`, so its layout comes from the
/// module's record declarations.
pub(super) fn metarecord_sigty(path: &Arc<Absyn::Path>) -> Result<SigTy> {
    let path_str = AbsynUtil::pathString(path.clone(), arcstr::literal!("."), true, false)?;
    let Some(declared) = record_decl_fields(&path_str) else {
        crate::CodegenWasmJit::record_error(format!(
            "CodegenWasmJit: boxed record constructor for undeclared record `{path_str}`"
        ));
        return Err("CodegenWasmJit: boxed record constructor for an undeclared record");
    };
    let mut fields = Vec::with_capacity(declared.len());
    for f in declared.iter() {
        fields.push((f.name.clone(), sig_ty(&f.ty)?));
    }
    Ok(SigTy::Record { path: path_str, fields: Arc::new(fields) })
}

/// The boxed record constructor the frontend emits instead of `E::RECORD` for a
/// record captured by a function reference (C: `mmc_mk_boxN(index, &R__desc,
/// args…)`). Our closures hold values unboxed, so it builds a plain record.
pub(super) fn compile_metarecord(
    ctx: &mut FnCtx,
    path: &Arc<Absyn::Path>,
    args: &List<Arc<DAE::Exp>>,
    fieldNames: &List<ArcStr>,
) -> Result<()> {
    let SigTy::Record { fields, .. } = metarecord_sigty(path)? else {
        return Err("CodegenWasmJit: boxed record constructor with non-record type");
    };
    let argv: Vec<&Arc<DAE::Exp>> = (&**args).into_iter().collect();
    let namev: Vec<&ArcStr> = (&**fieldNames).into_iter().collect();
    if argv.len() != fields.len() || namev.len() != argv.len() {
        return Err("CodegenWasmJit: boxed record constructor arity mismatch");
    }
    let mut field_exps = Vec::with_capacity(fields.len());
    for (fname, _) in fields.iter() {
        let pos = namev
            .iter()
            .position(|n| n.as_str() == fname.as_str())
            .ok_or_else(|| "CodegenWasmJit: boxed record constructor missing field")?;
        field_exps.push(argv[pos]);
    }
    emit_record_construction(ctx, &fields, &field_exps)
}

/// A record-constructor *call* `R(v1, v2, …)` (a `CALL` whose result is a record
/// and which is not a generated function): the positional arguments are the
/// fields in declaration order.
pub(super) fn compile_record_call(ctx: &mut FnCtx, ty: &DAE::Type, args: &List<Arc<DAE::Exp>>) -> Result<()> {
    let SigTy::Record { fields, .. } = sig_ty(ty)? else {
        return Err("CodegenWasmJit: record constructor call with non-record type");
    };
    let argv: Vec<&Arc<DAE::Exp>> = (&**args).into_iter().collect();
    if argv.len() != fields.len() {
        return Err("CodegenWasmJit: record constructor call arity mismatch");
    }
    emit_record_construction(ctx, &fields, &argv)
}

/// Read field `name` of the record produced by `exp` (`E::RSUB`). The record
/// expression is owned (retained if it was a variable) and released after the
/// field is read; a heap field is retained so the returned value is owned.
pub(super) fn compile_rsub(ctx: &mut FnCtx, exp: &DAE::Exp, name: &str) -> Result<WTy> {
    let SigTy::Record { fields, .. } = exp_sigty(exp)? else {
        return Err("CodegenWasmJit: field access `.` on a non-record expression");
    };
    let (off, fty) = record_field(&fields, name)?;
    compile_exp(ctx, exp)?; // owned record handle
    let rec = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(rec));
    ctx.emit(we::Instruction::LocalGet(rec));
    field_load(ctx, fty.wty(), off);
    if fty.is_heap() {
        // Retain the field (owned read), then release the record temp.
        let fv = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalTee(fv));
        ctx.emit(we::Instruction::LocalGet(fv));
        ctx.emit(we::Instruction::Call(rt_index("rt_retain")?));
    }
    ctx.emit(we::Instruction::LocalGet(rec));
    ctx.emit(we::Instruction::Call(rt_index("rt_record_release")?));
    Ok(fty.wty())
}

/// Assign `rhs` into field `name` of record local `rec_idx` (`r.field := rhs`),
/// in place. A heap field's previous value is released after the new owned value
/// is computed; an array/record field assigned from an alias is copied for value
/// semantics (like a whole-value assignment).
fn compile_record_field_assign(ctx: &mut FnCtx, rec_idx: u32, fields: &[(ArcStr, SigTy)], name: &str, rhs: &DAE::Exp) -> Result<()> {
    let (off, fty) = record_field(fields, name)?;
    let Some(release_fn) = fty.release_fn() else {
        // Scalar field: store directly.
        ctx.emit(we::Instruction::LocalGet(rec_idx));
        let w = compile_exp(ctx, rhs)?;
        coerce(ctx, w, fty.wty());
        field_store(ctx, fty.wty(), off);
        return Ok(());
    };
    // Heap field: compute the new owned value into a temp.
    let w = compile_exp(ctx, rhs)?;
    coerce(ctx, w, fty.wty());
    let val_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(val_t));
    // Value semantics: a mutable array/record from a non-fresh source aliases it.
    if let Some((copy_fn, rel_fn)) = value_copy_fns(&fty) {
        if !value_rhs_is_fresh(rhs) {
            ctx.emit(we::Instruction::LocalGet(val_t));
            ctx.emit(we::Instruction::Call(rt_index(copy_fn)?));
            ctx.emit(we::Instruction::LocalGet(val_t));
            ctx.emit(we::Instruction::Call(rt_index(rel_fn)?));
            ctx.emit(we::Instruction::LocalSet(val_t));
        }
    }
    // Release the previous field value (now that the new one is computed).
    ctx.emit(we::Instruction::LocalGet(rec_idx));
    field_load(ctx, fty.wty(), off);
    ctx.emit(we::Instruction::Call(rt_index(release_fn)?));
    // Store the new owned value into the field.
    ctx.emit(we::Instruction::LocalGet(rec_idx));
    ctx.emit(we::Instruction::LocalGet(val_t));
    field_store(ctx, fty.wty(), off);
    Ok(())
}

/// Push a *borrowed* record handle for the head of a qualified cref into a temp:
/// either a record local, or an array-of-records local subscripted to one element.
/// The head is always a function local, which holds the reference for the whole
/// expression, so no retain/release pair is needed.
fn push_record_base(
    ctx: &mut FnCtx,
    ident: &str,
    subs: &List<Arc<DAE::Subscript>>,
) -> Result<(u32, Arc<Vec<(ArcStr, SigTy)>>)> {
    let (idx, sty) = ctx
        .locals
        .get(ident)
        .ok_or_else(|| unknown_variable(ident))?
        .clone();
    if subs.is_empty() {
        let SigTy::Record { fields, .. } = sty else {
            return Err("CodegenWasmJit: field access on non-record local");
        };
        Ok((idx, fields))
    } else {
        let SigTy::Array { elem, rank } = sty else {
            return Err("CodegenWasmJit: subscripting non-array local");
        };
        let SigTy::Record { fields, .. } = &*elem else {
            return Err("CodegenWasmJit: indexed base `[..]` is not an array of records");
        };
        let fields = fields.clone();
        if !is_scalar_index(subs, rank) {
            return Err("CodegenWasmJit: slicing an array of records before field access is not supported");
        }
        let idx_exps = index_subscripts(subs, rank)?;
        emit_elem_addr(ctx, idx, &elem, &idx_exps)?;
        elem_load(ctx, &elem);
        let t = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalSet(t));
        Ok((t, fields))
    }
}

/// Retain the borrowed heap value on top of the stack, leaving it there: the
/// expression protocol hands its consumer an owned value. No-op for a scalar.
pub(super) fn retain_on_stack(ctx: &mut FnCtx, ty: &SigTy) -> Result<()> {
    if !ty.is_heap() {
        return Ok(());
    }
    let v = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalTee(v));
    ctx.emit(we::Instruction::Call(rt_index("rt_retain")?));
    ctx.emit(we::Instruction::LocalGet(v));
    Ok(())
}

/// Read field `name` out of the borrowed record in `rec` into a fresh temp. The
/// value is borrowed too.
fn load_field(
    ctx: &mut FnCtx,
    rec: u32,
    fields: &[(ArcStr, SigTy)],
    name: &str,
) -> Result<(u32, SigTy)> {
    let (off, fty) = record_field(fields, name)?;
    let vt = ctx.alloc_temp(fty.wty());
    ctx.emit(we::Instruction::LocalGet(rec));
    field_load(ctx, fty.wty(), off);
    ctx.emit(we::Instruction::LocalSet(vt));
    Ok((vt, fty))
}

/// Descend one qualified-cref step into field `field[fsubs]` of the record in
/// temp `rec`, producing an owned record handle for the field in a fresh temp.
/// Used by the read/assign navigators for an intermediate `.field.` segment that
/// must resolve to a (sub-)record. Returns `(record_temp, that record's fields)`.
fn step_into_record(
    ctx: &mut FnCtx,
    rec: u32,
    fields: &[(ArcStr, SigTy)],
    field: &str,
    fsubs: &List<Arc<DAE::Subscript>>,
) -> Result<(u32, Arc<Vec<(ArcStr, SigTy)>>)> {
    let (vt, fty) = load_field(ctx, rec, fields, field)?;
    if fsubs.is_empty() {
        let SigTy::Record { fields: f2, .. } = fty else {
            return Err("CodegenWasmJit: field access on non-record field");
        };
        Ok((vt, f2))
    } else {
        let SigTy::Array { elem, rank } = fty else {
            return Err("CodegenWasmJit: subscripting non-array field");
        };
        let SigTy::Record { fields: f2, .. } = &*elem else {
            return Err("CodegenWasmJit: field access on non-record array element");
        };
        let f2 = f2.clone();
        if !is_scalar_index(fsubs, rank) {
            return Err("CodegenWasmJit: slicing an array of records before field access is not supported");
        }
        let idx_exps = index_subscripts(fsubs, rank)?;
        emit_elem_addr(ctx, vt, &elem, &idx_exps)?;
        elem_load(ctx, &elem);
        let t = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalSet(t));
        Ok((t, f2))
    }
}

/// Read a qualified cref `base[..].f1[..].….fn[..]` (`E::CREF` with a
/// `CREF_QUAL` head), descending through nested records (and arrays of records)
/// to the final field, which may itself be subscripted (a scalar index or a
/// slice). Leaves the owned field value on the stack.
pub(super) fn compile_cref_read_qual(ctx: &mut FnCtx, cref: &DAE::ComponentRef) -> Result<WTy> {
    let DAE::ComponentRef::CREF_QUAL { ident, subscriptLst, componentRef: rest, .. } = cref else {
        return Err("CodegenWasmJit: compile_cref_read_qual on non-qualified cref");
    };
    let (mut rec, mut fields) = push_record_base(ctx, ident, subscriptLst)?;
    let mut cur: &DAE::ComponentRef = rest;
    loop {
        match cur {
            DAE::ComponentRef::CREF_IDENT { ident: field, subscriptLst: fsubs, .. } => {
                let (vt, fty) = load_field(ctx, rec, &fields, field)?;
                if fsubs.is_empty() {
                    ctx.emit(we::Instruction::LocalGet(vt));
                    retain_on_stack(ctx, &fty)?;
                    return Ok(fty.wty());
                }
                let SigTy::Array { elem, rank } = fty else {
                    return Err("CodegenWasmJit: subscripting non-array field");
                };
                return if is_scalar_index(fsubs, rank) {
                    let idx_exps = index_subscripts(fsubs, rank)?;
                    emit_elem_addr(ctx, vt, &elem, &idx_exps)?;
                    elem_load(ctx, &elem);
                    retain_on_stack(ctx, &elem)?;
                    Ok(elem.wty())
                } else {
                    // `slice_loaded` consumes an owned handle.
                    ctx.emit(we::Instruction::LocalGet(vt));
                    ctx.emit(we::Instruction::LocalGet(vt));
                    ctx.emit(we::Instruction::Call(rt_index("rt_retain")?));
                    slice_loaded(ctx, fsubs)
                };
            }
            DAE::ComponentRef::CREF_QUAL { ident: field, subscriptLst: fsubs, componentRef: inner, .. } => {
                let (t, f2) = step_into_record(ctx, rec, &fields, field, fsubs)?;
                rec = t;
                fields = f2;
                cur = inner;
            }
            other => return Err("CodegenWasmJit: unsupported component reference"),
        }
    }
}

/// Navigate a qualified cref to the record that directly contains its final
/// field, returning `(owned record temp, that record's fields, final field
/// name, final field subscripts)`. The caller releases the returned temp.
pub(super) fn navigate_qual<'c>(
    ctx: &mut FnCtx,
    cref: &'c DAE::ComponentRef,
) -> Result<(u32, Arc<Vec<(ArcStr, SigTy)>>, &'c str, &'c List<Arc<DAE::Subscript>>)> {
    let DAE::ComponentRef::CREF_QUAL { ident, subscriptLst, componentRef: rest, .. } = cref else {
        return Err("CodegenWasmJit: navigate_qual on non-qualified cref");
    };
    let (mut rec, mut fields) = push_record_base(ctx, ident, subscriptLst)?;
    let mut cur: &DAE::ComponentRef = rest;
    loop {
        match cur {
            DAE::ComponentRef::CREF_IDENT { ident: field, subscriptLst: fsubs, .. } => {
                return Ok((rec, fields, field, fsubs));
            }
            DAE::ComponentRef::CREF_QUAL { ident: field, subscriptLst: fsubs, componentRef: inner, .. } => {
                let (t, f2) = step_into_record(ctx, rec, &fields, field, fsubs)?;
                rec = t;
                fields = f2;
                cur = inner;
            }
            other => return Err("CodegenWasmJit: unsupported component reference"),
        }
    }
}

/// Assign `rhs` into a qualified cref `base[..].f1[..].….fn[..]`. Navigates to
/// the record holding the final field and stores in place (a scalar/heap field,
/// or an element of an array-valued field).
pub(super) fn compile_cref_assign_qual(ctx: &mut FnCtx, cref: &DAE::ComponentRef, rhs: &DAE::Exp) -> Result<()> {
    let (rec, fields, leaf, lsubs) = navigate_qual(ctx, cref)?;
    if lsubs.is_empty() {
        compile_record_field_assign(ctx, rec, &fields, leaf, rhs)?;
    } else {
        // `…field[i] := rhs`: element assignment into the field's (privately
        // owned) array, in place.
        let (off, fty) = record_field(&fields, leaf)?;
        let SigTy::Array { elem, rank } = fty else {
            return Err("CodegenWasmJit: subscripted field is not an array");
        };
        let arr_t = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalGet(rec));
        field_load(ctx, WTy::I32, off);
        ctx.emit(we::Instruction::LocalSet(arr_t));
        if !is_scalar_index(lsubs, rank) {
            return compile_slice_assign(ctx, arr_t, lsubs, RhsSource::Exp(rhs));
        }
        let idx_exps = index_subscripts(lsubs, rank)?;
        compile_elem_assign(ctx, arr_t, &elem, &idx_exps, rhs)?;
    }
    Ok(())
}

/// Element assignment `a[i,...] := rhs`, in place. `arr_idx` is the array local
/// (which privately owns its buffer). For a heap element the previous handle in
/// the slot is released and the new owned value moved in; the old value is
/// released only *after* the rhs is computed, in case the rhs reads it.
pub(super) fn compile_elem_assign(ctx: &mut FnCtx, arr_idx: u32, elem: &SigTy, idx_exps: &[Arc<DAE::Exp>], rhs: &DAE::Exp) -> Result<()> {
    emit_elem_addr(ctx, arr_idx, elem, idx_exps)?;
    let addr_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(addr_t));
    if let Some(release_fn) = elem.release_fn() {
        let w = compile_exp(ctx, rhs)?;
        coerce(ctx, w, elem.wty());
        let val_t = ctx.alloc_temp(elem.wty());
        ctx.emit(we::Instruction::LocalSet(val_t));
        // Release the previous element handle now that the new value is computed.
        ctx.emit(we::Instruction::LocalGet(addr_t));
        elem_load(ctx, elem);
        ctx.emit(we::Instruction::Call(rt_index(release_fn)?));
        // Store the new owned handle into the slot.
        ctx.emit(we::Instruction::LocalGet(addr_t));
        ctx.emit(we::Instruction::LocalGet(val_t));
        elem_store(ctx, elem);
    } else {
        ctx.emit(we::Instruction::LocalGet(addr_t));
        let w = compile_exp(ctx, rhs)?;
        coerce(ctx, w, elem.wty());
        elem_store(ctx, elem);
    }
    Ok(())
}

/// Emit the byte address of array element `a[idx_exps...]`, reading the array
/// handle from local `arr_idx` (the local owns it — no retain/release). Leaves
/// the address on the stack. Same row-major linear index as [`index_loaded`].
pub(super) fn emit_elem_addr(ctx: &mut FnCtx, arr_idx: u32, elem: &SigTy, idx_exps: &[Arc<DAE::Exp>]) -> Result<()> {
    let acc = ctx.alloc_temp(WTy::I32);
    emit_subscript_index(ctx, &idx_exps[0])?;
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Sub);
    ctx.emit(we::Instruction::LocalSet(acc));
    for (axis0, ie) in idx_exps.iter().enumerate().skip(1) {
        ctx.emit(we::Instruction::LocalGet(acc));
        ctx.emit(we::Instruction::LocalGet(arr_idx));
        emit_array_dim(ctx, axis0 as u32 + 1)?;
        ctx.emit(we::Instruction::I32Mul);
        emit_subscript_index(ctx, ie)?;
        ctx.emit(we::Instruction::I32Const(1));
        ctx.emit(we::Instruction::I32Sub);
        ctx.emit(we::Instruction::I32Add);
        ctx.emit(we::Instruction::LocalSet(acc));
    }
    ctx.emit(we::Instruction::LocalGet(arr_idx));
    ctx.emit(we::Instruction::LocalGet(acc));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    emit_elem_ptr(ctx, elem)
}

/// Evaluate a call for its side effects and discard any results. A discarded
/// heap result is owned (+1), so it must be released, not merely dropped. Shared
/// by `STMT_NORETCALL` and the `when`-body `NORETCALL` operator.
pub(super) fn emit_noretcall(ctx: &mut FnCtx, exp: &DAE::Exp) -> Result<()> {
    let results = compile_call_drop(ctx, exp)?;
    for sty in results.iter().rev() {
        match sty.release_fn() {
            Some(release_fn) => ctx.emit(we::Instruction::Call(rt_index(release_fn)?)),
            None => ctx.emit(we::Instruction::Drop),
        }
    }
    Ok(())
}
