//! String builtins: char conversions, length/get/compare, append, and
//! `substring`. Hashing lives in [`hash`], URI resolution in [`uri`].

use std::sync::Arc;
use anyhow::{Result, bail};
use arcstr::{ArcStr, format};
use ordered_float::OrderedFloat;
use crate::{Real, list::List};

pub mod hash;
pub mod uri;
pub use hash::*;
pub use uri::*;

/// Returns the ASCII code point of a single-character string.
pub fn stringCharInt(ch: ArcStr) -> Result<i32> {
    // The string model here is char-based (cf. `stringListStringChar` /
    // `stringGetStringChar`): "single character" means one Unicode scalar, which
    // may span several bytes (e.g. "ö"). Count chars, not bytes, and return its
    // code point.
    if ch.chars().count() != 1 {
        bail!("stringCharInt expects a single-character string, got '{}'", ch);
    };
    ch.chars().next()
        .map(|c| c as i32)
        .ok_or_else(|| anyhow::anyhow!("Failed to get character from string: {}", ch))
}

/// Returns a single-character string from an ASCII code point.
pub fn intStringChar(i: i32) -> ArcStr {
    format!("{}", std::char::from_u32(i as u32).unwrap())
}

/// Parses an integer from a string. Fails if the string is not a valid integer.
///
/// Mirrors `nobox_stringInt` (meta_modelica_builtin.c): `strtol` skips
/// leading whitespace, and the conversion fails unless everything after the
/// number has been consumed (so trailing whitespace is an error).
pub fn stringInt(str: ArcStr) -> Result<i32> {
    str.trim_start_matches(c_isspace)
        .parse::<i32>()
        .map_err(|_| anyhow::anyhow!("Failed to parse integer from string: {}", str))
}

/// The C-locale `isspace` set that `strtol`/`strtod` skip before a number.
fn c_isspace(c: char) -> bool {
    matches!(c, ' ' | '\t' | '\n' | '\x0b' | '\x0c' | '\r')
}

/// Parses a real from a string.
/// Fails unless the whole string can be consumed.
///
/// Mirrors `nobox_stringReal` (meta_modelica_builtin.c): `strtod` skips
/// leading whitespace — e.g. `" 2.10"` from a CSV column parses — and the
/// conversion fails unless everything after the number has been consumed.
/// (C99 hex-float syntax, which strtod would also accept, is not supported
/// by Rust's parser; no caller is known to rely on it.)
pub fn stringReal(str: ArcStr) -> Result<Real> {
    str.trim_start_matches(c_isspace)
        .parse::<f64>()
        .map(OrderedFloat)
        .map_err(|_| anyhow::anyhow!("Failed to parse real from string: {}", str))
}

/// Converts a string to a list of single-character strings.
pub fn stringListStringChar(str: ArcStr) -> Arc<List<ArcStr>> {
    // TODO: We could have constants for all these short strings to avoid allocations.
    Arc::new(str.chars().map(|c| format!("{}", c)).collect())
}

/// Appends a list of strings into a single string.
pub fn stringAppendList(strs: Arc<List<ArcStr>>) -> ArcStr {
    let mut len = 0;
    for s in &*strs {
        len += s.len();
    }
    let mut result = String::with_capacity(len);
    for s in &*strs {
        result.push_str(s);
    }
    result.into()
}

/// Takes a list of strings and a delimiter and joins them with the delimiter inserted between elements.
/// Example: stringDelimitList({"x","y","z"}, ", ") => "x, y, z"
pub fn stringDelimitList(strs: Arc<List<ArcStr>>, delimiter: ArcStr) -> ArcStr {
    let mut len = 0;
    let delimiter_len = delimiter.len();
    for s in &*strs {
        len += s.len() + delimiter_len;
    }

    let mut result = String::with_capacity(len);
    let mut first = true;

    for s in &*strs {
        if !first {
            result.push_str(&delimiter);
        }
        result.push_str(s);
        first = false;
    }

    result.into()
}

/// Returns the length of the string (number of bytes).
pub fn stringLength(str: ArcStr) -> i32 {
    str.len() as i32
}

