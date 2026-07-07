// Tests for crate::UnorderedMap.
//
// The Rust source is auto-generated from:
//   ~/OpenModelica/OMCompiler/Compiler/Util/UnorderedMap.mo
//
// UnorderedMap is a generic hash-map backed by three Vectors (buckets, keys,
// values).  All mutation happens in-place through Arc.
//
// We use ArcStr keys and i32 values throughout.

use anyhow::Result;
use std::sync::Arc;
use metamodelica::*;
use arcstr::{ArcStr, literal};
use crate::UnorderedMap as UM;

// ── hash / eq helpers ────────────────────────────────────────────────────────

fn hash_str(k: ArcStr) -> Result<i32> {
    Ok(stringHashDjb2(k))
}

fn eq_str(a: ArcStr, b: ArcStr) -> Result<bool> {
    Ok(stringEq(a, b))
}

// ── construction helpers ──────────────────────────────────────────────────────

fn empty_map() -> Arc<UM::UnorderedMap<ArcStr, i32>> {
    UM::new(Arc::new(hash_str), Arc::new(eq_str), 13)
}

fn map_of(pairs: &[(&str, i32)]) -> Result<Arc<UM::UnorderedMap<ArcStr, i32>>> {
    let m = empty_map();
    for (k, v) in pairs {
        UM::add(arcstr::format!("{}", k), *v, m.clone())?;
    }
    Ok(m)
}

/// Collect (keyList, valueList) as sorted-by-key pairs for comparison.
fn to_sorted_pairs(m: Arc<UM::UnorderedMap<ArcStr, i32>>) -> Vec<(String, i32)> {
    let keys = UM::keyList(m.clone());
    let vals = UM::valueList(m.clone());
    let mut pairs: Vec<(String, i32)> = vec![];
    let mut ki = keys.as_ref();
    let mut vi = vals.as_ref();
    loop {
        match (ki, vi) {
            (metamodelica::List::Cons { head: k, tail: kt },
             metamodelica::List::Cons { head: v, tail: vt }) => {
                pairs.push((k.to_string(), *v));
                ki = kt.as_ref();
                vi = vt.as_ref();
            }
            _ => break,
        }
    }
    pairs.sort_by(|a, b| a.0.cmp(&b.0));
    pairs
}

// ── new / isEmpty / size ──────────────────────────────────────────────────────

#[test]
fn test_new_is_empty() {
    let m = empty_map();
    assert!(UM::isEmpty(m.clone()));
    assert_eq!(UM::size(m), 0);
}

// ── add / get / contains ─────────────────────────────────────────────────────

#[test]
fn test_add_and_get() -> Result<()> {
    let m = map_of(&[("alpha", 10), ("beta", 20), ("gamma", 30)])?;
    assert_eq!(UM::get(literal!("alpha"), m.clone())?, Some(10));
    assert_eq!(UM::get(literal!("beta"),  m.clone())?, Some(20));
    assert_eq!(UM::get(literal!("gamma"), m.clone())?, Some(30));
    Ok(())
}

#[test]
fn test_get_absent_key_returns_none() -> Result<()> {
    let m = map_of(&[("a", 1)])?;
    assert_eq!(UM::get(literal!("missing"), m)?, None);
    Ok(())
}

#[test]
fn test_contains_present_key() -> Result<()> {
    let m = map_of(&[("key", 42)])?;
    assert!(UM::contains(literal!("key"), m)?);
    Ok(())
}

#[test]
fn test_contains_absent_key_returns_false() -> Result<()> {
    let m = map_of(&[("key", 42)])?;
    assert!(!UM::contains(literal!("no_such_key"), m)?);
    Ok(())
}

// ── add updates existing key ──────────────────────────────────────────────────

#[test]
fn test_add_updates_existing_value() -> Result<()> {
    let m = map_of(&[("key", 1)])?;
    UM::add(literal!("key"), 99, m.clone())?;
    assert_eq!(UM::get(literal!("key"), m)?, Some(99));
    Ok(())
}

#[test]
fn test_add_update_does_not_grow_size() -> Result<()> {
    let m = map_of(&[("key", 1)])?;
    UM::add(literal!("key"), 2, m.clone())?;
    assert_eq!(UM::size(m), 1);
    Ok(())
}

// ── size tracking ────────────────────────────────────────────────────────────

#[test]
fn test_size_grows_with_unique_keys() -> Result<()> {
    let m = map_of(&[("a", 1), ("b", 2), ("c", 3)])?;
    assert_eq!(UM::size(m), 3);
    Ok(())
}

// ── addUnique ────────────────────────────────────────────────────────────────

#[test]
fn test_add_unique_new_key_succeeds() -> Result<()> {
    let m = empty_map();
    UM::addUnique(literal!("new"), 7, m.clone())?;
    assert_eq!(UM::get(literal!("new"), m)?, Some(7));
    Ok(())
}

