//! Per-target declaration overrides.
//!
//! A file `X.rust.mo` next to `X.mo` declares the items the Rust port
//! represents differently from the C compiler: a record field whose
//! representation differs, and the accessors that go with it. It is spliced
//! into the parsed AST *before* any analysis, so fallibility, recursion,
//! traced types and the generated code all see the Rust view, while the C
//! compiler only ever reads `X.mo`.
//!
//! Matching is by name and recurses through packages and uniontypes, so an
//! override restates one record or one function rather than a whole file. A
//! name the base does not have is appended.

use openmodelica_ast::Absyn;
use metamodelica::{cons, nil, List, Ref};

/// The name an element declares, if it declares exactly one.
fn element_name(e: &Absyn::Element) -> Option<String> {
    let Absyn::Element::ELEMENT { specification, .. } = e else { return None };
    match &**specification {
        Absyn::ElementSpec::CLASSDEF { class_, .. } => Some(class_.name.to_string()),
        Absyn::ElementSpec::COMPONENTS { components, .. } => {
            let mut it = components.iter();
            let first = it.next()?;
            // A single `Type name;` declaration; a multi-name one is ambiguous
            // to match on, so leave it to be appended rather than replace.
            if it.next().is_some() { None } else { Some(first.component.name.to_string()) }
        }
        _ => None,
    }
}

fn item_name(i: &Absyn::ElementItem) -> Option<String> {
    match i {
        Absyn::ElementItem::ELEMENTITEM { element } => element_name(element),
        _ => None,
    }
}

fn as_class(i: &Absyn::ElementItem) -> Option<&Absyn::Class> {
    let Absyn::ElementItem::ELEMENTITEM { element } = i else { return None };
    let Absyn::Element::ELEMENT { specification, .. } = &**element else { return None };
    match &**specification {
        Absyn::ElementSpec::CLASSDEF { class_, .. } => Some(class_),
        _ => None,
    }
}

/// Rebuild `item` with `class_` swapped in, keeping every other field.
fn with_class(item: &Absyn::ElementItem, class_: Absyn::Class) -> Absyn::ElementItem {
    let Absyn::ElementItem::ELEMENTITEM { element } = item else { return item.clone() };
    let Absyn::Element::ELEMENT { finalPrefix, redeclareKeywords, innerOuter, specification, info, constrainClass } = &**element
    else { return item.clone() };
    let replaceable_ = match &**specification {
        Absyn::ElementSpec::CLASSDEF { replaceable_, .. } => *replaceable_,
        _ => false,
    };
    Absyn::ElementItem::ELEMENTITEM {
        element: Ref::new(Absyn::Element::ELEMENT {
            finalPrefix: *finalPrefix,
            redeclareKeywords: redeclareKeywords.clone(),
            innerOuter: innerOuter.clone(),
            specification: Ref::new(Absyn::ElementSpec::CLASSDEF { replaceable_, class_: Ref::new(class_) }),
            info: info.clone(),
            constrainClass: constrainClass.clone(),
        }),
    }
}

/// Merge one class part. `used` is shared across the parts of a class, so an
/// override item lands exactly once however many parts the base has, and
/// `append_rest` is set only for the part that collects the leftovers.
fn merge_items(base: &List<Ref<Absyn::ElementItem>>, ovr_items: &[Ref<Absyn::ElementItem>],
               used: &mut [bool], append_rest: bool, applied: &mut Vec<String>)
    -> List<Ref<Absyn::ElementItem>>
{
    let mut out: Vec<Ref<Absyn::ElementItem>> = Vec::new();
    for b in base.iter() {
        let bname = item_name(b);
        let mut replaced = false;
        if let Some(bn) = &bname {
            for (k, o) in ovr_items.iter().enumerate() {
                if used[k] || item_name(o).as_ref() != Some(bn) { continue; }
                used[k] = true;
                replaced = true;
                match (as_class(b), as_class(o)) {
                    (Some(bc), Some(oc)) => {
                        let merged = merge_class(bc, oc, applied);
                        out.push(Ref::new(with_class(o, merged)));
                    }
                    _ => {
                        applied.push(bn.clone());
                        out.push(o.clone());
                    }
                }
                break;
            }
        }
        if !replaced { out.push(b.clone()); }
    }
    if append_rest {
        for (k, o) in ovr_items.iter().enumerate() {
            if !used[k] {
                used[k] = true;
                if let Some(n) = item_name(o) { applied.push(format!("+{n}")); }
                out.push(o.clone());
            }
        }
    }

    let mut list = nil();
    for x in out.into_iter().rev() { list = cons(x, list); }
    list
}

