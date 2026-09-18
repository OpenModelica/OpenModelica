//! The render-ready facts about a class, read straight out of the Absyn AST.

use arcstr::ArcStr;
use metamodelica::Ref;
use openmodelica_ast::Absyn;
use openmodelica_frontend_dump::{AbsynUtil, Dump};

/// What a declaration is, which decides the table it is listed in.
#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Kind {
    Parameter,
    Constant,
    Input,
    Output,
    Variable,
}

pub struct Component {
    pub name: ArcStr,
    pub type_path: String,
    pub dims: String,
    pub default: String,
    pub description: String,
    /// `Dialog(tab=…, group=…)`, the heading rows the parameter table groups by.
    pub group: String,
    pub kind: Kind,
    pub protected: bool,
    /// Index of the type's class, once [`crate::resolve`] has run.
    pub type_class: Option<usize>,
}

/// A short class definition: `type Angle = Real(final unit="rad", …)`.
pub struct Derived {
    pub base: String,
    pub base_class: Option<usize>,
    pub dims: String,
    pub modifiers: Vec<Modifier>,
}

pub struct Modifier {
    pub name: String,
    pub value: String,
    pub is_final: bool,
}

pub struct EnumLiteral {
    pub name: ArcStr,
    pub description: String,
}

pub struct Extends {
    pub path: String,
    pub base: Option<usize>,
    /// How many of the class' own components were declared before this clause,
    /// so the inherited members can be listed where the `extends` stands.
    pub before: usize,
}

pub enum Import {
    /// `import A.B.C;` — binds `C`.
    Qualified(String),
    /// `import D = A.B.C;` — binds `D`.
    Named(String, String),
    /// `import A.B.*;` — binds everything under `A.B`.
    Unqualified(String),
}

/// One documented class. `children` indexes back into the arena holding it.
pub struct ClassDoc {
    pub path: Vec<ArcStr>,
    pub restriction: String,
    /// The description string as written. Usually plain text, but the
    /// specification makes one starting with `<html>` an HTML fragment, so
    /// rendering it is `html::description_html`'s job and reading it as text
    /// is `description_text`'s.
    pub comment: String,
    pub info: String,
    pub revisions: String,
    pub info_header: String,
    pub version: String,
    pub source_file: String,
    pub protected: bool,
    pub parent: Option<usize>,
    pub children: Vec<usize>,
    pub components: Vec<Component>,
    pub extends: Vec<Extends>,
    pub imports: Vec<Import>,
    pub is_function: bool,
    pub derived: Option<Derived>,
    pub enumeration: Vec<EnumLiteral>,
    /// `annotation(uses(Modelica(version="4.0.0")))` — the libraries this one
    /// needs before it can be instantiated.
    pub uses: Vec<(String, String)>,
}

impl ClassDoc {
    pub fn qualified_name(&self) -> String {
        self.path.join(".")
    }

    pub fn name(&self) -> &str {
        self.path.last().map(|s| s.as_str()).unwrap_or("")
    }
}

/// Every class in `program`, parents before children.
pub fn collect(program: &Absyn::Program) -> Vec<ClassDoc> {
    let mut arena = Vec::new();
    for class in &program.classes {
        collect_class(class, &[], false, None, &mut arena);
    }
    arena
}

