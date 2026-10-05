//! Typed global-root variables for the `openmodelica_nf_api` crate.
//!
//! Hand-maintained, like every other `Globals.rs`: the type stored at a
//! global-root slot cannot be inferred from the MetaModelica source. See
//! `openmodelica_util/src/Globals.rs` for the design.

#![allow(non_snake_case, non_upper_case_globals)]

use std::cell::RefCell;

thread_local! {
    // Index 11 — instNFNodeCacheIndex
    //
    // The NF top scope, keyed on the Absyn program it was built from
    // (program → SCode elements, InstNode). `NFInstanceAPI.mkTop` reuses it
    // whenever it is handed the same program, which is what keeps a second
    // instance-API call from retranslating the whole library.
    pub static instNFNodeCacheIndex: RefCell<metamodelica::List<(
        openmodelica_ast::Absyn::Program,
        (metamodelica::List<metamodelica::Ref<openmodelica_frontend_types::SCode::Element>>, metamodelica::Ref<openmodelica_nf_frontend::NFInstNode::InstNode::InstNode>),
    )>> = RefCell::new(metamodelica::nil());

    // Index 41 — nfDiagramIconCache
    //
    // The icon annotation JSON of each class a diagram has drawn a component
    // of, keyed by the class' full path. A diagram dumps its components' icons,
    // and a library draws the same few dozen types across thousands of
    // diagrams; the dump depends on the class alone, because the node was
    // reached by looking up and expanding the type name without the
    // component's own modifications. Dropped with the top scope by
    // `NFInstanceAPI.clearTopScopeCache`.
    pub static nfDiagramIconCache: RefCell<Option<metamodelica::Ref<
        openmodelica_util::UnorderedMap::UnorderedMap<arcstr::ArcStr, metamodelica::Ref<openmodelica_util::JSON::JSON>>,
    >>> = const { RefCell::new(None) };
}
