//! Detect match/matchcontinue case patterns that reference a named `constant`.
//!
//! Optional pass invoked via the `const-patterns` subcommand. In MetaModelica a
//! `case` pattern may refer to a named constant, e.g.
//!
//! ```text
//! constant Integer XXX = 33;
//! ...
//! match i
//!   case XXX then ...;   // matches when i == 33
//! ```
//!
//! Here `XXX` is *not* a binder — it is a value the scrutinee is compared
//! against. Rust gets this wrong by default: a bare lowercase identifier in a
//! pattern binds a fresh variable, and an uppercase one is read as a unit-struct
//! / enum-variant path. The transpiler papers over the common case by folding a
//! constant whose value is a literal into a literal pattern (see
//! `typedexp::const_ref_to_lit_pat`), but a constant whose value is *not* a
//! literal (a function call, a record, an arithmetic expression, …) silently
//! falls through to the constructor / binder path and miscompiles.
//!
//! This pass walks every user-defined function body, finds all match-case
//! patterns, and reports each sub-pattern that resolves to a `constant`
//! declaration — flagging whether the transpiler can currently fold it to a
//! literal (handled) or not (likely miscompiled).
//!
//! Detection mirrors `typedexp::infer_pat`'s precedence so the verdict matches
//! what codegen actually does:
//!   1. `_` / wildcard            → ignored
//!   2. name bound in scope        → a binder, ignored (a local shadows a
//!      same-named constant)
//!   3. name resolves to a constant→ **reported**
//!   4. uppercase name             → a constructor, ignored
//!   5. otherwise                  → a binder, ignored
//!
//! In-scope names are accumulated exactly as inference does: function
//! formals/locals (`node.children`), match-level `localDecls`, case-level
//! `localDecls`, and `for`-loop iterators of any enclosing loop.

use std::collections::{BTreeMap, BTreeSet};
use std::sync::Arc;

use openmodelica_ast::Absyn;

use crate::hierarchy::{extract_default_exp, InstanceHierarchy, NameNode, NodeKind};
use crate::typedexp::{cref_to_dotted, walk_dotted_with_imports};
use crate::MM;

/// One constant-reference pattern found in a match case.
pub struct Finding {
    /// Fully-qualified name of the enclosing function.
    pub function: String,
    pub file: String,
    pub line: i32,
    pub col: i32,
    /// `match` or `matchcontinue`.
    pub match_kind: &'static str,
    /// The name as written in the pattern (e.g. `XXX`, `DAE.derivativeNamePrefix`).
    pub written: String,
    /// The resolved qualified name of the constant declaration.
    pub resolved: String,
    /// Textual representation of the constant's literal value when the
    /// transpiler can fold it (`Some`), or `None` when it cannot — the latter
    /// are the cases most likely to be miscompiled today.
    pub value: Option<String>,
}

pub struct Report {
    pub findings: Vec<Finding>,
    /// Number of function bodies scanned.
    pub functions_scanned: usize,
}

/// Collect `(qname, node)` for every R_FUNCTION class in the hierarchy.
fn collect_functions<'a>(
    nodes: &'a BTreeMap<String, NameNode<'a>>,
    prefix: &str,
    out: &mut Vec<(String, &'a NameNode<'a>)>,
) {
    for (name, node) in nodes {
        let qname = if prefix.is_empty() { name.clone() } else { format!("{prefix}.{name}") };
        if let NodeKind::Class(c) = &node.kind
            && matches!(c.restriction, Absyn::Restriction::R_FUNCTION { .. })
        {
            out.push((qname.clone(), node));
        }
        collect_functions(&node.children, &qname, out);
    }
}

/// Pull the declared component names out of a `localDecls` list.
fn collect_local_names(
    decls: &Arc<metamodelica::List<Arc<Absyn::ElementItem>>>,
    out: &mut BTreeSet<String>,
) {
    for item in (&**decls).into_iter() {
        let Absyn::ElementItem::ELEMENTITEM { element } = item.as_ref() else { continue };
        let Absyn::Element::ELEMENT { specification, .. } = &**element else { continue };
        let Absyn::ElementSpec::COMPONENTS { components, .. } = &**specification else { continue };
        for comp_item in (&**components).into_iter() {
            let Absyn::ComponentItem { component, .. } = comp_item.as_ref();
            out.insert(component.name.to_string());
        }
    }
}

