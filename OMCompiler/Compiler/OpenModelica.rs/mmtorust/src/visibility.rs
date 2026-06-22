//! Cross-crate visibility analysis.
//!
//! Decides which generated `pub` functions and `constant`s must stay `pub` and
//! which can be narrowed to `pub(crate)`. Because `pub(crate)` is already
//! visible from everywhere inside the defining crate, an item needs full `pub`
//! only when it is reachable from a *different* crate. So this pass collects
//! every cross-crate reference in the generated program; an item not referenced
//! across a crate boundary (and not in the hand-written-export allow-list) is
//! narrowed to `pub(crate)`.
//!
//! Types (records / uniontypes / type aliases) are still always emitted `pub`:
//! narrowing them additionally requires propagating visibility through the
//! interface of every kept-public item (a `pub fn`/`pub struct` exposes its
//! signature/field types — Rust's `private_interfaces` rule), which this pass
//! does not yet do.
//!
//! ## What counts as keeping a function `pub`
//!
//!  * A call / partial-application / function-value reference whose resolved
//!    target lives in another crate (the bulk — direct cross-crate calls).
//!  * A function used as the default value of an `input` parameter: codegen
//!    expands such defaults at the *call site*, which may be in any crate, so
//!    the referenced function is conservatively kept public.
//!  * The base of a `function Foo = Bar(...)` alias: the alias is emitted as a
//!    `pub use … as …;` re-export, and `pub use` of a `pub(crate)` item is
//!    rejected (E0365). Keeping the base public makes the re-export valid
//!    regardless of where the alias is consumed.
//!  * The hand-written allow-list ([`HANDWRITTEN_EXPORTS`]): generated items
//!    that hand-written `.rs` files reference across a crate boundary. Those
//!    references live outside the MetaModelica hierarchy this pass walks, so
//!    they cannot be discovered automatically and are listed explicitly.
//!
//! Soundness note: missing a real cross-crate reference would narrow a function
//! that is actually used elsewhere, surfacing as a hard `E0603` at build time
//! (never as silent miscompilation); over-approximating merely leaves a
//! function `pub` that could have been `pub(crate)`. The analysis therefore
//! errs toward keeping functions public when a reference cannot be resolved.

use std::collections::{BTreeMap, BTreeSet};

use openmodelica_ast::Absyn;

use crate::hierarchy::{extract_default_exp, InstanceHierarchy, NameNode, NodeKind, Ty};
use crate::typedexp::resolve_call_node;
use crate::unused_functions::RefScan;
use crate::MM;

/// Generated items (by fully-qualified MetaModelica name) that hand-written
/// Rust code references across a crate boundary, and which must therefore stay
/// `pub`. These references are invisible to the MetaModelica hierarchy, so they
/// are declared here as upstream knowledge rather than discovered. Add an entry
/// whenever a hand-written `.rs` file gains a cross-crate use of a generated
/// function (an omission shows up as an `E0603` for a `pub(crate)` item named
/// from another crate's hand-written source).
const HANDWRITTEN_EXPORTS: &[&str] = &[
    // openmodelica/src/main.rs → the program entry point.
    "Main.main",
    // openmodelica_script_util/src/{DynLoadExt,SimulationResults,UnitParserExt,Unzip}.rs,
    // openmodelica_backend/src/SerializeSparsityPattern.rs, …/Curl.rs → error reporting.
    "Error.addMessage",
    // openmodelica_script_util/src/DynLoadExt.rs → diagnostics / flag access.
    "Error.getCurrentComponent",
    "AbsynUtil.pathString",
    "Flags.getFlags",
    // openmodelica_frontend/src/Globals.rs → global-state initialisers.
    "Flags.getConfigInt",
    "BaseHashTable.emptyHashTableWork",
    // openmodelica_util/src/Globals.rs → global-state initialiser.
    "DoubleEnded.fromList",
    // openmodelica_frontend_dump/src/unittests/*.rs → flag tables (constants).
    "FlagsUtil.allConfigFlags",
    "FlagsUtil.allDebugFlags",
];

