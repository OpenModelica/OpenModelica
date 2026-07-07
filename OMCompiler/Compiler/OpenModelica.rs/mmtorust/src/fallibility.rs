//! Fallibility analysis phase.
//!
//! Runs after [`crate::hierarchy::resolve_pass`] has converged and after
//! [`crate::hierarchy::detect_recursive_types`] / [`detect_types_containing_mutable`].
//!
//! Goal: classify every MetaModelica function (and every MetaModelica builtin
//! and every `external "C"` binding referenced from the sources) as
//! [`Fallibility::Fallible`] or [`Fallibility::Infallible`].  The result drives
//! codegen decisions later:
//!
//!   * Fallible function ⇒ Rust lowering returns `anyhow::Result<T>`, every
//!     call site appends `?` (or the surrounding [`crate::codegen::QMode`]
//!     equivalent).
//!   * Infallible function ⇒ Rust lowering returns the raw `T`, call sites
//!     emit a bare call expression — and when the function is referenced
//!     through a function-pointer type whose signature expects `Result<T>`,
//!     codegen wraps the value with a `fnptr!(f)` adapter so the types match.
//!
//! ## Why a dedicated phase
//!
//! Codegen used to assume every call is fallible and unconditionally appended
//! `?`. That bloats both compile times and runtime cost (every call materialises
//! a `Result`).  Determining fallibility precisely requires a global view —
//! a function is fallible iff one of its calls is fallible — so the natural
//! formulation is a fixed-point over the call graph, computed once before
//! code generation begins.  This file is the analogue of
//! [`crate::hierarchy::detect_recursive_types`] for fallibility.
//!
//! ## Definition of "fallible"
//!
//! A MetaModelica function `f` is *fallible* iff its body can fail at run time
//! via a code path that escapes the function. Concretely, `f` is fallible if
//! any of the following holds:
//!
//!  * `f` is `external "C" foo(...)` and the external `foo` is classified as
//!    [`Fallibility::Fallible`] in [`crate::external_c_calls`].
//!  * The body of `f` contains a call to `fail()` outside a `try`/`failure`
//!    boundary.
//!  * The body of `f` contains a `match` expression whose case patterns do
//!    not exhaustively cover the scrutinee (falling through every case
//!    raises a MetaModelica failure).
//!  * The body of `f` contains a `matchcontinue` expression that can exhaust
//!    its arms. A failing arm (guard or body) falls through to the *next*
//!    arm, so nothing inside an arm escapes directly; the construct fails
//!    only when no arm runs to completion. It is therefore infallible iff
//!    the patterns of its unguarded, infallible-bodied arms exhaustively
//!    cover the scrutinee — an always-succeeding `else` being the common
//!    special case. Whether an arm body is infallible depends on the
//!    call-graph fixed point, so the check is deferred (see [`McCheck`]).
//!  * The body of `f` calls some other function `g` (builtin, external, or
//!    user-defined) that is itself fallible, again outside a `try`/`failure`
//!    boundary.
//!
//! `try ... else ... end try` and `failure(...)` blocks catch failures from
//! their body, so a fallible operation inside one does *not* propagate
//! upwards.  This is approximated, not implemented, in this first iteration —
//! see [`Walk::in_catch_depth`] — to keep the initial scaffold focused.
//!
//! ## What this iteration does NOT yet do
//!
//! * Walking `for`/`while` loop bodies — these are walked uniformly with the
//!   surrounding scope (no special semantics needed for fallibility).
//! * Distinguishing `pure` external annotations.
//!
//! Calls *through* a function value (higher-order callbacks) ARE handled: see
//! [`Walk::calls_fn_value`]. Because every function value lowers to
//! `Arc<dyn Fn(...) -> Result<...>>`, invoking one is unconditionally fallible,
//! so a function that calls one of its own function-typed parameters/locals is
//! marked fallible without needing to resolve the callback's target.
//! * Refining the analysis from `Absyn::Exp`/`Absyn::Algorithm` to
//!   `typedexp::TypedExp`. The typed IR carries resolved call targets that
//!   would yield more precise results, but it is also expensive to compute
//!   (it currently runs once per function inside codegen). Re-using the typed
//!   IR here would duplicate that work; a future refactor should hoist the
//!   inference out of codegen and share the result.

use std::collections::{BTreeMap, BTreeSet};
use std::sync::Arc;

use openmodelica_ast::Absyn;

use crate::external_c_calls::{self, Fallibility};
use crate::hierarchy::{InstanceHierarchy, NameNode, NodeKind, Ty};
use crate::typedexp::resolve_call_node;
use crate::MM;

// ── Builtin classification ───────────────────────────────────────────────────

/// Fallibility classification for MetaModelica built-in functions implemented
/// in the `metamodelica` crate (see `metamodelica/src/lib.rs`).
///
/// Returns `None` if `name` is not recognised as a builtin; the caller is then
/// expected to look the name up as a user-defined or external function.
///
/// The classification mirrors what each function *actually* does today, not
/// what its current Rust signature claims: today every metamodelica function
/// returns `Result<T>` (a historical accident), but most are provably
/// infallible.  The codegen layer will eventually drop the `Result` from
/// infallible callees once this analysis is wired in.
pub fn builtin_fallibility(name: &str) -> Option<Fallibility> {
    use Fallibility::*;
    Some(match name {
        // ── Boolean — pure value logic, never fails ──────────────────────────
        "boolAnd" | "boolOr" | "boolNot" | "boolEq" | "boolString" => Infallible,

        // ── Integer arithmetic ───────────────────────────────────────────────
        // intDiv / intMod can in principle trap on divide-by-zero, but the
        // current implementation matches Modelica semantics by relying on the
        // host CPU's trap (we do not produce a `Result`). They are marked
        // Infallible to match the Rust signature; we may revisit if we
        // introduce explicit divide-by-zero checks.
        "intAdd" | "intSub" | "intMul" | "intDiv" | "intMod"
        | "intMax" | "intMin" | "intAbs" | "intNeg" => Infallible,
        "intLt" | "intLe" | "intEq" | "intNe" | "intGe" | "intGt" => Infallible,
        "intBitNot" | "intBitAnd" | "intBitOr" | "intBitXor"
        | "intBitLShift" | "intBitRShift" => Infallible,
        "intReal" | "intString" => Infallible,

        // ── Real arithmetic ──────────────────────────────────────────────────
        "realAdd" | "realSub" | "realMul" | "realDiv" | "realMod" | "realPow"
        | "realMax" | "realMin" | "realAbs" | "realNeg"
        | "realAlmostEq" => Infallible,
        "realLt" | "realLe" | "realEq" | "realNe" | "realGe" | "realGt" => Infallible,
        "realInt" | "realString" => Infallible,

        // ── String ───────────────────────────────────────────────────────────
        "stringCharInt" => Fallible,       // bails on non-singleton input
        "intStringChar" => Infallible,
        "stringInt" => Fallible,           // parse error
        "stringReal" => Fallible,          // parse error
        "stringListStringChar" => Infallible,
        "stringAppendList" | "stringDelimitList" => Infallible,
        "stringLength" | "stringEmpty" => Infallible,
        // `metamodelica::uriToFilename` fails (Result) on malformed or
        // unknown URIs and on `modelica://` packages that are not loaded,
        // matching the C `MMC_THROW` — callers catch it like any failure.
        "uriToFilename" => Fallible,
        "stringGet" => Fallible,           // index OOB
        "stringGetStringChar" => Fallible, // index OOB
        "stringUpdateStringChar" => Fallible, // bails on empty / OOB
        "stringAppend" => Infallible,
        "stringEq" | "stringEqual" | "stringCompare" => Infallible,
        "stringHash" | "stringHashDjb2" | "stringHashDjb2Continue"
        | "stringHashDjb2Mod" | "stringHashSdbm" => Infallible,
        "substring" => Fallible,           // bails on bogus range
        "listStringCharString" | "stringCharListString" => Infallible,

        // ── List ─────────────────────────────────────────────────────────────
        // listHead / listRest fail on Nil; the .get/.delete methods on Arc<List>
        // are bounds-checked. Plain `listAppend` / `listMember` / `listLength`
        // are total over `List<T>`.
        "listAppend" | "listMember" | "listLength" | "listEmpty" => Infallible,
        // `cons(head, tail)` is the function-call form of `head :: tail`. It
        // wraps in Arc<List<_>> via a single allocation and never fails.
        "cons" | "nil" => Infallible,
        "listHead" | "listRest" => Fallible,
        // `listGet` / `listDelete` bounds-check the 1-based index and bail
        // on OOB (`(list).get(i)` returns `Result`).
        "listGet" | "listDelete" => Fallible,

        // ── Array ────────────────────────────────────────────────────────────
        // arrayLength / arrayEmpty / arrayList / listArray / arrayCopy /
        // arrayAppend are total. arrayGet / arrayUpdate bounds-check.
        "arrayLength" | "arrayEmpty" | "arrayList" | "listArray"
        | "arrayCopy" | "arrayAppend" | "arrayCreate" => Infallible,
        "arrayGet" | "arrayUpdate" => Fallible,

        // ── Generic value / Option / misc ────────────────────────────────────
        "anyString" | "tick" | "clock"
        | "valueEq" | "valueCompare" | "referenceEq"
        | "referencePointerString" | "referenceDebugString"
        | "valueConstructor"
        | "isNone" | "isSome"
        | "setStackOverflowSignal" | "isPresent" => Infallible,

        // ── Explicit failure ─────────────────────────────────────────────────
        "fail" => Fallible,

        // ── MetaModelica::Dangerous — bounds-checked variants drop the check ─
        // The "no bounds checking" variants are infallible by construction:
        // their Rust impls perform an unchecked read/write and return the raw
        // value (`arrayGetNoBoundsChecking` → element, `stringGetNoBoundsChecking`
        // → `i32`, `arrayUpdateNoBoundsChecking` → array), never a `Result`.
        // listSetRest / listSetFirst bail on Nil — fallible.
        "arrayGetNoBoundsChecking"
        | "arrayUpdateNoBoundsChecking"
        | "arrayClearIndex"
        | "arrayCreateNoInit"
        | "stringGetNoBoundsChecking"
        | "listReverseInPlace" => Infallible,
        "listSetRest" | "listSetFirst" => Fallible,

        // ── Modelica language built-ins ──────────────────────────────────────
        // Declared as `external "C" name(...)` in
        // `OMCompiler/Compiler/FrontEnd/ModelicaBuiltin.mo` (and friends), but
        // they are NOT calls into the OpenModelica C runtime — the compiler
        // implements them directly (math intrinsics, array constructors,
        // signal operators). Classifying them here short-circuits the
        // [`crate::external_c_calls`] lookup so they don't need an entry in
        // that runtime-symbol registry.

        // Pure mathematical functions — total over the input domain. Some
        // (sqrt for negative input, log for non-positive) yield NaN/-inf at
        // runtime rather than raising, so they remain infallible.
        "sin" | "cos" | "tan"
        | "sinh" | "cosh" | "tanh"
        | "asin" | "acos" | "atan" | "atan2"
        | "exp" | "log" | "log10"
        | "sqrt" | "ceil" | "floor"
        | "sign" | "integer"
        | "abs" | "mod" | "div" | "rem" => Infallible,

        // Array constructors / reshape / projections.
        "ones" | "zeros" | "fill" | "identity" | "diagonal"
        | "vector" | "matrix" | "scalar" | "array"
        | "transpose" | "symmetric" | "skew"
        | "cross" | "outerProduct" | "linspace" => Infallible,

        // Reductions over arrays.
        "sum" | "product" | "min" | "max" => Infallible,

        // Continuous- / discrete-signal operators. Semantically these read
        // from solver state; they cannot fail at the language level.
        "pre" | "previous" | "der" | "edge" | "change"
        | "sample" | "hold" | "noEvent" | "smooth"
        | "semiLinear" | "reinit" | "delay"
        | "initial" | "terminal" => Infallible,

        // Synchronous (clocked) operators.
        "subSample" | "superSample" | "shiftSample" | "backSample"
        | "noClock" | "transition" | "ticksInState" | "timeInState"
        | "inStream" | "actualStream" | "getInstanceName"
        | "activeState" | "initialState" => Infallible,

        // Array shape / introspection.
        "size" | "ndims" => Infallible,

        // `cat(dim, A1, A2, ...)` concatenates arrays along dimension `dim`.
        // `classDirectory()` returns the source-file directory at the call
        // site — purely a compile-time query lowered to a constant.
        "cat" | "classDirectory" => Infallible,

        // Miscellaneous: connector cardinality, homotopy continuation,
        // distributed-parameter PDE primitive, pure-function marker.
        "cardinality" | "homotopy" | "spatialDistribution"
        | "promote" | "pure" => Infallible,

        // ── Failure-raising Modelica builtins ────────────────────────────────
        // `assert` throws when its condition is false; `terminate` ends the
        // simulation. Both propagate failure to the surrounding function.
        "assert" | "terminate" => Fallible,

        // ── I/O — `print` writes to stdout and never fails at this level. ──
        "print" => Infallible,

        _ => return None,
    })
}

