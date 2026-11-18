//! Rewrites generated code into the shapes rustc and clippy expect: no
//! parentheses around a whole value, a declaration merged into its first
//! assignment, a `let` that is returned at once turned into the tail
//! expression, field init shorthand, compound assignment and no unused
//! imports. Runs on the generated text before `mutfix`; like there, anything
//! it gets wrong is a compile error, not a behaviour change.

use crate::mutfix::{fn_scopes, ident_at, ident_str, is_ident_char, mask, skip_ws, skip_ws_back, word_at};

/// The closing bracket matching the one at `open`, over `()`, `[]` and `{}`.
fn close_of(b: &[u8], open: usize) -> Option<usize> {
    let mut depth = 0i32;
    for (k, &c) in b.iter().enumerate().skip(open) {
        match c {
            b'(' | b'[' | b'{' => depth += 1,
            b')' | b']' | b'}' => {
                depth -= 1;
                if depth == 0 {
                    return Some(k);
                }
            }
            _ => {}
        }
    }
    None
}

/// Whether `b[from..to]` has a `,` outside any bracket.
fn top_level_comma(b: &[u8], from: usize, to: usize) -> bool {
    let mut depth = 0i32;
    for &c in &b[from..to] {
        match c {
            b'(' | b'[' | b'{' => depth += 1,
            b')' | b']' | b'}' => depth -= 1,
            b',' if depth == 0 => return true,
            _ => {}
        }
    }
    false
}

/// An `=` that assigns or initialises (not `==`, `!=`, `<=`, `>=`, `=>`).
fn is_assign_eq(b: &[u8], i: usize) -> bool {
    b[i] == b'='
        && !matches!(b.get(i + 1), Some(b'=') | Some(b'>'))
        && i > 0
        && !matches!(b[i - 1], b'=' | b'!' | b'<' | b'>')
}

fn line_start(b: &[u8], i: usize) -> usize {
    b[..i].iter().rposition(|&c| c == b'\n').map_or(0, |p| p + 1)
}

fn only_ws(b: &[u8]) -> bool {
    b.iter().all(|c| c.is_ascii_whitespace())
}

/// Replaces byte ranges of `src`. Overlapping ranges leave `src` unchanged.
fn apply(src: &str, mut edits: Vec<(usize, usize, String)>) -> String {
    if edits.is_empty() {
        return src.to_owned();
    }
    edits.sort_by_key(|e| e.0);
    if let Some(w) = edits.windows(2).find(|w| w[1].0 < w[0].1) {
        eprintln!(
            "[mmtorust] tidy: overlapping edits {:?} -> {:?} and {:?} -> {:?}",
            &src[w[0].0..w[0].1],
            w[0].2,
            &src[w[1].0..w[1].1.max(w[1].0)],
            w[1].2
        );
        return src.to_owned();
    }
    let mut out = String::with_capacity(src.len());
    let mut last = 0;
    for (s, e, text) in edits {
        out.push_str(&src[last..s]);
        out.push_str(&text);
        last = e;
    }
    out.push_str(&src[last..]);
    out
}

