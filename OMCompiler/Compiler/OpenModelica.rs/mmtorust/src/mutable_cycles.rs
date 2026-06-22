//! `mutable-cycles` subcommand: report which generated datatypes can sit on
//! reference cycles created through mutable cells.
//!
//! Informational: the runtime's trial-deletion collector
//! (`metamodelica::gc::collect`) works over the `Arc` representation and
//! needs no per-type opt-in, so this analysis no longer gates code
//! generation. It remains useful for auditing where cycles can arise (e.g.
//! when judging whether a `GCExt.gcollect` call site is worthwhile) and for
//! sizing a future "skip registering never-cyclic cells" optimization.
//!
//! Background: immutable `Arc` values are constructed bottom-up and can never
//! be cyclic on their own. A heap cycle can only be closed by *updating* a
//! cell (`Mutable.update` / `Pointer.update`) with a value that transitively
//! contains the cell. Therefore a named type `U` can participate in a cycle
//! only if both
//!   1. `U` is transitively *contained in* some content type `T` that is
//!      actually stored into a cell via an update call, and
//!   2. `U` lies on a cycle of the type-containment graph that crosses a
//!      cell edge — i.e. `U` can reach a `Mutable<T'>`/`Pointer<T'>` field
//!      whose content `T'` reaches `U` again. Merely *reaching* some cell is
//!      not enough: a dead-end `Mutable<Integer>` field (e.g. `Tpl`'s
//!      `BT_ITER.index0`) cannot continue a cycle because its content
//!      terminates. Formally: `U` is in a strongly connected component of
//!      the containment graph that contains an edge crossing a cell.
//! The intersection of those two sets is exactly the set of types whose
//! `Arc`s may sit on a cycle — the types that would need `Gc` + `Trace`.
//! Types outside the set can keep plain `Arc` (a `Trace` impl that visits
//! nothing is sound for them because they can never reach a `Gc` allocation).
//!
//! The analysis:
//!   * types every function body and records calls to the cell updaters,
//!     taking the concrete cell content type at each call site;
//!   * runs a fixed point to discover *generic updater wrappers* (functions
//!     like `Pointer.apply` whose body updates a cell whose content type is
//!     still a type variable) and re-attributes their call sites to the
//!     concrete argument types at the callers;
//!   * computes downward containment reachability from the recorded content
//!     types and the "can reach a cell field" fixed point, and intersects.
//!
//! Reported in two scopes: `Mutable`-only (the user-facing question) and
//! `Mutable`+`Pointer` (the honest total — `Pointer` is the same
//! `Arc<Mutex<..>>` cell pattern and e.g. `InstNode.cls` cycles go through it).
//!
//! The reported sets contain the *payload* types. Generic container types
//! (`Mutable`, `Pointer`, `Vector`, `UnorderedMap`, `DoubleEnded`, …) are
//! deliberately absent even though their allocations sit on runtime cycles
//! whenever their element type does: in Rust they stay generic and need one
//! conditional `Trace` impl (`T: Trace ⇒ Container<T>: Trace`), not a
//! per-instantiation conversion, so listing them per payload would be noise.
//! The instantiation edge `Container<A> → A` is still followed (labeled with
//! the cell kinds the container stores its payload under, see
//! [`tv_under_cells`]), which is what puts the payloads on the cycle.
//!
//! Known limitations (all conservative in the "may miss a site" direction,
//! flagged in the report where detectable):
//!   * an updater passed as a first-class function value (`PartEval` of
//!     `Mutable.update`) is only caught when the cell is bound at the
//!     partial-application site itself;
//!   * cells smuggled through `Arc<dyn Fn>` captures are invisible to the
//!     containment graph (the dyn-fn overlap section quantifies the risk).

use std::collections::{BTreeMap, BTreeSet};

use rayon::prelude::*;

use crate::codegen;
use crate::hierarchy::{self, InstanceHierarchy, Ty};
use crate::typedexp::{TypedCase, TypedExp, TypedStmt};

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Debug)]
pub enum CellKind {
    Mutable,
    Pointer,
}

