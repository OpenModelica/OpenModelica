//! Calling external C: shared-memory marshalling, known externals, general
//! externals, native externals, error catching.

use super::*;

/// Emit an external call in a *shared-memory* module, where the import is the
/// real symbol and nothing marshals for us. Mirrors the host trampoline
/// (`call_external_in_wasm` in `dylink_wasmtime.rs`), which is C's `extFunCallC`
/// / `extFunCallF77`:
///
/// * a `String` passes its bytes, an array its elements; a C array is the
///   row-major elements themselves, a Fortran array of 2+ dimensions a
///   column-major copy, copied back if it is an output
/// * an `_Out_` scalar (every Fortran scalar) goes into an 8-byte cell whose
///   address is passed and which is read back after the call; an `_Out_` String
///   cell holds the `char*` the callee wrote
/// * a returned `char*` becomes a `String`
///
/// Every scratch allocation is released afterwards, in one pass over the same
/// argument list — including on the path a recovered `ModelicaError` takes.
pub(super) fn emit_shared_external_call(
    ctx: &mut FnCtx,
    sig: &ExtCallSig,
    extArgs: &List<Arc<SimCodeFunction::SimExtArg::SimExtArg>>,
    extReturn: &Arc<SimCodeFunction::SimExtArg::SimExtArg>,
    fn_path: &dyn Fn() -> ArcStr,
) -> Result<()> {
    use SimCodeFunction::SimExtArg::SimExtArg as A;

    /// Where a value the callee wrote lands: a declared output, or a field of one.
    struct Target {
        out_idx: u32,
        out_sty: SigTy,
        field: Option<String>,
    }
    /// What the call has to undo for one argument once the callee returns.
    enum Cleanup {
        /// A scalar/String cell: read it back into `out` (when it is an `_Out_`), free it.
        Cell { ptr: u32, ty: SigTy, out: Option<Target> },
        /// A Fortran array: copy back if it is an output, then release any scratch.
        F77Array { handle: u32, ptr: u32, is_out: bool },
        /// C's `<record>_external`: copy its fields into `out`, then free it.
        CRecord { ptr: u32, fields: Arc<Vec<(ArcStr, SigTy)>>, out: Target },
        /// A String argument: the callee got a `rt_str_data` pointer into it, so
        /// this side still owns the handle and releases it once the call is done.
        Owned { handle: u32 },
    }
    let fortran = sig.lang == ExtLang::Fortran77;
    let native = is_native_external(&sig.name);
    let mut cleanups: Vec<Cleanup> = Vec::new();
    let key = format!("ext.{}", sig.name);
    let Some(info) = ctx.by_name.get(&key) else {
        return Err("CodegenWasmJit: external import not declared");
    };
    let (index, results) = (info.index, info.sig.results.clone());
    let output_target = |ctx: &FnCtx, output_index: usize, cref: Option<&DAE::ComponentRef>| -> Result<Target> {
        let Some((out_idx, out_sty)) = ctx.outputs.get(output_index.max(1) - 1).cloned() else {
            openmodelica_wasm_jit::set_engine_error_detail(format!(
                "  {}, external `{}`: an argument writes output {} the function does not declare",
                fn_path(),
                sig.name,
                output_index,
            ));
            return Err("CodegenWasmJit: external output index out of range");
        };
        Ok(Target { out_idx, out_sty, field: cref.and_then(cref_field) })
    };

    let catch = EXT_ERROR_CATCH.with(|c| c.get());
    let mut temps: Vec<u32> = Vec::new();
    let mut saved_stack = 0;
    if let Some(tag) = catch {
        temps = results.iter().map(|r| ctx.alloc_temp(r.wty())).collect();
        saved_stack = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::Call(env_extra_index("rt_ext_stack_save")?));
        ctx.emit(we::Instruction::LocalSet(saved_stack));
        ctx.emit(we::Instruction::Block(we::BlockType::Empty)); // done
        ctx.emit(we::Instruction::Block(we::BlockType::Result(we::ValType::EXNREF))); // handler
        ctx.emit(we::Instruction::TryTable(
            we::BlockType::Empty,
            vec![we::Catch::OneRef { tag, label: 0 }].into(),
        ));
    }

    for a in &**extArgs {
        let is_out = ext_arg_output_index(a) != 0;
        let ty = match &**a {
            A::SIMEXTARGSIZE { .. } => SigTy::Int,
            A::SIMEXTARG { type_, .. } | A::SIMEXTARGEXP { type_, .. } => sig_ty(type_)?,
            _ => return Err("CodegenWasmJit: unsupported external-call argument"),
        };
        // The expression this argument passes; an `_Out_` scalar has no value to
        // read, only a cell to hand over.
        let value: Option<Arc<DAE::Exp>> = match &**a {
            A::SIMEXTARG { cref, type_, .. } => {
                Some(Arc::new(DAE::Exp::CREF { componentRef: cref.clone(), ty: type_.clone() }))
            }
            A::SIMEXTARGEXP { exp, .. } => Some(exp.clone()),
            A::SIMEXTARGSIZE { cref, type_, exp, .. } => {
                let arr = Arc::new(DAE::Exp::CREF { componentRef: cref.clone(), ty: type_.clone() });
                Some(Arc::new(DAE::Exp::SIZE { exp: arr, sz: Some(exp.clone()) }))
            }
            _ => None,
        };
        let cref: Option<&DAE::ComponentRef> = match &**a {
            A::SIMEXTARG { cref, .. } => Some(cref),
            _ => None,
        };
        let push_value = |ctx: &mut FnCtx, what: &str, wty: WTy| -> Result<()> {
            let Some(v) = &value else {
                openmodelica_wasm_jit::set_engine_error_detail(format!(
                    "  {}, external `{}`: {what} argument has no value",
                    fn_path(),
                    sig.name,
                ));
                return Err("CodegenWasmJit: external argument has no value");
            };
            let w = compile_exp(ctx, v)?;
            coerce(ctx, w, wty);
            Ok(())
        };
        match &ty {
            // Host-served: the handle, as for C; the host reorders itself.
            SigTy::Array { .. } if fortran && !native => {
                // The array handle, then its Fortran-visible address. Both are kept:
                // the copy-back needs the handle and the scratch pointer together.
                push_value(ctx, "an array", WTy::I32)?;
                let handle = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalSet(handle));
                ctx.emit(we::Instruction::LocalGet(handle));
                ctx.emit(we::Instruction::Call(rt_index("rt_f77_arr_in")?));
                let ptr = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalSet(ptr));
                ctx.emit(we::Instruction::LocalGet(ptr));
                cleanups.push(Cleanup::F77Array { handle, ptr, is_out });
            }
            SigTy::Array { .. } => {
                // C reads and writes the row-major elements in place.
                push_value(ctx, "an array", WTy::I32)?;
                if !native {
                    ctx.emit(we::Instruction::Call(rt_index("rt_array_data")?));
                }
            }
            SigTy::Str if !is_out => {
                push_value(ctx, "a String", WTy::I32)?;
                let handle = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalTee(handle));
                cleanups.push(Cleanup::Owned { handle });
                if !native {
                    ctx.emit(we::Instruction::Call(rt_index("rt_str_data")?));
                }
            }
            SigTy::Int | SigTy::Bool | SigTy::Real if !is_out && !fortran => {
                push_value(ctx, "a scalar", ty.wty())?;
            }
            SigTy::Int | SigTy::Bool | SigTy::Real | SigTy::Str => {
                // An `_Out_` cell starts zeroed; a Fortran input cell at its value.
                let cell_fn = if matches!(ty, SigTy::Real) { "rt_f77_cell_r" } else { "rt_f77_cell_i" };
                match (&value, is_out) {
                    (Some(v), false) => {
                        let w = compile_exp(ctx, v)?;
                        coerce(ctx, w, ty.wty());
                    }
                    _ if matches!(ty, SigTy::Real) => ctx.emit(we::Instruction::F64Const(0.0.into())),
                    _ => ctx.emit(we::Instruction::I32Const(0)),
                }
                ctx.emit(we::Instruction::Call(rt_index(cell_fn)?));
                let ptr = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalSet(ptr));
                ctx.emit(we::Instruction::LocalGet(ptr));
                let out = if is_out { Some(output_target(ctx, ext_arg_output_index(a), cref)?) } else { None };
                cleanups.push(Cleanup::Cell { ptr, ty: ty.clone(), out });
            }
            SigTy::Ptr => push_value(ctx, "an external-object", WTy::I32)?,
            // A record still crosses as the runtime object, not C's `<record>_external`.
            SigTy::Record { .. } if !is_out && !fortran => push_value(ctx, "a record", WTy::I32)?,
            // C writes a `<record>_external` (the fields' C types, no runtime
            // header), so it gets a scratch one and the fields are copied back.
            SigTy::Record { fields, .. } if !fortran => {
                let size = openmodelica_wasm_jit::sig::c_record_layout(fields, 4).size.max(1);
                ctx.emit(we::Instruction::I32Const(size as i32));
                ctx.emit(we::Instruction::Call(rt_index("rt_alloc")?));
                let ptr = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalSet(ptr));
                // `rt_alloc` reuses freed blocks.
                ctx.emit(we::Instruction::LocalGet(ptr));
                ctx.emit(we::Instruction::I32Const(0));
                ctx.emit(we::Instruction::I32Const(size as i32));
                ctx.emit(we::Instruction::MemoryFill(0));
                ctx.emit(we::Instruction::LocalGet(ptr));
                let out = output_target(ctx, ext_arg_output_index(a), cref)?;
                cleanups.push(Cleanup::CRecord { ptr, fields: fields.clone(), out });
            }
            other => {
                openmodelica_wasm_jit::set_engine_error_detail(format!(
                    "  {}, external `{}`: {other:?} cannot be passed to a shared-memory {}",
                    fn_path(),
                    sig.name,
                    if fortran { "FORTRAN 77 function" } else { "external \"C\" function" },
                ));
                return Err("CodegenWasmJit: unsupported shared-memory external argument type");
            }
        }
    }

    ctx.emit(we::Instruction::Call(index));

    if catch.is_some() {
        // Out of the `try_table` region: the results travel through locals so every
        // block here is empty-typed but the one the caught `exnref` lands in.
        for t in temps.iter().rev() {
            ctx.emit(we::Instruction::LocalSet(*t));
        }
        ctx.emit(we::Instruction::End); // try_table
        ctx.emit(we::Instruction::Br(1)); // done
        ctx.emit(we::Instruction::End); // handler: the exception is on the stack
        ctx.emit(we::Instruction::Call(rt_index("rt_nls_recovering")?));
        ctx.emit(we::Instruction::If(we::BlockType::Empty));
        ctx.emit(we::Instruction::LocalGet(saved_stack));
        ctx.emit(we::Instruction::Call(env_extra_index("rt_ext_stack_restore")?));
        ctx.emit(we::Instruction::Call(rt_index("rt_nls_note_assert")?));
        for c in &cleanups {
            match c {
                Cleanup::Cell { ptr, .. } => {
                    ctx.emit(we::Instruction::LocalGet(*ptr));
                    ctx.emit(we::Instruction::Call(rt_index("rt_free")?));
                }
                Cleanup::F77Array { handle, ptr, .. } => {
                    ctx.emit(we::Instruction::LocalGet(*handle));
                    ctx.emit(we::Instruction::LocalGet(*ptr));
                    ctx.emit(we::Instruction::I32Const(0));
                    ctx.emit(we::Instruction::Call(rt_index("rt_f77_arr_out")?));
                }
                // The call did not return, so nothing is copied back out of it.
                Cleanup::CRecord { ptr, .. } => {
                    ctx.emit(we::Instruction::LocalGet(*ptr));
                    ctx.emit(we::Instruction::Call(rt_index("rt_free")?));
                }
                Cleanup::Owned { handle } => {
                    ctx.emit(we::Instruction::LocalGet(*handle));
                    ctx.emit(we::Instruction::Call(rt_index("rt_release")?));
                }
            }
        }
        release_heap_locals(ctx)?;
        push_outputs(ctx);
        ctx.emit(we::Instruction::Return);
        ctx.emit(we::Instruction::End); // if
        // Not inside a residual: a `ModelicaError` ends the run, as in C.
        ctx.emit(we::Instruction::ThrowRef);
        ctx.emit(we::Instruction::End); // done
        for t in &temps {
            ctx.emit(we::Instruction::LocalGet(*t));
        }
    }

    // Store one value the callee produced (on the stack, of type `ty`) into `target`.
    let store = |ctx: &mut FnCtx, ty: &SigTy, target: &Target| -> Result<()> {
        if matches!(ty, SigTy::Str) {
            ctx.emit(we::Instruction::Call(rt_index("rt_str_from_cstr")?));
        }
        if let Some(field) = &target.field {
            let SigTy::Record { fields, .. } = &target.out_sty else {
                openmodelica_wasm_jit::set_engine_error_detail(format!(
                    "  {}, external `{}`: `{field}` is a field of an output that is not a record",
                    fn_path(),
                    sig.name,
                ));
                return Err("CodegenWasmJit: external output field on a non-record");
            };
            let vt = ctx.alloc_temp(ty.wty());
            ctx.emit(we::Instruction::LocalSet(vt));
            return store_fresh_into_field(ctx, target.out_idx, fields, field, vt);
        }
        coerce(ctx, ty.wty(), target.out_sty.wty());
        ctx.emit(we::Instruction::LocalSet(target.out_idx));
        Ok(())
    };

    // The C return value is the only thing on the stack.
    if results.len() == 1 {
        let A::SIMEXTARG { outputIndex, cref, .. } = &**extReturn else {
            return Err("CodegenWasmJit: an external return value with no declared output");
        };
        let target = output_target(ctx, *outputIndex as usize, Some(cref))?;
        let ret = sig.ret.clone().unwrap_or(SigTy::Real);
        store(ctx, &ret, &target)?;
    } else if !results.is_empty() {
        return Err("CodegenWasmJit: a shared-memory import returns more than one value");
    }

    // Read back the `_Out_` cells and release every scratch allocation.
    for c in &cleanups {
        match c {
            Cleanup::Cell { ptr, ty, out } => {
                if let Some(target) = out {
                    ctx.emit(we::Instruction::LocalGet(*ptr));
                    let getter = if matches!(ty, SigTy::Real) { "rt_f77_cell_get_r" } else { "rt_f77_cell_get_i" };
                    ctx.emit(we::Instruction::Call(rt_index(getter)?));
                    store(ctx, ty, target)?;
                }
                ctx.emit(we::Instruction::LocalGet(*ptr));
                ctx.emit(we::Instruction::Call(rt_index("rt_free")?));
            }
            Cleanup::F77Array { handle, ptr, is_out } => {
                ctx.emit(we::Instruction::LocalGet(*handle));
                ctx.emit(we::Instruction::LocalGet(*ptr));
                ctx.emit(we::Instruction::I32Const(i32::from(*is_out)));
                ctx.emit(we::Instruction::Call(rt_index("rt_f77_arr_out")?));
            }
            Cleanup::CRecord { ptr, fields, out } => {
                let c = openmodelica_wasm_jit::sig::c_record_layout(fields, 4);
                let rec = match &out.out_sty {
                    SigTy::Record { path, .. } => path.as_str(),
                    _ => "the output record",
                };
                for (i, (name, fty)) in fields.iter().enumerate() {
                    if !matches!(fty, SigTy::Real | SigTy::Int | SigTy::Bool) {
                        // As C's `recordMemberCopyToFromExternal` refuses a String.
                        openmodelica_wasm_jit::set_engine_error_detail(format!(
                            "  {}, external `{}`: cannot read output field `{name}` of `{rec}` back \
                             from C - only Real, Integer and Boolean record members are copied",
                            fn_path(),
                            sig.name,
                        ));
                        return Err("CodegenWasmJit: unsupported external output record field");
                    }
                    ctx.emit(we::Instruction::LocalGet(*ptr));
                    field_load(ctx, fty.wty(), c.offsets[i]);
                    let vt = ctx.alloc_temp(fty.wty());
                    ctx.emit(we::Instruction::LocalSet(vt));
                    store_fresh_into_field(ctx, out.out_idx, fields, name, vt)?;
                }
                ctx.emit(we::Instruction::LocalGet(*ptr));
                ctx.emit(we::Instruction::Call(rt_index("rt_free")?));
            }
            Cleanup::Owned { handle } => {
                ctx.emit(we::Instruction::LocalGet(*handle));
                ctx.emit(we::Instruction::Call(rt_index("rt_release")?));
            }
        }
    }
    Ok(())
}

