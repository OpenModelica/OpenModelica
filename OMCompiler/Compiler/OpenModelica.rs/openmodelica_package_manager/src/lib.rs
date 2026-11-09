//! Chooses the versions of Modelica libraries to load or install for a set
//! of `uses` requirements, with a SAT solver (resolvo). Shared by the C omc
//! (through runtime/rust), the Rust omc and the web build.

mod library_metadata;
mod manager;
mod scan;
mod solve;
pub use openmodelica_version as version;

use std::borrow::Cow;
use std::collections::BTreeMap;
use std::hash::{DefaultHasher, Hash, Hasher};
use std::sync::Arc;

use serde::{Deserialize, Deserializer, Serialize};
use serde_json::Value;
use serde_json::value::RawValue;

#[cfg(target_arch = "wasm32")]
pub use openmodelica_download::take_pending as take_pending_downloads;
pub use solve::resolve;

/// The package index (`index.json`), as far as it matters here. Fields of
/// an unexpected type are left out instead of failing the whole problem.
#[derive(Default, Debug)]
pub struct Index {
    pub libs: BTreeMap<String, IndexLibrary>,
    /// A hash of the JSON text, or 0; caches what is computed from it.
    pub key: u64,
    /// The whole index, for installing.
    pub raw: Value,
}

#[derive(Default, Debug)]
pub struct IndexLibrary {
    /// Stands in for a library of another tool; any version matches.
    pub any_version: bool,
    pub versions: BTreeMap<String, Facts>,
}

#[derive(Default, Clone, Debug)]
pub struct Facts {
    pub uses: BTreeMap<String, String>,
    pub provides: Vec<String>,
    pub support: Option<String>,
}

pub(crate) fn string_map(v: &Value) -> BTreeMap<String, String> {
    v.as_object()
        .map(|o| {
            o.iter()
                .filter_map(|(k, v)| Some((k.clone(), v.as_str()?.to_owned())))
                .collect()
        })
        .unwrap_or_default()
}

fn strings(v: &Value) -> Vec<String> {
    v.as_array()
        .map(|a| a.iter().filter_map(|v| Some(v.as_str()?.to_owned())).collect())
        .unwrap_or_default()
}

pub(crate) fn string(v: &Value) -> Option<String> {
    v.as_str().map(str::to_owned)
}

impl From<&Value> for Facts {
    fn from(v: &Value) -> Facts {
        Facts {
            uses: string_map(&v["uses"]),
            provides: strings(&v["provides"]),
            support: string(&v["support"]),
        }
    }
}

impl<'de> Deserialize<'de> for Index {
    fn deserialize<D: Deserializer<'de>>(d: D) -> Result<Index, D::Error> {
        let v = Value::deserialize(d)?;
        let libs = v["libs"].as_object().map_or_else(BTreeMap::new, |libs| {
            libs.iter()
                .map(|(name, lib)| {
                    let versions = lib["versions"]
                        .as_object()
                        .map(|vs| vs.iter().map(|(k, v)| (k.clone(), Facts::from(v))).collect())
                        .unwrap_or_default();
                    let any_version = lib["anyVersion"].as_bool().unwrap_or(false);
                    (name.clone(), IndexLibrary { any_version, versions })
                })
                .collect()
        });
        Ok(Index { libs, key: 0, raw: v })
    }
}

/// An index given in the problem itself, as the tests do.
fn inline_index<'de, D: Deserializer<'de>>(d: D) -> Result<Option<Arc<Index>>, D::Error> {
    let raw = Box::<RawValue>::deserialize(d)?;
    let mut h = DefaultHasher::new();
    raw.get().hash(&mut h);
    let mut index: Index = serde_json::from_str(raw.get()).map_err(serde::de::Error::custom)?;
    index.key = h.finish() | 1;
    Ok(Some(Arc::new(index)))
}

fn some_string_map<'de, D: Deserializer<'de>>(d: D) -> Result<Option<BTreeMap<String, String>>, D::Error> {
    Ok(Some(string_map(&Value::deserialize(d)?)))
}

fn some_strings<'de, D: Deserializer<'de>>(d: D) -> Result<Option<Vec<String>>, D::Error> {
    Ok(Some(strings(&Value::deserialize(d)?)))
}

fn lenient_string<'de, D: Deserializer<'de>>(d: D) -> Result<Option<String>, D::Error> {
    Ok(string(&Value::deserialize(d)?))
}