/// Parentheses around a whole value: an assigned value (`x = (e);`, also as
/// a macro argument), a returned one, a condition, a loop's iterator, or a
/// call argument (`f((e), g)`); and `return ();` as `return;`.
fn strip_value_parens(src: &str) -> String {
    let b = mask(src);
    let mut edits = Vec::new();
    let mut i = 0;
    while i < b.len() {
        let (open, followers): (usize, &[u8]) = if is_assign_eq(&b, i) {
            (skip_ws(&b, i + 1), b";),")
        } else if word_at(&b, i, b"return") {
            let open = skip_ws(&b, i + 6);
            if b.get(open) == Some(&b'(')
                && let Some(close) = close_of(&b, open)
                && only_ws(&b[open + 1..close])
                && b.get(skip_ws(&b, close + 1)) == Some(&b';')
            {
                edits.push((i + 6, close + 1, String::new()));
                i = close + 1;
                continue;
            }
            (open, b";")
        } else if word_at(&b, i, b"in") {
            (skip_ws(&b, i + 2), b"{")
        } else if word_at(&b, i, b"if") || word_at(&b, i, b"while") {
            let open = skip_ws(&b, i + if b[i] == b'i' { 2 } else { 5 });
            // Without the parentheses a struct literal in the condition
            // would read as the body.
            match close_of(&b, open) {
                Some(close) if b[open] == b'(' && !b[open..close].contains(&b'{') => (open, b"{"),
                _ => {
                    i += 1;
                    continue;
                }
            }
        } else if matches!(b[i], b'(' | b',') {
            (skip_ws(&b, i + 1), b",)")
        } else {
            i += 1;
            continue;
        };
        if b.get(open) == Some(&b'(')
            && let Some(close) = close_of(&b, open)
            && b.get(skip_ws(&b, close + 1)).is_some_and(|c| followers.contains(c))
            && !only_ws(&b[open + 1..close])
            && !top_level_comma(&b, open + 1, close)
        {
            edits.push((open, open + 1, String::new()));
            edits.push((close, close + 1, String::new()));
            i = open + 1;
            continue;
        }
        i += 1;
    }
    apply(src, edits)
}

/// The first use of `name` in `b[from..to]`, with the change in `{}` depth
/// on the way there; `None` when the enclosing block ends first.
fn first_use(b: &[u8], from: usize, to: usize, name: &str) -> Option<(usize, usize, i32)> {
    let mut depth = 0i32;
    let mut i = from;
    while i < to {
        match b[i] {
            b'{' => depth += 1,
            b'}' => {
                depth -= 1;
                if depth < 0 {
                    return None;
                }
            }
            c if is_ident_char(c) && !is_ident_char(b[i - 1]) => {
                let Some(r) = ident_at(b, i) else {
                    while i < to && is_ident_char(b[i]) {
                        i += 1;
                    }
                    continue;
                };
                let field = b[i - 1] == b'.' || (i >= 2 && &b[i - 2..i] == b"::");
                let after = skip_ws(b, r.1);
                let before = skip_ws_back(b, i);
                let declared = before >= 3 && (word_at(b, before - 3, b"let") || word_at(b, before - 3, b"mut"));
                let label = !declared && b.get(after) == Some(&b':') && b.get(after + 1) != Some(&b':');
                let mac = b.get(r.1) == Some(&b'!');
                if !field && !label && !mac && ident_str(b, r) == name {
                    return Some((r.0, r.1, depth));
                }
                i = r.1;
                continue;
            }
            _ => {}
        }
        i += 1;
    }
    None
}

/// The `;` that ends the statement continuing at `from`.
fn stmt_end(b: &[u8], from: usize, to: usize) -> Option<usize> {
    let mut depth = 0i32;
    for (k, &c) in b.iter().enumerate().take(to).skip(from) {
        match c {
            b'(' | b'[' | b'{' => depth += 1,
            b')' | b']' | b'}' => depth -= 1,
            b';' if depth == 0 => return Some(k),
            _ => {}
        }
        if depth < 0 {
            return None;
        }
    }
    None
}

/// Whether the identifier `name` occurs in `b[from..to]`.
fn mentions(b: &[u8], from: usize, to: usize, name: &str) -> bool {
    let mut i = from;
    while i < to {
        if is_ident_char(b[i]) && !is_ident_char(b[i - 1]) {
            let Some(r) = ident_at(b, i) else {
                while i < to && is_ident_char(b[i]) {
                    i += 1;
                }
                continue;
            };
            if ident_str(b, r) == name {
                return true;
            }
            i = r.1;
        } else {
            i += 1;
        }
    }
    false
}

