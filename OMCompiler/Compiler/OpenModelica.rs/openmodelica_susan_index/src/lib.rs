//! The interface index Susan's Rust backend reads: for every package the
//! templates can reach, its crate, types, functions and constants, with the
//! Rust-level facts the Susan interface language has no words for (boxing,
//! borrowed parameters, fallibility, how a constant is read).

use std::collections::BTreeMap;

use serde_json::{Value, json};

pub mod extract;

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum Ty {
    Int,
    /// `metamodelica::Real`
    Real,
    /// a bare `f64`
    F64,
    Bool,
    String,
    Text,
    SourceInfo,
    Unit,
    FuncPtr,
    Ref(Box<Ty>),
    List(Box<Ty>),
    Option(Box<Ty>),
    Array(Box<Ty>),
    Tuple(Vec<Ty>),
    /// A package-qualified type, `DAE.Exp`.
    Named(String),
    /// A polymorphic type Susan can only pass along, `ExpandableArray.ExpandableArray<T>`.
    Generic(String, Vec<Ty>),
    TyVar(String),
}

#[derive(Clone, Debug)]
pub struct Field {
    pub name: String,
    pub rust: String,
    pub ty: Ty,
}

#[derive(Clone, Debug)]
pub struct Record {
    pub name: String,
    pub fields: Vec<Field>,
}

#[derive(Clone, Debug)]
pub enum TypeDef {
    /// `rust` is the path below the package module, e.g. `Exp` or `Variable::Variable`.
    Union {
        rust: String,
        is_struct: bool,
        records: Vec<Record>,
    },
    Alias(Ty),
}

#[derive(Clone, Debug)]
pub struct Param {
    pub name: String,
    pub ty: Ty,
    pub borrowed: bool,
}

#[derive(Clone, Debug)]
pub struct Function {
    pub rust: String,
    pub tyvars: Vec<String>,
    pub params: Vec<Param>,
    pub outs: Vec<Ty>,
    pub fallible: bool,
    pub public: bool,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ConstAccess {
    /// `name()`
    Call,
    /// `name` (a `const`)
    Value,
    /// `(*name).clone()` (a `LazyLock` static)
    Deref,
    /// `ArcStr::from(name)` (a `&'static str`)
    Str,
}

#[derive(Clone, Debug)]
pub struct Constant {
    pub rust: String,
    pub ty: Ty,
    pub access: ConstAccess,
}

#[derive(Clone, Debug, Default)]
pub struct Package {
    pub krate: String,
    pub types: BTreeMap<String, TypeDef>,
    pub functions: BTreeMap<String, Function>,
    pub constants: BTreeMap<String, Constant>,
}

#[derive(Clone, Debug, Default)]
pub struct Index {
    pub packages: BTreeMap<String, Package>,
    /// Named types that are held behind `metamodelica::Ref` as values.
    pub boxed: BTreeMap<String, bool>,
    /// The crate of every package found in the sources, indexed or not.
    pub crates: BTreeMap<String, String>,
}

impl Ty {
    pub fn strip_ref(&self) -> &Ty {
        match self {
            Ty::Ref(t) => t.strip_ref(),
            t => t,
        }
    }

    /// The type in Susan's interface syntax.
    pub fn susan(&self) -> String {
        match self {
            Ty::Int => "Integer".into(),
            Ty::Real | Ty::F64 => "Real".into(),
            Ty::Bool => "Boolean".into(),
            Ty::String => "String".into(),
            Ty::Text => "Tpl.Text".into(),
            Ty::SourceInfo => "builtin.SourceInfo".into(),
            Ty::Unit => "tuple<>".into(),
            Ty::FuncPtr => "builtin.FuncPtr".into(),
            Ty::Ref(t) => t.susan(),
            Ty::List(t) => format!("list<{}>", t.susan()),
            Ty::Option(t) => format!("Option<{}>", t.susan()),
            Ty::Array(t) => format!("array<{}>", t.susan()),
            Ty::Tuple(ts) => format!("tuple<{}>", ts.iter().map(Ty::susan).collect::<Vec<_>>().join(", ")),
            Ty::Named(n) | Ty::TyVar(n) | Ty::Generic(n, _) => n.clone(),
        }
    }

