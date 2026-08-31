#![allow(unused)]

use std::collections::HashMap;
use std::collections::BTreeMap;
use std::sync::Arc;
use openmodelica_ast::Absyn;
use crate::MM;
use crate::hierarchy::{FunctionInput, NameNode, NodeKind, Ty, extract_default_exp, strip_exp_wrappers, lookup_record_through_unions, collect_type_vars_in_ty, collect_type_vars_in_env};

// ── Literal values ────────────────────────────────────────────────────────────

#[derive(Debug, Clone, PartialEq)]
pub enum Lit {
    Int(i32),
    Real(String),
    Str(String),
    Bool(bool),
}

// ── Operator kinds ────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum BinOpKind {
    Add, Sub, Mul, Div, Pow,
    And, Or,
    Eq, NEq, Lt, LEq, Gt, GEq,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum UnOpKind { Neg, Not }

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum MatchKind { Match, MatchContinue }

/// How multiple iterators in a reduction interact:
/// - `Combine`: cartesian product (the default; e.g. `f(e for i in xs, j in ys)`).
/// - `Thread`:  zip (introduced by the `threaded` keyword).
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ReductionIterKind { Combine, Thread }

/// One iterator in a reduction. `range` is the source collection, `guard` is an
/// optional Boolean filter expression evaluated per element.
#[derive(Debug, Clone)]
pub struct ReductionIter {
    pub name: String,
    pub range: TypedExp,
    pub guard: Option<TypedExp>,
    pub elem_ty: Ty,
}

// ── Typed expression IR ───────────────────────────────────────────────────────

/// One case in a match/matchcontinue expression.
#[derive(Debug, Clone)]
pub struct TypedCase {
    pub pattern: TypedPat,
    pub guard: Option<TypedExp>,
    /// Case-local declarations.  Each entry is
    /// `(name, type, default, original TypeSpec)` where `default` is the
    /// optional binding expression from the MetaModelica source (e.g.
    /// `list<list<T>> ol = {};`) and `type_spec` is the syntactic source
    /// type used at declaration (kept so codegen can recover a `Key`/`Value`
    /// alias reference instead of inlining the resolved concrete type).
    /// When `default` is present, codegen emits the local as
    /// `let mut <name>: <ty> = <default>;` so that the body may read it
    /// before any explicit assignment, matching MetaModelica semantics.
    pub locals: Vec<(String, Ty, Option<TypedExp>, Option<Absyn::TypeSpec>)>,
    pub stmts: Vec<TypedStmt>,
    pub result: TypedExp,
}

/// One segment of a structured component reference, carrying its subscripts.
/// e.g. `arr[1].field[2+i]` → `[Seg("arr",[1]), Seg("field",[2+i])]`
#[derive(Debug, Clone)]
pub struct CrefSegment {
    pub name: String,
    pub subscripts: Vec<TypedExp>,
}

#[derive(Debug, Clone)]
pub enum TypedExp {
    Lit(Lit),
    /// A variable reference or constant path.
    /// `name` is the dotted MM name (for lookup/compat).
    /// `segments` carries the structured parts with subscripts.
    /// `last_use` is set by [`crate::codegen::mark_last_uses`] (a backward
    /// liveness pass run just before emission): `true` means this occurrence is
    /// the final read of the variable on every forward path, so the code
    /// generator may *move* an owned value here instead of cloning it. Defaults
    /// to `false` (clone) — a freshly synthesised `Var` is always treated as a
    /// non-final use, which is the safe choice.
    Var { name: String, segments: Vec<CrefSegment>, ty: Ty, last_use: bool },
    BinOp { op: BinOpKind, lhs: Box<TypedExp>, rhs: Box<TypedExp>, ty: Ty },
    UnOp { op: UnOpKind, operand: Box<TypedExp>, ty: Ty },
    /// A function call. `func` is the dotted MM name (e.g. "List.map", "SOME").
    Call { func: String, args: Vec<TypedExp>, named_args: Vec<(String, TypedExp)>, ty: Ty, sig_ty: Ty },
    /// A constructor/record literal. `name` is the dotted MM name.
    Constructor { name: String, args: Vec<TypedExp>, named_args: Vec<(String, TypedExp)>, ty: Ty, field_names: Vec<String> },
    /// Partial function application: `function f(arg1 = e1, arg2 = e2, ...)` —
    /// produces a callable value with the named/positional formals bound and the
    /// remaining formals still open. Lowers to a Rust closure that captures the
    /// bound expressions and forwards the unbound formals to `f`.
    ///
    /// `func` is the MM name of the underlying function. `args` are positional
    /// bindings (each binds the i-th formal); `named_args` are bindings keyed by
    /// formal name. `sig_ty` is the resolved `Ty::Function` of `func` (carrying
    /// formal names/types, needed by codegen to know which formals remain
    /// unbound). `ty` is the resulting function type — `sig_ty` with the bound
    /// formals removed from `inputs`.
    PartEval {
        func: String,
        args: Vec<TypedExp>,
        named_args: Vec<(String, TypedExp)>,
        sig_ty: Ty,
        ty: Ty,
        /// True when `func` is a function-typed local variable (e.g.
        /// `Slice.filterCref filter; … function filter(acc = occ2)`), so the
        /// partial application closes over the variable's *value*. Codegen
        /// must call the local (an `Arc<dyn Fn(..) -> Result<..>>`, hence
        /// always fallible) instead of resolving the name to a function
        /// declaration.
        callee_is_local: bool,
    },
    If {
        cond: Box<TypedExp>,
        then_: Box<TypedExp>,
        elseif: Vec<(TypedExp, TypedExp)>,
        else_: Box<TypedExp>,
        ty: Ty,
    },
    Cons { head: Box<TypedExp>, tail: Box<TypedExp>, ty: Ty },
    Tuple(Vec<TypedExp>),
    /// An array/list literal. Empty array = empty list.
    Array { elems: Vec<TypedExp>, ty: Ty },
    /// `as_binding` is `Some(name)` when the source wrote `match name as expr ...`,
    /// in which case the scrutinee value must be bound to `name` and visible in
    /// every arm's guard / locals / body / result.
    Match { kind: MatchKind, input: Box<TypedExp>, cases: Vec<TypedCase>, ty: Ty, as_binding: Option<String> },
    /// `start:stop` or `start:step:stop` — an arithmetic-progression iterator.
    Range { start: Box<TypedExp>, step: Option<Box<TypedExp>>, stop: Box<TypedExp>, elem_ty: Ty },
    /// A reduction expression `f(body for iter1 in r1, iter2 in r2, ...)` (or
    /// `threaded for ...` for zip semantics). The reduction is identified by
    /// `func` — either a builtin (`list`, `listReverse`, `sum`, `product`,
    /// `min`, `max`, `listAppend`) or a user-defined function whose signature
    /// must carry a `defaultValue` so the accumulator can be seeded.
    Reduction {
        func: String,
        body: Box<TypedExp>,
        iterators: Vec<ReductionIter>,
        iter_kind: ReductionIterKind,
        ty: Ty,
    },
    Todo(String),
}

impl TypedExp {
    pub fn ty(&self) -> Ty {
        match self {
            TypedExp::Lit(Lit::Int(_))  => Ty::I32,
            TypedExp::Lit(Lit::Real(_)) => Ty::F64,
            TypedExp::Lit(Lit::Str(_))  => Ty::Str,
            TypedExp::Lit(Lit::Bool(_)) => Ty::Bool,
            TypedExp::Var    { ty, .. }  => ty.clone(),
            TypedExp::BinOp  { ty, .. }  => ty.clone(),
            TypedExp::UnOp   { ty, .. }  => ty.clone(),
            TypedExp::Call   { ty, .. }  => ty.clone(),
            TypedExp::Constructor { ty, .. } => ty.clone(),
            TypedExp::If     { ty, .. }  => ty.clone(),
            TypedExp::Cons   { ty, .. }  => ty.clone(),
            TypedExp::Array  { ty, .. }  => ty.clone(),
            TypedExp::Match  { ty, .. }  => ty.clone(),
            TypedExp::Range  { elem_ty, .. } => Ty::Range(Box::new(elem_ty.clone())),
            TypedExp::Reduction { ty, .. } => ty.clone(),
            TypedExp::PartEval { ty, .. } => ty.clone(),
            TypedExp::Tuple(v) => Ty::Tuple(v.iter().map(|e| e.ty()).collect()),
            TypedExp::Todo(_)  => Ty::Unknown,
        }
    }
}

// ── Typed pattern IR ──────────────────────────────────────────────────────────

#[derive(Debug, Clone)]
pub enum TypedPat {
    Wildcard,
    /// A binding variable introduced by this pattern.
    Var(String),
    Lit(Lit),
    EmptyList,
    Some_(Box<TypedPat>),
    None_,
    Cons { head: Box<TypedPat>, tail: Box<TypedPat> },
    Tuple(Vec<TypedPat>),
    /// A constructor/record pattern.
    /// `name` is the dotted MM name; `fields` are positional args; `named_fields` are named args.
    Constructor {
        name: String,
        fields: Vec<TypedPat>,
        named_fields: Vec<(String, TypedPat)>,
        ty: Ty,
    },
    /// `var as pat` — binds `var` to the whole value while also matching `pat`.
    As { var: String, pat: Box<TypedPat> },
    /// Array element access in pattern position (e.g. `arr[1]` on LHS of `:=`).
    Index { base: TypedExp, index: TypedExp },
    /// Field access on a local variable (e.g. `exarray.lastUsedIndex` where `exarray`
    /// is a variable). This must emit as `base.field` not as a let pattern.
    FieldAccess { base: Box<TypedPat>, field: String },
    Todo(String),
}

// ── Inference ─────────────────────────────────────────────────────────────────

/// Convert a ComponentRef to a dotted MetaModelica name (e.g. "List.map").
/// Deprecated: loses subscripts and structure. Use `extract_cref_segments` instead.
pub fn cref_to_dotted(cref: &Absyn::ComponentRef) -> String {
    let raw = match cref {
        Absyn::ComponentRef::CREF_IDENT { name, .. } => name.to_string(),
        Absyn::ComponentRef::CREF_QUAL { name, componentRef, .. } => {
            format!("{name}.{}", cref_to_dotted(componentRef))
        }
        Absyn::ComponentRef::CREF_FULLYQUALIFIED { componentRef } => cref_to_dotted(componentRef),
        Absyn::ComponentRef::WILD | Absyn::ComponentRef::ALLWILD => "_".to_owned(),
    };
    match raw.as_str() {
        // NB: `arrayGetNoBoundsChecking` / `arrayUpdateNoBoundsChecking` /
        // `stringGetNoBoundsChecking` are deliberately NOT normalised to the
        // plain bounds-checked builtins. They are distinct functions with their
        // own (unchecked) semantics and lower to real
        // `metamodelica::Dangerous::*NoBoundsChecking(..)` calls (see the
        // dedicated arms in `emit_builtin_call`). Renaming them here would
        // silently substitute the bounds-checked, `Result`-returning builtin.
        // arrayCreateNoInit is kept distinct from arrayCreate: it lowers to
        // `metamodelica::Dangerous::arrayCreateNoInit(size)` which takes only the
        // size (the MetaModelica `dummy` second argument is a type witness only
        // and is dropped at codegen time).
        // The 2-segment `MetaModelica.arrayCreateNoInit` form appears when the
        // Absyn strips the intermediate `Dangerous` package (as it does for
        // these builtins in SimpleModelicaParser).
        "MetaModelica.Dangerous.arrayCreateNoInit" | "Dangerous.arrayCreateNoInit" | "MetaModelica.arrayCreateNoInit" => "arrayCreateNoInit".to_owned(),
        "MetaModelica.Dangerous.listArrayLiteral" | "Dangerous.listArrayLiteral" | "listArrayLiteral" => "listArray".to_owned(),
        // `listAppendDestroy(first, second)` destructively splices `second` onto
        // the end of `first` with no allocation. Kept distinct from `listAppend`
        // (like `arrayCreateNoInit` vs `arrayCreate`) so codegen routes it to the
        // runtime's in-place implementation; only the qualified spelling is
        // normalised to the bare builtin name here.
        "MetaModelica.Dangerous.listAppendDestroy" | "Dangerous.listAppendDestroy" | "listAppendDestroy" => "listAppendDestroy".to_owned(),
        // OpenModelica scripting builtins. These live in `package OpenModelica
        // package Scripting ... function uriToFilename ... external "builtin"
        // ... end uriToFilename;` in NFModelicaBuiltin.mo, which the codegen
        // excludes from compilation (we don't emit a Rust `pub mod OpenModelica`).
        // Route the source-level qualified call to the runtime port in the
        // `metamodelica` crate.
        // The 2-segment `OpenModelica.uriToFilename` form appears when the
        // Absyn parser collapses the intermediate `Scripting` package (and
        // for the matching reference in CevalScriptBackend / NFCeval the
        // shape is consistently shorter than the source spelling).
        "OpenModelica.Scripting.uriToFilename"
        | "OpenModelica.uriToFilename"
        | "Scripting.uriToFilename" => "uriToFilename".to_owned(),
        _ => raw,
    }
}

/// Extract structured segments (with subscripts) from a ComponentRef.
/// Returns (dotted_name, segments). The segments are in read-order:
/// `arr[1].field` → [("arr", [1]), ("field", [])]
fn extract_cref_segments<'a>(
    cref: &Absyn::ComponentRef,
    env: &HashMap<String, Ty>,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
) -> (String, Vec<CrefSegment>) {
    // Collect segments in read-order (head -> tail).
    let mut segs: Vec<CrefSegment> = Vec::new();
    collect_cref_segments_rev(cref, env, top_level, pkg_prefix, &mut segs);

    let dotted: String = segs.iter().map(|s| s.name.clone()).collect::<Vec<_>>().join(".");
    (dotted, segs)
}

fn collect_cref_segments_rev<'a>(
    cref: &Absyn::ComponentRef,
    env: &HashMap<String, Ty>,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
    acc: &mut Vec<CrefSegment>,
) {
    match cref {
        Absyn::ComponentRef::CREF_IDENT { name, subscripts } => {
            let subs: Vec<TypedExp> = (&**subscripts).into_iter()
                .filter_map(|s| {
                    if let Absyn::Subscript::SUBSCRIPT { subscript } = s.as_ref() {
                        Some(infer_exp(subscript, env, top_level, pkg_prefix, &[]))
                    } else {
                        None
                    }
                })
                .collect();
            acc.push(CrefSegment { name: name.to_string(), subscripts: subs });
        }
        Absyn::ComponentRef::CREF_QUAL { name, subscripts, componentRef } => {
            let subs: Vec<TypedExp> = (&**subscripts).into_iter()
                .filter_map(|s| {
                    if let Absyn::Subscript::SUBSCRIPT { subscript } = s.as_ref() {
                        Some(infer_exp(subscript, env, top_level, pkg_prefix, &[]))
                    } else {
                        None
                    }
                })
                .collect();
            acc.push(CrefSegment { name: name.to_string(), subscripts: subs });
            collect_cref_segments_rev(componentRef, env, top_level, pkg_prefix, acc);
        }
        Absyn::ComponentRef::CREF_FULLYQUALIFIED { componentRef } => {
            collect_cref_segments_rev(componentRef, env, top_level, pkg_prefix, acc);
        }
        Absyn::ComponentRef::WILD | Absyn::ComponentRef::ALLWILD => {
            acc.push(CrefSegment { name: "_".to_owned(), subscripts: vec![] });
        }
    }
}

/// Convert an `Absyn::Path` to a dotted string (e.g. `"Pkg.Sub.Name"`).
fn path_to_dotted(path: &Absyn::Path) -> String {
    match path {
        Absyn::Path::IDENT { name } => name.to_string(),
        Absyn::Path::QUALIFIED { name, path } => format!("{name}.{}", path_to_dotted(path)),
        Absyn::Path::FULLYQUALIFIED { path } => path_to_dotted(path),
    }
}

/// Extract the target dotted path from any import (including unqualified/wildcard).
fn import_any_target_path(import: &Absyn::Import) -> Option<String> {
    match import {
        Absyn::Import::NAMED_IMPORT { path, .. }
        | Absyn::Import::QUAL_IMPORT { path }
        | Absyn::Import::UNQUAL_IMPORT { path } => {
            let d = path_to_dotted(path);
            if d.is_empty() { None } else { Some(d) }
        }
        _ => None,
    }
}

/// Extract the target dotted path from a named or qualified import statement.
/// Returns `None` for wildcard (`import Pkg.*`) and group imports.
pub(crate) fn import_target_path(import: &Absyn::Import) -> Option<String> {
    match import {
        Absyn::Import::NAMED_IMPORT { path, .. } | Absyn::Import::QUAL_IMPORT { path } => {
            let d = path_to_dotted(path);
            if d.is_empty() { None } else { Some(d) }
        }
        _ => None,
    }
}

/// Resolve the target dotted path for `local` under an import node. `local` is the
/// local alias / simple name being looked up against the import.
///
/// - NAMED_IMPORT (`import X = A.B;`): always resolves to `A.B` (the local alias is
///   already incorporated in the import declaration).
/// - QUAL_IMPORT (`import A.B;`): resolves to `A.B`.
/// - GROUP_IMPORT (`import P.{a, b as c};`): resolves to `P.<orig>` where `<orig>`
///   is the entry whose local name (after rename, if any) matches `local`.
/// - UNQUAL_IMPORT (`import P.*;`): not handled here — wildcard imports are resolved
///   by separately scanning each child of the target package.
pub(crate) fn import_target_for_local(import: &Absyn::Import, local: &str) -> Option<String> {
    match import {
        Absyn::Import::NAMED_IMPORT { path, .. } | Absyn::Import::QUAL_IMPORT { path } => {
            let d = path_to_dotted(path);
            if d.is_empty() { None } else { Some(d) }
        }
        Absyn::Import::GROUP_IMPORT { prefix, groups } => {
            let prefix_str = path_to_dotted(prefix);
            for g in &**groups {
                let (is_match, orig) = match g {
                    Absyn::GroupImport::GROUP_IMPORT_NAME { name } => (&**name == local, name.to_string()),
                    Absyn::GroupImport::GROUP_IMPORT_RENAME { rename, name } => (&**rename == local, name.to_string()),
                };
                if is_match {
                    return Some(if prefix_str.is_empty() { orig } else { format!("{prefix_str}.{orig}") });
                }
            }
            None
        }
        _ => None,
    }
}

/// Walk a dotted path through the hierarchy, transparently following import alias nodes.
///
/// For example, if `NFBuiltin` has `import LookupTree = NFLookupTree`, then
/// `walk_dotted_with_imports("NFBuiltin.LookupTree.Tree.EMPTY", top_level)` resolves
/// `LookupTree` → `NFLookupTree` and returns the node for `NFLookupTree.Tree.EMPTY`.
///
/// Also handles `Ty::AliasTo` type aliases (e.g. `type ParameterTree = NFCallParameterTree.Tree`).
///
/// Depth-limited to avoid infinite loops from mutually-recursive import aliases.
pub(crate) fn walk_dotted_with_imports<'a>(
    dotted: &str,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    depth: u32,
) -> Option<(String, &'a NameNode<'a>)> {
    if depth > 8 {
        // Guard against pathological import alias cycles.
        return None;
    }

    // Fast path: direct lookup (also checks through intermediate uniontype nodes).
    if let Some((qname, node)) = lookup_record_through_unions(dotted, top_level)
        .or_else(|| lookup_node(dotted, top_level).map(|n| (dotted.to_owned(), n)))
    {
        // If the final node is an import alias, follow it so callers always see
        // the *target* node (record/function/etc.), not the Import declaration.
        // This covers function-scope imports like
        //   `function F  import Pkg.{X, Y};  ... X(...) ... end F;`
        // where bare `X` resolves to `F.X` — an Import node — but the user means
        // the imported entity. Without following the import, `is_constructor`
        // sees `NodeKind::Import` and falls through to "not a constructor",
        // making the call emit as a function call instead of a record literal.
        if let NodeKind::Import(m) = &node.kind {
            // The local name to match against the import is the *last segment* of
            // what we just looked up (e.g. `TOKEN` from `LexerModelicaDiff.filterModelicaDiff.TOKEN`).
            let local = qname.rsplit('.').next().unwrap_or(&qname);
            if let Some(target) = import_target_for_local(&m.import, local)
                && let Some(r) = walk_dotted_with_imports(&target, top_level, depth + 1) {
                    return Some(r);
                }
        }
        return Some((qname, node));
    }

    // Incremental walk: find the first prefix that exists in the hierarchy
    // and is an import or type-alias node, then substitute and retry.
    let parts: Vec<&str> = dotted.split('.').collect();
    for split in 1..parts.len() {
        let prefix = parts[..split].join(".");
        let Some(node) = lookup_node(&prefix, top_level) else { continue };

        // For an Import node used as a prefix, the "local" name is the *last
        // segment of the prefix* (which is what the user wrote to refer to it);
        // for GROUP_IMPORT this picks the matching group entry.
        let prefix_local = parts[split - 1];
        let target: Option<String> = match &node.kind {
            NodeKind::Import(m) => import_target_for_local(&m.import, prefix_local)
                .or_else(|| import_target_path(&m.import)),
            _ => None,
        }
        // Also follow type aliases recorded in the node's resolved type.
        .or_else(|| match &node.ty {
            Ty::AliasTo(t) => Some(t.clone()),
            Ty::RustEnum(t) | Ty::RustStruct(t) => Some(t.clone()),
            _ => None,
        });

        if let Some(target) = target {
            let rest = parts[split..].join(".");
            let resolved = if rest.is_empty() { target.clone() } else { format!("{target}.{rest}") };
            if let Some(r) = walk_dotted_with_imports(&resolved, top_level, depth + 1) {
                return Some(r);
            }
            // MetaModelica name resolution for `T = M.X` (a type alias to a type
            // declared inside a package): `T.foo(...)` first looks up `foo` as a
            // member of `X` (the type itself) and then *also* as a member of the
            // enclosing package `M`. This is how `extends BaseAvlTree` produces
            // a package with members like `new`, `listValues`, `hasKey`, etc.,
            // which are then reached through the renamed `FunctionTree` alias.
            // Without this fall-through, dotted calls like `FunctionTree.new()`
            // fail to resolve and the call emits as if `new` were an associated
            // function of `Arc<FunctionTreeImpl::Tree>`.
            if !rest.is_empty()
                && let Some((parent_target, _)) = target.rsplit_once('.') {
                let alt = format!("{parent_target}.{rest}");
                if let Some(r) = walk_dotted_with_imports(&alt, top_level, depth + 1) {
                    return Some(r);
                }
            }
        }
    }
    None
}