// ── Public result type ───────────────────────────────────────────────────────

/// Output of [`analyze`]. Owned, cheap to clone — sets are typically small
/// compared to the size of the hierarchy.
#[derive(Debug, Default, Clone)]
pub struct FallibilityInfo {
    /// Fully-qualified MetaModelica names of every user-defined function
    /// classified as [`Fallibility::Fallible`].  Functions absent from this
    /// set are infallible.
    pub fallible_functions: BTreeSet<String>,
    /// Total number of user-defined function classes inspected.
    pub total_functions: usize,
    /// Number of distinct `external "C"` declarations encountered.
    pub external_functions: usize,
    /// One human-readable diagnostic per `matchcontinue` whose every arm
    /// *except the last* is provably infallible — it can (and for
    /// clarity/efficiency should) be rewritten as a plain `match` in the
    /// MetaModelica source (a failing last arm has nothing to fall through to,
    /// so it behaves identically under `match`). Ordered by enclosing function
    /// FQN then source position. Printed by the caller.
    pub matchcontinue_as_match: Vec<String>,
    /// Source location (the first arm's `Info`) of each safe-to-rewrite
    /// `matchcontinue`, parallel to [`Self::matchcontinue_as_match`]. Consumed
    /// by the `--fix` rewriter (`crate::fix`) to locate and rewrite the
    /// `matchcontinue`/`end matchcontinue` keywords in the `.mo` source.
    pub matchcontinue_as_match_locs: Vec<Absyn::Info>,
}

// ── Walk state ───────────────────────────────────────────────────────────────

/// Per-function call/feature accumulator. Built lazily by [`Walk::scan_class`]
/// and consumed by the fixed-point loop below.
#[derive(Debug, Default)]
struct Walk {
    /// `external "C"` binding for this function, if any. The first element is
    /// the C symbol name (with the MM-level name as a fallback when funcName
    /// is omitted, per Modelica external-function defaults).
    external: Option<String>,
    /// Names of all callees observed in the body — at this stage they are raw
    /// MM names from the source (e.g. "List.map", "foo", "intAdd"). They are
    /// resolved against the hierarchy in [`resolve_called_qname`].
    calls: BTreeSet<String>,
    /// True if the body contains a `match`/`matchcontinue` expression — a
    /// fail-on-no-match is observable to callers.
    has_match: bool,
    /// True if the body contains an explicit `fail()` call outside a catch
    /// boundary.  (Catch boundaries are not yet tracked; see module docs.)
    has_fail: bool,
    /// True if the body calls *through a function value* — i.e. invokes one of
    /// the function's own function-typed parameters/locals (a callback), or a
    /// function-typed field of such a local. Every function value in our
    /// codegen lowers to `Arc<dyn Fn(...) -> Result<...>>` (see codegen
    /// `fmt_param_ty` / partial-alias emission), so calling one is *always*
    /// fallible regardless of the target — which we cannot, and need not,
    /// resolve. This is what makes higher-order functions (`Array.map`,
    /// `List.fold`, the `AvlTree*` walkers, …) fallible; the older analysis
    /// silently dropped these unresolved callee names and let codegen emit a
    /// latent `.unwrap()` instead.
    calls_fn_value: bool,
    /// Function-level variable names (inputs/outputs/protected component
    /// declarations) that are visible as bindings inside any match in this
    /// function. Used by [`match_is_exhaustive`] / [`absyn_pat_is_irrefutable`]
    /// to decide whether a bare identifier in pattern position refers to a
    /// declared local (irrefutable variable binding) or a constructor
    /// (refutable). This is the scope-aware replacement for the historical
    /// case-sensitivity heuristic.
    outer_scope: BTreeSet<String>,
    /// Deferred safety obligations, one per `matchcontinue` expression in the
    /// body. A failing `matchcontinue` arm (guard or body) falls through to
    /// the next arm, so nothing *inside* an arm escapes directly — the
    /// construct as a whole fails only when every arm fails or mismatches.
    /// Whether that can happen depends on the fallibility of the functions
    /// the arms call, which is only known at the call-graph fixed point, so
    /// the check is recorded here and evaluated in [`analyze`] (see
    /// [`mc_check_is_safe`]).
    mc_checks: Vec<McCheck>,
    /// Deferred "this `matchcontinue` could be a plain `match`" diagnostics,
    /// one per `matchcontinue` expression in the body. A `matchcontinue` and a
    /// `match` over the same arms differ *only* when a *non-last* arm's
    /// pattern+guard succeed but its guard/body/result then fails:
    /// `matchcontinue` falls through to the next arm, whereas `match` propagates
    /// the failure. A failing *last* arm has no next arm to fall through to, so
    /// `matchcontinue` fails there too — identical to `match`. So when every arm
    /// before the last is infallible that distinction never materialises and
    /// the construct is exactly a `match` — which is cheaper and clearer.
    /// Whether each arm is infallible depends on the call-graph fixed point, so
    /// (like [`McCheck`]) the verdict is recorded here and evaluated in
    /// [`analyze`].
    mc_lints: Vec<McLint>,
}