/// `let x: T;` followed, in the same block, by `x = e;` as the first use
/// becomes `let x: T = e;`, unless `e` itself refers to `x`.
fn merge_late_init(src: &str) -> String {
    let b = mask(src);
    let mut edits = Vec::new();
    for (from, to) in fn_scopes(&b) {
        let mut i = from;
        while i < to {
            if !word_at(&b, i, b"let") {
                i += 1;
                continue;
            }
            let ls = line_start(&b, i);
            let mut k = skip_ws(&b, i + 3);
            if word_at(&b, k, b"mut") {
                k = skip_ws(&b, k + 3);
            }
            let Some(r) = ident_at(&b, k) else {
                i += 3;
                continue;
            };
            let name = ident_str(&b, r);
            let mut depth = 0i32;
            let mut end = r.1;
            while end < to {
                match b[end] {
                    b'(' | b'[' | b'{' => depth += 1,
                    b')' | b']' | b'}' => depth -= 1,
                    b';' | b'=' if depth == 0 => break,
                    _ => {}
                }
                end += 1;
            }
            let eol = b[end..to].iter().position(|&c| c == b'\n').map_or(to, |p| end + p);
            if name == "_" || end >= to || b[end] != b';' || !only_ws(&b[ls..i]) || !only_ws(&b[end + 1..eol]) {
                i = r.1;
                continue;
            }
            if let Some((us, ue, 0)) = first_use(&b, end + 1, to, &name)
                && only_ws(&b[line_start(&b, us)..us])
                && let a = skip_ws(&b, ue)
                && a < to
                && is_assign_eq(&b, a)
                && let Some(stmt_end) = stmt_end(&b, a + 1, to)
                && !mentions(&b, a + 1, stmt_end, &name)
            {
                edits.push((ls, (eol + 1).min(to), String::new()));
                edits.push((us, ue, src[i..end].trim_end().to_owned()));
            }
            i = end;
        }
    }
    apply(src, edits)
}

/// A function that ends in `let x = e; x` (or `Ok(x)`) ends in `e` (or
/// `Ok(e)`) instead.
fn return_tail_let(src: &str) -> String {
    let b = mask(src);
    let mut edits = Vec::new();
    for (from, to) in fn_scopes(&b) {
        let Some(open) = b[from..to].iter().position(|&c| c == b'{').map(|p| from + p) else {
            continue;
        };
        let mut semis = Vec::new();
        let mut depth = 0i32;
        for k in open + 1..to {
            match b[k] {
                b'(' | b'[' | b'{' => depth += 1,
                b')' | b']' | b'}' => depth -= 1,
                b';' if depth == 0 => semis.push(k),
                _ => {}
            }
        }
        let Some(&last) = semis.last() else { continue };
        let prev = semis.len().checked_sub(2).map_or(open, |n| semis[n]);
        let tail = std::str::from_utf8(&b[last + 1..to]).unwrap_or("").trim();
        let (name, wrap) = match tail.strip_prefix("Ok(").and_then(|t| t.strip_suffix(')')) {
            Some(n) => (n.trim(), true),
            None => (tail, false),
        };
        if name.is_empty() || !name.bytes().all(is_ident_char) {
            continue;
        }
        // The `let` of the last statement starts a line at depth 0.
        let mut let_at = None;
        let mut depth = 0i32;
        for k in prev + 1..last {
            match b[k] {
                b'(' | b'[' | b'{' => depth += 1,
                b')' | b']' | b'}' => depth -= 1,
                _ if depth == 0 && word_at(&b, k, b"let") && only_ws(&b[line_start(&b, k)..k]) => let_at = Some(k),
                _ => {}
            }
        }
        let Some(l) = let_at else { continue };
        let mut k = skip_ws(&b, l + 3);
        if word_at(&b, k, b"mut") {
            k = skip_ws(&b, k + 3);
        }
        let Some(r) = ident_at(&b, k) else { continue };
        if ident_str(&b, r) != name {
            continue;
        }
        let mut k = skip_ws(&b, r.1);
        if b[k] == b':' {
            let mut depth = 0i32;
            while k < last {
                match b[k] {
                    b'(' | b'[' | b'{' => depth += 1,
                    b')' | b']' | b'}' => depth -= 1,
                    _ if depth == 0 && is_assign_eq(&b, k) => break,
                    _ => {}
                }
                k += 1;
            }
        }
        if k >= last || !is_assign_eq(&b, k) {
            continue;
        }
        let value = src[k + 1..last].trim();
        let text = if wrap { format!("Ok({value})") } else { value.to_owned() };
        edits.push((l, skip_ws_back(&b, to).max(last + 1), text));
    }
    apply(src, edits)
}

