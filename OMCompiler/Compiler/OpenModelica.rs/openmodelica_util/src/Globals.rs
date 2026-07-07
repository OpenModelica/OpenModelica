//! Typed global-root variables for the `openmodelica_util` crate.
//!
//! This file is **manually maintained**. The auto-generated code in the
//! other `.rs` files in this crate references these variables via
//! `crate::Globals::NAME` (within the crate) or
//! `openmodelica_util::Globals::NAME` (from outside).
//!
//! # Background
//!
//! MetaModelica uses `setGlobalRoot(Global.INDEX, value)` /
//! `getGlobalRoot(Global.INDEX)` to store and retrieve global state.
//! The original C MMC runtime backs this with two arrays:
//!   * thread-local (indices 0–8):  `threadData->localRoots`
//!   * process-global (indices 9+): `mmc_GC_state->global_roots`
//!
//! In Rust, every named slot is exposed as a typed `thread_local!` variable.
//!
//! # Why `thread_local!` for everything (including "global" slots)?
//!
//! `Array<T> = Rc<RefCell<Vec<T>>>` is **not** `Send`, which prevents the use
//! of `static Mutex<T>` for slots that may store arrays. We therefore use
//! `thread_local!` for *all* named roots for now.
//!
//! TODO: when `Array<T>` is changed to `Arc<Mutex<Vec<T>>>` (making it
//! `Send`), migrate the process-global roots (index 9+) to `static Mutex<T>`
//! and update `global_root_var_path` in `mmtorust/src/codegen.rs` accordingly.
//!
//! # Access pattern
//!
//! *Read:*  `NAME.with(|__root| __root.borrow().clone())`
//! *Write:* `NAME.with(|__root| *__root.borrow_mut() = value)`
//!
//! Both are infallible; no `?` propagation is needed at call sites.
//!
//! # Adding new entries
//!
//! When the compiler reports a missing `Globals::XXX`, find the type from the
//! MetaModelica source (look at the `setGlobalRoot` / `getGlobalRoot` call
//! sites for `Global.XXX`) and add a `thread_local!` declaration here.  Run
//! `cargo run -p mmtorust` afterwards to regenerate the call sites.

#![allow(non_snake_case, non_upper_case_globals)]

use std::cell::RefCell;
use std::sync::Arc;
use anyhow::Result;
use arcstr::ArcStr;
use metamodelica::SourceInfo;
use openmodelica_util_datatypes_basic::DoubleEnded;

// ── Thread-local roots (index 0–8, C: threadData->localRoots) ────────────────

thread_local! {
    /// Index 0 — Whether to force instantiation of functions only.
    ///
    /// Set to `Some(true)` before inst-only runs; `None` otherwise.
    /// Source: `CevalScript.mo` (setter), `Static.mo` (reader).
    ///
    /// Note: `Global.simulationData` also maps to index 0 but is only used in
    /// simulation builds.  The two constants are mutually exclusive; they share
    /// the same underlying slot but the compiler build only ever uses
    /// `instOnlyForcedFunctions`.
    pub static instOnlyForcedFunctions: RefCell<Option<bool>> =
        const { RefCell::new(None) };

    /// Index 1 — Codegen try/throw list.
    ///
    /// Stores the list of active try/throw levels during code generation.
    /// Source: `SimCodeFunctionUtil.mo`.
    pub static codegenTryThrowIndex: RefCell<Arc<metamodelica::List<i32>>> =
        RefCell::new(metamodelica::nil());

    /// Index 2 — Codegen function list.
    ///
    /// A double-ended mutable list of function names accumulated during
    /// SimCode generation.  Initialised to an empty list by
    /// `SimCodeUtil.initFunctionListIndex`.
    /// Source: `SimCodeUtil.mo`.
    pub static codegenFunctionList: RefCell<DoubleEnded::MutableList<ArcStr>> =
        RefCell::new(DoubleEnded::fromList(metamodelica::nil()).expect("DoubleEnded::fromList(nil) is infallible"));

    // Index 3 — symbolTable
    // Declared in openmodelica_backend::Globals (type Arc<SymbolTable::SymbolTable>
    // from openmodelica_backend::SymbolTable; circular dep if declared here).

    // Indices 4–8 are unused in the MetaModelica sources seen so far.
}

