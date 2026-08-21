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
//   * the loaded shared objects and the resolved `in_*` addresses, and
//   * the one-time runtime initialisation: `mmc_init()` (GC + thread key) plus
//     a `threadData` buffer to thread through the generated entry points.
//
// The C runtime keeps global GC and thread-local state and is not safe to call
// from several threads at once, so everything here is serialised behind a
// single mutex. `loadLibrary`/`lookupFunction`/`freeLibrary`/`freeFunction` in
// `System` forward here; the `Values` marshalling lives in
// `openmodelica_script_util` (it needs the frontend `Values` type) and reaches
// the loaded function through [`function_addr`] and [`thread_data`].
//
// The platform dynamic-loading primitives (dlopen/LoadLibrary etc.) live in the
// [`dl`] submodule, with a POSIX backend and a Windows (kernel32) backend; the
// rest of the module is platform-neutral.

use std::collections::HashMap;
use std::sync::{LazyLock, Mutex};

use metamodelica::Result;
use core::ffi::c_void;

// `threadData_t` is 304 bytes in the current runtime; over-allocate generously
// so a minor runtime struct change cannot make the generated `in_*` wrapper
// scribble past the buffer. The extra bytes stay zeroed (and so contain no
// pointers the GC could mistake for roots).
const THREADDATA_SIZE: usize = 4096;

// ---------------------------------------------------------------------------
// Platform dynamic-loading primitives. The POSIX backend wraps libdl; the
// Windows backend wraps the kernel32 module API. Both expose the same set of
// `usize`-handle helpers the loader below is written against.
// ---------------------------------------------------------------------------
#[cfg(unix)]
pub(crate) mod dl {
    use metamodelica::Result;
    use core::ffi::c_void;
    use libc::c_int;
    use std::ffi::{CStr, CString};

    // dlopen flags mirror `SystemImpl__loadLibrary` in the C runtime.
    #[cfg(target_os = "linux")]
    const LOCAL: c_int = libc::RTLD_LOCAL | libc::RTLD_DEEPBIND;
    #[cfg(not(target_os = "linux"))]
    const LOCAL: c_int = libc::RTLD_LOCAL;

    const FLAGS: c_int = LOCAL | libc::RTLD_NOW;

    fn flags(lazy: bool) -> c_int {
        LOCAL | if lazy { libc::RTLD_LAZY } else { libc::RTLD_NOW }
    }

    // C-runtime shared objects external-function libraries link against
    // (DT_NEEDED), preloaded RTLD_GLOBAL so the loader resolves them.
    pub const RUNTIME_LIBS: &[&str] =
        &["libOpenModelicaRuntimeC.so", "libopenblas.so.0", "libomcruntime.so"];

    pub fn last_error() -> String {
        let e = unsafe { libc::dlerror() };
        if e.is_null() {
            "unknown error".to_owned()
        } else {
            unsafe { CStr::from_ptr(e) }.to_string_lossy().into_owned()
        }
    }

    pub fn open(path: &str) -> Result<usize> {
        open_with_binding(path, false)
    }

    pub fn open_with_binding(path: &str, lazy: bool) -> Result<usize> {
        let c = CString::new(path).map_err(|_| "dynload: NUL byte in path")?;
        unsafe { libc::dlerror() }; // clear any stale error
        let h = unsafe { libc::dlopen(c.as_ptr(), flags(lazy)) };
        if h.is_null() {
            super::record_load_error(last_error());
            return Err("dlopen `{path}`: {}");
        }
        Ok(h as usize)
    }

    /// Open the running process (resolve symbols already in the image).
    pub fn open_self() -> Result<usize> {
        unsafe { libc::dlerror() };
        let h = unsafe { libc::dlopen(std::ptr::null(), FLAGS) };
        if h.is_null() {
            return Err("dlopen process: {}");
        }
        Ok(h as usize)
    }

    /// Preload a library into the global scope so later loads resolve its
    /// symbols. Returns true on success.
    pub fn open_global(name: &str) -> bool {
        let Ok(c) = CString::new(name) else { return false };
        unsafe { libc::dlerror() };
        !unsafe { libc::dlopen(c.as_ptr(), libc::RTLD_GLOBAL | libc::RTLD_NOW) }.is_null()
    }