/// `S { f: f }` (literal or pattern) as `S { f }`, inside function bodies
/// only, where no struct is declared.
fn shorthand_fields(src: &str) -> String {
    let b = mask(src);
    let mut edits = Vec::new();
    for (from, to) in fn_scopes(&b) {
        let Some(open) = b[from..to].iter().position(|&c| c == b'{').map(|p| from + p) else {
            continue;
        };
        shorthand_fields_in(&b, open, to, &mut edits);
    }
    apply(src, edits)
}

fn shorthand_fields_in(b: &[u8], from: usize, to: usize, edits: &mut Vec<(usize, usize, String)>) {
    let mut stack: Vec<u8> = Vec::new();
    let mut i = from;
    while i < to {
        match b[i] {
            c @ (b'(' | b'[' | b'{') => stack.push(c),
            b')' | b']' | b'}' => {
                stack.pop();
            }
            _ => {}
        }
        if matches!(b[i], b'{' | b',') && stack.last() == Some(&b'{') {
            let k = skip_ws(b, i + 1);
            if let Some(f) = ident_at(b, k) {
                let colon = skip_ws(b, f.1);
                if b.get(colon) == Some(&b':') && b.get(colon + 1) != Some(&b':') {
                    let v0 = skip_ws(b, colon + 1);
                    if let Some(v) = ident_at(b, v0)
                        && b[f.0..f.1] == b[v.0..v.1]
                        && matches!(b.get(skip_ws(b, v.1)), Some(b',') | Some(b'}'))
                    {
                        edits.push((f.1, v.1, String::new()));
                        i = v.1;
                        continue;
                    }
                }
            }
        }
        i += 1;
    }
}

/// Whether `b[from..to]` holds a binary operator outside brackets (a
/// leading unary `-`, `!`, `&` or `*` does not count).
fn has_top_level_operator(b: &[u8], from: usize, to: usize) -> bool {
    let mut depth = 0i32;
    let start = skip_ws(b, from);
    for k in start..to {
        match b[k] {
            b'(' | b'[' | b'{' => depth += 1,
            b')' | b']' | b'}' => depth -= 1,
            b'+' | b'-' | b'*' | b'/' | b'%' | b'&' | b'|' | b'^' | b'<' | b'>' | b'=' | b'!' | b'?'
                if depth == 0 && k != start =>
            {
                return true;
            }
            _ => {}
        }
    }
    false
}

/// `x = x + y;` as `x += y;` (also `-`, `*`, `/`, `%`) when `y` is a single
/// operand, so that the evaluation order cannot change.
fn compound_assign(src: &str) -> String {
    let b = mask(src);
    let mut edits = Vec::new();
    let mut i = 0;
    while i < b.len() {
        if !is_assign_eq(&b, i) || !matches!(b[i - 1], b' ' | b'\t') {
            i += 1;
            continue;
        }
        let lhs_end = skip_ws_back(&b, i);
        let mut lhs_start = lhs_end;
        while lhs_start > 0 && (is_ident_char(b[lhs_start - 1]) || b[lhs_start - 1] == b'#') {
            lhs_start -= 1;
        }
        let lhs = &b[lhs_start..lhs_end];
        let rhs = skip_ws(&b, i + 1);
        if lhs.is_empty()
            || !only_ws(&b[line_start(&b, lhs_start)..lhs_start])
            || !b[rhs..].starts_with(lhs)
            || b.get(rhs + lhs.len()).is_some_and(|&c| is_ident_char(c))
        {
            i += 1;
            continue;
        }
        let op_at = skip_ws(&b, rhs + lhs.len());
        let Some(&op) = b.get(op_at) else { break };
        let operand = skip_ws(&b, op_at + 1);
        if !matches!(op, b'+' | b'-' | b'*' | b'/' | b'%')
            || matches!(b.get(op_at + 1), Some(b'=') | Some(b'>'))
            || b[op_at..].starts_with(b"->")
        {
            i += 1;
            continue;
        }
        if let Some(end) = stmt_end(&b, operand, b.len())
            && end > operand
            && !has_top_level_operator(&b, operand, end)
            && only_ws(&b[end + 1..b[end..].iter().position(|&c| c == b'\n').map_or(b.len(), |p| end + p)])
        {
            edits.push((i, operand, format!("{}= ", op as char)));
            i = end;
            continue;
        }
        i += 1;
    }
    apply(src, edits)
}