    pub fn to_json(&self) -> Value {
        let k = |k: &str| json!({ "k": k });
        let of = |k: &str, t: &Ty| json!({ "k": k, "of": t.to_json() });
        match self {
            Ty::Int => k("int"),
            Ty::Real => k("real"),
            Ty::F64 => k("f64"),
            Ty::Bool => k("bool"),
            Ty::String => k("string"),
            Ty::Text => k("text"),
            Ty::SourceInfo => k("sourceinfo"),
            Ty::Unit => k("unit"),
            Ty::FuncPtr => k("funcptr"),
            Ty::Ref(t) => of("ref", t),
            Ty::List(t) => of("list", t),
            Ty::Option(t) => of("option", t),
            Ty::Array(t) => of("array", t),
            Ty::Tuple(ts) => json!({ "k": "tuple", "of": ts.iter().map(Ty::to_json).collect::<Vec<_>>() }),
            Ty::Named(n) => json!({ "k": "named", "name": n }),
            Ty::Generic(n, ts) => {
                json!({ "k": "generic", "name": n, "of": ts.iter().map(Ty::to_json).collect::<Vec<_>>() })
            }
            Ty::TyVar(n) => json!({ "k": "tyvar", "name": n }),
        }
    }

    pub fn from_json(v: &Value) -> Option<Ty> {
        let of = || Ty::from_json(v.get("of")?).map(Box::new);
        Some(match v.get("k")?.as_str()? {
            "int" => Ty::Int,
            "real" => Ty::Real,
            "f64" => Ty::F64,
            "bool" => Ty::Bool,
            "string" => Ty::String,
            "text" => Ty::Text,
            "sourceinfo" => Ty::SourceInfo,
            "unit" => Ty::Unit,
            "funcptr" => Ty::FuncPtr,
            "ref" => Ty::Ref(of()?),
            "list" => Ty::List(of()?),
            "option" => Ty::Option(of()?),
            "array" => Ty::Array(of()?),
            "tuple" => Ty::Tuple(
                v.get("of")?
                    .as_array()?
                    .iter()
                    .map(Ty::from_json)
                    .collect::<Option<_>>()?,
            ),
            "named" => Ty::Named(v.get("name")?.as_str()?.into()),
            "generic" => Ty::Generic(
                v.get("name")?.as_str()?.into(),
                v.get("of")?
                    .as_array()?
                    .iter()
                    .map(Ty::from_json)
                    .collect::<Option<_>>()?,
            ),
            "tyvar" => Ty::TyVar(v.get("name")?.as_str()?.into()),
            _ => return None,
        })
    }
}

fn fields_json(fs: &[Field]) -> Value {
    fs.iter()
        .map(|f| json!({ "name": f.name, "rust": f.rust, "ty": f.ty.to_json() }))
        .collect()
}

impl Index {
    pub fn to_json(&self) -> Value {
        let mut pkgs = serde_json::Map::new();
        for (name, p) in &self.packages {
            let types: serde_json::Map<String, Value> = p
                .types
                .iter()
                .map(|(n, t)| {
                    let v = match t {
                        TypeDef::Union { rust, is_struct, records } => json!({
                            "kind": if *is_struct { "struct" } else { "union" },
                            "rust": rust,
                            "records": records.iter().map(|r| json!({ "name": r.name, "fields": fields_json(&r.fields) })).collect::<Vec<_>>(),
                        }),
                        TypeDef::Alias(t) => json!({ "kind": "alias", "ty": t.to_json() }),
                    };
                    (n.clone(), v)
                })
                .collect();
            let functions: serde_json::Map<String, Value> = p
                .functions
                .iter()
                .map(|(n, f)| {
                    (
                        n.clone(),
                        json!({
                            "rust": f.rust,
                            "tyvars": f.tyvars,
                            "params": f.params.iter().map(|a| json!({ "name": a.name, "ty": a.ty.to_json(), "borrowed": a.borrowed })).collect::<Vec<_>>(),
                            "outs": f.outs.iter().map(Ty::to_json).collect::<Vec<_>>(),
                            "fallible": f.fallible,
                            "public": f.public,
                        }),
                    )
                })
                .collect();
            let constants: serde_json::Map<String, Value> = p
                .constants
                .iter()
                .map(|(n, c)| {
                    let access = match c.access {
                        ConstAccess::Call => "call",
                        ConstAccess::Value => "value",
                        ConstAccess::Deref => "deref",
                        ConstAccess::Str => "str",
                    };
                    (
                        n.clone(),
                        json!({ "rust": c.rust, "ty": c.ty.to_json(), "access": access }),
                    )
                })
                .collect();
            pkgs.insert(
                name.clone(),
                json!({ "crate": p.krate, "types": types, "functions": functions, "constants": constants }),
            );
        }
        json!({ "version": 1, "packages": pkgs, "boxed": self.boxed, "crates": self.crates })
    }

