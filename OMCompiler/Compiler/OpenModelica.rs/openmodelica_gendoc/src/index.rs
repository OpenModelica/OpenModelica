//! The JSON the sidebar and the search box read.
//!
//! One tree per library (`index/tree/<Library>.json`) and, for content search,
//! one inverted index per library (`index/text/<Library>.json`). Both are
//! fetched on demand, so a page costs nothing until the reader navigates.

use std::collections::HashMap;

use crate::doc::ClassDoc;

pub fn escape(s: &str, out: &mut String) {
    out.push('"');
    for ch in s.chars() {
        match ch {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out.push('"');
}

fn string_array(values: impl Iterator<Item = impl AsRef<str>>, out: &mut String) {
    out.push('[');
    for (i, value) in values.enumerate() {
        if i > 0 {
            out.push(',');
        }
        escape(value.as_ref(), out);
    }
    out.push(']');
}

/// `{"n":[segment…],"p":[parent…],"d":[comment…],"k":[kind…],"kt":[kind name…],
/// "ic":[icon…]}` — a class' page name is rebuilt by walking `p`, so the
/// qualified names are not repeated 84 000 times. `ic` is the icon's URL, or
/// empty where the class has none.
pub fn tree(classes: &[ClassDoc], members: &[usize], icons: &[Option<String>]) -> String {
    let position: HashMap<usize, usize> = members
        .iter()
        .enumerate()
        .map(|(i, &c)| (c, i))
        .collect();
    let mut kinds: Vec<&str> = Vec::new();
    let mut kind_of = Vec::with_capacity(members.len());
    let mut parents = Vec::with_capacity(members.len());
    for &class in members {
        let restriction = classes[class].restriction.as_str();
        let kind = kinds.iter().position(|k| *k == restriction).unwrap_or_else(|| {
            kinds.push(restriction);
            kinds.len() - 1
        });
        kind_of.push(kind);
        parents.push(
            classes[class]
                .parent
                .and_then(|p| position.get(&p))
                .map_or(-1i64, |&p| p as i64),
        );
    }

    let mut out = String::with_capacity(members.len() * 64);
    out.push_str("{\"n\":");
    string_array(members.iter().map(|&c| classes[c].name()), &mut out);
    out.push_str(",\"p\":[");
    for (i, parent) in parents.iter().enumerate() {
        if i > 0 {
            out.push(',');
        }
        out.push_str(&parent.to_string());
    }
    out.push_str("],\"d\":");
    string_array(
        members.iter().map(|&c| crate::doc::description_text(&classes[c].comment)),
        &mut out,
    );
    out.push_str(",\"k\":[");
    for (i, kind) in kind_of.iter().enumerate() {
        if i > 0 {
            out.push(',');
        }
        out.push_str(&kind.to_string());
    }
    out.push_str("],\"kt\":");
    string_array(kinds.into_iter(), &mut out);
    out.push_str(",\"ic\":");
    string_array(
        members
            .iter()
            .map(|&c| icons.get(c).and_then(Option::as_deref).unwrap_or("")),
        &mut out,
    );
    out.push('}');
    out
}

/// Visible text of an HTML fragment, for the content index.
fn strip_markup(html: &str) -> String {
    let mut out = String::with_capacity(html.len());
    let mut depth = 0usize;
    let mut entity = String::new();
    for ch in html.chars() {
        match ch {
            '<' => depth += 1,
            '>' => depth = depth.saturating_sub(1),
            _ if depth > 0 => {}
            '&' => entity.push('&'),
            ';' if !entity.is_empty() => {
                out.push(' ');
                entity.clear();
            }
            c if !entity.is_empty() => {
                if entity.len() > 10 {
                    out.push_str(&entity);
                    entity.clear();
                    out.push(c);
                } else {
                    entity.push(c);
                }
            }
            c => out.push(c),
        }
    }
    out
}

/// Lowercase `[a-z0-9_]` runs of 3..=32 characters. The search box tokenizes
/// a query exactly the same way.
fn tokenize(text: &str, into: &mut Vec<String>) {
    let mut token = String::new();
    for ch in text.chars() {
        if ch.is_ascii_alphanumeric() || ch == '_' {
            token.push(ch.to_ascii_lowercase());
        } else {
            if token.len() >= 3 && token.len() <= 32 {
                into.push(std::mem::take(&mut token));
            } else {
                token.clear();
            }
        }
    }
    if token.len() >= 3 && token.len() <= 32 {
        into.push(token);
    }
}

fn base36(mut value: usize, out: &mut String) {
    const DIGITS: &[u8] = b"0123456789abcdefghijklmnopqrstuvwxyz";
    let start = out.len();
    loop {
        out.push(DIGITS[value % 36] as char);
        value /= 36;
        if value == 0 {
            break;
        }
    }
    // SAFETY-free reverse: the digits just pushed are all ASCII.
    let digits: Vec<char> = out[start..].chars().rev().collect();
    out.truncate(start);
    out.extend(digits);
}

/// `{"<token>":"<base-36 gaps between class indices, '.'-separated>"}`.
/// A token in more than 40% of the library's classes carries no information and
/// is dropped, which is most of what a stopword list would have caught.
pub fn text(classes: &[ClassDoc], members: &[usize]) -> String {
    let mut postings: HashMap<String, Vec<u32>> = HashMap::new();
    let mut tokens = Vec::new();
    for (position, &class) in members.iter().enumerate() {
        tokens.clear();
        tokenize(&crate::doc::description_text(&classes[class].comment), &mut tokens);
        tokenize(&strip_markup(&classes[class].info), &mut tokens);
        tokens.sort_unstable();
        tokens.dedup();
        for token in &tokens {
            let entry = postings.entry(token.clone()).or_default();
            entry.push(position as u32);
        }
    }

    let limit = (members.len() * 2 / 5).max(64);
    let mut terms: Vec<(&String, &Vec<u32>)> = postings
        .iter()
        .filter(|(_, p)| p.len() <= limit)
        .collect();
    terms.sort_unstable_by(|a, b| a.0.cmp(b.0));

    let mut out = String::with_capacity(terms.len() * 24);
    out.push('{');
    for (i, (token, classes)) in terms.iter().enumerate() {
        if i > 0 {
            out.push(',');
        }
        escape(token, &mut out);
        out.push_str(":\"");
        let mut previous = 0u32;
        for (j, &class) in classes.iter().enumerate() {
            if j > 0 {
                out.push('.');
            }
            base36((class - previous) as usize, &mut out);
            previous = class;
        }
        out.push('"');
    }
    out.push('}');
    out
}

/// `[{"n":name,"d":comment,"v":version,"c":class count,"ic":icon}…]`
pub fn libraries(
    classes: &[ClassDoc],
    roots: &[usize],
    counts: &[usize],
    icons: &[Option<String>],
) -> String {
    let mut out = String::from("[");
    for (i, (&root, &count)) in roots.iter().zip(counts).enumerate() {
        if i > 0 {
            out.push(',');
        }
        out.push_str("{\"n\":");
        escape(classes[root].name(), &mut out);
        out.push_str(",\"d\":");
        escape(&crate::doc::description_text(&classes[root].comment), &mut out);
        out.push_str(",\"v\":");
        escape(&classes[root].version, &mut out);
        out.push_str(",\"c\":");
        out.push_str(&count.to_string());
        out.push_str(",\"ic\":");
        escape(
            icons.get(root).and_then(Option::as_deref).unwrap_or(""),
            &mut out,
        );
        out.push('}');
    }
    out.push(']');
    out
}
