// Tests for crate::AvlTreeString
//
// The Rust source is auto-generated from:
//   ~/OpenModelica/OMCompiler/Compiler/Util/AvlTreeString.mo  (extends BaseAvlTree)
//
// AvlTreeString maps String → Integer.
// Key ordering: stringCompare; smaller keys go LEFT, larger keys go RIGHT.
//
// Note on addConflictKeep / addConflictReplace:
//   These are declared `-> Value` (i32), not `-> Result<Value>`.  Codegen
//   handles this by wrapping them with the `fnptr!` macro, which lifts the
//   return value into `Ok(...)`.  The tests below do the same.
//
// Known runtime bug:
//   intersection() always fails (bail!("fail")), faithfully reproducing the
//   MetaModelica source which has `redeclare function intersection; algorithm fail();`.

use anyhow::Result;
use std::sync::Arc;
use metamodelica::*;
use arcstr::{ArcStr, literal};
use crate::AvlTreeString as T;

// ── helpers ──────────────────────────────────────────────────────────────────

/// Build a tree from (key, value) pairs using the given conflict function.
///
/// `ConflictFunc` is now `Arc<dyn Fn(...) + 'static>` (see `fmt_param_ty`
/// in mmtorust); pass it by clone to keep the original handle alive for
/// subsequent `T::add` calls.
fn tree_of(pairs: &[(&str, i32)], cf: T::ConflictFunc) -> Result<Arc<T::Tree>> {
    let mut t = T::new();
    for (k, v) in pairs {
        t = T::add(t, arcstr::format!("{}", k), *v, cf.clone())?;
    }
    Ok(t)
}

/// Keys in ascending order.
fn keys_vec(t: Arc<T::Tree>) -> Vec<String> {
    let list = T::listKeys(t, metamodelica::nil());
    let mut v = vec![];
    for k in &*list { v.push(k.to_string()); }
    v
}

/// Values in key-ascending order.
fn vals_vec(t: Arc<T::Tree>) -> Vec<i32> {
    let list = T::listValues(t, metamodelica::nil());
    let mut v = vec![];
    for val in &*list { v.push(*val); }
    v
}

// ── fnptr! wrappers (mirrors codegen) ────────────────────────────────────────
//
// addConflictKeep and addConflictReplace return `Value` (i32) rather than
// `Result<Value>`.  Codegen wraps them with `fnptr!(f, ArgTy…)` to lift the
// return value into `Ok(…)`, then `Arc::new` to land in the
// `Arc<dyn Fn(...) + 'static>` shape that `ConflictFunc` aliases. The
// wrappers can't be `const` because `Arc::new` is not const — promote
// each to a helper function that constructs a fresh `Arc<dyn Fn>` on
// demand. The returned handle is cheap to clone (refcount bump).
fn conflict_keep() -> T::ConflictFunc {
    Arc::new(fnptr!(T::addConflictKeep, i32, i32, ArcStr))
}
fn conflict_replace() -> T::ConflictFunc {
    Arc::new(fnptr!(T::addConflictReplace, i32, i32, ArcStr))
}
fn conflict_fail() -> T::ConflictFunc {
    Arc::new(T::addConflictFail)
}
fn conflict_default() -> T::ConflictFunc {
    Arc::new(T::addConflictDefault)
}

// ── new / isEmpty ─────────────────────────────────────────────────────────────

#[test]
fn test_new_is_empty() {
    let t = T::new();
    assert!(T::isEmpty(t));
}

#[test]
fn test_non_empty_is_not_empty() -> Result<()> {
    let t = tree_of(&[("a", 1)], conflict_fail())?;
    assert!(!T::isEmpty(t));
    Ok(())
}

// ── add / get / getOpt / hasKey ───────────────────────────────────────────────

#[test]
fn test_add_and_get() -> Result<()> {
    let t = tree_of(&[("alpha", 10), ("beta", 20), ("gamma", 30)], conflict_fail())?;
    assert_eq!(T::get(t.clone(), literal!("alpha"))?, 10);
    assert_eq!(T::get(t.clone(), literal!("beta"))?,  20);
    assert_eq!(T::get(t,         literal!("gamma"))?, 30);
    Ok(())
}

#[test]
fn test_get_missing_key_fails() -> Result<()> {
    let t = tree_of(&[("a", 1)], conflict_fail())?;
    assert!(T::get(t, literal!("missing")).is_err());
    Ok(())
}

