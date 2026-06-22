// Tests for crate::StringUtil
//
// The Rust source is auto-generated from:
//   ~/OpenModelica/OMCompiler/Compiler/Util/StringUtil.mo
//
// Position indices are 1-based throughout (MetaModelica convention).
// NO_POS (= 0) is returned when a character is not found.

use anyhow::Result;
use arcstr::{ArcStr, literal};
use crate::StringUtil as S;

// ── constants ────────────────────────────────────────────────────────────────

const NO_POS: i32 = 0; // same as StringUtil::NO_POS
const CHAR_A_UPPER: i32 = 65;
const CHAR_Z_UPPER: i32 = 90;
const CHAR_A_LOWER: i32 = 97;
const CHAR_Z_LOWER: i32 = 122;
const CHAR_NEWLINE: i32 = 10;
const CHAR_SPACE: i32 = 32;
const CHAR_DASH: i32 = 45;
const CHAR_DOT: i32 = 46;

// ── isAlpha ───────────────────────────────────────────────────────────────────

#[test]
fn test_is_alpha_uppercase() {
    assert!(S::isAlpha(CHAR_A_UPPER), "A (65) should be alpha");
    assert!(S::isAlpha(CHAR_Z_UPPER), "Z (90) should be alpha");
    assert!(S::isAlpha(75), "K (75) should be alpha");
}

#[test]
fn test_is_alpha_lowercase() {
    assert!(S::isAlpha(CHAR_A_LOWER), "a (97) should be alpha");
    assert!(S::isAlpha(CHAR_Z_LOWER), "z (122) should be alpha");
    assert!(S::isAlpha(109), "m (109) should be alpha");
}

#[test]
fn test_is_alpha_digits_are_not() {
    assert!(!S::isAlpha(48), "digit '0' (48) should not be alpha");
    assert!(!S::isAlpha(57), "digit '9' (57) should not be alpha");
}

#[test]
fn test_is_alpha_special_chars_are_not() {
    assert!(!S::isAlpha(CHAR_SPACE), "space should not be alpha");
    assert!(!S::isAlpha(CHAR_DOT), "dot should not be alpha");
    assert!(!S::isAlpha(CHAR_DASH), "dash should not be alpha");
    assert!(!S::isAlpha(CHAR_NEWLINE), "newline should not be alpha");
    assert!(!S::isAlpha(64), "@ (64) is just below 'A', should not be alpha");
    assert!(!S::isAlpha(91), "[ (91) is just above 'Z', should not be alpha");
    assert!(!S::isAlpha(96), "` (96) is just below 'a', should not be alpha");
    assert!(!S::isAlpha(123), "{{ (123) is just above 'z', should not be alpha");
}

// ── quote ─────────────────────────────────────────────────────────────────────
//
// BUG: The `quote` function uses `literal!("\\\"")` which produces a 2-char
// string containing backslash + double-quote (`\"`), when it should produce a
// 1-char string containing just a double-quote (`"`).
//
// MetaModelica source: `outString := "\"" + inString + "\""` where `"\""` is
// a single double-quote character (ASCII 34).
//
// Rust translation: `literal!("\\\"")` = the 2-char string `\"` (wrong).
// Should be:        `literal!("\"")` = the 1-char string `"` (correct).
//
// Consequence:
//   quote("")     → `\"\"` (4 chars: backslash,dquote,backslash,dquote)
//                   instead of `""` (2 chars: dquote,dquote)
//   quote("hello") → `\"hello\"` (9 chars) instead of `"hello"` (7 chars)

#[test]
fn test_quote_empty() {
    // Expected (correct): `""` (two double-quote chars, 2 chars total)
    // Actual (buggy):     `\"\"` (backslash+dquote+backslash+dquote, 4 chars)
    assert_eq!(S::quote(literal!("")), literal!("\"\""),
        "BUG: quote uses backslash+dquote instead of just dquote");
}

#[test]
fn test_quote_word() {
    // Expected (correct): `"hello"` (7 chars)
    // Actual (buggy):     `\"hello\"` (9 chars with literal backslashes)
    assert_eq!(S::quote(literal!("hello")), literal!("\"hello\""),
        "BUG: quote wraps with backslash+dquote instead of just dquote");
}

// ── rest ─────────────────────────────────────────────────────────────────────

