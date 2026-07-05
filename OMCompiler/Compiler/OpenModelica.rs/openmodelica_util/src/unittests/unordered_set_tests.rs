// Tests for crate::UnorderedSet.
//
// The Rust source is auto-generated from:
//   ~/OpenModelica/OMCompiler/Compiler/Util/UnorderedSet.mo
//
// UnorderedSet is a generic hash-set backed by a bucket array stored inside a
// Mutable wrapper.  All mutation happens in-place through Arc.
//
// We use ArcStr elements with stringHashDjb2 / stringEq throughout.

use anyhow::Result;
use std::sync::Arc;
use metamodelica::*;
use arcstr::{ArcStr, literal};
use crate::UnorderedSet as US;

// ── hash / eq helpers ────────────────────────────────────────────────────────

fn hash_str(k: ArcStr) -> Result<i32> {
    Ok(stringHashDjb2(k))
}

fn eq_str(a: ArcStr, b: ArcStr) -> Result<bool> {
    Ok(stringEq(a, b))
}

// ── construction helpers ──────────────────────────────────────────────────────

fn empty_set() -> Arc<US::UnorderedSet<ArcStr>> {
    // Callbacks are now `Arc<dyn Fn(...) + 'static>` aliases (see
    // `fmt_param_ty` in mmtorust); wrap each fn-item in `Arc::new` so
    // the unsized coercion to the trait object happens at the call
    // boundary.
    US::new(Arc::new(hash_str), Arc::new(eq_str), 13)
}

fn set_of(keys: &[&str]) -> Result<Arc<US::UnorderedSet<ArcStr>>> {
    let s = empty_set();
    for k in keys {
        US::add(arcstr::format!("{}", k), s.clone())?;
    }
    Ok(s)
}

/// toList as a sorted Vec<String>.
fn to_sorted_vec(s: Arc<US::UnorderedSet<ArcStr>>) -> Vec<String> {
    let lst = US::toList(s);
    let mut v: Vec<String> = vec![];
    for k in &*lst { v.push(k.to_string()); }
    v.sort();
    v
}

// ── new / isEmpty / size ──────────────────────────────────────────────────────

#[test]
fn test_new_is_empty() {
    let s = empty_set();
    assert!(US::isEmpty(s.clone()));
    assert_eq!(US::size(s), 0);
}

#[test]
fn test_non_empty_is_not_empty() -> Result<()> {
    let s = set_of(&["hello"])?;
    assert!(!US::isEmpty(s.clone()));
    assert_eq!(US::size(s), 1);
    Ok(())
}

// ── add / contains / get ──────────────────────────────────────────────────────

#[test]
fn test_add_and_contains() -> Result<()> {
    let s = set_of(&["alpha", "beta", "gamma"])?;
    assert!(US::contains(literal!("alpha"), s.clone())?);
    assert!(US::contains(literal!("beta"),  s.clone())?);
    assert!(US::contains(literal!("gamma"), s.clone())?);
    Ok(())
}

#[test]
fn test_contains_absent_key_returns_false() -> Result<()> {
    let s = set_of(&["a", "b"])?;
    assert!(!US::contains(literal!("c"), s)?);
    Ok(())
}

#[test]
fn test_get_present_key_returns_some() -> Result<()> {
    let s = set_of(&["present"])?;
    let result = US::get(literal!("present"), s)?;
    assert_eq!(result, Some(literal!("present")));
    Ok(())
}

#[test]
fn test_get_absent_key_returns_none() -> Result<()> {
    let s = set_of(&["present"])?;
    let result = US::get(literal!("absent"), s)?;
    assert_eq!(result, None);
    Ok(())
}

#[test]
fn test_get_or_fail_present_key() -> Result<()> {
    let s = set_of(&["key"])?;
    let result = US::getOrFail(literal!("key"), s)?;
    assert_eq!(result, literal!("key"));
    Ok(())
}

#[test]
fn test_get_or_fail_absent_key_fails() -> Result<()> {
    let s = set_of(&["key"])?;
    let result = US::getOrFail(literal!("missing"), s);
    assert!(result.is_err());
    Ok(())
}

// ── duplicate add ─────────────────────────────────────────────────────────────

#[test]
fn test_add_duplicate_does_not_grow_size() -> Result<()> {
    let s = set_of(&["dup", "dup", "dup"])?;
    assert_eq!(US::size(s), 1);
    Ok(())
}

#[test]
fn test_add_duplicate_still_contained() -> Result<()> {
    let s = empty_set();
    US::add(literal!("x"), s.clone())?;
    US::add(literal!("x"), s.clone())?;
    assert!(US::contains(literal!("x"), s)?);
    Ok(())
}

