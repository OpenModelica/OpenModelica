//! Chooses the input parameters that are emitted as `&T` instead of `T`.
//!
//! A parameter qualifies when its type is a heap handle (`Ref<T>`, `List<T>`,
//! `ArcStr`, a callback, which becomes a `&dyn Fn`) or a non-`Copy` record, it
//! is never written or shadowed, and every read borrows it: a field access, a
//! match or pattern-let subject, a borrowing builtin, or an argument to a callee
//! parameter that itself qualifies (solved as a greatest fixpoint). In a
//! loop-lowered (tail-recursive) function a self-call must pass it on unchanged
//! or replace it by a field of a borrowed parameter. Callers then pass `&x`
//! instead of cloning the value into the call.
//!
//! The same fixpoint chooses callback *slots*: the inputs of a borrowed
//! callback parameter that the function passes by reference (`&dyn Fn(&T)`).
//! A slot input qualifies when every function or partial application passed
//! there borrows it or takes a `Copy` type, so no adapter has to clone, or when
//! the function could not move its argument there anyway (a loop variable, a
//! pattern binding, an unwritten variable read in a loop), so the clone only
//! moves from the function into the adapter.

use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet};

use crate::hierarchy::{NameNode, NodeKind, Ty};
use crate::typedexp::{self, BinOpKind, MatchKind, TypedExp, TypedPat, TypedStmt};
use crate::MM;
use rayon::prelude::*;
use openmodelica_ast::Absyn;

pub(crate) type BorrowMasks = BTreeMap<String, Vec<bool>>;
/// (function, callback parameter) -> inputs the callback takes by reference.
pub(crate) type SlotMasks = BTreeMap<(String, String), Vec<bool>>;

static MASKS: std::sync::OnceLock<BorrowMasks> = std::sync::OnceLock::new();
static SLOTS: std::sync::OnceLock<SlotMasks> = std::sync::OnceLock::new();

/// Hand-written functions whose parameters are borrowed.
const HANDWRITTEN_MASKS: &[(&str, &[bool])] = &[
    ("System.dladdr", &[true]),
];

pub(crate) fn install(mut masks: BorrowMasks, slots: SlotMasks) {
    for (q, m) in HANDWRITTEN_MASKS {
        masks.insert((*q).to_owned(), m.to_vec());
    }
    let _ = MASKS.set(masks);
    let _ = SLOTS.set(slots);
}

pub(crate) fn slot_mask(qname: &str, param: &str) -> Option<&'static [bool]> {
    SLOTS.get()?.get(&(qname.to_owned(), param.to_owned())).map(|v| v.as_slice())
}

/// The borrow mask of the function `qname`, if any of its parameters is borrowed.
pub(crate) fn mask(qname: &str) -> Option<&'static [bool]> {
    MASKS.get()?.get(qname).map(|v| v.as_slice())
}

#[derive(Clone, Copy, PartialEq)]
enum Kind {
    /// `Ref<T>`, `List<T>`, `ArcStr`, and a callback, borrowed as `&dyn Fn`.
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
        Ty::List(_) | Ty::Str | Ty::Function { .. } => Some(Kind::Handle),
        Ty::RustStruct(n) | Ty::RustEnum(n) | Ty::AliasTo(n) if types.recursive.contains(n) => Some(Kind::Handle),
        Ty::RustStruct(n) | Ty::RustEnum(n) | Ty::AliasTo(n) if !types.copy.contains(n) => Some(Kind::Value),
        Ty::UnionTypeVariant(parent, _) if types.recursive.contains(parent) => Some(Kind::Handle),
        Ty::Tuple(ts) if ts.iter().any(|t| candidate_kind(t, types).is_some() || matches!(t, Ty::Option(_))) =>
            Some(Kind::Handle),
        _ => None,
    }
}

fn is_copy(ty: &Ty, types: &Types<'_>) -> bool {
    match ty {
        Ty::I32 | Ty::F64 | Ty::Bool | Ty::Enumeration(_) => true,
        Ty::RustStruct(q) | Ty::RustEnum(q) | Ty::AliasTo(q) => types.copy.contains(q),
        Ty::Tuple(ts) => ts.iter().all(|t| is_copy(t, types)),
        _ => false,
    }
}

