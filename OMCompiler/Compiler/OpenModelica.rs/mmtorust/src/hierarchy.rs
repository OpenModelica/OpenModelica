#![allow(unused)]

use std::collections::{BTreeMap, BTreeSet};
use std::fmt;
use std::sync::Arc;
use openmodelica_ast::Absyn;
use crate::MM;

// ── Ty ───────────────────────────────────────────────────────────────────────

/// One input parameter of a function: name, resolved type, and optional default expression.
#[derive(Debug, Clone, PartialEq)]
pub struct FunctionInput {
    pub name: String,
    pub ty: Ty,
    pub default: Option<String>,
}

/// The resolved type of a named entity, populated during type-checking passes.
#[derive(Debug, Clone, PartialEq, Default)]
pub enum Ty {
    #[default]
    Unknown,
    /// Modelica `Integer` → Rust `i32`
    I32,
    /// Modelica `Real` → Rust `f64`
    F64,
    /// Modelica `Boolean` → Rust `bool`
    Bool,
    /// Modelica `String` → Rust `String`
    Str,
    /// An enumeration type; carries its qualified class name.
    Enumeration(String),
    /// A polymorphic type parameter declared with `replaceable type T subtypeof Any`.
    TypeVar(String),
    /// `Option<T>`
    Option(Box<Ty>),
    /// Modelica `list<T>` → Rust `Vec<T>`
    List(Box<Ty>),
    /// Modelica `array<T>`
    Array(Box<Ty>),
    /// A Modelica range expression `start:stop` or `start:step:stop`.
    /// Carries the element type. Only valid as the type of `TypedExp::Range` —
    /// represents a Rust iterator value, not a materialised collection.
    /// Must be consumed in-place (for-loop, reduction iterator). Flowing
    /// into an Array/List context requires explicit materialisation.
    Range(Box<Ty>),
    /// Multiple values (multiple output components of a function).
    Tuple(Vec<Ty>),
    /// No output.
    Unit,
    /// A resolved function type. `inputs` carries names and optional defaults.
    ///
    /// `name` is set when the function type was *introduced* by a `partial function`
    /// declaration (e.g. `partial function KeyEq` inside `uniontype UnorderedSet<T>`).
    /// It carries the fully-qualified name of that declaration so that downstream
    /// codegen can emit the named type alias (`KeyEq<T>`) at use sites instead of
    /// inlining the raw `fn(...) -> Result<...>` signature. For ordinary functions
    /// (non-partial, or anonymous function types) this is `None` and codegen falls
    /// back to the structural representation.
    Function {
        type_vars: Vec<String>,
        inputs: Vec<FunctionInput>,
        output: Box<Ty>,
        name: Option<String>,
    },
    /// `function Foo = Bar(param=default)` — a named alias of another function with optional
    /// default-argument overrides. `modifications` is `(param_name, expr_string)` pairs.
    FunctionAlias {
        base: String,
        modifications: Vec<(String, String)>,
    },
    /// A metarecord with fields — maps to a Rust struct. Carries its qualified name.
    RustStruct(String),
    /// A metarecord with no fields — maps to a unit enum variant, not a struct.
    RustUnitVariant,
    /// A uniontype with ≥2 records — maps to a Rust enum. Carries its qualified name.
    RustEnum(String),
    /// A single-record uniontype — transparent alias to the sole record.
    /// Carries the simple name of that record.
    AliasTo(String),
    /// A record/variant inside a multi-record uniontype (Rust enum).
    /// Rust cannot import through enums, so we emit `UnionType::VariantName`.
    /// Carries (uniontype_qualified_name, variant_simple_name).
    UnionTypeVariant(String, String),
    /// A user-defined parameterized type with resolved type arguments, e.g. `ExpandableArray<T>`.
    Generic(String, Vec<Ty>),
    /// An external object class — a class with R_CLASS that extends ExternalObject.
    /// Treated as an opaque nominal type in Rust; the qualified path is significant.
    ExternalObject(String),
}

impl fmt::Display for Ty {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Ty::Unknown => f.write_str("?"),
            Ty::I32 => f.write_str("i32"),
            Ty::F64 => f.write_str("f64"),
            Ty::Bool => f.write_str("bool"),
            Ty::Str => f.write_str("String"),
            Ty::Enumeration(name) => f.write_str(&name.replace('.', "::")),
            Ty::TypeVar(name) => write!(f, "{name}"),
            Ty::Option(inner) => write!(f, "Option<{inner}>"),
            Ty::List(inner) => write!(f, "List<{inner}>"),
            Ty::Array(inner) => write!(f, "Array<{inner}>"),
            Ty::Range(inner) => write!(f, "Range<{inner}>"),
            Ty::Unit => f.write_str("()"),
            Ty::Tuple(tys) => {
                f.write_str("(")?;
                for (i, ty) in tys.iter().enumerate() {
                    if i > 0 { f.write_str(", ")?; }
                    write!(f, "{ty}")?;
                }
                f.write_str(")")
            }
            Ty::Function { type_vars, inputs, output, name: _ } => {
                if !type_vars.is_empty() {
                    write!(f, "<{}>", type_vars.join(", "))?;
                }
                f.write_str("fn(")?;
                for (i, inp) in inputs.iter().enumerate() {
                    if i > 0 { f.write_str(", ")?; }
                    write!(f, "{}", inp.ty)?;
                }
                write!(f, ") -> {output}")
            }
            Ty::FunctionAlias { base, modifications } => {
                write!(f, "= {base}")?;
                if !modifications.is_empty() {
                    write!(f, "(")?;
                    for (i, (k, v)) in modifications.iter().enumerate() {
                        if i > 0 { write!(f, ", ")?; }
                        write!(f, "{k}={v}")?;
                    }
                    write!(f, ")")?;
                }
                Ok(())
            }
            Ty::RustStruct(name) => f.write_str(&name.replace('.', "::")),
            Ty::RustUnitVariant => f.write_str("unit variant"),
            Ty::RustEnum(name) => f.write_str(&name.replace('.', "::")),
            Ty::AliasTo(name) => write!(f, "= {}", name.replace('.', "::")),
            Ty::UnionTypeVariant(union_qname, variant) => {
                write!(f, "{}::{}", union_qname.replace('.', "::"), variant)
            }
            Ty::Generic(name, args) => {
                write!(f, "{name}<")?;
                for (i, ty) in args.iter().enumerate() {
                    if i > 0 { write!(f, ", ")?; }
                    write!(f, "{ty}")?;
                }
                write!(f, ">")
            }
            Ty::ExternalObject(name) => write!(f, "ExternalObject<{}>", name.replace('.', "::")),
        }
    }
}

// ── NodeKind ──────────────────────────────────────────────────────────────────

#[derive(Debug, Clone)]
pub enum NodeKind<'a> {
    Class(&'a MM::Class),
    Component(&'a MM::ComponentMember),
    /// A single import statement; the map key is the locally introduced name.
    Import(&'a MM::ImportMember),
    /// One literal inside an `enumeration(...)` body.
    EnumLiteral,
}

// ── NameNode ──────────────────────────────────────────────────────────────────

#[derive(Debug, Clone)]
pub struct NameNode<'a> {
    pub kind: NodeKind<'a>,
    pub ty: Ty,
    pub children: BTreeMap<String, NameNode<'a>>,
    /// Extends clauses — no local name, but must be followed during lookup.
    pub extends: Vec<&'a MM::ExtendsMember>,
    pub visibility: MM::Visibility,
    /// For functions with a `ClassExtends` body (`function extends Foo`): the base
    /// function's `MM::Class` whose input/output declarations we inherit.  Set by
    /// `flatten_extends` so that `resolve_function_type` can re-resolve the signature
    /// in the derived class's type context.
    pub base_fn: Option<&'a MM::Class>,
    /// Override for the default value of a `Component` node, applied by a parent
    /// package's `extends Base(field=expr)` modification. When set, codegen uses
    /// this expression instead of the underlying `m.modification` from the AST.
    /// Only meaningful when `kind` is `NodeKind::Component`.
    pub override_default_exp: Option<&'a Absyn::Exp>,
}

impl<'a> NameNode<'a> {
    fn new(kind: NodeKind<'a>) -> Self {
        Self { kind, ty: Ty::default(), children: BTreeMap::new(), extends: Vec::new(), visibility: MM::Visibility::Public, base_fn: None, override_default_exp: None }
    }
}

// ── InstanceHierarchy ─────────────────────────────────────────────────────────

#[derive(Debug)]
pub struct InstanceHierarchy<'a> {
    pub top_level: BTreeMap<String, NameNode<'a>>,
    /// Fully-qualified names of types that form size-recursive cycles in Rust.
    /// Populated by `detect_recursive_types` after resolve_pass converges.
    pub recursive_types: BTreeSet<String>,
    /// Fully-qualified names of user-defined struct/enum types that transitively
    /// embed a `Mutable<T>` (= `Arc<Mutex<T>>`) field. `Mutex<T>` does not implement
    /// `PartialEq` / `Eq` / `Hash`, so these types must not request those derives —
    /// the generated `#[derive(...)]` would otherwise fail to compile. Propagation
    /// also follows container types (`Option`, `List`, `Array`, `Tuple`, `Generic`)
    /// because `#[derive(PartialEq)]` on a struct uses the concrete field types
    /// directly: a field of type `List<MyOther>` still needs `MyOther: PartialEq`
    /// for the derive to apply.
    /// Populated by `detect_types_containing_mutable` after resolve_pass converges.
    pub types_containing_mutable: BTreeSet<String>,
    /// Fully-qualified names of user-defined struct/enum types that transitively
    /// embed a MetaModelica `Array<T>` (= `Rc<RefCell<Vec<T>>>`) field. `Rc`/`RefCell`
    /// are not `Sync`, so values whose type is in this set cannot be stored in a
    /// `pub static` (which requires `T: Sync`). Codegen uses this to choose between
    /// `pub static` and `pub const fn` getter emission for constant components.
    /// Propagation follows the same container rules as
    /// [`Self::types_containing_mutable`].
    pub types_containing_array: BTreeSet<String>,
    /// Fully-qualified names of user-defined struct/enum types that
    /// transitively embed a function-typed field — i.e. one lowered to
    /// `Arc<dyn Fn(...) + 'static>` by codegen (see `fmt_param_ty`).
    /// `dyn Fn` implements none of Debug / PartialEq / Eq / PartialOrd /
    /// Ord / Hash, so a `#[derive]`-generated impl on a containing type
    /// fails to compile. `Arc<dyn Fn>` (without `+ Send + Sync`) is also
    /// not `Sync`, so containing values cannot live in a plain `pub
    /// static`. Codegen consults this set in `derives_for` (drop
    /// affected derives) and via `ty_is_sync` in `emit_node` (emit
    /// `thread_local! + getter` rather than `pub static LazyLock<T>`).
    /// Propagation follows the same container rules as
    /// [`Self::types_containing_mutable`].
    pub types_containing_dyn_fn: BTreeSet<String>,
    /// Subset of [`Self::types_containing_dyn_fn`]: types whose *own*
    /// fields/variants directly reference a function type without going
    /// through another user-defined struct/enum. These need a hand-rolled
    /// trait impl block (Debug / PartialEq / Eq / PartialOrd / Ord / Hash)
    /// that handles the `Arc<dyn Fn>` field(s) via pointer identity;
    /// codegen emits `#[derive(Clone)]` on the type itself and the impl
    /// block separately. Transitive (indirect) containers still get the
    /// full `#[derive(...)]` set because their dependent types already
    /// provide the impls via this hand-rolled emission.
    pub types_directly_containing_dyn_fn: BTreeSet<String>,
    /// Fully-qualified names of every user-defined function that the
    /// fallibility analysis classified as fallible (i.e. lowers to a Rust
    /// function returning `anyhow::Result<T>`).  Functions absent from this
    /// set are infallible and lower to a bare `T`.
    ///
    /// Populated by [`crate::fallibility::analyze`] after both
    /// [`detect_recursive_types`] and [`detect_types_containing_mutable`] have
    /// converged. Empty until then.
    pub fallible_functions: BTreeSet<String>,
    /// Fully-qualified names of every public function that must keep full `pub`
    /// visibility because it is reachable from another crate; every other
    /// public function is narrowed to `pub(crate)`. Populated by
    /// [`crate::visibility::analyze`]. Empty until then.
    pub keep_public: BTreeSet<String>,
    /// Per-function set of type-parameter names that need a `+ PartialEq`
    /// bound in the emitted Rust signature.
    ///
    /// Key: the function's fully-qualified MM name (same convention as
    /// `fallible_functions`). Value: names of type parameters declared on
    /// that function whose value gets compared via `==` / `!=`, passed to
    /// a `PartialEq`-requiring builtin (`valueEq`, `listMember`,
    /// `referenceEq`), or forwarded into another user function whose
    /// matching type parameter already needs `PartialEq` (transitive
    /// propagation, computed by fixed-point).
    ///
    /// Type parameters absent from this set are emitted with `Clone +
    /// 'static` only — so callers can forward non-`PartialEq` values
    /// (notably `&impl Fn(...)` callbacks) through generic helpers like
    /// `List::map3(.., extra_arg, ..)` without tripping a bound.
    ///
    /// Populated by [`crate::partial_eq_analysis::analyze`] after
    /// [`crate::fallibility::analyze`].
    pub partial_eq_required: BTreeMap<String, std::collections::HashSet<String>>,
    /// Per-function set of type-parameter names that need a `+ Default`
    /// bound, populated by [`crate::codegen::analyze_default`].  Companion to
    /// [`Self::partial_eq_required`] — same shape, different bound; required
    /// because `arrayCreateNoInit(size, <unassigned dummy>)` lowers to
    /// `arrayCreateDefault(size)` which requires `A: Default`.
    pub default_required: BTreeMap<String, std::collections::HashSet<String>>,
    /// Per-function set of type-parameter names that need a
    /// `+ metamodelica::ReferenceEq` bound, populated by
    /// [`crate::codegen::analyze_reference_eq`].  Companion to
    /// [`Self::partial_eq_required`] — same shape, different bound; required
    /// because `referenceEq(a, b)` on operands of opaque (type-variable)
    /// type lowers to a `metamodelica::ReferenceEq::reference_eq` trait
    /// call.
    pub reference_eq_required: BTreeMap<String, std::collections::HashSet<String>>,
}

impl<'a> InstanceHierarchy<'a> {
    pub fn from_program(program: &'a MM::Program) -> Self {
        let top_level = program
            .iter()
            .map(|class| (class.name.clone(), build_class_node(class)))
            .collect();
        Self {
            top_level,
            recursive_types: BTreeSet::new(),
            types_containing_mutable: BTreeSet::new(),
            types_containing_array: BTreeSet::new(),
            types_containing_dyn_fn: BTreeSet::new(),
            types_directly_containing_dyn_fn: BTreeSet::new(),
            fallible_functions: BTreeSet::new(),
            keep_public: BTreeSet::new(),
            partial_eq_required: BTreeMap::new(),
            default_required: BTreeMap::new(),
            reference_eq_required: BTreeMap::new(),
        }
    }
}

