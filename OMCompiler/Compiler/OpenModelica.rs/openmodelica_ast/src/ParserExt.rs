// Manually written file.
//
// Rust port of `OMCompiler/Compiler/FrontEnd/ParserExt.mo`'s
// `external "C"` declarations.  The MetaModelica module is a thin shim
// over the C entry points defined in `OMCompiler/Parser/Parser_omc.c`
// (which in turn drive the ANTLR3 grammar at `grammars/Modelica.g`).
//
// Here we forward to the winnow-based parser already living in the
// same crate at `crate::parser`, so callers like `Parser.mo` /
// `openmodelica_frontend::Parser` keep working without going through
// any C runtime.
//
// Grammar selection (`acceptedGram`) follows the integer encoding used
// by `Flags.GRAMMAR` (see `OMCompiler/Compiler/Util/Flags.mo:154-158`):
//
//   1 = Modelica       → `Grammar::Modelica2` if `languageStandardInt < 30`
//                        otherwise `Grammar::Modelica3`
//   2 = MetaModelica   → `Grammar::MetaModelica`
//   3 = ParModelica    → `Grammar::MetaModelica`     (parmodelica keywords are
//                        lexed by the MetaModelica lexer in mmwinnow)
//   4 = Optimica       → `Grammar::Optimica`
//   5 = PDEModelica    → `Grammar::PDEModelica`
//
// The interactive entry points (`parseexp`, `parsestringexp`, `stringPath`,
// `stringCref`, `stringMod`, `stringEq`) forward to the corresponding
// per-construct parser entry points (`parser::parse_statements` etc.),
// mirroring how `parse.c` selects an ANTLR entry rule from the `PARSE_*`
// flags.

#![allow(non_snake_case)]

use std::sync::Arc;

use arcstr::ArcStr;
use metamodelica::Result;

use crate::Absyn;
use crate::GlobalScript;
use crate::parser::{self, Grammar};

/// Map `(acceptedGram, languageStandardInt)` to the parser's [`Grammar`]
/// enum. Mirrors the `set_grammar_flag` switch in
/// `OMCompiler/Parser/Parser_omc.c`.
fn select_grammar(acceptedGram: i32, languageStandardInt: i32) -> Grammar {
    match acceptedGram {
        2 | 3 => Grammar::MetaModelica,
        4 => Grammar::Optimica,
        // 5 = PDEModelica: Modelica 3 plus the field/indomain extensions.
        5 => Grammar::PDEModelica,
        // 1 = Modelica, and anything unknown falls back to the Modelica
        // grammar.  The language-standard integer follows
        // `Flags.LANGUAGE_STANDARD`: values 10/20 are Modelica 1.x / 2.x,
        // 30+ are Modelica 3.x.
        _ => {
            if languageStandardInt < 30 {
                Grammar::Modelica2
            } else {
                Grammar::Modelica3
            }
        }
    }
}

/// Mirror of `System.regularFileWritable`: true when `path` is an existing
/// file that can be opened for writing. Classes parsed from a non-writable
/// file are flagged read-only in their SOURCEINFO. Inlined here so the parser
/// crate need not depend on the rest of the util crate.
fn regular_file_writable(path: &str) -> bool {
    // access(2) answers it without opening the file for writing.
    #[cfg(unix)]
    return std::ffi::CString::new(path).is_ok_and(|p| unsafe { libc::access(p.as_ptr(), libc::W_OK) } == 0);
    #[cfg(not(unix))]
    openmodelica_wasi::fs::is_writable(path)
}

/// Forward the syntax diagnostics recorded by the most recent parser
/// invocation to the Error subsystem, the way the C parser's
/// `displayRecognitionError` calls `c_add_source_message` (Parser/parse.c).
/// Must run after every entry-point call, success or failure: a successful
/// parse can still record warnings (e.g. the `der(cr) :=` compatibility
/// warning).
fn report_syntax_messages(info_filename: &str) {
    report_messages(info_filename, &parser::take_syntax_messages());
}

