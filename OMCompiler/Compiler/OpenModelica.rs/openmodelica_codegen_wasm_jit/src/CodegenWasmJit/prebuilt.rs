//! Prebuilt wasm modules for external "C" code, built per library by the package
//! manager from what `getExternalFunctions` describes, and installed into
//! `<library>/Resources/Library/wasm32-wasip1/omc-<generation>`:
//!
//! ```text
//! omc-externals.json  functions -> module, library aliases
//! *.wasm              modules for `Include` sources and `Library` annotations
//! <name>/             system libraries shared with other libraries
//! ```
//!
//! A generation is everything the package manager built with one toolchain and
//! libc. Several can be installed at once; a model takes the newest one all its
//! libraries have, and never mixes them.

use super::*;
use serde_json::Value;

pub(crate) const PREBUILT_ABI: i64 = openmodelica_wasm_jit::dylink::PREBUILT_ABI as i64;
pub(crate) use openmodelica_wasm_jit::dylink::{generation_of, BUNDLE_MANIFEST as MANIFEST, GENERATION_PREFIX};
const BUNDLE_DIR: &str = "Resources/Library/wasm32-wasip1";

/// The `ModelicaUtilities.h` functions both simulation hosts serve a library as
/// host imports.
pub(crate) const HOST_UTILITIES: [&str; 13] = [
    "ModelicaMessage",
    "ModelicaWarning",
    "ModelicaError",
    "ModelicaFormatMessage",
    "ModelicaFormatWarning",
    "ModelicaFormatError",
    "ModelicaVFormatMessage",
    "ModelicaVFormatWarning",
    "ModelicaVFormatError",
    "ModelicaAllocateString",
    "ModelicaAllocateStringWithErrorReturn",
    "ModelicaDuplicateString",
    "ModelicaDuplicateStringWithErrorReturn",
];

fn path_string(p: &openmodelica_ast::Absyn::Path) -> String {
    use openmodelica_ast::Absyn::Path as P;
    match p {
        P::IDENT { name } => name.to_string(),
        P::QUALIFIED { name, path } => format!("{name}.{}", path_string(path)),
        P::FULLYQUALIFIED { path } => path_string(path),
    }
}

fn read_manifest(path: &str) -> Option<Value> {
    serde_json::from_slice(&openmodelica_wasi::fs::read(path).ok()?).ok()
}

/// The generations installed in a `wasm32-wasip1` library directory.
fn generations(dir: &str) -> Vec<u64> {
    let dir = dir.trim_end_matches('/');
    let Ok(entries) = openmodelica_wasi::fs::read_dir(dir) else { return Vec::new() };
    entries
        .into_iter()
        .filter(|e| e.is_dir)
        .filter_map(|e| generation_of(&e.name))
        .filter(|g| openmodelica_wasi::fs::exists(&format!("{dir}/{GENERATION_PREFIX}{g}/{MANIFEST}")))
        .collect()
}

/// The newest generation every library with bundles among `lib_dirs` has.
/// `Err` when they have none in common.
pub(crate) fn bundle_generation<'a>(lib_dirs: impl IntoIterator<Item = &'a str>) -> std::result::Result<Option<u64>, String> {
    let mut common: Option<Vec<u64>> = None;
    for dir in lib_dirs {
        if !dir.trim_end_matches('/').ends_with("wasm32-wasip1") {
            continue;
        }
        let gens = generations(dir);
        if gens.is_empty() {
            continue;
        }
        common = Some(match common {
            None => gens,
            Some(c) => c.into_iter().filter(|g| gens.contains(g)).collect(),
        });
    }
    match common {
        None => Ok(None),
        Some(c) => c.into_iter().max().map(Some).ok_or_else(|| {
            "the prebuilt wasm modules installed for these libraries are of different generations; \
             upgrade the packages (upgradeInstalledPackages)"
                .to_string()
        }),
    }
}

