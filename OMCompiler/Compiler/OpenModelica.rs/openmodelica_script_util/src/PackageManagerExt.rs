// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/PackageManagerExt.mo`, whose function
// is an `external "C"` shim into `runtime/PackageManagerExt_omc.c`. Both omcs
// implement it with `openmodelica_package_manager`.

#![allow(non_snake_case)]

use arcstr::ArcStr;

pub fn call(request: ArcStr) -> ArcStr {
    ArcStr::from(openmodelica_package_manager::call(&request))
}

/// The files the package manager asked for but did not find in the virtual
/// file system; the wasm host fetches them and runs the command again.
#[cfg(target_arch = "wasm32")]
pub fn take_pending_downloads() -> Vec<(Vec<String>, String)> {
    openmodelica_package_manager::take_pending_downloads()
}
