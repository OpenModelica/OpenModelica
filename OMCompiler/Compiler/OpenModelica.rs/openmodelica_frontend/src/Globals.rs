//! Typed global-root variables for the `openmodelica_frontend` crate.
//!
//! This file is **manually maintained**. It declares the `thread_local!`
//! statics for global roots whose value types are defined in this crate
//! (and therefore cannot be declared in `openmodelica_util::Globals` without
//! creating a circular dependency).
//!
//! See `openmodelica_util/src/Globals.rs` for the full design rationale.

#![allow(non_snake_case, non_upper_case_globals, clippy::type_complexity)]

use std::cell::RefCell;
use std::sync::Arc;

use arcstr::ArcStr;
use openmodelica_ast::Absyn;
use openmodelica_frontend_dump::AbsynUtil;

// ── Thread-local roots (process-global by MetaModelica semantics) ─────────────

thread_local! {
    // Index 9 — instHashIndex
    //
    // The instantiation hash table. `InstHashTable.init()` sets it up, but its
    // very first statement *reads* the slot (`ht = instHashIndex; ht =
    // clear(ht); ...`), and `clear` reuses the existing bucket array and the
    // key/value function tuple. A `todo!()` initializer therefore panicked the
    // moment `init()` read the slot (a panic, not a catchable failure, so the
    // try/else in `init()` could not recover). Seed with a valid empty table
    // built exactly like `InstHashTable.emptyInstHashTable` (bucket count from
    // the instCacheSize flag, default 25343; key = Absyn.Path). `init()` then
    // reads and clears this table normally.
    pub static instHashIndex: RefCell<crate::InstHashTable::HashTable> =
        RefCell::new(openmodelica_util::BaseHashTable::emptyHashTableWork(
            openmodelica_util::Flags::getConfigInt(openmodelica_util::Flags::INST_CACHE_SIZE.clone()).unwrap_or(25343),
            (
                (Arc::new(AbsynUtil::pathHash) as Arc<dyn ::std::ops::Fn(Arc<Absyn::Path>) -> anyhow::Result<i32> + 'static>),
                (Arc::new(metamodelica::fnptr!(AbsynUtil::pathEqual, Arc<Absyn::Path>, Arc<Absyn::Path>)) as Arc<dyn ::std::ops::Fn(Arc<Absyn::Path>, Arc<Absyn::Path>) -> anyhow::Result<bool> + 'static>),
                (Arc::new(AbsynUtil::pathStringDefault) as Arc<dyn ::std::ops::Fn(Arc<Absyn::Path>) -> anyhow::Result<ArcStr> + 'static>),
                // `opaqVal` in InstHashTable is a private helper returning the
                // constant "OPAQUE_VALUE" (used only for debug dumping of cache
                // values); replicate it inline so this glue file stays
                // self-contained.
                (Arc::new(|_v: crate::InstHashTable::Value| -> anyhow::Result<ArcStr> { Ok(arcstr::literal!("OPAQUE_VALUE")) }) as Arc<dyn ::std::ops::Fn(crate::InstHashTable::Value) -> anyhow::Result<ArcStr> + 'static>),
            ),
        ));

    // Indices 10–12 — instNFInstCacheIndex / instNFNodeCacheIndex /
    // instNFLookupCacheIndex
    //
    // These NF caches store `NFInstNode.InstNode` values from
    // `openmodelica_nf_frontend` and are only accessed by `Script/NFApi.mo`.
    // They are declared in `openmodelica_backend_main::Globals` so that the old
    // frontend does not have to depend on the new-frontend crate.

    // Index 13 — builtinIndex
    //
    // Builtin function index: list of (flag × parse functions).
    // Initialised by FBuiltin.mo; reset to nil() between runs.
    pub static builtinIndex: RefCell<Arc<metamodelica::List<(
        (i32, bool),
        (openmodelica_ast::Absyn::Program, Arc<metamodelica::List<Arc<openmodelica_frontend_types::SCode::Element>>>),
    )>>> = RefCell::new(metamodelica::nil());

    // Index 18 — builtinGraphIndex
    //
    // Builtin environment graph index: list of (flag × FCore.Graph).
    // Initialised by Builtin.mo; reset to nil() between runs.
    pub static builtinGraphIndex: RefCell<Arc<metamodelica::List<(i32, openmodelica_frontend_dump::FCore::Graph)>>> =
        RefCell::new(metamodelica::nil());

    // Index 22 — inlineHashTable: moved to openmodelica_frontend_base::Globals
    // (its value type VarTransform.VariableReplacements lives in that crate now).

    // Index 24 — operatorOverloadingCache
    //
    // Pair of AVL trees caching operator-overloading resolutions.
    // Reset to empty trees by OperatorOverloading.clearCache().
    pub static operatorOverloadingCache: RefCell<(
        Arc<crate::OperatorOverloading::AvlTreePathPathEnv::Tree>,
        Arc<crate::OperatorOverloading::AvlTreePathOperatorTypes::Tree>,
    )> = RefCell::new((
        Arc::new(crate::OperatorOverloading::AvlTreePathPathEnv::Tree::EMPTY),
        Arc::new(crate::OperatorOverloading::AvlTreePathOperatorTypes::Tree::EMPTY),
    ));

    // Index 32 — backendCevalInterface
    //
    // Function table populated by backend registration before any ceval-from-
    // backend operation (cevalCallFunction, cevalInteractiveFunctions,
    // elabCallInteractive).
    //
    // A `todo!()` initializer is unsound here: a thread-local's lazy
    // initializer runs on the *first* `.with()` access, and registration
    // stores the table via `.with(|r| *r.borrow_mut() = ...)` — a write — so
    // the `todo!()` panicked before registration could store anything. Seed
    // with the generated `Default`, whose fields are placeholder closures that
    // panic only if *called* before registration. Registration overwrites
    // them, so the placeholders are never invoked in practice.
    pub static backendCevalInterface: RefCell<crate::BackendCevalInterface::BackendInterfaceFunctions> =
        RefCell::new(<crate::BackendCevalInterface::BackendInterfaceFunctions as ::std::default::Default>::default());
}
