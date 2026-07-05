//! No-engine stub for the function-evaluation half of the wasm-jit target,
//! selected when the crate is built without the `jit` feature. The crate can
//! still *emit* wasm modules, but cannot execute them in-process, so the entry
//! point reports the engine as not built in (neither wasmtime nor wasmer is
//! linked in this configuration).

use std::sync::Arc;

use anyhow::{Result, bail};

use metamodelica::List;
use openmodelica_frontend_types::Values;

pub(super) fn load_and_execute(
    _file_name: &str,
    _name: &str,
    _args: &Arc<List<Arc<Values::Value>>>,
) -> Result<Arc<Values::Value>> {
    bail!("CodegenWasmJit: the wasm JIT engine is not built in (enable the `jit` feature)")
}
