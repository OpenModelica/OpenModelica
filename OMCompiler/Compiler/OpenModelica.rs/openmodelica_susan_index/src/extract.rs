//! Reads the Rust sources of the packages the templates use.
//!
//! The sources follow mmtorust's conventions: a package is `<crate>/src/<Pkg>.rs`
//! (plus an optional `<Pkg>.handwritten.rs`), a single-record uniontype is a
//! struct followed by `pub type RECORD = Struct;`, a uniontype with functions is
//! `pub mod X { pub enum X .. }`, and a constant is a `const`, a static, a
//! zero-argument `const fn` or a zero-argument function reading a thread-local.

use std::collections::{BTreeMap, HashMap, HashSet};
use std::path::{Path, PathBuf};

use syn::{FnArg, GenericArgument, Item, PathArguments, ReturnType, Type, Visibility};

use crate::{ConstAccess, Constant, Field, Function, Index, Package, Param, Record, Ty, TypeDef};

pub struct SourceFiles {
    /// package -> (crate, files)
    pub packages: HashMap<String, (String, Vec<PathBuf>)>,
}

impl SourceFiles {
    pub fn scan(root: &Path) -> SourceFiles {
        let mut packages: HashMap<String, (String, Vec<PathBuf>)> = HashMap::new();
        let Ok(crates) = std::fs::read_dir(root) else { return SourceFiles { packages } };
        let mut crates: Vec<PathBuf> = crates.flatten().map(|e| e.path()).filter(|p| p.join("src").is_dir()).collect();
        crates.sort();
        for c in crates {
            let krate = c.file_name().unwrap().to_string_lossy().into_owned();
            let Ok(files) = std::fs::read_dir(c.join("src")) else { continue };
            let mut files: Vec<PathBuf> = files.flatten().map(|e| e.path()).filter(|p| p.is_file()).collect();
            files.sort();
            for f in files {
                let name = f.file_name().unwrap().to_string_lossy().into_owned();
                let Some(stem) = name.strip_suffix(".handwritten.rs").or(name.strip_suffix(".rs")) else { continue };
                let e = packages.entry(stem.to_string()).or_insert_with(|| (krate.clone(), vec![]));
                if e.0 == krate {
                    e.1.push(f);
                }
            }
        }
        SourceFiles { packages }
    }
}

struct Scope<'a> {
    pkg: &'a str,
    tyvars: HashSet<String>,
    mods: &'a HashSet<String>,
    uses: &'a HashMap<String, Vec<String>>,
}

fn collect_uses(tree: &syn::UseTree, prefix: &mut Vec<String>, out: &mut HashMap<String, Vec<String>>) {
    match tree {
        syn::UseTree::Path(p) => {
            prefix.push(p.ident.to_string());
            collect_uses(&p.tree, prefix, out);
            prefix.pop();
        }
        syn::UseTree::Name(n) => {
            let mut v = prefix.clone();
            v.push(n.ident.to_string());
            out.insert(n.ident.to_string(), v);
        }
        syn::UseTree::Rename(r) => {
            let mut v = prefix.clone();
            v.push(r.ident.to_string());
            out.insert(r.rename.to_string(), v);
        }
        syn::UseTree::Group(g) => g.items.iter().for_each(|t| collect_uses(t, prefix, out)),
        syn::UseTree::Glob(_) => {}
    }
}

fn is_path_prefix(s: &str) -> bool {
    s == "crate" || s == "self" || s == "super" || s == "metamodelica" || s.starts_with("openmodelica_")
}

fn generic_args(seg: &syn::PathSegment) -> Vec<&Type> {
    match &seg.arguments {
        PathArguments::AngleBracketed(a) => a.args.iter().filter_map(|g| if let GenericArgument::Type(t) = g { Some(t) } else { None }).collect(),
        _ => vec![],
    }
}

fn unraw(s: &str) -> String {
    s.strip_prefix("r#").unwrap_or(s).to_string()
}