/// Resolve a call-site function name to a `(canonical_dotted_name, node)` pair.
///
/// Resolution order:
/// 1. Direct top-level lookup, including through intermediate uniontype nodes.
/// 2. With `pkg_prefix` prepended (walking up the scope hierarchy from the most-specific
///    enclosing scope to the least-specific), to resolve names relative to the current package.
/// 3. At each candidate path, import-alias nodes (and `AliasTo` type aliases) are followed
///    transparently so that e.g. `LookupTree.Tree.EMPTY` inside `NFBuiltin` resolves to
///    `NFLookupTree.Tree.EMPTY` via the `import LookupTree = NFLookupTree;` declaration.
///
/// This function does NOT use heuristics (case/prefix); all decisions are based on the
/// hierarchy.
fn find_record_in_package_unions<'a>(
    pkg_node: &'a NameNode<'a>,
    pkg_qname: &str,
    simple: &str,
) -> Option<(String, &'a NameNode<'a>)> {
    for (child_name, child) in &pkg_node.children {
        if let NodeKind::Class(c) = &child.kind
            && matches!(c.restriction, Absyn::Restriction::R_UNIONTYPE)
            && let Some(rec) = child.children.get(simple)
        {
            return Some((format!("{pkg_qname}.{child_name}.{simple}"), rec));
        }
    }
    None
}

/// Whether `func` resolves to a function class with more than one OUTPUT or
/// INPUT_OUTPUT direction member. A single-output function whose result type
/// happens to be a Tuple (e.g. `output tuple<A, B> branch`) returns false —
/// the tuple is the value, not a synthesized multi-output return.
///
/// Used by reduction inference to apply MetaModelica's implicit "first-output"
/// coercion only to genuine multi-output calls.
pub fn function_has_multiple_outputs<'a>(
    func: &str,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
) -> bool {
    let Some((_, node)) = resolve_call_node(func, top_level, pkg_prefix) else {
        return false;
    };
    let NodeKind::Class(c) = &node.kind else { return false; };
    let members = match &c.body {
        crate::MM::ClassDef::Parts { members, .. } | crate::MM::ClassDef::ClassExtends { members, .. } => members,
        _ => return false,
    };
    let mut count: usize = 0;
    for m in members.iter() {
        let crate::MM::ClassMember::Component(comp) = m else { continue };
        if matches!(comp.direction, Absyn::Direction::OUTPUT | Absyn::Direction::INPUT_OUTPUT) {
            count += 1;
            if count > 1 { return true; }
        }
    }
    false
}

pub fn resolve_call_node<'a>(
    func: &str,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
) -> Option<(String, &'a NameNode<'a>)> {
    // MetaModelica name resolution looks up names from the innermost scope
    // outwards. A local import alias must shadow any unrelated top-level
    // package of the same head segment — e.g. `Expression.transposeArray`
    // inside `NFCeval` (which declares `import Expression = NFExpression;`)
    // must resolve to `NFExpression.transposeArray`, not to the unrelated
    // top-level `Expression` package from `FrontEnd/Expression.mo`. So we
    // try the scope-qualified lookups first and only fall back to the
    // direct top-level form when nothing matches in any enclosing scope.
    //
    // 1. Qualify with each enclosing scope level (most-specific first). This
    //    naturally picks up import aliases declared at that scope through
    //    `walk_dotted_with_imports`'s incremental-walk import-follow step.
    if !pkg_prefix.is_empty() {
        let mut parts: Vec<&str> = pkg_prefix.split('.').collect();
        loop {
            let prefixed = format!("{}.{func}", parts.join("."));
            if let Some(r) = walk_dotted_with_imports(&prefixed, top_level, 0) {
                return Some(r);
            }
            if parts.is_empty() {
                break;
            }
            parts.pop();
        }
    }

    // 1b. A qualified `Package.Record` reference whose trailing segment names a
    //     record exported by one of the package's own uniontypes is a *local*
    //     member and shadows any same-named import the package declares. Resolve
    //     it before the import-following walk in step 2, which would otherwise
    //     resolve the trailing segment through that import. Example:
    //     `BackendDAE.DAE` — the record `DAE` of uniontype `BackendDAE` is
    //     shadowed by the enclosing package's own `import DAE;`, so step 2
    //     mis-resolves the constructor to the frontend `DAE` package, yielding a
    //     positional call on a named-field struct alias (E0423) and a pattern
    //     whose "fields" are the package's members (E0574).
    //     `lookup_record_through_unions` is a pure child walk (it never follows
    //     imports), and we only short-circuit when it lands on a non-package
    //     node, so bare package names and sub-package paths still fall through to
    //     the import-aware walk below.
    if func.contains('.')
        && let Some((qname, node)) = crate::hierarchy::lookup_record_through_unions(func, top_level)
        && !matches!(&node.kind, NodeKind::Class(c) if matches!(c.restriction, Absyn::Restriction::R_PACKAGE))
    {
        return Some((qname, node));
    }

    // 2. Direct lookup (handles fully-qualified top-level names not shadowed
    //    by any scope-local alias).
    if let Some(r) = walk_dotted_with_imports(func, top_level, 0) {
        // Packages are not callable. If the direct lookup landed on a package
        // and that package contains a uniontype whose record-variant has the
        // same simple name as `func`, prefer that record — this is the only
        // valid interpretation in a call position. Without this, a constant
        // like `emptyDae = DAE({})` inside the `DAE` package would resolve
        // `DAE` to the package itself instead of to the `DAElist.DAE` record.
        if let NodeKind::Class(c) = &r.1.kind
            && matches!(c.restriction, Absyn::Restriction::R_PACKAGE)
            && let Some(simple) = func.rsplit('.').next()
            && let Some((qname, rec)) = find_record_in_package_unions(r.1, &r.0, simple)
        {
            return Some((qname, rec));
        }
        return Some(r);
    }

    // 3. For each scope level, scan all import children and try to resolve `func`
    //    against each import's target package. This handles:
    //    - bare names whose source type's package is only reachable via import alias
    //      (e.g. `MATCHING` in a scope with `import Matching = NBMatching;` — the
    //      record `MATCHING` lives in `NBMatching` and is used unqualified)
    //    - bare/dotted names reachable via wildcard imports
    //      (e.g. `Replaceable.NOT_REPLACEABLE` in a scope with `import NFPrefixes.*`)
    if !pkg_prefix.is_empty() {
        let mut parts: Vec<&str> = pkg_prefix.split('.').collect();
        loop {
            let scope_path = parts.join(".");
            if let Some(scope_node) = lookup_node(&scope_path, top_level) {
                for child in scope_node.children.values() {
                    if let NodeKind::Import(m) = &child.kind
                        && let Some(target) = import_any_target_path(&m.import) {
                            let candidate = format!("{target}.{func}");
                            if let Some(r) = walk_dotted_with_imports(&candidate, top_level, 0) {
                                return Some(r);
                            }
                        }
                }
            }
            if parts.is_empty() {
                break;
            }
            parts.pop();
        }
    }

    None
}

/// If `ty` is the record-struct type of a multi-record uniontype variant,
/// return the parent uniontype's `Ty::RustEnum`; otherwise return `ty`
/// unchanged. The hierarchy stores variant records as `Ty::RustStruct(qname)`
/// where qname is the variant's full path (e.g. `"Absyn.Exp.STRING"`). When
/// that ty escapes into an *expression* context (the result type of a
/// reduction body, etc.), `fmt_ty` would render `Absyn::Exp::STRING` — a
/// variant path, which is not a valid Rust type. Promotion is needed at all
/// such sites; single-record uniontypes already encode the record under the
/// uniontype's own qname, so this is a no-op there.
fn promote_variant_to_enum_ty(ty: Ty, top_level: &BTreeMap<String, NameNode<'_>>) -> Ty {
    match ty {
        // A narrowed variant: `Ty::UnionTypeVariant(parent, _)` is a Rust path
        // (`Parent::Variant`), not a type. The parent enum is the actual type
        // of any value of that variant.
        Ty::UnionTypeVariant(parent, variant) => {
            match lookup_ty_in_hierarchy(&parent, top_level) {
                Ty::RustEnum(_) => Ty::RustEnum(parent),
                _ => Ty::UnionTypeVariant(parent, variant),
            }
        }
        // A record-struct of a multi-record uniontype: hierarchy stores it as
        // `Ty::RustStruct(<variant-qname>)`, which `fmt_ty` would render as the
        // variant path. Promote to the parent's `Ty::RustEnum`.
        Ty::RustStruct(qname) => {
            let Some((parent, _)) = qname.rsplit_once('.') else { return Ty::RustStruct(qname) };
            match lookup_ty_in_hierarchy(parent, top_level) {
                parent_ty @ Ty::RustEnum(_) => parent_ty,
                _ => Ty::RustStruct(qname),
            }
        }
        // Tuples carry per-element types; promote each element so that nested
        // variant-typed expressions (e.g. a reduction body of the form
        // `(DAE.ADD_ARR(...), {at,at}, at)`) infer with the parent enum in
        // every slot rather than the variant path.
        Ty::Tuple(elems) => Ty::Tuple(elems.into_iter().map(|t| promote_variant_to_enum_ty(t, top_level)).collect()),
        // Same for the element type of a list/array/option/range produced by
        // a constructor expression.
        Ty::List(inner) => Ty::List(Box::new(promote_variant_to_enum_ty(*inner, top_level))),
        Ty::Array(inner) => Ty::Array(Box::new(promote_variant_to_enum_ty(*inner, top_level))),
        Ty::Option(inner) => Ty::Option(Box::new(promote_variant_to_enum_ty(*inner, top_level))),
        Ty::Range(inner) => Ty::Range(Box::new(promote_variant_to_enum_ty(*inner, top_level))),
        other => other,
    }
}

/// Rewrite a dotted call name whose head segment is a local variable into a
/// type-qualified call. MetaModelica's `obj.member(args)` syntax desugars to
/// looking up `member` in the *type of `obj`* — i.e. for `cls : Class`, the
/// expression `cls.setSections(s, c)` denotes the function `Class.setSections`
/// applied to `(s, c)`. The user is responsible for passing `obj` explicitly
/// when required (no implicit self).
///
/// If `func`'s head segment names a local binding in `env` whose type carries
/// a qname (record / uniontype / type alias), and the resulting `<TyQname>.<tail>`
/// resolves to a real node in the hierarchy, return the rewritten name. Otherwise
/// return `None` and let the caller fall through to normal resolution.
///
/// This is only invoked for dotted names with at least one `.`; bare names cannot
/// be method-style calls.
fn rewrite_method_call_head<'a>(
    func: &str,
    env: &HashMap<String, Ty>,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
) -> Option<String> {
    let (head, tail) = func.split_once('.')?;
    let head_ty = env.get(head)?;
    let qname = match head_ty {
        Ty::RustStruct(n) | Ty::RustEnum(n) | Ty::Enumeration(n) | Ty::ExternalObject(n) => n.clone(),
        // `AliasTo(n)` is a single-record uniontype that aliases its sole record.
        // Use `n` (the record's qname) which carries the member functions.
        Ty::AliasTo(n) => n.clone(),
        // Generic instantiations: the package containing member functions is the
        // generic head, e.g. `ExpandableArray<Expression>` -> `ExpandableArray`.
        Ty::Generic(n, _) => n.clone(),
        // Variant of a multi-record uniontype: member functions live on the
        // parent uniontype.
        Ty::UnionTypeVariant(parent, _) => parent.clone(),
        _ => return None,
    };
    let candidate = format!("{qname}.{tail}");
    // Confirm the rewritten path resolves to a node in the hierarchy. If not,
    // fall back to letting normal resolution try its own path (named imports,
    // wildcard imports, type-alias-head walks, etc.) — the head might still
    // happen to be a package even though it shadows a local variable, though
    // this is unusual.
    resolve_call_node(&candidate, top_level, pkg_prefix).map(|(q, _)| q)
}

fn lookup_ty_in_hierarchy<'a>(dotted: &str, top_level: &'a BTreeMap<String, NameNode<'a>>) -> Ty {
    let mut parts = dotted.split('.');
    let first = parts.next().unwrap_or("");
    let Some(mut node) = top_level.get(first) else { return Ty::Unknown };
    for part in parts {
        let Some(child) = node.children.get(part) else { return Ty::Unknown };
        node = child;
    }
    node.ty.clone()
}

/// Like [`lookup_ty_in_hierarchy`], but recovers a record whose enclosing
/// uniontype shares its package's name. For `BackendDAE.DAE` the record `DAE`
/// lives inside the uniontype `BackendDAE` (itself in package `BackendDAE`), so
/// it is not a direct child of the package and the plain walk returns
/// `Unknown`. MetaModelica exports a uniontype's records into the enclosing
/// scope, so fall back to [`lookup_record_through_unions`]. Without this the
/// constructor is misclassified as a plain function call (positional call on a
/// named-field struct alias — E0423) and its pattern mis-binds the bare last
/// segment to a same-named top-level package, listing that package's members as
/// "fields" (E0574).
fn lookup_ctor_ty<'a>(dotted: &str, top_level: &'a BTreeMap<String, NameNode<'a>>) -> Ty {
    match lookup_ty_in_hierarchy(dotted, top_level) {
        Ty::Unknown => crate::hierarchy::lookup_record_through_unions(dotted, top_level)
            .map(|(_, n)| n.ty.clone())
            .unwrap_or(Ty::Unknown),
        other => other,
    }
}

/// Canonical fully-qualified qname for a constructor call. Uses the
/// import-aware [`resolve_call_node`] result when available, then falls back to
/// a record exported through an enclosing uniontype (see [`lookup_ctor_ty`]),
/// and finally to the source path. Keeps the downstream field/struct lookups
/// pointed at the real record rather than a same-named package.
fn canonical_ctor_qname<'a>(
    func: &str,
    resolved: &Option<(String, &NameNode<'a>)>,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
) -> String {
    resolved.as_ref().map(|(q, _)| q.clone())
        .or_else(|| crate::hierarchy::lookup_record_through_unions(func, top_level).map(|(q, _)| q))
        .unwrap_or_else(|| func.to_owned())
}

/// When a record constructor belongs to a generic uniontype (e.g. `record SLICE
/// T t; ... end SLICE;` inside `uniontype Slice<T>`), the constructor's static
/// type must carry the bound type arguments — otherwise downstream codegen
/// renders the bare, under-applied generic (`Slice::NBSlice`) and rustc rejects
/// it (E0107). Unify the record's declared field types against the actual
/// argument types to bind the parent uniontype's type parameters (in
/// declaration order), then build `Ty::Generic`. Returns `None` when the type
/// isn't generic or a parameter can't be pinned from the arguments — in which
/// case the caller keeps the un-parameterised base type (no behaviour change).
fn generic_constructor_ty<'a>(
    canonical: &str,
    base_ty: &Ty,
    args: &[TypedExp],
    named_args: &[(String, TypedExp)],
    field_names: &[String],
    top_level: &'a BTreeMap<String, NameNode<'a>>,
) -> Option<Ty> {
    // The type parameters live on the enclosing uniontype (or on the record
    // itself for a top-level generic record). Collect them in declaration order.
    let mut type_vars: Vec<String> = Vec::new();
    if let Some(node) = lookup_node(canonical, top_level)
        && let NodeKind::Class(c) = &node.kind {
        type_vars.extend(crate::hierarchy::class_type_vars(c));
    }
    if let Some((parent, _)) = canonical.rsplit_once('.')
        && let Some(pnode) = lookup_node(parent, top_level)
        && let NodeKind::Class(pc) = &pnode.kind {
        for v in crate::hierarchy::class_type_vars(pc) {
            if !type_vars.contains(&v) { type_vars.push(v); }
        }
    }
    if type_vars.is_empty() { return None; }
    let rust_name = ty_rust_name(base_ty).unwrap_or_else(|| canonical.replace('.', "::"));
    let decl_fields = record_field_tys(canonical, top_level);
    let mut subst: HashMap<String, Ty> = HashMap::new();
    // Positional args align with `field_names` (declaration order).
    for (i, arg) in args.iter().enumerate() {
        if let Some(fname) = field_names.get(i)
            && let Some((_, fty)) = decl_fields.iter().find(|(n, _)| n == fname) {
            unify_collect(fty, &arg.ty(), &type_vars, &mut subst);
        }
    }
    // Named args match by field name.
    for (n, v) in named_args {
        if let Some((_, fty)) = decl_fields.iter().find(|(fname, _)| fname == n) {
            unify_collect(fty, &v.ty(), &type_vars, &mut subst);
        }
    }
    let ty_args: Vec<Ty> = type_vars.iter()
        .map(|tv| subst.get(tv).cloned().unwrap_or(Ty::Unknown))
        .collect();
    // Only commit to a parameterised type when every parameter was pinned; an
    // `Unknown` arg would render as an invalid type. Falling back to the base
    // type preserves today's behaviour for the unpinnable case.
    if ty_args.iter().any(|t| matches!(t, Ty::Unknown)) { return None; }
    Some(Ty::Generic(rust_name, ty_args))
}

/// Extract the Rust-form (`::`-separated) name from a resolved nominal type,
/// matching `hierarchy::ty_rust_name`. Used when wrapping a user-defined
/// generic instantiation in `Ty::Generic` so that downstream `fmt_ty`
/// produces the correct path (including doubling for top-level uniontypes).
fn ty_rust_name(ty: &Ty) -> Option<String> {
    match ty {
        Ty::AliasTo(n) | Ty::RustEnum(n) | Ty::RustStruct(n) | Ty::Enumeration(n) => Some(n.replace('.', "::")),
        Ty::ExternalObject(n) => Some(n.replace('.', "::")),
        _ => None,
    }
}

/// Scope-aware type-name resolution for use by `typespec_to_ty`.
///
/// MetaModelica scopes name lookup from the inside out: a simple name inside
/// `package P` resolves to `P.X` (a sibling), to an `extends`-imported name,
/// or finally to a top-level package. Critically, when a uniontype `IOStream`
/// is declared inside `package IOStream`, the bare name `IOStream` inside that
/// package's bodies must resolve to the *uniontype*, not the package itself.
///
/// `resolve_call_node` would short-circuit on step 1 (direct top-level lookup)
/// and return the package node — whose `.ty` is `Ty::Unknown` for non-record
/// packages — so for type resolution we walk scopes first and only fall back
/// to the top level once nothing matches inside any enclosing scope.
fn resolve_type_name<'a>(
    name: &str,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
) -> Ty {
    // MetaModelica builtin types not declared in any source file. The hierarchy
    // seeds these into a separate `ScopedKnown` map and not into `top_level`,
    // so we resolve them here directly. Mirrors `seed_builtins` in hierarchy.rs.
    if name == "SourceInfo" { return Ty::RustStruct("SourceInfo".into()) }
    if !pkg_prefix.is_empty() {
        let mut parts: Vec<&str> = pkg_prefix.split('.').collect();
        loop {
            let prefixed = format!("{}.{name}", parts.join("."));
            let ty = lookup_ty_in_hierarchy(&prefixed, top_level);
            if !matches!(ty, Ty::Unknown) {
                return ty;
            }
            if parts.is_empty() {
                break;
            }
            parts.pop();
        }
    }
    // Fall back to `resolve_call_node` so that import-aliased and
    // wildcard-imported type names also resolve.
    resolve_call_node(name, top_level, pkg_prefix)
        .map(|(_, n)| n.ty.clone())
        .unwrap_or(Ty::Unknown)
}

