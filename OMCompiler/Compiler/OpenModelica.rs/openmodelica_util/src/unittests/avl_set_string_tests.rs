// Tests for crate::AvlSetString
//
// The Rust source is auto-generated from:
//   ~/OpenModelica/OMCompiler/Compiler/Util/AvlSetString.mo  (extends BaseAvlSet)
//
// Key invariant: key comparison uses stringCompare; smaller keys go LEFT, larger
// keys go RIGHT.  listKeys/listKeysReverse traverse in ascending/descending order.

use anyhow::Result;
use std::sync::Arc;
use metamodelica::*;
use arcstr::{ArcStr, literal};
use crate::AvlSetString as S;

// ── helpers ──────────────────────────────────────────────────────────────────

/// Build a set from a &[&str] slice.
fn set_of(keys: &[&str]) -> Result<Arc<S::Tree>> {
    let mut t = S::new();
    for k in keys {
        t = S::add(t, arcstr::format!("{}", k))?;
    }
    Ok(t)
}

/// Collect listKeys into a Vec<String> for easy comparison.
fn keys_vec(t: Arc<S::Tree>) -> Vec<String> {
    let list = S::listKeys(t, metamodelica::nil());
    let mut v = vec![];
    for k in &*list { v.push(k.to_string()); }
    v
}

// ── new / isEmpty ─────────────────────────────────────────────────────────────

#[test]
fn test_new_is_empty() {
    let t = S::new();
    assert!(S::isEmpty(t));
}

#[test]
fn test_non_empty_is_not_empty() -> Result<()> {
    let t = set_of(&["hello"])?;
    assert!(!S::isEmpty(t));
    Ok(())
}

// ── add / hasKey ──────────────────────────────────────────────────────────────

#[test]
fn test_haskey_empty_returns_false() -> Result<()> {
    let t = S::new();
    assert!(!S::hasKey(t, literal!("anything"))?);
    Ok(())
}

#[test]
fn test_add_and_haskey() -> Result<()> {
    let t = set_of(&["alpha", "beta", "gamma"])?;
    assert!(S::hasKey(t.clone(), literal!("alpha"))?);
    assert!(S::hasKey(t.clone(), literal!("beta"))?);
    assert!(S::hasKey(t.clone(), literal!("gamma"))?);
    Ok(())
}

#[test]
fn test_haskey_absent() -> Result<()> {
    let t = set_of(&["alpha", "beta"])?;
    assert!(!S::hasKey(t, literal!("gamma"))?);
    Ok(())
}

#[test]
fn test_add_duplicate_no_growth() -> Result<()> {
    let t = set_of(&["dup", "dup", "dup"])?;
    assert_eq!(keys_vec(t), vec!["dup"]);
    Ok(())
}

// ── listKeys ordering ─────────────────────────────────────────────────────────

#[test]
fn test_listkeys_ascending_order() -> Result<()> {
    // Insert in deliberately non-sorted order.
    let t = set_of(&["banana", "apple", "cherry", "date"])?;
    assert_eq!(
        keys_vec(t),
        vec!["apple", "banana", "cherry", "date"]
    );
    Ok(())
}

#[test]
fn test_listkeys_empty() {
    let t = S::new();
    assert_eq!(keys_vec(t), Vec::<String>::new());
}

#[test]
fn test_listkeys_single() -> Result<()> {
    let t = set_of(&["solo"])?;
    assert_eq!(keys_vec(t), vec!["solo"]);
    Ok(())
}

#[test]
fn test_listkeysreverse_descending_order() -> Result<()> {
    let t = set_of(&["banana", "apple", "cherry"])?;
    let list = S::listKeysReverse(t, metamodelica::nil());
    let mut rev = vec![];
    for k in &*list { rev.push(k.to_string()); }
    assert_eq!(rev, vec!["cherry", "banana", "apple"]);
    Ok(())
}

// ── addList ───────────────────────────────────────────────────────────────────

#[test]
fn test_addlist_basic() -> Result<()> {
    let lst = list![literal!("c"), literal!("a"), literal!("b")];
    let t = S::addList(S::new(), lst)?;
    assert_eq!(keys_vec(t), vec!["a", "b", "c"]);
    Ok(())
}

