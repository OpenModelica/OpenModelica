// Tests for the external object System.StringAllocator and its companions
// stringAllocatorStringCopy / stringAllocatorResult (manual ports of the
// inline C helpers in ~/OpenModelica/OMCompiler/Compiler/Util/System.mo).
//
// The allocator is a fixed-size byte buffer filled piecewise at caller-
// computed offsets; the call patterns below mirror its three users:
// StringUtil.repeat (forward, repeated segment), Initialization.
// warnAboutVars2Work (forward, prefix/str/suffix) and AbsynUtil.
// pathStringWork (forward and reverse segment order).

use arcstr::{ArcStr, literal};
use crate::StringUtil;
use crate::System;

fn result_string(sa: System::StringAllocator) -> ArcStr {
    System::stringAllocatorResult(sa, literal!(""))
}

#[test]
fn test_constructor_negative_size_fails() {
    assert!(System::StringAllocator(-1).is_err());
}

#[test]
fn test_empty_allocator_yields_empty_string() {
    let sa = System::StringAllocator(0).unwrap();
    assert_eq!(result_string(sa), literal!(""));
}

#[test]
fn test_forward_fill() {
    // Initialization.warnAboutVars2Work pattern: prefix + str + suffix.
    let sa = System::StringAllocator(9).unwrap();
    System::stringAllocatorStringCopy(sa.clone(), literal!("foo"), 0);
    System::stringAllocatorStringCopy(sa.clone(), literal!("bar"), 3);
    System::stringAllocatorStringCopy(sa.clone(), literal!("baz"), 6);
    assert_eq!(result_string(sa), literal!("foobarbaz"));
}

#[test]
fn test_reverse_fill_does_not_corrupt_earlier_segments() {
    // AbsynUtil.pathStringWork(reverse=true) pattern: segments are written
    // right-to-left. The C strcpy-based helper writes a trailing NUL over the
    // first byte of the previously written segment here; the Rust port copies
    // exactly the source bytes, so "a.b.c" reversed builds cleanly.
    let sa = System::StringAllocator(5).unwrap();
    // iteration 1 (count=0): name "a" ends the string, delimiter to its left
    System::stringAllocatorStringCopy(sa.clone(), literal!("a"), 4);
    System::stringAllocatorStringCopy(sa.clone(), literal!("."), 3);
    // iteration 2 (count=2): name "b", delimiter to its left
    System::stringAllocatorStringCopy(sa.clone(), literal!("b"), 2);
    System::stringAllocatorStringCopy(sa.clone(), literal!("."), 1);
    // iteration 3 (IDENT "c", count=4)
    System::stringAllocatorStringCopy(sa.clone(), literal!("c"), 0);
    assert_eq!(result_string(sa), literal!("c.b.a"));
}

#[test]
fn test_empty_source_is_a_no_op() {
    // C guards with `if (*source)`; an empty copy must not touch the buffer
    // (offset may even be out of range in the C version's callers).
    let sa = System::StringAllocator(2).unwrap();
    System::stringAllocatorStringCopy(sa.clone(), literal!("hi"), 0);
    System::stringAllocatorStringCopy(sa.clone(), literal!(""), 2);
    assert_eq!(result_string(sa), literal!("hi"));
}

#[test]
fn test_overwrite_is_allowed() {
    // The buffer is mutable in place; later copies may overwrite earlier ones.
    let sa = System::StringAllocator(3).unwrap();
    System::stringAllocatorStringCopy(sa.clone(), literal!("aaa"), 0);
    System::stringAllocatorStringCopy(sa.clone(), literal!("b"), 1);
    assert_eq!(result_string(sa), literal!("aba"));
}

#[test]
fn test_shared_handle_views_one_buffer() {
    // External objects have reference semantics: clones alias the same buffer.
    let sa = System::StringAllocator(2).unwrap();
    let alias = sa.clone();
    System::stringAllocatorStringCopy(alias, literal!("ok"), 0);
    assert_eq!(result_string(sa), literal!("ok"));
}

#[test]
#[should_panic(expected = "does not fit")]
fn test_out_of_bounds_copy_panics() {
    // C documents this as writing out of bounds; the Rust port panics instead.
    let sa = System::StringAllocator(3).unwrap();
    System::stringAllocatorStringCopy(sa, literal!("abc"), 1);
}

#[test]
#[should_panic(expected = "does not fit")]
fn test_negative_offset_panics() {
    let sa = System::StringAllocator(3).unwrap();
    System::stringAllocatorStringCopy(sa, literal!("a"), -1);
}

#[test]
fn test_string_util_repeat() {
    // StringUtil.repeat is the simplest real user of the allocator.
    assert_eq!(StringUtil::repeat(literal!("ab"), 3).unwrap(), literal!("ababab"));
    assert_eq!(StringUtil::repeat(literal!("x"), 1).unwrap(), literal!("x"));
    assert_eq!(StringUtil::repeat(literal!("ab"), 0).unwrap(), literal!(""));
}
