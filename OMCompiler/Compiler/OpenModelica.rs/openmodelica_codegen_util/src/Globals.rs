//! Typed global-root variables for the `openmodelica_codegen_util` crate.
//!
//! This file is **manually maintained**. See `openmodelica_util/src/Globals.rs`
//! for the design rationale.

#![allow(non_snake_case, non_upper_case_globals, clippy::type_complexity)]

use std::cell::RefCell;

thread_local! {
    // Index 25 — optionSimCode
    //
    // The current SimCode structure, set during SimCode generation.
    // None when not in a SimCode generation pass.
    pub static optionSimCode: RefCell<Option<metamodelica::Ref<openmodelica_simcode_types::SimCode::SimCode>>> =
        const { RefCell::new(None) };

    // Index 34 — fmi3VariableAliasCache
    //
    // Value reference -> the FMI 3.0 <Alias> members nested under the variable
    // with that value reference. Live only while one modelDescription.xml is
    // being written; source: SimCodeCodegenUtil.cacheFMI3VariableAliases.
    pub static fmi3VariableAliasCache: RefCell<
        Option<metamodelica::Array<metamodelica::List<metamodelica::Ref<openmodelica_simcode_types::SimCodeVar::SimVar>>>>,
    > = const { RefCell::new(None) };
}