#[test]
fn test_getopt_present() -> Result<()> {
    let t = tree_of(&[("key", 42)], conflict_fail())?;
    assert_eq!(T::getOpt(t, literal!("key")), Some(42));
    Ok(())
}

#[test]
fn test_getopt_absent() -> Result<()> {
    let t = tree_of(&[("key", 42)], conflict_fail())?;
    assert_eq!(T::getOpt(t, literal!("nope")), None);
    Ok(())
}

#[test]
fn test_getopt_empty_tree() {
    let t = T::new();
    assert_eq!(T::getOpt(t, literal!("x")), None);
}

#[test]
fn test_haskey_present() -> Result<()> {
    let t = tree_of(&[("x", 0)], conflict_fail())?;
    assert!(T::hasKey(t, literal!("x"))?);
    Ok(())
}

#[test]
fn test_haskey_absent() -> Result<()> {
    let t = tree_of(&[("x", 0)], conflict_fail())?;
    assert!(!T::hasKey(t, literal!("y"))?);
    Ok(())
}

#[test]
fn test_haskey_empty_tree() -> Result<()> {
    let t = T::new();
    assert!(!T::hasKey(t, literal!("anything"))?);
    Ok(())
}

// ── conflict functions ────────────────────────────────────────────────────────

#[test]
fn test_conflict_fail_on_duplicate() -> Result<()> {
    let t = tree_of(&[("k", 1)], conflict_fail())?;
    // Inserting the same key again should fail.
    let result = T::add(t, literal!("k"), 2, conflict_fail());
    assert!(result.is_err(),
        "addConflictFail should return an error when inserting a duplicate key");
    Ok(())
}

#[test]
fn test_conflict_keep_preserves_old_value() -> Result<()> {
    let t = tree_of(&[("k", 1)], conflict_keep())?;
    let t = T::add(t, literal!("k"), 999, conflict_keep())?;
    assert_eq!(T::get(t, literal!("k"))?, 1,
        "addConflictKeep should keep the OLD value when there is a conflict");
    Ok(())
}

// BUG: assign_variant_field! field-name shadowing.
// Inside the macro, `if let Tree::LEAF { value, .. } = &mut __owned` binds
// `value` as `&mut i32` (the field of __owned).  The expression
// `value = value.clone()` in the macro call then expands to
// `*value = value.clone()` where the RHS `value.clone()` resolves to the
// PATTERN-BOUND `value: &mut i32`, not the outer `value: i32 = 999`.
// `(*(&mut i32)).clone()` yields the old field value, so the update is a no-op.
// The same shadowing happens in the NODE arm.
#[test]
fn test_conflict_replace_uses_new_value() -> Result<()> {
    let t = tree_of(&[("k", 1)], conflict_replace())?;
    let t = T::add(t, literal!("k"), 999, conflict_replace())?;
    assert_eq!(T::get(t, literal!("k"))?, 999,
        "addConflictReplace should use the NEW value when there is a conflict; \
         assign_variant_field! shadowing causes the update to be silently skipped");
    Ok(())
}

// ── addConflictDefault = addConflictFail ──────────────────────────────────────
// (also verifies that the alias works)

#[test]
fn test_conflict_default_is_fail() -> Result<()> {
    let t = tree_of(&[("k", 1)], conflict_default())?;
    let result = T::add(t, literal!("k"), 2, conflict_default());
    assert!(result.is_err());
    Ok(())
}

// ── listKeys ordering ─────────────────────────────────────────────────────────

#[test]
fn test_listkeys_ascending_order() -> Result<()> {
    let t = tree_of(&[("banana", 2), ("apple", 1), ("cherry", 3), ("date", 4)],
                    conflict_fail())?;
    assert_eq!(keys_vec(t), vec!["apple", "banana", "cherry", "date"]);
    Ok(())
}

#[test]
fn test_listkeys_empty() {
    assert_eq!(keys_vec(T::new()), Vec::<String>::new());
}

// ── listValues ordering ───────────────────────────────────────────────────────

#[test]
fn test_listvalues_in_key_ascending_order() -> Result<()> {
    // Keys: a=10, b=20, c=30 → values in key-ascending order: [10, 20, 30]
    let t = tree_of(&[("c", 30), ("a", 10), ("b", 20)], conflict_fail())?;
    assert_eq!(vals_vec(t), vec![10, 20, 30]);
    Ok(())
}

