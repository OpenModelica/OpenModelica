//! `rt_uri_to_filename` for the runtimes with no host to ask: C's
//! `OpenModelica_uriToFilename_impl` (`SimulationRuntime/c/util/utility.c`).
//!
//! The wasip1 standalone command has a filesystem; the FMI adapter has none and
//! needs none, since a literal URI is already folded to a path by the time it
//! exports. The `modelica://Pkg/rest` class lookup needs the table
//! `OpenModelica_updateUriMapping` installs, which only a host has.

use alloc::format;
use alloc::string::{String, ToString};

/// The importer's resources directory, C's `data->modelData->resourcesDir`.
struct ResourcesDir(core::cell::UnsafeCell<Option<String>>);
unsafe impl Sync for ResourcesDir {}
static RESOURCES_DIR: ResourcesDir = ResourcesDir(core::cell::UnsafeCell::new(None));

/// Set the resources directory `OpenModelica_fmuLoadResource` resolves against.
/// Called once per instantiate by the FMI adapter; single-threaded by the ABI.
pub fn set_resources_dir(dir: &str) {
    *unsafe { &mut *RESOURCES_DIR.0.get() } = (!dir.is_empty()).then(|| dir.to_string());
}

fn resources_dir() -> Option<&'static str> {
    unsafe { &*RESOURCES_DIR.0.get() }.as_deref()
}

/// The `uri` String handle resolved to a filename, as a fresh String handle.
/// `fmu` resolves relative to the resources directory (`OpenModelica_fmuLoadResource`).
#[unsafe(no_mangle)]
pub extern "C" fn rt_uri_to_filename(uri: u32, fmu: i32) -> u32 {
    let bytes = unsafe { crate::str_bytes(uri) };
    let uri = core::str::from_utf8(bytes).unwrap_or("");
    match resolve(uri, fmu != 0) {
        Ok(path) => crate::new_str_from(&path),
        Err(msg) => {
            // C's `omc_assert` + `MMC_THROW`: report and abort the run.
            openmodelica_sim_meta::driver::note_runtime_error(&msg);
            crate::trap()
        }
    }
}

/// C's `hasDriveLetter`.
fn has_drive_letter(p: &str) -> bool {
    let b = p.as_bytes();
    b.len() > 2 && b[0].is_ascii_alphabetic() && b[1] == b':' && (b[2] == b'/' || b[2] == b'\\')
}

fn starts_ci(s: &str, prefix: &str) -> bool {
    s.len() >= prefix.len() && s[..prefix.len()].eq_ignore_ascii_case(prefix)
}

fn resolve(uri: &str, fmu: bool) -> Result<String, String> {
    if uri.is_empty() {
        return Err("Malformed URI (got an empty string)".to_string());
    }
    let resources = if fmu { resources_dir() } else { None };
    if starts_ci(uri, "modelica://") {
        return Err(format!(
            "Failed to lookup URI (this module carries no class directories) {uri}"
        ));
    }
    if starts_ci(uri, "file://") {
        return Ok(regular_paths(&uri[7..], uri, resources));
    }
    if uri.contains("://") {
        return Err(format!("Unknown URI schema: {uri}"));
    }
    Ok(regular_paths(uri, uri, resources))
}

/// C's `uriToFilenameRegularPaths`, minus the `PATH_MAX` bookkeeping (no fixed
/// buffer here): try the resources directory first, then the path itself.
fn regular_paths(path: &str, orig: &str, resources: Option<&str>) -> String {
    let exists = fs::exists(path);
    if let Some(res) = resources {
        // `res` is `/` when the resources directory is the whole filesystem, so
        // the separator is not doubled onto an absolute path.
        let res = res.trim_end_matches('/');
        let rooted = if has_drive_letter(path) {
            format!("{res}/{}", path.replace(':', "").replace('\\', "/"))
        } else {
            format!("{res}/{}", path.trim_start_matches('/'))
        };
        if !exists || fs::exists(&rooted) {
            return regular_paths(&rooted, orig, None);
        }
    }
    if exists {
        let mut real = fs::realpath(path);
        // A directory keeps a trailing '/' when the original URI had one.
        if orig.ends_with('/') && !real.ends_with('/') && fs::is_dir(path) {
            real.push('/');
        }
        return real;
    }
    if path.starts_with('/') || has_drive_letter(path) {
        return path.to_string();
    }
    match fs::cwd() {
        Some(cwd) => format!("{}/{path}", cwd.trim_end_matches('/')),
        None => path.to_string(),
    }
}

/// The filesystem the standalone command has and the FMI adapter does not.
#[cfg(target_os = "wasi")]
mod fs {
    use alloc::string::{String, ToString};

    pub fn exists(p: &str) -> bool {
        std::fs::metadata(p).is_ok()
    }
    pub fn is_dir(p: &str) -> bool {
        std::fs::metadata(p).map(|m| m.is_dir()).unwrap_or(false)
    }
    pub fn realpath(p: &str) -> String {
        match std::fs::canonicalize(p) {
            Ok(c) => c.to_string_lossy().into_owned(),
            Err(_) => p.to_string(),
        }
    }
    pub fn cwd() -> Option<String> {
        std::env::current_dir().ok().map(|d| d.to_string_lossy().into_owned())
    }
}

#[cfg(not(target_os = "wasi"))]
mod fs {
    use alloc::string::{String, ToString};

    pub fn exists(_p: &str) -> bool {
        false
    }
    pub fn is_dir(_p: &str) -> bool {
        false
    }
    pub fn realpath(p: &str) -> String {
        p.to_string()
    }
    pub fn cwd() -> Option<String> {
        None
    }
}
