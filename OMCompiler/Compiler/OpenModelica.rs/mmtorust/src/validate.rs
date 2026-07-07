//! Source validation pass: reject constructs the port no longer supports.
//!
//! Currently this enforces a single rule: a `match`/`matchcontinue` case body
//! must be an `algorithm` section, never an `equation` section. The
//! MetaModelica sources are being migrated so that every case uses `algorithm`;
//! an `equation` case that slips through is a migration miss, so the generator
//! errors out with the full list of offenders rather than silently translating
//! them.

use std::collections::BTreeMap;

use openmodelica_ast::Absyn;

use crate::hierarchy::{InstanceHierarchy, NameNode, NodeKind};
use crate::MM;

/// Scan every function for `match`/`matchcontinue` cases whose body is an
/// `equation` section and return one `"<qname> (<file>:<line>:<col>)"` string
/// per offender, ordered by function FQN then source position.
pub fn match_cases_with_equation_sections(hier: &InstanceHierarchy<'_>) -> Vec<String> {
    let mut out: Vec<String> = Vec::new();
    walk_nodes(&hier.top_level, "", &mut out);
    out
}

fn walk_nodes(nodes: &BTreeMap<String, NameNode<'_>>, prefix: &str, out: &mut Vec<String>) {
    for (name, node) in nodes {
        let qname = if prefix.is_empty() { name.clone() } else { format!("{prefix}.{name}") };
        if let NodeKind::Class(c) = &node.kind
            && matches!(c.restriction, Absyn::Restriction::R_FUNCTION { .. })
        {
            let mut v = Finder { qname: &qname, out };
            v.scan_class(c);
        }
        walk_nodes(&node.children, &qname, out);
    }
}

struct Finder<'a> {
    qname: &'a str,
    out: &'a mut Vec<String>,
}