/// Walk `dotted` (and, when unqualified, its enclosing-package qualifications)
/// looking for a `constant` component declaration. Returns the resolved
/// qualified name plus the folded literal value (when the value reduces to a
/// literal). `None` when no constant is found.
fn resolve_const(
    written: &str,
    pkg_prefix: &str,
    top_level: &BTreeMap<String, NameNode<'_>>,
) -> Option<(String, Option<String>)> {
    // Candidate dotted names, in the same precedence inference would use: the
    // name as written first, then qualified with each enclosing package scope.
    let mut candidates: Vec<String> = vec![written.to_owned()];
    if !written.contains('.') {
        let mut parts: Vec<&str> = pkg_prefix.split('.').filter(|s| !s.is_empty()).collect();
        while !parts.is_empty() {
            candidates.push(format!("{}.{written}", parts.join(".")));
            parts.pop();
        }
    }
    for cand in &candidates {
        let Some((qname, node)) = walk_dotted_with_imports(cand, top_level, 0) else { continue };
        let NodeKind::Component(comp) = &node.kind else { continue };
        if comp.variability != Absyn::Variability::CONST { continue; }
        return Some((qname.clone(), fold_const_value(&qname, top_level, 0)));
    }
    None
}

/// Reduce a constant declaration's default expression to a literal string,
/// following chains of `constant X = Y` references. Mirrors the fold in
/// `typedexp::const_ref_to_lit_pat`; returns `None` when the value is not a
/// plain literal.
fn fold_const_value(
    dotted: &str,
    top_level: &BTreeMap<String, NameNode<'_>>,
    depth: u32,
) -> Option<String> {
    if depth > 16 { return None; }
    let (_, node) = walk_dotted_with_imports(dotted, top_level, 0)?;
    let NodeKind::Component(comp) = &node.kind else { return None };
    if comp.variability != Absyn::Variability::CONST { return None; }
    let default = extract_default_exp(&comp.modification)?;
    match default {
        Absyn::Exp::STRING { value } => Some(format!("{value:?}")),
        Absyn::Exp::INTEGER { value } => Some(value.to_string()),
        Absyn::Exp::BOOL { value } => Some(value.to_string()),
        Absyn::Exp::REAL { value } => Some(value.to_string()),
        Absyn::Exp::CREF { componentRef } => {
            fold_const_value(&cref_to_dotted(componentRef), top_level, depth + 1)
        }
        _ => None,
    }
}

struct Scan<'a> {
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    function: String,
    pkg_prefix: String,
    findings: Vec<Finding>,
}

impl<'a> Scan<'a> {
    /// Walk a pattern expression, recording any sub-pattern that resolves to a
    /// constant. `env` is the set of names bound in this case's scope.
    fn walk_pattern(
        &mut self,
        pat: &Absyn::Exp,
        env: &BTreeSet<String>,
        info: &Absyn::Info,
        kind: &'static str,
    ) {
        use Absyn::Exp::*;
        match pat {
            CREF { componentRef } => {
                match componentRef.as_ref() {
                    Absyn::ComponentRef::WILD | Absyn::ComponentRef::ALLWILD => {}
                    _ => {
                        let written = cref_to_dotted(componentRef);
                        let first = written.split('.').next().unwrap_or(&written);
                        // `_` and any name bound in scope are binders, not constants.
                        if first == "_" || env.contains(first) {
                            return;
                        }
                        if let Some((resolved, value)) =
                            resolve_const(&written, &self.pkg_prefix, self.top_level)
                        {
                            self.findings.push(Finding {
                                function: self.function.clone(),
                                file: info.fileName.to_string(),
                                line: info.lineNumberStart,
                                col: info.columnNumberStart,
                                match_kind: kind,
                                written,
                                resolved,
                                value,
                            });
                        }
                    }
                }
            }
            // Constructor / SOME / NONE pattern: positional and named args are
            // themselves patterns.
            CALL { functionArgs, .. } => match &**functionArgs {
                Absyn::FunctionArgs::FUNCTIONARGS { args, argNames } => {
                    for a in &**args {
                        self.walk_pattern(a, env, info, kind);
                    }
                    for na in &**argNames {
                        let Absyn::NamedArg { argValue, .. } = &**na;
                        self.walk_pattern(argValue, env, info, kind);
                    }
                }
                Absyn::FunctionArgs::FOR_ITER_FARG { .. } => {}
            },
            TUPLE { expressions } => {
                for e in &**expressions {
                    self.walk_pattern(e, env, info, kind);
                }
            }
            ARRAY { arrayExp } | LIST { exps: arrayExp } => {
                for e in &**arrayExp {
                    self.walk_pattern(e, env, info, kind);
                }
            }
            CONS { head, rest } => {
                self.walk_pattern(head, env, info, kind);
                self.walk_pattern(rest, env, info, kind);
            }
            AS { exp, .. } => self.walk_pattern(exp, env, info, kind),
            EXPRESSIONCOMMENT { exp, .. } => self.walk_pattern(exp, env, info, kind),
            // Literals (INTEGER/REAL/STRING/BOOL), negative-literal UNARY, etc.
            // never reference a constant.
            _ => {}
        }
    }

