//! wasmtime's default reservation stands: 4 GiB per 32-bit memory plus 2 GiB for
//! growth, which a `ulimit -v` counts and a session needs twice over. Sizing it
//! to the limit instead would cost the simulations their reservation, and the
//! reservation is a tunable a precompiled artifact is validated against
//! (`sim_runtime_wasmtime::aot_cache_key`) -- a process that picked its own value
//! could not use what any other one compiled.

const MIB: u64 = 1 << 20;
const GROWTH_CAP: u64 = 2048 * MIB;

/// A run that sets `OMC_WASM_MEMORY_RESERVATION_MB` compiles its own artifacts.
pub fn tune_memory(cfg: &mut wasmtime::Config) {
    let Some(mb) = std::env::var("OMC_WASM_MEMORY_RESERVATION_MB")
        .ok()
        .and_then(|s| s.trim().parse::<u64>().ok())
    else {
        return;
    };
    cfg.memory_reservation(mb * MIB);
    cfg.memory_reservation_for_growth((mb * MIB).min(GROWTH_CAP));
}