fn collect_class(
    class: &Ref<Absyn::Class>,
    prefix: &[ArcStr],
    protected: bool,
    parent: Option<usize>,
    arena: &mut Vec<ClassDoc>,
) -> usize {
    let mut path = prefix.to_vec();
    path.push(class.name.clone());

    let (info, revisions, info_header) = documentation(class);
    let index = arena.len();
    arena.push(ClassDoc {
        path: path.clone(),
        restriction: Dump::unparseRestrictionStr(class.restriction.clone())
            .map(|s| s.to_string())
            .unwrap_or_default(),
        comment: openmodelica_util::System::unescapedString(
            AbsynUtil::classDefStringComment(class.body.clone()),
        )
        .to_string(),
        info,
        revisions,
        info_header,
        version: string_annotation(class, "version"),
        source_file: class.info.fileName.to_string(),
        protected,
        parent,
        children: Vec::new(),
        components: Vec::new(),
        extends: Vec::new(),
        imports: Vec::new(),
        is_function: matches!(class.restriction, Absyn::Restriction::R_FUNCTION { .. }),
        derived: derived(&class.body),
        enumeration: enumeration(&class.body),
        uses: if parent.is_none() { uses(class) } else { Vec::new() },
    });
    let (components, extends, imports) = declarations(class);
    arena[index].components = components;
    arena[index].extends = extends;
    arena[index].imports = imports;

    let mut children = Vec::new();
    for (nested, nested_protected) in nested_classes(class) {
        children.push(collect_class(&nested, &path, nested_protected, Some(index), arena));
    }
    arena[index].children = children;
    index
}

/// Paired with whether the declaration sits in a protected section.
fn nested_classes(class: &Ref<Absyn::Class>) -> Vec<(Ref<Absyn::Class>, bool)> {
    let mut out = Vec::new();
    for part in &AbsynUtil::getClassPartsInClass(class.clone()) {
        let (items, protected) = match &**part {
            Absyn::ClassPart::PUBLIC { contents } => (contents, false),
            Absyn::ClassPart::PROTECTED { contents } => (contents, true),
            _ => continue,
        };
        for item in items {
            let Absyn::ElementItem::ELEMENTITEM { element } = &**item else {
                continue;
            };
            let Absyn::Element::ELEMENT { specification, .. } = &**element else {
                continue;
            };
            if let Absyn::ElementSpec::CLASSDEF { class_, .. } = &**specification {
                out.push((class_.clone(), protected));
            }
        }
    }
    out
}

/// `annotation(Documentation(info=…, revisions=…, __OpenModelica_infoHeader=…))`.
fn documentation(class: &Ref<Absyn::Class>) -> (String, String, String) {
    let Ok(Some(modification)) =
        AbsynUtil::lookupClassAnnotation(class.clone(), arcstr::literal!("Documentation"))
    else {
        return (String::new(), String::new(), String::new());
    };
    let mut info = String::new();
    let mut revisions = String::new();
    let mut info_header = String::new();
    for arg in &modification.elementArgLst {
        let Some((name, exp)) = named_binding(arg) else {
            continue;
        };
        let slot = match name.as_str() {
            "info" => &mut info,
            "revisions" => &mut revisions,
            "__OpenModelica_infoHeader" => &mut info_header,
            _ => continue,
        };
        if let Some(s) = eval_string(&exp) {
            *slot = s;
        }
    }
    (info, revisions, info_header)
}

/// A top-level string annotation such as `annotation(version="4.1.0")`.
fn string_annotation(class: &Ref<Absyn::Class>, name: &str) -> String {
    let Ok(Some(annotation)) = AbsynUtil::getClassAnnotation(class.clone()) else {
        return String::new();
    };
    for arg in &annotation.elementArgs {
        if let Some((arg_name, exp)) = named_binding(arg)
            && arg_name == name
        {
            return eval_string(&exp).unwrap_or_default();
        }
    }
    String::new()
}

fn named_binding(arg: &Absyn::ElementArg) -> Option<(ArcStr, Ref<Absyn::Exp>)> {
    let Absyn::ElementArg::MODIFICATION {
        path, modification, ..
    } = arg
    else {
        return None;
    };
    let Absyn::Path::IDENT { name } = &**path else {
        return None;
    };
    let Absyn::EqMod::EQMOD { exp, .. } = &*modification.as_ref()?.eqMod else {
        return None;
    };
    Some((name.clone(), exp.clone()))
}

