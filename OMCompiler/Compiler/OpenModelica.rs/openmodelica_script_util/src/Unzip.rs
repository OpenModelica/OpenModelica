// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/Unzip.mo`, whose functions are
// `external "C"` shims into `OMCompiler/Compiler/runtime/om_unzip.c` and
// `om_zip.c` (minizip). We use the pure-Rust `zip` crate instead.
//
// Semantics of `unzipPath` mirrored from `om_unzip`:
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

use arcstr::ArcStr;
use metamodelica::List;
use openmodelica_error::ErrorTypes;
use openmodelica_util::Error;

/// `c_add_message(NULL, -1, ErrorType_runtime, ErrorLevel_error, ...)`
/// equivalent: an ad-hoc runtime error with no source location. Failures
/// to push the message are ignored — this function is itself only used on
/// error paths that already return `false`.
fn add_error(template: &str, tokens: &[&str]) {
    let mut toks: List<ArcStr> = metamodelica::nil();
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
    unzip_impl(&fileName, &pathToExtract, &destinationPath, true).is_ok()
}

/// `om_unzip_all`: every entry under its stored name, no prefix stripped.
pub fn unzipAll(fileName: ArcStr, destinationPath: ArcStr) -> bool {
    unzip_impl(&fileName, "", &destinationPath, false).is_ok()
}

