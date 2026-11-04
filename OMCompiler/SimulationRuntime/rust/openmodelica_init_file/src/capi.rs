//! The C ABI, see `include/omc_init_file.h`.

use std::ffi::{CStr, CString, c_char};
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::ptr;

use crate::InitFile;

fn to_c(s: String) -> *mut c_char {
    CString::new(s.replace('\0', " ")).unwrap_or_default().into_raw()
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_init_file_text(path: *const c_char, error: *mut *mut c_char) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| {
        if path.is_null() {
            return Err("no file name".to_string());
        }
        let path = unsafe { CStr::from_ptr(path) }.to_string_lossy();
        InitFile::read(&path).map(|f| f.to_text())
    }))
    .unwrap_or_else(|_| Err("internal error".into()));
    match result {
        Ok(text) => to_c(text),
        Err(e) => {
            if !error.is_null() {
                unsafe { *error = to_c(e) };
            }
            ptr::null_mut()
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_init_free_string(s: *mut c_char) {
    if !s.is_null() {
        drop(unsafe { CString::from_raw(s) });
    }
}
