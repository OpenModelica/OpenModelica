//! Chooses the input parameters that are emitted as `&T` instead of `T`.
//!
//! A parameter qualifies when its type is a heap handle (`Ref<T>`, `List<T>`,
//! `ArcStr`) or a non-`Copy` record, it is never written or shadowed, and every
//! read borrows it: a field access, a match or pattern-let subject, a borrowing
//! builtin, or an argument to a callee parameter that itself qualifies (solved
//! as a greatest fixpoint). In a loop-lowered (tail-recursive) function the
//! self-calls must also pass it through unchanged. Callers then pass `&x`
//! instead of cloning the value into the call.

use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet};

use crate::hierarchy::{NameNode, NodeKind, Ty};
use crate::typedexp::{self, BinOpKind, TypedExp, TypedPat, TypedStmt};
use crate::MM;
use rayon::prelude::*;
use openmodelica_ast::Absyn;

pub(crate) type BorrowMasks = BTreeMap<String, Vec<bool>>;

static MASKS: std::sync::OnceLock<BorrowMasks> = std::sync::OnceLock::new();

pub(crate) fn install(masks: BorrowMasks) {
    let _ = MASKS.set(masks);
}

/// The borrow mask of the function `qname`, if any of its parameters is borrowed.
pub(crate) fn mask(qname: &str) -> Option<&'static [bool]> {
    MASKS.get()?.get(qname).map(|v| v.as_slice())
}

#[derive(Clone, Copy, PartialEq)]
enum Kind {
    /// `Ref<T>`, `List<T>`, `ArcStr`.
    Handle,
    /// A record or uniontype stored by value.
    Value,
}

pub(crate) struct Types<'t> {
    pub recursive: &'t BTreeSet<String>,
    pub copy: &'t HashSet<String>,
}

fn candidate_kind(ty: &Ty, types: &Types<'_>) -> Option<Kind> {
    match ty {
        Ty::List(_) | Ty::Str => Some(Kind::Handle),
        Ty::RustStruct(n) | Ty::RustEnum(n) | Ty::AliasTo(n) if types.recursive.contains(n) => Some(Kind::Handle),
        Ty::RustStruct(n) | Ty::RustEnum(n) | Ty::AliasTo(n) if !types.copy.contains(n) => Some(Kind::Value),
        Ty::UnionTypeVariant(parent, _) if types.recursive.contains(parent) => Some(Kind::Handle),
        _ => None,
    }
}

/// Builtins lowered with the argument read in place (see `emit_place_arg`).
fn builtin_borrows(func: &str, idx: usize) -> bool {
    match func {
        "referenceEq" | "stringEq" | "stringEqual" | "stringCompare" => idx < 2,
        "stringEmpty" | "stringHash" | "stringHashDjb2" | "stringHashDjb2Continue"
        | "stringHashDjb2Mod" | "stringHashSdbm" | "stringGet" | "listLength"
        | "stringLength" | "listHead" | "listRest" | "listGet" | "listEmpty"
        | "valueConstructor" => idx == 0,
        _ => false,
    }
}

/// A pattern-let target that only reads its subject.
pub(crate) fn pat_destructures(p: &TypedPat) -> bool {
    matches!(p, TypedPat::Constructor { .. } | TypedPat::Cons { .. } | TypedPat::Some_(_) | TypedPat::None_
        | TypedPat::EmptyList | TypedPat::As { .. })
}

#[derive(Clone)]
enum Pos {
    Owned,
    Borrow,
    Arg(String, usize),
}

struct Scan<'a, 'b> {
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    /// Set for a loop-lowered function (short name, inputs): its tail
    /// self-calls reassign the parameters, so a borrowed one must be passed
    /// through unchanged.
    self_call: Option<(&'b str, &'b [String])>,
    pkg_prefix: &'b str,
    candidates: &'b HashSet<String>,
    values: &'b HashSet<String>,
    locals: &'b HashSet<String>,
    disq: HashSet<String>,
    deps: Vec<(String, String, usize)>,
    /// `MMTORUST_TRACE_BORROW=<qname suffix>` reports why a parameter is by value.
    trace: Option<&'b str>,
    /// The expression enclosing the current read, for the trace.
    parent: String,
}

