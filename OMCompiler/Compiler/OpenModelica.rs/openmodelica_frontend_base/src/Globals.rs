//! Typed global-root variables for the `openmodelica_frontend_base` crate.
//!
//! This file is **manually maintained**. It declares the `thread_local!`
//! statics for global roots whose value types are defined in this crate
//! (and therefore cannot be declared in `openmodelica_util::Globals` without
//! creating a circular dependency).
//!
//! See `openmodelica_util/src/Globals.rs` for the full design rationale.

#![allow(non_snake_case, non_upper_case_globals, clippy::type_complexity)]

use std::cell::RefCell;

// ── Thread-local roots (process-global by MetaModelica semantics) ─────────────

thread_local! {
    // Index 22 — inlineHashTable
    //
    // Hash table used during inlining. Set to Some(...) when inlining starts,
    // None when done. Source: Inline.mo.
    pub static inlineHashTable: RefCell<Option<(
        openmodelica_frontend_dump::HashTableCG::HashTable,
        crate::VarTransform::VariableReplacements,
    )>> = const { RefCell::new(None) };
}
