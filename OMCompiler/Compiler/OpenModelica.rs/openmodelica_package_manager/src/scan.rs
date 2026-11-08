//! The libraries in the MODELICAPATH and the package index file, read as
//! omc's class loader sees them.

use std::hash::{DefaultHasher, Hash, Hasher};
use std::sync::{Arc, Mutex};
use std::time::UNIX_EPOCH;

use openmodelica_wasi::fs;
use serde_json::Value;

use crate::version::{Version, compare};
use crate::{Index, Installed, string, string_map};

/// The libraries in the MODELICAPATH: directories (also through symbolic
/// links) with a `package.mo` and `.mo` files other than `package.mo`, named
/// `Name` or `Name version`. The files and then the directories are taken
/// from the last entry to the first, a later one replacing an equal version,
/// so a directory in the first entry wins. With `metadata`, the uses and
/// support level come from the package manager metadata.
pub(crate) fn libraries(modelica_path: &[String], metadata: bool) -> Vec<Installed> {
    let mut found: Vec<(Installed, Version)> = Vec::new();
    let entries: Vec<Vec<(String, bool)>> = modelica_path
        .iter()
        .map(|dir| {
            let mut entries: Vec<(String, bool)> = fs::read_dir(dir)
                .unwrap_or_default()
                .into_iter()
                .map(|e| {
                    let is_dir = e.is_dir || fs::is_dir(&format!("{dir}/{}", e.name));
                    (e.name, is_dir)
                })
                .collect();
            entries.sort();
            entries
        })
        .collect();
    for want_dir in [false, true] {
        for (k, dir) in modelica_path.iter().enumerate().rev() {
            for (file, is_dir) in entries[k].iter().filter(|e| e.1 == want_dir) {
                let path = format!("{dir}/{file}");
                let stem = if *is_dir {
                    if !fs::is_file(&format!("{path}/package.mo")) {
                        continue;
                    }
                    file.as_str()
                } else {
                    match file.strip_suffix(".mo") {
                        Some(stem) if file != "package.mo" => stem,
                        _ => continue,
                    }
                };
                let mut words = stem.split(' ').filter(|w| !w.is_empty());
                let Some(name) = words.next() else { continue };
                let version = words.collect::<Vec<_>>().join(" ");
                let key = Version::parse(&version);
                let lib = Installed {
                    name: name.to_owned(),
                    version,
                    path: Some(path),
                    modelica_path_index: Some(k),
                    file: Some(file.clone()),
                    ..Default::default()
                };
                match found
                    .iter()
                    .position(|(f, v)| f.name == name && compare(v, &key, true).is_eq())
                {
                    Some(i) => found[i] = (lib, key),
                    None => found.push((lib, key)),
                }
            }
        }
    }
    found
        .into_iter()
        .map(|(mut lib, _)| {
            if !metadata {
                return lib;
            }
            let path = lib.path.clone().unwrap_or_default();
            let meta = fs::read_to_string(&format!("{path}/openmodelica.metadata.json"))
                .ok()
                .and_then(|text| serde_json::from_str::<Value>(&text).ok());
            lib.uses = meta.as_ref().map(|m| string_map(&m["uses"]));
            lib.support = meta.as_ref().and_then(|m| string(&m["support"]));
            lib
        })
        .collect()
}

static INDEX_FILE: Mutex<Option<(u64, Option<Arc<Index>>)>> = Mutex::new(None);

/// The parsed index file, read again only if its size or modification time
/// changed. None if it cannot be read or parsed.
pub(crate) fn index_file(path: &str) -> Option<Arc<Index>> {
    let mut h = DefaultHasher::new();
    path.hash(&mut h);
    fs::len(path).ok()?.hash(&mut h);
    fs::modified(path)
        .ok()
        .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
        .hash(&mut h);
    let key = h.finish() | 1;
    let mut cache = INDEX_FILE.lock().unwrap_or_else(|e| e.into_inner());
    if let Some((cached, index)) = cache.as_ref()
        && *cached == key
    {
        return index.clone();
    }
    let index = fs::read_to_string(path)
        .ok()
        .and_then(|text| serde_json::from_str::<Index>(&text).ok())
        .map(|mut index| {
            index.key = key;
            Arc::new(index)
        });
    *cache = Some((key, index.clone()));
    index
}