/// Deferred "rewrite `matchcontinue` as `match`" diagnostic for one
/// `matchcontinue` expression: it is reportable iff every arm *except the last*
/// is infallible (see [`Walk::mc_lints`] and the check in [`analyze`]). The
/// fall-through-on-failure that distinguishes `matchcontinue` from `match` only
/// fires when a failing arm has a *next* arm to fall back to, so the last arm's
/// fallibility is irrelevant — a failing last arm leaves `matchcontinue` with
/// nothing left to try, exactly like `match` propagating. Unlike [`McCheck`],
/// this records a sub-[`Walk`] for *all* arms — guarded and
/// [`CoverKey::Other`]-patterned ones included — in source order, because the
/// equivalence hinges on which arm is last and on no *earlier* arm being able to
/// fail, regardless of whether the arm contributes pattern coverage. `info` is
/// the source location of the first arm, used to point the developer at the
/// source.
#[derive(Debug)]
struct McLint {
    info: Absyn::Info,
    /// All arms, in source order; the last element is the matchcontinue's last
    /// arm (whose fallibility the lint deliberately ignores).
    arms: Vec<Walk>,
}

/// Safety obligation for one `matchcontinue` expression: it cannot fail iff
/// the patterns of its *infallible* candidate arms exhaustively cover the
/// scrutinee — execution then always reaches some matching arm that runs to
/// completion (an always-succeeding `else` is the common special case).
///
/// `candidates` holds the unguarded arms (incl. `else`, as
/// [`CoverKey::Irrefutable`]) whose pattern can contribute type-independent
/// coverage, paired with a sub-[`Walk`] of the failure sources *inside* the
/// arm. Guarded arms are not recorded: a guard may evaluate to false, so a
/// guarded arm never guarantees success — and its failures are caught by the
/// matchcontinue either way. Arms whose pattern classifies as
/// [`CoverKey::Other`] are likewise dropped (they can never contribute
/// coverage).
#[derive(Debug, Default)]
struct McCheck {
    candidates: Vec<(CoverKey, Walk)>,
}

impl Walk {
    /// `inherited_scope` carries component names merged in from an `extends`
    /// base (see [`node_component_names`]); they join `outer_scope` so calls
    /// through an inherited function-typed input register as `calls_fn_value`.
    fn scan_class(c: &MM::Class, inherited_scope: &BTreeSet<String>) -> Self {
        let mut w = Walk::default();
        w.outer_scope.extend(inherited_scope.iter().cloned());
        let (algorithms, members) = match &c.body {
            MM::ClassDef::Parts { algorithms, external, members, .. } => {
                if let Some(ext) = external {
                    w.external = Some(external_symbol_name(&ext.decl, &c.name));
                }
                (algorithms, members)
            }
            MM::ClassDef::ClassExtends { algorithms, members, .. } => (algorithms, members),
            _ => return w,
        };
        // Function-level variable declarations contribute to the binding
        // scope visible inside any nested match expression. Collect their
        // names up-front; per-match additions (matchExp.localDecls and
        // each case's localDecls) are layered on top inside
        // `match_is_exhaustive`.
        // First pass: collect every component name so `outer_scope` is fully
        // populated before any expression is scanned. `record_call` consults it
        // to recognise calls through function-typed locals (see
        // [`Walk::calls_fn_value`]), and a default binding can legally refer to
        // a local declared later in the same parameter/protected list, so the
        // scope must be complete up front.
        for m in members {
            if let MM::ClassMember::Component(cm) = m {
                w.outer_scope.insert(cm.name.clone());
            }
        }
        // Second pass: scan the eagerly-evaluated component bindings.
        for m in members {
            if let MM::ClassMember::Component(cm) = m {
                // A component's default-value binding (`output T x = <exp>;` or
                // a protected local with an initializer) is evaluated in the
                // function body — codegen lowers it to a `let x = <exp>;`
                // statement (see `extract_default_exp` uses in codegen). If
                // `<exp>` calls a fallible function (e.g. `StringUtil.rest`'s
                // `output String rest = substring(str, 2, stringLength(str))`),
                // the enclosing function is fallible too. Scanning the body
                // algorithms alone misses these bindings, so walk them here.
                if let Some(exp) = crate::hierarchy::extract_default_exp(&cm.modification) {
                    w.scan_exp(exp);
                }
                // A component `condition` (`T x if <cond>;`) is likewise
                // evaluated eagerly; fallible calls within it propagate.
                if let Some(cond) = cm.condition.as_deref() {
                    w.scan_exp(cond);
                }
            }
        }
        for it in algorithms {
            w.scan_algorithm_item(it);
        }
        w
    }

    fn scan_algorithm_item(&mut self, it: &Absyn::AlgorithmItem) {
        let (alg, comment) = match it {
            Absyn::AlgorithmItem::ALGORITHMITEM { algorithm_, comment, .. } => (&**algorithm_, comment),
            Absyn::AlgorithmItem::ALGORITHMITEMCOMMENT { .. } => return,
        };
        // A `try`/`else` block annotated with `__OpenModelica_stackOverflowCheckpoint=true`
        // is lowered as if the `try` body were written inline (see
        // `typedexp::infer_stmt_into`): the `else` handler is discarded, so the
        // body's failures propagate to the enclosing function rather than being
        // caught. Mirror that here — scan the BODY, not the `else` handler.
        if let Absyn::Algorithm::ALG_TRY { body, .. } = alg
            && crate::typedexp::comment_has_boolean_named_annotation(
                comment,
                "__OpenModelica_stackOverflowCheckpoint",
            )
        {
            for it in &**body { self.scan_algorithm_item(it); }
            return;
        }
        match alg {
            Absyn::Algorithm::ALG_ASSIGN { assignComponent, value } => {
                // MetaModelica's `:=` is a *pattern* assignment: if the LHS is
                // anything other than a plain variable reference (or a tuple
                // of plain variable references), the match can fail at runtime
                // and the surrounding function therefore fallible. Codegen
                // lowers these to `let PAT = RHS else { bail!("pattern
                // mismatch") };`, which only typechecks when the function
                // returns `Result`. Examples:
                //   `Cons(h, t) := xs;`        — list cons pattern
                //   `SOME(x) := opt;`          — uniontype variant pattern
                //   `(a, SOME(b)) := pair;`    — tuple containing a refutable
                //                                sub-pattern
                if exp_is_refutable_lhs(assignComponent) {
                    self.has_fail = true;
                }
                self.scan_exp(assignComponent);
                self.scan_exp(value);
            }
            Absyn::Algorithm::ALG_IF { ifExp, trueBranch, elseIfAlgorithmBranch, elseBranch } => {
                self.scan_exp(ifExp);
                for it in &**trueBranch { self.scan_algorithm_item(it); }
                for (cond, branch) in &**elseIfAlgorithmBranch {
                    self.scan_exp(cond);
                    for it in &**branch { self.scan_algorithm_item(it); }
                }
                for it in &**elseBranch { self.scan_algorithm_item(it); }
            }
            Absyn::Algorithm::ALG_FOR { iterators, forBody }
            | Absyn::Algorithm::ALG_PARFOR { iterators, parforBody: forBody } => {
                // The iterator range (`for x in <range> loop`) and any guard are
                // evaluated before/around the loop body, so a fallible call in
                // them (`for v in getVariables(c) loop …`) escapes the function
                // just like a body call. Scanning only `forBody` missed these.
                for it in &**iterators {
                    let Absyn::ForIterator { range, guardExp, .. } = &**it;
                    if let Some(r) = range.as_deref() { self.scan_exp(r); }
                    if let Some(g) = guardExp.as_deref() { self.scan_exp(g); }
                }
                for it in &**forBody { self.scan_algorithm_item(it); }
            }
            Absyn::Algorithm::ALG_WHILE { boolExpr, whileBody } => {
                self.scan_exp(boolExpr);
                for it in &**whileBody { self.scan_algorithm_item(it); }
            }
            Absyn::Algorithm::ALG_WHEN_A { boolExpr, whenBody, elseWhenAlgorithmBranch } => {
                self.scan_exp(boolExpr);
                for it in &**whenBody { self.scan_algorithm_item(it); }
                for (e, branch) in &**elseWhenAlgorithmBranch {
                    self.scan_exp(e);
                    for it in &**branch { self.scan_algorithm_item(it); }
                }
            }
            Absyn::Algorithm::ALG_NORETCALL { functionCall, functionArgs } => {
                self.record_call(&cref_to_dotted(functionCall));
                self.scan_function_args(functionArgs);
            }
            Absyn::Algorithm::ALG_FAILURE { equ: _ } => {
                // `failure(body)` *succeeds* iff `body` fails, which means it
                // *throws* whenever the body succeeds — so the construct
                // itself is unconditionally fallible from the enclosing
                // function's point of view. We do NOT need to inspect the
                // body: regardless of what it does, the failure clause can
                // raise the failure that escapes upward.
                self.has_fail = true;
            }
            Absyn::Algorithm::ALG_TRY { body: _, elseBody } => {
                // `try BODY else ELSE end try;` catches a failure raised by
                // BODY and runs ELSE instead. The only paths that can
                // propagate a failure *out* of the try clause are failures
                // inside ELSE (BODY's failures are caught and so do not
                // contribute to the enclosing function's fallibility).
                for it in &**elseBody { self.scan_algorithm_item(it); }
            }
            Absyn::Algorithm::ALG_RETURN
            | Absyn::Algorithm::ALG_BREAK
            | Absyn::Algorithm::ALG_CONTINUE => {}
        }
    }

