//! Flat records: a record whose fields are all Integer/Real/Boolean is held as
//! one wasm local per field instead of a heap object, the way C passes such a
//! struct by value. A function taking or returning a flat record, and returning
//! nothing but scalars and flat records, also gets a `$flat` variant with those
//! fields as multi-value params/results; each variant is reachable from the other
//! through a boxing wrapper.

use super::*;

pub(crate) type FlatFields = Arc<Vec<(ArcStr, SigTy)>>;

const MAX_FLAT_FIELDS: usize = 16;

pub(crate) fn flat_fields(t: &SigTy) -> Option<&FlatFields> {
    let SigTy::Record { fields, .. } = t else { return None };
    let scalar = |t: &SigTy| matches!(t, SigTy::Int | SigTy::Real | SigTy::Bool);
    (!fields.is_empty() && fields.len() <= MAX_FLAT_FIELDS && fields.iter().all(|(_, t)| scalar(t))).then_some(fields)
}

pub(crate) fn flat_key(mangled: &str) -> String {
    format!("{mangled}$flat")
}

fn expand(tys: &[SigTy]) -> Vec<SigTy> {
    let mut out = Vec::new();
    for t in tys {
        match flat_fields(t) {
            Some(fields) => out.extend(fields.iter().map(|(_, t)| t.clone())),
            None => out.push(t.clone()),
        }
    }
    out
}

fn flat_sig(sig: &FnSig) -> Option<FnSig> {
    let ok = |t: &SigTy| matches!(t, SigTy::Int | SigTy::Real | SigTy::Bool) || flat_fields(t).is_some();
    if !sig.results.iter().all(ok) || !sig.params.iter().chain(&sig.results).any(|t| flat_fields(t).is_some()) {
        return None;
    }
    Some(FnSig { params: expand(&sig.params), results: expand(&sig.results) })
}

pub(super) fn field_temps(ctx: &mut FnCtx, fields: &FlatFields) -> Vec<u32> {
    fields.iter().map(|(_, t)| ctx.alloc_temp(t.wty())).collect()
}

/// Box the field values in `vals` into a new record, leaving the owned handle.
pub(super) fn box_flat(ctx: &mut FnCtx, fields: &FlatFields, vals: &[u32]) -> Result<()> {
    let layout = record_layout(fields);
    let obj = emit_record_alloc(ctx, &layout)?;
    for (i, (_, t)) in fields.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::LocalGet(vals[i]));
        field_store(ctx, t.wty(), layout.data_off + layout.field_off[i]);
    }
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(())
}

pub(super) fn load_fields(ctx: &mut FnCtx, fields: &FlatFields, rec: u32, out: &[u32]) {
    let layout = record_layout(fields);
    for (i, (_, t)) in fields.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(rec));
        field_load(ctx, t.wty(), layout.data_off + layout.field_off[i]);
        ctx.emit(we::Instruction::LocalSet(out[i]));
    }
}

/// Unpack the owned record handle on the stack into fresh locals, releasing it.
fn unpack_owned(ctx: &mut FnCtx, fields: &FlatFields) -> Result<Vec<u32>> {
    let rec = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(rec));
    let out = field_temps(ctx, fields);
    load_fields(ctx, fields, rec, &out);
    ctx.emit(we::Instruction::LocalGet(rec));
    ctx.emit(we::Instruction::Call(rt_index("rt_record_release")?));
    Ok(out)
}

fn store_value(ctx: &mut FnCtx, e: &DAE::Exp, t: &SigTy) -> Result<u32> {
    let w = compile_exp(ctx, e)?;
    coerce(ctx, w, t.wty());
    let v = ctx.alloc_temp(t.wty());
    ctx.emit(we::Instruction::LocalSet(v));
    Ok(v)
}

/// The flat variable `name`, unless a local shadows it (see `record_default_values`).
pub(super) fn flat_var<'c>(ctx: &'c FnCtx, name: &str) -> Option<&'c FlatVar> {
    if ctx.locals.contains_key(name) {
        return None;
    }
    ctx.flat.get(name)
}

