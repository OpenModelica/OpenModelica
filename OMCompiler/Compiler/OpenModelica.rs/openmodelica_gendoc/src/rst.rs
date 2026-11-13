//! The scripting API chapter of the User's Guide, as reST.

use std::collections::{BTreeMap, HashMap};
use std::path::Path;

use metamodelica::Ref;
use openmodelica_ast::Absyn;
use openmodelica_frontend_dump::{AbsynUtil, Dump};

use crate::doc;

const PACKAGE: &str = "OpenModelica.Scripting.";

type Classes = HashMap<String, Ref<Absyn::Class>>;

struct Documented {
    name: String,
    comment: String,
    info: String,
}

struct Section {
    class: Documented,
    inherited: Vec<Documented>,
    listing: String,
}

/// Writes `dir/interface.inc` for every public function in
/// `OpenModelica.Scripting` that is not internal, partial or deprecated, and
/// the HTML documentation of each in `dir/interface/<class>.html`, which the
/// guide converts to the `<class>.inc` that `interface.inc` includes.
pub fn scripting_api(program: &Absyn::Program, dir: &Path) -> Result<(), String> {
    let mut classes = Classes::new();
    let mut public = Vec::new();
    for class in &program.classes {
        walk(class, "", true, &mut classes, &mut public);
    }
    public.retain(|name| name.starts_with(PACKAGE));
    public.sort();

    let mut out = String::new();
    let mut info = BTreeMap::new();
    for section in public.iter().filter_map(|name| section(name, &classes)) {
        out.push_str(&render(&section));
        for class in std::iter::once(&section.class).chain(&section.inherited) {
            if !class.info.is_empty() {
                info.insert(class.name.clone(), class.info.clone());
            }
        }
    }
    let write = |path: &Path, text: &str| std::fs::write(path, text).map_err(|e| format!("{}: {e}", path.display()));
    let info_dir = dir.join("interface");
    std::fs::create_dir_all(&info_dir).map_err(|e| format!("{}: {e}", info_dir.display()))?;
    for (name, html) in &info {
        write(&info_dir.join(format!("{name}.html")), html)?;
    }
    write(&dir.join("interface.inc"), &out)
}

fn walk(class: &Ref<Absyn::Class>, prefix: &str, public: bool, classes: &mut Classes, listed: &mut Vec<String>) {
    let name = match prefix {
        "" => class.name.to_string(),
        _ => format!("{prefix}.{}", class.name),
    };
    for (nested, protected) in doc::nested_classes(class) {
        walk(&nested, &name, public && !protected, classes, listed);
    }
    if public {
        listed.push(name.clone());
    }
    classes.insert(name, class.clone());
}

fn section(name: &str, classes: &Classes) -> Option<Section> {
    let class = &classes[name];
    let documented = matches!(class.restriction, Absyn::Restriction::R_FUNCTION { .. })
        && !class.partialPrefix
        && doc::string_annotation(class, "version") != "Deprecated"
        && !name.contains("Internal");
    if !documented {
        return None;
    }
    let mut bases = Vec::new();
    let listing = interface(name, class, classes, &mut bases, 0)
        .and_then(|interface| {
            let program = Absyn::Program {
                classes: std::iter::once(interface).collect(),
                within_: Absyn::Within::TOP,
            };
            Dump::unparseStr(program, false, Dump::defaultDumpOptions.clone()).ok()
        })
        .map(|s| s.to_string())
        .unwrap_or_default();
    Some(Section {
        class: documented_class(name, class),
        inherited: bases
            .iter()
            .map(|base| documented_class(base, &classes[base]))
            .collect(),
        listing,
    })
}

fn documented_class(name: &str, class: &Ref<Absyn::Class>) -> Documented {
    Documented {
        name: name.to_string(),
        comment: openmodelica_util::System::unescapedString(AbsynUtil::classDefStringComment(&class.body)).to_string(),
        info: doc::documentation(class).0,
    }
}

