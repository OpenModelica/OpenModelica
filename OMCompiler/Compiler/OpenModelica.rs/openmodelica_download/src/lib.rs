//! Downloads files, each from a list of mirror URLs, for both omcs.
//!
//! Natively over libcurl: each file is fetched into `<file>.tmp<N>` and renamed
//! over the target on success; on failure the next mirror is tried. At most
//! `max_parallel` transfers run at the same time.
//!
//! On wasm the host performs the transfers, because `omc_eval` runs
//! synchronously and cannot await a `fetch()`. A file already in the virtual
//! file system counts as downloaded; a missing one is recorded as pending and
//! the download fails. The host takes the pending list ([`take_pending`]),
//! writes the files to the virtual file system and runs the command again.

/// A file to download and the URLs to try, in order.
pub struct Item {
    pub urls: Vec<String>,
    pub file: String,
}

/// An error, as a template with `%s` for each of its tokens.
#[derive(Debug, PartialEq, Eq)]
pub struct Message {
    pub template: &'static str,
    pub tokens: Vec<String>,
}

impl Message {
    #[cfg_attr(target_arch = "wasm32", allow(dead_code))]
    fn new(template: &'static str, tokens: Vec<String>) -> Message {
        Message { template, tokens }
    }

    pub fn text(&self) -> String {
        let mut parts = self.template.split("%s");
        let mut out = parts.next().unwrap_or_default().to_owned();
        for (part, token) in parts.zip(self.tokens.iter().map(String::as_str).chain(std::iter::repeat(""))) {
            out.push_str(token);
            out.push_str(part);
        }
        out
    }
}

/// Downloads all items; false if one of them could not be downloaded.
pub fn download(items: Vec<Item>, max_parallel: usize) -> (bool, Vec<Message>) {
    imp::download(items, max_parallel)
}

#[cfg(target_arch = "wasm32")]
pub use imp::take_pending;

#[cfg(all(feature = "curl", not(target_arch = "wasm32")))]
mod imp {
    use std::collections::VecDeque;
    use std::sync::Mutex;
    use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
    use std::time::Duration;

    use curl::easy::Easy;

    use crate::{Item, Message};

    struct Shared {
        queue: Mutex<VecDeque<Item>>,
        messages: Mutex<Vec<Message>>,
        ok: AtomicBool,
        /// For unique `.tmp<N>` suffixes.
        transfer_number: AtomicUsize,
    }

    impl Shared {
        fn error(&self, template: &'static str, tokens: Vec<String>) {
            self.messages.lock().unwrap().push(Message::new(template, tokens));
        }
    }

    /// None if the file cannot be created, else the curl error, if any.
    fn download_one(easy: &mut Easy, url: &str, tmp: &str) -> Option<Result<(), String>> {
        use std::io::Write;
        let mut out = std::fs::File::create(tmp).ok()?;
        let mut setup = || -> Result<(), curl::Error> {
            easy.url(url)?;
            easy.follow_location(true)?;
            easy.connect_timeout(Duration::from_secs(8))?;
            easy.fail_on_error(true)?;
            easy.useragent("OpenModelica/1.0")?;
            Ok(())
        };
        if let Err(e) = setup() {
            return Some(Err(e.description().to_owned()));
        }
        let mut write_failed = false;
        let result = {
            let mut transfer = easy.transfer();
            transfer
                .write_function(|data| match out.write_all(data) {
                    Ok(()) => Ok(data.len()),
                    Err(_) => {
                        write_failed = true;
                        Ok(0)
                    }
                })
                .expect("a write function can be set");
            transfer.perform()
        };
        Some(match result {
            Ok(()) => Ok(()),
            Err(e) if write_failed => Err(format!("{} (local write failed)", e.description())),
            Err(e) => Err(e.description().to_owned()),
        })
    }

    fn worker(shared: &Shared) {
        let mut easy = Easy::new();
        loop {
            let Some(mut item) = shared.queue.lock().unwrap().pop_front() else {
                return;
            };
            let mut urls: VecDeque<String> = std::mem::take(&mut item.urls).into();
            while let Some(url) = urls.pop_front() {
                let n = shared.transfer_number.fetch_add(1, Ordering::Relaxed);
                let tmp = format!("{}.tmp{n}", item.file);
                match download_one(&mut easy, &url, &tmp) {
                    Some(Ok(())) => {
                        if let Err(e) = std::fs::rename(&tmp, &item.file) {
                            shared.error(
                                "Failed to rename file after downloading with curl %s %s: %s",
                                vec![tmp, item.file.clone(), e.to_string()],
                            );
                        }
                        break;
                    }
                    None => {
                        shared.error("Failed to open file for writing: %s", vec![tmp]);
                        shared.ok.store(false, Ordering::Relaxed);
                        break;
                    }
                    Some(Err(error)) => {
                        let _ = std::fs::remove_file(&tmp);
                        if urls.is_empty() {
                            shared.error("Curl error for URL %s: %s", vec![url, error]);
                            shared.ok.store(false, Ordering::Relaxed);
                        } else {
                            shared.error(
                                "Will try another mirror due to curl error for URL %s: %s",
                                vec![url, error],
                            );
                        }
                    }
                }
            }
        }
    }

