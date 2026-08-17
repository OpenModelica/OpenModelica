// Shared literals — the C target's `_OMC_LIT`.
//
// The backend rewrites constant String/array expressions to `SHARED_LITERAL` and
// C emits them as `static const`, so a medium property function reading a NASA
// coefficient table allocates nothing per call. Here each becomes one heap object
// built by the module's `start` into a wasm global; a use is `global.get` +
// `rt_retain`, so callers keep the ordinary owned-handle contract and the pool's
// own reference keeps the object alive. A record constructor with all-constant
// fields is hoisted the same way. The object is shared, so an assignment from one
// copies it (`value_rhs_is_fresh`).

use std::cell::{Cell, RefCell};
use std::collections::{BTreeMap, HashMap};
use std::sync::Arc;

use metamodelica::Result;
use openmodelica_frontend_types::DAE;
use wasm_encoder as we;

use super::{FnCtx, FnInfo, WTy, compile_exp, exp_sigty, rt_index};

struct LitPool {
    /// Interned literals in global order: entry `i` lives in `base_global + i`.
    exps: Vec<Arc<DAE::Exp>>,
    /// Ordered, not hashed: `MetaCmp` gives every `Exp` `Ord` (with an `Arc::ptr_eq`
    /// fast path), while `Hash` is only derived for the ones holding no array.
    by_exp: BTreeMap<Arc<DAE::Exp>, u32>,
    base_global: u32,
}

thread_local! {
    static POOL: RefCell<LitPool> =
        RefCell::new(LitPool { exps: Vec::new(), by_exp: BTreeMap::new(), base_global: 0 });
    /// Off while the pool's own initializers are lowered, so a literal is built
    /// from its constant expression instead of reading its own global.
    static HOISTING: Cell<bool> = const { Cell::new(true) };
}

/// Start collecting for a new module: the first global the literals occupy.
pub(crate) fn begin(base_global: u32) {
    POOL.with(|p| {
        *p.borrow_mut() = LitPool { exps: Vec::new(), by_exp: BTreeMap::new(), base_global };
    });
    HOISTING.with(|h| h.set(true));
}

/// The interned literals, in global order, once every body is lowered.
pub(crate) fn take() -> Vec<Arc<DAE::Exp>> {
    POOL.with(|p| core::mem::take(&mut p.borrow_mut().exps))
}

/// Whether a use of `e` reads the module-wide object rather than building a
/// fresh one — so an assignment from it needs a private copy.
pub(crate) fn is_shared(e: &DAE::Exp) -> bool {
    HOISTING.with(|h| h.get()) && hoistable(e)
}

/// Emit `e` as a reference to its module-wide literal object, or `None` when it
/// is not one.
pub(crate) fn compile(ctx: &mut FnCtx, e: &DAE::Exp) -> Result<Option<WTy>> {
    if !is_shared(e) {
        return Ok(None);
    }
    let g = intern(e);
    ctx.emit(we::Instruction::GlobalGet(g));
    ctx.emit(we::Instruction::GlobalGet(g));
    ctx.emit(we::Instruction::Call(rt_index("rt_retain")?));
    Ok(Some(WTy::I32))
}

/// The body the module's `start` calls: build every literal into its global.
pub(crate) fn build_init_fn(
    exps: &[Arc<DAE::Exp>],
    base_global: u32,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut super::Literals,
) -> Result<we::Function> {
    HOISTING.with(|h| h.set(false));
    let mut ctx = FnCtx {
        locals: HashMap::new(),
        extra_locals: Vec::new(),
        n_params: 0,
        outputs: Vec::new(),
        by_name,
        literals,
        instrs: Vec::new(),
        ctrl_depth: 0,
        loops: Vec::new(),
        borrowed_locals: Vec::new(),
        elem_ptr_tmp: None,
        src_loc: None,
        sim: None,
    };
    for (i, e) in exps.iter().enumerate() {
        if compile_exp(&mut ctx, e)? != WTy::I32 {
            return Err("CodegenWasmJit: shared literal is not a heap value");
        }
        ctx.emit(we::Instruction::GlobalSet(base_global + i as u32));
    }
    ctx.emit(we::Instruction::End);
    HOISTING.with(|h| h.set(true));
    let FnCtx { extra_locals, instrs, .. } = ctx;
    let mut f = we::Function::new(extra_locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        f.instruction(i);
    }
    Ok(f)
}

/// Intern a heap-valued constant the backend did not mark `SHARED_LITERAL`: the
/// index tables a non-scalarized for-equation loops over (C's `static const`).
pub(crate) fn intern_const(e: &DAE::Exp) -> u32 {
    intern(e)
}

fn intern(e: &DAE::Exp) -> u32 {
    POOL.with(|p| {
        let mut p = p.borrow_mut();
        let key = Arc::new(e.clone());
        if let Some(&g) = p.by_exp.get(&key) {
            return g;
        }
        let g = p.base_global + p.exps.len() as u32;
        p.exps.push(key.clone());
        p.by_exp.insert(key, g);
        g
    })
}

/// A heap-valued compile-time constant: one object can serve every use of it.
fn hoistable(e: &DAE::Exp) -> bool {
    match e {
        DAE::Exp::SHARED_LITERAL { exp, .. } => {
            matches!(exp_sigty(exp), Ok(t) if t.is_heap())
        }
        DAE::Exp::RECORD { exps, .. } => (&**exps).into_iter().all(|x| is_const(x)),
        _ => false,
    }
}

fn is_const(e: &DAE::Exp) -> bool {
    use DAE::Exp as E;
    match e {
        E::ICONST { .. } | E::RCONST { .. } | E::BCONST { .. } | E::SCONST { .. } => true,
        E::ENUM_LITERAL { .. } | E::SHARED_LITERAL { .. } => true,
        E::CAST { exp, .. } | E::UNARY { exp, .. } => is_const(exp),
        E::ARRAY { array, .. } => (&**array).into_iter().all(|x| is_const(x)),
        E::MATRIX { matrix, .. } => {
            (&**matrix).into_iter().all(|row| (&**row).into_iter().all(|x| is_const(x)))
        }
        E::RECORD { exps, .. } => (&**exps).into_iter().all(|x| is_const(x)),
        _ => false,
    }
}
