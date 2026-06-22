// Manually written file.
//
// Runtime loader for `-d=gen` compiled MetaModelica functions.
//
// With `-d=gen`, `CevalScript.cevalGenerateFunction` translates a function to
// C and `compileModel` builds it into a shared object that links the C
// MetaModelica runtime (`libOpenModelicaRuntimeC`). The function is then called
// through the runtime: `System.loadLibrary` (dlopen), `System.lookupFunction`
// (resolve the `in_<name>` entry point) and `DynLoad.executeFunction` (marshal
// the argument/result `Values`). This module owns the process-global state for
// that path:
//
//   * the `dlopen`ed shared objects and the resolved `in_*` addresses, and
//   * the one-time runtime initialisation: `mmc_init()` (GC + thread key) plus
//     a `threadData` buffer to thread through the generated entry points.
//
// The C runtime keeps global GC and thread-local state and is not safe to call
// from several threads at once, so everything here is serialised behind a
// single mutex. `loadLibrary`/`lookupFunction`/`freeLibrary`/`freeFunction` in
// `System` forward here; the `Values` marshalling lives in
// `openmodelica_script_util` (it needs the frontend `Values` type) and reaches
// the loaded function through [`function_addr`] and [`thread_data`].

use std::collections::HashMap;
use std::ffi::{CStr, CString};
use std::sync::{LazyLock, Mutex};

use anyhow::{Result, bail};
use libc::{c_int, c_void};

// dlopen flags mirror `SystemImpl__loadLibrary` in the C runtime.
#[cfg(target_os = "linux")]
const DLOPEN_FLAGS: c_int = libc::RTLD_LOCAL | libc::RTLD_NOW | libc::RTLD_DEEPBIND;
#[cfg(not(target_os = "linux"))]
const DLOPEN_FLAGS: c_int = libc::RTLD_LOCAL | libc::RTLD_NOW;

// `threadData_t` is 304 bytes in the current runtime; over-allocate generously
// so a minor runtime struct change cannot make the generated `in_*` wrapper
// scribble past the buffer. The extra bytes stay zeroed (and so contain no
// pointers the GC could mistake for roots).
const THREADDATA_SIZE: usize = 4096;

struct Registry {
    /// loadLibrary handle → `dlopen` handle (cast to usize so the map is `Send`).
    libs: HashMap<i32, usize>,
    /// lookupFunction handle → `in_*` function address.
    funcs: HashMap<i32, usize>,
    next_lib: i32,
    next_func: i32,
    /// `mmc_init()` called and `thread_data` allocated.
    inited: bool,
    /// `threadData` pointer (cast to usize), valid once `inited`.
    thread_data: usize,
}

impl Registry {
    fn new() -> Self {
        Registry { libs: HashMap::new(), funcs: HashMap::new(), next_lib: 1, next_func: 1, inited: false, thread_data: 0 }
    }
}

static REGISTRY: LazyLock<Mutex<Registry>> = LazyLock::new(|| Mutex::new(Registry::new()));

unsafe extern "C" {
    /// C shim (`src/runtime_error_shim.c`): rebind the runtime's
    /// `OpenModelica_Modelica{,V}FormatError` function-pointer slots so that a
    /// `ModelicaError`/`ModelicaFormatError` raised inside an evaluated external
    /// function is reported to the error buffer before the runtime throws. See
    /// [`install_modelica_error_interception`].
    fn omrs_install_modelica_error(err_slot: *mut c_void, verr_slot: *mut c_void);

    /// C shim: rebind the runtime's `omc_assert` function-pointer slot to a shim
    /// that reports the assertion (with its source position) to the error buffer
    /// and then throws via `throw_fn` (the runtime's `omc_throw`), without the
    /// default `omc_assert_function` stderr print. The analogue of
    /// `Error_initAssertionFunctions`. See [`install_omc_assert_interception`].
    fn omrs_install_omc_assert(assert_slot: *mut c_void, throw_fn: *mut c_void);
}