/// Emit a call to a known math/string `extName` over already-lowered arguments,
/// leaving its result on the stack (the returned `SigTy` says of which type). Mirrors
/// the host-builtin path of [`compile_math_builtin`]: an imported transcendental
/// ([`BUILTINS`]) or a single-instruction math function inline. `out` is the declared
/// output type, which the `external "builtin"` operators are overloaded on.
pub(super) fn emit_known_external_call(
    ctx: &mut FnCtx,
    ext_name: &str,
    args: &[Arc<DAE::Exp>],
    out: &SigTy,
) -> Result<SigTy> {
    // `external "builtin" o = abs(v)` and the `div`/`mod` pairs
    // (`OpenModelica.Internal.{int,real}{Abs,Div,Mod}`) are the tool's own operators,
    // not C symbols. Their Integer and Real overloads share one `extName`, so a host
    // import would bind both to the same signature and hand libc's `abs(int)` a double.
    if matches!(ext_name, "abs" | "div" | "mod") {
        let args = args.iter().cloned().collect::<List<Arc<DAE::Exp>>>();
        let attr = match out {
            SigTy::Int => DAE::callAttrBuiltinInteger(),
            _ => DAE::callAttrBuiltinReal(),
        };
        return compile_math_builtin(ctx, ext_name, &args, &attr);
    }
    // `ModelicaStrings_*` functions that map directly to existing runtime string
    // ops (same lowering as the corresponding Modelica string builtins, so the
    // argument ARC is handled identically).
    match ext_name {
        "ModelicaStrings_length" => {
            str_unop(ctx, &args[0], "rt_str_len")?;
            return Ok(SigTy::Int);
        }
        "ModelicaStrings_substring" => {
            str_substring(ctx, &args[0], &args[1], &args[2])?;
            return Ok(SigTy::Str);
        }
        _ => {}
    }
    if let Some(bi) = builtin_index(ext_name) {
        let (_, params, _) = BUILTINS[bi as usize];
        if args.len() != params.len() {
            return Err("CodegenWasmJit: external argument count mismatch");
        }
        for (a, p) in args.iter().zip(params.iter()) {
            let w = compile_exp(ctx, a)?;
            coerce(ctx, w, *p);
        }
        ctx.emit(we::Instruction::Call(bi));
        return Ok(SigTy::Real);
    }
    if args.len() != 1 {
        return Err("CodegenWasmJit: external expects 1 argument");
    }
    let w = compile_exp(ctx, &args[0])?;
    coerce(ctx, w, WTy::F64);
    match ext_name {
        "sqrt" => ctx.emit(we::Instruction::F64Sqrt),
        "fabs" => ctx.emit(we::Instruction::F64Abs),
        "floor" => ctx.emit(we::Instruction::F64Floor),
        "ceil" => ctx.emit(we::Instruction::F64Ceil),
        other => return Err("CodegenWasmJit: external math function not supported"),
    }
    Ok(SigTy::Real)
}

