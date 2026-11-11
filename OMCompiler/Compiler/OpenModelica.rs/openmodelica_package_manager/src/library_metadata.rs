//! Metadata of libraries that the package manager did not install, read by
//! omc from their top-level file: the version, the uses, the versions they
//! convert from without changes and the versions they have conversion
//! scripts from. Kept in memory and in the user's cache directory,
//! keyed by the path and checked against a hash of the content, so that each
//! file is parsed once per change.

use std::collections::{BTreeMap, HashMap};
use std::sync::Mutex;
use std::sync::atomic::{AtomicBool, Ordering};

use openmodelica_wasi::fs;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Default, Debug, PartialEq, Eq)]
#[serde(default)]
pub struct LibraryMetadata {
    pub version: String,
    pub uses: BTreeMap<String, String>,
    pub provides: Vec<String>,
    /// The versions it has conversion scripts from.
    pub converts: Vec<String>,
}

/// None for a file omc could not read the metadata from.
type Known = Option<LibraryMetadata>;

/// Entries of another format are read again.
const FORMAT: u32 = 1;

#[derive(Serialize, Deserialize)]
struct Entry {
    #[serde(default)]
    format: u32,
    path: String,
    hash: u64,
    metadata: Known,
}

static MEMORY: Mutex<Option<HashMap<String, (u64, Known)>>> = Mutex::new(None);
static PRUNED: AtomicBool = AtomicBool::new(false);

/// FNV-1a: the same in every omc build.
fn fnv(bytes: &[u8]) -> u64 {
    bytes.iter().fold(0xcbf2_9ce4_8422_2325_u64, |h, &b| {
        (h ^ b as u64).wrapping_mul(0x0100_0000_01b3)
    })
}

fn file_name(path: &str) -> String {
    format!("{:016x}.json", fnv(path.as_bytes()))
}

fn content_hash(path: &str) -> Option<u64> {
    fs::with_bytes(path, fnv).ok()
}

pub(crate) struct Cache {
    dir: Option<String>,
}

impl Cache {
    /// Without a home directory (as in the testsuite), only in memory, unless
    /// the store keeps a tree across sessions (the web omc).
    pub fn new(home: &str) -> Cache {
        let dir = if !home.is_empty() && home != "/" {
            Some(format!("{home}/.openmodelica/cache/library-metadata/"))
        } else {
            openmodelica_wasi::persistent_root().map(|root| format!("{root}/cache/library-metadata/"))
        };
        Cache { dir }
    }

    /// The metadata of a file as it is now, if they are known; a file that
    /// cannot be read has none.
    pub fn get(&self, path: &str) -> Option<Known> {
        let Some(hash) = content_hash(path) else {
            return Some(None);
        };
        let mut memory = MEMORY.lock().unwrap_or_else(|e| e.into_inner());
        let memory = memory.get_or_insert_with(HashMap::new);
        if let Some((h, known)) = memory.get(path)
            && *h == hash
        {
            return Some(known.clone());
        }
        let file = format!("{}{}", self.dir.as_ref()?, file_name(path));
        let entry: Entry = serde_json::from_str(&fs::read_to_string(&file).ok()?).ok()?;
        if (entry.format, entry.path.as_str(), entry.hash) != (FORMAT, path, hash) {
            return None;
        }
        memory.insert(path.to_owned(), (hash, entry.metadata.clone()));
        Some(entry.metadata)
    }

    pub fn put(&self, path: &str, metadata: Known) {
        let Some(hash) = content_hash(path) else { return };
        MEMORY
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .get_or_insert_with(HashMap::new)
            .insert(path.to_owned(), (hash, metadata.clone()));
        let Some(dir) = &self.dir else { return };
        let entry = Entry {
            format: FORMAT,
            path: path.to_owned(),
            hash,
            metadata,
        };
        let file = format!("{dir}{}", file_name(path));
        let tmp = format!("{file}.{:x}", openmodelica_wasi::realtime_nanos());
        let written = fs::create_dir_all(dir).is_ok()
            && fs::write(
                &tmp,
                serde_json::to_string(&entry).expect("metadata serializes").as_bytes(),
            )
            .is_ok();
        if !written || fs::rename(&tmp, &file).is_err() {
            let _ = fs::remove_file(&tmp);
        }
        if !PRUNED.swap(true, Ordering::Relaxed) {
            prune(dir);
        }
    }
}

/// Removes the entries of files that are gone.
fn prune(dir: &str) {
    for e in fs::read_dir(dir).unwrap_or_default() {
        let file = format!("{dir}{}", e.name);
        let gone = fs::read_to_string(&file)
            .ok()
            .and_then(|text| serde_json::from_str::<Entry>(&text).ok())
            .is_some_and(|entry| !fs::exists(&entry.path));
        if gone {
            let _ = fs::remove_file(&file);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn kept_until_the_content_changes() {
        let root = std::env::temp_dir().join(format!("pkgmetadata-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&root);
        std::fs::create_dir_all(&root).unwrap();
        let file = root.join("package.mo");
        let path = file.to_str().unwrap();
        std::fs::write(&file, "package A annotation(version=\"1.0.0\"); end A;").unwrap();
        let cache = Cache::new(root.join("home").to_str().unwrap());
        assert_eq!(cache.get(path), None);
        let metadata = LibraryMetadata {
            version: "1.0.0".into(),
            ..Default::default()
        };
        cache.put(path, Some(metadata.clone()));
        assert_eq!(cache.get(path), Some(Some(metadata.clone())));
        MEMORY.lock().unwrap().take();
        assert_eq!(cache.get(path), Some(Some(metadata)), "read from disk");
        std::fs::write(&file, "package A annotation(version=\"2.0.0\"); end A;").unwrap();
        assert_eq!(cache.get(path), None, "same size, other content");
        let gone = root.join("gone.mo");
        std::fs::write(&gone, "").unwrap();
        cache.put(gone.to_str().unwrap(), None);
        std::fs::remove_file(&gone).unwrap();
        prune(cache.dir.as_ref().unwrap());
        let entries = std::fs::read_dir(root.join("home/.openmodelica/cache/library-metadata"))
            .unwrap()
            .count();
        assert_eq!(entries, 1);
        let _ = std::fs::remove_dir_all(&root);
    }
}
