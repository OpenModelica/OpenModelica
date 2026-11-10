//! `diffModelicaFileListings`: puts the changes that the scripting API made to
//! a class into the text the user wrote, keeping the user's formatting.
//!
//! The API lists the edited class with omc's printer (`after`), which formats
//! everything its own way. So the user's text (`before`) is printed too
//! (`before_canonical`, unparse(parse(before))): it has the same tokens as
//! `before`, and since it comes from the same printer as `after`, the
//! difference of the two is the edit only. That difference is applied to
//! `before`:
//!
//! - Text that did not change is copied from `before`. Comments are not
//!   compared, so a comment that the AST moved or lost stays where it was.
//! - New code has the layout of `after`, indented like its neighbours; a list
//!   with an element on each line gets new elements on lines of their own.
//! - Code that moved keeps its text. In the classes the edit changes, code
//!   that the printer moved follows it.
//! - Deleted code takes the comments on its lines and those directly above
//!   it, but not a comment between two elements, which can belong to either.
//!
//! The texts have LF line endings and no byte order mark; omc handles those.

mod lex;
mod merge;
mod myers;

pub use merge::Stats;

/// The output of [`render`].
/// `ModelicaDiff.Format` in omc.
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
pub enum Format {
    /// The merged text.
    Plain,
    /// Terminal escape sequences: added text underlined green, deleted text struck red.
    Color,
    /// `<equal>`, `<add>` and `<del>` elements.
    Xml,
}

/// `before` with the changes from `before_canonical` to `after`.
/// `before_canonical` is omc's listing of `before` (unparse(parse(before))).
// TODO: When omc is only Rust, take its parser and printer as a function
// instead of `before_canonical`, list `before` only when it is needed, and
// move the sanity check of omc here (return None when it fails). The C
// interface of the bootstrapped omc cannot call back into omc.
pub fn merge(before: &str, before_canonical: &str, after: &str) -> String {
    merge::merge(before, before_canonical, after).0
}

/// [`merge`] with what it did.
pub fn merge_with_stats(before: &str, before_canonical: &str, after: &str) -> (String, Stats) {
    merge::merge(before, before_canonical, after)
}

/// `merged` as `format`: itself, or a diff of `before` and it.
pub fn render(before: &str, merged: &str, format: Format) -> String {
    merge::render(before, merged, format)
}

/// Whether `a` and `b` have the same code, ignoring whitespace, comments, the
/// common indentation of the lines of multi-line strings and a leading
/// `within` clause.
pub fn code_equal(a: &str, b: &str) -> bool {
    merge::code_equal(a, b)
}

// TODO: Remove the *_bytes functions when the bootstrapped omc is removed.
// Only its C strings can be other than UTF-8.

/// Runs `f` on the texts, decoded as UTF-8 if they all are, else byte by
/// byte as Latin-1, so that the bytes of a file in another encoding are kept.
fn on_bytes<R>(texts: &[&[u8]], f: impl FnOnce(&[&str]) -> R) -> (R, bool) {
    match texts
        .iter()
        .map(|t| std::str::from_utf8(t))
        .collect::<Result<Vec<&str>, _>>()
    {
        Ok(strs) => (f(&strs), true),
        Err(_) => {
            let owned: Vec<String> = texts.iter().map(|t| t.iter().map(|&c| c as char).collect()).collect();
            let strs: Vec<&str> = owned.iter().map(String::as_str).collect();
            (f(&strs), false)
        }
    }
}

fn encode(text: String, utf8: bool) -> Vec<u8> {
    if utf8 {
        text.into_bytes()
    } else {
        text.chars().map(|c| c as u32 as u8).collect()
    }
}

/// [`merge`] on bytes.
pub fn merge_bytes(before: &[u8], before_canonical: &[u8], after: &[u8]) -> Vec<u8> {
    let (text, utf8) = on_bytes(&[before, before_canonical, after], |t| merge(t[0], t[1], t[2]));
    encode(text, utf8)
}

/// [`render`] on bytes.
pub fn render_bytes(before: &[u8], merged: &[u8], format: Format) -> Vec<u8> {
    let (text, utf8) = on_bytes(&[before, merged], |t| render(t[0], t[1], format));
    encode(text, utf8)
}

/// [`code_equal`] on bytes.
pub fn code_equal_bytes(a: &[u8], b: &[u8]) -> bool {
    on_bytes(&[a, b], |t| code_equal(t[0], t[1])).0
}