// ── Extends flattening ────────────────────────────────────────────────────────

/// Clone a NameNode with all resolved types reset to Unknown so that the seeding
/// and resolution passes re-run correctly in the derived class's context.
fn clone_and_reset<'a>(node: &NameNode<'a>) -> NameNode<'a> {
    NameNode {
        kind: node.kind.clone(),
        ty: Ty::Unknown,
        children: node.children.iter().map(|(k, v)| (k.clone(), clone_and_reset(v))).collect(),
        extends: node.extends.clone(),
        visibility: node.visibility.clone(),
        base_fn: None,
        override_default_exp: None,
    }
}

/// Flatten `extends` clauses for all packages: copy missing children from
/// the base class into the derived class so that type resolution and codegen see a
/// fully-populated hierarchy.  Must be called **before** `resolve_pass`.
///
/// Handles top-level packages and packages nested one level inside a top-level package,
/// as long as the base class is itself a top-level class.
pub fn flatten_extends(hier: &mut InstanceHierarchy<'_>) {
    let names: Vec<String> = hier.top_level.keys().cloned().collect();
    let mut visited: std::collections::HashSet<String> = std::collections::HashSet::new();
    for name in names {
        flatten_package_node(&name, &mut hier.top_level, &mut visited);
    }
    flatten_nested_package_extends(&mut hier.top_level);
    flatten_sibling_package_extends(&mut hier.top_level);
}

/// Flatten `extends` for nested packages whose base is another *sibling* package
/// living in the same parent. Without this, derived packages such as
/// `CompareWithoutSubscripts extends CompareWithGenericSubscript(...)` end up as
/// empty `pub mod {}` blocks because neither `flatten_package_node` (top-level)
/// nor `flatten_nested_package_extends` (top-level base) sees them.
///
/// Behaviour:
///   * Copy children of the base into the derived package, but only those the
///     derived doesn't already declare locally (a local declaration with the
///     same name is treated as an override).
///   * Apply `extends Base(field=expr)` modifications to the copied components
///     by setting `override_default_exp` on the matching child node — codegen
///     reads that field to override the component's initial value. This makes
///     the derived package's constant pick up the modified value instead of
///     the base's, which is essential when functions inherited from the base
///     read the constant by simple name (Rust name resolution finds the
///     overridden one in the derived module first).
fn flatten_sibling_package_extends<'a>(top_level: &mut BTreeMap<String, NameNode<'a>>) {
    let parent_names: Vec<String> = top_level.keys().cloned().collect();
    for parent_name in &parent_names {
        // Build the per-parent worklist: for each child with `extends` whose
        // base is a *sibling* of the child (i.e. another child of this parent
        // resolvable by the bare path written in `extends`), record the work.
        // The base resolution here only accepts a single-segment path matching
        // a sibling; nested or fully-qualified paths fall back to the other
        // flatten passes.
        let work: Vec<(String, String, &'a MM::ExtendsMember)> = {
            let Some(parent) = top_level.get(parent_name.as_str()) else { continue };
            let sibling_names: std::collections::HashSet<&str> =
                parent.children.keys().map(|s| s.as_str()).collect();
            let mut out = Vec::new();
            for (child_name, child) in &parent.children {
                for ext in &child.extends {
                    let base_path = fmt_path(&ext.path);
                    let base_simple = base_path.trim_start_matches('.');
                    // Single-segment path that resolves to a sibling.
                    if !base_simple.contains('.') && sibling_names.contains(base_simple)
                        && base_simple != child_name {
                        out.push((child_name.clone(), base_simple.to_owned(), *ext));
                    }
                }
            }
            out
        };

        for (child_name, base_name, ext) in work {
            // Phase 1: collect missing children to copy from base.
            let to_copy: Vec<(String, NameNode<'a>)> = {
                let parent = top_level.get(parent_name.as_str()).unwrap();
                let base = parent.children.get(base_name.as_str()).unwrap();
                let child = parent.children.get(child_name.as_str()).unwrap();
                base.children.iter()
                    .filter(|(cn, _)| !child.children.contains_key(cn.as_str()))
                    .map(|(cn, n)| (cn.clone(), clone_and_reset(n)))
                    .collect()
            };

            // Phase 2: insert copies, then apply modifications by setting
            // override_default_exp on each targeted component child.
            let parent_mut = top_level.get_mut(parent_name.as_str()).unwrap();
            let child_mut = parent_mut.children.get_mut(child_name.as_str()).unwrap();
            for (cn, n) in to_copy {
                child_mut.children.insert(cn, n);
            }
            for arg in &ext.element_args {
                let Absyn::ElementArg::MODIFICATION { path, modification, .. } = arg else {
                    // REDECLARATION / INHERITANCEBREAK / ELEMENTARGCOMMENT are
                    // not yet supported here — they would require structural
                    // overrides beyond a simple value swap. Leave as a no-op
                    // so the existing codegen surfaces any resulting mismatch
                    // at the use site rather than silently miscompiling.
                    continue;
                };
                // Only handle single-segment modification paths
                // (`compareSubscript = ...`); a dotted path would target a
                // sub-component and is not exercised by the current corpus.
                let target_name = match &**path {
                    Absyn::Path::IDENT { name } => name.to_string(),
                    _ => continue,
                };
                let Some(target) = child_mut.children.get_mut(&target_name) else { continue };
                let Some(modif) = modification.as_ref() else { continue };
                if let Absyn::Modification { eqMod, .. } = &**modif
                    && let Absyn::EqMod::EQMOD { exp, .. } = &**eqMod {
                    target.override_default_exp = Some(&**exp);
                }
            }
        }
    }
}

/// Flatten `extends` for packages nested one level inside a top-level package,
/// where the base class is a top-level class. Same two-phase copy logic as
/// `flatten_package_node`; the immutable borrow of the base (a different top-level
/// key) and the mutable borrow of the parent are non-overlapping.
fn flatten_nested_package_extends<'a>(top_level: &mut BTreeMap<String, NameNode<'a>>) {
    let parent_names: Vec<String> = top_level.keys().cloned().collect();
    for parent_name in &parent_names {
        // Collect (child_name, base_paths) for children that extend a top-level base.
        let work: Vec<(String, Vec<String>)> = {
            let Some(parent) = top_level.get(parent_name.as_str()) else { continue };
            parent.children.iter()
                .filter(|(_, child)| !child.extends.is_empty())
                .map(|(child_name, child)| {
                    let bases = child.extends.iter()
                        .map(|e| fmt_path(&e.path).trim_start_matches('.').to_owned())
                        .filter(|base| top_level.contains_key(base.as_str()))
                        .collect();
                    (child_name.clone(), bases)
                })
                .collect()
        };

        for (child_name, base_paths) in work {
            for base_path in &base_paths {
                // Phase 1: collect children to copy and base_fn links to establish.
                let to_copy: Vec<(String, NameNode<'a>)>;
                let base_fn_updates: Vec<(String, &'a MM::Class)>;
                {
                    let base = top_level.get(base_path.as_str()).unwrap();
                    let child = top_level.get(parent_name.as_str())
                        .and_then(|p| p.children.get(child_name.as_str()))
                        .unwrap();
                    to_copy = base.children.iter()
                        .filter(|(cn, _)| !child.children.contains_key(cn.as_str()))
                        .map(|(cn, node)| (cn.clone(), clone_and_reset(node)))
                        .collect();
                    base_fn_updates = child.children.iter()
                        .filter_map(|(cn, child_node)| {
                            if let NodeKind::Class(c) = &child_node.kind
                                && let MM::ClassDef::ClassExtends { base_class_name, .. } = &c.body
                                    && let Some(base_fn_node) = base.children.get(base_class_name.as_str())
                                        && let NodeKind::Class(base_c) = &base_fn_node.kind
                                            && is_function_class(&base_c.restriction) {
                                                return Some((cn.clone(), *base_c));
                                            }
                            None
                        })
                        .collect();
                }

                // Phase 2: apply.
                let child = top_level.get_mut(parent_name.as_str())
                    .and_then(|p| p.children.get_mut(child_name.as_str()))
                    .unwrap();
                for (cn, base_c) in base_fn_updates {
                    if let Some(c) = child.children.get_mut(&cn) {
                        c.base_fn = Some(base_c);
                    }
                }
                for (cn, node) in to_copy {
                    child.children.insert(cn, node);
                }
            }
        }
    }
}

fn flatten_package_node<'a>(
    name: &str,
    top_level: &mut BTreeMap<String, NameNode<'a>>,
    visited: &mut std::collections::HashSet<String>,
) {
    if !visited.insert(name.to_owned()) {
        return;
    }

    let extends_paths: Vec<String> = top_level.get(name)
        .map(|n| n.extends.iter().map(|e| fmt_path(&e.path).trim_start_matches('.').to_owned()).collect())
        .unwrap_or_default();

    for base_path in &extends_paths {
        // Flatten base first (handles transitive extends chains).
        flatten_package_node(base_path, top_level, visited);

        // Phase 1: collect children to copy (those absent in the current node) and
        //          base_fn assignments for ClassExtends functions already present.
        let to_copy: Vec<(String, NameNode<'a>)>;
        let base_fn_updates: Vec<(String, &'a MM::Class)>;
        {
            let base = top_level.get(base_path.as_str());
            let current = top_level.get(name);
            match (current, base) {
                (Some(cur), Some(base_node)) => {
                    to_copy = base_node.children.iter()
                        .filter(|(cn, _)| !cur.children.contains_key(cn.as_str()))
                        .map(|(cn, child)| (cn.clone(), clone_and_reset(child)))
                        .collect();

                    // For each ClassExtends function already in the current node, find
                    // the corresponding function in the base class and record it.
                    base_fn_updates = cur.children.iter()
                        .filter_map(|(cn, child_node)| {
                            if let NodeKind::Class(c) = &child_node.kind
                                && let MM::ClassDef::ClassExtends { base_class_name, .. } = &c.body
                                    && let Some(base_fn_node) = base_node.children.get(base_class_name.as_str())
                                        && let NodeKind::Class(base_c) = &base_fn_node.kind
                                            && is_function_class(&base_c.restriction) {
                                                return Some((cn.clone(), *base_c));
                                            }
                            None
                        })
                        .collect()
                }
                _ => { to_copy = vec![]; base_fn_updates = vec![]; }
            }
        }

        // Phase 2: apply the collected updates.
        if let Some(cur_node) = top_level.get_mut(name) {
            for (cn, base_c) in base_fn_updates {
                if let Some(child) = cur_node.children.get_mut(&cn) {
                    child.base_fn = Some(base_c);
                }
            }
            for (cn, child) in to_copy {
                cur_node.children.insert(cn, child);
            }
        }
    }
}

// ── Building ──────────────────────────────────────────────────────────────────

fn build_class_node(class: &MM::Class) -> NameNode<'_> {
    let mut node = NameNode::new(NodeKind::Class(class));
    populate_from_class_def(&class.body, &mut node);
    node
}

fn populate_from_class_def<'a>(def: &'a MM::ClassDef, node: &mut NameNode<'a>) {
    let members: &[MM::ClassMember] = match def {
        MM::ClassDef::Parts { members, .. } => members,
        MM::ClassDef::ClassExtends { members, .. } => members,
        MM::ClassDef::Enumeration { enum_literals, .. } => {
            if let Absyn::EnumDef::ENUMLITERALS { enumLiterals } = &**enum_literals {
                for lit in &**enumLiterals {
                    let Absyn::EnumLiteral { literal, .. } = &**lit;
                    node.children.insert(literal.to_string(), NameNode::new(NodeKind::EnumLiteral));
                }
            }
            return;
        }
        MM::ClassDef::Derived { .. } => return,
    };

    for member in members {
        match member {
            MM::ClassMember::ClassDef(m) => {
                let mut child = build_class_node(&m.class_def);
                child.visibility = m.visibility.clone();
                node.children.insert(m.class_def.name.clone(), child);
            }
            MM::ClassMember::Component(m) => {
                node.children.insert(m.name.clone(), NameNode::new(NodeKind::Component(m)));
            }
            MM::ClassMember::Import(m) => {
                for (local_name, child_node) in import_nodes(m) {
                    node.children.insert(local_name, child_node);
                }
            }
            MM::ClassMember::Extends(m) => {
                node.extends.push(m);
            }
            MM::ClassMember::LexerComment(_) => {}
        }
    }
}

fn import_nodes(m: &MM::ImportMember) -> Vec<(String, NameNode<'_>)> {
    let node = || NameNode::new(NodeKind::Import(m));
    match &m.import {
        Absyn::Import::NAMED_IMPORT { name, .. } => vec![(name.to_string(), node())],
        Absyn::Import::QUAL_IMPORT { path } => vec![(path_last(path).to_owned(), node())],
        Absyn::Import::UNQUAL_IMPORT { .. } => vec![("*".to_owned(), node())],
        Absyn::Import::GROUP_IMPORT { groups, .. } => (&**groups)
            .into_iter()
            .map(|g| {
                let local = match g {
                    Absyn::GroupImport::GROUP_IMPORT_NAME { name } => name.to_string(),
                    Absyn::GroupImport::GROUP_IMPORT_RENAME { rename, .. } => rename.to_string(),
                };
                (local, node())
            })
            .collect(),
    }
}

// ── Type-variable helpers ─────────────────────────────────────────────────────

fn type_spec_path(ts: &Absyn::TypeSpec) -> &Absyn::Path {
    match ts {
        Absyn::TypeSpec::TPATH { path, .. } => path,
        Absyn::TypeSpec::TCOMPLEX { path, .. } => path,
    }
}

/// Both `replaceable type T subtypeof Any` (TPATH) and `type T = polymorphic<Any>` (TCOMPLEX)
/// declare a type variable.
fn is_type_var_decl(class: &MM::Class) -> bool {
    if !matches!(class.restriction, Absyn::Restriction::R_TYPE) {
        return false;
    }
    match &class.body {
        MM::ClassDef::Derived { type_spec, .. } => match &**type_spec {
            Absyn::TypeSpec::TPATH { path, .. } => path_last(path) == "Any",
            Absyn::TypeSpec::TCOMPLEX { path, .. } => path_last(path) == "polymorphic",
        },
        _ => false,
    }
}

/// Collect all type-variable names declared in a class:
/// from `<T, U>` (typeVars list), `replaceable type T subtypeof Any`, and `type T = polymorphic<Any>`.
pub fn class_type_vars(c: &MM::Class) -> Vec<String> {
    match &c.body {
        MM::ClassDef::Parts { type_vars, members, .. } => {
            let mut vars: Vec<String> = type_vars.clone();
            for m in members {
                if let MM::ClassMember::ClassDef(cdm) = m
                    && is_type_var_decl(&cdm.class_def) {
                        vars.push(cdm.class_def.name.clone());
                    }
            }
            vars
        }
        _ => vec![],
    }
}

fn is_function_class(r: &Absyn::Restriction) -> bool {
    matches!(r, Absyn::Restriction::R_FUNCTION { .. })
}

/// Returns the simple names of all direct record children of a uniontype node.
/// The mmwinnow parser assigns `R_RECORD` (not `R_METARECORD`) to every `record`
/// declaration, so we identify records by restriction and by being a direct class child.
fn record_child_names(node: &NameNode<'_>) -> Vec<String> {
    node.children
        .iter()
        .filter_map(|(name, child)| {
            if let NodeKind::Class(c) = &child.kind
                && matches!(c.restriction, Absyn::Restriction::R_RECORD | Absyn::Restriction::R_METARECORD { .. }) {
                    return Some(name.clone());
                }
            None
        })
        .collect()
}

fn has_component_children(node: &NameNode<'_>) -> bool {
    node.children.values().any(|c| matches!(c.kind, NodeKind::Component(_)))
}

/// Returns true if a uniontype node has any children that are not records — e.g. functions,
/// nested packages, constants. When true, the uniontype needs a `pub mod` wrapper so those
/// members are reachable as `TypeName::function_name`. When false (records only), the wrapper
/// is unnecessary and can be omitted.
pub fn uniontype_needs_mod(node: &NameNode<'_>) -> bool {
    node.children.values().any(|child| {
        if let NodeKind::Class(c) = &child.kind {
            !matches!(c.restriction, Absyn::Restriction::R_RECORD | Absyn::Restriction::R_METARECORD { .. })
        } else {
            false
        }
    })
}

/// Check if a class is an external object: has R_CLASS restriction and extends ExternalObject.
pub fn is_external_object_class(node: &NameNode<'_>) -> bool {
    let NodeKind::Class(c) = &node.kind else { return false };
    if !matches!(c.restriction, Absyn::Restriction::R_CLASS) {
        return false;
    }
    node.extends.iter().any(|ext| path_last(&ext.path) == "ExternalObject")
}

// ── Warning context ───────────────────────────────────────────────────────────

/// Per-scope import tracking: maps a fully-qualified scope name to the set of names
/// that are directly imported in that scope (one entry per `import` statement).
/// Used only for warning checks; built from a read-only pass before mutation starts.
type ScopeImports = BTreeMap<String, BTreeSet<String>>;

/// Two-level type environment.
/// Outer key = fully-qualified scope (parent package path); inner key = simple name.
/// Builtins and top-level names use the empty-string scope `""`.
/// Example: type `A.B.Foo` is stored as `env["A.B"]["Foo"]`.
type ScopedKnown = BTreeMap<String, BTreeMap<String, Ty>>;

/// Per-scope import alias map: outer key = fully-qualified scope, inner key = local alias name,
/// value = fully-qualified target. Mirrors ScopedKnown layout so alias lookups can scope-walk.
type ScopedAliases = BTreeMap<String, BTreeMap<String, String>>;

struct WarnCtx<'a> {
    warnings: &'a mut BTreeSet<String>,
    scope_imports: &'a ScopeImports,
}