/// Returns true if the string is empty.
pub fn stringEmpty(str: ArcStr) -> bool {
    str.is_empty()
}

/// Returns the byte value at the given 1-based index.
pub fn stringGet(str: ArcStr, index: i32) -> Result<i32> {
    let idx = (index - 1) as usize; // 1-based to 0-based
    str.bytes().nth(idx)
        .map(|b| b as i32)
        .ok_or_else(|| anyhow::anyhow!("Index {} out of bounds for string of length {}", index, str.len()))
}

/// Returns the character at the given 1-based index as a string.
pub fn stringGetStringChar(str: ArcStr, index: i32) -> Result<ArcStr> {
    let idx = (index - 1) as usize; // 1-based to 0-based
    str.chars().nth(idx)
        .map(|c| format!("{}", c))
        .ok_or_else(|| anyhow::anyhow!("Index {} out of bounds for string of length {}", index, str.chars().count()))
}

/// Updates the character at the given 1-based index with newch.
/// newch should be a single character.
pub fn stringUpdateStringChar(str: ArcStr, newch: ArcStr, index: i32) -> Result<ArcStr> {
    if newch.is_empty() {
        bail!("newch must not be empty");
    }
    let idx = (index - 1) as usize; // 1-based to 0-based
    let mut chars: Vec<char> = str.chars().collect();
    if idx >= chars.len() {
        bail!("Index {} out of bounds for string with {} characters", index, chars.len());
    }
    let new_char = newch.chars().next().unwrap_or(' ');
    chars[idx] = new_char;
    Ok(format!("{}", chars.into_iter().collect::<String>()))
}

/// Concatenates two strings (s1 + s2).
pub fn stringAppend(s1: ArcStr, s2: ArcStr) -> ArcStr {
    format!("{}{}", s1, s2)
}

/// Compares two strings for equality.
#[inline(always)]
pub fn stringEq(s1: ArcStr, s2: ArcStr) -> bool {
    s1 == s2
}
#[inline(always)]
pub fn stringEqual(s1: ArcStr, s2: ArcStr) -> bool {
    s1 == s2
}

/// Compares two strings lexicographically.
/// Returns negative if s1 < s2, zero if s1 == s2, positive if s1 > s2.
pub fn stringCompare(s1: ArcStr, s2: ArcStr) -> i32 {
    // Byte-by-byte comparison for consistency
    let bytes1 = s1.as_bytes();
    let bytes2 = s2.as_bytes();
    let len = bytes1.len().min(bytes2.len());
    for i in 0..len {
        if bytes1[i] < bytes2[i] {
            return -1;
        }
        if bytes1[i] > bytes2[i] {
            return 1;
        }
    }
    // Length comparison if all compared bytes were equal
    match bytes1.len().cmp(&bytes2.len()) {
        std::cmp::Ordering::Less => -1,
        std::cmp::Ordering::Equal => 0,
        std::cmp::Ordering::Greater => 1,
    }
}

/// Extracts a substring from str.
/// start and stop are 1-based indices (first character is at index 1).
/// Fails for bogus start/stop values.
pub fn substring(str: ArcStr, start: i32, stop: i32) -> Result<ArcStr> {
    if start < 1 || stop < start || start > stop {
        bail!("Invalid substring range: start={}, stop={}", start, stop);
    }
    // `substring` is byte-indexed to match the rest of the MetaModelica
    // string surface (stringLength returns bytes via `.len()`, stringGet
    // returns a byte value). Treating these as char-based here caused
    // bytes/chars mismatches when callers reach for the indices returned
    // by `stringLength` — e.g. `stripBOM` would error with
    // "Stop index 8 exceeds string length 6" on a UTF-8 BOM input
    // because the BOM is 1 char but 3 bytes.
    let start_idx = (start - 1) as usize; // 1-based to 0-based
    let stop_idx = stop as usize;         // 1-based, inclusive -> exclusive
    if stop_idx > str.len() {
        bail!("Stop index {} exceeds string length {}", stop, str.len());
    }
    match str.get(start_idx..stop_idx) {
        Some(slice) => Ok(ArcStr::from(slice)),
        // The byte range falls inside a multi-byte UTF-8 sequence — there is
        // no valid string to return. Surface this rather than silently
        // producing nonsense; the call site should be rewritten to use
        // codepoint indices if that's what it meant.
        None => bail!(
            "substring({}, {}) does not fall on UTF-8 character boundaries",
            start, stop
        ),
    }
}