/// The top-level `use` lines without the names nothing else in the file
/// mentions. Re-exports, globs and `as _` imports stay, and so does every
/// import of a module with a `<Package>.handwritten.rs` part, which sees them
/// through `use super::*`.
fn prune_imports(src: &str) -> String {
    if src.contains(".handwritten.rs\"") {
        return src.to_owned();
    }
    let b = mask(src);
    let mentioned = |name: &str, skip: (usize, usize)| -> bool {
        let n = name.as_bytes();
        let mut k = 0;
        while let Some(p) = b[k..].windows(n.len()).position(|w| w == n) {
            let at = k + p;
            let bounded =
                (at == 0 || !is_ident_char(b[at - 1])) && b.get(at + n.len()).is_none_or(|&c| !is_ident_char(c));
            if bounded && !(skip.0 <= at && at < skip.1) {
                return true;
            }
            k = at + 1;
        }
        false
    };
    let mut edits = Vec::new();
    let mut ls = 0;
    while ls < b.len() {
        let le = b[ls..].iter().position(|&c| c == b'\n').map_or(b.len(), |p| ls + p);
        let line = std::str::from_utf8(&b[ls..le]).unwrap_or("");
        if let Some(rest) = line.strip_prefix("use ").and_then(|r| r.trim_end().strip_suffix(';')) {
            let names: Option<(String, Vec<String>)> = if let Some((prefix, list)) = rest.split_once('{') {
                let list = list.strip_suffix('}').unwrap_or(list);
                Some((
                    prefix.to_owned(),
                    list.split(',')
                        .map(|x| x.trim().to_owned())
                        .filter(|x| !x.is_empty())
                        .collect(),
                ))
            } else if !rest.ends_with('*') {
                Some((String::new(), vec![rest.trim().to_owned()]))
            } else {
                None
            };
            if let Some((prefix, items)) = names {
                let keep: Vec<&String> = items
                    .iter()
                    .filter(|item| {
                        let local = match item.rsplit_once(" as ") {
                            Some((_, alias)) => alias.trim(),
                            None => item.rsplit("::").next().unwrap_or(item),
                        };
                        local == "_" || local == "self" || local.contains('{') || mentioned(local, (ls, le))
                    })
                    .collect();
                if keep.len() < items.len() {
                    let text = if keep.is_empty() {
                        String::new()
                    } else if prefix.is_empty() {
                        format!("use {};", keep[0])
                    } else {
                        format!(
                            "use {prefix}{{{}}};",
                            keep.iter().map(|x| x.as_str()).collect::<Vec<_>>().join(", ")
                        )
                    };
                    let end = if keep.is_empty() { (le + 1).min(b.len()) } else { le };
                    edits.push((ls, end, text));
                }
            }
        }
        ls = le + 1;
    }
    apply(src, edits)
}

/// A block that ends in `stmt; ()` ends in `stmt;` instead.
fn drop_unit_tails(src: &str) -> String {
    let b = mask(src);
    let mut edits = Vec::new();
    let mut ls = 0;
    while ls < b.len() {
        let le = b[ls..].iter().position(|&c| c == b'\n').map_or(b.len(), |p| ls + p);
        if b[ls..le].iter().filter(|c| !c.is_ascii_whitespace()).eq(b"()".iter())
            && b.get(skip_ws(&b, le)) == Some(&b'}')
            && matches!(b.get(skip_ws_back(&b, ls).wrapping_sub(1)), Some(b';') | Some(b'}'))
        {
            edits.push((ls, (le + 1).min(b.len()), String::new()));
        }
        ls = le + 1;
    }
    apply(src, edits)
}