// ── ScopedKnown helpers ───────────────────────────────────────────────────────

/// Split "A.B.C" into ("A.B", "C"); "A" into ("", "A").
fn split_qname(qname: &str) -> (&str, &str) {
    match qname.rfind('.') {
        Some(i) => (&qname[..i], &qname[i + 1..]),
        None => ("", qname),
    }
}

/// Direct lookup by fully-qualified name: `env["A.B"]["Foo"]` for `"A.B.Foo"`.
fn sk_get<'a>(known: &'a ScopedKnown, qname: &str) -> Option<&'a Ty> {
    let (scope, name) = split_qname(qname);
    known.get(scope)?.get(name)
}

/// Insert only if the slot is absent.
fn sk_insert_if_absent(known: &mut ScopedKnown, qname: &str, ty: Ty) {
    let (scope, name) = split_qname(qname);
    known.entry(scope.to_owned()).or_default().entry(name.to_owned()).or_insert(ty);
}

/// Scope-walk: find `name` starting at `module_prefix`, walking up to the top-level
/// package, then the builtin/top-level scope `""`.
/// Returns the type reference and its resolved fully-qualified name.
fn sk_lookup_bare<'a>(known: &'a ScopedKnown, name: &str, module_prefix: &str) -> Option<(&'a Ty, String)> {
    if !module_prefix.is_empty() {
        let mut scope = module_prefix;
        loop {
            if let Some(ty) = known.get(scope).and_then(|m| m.get(name)) {
                return Some((ty, qualify(scope, name)));
            }
            match scope.rfind('.') {
                Some(dot) => scope = &scope[..dot],
                None => break,
            }
        }
    }
    known.get("").and_then(|m| m.get(name)).map(|ty| (ty, name.to_owned()))
}

/// If `(scope, name)` resolves to a RustStruct/RustUnitVariant and `scope` is itself a
/// RustEnum in its parent, return `UnionTypeVariant`; otherwise clone `ty` unchanged.
fn variant_promotion(scope: &str, name: &str, ty: &Ty, known: &ScopedKnown) -> Ty {
    if matches!(ty, Ty::RustStruct(_) | Ty::RustUnitVariant) && !scope.is_empty() {
        let (parent_scope, scope_name) = split_qname(scope);
        if let Some(parent_ty) = known.get(parent_scope).and_then(|m| m.get(scope_name))
            && matches!(parent_ty, Ty::RustEnum(_)) {
                return Ty::UnionTypeVariant(scope.to_owned(), name.to_owned());
            }
    }
    ty.clone()
}

/// Walk the hierarchy and record, for each scope, all names directly accessible within it
/// — both locally-defined children (nested packages, classes, functions) and imports.
/// Wildcard imports (`import Pkg.*`) are expanded: every child of `Pkg` in the hierarchy
/// is inserted into the scope's visible-name set.
fn collect_scope_imports<'a>(
    nodes: &BTreeMap<String, NameNode<'a>>,
    prefix: &str,
    top_level: &BTreeMap<String, NameNode<'a>>,
    out: &mut ScopeImports,
) {
    for (name, node) in nodes {
        let qname = qualify(prefix, name);
        for (child_name, child_node) in &node.children {
            if child_name == "*" {
                if let NodeKind::Import(m) = &child_node.kind
                    && let Absyn::Import::UNQUAL_IMPORT { path } = &m.import {
                        let pkg = fmt_path(path);
                        let pkg_path = pkg.trim_start_matches('.');
                        if let Some(pkg_node) = find_node_by_path(top_level, pkg_path) {
                            let scope_entry = out.entry(qname.clone()).or_default();
                            for n in pkg_node.children.keys() {
                                scope_entry.insert(n.clone());
                            }
                        }
                    }
            } else {
                out.entry(qname.clone()).or_default().insert(child_name.clone());
            }
        }
        collect_scope_imports(&node.children, &qname, top_level, out);
    }
}

/// Return true if `imported_name` is visible from `module_prefix` — i.e., it appears
/// as a direct import in the scope itself or any enclosing scope up to (and including)
/// the top-level package. Does not cross top-level package boundaries.
fn is_imported_in_scope(scope_imports: &ScopeImports, module_prefix: &str, imported_name: &str) -> bool {
    if module_prefix.is_empty() {
        return false;
    }
    let mut scope = module_prefix;
    loop {
        if scope_imports.get(scope).is_some_and(|s| s.contains(imported_name)) {
            return true;
        }
        match scope.rfind('.') {
            Some(dot) => scope = &scope[..dot],
            None => break, // checked the top-level package; stop
        }
    }
    false
}

// ── Type resolution ───────────────────────────────────────────────────────────

pub fn resolve_pass(hier: &mut InstanceHierarchy<'_>, warnings: &mut BTreeSet<String>) -> bool {
    let mut changed = false;
    seed_enumerations(&mut hier.top_level, "", &mut changed);
    seed_primitive_type_aliases(&mut hier.top_level, "", &mut changed);
    seed_metarecords(&mut hier.top_level, "", &mut changed);
    seed_external_objects(&mut hier.top_level, "", &mut changed);
    seed_type_vars(&mut hier.top_level, &mut changed);
    let mut known: ScopedKnown = BTreeMap::new();
    seed_builtins(&mut known);
    collect_known(&hier.top_level, "", &mut known);
    // Resolve import nodes using the seeded known map so that imported types (e.g. via
    // `import LexerJSON.{Token,...}`) appear as `Module.Name` entries in known before
    // components and functions are resolved. This prevents bare-name ambiguity when
    // multiple modules define the same type name.
    seed_imports(&mut hier.top_level, "", &known, &mut changed);
    known.clear();
    seed_builtins(&mut known);
    collect_known(&hier.top_level, "", &mut known);
    // Build the per-scope import index from a read-only pass before any mutation.
    let mut scope_imports: ScopeImports = BTreeMap::new();
    collect_scope_imports(&hier.top_level, "", &hier.top_level, &mut scope_imports);
    let mut wctx = WarnCtx { warnings, scope_imports: &scope_imports };
    collect_extends_known(&hier.top_level, "", &hier.top_level, &mut known, &mut wctx);
    // Apply `redeclare type X = Y` overrides directly onto the child nodes
    // they refer to. `seed_primitive_type_aliases` and `seed_metarecords` may
    // already have set the inherited child's `ty` to the *base*'s type (e.g.
    // `BaseAvlTree.Value = Integer` → `NFLookupTree.Value.ty = I32`). The
    // `try_resolve` short-circuit only fires for `ty == Unknown` nodes, so
    // without this pass the seeded primitive type wins and the redeclare is
    // ignored when body locals look up `Value`. We propagate the known-map
    // override into the node's `ty` field so `lookup_ty_in_hierarchy`
    // (used by `resolve_type_name` during body inference) returns the
    // redeclared type.
    apply_redeclare_overrides(&mut hier.top_level, "", &known, &mut changed);
    collect_wildcard_import_known(&hier.top_level, "", &hier.top_level, &mut known);
    let mut aliases: ScopedAliases = BTreeMap::new();
    collect_package_aliases(&hier.top_level, "", &mut aliases);
    resolve_nodes(&mut hier.top_level, "", &known, &aliases, &mut changed, &mut wctx);
    changed
}

/// Resolve import nodes using the current known map so they appear in collect_known
/// before components and functions are resolved.
fn seed_imports(nodes: &mut BTreeMap<String, NameNode<'_>>, prefix: &str, known: &ScopedKnown, changed: &mut bool) {
    for (name, node) in nodes.iter_mut() {
        let qname = qualify(prefix, name);
        if node.ty == Ty::Unknown
            && let NodeKind::Import(m) = &node.kind
                && let Some(ty) = try_resolve_import(m, &qname, known) {
                    node.ty = ty;
                    *changed = true;
                }
        seed_imports(&mut node.children, &qname, known, changed);
    }
}

/// Seed classes with R_CLASS that extend ExternalObject as `Ty::ExternalObject(qname)`.
/// These are opaque nominal types — the qualified path matters and they never match
/// other external objects even with the same simple name.
fn seed_external_objects(nodes: &mut BTreeMap<String, NameNode<'_>>, prefix: &str, changed: &mut bool) {
    for (name, node) in nodes.iter_mut() {
        let qname = qualify(prefix, name);
        if node.ty == Ty::Unknown && is_external_object_class(node) {
            node.ty = Ty::ExternalObject(qname.clone());
            *changed = true;
        }
        seed_external_objects(&mut node.children, &qname, changed);
    }
}

/// Pre-populate the known map with MM builtin types that are defined in the runtime
/// rather than in any source file and therefore never appear in the hierarchy.
fn seed_builtins(known: &mut ScopedKnown) {
    let top = known.entry(String::new()).or_default();
    top.entry("SOURCEINFO".into()).or_insert(Ty::RustStruct("SOURCEINFO".into()));
    top.entry("SourceInfo".into()).or_insert(Ty::AliasTo("SourceInfo".into()));
}

/// Seed `type T = Integer/Real/Boolean/String` aliases as primitive Ty variants.
/// These never appear in the seeding passes for enumerations or metarecords, so without
/// this pass they stay Unknown and `collect_known` skips them. A sibling import alias
/// (e.g. `import Type = NFType`) would then shadow the local definition during bare-name
/// lookup in `sk_lookup_bare`, producing a wrong type for function outputs.
/// Walk the hierarchy and, for every child node whose qname is keyed in
/// `known`, replace its `ty` with the `known` value. Used after
/// `collect_extends_known` to propagate `redeclare type X = Y` overrides
/// (which only landed in the `known` map) into the actual node tree, so
/// later lookups via `lookup_ty_in_hierarchy`/`node.ty` see the redeclared
/// type. We only overwrite when the override is a concrete type (not
/// `Unknown` or a stand-in `TypeVar`); that protects against accidentally
/// regressing a node we've already resolved more precisely.
fn apply_redeclare_overrides(nodes: &mut BTreeMap<String, NameNode<'_>>, prefix: &str, known: &ScopedKnown, changed: &mut bool) {
    for (name, node) in nodes.iter_mut() {
        let qname = qualify(prefix, name);
        if let Some((scope, key)) = qname.rsplit_once('.')
            && let Some(ty) = known.get(scope).and_then(|m| m.get(key))
                && !matches!(ty, Ty::Unknown | Ty::TypeVar(_)) && node.ty != *ty {
                    node.ty = ty.clone();
                    *changed = true;
                }
        apply_redeclare_overrides(&mut node.children, &qname, known, changed);
    }
}

fn seed_primitive_type_aliases(nodes: &mut BTreeMap<String, NameNode<'_>>, prefix: &str, changed: &mut bool) {
    for (name, node) in nodes.iter_mut() {
        let qname = qualify(prefix, name);
        if node.ty == Ty::Unknown
            && let NodeKind::Class(c) = &node.kind
                && matches!(c.restriction, Absyn::Restriction::R_TYPE)
                    && let MM::ClassDef::Derived { type_spec, .. } = &c.body {
                        let ty = match path_last(type_spec_path(type_spec)) {
                            "Integer" => Some(Ty::I32),
                            "Real" => Some(Ty::F64),
                            "Boolean" => Some(Ty::Bool),
                            "String" => Some(Ty::Str),
                            _ => None,
                        };
                        if let Some(ty) = ty {
                            node.ty = ty;
                            *changed = true;
                        }
                    }
        seed_primitive_type_aliases(&mut node.children, &qname, changed);
    }
}