fn report_messages(info_filename: &str, messages: &[parser::SyntaxMessage]) {
    use openmodelica_error::ErrorTypes::{MessageType, Severity};
    for m in messages {
        openmodelica_error::ErrorExt::addSourceMessage(
            // Error id used by the C parser for every syntax diagnostic
            // (the literal `2` in its c_add_source_message calls).
            2,
            MessageType::SYNTAX,
            match m.severity {
                parser::SyntaxSeverity::Error => Severity::ERROR,
                parser::SyntaxSeverity::Warning => Severity::WARNING,
            },
            m.line1 as i32,
            m.col1 as i32,
            m.line2 as i32,
            m.col2 as i32,
            false,
            ArcStr::from(info_filename),
            ArcStr::from(m.message.as_str()),
            metamodelica::nil(),
        );
    }
}

/// Wrap [`parser::parse`]'s `Box<dyn Error>` into an `&'static str` so
/// the MetaModelica-facing signatures (which return `anyhow::Result`)
/// can use `?` directly. `filename` is the real path stored into SOURCEINFO;
/// `info_filename` (the possibly testsuite-friendly name) is only used to
/// display syntax errors — same split as the C parser's `filename_C` vs
/// `filename_C_testsuiteFriendly` (Parser/parse.c).
fn run_parse(
    src: &str,
    filename: &str,
    info_filename: &str,
    grammar: Grammar,
    readonly: bool,
    timestamp: f64,
) -> Result<Absyn::Program> {
    let result = parser::parse(src, filename, info_filename, grammar, readonly, timestamp).map_err(|_| "error");
    report_syntax_messages(info_filename);
    result
}

/// Parsed files cached under `$OPENMODELICA_PARSE_CACHE` (default
/// `~/.openmodelica/cache/ast`, outside the testsuite; empty disables it), one
/// directory per AST schema. An entry is keyed by the path and parse options,
/// and its header records the source's size and mtime, so editing the source
/// replaces it. A writer thread stores entries and sweeps the cache once a day:
/// entries whose source changed or is gone, and schemas unused for a week.
///
/// On the web target the cache is `cache/ast` below the persistent store's root
/// and holds only sources below that root. Entries are written, and the cache
/// swept, when the host takes a store snapshot. A panic aborts there, so a
/// checksum guards each entry instead of `catch_unwind`.
mod parse_cache {
    use super::*;
    use metamodelica::serial::{Decoder, Encoder, MMSerial};
    use parser::{SyntaxMessage, SyntaxSeverity};
    use std::hash::{Hash, Hasher};
    use std::path::{Path, PathBuf};
    use std::sync::OnceLock;
    use std::time::Duration;

    const fn fnv(bytes: &[u8]) -> u64 {
        let mut h: u64 = 0xcbf29ce484222325;
        let mut i = 0;
        while i < bytes.len() {
            h = (h ^ bytes[i] as u64).wrapping_mul(0x100000001b3);
            i += 1;
        }
        h
    }

    const SCHEMA: u64 = fnv(include_bytes!("Absyn.rs"))
        ^ fnv(include_bytes!("../../metamodelica/src/serial.rs"))
        ^ fnv(include_bytes!("../../metamodelica_derive/src/lib.rs"));
    const DAY: Duration = Duration::from_secs(24 * 3600);
    const USED: &str = ".used";

    pub struct Entry {
        path: PathBuf,
        header: Vec<u8>,
    }

    type Job = (Entry, Absyn::Program, Vec<SyntaxMessage>);

    struct Cache {
        dir: PathBuf,
        #[cfg(not(target_arch = "wasm32"))]
        writer: std::sync::mpsc::Sender<Job>,
        #[cfg(target_arch = "wasm32")]
        root: String,
    }

    static CACHE: OnceLock<Option<Cache>> = OnceLock::new();

