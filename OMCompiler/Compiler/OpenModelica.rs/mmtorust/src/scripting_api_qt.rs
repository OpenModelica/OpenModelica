//! Generator for the typed `OMCInterface` (OpenModelicaScriptingAPIQt) that
//! OMEdit links against, retargeted from the MMC ABI to the Rust port.
//!
//! The C compiler builds this interface with the Susan template
//! `GenerateAPIFunctionsTpl.tpl`, emitting a Qt C++ class whose methods marshal
//! Qt ↔ MMC boxed values and call `omc_OpenModelicaScriptingAPI_*`. Those MMC
//! symbols do not exist in the Rust port, so we instead generate three files
//! from the *resolved* signatures mmtorust already has for the
//! `OpenModelicaScriptingAPI` package:
//!
//!   * `scripting_api_qt.rs` — one `#[no_mangle] extern "C"` wrapper per
//!     scripting function, plus a tiny runtime (an opaque `OmcSeq` container for
//!     lists/tuples, string allocation, and a thread-local exception slot).
//!   * `OpenModelicaScriptingAPIQtABI.h` — the C declarations of that ABI.
//!   * `OpenModelicaScriptingAPIQt.{h,cpp}` — the `OMCInterface` Qt class,
//!     marshalling Qt types ↔ the plain-C Rust ABI.
//!
//! ## ABI shape (typed, per function)
//! Scalars cross the boundary as native C types (`*const c_char` / `int64_t` /
//! `double` / `int`); aggregates (`list<…>`, including nested lists, and the
//! multiple-output tuple of a function) cross as an opaque `OmcSeq*` handle that
//! the other side reads positionally with typed getters. This is the bounded
//! type space the Qt template supports — `String`, `Integer`, `Real`,
//! `Boolean`, `T_Code(typename)` (already `String` at this layer), `list<…>`,
//! and tuples thereof. Any function whose signature falls outside it is skipped
//! (and reported), never miscompiled.
//!
//! ## Failure semantics
//! Mirrors the MMC interface (`MMC_TRY_TOP_INTERNAL`/`MMC_CATCH_TOP()`): a
//! MetaModelica failure (`Result::Err`) yields a default-valued result and is
//! *not* surfaced as an exception (OMEdit reads `getErrorString()` separately);
//! only a hard fault (a Rust panic, the analogue of the C++ exception the MMC
//! interface caught) is reported, via a thread-local message the C++ side turns
//! into `emit throwException(...)`.

use crate::hierarchy::{FunctionInput, NameNode, Ty};
use openmodelica_ast::Absyn;
use std::collections::HashMap;
use std::fmt::Write as _;

/// The three generated artifacts.
pub struct Generated {
    /// `scripting_api_qt.rs` — the Rust C-ABI module (lives in the crate's src).
    pub rust_abi: String,
    /// `OpenModelicaScriptingAPIQtABI.h` — C declarations of the ABI.
    pub abi_header: String,
    /// `OpenModelicaScriptingAPIQt.h` — the `OMCInterface` class declaration.
    pub qt_header: String,
    /// `OpenModelicaScriptingAPIQt.cpp` — the `OMCInterface` implementation.
    pub qt_source: String,
    /// Names of functions skipped because their signature is outside the
    /// supported type space (reported by the caller).
    pub skipped: Vec<String>,
}

/// One scripting function, distilled to what both back-ends need.
struct Func {
    /// Simple name = Rust function name in `OpenModelicaScriptingAPI` and the
    /// C++ method name (and, prefixed, the C symbol).
    name: String,
    inputs: Vec<(String, Ty)>,
    /// `Ty::Tuple` for multiple outputs, a scalar/list `Ty` for one, `Ty::Unit`
    /// for none.
    output: Ty,
    /// For a tuple output, the per-component names recovered from the
    /// `OpenModelica.Scripting` definition; used for the `<name>_res` fields.
    output_names: Vec<String>,
}

// ── public entry points ────────────────────────────────────────────────────

/// Recover, for every function in the `OpenModelica.Scripting` package of the
/// builtin environment, its output-component names in declaration order.
///
/// The generated `OpenModelicaScriptingAPI.mo` wrapper renames outputs to
/// `res1`, `res2`, … so the names OMEdit relies on (e.g.
/// `convertUnits_res.scaleFactor`) survive only in the original definition in
/// `ModelicaBuiltin.mo`/`NFModelicaBuiltin.mo`. We parse that separately (it is
/// not part of the compiler sources mmtorust translates) and walk the
/// `OpenModelica` subtree.
///
/// We work on the raw `Absyn` rather than the `MM` model: the builtin functions
/// are Modelica, not MetaModelica, and declare outputs with array dimensions
/// (`output String[:] x;`) which `MM::from_program` rejects (and silently drops
/// the whole function for the NF builtin) — losing exactly the array-output
/// functions whose names we need.
pub fn extract_output_names(prog: &Absyn::Program) -> HashMap<String, Vec<String>> {
    let mut out = HashMap::new();
    for class in prog.classes.as_ref() {
        if class.name == "OpenModelica" {
            collect_output_names(class, &mut out);
        }
    }
    out
}

fn collect_output_names(c: &Absyn::Class, out: &mut HashMap<String, Vec<String>>) {
    let parts = match c.body.as_ref() {
        Absyn::ClassDef::PARTS { classParts, .. } => classParts,
        Absyn::ClassDef::CLASS_EXTENDS { parts, .. } => parts,
        _ => return,
    };
    let is_function = matches!(c.restriction, Absyn::Restriction::R_FUNCTION { .. });
    if is_function {
        let mut names = Vec::new();
        for_each_element(parts, |spec| {
            if let Absyn::ElementSpec::COMPONENTS { attributes, components, .. } = spec
                && matches!(
                    attributes.direction,
                    Absyn::Direction::OUTPUT | Absyn::Direction::INPUT_OUTPUT
                )
            {
                for ci in components.as_ref() {
                    names.push(ci.component.name.to_string());
                }
            }
        });
        out.insert(c.name.to_string(), names);
        return;
    }
    // A package (or other container): recurse into nested classes.
    for_each_element(parts, |spec| {
        if let Absyn::ElementSpec::CLASSDEF { class_, .. } = spec {
            collect_output_names(class_, out);
        }
    });
}

/// Apply `f` to each element specification in the public/protected parts.
fn for_each_element(
    parts: &metamodelica::List<std::sync::Arc<Absyn::ClassPart>>,
    mut f: impl FnMut(&Absyn::ElementSpec),
) {
    for part in parts {
        let items = match part.as_ref() {
            Absyn::ClassPart::PUBLIC { contents } | Absyn::ClassPart::PROTECTED { contents } => contents,
            _ => continue,
        };
        for item in items.as_ref() {
            let Absyn::ElementItem::ELEMENTITEM { element } = item.as_ref() else { continue };
            let Absyn::Element::ELEMENT { specification, .. } = element.as_ref() else { continue };
            f(specification);
        }
    }
}

