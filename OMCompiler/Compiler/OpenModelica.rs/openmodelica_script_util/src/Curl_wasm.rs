//! Browser/Node-wasm implementation of [`crate::Curl`]. The native module
//! downloads over libcurl (which has no wasm target); on wasm the *host*
//! environment performs the transfer instead, because `omc_eval` runs
//! synchronously and cannot await a `fetch()` from inside the compiler call.
//!
//! So this module does no network I/O of its own. `multiDownload` checks the
//! in-memory VFS (`openmodelica_vfs`) for each requested file: a file already
//! present counts as downloaded; a missing one is recorded as *pending* and the
//! call reports failure (which makes the caller, e.g. `installPackage`, abort
//! cleanly). The wasm host — the OMShell Web Worker in the browser, or
//! `omc-cli.js` under Node — then drains the pending list with
//! [`take_pending_downloads`], fetches each file (the browser host streams it so
//! it can report download progress), stages the bytes with `omc_vfs_put`, and
//! re-runs the command. On the re-run the files are in the VFS, so `multiDownload`
//! succeeds and the command proceeds. A package install needs only a couple of
//! files (the index, then the library zip), so the command re-runs a handful of
//! times; the work before each download is cheap next to the transfer itself.

#![allow(non_snake_case)]

use std::cell::RefCell;
use std::sync::Arc;

use anyhow::Result;
use arcstr::ArcStr;

use metamodelica::List;

thread_local! {
    /// `(mirror URLs, target filename)` items the last `multiDownload` requested
    /// but could not satisfy from the VFS. Drained by [`take_pending_downloads`].
    static PENDING: RefCell<Vec<(Vec<String>, String)>> = const { RefCell::new(Vec::new()) };
}

/// Take and clear the files `multiDownload` asked for but did not find in the VFS.
/// The wasm host fetches each (trying the mirrors in order), writes the bytes to
/// the VFS, and re-runs the command. See the module docs.
pub fn take_pending_downloads() -> Vec<(Vec<String>, String)> {
    PENDING.with(|p| std::mem::take(&mut *p.borrow_mut()))
}

/// For each `(mirror URLs, target filename)`, succeed if the file is already in
/// the VFS; otherwise record it as pending and fail. `maxParallel` is unused — the
/// host fetches the pending list. Returns whether every file was already present.
pub fn multiDownload(
    urlFileList: Arc<List<(Arc<List<ArcStr>>, ArcStr)>>,
    _maxParallel: i32,
) -> Result<bool> {
    let mut all_present = true;

    let mut cur = urlFileList;
    while let List::Cons { head: (urls, filename), tail } = &*cur {
        if openmodelica_vfs::read(filename.as_str()).is_none() {
            // Flatten this item's mirror URLs and record it for the host to fetch.
            let mut mirrors: Vec<String> = Vec::new();
            let mut u = urls.clone();
            while let List::Cons { head, tail } = &*u {
                mirrors.push(head.to_string());
                let tail = tail.clone();
                u = tail;
            }
            PENDING.with(|p| p.borrow_mut().push((mirrors, filename.to_string())));
            all_present = false;
        }

        let tail = tail.clone();
        cur = tail;
    }

    Ok(all_present)
}