fn is_plain(name: &str, segments: &[typedexp::CrefSegment]) -> bool {
    segments.len() <= 1 && !name.contains('.') && segments.iter().all(|s| s.subscripts.is_empty())
}

impl Scan<'_, '_> {
    fn disqualify(&mut self, name: &str, why: &dyn std::fmt::Debug) {
        if self.candidates.contains(name) && self.disq.insert(name.to_owned())
            && let Some(q) = self.trace
        {
            eprintln!("[borrow] {q}: `{name}` by value: {why:?}");
        }
    }

    fn bind(&mut self, name: &str) {
        self.disqualify(name, &"written or shadowed");
    }

    fn pat(&mut self, p: &TypedPat) {
        match p {
            TypedPat::Var(n) => self.bind(n),
            TypedPat::As { var, pat } => {
                self.bind(var);
                self.pat(pat);
            }
            TypedPat::Some_(inner) => self.pat(inner),
            TypedPat::Cons { head, tail } => {
                self.pat(head);
                self.pat(tail);
            }
            TypedPat::Tuple(ps) => ps.iter().for_each(|p| self.pat(p)),
            TypedPat::Constructor { fields, named_fields, .. } => {
                fields.iter().for_each(|p| self.pat(p));
                named_fields.iter().for_each(|(_, p)| self.pat(p));
            }
            TypedPat::Index { base, index } => {
                if let TypedExp::Var { name, segments, .. } = base {
                    self.bind(&crate::codegen::var_base_name(name, segments));
                }
                self.exp(base, Pos::Owned);
                self.exp(index, Pos::Owned);
            }
            TypedPat::FieldAccess { base, .. } => self.pat(base),
            TypedPat::Wildcard | TypedPat::Lit(_) | TypedPat::EmptyList | TypedPat::None_ | TypedPat::Todo(_) => {}
        }
    }

    fn stmts(&mut self, stmts: &[TypedStmt]) {
        stmts.iter().for_each(|s| self.stmt(s));
    }

    fn stmt(&mut self, s: &TypedStmt) {
        match s {
            TypedStmt::Assign { lhs, rhs, .. } => {
                self.pat(lhs);
                let value = matches!(rhs, TypedExp::Var { name, .. } if self.values.contains(name));
                let p = if pat_destructures(lhs) && !value { Pos::Borrow } else { Pos::Owned };
                self.arg(rhs, p);
            }
            TypedStmt::NoRetCall { call, .. } => self.exp(call, Pos::Owned),
            TypedStmt::If { cond, then_, elseif, else_ } => {
                self.exp(cond, Pos::Owned);
                self.stmts(then_);
                for (c, b) in elseif {
                    self.exp(c, Pos::Owned);
                    self.stmts(b);
                }
                self.stmts(else_);
            }
            TypedStmt::For { var, range, body } => {
                self.bind(var);
                self.exp(range, Pos::Owned);
                self.stmts(body);
            }
            TypedStmt::While { cond, body } => {
                self.exp(cond, Pos::Owned);
                self.stmts(body);
            }
            TypedStmt::Try { body, else_body, .. } => {
                self.stmts(body);
                self.stmts(else_body);
            }
            TypedStmt::Failure { body } => self.stmts(body),
            TypedStmt::Return | TypedStmt::Break | TypedStmt::Continue | TypedStmt::Todo(_) => {}
        }
    }

    fn user_callee(&self, func: &str) -> Option<(String, Vec<String>)> {
        if self.locals.contains(func) {
            return None;
        }
        let (qname, node) = typedexp::resolve_call_node(func, self.top_level, self.pkg_prefix)?;
        match &node.ty {
            Ty::Function { inputs, .. } => Some((qname, inputs.iter().map(|i| i.name.clone()).collect())),
            _ => None,
        }
    }

