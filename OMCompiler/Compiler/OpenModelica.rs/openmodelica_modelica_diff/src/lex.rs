//! A lossless Modelica lexer: every byte of the text belongs to a token.

use std::cell::OnceCell;
use std::collections::HashMap;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Kind {
    Newline,
    Space,
    LineComment,
    BlockComment,
    Str,
    QIdent,
    Int,
    Real,
    Ident,
    Op,
}

impl Kind {
    pub fn is_trivia(self) -> bool {
        matches!(
            self,
            Kind::Newline | Kind::Space | Kind::LineComment | Kind::BlockComment
        )
    }

    pub fn is_comment(self) -> bool {
        matches!(self, Kind::LineComment | Kind::BlockComment)
    }
}

#[derive(Clone, Copy, Debug)]
pub struct Token {
    pub kind: Kind,
    pub start: usize,
    pub end: usize,
}

pub fn lex(text: &str) -> Vec<Token> {
    let b = text.as_bytes();
    let n = b.len();
    let mut toks = Vec::with_capacity(n / 4 + 1);
    let mut i = 0;
    while i < n {
        let start = i;
        let c = b[i];
        let kind = match c {
            b'\n' => {
                i += 1;
                Kind::Newline
            }
            b' ' | b'\t' | b'\r' | 0x0b | 0x0c => {
                while i < n && matches!(b[i], b' ' | b'\t' | b'\r' | 0x0b | 0x0c) {
                    i += 1;
                }
                Kind::Space
            }
            b'/' if b.get(i + 1) == Some(&b'/') => {
                while i < n && b[i] != b'\n' {
                    i += 1;
                }
                Kind::LineComment
            }
            b'/' if b.get(i + 1) == Some(&b'*') => {
                i = b[i + 2..]
                    .windows(2)
                    .position(|w| w == b"*/")
                    .map_or(n, |p| i + 2 + p + 2);
                Kind::BlockComment
            }
            b'"' => {
                i = skip_quoted(b, i);
                Kind::Str
            }
            b'\'' => {
                i = skip_quoted(b, i);
                Kind::QIdent
            }
            b'0'..=b'9' => number(b, &mut i),
            b'A'..=b'Z' | b'a'..=b'z' | b'_' => {
                while i < n && (b[i].is_ascii_alphanumeric() || b[i] == b'_') {
                    i += 1;
                }
                Kind::Ident
            }
            0x80.. => {
                i += 1;
                while i < n && (b[i] & 0xc0) == 0x80 {
                    i += 1;
                }
                Kind::Op
            }
            _ => {
                let two = matches!(
                    (c, b.get(i + 1)),
                    (b'.', Some(b'+' | b'-' | b'*' | b'/' | b'^'))
                        | (b'=' | b'<' | b'>' | b':', Some(b'='))
                        | (b'<', Some(b'>'))
                );
                i += if two { 2 } else { 1 };
                Kind::Op
            }
        };
        toks.push(Token { kind, start, end: i });
    }
    toks
}

fn skip_quoted(b: &[u8], start: usize) -> usize {
    let q = b[start];
    let mut j = start + 1;
    while j < b.len() {
        match b[j] {
            b'\\' => j += 2,
            c if c == q => return j + 1,
            _ => j += 1,
        }
    }
    b.len()
}

fn number(b: &[u8], i: &mut usize) -> Kind {
    let n = b.len();
    let mut real = false;
    while *i < n && b[*i].is_ascii_digit() {
        *i += 1;
    }
    // The longest match: `2.*x` is 2. * x
    if *i < n && b[*i] == b'.' {
        real = true;
        *i += 1;
        while *i < n && b[*i].is_ascii_digit() {
            *i += 1;
        }
    }
    if *i < n && (b[*i] == b'e' || b[*i] == b'E') {
        let mut j = *i + 1;
        if j < n && (b[j] == b'+' || b[j] == b'-') {
            j += 1;
        }
        if j < n && b[j].is_ascii_digit() {
            while j < n && b[j].is_ascii_digit() {
                j += 1;
            }
            *i = j;
            real = true;
        }
    }
    if real { Kind::Real } else { Kind::Int }
}

