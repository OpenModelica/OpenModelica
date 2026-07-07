//! Reachability analysis from `Main.main`.
//!
//! Optional pass invoked via the `unused-functions` subcommand. Walks every
//! user-defined MetaModelica function class, collects the union of names it
//! references (direct calls, partial applications, and bare `CREF` uses that
//! resolve to an R_FUNCTION node — the function-pointer case used by
//! higher-order helpers like `List.map`), then performs a forward reachability
//! search from `Main.main` and reports every function that the search did not
//! reach.
//!
//! Limitations:
//!   * Approximate — a function referenced only through a name constructed at
//!     runtime (string-based reflection, code templates) will appear unused.
//!     There is no such mechanism in the current Compiler/, but unresolved
//!     names are reported in the summary so users can audit.
//!   * Builtins / externals are ignored — only user-defined functions
//!     participate in the call graph.
//!   * `function Foo = Bar(...)` aliases keep the base reachable: visiting
//!     the alias enqueues its base.
//!   * Functions referenced from non-function contexts (e.g. as values inside
//!     constant initializers in a `package` body) are NOT walked — only
//!     function bodies are scanned. If this matters in the future, expand the
//!     walker to cover component default expressions.

use std::collections::{BTreeMap, BTreeSet, VecDeque};

use openmodelica_ast::Absyn;

use crate::hierarchy::{InstanceHierarchy, NameNode, NodeKind, Ty};
use crate::typedexp::{cref_to_dotted, resolve_call_node};
use crate::MM;

const ROOT: &str = "Main.main";

/// Collect every R_FUNCTION node together with its FQN, the resolved alias
/// base (if `function Foo = Bar(...)`), and the base function pointer when the
/// node is a `redeclare function extends X` form (carried on
/// `NameNode.base_fn`).
fn collect_functions<'a>(
    nodes: &BTreeMap<String, NameNode<'a>>,
    prefix: &str,
    out: &mut Vec<(String, &'a MM::Class, Option<&'a MM::Class>, Option<String>)>,
) {
    for (name, node) in nodes {
        let qname = if prefix.is_empty() { name.clone() } else { format!("{prefix}.{name}") };
        if let NodeKind::Class(c) = &node.kind
            && matches!(c.restriction, Absyn::Restriction::R_FUNCTION { .. })
        {
            let alias_base = match &node.ty {
                Ty::FunctionAlias { base, .. } => Some(base.clone()),
                _ => None,
            };
            out.push((qname.clone(), *c, node.base_fn, alias_base));
        }
        collect_functions(&node.children, &qname, out);
    }
}

#[derive(Default)]
pub(crate) struct RefScan {
    /// Raw dotted names that appear as callees (CALL / ALG_NORETCALL /
    /// PARTEVALFUNCTION callees) and as standalone CREF expressions that
    /// might denote a function value.
    pub(crate) refs: BTreeSet<String>,
}

impl RefScan {
    pub(crate) fn scan_class(c: &MM::Class) -> Self {
        let mut s = RefScan::default();
        let (algorithms, members) = match &c.body {
            MM::ClassDef::Parts { algorithms, members, .. } => (algorithms, members),
            MM::ClassDef::ClassExtends { algorithms, members, .. } => (algorithms, members),
            _ => return s,
        };
        // Walk component default expressions (e.g. `String x = getCachePath();`)
        // — these expressions execute at function entry just like algorithm
        // statements, so calls inside them must contribute to the call graph.
        for member in members {
            let MM::ClassMember::Component(cm) = member else { continue };
            let Some(modif) = cm.modification.as_ref() else { continue };
            let Absyn::Modification { eqMod, .. } = &**modif;
            if let Absyn::EqMod::EQMOD { exp, .. } = &**eqMod {
                s.scan_exp(exp);
            }
        }
        for it in algorithms {
            s.scan_algorithm_item(it);
        }
        s
    }

    fn scan_algorithm_item(&mut self, it: &Absyn::AlgorithmItem) {
        let alg = match it {
            Absyn::AlgorithmItem::ALGORITHMITEM { algorithm_, .. } => &**algorithm_,
            Absyn::AlgorithmItem::ALGORITHMITEMCOMMENT { .. } => return,
        };
        match alg {
            Absyn::Algorithm::ALG_ASSIGN { assignComponent, value } => {
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
                self.refs.insert(cref_to_dotted(functionCall));
                self.scan_function_args(functionArgs);
            }
            Absyn::Algorithm::ALG_FAILURE { equ } => {
                for it in &**equ { self.scan_algorithm_item(it); }
            }
            Absyn::Algorithm::ALG_TRY { body, elseBody } => {
                for it in &**body { self.scan_algorithm_item(it); }
                for it in &**elseBody { self.scan_algorithm_item(it); }
            }
            Absyn::Algorithm::ALG_RETURN
            | Absyn::Algorithm::ALG_BREAK
            | Absyn::Algorithm::ALG_CONTINUE => {}
        }
    }