/// Generate the three files from the resolved `OpenModelicaScriptingAPI`
/// package node.
pub fn generate(node: &NameNode<'_>, output_names: &HashMap<String, Vec<String>>) -> Generated {
    let mut funcs: Vec<Func> = Vec::new();
    let mut skipped: Vec<String> = Vec::new();

    for (name, child) in &node.children {
        let Ty::Function { inputs, output, .. } = &child.ty else { continue };
        // Reject anything outside the supported type space rather than emit
        // code that would not compile or would silently misbehave.
        let supported = inputs.iter().all(|i| is_supported_arg(&i.ty)) && is_supported_ret(output);
        if !supported {
            skipped.push(name.clone());
            continue;
        }
        let in_pairs: Vec<(String, Ty)> = inputs
            .iter()
            .map(|FunctionInput { name, ty, .. }| (name.clone(), ty.clone()))
            .collect();
        let out_names = match output.as_ref() {
            Ty::Tuple(tys) => {
                let n = output_names.get(name).cloned().unwrap_or_default();
                if n.len() == tys.len() {
                    n
                } else {
                    // Fall back to positional names; flag it so a missing/changed
                    // builtin definition is visible rather than silently wrong.
                    eprintln!(
                        "[mmtorust] scripting-api: no matching OpenModelica.Scripting output names for tuple `{name}` ({} outputs); using res1..",
                        tys.len()
                    );
                    (1..=tys.len()).map(|i| format!("res{i}")).collect()
                }
            }
            _ => Vec::new(),
        };
        funcs.push(Func {
            name: name.clone(),
            inputs: in_pairs,
            output: (**output).clone(),
            output_names: out_names,
        });
    }
    funcs.sort_by(|a, b| a.name.cmp(&b.name));

    Generated {
        rust_abi: gen_rust_abi(&funcs),
        abi_header: gen_abi_header(&funcs),
        qt_header: gen_qt_header(&funcs),
        qt_source: gen_qt_source(&funcs),
        skipped,
    }
}

// ── supported-type predicates ──────────────────────────────────────────────

fn is_scalar(ty: &Ty) -> bool {
    matches!(ty, Ty::Str | Ty::I32 | Ty::F64 | Ty::Bool)
}

fn is_supported_arg(ty: &Ty) -> bool {
    match ty {
        t if is_scalar(t) => true,
        Ty::List(inner) => is_supported_arg(inner),
        _ => false,
    }
}

fn is_supported_ret(ty: &Ty) -> bool {
    match ty {
        Ty::Unit => true,
        t if is_scalar(t) => true,
        Ty::List(inner) => is_supported_arg(inner),
        Ty::Tuple(tys) => tys.iter().all(is_supported_arg),
        _ => false,
    }
}

// ── shared type mappings ───────────────────────────────────────────────────

/// The Rust type a scalar/list value has in `OpenModelicaScriptingAPI.rs`.
fn rust_ty(ty: &Ty) -> String {
    match ty {
        Ty::Str => "arcstr::ArcStr".to_string(),
        Ty::I32 => "i32".to_string(),
        Ty::F64 => "metamodelica::Real".to_string(),
        Ty::Bool => "bool".to_string(),
        Ty::List(inner) => format!("std::sync::Arc<metamodelica::List<{}>>", rust_ty(inner)),
        other => unreachable!("rust_ty on unsupported {other:?}"),
    }
}

/// C return type for a function's result.
fn c_ret_ty(ty: &Ty) -> &'static str {
    match ty {
        Ty::Unit => "void",
        Ty::Str => "char*",
        Ty::I32 => "int64_t",
        Ty::F64 => "double",
        Ty::Bool => "int",
        Ty::List(_) | Ty::Tuple(_) => "OmcSeq*",
        _ => unreachable!(),
    }
}

/// C parameter type for a function argument.
fn c_arg_ty(ty: &Ty) -> &'static str {
    match ty {
        Ty::Str => "const char*",
        Ty::I32 => "int64_t",
        Ty::F64 => "double",
        Ty::Bool => "int",
        Ty::List(_) => "const OmcSeq*",
        _ => unreachable!(),
    }
}

/// Rust spelling of the C types above (for the `extern "C"` signature).
fn rust_c_ret_ty(ty: &Ty) -> &'static str {
    match ty {
        Ty::Unit => "()",
        Ty::Str => "*mut c_char",
        Ty::I32 => "i64",
        Ty::F64 => "f64",
        Ty::Bool => "c_int",
        Ty::List(_) | Ty::Tuple(_) => "*mut OmcSeq",
        _ => unreachable!(),
    }
}

fn rust_c_arg_ty(ty: &Ty) -> &'static str {
    match ty {
        Ty::Str => "*const c_char",
        Ty::I32 => "i64",
        Ty::F64 => "f64",
        Ty::Bool => "c_int",
        Ty::List(_) => "*const OmcSeq",
        _ => unreachable!(),
    }
}

/// Qt type used in the `OMCInterface` method signatures and `_res` structs.
fn qt_ty(ty: &Ty) -> String {
    match ty {
        Ty::Str => "QString".to_string(),
        Ty::I32 => "modelica_integer".to_string(),
        Ty::F64 => "modelica_real".to_string(),
        Ty::Bool => "modelica_boolean".to_string(),
        Ty::List(inner) => format!("QList<{} >", qt_ty(inner)),
        other => unreachable!("qt_ty on unsupported {other:?}"),
    }
}

/// The `<name>_res` struct type name for a tuple-returning function.
fn res_struct(name: &str) -> String {
    format!("{name}_res")
}

// ── Rust ABI generation ────────────────────────────────────────────────────

fn gen_rust_abi(funcs: &[Func]) -> String {
    let mut s = String::new();
    s.push_str(RUST_ABI_RUNTIME);
    for f in funcs {
        gen_rust_wrapper(&mut s, f);
    }
    gen_wasm_dispatch(&mut s, funcs);
    s
}