impl std::fmt::Display for CellKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CellKind::Mutable => write!(f, "Mutable"),
            CellKind::Pointer => write!(f, "Pointer"),
        }
    }
}

/// One concrete update call site: in `function`, a call to `callee` passed a
/// cell of kind `kind` whose content type resolved to `content` (no type
/// variables left).
pub struct UpdateSite {
    pub function: String,
    pub callee: String,
    pub kind: CellKind,
    pub content: Ty,
}

pub struct Report {
    pub sites: Vec<UpdateSite>,
    /// Functions discovered to update a cell whose content is still generic
    /// at their level (wrappers); their call sites were re-attributed.
    pub generic_updaters: BTreeMap<String, BTreeSet<CellKind>>,
    /// Update sites whose cell content type never became concrete (e.g. the
    /// updater value escaped as a closure) — potential blind spots.
    pub unresolved_generic_sites: Vec<(String, String)>,
    /// Named types needing Arc→Gc, Mutable-only scope.
    pub gc_types_mutable_only: BTreeSet<String>,
    /// Named types needing Arc→Gc, Mutable+Pointer scope.
    pub gc_types_full: BTreeSet<String>,
    /// Subset of `gc_types_full` that transitively embeds an `Arc<dyn Fn>`
    /// field — untraceable edges, the hard part for any `Trace` derive.
    pub gc_types_with_dyn_fn: BTreeSet<String>,
}

/// If `ty` is a cell type, return its kind and content type. The `Mutable`
/// constructor is built in (`Ty::Generic("Mutable", [T])`); `Pointer` is the
/// MM uniontype `Pointer.Pointer`, whose generic constructor name may appear
/// in either dotted or `::` path form depending on the resolution path.
fn cell_content(ty: &Ty) -> Option<(CellKind, &Ty)> {
    if let Ty::Generic(name, args) = ty
        && args.len() == 1
    {
        let dotted = name.replace("::", ".");
        match dotted.as_str() {
            "Mutable" | "Mutable.Mutable" => return Some((CellKind::Mutable, &args[0])),
            "Pointer" | "Pointer.Pointer" => return Some((CellKind::Pointer, &args[0])),
            _ => {}
        }
    }
    None
}

/// Collect the qualified names of user-defined named types mentioned anywhere
/// in `ty`, recursing through containers *and* cells (a cycle may pass
/// through nested cells). Function types are opaque: their captures are not
/// part of the containment graph (see module doc on dyn-fn blind spots).
fn collect_named_types(ty: &Ty, out: &mut BTreeSet<String>) {
    match ty {
        Ty::Option(t) | Ty::List(t) | Ty::Array(t) | Ty::Range(t) => collect_named_types(t, out),
        Ty::Tuple(ts) => ts.iter().for_each(|t| collect_named_types(t, out)),
        Ty::Generic(name, args) => {
            let dotted = name.replace("::", ".");
            // `Mutable` is not a user type; `Pointer.Pointer` is, but as a
            // cell it is handled by the reach-back side, not as a Gc payload
            // by itself. Other generics (UnorderedMap, Vector, …) are user
            // types that themselves embed fields.
            if !matches!(dotted.as_str(), "Mutable" | "Mutable.Mutable" | "Pointer" | "Pointer.Pointer") {
                out.insert(dotted);
            }
            args.iter().for_each(|t| collect_named_types(t, out));
        }
        Ty::RustStruct(q) | Ty::RustEnum(q) | Ty::AliasTo(q) | Ty::Enumeration(q) => {
            out.insert(q.clone());
        }
        Ty::UnionTypeVariant(q, _) => {
            out.insert(q.clone());
        }
        _ => {}
    }
}

fn ty_has_type_var(ty: &Ty) -> bool {
    match ty {
        Ty::TypeVar(_) => true,
        Ty::Option(t) | Ty::List(t) | Ty::Array(t) | Ty::Range(t) => ty_has_type_var(t),
        Ty::Tuple(ts) => ts.iter().any(ty_has_type_var),
        Ty::Generic(_, args) => args.iter().any(ty_has_type_var),
        Ty::Function { inputs, output, .. } => {
            inputs.iter().any(|i| ty_has_type_var(&i.ty)) || ty_has_type_var(output)
        }
        _ => false,
    }
}