pub(super) fn flat_var_ref<'c>(ctx: &'c FnCtx, e: &DAE::Exp) -> Option<&'c FlatVar> {
    let DAE::Exp::CREF { componentRef, .. } = e else { return None };
    flat_cref(ctx, componentRef)
}

pub(super) fn flat_cref<'c>(ctx: &'c FnCtx, cref: &DAE::ComponentRef) -> Option<&'c FlatVar> {
    let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = cref else { return None };
    if !subscriptLst.is_empty() {
        return None;
    }
    flat_var(ctx, ident)
}

pub(super) fn flat_field_ref(ctx: &FnCtx, cref: &DAE::ComponentRef) -> Option<(FlatVar, usize)> {
    let DAE::ComponentRef::CREF_QUAL { ident, subscriptLst, componentRef, .. } = cref else { return None };
    let DAE::ComponentRef::CREF_IDENT { ident: field, subscriptLst: fsubs, .. } = &**componentRef else { return None };
    if !subscriptLst.is_empty() || !fsubs.is_empty() {
        return None;
    }
    let v = flat_var(ctx, ident)?;
    let i = v.fields.iter().position(|(n, _)| n == field)?;
    Some((v.clone(), i))
}

/// Compile the record value `e` into one fresh local per field of `fields`.
pub(super) fn compile_flat(ctx: &mut FnCtx, e: &DAE::Exp, fields: &FlatFields) -> Result<Vec<u32>> {
    use DAE::Exp as E;
    match e {
        E::RECORD { exps, comp, .. } => {
            let expv: Vec<&metamodelica::Ref<DAE::Exp>> = (&**exps).into_iter().collect();
            let compv: Vec<&ArcStr> = (&**comp).into_iter().collect();
            if expv.len() == fields.len() && compv.len() == fields.len() {
                let mut out = Vec::with_capacity(fields.len());
                for (name, t) in fields.iter() {
                    let pos = compv
                        .iter()
                        .position(|n| *n == name)
                        .ok_or("CodegenWasmJit: record constructor missing field")?;
                    out.push(store_value(ctx, expv[pos], t)?);
                }
                return Ok(out);
            }
        }
        E::CREF { .. } => {
            if let Some(v) = flat_var_ref(ctx, e).cloned() {
                let out = field_temps(ctx, fields);
                for (src, dst) in v.locals.iter().zip(&out) {
                    ctx.emit(we::Instruction::LocalGet(*src));
                    ctx.emit(we::Instruction::LocalSet(*dst));
                }
                return Ok(out);
            }
            if let Some(rec) = record_local(ctx, e) {
                let out = field_temps(ctx, fields);
                load_fields(ctx, fields, rec, &out);
                return Ok(out);
            }
        }
        E::CALL { path, expLst, attr } if !attr.isFunctionPointerCall => {
            let mangled = mangle(path)?;
            if let Some(outs) = compile_flat_call(ctx, &mangled, expLst)? {
                return match outs.into_iter().next() {
                    Some(first) if first.len() == fields.len() => Ok(first),
                    _ => Err("CodegenWasmJit: flat call result does not match its record type"),
                };
            }
            if !ctx.by_name.contains_key(&mangled) && matches!(sig_ty_quiet(&attr.ty), Ok(SigTy::Record { .. })) {
                let argv: Vec<&metamodelica::Ref<DAE::Exp>> = (&**expLst).into_iter().collect();
                if argv.len() == fields.len() {
                    let mut out = Vec::with_capacity(fields.len());
                    for (a, (_, t)) in argv.iter().zip(fields.iter()) {
                        out.push(store_value(ctx, a, t)?);
                    }
                    return Ok(out);
                }
            }
        }
        E::IFEXP { expCond, expThen, expElse } => {
            let c = compile_exp(ctx, expCond)?;
            coerce(ctx, c, WTy::I32);
            let out = field_temps(ctx, fields);
            ctx.emit(we::Instruction::If(we::BlockType::Empty));
            for (k, branch) in [expThen, expElse].into_iter().enumerate() {
                if k == 1 {
                    ctx.emit(we::Instruction::Else);
                }
                let vals = compile_flat(ctx, branch, fields)?;
                for (v, o) in vals.iter().zip(&out) {
                    ctx.emit(we::Instruction::LocalGet(*v));
                    ctx.emit(we::Instruction::LocalSet(*o));
                }
            }
            ctx.emit(we::Instruction::End);
            return Ok(out);
        }
        _ => {}
    }
    compile_exp(ctx, e)?;
    unpack_owned(ctx, fields)
}