/// Return the function signature for a MetaModelica built-in function used as a
/// first-class value (e.g. `valueEq` passed as a callback). Built-ins are not in
/// the hierarchy, so when a CREF resolves to `Ty::Unknown` we fall back here so
/// that codegen can treat the reference as a function pointer (no `.clone()`).
///
/// The signatures use `TypeVar("T")` as a stand-in for parameters whose actual
/// type is determined by the call site. The shape only needs to be `Ty::Function`
/// for codegen to skip the value clone; the inputs/output are informational —
/// EXCEPT for partial-application lowering (PARTEVALFUNCTION), which needs the
/// formal *names* to match what users write in `function f(name = value)`. So
/// where the MetaModelica builtin uses specific names (e.g. `realEq(x1, x2)`),
/// they are mirrored here.
pub fn builtin_function_ty(name: &str) -> Option<Ty> {
    let tv = |n: &str| Ty::TypeVar(n.to_owned());
    let inp = |name: &str, ty: Ty| FunctionInput { name: name.to_owned(), ty, default: None };
    let f = |inputs: Vec<FunctionInput>, output: Ty, type_vars: Vec<String>| -> Ty {
        Ty::Function { type_vars, inputs, output: Box::new(output), name: None }
    };
    match name {
        // Equality / comparison predicates: (T, T) -> Bool
        // Formal names mirror MetaModelicaBuiltin.mo exactly — they are used to
        // match named-arg partial applications (`function intLt(i2=...)`), so a
        // mismatch silently drops the binding and emits a `todo!()`.
        "valueEq" | "referenceEq" =>
            Some(f(vec![inp("a1", tv("T")), inp("a2", tv("T"))], Ty::Bool, vec!["T".to_owned()])),
        "intEq" | "intNe" | "intLt" | "intLe" | "intGt" | "intGe" =>
            Some(f(vec![inp("i1", Ty::I32), inp("i2", Ty::I32)], Ty::Bool, vec![])),
        "realEq" | "realLt" | "realLe" | "realGt" | "realGe" =>
            Some(f(vec![inp("x1", Ty::F64), inp("x2", Ty::F64)], Ty::Bool, vec![])),
        "stringEq" | "stringEqual" =>
            Some(f(vec![inp("s1", Ty::Str), inp("s2", Ty::Str)], Ty::Bool, vec![])),
        "boolEq" | "boolAnd" | "boolOr" =>
            Some(f(vec![inp("b1", Ty::Bool), inp("b2", Ty::Bool)], Ty::Bool, vec![])),
        "boolNot" =>
            Some(f(vec![inp("b", Ty::Bool)], Ty::Bool, vec![])),
        "isSome" | "isNone" =>
            Some(f(vec![inp("opt", Ty::Option(Box::new(tv("T"))))], Ty::Bool, vec!["T".to_owned()])),
        "listEmpty" =>
            Some(f(vec![inp("lst", Ty::List(Box::new(tv("T"))))], Ty::Bool, vec!["T".to_owned()])),
        // `listGet(list<T>, Integer) -> T`. Without this entry the result type
        // is `Ty::Unknown`, which then propagates into surrounding expressions
        // — most visibly into `+` chains where `binop_ty` can no longer route
        // `listGet(strs, i) + listGet(strs, j)` to the ArcStr concat path.
        "listGet" =>
            Some(f(vec![inp("lst", Ty::List(Box::new(tv("T")))), inp("index", Ty::I32)], tv("T"), vec!["T".to_owned()])),
        // `listHead`/`listFirst` (`list<T> -> T`) and `listRest`/`listTail`
        // (`list<T> -> list<T>`). Declared in MetaModelicaBuiltin.mo. These
        // names also occur as ordinary local variables (e.g. `List.mo`'s
        // `case listHead :: listRest`), but the bare-CREF promotion that
        // consults this registry is gated on the name *not* being a local
        // binding (see `infer_exp`'s CREF arm), so adding them here as proper
        // prelude functions only affects genuine function-pointer references
        // such as `List.map(lst, listHead)` — it never shadows a local. The
        // result type at call sites is still computed by `call_ty`, which peels
        // the element type from the concrete argument; the signature here is
        // what lets a bare reference lower to a function pointer and what
        // `builtin_formal_ty` reports as the call-argument formal (`list<T>`).
        "listHead" | "listFirst" =>
            Some(f(vec![inp("lst", Ty::List(Box::new(tv("T"))))], tv("T"), vec!["T".to_owned()])),
        "listRest" | "listTail" =>
            Some(f(vec![inp("lst", Ty::List(Box::new(tv("T"))))], Ty::List(Box::new(tv("T"))), vec!["T".to_owned()])),
        "arrayEmpty" =>
            Some(f(vec![inp("arr", Ty::Array(Box::new(tv("T"))))], Ty::Bool, vec!["T".to_owned()])),
        // `arrayGet(array<A>, Integer) -> A`. Needed so a partial application
        // `function arrayGet(arr = ...)` (common as a `List.map` mapper, e.g.
        // HpcOmMemory) resolves its signature and lowers to a real closure
        // rather than a `todo!()`. Formal names mirror MetaModelicaBuiltin.mo.
        "arrayGet" =>
            Some(f(vec![inp("arr", Ty::Array(Box::new(tv("A")))), inp("index", Ty::I32)], tv("A"), vec!["A".to_owned()])),

        // Length-style: container -> Integer
        "listLength" =>
            Some(f(vec![inp("lst", Ty::List(Box::new(tv("T"))))], Ty::I32, vec!["T".to_owned()])),
        "arrayLength" =>
            Some(f(vec![inp("arr", Ty::Array(Box::new(tv("T"))))], Ty::I32, vec!["T".to_owned()])),
        "stringLength" =>
            Some(f(vec![inp("str", Ty::Str)], Ty::I32, vec![])),
        // OpenModelica.Scripting.uriToFilename — see the cref_to_dotted
        // rewrite above. Signature mirrors the MM declaration in
        // NFModelicaBuiltin.mo: `(String) -> String`.
        "uriToFilename" =>
            Some(f(vec![inp("uri", Ty::Str)], Ty::Str, vec![])),
        // String hashing builtins: String -> Integer. Listed so that bare-CREF
        // references like `(stringHashDjb2, stringEq, ...)` passed to
        // `BaseHashSet::emptyHashSetWork` / `UnorderedMap::new` get wrapped by
        // `fnptr!(stringHashDjb2, ArcStr)` instead of falling through as a
        // value (which the surrounding `Hash<K> = fn(K) -> Result<i32>` slot
        // then rejects).
        "stringHash" | "stringHashDjb2" | "stringHashSdbm" =>
            Some(f(vec![inp("str", Ty::Str)], Ty::I32, vec![])),

        // Arithmetic: (T, T) -> T
        "intAdd" | "intSub" | "intMul" | "intDiv" | "intMod" | "intMax" | "intMin" =>
            Some(f(vec![inp("i1", Ty::I32), inp("i2", Ty::I32)], Ty::I32, vec![])),
        "realAdd" | "realSub" | "realMul" | "realDiv" | "realMax" | "realMin"
        | "realMod" | "realPow" =>
            Some(f(vec![inp("r1", Ty::F64), inp("r2", Ty::F64)], Ty::F64, vec![])),

        // Numeric coercions
        "intReal" =>
            Some(f(vec![inp("i", Ty::I32)], Ty::F64, vec![])),
        "realInt" =>
            Some(f(vec![inp("r", Ty::F64)], Ty::I32, vec![])),

        // String conversions/concat
        "intString" =>
            Some(f(vec![inp("i", Ty::I32)], Ty::Str, vec![])),
        "realString" =>
            Some(f(vec![inp("r", Ty::F64)], Ty::Str, vec![])),
        "boolString" =>
            Some(f(vec![inp("b", Ty::Bool)], Ty::Str, vec![])),
        "anyString" =>
            Some(f(vec![inp("a", tv("T"))], Ty::Str, vec!["T".to_owned()])),
        "stringAppend" =>
            Some(f(vec![inp("s1", Ty::Str), inp("s2", Ty::Str)], Ty::Str, vec![])),
        // `stringDelimitList(list<String>, String) -> String`. Declared in
        // MetaModelicaBuiltin.mo. Listing it here pins the result type so
        // that adjacent `+` chains in user code are typed as Ty::Str and
        // routed to the ArcStr concat path rather than the numeric `+`.
        "stringDelimitList" =>
            Some(f(vec![inp("strs", Ty::List(Box::new(Ty::Str))), inp("delimiter", Ty::Str)], Ty::Str, vec![])),
        "stringAppendList" =>
            Some(f(vec![inp("strs", Ty::List(Box::new(Ty::Str)))], Ty::Str, vec![])),
        // `getInstanceName()` — MetaModelicaBuiltin.mo. Lowered to a literal at
        // each call site by `emit_builtin_call` using the enclosing function's
        // qualified name (`GenCtx::current_fn_qname`). Listed here so the
        // result type is known for surrounding expression typing (e.g. it
        // becomes the lhs of a `+ literal!(...)` string concat).
        "getInstanceName" =>
            Some(f(vec![], Ty::Str, vec![])),
        // String → number/boolean parsing
        "stringInt" =>
            Some(f(vec![inp("str", Ty::Str)], Ty::I32, vec![])),
        "stringReal" =>
            Some(f(vec![inp("str", Ty::Str)], Ty::F64, vec![])),
        "stringBool" =>
            Some(f(vec![inp("str", Ty::Str)], Ty::Bool, vec![])),

        _ => None,
    }
}

fn binop_ty(op: BinOpKind, lhs_ty: &Ty, rhs_ty: &Ty) -> Ty {
    match op {
        // Division in MetaModelica/Modelica is *always* real division. The
        // built-in operator table (OperatorOverloading.mo) gives `/` a single
        // scalar overload `Real / Real -> Real`; Integer operands are coerced
        // to Real. Integer (truncating) division is a separate builtin
        // (`intDiv`/`div`), never the `/` operator. So a `Div` node is Real
        // regardless of operand types — emitting it as `i32 / i32` would
        // silently truncate. The matching codegen promotes both operands to
        // f64 (see emit_exp's BinOpKind::Div arm).
        BinOpKind::Div => Ty::F64,
        BinOpKind::Add | BinOpKind::Sub | BinOpKind::Mul => {
            match (lhs_ty, rhs_ty) {
                // String concatenation: in MetaModelica, `+` on String is the
                // only overload that doesn't require both sides to be numeric,
                // so a single Str side is enough to pin the result type.
                // Without this rule, a call whose return type we failed to
                // infer (Ty::Unknown) would propagate up the Add chain even
                // when the other operand is a literal! string, and emit_exp
                // would fall through to the numeric `+` codegen instead of
                // the ArcStr concat path. Only valid for Add — Sub/Mul on
                // strings don't exist in MetaModelica.
                _ if matches!(op, BinOpKind::Add) && (matches!(lhs_ty, Ty::Str) || matches!(rhs_ty, Ty::Str)) => Ty::Str,
                (Ty::F64, _) | (_, Ty::F64) => Ty::F64,
                (Ty::I32, _) | (_, Ty::I32) => Ty::I32,
                _ => lhs_ty.clone(),
            }
        }
        BinOpKind::Pow => Ty::F64,
        BinOpKind::And | BinOpKind::Or
        | BinOpKind::Eq | BinOpKind::NEq
        | BinOpKind::Lt | BinOpKind::LEq
        | BinOpKind::Gt | BinOpKind::GEq => Ty::Bool,
    }
}

fn call_ty(func: &str, args: &[TypedExp], top_level: &BTreeMap<String, NameNode<'_>>, pkg_prefix: &str) -> Ty {
    match func {
        "SOME" => Ty::Option(Box::new(args.first().map(|a| a.ty()).unwrap_or(Ty::Unknown))),
        "NONE" => Ty::Option(Box::new(Ty::Unknown)),
        "fail" => Ty::Unknown,
        "intAdd" | "intSub" | "intMul" | "intDiv" | "intMod" | "intAbs"
        | "intMax" | "intMin" | "intNeg" | "intBitAnd" | "intBitOr" | "intBitXor"
        | "intBitNot" | "intBitLShift" | "intBitRShift" | "intFromChar"
        | "stringLength" | "stringCompare" | "stringHash" | "stringHashDjb2"
        | "stringGet" | "stringInt" | "realInt"
        | "stringGetNoBoundsChecking" | "Dangerous.stringGetNoBoundsChecking" | "MetaModelica.Dangerous.stringGetNoBoundsChecking"
        | "arrayLength" | "listLength" => Ty::I32,
        "realAdd" | "realSub" | "realMul" | "realDiv" | "realAbs"
        | "realMax" | "realMin" | "realNeg" | "realFloor" | "realCeil"
        | "realMod" | "realPow" | "intReal" | "stringReal" => Ty::F64,
        // Source-level Modelica/MetaModelica math builtins (the bare names, as
        // opposed to the `realFloor`/`realAbs` runtime spellings above). The
        // emission side (`emit_builtin_call`) dispatches these by name with these
        // same arities, so we mirror their result types here. `floor`/`ceil`/
        // `sqrt` and the trig/exp/log family are Real -> Real. Without an entry
        // their result infers as `Ty::Unknown`, and an enclosing
        // `Integer + floor(..)` is then mistyped Integer by `binop_ty`'s
        // `(I32, _) => I32` arm — which makes a Real context (e.g. `step * (..)`)
        // wrap the whole subexpression in `OrderedFloat((.. ) as f64)`, producing
        // `1 + OrderedFloat<f64>` that fails to compile.
        "floor" | "ceil" | "sqrt"
        | "sin" | "cos" | "tan" | "asin" | "acos" | "atan"
        | "sinh" | "cosh" | "tanh" | "exp" | "log" | "log10"
            if args.len() == 1 => Ty::F64,
        "atan2" if args.len() == 2 => Ty::F64,
        // `integer(Real)` truncates toward -inf, yielding an Integer.
        "integer" if args.len() == 1 => Ty::I32,
        // `sign(v)` is `input Real v; output Integer` (ModelicaBuiltin.mo).
        "sign" if args.len() == 1 => Ty::I32,
        // Scalar 2-arg `max(a, b)` / `min(a, b)` (emitted as `std::cmp::max`/
        // `min`) return the common type of their operands. Inferring this lets a
        // surrounding real division widen the result correctly — e.g.
        // `(stopTime - startTime) / max(numberOfIntervals, 1)`, where
        // `numberOfIntervals` is a pattern binding typed `Unknown` but the `1`
        // literal pins the result to Integer. (The single-arg/array reduction
        // forms `max(e for ..)` are typed by the reduction path, not here.)
        "max" | "min" if args.len() == 2 => {
            let t0 = args[0].ty();
            let t1 = args[1].ty();
            match (&t0, &t1) {
                (Ty::F64, _) | (_, Ty::F64) => Ty::F64,
                (Ty::I32, _) | (_, Ty::I32) => Ty::I32,
                (Ty::Unknown, _) => t1,
                _ => t0,
            }
        }
        "stringBool" => Ty::Bool,
        "intString" | "realString" | "boolString" | "anyString"
        | "stringAppend" | "stringCharAt" | "stringGetStringChar" => Ty::Str,
        "stringEqual" | "stringEq" | "intEq" | "intLt" | "intLe" | "intGt" | "intGe"
        | "intNe" | "realEq" | "realLt" | "realLe" | "realGt" | "realGe"
        | "boolAnd" | "boolOr" | "boolNot" | "boolEq"
        | "referenceEq" | "valueEq" | "isEmpty" | "isSome" | "isNone"
        | "arrayEmpty" | "listEmpty" => Ty::Bool,
        "listHead" | "listFirst" | "listGet" => {
            match args.first().map(|a| a.ty()) {
                Some(Ty::List(inner)) => *inner,
                _ => Ty::Unknown,
            }
        }
        "listRest" | "listTail" | "listReverse" | "listAppend" | "listReverseInPlace" | "listAppendDestroy" => {
            args.first().map(|a| a.ty()).unwrap_or(Ty::Unknown)
        }
        // `arrayGet` yields the array's element type. `arrayGetNoBoundsChecking`
        // is the same observable type; it is *not* name-normalised (it lowers to
        // a real `metamodelica::Dangerous::arrayGetNoBoundsChecking` call), so
        // type its bare and `Dangerous.`/`MetaModelica.Dangerous.`-qualified
        // spellings here too — otherwise a result flowing into e.g. a `for`
        // loop's iterable would infer as `Unknown`.
        "arrayGet"
        | "arrayGetNoBoundsChecking" | "Dangerous.arrayGetNoBoundsChecking" | "MetaModelica.Dangerous.arrayGetNoBoundsChecking" => {
            match args.first().map(|a| a.ty()) {
                Some(Ty::Array(inner)) => *inner,
                _ => Ty::Unknown,
            }
        }
        "arrayUpdate" | "arrayCopy"
        | "arrayUpdateNoBoundsChecking" | "Dangerous.arrayUpdateNoBoundsChecking" | "MetaModelica.Dangerous.arrayUpdateNoBoundsChecking" => {
            args.first().map(|a| a.ty()).unwrap_or(Ty::Unknown)
        }
        "arrayCreate" => {
            Ty::Array(Box::new(args.get(1).map(|a| a.ty()).unwrap_or(Ty::Unknown)))
        }
        // arrayCreateNoInit(size, dummy): element type comes from the dummy
        // witness argument, same as arrayCreate. The dummy is dropped at
        // codegen time; here we still use it for type inference.
        "arrayCreateNoInit" => {
            Ty::Array(Box::new(args.get(1).map(|a| a.ty()).unwrap_or(Ty::Unknown)))
        }
        "listArray" => {
            match args.first().map(|a| a.ty()) {
                Some(Ty::List(inner)) => Ty::Array(inner),
                _ => Ty::Unknown,
            }
        }
        // MetaModelica builtin: `stringListStringChar(s)` → `List<String>` of one-char strings.
        // Declared in MetaModelicaBuiltin.mo (`output List<String> chars`); the metamodelica
        // runtime crate exposes it returning `Arc<List<ArcStr>>` to match the list convention.
        "stringListStringChar" => Ty::List(Box::new(Ty::Str)),
        // `listStringCharString` / `stringCharListString` invert that — list of one-char strings → String.
        "listStringCharString" | "stringCharListString" => Ty::Str,
        "arrayList" => {
            match args.first().map(|a| a.ty()) {
                Some(Ty::Array(inner)) => Ty::List(inner),
                _ => Ty::Unknown,
            }
        }
        _ => {
            // Resolve bare names against the current package scope so that calls
            // inside a module (e.g. `deleteMemberOnTrue` from inside `List.mo`)
            // find their canonical fully-qualified definition. Without this, the
            // hierarchy lookup would miss the function and return Ty::Unknown,
            // causing downstream Tuple-coercion logic to skip its tuple handling.
            let canonical = resolve_call_node(func, top_level, pkg_prefix)
                .map(|(q, _)| q)
                .unwrap_or_else(|| func.to_owned());
            match lookup_ty_in_hierarchy(&canonical, top_level) {
                Ty::Function { type_vars, inputs, output, .. } => {
                    // Unify the declared input types with the actual argument types
                    // so that any free type variables in the function signature get
                    // bound to concrete types from the call site. Without this step,
                    // calls like `Mutable.access<T>(mutable: Mutable<T>) -> T` invoked
                    // on a value of type `Mutable<list<X>>` would report their output
                    // as the raw `TypeVar("T")` instead of the concrete `list<X>`,
                    // breaking type-directed codegen (e.g. for-loop iterator handling,
                    // Arc-borrow decisions in pattern matching).
                    //
                    // The unification variables are every type-variable name that
                    // appears anywhere in the function's input or output types —
                    // not just `Ty::Function::type_vars`. Functions defined inside
                    // a generic class (e.g. `function access` inside `uniontype
                    // Mutable<T>`) inherit the enclosing class's type parameter
                    // without listing it in their own `type_vars` field.
                    let mut all_vars: Vec<String> = Vec::new();
                    for inp in inputs.iter() {
                        collect_type_vars_in_ty(&inp.ty, &mut all_vars);
                    }
                    collect_type_vars_in_ty(&output, &mut all_vars);
                    for v in &type_vars {
                        if !all_vars.contains(v) { all_vars.push(v.clone()); }
                    }
                    let mut subst: HashMap<String, Ty> = HashMap::new();
                    for (inp, arg) in inputs.iter().zip(args.iter()) {
                        unify_collect(&inp.ty, &arg.ty(), &all_vars, &mut subst);
                    }
                    apply_subst(&output, &subst)
                }
                other => other,
            }
        }
    }
}

/// Build a substitution map by structurally walking `sig` against `actual`.
/// Whenever `sig` is a `TypeVar` listed in `type_vars`, record the binding to
/// `actual` (first-binding wins; later inconsistent bindings are ignored — a
/// proper compiler pass would report the conflict, but for return-type
/// substitution alone any consistent witness suffices).
pub fn unify_collect(sig: &Ty, actual: &Ty, type_vars: &[String], subst: &mut HashMap<String, Ty>) {
    match (sig, actual) {
        (Ty::TypeVar(name), other) if type_vars.iter().any(|v| v == name) => {
            if !matches!(other, Ty::Unknown) {
                subst.entry(name.clone()).or_insert_with(|| other.clone());
            }
        }
        (Ty::Option(a), Ty::Option(b))
        | (Ty::List(a),   Ty::List(b))
        | (Ty::Array(a),  Ty::Array(b))
        | (Ty::Range(a),  Ty::Range(b)) => unify_collect(a, b, type_vars, subst),
        (Ty::Tuple(a), Ty::Tuple(b)) if a.len() == b.len() => {
            for (x, y) in a.iter().zip(b.iter()) {
                unify_collect(x, y, type_vars, subst);
            }
        }
        (Ty::Generic(na, aargs), Ty::Generic(nb, bargs))
            if na == nb && aargs.len() == bargs.len() =>
        {
            for (x, y) in aargs.iter().zip(bargs.iter()) {
                unify_collect(x, y, type_vars, subst);
            }
        }
        (Ty::Function { inputs: ai, output: ao, .. },
         Ty::Function { inputs: bi, output: bo, .. }) if ai.len() == bi.len() => {
            for (x, y) in ai.iter().zip(bi.iter()) {
                unify_collect(&x.ty, &y.ty, type_vars, subst);
            }
            unify_collect(ao, bo, type_vars, subst);
        }
        _ => {}
    }
}

/// Apply a type-variable substitution to a type, recursively.
pub fn apply_subst(ty: &Ty, subst: &HashMap<String, Ty>) -> Ty {
    if subst.is_empty() { return ty.clone(); }
    match ty {
        Ty::TypeVar(name) => subst.get(name).cloned().unwrap_or_else(|| ty.clone()),
        Ty::Option(inner) => Ty::Option(Box::new(apply_subst(inner, subst))),
        Ty::List(inner)   => Ty::List(Box::new(apply_subst(inner, subst))),
        Ty::Array(inner)  => Ty::Array(Box::new(apply_subst(inner, subst))),
        Ty::Range(inner)  => Ty::Range(Box::new(apply_subst(inner, subst))),
        Ty::Tuple(tys)    => Ty::Tuple(tys.iter().map(|t| apply_subst(t, subst)).collect()),
        Ty::Generic(name, args) =>
            Ty::Generic(name.clone(), args.iter().map(|t| apply_subst(t, subst)).collect()),
        Ty::Function { type_vars, inputs, output, name } => Ty::Function {
            type_vars: type_vars.clone(),
            inputs: inputs.iter()
                .map(|inp| FunctionInput { name: inp.name.clone(), ty: apply_subst(&inp.ty, subst), default: inp.default.clone() })
                .collect(),
            output: Box::new(apply_subst(output, subst)),
            name: name.clone(),
        },
        _ => ty.clone(),
    }
}