    #[cfg(not(target_arch = "wasm32"))]
    fn base_dir(running_testsuite: bool) -> Option<PathBuf> {
        match std::env::var_os("OPENMODELICA_PARSE_CACHE") {
            Some(d) if d.is_empty() => None,
            Some(d) => Some(d.into()),
            None if running_testsuite => None,
            None => {
                let home = if cfg!(windows) {
                    std::env::var_os("APPDATA").or_else(|| std::env::var_os("HOME"))
                } else {
                    std::env::var_os("HOME")
                };
                let home = home.filter(|h| !h.is_empty())?;
                Some(Path::new(&home).join(".openmodelica").join("cache").join("ast"))
            }
        }
    }

    #[cfg(not(target_arch = "wasm32"))]
    fn cache(running_testsuite: bool) -> Option<&'static Cache> {
        CACHE
            .get_or_init(|| {
                let base = base_dir(running_testsuite)?;
                let dir = base.join(format!("{SCHEMA:016x}"));
                std::fs::create_dir_all(&dir).ok()?;
                let (writer, jobs) = std::sync::mpsc::channel::<Job>();
                let thread_dir = dir.clone();
                std::thread::Builder::new()
                    .name("parse-cache".into())
                    .stack_size(metamodelica::thread_stack_size())
                    .spawn(move || {
                        maintain(&base, &thread_dir);
                        for (entry, program, messages) in jobs {
                            let _ = std::panic::catch_unwind(|| write(&entry, &program, &messages));
                        }
                    })
                    .ok()?;
                Some(Cache { dir, writer })
            })
            .as_ref()
    }

    #[cfg(target_arch = "wasm32")]
    thread_local! {
        static JOBS: std::cell::RefCell<Vec<Job>> = const { std::cell::RefCell::new(Vec::new()) };
        static SWEPT: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
    }

    #[cfg(target_arch = "wasm32")]
    fn cache(running_testsuite: bool) -> Option<&'static Cache> {
        CACHE
            .get_or_init(|| {
                let root = openmodelica_wasi::persistent_root().filter(|_| !running_testsuite)?;
                let dir = Path::new(&root)
                    .join("cache")
                    .join("ast")
                    .join(format!("{SCHEMA:016x}"));
                openmodelica_wasi::on_snapshot(flush);
                Some(Cache {
                    dir,
                    root: format!("{root}/"),
                })
            })
            .as_ref()
    }

    #[cfg(target_arch = "wasm32")]
    fn flush() {
        let Some(Some(cache)) = CACHE.get() else { return };
        let jobs = JOBS.take();
        if jobs.is_empty() {
            return;
        }
        if !SWEPT.replace(true)
            && let Some(base) = cache.dir.parent()
        {
            maintain(base, &cache.dir);
        }
        for (entry, program, messages) in jobs {
            write(&entry, &program, &messages);
        }
    }

    fn header(filename: &str, len: u64, mtime: Duration) -> Vec<u8> {
        let mut h = Vec::with_capacity(24 + filename.len());
        h.extend_from_slice(&len.to_le_bytes());
        h.extend_from_slice(&mtime.as_secs().to_le_bytes());
        h.extend_from_slice(&mtime.subsec_nanos().to_le_bytes());
        h.extend_from_slice(&(filename.len() as u32).to_le_bytes());
        h.extend_from_slice(filename.as_bytes());
        h
    }

    pub fn entry(filename: &str, key: impl Hash, running_testsuite: bool) -> Option<Entry> {
        let cache = cache(running_testsuite)?;
        #[cfg(target_arch = "wasm32")]
        if !filename.starts_with(&cache.root) {
            return None;
        }
        let (len, mtime) = io::meta(filename)?;
        let mut h = std::collections::hash_map::DefaultHasher::new();
        (filename, key).hash(&mut h);
        Some(Entry {
            path: cache.dir.join(format!("{:016x}.ast", h.finish())),
            header: header(filename, len, mtime),
        })
    }

    #[cfg(target_arch = "wasm32")]
    fn checksum(bytes: &[u8]) -> u64 {
        const K: u64 = 0x517cc1b727220a95;
        let mut h = bytes.len() as u64;
        let mut words = bytes.chunks_exact(8);
        for w in &mut words {
            h = (h.rotate_left(5) ^ u64::from_le_bytes(w.try_into().unwrap())).wrapping_mul(K);
        }
        for &b in words.remainder() {
            h = (h.rotate_left(5) ^ b as u64).wrapping_mul(K);
        }
        h
    }

    /// A stale entry or one that does not decode counts as a miss.
    pub fn load(entry: &Entry) -> Option<(Absyn::Program, Vec<SyntaxMessage>)> {
        let bytes = io::read(&entry.path)?;
        let body = bytes.strip_prefix(entry.header.as_slice())?;
        #[cfg(target_arch = "wasm32")]
        let body = {
            let (sum, body) = body.split_at_checked(8)?;
            (u64::from_le_bytes(sum.try_into().ok()?) == checksum(body)).then_some(body)?
        };
        std::panic::catch_unwind(|| {
            let mut d = Decoder::new(body);
            let messages = (0..d.varint())
                .map(|_| SyntaxMessage {
                    severity: if bool::mm_decode(&mut d) {
                        SyntaxSeverity::Error
                    } else {
                        SyntaxSeverity::Warning
                    },
                    line1: d.varint() as u32,
                    col1: d.varint() as u32,
                    line2: d.varint() as u32,
                    col2: d.varint() as u32,
                    message: ArcStr::mm_decode(&mut d).to_string(),
                })
                .collect();
            (Absyn::Program::mm_decode(&mut d), messages)
        })
        .ok()
    }

    pub fn store(entry: Entry, program: &Absyn::Program, messages: Vec<SyntaxMessage>) {
        #[cfg(not(target_arch = "wasm32"))]
        if let Some(Some(cache)) = CACHE.get() {
            let _ = cache.writer.send((entry, program.clone(), messages));
        }
        #[cfg(target_arch = "wasm32")]
        if openmodelica_wasi::persistent_root().is_some() {
            JOBS.with(|jobs| jobs.borrow_mut().push((entry, program.clone(), messages)));
        }
    }

    fn write(entry: &Entry, program: &Absyn::Program, messages: &[SyntaxMessage]) {
        let mut e = Encoder::new();
        e.buf.extend_from_slice(&entry.header);
        #[cfg(target_arch = "wasm32")]
        e.buf.extend_from_slice(&[0; 8]);
        e.varint(messages.len() as u64);
        for m in messages {
            (m.severity == SyntaxSeverity::Error).mm_encode(&mut e);
            for v in [m.line1, m.col1, m.line2, m.col2] {
                e.varint(v as u64);
            }
            ArcStr::from(m.message.as_str()).mm_encode(&mut e);
        }
        program.mm_encode(&mut e);
        #[cfg(target_arch = "wasm32")]
        {
            let at = entry.header.len();
            let sum = checksum(&e.buf[at + 8..]);
            e.buf[at..at + 8].copy_from_slice(&sum.to_le_bytes());
        }
        io::write(&entry.path, &e.buf);
    }

    fn touch(path: &Path) {
        if io::age(path).map_or(true, |a| a > DAY / 2) {
            io::touch(path);
        }
    }

    /// The source an entry was parsed from still has the size and mtime in its header.
    fn up_to_date(entry: &Path) -> Option<bool> {
        use std::io::Read;
        let mut f = io::open(entry)?;
        let mut fixed = [0u8; 24];
        f.read_exact(&mut fixed).ok()?;
        let mut name = vec![0u8; u32::from_le_bytes(fixed[20..24].try_into().ok()?) as usize];
        f.read_exact(&mut name).ok()?;
        let name = String::from_utf8(name).ok()?;
        let current = io::meta(&name).map(|(len, mtime)| header(&name, len, mtime));
        Some(current.is_some_and(|h| h[..24] == fixed))
    }

    fn maintain(base: &Path, dir: &Path) {
        touch(&dir.join(USED));
        let swept = base.join(".swept");
        if io::age(&swept).is_some_and(|a| a < DAY) {
            return;
        }
        touch(&swept);
        for p in io::dir(base) {
            let schema_dir = p
                .file_name()
                .and_then(|n| n.to_str())
                .is_some_and(|n| n.len() == 16 && n.bytes().all(|b| b.is_ascii_hexdigit()));
            if p != dir && schema_dir && io::age(&p.join(USED)).is_some_and(|a| a > 7 * DAY) {
                io::remove_dir_all(&p);
            }
        }
        for p in io::dir(dir) {
            let stale = match p.extension().and_then(|e| e.to_str()) {
                Some("ast") => up_to_date(&p) == Some(false),
                Some("tmp") => io::age(&p).map_or(true, |a| a > DAY),
                _ => false,
            };
            if stale {
                io::remove_file(&p);
            }
        }
    }

    #[cfg(not(target_arch = "wasm32"))]
    mod io {
        use std::path::{Path, PathBuf};
        use std::time::{Duration, SystemTime};

        pub fn meta(path: &str) -> Option<(u64, Duration)> {
            let m = std::fs::metadata(path).ok()?;
            Some((m.len(), m.modified().ok()?.duration_since(SystemTime::UNIX_EPOCH).ok()?))
        }

        pub fn read(path: &Path) -> Option<Vec<u8>> {
            std::fs::read(path).ok()
        }

        pub fn open(path: &Path) -> Option<std::fs::File> {
            std::fs::File::open(path).ok()
        }

        pub fn write(path: &Path, bytes: &[u8]) {
            let tmp = path.with_extension(format!("{}.tmp", std::process::id()));
            if std::fs::write(&tmp, bytes).is_ok() && std::fs::rename(&tmp, path).is_err() {
                let _ = std::fs::remove_file(&tmp);
            }
        }

        pub fn age(path: &Path) -> Option<Duration> {
            std::fs::metadata(path).ok()?.modified().ok()?.elapsed().ok()
        }

        pub fn touch(path: &Path) {
            if let Ok(f) = std::fs::File::create(path) {
                let _ = f.set_modified(SystemTime::now());
            }
        }

        pub fn dir(path: &Path) -> Vec<PathBuf> {
            std::fs::read_dir(path)
                .into_iter()
                .flatten()
                .flatten()
                .map(|e| e.path())
                .collect()
        }

        pub fn remove_file(path: &Path) {
            let _ = std::fs::remove_file(path);
        }

        pub fn remove_dir_all(path: &Path) {
            let _ = std::fs::remove_dir_all(path);
        }
    }

    #[cfg(target_arch = "wasm32")]
    mod io {
        use openmodelica_wasi::fs;
        use std::path::{Path, PathBuf};
        use std::time::{Duration, SystemTime};

        fn mtime(path: &str) -> Option<Duration> {
            fs::modified(path).ok()?.duration_since(SystemTime::UNIX_EPOCH).ok()
        }

        /// None for an embedded builtin, whose mtime is the epoch whatever its contents.
        pub fn meta(path: &str) -> Option<(u64, Duration)> {
            let mtime = mtime(path).filter(|t| !t.is_zero())?;
            Some((fs::len(path).ok()?, mtime))
        }

        pub fn read(path: &Path) -> Option<Vec<u8>> {
            fs::read(path.to_str()?).ok()
        }

        pub fn open(path: &Path) -> Option<std::io::Cursor<Vec<u8>>> {
            read(path).map(std::io::Cursor::new)
        }

        pub fn write(path: &Path, bytes: &[u8]) {
            if let Some(p) = path.to_str() {
                let _ = fs::write(p, bytes);
            }
        }

        pub fn age(path: &Path) -> Option<Duration> {
            Duration::from_nanos(openmodelica_wasi::realtime_nanos()).checked_sub(mtime(path.to_str()?)?)
        }

        pub fn touch(path: &Path) {
            write(path, &[]);
        }

        pub fn dir(path: &Path) -> Vec<PathBuf> {
            let Some(p) = path.to_str() else { return Vec::new() };
            fs::read_dir(p)
                .unwrap_or_default()
                .into_iter()
                .map(|e| path.join(e.name))
                .collect()
        }

        pub fn remove_file(path: &Path) {
            if let Some(p) = path.to_str() {
                let _ = fs::remove_file(p);
            }
        }

        pub fn remove_dir_all(path: &Path) {
            if let Some(p) = path.to_str() {
                let _ = fs::remove_dir_all(p);
            }
        }
    }
}