fn unzip_impl(
    zip_file_name: &str,
    path_to_extract: &str,
    dest_path: &str,
    strip_common_prefix: bool,
) -> Result<(), ()> {
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
    let mut common_len = if strip_common_prefix { first_name.len() } else { 0 };
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
            // Zip files need not contain entries for the directories.
            if let Some(parent) = std::path::Path::new(&out_path).parent() {
                if std::fs::create_dir_all(parent).is_err() {
                    add_error("Failed to open file for writing %s", &[&out_path]);
                    return Err(());
                }
            }
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
                if std::fs::set_permissions(&out_path, std::fs::Permissions::from_mode(mode)).is_err() {
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

/// `om_zip` in `runtime/om_zip.c`. The archive is assembled in memory on the
/// web target and written to disk natively.
pub fn zipPath(zipFileName: ArcStr, path: ArcStr, entryName: ArcStr) -> bool {
    let ok = zip_impl(&zipFileName, &path, &entryName).is_ok();
    if !ok {
        let _ = openmodelica_wasi::fs::remove_file(&zipFileName);
    }
    ok
}

fn zip_impl(zip_file_name: &str, path: &str, entry_name: &str) -> Result<(), ()> {
    use std::io::Write;
    let write_failed = || add_error("minizip failed to write to %s", &[zip_file_name]);
    if openmodelica_wasi::fs::IN_MEMORY {
        let mut w = zip::ZipWriter::new(std::io::Cursor::new(Vec::new()));
        add_path(&mut w, zip_file_name, path, entry_name)?;
        let bytes = w.finish().map_err(|_| write_failed())?.into_inner();
        openmodelica_wasi::fs::write(zip_file_name, &bytes).map_err(|_| write_failed())
    } else {
        let Ok(f) = std::fs::File::create(zip_file_name) else {
            add_error("Failed to open file for writing %s", &[zip_file_name]);
            return Err(());
        };
        let mut w = zip::ZipWriter::new(std::io::BufWriter::new(f));
        add_path(&mut w, zip_file_name, path, entry_name)?;
        w.finish()
            .map_err(|_| write_failed())?
            .flush()
            .map_err(|_| write_failed())
    }
}

fn add_path<W: std::io::Write + std::io::Seek>(
    w: &mut zip::ZipWriter<W>,
    zip_file_name: &str,
    path: &str,
    name: &str,
) -> Result<(), ()> {
    use openmodelica_wasi::fs;
    let options = entry_options(path);
    if !fs::is_dir(path) {
        let Ok(mut reader) = fs::open_read(path) else {
            add_error("Failed to open file: %s", &[path]);
            return Err(());
        };
        let large = fs::len(path).is_ok_and(|n| n >= u32::MAX as u64);
        if w.start_file(name, options.large_file(large)).is_err() {
            add_error("minizip failed to add %s to %s", &[name, zip_file_name]);
            return Err(());
        }
        if std::io::copy(&mut reader, w).is_err() {
            add_error("minizip failed to write to %s", &[zip_file_name]);
            return Err(());
        }
        return Ok(());
    }
    if !name.is_empty() && w.add_directory(name, options).is_err() {
        add_error("minizip failed to add %s to %s", &[name, zip_file_name]);
        return Err(());
    }
    let Ok(mut entries) = fs::read_dir(path) else {
        add_error("Failed to open directory: %s", &[path]);
        return Err(());
    };
    entries.sort_by(|a, b| a.name.cmp(&b.name));
    for e in entries {
        let child_name = if name.is_empty() {
            e.name.clone()
        } else {
            format!("{name}/{}", e.name)
        };
        add_path(w, zip_file_name, &format!("{path}/{}", e.name), &child_name)?;
    }
    Ok(())
}

fn entry_options(path: &str) -> zip::write::SimpleFileOptions {
    let mut options = zip::write::SimpleFileOptions::default();
    if let Some(t) = openmodelica_wasi::fs::modified(path).ok().and_then(dos_date_time) {
        options = options.last_modified_time(t);
    }
    #[cfg(unix)]
    if let Ok(m) = std::fs::metadata(path) {
        use std::os::unix::fs::PermissionsExt;
        options = options.unix_permissions(m.permissions().mode());
    }
    options
}

/// UTC, as there is no time zone database on every target.
fn dos_date_time(t: std::time::SystemTime) -> Option<zip::DateTime> {
    let secs = t.duration_since(std::time::UNIX_EPOCH).ok()?.as_secs();
    let (days, s) = ((secs / 86400) as i64, secs % 86400);
    // civil_from_days, http://howardhinnant.github.io/date_algorithms.html
    let z = days + 719468;
    let era = z.div_euclid(146097);
    let doe = z - era * 146097;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let day = doy - (153 * mp + 2) / 5 + 1;
    let month = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = yoe + era * 400 + i64::from(month <= 2);
    zip::DateTime::from_date_and_time(
        u16::try_from(year).ok()?,
        month as u8,
        day as u8,
        (s / 3600) as u8,
        (s / 60 % 60) as u8,
        (s % 60) as u8,
    )
    .ok()
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

    /// A zip with no directory entries at all, as the SDF-Modelica releases
    /// are built: every directory has to come from the file names.
    #[test]
    fn extracts_zip_without_directory_entries() {
        let dir = std::env::temp_dir().join(format!("unzip_rs_nodirs_{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        let zip_path = dir.join("a.zip");
        {
            let f = std::fs::File::create(&zip_path).unwrap();
            let mut w = zip::ZipWriter::new(f);
            let opts: zip::write::SimpleFileOptions = Default::default();
            w.start_file("SDF/Examples/InterpolationMethods.mo", opts).unwrap();
            w.write_all(b"model InterpolationMethods end InterpolationMethods;")
                .unwrap();
            w.start_file("SDF/package.mo", opts).unwrap();
            w.write_all(b"package SDF end SDF;").unwrap();
            w.start_file("LICENSE.txt", opts).unwrap();
            w.write_all(b"license").unwrap();
            w.finish().unwrap();
        }
        let dest = dir.join("SDF 0.4.5");
        std::fs::create_dir_all(&dest).unwrap();
        let ok = unzipPath(
            ArcStr::from(zip_path.display().to_string()),
            ArcStr::from("SDF"),
            ArcStr::from(dest.display().to_string()),
        );
        assert!(ok);
        assert!(dest.join("package.mo").exists());
        assert_eq!(
            std::fs::read_to_string(dest.join("Examples/InterpolationMethods.mo")).unwrap(),
            "model InterpolationMethods end InterpolationMethods;"
        );
        assert!(!dest.join("LICENSE.txt").exists(), "filtered path must be skipped");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn zip_path_round_trip() {
        let dir = std::env::temp_dir().join(format!("zip_rs_test_{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(dir.join("P/sub")).unwrap();
        std::fs::write(dir.join("P/package.mo"), "package P end P;").unwrap();
        std::fs::write(dir.join("P/sub/a.txt"), "a").unwrap();
        let s = |p: &std::path::Path| ArcStr::from(p.display().to_string());

        let mol = dir.join("P.mol");
        assert!(zipPath(s(&mol), s(&dir.join("P")), ArcStr::from("P")));
        let archive = zip::ZipArchive::new(std::fs::File::open(&mol).unwrap()).unwrap();
        let names: Vec<&str> = archive.file_names().collect();
        let mut sorted = names.clone();
        sorted.sort();
        assert_eq!(sorted, ["P/", "P/package.mo", "P/sub/", "P/sub/a.txt"]);

        let fmu = dir.join("P.fmu");
        assert!(zipPath(s(&fmu), s(&dir.join("P")), ArcStr::from("")));
        let out = dir.join("out");
        std::fs::create_dir_all(&out).unwrap();
        assert!(unzipPath(s(&fmu), ArcStr::from(""), s(&out)));
        assert_eq!(std::fs::read_to_string(out.join("sub/a.txt")).unwrap(), "a");
        assert_eq!(
            std::fs::read_to_string(out.join("package.mo")).unwrap(),
            "package P end P;"
        );
        assert!(unzipAll(s(&mol), s(&out)));
        assert_eq!(std::fs::read_to_string(out.join("P/sub/a.txt")).unwrap(), "a");

        assert!(!zipPath(
            s(&dir.join("x.zip")),
            s(&dir.join("missing")),
            ArcStr::from("")
        ));
        assert!(!dir.join("x.zip").exists());

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