/// Emit a call to a general external `extName` via its `ext.<extName>` host
/// import (declared in `build_sim_model`): push each already-lowered *input*
/// argument coerced to the import's parameter type, then `call`. The import's
/// results (one per external output: the C return value first, then each `_Out_`
/// pointer's value) are left on the stack in order; their `SigTy`s are returned.
thread_local! {
    /// When set, `external` calls take the real C/Fortran argument list instead
    /// of the host-trampoline shape ([`emit_shared_external_call`]): a wasm FMU,
    /// where model, runtime and ModelicaExternalC share one memory.
    pub(super) static EXTERNALS_SHARED: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
}

/// Whether externals are being lowered for a shared-memory module, which decides
/// the wasm signature an import is declared with (see
/// [`ExtCallSig::wasm_sig_c_shared`] and [`ExtCallSig::wasm_sig_f77_shared`]).
pub(crate) fn externals_shared() -> bool {
    EXTERNALS_SHARED.with(|c| c.get())
}

/// Run `f` with [`EXTERNALS_SHARED`] set, restoring it after.
pub(crate) fn with_shared_externals<T>(f: impl FnOnce() -> T) -> T {
    let prev = EXTERNALS_SHARED.with(|c| c.replace(true));
    let r = f();
    EXTERNALS_SHARED.with(|c| c.set(prev));
    r
}