/// Result of [`analyze`]: the set of function FQNs that must keep full `pub`
/// visibility. Every other `pub` function is narrowed to `pub(crate)`.
#[derive(Debug, Default, Clone)]
pub struct VisibilityInfo {
    pub keep_public: BTreeSet<String>,
}

impl VisibilityInfo {
    /// Whether the (public) function `qname` may be narrowed to `pub(crate)` —
    /// i.e. it is not reachable from another crate.
    pub fn fn_is_crate_local(&self, qname: &str) -> bool {
        !self.keep_public.contains(qname)
    }
}

fn is_function_node(node: &NameNode<'_>) -> bool {
    matches!(&node.kind, NodeKind::Class(c) if matches!(c.restriction, Absyn::Restriction::R_FUNCTION { .. }))
}

/// A `constant` component — emitted as `pub const`/`pub static`/`pub const fn`/
/// a `LazyLock` getter, whose visibility this pass also narrows.
fn is_const_node(node: &NameNode<'_>) -> bool {
    matches!(&node.kind, NodeKind::Component(m) if m.variability == Absyn::Variability::CONST)
}

/// True for any item whose generated visibility this pass narrows: free
/// functions and `constant`s. (Types/records/uniontypes are always emitted
/// `pub` for now — see the module docs.)
fn is_narrowable_item(node: &NameNode<'_>) -> bool {
    is_function_node(node) || is_const_node(node)
}

fn path_to_dotted(p: &Absyn::Path) -> String {
    match p {
        Absyn::Path::IDENT { name } => name.to_string(),
        Absyn::Path::QUALIFIED { name, path } => format!("{}.{}", name, path_to_dotted(path)),
        Absyn::Path::FULLYQUALIFIED { path } => path_to_dotted(path),
    }
}

/// The fully-qualified item paths a *specific-item* import brings into scope.
/// Codegen lowers each to a `use …::Item;` statement, so each is a real
/// reference even when the imported name is never otherwise used (e.g. an
/// import whose only uses sit in commented-out source). A whole-package
/// `import Pkg;` / wildcard `import Pkg.*;` names no specific item — its members
/// are reached through ordinary `Pkg.foo` calls that the body scan already
/// sees — so it contributes nothing here.
fn import_item_targets(import: &Absyn::Import) -> Vec<String> {
    match import {
        Absyn::Import::QUAL_IMPORT { path } | Absyn::Import::NAMED_IMPORT { path, .. } => {
            vec![path_to_dotted(path)]
        }
        Absyn::Import::GROUP_IMPORT { prefix, groups } => {
            let pfx = path_to_dotted(prefix);
            (&**groups).into_iter().map(|g| {
                let name = match g {
                    Absyn::GroupImport::GROUP_IMPORT_NAME { name }
                    | Absyn::GroupImport::GROUP_IMPORT_RENAME { name, .. } => name,
                };
                format!("{pfx}.{name}")
            }).collect()
        }
        // `import Pkg.*;` — a glob, not a specific item.
        Absyn::Import::UNQUAL_IMPORT { .. } => Vec::new(),
    }
}

/// Record that a reference (resolved to `target`/`node`) appearing in crate
/// `ref_crate` keeps its target public when it lives in another crate. Covers
/// both the directly-narrowable target (a function or constant) and the nominal
/// *types* the target's resolved type names — so a constructor or enum-variant
/// reference used as a value (`Op.ADD`, `SomeRecord(...)`) keeps the backing
/// enum/struct public even though it is named only in expression position.
fn keep_ref_target(
    target: &str,
    node: &NameNode<'_>,
    ref_crate: &str,
    crate_map: &BTreeMap<&str, &str>,
    keep_public: &mut BTreeSet<String>,
) {
    let crate_of = |q: &str| crate_map.get(q.split('.').next().unwrap_or(q)).copied();
    if is_narrowable_item(node) && crate_of(target).is_some_and(|c| c != ref_crate) {
        keep_public.insert(target.to_owned());
    }
    let mut tys: Vec<String> = Vec::new();
    ty_referenced_qnames(&node.ty, &mut tys);
    for u in tys {
        if crate_of(&u).is_some_and(|c| c != ref_crate) {
            keep_public.insert(u);
        }
    }
}

