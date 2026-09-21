//! `--fix`: rewrite each `matchcontinue` the fallibility analysis proved
//! equivalent to a plain `match` (all arms infallible — see
//! [`crate::fallibility`]) into a `match` in the MetaModelica source.
//!
//! The analysis only hands us the *first arm's* `Info` (file + line/col), not
//! the `matchcontinue`/`end matchcontinue` keyword positions, so this module
//! re-scans each `.mo` file with a small comment/string-aware lexer, pairs
//! every `matchcontinue`…`end matchcontinue` (and `match`…`end match`) by
//! nesting, finds the region that directly encloses each flagged first-arm
//! position, and rewrites both keywords (`matchcontinue` → `match`,
//! `end matchcontinue` → `end match`). Both rewrites are the same token
//! edit: a 13-byte `matchcontinue` becomes the 5-byte `match`.
//!
//! Some of those `matchcontinue`s first need their arms' leading
//! `true := COND;` statements turned into `guard COND` (see
//! [`crate::fallibility::GuardHoist`]) — the same fall-through, expressed as
//! part of the pattern so `match` performs it too. `COND` is taken verbatim from
//! the statement's own source span rather than unparsed from the AST, so the
//! rewrite preserves the author's formatting.
//!
//! Every edit is sanity-checked against the source bytes before being applied;
//! if a file's `match`/`matchcontinue` nesting does not balance (a lexer/source
//! surprise) the whole file is left untouched and a warning is printed, so a
//! `--fix` run can never silently corrupt a source file.

use std::collections::BTreeMap;

use openmodelica_ast::Absyn;

use crate::fallibility::GuardHoist;

/// Keyword token kinds the rewriter tracks. Openers are `match`/`matchcontinue`;
/// closers are the `match`/`matchcontinue` word of an `end match`/
/// `end matchcontinue`.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum Kw {
    MatchOpen,
    McOpen,
    MatchEnd,
    McEnd,
}

/// One keyword occurrence. `byte`/`line`/`col` point at the `match` /
/// `matchcontinue` *word* (for a closer, the word after `end`), so a closer's
/// `byte` is exactly the token to rewrite.
#[derive(Clone, Copy)]
struct KwTok {
    kw: Kw,
    line: i32,
    col: i32,
    byte: usize,
}

/// A matched `match`…`end match` or `matchcontinue`…`end matchcontinue` pair.
struct Region {
    open_kw: Kw,
    open_line: i32,
    open_col: i32,
    open_byte: usize,
    close_line: i32,
    close_col: i32,
    close_byte: usize,
}

const MATCHCONTINUE: &str = "matchcontinue";
const MATCH: &str = "match";

fn is_ident_start(c: u8) -> bool {
    c.is_ascii_alphabetic() || c == b'_'
}
fn is_ident_cont(c: u8) -> bool {
    c.is_ascii_alphanumeric() || c == b'_'
}

/// Lex `src` into the ordered `match`/`matchcontinue`/`end match`/
/// `end matchcontinue` keyword tokens, skipping `//` and `/* */` comments,
/// `"…"` strings and `'…'` quoted identifiers. A `match`/`matchcontinue` word
/// is classified as a closer iff the immediately preceding identifier was
/// `end` (the only MetaModelica spelling that puts `end` before them).
fn scan_keywords(src: &str) -> Vec<KwTok> {
    let b = src.as_bytes();
    let mut toks = Vec::new();
    let mut i = 0usize;
    let mut line = 1i32;
    let mut col = 1i32;
    // Last identifier seen, to recognise `end match` / `end matchcontinue`.
    let mut prev_ident_is_end = false;

    // Advance one byte, maintaining line/col.
    macro_rules! bump {
        () => {{
            if b[i] == b'\n' {
                line += 1;
                col = 1;
            } else {
                col += 1;
            }
            i += 1;
        }};
    }

    while i < b.len() {
        let c = b[i];
        // Comments and quotes.
        if c == b'/' && i + 1 < b.len() && b[i + 1] == b'/' {
            while i < b.len() && b[i] != b'\n' {
                bump!();
            }
            continue;
        }
        if c == b'/' && i + 1 < b.len() && b[i + 1] == b'*' {
            bump!();
            bump!();
            while i + 1 < b.len() && !(b[i] == b'*' && b[i + 1] == b'/') {
                bump!();
            }
            if i + 1 < b.len() {
                bump!();
                bump!();
            }
            continue;
        }
        if c == b'"' {
            bump!();
            while i < b.len() && b[i] != b'"' {
                if b[i] == b'\\' && i + 1 < b.len() {
                    bump!();
                }
                bump!();
            }
            if i < b.len() {
                bump!();
            }
            prev_ident_is_end = false;
            continue;
        }
        if c == b'\'' {
            // Modelica quoted identifier: 'foo bar'. Skip its content; it is an
            // identifier, never the `match`/`matchcontinue`/`end` keyword.
            bump!();
            while i < b.len() && b[i] != b'\'' {
                if b[i] == b'\\' && i + 1 < b.len() {
                    bump!();
                }
                bump!();
            }
            if i < b.len() {
                bump!();
            }
            prev_ident_is_end = false;
            continue;
        }
        if is_ident_start(c) {
            let start = i;
            let start_line = line;
            let start_col = col;
            while i < b.len() && is_ident_cont(b[i]) {
                bump!();
            }
            let word = &src[start..i];
            match word {
                MATCH => {
                    let kw = if prev_ident_is_end { Kw::MatchEnd } else { Kw::MatchOpen };
                    toks.push(KwTok { kw, line: start_line, col: start_col, byte: start });
                }
                MATCHCONTINUE => {
                    let kw = if prev_ident_is_end { Kw::McEnd } else { Kw::McOpen };
                    toks.push(KwTok { kw, line: start_line, col: start_col, byte: start });
                }
                _ => {}
            }
            prev_ident_is_end = word == "end";
            continue;
        }
        bump!();
    }
    toks
}