// ── typed-body call walker ────────────────────────────────────────────────────

/// Visit every call-like node (`Call` and `PartEval`) in an expression,
/// handing the callee name and all argument expressions (positional then
/// named) to `f`. Exhaustive over `TypedExp` so new variants fail to compile
/// here rather than being silently skipped.
fn visit_exp(e: &TypedExp, f: &mut impl FnMut(&str, Vec<&TypedExp>)) {
    match e {
        TypedExp::Lit(_) | TypedExp::Todo(_) => {}
        TypedExp::Var { segments, .. } => {
            for seg in segments {
                for sub in &seg.subscripts {
                    visit_exp(sub, f);
                }
            }
        }
        TypedExp::BinOp { lhs, rhs, .. } => {
            visit_exp(lhs, f);
            visit_exp(rhs, f);
        }
        TypedExp::UnOp { operand, .. } => visit_exp(operand, f),
        TypedExp::Call { func, args, named_args, .. }
        | TypedExp::PartEval { func, args, named_args, .. } => {
            let mut all: Vec<&TypedExp> = args.iter().collect();
            all.extend(named_args.iter().map(|(_, v)| v));
            f(func, all);
            for a in args {
                visit_exp(a, f);
            }
            for (_, v) in named_args {
                visit_exp(v, f);
            }
        }
        TypedExp::Constructor { args, named_args, .. } => {
            for a in args {
                visit_exp(a, f);
            }
            for (_, v) in named_args {
                visit_exp(v, f);
            }
        }
        TypedExp::If { cond, then_, elseif, else_, .. } => {
            visit_exp(cond, f);
            visit_exp(then_, f);
            for (c, t) in elseif {
                visit_exp(c, f);
                visit_exp(t, f);
            }
            visit_exp(else_, f);
        }
        TypedExp::Cons { head, tail, .. } => {
            visit_exp(head, f);
            visit_exp(tail, f);
        }
        TypedExp::Tuple(es) => es.iter().for_each(|e| visit_exp(e, f)),
        TypedExp::Array { elems, .. } => elems.iter().for_each(|e| visit_exp(e, f)),
        TypedExp::Match { input, cases, .. } => {
            visit_exp(input, f);
            for TypedCase { guard, locals, stmts, result, .. } in cases {
                if let Some(g) = guard {
                    visit_exp(g, f);
                }
                for (_, _, default, _) in locals {
                    if let Some(d) = default {
                        visit_exp(d, f);
                    }
                }
                for s in stmts {
                    visit_stmt(s, f);
                }
                visit_exp(result, f);
            }
        }
        TypedExp::Range { start, step, stop, .. } => {
            visit_exp(start, f);
            if let Some(s) = step {
                visit_exp(s, f);
            }
            visit_exp(stop, f);
        }
        TypedExp::Reduction { body, iterators, .. } => {
            visit_exp(body, f);
            for it in iterators {
                visit_exp(&it.range, f);
                if let Some(g) = &it.guard {
                    visit_exp(g, f);
                }
            }
        }
    }
}

fn visit_stmt(s: &TypedStmt, f: &mut impl FnMut(&str, Vec<&TypedExp>)) {
    match s {
        TypedStmt::Assign { rhs, .. } => visit_exp(rhs, f),
        TypedStmt::NoRetCall { call } => visit_exp(call, f),
        TypedStmt::If { cond, then_, elseif, else_ } => {
            visit_exp(cond, f);
            then_.iter().for_each(|s| visit_stmt(s, f));
            for (c, body) in elseif {
                visit_exp(c, f);
                body.iter().for_each(|s| visit_stmt(s, f));
            }
            else_.iter().for_each(|s| visit_stmt(s, f));
        }
        TypedStmt::For { range, body, .. } => {
            visit_exp(range, f);
            body.iter().for_each(|s| visit_stmt(s, f));
        }
        TypedStmt::While { cond, body } => {
            visit_exp(cond, f);
            body.iter().for_each(|s| visit_stmt(s, f));
        }
        TypedStmt::Try { body, else_body } => {
            body.iter().for_each(|s| visit_stmt(s, f));
            else_body.iter().for_each(|s| visit_stmt(s, f));
        }
        TypedStmt::Failure { body } => body.iter().for_each(|s| visit_stmt(s, f)),
        TypedStmt::Return | TypedStmt::Break | TypedStmt::Continue | TypedStmt::Todo(_) => {}
    }
}