    fn scan_exp(&mut self, e: &Absyn::Exp) {
        use Absyn::Exp::*;
        match e {
            INTEGER { .. } | REAL { .. } | STRING { .. } | BOOL { .. } | END | BREAK => {}
            CREF { .. } | CODE { .. } => {}
            BINARY { exp1, op, exp2 } => {
                // `/` (and its element-wise form `./`) is Real division, whose
                // zero-divisor case is a recoverable MetaModelica failure — the
                // C runtime emits `if (denom == 0) goto fail;` before every Real
                // division. Codegen lowers it through `real_div_checked(..)?`
                // (see `BinOpKind::Div` in codegen), so the surrounding function
                // is fallible. This must agree with that lowering exactly, or
                // `GenCtx::q` will panic on the analysis/codegen mismatch.
                if matches!(op, Absyn::Operator::DIV | Absyn::Operator::DIV_EW) {
                    self.has_fail = true;
                }
                self.scan_exp(exp1); self.scan_exp(exp2);
            }
            LBINARY { exp1, exp2, .. } | RELATION { exp1, exp2, .. } => {
                self.scan_exp(exp1); self.scan_exp(exp2);
            }
            UNARY { exp, .. } | LUNARY { exp, .. } => self.scan_exp(exp),
            IFEXP { ifExp, trueBranch, elseBranch, elseIfBranch } => {
                self.scan_exp(ifExp);
                self.scan_exp(trueBranch);
                self.scan_exp(elseBranch);
                for (c, t) in &**elseIfBranch { self.scan_exp(c); self.scan_exp(t); }
            }
            CALL { function_, functionArgs, .. } => {
                self.record_call(&cref_to_dotted(function_));
                self.scan_function_args(functionArgs);
            }
            PARTEVALFUNCTION { function_, functionArgs } => {
                // Partial application produces a function value rather than
                // calling the function. It does NOT make the surrounding
                // function fallible on its own — but the bound argument
                // expressions are evaluated eagerly and therefore still need
                // to be walked.
                let _ = function_;
                self.scan_function_args(functionArgs);
            }
            ARRAY { arrayExp } | LIST { exps: arrayExp } => {
                for e in &**arrayExp { self.scan_exp(e); }
            }
            MATRIX { matrix } => {
                for row in &**matrix {
                    for e in &**row { self.scan_exp(e); }
                }
            }
            RANGE { start, step, stop } => {
                self.scan_exp(start);
                if let Some(s) = step.as_deref() { self.scan_exp(s); }
                self.scan_exp(stop);
            }
            TUPLE { expressions } => {
                for e in &**expressions { self.scan_exp(e); }
            }
            AS { exp, .. } => self.scan_exp(exp),
            CONS { head, rest } => { self.scan_exp(head); self.scan_exp(rest); }
            MATCHEXP { matchTy, inputExp, localDecls, cases, .. } => {
                // The scrutinee is evaluated once, before any arm's failure-
                // catch scope is entered, so its failures escape the match —
                // for `matchcontinue` too (codegen binds `__mc_input` outside
                // the per-arm closures). Likewise the `= <exp>` default
                // bindings of match-level locals: codegen hoists them to a
                // `let` evaluated once before the match.
                self.scan_exp(inputExp);
                self.scan_local_decl_defaults(localDecls);
                if matches!(matchTy, Absyn::MatchType::MATCH) {
                    // A `match` raises a failure when no arm matches the
                    // scrutinee. If the patterns exhaustively cover every
                    // value of the scrutinee's type, the match cannot fail,
                    // so the surrounding function stays infallible. See
                    // codegen `cases_exhaustive` for the typed-IR
                    // counterpart; the two must agree.
                    if !match_is_exhaustive(cases, localDecls, &self.outer_scope) {
                        self.has_match = true;
                    }
                    // A failure inside a `match` arm (guard, body, or result)
                    // escapes the match — there is no fall-through to the
                    // next arm — so arm contents are scanned into `self`.
                    //
                    // Scanning into `self` means `record_call` consults
                    // `self.outer_scope` to recognise calls through a
                    // function-typed local (see [`Walk::calls_fn_value`]). The
                    // names a pattern binds — and any `local`-declared helpers —
                    // are in scope inside the arm but are NOT function-level
                    // components, so they must be layered onto `outer_scope` for
                    // the duration of the arm. Without this, a callback bound by
                    // a pattern (`case SOME(cond) ... cond(e)`, the
                    // `FuncTypeExp_ExpToBoolean` pattern in
                    // `BackendVarTransform.replaceExpCond`) is missed, the
                    // function is mis-classified infallible, and codegen emits a
                    // latent `.unwrap()` on the callback's `Result` instead of
                    // propagating the failure. The enclosing scope is saved and
                    // restored so a match nested in another arm sees the correct
                    // lexical scope. Mirrors the per-arm scope construction in
                    // the `matchcontinue` branch below.
                    let saved_scope = std::mem::take(&mut self.outer_scope);
                    let mut match_scope = saved_scope.clone();
                    collect_local_decl_names(localDecls, &mut match_scope);
                    for case in &**cases {
                        let (case_decls, guard, pattern, class_part, result) = match &**case {
                            Absyn::Case::CASE { pattern, patternGuard, localDecls: case_decls, classPart, result, .. } =>
                                (case_decls, patternGuard.as_deref(), Some(&**pattern), classPart, result),
                            Absyn::Case::ELSE { localDecls: case_decls, classPart, result, .. } =>
                                (case_decls, None, None, classPart, result),
                        };
                        let mut scope = match_scope.clone();
                        collect_local_decl_names(case_decls, &mut scope);
                        self.outer_scope = scope;
                        if let Some(p) = pattern { self.scan_exp(p); }
                        if let Some(g) = guard { self.scan_exp(g); }
                        self.scan_local_decl_defaults(case_decls);
                        self.scan_class_part(class_part);
                        self.scan_exp(result);
                    }
                    self.outer_scope = saved_scope;
                } else {
                    // `matchcontinue`: a failing arm falls through to the
                    // next arm, so nothing inside an arm escapes directly.
                    // Record the deferred safety check instead — see
                    // [`McCheck`]. Arm contents are scanned into per-arm
                    // sub-walks whose verdicts feed the check; arms that can
                    // never contribute coverage (guarded, or pattern shape
                    // [`CoverKey::Other`]) are dropped entirely.
                    let mut match_scope = self.outer_scope.clone();
                    collect_local_decl_names(localDecls, &mut match_scope);
                    let mut candidates: Vec<(CoverKey, Walk)> = Vec::new();
                    for case in &**cases {
                        match &**case {
                            Absyn::Case::CASE { pattern, patternGuard, localDecls: case_decls, classPart, result, .. } => {
                                if patternGuard.is_some() { continue; }
                                let mut scope = match_scope.clone();
                                collect_local_decl_names(case_decls, &mut scope);
                                let key = pat_cover_key(pattern, &scope);
                                if matches!(key, CoverKey::Other) { continue; }
                                let mut sub = Walk { outer_scope: scope, ..Walk::default() };
                                sub.scan_exp(pattern);
                                sub.scan_local_decl_defaults(case_decls);
                                sub.scan_class_part(classPart);
                                sub.scan_exp(result);
                                candidates.push((key, sub));
                            }
                            Absyn::Case::ELSE { localDecls: case_decls, classPart, result, .. } => {
                                let mut scope = match_scope.clone();
                                collect_local_decl_names(case_decls, &mut scope);
                                let mut sub = Walk { outer_scope: scope, ..Walk::default() };
                                sub.scan_local_decl_defaults(case_decls);
                                sub.scan_class_part(classPart);
                                sub.scan_exp(result);
                                candidates.push((CoverKey::Irrefutable, sub));
                            }
                        }
                    }
                    self.mc_checks.push(McCheck { candidates });

                    // Build a parallel per-arm walk over *every* arm (guarded and
                    // `Other`-patterned ones too) for the rewrite-as-`match` lint.
                    // The guard is scanned here — unlike the coverage candidates,
                    // which omit guarded arms entirely — so a fallible guard keeps
                    // the arm fallible and suppresses the (then-unsound) suggestion.
                    let mut lint_arms: Vec<Walk> = Vec::new();
                    let mut lint_info: Option<Absyn::Info> = None;
                    for case in &**cases {
                        let (case_decls, guard, pattern, class_part, result, info) = match &**case {
                            Absyn::Case::CASE { pattern, patternGuard, localDecls: case_decls, classPart, result, info, .. } =>
                                (case_decls, patternGuard.as_deref(), Some(&**pattern), classPart, result, info),
                            Absyn::Case::ELSE { localDecls: case_decls, classPart, result, info, .. } =>
                                (case_decls, None, None, classPart, result, info),
                        };
                        if lint_info.is_none() { lint_info = Some(info.clone()); }
                        let mut scope = match_scope.clone();
                        collect_local_decl_names(case_decls, &mut scope);
                        let mut sub = Walk { outer_scope: scope, ..Walk::default() };
                        if let Some(g) = guard { sub.scan_exp(g); }
                        if let Some(p) = pattern { sub.scan_exp(p); }
                        sub.scan_local_decl_defaults(case_decls);
                        sub.scan_class_part(class_part);
                        sub.scan_exp(result);
                        lint_arms.push(sub);
                    }
                    if let Some(info) = lint_info {
                        self.mc_lints.push(McLint { info, arms: lint_arms });
                    }
                }
            }
            DOT { exp, index } => { self.scan_exp(exp); self.scan_exp(index); }
            EXPRESSIONCOMMENT { exp, .. } => self.scan_exp(exp),
            SUBSCRIPTED_EXP { exp, .. } => self.scan_exp(exp),
        }
    }

