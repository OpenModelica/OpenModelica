//! `list!`, `assign_field!`, `assign_variant_field!`, `var_field!`.

#[macro_export]
macro_rules! list {
    // Base case: empty list
    () => {
        std::sync::Arc::new($crate::List::Nil)
    };
    // Case with a trailing comma
    ( $($x:expr),*, ) => {
        $crate::list!($($x),*)
    };
    // General case: peel off the first element and recurse
    ( $x:expr, $($rest:expr),+ ) => {
        $crate::cons($x, $crate::list!($($rest),+))
    };
    // Single element case
    ( $x:expr ) => {
        $crate::cons($x, $crate::list!())
    };
}

/// Functionally update a single field of a record value stored as `Arc<T>`.
///
/// MetaModelica record update (`var.field := value`) has value semantics: a new
/// record is produced and rebound. We model the record as `Arc<T>` for cheap
/// sharing, so direct field mutation through the `Arc` is impossible. This macro
/// clones the underlying record (a shallow copy — the contained fields are
/// themselves cheap `Arc` handles or scalars), overwrites the targeted field on
/// the owned copy, and rebinds `$base` to a fresh `Arc<T>`.
///
/// For multi-record uniontypes (Rust enums), use `assign_variant_field!` instead:
/// the matched variant must be named explicitly because the enum tag is not
/// inferable from the macro's input position. With a single-record uniontype
/// (or any plain struct), this macro suffices.
#[macro_export]
macro_rules! assign_field {
    // One or more field assignments against the same `Arc<T>` base. The clone
    // and the `Arc::new` happen once for the whole batch, no matter how many
    // fields are updated. All assignments must target the same identifier; the
    // macro reuses `$base` as the storage and only matches the trailing entries
    // to keep the parser happy.
    (
        $base:ident . $first_field:ident = $first_value:expr
        $(, $_base:ident . $field:ident = $value:expr)*
        $(,)?
    ) => {{
        let mut __owned = (*$base).clone();
        __owned.$first_field = $first_value;
        $( __owned.$field = $value; )*
        $base = ::std::sync::Arc::new(__owned);
    }};
}

/// Like `assign_field!`, but for a uniontype-enum value whose currently matched
/// variant is known statically (e.g. inside a `match` arm or after a refutable
/// `let`-pattern). The variant path must be supplied so the destructure picks
/// the right arm; a runtime mismatch panics, which would indicate a codegen bug.
///
/// Example: `assign_variant_field!(node => NFInstNode::CLASS_NODE; ty = newTy);`
#[macro_export]
macro_rules! assign_variant_field {
    // One or more field assignments to a value already known to be a specific
    // variant (`$($variant)::+`). The destructure happens once; the field
    // bindings are then assigned in sequence on the owned copy. A runtime
    // variant mismatch panics — that would indicate a codegen bug.
    (
        $base:ident => $variant:path ;
        $first_field:ident = $first_value:expr
        $(, $field:ident = $value:expr)*
        $(,)?
    ) => {{
        let mut __owned = (*$base).clone();
        // Evaluate every value expression BEFORE entering an `if let` that
        // would introduce field-shorthand pattern bindings with the same name
        // as the field. Otherwise a call site like
        //   `assign_variant_field!(t => T::N; value = value.clone())`
        // would have `value.clone()` resolve to the &mut FieldType binding
        // produced by the destructure, not the outer local — silently turning
        // the assignment into a self-copy. We capture each value into `__v`
        // immediately before its assignment; `__v` is shadowed each iteration,
        // which is fine because it's consumed before the next `let __v = ...`.
        let __v = $first_value;
        if let $variant { $first_field, .. } = &mut __owned {
            *$first_field = __v;
        } else {
            panic!(
                "assign_variant_field!: expected variant {} but value held a different variant",
                stringify!($variant),
            );
        }
        $(
            let __v = $value;
            if let $variant { $field, .. } = &mut __owned {
                *$field = __v;
            } else {
                panic!(
                    "assign_variant_field!: expected variant {} but value held a different variant",
                    stringify!($variant),
                );
            }
        )*
        $base = ::std::sync::Arc::new(__owned);
    }};
}

/// Read a single field from a uniontype-enum value whose currently matched
/// variant is known statically (e.g. inside a `match` arm or after a refutable
/// `let`-pattern). MetaModelica syntax `v.field` is valid on a uniontype value
/// when the surrounding control flow proves `v` holds a particular record
/// variant; in Rust the enum has no such field directly, so the field must be
/// extracted by destructuring. This macro performs that destructure inline.
///
/// The returned value is a reference (`&FieldType`) borrowed from `$base`; the
/// caller is expected to clone it as appropriate. A runtime variant mismatch
/// panics, which would indicate a codegen bug.
///
/// Two input forms are supported:
///   - `var_field!(v.field, Pkg::Type::VARIANT)` for a plain (owned) enum value.
///   - `var_field!((*v).field, Pkg::Type::VARIANT)` when `v` is `Arc<Enum>` /
///     other `Deref`-able smart pointer; the explicit `*` selects the deref arm.
///
/// The variant path must be supplied so the destructure picks the right arm;
/// it cannot be inferred from the input position.
#[macro_export]
macro_rules! var_field {
    // Plain (owned) base: match against `&$base`. Rust match ergonomics binds
    // `$field` as `&FieldType` against the enum scrutinee.
    ( $base:ident . $field:ident , $($variant:ident)::+ ) => {
        match &$base {
            $($variant)::+ { $field, .. } => $field,
            _ => panic!(
                "var_field!: expected variant {} but value held a different variant",
                stringify!($($variant)::+),
            ),
        }
    };
    // Smart-pointer base (Arc / Rc / Box / &T / &mut T): `*$base` derefs through
    // the wrapper to the underlying enum; `&*$base` then yields `&Enum`.
    ( ( * $base:ident ) . $field:ident , $($variant:ident)::+ ) => {
        match &*$base {
            $($variant)::+ { $field, .. } => $field,
            _ => panic!(
                "var_field!: expected variant {} but value held a different variant",
                stringify!($($variant)::+),
            ),
        }
    };
    // Reference to a smart pointer (e.g. `&Arc<Enum>`): produced by `ref`
    // pattern bindings on Arc-typed fields under `deref_patterns`. The first
    // `*` strips the outer reference, the second `*` derefs the Arc.
    ( ( * * $base:ident ) . $field:ident , $($variant:ident)::+ ) => {
        match &**$base {
            $($variant)::+ { $field, .. } => $field,
            _ => panic!(
                "var_field!: expected variant {} but value held a different variant",
                stringify!($($variant)::+),
            ),
        }
    };
}