    pub fn download(items: Vec<Item>, max_parallel: usize) -> (bool, Vec<Message>) {
        let workers = items.len().min(max_parallel).max(1);
        let shared = Shared {
            queue: Mutex::new(items.into()),
            messages: Mutex::new(Vec::new()),
            ok: AtomicBool::new(true),
            transfer_number: AtomicUsize::new(1),
        };
        std::thread::scope(|scope| {
            for _ in 0..workers {
                scope.spawn(|| worker(&shared));
            }
        });
        (shared.ok.into_inner(), shared.messages.into_inner().unwrap())
    }
}

#[cfg(all(not(feature = "curl"), not(target_arch = "wasm32")))]
mod imp {
    use crate::{Item, Message};

    pub fn download(items: Vec<Item>, _max_parallel: usize) -> (bool, Vec<Message>) {
        let messages: Vec<Message> = items
            .into_iter()
            .filter(|item| !std::path::Path::new(&item.file).exists())
            .map(|item| {
                Message::new(
                    "Cannot download %s: this build has no download support.",
                    vec![item.file],
                )
            })
            .collect();
        (messages.is_empty(), messages)
    }
}

#[cfg(target_arch = "wasm32")]
mod imp {
    use std::cell::RefCell;

    use crate::{Item, Message};

    thread_local! {
        static PENDING: RefCell<Vec<(Vec<String>, String)>> = const { RefCell::new(Vec::new()) };
    }

    /// Takes and clears the `(mirror URLs, file)` that [`crate::download`]
    /// did not find in the virtual file system.
    pub fn take_pending() -> Vec<(Vec<String>, String)> {
        PENDING.with(|p| std::mem::take(&mut *p.borrow_mut()))
    }

    pub fn download(items: Vec<Item>, _max_parallel: usize) -> (bool, Vec<Message>) {
        let mut all_present = true;
        for item in items {
            if openmodelica_wasi::exists(&item.file) {
                continue;
            }
            all_present = false;
            PENDING.with(|p| {
                let mut p = p.borrow_mut();
                if !p.iter().any(|(_, file)| *file == item.file) {
                    p.push((item.urls, item.file));
                }
            });
        }
        (all_present, Vec::new())
    }
}

#[cfg(all(test, feature = "curl", not(target_arch = "wasm32")))]
mod tests {
    use super::*;

    fn item(urls: &[&str], file: &std::path::Path) -> Item {
        Item {
            urls: urls.iter().map(|u| u.to_string()).collect(),
            file: file.display().to_string(),
        }
    }

    /// Without a TLS backend, the https download of the package index fails
    /// with "Unsupported protocol". No network needed.
    #[test]
    fn curl_has_tls_backend() {
        let v = curl::Version::get();
        assert!(v.ssl_version().is_some(), "libcurl built without a TLS backend");
        assert!(v.protocols().any(|p| p == "https"), "libcurl does not support https");
    }

    #[test]
    fn downloads_and_retries_mirrors() {
        let dir = std::env::temp_dir().join(format!("om_download_test_{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let src = dir.join("src.txt");
        std::fs::write(&src, "payload").unwrap();
        let src_url = format!("file://{}", src.display());
        let missing_url = format!("file://{}/does-not-exist", dir.display());
        let (ok, retry, fail) = (dir.join("ok.txt"), dir.join("retry.txt"), dir.join("fail.txt"));

        let (success, messages) = download(
            vec![
                item(&[&src_url], &ok),
                item(&[&missing_url, &src_url], &retry),
                item(&[&missing_url], &fail),
            ],
            2,
        );
        assert!(!success);
        assert_eq!(std::fs::read_to_string(&ok).unwrap(), "payload");
        assert_eq!(std::fs::read_to_string(&retry).unwrap(), "payload");
        assert!(!fail.exists());
        assert_eq!(messages.len(), 2);
        assert!(
            messages
                .iter()
                .any(|m| m.template.starts_with("Will try another mirror"))
        );
        assert!(
            messages
                .iter()
                .any(|m| m.text().starts_with(&format!("Curl error for URL {missing_url}: ")))
        );
        for e in std::fs::read_dir(&dir).unwrap() {
            let name = e.unwrap().file_name().into_string().unwrap();
            assert!(!name.contains(".tmp"), "leftover temp file {name}");
        }
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn message_text() {
        let m = Message::new("Failed to rename %s %s: %s", vec!["a".into(), "b".into(), "c".into()]);
        assert_eq!(m.text(), "Failed to rename a b: c");
    }
}