/// What `list(name, interfaceOnly=true)` prints, with each `extends` replaced
/// by the interface of its base class.
fn interface(
    name: &str,
    class: &Ref<Absyn::Class>,
    classes: &Classes,
    bases: &mut Vec<String>,
    depth: usize,
) -> Option<Ref<Absyn::Class>> {
    let own = AbsynUtil::getFunctionInterface(class.clone()).ok()?;
    let Absyn::ClassDef::PARTS {
        typeVars,
        classAttrs,
        ann,
        comment,
        ..
    } = &*own.body
    else {
        return Some(own);
    };
    let mut contents = Vec::new();
    for item in public_items(&own) {
        let inherited = base_class(name, &item, classes)
            .filter(|_| depth < 16)
            .and_then(|base| Some((interface(&base, &classes[&base], classes, bases, depth + 1)?, base)));
        match inherited {
            Some((inherited, base)) => {
                contents.extend(public_items(&inherited));
                if !bases.contains(&base) {
                    bases.push(base);
                }
            }
            None => contents.push(item),
        }
    }
    let mut expanded = (*own).clone();
    expanded.body = Ref::new(Absyn::ClassDef::PARTS {
        typeVars: typeVars.clone(),
        classAttrs: classAttrs.clone(),
        classParts: std::iter::once(Ref::new(Absyn::ClassPart::PUBLIC {
            contents: contents.into_iter().collect(),
        }))
        .collect(),
        ann: ann.clone(),
        comment: comment.clone(),
    });
    Some(Ref::new(expanded))
}

fn public_items(class: &Absyn::Class) -> Vec<Ref<Absyn::ElementItem>> {
    let Absyn::ClassDef::PARTS { classParts, .. } = &*class.body else {
        return Vec::new();
    };
    classParts
        .iter()
        .flat_map(|part| match &**part {
            Absyn::ClassPart::PUBLIC { contents } => contents.iter().cloned().collect(),
            _ => Vec::new(),
        })
        .collect()
}

/// The class an `extends` without modifiers names, looked up outwards from
/// the scope of `name`.
fn base_class(name: &str, item: &Absyn::ElementItem, classes: &Classes) -> Option<String> {
    let Absyn::ElementItem::ELEMENTITEM { element } = item else {
        return None;
    };
    let Absyn::Element::ELEMENT { specification, .. } = &**element else {
        return None;
    };
    let Absyn::ElementSpec::EXTENDS { path, elementArg, .. } = &**specification else {
        return None;
    };
    let path = AbsynUtil::pathString(path.clone(), arcstr::literal!("."), false, false).ok()?;
    if !elementArg.is_empty() {
        eprintln!("omgendoc: {name}: extends {path} has modifiers and is not expanded");
        return None;
    }
    let mut scope = Some(name);
    while let Some(s) = scope {
        let candidate = format!("{s}.{path}");
        if classes.contains_key(&candidate) {
            return Some(candidate);
        }
        scope = s.rfind('.').map(|i| &s[..i]);
    }
    if classes.contains_key(path.as_str()) {
        return Some(path.to_string());
    }
    eprintln!("omgendoc: {name}: base class {path} not found");
    None
}

fn render(section: &Section) -> String {
    let name = section.class.name.rsplit('.').next().unwrap_or_default();
    let mut out = format!("\n.. _{name} :\n\n{name}\n{}\n", "^".repeat(name.len()));
    for class in std::iter::once(&section.class).chain(&section.inherited) {
        push_comment(&mut out, &class.comment);
        if !class.info.is_empty() {
            out.push_str(&format!("\n.. include :: interface/{}.inc\n", class.name));
        }
    }
    if !section.listing.is_empty() {
        // Pygments' Modelica lexer rejects OpenModelica's $Code() default values.
        let language = if section.listing.contains('$') {
            "text"
        } else {
            "modelica"
        };
        out.push_str(&format!("\n.. code-block :: {language}\n\n"));
        for line in section.listing.split('\n').filter(|l| !l.is_empty()) {
            out.push_str("  ");
            out.push_str(line);
            out.push('\n');
        }
        out.push_str("  \n");
    }
    out
}

fn push_comment(out: &mut String, comment: &str) {
    let lines: String = comment
        .split('\n')
        .filter(|l| !l.is_empty())
        .map(|l| format!("{}\n", l.trim_start_matches(' ')))
        .collect();
    if !lines.is_empty() {
        out.push_str("\n\n");
        out.push_str(&lines);
        out.push('\n');
    }
}
