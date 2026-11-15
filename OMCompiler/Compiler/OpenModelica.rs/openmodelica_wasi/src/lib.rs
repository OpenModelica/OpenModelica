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

use std::collections::{BTreeMap, HashSet};
use std::ops::Bound;
use std::sync::{Mutex, MutexGuard, OnceLock};
use std::time::Duration;

pub mod env;
pub mod fs;
#[cfg(not(target_arch = "wasm32"))]
pub mod stdio;
pub mod wasi;

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

/// A stored file's bytes: in memory, or a byte range of a host segment file that
/// is read on demand through the [`SegmentReader`].
enum Data {
    Mem(Vec<u8>),
    Stored { seg: u32, off: u64, len: u64 },
}

/// A stored file: its bytes plus the wall-clock modification time, kept as a
/// `Duration` since the Unix epoch (clock-free to store; `Default` = the epoch).
struct Entry {
    data: Data,
    mtime: Duration,
}

impl Default for Entry {
    fn default() -> Self {
        Entry {
            data: Data::Mem(Vec::new()),
            mtime: Duration::ZERO,
        }
    }
}

impl Entry {
    fn len(&self) -> u64 {
        match &self.data {
            Data::Mem(b) => b.len() as u64,
            Data::Stored { len, .. } => *len,
        }
    }
}

/// Fill `buf` from byte `off` of host segment `seg`; false if it cannot.
pub type SegmentReader = fn(seg: u32, off: u64, buf: &mut [u8]) -> bool;

#[derive(Default)]
struct Store {
    files: BTreeMap<String, Entry>,
    /// `<root>/` of the persistent tree; changes below it are recorded in `dirty`.
    persist: Option<String>,
    /// Directories below the root whose own files are not persisted, as `<root>/<dir>/`.
    transient: Vec<String>,
    dirty: HashSet<String>,
    reader: Option<SegmentReader>,
    /// The files and removals of the last [`take_snapshot`], in snapshot order.
    snapshot: Vec<(String, Duration, u64)>,
    snapshot_removed: Vec<String>,
}

impl Store {
    fn touched(&mut self, key: &str) {
        let transient = self
            .transient
            .iter()
            .any(|t| key.strip_prefix(t.as_str()).is_some_and(|f| !f.contains('/')));
        if !transient && self.persist.as_deref().is_some_and(|p| key.starts_with(p)) {
            self.dirty.insert(key.to_owned());
        }
    }

    fn load(&self, seg: u32, off: u64, len: u64) -> Option<Vec<u8>> {
        let mut buf = vec![0u8; usize::try_from(len).ok()?];
        (self.reader?)(seg, off, &mut buf).then_some(buf)
    }

    /// The entry for `key` with its bytes in memory, created empty if absent.
    fn materialize(&mut self, key: &str) -> &mut Vec<u8> {
        let stored = match self.files.get(key).map(|e| &e.data) {
            Some(Data::Stored { seg, off, len }) => Some(self.load(*seg, *off, *len).unwrap_or_default()),
            _ => None,
        };
        let e = self.files.entry(key.to_owned()).or_default();
        if let Some(bytes) = stored {
            e.data = Data::Mem(bytes);
        }
        match &mut e.data {
            Data::Mem(b) => b,
            Data::Stored { .. } => unreachable!(),
        }
    }
}

/// "Now" as a duration since the Unix epoch. `std::time::SystemTime::now()`
/// panics on wasm32-unknown-unknown, so the JS clock (`web-time`) is used there;
/// every other target (native, wasip1) uses the std wall clock.
fn now_since_epoch() -> Duration {
    #[cfg(target_arch = "wasm32")]
    {
        web_time::SystemTime::now()
            .duration_since(web_time::SystemTime::UNIX_EPOCH)
            .unwrap_or_default()
    }
    #[cfg(not(target_arch = "wasm32"))]
    {
        std::time::SystemTime::now()
            .duration_since(std::time::SystemTime::UNIX_EPOCH)
            .unwrap_or_default()
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
    #[cfg(not(target_arch = "wasm32"))]
    use std::time::Instant;
    #[cfg(target_arch = "wasm32")]
    use web_time::Instant;
    static START: OnceLock<Instant> = OnceLock::new();
    START.get_or_init(Instant::now).elapsed().as_nanos() as u64
}

fn store() -> MutexGuard<'static, Store> {
    static STORE: OnceLock<Mutex<Store>> = OnceLock::new();
    STORE.get_or_init(Default::default).lock().unwrap()
}

