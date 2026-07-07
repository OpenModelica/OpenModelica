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
//! Every edit is sanity-checked against the source bytes before being applied;
//! if a file's `match`/`matchcontinue` nesting does not balance (a lexer/source
//! surprise) the whole file is left untouched and a warning is printed, so a
//! `--fix` run can never silently corrupt a source file.

use std::collections::BTreeMap;

use openmodelica_ast::Absyn;

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
pub fn apply_match_fixes(locs: &[Absyn::Info]) -> std::io::Result<FixStats> {
    // Group anchors by source file.
    let mut by_file: BTreeMap<String, Vec<(i32, i32)>> = BTreeMap::new();
    for info in locs {
        by_file
            .entry(info.fileName.to_string())
            .or_default()
            .push((info.lineNumberStart, info.columnNumberStart));
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

        // Collect the byte offsets of the `matchcontinue` tokens to rewrite
        // (opener + matching `end matchcontinue`), deduplicated.
        let mut edits: Vec<usize> = Vec::new();
        for &(line, col) in anchors {
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
            edits.push(r.open_byte);
            edits.push(r.close_byte);
        }
        if edits.is_empty() {
            continue;
        }
        edits.sort_unstable();
        edits.dedup();

        // Apply from the end so earlier offsets stay valid.
        let mut out = src.clone();
        for &off in edits.iter().rev() {
            out.replace_range(off..off + MATCHCONTINUE.len(), MATCH);
        }
        std::fs::write(file, out)?;
        stats.files_changed += 1;
        stats.rewritten += edits.len() / 2;
    }
    Ok(stats)
}
