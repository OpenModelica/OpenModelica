//! `modelica://` / `file://` URI resolution (`uriToFilename`).

use std::cell::RefCell;
use anyhow::Result;
use arcstr::ArcStr;
use crate::Array;
use crate::omc_assert;

thread_local! {
    /// Class-name → source-directory mapping for `modelica://` URI
    /// resolution. The Rust analogue of the C runtime's
    /// `threadData->localRoots[LOCAL_ROOT_URI_LOOKUP]`: an interleaved
    /// `[name1, dir1, name2, dir2, ...]` array sorted by name, installed by
    /// `SymbolTable.updateUriMapping` (via `System.updateUriMapping`)
    /// whenever the loaded program changes.
    static URI_LOOKUP: RefCell<Array<ArcStr>> = RefCell::new(Default::default());
}

/// Install the `modelica://` URI lookup table. Port of
/// `OpenModelica_updateUriMapping` (`SimulationRuntime/c/util/utility.c`),
/// which stashes the array in a thread-local root for [`uriToFilename`] to
/// read later. No parsing happens here.
pub fn updateUriMapping(namesAndDirs: Array<ArcStr>) {
    URI_LOOKUP.with(|r| *r.borrow_mut() = namesAndDirs);
}

/// Port of `lookupDirectoryFromName`: binary-search the interleaved
/// `[name, dir, ...]` table for `name` and return its directory.
fn uri_lookup_directory(name: &str) -> Option<String> {
    URI_LOOKUP.with(|r| {
        let table = r.borrow();
        let table = table.borrow();
        // The table is sorted by name (AvlTreeStringString in-order), so a
        // binary search matches the C bsearch; a linear scan would also be
        // correct but the table can hold every loaded top-level class.
        let mut lo = 0usize;
        let mut hi = table.len() / 2;
        while lo < hi {
            let mid = (lo + hi) / 2;
            match name.cmp(table[2 * mid].as_str()) {
                std::cmp::Ordering::Equal => return Some(table[2 * mid + 1].to_string()),
                std::cmp::Ordering::Less => hi = mid,
                std::cmp::Ordering::Greater => lo = mid + 1,
            }
        }
        None
    })
}

/// Port of `OpenModelica_decode_uri_inplace`: `+` becomes a space and
/// `%XX` hex escapes are decoded; a `%` followed by invalid hex is copied
/// through literally.
fn decode_uri(src: &str) -> String {
    let bytes = src.as_bytes();
    let mut out: Vec<u8> = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'+' => out.push(b' '),
            b'%' if i + 2 < bytes.len()
                && bytes[i + 1].is_ascii_hexdigit()
                && bytes[i + 2].is_ascii_hexdigit() =>
            {
                let hi = (bytes[i + 1] as char).to_digit(16).unwrap() as u8;
                let lo = (bytes[i + 2] as char).to_digit(16).unwrap() as u8;
                out.push(hi * 16 + lo);
                i += 2;
            }
            b => out.push(b),
        }
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

