// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/Unzip.mo`, whose single function
// is an `external "C"` shim into `OMCompiler/Compiler/runtime/om_unzip.c`
// (minizip). We use the pure-Rust `zip` crate instead.
//
// Semantics mirrored from `om_unzip`:
//
//   * The longest common `/`-terminated prefix of *all* entry names is
//     stripped (GitHub-style archives wrap everything in a top-level
//     `Repo-hash/` directory).
//   * If the last segment of that common prefix equals `pathToExtract`,
//     the segment is kept (the caller asked for it by name).
//   * Only entries under `pathToExtract` (after prefix stripping) are
//     extracted; an empty `pathToExtract` extracts everything.
//   * Files are written to `destinationPath/<relative path>`; POSIX
//     permissions are restored from the entry's external attributes with
//     `rw-r--r--` as the base, directories get `rwxr-xr-x`.
//   * Errors are reported through the error buffer (mirroring the
//     `c_add_message` calls) and abort the whole extraction.

#![allow(non_snake_case)]

use std::io::Read;
use std::sync::Arc;

use arcstr::ArcStr;
use metamodelica::List;
use openmodelica_util::Error;
use openmodelica_error::ErrorTypes;

/// `c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, ...)`
/// equivalent: an ad-hoc runtime error with no source location. Failures
/// to push the message are ignored — this function is itself only used on
/// error paths that already return `false`.
fn add_error(template: &str, tokens: &[&str]) {
    let mut toks: Arc<List<ArcStr>> = Arc::new(List::Nil);
    for t in tokens.iter().rev() {
        toks = metamodelica::cons(ArcStr::from(*t), toks);
    }
    let _ = Error::addMessage(
        ErrorTypes::Message {
            id: -1,
            ty: ErrorTypes::MessageType::SIMULATION,
            severity: ErrorTypes::Severity::ERROR,
            message: ArcStr::from(template),
        },
        toks,
    );
}

pub fn unzipPath(fileName: ArcStr, pathToExtract: ArcStr, destinationPath: ArcStr) -> bool {
    unzip_impl(&fileName, &pathToExtract, &destinationPath).is_ok()
}

