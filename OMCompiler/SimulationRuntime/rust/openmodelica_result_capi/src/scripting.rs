//! `omc_result_script_*`: the scripting API's result-file functions
//! (`openmodelica_result_files::scripting`) for the C omc.

use std::ffi::{CString, c_char, c_double, c_int, c_void};
use std::ptr;

use openmodelica_result_files::scripting::{self, Messages, Severity};

use crate::{cstr, guard, malloc_str, names};

#[allow(non_camel_case_types)]
pub type omc_result_message_fn =
    extern "C" fn(data: *mut c_void, severity: c_int, format: *const c_char, tokens: *const *const c_char, n: usize);

#[allow(non_camel_case_types)]
#[repr(C)]
pub struct omc_result_messages {
    pub add: Option<omc_result_message_fn>,
    pub data: *mut c_void,
}

struct Sink(*const omc_result_messages);

impl Messages for Sink {
    fn add(&mut self, severity: Severity, format: &str, tokens: &[&str]) {
        let Some(m) = (unsafe { self.0.as_ref() }) else {
            return;
        };
        let Some(add) = m.add else {
            return;
        };
        let c = |s: &str| CString::new(s.replace('\0', " ")).unwrap_or_default();
        let format = c(format);
        let tokens: Vec<CString> = tokens.iter().map(|t| c(t)).collect();
        let ptrs: Vec<*const c_char> = tokens.iter().map(|t| t.as_ptr()).collect();
        let severity = match severity {
            Severity::Error => 0,
            Severity::Warning => 1,
            Severity::Notification => 2,
        };
        add(m.data, severity, format.as_ptr(), ptrs.as_ptr(), ptrs.len());
    }
}

fn malloc_strings(list: &[String], n_out: *mut usize) -> *mut *mut c_char {
    unsafe { *n_out = list.len() };
    let arr = unsafe { libc::malloc(list.len().max(1) * size_of::<*mut c_char>()) } as *mut *mut c_char;
    if !arr.is_null() {
        for (i, s) in list.iter().enumerate() {
            unsafe { *arr.add(i) = malloc_str(s) };
        }
    }
    arr
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_script_close() {
    guard((), scripting::close);
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_script_val(
    msgs: *const omc_result_messages,
    filename: *const c_char,
    var: *const c_char,
    time: c_double,
) -> c_double {
    guard(f64::NAN, || {
        scripting::val(&mut Sink(msgs), &cstr(filename), &cstr(var), time)
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_script_variables(
    msgs: *const omc_result_messages,
    filename: *const c_char,
    parameters: c_int,
    omc_style: c_int,
    n_out: *mut usize,
) -> *mut *mut c_char {
    if n_out.is_null() {
        return ptr::null_mut();
    }
    guard(ptr::null_mut(), || {
        let vars = scripting::read_variables(&mut Sink(msgs), &cstr(filename), parameters != 0, omc_style != 0);
        malloc_strings(&vars, n_out)
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_script_size(msgs: *const omc_result_messages, filename: *const c_char) -> c_int {
    guard(-1, || scripting::read_size(&mut Sink(msgs), &cstr(filename)))
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_script_dataset(
    msgs: *const omc_result_messages,
    filename: *const c_char,
    vars: *const *const c_char,
    n: usize,
    dimsize: c_int,
    n_rows: *mut usize,
) -> *mut c_double {
    if n_rows.is_null() {
        return ptr::null_mut();
    }
    guard(ptr::null_mut(), || {
        let Some(rows) = scripting::read_dataset(&mut Sink(msgs), &cstr(filename), &names(vars, n), dimsize) else {
            return ptr::null_mut();
        };
        let len = rows.first().map_or(0, Vec::len);
        unsafe { *n_rows = len };
        let out = unsafe { libc::malloc((n * len).max(1) * size_of::<c_double>()) } as *mut c_double;
        if !out.is_null() {
            for (i, row) in rows.iter().enumerate() {
                unsafe { ptr::copy_nonoverlapping(row.as_ptr(), out.add(i * len), len) };
            }
        }
        out
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_script_compare(
    msgs: *const omc_result_messages,
    running_testsuite: c_int,
    filename: *const c_char,
    reffilename: *const c_char,
    logfile: *const c_char,
    reltol: c_double,
    abstol: c_double,
    vars: *const *const c_char,
    n: usize,
    n_out: *mut usize,
) -> *mut *mut c_char {
    if n_out.is_null() {
        return ptr::null_mut();
    }
    guard(ptr::null_mut(), || {
        match scripting::compare(
            &mut Sink(msgs),
            running_testsuite != 0,
            &cstr(filename),
            &cstr(reffilename),
            &cstr(logfile),
            reltol,
            abstol,
            &names(vars, n),
        ) {
            Some(res) => malloc_strings(&res, n_out),
            None => ptr::null_mut(),
        }
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_script_delta(
    msgs: *const omc_result_messages,
    filename: *const c_char,
    reffilename: *const c_char,
    method: *const c_char,
    vars: *const *const c_char,
    n: usize,
) -> c_double {
    guard(-1.0, || {
        scripting::delta(
            &mut Sink(msgs),
            &cstr(filename),
            &cstr(reffilename),
            &cstr(method),
            &names(vars, n),
        )
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_script_diff(
    msgs: *const omc_result_messages,
    running_testsuite: c_int,
    filename: *const c_char,
    reffilename: *const c_char,
    prefix: *const c_char,
    reltol: c_double,
    reltol_diff_max_min: c_double,
    range_delta: c_double,
    vars: *const *const c_char,
    n: usize,
    keep_equal_results: c_int,
    success: *mut c_int,
    n_out: *mut usize,
) -> *mut *mut c_char {
    if n_out.is_null() || success.is_null() {
        return ptr::null_mut();
    }
    guard(ptr::null_mut(), || {
        let (ok, res) = scripting::diff(
            &mut Sink(msgs),
            running_testsuite != 0,
            &cstr(filename),
            &cstr(reffilename),
            &cstr(prefix),
            reltol,
            reltol_diff_max_min,
            range_delta,
            &names(vars, n),
            keep_equal_results != 0,
        );
        unsafe { *success = c_int::from(ok) };
        malloc_strings(&res, n_out)
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_script_diff_html(
    msgs: *const omc_result_messages,
    running_testsuite: c_int,
    var: *const c_char,
    filename: *const c_char,
    reffilename: *const c_char,
    reltol: c_double,
    reltol_diff_max_min: c_double,
    range_delta: c_double,
) -> *mut c_char {
    guard(ptr::null_mut(), || {
        scripting::diff_html(
            &mut Sink(msgs),
            running_testsuite != 0,
            &cstr(var),
            &cstr(filename),
            &cstr(reffilename),
            reltol,
            reltol_diff_max_min,
            range_delta,
        )
        .map_or(ptr::null_mut(), |html| malloc_str(&html))
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_script_filter(
    msgs: *const omc_result_messages,
    in_file: *const c_char,
    out_file: *const c_char,
    vars: *const *const c_char,
    n: usize,
    intervals: c_int,
    remove_description: c_int,
) -> c_int {
    guard(0, || {
        c_int::from(scripting::filter(
            &mut Sink(msgs),
            &cstr(in_file),
            &cstr(out_file),
            &names(vars, n),
            intervals,
            remove_description != 0,
        ))
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_free_doubles(p: *mut c_double) {
    unsafe { libc::free(p.cast()) };
}