/// String literals and their concatenations. Anything else would need the class
/// instantiated, which a documentation string is not worth. Absyn keeps a
/// literal escaped, so this is also where `\"` becomes `"`.
fn eval_string(exp: &Absyn::Exp) -> Option<String> {
    match exp {
        Absyn::Exp::STRING { value } => {
            Some(openmodelica_util::System::unescapedString(value.clone()).to_string())
        }
        Absyn::Exp::BINARY {
            exp1,
            op: Absyn::Operator::ADD | Absyn::Operator::ADD_EW,
            exp2,
        } => Some(eval_string(exp1)? + &eval_string(exp2)?),
        Absyn::Exp::EXPRESSIONCOMMENT { exp, .. } => eval_string(exp),
        _ => None,
    }
}

/// The components, base classes and imports declared directly in `class`.
fn declarations(class: &Ref<Absyn::Class>) -> (Vec<Component>, Vec<Extends>, Vec<Import>) {
    let mut components = Vec::new();
    let mut extends = Vec::new();
    let mut imports = Vec::new();
    for part in &AbsynUtil::getClassPartsInClass(class.clone()) {
        let (items, protected) = match &**part {
            Absyn::ClassPart::PUBLIC { contents } => (contents, false),
            Absyn::ClassPart::PROTECTED { contents } => (contents, true),
            _ => continue,
        };
        for item in items {
            let Absyn::ElementItem::ELEMENTITEM { element } = &**item else {
                continue;
            };
            let Absyn::Element::ELEMENT { specification, .. } = &**element else {
                continue;
            };
            match &**specification {
                Absyn::ElementSpec::COMPONENTS {
                    attributes,
                    typeSpec,
                    components: items,
                } => {
                    for item in items {
                        components.push(component(attributes, typeSpec, item, protected));
                    }
                }
                Absyn::ElementSpec::EXTENDS { path, .. } => extends.push(Extends {
                    path: path_string(path),
                    base: None,
                    before: components.len(),
                }),
                Absyn::ElementSpec::IMPORT { import_, .. } => match import_ {
                    Absyn::Import::QUAL_IMPORT { path } => {
                        imports.push(Import::Qualified(path_string(path)))
                    }
                    Absyn::Import::NAMED_IMPORT { name, path } => {
                        imports.push(Import::Named(name.to_string(), path_string(path)))
                    }
                    Absyn::Import::UNQUAL_IMPORT { path } => {
                        imports.push(Import::Unqualified(path_string(path)))
                    }
                    Absyn::Import::GROUP_IMPORT { .. } => {}
                },
                Absyn::ElementSpec::CLASSDEF { .. } => {}
            }
        }
    }
    (components, extends, imports)
}

fn component(
    attributes: &Absyn::ElementAttributes,
    type_spec: &Ref<Absyn::TypeSpec>,
    item: &Ref<Absyn::ComponentItem>,
    protected: bool,
) -> Component {
    let kind = match (attributes.variability.clone(), attributes.direction.clone()) {
        (Absyn::Variability::PARAM, _) => Kind::Parameter,
        (Absyn::Variability::CONST, _) => Kind::Constant,
        (_, Absyn::Direction::INPUT) => Kind::Input,
        (_, Absyn::Direction::OUTPUT) => Kind::Output,
        _ => Kind::Variable,
    };
    let dims = Dump::printArraydimStr(item.component.arrayDim.clone())
        .or_else(|_| Dump::printArraydimStr(attributes.arrayDim.clone()))
        .map(|s| s.to_string())
        .unwrap_or_default();
    Component {
        name: item.component.name.clone(),
        type_path: Dump::unparseTypeSpec(type_spec.clone())
            .map(|s| s.to_string())
            .unwrap_or_default(),
        dims: if dims == "[]" { String::new() } else { dims },
        default: binding(item.component.modification.as_ref()),
        description: item
            .comment
            .as_ref()
            .and_then(|c| c.comment.clone())
            .map(|c| openmodelica_util::System::unescapedString(c).to_string())
            .unwrap_or_default(),
        group: dialog_group(item.comment.as_ref()),
        kind,
        protected,
        type_class: None,
    }
}