/// A library version on disk (MODELICAPATH). Facts that are missing are
/// taken from the index entry of the same version.
#[derive(Deserialize, Default, Debug, Hash)]
#[serde(default)]
pub struct Installed {
    pub name: String,
    pub version: String,
    pub path: Option<String>,
    /// Where a library found in the MODELICAPATH is: the entry and
    /// the name of its directory or file in it.
    #[serde(skip)]
    pub modelica_path_index: Option<usize>,
    #[serde(skip)]
    pub file: Option<String>,
    #[serde(deserialize_with = "some_string_map")]
    pub uses: Option<BTreeMap<String, String>>,
    #[serde(deserialize_with = "some_strings")]
    pub provides: Option<Vec<String>>,
    #[serde(deserialize_with = "lenient_string")]
    pub support: Option<String>,
}

#[derive(Deserialize, Default, Debug, Hash)]
#[serde(default)]
pub struct Loaded {
    pub name: String,
    pub version: String,
}

#[derive(Deserialize, Default, Debug)]
#[serde(default)]
pub struct Requirement {
    pub name: String,
    /// `""` for any version.
    pub version: String,
    /// Versions to try in order, in place of `version`: the first one that
    /// an available version satisfies.
    pub versions: Vec<String>,
    pub exact: bool,
    /// Who asks, for the messages.
    pub origin: String,
}

#[derive(Deserialize, Default, Debug)]
#[serde(default, rename_all = "camelCase")]
pub struct Problem {
    #[serde(deserialize_with = "inline_index")]
    pub index: Option<Arc<Index>>,
    pub installed: Vec<Installed>,
    pub loaded: Vec<Loaded>,
    pub requirements: Vec<Requirement>,
    /// Choose from the index as well, not only from the installed versions.
    pub install: bool,
    /// Prefer the exact version for the uses of the chosen libraries.
    pub exact_uses: bool,
    /// Only list the versions the first requirement can use, best first.
    pub versions: bool,
}

#[derive(Serialize, Debug, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct Selected {
    pub name: String,
    pub version: String,
    pub path: Option<String>,
    pub installed: bool,
    /// For a version found in the MODELICAPATH: the entry, and the
    /// name of its directory or file in it.
    pub modelica_path_index: Option<usize>,
    pub file: Option<String>,
    pub loaded: bool,
    /// The first requirement on the library.
    pub origin: String,
}

#[derive(Serialize, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
#[serde(rename_all = "camelCase")]
pub enum MessageKind {
    /// No version of the library is available that can be used.
    Missing,
    /// The chosen (often already loaded) version is not compatible.
    Incompatible,
    /// Nothing knows the requested version; another version was chosen.
    UnknownVersion,
    /// No compatible version is available; a development branch was chosen.
    BranchFallback,
}

#[derive(Serialize, Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub struct Message {
    pub kind: MessageKind,
    pub name: String,
    pub version: String,
    pub selected: Option<String>,
    pub origin: String,
}

#[derive(Serialize, Debug, Default)]
#[serde(rename_all = "camelCase")]
pub struct Solution {
    pub ok: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
    pub selected: Vec<Selected>,
    pub messages: Vec<Message>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub versions: Vec<String>,
}

/// Makes the escapes of omc's `System.escapedString` valid JSON: `\a` and
/// `\v`, and control characters in strings. Copies only if it must.
fn sanitize(json: &str) -> Cow<'_, str> {
    let bytes = json.as_bytes();
    let mut out: Option<String> = None;
    let (mut last, mut i, mut in_string) = (0, 0, false);
    while i < bytes.len() {
        let fix = match bytes[i] {
            b'"' => {
                in_string = !in_string;
                None
            }
            b'\\' if in_string => match bytes.get(i + 1) {
                Some(b'a') => Some(("\\u0007".to_owned(), 2)),
                Some(b'v') => Some(("\\u000b".to_owned(), 2)),
                _ => {
                    i += 2;
                    continue;
                }
            },
            b if in_string && b < 0x20 => Some((format!("\\u{b:04x}"), 1)),
            _ => None,
        };
        match fix {
            Some((escape, len)) => {
                let o = out.get_or_insert_with(|| String::with_capacity(json.len()));
                o.push_str(&json[last..i]);
                o.push_str(&escape);
                i += len;
                last = i;
            }
            None => i += 1,
        }
    }
    match out {
        Some(mut o) => {
            o.push_str(&json[last..]);
            Cow::Owned(o)
        }
        None => Cow::Borrowed(json),
    }
}