#[test]
fn test_rest_single_char() -> Result<()> {
    // StringUtil.mo guards the single-char case explicitly:
    //   rest := if stringLength(str) == 1 then "" else substring(str, 2, stringLength(str));
    // so rest("a") returns "" rather than erroring on the would-be
    // out-of-range substring(str, 2, 1).
    assert_eq!(S::rest(literal!("a"))?, literal!(""));
    Ok(())
}

#[test]
fn test_rest_multi_char() -> Result<()> {
    // rest("hello") = substring("hello", 2, 5) = "ello"
    assert_eq!(S::rest(literal!("hello"))?, literal!("ello"));
    Ok(())
}

#[test]
fn test_rest_two_chars() -> Result<()> {
    // rest("ab") = substring("ab", 2, 2) = "b"
    assert_eq!(S::rest(literal!("ab"))?, literal!("b"));
    Ok(())
}

// ── endsWithNewline ───────────────────────────────────────────────────────────

#[test]
fn test_ends_with_newline_true() {
    let s: ArcStr = ArcStr::from("hello\n");
    assert!(S::endsWithNewline(s));
}

#[test]
fn test_ends_with_newline_false() {
    assert!(!S::endsWithNewline(literal!("hello")));
    assert!(!S::endsWithNewline(literal!("hello ")));
}

#[test]
fn test_ends_with_newline_only_newline() {
    let s: ArcStr = ArcStr::from("\n");
    assert!(S::endsWithNewline(s));
}

#[test]
fn test_ends_with_newline_multiple_newlines() {
    let s: ArcStr = ArcStr::from("a\nb\n");
    assert!(S::endsWithNewline(s));
}

// ── findChar ─────────────────────────────────────────────────────────────────

#[test]
fn test_find_char_first_position() {
    // findChar("hello", ord('h'), 1, 0) should return 1
    assert_eq!(S::findChar(literal!("hello"), 104 /*'h'*/, 1, 0), 1);
}

#[test]
fn test_find_char_middle_position() {
    // findChar("hello", ord('l'), 1, 0) should return 3 (first 'l')
    assert_eq!(S::findChar(literal!("hello"), 108 /*'l'*/, 1, 0), 3);
}

#[test]
fn test_find_char_last_position() {
    // findChar("hello", ord('o'), 1, 0) should return 5
    assert_eq!(S::findChar(literal!("hello"), 111 /*'o'*/, 1, 0), 5);
}

#[test]
fn test_find_char_not_found() {
    // findChar("hello", ord('x'), 1, 0) should return NO_POS (0)
    assert_eq!(S::findChar(literal!("hello"), 120 /*'x'*/, 1, 0), NO_POS);
}

#[test]
fn test_find_char_start_pos_limits_search() {
    // findChar("hello", ord('h'), 2, 0) starts after 'h', so should not find it
    assert_eq!(S::findChar(literal!("hello"), 104 /*'h'*/, 2, 0), NO_POS);
}

#[test]
fn test_find_char_end_pos_limits_search() {
    // findChar("hello", ord('o'), 1, 4) ends before 'o' at pos 5, so NO_POS
    assert_eq!(S::findChar(literal!("hello"), 111 /*'o'*/, 1, 4), NO_POS);
}

#[test]
fn test_find_char_exact_bounds() {
    // findChar("hello", ord('o'), 1, 5) includes 'o', so returns 5
    assert_eq!(S::findChar(literal!("hello"), 111 /*'o'*/, 1, 5), 5);
}

#[test]
fn test_find_char_start_below_1_clamps_to_1() {
    // findChar("hello", ord('h'), -5, 0): start clamped to 1, should find 'h' at 1
    assert_eq!(S::findChar(literal!("hello"), 104 /*'h'*/, -5, 0), 1);
}

#[test]
fn test_find_char_dot() {
    assert_eq!(S::findChar(literal!("file.txt"), CHAR_DOT, 1, 0), 5);
}

// ── rfindChar ────────────────────────────────────────────────────────────────

#[test]
fn test_rfind_char_last_occurrence() {
    // rfindChar("hello", ord('l'), 0, 1) - searches backwards, finds last 'l' at 4
    assert_eq!(S::rfindChar(literal!("hello"), 108 /*'l'*/, 0, 1), 4);
}

#[test]
fn test_rfind_char_only_occurrence() {
    // rfindChar("hello", ord('h'), 0, 1) - searches backwards, finds 'h' at 1
    assert_eq!(S::rfindChar(literal!("hello"), 104 /*'h'*/, 0, 1), 1);
}

#[test]
fn test_rfind_char_not_found() {
    // rfindChar("hello", ord('x'), 0, 1) should return NO_POS
    assert_eq!(S::rfindChar(literal!("hello"), 120 /*'x'*/, 0, 1), NO_POS);
}