// ── addUnique ─────────────────────────────────────────────────────────────────

#[test]
fn test_add_unique_new_key_succeeds() -> Result<()> {
    let s = empty_set();
    US::addUnique(literal!("new"), s.clone())?;
    assert!(US::contains(literal!("new"), s)?);
    Ok(())
}

#[test]
fn test_add_unique_duplicate_fails() -> Result<()> {
    let s = set_of(&["existing"])?;
    let result = US::addUnique(literal!("existing"), s);
    assert!(result.is_err());
    Ok(())
}

// ── remove ────────────────────────────────────────────────────────────────────

#[test]
fn test_remove_present_key_returns_true() -> Result<()> {
    let s = set_of(&["a", "b", "c"])?;
    let removed = US::remove(literal!("b"), s.clone())?;
    assert!(removed);
    Ok(())
}

#[test]
fn test_remove_present_key_is_no_longer_contained() -> Result<()> {
    let s = set_of(&["a", "b"])?;
    US::remove(literal!("a"), s.clone())?;
    assert!(!US::contains(literal!("a"), s)?);
    Ok(())
}

#[test]
fn test_remove_decrements_size() -> Result<()> {
    let s = set_of(&["a", "b", "c"])?;
    assert_eq!(US::size(s.clone()), 3);
    US::remove(literal!("b"), s.clone())?;
    assert_eq!(US::size(s), 2);
    Ok(())
}

#[test]
fn test_remove_absent_key_returns_false() -> Result<()> {
    let s = set_of(&["a"])?;
    let removed = US::remove(literal!("absent"), s.clone())?;
    assert!(!removed);
    // Size is unchanged.
    assert_eq!(US::size(s), 1);
    Ok(())
}

#[test]
fn test_remove_does_not_affect_other_keys() -> Result<()> {
    let s = set_of(&["alpha", "beta", "gamma"])?;
    US::remove(literal!("beta"), s.clone())?;
    assert!(US::contains(literal!("alpha"), s.clone())?);
    assert!(US::contains(literal!("gamma"), s.clone())?);
    Ok(())
}

// ── toList ────────────────────────────────────────────────────────────────────

#[test]
fn test_tolist_empty() {
    let s = empty_set();
    assert!(US::toList(s).is_empty());
}

#[test]
fn test_tolist_contains_all_elements() -> Result<()> {
    let s = set_of(&["c", "a", "b"])?;
    assert_eq!(to_sorted_vec(s), vec!["a", "b", "c"]);
    Ok(())
}

#[test]
fn test_tolist_no_duplicates() -> Result<()> {
    let s = set_of(&["x", "x", "y"])?;
    let v = to_sorted_vec(s);
    assert_eq!(v, vec!["x", "y"]);
    Ok(())
}

// ── copy independence ─────────────────────────────────────────────────────────

#[test]
fn test_copy_is_independent() -> Result<()> {
    let s1 = set_of(&["a", "b"])?;
    let s2 = US::copy(s1.clone());
    // Mutate s1; s2 must not be affected.
    US::add(literal!("c"), s1.clone())?;
    assert!(!US::contains(literal!("c"), s2)?);
    Ok(())
}

#[test]
fn test_copy_contains_same_elements() -> Result<()> {
    let s1 = set_of(&["x", "y"])?;
    let s2 = US::copy(s1.clone());
    assert_eq!(to_sorted_vec(s1), to_sorted_vec(s2));
    Ok(())
}

// ── fromList ──────────────────────────────────────────────────────────────────

#[test]
fn test_from_list_basic() -> Result<()> {
    let lst = list![literal!("p"), literal!("q"), literal!("r")];
    let s = US::fromList(lst, Arc::new(hash_str), Arc::new(eq_str))?;
    assert_eq!(to_sorted_vec(s), vec!["p", "q", "r"]);
    Ok(())
}

#[test]
fn test_from_list_deduplicates() -> Result<()> {
    let lst = list![literal!("x"), literal!("x"), literal!("y")];
    let s = US::fromList(lst, Arc::new(hash_str), Arc::new(eq_str))?;
    assert_eq!(US::size(s.clone()), 2);
    assert_eq!(to_sorted_vec(s), vec!["x", "y"]);
    Ok(())
}

#[test]
fn test_from_list_empty() -> Result<()> {
    let lst: Arc<metamodelica::List<ArcStr>> = metamodelica::nil();
    let s = US::fromList(lst, Arc::new(hash_str), Arc::new(eq_str))?;
    assert!(US::isEmpty(s));
    Ok(())
}

// ── isEqual ───────────────────────────────────────────────────────────────────