/// The value a significant token is compared by: numbers by value, multi-line
/// strings by their lines, everything else by text.
enum Norm<'a> {
    Int(&'a str),
    Real(f64),
    Lines(&'a str),
    Text(Kind, &'a str),
}

fn norm(kind: Kind, text: &str) -> Norm<'_> {
    match kind {
        Kind::Int => Norm::Int(text.trim_start_matches('0')),
        Kind::Real => match text.parse::<f64>() {
            Ok(v) => Norm::Real(v),
            Err(_) => Norm::Text(kind, text),
        },
        Kind::Str if text.contains('\n') => Norm::Lines(text),
        _ => Norm::Text(kind, text),
    }
}

/// A fast 64-bit hash. A collision can only make the merge lose formatting:
/// omc checks the code of the result with exact comparisons.
pub fn hash(seed: u64, b: &[u8]) -> u64 {
    let mut h = seed ^ (b.len() as u64).wrapping_mul(0x9e37_79b9_7f4a_7c15);
    for chunk in b.chunks(8) {
        let mut w = [0u8; 8];
        w[..chunk.len()].copy_from_slice(chunk);
        h = (h ^ u64::from_le_bytes(w)).wrapping_mul(0xbf58_476d_1ce4_e5b9);
        h ^= h >> 31;
    }
    h = (h ^ (h >> 30)).wrapping_mul(0xbf58_476d_1ce4_e5b9);
    h = (h ^ (h >> 27)).wrapping_mul(0x94d0_49bb_1331_11eb);
    h ^ (h >> 31)
}

/// The lines of a multi-line string without the indentation the lines after
/// the first have in common: omc's printer shifts them all when it indents.
fn dedented(s: &str) -> impl Iterator<Item = &str> {
    let n = s
        .split('\n')
        .skip(1)
        .filter(|l| !l.trim().is_empty())
        .map(|l| l.len() - l.trim_start_matches([' ', '\t']).len())
        .min()
        .unwrap_or(0);
    s.split('\n').enumerate().map(move |(i, l)| match i {
        0 => l,
        _ if l.trim().is_empty() => "",
        _ => &l[n..],
    })
}

/// `exact` keys compare multi-line strings by their dedented lines, the others
/// by their trimmed lines, which also matches what the printer re-indented
/// in other ways.
fn key(kind: Kind, text: &str, exact: bool) -> u64 {
    match norm(kind, text) {
        Norm::Int(s) => hash(1, s.as_bytes()),
        Norm::Real(v) => hash(2, &v.to_bits().to_le_bytes()),
        Norm::Lines(s) if exact => dedented(s).fold(3, |h, l| hash(h, l.as_bytes())),
        Norm::Lines(s) => s.split('\n').fold(4, |h, l| hash(h, l.trim().as_bytes())),
        Norm::Text(k, s) => hash(16 + k as u64, s.as_bytes()),
    }
}

pub fn same(ka: Kind, a: &str, kb: Kind, b: &str) -> bool {
    if ka == kb && a == b {
        return true;
    }
    match (norm(ka, a), norm(kb, b)) {
        (Norm::Int(x), Norm::Int(y)) => x == y,
        (Norm::Real(x), Norm::Real(y)) => x == y,
        (Norm::Lines(x), Norm::Lines(y)) => dedented(x).eq(dedented(y)),
        (Norm::Text(kx, x), Norm::Text(ky, y)) => kx == ky && x == y,
        _ => false,
    }
}

/// Number of tokens of a leading `within ...;` clause.
pub fn within_len(sig: &[Token], text: &str) -> usize {
    let t = |k: usize| &text[sig[k].start..sig[k].end];
    if !sig.is_empty() && t(0) == "within" {
        (0..sig.len()).find(|&k| t(k) == ";").map_or(0, |k| k + 1)
    } else {
        0
    }
}

pub const NONE: usize = usize::MAX;

pub struct Doc<'a> {
    pub text: &'a str,
    pub sig: Vec<Token>,
    pub comments: Vec<Token>,
    /// Keys for the alignment of `before` with its listing.
    pub keys: Vec<u64>,
    /// Keys for the diff of two listings, which keeps whitespace edits in strings.
    pub dkeys: Vec<u64>,
    /// Index in `sig` of the innermost open bracket around each token, or NONE.
    pub encl: Vec<usize>,
    line_starts: Vec<usize>,
    commas: OnceCell<HashMap<usize, Vec<usize>>>,
}

impl<'a> Doc<'a> {
    pub fn new(text: &'a str) -> Self {
        let mut sig = Vec::new();
        let mut comments = Vec::new();
        for t in lex(text) {
            if t.kind.is_comment() {
                comments.push(t);
            } else if !t.kind.is_trivia() {
                sig.push(t);
            }
        }
        let keys = sig.iter().map(|t| key(t.kind, &text[t.start..t.end], false)).collect();
        let dkeys = sig.iter().map(|t| key(t.kind, &text[t.start..t.end], true)).collect();
        let mut line_starts = vec![0];
        line_starts.extend(
            text.bytes()
                .enumerate()
                .filter(|&(_, c)| c == b'\n')
                .map(|(p, _)| p + 1),
        );
        let mut doc = Doc {
            text,
            sig,
            comments,
            keys,
            dkeys,
            encl: Vec::new(),
            line_starts,
            commas: OnceCell::new(),
        };
        doc.encl = doc.enclosing();
        doc
    }

    /// The line of each significant token.
    pub fn sig_lines(&self) -> Vec<usize> {
        let mut line = 0;
        self.sig
            .iter()
            .map(|t| {
                while line + 1 < self.line_starts.len() && self.line_starts[line + 1] <= t.start {
                    line += 1;
                }
                line
            })
            .collect()
    }

    fn enclosing(&self) -> Vec<usize> {
        let mut stack = Vec::new();
        let mut encl = Vec::with_capacity(self.sig.len());
        for k in 0..self.sig.len() {
            let t = self.st(k);
            if matches!(t, ")" | "}" | "]") {
                stack.pop();
            }
            encl.push(stack.last().copied().unwrap_or(NONE));
            if matches!(t, "(" | "{" | "[") {
                stack.push(k);
            }
        }
        encl
    }