/// Only a container is merged item by item. Anything else -- a function, a
/// record -- is replaced whole: merging a function would keep the base's
/// algorithm section under the override's declarations.
fn is_container(c: &Absyn::Class) -> bool {
    matches!(&*c.body, Absyn::ClassDef::PARTS { .. })
        && matches!(c.restriction,
            Absyn::Restriction::R_PACKAGE | Absyn::Restriction::R_UNIONTYPE | Absyn::Restriction::R_CLASS)
}

fn merge_class(base: &Absyn::Class, ovr: &Absyn::Class, applied: &mut Vec<String>) -> Absyn::Class {
    if !is_container(base) || !is_container(ovr) {
        applied.push(base.name.to_string());
        return ovr.clone();
    }
    let (Absyn::ClassDef::PARTS { typeVars, classAttrs, classParts: b_parts, ann, comment },
         Absyn::ClassDef::PARTS { classParts: o_parts, .. }) = (&*base.body, &*ovr.body)
    else { unreachable!() };

    let o_items: Vec<Ref<Absyn::ElementItem>> = o_parts.iter().flat_map(|p| match &**p {
        Absyn::ClassPart::PUBLIC { contents } | Absyn::ClassPart::PROTECTED { contents } =>
            contents.iter().cloned().collect::<Vec<_>>(),
        _ => Vec::new(),
    }).collect();
    let mut used = vec![false; o_items.len()];

    // Leftovers go to the last part that can hold elements.
    let last_mergeable = b_parts.iter().enumerate().filter(|(_, p)| matches!(&***p,
        Absyn::ClassPart::PUBLIC { .. } | Absyn::ClassPart::PROTECTED { .. })).map(|(i, _)| i).last();

    let mut new_parts = Vec::new();
    for (i, p) in b_parts.iter().enumerate() {
        let rest = Some(i) == last_mergeable;
        let np = match &**p {
            Absyn::ClassPart::PUBLIC { contents } =>
                Absyn::ClassPart::PUBLIC { contents: merge_items(contents, &o_items, &mut used, rest, applied) },
            Absyn::ClassPart::PROTECTED { contents } =>
                Absyn::ClassPart::PROTECTED { contents: merge_items(contents, &o_items, &mut used, rest, applied) },
            other => other.clone(),
        };
        new_parts.push(Ref::new(np));
    }
    let mut parts = nil();
    for x in new_parts.into_iter().rev() { parts = cons(x, parts); }

    let mut c = base.clone();
    c.body = Ref::new(Absyn::ClassDef::PARTS {
        typeVars: typeVars.clone(), classAttrs: classAttrs.clone(),
        classParts: parts, ann: ann.clone(), comment: comment.clone(),
    });
    c
}

/// Splice `ovr` onto `base`, returning the names of the items replaced.
pub fn apply(base: &mut Absyn::Program, ovr: &Absyn::Program) -> Vec<String> {
    let mut applied = Vec::new();
    let o_classes: Vec<Ref<Absyn::Class>> = ovr.classes.iter().cloned().collect();

    let mut out: Vec<Ref<Absyn::Class>> = Vec::new();
    for b in base.classes.iter() {
        let mut merged = None;
        for o in &o_classes {
            if o.name == b.name { merged = Some(merge_class(b, o, &mut applied)); break; }
        }
        out.push(match merged { Some(c) => Ref::new(c), None => b.clone() });
    }
    let mut list = nil();
    for x in out.into_iter().rev() { list = cons(x, list); }
    base.classes = list;
    applied
}
