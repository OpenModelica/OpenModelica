#![allow(non_snake_case, dead_code, unused_macros)]
//! Translation of FrontEnd/MetaModelicaBuiltin.mo
//!
//! Built-in MetaModelica declarations translated to Rust.
//! All functions are translated even if Rust has built-in alternatives,
//! since these functions may be referenced by other translated modules.
//!
//! Datatype mapping:
//!   Integer -> i32
//!   Real -> OrderedFloat<f64> (aliased as `metamodelica::Real`)
//!   Boolean -> bool
//!   String -> String
//!   List<T> -> Arc<List<T>>           (persistent singly-linked list)
//!   array<T> -> Array<T> = Rc<RefCell<Vec<T>>>
//!
//! Note: MetaModelica uses 1-based indexing; Rust uses 0-based.
//! Functions that take indices expect 1-based indexing to match MetaModelica semantics.
//!
//! Array semantics: MetaModelica `array<T>` has reference (aliasing) semantics —
//! `arrayUpdate` mutates the underlying storage in place and the change is visible
//! through every alias of the array. We model that with `Rc<RefCell<Vec<T>>>`.
//! The compiler the bootstrap targets is single-threaded at the MM level, so
//! `Rc`/`RefCell` (no synchronization cost, deterministic borrow-violation panics)
//! is preferred over `Arc<Mutex<...>>` (lock+unlock per access, deadlock risk on
//! re-entrant callbacks). If MM-level concurrency is ever introduced, this alias
//! is the only thing that needs to change.

pub use ordered_float::OrderedFloat;
pub use num_traits::Float;

use std::rc::Rc;
use std::cell::RefCell;
pub mod gc;

/// MetaModelica `array<T>`. See module-level docs for rationale.
pub type Array<A> = Rc<RefCell<Vec<A>>>;

/// MetaModelica `Real`. Wraps `f64` with `OrderedFloat` so that values
/// containing `Real` can implement `Ord` / `Eq` / `Hash` — required for
/// derived `valueCompare` on enums such as `DAE::Exp` and `DAE::Type`.
/// NaN ordering follows `ordered_float` semantics (`NaN` > any non-NaN).
pub type Real = OrderedFloat<f64>;

// Modules (split out of the original monolithic lib.rs).
pub mod source_info;
pub mod boolean;
pub mod host_io;
pub mod assert;
pub mod integer;
pub mod real;
pub mod string;
pub mod list;
pub mod array;
pub mod value;
pub mod misc;
pub mod ext;
pub mod Dangerous;

// Flatten the public API back to the crate root: generated code refers
// to `metamodelica::<builtin>` regardless of which module now defines it.
pub use source_info::*;
pub use boolean::*;
pub use host_io::*;
pub use assert::*;
pub use integer::*;
pub use real::*;
pub use string::*;
pub use list::*;
pub use array::*;
pub use value::*;
pub use misc::*;

/// Wrap an infallible function value so it satisfies a function-pointer type
/// whose signature expects `Result<T>`.
///
/// MetaModelica function-typed parameters are uniformly lowered to
/// `fn(...) -> Result<T>` so that the same callback site can accept both
/// failing and non-failing callees. Codegen tracks which functions are
/// fallible (see `mmtorust::fallibility`); when an *infallible* function `f`
/// is passed by reference into a position that wants
/// `fn(A, B, ...) -> Result<T>`, codegen wraps it with `fnptr!(f)` so the
/// shapes line up without forcing every infallible function to materialise
/// a `Result`.
///
/// The macro is variadic in its argument list. Example expansions:
///
///   `fnptr!(g, A, B)`   →   `|a: A, b: B| -> Result<_> { Ok(g(a, b)) }`
///   `fnptr!(h, A)`      →   `|a: A| -> Result<_> { Ok(h(a)) }`
///   `fnptr!(noargs)`    →   `|| -> Result<_> { Ok(noargs()) }`
///
/// The closure does not capture by reference — the wrapped function is a
/// path expression (a function name or `Module::f`), which is already a
/// zero-sized `fn` item with no environment to capture.
///
/// **Note on cost**: the closure boxes nothing and the `Ok(..)` wrap is
/// trivially inlined by the optimiser. The point of the wrapper is purely
/// type-level; the runtime cost is the moral equivalent of `unwrap_unchecked`
/// in the reverse direction.
#[macro_export]
macro_rules! fnptr {
    // Zero-argument form.
    ($f:path) => {
        || -> ::anyhow::Result<_> { ::std::result::Result::Ok($f()) }
    };
    // 1+ argument form. The argument *types* must be supplied at the call
    // site so the closure's signature is unambiguous to the type system
    // (function pointers don't auto-infer parameter types).
    ($f:path $(, $t:ty)+ $(,)?) => {{
        // Generate fresh idents `__a0, __a1, …` for each type slot so the
        // macro stays type-driven (no second list of argument names needed
        // from the caller). The implementation expands one closure
        // parameter per `$t` via the `${index()}` builtin if available, but
        // we fall back to a hand-written tuple form for stability across
        // Rust versions: we accept up to 10 type arguments — enough for all
        // call sites we generate today (e.g. `NBJacobian.jacobianNone`, which
        // takes 9) — and the user gets a clear macro error otherwise.
        $crate::__fnptr_dispatch!($f $(, $t)+)
    }};
}