// ── reach-back fixed point ────────────────────────────────────────────────────

/// True if `ty` mentions a cell of one of `kinds` anywhere, treating the
/// `tainted` user types as cell-containing. Mirrors
/// `hierarchy::ty_contains_mutable` but parameterised over the cell kinds.
fn ty_contains_cell(ty: &Ty, kinds: &[CellKind], tainted: &BTreeSet<String>) -> bool {
    if let Some((k, _)) = cell_content(ty)
        && kinds.contains(&k)
    {
        return true;
    }
    match ty {
        Ty::Generic(name, args) => {
            let dotted = name.replace("::", ".");
            tainted.contains(&dotted) || args.iter().any(|a| ty_contains_cell(a, kinds, tainted))
        }
        Ty::Option(t) | Ty::List(t) | Ty::Array(t) | Ty::Range(t) => {
            ty_contains_cell(t, kinds, tainted)
        }
        Ty::Tuple(ts) => ts.iter().any(|t| ty_contains_cell(t, kinds, tainted)),
        Ty::RustStruct(q) | Ty::RustEnum(q) | Ty::AliasTo(q) => tainted.contains(q),
        Ty::UnionTypeVariant(q, _) => tainted.contains(q),
        _ => false,
    }
}

fn types_containing_cell(
    graph: &BTreeMap<String, Vec<Ty>>,
    kinds: &[CellKind],
) -> BTreeSet<String> {
    let mut tainted = BTreeSet::new();
    loop {
        let mut changed = false;
        for (qname, field_tys) in graph {
            if tainted.contains(qname) {
                continue;
            }
            if field_tys.iter().any(|t| ty_contains_cell(t, kinds, &tainted)) {
                tainted.insert(qname.clone());
                changed = true;
            }
        }
        if !changed {
            return tainted;
        }
    }
}

/// All named types transitively contained in the `seeds` (downward
/// containment closure over the field graph, crossing containers and cells).
fn downward_reach(graph: &BTreeMap<String, Vec<Ty>>, seeds: &BTreeSet<String>) -> BTreeSet<String> {
    let mut reached = seeds.clone();
    let mut frontier: Vec<String> = seeds.iter().cloned().collect();
    while let Some(q) = frontier.pop() {
        let Some(field_tys) = graph.get(&q) else { continue };
        let mut succ = BTreeSet::new();
        for t in field_tys {
            collect_named_types(t, &mut succ);
        }
        for s in succ {
            if reached.insert(s.clone()) {
                frontier.push(s);
            }
        }
    }
    reached
}

// ── cell-crossing containment cycles (SCC analysis) ──────────────────────────
//
// A named type can be cyclic at runtime only if the *type* containment graph
// has a cycle through it that crosses a cell (`Mutable`/`Pointer`) edge:
// immutable recursion (lists, expression trees) is constructed bottom-up and
// can never alias back, and a cell whose content type cannot reach the cycle
// again (`Mutable<Integer>`) is a dead end. We label every containment edge
// with the set of cell kinds crossed on the way to the target type, run
// Tarjan SCC, and keep the members of components containing an internal
// cell-crossing edge.