fn gen_rust_wrapper(s: &mut String, f: &Func) {
    let sym = format!("omc_scripting_{}", f.name);
    let params: Vec<String> = f
        .inputs
        .iter()
        .map(|(n, ty)| format!("{}: {}", arg_ident(n), rust_c_arg_ty(ty)))
        .collect();
    let ret = rust_c_ret_ty(&f.output);
    let ret_clause = if f.output == Ty::Unit { String::new() } else { format!(" -> {ret}") };

    writeln!(s, "#[unsafe(no_mangle)]").unwrap();
    writeln!(s, "pub extern \"C\" fn {sym}({}){ret_clause} {{", params.join(", ")).unwrap();

    // Convert each C argument to its Rust value, then call.
    let mut call_args: Vec<String> = Vec::new();
    let mut conv = String::new();
    for (i, (n, ty)) in f.inputs.iter().enumerate() {
        let local = format!("__a{i}");
        writeln!(&mut conv, "        let {local} = {};", abi_in(ty, &arg_ident(n), 0)).unwrap();
        call_args.push(local);
    }
    let call = format!(
        "openmodelica_backend_main::OpenModelicaScriptingAPI::{}({})",
        crate::codegen::escape_ident(&f.name),
        call_args.join(", ")
    );

    writeln!(s, "    let __r = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {{").unwrap();
    s.push_str(&conv);
    writeln!(s, "        {call}").unwrap();
    writeln!(s, "    }}));").unwrap();

    let ok = match &f.output {
        Ty::Unit => "{}".to_string(),
        ty => abi_out(ty, "__v", 0),
    };
    let default = default_ret(&f.output);
    writeln!(s, "    match __r {{").unwrap();
    if f.output == Ty::Unit {
        writeln!(s, "        Ok(Ok(_)) => {{}},").unwrap();
        writeln!(s, "        Ok(Err(_)) => {{}},").unwrap();
        writeln!(s, "        Err(__e) => {{ abi_set_exception(format!(\"{}: {{}}\", panic_msg(__e))); }},", f.name).unwrap();
    } else {
        writeln!(s, "        Ok(Ok(__v)) => {ok},").unwrap();
        writeln!(s, "        Ok(Err(_)) => {default},").unwrap();
        writeln!(s, "        Err(__e) => {{ abi_set_exception(format!(\"{}: {{}}\", panic_msg(__e))); {default} }},", f.name).unwrap();
    }
    writeln!(s, "    }}").unwrap();
    writeln!(s, "}}").unwrap();
    s.push('\n');
}

/// A safe default C return for the MM-failure / panic paths.
fn default_ret(ty: &Ty) -> String {
    match ty {
        Ty::Unit => String::new(),
        Ty::Str => "abi_cstring(\"\")".to_string(),
        Ty::I32 => "0".to_string(),
        Ty::F64 => "0.0".to_string(),
        Ty::Bool => "0".to_string(),
        Ty::List(_) | Ty::Tuple(_) => "Box::into_raw(Box::new(OmcSeq::new()))".to_string(),
        _ => unreachable!(),
    }
}

// ── wasm worker-side ABI dispatch generation ───────────────────────────────
// Emits `omc_abi_dispatch`, which decodes the JSON request `{fn, args}` the
// main-side bridge posts, calls the matching `OpenModelicaScriptingAPI` function,
// and returns `{result}` / `{error}`. JSON shapes mirror the C++ OmcSeq↔JSON
// mapping (String→string, Integer/Real→number, Boolean→bool, list<…>→array).

fn gen_wasm_dispatch(s: &mut String, funcs: &[Func]) {
    s.push_str(WASM_DISPATCH_PREAMBLE);
    for f in funcs {
        gen_dispatch_arm(s, f);
    }
    s.push_str(WASM_DISPATCH_SUFFIX);
}

fn gen_dispatch_arm(s: &mut String, f: &Func) {
    let name = &f.name;
    let call_ident = crate::codegen::escape_ident(name);
    writeln!(s, "        \"{name}\" => {{").unwrap();
    writeln!(s, "            let __r = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {{").unwrap();
    let mut call_args: Vec<String> = Vec::new();
    for (i, (_n, ty)) in f.inputs.iter().enumerate() {
        writeln!(s, "                let __a{i} = {};", json_arg(ty, i)).unwrap();
        call_args.push(format!("__a{i}"));
    }
    writeln!(
        s,
        "                openmodelica_backend_main::OpenModelicaScriptingAPI::{call_ident}({})",
        call_args.join(", ")
    )
    .unwrap();
    writeln!(s, "            }}));").unwrap();
    writeln!(s, "            match __r {{").unwrap();
    match &f.output {
        Ty::Unit => {
            writeln!(s, "                Ok(_) => __ok(serde_json::Value::Null),").unwrap();
        }
        Ty::Tuple(tys) => {
            let binds: Vec<String> = (0..tys.len()).map(|i| format!("__t{i}")).collect();
            let items: Vec<String> = tys
                .iter()
                .enumerate()
                .map(|(i, t)| json_outr(t, &format!("&{}", binds[i]), 0))
                .collect();
            writeln!(
                s,
                "                Ok(Ok(({}))) => __ok(serde_json::Value::Array(vec![{}])),",
                binds.join(", "),
                items.join(", ")
            )
            .unwrap();
            writeln!(s, "                Ok(Err(_)) => __ok({}),", json_default(&f.output)).unwrap();
        }
        ty => {
            writeln!(s, "                Ok(Ok(__v)) => __ok({}),", json_out_owned(ty, "__v")).unwrap();
            writeln!(s, "                Ok(Err(_)) => __ok({}),", json_default(ty)).unwrap();
        }
    }
    writeln!(s, "                Err(__e) => __err(format!(\"{name}: {{}}\", panic_msg(__e))),").unwrap();
    writeln!(s, "            }}").unwrap();
    writeln!(s, "        }}").unwrap();
}

/// JSON argument `idx` → the Rust value of type `ty` the scripting function expects.
fn json_arg(ty: &Ty, idx: usize) -> String {
    match ty {
        Ty::Str => format!("__jstr(a, {idx})"),
        Ty::I32 => format!("__ji32(a, {idx})"),
        Ty::F64 => format!("__jf64(a, {idx})"),
        Ty::Bool => format!("__jbool(a, {idx})"),
        Ty::List(inner) => format!(
            "std::sync::Arc::new(a.get({idx}).and_then(|__v| __v.as_array()).map(|__arr0| __arr0.iter().map(|__o0| {}).collect::<metamodelica::List<{}>>()).unwrap_or(metamodelica::List::Nil))",
            json_elem(inner, "__o0", 1),
            rust_ty(inner)
        ),
        _ => unreachable!(),
    }
}

/// Read a `&serde_json::Value` (`o`) as the Rust value of type `ty`.
fn json_elem(ty: &Ty, o: &str, depth: usize) -> String {
    match ty {
        Ty::Str => format!("{o}.as_str().map(arcstr::ArcStr::from).unwrap_or_default()"),
        Ty::I32 => format!("{o}.as_f64().unwrap_or(0.0) as i32"),
        Ty::F64 => format!("metamodelica::OrderedFloat({o}.as_f64().unwrap_or(0.0))"),
        Ty::Bool => format!("{o}.as_bool().unwrap_or(false)"),
        Ty::List(inner) => {
            let arr = format!("__arr{depth}");
            let o2 = format!("__o{depth}");
            format!(
                "std::sync::Arc::new({o}.as_array().map(|{arr}| {arr}.iter().map(|{o2}| {}).collect::<metamodelica::List<{}>>()).unwrap_or(metamodelica::List::Nil))",
                json_elem(inner, &o2, depth + 1),
                rust_ty(inner)
            )
        }
        _ => unreachable!(),
    }
}

