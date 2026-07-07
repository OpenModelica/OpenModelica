//! String hashing builtins (djb2 / sdbm).

use arcstr::ArcStr;

/// Returns a hash of the string using Rust's built-in hash.
pub fn stringHash(str: ArcStr) -> i32 {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::Hash;
    use std::hash::Hasher;
    let mut hasher = DefaultHasher::new();
    str.hash(&mut hasher);
    hasher.finish() as i32
}

/// Reduces a 64-bit djb2 accumulator to the non-negative `Integer` (i32) the
/// MetaModelica builtins return. The C runtime (`meta_modelica_builtin.c`)
/// computes djb2 in a 64-bit word and returns `labs()` of it; mirror that by
/// taking the magnitude and keeping the low 31 bits, so the result is always
/// `>= 0`. A non-negative hash matters wherever it reaches a textual context —
/// e.g. `Util.hashFileNamePrefix` embeds `intString(hash)` in generated file
/// and directory names, and a leading '-' from a negative value breaks the
/// shell commands (`rm -rf -56.fmutmp`) the generated makefiles run on them.
#[inline]
fn djb2_to_integer(hash: i64) -> i32 {
    (hash.unsigned_abs() & i32::MAX as u64) as i32
}

/// Returns a DJB2 hash of the string.
/// DJB2 algorithm: hash = hash * 33 + byte
///
/// Accumulated in i64 to match the C runtime's 64-bit `unsigned long` recurrence
/// (the i32 port previously wrapped at 32 bits, diverging from C and collapsing
/// long strings), then returned as a non-negative i32 — see [`djb2_to_integer`].
pub fn stringHashDjb2(str: ArcStr) -> i32 {
    let mut hash: i64 = 5381;
    for &byte in str.as_bytes() {
        hash = hash.wrapping_mul(33).wrapping_add(byte as i64);
    }
    djb2_to_integer(hash)
}

/// Continues computing a DJB2 hash by adding another string to it. The incoming
/// `hash` is the (already non-negative) result of a previous step; accumulation
/// proceeds in i64 and the result is reduced back to a non-negative i32.
pub fn stringHashDjb2Continue(str: ArcStr, hash: i32) -> i32 {
    let mut h = hash as i64;
    for &byte in str.as_bytes() {
        h = h.wrapping_mul(33).wrapping_add(byte as i64);
    }
    djb2_to_integer(h)
}

/// Computes a DJB2 hash and applies modulo without intermediate overflow issues.
/// Mirrors the C runtime: the 64-bit hash is reduced modulo `mod_val` using
/// unsigned arithmetic, so the result lies in `[0, mod_val)`.
pub fn stringHashDjb2Mod(str: ArcStr, mod_val: i32) -> i32 {
    if mod_val == 0 {
        return 0;
    }
    let mut hash: i64 = 5381;
    for &byte in str.as_bytes() {
        hash = hash.wrapping_mul(33).wrapping_add(byte as i64);
    }
    ((hash as u64) % (mod_val as u32 as u64)) as i32
}

/// Returns an SDBM hash of the string.
/// SDBM algorithm: hash = byte + (hash << 6) + (hash << 16) - hash
pub fn stringHashSdbm(str: ArcStr) -> i32 {
    let mut hash: i32 = 0;
    for &byte in str.as_bytes() {
        hash = byte as i32 + (hash << 6) + (hash << 16) - hash;
    }
    hash
}

#[cfg(test)]
#[allow(unused_imports)]
mod tests {
    use super::*;
    use crate::*;
    use std::sync::Arc;
    use std::rc::Rc;
    use arcstr::{literal, ArcStr};
    mod string_hash_tests {
        use super::*;

        #[test]
        fn test_string_hash_djb2() {
            // DJB2 of "a" = 5381 * 33 + 97 = 177700 + 97 = 177797
            assert_eq!(stringHashDjb2(literal!("a")), 5381_i32.wrapping_mul(33).wrapping_add(97));
            assert_eq!(stringHashDjb2(literal!("")), 5381);
        }

        #[test]
        fn test_string_hash_djb2_continue() {
            // Starting from the hash of "ab" and adding "c" gives the same as
            // hashing "abc" from scratch. The strings are kept short so every
            // intermediate value fits a non-negative i32: the `Continue` API
            // passes the running hash as an `Integer` (i32), so the chain
            // identity only holds while no intermediate has been reduced (it
            // matches the C runtime, whose `labs()`/64-bit width has the same
            // boundary limitation).
            let h1 = stringHashDjb2(literal!("ab"));
            let combined = stringHashDjb2Continue(literal!("c"), h1);
            assert_eq!(combined, stringHashDjb2(literal!("abc")));
        }

        #[test]
        fn test_string_hash_djb2_mod() {
            let h = stringHashDjb2Mod(literal!("hello"), 100);
            assert!(h >= 0 && h < 100);
            assert_eq!(stringHashDjb2Mod(literal!("hello"), 0), 0);
        }

        #[test]
        fn test_string_hash_sdbm() {
            // SDBM of "a" = 97 + 0 + 0 - 0 = 97
            assert_eq!(stringHashSdbm(literal!("a")), 97);
            assert_eq!(stringHashSdbm(literal!("")), 0);
        }

        #[test]
        fn test_string_hash_consistency() {
            // Same string should produce same hash
            assert_eq!(stringHash(literal!("test")), stringHash(literal!("test")));
        }
    }
}
