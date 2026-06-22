// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/Curl.mo`, whose single function
// is an `external "C"` shim into `OMCompiler/Compiler/runtime/om_curl.c`.
// Like the C runtime we use libcurl (via the `curl` crate, which links the
// system library); parallelism comes from a small worker pool instead of
// the curl multi interface — same observable behaviour, much simpler
// retry/cleanup logic.
//
// Semantics mirrored from `om_curl_multi_download`:
//
//   * Each work item is `(mirror URLs, target filename)`. The first URL is
//     fetched into `<filename>.tmp<N>` (N = global transfer counter) and
//     renamed over the target on success.
//   * On failure the temp file is removed; if more mirror URLs remain the
//     item is retried with the tail of the URL list, otherwise the
//     download counts as failed and the result is `false`.
//   * At most `maxParallel` transfers run concurrently.
//   * Diagnostics use the same message templates and token order as the C
//     implementation (`c_add_message` reverses its token array, so the
//     first `%s` gets the *last* C token; the vectors below are already in
//     substitution order).
//
// The error buffer (`ErrorExt`) is thread-local, so workers only *collect*
// diagnostics; they are pushed into the buffer from the calling thread
// after all transfers finish.

#![allow(non_snake_case)]

use std::collections::VecDeque;
use std::sync::Mutex;
use std::sync::atomic::{AtomicBool, AtomicI32, Ordering};
use std::sync::Arc;
use std::time::Duration;

use anyhow::Result;
use arcstr::ArcStr;
use curl::easy::Easy;
use metamodelica::List;
use openmodelica_util::Error;
use openmodelica_error::ErrorTypes;

/// One pending download: the remaining mirror URLs and the target file.
struct WorkItem {
    urls: VecDeque<ArcStr>,
    filename: ArcStr,
}