fn slot_candidate(ty: &Ty, types: &Types<'_>) -> bool {
    !matches!(ty, Ty::Function { .. } | Ty::FunctionAlias { .. } | Ty::Unknown) && !is_copy(ty, types)
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
        | TypedPat::EmptyList | TypedPat::As { .. } | TypedPat::Tuple(_))
}

/// For a plain match on `Ref`/`List` parameters (one, or a tuple of them), the
/// list tails and constructor fields a case binds from a parameter column into
/// its own (not escaping) locals and does not reassign, as (binding, parameter). When every column is
/// borrowed, codegen matches the references themselves, so these outlive the
/// arm.
pub(crate) fn param_tail_bindings(
    input: &TypedExp,
    case: &crate::typedexp::TypedCase,
    is_param: &dyn Fn(&str, &Ty) -> bool,
) -> Vec<(String, String)> {
    let plain = |e: &TypedExp| match e {
        TypedExp::Var { name, segments, ty, .. } if is_plain(name, segments) && is_param(name, ty) => Some(name.clone()),
        _ => None,
    };
    let cols: Vec<(String, &TypedPat)> = match (input, &case.pattern) {
        (TypedExp::Tuple(es), TypedPat::Tuple(ps)) if es.len() == ps.len() => {
            let Some(names) = es.iter().map(plain).collect::<Option<Vec<_>>>() else { return Vec::new() };
            names.into_iter().zip(ps.iter()).collect()
        }
        (TypedExp::Tuple(_), _) => return Vec::new(),
        (e, p) => match plain(e) {
            Some(n) => vec![(n, p)],
            None => return Vec::new(),
        },
    };
    let mut written = HashSet::new();
    crate::codegen::stmts_assigned_var_names(&case.stmts, &mut written);
    crate::codegen::exp_assigned_var_names(&case.result, &mut written);
    let local = |x: &String| !written.contains(x) && case.locals.iter().any(|(n, _, d, _)| n == x && d.is_none());
    let mut out = Vec::new();
    for (p, pat) in cols {
        let parts: Vec<&TypedPat> = match pat {
            TypedPat::Cons { tail, .. } => vec![&**tail],
            TypedPat::Constructor { fields, named_fields, .. } =>
                fields.iter().chain(named_fields.iter().map(|(_, f)| f)).collect(),
            _ => Vec::new(),
        };
        for part in parts {
            if let TypedPat::Var(x) = part && local(x) {
                out.push((x.clone(), p.clone()));
            }
        }
    }
    out
}

#[derive(Clone, Debug)]
enum Target {
    Param(String, usize),
    Slot(String, String, usize),
}

#[derive(Clone)]
enum Pos {
    Owned,
    Borrow,
    Arg(Target),
}

/// An argument of a callback call, for deciding whether it could be moved.
enum CbArg {
    /// A fresh value per iteration: a `for`/reduction variable.
    Loop,
    Name { name: String, in_loop: bool },
    Other,
}

/// What a function value passed to a callback slot needs, per slot input.
#[derive(Clone, Debug)]
enum Req {
    Ok,
    Fail,
    /// The adapter clones, which only a free slot pays nothing for.
    Clone,
    Param(Target),
}

