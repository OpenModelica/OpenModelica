//! Compiling one function: body, locals, outputs, heap release.

use super::*;

pub(crate) fn compile_function(
    f: &SimCodeFunction::Function::Function,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    CURRENT_FN.with(|c| *c.borrow_mut() = function_path(f));
    let out = compile_boxed(f, by_name, literals);
    CURRENT_FN.with(|c| c.borrow_mut().clear());
    out
}

/// Compile a function that has a `$flat` variant: `(boxed body, flat body)`. The
/// flat body is compiled once and the boxed one wraps it; if the flat body cannot
/// be lowered, the boxed body is compiled as usual and the flat one wraps it.
pub(crate) fn compile_function_variants(
    f: &SimCodeFunction::Function::Function,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
    boxed_index: u32,
    flat_index: u32,
) -> Result<(we::Function, we::Function)> {
    CURRENT_FN.with(|c| *c.borrow_mut() = function_path(f));
    let (_, sig) = function_signature(f)?;
    openmodelica_error::ErrorExt::setCheckpoint(FLAT_VARIANT_CHECKPOINT);
    let out = match compile_function_body(f, by_name, literals, FlatMode::Variant) {
        Ok(flat) => {
            openmodelica_error::ErrorExt::delCheckpoint(FLAT_VARIANT_CHECKPOINT);
            variant_wrapper(&sig, true, flat_index, by_name, literals).map(|boxed| (boxed, flat))
        }
        Err(_) => {
            openmodelica_error::ErrorExt::rollBack(FLAT_VARIANT_CHECKPOINT);
            compile_boxed(f, by_name, literals).and_then(|boxed| {
                variant_wrapper(&sig, false, boxed_index, by_name, literals).map(|flat| (boxed, flat))
            })
        }
    };
    CURRENT_FN.with(|c| c.borrow_mut().clear());
    out
}

const FLAT_VARIANT_CHECKPOINT: ArcStr = arcstr::literal!("wasm-jit flat variant");
const FLAT_LOCALS_CHECKPOINT: ArcStr = arcstr::literal!("wasm-jit flat locals");

#[derive(Clone, Copy, PartialEq)]
enum FlatMode {
    Off,
    /// Record outputs and locals of a flat type are held field by field.
    Locals,
    /// As `Locals`, and so are the record inputs: the `$flat` variant.
    Variant,
}

/// The boxed body, holding flat record locals field by field unless that fails.
fn compile_boxed(
    f: &SimCodeFunction::Function::Function,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    if !has_flat_locals(f) {
        return compile_function_body(f, by_name, literals, FlatMode::Off);
    }
    openmodelica_error::ErrorExt::setCheckpoint(FLAT_LOCALS_CHECKPOINT);
    match compile_function_body(f, by_name, literals, FlatMode::Locals) {
        Ok(func) => {
            openmodelica_error::ErrorExt::delCheckpoint(FLAT_LOCALS_CHECKPOINT);
            Ok(func)
        }
        Err(_) => {
            openmodelica_error::ErrorExt::rollBack(FLAT_LOCALS_CHECKPOINT);
            compile_function_body(f, by_name, literals, FlatMode::Off)
        }
    }
}

