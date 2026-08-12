//! The `OMGraphics_*` `external "C"` bodies of `CevalScriptBackend` (the FMI 3.0
//! graphical representation). `runtime/OMGraphics.cpp` walks a *boxed C*
//! MetaModelica value, so the port cannot link it; until it is reimplemented in
//! MetaModelica a Rust omc answers "this model has no icon", which
//! `generateFMI3GraphicalRepresentation` handles best-effort. Without these
//! bodies the generated code is `todo!()` and any FMI 3.0 export panics.

use arcstr::ArcStr;

pub fn iconSVGFromHandle(_handle: i32, _modelName: ArcStr) -> ArcStr {
    ArcStr::new()
}

pub fn graphicalRepresentationXMLFromHandle(_handle: i32, _scaleToMm: metamodelica::Real) -> ArcStr {
    ArcStr::new()
}

pub fn placedConnectorCount(_handle: i32) -> i32 {
    0
}

pub fn placedConnectorInfo(_handle: i32, _index: i32) -> ArcStr {
    ArcStr::new()
}

pub fn placedConnectorIconSVG(_handle: i32, _index: i32) -> ArcStr {
    ArcStr::new()
}

/// 0, not 1: the caller must not reference an icon file that is not there, since a
/// dangling `iconBaseName` would make the FMU invalid.
pub fn writeIconPNGFromHandle(_handle: i32, _modelName: ArcStr, _path: ArcStr) -> i32 {
    0
}

pub fn writePlacedConnectorIconPNG(_handle: i32, _index: i32, _path: ArcStr) -> i32 {
    0
}
