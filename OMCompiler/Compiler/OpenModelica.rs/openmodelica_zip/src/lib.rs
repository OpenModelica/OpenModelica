//! Zip archives for omc: extraction to disk (in parallel where there are
//! threads), packing files and directories, and archives built in memory.
//! Errors are complete messages for the caller's error buffer.

use std::collections::BTreeSet;
use std::io::{Read, Seek, Write};

use openmodelica_wasi::fs;

pub type Result<T> = std::result::Result<T, String>;

/// `Unzip.unzipPath`: strips the longest common directory prefix of all
/// entries (GitHub archives wrap everything in `Repo-hash/`), except its last
/// segment when that is `path_to_extract`, and writes the entries below
/// `path_to_extract` (all when empty) below `dest`.
pub fn unzip_path(zip_file: &str, path_to_extract: &str, dest: &str) -> Result<()> {
    extract(zip_file, dest, |names| select_path(names, path_to_extract))
}

/// `Unzip.unzipAll`: every entry below `dest` under its stored name.
pub fn unzip_all(zip_file: &str, dest: &str) -> Result<()> {
    extract(zip_file, dest, |names| names.iter().map(|n| Some(n.clone())).collect())
}

fn select_path(names: &[String], path: &str) -> Vec<Option<String>> {
    let first = names.first().map_or("", |s| s.as_str());
    let mut common = first.len();
    for name in &names[1..] {
        common = name
            .bytes()
            .zip(first.bytes())
            .take(common)
            .take_while(|(a, b)| a == b)
            .count();
    }
    let mut prefix_len = first.as_bytes()[..common]
        .iter()
        .rposition(|&b| b == b'/')
        .map_or(0, |i| i + 1);
    if !path.is_empty() && prefix_len > path.len() && first[..prefix_len - 1].ends_with(path) {
        prefix_len -= path.len() + 1;
    }
    names
        .iter()
        .map(|name| {
            let rel = name.get(prefix_len..)?;
            if !path.is_empty()
                && !(rel.starts_with(path) && matches!(rel.as_bytes().get(path.len()), None | Some(b'/')))
            {
                return None;
            }
            Some(rel[path.len()..].trim_start_matches('/').to_string())
        })
        .collect()
}

fn extract(zip_file: &str, dest: &str, select: impl FnOnce(&[String]) -> Vec<Option<String>>) -> Result<()> {
    #[allow(unused_mut)]
    let mut archive = open(zip_file)?;
    let names: Vec<String> = (0..archive.len())
        .map(|i| archive.name_for_index(i).unwrap_or("").to_string())
        .collect();
    let mut dirs = BTreeSet::new();
    let mut files = Vec::new();
    for (i, (name, rel)) in names.iter().zip(select(&names)).enumerate() {
        let Some(rel) = rel else { continue };
        if rel.split(['/', '\\']).any(|c| c == "..") {
            continue;
        }
        let out = if rel.is_empty() {
            dest.to_string()
        } else {
            format!("{dest}/{}", rel.trim_end_matches('/'))
        };
        if name.ends_with('/') {
            dirs.insert(out);
        } else {
            if let Some(parent) = out.rfind('/').map(|i| &out[..i]) {
                dirs.insert(parent.to_string());
            }
            files.push((i, out));
        }
    }
    for dir in &dirs {
        fs::create_dir_all(dir).map_err(|e| format!("Failed to create directory {dir}: {e}"))?;
    }
    #[cfg(all(any(unix, windows), not(target_os = "emscripten")))]
    {
        use rayon::prelude::*;
        files
            .par_iter()
            .try_for_each_init(|| archive.clone(), |a, (i, out)| extract_entry(a, zip_file, *i, out))
    }
    #[cfg(not(all(any(unix, windows), not(target_os = "emscripten"))))]
    files
        .iter()
        .try_for_each(|(i, out)| extract_entry(&mut archive, zip_file, *i, out))
}