/// Read a source file as a UTF-8 string for the lexer, mirroring the C lexer's
/// tolerance of non-UTF-8 input (it lexes raw bytes and only validates inside
/// the `STRING` rule). When the file is valid UTF-8 this is just the contents
/// and `None`. When it is not, each byte that is not part of a valid UTF-8
/// sequence is replaced by `'?'` — one byte each, so byte offsets stay aligned
/// with the original — and the original bytes are returned so the lexer can
/// reproduce the per-string-literal warning + ASCII fallback.
fn read_source_file(filename: &str) -> std::io::Result<(String, Option<Arc<[u8]>>)> {
    Ok(sanitize_source_bytes(openmodelica_wasi::fs::read(filename)?))
}

fn sanitize_source_bytes(bytes: Vec<u8>) -> (String, Option<Arc<[u8]>>) {
    match std::str::from_utf8(&bytes) {
        Ok(s) => (s.to_owned(), None),
        Err(_) => {
            let mut out = String::with_capacity(bytes.len());
            let mut i = 0;
            while i < bytes.len() {
                match std::str::from_utf8(&bytes[i..]) {
                    Ok(s) => {
                        out.push_str(s);
                        break;
                    }
                    Err(e) => {
                        let valid = e.valid_up_to();
                        // SAFETY: `bytes[i..i+valid]` is valid UTF-8 per the
                        // `from_utf8` error contract.
                        out.push_str(unsafe { std::str::from_utf8_unchecked(&bytes[i..i + valid]) });
                        // `error_len() == None` ⇒ truncated multibyte sequence
                        // at EOF; replace the rest. Each invalid byte → one '?'.
                        let invalid = e.error_len().unwrap_or(bytes.len() - i - valid);
                        for _ in 0..invalid {
                            out.push('?');
                        }
                        i += valid + invalid;
                    }
                }
            }
            (out, Some(Arc::from(bytes)))
        }
    }
}