fn unzip_impl(zip_file_name: &str, path_to_extract: &str, dest_path: &str) -> Result<(), ()> {
    // The archive is read through the fs facade: off disk natively, from the
    // in-memory store on the web target (entry writes route the same way).
    let reader = match openmodelica_wasi::fs::open_read(zip_file_name) {
        Ok(r) => r,
        Err(_) => {
            add_error("Failed to open file: %s", &[zip_file_name]);
            return Err(());
        }
    };
    let mut archive = match zip::ZipArchive::new(reader) {
        Ok(a) => a,
        Err(_) => {
            add_error("minizip failed to read file global info: %s", &[zip_file_name]);
            return Err(());
        }
    };
    if archive.is_empty() {
        return Ok(());
    }

    // Longest common prefix of all entry names, cut back to a '/' boundary.
    let first_name = archive.name_for_index(0).unwrap_or("").to_string();
    let mut common_len = first_name.len();
    for i in 1..archive.len() {
        let name = archive.name_for_index(i).unwrap_or("");
        common_len = name
            .bytes()
            .zip(first_name.bytes())
            .take(common_len)
            .take_while(|(a, b)| a == b)
            .count();
    }
    let mut common_prefix = &first_name[..common_len];
    while !common_prefix.is_empty() && !common_prefix.ends_with('/') {
        common_prefix = &common_prefix[..common_prefix.len() - 1];
    }
    // Keep the last segment of the common prefix when it *is* the path the
    // caller asked to extract (e.g. an archive wrapping everything in
    // `Modelica/` with pathToExtract = "Modelica").
    if !path_to_extract.is_empty()
        && common_prefix.len() > path_to_extract.len()
        && common_prefix[..common_prefix.len() - 1].ends_with(path_to_extract)
    {
        common_prefix = &common_prefix[..common_prefix.len() - path_to_extract.len() - 1];
    }
    let common_len = common_prefix.len();

    for i in 0..archive.len() {
        let mut entry = match archive.by_index(i) {
            Ok(e) => e,
            Err(_) => {
                add_error("minizip failed to read file info: %s", &[zip_file_name]);
                return Err(());
            }
        };
        let name = entry.name().to_string();
        let Some(rel) = name.get(common_len..) else { continue };
        // Filter to the requested sub-path: `rel` must be exactly
        // `pathToExtract` (a directory) or start with `pathToExtract/`.
        if !path_to_extract.is_empty() {
            let matches = rel.starts_with(path_to_extract)
                && matches!(rel.as_bytes().get(path_to_extract.len()), None | Some(b'/'));
            if !matches {
                continue;
            }
        }
        // Destination: destPath + '/' + remainder (the leading '/' of the
        // remainder after stripping pathToExtract doubles as the separator).
        let remainder = &rel[path_to_extract.len()..];
        let out_path = if remainder.starts_with('/') || remainder.is_empty() {
            format!("{dest_path}{remainder}")
        } else {
            format!("{dest_path}/{remainder}")
        };

        if name.ends_with('/') {
            // Directory entry. The VFS has no directory objects (paths are
            // implicit in file keys), so only the native build materialises one.
            #[cfg(not(target_arch = "wasm32"))]
            {
                if std::fs::create_dir_all(&out_path).is_err() {
                    add_error("Failed to open file for writing %s", &[&out_path]);
                    return Err(());
                }
                #[cfg(unix)]
                {
                    use std::os::unix::fs::PermissionsExt;
                    let _ = std::fs::set_permissions(&out_path, std::fs::Permissions::from_mode(0o755));
                }
            }
            continue;
        }

        // Write the entry's bytes to `out_path` (a real file natively, a VFS
        // entry on wasm).
        #[cfg(not(target_arch = "wasm32"))]
        {
            let mut fout = match std::fs::File::create(&out_path) {
                Ok(f) => f,
                Err(_) => {
                    add_error("Failed to open file for writing %s", &[&out_path]);
                    return Err(());
                }
            };
            let mut buf = [0u8; 8192];
            loop {
                match entry.read(&mut buf) {
                    Ok(0) => break,
                    Ok(n) => {
                        use std::io::Write;
                        if let Err(e) = fout.write_all(&buf[..n]) {
                            add_error("Failed to write data to %s: %s", &[&out_path, &e.to_string()]);
                            return Err(());
                        }
                    }
                    Err(_) => {
                        add_error("minizip failed to open read data in %s", &[zip_file_name]);
                        return Err(());
                    }
                }
            }
            // Restore permissions from the entry: keep user-execute and all
            // group/other bits, with rw-r--r-- as the base — exactly the
            // `((external_fa >> 16) & 0x7F) | 0644` computation in om_unzip.c.
            // Windows has no unix permission bits, so this is unix-only.
            #[cfg(unix)]
            {
                use std::os::unix::fs::PermissionsExt;
                let mode = (entry.unix_mode().unwrap_or(0) & 0o177) | 0o644;
                if std::fs::set_permissions(&out_path, std::fs::Permissions::from_mode(mode)).is_err()
                {
                    add_error("fchmod failed for %s: %s", &[&out_path, "set_permissions failed"]);
                    return Err(());
                }
            }
        }
        #[cfg(target_arch = "wasm32")]
        {
            let mut data = Vec::with_capacity(entry.size() as usize);
            if entry.read_to_end(&mut data).is_err() {
                add_error("minizip failed to open read data in %s", &[zip_file_name]);
                return Err(());
            }
            openmodelica_wasi::write(&out_path, data);
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    /// Build a zip with a GitHub-style wrapper directory and check both the
    /// prefix stripping and the pathToExtract filtering.
    #[test]
    fn extracts_subpath_and_strips_common_prefix() {
        let dir = std::env::temp_dir().join(format!("unzip_rs_test_{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        let zip_path = dir.join("a.zip");
        {
            let f = std::fs::File::create(&zip_path).unwrap();
            let mut w = zip::ZipWriter::new(f);
            let opts: zip::write::SimpleFileOptions = Default::default();
            w.add_directory("Repo-abc123/", opts).unwrap();
            w.add_directory("Repo-abc123/Modelica/", opts).unwrap();
            w.start_file("Repo-abc123/Modelica/package.mo", opts).unwrap();
            w.write_all(b"package Modelica end Modelica;").unwrap();
            w.start_file("Repo-abc123/README.md", opts).unwrap();
            w.write_all(b"readme").unwrap();
            w.finish().unwrap();
        }
        let dest = dir.join("out");
        std::fs::create_dir_all(&dest).unwrap();
        let ok = unzipPath(
            ArcStr::from(zip_path.display().to_string()),
            ArcStr::from("Modelica"),
            ArcStr::from(dest.display().to_string()),
        );
        assert!(ok);
        assert_eq!(
            std::fs::read_to_string(dest.join("package.mo")).unwrap(),
            "package Modelica end Modelica;"
        );
        assert!(!dest.join("README.md").exists(), "filtered path must be skipped");

        // Extract-everything mode: empty pathToExtract.
        let dest_all = dir.join("out_all");
        std::fs::create_dir_all(&dest_all).unwrap();
        let ok = unzipPath(
            ArcStr::from(zip_path.display().to_string()),
            ArcStr::from(""),
            ArcStr::from(dest_all.display().to_string()),
        );
        assert!(ok);
        assert!(dest_all.join("Modelica/package.mo").exists());
        assert!(dest_all.join("README.md").exists());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn missing_zip_reports_failure() {
        assert!(!unzipPath(
            ArcStr::from("/nonexistent/x.zip"),
            ArcStr::from(""),
            ArcStr::from("/tmp"),
        ));
    }
}
