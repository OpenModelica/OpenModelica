// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/Unzip.mo`, whose functions are
// `external "C"` shims into `OMCompiler/Compiler/runtime/om_zip.c`. Both omcs
// implement them with `openmodelica_zip`; errors go to the error buffer.

#![allow(non_snake_case)]

use arcstr::ArcStr;
use openmodelica_error::ErrorTypes;
use openmodelica_util::Error;

/// `c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, "%s", ...)`
/// as om_zip.c reports a failure.
fn report(r: openmodelica_zip::Result<()>) -> bool {
    let Err(msg) = r else { return true };
    let _ = Error::addMessage(
        ErrorTypes::Message {
            id: -1,
            ty: ErrorTypes::MessageType::SIMULATION,
            severity: ErrorTypes::Severity::ERROR,
            message: arcstr::literal!("%s"),
        },
        metamodelica::cons(ArcStr::from(msg), metamodelica::nil()),
    );
    false
}

pub fn unzipPath(fileName: ArcStr, pathToExtract: ArcStr, destinationPath: ArcStr) -> bool {
    report(openmodelica_zip::unzip_path(
        &fileName,
        &pathToExtract,
        &destinationPath,
    ))
}

pub fn unzipAll(fileName: ArcStr, destinationPath: ArcStr) -> bool {
    report(openmodelica_zip::unzip_all(&fileName, &destinationPath))
}

pub fn zipPath(zipFileName: ArcStr, path: ArcStr, entryName: ArcStr) -> bool {
    report(openmodelica_zip::zip_path(&zipFileName, &path, &entryName))
}

pub fn zipPaths(zipFileName: ArcStr, directory: ArcStr, names: metamodelica::List<ArcStr>) -> bool {
    let paths: Vec<(String, ArcStr)> = (&*names)
        .into_iter()
        .map(|n| (format!("{directory}/{n}"), n.clone()))
        .collect();
    let entries: Vec<(&str, &str)> = paths.iter().map(|(p, n)| (p.as_str(), n.as_str())).collect();
    report(openmodelica_zip::zip_paths(&zipFileName, &entries, &[]))
}