/// Call `mangled`'s `$flat` variant, returning one list of locals per output
/// (a single one for a scalar output), or `None` if it has none.
pub(super) fn compile_flat_call(
    ctx: &mut FnCtx,
    mangled: &str,
    args: &List<metamodelica::Ref<DAE::Exp>>,
) -> Result<Option<Vec<Vec<u32>>>> {
    let (Some(boxed), Some(flat)) = (ctx.by_name.get(mangled), ctx.by_name.get(&flat_key(mangled))) else {
        return Ok(None);
    };
    let params = boxed.sig.params.clone();
    let results = boxed.sig.results.clone();
    let index = flat.index;
    let argv: Vec<&metamodelica::Ref<DAE::Exp>> = (&**args).into_iter().collect();
    if argv.len() != params.len() {
        return Err("CodegenWasmJit: call argument count mismatch");
    }
    let mut vals = Vec::new();
    // Other record arguments are borrowed, as in `compile_call_args`.
    let mut borrowed = Vec::new();
    for (a, p) in argv.iter().zip(&params) {
        match flat_fields(p) {
            Some(fields) => vals.extend(compile_flat(ctx, a, &fields.clone())?),
            None if matches!(p, SigTy::Record { .. }) => match record_local(ctx, a) {
                Some(idx) => vals.push(idx),
                None => {
                    let t = store_value(ctx, a, p)?;
                    vals.push(t);
                    borrowed.push(t);
                }
            },
            None => vals.push(store_value(ctx, a, p)?),
        }
    }
    for v in vals {
        ctx.emit(we::Instruction::LocalGet(v));
    }
    let clock = prof_fn_clock(ctx, mangled);
    emit_prof(ctx, clock, "rt_prof_tick")?;
    ctx.emit(we::Instruction::Call(index));
    emit_prof(ctx, clock, "rt_prof_acc")?;
    let outs: Vec<Vec<u32>> = results
        .iter()
        .map(|r| match flat_fields(r) {
            Some(fields) => field_temps(ctx, &fields.clone()),
            None => vec![ctx.alloc_temp(r.wty())],
        })
        .collect();
    for v in outs.iter().flatten().rev() {
        ctx.emit(we::Instruction::LocalSet(*v));
    }
    release_record_temps(ctx, &borrowed)?;
    Ok(Some(outs))
}

pub(super) fn assign_flat(ctx: &mut FnCtx, v: &FlatVar, rhs: &DAE::Exp) -> Result<()> {
    let vals = compile_flat(ctx, rhs, &v.fields)?;
    for (src, dst) in vals.iter().zip(&v.locals) {
        ctx.emit(we::Instruction::LocalGet(*src));
        ctx.emit(we::Instruction::LocalSet(*dst));
    }
    Ok(())
}

/// Store the owned record handle in `vt` into flat variable `v`, releasing it.
pub(super) fn store_fresh_into_flat(ctx: &mut FnCtx, v: &FlatVar, vt: u32) -> Result<()> {
    load_fields(ctx, &v.fields, vt, &v.locals);
    ctx.emit(we::Instruction::LocalGet(vt));
    ctx.emit(we::Instruction::Call(rt_index("rt_record_release")?));
    Ok(())
}

