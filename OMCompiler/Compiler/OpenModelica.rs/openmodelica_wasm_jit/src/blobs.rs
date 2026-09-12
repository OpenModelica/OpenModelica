//! The wasm artifacts omc runs, links into what it exports, and loads a model's
//! external "C" on top of. Shipped as files under `lib/wasm32-wasip1/omc` and read
//! on first use: 30 MB of an omc, identical on every platform, and carried twice
//! over by a macOS universal build. The browser build has no filesystem and embeds
//! them instead. A blob that was not built, or whose file is missing, is an empty
//! slice -- which the callers already read as "cannot".

#![allow(non_snake_case)]

/// In order: `OMC_WASM_BLOB_DIR`, the install tree, then the build directories they
/// came from, so an omc run out of a build tree (which has no install) still works.
/// Resolved per call, not cached: the installation directory is not necessarily
/// known the first time a blob is wanted, and caching the list would then pin the
/// install tree out of it for the life of the process. `Settings` caches the
/// lookup itself, and the bytes are cached per blob by the caller.
#[cfg(not(target_arch = "wasm32"))]
fn load(file: &str) -> &'static [u8] {
    use std::path::PathBuf;
    let mut dirs = Vec::new();
    if let Some(d) = std::env::var_os("OMC_WASM_BLOB_DIR") {
        dirs.push(PathBuf::from(d));
    }
    if let Ok(home) = openmodelica_util::Settings::getInstallationDirectoryPath() {
        dirs.push(PathBuf::from(home.as_str()).join("lib/wasm32-wasip1/omc"));
    }
    dirs.push(PathBuf::from(env!("OUT_DIR")));
    dirs.push(PathBuf::from(env!("OMC_WASI_BLOB_DIR")));
    for dir in dirs {
        if let Ok(bytes) = std::fs::read(dir.join(file)) {
            return Vec::leak(bytes);
        }
    }
    &[]
}

#[cfg(target_arch = "wasm32")]
macro_rules! blob_bytes {
    ($dir:expr, $file:literal) => {
        include_bytes!(concat!($dir, "/", $file))
    };
}

#[cfg(not(target_arch = "wasm32"))]
macro_rules! blob_bytes {
    ($dir:expr, $file:literal) => {{
        static BYTES: std::sync::OnceLock<&'static [u8]> = std::sync::OnceLock::new();
        *BYTES.get_or_init(|| load($file))
    }};
}