/// Per generic type `G`, the cell kinds under which a type variable of `G`
/// is stored in `G`'s own fields (transitively through other generics'
/// instantiations — e.g. `UnorderedMap` storing keys inside a `Vector`,
/// whose payload sits behind a `Mutable<array<T>>`). Needed to label the
/// implicit containment edge from an instantiation `G<A>` to `A`.
fn tv_under_cells(graph: &BTreeMap<String, Vec<Ty>>) -> BTreeMap<String, BTreeSet<CellKind>> {
    fn collect(
        ty: &Ty,
        crossed: &BTreeSet<CellKind>,
        tv_under: &BTreeMap<String, BTreeSet<CellKind>>,
        out: &mut BTreeSet<CellKind>,
    ) {
        if let Some((k, content)) = cell_content(ty) {
            let mut c = crossed.clone();
            c.insert(k);
            collect(content, &c, tv_under, out);
            return;
        }
        match ty {
            Ty::TypeVar(_) => out.extend(crossed.iter().copied()),
            Ty::Option(t) | Ty::List(t) | Ty::Array(t) | Ty::Range(t) => {
                collect(t, crossed, tv_under, out)
            }
            Ty::Tuple(ts) => ts.iter().for_each(|t| collect(t, crossed, tv_under, out)),
            Ty::Generic(name, args) => {
                let dotted = name.replace("::", ".");
                let mut c = crossed.clone();
                if let Some(extra) = tv_under.get(&dotted) {
                    c.extend(extra.iter().copied());
                }
                args.iter().for_each(|a| collect(a, &c, tv_under, out));
            }
            // Function types are opaque (see module doc on dyn-fn blind spots).
            _ => {}
        }
    }

    let mut tv_under: BTreeMap<String, BTreeSet<CellKind>> = BTreeMap::new();
    loop {
        let mut changed = false;
        for (qname, field_tys) in graph {
            let mut kinds = BTreeSet::new();
            for t in field_tys {
                collect(t, &BTreeSet::new(), &tv_under, &mut kinds);
            }
            if !kinds.is_empty() {
                let entry = tv_under.entry(qname.clone()).or_default();
                let before = entry.len();
                entry.extend(kinds);
                changed |= entry.len() != before;
            }
        }
        if !changed {
            return tv_under;
        }
    }
}

/// Containment edges `from → (to, kinds crossed)`. One edge per mention; a
/// `Generic` instantiation contributes both an edge to the generic type
/// itself (plain) and edges to its arguments labeled with the kinds the
/// generic stores its payload under (over-approximate: if the payload is
/// stored both plainly and behind a cell, the single edge carries the cell
/// label — labels only ever *add* cycle capability, never remove SCC
/// membership, so this errs toward reporting a type rather than missing it).
fn collect_edges(
    ty: &Ty,
    crossed: &BTreeSet<CellKind>,
    tv_under: &BTreeMap<String, BTreeSet<CellKind>>,
    out: &mut Vec<(String, BTreeSet<CellKind>)>,
) {
    if let Some((k, content)) = cell_content(ty) {
        let mut c = crossed.clone();
        c.insert(k);
        collect_edges(content, &c, tv_under, out);
        return;
    }
    match ty {
        Ty::Option(t) | Ty::List(t) | Ty::Array(t) | Ty::Range(t) => {
            collect_edges(t, crossed, tv_under, out)
        }
        Ty::Tuple(ts) => ts.iter().for_each(|t| collect_edges(t, crossed, tv_under, out)),
        Ty::Generic(name, args) => {
            let dotted = name.replace("::", ".");
            out.push((dotted.clone(), crossed.clone()));
            let mut c = crossed.clone();
            if let Some(extra) = tv_under.get(&dotted) {
                c.extend(extra.iter().copied());
            }
            args.iter().for_each(|a| collect_edges(a, &c, tv_under, out));
        }
        Ty::RustStruct(q) | Ty::RustEnum(q) | Ty::AliasTo(q) | Ty::Enumeration(q) => {
            out.push((q.clone(), crossed.clone()));
        }
        Ty::UnionTypeVariant(q, _) => out.push((q.clone(), crossed.clone())),
        _ => {}
    }
}