/// A body for one variant that calls the other: the boxed variant unpacks its
/// record params and boxes the results of the flat one, the flat variant boxes
/// its params and unpacks the results of the boxed one.
pub(crate) fn variant_wrapper(
    boxed: &FnSig,
    to_flat: bool,
    callee: u32,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let n_params = if to_flat { boxed.params.len() } else { expand(&boxed.params).len() } as u32;
    let mut ctx = FnCtx {
        locals: HashMap::default(),
        extra_locals: Vec::new(),
        n_params,
        outputs: Vec::new(),
        by_name,
        literals,
        instrs: Vec::new(),
        ctrl_depth: 0,
        loops: Vec::new(),
        borrowed_locals: Vec::new(),
        null_locals: Vec::new(),
        elem_ptr_tmp: None,
        src_loc: None,
        sim: None,
        dt_local_cons: false,
        dt_fallback: None,
        flat: HashMap::default(),
        flat_outs: Vec::new(),
        flat_results: false,
    };
    let mut boxed_args = Vec::new();
    let mut idx = 0u32;
    for p in &boxed.params {
        match (flat_fields(p), to_flat) {
            (Some(fields), true) => {
                let fields = fields.clone();
                let layout = record_layout(&fields);
                for (i, (_, t)) in fields.iter().enumerate() {
                    ctx.emit(we::Instruction::LocalGet(idx));
                    field_load(&mut ctx, t.wty(), layout.data_off + layout.field_off[i]);
                }
                idx += 1;
            }
            (Some(fields), false) => {
                let fields = fields.clone();
                let vals: Vec<u32> = (idx..idx + fields.len() as u32).collect();
                box_flat(&mut ctx, &fields, &vals)?;
                let h = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalTee(h));
                boxed_args.push(h);
                idx += fields.len() as u32;
            }
            (None, _) => {
                ctx.emit(we::Instruction::LocalGet(idx));
                idx += 1;
            }
        }
    }
    ctx.emit(we::Instruction::Call(callee));
    let results = if to_flat { expand(&boxed.results) } else { boxed.results.clone() };
    let temps: Vec<u32> = results.iter().map(|r| ctx.alloc_temp(r.wty())).collect();
    for t in temps.iter().rev() {
        ctx.emit(we::Instruction::LocalSet(*t));
    }
    release_record_temps(&mut ctx, &boxed_args)?;
    let mut k = 0usize;
    for r in &boxed.results {
        match (flat_fields(r), to_flat) {
            (Some(fields), true) => {
                let fields = fields.clone();
                box_flat(&mut ctx, &fields, &temps[k..k + fields.len()])?;
                k += fields.len();
            }
            (Some(fields), false) => {
                let fields = fields.clone();
                let vals = field_temps(&mut ctx, &fields);
                load_fields(&mut ctx, &fields, temps[k], &vals);
                ctx.emit(we::Instruction::LocalGet(temps[k]));
                ctx.emit(we::Instruction::Call(rt_index("rt_record_release")?));
                for v in vals {
                    ctx.emit(we::Instruction::LocalGet(v));
                }
                k += 1;
            }
            (None, _) => {
                ctx.emit(we::Instruction::LocalGet(temps[k]));
                k += 1;
            }
        }
    }
    ctx.emit(we::Instruction::End);
    let FnCtx { extra_locals, instrs, .. } = ctx;
    let mut func = we::Function::new(extra_locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// The functions of `funcs` (by position) that get a `$flat` variant, with its
/// `by_name` key and signature, in `funcs` order.
pub(crate) fn flat_variants(funcs: &[&SimCodeFunction::Function::Function]) -> Result<Vec<(usize, String, FnSig)>> {
    let mut out = Vec::new();
    for (id, f) in funcs.iter().enumerate() {
        if !matches!(f, SimCodeFunction::Function::Function::FUNCTION { .. }) {
            continue;
        }
        let (name, sig) = function_signature(f)?;
        if let Some(fsig) = flat_sig(&sig) {
            out.push((id, flat_key(&name), fsig));
        }
    }
    Ok(out)
}