fn seed_enumerations(nodes: &mut BTreeMap<String, NameNode<'_>>, prefix: &str, changed: &mut bool) {
    for (name, node) in nodes.iter_mut() {
        let qname = qualify(prefix, name);
        if node.ty == Ty::Unknown
            && let NodeKind::Class(c) = &node.kind {
                let is_enum = matches!(c.restriction, Absyn::Restriction::R_ENUMERATION)
                    || (matches!(c.restriction, Absyn::Restriction::R_TYPE)
                        && matches!(c.body, MM::ClassDef::Enumeration { .. }));
                if is_enum {
                    let ty = Ty::Enumeration(qname.clone());
                    for child in node.children.values_mut() {
                        if matches!(child.kind, NodeKind::EnumLiteral) && child.ty == Ty::Unknown {
                            child.ty = ty.clone();
                            *changed = true;
                        }
                    }
                    node.ty = ty;
                    *changed = true;
                }
            }
        seed_enumerations(&mut node.children, &qname, changed);
    }
}

/// Seed the record children of every R_UNIONTYPE node.
/// Records with fields → RustStruct; records with no fields → RustUnitVariant.
/// We seed by context (record inside a uniontype) rather than by restriction because
/// the mmwinnow parser assigns R_RECORD (not R_METARECORD) to all record declarations.
fn seed_metarecords(nodes: &mut BTreeMap<String, NameNode<'_>>, prefix: &str, changed: &mut bool) {
    for (name, node) in nodes.iter_mut() {
        let qname = qualify(prefix, name);
        if let NodeKind::Class(c) = &node.kind
            && matches!(c.restriction, Absyn::Restriction::R_UNIONTYPE) {
                let rec_names: Vec<String> = record_child_names(node);
                for rec_name in &rec_names {
                    let rec_qname = qualify(&qname, rec_name);
                    let child = node.children.get_mut(rec_name).unwrap();
                    if child.ty == Ty::Unknown {
                        child.ty = if has_component_children(child) {
                            Ty::RustStruct(rec_qname)
                        } else {
                            Ty::RustUnitVariant
                        };
                        *changed = true;
                    }
                }
                // Also seed the uniontype itself once all records are known, so that
                // collect_known can include it before functions in the same module are resolved.
                if node.ty == Ty::Unknown {
                    let all_seeded = rec_names.iter().all(|n| {
                        node.children.get(n).is_some_and(|c| c.ty != Ty::Unknown)
                    });
                    if all_seeded {
                        let mut sorted = rec_names.clone();
                        sorted.sort();
                        node.ty = match sorted.len() {
                            0 => Ty::RustStruct(qname.clone()),
                            1 => {
                                // Single-record uniontype: the struct will be emitted under the
                                // uniontype's name (no separate record struct + type alias).
                                // Update the record's type so all references resolve to the
                                // uniontype's qname, which is the Rust struct's actual name.
                                if let Some(rec_child) = node.children.get_mut(sorted[0].as_str()) {
                                    rec_child.ty = Ty::RustStruct(qname.clone());
                                }
                                Ty::AliasTo(qname.clone())
                            }
                            _ => Ty::RustEnum(qname.clone()),
                        };
                        *changed = true;
                    }
                }
            }
        seed_metarecords(&mut node.children, &qname, changed);
    }
}

/// Mark `replaceable type T subtypeof Any` class members as `Ty::TypeVar`.
fn seed_type_vars(nodes: &mut BTreeMap<String, NameNode<'_>>, changed: &mut bool) {
    for node in nodes.values_mut() {
        if let NodeKind::Class(c) = &node.kind {
            let vars = class_type_vars(c);
            for var_name in vars {
                if let Some(child) = node.children.get_mut(&var_name)
                    && child.ty == Ty::Unknown {
                        child.ty = Ty::TypeVar(var_name.clone());
                        *changed = true;
                    }
            }
        }
        seed_type_vars(&mut node.children, changed);
    }
}

/// Snapshot all resolved types into the scoped lookup map.
/// TypeVars are excluded — they are local to their enclosing class.
fn collect_known(nodes: &BTreeMap<String, NameNode<'_>>, prefix: &str, known: &mut ScopedKnown) {
    for (name, node) in nodes {
        let qname = qualify(prefix, name);
        if node.ty != Ty::Unknown && !matches!(node.ty, Ty::TypeVar(_)) {
            known.entry(prefix.to_owned()).or_default()
                .entry(name.clone()).or_insert_with(|| node.ty.clone());
        }
        collect_known(&node.children, &qname, known);
    }
}

/// Navigate the top-level hierarchy following a dot-separated path.
fn find_node_by_path<'h>(top_level: &'h BTreeMap<String, NameNode<'h>>, path: &str) -> Option<&'h NameNode<'h>> {
    let mut parts = path.split('.');
    let first = parts.next()?;
    let mut current = top_level.get(first)?;
    for part in parts {
        current = current.children.get(part)?;
    }
    Some(current)
}

/// Recursively copy all children of `pkg_node` (rooted at `pkg_scope`) into `known`
/// under `import_scope`, so that dotted paths like `ConnectorType.Type` resolve when
/// `ConnectorType` was brought in via a wildcard import.
fn copy_wildcard_children(
    pkg_node: &NameNode<'_>,
    pkg_scope: &str,
    import_scope: &str,
    known: &mut ScopedKnown,
) {
    for (child_name, child_node) in &pkg_node.children {
        let child_import_scope = qualify(import_scope, child_name);
        let child_pkg_scope = qualify(pkg_scope, child_name);
        // Copy resolved typed children into the importing scope.
        if child_node.ty != Ty::Unknown && !matches!(child_node.ty, Ty::TypeVar(_)) {
            known.entry(import_scope.to_owned()).or_default()
                .entry(child_name.clone()).or_insert_with(|| child_node.ty.clone());
        }
        // Recurse into sub-packages so `Pkg.SubPkg.Type` is reachable as `SubPkg.Type`.
        if matches!(child_node.kind, NodeKind::Class(crate::MM::Class { restriction: openmodelica_ast::Absyn::Restriction::R_PACKAGE, .. })) {
            copy_wildcard_children(child_node, &child_pkg_scope, &child_import_scope, known);
        }
    }
}

/// Expand wildcard imports (`import Pkg.*`) into the known map.
/// For each scope that contains a `*`-named child (a wildcard import), look up the
/// target package in the hierarchy and copy all its resolved direct-child types into
/// `known` under the importing scope, so that `sk_lookup_bare` can find them.
/// Sub-packages of the imported package are also recursively copied so that dotted
/// paths like `ConnectorType.Type` (where `ConnectorType` lives in the imported pkg)
/// resolve correctly.
fn collect_wildcard_import_known(
    nodes: &BTreeMap<String, NameNode<'_>>,
    prefix: &str,
    top_level: &BTreeMap<String, NameNode<'_>>,
    known: &mut ScopedKnown,
) {
    for (name, node) in nodes {
        let qname = qualify(prefix, name);
        if let Some(star_child) = node.children.get("*")
            && let NodeKind::Import(m) = &star_child.kind
                && let Absyn::Import::UNQUAL_IMPORT { path } = &m.import {
                    let pkg = fmt_path(path);
                    let pkg_path = pkg.trim_start_matches('.');
                    if let Some(pkg_node) = find_node_by_path(top_level, pkg_path) {
                        copy_wildcard_children(pkg_node, pkg_path, &qname, known);
                    }
                }
        collect_wildcard_import_known(&node.children, &qname, top_level, known);
    }
}

/// Propagate extends inheritance into the known map.
/// For each node with extends clauses, find the base class in the top-level hierarchy
/// and add its resolved direct children under the derived node's qualified name.
/// This lets `ZeroCrossingTree.Tree` resolve even though Tree is only defined in BaseAvlTree.
fn collect_extends_known<'a>(
    nodes: &BTreeMap<String, NameNode<'a>>,
    prefix: &str,
    top_level: &BTreeMap<String, NameNode<'a>>,
    known: &mut ScopedKnown,
    wctx: &mut WarnCtx<'_>,
) {
    for (name, node) in nodes {
        let qname = qualify(prefix, name);
        for ext in &node.extends {
            let base_path = fmt_path(&ext.path);
            let base_path = base_path.trim_start_matches('.');
            if let Some(base_node) = find_node_by_path(top_level, base_path) {
                for (child_name, child_node) in &base_node.children {
                    if child_node.ty == Ty::Unknown || matches!(child_node.ty, Ty::TypeVar(_)) {
                        continue;
                    }
                    // If the derived node has its own child by this name, do not
                    // contribute the base's type for it. The local declaration
                    // either (a) was copied from the base by `flatten_extends`
                    // (same definition; it'll resolve to the right type in the
                    // derived scope via `collect_known`), or (b) is a *redeclare*
                    // that overrides the base (e.g. `redeclare type Value =
                    // list<TplAbsyn.ASTDef>` in `CacheTree extends BaseAvlTree`).
                    // In case (b), letting the base's type win here would
                    // propagate through `apply_redeclare_overrides` and replace
                    // the (still-Unknown, pending re-resolution) local node's
                    // type — silently demoting the redeclare. Until the local
                    // resolves on a later pass, leave its known-map slot empty
                    // rather than fill it with a value we know is wrong.
                    if node.children.contains_key(child_name) {
                        continue;
                    }
                    // Full qualified key: ZeroCrossings.ZeroCrossingTree.Tree
                    sk_insert_if_absent(known, &qualify(&qname, child_name), child_node.ty.clone());
                    // Relative key (no enclosing package prefix): ZeroCrossingTree.Tree
                    // Used by sibling type aliases, e.g. `type Tree = ZeroCrossingTree.Tree`
                    // Prefer the derived class's already-seeded type (from collect_known) over the
                    // base class's type, so that e.g. `EnvTree.Tree` resolves to
                    // `NFSCodeEnv.EnvTree.Tree` rather than `BaseAvlTree.Tree`.
                    let full_key = qualify(&qname, child_name);
                    let rel_ty = sk_get(known, &full_key)
                        .filter(|t| **t != Ty::Unknown && !matches!(*t, Ty::TypeVar(_)))
                        .cloned()
                        .unwrap_or_else(|| child_node.ty.clone());
                    sk_insert_if_absent(known, &qualify(name, child_name), rel_ty);
                }
            }
            // Process `redeclare type X = Y` modifications in the extends clause.
            //
            // The redeclare must *override* the type that the base class
            // contributes for `X` (e.g. `BaseAvlTree.Value = Integer` is
            // overridden in `NFLookupTree extends BaseAvlTree(redeclare
            // type Value = Entry)`). The earlier base-children pass already
            // inserted the *base*'s type for `X` into both `qname.X` and
            // `name.X`, so we use unconditional insert here (not
            // `_if_absent`) to replace it. Without this, inherited function
            // signatures like `valueStr(inValue: Value)` keep resolving to
            // the base's `Integer` rather than the redeclared `Entry`.
            //
            // The redeclared `typeSpec` (`Entry`) is resolved in the
            // *redeclaring* scope (`qname` — the package that contains the
            // extends clause). That scope is where `Entry` is declared
            // (here, as a sibling of the extends inside `NFLookupTree`); a
            // top-level lookup ("" prefix) would never find it.
            let empty_aliases: ScopedAliases = BTreeMap::new();
            for arg in &ext.element_args {
                if let Absyn::ElementArg::REDECLARATION { elementSpec, .. } = arg
                    && let Absyn::ElementSpec::CLASSDEF { class_, .. } = &**elementSpec
                {
                    let Absyn::Class { name: child_name, body, .. } = class_.as_ref();
                    if let Absyn::ClassDef::DERIVED { typeSpec, .. } = body.as_ref()
                        && let Some(ty) = resolve_type_spec(typeSpec, known, &empty_aliases, &[], &qname, wctx) {
                            known.entry(qname.clone()).or_default().insert(child_name.to_string(), ty.clone());
                            known.entry(name.to_owned()).or_default().insert(child_name.to_string(), ty);
                        }
                }
            }
        }
        collect_extends_known(&node.children, &qname, top_level, known, wctx);
    }
}

/// Collect package-level import aliases per scope.
/// Each QUAL_IMPORT / NAMED_IMPORT is recorded under the scope that contains it so that
/// alias lookup can scope-walk and never mix up `import Unit=FUnit` in one package with
/// `import Unit=NFUnit` in another.
fn collect_package_aliases(nodes: &BTreeMap<String, NameNode<'_>>, prefix: &str, aliases: &mut ScopedAliases) {
    for (name, node) in nodes {
        let qname = qualify(prefix, name);
        if let NodeKind::Import(m) = &node.kind {
            // The import node lives at `qname`; its containing scope is `prefix`.
            let scope_map = aliases.entry(prefix.to_owned()).or_default();
            match &m.import {
                Absyn::Import::QUAL_IMPORT { path } => {
                    let full = fmt_path(path);
                    let full = full.trim_start_matches('.');
                    // Skip self-referential entries (`import Tpl;` where local == full path).
                    if name != full {
                        scope_map.entry(name.clone()).or_insert_with(|| full.to_owned());
                    }
                }
                Absyn::Import::NAMED_IMPORT { name: alias_name, path } => {
                    let full = fmt_path(path);
                    let full = full.trim_start_matches('.');
                    scope_map.insert(alias_name.to_string(), full.to_owned());
                }
                // `import Pkg.{X, Y, Z};` and `import Pkg.{X = Orig, ...}` each
                // bind one or more names in the importing scope, so they must
                // contribute alias entries the same way QUAL_IMPORT does.
                // Without this, downstream resolution of `X.field` in the
                // importer never reaches `Pkg.X.field` (E0425 / silent fn-skip
                // at `Ty::Unknown` for any signature that mentions `X.<sub>`).
                Absyn::Import::GROUP_IMPORT { prefix, groups } => {
                    let prefix_str_owned = fmt_path(prefix);
                    let prefix_str = prefix_str_owned.trim_start_matches('.');
                    for g in &**groups {
                        let (local_name, original) = match g {
                            Absyn::GroupImport::GROUP_IMPORT_NAME { name } => (name.to_string(), name.to_string()),
                            Absyn::GroupImport::GROUP_IMPORT_RENAME { rename, name } => (rename.to_string(), name.to_string()),
                        };
                        let full = format!("{prefix_str}.{original}");
                        scope_map.insert(local_name, full);
                    }
                }
                _ => {}
            }
        }
        collect_package_aliases(&node.children, &qname, aliases);
    }
}

