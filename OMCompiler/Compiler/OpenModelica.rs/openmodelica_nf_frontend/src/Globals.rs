//! Typed global-root variables for the `openmodelica_nf_frontend` crate.
//!
//! This file is **manually maintained**. See `openmodelica_util/src/Globals.rs`
//! for the design rationale.

#![allow(non_snake_case, non_upper_case_globals)]

use std::cell::RefCell;

thread_local! {
    // Index 38 — nfTopScope
    //
    // The top scope of the current frontend run, empty or a single node. Every
    // NF node refers to its enclosing scope weakly, so without this root the
    // top scope has no owner at all and `InstNode.topScope` walks off the end.
    // Written by NFInst.makeTopNode, which replaces the previous run's scope.
    pub static nfTopScope: RefCell<metamodelica::List<metamodelica::Ref<crate::NFInstNode::InstNode::InstNode>>> =
        RefCell::new(metamodelica::nil());

    // Index 39 — nfIdentityCells
    //
    // Every identity cell made during the current frontend run. A node's
    // children hold the cell weakly and a cref outlives the node value that
    // owns it, so the run owns the cells; NFInst.makeTopNode drops the
    // previous run's.
    pub static nfIdentityCells: RefCell<metamodelica::List<
        openmodelica_util_datatypes_basic::Mutable::Mutable<
            metamodelica::Ref<crate::NFInstNode::InstNode::InstNode>>>> =
        RefCell::new(metamodelica::nil());

    // Index 40 — nbCreatedVars
    //
    // Every backend variable from NBVariable.makeVarPtrCyclic. Its cref holds
    // it weakly, and NBFunctionAlias reads the cref back before the variable
    // reaches `VariablePointers`, so the run owns it in between.
    pub static nbCreatedVars: RefCell<metamodelica::List<
        openmodelica_util_datatypes_basic::Pointer::Pointer<
            metamodelica::Ref<crate::NFVariable::NFVariable>>>> =
        RefCell::new(metamodelica::nil());
}
