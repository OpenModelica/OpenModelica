//! `SourceInfo` and the `sourceInfo!` builtin macro.

use arcstr::ArcStr;
use crate::Real;

/// MetaModelica's `sourceInfo()` built-in: returns a `SourceInfo` populated from
/// the *compiler* call-site, not from any runtime value. We mirror that here by
/// using `file!()` / `line!()` / `column!()`, which the Rust compiler expands at
/// macro-invocation site — exactly the semantics MetaModelica gives `sourceInfo()`.
///
/// Codegen emits `sourceInfo!()` for the no-arg MetaModelica builtin call.
#[macro_export]
macro_rules! sourceInfo {
    () => {
        $crate::SourceInfo {
            fileName: ::arcstr::ArcStr::from(file!()),
            isReadOnly: false,
            lineNumberStart: line!() as i32,
            columnNumberStart: column!() as i32,
            lineNumberEnd: line!() as i32,
            columnNumberEnd: column!() as i32,
            lastModification: $crate::OrderedFloat(0.0_f64),
        }
    };
    // With an explicit file: the original MetaModelica source path (the code
    // generator knows the `.mo` a function came from, but not the statement's
    // line — positions are zero, "unknown line in this file", which is also
    // exactly what the reference compiler prints under Testsuite.isRunning).
    ($file:literal) => {
        $crate::SourceInfo {
            fileName: ::arcstr::literal!($file),
            isReadOnly: false,
            lineNumberStart: 0,
            columnNumberStart: 0,
            lineNumberEnd: 0,
            columnNumberEnd: 0,
            lastModification: $crate::OrderedFloat(0.0_f64),
        }
    };
}

/// The Info attribute provides location information for elements and classes.
/// Mapped from the SOURCEINFO record in MetaModelicaBuiltin.mo.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash, Default)]
pub struct SourceInfo {
    /// File name where the class is defined in.
    pub fileName: ArcStr,
    /// Should be true for libraries.
    pub isReadOnly: bool,
    /// Start line number (1-based).
    pub lineNumberStart: i32,
    /// Start column number (1-based).
    pub columnNumberStart: i32,
    /// End line number (1-based).
    pub lineNumberEnd: i32,
    /// End column number (1-based).
    pub columnNumberEnd: i32,
    /// mtime in stat(2), stored as a double for increased precision on 32-bit platforms.
    pub lastModification: Real,
}