/// Alias for string_append_list (maps a list of single-char strings to one string).
pub fn listStringCharString(strs: Arc<List<ArcStr>>) -> ArcStr {
    stringAppendList(strs)
}

/// Alias for string_append_list (maps a list of single-char strings to one string).
pub fn stringCharListString(strs: Arc<List<ArcStr>>) -> ArcStr {
    stringAppendList(strs)
}

#[cfg(test)]
#[allow(unused_imports)]
mod tests {
    use super::*;
    use crate::*;
    use std::sync::Arc;
    use std::rc::Rc;
    use arcstr::{literal, ArcStr};
    mod string_char_tests {
        use super::*;

        #[test]
        fn test_string_char_int() {
            assert_eq!(stringCharInt(literal!("A")).unwrap(), 65);
            assert_eq!(stringCharInt(literal!("a")).unwrap(), 97);
            assert_eq!(stringCharInt(literal!("0")).unwrap(), 48);
        }

        #[test]
        fn test_int_string_char() {
            assert_eq!(&*intStringChar(65), "A");
            assert_eq!(&*intStringChar(97), "a");
            assert_eq!(&*intStringChar(48), "0");
            assert_eq!(&*intStringChar(0), "\0");
        }

        #[test]
        fn test_string_int() {
            assert_eq!(stringInt(literal!("42")).unwrap(), 42);
            assert_eq!(stringInt(literal!("-7")).unwrap(), -7);
            assert!(stringInt(literal!("not_a_number")).is_err());
            // strtol semantics: leading whitespace is skipped, trailing
            // junk (including whitespace) is an error.
            assert_eq!(stringInt(literal!("  42")).unwrap(), 42);
            assert!(stringInt(literal!("42 ")).is_err());
        }

        #[test]
        fn test_string_real() {
            assert_eq!(stringReal(literal!("3.14")).unwrap(), OrderedFloat(3.14));
            assert_eq!(stringReal(literal!("-2.5")).unwrap(), OrderedFloat(-2.5));
            assert!(stringReal(literal!("not_a_number")).is_err());
            // strtod semantics: leading whitespace is skipped (e.g. a CSV
            // column " 2.10"), trailing junk is an error.
            assert_eq!(stringReal(literal!(" 2.10")).unwrap(), OrderedFloat(2.10));
            assert!(stringReal(literal!("2.10 x")).is_err());
        }

        #[test]
        fn test_string_list_string_char() {
            let result = stringListStringChar(literal!("abc "));
            assert_eq!(&*result, &List::from_iter([literal!("a"), literal!("b"), literal!("c"), literal!(" ")]));
        }

        #[test]
        fn test_string_append_list() {
            let strs = list![literal!("hello"), literal!(" "), literal!("world")];
            assert_eq!(&*stringAppendList(strs), "hello world");
        }

        #[test]
        fn test_string_delimit_list() {
            let strs: Arc<List<ArcStr>> = list![literal!("x"), literal!("y"), literal!("z")];
            assert_eq!(stringDelimitList(strs, literal!(", ")), "x, y, z");
        }
    }

    mod string_length_tests {
        use super::*;

        #[test]
        fn test_string_length() {
            assert_eq!(stringLength("hello".into()), 5);
            assert_eq!(stringLength("".into()), 0);
        }

        #[test]
        fn test_string_empty() {
            assert!(stringEmpty("".into()));
            assert!(!stringEmpty("hello".into()));
        }
    }

    mod string_get_update_tests {
        use super::*;

        #[test]
        fn test_string_get() {
            assert_eq!(stringGet(literal!("hello"), 1).unwrap(), b'h' as i32);
            assert_eq!(stringGet(literal!("hello"), 5).unwrap(), b'o' as i32);
            assert!(stringGet(literal!("hello"), 0).is_err());
            assert!(stringGet(literal!("hello"), 6).is_err());
        }

