//! Standalone WASI command-module export (native only).

use super::*;

/// Emit a self-contained `wasm32-wasip1` *command* module for `sim_code`: lower
/// the model to its wasm module, then `wasm-merge` it with the standalone runtime
/// so the merged module's `_start` runs the whole simulation in-wasm and writes
/// `<prefix>_res.mat` over WASI (`wasmtime run <module> --dir .::.`). Native only —
/// `wasm-merge` is an external tool, absent in the omc wasm build.
#[cfg(not(target_arch = "wasm32"))]
pub fn emit_standalone_module(sim_code: &SimCode::SimCode) -> Result<Vec<u8>> {
    let model = build_sim_model(sim_code, false, ExtHost::Wasm, "", "")?;
    merge_standalone(&model.wasm)
}

/// `wasm-merge` the standalone runtime (module name `rt`) with a model module
/// (module name `model`), resolving both directions of the merge contract (see
/// `openmodelica_codegen_wasm_jit_runtime::standalone`) and leaving only the WASI
/// imports. The merge tool is `wasm-merge` on `PATH`, overridable with
/// `OMC_WASM_MERGE`.
#[cfg(not(target_arch = "wasm32"))]
pub(super) fn merge_standalone(model_wasm: &[u8]) -> Result<Vec<u8>> {
    use std::process::Command;
    if RUNTIME_WASIP1().is_empty() {
        return Err("error");
    }
    let merge = std::env::var("OMC_WASM_MERGE").unwrap_or_else(|_| "wasm-merge".to_owned());

    let dir = std::env::temp_dir().join(format!(
        "om-wasm-merge-{}-{:p}",
        std::process::id(),
        model_wasm.as_ptr()
    ));
    std::fs::create_dir_all(&dir).map_err(|_| "CodegenWasmJit: cannot create temp merge dir")?;
    let rt_path = dir.join("runtime.wasm");
    let model_path = dir.join("model.wasm");
    let out_path = dir.join("standalone.wasm");
    std::fs::write(&rt_path, RUNTIME_WASIP1()).map_err(|_| "CodegenWasmJit: cannot write runtime.wasm")?;
    std::fs::write(&model_path, model_wasm).map_err(|_| "CodegenWasmJit: cannot write model.wasm")?;

    // `-all` enables every wasm feature so the model's bulk-memory `memory.init`
    // (the metadata data segment) and the runtime's features pass through unmodified.
    let status = Command::new(&merge)
        .arg(&rt_path)
        .arg("rt")
        .arg(&model_path)
        .arg("model")
        .arg("-o")
        .arg(&out_path)
        .arg("-all")
        .status()
        .map_err(|e| "CodegenWasmJit: cannot run")?;
    if !status.success() {
        return Err("CodegenWasmJit: failed with");
    }
    let bytes = std::fs::read(&out_path).map_err(|_| "CodegenWasmJit: cannot read merged wasm")?;
    let _ = std::fs::remove_dir_all(&dir);
    Ok(bytes)
}
