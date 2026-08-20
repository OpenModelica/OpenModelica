// Function references (`function f(w=3)` passed to a `partialScalarFunction`
// formal, as `Modelica.Math.Nonlinear.solveOneNonlinearEquation` takes).
//
// `call_indirect` needs an exact type and the residual signature is static at
// both ends, so each `PARTEVALFUNCTION` gets a *thunk* with that signature,
// appended to the shared `rt.__indirect_function_table`. The value passed
// around is a closure object: a two-field record `{fn: Integer, env}` over an
// `env` record of the applied arguments, mirroring the C target's
// `mmc_mk_box2(0, closure_fn, env)` over `mmc_mk_boxN(0, args…)`. Nesting the
// environment keeps `fn` at a fixed offset — the call site knows nothing about
// what the callee applied. Both are ordinary runtime records, so
// `rt_record_release` frees the captured values.

use std::cell::RefCell;
use std::collections::HashMap;
use std::sync::Arc;

use arcstr::ArcStr;
use metamodelica::{List, Result};
use openmodelica_frontend_base::ComponentReference;
use openmodelica_frontend_types::DAE;
use openmodelica_simcode_types::SimCodeFunction;
use wasm_encoder as we;

use super::{
    FnCtx, FnSig, SigTy, WTy, WTyVal, coerce, compile_exp, emit_record_alloc,
    emit_record_construction, mangle, mem_arg, record_layout, rt_index, sig_ty, var_sigtys,
};

/// The closure object's own fields: the thunk's table index and the `env` handle.
fn closure_fields() -> [(ArcStr, SigTy); 2] {
    [
        (arcstr::literal!("fn"), SigTy::Int),
        (arcstr::literal!("env"), SigTy::Record { path: ArcStr::new(), fields: Arc::new(Vec::new()) }),
    ]
}

/// Byte offsets of `fn` and `env` from the closure object's base.
fn closure_offsets() -> (u32, u32) {
    let l = record_layout(&closure_fields());
    (l.data_off + l.field_off[0], l.data_off + l.field_off[1])
}

/// Synthetic field list for the environment record holding `tys` in order.
fn env_fields(tys: &[SigTy]) -> Vec<(ArcStr, SigTy)> {
    tys.iter().enumerate().map(|(i, t)| (ArcStr::from(format!("${i}")), t.clone())).collect()
}

/// Closure thunks and `call_indirect` types collected while lowering one
/// module's function bodies; module assembly drains it with [`take`].
struct ClosurePool {
    /// `(type index, body)` in table order: entry `k` takes slot `base_global + k`.
    thunks: Vec<(u32, we::Function)>,
    /// Dedup key -> slot. Same function, same applied parameters, one thunk.
    by_key: HashMap<String, u32>,
    /// Distinct thunk / `call_indirect` types; entry `i` is `type_base + i`.
    types: Vec<(Vec<we::ValType>, Vec<we::ValType>)>,
    type_base: u32,
    base_global: u32,
}

thread_local! {
    static POOL: RefCell<ClosurePool> = RefCell::new(ClosurePool {
        thunks: Vec::new(), by_key: HashMap::new(), types: Vec::new(), type_base: 0, base_global: 0,
    });
}

/// What module assembly needs from the pool once every body is lowered.
pub(crate) struct ClosureWiring {
    pub(crate) thunks: Vec<(u32, we::Function)>,
    /// Appended to the type section from the `type_base` given to [`begin`].
    pub(crate) types: Vec<(Vec<we::ValType>, Vec<we::ValType>)>,
}

/// Start collecting for a new module: the next free type index, and the global
/// the module's `start` stores the thunks' table base in.
pub(crate) fn begin(type_base: u32, base_global: u32) {
    POOL.with(|p| {
        *p.borrow_mut() = ClosurePool {
            thunks: Vec::new(),
            by_key: HashMap::new(),
            types: Vec::new(),
            type_base,
            base_global,
        };
    });
}