/// Marshal an owned Rust result `v` of type `ty` to a `serde_json::Value`.
fn json_out_owned(ty: &Ty, v: &str) -> String {
    match ty {
        Ty::List(inner) => format!(
            "serde_json::Value::Array({v}.as_ref().into_iter().map(|__e0| {}).collect())",
            json_outr(inner, "__e0", 1)
        ),
        ty => json_outr(ty, &format!("&{v}"), 0),
    }
}

/// Marshal a *reference* `e` (`&T`) of type `ty` to a `serde_json::Value`.
fn json_outr(ty: &Ty, e: &str, depth: usize) -> String {
    match ty {
        Ty::Str => format!("serde_json::Value::String(({e}).to_string())"),
        Ty::I32 => format!("serde_json::Value::from((*{e}) as i64)"),
        Ty::F64 => format!("__jnum(({e}).0)"),
        Ty::Bool => format!("serde_json::Value::Bool(*{e})"),
        Ty::List(inner) => {
            let el = format!("__e{depth}");
            format!(
                "serde_json::Value::Array((&**{e}).into_iter().map(|{el}| {}).collect())",
                json_outr(inner, &el, depth + 1)
            )
        }
        _ => unreachable!(),
    }
}

/// The JSON value returned on a MetaModelica failure (mirrors the C-ABI default).
fn json_default(ty: &Ty) -> String {
    match ty {
        Ty::Str => "serde_json::Value::String(String::new())".to_string(),
        Ty::I32 => "serde_json::Value::from(0i64)".to_string(),
        Ty::F64 => "__jnum(0.0)".to_string(),
        Ty::Bool => "serde_json::Value::Bool(false)".to_string(),
        Ty::List(_) | Ty::Tuple(_) => "serde_json::Value::Array(Vec::new())".to_string(),
        _ => unreachable!(),
    }
}

const WASM_DISPATCH_PREAMBLE: &str = r#"
// ── wasm worker-side ABI dispatch (OMEdit web bridge) ───────────────────────
// GENERATED. Routes a JSON request {fn, args} posted by OMEdit's main-thread
// bridge (OpenModelicaScriptingAPIQtBridge.cpp) to the scripting function and
// returns {result} or {error}. See the generator (gen_wasm_dispatch).
#[cfg(target_arch = "wasm32")]
fn __jstr(a: &[serde_json::Value], i: usize) -> arcstr::ArcStr {
    a.get(i).and_then(|v| v.as_str()).map(arcstr::ArcStr::from).unwrap_or_default()
}
#[cfg(target_arch = "wasm32")]
fn __ji32(a: &[serde_json::Value], i: usize) -> i32 {
    a.get(i).and_then(|v| v.as_f64()).unwrap_or(0.0) as i32
}
#[cfg(target_arch = "wasm32")]
fn __jf64(a: &[serde_json::Value], i: usize) -> metamodelica::Real {
    metamodelica::OrderedFloat(a.get(i).and_then(|v| v.as_f64()).unwrap_or(0.0))
}
#[cfg(target_arch = "wasm32")]
fn __jbool(a: &[serde_json::Value], i: usize) -> bool {
    a.get(i).and_then(|v| v.as_bool()).unwrap_or(false)
}
/// JSON cannot represent NaN/Inf; such a value becomes null (the C++ side maps it back to 0).
#[cfg(target_arch = "wasm32")]
fn __jnum(x: f64) -> serde_json::Value {
    serde_json::Number::from_f64(x).map(serde_json::Value::Number).unwrap_or(serde_json::Value::Null)
}
#[cfg(target_arch = "wasm32")]
fn __ok(v: serde_json::Value) -> serde_json::Value {
    let mut o = serde_json::Map::new();
    o.insert("result".to_string(), v);
    serde_json::Value::Object(o)
}
#[cfg(target_arch = "wasm32")]
fn __err(msg: String) -> serde_json::Value {
    let mut o = serde_json::Map::new();
    o.insert("error".to_string(), serde_json::Value::String(msg));
    serde_json::Value::Object(o)
}

/// Dispatch one OMEdit ABI call. `req` is `{"fn": <name>, "args": [...]}`.
#[cfg(target_arch = "wasm32")]
pub fn omc_abi_dispatch(req: &str) -> String {
    let parsed: serde_json::Value = match serde_json::from_str(req) {
        Ok(v) => v,
        Err(__e) => return __err(format!("omc_abi_dispatch: bad request json: {__e}")).to_string(),
    };
    let fnname = parsed.get("fn").and_then(|v| v.as_str()).unwrap_or("");
    let __empty: Vec<serde_json::Value> = Vec::new();
    let a: &[serde_json::Value] = parsed
        .get("args")
        .and_then(|v| v.as_array())
        .map(|v| v.as_slice())
        .unwrap_or(&__empty);

    let resp: serde_json::Value = match fnname {
"#;

const WASM_DISPATCH_SUFFIX: &str = r#"        __other => __err(format!("omc_abi_dispatch: unknown function `{__other}`")),
    };
    resp.to_string()
}
"#;

/// Convert a C argument expression `c` to the Rust value of type `ty`.
fn abi_in(ty: &Ty, c: &str, depth: usize) -> String {
    match ty {
        Ty::Str => format!("unsafe {{ abi_str_in({c}) }}"),
        Ty::I32 => format!("{c} as i32"),
        Ty::F64 => format!("metamodelica::OrderedFloat({c})"),
        Ty::Bool => format!("{c} != 0"),
        Ty::List(inner) => {
            let o = format!("__o{depth}");
            format!(
                "std::sync::Arc::new(unsafe {{ seq_slice({c}) }}.iter().map(|{o}| {}).collect::<metamodelica::List<{}>>())",
                read_elem(inner, &o, depth + 1),
                rust_ty(inner)
            )
        }
        _ => unreachable!(),
    }
}

/// Read an `&OmcVal` (`o`) as the Rust value of type `ty`.
fn read_elem(ty: &Ty, o: &str, depth: usize) -> String {
    match ty {
        Ty::Str => format!(
            "match {o} {{ OmcVal::Str(__c) => arcstr::ArcStr::from(__c.to_string_lossy().as_ref()), _ => arcstr::ArcStr::new() }}"
        ),
        Ty::I32 => format!("match {o} {{ OmcVal::Int(__x) => *__x as i32, _ => 0 }}"),
        Ty::F64 => format!(
            "match {o} {{ OmcVal::Real(__x) => metamodelica::OrderedFloat(*__x), _ => metamodelica::OrderedFloat(0.0) }}"
        ),
        Ty::Bool => format!("match {o} {{ OmcVal::Bool(__x) => *__x, _ => false }}"),
        Ty::List(inner) => {
            let o2 = format!("__o{depth}");
            format!(
                "match {o} {{ OmcVal::Seq(__sb) => std::sync::Arc::new(__sb.0.iter().map(|{o2}| {}).collect::<metamodelica::List<{}>>()), _ => std::sync::Arc::new(metamodelica::List::Nil) }}",
                read_elem(inner, &o2, depth + 1),
                rust_ty(inner)
            )
        }
        _ => unreachable!(),
    }
}

