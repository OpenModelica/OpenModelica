// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/Curl.mo`, whose single function is an
// `external "C"` shim into `OMCompiler/Compiler/runtime/om_curl.c`. Both omcs
// download with `openmodelica_download`; its errors go to the error buffer.

#![allow(non_snake_case)]

use arcstr::ArcStr;
use metamodelica::{List, Result};
use openmodelica_error::ErrorTypes;
use openmodelica_util::Error;

pub fn multiDownload(urlFileList: List<(List<ArcStr>, ArcStr)>, maxParallel: i32) -> Result<bool> {
    let items = (&*urlFileList)
        .into_iter()
        .map(|(urls, file)| openmodelica_download::Item {
            urls: (&**urls).into_iter().map(|u| u.to_string()).collect(),
            file: file.to_string(),
        })
        .collect();
    let (ok, messages) = openmodelica_download::download(items, maxParallel.max(1) as usize);
    for m in messages {
        Error::addMessage(
            ErrorTypes::Message {
                id: -1,
                ty: ErrorTypes::MessageType::SIMULATION,
                severity: ErrorTypes::Severity::ERROR,
                message: ArcStr::from(m.template),
            },
            m.tokens
                .into_iter()
                .rev()
                .fold(metamodelica::nil(), |l, t| metamodelica::cons(ArcStr::from(t), l)),
        )?;
    }
    Ok(ok)
}

/// The files `multiDownload` asked for but did not find in the virtual file
/// system; the wasm host fetches them and runs the command again.
#[cfg(target_arch = "wasm32")]
pub fn take_pending_downloads() -> Vec<(Vec<String>, String)> {
    openmodelica_download::take_pending()
}