/// Pair openers and closers by nesting. Returns `Err` if the file does not
/// balance (then the caller leaves the file untouched).
fn build_regions(toks: &[KwTok]) -> Result<Vec<Region>, String> {
    let mut stack: Vec<KwTok> = Vec::new();
    let mut regions = Vec::new();
    for t in toks {
        match t.kw {
            Kw::MatchOpen | Kw::McOpen => stack.push(*t),
            Kw::MatchEnd | Kw::McEnd => {
                let open = stack.pop().ok_or_else(|| {
                    format!("unbalanced `end match`/`end matchcontinue` at {}:{}", t.line, t.col)
                })?;
                let expected = if t.kw == Kw::MatchEnd { Kw::MatchOpen } else { Kw::McOpen };
                if open.kw != expected {
                    return Err(format!(
                        "`end {}` at {}:{} closes a `{}` opened at {}:{}",
                        if t.kw == Kw::MatchEnd { "match" } else { "matchcontinue" },
                        t.line, t.col,
                        if open.kw == Kw::MatchOpen { "match" } else { "matchcontinue" },
                        open.line, open.col,
                    ));
                }
                regions.push(Region {
                    open_kw: open.kw,
                    open_line: open.line,
                    open_col: open.col,
                    open_byte: open.byte,
                    close_line: t.line,
                    close_col: t.col,
                    close_byte: t.byte,
                });
            }
        }
    }
    if !stack.is_empty() {
        let o = stack.last().unwrap();
        return Err(format!("unclosed `match`/`matchcontinue` opened at {}:{}", o.line, o.col));
    }
    Ok(regions)
}

/// The `matchcontinue` region that directly encloses position `(line, col)` —
/// the innermost `McOpen` region containing it (largest opener position that is
/// still `<=` the anchor and whose closer is `>=` the anchor).
fn enclosing_mc<'a>(regions: &'a [Region], line: i32, col: i32) -> Option<&'a Region> {
    regions
        .iter()
        .filter(|r| r.open_kw == Kw::McOpen)
        .filter(|r| {
            (r.open_line, r.open_col) <= (line, col) && (line, col) <= (r.close_line, r.close_col)
        })
        .max_by_key(|r| (r.open_line, r.open_col))
}

/// Outcome of a `--fix` run.
#[derive(Default)]
pub struct FixStats {
    pub files_changed: usize,
    pub rewritten: usize,
    pub skipped: usize,
}