/// Take the collected wiring at the end of module assembly.
pub(crate) fn take() -> ClosureWiring {
    POOL.with(|p| {
        let mut pool = p.borrow_mut();
        ClosureWiring { thunks: std::mem::take(&mut pool.thunks), types: std::mem::take(&mut pool.types) }
    })
}

/// The type index of `(i32 env, params…) -> results`, interning it on first use.
fn intern_type(params: &[SigTy], results: &[SigTy]) -> u32 {
    let p: Vec<we::ValType> =
        std::iter::once(we::ValType::I32).chain(params.iter().map(|s| s.wty().val())).collect();
    let r: Vec<we::ValType> = results.iter().map(|s| s.wty().val()).collect();
    POOL.with(|pool| {
        let mut pool = pool.borrow_mut();
        match pool.types.iter().position(|(tp, tr)| *tp == p && *tr == r) {
            Some(i) => pool.type_base + i as u32,
            None => {
                pool.types.push((p, r));
                pool.type_base + pool.types.len() as u32 - 1
            }
        }
    })
}

/// The `SigTy` of a `FUNCTION_PTR` function argument — what its holder may call.
pub(crate) fn function_ptr_sigty(
    tys: &Arc<List<Arc<DAE::Type>>>,
    args: &Arc<List<Arc<SimCodeFunction::Variable::Variable>>>,
) -> Result<SigTy> {
    let results: Result<Vec<SigTy>> = (&**tys).into_iter().map(|t| sig_ty(t)).collect();
    Ok(SigTy::Func { params: Arc::new(var_sigtys(args)?), results: Arc::new(results?) })
}

/// The `T_FUNCTION` inside a `T_FUNCTION_REFERENCE_VAR`/`_FUNC` wrapper.
fn function_type(ty: &DAE::Type) -> Result<&DAE::Type> {
    match ty {
        DAE::Type::T_FUNCTION_REFERENCE_VAR { functionType }
        | DAE::Type::T_FUNCTION_REFERENCE_FUNC { functionType, .. } => Ok(functionType),
        DAE::Type::T_FUNCTION { .. } => Ok(ty),
        other => Err("CodegenWasmJit: not a function-reference type"),
    }
}

/// The formal-argument names of a function type, in declaration order.
fn func_arg_names(ty: &DAE::Type) -> Result<Vec<ArcStr>> {
    let DAE::Type::T_FUNCTION { funcArg, .. } = function_type(ty)? else {
        return Err("CodegenWasmJit: function reference without a function type");
    };
    Ok((&**funcArg).into_iter().map(|a| a.name.clone()).collect())
}

/// The residual signature a function-reference expression's value is called with.
pub(crate) fn reference_sigty(ty: &DAE::Type) -> Result<SigTy> {
    let DAE::Type::T_FUNCTION { funcArg, funcResultType, .. } = function_type(ty)? else {
        return Err("CodegenWasmJit: function reference without a function type");
    };
    let params: Result<Vec<SigTy>> = (&**funcArg).into_iter().map(|a| sig_ty(&a.ty)).collect();
    let results = match &**funcResultType {
        DAE::Type::T_NORETCALL { .. } => Vec::new(),
        DAE::Type::T_TUPLE { types, .. } => {
            (&**types).into_iter().map(|t| sig_ty(t)).collect::<Result<Vec<_>>>()?
        }
        other => vec![sig_ty(other)?],
    };
    Ok(SigTy::Func { params: Arc::new(params?), results: Arc::new(results) })
}

/// Lower a `PARTEVALFUNCTION`, leaving the owned closure handle on the stack.
pub(crate) fn compile_parteval(ctx: &mut FnCtx, exp: &DAE::Exp) -> Result<()> {
    let DAE::Exp::PARTEVALFUNCTION { path, expList, ty, origType } = exp else {
        return Err("CodegenWasmJit: not a PARTEVALFUNCTION");
    };
    let exps: Vec<&Arc<DAE::Exp>> = (&**expList).into_iter().collect();
    emit_reference(ctx, &mangle(path)?, &exps, ty, origType)
}