/// Names of types lying on a containment cycle that crosses a cell of one of
/// `kinds`: members of Tarjan SCCs containing an internal edge labeled with
/// one of `kinds` (a single node with a matching self-edge counts).
fn cell_cyclic_types(
    graph: &BTreeMap<String, Vec<Ty>>,
    tv_under: &BTreeMap<String, BTreeSet<CellKind>>,
    kinds: &[CellKind],
) -> BTreeSet<String> {
    // Index every graph key and edge target.
    let mut index: BTreeMap<String, usize> = BTreeMap::new();
    let mut names: Vec<String> = Vec::new();
    let intern = |n: &str, index: &mut BTreeMap<String, usize>, names: &mut Vec<String>| {
        *index.entry(n.to_string()).or_insert_with(|| {
            names.push(n.to_string());
            names.len() - 1
        })
    };
    let mut adj: Vec<Vec<(usize, bool)>> = Vec::new(); // (target, crosses one of `kinds`)
    for (qname, field_tys) in graph {
        let from = intern(qname, &mut index, &mut names);
        let mut edges = Vec::new();
        for t in field_tys {
            collect_edges(t, &BTreeSet::new(), tv_under, &mut edges);
        }
        let targets: Vec<(usize, bool)> = edges
            .iter()
            .map(|(to, crossed)| {
                (
                    intern(to, &mut index, &mut names),
                    kinds.iter().any(|k| crossed.contains(k)),
                )
            })
            .collect();
        if adj.len() <= from {
            adj.resize(from + 1, Vec::new());
        }
        adj[from] = targets;
    }
    adj.resize(names.len(), Vec::new());

    // Iterative Tarjan SCC (explicit stack; the graph is shallow but cheap
    // insurance against deep containment chains).
    let n = names.len();
    let mut scc_of = vec![usize::MAX; n];
    let mut low = vec![0usize; n];
    let mut num = vec![usize::MAX; n];
    let mut on_stack = vec![false; n];
    let mut stack: Vec<usize> = Vec::new();
    let mut counter = 0usize;
    let mut scc_count = 0usize;
    for root in 0..n {
        if num[root] != usize::MAX {
            continue;
        }
        // (node, next edge index)
        let mut call: Vec<(usize, usize)> = vec![(root, 0)];
        while let Some(&mut (v, ref mut ei)) = call.last_mut() {
            if *ei == 0 {
                num[v] = counter;
                low[v] = counter;
                counter += 1;
                stack.push(v);
                on_stack[v] = true;
            }
            if let Some(&(w, _)) = adj[v].get(*ei) {
                *ei += 1;
                if num[w] == usize::MAX {
                    call.push((w, 0));
                } else if on_stack[w] {
                    low[v] = low[v].min(num[w]);
                }
            } else {
                if low[v] == num[v] {
                    loop {
                        let w = stack.pop().expect("Tarjan stack underflow");
                        on_stack[w] = false;
                        scc_of[w] = scc_count;
                        if w == v {
                            break;
                        }
                    }
                    scc_count += 1;
                }
                call.pop();
                if let Some(&(parent, _)) = call.last() {
                    low[parent] = low[parent].min(low[v]);
                }
            }
        }
    }

    // SCCs containing an internal cell-crossing edge.
    let mut scc_cyclic = vec![false; scc_count];
    for v in 0..n {
        for &(w, crosses) in &adj[v] {
            if crosses && scc_of[v] == scc_of[w] {
                scc_cyclic[scc_of[v]] = true;
            }
        }
    }
    (0..n)
        .filter(|&v| scc_cyclic[scc_of[v]])
        .map(|v| names[v].clone())
        .collect()
}

// ── main analysis ─────────────────────────────────────────────────────────────