/// Marshal an owned Rust result `v` of type `ty` to its C return value.
fn abi_out(ty: &Ty, v: &str, depth: usize) -> String {
    match ty {
        Ty::Str => format!("abi_cstring(&{v})"),
        Ty::I32 => format!("{v} as i64"),
        Ty::F64 => format!("({v}).0"),
        Ty::Bool => format!("{v} as c_int"),
        Ty::List(elem) => {
            let s = format!("__s{depth}");
            let e = format!("__e{depth}");
            format!(
                "{{ let mut {s} = Box::new(OmcSeq::new()); for {e} in ({v}).as_ref() {{ {s}.0.push({}); }} Box::into_raw({s}) }}",
                omc_val(elem, &e, depth + 1)
            )
        }
        Ty::Tuple(tys) => {
            let s = format!("__s{depth}");
            let binds: Vec<String> = (0..tys.len()).map(|i| format!("__t{depth}_{i}")).collect();
            let mut body = String::new();
            write!(body, "{{ let ({}) = {v}; let mut {s} = Box::new(OmcSeq::new()); ", binds.join(", ")).unwrap();
            for (i, t) in tys.iter().enumerate() {
                write!(body, "{s}.0.push({}); ", omc_val(t, &format!("&{}", binds[i]), depth + 1)).unwrap();
            }
            write!(body, "Box::into_raw({s}) }}").unwrap();
            body
        }
        _ => unreachable!(),
    }
}

/// Build an `OmcVal` from a *reference* expression `e` (`&T`) of type `ty`.
fn omc_val(ty: &Ty, e: &str, depth: usize) -> String {
    match ty {
        Ty::Str => format!("OmcVal::Str(cstr_of({e}))"),
        Ty::I32 => format!("OmcVal::Int(*{e} as i64)"),
        // `{e}` is a reference (`&Real`); parenthesise before `.0` so it does not
        // bind as `&(x.0)`. Field access auto-derefs the reference to the f64.
        Ty::F64 => format!("OmcVal::Real(({e}).0)"),
        Ty::Bool => format!("OmcVal::Bool(*{e})"),
        Ty::List(inner) => {
            let s = format!("__s{depth}");
            let ev = format!("__e{depth}");
            format!(
                "OmcVal::Seq({{ let mut {s} = Box::new(OmcSeq::new()); for {ev} in ({e}).as_ref() {{ {s}.0.push({}); }} {s} }})",
                omc_val(inner, &ev, depth + 1)
            )
        }
        _ => unreachable!(),
    }
}

/// A Rust-safe spelling of an argument name (the source names are already
/// keyword-escaped, e.g. `class_`, but guard against Rust keywords anyway).
fn arg_ident(n: &str) -> String {
    crate::codegen::escape_ident(n)
}

const RUST_ABI_RUNTIME: &str = r#"//! GENERATED by mmtorust (scripting_api_qt) — DO NOT EDIT.
//!
//! Typed C ABI behind the OMEdit `OMCInterface` (OpenModelicaScriptingAPIQt).
//! See the generator `mmtorust/src/scripting_api_qt.rs` for the design.
#![allow(non_snake_case, unused_imports, clippy::all)]

use std::ffi::{c_char, c_int, CStr, CString};

/// Opaque positional container crossing the C boundary: a `list<…>` (possibly
/// nested) or a function's multiple-output tuple.
pub struct OmcSeq(Vec<OmcVal>);
pub enum OmcVal {
    Str(CString),
    Int(i64),
    Real(f64),
    Bool(bool),
    Seq(Box<OmcSeq>),
}
impl OmcSeq {
    fn new() -> Self { OmcSeq(Vec::new()) }
}

static EMPTY: &CStr = c"";

thread_local! {
    static ABI_EXCEPTION: std::cell::RefCell<Option<CString>> = const { std::cell::RefCell::new(None) };
}

fn abi_set_exception(msg: String) {
    let c = CString::new(msg.replace('\0', " ")).unwrap_or_else(|_| CString::new("error").unwrap());
    ABI_EXCEPTION.with(|cell| *cell.borrow_mut() = Some(c));
}

fn panic_msg(e: Box<dyn std::any::Any + Send>) -> String {
    if let Some(s) = e.downcast_ref::<&str>() {
        (*s).to_string()
    } else if let Some(s) = e.downcast_ref::<String>() {
        s.clone()
    } else {
        "panic".to_string()
    }
}

/// `1` if a panic was caught since the last `omc_abi_take_exception`.
#[unsafe(no_mangle)]
pub extern "C" fn omc_abi_has_exception() -> c_int {
    ABI_EXCEPTION.with(|c| if c.borrow().is_some() { 1 } else { 0 })
}

/// Take and clear the pending exception message (caller frees with
/// `omc_abi_free_string`); null if none.
#[unsafe(no_mangle)]
pub extern "C" fn omc_abi_take_exception() -> *mut c_char {
    ABI_EXCEPTION.with(|c| match c.borrow_mut().take() {
        Some(s) => s.into_raw(),
        None => std::ptr::null_mut(),
    })
}

fn cstr_of(s: &str) -> CString {
    CString::new(s.replace('\0', " ")).unwrap_or_else(|_| CString::new("").unwrap())
}
fn abi_cstring(s: &str) -> *mut c_char {
    cstr_of(s).into_raw()
}

/// Free a `char*` returned by a scripting wrapper or `omc_abi_take_exception`.
#[unsafe(no_mangle)]
pub extern "C" fn omc_abi_free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe { drop(CString::from_raw(s)); }
    }
}

unsafe fn abi_str_in(p: *const c_char) -> arcstr::ArcStr {
    if p.is_null() {
        return arcstr::ArcStr::new();
    }
    let b = unsafe { CStr::from_ptr(p) }.to_bytes();
    arcstr::ArcStr::from(String::from_utf8_lossy(b).as_ref())
}

unsafe fn seq_slice<'a>(s: *const OmcSeq) -> &'a [OmcVal] {
    if s.is_null() { &[] } else { unsafe { &(*s).0 } }
}