/// `src` after all rewrites, in the order that lets each one see the shapes
/// the previous one leaves.
pub fn tidy(src: &str) -> String {
    let s = return_tail_let(&merge_late_init(&strip_value_parens(src)));
    prune_imports(&compound_assign(&shorthand_fields(&drop_unit_tails(&s))))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn value_parens() {
        let src = "fn g() {\n    x = (match y { _ => 1 });\n    let z: T = (a + b);\n    w = (a, b);\n    v = (a).f();\n    u += (1);\n    return (e);\n    f((x as i32), ((a, b)), (y)?, m!(t => V; f = ({ 1 })));\n    for v in ({ l }) {}\n    return ();\n}\n";
        assert_eq!(
            strip_value_parens(src),
            "fn g() {\n    x = match y { _ => 1 };\n    let z: T = a + b;\n    w = (a, b);\n    v = (a).f();\n    u += 1;\n    return e;\n    f(x as i32, (a, b), (y)?, m!(t => V; f = { 1 }));\n    for v in { l } {}\n    return;\n}\n"
        );
    }

    #[test]
    fn parens_ignore_comparisons_and_strings() {
        let src = "fn g() {\n    if a == (b) {}\n    let s = \"x = (y);\";\n}\n";
        assert_eq!(strip_value_parens(src), src);
    }

    #[test]
    fn late_init_merged_at_first_use() {
        let src = "fn g() -> i32 {\n    let mut a: i32;\n    let b: Vec<(i32, i32)>;\n    // a comment\n    a = 1;\n    b = f(a);\n    a + b.len()\n}\n";
        assert_eq!(
            merge_late_init(src),
            "fn g() -> i32 {\n    // a comment\n    let mut a: i32 = 1;\n    let b: Vec<(i32, i32)> = f(a);\n    a + b.len()\n}\n"
        );
    }

    #[test]
    fn late_init_kept_when_first_use_is_not_an_assignment_in_the_block() {
        let src = "fn g(c: bool) -> i32 {\n    let a: i32;\n    let b: i32;\n    let d: i32;\n    let e: i32;\n    if c {\n        a = 1;\n    } else {\n        a = 2;\n    }\n    h(b);\n    (d, e) = (1, 2);\n    a + b + d + e\n}\n";
        assert_eq!(merge_late_init(src), src);
    }

    #[test]
    fn late_init_kept_when_the_value_uses_the_name() {
        let src = "fn g(t: Option<i32>) -> i32 {\n    let mut r#str: i32;\n    r#str = match t {\n        Some(v) => {\n            r#str = v;\n            r#str\n        }\n        None => 0,\n    };\n    r#str\n}\n";
        assert_eq!(merge_late_init(src), src);
    }

    #[test]
    fn late_init_kept_for_a_name_declared_twice() {
        let src = "fn g() -> i32 {\n    let mut a: i32;\n    let a: i32;\n    a = 1;\n    a\n}\n";
        assert_eq!(
            merge_late_init(src),
            "fn g() -> i32 {\n    let mut a: i32;\n    let a: i32 = 1;\n    a\n}\n"
        );
    }

    #[test]
    fn late_init_skips_fields_paths_and_labels() {
        let src = "fn g() -> R {\n    let a: i32;\n    x.a = 2;\n    let r = R { a: 1 };\n    T::a();\n    a = 3;\n    r\n}\n";
        assert_eq!(
            merge_late_init(src),
            "fn g() -> R {\n    x.a = 2;\n    let r = R { a: 1 };\n    T::a();\n    let a: i32 = 3;\n    r\n}\n"
        );
    }

    #[test]
    fn tail_let_returned() {
        let src = "fn g(y: Option<i32>) -> Result<i32> {\n    let z = 1;\n    let out: i32 = match y {\n        Some(v) => v,\n        _ => z,\n    };\n    Ok(out)\n}\nfn h() -> i32 {\n    let mut o = 2;\n    o\n}\n";
        assert_eq!(
            return_tail_let(src),
            "fn g(y: Option<i32>) -> Result<i32> {\n    let z = 1;\n    Ok(match y {\n        Some(v) => v,\n        _ => z,\n    })\n}\nfn h() -> i32 {\n    2\n}\n"
        );
    }

    #[test]
    fn tail_let_kept_for_other_names_and_tuples() {
        let src = "fn g() -> (i32, i32) {\n    let a = 1;\n    let b = 2;\n    (a, b)\n}\nfn h() -> i32 {\n    let a = 1;\n    let b = 2;\n    a\n}\n";
        assert_eq!(return_tail_let(src), src);
    }

    #[test]
    fn field_shorthand() {
        let src = "pub enum E {\n    BCONST { bool: bool },\n}\nfn g(a: i32, b: b) -> R {\n    let r = R { a: a, b: c, r#mod: r#mod };\n    match r { R { a: a, .. } => f(x: x) }\n}\n";
        assert_eq!(
            shorthand_fields(src),
            "pub enum E {\n    BCONST { bool: bool },\n}\nfn g(a: i32, b: b) -> R {\n    let r = R { a, b: c, r#mod };\n    match r { R { a, .. } => f(x: x) }\n}\n"
        );
    }

    #[test]
    fn compound_assignments() {
        let src = "fn g() {\n    w = w + 1;\n    i = i - (n).len() as i32;\n    x = x * f(a, b);\n    y = y + a - b;\n    z = 1 + z;\n    v = v - -1;\n    s.t = s.t + 1;\n    q = qq + 1;\n}\n";
        assert_eq!(
            compound_assign(src),
            "fn g() {\n    w += 1;\n    i -= (n).len() as i32;\n    x *= f(a, b);\n    y = y + a - b;\n    z = 1 + z;\n    v -= -1;\n    s.t = s.t + 1;\n    q = qq + 1;\n}\n"
        );
    }

    #[test]
    fn imports_pruned() {
        let src = "use arcstr::{ArcStr, format, literal};\nuse const_str;\nuse metamodelica::*;\nuse crate::NFConnection as Connection;\nuse crate::Util;\npub use self::T::{A, B};\nuse std::fmt::Write as _;\n\nfn g() -> ArcStr {\n    Util::f(literal!(\"format\"))\n}\n";
        assert_eq!(
            prune_imports(src),
            "use arcstr::{ArcStr, literal};\nuse metamodelica::*;\nuse crate::Util;\npub use self::T::{A, B};\nuse std::fmt::Write as _;\n\nfn g() -> ArcStr {\n    Util::f(literal!(\"format\"))\n}\n"
        );
    }

    #[test]
    fn conditions_and_unit_tails() {
        let src = "fn g() {\n    if (a == b) {\n        f();\n        ()\n    } else if (S { x } == s) {\n        ()\n    }\n    while (i < n) {\n        i += 1;\n    }\n    let () = match x {\n        _ => {\n            h()?;\n            ()\n        }\n    };\n}\n";
        assert_eq!(
            drop_unit_tails(&strip_value_parens(src)),
            "fn g() {\n    if a == b {\n        f();\n    } else if (S { x } == s) {\n        ()\n    }\n    while i < n {\n        i += 1;\n    }\n    let () = match x {\n        _ => {\n            h()?;\n        }\n    };\n}\n"
        );
    }

    #[test]
    fn whole_pipeline() {
        let src = "pub fn getOptionOrDefault<T>(inOption: Option<T>, inDefault: T) -> T {\n    let outValue: T;\n    outValue = (match inOption {\n        Some(value) => value,\n        _ => inDefault,\n    });\n    outValue\n}\n";
        assert_eq!(
            tidy(src),
            "pub fn getOptionOrDefault<T>(inOption: Option<T>, inDefault: T) -> T {\n    match inOption {\n        Some(value) => value,\n        _ => inDefault,\n    }\n}\n"
        );
    }
}