/// Scope-walk alias lookup: search from `module_prefix` up to the top-level scope.
/// Resolve a dotted qname through chained import aliases, segment by segment.
///
/// Single-level expansion of the leading segment is not enough: an import like
/// `import NFTyping.InstContext` re-exports a name that itself was introduced
/// by a sibling import `import InstContext = NFInstContext` in NFTyping's
/// scope. The first-level alias expands `InstContext` to `NFTyping.InstContext`
/// (a path that has no entry in `known`); we then have to look up
/// `InstContext` *within NFTyping's scope* to reach `NFInstContext`, the
/// package that actually defines `Type`.
///
/// Each iteration peels one segment off the front, tries to expand it against
/// the surrounding scope (which moves forward as segments are consumed), and
/// stops as soon as the resulting full path is a `known` type — or when no
/// further expansion is available. Returns `Some(expanded)` only when the
/// resolved path is present in `known`; otherwise the caller falls back to
/// the existing logic.
fn expand_dotted_through_aliases(
    qname: &str,
    aliases: &ScopedAliases,
    known: &ScopedKnown,
    module_prefix: &str,
) -> Option<String> {
    // Iteratively rewrite the path: consume one segment at a time. Each step
    // either expands the next segment via an alias (and re-anchors `scope` to
    // the segment's parent so further aliases in *that* scope can fire) or
    // treats the segment as a real package and advances `scope` into it.
    // Stops as soon as the full `scope.tail` path lives in `known`.
    //
    // Bound by the original dot count plus a small safety margin so a cyclic
    // alias graph terminates rather than spinning.
    let mut scope = module_prefix.to_owned();
    let mut tail = qname.to_owned();
    let max_iters = qname.matches('.').count() * 2 + 8;
    for _ in 0..max_iters {
        let full = if scope.is_empty() {
            tail.clone()
        } else {
            format!("{scope}.{tail}")
        };
        if sk_get(known, &full).is_some() {
            return Some(full);
        }
        let dot = tail.find('.')?;
        let (first, rest) = tail.split_at(dot);
        let rest = &rest[1..]; // drop the leading '.'
        if let Some(target) = alias_lookup(aliases, &scope, first) {
            // Replace `first` with its alias target, then re-anchor `scope` to
            // the target's parent so the next iteration's lookups see the
            // aliases declared at that level. The remainder `rest` is left
            // unconsumed so subsequent iterations can keep peeling it.
            let target = target.to_owned();
            let (target_scope, target_tail) = match target.rfind('.') {
                Some(d) => (target[..d].to_owned(), target[d+1..].to_owned()),
                None => (String::new(), target),
            };
            scope = target_scope;
            tail = if rest.is_empty() { target_tail } else { format!("{target_tail}.{rest}") };
        } else {
            // Not aliased: descend into the segment as a real package. The
            // next iteration looks up aliases at the new scope, which is how
            // chained imports across packages get resolved.
            scope = if scope.is_empty() { first.to_owned() } else { format!("{scope}.{first}") };
            tail = rest.to_owned();
            if tail.is_empty() { return None; }
        }
    }
    None
}

fn alias_lookup<'a>(aliases: &'a ScopedAliases, module_prefix: &str, name: &str) -> Option<&'a str> {
    let mut scope = module_prefix;
    loop {
        if let Some(target) = aliases.get(scope).and_then(|m| m.get(name)) {
            return Some(target.as_str());
        }
        match scope.rfind('.') {
            Some(dot) => scope = &scope[..dot],
            None if scope.is_empty() => return None,
            None => scope = "",
        }
    }
}

fn resolve_nodes(nodes: &mut BTreeMap<String, NameNode<'_>>, prefix: &str, known: &ScopedKnown, aliases: &ScopedAliases, changed: &mut bool, wctx: &mut WarnCtx<'_>) {
    resolve_nodes_inner(nodes, prefix, known, aliases, &[], changed, wctx);
}

fn resolve_nodes_inner(nodes: &mut BTreeMap<String, NameNode<'_>>, prefix: &str, known: &ScopedKnown, aliases: &ScopedAliases, outer_type_vars: &[String], changed: &mut bool, wctx: &mut WarnCtx<'_>) {
    for (name, node) in nodes.iter_mut() {
        let qname = qualify(prefix, name);
        if node.ty == Ty::Unknown
            && let Some(ty) = try_resolve(node, &qname, known, aliases, outer_type_vars, wctx) {
                node.ty = ty;
                *changed = true;
            }
        // Collect this node's own type vars and merge with inherited outer ones.
        let child_outer: Vec<String> = {
            let mut vars: Vec<String> = if let NodeKind::Class(c) = &node.kind {
                class_type_vars(c)
            } else {
                vec![]
            };
            for v in outer_type_vars {
                if !vars.contains(v) { vars.push(v.clone()); }
            }
            vars
        };
        resolve_nodes_inner(&mut node.children, &qname, known, aliases, &child_outer, changed, wctx);
    }
}

fn try_resolve(node: &NameNode<'_>, qname: &str, known: &ScopedKnown, aliases: &ScopedAliases, outer_type_vars: &[String], wctx: &mut WarnCtx<'_>) -> Option<Ty> {
    let module_prefix = qname.rsplit_once('.').map_or("", |(p, _)| p);
    // An explicit `known[qname]` entry overrides whatever the node's own
    // declaration would resolve to. The only producer of such entries is
    // `collect_extends_known`, which records `redeclare type X = Y` modifications
    // in an `extends` clause: e.g. `NFLookupTree extends BaseAvlTree(redeclare
    // type Value = Entry)` writes `NFLookupTree.Value -> Entry` into `known`.
    // The inherited `Value` node, however, was copied from the base
    // (`clone_and_reset`) and still has `c.body = Derived(Integer)`; without
    // this short-circuit, `try_resolve` would re-resolve it to `Integer` and
    // erase the redeclare. We check `known[scope][name]` directly (rather
    // than via `sk_lookup_bare`, which walks parents) so this only triggers
    // when the entry is *exactly* at this scope — i.e. when a redeclare
    // applied here, not when an enclosing scope happens to have a matching
    // name.
    if let Some((scope, name)) = qname.rsplit_once('.')
        && let Some(ty) = known.get(scope).and_then(|m| m.get(name))
            && !matches!(ty, Ty::Unknown | Ty::TypeVar(_)) {
                return Some(ty.clone());
            }
    match &node.kind {
        NodeKind::Class(c) if is_function_class(&c.restriction) => {
            resolve_function_type(c, node, known, aliases, outer_type_vars, qname, wctx, /*nested_in_function=*/false)
        }
        NodeKind::Class(c) if matches!(c.restriction, Absyn::Restriction::R_UNIONTYPE) => {
            try_resolve_uniontype(node, qname)
        }
        NodeKind::Class(c) => match &c.body {
            MM::ClassDef::Derived { type_spec, .. } => resolve_type_spec(type_spec, known, aliases, outer_type_vars, module_prefix, wctx),
            _ => None,
        },
        NodeKind::Component(m) => resolve_type_spec(&m.type_spec, known, aliases, outer_type_vars, module_prefix, wctx),
        NodeKind::Import(m) => try_resolve_import(m, qname, known),
        NodeKind::EnumLiteral => None,
    }
}

/// Resolve an import node to the type of the thing it imports.
/// `qname` is used to extract the local alias (its last segment) for GROUP_IMPORT disambiguation.
fn try_resolve_import(m: &MM::ImportMember, qname: &str, known: &ScopedKnown) -> Option<Ty> {
    let local = qname.rsplit('.').next().unwrap_or(qname);
    match &m.import {
        Absyn::Import::NAMED_IMPORT { path, .. } | Absyn::Import::QUAL_IMPORT { path } => {
            let dotted = fmt_path(path);
            let dotted = dotted.trim_start_matches('.');
            sk_get(known, dotted).cloned()
                .or_else(|| known.get("").and_then(|m| m.get(path_last(path))).cloned())
        }
        Absyn::Import::GROUP_IMPORT { prefix, groups } => {
            let prefix_str = fmt_path(prefix);
            let prefix_str = prefix_str.trim_start_matches('.');
            for g in &**groups {
                let (is_match, orig) = match g {
                    Absyn::GroupImport::GROUP_IMPORT_NAME { name } => (&**name == local, name),
                    Absyn::GroupImport::GROUP_IMPORT_RENAME { rename, name } => (&**rename == local, name),
                };
                if is_match {
                    let full = format!("{prefix_str}.{orig}");
                    return sk_get(known, &full).cloned()
                        .or_else(|| known.get("").and_then(|m| m.get(&**orig)).cloned());
                }
            }
            None
        }
        // Wildcard imports don't map to a single type.
        Absyn::Import::UNQUAL_IMPORT { .. } => None,
    }
}

fn try_resolve_uniontype(node: &NameNode<'_>, qname: &str) -> Option<Ty> {
    let mut record_names: Vec<String> = record_child_names(node);

    // Defer if any record child is still Unknown (seeding hasn't run yet).
    for name in &record_names {
        if node.children.get(name).is_none_or(|c| c.ty == Ty::Unknown) {
            return None;
        }
    }

    record_names.sort(); // deterministic order for AliasTo
    match record_names.len() {
        0 => Some(Ty::RustStruct(qname.to_owned())), // function-only (e.g. Mutable<T>)
        1 => Some(Ty::AliasTo(qname.to_owned())),
        _ => Some(Ty::RustEnum(qname.to_owned())),
    }
}

/// Re-resolve the inputs/outputs of `base_fn_c` in the scope of a derived class.
/// Used for `function extends Foo` redeclarations: the base class provides the
/// parameter declarations; the derived class's context provides the concrete types
/// for any replaceable type parameters (e.g. `Key = String` instead of `Key = Integer`).
fn resolve_function_from_base(
    base_fn_c: &MM::Class,
    known: &ScopedKnown,
    aliases: &ScopedAliases,
    type_vars: &[String],
    module_prefix: &str,
    wctx: &mut WarnCtx<'_>,
) -> Option<Ty> {
    let members = match &base_fn_c.body {
        MM::ClassDef::Parts { members, .. } => members,
        _ => return None,
    };
    let mut inputs: Vec<FunctionInput> = Vec::new();
    let mut outputs: Vec<Ty> = Vec::new();
    for member in members {
        let MM::ClassMember::Component(m) = member else { continue };
        let Some(ty) = resolve_type_spec(&m.type_spec, known, aliases, type_vars, module_prefix, wctx) else {
            return None; // Defer if a type can't be resolved yet.
        };
        let default = extract_default(&m.modification);
        match m.direction {
            Absyn::Direction::INPUT => inputs.push(FunctionInput { name: m.name.clone(), ty, default }),
            Absyn::Direction::OUTPUT => outputs.push(ty),
            Absyn::Direction::INPUT_OUTPUT => {
                outputs.push(ty.clone());
                inputs.push(FunctionInput { name: m.name.clone(), ty, default });
            }
            _ => {}
        }
    }
    let output = match outputs.len() {
        0 => Ty::Unit,
        1 => outputs.into_iter().next().unwrap(),
        _ => Ty::Tuple(outputs),
    };
    Some(Ty::Function { type_vars: vec![], inputs, output: Box::new(output), name: None })
}

/// Resolve a function's type, threading `outer_type_vars` into nested partial functions.
/// `fn_qname` is the fully-qualified name of this function; its parent segment is used as the
/// module prefix when resolving bare type names in function parameters.
fn resolve_function_type(
    c: &MM::Class,
    node: &NameNode<'_>,
    known: &ScopedKnown,
    aliases: &ScopedAliases,
    outer_type_vars: &[String],
    fn_qname: &str,
    wctx: &mut WarnCtx<'_>,
    // Set when this resolution is for a partial function nested directly inside
    // another function (i.e. invoked via the recursive call below). Codegen
    // currently does not emit those nested aliases — they're only resolvable
    // structurally — so we must not tag the resulting `Ty::Function` with a
    // name that points at a non-existent Rust type alias.
    nested_in_function: bool,
) -> Option<Ty> {
    let module_prefix = fn_qname.rsplit_once('.').map_or("", |(p, _)| p);
    let mut type_vars = class_type_vars(c);
    for v in outer_type_vars {
        if !type_vars.contains(v) { type_vars.push(v.clone()); }
    }

    // Function alias: `function Foo = Bar(param=default)`
    if let MM::ClassDef::Derived { type_spec, arguments, .. } = &c.body {
        let base = fmt_path(type_spec_path(type_spec)).trim_start_matches('.').to_owned();
        let modifications = arguments.iter()
            .filter_map(|arg| {
                let Absyn::ElementArg::MODIFICATION { path, modification: Some(m), .. } = arg else { return None };
                let Absyn::EqMod::EQMOD { exp, .. } = &*m.eqMod else { return None };
                Some((fmt_path(path), fmt_exp(exp)))
            })
            .collect();
        return Some(Ty::FunctionAlias { base, modifications });
    }

    // `function extends Foo` (redeclare function extends): inherit the base function's
    // input/output declarations but re-resolve all types in the derived class's context
    // so that replaceable type parameters (e.g. `Key`) pick up their concrete bindings.
    if matches!(&c.body, MM::ClassDef::ClassExtends { .. }) {
        if let Some(base_fn_c) = node.base_fn {
            return resolve_function_from_base(base_fn_c, known, aliases, &type_vars, module_prefix, wctx);
        }
        return None; // Defer until flatten_extends has set base_fn.
    }

    let members: &[MM::ClassMember] = match &c.body {
        MM::ClassDef::Parts { members, .. } => members,
        MM::ClassDef::ClassExtends { members, .. } => members,
        _ => return None,
    };

    // Resolve nested partial function children with the combined type vars so they
    // can reference type variables declared in the outer function.
    let mut local_fns: BTreeMap<String, Ty> = BTreeMap::new();
    for (child_name, child_node) in &node.children {
        if let NodeKind::Class(fn_class) = &child_node.kind
            && is_function_class(&fn_class.restriction)
                && let Some(fn_ty) = resolve_function_type(fn_class, child_node, known, aliases, &type_vars, &format!("{fn_qname}.{child_name}"), wctx, /*nested_in_function=*/true) {
                    local_fns.insert(child_name.clone(), fn_ty);
                }
    }

    let mut inputs: Vec<FunctionInput> = Vec::new();
    let mut outputs: Vec<Ty> = Vec::new();

    // `function F ... extends G; ... end F;` (an Extends member inside a
    // function-body's Parts) inherits G's inputs/outputs in declaration order
    // ahead of F's own components. Without this merge, callers that read the
    // function's resolved `Ty::Function` (e.g. `call_ty` for type inference at
    // call sites) see an empty inputs list and `Unit` output, which silently
    // miscompiles destructure-assignments of the call's tuple result.
    //
    // Local components (handled by the loop below) come *after* the inherited
    // ones so the parameter and output order matches Modelica's
    // base-then-derived convention. If F locally redeclares a name from G,
    // the local declaration wins — we skip the inherited entry by name.
    let local_component_names: std::collections::HashSet<String> = members.iter()
        .filter_map(|m| match m {
            MM::ClassMember::Component(cm) => Some(cm.name.clone()),
            _ => None,
        })
        .collect();
    let mut seen_inherited: std::collections::HashSet<String> = std::collections::HashSet::new();
    for ext in &node.extends {
        let ext_path_owned = fmt_path(&ext.path);
        let ext_path = ext_path_owned.trim_start_matches('.');
        // Resolve the base function's type. Use the dotted-path lookup for
        // qualified names (`Pkg.Foo`); for bare names walk scopes outward
        // from `module_prefix` so a sibling `partialParser` is found in
        // the same package.
        let base_ty = if ext_path.contains('.') {
            // The head segment may be an import alias (`extends Module.aliasInterface;`
            // where `import Module = NBModule;`). Resolve it through the alias
            // map first — otherwise the literal `Module.aliasInterface` is never
            // a `known` key, `base_ty` stays `None`, and the function is deferred
            // forever and ultimately dropped (no signature → not emitted).
            expand_dotted_through_aliases(ext_path, aliases, known, module_prefix)
                .and_then(|q| sk_get(known, &q).cloned())
                .or_else(|| sk_get(known, ext_path).cloned())
        } else {
            sk_lookup_bare(known, ext_path, module_prefix).map(|(t, _)| t.clone())
        };
        match base_ty {
            Some(Ty::Function { inputs: base_inputs, output: base_output, .. }) => {
                for inp in base_inputs {
                    if local_component_names.contains(&inp.name) { continue; }
                    if !seen_inherited.insert(inp.name.clone()) { continue; }
                    inputs.push(inp);
                }
                match *base_output {
                    Ty::Unit => {}
                    Ty::Tuple(ts) => outputs.extend(ts),
                    t => outputs.push(t),
                }
            }
            // Base resolved to something that isn't a function (e.g. a uniontype
            // extends — handled elsewhere). Skip; the local-member loop below
            // still runs.
            Some(_) => {}
            // Base function type isn't ready yet (still `Ty::Unknown` in
            // `known`). Defer this function so it gets re-resolved on the
            // next `resolve_pass` iteration, by which time the base will
            // have its signature populated.
            None => return None,
        }
    }

    for member in members {
        let MM::ClassMember::Component(m) = member else { continue };
        let child = node.children.get(&m.name)?;
        let ty = if child.ty != Ty::Unknown {
            child.ty.clone()
        } else {
            // Check local partial functions first (higher-order function args).
            let type_name = path_last(type_spec_path(&m.type_spec));
            if let Some(fn_ty) = local_fns.get(type_name).cloned() {
                fn_ty
            } else {
                resolve_type_spec(&m.type_spec, known, aliases, &type_vars, module_prefix, wctx)?
            }
        };
        let default = extract_default(&m.modification);
        match m.direction {
            Absyn::Direction::INPUT => inputs.push(FunctionInput { name: m.name.clone(), ty, default }),
            Absyn::Direction::OUTPUT => outputs.push(ty),
            Absyn::Direction::INPUT_OUTPUT => {
                outputs.push(ty.clone());
                inputs.push(FunctionInput { name: m.name.clone(), ty, default });
            }
            _ => {}
        }
    }

    let output = match outputs.len() {
        0 => Ty::Unit,
        1 => outputs.into_iter().next().unwrap(),
        _ => Ty::Tuple(outputs),
    };
    // Only report the type vars that belong to this function (not inherited outer ones).
    let own_type_vars = class_type_vars(c);
    // Tag with the declaration name only for `partial function` declarations.
    // Those are the named function-type aliases consumers may refer to by name
    // (e.g. `KeyEq eqFn;`); concrete functions don't need the name attached
    // because their signature is not what gets referenced as a type.
    let name = if c.partial_prefix && !nested_in_function { Some(fn_qname.to_owned()) } else { None };
    Some(Ty::Function { type_vars: own_type_vars, inputs, output: Box::new(output), name })
}

