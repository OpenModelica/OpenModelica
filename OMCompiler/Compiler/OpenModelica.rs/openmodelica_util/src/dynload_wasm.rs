//! wasm implementation of [`crate::dynload`]. A wasm omc has no dlopen and no
//! native library to open: what it loads is a wasm shared library, run by the
//! engine the wasm-jit simulations use, so `external "C"` can still be evaluated
//! at compile time.
//!
//! That engine lives in `openmodelica_wasm_jit`, which depends on this crate, so
//! it installs itself with [`set_backend`] (from `omc_init`) rather than being
//! called from here. `-d=gen` has no wasm equivalent at all: [`function_addr`]
//! and [`thread_data`] stay unavailable.

use std::cell::RefCell;

use metamodelica::Result;

/// The loader, installed by `openmodelica_wasm_jit::ext_eval`. Handles are the
/// backend's; this module only routes. The error is a `String` so it can name the
/// module and the reason, which `searchLibraryPaths` prints through
/// [`last_load_error`].
#[derive(Clone, Copy)]
pub struct Backend {
    pub open: fn(&str, bool) -> std::result::Result<i32, String>,
    pub lookup: fn(i32, &str) -> std::result::Result<i32, String>,
    pub free_library: fn(i32),
    pub free_function: fn(i32),
}

thread_local! {
    static BACKEND: RefCell<Option<Backend>> = const { RefCell::new(None) };
    static LAST_ERROR: RefCell<String> = const { RefCell::new(String::new()) };
}

pub fn set_backend(backend: Backend) {
    BACKEND.with(|b| *b.borrow_mut() = Some(backend));
}

fn backend() -> Result<Backend> {
    match BACKEND.with(|b| *b.borrow()) {
        Some(b) => Ok(b),
        None => Err("System.loadLibrary: no wasm side-module loader is installed"),
    }
}

fn record(e: String) -> &'static str {
    LAST_ERROR.with(|l| *l.borrow_mut() = e);
    "System.loadLibrary: the wasm side module could not be loaded"
}

fn open(path: &str, lazy: bool) -> Result<i32> {
    LAST_ERROR.with(|l| l.borrow_mut().clear());
    (backend()?.open)(path, lazy).map_err(record)
}

pub fn load_library(path: &str, _relative: bool, _debug: bool) -> Result<i32> {
    open(path, false)
}

pub fn load_library_lazy(path: &str, _relative: bool, _debug: bool) -> Result<i32> {
    open(path, true)
}

/// `System.getLoadLibraryError`: why the last [`load_library`] failed.
pub fn last_load_error() -> String {
    LAST_ERROR.with(|l| l.borrow().clone())
}

pub fn lookup_function(lib: i32, name: &str) -> Result<i32> {
    (backend()?.lookup)(lib, name).map_err(record)
}

pub fn free_function(func: i32, _debug: bool) -> Result<()> {
    if let Ok(b) = backend() {
        (b.free_function)(func);
    }
    Ok(())
}

pub fn free_library(lib: i32, _debug: bool) -> Result<()> {
    if let Ok(b) = backend() {
        (b.free_library)(lib);
    }
    Ok(())
}

/// A side module's function is an engine handle, not an address in this process.
/// `FFI_wasm::callFunction` calls it through the backend instead.
pub fn function_addr(_func: i32) -> Result<usize> {
    return Err("dynload::function_addr: a wasm side module's function has no process address")
}

pub fn runtime_symbol(_name: &str) -> Option<usize> {
    None
}

pub fn thread_data() -> Result<usize> {
    return Err("dynload::thread_data: the dlopen'd MMC runtime is unavailable on wasm")
}
