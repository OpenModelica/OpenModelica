//! C ABI of omcruntime's Rust part; see include/omcruntime_rust.h.

use std::ffi::{CStr, CString, c_char, c_int};

/// # Safety
/// Every pointer is a NUL-terminated string.
unsafe fn arg<'a>(p: *const c_char) -> std::borrow::Cow<'a, str> {
    unsafe { CStr::from_ptr(p) }.to_string_lossy()
}

fn result(r: Result<(), String>) -> *mut c_char {
    match r {
        Ok(()) => std::ptr::null_mut(),
        Err(msg) => CString::new(msg.replace('\0', " ")).unwrap_or_default().into_raw(),
    }
}

/// # Safety
/// Every pointer is a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_unzip_path(zip: *const c_char, path: *const c_char, dest: *const c_char) -> *mut c_char {
    unsafe { result(openmodelica_zip::unzip_path(&arg(zip), &arg(path), &arg(dest))) }
}

/// # Safety
/// Every pointer is a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_unzip_all(zip: *const c_char, dest: *const c_char) -> *mut c_char {
    unsafe { result(openmodelica_zip::unzip_all(&arg(zip), &arg(dest))) }
}

/// # Safety
/// `paths` and `entry_names` hold `n` strings, `excludes` holds `n_excludes`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_zip_paths(
    zip: *const c_char,
    paths: *const *const c_char,
    entry_names: *const *const c_char,
    n: usize,
    excludes: *const *const c_char,
    n_excludes: usize,
) -> *mut c_char {
    let strings = |p: *const *const c_char, n: usize| -> Vec<String> {
        if n == 0 {
            return Vec::new();
        }
        unsafe { std::slice::from_raw_parts(p, n) }
            .iter()
            .map(|&s| unsafe { arg(s) }.into_owned())
            .collect()
    };
    let (paths, names, excludes) = (
        strings(paths, n),
        strings(entry_names, n),
        strings(excludes, n_excludes),
    );
    let entries: Vec<(&str, &str)> = paths
        .iter()
        .zip(&names)
        .map(|(p, e)| (p.as_str(), e.as_str()))
        .collect();
    let excludes: Vec<&str> = excludes.iter().map(String::as_str).collect();
    unsafe { result(openmodelica_zip::zip_paths(&arg(zip), &entries, &excludes)) }
}

/// # Safety
/// `p` points to `len` valid entries, or `len` is 0.
unsafe fn slice<'a, T>(p: *const T, len: usize) -> &'a [T] {
    if len == 0 {
        &[]
    } else {
        unsafe { std::slice::from_raw_parts(p, len) }
    }
}

/// Downloads `n` files: `files[i]` from the next `url_counts[i]` entries of
/// `urls`, tried in order. `report` gets each error message. 1 on success.
///
/// # Safety
/// `urls`, `url_counts` and `files` hold as many valid entries as described.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_download(
    urls: *const *const c_char,
    url_counts: *const usize,
    files: *const *const c_char,
    n: usize,
    max_parallel: usize,
    report: extern "C" fn(*const c_char),
) -> c_int {
    let counts: &[usize] = unsafe { slice(url_counts, n) };
    let mut urls = unsafe { slice(urls, counts.iter().sum()) }.iter();
    let items = unsafe { slice(files, n) }
        .iter()
        .zip(counts)
        .map(|(&file, &count)| openmodelica_download::Item {
            urls: urls
                .by_ref()
                .take(count)
                .map(|&u| unsafe { arg(u) }.into_owned())
                .collect(),
            file: unsafe { arg(file) }.into_owned(),
        })
        .collect();
    let (ok, messages) = openmodelica_download::download(items, max_parallel);
    for m in messages {
        let text = CString::new(m.text().replace('\0', " ")).unwrap_or_default();
        report(text.as_ptr());
    }
    ok as c_int
}

/// # Safety
/// `s` is NULL or a string returned by this library.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_free_string(s: *mut c_char) {
    if !s.is_null() {
        drop(unsafe { CString::from_raw(s) });
    }
}
