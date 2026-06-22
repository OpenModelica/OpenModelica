//! `scripting_api_gen <ModelicaBuiltin.mo> <out OpenModelicaScriptingAPI.mo>`
//!
//! Reproduces `OpenModelica.Scripting.generateScriptingAPI` (CevalScript.mo) +
//! GenerateAPIFunctionsTpl.tpl, but at the Absyn level with no frontend `Lookup`
//! and no Tpl runtime — the per-function MetaModelica is emitted directly.
//!
//! For every direct `external "builtin"` function of `OpenModelica.Scripting`
//! whose inputs and outputs are all "simple" (Integer/Real/Boolean/String/
//! TypeName/arrays of those; see `CevalScript.isSimpleAPIFunctionArg`), we emit a
//! thin wrapper that forwards to `CevalScript.cevalInteractiveFunctions2`. The
//! functions are emitted in reverse source order, matching omc (which prepends to
//! its `tys` list). The two `stringReplace`s from OpenModelicaScriptingAPI.mos are
//! applied at the end.

use std::sync::Arc;

use openmodelica_ast::Absyn::{Class, ClassDef, ClassPart, Direction, Element, ElementItem, ElementSpec, EqMod, Exp, Modification, Path, Restriction, TypeSpec};
use openmodelica_ast::parser::{Grammar, parse};

/// A "simple API" type, as accepted by `isSimpleAPIFunctionArg`.
#[derive(Clone)]
enum STy {
    Int,
    Real,
    Bool,
    Str,
    /// `TypeName` → `DAE.T_CODE(C_TYPENAME)`.
    TypeName,
    /// One array dimension (`DAE.T_ARRAY`); nests for multi-dim.
    Arr(Box<STy>),
}

impl STy {
    /// `getInType`: the MetaModelica type written in the wrapper signature.
    fn in_type(&self) -> String {
        match self {
            STy::Str | STy::TypeName => "String".to_owned(),
            STy::Int => "Integer".to_owned(),
            STy::Bool => "Boolean".to_owned(),
            STy::Real => "Real".to_owned(),
            STy::Arr(t) => format!("list<{}>", t.in_type()),
        }
    }

    /// `getInValue`: the `Values.*` expression for an input argument.
    fn in_value(&self, name: &str) -> String {
        match self {
            STy::Str => format!("Values.STRING({name})"),
            STy::Int => format!("Values.INTEGER({name})"),
            STy::Bool => format!("Values.BOOL({name})"),
            STy::Real => format!("Values.REAL({name})"),
            STy::TypeName => format!("Values.CODE(Absyn.C_TYPENAME(Parser.stringPath({name})))"),
            STy::Arr(t) => format!(
                "ValuesUtil.makeArray(list({} for {name}_iter in {name}))",
                t.in_value(&format!("{name}_iter"))
            ),
        }
    }

    /// `getOutValue`: the `Values.*` pattern matched for an output, possibly
    /// appending a protected declaration and a post-match assignment.
    fn out_value(&self, name: &str, var_decl: &mut String, post_match: &mut String) -> String {
        match self {
            STy::Str => format!("Values.STRING({name})"),
            STy::Int => format!("Values.INTEGER({name})"),
            STy::Bool => format!("Values.BOOL({name})"),
            STy::Real => format!("Values.REAL({name})"),
            STy::Arr(_) => {
                var_decl.push_str(&format!("Values.Value {name}_arr;\n"));
                post_match.push_str(&format!("{name} := {};\n", self.out_value_array(&format!("{name}_arr"))));
                format!("{name}_arr")
            }
            STy::TypeName => {
                var_decl.push_str(&format!("Absyn.Path {name}_path;\n"));
                post_match.push_str(&format!("{name} := AbsynUtil.pathString({name}_path);\n"));
                format!("Values.CODE(Absyn.C_TYPENAME(path={name}_path))")
            }
        }
    }

    /// `getOutValueArray`: element extraction for an array-typed output.
    fn out_value_array(&self, name: &str) -> String {
        match self {
            STy::Str => format!("match {name} case Values.STRING() then {name}.string; end match"),
            STy::Int => format!("match {name} case Values.INTEGER() then {name}.integer; end match"),
            STy::Bool => format!("match {name} case Values.BOOL() then {name}.boolean; end match"),
            STy::Real => format!("match {name} case Values.REAL() then {name}.real; end match"),
            STy::Arr(t) => format!(
                "list({} for {name}_iter in ValuesUtil.arrayValues({name}))",
                t.out_value_array(&format!("{name}_iter"))
            ),
            STy::TypeName => format!("ValuesUtil.valString({name})"),
        }
    }
}

/// A collected simple-API function: name, ordered inputs, ordered outputs.
struct Func {
    name: String,
    inputs: Vec<(String, STy)>,
    outputs: Vec<(String, STy)>,
}