pub fn analyze(hier: &InstanceHierarchy<'_>) -> Report {
    let mut all_fns = Vec::new();
    codegen::collect_all_function_nodes(&hier.top_level, "", &mut all_fns);

    let bodies: Vec<(String, Vec<TypedStmt>)> = all_fns
        .par_iter()
        .map(|(qname, node)| {
            (
                qname.clone(),
                codegen::typedexp_function_body_for_analysis(qname, node, &hier.top_level),
            )
        })
        .collect();

    // Containment graph over all user-defined named types, and the
    // "transitively contains a cell field" fixed points. Computed before site
    // collection because wrapper-call seeding consults the reach-back sets.
    let mut graph: BTreeMap<String, Vec<Ty>> = BTreeMap::new();
    hierarchy::collect_struct_field_tys(&hier.top_level, "", &mut graph);
    let back_mutable = types_containing_cell(&graph, &[CellKind::Mutable]);
    let back_pointer = types_containing_cell(&graph, &[CellKind::Pointer]);
    let back_for = |k: CellKind| match k {
        CellKind::Mutable => &back_mutable,
        CellKind::Pointer => &back_pointer,
    };

    // Fixed point over the updater set: a function whose body passes a cell
    // with a still-generic content type to a known updater is itself an
    // updater (a wrapper like `Pointer.apply`); its own call sites carry the
    // concrete types.
    let mut updaters: BTreeMap<String, BTreeSet<CellKind>> = BTreeMap::new();
    updaters.insert("Mutable.update".into(), BTreeSet::from([CellKind::Mutable]));
    updaters.insert("Pointer.update".into(), BTreeSet::from([CellKind::Pointer]));
    loop {
        let mut changed = false;
        for (qname, stmts) in &bodies {
            let mut found: BTreeSet<CellKind> = BTreeSet::new();
            let mut visit = |func: &str, args: Vec<&TypedExp>| {
                let Some(kinds) = updaters.get(func) else { return };
                for a in &args {
                    if let Some((k, content)) = cell_content(&a.ty())
                        && ty_has_type_var(content)
                    {
                        // The cell's own kind when known; the updater's kinds
                        // when the wrapper is kind-agnostic.
                        found.insert(k);
                        found.extend(kinds.iter().copied());
                    }
                }
            };
            for s in stmts {
                visit_stmt(s, &mut visit);
            }
            if !found.is_empty() {
                let entry = updaters.entry(qname.clone()).or_default();
                let before = entry.len();
                entry.extend(found);
                changed |= entry.len() != before;
            }
        }
        if !changed {
            break;
        }
    }

    // Final pass: collect concrete update sites (and the residual generic
    // ones, for the blind-spot report). Two ways an argument seeds:
    //   * it is a bare cell (`Mutable<T>` / `Pointer<T>`) — content is `T`;
    //   * the callee is a wrapper updater and the argument's type
    //     transitively contains a cell (e.g. `UnorderedSet<T>` passed to
    //     `UnorderedSet.apply`, whose buckets cell is a record field) —
    //     content is the whole argument type.
    let primitives = ["Mutable.update", "Pointer.update"];
    let mut sites: Vec<UpdateSite> = Vec::new();
    let mut unresolved: Vec<(String, String)> = Vec::new();
    for (qname, stmts) in &bodies {
        let mut visit = |func: &str, args: Vec<&TypedExp>| {
            let Some(kinds) = updaters.get(func) else { return };
            for a in &args {
                let a_ty = a.ty();
                if let Some((k, content)) = cell_content(&a_ty) {
                    if ty_has_type_var(content) {
                        // Generic at this level: re-attributed via the
                        // updater fixed point unless `qname` itself never
                        // gets concrete callers — those show up as wrappers
                        // with zero concrete sites, reported below.
                        if !updaters.contains_key(qname) {
                            unresolved.push((qname.clone(), func.to_string()));
                        }
                    } else {
                        sites.push(UpdateSite {
                            function: qname.clone(),
                            callee: func.to_string(),
                            kind: k,
                            content: content.clone(),
                        });
                    }
                } else if !primitives.contains(&func) && !ty_has_type_var(&a_ty) {
                    for &k in kinds.iter() {
                        if ty_contains_cell(&a_ty, &[k], back_for(k)) {
                            sites.push(UpdateSite {
                                function: qname.clone(),
                                callee: func.to_string(),
                                kind: k,
                                content: a_ty.clone(),
                            });
                        }
                    }
                }
            }
        };
        for s in stmts {
            visit_stmt(s, &mut visit);
        }
    }

    let seeds = |pred: &dyn Fn(&UpdateSite) -> bool| -> BTreeSet<String> {
        let mut s = BTreeSet::new();
        for site in sites.iter().filter(|s| pred(s)) {
            collect_named_types(&site.content, &mut s);
        }
        s
    };

    let seeds_mutable = seeds(&|s| s.kind == CellKind::Mutable);
    let seeds_all = seeds(&|_| true);

    let reach_mutable = downward_reach(&graph, &seeds_mutable);
    let reach_all = downward_reach(&graph, &seeds_all);

    // Types on a cell-crossing containment cycle, restricted to those whose
    // cells actually get updated (the downward reach from update contents).
    let tv_under = tv_under_cells(&graph);
    let cyclic_mutable = cell_cyclic_types(&graph, &tv_under, &[CellKind::Mutable]);
    let cyclic_all =
        cell_cyclic_types(&graph, &tv_under, &[CellKind::Mutable, CellKind::Pointer]);

    let known = |set: BTreeSet<String>| -> BTreeSet<String> {
        set.into_iter().filter(|q| graph.contains_key(q)).collect()
    };
    let gc_types_mutable_only: BTreeSet<String> =
        known(reach_mutable.intersection(&cyclic_mutable).cloned().collect());
    let gc_types_full: BTreeSet<String> =
        known(reach_all.intersection(&cyclic_all).cloned().collect());
    let gc_types_with_dyn_fn: BTreeSet<String> = gc_types_full
        .intersection(&hier.types_containing_dyn_fn)
        .cloned()
        .collect();

    let generic_updaters: BTreeMap<String, BTreeSet<CellKind>> = updaters
        .into_iter()
        .filter(|(q, _)| q != "Mutable.update" && q != "Pointer.update")
        .collect();

    Report {
        sites,
        generic_updaters,
        unresolved_generic_sites: unresolved,
        gc_types_mutable_only,
        gc_types_full,
        gc_types_with_dyn_fn,
    }
}

