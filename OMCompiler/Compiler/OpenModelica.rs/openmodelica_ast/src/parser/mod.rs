//! Winnow-based MetaModelica parser
//!
//! Source is first tokenised by [`lexer::lex`], then parsed by the functions
//! in this file. AST types come from the crate-level [`crate::Absyn`] module
//! (generated from `Compiler/AbsynTypes/Absyn.mo`), mirroring the ANTLR3
//! grammar from `grammars/Modelica.g`.
#![allow(non_snake_case)]

pub mod lexer;
pub mod token_input;

// AST types live in the parent crate (generated from Absyn.mo). The parser
// builds values of those types directly so callers can consume the result
// without an extra conversion layer.
pub use crate::Absyn;
pub use crate::Absyn::*;
pub use metamodelica::List;
pub use lexer::{Token as LexToken, TokenKind, LexError};
pub use token_input::TokenInput;

use lexer::{Token, TokenKind as TK};
use token_input::{t, next_tok, peek_kind, try_tok, t_ident, t_path_ident, t_any_ident, t_str_token};
use winnow::stream::Stream;
use metamodelica::{cons, nil, SourceInfo};

use winnow::{Parser, ModalResult, combinator::{opt, alt, cut_err}, error::{AddContext, ContextError, StrContext, StrContextValue, ErrMode}};
use std::sync::Arc;
use std::cell::{Cell, RefCell};
use arcstr::{ArcStr, literal};

thread_local! {
    /// File name stored into every SOURCEINFO the parser constructs. This is
    /// the *real* path of the file being parsed — like `members.filename_C`
    /// in the C parser (Parser/parse.c), NOT the testsuite-friendly name.
    static CURRENT_FILE: RefCell<ArcStr> = const { RefCell::new(literal!("")) };
    /// Whether the file being parsed is read-only (not writable on disk).
    /// Mirrors `members.readonly` in Parser/parse.c: file-based parses set
    /// it from the file's writability, string-based parses leave it false.
    /// Recorded into every SOURCEINFO so the interactive API can refuse to
    /// modify classes from read-only files.
    static CURRENT_READONLY: Cell<bool> = const { Cell::new(false) };
    /// Timestamp recorded into every SOURCEINFO's lastModification, mirroring
    /// `members.timestamp` in Parser/parse.c: the file's mtime for file-based
    /// parses (0.0 under OPENMODELICA_BACKEND_STUBS for reproducible
    /// bootstrapping sources), the current time for string parses. Read back
    /// by the scripting API's getTimeStamp / reloadClass change detection.
    static CURRENT_TIMESTAMP: Cell<f64> = const { Cell::new(0.0) };
    /// File name used when *displaying* syntax errors — the C parser's
    /// `filename_C_testsuiteFriendly` (`infoFilename` in ParserExt.mo). In
    /// testsuite mode this is the testsuite-relative name, so parse-error
    /// output is stable, while SOURCEINFO keeps the real path (which e.g.
    /// `SymbolTable.updateUriMapping` needs to resolve modelica:// URIs).
    static CURRENT_ERROR_FILE: RefCell<ArcStr> = const { RefCell::new(literal!("")) };
    /// Comments collected by the lexer alongside the token stream.
    ///
    /// Stored as a thread-local because the parser is built on winnow
    /// combinators with the input type fixed to `&[Token]`; threading an
    /// extra mutable cursor through every parser function would be a
    /// large mechanical change. This mirrors the ANTLR3 grammar, which
    /// used the global `omc_first_comment` to drive comment splicing.
    ///
    /// Mutated **only** at strategic checkpoints in the parser (between
    /// `;`-delimited items, after a class definition, etc.), so it is
    /// safe under winnow's backtracking: backtracking does not move the
    /// cursor backwards, and we only consume comments once their
    /// surrounding tokens have been committed to.
    static COMMENT_STREAM: RefCell<CommentStream> = RefCell::new(CommentStream::empty());
}

/// Parser-side view over the lexer's parallel comment stream.
#[derive(Debug, Default)]
pub struct CommentStream {
    comments: Vec<lexer::CommentToken>,
    /// Index of the next comment that has not yet been spliced into the AST.
    cursor: usize,
}

impl CommentStream {
    pub fn empty() -> Self { CommentStream { comments: Vec::new(), cursor: 0 } }
    pub fn new(comments: Vec<lexer::CommentToken>) -> Self {
        CommentStream { comments, cursor: 0 }
    }
}

/// Drain all comments whose start position is *strictly before* `(line, col)`,
/// in source order, and clone their text payloads.
///
/// Used at AST checkpoint points (between elements, equations, etc.) to flush
/// any pending comments into the surrounding container before the next item.
fn take_comments_before(line: u32, col: u32) -> Vec<ArcStr> {
    COMMENT_STREAM.with(|s| {
        let mut s = s.borrow_mut();
        let mut out = Vec::new();
        while s.cursor < s.comments.len() {
            let c = &s.comments[s.cursor];
            if c.line < line || (c.line == line && c.col < col) {
                out.push(c.text.clone());
                s.cursor += 1;
            } else {
                break;
            }
        }
        out
    })
}

/// Snapshot the current comment cursor index. Paired with
/// [`restore_comment_cursor`] to make speculative parses (e.g. `expression`,
/// which winnow may attempt and then backtrack) leave the comment stream
/// untouched on failure.
fn save_comment_cursor() -> usize {
    COMMENT_STREAM.with(|s| s.borrow().cursor)
}

/// Reset the comment cursor to a previously saved index. Used by callers that
/// drained comments during a speculative parse that ultimately backtracked,
/// so the comments are still available to the next parse attempt.
fn restore_comment_cursor(idx: usize) {
    COMMENT_STREAM.with(|s| s.borrow_mut().cursor = idx);
}

// ---------------------------------------------------------------------------
// Syntax diagnostics
// ---------------------------------------------------------------------------

/// Severity of a recorded syntax diagnostic; mirrors the `ErrorLevel_*`
/// values the ANTLR3 grammar passes to `c_add_source_message`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SyntaxSeverity {
    Error,
    Warning,
}

/// One positioned diagnostic produced while parsing, equivalent to a
/// `c_add_source_message(…, ErrorType_syntax, …)` call in `Modelica.g` /
/// `Parser/parse.c`. `message` is the final rendered text (including any
/// `"Parse error: "` prefix); positions are 1-based line / column spans in
/// the source named by [`CURRENT_ERROR_FILE`].
#[derive(Debug, Clone)]
pub struct SyntaxMessage {
    pub severity: SyntaxSeverity,
    pub message: String,
    pub line1: u32,
    pub col1: u32,
    pub line2: u32,
    pub col2: u32,
}

thread_local! {
    /// Diagnostics recorded during the current `run_entry` invocation.
    ///
    /// Like [`COMMENT_STREAM`], this must only be appended to at points the
    /// parser has committed to (an assert about already-consumed tokens, or
    /// just before returning a `Cut` error) — never inside a speculative
    /// branch that an enclosing `alt`/`opt` may retry with different rules,
    /// or a successful reparse would leave a stale diagnostic behind.
    static SYNTAX_MESSAGES: RefCell<Vec<SyntaxMessage>> = const { RefCell::new(Vec::new()) };
}

thread_local! {
    /// Original file bytes when the source was not valid UTF-8 and had to be
    /// sanitized for the lexer (each invalid byte replaced by `'?'`, preserving
    /// byte offsets). `None` for valid-UTF-8 or string-literal input. The lexer
    /// consults this in `lex_string` to reproduce the C `STRING` rule's
    /// per-literal UTF-8 check (`SystemImpl__iconv__ascii` + warning).
    static SOURCE_ORIG_BYTES: RefCell<Option<std::sync::Arc<[u8]>>> = const { RefCell::new(None) };
}

/// Install (or clear) the original bytes of a non-UTF-8 source for the duration
/// of a parse. `ParserExt` sets this from the raw file bytes before parsing and
/// clears it afterwards. See [`SOURCE_ORIG_BYTES`].
pub fn set_non_utf8_source_bytes(bytes: Option<std::sync::Arc<[u8]>>) {
    SOURCE_ORIG_BYTES.with(|b| *b.borrow_mut() = bytes);
}

/// If the source was non-UTF-8 and the original bytes of `[start, end)` (a
/// string literal's content span, in byte offsets that line up with the
/// sanitized source) are not valid UTF-8, return that span ASCII-fied — every
/// byte with the high bit set replaced by `'?'`, the rest kept — exactly like
/// the C `SystemImpl__iconv__ascii`. Returns `None` when the span was valid (so
/// the lexer keeps the string verbatim and emits no warning).
fn ascii_fy_string_span_if_invalid(start: usize, end: usize) -> Option<String> {
    SOURCE_ORIG_BYTES.with(|b| {
        let b = b.borrow();
        let bytes = b.as_deref()?;
        let span = bytes.get(start..end)?;
        if std::str::from_utf8(span).is_ok() {
            return None;
        }
        Some(span.iter().map(|&c| if c & 0x80 != 0 { '?' } else { c as char }).collect())
    })
}

/// Record a non-fatal syntax diagnostic. With `SyntaxSeverity::Error` the
/// parse continues but `run_entry` fails afterwards, mirroring the C
/// parser's `ModelicaParser_lexerError = ANTLR3_TRUE` convention; a
/// `Warning` does not affect the parse result (e.g. the `der(cr) :=`
/// interoperability warning).
fn add_syntax_message(severity: SyntaxSeverity, message: String, line1: u32, col1: u32, line2: u32, col2: u32) {
    SYNTAX_MESSAGES.with(|m| m.borrow_mut().push(SyntaxMessage {
        severity, message, line1, col1, line2, col2,
    }));
}

/// `modelicaParserAssert` failure: record `"Parse error: <message>"` over the
/// given span and return the `Cut` error that aborts the parse. The span
/// arguments follow the grammar's convention of 1-based columns (ANTLR
/// `charPosition+1` == our `Token::col`).
fn parser_assert_fail(message: &str, line1: u32, col1: u32, line2: u32, col2: u32) -> ErrMode<ContextError> {
    add_syntax_message(SyntaxSeverity::Error, format!("Parse error: {message}"), line1, col1, line2, col2);
    ErrMode::Cut(ContextError::new())
}

/// Drain the diagnostics recorded by the most recent `parse_*` call on this
/// thread. `ParserExt` forwards these to the `Error` subsystem
/// (`ErrorExt::addSourceMessage`), which is how they end up in omc's error
/// buffer with the standard `[file:l:c-l:c:writable] Error: …` rendering.
/// Must be called after every entry-point invocation (success or failure)
/// if the caller wants warnings — a successful parse can still record e.g.
/// the `der(cr) :=` warning.
pub fn take_syntax_messages() -> Vec<SyntaxMessage> {
    SYNTAX_MESSAGES.with(|m| std::mem::take(&mut *m.borrow_mut()))
}

/// Drain every remaining comment. Used at end-of-stream / after the last
/// `end ClassName;` for `commentsAfterEnd`.
fn take_comments_remaining() -> Vec<ArcStr> {
    COMMENT_STREAM.with(|s| {
        let mut s = s.borrow_mut();
        let out: Vec<ArcStr> = s.comments[s.cursor..].iter().map(|c| c.text.clone()).collect();
        s.cursor = s.comments.len();
        out
    })
}

/// Position helper: `(line, col)` of the *next* token, or one past EOF.
fn next_pos(input: &TokenInput) -> (u32, u32) {
    match input.first() {
        Some(t) => (t.line, t.col),
        None => (u32::MAX, u32::MAX),
    }
}

// ---------------------------------------------------------------------------
// Grammar selector
// ---------------------------------------------------------------------------

pub struct ParserConfig {
    pub filename: String,
    pub grammar: Grammar,
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Grammar {
    Modelica2,
    Modelica3,
    MetaModelica,
    Optimica,
    /// PDEModelica (`--grammar=PDEModelica`): Modelica 3 plus the `field` /
    /// `nonfield` type prefixes, the `indomain` equation suffix and the `pder`
    /// builtin. Mirrors the C lexer's `pdemodelica_enabled()` flag.
    PDEModelica,
}

thread_local! {
    /// Grammar selected for the current parse; backs the equivalent of the
    /// ANTLR grammar's `metamodelica_enabled()` checks.
    static CURRENT_GRAMMAR: std::cell::Cell<Grammar> = const { std::cell::Cell::new(Grammar::Modelica3) };
    /// True while parsing interactive input (a `.mos` statement stream) —
    /// the equivalent of `parse_expression_enabled()` in `Modelica.g`,
    /// which relaxes some pure-Modelica restrictions (e.g. `{}` literals).
    static INTERACTIVE_PARSE: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
    /// The `allowPartEvalFunc` argument of the ANTLR `expression` rule: a
    /// partial function application (`function f(...)`) is allowed as a
    /// function-call argument (`expression[1]`), disallowed in match patterns
    /// (`expression[0]`), and allowed iff MetaModelica everywhere else
    /// (`expression[metamodelica_enabled()]`). `Some(_)` is an explicit
    /// argument; `None` is the default `metamodelica_enabled()` case. The
    /// cell is consumed on entry to `expression_inner` so an explicit value
    /// applies to just that expression — nested expressions fall back to the
    /// default, exactly like the explicit rule arguments in Modelica.g.
    static ALLOW_PART_EVAL_FUNC: std::cell::Cell<Option<bool>> = const { std::cell::Cell::new(None) };
    /// Whether `pure`/`impure` are lexed as plain identifiers rather than
    /// keywords. Mirrors the `Modelica_3_Lexer.g` predicate
    /// `if (ModelicaParser_langStd < 33 && ModelicaParser_strict) $type = IDENT;`
    /// — i.e. they only became keywords in Modelica 3.3, so a `--std=3.2
    /// --strict` parse must reject `pure function …`. Defaults to `false`
    /// (keywords); set per-parse by [`set_pure_impure_as_ident`].
    static PURE_IMPURE_AS_IDENT: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
}

/// Set whether `pure`/`impure` should be lexed as identifiers for subsequent
/// parses on this thread (see [`PURE_IMPURE_AS_IDENT`]). Called from
/// `ParserExt` with `languageStandardInt < 33 && strict`.
pub fn set_pure_impure_as_ident(b: bool) {
    PURE_IMPURE_AS_IDENT.with(|c| c.set(b));
}

/// Whether the lexer should treat `pure`/`impure` as identifiers. Read by the
/// Modelica-3 keyword table in [`lexer`].
pub(crate) fn pure_impure_as_ident() -> bool {
    PURE_IMPURE_AS_IDENT.with(|c| c.get())
}

/// Parse a function-call argument expression, permitting a top-level partial
/// function application (`expression[1]` in Modelica.g).
fn arg_expression(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    ALLOW_PART_EVAL_FUNC.with(|f| f.set(Some(true)));
    let r = expression(input);
    ALLOW_PART_EVAL_FUNC.with(|f| f.set(None));
    r
}

/// Parse a match-case pattern expression, rejecting a top-level partial
/// function application even in MetaModelica (`expression[0]` in the
/// `pattern` rule of Modelica.g).
fn pattern_expression(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    ALLOW_PART_EVAL_FUNC.with(|f| f.set(Some(false)));
    let r = expression(input);
    ALLOW_PART_EVAL_FUNC.with(|f| f.set(None));
    r
}

/// `metamodelica_enabled()` from `Modelica.g`: MetaModelica (and
/// ParModelica, which shares the lexer/grammar selection) relaxes the
/// Modelica-only grammar restrictions.
fn metamodelica_enabled() -> bool {
    CURRENT_GRAMMAR.with(|g| g.get()) == Grammar::MetaModelica
}

/// `pdemodelica_enabled()` from `Modelica.g`: enables the PDEModelica
/// extensions (the `indomain` equation suffix; `field`/`nonfield` are lexed as
/// keywords in this grammar).
fn pdemodelica_enabled() -> bool {
    CURRENT_GRAMMAR.with(|g| g.get()) == Grammar::PDEModelica
}

/// `parse_expression_enabled()` from `Modelica.g`: interactive statement
/// parsing also lifts some restrictions (e.g. empty array constructors).
fn parse_expression_enabled() -> bool {
    INTERACTIVE_PARSE.with(|f| f.get())
}

/// True while parsing an interactive `.mos` statement stream (vs. a stored
/// definition). Interactive statements discard expression comments instead of
/// wrapping them in `Absyn.EXPRESSIONCOMMENT`; see [`expression`].
fn is_interactive_parse() -> bool {
    INTERACTIVE_PARSE.with(|f| f.get())
}

// ---------------------------------------------------------------------------
// Error type
// ---------------------------------------------------------------------------

/// Parse error with the position taken directly from the failing token.
#[derive(Debug)]
pub struct ParserError {
    pub line: u32,
    pub col: u32,
    pub inner: ContextError,
    /// The positioned syntax diagnostics recorded while parsing (also left
    /// in the thread-local sink for [`take_syntax_messages`]). Carried here
    /// too so plain `Display` consumers (mmtorust, tests) show the real
    /// diagnostic instead of only a generic context trace.
    pub syntax_messages: Vec<SyntaxMessage>,
}

impl ParserError {
    pub fn from_parse_error(
        err: winnow::error::ParseError<&[LexToken], ContextError>,
        all_tokens: &[LexToken],
    ) -> Self {
        let offset = err.offset();
        let (line, col) = all_tokens
            .get(offset)
            .or_else(|| all_tokens.last())
            .map(|t| (t.line, t.col))
            .unwrap_or((0, 0));
        ParserError { line, col, inner: err.inner().clone(), syntax_messages: Vec::new() }
    }

    pub fn display(&self) -> String {
        let mut out = format!("error: parsing failed at {} {}:{}\n", CURRENT_ERROR_FILE.take(), self.line, self.col);
        for m in &self.syntax_messages {
            out.push_str(&format!(
                "  [{}:{}-{}:{}] {}: {}\n",
                m.line1, m.col1, m.line2, m.col2,
                match m.severity { SyntaxSeverity::Error => "error", SyntaxSeverity::Warning => "warning" },
                m.message,
            ));
        }
        let mut labels: Vec<String> = Vec::new();
        let mut expected: Vec<String> = Vec::new();
        for ctx in self.inner.context() {
            match ctx {
                StrContext::Label(l) => labels.push(l.to_string()),
                StrContext::Expected(StrContextValue::StringLiteral(s)) => {
                    expected.push(format!("{:?}", s));
                }
                StrContext::Expected(StrContextValue::CharLiteral(c)) => {
                    expected.push(format!("{:?}", c));
                }
                StrContext::Expected(e) => expected.push(e.to_string()),
                _ => {}
            }
        }
        if !expected.is_empty() {
            out.push_str(&format!("  expected: {}\n", expected.join(", ")));
        }
        if !labels.is_empty() {
            out.push_str(&format!("  while parsing: {}\n", labels.join(" > ")));
        }
        if let Some(cause) = self.inner.cause() {
            out.push_str(&format!("  caused by: {}\n", cause));
        }
        out
    }
}

impl std::fmt::Display for ParserError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(&self.display())
    }
}

impl std::error::Error for ParserError {}

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Lex `src` and run a single grammar entry point over the token stream,
/// requiring all tokens to be consumed.
///
/// This mirrors how `OMCompiler/Parser/parse.c` selects an entry rule from
/// the `PARSE_*` flags (`stored_definition`, `interactive_stmt`,
/// `name_path_end`, `component_reference_end`,
/// `element_modification_or_replaceable`, `equation`); each public
/// `parse_*` function below corresponds to one of those rules.
fn run_entry<T>(
    src: &str,
    filename: &str,
    info_filename: &str,
    grammar: Grammar,
    interactive: bool,
    readonly: bool,
    timestamp: f64,
    mut entry: fn(&mut &[LexToken]) -> ModalResult<T>,
) -> Result<T, Box<dyn std::error::Error>> {
    CURRENT_FILE.with(|f| *f.borrow_mut() = ArcStr::from(filename));
    CURRENT_READONLY.with(|f| f.set(readonly));
    CURRENT_TIMESTAMP.with(|f| f.set(timestamp));
    CURRENT_ERROR_FILE.with(|f| *f.borrow_mut() = ArcStr::from(info_filename));
    CURRENT_GRAMMAR.with(|g| g.set(grammar));
    INTERACTIVE_PARSE.with(|f| f.set(interactive));
    // Discard diagnostics from a previous parse whose caller never drained
    // them, so this run starts from a clean sink.
    SYNTAX_MESSAGES.with(|m| m.borrow_mut().clear());
    let (tokens, comments) = match lexer::lex_with_comments(src, grammar) {
        Ok(v) => v,
        Err(e) => {
            // Surface lexer failures as positioned diagnostics too, like
            // handleLexerError in Parser/parse.c. The message text is our
            // own — ANTLR's "Lexer got '…' but failed to recognize the
            // rest" depends on its internal lexer state.
            add_syntax_message(SyntaxSeverity::Error, e.message.clone(), e.line, e.col, e.line, e.col);
            return Err(Box::new(e));
        }
    };
    COMMENT_STREAM.with(|s| *s.borrow_mut() = CommentStream::new(comments));
    let result = entry.parse(tokens.as_slice());
    // Don't keep references to the previous file's comments alive across calls.
    COMMENT_STREAM.with(|s| *s.borrow_mut() = CommentStream::empty());
    match result {
        Ok(value) => {
            // Non-fatal syntax errors (`add_syntax_message` with
            // `SyntaxSeverity::Error`) let the parse continue but must fail
            // the entry point, like `ModelicaParser_lexerError` in parse.c.
            let first_err = SYNTAX_MESSAGES.with(|m| {
                m.borrow().iter().find(|m| m.severity == SyntaxSeverity::Error).cloned()
            });
            match first_err {
                None => Ok(value),
                Some(err) => {
                    let messages = SYNTAX_MESSAGES.with(|m| m.borrow().clone());
                    Err(Box::new(ParserError {
                        line: err.line1,
                        col: err.col1,
                        inner: ContextError::new(),
                        syntax_messages: messages,
                    }) as Box<dyn std::error::Error>)
                }
            }
        }
        Err(e) => {
            let failed_at = e.offset();
            let mut parser_error = ParserError::from_parse_error(e, &tokens);
            let has_error_msg = SYNTAX_MESSAGES.with(|m| {
                m.borrow().iter().any(|m| m.severity == SyntaxSeverity::Error)
            });
            if !has_error_msg {
                // No specific diagnostic was recorded: synthesize the generic
                // one the ANTLR3 parser produces (`Parser/parse.c`
                // `displayRecognitionError`).
                add_generic_syntax_error(&tokens, failed_at, src);
            }
            parser_error.syntax_messages = SYNTAX_MESSAGES.with(|m| m.borrow().clone());
            Err(Box::new(parser_error) as Box<dyn std::error::Error>)
        }
    }
}

/// Record the generic diagnostic for a parse failure with no specific
/// recorded message, mirroring ANTLR3's error display (`Parser/parse.c`):
///
/// - mid-stream: `"No viable alternative near token: <text>"`, spanning from
///   LT(1) — the first unconsumed token, 1-based column — to LT(2)'s 0-based
///   column (ANTLR `charPosition` without the usual `+1`).
/// - at end of input: ANTLR reports a mismatched-token exception through its
///   default branch, `"Parser error: <msg> near: <text> (<token>)"`, with the
///   synthetic EOF token sitting at column 0 of the line after the last
///   newline. We approximate ANTLR's exception taxonomy by always using the
///   default branch at EOF; the C parser additionally produces
///   "Expected token of type …" / "Missing token: …" variants from its
///   recovery machinery that a non-recovering parser has no equivalent for.
fn add_generic_syntax_error(tokens: &[LexToken], failed_at: usize, src: &str) {
    match tokens.get(failed_at) {
        Some(lt1) => {
            let (n_line, n_col) = match tokens.get(failed_at + 1) {
                Some(lt2) => (lt2.line, lt2.col.saturating_sub(1)),
                // LT(2) is the synthetic EOF token; ANTLR's `charPosition`
                // for it is -1, clamping the end of the span to the start.
                None => (lt1.line, lt1.col),
            };
            add_syntax_message(
                SyntaxSeverity::Error,
                format!("No viable alternative near token: {}", lexer::source_text(&lt1.kind)),
                lt1.line, lt1.col, n_line, n_col,
            );
        }
        None => {
            // Failure at end of input. ANTLR's EOF token reports
            // charPosition -1 (column 0) on the line following the final
            // newline.
            let eof_line = src.matches('\n').count() as u32 + 1;
            add_syntax_message(
                SyntaxSeverity::Error,
                "Parser error: Unexpected token near:  (<EOF>)".to_owned(),
                eof_line, 0, eof_line, 0,
            );
        }
    }
}

/// Match a required closing `)`. When it is absent, ANTLR's single-token
/// recovery reports `"Missing token: ')'"` at the offending token rather than
/// the generic "No viable alternative"; record that diagnostic and cut so the
/// reported error matches the C parser (e.g. `M(redeclare Real A.c = 2.0)`,
/// `extends A(break a[2])`).
fn expect_rparen(input: &mut TokenInput) -> ModalResult<()> {
    if opt(t(TK::RParen)).parse_next(input)?.is_some() {
        return Ok(());
    }
    let (line, col) = match input.first() {
        Some(tok) => (tok.line, tok.col),
        // At end of input ANTLR puts the synthetic EOF on the line after the
        // last newline; `add_generic_syntax_error` would handle that, but here
        // we still name the missing token.
        None => input.last().map(|t| (t.line, t.col)).unwrap_or((0, 0)),
    };
    add_syntax_message(SyntaxSeverity::Error, "Missing token: ')'".to_owned(), line, col, line, col);
    Err(ErrMode::Cut(ContextError::new()))
}

/// Lex then parse `src`.  Returns the AST or the first error encountered.
pub fn parse(src: &str, filename: &str, info_filename: &str, grammar: Grammar, readonly: bool, timestamp: f64) -> Result<Program, Box<dyn std::error::Error>> {
    run_entry(src, filename, info_filename, grammar, false, readonly, timestamp, stored_definition)
}