    pub(crate) fn scan_exp(&mut self, e: &Absyn::Exp) {
        use Absyn::Exp::*;
        match e {
            INTEGER { .. } | REAL { .. } | STRING { .. } | BOOL { .. } | END | BREAK => {}
            CODE { .. } => {}
            // A bare CREF in expression position may denote a function value
            // (e.g. `List.map(stringGet, xs)`). Record the dotted name; the
            // resolver later filters out anything that does not actually point
            // at a function class.
            CREF { componentRef } => {
                self.refs.insert(cref_to_dotted(componentRef));
            }
            BINARY { exp1, exp2, .. } | LBINARY { exp1, exp2, .. } | RELATION { exp1, exp2, .. } => {
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
                self.refs.insert(cref_to_dotted(function_));
                self.scan_function_args(functionArgs);
            }
            PARTEVALFUNCTION { function_, functionArgs } => {
                self.refs.insert(cref_to_dotted(function_));
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
            MATCHEXP { inputExp, cases, .. } => {
                self.scan_exp(inputExp);
                for case in &**cases {
                    match &**case {
                        Absyn::Case::CASE { pattern, patternGuard, classPart, result, .. } => {
                            self.scan_exp(pattern);
                            if let Some(g) = patternGuard.as_deref() { self.scan_exp(g); }
                            self.scan_class_part(classPart);
                            self.scan_exp(result);
                        }
                        Absyn::Case::ELSE { classPart, result, .. } => {
                            self.scan_class_part(classPart);
                            self.scan_exp(result);
                        }
                    }
                }
            }
            DOT { exp, index } => { self.scan_exp(exp); self.scan_exp(index); }
            EXPRESSIONCOMMENT { exp, .. } => self.scan_exp(exp),
            SUBSCRIPTED_EXP { exp, .. } => self.scan_exp(exp),
        }
    }

    fn scan_class_part(&mut self, part: &Absyn::ClassPart) {
        if let Absyn::ClassPart::ALGORITHMS { contents } = part {
            for it in &**contents { self.scan_algorithm_item(it); }
        }
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
}

/// Hold the scan + resolved edges together so the caller can pass them around.
pub struct UnusedReport {
    pub total_functions: usize,
    pub reachable: BTreeSet<String>,
    pub unreachable: BTreeSet<String>,
    /// Raw names that did not resolve to any function class. Aggregated to
    /// help spot reflective lookups that the static analysis cannot follow.
    pub unresolved_sample: Vec<String>,
}

pub fn analyze(hier: &InstanceHierarchy<'_>) -> UnusedReport {
    let mut functions: Vec<(String, &MM::Class, Option<&MM::Class>, Option<String>)> = Vec::new();
    collect_functions(&hier.top_level, "", &mut functions);

    // Union-find on `&MM::Class` pointer values. Two FQNs are unified when:
    //  1. They share the same `MM::Class` pointer (extends-flattening copies
    //     base function nodes into every derived class, keeping the same
    //     `&MM::Class`).
    //  2. One declaration is `redeclare function extends X` — the derived
    //     concrete impl carries `base_fn: Some(&X)` so the override-vs-base
    //     pair lives in the same logical "function slot" of the abstract
    //     package.  Without this link, a derived `keyStr` would be reported
    //     unused even though the base's `add` invokes `keyStr` at runtime.
    let ptr_of = |c: &MM::Class| -> usize { (c as *const MM::Class) as usize };
    let mut uf: BTreeMap<usize, usize> = BTreeMap::new();
    fn uf_find(uf: &mut BTreeMap<usize, usize>, x: usize) -> usize {
        let p = *uf.entry(x).or_insert(x);
        if p == x { return x; }
        let r = uf_find(uf, p);
        uf.insert(x, r);
        r
    }
    fn uf_union(uf: &mut BTreeMap<usize, usize>, a: usize, b: usize) {
        let ra = uf_find(uf, a);
        let rb = uf_find(uf, b);
        if ra != rb { uf.insert(ra, rb); }
    }
    for (_, class, base_fn, _) in &functions {
        uf_find(&mut uf, ptr_of(class));
        if let Some(bf) = base_fn { uf_union(&mut uf, ptr_of(class), ptr_of(bf)); }
    }

    // Group every (FQN, &MM::Class, alias_base) by its union-find root.
    let mut by_root: BTreeMap<usize, Vec<(String, &MM::Class, Option<String>)>> = BTreeMap::new();
    for (qname, class, _, alias_base) in &functions {
        let r = uf_find(&mut uf, ptr_of(class));
        by_root.entry(r).or_default().push((qname.clone(), *class, alias_base.clone()));
    }

    // Pick a canonical FQN per group.  Preference: the FQN whose top-level
    // package name matches the basename of one of the group members'
    // `info.fileName` (the abstract base's own source file).  Falls back to
    // the lexicographically smallest FQN otherwise.
    let mut canonical_of: BTreeMap<String, String> = BTreeMap::new();
    // For each canonical root: the full list of (FQN, class) members so
    // every body is scanned (a `redeclare function extends` body is a
    // separate `MM::Class` from the base — without this we'd miss the
    // override's calls).
    let mut groups: BTreeMap<String, Vec<(String, &MM::Class, Option<String>)>> = BTreeMap::new();
    for group in by_root.values() {
        // Stems of every class in the group — `redeclare function extends`
        // and the abstract base usually live in different files; the
        // abstract base's stem matches its declaring package, so look there
        // first.
        let stems: BTreeSet<String> = group.iter()
            .filter_map(|(_, c, _)| std::path::Path::new(c.info.fileName.as_str())
                .file_stem().and_then(|s| s.to_str()).map(|s| s.to_owned()))
            .collect();
        let canonical = group.iter()
            .map(|(q, _, _)| q.as_str())
            .find(|q| stems.iter().any(|s| q.split('.').next() == Some(s.as_str())))
            .map(|q| q.to_owned())
            .unwrap_or_else(|| {
                group.iter().map(|(q, _, _)| q.clone()).min().expect("non-empty group")
            });
        for (q, _, _) in group {
            canonical_of.insert(q.clone(), canonical.clone());
        }
        groups.insert(canonical.clone(), group.clone());
    }

    let canonical_set: BTreeSet<String> = groups.keys().cloned().collect();

    // Per-group reference scan.  We scan *every* MM::Class in the group so
    // that calls inside a `redeclare function extends` override contribute
    // to reachability — its body is a different `MM::Class` from the
    // abstract base and would otherwise be invisible.
    let mut refs: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
    let mut alias_bases: BTreeMap<String, String> = BTreeMap::new();
    // Per-group: scope FQNs (one per member) so we resolve raw names in
    // each member's own enclosing-package context.
    let mut group_scopes: BTreeMap<String, Vec<String>> = BTreeMap::new();
    let mut seen_class_ptrs: BTreeMap<String, BTreeSet<usize>> = BTreeMap::new();
    for (canonical, members) in &groups {
        let mut all_refs: BTreeSet<String> = BTreeSet::new();
        let mut scopes: Vec<String> = Vec::new();
        let mut seen: BTreeSet<usize> = BTreeSet::new();
        for (qname, class, alias_base) in members {
            // De-dup bodies by class pointer (a base class appearing under
            // many FQNs through `flatten_extends` should be scanned once).
            if seen.insert(ptr_of(class)) {
                let s = RefScan::scan_class(class);
                all_refs.extend(s.refs);
                scopes.push(qname.clone());
            }
            if let Some(base) = alias_base {
                alias_bases.entry(canonical.clone()).or_insert_with(|| base.clone());
            }
        }
        refs.insert(canonical.clone(), all_refs);
        group_scopes.insert(canonical.clone(), scopes);
        seen_class_ptrs.insert(canonical.clone(), seen);
    }

    // Resolve raw names → canonical FQN edges.  We try each member's own
    // scope until one succeeds — a name inside a `redeclare extends`
    // override resolves from its containing package, not the abstract base.
    let mut edges: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
    let mut unresolved: BTreeSet<String> = BTreeSet::new();
    let resolve_to_canonical = |raw: &str, scopes: &[String]| -> Option<String> {
        for scope in scopes {
            if let Some((qname, node)) = resolve_call_node(raw, &hier.top_level, scope) {
                let NodeKind::Class(c) = &node.kind else { continue };
                if !matches!(c.restriction, Absyn::Restriction::R_FUNCTION { .. }) { continue; }
                if let Some(c) = canonical_of.get(&qname) { return Some(c.clone()); }
            }
        }
        None
    };
    for (qname, raw_refs) in &refs {
        let scopes = group_scopes.get(qname).cloned().unwrap_or_else(|| vec![qname.clone()]);
        let mut set: BTreeSet<String> = BTreeSet::new();
        for raw in raw_refs {
            if raw == "_" || raw == "__" || raw.is_empty() { continue; }
            match resolve_to_canonical(raw, &scopes) {
                Some(target) => { set.insert(target); }
                None => {
                    if unresolved.len() < 64 {
                        unresolved.insert(raw.clone());
                    }
                }
            }
        }
        if let Some(base) = alias_bases.get(qname)
            && let Some(target) = resolve_to_canonical(base, &scopes) {
                set.insert(target);
            }
        edges.insert(qname.clone(), set);
    }
    let _ = seen_class_ptrs;

    // BFS from Main.main.
    let root_canonical = canonical_of.get(ROOT).cloned().unwrap_or_else(|| ROOT.to_owned());
    let mut reachable: BTreeSet<String> = BTreeSet::new();
    let mut queue: VecDeque<String> = VecDeque::new();
    if canonical_set.contains(&root_canonical) {
        reachable.insert(root_canonical.clone());
        queue.push_back(root_canonical);
    }
    while let Some(cur) = queue.pop_front() {
        if let Some(targets) = edges.get(&cur) {
            for t in targets {
                if reachable.insert(t.clone()) {
                    queue.push_back(t.clone());
                }
            }
        }
    }

    // Externally-exposed APIs and Modelica builtins are not callable from
    // `Main.main`; they are entry points for *outside* the compiler. Filter
    // them out of the report so they don't drown the genuinely-dead code:
    //   * Top-level (single-segment) FQNs — Modelica builtins declared at
    //     file top level in `*Builtin.mo` (e.g. `sin`, `der`,
    //     `dumpWhenOperators`).
    //   * `OpenModelica.*` — the builtin `OpenModelica` package.
    //   * `OpenModelicaScriptingAPI.*` — the C-callable scripting API used
    //     when OMC is loaded as a library.
    let is_external_api = |q: &str| -> bool {
        if !q.contains('.') { return true; }
        let top = q.split('.').next().unwrap_or(q);
        matches!(top, "OpenModelica" | "OpenModelicaScriptingAPI")
    };
    // `partial function` declarations are abstract — they have a signature
    // but no body, and exist solely as a function *type* (e.g. used as a
    // field type or generic parameter). A group is "type-only" if every
    // member is partial, in which case nothing in it is callable code, so
    // we exclude it from the report. Groups with at least one concrete
    // member (e.g. a `redeclare function extends X` override) stay.
    let is_type_only_group = |canonical: &str| -> bool {
        groups.get(canonical)
            .map(|members| members.iter().all(|(_, c, _)| c.partial_prefix))
            .unwrap_or(false)
    };
    let unreachable: BTreeSet<String> = canonical_set.iter()
        .filter(|q| !reachable.contains(q.as_str())
            && !is_external_api(q)
            && !is_type_only_group(q))
        .cloned()
        .collect();

    UnusedReport {
        total_functions: canonical_set.len(),
        reachable,
        unreachable,
        unresolved_sample: unresolved.into_iter().collect(),
    }
}

pub fn print_report(report: &UnusedReport) {
    println!("═══════════════════════════════════════════════════════════");
    println!("  Unused-function analysis (reachability from {ROOT})");
    println!("═══════════════════════════════════════════════════════════");
    println!();
    println!(
        "  Functions total:      {}",
        report.total_functions
    );
    println!("  Reachable from root:  {}", report.reachable.len());
    println!("  Unreachable:          {}", report.unreachable.len());
    println!();

    if !report.reachable.contains(ROOT) {
        println!(
            "  WARNING: root `{ROOT}` was not found in the hierarchy — no reachability \
             could be computed."
        );
        println!();
    }

    // Group unreachable by top-level package so the output stays scannable on
    // a large codebase.
    let mut by_pkg: BTreeMap<&str, Vec<&str>> = BTreeMap::new();
    for q in &report.unreachable {
        let pkg = q.split('.').next().unwrap_or(q.as_str());
        by_pkg.entry(pkg).or_default().push(q.as_str());
    }

    if !report.unresolved_sample.is_empty() {
        println!(
            "── Unresolved names (sample of up to 64 — not function classes, likely builtins/locals) ─"
        );
        for n in &report.unresolved_sample {
            println!("    · {n}");
        }
        println!();
    }

    println!("── Unreachable functions, grouped by top-level package ─────");
    for (pkg, fns) in &by_pkg {
        println!("  {pkg}  ({} functions)", fns.len());
        for f in fns {
            println!("    · {f}");
        }
    }
    println!();
}
