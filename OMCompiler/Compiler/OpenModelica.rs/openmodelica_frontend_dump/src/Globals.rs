//! Typed global-root variables for the `openmodelica_frontend_dump` crate.
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
    // Index 31 — backendInterface
    //
    // Function table populated by backend registration (frontend_dump side).
    // See FrontEnd/BackendInterface.mo (upstream).
    //
    // A `todo!()` initializer is unsound here: a thread-local's lazy
    // initializer runs on the *first* `.with()` access, and `setBackendInterface`
    // registers the table via `.with(|r| *r.borrow_mut() = ...)` — a write —
    // so the `todo!()` panicked before registration could store anything.
    // Seed with the generated `Default`, whose fields are placeholder closures
    // that panic only if *called* before registration. The registration
    // overwrites them, so the placeholders are never invoked in practice.
    pub static backendInterface: RefCell<crate::BackendInterface::BackendInterfaceFunctions> =
        RefCell::new(<crate::BackendInterface::BackendInterfaceFunctions as ::std::default::Default>::default());
}