/// Resolve a TypeSpec to a Ty.
/// `type_vars` is the list of type-variable names in scope; they resolve to `Ty::TypeVar`.
/// `module_prefix` is the enclosing module qname used to resolve bare names to module-local types.
fn resolve_type_spec(ts: &Absyn::TypeSpec, known: &ScopedKnown, aliases: &ScopedAliases, type_vars: &[String], module_prefix: &str, wctx: &mut WarnCtx<'_>) -> Option<Ty> {
    match ts {
        Absyn::TypeSpec::TPATH { path, .. } => resolve_path(path, known, aliases, type_vars, module_prefix, wctx),
        Absyn::TypeSpec::TCOMPLEX { path, typeSpecs, .. } => {
            let args: Vec<Arc<Absyn::TypeSpec>> = (&**typeSpecs).into_iter().cloned().collect();
            let ctor = path_last(path);
            match ctor {
                "tuple" => {
                    let tys: Option<Vec<Ty>> = args.iter()
                        .map(|a| resolve_type_spec(a, known, aliases, type_vars, module_prefix, wctx))
                        .collect();
                    Some(Ty::Tuple(tys?))
                }
                "Option" if args.len() == 1 => {
                    Some(Ty::Option(Box::new(resolve_type_spec(&args[0], known, aliases, type_vars, module_prefix, wctx)?)))
                }
                "list" | "List" if args.len() == 1 => {
                    Some(Ty::List(Box::new(resolve_type_spec(&args[0], known, aliases, type_vars, module_prefix, wctx)?)))
                }
                "array" | "Array" if args.len() == 1 => {
                    Some(Ty::Array(Box::new(resolve_type_spec(&args[0], known, aliases, type_vars, module_prefix, wctx)?)))
                }
                "Mutable" if args.len() == 1 => {
                    let inner = resolve_type_spec(&args[0], known, aliases, type_vars, module_prefix, wctx)?;
                    Some(Ty::Generic("Mutable".to_owned(), vec![inner]))
                }
                _ => {
                    // User-defined generic: base type must be known, all args must resolve.
                    let full = fmt_path(path);
                    let lookup = full.trim_start_matches('.');
                    let base_ty = if lookup.contains('.') {
                        sk_get(known, lookup)
                    } else {
                        sk_lookup_bare(known, lookup, module_prefix).map(|(ty, _)| ty)
                    }?;
                    let base_name = ty_rust_name(base_ty).unwrap_or_else(|| ctor.to_owned());
                    let resolved: Option<Vec<Ty>> = args.iter()
                        .map(|a| resolve_type_spec(a, known, aliases, type_vars, module_prefix, wctx))
                        .collect();
                    Some(Ty::Generic(base_name, resolved?))
                }
            }
        }
    }
}

fn resolve_path(path: &Absyn::Path, known: &ScopedKnown, aliases: &ScopedAliases, type_vars: &[String], module_prefix: &str, wctx: &mut WarnCtx<'_>) -> Option<Ty> {
    let last = path_last(path);
    match last {
        "Integer" => return Some(Ty::I32),
        "Real" => return Some(Ty::F64),
        "Boolean" => return Some(Ty::Bool),
        "String" => return Some(Ty::Str),
        name if type_vars.iter().any(|v| v == name) => return Some(Ty::TypeVar(name.to_owned())),
        _ => {}
    }
    let qname = fmt_path(path);
    let qname = qname.trim_start_matches('.');

    // Bare name: scope-walk from module_prefix up to builtins/top-level.
    if !qname.contains('.') {
        if let Some((ty, resolved)) = sk_lookup_bare(known, qname, module_prefix) {
            let (scope, name) = split_qname(&resolved);
            return Some(variant_promotion(scope, name, ty, known));
        }
        return None;
    }

    // Dotted name: try direct lookup first, then scope-walk by prepending ancestor
    // scopes (e.g. `Connect.Face` in scope `DAE` → try `DAE.Connect.Face`), then
    // alias-expand the leading segment.
    let expanded: Option<String> = if sk_get(known, qname).is_some() {
        None
    } else {
        // Scope-walk: try prepending each enclosing scope.
        let scope_walked = if !module_prefix.is_empty() {
            let mut scope = module_prefix;
            let mut found = None;
            loop {
                let candidate = format!("{scope}.{qname}");
                if sk_get(known, &candidate).is_some() {
                    found = Some(candidate);
                    break;
                }
                match scope.rfind('.') {
                    Some(dot) => scope = &scope[..dot],
                    None => break,
                }
            }
            found
        } else {
            None
        };
        scope_walked.or_else(|| expand_dotted_through_aliases(qname, aliases, known, module_prefix))
    };
    let effective = expanded.as_deref().unwrap_or(qname);

    // Warn when a dotted path resolves but its leading segment package was not imported.
    if let Some(dot) = qname.find('.') {
        let first = &qname[..dot];
        // No warning if first is itself a known type (accessible via scope-walk).
        let first_is_type = sk_lookup_bare(known, first, module_prefix).is_some();
        // No warning if first is the current module or one of its enclosing packages.
        let is_ancestor = !module_prefix.is_empty()
            && (module_prefix == first || module_prefix.starts_with(&format!("{first}.")));
        if !first_is_type && !is_ancestor
            && !is_imported_in_scope(wctx.scope_imports, module_prefix, first)
            && sk_get(known, effective).is_some()
            && !module_prefix.is_empty() {
                wctx.warnings.insert(format!("warning: in '{module_prefix}': '{qname}' uses package '{first}' which is not imported"));
            };
    }

    let (scope, name) = split_qname(effective);
    let ty = known.get(scope).and_then(|m| m.get(name))?;
    Some(variant_promotion(scope, name, ty, known))
}

// ── Hierarchy lookup helpers (used by codegen and typedexp) ──────────────────

/// Collect all type-variable names (from `Ty::TypeVar`) reachable inside `ty`.
/// Duplicates are suppressed. Suitable for deriving Rust generic parameters from resolved types.
pub(crate) fn collect_type_vars_in_ty(ty: &Ty, out: &mut Vec<String>) {
    match ty {
        Ty::TypeVar(name) => { if !out.contains(name) { out.push(name.clone()); } }
        Ty::Option(inner) | Ty::List(inner) | Ty::Array(inner) | Ty::Range(inner) => collect_type_vars_in_ty(inner, out),
        Ty::Tuple(tys) => tys.iter().for_each(|t| collect_type_vars_in_ty(t, out)),
        Ty::Generic(_, args) => args.iter().for_each(|t| collect_type_vars_in_ty(t, out)),
        Ty::Function { inputs, output, .. } => {
            inputs.iter().for_each(|inp| collect_type_vars_in_ty(&inp.ty, out));
            collect_type_vars_in_ty(output, out);
        }
        _ => {}
    }
}

/// Collect all type-variable names reachable in the value-types of an environment map.
pub(crate) fn collect_type_vars_in_env(env: &std::collections::HashMap<String, Ty>, out: &mut Vec<String>) {
    for ty in env.values() {
        collect_type_vars_in_ty(ty, out);
    }
}

pub(crate) fn lookup_node<'a>(dotted: &str, top_level: &'a BTreeMap<String, NameNode<'a>>) -> Option<&'a NameNode<'a>> {
    let mut parts = dotted.split('.');
    let first = parts.next().unwrap_or("");
    let mut node = top_level.get(first)?;
    for part in parts {
        node = node.children.get(part)?;
    }
    Some(node)
}

pub(crate) fn lookup_node_ty<'a>(dotted: &str, top_level: &'a BTreeMap<String, NameNode<'a>>) -> Option<&'a Ty> {
    lookup_node(dotted, top_level).map(|n| &n.ty)
}

/// Look up a record node, searching through intermediate uniontype children when
/// the direct path fails.
///
/// MetaModelica allows writing `Pkg.RECORD` when `RECORD` is actually a member of
/// a uniontype `Pkg.SomeUniontype`.  When `lookup_node("Pkg.RECORD")` fails, this
/// function tries `lookup_node("Pkg.U.RECORD")` for every uniontype child `U` of
/// `Pkg`.  If several matches exist the first one (alphabetical order from the
/// BTreeMap) is returned, which is deterministic.
///
/// Returns `(fully_qualified_dotted_path, &NameNode)` so callers can use the
/// canonical name for further lookups.
pub(crate) fn lookup_record_through_unions<'a>(
    dotted: &str,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
) -> Option<(String, &'a NameNode<'a>)> {
    // Fast path: direct lookup succeeds and names a real declaration. A package
    // that `import`s a same-named package (e.g. `BackendDAE` does `import DAE;`)
    // has an `Import` child `DAE`, so a `BackendDAE.DAE` lookup would otherwise
    // return that import node — masking the package's own uniontype record `DAE`,
    // which in MetaModelica shadows the import. Skip import children so the
    // uniontype walk below recovers the local record.
    if let Some(node) = lookup_node(dotted, top_level)
        && !matches!(&node.kind, NodeKind::Import(_))
    {
        return Some((dotted.to_owned(), node));
    }

    // The last segment is the record/constructor name we're looking for.
    let (parent_dotted, last) = dotted.rsplit_once('.')?;

    // Walk to the parent node.
    let parent = lookup_node(parent_dotted, top_level)?;

    // Try all direct children that are uniontypes.
    for (child_name, child_node) in &parent.children {
        if let NodeKind::Class(c) = &child_node.kind
            && matches!(c.restriction, Absyn::Restriction::R_UNIONTYPE)
                && let Some(rec_node) = child_node.children.get(last) {
                    let full = format!("{parent_dotted}.{child_name}.{last}");
                    return Some((full, rec_node));
                }
    }

    None
}

/// Strip wrapper nodes the parser adds around an expression without changing
/// its meaning: comment attachments (`EXPRESSIONCOMMENT`) and parentheses
/// (a single-element `TUPLE`, mirroring the regular omc parser — see
/// `Modelica.g` `primary` and Static.elabExp_Tuple_LHS_RHS). Use this before
/// matching on the *shape* of an `Absyn::Exp`; `infer_exp`/`infer_pat`
/// already unwrap both themselves.
pub(crate) fn strip_exp_wrappers(mut e: &Absyn::Exp) -> &Absyn::Exp {
    loop {
        match e {
            Absyn::Exp::EXPRESSIONCOMMENT { exp, .. } => e = exp,
            Absyn::Exp::TUPLE { expressions } => match &**expressions {
                metamodelica::List::Cons { head, tail } if tail.is_empty() => e = head,
                _ => return e,
            },
            _ => return e,
        }
    }
}

/// Extract the raw `Absyn::Exp` from a modification, for typed inference in codegen.
/// Comment and parenthesis wrappers are stripped so callers can match on the
/// expression's shape (literal constant folding, self-reference checks, …).
pub(crate) fn extract_default_exp(modification: &Option<std::sync::Arc<Absyn::Modification>>) -> Option<&Absyn::Exp> {
    match modification {
        Some(m) => match &*m.eqMod {
            Absyn::EqMod::EQMOD { exp, .. } => Some(strip_exp_wrappers(exp)),
            _ => None,
        },
        _ => None,
    }
}

// ── Expression helpers ────────────────────────────────────────────────────────

pub(crate) fn extract_default(modification: &Option<std::sync::Arc<Absyn::Modification>>) -> Option<String> {
    match modification {
        Some(m) => match &*m.eqMod {
            Absyn::EqMod::EQMOD { exp, .. } => Some(fmt_exp(exp)),
            _ => None,
        },
        _ => None,
    }
}