/// Compute the cross-crate visibility classification for every function.
pub fn analyze(hier: &InstanceHierarchy<'_>) -> VisibilityInfo {
    let top_level = &hier.top_level;

    // top-level package name → Rust crate name (mirrors the `crate_map` built
    // in `codegen::generate_all`). The crate owning any FQN is the crate of its
    // first dotted segment.
    let crate_map: BTreeMap<&str, &str> = top_level.iter()
        .filter_map(|(name, node)| match &node.kind {
            NodeKind::Class(c) => c.crate_name.as_deref().map(|cn| (name.as_str(), cn)),
            _ => None,
        })
        .collect();
    let crate_of = |qname: &str| -> Option<&str> {
        crate_map.get(qname.split('.').next().unwrap_or(qname)).copied()
    };

    let mut functions: Vec<(String, &NameNode<'_>)> = Vec::new();
    crate::codegen::collect_all_function_nodes(top_level, "", &mut functions);

    let mut keep_public: BTreeSet<String> = BTreeSet::new();

    for (qname, node) in &functions {
        let NodeKind::Class(class) = &node.kind else { continue };
        let Some(ref_crate) = crate_of(qname) else { continue };

        // Direct references in the body and in component default expressions: a
        // narrowable target (function/constant) — or a type named through a
        // constructor / enum-variant value — resolving into another crate keeps
        // it pub.
        for raw in &RefScan::scan_class(class).refs {
            if let Some((target, n)) = resolve_call_node(raw, top_level, qname) {
                keep_ref_target(&target, n, ref_crate, &crate_map, &mut keep_public);
            }
        }

        // `function Foo = Bar(...)` alias: its base is re-exported via `pub use`
        // and must stay `pub` (E0365). Resolve and keep it regardless of crate —
        // a same-crate base only ends up redundantly present, never wrongly so.
        if let Ty::FunctionAlias { base, .. } = &node.ty
            && let Some((target, n)) = resolve_call_node(base, top_level, qname)
            && is_function_node(n)
        {
            keep_public.insert(target);
        }

        // `input T f = <default>` — the default value (a function or a constant,
        // e.g. `input MatchOptions options = NFTypeCheck.DEFAULT_OPTIONS`) is
        // expanded at the caller's site, which may be in any crate. Keep it pub.
        let members = match &class.body {
            MM::ClassDef::Parts { members, .. } | MM::ClassDef::ClassExtends { members, .. } => members.as_slice(),
            _ => &[],
        };
        for m in members {
            let MM::ClassMember::Component(cm) = m else { continue };
            if cm.direction != Absyn::Direction::INPUT { continue; }
            let Some(default) = extract_default_exp(&cm.modification) else { continue };
            let mut scan = RefScan::default();
            scan.scan_exp(default);
            for raw in &scan.refs {
                if let Some((target, n)) = resolve_call_node(raw, top_level, qname)
                    && is_narrowable_item(n)
                {
                    keep_public.insert(target);
                }
            }
        }
    }

    // Package-level `constant`s have initialisers that the per-function scan
    // above does not reach (they are not inside any function body). Their
    // expressions reference other constants / functions, possibly across a
    // crate boundary, so scan every component's default initialiser.
    scan_component_defaults(top_level, top_level, "", &crate_map, &mut keep_public);

    // Specific-item imports (`import Pkg.{a,b}`, `import Pkg.X`, `import N = Pkg.X`),
    // declared at package or function scope, each lower to a `use …::Item;`
    // statement — a cross-crate reference even when the name is never otherwise
    // used. Walk every import and keep cross-crate function targets public.
    scan_imports(top_level, top_level, "", &crate_map, &mut keep_public);

    for &q in HANDWRITTEN_EXPORTS {
        keep_public.insert(q.to_owned());
    }

    // ── Types ────────────────────────────────────────────────────────────────
    // A generated type (record / uniontype / enumeration / type alias) is kept
    // `pub` when either:
    //   (a) it is referenced from another crate — directly named in a
    //       signature, field, local, alias target, … (the seed walk below), or
    //   (b) it is exposed through the public interface of a kept-public item:
    //       a `pub fn`'s signature types, a `pub` constant's type, a `pub`
    //       record's field types, a `pub` uniontype's variant field types, a
    //       `pub` alias's target — Rust's `private_interfaces` rule. This is a
    //       fixpoint: a type kept public by (b) in turn exposes its own
    //       interface types. (Single-record uniontypes stay `pub` regardless —
    //       see `Ty::AliasTo` handling — so this pass never narrows them.)
    seed_cross_crate_types(top_level, top_level, "", &crate_map, &mut keep_public);

    let mut worklist: Vec<String> = keep_public.iter().cloned().collect();
    while let Some(q) = worklist.pop() {
        let Some(node) = crate::hierarchy::lookup_node(&q, top_level) else { continue };
        let mut refs: Vec<String> = Vec::new();
        interface_qnames(node, &mut refs);
        for u in refs {
            // Only narrowable *types* are kept here; functions/constants are
            // already resolved above. `lookup_node` confirms `u` names a type
            // node (it always should, coming from `ty_referenced_qnames`).
            if keep_public.insert(u.clone()) {
                worklist.push(u);
            }
        }
    }

    VisibilityInfo { keep_public }
}

/// The nominal type FQNs a resolved [`Ty`] names. Containers/tuples/function
/// types are walked transitively. `Ty::AliasTo` (single-record uniontypes) is
/// skipped: those stay `pub` unconditionally, so a reference to one never
/// forces anything to stay public — which also sidesteps that variant carrying
/// only a simple (non-qualified) name.
fn ty_referenced_qnames(ty: &Ty, out: &mut Vec<String>) {
    match ty {
        Ty::RustStruct(q) | Ty::RustEnum(q) | Ty::Enumeration(q) | Ty::ExternalObject(q) => {
            out.push(q.clone());
        }
        Ty::UnionTypeVariant(union_q, _) => out.push(union_q.clone()),
        Ty::Generic(name, args) => {
            if name.contains('.') { out.push(name.clone()); }
            for a in args { ty_referenced_qnames(a, out); }
        }
        Ty::List(t) | Ty::Array(t) | Ty::Option(t) | Ty::Range(t) => ty_referenced_qnames(t, out),
        Ty::Tuple(ts) => for t in ts { ty_referenced_qnames(t, out); },
        Ty::Function { inputs, output, .. } => {
            for i in inputs { ty_referenced_qnames(&i.ty, out); }
            ty_referenced_qnames(output, out);
        }
        // Scalars, type vars, AliasTo, FunctionAlias, Unit, Unknown — no
        // narrowable nominal type to keep.
        _ => {}
    }
}

/// The type FQNs exposed through the public interface of `node`: a function's
/// signature, a constant's type, a record's field types, a uniontype's variant
/// field types, or a type alias's target.
fn interface_qnames(node: &NameNode<'_>, out: &mut Vec<String>) {
    match &node.kind {
        NodeKind::Class(c) => {
            use Absyn::Restriction::*;
            match &c.restriction {
                // Function: inputs + output (carried by the resolved `Function`
                // type). Protected locals are *not* part of the interface.
                R_FUNCTION { .. } => ty_referenced_qnames(&node.ty, out),
                // Uniontype: every variant record's fields.
                R_UNIONTYPE => {
                    for rec in node.children.values() {
                        if let NodeKind::Class(_) = &rec.kind {
                            for field in rec.children.values() {
                                if matches!(&field.kind, NodeKind::Component(_)) {
                                    ty_referenced_qnames(&field.ty, out);
                                }
                            }
                        }
                    }
                }
                // Record / metarecord: own fields.
                R_RECORD | R_METARECORD { .. } => {
                    for field in node.children.values() {
                        if matches!(&field.kind, NodeKind::Component(_)) {
                            ty_referenced_qnames(&field.ty, out);
                        }
                    }
                }
                // Type alias / enumeration / everything else: the resolved type
                // (alias target; enumerations expose nothing).
                _ => ty_referenced_qnames(&node.ty, out),
            }
        }
        // A constant component exposes its type.
        NodeKind::Component(_) => ty_referenced_qnames(&node.ty, out),
        _ => {}
    }
}

/// Seed `keep_public` with every type referenced across a crate boundary: walk
/// every node and, for each nominal type its resolved type names, keep that
/// type `pub` when it lives in a different crate than the referencing node.
fn seed_cross_crate_types<'a>(
    nodes: &BTreeMap<String, NameNode<'a>>,
    top_level: &BTreeMap<String, NameNode<'a>>,
    prefix: &str,
    crate_map: &BTreeMap<&str, &str>,
    keep_public: &mut BTreeSet<String>,
) {
    let crate_of = |qname: &str| -> Option<&str> {
        crate_map.get(qname.split('.').next().unwrap_or(qname)).copied()
    };
    for (name, node) in nodes {
        let qname = if prefix.is_empty() { name.clone() } else { format!("{prefix}.{name}") };
        if let Some(ref_crate) = crate_of(&qname) {
            let mut refs: Vec<String> = Vec::new();
            ty_referenced_qnames(&node.ty, &mut refs);
            for u in refs {
                if crate_of(&u).is_some_and(|c| c != ref_crate) {
                    keep_public.insert(u);
                }
            }
            // A derived type alias (`type X = Y`) is kept `pub` unconditionally:
            // codegen emits the *alias name* at use sites (via the syntactic
            // `TypeSpec`, recovered by `field_type_alias_name`) while the
            // resolved `Ty` shows only the underlying type, so a cross-crate
            // alias reference is invisible to this resolved-type analysis.
            // Keeping aliases public avoids that gap; the fixpoint then keeps the
            // alias target public too (no `private_interfaces`). Aliases are few,
            // so the lost narrowing is negligible.
            if matches!(&node.kind, NodeKind::Class(c) if matches!(&c.body, MM::ClassDef::Derived { .. })) {
                keep_public.insert(qname.clone());
            }
        }
        seed_cross_crate_types(&node.children, top_level, &qname, crate_map, keep_public);
    }
}

