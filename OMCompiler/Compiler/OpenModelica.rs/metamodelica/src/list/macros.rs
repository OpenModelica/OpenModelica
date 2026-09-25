//! `list!`, `assign_field!`, `assign_variant_field!`, `var_field!`.

#[macro_export]
macro_rules! list {
    // Base case: empty list
    () => {
        $crate::nil()
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

/// Functionally update fields of a record value stored behind a
/// `metamodelica::Ref<T>`.
///
/// MetaModelica record update (`var.field := value`) has value semantics. All
/// values are evaluated first (they may read `$base`), then `Arc::make_mut`
/// updates the record in place when `$base` is its only owner and copies it
/// otherwise.
///
/// For multi-record uniontypes (Rust enums), use `assign_variant_field!`.
#[macro_export]
macro_rules! assign_field {
    (@eval $base:ident [$(($field:ident $v:ident))*]) => {{
        let __owned = ::std::sync::Arc::make_mut(&mut $base);
        $( __owned.$field = $v; )*
    }};
    // Each recursion level's `__v` is a distinct hygienic binding.
    (@eval $base:ident [$($done:tt)*] $field:ident = $value:expr $(, $rest_field:ident = $rest_value:expr)*) => {{
        let __v = $value;
        $crate::assign_field!(@eval $base [$($done)* ($field __v)] $($rest_field = $rest_value),*)
    }};
    (
        $base:ident . $first_field:ident = $first_value:expr
        $(, $_base:ident . $field:ident = $value:expr)*
        $(,)?
    ) => {
        $crate::assign_field!(@eval $base [] $first_field = $first_value $(, $field = $value)*)
    };
}

/// Like `assign_field!`, but for a uniontype-enum value whose currently matched
/// variant is known statically (e.g. inside a `match` arm or after a refutable
/// `let`-pattern). A runtime variant mismatch panics — that would indicate a
/// codegen bug.
///
/// Example: `assign_variant_field!(node => NFInstNode::CLASS_NODE; ty = newTy);`
#[macro_export]
macro_rules! assign_variant_field {
    (@eval $base:ident => $variant:path ; [$(($field:ident $v:ident))*]) => {{
        let __owned = ::std::sync::Arc::make_mut(&mut $base);
        $(
            if let $variant { $field: __dst, .. } = &mut *__owned {
                *__dst = $v;
            } else {
                panic!(
                    "assign_variant_field!: expected variant {} but value held a different variant",
                    stringify!($variant),
                );
            }
        )*
    }};
    (@eval $base:ident => $variant:path ; [$($done:tt)*] $field:ident = $value:expr $(, $rest_field:ident = $rest_value:expr)*) => {{
        let __v = $value;
        $crate::assign_variant_field!(@eval $base => $variant ; [$($done)* ($field __v)] $($rest_field = $rest_value),*)
    }};
    (
        $base:ident => $variant:path ;
        $($field:ident = $value:expr),+
        $(,)?
    ) => {
        $crate::assign_variant_field!(@eval $base => $variant ; [] $($field = $value),+)
    };
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
///   - `var_field!((*v).field, Pkg::Type::VARIANT)` when `v` is `metamodelica::Ref<Enum>` /
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
    // Reference to a smart pointer (e.g. `&metamodelica::Ref<Enum>`): produced by `ref`
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