    /// Scan the eagerly-evaluated `= <exp>` default bindings (and `if <cond>`
    /// component conditions) of a match-level `local` declaration block.
    /// Codegen hoists initialised match-locals to a `let` emitted once before
    /// the match expression — outside any arm's failure-catch scope — so a
    /// fallible call inside such a binding escapes the match, even for
    /// `matchcontinue`. Mirrors the component-binding scan in
    /// [`Walk::scan_class`].
    fn scan_local_decl_defaults(&mut self, decls: &metamodelica::List<std::sync::Arc<Absyn::ElementItem>>) {
        for item in decls {
            let Absyn::ElementItem::ELEMENTITEM { element } = item.as_ref() else { continue };
            let Absyn::Element::ELEMENT { specification, .. } = &**element else { continue };
            let Absyn::ElementSpec::COMPONENTS { components, .. } = &**specification else { continue };
            for ci in &**components {
                if let Some(exp) = crate::hierarchy::extract_default_exp(&ci.component.modification) {
                    self.scan_exp(exp);
                }
                if let Some(cond) = ci.condition.as_deref() {
                    self.scan_exp(cond);
                }
            }
        }
    }

    fn scan_class_part(&mut self, part: &Absyn::ClassPart) {
        if let Absyn::ClassPart::ALGORITHMS { contents } = part {
            for it in &**contents { self.scan_algorithm_item(it); }
        }
        // EQUATIONS / EXTERNAL / etc. are not introduced inside match-case
        // class parts by the parser we use; if a future grammar revision
        // changes that, this match needs to grow.
    }

    fn scan_function_args(&mut self, fa: &Absyn::FunctionArgs) {
        match fa {
            Absyn::FunctionArgs::FUNCTIONARGS { args, argNames } => {
                for e in &**args { self.scan_exp(e); }
                for na in &**argNames {
                    let Absyn::NamedArg { argValue, .. } = &**na;
                    self.scan_exp(argValue);
                }
            }
            Absyn::FunctionArgs::FOR_ITER_FARG { exp, iterators, .. } => {
                self.scan_exp(exp);
                for it in &**iterators {
                    let Absyn::ForIterator { range, guardExp, .. } = &**it;
                    if let Some(r) = range.as_deref() { self.scan_exp(r); }
                    if let Some(g) = guardExp.as_deref() { self.scan_exp(g); }
                }
            }
        }
    }

    fn record_call(&mut self, name: &str) {
        if name == "fail" {
            self.has_fail = true;
        }
        // A call whose first dotted segment names one of this function's own
        // parameters/locals is a call *through a function value*: you can only
        // "call" something of function type, and every function value lowers to
        // `Arc<dyn Fn(...) -> Result<...>>`, so the call is fallible regardless
        // of which target the value holds. This covers both a bare callback
        // parameter `f(x)` and a function-typed field of a local record
        // `obj.fn(x)`. Package-qualified calls (`List.map`, `SOME(...)`) have a
        // first segment that is a package / constructor, never a local, so they
        // are correctly excluded and resolved through the normal call graph.
        let first_seg = name.split('.').next().unwrap_or(name);
        if self.outer_scope.contains(first_seg) {
            self.calls_fn_value = true;
        }
        self.calls.insert(name.to_owned());
    }
}

/// True when an expression used on the LHS of a MetaModelica `:=` assignment
/// produces a *refutable* pattern — one whose match can fail at runtime, in
/// which case codegen emits `bail!("pattern mismatch")` to surface the failure
/// to the caller, making the surrounding function fallible.
///
/// Plain variables and tuples-of-plain-variables are irrefutable; anything
/// involving a constructor, cons-cell, literal, range, or destructuring
/// expression is refutable. Wildcards (`_`) are irrefutable but appear in
/// pattern position only inside a containing tuple.
///
/// Conservative: when in doubt, classify as refutable. A spurious "fallible"
/// classification just keeps a `Result<>` return where it wasn't needed, while
/// a spurious "infallible" classification produces uncompilable code.
fn exp_is_refutable_lhs(e: &Absyn::Exp) -> bool {
    use Absyn::Exp::*;
    match e {
        // A plain identifier on the LHS is an ordinary assignment.
        CREF { .. } => false,
        // `(a, b, c) := rhs` — only irrefutable if every component is itself
        // irrefutable on the LHS.
        TUPLE { expressions } => (&**expressions).into_iter().any(|e| exp_is_refutable_lhs(e)),
        // Every other Exp shape that can syntactically appear on the LHS of
        // `:=` denotes a refutable pattern match: constructor applications
        // (CALL), cons-cells (CONS), literal lists/arrays, as-patterns,
        // ranges, and even bare literals.
        _ => true,
    }
}

/// Collect the bare component names declared in a `localDecls` block of a
/// `match` expression or a `case`. Each declaration takes the shape
/// `ELEMENTITEM { element: ELEMENT { specification: COMPONENTS { components, .. } } }`
/// where each component is a `COMPONENTITEM { component: COMPONENT { name } }`.
///
/// Lexer comment / TEXT / DEFINEUNIT items are silently skipped — they
/// don't introduce variable bindings.
fn collect_local_decl_names(
    decls: &metamodelica::List<std::sync::Arc<Absyn::ElementItem>>,
    out: &mut BTreeSet<String>,
) {
    for item in decls {
        let Absyn::ElementItem::ELEMENTITEM { element } = item.as_ref() else { continue };
        let Absyn::Element::ELEMENT { specification, .. } = &**element else { continue };
        let Absyn::ElementSpec::COMPONENTS { components, .. } = &**specification else { continue };
        for ci in &**components {
            let Absyn::ComponentItem { component, .. } = ci.as_ref();
            let Absyn::Component { name, .. } = component;
            out.insert(name.to_string());
        }
    }
}

// ── Exhaustiveness on Absyn patterns ─────────────────────────────────────────
//
// This is the Absyn-IR counterpart to codegen's `cases_exhaustive` /
// `pats_cover_ty`. The two analyses run on different IRs (Absyn here,
// typedexp::TypedPat there) but MUST classify the same set of matches as
// exhaustive — otherwise the fallibility verdict for a function disagrees
// with whether codegen emits a `_ => bail!(...)` fallback, producing
// uncompilable lowered code.
//
// Conservative: we underapproximate exhaustiveness. A `false` here just
// keeps the surrounding function flagged fallible (the historical default);
// a spurious `true` would let codegen elide a needed fallback and break the
// build. Type info is not available at this phase, so we only recognise
// the type-independent shapes whose pattern coverage is decidable purely
// from the constructor names involved (List, Option, Bool).

/// Is an Absyn-level pattern *irrefutable* — i.e. does it match every
/// possible value of whichever type the scrutinee turns out to have?
///
/// MetaModelica resolves bare identifiers in pattern position to either
/// "fresh variable binding" or "unit constructor reference" depending on
/// whether the name is declared as a local in the enclosing scope (match-
/// level or case-level `localDecls`, plus the surrounding function's
/// inputs/outputs/protected variables). `binding_names` carries that set
/// of names, gathered upstream by [`collect_match_binding_names`]. An
/// identifier in the set is treated as a variable binding (irrefutable);
/// any other identifier might be a constructor and is conservatively
/// classified refutable.
///
/// This is the sound replacement for the historical "first letter
/// uppercase ⇒ constructor" heuristic — we now consult the actual
/// declared scope.
fn absyn_pat_is_irrefutable(e: &Absyn::Exp, binding_names: &BTreeSet<String>) -> bool {
    use Absyn::Exp::*;
    match e {
        CREF { componentRef } => match componentRef.as_ref() {
            Absyn::ComponentRef::WILD | Absyn::ComponentRef::ALLWILD => true,
            Absyn::ComponentRef::CREF_IDENT { name, subscripts } if subscripts.is_empty() => {
                &**name == "_" || binding_names.contains(&**name as &str)
            }
            _ => false,
        }
        AS { exp, .. } => absyn_pat_is_irrefutable(exp, binding_names),
        TUPLE { expressions } => (&**expressions).into_iter().all(|e| absyn_pat_is_irrefutable(e, binding_names)),
        _ => false,
    }
}

/// A `SOME(<pat>)` pattern whose inner sub-pattern is itself irrefutable
/// covers every `SOME(_)` value. We recognise the Absyn-level shape: a
/// `CALL` whose callee dottifies to `SOME` with exactly one positional
/// argument that is irrefutable. (Named-argument forms or multi-arg
/// shapes are rejected as not-a-canonical-SOME-pattern.)
fn absyn_pat_is_full_some(e: &Absyn::Exp, binding_names: &BTreeSet<String>) -> bool {
    if let Absyn::Exp::CALL { function_, functionArgs, .. } = e {
        if cref_to_dotted(function_) != "SOME" { return false; }
        if let Absyn::FunctionArgs::FUNCTIONARGS { args, argNames } = &**functionArgs {
            let args_vec: Vec<&Absyn::Exp> = (&**args).into_iter().map(|a| a.as_ref()).collect();
            let names_empty = (&**argNames).into_iter().next().is_none();
            return names_empty
                && args_vec.len() == 1
                && absyn_pat_is_irrefutable(args_vec[0], binding_names);
        }
    }
    false
}