/// The `= value` of a declaration, or the whole modification when there is no
/// binding equation (`Dialog(…)`-style class modifiers are not shown).
fn binding(modification: Option<&Ref<Absyn::Modification>>) -> String {
    let Some(modification) = modification else {
        return String::new();
    };
    if let Absyn::EqMod::EQMOD { exp, .. } = &*modification.eqMod {
        return Dump::printExpStr(exp.clone())
            .map(|s| s.to_string())
            .unwrap_or_default();
    }
    String::new()
}

/// `annotation(Dialog(tab=…, group=…))`, joined as the parameter table heading.
fn dialog_group(comment: Option<&Ref<Absyn::Comment>>) -> String {
    let Some(annotation) = comment.and_then(|c| c.annotation_.as_ref()) else {
        return String::new();
    };
    for arg in &annotation.elementArgs {
        let Absyn::ElementArg::MODIFICATION {
            path, modification, ..
        } = &**arg
        else {
            continue;
        };
        let Absyn::Path::IDENT { name } = &**path else {
            continue;
        };
        if name != "Dialog" {
            continue;
        }
        let Some(modification) = modification else {
            continue;
        };
        let mut tab = String::new();
        let mut group = String::new();
        for arg in &modification.elementArgLst {
            if let Some((name, exp)) = named_binding(arg)
                && let Some(value) = eval_string(&exp)
            {
                match name.as_str() {
                    "tab" => tab = value,
                    "group" => group = value,
                    _ => {}
                }
            }
        }
        return match (tab.is_empty(), group.is_empty()) {
            (true, true) => String::new(),
            (true, false) => group,
            (false, true) => tab,
            (false, false) => format!("{tab} \u{203a} {group}"),
        };
    }
    String::new()
}

fn path_string(path: &Ref<Absyn::Path>) -> String {
    AbsynUtil::pathString(path.clone(), arcstr::literal!("."), false, false)
        .map(|s| s.to_string())
        .unwrap_or_default()
}

/// One row of a member table: a declaration, and the base class it came from.
pub struct Member<'a> {
    pub component: &'a Component,
    pub inherited_from: Option<usize>,
}

/// Every member of `class`, its base classes' included, in declaration order
/// with each `extends` expanded where it stands — which is the order the
/// Modelica documentation has always listed them in. The first declaration of a
/// name wins, so a redeclaration hides what it replaces.
pub fn members(classes: &[ClassDoc], class: usize) -> Vec<Member<'_>> {
    let mut out = Vec::new();
    let mut seen = std::collections::HashSet::new();
    let mut visited = std::collections::HashSet::new();
    gather(classes, class, None, &mut out, &mut seen, &mut visited);
    out
}

fn gather<'a>(
    classes: &'a [ClassDoc],
    class: usize,
    from: Option<usize>,
    out: &mut Vec<Member<'a>>,
    seen: &mut std::collections::HashSet<ArcStr>,
    visited: &mut std::collections::HashSet<usize>,
) {
    if !visited.insert(class) {
        return;
    }
    let doc = &classes[class];
    let mut next = 0;
    for extends in &doc.extends {
        for component in &doc.components[next..extends.before] {
            push(out, seen, component, from);
        }
        next = extends.before;
        if let Some(base) = extends.base {
            gather(classes, base, Some(base), out, seen, visited);
        }
    }
    for component in &doc.components[next..] {
        push(out, seen, component, from);
    }
}

fn push<'a>(
    out: &mut Vec<Member<'a>>,
    seen: &mut std::collections::HashSet<ArcStr>,
    component: &'a Component,
    from: Option<usize>,
) {
    if seen.insert(component.name.clone()) {
        out.push(Member {
            component,
            inherited_from: from,
        });
    }
}

