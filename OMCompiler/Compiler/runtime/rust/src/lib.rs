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

fn text(s: impl Into<Vec<u8>>) -> *mut c_char {
    let mut bytes = s.into();
    bytes.retain(|&b| b != 0);
    CString::new(bytes).unwrap_or_default().into_raw()
}

/// # Safety
/// `zip` is a NUL-terminated string and `entries` points to writable storage.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_zip_entries(zip: *const c_char, entries: *mut *mut c_char) -> *mut c_char {
    match openmodelica_zip::entries(&unsafe { arg(zip) }) {
        Ok(names) => {
            unsafe { *entries = text(names.join("\n")) };
            std::ptr::null_mut()
        }
        Err(e) => result(Err(e)),
    }
}

/// # Safety
/// `zip` and `path` are NUL-terminated strings and `contents` points to writable storage.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_zip_read(
    zip: *const c_char,
    path: *const c_char,
    contents: *mut *mut c_char,
) -> *mut c_char {
    match openmodelica_zip::read(&unsafe { arg(zip) }, &unsafe { arg(path) }) {
        Ok(bytes) => {
            unsafe { *contents = text(bytes) };
            std::ptr::null_mut()
        }
        Err(e) => result(Err(e)),
    }
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

/// The JSON response of the package manager to a JSON request; see
/// `openmodelica_package_manager::call`. Never NULL.
///
/// # Safety
/// `request` is a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_package_manager(request: *const c_char) -> *mut c_char {
    let response = openmodelica_package_manager::call(&unsafe { arg(request) });
    CString::new(response.replace('\0', " ")).unwrap_or_default().into_raw()
}

/// The JSON response of `openmodelica_fmi_guide::call`.
///
/// # Safety
/// `request` is a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_fmi_guide(request: *const c_char) -> *mut c_char {
    let response = openmodelica_fmi_guide::call(&unsafe { arg(request) });
    CString::new(response.replace('\0', " ")).unwrap_or_default().into_raw()
}

/// `openmodelica_version::compare_parts` as -1, 0 or 1.
///
/// # Safety
/// `a` and `b` are NUL-terminated strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_version_compare(a: *const c_char, b: *const c_char, pre: c_int, build: c_int) -> c_int {
    use openmodelica_version::{Version, compare_parts};
    let (a, b) = unsafe { (Version::parse(&arg(a)), Version::parse(&arg(b))) };
    compare_parts(&a, &b, pre != 0, build != 0) as c_int
}

/// `openmodelica_version::canonical`.
///
/// # Safety
/// `s` is a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_version_canonical(s: *const c_char) -> *mut c_char {
    let text = openmodelica_version::canonical(&unsafe { arg(s) });
    CString::new(text).unwrap_or_default().into_raw()
}

/// Whether `s` is a numbered version, not a branch or empty.
///
/// # Safety
/// `s` is a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_version_is_numbered(s: *const c_char) -> c_int {
    let v = openmodelica_version::Version::parse(&unsafe { arg(s) });
    matches!(v.kind, openmodelica_version::Kind::Numbered { .. }) as c_int
}

/// # Safety
/// `p` is a NUL-terminated string.
unsafe fn bytes<'a>(p: *const c_char) -> &'a [u8] {
    unsafe { CStr::from_ptr(p) }.to_bytes()
}

fn c_bytes(text: Vec<u8>) -> *mut c_char {
    CString::new(text).unwrap_or_default().into_raw()
}

/// `openmodelica_modelica_diff::merge_bytes`. Never NULL.
///
/// # Safety
/// Every pointer is a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_modelica_diff(
    before: *const c_char,
    before_canonical: *const c_char,
    after: *const c_char,
) -> *mut c_char {
    use openmodelica_modelica_diff::merge_bytes;
    c_bytes(unsafe { merge_bytes(bytes(before), bytes(before_canonical), bytes(after)) })
}

/// `openmodelica_modelica_diff::render_bytes`, with `format` the
/// `ModelicaDiff.Format` literal (1-based). Never NULL.
///
/// # Safety
/// Every pointer is a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_modelica_render(before: *const c_char, merged: *const c_char, format: c_int) -> *mut c_char {
    use openmodelica_modelica_diff::{Format, render_bytes};
    let format = match format {
        2 => Format::Color,
        3 => Format::Xml,
        _ => Format::Plain,
    };
    c_bytes(unsafe { render_bytes(bytes(before), bytes(merged), format) })
}

/// `openmodelica_modelica_diff::code_equal_bytes`.
///
/// # Safety
/// `a` and `b` are NUL-terminated strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_modelica_code_equal(a: *const c_char, b: *const c_char) -> c_int {
    unsafe { openmodelica_modelica_diff::code_equal_bytes(bytes(a), bytes(b)) as c_int }
}

/// # Safety
/// `s` is NULL or a string returned by this library.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omcrs_free_string(s: *mut c_char) {
    if !s.is_null() {
        drop(unsafe { CString::from_raw(s) });
    }
}