/// Write `bytes` to `path`, replacing any existing entry.
pub fn write(path: &str, bytes: Vec<u8>) {
    let mtime = now_since_epoch();
    let key = normalize(path);
    let mut s = store();
    s.touched(&key);
    s.files.insert(
        key,
        Entry {
            data: Data::Mem(bytes),
            mtime,
        },
    );
}

/// Overwrite `bytes` at byte offset `pos` of `path`, extending it if short.
pub fn write_at(path: &str, pos: usize, bytes: &[u8]) {
    let mtime = now_since_epoch();
    let key = normalize(path);
    let mut s = store();
    s.touched(&key);
    let data = s.materialize(&key);
    let end = pos + bytes.len();
    if data.len() < end {
        data.resize(end, 0);
    }
    data[pos..end].copy_from_slice(bytes);
    s.files.get_mut(&key).unwrap().mtime = mtime;
}

/// Run `f` over the stored bytes of `path` without copying them; `None` if absent.
pub fn with_bytes<R>(path: &str, f: impl FnOnce(&[u8]) -> R) -> Option<R> {
    let s = store();
    match s.files.get(&normalize(path)) {
        Some(Entry { data: Data::Mem(b), .. }) => Some(f(b)),
        Some(Entry {
            data: Data::Stored { seg, off, len },
            ..
        }) => {
            let bytes = s.load(*seg, *off, *len)?;
            drop(s);
            Some(f(&bytes))
        }
        None => builtin_by_basename(basename(path)).map(|b| f(b.as_bytes())),
    }
}

/// Append `bytes` to `path`, creating it if absent.
pub fn append(path: &str, bytes: &[u8]) {
    let mtime = now_since_epoch();
    let key = normalize(path);
    let mut s = store();
    s.touched(&key);
    s.materialize(&key).extend_from_slice(bytes);
    s.files.get_mut(&key).unwrap().mtime = mtime;
}

/// Read `path`: an exact store entry wins, otherwise the embedded builtin whose
/// basename matches. Returns `None` if neither exists.
pub fn read(path: &str) -> Option<Vec<u8>> {
    let s = store();
    match s.files.get(&normalize(path)) {
        Some(Entry { data: Data::Mem(b), .. }) => Some(b.clone()),
        Some(Entry {
            data: Data::Stored { seg, off, len },
            ..
        }) => s.load(*seg, *off, *len),
        None => builtin_by_basename(basename(path)).map(|s| s.as_bytes().to_vec()),
    }
}

/// The size of `path` in bytes, without reading a stored file.
pub fn size(path: &str) -> Option<u64> {
    if let Some(e) = store().files.get(&normalize(path)) {
        return Some(e.len());
    }
    builtin_by_basename(basename(path)).map(|b| b.len() as u64)
}

/// The modification time of `path` as a duration since the Unix epoch: a stored
/// file's last-write wall-clock time (the JS clock on the web target), the epoch
/// (`0`) for an immutable embedded builtin, `None` when neither exists. Drives
/// mtime-based caching ([`fs::modified`]) and the WASI `filestat` mtim field.
pub fn mtime(path: &str) -> Option<Duration> {
    if let Some(e) = store().files.get(&normalize(path)) {
        return Some(e.mtime);
    }
    builtin_by_basename(basename(path)).map(|_| Duration::ZERO)
}

/// True when [`read`] would succeed for `path` (a stored file).
pub fn exists(path: &str) -> bool {
    store().files.contains_key(&normalize(path)) || builtin_by_basename(basename(path)).is_some()
}

fn starting_at(key: &str) -> (Bound<&str>, Bound<&str>) {
    (Bound::Included(key), Bound::Unbounded)
}

/// True when `path` is a directory: some stored key lives under `path/`.
pub fn is_dir(path: &str) -> bool {
    let prefix = format!("{}/", normalize(path));
    store()
        .files
        .range::<str, _>(starting_at(&prefix))
        .next()
        .is_some_and(|(k, _)| k.starts_with(&prefix))
}