fn extract_entry<R: Read + Seek>(
    archive: &mut zip::ZipArchive<R>,
    zip_file: &str,
    index: usize,
    out: &str,
) -> Result<()> {
    let mut entry = archive
        .by_index(index)
        .map_err(|e| format!("Failed to read {zip_file}: {e}"))?;
    let write_failed = |e: std::io::Error| format!("Failed to write data to {out}: {e}");
    let mut w = fs::Writer::create(out).map_err(|e| format!("Failed to open file for writing {out}: {e}"))?;
    let mut buf = vec![0u8; 1 << 16];
    loop {
        let n = entry
            .read(&mut buf)
            .map_err(|e| format!("Failed to read {} in {zip_file}: {e}", entry.name()))?;
        if n == 0 {
            break;
        }
        w.write_all(&buf[..n]).map_err(write_failed)?;
    }
    w.flush().map_err(write_failed)?;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        // User execute and the group/other bits from the entry, at least rw-r--r--.
        let mode = (entry.unix_mode().unwrap_or(0) & 0o177) | 0o644;
        std::fs::set_permissions(out, std::fs::Permissions::from_mode(mode)).map_err(write_failed)?;
    }
    Ok(())
}

fn open_failed(zip_file: &str, e: impl std::fmt::Display) -> String {
    format!("Failed to read zip file {zip_file}: {e}")
}

#[cfg(all(any(unix, windows), not(target_os = "emscripten")))]
fn open(zip_file: &str) -> Result<zip::ZipArchive<SharedFile>> {
    let file = std::fs::File::open(zip_file).map_err(|e| format!("Failed to open file {zip_file}: {e}"))?;
    let len = file.metadata().map_err(|e| open_failed(zip_file, e))?.len();
    let file = SharedFile {
        file: std::sync::Arc::new(file),
        len,
        pos: 0,
    };
    zip::ZipArchive::new(file).map_err(|e| open_failed(zip_file, e))
}

#[cfg(not(all(any(unix, windows), not(target_os = "emscripten"))))]
fn open(zip_file: &str) -> Result<zip::ZipArchive<fs::Reader>> {
    let reader = fs::open_read(zip_file).map_err(|e| format!("Failed to open file {zip_file}: {e}"))?;
    zip::ZipArchive::new(reader).map_err(|e| open_failed(zip_file, e))
}

/// One open file read by every extraction thread, each clone at its own
/// position; positioned reads leave the shared descriptor alone.
#[cfg(all(any(unix, windows), not(target_os = "emscripten")))]
#[derive(Clone)]
struct SharedFile {
    file: std::sync::Arc<std::fs::File>,
    len: u64,
    pos: u64,
}

#[cfg(all(any(unix, windows), not(target_os = "emscripten")))]
impl Read for SharedFile {
    fn read(&mut self, buf: &mut [u8]) -> std::io::Result<usize> {
        #[cfg(unix)]
        let n = std::os::unix::fs::FileExt::read_at(&*self.file, buf, self.pos)?;
        #[cfg(windows)]
        let n = std::os::windows::fs::FileExt::seek_read(&*self.file, buf, self.pos)?;
        self.pos += n as u64;
        Ok(n)
    }
}

#[cfg(all(any(unix, windows), not(target_os = "emscripten")))]
impl Seek for SharedFile {
    fn seek(&mut self, pos: std::io::SeekFrom) -> std::io::Result<u64> {
        let to = match pos {
            std::io::SeekFrom::Start(n) => Some(n),
            std::io::SeekFrom::End(d) => self.len.checked_add_signed(d),
            std::io::SeekFrom::Current(d) => self.pos.checked_add_signed(d),
        };
        self.pos = to.ok_or_else(|| {
            std::io::Error::new(std::io::ErrorKind::InvalidInput, "seek before the start of the file")
        })?;
        Ok(self.pos)
    }
}

/// `Unzip.zipPath`: a new `zip_file` with `path` stored under `entry_name`: a
/// file as that entry, a directory recursively below it, or with an empty
/// `entry_name` the contents of a directory at the root.
pub fn zip_path(zip_file: &str, path: &str, entry_name: &str) -> Result<()> {
    zip_paths(zip_file, &[(path, entry_name)], &[])
}