fn last_ident(p: &Path) -> &str {
    match p {
        Path::IDENT { name } => name,
        Path::QUALIFIED { path, .. } => last_ident(path),
        Path::FULLYQUALIFIED { path } => last_ident(path),
    }
}

/// Map a `TypeSpec` (+ extra array dims from the component / attributes) to a
/// simple type, or `None` if it is not a simple-API type.
fn simple_ty(ts: &TypeSpec, extra_dims: usize) -> Option<STy> {
    let (path, ts_dims) = match ts {
        TypeSpec::TPATH { path, arrayDim } => (path, arrayDim.as_ref().map_or(0, |d| d.len() as usize)),
        // TCOMPLEX (e.g. `list<...>`) is never a simple-API arg.
        _ => return None,
    };
    let mut base = match last_ident(path) {
        "Integer" => STy::Int,
        "Real" => STy::Real,
        "Boolean" => STy::Bool,
        "String" => STy::Str,
        "TypeName" => STy::TypeName,
        _ => return None,
    };
    for _ in 0..(ts_dims + extra_dims) {
        base = STy::Arr(Box::new(base));
    }
    Some(base)
}

/// Whether a parameter's default binding is type-compatible with its declared
/// (scalar) simple type. omc elaborates each function with `Lookup.lookupType`;
/// a type-mismatched default (e.g. the `Real startTime = "<default>"` idiom on
/// the simulation functions) makes that lookup FAIL, so the function falls
/// through `generateScriptingAPI`'s `else` and is silently dropped. We replicate
/// that here: a simple-literal default whose type does not match the scalar
/// parameter excludes the function. Non-literal defaults and non-scalar params
/// are not judged (left in).
fn default_ok(modif: &Option<Arc<Modification>>, ty: &STy) -> bool {
    let Some(m) = modif else { return true };
    let EqMod::EQMOD { exp, .. } = &*m.eqMod else { return true };
    match (&**exp, ty) {
        (Exp::STRING { .. }, STy::Str) => true,
        (Exp::INTEGER { .. }, STy::Int | STy::Real) => true,
        (Exp::REAL { .. }, STy::Real) => true,
        (Exp::BOOL { .. }, STy::Bool) => true,
        // A literal default of the wrong type on a scalar param → Lookup fails.
        (
            Exp::STRING { .. } | Exp::INTEGER { .. } | Exp::REAL { .. } | Exp::BOOL { .. },
            STy::Int | STy::Real | STy::Bool | STy::Str,
        ) => false,
        // Non-literal default, or non-scalar param: not judged.
        _ => true,
    }
}

/// Direct sub-classes (CLASSDEF elements) of a package, in source order.
fn sub_classes(c: &Class) -> Vec<Arc<Class>> {
    let mut out = Vec::new();
    if let ClassDef::PARTS { classParts, .. } = &*c.body {
        for part in &**classParts {
            let contents = match &**part {
                ClassPart::PUBLIC { contents } | ClassPart::PROTECTED { contents } => contents,
                _ => continue,
            };
            for item in &**contents {
                if let ElementItem::ELEMENTITEM { element } = &**item {
                    if let Element::ELEMENT { specification, .. } = &**element {
                        if let ElementSpec::CLASSDEF { class_, .. } = &**specification {
                            out.push(class_.clone());
                        }
                    }
                }
            }
        }
    }
    out
}

fn find_class(classes: &[Arc<Class>], name: &str) -> Option<Arc<Class>> {
    classes.iter().find(|c| c.name.as_str() == name).cloned()
}

/// Whether the class is `external "builtin"`.
fn is_external_builtin(c: &Class) -> bool {
    if let ClassDef::PARTS { classParts, .. } = &*c.body {
        for part in &**classParts {
            if let ClassPart::EXTERNAL { externalDecl, .. } = &**part {
                return externalDecl.lang.as_deref() == Some("builtin");
            }
        }
    }
    false
}

/// Extract a simple-API function, or `None` if it does not qualify.
fn collect_func(c: &Class) -> Option<Func> {
    if !matches!(c.restriction, Restriction::R_FUNCTION { .. }) || c.partialPrefix {
        return None;
    }
    if !is_external_builtin(c) {
        return None;
    }
    let ClassDef::PARTS { classParts, .. } = &*c.body else { return None };
    let mut inputs = Vec::new();
    let mut outputs = Vec::new();
    for part in &**classParts {
        let contents = match &**part {
            ClassPart::PUBLIC { contents } | ClassPart::PROTECTED { contents } => contents,
            _ => continue,
        };
        for item in &**contents {
            let ElementItem::ELEMENTITEM { element } = &**item else { continue };
            let Element::ELEMENT { specification, .. } = &**element else { continue };
            let ElementSpec::COMPONENTS { attributes, typeSpec, components } = &**specification else { continue };
            let dst = match attributes.direction {
                Direction::INPUT => &mut inputs,
                Direction::OUTPUT => &mut outputs,
                _ => continue, // local protected vars etc. are not part of the signature
            };
            let attr_dims = attributes.arrayDim.len() as usize;
            for comp in &**components {
                let comp_dims = comp.component.arrayDim.len() as usize;
                let ty = simple_ty(typeSpec, attr_dims + comp_dims)?; // any non-simple arg disqualifies
                // A type-mismatched default makes omc's Lookup fail → drop the function.
                if !default_ok(&comp.component.modification, &ty) {
                    return None;
                }
                dst.push((comp.component.name.to_string(), ty));
            }
        }
    }
    Some(Func { name: c.name.to_string(), inputs, outputs })
}