    /// Process one `MATCHEXP`: thread the env through its cases and analyse each
    /// pattern; recurse into guards, bodies and results for nested matches.
    fn process_match(
        &mut self,
        match_ty: &Absyn::MatchType,
        match_locals: &Arc<metamodelica::List<Arc<Absyn::ElementItem>>>,
        input_exp: &Absyn::Exp,
        cases: &Arc<metamodelica::List<Arc<Absyn::Case>>>,
        env: &BTreeSet<String>,
    ) {
        let kind = match match_ty {
            Absyn::MatchType::MATCH => "match",
            Absyn::MatchType::MATCHCONTINUE => "matchcontinue",
        };

        // The scrutinee is evaluated in the enclosing scope.
        self.walk_exp(input_exp, env);

        let mut match_env = env.clone();
        collect_local_names(match_locals, &mut match_env);

        for case in (&**cases).into_iter() {
            match case.as_ref() {
                Absyn::Case::CASE {
                    pattern,
                    patternGuard,
                    patternInfo,
                    localDecls,
                    classPart,
                    result,
                    ..
                } => {
                    let mut case_env = match_env.clone();
                    collect_local_names(localDecls, &mut case_env);
                    self.walk_pattern(pattern, &case_env, patternInfo, kind);
                    if let Some(g) = patternGuard.as_deref() {
                        self.walk_exp(g, &case_env);
                    }
                    self.walk_class_part(classPart, &case_env);
                    self.walk_exp(result, &case_env);
                }
                Absyn::Case::ELSE { localDecls, classPart, result, .. } => {
                    let mut case_env = match_env.clone();
                    collect_local_names(localDecls, &mut case_env);
                    self.walk_class_part(classPart, &case_env);
                    self.walk_exp(result, &case_env);
                }
            }
        }
    }

    fn walk_class_part(&mut self, part: &Absyn::ClassPart, env: &BTreeSet<String>) {
        if let Absyn::ClassPart::ALGORITHMS { contents } = part {
            for it in &**contents {
                self.walk_algorithm_item(it, env);
            }
        }
    }