// ── seq builder (C++ → Rust, for list arguments) ──
#[unsafe(no_mangle)]
pub extern "C" fn omc_seq_new() -> *mut OmcSeq {
    Box::into_raw(Box::new(OmcSeq::new()))
}
#[unsafe(no_mangle)]
pub extern "C" fn omc_seq_free(s: *mut OmcSeq) {
    if !s.is_null() {
        unsafe { drop(Box::from_raw(s)); }
    }
}
#[unsafe(no_mangle)]
pub extern "C" fn omc_seq_push_str(s: *mut OmcSeq, p: *const c_char) {
    if let Some(sq) = unsafe { s.as_mut() } {
        let c = if p.is_null() { CString::default() } else { unsafe { CStr::from_ptr(p) }.to_owned() };
        sq.0.push(OmcVal::Str(c));
    }
}
#[unsafe(no_mangle)]
pub extern "C" fn omc_seq_push_int(s: *mut OmcSeq, v: i64) {
    if let Some(sq) = unsafe { s.as_mut() } { sq.0.push(OmcVal::Int(v)); }
}
#[unsafe(no_mangle)]
pub extern "C" fn omc_seq_push_real(s: *mut OmcSeq, v: f64) {
    if let Some(sq) = unsafe { s.as_mut() } { sq.0.push(OmcVal::Real(v)); }
}
#[unsafe(no_mangle)]
pub extern "C" fn omc_seq_push_bool(s: *mut OmcSeq, v: c_int) {
    if let Some(sq) = unsafe { s.as_mut() } { sq.0.push(OmcVal::Bool(v != 0)); }
}
/// Push `child` as a nested sequence; takes ownership of `child`.
#[unsafe(no_mangle)]
pub extern "C" fn omc_seq_push_seq(s: *mut OmcSeq, child: *mut OmcSeq) {
    if child.is_null() {
        return;
    }
    let cb = unsafe { Box::from_raw(child) };
    if let Some(sq) = unsafe { s.as_mut() } {
        sq.0.push(OmcVal::Seq(cb));
    }
    // If `s` is null, `cb` is dropped here (no leak).
}

// ── seq reader (Rust → C++, for list/tuple results) ──
#[unsafe(no_mangle)]
pub extern "C" fn omc_seq_len(s: *const OmcSeq) -> usize {
    unsafe { seq_slice(s) }.len()
}
#[unsafe(no_mangle)]
pub extern "C" fn omc_seq_str(s: *const OmcSeq, i: usize) -> *const c_char {
    match unsafe { seq_slice(s) }.get(i) {
        Some(OmcVal::Str(c)) => c.as_ptr(),
        _ => EMPTY.as_ptr(),
    }
}
#[unsafe(no_mangle)]
pub extern "C" fn omc_seq_int(s: *const OmcSeq, i: usize) -> i64 {
    match unsafe { seq_slice(s) }.get(i) {
        Some(OmcVal::Int(x)) => *x,
        _ => 0,
    }
}
#[unsafe(no_mangle)]
pub extern "C" fn omc_seq_real(s: *const OmcSeq, i: usize) -> f64 {
    match unsafe { seq_slice(s) }.get(i) {
        Some(OmcVal::Real(x)) => *x,
        _ => 0.0,
    }
}
#[unsafe(no_mangle)]
pub extern "C" fn omc_seq_bool(s: *const OmcSeq, i: usize) -> c_int {
    match unsafe { seq_slice(s) }.get(i) {
        Some(OmcVal::Bool(x)) => *x as c_int,
        _ => 0,
    }
}
#[unsafe(no_mangle)]
pub extern "C" fn omc_seq_seq(s: *const OmcSeq, i: usize) -> *const OmcSeq {
    match unsafe { seq_slice(s) }.get(i) {
        Some(OmcVal::Seq(b)) => &**b as *const OmcSeq,
        _ => std::ptr::null(),
    }
}

"#;

// ── C ABI header generation ────────────────────────────────────────────────