fn scan_component_defaults<'a>(
    nodes: &BTreeMap<String, NameNode<'a>>,
    top_level: &BTreeMap<String, NameNode<'a>>,
    prefix: &str,
    crate_map: &BTreeMap<&str, &str>,
    keep_public: &mut BTreeSet<String>,
) {
    let crate_of = |qname: &str| -> Option<&str> {
        crate_map.get(qname.split('.').next().unwrap_or(qname)).copied()
    };
    for (name, node) in nodes {
        let qname = if prefix.is_empty() { name.clone() } else { format!("{prefix}.{name}") };
        if let NodeKind::Component(m) = &node.kind
            && let Some(ref_crate) = crate_of(prefix)
            && let Some(exp) = node.override_default_exp.or_else(|| crate::hierarchy::extract_default_exp(&m.modification))
        {
            // Resolve references in the *enclosing* scope (the package/function
            // the constant is declared in), mirroring codegen's const lowering.
            let mut scan = RefScan::default();
            scan.scan_exp(exp);
            for raw in &scan.refs {
                if let Some((target, n)) = resolve_call_node(raw, top_level, prefix) {
                    keep_ref_target(&target, n, ref_crate, crate_map, keep_public);
                }
            }
        }
        scan_component_defaults(&node.children, top_level, &qname, crate_map, keep_public);
    }
}

fn scan_imports<'a>(
    nodes: &BTreeMap<String, NameNode<'a>>,
    top_level: &BTreeMap<String, NameNode<'a>>,
    prefix: &str,
    crate_map: &BTreeMap<&str, &str>,
    keep_public: &mut BTreeSet<String>,
) {
    let crate_of = |qname: &str| -> Option<&str> {
        crate_map.get(qname.split('.').next().unwrap_or(qname)).copied()
    };
    for (name, node) in nodes {
        let qname = if prefix.is_empty() { name.clone() } else { format!("{prefix}.{name}") };
        if let NodeKind::Import(m) = &node.kind
            && let Some(ref_crate) = crate_of(prefix)
        {
            for target in import_item_targets(&m.import) {
                // Resolve in the importing scope (handles relative imports and
                // import-alias chains, same as codegen's `use`-line emission).
                if let Some((q, n)) = resolve_call_node(&target, top_level, prefix) {
                    keep_ref_target(&q, n, ref_crate, crate_map, keep_public);
                }
            }
        }
        scan_imports(&node.children, top_level, &qname, crate_map, keep_public);
    }
}