/// For a dotted name like `exarray.lastUsedIndex`, resolve the first segment in the
/// env to get its type, then walk through remaining segments as field accesses to get
/// the final field type. Returns `None` if the first segment isn't in env.
fn resolve_first_segment_type<'a>(
    dotted: &str,
    segments: &[CrefSegment],
    env: &HashMap<String, Ty>,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
) -> Option<Ty> {
    let first_name = segments.first().map(|s| s.name.as_str()).unwrap_or(dotted);
    let mut ty = env.get(first_name)?.clone();

    // Apply subscripts on the first segment. Each scalar subscript peels off one
    // outer Array/List layer (e.g. `arr[i]` on an `Array<T>` yields `T`). Without
    // this, a reduction over `arr[i]` would type its body as `Array<T>` and the
    // accumulator declaration would be `List<Array<T>>` instead of `List<T>`.
    if let Some(seg) = segments.first() {
        for _ in &seg.subscripts {
            ty = match ty {
                Ty::Array(inner) | Ty::List(inner) => *inner,
                other => other,
            };
        }
    }

    // Walk remaining segments as field accesses to narrow the type, applying
    // each segment's subscripts the same way.
    //
    // Both plain structs (`Ty::RustStruct`) and generic instantiations
    // (`Ty::Generic` of a user-defined struct/uniontype) support field access.
    // For the generic case we look up the underlying type's field declarations
    // and apply the instantiation's type-argument substitution so that fields
    // are reported in the caller's instantiation rather than in the parameter
    // form. Without this, `delst.front` where `delst: MutableList<X>` would
    // return the parameter form `Ty::TypeVar("T")`/`Mutable<list<T>>` and
    // downstream type-directed codegen would fail (e.g. function-call
    // type-variable unification cannot tell what concrete type a `Mutable<...>`
    // wraps without it).
    for seg in segments.iter().skip(1) {
        let field_ty: Option<Ty> = match &ty {
            // Plain record / single-record uniontype rendered as a struct.
            // `record_field_tys` transparently handles the single-record uniontype
            // case by walking through to the sole record child.
            Ty::RustStruct(qname) | Ty::AliasTo(qname) => {
                let field_tys = record_field_tys(qname, top_level);
                field_tys.iter().find(|(n, _)| n == &seg.name).map(|(_, t)| t.clone())
            }
            // Multi-record uniontype rendered as a Rust enum. Field access on an
            // enum value is only legal in MetaModelica when the field exists in
            // the matched record-variant. When `infer_case` has narrowed the
            // scrutinee variable to a specific variant we'll see
            // `Ty::UnionTypeVariant` below — that's the precise path. The
            // fallback here (`Ty::RustEnum` without narrowing) walks all record
            // variants and returns the *first* hit; this is only correct when
            // the field has the same type in every variant (most uniontypes,
            // e.g. SourceInfo) but is wrong for cases like JSON where `values`
            // has different types per variant. Such expressions must rely on
            // the variant being narrowed by an enclosing case pattern.
            Ty::RustEnum(qname) => uniontype_variant_field_ty(qname, &seg.name, top_level),
            // Narrowed by pattern matching to a specific record variant: look
            // up the field directly on that record (with the union's type
            // parameters substituted in, mirroring the `Ty::Generic` arm).
            Ty::UnionTypeVariant(union_qname, variant_name) => {
                let variant_qname = format!("{union_qname}.{variant_name}");
                let field_tys = record_field_tys(&variant_qname, top_level);
                field_tys.iter().find(|(n, _)| n == &seg.name).map(|(_, t)| t.clone())
            }
            Ty::Generic(rust_name, args) => {
                // `rust_name` uses `::` separators; the hierarchy is dotted.
                let dotted = rust_name.replace("::", ".");
                let formal = class_type_param_names(&dotted, top_level);
                let mut subst: HashMap<String, Ty> = HashMap::new();
                for (name, actual) in formal.iter().zip(args.iter()) {
                    subst.insert(name.clone(), actual.clone());
                }
                let field_tys = record_field_tys(&dotted, top_level);
                field_tys.iter().find(|(n, _)| n == &seg.name).map(|(_, t)| apply_subst(t, &subst))
            }
            _ => None,
        };
        match field_ty {
            Some(t) => ty = t,
            None => break,
        }
        for _ in &seg.subscripts {
            ty = match ty {
                Ty::Array(inner) | Ty::List(inner) => *inner,
                other => other,
            };
        }
    }

    Some(ty)
}

/// If `pat` fixes the scrutinee to a specific record-variant of the scrutinee
/// uniontype, return the narrowed `Ty::UnionTypeVariant`. Otherwise `None`.
///
/// Used to narrow the scrutinee variable's type inside a `case CTOR(...)` arm
/// so that field-type resolution picks fields from the *matched* record rather
/// than walking every variant of the uniontype. Walks `As`-wrappers since the
/// outer `var as PAT` does not change which variant `PAT` matches.
fn narrow_scrutinee_for_pat<'a>(
    pat: &TypedPat,
    scrut_ty: &Ty,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
) -> Option<Ty> {
    let ctor_name = match pat {
        TypedPat::Constructor { name, .. } => name.as_str(),
        TypedPat::As { pat, .. } => return narrow_scrutinee_for_pat(pat, scrut_ty, top_level),
        _ => return None,
    };
    // Use the simple (last) name segment since constructor patterns in
    // MetaModelica are written with the bare record name (e.g. `LIST_OBJECT()`).
    let simple = ctor_name.rsplit('.').next().unwrap_or(ctor_name);
    let union_qname = match scrut_ty {
        Ty::RustEnum(q) => q,
        _ => return None,
    };
    let node = lookup_node(union_qname, top_level)?;
    if node.children.contains_key(simple) {
        Some(Ty::UnionTypeVariant(union_qname.clone(), simple.to_string()))
    } else {
        None
    }
}

/// Look up a field on a multi-record uniontype by searching each record-variant.
///
/// Use case: in a match arm like `case Flags.ENUM_FLAG() then ... flag.validValues ...`,
/// the bound `flag` is typed as the uniontype (`Ty::RustEnum`) — narrowing isn't
/// tracked at the type level. To resolve `flag.validValues` we walk the
/// uniontype's record children and pick the first record that declares the
/// field. MetaModelica enforces that fields with the same name across variants
/// share a type, so the first hit is authoritative.
///
/// Returns `None` if `qname` doesn't name a uniontype or none of its records
/// declare a field with this name.
fn uniontype_variant_field_ty<'a>(
    qname: &str,
    field: &str,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
) -> Option<Ty> {
    let node = lookup_node(qname, top_level)?;
    let NodeKind::Class(c) = &node.kind else { return None };
    if !matches!(c.restriction, Absyn::Restriction::R_UNIONTYPE) {
        return None;
    }
    for child in node.children.values() {
        let NodeKind::Class(rc) = &child.kind else { continue };
        if !matches!(rc.restriction, Absyn::Restriction::R_RECORD | Absyn::Restriction::R_METARECORD { .. }) {
            continue;
        }
        let rec_members: &[MM::ClassMember] = match &rc.body {
            MM::ClassDef::Parts { members, .. } | MM::ClassDef::ClassExtends { members, .. } => members,
            _ => continue,
        };
        for m in rec_members {
            let MM::ClassMember::Component(cm) = m else { continue };
            if cm.name == field
                && let Some(comp_node) = child.children.get(&cm.name) {
                    return Some(comp_node.ty.clone());
                }
        }
    }
    None
}

fn record_field_tys<'a>(
    qname: &str,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
) -> Vec<(String, Ty)> {
    // Try the direct path first; fall back to looking through uniontype parents.
    let node = lookup_node(qname, top_level)
        .or_else(|| lookup_record_through_unions(qname, top_level).map(|(_, n)| n));
    let Some(node) = node else { return vec![] };
    let NodeKind::Class(c) = &node.kind else { return vec![] };
    let members: &[MM::ClassMember] = match &c.body {
        MM::ClassDef::Parts { members, .. } | MM::ClassDef::ClassExtends { members, .. } => members,
        _ => return vec![],
    };
    // Single-record uniontype: hierarchy seeding emits the record under the
    // uniontype's own qname (no separate record struct + alias), so direct
    // field lookup on the uniontype node finds no components — the components
    // live on the sole record child. A uniontype's *own* component members
    // (e.g. a `constant Matching EMPTY_MATCHING = ...`) are NOT record fields,
    // so handle the uniontype case before collecting them.
    if matches!(c.restriction, Absyn::Restriction::R_UNIONTYPE) {
        let record_children: Vec<&NameNode> = node.children.values()
            .filter(|child| matches!(&child.kind, NodeKind::Class(cc)
                if matches!(cc.restriction, Absyn::Restriction::R_RECORD | Absyn::Restriction::R_METARECORD { .. })))
            .collect();
        if record_children.len() == 1 {
            let rec_node = record_children[0];
            if let NodeKind::Class(rc) = &rec_node.kind {
                let rec_members: &[MM::ClassMember] = match &rc.body {
                    MM::ClassDef::Parts { members, .. } | MM::ClassDef::ClassExtends { members, .. } => members,
                    _ => return vec![],
                };
                return rec_members.iter().filter_map(|m| {
                    let MM::ClassMember::Component(cm) = m else { return None };
                    let child = rec_node.children.get(&cm.name)?;
                    Some((cm.name.clone(), child.ty.clone()))
                }).collect();
            }
        }
        // Multi-record uniontype has no flat field list.
        return vec![];
    }
    members.iter().filter_map(|m| {
        let MM::ClassMember::Component(cm) = m else { return None };
        let child = node.children.get(&cm.name)?;
        Some((cm.name.clone(), child.ty.clone()))
    }).collect()
}

/// Return the formal type-parameter names declared on a user-defined class
/// (uniontype or record) identified by `qname`. For a uniontype like
/// `uniontype Mutable<T> ... end Mutable;` the result is `["T"]`. Used to
/// substitute a generic instantiation's type arguments into the parameter
/// form of its field declarations when walking field accesses.
fn class_type_param_names<'a>(
    qname: &str,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
) -> Vec<String> {
    let node = lookup_node(qname, top_level)
        .or_else(|| lookup_record_through_unions(qname, top_level).map(|(_, n)| n));
    let Some(node) = node else { return vec![] };
    let NodeKind::Class(c) = &node.kind else { return vec![] };
    match &c.body {
        MM::ClassDef::Parts { type_vars, .. } => type_vars.clone(),
        _ => vec![],
    }
}

fn lookup_node<'a>(
    dotted: &str,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
) -> Option<&'a NameNode<'a>> {
    let mut parts = dotted.split('.');
    let first = parts.next().unwrap_or("");
    let mut node = top_level.get(first)?;
    for part in parts {
        let child = node.children.get(part)?;
        node = child;
    }
    Some(node)
}