fn fmt_exp(exp: &Absyn::Exp) -> String {
    match exp {
        Absyn::Exp::INTEGER { value } => value.to_string(),
        Absyn::Exp::REAL { value } => value.to_string(),
        Absyn::Exp::STRING { value } => format!("\"{value}\""),
        Absyn::Exp::BOOL { value } => value.to_string(),
        Absyn::Exp::CREF { componentRef } => fmt_cref(componentRef),
        Absyn::Exp::UNARY { op, exp } => {
            let s = match op {
                Absyn::Operator::UMINUS | Absyn::Operator::UMINUS_EW => "-",
                Absyn::Operator::NOT => "!",
                _ => "+",
            };
            format!("{s}{}", fmt_exp(exp))
        }
        Absyn::Exp::LBINARY { exp1, op, exp2 } |
        Absyn::Exp::RELATION { exp1, op, exp2 } |
        Absyn::Exp::BINARY { exp1, op, exp2 } => {
            if op == &Absyn::Operator::EQUAL {
                // Constant-time string equality
                return format!("const_str::equal!({},{})", fmt_exp(exp1), fmt_exp(exp2));
            };
            let s = match op {
                Absyn::Operator::ADD | Absyn::Operator::ADD_EW => "+",
                Absyn::Operator::SUB | Absyn::Operator::SUB_EW => "-",
                Absyn::Operator::MUL | Absyn::Operator::MUL_EW => "*",
                Absyn::Operator::DIV | Absyn::Operator::DIV_EW => "/",
                Absyn::Operator::AND => "&&",
                Absyn::Operator::OR => "||",
                Absyn::Operator::LESS => "<",
                Absyn::Operator::LESSEQ => "<=",
                Absyn::Operator::GREATER => ">",
                Absyn::Operator::GREATEREQ => ">=",
                Absyn::Operator::EQUAL => "==",
                Absyn::Operator::NEQUAL => "!=",
                _ => "?",
            };
            format!("{} {s} {}", fmt_exp(exp1), fmt_exp(exp2))
        }
        Absyn::Exp::CALL { function_, functionArgs, .. } if matches!(&**functionArgs, Absyn::FunctionArgs::FUNCTIONARGS { .. }) => {
            let Absyn::FunctionArgs::FUNCTIONARGS { args, argNames } = &**functionArgs else { unreachable!() };
            let mut parts: Vec<String> = (&**args).into_iter().map(|a| fmt_exp(a.as_ref())).collect();
            for named in &**argNames {
                let Absyn::NamedArg { argName, argValue } = &**named;
                parts.push(format!("{argName}={}", fmt_exp(argValue.as_ref())));
            }
            format!("{}({})", fmt_cref(function_), parts.join(", "))
        }
        Absyn::Exp::ARRAY { arrayExp } => {
            let items: Vec<_> = (&**arrayExp).into_iter().map(|e| fmt_exp(e.as_ref())).collect();
            format!("{{{}}}", items.join(", "))
        }
        // A parenthesized source expression: the parser keeps `(e)` as a
        // single-element TUPLE. Emit the parentheses — this formatter
        // produces Rust expression text, where they are still significant.
        Absyn::Exp::TUPLE { expressions } => {
            let items: Vec<_> = (&**expressions).into_iter().map(|e| fmt_exp(e.as_ref())).collect();
            if let [single] = items.as_slice() {
                format!("({single})")
            } else {
                // A real tuple constant; Rust tuple syntax happens to match.
                format!("({})", items.join(", "))
            }
        }
        Absyn::Exp::IFEXP { ifExp, trueBranch, elseBranch, elseIfBranch } => {
            let else_if: String = (&**elseIfBranch).into_iter().map(|(cond, branch)| format!(" else if {} {{{}}}", fmt_exp(cond.as_ref()), fmt_exp(branch.as_ref()))).collect();
            format!("if {} {{{}}}{} else {{{}}}", fmt_exp(ifExp), fmt_exp(trueBranch), else_if, fmt_exp(elseBranch))
        }
        _ => format!("todo!(/*{:?}*/)", exp).to_owned(),
    }
}

fn fmt_cref(cref: &Absyn::ComponentRef) -> String {
    let raw = match cref {
        Absyn::ComponentRef::CREF_IDENT { name, .. } => name.to_string(),
        Absyn::ComponentRef::CREF_QUAL { name, componentRef, .. } => {
            format!("{name}.{}", fmt_cref(componentRef))
        }
        Absyn::ComponentRef::CREF_FULLYQUALIFIED { componentRef } => {
            format!(".{}", fmt_cref(componentRef))
        }
        Absyn::ComponentRef::WILD => "_".to_owned(),
        Absyn::ComponentRef::ALLWILD => "__".to_owned(),
    };
    match raw.as_str() {
        // The `*NoBoundsChecking` builtins are not normalised: they are distinct
        // functions lowered as real `metamodelica::Dangerous::*` calls (see
        // `typedexp::cref_to_dotted`).
        // Keep arrayCreateNoInit distinct from arrayCreate; codegen lowers it
        // to `metamodelica::Dangerous::arrayCreateNoInit(size)` (dropping the
        // dummy type-witness argument).
        "MetaModelica.Dangerous.arrayCreateNoInit" | "Dangerous.arrayCreateNoInit" | ".MetaModelica.Dangerous.arrayCreateNoInit" | "MetaModelica.arrayCreateNoInit" => "arrayCreateNoInit".to_owned(),
        "MetaModelica.Dangerous.listArrayLiteral" | "Dangerous.listArrayLiteral" | ".MetaModelica.Dangerous.listArrayLiteral" | "listArrayLiteral" => "listArray".to_owned(),
        // Destructive append: kept distinct from `listAppend` so codegen routes
        // it to the runtime's in-place implementation (see typedexp::cref_to_dotted).
        "MetaModelica.Dangerous.listAppendDestroy" | "Dangerous.listAppendDestroy" | ".MetaModelica.Dangerous.listAppendDestroy" | "listAppendDestroy" => "listAppendDestroy".to_owned(),
        _ => raw,
    }
}

// ── Display helpers ───────────────────────────────────────────────────────────

/// Extract the Rust-style name from a resolved type, for use as a generic base.
fn ty_rust_name(ty: &Ty) -> Option<String> {
    match ty {
        Ty::AliasTo(n) | Ty::RustEnum(n) | Ty::RustStruct(n) | Ty::Enumeration(n) => Some(n.replace('.', "::")),
        Ty::ExternalObject(n) => Some(n.replace('.', "::")),
        _ => None,
    }
}

fn qualify(prefix: &str, name: &str) -> String {
    if prefix.is_empty() { name.to_owned() } else { format!("{prefix}.{name}") }
}

fn path_last(path: &Absyn::Path) -> &str {
    match path {
        Absyn::Path::IDENT { name } => name,
        Absyn::Path::QUALIFIED { path, .. } => path_last(path),
        Absyn::Path::FULLYQUALIFIED { path } => path_last(path),
    }
}

fn fmt_path(path: &Absyn::Path) -> String {
    match path {
        Absyn::Path::IDENT { name } => name.to_string(),
        Absyn::Path::QUALIFIED { name, path } => format!("{name}.{}", fmt_path(path)),
        Absyn::Path::FULLYQUALIFIED { path } => format!(".{}", fmt_path(path)),
    }
}

fn fmt_type_spec(ts: &Absyn::TypeSpec) -> String {
    match ts {
        Absyn::TypeSpec::TPATH { path, .. } => fmt_path(path),
        Absyn::TypeSpec::TCOMPLEX { path, typeSpecs, .. } => {
            let args: Vec<_> = (&**typeSpecs).into_iter().map(|t| fmt_type_spec(t)).collect();
            format!("{}<{}>", fmt_path(path), args.join(", "))
        }
    }
}

fn fmt_restriction(r: &Absyn::Restriction) -> &'static str {
    use Absyn::Restriction::*;
    match r {
        R_CLASS => "class",
        R_OPTIMIZATION => "optimization",
        R_MODEL => "model",
        R_RECORD => "record",
        R_BLOCK => "block",
        R_CONNECTOR => "connector",
        R_EXP_CONNECTOR => "expandable connector",
        R_TYPE => "type",
        R_PACKAGE => "package",
        R_FUNCTION { .. } => "function",
        R_OPERATOR => "operator",
        R_OPERATOR_RECORD => "operator record",
        R_ENUMERATION => "enumeration",
        R_UNIONTYPE => "uniontype",
        R_METARECORD { .. } => "metarecord",
        _ => "class",
    }
}

fn fmt_import(m: &MM::ImportMember) -> String {
    match &m.import {
        Absyn::Import::NAMED_IMPORT { name, path } => format!("import {} = {}", name, fmt_path(path)),
        Absyn::Import::QUAL_IMPORT { path } => format!("import {}", fmt_path(path)),
        Absyn::Import::UNQUAL_IMPORT { path } => format!("import {}.*", fmt_path(path)),
        Absyn::Import::GROUP_IMPORT { prefix, groups } => {
            let names: Vec<String> = (&**groups).into_iter().map(|g| match g {
                Absyn::GroupImport::GROUP_IMPORT_NAME { name } => name.to_string(),
                Absyn::GroupImport::GROUP_IMPORT_RENAME { rename, name } => format!("{name} as {rename}"),
            }).collect();
            format!("import {}.{{{}}}", fmt_path(prefix), names.join(", "))
        }
    }
}

// ── Recursive type detection ──────────────────────────────────────────────────

/// Collect the qualified names of types that are directly size-embedded — i.e. not behind a
/// heap-allocated indirection.  Used to build the type-dependency graph for cycle detection.
/// `List<T>` (→ `metamodelica::List<T>`) and `Array<T>` (→ `Vec<T>`) are already heap-
/// allocated and therefore break any size-recursion cycle; they are excluded.
fn ty_direct_deps(ty: &Ty) -> Vec<String> {
    match ty {
        Ty::RustStruct(name) | Ty::RustEnum(name) | Ty::AliasTo(name) => vec![name.clone()],
        // A variant reference contributes a dep on its parent enum.
        Ty::UnionTypeVariant(union_qname, _) => vec![union_qname.clone()],
        // Option<T> embeds T inline in Rust — follow through.
        Ty::Option(inner) => ty_direct_deps(inner),
        // Tuple embeds all elements.
        Ty::Tuple(tys) => tys.iter().flat_map(ty_direct_deps).collect(),
        // List<T> has head: T inline (only tail is Arc); follow through.
        Ty::List(inner) => ty_direct_deps(inner),
        // Array (Vec<T>) is fully heap-allocated — skip.
        Ty::Array(_) => vec![],
        // Generic instantiation: the base type is embedded directly (not heap-allocated),
        // so it participates in size cycles just like a plain reference.
        // `name` is stored in `::` form; convert to dotted form to match graph keys.
        Ty::Generic(name, args) => {
            let mut deps = vec![name.replace("::", ".")];
            deps.extend(args.iter().flat_map(ty_direct_deps));
            deps
        }
        _ => vec![],
    }
}

fn collect_type_graph(
    nodes: &BTreeMap<String, NameNode<'_>>,
    prefix: &str,
    graph: &mut BTreeMap<String, BTreeSet<String>>,
) {
    for (name, node) in nodes {
        let qname = qualify(prefix, name);
        match &node.ty {
            Ty::RustStruct(_) => {
                let deps: BTreeSet<String> = node.children.values()
                    .filter(|c| matches!(c.kind, NodeKind::Component(_)))
                    .flat_map(|c| ty_direct_deps(&c.ty))
                    .collect();
                graph.insert(qname.clone(), deps);
            }
            Ty::RustEnum(_) | Ty::AliasTo(_) => {
                // The enum's size is the max of all its variants' sizes; follow all variant fields.
                let deps: BTreeSet<String> = node.children.values()
                    .flat_map(|variant| {
                        variant.children.values()
                            .filter(|c| matches!(c.kind, NodeKind::Component(_)))
                            .flat_map(|c| ty_direct_deps(&c.ty))
                    })
                    .collect();
                graph.insert(qname.clone(), deps);
            }
            _ => {}
        }
        collect_type_graph(&node.children, &qname, graph);
    }
}

/// Detect which named types form size-recursive cycles (directly or mutually).
/// Populates `hier.recursive_types` with the fully-qualified names of all such types.
/// Must be called after `resolve_pass` has converged.
pub fn detect_recursive_types(hier: &mut InstanceHierarchy<'_>) {
    let mut graph: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
    collect_type_graph(&hier.top_level, "", &mut graph);

    let nodes: Vec<String> = graph.keys().cloned().collect();
    // 0 = white (unvisited), 1 = gray (on stack), 2 = black (done)
    let mut color: BTreeMap<String, u8> = BTreeMap::new();
    let mut path_stack: Vec<String> = Vec::new();
    let mut call_stack: Vec<(String, Vec<String>, usize)> = Vec::new();

    for start in &nodes {
        if color.get(start.as_str()).copied().unwrap_or(0) != 0 {
            continue;
        }
        color.insert(start.clone(), 1);
        path_stack.push(start.clone());
        let deps: Vec<String> = graph.get(start).map(|d| d.iter().cloned().collect()).unwrap_or_default();
        call_stack.push((start.clone(), deps, 0));

        while !call_stack.is_empty() {
            let has_more = {
                let (_, deps, idx) = call_stack.last().unwrap();
                *idx < deps.len()
            };
            if has_more {
                let dep = {
                    let (_, deps, idx) = call_stack.last_mut().unwrap();
                    let d = deps[*idx].clone();
                    *idx += 1;
                    d
                };
                match color.get(dep.as_str()).copied().unwrap_or(0) {
                    1 => {
                        // Back edge to a gray node — every node from dep's position to the
                        // top of path_stack is part of this cycle.
                        let cycle_start = path_stack.iter().position(|s| s == &dep).unwrap_or(0);
                        for s in &path_stack[cycle_start..] {
                            hier.recursive_types.insert(s.clone());
                        }
                    }
                    0 => {
                        color.insert(dep.clone(), 1);
                        path_stack.push(dep.clone());
                        let new_deps: Vec<String> = graph.get(&dep)
                            .map(|d| d.iter().cloned().collect())
                            .unwrap_or_default();
                        call_stack.push((dep, new_deps, 0));
                    }
                    _ => {} // black — already fully explored
                }
            } else {
                let (done_node, _, _) = call_stack.pop().unwrap();
                color.insert(done_node, 2);
                path_stack.pop();
            }
        }
    }
}

// ── Mutable-containment detection ─────────────────────────────────────────────