    fn walk_algorithm_item(&mut self, it: &Absyn::AlgorithmItem, env: &BTreeSet<String>) {
        let alg = match it {
            Absyn::AlgorithmItem::ALGORITHMITEM { algorithm_, .. } => &**algorithm_,
            Absyn::AlgorithmItem::ALGORITHMITEMCOMMENT { .. } => return,
        };
        match alg {
            Absyn::Algorithm::ALG_ASSIGN { assignComponent, value } => {
                self.walk_exp(assignComponent, env);
                self.walk_exp(value, env);
            }
            Absyn::Algorithm::ALG_IF { ifExp, trueBranch, elseIfAlgorithmBranch, elseBranch } => {
                self.walk_exp(ifExp, env);
                for it in &**trueBranch { self.walk_algorithm_item(it, env); }
                for (cond, branch) in &**elseIfAlgorithmBranch {
                    self.walk_exp(cond, env);
                    for it in &**branch { self.walk_algorithm_item(it, env); }
                }
                for it in &**elseBranch { self.walk_algorithm_item(it, env); }
            }
            Absyn::Algorithm::ALG_FOR { iterators, forBody }
            | Absyn::Algorithm::ALG_PARFOR { iterators, parforBody: forBody } => {
                // A loop iterator binds a fresh name visible in the body, so any
                // nested-match pattern referencing it is a binder, not a constant.
                let mut body_env = env.clone();
                for it in &**iterators {
                    let Absyn::ForIterator { name, range, guardExp, .. } = &**it;
                    body_env.insert(name.to_string());
                    if let Some(r) = range.as_deref() { self.walk_exp(r, env); }
                    if let Some(g) = guardExp.as_deref() { self.walk_exp(g, env); }
                }
                for it in &**forBody { self.walk_algorithm_item(it, &body_env); }
            }
            Absyn::Algorithm::ALG_WHILE { boolExpr, whileBody } => {
                self.walk_exp(boolExpr, env);
                for it in &**whileBody { self.walk_algorithm_item(it, env); }
            }
            Absyn::Algorithm::ALG_WHEN_A { boolExpr, whenBody, elseWhenAlgorithmBranch } => {
                self.walk_exp(boolExpr, env);
                for it in &**whenBody { self.walk_algorithm_item(it, env); }
                for (e, branch) in &**elseWhenAlgorithmBranch {
                    self.walk_exp(e, env);
                    for it in &**branch { self.walk_algorithm_item(it, env); }
                }
            }
            Absyn::Algorithm::ALG_NORETCALL { functionArgs, .. } => {
                self.walk_function_args(functionArgs, env);
            }
            Absyn::Algorithm::ALG_FAILURE { equ } => {
                for it in &**equ { self.walk_algorithm_item(it, env); }
            }
            Absyn::Algorithm::ALG_TRY { body, elseBody } => {
                for it in &**body { self.walk_algorithm_item(it, env); }
                for it in &**elseBody { self.walk_algorithm_item(it, env); }
            }
            Absyn::Algorithm::ALG_RETURN
            | Absyn::Algorithm::ALG_BREAK
            | Absyn::Algorithm::ALG_CONTINUE => {}
        }
    }

    fn walk_exp(&mut self, e: &Absyn::Exp, env: &BTreeSet<String>) {
        use Absyn::Exp::*;
        match e {
            INTEGER { .. } | REAL { .. } | STRING { .. } | BOOL { .. } | END | BREAK => {}
            CODE { .. } => {}
            CREF { .. } => {}
            BINARY { exp1, exp2, .. } | LBINARY { exp1, exp2, .. } | RELATION { exp1, exp2, .. } => {
                self.walk_exp(exp1, env);
                self.walk_exp(exp2, env);
            }
            UNARY { exp, .. } | LUNARY { exp, .. } => self.walk_exp(exp, env),
            IFEXP { ifExp, trueBranch, elseBranch, elseIfBranch } => {
                self.walk_exp(ifExp, env);
                self.walk_exp(trueBranch, env);
                self.walk_exp(elseBranch, env);
                for (c, t) in &**elseIfBranch {
                    self.walk_exp(c, env);
                    self.walk_exp(t, env);
                }
            }
            CALL { functionArgs, .. } | PARTEVALFUNCTION { functionArgs, .. } => {
                self.walk_function_args(functionArgs, env);
            }
            ARRAY { arrayExp } | LIST { exps: arrayExp } => {
                for e in &**arrayExp { self.walk_exp(e, env); }
            }
            MATRIX { matrix } => {
                for row in &**matrix {
                    for e in &**row { self.walk_exp(e, env); }
                }
            }
            RANGE { start, step, stop } => {
                self.walk_exp(start, env);
                if let Some(s) = step.as_deref() { self.walk_exp(s, env); }
                self.walk_exp(stop, env);
            }
            TUPLE { expressions } => {
                for e in &**expressions { self.walk_exp(e, env); }
            }
            AS { exp, .. } => self.walk_exp(exp, env),
            CONS { head, rest } => {
                self.walk_exp(head, env);
                self.walk_exp(rest, env);
            }
            MATCHEXP { matchTy, inputExp, localDecls, cases, .. } => {
                self.process_match(matchTy, localDecls, inputExp, cases, env);
            }
            DOT { exp, index } => {
                self.walk_exp(exp, env);
                self.walk_exp(index, env);
            }
            EXPRESSIONCOMMENT { exp, .. } => self.walk_exp(exp, env),
            SUBSCRIPTED_EXP { exp, .. } => self.walk_exp(exp, env),
        }
    }