/// A new `zip_file` with every (path, entry name) of `entries` added as by
/// [`zip_path`], leaving out the entries named in `exclude` and everything
/// below them, and `zip_file` itself. Removed again on error.
pub fn zip_paths(zip_file: &str, entries: &[(&str, &str)], exclude: &[&str]) -> Result<()> {
    let r = write_zip_file(zip_file, entries, exclude);
    if r.is_err() {
        let _ = fs::remove_file(zip_file);
    }
    r
}

struct Packer<'a> {
    zip_file: &'a str,
    output: Option<std::path::PathBuf>,
    exclude: &'a [&'a str],
}

fn write_zip_file(zip_file: &str, entries: &[(&str, &str)], exclude: &[&str]) -> Result<()> {
    let write_failed = |e: &dyn std::fmt::Display| format!("Failed to write zip file {zip_file}: {e}");
    if fs::IN_MEMORY {
        let packer = Packer {
            zip_file,
            output: None,
            exclude,
        };
        let mut w = zip::ZipWriter::new(std::io::Cursor::new(Vec::new()));
        for (path, name) in entries {
            packer.add(&mut w, path, name)?;
        }
        let bytes = w.finish().map_err(|e| write_failed(&e))?.into_inner();
        return fs::write(zip_file, &bytes).map_err(|e| write_failed(&e));
    }
    let f = std::fs::File::create(zip_file).map_err(|e| format!("Failed to open file for writing {zip_file}: {e}"))?;
    let packer = Packer {
        zip_file,
        output: std::fs::canonicalize(zip_file).ok(),
        exclude,
    };
    let mut w = zip::ZipWriter::new(std::io::BufWriter::new(f));
    for (path, name) in entries {
        packer.add(&mut w, path, name)?;
    }
    w.finish()
        .map_err(|e| write_failed(&e))?
        .flush()
        .map_err(|e| write_failed(&e))
}

impl Packer<'_> {
    fn add<W: Write + Seek>(&self, w: &mut zip::ZipWriter<W>, path: &str, name: &str) -> Result<()> {
        if self
            .exclude
            .iter()
            .any(|x| name == *x || name.strip_prefix(x).is_some_and(|r| r.starts_with('/')))
        {
            return Ok(());
        }
        let zip_file = self.zip_file;
        let add_failed = |e: &dyn std::fmt::Display| format!("Failed to add {name} to {zip_file}: {e}");
        let options = entry_options(path);
        if !fs::is_dir(path) {
            if self.output.is_some() && std::fs::canonicalize(path).ok() == self.output {
                return Ok(());
            }
            let mut reader = fs::open_read(path).map_err(|e| format!("Failed to open file {path}: {e}"))?;
            let large = fs::len(path).is_ok_and(|n| n >= u32::MAX as u64);
            w.start_file(name, options.large_file(large))
                .map_err(|e| add_failed(&e))?;
            std::io::copy(&mut reader, w).map_err(|e| add_failed(&e))?;
            return Ok(());
        }
        if !name.is_empty() {
            w.add_directory(name, options).map_err(|e| add_failed(&e))?;
        }
        let mut children = fs::read_dir(path).map_err(|e| format!("Failed to open directory {path}: {e}"))?;
        children.sort_by(|a, b| a.name.cmp(&b.name));
        for c in children {
            let child_name = if name.is_empty() {
                c.name.clone()
            } else {
                format!("{name}/{}", c.name)
            };
            self.add(w, &format!("{path}/{}", c.name), &child_name)?;
        }
        Ok(())
    }
}