/// Infer the type of a MetaModelica expression, building a typed expression tree.
/// `env` maps local variable names to their resolved types.
/// `type_vars` is the list of type-variable names in scope for the enclosing function
/// (e.g. `["Key"]` for a function with `replaceable type Key subtypeof Any`).
/// These are needed to resolve local variable type annotations that reference type params.
pub fn infer_exp<'a>(
    exp: &Absyn::Exp,
    env: &HashMap<String, Ty>,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
    type_vars: &[String],
) -> TypedExp {
    match exp {
        Absyn::Exp::INTEGER { value } => TypedExp::Lit(Lit::Int(*value)),
        Absyn::Exp::REAL    { value } => TypedExp::Lit(Lit::Real(value.to_string())),
        Absyn::Exp::STRING  { value } => TypedExp::Lit(Lit::Str(value.to_string())),
        Absyn::Exp::BOOL    { value } => TypedExp::Lit(Lit::Bool(*value)),

        Absyn::Exp::CREF { componentRef } => {
            let (name, segments) = extract_cref_segments(componentRef, env, top_level, pkg_prefix);
            // Local env takes priority; fall back to hierarchy, then try qualifying
            // the bare name with the enclosing package prefix (for sibling references).
            // For dotted names like `exarray.lastUsedIndex`, the env key is just
            // the first segment. If it resolves to a record type and the remaining
            // segments are field accesses, use the record's field types.
            let ty = resolve_first_segment_type(&name, &segments, env, top_level).unwrap_or_else(|| {
                // Dotted name with no local-variable shadow: prefer the
                // full-path hierarchy lookup. This correctly types references
                // to imported functions like `SBInterval.isEmpty` as
                // `Ty::Function` so they round-trip through the call-site
                // `fnptr!` wrapping. Without this we'd resolve the leading
                // segment (a uniontype/package) and stop, dropping the
                // function's type entirely.
                if name.contains('.') {
                    // Use scope-aware resolution so a name like
                    // `Expression.isArray` inside `NFSimplifyExp` (which
                    // declares `import Expression = NFExpression;`) types as
                    // the NFExpression version — not the unrelated top-level
                    // `Expression` package whose `isArray` takes `DAE.Exp`.
                    // Falling back to a bare top-level `lookup_ty_in_hierarchy`
                    // would silently produce the wrong function signature for
                    // `fnptr!` wrapping at call sites.
                    if let Some((qname, _)) = resolve_call_node(&name, top_level, pkg_prefix) {
                        let resolved = lookup_ty_in_hierarchy(&qname, top_level);
                        if !matches!(resolved, Ty::Unknown) {
                            return resolved;
                        }
                    }
                    let full = lookup_ty_in_hierarchy(&name, top_level);
                    if !matches!(full, Ty::Unknown) {
                        return full;
                    }
                }
                let first = segments.first().map(|s| s.name.as_str()).unwrap_or(&name);
                let ty = lookup_ty_in_hierarchy(first, top_level);
                if ty == Ty::Unknown && !pkg_prefix.is_empty() && !name.contains('.') {
                    // Walk up enclosing scopes so that bare references to siblings
                    // (e.g. a module-level `constant list<...> allConfigFlags` referenced
                    // from inside `FlagsUtil.checkConfigFlags`) resolve, not just direct
                    // children of the innermost scope. Mirrors `resolve_type_name`.
                    let mut parts: Vec<&str> = pkg_prefix.split('.').collect();
                    loop {
                        let prefixed = if parts.is_empty() {
                            name.clone()
                        } else {
                            format!("{}.{name}", parts.join("."))
                        };
                        let t = lookup_ty_in_hierarchy(&prefixed, top_level);
                        if !matches!(t, Ty::Unknown) { break t; }
                        if parts.is_empty() { break Ty::Unknown; }
                        parts.pop();
                    }
                } else {
                    ty
                }
            });
            // If the reference still resolves to Unknown and the name matches a known
            // built-in function (not in the hierarchy), treat it as a function pointer
            // so callers can pass it without `.clone()`.
            //
            // Crucially, only promote a name that is *not* a local binding. The
            // builtin registry acts as a prelude scope, and proper lexical
            // scoping means a local variable shadows a prelude function of the
            // same name. Several builtins double as common local names — e.g.
            // `List.mo`'s `insertListSorted1` declares `T listHead; list<T>
            // listRest;` and matches `case listHead :: listRest`. If such a
            // local's type fails to infer (it lands in `env` as `Ty::Unknown`,
            // e.g. when the matched value comes from a generic call), promoting
            // it to the `listHead` builtin signature would make codegen treat
            // `listHead :: inResultList` as consing a *function pointer*. The
            // `env.contains_key` guard keeps the prelude lookup from ever
            // overriding an in-scope binding. (A name used genuinely as a
            // builtin function pointer — `List.map(lst, listHead)` — is not a
            // local, so it is absent from `env` and still promotes.)
            let ty = if ty == Ty::Unknown && segments.len() == 1 && !name.contains('.')
                && !env.contains_key(&name)
            {
                builtin_function_ty(&name).unwrap_or(Ty::Unknown)
            } else {
                ty
            };
            TypedExp::Var { name, segments, ty, last_use: false }
        }

        Absyn::Exp::BINARY  { exp1, op, exp2 }
        | Absyn::Exp::LBINARY  { exp1, op, exp2 }
        | Absyn::Exp::RELATION { exp1, op, exp2 } => {
            let lhs = infer_exp(exp1, env, top_level, pkg_prefix, type_vars);
            let rhs = infer_exp(exp2, env, top_level, pkg_prefix, type_vars);
            let bin_op = absyn_op_to_binop(op);
            let ty = binop_ty(bin_op, &lhs.ty(), &rhs.ty());
            TypedExp::BinOp { op: bin_op, lhs: Box::new(lhs), rhs: Box::new(rhs), ty }
        }

        Absyn::Exp::UNARY { op, exp } => {
            let operand = infer_exp(exp, env, top_level, pkg_prefix, type_vars);
            match op {
                Absyn::Operator::NOT => {
                    // Fold `!true` → `Lit(false)`, `!false` → `Lit(true)`.
                    if let TypedExp::Lit(Lit::Bool(v)) = &operand {
                        TypedExp::Lit(Lit::Bool(!v))
                    } else {
                        TypedExp::UnOp { op: UnOpKind::Not, operand: Box::new(operand), ty: Ty::Bool }
                    }
                }
                _ => {
                    // Fold `-1` → `Lit(Int(-1))`, `-"3.14"` → `Lit(Real("-3.14"))`.
                    match &operand {
                        TypedExp::Lit(Lit::Int(v)) => TypedExp::Lit(Lit::Int(-v)),
                        TypedExp::Lit(Lit::Real(v)) => TypedExp::Lit(Lit::Real(format!("-{v}"))),
                        _ => {
                            let ty = operand.ty();
                            TypedExp::UnOp { op: UnOpKind::Neg, operand: Box::new(operand), ty }
                        }
                    }
                }
            }
        }

        Absyn::Exp::LUNARY { exp, .. } => {
            let operand = infer_exp(exp, env, top_level, pkg_prefix, type_vars);
            // Fold `not true` → `Lit(false)`, `not false` → `Lit(true)`.
            if let TypedExp::Lit(Lit::Bool(v)) = &operand {
                TypedExp::Lit(Lit::Bool(!v))
            } else {
                TypedExp::UnOp { op: UnOpKind::Not, operand: Box::new(operand), ty: Ty::Bool }
            }
        }

        Absyn::Exp::IFEXP { ifExp, trueBranch, elseBranch, elseIfBranch } => {
            let cond  = infer_exp(ifExp, env, top_level, pkg_prefix, type_vars);
            let then_ = infer_exp(trueBranch, env, top_level, pkg_prefix, type_vars);
            let else_ = infer_exp(elseBranch, env, top_level, pkg_prefix, type_vars);
            let elseif: Vec<(TypedExp, TypedExp)> = (&**elseIfBranch).into_iter()
                .map(|(c, b)| (infer_exp(c.as_ref(), env, top_level, pkg_prefix, type_vars), infer_exp(b.as_ref(), env, top_level, pkg_prefix, type_vars)))
                .collect();
            // Branch-type unification with MetaModelica's implicit first-output
            // coercion: when one branch is a multi-output call (`Ty::Tuple`) and
            // the other is a scalar (non-tuple) value, the tuple branch yields
            // only its first output so both branches share the scalar type (e.g.
            // `systs := if b then partitionIndependentBlocksSplitBlocks(..) else
            // {syst}`, whose `then` returns a 3-tuple but `else` is a single
            // list). Codegen applies the `.0` to the tuple branch; the
            // expression's static type must then be the scalar branch's type so
            // a single-variable assignment doesn't mis-expand its LHS into a
            // tuple destructure (E0308). Otherwise keep the then-branch type
            // (falling back to else when then is unknown).
            let ty = match (then_.ty(), else_.ty()) {
                (Ty::Tuple(_), other) if !matches!(other, Ty::Tuple(_) | Ty::Unknown) => other,
                (other, Ty::Tuple(_)) if !matches!(other, Ty::Tuple(_) | Ty::Unknown) => other,
                _ => if then_.ty() != Ty::Unknown { then_.ty() } else { else_.ty() },
            };
            TypedExp::If { cond: Box::new(cond), then_: Box::new(then_), elseif, else_: Box::new(else_), ty }
        }

        Absyn::Exp::CALL { function_, functionArgs, .. } => {
            let mut func = cref_to_dotted(function_);
            // Method-style call rewriting: `obj.member(args)` where `obj` is a
            // local variable means "call `member` on the type of `obj`". The
            // head segment of `func` is the variable name, but MetaModelica
            // resolves the member through the variable's *type*. Rewrite the
            // head to the type's qname so downstream call resolution finds
            // the function. Only applied when the rewritten path resolves;
            // otherwise we leave the original form for normal resolution.
            if func.contains('.')
                && let Some(rewritten) = rewrite_method_call_head(&func, env, top_level, pkg_prefix)
            {
                func = rewritten;
            }
            // Detect reduction syntax `f(expr for it in range, ...)` and lower it
            // into a dedicated TypedExp::Reduction node rather than a Call with
            // missing arguments.
            if let Absyn::FunctionArgs::FOR_ITER_FARG { exp: body_exp, iterType, iterators } = &**functionArgs {
                let iter_kind = match iterType {
                    Absyn::ReductionIterType::COMBINE => ReductionIterKind::Combine,
                    Absyn::ReductionIterType::THREAD  => ReductionIterKind::Thread,
                };
                // Build iterators left-to-right; each iterator binds a name visible
                // to subsequent iterator ranges and the body. We thread `env` so
                // later iterators / body see those bindings.
                let mut iter_env = env.clone();
                let mut iters: Vec<ReductionIter> = Vec::new();
                for it in (&**iterators).into_iter() {
                    let Absyn::ForIterator { name: it_name, guardExp, range } = &**it;
                    let range_e = match range {
                        Some(r) => infer_exp(r.as_ref(), &iter_env, top_level, pkg_prefix, type_vars),
                        // A reduction iterator without an explicit range is the implicit-array
                        // form (Modelica spec §3.4.4.2); not yet supported in the lowering.
                        None => TypedExp::Todo("reduction-iter-without-range".to_owned()),
                    };
                    let elem_ty = match range_e.ty() {
                        Ty::List(t) | Ty::Array(t) | Ty::Range(t) => *t,
                        _ => Ty::Unknown,
                    };
                    iter_env.insert(it_name.to_string(), elem_ty.clone());
                    let guard = guardExp.as_ref().map(|g| infer_exp(g.as_ref(), &iter_env, top_level, pkg_prefix, type_vars));
                    iters.push(ReductionIter { name: it_name.to_string(), range: range_e, guard, elem_ty });
                }
                let body = infer_exp(body_exp.as_ref(), &iter_env, top_level, pkg_prefix, type_vars);
                // The reduction's result type depends on `func`:
                //  - list / listReverse / listAppend → list<body_ty>
                //  - min / max → body_ty itself
                //  - sum / product → body_ty (numeric)
                //  - user function → the function's output type
                // When the body is a constructor for a multi-record uniontype
                // variant, `body.ty()` is `Ty::RustStruct(<variant-qname>)`. As
                // an *expression* type that's not a Rust type — `Mod::Enum::Var`
                // is a variant path, not a struct. Promote it to the parent
                // `Ty::RustEnum` so that `list(...)` infers as `List<Enum>`,
                // which `fmt_ty` renders as a valid Rust type.
                let raw_body_ty = promote_variant_to_enum_ty(body.ty(), top_level);
                // MetaModelica implicit "first-output" coercion: when the body is
                // a call to a multi-output function but the reduction (and the
                // surrounding assignment) expects a single value, the secondary
                // outputs are dropped. We model that by collapsing a Call's
                // tuple result type to its first element here, so the reduction's
                // overall type infers as `list<T>` (not `list<(T, ...)>`) — and
                // codegen later appends `.0` to the body expression.
                //
                // Only Call/Constructor with a tuple-typed result is collapsed —
                // an explicit `(a, b)` tuple body keeps its type so users can
                // still build `list<tuple<...>>` when intended.
                let body_ty = match (&body, &raw_body_ty) {
                    (TypedExp::Call { func, .. }, Ty::Tuple(ts))
                        if !ts.is_empty() && function_has_multiple_outputs(func, top_level, pkg_prefix)
                        => ts[0].clone(),
                    _ => raw_body_ty,
                };
                // Per-level reduction result type. `list`/`listReverse` lift the
                // collected type by one list level; the scalar folds and
                // `listAppend` keep it; a user-defined reduction yields its
                // function output type.
                let reduction_result_ty = |func: &str, inner: &Ty| -> Ty {
                    match func {
                        "list" | "listReverse" => Ty::List(Box::new(inner.clone())),
                        "listAppend" => inner.clone(),
                        "sum" | "product" | "min" | "max" => inner.clone(),
                        _ => match lookup_ty_in_hierarchy(func, top_level) {
                            Ty::Function { output, .. } => *output,
                            _ => Ty::Unknown,
                        },
                    }
                };
                // A multi-iterator COMBINE reduction desugars to NESTED
                // single-iterator reductions. OMC's own frontend requires this
                // rewrite (Static.elabCallReduction errors on multi-iterator
                // COMBINE, advising e.g. `array(i+j for i, j) =>
                // array(array(i+j for i) for j)`), and `Static.reductionType`
                // lifts the result type one list level per iterator
                // (`List.foldr(dims, Types.liftList, ty)`), so `list(e for a, b)`
                // has type `list<list<...>>`. The compiled C confirms the LAST
                // iterator's loop is OUTERMOST and one list level nests per
                // iterator. Building the nesting here makes both the inferred
                // type and the emitted accumulators correct, because every level
                // is an ordinary single-iterator reduction the rest of the
                // lowering already handles. (THREAD reductions zip their
                // iterators into one loop and are left as a single node.)
                if matches!(iter_kind, ReductionIterKind::Combine) && iters.len() > 1 {
                    let mut acc_exp = body;
                    let mut acc_ty = body_ty;
                    // iters[0] becomes the innermost reduction, iters[last] the
                    // outermost — matching the last-iterator-outermost nesting.
                    for it in iters {
                        let lvl_ty = reduction_result_ty(&func, &acc_ty);
                        acc_exp = TypedExp::Reduction {
                            func: func.clone(),
                            body: Box::new(acc_exp),
                            iterators: vec![it],
                            iter_kind: ReductionIterKind::Combine,
                            ty: lvl_ty.clone(),
                        };
                        acc_ty = lvl_ty;
                    }
                    return acc_exp;
                }
                let ty = reduction_result_ty(&func, &body_ty);
                return TypedExp::Reduction {
                    func,
                    body: Box::new(body),
                    iterators: iters,
                    iter_kind,
                    ty,
                };
            }
            let (args, named_args) = extract_call_args(functionArgs, env, top_level, pkg_prefix, type_vars);
            let sig_ty = lookup_ctor_ty(&func, top_level);
            // Resolve the call node using import-aware lookup so that dotted names whose
            // first segment is an import alias (e.g. `LookupTree.Tree.EMPTY` where
            // `import LookupTree = NFLookupTree`) and names relative to the current
            // package (e.g. bare `LEAF` or dotted `Tree.EMPTY` inside `AvlSetInt`) all
            // resolve to their canonical fully-qualified path.
            let resolved: Option<(String, &NameNode)> = resolve_call_node(&func, top_level, pkg_prefix);
            let is_constructor = match &sig_ty {
                Ty::RustStruct(_) | Ty::RustEnum(_) => true,
                _ => {
                    if let Some((_, node)) = &resolved {
                        matches!(node.kind, NodeKind::Class(c) if matches!(c.restriction, Absyn::Restriction::R_RECORD | Absyn::Restriction::R_UNIONTYPE))
                    } else {
                        false
                    }
                }
            };
            if is_constructor {
                // Use the canonical (fully-qualified) name so downstream codegen can
                // look up fields, even when the call site used a shorter path.
                let canonical = canonical_ctor_qname(&func, &resolved, top_level);
                let ty = match lookup_ty_in_hierarchy(&canonical, top_level) {
                    Ty::Function { output, .. } => *output,
                    other => other,
                };
                // Tag unit-variant constructors with their parent enum so the
                // expression's static type names a real Rust type (`Ty::RustEnum`
                // via `fmt_ty`'s `UnionTypeVariant` arm) rather than `()`.
                // `lookup_ty_in_hierarchy` returns the raw `RustUnitVariant`
                // (no parent qname); recover the parent from the constructor's
                // own canonical path. Codegen at the constructor emit site
                // still uses the `name` field to spell `Parent::Variant`, so
                // this only changes the static type of the value expression.
                let ty = match ty {
                    Ty::RustUnitVariant => {
                        if let Some((parent, variant)) = canonical.rsplit_once('.')
                            && matches!(lookup_ty_in_hierarchy(parent, top_level), Ty::RustEnum(_))
                        {
                            Ty::UnionTypeVariant(parent.to_string(), variant.to_string())
                        } else {
                            Ty::RustUnitVariant
                        }
                    }
                    other => other,
                };
                let field_names: Vec<String> = match &sig_ty {
                    Ty::RustStruct(qname) | Ty::RustEnum(qname) => {
                        record_field_tys(qname, top_level).into_iter().map(|(n, _)| n).collect()
                    }
                    _ => {
                        record_field_tys(&canonical, top_level).into_iter().map(|(n, _)| n).collect()
                    }
                };
                // Bind the parent uniontype's type parameters from the actual
                // arguments so a generic record (`Slice<T>`) keeps its type
                // argument in the value's static type (see `generic_constructor_ty`).
                let ty = generic_constructor_ty(&canonical, &ty, &args, &named_args, &field_names, top_level)
                    .unwrap_or(ty);
                TypedExp::Constructor { name: canonical, args, named_args, ty, field_names }
            } else {
                // A call whose callee is a function-typed LOCAL variable — e.g.
                // a `partial function` parameter `fun` invoked as `fun()`, as in
                // `Types.getMetaRecordFields`'s `DAE.T_METARECORD(..) := fun();`.
                // `call_ty` only consults the hierarchy, so it returns `Unknown`
                // for a local; resolve the result type from the variable's
                // declared function type in `env` instead. Without this the
                // scrutinee of a downstream pattern-let infers as `Unknown` and
                // the `match_deref!` Arc-peeling for a recursive uniontype
                // pattern (`Arc<DAE::Type>`) is skipped (E0308).
                let local_fn_output: Option<Ty> = if !func.contains('.') {
                    let resolve_fn_output = |t: &Ty| -> Option<Ty> {
                        match t {
                            Ty::Function { output, .. } => Some((**output).clone()),
                            Ty::FunctionAlias { base, .. } => {
                                let base_ty = resolve_call_node(base, top_level, pkg_prefix)
                                    .map(|(_, n)| n.ty.clone())
                                    .unwrap_or_else(|| lookup_ty_in_hierarchy(base, top_level));
                                match base_ty {
                                    Ty::Function { output, .. } => Some(*output),
                                    _ => None,
                                }
                            }
                            _ => None,
                        }
                    };
                    env.get(&func).and_then(resolve_fn_output)
                } else {
                    None
                };
                let ty = local_fn_output
                    .unwrap_or_else(|| call_ty(&func, &args, top_level, pkg_prefix));
                TypedExp::Call { func, args, named_args, ty, sig_ty }
            }
        }

        Absyn::Exp::PARTEVALFUNCTION { function_, functionArgs } => {
            // `function f(arg = e, ...)`: partial application of `f` with the
            // specified arguments bound. The remaining formals stay open and
            // must be supplied at every later call site.
            let func = cref_to_dotted(function_);
            let (args, named_args) = extract_call_args(functionArgs, env, top_level, pkg_prefix, type_vars);
            // Resolve the underlying function's signature. We need formal
            // names and types (in order) so codegen can identify which
            // formals were bound positionally / by name and emit a closure
            // that forwards the remaining unbound formals.
            //
            // We use the same name-resolution path as a normal CALL site so
            // that bare references to sibling functions (e.g. `edge_finder`
            // inside its enclosing package) are found.  Built-ins (e.g.
            // `realEq`) live outside the hierarchy and are looked up in
            // `builtin_function_ty`.
            // A plain name bound to a function type in the local scope is a
            // function-typed *component* — `function v(arg = e)` partially
            // applies the function value stored in `v`, and the formal list
            // comes from the variable's declared (partial-)function type.
            // Locals shadow function declarations here, same as in a call.
            let local_fn_ty: Option<Ty> = if !func.contains('.') {
                match env.get(&func) {
                    Some(t @ (Ty::Function { .. } | Ty::FunctionAlias { .. })) => Some(t.clone()),
                    _ => None,
                }
            } else {
                None
            };
            let callee_is_local = local_fn_ty.is_some();
            let sig_ty = match local_fn_ty {
                Some(t) => t,
                None => match resolve_call_node(&func, top_level, pkg_prefix) {
                    Some((_, node)) => node.ty.clone(),
                    None => builtin_function_ty(&func).unwrap_or_else(|| lookup_ty_in_hierarchy(&func, top_level)),
                },
            };
            // `function f = g;` declares `f` as an alias of `g` — its node
            // carries `Ty::FunctionAlias`, not `Ty::Function`, so the formal
            // list needed to lower a partial application of `f` lives on the
            // base `g`. Resolve the base to its `Ty::Function` (the base name
            // is found by the same outward scope-walk a normal call uses).
            let sig_ty = if let Ty::FunctionAlias { base, .. } = &sig_ty {
                resolve_call_node(base, top_level, pkg_prefix)
                    .map(|(_, n)| n.ty.clone())
                    .unwrap_or_else(|| lookup_ty_in_hierarchy(base, top_level))
            } else {
                sig_ty
            };
            let ty = match &sig_ty {
                Ty::Function { type_vars: tvs, inputs, output, .. } => {
                    let bound_pos = args.len();
                    let bound_named: std::collections::HashSet<&str> =
                        named_args.iter().map(|(n, _)| n.as_str()).collect();
                    let remaining: Vec<FunctionInput> = inputs.iter().enumerate()
                        .filter_map(|(i, inp)| {
                            if i < bound_pos { return None; }
                            if bound_named.contains(inp.name.as_str()) { return None; }
                            Some(inp.clone())
                        })
                        .collect();
                    Ty::Function {
                        type_vars: tvs.clone(),
                        inputs: remaining,
                        output: output.clone(),
                        // The result is no longer the original named alias —
                        // it's a freshly-shaped function whose arity differs.
                        name: None,
                    }
                }
                _ => Ty::Unknown,
            };
            TypedExp::PartEval { func, args, named_args, sig_ty, ty, callee_is_local }
        }

        Absyn::Exp::TUPLE { expressions } => {
            let mut elems: Vec<TypedExp> = (&**expressions).into_iter()
                .map(|e| infer_exp(e.as_ref(), env, top_level, pkg_prefix, type_vars))
                .collect();
            // The parser preserves source parentheses as a single-element
            // TUPLE (regular omc does the same, see `Modelica.g` `primary`).
            // MetaModelica has no one-element tuple type, so `(e)` always
            // means a parenthesized expression; unwrap it like
            // Static.elabExp_Tuple_LHS_RHS does.
            if elems.len() == 1 {
                elems.pop().unwrap()
            } else {
                TypedExp::Tuple(elems)
            }
        }

        Absyn::Exp::ARRAY { arrayExp } => {
            let elems: Vec<TypedExp> = (&**arrayExp).into_iter()
                .map(|e| infer_exp(e.as_ref(), env, top_level, pkg_prefix, type_vars))
                .collect();
            let inner_ty = elems.first().map(|e| e.ty()).unwrap_or(Ty::Unknown);
            TypedExp::Array { elems, ty: Ty::List(Box::new(inner_ty)) }
        }

        Absyn::Exp::CONS { head, rest } => {
            let head_e = infer_exp(head, env, top_level, pkg_prefix, type_vars);
            let tail_e = infer_exp(rest, env, top_level, pkg_prefix, type_vars);
            let ty = tail_e.ty();
            TypedExp::Cons { head: Box::new(head_e), tail: Box::new(tail_e), ty }
        }

        Absyn::Exp::MATCHEXP { matchTy, inputExp, localDecls, cases, .. } => {
            // `match id as expr ...` binds the scrutinee to `id` so the arm
            // bodies can refer to the un-decomposed value. Lift the `AS`
            // wrapper out into an explicit `as_binding`; the real scrutinee
            // is the inner expression.
            let (real_input, as_binding): (&Absyn::Exp, Option<String>) = match strip_exp_wrappers(inputExp) {
                Absyn::Exp::AS { id, exp } => (exp.as_ref(), Some(id.to_string())),
                other => (other, None),
            };
            let input = infer_exp(real_input, env, top_level, pkg_prefix, type_vars);
            let kind = match matchTy {
                Absyn::MatchType::MATCH => MatchKind::Match,
                Absyn::MatchType::MATCHCONTINUE => MatchKind::MatchContinue,
            };
            // Process match-level local declarations: these are visible to all arms
            // and must be declared in each arm body. We add them to the environment
            // before inferring the case bodies so that their types are known inside arms.
            let match_locals_raw = infer_case_locals_standalone(localDecls, type_vars, top_level, pkg_prefix);
            let mut case_env = env.clone();
            for (n, t, _, _) in &match_locals_raw {
                case_env.insert(n.clone(), t.clone());
            }
            // The `as` binding is in scope inside every arm; its type is
            // the scrutinee's type.
            if let Some(name) = &as_binding {
                case_env.insert(name.clone(), input.ty());
            }
            // Type-check default-binding expressions for match-level locals in
            // an environment where the surrounding scope and all match-level
            // locals are visible.  Pattern bindings are *not* — match-level
            // locals are evaluated once per arm entry, before patterns bind.
            let match_locals: Vec<(String, Ty, Option<TypedExp>, Option<Absyn::TypeSpec>)> = match_locals_raw.into_iter()
                .map(|(n, t, d, ts)| {
                    let td = d.as_ref().map(|e| infer_exp(e, &case_env, top_level, pkg_prefix, type_vars));
                    (n, t, td, ts)
                })
                .collect();
            // Identify a scrutinee variable that can be narrowed inside each arm:
            // either `match x as y ...` (use `y`) or `match x ...` where `x` is
            // a plain variable reference. Carries that variable's pre-narrowing
            // type so `infer_case` can replace it with `Ty::UnionTypeVariant`
            // for arms whose pattern fixes the variant.
            // A scrutinee is narrowable when the input is a simple variable
            // reference (single segment, no subscripts). We don't try to
            // narrow on `match foo.bar` or `match arr[i]` since narrowing a
            // sub-expression would require synthesising a fresh local.
            let scrut_name_owned: Option<String> = match (&as_binding, &input) {
                (Some(name), _) => Some(name.clone()),
                (None, TypedExp::Var { segments, .. })
                    if segments.len() == 1 && segments[0].subscripts.is_empty() =>
                {
                    Some(segments[0].name.clone())
                }
                _ => None,
            };
            let scrut_ty = input.ty();
            let scrutinee_for_arm = scrut_name_owned.as_deref().map(|n| (n, &scrut_ty));
            // Tuple scrutinee: collect (name, ty) for each tuple element that
            // is itself a plain variable reference, so each can be narrowed
            // independently inside arms whose tuple-pattern fixes that
            // element's variant. Without this, an arm pattern like
            // `(Expression.REAL(), Expression.INTEGER())` over the synthetic
            // tuple `(exp1, exp2)` leaves both `exp1` and `exp2` typed as the
            // wide `Ty::RustEnum(Expression)` — and field-type resolution on
            // `exp1.value` / `exp2.value` returns the *first* enum variant's
            // field type (often Integer), so mixed-numeric arithmetic at the
            // typedexp level looks like `i32 + i32` even though the emitted
            // var_field! calls produce mismatched OrderedFloat/i32 operands.
            let tuple_scrutinees: Vec<(String, Ty)> = match &input {
                TypedExp::Tuple(elems) => elems.iter().filter_map(|e| match e {
                    TypedExp::Var { segments, ty, .. } if segments.len() == 1 && segments[0].subscripts.is_empty() => {
                        Some((segments[0].name.clone(), ty.clone()))
                    }
                    _ => None,
                }).collect(),
                _ => Vec::new(),
            };
            let typed_cases: Vec<TypedCase> = (&**cases).into_iter()
                .map(|c| infer_case(c, &case_env, top_level, pkg_prefix, &match_locals, type_vars, scrutinee_for_arm, &tuple_scrutinees))
                .collect();
            // Promote each arm's type from a narrowed variant struct to its
            // parent uniontype enum: an arm that returned the scrutinee under a
            // narrowed pattern would otherwise type the whole `match` as the
            // variant struct (e.g. `Absyn.ClassPart.PUBLIC`), which renders as
            // a variant *path* — not a valid Rust type when this match's value
            // is later used (e.g. as a `list(...)` element type).
            let ty = typed_cases.iter()
                .map(|c| promote_variant_to_enum_ty(c.result.ty(), top_level))
                .find(|t| *t != Ty::Unknown)
                .unwrap_or(Ty::Unknown);
            TypedExp::Match { kind, input: Box::new(input), cases: typed_cases, ty, as_binding }
        }

        Absyn::Exp::RANGE { start, step, stop } => {
            let start_e = infer_exp(start, env, top_level, pkg_prefix, type_vars);
            let step_e = step.as_ref().map(|s| infer_exp(s, env, top_level, pkg_prefix, type_vars));
            let stop_e = infer_exp(stop, env, top_level, pkg_prefix, type_vars);
            let elem_ty = start_e.ty();
            TypedExp::Range {
                start: Box::new(start_e),
                step: step_e.map(Box::new),
                stop: Box::new(stop_e),
                elem_ty,
            }
        }

        // EXPRESSIONCOMMENT is a transparent wrapper added by the parser to
        // preserve `//` / `/*…*/` comments that appear immediately before /
        // after an expression. The codegen's typed expression layer does not
        // (yet) carry per-expression comments, so we recurse into the inner
        // expression. Comments are still retained at the surrounding item
        // level (LEXER_COMMENT, *ITEMCOMMENT, commentsBeforeClass, …) which
        // is where the code generator actually emits them. If we later want
        // comments anchored to individual expressions in the generated
        // source, extend TypedExp with a `Commented { before, exp, after }`
        // variant and propagate it through `emit_exp`.
        Absyn::Exp::EXPRESSIONCOMMENT { exp, .. } => {
            infer_exp(exp, env, top_level, pkg_prefix, type_vars)
        }

        other => TypedExp::Todo(format!("{other:?}").chars().take(80).collect()),
    }
}

fn extract_call_args<'a>(
    function_args: &Absyn::FunctionArgs,
    env: &HashMap<String, Ty>,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
    type_vars: &[String],
) -> (Vec<TypedExp>, Vec<(String, TypedExp)>) {
    match function_args {
        Absyn::FunctionArgs::FUNCTIONARGS { args, argNames } => {
            let pos: Vec<TypedExp> = (&**args).into_iter()
                .map(|a| infer_exp(a.as_ref(), env, top_level, pkg_prefix, type_vars))
                .collect();
            let named: Vec<(String, TypedExp)> = (&**argNames).into_iter()
                .map(|na| {
                    let Absyn::NamedArg { argName, argValue } = na.as_ref();
                    (argName.to_string(), infer_exp(argValue.as_ref(), env, top_level, pkg_prefix, type_vars))
                })
                .collect();
            (pos, named)
        }
        _ => (vec![], vec![]),
    }
}