thread_local! {
    /// The shared-memory externals a host serves (`om:ext/native`); their stub
    /// marshals from runtime handles, so a String or array passes as the handle.
    static NATIVE_EXTERNALS: std::cell::RefCell<HashSet<String>> = std::cell::RefCell::new(HashSet::new());
}

pub(crate) fn set_native_externals(names: impl IntoIterator<Item = String>) {
    NATIVE_EXTERNALS.with(|c| *c.borrow_mut() = names.into_iter().collect());
}

fn is_native_external(name: &str) -> bool {
    NATIVE_EXTERNALS.with(|c| c.borrow().contains(name))
}

thread_local! {
    /// The `model_error` tag, while lowering a module that catches an external
    /// `ModelicaError` rather than letting it trap. Unset for the `-d=gen`
    /// function JIT, which has no solver to recover into.
    static EXT_ERROR_CATCH: std::cell::Cell<Option<u32>> = const { std::cell::Cell::new(None) };
}

/// Lower `ext` calls under a `try_table` for `tag` until unset again.
pub(crate) fn set_ext_error_catch(tag: Option<u32>) {
    EXT_ERROR_CATCH.with(|c| c.set(tag));
}

thread_local! {
    /// The tag a failed `assert()` throws, while lowering a host-free module. Unset
    /// where a trap is the end of the run anyway, so C's `unreachable` is enough.
    static ASSERT_THROW_TAG: std::cell::Cell<Option<u32>> = const { std::cell::Cell::new(None) };
}