#[test]
fn test_rfind_char_limited_by_start_pos() {
    // rfindChar("hello", ord('h'), 3, 1): searches from pos 3 backwards to 1
    // 'h' is at position 1, 3 >= 1 so should find it
    assert_eq!(S::rfindChar(literal!("hello"), 104 /*'h'*/, 3, 1), 1);
}

#[test]
fn test_rfind_char_limited_by_end_pos() {
    // rfindChar("hello", ord('h'), 0, 2): end_pos = max(2,1) = 2
    // searches backwards from 5 (len) down to 2, 'h' is at 1 (below end_pos), NO_POS
    assert_eq!(S::rfindChar(literal!("hello"), 104 /*'h'*/, 0, 2), NO_POS);
}

#[test]
fn test_rfind_char_dot_in_filename() {
    // rfindChar("file.tar.gz", '.', 0, 1) should find last '.' at pos 9
    assert_eq!(S::rfindChar(literal!("file.tar.gz"), CHAR_DOT, 0, 1), 9);
}

// ── findCharNot ──────────────────────────────────────────────────────────────

#[test]
fn test_find_char_not_spaces() {
    // findCharNot("   hello", CHAR_SPACE, 1, 0) should find 'h' at pos 4
    assert_eq!(S::findCharNot(literal!("   hello"), CHAR_SPACE, 1, 0), 4);
}

#[test]
fn test_find_char_not_all_matching() {
    // findCharNot("   ", CHAR_SPACE, 1, 0) - all spaces, should return NO_POS
    assert_eq!(S::findCharNot(literal!("   "), CHAR_SPACE, 1, 0), NO_POS);
}

#[test]
fn test_find_char_not_first_char() {
    // findCharNot("hello", CHAR_SPACE, 1, 0) - 'h' is not a space, returns 1
    assert_eq!(S::findCharNot(literal!("hello"), CHAR_SPACE, 1, 0), 1);
}

// ── rfindCharNot ─────────────────────────────────────────────────────────────

#[test]
fn test_rfind_char_not_trailing_spaces() {
    // rfindCharNot("hello   ", CHAR_SPACE, 0, 1) should find 'o' at pos 5
    assert_eq!(S::rfindCharNot(literal!("hello   "), CHAR_SPACE, 0, 1), 5);
}

#[test]
fn test_rfind_char_not_all_matching() {
    // rfindCharNot("   ", CHAR_SPACE, 0, 1) - all spaces, should return NO_POS
    assert_eq!(S::rfindCharNot(literal!("   "), CHAR_SPACE, 0, 1), NO_POS);
}

#[test]
fn test_rfind_char_not_last_char() {
    // rfindCharNot("hello", CHAR_SPACE, 0, 1): searches backwards, 'o' at pos 5 is not space
    assert_eq!(S::rfindCharNot(literal!("hello"), CHAR_SPACE, 0, 1), 5);
}

// ── stripFileExtension ───────────────────────────────────────────────────────

#[test]
fn test_strip_file_extension_basic() -> Result<()> {
    assert_eq!(S::stripFileExtension(literal!("file.txt"))?, literal!("file"));
    Ok(())
}

#[test]
fn test_strip_file_extension_multiple_dots() -> Result<()> {
    // rfindChar finds LAST dot, so strips only the last extension
    assert_eq!(S::stripFileExtension(literal!("file.tar.gz"))?, literal!("file.tar"));
    Ok(())
}

#[test]
fn test_strip_file_extension_no_extension() -> Result<()> {
    // No dot -> rfindChar returns NO_POS -> filename unchanged
    assert_eq!(S::stripFileExtension(literal!("readme"))?, literal!("readme"));
    Ok(())
}

#[test]
fn test_strip_file_extension_dot_at_start() -> Result<()> {
    // ".hidden" has dot at pos 1 -> substring(s, 1, 0) which is invalid
    // so returns an Err or empty string depending on implementation
    // Actually: pos=1, filename = substring(s, 1, pos-1) = substring(s, 1, 0) -> error
    let result = S::stripFileExtension(literal!(".hidden"));
    // substring with stop=0 < start=1 should error
    assert!(result.is_err(), "dot at start: substring(s,1,0) should fail");
    Ok(())
}

// ── equalIgnoreSpace ─────────────────────────────────────────────────────────