/// Rewrite every flagged `matchcontinue` (given as its first arm's `Info`) to a
/// plain `match` in its `.mo` source. Files are read, edited and written once;
/// a file whose nesting does not balance is left untouched.
pub fn apply_match_fixes(
    locs: &[Absyn::Info],
    hoists: &[Vec<GuardHoist>],
) -> std::io::Result<FixStats> {
    // Group anchors by source file.
    let mut by_file: BTreeMap<String, Vec<(i32, i32, &[GuardHoist])>> = BTreeMap::new();
    for (i, info) in locs.iter().enumerate() {
        by_file
            .entry(info.fileName.to_string())
            .or_default()
            .push((info.lineNumberStart, info.columnNumberStart,
                   hoists.get(i).map(|v| &v[..]).unwrap_or(&[])));
    }

    let mut stats = FixStats::default();
    for (file, anchors) in &by_file {
        let src = std::fs::read_to_string(file)?;
        let toks = scan_keywords(&src);
        let regions = match build_regions(&toks) {
            Ok(r) => r,
            Err(e) => {
                eprintln!("[mmtorust --fix] skipping {file}: {e}");
                stats.skipped += anchors.len();
                continue;
            }
        };

        let lines = LineIndex::new(&src);

        // Collect every byte-range replacement for this file: the two
        // `matchcontinue` keywords per flagged expression, plus the guard
        // hoists (an insertion after a pattern, a deletion per statement).
        let mut edits: Vec<(usize, usize, String)> = Vec::new();
        let mut rewritten = 0;
        for &(line, col, hoists) in anchors {
            let Some(r) = enclosing_mc(&regions, line, col) else {
                eprintln!("[mmtorust --fix] {file}:{line}:{col}: no enclosing matchcontinue found; skipped");
                stats.skipped += 1;
                continue;
            };
            // Verify both tokens really are `matchcontinue` before touching the
            // file, so a position/lexer surprise can never corrupt the source.
            let ok = |off: usize| src.get(off..off + MATCHCONTINUE.len()) == Some(MATCHCONTINUE);
            if !ok(r.open_byte) || !ok(r.close_byte) {
                eprintln!("[mmtorust --fix] {file}:{line}:{col}: expected `matchcontinue` keywords not found at the resolved span; skipped");
                stats.skipped += 1;
                continue;
            }
            let guard_edits = match guard_edits(&src, &lines, hoists) {
                Ok(e) => e,
                Err(e) => {
                    eprintln!("[mmtorust --fix] {file}:{line}:{col}: {e}; skipped");
                    stats.skipped += 1;
                    continue;
                }
            };
            edits.push((r.open_byte, r.open_byte + MATCHCONTINUE.len(), MATCH.to_owned()));
            edits.push((r.close_byte, r.close_byte + MATCHCONTINUE.len(), MATCH.to_owned()));
            edits.extend(guard_edits);
            rewritten += 1;
        }
        if edits.is_empty() {
            continue;
        }
        edits.sort_unstable_by_key(|e| e.0);
        edits.dedup();

        // Apply from the end so earlier offsets stay valid.
        let mut out = src.clone();
        for (start, end, text) in edits.iter().rev() {
            out.replace_range(*start..*end, text);
        }
        std::fs::write(file, out)?;
        stats.files_changed += 1;
        stats.rewritten += rewritten;
    }
    Ok(stats)
}

/// Byte offsets of each line start, for turning a `SourceInfo`'s 1-based
/// line/column into a byte offset.
struct LineIndex {
    starts: Vec<usize>,
}

impl LineIndex {
    fn new(src: &str) -> Self {
        let mut starts = vec![0usize];
        starts.extend(src.match_indices('\n').map(|(i, _)| i + 1));
        LineIndex { starts }
    }

    /// Offset of the character at 1-based `line`/`col`.
    fn offset(&self, line: i32, col: i32) -> Option<usize> {
        let start = *self.starts.get((line as usize).checked_sub(1)?)?;
        Some(start + (col as usize).checked_sub(1)?)
    }
}

