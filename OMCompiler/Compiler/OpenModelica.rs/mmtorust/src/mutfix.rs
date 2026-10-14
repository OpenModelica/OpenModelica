//! Drops `mut` from bindings that nothing in their function mutates.
//!
//! Runs on the generated text. A binding keeps its `mut` when the enclosing
//! top-level `fn` assigns its name (plainly, compoundly, through a field or
//! index, or in a tuple), takes `&mut` of it, calls a `&mut self` method on
//! it, or passes it first to a macro. Names are not resolved, so a shadowed
//! name keeps every `mut` of that name. Anything this misses is a compile
//! error (E0596/E0384), not a behaviour change.

use std::collections::HashSet;

const MUT_METHODS: &[&str] = &[
    "push", "push_str", "push_front", "push_back", "pop", "pop_front", "pop_back",
    "insert", "remove", "clear", "extend", "extend_from_slice", "append", "truncate",
    "drain", "retain", "sort", "sort_by", "sort_by_key", "sort_unstable",
    "sort_unstable_by", "dedup", "reverse", "swap", "iter_mut", "get_mut", "as_mut",
    "last_mut", "first_mut", "entry", "take", "replace", "set", "fill", "resize",
    "split_off", "make_mut", "borrow_mut", "get_or_insert", "get_or_insert_with",
    "values_mut", "next", "next_back", "nth", "by_ref", "peek", "rotate_left",
    "rotate_right", "write_str", "write_fmt", "read_to_string", "seek", "flush",
    "field", "finish", "finish_non_exhaustive", "entries", "key", "value",
];

fn is_ident_char(c: u8) -> bool {
    c.is_ascii_alphanumeric() || c == b'_'
}

/// The text with comments and string/char literals blanked to spaces, so
/// byte offsets stay valid.
fn mask(src: &str) -> Vec<u8> {
    let b = src.as_bytes();
    let mut out = b.to_vec();
    let mut i = 0;
    let blank = |out: &mut Vec<u8>, from: usize, to: usize| {
        for c in &mut out[from..to] {
            if *c != b'\n' { *c = b' '; }
        }
    };
    while i < b.len() {
        match b[i] {
            b'/' if b.get(i + 1) == Some(&b'/') => {
                let e = b[i..].iter().position(|&c| c == b'\n').map_or(b.len(), |p| i + p);
                blank(&mut out, i, e);
                i = e;
            }
            b'/' if b.get(i + 1) == Some(&b'*') => {
                let (mut j, mut depth) = (i + 2, 1);
                while j < b.len() && depth > 0 {
                    if b[j] == b'/' && b.get(j + 1) == Some(&b'*') { depth += 1; j += 2; }
                    else if b[j] == b'*' && b.get(j + 1) == Some(&b'/') { depth -= 1; j += 2; }
                    else { j += 1; }
                }
                blank(&mut out, i, j);
                i = j;
            }
            b'r' if (b.get(i + 1) == Some(&b'"') || b.get(i + 1) == Some(&b'#'))
                && (i == 0 || !is_ident_char(b[i - 1])) => {
                let mut j = i + 1;
                let mut hashes = 0;
                while b.get(j) == Some(&b'#') { hashes += 1; j += 1; }
                if b.get(j) != Some(&b'"') { i += 1; continue; }
                let close: Vec<u8> = std::iter::once(b'"').chain(std::iter::repeat_n(b'#', hashes)).collect();
                let e = b[j + 1..].windows(close.len()).position(|w| w == close.as_slice())
                    .map_or(b.len(), |p| j + 1 + p + close.len());
                blank(&mut out, i, e);
                i = e;
            }
            b'"' => {
                let mut j = i + 1;
                while j < b.len() && b[j] != b'"' {
                    j += if b[j] == b'\\' { 2 } else { 1 };
                }
                let e = (j + 1).min(b.len());
                blank(&mut out, i, e);
                i = e;
            }
            b'\'' => {
                // A char literal ends with a quote within a few bytes; a
                // lifetime does not.
                let e = if b.get(i + 1) == Some(&b'\\') {
                    b[i + 2..].iter().position(|&c| c == b'\'').map(|p| i + 3 + p)
                } else {
                    let ch = src[i + 1..].chars().next().map_or(1, |c| c.len_utf8());
                    (b.get(i + 1 + ch) == Some(&b'\'')).then_some(i + 2 + ch)
                };
                match e {
                    Some(e) => { blank(&mut out, i, e); i = e; }
                    None => i += 1,
                }
            }
            _ => i += 1,
        }
    }
    out
}