/// The file's mtime in seconds, the way parseFile in Parser/parse.c stores
/// `st.st_mtime` into every SOURCEINFO's lastModification — except under
/// OPENMODELICA_BACKEND_STUBS, where it is pinned to 0.0 so bootstrapping
/// sources are reproducible. getTimeStamp/reloadClass compare this value.
fn file_timestamp(filename: &str) -> f64 {
    if std::env::var_os("OPENMODELICA_BACKEND_STUBS").is_some_and(|v| v == "1") {
        return 0.0;
    }
    openmodelica_wasi::fs::modified(filename)
        .ok()
        .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
        .map(|d| d.as_secs() as f64)
        .unwrap_or(0.0)
}

/// `time(NULL)` for string parses, like parseString in Parser/parse.c. The wall
/// clock comes from `openmodelica_wasi` (JS clock on wasm, where
/// `std::time::SystemTime::now()` panics).
fn now_timestamp() -> f64 {
    (openmodelica_wasi::realtime_nanos() / 1_000_000_000) as f64
}

pub fn parse(
    filename: ArcStr,
    infoFilename: ArcStr,
    acceptedGram: i32,
    encoding: ArcStr,
    languageStandardInt: i32,
    strict: bool,
    runningTestsuite: bool,
    _libraryPath: ArcStr,
    _lveInstance: Option<i32>,
) -> Result<Absyn::Program> {
    // Loader cancel chokepoint: loadModel/loadFile/installPackage parse each file
    // through here, so a per-file check makes the whole parse phase cancellable.
    metamodelica::cancel::bail_if_cancelled()?;
    let _step = metamodelica::cancel::report_progress_step(
        metamodelica::cancel::PROGRESS_INDETERMINATE,
        metamodelica::cancel::PHASE_PARSE,
        &format!("parsing {filename}"),
    );
    let grammar = select_grammar(acceptedGram, languageStandardInt);
    // Like parseFile in Parser/parse.c: classes parsed from a file the user
    // cannot write to are flagged read-only in their SOURCEINFO, so the
    // interactive API refuses to modify them.
    let readonly = !regular_file_writable(filename.as_str());
    let cache_entry = parse_cache::entry(
        filename.as_str(),
        (
            acceptedGram,
            languageStandardInt,
            strict,
            readonly,
            encoding.as_str(),
            file_timestamp(filename.as_str()).to_bits(),
        ),
        runningTestsuite,
    );
    if let Some((program, messages)) = cache_entry.as_ref().and_then(parse_cache::load) {
        report_messages(infoFilename.as_str(), &messages);
        return Ok(program);
    }
    let (src, orig_bytes) =
        read_source_file(filename.as_str()).map_err(|_| "ParserExt::parse: cannot read {filename}")?;
    parser::set_language_standard(languageStandardInt, strict);
    // Outside string literals the grammar allows nothing but ASCII, so only
    // the literals are transcoded from `encoding`.
    parser::set_non_utf8_source_bytes(orig_bytes);
    parser::set_source_encoding(encoding.as_str());
    let result = parser::parse(
        &src,
        filename.as_str(),
        infoFilename.as_str(),
        grammar,
        readonly,
        file_timestamp(filename.as_str()),
    )
    .map_err(|_| "error");
    parser::set_source_encoding("");
    parser::set_non_utf8_source_bytes(None);
    let messages = parser::take_syntax_messages();
    report_messages(infoFilename.as_str(), &messages);
    if let (Ok(program), Some(entry)) = (&result, cache_entry) {
        parse_cache::store(entry, program, messages);
    }
    result
}