fn arg_str<'v>(request: &'v Value, key: &str) -> &'v str {
    request[key].as_str().unwrap_or_default()
}

fn arg_bool(request: &Value, key: &str) -> bool {
    request[key].as_bool().unwrap_or(false)
}

/// The package manager, for omc: `request` is a JSON object with the
/// operation `op`, the [`manager::Env`] and the operation's arguments. The
/// response has `ok`, the results and the `messages` to report.
pub fn call(request: &str) -> String {
    let request: Value = match serde_json::from_str(&sanitize(request)) {
        Ok(v) => v,
        Err(e) => return serde_json::json!({"ok": false, "error": e.to_string(), "messages": []}).to_string(),
    };
    let env: manager::Env = serde_json::from_value(request.clone()).unwrap_or_default();
    let mut m = manager::Manager::new(&env);
    let abi = request["wasmAbi"].as_i64().unwrap_or(0);
    let print_error = arg_bool(&request, "printError");
    let mut response = match arg_str(&request, "op") {
        "resolve" => resolve_request(&mut m, &request),
        "libraryPath" => library_path(&m, &request),
        "versions" => {
            serde_json::json!({"ok": true, "versions": m.versions(arg_str(&request, "name"), arg_str(&request, "version"), print_error)})
        }
        "convertFrom" => serde_json::json!({"ok": true,
            "versions": m.conversions_from(arg_str(&request, "name"), arg_str(&request, "version"), print_error)}),
        "convertTo" => serde_json::json!({"ok": true,
            "versions": m.conversions_to(arg_str(&request, "name"), arg_str(&request, "version"), print_error)}),
        "installPackage" => {
            let (ok, dirs) = m.install_package(
                arg_str(&request, "pkg"),
                arg_str(&request, "version"),
                arg_bool(&request, "exactMatch"),
                arg_bool(&request, "skipDownload"),
                abi,
            );
            serde_json::json!({"ok": ok, "wasmDirs": dirs})
        }
        "installCached" => {
            m.install_cached();
            serde_json::json!({"ok": true})
        }
        "updateIndex" => serde_json::json!({"ok": m.update_index()}),
        "upgrade" => serde_json::json!({"ok": m.upgrade(arg_bool(&request, "newest"), abi)}),
        "installedLibraries" => {
            serde_json::json!({"ok": true, "libraries": m.installed_versions().into_keys().collect::<Vec<_>>()})
        }
        "installedVersions" => match m.installed_versions().remove(arg_str(&request, "name")) {
            Some(versions) => {
                let versions: Vec<String> = versions
                    .iter()
                    .rev()
                    .map(|v| version::canonical(v))
                    .filter(|v| !v.is_empty())
                    .collect();
                serde_json::json!({"ok": true, "versions": versions})
            }
            None => serde_json::json!({"ok": false, "versions": []}),
        },
        "missingWasmOfLoaded" => {
            let files: Vec<String> = strings(&request["files"]);
            serde_json::json!({"ok": true, "wasmDirs": m.missing_wasm_of_loaded(&files, abi)})
        }
        "wasmToolchain" => serde_json::json!({"ok": true, "sysroot": m.wasm_toolchain(arg_bool(&request, "cxx"))}),
        op => serde_json::json!({"ok": false, "error": format!("Unknown package manager operation {op}.")}),
    };
    response["messages"] = serde_json::to_value(&m.notes).expect("notes serialize");
    response.to_string()
}

/// The installed version of `name` that loading `version` of it would
/// choose, without its uses: where it is in `searchPath`.
fn library_path(m: &manager::Manager, request: &Value) -> Value {
    let modelica_path = m.modelica_path(request["searchPath"].as_str().unwrap_or(&m.env().modelica_path));
    let name = arg_str(request, "name");
    let problem = Problem {
        installed: scan::libraries(&modelica_path, false),
        requirements: vec![Requirement {
            name: name.to_owned(),
            versions: vec![arg_str(request, "version").to_owned()],
            ..Default::default()
        }],
        ..Default::default()
    };
    match resolve(&problem).selected.into_iter().find(|s| s.name == name) {
        Some(s) => serde_json::json!({"ok": true, "modelicaPathIndex": s.modelica_path_index, "file": s.file,
            "modelicaPath": modelica_path}),
        None => serde_json::json!({"ok": false}),
    }
}

