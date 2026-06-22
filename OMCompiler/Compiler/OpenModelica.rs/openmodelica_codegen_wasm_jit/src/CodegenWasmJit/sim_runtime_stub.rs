//! No-engine stub for the simulation half of the wasm-jit target, selected when
//! the crate is built without the `jit` feature. Mirrors the public surface the
//! parent `CodegenWasmJit` module uses, reporting the engine as not built in.

use anyhow::{Result, bail};

use super::SimModel;

const NO_ENGINE: &str =
    "CodegenWasmJit: the wasm JIT engine is not built in (enable the `jit` feature)";

/// No compiled-module type without an engine.
pub(super) type Module = ();

#[allow(dead_code)]
pub(super) struct RunResult {
    pub(super) rows: Vec<f64>,
    pub(super) n_reals: u32,
    pub(super) params: Vec<f64>,
}

pub(super) fn runtime_module() -> Result<&'static Module> {
    bail!("{NO_ENGINE}")
}

pub(super) fn compile_model_module(_wasm: &[u8]) -> Result<Module> {
    bail!("{NO_ENGINE}")
}

pub(super) fn start_runtime_compile() {}

pub(super) fn take_compiled_model(_model: &SimModel) -> Result<Module> {
    bail!("{NO_ENGINE}")
}

pub(super) fn run(_model: &SimModel) -> Result<RunResult> {
    bail!("{NO_ENGINE}")
}