/// Type-independent pattern-coverage classification of one unguarded case.
/// [`cover_keys_exhaustive`] decides exhaustiveness from a set of these, so
/// the whole-match check ([`match_is_exhaustive`]) and the per-arm-subset
/// check for `matchcontinue` safety ([`mc_check_is_safe`]) share one
/// definition of what covers what.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum CoverKey {
    /// Matches every value of the scrutinee type: `else`, `_`, a declared
    /// variable binding, as-patterns and tuples of irrefutable patterns.
    Irrefutable,
    /// `{}` — the empty-list literal.
    NilList,
    /// `head :: rest` with both sub-patterns irrefutable.
    FullCons,
    /// `NONE()`.
    NoneOpt,
    /// `SOME(<irrefutable>)`.
    FullSome,
    /// Literal `true`.
    BoolTrue,
    /// Literal `false`.
    BoolFalse,
    /// Every other shape — constructor patterns, literals, partial
    /// cons/SOME, … — contributes no type-independent coverage.
    Other,
}

/// Classify a pattern's coverage contribution. `binding_names` is the set of
/// names in scope as variable bindings for this pattern (function locals +
/// match-level localDecls + the case's own localDecls) — see
/// [`absyn_pat_is_irrefutable`].
fn pat_cover_key(e: &Absyn::Exp, binding_names: &BTreeSet<String>) -> CoverKey {
    if absyn_pat_is_irrefutable(e, binding_names) {
        return CoverKey::Irrefutable;
    }
    // The parser surface for the empty list literal `{}` is currently
    // `Absyn::Exp::ARRAY { arrayExp: [] }` (the MetaModelica `{...}`
    // syntax always produces an ARRAY node; the dedicated LIST variant is
    // emitted for the `list(...)` builtin or list-comprehension forms).
    // We accept either shape so a future parser change to emit LIST for
    // `{}` continues to be recognised. A non-empty `{l}` literal would
    // desugar to a Cons chain in pattern position, but the parser keeps
    // the literal form here — `{l}` is therefore ARRAY/LIST with a single
    // element and does NOT contribute to Cons coverage.
    match e {
        Absyn::Exp::ARRAY { arrayExp } if arrayExp.is_empty() => CoverKey::NilList,
        Absyn::Exp::LIST { exps } if exps.is_empty() => CoverKey::NilList,
        Absyn::Exp::CONS { head, rest }
            if absyn_pat_is_irrefutable(head, binding_names)
                && absyn_pat_is_irrefutable(rest, binding_names) =>
            CoverKey::FullCons,
        Absyn::Exp::CALL { function_, .. }
            if cref_to_dotted(function_.as_ref()) == "NONE" =>
            CoverKey::NoneOpt,
        _ if absyn_pat_is_full_some(e, binding_names) => CoverKey::FullSome,
        Absyn::Exp::BOOL { value: true } => CoverKey::BoolTrue,
        Absyn::Exp::BOOL { value: false } => CoverKey::BoolFalse,
        _ => CoverKey::Other,
    }
}

/// Does a set of unguarded patterns (classified by [`pat_cover_key`])
/// exhaustively cover the scrutinee? Handles the type-independent shapes:
///   * any irrefutable pattern (incl. `else`) → exhaustive
///   * `{}` (Nil) + `_ :: _` with both subpatterns irrefutable → List
///   * `NONE()` + `SOME(_)` with irrefutable inner → Option
///   * boolean literals `true` and `false` → Bool
///
/// TODO: uniontype / record exhaustiveness — requires looking up the
/// scrutinee's type to enumerate constructors, which needs the typed IR.
/// See the typedexp::TypedPat counterpart in codegen (`pats_cover_ty`) for
/// the analogous gap.
fn cover_keys_exhaustive(keys: &[CoverKey]) -> bool {
    use CoverKey::*;
    keys.contains(&Irrefutable)
        || (keys.contains(&NilList) && keys.contains(&FullCons))
        || (keys.contains(&NoneOpt) && keys.contains(&FullSome))
        || (keys.contains(&BoolTrue) && keys.contains(&BoolFalse))
}

/// Does an Absyn case set exhaustively cover the scrutinee? See
/// [`cover_keys_exhaustive`] for the recognised shapes. Cases with a guard
/// never contribute coverage — a guard can fail.
fn match_is_exhaustive(
    cases: &metamodelica::List<Arc<Absyn::Case>>,
    match_local_decls: &metamodelica::List<std::sync::Arc<Absyn::ElementItem>>,
    outer_scope: &BTreeSet<String>,
) -> bool {
    // The full set of names in scope as variable bindings for any pattern
    // in this match: outer scope (function inputs/outputs/protected) ∪
    // match-level localDecls ∪ per-case localDecls.  Built once for the
    // match, augmented per-case below.
    let mut match_scope: BTreeSet<String> = outer_scope.clone();
    collect_local_decl_names(match_local_decls, &mut match_scope);

    let keys: Vec<CoverKey> = cases.into_iter().filter_map(|c| match &**c {
        Absyn::Case::ELSE { .. } => Some(CoverKey::Irrefutable),
        Absyn::Case::CASE { pattern, patternGuard, localDecls, .. } if patternGuard.is_none() => {
            let mut scope = match_scope.clone();
            collect_local_decl_names(localDecls, &mut scope);
            Some(pat_cover_key(pattern.as_ref(), &scope))
        }
        _ => None,
    }).collect();
    cover_keys_exhaustive(&keys)
}

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Return the dotted MM-side name for a `ComponentRef` (e.g. `List.map`).
/// Mirrors `typedexp::cref_to_dotted` but kept private here so the analysis
/// is independent of the typed-IR module's surface.
fn cref_to_dotted(cref: &Absyn::ComponentRef) -> String {
    match cref {
        Absyn::ComponentRef::CREF_IDENT { name, .. } => name.to_string(),
        Absyn::ComponentRef::CREF_QUAL { name, componentRef, .. } => {
            format!("{name}.{}", cref_to_dotted(componentRef))
        }
        Absyn::ComponentRef::CREF_FULLYQUALIFIED { componentRef } => {
            cref_to_dotted(componentRef)
        }
        Absyn::ComponentRef::WILD => "_".to_owned(),
        Absyn::ComponentRef::ALLWILD => "__".to_owned(),
    }
}

/// Dotted form of an `Absyn::Path` (e.g. `List.map`), for resolving `extends`
/// base-class paths.
fn path_to_dotted(path: &Absyn::Path) -> String {
    match path {
        Absyn::Path::IDENT { name } => name.to_string(),
        Absyn::Path::QUALIFIED { name, path } => format!("{name}.{}", path_to_dotted(path)),
        Absyn::Path::FULLYQUALIFIED { path } => path_to_dotted(path),
    }
}

/// Pick the external C symbol used by an `external "C" ...` declaration.
///
/// Modelica allows omitting the explicit funcName, in which case the enclosing
/// MM function's name is the C symbol — see the Modelica spec, §12.9.1.3.
fn external_symbol_name(decl: &Absyn::ExternalDecl, fallback_fn_name: &str) -> String {
    let Absyn::ExternalDecl { funcName, .. } = decl;
    match funcName.as_ref() {
        Some(n) if !n.is_empty() => n.to_string(),
        _ => fallback_fn_name.to_owned(),
    }
}

/// Walk the hierarchy and collect every R_FUNCTION class together with its
/// fully-qualified MM name. Mirrors the convention used throughout codegen
/// (dot-separated, top-level package first).
///
/// Collects the [`NameNode`] of every R_FUNCTION class so the analysis can see
/// not just the raw AST body but the *resolved* picture: inherited components
/// (merged into `node.children` by `flatten_extends`) and the `extends` links to
/// any partial base function whose algorithm is inlined at codegen time.
fn collect_functions<'a>(
    nodes: &'a BTreeMap<String, NameNode<'a>>,
    prefix: &str,
    out: &mut Vec<(String, &'a NameNode<'a>)>,
) {
    for (name, node) in nodes {
        let qname = if prefix.is_empty() { name.clone() } else { format!("{prefix}.{name}") };
        if let NodeKind::Class(c) = &node.kind
            && matches!(c.restriction, Absyn::Restriction::R_FUNCTION { .. }) {
                out.push((qname.clone(), node));
            }
        collect_functions(&node.children, &qname, out);
    }
}

/// Does a function class carry an algorithm section of its own? A function that
/// `extends` a partial base but has no body inlines the base's algorithm at
/// codegen time (see `emit_function`'s `inherited_alg_base`), so its
/// fallibility must include the base's — see the `base_fn` edges in [`analyze`].
fn class_has_own_algorithm(c: &MM::Class) -> bool {
    match &c.body {
        MM::ClassDef::Parts { algorithms, .. } | MM::ClassDef::ClassExtends { algorithms, .. } =>
            !algorithms.is_empty(),
        _ => false,
    }
}