/// Rebind the loaded runtime's `ModelicaError`/`ModelicaFormatError` hooks, the
/// analogue of `Error_registerModelicaFormatError` (which the C compiler runs at
/// startup against its statically-linked runtime). Only takes effect when the
/// host requested it via `ErrorExt::registerModelicaFormatError`. `dlsym`
/// resolves the addresses of the runtime's function-pointer variables (through
/// the function library's `DT_NEEDED` on `libOpenModelicaRuntimeC`); the C shim
/// saves the originals (for the throw) and repoints them at its reporting shims.
fn install_modelica_error_interception(lib: usize) {
    if !openmodelica_error::ErrorExt::modelicaFormatErrorRegistered() {
        return;
    }
    let err_slot = dlsym_addr(lib, "OpenModelica_ModelicaError");
    let verr_slot = dlsym_addr(lib, "OpenModelica_ModelicaVFormatError");
    // Both pointers come from the same runtime translation unit; if either is
    // missing the runtime predates this hook and there is nothing to rebind.
    if let (Some(err_slot), Some(verr_slot)) = (err_slot, verr_slot) {
        unsafe {
            omrs_install_modelica_error(err_slot as *mut c_void, verr_slot as *mut c_void);
        }
    }
}

/// Rebind the loaded runtime's `omc_assert`, the analogue of
/// `Error_initAssertionFunctions`. Only takes effect when the host requested it
/// via `ErrorExt::initAssertionFunctions`. `dlsym` resolves the `omc_assert`
/// function-pointer variable's address and the `omc_throw` variable (whose
/// current value is the runtime's clean, non-printing throw); the shim repoints
/// `omc_assert` and uses `omc_throw` to throw after reporting the message.
fn install_omc_assert_interception(lib: usize) {
    if !openmodelica_error::ErrorExt::assertFunctionsRegistered() {
        return;
    }
    let assert_slot = dlsym_addr(lib, "omc_assert");
    let throw_slot = dlsym_addr(lib, "omc_throw");
    if let (Some(assert_slot), Some(throw_slot)) = (assert_slot, throw_slot) {
        // `omc_throw` is itself a function-pointer variable; read its current
        // value (the runtime's `omc_throw_function`) to hand the shim a throw.
        let throw_fn = unsafe { *(throw_slot as *const usize) };
        unsafe {
            omrs_install_omc_assert(assert_slot as *mut c_void, throw_fn as *mut c_void);
        }
    }
}

fn last_dlerror() -> String {
    let e = unsafe { libc::dlerror() };
    if e.is_null() { "unknown error".to_owned() } else { unsafe { CStr::from_ptr(e) }.to_string_lossy().into_owned() }
}

fn dlopen_path(path: &str) -> Result<usize> {
    let c = CString::new(path)?;
    unsafe { libc::dlerror() }; // clear any stale error
    let h = unsafe { libc::dlopen(c.as_ptr(), DLOPEN_FLAGS) };
    if h.is_null() {
        bail!("dlopen `{path}`: {}", last_dlerror());
    }
    Ok(h as usize)
}

fn dlsym_addr(handle: usize, name: &str) -> Option<usize> {
    let c = CString::new(name).ok()?;
    let p = unsafe { libc::dlsym(handle as *mut c_void, c.as_ptr()) };
    if p.is_null() { None } else { Some(p as usize) }
}