    pub fn from_json(v: &Value) -> Result<Index, String> {
        let err = |what: &str| format!("susan index: malformed {what}");
        let mut idx = Index::default();
        for (name, p) in v
            .get("packages")
            .and_then(Value::as_object)
            .ok_or_else(|| err("packages"))?
        {
            let mut pkg = Package {
                krate: p["crate"].as_str().ok_or_else(|| err("crate"))?.into(),
                ..Default::default()
            };
            let fields = |v: &Value| -> Result<Vec<Field>, String> {
                v.as_array()
                    .ok_or_else(|| err("fields"))?
                    .iter()
                    .map(|f| {
                        Ok(Field {
                            name: f["name"].as_str().ok_or_else(|| err("field name"))?.into(),
                            rust: f["rust"].as_str().ok_or_else(|| err("field rust"))?.into(),
                            ty: Ty::from_json(&f["ty"]).ok_or_else(|| err("field type"))?,
                        })
                    })
                    .collect()
            };
            for (n, t) in p["types"].as_object().ok_or_else(|| err("types"))? {
                let def = match t["kind"].as_str() {
                    Some("alias") => TypeDef::Alias(Ty::from_json(&t["ty"]).ok_or_else(|| err("alias"))?),
                    Some(k @ ("union" | "struct")) => TypeDef::Union {
                        rust: t["rust"].as_str().ok_or_else(|| err("type rust"))?.into(),
                        is_struct: k == "struct",
                        records: t["records"]
                            .as_array()
                            .ok_or_else(|| err("records"))?
                            .iter()
                            .map(|r| {
                                Ok(Record {
                                    name: r["name"].as_str().ok_or_else(|| err("record"))?.into(),
                                    fields: fields(&r["fields"])?,
                                })
                            })
                            .collect::<Result<_, String>>()?,
                    },
                    _ => return Err(err("type kind")),
                };
                pkg.types.insert(n.clone(), def);
            }
            for (n, f) in p["functions"].as_object().ok_or_else(|| err("functions"))? {
                let params = f["params"]
                    .as_array()
                    .ok_or_else(|| err("params"))?
                    .iter()
                    .map(|a| {
                        Ok(Param {
                            name: a["name"].as_str().ok_or_else(|| err("param"))?.into(),
                            ty: Ty::from_json(&a["ty"]).ok_or_else(|| err("param type"))?,
                            borrowed: a["borrowed"].as_bool().unwrap_or(false),
                        })
                    })
                    .collect::<Result<_, String>>()?;
                pkg.functions.insert(
                    n.clone(),
                    Function {
                        rust: f["rust"].as_str().ok_or_else(|| err("function rust"))?.into(),
                        tyvars: f["tyvars"]
                            .as_array()
                            .map(|a| a.iter().filter_map(|s| s.as_str().map(String::from)).collect())
                            .unwrap_or_default(),
                        params,
                        outs: f["outs"]
                            .as_array()
                            .ok_or_else(|| err("outs"))?
                            .iter()
                            .map(Ty::from_json)
                            .collect::<Option<_>>()
                            .ok_or_else(|| err("out type"))?,
                        fallible: f["fallible"].as_bool().unwrap_or(true),
                        public: f["public"].as_bool().unwrap_or(true),
                    },
                );
            }
            for (n, c) in p["constants"].as_object().ok_or_else(|| err("constants"))? {
                let access = match c["access"].as_str() {
                    Some("call") => ConstAccess::Call,
                    Some("value") => ConstAccess::Value,
                    Some("deref") => ConstAccess::Deref,
                    Some("str") => ConstAccess::Str,
                    _ => return Err(err("constant access")),
                };
                pkg.constants.insert(
                    n.clone(),
                    Constant {
                        rust: c["rust"].as_str().ok_or_else(|| err("constant rust"))?.into(),
                        ty: Ty::from_json(&c["ty"]).ok_or_else(|| err("constant type"))?,
                        access,
                    },
                );
            }
            idx.packages.insert(name.clone(), pkg);
        }
        if let Some(b) = v.get("boxed").and_then(Value::as_object) {
            idx.boxed = b.iter().filter_map(|(k, v)| Some((k.clone(), v.as_bool()?))).collect();
        }
        if let Some(c) = v.get("crates").and_then(Value::as_object) {
            idx.crates = c
                .iter()
                .filter_map(|(k, v)| Some((k.clone(), v.as_str()?.to_string())))
                .collect();
        }
        Ok(idx)
    }

    pub fn is_boxed(&self, named: &str) -> bool {
        self.boxed.get(named).copied().unwrap_or(false)
    }
}
