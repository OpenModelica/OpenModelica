//! The wasm artifacts omc runs, links into what it exports, and loads a model's
//! external "C" on top of. Shipped as files under `lib/wasm32-wasip1/omc` and read
//! on first use: 30 MB of an omc, identical on every platform, and carried twice
//! over by a macOS universal build. The browser build has no filesystem and embeds
//! them instead, all but the [`ondemand`] ones. A blob that was not built, or whose
//! file is missing, is an empty slice -- which the callers already read as "cannot".

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

/// Blobs the browser build does not embed; its bundle ships them as files.
#[cfg(target_arch = "wasm32")]
pub mod ondemand {
    use std::cell::RefCell;
    use std::collections::HashMap;

    thread_local! {
        static SOURCE: RefCell<Option<fn(&str) -> Option<Vec<u8>>>> = const { RefCell::new(None) };
        static CACHE: RefCell<HashMap<&'static str, &'static [u8]>> = RefCell::new(HashMap::new());
    }

    pub fn set_source(f: fn(&str) -> Option<Vec<u8>>) {
        SOURCE.with(|s| *s.borrow_mut() = Some(f));
    }

    /// A failed fetch is not cached, so the next simulation tries again.
    pub fn get(file: &'static str) -> &'static [u8] {
        if let Some(b) = CACHE.with(|c| c.borrow().get(file).copied()) {
            return b;
        }
        let Some(src) = SOURCE.with(|s| *s.borrow()) else { return &[] };
        let Some(bytes) = src(file).filter(|v| !v.is_empty()) else { return &[] };
        let bytes: &'static [u8] = Vec::leak(bytes);
        CACHE.with(|c| c.borrow_mut().insert(file, bytes));
        bytes
    }
}

macro_rules! blobs_ondemand {
    ($dir:expr, $($(#[$doc:meta])* $name:ident = $file:literal;)*) => {$(
        $(#[$doc])*
        pub fn $name() -> &'static [u8] {
            #[cfg(target_arch = "wasm32")]
            {
                ondemand::get($file)
            }
            #[cfg(not(target_arch = "wasm32"))]
            {
                blob_bytes!($dir, $file)
            }
        }
    )*};
}

blobs_ondemand! {env!("OUT_DIR"),
    /// `openmodelica_lapack` as a PIC dylink library, loaded into the simulation's
    /// memory (or linked into an FMU) when a model's `external "FORTRAN 77"` calls
    /// reach it. 1.3 MB most sessions never ask for, hence on demand.
    LAPACK_DYLINK = "liblapack.wasm";

    /// `[{"file": …, "exports": […]}]`, so a name is looked up before anything is fetched.
    ONDEMAND_INDEX = "index.json";
}

/// Symbol -> blob file. Cached even when it fails, so a bundle with no index is not
/// fetched again for every name.
fn ondemand_index() -> Option<&'static std::collections::HashMap<String, String>> {
    static MAP: std::sync::OnceLock<Option<std::collections::HashMap<String, String>>> =
        std::sync::OnceLock::new();
    MAP.get_or_init(|| {
        let json = serde_json::from_slice::<serde_json::Value>(ONDEMAND_INDEX()).ok()?;
        let mut map = std::collections::HashMap::new();
        for entry in json.as_array()? {
            let (Some(file), Some(exports)) = (
                entry.get("file").and_then(|f| f.as_str()),
                entry.get("exports").and_then(|e| e.as_array()),
            ) else {
                continue;
            };
            for name in exports.iter().filter_map(|n| n.as_str()) {
                map.insert(name.to_owned(), file.to_owned());
            }
        }
        Some(map)
    })
    .as_ref()
}

pub fn ondemand_library_for(symbol: &str) -> Option<&'static str> {
    ondemand_index()?.get(symbol).map(String::as_str)
}

/// No index means no on-demand libraries: not the same as a name none exports.
pub fn ondemand_index_read() -> bool {
    ondemand_index().is_some()
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
// One library per MSL library, none embedded: the browser fetches what a model
// calls into and what that needs, for most models one small library or none.
blobs_ondemand! {env!("OMC_WASI_BLOB_DIR"),
    /// The base: ModelicaInternal/Strings/Random/FFT, plus the `Modelica*`
    /// utilities and the stubs wasi-libc lacks, which the rest of the family needs.
    EXTERNAL_C_DYLINK = "ModelicaExternalC.wasm";
    /// ModelicaStandardTables; needs [`MODELICA_IO_DYLINK`].
    STANDARD_TABLES_DYLINK = "ModelicaStandardTables.wasm";
    /// ModelicaIO; needs [`MODELICA_MATIO_DYLINK`].
    MODELICA_IO_DYLINK = "ModelicaIO.wasm";
    /// ModelicaMatIO; needs [`ZLIB_DYLINK`] and [`HDF5_DYLINK`].
    MODELICA_MATIO_DYLINK = "ModelicaMatIO.wasm";
    /// The bundled zlib.
    ZLIB_DYLINK = "zlib.wasm";
    /// The HDF5 that gives ModelicaMatIO MAT v7.3, as separate from it as
    /// `libhdf5.so` is natively.
    HDF5_DYLINK = "hdf5.wasm";
    /// A `-fPIC` wasi-libc `libc.so` dylink module (Debian's is non-PIC).
    LIBC_PIC = "libc_pic.wasm";
}

blobs! {env!("OMC_WASI_BLOB_DIR"),
    /// The dummy `usertab` ModelicaExternalC imports, separate so it can be linked
    /// last; 400 bytes, so embedded rather than fetched.
    USERTAB_DYLINK = "usertab_dylink.wasm";
    /// The `wasi_snapshot_preview1` -> preview2 reactor adapter.
    WASI_P1_ADAPTER = "wasi_snapshot_preview1.reactor.wasm";
}

/// The shared libraries omc carries, by the file name `dylink.0` NEEDED uses.
/// Nothing here is linked unconditionally; see `dylink::libraries_for`.
pub const EXT_FAMILY: &[(&str, fn() -> &'static [u8])] = &[
    ("ModelicaExternalC.wasm", EXTERNAL_C_DYLINK),
    ("ModelicaStandardTables.wasm", STANDARD_TABLES_DYLINK),
    ("ModelicaIO.wasm", MODELICA_IO_DYLINK),
    ("ModelicaMatIO.wasm", MODELICA_MATIO_DYLINK),
    ("zlib.wasm", ZLIB_DYLINK),
    ("hdf5.wasm", HDF5_DYLINK),
    ("liblapack.wasm", LAPACK_DYLINK),
];

/// The bytes of a library named by [`EXT_FAMILY`] or a NEEDED entry.
pub fn ext_library(file: &str) -> Option<&'static [u8]> {
    EXT_FAMILY.iter().find(|(f, _)| *f == file).map(|(_, b)| b()).filter(|b| !b.is_empty())
}

/// Whether external "C" in a host-free wasm FMU is supported: the libraries are
/// chosen per model, so what must be present is the PIC libc and the adapter.
pub fn external_c_available() -> bool {
    !LIBC_PIC().is_empty() && !WASI_P1_ADAPTER().is_empty()
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