    /// Global scope, deferred binding: for libraries that reference each other, so
    /// the order they are loaded in need not be a topological one.
    pub fn open_global_deferred(name: &str) -> std::result::Result<usize, String> {
        let c = CString::new(name).map_err(|_| "NUL byte in path".to_owned())?;
        unsafe { libc::dlerror() };
        let h = unsafe { libc::dlopen(c.as_ptr(), libc::RTLD_GLOBAL | libc::RTLD_LAZY) };
        if h.is_null() { Err(last_error()) } else { Ok(h as usize) }
    }

    pub fn sym(handle: usize, name: &str) -> Option<usize> {
        let c = CString::new(name).ok()?;
        let p = unsafe { libc::dlsym(handle as *mut c_void, c.as_ptr()) };
        if p.is_null() { None } else { Some(p as usize) }
    }

    pub fn close(handle: usize) {
        unsafe { libc::dlclose(handle as *mut c_void) };
    }

    /// Pin the shared object containing `addr` (re-open it `RTLD_NODELETE`) so a
    /// later `close` of a function library cannot unload it.
    pub fn pin_containing(addr: usize) {
        unsafe {
            let mut info: libc::Dl_info = std::mem::zeroed();
            if libc::dladdr(addr as *const c_void, &mut info) != 0 && !info.dli_fname.is_null() {
                libc::dlopen(info.dli_fname, libc::RTLD_NOW | libc::RTLD_GLOBAL | libc::RTLD_NODELETE);
            }
        }
    }
}

#[cfg(windows)]
pub(crate) mod dl {
    use metamodelica::Result;
    use core::ffi::{c_char, c_void};
    use std::ffi::CString;

    type HMODULE = *mut c_void;

    unsafe extern "system" {
        fn LoadLibraryA(name: *const c_char) -> HMODULE;
        fn GetModuleHandleA(name: *const c_char) -> HMODULE;
        fn GetProcAddress(module: HMODULE, name: *const c_char) -> *mut c_void;
        fn FreeLibrary(module: HMODULE) -> i32;
        fn GetLastError() -> u32;
        fn GetModuleHandleExA(flags: u32, addr: *const c_char, module: *mut HMODULE) -> i32;
    }
    const GET_MODULE_HANDLE_EX_FLAG_PIN: u32 = 0x1;
    const GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS: u32 = 0x4;

    // The Windows DLLs an external-function library depends on are resolved by
    // the loader through the executable's directory and PATH; preloading them by
    // name pins the same copy in the process. Names mirror RUNTIME_LIBS above.
    pub const RUNTIME_LIBS: &[&str] =
        &["OpenModelicaRuntimeC.dll", "libopenblas.dll", "omcruntime.dll"];

    pub fn last_error() -> String {
        format!("error {}", unsafe { GetLastError() })
    }

    pub fn open(path: &str) -> Result<usize> {
        open_with_binding(path, false)
    }

    /// Windows resolves imports when the module is loaded and offers no way to
    /// defer it, so `lazy` has nothing to select here.
    pub fn open_with_binding(path: &str, _lazy: bool) -> Result<usize> {
        let c = CString::new(path).map_err(|_| "dynload: NUL byte in path")?;
        let h = unsafe { LoadLibraryA(c.as_ptr()) };
        if h.is_null() {
            super::record_load_error(last_error());
            return Err("LoadLibrary `{path}`: {}");
        }
        Ok(h as usize)
    }

    pub fn open_self() -> Result<usize> {
        let h = unsafe { GetModuleHandleA(std::ptr::null()) };
        if h.is_null() {
            return Err("GetModuleHandle(process): {}");
        }
        Ok(h as usize)
    }

    pub fn open_global(name: &str) -> bool {
        let Ok(c) = CString::new(name) else { return false };
        let h = unsafe { LoadLibraryA(c.as_ptr()) };
        if h.is_null() {
            return false;
        }
        // Pin it so its globals (PRNG seed, Print/error buffers) survive a
        // later FreeLibrary of a function DLL.
        let mut module: HMODULE = std::ptr::null_mut();
        unsafe {
            GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_PIN, c.as_ptr(), &mut module);
        }
        true
    }

    /// The Windows loader always binds lazily and has no global scope; a plain
    /// `LoadLibrary` is what [`open_global_deferred`] means here.
    pub fn open_global_deferred(name: &str) -> std::result::Result<usize, String> {
        let c = CString::new(name).map_err(|_| "NUL byte in path".to_owned())?;
        let h = unsafe { LoadLibraryA(c.as_ptr()) };
        if h.is_null() { Err(last_error()) } else { Ok(h as usize) }
    }

    pub fn sym(handle: usize, name: &str) -> Option<usize> {
        let c = CString::new(name).ok()?;
        let p = unsafe { GetProcAddress(handle as HMODULE, c.as_ptr()) };
        if p.is_null() { None } else { Some(p as usize) }
    }

    pub fn close(handle: usize) {
        unsafe { FreeLibrary(handle as HMODULE) };
    }

    pub fn pin_containing(addr: usize) {
        let mut module: HMODULE = std::ptr::null_mut();
        unsafe {
            GetModuleHandleExA(
                GET_MODULE_HANDLE_EX_FLAG_PIN | GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS,
                addr as *const c_char,
                &mut module,
            );
        }
    }
}

