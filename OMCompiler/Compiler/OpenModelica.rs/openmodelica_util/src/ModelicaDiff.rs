// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/ModelicaDiff.mo`, whose functions are
// `external "C"` shims into `runtime/ModelicaDiff_omc.c`. Both omcs implement
// them with `openmodelica_modelica_diff`.

#![allow(non_snake_case)]

use arcstr::ArcStr;
pub use openmodelica_modelica_diff::Format;
use openmodelica_modelica_diff::code_equal;

pub fn merge(before: ArcStr, beforeCanonical: ArcStr, after: ArcStr) -> ArcStr {
    ArcStr::from(openmodelica_modelica_diff::merge(&before, &beforeCanonical, &after))
}

pub fn render(before: ArcStr, merged: ArcStr, format: Format) -> ArcStr {
    ArcStr::from(openmodelica_modelica_diff::render(&before, &merged, format))
}

pub fn codeEqual(a: ArcStr, b: ArcStr) -> bool {
    code_equal(&a, &b)
}
