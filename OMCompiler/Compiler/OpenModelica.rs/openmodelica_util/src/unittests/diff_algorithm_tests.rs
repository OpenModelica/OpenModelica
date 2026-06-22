// Tests for crate::DiffAlgorithm
//
// The Rust source is auto-generated from:
//   ~/OpenModelica/OMCompiler/Compiler/Util/DiffAlgorithm.mo
//
// DiffAlgorithm::diff computes a diff of two lists of tokens, returning a
// list of (Diff, tokens) pairs tagged with Add, Delete, or Equal.
//
// printDiffTerminalColor, printDiffXml, and printActual inherit
// `partialPrintDiff`'s algorithm via `extends`, specialising its
// `replaceable package DiffStrings` constants; they are tested below.
//
// Known bugs / limitations found while writing these tests are documented
// inline with "Bug:" prefixes.

use anyhow::Result;
use std::sync::Arc;
use metamodelica::*;
use arcstr::ArcStr;
use crate::DiffAlgorithm::{self, Diff};

// ---------------------------------------------------------------------------
// helper function types
// ---------------------------------------------------------------------------

fn str_equals(a: ArcStr, b: ArcStr) -> Result<bool> {
    Ok(a == b)
}

/// For these tests every token is treated as non-whitespace.
fn not_whitespace(_s: ArcStr) -> Result<bool> {
    Ok(false)
}

fn to_str(s: ArcStr) -> Result<ArcStr> {
    Ok(s)
}

// ---------------------------------------------------------------------------
// helper: collect result list into a Vec<(Diff, Vec<ArcStr>)>
// ---------------------------------------------------------------------------

fn collect_diff(
    result: Arc<metamodelica::List<(Diff, Arc<metamodelica::List<ArcStr>>)>>,
) -> Vec<(Diff, Vec<String>)> {
    let mut out = Vec::new();
    let mut node = result;
    loop {
        match node.as_ref() {
            metamodelica::List::Nil => break,
            metamodelica::List::Cons { head: (d, ts), tail } => {
                let mut tokens = Vec::new();
                let mut t = Arc::clone(ts);
                loop {
                    match t.as_ref() {
                        metamodelica::List::Nil => break,
                        metamodelica::List::Cons { head, tail: t2 } => {
                            tokens.push(head.to_string());
                            t = Arc::clone(t2);
                        }
                    }
                }
                out.push((*d, tokens));
                node = Arc::clone(tail);
            }
        }
    }
    out
}

fn run_diff(seq1: &[&str], seq2: &[&str]) -> Result<Vec<(Diff, Vec<String>)>> {
    let list1: Arc<metamodelica::List<ArcStr>> = seq1
        .iter()
        .rev()
        .fold(metamodelica::nil(), |acc, &s| cons(arcstr::format!("{}", s), acc));
    let list2: Arc<metamodelica::List<ArcStr>> = seq2
        .iter()
        .rev()
        .fold(metamodelica::nil(), |acc, &s| cons(arcstr::format!("{}", s), acc));

    let result = DiffAlgorithm::diff(
        list1,
        list2,
        Arc::new(str_equals),
        Arc::new(not_whitespace),
        Arc::new(not_whitespace),
        Arc::new(to_str),
    )?;
    Ok(collect_diff(result))
}

// ---------------------------------------------------------------------------
// empty sequences
// ---------------------------------------------------------------------------

/// diff([], []) should produce an empty result list.
#[test]
fn diff_both_empty_gives_empty_result() -> Result<()> {
    let result = run_diff(&[], &[])?;
    assert!(
        result.is_empty(),
        "expected empty diff result, got: {:?}", result
    );
    Ok(())
}

// ---------------------------------------------------------------------------
// identical sequences
// ---------------------------------------------------------------------------

/// diff([a], [a]) should produce [(Equal, [a])].
#[test]
fn diff_single_identical_element_is_equal() -> Result<()> {
    let result = run_diff(&["a"], &["a"])?;
    assert_eq!(result.len(), 1, "expected 1 chunk, got: {:?}", result);
    assert_eq!(result[0].0, Diff::Equal, "expected Equal tag, got: {:?}", result[0].0);
    assert_eq!(result[0].1, vec!["a"], "expected [a], got: {:?}", result[0].1);
    Ok(())
}

/// diff([a,b,c], [a,b,c]) should produce [(Equal, [a,b,c])].
#[test]
fn diff_identical_sequence_gives_single_equal_chunk() -> Result<()> {
    let result = run_diff(&["a", "b", "c"], &["a", "b", "c"])?;
    assert_eq!(result.len(), 1, "expected 1 chunk, got: {:?}", result);
    assert_eq!(result[0].0, Diff::Equal);
    assert_eq!(result[0].1, vec!["a", "b", "c"]);
    Ok(())
}

// ---------------------------------------------------------------------------
// pure additions
// ---------------------------------------------------------------------------