struct Registry {
    /// loadLibrary handle → module handle (cast to usize so the map is `Send`).
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

    /// Panic-mode variants for the simulation host: the shims report the message
    /// and then call the Rust `omrs_runtime_abort` (a panic) instead of the
    /// runtime's throw — whose simulation-side `longjmp` has no jump buffer set
    /// up here. See [`ensure_sim_error_interception`] and `runtime_error_shim.c`.
    fn omrs_install_modelica_error_panic(err_slot: *mut c_void, verr_slot: *mut c_void);
    fn omrs_install_omc_assert_panic(assert_slot: *mut c_void);

    /// C shim: rebind the runtime's `OpenModelica_ModelicaVFormat{Message,Warning}`
    /// slots so an external function's messages reach the running simulation's
    /// log instead of the runtime's never-enabled `OMC_LOG_STDOUT` stream.
    fn omrs_install_modelica_message(
        msg_slot: *mut c_void,
        warn_slot: *mut c_void,
        msg_hook: ModelicaMessageHook,
        warn_hook: ModelicaMessageHook,
    );
}

/// Renders a `ModelicaMessage`/`ModelicaWarning` for the simulation host;
/// returns whether it took it. See [`install_modelica_message_interception`].
pub type ModelicaMessageHook = extern "C" fn(*const core::ffi::c_char) -> i32;

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

fn dlsym_addr(handle: usize, name: &str) -> Option<usize> {
    dl::sym(handle, name)
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
        // resets; pin the library here so the close of a function library
        // (each `-d=gen` call frees its lib afterwards) can never drop its
        // refcount to zero and reset those statics. Its `RTLD_NOW` load needs
        // two symbol sources that the C omc's executable provides by linking
        // them outright: openblas (libomcruntime underlinks LAPACK — `dgesv_`
        // and friends are not in its DT_NEEDED closure), pinned global just
        // before it, and `omc_Error_getCurrentComponent` from the executable's
        // dynamic symbol table (the shim in DynLoadExt.rs).
        for lib in dl::RUNTIME_LIBS {
            // First by basename: this resolves through the binary's RUNPATH
            // (`$ORIGIN/../lib/<triple>/omc`, see openmodelica/build.rs) and
            // — crucially — registers the library in ld.so's link map under
            // its DT_NEEDED name, since it has no SONAME. Only then does a
            // dependent library's `NEEDED libOpenModelicaRuntimeC.so` match
            // the already-loaded copy, exactly as it does in the reference
            // omc process (which links the library outright). On Windows the
            // loader resolves DLL dependencies via the exe directory and PATH,
            // so the basename load both finds and pins the runtime DLL.
            if dl::open_global(lib) {
                continue;
            }
            // Fallback for uninstalled layouts (e.g. running from
            // target/debug): load by full path from the installation's omc
            // lib dir. This satisfies direct dlopen uses but not DT_NEEDED
            // references (the link-map name is then the full path).
            let Ok(install_dir) = crate::Settings::getInstallationDirectoryPath() else { return };
            let path = format!("{install_dir}/lib/{}/omc/{lib}", crate::Autoconf::triple);
            dl::open_global(&path);
        }
    });
}

/// `System.loadLibrary`: open the shared object and return a handle.
/// `relative` resolves the name against the current directory like the C
/// runtime (`./name`); an empty name opens the running process.
/// Why the last [`load_library`] failed, for a caller searching a list of
/// candidate paths: the error it reports is about the whole list, so each
/// path's reason has to survive until it gives up. Mirrors
/// `last_load_library_error` in the C runtime.
static LAST_LOAD_ERROR: Mutex<String> = Mutex::new(String::new());

pub(crate) fn record_load_error(msg: String) {
    *LAST_LOAD_ERROR.lock().unwrap() = msg;
}

/// `System.getLoadLibraryError`.
pub fn last_load_error() -> String {
    LAST_LOAD_ERROR.lock().unwrap().clone()
}

