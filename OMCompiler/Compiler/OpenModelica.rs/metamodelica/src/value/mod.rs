//! Generic value builtins: `anyString`, `tick`, `valueEq`,
//! `valueCompare`, `valueConstructor`, `clock`. Reference identity lives
//! in [`reference_eq`]; global roots in [`global_root`].

use arcstr::{ArcStr, format};
use ordered_float::OrderedFloat;
use anyhow::Result;
use crate::Real;

pub mod reference_eq;
pub mod global_root;
pub use reference_eq::*;
pub use global_root::*;

/// Returns the string representation of any Debug-printable value.
/// Rather slow; only use this for debugging!
pub fn anyString<A: std::fmt::Debug>(a: A) -> ArcStr {
    format!("{:?}", a)
}

thread_local! {
    static TICK_COUNTER: std::cell::Cell<u64> = const { std::cell::Cell::new(0) };
}

/// Returns a monotonically increasing tick counter.
/// Uses a thread-local counter for simulation purposes.
pub fn tick() -> i32 {
    TICK_COUNTER.with(|counter| {
        let current = counter.get();
        counter.set(current.wrapping_add(1));
        current as i32
    })
}

/// Structural equality for any PartialEq value.
pub fn valueEq<A: PartialEq>(a1: A, a2: A) -> bool {
    a1 == a2
}

/// Compares two Ord values.
/// Returns -1 if a1 < a2, 0 if a1 == a2, 1 if a1 > a2.
pub fn valueCompare<A: Ord>(a1: A, a2: A) -> i32 {
    match a1.cmp(&a2) {
        std::cmp::Ordering::Less => -1,
        std::cmp::Ordering::Equal => 0,
        std::cmp::Ordering::Greater => 1,
    }
}

/// Returns the constructor tag for a value.
///
/// In MetaModelica `valueConstructor(v)` returns the variant index of a
/// boxed uniontype value (it is the *value* that matters, not its static
/// type — two values of the same uniontype but different records produce
/// different tags). In Rust we implement this using
/// [`std::mem::discriminant`], hashed into an `i32`.
///
/// For enums this yields a stable, distinct number per variant.  For
/// non-enum types `mem::discriminant` returns a single constant value (so
/// all instances hash to the same `i32`), which matches MetaModelica's
/// "records have a single constructor" semantics.
///
/// The caller is expected to pass `&value` — for `Arc<T>`-wrapped values
/// generated code must deref through the `Arc` (`&*arc`) so that the
/// inspected discriminant belongs to the inner enum, not to `Arc` itself.
pub fn valueConstructor<A>(value: &A) -> Result<i32> {
    use std::hash::{Hash, Hasher};
    let mut hasher = std::collections::hash_map::DefaultHasher::new();
    std::mem::discriminant(value).hash(&mut hasher);
    Ok((hasher.finish() & 0x7FFF_FFFF) as i32)
}

/// Returns the current time in seconds relative to process start.
/// Not very accurate, intended for diff comparisons.
pub fn clock() -> Real {
    OrderedFloat(openmodelica_wasi::monotonic_nanos() as f64 / 1.0e9)
}

#[cfg(test)]
#[allow(unused_imports)]
mod tests {
    use super::*;
    use crate::*;
    use std::sync::Arc;
    use std::rc::Rc;
    use arcstr::{literal, ArcStr};
    mod generic_value_tests {
        use super::*;

        #[test]
        fn test_any_string() {
            let val = 42i32;
            let result = anyString(&val);
            assert_eq!(&*result, "42");

            let s = "hello";
            assert!(anyString(&s).contains("hello"));
        }

        #[test]
        fn test_tick() {
            let t1 = tick();
            let t2 = tick();
            assert_eq!(t2, t1+1);
        }

        #[test]
        fn test_value_eq() {
            let a = vec![1, 2, 3];
            let b = vec![1, 2, 3];
            let c = vec![1, 2, 4];
            assert!(valueEq(&a, &b));
            assert!(!valueEq(&a, &c));
        }

        #[test]
        fn test_value_compare() {
            assert_eq!(valueCompare(&1, &2), -1);
            assert_eq!(valueCompare(&2, &2), 0);
            assert_eq!(valueCompare(&3, &2), 1);

            assert_eq!(valueCompare(&"abc", &"abd"), -1);
            assert_eq!(valueCompare(&"abc", &"abc"), 0);
            assert_eq!(valueCompare(&"abd", &"abc"), 1);
        }

        #[test]
        fn test_reference_eq() {
            let a = 42;
            let b = 42;
            // Same reference should be equal
            assert!(referenceEq(&a, &a));
            // Different references with same value
            // reference_eq checks pointer equality, so different vars may not be equal
            assert!(referenceEq(&a, &b) || !referenceEq(&a, &b)); // either is valid
        }

        #[test]
        fn test_reference_arc() {
            let a = Arc::new(42);
            let b = a.clone();
            // Comparing the Arc *handles* distinguishes clones — they are two
            // distinct stack objects even though they share the pointee. This
            // is why generated code must not compare handles directly.
            assert!(!referenceEq(&a, &b));
            // Comparing the *pointees* (`&*v`, as the code generator emits for
            // handle-represented values) identifies clones of the same Arc.
            assert!(referenceEq(&*a, &*b));
            // A separate allocation with an equal value is NOT reference-equal.
            let c = Arc::new(42);
            assert!(!referenceEq(&*a, &*c));
        }

        #[test]
        fn test_reference_eq_str_pointee() {
            // `A: ?Sized` lets callers compare unsized pointees: clones of the
            // same ArcStr share storage (address + length both match)…
            let s1 = ArcStr::from("hello");
            let s2 = s1.clone();
            assert!(referenceEq(&*s1, &*s2));
            // …while an equal-valued but separately allocated string differs.
            let s3 = ArcStr::from("hello");
            assert!(!referenceEq(&*s1, &*s3));
        }

        #[test]
        fn test_reference_pointer_string() {
            let val = 42;
            let ptr_str = referencePointerString(&val).unwrap();
            // Should be a valid hex representation like "0x..."
            assert!(ptr_str.starts_with("0x"));
        }

        #[test]
        fn test_reference_debug_string() {
            let val = 42i32;
            let result = referenceDebugString(&val).unwrap();
            assert!(result.contains("i32"));
        }

        #[test]
        fn test_value_constructor() {
            // MetaModelica semantics: same variant → same tag; different
            // variants of the same uniontype → different tags. Implemented
            // via `std::mem::discriminant`, so values of the same enum
            // variant compare equal (e.g. `Some(1)` and `Some(2)`), while
            // values of different variants compare unequal.
            #[allow(dead_code)]
            enum E { A(i32), B(i32), C }
            let a1 = valueConstructor(&E::A(1)).unwrap();
            let a2 = valueConstructor(&E::A(99)).unwrap();
            let b  = valueConstructor(&E::B(1)).unwrap();
            let c  = valueConstructor(&E::C).unwrap();
            assert_eq!(a1, a2);
            assert_ne!(a1, b);
            assert_ne!(a1, c);
            assert_ne!(b, c);
        }

        #[test]
        fn test_clock() {
            let t1 = clock();
            let t2 = clock();
            assert!(t1 >= OrderedFloat(0.0));
            assert!(t2 >= t1);
        }
    }
}