// ── addList ───────────────────────────────────────────────────────────────────

#[test]
fn test_addlist() -> Result<()> {
    let pairs = list![
        (literal!("c"), 3i32),
        (literal!("a"), 1i32),
        (literal!("b"), 2i32)
    ];
    let t = T::addList(T::new(), pairs, conflict_fail())?;
    assert_eq!(keys_vec(t.clone()), vec!["a", "b", "c"]);
    assert_eq!(vals_vec(t), vec![1, 2, 3]);
    Ok(())
}

// ── fromList ──────────────────────────────────────────────────────────────────

#[test]
fn test_fromlist() -> Result<()> {
    let pairs = list![
        (literal!("x"), 10i32),
        (literal!("y"), 20i32)
    ];
    let t = T::fromList(pairs, conflict_fail())?;
    assert_eq!(T::get(t.clone(), literal!("x"))?, 10);
    assert_eq!(T::get(t,         literal!("y"))?, 20);
    Ok(())
}

// ── addUpdate ─────────────────────────────────────────────────────────────────

#[test]
fn test_addupdate_insert_new() -> Result<()> {
    let t = T::new();
    let t = T::addUpdate(t, literal!("k"), Arc::new(|opt| {
        assert!(opt.is_none(), "key is new, oldValue should be None");
        Ok(42)
    }))?;
    assert_eq!(T::get(t, literal!("k"))?, 42);
    Ok(())
}

#[test]
fn test_addupdate_update_existing() -> Result<()> {
    let t = tree_of(&[("k", 10)], conflict_fail())?;
    let t = T::addUpdate(t, literal!("k"), Arc::new(|opt| {
        assert_eq!(opt, Some(10), "key exists, oldValue should be Some(10)");
        Ok(99)
    }))?;
    assert_eq!(T::get(t, literal!("k"))?, 99);
    Ok(())
}

// ── fold ──────────────────────────────────────────────────────────────────────

#[test]
fn test_fold_sum_values() -> Result<()> {
    let t = tree_of(&[("a", 1), ("b", 2), ("c", 3)], conflict_fail())?;
    let sum = T::fold(t, Arc::new(|_k, v, acc| Ok(acc + v)), 0i32)?;
    assert_eq!(sum, 6);
    Ok(())
}

#[test]
fn test_fold_empty_tree() -> Result<()> {
    let t = T::new();
    let sum = T::fold(t, Arc::new(|_k, v, acc| Ok(acc + v)), 0i32)?;
    assert_eq!(sum, 0);
    Ok(())
}

#[test]
fn test_fold_collects_keys_in_order() -> Result<()> {
    let t = tree_of(&[("c", 3), ("a", 1), ("b", 2)], conflict_fail())?;
    // fold visits in in-order (key-ascending).
    let collected = T::fold(
        t,
        Arc::new(|k, _v, mut acc: Vec<String>| { acc.push(k.to_string()); Ok(acc) }),
        vec![],
    )?;
    assert_eq!(collected, vec!["a", "b", "c"]);
    Ok(())
}

// ── forEach ───────────────────────────────────────────────────────────────────

#[test]
fn test_foreach_visits_all_in_order() -> Result<()> {
    use std::cell::RefCell;
    use std::rc::Rc;

    let t = tree_of(&[("c", 30), ("a", 10), ("b", 20)], conflict_fail())?;
    let visited: Rc<RefCell<Vec<(String, i32)>>> = Rc::new(RefCell::new(vec![]));
    let visited_clone = visited.clone();
    T::forEach(t, Arc::new(move |k, v| {
        visited_clone.borrow_mut().push((k.to_string(), v));
        Ok(())
    }))?;
    assert_eq!(
        *visited.borrow(),
        vec![("a".into(), 10), ("b".into(), 20), ("c".into(), 30)]
    );
    Ok(())
}

#[test]
fn test_foreach_empty_tree() -> Result<()> {
    T::forEach(T::new(), Arc::new(|_k, _v| {
        panic!("forEach on empty tree should not call func");
    }))?;
    Ok(())
}

// ── map ───────────────────────────────────────────────────────────────────────

#[test]
fn test_map_doubles_values() -> Result<()> {
    let t = tree_of(&[("a", 1), ("b", 2), ("c", 3)], conflict_fail())?;
    let t2 = T::map(t, Arc::new(|_k, v| Ok(v * 2)))?;
    assert_eq!(vals_vec(t2), vec![2, 4, 6]);
    Ok(())
}