/// diff([], [x]) should produce [(Add, [x])].
#[test]
fn diff_empty_vs_single_element_is_add() -> Result<()> {
    let result = run_diff(&[], &["x"])?;
    assert_eq!(result.len(), 1, "expected 1 chunk, got: {:?}", result);
    assert_eq!(result[0].0, Diff::Add, "expected Add tag, got: {:?}", result[0].0);
    assert_eq!(result[0].1, vec!["x"]);
    Ok(())
}

/// diff([], [x,y,z]) should produce [(Add, [x,y,z])].
#[test]
fn diff_empty_vs_sequence_is_single_add_chunk() -> Result<()> {
    let result = run_diff(&[], &["x", "y", "z"])?;
    assert_eq!(result.len(), 1, "expected 1 chunk");
    assert_eq!(result[0].0, Diff::Add);
    assert_eq!(result[0].1, vec!["x", "y", "z"]);
    Ok(())
}

// ---------------------------------------------------------------------------
// pure deletions
// ---------------------------------------------------------------------------

/// diff([x], []) should produce [(Delete, [x])].
#[test]
fn diff_single_element_vs_empty_is_delete() -> Result<()> {
    let result = run_diff(&["x"], &[])?;
    assert_eq!(result.len(), 1, "expected 1 chunk, got: {:?}", result);
    assert_eq!(result[0].0, Diff::Delete, "expected Delete tag, got: {:?}", result[0].0);
    assert_eq!(result[0].1, vec!["x"]);
    Ok(())
}

/// diff([x,y,z], []) should produce [(Delete, [x,y,z])].
#[test]
fn diff_sequence_vs_empty_is_single_delete_chunk() -> Result<()> {
    let result = run_diff(&["x", "y", "z"], &[])?;
    assert_eq!(result.len(), 1, "expected 1 chunk");
    assert_eq!(result[0].0, Diff::Delete);
    assert_eq!(result[0].1, vec!["x", "y", "z"]);
    Ok(())
}

// ---------------------------------------------------------------------------
// suffix added
// ---------------------------------------------------------------------------

/// diff([a], [a, b]) should contain an Equal chunk for [a] and an Add chunk
/// for [b].  The order of chunks must be Equal then Add.
#[test]
fn diff_suffix_addition_produces_equal_then_add() -> Result<()> {
    let result = run_diff(&["a"], &["a", "b"])?;
    // Flatten and verify all tokens appear and tags are correct.
    let equal_chunks: Vec<_> = result.iter().filter(|(d, _)| *d == Diff::Equal).collect();
    let add_chunks: Vec<_> = result.iter().filter(|(d, _)| *d == Diff::Add).collect();
    assert!(!equal_chunks.is_empty(), "expected at least one Equal chunk");
    assert!(!add_chunks.is_empty(), "expected at least one Add chunk");
    let equal_tokens: Vec<String> = equal_chunks.iter().flat_map(|(_, ts)| ts.iter().cloned()).collect();
    let add_tokens: Vec<String> = add_chunks.iter().flat_map(|(_, ts)| ts.iter().cloned()).collect();
    assert!(equal_tokens.contains(&"a".to_string()), "Equal chunk must contain 'a'");
    assert!(add_tokens.contains(&"b".to_string()), "Add chunk must contain 'b'");
    // Check ordering: Equal must come before Add in the result.
    let first_equal_pos = result.iter().position(|(d, _)| *d == Diff::Equal).unwrap();
    let first_add_pos  = result.iter().position(|(d, _)| *d == Diff::Add).unwrap();
    assert!(
        first_equal_pos < first_add_pos,
        "Equal chunk should appear before Add chunk, positions: equal={}, add={}",
        first_equal_pos, first_add_pos
    );
    Ok(())
}

// ---------------------------------------------------------------------------
// prefix deleted
// ---------------------------------------------------------------------------

/// diff([a, b], [b]) should contain a Delete chunk for [a] and an Equal chunk
/// for [b].
#[test]
fn diff_prefix_deletion_produces_delete_then_equal() -> Result<()> {
    let result = run_diff(&["a", "b"], &["b"])?;
    let delete_chunks: Vec<_> = result.iter().filter(|(d, _)| *d == Diff::Delete).collect();
    let equal_chunks: Vec<_>  = result.iter().filter(|(d, _)| *d == Diff::Equal).collect();
    assert!(!delete_chunks.is_empty(), "expected at least one Delete chunk");
    assert!(!equal_chunks.is_empty(), "expected at least one Equal chunk");
    let del_tokens: Vec<String> = delete_chunks.iter().flat_map(|(_, ts)| ts.iter().cloned()).collect();
    let eq_tokens:  Vec<String> = equal_chunks.iter().flat_map(|(_, ts)| ts.iter().cloned()).collect();
    assert!(del_tokens.contains(&"a".to_string()), "Delete chunk must contain 'a'");
    assert!(eq_tokens.contains(&"b".to_string()), "Equal chunk must contain 'b'");
    Ok(())
}

// ---------------------------------------------------------------------------
// middle element changed
// ---------------------------------------------------------------------------