struct Scan<'a, 'b> {
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    qname: &'b str,
    /// Set for a loop-lowered function (short name, inputs): its tail
    /// self-calls reassign the parameters.
    self_call: Option<(&'b str, &'b [String])>,
    pkg_prefix: &'b str,
    candidates: &'b HashSet<String>,
    values: &'b HashSet<String>,
    locals: &'b HashSet<String>,
    /// In a loop-lowered function, the parts of parameters bound by the
    /// enclosing match arms (see [`param_tail_bindings`]).
    tails: HashMap<String, Vec<String>>,
    recursive: &'b BTreeSet<String>,
    disq: HashSet<String>,
    deps: Vec<(String, Target)>,
    callbacks: &'b HashMap<String, Vec<bool>>,
    types: &'b Types<'b>,
    /// Function values passed to callback slots: (callee, formal, per input).
    srcs: Vec<(String, String, Vec<Req>)>,
    /// Arguments of calls through callback parameters: (parameter, input, arg).
    cb_args: Vec<(String, usize, CbArg)>,
    written: HashSet<String>,
    /// Bound inside a destructuring pattern, i.e. read out of a shared value.
    part_bound: HashSet<String>,
    destructure_depth: usize,
    loop_vars: Vec<String>,
    loop_depth: usize,
    /// Match-arm nesting of the current read.
    case_depth: usize,
    /// Owned uses inside a match arm, which a recursive function pays for with
    /// a clone there instead of one per call: (param, callee slot or `None`).
    soft: Vec<(String, Option<Target>)>,
    calls_self: bool,
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
        self.written.insert(name.to_owned());
        if self.destructure_depth > 0 {
            self.part_bound.insert(name.to_owned());
        }
        self.disqualify(name, &"written or shadowed");
    }

    /// Whether every call through callback `p` passes input `j` a value it
    /// could not have moved.
    fn slot_free(&self, p: &str, j: usize) -> bool {
        let mut any = false;
        for (q, i, a) in &self.cb_args {
            if q != p || *i != j {
                continue;
            }
            any = true;
            let free = match a {
                CbArg::Loop => true,
                CbArg::Name { name, in_loop } => self.part_bound.contains(name) || !self.written.contains(name) && *in_loop,
                CbArg::Other => false,
            };
            if !free {
                return false;
            }
        }
        any
    }

    fn pat(&mut self, p: &TypedPat) {
        match p {
            TypedPat::Var(n) => self.bind(n),
            TypedPat::As { var, pat } => {
                self.bind(var);
                self.pat(pat);
            }
            TypedPat::Some_(inner) => {
                self.destructure_depth += 1;
                self.pat(inner);
                self.destructure_depth -= 1;
            }
            TypedPat::Cons { head, tail } => {
                self.destructure_depth += 1;
                self.pat(head);
                self.pat(tail);
                self.destructure_depth -= 1;
            }
            TypedPat::Tuple(ps) => ps.iter().for_each(|p| self.pat(p)),
            TypedPat::Constructor { fields, named_fields, .. } => {
                self.destructure_depth += 1;
                fields.iter().for_each(|p| self.pat(p));
                named_fields.iter().for_each(|(_, p)| self.pat(p));
                self.destructure_depth -= 1;
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
                let p = if matches!(range.ty(), Ty::List(_)) { Pos::Borrow } else { Pos::Owned };
                self.arg(range, p);
                self.loop_vars.push(var.clone());
                self.loop_depth += 1;
                self.stmts(body);
                self.loop_depth -= 1;
                self.loop_vars.pop();
            }
            TypedStmt::While { cond, body } => {
                self.loop_depth += 1;
                self.exp(cond, Pos::Owned);
                self.stmts(body);
                self.loop_depth -= 1;
            }
            TypedStmt::Try { body, else_body, .. } => {
                self.stmts(body);
                self.stmts(else_body);
            }
            TypedStmt::Failure { body } => self.stmts(body),
            TypedStmt::Return | TypedStmt::Break | TypedStmt::Continue | TypedStmt::Todo(_) => {}
        }
    }

    fn user_callee(&self, func: &str) -> Option<(String, Vec<crate::hierarchy::FunctionInput>)> {
        if self.locals.contains(func) {
            return None;
        }
        let (qname, node) = typedexp::resolve_call_node(func, self.top_level, self.pkg_prefix)?;
        match &node.ty {
            Ty::Function { inputs, .. } => Some((qname, inputs.clone())),
            _ => None,
        }
    }

    fn named_fn(&self, name: &str) -> Option<(String, Vec<crate::hierarchy::FunctionInput>)> {
        let (qname, node) = typedexp::resolve_call_node(name, self.top_level, self.pkg_prefix)?;
        let NodeKind::Class(_) = &node.kind else { return None };
        match &node.ty {
            Ty::Function { inputs, .. } => Some((qname, inputs.clone())),
            _ => None,
        }
    }

    /// A function used as a value is called through `Arc<dyn Fn>` values its
    /// callers cannot see, so its callback inputs get an unknown source.
    fn escaping_fn(&mut self, name: &str) {
        let Some((f, ins)) = self.named_fn(name) else { return };
        for i in ins {
            if let Ty::Function { inputs, .. } = &i.ty {
                self.srcs.push((f.clone(), i.name.clone(), vec![Req::Clone; inputs.len()]));
            }
        }
    }

    fn fn_value_source(&mut self, callee: &str, formal: &crate::hierarchy::FunctionInput, a: &TypedExp) {
        let Ty::Function { inputs: slot_ins, .. } = &formal.ty else { return };
        let need = |f: &str, ins: &[crate::hierarchy::FunctionInput], idx: Option<usize>| -> Req {
            match idx.and_then(|i| ins.get(i).map(|inp| (i, inp))) {
                Some((_, inp)) if is_copy(&inp.ty, self.types) => Req::Ok,
                Some((i, _)) => Req::Param(Target::Param(f.to_owned(), i)),
                None => Req::Fail,
            }
        };
        let reqs: Vec<Req> = match a {
            TypedExp::Var { name, segments, .. } if is_plain(name, segments) && self.callbacks.contains_key(name.as_str()) =>
                (0..slot_ins.len()).map(|j| Req::Param(Target::Slot(self.qname.to_owned(), name.clone(), j))).collect(),
            TypedExp::Var { name, segments, .. } if is_plain(name, segments) && self.locals.contains(name.as_str()) =>
                vec![Req::Clone; slot_ins.len()],
            TypedExp::Var { name, segments, .. } if segments.iter().all(|s| s.subscripts.is_empty()) => {
                match (self.named_fn(name), typedexp::builtin_function_ty(name)) {
                    (Some((f, ins)), _) => (0..slot_ins.len()).map(|j| need(&f, &ins, Some(j))).collect(),
                    (None, Some(Ty::Function { inputs: ins, .. })) => (0..slot_ins.len())
                        .map(|j| match ins.get(j) {
                            Some(inp) if is_copy(&inp.ty, self.types) => Req::Ok,
                            _ => Req::Clone,
                        })
                        .collect(),
                    _ => vec![Req::Clone; slot_ins.len()],
                }
            }
            TypedExp::PartEval { func, args, named_args, .. } if !self.locals.contains(func.as_str()) => {
                match self.named_fn(func) {
                    Some((f, ins)) => {
                        let unbound: Vec<usize> = (args.len()..ins.len())
                            .filter(|&i| !named_args.iter().any(|(n, _)| *n == ins[i].name))
                            .collect();
                        (0..slot_ins.len()).map(|j| need(&f, &ins, unbound.get(j).copied())).collect()
                    }
                    None => vec![Req::Clone; slot_ins.len()],
                }
            }
            _ => vec![Req::Fail; slot_ins.len()],
        };
        self.srcs.push((callee.to_owned(), formal.name.clone(), reqs));
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
            TypedExp::Var { name, segments, ty, .. } => {
                let base = crate::codegen::var_base_name(name, segments);
                if !self.locals.contains(base.as_str()) && segments.iter().all(|s| s.subscripts.is_empty()) {
                    self.escaping_fn(name);
                }
                if !self.candidates.contains(&base) {
                    return;
                }
                if is_plain(name, segments) {
                    let soft = self.case_depth > 0 && !matches!(ty, Ty::Function { .. });
                    match pos {
                        Pos::Owned if soft => self.soft.push((base, None)),
                        Pos::Owned => {
                            let why = format!("read in {}", self.parent);
                            self.disqualify(&base, &why);
                        }
                        Pos::Borrow => {}
                        Pos::Arg(t) if soft => self.soft.push((base, Some(t))),
                        Pos::Arg(t) => self.deps.push((base, t)),
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
                        // A field of a borrowed parameter outlives the iteration too.
                        let field_of = match a {
                            TypedExp::Var { segments, .. }
                                if segments.len() == 2 && segments.iter().all(|s| s.subscripts.is_empty()) =>
                                inputs.iter().position(|n| *n == segments[0].name && self.candidates.contains(n)),
                            _ => None,
                        };
                        if let (Some(p), Some(j)) = (inputs.get(i), field_of) {
                            self.deps.push((p.clone(), Target::Param(self.qname.to_owned(), j)));
                            continue;
                        }
                        let tail_of: Option<Vec<usize>> = match a {
                            TypedExp::Var { name, segments, .. } if is_plain(name, segments) => self.tails.get(name)
                                .and_then(|from| from.iter().map(|q| inputs.iter().position(|n| n == q)).collect()),
                            _ => None,
                        };
                        if let (Some(p), Some(js)) = (inputs.get(i), tail_of) {
                            for j in js {
                                self.deps.push((p.clone(), Target::Param(self.qname.to_owned(), j)));
                            }
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
                } else if let Some(slots) = self.callbacks.get(func.as_str()) {
                    let slots = slots.clone();
                    for (j, a) in args.iter().enumerate() {
                        let shape = match a {
                            TypedExp::Var { name, segments, .. } if is_plain(name, segments) =>
                                if self.loop_vars.contains(name) {
                                    CbArg::Loop
                                } else {
                                    CbArg::Name { name: name.clone(), in_loop: self.loop_depth > 0 }
                                },
                            _ => CbArg::Other,
                        };
                        self.cb_args.push((func.clone(), j, shape));
                        if named_args.is_empty() && slots.get(j) == Some(&true) {
                            self.arg(a, Pos::Arg(Target::Slot(self.qname.to_owned(), func.clone(), j)));
                        } else {
                            self.exp(a, Pos::Owned);
                        }
                    }
                    named_args.iter().for_each(|(_, a)| self.exp(a, Pos::Owned));
                } else if let Some((q, formals)) = self.user_callee(func) {
                    if q == self.qname {
                        self.calls_self = true;
                    }
                    let fixed = HANDWRITTEN_MASKS.iter().find(|(h, _)| *h == q).map(|(_, m)| *m);
                    for (i, a) in args.iter().enumerate() {
                        if let Some(f) = formals.get(i) {
                            self.fn_value_source(&q, f, a);
                        }
                        match fixed {
                            Some(m) if m.get(i) == Some(&true) => self.arg(a, Pos::Borrow),
                            Some(_) => self.exp(a, Pos::Owned),
                            None => self.arg(a, Pos::Arg(Target::Param(q.clone(), i))),
                        }
                    }
                    for (n, a) in named_args {
                        match formals.iter().position(|f| f.name == *n) {
                            Some(i) => {
                                self.fn_value_source(&q, &formals[i], a);
                                self.arg(a, Pos::Arg(Target::Param(q.clone(), i)));
                            }
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
            TypedExp::Match { kind, input, cases, as_binding, .. } => {
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
                let track_tails = self.self_call.is_some() && matches!(kind, MatchKind::Match) && as_binding.is_none();
                let columns: Vec<String> = match &**input {
                    TypedExp::Tuple(es) => es.iter().filter_map(|e| match e {
                        TypedExp::Var { name, .. } => Some(name.clone()),
                        _ => None,
                    }).collect(),
                    TypedExp::Var { name, .. } => vec![name.clone()],
                    _ => Vec::new(),
                };
                self.case_depth += 1;
                for c in cases {
                    let saved_tails = self.tails.clone();
                    if track_tails {
                        let (cands, recursive) = (self.candidates, self.recursive);
                        let is_param = |n: &str, t: &Ty| cands.contains(n) && match t {
                            Ty::List(_) => true,
                            Ty::RustStruct(q) | Ty::RustEnum(q) | Ty::AliasTo(q) => recursive.contains(q),
                            Ty::UnionTypeVariant(q, _) => recursive.contains(q),
                            _ => false,
                        };
                        for (x, p) in param_tail_bindings(input, c, &is_param) {
                            let mut from = vec![p.clone()];
                            from.extend(columns.iter().filter(|q| **q != p).cloned());
                            self.tails.insert(x, from);
                        }
                    }
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
                    self.tails = saved_tails;
                }
                self.case_depth -= 1;
            }
            TypedExp::UnOp { operand, .. } => self.exp(operand, Pos::Owned),
            TypedExp::Constructor { args, named_args, .. } => {
                args.iter().for_each(|a| self.exp(a, Pos::Owned));
                named_args.iter().for_each(|(_, a)| self.exp(a, Pos::Owned));
            }
            TypedExp::PartEval { func, args, named_args, .. } => {
                self.disqualify(func, &"partially applied");
                if !self.locals.contains(func.as_str()) {
                    self.escaping_fn(func);
                }
                if let Some((q, formals)) = self.user_callee(func) {
                    for (i, a) in args.iter().enumerate() {
                        if let Some(f) = formals.get(i) {
                            self.fn_value_source(&q, f, a);
                        }
                    }
                    for (n, a) in named_args {
                        if let Some(f) = formals.iter().find(|f| f.name == *n) {
                            self.fn_value_source(&q, f, a);
                        }
                    }
                }
                // The closure captures a clone once; a callback cannot be cloned
                // out of a `&dyn Fn`.
                let capture = |a: &TypedExp| if matches!(a.ty(), Ty::Function { .. }) { Pos::Owned } else { Pos::Borrow };
                args.iter().for_each(|a| self.arg(a, capture(a)));
                named_args.iter().for_each(|(_, a)| self.arg(a, capture(a)));
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
                    self.loop_vars.push(it.name.clone());
                }
                self.loop_depth += 1;
                for it in iterators {
                    if let Some(g) = &it.guard {
                        self.exp(g, Pos::Owned);
                    }
                }
                self.exp(body, Pos::Owned);
                self.loop_depth -= 1;
                self.loop_vars.truncate(self.loop_vars.len() - iterators.len());
            }
            TypedExp::Lit(_) | TypedExp::Todo(_) => {}
        }
    }
}

struct FnScan {
    inputs: Vec<String>,
    candidates: HashSet<String>,
    disq: HashSet<String>,
    deps: Vec<(String, Target)>,
    slots: HashMap<String, Vec<bool>>,
    /// Slot inputs that need no borrowing callee (see [`Scan::slot_free`]).
    free: HashMap<String, Vec<bool>>,
    srcs: Vec<(String, String, Vec<Req>)>,
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
    let own_masks = !excluded.contains(qname);
    if crate::codegen::HANDWRITTEN_TOP_PACKAGES.contains(&top_pkg)
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
    let MM::ClassDef::Parts { members, external: None, .. } = &c.body else { return None };
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
        .filter(|i| own_masks && !outputs.contains(&i.name))
        .filter_map(|i| Some((i.name.clone(), candidate_kind(&i.ty, types)?)))
        .collect();
    let candidates: HashSet<String> = kinds.keys().cloned().collect();
    let values: HashSet<String> = kinds.iter().filter(|(_, k)| **k == Kind::Value).map(|(n, _)| n.clone()).collect();
    let callbacks: HashMap<String, Vec<bool>> = inputs.iter()
        .filter(|i| !outputs.contains(&i.name))
        .filter_map(|i| match &i.ty {
            Ty::Function { inputs: ins, .. } => Some((i.name.clone(),
                ins.iter().map(|x| candidates.contains(&i.name) && slot_candidate(&x.ty, types)).collect())),
            _ => None,
        })
        .collect();
    let stmts = crate::codegen::typedexp_function_body_for_analysis(qname, node, top_level);
    let short = qname.rsplit('.').next().unwrap_or(qname);
    let input_names: Vec<String> = inputs.iter().map(|i| i.name.clone()).collect();
    let tail_recursive = crate::codegen::stmts_have_tail_self_call(&stmts, &outputs, short);
    let pkg_prefix = qname.rsplit_once('.').map_or("", |(p, _)| p);
    let mut scan = Scan {
        top_level,
        qname,
        self_call: tail_recursive.then_some((short, input_names.as_slice())),
        pkg_prefix,
        candidates: &candidates,
        values: &values,
        locals: &locals,
        tails: HashMap::new(),
        recursive: types.recursive,
        disq: HashSet::new(),
        deps: Vec::new(),
        callbacks: &callbacks,
        types,
        srcs: Vec::new(),
        cb_args: Vec::new(),
        written: HashSet::new(),
        part_bound: HashSet::new(),
        destructure_depth: 0,
        loop_vars: Vec::new(),
        loop_depth: 0,
        case_depth: 0,
        soft: Vec::new(),
        calls_self: false,
        trace: trace.filter(|t| qname.ends_with(*t)).map(|_| qname),
        parent: String::new(),
    };
    for init in crate::codegen::typedexp_initializers_for_analysis(qname, node, top_level) {
        scan.exp(&init, Pos::Owned);
    }
    scan.stmts(&stmts);
    if !scan.calls_self && scan.self_call.is_none() {
        for (p, slot) in std::mem::take(&mut scan.soft) {
            match slot {
                Some(t) => scan.deps.push((p, t)),
                None => scan.disqualify(&p, &"read in a match arm"),
            }
        }
    }
    let free: HashMap<String, Vec<bool>> = callbacks.iter()
        .map(|(p, v)| (p.clone(), (0..v.len()).map(|j| v[j] && scan.slot_free(p, j)).collect()))
        .collect();
    let (disq, deps, srcs) = (scan.disq, scan.deps, scan.srcs);
    let slots = callbacks.into_iter().filter(|(_, v)| v.contains(&true)).collect();
    Some(FnScan {
        inputs: input_names,
        candidates,
        disq,
        deps,
        slots,
        free,
        srcs,
    })
}

/// `excluded` names the functions whose signature must stay by value, unless
/// `forced` fixes their mask.
pub(crate) fn analyze<'a>(
    top_level: &'a BTreeMap<String, NameNode<'a>>,
    types: &Types<'_>,
    excluded: &HashSet<String>,
    forced: &BorrowMasks,
) -> (BorrowMasks, SlotMasks) {
    let mut all_fns: Vec<(String, &'a NameNode<'a>)> = Vec::new();
    crate::codegen::collect_all_function_nodes(top_level, "", &mut all_fns);

    let trace = std::env::var("MMTORUST_TRACE_BORROW").ok();
    let traced = |q: &str| trace.as_deref().is_some_and(|t| q.ends_with(t));
    let scans: BTreeMap<String, FnScan> = all_fns.par_iter()
        .filter_map(|(qname, node)| Some((qname.clone(), scan_fn(qname, node, top_level, types, excluded, trace.as_deref())?)))
        .collect();

    let mut borrowed: HashMap<String, HashSet<String>> = scans.iter()
        .map(|(q, s)| (q.clone(), s.candidates.difference(&s.disq).cloned().collect()))
        .collect();
    let mut slots: HashMap<(String, String), Vec<bool>> = scans.iter()
        .flat_map(|(q, s)| s.slots.iter().map(move |(p, v)| ((q.clone(), p.clone()), v.clone())))
        .collect();
    let param_ok = |borrowed: &HashMap<String, HashSet<String>>, callee: &str, idx: usize| match forced.get(callee) {
        Some(m) => m.get(idx).copied().unwrap_or(false),
        None => scans.get(callee)
            .and_then(|cs| cs.inputs.get(idx))
            .is_some_and(|formal| borrowed[callee].contains(formal)),
    };
    let target_ok = |borrowed: &HashMap<String, HashSet<String>>, slots: &HashMap<(String, String), Vec<bool>>, t: &Target| match t {
        Target::Param(callee, idx) => param_ok(borrowed, callee, *idx),
        Target::Slot(q, p, j) => slots.get(&(q.clone(), p.clone())).is_some_and(|v| v.get(*j) == Some(&true)),
    };
    loop {
        let mut changed = false;
        for (q, s) in &scans {
            for (param, target) in &s.deps {
                if borrowed[q].contains(param) && !target_ok(&borrowed, &slots, target) {
                    if traced(q) {
                        eprintln!("[borrow] {q}: `{param}` by value: passed on to a by-value input");
                    }
                    borrowed.get_mut(q).unwrap().remove(param);
                    changed = true;
                }
            }
        }
        for ((q, p), v) in slots.iter_mut() {
            if !borrowed[q].contains(p) && v.contains(&true) {
                v.iter_mut().for_each(|b| *b = false);
                changed = true;
            }
        }
        for (caller, s) in &scans {
            for (h, k, reqs) in &s.srcs {
                let key = (h.clone(), k.clone());
                let Some(v) = slots.get(&key) else { continue };
                let free = |j: usize| scans[h].free.get(k).is_some_and(|f| f.get(j) == Some(&true));
                let drop: Vec<usize> = (0..v.len())
                    .filter(|&j| v[j] && match reqs.get(j) {
                        Some(Req::Ok) => false,
                        Some(Req::Param(t)) => !free(j) && !target_ok(&borrowed, &slots, t),
                        Some(Req::Clone) => !free(j),
                        Some(Req::Fail) | None => true,
                    })
                    .collect();
                if !drop.is_empty() {
                    if traced(h) {
                        eprintln!("[borrow] {h}: callback `{k}` inputs {drop:?} by value: {caller} passes {:?}", reqs);
                    }
                    let v = slots.get_mut(&key).unwrap();
                    drop.into_iter().for_each(|j| v[j] = false);
                    changed = true;
                }
            }
        }
        if !changed {
            break;
        }
    }

    let mut masks: BorrowMasks = scans.iter()
        .filter(|(q, _)| !borrowed[*q].is_empty())
        .map(|(q, s)| (q.clone(), s.inputs.iter().map(|i| borrowed[q].contains(i)).collect()))
        .collect();
    masks.extend(forced.iter().filter(|(_, m)| m.contains(&true)).map(|(q, m)| (q.clone(), m.clone())));
    let slots: SlotMasks = slots.into_iter().filter(|(_, v)| v.contains(&true)).collect();
    for ((q, p), v) in &slots {
        if traced(q) {
            eprintln!("[borrow] {q}: callback `{p}` takes {v:?} by reference");
        }
    }
    (masks, slots)
}