pub(crate) fn set_assert_throw_tag(tag: Option<u32>) {
    ASSERT_THROW_TAG.with(|c| c.set(tag));
}

/// End the computation the failed `assert()` was part of: a host-free module unwinds
/// to its `<entry>$guard`, anything else traps.
pub(super) fn emit_assert_unwind(ctx: &mut FnCtx) {
    match ASSERT_THROW_TAG.with(|c| c.get()) {
        Some(tag) => ctx.emit(we::Instruction::Throw(tag)),
        None => ctx.emit(we::Instruction::Unreachable),
    }
}

pub(super) fn emit_general_external_call(ctx: &mut FnCtx, ext_name: &str, args: &[Arc<DAE::Exp>]) -> Result<Vec<SigTy>> {
    let key = format!("ext.{ext_name}");
    let (index, params, results) = match ctx.by_name.get(&key) {
        Some(info) => (info.index, info.sig.params.clone(), info.sig.results.clone()),
        None => return Err("CodegenWasmJit: external import not declared"),
    };
    if args.len() != params.len() {
        return Err("CodegenWasmJit: external input argument count mismatch");
    }
    let catch = EXT_ERROR_CATCH.with(|c| c.get());
    let mut temps: Vec<u32> = Vec::new();
    let mut saved_stack = 0;
    if let Some(tag) = catch {
        temps = results.iter().map(|r| ctx.alloc_temp(r.wty())).collect();
        saved_stack = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::Call(env_extra_index("rt_ext_stack_save")?));
        ctx.emit(we::Instruction::LocalSet(saved_stack));
        ctx.emit(we::Instruction::Block(we::BlockType::Empty)); // done
        ctx.emit(we::Instruction::Block(we::BlockType::Result(we::ValType::EXNREF))); // handler
        ctx.emit(we::Instruction::TryTable(
            we::BlockType::Empty,
            vec![we::Catch::OneRef { tag, label: 0 }].into(),
        ));
    }

    // A heap argument reaches the host as an owned reference (reading a String
    // local retains), and the trampoline only copies out of it — so this side
    // owns it still and must release it after the call, as `str_binop` does.
    // `Strings.compare` takes two per call, which is why `Strings.find` leaked one
    // substring per position it tried.
    let mut arg_temps: Vec<(u32, &'static str)> = Vec::new();
    for (a, p) in args.iter().zip(params.iter()) {
        let w = compile_exp(ctx, a)?;
        coerce(ctx, w, p.wty());
        if let Some(release_fn) = p.release_fn() {
            let t = ctx.alloc_temp(p.wty());
            ctx.emit(we::Instruction::LocalTee(t));
            arg_temps.push((t, release_fn));
        }
    }
    ctx.emit(we::Instruction::Call(index));
    // The results sit on the stack (or in `temps`); `rt_release` leaves nothing
    // behind, so releasing here does not disturb them.
    let release_args = |ctx: &mut FnCtx| -> Result<()> {
        for (t, release_fn) in &arg_temps {
            ctx.emit(we::Instruction::LocalGet(*t));
            ctx.emit(we::Instruction::Call(rt_index(release_fn)?));
        }
        Ok(())
    };
    if catch.is_some() {
        // Out of the `try_table` region: the results travel through locals so every
        // block here is empty-typed but the one the caught `exnref` lands in.
        for t in temps.iter().rev() {
            ctx.emit(we::Instruction::LocalSet(*t));
        }
        release_args(ctx)?;
        ctx.emit(we::Instruction::End); // try_table
        ctx.emit(we::Instruction::Br(1)); // done
        ctx.emit(we::Instruction::End); // handler: the exception is on the stack
        ctx.emit(we::Instruction::Call(rt_index("rt_nls_recovering")?));
        ctx.emit(we::Instruction::If(we::BlockType::Empty));
        ctx.emit(we::Instruction::LocalGet(saved_stack));
        ctx.emit(we::Instruction::Call(env_extra_index("rt_ext_stack_restore")?));
        ctx.emit(we::Instruction::Call(rt_index("rt_nls_note_assert")?));
        release_args(ctx)?;
        release_heap_locals(ctx)?;
        push_outputs(ctx);
        ctx.emit(we::Instruction::Return);
        ctx.emit(we::Instruction::End); // if
        // Not inside a residual: a `ModelicaError` ends the run, as in C.
        ctx.emit(we::Instruction::ThrowRef);
        ctx.emit(we::Instruction::End); // done
        for t in &temps {
            ctx.emit(we::Instruction::LocalGet(*t));
        }
    } else {
        release_args(ctx)?;
    }
    Ok(results)
}

/// Intern a function variable into the locals map (allocating a wasm local slot
/// on first sight of the name), returning its `(index, type)`. Array variables
/// are additionally recorded in `array_allocs` (once per slot) for entry-time
/// allocation.
pub(super) fn intern_local(
    v: &SimCodeFunction::Variable::Variable,
    idx: &mut u32,
    extra_locals: &mut Vec<we::ValType>,
    locals: &mut HashMap<String, (u32, SigTy)>,
    array_allocs: &mut Vec<(u32, Arc<SigTy>, Vec<Arc<DAE::Dimension>>)>,
) -> Result<(u32, SigTy)> {
    let (name, sty) = var_name_ty(v)?;
    let slot = locals
        .entry(name)
        .or_insert_with(|| {
            extra_locals.push(sty.wty().val());
            let s = (*idx, sty.clone());
            *idx += 1;
            s
        })
        .clone();
    if let SigTy::Array { elem, .. } = &slot.1 {
        if !array_allocs.iter().any(|(i, ..)| *i == slot.0) {
            array_allocs.push((slot.0, elem.clone(), var_array_dims(v)?));
        }
    }
    Ok(slot)
}
