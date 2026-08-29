//! `libSimulationRuntimeRust`: the simulation runtime behind `--simCodeTarget=C+Rust`.
//!
//! The C code generator's output is unchanged; this library provides the runtime
//! half of its ABI. Simulation itself is the same Rust the `wasm-jit` target runs:
//! [`openmodelica_sim_meta::driver`] over [`openmodelica_solvers`], reached through
//! a [`SimEngine`](openmodelica_sim_meta::driver::SimEngine) that calls the model
//! through `data->callback` (src/engine.rs).

// The `omc_assert_*` entry points the generated code names are printf-style
// variadics; only a `c_variadic` definition can carry their arguments to
// `vsnprintf` with C's own formatting.
#![feature(c_variadic)]
#![allow(non_snake_case)]

pub mod abi;
mod data;
mod engine;
mod info_json;
mod meta;
mod mixed;
mod model_data;
mod operators;
mod run;
mod nls;
mod stateset;
mod support;
mod systems;

/// C's `throwStreamPrint`, which is what an `assertStreamPrint` in the runtime
/// reaches: report on `OMC_LOG_ASSERT` and leave through `threadData`'s jump
/// buffer for the error stage in progress.
pub(crate) fn throw(threadData: *mut abi::threadData_t, msg: &str) -> ! {
    support::throw_stream(threadData, msg)
}