    fn arg(&mut self, a: &TypedExp, pos: Pos) {
        match a {
            TypedExp::Var { name, segments, .. } if is_plain(name, segments) => self.exp(a, pos),
            _ => self.exp(a, Pos::Owned),
        }
    }

    fn exp(&mut self, e: &TypedExp, pos: Pos) {
        let saved = if self.trace.is_some() && !matches!(e, TypedExp::Var { .. }) {
            let d = format!("{e:?}");
            Some(std::mem::replace(&mut self.parent, d.chars().take(160).collect()))
        } else {
            None
        };
        self.exp_inner(e, pos);
        if let Some(p) = saved {
            self.parent = p;
        }
    }

    fn exp_inner(&mut self, e: &TypedExp, pos: Pos) {
        match e {
            TypedExp::Var { name, segments, .. } => {
                let base = crate::codegen::var_base_name(name, segments);
                if !self.candidates.contains(&base) {
                    return;
                }
                if is_plain(name, segments) {
                    match pos {
                        Pos::Owned => {
                            let why = format!("read in {}", self.parent);
                            self.disqualify(&base, &why);
                        }
                        Pos::Borrow => {}
                        Pos::Arg(q, i) => self.deps.push((base, q, i)),
                    }
                } else {
                    for s in segments {
                        s.subscripts.iter().for_each(|x| self.exp(x, Pos::Owned));
                    }
                }
            }
            TypedExp::Call { func, args, named_args, .. } => {
                if let Some((short, inputs)) = self.self_call
                    && func == short
                {
                    let passed = |i: usize, a: &TypedExp| matches!(a,
                        TypedExp::Var { name, segments, .. } if is_plain(name, segments) && inputs.get(i) == Some(name));
                    let mut given: HashSet<usize> = HashSet::new();
                    let slots = args.iter().enumerate()
                        .chain(named_args.iter().filter_map(|(n, a)| Some((inputs.iter().position(|f| f == n)?, a))));
                    for (i, a) in slots {
                        given.insert(i);
                        if passed(i, a) {
                            continue;
                        }
                        if let Some(p) = inputs.get(i) {
                            self.disqualify(p, &"changed by a tail self-call");
                        }
                        self.exp(a, Pos::Owned);
                    }
                    for (i, p) in inputs.iter().enumerate() {
                        if !given.contains(&i) {
                            self.disqualify(p, &"defaulted in a tail self-call");
                        }
                    }
                } else if let Some((q, formals)) = self.user_callee(func) {
                    for (i, a) in args.iter().enumerate() {
                        self.arg(a, Pos::Arg(q.clone(), i));
                    }
                    for (n, a) in named_args {
                        match formals.iter().position(|f| f == n) {
                            Some(i) => self.arg(a, Pos::Arg(q.clone(), i)),
                            None => self.exp(a, Pos::Owned),
                        }
                    }
                } else {
                    for (i, a) in args.iter().enumerate() {
                        let p = if named_args.is_empty() && builtin_borrows(func, i) { Pos::Borrow } else { Pos::Owned };
                        self.arg(a, p);
                    }
                    named_args.iter().for_each(|(_, a)| self.exp(a, Pos::Owned));
                }
            }
            TypedExp::BinOp { op, lhs, rhs, ty } => {
                let str_eq = matches!(op, BinOpKind::Eq | BinOpKind::NEq) && lhs.ty() == Ty::Str && rhs.ty() == Ty::Str;
                let str_cat = matches!(op, BinOpKind::Add) && *ty == Ty::Str;
                let p = if str_eq || str_cat { Pos::Borrow } else { Pos::Owned };
                for side in [lhs, rhs] {
                    if str_cat && matches!(**side, TypedExp::BinOp { .. }) {
                        self.exp(side, Pos::Borrow);
                    } else {
                        self.arg(side, p.clone());
                    }
                }
            }
            TypedExp::Match { input, cases, as_binding, .. } => {
                let whole = |p: &TypedPat| matches!(p, TypedPat::Var(_) | TypedPat::As { .. } | TypedPat::Index { .. }
                    | TypedPat::FieldAccess { .. } | TypedPat::Todo(_));
                let borrowing = as_binding.is_none();
                match &**input {
                    TypedExp::Tuple(elems) if borrowing => {
                        for (i, el) in elems.iter().enumerate() {
                            let binds_whole = cases.iter().any(|c| match &c.pattern {
                                TypedPat::Tuple(ps) => ps.get(i).is_none_or(whole),
                                TypedPat::Wildcard => false,
                                _ => true,
                            });
                            self.arg(el, if binds_whole { Pos::Owned } else { Pos::Borrow });
                        }
                    }
                    _ => {
                        let binds_whole = cases.iter().any(|c| whole(&c.pattern));
                        let p = if borrowing && !binds_whole { Pos::Borrow } else { Pos::Owned };
                        self.arg(input, p);
                    }
                }
                if let Some(n) = as_binding {
                    self.bind(n);
                }
                for c in cases {
                    self.pat(&c.pattern);
                    for (n, _, init, _) in &c.locals {
                        self.bind(n);
                        if let Some(init) = init {
                            self.exp(init, Pos::Owned);
                        }
                    }
                    if let Some(g) = &c.guard {
                        self.exp(g, Pos::Owned);
                    }
                    self.stmts(&c.stmts);
                    self.exp(&c.result, Pos::Owned);
                }
            }
            TypedExp::UnOp { operand, .. } => self.exp(operand, Pos::Owned),
            TypedExp::Constructor { args, named_args, .. } | TypedExp::PartEval { args, named_args, .. } => {
                args.iter().for_each(|a| self.exp(a, Pos::Owned));
                named_args.iter().for_each(|(_, a)| self.exp(a, Pos::Owned));
            }
            TypedExp::If { cond, then_, elseif, else_, .. } => {
                self.exp(cond, Pos::Owned);
                self.exp(then_, Pos::Owned);
                for (c, b) in elseif {
                    self.exp(c, Pos::Owned);
                    self.exp(b, Pos::Owned);
                }
                self.exp(else_, Pos::Owned);
            }
            TypedExp::Cons { head, tail, .. } => {
                self.exp(head, Pos::Owned);
                self.exp(tail, Pos::Owned);
            }
            TypedExp::Tuple(elems) | TypedExp::Array { elems, .. } => elems.iter().for_each(|x| self.exp(x, Pos::Owned)),
            TypedExp::Range { start, step, stop, .. } => {
                self.exp(start, Pos::Owned);
                if let Some(s) = step {
                    self.exp(s, Pos::Owned);
                }
                self.exp(stop, Pos::Owned);
            }
            TypedExp::Reduction { body, iterators, .. } => {
                for it in iterators {
                    self.bind(&it.name);
                    self.exp(&it.range, Pos::Owned);
                    if let Some(g) = &it.guard {
                        self.exp(g, Pos::Owned);
                    }
                }
                self.exp(body, Pos::Owned);
            }
            TypedExp::Lit(_) | TypedExp::Todo(_) => {}
        }
    }
}