#[test]
fn test_map_preserves_keys() -> Result<()> {
    let t = tree_of(&[("x", 0), ("y", 0)], conflict_fail())?;
    let t2 = T::map(t, Arc::new(|_k, v| Ok(v + 100)))?;
    assert_eq!(keys_vec(t2), vec!["x", "y"]);
    Ok(())
}

#[test]
fn test_map_empty_tree() -> Result<()> {
    let t = T::map(T::new(), Arc::new(|_k, v| Ok(v + 1)))?;
    assert!(T::isEmpty(t));
    Ok(())
}

// ── join ──────────────────────────────────────────────────────────────────────

#[test]
fn test_join_disjoint() -> Result<()> {
    let t1 = tree_of(&[("a", 1), ("b", 2)], conflict_fail())?;
    let t2 = tree_of(&[("c", 3), ("d", 4)], conflict_fail())?;
    let joined = T::join(t1, t2, conflict_fail())?;
    assert_eq!(keys_vec(joined.clone()), vec!["a", "b", "c", "d"]);
    assert_eq!(vals_vec(joined), vec![1, 2, 3, 4]);
    Ok(())
}

#[test]
fn test_join_with_conflict_keep() -> Result<()> {
    let t1 = tree_of(&[("shared", 1)], conflict_keep())?;
    let t2 = tree_of(&[("shared", 999)], conflict_keep())?;
    let joined = T::join(t1, t2, conflict_keep())?;
    assert_eq!(T::get(joined, literal!("shared"))?, 1,
        "join with conflict_keep should preserve the original value");
    Ok(())
}

// Same assign_variant_field! shadowing bug as test_conflict_replace_uses_new_value.
#[test]
fn test_join_with_conflict_replace() -> Result<()> {
    let t1 = tree_of(&[("shared", 1)], conflict_replace())?;
    let t2 = tree_of(&[("shared", 999)], conflict_replace())?;
    let joined = T::join(t1, t2, conflict_replace())?;
    assert_eq!(T::get(joined, literal!("shared"))?, 999,
        "join with conflict_replace should overwrite with the new value; \
         assign_variant_field! shadowing prevents the update");
    Ok(())
}

// ── intersection ─────────────────────────────────────────────────────────────
//
// BUG: AvlTreeString::intersection always fails.
// This is faithful to the MetaModelica source:
//
//   redeclare function intersection
//   algorithm
//     fail();
//   end intersection;
//
// Unlike AvlSetString (which has a real implementation), AvlTreeString
// explicitly chose not to implement intersection.  Any call returns an error.

#[test]
fn test_intersection_always_fails() -> Result<()> {
    // Even empty-tree intersection must fail.
    let result = T::intersection();
    assert!(result.is_err(),
        "AvlTreeString::intersection is not implemented and always returns an error");
    Ok(())
}

// ── printNodeStr / printTreeStr ───────────────────────────────────────────────

#[test]
fn test_print_node_str_leaf() -> Result<()> {
    let t = tree_of(&[("key", 7)], conflict_fail())?;
    let s = T::printNodeStr(t)?;
    assert_eq!(s, literal!("(key, 7)"));
    Ok(())
}

#[test]
fn test_print_tree_str_empty() -> Result<()> {
    let s = T::printTreeStr(T::new())?;
    assert_eq!(s, literal!("EMPTY()"));
    Ok(())
}

// ── keyCompare / keyStr / valueStr ────────────────────────────────────────────

#[test]
fn test_key_compare_equal() {
    assert_eq!(T::keyCompare(literal!("abc"), literal!("abc")), 0);
}

#[test]
fn test_key_compare_less() {
    assert_eq!(T::keyCompare(literal!("abc"), literal!("xyz")), -1);
}

#[test]
fn test_key_compare_greater() {
    assert_eq!(T::keyCompare(literal!("xyz"), literal!("abc")), 1);
}

#[test]
fn test_keystr_roundtrip() {
    let k = literal!("hello");
    assert_eq!(T::keyStr(k.clone()), k);
}

#[test]
fn test_valuestr() {
    assert_eq!(T::valueStr(42), literal!("42"));
    assert_eq!(T::valueStr(-1), literal!("-1"));
    assert_eq!(T::valueStr(0),  literal!("0"));
}