fn word_at(b: &[u8], i: usize, w: &[u8]) -> bool {
    b[i..].starts_with(w)
        && (i == 0 || !is_ident_char(b[i - 1]))
        && b.get(i + w.len()).is_none_or(|&c| !is_ident_char(c))
}

fn ident_at(b: &[u8], i: usize) -> Option<(usize, usize)> {
    let start = i;
    let mut j = i;
    if b[j..].starts_with(b"r#") { j += 2; }
    let s = j;
    while j < b.len() && is_ident_char(b[j]) { j += 1; }
    (j > s && !b[s].is_ascii_digit()).then_some((start, j))
}

fn skip_ws(b: &[u8], mut i: usize) -> usize {
    while i < b.len() && b[i].is_ascii_whitespace() { i += 1; }
    i
}

fn skip_ws_back(b: &[u8], mut i: usize) -> usize {
    while i > 0 && b[i - 1].is_ascii_whitespace() { i -= 1; }
    i
}

/// Byte ranges of the top-level `fn` items, from `fn` to the closing brace.
fn fn_scopes(b: &[u8]) -> Vec<(usize, usize)> {
    let mut scopes = Vec::new();
    let mut i = 0;
    while i < b.len() {
        if word_at(b, i, b"fn") && b.get(skip_ws(b, i + 2)) != Some(&b'(') {
            let Some(open) = b[i..].iter().position(|&c| c == b'{' || c == b';').map(|p| i + p) else { break };
            if b[open] == b';' { i = open + 1; continue; }
            let mut depth = 0usize;
            let mut j = open;
            while j < b.len() {
                match b[j] {
                    b'{' => depth += 1,
                    b'}' => { depth -= 1; if depth == 0 { break; } }
                    _ => {}
                }
                j += 1;
            }
            scopes.push((i, j.min(b.len())));
            i = j + 1;
        } else {
            i += 1;
        }
    }
    scopes
}

fn ident_str(b: &[u8], (s, e): (usize, usize)) -> String {
    let s = if b[s..].starts_with(b"r#") { s + 2 } else { s };
    String::from_utf8_lossy(&b[s..e]).into_owned()
}

/// A mutation of `name` at a byte offset: an assignment, or anything else
/// (`&mut`, a `&mut self` method, a macro's first argument).
struct Mutation { name: String, at: usize, assign: bool }