struct FnScan {
    inputs: Vec<String>,
    candidates: HashSet<String>,
    disq: HashSet<String>,
    deps: Vec<(String, String, usize)>,
}

fn scan_fn<'a>(
    qname: &str,
    node: &NameNode<'a>,
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    types: &Types<'_>,
    excluded: &HashSet<String>,
    trace: Option<&str>,
) -> Option<FnScan> {
    let top_pkg = qname.split('.').next().unwrap_or("");
    if excluded.contains(qname)
        || crate::codegen::HANDWRITTEN_TOP_PACKAGES.contains(&top_pkg)
        || crate::codegen::function_source_replacement(qname).is_some()
        || node.base_fn.is_some()
        || !node.extends.is_empty()
    {
        return None;
    }
    let NodeKind::Class(c) = &node.kind else { return None };
    if c.partial_prefix {
        return None;
    }
    let MM::ClassDef::Parts { members, algorithms, external: None, .. } = &c.body else { return None };
    if algorithms.is_empty() {
        return None;
    }
    let Ty::Function { inputs, .. } = &node.ty else { return None };
    let mut outputs: Vec<String> = Vec::new();
    let mut locals: HashSet<String> = HashSet::new();
    for m in members {
        if let MM::ClassMember::Component(cm) = m {
            locals.insert(cm.name.clone());
            if matches!(cm.direction, Absyn::Direction::OUTPUT | Absyn::Direction::INPUT_OUTPUT) {
                outputs.push(cm.name.clone());
            }
        }
    }
    let kinds: HashMap<String, Kind> = inputs.iter()
        .filter(|i| !outputs.contains(&i.name))
        .filter_map(|i| Some((i.name.clone(), candidate_kind(&i.ty, types)?)))
        .collect();
    let candidates: HashSet<String> = kinds.keys().cloned().collect();
    let values: HashSet<String> = kinds.iter().filter(|(_, k)| **k == Kind::Value).map(|(n, _)| n.clone()).collect();
    if candidates.is_empty() {
        return None;
    }
    let stmts = crate::codegen::typedexp_function_body_for_analysis(qname, node, top_level);
    let short = qname.rsplit('.').next().unwrap_or(qname);
    let input_names: Vec<String> = inputs.iter().map(|i| i.name.clone()).collect();
    let tail_recursive = crate::codegen::stmts_have_tail_self_call(&stmts, &outputs, short);
    let pkg_prefix = qname.rsplit_once('.').map_or("", |(p, _)| p);
    let mut scan = Scan {
        top_level,
        self_call: tail_recursive.then_some((short, input_names.as_slice())),
        pkg_prefix,
        candidates: &candidates,
        values: &values,
        locals: &locals,
        disq: HashSet::new(),
        deps: Vec::new(),
        trace: trace.filter(|t| qname.ends_with(*t)).map(|_| qname),
        parent: String::new(),
    };
    scan.stmts(&stmts);
    let (disq, deps) = (scan.disq, scan.deps);
    Some(FnScan {
        inputs: input_names,
        candidates,
        disq,
        deps,
    })
}