fn infer_case<'a>(
    case: &Absyn::Case,
    env: &HashMap<String, Ty>,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
    // Match-level locals already incorporated into `env` by the caller.
    extra_locals: &[(String, Ty, Option<TypedExp>, Option<Absyn::TypeSpec>)],
    type_vars: &[String],
    // If the scrutinee was a plain variable reference (or `match x as x ...`),
    // pass `(name, ty)` so we can narrow that variable to a `Ty::UnionTypeVariant`
    // inside each arm whose pattern fixes the variant. This is what allows
    // downstream field-type resolution to pick the *correct* variant's field
    // type for fields whose declared type differs per variant (e.g. JSON.values).
    scrutinee: Option<(&str, &Ty)>,
    // Per-element scrutinees for a tuple input — each tuple position whose
    // input expression was a plain variable reference. Used to narrow each
    // such variable independently when the arm's pattern is also a tuple.
    tuple_scrutinees: &[(String, Ty)],
) -> TypedCase {
    fn path_to_dotted(path: &Absyn::Path) -> String {
        match path {
            Absyn::Path::IDENT { name } => name.to_string(),
            Absyn::Path::QUALIFIED { name, path } => format!("{name}.{}", path_to_dotted(path)),
            Absyn::Path::FULLYQUALIFIED { path } => path_to_dotted(path),
        }
    }

    /// Resolve a single MetaModelica TypeSpec to a `Ty`.
    ///
    /// `type_vars` lists the type-variable names in scope for the enclosing function.
    /// This is required so that references to type variables like `Option<Key>` produce
    /// `Ty::Option(Ty::TypeVar("Key"))` rather than falling through to a failed hierarchy
    /// lookup and returning `Ty::Unknown`.
    ///
    /// Handling mirrors `hierarchy::resolve_type_spec`:
    /// - Primitives (Integer, Real, Boolean, String) → primitive Ty variants
    /// - Type variable names → `Ty::TypeVar(name)`
    /// - Option<T>, list<T>/List<T>, array<T>/Array<T>, tuple<...> → structured Ty variants
    /// - `polymorphic<T>` (the parser's representation of `replaceable type T subtypeof Any`) →
    ///   recurse into the inner spec (stripping the wrapper)
    /// - Everything else → hierarchy lookup
    fn typespec_to_ty(type_spec: &Absyn::TypeSpec, type_vars: &[String], top_level: &BTreeMap<String, NameNode<'_>>, pkg_prefix: &str) -> Ty {
        match type_spec {
            Absyn::TypeSpec::TPATH { path, .. } => {
                let name = path_to_dotted(path);
                match name.as_str() {
                    "Integer" => Ty::I32,
                    "Real"    => Ty::F64,
                    "Boolean" => Ty::Bool,
                    "String"  => Ty::Str,
                    _ if type_vars.iter().any(|v| v == &name) => Ty::TypeVar(name),
                    // Scope-aware lookup: resolve the type name relative to the
                    // enclosing package using the same rules as call resolution.
                    // Falling back to `lookup_ty_in_hierarchy` (which only handles
                    // fully-qualified names) here would leave package-local types
                    // like `Tree` (declared inside `AvlSet*` via `extends`) as
                    // `Ty::Unknown`, which in turn forces the code generator to
                    // emit `let mut x; // TODO: ...` for case locals.
                    _ => resolve_type_name(&name, top_level, pkg_prefix),
                }
            }
            Absyn::TypeSpec::TCOMPLEX { path, typeSpecs, .. } => {
                let args: Vec<std::sync::Arc<Absyn::TypeSpec>> = (&**typeSpecs).into_iter().cloned().collect();
                let ctor = path_to_dotted(path);
                match ctor.as_str() {
                    "Option" if args.len() == 1 => {
                        Ty::Option(Box::new(typespec_to_ty(args[0].as_ref(), type_vars, top_level, pkg_prefix)))
                    }
                    "list" | "List" if args.len() == 1 => {
                        Ty::List(Box::new(typespec_to_ty(args[0].as_ref(), type_vars, top_level, pkg_prefix)))
                    }
                    "array" | "Array" if args.len() == 1 => {
                        Ty::Array(Box::new(typespec_to_ty(args[0].as_ref(), type_vars, top_level, pkg_prefix)))
                    }
                    "tuple" => {
                        let tys: Vec<Ty> = args.iter().map(|a| typespec_to_ty(a.as_ref(), type_vars, top_level, pkg_prefix)).collect();
                        Ty::Tuple(tys)
                    }
                    // `polymorphic<T>` is the parser's representation for `replaceable type T subtypeof Any`.
                    // Strip the wrapper and resolve the inner spec directly.
                    "polymorphic" if args.len() == 1 => {
                        typespec_to_ty(args[0].as_ref(), type_vars, top_level, pkg_prefix)
                    }
                    // User-defined generic (e.g. `Mutable<T>`, `UnorderedSet<T>`).
                    // Preserve the type arguments as `Ty::Generic` so `fmt_ty`
                    // emits `Base<Arg>` instead of dropping the parameter and
                    // generating a bare `Base` — which would fail to compile
                    // (e.g. `let mut i0: Mutable;`).
                    "Mutable" if args.len() == 1 => {
                        let inner = typespec_to_ty(args[0].as_ref(), type_vars, top_level, pkg_prefix);
                        Ty::Generic("Mutable".to_owned(), vec![inner])
                    }
                    _ => {
                        let base_ty = resolve_type_name(&ctor, top_level, pkg_prefix);
                        let resolved: Vec<Ty> = args.iter()
                            .map(|a| typespec_to_ty(a.as_ref(), type_vars, top_level, pkg_prefix))
                            .collect();
                        let base_name = ty_rust_name(&base_ty).unwrap_or_else(|| ctor.clone());
                        Ty::Generic(base_name, resolved)
                    }
                }
            }
        }
    }

    fn infer_case_locals(local_decls: &std::sync::Arc<metamodelica::List<std::sync::Arc<Absyn::ElementItem>>>, type_vars: &[String], top_level: &BTreeMap<String, NameNode<'_>>, pkg_prefix: &str) -> Vec<(String, Ty, Option<Absyn::Exp>, Option<Absyn::TypeSpec>)> {
        let mut out = Vec::new();
        for item in (&**local_decls).into_iter() {
            let Absyn::ElementItem::ELEMENTITEM { element } = item.as_ref() else { continue };
            let Absyn::Element::ELEMENT { specification, .. } = &**element else { continue };
            let Absyn::ElementSpec::COMPONENTS { typeSpec, components, .. } = &**specification else { continue };
            let ty = typespec_to_ty(typeSpec, type_vars, top_level, pkg_prefix);
            for comp_item in (&**components).into_iter() {
                let Absyn::ComponentItem { component, .. } = comp_item.as_ref();
                let Absyn::Component { name, modification, .. } = component;
                let default = extract_default_exp(modification).cloned();
                out.push((name.to_string(), ty.clone(), default, Some((**typeSpec).clone())));
            }
        }
        out
    }

    fn infer_eq_item<'a>(
        item: &Absyn::EquationItem,
        env: &mut HashMap<String, Ty>,
        top_level: &'a BTreeMap<String, NameNode<'a>>,
        pkg_prefix: &str,
        type_vars: &[String],
    ) -> Option<TypedStmt> {
        let eq = match item {
            Absyn::EquationItem::EQUATIONITEM { equation_, .. } => equation_,
            Absyn::EquationItem::EQUATIONITEMCOMMENT { .. } => return None,
        };
        Some(match eq.as_ref() {
            Absyn::Equation::EQ_EQUALS { leftSide, rightSide } => {
                let rhs = infer_exp(rightSide, env, top_level, pkg_prefix, type_vars);
                let lhs = infer_pat(leftSide, env, top_level, pkg_prefix, type_vars);
                for (name, _ty) in pat_bindings(&lhs) {
                    env.insert(name, rhs.ty());
                }
                TypedStmt::Assign { lhs, rhs }
            }
            Absyn::Equation::EQ_NORETCALL { functionName, functionArgs } => {
                let func = cref_to_dotted(functionName);
                let (args, named_args) = extract_call_args(functionArgs, env, top_level, pkg_prefix, type_vars);
                let sig_ty = lookup_ctor_ty(&func, top_level);
                let resolved = resolve_call_node(&func, top_level, pkg_prefix);
                let is_constructor = match &sig_ty {
                    Ty::RustStruct(_) | Ty::RustEnum(_) => true,
                    _ => {
                        if let Some((_, node)) = &resolved {
                            matches!(node.kind, NodeKind::Class(c) if matches!(c.restriction, Absyn::Restriction::R_RECORD | Absyn::Restriction::R_UNIONTYPE))
                        } else {
                            false
                        }
                    }
                };
                let call = if is_constructor {
                    let canonical = canonical_ctor_qname(&func, &resolved, top_level);
                    let ty = match lookup_ty_in_hierarchy(&canonical, top_level) {
                        Ty::Function { output, .. } => *output,
                        other => other,
                    };
                    let field_names = match &sig_ty {
                        Ty::RustStruct(qname) | Ty::RustEnum(qname) => {
                            record_field_tys(qname, top_level).into_iter().map(|(n, _)| n).collect()
                        }
                        _ => {
                            record_field_tys(&canonical, top_level).into_iter().map(|(n, _)| n).collect()
                        }
                    };
                    TypedExp::Constructor { name: canonical, args, named_args, ty, field_names }
                } else {
                    let ty = call_ty(&func, &args, top_level, pkg_prefix);
                    TypedExp::Call { func, args, named_args, ty, sig_ty }
                };
                TypedStmt::NoRetCall { call }
            }
            Absyn::Equation::EQ_IF { ifExp, equationTrueItems, elseIfBranches, equationElseItems } => {
                let cond = infer_exp(ifExp, env, top_level, pkg_prefix, type_vars);
                let then_ = infer_eq_items_list_arc(equationTrueItems, env, top_level, pkg_prefix, type_vars);
                let elseif: Vec<(TypedExp, Vec<TypedStmt>)> = (&**elseIfBranches).into_iter()
                    .map(|(c, b)| (
                        infer_exp(c, env, top_level, pkg_prefix, type_vars),
                        infer_eq_items_list_arc(b, env, top_level, pkg_prefix, type_vars),
                    ))
                    .collect();
                let else_ = infer_eq_items_list_arc(equationElseItems, env, top_level, pkg_prefix, type_vars);
                TypedStmt::If { cond, then_, elseif, else_ }
            }
            Absyn::Equation::EQ_FOR { iterators, forEquations } => {
                let iters: Vec<std::sync::Arc<Absyn::ForIterator>> = (&**iterators).into_iter().cloned().collect();
                if iters.len() == 1 {
                    let Absyn::ForIterator { name, range, .. } = &*iters[0];
                    let range_e = match range {
                        Some(r) => infer_exp(r.as_ref(), env, top_level, pkg_prefix, type_vars),
                        None => TypedExp::Todo("for-without-range".to_owned()),
                    };
                    let elem_ty = match range_e.ty() {
                        Ty::List(t) | Ty::Array(t) | Ty::Range(t) => *t,
                        _ => Ty::Unknown,
                    };
                    let mut inner = env.clone();
                    inner.insert(name.to_string(), elem_ty);
                    let body = infer_eq_items_list_arc(forEquations, &mut inner, top_level, pkg_prefix, type_vars);
                    TypedStmt::For { var: name.to_string(), range: range_e, body }
                } else {
                    TypedStmt::Todo("multi-iterator-for-eq".to_owned())
                }
            }
            Absyn::Equation::EQ_FAILURE { equ } => {
                let mut body = Vec::new();
                if let Some(s) = infer_eq_item(equ, env, top_level, pkg_prefix, type_vars) {
                    body.push(s);
                }
                TypedStmt::Failure { body }
            }
            other => TypedStmt::Todo(format!("{other:?}").chars().take(60).collect()),
        })
    }

    fn infer_eq_items_list<'a>(
        items: &std::sync::Arc<metamodelica::List<Absyn::EquationItem>>,
        env: &mut HashMap<String, Ty>,
        top_level: &'a BTreeMap<String, NameNode<'a>>,
        pkg_prefix: &str,
        type_vars: &[String],
    ) -> Vec<TypedStmt> {
        let mut out = Vec::new();
        for it in (&**items).into_iter() {
            if let Some(s) = infer_eq_item(it, env, top_level, pkg_prefix, type_vars) {
                out.push(s);
            }
        }
        out
    }

    fn infer_eq_items_list_arc<'a>(
        items: &std::sync::Arc<metamodelica::List<std::sync::Arc<Absyn::EquationItem>>>,
        env: &mut HashMap<String, Ty>,
        top_level: &'a BTreeMap<String, NameNode<'a>>,
        pkg_prefix: &str,
        type_vars: &[String],
    ) -> Vec<TypedStmt> {
        let mut out = Vec::new();
        for it in (&**items).into_iter() {
            if let Some(s) = infer_eq_item(it.as_ref(), env, top_level, pkg_prefix, type_vars) {
                out.push(s);
            }
        }
        out
    }

    fn infer_case_class_part<'a>(
        class_part: &Absyn::ClassPart,
        env: &mut HashMap<String, Ty>,
        top_level: &'a BTreeMap<String, NameNode<'a>>,
        pkg_prefix: &str,
        type_vars: &[String],
    ) -> Vec<TypedStmt> {
        match class_part {
            Absyn::ClassPart::ALGORITHMS { contents }
            | Absyn::ClassPart::INITIALALGORITHMS { contents } => {
                infer_stmts_list(contents, env, top_level, pkg_prefix, type_vars)
            }
            Absyn::ClassPart::EQUATIONS { contents }
            | Absyn::ClassPart::INITIALEQUATIONS { contents } => {
                infer_eq_items_list_arc(contents, env, top_level, pkg_prefix, type_vars)
            }
            _ => vec![],
        }
    }

    match case {
        Absyn::Case::CASE { pattern, patternGuard, localDecls, classPart, result, .. } => {
            // Case-level locals (`local list<X> M;`) must be visible to
            // `infer_pat` so that a pattern reference like `node::M` resolves
            // `M` to the locally-declared variable rather than being
            // misclassified as a constructor by the uppercase heuristic in
            // `infer_pat`. Without this, an uppercase-named local appearing
            // in pattern position becomes `TypedPat::Constructor { name: "M" }`
            // and downstream codegen emits it as a bare ctor name, losing the
            // ref-binding through the surrounding `Cons.tail` Arc edge.
            let case_locals_pre = infer_case_locals(localDecls, type_vars, top_level, pkg_prefix);
            let mut pat_env = env.clone();
            for (n, t, _, _) in &case_locals_pre {
                pat_env.insert(n.clone(), t.clone());
            }
            let pat = infer_pat(pattern, &pat_env, top_level, pkg_prefix, type_vars);
            let mut inner_env = env.clone();
            // Use the typed scrutinee (when we have one) so constructor-field
            // bindings get the field's real type rather than `Ty::Unknown`.
            // Without this, a binding like `subModLst = submods` inside a
            // `SCode.MOD { … }` pattern shadows any like-named function-level
            // protected local with `Unknown` — which then propagates to the
            // for-loop iteratee type and disables the List/Array iteration
            // dispatch in codegen. Keep the un-typed fallback so we don't
            // overwrite an existing rich type with `Unknown` for patterns
            // whose scrutinee is itself untyped.
            let pat_binds: Vec<(String, Ty)> = if let Some((_, sty)) = scrutinee {
                pat_bindings_with_scrut_ty_tl(&pat, sty, top_level)
            } else {
                pat_bindings(&pat)
            };
            for (n, t) in pat_binds {
                if matches!(t, Ty::Unknown) {
                    inner_env.entry(n).or_insert(t);
                } else {
                    inner_env.insert(n, t);
                }
            }
            // Narrow the scrutinee variable's type to the matched record-variant
            // when the pattern is a constructor on a multi-record uniontype.
            // Without this, `obj.values` inside a `case LIST_OBJECT() ...` arm
            // would resolve via `Ty::RustEnum` (which picks the first variant
            // declaring `values`) and pick the wrong field type for uniontypes
            // where same-named fields differ across variants (e.g. JSON, where
            // `values` is `UnorderedMap` in OBJECT, `list<tuple<...>>` in
            // LIST_OBJECT, `Vector<JSON>` in ARRAY, and `list<JSON>` in LIST).
            if let Some((scrut_name, scrut_ty)) = scrutinee
                && let Some(narrowed) = narrow_scrutinee_for_pat(&pat, scrut_ty, top_level) {
                    inner_env.insert(scrut_name.to_string(), narrowed);
                }
            // Tuple-element narrowing: for each tuple-position variable, if
            // the arm's pattern is also a tuple of the same arity and the
            // corresponding sub-pattern fixes the variant, narrow that
            // variable in `inner_env`.
            if !tuple_scrutinees.is_empty()
                && let TypedPat::Tuple(pat_elems) = &pat
                && pat_elems.len() >= tuple_scrutinees.len() {
                    for ((name, ty), sub_pat) in tuple_scrutinees.iter().zip(pat_elems.iter()) {
                        if let Some(narrowed) = narrow_scrutinee_for_pat(sub_pat, ty, top_level) {
                            inner_env.insert(name.clone(), narrowed);
                        }
                    }
                }
            // Start with match-level locals (already in env), then add case-level locals.
            // Dedup: case-level locals shadow match-level ones with the same name.
            let mut locals: Vec<(String, Ty, Option<TypedExp>, Option<Absyn::TypeSpec>)> = extra_locals.to_vec();
            // Build the environment in which case-local default expressions are
            // type-checked: surrounding scope + pattern bindings + all
            // case-locals (so a later local can mention an earlier one).
            // This mirrors MetaModelica's case-local evaluation rules.
            let mut local_init_env = inner_env.clone();
            for (n, t, _, _) in &case_locals_pre {
                local_init_env.insert(n.clone(), t.clone());
            }
            for (n, t, default_exp, ts) in &case_locals_pre {
                let typed_default = default_exp.as_ref()
                    .map(|e| infer_exp(e, &local_init_env, top_level, pkg_prefix, type_vars));
                if let Some(pos) = locals.iter().position(|(ln, _, _, _)| ln == n) {
                    locals[pos] = (n.clone(), t.clone(), typed_default, ts.clone()); // case-level shadows match-level
                } else {
                    locals.push((n.clone(), t.clone(), typed_default, ts.clone()));
                }
            }
            for (n, t, _, _) in &locals {
                // A case-local declaration and a pattern binding can name the
                // same variable — e.g. `local Expression lhs;` together with
                // `case RECORD_EQUATION(lhs = lhs as Expression.TUPLE())`. The
                // pattern narrowed `lhs` to `UnionTypeVariant(NFExpression,
                // TUPLE)` in `inner_env`; the local declares only the bare enum
                // `Expression`. The narrowing is strictly more precise for the
                // arm body (it picks the correct variant's field types for
                // fields whose type differs per variant), so don't clobber it
                // with the less-specific declared type when they share the
                // parent enum.
                if let (Some(Ty::UnionTypeVariant(parent, _)), Ty::RustEnum(decl)) =
                    (inner_env.get(n), t)
                    && parent == decl
                {
                    continue;
                }
                inner_env.insert(n.clone(), t.clone());
            }
            let guard = patternGuard.as_ref().map(|g| infer_exp(g, &inner_env, top_level, pkg_prefix, type_vars));
            let mut case_env = inner_env.clone();
            let stmts = infer_case_class_part(classPart, &mut case_env, top_level, pkg_prefix, type_vars);
            // Discover any new variables first assigned inside the arm body (not declared
            // anywhere). These arise when the MetaModelica source omits explicit local
            // declarations for intermediate variables that are only assigned once.
            // `case_env` is a `HashMap`, whose iteration order is randomised
            // per process. Collect the newly-discovered locals and sort by name
            // before appending so the emitted `let mut` declaration order — and
            // hence the generated Rust — is deterministic across codegen runs.
            let mut discovered: Vec<(&String, &Ty)> = case_env.iter()
                .filter(|(n, _)| !inner_env.contains_key(*n) && !locals.iter().any(|(ln, _, _, _)| &ln == n))
                .collect();
            discovered.sort_by(|a, b| a.0.cmp(b.0));
            for (n, t) in discovered {
                locals.push((n.clone(), t.clone(), None, None));
            }
            TypedCase { pattern: pat, guard, locals, stmts, result: infer_exp(result, &case_env, top_level, pkg_prefix, type_vars) }
        }
        Absyn::Case::ELSE { localDecls, classPart, result, .. } => {
            let mut case_env = env.clone();
            let mut locals: Vec<(String, Ty, Option<TypedExp>, Option<Absyn::TypeSpec>)> = extra_locals.to_vec();
            let case_locals = infer_case_locals(localDecls, type_vars, top_level, pkg_prefix);
            // Build the environment in which case-local default expressions
            // are type-checked: surrounding scope + all case-locals.
            let mut local_init_env = env.clone();
            for (n, t, _, _) in &case_locals {
                local_init_env.insert(n.clone(), t.clone());
            }
            for (n, t, default_exp, ts) in &case_locals {
                let typed_default = default_exp.as_ref()
                    .map(|e| infer_exp(e, &local_init_env, top_level, pkg_prefix, type_vars));
                if let Some(pos) = locals.iter().position(|(ln, _, _, _)| ln == n) {
                    locals[pos] = (n.clone(), t.clone(), typed_default, ts.clone());
                } else {
                    locals.push((n.clone(), t.clone(), typed_default, ts.clone()));
                }
            }
            for (n, t, _, _) in &locals {
                case_env.insert(n.clone(), t.clone());
            }
            let stmts = infer_case_class_part(classPart, &mut case_env, top_level, pkg_prefix, type_vars);
            // See the MATCH-case branch above: sort the HashMap-discovered
            // locals by name so the generated declaration order is stable.
            let mut discovered: Vec<(&String, &Ty)> = case_env.iter()
                .filter(|(n, _)| !env.contains_key(*n) && !locals.iter().any(|(ln, _, _, _)| &ln == n))
                .collect();
            discovered.sort_by(|a, b| a.0.cmp(b.0));
            for (n, t) in discovered {
                locals.push((n.clone(), t.clone(), None, None));
            }
            TypedCase { pattern: TypedPat::Wildcard, guard: None, locals, stmts, result: infer_exp(result, &case_env, top_level, pkg_prefix, type_vars) }
        }
    }
}