/// The mutations in a scope.
fn mutations(b: &[u8], from: usize, to: usize) -> Vec<Mutation> {
    let mut out = Vec::new();
    let mut i = from;
    while i < to {
        let c = b[i];
        // Assignment operators: `=` that is not `==`, `!=`, `<=`, `>=`, `=>`.
        if c == b'=' && b.get(i + 1) != Some(&b'=') && b.get(i + 1) != Some(&b'>')
            && i > 0 && b[i - 1] != b'=' && b[i - 1] != b'!'
            && !(b[i - 1] == b'<' && b.get(i.wrapping_sub(2)) != Some(&b'<'))
            && !(b[i - 1] == b'>' && b.get(i.wrapping_sub(2)) != Some(&b'>'))
        {
            let mut end = i;
            if end > 0 && b"+-*/%|&^".contains(&b[end - 1]) { end -= 1; }
            if end >= 2 && (&b[end - 2..end] == b"<<" || &b[end - 2..end] == b">>") { end -= 2; }
            let end = skip_ws_back(b, end);
            // Walk back over a place expression: idents, `.`, `::`, `#`,
            // `*`, and bracketed groups.
            let mut s = end;
            while s > from {
                let p = b[s - 1];
                if is_ident_char(p) || p == b'.' || p == b':' || p == b'#' || p == b'*' {
                    s -= 1;
                } else if p == b')' || p == b']' {
                    let (open, close) = if p == b')' { (b'(', b')') } else { (b'[', b']') };
                    let mut depth = 0i32;
                    let mut k = s;
                    while k > from {
                        k -= 1;
                        if b[k] == close { depth += 1; }
                        else if b[k] == open { depth -= 1; if depth == 0 { break; } }
                    }
                    s = k;
                } else {
                    break;
                }
            }
            let before = skip_ws_back(b, s);
            let prev_word = {
                let mut k = before;
                while k > from && is_ident_char(b[k - 1]) { k -= 1; }
                &b[k..before]
            };
            let is_decl = matches!(prev_word, b"let" | b"mut" | b"const" | b"static" | b"type")
                || (before > from && b[before - 1] == b'<');
            if !is_decl && s < end {
                let place = &b[s..end];
                if place.first() == Some(&b'(') {
                    // Tuple assignment: every bare name inside is assigned.
                    let mut k = s;
                    while k < end {
                        if let Some(r) = ident_at(b, k) {
                            let after = skip_ws(b, r.1);
                            let preceded = k > 0 && (b[k - 1] == b'.' || b[k - 1] == b':');
                            if !preceded && !matches!(b.get(after), Some(b'(') | Some(b':') | Some(b'!')) {
                                out.push(Mutation { name: ident_str(b, r), at: i, assign: true });
                            }
                            k = r.1;
                        } else {
                            k += 1;
                        }
                    }
                } else {
                    let mut k = s;
                    let deref = b[k] == b'*';
                    while k < end && b[k] == b'*' { k += 1; }
                    if let Some(r) = ident_at(b, k) {
                        // Only a plain `name = …` can be a deferred initialisation.
                        out.push(Mutation { name: ident_str(b, r), at: i, assign: !deref && r.1 == end });
                    }
                }
            }
            i += 1;
            continue;
        }
        // `&mut name`
        if c == b'&' {
            let k = skip_ws(b, i + 1);
            if word_at(b, k, b"mut") {
                let mut k = skip_ws(b, k + 3);
                while k < to && (b[k] == b'*' || b[k] == b'(') { k += 1; }
                if let Some(r) = ident_at(b, k) { out.push(Mutation { name: ident_str(b, r), at: i, assign: false }); }
            }
            i += 1;
            continue;
        }
        // `name.path.method(` with a `&mut self` method, and `macro!(name, …)`.
        if is_ident_char(c) && (i == 0 || (!is_ident_char(b[i - 1]) && b[i - 1] != b'.')) {
            if let Some(r) = ident_at(b, i) {
                let name = ident_str(b, r);
                let mut k = r.1;
                loop {
                    if b.get(k) == Some(&b'.') {
                        if let Some(m) = ident_at(b, k + 1) {
                            let mname = &b[m.0..m.1];
                            if b.get(m.1) == Some(&b'(')
                                && MUT_METHODS.iter().any(|x| x.as_bytes() == mname)
                            {
                                out.push(Mutation { name: name.clone(), at: i, assign: false });
                                break;
                            }
                            k = m.1;
                            continue;
                        }
                    } else if b.get(k) == Some(&b'[') {
                        if let Some(p) = b[k..to].iter().position(|&c| c == b']') { k += p + 1; continue; }
                    }
                    break;
                }
                if b.get(r.1) == Some(&b'!') {
                    let k = skip_ws(b, r.1 + 1);
                    if matches!(b.get(k), Some(b'(') | Some(b'[') | Some(b'{')) {
                        let k = skip_ws(b, k + 1);
                        if let Some(a) = ident_at(b, k) {
                            let n = skip_ws(b, a.1);
                            if matches!(b.get(n), Some(b',') | Some(b')')) || b[n..].starts_with(b"=>") {
                                out.push(Mutation { name: ident_str(b, a), at: i, assign: false });
                            }
                        }
                    }
                }
                i = r.1;
                continue;
            }
        }
        i += 1;
    }
    out
}

/// Whether `let mut name: T;` ending its name at `after` is assigned exactly
/// once in its block, outside any loop that does not also hold the
/// declaration, and mutated no other way: then it needs no `mut`.
fn deferred_init_once(b: &[u8], after: usize, to: usize, name: &str, muts: &[Mutation]) -> bool {
    let Some(semi) = b[after..to].iter().position(|&c| c == b';' || c == b'=').map(|p| after + p) else { return false };
    if b[semi] != b';' {
        return false;
    }
    let mut depth = 0i32;
    let mut end = semi;
    while end < to {
        match b[end] {
            b'{' => depth += 1,
            b'}' => { depth -= 1; if depth < 0 { break; } }
            _ => {}
        }
        end += 1;
    }
    let body = &b[semi..end];
    let redeclared = body.windows(name.len() + 4).enumerate().any(|(k, w)| {
        (w.starts_with(b"mut ") || w.starts_with(b"let ")) && &w[4..] == name.as_bytes()
            && body.get(k + 4 + name.len()).is_none_or(|&c| !is_ident_char(c))
    });
    let here: Vec<&Mutation> = muts.iter().filter(|x| x.name == name && x.at > semi && x.at < end).collect();
    if redeclared || here.len() != 1 || !here[0].assign {
        return false;
    }
    let between = &b[semi..here[0].at];
    !(0..between.len()).any(|k| word_at(between, k, b"loop") || word_at(between, k, b"while") || word_at(between, k, b"for"))
}