#[test]
fn test_is_equal_same_elements() -> Result<()> {
    let s1 = set_of(&["a", "b", "c"])?;
    let s2 = set_of(&["c", "a", "b"])?;
    assert!(US::isEqual(s1, s2)?);
    Ok(())
}

#[test]
fn test_is_equal_different_sizes() -> Result<()> {
    let s1 = set_of(&["a", "b"])?;
    let s2 = set_of(&["a", "b", "c"])?;
    assert!(!US::isEqual(s1, s2)?);
    Ok(())
}

#[test]
fn test_is_equal_same_size_different_elements() -> Result<()> {
    let s1 = set_of(&["a", "b"])?;
    let s2 = set_of(&["a", "c"])?;
    assert!(!US::isEqual(s1, s2)?);
    Ok(())
}

#[test]
fn test_is_equal_empty_sets() -> Result<()> {
    let s1 = empty_set();
    let s2 = empty_set();
    assert!(US::isEqual(s1, s2)?);
    Ok(())
}

// ── first ─────────────────────────────────────────────────────────────────────

#[test]
fn test_first_on_empty_fails() {
    let s = empty_set();
    assert!(US::first(s).is_err());
}

#[test]
fn test_first_on_non_empty_returns_some_element() -> Result<()> {
    let s = set_of(&["only"])?;
    let f = US::first(s.clone())?;
    assert!(US::contains(f, s)?);
    Ok(())
}

// ── large set / rehash ────────────────────────────────────────────────────────

#[test]
fn test_large_set_all_keys_present() -> Result<()> {
    let s = empty_set();
    let n = 300_i32;
    for i in 0..n {
        US::add(arcstr::format!("item_{}", i), s.clone())?;
    }
    assert_eq!(US::size(s.clone()), n);
    for i in 0..n {
        assert!(
            US::contains(arcstr::format!("item_{}", i), s.clone())?,
            "item_{} not found",
            i
        );
    }
    Ok(())
}

#[test]
fn test_rehash_preserves_all_keys() -> Result<()> {
    let s = empty_set();
    for i in 0..50_i32 {
        US::add(arcstr::format!("k{}", i), s.clone())?;
    }
    US::rehash(s.clone())?;
    for i in 0..50_i32 {
        assert!(
            US::contains(arcstr::format!("k{}", i), s.clone())?,
            "k{} missing after rehash",
            i
        );
    }
    Ok(())
}

// ── all / any / none ──────────────────────────────────────────────────────────

#[test]
fn test_all_true_when_all_match() -> Result<()> {
    // All keys start with "aa" – pred is always true.
    let s = set_of(&["aaa", "aab", "aac"])?;
    let result = US::all(s, Arc::new(|k: ArcStr| Ok(k.starts_with("aa")))).unwrap();
    assert!(result);
    Ok(())
}

#[test]
fn test_all_false_when_one_does_not_match() -> Result<()> {
    let s = set_of(&["aaa", "bbb"])?;
    let result = US::all(s, Arc::new(|k: ArcStr| Ok(k.starts_with("aa")))).unwrap();
    assert!(!result);
    Ok(())
}

#[test]
fn test_all_empty_set_returns_true() {
    let s = empty_set();
    let result = US::all(s, Arc::new(|_: ArcStr| Ok(false))).unwrap();
    assert!(result);
}

#[test]
fn test_any_true_when_one_matches() -> Result<()> {
    let s = set_of(&["no_match", "yes_match"])?;
    let result = US::any(s, Arc::new(|k: ArcStr| Ok(k.starts_with("yes")))).unwrap();
    assert!(result);
    Ok(())
}

#[test]
fn test_any_false_when_none_match() -> Result<()> {
    let s = set_of(&["a", "b"])?;
    let result = US::any(s, Arc::new(|k: ArcStr| Ok(k.starts_with("z")))).unwrap();
    assert!(!result);
    Ok(())
}

#[test]
fn test_any_empty_set_returns_false() {
    let s = empty_set();
    let result = US::any(s, Arc::new(|_: ArcStr| Ok(true))).unwrap();
    assert!(!result);
}

#[test]
fn test_none_when_no_element_matches() -> Result<()> {
    let s = set_of(&["a", "b"])?;
    let result = US::none(s, Arc::new(|k: ArcStr| Ok(k.starts_with("z")))).unwrap();
    assert!(result);
    Ok(())
}

#[test]
fn test_none_false_when_one_matches() -> Result<()> {
    let s = set_of(&["a", "z_key"])?;
    let result = US::none(s, Arc::new(|k: ArcStr| Ok(k.starts_with("z")))).unwrap();
    assert!(!result);
    Ok(())
}