/// Resolve match-level local declarations (from `MATCHEXP.localDecls`) to a list of
/// `(name, Ty)` pairs. This is the same resolution logic as `infer_case_locals`
/// (used for case-level locals) but exposed at the top level so `infer_exp` can
/// call it directly when processing a `MATCHEXP` node.
///
/// `type_vars` must be the function-level type variable names (e.g. `["Key"]`).
fn infer_case_locals_standalone(
    local_decls: &std::sync::Arc<metamodelica::List<std::sync::Arc<Absyn::ElementItem>>>,
    type_vars: &[String],
    top_level: &BTreeMap<String, NameNode<'_>>,
    pkg_prefix: &str,
) -> Vec<(String, Ty, Option<Absyn::Exp>, Option<Absyn::TypeSpec>)> {
    fn path_to_dotted(path: &Absyn::Path) -> String {
        match path {
            Absyn::Path::IDENT { name } => name.to_string(),
            Absyn::Path::QUALIFIED { name, path } => format!("{name}.{}", path_to_dotted(path)),
            Absyn::Path::FULLYQUALIFIED { path } => path_to_dotted(path),
        }
    }
    fn typespec_to_ty(type_spec: &Absyn::TypeSpec, type_vars: &[String], top_level: &BTreeMap<String, NameNode<'_>>, pkg_prefix: &str) -> Ty {
        match type_spec {
            Absyn::TypeSpec::TPATH { path, .. } => {
                let name = path_to_dotted(path);
                match name.as_str() {
                    "Integer" => Ty::I32,
                    "Real"    => Ty::F64,
                    "Boolean" => Ty::Bool,
                    "String"  => Ty::Str,
                    _ if type_vars.iter().any(|v| v == &name) => Ty::TypeVar(name),
                    // Scope-aware lookup — see the inner copy in `infer_case`.
                    _ => resolve_type_name(&name, top_level, pkg_prefix),
                }
            }
            Absyn::TypeSpec::TCOMPLEX { path, typeSpecs, .. } => {
                let args: Vec<std::sync::Arc<Absyn::TypeSpec>> = (&**typeSpecs).into_iter().cloned().collect();
                let ctor = path_to_dotted(path);
                match ctor.as_str() {
                    "Option" if args.len() == 1 => {
                        Ty::Option(Box::new(typespec_to_ty(args[0].as_ref(), type_vars, top_level, pkg_prefix)))
                    }
                    "list" | "List" if args.len() == 1 => {
                        Ty::List(Box::new(typespec_to_ty(args[0].as_ref(), type_vars, top_level, pkg_prefix)))
                    }
                    "array" | "Array" if args.len() == 1 => {
                        Ty::Array(Box::new(typespec_to_ty(args[0].as_ref(), type_vars, top_level, pkg_prefix)))
                    }
                    "tuple" => {
                        let tys: Vec<Ty> = args.iter().map(|a| typespec_to_ty(a.as_ref(), type_vars, top_level, pkg_prefix)).collect();
                        Ty::Tuple(tys)
                    }
                    "polymorphic" if args.len() == 1 => {
                        typespec_to_ty(args[0].as_ref(), type_vars, top_level, pkg_prefix)
                    }
                    // User-defined generic — preserve type arguments via `Ty::Generic`.
                    // See the inner `typespec_to_ty` in `infer_case` for the rationale.
                    "Mutable" if args.len() == 1 => {
                        let inner = typespec_to_ty(args[0].as_ref(), type_vars, top_level, pkg_prefix);
                        Ty::Generic("Mutable".to_owned(), vec![inner])
                    }
                    _ => {
                        let base_ty = resolve_type_name(&ctor, top_level, pkg_prefix);
                        let resolved: Vec<Ty> = args.iter()
                            .map(|a| typespec_to_ty(a.as_ref(), type_vars, top_level, pkg_prefix))
                            .collect();
                        let base_name = ty_rust_name(&base_ty).unwrap_or_else(|| ctor.clone());
                        Ty::Generic(base_name, resolved)
                    }
                }
            }
        }
    }

    let mut out = Vec::new();
    for item in (&**local_decls).into_iter() {
        let Absyn::ElementItem::ELEMENTITEM { element } = item.as_ref() else { continue };
        let Absyn::Element::ELEMENT { specification, .. } = &**element else { continue };
        let Absyn::ElementSpec::COMPONENTS { typeSpec, components, .. } = &**specification else { continue };
        let ty = typespec_to_ty(typeSpec, type_vars, top_level, pkg_prefix);
        for comp_item in (&**components).into_iter() {
            let Absyn::ComponentItem { component, .. } = comp_item.as_ref();
            let Absyn::Component { name, modification, .. } = component;
            let default = extract_default_exp(modification).cloned();
            out.push((name.to_string(), ty.clone(), default, Some((**typeSpec).clone())));
        }
    }
    out
}

/// Resolve a MetaModelica `TypeSpec` to a `Ty` using the same rules as the
/// inner helpers nested in `infer_case` / `infer_case_locals_standalone`.
///
/// Exposed so that the code generator can resolve component types for
/// inherited members where the hierarchy did not pre-populate `NameNode.ty`
/// (e.g. components of a `replaceable partial function` carried in through
/// `function F extends G` — the base's children are not copied across).
pub fn resolve_typespec<'a>(
    type_spec: &Absyn::TypeSpec,
    type_vars: &[String],
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
) -> Ty {
    fn path_to_dotted(path: &Absyn::Path) -> String {
        match path {
            Absyn::Path::IDENT { name } => name.to_string(),
            Absyn::Path::QUALIFIED { name, path } => format!("{name}.{}", path_to_dotted(path)),
            Absyn::Path::FULLYQUALIFIED { path } => path_to_dotted(path),
        }
    }
    match type_spec {
        Absyn::TypeSpec::TPATH { path, .. } => {
            let name = path_to_dotted(path);
            match name.as_str() {
                "Integer" => Ty::I32,
                "Real"    => Ty::F64,
                "Boolean" => Ty::Bool,
                "String"  => Ty::Str,
                _ if type_vars.iter().any(|v| v == &name) => Ty::TypeVar(name),
                _ => resolve_type_name(&name, top_level, pkg_prefix),
            }
        }
        Absyn::TypeSpec::TCOMPLEX { path, typeSpecs, .. } => {
            let args: Vec<std::sync::Arc<Absyn::TypeSpec>> = (&**typeSpecs).into_iter().cloned().collect();
            let ctor = path_to_dotted(path);
            match ctor.as_str() {
                "Option" if args.len() == 1 => {
                    Ty::Option(Box::new(resolve_typespec(args[0].as_ref(), type_vars, top_level, pkg_prefix)))
                }
                "list" | "List" if args.len() == 1 => {
                    Ty::List(Box::new(resolve_typespec(args[0].as_ref(), type_vars, top_level, pkg_prefix)))
                }
                "array" | "Array" if args.len() == 1 => {
                    Ty::Array(Box::new(resolve_typespec(args[0].as_ref(), type_vars, top_level, pkg_prefix)))
                }
                "tuple" => {
                    let tys: Vec<Ty> = args.iter().map(|a| resolve_typespec(a.as_ref(), type_vars, top_level, pkg_prefix)).collect();
                    Ty::Tuple(tys)
                }
                "polymorphic" if args.len() == 1 => {
                    resolve_typespec(args[0].as_ref(), type_vars, top_level, pkg_prefix)
                }
                // User-defined generic — preserve type arguments via `Ty::Generic`.
                // See the inner `typespec_to_ty` in `infer_case` for the rationale.
                "Mutable" if args.len() == 1 => {
                    let inner = resolve_typespec(args[0].as_ref(), type_vars, top_level, pkg_prefix);
                    Ty::Generic("Mutable".to_owned(), vec![inner])
                }
                _ => {
                    let base_ty = resolve_type_name(&ctor, top_level, pkg_prefix);
                    let resolved: Vec<Ty> = args.iter()
                        .map(|a| resolve_typespec(a.as_ref(), type_vars, top_level, pkg_prefix))
                        .collect();
                    let base_name = ty_rust_name(&base_ty).unwrap_or_else(|| ctor.clone());
                    Ty::Generic(base_name, resolved)
                }
            }
        }
    }
}

/// Check if a pattern is a "local base" — a variable or field-access chain that can be
/// used as the base of a field access expression (as opposed to a constructor/literal).
fn is_local_base(pat: &TypedPat, env: &HashMap<String, Ty>) -> bool {
    match pat {
        TypedPat::Var(name) => env.contains_key(name),
        TypedPat::FieldAccess { base, .. } => is_local_base(base, env),
        _ => false,
    }
}

/// Convert a local-base pattern back into a TypedExp for use as the base of field access.
fn pat_to_exp(pat: &TypedPat, top_level: &BTreeMap<String, NameNode<'_>>) -> TypedExp {
    match pat {
        TypedPat::Var(name) => TypedExp::Var {
            name: name.clone(),
            segments: vec![CrefSegment { name: name.clone(), subscripts: vec![] }],
            ty: lookup_ty_in_hierarchy(name, top_level),
            last_use: false,
        },
        TypedPat::FieldAccess { base, field } => {
            let base_exp = pat_to_exp(base, top_level);
            // Build a Var that represents the full dotted path, appending this field.
            let base_name = match base_exp {
                TypedExp::Var { name, .. } => name,
                _ => "_".to_owned(),
            };
            TypedExp::Var {
                name: format!("{base_name}.{field}"),
                segments: vec![],
                ty: Ty::Unknown,
                last_use: false,
            }
        },
        _ => TypedExp::Var { name: "_".into(), segments: vec![], ty: Ty::Unknown, last_use: false },
    }
}

/// Infer the pattern from an expression in case-pattern position.
/// `env` and `pkg_prefix` are needed for subscripted refs (Index patterns) in assignment LHS.
/// Fold a dotted name that refers to a `constant` declaration to the literal
/// pattern its value represents. MetaModelica permits referring to a named
/// `constant` in pattern position (e.g. `case DAE.CREF_QUAL(ident =
/// DAE.derivativeNamePrefix)`), where the field is matched for equality against
/// the constant's value. Rust struct patterns can't carry a `const` path in
/// field position (and a `&str`/`ArcStr` mismatch would result anyway), so we
/// resolve the constant to its literal value and lower it to a `TypedPat::Lit`,
/// which the codegen renders as a `Deref @ <lit>` equality match.
///
/// Returns `None` when the name does not resolve to a constant with a literal
/// value (including nested constant references); the caller then falls back to
/// treating it as a constructor path.
fn const_ref_to_lit_pat<'a>(
    dotted: &str,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
) -> Option<TypedPat> {
    let mut seen = 0u32;
    fn fold<'a>(dotted: &str, top_level: &'a BTreeMap<String, NameNode<'a>>, seen: &mut u32) -> Option<TypedPat> {
        *seen += 1;
        if *seen > 16 { return None; }
        let (_, node) = walk_dotted_with_imports(dotted, top_level, 0)?;
        let NodeKind::Component(comp) = &node.kind else { return None };
        if comp.variability != Absyn::Variability::CONST { return None; }
        let default = extract_default_exp(&comp.modification)?;
        match default {
            Absyn::Exp::STRING { value }  => Some(TypedPat::Lit(Lit::Str(value.to_string()))),
            Absyn::Exp::INTEGER { value } => Some(TypedPat::Lit(Lit::Int(*value))),
            Absyn::Exp::BOOL { value }    => Some(TypedPat::Lit(Lit::Bool(*value))),
            Absyn::Exp::REAL { value }    => Some(TypedPat::Lit(Lit::Real(value.to_string()))),
            // A constant defined in terms of another constant — follow it.
            Absyn::Exp::CREF { componentRef } => {
                fold(&cref_to_dotted(componentRef), top_level, seen)
            }
            _ => None,
        }
    }
    fold(dotted, top_level, &mut seen)
}

pub fn infer_pat<'a>(
    exp: &Absyn::Exp,
    env: &HashMap<String, Ty>,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
    type_vars: &[String],
) -> TypedPat {
    match exp {
        Absyn::Exp::INTEGER { value } => TypedPat::Lit(Lit::Int(*value)),
        Absyn::Exp::REAL    { value } => TypedPat::Lit(Lit::Real(value.to_string())),
        Absyn::Exp::STRING  { value } => TypedPat::Lit(Lit::Str(value.to_string())),
        Absyn::Exp::BOOL    { value } => TypedPat::Lit(Lit::Bool(*value)),

        Absyn::Exp::CREF { componentRef } => {
            match componentRef.as_ref() {
                Absyn::ComponentRef::WILD | Absyn::ComponentRef::ALLWILD => TypedPat::Wildcard,
                Absyn::ComponentRef::CREF_IDENT { name, subscripts } if subscripts.is_empty() => {
                    if &**name == "_" {
                        TypedPat::Wildcard
                    } else if env.contains_key(&**name) {
                        // The name is bound in the current scope (function
                        // input/output/protected, match-level local, or
                        // case-level local). It must be a pattern variable —
                        // a local variable shadows any same-named constructor
                        // in scope, and crucially this prevents an uppercase
                        // local (e.g. `local list<X> M;` referenced as `node::M`)
                        // from being misclassified as a constructor.
                        TypedPat::Var(name.to_string())
                    } else if let Some(lit) = const_ref_to_lit_pat(name, top_level) {
                        // A bare reference to a `constant` (e.g. an imported
                        // `constant String`) — match its value, not a binder or
                        // constructor of the same name.
                        lit
                    } else if name.chars().next().map(|c| c.is_uppercase()).unwrap_or(false) {
                        // Uppercase identifiers in pattern position are constructors in
                        // MetaModelica (variants/records), not variable binders.
                        let ty = lookup_ty_in_hierarchy(name, top_level);
                        TypedPat::Constructor { name: name.to_string(), fields: vec![], named_fields: vec![], ty }
                    } else {
                        TypedPat::Var(name.to_string())
                    }
                }
                // Subscripted reference in pattern position (e.g. `arr[1]` on LHS of `:=`).
                Absyn::ComponentRef::CREF_IDENT { name, subscripts } => {
                    let sub = (&**subscripts).into_iter()
                        .filter_map(|s| {
                            if let Absyn::Subscript::SUBSCRIPT { subscript } = s.as_ref() {
                                Some(subscript.as_ref().clone())
                            } else {
                                None
                            }
                        })
                        .next();
                    if let Some(sub_exp) = sub {
                        let base_ty = env.get(&**name).cloned().unwrap_or_else(|| {
                            lookup_ty_in_hierarchy(name, top_level)
                        });
                        let base = TypedExp::Var { name: name.to_string(), segments: vec![], ty: base_ty, last_use: false };
                        TypedPat::Index {
                            base,
                            index: infer_exp(&sub_exp, env, top_level, pkg_prefix, type_vars),
                        }
                    } else {
                        TypedPat::Var(name.to_string())
                    }
                }
                // Qualified reference, possibly subscripted at some segment.
                // Examples (LHS of `:=`):
                //   `a.b.c`     — plain field chain, no subscript anywhere.
                //   `a.b.c[i]`  — subscript on the LAST segment; lift to Index pattern.
                //   `a[i].b`    — subscript followed by field access; not handled
                //                 (TypedPat::Todo so the issue is visible at the call site).
                Absyn::ComponentRef::CREF_QUAL { .. } => {
                    // Walk the entire cref into structured segments. The outer `subscripts`
                    // field of CREF_QUAL only carries the head's subscripts; subscripts on
                    // deeper segments live inside `rest`. A pure CREF_QUAL match on the head
                    // misses them — segment-based walk captures every level uniformly.
                    let (full_dotted, segs) = extract_cref_segments(componentRef, env, top_level, pkg_prefix);
                    let sub_pos = segs.iter().position(|s| !s.subscripts.is_empty());

                    if let Some(idx) = sub_pos {
                        // Only handle the common shape `a.b...x[i]` (subscripts on the LAST
                        // segment, one index). Other shapes need additional lowering work
                        // (field access after subscript, multidim) — flag explicitly.
                        if idx != segs.len() - 1 {
                            return TypedPat::Todo(format!(
                                "LHS subscript followed by field access not yet supported: {full_dotted}"
                            ));
                        }
                        if segs[idx].subscripts.len() > 1 {
                            return TypedPat::Todo(format!(
                                "LHS multidim subscript not yet supported: {full_dotted}"
                            ));
                        }
                        let sub_exp = segs[idx].subscripts[0].clone();
                        // Base is the field chain WITHOUT the trailing subscript, so its type
                        // remains `Ty::Array(_)` / `Ty::List(_)`. `emit_stmt` then dispatches
                        // through the `Ty::Array` branch which emits `.borrow_mut()[..] = ..`.
                        let mut base_segs = segs.clone();
                        base_segs[idx].subscripts.clear();
                        let base_dotted: String = base_segs.iter().map(|s| s.name.clone()).collect::<Vec<_>>().join(".");
                        let base_ty = resolve_first_segment_type(&base_dotted, &base_segs, env, top_level)
                            .unwrap_or_else(|| lookup_ty_in_hierarchy(&base_dotted, top_level));
                        TypedPat::Index {
                            base: TypedExp::Var { name: base_dotted, segments: base_segs, ty: base_ty, last_use: false },
                            index: sub_exp,
                        }
                    } else {
                        // No subscript anywhere: plain field chain when the head is a local,
                        // otherwise a fully-qualified constructor path (e.g. `Pkg.CTOR`).
                        let mut parts = full_dotted.split('.');
                        let first = parts.next().unwrap_or("");
                        if !first.is_empty() && env.contains_key(first) {
                            let mut pat = TypedPat::Var(first.to_owned());
                            for field in parts {
                                pat = TypedPat::FieldAccess {
                                    base: Box::new(pat),
                                    field: field.to_owned(),
                                };
                            }
                            pat
                        } else if let Some(lit) = const_ref_to_lit_pat(&full_dotted, top_level) {
                            // A qualified reference to a `constant` (e.g.
                            // `DAE.derivativeNamePrefix`) — match its value, not
                            // a constructor of the same name.
                            lit
                        } else {
                            let ty = lookup_ty_in_hierarchy(&full_dotted, top_level);
                            TypedPat::Constructor { name: full_dotted, fields: vec![], named_fields: vec![], ty }
                        }
                    }
                }
                _ => {
                    let dotted = cref_to_dotted(componentRef);
                    let ty = lookup_ty_in_hierarchy(&dotted, top_level);
                    TypedPat::Constructor { name: dotted, fields: vec![], named_fields: vec![], ty }
                }
            }
        }

        Absyn::Exp::CALL { function_, functionArgs, .. } => {
            let func = cref_to_dotted(function_);
            match func.as_str() {
                "SOME" => {
                    let inner = match &**functionArgs {
                        Absyn::FunctionArgs::FUNCTIONARGS { args, .. } => (&**args).into_iter().next()
                            .map(|a| infer_pat(a.as_ref(), env, top_level, pkg_prefix, type_vars))
                            .unwrap_or(TypedPat::Wildcard),
                        _ => TypedPat::Wildcard,
                    };
                    TypedPat::Some_(Box::new(inner))
                }
                "NONE" => TypedPat::None_,
                _ => {
                    let (fields, named_fields) = match &**functionArgs {
                        Absyn::FunctionArgs::FUNCTIONARGS { args, argNames } => {
                            let pos: Vec<TypedPat> = (&**args).into_iter()
                                .map(|a| infer_pat(a.as_ref(), env, top_level, pkg_prefix, type_vars))
                                .collect();
                            let named: Vec<(String, TypedPat)> = (&**argNames).into_iter()
                                .map(|na| {
                                    let Absyn::NamedArg { argName, argValue } = na.as_ref();
                                    (argName.to_string(), infer_pat(argValue.as_ref(), env, top_level, pkg_prefix, type_vars))
                                })
                                .collect();
                            (pos, named)
                        }
                        _ => (vec![], vec![]),
                    };
                    // Resolve *bare* constructor names to their canonical qname
                    // through the same scope/import machinery expression-position
                    // calls use. Without this, a pattern like `case SLOT(...)`
                    // for a uniontype record `SLOT` nested under
                    // `NFFunction.Slot` keeps the bare name `SLOT` and codegen
                    // can't qualify it (it needs `Slot::SLOT` or, for
                    // single-record uniontypes that collapse to the parent
                    // struct, `Slot { ... }`).
                    //
                    // Only triggered for names without a `.`: already-dotted
                    // names like `Class.Prefixes.PREFIXES` have their own
                    // shorten/alias-aware codegen path that we must not
                    // disturb — re-canonicalising them can swap an import
                    // alias for the uniontype's canonical qname and then
                    // shorten back to the alias's *module* name (not the
                    // struct), producing E0574.
                    let canonical = if func.contains('.') {
                        func.clone()
                    } else {
                        // Only re-canonicalise; leave `ty` to the lookup below.
                        // Setting `ty` from the canonical qname would tempt the
                        // codegen pattern emitter into the `Ty::RustStruct`
                        // shortcut which folds to the parent struct's path —
                        // wrong when the parent is a `pub mod`-wrapped
                        // single-record uniontype (the struct is at
                        // `Mod::Struct`, not at the bare `Mod`).
                        resolve_call_node(&func, top_level, pkg_prefix)
                            .map(|(qname, _)| qname)
                            .unwrap_or_else(|| func.clone())
                    };
                    // A record whose enclosing uniontype shares its package's
                    // name (e.g. `BackendDAE.DAE`: the record `DAE` lives inside
                    // the uniontype `BackendDAE`, itself in package `BackendDAE`)
                    // is not a *direct* child of the package, so the plain
                    // hierarchy walk returns `Unknown`. MetaModelica exports a
                    // uniontype's records into the enclosing scope, so resolve
                    // through the package's uniontypes to recover the record's
                    // type (`RustStruct(...)`); without this the codegen pattern
                    // emitter mis-binds the bare last segment to a same-named
                    // top-level package and lists that package's members as
                    // "fields" (E0574).
                    let ty = lookup_ctor_ty(&canonical, top_level);
                    TypedPat::Constructor { name: canonical, fields, named_fields, ty }
                }
            }
        }

        Absyn::Exp::TUPLE { expressions } => {
            let mut pats: Vec<TypedPat> = (&**expressions).into_iter()
                .map(|e| infer_pat(e.as_ref(), env, top_level, pkg_prefix, type_vars))
                .collect();
            // `(pat)` is a parenthesized pattern, kept as a single-element
            // TUPLE by the parser; unwrap it like Patternm.elabPattern does
            // (`case (cache, Absyn.TUPLE({exp}), _)`).
            if pats.len() == 1 {
                pats.pop().unwrap()
            } else {
                TypedPat::Tuple(pats)
            }
        }

        Absyn::Exp::ARRAY { arrayExp } => {
            // {} is the empty-list pattern; {a,b,...} builds a list via nested cons.
            let mut pats: Vec<TypedPat> = (&**arrayExp).into_iter()
                .map(|e| infer_pat(e.as_ref(), env, top_level, pkg_prefix, type_vars))
                .collect();
            if pats.is_empty() {
                TypedPat::EmptyList
            } else {
                let mut result = TypedPat::EmptyList;
                for p in pats.into_iter().rev() {
                    result = TypedPat::Cons { head: Box::new(p), tail: Box::new(result) };
                }
                result
            }
        }

        Absyn::Exp::CONS { head, rest } => {
            TypedPat::Cons {
                head: Box::new(infer_pat(head, env, top_level, pkg_prefix, type_vars)),
                tail: Box::new(infer_pat(rest, env, top_level, pkg_prefix, type_vars)),
            }
        }

        Absyn::Exp::AS { id, exp } => {
           TypedPat::As { var: id.to_string(), pat: Box::new(infer_pat(exp, env, top_level, pkg_prefix, type_vars)) }
        }

        // Negative literal in pattern position.
        Absyn::Exp::UNARY { op: Absyn::Operator::UMINUS | Absyn::Operator::UMINUS_EW, exp } => {
            match exp.as_ref() {
                Absyn::Exp::INTEGER { value } => TypedPat::Lit(Lit::Int(-value)),
                Absyn::Exp::REAL    { value } => TypedPat::Lit(Lit::Real(format!("-{value}"))),
                other => TypedPat::Todo(format!("{other:?}").chars().take(40).collect()),
            }
        }

        // Patterns are written using the same Exp grammar as expressions, so
        // a comment immediately before/after a pattern gets wrapped in
        // EXPRESSIONCOMMENT by the parser. Strip the wrapper here — the
        // comment is preserved at the surrounding `case`/algorithm level
        // (or as a `LEXER_COMMENT` element) so we lose nothing at this
        // layer.
        Absyn::Exp::EXPRESSIONCOMMENT { exp, .. } => {
            infer_pat(exp, env, top_level, pkg_prefix, type_vars)
        }

        other => TypedPat::Todo(format!("{other:?}").chars().take(80).collect()),
    }
}

