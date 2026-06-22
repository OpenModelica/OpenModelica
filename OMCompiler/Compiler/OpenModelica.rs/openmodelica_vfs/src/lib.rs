//! In-memory virtual filesystem for the wasm build.
//!
//! `wasm32-unknown-unknown` has no OS filesystem, but the compiler still needs
//! to read the builtin Modelica/MetaModelica sources at startup (FBuiltin parses
//! `ModelicaBuiltin.mo`, `NFModelicaBuiltin.mo` and `MetaModelicaBuiltin.mo` from
//! `<installdir>/lib/omc/`) and to read/write scratch files while it runs. This
//! crate provides a process-global in-memory store plus the embedded builtin
//! sources, and the file-I/O entry points in `openmodelica_util::System` and
//! `openmodelica_ast::ParserExt` route through it on wasm.
//!
//! Lookups resolve in two steps: an exact match in the writable store first,
//! then — for reads/existence — a fallback on the file's *basename* against the
//! embedded builtins, so the canonical `<installdir>/lib/omc/ModelicaBuiltin.mo`
//! path resolves no matter what `OPENMODELICAHOME` the host seeds.
//!
//! The crate compiles on every target (it is a plain dependency) but the store
//! is only meant to be consulted on wasm; native builds keep using `std::fs`.

use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};

// ─────────────────────────── embedded builtins ───────────────────────────────

// The builtin .mo are embedded straight from their canonical locations in the
// Compiler tree (../../../{FrontEnd,NFFrontEnd}/ relative to this file) rather
// than copied into the crate — there must be exactly one copy of each.

/// `ModelicaBuiltin.mo` — the interactive scripting API + Modelica builtins
/// (`OpenModelica.Scripting.*`, `size`, `der`, …).
pub static MODELICA_BUILTIN: &str = include_str!("../../../FrontEnd/ModelicaBuiltin.mo");
/// `NFModelicaBuiltin.mo` — the new-frontend variant of the Modelica builtins.
pub static NF_MODELICA_BUILTIN: &str = include_str!("../../../NFFrontEnd/NFModelicaBuiltin.mo");
/// `MetaModelicaBuiltin.mo` — the MetaModelica builtin operators/types.
pub static META_MODELICA_BUILTIN: &str = include_str!("../../../FrontEnd/MetaModelicaBuiltin.mo");

/// The Modelica annotation programs, selected by the `--annotationVersion` flag
/// (default `3.x`); `modelicaAnnotationProgram` parses one of these during
/// instantiation.
pub static ANNOTATIONS_BUILTIN_1_X: &str = include_str!("../../../FrontEnd/AnnotationsBuiltin_1_x.mo");
pub static ANNOTATIONS_BUILTIN_2_X: &str = include_str!("../../../FrontEnd/AnnotationsBuiltin_2_x.mo");
pub static ANNOTATIONS_BUILTIN_3_X: &str = include_str!("../../../FrontEnd/AnnotationsBuiltin_3_x.mo");

/// The embedded builtin source for `name` (a bare basename), if any.
pub fn builtin_by_basename(name: &str) -> Option<&'static str> {
    match name {
        "ModelicaBuiltin.mo" => Some(MODELICA_BUILTIN),
        "NFModelicaBuiltin.mo" => Some(NF_MODELICA_BUILTIN),
        "MetaModelicaBuiltin.mo" => Some(META_MODELICA_BUILTIN),
        "AnnotationsBuiltin_1_x.mo" => Some(ANNOTATIONS_BUILTIN_1_X),
        "AnnotationsBuiltin_2_x.mo" => Some(ANNOTATIONS_BUILTIN_2_X),
        "AnnotationsBuiltin_3_x.mo" => Some(ANNOTATIONS_BUILTIN_3_X),
        _ => None,
    }
}

/// The last path component, splitting on either slash (paths reach us already
/// forward-slash-normalised, but be defensive about `\` too).
fn basename(path: &str) -> &str {
    path.rsplit(['/', '\\']).next().unwrap_or(path)
}

/// Canonicalise a path key: backslashes → `/`, collapse repeated slashes, and
/// drop any trailing slash (except for the root `/`). So `a//b/`, `a/b`, and
/// `a\b` all map to the same key — essential for prefix-based directory queries
/// when MODELICAPATH and the compiler concatenate paths with stray slashes.
fn normalize(path: &str) -> String {
    let mut out = String::with_capacity(path.len());
    let mut prev_slash = false;
    for c in path.chars() {
        let c = if c == '\\' { '/' } else { c };
        if c == '/' {
            if !prev_slash {
                out.push('/');
            }
            prev_slash = true;
        } else {
            out.push(c);
            prev_slash = false;
        }
    }
    if out.len() > 1 && out.ends_with('/') {
        out.pop();
    }
    out
}

// ──────────────────────────── writable store ─────────────────────────────────

fn store() -> &'static Mutex<HashMap<String, Vec<u8>>> {
    static STORE: OnceLock<Mutex<HashMap<String, Vec<u8>>>> = OnceLock::new();
    STORE.get_or_init(|| Mutex::new(HashMap::new()))
}

/// Write `bytes` to `path`, replacing any existing entry.
pub fn write(path: &str, bytes: Vec<u8>) {
    store().lock().unwrap().insert(normalize(path), bytes);
}

/// Append `bytes` to `path`, creating it if absent.
pub fn append(path: &str, bytes: &[u8]) {
    store()
        .lock()
        .unwrap()
        .entry(normalize(path))
        .or_default()
        .extend_from_slice(bytes);
}

/// Read `path`: an exact store entry wins, otherwise the embedded builtin whose
/// basename matches. Returns `None` if neither exists.
pub fn read(path: &str) -> Option<Vec<u8>> {
    if let Some(b) = store().lock().unwrap().get(&normalize(path)) {
        return Some(b.clone());
    }
    builtin_by_basename(basename(path)).map(|s| s.as_bytes().to_vec())
}

/// True when [`read`] would succeed for `path` (a stored file).
pub fn exists(path: &str) -> bool {
    store().lock().unwrap().contains_key(&normalize(path)) || builtin_by_basename(basename(path)).is_some()
}

/// True when `path` is a directory: some stored key lives under `path/`.
pub fn is_dir(path: &str) -> bool {
    let prefix = format!("{}/", normalize(path));
    store().lock().unwrap().keys().any(|k| k.starts_with(&prefix))
}

/// The immediate children of directory `dir`, as `(name, is_dir)` pairs (no
/// recursion, deduplicated). Empty when `dir` holds nothing.
pub fn list_dir(dir: &str) -> Vec<(String, bool)> {
    let prefix = format!("{}/", normalize(dir));
    let mut seen: std::collections::HashMap<String, bool> = std::collections::HashMap::new();
    for k in store().lock().unwrap().keys() {
        if let Some(rest) = k.strip_prefix(&prefix)
            && !rest.is_empty()
        {
            match rest.split_once('/') {
                Some((child, _)) => {
                    seen.insert(child.to_owned(), true);
                }
                None => {
                    seen.entry(rest.to_owned()).or_insert(false);
                }
            }
        }
    }
    seen.into_iter().collect()
}

/// Remove `path` from the writable store. Embedded builtins are immutable and
/// unaffected. Returns true if an entry was removed.
pub fn remove(path: &str) -> bool {
    store().lock().unwrap().remove(&normalize(path)).is_some()
}

/// Every path currently held in the writable store (excludes embedded builtins).
pub fn list() -> Vec<String> {
    store().lock().unwrap().keys().cloned().collect()
}

/// Number of files currently held in the writable store.
pub fn len() -> usize {
    store().lock().unwrap().len()
}