#[test]
fn test_add_unique_duplicate_fails() -> Result<()> {
    let m = map_of(&[("existing", 1)])?;
    let result = UM::addUnique(literal!("existing"), 2, m);
    assert!(result.is_err());
    Ok(())
}

// ── getOrDefault ─────────────────────────────────────────────────────────────

#[test]
fn test_get_or_default_present_key() -> Result<()> {
    let m = map_of(&[("k", 5)])?;
    assert_eq!(UM::getOrDefault(literal!("k"), m, -1)?, 5);
    Ok(())
}

#[test]
fn test_get_or_default_absent_key_returns_default() -> Result<()> {
    let m = empty_map();
    assert_eq!(UM::getOrDefault(literal!("missing"), m, -99)?, -99);
    Ok(())
}

// ── tryAdd ────────────────────────────────────────────────────────────────────

#[test]
fn test_try_add_new_key_returns_inserted_value() -> Result<()> {
    let m = empty_map();
    let v = UM::tryAdd(literal!("new"), 42, m.clone())?;
    assert_eq!(v, 42);
    assert_eq!(UM::get(literal!("new"), m)?, Some(42));
    Ok(())
}

#[test]
fn test_try_add_existing_key_returns_existing_value() -> Result<()> {
    let m = map_of(&[("key", 10)])?;
    let v = UM::tryAdd(literal!("key"), 99, m.clone())?;
    // Should return the existing value, not the new one.
    assert_eq!(v, 10);
    // Map value should remain unchanged.
    assert_eq!(UM::get(literal!("key"), m)?, Some(10));
    Ok(())
}

// ── tryUpdate ────────────────────────────────────────────────────────────────

#[test]
fn test_try_update_existing_key_returns_true() -> Result<()> {
    let m = map_of(&[("key", 1)])?;
    let updated = UM::tryUpdate(literal!("key"), 2, m.clone())?;
    assert!(updated);
    assert_eq!(UM::get(literal!("key"), m)?, Some(2));
    Ok(())
}

#[test]
fn test_try_update_absent_key_returns_false() -> Result<()> {
    let m = empty_map();
    let updated = UM::tryUpdate(literal!("absent"), 1, m.clone())?;
    assert!(!updated);
    // Key was NOT inserted.
    assert!(!UM::contains(literal!("absent"), m)?);
    Ok(())
}

// ── remove ───────────────────────────────────────────────────────────────────

#[test]
fn test_remove_present_key_returns_true() -> Result<()> {
    let m = map_of(&[("a", 1), ("b", 2)])?;
    let removed = UM::remove(literal!("a"), m.clone())?;
    assert!(removed);
    Ok(())
}

#[test]
fn test_remove_absent_key_returns_false() -> Result<()> {
    let m = map_of(&[("a", 1)])?;
    let removed = UM::remove(literal!("absent"), m.clone())?;
    assert!(!removed);
    Ok(())
}

#[test]
fn test_remove_decrements_size() -> Result<()> {
    let m = map_of(&[("a", 1), ("b", 2), ("c", 3)])?;
    UM::remove(literal!("b"), m.clone())?;
    assert_eq!(UM::size(m), 2);
    Ok(())
}

#[test]
fn test_remove_key_no_longer_present() -> Result<()> {
    let m = map_of(&[("x", 10)])?;
    UM::remove(literal!("x"), m.clone())?;
    assert!(!UM::contains(literal!("x"), m)?);
    Ok(())
}

#[test]
fn test_remove_does_not_affect_other_keys() -> Result<()> {
    let m = map_of(&[("a", 1), ("b", 2), ("c", 3)])?;
    UM::remove(literal!("b"), m.clone())?;
    assert_eq!(UM::get(literal!("a"), m.clone())?, Some(1));
    assert_eq!(UM::get(literal!("c"), m.clone())?, Some(3));
    Ok(())
}

#[test]
fn test_remove_then_lookup_remaining_keys_after_reindex() -> Result<()> {
    // Specifically tests the index-update logic: after removing key at some
    // internal position, keys that had higher indices must be reachable.
    let m = empty_map();
    for i in 0..10_i32 {
        UM::add(arcstr::format!("k{}", i), i, m.clone())?;
    }
    // Remove the first inserted key.
    UM::remove(literal!("k0"), m.clone())?;
    for i in 1..10_i32 {
        assert_eq!(
            UM::get(arcstr::format!("k{}", i), m.clone())?,
            Some(i),
            "k{} missing after removing k0",
            i
        );
    }
    Ok(())
}

// ── clear ────────────────────────────────────────────────────────────────────