/// Parse a `.mos` script / sequence of interactive statements (ANTLR3 rule
/// `interactive_stmt`; entry point for `ParserExt.parseexp` and
/// `ParserExt.parsestringexp`).
pub fn parse_statements(
    src: &str,
    filename: &str,
    info_filename: &str,
    grammar: Grammar,
    readonly: bool,
    timestamp: f64,
) -> Result<crate::GlobalScript::Statements, Box<dyn std::error::Error>> {
    // The pure/impure language-version gating is a property of a full-file
    // parse (set by ParserExt.parse/parsestring); interactive statements and
    // fragments use the default (keywords), so reset any inherited value.
    set_pure_impure_as_ident(false);
    run_entry(src, filename, info_filename, grammar, true, readonly, timestamp, interactive_stmt)
}

/// Parse a dotted name path such as `Modelica.Blocks.Sources` (ANTLR3 rule
/// `name_path_end`; entry point for `ParserExt.stringPath`).
pub fn parse_path(src: &str, filename: &str, grammar: Grammar) -> Result<Path, Box<dyn std::error::Error>> {
    set_pure_impure_as_ident(false);
    run_entry(src, filename, filename, grammar, false, /*readonly=*/false, /*timestamp=*/0.0, name_path)
}

/// Parse a component reference such as `a.b[1].c` (ANTLR3 rule
/// `component_reference_end`; entry point for `ParserExt.stringCref`).
pub fn parse_cref(src: &str, filename: &str, grammar: Grammar) -> Result<Absyn::ComponentRef, Box<dyn std::error::Error>> {
    set_pure_impure_as_ident(false);
    run_entry(src, filename, filename, grammar, false, /*readonly=*/false, /*timestamp=*/0.0, component_reference)
}

/// Parse a single element modification such as `x(start = 1.0)` (ANTLR3 rule
/// `element_modification_or_replaceable`; entry point for `ParserExt.stringMod`).
pub fn parse_modification(src: &str, filename: &str, grammar: Grammar) -> Result<Absyn::ElementArg, Box<dyn std::error::Error>> {
    set_pure_impure_as_ident(false);
    run_entry(src, filename, filename, grammar, false, /*readonly=*/false, /*timestamp=*/0.0, element_modification_or_replaceable)
}

/// Parse a single equation such as `x = y + 1` (ANTLR3 rule `equation`;
/// entry point for `ParserExt.stringEq`).
pub fn parse_equation(src: &str, filename: &str, grammar: Grammar) -> Result<Absyn::EquationItem, Box<dyn std::error::Error>> {
    set_pure_impure_as_ident(false);
    run_entry(src, filename, filename, grammar, false, /*readonly=*/false, /*timestamp=*/0.0, equation_item)
}

// ---------------------------------------------------------------------------
// Intermediate types used during parsing
// ---------------------------------------------------------------------------