#[test]
fn test_addlist_empty_list() -> Result<()> {
    let lst: Arc<List<ArcStr>> = metamodelica::nil();
    let t = S::addList(S::new(), lst)?;
    assert!(S::isEmpty(t));
    Ok(())
}

// ── join ──────────────────────────────────────────────────────────────────────

#[test]
fn test_join_disjoint() -> Result<()> {
    let t1 = set_of(&["a", "b"])?;
    let t2 = set_of(&["c", "d"])?;
    let joined = S::join(t1, t2)?;
    assert_eq!(keys_vec(joined), vec!["a", "b", "c", "d"]);
    Ok(())
}

#[test]
fn test_join_overlapping() -> Result<()> {
    let t1 = set_of(&["a", "b", "c"])?;
    let t2 = set_of(&["b", "c", "d"])?;
    let joined = S::join(t1, t2)?;
    // No duplicates
    assert_eq!(keys_vec(joined), vec!["a", "b", "c", "d"]);
    Ok(())
}

#[test]
fn test_join_with_empty() -> Result<()> {
    let t = set_of(&["x", "y"])?;
    let empty = S::new();
    let joined = S::join(t.clone(), empty)?;
    assert_eq!(keys_vec(joined), keys_vec(t));
    Ok(())
}

// ── keyCompare / keyStr ───────────────────────────────────────────────────────

#[test]
fn test_key_compare_equal() {
    assert_eq!(S::keyCompare(literal!("abc"), literal!("abc")), 0);
}

#[test]
fn test_key_compare_less() {
    assert_eq!(S::keyCompare(literal!("abc"), literal!("xyz")), -1);
}

#[test]
fn test_key_compare_greater() {
    assert_eq!(S::keyCompare(literal!("xyz"), literal!("abc")), 1);
}

#[test]
fn test_keystr() {
    let k = literal!("hello");
    assert_eq!(S::keyStr(k.clone()), k);
}

// ── printNodeStr / printTreeStr ───────────────────────────────────────────────

#[test]
fn test_print_node_str_leaf() -> Result<()> {
    let t = set_of(&["only"])?;
    let s = S::printNodeStr(t)?;
    assert_eq!(s, literal!("only"));
    Ok(())
}

#[test]
fn test_print_tree_str_empty() -> Result<()> {
    let s = S::printTreeStr(S::new())?;
    assert_eq!(s, literal!("EMPTY()"));
    Ok(())
}

// ── smallestKey ──────────────────────────────────────────────────────────────
//
// NOTE: smallestKey is named as if it returns the minimum key, but the
// MetaModelica source (BaseAvlSet.mo) recurses RIGHT (towards larger keys):
//
//   case NODE(right = EMPTY()) then tree.key;
//   case NODE()               then smallestKey(tree.right);
//   case LEAF()               then tree.key;
//
// The Rust code faithfully reproduces this, so smallestKey actually returns
// the MAXIMUM (rightmost) key.  The test below documents that behaviour.

#[test]
fn test_smallest_key_returns_rightmost() -> Result<()> {
    let t = set_of(&["b", "a", "c"])?;
    // MetaModelica's smallestKey recurses right, so it finds the maximum.
    let k = S::smallestKey(t)?;
    assert_eq!(k, literal!("c"),
        "smallestKey recurses right (matching MetaModelica source) and returns the maximum key");
    Ok(())
}

#[test]
fn test_smallest_key_single_element() -> Result<()> {
    let t = set_of(&["only"])?;
    // Single-element tree: leaf node. This case works correctly.
    let k = S::smallestKey(t)?;
    assert_eq!(k, literal!("only"));
    Ok(())
}

// ── intersection ─────────────────────────────────────────────────────────────
//
// Intersection splits two sets into three parts:
//   (elements in both,  elements only in set1,  elements only in set2)
//
// NOTE: When the sorted key-lists are walked in lock-step and one side's
// remaining list becomes empty, the algorithm breaks without recording the
// "current" key of the other side into the rest-set.  The result is that one
// element is silently dropped.
//
// Concrete example:  tree1={a,b,c}  tree2={b,d}
//   Walk:  a<b → rest1←a, advance k1→b
//          b=b → intersect←b, advance both: k1=c, k2=d, keylist2=[]
//          c<d → rest1←c, keylist1=[] → BREAK  (k2=d never put in rest2)
//   Actual rest2 = {} (d is dropped)
//
// The MetaModelica source (BaseAvlSet.mo) has the same behaviour; the Rust
// code faithfully reproduces it.  The tests below document the actual output.