/// `function f()` with nothing applied, which the frontend leaves as a `CREF`
/// of function-reference type rather than a `PARTEVALFUNCTION`.
pub(crate) fn compile_fnref_cref(
    ctx: &mut FnCtx,
    cref: &DAE::ComponentRef,
    ty: &DAE::Type,
) -> Result<()> {
    let path = ComponentReference::crefToPath(Arc::new(cref.clone()))?;
    emit_reference(ctx, &mangle(&path)?, &[], ty, ty)
}

fn emit_reference(
    ctx: &mut FnCtx,
    target: &str,
    exps: &[&Arc<DAE::Exp>],
    ty: &DAE::Type,
    origType: &DAE::Type,
) -> Result<()> {
    let Some(info) = ctx.by_name.get(target) else {
        return Err("CodegenWasmJit: function reference to a function that was not compiled");
    };
    let (target_index, target_sig) = (info.index, info.sig.clone());
    // The applied parameters are the formals the residual type dropped, in
    // declaration order — `expList`'s order (C's `setDifference`).
    let all_names = func_arg_names(origType)?;
    let residual_names = func_arg_names(ty)?;
    if all_names.len() != target_sig.params.len() {
        return Err("CodegenWasmJit: function reference disagrees with the function's argument count");
    }
    let applied: Vec<usize> =
        (0..all_names.len()).filter(|i| !residual_names.contains(&all_names[*i])).collect();
    if applied.len() != exps.len() {
        return Err("CodegenWasmJit: function reference applies a different number of arguments than it drops");
    }
    let applied_tys: Vec<SigTy> = applied.iter().map(|i| target_sig.params[*i].clone()).collect();
    let slot = intern_thunk(target, target_index, &target_sig, &applied, &residual_names, &all_names)?;

    let env = ctx.alloc_temp(WTy::I32);
    let env_flds = env_fields(&applied_tys);
    if env_flds.is_empty() {
        ctx.emit(we::Instruction::I32Const(0));
    } else {
        emit_record_construction(ctx, &env_flds, &exps)?;
    }
    ctx.emit(we::Instruction::LocalSet(env));

    let layout = record_layout(&closure_fields());
    let (fn_off, env_off) = closure_offsets();
    let obj = emit_record_alloc(ctx, &layout)?;
    let base_global = POOL.with(|p| p.borrow().base_global);
    ctx.emit(we::Instruction::LocalGet(obj));
    ctx.emit(we::Instruction::GlobalGet(base_global));
    ctx.emit(we::Instruction::I32Const(slot as i32));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::I32Store(mem_arg(fn_off, 2)));
    ctx.emit(we::Instruction::LocalGet(obj));
    ctx.emit(we::Instruction::LocalGet(env));
    ctx.emit(we::Instruction::I32Store(mem_arg(env_off, 2)));
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(())
}

/// Push the environment record's field at `off`; the closure is parameter 0.
fn load_env_field(f: &mut we::Function, env_off: u32, off: u32, wty: WTy) {
    use we::Instruction as I;
    f.instruction(&I::LocalGet(0));
    f.instruction(&I::I32Load(mem_arg(env_off, 2)));
    match wty {
        WTy::I32 => f.instruction(&I::I32Load(mem_arg(off, 2))),
        WTy::F64 => f.instruction(&I::F64Load(mem_arg(off, 3))),
    };
}