fn derived(body: &Ref<Absyn::ClassDef>) -> Option<Derived> {
    let Absyn::ClassDef::DERIVED {
        typeSpec,
        arguments,
        ..
    } = &**body
    else {
        return None;
    };
    let printed = Dump::unparseTypeSpec(typeSpec.clone())
        .map(|s| s.to_string())
        .unwrap_or_default();
    let (base, dims) = match printed.split_once('[') {
        Some((base, dims)) => (base.to_string(), format!("[{dims}")),
        None => (printed, String::new()),
    };
    let mut modifiers = Vec::new();
    for arg in arguments {
        let Absyn::ElementArg::MODIFICATION {
            finalPrefix, path, ..
        } = &**arg
        else {
            continue;
        };
        let Some((name, exp)) = named_binding(arg) else {
            // A submodifier without a binding, e.g. `Real(x(unit="m"))`.
            modifiers.push(Modifier {
                name: path_string(path),
                value: String::new(),
                is_final: *finalPrefix,
            });
            continue;
        };
        modifiers.push(Modifier {
            name: name.to_string(),
            value: Dump::printExpStr(exp)
                .map(|s| s.to_string())
                .unwrap_or_default(),
            is_final: *finalPrefix,
        });
    }
    Some(Derived {
        base,
        base_class: None,
        dims,
        modifiers,
    })
}

fn enumeration(body: &Ref<Absyn::ClassDef>) -> Vec<EnumLiteral> {
    let Absyn::ClassDef::ENUMERATION { enumLiterals, .. } = &**body else {
        return Vec::new();
    };
    let Absyn::EnumDef::ENUMLITERALS { enumLiterals } = &**enumLiterals else {
        return Vec::new();
    };
    enumLiterals
        .into_iter()
        .map(|literal| EnumLiteral {
            name: literal.literal.clone(),
            description: literal
                .comment
                .as_ref()
                .and_then(|c| c.comment.clone())
                .map(|c| openmodelica_util::System::unescapedString(c).to_string())
                .unwrap_or_default(),
        })
        .collect()
}

/// The `uses` annotation, as (library, version) pairs.
pub fn uses_of(class: &Ref<Absyn::Class>) -> Vec<(String, String)> {
    uses(class)
}

fn uses(class: &Ref<Absyn::Class>) -> Vec<(String, String)> {
    let Ok(Some(modification)) =
        AbsynUtil::lookupClassAnnotation(class.clone(), arcstr::literal!("uses"))
    else {
        return Vec::new();
    };
    let mut out = Vec::new();
    for arg in &modification.elementArgLst {
        let Absyn::ElementArg::MODIFICATION {
            path, modification, ..
        } = &**arg
        else {
            continue;
        };
        let Absyn::Path::IDENT { name } = &**path else {
            continue;
        };
        let mut version = String::new();
        if let Some(modification) = modification {
            for arg in &modification.elementArgLst {
                if let Some((key, exp)) = named_binding(arg)
                    && key == "version"
                {
                    version = eval_string(&exp).unwrap_or_default();
                }
            }
        }
        out.push((name.to_string(), version));
    }
    out
}

/// A description string as readable text, for the places that cannot show
/// markup: the sidebar, the search index, JSON attributes. Tags go, the few
/// entities a description realistically carries are decoded, and runs of
/// whitespace collapse to one space.
pub fn description_text(raw: &str) -> String {
    if !raw.contains('<') && !raw.contains('&') {
        return raw.to_string();
    }
    let mut out = String::with_capacity(raw.len());
    let mut rest = raw;
    while let Some(at) = rest.find('<') {
        out.push_str(&rest[..at]);
        match rest[at..].find('>') {
            Some(end) => rest = &rest[at + end + 1..],
            None => {
                rest = "";
                break;
            }
        }
    }
    out.push_str(rest);
    for (entity, text) in [
        ("&nbsp;", " "),
        ("&copy;", "\u{a9}"),
        ("&quot;", "\""),
        ("&lt;", "<"),
        ("&gt;", ">"),
        ("&amp;", "&"),
    ] {
        if out.contains(entity) {
            out = out.replace(entity, text);
        }
    }
    out.split_whitespace().collect::<Vec<_>>().join(" ")
}