/// `excluded` names the functions whose signature must stay by value.
pub(crate) fn analyze<'a>(
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    types: &Types<'_>,
    excluded: &HashSet<String>,
) -> BorrowMasks {
    let mut all_fns: Vec<(String, &'a NameNode<'a>)> = Vec::new();
    crate::codegen::collect_all_function_nodes(top_level, "", &mut all_fns);

    let trace = std::env::var("MMTORUST_TRACE_BORROW").ok();
    let scans: BTreeMap<String, FnScan> = all_fns.par_iter()
        .filter_map(|(qname, node)| Some((qname.clone(), scan_fn(qname, node, top_level, types, excluded, trace.as_deref())?)))
        .collect();

    let mut borrowed: HashMap<String, HashSet<String>> = scans.iter()
        .map(|(q, s)| (q.clone(), s.candidates.difference(&s.disq).cloned().collect()))
        .collect();
    loop {
        let mut changed = false;
        for (q, s) in &scans {
            for (param, callee, idx) in &s.deps {
                if !borrowed[q].contains(param) {
                    continue;
                }
                let ok = scans.get(callee)
                    .and_then(|cs| cs.inputs.get(*idx))
                    .is_some_and(|formal| borrowed[callee].contains(formal));
                if !ok {
                    if trace.as_deref().is_some_and(|t| q.ends_with(t)) {
                        eprintln!("[borrow] {q}: `{param}` by value: passed to {callee} #{idx}");
                    }
                    borrowed.get_mut(q).unwrap().remove(param);
                    changed = true;
                }
            }
        }
        if !changed {
            break;
        }
    }

    scans.iter()
        .filter(|(q, _)| !borrowed[*q].is_empty())
        .map(|(q, s)| (q.clone(), s.inputs.iter().map(|i| borrowed[q].contains(i)).collect()))
        .collect()
}