#[test]
fn test_clear_makes_map_empty() -> Result<()> {
    let m = map_of(&[("a", 1), ("b", 2)])?;
    UM::clear(m.clone());
    assert!(UM::isEmpty(m.clone()));
    assert_eq!(UM::size(m), 0);
    Ok(())
}

#[test]
fn test_clear_then_add_works() -> Result<()> {
    let m = map_of(&[("old", 1)])?;
    UM::clear(m.clone());
    UM::add(literal!("new"), 42, m.clone())?;
    assert_eq!(UM::get(literal!("new"), m.clone())?, Some(42));
    assert_eq!(UM::size(m), 1);
    Ok(())
}

// ── keyList / valueList / toList ─────────────────────────────────────────────

#[test]
fn test_keylist_and_valuelist() -> Result<()> {
    let m = map_of(&[("b", 2), ("a", 1), ("c", 3)])?;
    let pairs = to_sorted_pairs(m);
    assert_eq!(pairs, vec![
        ("a".to_string(), 1),
        ("b".to_string(), 2),
        ("c".to_string(), 3),
    ]);
    Ok(())
}

#[test]
fn test_tolist_empty_map() {
    let m = empty_map();
    let lst = UM::toList(m);
    assert!(lst.is_empty());
}

#[test]
fn test_tolist_contains_all_pairs() -> Result<()> {
    let m = map_of(&[("k", 7)])?;
    let lst = UM::toList(m);
    let mut pairs: Vec<(String, i32)> = vec![];
    for (k, v) in &*lst { pairs.push((k.to_string(), *v)); }
    assert!(pairs.contains(&("k".to_string(), 7)));
    Ok(())
}

// ── fromLists ─────────────────────────────────────────────────────────────────

#[test]
fn test_from_lists_basic() -> Result<()> {
    let keys = list![literal!("a"), literal!("b"), literal!("c")];
    let vals = list![1_i32, 2_i32, 3_i32];
    let m = UM::fromLists(keys, vals, Arc::new(hash_str), Arc::new(eq_str))?;
    assert_eq!(UM::get(literal!("a"), m.clone())?, Some(1));
    assert_eq!(UM::get(literal!("b"), m.clone())?, Some(2));
    assert_eq!(UM::get(literal!("c"), m.clone())?, Some(3));
    Ok(())
}

#[test]
fn test_from_lists_empty() -> Result<()> {
    let keys: Arc<metamodelica::List<ArcStr>> = metamodelica::nil();
    let vals: Arc<metamodelica::List<i32>>    = metamodelica::nil();
    let m = UM::fromLists(keys, vals, Arc::new(hash_str), Arc::new(eq_str))?;
    assert!(UM::isEmpty(m));
    Ok(())
}

#[test]
fn test_from_lists_mismatched_length_fails() -> Result<()> {
    // More keys than values – should fail.
    let keys = list![literal!("a"), literal!("b")];
    let vals = list![1_i32];
    let result = UM::fromLists(keys, vals, Arc::new(hash_str), Arc::new(eq_str));
    assert!(result.is_err());
    Ok(())
}

// ── copy independence ─────────────────────────────────────────────────────────

#[test]
fn test_copy_is_independent() -> Result<()> {
    let m1 = map_of(&[("a", 1), ("b", 2)])?;
    let m2 = UM::copy(m1.clone());
    // Mutate m1; m2 should be unaffected.
    UM::add(literal!("c"), 3, m1.clone())?;
    assert!(!UM::contains(literal!("c"), m2)?);
    Ok(())
}

#[test]
fn test_copy_contains_same_entries() -> Result<()> {
    let m1 = map_of(&[("x", 10), ("y", 20)])?;
    let m2 = UM::copy(m1.clone());
    assert_eq!(to_sorted_pairs(m1), to_sorted_pairs(m2));
    Ok(())
}

// ── large map / rehash ────────────────────────────────────────────────────────

#[test]
fn test_large_map_all_entries_present() -> Result<()> {
    let m = empty_map();
    let n = 300_i32;
    for i in 0..n {
        UM::add(arcstr::format!("key_{}", i), i, m.clone())?;
    }
    assert_eq!(UM::size(m.clone()), n);
    for i in 0..n {
        assert_eq!(
            UM::get(arcstr::format!("key_{}", i), m.clone())?,
            Some(i),
            "key_{} has wrong value",
            i
        );
    }
    Ok(())
}

// ── first / firstKey ──────────────────────────────────────────────────────────

#[test]
fn test_first_on_non_empty_map() -> Result<()> {
    let m = map_of(&[("only", 99)])?;
    let v = UM::first(m.clone())?;
    assert_eq!(v, 99);
    Ok(())
}

#[test]
fn test_first_key_on_non_empty_map() -> Result<()> {
    let m = map_of(&[("solo", 1)])?;
    let k = UM::firstKey(m.clone())?;
    assert_eq!(k, literal!("solo"));
    Ok(())
}