fn has_flat_locals(f: &SimCodeFunction::Function::Function) -> bool {
    let SimCodeFunction::Function::Function::FUNCTION { outVars, variableDeclarations, .. } = f else {
        return false;
    };
    (&**outVars)
        .into_iter()
        .chain(&**variableDeclarations)
        .any(|v| var_name_ty(v).is_ok_and(|(_, t)| flat_fields(&t).is_some()))
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
    mode: FlatMode,
) -> Result<we::Function> {
    if matches!(f, SimCodeFunction::Function::Function::EXTERNAL_FUNCTION { .. }) {
        return compile_external_function(f, by_name, literals);
    }
    let SimCodeFunction::Function::Function::FUNCTION { outVars, functionArguments, variableDeclarations, body, .. } = f
    else {
        return Err("CodegenWasmJit: only plain FUNCTIONs are supported");
    };

    let mut locals: HashMap<String, (u32, SigTy)> = HashMap::default();
    let mut flat: HashMap<String, FlatVar> = HashMap::default();
    let mut idx: u32 = 0;
    // Parameters first (wasm locals 0..n_params).
    for v in &**functionArguments {
        let (name, sty) = var_name_ty(v)?;
        match flat_fields(&sty) {
            Some(fields) if mode == FlatMode::Variant => {
                let n = fields.len() as u32;
                flat.insert(name, FlatVar { fields: fields.clone(), locals: (idx..idx + n).collect() });
                idx += n;
            }
            _ => {
                locals.insert(name, (idx, sty));
                idx += 1;
            }
        }
    }
    let n_params = idx;
    let mut extra_locals: Vec<we::ValType> = Vec::new();
    let mut outputs: Vec<(u32, SigTy)> = Vec::new();
    let mut flat_outs: Vec<Option<String>> = Vec::new();
    // Array locals/outputs to allocate at function entry (see `emit_array_alloc`):
    // (local index, element type, dimension specs). Inputs are excluded — they
    // are passed in already built.
    let mut array_allocs: Vec<(u32, Arc<SigTy>, Vec<metamodelica::Ref<DAE::Dimension>>)> = Vec::new();
    // A flat output or local, unless the name is already taken.
    let mut intern_flat = |v: &SimCodeFunction::Variable::Variable,
                           idx: &mut u32,
                           extra_locals: &mut Vec<we::ValType>,
                           locals: &HashMap<String, (u32, SigTy)>|
     -> Result<Option<String>> {
        let (name, sty) = var_name_ty(v)?;
        let Some(fields) = flat_fields(&sty).filter(|_| mode != FlatMode::Off) else { return Ok(None) };
        if locals.contains_key(&name) {
            return Ok(None);
        }
        if !flat.contains_key(&name) {
            let vars = fields
                .iter()
                .map(|(_, t)| {
                    extra_locals.push(t.wty().val());
                    *idx += 1;
                    *idx - 1
                })
                .collect();
            flat.insert(name.clone(), FlatVar { fields: fields.clone(), locals: vars });
        }
        Ok(Some(name))
    };
    // Outputs next, then local declarations. An output is often also listed in
    // `variableDeclarations` (the function body assigns to it through the same
    // name); it must map to a single local, so a name already allocated as an
    // input or output is reused rather than given a fresh slot.
    for v in &**outVars {
        match intern_flat(v, &mut idx, &mut extra_locals, &locals)? {
            Some(name) => {
                outputs.push((u32::MAX, var_name_ty(v)?.1));
                flat_outs.push(Some(name));
            }
            None => {
                outputs.push(intern_local(v, &mut idx, &mut extra_locals, &mut locals, &mut array_allocs)?);
                flat_outs.push(None);
            }
        }
    }
    for v in &**variableDeclarations {
        if intern_flat(v, &mut idx, &mut extra_locals, &locals)?.is_none() {
            intern_local(v, &mut idx, &mut extra_locals, &mut locals, &mut array_allocs)?;
        }
    }

    let mut ctx = FnCtx { locals, extra_locals, n_params, outputs, by_name, literals, instrs: Vec::new(), ctrl_depth: 0, loops: Vec::new(), borrowed_locals: Vec::new(), null_locals: Vec::new(), elem_ptr_tmp: None, src_loc: None, sim: None, dt_local_cons: false, dt_fallback: None, flat, flat_outs, flat_results: mode == FlatMode::Variant };
    borrow_record_params(&mut ctx, functionArguments, Some(body))?;
    // In declaration order, like C's `varInit` loop: a declaration's dimensions
    // may read an earlier one (`Integer n = size(x,1); Real delta[n-1]`), so
    // allocation and binding must interleave. `variableDeclarations` already
    // contains the outputs; one missing from it is initialized first.
    let decl_names: HashSet<String> =
        (&**variableDeclarations).into_iter().filter_map(|v| var_name_ty(v).ok().map(|(n, _)| n)).collect();
    let loose_outs: Vec<_> = (&**outVars)
        .into_iter()
        .filter(|v| !var_name_ty(v).is_ok_and(|(n, _)| decl_names.contains(&n)))
        .collect();
    let mut done: Vec<u32> = Vec::new();
    for v in loose_outs.into_iter().chain(&**variableDeclarations) {
        init_var(&mut ctx, v, &mut array_allocs, &mut done, body)?;
    }
    compile_stmts(&mut ctx, body)?;
    // Fall-through return: release heap locals, push the output locals and end.
    release_heap_locals(&mut ctx)?;
    push_outputs(&mut ctx)?;
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

    let mut locals: HashMap<String, (u32, SigTy)> = HashMap::default();
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
    let mut array_allocs: Vec<(u32, Arc<SigTy>, Vec<metamodelica::Ref<DAE::Dimension>>)> = Vec::new();
    for v in &**outVars {
        let slot = intern_local(v, &mut idx, &mut extra_locals, &mut locals, &mut array_allocs)?;
        outputs.push(slot);
    }
    for v in &**biVars {
        intern_local(v, &mut idx, &mut extra_locals, &mut locals, &mut array_allocs)?;
    }

    let mut ctx = FnCtx { locals, extra_locals, n_params, outputs, by_name, literals, instrs: Vec::new(), ctrl_depth: 0, loops: Vec::new(), borrowed_locals: Vec::new(), null_locals: Vec::new(), elem_ptr_tmp: None, src_loc: None, sim: None, dt_local_cons: false, dt_fallback: None, flat: HashMap::default(), flat_outs: Vec::new(), flat_results: false };
    borrow_record_params(&mut ctx, funArgs, None)?;
    // In the order the C body emits them: `extFunCallF77` appends the `biVars` to
    // the *outputAlloc* buffer, ahead of the outputs (`output Real x[max(nrow,
    // ncol)] = cat(…nrow…)` reads them); `extFunCallC` appends them behind.
    let lang = external_import_sig(f).map(|s| s.lang).unwrap_or(ExtLang::C);
    let ordered: Vec<&metamodelica::Ref<SimCodeFunction::Variable::Variable>> = match lang {
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
    let lower_arg = |a: &A| -> Result<Option<metamodelica::Ref<DAE::Exp>>> {
        let is_out = ext_arg_output_index(a) != 0;
        Ok(match a {
            // An output array is pre-allocated and passed by pointer, like an input.
            A::SIMEXTARG { cref, type_, .. } if !is_out || matches!(sig_ty_quiet(type_), Ok(SigTy::Array { .. })) => {
                Some(metamodelica::Ref::new(DAE::Exp::CREF { componentRef: cref.clone(), ty: type_.clone() }))
            }
            A::SIMEXTARG { .. } => None,
            A::SIMEXTARGEXP { exp, .. } => Some(exp.clone()),
            // `size(array, dim)`: `cref`+`type_` are the array (full type), `exp`
            // is the 1-based dimension index. Lower as a `size(cref, exp)`
            // expression → `rt_array_dim`. (Pushing `exp` alone would pass the
            // dimension index itself as the C `int`, not the size.)
            A::SIMEXTARGSIZE { cref, type_, exp, .. } => {
                let arr = metamodelica::Ref::new(DAE::Exp::CREF { componentRef: cref.clone(), ty: type_.clone() });
                Some(metamodelica::Ref::new(DAE::Exp::SIZE { exp: arr, sz: Some(exp.clone()) }))
            }
            other => return Err("CodegenWasmJit: unsupported external-call argument"),
        })
    };

    // Input-side arguments (both known and general externals pass these by value).
    let mut input_args: Vec<metamodelica::Ref<DAE::Exp>> = Vec::new();
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
            push_outputs(&mut ctx)?;
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
    push_outputs(&mut ctx)?;
    ctx.emit(we::Instruction::End);

    let FnCtx { extra_locals, instrs, .. } = ctx;
    let mut func = we::Function::new(extra_locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Record parameters are borrowed from the caller. One the body assigns to is
/// copied on entry instead, so the caller's value stays untouched.
fn borrow_record_params(
    ctx: &mut FnCtx,
    params: &List<metamodelica::Ref<SimCodeFunction::Variable::Variable>>,
    body: Option<&List<metamodelica::Ref<DAE::Statement>>>,
) -> Result<()> {
    for v in &**params {
        let (name, sty) = var_name_ty(v)?;
        if !matches!(sty, SigTy::Record { .. }) {
            continue;
        }
        let Some(slot) = var_slot(ctx, v) else { continue };
        if body.is_some_and(|b| stmts_assign_to(b, &name)) {
            ctx.emit(we::Instruction::LocalGet(slot));
            ctx.emit(we::Instruction::Call(rt_index("rt_record_copy")?));
            ctx.emit(we::Instruction::LocalSet(slot));
        } else {
            ctx.borrowed_locals.push(slot);
        }
    }
    Ok(())
}

fn stmts_assign_to(stmts: &List<metamodelica::Ref<DAE::Statement>>, name: &str) -> bool {
    (&**stmts).into_iter().any(|s| stmt_assigns_to(s, name))
}

fn stmt_assigns_to(s: &DAE::Statement, name: &str) -> bool {
    use DAE::Statement as S;
    let lhs_is = |e: &DAE::Exp| match e {
        DAE::Exp::CREF { componentRef, .. } => match &**componentRef {
            DAE::ComponentRef::CREF_IDENT { ident, .. } | DAE::ComponentRef::CREF_QUAL { ident, .. } => ident.as_str() == name,
            _ => true,
        },
        _ => true,
    };
    let else_assigns = |mut e: &DAE::Else| loop {
        match e {
            DAE::Else::NOELSE => return false,
            DAE::Else::ELSE { statementLst } => return stmts_assign_to(statementLst, name),
            DAE::Else::ELSEIF { statementLst, else_, .. } => {
                if stmts_assign_to(statementLst, name) {
                    return true;
                }
                e = else_;
            }
        }
    };
    match s {
        S::STMT_ASSIGN { exp1, .. } => lhs_is(exp1),
        S::STMT_ASSIGN_ARR { lhs, .. } => lhs_is(lhs),
        S::STMT_TUPLE_ASSIGN { expExpLst, .. } => (&**expExpLst).into_iter().any(|e| lhs_is(e)),
        S::STMT_IF { statementLst, else_, .. } => stmts_assign_to(statementLst, name) || else_assigns(else_),
        S::STMT_FOR { statementLst, .. }
        | S::STMT_PARFOR { statementLst, .. }
        | S::STMT_WHILE { statementLst, .. } => stmts_assign_to(statementLst, name),
        S::STMT_WHEN { statementLst, elseWhen, .. } => {
            stmts_assign_to(statementLst, name) || elseWhen.as_ref().is_some_and(|w| stmt_assigns_to(w, name))
        }
        S::STMT_FAILURE { body, .. } => stmts_assign_to(body, name),
        S::STMT_ASSERT { .. }
        | S::STMT_TERMINATE { .. }
        | S::STMT_REINIT { .. }
        | S::STMT_NORETCALL { .. }
        | S::STMT_RETURN { .. }
        | S::STMT_BREAK { .. }
        | S::STMT_CONTINUE { .. } => false,
        _ => true,
    }
}

/// Whether the first top-level statement that mentions `name` assigns it as a
/// whole without reading it, so nothing can see it before that.
fn assigned_whole_first(stmts: &List<metamodelica::Ref<DAE::Statement>>, name: &str) -> bool {
    for s in &**stmts {
        let (lhs, rhs) = match &**s {
            DAE::Statement::STMT_ASSIGN { exp1, exp, .. } | DAE::Statement::STMT_ASSIGN_ARR { lhs: exp1, exp, .. } => (exp1, exp),
            _ => return false,
        };
        if exp_mentions(rhs, name) {
            return false;
        }
        if let DAE::Exp::CREF { componentRef, .. } = &**lhs
            && let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = &**componentRef
            && ident.as_str() == name
        {
            return subscriptLst.is_empty();
        }
        if exp_mentions(lhs, name) {
            return false;
        }
    }
    false
}

fn exp_mentions(e: &metamodelica::Ref<DAE::Exp>, name: &str) -> bool {
    let name = name.to_string();
    let visit = move |e: metamodelica::Ref<DAE::Exp>, found: i32| -> Result<(metamodelica::Ref<DAE::Exp>, i32)> {
        let hit = match &*e {
            DAE::Exp::CREF { componentRef, .. } => match &**componentRef {
                DAE::ComponentRef::CREF_IDENT { ident, .. } | DAE::ComponentRef::CREF_QUAL { ident, .. } => ident.as_str() == name,
                _ => false,
            },
            _ => false,
        };
        Ok((e, found | hit as i32))
    };
    Expression::traverseExpBottomUp(e.clone(), Arc::new(visit), 0).map_or(true, |(_, found)| found != 0)
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
    array_allocs: &mut Vec<(u32, Arc<SigTy>, Vec<metamodelica::Ref<DAE::Dimension>>)>,
    done: &mut Vec<u32>,
    body: &List<metamodelica::Ref<DAE::Statement>>,
) -> Result<()> {
    let SimCodeFunction::Variable::Variable::VARIABLE { name, ty, value, kind, bind_from_outside, .. } = v else {
        return Ok(());
    };
    let (vname, sty) = var_name_ty(v)?;
    if let Some(fv) = flat_var(ctx, &vname).cloned() {
        if fv.locals[0] < ctx.n_params || done.contains(&fv.locals[0]) {
            return Ok(());
        }
        done.push(fv.locals[0]);
        let lhs = DAE::Exp::CREF { componentRef: name.clone(), ty: ty.clone() };
        return match value {
            _ if *bind_from_outside => Ok(()),
            Some(val) => compile_assign(ctx, &lhs, val),
            None if assigned_whole_first(body, &vname) => Ok(()),
            None => {
                let (_, vals) = record_default_values(ctx, ty)?;
                for (v, l) in vals.iter().zip(&fv.locals) {
                    ctx.emit(we::Instruction::LocalGet(*v));
                    ctx.emit(we::Instruction::LocalSet(*l));
                }
                Ok(())
            }
        };
    }
    let Some(slot) = var_slot(ctx, v) else { return Ok(()) };
    if done.contains(&slot) {
        return Ok(());
    }
    done.push(slot);
    let _g = PartGuard::new(format!("the declaration of `{vname}`"));
    // A `constant` is never assigned, so it aliases its shared literal instead of
    // copying it on every call (C's `arrayVarConstLiteralAlias`). The pool keeps
    // the literal alive, so the local borrows it and every read retains as usual.
    if matches!(kind, DAE::VarKind::CONST)
        && !*bind_from_outside
        && let Some(val) = value
        && shared_lits::is_shared(val)
    {
        array_allocs.retain(|(i, ..)| *i != slot);
        shared_lits::compile_borrowed(ctx, val);
        ctx.emit(we::Instruction::LocalSet(slot));
        ctx.borrowed_locals.push(slot);
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
        // The null handle until a whole-record assignment replaces it.
        SigTy::Record { .. } if value.is_some() || assigned_whole_first(body, &vname) => ctx.null_locals.push(slot),
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
pub(super) fn var_array_dims(v: &SimCodeFunction::Variable::Variable) -> Result<Vec<metamodelica::Ref<DAE::Dimension>>> {
    let SimCodeFunction::Variable::Variable::VARIABLE { ty, instDims, .. } = v else {
        return Err("CodegenWasmJit: function-pointer variables not supported");
    };
    let from_ty = type_array_dims(ty);
    Ok(if from_ty.is_empty() { (&**instDims).into_iter().cloned().collect() } else { from_ty })
}

/// The dimensions carried by a `T_ARRAY` type, flattening nested `T_ARRAY`s
/// (outer dims first). Empty for a non-array type.
pub(super) fn type_array_dims(ty: &DAE::Type) -> Vec<metamodelica::Ref<DAE::Dimension>> {
    match ty {
        DAE::Type::T_ARRAY { ty, dims } => {
            let mut out: Vec<metamodelica::Ref<DAE::Dimension>> = (&**dims).into_iter().cloned().collect();
            out.extend(type_array_dims(ty));
            out
        }
        _ => Vec::new(),
    }
}

/// Allocate an array local at function entry: evaluate each dimension to an
/// `i32` (unknown `:` dims start at 0), build the runtime array of the right
/// element kind, set the dimension sizes, and store the handle in `slot`.
pub(super) fn emit_array_alloc(ctx: &mut FnCtx, slot: u32, elem: &SigTy, dims: &[metamodelica::Ref<DAE::Dimension>]) -> Result<()> {
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

pub(super) fn push_outputs(ctx: &mut FnCtx) -> Result<()> {
    for (k, (idx, _)) in ctx.outputs.clone().into_iter().enumerate() {
        let fv = ctx.flat_outs.get(k).cloned().flatten().and_then(|n| ctx.flat.get(&n).cloned());
        match fv {
            Some(v) if ctx.flat_results => {
                for l in &v.locals {
                    ctx.emit(we::Instruction::LocalGet(*l));
                }
            }
            Some(v) => box_flat(ctx, &v.fields, &v.locals)?,
            None => ctx.emit(we::Instruction::LocalGet(idx)),
        }
    }
    Ok(())
}

/// Reference-count cleanup before a return: release every heap local that is
/// not an output (outputs are moved out to the caller). Parameters are included
/// — a generated function *owns* its heap parameters (the caller passes an owned
/// reference and does not release it after the call), so they are released here
/// too. Releasing the null handle (an unassigned heap local) is a no-op.
pub(super) fn release_heap_locals(ctx: &mut FnCtx) -> Result<()> {
    let output_idxs: HashSet<u32> = ctx.outputs.iter().map(|(i, _)| *i).collect();
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
