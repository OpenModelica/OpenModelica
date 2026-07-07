// Tests for crate::HashSetString (backed by BaseHashSet).
//
// The Rust source is auto-generated from:
//   ~/OpenModelica/OMCompiler/Compiler/Util/HashSetString.mo
//   ~/OpenModelica/OMCompiler/Compiler/Util/BaseHashSet.mo
//
// HashSetString is a specialisation of BaseHashSet with Key = ArcStr,
// using stringHashDjb2 / stringEq.  The heavy-lifting lives in BaseHashSet.
//
// Semantics under test:
//   emptyHashSet / emptyHashSetSized → initially empty (size 0)
//   add          → inserts; re-add of same key is a no-op (no size growth)
//   has          → membership test
//   get          → retrieves existing key wrapped in Some, None otherwise
//   currentSize  → count of stored keys
//   delete       → marks a slot empty (does NOT shrink size counter)
//   hashSetList  → all stored keys as a list
//   addUnique    → inserts only when key is absent; fails if already present

use anyhow::Result;
use std::sync::Arc;
use metamodelica::*;
use arcstr::{ArcStr, literal};
use crate::HashSetString as HS;
use crate::BaseHashSet;

// ── helpers ──────────────────────────────────────────────────────────────────

type HashSet = HS::HashSet;

fn empty() -> HashSet {
    HS::emptyHashSet()
}

fn with_keys(keys: &[&str]) -> Result<HashSet> {
    let mut hs = empty();
    for k in keys {
        hs = BaseHashSet::add(arcstr::format!("{}", k), hs)?;
    }
    Ok(hs)
}

/// Collect hashSetList into a sorted Vec<String> for order-independent comparison.
fn list_sorted(hs: HashSet) -> Result<Vec<String>> {
    let lst = BaseHashSet::hashSetList(hs)?;
    let mut v: Vec<String> = vec![];
    for k in &*lst { v.push(k.to_string()); }
    v.sort();
    Ok(v)
}

// ── emptyHashSet / emptyHashSetSized ─────────────────────────────────────────

#[test]
fn test_empty_hash_set_has_size_zero() {
    let hs = empty();
    assert_eq!(BaseHashSet::currentSize(hs), 0);
}

#[test]
fn test_empty_hash_set_sized_has_size_zero() {
    let hs = HS::emptyHashSetSized(64);
    assert_eq!(BaseHashSet::currentSize(hs), 0);
}

#[test]
fn test_has_on_empty_returns_false() -> Result<()> {
    let hs = empty();
    assert!(!BaseHashSet::has(literal!("anything"), hs)?);
    Ok(())
}

// ── add / has / currentSize ───────────────────────────────────────────────────

#[test]
fn test_add_single_key() -> Result<()> {
    let hs = with_keys(&["hello"])?;
    assert!(BaseHashSet::has(literal!("hello"), hs)?);
    Ok(())
}

#[test]
fn test_add_multiple_keys() -> Result<()> {
    let hs = with_keys(&["alpha", "beta", "gamma"])?;
    assert!(BaseHashSet::has(literal!("alpha"), hs.clone())?);
    assert!(BaseHashSet::has(literal!("beta"),  hs.clone())?);
    assert!(BaseHashSet::has(literal!("gamma"), hs.clone())?);
    Ok(())
}

#[test]
fn test_has_absent_key_returns_false() -> Result<()> {
    let hs = with_keys(&["alpha", "beta"])?;
    assert!(!BaseHashSet::has(literal!("gamma"), hs)?);
    Ok(())
}

#[test]
fn test_current_size_grows_with_each_unique_key() -> Result<()> {
    let hs = with_keys(&["a", "b", "c"])?;
    assert_eq!(BaseHashSet::currentSize(hs), 3);
    Ok(())
}

#[test]
fn test_add_duplicate_does_not_grow_size() -> Result<()> {
    let hs = with_keys(&["dup", "dup", "dup"])?;
    assert_eq!(BaseHashSet::currentSize(hs), 1);
    Ok(())
}

// ── get ───────────────────────────────────────────────────────────────────────

#[test]
fn test_get_present_key_returns_some() -> Result<()> {
    let hs = with_keys(&["foo"])?;
    let result = BaseHashSet::get(literal!("foo"), hs)?;
    assert_eq!(result, Some(literal!("foo")));
    Ok(())
}

#[test]
fn test_get_absent_key_returns_none() -> Result<()> {
    let hs = with_keys(&["foo"])?;
    let result = BaseHashSet::get(literal!("bar"), hs)?;
    assert_eq!(result, None);
    Ok(())
}

// ── hashSetList ───────────────────────────────────────────────────────────────

#[test]
fn test_hashsetlist_empty() -> Result<()> {
    let hs = empty();
    let lst = BaseHashSet::hashSetList(hs)?;
    assert!(lst.is_empty());
    Ok(())
}

#[test]
fn test_hashsetlist_contains_all_keys() -> Result<()> {
    let keys = &["one", "two", "three", "four"];
    let hs = with_keys(keys)?;
    let got = list_sorted(hs)?;
    assert_eq!(got, vec!["four", "one", "three", "two"]);
    Ok(())
}

#[test]
fn test_hashsetlist_no_duplicates_after_re_add() -> Result<()> {
    let hs = with_keys(&["x", "x", "y"])?;
    let got = list_sorted(hs)?;
    assert_eq!(got, vec!["x", "y"]);
    Ok(())
}

// ── delete ────────────────────────────────────────────────────────────────────

#[test]
fn test_delete_present_key() -> Result<()> {
    let hs = with_keys(&["to_delete", "to_keep"])?;
    let hs = BaseHashSet::delete(literal!("to_delete"), hs)?;
    // After delete the key should no longer be found.
    assert!(!BaseHashSet::has(literal!("to_delete"), hs.clone())?);
    // The other key is unaffected.
    assert!(BaseHashSet::has(literal!("to_keep"), hs)?);
    Ok(())
}

#[test]
fn test_delete_absent_key_fails() -> Result<()> {
    // delete requires the key to be present; it should fail when it isn't.
    let hs = with_keys(&["present"])?;
    let result = BaseHashSet::delete(literal!("absent"), hs);
    assert!(result.is_err());
    Ok(())
}

// ── addUnique ─────────────────────────────────────────────────────────────────

#[test]
fn test_add_unique_new_key_succeeds() -> Result<()> {
    let hs = empty();
    let hs = BaseHashSet::addUnique(literal!("new_key"), hs)?;
    assert!(BaseHashSet::has(literal!("new_key"), hs)?);
    Ok(())
}

#[test]
fn test_add_unique_duplicate_fails() -> Result<()> {
    let hs = with_keys(&["existing"])?;
    let result = BaseHashSet::addUnique(literal!("existing"), hs);
    assert!(result.is_err());
    Ok(())
}

// ── large set ─────────────────────────────────────────────────────────────────

#[test]
fn test_large_set_all_keys_present() -> Result<()> {
    let mut hs = empty();
    let n = 200;
    for i in 0..n {
        hs = BaseHashSet::add(arcstr::format!("key_{}", i), hs)?;
    }
    assert_eq!(BaseHashSet::currentSize(hs.clone()), n);
    for i in 0..n {
        assert!(
            BaseHashSet::has(arcstr::format!("key_{}", i), hs.clone())?,
            "key_{} not found",
            i
        );
    }
    Ok(())
}
