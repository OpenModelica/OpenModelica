//! No-engine stub for the simulation half of the wasm-jit target, selected when
//! the crate is built without the `jit` feature. Mirrors the public surface the
//! parent `CodegenWasmJit` module uses, reporting the engine as not built in.

use crate::model::SimModel;

const NO_ENGINE: &str =
    "CodegenWasmJit: the wasm JIT engine is not built in (enable the `jit` feature)";

/// No compiled-module type without an engine.
pub type Module = ();

#[allow(dead_code)]
pub struct RunResult {
    pub rows: Vec<f64>,
    pub n_reals: u32,
    pub params: Vec<f64>,
    pub stats: openmodelica_sim_meta::SolveStats,
}

pub fn runtime_module() -> std::result::Result<&'static Module, String> {
    return Err(NO_ENGINE.to_string())
}

pub fn compile_model_module(_wasm: &[u8]) -> std::result::Result<Module, String> {
    return Err(NO_ENGINE.to_string())
}

pub fn start_runtime_compile() {}

pub fn set_alarm(_seconds: Option<u32>) {}

pub fn take_compiled_model(_model: &SimModel) -> std::result::Result<Module, String> {
    return Err(NO_ENGINE.to_string())
}

pub fn prepare_native_externals(_model: &SimModel, _sigs: &[crate::sig::ExtCallSig]) -> std::result::Result<(), String> {
    Ok(())
}

pub fn run(_model: &SimModel, _meta: &openmodelica_sim_meta::SimMeta) -> std::result::Result<RunResult, String> {
    return Err(NO_ENGINE.to_string())
}

/// No engine here, so nothing to precompile.
pub fn precompile_fixed_blobs(_dir: &std::path::Path) -> std::result::Result<Vec<String>, String> {
    Ok(Vec::new())
}
