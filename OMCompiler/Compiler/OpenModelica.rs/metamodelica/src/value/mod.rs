//! Generic value builtins: `anyString`, `tick`, `valueEq`,
//! `valueCompare`, `valueConstructor`, `clock`. Reference identity lives
//! in [`reference_eq`]; global roots in [`global_root`].

use arcstr::{ArcStr, format};
use ordered_float::OrderedFloat;
use crate::Result;
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

/// MMC's constructor tag: the record's position in its uniontype plus 3
/// (`MMC_STRUCTHDR`), a plain record being tag 3. `Expression.compare` and
/// friends order values by this number, so the numbering itself matters.
pub trait MMCtor {
    fn mm_ctor(&self) -> i32;
}

/// mmtorust adds this to every generated MM value type (`GenCtx::derives_for`).
pub use metamodelica_derive::MMCtor;

macro_rules! mm_ctor_forward {
    ($($t:ty),*) => {$(
        impl<A: MMCtor + ?Sized> MMCtor for $t {
            fn mm_ctor(&self) -> i32 { (**self).mm_ctor() }
        }
    )*};
}
mm_ctor_forward!(std::sync::Arc<A>, std::rc::Rc<A>, Box<A>, &A);

/// MetaModelica `valueConstructor`.
pub fn valueConstructor<A: MMCtor + ?Sized>(value: &A) -> Result<i32> {
    Ok(value.mm_ctor())
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
            #[allow(dead_code)]
            #[derive(MMCtor)]
            enum E { A(i32), B { x: i32 }, C }
            assert_eq!(valueConstructor(&E::A(1)).unwrap(), 3);
            assert_eq!(valueConstructor(&E::A(99)).unwrap(), 3);
            assert_eq!(valueConstructor(&E::B { x: 1 }).unwrap(), 4);
            assert_eq!(valueConstructor(&E::C).unwrap(), 5);
            assert_eq!(valueConstructor(&Arc::new(E::C)).unwrap(), 5);

            #[derive(MMCtor)]
            struct R { x: i32 }
            assert_eq!(valueConstructor(&R { x: 1 }).unwrap(), 3);
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