/// Names of every component (input/output/protected) visible on a function
/// node, *including those merged in from a base via `extends`*. The raw AST
/// `MM::Class` body only lists the function's own components, so inherited
/// function-typed inputs (the `toString`/`func` callbacks of a partial base)
/// would be invisible to [`Walk::record_call`] — and a call through one would
/// not register as `calls_fn_value`. `flatten_extends` records the merged set in
/// `node.children`, so read the component children from there.
fn node_component_names(node: &NameNode<'_>) -> BTreeSet<String> {
    node.children
        .iter()
        .filter(|(_, c)| matches!(c.kind, NodeKind::Component(_)))
        .map(|(n, _)| n.clone())
        .collect()
}

/// Resolve a raw callee name to its fully-qualified MM name relative to the
/// caller's enclosing package, using the same scoping rules codegen uses.
///
/// Returns `None` when the name doesn't resolve to anything in the hierarchy
/// (typical for builtins and external symbols, which are handled separately).
fn resolve_called_qname<'a>(
    raw: &str,
    caller_qname: &str,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
) -> Option<String> {
    // Pass the *full* caller FQN as the scope prefix, not the enclosing
    // package. `resolve_call_node` walks the prefix outward one segment at
    // a time, so this lets it try `Mod.Caller.callee` first (catching
    // function-nested helper functions) before falling back to
    // `Mod.callee` and the bare top-level lookup. Stripping the function
    // name eagerly would skip the function-nested case and the
    // fallibility analysis would then see the call as unresolved.
    resolve_call_node(raw, top_level, caller_qname).map(|(q, _)| q)
}

// ── Driver ───────────────────────────────────────────────────────────────────

/// Run the full analysis pass.  Visits every function class in `hier`, scans
/// its body for calls / external bindings / match expressions, and computes
/// the fixed point of "is fallible".  Panics if it encounters an unlisted
/// external "C" symbol — see [`crate::external_c_calls::lookup_or_panic`].
pub fn analyze(hier: &InstanceHierarchy<'_>) -> FallibilityInfo {
    let mut functions: Vec<(String, &NameNode<'_>)> = Vec::new();
    collect_functions(&hier.top_level, "", &mut functions);

    // Map each function node's underlying `MM::Class` pointer to its FQN, so a
    // `base_fn` link (a bare `&MM::Class` with no name attached) can be turned
    // back into the qname of the in-`walks` base function. Also index every
    // function node by FQN to look up a resolved `extends` base's components.
    let mut ptr_to_qname: std::collections::HashMap<*const MM::Class, String> = std::collections::HashMap::new();
    let mut node_by_qname: std::collections::HashMap<&str, &NameNode<'_>> = std::collections::HashMap::new();
    for (q, n) in &functions {
        if let NodeKind::Class(c) = &n.kind {
            ptr_to_qname.insert(*c as *const MM::Class, q.clone());
        }
        node_by_qname.insert(q.as_str(), n);
    }

    // Resolve the base function(s) a derived function `extends`. A function
    // `extends`ing a partial base inherits that base both for codegen (the
    // base's algorithm is inlined, or at minimum its inputs/outputs are merged
    // into the signature) and for fallibility. Sources, both kept:
    //   * `node.extends` — `function F extends G(...);` paths, resolved by name
    //     (the common sibling-partial-function case).
    //   * `node.base_fn` — the precomputed link for header-form / package
    //     `extends`, where by-name resolution may miss the base package.
    let resolve_bases = |qname: &str, node: &NameNode<'_>| -> Vec<String> {
        let mut bases: Vec<String> = Vec::new();
        for ext in &node.extends {
            let dotted = path_to_dotted(&ext.path);
            if let Some(b) = resolve_called_qname(&dotted, qname, &hier.top_level) {
                bases.push(b);
            }
        }
        if let Some(b) = node.base_fn.and_then(|bf| ptr_to_qname.get(&(bf as *const MM::Class)).cloned()) {
            bases.push(b);
        }
        bases
    };

    // Per-function scan results, keyed by FQN. Storing the Walk separately
    // from the fallibility set keeps the propagation loop allocation-free.
    let mut walks: BTreeMap<String, Walk> = BTreeMap::new();
    let mut external_count = 0usize;
    // Function-alias edges, keyed by alias FQN → unresolved base name (as
    // written in `function Foo = Bar(...)`). Resolved to FQN below alongside
    // the rest of the call edges so the alias inherits its target's
    // fallibility classification.
    let mut alias_bases: BTreeMap<String, String> = BTreeMap::new();
    // Inherited-algorithm edges, keyed by derived-function FQN → base-function
    // FQN(s). A body-less function that `extends` a partial base inlines the
    // base's algorithm at codegen time, so it inherits the base's fallibility
    // (e.g. `DiffAlgorithm.printActual extends partialPrintDiff`, whose inlined
    // body calls the `toString` callback and the fallible `Print.*` builtins).
    let mut base_fn_edges: BTreeMap<String, Vec<String>> = BTreeMap::new();
    for (qname, node) in &functions {
        let NodeKind::Class(class) = &node.kind else { continue };
        let bases = resolve_bases(qname, node);
        // Scope visible to the body = this function's own + inherited
        // components, PLUS the components of any `extends` base. When the base's
        // algorithm is inlined into this AST body (as happens for some nested
        // functions, e.g. `NBEquation.Equation.simplify.apply extends
        // MapFuncExpWrapper`), the base's function-typed inputs (`func`) are not
        // copied into this node's children, yet the inlined body calls them —
        // so a call through one only registers as `calls_fn_value` if the
        // base's input names are in scope here.
        let mut inherited_scope = node_component_names(node);
        for base_q in &bases {
            if let Some(base_node) = node_by_qname.get(base_q.as_str()) {
                inherited_scope.extend(node_component_names(base_node));
            }
        }
        let w = Walk::scan_class(class, &inherited_scope);
        if w.external.is_some() {
            external_count += 1;
        }
        walks.insert(qname.clone(), w);
        if let Ty::FunctionAlias { base, .. } = &node.ty {
            alias_bases.insert(qname.clone(), base.clone());
        }
        // Only when the derived function has no algorithm of its own does
        // codegen inline the base's body (matching `inherited_alg_base`); a
        // function that extends a base purely for its signature but supplies
        // its own body does not inherit the base's calls. (When the base's
        // body was already inlined into this AST, it is scanned directly above,
        // and the base-component scope handles its callbacks.)
        if !class_has_own_algorithm(class) && !bases.is_empty() {
            base_fn_edges.insert(qname.clone(), bases);
        }
    }

    // Resolve every Walk (incl. the per-arm sub-walks of matchcontinue
    // checks) into qname edges + immediate verdicts.
    //
    // For functions with an `external` clause, look up the classification in
    // priority order:
    //   1. The C symbol in [`external_c_calls`] — the strict registry of
    //      genuine `OMCompiler/Compiler/runtime/*.c` symbols. An explicit
    //      registry entry is authoritative: it is keyed by the exact C
    //      symbol, whereas the builtin table below is keyed by bare MM name
    //      and would mis-classify same-named functions (e.g.
    //      `ParserExt.stringEq` → C symbol `ParserExt_stringEq`, a fallible
    //      parser entry point, must not be classified as the infallible
    //      `stringEq` string-comparison builtin).
    //   2. The MM-side bare name in [`builtin_fallibility`] — this is where
    //      Modelica language built-ins (`sin`, `cos`, `assert`, the array
    //      constructors, the signal operators, …) live. They are declared
    //      with `external "C"` in `ModelicaBuiltin.mo` but the compiler
    //      implements them directly; they are NOT calls into the OpenModelica
    //      C runtime, so they have no registry entry.
    //   3. Neither table knows the symbol: `lookup_or_panic` reports the
    //      missing registry entry (unless `MMTORUST_LENIENT_EXTERNALS=1`).
    let mut resolved: BTreeMap<String, ResolvedSources> = BTreeMap::new();
    for (qname, w) in &walks {
        let mut rs = resolve_walk(w, qname, &hier.top_level, &walks);
        if let Some(c_name) = &w.external {
            let simple = qname.rsplit_once('.').map(|(_, s)| s).unwrap_or(qname.as_str());
            let f = external_c_calls::lookup(c_name)
                .or_else(|| builtin_fallibility(simple))
                .unwrap_or_else(|| external_c_calls::lookup_or_panic(c_name, qname));
            if matches!(f, Fallibility::Fallible) {
                rs.always = true;
            }
        }
        // `function Foo = Bar(...)` aliases have no body of their own; their
        // fallibility comes from the base function. Add the resolved edge so
        // the fixed-point loop propagates it. Unresolved bases fall through
        // to the builtin table — pathStringNoQual → pathString, for example.
        if let Some(base) = alias_bases.get(qname) {
            if let Some(target) = resolve_called_qname(base, qname, &hier.top_level) {
                if walks.contains_key(&target) {
                    rs.edges.insert(target);
                }
            } else if let Some(b) = builtin_fallibility(base)
                && matches!(b, Fallibility::Fallible) {
                    rs.always = true;
                }
        }
        // A body-less function that `extends` a partial base inlines that
        // base's algorithm, so it inherits the base's fallibility. Only edges
        // to user-defined functions present in `walks` matter.
        if let Some(bases) = base_fn_edges.get(qname) {
            for base_q in bases {
                if walks.contains_key(base_q) {
                    rs.edges.insert(base_q.clone());
                }
            }
        }
        resolved.insert(qname.clone(), rs);
    }

    // Fixed point: a function becomes fallible as soon as one of its sources
    // evaluates fallible under the current set — a reachable fallible callee,
    // or a matchcontinue losing its last covering set of infallible arms.
    // [`sources_fallible`] is monotone in `fallible`, so saturating from the
    // empty set yields the least fixed point (the most precise sound
    // verdict). Naive O(n·#iters) re-evaluation — sufficient at current
    // scale (a few thousand functions) and easy to verify.
    let mut fallible: BTreeSet<String> = BTreeSet::new();
    loop {
        let mut changed = false;
        for (qname, rs) in &resolved {
            if fallible.contains(qname) { continue; }
            if sources_fallible(rs, &fallible) {
                fallible.insert(qname.clone());
                changed = true;
            }
        }
        if !changed { break; }
    }

    // With the fixed point reached, flag every `matchcontinue` whose arms —
    // *except the last* — are all infallible: the fall-through-on-failure that
    // distinguishes it from a `match` only fires when there is a *next* arm to
    // fall back to, so the last arm's fallibility is irrelevant (if it fails,
    // `matchcontinue` has nothing left to try and fails too — exactly what
    // `match` does). It is then exactly a `match` (see [`McLint`]).
    // `resolved` is a BTreeMap and each function's lints are in source order, so
    // the result is already deterministically ordered by FQN then position.
    let mut matchcontinue_as_match: Vec<String> = Vec::new();
    let mut matchcontinue_as_match_locs: Vec<Absyn::Info> = Vec::new();
    for (qname, rs) in &resolved {
        for lint in &rs.mc_lints {
            // Skip the final arm: a failure there can't fall through to anything.
            let non_last = lint.arms.len().saturating_sub(1);
            if lint.arms[..non_last].iter().all(|arm| !sources_fallible(arm, &fallible)) {
                matchcontinue_as_match.push(format!(
                    "warning: matchcontinue in `{qname}` ({}:{}:{}) has no fallible arm before its last — rewrite it as `match`",
                    lint.info.fileName, lint.info.lineNumberStart, lint.info.columnNumberStart,
                ));
                matchcontinue_as_match_locs.push(lint.info.clone());
            }
        }
    }

    FallibilityInfo {
        fallible_functions: fallible,
        total_functions: functions.len(),
        external_functions: external_count,
        matchcontinue_as_match,
        matchcontinue_as_match_locs,
    }
}