/// The immediate children of directory `dir`, as `(name, is_dir)` pairs (no
/// recursion, deduplicated, sorted). Empty when `dir` holds nothing.
pub fn list_dir(dir: &str) -> Vec<(String, bool)> {
    let prefix = format!("{}/", normalize(dir));
    let s = store();
    let mut children: Vec<(String, bool)> = Vec::new();
    let mut next = prefix.clone();
    while let Some((key, _)) = s.files.range::<str, _>(starting_at(&next)).next() {
        let Some(rest) = key.strip_prefix(&prefix) else { break };
        match rest.split_once('/') {
            Some((child, _)) => {
                if children.last().is_some_and(|(name, _)| name == child) {
                    children.pop();
                }
                children.push((child.to_owned(), true));
                // '0' follows '/', so this skips the child's subtree.
                next = format!("{prefix}{child}0");
            }
            None => {
                children.push((rest.to_owned(), false));
                next = format!("{key}\0");
            }
        }
    }
    children
}

/// Remove `path` from the writable store. Embedded builtins are immutable and
/// unaffected. Returns true if an entry was removed.
pub fn remove(path: &str) -> bool {
    let key = normalize(path);
    let mut s = store();
    let removed = s.files.remove(&key).is_some();
    if removed {
        s.touched(&key);
    }
    removed
}

/// Every path currently held in the writable store (excludes embedded builtins).
pub fn list() -> Vec<String> {
    store().files.keys().cloned().collect()
}

/// Number of files currently held in the writable store.
pub fn len() -> usize {
    store().files.len()
}

// ───────────────────────────── persistence ───────────────────────────────────
//
// The host keeps the tree under one root in segment files of its own. It mounts
// their files at startup as stored entries, and after each command writes what
// changed under the root to a new segment: [`take_snapshot`], then [`commit`].

/// Record changes below `root` from now on, except to the files directly in one of
/// its `transient` subdirectories, and read stored files with `reader`.
pub fn set_persistent_root(root: &str, transient: &[&str], reader: SegmentReader) {
    let mut s = store();
    let root = format!("{}/", normalize(root).trim_end_matches('/'));
    s.transient = transient
        .iter()
        .map(|d| format!("{root}{}/", d.trim_matches('/')))
        .collect();
    s.persist = Some(root);
    s.reader = Some(reader);
}

/// Stop recording changes, after the host failed to save them. Stored files stay readable.
pub fn stop_persisting() {
    let mut s = store();
    s.persist = None;
    s.dirty.clear();
}

pub fn persistent_root() -> Option<String> {
    store().persist.as_ref().map(|p| p.trim_end_matches('/').to_owned())
}

/// Add `path` as `len` bytes at `off` of segment `seg`. Not a change to persist.
pub fn mount(path: &str, mtime: Duration, seg: u32, off: u64, len: u64) {
    store().files.insert(
        normalize(path),
        Entry {
            data: Data::Stored { seg, off, len },
            mtime,
        },
    );
}

/// What changed below the persistent root since the last [`commit`].
pub struct Snapshot {
    /// Path, mtime and length of each file, whose bytes follow each other in `data`.
    pub files: Vec<(String, Duration, u64)>,
    pub data: Vec<u8>,
    pub removed: Vec<String>,
}

static BEFORE_SNAPSHOT: OnceLock<fn()> = OnceLock::new();

/// Run `f` at the start of every [`take_snapshot`], to write out what it holds back.
pub fn on_snapshot(f: fn()) {
    let _ = BEFORE_SNAPSHOT.set(f);
}

pub fn take_snapshot() -> Option<Snapshot> {
    if let Some(f) = BEFORE_SNAPSHOT.get() {
        f();
    }
    let mut s = store();
    if s.dirty.is_empty() {
        return None;
    }
    let mut dirty: Vec<String> = s.dirty.iter().cloned().collect();
    dirty.sort();
    let mut snap = Snapshot {
        files: Vec::new(),
        data: Vec::new(),
        removed: Vec::new(),
    };
    for key in dirty {
        let bytes = match s.files.get(&key) {
            None => {
                snap.removed.push(key);
                continue;
            }
            Some(Entry {
                data: Data::Stored { seg, off, len },
                ..
            }) => s.load(*seg, *off, *len).unwrap_or_default(),
            Some(Entry { data: Data::Mem(b), .. }) => b.clone(),
        };
        let mtime = s.files[&key].mtime;
        snap.files.push((key, mtime, bytes.len() as u64));
        snap.data.extend_from_slice(&bytes);
    }
    s.snapshot = snap.files.clone();
    s.snapshot_removed = snap.removed.clone();
    Some(snap)
}