/// `src` with the unneeded `mut` binding modes removed.
pub fn drop_unused_mut(src: &str) -> String {
    let m = mask(src);
    // Without `mut`, `let x` matches a unit variant named `x` in scope
    // instead of binding; keep `mut` on names used as a path's last segment.
    let mut variant_like: HashSet<String> = HashSet::new();
    for k in 0..m.len().saturating_sub(2) {
        if &m[k..k + 2] == b"::" && let Some(r) = ident_at(&m, k + 2)
            && !matches!(m.get(r.1), Some(b'(') | Some(b'!') | Some(b':') | Some(b'<'))
        {
            variant_like.insert(ident_str(&m, r));
        }
    }
    let mut removals: Vec<usize> = Vec::new();
    for (from, to) in fn_scopes(&m) {
        let muts = mutations(&m, from, to);
        let mutated: HashSet<&str> = muts.iter().map(|x| x.name.as_str()).collect();
        let mut i = from;
        while i < to {
            if word_at(&m, i, b"mut") {
                let before = skip_ws_back(&m, i);
                let prev = before.checked_sub(1).map(|k| m[k]);
                let mut k = before;
                while k > from && is_ident_char(m[k - 1]) { k -= 1; }
                let prev_word = &m[k..before];
                let lifetime = k > from && m[k - 1] == b'\'';
                let binding = !matches!(prev, Some(b'&') | Some(b'*'))
                    && prev_word != b"ref" && prev_word != b"raw" && !lifetime;
                let name_at = skip_ws(&m, i + 3);
                if binding
                    && let Some(r) = ident_at(&m, name_at)
                    && &m[r.0..r.1] != b"self"
                {
                    let name = ident_str(&m, r);
                    if variant_like.contains(&name) {
                        i += 3;
                        continue;
                    }
                    if !mutated.contains(name.as_str())
                        || (prev_word == b"let" && deferred_init_once(&m, r.1, to, &name, &muts))
                    {
                        removals.push(i);
                    }
                }
                i += 3;
            } else {
                i += 1;
            }
        }
    }
    if removals.is_empty() {
        return src.to_owned();
    }
    let mut out = String::with_capacity(src.len());
    let mut last = 0;
    for r in removals {
        out.push_str(&src[last..r]);
        last = skip_ws(src.as_bytes(), r + 3);
    }
    out.push_str(&src[last..]);
    out
}

#[cfg(test)]
mod tests {
    use super::drop_unused_mut as f;

    #[test]
    fn keeps_assigned_drops_rest() {
        let src = "fn g(mut a: i32, mut b: i32) -> i32 {\n    let mut c = 1;\n    let mut d = 2;\n    a = 3;\n    (c, _) = (4, 5);\n    a + b + c + d\n}\n";
        assert_eq!(f(src), "fn g(mut a: i32, b: i32) -> i32 {\n    let mut c = 1;\n    let d = 2;\n    a = 3;\n    (c, _) = (4, 5);\n    a + b + c + d\n}\n");
    }

    #[test]
    fn keeps_borrowed_methods_macros_and_types() {
        let src = "fn g(x: &mut Vec<i32>, mut v: Vec<i32>, mut it: I, mut s: String, mut f: F, mut e: E) {\n    let p: &'a mut T = q;\n    v.push(1);\n    it.next();\n    write!(s, \"x = 1\");\n    f.0 = 2;\n    assign_variant_field!(e => E::V { a = 1 });\n    let y = \"mut z = 1\";\n}\n";
        assert_eq!(f(src), src);
    }

    #[test]
    fn keeps_names_of_variants() {
        let src = "fn g() {\n    let mut support: S;\n    support = S::support;\n}\n";
        assert_eq!(f(src), src);
    }

    #[test]
    fn deferred_initialisation() {
        let src = "fn g(c: bool) -> i32 {\n    let mut a: i32;\n    let mut b: i32;\n    let mut d: i32;\n    a = 1;\n    b = 1;\n    b = 2;\n    loop {\n        d = 3;\n        break;\n    }\n    a + b + d\n}\n";
        assert_eq!(f(src), "fn g(c: bool) -> i32 {\n    let a: i32;\n    let mut b: i32;\n    let mut d: i32;\n    a = 1;\n    b = 1;\n    b = 2;\n    loop {\n        d = 3;\n        break;\n    }\n    a + b + d\n}\n");
    }

    #[test]
    fn compound_and_field_assignments() {
        let src = "fn g() {\n    let mut a = 1;\n    let mut b = R::default();\n    let mut c = 0;\n    a += 1;\n    b.field.x = 2;\n    if c == 1 {}\n}\n";
        assert_eq!(f(src), "fn g() {\n    let mut a = 1;\n    let mut b = R::default();\n    let c = 0;\n    a += 1;\n    b.field.x = 2;\n    if c == 1 {}\n}\n");
    }
}