/// Turn one flagged `matchcontinue`'s [`GuardHoist`]s into byte-range edits:
/// the `guard` insertion after each arm's pattern, and the deletion of the
/// `true := COND;` statements it came from.
fn guard_edits(
    src: &str,
    lines: &LineIndex,
    hoists: &[GuardHoist],
) -> Result<Vec<(usize, usize, String)>, String> {
    let mut edits = Vec::new();
    for h in hoists {
        let mut conds: Vec<String> = Vec::new();
        for (info, asserted) in &h.stmts {
            let start = lines.offset(info.lineNumberStart, info.columnNumberStart)
                .ok_or("statement start out of range")?;
            // `columnNumberEnd` addresses the statement's last character.
            let end = lines.offset(info.lineNumberEnd, info.columnNumberEnd)
                .map(|o| o + 1)
                .filter(|o| *o <= src.len())
                .ok_or("statement end out of range")?;
            let stmt = src.get(start..end).ok_or("statement span is not a char boundary")?;
            let cond = stmt
                .strip_suffix(';').unwrap_or(stmt)
                .split_once(":=").ok_or_else(|| format!("not an assignment: {stmt:?}"))?
                .1.trim();
            if cond.is_empty() {
                return Err(format!("empty condition in {stmt:?}"));
            }
            // A `//` comment inside the condition would swallow the rest of the
            // line once the text moves onto the `case` line.
            if cond.contains("//") || cond.contains("/*") {
                return Err(format!("condition carries a comment: {cond:?}"));
            }
            // `not` binds tighter than `and`, and a lone condition needs no
            // bracket at all, so parenthesise only what would otherwise regroup.
            let bracketed = if is_atom(cond) { cond.to_owned() } else { format!("({cond})") };
            conds.push(if *asserted {
                if h.stmts.len() == 1 { cond.to_owned() } else { bracketed }
            } else {
                format!("not {bracketed}")
            });
            // Swallow the rest of the line when the statement is alone on it, so
            // deleting it does not leave a blank line behind.
            let mut cut = end;
            while src.as_bytes().get(cut) == Some(&b' ') || src.as_bytes().get(cut) == Some(&b'\t') {
                cut += 1;
            }
            if src.as_bytes().get(cut) == Some(&b'\n') {
                let mut line_start = start;
                while line_start > 0 && src.as_bytes()[line_start - 1] != b'\n' {
                    line_start -= 1;
                }
                if src[line_start..start].trim().is_empty() {
                    edits.push((line_start, cut + 1, String::new()));
                    continue;
                }
            }
            edits.push((start, cut, String::new()));
        }
        // A `SourceInfo`'s end column addresses the token *after* the span, so
        // back up over the whitespace to land right behind the pattern text.
        let after = lines.offset(h.pattern_info.lineNumberEnd, h.pattern_info.columnNumberEnd)
            .filter(|o| *o <= src.len())
            .ok_or("pattern end out of range")?;
        let mut at = after;
        while at > 0 && src.as_bytes()[at - 1].is_ascii_whitespace() {
            at -= 1;
        }
        // Landing behind a comment would bury the guard inside it.
        let line_start = src[..at].rfind('\n').map_or(0, |i| i + 1);
        if src[line_start..at].contains("//") || src[..at].ends_with("*/") {
            return Err("pattern is followed by a comment".to_owned());
        }
        let mut guard = (at, at, format!(" guard {}", conds.join(" and ")));
        if h.drops_section {
            // Every statement went into the guard; drop the now-empty
            // `algorithm` keyword (and its line, if it has one to itself).
            let rest = src.get(after..).ok_or("pattern end is not a char boundary")?;
            let off = after + rest.find("algorithm").ok_or("no `algorithm` keyword after the pattern")?;
            let mut end = off + "algorithm".len();
            while matches!(src.as_bytes().get(end), Some(b' ' | b'\t')) {
                end += 1;
            }
            let kw_line_start = src[..off].rfind('\n').map_or(0, |i| i + 1);
            if src.as_bytes().get(end) == Some(&b'\n') && src[kw_line_start..off].trim().is_empty() {
                edits.push((kw_line_start, end + 1, String::new()));
            } else {
                // The keyword shares the pattern's line: fold it into the guard
                // insertion, which also eats the space that preceded it.
                guard.1 = end;
            }
        }
        edits.push(guard);
    }
    Ok(edits)
}

/// Does `cond` bind tightly enough to sit under `not` / beside `and` unbracketed?
/// True for a name, a literal, a parenthesised expression, and a single call —
/// anything whose text cannot be regrouped by a surrounding operator.
fn is_atom(cond: &str) -> bool {
    let b = cond.as_bytes();
    let mut i = 0;
    if b.first().is_some_and(|c| c.is_ascii_digit() || *c == b'"') {
        // A number or string literal, provided it is the whole condition.
        return !cond[1..].contains(|c: char| c.is_whitespace());
    }
    if b.first().is_some_and(|c| is_ident_start(*c)) {
        while i < b.len() && (is_ident_cont(b[i]) || b[i] == b'.') {
            i += 1;
        }
        if i == b.len() {
            return true;
        }
    } else if b.first() != Some(&b'(') {
        return false;
    }
    // A trailing (or leading) parenthesised group must close exactly at the end.
    if b.get(i) != Some(&b'(') {
        return false;
    }
    let mut depth = 0usize;
    let mut in_str = false;
    while i < b.len() {
        match b[i] {
            b'"' if !in_str => in_str = true,
            b'"' => in_str = false,
            b'\\' if in_str => i += 1,
            b'(' if !in_str => depth += 1,
            b')' if !in_str => {
                depth -= 1;
                if depth == 0 {
                    return i + 1 == b.len();
                }
            }
            _ => {}
        }
        i += 1;
    }
    false
}