#[test]
fn test_equal_ignore_space_identical() -> Result<()> {
    assert!(S::equalIgnoreSpace(literal!("hello"), literal!("hello"))?);
    Ok(())
}

#[test]
fn test_equal_ignore_space_both_empty() -> Result<()> {
    assert!(S::equalIgnoreSpace(literal!(""), literal!(""))?);
    Ok(())
}

#[test]
fn test_equal_ignore_space_spaces_stripped() -> Result<()> {
    // "h e l l o" vs "hello": same non-space chars in same order
    assert!(S::equalIgnoreSpace(literal!("h e l l o"), literal!("hello"))?);
    Ok(())
}

#[test]
fn test_equal_ignore_space_different_chars_same_count() -> Result<()> {
    // BUG: equalIgnoreSpace does NOT compare character values, only counts non-spaces.
    // "abc" vs "xyz" should return false (different content) but implementation
    // returns true because both have 3 non-space characters.
    // Expected (correct): false
    // Actual (buggy): true
    let result = S::equalIgnoreSpace(literal!("abc"), literal!("xyz"))?;
    assert!(!result, "equalIgnoreSpace does not compare char values: 'abc' != 'xyz'");
    Ok(())
}

#[test]
fn test_equal_ignore_space_different_length() -> Result<()> {
    // "ab" vs "abc": s1 has 2 non-spaces, s2 has 3 -> after consuming s1's chars,
    // s2 still has 'c' remaining -> returns false
    assert!(!S::equalIgnoreSpace(literal!("ab"), literal!("abc"))?);
    Ok(())
}

#[test]
fn test_equal_ignore_space_s1_longer() -> Result<()> {
    // "abc" vs "ab": when processing s1's 'c', s2 has no more non-spaces -> false
    assert!(!S::equalIgnoreSpace(literal!("abc"), literal!("ab"))?);
    Ok(())
}

#[test]
fn test_equal_ignore_space_only_spaces() -> Result<()> {
    // "   " vs "": both have 0 non-space chars -> true
    assert!(S::equalIgnoreSpace(literal!("   "), literal!(""))?);
    Ok(())
}

// ── stripBOM ─────────────────────────────────────────────────────────────────

#[test]
fn test_strip_bom_no_bom() -> Result<()> {
    let (s, bom) = S::stripBOM(literal!("Hello"))?;
    assert_eq!(s, literal!("Hello"));
    assert_eq!(bom, literal!(""));
    Ok(())
}

#[test]
fn test_strip_bom_too_short() -> Result<()> {
    let (s, bom) = S::stripBOM(literal!("Hi"))?;
    assert_eq!(s, literal!("Hi"));
    assert_eq!(bom, literal!(""));
    Ok(())
}

#[test]
fn test_strip_bom_with_bom_and_content() -> Result<()> {
    // BUG: stripBOM mixes byte-based operations (stringGet, .len()) with
    // char-based operations (substring). The BOM U+FEFF is 1 Unicode char
    // but 3 UTF-8 bytes. After checking bytes 1-3 for the BOM pattern,
    // the function calls `substring(s, 4, s.len())` where s.len() returns
    // bytes (8 for BOM+"Hello") but substring counts Unicode chars (6).
    // This causes "Stop index 8 exceeds string length 6".
    let bom_str = "\u{FEFF}"; // 1 Unicode char, 3 UTF-8 bytes
    let input = ArcStr::from(format!("{}Hello", bom_str));
    // The call should succeed and return ("Hello", "Hel"), but due to the
    // bytes/chars mismatch it actually errors.
    let (s, _bom) = S::stripBOM(input)?;
    assert!(s == "Hello",
        "BUG: stripBOM fails with real UTF-8 BOM due to byte/char inconsistency");
    Ok(())
}

#[test]
fn test_strip_bom_with_bom_short_content() -> Result<()> {
    // BOM + "Hi" (only 2 chars after BOM)
    // After stripping BOM: s = "Hi" (len=2)
    // bom = substring("Hi", 1, 3) -> error (stop > len)
    let bom_bytes = [239u8, 187u8, 191u8];
    let input = format!("{}Hi",
        std::str::from_utf8(&bom_bytes).unwrap_or("\u{FEFF}"));
    let input_arcstr = ArcStr::from(input);
    let (s, _bom) = S::stripBOM(input_arcstr)?;
    // substring("Hi", 1, 3) should fail because stop=3 > len=2
    assert!(s == "Hi",
        "substring out of bounds: bom=substring(stripped, 1, 3) fails when stripped is 'Hi'");
    Ok(())
}
