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

use anyhow::{anyhow, Context, Result};
use arcstr::ArcStr;

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

/// Forward the syntax diagnostics recorded by the most recent parser
/// invocation to the Error subsystem, the way the C parser's
/// `displayRecognitionError` calls `c_add_source_message` (Parser/parse.c).
/// Must run after every entry-point call, success or failure: a successful
/// parse can still record warnings (e.g. the `der(cr) :=` compatibility
/// warning).
/// Mirror of `System.regularFileWritable`: true when `path` is an existing
/// file that can be opened for writing. Classes parsed from a non-writable
/// file are flagged read-only in their SOURCEINFO. Inlined here so the parser
/// crate need not depend on the rest of the util crate.
fn regular_file_writable(path: &str) -> bool {
    std::fs::OpenOptions::new().write(true).open(path).is_ok()
}

fn report_syntax_messages(info_filename: &str) {
    use openmodelica_error::ErrorTypes::{MessageType, Severity};
    for m in parser::take_syntax_messages() {
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
            ArcStr::from(m.message),
            metamodelica::nil(),
        );
    }
}

/// Wrap [`parser::parse`]'s `Box<dyn Error>` into an `anyhow::Error` so
/// the MetaModelica-facing signatures (which return `anyhow::Result`)
/// can use `?` directly. `filename` is the real path stored into SOURCEINFO;
/// `info_filename` (the possibly testsuite-friendly name) is only used to
/// display syntax errors — same split as the C parser's `filename_C` vs
/// `filename_C_testsuiteFriendly` (Parser/parse.c).
fn run_parse(src: &str, filename: &str, info_filename: &str, grammar: Grammar, readonly: bool, timestamp: f64) -> Result<Absyn::Program> {
    let result = parser::parse(src, filename, info_filename, grammar, readonly, timestamp).map_err(|e| anyhow!(e.to_string()));
    report_syntax_messages(info_filename);
    result
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
    openmodelica_wasi::fs::modified(filename).ok()
        .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
        .map(|d| d.as_secs() as f64)
        .unwrap_or(0.0)
}

/// `time(NULL)` for string parses, like parseString in Parser/parse.c.
/// `SystemTime::now` panics on wasm32-unknown-unknown; web-time backs it with
/// the JS clock there.
fn now_timestamp() -> f64 {
    #[cfg(not(target_arch = "wasm32"))]
    use std::time::{SystemTime, UNIX_EPOCH};
    #[cfg(target_arch = "wasm32")]
    use web_time::{SystemTime, UNIX_EPOCH};
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as f64)
        .unwrap_or(0.0)
}