pub fn parsestring(
    r#str: ArcStr,
    infoFilename: ArcStr,
    acceptedGram: i32,
    languageStandardInt: i32,
    strict: bool,
    _runningTestsuite: bool,
) -> Result<Absyn::Program> {
    let grammar = select_grammar(acceptedGram, languageStandardInt);
    parser::set_language_standard(languageStandardInt, strict);
    // String input has no on-disk path; the interactive name serves as both
    // the SOURCEINFO and the error-display name (like the C `parseString`).
    run_parse(
        r#str.as_str(),
        infoFilename.as_str(),
        infoFilename.as_str(),
        grammar,
        /*readonly=*/ false,
        now_timestamp(),
    )
}

// ---------------------------------------------------------------------
// Interactive-mode entry points: parse a .mos script / statement
// sequence, or a single path / cref / modification / equation.  Each
// maps to one ANTLR entry rule selected by `parse.c`'s `PARSE_*` flags;
// the Rust parser exposes them as dedicated `parse_*` functions.
// ---------------------------------------------------------------------

pub fn parseexp(
    filename: ArcStr,
    infoFilename: ArcStr,
    acceptedGram: i32,
    languageStandardInt: i32,
    _runningTestsuite: bool,
) -> Result<GlobalScript::Statements> {
    let (src, orig_bytes) =
        read_source_file(filename.as_str()).map_err(|_| "ParserExt::parseexp: cannot read {filename}")?;
    let grammar = select_grammar(acceptedGram, languageStandardInt);
    let readonly = !regular_file_writable(filename.as_str());
    parser::set_non_utf8_source_bytes(orig_bytes);
    let result = parser::parse_statements(
        &src,
        filename.as_str(),
        infoFilename.as_str(),
        grammar,
        readonly,
        file_timestamp(filename.as_str()),
    )
    .map_err(|_| "error");
    report_syntax_messages(infoFilename.as_str());
    parser::set_non_utf8_source_bytes(None);
    result
}

