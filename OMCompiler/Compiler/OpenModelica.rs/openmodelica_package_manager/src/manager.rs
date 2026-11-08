//! The package manager: the package index, installing libraries with their
//! uses, the prebuilt wasm modules and the wasm toolchain. Messages are
//! named after the `Error.mo` messages omc reports them with.

use std::sync::Arc;

use openmodelica_wasi::fs;
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};

use crate::legacy;
use crate::{Index, Installed, Problem, Requirement, Selected, scan};

const INDEX_URL: &str = "https://libraries.openmodelica.org/index/v1/index.json";
const METADATA: &str = "openmodelica.metadata.json";
const WASM_ZIP_MARKER: &str = ".omc-zipfile";

/// Where omc runs; sent with each request.
#[derive(Deserialize, Default)]
#[serde(default, rename_all = "camelCase")]
pub(crate) struct Env {
    pub home: String,
    pub installation_dir: String,
    pub modelica_path: String,
    pub group_delimiter: String,
    pub testsuite: bool,
    pub max_parallel: usize,
    pub index_url: Option<String>,
}

#[derive(Serialize, Debug, PartialEq, Eq)]
pub struct Note {
    pub name: &'static str,
    pub tokens: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub file: Option<String>,
}

pub(crate) struct Manager<'a> {
    env: &'a Env,
    pub notes: Vec<Note>,
}

fn basename(path: &str) -> &str {
    path.rsplit('/').next().unwrap_or(path)
}

/// `System.dirname`: "." without a directory.
fn dirname(path: &str) -> &str {
    match path.rfind('/') {
        Some(0) => "/",
        Some(i) => &path[..i],
        None => ".",
    }
}

fn str_of<'v>(v: &'v Value, key: &str) -> Option<&'v str> {
    v.get(key).and_then(Value::as_str)
}

/// The sha of an index entry or metadata, else the name of its zip file.
fn sha_or_zipfile(v: &Value) -> Option<String> {
    match str_of(v, "sha") {
        Some(sha) => Some(sha.to_owned()),
        None => str_of(v, "zipfile").map(|z| basename(z).to_owned()),
    }
}

fn read_json(path: &str) -> Option<Value> {
    serde_json::from_str(&fs::read_to_string(path).ok()?).ok()
}

/// A zip of prebuilt wasm modules and the directory under
/// `Resources/Library/wasm32-wasip1` it unpacks into.
#[derive(Clone, PartialEq, Eq)]
struct WasmZip {
    url: String,
    dir: String,
}

impl WasmZip {
    fn is_generation(&self) -> bool {
        self.dir.split('/').filter(|s| !s.is_empty()).count() == 1
    }
}

struct Package {
    needs_install: bool,
    name: String,
    version: String,
    zipfile: String,
    path: String,
    sha: String,
    single_file_copy_all: bool,
    json: Value,
}

impl<'a> Manager<'a> {
    pub fn new(env: &'a Env) -> Self {
        Manager { env, notes: Vec::new() }
    }

    pub fn env(&self) -> &Env {
        self.env
    }

    fn note(&mut self, name: &'static str, tokens: Vec<String>, file: Option<String>) {
        self.notes.push(Note { name, tokens, file });
    }

    fn user_libraries(&self) -> String {
        format!("{}/.openmodelica/libraries/", self.env.home)
    }

    fn index_path(&self) -> String {
        format!("{}index.json", self.user_libraries())
    }

    fn cache_path(&self) -> String {
        format!("{}/.openmodelica/cache/", self.env.home)
    }

    fn installation_cache_path(&self) -> String {
        format!("{}/share/omlibrary/cache/", self.env.installation_dir)
    }

    pub fn modelica_path(&self, path: &str) -> Vec<String> {
        let delimiter = if self.env.group_delimiter.is_empty() {
            ":"
        } else {
            &self.env.group_delimiter
        };
        path.split(delimiter)
            .filter(|s| !s.is_empty())
            .map(str::to_owned)
            .collect()
    }