        #[test]
        fn test_string_get_string_char() {
            assert_eq!(stringGetStringChar(literal!("hello"), 1).unwrap(), literal!("h"));
            assert_eq!(stringGetStringChar(literal!("hello"), 3).unwrap(), literal!("l"));
            assert_eq!(stringGetStringChar(literal!("hello"), 5).unwrap(), literal!("o"));
            assert!(stringGetStringChar(literal!("hello"), 0).is_err());
            assert!(stringGetStringChar(literal!("hello"), 6).is_err());
        }

        #[test]
        fn test_string_update_string_char() {
            assert_eq!(stringUpdateStringChar(literal!("hello"), literal!("X"), 1).unwrap(), literal!("Xello"));
            assert_eq!(stringUpdateStringChar(literal!("hello"), literal!("X"), 3).unwrap(), literal!("heXlo"));
            assert_eq!(stringUpdateStringChar(literal!("hello"), literal!("X"), 5).unwrap(), literal!("hellX"));
            assert!(stringUpdateStringChar(literal!("hello"), literal!("X"), 0).is_err());
            assert!(stringUpdateStringChar(literal!("hello"), literal!("X"), 6).is_err());
            assert!(stringUpdateStringChar(literal!("hello"), literal!(""), 1).is_err());
        }
    }

    mod string_append_equal_tests {
        use super::*;

        #[test]
        fn test_string_append() {
            assert_eq!(stringAppend(literal!("hello"), literal!(" world")), literal!("hello world"));
            assert_eq!(stringAppend(literal!(""), literal!("hello")), literal!("hello"));
            assert_eq!(stringAppend(literal!("hello"), literal!("")), literal!("hello"));
        }

        #[test]
        fn test_string_eq() {
            assert!(stringEq(literal!("abc"), literal!("abc")));
            assert!(!stringEq(literal!("abc"), literal!("abd")));
            assert!(!stringEq(literal!(""), literal!("abc")));
        }

        #[test]
        fn test_string_equal() {
            assert!(stringEqual(literal!("abc"), literal!("abc")));
            assert!(!stringEqual(literal!("abc"), literal!("abd")));
        }
    }

    mod string_compare_test {
        use super::*;

        #[test]
        fn test_string_compare() {
            assert!(stringCompare(literal!("abc"), literal!("abd")) < 0);
            assert_eq!(stringCompare(literal!("abc"), literal!("abc")), 0);
            assert!(stringCompare(literal!("abd"), literal!("abc")) > 0);
            assert!(stringCompare(literal!("ab"), literal!("abc")) < 0);
            assert!(stringCompare(literal!("abc"), literal!("ab")) > 0);
        }
    }

    mod substring_tests {
        use super::*;

        #[test]
        fn test_substring_basic() {
            assert_eq!(*substring(literal!("hello world"), 1, 5).unwrap(), "hello".to_string());
            assert_eq!(*substring(literal!("hello world"), 7, 11).unwrap(), "world".to_string());
            assert_eq!(*substring(literal!("hello"), 3, 3).unwrap(), "l".to_string());
            assert_eq!(*substring(literal!("hello"), 1, 5).unwrap(), "hello".to_string());
        }

        #[test]
        fn test_substring_errors() {
            assert!(substring(literal!("hello"), 0, 3).is_err());  // start < 1
            assert!(substring(literal!("hello"), 3, 2).is_err());  // stop < start
            assert!(substring(literal!("hello"), 1, 6).is_err());  // stop out of bounds
            assert!(substring(literal!("hello"), 6, 7).is_err());  // start out of bounds
        }
    }

    mod list_string_tests {
        use super::*;

        #[test]
        fn test_list_string_char_string() {
            let strs: Arc<List<ArcStr>> = list![literal!("a"), literal!("b"), literal!("c")];
            assert_eq!(&*listStringCharString(strs), "abc");
        }

        #[test]
        fn test_string_char_list_string() {
            let strs: Arc<List<ArcStr>> = list![literal!("a"), literal!("b"), literal!("c")];
            assert_eq!(&*stringCharListString(strs), "abc");
        }
    }
}
