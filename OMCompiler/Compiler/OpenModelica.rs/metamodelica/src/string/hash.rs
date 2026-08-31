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

/// `meta_modelica_builtin.c`'s `djb2_hash_continue`: a fixed-width recurrence.
#[inline]
fn djb2(bytes: &[u8], mut hash: u32) -> u32 {
    for &byte in bytes {
        hash = hash.wrapping_mul(33).wrapping_add(byte as u32);
    }
    hash
}

/// `MMC_HASH_MASK`. Keeps the hash non-negative, which matters where it reaches
/// a textual context: `Util.hashFileNamePrefix` puts `intString(hash)` in
/// generated directory names that the makefiles `rm -rf`.
const HASH_MASK: u32 = 0x7fff_ffff;

/// `djb2_hash_wide`: kept for `stringHashDjb2Mod`, whose remainder is baked
/// into generated string-switch `case` labels.
#[inline]
fn djb2_wide(bytes: &[u8]) -> u64 {
    let mut hash: u64 = 5381;
    for &byte in bytes {
        hash = hash.wrapping_mul(33).wrapping_add(byte as u64);
    }
    hash
}

/// Returns a DJB2 hash of the string.
/// DJB2 algorithm: hash = hash * 33 + byte
pub fn stringHashDjb2(str: ArcStr) -> i32 {
    (djb2(str.as_bytes(), 5381) & HASH_MASK) as i32
}

/// Continues computing a DJB2 hash by adding another string to it.
pub fn stringHashDjb2Continue(str: ArcStr, hash: i32) -> i32 {
    (djb2(str.as_bytes(), hash as u32) & HASH_MASK) as i32
}

/// Computes a DJB2 hash and applies modulo, giving a result in `[0, mod_val)`.
pub fn stringHashDjb2Mod(str: ArcStr, mod_val: i32) -> i32 {
    if mod_val == 0 {
        return 0;
    }
    (djb2_wide(str.as_bytes()) % (mod_val as u32 as u64)) as i32
}

/// Returns an SDBM hash of the string.
/// SDBM algorithm: hash = byte + (hash << 6) + (hash << 16) - hash
pub fn stringHashSdbm(str: ArcStr) -> i32 {
    let mut hash: u32 = 0;
    for &byte in str.as_bytes() {
        hash = (byte as u32)
            .wrapping_add(hash << 6)
            .wrapping_add(hash << 16)
            .wrapping_sub(hash);
    }
    (hash & HASH_MASK) as i32
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
            // Short strings only: the identity holds while no intermediate has
            // lost its top bit to HASH_MASK, as in the C runtime.
            let h1 = stringHashDjb2(literal!("ab"));
            let combined = stringHashDjb2Continue(literal!("c"), h1);
            assert_eq!(combined, stringHashDjb2(literal!("abc")));
        }

        #[test]
        fn test_string_hash_fixed_width() {
            // A string long enough to overflow the 32-bit accumulator.
            assert_eq!(stringHashDjb2(literal!("$SEED_ODE_JAC_ADJ.$DER.b")), 1541592153);
            assert_eq!(stringHashDjb2Mod(literal!("$RES_SIM_1"), 13), 4);
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