pub fn parsestringexp(
    r#str: ArcStr,
    infoFilename: ArcStr,
    acceptedGram: i32,
    languageStandardInt: i32,
    _runningTestsuite: bool,
) -> Result<GlobalScript::Statements> {
    let grammar = select_grammar(acceptedGram, languageStandardInt);
    let result = parser::parse_statements(
        r#str.as_str(),
        infoFilename.as_str(),
        infoFilename.as_str(),
        grammar,
        /*readonly=*/ false,
        now_timestamp(),
    )
    .map_err(|_| "error");
    report_syntax_messages(infoFilename.as_str());
    result
}

pub fn stringPath(
    r#str: ArcStr,
    infoFilename: ArcStr,
    acceptedGram: i32,
    languageStandardInt: i32,
    _runningTestsuite: bool,
) -> Result<metamodelica::Ref<Absyn::Path>> {
    let grammar = select_grammar(acceptedGram, languageStandardInt);
    let result = parser::parse_path(r#str.as_str(), infoFilename.as_str(), grammar)
        .map(metamodelica::Ref::new)
        .map_err(|_| "error");
    report_syntax_messages(infoFilename.as_str());
    result
}

pub fn stringCref(
    r#str: ArcStr,
    infoFilename: ArcStr,
    acceptedGram: i32,
    languageStandardInt: i32,
    _runningTestsuite: bool,
) -> Result<metamodelica::Ref<Absyn::ComponentRef>> {
    let grammar = select_grammar(acceptedGram, languageStandardInt);
    let result = parser::parse_cref(r#str.as_str(), infoFilename.as_str(), grammar)
        .map(metamodelica::Ref::new)
        .map_err(|_| "error");
    report_syntax_messages(infoFilename.as_str());
    result
}

pub fn stringMod(
    r#str: ArcStr,
    infoFilename: ArcStr,
    acceptedGram: i32,
    languageStandardInt: i32,
    _runningTestsuite: bool,
) -> Result<metamodelica::Ref<Absyn::ElementArg>> {
    let grammar = select_grammar(acceptedGram, languageStandardInt);
    let result = parser::parse_modification(r#str.as_str(), infoFilename.as_str(), grammar)
        .map(metamodelica::Ref::new)
        .map_err(|_| "error");
    report_syntax_messages(infoFilename.as_str());
    result
}

pub fn stringEq(
    r#str: ArcStr,
    infoFilename: ArcStr,
    acceptedGram: i32,
    languageStandardInt: i32,
    _runningTestsuite: bool,
) -> Result<metamodelica::Ref<Absyn::EquationItem>> {
    let grammar = select_grammar(acceptedGram, languageStandardInt);
    let result = parser::parse_equation(r#str.as_str(), infoFilename.as_str(), grammar)
        .map(metamodelica::Ref::new)
        .map_err(|_| "error");
    report_syntax_messages(infoFilename.as_str());
    result
}

// ---------------------------------------------------------------------
// Library Vendor Executable (LVE) hooks.  These wrap a proprietary
// shared library used by some commercial libraries to validate license
// tokens; OpenModelica's open-source builds disable the feature by
// returning "not started".  Mirror that behaviour here so unrelated
// flows still type-check without dragging in dlopen plumbing.
// ---------------------------------------------------------------------

pub fn startLibraryVendorExecutable(_lvePath: ArcStr) -> (bool, Option<i32>) {
    (false, None)
}

pub fn checkLVEToolLicense(_lveInstance: Option<i32>, _packageName: ArcStr) -> bool {
    false
}

pub fn checkLVEToolFeature(_lveInstance: Option<i32>, _feature: ArcStr) -> bool {
    false
}

pub fn stopLibraryVendorExecutable(_lveInstance: Option<i32>) {}
