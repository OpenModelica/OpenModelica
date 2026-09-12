//! In-process ZIP writer (stored + deflate) and the FMU directory packaging.

use super::*;

/// Raw deflate (ZIP method 8), or `None` when the input is not worth compressing.
pub(super) fn deflate(data: &[u8]) -> Option<Vec<u8>> {
    if data.len() < 256 {
        return None;
    }
    Some(miniz_oxide::deflate::compress_to_vec(data, 6))
}

/// Add `path` (a file, or a directory copied whole) under `resources/<path>`,
/// keeping the absolute path so `rt_uri_to_filename` names it again at run time.
pub(super) fn add_resource(entries: &mut Vec<(String, Vec<u8>)>, path: &str) {
    if openmodelica_wasi::fs::is_dir(path) {
        let Ok(dir) = openmodelica_wasi::fs::read_dir(path) else { return };
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
    let name = if drive { path.replace(':', "").replace('\\', "/") } else { path.trim_start_matches('/').to_string() };
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
    let Ok(files) = openmodelica_wasi::fs::read_dir(dir) else { return };
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

/// A ZIP assembled in-process rather than by an external `zip`, deflated unless
/// that would grow the entry.
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

pub(super) fn zip_archive(entries: &[(String, Vec<u8>)]) -> Vec<u8> {
    let mut out = Vec::new();
    let mut central = Vec::new();
    let le16 = |v: u16, o: &mut Vec<u8>| o.extend_from_slice(&v.to_le_bytes());
    let le32 = |v: u32, o: &mut Vec<u8>| o.extend_from_slice(&v.to_le_bytes());
    let mut offsets: Vec<u32> = Vec::new();
    // Deflate once: the central directory must agree with the local headers.
    let stored: Vec<(u16, Vec<u8>)> = entries
        .iter()
        .map(|(_, data)| match deflate(data) {
            Some(z) if z.len() < data.len() => (8, z),
            _ => (0, data.clone()),
        })
        .collect();
    for ((name, data), (method, payload)) in entries.iter().zip(&stored) {
        offsets.push(out.len() as u32);
        let crc = crc32(data);
        let n = name.as_bytes();
        // local file header
        le32(0x0403_4b50, &mut out);
        le16(20, &mut out); // version needed
        le16(0, &mut out); // flags
        le16(*method, &mut out);
        le16(0, &mut out); // mod time
        le16(0x21, &mut out); // mod date (1980-01-01)
        le32(crc, &mut out);
        le32(payload.len() as u32, &mut out); // compressed size
        le32(data.len() as u32, &mut out); // uncompressed size
        le16(n.len() as u16, &mut out);
        le16(0, &mut out); // extra len
        out.extend_from_slice(n);
        out.extend_from_slice(payload);
    }
    let cd_start = out.len() as u32;
    for (((name, data), (method, payload)), off) in entries.iter().zip(&stored).zip(&offsets) {
        let crc = crc32(data);
        let n = name.as_bytes();
        le32(0x0201_4b50, &mut central);
        le16(20, &mut central); // version made by
        le16(20, &mut central); // version needed
        le16(0, &mut central); // flags
        le16(*method, &mut central);
        le16(0, &mut central); // time
        le16(0x21, &mut central); // date
        le32(crc, &mut central);
        le32(payload.len() as u32, &mut central);
        le32(data.len() as u32, &mut central);
        le16(n.len() as u16, &mut central);
        le16(0, &mut central); // extra
        le16(0, &mut central); // comment
        le16(0, &mut central); // disk
        le16(0, &mut central); // internal attrs
        le32(0, &mut central); // external attrs
        le32(*off, &mut central);
        central.extend_from_slice(n);
    }
    let cd_len = central.len() as u32;
    out.extend_from_slice(&central);
    // end of central directory
    le32(0x0605_4b50, &mut out);
    le16(0, &mut out); // disk
    le16(0, &mut out); // cd disk
    le16(entries.len() as u16, &mut out);
    le16(entries.len() as u16, &mut out);
    le32(cd_len, &mut out);
    le32(cd_start, &mut out);
    le16(0, &mut out); // comment len
    out
}

/// `CodegenWasmJit.emitMeFmu` / `emitCsFmu`: build the wasm FMU for `sim_code`
/// and write it to `fmu_path`. Host-free: no `wasm-merge`, no `zip`.
pub fn emitMeFmu(
    sim_code: SimCode::SimCode,
    fmu_path: ArcStr,
    _guid: ArcStr,
    model_description: ArcStr,
    ls_dae_manifest: ArcStr,
    documentation_dir: ArcStr,
    terminals_dir: ArcStr,
    simulation_flags_json: ArcStr,
) -> Result<()> {
    emit_fmu(sim_code, fmu_path, model_description, ls_dae_manifest, documentation_dir, terminals_dir, simulation_flags_json, FMI3_ME_ADAPTER(), "ME")
}
