//! `libSimulationRuntimeRust`: the simulation runtime behind `--simCodeTarget=C`.
//!
//! The C code generator's output is unchanged; this library provides the runtime
//! half of its ABI. Simulation itself is the same Rust the `wasm-jit` target runs:
//! [`openmodelica_sim_meta::driver`] over [`openmodelica_solvers`], reached through
//! a [`SimEngine`](openmodelica_sim_meta::driver::SimEngine) that calls the model
//! through `data->callback` (src/engine.rs).

#![allow(non_snake_case)]
// Without `standalone` the executable's half is gated out, and what only it
// reached is unused rather than deleted.
#![cfg_attr(not(feature = "standalone"), allow(dead_code))]

pub mod abi;
mod data;
mod datarecon;
mod engine;
mod fmi;
#[cfg(feature = "fmi")]
mod fmi_host;
mod fmi_vrs;
#[cfg(feature = "standalone")]
mod iif;
mod info_json;
mod linearize;
mod meta;
mod mixed;
mod model_data;
mod operators;
mod parmod;
mod optimization;
#[cfg(feature = "standalone")]
mod port;
#[cfg(feature = "standalone")]
mod run;
mod nls;
mod spatial;
mod stateset;
mod sync;
#[cfg(shim_trampolines)]
mod shim_export;
mod support;
mod systems;

/// C's `throwStreamPrint`, which is what an `assertStreamPrint` in the runtime
/// reaches: report on `OMC_LOG_ASSERT` and leave through `threadData`'s jump
/// buffer for the error stage in progress.
pub(crate) fn throw(threadData: *mut abi::threadData_t, msg: &str) -> ! {
    support::throw_stream(threadData, msg)
}