/// Internal helper for [`fnptr!`]: dispatches on arity (1..=10) without
/// requiring the unstable `${index()}` builtin. Each arm just spells out the
/// closure parameter names; adding more arms is mechanical if a generated
/// call site ever needs >8 arguments.
#[macro_export]
#[doc(hidden)]
macro_rules! __fnptr_dispatch {
    ($f:path, $t1:ty) =>
        { |a1: $t1| -> ::anyhow::Result<_> { ::std::result::Result::Ok($f(a1)) } };
    ($f:path, $t1:ty, $t2:ty) =>
        { |a1: $t1, a2: $t2| -> ::anyhow::Result<_> { ::std::result::Result::Ok($f(a1, a2)) } };
    ($f:path, $t1:ty, $t2:ty, $t3:ty) =>
        { |a1: $t1, a2: $t2, a3: $t3| -> ::anyhow::Result<_> { ::std::result::Result::Ok($f(a1, a2, a3)) } };
    ($f:path, $t1:ty, $t2:ty, $t3:ty, $t4:ty) =>
        { |a1: $t1, a2: $t2, a3: $t3, a4: $t4| -> ::anyhow::Result<_> { ::std::result::Result::Ok($f(a1, a2, a3, a4)) } };
    ($f:path, $t1:ty, $t2:ty, $t3:ty, $t4:ty, $t5:ty) =>
        { |a1: $t1, a2: $t2, a3: $t3, a4: $t4, a5: $t5| -> ::anyhow::Result<_> { ::std::result::Result::Ok($f(a1, a2, a3, a4, a5)) } };
    ($f:path, $t1:ty, $t2:ty, $t3:ty, $t4:ty, $t5:ty, $t6:ty) =>
        { |a1: $t1, a2: $t2, a3: $t3, a4: $t4, a5: $t5, a6: $t6| -> ::anyhow::Result<_> { ::std::result::Result::Ok($f(a1, a2, a3, a4, a5, a6)) } };
    ($f:path, $t1:ty, $t2:ty, $t3:ty, $t4:ty, $t5:ty, $t6:ty, $t7:ty) =>
        { |a1: $t1, a2: $t2, a3: $t3, a4: $t4, a5: $t5, a6: $t6, a7: $t7| -> ::anyhow::Result<_> { ::std::result::Result::Ok($f(a1, a2, a3, a4, a5, a6, a7)) } };
    ($f:path, $t1:ty, $t2:ty, $t3:ty, $t4:ty, $t5:ty, $t6:ty, $t7:ty, $t8:ty) =>
        { |a1: $t1, a2: $t2, a3: $t3, a4: $t4, a5: $t5, a6: $t6, a7: $t7, a8: $t8| -> ::anyhow::Result<_> { ::std::result::Result::Ok($f(a1, a2, a3, a4, a5, a6, a7, a8)) } };
    ($f:path, $t1:ty, $t2:ty, $t3:ty, $t4:ty, $t5:ty, $t6:ty, $t7:ty, $t8:ty, $t9:ty) =>
        { |a1: $t1, a2: $t2, a3: $t3, a4: $t4, a5: $t5, a6: $t6, a7: $t7, a8: $t8, a9: $t9| -> ::anyhow::Result<_> { ::std::result::Result::Ok($f(a1, a2, a3, a4, a5, a6, a7, a8, a9)) } };
    ($f:path, $t1:ty, $t2:ty, $t3:ty, $t4:ty, $t5:ty, $t6:ty, $t7:ty, $t8:ty, $t9:ty, $t10:ty) =>
        { |a1: $t1, a2: $t2, a3: $t3, a4: $t4, a5: $t5, a6: $t6, a7: $t7, a8: $t8, a9: $t9, a10: $t10| -> ::anyhow::Result<_> { ::std::result::Result::Ok($f(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)) } };
}