// ── Source resolution & fixed-point evaluation ───────────────────────────────

/// A [`Walk`] with its raw callee names resolved against the hierarchy and
/// the builtin table, ready for repeated evaluation in the fixed point.
#[derive(Debug, Default)]
struct ResolvedSources {
    /// Fallible regardless of the call graph: a local `fail()` / `failure()`
    /// clause / refutable `:=` LHS / non-exhaustive `match`, a call through a
    /// function value, a call to a fallible builtin — or, for `external`
    /// functions, a fallible registry classification (set by the caller in
    /// [`analyze`]).
    always: bool,
    /// FQNs of user-defined callees; fallible iff any of them is.
    edges: BTreeSet<String>,
    /// Per-`matchcontinue` safety obligations (see [`McCheck`]).
    mc: Vec<ResolvedMcCheck>,
    /// Per-`matchcontinue` rewrite-as-`match` diagnostics (see [`McLint`]).
    /// Purely advisory — never consulted by [`sources_fallible`].
    mc_lints: Vec<ResolvedMcLint>,
}

/// [`McCheck`] after callee-name resolution.
#[derive(Debug, Default)]
struct ResolvedMcCheck {
    candidates: Vec<(CoverKey, ResolvedSources)>,
}

/// [`McLint`] after callee-name resolution.
#[derive(Debug)]
struct ResolvedMcLint {
    info: Absyn::Info,
    arms: Vec<ResolvedSources>,
}

/// Resolve a [`Walk`]'s raw callee names (recursively through its
/// matchcontinue sub-walks) into [`ResolvedSources`]. `caller_qname` is the
/// enclosing *function* for every nesting level — match arms share the
/// function's name-resolution scope.
fn resolve_walk(
    w: &Walk,
    caller_qname: &str,
    top_level: &BTreeMap<String, NameNode<'_>>,
    walks: &BTreeMap<String, Walk>,
) -> ResolvedSources {
    let mut rs = ResolvedSources {
        always: w.has_fail || w.has_match || w.calls_fn_value,
        ..ResolvedSources::default()
    };
    for raw in &w.calls {
        // Resolve user-defined callee first: a user function shadows any
        // same-named builtin (e.g. `exp` inside `Template.TplMain`
        // refers to the AST-printer, not the math `exp` builtin).
        // If the name resolves to a node in the hierarchy, record the
        // edge for fixed-point propagation. Otherwise fall through to
        // the builtin table.
        if let Some((target, node)) = resolve_call_node(raw, top_level, caller_qname) {
            if walks.contains_key(&target) {
                // A user function shadows any same-named builtin (e.g. `exp`
                // inside `Template.TplMain` refers to the AST-printer, not the
                // math `exp` builtin), so record the edge and stop here.
                rs.edges.insert(target);
                continue;
            }
            if crate::hierarchy::is_external_object_class(node) {
                // A call to an ExternalObject class constructs it via its inner
                // `constructor`. Codegen emits every such constructor as an
                // unimplemented `todo!()` stub returning `Result<Foo>` (the
                // runtime `external "C"` symbol is not yet wired up — see
                // `emit_external_object`), so calling one is unconditionally
                // fallible regardless of the underlying C symbol's own
                // classification. Mark the caller fallible to match.
                rs.always = true;
                continue;
            }
            // Resolved to some other non-function node (record/type
            // constructor, package, partial-application reference, …). Those
            // never fail in our lowering — except when the name actually
            // denotes a builtin reached through an import alias, which the
            // builtin fallback below recognises by its trailing segment.
        }
        // Consult the builtin table, trying the full dotted name first and
        // then the trailing segment. The trailing-segment form catches
        // builtins referenced through an import alias — `import
        // MetaModelica.Dangerous;` then `Dangerous.listSetRest(...)` records
        // the qualified name, but the table is keyed by the bare builtin name
        // (`listSetRest`), so the qualified form would otherwise be dropped
        // and its (genuine) fallibility lost. A user function of the same bare
        // name was already handled above (it resolves into `walks`), so this
        // cannot mis-shadow one.
        let bare = raw.rsplit('.').next().unwrap_or(raw);
        if let Some(b) = builtin_fallibility(raw).or_else(|| builtin_fallibility(bare)) {
            if matches!(b, Fallibility::Fallible) {
                rs.always = true;
            }
            continue;
        }
        // Otherwise unresolved: a call through a function value (a
        // callback parameter or function-typed local/field) is already
        // accounted for via [`Walk::calls_fn_value`] during scanning, so it
        // does not need a call-graph edge here. Anything else that reaches
        // this point is a name we genuinely could not resolve (e.g. a
        // resolution gap); it contributes no edge. Marking it fallible
        // would be sound but would conflate true callbacks with resolution
        // bugs, so we leave it — `calls_fn_value` already covers the real
        // higher-order cases.
    }
    for mc in &w.mc_checks {
        rs.mc.push(ResolvedMcCheck {
            candidates: mc.candidates.iter()
                .map(|(key, sub)| (*key, resolve_walk(sub, caller_qname, top_level, walks)))
                .collect(),
        });
    }
    for lint in &w.mc_lints {
        rs.mc_lints.push(ResolvedMcLint {
            info: lint.info.clone(),
            arms: lint.arms.iter()
                .map(|sub| resolve_walk(sub, caller_qname, top_level, walks))
                .collect(),
        });
    }
    rs
}

/// Evaluate a function's failure sources under the current `fallible` set.
/// Monotone in `fallible`: a growing set can only flip verdicts from
/// infallible to fallible (directly through `edges`, or by shrinking the set
/// of infallible matchcontinue candidates below coverage).
fn sources_fallible(rs: &ResolvedSources, fallible: &BTreeSet<String>) -> bool {
    rs.always
        || rs.edges.iter().any(|t| fallible.contains(t))
        || rs.mc.iter().any(|mc| !mc_check_is_safe(mc, fallible))
}

/// A `matchcontinue` cannot fail iff the patterns of its infallible
/// candidate arms exhaustively cover the scrutinee: execution falls through
/// failing/mismatching arms until it reaches a covering arm that — being
/// infallible — runs to completion. The codegen counterpart needs no typed-IR
/// twin of this predicate: the `MatchKind::MatchContinue` lowering emits
/// every arm as a `Result` closure and its no-arm-matched fallback through
/// [`crate::codegen`]'s `emit_diverging_fail`, both of which are valid in
/// fallible and infallible functions alike.
fn mc_check_is_safe(mc: &ResolvedMcCheck, fallible: &BTreeSet<String>) -> bool {
    let keys: Vec<CoverKey> = mc.candidates.iter()
        .filter(|(_, sub)| !sources_fallible(sub, fallible))
        .map(|(key, _)| *key)
        .collect();
    cover_keys_exhaustive(&keys)
}