/// Preload the OMC C runtime libraries that external-function shared
/// objects link against (DT_NEEDED), once per process.
///
/// The reference `omc` binary itself links `libOpenModelicaRuntimeC.so`
/// (which pulls in `libomcgc`), so when an external library such as
/// `ffi/libModelicaExternalC.so` is dlopen'ed, the loader resolves that
/// dependency against the already-loaded copy. The Rust port does not link
/// the C runtime, so we dlopen it RTLD_GLOBAL from the installation's omc
/// lib dir before loading user libraries. A missing runtime lib is not an
/// error — libraries without that dependency still load fine.
fn ensure_runtime_solibs() {
    use std::sync::Once;
    static ONCE: Once = Once::new();
    ONCE.call_once(|| {
        // libomcruntime holds process-global state — the System PRNG seed
        // (`system_random_seed`), the Print buffers, the errorext message
        // stack. In the C omc that state lives in the executable and never
        // resets; pin the library here so the dlclose of a function library
        // (each `-d=gen` call frees its `.so` afterwards) can never drop its
        // refcount to zero and reset those statics. Its `RTLD_NOW` load needs
        // two symbol sources that the C omc's executable provides by linking
        // them outright: openblas (libomcruntime underlinks LAPACK — `dgesv_`
        // and friends are not in its DT_NEEDED closure), pinned global just
        // before it, and `omc_Error_getCurrentComponent` from the executable's
        // dynamic symbol table (the shim in DynLoadExt.rs).
        for lib in ["libOpenModelicaRuntimeC.so", "libopenblas.so.0", "libomcruntime.so"] {
            // First by basename: this resolves through the binary's RUNPATH
            // (`$ORIGIN/../lib/<triple>/omc`, see openmodelica/build.rs) and
            // — crucially — registers the library in ld.so's link map under
            // its DT_NEEDED name, since it has no SONAME. Only then does a
            // dependent library's `NEEDED libOpenModelicaRuntimeC.so` match
            // the already-loaded copy, exactly as it does in the reference
            // omc process (which links the library outright).
            let by_name = CString::new(lib).unwrap();
            unsafe { libc::dlerror() };
            if !unsafe { libc::dlopen(by_name.as_ptr(), libc::RTLD_GLOBAL | libc::RTLD_NOW) }
                .is_null()
            {
                continue;
            }
            // Fallback for uninstalled layouts (e.g. running from
            // target/debug): load by full path from the installation's omc
            // lib dir. This satisfies direct dlopen uses but not DT_NEEDED
            // references (the link-map name is then the full path).
            let Ok(install_dir) = crate::Settings::getInstallationDirectoryPath() else { return };
            let path = format!("{install_dir}/lib/{}/omc/{lib}", crate::Autoconf::triple);
            if let Ok(c) = CString::new(path) {
                unsafe {
                    libc::dlerror();
                    libc::dlopen(c.as_ptr(), libc::RTLD_GLOBAL | libc::RTLD_NOW);
                }
            }
        }
    });
}

/// `System.loadLibrary`: `dlopen` the shared object and return a handle.
/// `relative` resolves the name against the current directory like the C
/// runtime (`./name`); an empty name opens the running process.
pub fn load_library(path: &str, relative: bool, debug: bool) -> Result<i32> {
    ensure_runtime_solibs();
    let handle = if path.is_empty() {
        unsafe { libc::dlerror() };
        let h = unsafe { libc::dlopen(std::ptr::null(), DLOPEN_FLAGS) };
        if h.is_null() { bail!("dlopen process: {}", last_dlerror()); }
        h as usize
    } else if relative && !path.starts_with('/') {
        dlopen_path(&format!("./{path}"))?
    } else {
        dlopen_path(path)?
    };
    let mut reg = REGISTRY.lock().unwrap();
    let idx = reg.next_lib;
    reg.next_lib += 1;
    reg.libs.insert(idx, handle);
    if debug {
        eprintln!("LIB LOAD [{path}] index[{idx}].");
    }
    Ok(idx)
}

/// `System.lookupFunction`: resolve a symbol (the generated `in_<name>` entry
/// point) inside a loaded library and return a handle to it.
pub fn lookup_function(lib: i32, name: &str) -> Result<i32> {
    let mut reg = REGISTRY.lock().unwrap();
    let handle = *reg.libs.get(&lib).ok_or_else(|| anyhow::anyhow!("lookupFunction: invalid library handle {lib}"))?;
    let addr = dlsym_addr(handle, name).ok_or_else(|| anyhow::anyhow!("lookupFunction: `{name}` not found: {}", last_dlerror()))?;
    let idx = reg.next_func;
    reg.next_func += 1;
    reg.funcs.insert(idx, addr);
    Ok(idx)
}