fn map_ty(t: &Type, sc: &Scope) -> Result<Ty, String> {
    match t {
        Type::Reference(r) => map_ty(&r.elem, sc),
        Type::Paren(p) => map_ty(&p.elem, sc),
        Type::Tuple(tp) if tp.elems.is_empty() => Ok(Ty::Unit),
        Type::Tuple(tp) => Ok(Ty::Tuple(tp.elems.iter().map(|e| map_ty(e, sc)).collect::<Result<_, _>>()?)),
        Type::ImplTrait(i) if quote::quote!(#i).to_string().replace(' ', "").contains("AsRef<str>") => Ok(Ty::String),
        Type::TraitObject(_) | Type::ImplTrait(_) => Ok(Ty::FuncPtr),
        Type::Path(p) if p.qself.is_none() => {
            let segs: Vec<&syn::PathSegment> = p.path.segments.iter().collect();
            let last = segs.last().unwrap();
            let name = last.ident.to_string();
            let args = generic_args(last);
            let one = |f: fn(Box<Ty>) -> Ty| -> Result<Ty, String> {
                match args.as_slice() {
                    [a] => Ok(f(Box::new(map_ty(a, sc)?))),
                    _ => Err(format!("{name} arity")),
                }
            };
            match name.as_str() {
                "i32" | "i64" | "isize" => return Ok(Ty::Int),
                "f64" => return Ok(Ty::F64),
                "OrderedFloat" | "Real" => return Ok(Ty::Real),
                "Integer" => return Ok(Ty::Int),
                "Boolean" | "bool" => return Ok(Ty::Bool),
                "ArcStr" | "String" | "str" => return Ok(Ty::String),
                "Text" => return Ok(Ty::Text),
                "SourceInfo" => return Ok(Ty::SourceInfo),
                "Ref" => return one(Ty::Ref),
                "Box" | "Arc" | "LazyLock" if args.len() == 1 => return map_ty(args[0], sc),
                "List" => return one(Ty::List),
                "Option" => return one(Ty::Option),
                "Array" => return one(Ty::Array),
                _ => {}
            }
            let args: Vec<Ty> = args.iter().map(|a| map_ty(a, sc)).collect::<Result<_, _>>()?;
            if segs.len() == 1 && sc.tyvars.contains(&name) {
                return Ok(Ty::TyVar(name));
            }
            let mut parts: Vec<String> = segs.iter().map(|s| s.ident.to_string()).collect();
            if !sc.mods.contains(&parts[0]) {
                if let Some(full) = sc.uses.get(&parts[0]) {
                    let mut v = full.clone();
                    v.extend(parts.drain(1..));
                    parts = v;
                }
            }
            while parts.first().is_some_and(|s| is_path_prefix(s)) {
                parts.remove(0);
            }
            let n = parts.len();
            if n >= 2 && parts[n - 1] == parts[n - 2] && (n >= 3 || sc.mods.contains(&parts[0])) {
                parts.pop();
            }
            let name = match parts.len() {
                0 => return Err("empty path".into()),
                1 => format!("{}.{}", sc.pkg, parts[0]),
                _ => parts.join("."),
            };
            Ok(if args.is_empty() { Ty::Named(name) } else { Ty::Generic(name, args) })
        }
        _ => Err(format!("type {}", quote::quote!(#t))),
    }
}

fn visible(v: &Visibility) -> Option<bool> {
    match v {
        Visibility::Public(_) => Some(true),
        Visibility::Restricted(_) => Some(false),
        Visibility::Inherited => None,
    }
}

fn reads_thread_local(f: &syn::ItemFn) -> bool {
    f.sig.inputs.is_empty() && f.block.stmts.len() == 1 && quote::quote!(#f).to_string().contains("_TLS . with")
}

#[derive(Default)]
struct Collected {
    types: Vec<(String, TypeDef)>,
    functions: Vec<(String, Function)>,
    constants: Vec<(String, Constant)>,
}

fn collect(
    items: &[Item],
    pkg: &str,
    prefix: &str,
    parent_uses: &HashMap<String, Vec<String>>,
    parent_mods: &HashSet<String>,
    out: &mut Collected,
    skipped: &mut Vec<String>,
) {
    let mut uses = parent_uses.clone();
    let mut mods = parent_mods.clone();
    let mut structs = HashSet::new();
    for it in items {
        match it {
            Item::Use(u) => collect_uses(&u.tree, &mut vec![], &mut uses),
            Item::Mod(m) if visible(&m.vis).is_some() => {
                mods.insert(m.ident.to_string());
            }
            Item::Struct(s) if visible(&s.vis).is_some() => {
                structs.insert(s.ident.to_string());
            }
            _ => {}
        }
    }
    let mut record_name: HashMap<String, String> = HashMap::new();
    for it in items {
        if let Item::Type(t) = it {
            if let Type::Path(p) = &*t.ty {
                if p.path.segments.len() == 1 && p.path.segments[0].arguments.is_empty() {
                    let target = p.path.segments[0].ident.to_string();
                    if structs.contains(&target) && target != t.ident.to_string() {
                        record_name.entry(target).or_insert(t.ident.to_string());
                    }
                }
            }
        }
    }
    let sc = Scope { pkg, tyvars: HashSet::new(), mods: &mods, uses: &uses };
    let mut own_skips = Vec::new();
    let mut skip = |n: &str, why: String| own_skips.push(format!("{pkg}.{prefix}{n}: {why}"));
    let fields = |fs: &syn::Fields| -> Result<Vec<Field>, String> {
        match fs {
            syn::Fields::Named(n) => n
                .named
                .iter()
                .map(|f| {
                    let id = f.ident.as_ref().unwrap().to_string();
                    Ok(Field { name: unraw(&id), rust: id, ty: map_ty(&f.ty, &sc)? })
                })
                .collect(),
            syn::Fields::Unit => Ok(vec![]),
            syn::Fields::Unnamed(_) => Err("tuple fields".into()),
        }
    };
    for it in items {
        match it {
            Item::Struct(s) if visible(&s.vis).is_some() => {
                let n = s.ident.to_string();
                if !s.generics.params.is_empty() {
                    skip(&n, "generic struct".into());
                    continue;
                }
                match fields(&s.fields) {
                    Ok(fs) => {
                        let rec = record_name.get(&n).cloned().unwrap_or(n.clone());
                        out.types.push((n.clone(), TypeDef::Union { rust: format!("{prefix}{n}"), is_struct: true, records: vec![Record { name: rec, fields: fs }] }));
                    }
                    Err(e) => skip(&n, e),
                }
            }
            Item::Enum(e) if visible(&e.vis).is_some() => {
                let n = e.ident.to_string();
                if !e.generics.params.is_empty() {
                    skip(&n, "generic enum".into());
                    continue;
                }
                let recs: Result<Vec<Record>, String> =
                    e.variants.iter().map(|v| Ok(Record { name: v.ident.to_string(), fields: fields(&v.fields)? })).collect();
                match recs {
                    Ok(records) => out.types.push((n.clone(), TypeDef::Union { rust: format!("{prefix}{n}"), is_struct: false, records })),
                    Err(er) => skip(&n, er),
                }
            }
            Item::Type(t) if visible(&t.vis).is_some() => {
                let n = t.ident.to_string();
                if record_name.values().any(|r| *r == n) || !t.generics.params.is_empty() {
                    continue;
                }
                match map_ty(&t.ty, &sc) {
                    Ok(ty) => out.types.push((n, TypeDef::Alias(ty))),
                    Err(e) => skip(&n, e),
                }
            }
            Item::Const(c) if visible(&c.vis).is_some() => match map_ty(&c.ty, &sc) {
                Ok(ty) => {
                    let access = if matches!(&*c.ty, Type::Reference(_)) && ty == Ty::String { ConstAccess::Str } else { ConstAccess::Value };
                    out.constants.push((c.ident.to_string(), Constant { rust: c.ident.to_string(), ty, access }))
                }
                Err(e) => skip(&c.ident.to_string(), e),
            },
            Item::Static(c) if visible(&c.vis).is_some() => {
                let lazy = matches!(&*c.ty, Type::Path(p) if p.path.segments.last().is_some_and(|s| s.ident == "LazyLock"));
                match map_ty(&c.ty, &sc) {
                    Ok(ty) => out.constants.push((
                        c.ident.to_string(),
                        Constant { rust: c.ident.to_string(), ty, access: if lazy { ConstAccess::Deref } else { ConstAccess::Value } },
                    )),
                    Err(e) => skip(&c.ident.to_string(), e),
                }
            }
            Item::Fn(f) => {
                let Some(public) = visible(&f.vis) else { continue };
                let rust = f.sig.ident.to_string();
                let n = unraw(&rust);
                let tyvars: Vec<String> = f.sig.generics.type_params().map(|p| p.ident.to_string()).collect();
                let fsc = Scope { pkg, tyvars: tyvars.iter().cloned().collect(), mods: &mods, uses: &uses };
                let (ret, fallible) = match &f.sig.output {
                    ReturnType::Default => (None, false),
                    ReturnType::Type(_, t) => match &**t {
                        Type::Path(p) if p.path.segments.last().is_some_and(|l| l.ident == "Result") => {
                            match generic_args(p.path.segments.last().unwrap()).as_slice() {
                                [a] => (Some(*a), true),
                                _ => (Some(&**t), false),
                            }
                        }
                        t => (Some(t), false),
                    },
                };
                let outs: Result<Vec<Ty>, String> = match ret {
                    None => Ok(vec![]),
                    Some(Type::Tuple(tp)) => tp.elems.iter().map(|e| map_ty(e, &fsc)).collect(),
                    Some(t) => map_ty(t, &fsc).map(|t| vec![t]),
                };
                let params: Result<Vec<Param>, String> = f
                    .sig
                    .inputs
                    .iter()
                    .map(|a| match a {
                        FnArg::Typed(pt) => {
                            let name = match &*pt.pat {
                                syn::Pat::Ident(i) => unraw(&i.ident.to_string()),
                                _ => "_".into(),
                            };
                            let borrowed = matches!(&*pt.ty, Type::Reference(_) | Type::ImplTrait(_));
                            Ok(Param { name, ty: map_ty(&pt.ty, &fsc)?, borrowed })
                        }
                        FnArg::Receiver(_) => Err("method".into()),
                    })
                    .collect();
                match (params, outs) {
                    (Ok(params), Ok(outs)) => {
                        if params.is_empty() && outs.len() == 1 && (f.sig.constness.is_some() || reads_thread_local(f)) {
                            out.constants.push((n, Constant { rust, ty: outs[0].clone(), access: ConstAccess::Call }));
                        } else {
                            out.functions.push((n, Function { rust, tyvars, params, outs, fallible, public }));
                        }
                    }
                    (Err(e), _) | (_, Err(e)) => skip(&n, e),
                }
            }
            Item::Mod(m) if visible(&m.vis).is_some() => {
                let mn = m.ident.to_string();
                if let Some((_, inner)) = &m.content {
                    let mut sub = Collected::default();
                    collect(inner, pkg, &format!("{prefix}{mn}::"), &uses, &mods, &mut sub, skipped);
                    for (n, t) in sub.types {
                        if n == mn {
                            out.types.push((n, t));
                        }
                    }
                }
            }
            _ => {}
        }
    }
    skipped.extend(own_skips);
}

/// The MetaModelica builtins: every top-level `pub fn` of the `metamodelica`
/// crate, which generated code reaches through `use metamodelica::*`.
pub fn extract_builtins(root: &Path, report: &mut Vec<String>) -> Package {
    fn walk(d: &Path, out: &mut Vec<PathBuf>) {
        let Ok(rd) = std::fs::read_dir(d) else { return };
        let mut es: Vec<PathBuf> = rd.flatten().map(|e| e.path()).collect();
        es.sort();
        for p in es {
            if p.is_dir() {
                walk(&p, out);
            } else if p.extension().is_some_and(|e| e == "rs") {
                out.push(p);
            }
        }
    }
    let mut files = vec![];
    walk(&root.join("metamodelica").join("src"), &mut files);
    let mut col = Collected::default();
    let mut skipped = vec![];
    for f in files {
        let Ok(code) = std::fs::read_to_string(&f) else { continue };
        match syn::parse_file(&code) {
            Ok(file) => {
                let fns: Vec<Item> = file.items.into_iter().filter(|i| matches!(i, Item::Fn(_))).collect();
                collect(&fns, "builtin", "", &HashMap::new(), &HashSet::new(), &mut col, &mut skipped);
            }
            Err(e) => report.push(format!("{}: parse error {e}", f.display())),
        }
    }
    let mut pkg = Package { krate: "metamodelica".into(), ..Default::default() };
    for (n, f) in col.functions {
        if f.public {
            pkg.functions.entry(n).or_insert(f);
        }
    }
    pkg
}

fn count_boxing(t: &Ty, inside_ref: bool, counts: &mut BTreeMap<String, (u32, u32)>) {
    match t {
        Ty::Ref(t) => count_boxing(t, true, counts),
        Ty::Named(n) => {
            let c = counts.entry(n.clone()).or_default();
            if inside_ref { c.0 += 1 } else { c.1 += 1 }
        }
        Ty::List(t) | Ty::Option(t) | Ty::Array(t) => count_boxing(t, false, counts),
        Ty::Tuple(ts) | Ty::Generic(_, ts) => ts.iter().for_each(|t| count_boxing(t, false, counts)),
        _ => {}
    }
}

/// Indexes `packages`. Returns the index and a report of the items that could
/// not be represented.
pub fn extract(files: &SourceFiles, packages: &[String]) -> (Index, Vec<String>) {
    let mut idx = Index::default();
    let mut report = Vec::new();
    let mut names: Vec<&String> = packages.iter().collect();
    names.sort();
    names.dedup();
    for name in names {
        let Some((krate, paths)) = files.packages.get(name) else { continue };
        let mut col = Collected::default();
        for f in paths {
            let code = match std::fs::read_to_string(f) {
                Ok(c) => c,
                Err(e) => {
                    report.push(format!("{}: {e}", f.display()));
                    continue;
                }
            };
            match syn::parse_file(&code) {
                Ok(file) => collect(&file.items, name, "", &HashMap::new(), &HashSet::new(), &mut col, &mut report),
                Err(e) => report.push(format!("{}: parse error {e}", f.display())),
            }
        }
        let mut pkg = Package { krate: krate.clone(), ..Default::default() };
        for (n, t) in col.types {
            pkg.types.entry(n).or_insert(t);
        }
        for (n, f) in col.functions {
            pkg.functions.entry(n).or_insert(f);
        }
        for (n, c) in col.constants {
            pkg.constants.entry(n).or_insert(c);
        }
        idx.packages.insert(name.clone(), pkg);
    }
    let mut counts = BTreeMap::new();
    for p in idx.packages.values() {
        for t in p.types.values() {
            match t {
                TypeDef::Union { records, .. } => records.iter().flat_map(|r| &r.fields).for_each(|f| count_boxing(&f.ty, false, &mut counts)),
                TypeDef::Alias(t) => count_boxing(t, false, &mut counts),
            }
        }
        for f in p.functions.values() {
            f.params.iter().for_each(|a| count_boxing(&a.ty, false, &mut counts));
            f.outs.iter().for_each(|t| count_boxing(t, false, &mut counts));
        }
        for c in p.constants.values() {
            count_boxing(&c.ty, false, &mut counts);
        }
    }
    for (n, (boxed, unboxed)) in counts {
        if boxed > 0 && unboxed > 0 {
            report.push(format!("{n}: held both boxed ({boxed}) and unboxed ({unboxed})"));
        }
        idx.boxed.insert(n, boxed > unboxed);
    }
    (idx, report)
}