#[derive(Debug, Clone)]
pub enum ClassBodyItem {
    Section { section: SectionKind, items: Arc<List<ClassBodyItem>> },
    Element(Absyn::Element),
    Annotation(Absyn::Annotation),
    /// A `//` or `/*` lexer comment captured between elements. Lowered to
    /// `ElementItem::LEXER_COMMENT` inside a class section, preserving the
    /// comment's relative source position next to the surrounding elements.
    LexerComment(ArcStr),
    Equations(Arc<List<EquationItem>>),
    InitialEquations(Arc<List<EquationItem>>),
    Algorithms(Arc<List<AlgorithmItem>>),
    InitialAlgorithms(Arc<List<AlgorithmItem>>),
    Constraints(Arc<List<Arc<Absyn::Exp>>>),
    External {
        /// Language tag from the `external "C"` clause (Modelica allows "C"
        /// and "FORTRAN 77"; OpenModelica only uses "C"). Absent for the bare
        /// `external` marker form.
        lang: Option<ArcStr>,
        /// Explicit C symbol name when the clause spells one out as
        /// `external "C" funcName(...)`; absent when the C name defaults to
        /// the enclosing MetaModelica function's name (the common case).
        funcName: Option<ArcStr>,
        /// Optional `output = ...` binding (`external "C" out = foo(...)`):
        /// the wrapped function returns through this component instead of
        /// through a Modelica `output` declaration position.
        output_: Option<Absyn::ComponentRef>,
        /// Positional argument expressions passed to the C function.
        args: Arc<List<Arc<Absyn::Exp>>>,
        annotation_opt: Option<Absyn::Annotation>,
    },
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum SectionKind { Public, Protected }

#[derive(Debug, Clone)]
pub enum ClassSpecifier {
    Normal  { name: Ident, body: Arc<ClassDef> },
    Extends { name: Ident, body: Arc<ClassDef> },
}

impl ClassSpecifier {
    pub fn name(&self) -> Ident {
        match self {
            ClassSpecifier::Normal  { name, .. } => name.clone(),
            ClassSpecifier::Extends { name, .. } => name.clone(),
        }
    }
    pub fn body(&self) -> Arc<ClassDef> {
        match self {
            ClassSpecifier::Normal  { body, .. } => body.clone(),
            ClassSpecifier::Extends { body, .. } => body.clone(),
        }
    }
}

#[derive(Debug, Clone)]
struct ExtendsClause {
    path: Path,
    modification: Option<Arc<List<Arc<ElementArg>>>>,
    annotation_opt: Option<Annotation>,
}

#[derive(Debug, Clone)]
struct ComponentClause {
    typePrefix: ElementAttributes,
    typeSpec: TypeSpec,
    components: Arc<List<Arc<ComponentItem>>>,
}

/// End column for a span, replicating an ANTLR3 line-1 quirk. `PARSER_INFO`
/// computes the start column as `charPosition + (line==1 ? 2 : 1)` but the end
/// column always as `LT(1)->charPosition + 1`. ANTLR3 reports `charPosition` on
/// line 1 as one less than the true 0-based offset (the `+2` start case
/// compensates), so an end position falling on line 1 comes out one column
/// lower than the true 1-based column the lexer here reports. Mirror that so
/// SOURCEINFO for single-line input (e.g. `loadString("model M …")`,
/// `getClassInformation`) matches the reference omc.
fn end_col_for_line(line: u32, col: u32) -> i32 {
    if line == 1 { col as i32 - 1 } else { col as i32 }
}

/// Build a `SourceInfo` from the rule's first token to the *start* of
/// `lt1`, the first token that is **not** part of the construct.
///
/// This mirrors ANTLR3's `PARSER_INFO($start)` macro in `Modelica.g`,
/// which computes the end position as `LT(1)->line` /
/// `LT(1)->charPosition+1` — the start of the first not-yet-consumed
/// token at the time the rule's action runs. For `;`-terminated
/// constructs whose `;` belongs to the caller (equations, statements,
/// elements, class definitions) the end therefore lands *on* the
/// semicolon, not on the last token of the construct itself.
fn source_info(tok1: &Token, lt1: &Token) -> SourceInfo {
    SourceInfo {
        fileName: CURRENT_FILE.with(|f| f.borrow().clone()),
        isReadOnly: CURRENT_READONLY.with(|f| f.get()),
        lineNumberStart: tok1.line as i32,
        columnNumberStart: tok1.col as i32,
        lineNumberEnd: lt1.line as i32,
        columnNumberEnd: end_col_for_line(lt1.line, lt1.col),
        lastModification: metamodelica::Real::from(CURRENT_TIMESTAMP.with(|f| f.get())),
    }
}

/// `PARSER_INFO($start)` for the common snapshot pattern: `start` is the
/// token stream as it was when the rule was entered and `input` is the
/// current stream, so `input.first()` is `LT(1)`. At end of input the end
/// position falls back to one column past the last consumed token, which
/// is where ANTLR's synthetic EOF token sits.
fn parser_info(start: &TokenInput, input: &TokenInput) -> SourceInfo {
    parser_info_from(&start[0], start, input)
}

/// Like [`parser_info`] but with an explicit start token, for the ANTLR
/// actions that anchor the span at a named token rather than at `$start`
/// (e.g. `PARSER_INFO($eq)` for `EQMOD`, `PARSER_INFO($th)` for a match
/// case's result expression).
fn parser_info_from(first: &Token, start: &TokenInput, input: &TokenInput) -> SourceInfo {
    let (end_line, end_col) = match input.first() {
        Some(lt1) => (lt1.line, lt1.col),
        None => {
            let (l, c) = start[start.len() - 1].end_pos();
            (l, c + 1)
        }
    };
    SourceInfo {
        fileName: CURRENT_FILE.with(|f| f.borrow().clone()),
        isReadOnly: CURRENT_READONLY.with(|f| f.get()),
        lineNumberStart: first.line as i32,
        columnNumberStart: first.col as i32,
        lineNumberEnd: end_line as i32,
        columnNumberEnd: end_col_for_line(end_line, end_col),
        lastModification: metamodelica::Real::from(CURRENT_TIMESTAMP.with(|f| f.get())),
    }
}

// ---------------------------------------------------------------------------
// AST conversion helpers
// ---------------------------------------------------------------------------

/// Separate class-body annotation items from other items.
/// Annotations at the top level and annotations that end up as the trailing items in a
/// public/protected section (when the class has top-level public/protected blocks) are
/// both promoted to class-level annotations.
/// Returns `(non_annotation_items, annotations)`.
fn split_annotations(items: Arc<List<ClassBodyItem>>) -> (Arc<List<ClassBodyItem>>, Arc<List<Arc<Absyn::Annotation>>>) {
    let mut parts: Arc<List<ClassBodyItem>> = Arc::new(List::Nil);
    let mut anns:  Arc<List<Arc<Absyn::Annotation>>> = Arc::new(List::Nil);
    for item in &*items {
        match item {
            ClassBodyItem::Annotation(ann) => anns = cons(Arc::new(ann.clone()), anns),
            ClassBodyItem::Section { section, items: sec_items } => {
                // Annotations that appear directly in a section's element list are
                // class-level annotations (function-level ones are nested inside element bodies).
                let (inner_parts, inner_anns) = split_annotations(Arc::clone(sec_items));
                // inner_anns is already reversed; re-consing restores the
                // inner source order relative to this level's accumulator.
                for ann in &*inner_anns.reverse() { anns = cons(Arc::clone(ann), anns); }
                parts = cons(ClassBodyItem::Section { section: *section, items: inner_parts }, parts);
            }
            other => parts = cons(other.clone(), parts),
        }
    }
    // `anns` is deliberately NOT restored to source order: the C parser
    // accumulates class-level annotations by prepending, so `PARTS.ann` /
    // `CLASS_EXTENDS.ann` hold them in *reverse* source order, and the dump
    // compensates (`listReverse(ann)` in AbsynDumpTpl.tpl `dumpClassDef`).
    // The cons-accumulation above already yields that reversed order.
    (parts.reverse(), anns)
}

fn body_items_to_classparts(items: Arc<List<ClassBodyItem>>) -> Arc<List<Arc<ClassPart>>> {
    let mut res: Arc<List<Arc<ClassPart>>> = Arc::new(List::Nil);
    // Consecutive bare elements (and lexer comments between them) form ONE
    // implicit `public` part, exactly like the leading `element_list` of the
    // ANTLR `composition` rule. Emitting one part per element made
    // `Dump.unparseStr` print a spurious `public` keyword before every
    // element after the first.
    //
    // The leading `public` part is ALWAYS present, even when empty: the ANTLR
    // `composition` rule is `el=element_list els=composition2 ... { ast =
    // PUBLIC(el) :: els }`, so every PARTS body begins with `PUBLIC(el)` where
    // `el` is the (possibly empty) leading element list. Omitting it when the
    // body starts directly with a section (`protected`/`equation`/…) or is
    // empty diverged from the reference AST and broke `save`: its
    // `removeInnerDiffFiledClass` → `ProgramUtil.replacePublicList` *appends* a
    // fresh empty `PUBLIC` at the end (index ≠ 0) when no public part exists,
    // which the dump renders as a spurious trailing `public` keyword (whereas
    // replacing the leading one at index 0 renders nothing).
    let mut pending: Vec<Arc<ElementItem>> = Vec::new();
    let mut leading_public_emitted = false;
    fn flush(pending: &mut Vec<Arc<ElementItem>>, res: &mut Arc<List<Arc<ClassPart>>>, force: bool) {
        if pending.is_empty() && !force {
            return;
        }
        let mut contents: Arc<List<Arc<ElementItem>>> = Arc::new(List::Nil);
        for ei in pending.drain(..).rev() {
            contents = cons(ei, contents);
        }
        *res = cons(Arc::new(ClassPart::PUBLIC { contents }), Arc::clone(res));
    }
    for item in &*items {
        match item {
            ClassBodyItem::Element(elem) => {
                pending.push(Arc::new(ElementItem::ELEMENTITEM { element: Arc::new(elem.clone()) }));
                continue;
            }
            ClassBodyItem::LexerComment(text) => {
                pending.push(Arc::new(ElementItem::LEXER_COMMENT { comment: text.clone() }));
                continue;
            }
            // Force-emit the leading `public` part (even if empty) before the
            // first section, so every PARTS body opens with `PUBLIC(el)`.
            _ => {
                flush(&mut pending, &mut res, !leading_public_emitted);
                leading_public_emitted = true;
            }
        }
        let converted = match item {
            ClassBodyItem::Section { section, items } => {
                let content = body_items_to_element_items(Arc::clone(items));
                match section {
                    SectionKind::Public    => ClassPart::PUBLIC    { contents: content },
                    SectionKind::Protected => ClassPart::PROTECTED { contents: content },
                }
            }
            ClassBodyItem::Element(_) | ClassBodyItem::LexerComment(_) => unreachable!("accumulated into the pending public part above"),
            ClassBodyItem::Annotation(_) => unreachable!("annotations should be split out before body_items_to_classparts"),
            ClassBodyItem::Equations(items)        => ClassPart::EQUATIONS        { contents: to_rc_list(items.clone()) },
            ClassBodyItem::InitialEquations(items) => ClassPart::INITIALEQUATIONS { contents: to_rc_list(items.clone()) },
            ClassBodyItem::Algorithms(items)       => ClassPart::ALGORITHMS       { contents: to_rc_list(items.clone()) },
            ClassBodyItem::InitialAlgorithms(items)=> ClassPart::INITIALALGORITHMS{ contents: to_rc_list(items.clone()) },
            ClassBodyItem::Constraints(contents)   => ClassPart::CONSTRAINTS      { contents: contents.clone() },
            ClassBodyItem::External { lang, funcName, output_, args, annotation_opt } => ClassPart::EXTERNAL {
                externalDecl: Arc::new(ExternalDecl {
                    funcName: funcName.clone(),
                    lang: lang.clone(),
                    output_: output_.clone().map(Arc::new),
                    args: args.clone(),
                    annotation_: annotation_opt.clone().map(Arc::new),
                }),
                annotation_: None,
            },
        };
        res = cons(Arc::new(converted), res);
    }
    // Trailing flush: if no section was ever seen (body is only leading
    // elements, or entirely empty) this emits the always-present leading
    // `public` part; otherwise it flushes any straggling elements.
    flush(&mut pending, &mut res, !leading_public_emitted);
    res.reverse()
}

fn body_items_to_element_items(items: Arc<List<ClassBodyItem>>) -> Arc<List<Arc<ElementItem>>> {
    match &*items {
        List::Nil => Arc::new(List::Nil),
        List::Cons { head, tail } => {
            let converted = match head {
                ClassBodyItem::Element(elem)         => ElementItem::ELEMENTITEM { element: Arc::new(elem.clone()) },
                ClassBodyItem::LexerComment(text)    => ElementItem::LEXER_COMMENT { comment: text.clone() },
                _ => panic!("only Element/LexerComment items can appear inside public/protected sections, but found {:?}", head),
            };
            cons(Arc::new(converted), body_items_to_element_items(tail.clone()))
        }
    }
}

fn to_rc_list<T: Clone>(lst: Arc<List<T>>) -> Arc<List<Arc<T>>> {
    let mut result: Arc<List<Arc<T>>> = Arc::new(List::Nil);
    let rev = lst.reverse();
    for item in &*rev { result = cons(Arc::new(item.clone()), result); }
    result
}

/// Convenience: wrap a value in `Arc::new`.
#[allow(dead_code)]
fn arc<T>(t: T) -> Arc<T> { Arc::new(t) }

fn default_element_attrs() -> ElementAttributes {
    ElementAttributes {
        flowPrefix: false, streamPrefix: false,
        parallelism: Parallelism::NON_PARALLEL {},
        variability: Variability::VAR {},
        // No direction prefix means bidirectional (same default as type_prefix);
        // INPUT here used to leak into `replaceable type T subtypeof Any`, turning
        // every component of type T into a function input.
        direction: Direction::BIDIR {},
        isField: IsField::NONFIELD {},
        arrayDim: Arc::new(List::Nil),
    }
}

// ---------------------------------------------------------------------------
// Parser rules
// ---------------------------------------------------------------------------

/// stored_definition: BOM? (within_clause SEMICOLON)? class_definition_list EOF
fn stored_definition(input: &mut TokenInput) -> ModalResult<Program> {
    // Skip optional BOM token.
    if matches!(peek_kind(input), Some(TK::BOM)) { next_tok(input)?; }

    let within_ = if opt(t(TK::Within)).parse_next(input)?.is_some() {
        let path = opt(name_path).parse_next(input)?;
        cut_err(t(TK::Semi))
            .context(StrContext::Label("';' after within clause"))
            .parse_next(input)?;
        match path {
            Some(path) => Within::WITHIN { path: Arc::new(path) },
            None       => Within::TOP {},
        }
    } else {
        Within::TOP {}
    };

    let classes = class_definition_list(input)?;

    if !input.is_empty() {
        return Err(ErrMode::Backtrack(ContextError::default()));
    }
    Ok(Program { classes: to_rc_list(classes), within_ })
}

/// class_definition_list: (FINAL? class_definition SEMICOLON)*
fn class_definition_list(input: &mut TokenInput) -> ModalResult<Arc<List<Class>>> {
    let mut defs: Arc<List<Class>> = Arc::new(List::Nil);
    loop {
        if input.is_empty() { break; }
        // Take everything that lies textually before the next class header
        // (and its FINAL prefix, if present). These are this class's
        // commentsBeforeClass per ANTLR3 `Modelica.g`.
        let (next_l, next_c) = next_pos(input);
        let before: Vec<ArcStr> = take_comments_before(next_l, next_c);
        let _final = opt(t(TK::Final)).parse_next(input)?.is_some();
        if let Some(def) = opt(class_definition).parse_next(input)? {
            let def = attach_comments_before(def, before);
            defs = cons(def, defs);
            t(TK::Semi).parse_next(input)?;
        } else {
            // No further class: any comments we already drained from the
            // lookahead belong to the previously-parsed last class as
            // commentsAfterEnd.
            if !before.is_empty() {
                defs = attach_comments_after_end_on_head(defs, before);
            }
            break;
        }
    }
    // Drain anything left after the last `end Name;` (e.g. trailing
    // comments at EOF) onto the last class's commentsAfterEnd.
    let trailing = take_comments_remaining();
    if !trailing.is_empty() {
        defs = attach_comments_after_end_on_head(defs, trailing);
    }
    Ok(defs.reverse())
}

/// Returns `c` with its `commentsBeforeClass` field set to `before` (in source
/// order). Used by [`class_definition_list`].
fn attach_comments_before(c: Class, before: Vec<ArcStr>) -> Class {
    if before.is_empty() { return c; }
    let Class {
        name, partialPrefix, finalPrefix, encapsulatedPrefix, restriction,
        body, commentsBeforeClass: _old, commentsBeforeEnd, commentsAfterEnd, info,
    } = c;
    let mut lst: Arc<List<ArcStr>> = Arc::new(List::Nil);
    for txt in before.into_iter().rev() { lst = cons(txt, lst); }
    Class {
        name, partialPrefix, finalPrefix, encapsulatedPrefix, restriction,
        body, commentsBeforeClass: lst, commentsBeforeEnd, commentsAfterEnd, info,
    }
}

/// `defs` is a reverse-order list — its head is the most-recently-parsed
/// class. Append `tail` to that class's `commentsAfterEnd` list.
fn attach_comments_after_end_on_head(
    defs: Arc<List<Class>>,
    tail: Vec<ArcStr>,
) -> Arc<List<Class>> {
    match &*defs {
        List::Nil => defs, // no class to attach to; drop comments silently
        List::Cons { head, tail: rest } => {
            let Class {
                name, partialPrefix, finalPrefix, encapsulatedPrefix, restriction,
                body, commentsBeforeClass, commentsBeforeEnd, commentsAfterEnd, info,
            } = head.clone();
            let lst = commentsAfterEnd;
            // Existing list ordering follows the source; append the new
            // entries to the end.
            let mut new_tail: Arc<List<ArcStr>> = Arc::new(List::Nil);
            for txt in tail.into_iter().rev() { new_tail = cons(txt, new_tail); }
            // Concatenate lst ++ new_tail.
            let mut acc = new_tail;
            let existing: Vec<ArcStr> = (&*lst).into_iter().cloned().collect();
            for txt in existing.into_iter().rev() { acc = cons(txt, acc); }
            let new_head = Class {
                name, partialPrefix, finalPrefix, encapsulatedPrefix, restriction,
                body, commentsBeforeClass, commentsBeforeEnd, commentsAfterEnd: acc, info,
            };
            cons(new_head, rest.clone())
        }
    }
}

/// class_definition: ENCAPSULATED? PARTIAL? FINAL? class_type class_specifier
fn class_definition(input: &mut TokenInput) -> ModalResult<Class> {
    let start = *input;
    let encapsulatedPrefix = opt(t(TK::Encapsulated)).parse_next(input)?.is_some();
    let partialPrefix      = opt(t(TK::Partial)).parse_next(input)?.is_some();
    let finalPrefix        = opt(t(TK::Final)).parse_next(input)?.is_some();
    let restriction        = class_type(input)?;
    let specifier = cut_err(class_specifier)
        .context(StrContext::Label("class specifier"))
        .parse_next(input)?;
    Ok(Class {
        name: specifier.name(), partialPrefix, finalPrefix, encapsulatedPrefix,
        restriction, body: specifier.body(),
        commentsBeforeClass: Arc::new(List::Nil), commentsBeforeEnd: Arc::new(List::Nil),
        commentsAfterEnd: Arc::new(List::Nil), info: parser_info(&start, input),
    })
}

fn class_type(input: &mut TokenInput) -> ModalResult<Restriction> {
    alt((class_type2, class_type_function)).parse_next(input)
}

fn class_type2(input: &mut TokenInput) -> ModalResult<Restriction> {
    let res = match next_tok(input)? {
        TK::Class        => Restriction::R_CLASS,
        TK::Optimization => Restriction::R_OPTIMIZATION,
        TK::Model        => Restriction::R_MODEL,
        TK::Record       => Restriction::R_RECORD,
        TK::Block        => Restriction::R_BLOCK,
        TK::Expandable   => match next_tok(input)? {
            TK::Connector => Restriction::R_EXP_CONNECTOR,
            _             => return Err(ErrMode::Backtrack(ContextError::default())),
        },
        TK::Connector    => Restriction::R_CONNECTOR,
        TK::Type         => Restriction::R_TYPE,
        TK::Package      => Restriction::R_PACKAGE,
        TK::Uniontype    => Restriction::R_UNIONTYPE,
        TK::Operator     => {
            match opt(alt((t(TK::Record),t(TK::Function)))).parse_next(input)? {
                Some(TK::Function) => Restriction::R_FUNCTION {functionRestriction: FunctionRestriction::FR_OPERATOR_FUNCTION },
                Some(TK::Record)   => Restriction::R_OPERATOR_RECORD,
                _                  => Restriction::R_OPERATOR,
            }
        },
        _                => return Err(ErrMode::Backtrack(ContextError::default())),
    };
    Ok(res)
}

fn class_type_function(input: &mut TokenInput) -> ModalResult<Restriction> {
    let purity = match opt(alt((t(TK::Pure), t(TK::Impure)))).parse_next(input)? {
        Some(TK::Pure)   => Absyn::FunctionPurity::PURE,
        Some(TK::Impure) => Absyn::FunctionPurity::IMPURE,
        _ => Absyn::FunctionPurity::NO_PURITY,
    };
    let functionRestriction = try_tok(input, |k| match k {
        TK::Operator  => Some(Absyn::FunctionRestriction::FR_OPERATOR_FUNCTION),
        TK::Parallel  => Some(Absyn::FunctionRestriction::FR_PARALLEL_FUNCTION),
        TK::Parkernel => Some(Absyn::FunctionRestriction::FR_KERNEL_FUNCTION),
        _             => None,
    }).unwrap_or(Absyn::FunctionRestriction::FR_NORMAL_FUNCTION { purity });

    t(TK::Function).parse_next(input)?;
    Ok(Absyn::Restriction::R_FUNCTION { functionRestriction })
}

fn class_specifier(input: &mut TokenInput) -> ModalResult<ClassSpecifier> {
    // `$start` of the ANTLR class_specifier rule: the `extends` keyword or
    // the class name. Used as the span start of the name-mismatch assert.
    let (start_line, start_col) = next_pos(input);
    if opt(t(TK::Extends)).parse_next(input)?.is_some() {
        let name = cut_err(t_ident)
            .context(StrContext::Label("class name after 'extends'"))
            .parse_next(input)?;
        let modifications = opt(class_modification).parse_next(input)?.unwrap_or_else(|| Arc::new(List::Nil));
        let comment   = string_comment(input)?;
        let parts     = cut_err(composition)
            .context(StrContext::Label("class-extends body"))
            .parse_next(input)?;
        // Same annotation handling as the normal-class path below: a
        // class-level `annotation(...)` inside the body must be split out
        // before building the class parts, and merged with any trailing
        // annotation after `end Name`.
        let (non_ann_parts, body_ann) = split_annotations(parts);
        let classParts = body_items_to_classparts(non_ann_parts);
        cut_err(t(TK::End))
            .context(StrContext::Label("'end' closing class-extends"))
            .parse_next(input)?;
        let end_name = t_ident(input)?;
        if end_name != name {
            let (l2, c2) = match input.first() {
                Some(t) => (t.line, t.col.saturating_sub(1)),
                None => (start_line, start_col),
            };
            return Err(parser_assert_fail(
                "The identifier at start and end are different",
                start_line, start_col, l2, c2,
            ));
        }
        let ann = match opt(annotation).parse_next(input)? {
            Some(ann) => {
                t(TK::Semi).parse_next(input)?;
                // body_ann is in reverse source order (see split_annotations); the
                // `end Name annotation(...)` is the latest, so it goes in front.
                cons(Arc::new(ann), body_ann)
            },
            None => body_ann,
        };
        Ok(ClassSpecifier::Extends {
            name: name.clone(),
            body: Arc::new(ClassDef::CLASS_EXTENDS {
                baseClassName: name, modifications, comment, parts: classParts, ann,
            }),
        })
    } else {
        let name = t_ident(input)?;
        let body = class_specifier2(input, &name, start_line, start_col)?;
        Ok(ClassSpecifier::Normal { name, body })
    }
}

/// `start_name` and its position come from the enclosing
/// [`class_specifier`]; the long-form (`… end Name;`) branch checks the
/// closing identifier against it (the `modelicaParserAssert` at
/// `Modelica.g` `class_specifier`).
fn class_specifier2(input: &mut TokenInput, start_name: &ArcStr, start_line: u32, start_col: u32) -> ModalResult<Arc<ClassDef>> {
    if opt(t(TK::Subtypeof)).parse_next(input)?.is_some() {
        let ts = type_specifier(input)?;
        return Ok(Arc::new(ClassDef::DERIVED {
            typeSpec: Arc::new(TypeSpec::TCOMPLEX { path: Arc::new(Path::IDENT{name: "polymorphic".into()}), typeSpecs: List::new(Arc::new(ts)), arrayDim: None }), attributes: default_element_attrs(), arguments: Arc::new(List::Nil), comment: None,
        }));
    }

    if opt(t(TK::Equal)).parse_next(input)?.is_some() {
        if opt(t(TK::Enumeration)).parse_next(input)?.is_some() {
            t(TK::LParen).parse_next(input)?;
            if opt(t(TK::Colon)).parse_next(input)?.is_some() {
                t(TK::RParen).parse_next(input)?;
                // `enumeration(:)` takes a trailing comment just like the
                // literal-list form (`enumeration(:) "Substances in Fluid"`).
                let comment = comment.parse_next(input)?;
                return Ok(Arc::new(ClassDef::ENUMERATION {
                    enumLiterals: Arc::new(EnumDef::ENUM_COLON {}),
                    comment: comment.map(Arc::new),
                }));
            }
            let literals = cut_err(enum_list)
                .context(StrContext::Label("enumeration literal list"))
                .parse_next(input)?;
            t(TK::RParen).parse_next(input)?;
            let comment = comment.parse_next(input)?;
            return Ok(Arc::new(ClassDef::ENUMERATION {
                enumLiterals: Arc::new(EnumDef::ENUMLITERALS { enumLiterals: to_rc_list(literals) }),
                comment: comment.map(Arc::new),
            }));
        }
        if opt(t(TK::Der)).parse_next(input)?.is_some() {
            // `pder` (Modelica.g): a partial function derivative,
            // `function df = der(f, x, ...);` — DER LPAR name_path COMMA ident_list RPAR comment.
            t(TK::LParen).parse_next(input)?;
            let functionName = name_path.parse_next(input)?;
            t(TK::Comma).parse_next(input)?;
            let mut vars = List::new(t_ident(input)?);
            while opt(t(TK::Comma)).parse_next(input)?.is_some() {
                vars = cons(t_ident(input)?, vars);
            }
            t(TK::RParen).parse_next(input)?;
            let comment = comment.parse_next(input)?;
            return Ok(Arc::new(ClassDef::PDER {
                functionName: Arc::new(functionName),
                vars: vars.reverse(),
                comment: comment.map(Arc::new),
            }));
        }
        if opt(t(TK::Overload)).parse_next(input)?.is_some() {
            // function div = $overload(OpenModelica.Internal.intDiv,OpenModelica.Internal.realDiv)
            t(TK::LParen).parse_next(input)?;
            let mut functionNames = List::new(name_path.parse_next(input)?);
            while opt(t(TK::Comma)).parse_next(input)?.is_some() {
                functionNames = cons(name_path.parse_next(input)?, functionNames);
            };
            t(TK::RParen).parse_next(input)?;
            let comment = comment.parse_next(input)?;
            // The cons-built list is back to front; restore the source order —
            // overload resolution tries the candidates in declaration order.
            let functionNames = functionNames.reverse();
            return Ok(Arc::new(ClassDef::OVERLOAD { functionNames: to_rc_list(functionNames), comment: comment.map(Arc::new) }));
        }
        let attributes = type_prefix.parse_next(input)?;
        let typeSpec = cut_err(type_specifier)
            .context(StrContext::Label("type specifier after '='"))
            .parse_next(input)?;
        let arguments: Arc<List<Arc<ElementArg>>> = opt(class_modification).parse_next(input)?.unwrap_or_else(|| Arc::new(List::Nil));
        let comment = comment.parse_next(input)?;
        return Ok(Arc::new(ClassDef::DERIVED {
            typeSpec: Arc::new(typeSpec), attributes, arguments, comment: comment.map(Arc::new),
        }));
    }

    let mut typeVars: Arc<List<ArcStr>> = Arc::new(List::Nil);
    let mut classAttrs: Arc<List<Arc<Absyn::NamedArg>>> = Arc::new(List::Nil);
    if opt(t(TK::Less)).parse_next(input)?.is_some() {
        loop {
            let id = t_ident(input)?;
            typeVars = cons(id, typeVars);
            if opt(t(TK::Greater)).parse_next(input)?.is_some() { break; }
            t(TK::Comma).parse_next(input)?;
        }
        typeVars = typeVars.reverse();
    } else if matches!(peek_kind(input), Some(TK::LParen)) {
        // Optimica class attributes: `optimization Name (objective = x, ...)`.
        // Modelica.g hard-asserts the grammar selection here rather than
        // treating it as a syntax error.
        next_tok(input)?;
        if CURRENT_GRAMMAR.with(|g| g.get()) != Grammar::Optimica {
            let (l2, c2) = next_pos(input);
            return Err(parser_assert_fail(
                "Class attributes are currently allowed only for Optimica. Use -g=Optimica.",
                start_line, start_col, l2, c2,
            ));
        }
        classAttrs = cut_err(named_arguments)
            .context(StrContext::Label("Optimica class attributes"))
            .parse_next(input)?;
        cut_err(t(TK::RParen))
            .context(StrContext::Label("')' closing class attributes"))
            .parse_next(input)?;
    }

    let comment   = string_comment(input)?;
    let parts     = cut_err(composition)
        .context(StrContext::Label("class body"))
        .parse_next(input)?;
    let (non_ann_parts, body_ann) = split_annotations(parts);
    let classParts = body_items_to_classparts(non_ann_parts);
    cut_err(t(TK::End))
        .context(StrContext::Label("'end' closing class body"))
        .parse_next(input)?;
    let end_name = cut_err(t_ident)
        .context(StrContext::Label("class name after 'end'"))
        .parse_next(input)?;
    if end_name != *start_name {
        let (l2, c2) = match input.first() {
            Some(t) => (t.line, t.col.saturating_sub(1)),
            None => (start_line, start_col),
        };
        return Err(parser_assert_fail(
            "The identifier at start and end are different",
            start_line, start_col, l2, c2,
        ));
    }

    // Annotations can appear either inside the class body (body_ann) or after `end Name`
    // (Modelica2 style). Collect both into ann.
    let ann = match opt(annotation).parse_next(input)? {
        Some(ann) => {
            cut_err(t(TK::Semi)).context(StrContext::Label("';' after annotation")).parse_next(input)?;
            // body_ann is in reverse source order (see split_annotations); the
                // `end Name annotation(...)` is the latest, so it goes in front.
                cons(Arc::new(ann), body_ann)
        },
        None => body_ann
    };

    Ok(Arc::new(ClassDef::PARTS {
        typeVars, classAttrs, classParts, ann, comment,
    }))
}

fn composition(input: &mut TokenInput) -> ModalResult<Arc<List<ClassBodyItem>>> {
    let el_items = element_list(input)?;
    let c2_items = composition2(input)?;
    let mut result = el_items.append(&c2_items);
    // Trailing class annotations go at the *end* of the body item list so
    // `split_annotations` sees every annotation in source order.
    let mut trailing: Arc<List<ClassBodyItem>> = Arc::new(List::Nil);
    while let Some(ann) = opt(annotation).parse_next(input)? {
        cut_err(t(TK::Semi)).context(StrContext::Label("';' after annotation")).parse_next(input)?;
        trailing = cons(ClassBodyItem::Annotation(ann), trailing);
    }
    if !trailing.is_empty() {
        result = result.append(&trailing.reverse());
    }
    Ok(result)
}

fn composition2(input: &mut TokenInput) -> ModalResult<Arc<List<ClassBodyItem>>> {
    let mut parts: Arc<List<ClassBodyItem>> = Arc::new(List::Nil);
    loop {
        if input.is_empty() { break; }
        if let Some(ext) = opt(external_part).parse_next(input)? {
            parts = cons(ext, parts); continue;
        }
        if opt(t(TK::Public)).parse_next(input)?.is_some() {
            let items = element_list(input)?;
            parts = cons(ClassBodyItem::Section { section: SectionKind::Public, items }, parts);
            continue;
        }
        if opt(t(TK::Protected)).parse_next(input)?.is_some() {
            let items = element_list(input)?;
            parts = cons(ClassBodyItem::Section { section: SectionKind::Protected, items }, parts);
            continue;
        }
        if opt(t(TK::Initial)).parse_next(input)?.is_some() {
            if opt(t(TK::Equation)).parse_next(input)?.is_some() {
                let (items, anns) = cut_err(equation_section_items)
                    .context(StrContext::Label("initial equation section"))
                    .parse_next(input)?;
                parts = cons(ClassBodyItem::InitialEquations(items), parts);
                for ann in anns { parts = cons(ClassBodyItem::Annotation(ann), parts); }
            } else if opt(t(TK::Algorithm)).parse_next(input)?.is_some() {
                let (items, anns) = cut_err(algorithm_section_items)
                    .context(StrContext::Label("initial algorithm section"))
                    .parse_next(input)?;
                parts = cons(ClassBodyItem::InitialAlgorithms(items), parts);
                for ann in anns { parts = cons(ClassBodyItem::Annotation(ann), parts); }
            } else {
                return Err(ErrMode::Backtrack(ContextError::default()));
            }
            continue;
        }
        if opt(t(TK::Equation)).parse_next(input)?.is_some() {
            let (items, anns) = cut_err(equation_section_items)
                .context(StrContext::Label("equation section"))
                .parse_next(input)?;
            parts = cons(ClassBodyItem::Equations(items), parts);
            for ann in anns { parts = cons(ClassBodyItem::Annotation(ann), parts); }
            continue;
        }
        if opt(t(TK::Algorithm)).parse_next(input)?.is_some() {
            let (items, anns) = cut_err(algorithm_section_items)
                .context(StrContext::Label("algorithm section"))
                .parse_next(input)?;
            parts = cons(ClassBodyItem::Algorithms(items), parts);
            for ann in anns { parts = cons(ClassBodyItem::Annotation(ann), parts); }
            continue;
        }
        if matches!(peek_kind(input), Some(TK::Constraint)) {
            // Optimica `constraint` section (constraint_clause in Modelica.g;
            // the lexer only produces TK::Constraint under -g=Optimica). The
            // ANTLR `constraint` rule nominally admits algorithm-like
            // alternatives (for/while/when clauses), but those would put
            // Algorithm nodes in CONSTRAINTS' list<Exp> — only the expression
            // form is used by real Optimica code, so only that is supported.
            next_tok(input)?;
            let mut constraints: Arc<List<Arc<Absyn::Exp>>> = Arc::new(List::Nil);
            loop {
                if matches!(
                    peek_kind(input),
                    Some(TK::End | TK::Constraint | TK::Equation | TK::Algorithm
                        | TK::Initial | TK::Protected | TK::Public) | None
                ) {
                    break;
                }
                if let Some(ann) = opt(annotation).parse_next(input)? {
                    cut_err(t(TK::Semi))
                        .context(StrContext::Label("';' after constraint annotation"))
                        .parse_next(input)?;
                    parts = cons(ClassBodyItem::Annotation(ann), parts);
                    continue;
                }
                let e = cut_err(expression)
                    .context(StrContext::Label("constraint expression"))
                    .parse_next(input)?;
                cut_err(t(TK::Semi))
                    .context(StrContext::Label("';' after constraint"))
                    .parse_next(input)?;
                constraints = cons(Arc::new(e), constraints);
            }
            parts = cons(ClassBodyItem::Constraints(constraints.reverse()), parts);
            continue;
        }
        break;
    }
    Ok(parts.reverse())
}

/// `constraining_clause_comment?` on a `replaceable` element (Modelica.g):
/// `constrainedby Path mod?` and the pre-Modelica-3 spelling
/// `extends Path mod?` both produce the same `EXTENDS` element spec, followed
/// by the constraining clause's own comment/annotation. Only consulted after
/// a `replaceable` prefix, so it can never swallow a following
/// `extends X;` element — that one is separated by the element's `;`.
fn opt_constraining_clause(input: &mut TokenInput, replaceable_: bool) -> ModalResult<Option<ConstrainClass>> {
    if !replaceable_
        || !matches!(peek_kind(input), Some(TK::Constrainedby) | Some(TK::Extends))
    {
        return Ok(None);
    }
    next_tok(input)?;
    let path       = cut_err(name_path).context(StrContext::Label("path in constraining clause")).parse_next(input)?;
    let elementArg = opt(class_modification).parse_next(input)?.unwrap_or_else(|| Arc::new(List::Nil));
    let cmt        = comment(input)?;
    Ok(Some(ConstrainClass {
        elementSpec: Arc::new(ElementSpec::EXTENDS { path: Arc::new(path), elementArg, annotationOpt: None }),
        comment: cmt.map(Arc::new),
    }))
}

fn element_list(input: &mut TokenInput) -> ModalResult<Arc<List<ClassBodyItem>>> {
    let mut items: Arc<List<ClassBodyItem>> = Arc::new(List::Nil);
    loop {
        if input.is_empty() {
            // Flush any comments that follow the last element so they are
            // still preserved at the tail of the list.
            for txt in take_comments_before(u32::MAX, u32::MAX) {
                items = cons(ClassBodyItem::LexerComment(txt), items);
            }
            break;
        }
        // Drain any lexer comments whose source position precedes the next
        // token. They get spliced into the element list as LexerComment
        // items, preserving source order. This is a safe checkpoint because
        // `element_list` only commits forward through `;`-terminated items;
        // no caller backtracks across an entire element.
        let (next_l, next_c) = (input[0].line, input[0].col);
        for txt in take_comments_before(next_l, next_c) {
            items = cons(ClassBodyItem::LexerComment(txt), items);
        }
        let first_tok = &input[0];
        match peek_kind(input) {
            Some(TK::Public) | Some(TK::Protected) | Some(TK::Equation) | Some(TK::Algorithm)
            | Some(TK::External) | Some(TK::End) | Some(TK::Initial) | Some(TK::Case)
            | Some(TK::Else) | Some(TK::Then) | None => break,
            Some(TK::Connect) => {
                // `element` rule, `conn=CONNECT` alternative: a connect
                // equation in an element section gets a dedicated hint.
                let (l1, c1) = (input[0].line, input[0].col);
                next_tok(input)?;
                let (l2, c2) = match input.first() {
                    Some(t) => (t.line, t.col.saturating_sub(1)),
                    None => (l1, c1 + 6),
                };
                return Err(parser_assert_fail(
                    "Found the start of a connect equation but expected an element (are you missing the equation keyword?)",
                    l1, c1, l2, c2,
                ));
            }
            _ => {}
        }

        if let Some(ann) = opt(annotation).parse_next(input)? {
            cut_err(t(TK::Semi)).context(StrContext::Label("';' after annotation")).parse_next(input)?;
            items = cons(ClassBodyItem::Annotation(ann), items); continue;
        }
        if let Some(elem) = opt(element).parse_next(input)? {
            items = cons(ClassBodyItem::Element(elem), items); continue;
        }
        if let Some(imp) = opt(import_clause).parse_next(input)? {
            let comment = comment.parse_next(input)?;
            let last_tok = &input[0];
            cut_err(t(TK::Semi)).context(StrContext::Label("';' after import clause")).parse_next(input)?;
            let info = source_info(first_tok, last_tok);
            let elem = Absyn::Element::ELEMENT {
                finalPrefix: false, redeclareKeywords: None,
                innerOuter: InnerOuter::NOT_INNER_OUTER, specification: Arc::new(ElementSpec::IMPORT { import_: imp, comment: comment.map(Arc::new), info: info.clone() }),
                info, constrainClass: None,
            };
            items = cons(ClassBodyItem::Element(elem), items); continue;
        }
        if let Some(ext) = opt(extends_clause).parse_next(input)? {
            let last_tok = &input[0];
            cut_err(t(TK::Semi)).context(StrContext::Label("';' after extends clause")).parse_next(input)?;
            let info = source_info(first_tok, last_tok);
            let elem = Absyn::Element::ELEMENT {
                finalPrefix: false,
                redeclareKeywords: None,
                innerOuter: InnerOuter::NOT_INNER_OUTER {},
                specification: Arc::new(ElementSpec::EXTENDS {
                    path: Arc::new(ext.path),
                    elementArg: ext.modification.unwrap_or_else(|| Arc::new(List::Nil)),
                    annotationOpt: ext.annotation_opt.map(Arc::new),
                }),
                info,
                constrainClass: None,
            };
            items = cons(ClassBodyItem::Element(elem), items); continue;
        }
        // element prefixes: [ redeclare ] [ final ] [ inner ] [ outer ]
        //   then ( [replaceable] class_definition | [replaceable] component_clause )
        //   with optional constrainedby clause if replaceable
        let redeclare_  = opt(t(TK::Redeclare)).parse_next(input)?.is_some();
        let final_      = opt(t(TK::Final)).parse_next(input)?.is_some();
        let inner_      = opt(t(TK::Inner)).parse_next(input)?.is_some();
        let outer_      = opt(t(TK::Outer)).parse_next(input)?.is_some();
        let replaceable_ = opt(t(TK::Replaceable)).parse_next(input)?.is_some();

        let redeclareKeywords: Option<RedeclareKeywords> = match (redeclare_, replaceable_) {
            (true,  true)  => Some(RedeclareKeywords::REDECLARE_REPLACEABLE),
            (true,  false) => Some(RedeclareKeywords::REDECLARE),
            (false, true)  => Some(RedeclareKeywords::REPLACEABLE),
            (false, false) => None,
        };
        let innerOuter = match (inner_, outer_) {
            (true,  true)  => InnerOuter::INNER_OUTER,
            (true,  false) => InnerOuter::INNER,
            (false, true)  => InnerOuter::OUTER,
            (false, false) => InnerOuter::NOT_INNER_OUTER,
        };

        let had_prefixes = redeclare_ || final_ || inner_ || outer_ || replaceable_;

        if let Some(cls) = opt(class_definition).parse_next(input)? {
            let constrainClass = opt_constraining_clause(input, replaceable_)?;
            let last_tok = &input[0];
            cut_err(t(TK::Semi)).context(StrContext::Label("';' after class definition")).parse_next(input)?;
            let elem = Absyn::Element::ELEMENT {
                finalPrefix: final_, redeclareKeywords, innerOuter,
                specification: Arc::new(ElementSpec::CLASSDEF { replaceable_, class_: Arc::new(cls) }),
                info: source_info(first_tok, last_tok), constrainClass: constrainClass.map(Arc::new),
            };
            items = cons(ClassBodyItem::Element(elem), items); continue;
        }
        if let Some(cc) = opt(component_clause).parse_next(input)? {
            let constrainClass = opt_constraining_clause(input, replaceable_)?;
            let last_tok = &input[0];
            let elem = Absyn::Element::ELEMENT {
                finalPrefix: final_, redeclareKeywords, innerOuter,
                specification: Arc::new(ElementSpec::COMPONENTS {
                    attributes: cc.typePrefix, typeSpec: Arc::new(cc.typeSpec), components: cc.components,
                }),
                info: source_info(first_tok, last_tok), constrainClass: constrainClass.map(Arc::new),
            };
            cut_err(t(TK::Semi))
                .context(StrContext::Label("';' after component list"))
                .parse_next(input)?;
            items = cons(ClassBodyItem::Element(elem), items); continue;
        }

        if had_prefixes {
            return Err(ErrMode::Cut(ContextError::new().add_context(
                input, &input.checkpoint(),
                StrContext::Label("class definition or component clause after element prefixes"),
            )));
        }
        break;
    }
    Ok(items.reverse())
}

fn element(input: &mut TokenInput) -> ModalResult<Absyn::Element> {
    let first_tok = &input[0];
    if let Some(imp) = opt(import_clause).parse_next(input)? {
        let comment = comment.parse_next(input)?;
        let last_tok = &input[0];
        cut_err(t(TK::Semi)).context(StrContext::Label("';' after import clause")).parse_next(input)?;
        let info = source_info(first_tok, last_tok);
        let elem = Absyn::Element::ELEMENT {
            finalPrefix: false, redeclareKeywords: None,
            innerOuter: InnerOuter::NOT_INNER_OUTER, specification: Arc::new(ElementSpec::IMPORT { import_: imp, comment: comment.map(Arc::new), info: info.clone() }),
            info, constrainClass: None,
        };
        return Ok(elem);
    }
    if let Some(ext) = opt(extends_clause).parse_next(input)? {
        let last_tok = &input[0];
        cut_err(t(TK::Semi)).context(StrContext::Label("';' after extends clause")).parse_next(input)?;
        let info = source_info(first_tok, last_tok);
        let elem = Absyn::Element::ELEMENT {
            finalPrefix: false,
            redeclareKeywords: None,
            innerOuter: InnerOuter::NOT_INNER_OUTER {},
            specification: Arc::new(ElementSpec::EXTENDS {
                path: Arc::new(ext.path),
                elementArg: ext.modification.unwrap_or_else(|| Arc::new(List::Nil)),
                annotationOpt: ext.annotation_opt.map(Arc::new),
            }),
            info,
            constrainClass: None,
        };
        return Ok(elem);
    }
    // element prefixes: [ redeclare ] [ final ] [ inner ] [ outer ]
    //   then ( [replaceable] class_definition | [replaceable] component_clause )
    //   with optional constrainedby clause if replaceable
    let redeclare_  = opt(t(TK::Redeclare)).parse_next(input)?.is_some();
    let final_      = opt(t(TK::Final)).parse_next(input)?.is_some();
    let inner_      = opt(t(TK::Inner)).parse_next(input)?.is_some();
    let outer_      = opt(t(TK::Outer)).parse_next(input)?.is_some();
    let replaceable_ = opt(t(TK::Replaceable)).parse_next(input)?.is_some();

    let redeclareKeywords: Option<RedeclareKeywords> = match (redeclare_, replaceable_) {
        (true,  true)  => Some(RedeclareKeywords::REDECLARE_REPLACEABLE),
        (true,  false) => Some(RedeclareKeywords::REDECLARE),
        (false, true)  => Some(RedeclareKeywords::REPLACEABLE),
        (false, false) => None,
    };
    let innerOuter = match (inner_, outer_) {
        (true,  true)  => InnerOuter::INNER_OUTER,
        (true,  false) => InnerOuter::INNER,
        (false, true)  => InnerOuter::OUTER,
        (false, false) => InnerOuter::NOT_INNER_OUTER,
    };

    let had_prefixes = redeclare_ || final_ || inner_ || outer_ || replaceable_;

    if let Some(cls) = opt(class_definition).parse_next(input)? {
        let constrainClass = opt_constraining_clause(input, replaceable_)?;
        let last_tok = &input[0];
        cut_err(t(TK::Semi)).context(StrContext::Label("';' after class definition")).parse_next(input)?;
        let elem = Absyn::Element::ELEMENT {
            finalPrefix: final_, redeclareKeywords, innerOuter,
            specification: Arc::new(ElementSpec::CLASSDEF { replaceable_, class_: Arc::new(cls) }),
            info: source_info(first_tok, last_tok), constrainClass: constrainClass.map(Arc::new),
        };
        return Ok(elem);
    }
    if let Some(cc) = opt(component_clause).parse_next(input)? {
        let constrainClass = opt_constraining_clause(input, replaceable_)?;
        let last_tok = &input[0];
        let elem = Absyn::Element::ELEMENT {
            finalPrefix: final_, redeclareKeywords, innerOuter,
            specification: Arc::new(ElementSpec::COMPONENTS {
                attributes: cc.typePrefix, typeSpec: Arc::new(cc.typeSpec), components: cc.components,
            }),
            info: source_info(first_tok, last_tok), constrainClass: constrainClass.map(Arc::new),
        };
        cut_err(t(TK::Semi))
            .context(StrContext::Label("';' after component list"))
            .parse_next(input)?;
        return Ok(elem);
    }

    if had_prefixes {
        return Err(ErrMode::Cut(ContextError::new().add_context(
            input, &input.checkpoint(),
            StrContext::Label("class definition or component clause after element prefixes"),
        )));
    }
    Err(ErrMode::Backtrack(ContextError::default()))
}

fn type_prefix(input: &mut TokenInput) -> ModalResult<ElementAttributes> {
    let flow   = try_tok(input, |k| matches!(k, TK::Flow).then_some(())).is_some();
    let stream = !flow && try_tok(input, |k| matches!(k, TK::Stream).then_some(())).is_some();

    let parallelism = try_tok(input, |k| match k {
        TK::Parlocal  => Some(Parallelism::PARLOCAL),
        TK::Parglobal => Some(Parallelism::PARGLOBAL),
        _             => None,
    }).unwrap_or(Parallelism::NON_PARALLEL);

    let variability = try_tok(input, |k| match k {
        TK::Discrete  => Some(Variability::DISCRETE),
        TK::Parameter => Some(Variability::PARAM),
        TK::Constant  => Some(Variability::CONST),
        _             => None,
    }).unwrap_or(Variability::VAR);

    let has_input  = opt(t(TK::Input)).parse_next(input)?.is_some();
    let has_output = opt(t(TK::Output)).parse_next(input)?.is_some();
    let direction  = match (has_input, has_output) {
        (true,  true)  => Direction::INPUT_OUTPUT,
        (true,  false) => Direction::INPUT,
        (false, true)  => Direction::OUTPUT,
        (false, false) => Direction::BIDIR,
    };

    // `field`/`nonfield` are keywords only in the PDEModelica grammar; the lexer
    // emits them as `Ident` otherwise, so they stay valid type/component names.
    let is_field = try_tok(input, |k| match k {
        TK::Field    => Some(IsField::FIELD),
        TK::Nonfield => Some(IsField::NONFIELD),
        _            => None,
    }).unwrap_or(IsField::NONFIELD);

    Ok(ElementAttributes {
        flowPrefix: flow, streamPrefix: stream, parallelism, variability, direction,
        isField: is_field, arrayDim: Arc::new(List::Nil),
    })
}

fn component_clause(input: &mut TokenInput) -> ModalResult<ComponentClause> {
    let mut typePrefix = type_prefix(input)?;
    let mut typeSpec   = type_specifier(input)?;
    // Type-bound array dimensions (`Integer[2] x`) live on the attributes,
    // not the type: the ANTLR parser moves the type_specifier's subscripts
    // into `Absyn.ATTR.arrayDim` and clears them on the TypeSpec, and
    // everything downstream reads them from the attributes.
    let dims = match &mut typeSpec {
        TypeSpec::TPATH { arrayDim, .. } | TypeSpec::TCOMPLEX { arrayDim, .. } => arrayDim.take(),
    };
    if let Some(dims) = dims {
        typePrefix.arrayDim = dims;
    }
    let components = cut_err(component_list)
        .context(StrContext::Label("component list"))
        .parse_next(input)?;
    Ok(ComponentClause { typePrefix, typeSpec, components })
}

fn component_list(input: &mut TokenInput) -> ModalResult<Arc<List<Arc<ComponentItem>>>> {
    let first = component_declaration(input)?;
    let mut items = List::new(Arc::new(first));
    loop {
        if opt(t(TK::Comma)).parse_next(input)?.is_none() { break; }
        items = cons(Arc::new(component_declaration(input)?), items);
    }
    Ok(items.reverse())
}

fn component_declaration(input: &mut TokenInput) -> ModalResult<ComponentItem> {
    // Peek before consuming: a non-name token must leave the cursor in place so
    // the failure (and its `No viable alternative near token: …` diagnostic) is
    // reported at that token, not at the one after it.
    let name = match peek_kind(input) {
        Some(TK::Ident(n)) => n.clone(),
        Some(TK::Operator) => literal!("operator"),
        _ => return Err(ErrMode::Backtrack(ContextError::default())),
    };
    next_tok(input)?; // consume the validated name token
    let arrayDim  = opt(array_subscripts).parse_next(input)?.unwrap_or_else(|| Arc::new(List::Nil));
    let m         = opt(modification).parse_next(input)?;
    let condition = if opt(t(TK::If)).parse_next(input)?.is_some() {
        Some(expression(input)?)
    } else { None };
    let cmt = comment(input)?;
    Ok(ComponentItem {
        component: Component { name, arrayDim, modification: m.map(Arc::new) },
        condition: condition.map(Arc::new),
        comment: cmt.map(Arc::new),
    })
}

fn modification(input: &mut TokenInput) -> ModalResult<Modification> {
    let cm = opt(class_modification).parse_next(input)?.unwrap_or_else(|| Arc::new(List::Nil));
    // ANTLR anchors the EQMOD info at the `=`/`:=` token
    // (`PARSER_INFO($eq)`), not at the start of the whole modification.
    let eq_start = *input;
    let eq = if opt(alt((t(TK::Assign), t(TK::Equal)))).parse_next(input)?.is_some() {
        let exp = cut_err(modification_expression)
                .context(StrContext::Label("modification expression"))
                .parse_next(input)?;
        Absyn::EqMod::EQMOD {
            exp: Arc::new(exp),
            info: parser_info(&eq_start, input),
        }
    } else {
        Absyn::EqMod::NOMOD
    };
    Ok(Modification { elementArgLst: cm, eqMod: Arc::new(eq) })
}

fn modification_expression(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    if opt(t(TK::Break)).parse_next(input)?.is_some() {
        return Ok(Absyn::Exp::BREAK {});
    }
    expression(input)
}

fn class_modification(input: &mut TokenInput) -> ModalResult<Arc<List<Arc<ElementArg>>>> {
    class_modification_impl(input, false)
}

/// `class_or_inheritance_modification` (Modelica.g): like
/// [`class_modification`] but the arguments may also be `break ...`
/// inheritance modifications (`extends A(break x)`). Only extends clauses
/// accept these (`argument_list[1]` in the ANTLR grammar).
fn class_or_inheritance_modification(input: &mut TokenInput) -> ModalResult<Arc<List<Arc<ElementArg>>>> {
    class_modification_impl(input, true)
}

fn class_modification_impl(input: &mut TokenInput, can_have_break: bool) -> ModalResult<Arc<List<Arc<ElementArg>>>> {
    t(TK::LParen).parse_next(input)?;
    let arguments = opt(|i: &mut TokenInput| argument_list(i, can_have_break))
        .parse_next(input)?
        .unwrap_or_else(|| Arc::new(List::Nil));
    expect_rparen(input)?;
    Ok(arguments)
}

fn argument_list(input: &mut TokenInput, can_have_break: bool) -> ModalResult<Arc<List<Arc<ElementArg>>>> {
    // Mirror the ANTLR3 `argument_list` rule's comment handling: a line/block
    // comment that precedes an argument is preserved as an
    // `Absyn.ELEMENTARGCOMMENT` spliced into the list right before that
    // argument, and any comments trailing the last argument (before the
    // closing `)`) are appended. This is what lets `list`/save round-trip
    // class-modification comments such as the `// comment` before `Placement`
    // in an annotation (openmodelica/interactive-API/CopyClass6). Without it
    // the leading comment leaks forward and is swallowed by the next inner
    // expression's `EXPRESSIONCOMMENT`.
    let cursor = save_comment_cursor();
    let mut out: Vec<Arc<ElementArg>> = Vec::new();

    let push_comments_before = |out: &mut Vec<Arc<ElementArg>>, input: &TokenInput| {
        let (line, col) = next_pos(input);
        for txt in take_comments_before(line, col) {
            out.push(Arc::new(ElementArg::ELEMENTARGCOMMENT { comment: txt }));
        }
    };

    push_comments_before(&mut out, input);
    match argument_or_break(input, can_have_break) {
        Ok(a) => out.push(Arc::new(a)),
        // No (further) argument: an empty `()` reaches here via `opt`. Restore
        // the comment cursor so the drained comments are reclaimed by the
        // surrounding checkpoint rather than lost on backtrack.
        Err(e) => { restore_comment_cursor(cursor); return Err(e); }
    }
    loop {
        if opt(t(TK::Comma)).parse_next(input)?.is_none() { break; }
        push_comments_before(&mut out, input);
        out.push(Arc::new(argument_or_break(input, can_have_break)?));
    }
    // Comments between the last argument and the closing `)`.
    push_comments_before(&mut out, input);

    let mut res: Arc<List<Arc<ElementArg>>> = Arc::new(List::Nil);
    for e in out.into_iter().rev() { res = cons(e, res); }
    Ok(res)
}

fn argument_or_break(input: &mut TokenInput, can_have_break: bool) -> ModalResult<ElementArg> {
    if can_have_break && matches!(peek_kind(input), Some(TK::Break)) {
        inheritance_modification(input)
    } else {
        argument(input)
    }
}

/// `inheritance_modification` (Modelica.g): `break connect(a, b)` removes
/// the inherited connection, `break x` removes the inherited component
/// `x`. The latter is stored as `connect(break, x)` to reuse the
/// connect-equation shape, mirroring the ANTLR action.
fn inheritance_modification(input: &mut TokenInput) -> ModalResult<ElementArg> {
    let start = *input;
    t(TK::Break).parse_next(input)?;
    let cnct = if matches!(peek_kind(input), Some(TK::Connect)) {
        connect_equation(input)?
    } else {
        let name = t_ident(input)?;
        Equation::EQ_CONNECT {
            connector1: Arc::new(ComponentRef::CREF_IDENT {
                name: literal!("break"),
                subscripts: Arc::new(List::Nil),
            }),
            connector2: Arc::new(ComponentRef::CREF_IDENT {
                name,
                subscripts: Arc::new(List::Nil),
            }),
        }
    };
    Ok(ElementArg::INHERITANCEBREAK { cnct: Arc::new(cnct), info: parser_info(&start, input) })
}

fn argument(input: &mut TokenInput) -> ModalResult<ElementArg> {
    if let Some(r) = opt(element_redeclaration).parse_next(input)? { return Ok(r); }
    let eachPrefix_  = opt(t(TK::Each)).parse_next(input)?.is_some();
    let finalPrefix_ = opt(t(TK::Final)).parse_next(input)?.is_some();
    let mut res = alt((element_replaceable, element_modification)).parse_next(input)?;
    // `element_modification_or_replaceable` (Modelica.g) applies the leading
    // `each`/`final` prefixes to whichever branch matched: `element_modification`
    // yields a MODIFICATION, the bare-`replaceable` branch a REDECLARATION.
    match res {
        ElementArg::MODIFICATION { ref mut eachPrefix, ref mut finalPrefix, .. }
        | ElementArg::REDECLARATION { ref mut eachPrefix, ref mut finalPrefix, .. } => {
            *eachPrefix  = if eachPrefix_  { Each::EACH } else { Each::NON_EACH };
            *finalPrefix = finalPrefix_;
        }
        _ => return Err(ErrMode::Backtrack(ContextError::default())),
    }
    Ok(res)
}

// Shared body for the 'replaceable' branch: parses the class-or-component spec
// and the optional 'constrainedby' clause.  Called by both element_replaceable
// and the REDECLARE_REPLACEABLE branch of element_redeclaration.
fn parse_replaceable_spec(input: &mut TokenInput) -> ModalResult<(ElementSpec, Option<ConstrainClass>)> {
    let elementSpec = if let Some(cls) = opt(class_definition).parse_next(input)? {
        ElementSpec::CLASSDEF { replaceable_: true, class_: Arc::new(cls) }
    } else {
        let typePrefix = type_prefix(input)?;
        let typeSpec   = cut_err(type_specifier_no_dims)
            .context(StrContext::Label("type specifier in replaceable"))
            .parse_next(input)?;
        let comp       = cut_err(component_declaration)
            .context(StrContext::Label("component declaration in replaceable"))
            .parse_next(input)?;
        ElementSpec::COMPONENTS { attributes: typePrefix, typeSpec: Arc::new(typeSpec), components: List::new(Arc::new(comp)) }
    };
    let constrainClass = opt_constraining_clause(input, true)?;
    Ok((elementSpec, constrainClass))
}

fn element_redeclaration(input: &mut TokenInput) -> ModalResult<ElementArg> {
    let start = *input;
    t(TK::Redeclare).parse_next(input)?;
    let each_  = opt(t(TK::Each)).parse_next(input)?.is_some();
    let final_ = opt(t(TK::Final)).parse_next(input)?.is_some();

    // Position at the `replaceable` keyword (after redeclare/each/final). The
    // `redeclare replaceable` form is built by `element_replaceable`, whose
    // `PARSER_INFO($start)` starts at `replaceable`, not at `redeclare`; the
    // other forms use `element_redeclaration`'s own start (the `redeclare`).
    let repl_start = *input;
    let (redeclareKeywords, elementSpec, constrainClass, info) =
        if opt(t(TK::Replaceable)).parse_next(input)?.is_some() {
            let (es, cc) = parse_replaceable_spec(input)?;
            (RedeclareKeywords::REDECLARE_REPLACEABLE {}, es, cc, parser_info(&repl_start, input))
        } else if let Some(cls) = opt(class_definition).parse_next(input)? {
            (RedeclareKeywords::REDECLARE, ElementSpec::CLASSDEF { replaceable_: false, class_: Arc::new(cls) }, None, parser_info(&start, input))
        } else {
            let typePrefix = type_prefix(input)?;
            let typeSpec   = cut_err(type_specifier_no_dims)
                .context(StrContext::Label("type specifier in redeclaration"))
                .parse_next(input)?;
            let comp       = cut_err(component_declaration)
                .context(StrContext::Label("component declaration in redeclaration"))
                .parse_next(input)?;
            (RedeclareKeywords::REDECLARE, ElementSpec::COMPONENTS {
                attributes: typePrefix, typeSpec: Arc::new(typeSpec), components: List::new(Arc::new(comp)),
            }, None, parser_info(&start, input))
        };

    Ok(ElementArg::REDECLARATION {
        finalPrefix: final_,
        eachPrefix: if each_ { Each::EACH } else { Each::NON_EACH },
        redeclareKeywords, elementSpec: Arc::new(elementSpec), constrainClass: constrainClass.map(Arc::new), info,
    })
}

fn element_modification(input: &mut TokenInput) -> ModalResult<ElementArg> {
    let start = *input;
    let path = name_path(input)?;
    if opt(t(TK::LBracket)).parse_next(input)?.is_some() {
        // `element_modification` in Modelica.g records this diagnostic and
        // lets ANTLR's recovery resynchronize. We abort instead — the
        // recorded message suppresses the generic fallback, so the
        // observable diagnostic is the same.
        let (l2, c2) = match input.first() {
            Some(t) => (t.line, t.col.saturating_sub(1)),
            None => (start[0].line, start[0].col),
        };
        add_syntax_message(
            SyntaxSeverity::Error,
            "Subscripting modifiers is not allowed. Apply the modification on the whole identifier using an array-expression or an each-modifier.".to_owned(),
            start[0].line, start[0].col, l2, c2,
        );
        return Err(ErrMode::Cut(ContextError::new()));
    }
    let modification = opt(modification).parse_next(input)?;
    let comment      = string_comment(input)?;
    Ok(Absyn::ElementArg::MODIFICATION {
        eachPrefix: Each::NON_EACH {}, finalPrefix: false,
        modification: modification.map(Arc::new), comment, path: Arc::new(path), info: parser_info(&start, input),
    })
}

fn element_replaceable(input: &mut TokenInput) -> ModalResult<ElementArg> {
    let start = *input;
    t(TK::Replaceable).parse_next(input)?;
    let (elementSpec, constrainClass) = parse_replaceable_spec(input)?;
    Ok(ElementArg::REDECLARATION {
        finalPrefix: false, eachPrefix: Each::NON_EACH {},
        redeclareKeywords: RedeclareKeywords::REPLACEABLE {},
        elementSpec: Arc::new(elementSpec), constrainClass: constrainClass.map(Arc::new), info: parser_info(&start, input),
    })
}

fn annotation(input: &mut TokenInput) -> ModalResult<Annotation> {
    t(TK::Annotation).parse_next(input)?;
    Ok(Absyn::Annotation {
        elementArgs: cut_err(class_modification)
            .context(StrContext::Label("annotation body"))
            .parse_next(input)?,
    })
}

fn import_clause(input: &mut TokenInput) -> ModalResult<Import> {
    t(TK::Import).parse_next(input)?;
    // `name_path2`, not `name_path`: the implicit-import name (`name_path_star`
    // in Modelica.g) and the named-import LHS do not accept a leading dot, so
    // `import .P;` must be rejected. Only the named-import RHS below allows the
    // fully-qualified `.P` form (via `name_path`). `cut_err` commits once the
    // `import` keyword is seen, so the error is pinned to the offending token
    // (the `.`) instead of backtracking out to the enclosing element parser.
    let path = cut_err(name_path2).parse_next(input)?;
    // Group import: import Path.{Name, NewName = OldName, ...}
    // The dot before '{' is not consumed by name_path (it only follows dots to idents).
    match opt(alt((t(TK::StarEw), t(TK::Dot), t(TK::Equal)))).parse_next(input)? {
        Some(TK::StarEw) => Ok(Import::UNQUAL_IMPORT { path: Arc::new(path) }),
        Some(TK::Dot) => match alt((t(TK::LBrace),t(TK::Star))).parse_next(input)? {
            TK::Star => Ok(Import::UNQUAL_IMPORT { path: Arc::new(path) }), // Modelica 2 where .* is not a separate token
            TK::LBrace => {
                let mut groups: Arc<List<GroupImport>> = Arc::new(List::Nil);
                loop {
                    let first = t_any_ident(input)?;
                    let gi = if opt(t(TK::Equal)).parse_next(input)?.is_some() {
                        GroupImport::GROUP_IMPORT_RENAME { rename: first, name: t_any_ident(input)? }
                    } else {
                        GroupImport::GROUP_IMPORT_NAME { name: first }
                    };
                    groups = cons(gi, groups);
                    if opt(t(TK::Comma)).parse_next(input)?.is_none() { break; }
                }
                cut_err(t(TK::RBrace))
                    .context(StrContext::Label("'}' closing group import"))
                    .parse_next(input)?;
                Ok(Import::GROUP_IMPORT { prefix: Arc::new(path), groups: groups.reverse() })
            }
            _ => unreachable!(),
        },
        Some(TK::Equal) => {
            let name = match path {
                Path::IDENT{name} => name,
                _ => return Err(ErrMode::Cut(ContextError::new().add_context(
                    input,
                    &input.checkpoint(),
                    StrContext::Label("Named imports take identifiers only, but found a path before equals."),
                )))
            };
            let path = name_path.parse_next(input)?;
            Ok(Import::NAMED_IMPORT { name, path: Arc::new(path) })
        }
        _ => Ok(Import::QUAL_IMPORT { path: Arc::new(path) }),
    }
}

fn extends_clause(input: &mut TokenInput) -> ModalResult<ExtendsClause> {
    t(TK::Extends).parse_next(input)?;
    let path         = name_path(input)?;
    let modification = opt(class_or_inheritance_modification).parse_next(input)?;
    let annotation_opt = opt(annotation).parse_next(input)?;
    Ok(ExtendsClause { path, modification, annotation_opt })
}

/// Parse an `external` clause according to the Modelica spec:
///
/// ```text
/// external_clause      ::= "external" [ language_specification ]
///                                     [ external_function_call ]
///                                     [ annotation ] ";"
/// language_specification ::= STRING                              // e.g. "C"
/// external_function_call ::= [ component_reference "=" ]
///                            IDENT "(" [ expression_list ] ")"
/// ```
///
/// All sub-parts are optional individually — `external;` is a legal bare
/// marker, and `external annotation(...);` skips both the language tag and
/// the function call. We commit to one possible shape with `opt` per part so
/// the grammar stays close to the spec and unusual but legal combinations
/// (`external "C"  ;`) are accepted without bespoke special cases.
fn external_part(input: &mut TokenInput) -> ModalResult<ClassBodyItem> {
    if !matches!(peek_kind(input), Some(TK::External)) {
        return Err(ErrMode::Backtrack(ContextError::default()));
    }
    next_tok(input)?; // consume 'external'

    // 1. Optional language specification — a quoted string literal.
    let lang = opt(t_str_token).parse_next(input)?;

    // 2. Optional external function call:
    //      [ component_reference "=" ] IDENT "(" expression_list? ")"
    //
    // The `[component_reference "="]` prefix is rare (most externals omit it)
    // but legal — Modelica allows binding the C return value into a named
    // output component when the wrapping function's declared output is the
    // same component. We need a checkpoint-and-backtrack here because the
    // first identifier could be either the output component (followed by
    // `=`) or the function name (followed by `(`).
    let mut output_: Option<Absyn::ComponentRef> = None;
    let mut func_name: Option<ArcStr> = None;
    let mut args: Arc<List<Arc<Absyn::Exp>>> = nil();

    // The function-call body is only present when the next token is an
    // identifier; otherwise we are looking at `annotation` or `;`.
    if matches!(peek_kind(input), Some(TK::Ident(_))) {
        let checkpoint = input.checkpoint();
        // Try `component_reference "="` prefix first.
        let with_output = (|| -> ModalResult<(Absyn::ComponentRef, ArcStr)> {
            let cref = component_reference(input)?;
            t(TK::Equal).parse_next(input)?;
            let name = t_any_ident(input)?;
            Ok((cref, name))
        })();
        match with_output {
            Ok((cref, name)) => {
                output_ = Some(cref);
                func_name = Some(name);
            }
            Err(_) => {
                // No `=`; this identifier IS the function name.
                input.reset(&checkpoint);
                func_name = Some(t_any_ident(input)?);
            }
        }

        // Argument list. Required by the grammar once a function name is
        // present, but we accept the bare-identifier form gracefully — a few
        // MetaModelicaBuiltin entries declare e.g. `external "C" foo;`.
        if opt(t(TK::LParen)).parse_next(input)?.is_some() {
            let fa = function_arguments(input)?;
            t(TK::RParen).parse_next(input)?;
            // Only the positional-arg form is valid here — named arguments
            // and for-iterators are nonsense in an external binding. Drop
            // anything that isn't FUNCTIONARGS.args.
            if let Absyn::FunctionArgs::FUNCTIONARGS { args: a, .. } = fa {
                args = a;
            }
        }
    }

    // 3. Optional annotation, then mandatory `;`.
    let annotation_opt = opt(annotation).parse_next(input)?;
    t(TK::Semi).parse_next(input)?;

    Ok(ClassBodyItem::External {
        lang,
        funcName: func_name,
        output_,
        args,
        annotation_opt,
    })
}

// ---------------------------------------------------------------------------
// Equation / algorithm sections
// ---------------------------------------------------------------------------

/// Equation-section contents: equations interleaved with `annotation(…);`
/// items. The annotations are *class-level* annotations in the AST — the
/// ANTLR3 `equation_annotation_list` collects them into the class's `ann`
/// out-parameter — so they are returned separately for the caller to splice
/// in as [`ClassBodyItem::Annotation`] entries (which `split_annotations`
/// hoists like any other class annotation).
fn equation_section_items(input: &mut TokenInput) -> ModalResult<(Arc<List<EquationItem>>, Vec<Annotation>)> {
    let mut items: Arc<List<EquationItem>> = Arc::new(List::Nil);
    let mut anns: Vec<Annotation> = Vec::new();
    loop {
        let (next_l, next_c) = next_pos(input);
        for txt in take_comments_before(next_l, next_c) {
            items = cons(EquationItem::EQUATIONITEMCOMMENT { comment: txt }, items);
        }
        if input.is_empty() { break; }
        match peek_kind(input) {
            Some(TK::Public) | Some(TK::Protected) | Some(TK::Equation) | Some(TK::Algorithm)
            | Some(TK::External) | Some(TK::End) | Some(TK::Initial) => break,
            Some(TK::Annotation) => {
                let ann = annotation(input)?;
                cut_err(t(TK::Semi))
                    .context(StrContext::Label("';' after annotation in equation section"))
                    .parse_next(input)?;
                anns.push(ann);
                continue;
            }
            _ => {}
        }
        items = cons(equation_item(input)?, items);
        cut_err(t(TK::Semi)).context(StrContext::Label("';' after equation")).parse_next(input)?;
    }
    Ok((items.reverse(), anns))
}

/// Algorithm-section contents; see [`equation_section_items`] for the
/// interleaved-annotation handling (`algorithm_annotation_list` in ANTLR3).
fn algorithm_section_items(input: &mut TokenInput) -> ModalResult<(Arc<List<AlgorithmItem>>, Vec<Annotation>)> {
    let mut items: Arc<List<AlgorithmItem>> = Arc::new(List::Nil);
    let mut anns: Vec<Annotation> = Vec::new();
    loop {
        let (next_l, next_c) = next_pos(input);
        for txt in take_comments_before(next_l, next_c) {
            items = cons(AlgorithmItem::ALGORITHMITEMCOMMENT { comment: txt }, items);
        }
        if input.is_empty() { break; }
        match peek_kind(input) {
            Some(TK::Public) | Some(TK::Protected) | Some(TK::Equation) | Some(TK::Algorithm)
            | Some(TK::Initial) | Some(TK::End) | Some(TK::External) => break,
            Some(TK::Annotation) => {
                let ann = annotation(input)?;
                cut_err(t(TK::Semi))
                    .context(StrContext::Label("';' after annotation in algorithm section"))
                    .parse_next(input)?;
                anns.push(ann);
                continue;
            }
            _ => {}
        }
        items = cons(algorithm_item(input)?, items);
        cut_err(t(TK::Semi)).context(StrContext::Label("';' after statement")).parse_next(input)?;
    }
    Ok((items.reverse(), anns))
}

/// Equations stopping at Then / Else / Elseif / Elsewhen / End.
fn equation_list(input: &mut TokenInput) -> ModalResult<Arc<List<EquationItem>>> {
    let mut items: Arc<List<EquationItem>> = Arc::new(List::Nil);
    loop {
        // Flush lexer comments before the next token (or after the last
        // equation if we are about to break). They become EQUATIONITEMCOMMENT
        // entries interleaved with the parsed equations, preserving the
        // original source order.
        let (next_l, next_c) = next_pos(input);
        for txt in take_comments_before(next_l, next_c) {
            items = cons(EquationItem::EQUATIONITEMCOMMENT { comment: txt }, items);
        }
        if input.is_empty() { break; }
        match peek_kind(input) {
            Some(TK::Then) | Some(TK::Else) | Some(TK::Elseif)
            | Some(TK::Elsewhen) | Some(TK::End) | None => break,
            _ => {}
        }
        items = cons(equation_item(input)?, items);
        cut_err(t(TK::Semi)).context(StrContext::Label("';' after equation")).parse_next(input)?;
    }
    Ok(items.reverse())
}

fn equation_list_then(input: &mut TokenInput) -> ModalResult<Arc<List<Absyn::EquationItem>>> {
    equation_list(input)
}

fn equation_item(input: &mut TokenInput) -> ModalResult<EquationItem> {
    let start = *input;
    let eq = match peek_kind(input) {
        Some(TK::If)   => if_equation_e(input)?,
        Some(TK::For)  => for_equation_e(input)?,
        Some(TK::When) => when_equation_e(input)?,
        Some(TK::Failure)  => failure_equation(input)?,
        Some(TK::Connect)  => connect_equation(input)?,
        // Only `equality(`: a bare `equality` is an ordinary identifier.
        Some(TK::Equality) if matches!(input.get(1).map(|tok| &tok.kind), Some(TK::LParen)) =>
            equality_equation(input)?,
        _              => equality_or_noretcall_equation(input)?,
    };
    let comment = comment(input)?;
    Ok(EquationItem::EQUATIONITEM {
        equation_: Arc::new(eq),
        comment: comment.map(Arc::new),
        info: parser_info(&start, input),
    })
}

/// `equality_or_noretcall_equation` from `Modelica.g`, including its
/// `modelicaParserAssert` diagnostics: `:=` is rejected in equation
/// sections, and a standalone expression must be a function call.
fn equality_or_noretcall_equation(input: &mut TokenInput) -> ModalResult<Equation> {
    let start = *input;
    let lhs = simple_expression(input)?;
    if matches!(peek_kind(input), Some(TK::Equal) | Some(TK::Assign)) {
        let is_assign = matches!(input[0].kind, TK::Assign);
        let (ass_line, ass_col) = (input[0].line, input[0].col);
        next_tok(input)?;
        let rhs = cut_err(expression)
            .context(StrContext::Label("right-hand side of equation"))
            .parse_next(input)?;
        if is_assign {
            // Parsed like the C grammar (`(EQUALS | ass=ASSIGN) e2`), then
            // rejected with the `:=` token as the span.
            return Err(parser_assert_fail(
                "Equations can not contain assignments (':='), use equality ('=') instead",
                ass_line, ass_col, ass_line, ass_col + 1,
            ));
        }
        // PDEModelica `INDOMAIN component_reference2` suffix → `Absyn.EQ_PDE`
        // (the `indomain` keyword only exists in the PDEModelica grammar).
        if matches!(peek_kind(input), Some(TK::Indomain)) {
            next_tok(input)?;
            let domain = cut_err(component_reference2)
                .context(StrContext::Label("domain of indomain equation"))
                .parse_next(input)?;
            return Ok(Equation::EQ_PDE {
                leftSide: Arc::new(lhs),
                rightSide: Arc::new(rhs),
                domain: Arc::new(domain),
            });
        }
        Ok(Equation::EQ_EQUALS { leftSide: Arc::new(lhs), rightSide: Arc::new(rhs) })
    } else {
        match lhs {
            Absyn::Exp::CALL { function_, functionArgs, .. } =>
                Ok(Equation::EQ_NORETCALL { functionName: Arc::new((*function_).clone()), functionArgs }),
            _ => {
                // `modelicaParserAssert(isCall(e1), …)` — a hard error, like
                // the standalone-expression case in `assign_clause_a`.
                let (lt1_line, lt1_col) = match input.first() {
                    Some(t) => (t.line, t.col),
                    None => (start[0].line, start[0].col + 1),
                };
                Err(parser_assert_fail(
                    "A singleton expression in an equation section is required to be a function call",
                    start[0].line, start[0].col, lt1_line, lt1_col.saturating_sub(1),
                ))
            }
        }
    }
}

fn if_equation_e(input: &mut TokenInput) -> ModalResult<Equation> {
    next_tok(input)?; // If
    let cond = cut_err(expression).parse_next(input)?;
    match cut_err(next_tok)
        .context(StrContext::Label("'then' in if-equation"))
        .parse_next(input)?
    {
        TK::Then => {}
        _        => return Err(ErrMode::Cut(ContextError::default())),
    }
    let true_items = equation_list(input)?;
    let mut else_if_branches: Vec<(Arc<Absyn::Exp>, Arc<List<Arc<EquationItem>>>)> = Vec::new();
    loop {
        if !matches!(peek_kind(input), Some(TK::Elseif)) { break; }
        next_tok(input)?;
        let elif_cond = cut_err(expression).parse_next(input)?;
        match cut_err(next_tok).parse_next(input)? {
            TK::Then => {}
            _        => return Err(ErrMode::Cut(ContextError::default())),
        }
        else_if_branches.push((Arc::new(elif_cond), to_rc_list(equation_list(input)?)));
    }
    let mut has_else = false;
    let else_items = if matches!(peek_kind(input), Some(TK::Else)) {
        has_else = true;
        next_tok(input)?;
        equation_list(input)?
    } else { Arc::new(List::Nil) };
    let (end_line, end_col) = next_pos(input);
    match cut_err(next_tok)
        .context(StrContext::Label("'end' closing if-equation"))
        .parse_next(input)?
    {
        TK::End => {}
        _       => return Err(ErrMode::Cut(ContextError::default())),
    }
    // ANTLR lexes `end if` / `end <ident>` / `end for` / `end when` as
    // composite tokens and `conditional_equation_e` accepts all of them,
    // rejecting everything but END_IF with a dedicated diagnostic for the
    // classic nested-`else if` mistake.
    match peek_kind(input) {
        Some(TK::If) => { next_tok(input)?; }
        Some(TK::Ident(_)) | Some(TK::For) | Some(TK::When) => {
            next_tok(input)?;
            let (l2, c2) = match input.first() {
                Some(t) => (t.line, t.col),
                None => (end_line, end_col),
            };
            return Err(parser_assert_fail(
                if has_else {
                    "Expected 'end if'; did you use a nested 'else if' instead of 'elseif'?"
                } else {
                    "Expected 'end if'"
                },
                end_line, end_col, l2, c2,
            ));
        }
        _ => {
            return Err(ErrMode::Cut(ContextError::new().add_context(
                input, &input.checkpoint(),
                StrContext::Label("'if' after 'end' closing if-equation"),
            )));
        }
    }
    let mut elseif_list: Arc<List<(Arc<Absyn::Exp>, Arc<List<Arc<EquationItem>>>)>> = Arc::new(List::Nil);
    for branch in else_if_branches.into_iter().rev() { elseif_list = cons(branch, elseif_list); }
    Ok(Equation::EQ_IF {
        ifExp: Arc::new(cond),
        equationTrueItems: to_rc_list(true_items),
        elseIfBranches: elseif_list,
        equationElseItems: to_rc_list(else_items),
    })
}

fn for_equation_e(input: &mut TokenInput) -> ModalResult<Equation> {
    next_tok(input)?; // For
    let iterators = cut_err(for_indices).parse_next(input)?;
    match cut_err(next_tok)
        .context(StrContext::Label("'loop' in for-equation"))
        .parse_next(input)?
    {
        TK::Loop => {}
        _        => return Err(ErrMode::Cut(ContextError::default())),
    }
    let body = equation_list(input)?;
    match cut_err(next_tok)
        .context(StrContext::Label("'end' closing for-equation"))
        .parse_next(input)?
    {
        TK::End => {}
        _       => return Err(ErrMode::Cut(ContextError::default())),
    }
    next_tok(input)?; // "for"
    Ok(Equation::EQ_FOR { iterators, forEquations: to_rc_list(body) })
}

fn when_equation_e(input: &mut TokenInput) -> ModalResult<Equation> {
    next_tok(input)?; // When
    let when_cond = cut_err(expression).parse_next(input)?;
    match cut_err(next_tok)
        .context(StrContext::Label("'then' in when-equation"))
        .parse_next(input)?
    {
        TK::Then => {}
        _        => return Err(ErrMode::Cut(ContextError::default())),
    }
    let when_body = equation_list(input)?;
    let mut else_when: Vec<(Arc<Absyn::Exp>, Arc<List<Arc<EquationItem>>>)> = Vec::new();
    loop {
        if !matches!(peek_kind(input), Some(TK::Elsewhen)) { break; }
        next_tok(input)?;
        let ew_cond = cut_err(expression).parse_next(input)?;
        match cut_err(next_tok).parse_next(input)? {
            TK::Then => {}
            _        => return Err(ErrMode::Cut(ContextError::default())),
        }
        else_when.push((Arc::new(ew_cond), to_rc_list(equation_list(input)?)));
    }
    match cut_err(next_tok)
        .context(StrContext::Label("'end' closing when-equation"))
        .parse_next(input)?
    {
        TK::End => {}
        _       => return Err(ErrMode::Cut(ContextError::default())),
    }
    next_tok(input)?; // "when"
    let mut ew_list: Arc<List<(Arc<Absyn::Exp>, Arc<List<Arc<EquationItem>>>)>> = Arc::new(List::Nil);
    for branch in else_when.into_iter().rev() { ew_list = cons(branch, ew_list); }
    Ok(Equation::EQ_WHEN_E {
        whenExp: Arc::new(when_cond),
        whenEquations: to_rc_list(when_body),
        elseWhenEquations: ew_list,
    })
}

fn failure_equation(input: &mut TokenInput) -> ModalResult<Equation> {
    next_tok(input)?; // Failure
    t(TK::LParen).parse_next(input)?;
    let body = equation_item(input)?;
    t(TK::RParen).parse_next(input)?;
    Ok(Equation::EQ_FAILURE { equ: Arc::new(body) })
}

/// `equality(e1 = e2)` — MetaModelica's primitive equality equation
/// (`EQUALITY LPAR expression EQUALS expression RPAR` in the ANTLR grammar),
/// represented like there: a no-return call to `equality` with the two
/// operands as positional arguments.
fn equality_equation(input: &mut TokenInput) -> ModalResult<Equation> {
    next_tok(input)?; // Equality
    t(TK::LParen).parse_next(input)?;
    let lhs = cut_err(expression)
        .context(StrContext::Label("left operand of equality()"))
        .parse_next(input)?;
    cut_err(t(TK::Equal))
        .context(StrContext::Label("'=' in equality equation"))
        .parse_next(input)?;
    let rhs = cut_err(expression)
        .context(StrContext::Label("right operand of equality()"))
        .parse_next(input)?;
    cut_err(t(TK::RParen))
        .context(StrContext::Label("')' closing equality()"))
        .parse_next(input)?;
    Ok(Equation::EQ_NORETCALL {
        functionName: Arc::new(ComponentRef::CREF_IDENT { name: literal!("equality"), subscripts: nil() }),
        functionArgs: Arc::new(FunctionArgs::FUNCTIONARGS {
            args: cons(Arc::new(lhs), cons(Arc::new(rhs), nil())),
            argNames: nil(),
        }),
    })
}

/// `equality(e1 := e2)` — the algorithm-section form of [`equality_equation`]
/// (`EQUALITY LPAR expression ASSIGN expression RPAR`).
fn equality_algorithm(input: &mut TokenInput) -> ModalResult<Algorithm> {
    next_tok(input)?; // Equality
    t(TK::LParen).parse_next(input)?;
    let lhs = cut_err(expression)
        .context(StrContext::Label("left operand of equality()"))
        .parse_next(input)?;
    cut_err(t(TK::Assign))
        .context(StrContext::Label("':=' in equality statement"))
        .parse_next(input)?;
    let rhs = cut_err(expression)
        .context(StrContext::Label("right operand of equality()"))
        .parse_next(input)?;
    cut_err(t(TK::RParen))
        .context(StrContext::Label("')' closing equality()"))
        .parse_next(input)?;
    Ok(Algorithm::ALG_NORETCALL {
        functionCall: Arc::new(ComponentRef::CREF_IDENT { name: literal!("equality"), subscripts: nil() }),
        functionArgs: Arc::new(FunctionArgs::FUNCTIONARGS {
            args: cons(Arc::new(lhs), cons(Arc::new(rhs), nil())),
            argNames: nil(),
        }),
    })
}

fn connect_equation(input: &mut TokenInput) -> ModalResult<Equation> {
    next_tok(input)?; // Connect
    t(TK::LParen).parse_next(input)?;
    let connector1 = cut_err(component_reference)
        .context(StrContext::Label("first connector in connect equation"))
        .parse_next(input)?;
    t(TK::Comma).parse_next(input)?;
    let connector2 = cut_err(component_reference)
        .context(StrContext::Label("second connector in connect equation"))
        .parse_next(input)?;
    t(TK::RParen).parse_next(input)?;
    Ok(Equation::EQ_CONNECT { connector1: Arc::new(connector1), connector2: Arc::new(connector2) })
}

/// Algorithm statements stopping at Then / Else / Elseif / Elsewhen / End.
fn algorithm_list(input: &mut TokenInput) -> ModalResult<Arc<List<AlgorithmItem>>> {
    let mut items: Arc<List<AlgorithmItem>> = Arc::new(List::Nil);
    loop {
        // Mirror equation_list: drain lexer comments interleaved with
        // the algorithm statements so they round-trip through the AST.
        let (next_l, next_c) = next_pos(input);
        for txt in take_comments_before(next_l, next_c) {
            items = cons(AlgorithmItem::ALGORITHMITEMCOMMENT { comment: txt }, items);
        }
        if input.is_empty() { break; }
        match peek_kind(input) {
            Some(TK::Then) | Some(TK::Else) | Some(TK::Elseif)
            | Some(TK::Elsewhen) | Some(TK::End) | None => break,
            _ => {}
        }
        items = cons(algorithm_item(input)?, items);
        cut_err(t(TK::Semi)).context(StrContext::Label("';' after statement")).parse_next(input)?;
    }
    Ok(items.reverse())
}

fn algorithm_list_then(input: &mut TokenInput) -> ModalResult<Arc<List<Absyn::AlgorithmItem>>> {
    algorithm_list(input)
}

fn algorithm_item(input: &mut TokenInput) -> ModalResult<AlgorithmItem> {
    let start = *input;
    let alg = match peek_kind(input) {
        Some(TK::If)       => if_algorithm(input)?,
        Some(TK::For)      => for_algorithm(input)?,
        Some(TK::While)    => while_algorithm(input)?,
        Some(TK::When)     => when_algorithm(input)?,
        Some(TK::Try)      => try_algorithm(input)?,
        Some(TK::Failure)  => { failure_algorithm(input)? }
        Some(TK::Return)   => { next_tok(input)?; Algorithm::ALG_RETURN {} }
        Some(TK::Break)    => { next_tok(input)?; Algorithm::ALG_BREAK {} }
        Some(TK::Continue) => { next_tok(input)?; Algorithm::ALG_CONTINUE {} }
        // Only `equality(`: a bare `equality` is an ordinary identifier.
        Some(TK::Equality) if matches!(input.get(1).map(|tok| &tok.kind), Some(TK::LParen)) =>
            equality_algorithm(input)?,
        _                  => assign_clause_a(input)?,
    };
    let comment = comment(input)?;
    Ok(AlgorithmItem::ALGORITHMITEM {
        algorithm_: Arc::new(alg),
        comment: comment.map(Arc::new),
        info: parser_info(&start, input),
    })
}

/// `AbsynUtil.isDerCref`: a `der(cr)` call with a single positional cref
/// argument. Used for the non-standard `der(cr) := exp` statement form.
fn is_der_cref(exp: &Absyn::Exp) -> bool {
    if let Absyn::Exp::CALL { function_, functionArgs, .. } = exp
        && let Absyn::ComponentRef::CREF_IDENT { name, subscripts } = &**function_
        && name.as_str() == "der" && subscripts.is_empty()
        && let Absyn::FunctionArgs::FUNCTIONARGS { args, argNames } = &**functionArgs
        && argNames.is_empty()
        && let List::Cons { head, tail } = &**args
        && tail.is_empty()
    {
        return matches!(&**head, Absyn::Exp::CREF { .. });
    }
    false
}

/// `assign_clause_a` from `Modelica.g`, including its `modelicaParserAssert`
/// diagnostics: `=` is rejected in algorithm sections, and outside
/// MetaModelica the statement must be `cref := exp`,
/// `(out, …) := call(…)`, a `der(cr) := exp` compatibility form (which only
/// gets a warning), or a standalone function call.
fn assign_clause_a(input: &mut TokenInput) -> ModalResult<Algorithm> {
    let start = *input;
    let lhs = simple_expression(input)?;
    if matches!(peek_kind(input), Some(TK::Assign) | Some(TK::Equal)) {
        let is_equals = matches!(input[0].kind, TK::Equal);
        let (eq_line, eq_col) = (input[0].line, input[0].col);
        next_tok(input)?;
        let value = cut_err(expression)
            .context(StrContext::Label("right-hand side of assignment"))
            .parse_next(input)?;
        if is_equals {
            // The grammar parses the RHS before rejecting the statement, so
            // the recorded span is just the `=` token itself.
            return Err(parser_assert_fail(
                "Algorithms can not contain equations ('='), use assignments (':=') instead",
                eq_line, eq_col, eq_line, eq_col + 1,
            ));
        }
        if !metamodelica_enabled() {
            // MetaModelica allows pattern matching on arbitrary expressions
            // in algorithm sections; plain Modelica restricts the LHS form.
            // Like the C parser, the RHS call check looks at the raw node —
            // a comment-wrapped call does not count.
            let looks_like_cref = matches!(lhs, Absyn::Exp::CREF { .. });
            let looks_like_call = matches!(lhs, Absyn::Exp::TUPLE { .. })
                && matches!(value, Absyn::Exp::CALL { .. });
            let looks_like_der_cr = !looks_like_cref && !looks_like_call && is_der_cref(&lhs);
            // LT(1) position; ANTLR uses charPosition (0-based) for the
            // assert's end column but charPosition+1 for the warning's.
            let (lt1_line, lt1_col) = match input.first() {
                Some(t) => (t.line, t.col),
                None => (start[0].line, start[0].col + 1),
            };
            if !(looks_like_cref || looks_like_call || looks_like_der_cr) {
                return Err(parser_assert_fail(
                    "Modelica assignment statements are either on the form 'component_reference := expression' or '( output_expression_list ) := function_call'",
                    start[0].line, start[0].col, lt1_line, lt1_col.saturating_sub(1),
                ));
            }
            if looks_like_der_cr {
                add_syntax_message(
                    SyntaxSeverity::Warning,
                    "der(cr) := exp is not legal Modelica code. OpenModelica accepts it for interoperability with non-standards-compliant Modelica tools. There is no way to suppress this warning.".to_owned(),
                    start[0].line, start[0].col, lt1_line, lt1_col,
                );
            }
        }
        Ok(Algorithm::ALG_ASSIGN { assignComponent: Arc::new(lhs), value: Arc::new(value) })
    } else {
        match lhs {
            Absyn::Exp::CALL { function_, functionArgs, .. } =>
                Ok(Algorithm::ALG_NORETCALL { functionCall: Arc::new((*function_).clone()), functionArgs }),
            _ => {
                // `modelicaParserAssert(isCall(e1), …)`: a standalone
                // non-call expression is a hard syntax error, not a
                // backtrack — every caller has already committed to a
                // statement here (bare expressions in .mos scripts are
                // consumed by `top_algorithm`'s expression predicate).
                let (lt1_line, lt1_col) = match input.first() {
                    Some(t) => (t.line, t.col),
                    None => (start[0].line, start[0].col + 1),
                };
                Err(parser_assert_fail(
                    "Only function call expressions may stand alone in an algorithm section",
                    start[0].line, start[0].col, lt1_line, lt1_col.saturating_sub(1),
                ))
            }
        }
    }
}

/// `top_assign_clause_a` (Modelica.g): the interactive (.mos) assignment
/// statement. Unlike [`assign_clause_a`] it only accepts `:=` and performs
/// none of the algorithm-section shape checks.
fn top_assign_clause_a(input: &mut TokenInput) -> ModalResult<Algorithm> {
    let lhs = simple_expression(input)?;
    t(TK::Assign).parse_next(input)?;
    let value = cut_err(expression)
        .context(StrContext::Label("right-hand side of assignment"))
        .parse_next(input)?;
    Ok(Algorithm::ALG_ASSIGN { assignComponent: Arc::new(lhs), value: Arc::new(value) })
}

fn if_algorithm(input: &mut TokenInput) -> ModalResult<Algorithm> {
    next_tok(input)?; // If
    let cond = cut_err(expression).parse_next(input)?;
    match cut_err(next_tok).context(StrContext::Label("'then' in if-algorithm")).parse_next(input)? {
        TK::Then => {}
        _        => return Err(ErrMode::Cut(ContextError::default())),
    }
    let true_items = algorithm_list(input)?;
    let mut else_if_branches: Vec<(Arc<Absyn::Exp>, Arc<List<Arc<AlgorithmItem>>>)> = Vec::new();
    loop {
        if !matches!(peek_kind(input), Some(TK::Elseif)) { break; }
        next_tok(input)?;
        let elif_cond = cut_err(expression).parse_next(input)?;
        match cut_err(next_tok).parse_next(input)? {
            TK::Then => {}
            _        => return Err(ErrMode::Cut(ContextError::default())),
        }
        else_if_branches.push((Arc::new(elif_cond), to_rc_list(algorithm_list(input)?)));
    }
    let mut has_else = false;
    let else_items = if matches!(peek_kind(input), Some(TK::Else)) {
        has_else = true;
        next_tok(input)?; algorithm_list(input)?
    } else { Arc::new(List::Nil) };
    let (end_line, end_col) = next_pos(input);
    match cut_err(next_tok).context(StrContext::Label("'end' closing if-algorithm")).parse_next(input)? {
        TK::End => {}
        _       => return Err(ErrMode::Cut(ContextError::default())),
    }
    // See if_equation_e: only `end if` closes the statement; an `end`
    // followed by an identifier/for/when/while is the nested-`else if`
    // mistake (conditional_equation_a in Modelica.g).
    match peek_kind(input) {
        Some(TK::If) => { next_tok(input)?; }
        Some(TK::Ident(_)) | Some(TK::For) | Some(TK::When) | Some(TK::While) => {
            next_tok(input)?;
            let (l2, c2) = match input.first() {
                Some(t) => (t.line, t.col),
                None => (end_line, end_col),
            };
            return Err(parser_assert_fail(
                if has_else {
                    "Expected 'end if'; did you use a nested 'else if' instead of 'elseif'?"
                } else {
                    "Expected 'end if'"
                },
                end_line, end_col, l2, c2,
            ));
        }
        _ => {
            return Err(ErrMode::Cut(ContextError::new().add_context(
                input, &input.checkpoint(),
                StrContext::Label("'if' after 'end' closing if-statement"),
            )));
        }
    }
    let mut elseif_list: Arc<List<(Arc<Absyn::Exp>, Arc<List<Arc<AlgorithmItem>>>)>> = Arc::new(List::Nil);
    for branch in else_if_branches.into_iter().rev() { elseif_list = cons(branch, elseif_list); }
    Ok(Algorithm::ALG_IF {
        ifExp: Arc::new(cond), trueBranch: to_rc_list(true_items),
        elseIfAlgorithmBranch: elseif_list, elseBranch: to_rc_list(else_items),
    })
}

fn for_algorithm(input: &mut TokenInput) -> ModalResult<Algorithm> {
    next_tok(input)?; // For
    let iterators = cut_err(for_indices).parse_next(input)?;
    match cut_err(next_tok).context(StrContext::Label("'loop' in for-algorithm")).parse_next(input)? {
        TK::Loop => {}
        _        => return Err(ErrMode::Cut(ContextError::default())),
    }
    let body = algorithm_list(input)?;
    match cut_err(next_tok).context(StrContext::Label("'end' closing for-algorithm")).parse_next(input)? {
        TK::End => {}
        _       => return Err(ErrMode::Cut(ContextError::default())),
    }
    next_tok(input)?; // "for"
    Ok(Algorithm::ALG_FOR { iterators, forBody: to_rc_list(body) })
}

fn while_algorithm(input: &mut TokenInput) -> ModalResult<Algorithm> {
    next_tok(input)?; // While
    let cond = cut_err(expression).parse_next(input)?;
    match cut_err(next_tok).context(StrContext::Label("'loop' in while-algorithm")).parse_next(input)? {
        TK::Loop => {}
        _        => return Err(ErrMode::Cut(ContextError::default())),
    }
    let body = algorithm_list(input)?;
    match cut_err(next_tok).context(StrContext::Label("'end' closing while-algorithm")).parse_next(input)? {
        TK::End => {}
        _       => return Err(ErrMode::Cut(ContextError::default())),
    }
    next_tok(input)?; // "while"
    Ok(Algorithm::ALG_WHILE { boolExpr: Arc::new(cond), whileBody: to_rc_list(body) })
}

fn when_algorithm(input: &mut TokenInput) -> ModalResult<Algorithm> {
    next_tok(input)?; // When
    let when_cond = cut_err(expression).parse_next(input)?;
    match cut_err(next_tok).context(StrContext::Label("'then' in when-algorithm")).parse_next(input)? {
        TK::Then => {}
        _        => return Err(ErrMode::Cut(ContextError::default())),
    }
    let when_body = algorithm_list(input)?;
    let mut else_when: Vec<(Arc<Absyn::Exp>, Arc<List<Arc<AlgorithmItem>>>)> = Vec::new();
    loop {
        if !matches!(peek_kind(input), Some(TK::Elsewhen)) { break; }
        next_tok(input)?;
        let ew_cond = cut_err(expression).parse_next(input)?;
        match cut_err(next_tok).parse_next(input)? {
            TK::Then => {}
            _        => return Err(ErrMode::Cut(ContextError::default())),
        }
        else_when.push((Arc::new(ew_cond), to_rc_list(algorithm_list(input)?)));
    }
    match cut_err(next_tok).context(StrContext::Label("'end' closing when-algorithm")).parse_next(input)? {
        TK::End => {}
        _       => return Err(ErrMode::Cut(ContextError::default())),
    }
    next_tok(input)?; // "when"
    let mut ew_list: Arc<List<(Arc<Absyn::Exp>, Arc<List<Arc<AlgorithmItem>>>)>> = Arc::new(List::Nil);
    for branch in else_when.into_iter().rev() { ew_list = cons(branch, ew_list); }
    Ok(Algorithm::ALG_WHEN_A {
        boolExpr: Arc::new(when_cond), whenBody: to_rc_list(when_body), elseWhenAlgorithmBranch: ew_list,
    })
}

fn try_algorithm(input: &mut TokenInput) -> ModalResult<Algorithm> {
    next_tok(input)?; // Try
    let body = algorithm_list(input)?;
    match cut_err(next_tok).context(StrContext::Label("'else' in try-algorithm")).parse_next(input)? {
        TK::Else => {}
        _        => return Err(ErrMode::Cut(ContextError::default())),
    }
    let else_body = algorithm_list(input)?;
    match cut_err(next_tok).context(StrContext::Label("'end' closing try-algorithm")).parse_next(input)? {
        TK::End => {}
        _       => return Err(ErrMode::Cut(ContextError::default())),
    }
    next_tok(input)?; // "try"
    Ok(Algorithm::ALG_TRY { body: to_rc_list(body), elseBody: to_rc_list(else_body) })
}

fn failure_algorithm(input: &mut TokenInput) -> ModalResult<Algorithm> {
    next_tok(input)?; // Failure
    t(TK::LParen).parse_next(input)?;
    let equ = List::new(algorithm_item.parse_next(input)?);
    t(TK::RParen).parse_next(input)?;
    Ok(Algorithm::ALG_FAILURE{equ: to_rc_list(equ)})
}

// ---------------------------------------------------------------------------
// Interactive (.mos) statements
// ---------------------------------------------------------------------------

/// `interactive_stmt` (Modelica.g):
/// `BOM? interactive_stmt_list (SEMICOLON)? EOF` where `interactive_stmt_list`
/// is `top_algorithm (SEMICOLON top_algorithm)*`.  The trailing-semicolon flag
/// is recorded in `Statements.semicolon` (a statement ending in `;` does not
/// print its result in the interactive environment).
fn interactive_stmt(input: &mut TokenInput) -> ModalResult<crate::GlobalScript::Statements> {
    if matches!(peek_kind(input), Some(TK::BOM)) { next_tok(input)?; }
    let mut stmts: Arc<List<crate::GlobalScript::Statement>> = Arc::new(List::Nil);
    let mut semicolon = false;
    // The ANTLR rule requires at least one statement; we are slightly more
    // lenient and accept an empty token stream (e.g. a script containing
    // only comments) as an empty statement list.
    if !input.is_empty() {
        stmts = cons(top_algorithm(input)?, stmts);
        while opt(t(TK::Semi)).parse_next(input)?.is_some() {
            if input.is_empty() {
                // The optional final semicolon before EOF.
                semicolon = true;
                break;
            }
            // After a non-final ';' another statement is the only valid
            // continuation, so commit to it for a precise error position.
            stmts = cons(
                cut_err(top_algorithm)
                    .context(StrContext::Label("interactive statement"))
                    .parse_next(input)?,
                stmts,
            );
        }
    }
    Ok(crate::GlobalScript::Statements { interactiveStmtLst: stmts.reverse(), semicolon })
}

/// `top_algorithm` (Modelica.g): one interactive statement.
///
/// Mirrors the ANTLR syntactic predicate
/// `(expression (SEMICOLON|EOF)) => expression`: a bare expression is only
/// accepted when followed by `;` or end-of-input, and yields `IEXP`.
/// Otherwise one of the statement forms (assignment, if, for, while, try)
/// is parsed and yields `IALG`.  An assignment like `a := f()` fails the
/// expression predicate (the next token is `:=`) and lands in
/// [`assign_clause_a`].
fn top_algorithm(input: &mut TokenInput) -> ModalResult<crate::GlobalScript::Statement> {
    let start = *input;
    let cursor = save_comment_cursor();
    match expression(input) {
        Ok(e) if input.is_empty() || matches!(peek_kind(input), Some(TK::Semi)) => {
            return Ok(crate::GlobalScript::Statement::IEXP {
                exp: Arc::new(e),
                info: parser_info(&start, input),
            });
        }
        _ => {
            // Predicate failed (either the expression did not parse, or it
            // is not followed by ';'/EOF).  Rewind the token cursor and the
            // comment stream and try the statement alternatives, exactly
            // like ANTLR's backtracking over the predicate.
            *input = start;
            restore_comment_cursor(cursor);
        }
    }

    let alg = match peek_kind(input) {
        Some(TK::If)    => if_algorithm(input)?,    // conditional_equation_a
        Some(TK::For)   => for_algorithm(input)?,   // for_clause_a
        Some(TK::While) => while_algorithm(input)?, // while_clause
        Some(TK::Try)   => try_algorithm(input)?,   // try_clause
        // NOTE: `parfor_clause_a` (ParModelica) is not implemented — the
        // algorithm-section parser does not support parfor loops either.
        _               => top_assign_clause_a(input)?,
    };
    let cmt = comment(input)?;
    Ok(crate::GlobalScript::Statement::IALG {
        algItem: Arc::new(AlgorithmItem::ALGORITHMITEM {
            algorithm_: Arc::new(alg),
            comment: cmt.map(Arc::new),
            info: parser_info(&start, input),
        }),
    })
}

/// `element_modification_or_replaceable` (Modelica.g):
/// `EACH? FINAL? (element_modification | element_replaceable)`.
/// Entry point used by `ParserExt.stringMod`.
fn element_modification_or_replaceable(input: &mut TokenInput) -> ModalResult<ElementArg> {
    let each_  = opt(t(TK::Each)).parse_next(input)?.is_some();
    let final_ = opt(t(TK::Final)).parse_next(input)?.is_some();
    let mut res = alt((element_replaceable, element_modification)).parse_next(input)?;
    // The ANTLR rule threads each/final into the sub-rules as parameters;
    // here the sub-parsers build the node with default prefixes and we patch
    // the prefix fields afterwards.
    match &mut res {
        ElementArg::MODIFICATION { eachPrefix, finalPrefix, .. }
        | ElementArg::REDECLARATION { eachPrefix, finalPrefix, .. } => {
            *eachPrefix  = if each_ { Each::EACH {} } else { Each::NON_EACH {} };
            *finalPrefix = final_;
        }
        // element_modification/element_replaceable only build the two
        // variants above; the comment/inheritance-break variants come from
        // other producers.
        ElementArg::ELEMENTARGCOMMENT { .. } | ElementArg::INHERITANCEBREAK { .. } => {
            unreachable!("element_modification/element_replaceable produced an unexpected ElementArg variant")
        }
    }
    Ok(res)
}

// ---------------------------------------------------------------------------
// Match expression helpers
// ---------------------------------------------------------------------------

fn match_case_body(input: &mut TokenInput) -> ModalResult<Absyn::ClassPart> {
    match peek_kind(input) {
        /*
        Some(TK::Equation) => {
            return Err(ErrMode::Cut(ContextError::new().add_context(
                input,
                &input.checkpoint(),
                StrContext::Label("equation in match is no longer supported - use algorithm instead"),
            )));
        },
        */
        Some(TK::Equation) => {
            next_tok(input)?;
            let contents = cut_err(equation_list_then)
                .context(StrContext::Label("equation list in match case"))
                .parse_next(input)?;
            Ok(Absyn::ClassPart::EQUATIONS { contents: to_rc_list(contents) })
        },
        Some(TK::Algorithm) => {
            next_tok(input)?;
            let contents = cut_err(algorithm_list_then)
                .context(StrContext::Label("algorithm list in match case"))
                .parse_next(input)?;
            Ok(Absyn::ClassPart::ALGORITHMS { contents: to_rc_list(contents) })
        }
        _ => Ok(Absyn::ClassPart::ALGORITHMS { contents: Arc::new(List::Nil) }),
    }
}

fn local_clause(input: &mut TokenInput) -> ModalResult<Arc<List<Arc<Absyn::ElementItem>>>> {
    if !matches!(peek_kind(input), Some(TK::Local)) { return Ok(Arc::new(List::Nil)); }
    next_tok(input)?; // Local
    let items = element_list(input)?;
    let mut result: Arc<List<Arc<Absyn::ElementItem>>> = Arc::new(List::Nil);
    for item in &*items {
        let ei = match item {
            ClassBodyItem::Element(elem)   => Absyn::ElementItem::ELEMENTITEM { element: Arc::new(elem.clone()) },
            ClassBodyItem::Annotation(ann) => Absyn::ElementItem::LEXER_COMMENT { comment: arcstr::format!("{ann:?}") },
            _ => continue,
        };
        result = cons(Arc::new(ei), result);
    }
    Ok(result.reverse())
}

fn match_onecase(input: &mut TokenInput) -> ModalResult<Absyn::Case> {
    let case_start = *input;
    match next_tok(input)? {
        TK::Case => {}
        _        => return Err(ErrMode::Backtrack(ContextError::default())),
    }
    let start_pattern = *input;
    let pattern = pattern_expression(input)?;
    // `pattern` (Modelica.g) computes its info right after the expression,
    // so the end is the start of whatever follows (guard/`then`/...).
    let patternInfo = parser_info(&start_pattern, input);
    let patternGuard = if opt(alt((t(TK::If),t(TK::Guard)))).parse_next(input)?.is_some() {
        Some(Arc::new(expression(input)?))
    } else {
        None
    };
    let comment    = None; // string_comment(input)?;
    let localDecls = local_clause(input)?;
    let classPart  = match_case_body(input)?;
    // `onecase` consumes the trailing `;` before its action runs, so both
    // the case info (`PARSER_INFO($start)`) and the result info
    // (`PARSER_INFO($th)`, anchored at the `then` keyword) end at the
    // token *after* the semicolon.
    let then_start = *input;
    t(TK::Then).parse_next(input)?;
    let result = expression(input)?;
    t(TK::Semi).parse_next(input)?;
    Ok(Absyn::Case::CASE {
        pattern: Arc::new(pattern), patternGuard, patternInfo,
        localDecls, classPart: Arc::new(classPart), result: Arc::new(result),
        resultInfo: parser_info(&then_start, input),
        comment, info: parser_info(&case_start, input),
    })
}

fn match_cases(input: &mut TokenInput) -> ModalResult<Arc<List<Absyn::Case>>> {
    let mut cases: Arc<List<Absyn::Case>> = Arc::new(List::Nil);
    loop {
        match peek_kind(input) {
            Some(TK::Case) => { cases = cons(match_onecase(input)?, cases); }
            Some(TK::Else) => {
                let else_start = *input;
                cut_err(t(TK::Else)).context(StrContext::Label("else")).parse_next(input)?;
                let comment    = None; // string_comment(input)?;
                let localDecls = local_clause(input)?;
                // `cases2` (Modelica.g) anchors the result info at the
                // `then` keyword when one is present and at the `else`
                // otherwise (`if ($th) $el = $th;`), and both infos end
                // after the trailing `;` is consumed.
                let mut result_start = else_start;
                let classPart  = match peek_kind(input) {
                    Some(TK::Equation) | Some(TK::Algorithm) => {
                        let cp = match_case_body(input)?;
                        result_start = *input;
                        t(TK::Then).parse_next(input)?;
                        cp
                    },
                    _ => {
                        if matches!(peek_kind(input), Some(TK::Then)) {
                            result_start = *input;
                        }
                        opt(t(TK::Then)).parse_next(input)?;
                        Absyn::ClassPart::ALGORITHMS { contents: Arc::new(List::Nil) }
                    },
                };
                let result = expression(input)?;
                opt(t(TK::Semi)).parse_next(input)?;
                cases = cons(Absyn::Case::ELSE {
                    localDecls, classPart: Arc::new(classPart), result: Arc::new(result),
                    resultInfo: parser_info(&result_start, input), comment, info: parser_info(&else_start, input),
                }, cases);
                break;
            }
            _ => break,
        }
    }
    Ok(cases.reverse())
}

fn match_expression(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    let matchTy = match next_tok(input)? {
        TK::Match         => Absyn::MatchType::MATCH {},
        TK::Matchcontinue => Absyn::MatchType::MATCHCONTINUE {},
        _                 => return Err(ErrMode::Backtrack(ContextError::default())),
    };
    let inputExp   = expression(input)?;
    let comment    = None; // string_comment(input)?;
    let localDecls = local_clause(input)?;
    let cases      = cut_err(match_cases).
        context(StrContext::Label(match matchTy {MatchType::MATCH => "match", MatchType::MATCHCONTINUE => "matchcontinue" })).parse_next(input)?;
    match next_tok(input)? {
        TK::End => {}
        _       => return Err(ErrMode::Backtrack(ContextError::default())),
    }
    match next_tok(input)? {
        TK::Match | TK::Matchcontinue => {}
        _                              => return Err(ErrMode::Backtrack(ContextError::default())),
    }
    Ok(Absyn::Exp::MATCHEXP { matchTy, inputExp: Arc::new(inputExp), localDecls, cases: to_rc_list(cases), comment })
}

// ---------------------------------------------------------------------------
// Name / path / component reference parsers
// ---------------------------------------------------------------------------

fn name_path(input: &mut TokenInput) -> ModalResult<Path> {
    let fq  = opt(t(TK::Dot)).parse_next(input)?.is_some();
    let res = name_path2(input)?;
    if fq { Ok(Path::FULLYQUALIFIED { path: Arc::new(res) }) } else { Ok(res) }
}

fn name_path2(input: &mut TokenInput) -> ModalResult<Path> {
    // `name_path2` (Modelica.g) is `IDENT|CODE`, not the looser `identifier`
    // rule: keyword-names like `der`/`initial` are not valid path components.
    let mut parts = Vec::new();
    let mut last_id = t_path_ident(input)?;
    loop {
        // Only treat Dot as separator if the next token after it is an Ident.
        if input.len() >= 2
            && input[0].kind == TK::Dot
            && matches!(&input[1].kind, TK::Ident(_) | TK::Code)
        {
            *input = &input[1..]; // consume Dot
            parts.push(last_id);
            last_id = t_path_ident(input)?;
        } else {
            break;
        }
    }
    let mut res = Path::IDENT { name: last_id };
    for id in parts.iter().rev() {
        res = Path::QUALIFIED { name: id.clone(), path: Arc::new(res) };
    }
    Ok(res)
}

fn component_reference(input: &mut TokenInput) -> ModalResult<Absyn::ComponentRef> {
    let fq = opt(t(TK::Dot)).parse_next(input)?.is_some();
    let cr = component_reference2(input)?;
    if fq { Ok(Absyn::ComponentRef::CREF_FULLYQUALIFIED { componentRef: Arc::new(cr) }) }
    else  { Ok(cr) }
}

fn component_reference2(input: &mut TokenInput) -> ModalResult<Absyn::ComponentRef> {
    // Modelica.g admits `operator` as a component name here
    // (`id=IDENT | id=OPERATOR`) — record fields like `DAE.BINARY.operator`.
    let name = if matches!(peek_kind(input), Some(TK::Operator)) {
        next_tok(input)?;
        literal!("operator")
    } else {
        t_ident(input)?
    };
    let raw_subs = opt(array_subscripts).parse_next(input)?.unwrap_or_else(|| Arc::new(List::Nil));
    let mut subscripts: Arc<List<Arc<Absyn::Subscript>>> = Arc::new(List::Nil);
    for s in &*raw_subs.reverse() { subscripts = cons(s.clone(), subscripts); }
    if input.len() >= 2
        && input[0].kind == TK::Dot
        && matches!(&input[1].kind, TK::Ident(_) | TK::Operator)
    {
        *input = &input[1..]; // consume Dot
        let rest = component_reference2(input)?;
        Ok(Absyn::ComponentRef::CREF_QUAL { name, subscripts, componentRef: Arc::new(rest) })
    } else {
        Ok(Absyn::ComponentRef::CREF_IDENT { name, subscripts })
    }
}

// ---------------------------------------------------------------------------
// Expression parsers
// ---------------------------------------------------------------------------

/// Inner expression parser without comment splicing. Kept private so external
/// callers can't bypass the EXPRESSIONCOMMENT wrapper.
fn expression_inner(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    // Consume the `allowPartEvalFunc` flag: an explicit value governs only
    // this expression; nested expressions (parsed below) see the default,
    // which is `metamodelica_enabled()` like `expression[metamodelica_enabled()]`
    // at almost every call site in Modelica.g.
    let allow_part_eval = ALLOW_PART_EVAL_FUNC
        .with(|f| f.replace(None))
        .unwrap_or_else(metamodelica_enabled);
    match peek_kind(input) {
        Some(TK::If)                             => return if_expression(input),
        Some(TK::Match) | Some(TK::Matchcontinue) => return match_expression(input),
        Some(TK::Function)                       => {
            let start = *input;
            let e = part_eval_function_expression(input)?;
            if !allow_part_eval {
                let (l2, c2) = next_pos(input);
                add_syntax_message(
                    SyntaxSeverity::Error,
                    "Function partial application expressions are only allowed as inputs to functions.".to_owned(),
                    start[0].line, start[0].col, l2, c2,
                );
                return Err(ErrMode::Cut(ContextError::new()));
            }
            return Ok(e);
        }
        Some(TK::Code) | Some(TK::CodeName) | Some(TK::CodeExp) | Some(TK::CodeVar) | Some(TK::CodeAnnotation) => return code_expression(input),
        _ => {}
    }
    simple_expression(input)
}

/// Parse an expression, splicing any preceding/trailing lexer comments into
/// an `EXPRESSIONCOMMENT` wrapper that matches the ANTLR3 grammar's
/// non-bootstrap behaviour at `grammars/Modelica.g:1554-1599`.
///
/// Backtracking safety: `expression` is called speculatively in many places
/// (`opt(expression)`, `alt((..., expression))`, etc.). The comment cursor
/// is therefore snapshotted on entry and restored if the inner parse fails,
/// so a backtracked attempt leaves the parallel comment stream as if we had
/// never run.
fn expression(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    let cursor_save = save_comment_cursor();
    let input_save  = *input;

    // Comments immediately before the next token (the expression's first
    // token) become `commentsBefore`. We must drain — not peek — because the
    // global comment cursor has to advance past them so they are not
    // re-claimed at a later checkpoint, mirroring the ANTLR `expression` rule
    // advancing `omc_first_comment` in its `@init`/trailing actions.
    let (line, col) = next_pos(input);
    let before = take_comments_before(line, col);

    match expression_inner(input) {
        Ok(exp) => {
            // Comments between the expression's last token and whatever
            // follows are `commentsAfter`. We only treat comments adjacent
            // to the expression as "after"; anything past the next non-
            // comment token belongs to a later checkpoint.
            let (line, col) = next_pos(input);
            let after = take_comments_before(line, col);

            // Wrap in `Absyn.EXPRESSIONCOMMENT` only for stored definitions
            // (`loadFile`/`loadString`, where `list`/save round-trips must
            // preserve source comments). Interactive `.mos` statements drop the
            // drained comments: the reference omc echoes `getVersion()`, not
            // `// comment getVersion()`, under `-d=showStatement`. The ANTLR3
            // grammar achieves this via `omc_first_comment` already pointing
            // past the leading comment when an interactive statement's
            // expression runs; we model it directly with the interactive flag.
            if is_interactive_parse() || (before.is_empty() && after.is_empty()) {
                Ok(exp)
            } else {
                let mut b: Arc<List<ArcStr>> = Arc::new(List::Nil);
                for t in before.into_iter().rev() { b = cons(t, b); }
                let mut a: Arc<List<ArcStr>> = Arc::new(List::Nil);
                for t in after.into_iter().rev() { a = cons(t, a); }
                Ok(Absyn::Exp::EXPRESSIONCOMMENT {
                    commentsBefore: b,
                    exp: Arc::new(exp),
                    commentsAfter: a,
                })
            }
        }
        Err(e) => {
            // Restore both streams so a higher-level `alt` / `opt` retry sees
            // exactly the same state we started with.
            *input = input_save;
            restore_comment_cursor(cursor_save);
            Err(e)
        }
    }
}

fn if_expression(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    match next_tok(input)? { TK::If => {} _ => return Err(ErrMode::Backtrack(ContextError::default())) }
    let cond    = expression(input)?;
    match next_tok(input)? { TK::Then => {} _ => return Err(ErrMode::Backtrack(ContextError::default())) }
    let true_br = expression(input)?;
    let mut elseif: Arc<List<(Arc<Absyn::Exp>, Arc<Absyn::Exp>)>> = nil();
    loop {
        if !matches!(peek_kind(input), Some(TK::Elseif)) { break; }
        next_tok(input)?;
        let ec = expression(input)?;
        match next_tok(input)? { TK::Then => {} _ => return Err(ErrMode::Backtrack(ContextError::default())) }
        let et = expression(input)?;
        elseif = cons((Arc::new(ec), Arc::new(et)), elseif);
    }
    match next_tok(input)? { TK::Else => {} _ => return Err(ErrMode::Backtrack(ContextError::default())) }
    let false_br = expression(input)?;
    Ok(Absyn::Exp::IFEXP {
        ifExp: Arc::new(cond), trueBranch: Arc::new(true_br), elseBranch: Arc::new(false_br),
        elseIfBranch: elseif.reverse(),
    })
}

/// code_expression — $Code / $TypeName / $Expression / $Var / $annotation
///
/// ANTLR3 rule (simplified):
///   CODE LPAR ( initial? ( EQUATION eq | CONSTRAINT constr | ALGORITHM alg )
///             | m=modification
///             | (LPAR expr RPAR) => expr          /* Code((expr)) */
///             | (expr RPAR) => expr               /* Code(expr)   */
///             | el=element (SEMICOLON)? ) RPAR
///   | CODE_NAME LPAR name_path RPAR
///   | CODE_ANNOTATION class_modification
///   | CODE_EXP  LPAR expression RPAR
///   | CODE_VAR  LPAR component_reference RPAR
fn code_expression(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    match next_tok(input)? {
        TK::CodeName => {
            t(TK::LParen).parse_next(input)?;
            let path = name_path(input)?;
            t(TK::RParen).parse_next(input)?;
            return Ok(Exp::CODE { code: Arc::new(CodeNode::C_TYPENAME { path: Arc::new(path) }) });
        },
        TK::CodeExp => {
            t(TK::LParen).parse_next(input)?;
            let exp = expression(input)?;
            t(TK::RParen).parse_next(input)?;
            return Ok(Exp::CODE { code: Arc::new(CodeNode::C_EXPRESSION { exp: Arc::new(exp) }) });
        },
        TK::CodeVar => {
            t(TK::LParen).parse_next(input)?;
            let componentRef = component_reference(input)?;
            t(TK::RParen).parse_next(input)?;
            return Ok(Exp::CODE { code: Arc::new(CodeNode::C_VARIABLENAME { componentRef: Arc::new(componentRef) }) });
        },
        TK::CodeAnnotation => {
            let elementArgLst = class_modification(input)?;
            return Ok(Exp::CODE { code: Arc::new(CodeNode::C_MODIFICATION { modification: Arc::new(Modification { elementArgLst, eqMod: Arc::new(EqMod::NOMOD) }) }) });
        },
        TK::Code => {
                t(TK::LParen)
                    .context(StrContext::Label("'(' after $Code"))
                    .parse_next(input)?;

                // Optional 'initial' keyword before equation/constraint/algorithm sections
                let initial = matches!(opt(t(TK::Initial)).parse_next(input)?, Some(TK::Initial));

                // Try EQUATION code_equation_clause
                if matches!(peek_kind(input), Some(TK::Equation)) {
                    next_tok(input)?;
                    let eq = cut_err(code_equation_clause)
                        .context(StrContext::Label("equation clause in $Code"))
                        .parse_next(input)?;
                    cut_err(t(TK::RParen))
                        .context(StrContext::Label("')' closing $Code equation"))
                        .parse_next(input)?;
                    return Ok(Exp::CODE {
                        code: Arc::new(CodeNode::C_EQUATIONSECTION { boolean: initial, equationItemLst: eq }),
                    });
                }

                // Try CONSTRAINT code_constraint_clause
                if matches!(peek_kind(input), Some(TK::Constraint)) {
                    next_tok(input)?;
                    let constr = cut_err(code_constraint_clause)
                        .context(StrContext::Label("constraint clause in $Code"))
                        .parse_next(input)?;
                    cut_err(t(TK::RParen))
                        .context(StrContext::Label("')' closing $Code constraint"))
                        .parse_next(input)?;
                    return Ok(Exp::CODE {
                        code: Arc::new(CodeNode::C_CONSTRAINTSECTION { boolean: initial, equationItemLst: constr }),
                    });
                }

                // Try ALGORITHM code_algorithm_clause
                if matches!(peek_kind(input), Some(TK::Algorithm)) {
                    next_tok(input)?;
                    let alg = cut_err(code_algorithm_clause)
                        .context(StrContext::Label("algorithm clause in $Code"))
                        .parse_next(input)?;
                    cut_err(t(TK::RParen))
                        .context(StrContext::Label("')' closing $Code algorithm"))
                        .parse_next(input)?;
                    return Ok(Exp::CODE {
                        code: Arc::new(CodeNode::C_ALGORITHMSECTION { boolean: initial, algorithmItemLst: alg }),
                    });
                }

                // Try `modification`, BEFORE the expression alternatives like
                // the ANTLR rule does: `$Code(())` is an *empty class
                // modification* `()` (elabCodeType maps C_MODIFICATION to
                // C_EXPRESSION_OR_MODIFICATION, which the
                // `input ExpressionOrModification m = $Code(());` defaults in
                // ModelicaBuiltin.mo rely on), and `$Code((x))` is the
                // one-element modification list `(x)`. Only `$Code(((x)))`
                // and non-parenthesised contents reach the expression branch
                // — that is what the grammar's "Allow Code((<expr>))"
                // predicate is about. The ANTLR `modification` rule requires
                // a class modification or an (`=`|`:=`) binding (it has no
                // empty derivation, unlike our [`modification`] helper), and
                // the surrounding rule requires the closing `)`; backtrack
                // to the expression branch when either is missing.
                if matches!(peek_kind(input), Some(TK::LParen | TK::Equal | TK::Assign)) {
                    let checkpoint = input.checkpoint();
                    if let Ok(m) = modification.parse_next(input)
                        && matches!(peek_kind(input), Some(TK::RParen))
                    {
                        next_tok(input)?;
                        return Ok(Exp::CODE { code: Arc::new(CodeNode::C_MODIFICATION { modification: Arc::new(m) }) });
                    }
                    input.reset(&checkpoint);
                }

                // Try expression followed by ')'. Reset before the element
                // fallback: a failed expression parse may have consumed
                // tokens.
                let checkpoint = input.checkpoint();
                if let Ok(e) = expression.parse_next(input)
                    && matches!(peek_kind(input), Some(TK::RParen)) {
                        cut_err(t(TK::RParen))
                            .context(StrContext::Label("')' closing $Code expression"))
                            .parse_next(input)?;
                        return Ok(Exp::CODE {
                            code: Arc::new(CodeNode::C_EXPRESSION { exp: Arc::new(e) }),
                        });
                    }
                input.reset(&checkpoint);

                // Try element (SEMICOLON)? — the grammar requires the
                // closing ')' here like for every other alternative.
                if let Ok(element) = element.parse_next(input) {
                    opt(t(TK::Semi)).parse_next(input)?;
                    cut_err(t(TK::RParen))
                        .context(StrContext::Label("')' closing $Code element"))
                        .parse_next(input)?;
                    return Ok(Exp::CODE {
                        code: Arc::new(CodeNode::C_ELEMENT { element: Arc::new(element) }),
                    });
                }

        },
        _ => return Err(ErrMode::Backtrack(ContextError::default())),
    }

    // ---- CODE_NAME / CODE_ANNOTATION / CODE_EXP / CODE_VAR ----
    // These alternatives are distinguished by the first token:
    //   $TypeName ( … )   — first token after 'Code' would not be LParen
    //   but in our lexer $Code, $TypeName, $Expression, $Var are separate tokens.
    // Since we already consumed Code ($Code), the next token should be LParen.

    Err(ErrMode::Backtrack(ContextError::default()))
}

/// code_equation_clause: equation SEMICOLON code_equation_clause?
fn code_equation_clause(input: &mut TokenInput) -> ModalResult<Arc<List<Arc<EquationItem>>>> {
    let eq = Arc::new(equation_item(input)?);
    t(TK::Semi).parse_next(input)?;
    let rest = opt(code_equation_clause).parse_next(input)?.unwrap_or(nil());
    Ok(cons(eq, rest))
}

/// code_constraint_clause: equation SEMICOLON code_constraint_clause?
fn code_constraint_clause(input: &mut TokenInput) -> ModalResult<Arc<List<Arc<EquationItem>>>> {
    let eq = Arc::new(equation_item(input)?);
    t(TK::Semi).parse_next(input)?;
    let rest = opt(code_constraint_clause).parse_next(input)?.unwrap_or(nil());
    Ok(cons(eq, rest))
}

/// code_algorithm_clause: algorithm SEMICOLON code_algorithm_clause?
fn code_algorithm_clause(input: &mut TokenInput) -> ModalResult<Arc<List<Arc<AlgorithmItem>>>> {
    let alg = Arc::new(algorithm_item(input)?);
    t(TK::Semi).parse_next(input)?;
    let rest = opt(code_algorithm_clause).parse_next(input)?.unwrap_or(nil());
    Ok(cons(alg, rest))
}

fn part_eval_function_expression(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    t(TK::Function).parse_next(input)?;
    let cr      = component_reference(input)?;
    t(TK::LParen).parse_next(input)?;
    let argNames = opt(named_arguments).parse_next(input)?.unwrap_or(nil());
    t(TK::RParen).parse_next(input)?;
    Ok(Absyn::Exp::PARTEVALFUNCTION {
        function_: Arc::new(cr),
        functionArgs: Arc::new(Absyn::FunctionArgs::FUNCTIONARGS { args: nil(), argNames }),
    })
}

/// simple_expression: (ident AS simple_expr) | (simple_expr (:: simple_expression)?)
fn simple_expression(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    // Check for ident AS pattern (MetaModelica).
    {
        let saved = *input;
        let as_result: Option<ArcStr> = (|| {
            let id = match input.first() {
                Some(tok) => match &tok.kind {
                    TK::Ident(s) => s.clone(),
                    _ => return None,
                },
                None => return None,
            };
            *input = &input[1..];
            match input.first() {
                Some(tok) if tok.kind == TK::As => { *input = &input[1..]; Some(id) }
                _ => None,
            }
        })();
        match as_result {
            Some(id) => {
                let e = simple_expression(input)?;
                return Ok(Absyn::Exp::AS { id, exp: Arc::new(e) });
            }
            None => { *input = saved; }
        }
    }

    let e1 = simple_expr(input)?;
    if matches!(peek_kind(input), Some(TK::ColonColon)) {
        next_tok(input)?;
        let e2 = simple_expression(input)?;
        Ok(Absyn::Exp::CONS { head: Arc::new(e1), rest: Arc::new(e2) })
    } else {
        Ok(e1)
    }
}

/// simple_expr: logical_expression (: logical_expression (: logical_expression)?)?
fn simple_expr(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    let e1 = logical_expression(input)?;
    if !matches!(peek_kind(input), Some(TK::Colon)) {
        return Ok(e1);
    }
    next_tok(input)?; // ':'
    let e2 = logical_expression(input)?;
    if matches!(peek_kind(input), Some(TK::Colon)) {
        next_tok(input)?; // ':'
        let e3 = logical_expression(input)?;
        Ok(Absyn::Exp::RANGE { start: Arc::new(e1), step: Some(Arc::new(e2)), stop: Arc::new(e3) })
    } else {
        Ok(Absyn::Exp::RANGE { start: Arc::new(e1), step: None, stop: Arc::new(e2) })
    }
}

fn logical_expression(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    let mut e = logical_term(input)?;
    loop {
        if !matches!(peek_kind(input), Some(TK::Or)) { break; }
        next_tok(input)?;
        let e2 = logical_term(input)?;
        e = Absyn::Exp::LBINARY { exp1: Arc::new(e), op: Absyn::Operator::OR {}, exp2: Arc::new(e2) };
    }
    Ok(e)
}

fn logical_term(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    let mut e = logical_factor(input)?;
    loop {
        if !matches!(peek_kind(input), Some(TK::And)) { break; }
        next_tok(input)?;
        let e2 = logical_factor(input)?;
        e = Absyn::Exp::LBINARY { exp1: Arc::new(e), op: Absyn::Operator::AND {}, exp2: Arc::new(e2) };
    }
    Ok(e)
}

fn logical_factor(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    let has_not = matches!(peek_kind(input), Some(TK::Not));
    if has_not { next_tok(input)?; }
    let e = relation(input)?;
    if has_not { Ok(Absyn::Exp::LUNARY { op: Absyn::Operator::NOT {}, exp: Arc::new(e) }) }
    else       { Ok(e) }
}

fn relation(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    let e1 = arithmetic_expression(input)?;
    let op = match peek_kind(input) {
        Some(TK::Leq)     => { next_tok(input)?; Some(Absyn::Operator::LESSEQ {}) }
        Some(TK::Geq)     => { next_tok(input)?; Some(Absyn::Operator::GREATEREQ {}) }
        Some(TK::NotEq)   => { next_tok(input)?; Some(Absyn::Operator::NEQUAL {}) }
        Some(TK::EqEq)    => { next_tok(input)?; Some(Absyn::Operator::EQUAL {}) }
        Some(TK::Less)    => { next_tok(input)?; Some(Absyn::Operator::LESS {}) }
        Some(TK::Greater) => { next_tok(input)?; Some(Absyn::Operator::GREATER {}) }
        _                 => None,
    };
    match op {
        Some(op) => Ok(Absyn::Exp::RELATION { exp1: Arc::new(e1), op, exp2: Arc::new(arithmetic_expression(input)?) }),
        None     => Ok(e1),
    }
}

fn arithmetic_expression(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    let mut e = unary_arithmetic_expression(input)?;
    loop {
        let op = match peek_kind(input) {
            Some(TK::PlusEw)  => { next_tok(input)?; Some(Absyn::Operator::ADD_EW {}) }
            Some(TK::MinusEw) => { next_tok(input)?; Some(Absyn::Operator::SUB_EW {}) }
            Some(TK::Plus)    => { next_tok(input)?; Some(Absyn::Operator::ADD {}) }
            Some(TK::Minus)   => { next_tok(input)?; Some(Absyn::Operator::SUB {}) }
            _                 => None,
        };
        match op {
            Some(op) => { let e2 = term(input)?; e = Absyn::Exp::BINARY { exp1: Arc::new(e), op, exp2: Arc::new(e2) }; }
            None     => break,
        }
    }
    Ok(e)
}

fn unary_arithmetic_expression(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    let op = match peek_kind(input) {
        Some(TK::PlusEw)  => { next_tok(input)?; Some(Absyn::Operator::UPLUS_EW {}) }
        Some(TK::MinusEw) => { next_tok(input)?; Some(Absyn::Operator::UMINUS_EW {}) }
        Some(TK::Plus)    => { next_tok(input)?; Some(Absyn::Operator::UPLUS {}) }
        Some(TK::Minus)   => { next_tok(input)?; Some(Absyn::Operator::UMINUS {}) }
        _                 => None,
    };
    let t_expr = term(input)?;
    match op {
        Some(op) => Ok(Absyn::Exp::UNARY { op, exp: Arc::new(t_expr) }),
        None     => Ok(t_expr),
    }
}

fn term(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    let mut e = factor(input)?;
    loop {
        let op = match peek_kind(input) {
            Some(TK::StarEw)  => { next_tok(input)?; Some(Absyn::Operator::MUL_EW {}) }
            Some(TK::SlashEw) => { next_tok(input)?; Some(Absyn::Operator::DIV_EW {}) }
            Some(TK::Star)    => { next_tok(input)?; Some(Absyn::Operator::MUL {}) }
            Some(TK::Slash)   => { next_tok(input)?; Some(Absyn::Operator::DIV {}) }
            _                 => None,
        };
        match op {
            Some(op) => { let e2 = factor(input)?; e = Absyn::Exp::BINARY { exp1: Arc::new(e), op, exp2: Arc::new(e2) }; }
            None     => break,
        }
    }
    Ok(e)
}

fn factor(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    let e1 = primary(input)?;
    let op = match peek_kind(input) {
        Some(TK::PowerEw) => { next_tok(input)?; Some(Absyn::Operator::POW_EW {}) }
        Some(TK::Power)   => { next_tok(input)?; Some(Absyn::Operator::POW {}) }
        _                 => None,
    };
    match op {
        Some(op) => Ok(Absyn::Exp::BINARY { exp1: Arc::new(e1), op, exp2: Arc::new(primary(input)?) }),
        None     => Ok(e1),
    }
}

fn primary(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    match peek_kind(input) {
        Some(TK::End)   => { next_tok(input)?; return Ok(Absyn::Exp::END {}); }
        Some(TK::True)  => { next_tok(input)?; return Ok(Absyn::Exp::BOOL { value: true  }); }
        Some(TK::False) => { next_tok(input)?; return Ok(Absyn::Exp::BOOL { value: false }); }
        Some(TK::Str(s))=> { let value = s.clone(); next_tok(input)?; return Ok(Absyn::Exp::STRING { value }); }
        Some(TK::Int(_)) | Some(TK::Real(..)) => { return number_literal(input); }
        Some(TK::LParen) => {
            let (paren_line, paren_col) = next_pos(input);
            next_tok(input)?;
            let (exprs, is_tuple) = output_expression_list(input)?;
            let before_subs: TokenInput = *input;
            let raw_subs = opt(array_subscripts).parse_next(input)?;
            if let Some(subs) = raw_subs {
                // `(e)[subs]` stores the bare expression; the dump re-adds
                // the parentheses for SUBSCRIPTED_EXP itself. Subscripting a
                // tuple is a syntax error, as in `Modelica.g` `primary`
                // (recorded there as a non-fatal c_add_source_message; we
                // abort, which yields the same observable diagnostic).
                if is_tuple {
                    // The grammar anchors the span's end at the closing `]` of
                    // the subscripts (the last consumed token), not at the next
                    // unconsumed token — so the end column lands on the `]`,
                    // matching omc (e.g. `(1,2,3)[2]` reports `…-l:c` at the
                    // `]`, not the following `;`).
                    let consumed = before_subs.len() - input.len();
                    let (l2, c2) = if consumed >= 1 {
                        let last = &before_subs[consumed - 1];
                        (last.line, last.col)
                    } else {
                        (paren_line, paren_col)
                    };
                    add_syntax_message(
                        SyntaxSeverity::Error,
                        "Tuple expression can not be subscripted.".to_owned(),
                        paren_line, paren_col, l2, c2,
                    );
                    return Err(ErrMode::Cut(ContextError::new()));
                }
                let exp = match &*exprs {
                    List::Cons { head, .. } => head.clone(),
                    // output_expression_list only reports `()` as a tuple, so
                    // a non-tuple result always has exactly one element.
                    List::Nil => unreachable!("non-tuple output_expression_list returned no expression"),
                };
                let mut rc_subs: Arc<List<Arc<Subscript>>> = nil();
                for s in &*(subs.reverse()) { rc_subs = cons(s.clone(), rc_subs); }
                return Ok(Absyn::Exp::SUBSCRIPTED_EXP { exp, subscripts: rc_subs });
            }
            // Parentheses are preserved in the AST: like the regular (non-
            // OMC_BOOTSTRAPPING) C parser in `Modelica.g` `primary`, `(e)`
            // becomes a single-element TUPLE. The dumps rely on this instead
            // of re-deriving operator precedence (AbsynDumpTpl.dumpOperand
            // has shouldParenthesize commented out), and the semantic phases
            // unwrap it (Static.elabExp_Tuple_LHS_RHS, NFInst.instExp,
            // Patternm.elabPattern). For a non-tuple, `exprs` is already the
            // single-element list to wrap.
            return Ok(Absyn::Exp::TUPLE { expressions: exprs });
        }
        Some(TK::LBracket) => {
            next_tok(input)?;
            let rows = matrix_expression_list(input)?;
            t(TK::RBracket).parse_next(input)?;
            return Ok(Absyn::Exp::MATRIX { matrix: rows });
        }
        Some(TK::LBrace) => {
            let (brace_line, brace_col) = next_pos(input);
            next_tok(input)?;
            let fa = for_or_expression_list(input)?;
            t(TK::RBrace).parse_next(input)?;
            return match fa {
                Absyn::FunctionArgs::FOR_ITER_FARG { exp, iterType, iterators } => {
                    let cr = Absyn::ComponentRef::CREF_IDENT { name: "$array".into(), subscripts: nil() };
                    Ok(Absyn::Exp::CALL {
                        function_: Arc::new(cr),
                        functionArgs: Arc::new(Absyn::FunctionArgs::FOR_ITER_FARG { exp, iterType, iterators }),
                        typeVars: nil(),
                    })
                }
                Absyn::FunctionArgs::FUNCTIONARGS { args, argNames } if argNames.is_empty() => {
                    // `{}` is only allowed in MetaModelica (the empty list)
                    // and in interactive .mos scripts (`Modelica.g` allows it
                    // there explicitly).
                    if args.is_empty() && !metamodelica_enabled() && !parse_expression_enabled() {
                        let (l2, c2) = match input.first() {
                            Some(t) => (t.line, t.col.saturating_sub(1)),
                            None => (brace_line, brace_col + 1),
                        };
                        return Err(parser_assert_fail(
                            "Empty array constructors are not valid in Modelica.",
                            brace_line, brace_col, l2, c2,
                        ));
                    }
                    Ok(Absyn::Exp::ARRAY { arrayExp: args })
                }
                _ => Err(ErrMode::Backtrack(ContextError::default())),
            };
        }
        Some(TK::Der) => {
            next_tok(input)?;
            let fa = function_call(input)?;
            let cr = Absyn::ComponentRef::CREF_IDENT { name: "der".into(), subscripts: nil() };
            return Ok(Absyn::Exp::CALL { function_: Arc::new(cr), functionArgs: Arc::new(fa), typeVars: nil() });
        }
        Some(TK::Pure) => {
            next_tok(input)?;
            let fa = function_call(input)?;
            let cr = Absyn::ComponentRef::CREF_IDENT { name: "pure".into(), subscripts: nil() };
            return Ok(Absyn::Exp::CALL { function_: Arc::new(cr), functionArgs: Arc::new(fa), typeVars: nil() });
        }
        Some(TK::Wild) => {
            next_tok(input)?;
            return Ok(Absyn::Exp::CREF { componentRef: Arc::new(Absyn::ComponentRef::WILD {}) });
        }
        Some(TK::Allwild) => {
            next_tok(input)?;
            return Ok(Absyn::Exp::CREF { componentRef: Arc::new(Absyn::ComponentRef::ALLWILD {}) });
        }
        _ => {}
    }
    component_reference__function_call(input)
}

fn number_literal(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    match next_tok(input)? {
        TK::Int(n)  => Ok(Absyn::Exp::INTEGER { value: n }),
        TK::Real(_, s) => Ok(Absyn::Exp::REAL    { value: s }),
        _           => Err(ErrMode::Backtrack(ContextError::default())),
    }
}

fn component_reference__function_call(input: &mut TokenInput) -> ModalResult<Absyn::Exp> {
    // initial()
    if matches!(peek_kind(input), Some(TK::Initial)) {
        next_tok(input)?;
        if matches!(peek_kind(input), Some(TK::LParen)) {
            next_tok(input)?;
            t(TK::RParen).parse_next(input)?;
            let cr = Absyn::ComponentRef::CREF_IDENT { name: "initial".into(), subscripts: nil() };
            return Ok(Absyn::Exp::CALL {
                function_: Arc::new(cr),
                functionArgs: Arc::new(Absyn::FunctionArgs::FUNCTIONARGS { args: nil(), argNames: nil() }),
                typeVars: nil(),
            });
        }
        // Not initial() — treat 'initial' as an identifier.
        // Fall through with synthetic cref.
        return Ok(Absyn::Exp::CREF {
            componentRef: Arc::new(Absyn::ComponentRef::CREF_IDENT { name: "initial".into(), subscripts: nil() }),
        });
    }

    let cr = component_reference(input)?;

    // Polymorphic call: cr <T1,T2,...> ( args )
    if matches!(peek_kind(input), Some(TK::Less)) {
        let saved = *input;
        if let Ok(type_vars) = (|| -> ModalResult<Arc<List<Path>>> {
            next_tok(input)?; // '<'
            let mut vars: Arc<List<Path>> = nil();
            loop {
                if matches!(peek_kind(input), Some(TK::Greater)) { break; }
                vars = cons(name_path(input)?, vars);
                if opt(t(TK::Comma)).parse_next(input)?.is_none() { break; }
            }
            t(TK::Greater).parse_next(input)?;
            Ok(vars.reverse())
        })() {
            if matches!(peek_kind(input), Some(TK::LParen)) {
                let fa = function_call(input)?;
                return Ok(Absyn::Exp::CALL { function_: Arc::new(cr), functionArgs: Arc::new(fa), typeVars: to_rc_list(type_vars) });
            }
            *input = saved;
        } else {
            *input = saved;
        }
    }

    // Optional function call.
    if matches!(peek_kind(input), Some(TK::LParen)) {
        let fa = function_call(input)?;
        // Optional .field access after call (MetaModelica dot operator).
        if input.len() >= 2
            && input[0].kind == TK::Dot
            && matches!(&input[1].kind, TK::Ident(_))
        {
            next_tok(input)?; // Dot
            let field = expression(input)?;
            return Ok(Absyn::Exp::DOT {
                exp:   Arc::new(Absyn::Exp::CALL { function_: Arc::new(cr), functionArgs: Arc::new(fa), typeVars: nil() }),
                index: Arc::new(field),
            });
        }
        return Ok(Absyn::Exp::CALL { function_: Arc::new(cr), functionArgs: Arc::new(fa), typeVars: nil() });
    }

    Ok(Absyn::Exp::CREF { componentRef: Arc::new(cr) })
}

fn function_call(input: &mut TokenInput) -> ModalResult<Absyn::FunctionArgs> {
    t(TK::LParen).parse_next(input)?;
    let fa = function_arguments(input)?;
    t(TK::RParen).parse_next(input)?;
    Ok(fa)
}

fn function_arguments(input: &mut TokenInput) -> ModalResult<Absyn::FunctionArgs> {
    for_or_expression_list(input)
    /* for_or_expression_list returns the named arguments now, and for array they trigger an error
    match fa {
        Absyn::FunctionArgs::FOR_ITER_FARG { .. } => Ok(fa),
        Absyn::FunctionArgs::FUNCTIONARGS { args, argNames } => {
            if !matches!(argNames, List::Nil) {
                return Ok(Absyn::FunctionArgs::FUNCTIONARGS { args, argNames });
            }
            let argNames = opt(named_arguments).parse_next(input)?.unwrap_or(nil());
            Ok(Absyn::FunctionArgs::FUNCTIONARGS { args, argNames })
        }
    }*/
}

fn for_or_expression_list(input: &mut TokenInput) -> ModalResult<Absyn::FunctionArgs> {
    // Empty.
    if matches!(peek_kind(input), Some(TK::RParen) | Some(TK::RBrace) | None) {
        return Ok(Absyn::FunctionArgs::FUNCTIONARGS { args: nil(), argNames: nil() });
    }

    // If the first token cannot start an expression (e.g. a keyword used as a record
    // field name like `constraint = value`), try all-named-arguments directly.
    let mut checkpoint = input.checkpoint();
    let mut exp = match arg_expression(input) {
        Ok(e) => e,
        Err(ErrMode::Backtrack(_)) => {
            input.reset(&checkpoint);
            let arg_names = named_arguments(input)?;
            return Ok(Absyn::FunctionArgs::FUNCTIONARGS {
                args: nil(),
                argNames: arg_names,
            });
        }
        Err(e) => return Err(e),
    };

    // For-iterator.
    if matches!(peek_kind(input), Some(TK::For) | Some(TK::Threaded)) {
        let threaded = if matches!(peek_kind(input), Some(TK::Threaded)) {
            next_tok(input)?; true
        } else { false };
        t(TK::For).parse_next(input)?;
        let iterators = for_indices(input)?;
        return Ok(Absyn::FunctionArgs::FOR_ITER_FARG {
            exp: Arc::new(exp),
            iterType: if threaded { Absyn::ReductionIterType::THREAD {} } else { Absyn::ReductionIterType::COMBINE {} },
            iterators,
        });
    }

    // Expression list, possibly ending with named arguments.
    let mut args: Arc<List<Arc<Absyn::Exp>>> = nil();
    let mut arg_names: Arc<List<Arc<Absyn::NamedArg>>> = nil();
    loop {
        let is_plain_ident = matches!(
            &exp,
            Exp::CREF { componentRef }
            if matches!(&**componentRef, ComponentRef::CREF_IDENT { subscripts, .. } if subscripts.is_empty())
        );
        if is_plain_ident {
            let saved = *input;
            input.reset(&checkpoint);
            match named_arguments.parse_next(input) {
                Ok(na) => { arg_names = na; break; }
                Err(_) => { *input = saved; }
            }
        }
        args = cons(Arc::new(exp), args);
        if opt(t(TK::Comma)).parse_next(input)?.is_none() { break; }
        checkpoint = input.checkpoint();
        exp = arg_expression(input)?;
    }
    // `args` is cons-built back to front and needs the reverse; `arg_names`
    // comes from `named_arguments`, which already returns source order
    // (interactive-API unparsing is sensitive to it, e.g.
    // `annotate=Placement(transformation(origin=..., extent=...))`).
    Ok(Absyn::FunctionArgs::FUNCTIONARGS { args: args.reverse(), argNames: arg_names })
}

fn named_argument(input: &mut TokenInput) -> ModalResult<Absyn::NamedArg> {
    let argName  = t_any_ident(input)?;
    t(TK::Equal).parse_next(input)?;
    let argValue = Arc::new(arg_expression(input)?);
    Ok(Absyn::NamedArg { argName, argValue })
}

fn named_arguments(input: &mut TokenInput) -> ModalResult<Arc<List<Arc<Absyn::NamedArg>>>> {
    let first = named_argument(input)?;
    let mut args: Arc<List<Arc<Absyn::NamedArg>>> = cons(Arc::new(first), nil());
    loop {
        if opt(t(TK::Comma)).parse_next(input)?.is_none() { break; }
        match named_argument(input) {
            Ok(arg) => args = cons(Arc::new(arg), args),
            Err(_)  => break,
        }
    }
    Ok(args.reverse())
}

fn for_indices(input: &mut TokenInput) -> ModalResult<Absyn::ForIterators> {
    let first = for_index(input)?;
    let mut result: Arc<List<Absyn::ForIterator>> = List::new(first);
    loop {
        if opt(t(TK::Comma)).parse_next(input)?.is_none() { break; }
        match for_index(input) {
            Ok(fi)  => result = cons(fi, result),
            Err(_)  => break,
        }
    }
    Ok(to_rc_list(result.reverse()))
}

fn for_index(input: &mut TokenInput) -> ModalResult<Absyn::ForIterator> {
    let name = t_ident(input)?;
    let guardExp = match peek_kind(input) {
        Some(TK::If) | Some(TK::Guard) => {
            next_tok(input)?;
            Some(Arc::new(expression(input)?))
        }
        _ => None,
    };
    let range = if matches!(peek_kind(input), Some(TK::In)) {
        next_tok(input)?;
        Some(Arc::new(expression(input)?))
    } else { None };
    Ok(Absyn::ForIterator { name, guardExp, range })
}

fn expression_list(input: &mut TokenInput) -> ModalResult<Arc<List<Arc<Absyn::Exp>>>> {
    let e = expression(input)?;
    let mut result: Arc<List<Arc<Absyn::Exp>>> = cons(Arc::new(e), nil());
    loop {
        if opt(t(TK::Comma)).parse_next(input)?.is_none() { break; }
        match expression(input) {
            Ok(e)  => result = cons(Arc::new(e), result),
            Err(_) => break,
        }
    }
    Ok(result.reverse())
}

/// Consumes up to and including ')'; returns (expressions, isTuple).
fn output_expression_list(input: &mut TokenInput) -> ModalResult<(Arc<List<Arc<Absyn::Exp>>>, bool)> {
    // ()
    if opt(t(TK::RParen)).parse_next(input)?.is_some() {
        return Ok((nil(), true));
    }
    // Leading comma: (, b) → WILD, b
    if opt(t(TK::Comma)).parse_next(input)?.is_some() {
        let (rest, _) = output_expression_list(input)?;
        let wild_exp = Arc::new(Absyn::Exp::CREF { componentRef: Arc::new(Absyn::ComponentRef::WILD {}) });
        return Ok((cons(wild_exp, rest), true));
    }
    let e1 = expression(input)?;
    if opt(t(TK::Comma)).parse_next(input)?.is_some() {
        let (mut result, _) = output_expression_list(input)?;
        if result.is_empty() {
            let wild = Arc::new(Absyn::Exp::CREF { componentRef: Arc::new(Absyn::ComponentRef::WILD {}) });
            result = cons(wild, result);
        }
        return Ok((cons(Arc::new(e1), result), true));
    }
    t(TK::RParen).parse_next(input)?;
    Ok((cons(Arc::new(e1), nil()), false))
}

fn matrix_expression_list(input: &mut TokenInput) -> ModalResult<Arc<List<Arc<List<Arc<Absyn::Exp>>>>>> {
    let row = expression_list(input)?;
    let mut rows = cons(row, nil());
    loop {
        if matches!(peek_kind(input), Some(TK::Semi)) {
            next_tok(input)?;
            if matches!(peek_kind(input), Some(TK::RBracket)) { break; }
            match expression_list(input) {
                Ok(r)  => rows = cons(r, rows),
                Err(_) => break,
            }
        } else {
            break;
        }
    }
    Ok(rows.reverse())
}

// ---------------------------------------------------------------------------
// String comments and types
// ---------------------------------------------------------------------------

fn string_comment(input: &mut TokenInput) -> ModalResult<Option<ArcStr>> {
    let mut res: String = match opt(t_str_token).parse_next(input)? {
        Some(s) => s.to_string(),
        None    => return Ok(None),
    };
    while opt(t(TK::Plus)).parse_next(input)?.is_some() {
        res.push_str(&cut_err(t_str_token).parse_next(input)?);
    }
    Ok(Some(res.into()))
}

fn comment(input: &mut TokenInput) -> ModalResult<Option<Comment>> {
    let comment = string_comment.parse_next(input)?;
    let annotation_ = opt(annotation).parse_next(input)?;
    // The ANTLR rule yields no COMMENT node when both parts are absent —
    // `SOME(COMMENT(NONE, NONE))` is not the same as `NONE` to consumers
    // like Interactive.updateEquation's mergeDescription, which probes
    // `isNone(newEq.comment)` to decide whether to keep the old description.
    if comment.is_none() && annotation_.is_none() {
        return Ok(None);
    }
    Ok(Some(Comment { comment, annotation_: annotation_.map(Arc::new) }))
}

fn type_specifier(input: &mut TokenInput) -> ModalResult<TypeSpec> {
    type_specifier_impl(input, /*allow_dims=*/true)
}

/// `type_specifier_no_dims` from Modelica.g: the type in a (re)declared
/// component clause (`component_clause1`) must not carry array dimensions —
/// `redeclare A[2] x` is a syntax error (dimensions belong on the component).
fn type_specifier_no_dims(input: &mut TokenInput) -> ModalResult<TypeSpec> {
    type_specifier_impl(input, /*allow_dims=*/false)
}

fn type_specifier_impl(input: &mut TokenInput, allow_dims: bool) -> ModalResult<TypeSpec> {
    let path = name_path(input)?;
    let mut ts: Arc<List<Arc<TypeSpec>>> = nil();
    if opt(t(TK::Less)).parse_next(input)?.is_some() {
        loop {
            if matches!(peek_kind(input), Some(TK::Greater)) || input.is_empty() { break; }
            let inner_ts = type_specifier(input)?;
            ts = cons(Arc::new(inner_ts), ts);
            if opt(t(TK::Comma)).parse_next(input)?.is_some() { continue; }
            break;
        }
        ts = ts.reverse();
        t(TK::Greater).parse_next(input)?;
    }
    let arrayDim = if allow_dims { opt(array_subscripts).parse_next(input)? } else { None };
    if ts.is_empty() {
        Ok(TypeSpec::TPATH { path: Arc::new(path), arrayDim })
    } else {
        Ok(TypeSpec::TCOMPLEX { path: Arc::new(path), typeSpecs: ts, arrayDim })
    }
}

fn subscript(input: &mut TokenInput) -> ModalResult<Subscript> {
    if matches!(peek_kind(input), Some(TK::Colon)) {
        next_tok(input)?;
        return Ok(Subscript::NOSUB {});
    }
    Ok(Subscript::SUBSCRIPT { subscript: Arc::new(expression(input)?) })
}

fn array_subscripts(input: &mut TokenInput) -> ModalResult<ArrayDim> {
    t(TK::LBracket).parse_next(input)?;
    let mut subs: Arc<List<Subscript>> = nil();
    loop {
        if matches!(peek_kind(input), Some(TK::RBracket)) || input.is_empty() { break; }
        subs = cons(subscript(input)?, subs);
        if opt(t(TK::Comma)).parse_next(input)?.is_none() { break; }
    }
    t(TK::RBracket).parse_next(input)?;
    Ok(to_rc_list(subs.reverse()))
}

fn enum_list(input: &mut TokenInput) -> ModalResult<Arc<List<EnumLiteral>>> {
    let mut literals: Arc<List<EnumLiteral>> = nil();
    loop {
        match peek_kind(input) {
            None | Some(TK::Pipe) | Some(TK::Comma) | Some(TK::Semi)
            | Some(TK::Str(_)) | Some(TK::RParen) => break,
            _ => {}
        }
        match enum_literal(input) {
            Ok(lit) => literals = cons(lit, literals),
            Err(_)  => break,
        }
        if opt(t(TK::Comma)).parse_next(input)?.is_some() { continue; }
        break;
    }
    Ok(literals.reverse())
}

fn enum_literal(input: &mut TokenInput) -> ModalResult<EnumLiteral> {
    let literal = t_ident(input)?;
    let comment = comment.parse_next(input)?;
    Ok(EnumLiteral { literal, comment: comment.map(Arc::new) })
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_array() {
        // `{}` is a syntax error in plain Modelica (`Modelica.g` `primary`:
        // "Empty array constructors are not valid in Modelica.")…
        CURRENT_GRAMMAR.with(|g| g.set(Grammar::Modelica3));
        INTERACTIVE_PARSE.with(|f| f.set(false));
        let tokens = lexer::lex("{};", Grammar::Modelica3).unwrap();
        let mut ts = tokens.as_slice();
        assert!(expression(&mut ts).is_err());
        let msgs = take_syntax_messages();
        assert!(msgs.iter().any(|m| m.message.contains("Empty array constructors")),
                "messages = {msgs:?}");
        // …but it is the empty-list literal in MetaModelica.
        CURRENT_GRAMMAR.with(|g| g.set(Grammar::MetaModelica));
        let tokens = lexer::lex("{};", Grammar::MetaModelica).unwrap();
        let mut ts = tokens.as_slice();
        let exp = expression(&mut ts).unwrap();
        assert!(matches!(exp, Exp::ARRAY { arrayExp } if arrayExp.is_empty()));
    }

    #[test]
    fn array_expr() {
        let tokens = lexer::lex("{1,2,3};", Grammar::Modelica3).unwrap();
        let mut ts = tokens.as_slice();
        let exp = expression(&mut ts).unwrap();
        assert!(matches!(exp, Exp::ARRAY { arrayExp } if arrayExp.len() == 3));
    }

    #[test]
    fn parse_simple_package() {
        let code = "package SimpleSystem \"Returns the index...\"\n\
                    /* ... */\n\
                    Real x(start=0);\n\
                    end SimpleSystem;";
        match parse(code, "", "", Grammar::MetaModelica, false, 0.0).unwrap() {
            Program { classes, .. } => {
                assert!(!classes.is_empty());
                if let List::Cons { head, .. } = &*classes {
                    let Class { name, .. } = &**head;
                    assert_eq!(&**name, "SimpleSystem");
                }
            }
        }
    }

    #[test]
    fn parse_first_token() {
        let code = "package SimpleSystem \"Returns the index...\"\nend SimpleSystem;";
        parse(code, "", "", Grammar::MetaModelica, false, 0.0).expect("expected parse success");
    }

    #[test]
    fn parse_absyn() {
        let code = std::fs::read_to_string("tests/data/Absyn.mo").expect("Absyn.mo not found");
        if let Err(e) = parse(&code, "Absyn.mo", "Absyn.mo", Grammar::MetaModelica, false, 0.0) {
            panic!("expected Absyn.mo to parse: {e}");
        }
    }

    #[test]
    fn class_annotations_stored_in_reverse_source_order() {
        // Annotations inside an equation section are class-level annotations
        // (equation_annotation_list in Modelica.g). The C parser accumulates
        // `PARTS.ann` by *prepending*, so the stored list is in reverse
        // source order and AbsynDumpTpl's dumpClassDef compensates with
        // listReverse(ann) — the port matches that storage convention
        // (flattening/modelica/declarations/Annotations.mo pins the printed
        // order).
        let code = "\
model c\n\
  Real x;\n\
equation\n\
  x = 1;\n\
  annotation(key = value);\n\
  annotation(key2 = value2);\n\
end c;\n\
";
        let prog = parse(code, "t.mo", "t.mo", Grammar::Modelica3, false, 0.0).expect("parse");
        let Program { classes, .. } = prog;
        let first = match &*classes { List::Cons { head, .. } => head.clone(), _ => panic!("no classes") };
        let Class { body, .. } = &*first;
        let ClassDef::PARTS { ann, .. } = &**body else { panic!("expected PARTS") };
        let keys: Vec<String> = (&**ann).into_iter().map(|a| {
            let Annotation { elementArgs } = &**a;
            match &**elementArgs {
                List::Cons { head, .. } => match &**head {
                    ElementArg::MODIFICATION { path, .. } => format!("{path:?}"),
                    other => format!("{other:?}"),
                },
                List::Nil => "<empty>".to_owned(),
            }
        }).collect();
        assert!(keys.len() == 2 && keys[0].contains("key2") && keys[1].contains("key\""),
                "annotation order wrong (expected reverse source order): {keys:?}");
    }

    #[test]
    fn comments_spliced_into_ast() {
        // Three distinct comment placements that round-trip through the
        // parser: between classes (commentsBeforeClass / commentsAfterEnd),
        // between elements (LEXER_COMMENT inside a PUBLIC section), and
        // between algorithm statements (ALGORITHMITEMCOMMENT).
        let code = "\
// before A\n\
package A\n\
  // between elements\n\
  Real x;\n\
algorithm\n\
  // between statements\n\
  x := 1.0;\n\
end A;\n\
// after A\n\
";
        let prog = parse(code, "t.mo", "t.mo", Grammar::MetaModelica, false, 0.0).expect("parse");
        let Program { classes, .. } = prog;
        let first = match &*classes { List::Cons { head, .. } => head.clone(), _ => panic!("no classes") };
        let Class { commentsBeforeClass, commentsAfterEnd, body, .. } = &*first;
        assert!((&*commentsBeforeClass).into_iter().any(|c| c.contains("before A")),
                "commentsBeforeClass = {:?}", commentsBeforeClass);
        assert!((&*commentsAfterEnd).into_iter().any(|c| c.contains("after A")),
                "commentsAfterEnd = {:?}", commentsAfterEnd);
        // Walk the body for the embedded comments.
        let ClassDef::PARTS { classParts, .. } = &**body else { panic!("expected PARTS"); };
        let mut saw_lexer_comment = false;
        let mut saw_alg_comment = false;
        for cp in &**classParts {
            match &**cp {
                ClassPart::PUBLIC { contents } => {
                    for ei in &**contents {
                        if let ElementItem::LEXER_COMMENT { comment } = &**ei {
                            if comment.contains("between elements") { saw_lexer_comment = true; }
                        }
                    }
                }
                ClassPart::ALGORITHMS { contents } => {
                    for ai in &**contents {
                        if let AlgorithmItem::ALGORITHMITEMCOMMENT { comment } = &**ai {
                            if comment.contains("between statements") { saw_alg_comment = true; }
                        }
                    }
                }
                _ => {}
            }
        }
        assert!(saw_lexer_comment, "expected LEXER_COMMENT in element list");
        assert!(saw_alg_comment, "expected ALGORITHMITEMCOMMENT in algorithm list");
    }

    #[test]
    fn expression_comment_wraps_inner_expression() {
        // In a stored definition (`interactive == false`), a comment placed
        // immediately before/after an expression round-trips as an
        // `EXPRESSIONCOMMENT` wrapper, mirroring the ANTLR3 `expression` rule at
        // `grammars/Modelica.g:1554`. The reference omc preserves such comments
        // when a class is re-dumped via `list`.
        let code = "\
package P\n\
algorithm\n\
  x := /* before */ 1 /* after */;\n\
end P;\n\
";
        let prog = parse(code, "t.mo", "t.mo", Grammar::MetaModelica, false, 0.0).expect("parse");
        let Program { classes, .. } = prog;
        let first = match &*classes { List::Cons { head, .. } => head.clone(), _ => panic!("no classes") };
        let Class { body, .. } = &*first;
        let ClassDef::PARTS { classParts, .. } = &**body else { panic!("expected PARTS"); };
        let mut saw_wrapper = false;
        for cp in &**classParts {
            if let ClassPart::ALGORITHMS { contents } = &**cp {
                for ai in &**contents {
                    if let AlgorithmItem::ALGORITHMITEM { algorithm_, .. } = &**ai
                        && let Algorithm::ALG_ASSIGN { value, .. } = &**algorithm_
                        && let Exp::EXPRESSIONCOMMENT { commentsBefore, commentsAfter, .. } = &**value
                    {
                        assert!((&*commentsBefore.clone()).into_iter().any(|c| c.contains("before")),
                                "commentsBefore = {commentsBefore:?}");
                        assert!((&*commentsAfter.clone()).into_iter().any(|c| c.contains("after")),
                                "commentsAfter = {commentsAfter:?}");
                        saw_wrapper = true;
                    }
                }
            }
        }
        assert!(saw_wrapper, "expected an EXPRESSIONCOMMENT wrapper around the RHS");
    }

    #[test]
    fn interactive_expression_comment_is_dropped() {
        // An interactive `.mos` statement does NOT wrap its expression in
        // `EXPRESSIONCOMMENT`: the reference omc echoes `f()`, not
        // `// c f()`, under `-d=showStatement`. The leading comment is drained
        // and discarded.
        let stmts = parse_statements(
            "// a comment\nf();", "t.mos", "t.mos", Grammar::MetaModelica, false, 0.0,
        ).expect("parse");
        let items: Vec<_> = (&*stmts.interactiveStmtLst).into_iter().collect();
        assert_eq!(items.len(), 1, "expected one statement");
        let crate::GlobalScript::Statement::IEXP { exp, .. } = &*items[0] else {
            panic!("expected IEXP, got {:?}", items[0]);
        };
        assert!(!matches!(&**exp, Exp::EXPRESSIONCOMMENT { .. }),
                "interactive expression must not be wrapped in EXPRESSIONCOMMENT, got {exp:?}");
    }

    #[test]
    fn parens_preserved_as_single_element_tuple() {
        // `(e)` is kept in the AST as a single-element TUPLE, mirroring the
        // regular (non-OMC_BOOTSTRAPPING) ANTLR3 parser in `Modelica.g`
        // `primary`. The Absyn dumps print parentheses from this node —
        // AbsynDumpTpl.dumpOperand no longer re-derives operator precedence
        // (shouldParenthesize is commented out upstream) — so dropping the
        // wrapper regresses e.g. openmodelica/diff/RLC.mos. Real tuples and
        // subscripted parenthesized expressions keep their own shapes.
        let code = "\
package P\n\
algorithm\n\
  x := a*(b + c);\n\
  (u, v) := f(y);\n\
  w := (g(y))[1];\n\
end P;\n\
";
        let prog = parse(code, "t.mo", "t.mo", Grammar::MetaModelica, false, 0.0).expect("parse");
        let Program { classes, .. } = prog;
        let first = match &*classes { List::Cons { head, .. } => head.clone(), _ => panic!("no classes") };
        let Class { body, .. } = &*first;
        let ClassDef::PARTS { classParts, .. } = &**body else { panic!("expected PARTS"); };
        let mut assigns: Vec<(Arc<Exp>, Arc<Exp>)> = Vec::new();
        for cp in &**classParts {
            if let ClassPart::ALGORITHMS { contents } = &**cp {
                for ai in &**contents {
                    if let AlgorithmItem::ALGORITHMITEM { algorithm_, .. } = &**ai
                        && let Algorithm::ALG_ASSIGN { assignComponent, value } = &**algorithm_
                    {
                        assigns.push((assignComponent.clone(), value.clone()));
                    }
                }
            }
        }
        assert_eq!(assigns.len(), 3, "expected three assignments");

        // a*(b + c): the right operand is a parenthesized BINARY.
        let Exp::BINARY { exp2, .. } = &*assigns[0].1 else { panic!("expected BINARY, got {:?}", assigns[0].1) };
        let Exp::TUPLE { expressions } = &**exp2 else { panic!("expected TUPLE wrapper, got {exp2:?}") };
        let List::Cons { head, tail } = &**expressions else { panic!("expected one element") };
        assert!(tail.is_empty(), "expected exactly one element, got {expressions:?}");
        assert!(matches!(&**head, Exp::BINARY { .. }), "expected inner BINARY, got {head:?}");

        // (u, v) := …: a real tuple LHS keeps both elements.
        let Exp::TUPLE { expressions } = &*assigns[1].0 else { panic!("expected TUPLE LHS, got {:?}", assigns[1].0) };
        assert_eq!(expressions.len(), 2, "expected a two-element tuple LHS");

        // (g(y))[1]: SUBSCRIPTED_EXP stores the bare expression; the dump
        // re-adds the parentheses for this node itself.
        let Exp::SUBSCRIPTED_EXP { exp, .. } = &*assigns[2].1 else { panic!("expected SUBSCRIPTED_EXP, got {:?}", assigns[2].1) };
        assert!(matches!(&**exp, Exp::CALL { .. }), "expected bare CALL inside SUBSCRIPTED_EXP, got {exp:?}");
    }

    #[test]
    fn expression_comment_backtracks_cleanly() {
        // `equality_or_noretcall_equation` does a speculative `simple_expression`
        // probe followed by `opt(Equal)`. If `expression`'s comment drain were
        // not undone on backtrack, the trailing `/* …` comment could land on
        // the wrong node depending on which alt branch wins. This test pins
        // down that the comment ends up on the EQUATIONITEM, not lost.
        let code = "\
package P\n\
equation\n\
  /* eq-comment */\n\
  x = 1;\n\
end P;\n\
";
        let prog = parse(code, "t.mo", "t.mo", Grammar::MetaModelica, false, 0.0).expect("parse");
        let Program { classes, .. } = prog;
        let first = match &*classes { List::Cons { head, .. } => head.clone(), _ => panic!("no classes") };
        let Class { body, .. } = &*first;
        let ClassDef::PARTS { classParts, .. } = &**body else { panic!("expected PARTS"); };
        let mut saw = false;
        for cp in &**classParts {
            if let ClassPart::EQUATIONS { contents } = &**cp {
                for eq in &**contents {
                    if let EquationItem::EQUATIONITEMCOMMENT { comment } = &**eq
                        && comment.contains("eq-comment")
                    {
                        saw = true;
                    }
                }
            }
        }
        assert!(saw, "expected the /* eq-comment */ to surface as an EQUATIONITEMCOMMENT");
    }

    #[test]
    fn parse_codegen_c() {
        let code = std::fs::read_to_string("tests/data/CodegenC.mo").expect("CodegenC.mo not found");
        if let Err(e) = parse(&code, "CodegenC.mo", "CodegenC.mo", Grammar::MetaModelica, false, 0.0) {
            panic!("expected CodegenC.mo to parse: {e}");
        }
    }

    // -----------------------------------------------------------------------
    // Interactive (.mos) entry points
    // -----------------------------------------------------------------------

    #[test]
    fn interactive_stmt_mos_script() {
        // The shape of a typical .mos script: expression statements separated
        // by semicolons, several on one line, with a trailing semicolon.
        let code = "loadFile(\"a.mo\");getErrorString();\nsimulate(M);getErrorString();\n";
        let stmts = parse_statements(code, "t.mos", "t.mos", Grammar::Modelica3, false, 0.0).expect("parse");
        assert!(stmts.semicolon, "script ends with ';' — results must not print");
        let items: Vec<_> = (&*stmts.interactiveStmtLst).into_iter().collect();
        assert_eq!(items.len(), 4);
        for item in &items {
            assert!(matches!(item, crate::GlobalScript::Statement::IEXP { .. }),
                    "function calls parse as IEXP, got {item:?}");
        }
        // First statement is the loadFile(...) call.
        let crate::GlobalScript::Statement::IEXP { exp, .. } = items[0] else { unreachable!() };
        assert!(matches!(&**exp, Exp::CALL { .. }));
    }

    #[test]
    fn interactive_stmt_no_trailing_semicolon() {
        let stmts = parse_statements("1 + 2", "t.mos", "t.mos", Grammar::Modelica3, false, 0.0).expect("parse");
        assert!(!stmts.semicolon, "no trailing ';' — result prints");
        assert_eq!((&*stmts.interactiveStmtLst).into_iter().count(), 1);
    }

    #[test]
    fn parse_builtin_files_metamodelica_grammar() {
        // FBuiltin.getInitialFunctions parses these with -g=MetaModelica at
        // startup; a parse failure there breaks every MetaModelica session.
        for f in ["ModelicaBuiltin.mo", "MetaModelicaBuiltin.mo", "NFModelicaBuiltin.mo"] {
            let path = format!("/projects/OpenModelica/build/lib/omc/{f}");
            let Ok(src) = std::fs::read_to_string(&path) else { continue };
            if let Err(e) = parse(&src, f, f, Grammar::MetaModelica, false, 0.0) {
                panic!("{f} failed to parse under MetaModelica grammar: {e}");
            }
        }
    }

    #[test]
    fn interactive_stmt_metamodelica_grammar() {
        // .mos scripts must also parse under -g=MetaModelica (used by the
        // metamodelica testsuite); statements must not silently vanish.
        let code = "loadFile(\"a.mo\");\ngetErrorString();\n";
        let stmts = parse_statements(code, "t.mos", "t.mos", Grammar::MetaModelica, false, 0.0).expect("parse");
        assert!(stmts.semicolon);
        assert_eq!((&*stmts.interactiveStmtLst).into_iter().count(), 2);
    }

    #[test]
    fn interactive_stmt_assignment() {
        // `x := f(1)` must fail the expression predicate (next token is `:=`)
        // and land in the assignment clause as IALG.
        let stmts = parse_statements("x := f(1);", "t.mos", "t.mos", Grammar::Modelica3, false, 0.0).expect("parse");
        let items: Vec<_> = (&*stmts.interactiveStmtLst).into_iter().collect();
        assert_eq!(items.len(), 1);
        let crate::GlobalScript::Statement::IALG { algItem } = items[0] else {
            panic!("expected IALG, got {:?}", items[0]);
        };
        let AlgorithmItem::ALGORITHMITEM { algorithm_, .. } = &**algItem else {
            panic!("expected ALGORITHMITEM");
        };
        assert!(matches!(&**algorithm_, Algorithm::ALG_ASSIGN { .. }));
    }

    #[test]
    fn interactive_stmt_for_loop() {
        let stmts = parse_statements("for i in 1:10 loop x := i; end for;", "t.mos", "t.mos", Grammar::Modelica3, false, 0.0)
            .expect("parse");
        let items: Vec<_> = (&*stmts.interactiveStmtLst).into_iter().collect();
        assert_eq!(items.len(), 1);
        let crate::GlobalScript::Statement::IALG { algItem } = items[0] else {
            panic!("expected IALG, got {:?}", items[0]);
        };
        let AlgorithmItem::ALGORITHMITEM { algorithm_, .. } = &**algItem else {
            panic!("expected ALGORITHMITEM");
        };
        assert!(matches!(&**algorithm_, Algorithm::ALG_FOR { .. }));
    }

    #[test]
    fn interactive_stmt_rejects_trailing_junk() {
        assert!(parse_statements("foo() end", "t.mos", "t.mos", Grammar::Modelica3, false, 0.0).is_err());
    }

    #[test]
    fn interactive_stmt_empty_input_is_empty_list() {
        // More lenient than ANTLR (which requires at least one statement):
        // a script of only comments yields an empty statement list.
        let stmts = parse_statements("// nothing here\n", "t.mos", "t.mos", Grammar::Modelica3, false, 0.0).expect("parse");
        assert!(matches!(&*stmts.interactiveStmtLst, List::Nil));
        assert!(!stmts.semicolon);
    }

    #[test]
    fn string_path_entry_point() {
        let path = parse_path("Modelica.Blocks.Sources", "<internal>", Grammar::Modelica3).expect("parse");
        let Path::QUALIFIED { name, .. } = &path else { panic!("expected QUALIFIED, got {path:?}") };
        assert_eq!(&**name, "Modelica");
        // Trailing junk must be rejected.
        assert!(parse_path("A.B C", "<internal>", Grammar::Modelica3).is_err());
    }

    #[test]
    fn string_cref_entry_point() {
        let cref = parse_cref("a.b[1].c", "<internal>", Grammar::Modelica3).expect("parse");
        assert!(matches!(cref, ComponentRef::CREF_QUAL { .. }));
    }

    #[test]
    fn string_mod_entry_point() {
        let m = parse_modification("x(start = 1.0)", "<internal>", Grammar::Modelica3).expect("parse");
        let ElementArg::MODIFICATION { finalPrefix, eachPrefix, .. } = &m else {
            panic!("expected MODIFICATION, got {m:?}");
        };
        assert!(!finalPrefix);
        assert!(matches!(eachPrefix, Each::NON_EACH {}));
        // each/final prefixes are threaded into the node.
        let m = parse_modification("each final x = 2", "<internal>", Grammar::Modelica3).expect("parse");
        let ElementArg::MODIFICATION { finalPrefix, eachPrefix, .. } = &m else {
            panic!("expected MODIFICATION, got {m:?}");
        };
        assert!(finalPrefix);
        assert!(matches!(eachPrefix, Each::EACH {}));
    }

    #[test]
    fn string_eq_entry_point() {
        let eq = parse_equation("x = y + 1", "<internal>", Grammar::Modelica3).expect("parse");
        let EquationItem::EQUATIONITEM { equation_, .. } = &eq else {
            panic!("expected EQUATIONITEM, got {eq:?}");
        };
        assert!(matches!(&**equation_, Equation::EQ_EQUALS { .. }));
    }
}