/// The last snapshot is in segment `seg`, its files' bytes at `offsets`: they no
/// longer need persisting, and their memory is released.
pub fn commit(seg: u32, offsets: &[u64]) {
    let mut s = store();
    let files = std::mem::take(&mut s.snapshot);
    for ((key, mtime, len), &off) in files.into_iter().zip(offsets) {
        if let Some(e) = s.files.get_mut(&key)
            && e.mtime == mtime
            && e.len() == len
        {
            e.data = Data::Stored { seg, off, len };
            s.dirty.remove(&key);
        }
    }
    for key in std::mem::take(&mut s.snapshot_removed) {
        if !s.files.contains_key(&key) {
            s.dirty.remove(&key);
        }
    }
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

#[cfg(test)]
mod persist_tests {
    use super::*;

    const SEGMENT: &[u8] = b"package P end P;model M end M;";

    fn reader(seg: u32, off: u64, buf: &mut [u8]) -> bool {
        let off = off as usize;
        let ok = seg == 7 && off + buf.len() <= SEGMENT.len();
        if ok {
            buf.copy_from_slice(&SEGMENT[off..off + buf.len()]);
        }
        ok
    }

    #[test]
    fn mount_snapshot_commit() {
        set_persistent_root("/pt/", &["tmp"], reader);
        assert_eq!(persistent_root().as_deref(), Some("/pt"));
        let t = Duration::new(1_700_000_000, 5);
        mount("/pt/lib/P/package.mo", t, 7, 0, 16);
        mount("/pt/lib/M.mo", t, 7, 16, 14);
        assert!(take_snapshot().is_none());
        assert_eq!(size("/pt/lib/M.mo"), Some(14));
        assert_eq!(mtime("/pt/lib/M.mo"), Some(t));
        assert_eq!(read("/pt/lib/P/package.mo").as_deref(), Some(&b"package P end P;"[..]));
        assert_eq!(
            with_bytes("/pt/lib/M.mo", |b| b.to_vec()).as_deref(),
            Some(&b"model M end M;"[..])
        );
        assert!(is_dir("/pt/lib/P"));

        append("/pt/lib/M.mo", b"//");
        write("/pt/new.txt", b"abc".to_vec());
        write("/outside.txt", b"x".to_vec());
        write("/pt/tmp/download.zip", b"x".to_vec());
        assert!(remove("/pt/lib/P/package.mo"));
        let snap = take_snapshot().unwrap();
        let names: Vec<&str> = snap.files.iter().map(|f| f.0.as_str()).collect();
        assert_eq!(names, ["/pt/lib/M.mo", "/pt/new.txt"]);
        assert_eq!(snap.data, b"model M end M;//abc");
        assert_eq!(snap.removed, ["/pt/lib/P/package.mo"]);

        write("/pt/later.txt", b"x".to_vec());
        commit(8, &[100, 116]);
        assert_eq!(take_snapshot().unwrap().files.len(), 1);
        commit(9, &[0]);
        assert!(take_snapshot().is_none());
        let s = store();
        assert!(matches!(
            s.files["/pt/new.txt"].data,
            Data::Stored {
                seg: 8,
                off: 116,
                len: 3
            }
        ));
        assert!(matches!(s.files["/outside.txt"].data, Data::Mem(_)));
    }
}

#[cfg(test)]
mod dir_tests {
    use super::*;

    #[test]
    fn children_and_subtrees() {
        for f in [
            "/dt/a.mo",
            "/dt/a/package.mo",
            "/dt/a/b/c.mo",
            "/dt/a-b",
            "/dt/a0",
            "/dt/z/y",
            "/dtx",
        ] {
            write(f, Vec::new());
        }
        assert!(is_dir("/dt") && is_dir("/dt/a") && is_dir("/dt/a/b"));
        assert!(!is_dir("/dt/a.mo") && !is_dir("/d") && !is_dir("/dt/a/b/c.mo"));
        let names = |v: Vec<(String, bool)>| {
            v.into_iter()
                .map(|(n, d)| format!("{n}{}", if d { "/" } else { "" }))
                .collect::<Vec<_>>()
        };
        assert_eq!(names(list_dir("/dt")), ["a-b", "a.mo", "a/", "a0", "z/"]);
        assert_eq!(names(list_dir("/dt/a")), ["b/", "package.mo"]);
        assert!(list_dir("/dt/none").is_empty());
    }
}
