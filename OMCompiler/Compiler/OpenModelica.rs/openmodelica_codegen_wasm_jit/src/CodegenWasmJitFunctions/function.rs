//! Compiling one function: body, locals, outputs, heap release.

use super::*;

pub(crate) fn compile_function(
    f: &SimCodeFunction::Function::Function,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    CURRENT_FN.with(|c| *c.borrow_mut() = function_path(f));
    let out = compile_function_body(f, by_name, literals);
    CURRENT_FN.with(|c| c.borrow_mut().clear());
    out
}

fn function_path(f: &SimCodeFunction::Function::Function) -> String {
    use SimCodeFunction::Function::Function as F;
    let path = match f {
        F::FUNCTION { name, .. }
        | F::PARALLEL_FUNCTION { name, .. }
        | F::KERNEL_FUNCTION { name, .. }
        | F::EXTERNAL_FUNCTION { name, .. }
        | F::RECORD_CONSTRUCTOR { name, .. } => name,
    };
    AbsynUtil::pathString(path.clone(), arcstr::literal!("."), true, false)
        .map(|s| s.to_string())
        .unwrap_or_default()
}

fn compile_function_body(
    f: &SimCodeFunction::Function::Function,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    if matches!(f, SimCodeFunction::Function::Function::EXTERNAL_FUNCTION { .. }) {
        return compile_external_function(f, by_name, literals);
    }
    let SimCodeFunction::Function::Function::FUNCTION { outVars, functionArguments, variableDeclarations, body, .. } = f
    else {
        return Err("CodegenWasmJit: only plain FUNCTIONs are supported");
    };

    let mut locals: HashMap<String, (u32, SigTy)> = HashMap::new();
    let mut idx: u32 = 0;
    // Parameters first (wasm locals 0..n_params).
    for v in &**functionArguments {
        let (name, sty) = var_name_ty(v)?;
        locals.insert(name, (idx, sty));
        idx += 1;
    }
    let n_params = idx;
    let mut extra_locals: Vec<we::ValType> = Vec::new();
    let mut outputs: Vec<(u32, SigTy)> = Vec::new();
    // Array locals/outputs to allocate at function entry (see `emit_array_alloc`):
    // (local index, element type, dimension specs). Inputs are excluded — they
    // are passed in already built.
    let mut array_allocs: Vec<(u32, Arc<SigTy>, Vec<Arc<DAE::Dimension>>)> = Vec::new();
    // Outputs next, then local declarations. An output is often also listed in
    // `variableDeclarations` (the function body assigns to it through the same
    // name); it must map to a single local, so a name already allocated as an
    // input or output is reused rather than given a fresh slot.
    for v in &**outVars {
        let slot = intern_local(v, &mut idx, &mut extra_locals, &mut locals, &mut array_allocs)?;
        outputs.push(slot);
    }
    for v in &**variableDeclarations {
        intern_local(v, &mut idx, &mut extra_locals, &mut locals, &mut array_allocs)?;
    }

    let mut ctx = FnCtx { locals, extra_locals, n_params, outputs, by_name, literals, instrs: Vec::new(), ctrl_depth: 0, loops: Vec::new(), borrowed_locals: Vec::new(), elem_ptr_tmp: None, src_loc: None, sim: None, dt_local_cons: false, dt_fallback: None };
    // In declaration order, like C's `varInit` loop: a declaration's dimensions
    // may read an earlier one (`Integer n = size(x,1); Real delta[n-1]`), so
    // allocation and binding must interleave. `variableDeclarations` already
    // contains the outputs; one missing from it is initialized first.
    let decl_slots: Vec<u32> = (&**variableDeclarations).into_iter().filter_map(|v| var_slot(&ctx, v)).collect();
    let loose_outs: Vec<_> = (&**outVars)
        .into_iter()
        .filter(|v| !var_slot(&ctx, v).is_some_and(|s| decl_slots.contains(&s)))
        .collect();
    let mut done: Vec<u32> = Vec::new();
    for v in loose_outs.into_iter().chain(&**variableDeclarations) {
        init_var(&mut ctx, v, &mut array_allocs, &mut done)?;
    }
    compile_stmts(&mut ctx, body)?;
    // Fall-through return: release heap locals, push the output locals and end.
    release_heap_locals(&mut ctx)?;
    push_outputs(&mut ctx);
    ctx.emit(we::Instruction::End);

    let FnCtx { extra_locals, instrs, .. } = ctx;
    let mut func = we::Function::new(extra_locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Lower an `external "C"`/`"builtin"`/`"FORTRAN 77"` function to the wasm
/// equivalent of C's `functionBodyExternalFunction`: allocate and bind the
/// outputs and the protected `biVars` locals, call `extName` over `extArgs`,
/// then copy the results into the outputs.
fn compile_external_function(
    f: &SimCodeFunction::Function::Function,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    use SimCodeFunction::SimExtArg::SimExtArg as A;
    let SimCodeFunction::Function::Function::EXTERNAL_FUNCTION { name, funArgs, outVars, biVars, extName, extArgs, extReturn, .. } = f else {
        return Err("CodegenWasmJit: compile_external_function on a non-external function");
    };
    // Only for the mismatch diagnostics below.
    let fn_path = || {
        AbsynUtil::pathString(name.clone(), arcstr::literal!("."), true, false).unwrap_or_default()
    };

    let mut locals: HashMap<String, (u32, SigTy)> = HashMap::new();
    let mut idx: u32 = 0;
    for v in &**funArgs {
        let (name, sty) = var_name_ty(v)?;
        locals.insert(name, (idx, sty));
        idx += 1;
    }
    let n_params = idx;
    let mut extra_locals: Vec<we::ValType> = Vec::new();
    let mut outputs: Vec<(u32, SigTy)> = Vec::new();
    // Output arrays are pre-allocated at entry and passed to the C call as a pointer
    // (filled in place natively / copied back on web); collect them for allocation.
    let mut array_allocs: Vec<(u32, Arc<SigTy>, Vec<Arc<DAE::Dimension>>)> = Vec::new();
    for v in &**outVars {
        let slot = intern_local(v, &mut idx, &mut extra_locals, &mut locals, &mut array_allocs)?;
        outputs.push(slot);
    }
    for v in &**biVars {
        intern_local(v, &mut idx, &mut extra_locals, &mut locals, &mut array_allocs)?;
    }

    let mut ctx = FnCtx { locals, extra_locals, n_params, outputs, by_name, literals, instrs: Vec::new(), ctrl_depth: 0, loops: Vec::new(), borrowed_locals: Vec::new(), elem_ptr_tmp: None, src_loc: None, sim: None, dt_local_cons: false, dt_fallback: None };
    // In the order the C body emits them: `extFunCallF77` appends the `biVars` to
    // the *outputAlloc* buffer, ahead of the outputs (`output Real x[max(nrow,
    // ncol)] = cat(…nrow…)` reads them); `extFunCallC` appends them behind.
    let lang = external_import_sig(f).map(|s| s.lang).unwrap_or(ExtLang::C);
    let ordered: Vec<&Arc<SimCodeFunction::Variable::Variable>> = match lang {
        ExtLang::Fortran77 => (&**biVars).into_iter().chain(&**outVars).collect(),
        ExtLang::C => (&**outVars).into_iter().chain(&**biVars).collect(),
    };
    for v in ordered {
        let SimCodeFunction::Variable::Variable::VARIABLE { name, ty, value, bind_from_outside, .. } = &**v else {
            continue;
        };
        let slot = var_name_ty(v).ok().and_then(|(n, _)| ctx.locals.get(&n).cloned());
        if let Some((slot, SigTy::Array { elem, .. })) = slot
            && let Some(k) = array_allocs.iter().position(|(i, ..)| *i == slot)
        {
            let (_, _, dims) = array_allocs.remove(k);
            emit_array_alloc(&mut ctx, slot, &elem, &dims)?;
        }
        if *bind_from_outside {
            continue;
        }
        let Some(val) = value else { continue };
        let lhs = DAE::Exp::CREF { componentRef: name.clone(), ty: ty.clone() };
        compile_assign(&mut ctx, &lhs, val)?;
    }

    // Lower an extArg to the argument expression it contributes to the C call.
    // A scalar/String `_Out_` arg contributes none — its value comes back as a
    // call result — so `None` skips it.
    let lower_arg = |a: &A| -> Result<Option<Arc<DAE::Exp>>> {
        let is_out = ext_arg_output_index(a) != 0;
        Ok(match a {
            // An output array is pre-allocated and passed by pointer, like an input.
            A::SIMEXTARG { cref, type_, .. } if !is_out || matches!(sig_ty_quiet(type_), Ok(SigTy::Array { .. })) => {
                Some(Arc::new(DAE::Exp::CREF { componentRef: cref.clone(), ty: type_.clone() }))
            }
            A::SIMEXTARG { .. } => None,
            A::SIMEXTARGEXP { exp, .. } => Some(exp.clone()),
            // `size(array, dim)`: `cref`+`type_` are the array (full type), `exp`
            // is the 1-based dimension index. Lower as a `size(cref, exp)`
            // expression → `rt_array_dim`. (Pushing `exp` alone would pass the
            // dimension index itself as the C `int`, not the size.)
            A::SIMEXTARGSIZE { cref, type_, exp, .. } => {
                let arr = Arc::new(DAE::Exp::CREF { componentRef: cref.clone(), ty: type_.clone() });
                Some(Arc::new(DAE::Exp::SIZE { exp: arr, sz: Some(exp.clone()) }))
            }
            other => return Err("CodegenWasmJit: unsupported external-call argument"),
        })
    };

    // Input-side arguments (both known and general externals pass these by value).
    let mut input_args: Vec<Arc<DAE::Exp>> = Vec::new();
    for a in &**extArgs {
        if let Some(e) = lower_arg(&**a)? {
            input_args.push(e);
        }
    }

    if external_known(f) {
        // Known math/string externals: a single return value, no output pointers.
        let (out_idx, out_sty) = ctx.outputs[0].clone();
        let result = emit_known_external_call(&mut ctx, extName, &input_args, &out_sty)?;
        coerce(&mut ctx, result.wty(), out_sty.wty());
        ctx.emit(we::Instruction::LocalSet(out_idx));
    } else {
        // General external: the host returns one result per *scalar/string* output
        // (the C return value first, then each `_Out_` scalar/string pointer's
        // value). Array outputs are filled in place / copied back by the host, so
        // they are not results — their locals are already populated. The results
        // land on the stack in order, so they are stored back-to-front into the
        // declared outputs their `outputIndex` names.
        let sig = external_import_sig(f)?;
        // A shared-memory module calls the real symbol directly, so the pointer
        // and by-reference conversions the host trampoline would do
        // (`call_external_in_wasm`) are emitted here instead.
        if EXTERNALS_SHARED.with(|c| c.get()) {
            emit_shared_external_call(&mut ctx, &sig, extArgs, extReturn, &fn_path)?;
            release_heap_locals(&mut ctx)?;
            push_outputs(&mut ctx);
            ctx.emit(we::Instruction::End);
            let FnCtx { extra_locals, instrs, .. } = ctx;
            let mut func = we::Function::new(extra_locals.into_iter().map(|t| (1u32, t)));
            for i in &instrs {
                func.instruction(i);
            }
            return Ok(func);
        }
        let results = emit_general_external_call(&mut ctx, &sig.name, &input_args)?;
        // The declared output each wasm result feeds, in result order: the C
        // return value first, then each scalar/String `_Out_` arg.
        // `(declared output, the field of it this value assigns)`.
        let mut targets: Vec<(usize, Option<String>)> = Vec::new();
        if let A::SIMEXTARG { outputIndex, cref, .. } = &**extReturn {
            targets.push((*outputIndex as usize - 1, cref_field(cref)));
        }
        for a in &**extArgs {
            let oi = ext_arg_output_index(a);
            let scalar = !matches!(&**a, A::SIMEXTARG { type_, .. } if matches!(sig_ty_quiet(type_), Ok(SigTy::Array { .. })));
            if oi != 0 && scalar {
                let field = match &**a {
                    A::SIMEXTARG { cref, .. } => cref_field(cref),
                    _ => None,
                };
                targets.push((oi - 1, field));
            }
        }
        if results.len() != targets.len() {
            openmodelica_wasm_jit::set_engine_error_detail(format!(
                "  {}, external `{extName}`: the call returns {} value(s) for {} scalar output(s)",
                fn_path(),
                results.len(),
                targets.len(),
            ));
            return Err("CodegenWasmJit: external scalar-return/output count mismatch");
        }
        for k in (0..targets.len()).rev() {
            let (target, field) = targets[k].clone();
            let (out_idx, out_sty) = ctx.outputs[target].clone();
            // Must follow the whole-record store through the pointer argument, which
            // it does: results go back-to-front.
            if let Some(field) = field {
                let SigTy::Record { fields, .. } = &out_sty else {
                    openmodelica_wasm_jit::set_engine_error_detail(format!(
                        "  {}, external `{extName}`: `{field}` is a field of an output that is not a record",
                        fn_path(),
                    ));
                    return Err("CodegenWasmJit: external output field on a non-record");
                };
                let vt = ctx.alloc_temp(results[k].wty());
                ctx.emit(we::Instruction::LocalSet(vt));
                store_fresh_into_field(&mut ctx, out_idx, fields, &field, vt)?;
                continue;
            }
            if results[k].wty() != out_sty.wty() {
                openmodelica_wasm_jit::set_engine_error_detail(format!(
                    "  {}, external `{extName}`: output {k} is {:?} in the C call but \
                     {:?} in the function declaration",
                    fn_path(),
                    results[k],
                    out_sty,
                ));
                return Err("CodegenWasmJit: external output type mismatch");
            }
            ctx.emit(we::Instruction::LocalSet(out_idx));
        }
    }
    // Release heap parameters (e.g. a String input consumed by the callee), as a
    // normal function body would; the outputs are excluded and moved out.
    release_heap_locals(&mut ctx)?;
    push_outputs(&mut ctx);
    ctx.emit(we::Instruction::End);

    let FnCtx { extra_locals, instrs, .. } = ctx;
    let mut func = we::Function::new(extra_locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// The wasm local a `VARIABLE` was interned into, if any.
fn var_slot(ctx: &FnCtx, v: &SimCodeFunction::Variable::Variable) -> Option<u32> {
    let (name, _) = var_name_ty(v).ok()?;
    ctx.locals.get(&name).map(|(slot, _)| *slot)
}

/// Initialize one local/output at function entry, in C's `varInit` order:
/// array allocation (unknown `:` dims start at size 0), record default
/// construction (C's `<Rec>_construct`), then the default binding. A
/// `bind_from_outside` variable gets only its allocation; an already-initialized
/// slot is skipped.
fn init_var(
    ctx: &mut FnCtx,
    v: &SimCodeFunction::Variable::Variable,
    array_allocs: &mut Vec<(u32, Arc<SigTy>, Vec<Arc<DAE::Dimension>>)>,
    done: &mut Vec<u32>,
) -> Result<()> {
    let SimCodeFunction::Variable::Variable::VARIABLE { name, ty, value, kind, bind_from_outside, .. } = v else {
        return Ok(());
    };
    let (vname, sty) = var_name_ty(v)?;
    let Some(slot) = var_slot(ctx, v) else { return Ok(()) };
    if done.contains(&slot) {
        return Ok(());
    }
    done.push(slot);
    let _g = PartGuard::new(format!("the declaration of `{vname}`"));
    // A `constant` is never assigned, so it aliases its shared literal instead of
    // copying it on every call (C's `arrayVarConstLiteralAlias`).
    if matches!(kind, DAE::VarKind::CONST)
        && !*bind_from_outside
        && let Some(val) = value
        && shared_lits::is_shared(val)
    {
        array_allocs.retain(|(i, ..)| *i != slot);
        let w = compile_exp(ctx, val)?;
        coerce(ctx, w, sty.wty());
        ctx.emit(we::Instruction::LocalSet(slot));
        return Ok(());
    }
    if let Some(k) = array_allocs.iter().position(|(i, ..)| *i == slot) {
        let (_, elem, dims) = array_allocs.remove(k);
        emit_array_alloc(ctx, slot, &elem, &dims)?;
    }
    if *bind_from_outside {
        return Ok(());
    }
    match &sty {
        SigTy::Record { .. } => {
            emit_record_default(ctx, ty)?;
            ctx.emit(we::Instruction::LocalSet(slot));
        }
        SigTy::Array { elem, .. } if matches!(&**elem, SigTy::Record { .. }) => {
            emit_array_record_defaults(ctx, slot, &Types::arrayElementType(ty.clone()))?;
        }
        _ => {}
    }
    if let Some(val) = value {
        let lhs = DAE::Exp::CREF { componentRef: name.clone(), ty: ty.clone() };
        compile_assign(ctx, &lhs, val)?;
    }
    Ok(())
}

/// The dimension list of an array `VARIABLE`, consistent with [`variable_sigty`]:
/// a `T_ARRAY` `ty` carries the dimensions (flattened across nesting); otherwise
/// they live in `instDims`.
pub(super) fn var_array_dims(v: &SimCodeFunction::Variable::Variable) -> Result<Vec<Arc<DAE::Dimension>>> {
    let SimCodeFunction::Variable::Variable::VARIABLE { ty, instDims, .. } = v else {
        return Err("CodegenWasmJit: function-pointer variables not supported");
    };
    let from_ty = type_array_dims(ty);
    Ok(if from_ty.is_empty() { (&**instDims).into_iter().cloned().collect() } else { from_ty })
}

/// The dimensions carried by a `T_ARRAY` type, flattening nested `T_ARRAY`s
/// (outer dims first). Empty for a non-array type.
pub(super) fn type_array_dims(ty: &DAE::Type) -> Vec<Arc<DAE::Dimension>> {
    match ty {
        DAE::Type::T_ARRAY { ty, dims } => {
            let mut out: Vec<Arc<DAE::Dimension>> = (&**dims).into_iter().cloned().collect();
            out.extend(type_array_dims(ty));
            out
        }
        _ => Vec::new(),
    }
}

/// Allocate an array local at function entry: evaluate each dimension to an
/// `i32` (unknown `:` dims start at 0), build the runtime array of the right
/// element kind, set the dimension sizes, and store the handle in `slot`.
pub(super) fn emit_array_alloc(ctx: &mut FnCtx, slot: u32, elem: &SigTy, dims: &[Arc<DAE::Dimension>]) -> Result<()> {
    if dims.is_empty() {
        return Err("CodegenWasmJit: array local with no dimensions");
    }
    // Evaluate each dimension into a scratch local (reused for the total and the
    // per-axis size).
    let mut dim_temps = Vec::with_capacity(dims.len());
    for d in dims {
        let t = ctx.alloc_temp(WTy::I32);
        emit_dim_value(ctx, d)?;
        ctx.emit(we::Instruction::LocalSet(t));
        dim_temps.push(t);
    }
    // total = product of the dimension sizes.
    ctx.emit(we::Instruction::LocalGet(dim_temps[0]));
    for t in &dim_temps[1..] {
        ctx.emit(we::Instruction::LocalGet(*t));
        ctx.emit(we::Instruction::I32Mul);
    }
    let total_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(total_t));
    // obj = rt_array_new(elem_kind, rank, total); store into the local.
    ctx.emit(we::Instruction::I32Const(elem.elem_kind() as i32));
    ctx.emit(we::Instruction::I32Const(dims.len() as i32));
    ctx.emit(we::Instruction::LocalGet(total_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")?));
    ctx.emit(we::Instruction::LocalSet(slot));
    for (axis, t) in dim_temps.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(slot));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::LocalGet(*t));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")?));
    }
    Ok(())
}

/// Emit the `i32` size of one array dimension. An unknown (`:`) dimension is 0
/// (an empty array, resized on first whole-array assignment).
pub(super) fn emit_dim_value(ctx: &mut FnCtx, dim: &DAE::Dimension) -> Result<()> {
    match dim {
        DAE::Dimension::DIM_INTEGER { integer } => ctx.emit(we::Instruction::I32Const(*integer)),
        DAE::Dimension::DIM_BOOLEAN => ctx.emit(we::Instruction::I32Const(2)),
        DAE::Dimension::DIM_ENUM { size, .. } => ctx.emit(we::Instruction::I32Const(*size)),
        DAE::Dimension::DIM_UNKNOWN => ctx.emit(we::Instruction::I32Const(0)),
        DAE::Dimension::DIM_EXP { exp } => {
            let w = compile_exp(ctx, exp)?;
            coerce(ctx, w, WTy::I32);
        }
    }
    Ok(())
}

pub(super) fn push_outputs(ctx: &mut FnCtx) {
    for (idx, _) in ctx.outputs.clone() {
        ctx.emit(we::Instruction::LocalGet(idx));
    }
}

/// Reference-count cleanup before a return: release every heap local that is
/// not an output (outputs are moved out to the caller). Parameters are included
/// — a generated function *owns* its heap parameters (the caller passes an owned
/// reference and does not release it after the call), so they are released here
/// too. Releasing the null handle (an unassigned heap local) is a no-op.
pub(super) fn release_heap_locals(ctx: &mut FnCtx) -> Result<()> {
    let output_idxs: std::collections::HashSet<u32> = ctx.outputs.iter().map(|(i, _)| *i).collect();
    // (local index, release entry point) for each owned heap local that is not
    // an output. The entry point depends on the type (string vs array vs …).
    let mut to_release: Vec<(u32, &'static str)> = ctx
        .locals
        .values()
        .filter(|(idx, _)| !output_idxs.contains(idx) && !ctx.borrowed_locals.contains(idx))
        .filter_map(|(idx, sty)| sty.release_fn().map(|f| (*idx, f)))
        .collect();
    // Deterministic order (HashMap iteration is unspecified) for stable output.
    to_release.sort_unstable();
    for (idx, release_fn) in to_release {
        ctx.emit(we::Instruction::LocalGet(idx));
        ctx.emit(we::Instruction::Call(rt_index(release_fn)?));
    }
    Ok(())
}

/// Name and Modelica type of a `VARIABLE` (combining `ty` and `instDims`; see
/// [`variable_sigty`]). The name must be a plain `CREF_IDENT`.
pub(super) fn var_name_ty(v: &SimCodeFunction::Variable::Variable) -> Result<(String, SigTy)> {
    match v {
        SimCodeFunction::Variable::Variable::VARIABLE { name, ty, instDims, .. } => {
            Ok((cref_ident(name)?, variable_sigty(ty, instDims)?))
        }
        SimCodeFunction::Variable::Variable::FUNCTION_PTR { name, tys, args, .. } => {
            Ok((name.to_string(), closures::function_ptr_sigty(tys, args)?))
        }
    }
}

/// The identifier of a scalar `CREF_IDENT` component reference (no subscripts /
/// qualification, which only arise for arrays / records).
/// The field when a reference is `<var>.<field>` — an external call assigning one
/// member of a record output (`external "C" r.y = f(…)`).
pub(super) fn cref_field(cr: &DAE::ComponentRef) -> Option<String> {
    match cr {
        DAE::ComponentRef::CREF_QUAL { componentRef, .. } => match &**componentRef {
            DAE::ComponentRef::CREF_IDENT { ident, .. } => Some(ident.to_string()),
            _ => None,
        },
        _ => None,
    }
}

pub(super) fn cref_ident(cr: &DAE::ComponentRef) -> Result<String> {
    match cr {
        DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } => {
            if !subscriptLst.is_empty() {
                return Err("CodegenWasmJit: subscripted component reference (arrays not supported)");
            }
            Ok(ident.to_string())
        }
        DAE::ComponentRef::CREF_QUAL { .. } => return Err("CodegenWasmJit: qualified component reference (records not supported)"),
        other => return Err("CodegenWasmJit: unsupported component reference"),
    }
}