/// A diagnostic recorded by a worker, emitted later on the calling thread.
type PendingMessage = (&'static str, Vec<ArcStr>);

struct Shared {
    queue: Mutex<VecDeque<WorkItem>>,
    messages: Mutex<Vec<PendingMessage>>,
    /// Overall success flag, cleared when any item runs out of mirrors.
    ok: AtomicBool,
    /// Global transfer counter used for unique `.tmp<N>` suffixes.
    transfer_number: AtomicI32,
}

impl Shared {
    fn add_message(&self, template: &'static str, tokens: Vec<ArcStr>) {
        self.messages.lock().unwrap().push((template, tokens));
    }
}

/// `c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, ...)`
/// equivalent: an ad-hoc runtime error with no source location.
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

/// Download `url` into `tmp_filename` with the same transfer options as
/// `addTransfer` in `om_curl.c`. Returns the curl error text on failure.
fn download_one(easy: &mut Easy, url: &str, tmp_filename: &str) -> std::result::Result<(), String> {
    let mut out_file = match std::fs::File::create(tmp_filename) {
        Ok(f) => f,
        // Reported by the caller as "Failed to open file for writing".
        Err(_) => return Err(String::new()),
    };
    easy.url(url).map_err(|e| e.description().to_string())?;
    easy.follow_location(true).unwrap();          // CURLOPT_FOLLOWLOCATION
    easy.connect_timeout(Duration::from_secs(8)).unwrap(); // CURLOPT_CONNECTTIMEOUT
    easy.fail_on_error(true).unwrap();            // CURLOPT_FAILONERROR
    easy.useragent("OpenModelica/1.0").unwrap();  // CURLOPT_USERAGENT

    let mut write_error = false;
    let result = {
        let mut transfer = easy.transfer();
        transfer
            .write_function(|data| {
                use std::io::Write;
                match out_file.write_all(data) {
                    Ok(()) => Ok(data.len()),
                    // A short write aborts the transfer with CURLE_WRITE_ERROR.
                    Err(_) => {
                        write_error = true;
                        Ok(0)
                    }
                }
            })
            .unwrap();
        transfer.perform()
    };
    match result {
        Ok(()) => Ok(()),
        Err(e) if write_error => Err(format!("{} (local write failed)", e.description())),
        Err(e) => Err(e.description().to_string()),
    }
}

/// Worker loop: take items off the shared queue and try their mirrors in
/// order, mirroring the retry behaviour of `om_curl_multi_download`.
fn worker(shared: &Shared) {
    let mut easy = Easy::new();
    loop {
        let Some(mut item) = shared.queue.lock().unwrap().pop_front() else {
            return;
        };
        while let Some(url) = item.urls.pop_front() {
            let n = shared.transfer_number.fetch_add(1, Ordering::Relaxed);
            let tmp_filename = format!("{}.tmp{n}", item.filename);
            match download_one(&mut easy, &url, &tmp_filename) {
                Ok(()) => {
                    if let Err(e) = std::fs::rename(&tmp_filename, item.filename.as_str()) {
                        shared.add_message(
                            "Failed to rename file after downloading with curl %s %s: %s",
                            vec![
                                ArcStr::from(tmp_filename),
                                item.filename.clone(),
                                ArcStr::from(e.to_string()),
                            ],
                        );
                    }
                    break;
                }
                Err(err_text) if err_text.is_empty() => {
                    // Could not even create the temp file (e.g. missing
                    // directory); retrying other mirrors cannot help.
                    shared.add_message(
                        "Failed to open file for writing: %s",
                        vec![ArcStr::from(tmp_filename)],
                    );
                    shared.ok.store(false, Ordering::Relaxed);
                    break;
                }
                Err(err_text) => {
                    let _ = std::fs::remove_file(&tmp_filename);
                    let err_text = ArcStr::from(err_text);
                    if item.urls.is_empty() {
                        shared.add_message(
                            "Curl error for URL %s: %s",
                            vec![url.clone(), err_text],
                        );
                        shared.ok.store(false, Ordering::Relaxed);
                    } else {
                        shared.add_message(
                            "Will try another mirror due to curl error for URL %s: %s",
                            vec![url.clone(), err_text],
                        );
                    }
                }
            }
        }
    }
}

pub fn multiDownload(
    urlFileList: Arc<List<(Arc<List<ArcStr>>, ArcStr)>>,
    maxParallel: i32,
) -> Result<bool> {
    let mut queue: VecDeque<WorkItem> = VecDeque::new();
    let mut cur = urlFileList;
    while let List::Cons { head: (urls, filename), tail } = &*cur {
        let mut mirror_urls = VecDeque::new();
        let mut u = urls.clone();
        while let List::Cons { head, tail } = &*u {
            mirror_urls.push_back(head.clone());
            let tail = tail.clone();
            u = tail;
        }
        queue.push_back(WorkItem { urls: mirror_urls, filename: filename.clone() });
        let tail = tail.clone();
        cur = tail;
    }

    let num_workers = queue.len().min(maxParallel.max(1) as usize).max(1);
    let shared = Shared {
        queue: Mutex::new(queue),
        messages: Mutex::new(Vec::new()),
        ok: AtomicBool::new(true),
        transfer_number: AtomicI32::new(1),
    };

    std::thread::scope(|scope| {
        for _ in 0..num_workers {
            scope.spawn(|| worker(&shared));
        }
    });

    // The error buffer is thread-local: emit the collected diagnostics from
    // the calling thread, where omc will read them back.
    for (template, tokens) in shared.messages.into_inner().unwrap() {
        add_error(template, tokens)?;
    }
    Ok(shared.ok.into_inner())
}

#[cfg(test)]
mod tests {
    use super::*;
    use metamodelica::{cons, nil};

    fn item(urls: &[&str], file: &str) -> (Arc<List<ArcStr>>, ArcStr) {
        let mut l = nil::<ArcStr>();
        for u in urls.iter().rev() {
            l = cons(ArcStr::from(*u), l);
        }
        (l, ArcStr::from(file))
    }

    /// Download via file:// URLs so the test runs without network access.
    #[test]
    fn downloads_and_retries_mirrors() {
        let dir = std::env::temp_dir().join(format!("curl_rs_test_{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let src = dir.join("src.txt");
        std::fs::write(&src, "payload").unwrap();
        let src_url = format!("file://{}", src.display());
        let missing_url = format!("file://{}/does-not-exist", dir.display());

        let ok_target = dir.join("ok.txt");
        let retry_target = dir.join("retry.txt");
        let fail_target = dir.join("fail.txt");

        let list = cons(
            item(&[&src_url], &ok_target.display().to_string()),
            cons(
                // First mirror fails, second succeeds.
                item(&[&missing_url, &src_url], &retry_target.display().to_string()),
                cons(
                    // All mirrors fail.
                    item(&[&missing_url], &fail_target.display().to_string()),
                    nil(),
                ),
            ),
        );

        let success = multiDownload(list, 2).unwrap();
        assert!(!success, "one item has no working mirror");
        assert_eq!(std::fs::read_to_string(&ok_target).unwrap(), "payload");
        assert_eq!(std::fs::read_to_string(&retry_target).unwrap(), "payload");
        assert!(!fail_target.exists());
        // Temp files must not be left behind.
        for e in std::fs::read_dir(&dir).unwrap() {
            let name = e.unwrap().file_name().into_string().unwrap();
            assert!(!name.contains(".tmp"), "leftover temp file {name}");
        }
        let _ = std::fs::remove_dir_all(&dir);
    }
}
