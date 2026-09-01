//! The files a solver writes beside the result — C's `omc_fopen` under the model
//! prefix, e.g. the homotopy path CSV. With a host present the host writes them
//! (a JIT module has no file system); the standalone module writes them itself;
//! an FMU adapter build has no sink and drops them.

use alloc::string::String;
use core::cell::UnsafeCell;

struct PrefixCell(UnsafeCell<String>);
unsafe impl Sync for PrefixCell {}
static PREFIX: PrefixCell = PrefixCell(UnsafeCell::new(String::new()));

/// C's `modelData->modelFilePrefix`.
pub(crate) fn set_prefix(prefix: &str) {
    *unsafe { &mut *PREFIX.0.get() } = String::from(prefix);
}

pub(crate) fn prefix() -> &'static str {
    unsafe { &*PREFIX.0.get() }
}

/// [`set_prefix`] across the module boundary: `len` UTF-8 bytes at `ptr`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_set_file_prefix(ptr: u32, len: u32) {
    let bytes = unsafe { core::slice::from_raw_parts(ptr as *const u8, len as usize) };
    set_prefix(&String::from_utf8_lossy(bytes));
}

#[cfg(all(target_arch = "wasm32", feature = "host_log", not(feature = "standalone")))]
#[link(wasm_import_module = "env")]
unsafe extern "C" {
    fn rt_host_write_file(name: u32, name_len: u32, data: u32, data_len: u32);
}

/// Write `data` to `name`, relative to the working directory as C's executable does.
#[cfg(all(target_arch = "wasm32", feature = "host_log", not(feature = "standalone")))]
pub(crate) fn write_file(name: &str, data: &str) {
    unsafe { rt_host_write_file(name.as_ptr() as u32, name.len() as u32, data.as_ptr() as u32, data.len() as u32) };
}

#[cfg(all(target_arch = "wasm32", feature = "standalone"))]
pub(crate) fn write_file(name: &str, data: &str) {
    let _ = std::fs::write(name, data);
}

#[cfg(not(all(target_arch = "wasm32", any(feature = "standalone", all(feature = "host_log", not(feature = "standalone"))))))]
pub(crate) fn write_file(_name: &str, _data: &str) {}
