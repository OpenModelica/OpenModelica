//! "This `matchcontinue` is a `match`", decided from the patterns alone.
//!
//! When no two case patterns can match the same value, an arm's fall-through
//! can never reach an arm that matches, so the construct fails as a whole —
//! exactly what `match` does, whatever the arms call. That makes this check
//! complementary to the fallibility-based one in [`crate::fallibility`].
//!
//! [`pats_disjoint`] mirrors `Patternm.patternsDoNotOverlap`, which the
//! frontend already applies over the elaborated `DAE.Pattern`. Anything
//! unrecognised is reported as overlapping.

use std::collections::{BTreeMap, BTreeSet};
use std::sync::Arc;

use openmodelica_ast::Absyn;

use crate::fallibility::{absyn_pat_is_irrefutable, collect_local_decl_names, cref_to_dotted};
use crate::hierarchy::NameNode;
use crate::typedexp::resolve_call_node;

/// Are the case patterns of a `matchcontinue` pairwise disjoint? `scope` is the
/// binding scope shared by every case (function components plus the match's own
/// `local` declarations); each case's own `local`s are layered on per case.
pub(crate) fn cases_pairwise_disjoint(
    cases: &metamodelica::List<Arc<Absyn::Case>>,
    scope: &BTreeSet<String>,
    top_level: &BTreeMap<String, NameNode<'_>>,
    caller_qname: &str,
) -> bool {
    let mut pats: Vec<(Arc<Absyn::Exp>, BTreeSet<String>)> = Vec::new();
    for case in cases {
        match &**case {
            // `else` matches everything, so it overlaps every other case.
            Absyn::Case::ELSE { .. } => return false,
            Absyn::Case::CASE { pattern, localDecls, .. } => {
                let mut s = scope.clone();
                collect_local_decl_names(localDecls, &mut s);
                pats.push((pattern.clone(), s));
            }
        }
    }
    // A single case is the fallibility lint's business (a lone arm has nothing
    // to fall through to); reporting it here too would duplicate the warning.
    if pats.len() < 2 {
        return false;
    }
    for (i, (p1, s1)) in pats.iter().enumerate() {
        for (p2, s2) in &pats[i + 1..] {
            if !pats_disjoint(p1, p2, s1, s2, top_level, caller_qname) {
                return false;
            }
        }
    }
    true
}