fn top_package(qname: &str) -> &str {
    qname.split('.').next().unwrap_or(qname)
}

pub fn print_report(report: &Report) {
    let by_kind = |kind: CellKind| report.sites.iter().filter(move |s| s.kind == kind);

    for kind in [CellKind::Mutable, CellKind::Pointer] {
        let mut per_content: BTreeMap<String, (usize, BTreeSet<String>)> = BTreeMap::new();
        for site in by_kind(kind) {
            let e = per_content.entry(site.content.to_string()).or_default();
            e.0 += 1;
            e.1.insert(format!("{} → {}", site.function, site.callee));
        }
        println!(
            "── {kind}.update call sites: {} total, {} distinct content types ──",
            by_kind(kind).count(),
            per_content.len()
        );
        for (content, (count, fns)) in &per_content {
            let example = fns.iter().next().map(String::as_str).unwrap_or("?");
            println!("  {count:3}×  {content}    (e.g. in {example})");
        }
        println!();
    }

    if !report.generic_updaters.is_empty() {
        println!("── generic updater wrappers (call sites re-attributed to callers) ──");
        for (qname, kinds) in &report.generic_updaters {
            let kinds: Vec<String> = kinds.iter().map(|k| k.to_string()).collect();
            println!("  {qname}  [{}]", kinds.join(", "));
        }
        println!();
    }
    if !report.unresolved_generic_sites.is_empty() {
        println!("── unresolved generic update sites (potential blind spots) ──");
        for (f, callee) in &report.unresolved_generic_sites {
            println!("  {f} calls {callee} with generic cell content");
        }
        println!();
    }

    let print_set = |title: &str, set: &BTreeSet<String>| {
        println!("── {title}: {} types ──", set.len());
        let mut per_pkg: BTreeMap<&str, Vec<&str>> = BTreeMap::new();
        for q in set {
            per_pkg.entry(top_package(q)).or_default().push(q);
        }
        for (pkg, types) in &per_pkg {
            println!("  {pkg} ({}):", types.len());
            for t in types {
                println!("    {t}");
            }
        }
        println!();
    };

    print_set(
        "Arc→Gc set, Mutable-only scope (reachable from Mutable.update contents ∧ on a Mutable-crossing containment cycle)",
        &report.gc_types_mutable_only,
    );
    print_set(
        "Arc→Gc set, Mutable+Pointer scope",
        &report.gc_types_full,
    );
    print_set(
        "of those, types transitively embedding Arc<dyn Fn> (untraceable edges — Trace-derive problem cases)",
        &report.gc_types_with_dyn_fn,
    );
}