/// Collect all variable bindings introduced by a pattern, with Ty::Unknown for now.
/// Used to extend the type environment inside a match case body.
pub fn pat_bindings(pat: &TypedPat) -> Vec<(String, Ty)> {
    let mut out = Vec::new();
    collect_bindings(pat, &mut out);
    out
}

/// Like `pat_bindings`, but propagates a known scrutinee type into the pattern,
/// so tuple components, `SOME(x)` inners, etc. yield typed bindings instead of
/// `Ty::Unknown`. Constructor field types still come back as `Unknown` here —
/// resolving those requires the record-field map which lives in the codegen
/// context; callers that need typed constructor fields should look that up
/// separately.
pub fn pat_bindings_with_scrut_ty(pat: &TypedPat, scrut: &Ty) -> Vec<(String, Ty)> {
    let mut out = Vec::new();
    collect_bindings_typed(pat, scrut, &mut out);
    out
}

/// Like [`pat_bindings_with_scrut_ty`] but resolves Constructor field types
/// via `top_level`, so a binding for a record field (e.g. `EQMOD { exp: x }`)
/// gets `x`'s real type rather than `Ty::Unknown`. The codegen relies on
/// these types to choose `Deref @` prefixes for downstream Arc-edge patterns.
pub fn pat_bindings_with_scrut_ty_tl<'a>(
    pat: &TypedPat,
    scrut: &Ty,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
) -> Vec<(String, Ty)> {
    let mut out = Vec::new();
    collect_bindings_typed_tl(pat, scrut, top_level, &mut out);
    out
}

fn collect_bindings_typed(pat: &TypedPat, scrut: &Ty, out: &mut Vec<(String, Ty)>) {
    match pat {
        TypedPat::Var(name) => out.push((name.clone(), scrut.clone())),
        TypedPat::Some_(inner) => {
            let inner_ty = match scrut { Ty::Option(t) => (**t).clone(), _ => Ty::Unknown };
            collect_bindings_typed(inner, &inner_ty, out);
        }
        TypedPat::Cons { head, tail } => {
            let elem_ty = match scrut { Ty::List(t) => (**t).clone(), _ => Ty::Unknown };
            collect_bindings_typed(head, &elem_ty, out);
            collect_bindings_typed(tail, scrut, out);
        }
        TypedPat::Tuple(pats) => {
            let tys: Vec<Ty> = match scrut {
                Ty::Tuple(ts) if ts.len() == pats.len() => ts.clone(),
                _ => vec![Ty::Unknown; pats.len()],
            };
            for (p, ty) in pats.iter().zip(tys.iter()) {
                collect_bindings_typed(p, ty, out);
            }
        }
        TypedPat::Constructor { fields, named_fields, .. } => {
            // Without the record-field map we can't recover field types here;
            // emit Unknown so the caller can choose to enrich.
            fields.iter().for_each(|p| collect_bindings_typed(p, &Ty::Unknown, out));
            named_fields.iter().for_each(|(_, p)| collect_bindings_typed(p, &Ty::Unknown, out));
        }
        TypedPat::As { var, pat } => {
            out.push((var.clone(), scrut.clone()));
            collect_bindings_typed(pat, scrut, out);
        }
        _ => {}
    }
}

fn collect_bindings_typed_tl<'a>(
    pat: &TypedPat,
    scrut: &Ty,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    out: &mut Vec<(String, Ty)>,
) {
    match pat {
        TypedPat::Var(name) => out.push((name.clone(), scrut.clone())),
        TypedPat::Some_(inner) => {
            let inner_ty = match scrut { Ty::Option(t) => (**t).clone(), _ => Ty::Unknown };
            collect_bindings_typed_tl(inner, &inner_ty, top_level, out);
        }
        TypedPat::Cons { head, tail } => {
            let elem_ty = match scrut { Ty::List(t) => (**t).clone(), _ => Ty::Unknown };
            collect_bindings_typed_tl(head, &elem_ty, top_level, out);
            collect_bindings_typed_tl(tail, scrut, top_level, out);
        }
        TypedPat::Tuple(pats) => {
            let tys: Vec<Ty> = match scrut {
                Ty::Tuple(ts) if ts.len() == pats.len() => ts.clone(),
                _ => vec![Ty::Unknown; pats.len()],
            };
            for (p, ty) in pats.iter().zip(tys.iter()) {
                collect_bindings_typed_tl(p, ty, top_level, out);
            }
        }
        TypedPat::Constructor { name, fields, named_fields, .. } => {
            // Resolve field types via the hierarchy. For a qualified path we
            // can look up the record directly; otherwise, if the scrutinee's
            // type names a uniontype, search for the record by simple name
            // among its variants — the codegen-side `record_field_tys_*`
            // helpers use the same fallback chain.
            let field_tys: Vec<(String, Ty)> = {
                let direct = if name.contains('.') {
                    record_field_tys(name, top_level)
                } else { vec![] };
                if !direct.is_empty() {
                    direct
                } else if let Some((canonical, _)) = lookup_record_through_unions(name, top_level) {
                    record_field_tys(&canonical, top_level)
                } else if let Ty::RustEnum(parent) = scrut {
                    let simple = name.rsplit_once('.').map_or(name.as_str(), |(_, s)| s);
                    let candidate = format!("{parent}.{simple}");
                    record_field_tys(&candidate, top_level)
                } else if let Ty::RustStruct(parent) | Ty::AliasTo(parent) = scrut {
                    // Standalone record (no uniontype wrapper): the constructor
                    // name is the type name itself or a child record. Try the
                    // scrut's qname directly first, then `<scrut>.<name>`.
                    let direct = record_field_tys(parent, top_level);
                    if !direct.is_empty() {
                        direct
                    } else {
                        let simple = name.rsplit_once('.').map_or(name.as_str(), |(_, s)| s);
                        let candidate = format!("{parent}.{simple}");
                        record_field_tys(&candidate, top_level)
                    }
                } else { vec![] }
            };
            for (i, p) in fields.iter().enumerate() {
                let ty = field_tys.get(i).map(|(_, t)| t.clone()).unwrap_or(Ty::Unknown);
                collect_bindings_typed_tl(p, &ty, top_level, out);
            }
            for (fname, p) in named_fields {
                let ty = field_tys.iter().find(|(n, _)| n == fname)
                    .map(|(_, t)| t.clone()).unwrap_or(Ty::Unknown);
                collect_bindings_typed_tl(p, &ty, top_level, out);
            }
        }
        TypedPat::As { var, pat } => {
            // When the inner pattern fixes a specific variant (`x @ CTOR(..)`),
            // narrow `x`'s type to that variant. Variants of one uniontype may
            // share a field *name* with *different* types (e.g.
            // `NFExpression.ARRAY.elements` is `array<..>` but
            // `TUPLE.elements`/`RECORD.elements` are `list<..>`); without the
            // narrowing, `x` stays typed as the bare enum and field-access
            // resolution falls back to the first matching variant's type,
            // mis-inferring `x.elements` and e.g. iterating it as an Array
            // (`.borrow().iter()`) when it is a List (E0599).
            let var_ty = narrow_scrutinee_for_pat(pat, scrut, top_level)
                .unwrap_or_else(|| scrut.clone());
            out.push((var.clone(), var_ty));
            collect_bindings_typed_tl(pat, scrut, top_level, out);
        }
        _ => {}
    }
}

fn collect_bindings(pat: &TypedPat, out: &mut Vec<(String, Ty)>) {
    match pat {
        TypedPat::Var(name) => out.push((name.clone(), Ty::Unknown)),
        TypedPat::Some_(inner) => collect_bindings(inner, out),
        TypedPat::Cons { head, tail } => {
            collect_bindings(head, out);
            collect_bindings(tail, out);
        }
        TypedPat::Tuple(pats) => pats.iter().for_each(|p| collect_bindings(p, out)),
        TypedPat::Constructor { fields, named_fields, .. } => {
            fields.iter().for_each(|p| collect_bindings(p, out));
            named_fields.iter().for_each(|(_, p)| collect_bindings(p, out));
        }
        TypedPat::As { var, pat } => {
            out.push((var.clone(), Ty::Unknown));
            collect_bindings(pat, out);
        }
        _ => {}
    }
}

// ── Typed statement IR ────────────────────────────────────────────────────────

#[derive(Debug, Clone)]
pub enum TypedStmt {
    /// `lhs := rhs;` — `lhs` may be any pattern (`x`, `(a,b)`, `SOME(x)`, `true`, …).
    Assign { lhs: TypedPat, rhs: TypedExp },
    /// A call statement with no return value (or value discarded).
    NoRetCall { call: TypedExp },
    If {
        cond: TypedExp,
        then_: Vec<TypedStmt>,
        elseif: Vec<(TypedExp, Vec<TypedStmt>)>,
        else_: Vec<TypedStmt>,
    },
    /// `for var in range loop body end for;` — single-iterator form only for now.
    For { var: String, range: TypedExp, body: Vec<TypedStmt> },
    While { cond: TypedExp, body: Vec<TypedStmt> },
    /// `try body else else_body end try;`
    Try { body: Vec<TypedStmt>, else_body: Vec<TypedStmt> },
    /// `failure(body)` — succeeds iff `body` fails.
    Failure { body: Vec<TypedStmt> },
    Return,
    Break,
    Continue,
    Todo(String),
}

/// True iff `comment` carries the boolean annotation `name=true`.
///
/// Mirrors `SCodeUtil.commentHasBooleanNamedAnnotation`: an Absyn annotation is
/// a list of `MODIFICATION` element-args; we look for one whose path is the
/// bare identifier `name` bound to the literal `true` (`name = true`).
pub(crate) fn comment_has_boolean_named_annotation(
    comment: &Option<Arc<Absyn::Comment>>,
    name: &str,
) -> bool {
    let Some(comment) = comment else { return false };
    let Some(annotation) = &comment.annotation_ else { return false };
    (&*annotation.elementArgs).into_iter().any(|arg| {
        let Absyn::ElementArg::MODIFICATION { path, modification, .. } = arg.as_ref() else {
            return false;
        };
        if !matches!(path.as_ref(), Absyn::Path::IDENT { name: n } if n == name) {
            return false;
        }
        let Some(modification) = modification else { return false };
        matches!(
            modification.eqMod.as_ref(),
            Absyn::EqMod::EQMOD { exp, .. }
                if matches!(exp.as_ref(), Absyn::Exp::BOOL { value: true })
        )
    })
}

/// Lower one algorithm item, appending the resulting statement(s) to `out`.
///
/// Almost every item lowers to a single statement. The exception is a
/// `try`/`else` block annotated with `__OpenModelica_stackOverflowCheckpoint=true`:
/// that annotation requests a stack-overflow recovery handler (the `else`
/// branch) which we deliberately do not model. We splice the `try` body
/// straight into the enclosing statement list — in the *same* scope, with no
/// `else` handler — so the code behaves exactly as if the body had been written
/// without any `try` wrapper. A nested annotated try (none exist today, but the
/// recursion costs nothing) is inlined the same way.
fn infer_stmt_into<'a>(
    out: &mut Vec<TypedStmt>,
    item: &Absyn::AlgorithmItem,
    env: &mut HashMap<String, Ty>,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
    type_vars: &[String],
) {
    if let Absyn::AlgorithmItem::ALGORITHMITEM { algorithm_, comment, .. } = item
        && let Absyn::Algorithm::ALG_TRY { body, .. } = algorithm_.as_ref()
        && comment_has_boolean_named_annotation(comment, "__OpenModelica_stackOverflowCheckpoint")
    {
        for it in (&**body).into_iter() {
            infer_stmt_into(out, it, env, top_level, pkg_prefix, type_vars);
        }
        return;
    }
    if let Some(s) = infer_stmt(item, env, top_level, pkg_prefix, type_vars) {
        out.push(s);
    }
}

/// Infer a list of algorithm items into typed statements, threading the env so that
/// each pattern-assign extends bindings visible to subsequent stmts.
pub fn infer_stmts<'a>(
    items: &[Arc<Absyn::AlgorithmItem>],
    env: &mut HashMap<String, Ty>,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
    type_vars: &[String],
) -> Vec<TypedStmt> {
    let mut out = Vec::new();
    for it in items {
        infer_stmt_into(&mut out, it, env, top_level, pkg_prefix, type_vars);
    }
    out
}

fn infer_stmt<'a>(
    item: &Absyn::AlgorithmItem,
    env: &mut HashMap<String, Ty>,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
    type_vars: &[String],
) -> Option<TypedStmt> {
    let alg = match item {
        Absyn::AlgorithmItem::ALGORITHMITEM { algorithm_, .. } => algorithm_.as_ref(),
        Absyn::AlgorithmItem::ALGORITHMITEMCOMMENT { .. } => return None,
    };
    Some(match alg {
        Absyn::Algorithm::ALG_ASSIGN { assignComponent, value } => {
            let rhs = infer_exp(value, env, top_level, pkg_prefix, type_vars);
            // The LHS of `:=` is a pattern (in MetaModelica, patterns and expressions share syntax).
            let lhs = infer_pat(assignComponent, env, top_level, pkg_prefix, type_vars);
            // Extend env from any *new* bindings introduced by the LHS.
            // Declared locals (outputs/protected) already have their authoritative
            // type recorded in env from the function-prelude pass; we must not
            // overwrite that with `rhs.ty()`, because the RHS type can be a raw
            // function-output TypeVar (e.g. `Mutable.access<T>(Mutable<T>) -> T`
            // returns `Ty::TypeVar("T")` without per-call substitution) and we
            // would lose the local's structural type (e.g. `list<T>`), breaking
            // downstream type-directed codegen such as for-loop iteration.
            //
            // For pattern-introduced names not yet in env (e.g. `x :: rest := lst`)
            // we still need an entry. The exact type derivation from the scrutinee
            // is left to later work; insert `Ty::Unknown` so codegen at least sees
            // the binding exists without overriding declared types elsewhere.
            for (name, _ty) in pat_bindings(&lhs) {
                env.entry(name).or_insert(Ty::Unknown);
            }
            TypedStmt::Assign { lhs, rhs }
        }
        Absyn::Algorithm::ALG_NORETCALL { functionCall, functionArgs } => {
            let func = cref_to_dotted(functionCall);
            let (args, named_args) = extract_call_args(functionArgs, env, top_level, pkg_prefix, type_vars);
            let sig_ty = lookup_ctor_ty(&func, top_level);
            let resolved = resolve_call_node(&func, top_level, pkg_prefix);
            let is_constructor = match &sig_ty {
                Ty::RustStruct(_) | Ty::RustEnum(_) => true,
                _ => {
                    if let Some((_, node)) = &resolved {
                        matches!(node.kind, NodeKind::Class(c) if matches!(c.restriction, Absyn::Restriction::R_RECORD | Absyn::Restriction::R_UNIONTYPE))
                    } else {
                        false
                    }
                }
            };
            let call = if is_constructor {
                let canonical = canonical_ctor_qname(&func, &resolved, top_level);
                let ty = match lookup_ty_in_hierarchy(&canonical, top_level) {
                    Ty::Function { output, .. } => *output,
                    other => other,
                };
                let field_names = match &sig_ty {
                    Ty::RustStruct(qname) | Ty::RustEnum(qname) => {
                        record_field_tys(qname, top_level).into_iter().map(|(n, _)| n).collect()
                    }
                    _ => {
                        record_field_tys(&canonical, top_level).into_iter().map(|(n, _)| n).collect()
                    }
                };
                TypedExp::Constructor { name: canonical, args, named_args, ty, field_names }
            } else {
                let ty = call_ty(&func, &args, top_level, pkg_prefix);
                TypedExp::Call { func, args, named_args, ty, sig_ty }
            };
            TypedStmt::NoRetCall { call }
        }
        Absyn::Algorithm::ALG_IF { ifExp, trueBranch, elseIfAlgorithmBranch, elseBranch } => {
            let cond = infer_exp(ifExp, env, top_level, pkg_prefix, type_vars);
            let then_ = infer_stmts_list(trueBranch, env, top_level, pkg_prefix, type_vars);
            let elseif: Vec<(TypedExp, Vec<TypedStmt>)> = (&**elseIfAlgorithmBranch).into_iter()
                .map(|(c, b)| (
                    infer_exp(c, env, top_level, pkg_prefix, type_vars),
                    infer_stmts_list(b, env, top_level, pkg_prefix, type_vars),
                ))
                .collect();
            let else_ = infer_stmts_list(elseBranch, env, top_level, pkg_prefix, type_vars);
            TypedStmt::If { cond, then_, elseif, else_ }
        }
        Absyn::Algorithm::ALG_FOR { iterators, forBody }
        | Absyn::Algorithm::ALG_PARFOR { iterators, parforBody: forBody } => {
            // Single-iterator form only.
            let iters: Vec<Arc<Absyn::ForIterator>> = (&**iterators).into_iter().cloned().collect();
            if iters.len() == 1 {
                let Absyn::ForIterator { name, range, .. } = &*iters[0];
                let range_e = match range {
                    Some(r) => infer_exp(r.as_ref(), env, top_level, pkg_prefix, type_vars),
                    None => TypedExp::Todo("for-without-range".to_owned()),
                };
                // Element type from list/array.
                let elem_ty = match range_e.ty() {
                    Ty::List(t) | Ty::Array(t) | Ty::Range(t) => *t,
                    _ => Ty::Unknown,
                };
                let mut inner = env.clone();
                inner.insert(name.to_string(), elem_ty);
                let body = infer_stmts_list(forBody, &mut inner, top_level, pkg_prefix, type_vars);
                TypedStmt::For { var: name.to_string(), range: range_e, body }
            } else {
                // Multi-iterator for: nested loops with the FIRST iterator
                // outermost (Modelica spec §11.2.2: `for i in A, j in B loop S`
                // is equivalent to `for i in A loop for j in B loop S`). Each
                // iterator's range is elaborated in the scope of the preceding
                // iterators, so a later range may depend on an earlier one.
                let mut inner = env.clone();
                let mut specs: Vec<(String, TypedExp)> = Vec::new();
                for it in &iters {
                    let Absyn::ForIterator { name, range, .. } = &**it;
                    let range_e = match range {
                        Some(r) => infer_exp(r.as_ref(), &inner, top_level, pkg_prefix, type_vars),
                        None => TypedExp::Todo("for-without-range".to_owned()),
                    };
                    let elem_ty = match range_e.ty() {
                        Ty::List(t) | Ty::Array(t) | Ty::Range(t) => *t,
                        _ => Ty::Unknown,
                    };
                    inner.insert(name.to_string(), elem_ty);
                    specs.push((name.to_string(), range_e));
                }
                let body = infer_stmts_list(forBody, &mut inner, top_level, pkg_prefix, type_vars);
                // Wrap from the innermost (last) iterator outward, so the first
                // iterator ends up as the outermost loop.
                let mut stmts = body;
                for (var, range) in specs.into_iter().rev() {
                    stmts = vec![TypedStmt::For { var, range, body: stmts }];
                }
                stmts.into_iter().next().expect("multi-iterator for has >1 iterator")
            }
        }
        Absyn::Algorithm::ALG_WHILE { boolExpr, whileBody } => {
            let cond = infer_exp(boolExpr, env, top_level, pkg_prefix, type_vars);
            let body = infer_stmts_list(whileBody, env, top_level, pkg_prefix, type_vars);
            TypedStmt::While { cond, body }
        }
        Absyn::Algorithm::ALG_TRY { body, elseBody } => {
            let mut benv = env.clone();
            let body = infer_stmts_list(body, &mut benv, top_level, pkg_prefix, type_vars);
            let mut eenv = env.clone();
            let else_body = infer_stmts_list(elseBody, &mut eenv, top_level, pkg_prefix, type_vars);
            TypedStmt::Try { body, else_body }
        }
        Absyn::Algorithm::ALG_FAILURE { equ } => {
            let mut fenv = env.clone();
            let body = infer_stmts_list(equ, &mut fenv, top_level, pkg_prefix, type_vars);
            TypedStmt::Failure { body }
        }
        Absyn::Algorithm::ALG_RETURN   => TypedStmt::Return,
        Absyn::Algorithm::ALG_BREAK    => TypedStmt::Break,
        Absyn::Algorithm::ALG_CONTINUE => TypedStmt::Continue,
        other => TypedStmt::Todo(format!("{other:?}").chars().take(60).collect()),
    })
}

fn infer_stmts_list<'a>(
    items: &std::sync::Arc<metamodelica::List<std::sync::Arc<Absyn::AlgorithmItem>>>,
    env: &mut HashMap<String, Ty>,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    pkg_prefix: &str,
    type_vars: &[String],
) -> Vec<TypedStmt> {
    let mut out = Vec::new();
    for it in (&**items).into_iter() {
        infer_stmt_into(&mut out, it, env, top_level, pkg_prefix, type_vars);
    }
    out
}

// ── Helpers ───────────────────────────────────────────────────────────────────

fn absyn_op_to_binop(op: &Absyn::Operator) -> BinOpKind {
    match op {
        Absyn::Operator::ADD | Absyn::Operator::ADD_EW => BinOpKind::Add,
        Absyn::Operator::SUB | Absyn::Operator::SUB_EW => BinOpKind::Sub,
        Absyn::Operator::MUL | Absyn::Operator::MUL_EW => BinOpKind::Mul,
        Absyn::Operator::DIV | Absyn::Operator::DIV_EW => BinOpKind::Div,
        Absyn::Operator::POW | Absyn::Operator::POW_EW => BinOpKind::Pow,
        Absyn::Operator::AND   => BinOpKind::And,
        Absyn::Operator::OR    => BinOpKind::Or,
        Absyn::Operator::EQUAL => BinOpKind::Eq,
        Absyn::Operator::NEQUAL   => BinOpKind::NEq,
        Absyn::Operator::LESS     => BinOpKind::Lt,
        Absyn::Operator::LESSEQ   => BinOpKind::LEq,
        Absyn::Operator::GREATER  => BinOpKind::Gt,
        Absyn::Operator::GREATEREQ => BinOpKind::GEq,
        _ => BinOpKind::Add,
    }
}