    /// The commas of each bracket, by the index of its open bracket.
    pub fn commas(&self) -> &HashMap<usize, Vec<usize>> {
        self.commas.get_or_init(|| {
            let mut m: HashMap<usize, Vec<usize>> = HashMap::new();
            for k in 0..self.sig.len() {
                if self.st(k) == "," && self.encl[k] != NONE {
                    m.entry(self.encl[k]).or_default().push(k);
                }
            }
            m
        })
    }

    pub fn s(&self, t: &Token) -> &'a str {
        &self.text[t.start..t.end]
    }

    /// Text of significant token k.
    pub fn st(&self, k: usize) -> &'a str {
        self.s(&self.sig[k])
    }

    pub fn line_of(&self, off: usize) -> usize {
        self.line_starts.partition_point(|&s| s <= off) - 1
    }

    pub fn line_start(&self, off: usize) -> usize {
        self.line_starts[self.line_of(off)]
    }

    pub fn line_start_of(&self, line: usize) -> usize {
        self.line_starts[line]
    }

    /// Offset of the newline that ends the line of `off`, or the text length.
    pub fn line_end(&self, off: usize) -> usize {
        self.text[off..].find('\n').map_or(self.text.len(), |p| off + p)
    }

    pub fn line_text(&self, line: usize) -> &'a str {
        let s = self.line_starts[line];
        &self.text[s..self.line_end(s)]
    }

    pub fn indent(&self, off: usize) -> &'a str {
        let rest = &self.text[self.line_start(off)..];
        &rest[..rest.len() - rest.trim_start_matches([' ', '\t']).len()]
    }

    pub fn first_on_line(&self, k: usize) -> bool {
        let t = self.sig[k];
        self.text[self.line_start(t.start)..t.start].trim().is_empty()
    }

    /// The end of token k with the comments that start on its line after it.
    pub fn trail_end(&self, k: usize) -> usize {
        let end = self.sig[k].end;
        let le = self.line_end(end);
        let from = self.comments.partition_point(|c| c.start < end);
        self.comments[from..]
            .iter()
            .take_while(|c| c.start < le)
            .map(|c| c.end)
            .fold(end, usize::max)
    }

    /// No code follows token k on its line, nor on the line where its trailing comments end.
    pub fn last_on_line(&self, k: usize) -> bool {
        let le = self.line_end(self.trail_end(k));
        self.sig.get(k + 1).is_none_or(|t| t.start > le)
    }

    /// Whether a significant token starts on the line.
    pub fn has_code(&self, line: usize) -> bool {
        let s = self.line_starts[line];
        let k = self.sig.partition_point(|t| t.start < s);
        self.sig.get(k).is_some_and(|t| t.start < self.line_end(s))
    }

    /// The trivia before significant token k (k may be `sig.len()`).
    pub fn gap(&self, k: usize) -> (usize, usize) {
        let s = if k > 0 { self.sig[k - 1].end } else { 0 };
        let e = self.sig.get(k).map_or(self.text.len(), |t| t.start);
        (s, e)
    }

    pub fn within_len(&self) -> usize {
        within_len(&self.sig, self.text)
    }
}

/// Comments are equal when their lines are, ignoring indentation.
pub fn comment_key(doc: &Doc, t: &Token) -> String {
    let s = doc.s(t);
    if t.kind == Kind::BlockComment {
        s.split('\n').map(str::trim).collect::<Vec<_>>().join("\n")
    } else {
        s.trim_end().to_owned()
    }
}

/// Re-indents the lines after the first: an indentation that starts with
/// `from` gets `to` instead. Lines inside strings and comments are not touched.
pub fn reindent(text: &str, from: &str, to: &str) -> String {
    if from == to || !text.contains('\n') {
        return text.to_owned();
    }
    let toks = lex(text);
    let mut out = String::with_capacity(text.len() + 16);
    let mut k = 0;
    while k < toks.len() {
        let t = toks[k];
        out.push_str(&text[t.start..t.end]);
        k += 1;
        if t.kind != Kind::Newline {
            continue;
        }
        let ind = match toks.get(k) {
            Some(s) if s.kind == Kind::Space => {
                k += 1;
                &text[s.start..s.end]
            }
            _ => "",
        };
        if matches!(
            toks.get(k),
            None | Some(Token {
                kind: Kind::Newline,
                ..
            })
        ) {
            continue;
        }
        out.push_str(&shift(ind, from, to));
    }
    out
}

/// `ind` with its first `from.len()` characters replaced by `to`; a shorter
/// `ind` loses as much of `to`. Indentation is ASCII.
pub fn shift(ind: &str, from: &str, to: &str) -> String {
    if ind.len() >= from.len() {
        format!("{to}{}", &ind[from.len()..])
    } else {
        to[..to.len().saturating_sub(from.len() - ind.len())].to_owned()
    }
}