/// Emit one wrapper function (`getCevalScriptInterfaceFunc`).
fn emit_func(f: &Func) -> String {
    let mut var_decl = String::new();
    let mut post_match = String::new();
    let in_vals = f.inputs.iter().map(|(n, t)| t.in_value(n)).collect::<Vec<_>>().join(", ");

    let out_vals = match f.outputs.len() {
        0 => "Values.NORETCALL()".to_owned(),
        1 => f.outputs[0].1.out_value("res", &mut var_decl, &mut post_match),
        _ => {
            let parts = f
                .outputs
                .iter()
                .enumerate()
                .map(|(i, (_, t))| t.out_value(&format!("res{}", i + 1), &mut var_decl, &mut post_match))
                .collect::<Vec<_>>()
                .join(", ");
            format!("Values.TUPLE({{{parts}}})")
        }
    };

    let mut s = format!("function {}\n", f.name);
    for (n, t) in &f.inputs {
        s.push_str(&format!("  input {} {};\n", t.in_type(), n));
    }
    match f.outputs.len() {
        0 => {}
        1 => s.push_str(&format!("  output {} res;\n", f.outputs[0].1.in_type())),
        _ => {
            for (i, (_, t)) in f.outputs.iter().enumerate() {
                s.push_str(&format!("  output {} res{};\n", t.in_type(), i + 1));
            }
        }
    }
    if !var_decl.is_empty() {
        s.push_str("protected\n");
        for line in var_decl.lines() {
            s.push_str(&format!("  {line}\n"));
        }
    }
    s.push_str("algorithm\n");
    s.push_str(&format!(
        "  (_,{out_vals}) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), \"{}\", {{{in_vals}}}, dummyMsg);\n",
        f.name
    ));
    for line in post_match.lines() {
        s.push_str(&format!("  {line}\n"));
    }
    s.push_str(&format!("end {};\n", f.name));
    s
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 3 {
        eprintln!("usage: scripting_api_gen <ModelicaBuiltin.mo> <out OpenModelicaScriptingAPI.mo>");
        std::process::exit(2);
    }
    let builtin_path = &args[1];
    let out_path = &args[2];

    let code = std::fs::read_to_string(builtin_path)
        .unwrap_or_else(|e| panic!("read {builtin_path}: {e}"));
    let program = parse(&code, builtin_path, builtin_path, Grammar::MetaModelica, false, 0.0)
        .unwrap_or_else(|e| panic!("parse {builtin_path}: {e}"));

    let top: Vec<Arc<Class>> = (&*program.classes).into_iter().cloned().collect();
    let openmodelica = find_class(&top, "OpenModelica")
        .expect("no `OpenModelica` package in the builtin file");
    let scripting = find_class(&sub_classes(&openmodelica), "Scripting")
        .expect("no `OpenModelica.Scripting` package in the builtin file");

    // Collect in source order, then reverse to match omc's prepended `tys`.
    let mut funcs: Vec<Func> = sub_classes(&scripting).iter().filter_map(|c| collect_func(c)).collect();
    funcs.reverse();

    let mut body = String::from(
        "import Absyn;\n\
         import AbsynUtil;\n\
         import CevalScript;\n\
         import Parser;\n\
         \n\
         protected\n\
         \n\
         import Values;\n\
         import ValuesMake;\n\
         import ValuesUtil;\n\
         constant Absyn.Msg dummyMsg = Absyn.MSG(SOURCEINFO(\"<interactive>\",false,1,1,1,1,0.0));\n\
         \n\
         public\n\
         \n",
    );
    for f in &funcs {
        body.push_str(&emit_func(f));
        body.push('\n');
    }

    // The two fixups OpenModelicaScriptingAPI.mos applies to the template output.
    let body = body
        .replace("ValuesUtil.makeArray", "ValuesMake.makeArray")
        .replace("ValuesUtil.valString", "ValuesDump.valString");

    let out = format!(
        "encapsulated package OpenModelicaScriptingAPI\n\n{body}annotation(__OpenModelica_Interface=\"backend_main\");\nend OpenModelicaScriptingAPI;\n"
    );
    std::fs::write(out_path, out).unwrap_or_else(|e| panic!("write {out_path}: {e}"));
    eprintln!("scripting_api_gen: wrote {} functions to {out_path}", funcs.len());
}