pub fn parse(
    filename: ArcStr,
    infoFilename: ArcStr,
    acceptedGram: i32,
    encoding: ArcStr,
    languageStandardInt: i32,
    strict: bool,
    _runningTestsuite: bool,
    _libraryPath: ArcStr,
    _lveInstance: Option<i32>,
) -> Result<Absyn::Program> {
    // The Rust parser operates on UTF-8 `&str` directly.  Anything else
    // would need transcoding via the `encoding_rs` crate; bail explicitly
    // rather than silently misinterpreting the bytes.
    if !encoding.is_empty() && !encoding.eq_ignore_ascii_case("UTF-8") && !encoding.eq_ignore_ascii_case("UTF8") {
        return Err(anyhow!(
            "ParserExt::parse: only UTF-8 input is supported, got encoding {:?}",
            encoding.as_str()
        ));
    }
    let (src, orig_bytes) = read_source_file(filename.as_str())
        .with_context(|| format!("ParserExt::parse: cannot read {filename}"))?;
    let grammar = select_grammar(acceptedGram, languageStandardInt);
    parser::set_pure_impure_as_ident(languageStandardInt < 33 && strict);
    // Like parseFile in Parser/parse.c: classes parsed from a file the user
    // cannot write to are flagged read-only in their SOURCEINFO, so the
    // interactive API refuses to modify them.
    let readonly = !regular_file_writable(filename.as_str());
    parser::set_non_utf8_source_bytes(orig_bytes);
    let result = run_parse(&src, filename.as_str(), infoFilename.as_str(), grammar, readonly, file_timestamp(filename.as_str()));
    parser::set_non_utf8_source_bytes(None);
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
    parser::set_pure_impure_as_ident(languageStandardInt < 33 && strict);
    // String input has no on-disk path; the interactive name serves as both
    // the SOURCEINFO and the error-display name (like the C `parseString`).
    run_parse(r#str.as_str(), infoFilename.as_str(), infoFilename.as_str(), grammar, /*readonly=*/false, now_timestamp())
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
    let (src, orig_bytes) = read_source_file(filename.as_str())
        .with_context(|| format!("ParserExt::parseexp: cannot read {filename}"))?;
    let grammar = select_grammar(acceptedGram, languageStandardInt);
    let readonly = !regular_file_writable(filename.as_str());
    parser::set_non_utf8_source_bytes(orig_bytes);
    let result = parser::parse_statements(&src, filename.as_str(), infoFilename.as_str(), grammar, readonly, file_timestamp(filename.as_str())).map_err(|e| anyhow!(e.to_string()));
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
    let result = parser::parse_statements(r#str.as_str(), infoFilename.as_str(), infoFilename.as_str(), grammar, /*readonly=*/false, now_timestamp()).map_err(|e| anyhow!(e.to_string()));
    report_syntax_messages(infoFilename.as_str());
    result
}

pub fn stringPath(
    r#str: ArcStr,
    infoFilename: ArcStr,
    acceptedGram: i32,
    languageStandardInt: i32,
    _runningTestsuite: bool,
) -> Result<Arc<Absyn::Path>> {
    let grammar = select_grammar(acceptedGram, languageStandardInt);
    let result = parser::parse_path(r#str.as_str(), infoFilename.as_str(), grammar)
        .map(Arc::new)
        .map_err(|e| anyhow!(e.to_string()));
    report_syntax_messages(infoFilename.as_str());
    result
}

pub fn stringCref(
    r#str: ArcStr,
    infoFilename: ArcStr,
    acceptedGram: i32,
    languageStandardInt: i32,
    _runningTestsuite: bool,
) -> Result<Arc<Absyn::ComponentRef>> {
    let grammar = select_grammar(acceptedGram, languageStandardInt);
    let result = parser::parse_cref(r#str.as_str(), infoFilename.as_str(), grammar)
        .map(Arc::new)
        .map_err(|e| anyhow!(e.to_string()));
    report_syntax_messages(infoFilename.as_str());
    result
}

pub fn stringMod(
    r#str: ArcStr,
    infoFilename: ArcStr,
    acceptedGram: i32,
    languageStandardInt: i32,
    _runningTestsuite: bool,
) -> Result<Arc<Absyn::ElementArg>> {
    let grammar = select_grammar(acceptedGram, languageStandardInt);
    let result = parser::parse_modification(r#str.as_str(), infoFilename.as_str(), grammar)
        .map(Arc::new)
        .map_err(|e| anyhow!(e.to_string()));
    report_syntax_messages(infoFilename.as_str());
    result
}

pub fn stringEq(
    r#str: ArcStr,
    infoFilename: ArcStr,
    acceptedGram: i32,
    languageStandardInt: i32,
    _runningTestsuite: bool,
) -> Result<Arc<Absyn::EquationItem>> {
    let grammar = select_grammar(acceptedGram, languageStandardInt);
    let result = parser::parse_equation(r#str.as_str(), infoFilename.as_str(), grammar)
        .map(Arc::new)
        .map_err(|e| anyhow!(e.to_string()));
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

pub fn stopLibraryVendorExecutable(_lveInstance: Option<i32>) {

}