macro_rules! blobs {
    ($dir:expr, $($(#[$doc:meta])* $name:ident = $file:literal;)*) => {$(
        $(#[$doc])*
        pub fn $name() -> &'static [u8] {
            blob_bytes!($dir, $file)
        }
    )*};
}

blobs! {env!("OUT_DIR"),
    /// The JIT runtime: `wasm32-unknown-unknown`, no std, the host drives it.
    RUNTIME_WASM = "runtime.wasm";
    /// The standalone `wasm32-wasip1` (std) runtime a self-contained simulation
    /// module links against.
    RUNTIME_WASIP1 = "runtime_wasip1.wasm";
    /// The interactive `wasm32-wasip1` (std) runtime: exports `rt_*`+`memory`+table
    /// like [`RUNTIME_WASM`], but built with std so the sparse solver (`rsparse`)
    /// links in; imports `wasi_snapshot_preview1` (satisfied by `wasi_shim`). Empty
    /// when the wasip1 target was unavailable at build time (host then uses
    /// [`RUNTIME_WASM`]).
    RUNTIME_WASM_INTERACTIVE_WASIP1 = "runtime_wasip1_interactive.wasm";
    /// ModelicaExternalC as a WASI side module with its own memory.
    EXTERNAL_C_WASM = "modelicaexternalc.wasm";
    /// The FMI 3.0 Model Exchange adapter component.
    FMI3_ME_ADAPTER = "fmi3_me_adapter.wasm";
    /// Both interfaces in one component, and what a Co-Simulation FMU carries too:
    /// its imports are a `co-simulation-fmu`'s exactly and its exports a superset,
    /// so it substitutes for one -- cheaper than a fourth adapter blob in every omc.
    /// The SUNDIALS-backed solvers come with it, as imports [`SOLVER_LIBRARIES`]
    /// resolves.
    FMI3_MECS_ADAPTER = "fmi3_mecs_adapter.wasm";
    /// The me_cs adapter as a plain dylink library exporting the FMI 3.0 C API
    /// (`om_fmi3*`), for the artifact form a host links itself: being fixed, it is
    /// compiled once into the on-disk AOT cache instead of into every component.
    FMI3_MECS_CAPI_ADAPTER = "fmi3_mecs_capi_adapter.wasm";
    /// The **fused** artifact runtime: the FMI 3.0 adapter, the in-wasm driver and
    /// the simulation runtime in one non-PIC `wasm32-wasip1` module, with the
    /// SUNDIALS archives linked in (the dylink adapter cannot have them -- see
    /// `build_wasip1_fused_adapter`). Empty when the wasip1 target was unavailable
    /// at build time, in which case the dylink adapter serves the artifact instead.
    FMI3_FUSED_WASIP1 = "fmi3_fused_wasip1.wasm";
    /// `openmodelica_lapack` as a PIC dylink side module, linked into an FMU only
    /// when the model's `external "FORTRAN 77"` calls need it.
    LAPACK_DYLINK = "liblapack.wasm";

    SOLVER_KLU = "solver_klu.wasm";
    SOLVER_KLU_STUB = "solver_klu_stub.wasm";
    SOLVER_SUNDIALS_DRIVER = "solver_sundials_driver.wasm";
    SOLVER_SUNDIALS_DRIVER_STUB = "solver_sundials_driver_stub.wasm";
    SOLVER_KINSOL = "solver_kinsol.wasm";
    SOLVER_KINSOL_STUB = "solver_kinsol_stub.wasm";
    SOLVER_UMFPACK = "solver_umfpack.wasm";
    SOLVER_UMFPACK_STUB = "solver_umfpack_stub.wasm";
    SOLVER_LIS = "solver_lis.wasm";
    SOLVER_LIS_STUB = "solver_lis_stub.wasm";
}

// Produced by openmodelica_wasi_libc's build.rs; its OUT_DIR reaches this one
// through that crate's `links` metadata (see both build.rs).
blobs! {env!("OMC_WASI_BLOB_DIR"),
    /// ModelicaExternalC as a PIC dylink side module.
    EXTERNAL_C_DYLINK = "modelicaexternalc_dylink.wasm";
    /// The dummy `usertab` ModelicaExternalC imports, separate so it can be linked last.
    USERTAB_DYLINK = "usertab_dylink.wasm";
    /// A `-fPIC` wasi-libc `libc.so` dylink module (Debian's is non-PIC).
    LIBC_PIC = "libc_pic.wasm";
    /// The `wasi_snapshot_preview1` -> preview2 reactor adapter.
    WASI_P1_ADAPTER = "wasi_snapshot_preview1.reactor.wasm";
}

/// Whether external "C" in a host-free wasm FMU is supported (all three present).
pub fn external_c_available() -> bool {
    !EXTERNAL_C_DYLINK().is_empty() && !LIBC_PIC().is_empty() && !WASI_P1_ADAPTER().is_empty()
}

/// One solver library an exported FMU can be given, as a PIC dylink side module: the
/// same wasm archives the wasip1 runtimes link statically, re-linked `--shared` and
/// reduced to the entry points [`FMI3_MECS_ADAPTER`] imports from it.
pub struct SolverLibrary {
    /// The dylink library name, and the `om_have_<name>` marker the FMU's runtime
    /// reads to report what it was given.
    pub name: &'static str,
    module: fn() -> &'static [u8],
    stub: fn() -> &'static [u8],
}

impl SolverLibrary {
    /// Linked when the FMU's flags can reach this solver.
    pub fn module(&self) -> &'static [u8] {
        (self.module)()
    }

    /// Linked instead when they cannot: the same entry points, each a trap, and
    /// `om_have_<name>` answering 0 so `simflags::check` rejects the solver first.
    pub fn stub(&self) -> &'static [u8] {
        (self.stub)()
    }
}

/// The solver libraries, `klu` first: it is the shared SUNDIALS core, vectors,
/// matrices and dense/Krylov/nonlinear solvers the others call into, so it is linked
/// whenever any of them is. Every blob is empty when this omc was built without the
/// wasm solver archives.
pub static SOLVER_LIBRARIES: &[SolverLibrary] = &[
    SolverLibrary { name: "klu", module: SOLVER_KLU, stub: SOLVER_KLU_STUB },
    SolverLibrary {
        name: "sundials_driver",
        module: SOLVER_SUNDIALS_DRIVER,
        stub: SOLVER_SUNDIALS_DRIVER_STUB,
    },
    SolverLibrary { name: "kinsol", module: SOLVER_KINSOL, stub: SOLVER_KINSOL_STUB },
    SolverLibrary { name: "umfpack", module: SOLVER_UMFPACK, stub: SOLVER_UMFPACK_STUB },
    SolverLibrary { name: "lis", module: SOLVER_LIS, stub: SOLVER_LIS_STUB },
];

/// Whether an exported wasm FMU can be given the SUNDIALS-backed solvers.
pub fn sundials_dylink_available() -> bool {
    !SOLVER_LIBRARIES[0].module().is_empty()
}