/// Converts a Modelica URI to an absolute filename.
///
/// Mirrors `OpenModelica_uriToFilename_impl` in
/// `OMCompiler/SimulationRuntime/c/util/utility.c` (with a NULL
/// `resourcesDir`, like the `OpenModelica_uriToFilename` builtin). The
/// MM-source-level `OpenModelica.Scripting.uriToFilename(uri)` lowers to
/// this when called from generated code (see the rewrite in
/// `mmtorust::typedexp::cref_to_dotted`).
///
/// Schemes handled:
/// * `modelica://Package.Sub/path` — look up `Package`'s source directory
///   in the table installed by [`updateUriMapping`], descend into nested
///   class subdirectories as long as they exist on disk, and append the
///   path part. Fails (like the C `MMC_THROW`) when the package is not in
///   the table.
/// * `file://path` — strip the prefix and treat as a regular path.
/// * Other `xxx://` URIs — fail, matching the C runtime's `MMC_THROW`.
/// * Plain paths — canonicalize through `std::fs::canonicalize` if the path
///   exists; otherwise return as-is when absolute, or prepend the current
///   working directory when relative.
pub fn uriToFilename(uri_om: ArcStr) -> Result<ArcStr> {
    let uri = &*uri_om;
    if uri.is_empty() {
        omc_assert!("Malformed URI (got an empty string)");
    }
    // Scheme matching is case-insensitive per the C implementation
    // (`strncasecmp`). Only the prefix is lowercased — paths on
    // case-sensitive filesystems must keep their original casing.
    let scheme_match = |prefix: &str| -> bool {
        uri.len() >= prefix.len()
            && uri[..prefix.len()].eq_ignore_ascii_case(prefix)
    };

    // Resolve the path the same way `uriToFilenameRegularPaths` does for
    // non-FMU calls (resourcesDir == NULL). `orig_uri` only feeds the
    // trailing-slash rule: a directory result keeps a trailing '/' when the
    // *original URI* ended with one.
    fn regular_paths(path: &str, orig_uri: &ArcStr) -> ArcStr {
        let p = std::path::Path::new(path);
        match std::fs::canonicalize(p) {
            Ok(canon) => {
                let mut s = canon.to_string_lossy().into_owned();
                if orig_uri.ends_with('/') && !s.ends_with('/') && p.is_dir() {
                    s.push('/');
                }
                ArcStr::from(s)
            }
            Err(_) => {
                // Path does not exist (yet). For absolute paths, return
                // as-is; for relative paths, prepend the current working
                // directory.
                let is_absolute = p.is_absolute()
                    || (path.len() >= 2 && path.as_bytes()[1] == b':'
                        && path.as_bytes()[0].is_ascii_alphabetic());
                if is_absolute {
                    ArcStr::from(path)
                } else if let Ok(cwd) = std::env::current_dir() {
                    let mut joined = cwd;
                    joined.push(path);
                    ArcStr::from(joined.to_string_lossy().into_owned())
                } else {
                    ArcStr::from(path)
                }
            }
        }
    }

    if scheme_match("modelica://") {
        let rest = &uri[11..];
        // getIdent: the class name runs up to the first '.' or '/'.
        let ident_end = rest.find(['.', '/']).unwrap_or(rest.len());
        let class_name = &rest[..ident_end];
        if class_name.is_empty() {
            omc_assert!("Malformed URI (couldn't get a class name): {uri}");
        }
        let mut dir = match uri_lookup_directory(class_name).filter(|d| !d.is_empty()) {
            Some(dir) => dir,
            None => omc_assert!("Failed to lookup URI (is the package loaded?) {uri}"),
        };
        let rest = decode_uri(&rest[ident_end..]);
        // Descend into nested class subdirectories: for each `.Ident`,
        // extend the directory while `<dir>/<Ident>` exists on disk. An
        // ident whose directory does not exist is consumed and *dropped* —
        // the resource path is relative to the innermost class that has
        // its own directory (same as the C loop).
        let mut pos = 0usize;
        while rest[pos..].starts_with('.') {
            pos += 1;
            let id_end = rest[pos..]
                .find(['.', '/'])
                .map(|i| pos + i)
                .unwrap_or(rest.len());
            if id_end == pos {
                if rest[id_end..].starts_with('.') {
                    omc_assert!("Malformed URI (double dot in class name): {uri}");
                }
                break; // '/' or end of string
            }
            let candidate = std::format!("{dir}/{}", &rest[pos..id_end]);
            pos = id_end;
            if !std::path::Path::new(&candidate).is_dir() {
                break;
            }
            dir = candidate;
        }
        // Skip to just past the next '/'; everything after it is the
        // resource path, re-joined to the directory including the '/'.
        let path = match rest[pos..].find('/') {
            None => dir,
            Some(i) if pos + i + 1 == rest.len() => dir,
            Some(i) => std::format!("{dir}{}", &rest[pos + i..]),
        };
        return Ok(regular_paths(&path, &uri_om));
    }

    let path: &str = if scheme_match("file://") {
        &uri[7..]
    } else if uri.contains("://") {
        omc_assert!("Unknown URI schema: {uri}");
    } else {
        uri
    };
    Ok(regular_paths(path, &uri_om))
}