// ── Process-global roots (index 9+, C: mmc_GC_state->global_roots) ───────────
//
// These SHOULD be `static Mutex<T>` to match C semantics.  Currently using
// `thread_local!` because `Array<T> = Rc<RefCell<Vec<T>>>` is not `Send`.
// See the module-level doc comment for the upgrade path.

thread_local! {
    // Index 9  — instHashIndex
    // Declared in openmodelica_frontend::Globals.
    // Type: crate::InstHashTable::HashTable (from openmodelica_frontend).

    // Index 10 — instNFInstCacheIndex
    // Declared in openmodelica_frontend::Globals.
    // Type: Arc<List<((Absyn::Program, Arc<Absyn::Path>),
    //               (Arc<List<Arc<SCode::Element>>>, ArcStr, Arc<InstNode::InstNode>))>>

    // Index 11 — instNFNodeCacheIndex
    // Declared in openmodelica_frontend::Globals.
    // Type: Arc<List<(Absyn::Program,
    //               (Arc<List<Arc<SCode::Element>>>, Arc<InstNode::InstNode>))>>

    // Index 12 — instNFLookupCacheIndex
    // Declared in openmodelica_frontend::Globals. Same type as index 10.

    // Index 13 — builtinIndex
    // Declared in openmodelica_frontend::Globals.
    // Type: Arc<List<((i32, bool), (Absyn::Program, Arc<List<Arc<SCode::Element>>>))>>

    // Index 14 — builtinEnvIndex
    // Type: unknown; not used in generated code seen so far.

    /// Index 15 — Profiler timer 1.
    ///
    /// Accumulated wall-clock time for the first profiling slot.
    /// Initialised to 0.0; incremented by `Util.mo`.
    pub static profilerTime1Index: RefCell<metamodelica::Real> =
        const { RefCell::new(metamodelica::OrderedFloat(0.0_f64)) };

    /// Index 16 — Profiler timer 2.
    ///
    /// Accumulated wall-clock time for the second profiling slot.
    pub static profilerTime2Index: RefCell<metamodelica::Real> =
        const { RefCell::new(metamodelica::OrderedFloat(0.0_f64)) };

    /// Index 17 — Compiler flags.
    ///
    /// Read by `Flags.getFlags`; written by `FlagsUtil.saveFlags`.
    ///
    /// In MetaModelica this root starts unset, so `Flags.getFlags`
    /// (`getGlobalRoot`) *throws* until `FlagsUtil.loadFlags` lazily creates and
    /// stores the defaults on first use. MetaModelica has no way to initialise a
    /// global root statically; the Rust port does, so we seed the slot eagerly
    /// with the same defaults `loadFlags` would build (`createDebugFlags` /
    /// `createConfigFlags`). `getFlags` then always returns a valid `FLAGS(..)`
    /// and stays infallible — the lazy-init dance is unnecessary here.
    pub static flagsIndex: RefCell<crate::Flags::Flag> = RefCell::new(
        crate::Flags::Flag::FLAGS {
            debugFlags: crate::FlagsUtil::createDebugFlags(),
            configFlags: crate::FlagsUtil::createConfigFlags(),
        }
    );

    // Index 18 — builtinGraphIndex
    // Declared in openmodelica_frontend::Globals.
    // Type: Arc<List<(i32, FCore::Graph)>> — from openmodelica_frontend::Builtin.

    // Index 19 — rewriteRulesIndex
    // Declared in openmodelica_backend::Globals.
    // Type: Option<Arc<List<RewriteRules::Rule>>> — from openmodelica_backend::RewriteRules.

    /// Index 20 — Stack-overflow sentinel.
    ///
    /// Set to `None` before code that may overflow; set to `Some(1)` as a
    /// marker when stack-overflow handling has been armed for the current
    /// evaluation (see `CevalScript.cevalCallFunctionEvaluateOrGenerate`,
    /// which does `setGlobalRoot(Global.stackoverFlowIndex, SOME(1))` and tests
    /// it with `isNone(getGlobalRoot(...))`).
    /// Source: `CevalScript.mo` (`SOME(1)` store), plus `NONE()` clears in
    /// `BackendDAECreate.mo`, `Util.mo`, `DAEMode.mo`, `SimCodeMain.mo`.
    ///
    /// The stored value is `Option<Integer>` (`SOME(1)`), not `Option<()>`:
    /// the marker carries an Integer payload even though current call sites
    /// only test it via `isNone`.
    pub static stackoverFlowIndex: RefCell<Option<i32>> =
        const { RefCell::new(None) };

    /// Index 21 — GC profiling statistics.
    ///
    /// Stores the GC stats snapshot at the last call to `execStatReset`.
    /// Set and read by `ExecStat.mo`.
    pub static gcProfilingIndex: RefCell<openmodelica_util_datatypes_basic::GCExt::ProfStats> =
        RefCell::new(openmodelica_util_datatypes_basic::GCExt::getProfStats());

    // Index 22 — inlineHashTable
    // Declared in openmodelica_frontend::Globals.
    // Type: Option<(HashTableCG::HashTable, VarTransform::VariableReplacements)>
    // from openmodelica_frontend::Inline.

    /// Index 23 — Current component being instantiated.
    ///
    /// A triple of parallel arrays: component name strings, source-location
    /// records, and prefix-to-string functions.  Written by
    /// `Error.updateCurrentComponent`; read by
    /// `Error.getCurrentComponent` / `Error.addMessage`.
    ///
    /// The MetaModelica declaration (`Util/Error.mo`) is
    /// `Option<tuple<array<String>, array<SourceInfo>, array<prefixToStr>>>`
    /// and `Global.reset` initialises the slot to `NONE()`. The shape stored
    /// here must match what the generated code expects on the read side, so
    /// it is `Option<(Array<...>, Array<...>, Array<...>)>` rather than a
    /// flat triple.
    pub static currentInstVar: RefCell<
        Option<(
            metamodelica::Array<ArcStr>,
            metamodelica::Array<SourceInfo>,
            metamodelica::Array<Arc<dyn Fn(ArcStr) -> Result<ArcStr> + 'static>>,
        )>
    > = RefCell::new(None);

    // Index 24 — operatorOverloadingCache
    // Declared in openmodelica_frontend::Globals.
    // Type: (Arc<OperatorOverloading::AvlTreePathPathEnv::Tree>,
    //        Arc<OperatorOverloading::AvlTreePathOperatorTypes::Tree>)

    // Index 25 — optionSimCode
    // Declared in openmodelica_backend::Globals.
    // Type: Option<SimCode::SimCode> — from openmodelica_simcode_types::SimCode.

    // Index 26 — interactiveCache
    // Declared in openmodelica_backend::Globals.
    // Type: Option<Arc<List<(Absyn::Program, Arc<Absyn::Path>, Interactive::GraphicEnvCache)>>>

    /// Index 27 — Whether currently processing stream connectors.
    ///
    /// Set to `Some(true)` during stream-connector processing;
    /// `None` otherwise.
    /// Source: `NFConnectEquations.mo`, `ConnectUtil.mo`.
    pub static isInStream: RefCell<Option<bool>> =
        const { RefCell::new(None) };

    // Index 28 — MMToJLListIndex
    // Type: unknown — JuliaLink list. Not used in known generated code.

    // Index 29 — packageIndexCacheIndex
    // Type: Option<Arc<openmodelica_util::JSON::JSON>> — JSON is in
    // openmodelica_util so there is no circular dep.  This is a nullable root:
    // `PackageManagement`/`CevalScript` clear it via `setGlobalRoot(idx, 0)`,
    // the MetaModelica "empty" sentinel.  mmtorust detects that 0-clear
    // program-wide (see `compute_nullable_global_roots` in codegen.rs) and
    // lowers the slot as `Option`: clear → `None`, store → `Some(..)`, read →
    // unwrap-or-fail (so the surrounding `try` recomputes on a miss).
    pub static packageIndexCacheIndex: RefCell<Option<Arc<crate::JSON::JSON>>> =
        const { RefCell::new(None) };

    /// Index 30 — Shared-library lookup cache.
    ///
    /// Stores a list of `(library_path, handle)` pairs for already-opened
    /// shared libraries.  Initialised to `nil()` by `Global.initialize`.
    /// Source: `NFEvalFunction.mo`.
    pub static sharedLibraryCacheIndex: RefCell<Arc<metamodelica::List<(ArcStr, i32)>>> =
        RefCell::new(metamodelica::nil());

    // Index 31 — backendInterface
    // Declared in openmodelica_frontend::Globals.
    // Type: BackendInterface::BackendInterfaceFunctions
}
