//! `StaticArray<T>` — `Sync` read-only storage for module-level tables.

use std::sync::Arc;
use crate::Array;
use crate::array::arrayFromVec;

/// Storage for module-level immutable arrays (lexer/parser tables built from
/// `MetaModelica.Dangerous.listArrayLiteral` and similar constant
/// `array<T>` declarations).
///
/// The mutable [`Array<T>`] type is `Rc<RefCell<Vec<T>>>`, which is **not**
/// `Sync` and therefore cannot be placed inside `pub static LazyLock<...>`.
/// MM-level concurrency is single-threaded, so the unsync-ness is the right
/// trade-off for general-purpose arrays — but constant tables, which are
/// never written to after construction, do not need `RefCell` at all.
/// `StaticArray<T>` wraps the data in `Arc<Vec<T>>` instead, which **is**
/// `Sync + Send` (for `T: Sync + Send`) and thus admissible as a static.
///
/// The API exposed mirrors the parts of [`Array<T>`] that read-only call
/// sites use:
///
/// * [`StaticArray::borrow`] returns `&Vec<T>`, matching the use of
///   `RefCell::borrow` on `Array<T>` — generated code does
///   `TABLE.borrow()[idx]` and that resolves identically here.
/// * The inherent [`StaticArray::clone`] returns an `Array<T>`, **not**
///   `Self`. Generated code occasionally does `TABLE.clone()` and passes
///   the result to a function whose MM-level parameter type is
///   `array<T>` (e.g. `checkArrayModelica`). To keep those call sites
///   working without a codegen-side rewrite, `.clone()` materialises a
///   fresh mutable `Array<T>` (deep copy). Use [`StaticArray::share`] to
///   get a cheap aliasing copy of the `StaticArray` itself.
#[derive(Debug)]
pub struct StaticArray<T> {
    inner: Arc<Vec<T>>,
}

impl<T> StaticArray<T> {
    /// Wraps a `Vec<T>` into a read-only `StaticArray<T>`.
    #[inline]
    pub fn new(v: Vec<T>) -> Self {
        StaticArray { inner: Arc::new(v) }
    }

    /// Returns a borrow of the underlying vector. Named `borrow` to match
    /// `RefCell::borrow` so generated indexing code (`table.borrow()[i]`)
    /// works against both `Array<T>` and `StaticArray<T>`.
    #[inline]
    pub fn borrow(&self) -> &Vec<T> {
        &self.inner
    }

    #[inline]
    pub fn len(&self) -> usize {
        self.inner.len()
    }

    #[inline]
    pub fn is_empty(&self) -> bool {
        self.inner.is_empty()
    }

    /// Cheap aliasing copy of this `StaticArray` (Arc refcount bump).
    /// Use this when you want to keep `StaticArray<T>` semantics; use
    /// `.clone()` (the inherent method below) when you need a fresh
    /// mutable `Array<T>`.
    #[inline]
    pub fn share(&self) -> StaticArray<T> {
        StaticArray { inner: Arc::clone(&self.inner) }
    }
}

impl<T: Clone> StaticArray<T> {
    /// Materialises a fresh mutable [`Array<T>`] by element-wise cloning
    /// the static storage. See the type-level docs for the rationale —
    /// this is the form expected by MM-translated call sites that pass
    /// a static table into a function whose parameter type is
    /// `array<T>`.
    ///
    /// Note: this is an *inherent* method, not a `Clone` impl. We deliberately
    /// do **not** implement `Clone`, so `table.clone()` resolves to this
    /// method via method-lookup; calls through `Clone::clone` would not.
    #[inline]
    #[allow(clippy::should_implement_trait)]
    pub fn clone(&self) -> Array<T> {
        arrayFromVec((*self.inner).clone())
    }
}
