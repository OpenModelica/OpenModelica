//! Browser-wasm implementation of [`crate::Curl`]. The native module downloads
//! over native libcurl (the `curl` crate, which has no wasm target); here we use
//! the browser instead and stage the bytes in the in-memory VFS that the rest of
//! the compiler reads through (`openmodelica_vfs`). This is what lets
//! `installPackage(Modelica)` work in the web build: the package index and the
//! library zips are fetched straight from the network.
//!
//! `omc_eval` runs synchronously on the page's main thread, so we cannot await a
//! `fetch()` Promise — we use a *synchronous* `XMLHttpRequest`, which blocks
//! until the transfer finishes. Synchronous XHR on the main thread forbids
//! `responseType = "arraybuffer"`, so we recover the raw bytes with the classic
//! `charset=x-user-defined` trick: every response character's low byte is the
//! original byte. The remote (package index, library mirrors) must allow CORS
//! for this to succeed.
//!
//! Diagnostics mirror the native module's message templates and token order so
//! callers and the testsuite see the same errors.

#![allow(non_snake_case)]

use std::sync::Arc;

use anyhow::Result;
use arcstr::ArcStr;
use wasm_bindgen::JsValue;
use web_sys::XmlHttpRequest;

use metamodelica::List;
use openmodelica_error::ErrorTypes;
use openmodelica_util::Error;

/// Render a `JsValue` error/exception as readable text for a diagnostic.
fn js_err(e: JsValue) -> String {
    e.as_string()
        .or_else(|| js_sys::Reflect::get(&e, &JsValue::from_str("message")).ok().and_then(|m| m.as_string()))
        .unwrap_or_else(|| format!("{e:?}"))
}

/// `c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, ...)`
/// equivalent: an ad-hoc runtime error with no source location. Tokens are given
/// in substitution order (the C runtime reverses them internally).
fn add_error(template: &str, tokens: Vec<ArcStr>) -> Result<()> {
    let mut toks: Arc<List<ArcStr>> = Arc::new(List::Nil);
    for t in tokens.into_iter().rev() {
        toks = metamodelica::cons(t, toks);
    }
    Error::addMessage(
        ErrorTypes::Message {
            id: -1,
            ty: ErrorTypes::MessageType::SIMULATION,
            severity: ErrorTypes::Severity::ERROR,
            message: ArcStr::from(template),
        },
        toks,
    )
}

/// Synchronously download `url` and return its bytes, or the failure text.
fn download_one(url: &str) -> std::result::Result<Vec<u8>, String> {
    let xhr = XmlHttpRequest::new().map_err(js_err)?;
    // `false` => synchronous: send() blocks until the response is in.
    xhr.open_with_async("GET", url, false).map_err(js_err)?;
    // Keep every response byte intact (no UTF-8 / newline mangling): the low 8
    // bits of each resulting character are the original byte.
    xhr.override_mime_type("text/plain; charset=x-user-defined")
        .map_err(js_err)?;
    // A network/CORS failure makes send() throw rather than return a status.
    xhr.send().map_err(js_err)?;

    let status = xhr.status().map_err(js_err)?;
    if !(200..300).contains(&status) {
        return Err(format!("HTTP {status}"));
    }
    let text = xhr.response_text().map_err(js_err)?.unwrap_or_default();
    Ok(text.chars().map(|c| (c as u32 & 0xff) as u8).collect())
}

/// Download each `(mirror URLs, target filename)` item, writing the bytes into
/// the VFS at `filename`. Mirrors are tried in order; an item with no working
/// mirror fails the whole call (`Ok(false)`). `maxParallel` is ignored — the
/// browser main thread is single-threaded, so transfers run sequentially.
pub fn multiDownload(
    urlFileList: Arc<List<(Arc<List<ArcStr>>, ArcStr)>>,
    _maxParallel: i32,
) -> Result<bool> {
    let mut ok = true;
    let mut messages: Vec<(&'static str, Vec<ArcStr>)> = Vec::new();

    let mut cur = urlFileList;
    while let List::Cons { head: (urls, filename), tail } = &*cur {
        // Collect this item's mirror URLs into a flat list.
        let mut mirrors: Vec<ArcStr> = Vec::new();
        let mut u = urls.clone();
        while let List::Cons { head, tail } = &*u {
            mirrors.push(head.clone());
            let tail = tail.clone();
            u = tail;
        }

        for (i, url) in mirrors.iter().enumerate() {
            let last = i + 1 == mirrors.len();
            match download_one(url) {
                Ok(bytes) => {
                    openmodelica_vfs::write(filename.as_str(), bytes);
                    break;
                }
                Err(err_text) => {
                    let err_text = ArcStr::from(err_text);
                    if last {
                        messages.push(("Curl error for URL %s: %s", vec![url.clone(), err_text]));
                        ok = false;
                    } else {
                        messages.push((
                            "Will try another mirror due to curl error for URL %s: %s",
                            vec![url.clone(), err_text],
                        ));
                    }
                }
            }
        }

        let tail = tail.clone();
        cur = tail;
    }

    for (template, tokens) in messages {
        add_error(template, tokens)?;
    }
    Ok(ok)
}
