//! Where a library comes from, read out of the package index
//! (`<modelica path>/index.json`) that `updatePackageIndex()` maintains.

use std::collections::HashMap;
use std::path::Path;

use arcstr::ArcStr;
use openmodelica_util::JSON as json;
use openmodelica_util::JSON::JSON;

#[derive(Default)]
struct Release {
    sha: String,
    /// `fullSupport`, `support`, `experimental`, `obsolete` or `noSupport`.
    support: String,
}

#[derive(Default)]
pub struct Sources {
    /// Library name -> (git URL, version -> release).
    libraries: HashMap<String, (String, HashMap<String, Release>)>,
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
            let mut releases = HashMap::new();
            if let Ok(versions) = json::get(entry, arcstr::literal!("versions"))
                && let Ok(found) = json::getKeys(versions.clone())
            {
                for version in &found {
                    if let Ok(v) = json::get(versions.clone(), version.clone()) {
                        releases.insert(
                            version.to_string(),
                            Release {
                                sha: string(&v, "sha").unwrap_or_default(),
                                support: string(&v, "support").unwrap_or_default(),
                            },
                        );
                    }
                }
            }
            libraries.insert(name.to_string(), (git, releases));
        }
        Sources { libraries }
    }

    /// A page a reader can open: the GitHub tree at the exact commit when the
    /// index knows one, the repository otherwise, and failing that whatever the
    /// index calls the source.
    pub fn url(&self, library: &str, version: &str) -> Option<String> {
        let (git, releases) = self.libraries.get(library)?;
        let repository = git.strip_suffix(".git").unwrap_or(git);
        if !repository.starts_with("https://github.com/") {
            return Some(repository.to_string());
        }
        match releases.get(version).map(|r| r.sha.as_str()) {
            Some(sha) if !sha.is_empty() => Some(format!("{repository}/tree/{sha}")),
            _ => Some(repository.to_string()),
        }
    }

    /// How well OpenModelica supports this version, as the index records it.
    pub fn support(&self, library: &str, version: &str) -> Option<&str> {
        let support = self.libraries.get(library)?.1.get(version)?.support.as_str();
        (!support.is_empty()).then_some(support)
    }
}

fn string(object: &metamodelica::Ref<JSON>, key: &str) -> Option<String> {
    match &*json::get(object.clone(), ArcStr::from(key)).ok()? {
        JSON::STRING { r#str } => Some(r#str.to_string()),
        _ => None,
    }
}

/// What OpenModelicaLibraryTesting publishes a report for, read from its
/// `configs/conf.json`. A library is tested at several versions, each under
/// its own name.
#[derive(Default)]
pub struct Tested {
    /// Library name -> (the configured version, the report's name).
    entries: HashMap<String, Vec<(String, String)>>,
}

/// `shared.libname`: the directory and page the report is published under.
fn report_name(library: &str, version: &str, for_tests: Option<&str>, extra: Option<&str>) -> String {
    if let Some(name) = for_tests {
        // An empty `libraryVersionNameForTests` means the library's own name.
        return match name.is_empty() {
            true => library.to_string(),
            false => format!("{library}_{name}"),
        };
    }
    let mut out = String::from(library);
    if version != "default" {
        out.push('_');
        out.push_str(version);
    }
    if let Some(extra) = extra {
        out.push('_');
        out.push_str(extra);
    }
    out
}

/// The test configuration calls the development branch `master`, `trunk`,
/// `main` or `develop` where the package index calls it `master`, so the two
/// match on being branches at all rather than on the name.
fn is_branch(version: &str) -> bool {
    !version.starts_with(|c: char| c.is_ascii_digit())
}

impl Tested {
    pub fn read(path: &Path) -> Tested {
        let Ok(root) = json::parseFile(ArcStr::from(path.to_string_lossy().as_ref())) else {
            return Tested::default();
        };
        let mut entries: HashMap<String, Vec<(String, String)>> = HashMap::new();
        for i in 1..=json::size(root.clone()) {
            let Ok(entry) = json::at(root.clone(), i) else {
                continue;
            };
            let Some(library) = string(&entry, "library") else {
                continue;
            };
            let version = string(&entry, "libraryVersion").unwrap_or_default();
            let version = match version.is_empty() {
                true => String::from("default"),
                false => version,
            };
            let name = report_name(
                &library,
                &version,
                string(&entry, "libraryVersionNameForTests").as_deref(),
                string(&entry, "configExtraName").as_deref(),
            );
            entries.entry(library).or_default().push((version, name));
        }
        Tested { entries }
    }

    /// The report for the version this page documents. The installed version
    /// is not spelled the way the test configuration spells it:
    /// `4.1.0+maint.om` against `4.1.0`, `master` against `trunk`.
    pub fn url(&self, library: &str, version: &str) -> Option<String> {
        let tested = self.entries.get(library)?;
        let release = version.split_once('+').map_or(version, |(v, _)| v);
        let name = tested
            .iter()
            .find(|(v, _)| v == version)
            .or_else(|| tested.iter().find(|(v, _)| v == release))
            .or_else(|| match is_branch(version) {
                true => tested.iter().find(|(v, _)| is_branch(v) && v != "default"),
                false => tested.iter().find(|(v, _)| v == "default"),
            })
            // Failing that, whatever version it was tested at: the report is
            // still this library's.
            .or_else(|| tested.first())
            .map(|(_, name)| name)?;
        Some(format!(
            "https://libraries.openmodelica.org/branches/master/{name}/{name}.html"
        ))
    }
}
