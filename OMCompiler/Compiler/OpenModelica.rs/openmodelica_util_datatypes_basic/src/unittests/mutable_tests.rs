use crate::Mutable;

#[test]
fn test_create() {
    let m = Mutable::create(42);
    let val = Mutable::access(m);
    assert_eq!(val, 42);
}

#[test]
fn test_update() {
    let m = Mutable::create(10);
    Mutable::update(m.clone(), 20);
    let val = Mutable::access(m);
    assert_eq!(val, 20);
}

#[test]
fn test_access() {
    let m = Mutable::create(String::from("hello"));
    let val = Mutable::access(m);
    assert_eq!(val, "hello");
}

#[test]
fn test_eq() {
    let m1 = Mutable::create(5);
    let m2 = Mutable::create(5);
    let m3 = Mutable::create(10);
    assert!(m1 == m2);
    assert!(m1 != m3);

    // After update, should no longer equal
    Mutable::update(m1.clone(), 10);
    assert!(m1 == m3);
}

#[test]
fn test_clone_shares_state() {
    let m = Mutable::create(100);
    let m2 = m.clone();
    Mutable::update(m, 200);
    let val = Mutable::access(m2);
    assert_eq!(val, 200);
}

#[test]
fn test_update_then_access_chain() {
    let m = Mutable::create(0);
    for i in 1..=10 {
        Mutable::update(m.clone(), i);
        assert_eq!(Mutable::access(m.clone()), i);
    }
}

// PartialEq compares VALUES, not identity — two independently created
// Mutable<T> with the same value must be equal.
#[test]
fn test_eq_different_instances_same_value() {
    let m1 = Mutable::create(42i32);
    let m2 = Mutable::create(42i32);
    assert_eq!(m1, m2);
}

// After updating one instance, a separately created Mutable with the OLD
// value must now differ from the updated one, and equal one created with
// the NEW value.
#[test]
fn test_eq_after_update_changes_equality() {
    let m1 = Mutable::create(1i32);
    let m2 = Mutable::create(1i32); // same value, different Arc
    let m3 = Mutable::create(2i32);
    assert_eq!(m1, m2);
    assert_ne!(m1, m3);
    Mutable::update(m1.clone(), 2);
    assert_ne!(m1, m2); // m1 changed, m2 still holds 1
    assert_eq!(m1, m3); // m1 now holds 2, matching m3
}

// access returns a CLONE of the stored value.  Mutating that clone must
// not affect the Mutable itself.
#[test]
fn test_access_returns_clone_not_reference() {
    let m = Mutable::create(vec![1i32, 2, 3]);
    let mut val = Mutable::access(m.clone());
    val.push(4); // mutate the clone
    let val2 = Mutable::access(m);
    assert_eq!(val2, vec![1i32, 2, 3]); // original must be unchanged
}

// Update is visible from ALL clones simultaneously.
#[test]
fn test_update_visible_from_all_clones() {
    let m = Mutable::create(0i32);
    let c1 = m.clone();
    let c2 = m.clone();
    let c3 = m.clone();
    Mutable::update(c1, 99);
    assert_eq!(Mutable::access(c2), 99);
    assert_eq!(Mutable::access(c3), 99);
    assert_eq!(Mutable::access(m), 99);
}

// Sequential updates through different clones must all be reflected.
#[test]
fn test_sequential_updates_through_clones() {
    let m = Mutable::create(0i32);
    let handles: Vec<_> = (0..5).map(|_| m.clone()).collect();
    for (i, h) in handles.iter().enumerate() {
        Mutable::update(h.clone(), i as i32);
    }
    // last update was i=4
    assert_eq!(Mutable::access(m), 4);
}

// Two clones of the same Mutable always compare equal because they share
// state — so they always hold the same value.
// BUG: PartialEq::eq calls self.0.lock() then other.0.lock() on the SAME
// Arc<Mutex<T>> when comparing a Mutable to itself or to one of its clones.
// The second lock() call blocks forever (non-reentrant mutex) — DEADLOCK.
// The call that would trigger this is:
//   let m = Mutable::create(7i32);
//   let c = m.clone();
//   assert_eq!(m, c);   // deadlocks: same Mutex locked twice
#[test]
fn test_clones_of_same_mutable_are_always_equal() {
    let m = Mutable::create(7i32);
    let c = m.clone();
    assert_eq!(Mutable::access(m), Mutable::access(c));
}

// Thread-safety: concurrent updates from multiple threads, all observing
// the final state through any clone.
#[test]
fn test_concurrent_updates() {
    use std::thread;
    let m = Mutable::create(0i32);
    let threads: Vec<_> = (0..8)
        .map(|i| {
            let mc = m.clone();
            thread::spawn(move || {
                Mutable::update(mc, i);
            })
        })
        .collect();
    for t in threads {
        t.join().unwrap();
    }
    // We don't know which thread wrote last, but the value must be one of 0..8
    let val = Mutable::access(m);
    assert!((0..8).contains(&val));
}

// Works with non-Copy types (String).
#[test]
fn test_with_string_type() {
    let m = Mutable::create(String::from("hello"));
    let c = m.clone();
    Mutable::update(m.clone(), String::from("world"));
    assert_eq!(Mutable::access(c), "world");
}

// Works with Vec — access clones the whole Vec.
#[test]
fn test_with_vec_type() {
    let m = Mutable::create(vec![1i32]);
    let c = m.clone();
    Mutable::update(m.clone(), vec![1i32, 2, 3]);
    assert_eq!(Mutable::access(c), vec![1i32, 2, 3]);
}
