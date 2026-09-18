//! Where a library comes from, read out of the package index
//! (`<modelica path>/index.json`) that `updatePackageIndex()` maintains.

use std::collections::HashMap;
use std::path::Path;

use arcstr::ArcStr;
use openmodelica_util::JSON as json;
use openmodelica_util::JSON::JSON;

#[derive(Default)]
pub struct Sources {
    /// Library name -> (git URL, version -> commit sha).
    libraries: HashMap<String, (String, HashMap<String, String>)>,
}

impl Sources {
    pub fn read(path: &Path) -> Sources {
        let Ok(root) = json::parseFile(ArcStr::from(path.to_string_lossy().as_ref())) else {
            return Sources::default();
        };
        let Ok(libs) = json::get(root, arcstr::literal!("libs")) else {
            return Sources::default();
        };
        let mut libraries = HashMap::new();
        let Ok(names) = json::getKeys(libs.clone()) else {
            return Sources::default();
        };
        for name in &names {
            let name = name.clone();
            let Ok(entry) = json::get(libs.clone(), name.clone()) else {
                continue;
            };
            let Some(git) = string(&entry, "git") else {
                continue;
            };
            let mut shas = HashMap::new();
            if let Ok(versions) = json::get(entry, arcstr::literal!("versions"))
                && let Ok(found) = json::getKeys(versions.clone())
            {
                for version in &found {
                    if let Ok(v) = json::get(versions.clone(), version.clone())
                        && let Some(sha) = string(&v, "sha")
                    {
                        shas.insert(version.to_string(), sha);
                    }
                }
            }
            libraries.insert(name.to_string(), (git, shas));
        }
        Sources { libraries }
    }

    /// A page a reader can open: the GitHub tree at the exact commit when the
    /// index knows one, the repository otherwise, and failing that whatever the
    /// index calls the source.
    pub fn url(&self, library: &str, version: &str) -> Option<String> {
        let (git, shas) = self.libraries.get(library)?;
        let repository = git.strip_suffix(".git").unwrap_or(git);
        if !repository.starts_with("https://github.com/") {
            return Some(repository.to_string());
        }
        match shas.get(version) {
            Some(sha) => Some(format!("{repository}/tree/{sha}")),
            None => Some(repository.to_string()),
        }
    }
}

fn string(object: &metamodelica::Ref<JSON>, key: &str) -> Option<String> {
    match &*json::get(object.clone(), ArcStr::from(key)).ok()? {
        JSON::STRING { r#str } => Some(r#str.to_string()),
        _ => None,
    }
}