/// `System.freeFunction`: forget a function handle. The owning library stays
/// loaded until `freeLibrary`.
pub fn free_function(func: i32, _debug: bool) -> Result<()> {
    REGISTRY.lock().unwrap().funcs.remove(&func);
    Ok(())
}

/// `System.freeLibrary`: `dlclose` the shared object. The C runtime itself is
/// pinned (see [`ensure_runtime`]), so closing a function library never unloads
/// the shared GC/`threadData` state.
pub fn free_library(lib: i32, _debug: bool) -> Result<()> {
    let handle = REGISTRY.lock().unwrap().libs.remove(&lib);
    if let Some(h) = handle {
        unsafe { libc::dlclose(h as *mut c_void); }
    }
    Ok(())
}

/// Address of the `in_*` entry point behind a function handle.
pub fn function_addr(func: i32) -> Result<usize> {
    REGISTRY.lock().unwrap().funcs.get(&func).copied().ok_or_else(|| anyhow::anyhow!("executeFunction: invalid function handle {func}"))
}

/// Resolve a symbol from the loaded C runtime (e.g. `mmc_mk_*`,
/// `free_type_description`) for the marshalling layer. Returns `None` if no
/// library is loaded yet or the symbol is absent.
pub fn runtime_symbol(name: &str) -> Option<usize> {
    let reg = REGISTRY.lock().unwrap();
    let handle = *reg.libs.values().next()?;
    dlsym_addr(handle, name)
}

/// Initialise the C runtime once (`mmc_init`, a `threadData`) and pin
/// `libOpenModelicaRuntimeC` so it survives `freeLibrary`. Requires at least
/// one function library to be loaded (it provides the runtime symbols).
fn ensure_runtime(reg: &mut Registry) -> Result<()> {
    if reg.inited {
        return Ok(());
    }
    let &lib = reg.libs.values().next().ok_or_else(|| anyhow::anyhow!("executeFunction: no library loaded"))?;
    let mmc_init = dlsym_addr(lib, "mmc_init").ok_or_else(|| anyhow::anyhow!("runtime symbol `mmc_init` not found"))?;
    let gc_alloc = dlsym_addr(lib, "GC_malloc_uncollectable").ok_or_else(|| anyhow::anyhow!("runtime symbol `GC_malloc_uncollectable` not found"))?;
    unsafe {
        // Pin the runtime shared object: locate it from `mmc_init`'s address and
        // re-open it `RTLD_NODELETE` so later `dlclose`s of function libraries
        // leave the GC heap and `threadData` valid.
        let mut info: libc::Dl_info = std::mem::zeroed();
        if libc::dladdr(mmc_init as *const c_void, &mut info) != 0 && !info.dli_fname.is_null() {
            libc::dlopen(info.dli_fname, libc::RTLD_NOW | libc::RTLD_GLOBAL | libc::RTLD_NODELETE);
        }
        let init: extern "C" fn() = std::mem::transmute(mmc_init);
        init();
        let alloc: extern "C" fn(usize) -> *mut c_void = std::mem::transmute(gc_alloc);
        let td = alloc(THREADDATA_SIZE);
        if td.is_null() {
            bail!("executeFunction: threadData allocation failed");
        }
        std::ptr::write_bytes(td as *mut u8, 0, THREADDATA_SIZE);
        reg.thread_data = td as usize;
    }
    // The runtime that owns the `OpenModelica_Modelica*Error` pointers and
    // `omc_assert` is now loaded; rebind them if the host asked for
    // error-buffer interception.
    install_modelica_error_interception(lib);
    install_omc_assert_interception(lib);
    reg.inited = true;
    Ok(())
}

/// The `threadData` pointer to thread through a generated `in_*` call,
/// initialising the runtime on first use.
pub fn thread_data() -> Result<usize> {
    let mut reg = REGISTRY.lock().unwrap();
    ensure_runtime(&mut reg)?;
    Ok(reg.thread_data)
}