fn entry_options(path: &str) -> zip::write::SimpleFileOptions {
    let mut options = zip::write::SimpleFileOptions::default();
    if let Some(t) = fs::modified(path).ok().and_then(dos_date_time) {
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

/// An archive of `entries` (name, contents), built in memory. Small entries
/// are stored, the rest deflated; every entry is dated 1980-01-01, so the same
/// entries give the same bytes.
pub fn zip_entries(entries: &[(String, Vec<u8>)]) -> Result<Vec<u8>> {
    let failed = |e: &dyn std::fmt::Display| format!("Failed to write zip archive: {e}");
    let mut w = zip::ZipWriter::new(std::io::Cursor::new(Vec::new()));
    for (name, data) in entries {
        let method = if data.len() < 256 {
            zip::CompressionMethod::Stored
        } else {
            zip::CompressionMethod::Deflated
        };
        let options = zip::write::SimpleFileOptions::default()
            .compression_method(method)
            .last_modified_time(zip::DateTime::DEFAULT)
            .large_file(data.len() as u64 >= u32::MAX as u64);
        w.start_file(name.as_str(), options).map_err(|e| failed(&e))?;
        w.write_all(data).map_err(|e| failed(&e))?;
    }
    Ok(w.finish().map_err(|e| failed(&e))?.into_inner())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_dir(name: &str) -> std::path::PathBuf {
        let dir = std::env::temp_dir().join(format!("openmodelica_zip_{name}_{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        dir
    }

    fn s(p: &std::path::Path) -> String {
        p.display().to_string()
    }

    fn write_zip(path: &std::path::Path, dirs: &[&str], files: &[(&str, &str)]) {
        let mut w = zip::ZipWriter::new(std::fs::File::create(path).unwrap());
        let opts = zip::write::SimpleFileOptions::default();
        for d in dirs {
            w.add_directory(*d, opts).unwrap();
        }
        for (name, data) in files {
            w.start_file(*name, opts).unwrap();
            w.write_all(data.as_bytes()).unwrap();
        }
        w.finish().unwrap();
    }

    #[test]
    fn strips_common_prefix_and_selects_path() {
        let dir = temp_dir("prefix");
        let zip = dir.join("a.zip");
        write_zip(
            &zip,
            &["Repo-abc123/", "Repo-abc123/Modelica/"],
            &[
                ("Repo-abc123/Modelica/package.mo", "package Modelica end Modelica;"),
                ("Repo-abc123/README.md", "readme"),
            ],
        );
        let out = dir.join("out");
        unzip_path(&s(&zip), "Modelica", &s(&out)).unwrap();
        assert_eq!(
            std::fs::read_to_string(out.join("package.mo")).unwrap(),
            "package Modelica end Modelica;"
        );
        assert!(!out.join("README.md").exists());

        let all = dir.join("all");
        unzip_path(&s(&zip), "", &s(&all)).unwrap();
        assert!(all.join("Modelica/package.mo").exists());
        assert!(all.join("README.md").exists());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn creates_directories_without_directory_entries() {
        let dir = temp_dir("nodirs");
        let zip = dir.join("a.zip");
        write_zip(
            &zip,
            &[],
            &[
                ("SDF/Examples/I.mo", "model I end I;"),
                ("SDF/package.mo", "package SDF end SDF;"),
                ("LICENSE.txt", "l"),
            ],
        );
        let out = dir.join("SDF 0.4.5");
        unzip_path(&s(&zip), "SDF", &s(&out)).unwrap();
        assert_eq!(
            std::fs::read_to_string(out.join("Examples/I.mo")).unwrap(),
            "model I end I;"
        );
        assert!(out.join("package.mo").exists());
        assert!(!out.join("LICENSE.txt").exists());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn skips_entries_outside_the_destination() {
        let dir = temp_dir("slip");
        let zip = dir.join("a.zip");
        write_zip(&zip, &[], &[("../evil.txt", "x"), ("ok.txt", "y")]);
        let out = dir.join("out");
        unzip_all(&s(&zip), &s(&out)).unwrap();
        assert!(out.join("ok.txt").exists());
        assert!(!dir.join("evil.txt").exists());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn round_trip_many_files() {
        let dir = temp_dir("roundtrip");
        let src = dir.join("P");
        for i in 0..200 {
            let d = src.join(format!("d{}", i % 7));
            std::fs::create_dir_all(&d).unwrap();
            std::fs::write(d.join(format!("f{i}.mo")), format!("model M{i} end M{i};").repeat(i)).unwrap();
        }
        std::fs::create_dir_all(src.join("empty")).unwrap();

        let mol = dir.join("P.mol");
        zip_path(&s(&mol), &s(&src), "P").unwrap();
        let archive = zip::ZipArchive::new(std::fs::File::open(&mol).unwrap()).unwrap();
        assert!(archive.file_names().all(|n| n.starts_with("P/")));
        assert!(archive.file_names().any(|n| n == "P/empty/"));

        let out = dir.join("out");
        unzip_all(&s(&mol), &s(&out)).unwrap();
        for i in 0..200 {
            let f = out.join(format!("P/d{}/f{i}.mo", i % 7));
            assert_eq!(
                std::fs::read_to_string(f).unwrap(),
                format!("model M{i} end M{i};").repeat(i)
            );
        }
        assert!(out.join("P/empty").is_dir());

        let fmu = dir.join("P.fmu");
        zip_path(&s(&fmu), &s(&src), "").unwrap();
        let root = dir.join("root");
        unzip_path(&s(&fmu), "", &s(&root)).unwrap();
        assert!(root.join("d3/f3.mo").exists());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn zip_paths_excludes_and_skips_its_output() {
        let dir = temp_dir("exclude");
        std::fs::create_dir_all(dir.join("sources/build_cmake")).unwrap();
        std::fs::write(dir.join("sources/a.c"), "a").unwrap();
        std::fs::write(dir.join("sources/build_cmake/x.o"), "x").unwrap();
        std::fs::write(dir.join("modelDescription.xml"), "<m/>").unwrap();
        let fmu = dir.join("M.fmu");
        zip_paths(&s(&fmu), &[(&s(&dir), "")], &["sources/build_cmake"]).unwrap();
        let archive = zip::ZipArchive::new(std::fs::File::open(&fmu).unwrap()).unwrap();
        let mut names: Vec<&str> = archive.file_names().collect();
        names.sort();
        assert_eq!(names, ["modelDescription.xml", "sources/", "sources/a.c"]);

        let two = dir.join("two.zip");
        let md = s(&dir.join("modelDescription.xml"));
        let src = s(&dir.join("sources"));
        zip_paths(
            &s(&two),
            &[(&md, "modelDescription.xml"), (&src, "sources")],
            &["sources"],
        )
        .unwrap();
        let archive = zip::ZipArchive::new(std::fs::File::open(&two).unwrap()).unwrap();
        assert_eq!(archive.file_names().collect::<Vec<_>>(), ["modelDescription.xml"]);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn failures_report_and_clean_up() {
        let dir = temp_dir("fail");
        assert!(unzip_all(&s(&dir.join("missing.zip")), &s(&dir)).is_err());
        let zip = dir.join("x.zip");
        assert!(zip_path(&s(&zip), &s(&dir.join("missing")), "").is_err());
        assert!(!zip.exists());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn in_memory_archive_is_deterministic() {
        let entries = vec![
            ("a.txt".to_string(), b"small".to_vec()),
            ("b/c.bin".to_string(), vec![7u8; 4096]),
        ];
        let bytes = zip_entries(&entries).unwrap();
        assert_eq!(bytes, zip_entries(&entries).unwrap());
        let mut archive = zip::ZipArchive::new(std::io::Cursor::new(bytes)).unwrap();
        let mut c = Vec::new();
        archive.by_name("b/c.bin").unwrap().read_to_end(&mut c).unwrap();
        assert_eq!(c, vec![7u8; 4096]);
        assert_eq!(
            archive.by_name("b/c.bin").unwrap().compression(),
            zip::CompressionMethod::Deflated
        );
        assert_eq!(
            archive.by_name("a.txt").unwrap().compression(),
            zip::CompressionMethod::Stored
        );
    }
}