    fn walk_function_args(&mut self, fa: &Absyn::FunctionArgs, env: &BTreeSet<String>) {
        match fa {
            Absyn::FunctionArgs::FUNCTIONARGS { args, argNames } => {
                for e in &**args { self.walk_exp(e, env); }
                for na in &**argNames {
                    let Absyn::NamedArg { argValue, .. } = &**na;
                    self.walk_exp(argValue, env);
                }
            }
            Absyn::FunctionArgs::FOR_ITER_FARG { exp, iterators, .. } => {
                self.walk_exp(exp, env);
                for it in &**iterators {
                    let Absyn::ForIterator { range, guardExp, .. } = &**it;
                    if let Some(r) = range.as_deref() { self.walk_exp(r, env); }
                    if let Some(g) = guardExp.as_deref() { self.walk_exp(g, env); }
                }
            }
        }
    }
}

pub fn analyze(hier: &InstanceHierarchy<'_>) -> Report {
    let mut functions: Vec<(String, &NameNode<'_>)> = Vec::new();
    collect_functions(&hier.top_level, "", &mut functions);

    let functions_scanned = functions.len();
    let mut findings: Vec<Finding> = Vec::new();

    for (qname, node) in &functions {
        let NodeKind::Class(c) = &node.kind else { continue };
        let algorithms = match &c.body {
            MM::ClassDef::Parts { algorithms, .. } | MM::ClassDef::ClassExtends { algorithms, .. } => algorithms,
            _ => continue,
        };

        // Base env: the function's formals and locals (same source inference
        // uses — see `typedexp_function_body_for_analysis`).
        let env: BTreeSet<String> = node.children.keys().cloned().collect();
        let pkg_prefix = qname.rsplit_once('.').map_or("", |(p, _)| p).to_owned();

        let mut scan = Scan {
            top_level: &hier.top_level,
            function: qname.clone(),
            pkg_prefix,
            findings: Vec::new(),
        };
        for it in algorithms.iter() {
            scan.walk_algorithm_item(it, &env);
        }
        findings.append(&mut scan.findings);
    }

    findings.sort_by(|a, b| {
        a.function
            .cmp(&b.function)
            .then(a.file.cmp(&b.file))
            .then(a.line.cmp(&b.line))
            .then(a.written.cmp(&b.written))
    });

    Report { findings, functions_scanned }
}

pub fn print_report(report: &Report) {
    let foldable = report.findings.iter().filter(|f| f.value.is_some()).count();
    let unfoldable = report.findings.len() - foldable;

    println!("═══════════════════════════════════════════════════════════");
    println!("  Constant-reference match patterns");
    println!("═══════════════════════════════════════════════════════════");
    println!();
    println!("  Functions scanned:       {}", report.functions_scanned);
    println!("  Constant-ref patterns:   {}", report.findings.len());
    println!("    · foldable to literal: {foldable}  (handled by codegen today)");
    println!("    · NOT foldable:        {unfoldable}  (likely miscompiled — needs attention)");
    println!();

    if report.findings.is_empty() {
        return;
    }

    // The not-foldable findings are the actionable ones, so lead with them.
    let mut groups: [(&str, Vec<&Finding>); 2] = [
        ("NOT foldable to a literal (constructor/binder path — likely wrong)", Vec::new()),
        ("foldable to a literal (lowered to a value-equality match)", Vec::new()),
    ];
    for f in &report.findings {
        if f.value.is_some() { groups[1].1.push(f); } else { groups[0].1.push(f); }
    }

    for (heading, items) in &groups {
        if items.is_empty() { continue; }
        println!("── {heading} ──");
        for f in items {
            let value = match &f.value {
                Some(v) => format!(" = {v}"),
                None => String::new(),
            };
            let resolved = if f.resolved == f.written {
                String::new()
            } else {
                format!(" (→ {})", f.resolved)
            };
            println!(
                "  {}:{}:{}  [{}]  {} in {}{resolved}{value}",
                f.file, f.line, f.col, f.match_kind, f.written, f.function,
            );
        }
        println!();
    }
}