/// diff([a, X, c], [a, Y, c]) should keep 'a' and 'c' as Equal and mark 'X'
/// as Deleted and 'Y' as Added.
#[test]
fn diff_middle_substitution_preserves_surrounding_context() -> Result<()> {
    let result = run_diff(&["a", "X", "c"], &["a", "Y", "c"])?;
    let all_tags: Vec<Diff> = result.iter().map(|(d, _)| *d).collect();
    // 'a' and 'c' must appear in Equal chunks.
    let equal_tokens: Vec<String> = result
        .iter()
        .filter(|(d, _)| *d == Diff::Equal)
        .flat_map(|(_, ts)| ts.iter().cloned())
        .collect();
    assert!(equal_tokens.contains(&"a".to_string()), "'a' must be Equal; chunks={:?}", result);
    assert!(equal_tokens.contains(&"c".to_string()), "'c' must be Equal; chunks={:?}", result);
    // 'X' must appear in a Delete chunk.
    let del_tokens: Vec<String> = result
        .iter()
        .filter(|(d, _)| *d == Diff::Delete)
        .flat_map(|(_, ts)| ts.iter().cloned())
        .collect();
    assert!(del_tokens.contains(&"X".to_string()), "'X' must be Deleted; chunks={:?}", result);
    // 'Y' must appear in an Add chunk.
    let add_tokens: Vec<String> = result
        .iter()
        .filter(|(d, _)| *d == Diff::Add)
        .flat_map(|(_, ts)| ts.iter().cloned())
        .collect();
    assert!(add_tokens.contains(&"Y".to_string()), "'Y' must be Added; chunks={:?}", result);
    Ok(())
}

// ---------------------------------------------------------------------------
// Diff enum ordering (used internally as integer ordinals)
// ---------------------------------------------------------------------------

/// The Diff enum is repr(i32) with Add=1, Delete=2, Equal=3.
/// These ordinals are used internally for comparison; verify the values are
/// stable.
#[test]
fn diff_enum_ordinals_match_metamodelica_source() {
    assert_eq!(Diff::Add    as i32, 1);
    assert_eq!(Diff::Delete as i32, 2);
    assert_eq!(Diff::Equal  as i32, 3);
}

// ---------------------------------------------------------------------------
// print functions: printActual / printDiffXml / printDiffTerminalColor inherit
// `partialPrintDiff`'s algorithm via `extends`, specialising its `replaceable
// package DiffStrings` constants. printActual suppresses deletions
// (printDelete=false); printDiffXml wraps each chunk in tags.
// ---------------------------------------------------------------------------

/// One diff chunk `(tag, [tokens...])`.
fn chunk(tag: Diff, tokens: &[&str]) -> (Diff, Arc<metamodelica::List<ArcStr>>) {
    let toks = tokens
        .iter()
        .rev()
        .fold(metamodelica::nil(), |acc, &s| cons(arcstr::format!("{}", s), acc));
    (tag, toks)
}

/// A sequence with one equal, one added and one deleted chunk.
fn sample_seq() -> Arc<metamodelica::List<(Diff, Arc<metamodelica::List<ArcStr>>)>> {
    [
        chunk(Diff::Equal, &["a"]),
        chunk(Diff::Add, &["b"]),
        chunk(Diff::Delete, &["c"]),
    ]
    .into_iter()
    .rev()
    .fold(metamodelica::nil(), |acc, c| cons(c, acc))
}

/// printActual prints equal + added tokens but suppresses deletions.
#[test]
fn print_actual_suppresses_deletions() {
    let s = DiffAlgorithm::printActual::<ArcStr>(sample_seq(), Arc::new(to_str)).unwrap();
    assert_eq!(s.as_str(), "ab");
}

/// printDiffXml wraps each chunk in its tag, including deletions.
#[test]
fn print_diff_xml_wraps_in_tags() {
    let s = DiffAlgorithm::printDiffXml::<ArcStr>(sample_seq(), Arc::new(to_str)).unwrap();
    assert_eq!(s.as_str(), "<equal>a</equal><add>b</add><del>c</del>");
}

/// printDiffTerminalColor leaves equal text bare and brackets add/del in the
/// terminal control sequences supplied by its `DiffStrings` override.
#[test]
fn print_diff_terminal_color_brackets_changes() {
    let s = DiffAlgorithm::printDiffTerminalColor::<ArcStr>(sample_seq(), Arc::new(to_str)).unwrap();
    assert_eq!(s.as_str(), "a\u{1b}[4;32mb\u{1b}[0m\u{1b}[9;31mc\u{1b}[0m");
}

/// All three printers return the empty string for an empty diff.
#[test]
fn print_functions_empty_input() {
    assert_eq!(DiffAlgorithm::printActual::<ArcStr>(metamodelica::nil(), Arc::new(to_str)).unwrap().as_str(), "");
    assert_eq!(DiffAlgorithm::printDiffXml::<ArcStr>(metamodelica::nil(), Arc::new(to_str)).unwrap().as_str(), "");
    assert_eq!(DiffAlgorithm::printDiffTerminalColor::<ArcStr>(metamodelica::nil(), Arc::new(to_str)).unwrap().as_str(), "");
}