/// Collect, for every user-defined struct/enum/uniontype `qname`, the resolved
/// `Ty`s of all of its component fields (variant fields in the enum/uniontype
/// case). Used as the input to the `Mutable`-containment fixed point.
pub(crate) fn collect_struct_field_tys(
    nodes: &BTreeMap<String, NameNode<'_>>,
    prefix: &str,
    out: &mut BTreeMap<String, Vec<Ty>>,
) {
    for (name, node) in nodes {
        let qname = qualify(prefix, name);
        match &node.ty {
            Ty::RustStruct(_) => {
                let tys: Vec<Ty> = node.children.values()
                    .filter(|c| matches!(c.kind, NodeKind::Component(_)))
                    .map(|c| c.ty.clone())
                    .collect();
                out.insert(qname.clone(), tys);
            }
            Ty::RustEnum(_) | Ty::AliasTo(_) => {
                // Restrict to variant nodes (records) — a uniontype/enum
                // may also have sibling functions (utility members,
                // nested partial functions) which have their own
                // input/output Components that are NOT fields of this
                // type. Without the filter, those component types
                // would pollute the field-ty graph and mis-flag the
                // enclosing type as "containing" whatever those
                // function args happen to be (e.g. an `Arc<dyn Fn>`
                // parameter in some sibling function).
                let tys: Vec<Ty> = node.children.values()
                    .filter(|v| matches!(v.ty, Ty::RustStruct(_) | Ty::RustUnitVariant))
                    .flat_map(|variant| variant.children.values()
                        .filter(|c| matches!(c.kind, NodeKind::Component(_)))
                        .map(|c| c.ty.clone()))
                    .collect();
                out.insert(qname.clone(), tys);
            }
            _ => {}
        }
        collect_struct_field_tys(&node.children, &qname, out);
    }
}

/// True if `ty` mentions a `Mutable<...>` anywhere in its structure, considering
/// the (currently known) set of `tainted` user-defined types as also containing
/// `Mutable`. Container types (`Option`, `List`, `Array`, `Tuple`, `Generic`)
/// propagate the property because `#[derive(PartialEq)]` on a struct with a
/// field `List<MyOther>` requires `MyOther: PartialEq`.
fn ty_contains_mutable(ty: &Ty, tainted: &BTreeSet<String>) -> bool {
    match ty {
        Ty::Generic(name, args) => {
            // `name` is stored in `::` form (Rust path); normalise back to dotted
            // form to match graph keys.
            let dotted = name.replace("::", ".");
            dotted == "Mutable"
                || tainted.contains(&dotted)
                || args.iter().any(|a| ty_contains_mutable(a, tainted))
        }
        Ty::Option(t) | Ty::List(t) | Ty::Array(t) | Ty::Range(t) => ty_contains_mutable(t, tainted),
        Ty::Tuple(ts) => ts.iter().any(|t| ty_contains_mutable(t, tainted)),
        Ty::RustStruct(qname) | Ty::RustEnum(qname) | Ty::AliasTo(qname) => tainted.contains(qname),
        Ty::UnionTypeVariant(qname, _) => tainted.contains(qname),
        _ => false,
    }
}

/// Detect which named types transitively contain a `Mutable<T>` field and
/// therefore cannot derive `PartialEq` / `Eq` / `Hash` (because `Mutex<T>`
/// implements none of those traits). Must be called after `resolve_pass` has
/// converged so all field types are populated.
pub fn detect_types_containing_mutable(hier: &mut InstanceHierarchy<'_>) {
    let mut graph: BTreeMap<String, Vec<Ty>> = BTreeMap::new();
    collect_struct_field_tys(&hier.top_level, "", &mut graph);

    let mut tainted: BTreeSet<String> = BTreeSet::new();
    loop {
        let mut changed = false;
        for (qname, field_tys) in &graph {
            if tainted.contains(qname) { continue; }
            if field_tys.iter().any(|t| ty_contains_mutable(t, &tainted)) {
                tainted.insert(qname.clone());
                changed = true;
            }
        }
        if !changed { break; }
    }
    hier.types_containing_mutable = tainted;
}

/// True if `ty` mentions a MetaModelica `Array<...>` anywhere in its structure,
/// considering the (currently known) set of `tainted` user-defined types as also
/// containing `Array`. `Array<T> = Rc<RefCell<Vec<T>>>` is not `Sync`, so a
/// `pub static` of such a type fails to compile. Mirrors [`ty_contains_mutable`]
/// but for the `Array<_>` constructor specifically.
fn ty_contains_array(ty: &Ty, tainted: &BTreeSet<String>) -> bool {
    match ty {
        Ty::Array(_) => true,
        Ty::Option(t) | Ty::List(t) | Ty::Range(t) => ty_contains_array(t, tainted),
        Ty::Tuple(ts) => ts.iter().any(|t| ty_contains_array(t, tainted)),
        Ty::Generic(name, args) => {
            // Mirror the `ty_contains_mutable` rule: a generic
            // constructor name `Foo::Bar` may itself be a tainted
            // user-defined type (e.g. `UnorderedSet::UnorderedSet`,
            // whose buckets are an `Array<T>`). Normalise the `::`
            // path to dotted form to match the graph keys.
            let dotted = name.replace("::", ".");
            tainted.contains(&dotted)
                || args.iter().any(|a| ty_contains_array(a, tainted))
        }
        Ty::RustStruct(qname) | Ty::RustEnum(qname) | Ty::AliasTo(qname) => tainted.contains(qname),
        Ty::UnionTypeVariant(qname, _) => tainted.contains(qname),
        _ => false,
    }
}

/// Detect which named types transitively contain a `metamodelica::Array<T>` field.
/// Such types are not `Sync` (because `Rc`/`RefCell` aren't), so they cannot be
/// stored in a `pub static`. Codegen consults the result to pick `pub const fn`
/// getter emission instead of `pub static` for affected constants. Must be called
/// after `resolve_pass` has converged so all field types are populated.
/// True if `ty` mentions a function type (lowered to `Arc<dyn Fn(...)>` by
/// codegen) anywhere in its structure. User-defined types are tainted
/// transitively via the `tainted` set. `Ty::FunctionAlias` resolves to a
/// `Ty::Function` underneath and is treated as `Arc<dyn Fn>` at the alias
/// level too. `Ty::Generic` carries the constructor name in `::` form
/// (Rust path); normalise to dotted form to match graph keys.
fn ty_contains_dyn_fn(ty: &Ty, tainted: &BTreeSet<String>) -> bool {
    match ty {
        Ty::Function { .. } | Ty::FunctionAlias { .. } => true,
        Ty::Option(t) | Ty::List(t) | Ty::Range(t) | Ty::Array(t) => ty_contains_dyn_fn(t, tainted),
        Ty::Tuple(ts) => ts.iter().any(|t| ty_contains_dyn_fn(t, tainted)),
        Ty::Generic(name, args) => {
            let dotted = name.replace("::", ".");
            tainted.contains(&dotted)
                || args.iter().any(|a| ty_contains_dyn_fn(a, tainted))
        }
        Ty::RustStruct(qname) | Ty::RustEnum(qname) | Ty::AliasTo(qname) => tainted.contains(qname),
        Ty::UnionTypeVariant(qname, _) => tainted.contains(qname),
        _ => false,
    }
}

/// True if `ty` *directly* embeds a function type, i.e. without crossing
/// into another user-defined struct/enum. Used to distinguish types that
/// need a hand-rolled `PartialEq` / `Eq` / `PartialOrd` / `Ord` / `Hash`
/// / `Debug` impl (because at least one of their own fields is an
/// `Arc<dyn Fn(...)>` and `dyn Fn` implements none of those traits) from
/// transitive containers, which can still `#[derive(...)]` as long as
/// their direct dependents provide the impls themselves.
pub(crate) fn ty_directly_contains_dyn_fn(ty: &Ty) -> bool {
    match ty {
        Ty::Function { .. } | Ty::FunctionAlias { .. } => true,
        Ty::Option(t) | Ty::List(t) | Ty::Range(t) | Ty::Array(t) => ty_directly_contains_dyn_fn(t),
        Ty::Tuple(ts) => ts.iter().any(ty_directly_contains_dyn_fn),
        Ty::Generic(_, args) => args.iter().any(ty_directly_contains_dyn_fn),
        // Crossing into another user-defined type does NOT count as direct.
        _ => false,
    }
}

/// Detect which named types transitively contain a function-typed field.
/// Codegen lowers function types to `Arc<dyn Fn(...) + 'static>`, which is
/// none of `Debug` / `PartialEq` / `Eq` / `PartialOrd` / `Ord` / `Hash` —
/// so any `#[derive]`-generated impl on a containing type fails. The same
/// types are also not `Sync` (no `+ Send + Sync` bound on the trait
/// object), so they cannot live in a `pub static`. Codegen consults this
/// set in `derives_for` (drop derives) and `ty_is_sync` (route via
/// `thread_local! + getter` rather than `pub static LazyLock<T>`).
/// Must be called after `resolve_pass` has converged so all field types
/// are populated.
pub fn detect_types_containing_dyn_fn(hier: &mut InstanceHierarchy<'_>) {
    let mut graph: BTreeMap<String, Vec<Ty>> = BTreeMap::new();
    collect_struct_field_tys(&hier.top_level, "", &mut graph);

    // Direct containers: types whose own fields embed a function type
    // without traversing into another user-defined struct/enum. These
    // need hand-rolled `PartialEq`/`Eq`/`PartialOrd`/`Ord`/`Hash`/`Debug`
    // because `Arc<dyn Fn>` doesn't implement any of those.
    let mut direct: BTreeSet<String> = BTreeSet::new();
    for (qname, field_tys) in &graph {
        if field_tys.iter().any(ty_directly_contains_dyn_fn) {
            direct.insert(qname.clone());
        }
    }

    // Transitive containers (including direct): used by `ty_is_sync` to
    // route affected `pub static`s through `thread_local!` instead.
    let mut tainted: BTreeSet<String> = BTreeSet::new();
    loop {
        let mut changed = false;
        for (qname, field_tys) in &graph {
            if tainted.contains(qname) { continue; }
            if field_tys.iter().any(|t| ty_contains_dyn_fn(t, &tainted)) {
                tainted.insert(qname.clone());
                changed = true;
            }
        }
        if !changed { break; }
    }
    hier.types_containing_dyn_fn = tainted;
    hier.types_directly_containing_dyn_fn = direct;
}

pub fn detect_types_containing_array(hier: &mut InstanceHierarchy<'_>) {
    let mut graph: BTreeMap<String, Vec<Ty>> = BTreeMap::new();
    collect_struct_field_tys(&hier.top_level, "", &mut graph);

    let mut tainted: BTreeSet<String> = BTreeSet::new();
    loop {
        let mut changed = false;
        for (qname, field_tys) in &graph {
            if tainted.contains(qname) { continue; }
            if field_tys.iter().any(|t| ty_contains_array(t, &tainted)) {
                tainted.insert(qname.clone());
                changed = true;
            }
        }
        if !changed { break; }
    }
    hier.types_containing_array = tainted;
}

// ── Pretty-printing ───────────────────────────────────────────────────────────

impl fmt::Display for InstanceHierarchy<'_> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let mut names: Vec<_> = self.top_level.iter()
            .filter(|(_, node)| !matches!(&node.kind, NodeKind::Class(c) if c.info.fileName.ends_with("NFModelicaBuiltin.mo")))
            .collect();
        names.sort_by_key(|(n, _)| n.as_str());
        writeln!(f, "Hierarchy ({} top-level classes):", names.len())?;
        for (i, (name, node)) in names.iter().enumerate() {
            fmt_node(f, name, node, "", i + 1 == names.len())?;
        }
        Ok(())
    }
}

/// Write `{ field1: Type1, field2: Type2 }` for a struct node, in declaration order.
fn fmt_struct_fields(
    f: &mut fmt::Formatter<'_>,
    c: &MM::Class,
    children: &BTreeMap<String, NameNode<'_>>,
) -> fmt::Result {
    let members: &[MM::ClassMember] = match &c.body {
        MM::ClassDef::Parts { members, .. } => members,
        MM::ClassDef::ClassExtends { members, .. } => members,
        _ => return write!(f, "{{}}"),
    };
    write!(f, "{{ ")?;
    let mut first = true;
    for member in members {
        if let MM::ClassMember::Component(m) = member {
            if !first { write!(f, ", ")?; }
            let ty = children.get(&m.name).map(|n| &n.ty).unwrap_or(&Ty::Unknown);
            write!(f, "{}: {ty}", m.name)?;
            first = false;
        }
    }
    write!(f, " }}")
}

fn fmt_node(
    f: &mut fmt::Formatter<'_>,
    name: &str,
    node: &NameNode<'_>,
    prefix: &str,
    is_last: bool,
) -> fmt::Result {
    let connector = if is_last { "└─ " } else { "├─ " };
    write!(f, "{prefix}{connector}{name}")?;

    match &node.kind {
        NodeKind::Class(c) => {
            write!(f, " [{}]", fmt_restriction(&c.restriction))?;
            if let MM::ClassDef::Derived { type_spec, .. } = &c.body {
                write!(f, " = {}", fmt_type_spec(type_spec))?;
            }
        }
        NodeKind::Component(m) => {
            write!(f, " : {}", fmt_type_spec(&m.type_spec))?;
            if let Some(default) = extract_default(&m.modification) {
                write!(f, " = {default}")?;
            }
        }
        NodeKind::Import(m) => write!(f, "  // {}", fmt_import(m))?,
        NodeKind::EnumLiteral => {}
    }

    let has_no_type = matches!(&node.kind, NodeKind::Import(_))
        || matches!(&node.kind, NodeKind::Class(c) if matches!(c.restriction, Absyn::Restriction::R_PACKAGE));

    match &node.ty {
        Ty::Unknown if has_no_type => writeln!(f)?,
        Ty::Unknown => writeln!(f, "  [?]")?,
        Ty::RustStruct(_) => {
            // Show fields inline in declaration order; fall back to the name if no body.
            if let NodeKind::Class(c) = &node.kind {
                write!(f, "  ")?;
                fmt_struct_fields(f, c, &node.children)?;
                writeln!(f)?;
            } else {
                writeln!(f, "  [{}]", node.ty)?;
            }
        }
        ty => writeln!(f, "  [{ty}]")?,
    }

    let child_prefix = format!("{}{}", prefix, if is_last { "   " } else { "│  " });
    let mut children: Vec<_> = node.children.iter().collect();
    children.sort_by_key(|(n, _)| n.as_str());
    let total = children.len() + node.extends.len();

    for (i, (child_name, child_node)) in children.iter().enumerate() {
        fmt_node(f, child_name, child_node, &child_prefix, i + 1 == total)?;
    }
    for (i, ext) in node.extends.iter().enumerate() {
        let ext_last = children.len() + i + 1 == total;
        let conn = if ext_last { "└─ " } else { "├─ " };
        writeln!(f, "{child_prefix}{conn}extends {}", fmt_path(&ext.path))?;
    }
    Ok(())
}