/// Emit (or reuse) the thunk for `target` applying the given parameter positions
/// and return its table slot. It takes the closure, then the residual arguments,
/// reads the applied ones out of `env` and calls `target` with the full list.
fn intern_thunk(
    target: &str,
    target_index: u32,
    target_sig: &FnSig,
    applied: &[usize],
    residual_names: &[ArcStr],
    all_names: &[ArcStr],
) -> Result<u32> {
    let key = format!("{target}|{applied:?}");
    if let Some(slot) = POOL.with(|p| p.borrow().by_key.get(&key).copied()) {
        return Ok(slot);
    }
    // Residual arguments in the residual type's order, by name.
    let residual: Vec<usize> = residual_names
        .iter()
        .map(|n| all_names.iter().position(|a| a == n))
        .collect::<Option<Vec<usize>>>()
        .ok_or_else(|| "CodegenWasmJit: function reference keeps an argument the function does not have")?;
    let residual_tys: Vec<SigTy> = residual.iter().map(|i| target_sig.params[*i].clone()).collect();
    let applied_tys: Vec<SigTy> = applied.iter().map(|i| target_sig.params[*i].clone()).collect();
    let type_index = intern_type(&residual_tys, &target_sig.results);

    let env_layout = record_layout(&env_fields(&applied_tys));
    let (_, env_off) = closure_offsets();
    use we::Instruction as I;
    let mut f = we::Function::new([]);
    for i in 0..all_names.len() {
        match applied.iter().position(|a| *a == i) {
            // An applied argument: read it out of the environment, retained —
            // the target consumes its heap parameters, the closure keeps its own.
            Some(k) => {
                let off = env_layout.data_off + env_layout.field_off[k];
                load_env_field(&mut f, env_off, off, applied_tys[k].wty());
                if applied_tys[k].is_heap() {
                    load_env_field(&mut f, env_off, off, WTy::I32);
                    f.instruction(&I::Call(rt_index("rt_retain")?));
                }
            }
            // A residual argument: pushed by the caller, already owned.
            None => {
                let k = residual.iter().position(|r| *r == i).ok_or_else(|| {
                    "CodegenWasmJit: function-reference argument is neither applied nor residual"
                })?;
                f.instruction(&I::LocalGet(1 + k as u32));
            }
        }
    }
    f.instruction(&I::Call(target_index));
    f.instruction(&I::End);

    Ok(POOL.with(|p| {
        let mut pool = p.borrow_mut();
        let slot = pool.thunks.len() as u32;
        pool.thunks.push((type_index, f));
        pool.by_key.insert(key, slot);
        slot
    }))
}

/// Lower a call through a function-reference variable: push the closure (the
/// thunk's environment), the arguments, the thunk's table index, `call_indirect`.
pub(crate) fn compile_fnptr_call(
    ctx: &mut FnCtx,
    name: &str,
    args: &Arc<List<Arc<DAE::Exp>>>,
) -> Result<Vec<SigTy>> {
    let Some((local, SigTy::Func { params, results })) = ctx.locals.get(name).cloned() else {
        return Err("CodegenWasmJit: function-pointer calls are only supported through a local variable");
    };
    let argv: Vec<&Arc<DAE::Exp>> = (&**args).into_iter().collect();
    if argv.len() != params.len() {
        return Err("CodegenWasmJit: function-pointer call argument count mismatch");
    }
    let (fn_off, _) = closure_offsets();
    ctx.emit(we::Instruction::LocalGet(local)); // the closure, borrowed as `env`
    for (a, p) in argv.iter().zip(params.iter()) {
        let w = compile_exp(ctx, a)?;
        coerce(ctx, w, p.wty());
    }
    ctx.emit(we::Instruction::LocalGet(local));
    ctx.emit(we::Instruction::I32Load(mem_arg(fn_off, 2)));
    let type_index = intern_type(&params, &results);
    ctx.emit(we::Instruction::CallIndirect { type_index, table_index: 0 });
    Ok((*results).clone())
}

/// The `start` instructions appending the thunks (absolute wasm function
/// indices, in table order) to the shared table, base recorded in `base_global`.
pub(crate) fn emit_start(f: &mut we::Function, fn_indices: &[u32], base_global: u32) {
    use we::Instruction as I;
    f.instruction(&I::RefNull(we::HeapType::FUNC));
    f.instruction(&I::I32Const(fn_indices.len() as i32));
    f.instruction(&I::TableGrow(0));
    f.instruction(&I::GlobalSet(base_global));
    for (k, idx) in fn_indices.iter().enumerate() {
        f.instruction(&I::GlobalGet(base_global));
        f.instruction(&I::I32Const(k as i32));
        f.instruction(&I::I32Add);
        f.instruction(&I::RefFunc(*idx));
        f.instruction(&I::TableSet(0));
    }
}
