// Manually maintained — NOT auto-generated.
// This file defines the index constants from Global.mo and a hand-written
// `initialize()` that resets the global roots whose types are known to this
// crate.  Roots whose value types come from downstream crates (frontend /
// backend) cannot be reset here without creating circular dependencies; those
// crates are responsible for initialising their own globals.
#![allow(warnings)]
#![allow(unreachable_patterns, unreachable_code, non_camel_case_types, non_snake_case, dead_code, unused_imports, unused_variables, non_upper_case_globals, unused_mut)]

use std::sync::Arc;
use metamodelica::{sourceInfo};
use arcstr::{ArcStr, literal};

pub const MMToJLListIndex: i32 = 28;

pub const backendDAE_cseIndex: i32 = 23;

pub const backendDAE_fileSequence: i32 = 20;

pub const backendDAE_jacobianSeq: i32 = 21;

pub const backendInterface: i32 = 31;

pub const backendCevalInterface: i32 = 32;

pub const builtinEnvIndex: i32 = 14;

pub const builtinGraphIndex: i32 = 18;

pub const builtinIndex: i32 = 13;

pub const classExtends_index: i32 = 25;

pub const codegenFunctionList: i32 = 2;

pub const codegenTryThrowIndex: i32 = 1;

pub const currentInstVar: i32 = 23;

pub const fgraph_nextId: i32 = 22;

pub const flagsIndex: i32 = 17;

pub const gcProfilingIndex: i32 = 21;

pub const inferredClock_index: i32 = 31;

pub fn initialize() -> () {
    // ── Roots declared in openmodelica_util::Globals ───────────────────────
    crate::Globals::instOnlyForcedFunctions.with(|__root| *__root.borrow_mut() = None);
    crate::Globals::stackoverFlowIndex.with(|__root| *__root.borrow_mut() = None);
    crate::Globals::currentInstVar.with(|__root| *__root.borrow_mut() = None);
    crate::Globals::isInStream.with(|__root| *__root.borrow_mut() = None);
    crate::Globals::sharedLibraryCacheIndex.with(|__root| *__root.borrow_mut() = metamodelica::nil());
    crate::Globals::codegenTryThrowIndex.with(|__root| *__root.borrow_mut() = metamodelica::nil());
    crate::Globals::packageIndexCacheIndex.with(|__root| *__root.borrow_mut() = None);
    crate::Globals::profilerTime1Index.with(|__root| *__root.borrow_mut() = metamodelica::OrderedFloat(0.0_f64));
    crate::Globals::profilerTime2Index.with(|__root| *__root.borrow_mut() = metamodelica::OrderedFloat(0.0_f64));
    // NOTE: flagsIndex must NOT be reset here. MetaModelica's `Global.initialize`
    // (Global.mo) does not touch flagsIndex at all — in MM the root starts unset
    // and `Flags.getFlags` (`getGlobalRoot`) *throws* until `FlagsUtil.loadFlags`
    // lazily creates the defaults. The Rust port instead seeds the slot eagerly
    // with valid `FLAGS(..)` (see `Globals::flagsIndex`) so `getFlags` is
    // infallible. Resetting it to `NO_FLAGS` here would break that contract:
    // `getFlags` would then return `NO_FLAGS` *without failing*, so
    // `loadFlags`'s `try … else (re)initialize` never re-creates the defaults,
    // and every `getConfigValue` afterwards fails its `FLAGS(..)` pattern match.
    crate::Globals::gcProfilingIndex.with(|__root| *__root.borrow_mut() = openmodelica_util_datatypes_basic::GCExt::getProfStats());
    // ── Cross-crate roots — reset by the owning crate, not here ───────────
    // openmodelica_frontend::Globals::{rewriteRulesIndex, inlineHashTable,
    //   instNFInstCacheIndex, instNFNodeCacheIndex, instNFLookupCacheIndex}
    // openmodelica_backend::Globals::{interactiveCache}
    // Thread-local storage guarantees a fresh default on each new thread.
    ()
}

pub const inlineHashTable: i32 = 22;

pub const instHashIndex: i32 = 9;

pub const instNFInstCacheIndex: i32 = 10;

pub const instNFLookupCacheIndex: i32 = 12;

pub const instNFNodeCacheIndex: i32 = 11;

pub const instOnlyForcedFunctions: i32 = 0;

pub const interactiveCache: i32 = 26;

pub const isInStream: i32 = 27;

pub const iteratorIndex: i32 = 5;

pub const maxFunctionFileLength: i32 = 50;

pub const operatorOverloadingCache: i32 = 24;

pub const optionSimCode: i32 = 25;

pub const packageIndexCacheIndex: i32 = 29;

pub const profilerTime1Index: i32 = 15;

pub const profilerTime2Index: i32 = 16;

pub const recursionDepthLimit: i32 = 256;

pub const rewriteRulesIndex: i32 = 19;

pub const sharedLibraryCacheIndex: i32 = 30;

pub const simulationData: i32 = 0;

pub const stackoverFlowIndex: i32 = 20;

pub const strongComponent_index: i32 = 24;

pub const symbolTable: i32 = 3;

pub const tmpVariableIndex: i32 = 4;

