//! Module assembly: `build_module` lays out imports, memory, globals,
//! data segments and exports.

use super::*;

/// Signature of a generated wasm function: parameter and result Modelica types
/// (`SigTy`, so String parameters/results are distinguishable for reference
/// counting; the wasm value types are `SigTy::wty`).

/// Everything the second pass needs to resolve a `CALL` to another generated
/// function: its final wasm function index and signature.
pub(crate) struct FnInfo {
    pub(crate) index: u32,
    pub(crate) sig: FnSig,
}

/// Build the wasm module for `fnCode`. Returns the encoded module bytes and the
/// input/output `SigTy`s of the main function (for the sidecar).
/// Read back what [`write_ext_sig`] wrote.
pub(crate) fn parse_ext_sig(line: &str) -> Result<ExtCallSig> {
    let mut f = line.split('\t');
    let (Some(name), Some(lang), Some(ret), Some(args), Some(outs)) =
        (f.next(), f.next(), f.next(), f.next(), f.next())
    else {
        return Err("CodegenWasmJit: malformed external \"C\" signature in the .wasm.sig sidecar");
    };
    let tys = parse_sig_types(args)?;
    if tys.len() != outs.chars().count() {
        return Err("CodegenWasmJit: external \"C\" signature has a stale output mask");
    }
    Ok(ExtCallSig {
        name: name.to_string(),
        lang: if lang == "F" { ExtLang::Fortran77 } else { ExtLang::C },
        args: tys.into_iter().zip(outs.chars()).map(|(t, o)| (t, o == '1')).collect(),
        ret: if ret == "-" { None } else { parse_sig_types(ret)?.into_iter().next() },
        declare: f.next() == Some("1"),
    })
}

/// `<symbol>\t<C|F>\t<return code or ->\t<argument codes>\t<one 0/1 per argument>`,
/// a `1` marking an `_Out_`. The flags are separate because an argument code is
/// variable-length.
pub(super) fn write_ext_sig(e: &ExtCallSig) -> String {
    let mut args = String::new();
    let mut outs = String::new();
    for (ty, is_out) in &e.args {
        ty.write_code(&mut args);
        outs.push(if *is_out { '1' } else { '0' });
    }
    let mut ret = String::new();
    match &e.ret {
        Some(t) => t.write_code(&mut ret),
        None => ret.push('-'),
    }
    let lang = if e.lang == ExtLang::Fortran77 { 'F' } else { 'C' };
    let declare = if e.declare { '1' } else { '0' };
    format!("{}\t{lang}\t{ret}\t{args}\t{outs}\t{declare}", e.name)
}

/// A lowered function module and what its sidecar has to record: the main
/// function's signature, and the `external "C"` functions the module calls out to.
pub(super) struct BuiltModule {
    pub(super) bytes: Vec<u8>,
    pub(super) in_sig: Vec<SigTy>,
    pub(super) out_sig: Vec<SigTy>,
    pub(super) ext_imports: Vec<ExtCallSig>,
}

