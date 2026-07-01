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
//!
//! On top of the raw key/value store this crate also provides [`wasi`], a
//! `wasi_snapshot_preview1` view over the same store ([`wasi::WasiCtx`]). It is
//! the single filesystem surface the standalone wasm-jit *command* module and
//! the OMEdit worker file engine both speak, so the backing store can be
//! swapped without touching either client.

use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use std::time::Duration;

pub mod wasi;
pub mod fs;

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

/// The working directory used to resolve relative paths. Defaults to `/`.
/// `System.cd()` will eventually drive this (the wasm `set_current_dir` is a no-op),
/// so omc and OMEdit agree on one working directory.
fn cwd_store() -> &'static Mutex<String> {
    static CWD: OnceLock<Mutex<String>> = OnceLock::new();
    CWD.get_or_init(|| Mutex::new(String::from("/")))
}

/// Set the working directory used to resolve relative path keys.
pub fn set_cwd(dir: &str) {
    let n = normalize(dir);
    *cwd_store().lock().unwrap() = n;
}

/// The working directory relative path keys resolve against (default `/`).
pub fn cwd() -> String {
    cwd_store().lock().unwrap().clone()
}

/// Canonicalise a path key to an absolute, slash-normalised, dot-folded form:
/// backslashes → `/`, **relative paths resolve against the cwd** (default `/`),
/// repeated slashes collapse, and `.`/`..` segments fold. So a relative write
/// (`<model>_visual.xml`) and an absolute read (`/<model>_visual.xml`) map to the
/// same key, and `a//b/`, `a/b`, `a\b`, `/a/./b`, `/a/c/../b` all agree.
fn normalize(path: &str) -> String {
    let path = path.replace('\\', "/");
    // Relative paths are prefixed with the cwd; absolute paths stand alone.
    let base = if path.starts_with('/') {
        String::new()
    } else {
        cwd_store().lock().unwrap().clone()
    };
    let mut comps: Vec<&str> = Vec::new();
    for seg in base.split('/').chain(path.split('/')) {
        match seg {
            "" | "." => {}
            ".." => {
                comps.pop();
            }
            s => comps.push(s),
        }
    }
    let mut out = String::with_capacity(path.len() + base.len() + 1);
    for c in &comps {
        out.push('/');
        out.push_str(c);
    }
    if out.is_empty() {
        out.push('/');
    }
    out
}

// ──────────────────────────── writable store ─────────────────────────────────

/// A stored file: its bytes plus the wall-clock modification time, kept as a
/// `Duration` since the Unix epoch (clock-free to store; `Default` = the epoch).
#[derive(Default)]
struct Entry {
    data: Vec<u8>,
    mtime: Duration,
}

/// "Now" as a duration since the Unix epoch. `std::time::SystemTime::now()`
/// panics on wasm32-unknown-unknown, so the JS clock (`web-time`) is used there;
/// every other target (native, wasip1) uses the std wall clock.
fn now_since_epoch() -> Duration {
    #[cfg(target_arch = "wasm32")]
    {
        web_time::SystemTime::now().duration_since(web_time::SystemTime::UNIX_EPOCH).unwrap_or_default()
    }
    #[cfg(not(target_arch = "wasm32"))]
    {
        std::time::SystemTime::now().duration_since(std::time::SystemTime::UNIX_EPOCH).unwrap_or_default()
    }
}

/// Wall-clock time in nanoseconds since the Unix epoch (WASI `REALTIME`). Same
/// source as file mtimes, so a guest can compute a file's age consistently.
pub fn realtime_nanos() -> u64 {
    now_since_epoch().as_nanos() as u64
}

/// Monotonic time in nanoseconds since the first call (WASI `MONOTONIC`). Backed
/// by `Instant` (`performance.now` on web): high-resolution and never runs
/// backwards, unlike the wall clock — the right source for measuring elapsed time.
pub fn monotonic_nanos() -> u64 {
    #[cfg(target_arch = "wasm32")]
    use web_time::Instant;
    #[cfg(not(target_arch = "wasm32"))]
    use std::time::Instant;
    static START: OnceLock<Instant> = OnceLock::new();
    START.get_or_init(Instant::now).elapsed().as_nanos() as u64
}

fn store() -> &'static Mutex<HashMap<String, Entry>> {
    static STORE: OnceLock<Mutex<HashMap<String, Entry>>> = OnceLock::new();
    STORE.get_or_init(|| Mutex::new(HashMap::new()))
}

/// Write `bytes` to `path`, replacing any existing entry.
pub fn write(path: &str, bytes: Vec<u8>) {
    let mtime = now_since_epoch();
    store().lock().unwrap().insert(normalize(path), Entry { data: bytes, mtime });
}

/// Append `bytes` to `path`, creating it if absent.
pub fn append(path: &str, bytes: &[u8]) {
    let mtime = now_since_epoch();
    let mut s = store().lock().unwrap();
    let e = s.entry(normalize(path)).or_default();
    e.data.extend_from_slice(bytes);
    e.mtime = mtime;
}

/// Read `path`: an exact store entry wins, otherwise the embedded builtin whose
/// basename matches. Returns `None` if neither exists.
pub fn read(path: &str) -> Option<Vec<u8>> {
    if let Some(e) = store().lock().unwrap().get(&normalize(path)) {
        return Some(e.data.clone());
    }
    builtin_by_basename(basename(path)).map(|s| s.as_bytes().to_vec())
}

/// The modification time of `path` as a duration since the Unix epoch: a stored
/// file's last-write wall-clock time (the JS clock on the web target), the epoch
/// (`0`) for an immutable embedded builtin, `None` when neither exists. Drives
/// mtime-based caching ([`fs::modified`]) and the WASI `filestat` mtim field.
pub fn mtime(path: &str) -> Option<Duration> {
    if let Some(e) = store().lock().unwrap().get(&normalize(path)) {
        return Some(e.mtime);
    }
    builtin_by_basename(basename(path)).map(|_| Duration::ZERO)
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

#[cfg(test)]
mod normalize_tests {
    use super::normalize;
    #[test]
    fn resolves_and_folds() {
        assert_eq!(normalize("DoublePendulum_visual.xml"), "/DoublePendulum_visual.xml");
        assert_eq!(normalize("/DoublePendulum_visual.xml"), "/DoublePendulum_visual.xml");
        assert_eq!(normalize("a//b/"), "/a/b");
        assert_eq!(normalize("/a/./b"), "/a/b");
        assert_eq!(normalize("/a/c/../b"), "/a/b");
        assert_eq!(normalize("a\\b"), "/a/b");
        assert_eq!(normalize("/"), "/");
        assert_eq!(normalize(""), "/");
    }
}

#[cfg(test)]
mod mtime_tests {
    use super::{mtime, write};
    use std::time::Duration;

    #[test]
    fn records_write_time() {
        assert_eq!(mtime("/mt/missing"), None);
        write("/mt/a", b"1".to_vec());
        // A stored file reports a real wall-clock time (past the epoch); an
        // unchanged file keeps that stamp so the read cache hits.
        let t0 = mtime("/mt/a").unwrap();
        assert!(t0 > Duration::ZERO);
        assert_eq!(mtime("/mt/a"), Some(t0));
        // Embedded builtins are immutable: a stable stamp at the epoch.
        assert_eq!(mtime("ModelicaBuiltin.mo"), Some(Duration::ZERO));
    }
}