impl Finder<'_> {
    fn scan_class(&mut self, c: &MM::Class) {
        let (algorithms, members) = match &c.body {
            MM::ClassDef::Parts { algorithms, members, .. }
            | MM::ClassDef::ClassExtends { algorithms, members, .. } => (algorithms, members),
            _ => return,
        };
        for m in members {
            if let MM::ClassMember::Component(cm) = m
                && let Some(exp) = crate::hierarchy::extract_default_exp(&cm.modification)
            {
                self.scan_exp(exp);
            }
        }
        for it in &**algorithms {
            self.scan_algorithm_item(it);
        }
    }

    fn record(&mut self, info: &Absyn::Info) {
        self.out.push(format!(
            "{} ({}:{}:{})",
            self.qname, info.fileName, info.lineNumberStart, info.columnNumberStart
        ));
    }

    fn scan_case(&mut self, case: &Absyn::Case) {
        let (class_part, guard, result, info) = match case {
            Absyn::Case::CASE { classPart, patternGuard, result, info, .. } =>
                (classPart, patternGuard.as_deref(), result, info),
            Absyn::Case::ELSE { classPart, result, info, .. } =>
                (classPart, None, result, info),
        };
        // The rule under test: a case body must not be an `equation` section.
        if matches!(&**class_part,
            Absyn::ClassPart::EQUATIONS { .. } | Absyn::ClassPart::INITIALEQUATIONS { .. })
        {
            self.record(info);
        }
        // Recurse so nested matches (incl. ones inside an offending equation
        // section) are still inspected.
        if let Some(g) = guard { self.scan_exp(g); }
        self.scan_class_part(class_part);
        self.scan_exp(result);
    }

    fn scan_class_part(&mut self, part: &Absyn::ClassPart) {
        match part {
            Absyn::ClassPart::ALGORITHMS { contents }
            | Absyn::ClassPart::INITIALALGORITHMS { contents } => {
                for it in &**contents { self.scan_algorithm_item(it); }
            }
            Absyn::ClassPart::EQUATIONS { contents }
            | Absyn::ClassPart::INITIALEQUATIONS { contents } => {
                for it in &**contents { self.scan_equation_item(it); }
            }
            _ => {}
        }
    }

    fn scan_equation_item(&mut self, it: &Absyn::EquationItem) {
        let Absyn::EquationItem::EQUATIONITEM { equation_, .. } = it else { return };
        use Absyn::Equation::*;
        match &**equation_ {
            EQ_EQUALS { leftSide, rightSide } | EQ_PDE { leftSide, rightSide, .. } => {
                self.scan_exp(leftSide); self.scan_exp(rightSide);
            }
            EQ_NORETCALL { functionArgs, .. } => self.scan_function_args(functionArgs),
            EQ_IF { ifExp, equationTrueItems, elseIfBranches, equationElseItems } => {
                self.scan_exp(ifExp);
                for it in &**equationTrueItems { self.scan_equation_item(it); }
                for (c, items) in &**elseIfBranches {
                    self.scan_exp(c);
                    for it in &**items { self.scan_equation_item(it); }
                }
                for it in &**equationElseItems { self.scan_equation_item(it); }
            }
            EQ_FOR { forEquations, .. } => {
                for it in &**forEquations { self.scan_equation_item(it); }
            }
            EQ_WHEN_E { whenExp, whenEquations, elseWhenEquations } => {
                self.scan_exp(whenExp);
                for it in &**whenEquations { self.scan_equation_item(it); }
                for (c, items) in &**elseWhenEquations {
                    self.scan_exp(c);
                    for it in &**items { self.scan_equation_item(it); }
                }
            }
            EQ_FAILURE { equ } => self.scan_equation_item(equ),
            EQ_CONNECT { .. } => {}
        }
    }

    fn scan_algorithm_item(&mut self, it: &Absyn::AlgorithmItem) {
        let alg = match it {
            Absyn::AlgorithmItem::ALGORITHMITEM { algorithm_, .. } => &**algorithm_,
            Absyn::AlgorithmItem::ALGORITHMITEMCOMMENT { .. } => return,
        };
        use Absyn::Algorithm::*;
        match alg {
            ALG_ASSIGN { assignComponent, value } => { self.scan_exp(assignComponent); self.scan_exp(value); }
            ALG_IF { ifExp, trueBranch, elseIfAlgorithmBranch, elseBranch } => {
                self.scan_exp(ifExp);
                for it in &**trueBranch { self.scan_algorithm_item(it); }
                for (c, b) in &**elseIfAlgorithmBranch {
                    self.scan_exp(c);
                    for it in &**b { self.scan_algorithm_item(it); }
                }
                for it in &**elseBranch { self.scan_algorithm_item(it); }
            }
            ALG_FOR { iterators, forBody } | ALG_PARFOR { iterators, parforBody: forBody } => {
                for it in &**iterators {
                    let Absyn::ForIterator { range, guardExp, .. } = &**it;
                    if let Some(r) = range.as_deref() { self.scan_exp(r); }
                    if let Some(g) = guardExp.as_deref() { self.scan_exp(g); }
                }
                for it in &**forBody { self.scan_algorithm_item(it); }
            }
            ALG_WHILE { boolExpr, whileBody } => {
                self.scan_exp(boolExpr);
                for it in &**whileBody { self.scan_algorithm_item(it); }
            }
            ALG_WHEN_A { boolExpr, whenBody, elseWhenAlgorithmBranch } => {
                self.scan_exp(boolExpr);
                for it in &**whenBody { self.scan_algorithm_item(it); }
                for (e, b) in &**elseWhenAlgorithmBranch {
                    self.scan_exp(e);
                    for it in &**b { self.scan_algorithm_item(it); }
                }
            }
            ALG_NORETCALL { functionArgs, .. } => self.scan_function_args(functionArgs),
            ALG_FAILURE { equ } => for it in &**equ { self.scan_algorithm_item(it); },
            ALG_TRY { body, elseBody } => {
                for it in &**body { self.scan_algorithm_item(it); }
                for it in &**elseBody { self.scan_algorithm_item(it); }
            }
            ALG_RETURN | ALG_BREAK | ALG_CONTINUE => {}
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

    fn scan_exp(&mut self, e: &Absyn::Exp) {
        use Absyn::Exp::*;
        match e {
            INTEGER { .. } | REAL { .. } | STRING { .. } | BOOL { .. } | END | BREAK | CODE { .. } | CREF { .. } => {}
            BINARY { exp1, exp2, .. } | LBINARY { exp1, exp2, .. } | RELATION { exp1, exp2, .. } => {
                self.scan_exp(exp1); self.scan_exp(exp2);
            }
            UNARY { exp, .. } | LUNARY { exp, .. } => self.scan_exp(exp),
            IFEXP { ifExp, trueBranch, elseBranch, elseIfBranch } => {
                self.scan_exp(ifExp); self.scan_exp(trueBranch); self.scan_exp(elseBranch);
                for (c, t) in &**elseIfBranch { self.scan_exp(c); self.scan_exp(t); }
            }
            CALL { functionArgs, .. } | PARTEVALFUNCTION { functionArgs, .. } => self.scan_function_args(functionArgs),
            ARRAY { arrayExp } | LIST { exps: arrayExp } => for e in &**arrayExp { self.scan_exp(e); },
            MATRIX { matrix } => for row in &**matrix { for e in &**row { self.scan_exp(e); } },
            RANGE { start, step, stop } => {
                self.scan_exp(start);
                if let Some(s) = step.as_deref() { self.scan_exp(s); }
                self.scan_exp(stop);
            }
            TUPLE { expressions } => for e in &**expressions { self.scan_exp(e); },
            AS { exp, .. } => self.scan_exp(exp),
            CONS { head, rest } => { self.scan_exp(head); self.scan_exp(rest); }
            MATCHEXP { inputExp, cases, .. } => {
                self.scan_exp(inputExp);
                for case in &**cases { self.scan_case(case); }
            }
            DOT { exp, index } => { self.scan_exp(exp); self.scan_exp(index); }
            EXPRESSIONCOMMENT { exp, .. } => self.scan_exp(exp),
            SUBSCRIPTED_EXP { exp, .. } => self.scan_exp(exp),
        }
    }
}