    fn download(&mut self, items: Vec<(Vec<String>, String)>) -> bool {
        if items.is_empty() {
            return true;
        }
        let items = items
            .into_iter()
            .map(|(urls, file)| openmodelica_download::Item { urls, file })
            .collect();
        let (ok, messages) = openmodelica_download::download(items, self.env.max_parallel.max(1));
        for m in messages {
            self.note("runtimeError", vec![m.text()], None);
        }
        ok
    }

    fn unzip(&mut self, zip: &str, path: &str, dest: &str) {
        if let Err(e) = openmodelica_zip::unzip_path(zip, path, dest) {
            self.note("runtimeError", vec![e], None);
        }
    }

    pub fn update_index(&mut self) -> bool {
        let _ = fs::create_dir_all(&self.user_libraries());
        let index = self.index_path();
        let url = self.env.index_url.clone().unwrap_or_else(|| INDEX_URL.to_owned());
        if self.download(vec![(vec![url.clone()], index.clone())]) {
            self.note("NOTIFY_PKG_INDEX_DOWNLOAD", vec![url], Some(index));
            true
        } else {
            self.note("ERROR_PKG_INDEX_FAILED_DOWNLOAD", vec![url, index], None);
            false
        }
    }

    /// The index file, downloaded if it does not exist yet and `download` is
    /// set; None if the index cannot be used because the user's library
    /// directory is not in the MODELICAPATH.
    pub fn usable_index_file(&mut self, print_error: bool, download: bool) -> Option<String> {
        let user = self.user_libraries();
        let mps = self.modelica_path(&self.env.modelica_path);
        if !mps.iter().any(|mp| *mp == user || *mp == user[..user.len() - 1]) {
            if print_error {
                self.note(
                    "ERROR_PKG_INDEX_NOT_ON_PATH",
                    vec![self.env.modelica_path.clone(), user],
                    None,
                );
            }
            return None;
        }
        let index = self.index_path();
        (fs::is_file(&index) || download && self.update_index()).then_some(index)
    }

    pub fn index(&mut self, print_error: bool) -> Option<Arc<Index>> {
        let file = self.usable_index_file(print_error, true)?;
        let index = scan::index_file(&file);
        if index.is_none() {
            self.note("ERROR_PKG_INDEX_NOT_PARSED", vec![file.clone()], Some(file));
        }
        index
    }

    pub fn installed(&self, metadata: bool) -> Vec<Installed> {
        scan::libraries(&self.modelica_path(&self.env.modelica_path), metadata)
    }

    /// The versions of the index that can be used for `version` of `name`,
    /// best first, development branches last.
    pub fn versions(&mut self, name: &str, version: &str, print_error: bool) -> Vec<String> {
        let index = self.index(print_error);
        let problem = Problem {
            index,
            requirements: vec![Requirement {
                name: name.to_owned(),
                versions: vec![version.to_owned()],
                ..Default::default()
            }],
            install: true,
            versions: true,
            ..Default::default()
        };
        crate::resolve(&problem).versions
    }