pub(super) fn build_module(fn_code: &SimCodeFunction::FunctionCode) -> Result<BuiltModule> {
    set_record_decls(&fn_code.extraRecordDecls)?;
    // Collect the functions: the main function first (wasm index BUILTINS.len()),
    // then the dependencies.
    let mut funcs: Vec<&SimCodeFunction::Function::Function> = Vec::new();
    let Some(main) = &fn_code.mainFunction else {
        return Err("CodegenWasmJit: function code has no main function");
    };
    funcs.push(&**main);
    for f in &*fn_code.functions {
        // Plain Modelica functions, plus known scalar-math external functions
        // (lowered to a host-builtin call). Record constructors arrive as
        // `RECORD_CONSTRUCTOR` but are lowered inline (`E::RECORD`), and unknown
        // external / function-pointer dependencies cannot be JITed and, if
        // actually called, fail loudly at that call site instead.
        if matches!(&**f, SimCodeFunction::Function::Function::FUNCTION { .. })
            || external_known(f)
            || external_general(f)
        {
            funcs.push(&**f);
        }
    }

    // The `external "C"` functions reached from here, as `ext.<extName>` imports.
    let mut ext_imports: Vec<ExtCallSig> = Vec::new();
    let mut ext_seen: HashSet<String> = HashSet::new();
    for f in &funcs {
        if external_general_why(f).is_ok() {
            let sig = external_import_sig(f)?;
            if ext_seen.insert(sig.name.clone()) {
                ext_imports.push(sig);
            }
        }
    }

    // Imported functions occupy the low function indices: the `env` math
    // builtins, the `rt` heap-runtime functions, then the `ext` externals;
    // generated functions follow.
    let ext_base = (BUILTINS.len() + RT_BUILTINS.len() + ENV_EXTRA.len()) as u32;
    let base = ext_base + ext_imports.len() as u32;
    // Map mangled function name -> (local id, signature) so CALLs can resolve.
    let mut by_name: HashMap<String, FnInfo> = HashMap::new();
    for (i, sig) in ext_imports.iter().enumerate() {
        by_name.insert(format!("ext.{}", sig.name), FnInfo { index: ext_base + i as u32, sig: sig.wasm_sig() });
    }
    let mut sigs: Vec<FnSig> = Vec::with_capacity(funcs.len());
    for (id, f) in funcs.iter().enumerate() {
        let (name, sig) = function_signature(f)?;
        by_name.insert(name, FnInfo { index: base + id as u32, sig: sig.clone() });
        sigs.push(sig);
    }

    // Type section: one type per env builtin, per rt builtin, then per
    // generated function (matching the import + function order).
    let mut types = we::TypeSection::new();
    for (_, params, result) in BUILTINS {
        types.ty().function(params.iter().map(|w| w.val()), [result.val()]);
    }
    for (_, params, results) in RT_BUILTINS {
        types.ty().function(params.iter().map(|w| w.val()), results.iter().map(|w| w.val()));
    }
    for (_, params, results) in ENV_EXTRA {
        types.ty().function(params.iter().map(|w| w.val()), results.iter().map(|w| w.val()));
    }
    for sig in &ext_imports {
        types.ty().function(
            sig.wasm_params().iter().map(|s| s.wty().val()),
            sig.wasm_results().iter().map(|s| s.wty().val()),
        );
    }
    for sig in &sigs {
        types.ty().function(sig.params.iter().map(|s| s.wty().val()), sig.results.iter().map(|s| s.wty().val()));
    }

    // Import section: the runtime's shared linear memory, the `env` math
    // builtins, then the `rt` heap-runtime functions. Type indices line up with
    // the type section above.
    let mut imports = we::ImportSection::new();
    imports.import(
        "rt",
        "memory",
        we::MemoryType { minimum: 0, maximum: None, memory64: false, shared: false, page_size_log2: None },
    );
    // All three come from the runtime instance the host registers as `rt`: the math
    // builtins are in-wasm (libm), not host functions.
    for (i, (name, _, _)) in BUILTINS.iter().enumerate() {
        imports.import("rt", *name, we::EntityType::Function(i as u32));
    }
    for (j, (name, _, _)) in RT_BUILTINS.iter().enumerate() {
        imports.import("rt", *name, we::EntityType::Function((BUILTINS.len() + j) as u32));
    }
    for (k, (name, _, _)) in ENV_EXTRA.iter().enumerate() {
        imports.import("rt", *name, we::EntityType::Function((BUILTINS.len() + RT_BUILTINS.len() + k) as u32));
    }
    for (i, sig) in ext_imports.iter().enumerate() {
        imports.import("ext", &sig.name, we::EntityType::Function(ext_base + i as u32));
    }

    // Compile the function bodies first (collecting any String literals into a
    // module-wide pool), so the data-segment count is known before the code
    // section is emitted. Function references met on the way add thunks to the
    // closure pool; the module's only global holds their table base.
    closures::begin(types.len(), closure_base_global(false));
    shared_lits::begin(lit_base_global(false));
    let mut functions = we::FunctionSection::new();
    let mut bodies: Vec<we::Function> = Vec::with_capacity(funcs.len());
    let mut literals = Literals::default();
    for (id, f) in funcs.iter().enumerate() {
        functions.function(base + id as u32); // type index = base + id
        bodies.push(compile_function(f, &by_name, &mut literals)?);
    }
    let lits = shared_lits::take();
    let lit_init = lits
        .iter()
        .any(|s| s.is_some())
        .then(|| shared_lits::build_init_fn(&lits, lit_base_global(false), &by_name, &mut literals))
        .transpose()?;
    // Closure thunks, then the `start` that builds the literals and appends the
    // thunks to the shared table.
    let closure_wiring = closures::take();
    let mut thunk_indices: Vec<u32> = Vec::new();
    for (type_index, body) in closure_wiring.thunks {
        thunk_indices.push(base + bodies.len() as u32);
        functions.function(type_index);
        bodies.push(body);
    }
    for (params, results) in &closure_wiring.types {
        types.ty().function(params.iter().copied(), results.iter().copied());
    }
    let start_idx = if thunk_indices.is_empty() && lit_init.is_none() {
        None
    } else {
        let void_type = types.len();
        types.ty().function([], []);
        let lit_init_idx = lit_init.map(|f| {
            let idx = base + bodies.len() as u32;
            functions.function(void_type);
            bodies.push(f);
            idx
        });
        let idx = base + bodies.len() as u32;
        let mut f = we::Function::new([]);
        if let Some(i) = lit_init_idx {
            f.instruction(&we::Instruction::Call(i));
        }
        if !thunk_indices.is_empty() {
            closures::emit_start(&mut f, &thunk_indices, closure_base_global(false));
        }
        f.instruction(&we::Instruction::End);
        functions.function(void_type);
        bodies.push(f);
        Some(idx)
    };
    if !thunk_indices.is_empty() {
        // The thunks are reached by `call_indirect` through the runtime's table.
        imports.import("rt", "__indirect_function_table", we::EntityType::Table(we::TableType {
            element_type: we::RefType::FUNCREF,
            table64: false,
            minimum: 1,
            maximum: None,
            shared: false,
        }));
    }
    let mut code = we::CodeSection::new();
    for body in &bodies {
        code.function(body);
    }

    // Export the main function as "main".
    let mut exports = we::ExportSection::new();
    exports.export("main", we::ExportKind::Func, base);

    let mut module = we::Module::new();
    module.section(&types);
    module.section(&imports);
    module.section(&functions);
    // Flag slots need the globals even with no `start` to fill them.
    if start_idx.is_some() || !lits.is_empty() {
        // The closure-thunk table base, then one global per pool slot.
        let mut globals = we::GlobalSection::new();
        for _ in 0..lit_base_global(false) as usize + lits.len() {
            globals.global(
                we::GlobalType { val_type: we::ValType::I32, mutable: true, shared: false },
                &we::ConstExpr::i32_const(0),
            );
        }
        module.section(&globals);
    }
    module.section(&exports);
    if let Some(start_idx) = start_idx {
        module.section(&we::StartSection { function_index: start_idx });
        if !thunk_indices.is_empty() {
            let mut elements = we::ElementSection::new();
            elements.declared(we::Elements::Functions(thunk_indices.as_slice().into()));
            module.section(&elements);
        }
    }
    // String literals live in the constant pool, materialized at runtime with
    // `memory.init` (see SCONST in `compile_exp`). The DataCount section must
    // precede the code section; the Data section follows it.
    if !literals.is_empty() {
        module.section(&we::DataCountSection { count: 1 });
    }
    module.section(&code);
    if !literals.is_empty() {
        let mut data = we::DataSection::new();
        data.passive(literals.blob().iter().copied());
        module.section(&data);
    }
    let bytes = module.finish();

    // Signature types of the main function for the sidecar.
    let (in_sig, out_sig) = main_sig_types(main)?;
    Ok(BuiltModule { bytes, in_sig, out_sig, ext_imports })
}

/// The mangled name and wasm signature of a generated function.
pub(crate) fn function_signature(f: &SimCodeFunction::Function::Function) -> Result<(String, FnSig)> {
    use SimCodeFunction::Function::Function as F;
    match f {
        F::FUNCTION { name, outVars, functionArguments, .. } => {
            let params = var_sigtys(functionArguments)?;
            let results = var_sigtys(outVars)?;
            Ok((mangle(name)?, FnSig { params, results }))
        }
        // A known scalar-math `external "C"`/"builtin" function is lowered to a
        // wasm function calling the corresponding host import ([Approach C]).
        // A known scalar-math external, or a general external scalar function
        // (routed to an `ext.<extName>` host import). Both expose the Modelica
        // wrapper's own signature (funArgs -> outVars).
        F::EXTERNAL_FUNCTION { name, outVars, funArgs, .. } if external_known(f) || external_general(f) => {
            let params = var_sigtys(funArgs)?;
            let results = var_sigtys(outVars)?;
            Ok((mangle(name)?, FnSig { params, results }))
        }
        _ => return Err("CodegenWasmJit: only plain Modelica/MetaModelica FUNCTIONs and known scalar-math external functions are supported"),
    }
}
