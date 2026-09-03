//! Host-side wasm-jit execution engine for OpenModelica.

// Embedded wasm artifacts built by `build.rs`, used by this crate's engines and
// the codegen crate (standalone/FMU emission).
pub static RUNTIME_WASM: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/runtime.wasm"));
pub static RUNTIME_WASIP1: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/runtime_wasip1.wasm"));
/// The interactive `wasm32-wasip1` (std) runtime: exports `rt_*`+`memory`+table
/// like `RUNTIME_WASM`, but built with std so the sparse solver (`rsparse`) links
/// in; imports `wasi_snapshot_preview1` (satisfied by `wasi_shim`). Empty when the
/// wasip1 target was unavailable at build time (host then uses `RUNTIME_WASM`).
pub static RUNTIME_WASM_INTERACTIVE_WASIP1: &[u8] =
    include_bytes!(concat!(env!("OUT_DIR"), "/runtime_wasip1_interactive.wasm"));
pub static EXTERNAL_C_WASM: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/modelicaexternalc.wasm"));
pub static FMI3_ME_ADAPTER: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/fmi3_me_adapter.wasm"));
/// Both interfaces in one component, and what a Co-Simulation FMU carries too: its
/// imports are a `co-simulation-fmu`'s exactly and its exports a superset, so it
/// substitutes for one — cheaper than a fourth adapter blob in every omc.
/// The SUNDIALS-backed solvers come with it, as imports [`SOLVER_LIBRARIES`] resolves.
pub static FMI3_MECS_ADAPTER: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/fmi3_mecs_adapter.wasm"));

/// One solver library an exported FMU can be given, as a PIC dylink side module: the
/// same wasm archives the wasip1 runtimes link statically, re-linked `--shared` and
/// reduced to the entry points [`FMI3_MECS_ADAPTER`] imports from it.
pub struct SolverLibrary {
    /// The dylink library name, and the `om_have_<name>` marker the FMU's runtime
    /// reads to report what it was given.
    pub name: &'static str,
    /// Linked when the FMU's flags can reach this solver.
    pub module: &'static [u8],
    /// Linked instead when they cannot: the same entry points, each a trap, and
    /// `om_have_<name>` answering 0 so `simflags::check` rejects the solver first.
    pub stub: &'static [u8],
}

macro_rules! solver_library {
    ($name:literal) => {
        SolverLibrary {
            name: $name,
            module: include_bytes!(concat!(env!("OUT_DIR"), "/solver_", $name, ".wasm")),
            stub: include_bytes!(concat!(env!("OUT_DIR"), "/solver_", $name, "_stub.wasm")),
        }
    };
}

/// The solver libraries, `klu` first: it is the shared SUNDIALS core, vectors,
/// matrices and dense/Krylov/nonlinear solvers the others call into, so it is linked
/// whenever any of them is. Every blob is empty when this omc was built without the
/// wasm solver archives.
pub static SOLVER_LIBRARIES: &[SolverLibrary] = &[
    solver_library!("klu"),
    solver_library!("sundials_driver"),
    solver_library!("kinsol"),
    solver_library!("umfpack"),
    solver_library!("lis"),
];

/// Whether an exported wasm FMU can be given the SUNDIALS-backed solvers.
pub fn sundials_dylink_available() -> bool {
    !SOLVER_LIBRARIES[0].module.is_empty()
}

/// The me_cs adapter as a plain dylink library exporting the FMI 3.0 C API
/// (`om_fmi3*`), for the artifact form a host links itself: being fixed, it is
/// compiled once into the on-disk AOT cache instead of into every component.
pub static FMI3_MECS_CAPI_ADAPTER: &[u8] =
    include_bytes!(concat!(env!("OUT_DIR"), "/fmi3_mecs_capi_adapter.wasm"));

/// The **fused** artifact runtime: the FMI 3.0 adapter, the in-wasm driver and the
/// simulation runtime in one non-PIC `wasm32-wasip1` module, with the SUNDIALS
/// archives linked in (the dylink adapter cannot have them — see
/// `build_wasip1_fused_adapter`). Empty when the wasip1 target was unavailable at
/// build time, in which case the dylink adapter serves the artifact instead.
pub static FMI3_FUSED_WASIP1: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/fmi3_fused_wasip1.wasm"));

/// `openmodelica_lapack` as a PIC dylink side module, linked into an FMU only when
/// the model's `external "FORTRAN 77"` calls need it.
pub static LAPACK_DYLINK: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/liblapack.wasm"));

/// Whether the wasip1 runtimes above have the real SUNDIALS/KLU linked in (the
/// build script cross-compiled the archives), so a `-lss=klu` run can be served.
pub const SUNDIALS: bool = cfg!(sundials);

pub mod sig;
pub mod model;
pub mod dylink;

// A wasm trap collapses to the crate's `&'static str` error on the way out of the
// engine, losing the trap kind and the backtrace. The engine parks its message
// here for the caller that gives up on the run to add to the Error buffer.
std::thread_local! {
    static ENGINE_ERROR_DETAIL: std::cell::RefCell<Option<String>> =
        const { std::cell::RefCell::new(None) };
}

pub fn set_engine_error_detail(msg: String) {
    ENGINE_ERROR_DETAIL.with(|e| *e.borrow_mut() = Some(msg));
}

pub fn take_engine_error_detail() -> Option<String> {
    ENGINE_ERROR_DETAIL.with(|e| e.borrow_mut().take())
}

#[cfg(feature = "jit")]
pub mod host;

#[cfg(all(feature = "jit", not(target_arch = "wasm32")))]
mod engine_config;
#[cfg(all(feature = "jit", not(target_arch = "wasm32")))]
pub use engine_config::tune_memory;

/// Split the runtime's `-l` blob (`<file name>\0<content>`) into a [`LinFile`].
pub fn split_lin_blob(bytes: &[u8]) -> Option<openmodelica_sim_meta::linearize::LinFile> {
    let i = bytes.iter().position(|&b| b == 0)?;
    Some(openmodelica_sim_meta::linearize::LinFile {
        name: String::from_utf8_lossy(&bytes[..i]).into_owned(),
        content: String::from_utf8_lossy(&bytes[i + 1..]).into_owned(),
    })
}

// A thin facade over openmodelica_sim_meta::driver; present even in the no-jit
// stub build, which reads its result types.
pub mod sim_driver;
pub mod result_sink;
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
#[path = "sim_runtime_wasmtime.rs"]
pub mod sim_runtime;
#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
#[path = "sim_runtime_wasmer.rs"]
pub mod sim_runtime;
#[cfg(not(feature = "jit"))]
#[path = "sim_runtime_stub.rs"]
pub mod sim_runtime;
#[cfg(feature = "jit")]
#[path = "wasi_shim.rs"]
pub mod wasi_shim;
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
#[path = "dylink_wasmtime.rs"]
pub mod dylink_engine;