    fn index_entry<'i>(index: &'i Option<Arc<Index>>, name: &str, version: &str) -> Option<&'i Value> {
        index
            .as_ref()?
            .raw
            .get("libs")?
            .get(name)?
            .get("versions")?
            .get(version)
    }

    /// The index entry of an installed version, if it is still built from
    /// the same sources; its prebuilt wasm modules are only good then.
    fn installed_index_entry(index: &Option<Arc<Index>>, name: &str, version: &str, sha_or_zip: &str) -> Value {
        match Self::index_entry(index, name, version) {
            Some(o)
                if !sha_or_zip.is_empty()
                    && (sha_or_zipfile(o).as_deref() == Some(sha_or_zip)
                        || str_of(o, "zipfile").is_some_and(|z| basename(z) == sha_or_zip)) =>
            {
                o.clone()
            }
            _ => json!({}),
        }
    }

    /// The prebuilt wasm modules of a package version: the library's own
    /// bundle, then the system libraries it needs, under the generation they
    /// were built in.
    fn wasm_zips(&mut self, index: &Option<Arc<Index>>, version: &Value, abi: i64) -> Vec<WasmZip> {
        if abi <= 0 {
            return Vec::new();
        }
        let Some(obj) = version.get("wasm").and_then(|w| w.get(abi.to_string())) else {
            return Vec::new();
        };
        let (Some(generation), Some(zipfile)) = (obj.get("generation").and_then(Value::as_i64), str_of(obj, "zipfile"))
        else {
            return Vec::new();
        };
        let mut zips = vec![WasmZip {
            url: zipfile.to_owned(),
            dir: format!("omc-{generation}"),
        }];
        let system = index
            .as_ref()
            .and_then(|i| i.raw.get("systemLibraries").cloned())
            .unwrap_or(json!({}));
        for name in obj
            .get("systemLibraries")
            .and_then(Value::as_array)
            .into_iter()
            .flatten()
        {
            let Some(name) = name.as_str() else { continue };
            match system
                .get(name)
                .and_then(|s| s.get("wasm"))
                .and_then(|w| w.get(abi.to_string()))
            {
                Some(z) if str_of(z, "zipfile").is_some() => zips.push(WasmZip {
                    url: str_of(z, "zipfile").unwrap_or_default().to_owned(),
                    dir: format!("omc-{generation}/{name}"),
                }),
                _ => self.note(
                    "compilerWarning",
                    vec![format!(
                        "The package index has no wasm system library {name} for ABI {abi}."
                    )],
                    None,
                ),
            }
        }
        zips
    }

    fn wasm_unpacked(dest: &str, zip: &WasmZip) -> bool {
        let marker = format!("{dest}/Resources/Library/wasm32-wasip1/{}/{WASM_ZIP_MARKER}", zip.dir);
        fs::read_to_string(&marker).is_ok_and(|s| s == basename(&zip.url))
    }

    /// A new directory named `prefix` and a unique suffix, or None.
    fn temporary_directory(prefix: &str) -> Option<String> {
        let mut n = openmodelica_wasi::realtime_nanos();
        for _ in 0..100 {
            let dir = format!("{prefix}{:06x}", n % 0x100_0000);
            let created = if fs::IN_MEMORY {
                !fs::exists(&dir)
            } else {
                std::fs::create_dir(&dir).is_ok()
            };
            if created {
                return Some(dir);
            }
            n = n.wrapping_add(7919);
        }
        None
    }

    /// Takes the lock directory, unless another omc holds it: renaming a
    /// non-empty directory onto an existing one fails. A lock older than ten
    /// minutes was left by an omc that died and is taken over.
    fn wasm_lock(lock: &str) -> bool {
        let _ = fs::create_dir_all(dirname(lock));
        let Some(tmp) = Self::temporary_directory(&format!("{lock}.")) else {
            return false;
        };
        let _ = fs::write(&format!("{tmp}/owner"), b"");
        let mut locked = fs::rename(&tmp, lock).is_ok();
        if !locked {
            let now = openmodelica_wasi::realtime_nanos() / 1_000_000_000;
            let stale = fs::modified(lock)
                .ok()
                .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
                .is_some_and(|t| now.saturating_sub(t.as_secs()) > 600);
            if stale {
                let _ = fs::remove_dir_all(lock);
                locked = fs::rename(&tmp, lock).is_ok();
            }
        }
        if !locked {
            let _ = fs::remove_dir_all(&tmp);
        }
        locked
    }

    /// Replaces `dir` with the first zip's contents and each other's in a
    /// subdirectory named after it, built beside `dir` and renamed into place.
    fn unpack_wasm_tree(&mut self, dir: &str, zips: &[WasmZip], cache: &str) {
        let _ = fs::create_dir_all(dirname(dir));
        let Some(tmp) = Self::temporary_directory(&format!("{dir}.tmp")) else {
            self.note(
                "runtimeError",
                vec![format!("Failed to create a directory beside {dir}.")],
                None,
            );
            return;
        };
        for (i, z) in zips.iter().enumerate() {
            let sub = if i == 0 {
                tmp.clone()
            } else {
                format!("{tmp}/{}", basename(&z.dir))
            };
            let _ = fs::create_dir_all(&sub);
            self.unzip(&format!("{cache}{}", basename(&z.url)), "", &sub);
            let _ = fs::write(&format!("{sub}/{WASM_ZIP_MARKER}"), basename(&z.url).as_bytes());
        }
        let _ = fs::remove_dir_all(dir);
        if fs::rename(&tmp, dir).is_err() {
            let _ = fs::remove_dir_all(&tmp);
        }
    }

    /// A generation's system libraries go into its tree before it is renamed
    /// into place, so an omc running at the same time never sees it half
    /// written.
    fn unpack_wasm(&mut self, dest: &str, zips: &[WasmZip], cache: &str) {
        let base = format!("{dest}/Resources/Library/wasm32-wasip1/");
        let (generations, mut libs): (Vec<WasmZip>, Vec<WasmZip>) =
            zips.iter().cloned().partition(WasmZip::is_generation);
        for g in generations {
            let (inside, rest): (Vec<WasmZip>, Vec<WasmZip>) = libs.into_iter().partition(|z| dirname(&z.dir) == g.dir);
            let mut tree = vec![g.clone()];
            tree.extend(inside);
            self.unpack_wasm_tree(&format!("{base}{}", g.dir), &tree, cache);
            libs = rest;
        }
        for z in libs {
            self.unpack_wasm_tree(&format!("{base}{}", z.dir), &[z.clone()], cache);
        }
    }

    /// Fetches and unpacks the prebuilt wasm modules of an installed package
    /// that it does not have yet: those of a newer generation, or a rebuild.
    fn install_missing_wasm(&mut self, dest: &str, zips: &[WasmZip], cache: &str) -> bool {
        if zips.iter().all(|z| Self::wasm_unpacked(dest, z)) {
            return false;
        }
        let lock = format!("{dest}/Resources/Library/wasm32-wasip1.lock");
        if !Self::wasm_lock(&lock) {
            return false;
        }
        let mut missing: Vec<WasmZip> = zips.iter().filter(|z| !Self::wasm_unpacked(dest, z)).cloned().collect();
        // The library's own zip unpacks into the generation directory that
        // holds the system libraries' ones, so replacing it replaces them all.
        if missing.iter().any(WasmZip::is_generation) {
            missing = zips.to_vec();
        }
        let _ = fs::create_dir_all(cache);
        let downloads = missing
            .iter()
            .map(|z| format!("{cache}{}", basename(&z.url)))
            .zip(&missing)
            .filter(|(file, _)| !fs::exists(file))
            .map(|(file, z)| (vec![z.url.clone()], file))
            .collect();
        let unpacked = !missing.is_empty() && self.download(downloads);
        if unpacked {
            self.unpack_wasm(dest, &missing, cache);
        }
        let _ = fs::remove_dir_all(&lock);
        unpacked
    }

    /// The URL and the mirrors of an https URL, the mirrors first.
    fn all_urls(url: &str, mirrors: &[String]) -> Vec<String> {
        let mut urls = vec![url.to_owned()];
        if let Some(rest) = url.strip_prefix("https://") {
            for mirror in mirrors {
                let sep = if mirror.ends_with('/') { "" } else { "/" };
                urls.insert(0, format!("{mirror}{sep}{rest}"));
            }
        }
        urls
    }

    /// The chosen versions of `pkg` and the libraries it uses, and which of
    /// them are to be installed: the missing ones and the ones whose sources
    /// changed.
    fn packages(&mut self, index: &Option<Arc<Index>>, pkg: &str, version: &str, exact: bool) -> (bool, Vec<Package>) {
        let problem = Problem {
            index: index.clone(),
            installed: self.installed(true),
            requirements: vec![Requirement {
                name: pkg.to_owned(),
                versions: vec![version.to_owned()],
                exact,
                origin: "installPackage".to_owned(),
                ..Default::default()
            }],
            install: true,
            exact_uses: exact,
            ..Default::default()
        };
        let solution = crate::resolve(&problem);
        if !solution.ok {
            let file = self.index_path();
            self.note(
                "ERROR_PKG_CONFLICT",
                vec![pkg.to_owned(), version.to_owned(), solution.error.unwrap_or_default()],
                Some(file),
            );
            return (false, Vec::new());
        }
        let mut success = true;
        for m in solution
            .messages
            .iter()
            .filter(|m| m.kind == crate::MessageKind::Missing)
        {
            let compatible = self.versions(&m.name, &m.version, false);
            let file = Some(self.index_path());
            if m.name == pkg && exact && !compatible.is_empty() {
                self.note(
                    "ERROR_PKG_NOT_EXACT_MATCH",
                    vec![m.name.clone(), m.version.clone(), compatible.join(", ")],
                    file,
                );
            } else {
                let all = self.versions(&m.name, "", false).join("\n");
                self.note(
                    "ERROR_PKG_NOT_FOUND_VERSION",
                    vec![m.name.clone(), m.version.clone(), all],
                    file,
                );
            }
            success = false;
        }
        let mut packages = Vec::new();
        for s in solution.selected.iter().rev() {
            match Self::package(index, s) {
                Some(p) => packages.push(p),
                None => return (false, Vec::new()),
            }
        }
        (success, packages)
    }

    fn package(index: &Option<Arc<Index>>, s: &Selected) -> Option<Package> {
        let version = legacy::normalize(&s.version);
        let entry = Self::index_entry(index, &s.name, &s.version).cloned();
        if let Some(path) = s.path.as_ref().filter(|_| s.installed) {
            let meta = read_json(&format!("{path}/{METADATA}"));
            let zipfile = meta
                .as_ref()
                .and_then(|m| str_of(m, "zipfile"))
                .unwrap_or_default()
                .to_owned();
            let sha = meta
                .as_ref()
                .and_then(|m| str_of(m, "sha"))
                .unwrap_or_default()
                .to_owned();
            // Metadata written from an index without shas only knows its zipfile.
            let same = match &entry {
                None => true,
                Some(e) if !sha.is_empty() => sha_or_zipfile(e).as_deref() == Some(sha.as_str()),
                Some(e) => {
                    zipfile.is_empty() || str_of(e, "zipfile").is_some_and(|z| basename(z) == basename(&zipfile))
                }
            };
            if same {
                let key = if sha.is_empty() { zipfile.clone() } else { sha.clone() };
                return Some(Package {
                    needs_install: false,
                    name: s.name.clone(),
                    json: Self::installed_index_entry(index, &s.name, &version, &key),
                    version,
                    zipfile,
                    path: path.clone(),
                    sha,
                    single_file_copy_all: false,
                });
            }
        }
        let entry = entry?;
        Some(Package {
            needs_install: true,
            name: s.name.clone(),
            version,
            zipfile: str_of(&entry, "zipfile").unwrap_or_default().to_owned(),
            path: str_of(&entry, "path").unwrap_or_default().to_owned(),
            sha: sha_or_zipfile(&entry).unwrap_or_default(),
            single_file_copy_all: entry
                .get("singleFileStructureCopyAllFiles")
                .and_then(Value::as_bool)
                .unwrap_or(false),
            json: entry,
        })
    }

    /// Installs `pkg` and the libraries it uses; with `skip_download`, only
    /// from files that are already in the caches. Returns the libraries that
    /// prebuilt wasm modules were unpacked into.
    pub fn install_package(
        &mut self,
        pkg: &str,
        version: &str,
        exact: bool,
        skip_download: bool,
        abi: i64,
    ) -> (bool, Vec<String>) {
        let index = self.index(true);
        let (success, packages) = self.packages(&index, pkg, version, exact);
        let cache = self.cache_path();
        let installation_cache = self.installation_cache_path();
        let mut wasm_dirs = Vec::new();
        for p in packages.iter().filter(|p| p.name == pkg && !p.needs_install) {
            if version == p.version {
                self.note(
                    "NOTIFY_PKG_ALREADY_INSTALLED",
                    vec![pkg.to_owned(), p.version.clone()],
                    Some(p.path.clone()),
                );
            } else {
                self.note(
                    "NOTIFY_PKG_NO_INSTALL",
                    vec![pkg.to_owned(), version.to_owned(), p.version.clone()],
                    Some(p.path.clone()),
                );
            }
        }
        if !skip_download {
            for p in packages.iter().filter(|p| !p.needs_install) {
                let zips = self.wasm_zips(&index, &p.json, abi);
                if self.install_missing_wasm(&p.path, &zips, &cache) {
                    wasm_dirs.push(p.path.clone());
                }
            }
        }
        let to_install: Vec<(&Package, Vec<WasmZip>)> = packages
            .iter()
            .filter(|p| p.needs_install)
            .map(|p| (p, self.wasm_zips(&index, &p.json, abi)))
            .collect();
        if !to_install.is_empty() {
            let _ = fs::create_dir_all(&cache);
        }
        let cached = |zipfile: &str| -> String {
            let in_installation = format!("{installation_cache}{}", basename(zipfile));
            if fs::exists(&in_installation) {
                in_installation
            } else {
                format!("{cache}{}", basename(zipfile))
            }
        };
        if !skip_download {
            let mirrors: Vec<String> = index
                .as_ref()
                .and_then(|i| i.raw.get("mirrors").and_then(Value::as_array).cloned())
                .unwrap_or_default()
                .iter()
                .filter_map(|m| m.as_str().map(str::to_owned))
                .collect();
            let mut items: Vec<(Vec<String>, String)> = Vec::new();
            for (_, zips) in &to_install {
                for z in zips {
                    items.push((vec![z.url.clone()], format!("{cache}{}", basename(&z.url))));
                }
            }
            for (p, _) in &to_install {
                items.push((Self::all_urls(&p.zipfile, &mirrors), cached(&p.zipfile)));
            }
            let mut unique: Vec<(Vec<String>, String)> = Vec::new();
            for item in items {
                if !unique.contains(&item) && !fs::exists(&item.1) {
                    unique.push(item);
                }
            }
            if !self.download(unique) {
                return (false, Vec::new());
            }
        }
        for (p, zips) in to_install {
            let dest = format!("{}{} {}", self.user_libraries(), p.name, p.version);
            let package_mo = format!("{dest}/package.mo");
            let info = format!("{dest}/{METADATA}");
            let old_sha = read_json(&info).and_then(|m| sha_or_zipfile(&m)).unwrap_or_default();
            let _ = fs::remove_dir_all(&dest);
            let _ = fs::create_dir_all(&dest);
            let zip = cached(&p.zipfile);
            if p.path.ends_with(".mo") {
                if p.single_file_copy_all {
                    // Not a whole directory: also take the Resources next to the file.
                    let dir = dirname(&p.path);
                    self.unzip(&zip, if dir == "." { "" } else { dir }, &dest);
                    let expected = format!("{dest}/{}", basename(&p.path));
                    if fs::rename(&expected, &package_mo).is_err() {
                        self.note("ERROR_PKG_INSTALL_NO_PACKAGE_MO", vec![zip, expected], None);
                        return (false, Vec::new());
                    }
                } else {
                    self.unzip(&zip, &p.path, &package_mo);
                }
            } else {
                self.unzip(&zip, &p.path, &dest);
            }
            if !fs::is_file(&package_mo) {
                self.note("ERROR_PKG_INSTALL_NO_PACKAGE_MO", vec![zip, package_mo], None);
                let _ = fs::remove_dir_all(&dest);
                return (false, Vec::new());
            }
            let zips: Vec<WasmZip> = zips
                .into_iter()
                .filter(|z| fs::exists(&format!("{cache}{}", basename(&z.url))))
                .collect();
            self.unpack_wasm(&dest, &zips, &cache);
            if !zips.is_empty() {
                wasm_dirs.push(dest.clone());
            }
            if old_sha.is_empty() {
                self.note("NOTIFY_PKG_INSTALL_DONE", vec![p.sha.clone()], Some(package_mo));
            } else {
                self.note(
                    "NOTIFY_PKG_UPGRADE_DONE",
                    vec![p.sha.clone(), old_sha],
                    Some(package_mo),
                );
            }
            let _ = fs::write(&info, format!("{}\n", p.json).as_bytes());
        }
        (success, wasm_dirs)
    }

    /// Installs the libraries cached in the installation if the user's
    /// library directory is empty, to allow bundling libraries with omc.
    pub fn install_cached(&mut self) {
        let user = self.user_libraries();
        let has_libraries = fs::read_dir(&user).is_ok_and(|entries| {
            entries
                .iter()
                .any(|e| e.is_dir || fs::is_dir(&format!("{user}{}", e.name)))
        });
        // Also when running e.g. rtest, where the path might not be right.
        if has_libraries || self.env.home.is_empty() || self.env.home == "/" {
            return;
        }
        let file = format!("{}index.json", self.installation_cache_path());
        if !fs::is_file(&file) {
            return;
        }
        let Some(index) = read_json(&file) else {
            self.note("ERROR_PKG_INDEX_NOT_PARSED", vec![file.clone()], Some(file));
            return;
        };
        let Some(libs) = index.get("libs").and_then(Value::as_object) else {
            return;
        };
        if !libs.is_empty() {
            self.note(
                "NOTIFY_INITIALIZING_USER_LIBRARIES",
                vec![user.clone()],
                Some(file.clone()),
            );
        }
        if !fs::is_file(&self.index_path()) {
            let _ = fs::create_dir_all(&user);
            let _ = fs::copy(&file, &self.index_path());
        }
        for (lib, obj) in libs {
            for version in obj
                .get("versions")
                .and_then(Value::as_object)
                .into_iter()
                .flat_map(|v| v.keys())
            {
                self.install_package(lib, version, true, true, 0);
            }
        }
        self.update_index();
    }

    /// The libraries in the MODELICAPATH, by name, each with its versions in
    /// the order of `SemanticVersion.compare`.
    pub fn installed_versions(&self) -> std::collections::BTreeMap<String, Vec<String>> {
        let mut map: std::collections::BTreeMap<String, Vec<String>> = Default::default();
        for lib in self.installed(false) {
            map.entry(lib.name).or_default().push(lib.version);
        }
        for versions in map.values_mut() {
            versions.sort_by(|a, b| {
                legacy::compare(&legacy::parse(a, false), &legacy::parse(b, false), true, true).cmp(&0)
            });
        }
        map
    }

    /// Upgrades each installed library, also after one fails.
    pub fn upgrade(&mut self, newest: bool, abi: i64) -> bool {
        let mut success = true;
        for (pkg, versions) in self.installed_versions() {
            for version in versions {
                success &= self
                    .install_package(&pkg, &legacy::normalize(&version), true, false, abi)
                    .0;
            }
            if newest {
                success &= self.install_package(&pkg, "", false, false, abi).0;
            }
        }
        success
    }

    /// Fetches the prebuilt wasm modules the index has for loaded libraries
    /// installed without them. `files` are the files of the loaded classes.
    pub fn missing_wasm_of_loaded(&mut self, files: &[String], abi: i64) -> Vec<String> {
        if abi <= 0 {
            return Vec::new();
        }
        let dirs: Vec<&str> = files
            .iter()
            .map(|f| dirname(f))
            .filter(|d| fs::is_file(&format!("{d}/{METADATA}")))
            .collect();
        if dirs.is_empty() {
            return Vec::new();
        }
        let mut index = self.index(false);
        // An index from before any wasm modules were built.
        let old = index.as_ref().is_none_or(|i| i.raw.get("systemLibraries").is_none());
        if old && !self.env.testsuite && self.update_index() {
            index = self.index(false);
        }
        let cache = self.cache_path();
        let mut wasm_dirs = Vec::new();
        for dir in dirs {
            let Some(installed) = read_json(&format!("{dir}/{METADATA}")) else {
                continue;
            };
            let pkg = basename(dir)
                .split(' ')
                .find(|w| !w.is_empty())
                .unwrap_or_default()
                .to_owned();
            let (Some(version), Some(key)) = (str_of(&installed, "version"), sha_or_zipfile(&installed)) else {
                continue;
            };
            let entry = Self::installed_index_entry(&index, &pkg, &legacy::normalize(version), &key);
            let zips = self.wasm_zips(&index, &entry, abi);
            let has_wasm = Self::index_entry(&index, &pkg, version)
                .and_then(|e| e.get("wasm"))
                .is_some_and(|w| w.get(abi.to_string()).is_some());
            if zips.is_empty() && has_wasm {
                self.note(
                    "compilerWarning",
                    vec![format!(
                        "{pkg} {version} has no prebuilt wasm libraries. Update it with upgradeInstalledPackages()."
                    )],
                    None,
                );
            }
            if self.install_missing_wasm(dir, &zips, &cache) {
                wasm_dirs.push(dir.to_owned());
            }
        }
        wasm_dirs
    }

    fn unpack_toolchain_part(&mut self, obj: &Value, dir: &str, marker: &str) -> bool {
        if fs::is_file(&format!("{dir}{marker}")) {
            return true;
        }
        let Some(url) = str_of(obj, "zipfile") else {
            return false;
        };
        let cache = self.cache_path();
        let zip = format!("{cache}{}", basename(url));
        let _ = fs::create_dir_all(&cache);
        let ok = fs::exists(&zip) || self.download(vec![(vec![url.to_owned()], zip.clone())]);
        if ok {
            let _ = fs::create_dir_all(dir);
            self.unzip(&zip, "", dir);
        }
        ok
    }

    /// Installs the index's wasm sysroot (with libc++ for `cxx`) and returns
    /// its path, or "" if there is none.
    pub fn wasm_toolchain(&mut self, cxx: bool) -> String {
        let index = self.index(true);
        let toolchain = index.as_ref().and_then(|i| i.raw.get("wasmToolchain").cloned());
        let Some((obj, generation)) =
            toolchain.and_then(|t| t.get("generation").and_then(Value::as_i64).map(|g| (t.clone(), g)))
        else {
            self.note(
                "compilerError",
                vec![
                    "The package index has no wasm toolchain; updatePackageIndex() may fetch a newer index.".to_owned(),
                ],
                None,
            );
            return String::new();
        };
        let dir = format!("{}/.openmodelica/wasm32-wasip1/omc-{generation}/sysroot", self.env.home);
        if !self.unpack_toolchain_part(&obj, &dir, "/lib/wasm32-wasip1/libc.so") {
            return String::new();
        }
        if cxx {
            let Some(cxx) = obj.get("cxx") else {
                self.note(
                    "compilerError",
                    vec!["The package index has no libc++ for its wasm toolchain.".to_owned()],
                    None,
                );
                return String::new();
            };
            if !self.unpack_toolchain_part(cxx, &dir, "/lib/wasm32-wasip1/libc++.so") {
                return String::new();
            }
        }
        dir
    }

    fn index_versions(&mut self, id: &str, print_error: bool) -> Option<serde_json::Map<String, Value>> {
        self.index(print_error)?
            .raw
            .get("libs")?
            .get(id)?
            .get("versions")?
            .as_object()
            .cloned()
    }

    /// The versions of `id` that can convert from `version`.
    pub fn conversions_from(&mut self, id: &str, version: &str, print_error: bool) -> Vec<String> {
        let wanted = legacy::parse(version, true);
        let mut result = Vec::new();
        for (v, entry) in self.index_versions(id, print_error).unwrap_or_default() {
            for from in entry
                .get("convertFromVersion")
                .and_then(Value::as_array)
                .into_iter()
                .flatten()
            {
                if from
                    .as_str()
                    .is_some_and(|f| legacy::compare(&wanted, &legacy::parse(f, true), true, false) == 0)
                {
                    result.insert(0, v.clone());
                }
            }
        }
        result
    }

    /// The versions that `version` of `id` can convert from.
    pub fn conversions_to(&mut self, id: &str, version: &str, print_error: bool) -> Vec<String> {
        let wanted = legacy::parse(version, true);
        for (v, entry) in self.index_versions(id, print_error).unwrap_or_default() {
            if legacy::compare(&wanted, &legacy::parse(&v, true), true, false) == 0 {
                return entry
                    .get("convertFromVersion")
                    .and_then(Value::as_array)
                    .into_iter()
                    .flatten()
                    .filter_map(|s| s.as_str().map(str::to_owned))
                    .collect();
            }
        }
        Vec::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn mirrors_come_first() {
        let urls = Manager::all_urls(
            "https://github.com/a/b.zip",
            &["https://m1/".into(), "https://m2".into()],
        );
        assert_eq!(
            urls,
            [
                "https://m2/github.com/a/b.zip",
                "https://m1/github.com/a/b.zip",
                "https://github.com/a/b.zip"
            ]
        );
        assert_eq!(
            Manager::all_urls("file:///x.zip", &["https://m1/".into()]),
            ["file:///x.zip"]
        );
    }

    #[test]
    fn dirname_as_omc() {
        assert_eq!(dirname("A.mo"), ".");
        assert_eq!(dirname("dir/A.mo"), "dir");
        assert_eq!(basename("/a/b/c.zip"), "c.zip");
    }
}
