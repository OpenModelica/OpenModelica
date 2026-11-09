//! The FMU's entries and its directory packaging; `openmodelica_zip` zips them.

use super::*;

/// Add `path` (a file, or a directory copied whole) under `resources/<path>`,
/// keeping the absolute path so `rt_uri_to_filename` names it again at run time.
pub(super) fn add_resource(entries: &mut Vec<(String, Vec<u8>)>, path: &str) {
    if openmodelica_wasi::fs::is_dir(path) {
        let Ok(dir) = openmodelica_wasi::fs::read_dir(path) else {
            return;
        };
        for e in dir {
            add_resource(entries, &format!("{}/{}", path.trim_end_matches('/'), e.name));
        }
        return;
    }
    // A drive letter cannot be a directory name.
    let drive = path.len() > 2
        && path.as_bytes()[0].is_ascii_alphabetic()
        && path.as_bytes()[1] == b':'
        && matches!(path.as_bytes()[2], b'/' | b'\\');
    let name = if drive {
        path.replace(':', "").replace('\\', "/")
    } else {
        path.trim_start_matches('/').to_string()
    };
    if let Ok(bytes) = openmodelica_wasi::fs::read(path) {
        entries.push((format!("resources/{name}"), bytes));
    }
}

/// Ship `dir` as the FMU's `terminalsAndIcons/`: the XML SimCode wrote and the icons
/// the OMGraphics renderer put beside it, as the C export's `fmutmp` subtree is.
/// Ship everything under `dir` as `prefix/<path below dir>`, recursively: the
/// staged `documentation/` (whose images keep the modelica:// URI's own directory
/// structure) and `terminalsAndIcons/`.
pub(super) fn add_directory(entries: &mut Vec<(String, Vec<u8>)>, dir: &str, prefix: &str) {
    if dir.is_empty() {
        return;
    }
    let dir = dir.trim_end_matches('/');
    let Ok(files) = openmodelica_wasi::fs::read_dir(dir) else {
        return;
    };
    for e in files {
        let path = format!("{dir}/{}", e.name);
        let name = format!("{prefix}/{}", e.name);
        if e.is_dir {
            add_directory(entries, &path, &name);
        } else if let Ok(bytes) = openmodelica_wasi::fs::read(&path) {
            entries.push((name, bytes));
        }
    }
}

/// `--fmuDirectory`: the same entries as files under `path`, which then names a
/// directory rather than a zip. A stale export of the same name is removed first,
/// so what is there is what this run wrote.
pub(super) fn write_directory(path: &str, entries: &[(String, Vec<u8>)]) -> Result<()> {
    let root = std::path::Path::new(path);
    if root.is_dir() {
        let _ = std::fs::remove_dir_all(root);
    } else {
        let _ = std::fs::remove_file(root);
    }
    for (name, bytes) in entries {
        let out = root.join(name);
        if let Some(parent) = out.parent()
            && std::fs::create_dir_all(parent).is_err()
        {
            record_error(format!("CodegenWasmJit: cannot create {}", parent.display()));
            return Err("CodegenWasmJit: cannot write the FMU directory");
        }
        if write_output(&out.to_string_lossy(), bytes).is_err() {
            record_error(format!("CodegenWasmJit: cannot write {}", out.display()));
            return Err("CodegenWasmJit: cannot write the FMU directory");
        }
    }
    Ok(())
}

/// `CodegenWasmJit.emitMeFmu` / `emitCsFmu`: build the wasm FMU for `sim_code`
/// and write it to `fmu_path`. Host-free: no `wasm-merge`, no `zip`.
pub fn emitMeFmu(
    sim_code: metamodelica::Ref<SimCode::SimCode>,
    fmu_path: ArcStr,
    _guid: ArcStr,
    model_description: ArcStr,
    ls_dae_manifest: ArcStr,
    documentation_dir: ArcStr,
    terminals_dir: ArcStr,
    simulation_flags_json: ArcStr,
) -> Result<()> {
    emit_fmu(
        sim_code,
        fmu_path,
        model_description,
        ls_dae_manifest,
        documentation_dir,
        terminals_dir,
        simulation_flags_json,
        FMI3_ME_ADAPTER(),
        "ME",
    )
}