fn gen_abi_header(funcs: &[Func]) -> String {
    let mut s = String::new();
    s.push_str(
        r#"/* generated by mmtorust (scripting_api_qt) */
#ifndef OpenModelicaScriptingAPIQtABI__H
#define OpenModelicaScriptingAPIQtABI__H

#include <stdint.h>
#include <stddef.h>

/* OMEdit constructs OMCInterface with its compiler thread handle; the Rust
   backend keeps its own per-thread state, so this is an opaque, ignored tag. */
typedef struct threadData_s threadData_t;

typedef int64_t modelica_integer;
typedef double  modelica_real;
typedef int     modelica_boolean;

typedef struct OmcSeq OmcSeq;

#ifdef __cplusplus
extern "C" {
#endif

/* failure / strings */
int   omc_abi_has_exception(void);
char* omc_abi_take_exception(void);
void  omc_abi_free_string(char*);

/* opaque sequence container (list<…>, nested lists, and output tuples) */
OmcSeq* omc_seq_new(void);
void    omc_seq_free(OmcSeq*);
void    omc_seq_push_str(OmcSeq*, const char*);
void    omc_seq_push_int(OmcSeq*, int64_t);
void    omc_seq_push_real(OmcSeq*, double);
void    omc_seq_push_bool(OmcSeq*, int);
void    omc_seq_push_seq(OmcSeq*, OmcSeq*);
size_t        omc_seq_len(const OmcSeq*);
const char*   omc_seq_str(const OmcSeq*, size_t);
int64_t       omc_seq_int(const OmcSeq*, size_t);
double        omc_seq_real(const OmcSeq*, size_t);
int           omc_seq_bool(const OmcSeq*, size_t);
const OmcSeq* omc_seq_seq(const OmcSeq*, size_t);

/* scripting functions */
"#,
    );
    for f in funcs {
        let params: Vec<String> = f.inputs.iter().map(|(_, ty)| c_arg_ty(ty).to_string()).collect();
        let plist = if params.is_empty() { "void".to_string() } else { params.join(", ") };
        writeln!(s, "{} omc_scripting_{}({});", c_ret_ty(&f.output), f.name, plist).unwrap();
    }
    s.push_str("\n#ifdef __cplusplus\n}\n#endif\n#endif\n");
    s
}

// ── Qt header generation ───────────────────────────────────────────────────

fn gen_qt_header(funcs: &[Func]) -> String {
    let mut s = String::new();
    s.push_str(
        r#"/* generated by mmtorust (scripting_api_qt) */
#ifndef OpenModelicaScriptingAPIQt__H
#define OpenModelicaScriptingAPIQt__H

// Only basic Qt datatypes are used (QObject/QString/QList/QElapsedTimer), all
// in QtCore — no QtGui/OpenGL dependency.
#include <QtCore>
#include "OpenModelicaScriptingAPIQtABI.h"

class OMCInterface : public QObject
{
  Q_OBJECT
public:
  threadData_t *threadData;
  OMCInterface(threadData_t *td);
"#,
    );
    for f in funcs {
        if let Ty::Tuple(tys) = &f.output {
            s.push_str(&gen_res_struct(f, tys));
        }
        writeln!(s, "  {};", method_signature(f)).unwrap();
    }
    s.push_str(
        r#"signals:
  void logCommand(QString command);
  // elapsed time in seconds
  void logResponse(QString command, QString response, double elapsed);
  void throwException(QString exception);
};

#endif
"#,
    );
    s
}

/// `typedef struct <name>_res { … QString toString(){…} } <name>_res;`
fn gen_res_struct(f: &Func, tys: &[Ty]) -> String {
    let res = res_struct(&f.name);
    let mut s = String::new();
    writeln!(s, "  typedef struct {res} {{").unwrap();
    for (i, ty) in tys.iter().enumerate() {
        writeln!(s, "    {} {};", qt_ty(ty), f.output_names[i]).unwrap();
    }
    writeln!(s, "    QString toString() {{").unwrap();
    writeln!(s, "      QString resultBuffer = \"(\";").unwrap();
    for (i, ty) in tys.iter().enumerate() {
        if i > 0 {
            writeln!(s, "      resultBuffer.append(\",\");").unwrap();
        }
        s.push_str(&log_text(ty, &f.output_names[i], "resultBuffer", 6, false));
    }
    writeln!(s, "      resultBuffer.append(\")\");").unwrap();
    writeln!(s, "      return resultBuffer;").unwrap();
    writeln!(s, "    }}").unwrap();
    writeln!(s, "  }} {res};").unwrap();
    s
}

/// `<retType> <name>(<qt params>)` (no trailing semicolon, no class qualifier).
fn method_signature(f: &Func) -> String {
    let params: Vec<String> = f
        .inputs
        .iter()
        .map(|(n, ty)| format!("{} {}", qt_ty(ty), n))
        .collect();
    let ret = match &f.output {
        Ty::Unit => "void".to_string(),
        Ty::Tuple(_) => res_struct(&f.name),
        ty => qt_ty(ty),
    };
    format!("{ret} {}({})", f.name, params.join(", "))
}

// ── Qt source generation ───────────────────────────────────────────────────

fn gen_qt_source(funcs: &[Func]) -> String {
    let mut s = String::new();
    s.push_str(
        r#"/* generated by mmtorust (scripting_api_qt) */

#include <stdexcept>
#include "OpenModelicaScriptingAPIQt.h"

OMCInterface::OMCInterface(threadData_t *td)
  : threadData(td)
{
}
"#,
    );
    for f in funcs {
        gen_qt_method(&mut s, f);
    }
    s
}

fn gen_qt_method(s: &mut String, f: &Func) {
    // Out-of-line member definition: a nested `_res` return type must be
    // qualified with the class name (`OMCInterface::<name>_res`).
    let ret = match &f.output {
        Ty::Unit => "void".to_string(),
        Ty::Tuple(_) => format!("OMCInterface::{}", res_struct(&f.name)),
        ty => qt_ty(ty),
    };
    let params: Vec<String> = f
        .inputs
        .iter()
        .map(|(n, ty)| format!("{} {}", qt_ty(ty), n))
        .collect();
    writeln!(s, "{ret} OMCInterface::{}({})", f.name, params.join(", ")).unwrap();
    writeln!(s, "{{").unwrap();
    writeln!(s, "  QElapsedTimer commandTime;").unwrap();
    writeln!(s, "  commandTime.start();").unwrap();

    // command log
    writeln!(s, "  QString commandLog;").unwrap();
    for (i, (n, ty)) in f.inputs.iter().enumerate() {
        if i > 0 {
            writeln!(s, "  commandLog.append(\",\");").unwrap();
        }
        s.push_str(&log_text(ty, n, "commandLog", 2, true));
    }
    writeln!(s, "  emit logCommand(\"{}(\"+commandLog+\")\");", f.name).unwrap();
    s.push('\n');

    // input marshalling (build OmcSeq for lists, QByteArray for strings)
    let mut ctr = Counter::default();
    let mut cargs: Vec<String> = Vec::new();
    let mut frees: Vec<String> = Vec::new();
    for (n, ty) in &f.inputs {
        match ty {
            Ty::Str => {
                writeln!(s, "  QByteArray {n}_utf8 = {n}.toUtf8();").unwrap();
                cargs.push(format!("{n}_utf8.constData()"));
            }
            Ty::I32 | Ty::F64 | Ty::Bool => cargs.push(n.clone()),
            Ty::List(elem) => {
                let seq = format!("{n}_seq");
                writeln!(s, "  OmcSeq* {seq} = omc_seq_new();").unwrap();
                cpp_build_seq(s, &seq, n, elem, 2, &mut ctr);
                cargs.push(seq.clone());
                frees.push(seq);
            }
            _ => unreachable!(),
        }
    }

    // result declaration
    if f.output != Ty::Unit {
        let decl = match &f.output {
            Ty::Tuple(_) => res_struct(&f.name),
            ty => qt_ty(ty),
        };
        writeln!(s, "  {decl} result;").unwrap();
    }
    let call = format!("omc_scripting_{}({})", f.name, cargs.join(", "));

    writeln!(s, "  try {{").unwrap();
    cpp_call_and_read(s, f, &call, &mut ctr);
    for fr in &frees {
        writeln!(s, "    omc_seq_free({fr});").unwrap();
    }
    writeln!(s, "    if (omc_abi_has_exception()) {{").unwrap();
    writeln!(s, "      char *__ex = omc_abi_take_exception();").unwrap();
    writeln!(s, "      emit throwException(QString(\"{} failed. %1\").arg(QString::fromUtf8(__ex)));", f.name).unwrap();
    writeln!(s, "      omc_abi_free_string(__ex);").unwrap();
    writeln!(s, "    }}").unwrap();
    writeln!(s, "  }} catch(std::exception &exception) {{").unwrap();
    writeln!(s, "    emit throwException(QString(\"{} failed. %1\").arg(exception.what()));", f.name).unwrap();
    writeln!(s, "  }}").unwrap();
    s.push('\n');

    // response log
    writeln!(s, "  QString responseLog;").unwrap();
    if f.output != Ty::Unit {
        if let Ty::Tuple(_) = &f.output {
            writeln!(s, "  responseLog.append(result.toString());").unwrap();
        } else {
            s.push_str(&log_text(&f.output, "result", "responseLog", 2, false));
        }
    }
    writeln!(s, "  double elapsed = (double)commandTime.elapsed() / 1000.0;").unwrap();
    writeln!(s, "  emit logResponse(\"{}(\"+commandLog+\")\", responseLog, elapsed);", f.name).unwrap();
    if f.output != Ty::Unit {
        writeln!(s, "  return result;").unwrap();
    }
    writeln!(s, "}}").unwrap();
}

/// Emit the ABI call and read the raw result into the `result` lvalue.
fn cpp_call_and_read(s: &mut String, f: &Func, call: &str, ctr: &mut Counter) {
    match &f.output {
        Ty::Unit => {
            writeln!(s, "    {call};").unwrap();
        }
        Ty::Str => {
            writeln!(s, "    char *__r = {call};").unwrap();
            writeln!(s, "    result = QString::fromUtf8(__r);").unwrap();
            writeln!(s, "    omc_abi_free_string(__r);").unwrap();
        }
        Ty::I32 | Ty::F64 | Ty::Bool => {
            writeln!(s, "    result = {call};").unwrap();
        }
        Ty::List(elem) => {
            writeln!(s, "    OmcSeq *__rs = {call};").unwrap();
            cpp_read_list(s, "result", elem, "__rs", 4, ctr);
            writeln!(s, "    omc_seq_free(__rs);").unwrap();
        }
        Ty::Tuple(tys) => {
            writeln!(s, "    OmcSeq *__rs = {call};").unwrap();
            for (i, ty) in tys.iter().enumerate() {
                let lv = format!("result.{}", f.output_names[i]);
                cpp_read_into(s, &lv, ty, "__rs", &i.to_string(), 4, ctr);
            }
            writeln!(s, "    omc_seq_free(__rs);").unwrap();
        }
        _ => unreachable!(),
    }
}

/// Read element `idx` of `seq` as `ty` into the C++ lvalue `lv`.
fn cpp_read_into(s: &mut String, lv: &str, ty: &Ty, seq: &str, idx: &str, ind: usize, ctr: &mut Counter) {
    let pad = " ".repeat(ind);
    match ty {
        Ty::Str => writeln!(s, "{pad}{lv} = QString::fromUtf8(omc_seq_str({seq}, {idx}));").unwrap(),
        Ty::I32 => writeln!(s, "{pad}{lv} = omc_seq_int({seq}, {idx});").unwrap(),
        Ty::F64 => writeln!(s, "{pad}{lv} = omc_seq_real({seq}, {idx});").unwrap(),
        Ty::Bool => writeln!(s, "{pad}{lv} = omc_seq_bool({seq}, {idx});").unwrap(),
        Ty::List(elem) => {
            let sub = ctr.next("sub");
            writeln!(s, "{pad}{{").unwrap();
            writeln!(s, "{pad}  const OmcSeq *{sub} = omc_seq_seq({seq}, {idx});").unwrap();
            cpp_read_list(s, lv, elem, &sub, ind + 2, ctr);
            writeln!(s, "{pad}}}").unwrap();
        }
        _ => unreachable!(),
    }
}

/// Read all elements of `seq` (as a `list<elem>`) into the C++ list lvalue `lv`.
fn cpp_read_list(s: &mut String, lv: &str, elem: &Ty, seq: &str, ind: usize, ctr: &mut Counter) {
    let pad = " ".repeat(ind);
    let n = ctr.next("n");
    let i = ctr.next("i");
    let e = ctr.next("e");
    writeln!(s, "{pad}{lv}.clear();").unwrap();
    writeln!(s, "{pad}size_t {n} = omc_seq_len({seq});").unwrap();
    writeln!(s, "{pad}for (size_t {i} = 0; {i} < {n}; {i}++) {{").unwrap();
    writeln!(s, "{pad}  {} {e};", qt_ty(elem)).unwrap();
    cpp_read_into(s, &e, elem, seq, &i, ind + 2, ctr);
    writeln!(s, "{pad}  {lv}.push_back({e});").unwrap();
    writeln!(s, "{pad}}}").unwrap();
}

/// Build `seq` from the C++ list value `src` (element type `elem`).
fn cpp_build_seq(s: &mut String, seq: &str, src: &str, elem: &Ty, ind: usize, ctr: &mut Counter) {
    let pad = " ".repeat(ind);
    let e = ctr.next("be");
    writeln!(s, "{pad}for (const {} &{e} : {src}) {{", qt_ty(elem)).unwrap();
    match elem {
        Ty::Str => {
            let b = ctr.next("bb");
            writeln!(s, "{pad}  QByteArray {b} = {e}.toUtf8();").unwrap();
            writeln!(s, "{pad}  omc_seq_push_str({seq}, {b}.constData());").unwrap();
        }
        Ty::I32 => writeln!(s, "{pad}  omc_seq_push_int({seq}, {e});").unwrap(),
        Ty::F64 => writeln!(s, "{pad}  omc_seq_push_real({seq}, {e});").unwrap(),
        Ty::Bool => writeln!(s, "{pad}  omc_seq_push_bool({seq}, {e});").unwrap(),
        Ty::List(inner) => {
            let child = ctr.next("child");
            writeln!(s, "{pad}  OmcSeq *{child} = omc_seq_new();").unwrap();
            cpp_build_seq(s, &child, &e, inner, ind + 2, ctr);
            writeln!(s, "{pad}  omc_seq_push_seq({seq}, {child});").unwrap();
        }
        _ => unreachable!(),
    }
    writeln!(s, "{pad}}}").unwrap();
}

/// Append a textual rendering of value `name` (type `ty`) to the C++ string
/// `buf` (used for command/response logs and `_res::toString`).
fn log_text(ty: &Ty, name: &str, buf: &str, ind: usize, _is_arg: bool) -> String {
    let pad = " ".repeat(ind);
    match ty {
        Ty::Str => format!("{pad}{buf}.append(\"\\\"\" + {name} + \"\\\"\");\n"),
        Ty::I32 | Ty::F64 => format!("{pad}{buf}.append(QString::number({name}));\n"),
        Ty::Bool => format!("{pad}{buf}.append({name} ? \"true\" : \"false\");\n"),
        Ty::List(elem) => {
            // A unique-ish suffix from the value name keeps nested loop vars distinct.
            let tag: String = name.chars().filter(|c| c.is_alphanumeric()).collect();
            let e = format!("{tag}_e");
            let c = format!("{tag}_c");
            let mut s = String::new();
            writeln!(s, "{pad}{buf}.append(\"{{\");").unwrap();
            writeln!(s, "{pad}int {c} = 0;").unwrap();
            writeln!(s, "{pad}foreach({} {e}, {name}) {{", qt_ty(elem)).unwrap();
            writeln!(s, "{pad}  if ({c}) {{ {buf}.append(\",\"); }}").unwrap();
            s.push_str(&log_text(elem, &e, buf, ind + 2, _is_arg));
            writeln!(s, "{pad}  {c}++;").unwrap();
            writeln!(s, "{pad}}}").unwrap();
            writeln!(s, "{pad}{buf}.append(\"}}\");").unwrap();
            s
        }
        _ => unreachable!(),
    }
}

/// Generates fresh, collision-free C++ identifiers across a method body.
#[derive(Default)]
struct Counter(usize);
impl Counter {
    fn next(&mut self, base: &str) -> String {
        self.0 += 1;
        format!("__{base}{}", self.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn parse_pkg(code: &str) -> Absyn::Program {
        openmodelica_ast::parser::parse(
            code,
            "t",
            "t",
            openmodelica_ast::parser::Grammar::MetaModelica,
            false,
            0.0,
        )
        .unwrap()
    }

    #[test]
    fn extract_array_and_comma_outputs() {
        let code = r#"encapsulated package OpenModelica
  package Scripting
    function f1
      output String[:] a;
      output String[:] b;
    external "builtin";
    end f1;
    function f2
      input String q;
      output String x, y;
      output String[:] z;
    external "builtin";
    end f2;
  end Scripting;
end OpenModelica;
"#;
        let prog = parse_pkg(code);
        let m = extract_output_names(&prog);
        assert_eq!(m.get("f1").map(|v| v.as_slice()), Some(["a".to_string(), "b".to_string()].as_slice()), "f1 = {:?}", m.get("f1"));
        assert_eq!(
            m.get("f2").map(|v| v.as_slice()),
            Some(["x".to_string(), "y".to_string(), "z".to_string()].as_slice()),
            "f2 = {:?}",
            m.get("f2")
        );
    }
}