#[test]
fn test_intersection_basic() -> Result<()> {
    let t1 = set_of(&["a", "b", "c"])?;
    let t2 = set_of(&["b", "c", "d"])?;
    let (intersect, rest1, rest2) = S::intersection(t1, t2)?;
    assert_eq!(keys_vec(intersect), vec!["b", "c"]);
    assert_eq!(keys_vec(rest1),     vec!["a"]);
    assert_eq!(keys_vec(rest2),     vec!["d"]);
    Ok(())
}

#[test]
fn test_intersection_empty_left() -> Result<()> {
    let t1 = S::new();
    let t2 = set_of(&["a", "b"])?;
    let (intersect, rest1, rest2) = S::intersection(t1, t2)?;
    assert!(S::isEmpty(intersect));
    assert!(S::isEmpty(rest1));
    assert_eq!(keys_vec(rest2), vec!["a", "b"]);
    Ok(())
}

#[test]
fn test_intersection_empty_right() -> Result<()> {
    let t1 = set_of(&["a", "b"])?;
    let t2 = S::new();
    let (intersect, rest1, rest2) = S::intersection(t1, t2)?;
    assert!(S::isEmpty(intersect));
    assert_eq!(keys_vec(rest1), vec!["a", "b"]);
    assert!(S::isEmpty(rest2));
    Ok(())
}

// Disjoint sets: walk of [a,c] vs [b,d]:
//   a<b → rest1←a, advance k1→c
//   c>b → rest2←b, advance k2→d (k2=d, keylist2=[])
//   c<d → rest1←c, keylist1=[] → BREAK  (k2=d is the dropped element)
// MetaModelica source gives: rest2 = {b}  (d is lost, matching the algorithm)
#[test]
fn test_intersection_disjoint() -> Result<()> {
    let t1 = set_of(&["a", "c"])?;
    let t2 = set_of(&["b", "d"])?;
    let (intersect, rest1, rest2) = S::intersection(t1, t2)?;
    assert!(S::isEmpty(intersect));
    assert_eq!(keys_vec(rest1), vec!["a", "c"]);
    // MetaModelica algorithm drops the last-advanced k2 ('d') when keylist1
    // runs out; rest2 contains only what was explicitly recorded before the break.
    assert_eq!(keys_vec(rest2), vec!["b"]);
    Ok(())
}

// Isolates the "dropped last-advanced k2" behaviour:
//   tree1={a,b,c}  tree2={b,d}
//   MetaModelica result: intersect={b}, rest1={a,c}, rest2={} (d is dropped)
#[test]
fn test_intersection_orphaned_k2_bug() -> Result<()> {
    let t1 = set_of(&["a", "b", "c"])?;
    let t2 = set_of(&["b", "d"])?;
    let (intersect, rest1, rest2) = S::intersection(t1, t2)?;
    assert_eq!(keys_vec(intersect), vec!["b"]);
    assert_eq!(keys_vec(rest1), vec!["a", "c"]);
    // MetaModelica algorithm: k2='d' is advanced out of keylist2 but keylist1
    // then runs out, causing a break before 'd' is recorded in rest2.
    assert!(S::isEmpty(rest2));
    Ok(())
}

// Symmetric case: dropped last-advanced k1.
//   tree1={b,d}  tree2={a,b,c}
//   MetaModelica result: intersect={b}, rest1={} (d is dropped), rest2={a,c}
#[test]
fn test_intersection_orphaned_k1_bug() -> Result<()> {
    let t1 = set_of(&["b", "d"])?;
    let t2 = set_of(&["a", "b", "c"])?;
    let (intersect, rest1, rest2) = S::intersection(t1, t2)?;
    assert_eq!(keys_vec(intersect), vec!["b"]);
    // MetaModelica algorithm: k1='d' is advanced out of keylist1 but keylist2
    // then runs out, causing a break before 'd' is recorded in rest1.
    assert!(S::isEmpty(rest1));
    assert_eq!(keys_vec(rest2), vec!["a", "c"]);
    Ok(())
}