/// The bundle of generation `generation` installed beside the library `file` belongs to,
/// as (bundle directory, manifest).
fn manifest_for(file: &str, generation: u64) -> Option<(String, Value)> {
    let mut dir = std::path::Path::new(file).parent();
    while let Some(d) = dir {
        let bundle = format!("{}/{BUNDLE_DIR}/{GENERATION_PREFIX}{generation}", d.display());
        if let Some(manifest) = read_manifest(&format!("{bundle}/{MANIFEST}")) {
            return Some((bundle, manifest));
        }
        dir = d.parent();
    }
    None
}

/// What a manifest in `dir` names `Library="name"` as: a system library the
/// bundle shares with others, and the `NAME=value` environment it needs. Both
/// are relative to `dir`.
pub(crate) fn library_alias(dir: &str, name: &str) -> Option<(String, Vec<String>)> {
    let manifest = read_manifest(&format!("{dir}{MANIFEST}"))?;
    let alias = manifest.get("libraries")?.get(name)?;
    let module = alias.get("module")?.as_str()?;
    let env = alias
        .get("environment")
        .and_then(Value::as_object)
        .map(|e| e.iter().filter_map(|(k, v)| Some(format!("{k}={dir}{}", v.as_str()?))).collect())
        .unwrap_or_default();
    Some((format!("{dir}{module}"), env))
}

/// The prebuilt modules of generation `generation` holding the `Include` sources of `fns`
/// that `missing` still needs, or that override ModelicaExternalC's `usertab`
/// (`hook`). A mismatched module is caught when its wrapper is bound.
pub(crate) fn prebuilt_include_libraries(
    fns: &[&SimCodeFunction::Function::Function],
    missing: &[ExtCallSig],
    hook: bool,
    generation: Option<u64>,
    notes: &mut Vec<String>,
) -> Vec<ExtLibrary> {
    let Some(generation) = generation else { return Vec::new() };
    let missing: HashMap<&str, &ExtCallSig> = missing.iter().map(|s| (s.name.as_str(), s)).collect();
    let mut out: Vec<ExtLibrary> = Vec::new();
    for f in fns {
        let SimCodeFunction::Function::Function::EXTERNAL_FUNCTION { name, includes, info, .. } = f else { continue };
        let Ok(sig) = external_import_sig(f) else { continue };
        let usertab = hook && includes.iter().any(|s| s.contains("usertab"));
        if includes.is_empty() || (!missing.contains_key(sig.name.as_str()) && !usertab) {
            continue;
        }
        let path = path_string(name);
        let Some((bundle, manifest)) = manifest_for(&info.fileName, generation) else {
            notes.push(format!("no prebuilt wasm modules are installed for the library of `{path}`"));
            continue;
        };
        let sources = includes.iter().map(|s| s.as_str()).collect::<Vec<_>>().join("\n");
        // A function declared inside a model is named after the component there.
        let entry = manifest.get("functions").and_then(|m| {
            m.get(&path).or_else(|| {
                m.as_object()?.values().find(|e| {
                    e.get("name").and_then(Value::as_str) == Some(sig.name.as_str())
                        && e.get("includes").and_then(Value::as_str) == Some(sources.as_str())
                })
            })
        });
        let Some(entry) = entry else {
            let why = manifest.get("failed").and_then(|m| m.get(&path)).and_then(Value::as_str);
            notes.push(match why {
                Some(why) => format!("`{path}` has no prebuilt wasm module: {why}"),
                None => format!("`{path}` has no prebuilt wasm module in {bundle}"),
            });
            continue;
        };
        let Some(module) = entry.get("module").and_then(Value::as_str) else { continue };
        let file = format!("{bundle}/{module}");
        if out.iter().any(|l| l.name == file) {
            continue;
        }
        match openmodelica_wasi::fs::read(&file) {
            Ok(bytes) => out.push(ExtLibrary { name: file, bytes, fixed: true }),
            Err(_) => notes.push(format!("the prebuilt wasm module {file} for `{path}` is missing")),
        }
    }
    out
}

