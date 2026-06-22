//! Typed global-root variables for the `openmodelica_backend` crate.
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

// ── Thread-local roots (process-global by MetaModelica semantics) ─────────────

thread_local! {
    // Index 3 — symbolTable
    //
    // The compiler symbol table. `SymbolTable.reset()` installs the real
    // (empty) table at startup, but it does so via `symbolTable.with(...)`,
    // and a thread-local's lazy initializer runs on the *first* `.with()`
    // access — including a write. A `todo!()` initializer therefore panicked
    // before `reset()` could store anything. Seed with the default empty
    // `SymbolTable` (same shape `reset()` builds) so the slot is valid on
    // first touch; it is overwritten by `reset()`/`update()` as before.
    pub static symbolTable: RefCell<Arc<crate::SymbolTable::SymbolTable>> =
        RefCell::new(Arc::new(<crate::SymbolTable::SymbolTable as ::std::default::Default>::default()));

    // Index 19 — rewriteRulesIndex
    //
    // Optional list of active rewrite rules. Set to Some(rules) when a
    // rewrite-rule file is loaded; None otherwise.
    // Source: RewriteRules.mo.
    pub static rewriteRulesIndex: RefCell<Option<Arc<metamodelica::List<crate::RewriteRules::Rule>>>> =
        const { RefCell::new(None) };

    // Index 25 — optionSimCode
    //
    // The current SimCode structure, set during SimCode generation.
    // None when not in a SimCode generation pass.
    pub static optionSimCode: RefCell<Option<openmodelica_simcode_types::SimCode::SimCode>> =
        const { RefCell::new(None) };

    // Index 26 — interactiveCache
    //
    // Declared in `openmodelica_backend_main/src/Globals.rs`: its value type
    // includes `Interactive.GraphicEnvCache`, defined in backend_main, which
    // this crate does not depend on. See `global_root_var_path`'s crate
    // override for `interactiveCache`.
}