pub fn load_library(path: &str, relative: bool, debug: bool) -> Result<i32> {
    load_library_with_binding(path, relative, debug, false)
}

/// `System.loadLibraryLazy`: as [`load_library`], but binds symbols when they
/// are used rather than when the library is loaded.
pub fn load_library_lazy(path: &str, relative: bool, debug: bool) -> Result<i32> {
    load_library_with_binding(path, relative, debug, true)
}

fn load_library_with_binding(path: &str, relative: bool, debug: bool, lazy: bool) -> Result<i32> {
    ensure_runtime_solibs();
    record_load_error(String::new());
    let handle = if path.is_empty() {
        dl::open_self()?
    } else if relative && !path.starts_with('/') {
        dl::open_with_binding(&format!("./{path}"), lazy)?
    } else {
        dl::open_with_binding(path, lazy)?
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
    let handle = *reg.libs.get(&lib).ok_or_else(|| "lookupFunction: invalid library handle {lib}")?;
    let addr = dlsym_addr(handle, name).ok_or_else(|| "lookupFunction: `{name}` not found: {}")?;
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

/// `System.freeLibrary`: close the shared object. The C runtime itself is
/// pinned (see [`ensure_runtime`]), so closing a function library never unloads
/// the shared GC/`threadData` state.
pub fn free_library(lib: i32, _debug: bool) -> Result<()> {
    let handle = REGISTRY.lock().unwrap().libs.remove(&lib);
    if let Some(h) = handle {
        dl::close(h);
    }
    Ok(())
}

/// Address of the `in_*` entry point behind a function handle.
pub fn function_addr(func: i32) -> Result<usize> {
    REGISTRY.lock().unwrap().funcs.get(&func).copied().ok_or_else(|| "executeFunction: invalid function handle {func}")
}

/// Resolve a symbol from the loaded C runtime (e.g. `mmc_mk_*`,
/// `free_type_description`) for the marshalling layer. Returns `None` if no
/// library is loaded yet or the symbol is absent.
pub fn runtime_symbol(name: &str) -> Option<usize> {
    let reg = REGISTRY.lock().unwrap();
    let handle = *reg.libs.values().next()?;
    dlsym_addr(handle, name)
}

/// Resolve an external "C" function for the wasm-jit simulation host. Ensures the
/// C runtime libraries and the bundled `ffi/` libraries (ModelicaStandardTables,
/// ModelicaExternalC, …) are loaded `RTLD_GLOBAL`, then resolves `name` from the
/// process image (self + globally-loaded libraries, incl. libm). Returns the
/// function address, or `None` if no loaded library provides it.
pub fn external_symbol(name: &str) -> Option<usize> {
    ensure_sim_libs();
    let me = dl::open_self().ok()?;
    dl::sym(me, name)
}

fn ensure_sim_libs() {
    ensure_runtime_solibs();
    ensure_ffi_solibs();
    ensure_sim_error_interception();
}

/// The platform shared libraries a model's `Library` annotations name, which the C
/// target would have linked into the simulation executable. Loaded once per path (a
/// model may be resimulated), into the global scope so they resolve against the C
/// runtime's `ModelicaError` and each other. Returns why any that would not load did
/// not, alongside the handles, in the declared order.
///
/// One of them may leave a symbol a later one defines undefined, which the C target's
/// single link resolves but a loader binding one library at a time does not, so retry
/// the ones that would not load until a pass loads nothing new.
pub fn load_external_libraries(paths: &[String]) -> (Vec<usize>, Vec<String>) {
    static LOADED: LazyLock<Mutex<HashMap<String, usize>>> = LazyLock::new(|| Mutex::new(HashMap::new()));
    ensure_sim_libs();
    let mut loaded = LOADED.lock().unwrap();
    let mut handles: Vec<Option<usize>> = paths.iter().map(|p| loaded.get(p).copied()).collect();
    let mut errors: Vec<String> = vec![String::new(); paths.len()];
    loop {
        let mut progress = false;
        for (i, path) in paths.iter().enumerate() {
            if handles[i].is_some() {
                continue;
            }
            match dl::open_global_deferred(path) {
                Ok(h) => {
                    loaded.insert(path.clone(), h);
                    handles[i] = Some(h);
                    progress = true;
                }
                Err(e) => errors[i] = e,
            }
        }
        if !progress {
            break;
        }
    }
    let errors = paths
        .iter()
        .zip(&handles)
        .zip(errors)
        .filter(|((_, h), _)| h.is_none())
        .map(|((path, _), e)| format!("`{path}` could not be loaded: {e}"))
        .collect();
    (handles.into_iter().flatten().collect(), errors)
}

/// Resolve against `handles` — the model's own libraries, which shadow a same-named
/// symbol elsewhere — then against the process image.
pub fn external_symbol_in(handles: &[usize], name: &str) -> Option<usize> {
    symbol_in(handles, name).or_else(|| external_symbol(name))
}

/// Resolve against `handles` alone: for [`usertab`] the process image holds a
/// fallback, so only the model's own definition is an answer.
pub fn symbol_in(handles: &[usize], name: &str) -> Option<usize> {
    handles.iter().find_map(|&h| dl::sym(h, name))
}

/// C's `RHSFinalFlag` (`dassl.c`). External C source declares it `extern` and
/// reads it, so it has to be a real exported symbol of the compiler image.
#[unsafe(no_mangle)]
pub static mut RHSFinalFlag: libc::c_int = 0;

/// A library the linker could only build with a definition of its own (see
/// `ExtArchives::link_attempt`) reads a different `int` from the one above, so
/// every copy is kept in step.
static RHS_FINAL_COPIES: Mutex<Vec<usize>> = Mutex::new(Vec::new());

/// Record the `RHSFinalFlag` each of `handles` exports, if it is not ours.
pub fn register_rhs_final_flag(handles: &[usize]) {
    let mine = (&raw const RHSFinalFlag) as usize;
    let mut copies = RHS_FINAL_COPIES.lock().unwrap();
    copies.clear();
    for &h in handles {
        if let Some(addr) = dl::sym(h, "RHSFinalFlag")
            && addr != mine
            && !copies.contains(&addr)
        {
            copies.push(addr);
        }
    }
}

/// Set [`RHSFinalFlag`] and every copy [`register_rhs_final_flag`] found.
pub fn set_rhs_final_flag(value: bool) {
    let v = value as libc::c_int;
    unsafe { RHSFinalFlag = v };
    for &addr in RHS_FINAL_COPIES.lock().unwrap().iter() {
        unsafe { *(addr as *mut libc::c_int) = v };
    }
}

static USERTAB: std::sync::atomic::AtomicUsize = std::sync::atomic::AtomicUsize::new(0);

type UsertabFn = unsafe extern "C-unwind" fn(
    *mut libc::c_char,
    libc::c_int,
    *mut libc::c_int,
    *mut libc::c_int,
    *mut *mut f64,
) -> libc::c_int;

pub fn set_usertab(addr: Option<usize>) {
    USERTAB.store(addr.unwrap_or(0), std::sync::atomic::Ordering::Relaxed);
}

/// `usertab`, for a `tableOnFile` table with no `fileName`. Preempts the weak dummy
/// `libModelicaStandardTables` carries: the compiler image comes first in the scope.
#[unsafe(no_mangle)]
pub unsafe extern "C-unwind" fn usertab(
    table_name: *mut libc::c_char,
    nipo: libc::c_int,
    dim: *mut libc::c_int,
    col_wise: *mut libc::c_int,
    table: *mut *mut f64,
) -> libc::c_int {
    let hook = USERTAB.load(std::sync::atomic::Ordering::Relaxed);
    if hook != 0 {
        let f: UsertabFn = unsafe { std::mem::transmute(hook) };
        return unsafe { f(table_name, nipo, dim, col_wise, table) };
    }
    // The runtime's own, so the installed interception reports and throws.
    if let Some(addr) = dl::open_self().ok().and_then(|me| dl::sym(me, "ModelicaError")) {
        let err: unsafe extern "C-unwind" fn(*const libc::c_char) = unsafe { std::mem::transmute(addr) };
        unsafe { err(c"Function \"usertab\" is not implemented\n".as_ptr()) };
    }
    1
}

/// Install the panic-mode `ModelicaError`/`omc_assert` interception for the
/// simulation host, once. A `ModelicaError` from an external library (e.g. a
/// missing table file) then records its message in the compiler Error buffer and raises a Rust panic
/// (`omrs_runtime_abort`), which the libffi call site catches
/// (`ErrorExt::catch_runtime_error`) — instead of longjmp-ing into an unset jump
/// buffer and crashing. The runtime's `OpenModelica_Modelica*`/`omc_assert`
/// slots resolve through the global scope (`ensure_runtime_solibs` loaded the
/// runtime `RTLD_GLOBAL`).
fn ensure_sim_error_interception() {
    use std::sync::Once;
    static ONCE: Once = Once::new();
    ONCE.call_once(|| {
        openmodelica_error::ErrorExt::install_runtime_panic_hook();
        let Ok(me) = dl::open_self() else { return };
        let err_slot = dlsym_addr(me, "OpenModelica_ModelicaError");
        let verr_slot = dlsym_addr(me, "OpenModelica_ModelicaVFormatError");
        if let (Some(err_slot), Some(verr_slot)) = (err_slot, verr_slot) {
            unsafe { omrs_install_modelica_error_panic(err_slot as *mut c_void, verr_slot as *mut c_void) };
        }
        if let Some(assert_slot) = dlsym_addr(me, "omc_assert") {
            unsafe { omrs_install_omc_assert_panic(assert_slot as *mut c_void) };
        }
    });
}

/// Route an external function's `ModelicaMessage`/`ModelicaWarning` to `msg_hook`
/// / `warn_hook` — the runtime sends them to `OMC_LOG_STDOUT`, a stream the
/// compiler process never enables, so `Streams.print` output would vanish. A
/// message the hook declines still reaches the original.
pub fn install_modelica_message_interception(msg_hook: ModelicaMessageHook, warn_hook: ModelicaMessageHook) {
    use std::sync::Once;
    static ONCE: Once = Once::new();
    ONCE.call_once(|| {
        ensure_runtime_solibs();
        let Ok(me) = dl::open_self() else { return };
        let msg_slot = dlsym_addr(me, "OpenModelica_ModelicaVFormatMessage");
        let warn_slot = dlsym_addr(me, "OpenModelica_ModelicaVFormatWarning");
        if msg_slot.is_some() || warn_slot.is_some() {
            unsafe {
                omrs_install_modelica_message(
                    msg_slot.unwrap_or(0) as *mut c_void,
                    warn_slot.unwrap_or(0) as *mut c_void,
                    msg_hook,
                    warn_hook,
                )
            };
        }
    });
}

/// Preload the bundled `ffi/` shared objects (`libModelicaStandardTables.so` and
/// friends) `RTLD_GLOBAL`, once, so their symbols (`ModelicaStandardTables_*`,
/// `ModelicaIO_*`, …) resolve via `dlopen(NULL)`. Loaded leaf-first so each
/// library's `DT_NEEDED`/undefined refs resolve against the previous ones and the
/// already-`RTLD_GLOBAL` C runtime (which provides `ModelicaError` etc.). Called
/// after [`ensure_runtime_solibs`]. Missing libs are not an error.
fn ensure_ffi_solibs() {
    use std::sync::Once;
    static ONCE: Once = Once::new();
    ONCE.call_once(|| {
        let Ok(install_dir) = crate::Settings::getInstallationDirectoryPath() else { return };
        let ffi = format!("{install_dir}/lib/{}/omc/ffi", crate::Autoconf::triple);
        for lib in ["libModelicaMatIO.so", "libModelicaIO.so", "libModelicaExternalC.so", "libModelicaStandardTables.so"] {
            dl::open_global(&format!("{ffi}/{lib}"));
        }
    });
}

/// Initialise the C runtime once (`mmc_init`, a `threadData`) and pin
/// `libOpenModelicaRuntimeC` so it survives `freeLibrary`. Requires at least
/// one function library to be loaded (it provides the runtime symbols).
fn ensure_runtime(reg: &mut Registry) -> Result<()> {
    if reg.inited {
        return Ok(());
    }
    let &lib = reg.libs.values().next().ok_or_else(|| "executeFunction: no library loaded")?;
    let mmc_init = dlsym_addr(lib, "mmc_init").ok_or_else(|| "runtime symbol `mmc_init` not found")?;
    let gc_alloc = dlsym_addr(lib, "GC_malloc_uncollectable").ok_or_else(|| "runtime symbol `GC_malloc_uncollectable` not found")?;
    // Pin the runtime shared object: locate it from `mmc_init`'s address and
    // re-open it so later closes of function libraries leave the GC heap and
    // `threadData` valid.
    dl::pin_containing(mmc_init);
    unsafe {
        let init: extern "C" fn() = std::mem::transmute(mmc_init);
        init();
        let alloc: extern "C" fn(usize) -> *mut c_void = std::mem::transmute(gc_alloc);
        let td = alloc(THREADDATA_SIZE);
        if td.is_null() {
            return Err("executeFunction: threadData allocation failed");
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
