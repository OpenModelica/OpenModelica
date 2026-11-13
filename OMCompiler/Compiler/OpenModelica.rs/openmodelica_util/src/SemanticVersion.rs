// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/SemanticVersion.mo`, whose functions
// are `external "C"` shims into `runtime/SemanticVersion_omc.c`. Both omcs
// implement them with `openmodelica_version`.

#![allow(non_snake_case)]

use arcstr::ArcStr;
use openmodelica_version::{Kind, Version, canonical, compare_parts};

pub fn compare(v1: ArcStr, v2: ArcStr, comparePrerelease: bool, compareBuildInformation: bool) -> i32 {
    compare_parts(
        &Version::parse(&v1),
        &Version::parse(&v2),
        comparePrerelease,
        compareBuildInformation,
    ) as i32
}

pub fn normalize(v: ArcStr) -> ArcStr {
    ArcStr::from(canonical(&v))
}

pub fn isSemVer(v: ArcStr) -> bool {
    matches!(Version::parse(&v).kind, Kind::Numbered { .. })
}