/// Fills in the uses and versions of the installed libraries without
/// package manager metadata that the requirements may reach, from `cache`;
/// the top-level files whose metadata is not known are added to `need`. A version known this way can equal one
/// found before; as in [`scan::libraries`], the later one is kept.
fn complete_metadata(problem: &mut Problem, cache: &library_metadata::Cache, need: &mut Vec<String>) {
    let mut queue: std::collections::VecDeque<String> = problem.requirements.iter().map(|r| r.name.clone()).collect();
    let mut seen = std::collections::HashSet::new();
    while let Some(name) = queue.pop_front() {
        if !seen.insert(name.clone()) {
            continue;
        }
        let index = problem.index.as_ref().and_then(|i| i.libs.get(&name));
        for inst in problem.installed.iter_mut().filter(|i| i.name == name) {
            if let Some(uses) = &inst.uses {
                queue.extend(uses.keys().cloned());
                continue;
            }
            if let Some(facts) = index.and_then(|l| l.versions.get(&inst.version)) {
                queue.extend(facts.uses.keys().cloned());
                continue;
            }
            let path = inst.path.clone().unwrap_or_default();
            let Some(top) = scan::top_file(&path, openmodelica_wasi::fs::is_dir(&path)) else {
                continue;
            };
            match cache.get(&top) {
                None => need.push(top),
                Some(None) => {}
                Some(Some(f)) => {
                    if inst.version.is_empty() {
                        inst.version = f.version;
                    }
                    queue.extend(f.uses.keys().cloned());
                    inst.uses = Some(f.uses);
                    inst.provides = Some(f.provides);
                }
            }
        }
    }
    let mut kept: Vec<Installed> = Vec::new();
    for inst in std::mem::take(&mut problem.installed).into_iter().rev() {
        let v = version::Version::parse(&inst.version);
        let same = |k: &Installed| {
            k.name == inst.name && version::compare(&version::Version::parse(&k.version), &v, true).is_eq()
        };
        if !kept.iter().any(same) {
            kept.push(inst);
        }
    }
    kept.reverse();
    problem.installed = kept;
}

/// Chooses versions to load (or with `install`, to install): the libraries
/// in `searchPath` (the MODELICAPATH by default) and those in the index. Only
/// `install` downloads a missing index. For a load, the metadata of
/// libraries the package manager did not install comes from `metadata` or
/// the cache; the response lists the files whose metadata is missing as
/// `needMetadata`, instead of a solution.
fn resolve_request(m: &mut manager::Manager, request: &Value) -> Value {
    let install = arg_bool(request, "install");
    let print_error = request["printError"].as_bool().unwrap_or(install);
    let modelica_path = m.modelica_path(request["searchPath"].as_str().unwrap_or(&m.env().modelica_path));
    let fields = ["requirements", "loaded", "install", "exactUses"];
    let problem = Value::Object(
        fields
            .iter()
            .filter_map(|k| Some((k.to_string(), request.get(*k)?.clone())))
            .collect(),
    );
    let mut problem: Problem = match serde_json::from_value(problem) {
        Ok(p) => p,
        Err(e) => return serde_json::json!({"ok": false, "error": format!("Invalid package resolution problem: {e}")}),
    };
    if let Some(file) = m.usable_index_file(print_error, install) {
        problem.index = scan::index_file(&file);
        if problem.index.is_none() && print_error {
            m.notes.push(manager::Note {
                name: "ERROR_PKG_INDEX_NOT_PARSED",
                tokens: vec![file.clone()],
                file: Some(file),
            });
        }
    }
    problem.installed.extend(scan::libraries(&modelica_path, true));
    if !install && !arg_bool(request, "withoutMetadata") {
        let cache = library_metadata::Cache::new(&m.env().home);
        let mut answered = std::collections::HashSet::new();
        for f in request["metadata"].as_array().into_iter().flatten() {
            if let Some(file) = f["file"].as_str() {
                cache.put(file, serde_json::from_value(f["metadata"].clone()).ok());
                answered.insert(file.to_owned());
            }
        }
        let mut need = Vec::new();
        complete_metadata(&mut problem, &cache, &mut need);
        need.retain(|f| !answered.contains(f));
        if !need.is_empty() {
            return serde_json::json!({"ok": true, "needMetadata": need});
        }
    }
    let solution = resolve(&problem);
    serde_json::json!({
        "ok": solution.ok,
        "error": solution.error,
        "selected": solution.selected,
        "resolveMessages": solution.messages,
        "modelicaPath": modelica_path,
    })
}