/// Can no value match both patterns? Conservative: `false` whenever the shapes
/// do not prove disjointness.
fn pats_disjoint(
    p1: &Absyn::Exp,
    p2: &Absyn::Exp,
    s1: &BTreeSet<String>,
    s2: &BTreeSet<String>,
    top_level: &BTreeMap<String, NameNode<'_>>,
    caller_qname: &str,
) -> bool {
    use Absyn::Exp::*;
    // `id as pat` matches whatever `pat` matches.
    if let AS { exp, .. } = p1 {
        return pats_disjoint(exp, p2, s1, s2, top_level, caller_qname);
    }
    if let AS { exp, .. } = p2 {
        return pats_disjoint(p1, exp, s1, s2, top_level, caller_qname);
    }
    if absyn_pat_is_irrefutable(p1, s1) || absyn_pat_is_irrefutable(p2, s2) {
        return false;
    }
    let elems = |e: &Absyn::Exp| -> Option<Vec<Arc<Absyn::Exp>>> {
        match e {
            ARRAY { arrayExp } => Some((&**arrayExp).into_iter().cloned().collect()),
            LIST { exps } => Some((&**exps).into_iter().cloned().collect()),
            _ => None,
        }
    };
    match (p1, p2) {
        (CONS { head: h1, rest: r1 }, CONS { head: h2, rest: r2 }) =>
            pats_disjoint(h1, h2, s1, s2, top_level, caller_qname)
                || pats_disjoint(r1, r2, s1, s2, top_level, caller_qname),
        (TUPLE { expressions: e1 }, TUPLE { expressions: e2 }) => {
            let v1: Vec<&Arc<Absyn::Exp>> = (&**e1).into_iter().collect();
            let v2: Vec<&Arc<Absyn::Exp>> = (&**e2).into_iter().collect();
            v1.len() == v2.len()
                && v1.iter().zip(&v2).any(|(a, b)| pats_disjoint(a, b, s1, s2, top_level, caller_qname))
        }
        (CALL { function_: f1, functionArgs: a1, .. }, CALL { function_: f2, functionArgs: a2, .. }) => {
            let n1 = cref_to_dotted(f1);
            let n2 = cref_to_dotted(f2);
            if !same_constructor(&n1, &n2, top_level, caller_qname) {
                return true;
            }
            let (Absyn::FunctionArgs::FUNCTIONARGS { args: args1, argNames: names1 },
                 Absyn::FunctionArgs::FUNCTIONARGS { args: args2, argNames: names2 }) = (&**a1, &**a2)
                else { return false };
            // Named-field patterns list a subset of the fields, so a positional
            // comparison would pair up unrelated fields; compare field by name.
            let v1: Vec<&Arc<Absyn::Exp>> = (&**args1).into_iter().collect();
            let v2: Vec<&Arc<Absyn::Exp>> = (&**args2).into_iter().collect();
            let named1: BTreeMap<&str, &Arc<Absyn::Exp>> =
                (&**names1).into_iter().map(|n| (&*n.argName, &n.argValue)).collect();
            let named2: BTreeMap<&str, &Arc<Absyn::Exp>> =
                (&**names2).into_iter().map(|n| (&*n.argName, &n.argValue)).collect();
            (v1.len() == v2.len()
                && v1.iter().zip(&v2).any(|(a, b)| pats_disjoint(a, b, s1, s2, top_level, caller_qname)))
                || named1.iter().any(|(k, a)| named2.get(k)
                    .is_some_and(|b| pats_disjoint(a, b, s1, s2, top_level, caller_qname)))
        }
        (INTEGER { value: v1 }, INTEGER { value: v2 }) => v1 != v2,
        (BOOL { value: v1 }, BOOL { value: v2 }) => v1 != v2,
        (STRING { value: v1 }, STRING { value: v2 }) => v1 != v2,
        (REAL { value: v1 }, REAL { value: v2 }) => v1 != v2,
        _ => match (elems(p1), elems(p2)) {
            // Two list literals: disjoint on differing length, else element-wise.
            (Some(l1), Some(l2)) => l1.len() != l2.len()
                || l1.iter().zip(&l2).any(|(a, b)| pats_disjoint(a, b, s1, s2, top_level, caller_qname)),
            // `{}` matches only the empty list, which no `_ :: _` matches.
            (Some(l1), None) => l1.is_empty() && matches!(p2, CONS { .. }),
            (None, Some(l2)) => l2.is_empty() && matches!(p1, CONS { .. }),
            (None, None) => is_literal(p1) != is_literal(p2),
        },
    }
}

/// A constant pattern. Two unequal constants are handled above; a constant and a
/// structural pattern can never match the same value (mirrors the
/// `PAT_CONSTANT` arms of `Patternm.patternsDoNotOverlap`).
fn is_literal(e: &Absyn::Exp) -> bool {
    matches!(e, Absyn::Exp::INTEGER { .. } | Absyn::Exp::REAL { .. }
        | Absyn::Exp::STRING { .. } | Absyn::Exp::BOOL { .. })
}

/// Do two constructor names in pattern position denote the same constructor?
/// Names are compared after resolution, so `DAE.CREF` and an imported `CREF`
/// are recognised as one. An unresolvable name is assumed to be the same
/// constructor as anything it is compared against, which keeps the enclosing
/// patterns "overlapping".
fn same_constructor(
    n1: &str,
    n2: &str,
    top_level: &BTreeMap<String, NameNode<'_>>,
    caller_qname: &str,
) -> bool {
    if n1 == n2 {
        return true;
    }
    // `NONE`/`SOME` are builtins with no hierarchy node.
    let builtin = |n: &str| matches!(n.rsplit('.').next().unwrap_or(n), "NONE" | "SOME");
    if builtin(n1) || builtin(n2) {
        return n1.rsplit('.').next() == n2.rsplit('.').next();
    }
    match (resolve_call_node(n1, top_level, caller_qname), resolve_call_node(n2, top_level, caller_qname)) {
        (Some((q1, _)), Some((q2, _))) => q1 == q2,
        _ => true,
    }
}
