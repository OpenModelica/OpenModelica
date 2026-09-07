//! `omc_result_*`: the C ABI declared in `include/omc_result.h`, over
//! `openmodelica_result_files::ResultFile`; the writers for the C simulation
//! runtime are in [`writer`]. One reader is used from one thread
//! at a time (the embedding contract OMEdit's other readers follow). Strings
//! returned as `char*` are `malloc`'d for `omc_result_free_string`; `const
//! char*` and `const double*` results are owned by the reader and live until it
//! is closed.

use std::collections::HashMap;
use std::ffi::{CStr, CString, c_char, c_double, c_int, c_uint};
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::ptr;

use openmodelica_result_files::file::{self, ResultFile, Tolerances, TubeDiff};

pub mod writer;

#[allow(non_camel_case_types)]
pub struct omc_result {
    file: ResultFile,
    names: Vec<CString>,
    compared: Vec<CString>,
    time_name: CString,
    trajectories: HashMap<String, Vec<f64>>,
    /// A String variable's texts and the pointer array handed out over them.
    strings: HashMap<String, (Vec<CString>, Vec<*const c_char>)>,
}

#[repr(C)]
#[derive(Clone, Copy)]
pub struct omc_result_tolerances {
    pub reltol: c_double,
    pub reltol_diff_min_max: c_double,
    pub range_delta: c_double,
}

/// One variable's tube comparison; the arrays live until `omc_result_tube_free`.
#[repr(C)]
pub struct omc_result_tube {
    pub differs: c_int,
    /// Length of `time`, `reference`, `actual`, `high` and `low`.
    pub n: usize,
    pub time: *const c_double,
    pub reference: *const c_double,
    pub actual: *const c_double,
    pub high: *const c_double,
    pub low: *const c_double,
    pub n_error: usize,
    pub error: *const c_double,
    /// Length of `actual_time` and `actual_original`.
    pub n_actual: usize,
    pub actual_time: *const c_double,
    pub actual_original: *const c_double,
    pub abstol: c_double,
}

#[repr(C)]
struct TubeOwner {
    view: omc_result_tube,
    data: TubeDiff,
}

fn cstr(p: *const c_char) -> String {
    if p.is_null() { String::new() } else { unsafe { CStr::from_ptr(p) }.to_string_lossy().into_owned() }
}

pub(crate) fn malloc_str(s: &str) -> *mut c_char {
    let c = CString::new(s.replace('\0', " ")).unwrap_or_default();
    unsafe { libc::strdup(c.as_ptr()) }
}

pub(crate) fn set_error(error: *mut *mut c_char, msg: &str) {
    if !error.is_null() {
        unsafe { *error = malloc_str(msg) };
    }
}

fn names(vars: *const *const c_char, n: usize) -> Vec<String> {
    if vars.is_null() { Vec::new() } else { (0..n).map(|i| cstr(unsafe { *vars.add(i) })).collect() }
}

fn guard<T>(fallback: T, f: impl FnOnce() -> T) -> T {
    catch_unwind(AssertUnwindSafe(f)).unwrap_or(fallback)
}

impl omc_result_tolerances {
    fn get(p: *const omc_result_tolerances) -> Tolerances {
        if p.is_null() {
            return Tolerances::default();
        }
        let t = unsafe { *p };
        Tolerances { reltol: t.reltol, reltol_diff_min_max: t.reltol_diff_min_max, range_delta: t.range_delta }
    }
}

/// Open `path` (format by suffix). Null on failure, with `*error` set when
/// `error` is given.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_open(path: *const c_char, error: *mut *mut c_char) -> *mut omc_result {
    guard(ptr::null_mut(), || match ResultFile::open(&cstr(path)) {
        Ok(file) => {
            let to_c = |n: String| CString::new(n.replace('\0', " ")).unwrap_or_default();
            let names = file.variables().into_iter().map(to_c).collect();
            let compared = file.compared_variables().into_iter().map(to_c).collect();
            let time_name = CString::new(file.time_name()).unwrap_or_default();
            Box::into_raw(Box::new(omc_result { file, names, compared, time_name, trajectories: HashMap::new(), strings: HashMap::new() }))
        }
        Err(e) => {
            set_error(error, &e);
            ptr::null_mut()
        }
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_close(r: *mut omc_result) {
    if !r.is_null() {
        drop(unsafe { Box::from_raw(r) });
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe { libc::free(s.cast()) };
    }
}

/// Frees an array of `n` strings from `omc_result_diff`.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_free_strings(s: *mut *mut c_char, n: usize) {
    if s.is_null() {
        return;
    }
    for i in 0..n {
        omc_result_free_string(unsafe { *s.add(i) });
    }
    unsafe { libc::free(s.cast()) };
}

fn with<T>(r: *const omc_result, fallback: T, f: impl FnOnce(&omc_result) -> T) -> T {
    if r.is_null() { fallback } else { guard(fallback, || f(unsafe { &*r })) }
}

fn with_mut<T>(r: *mut omc_result, fallback: T, f: impl FnOnce(&mut omc_result) -> T) -> T {
    if r.is_null() { fallback } else { guard(fallback, || f(unsafe { &mut *r })) }
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_num_variables(r: *const omc_result) -> usize {
    with(r, 0, |r| r.names.len())
}

/// The `i`th variable name (parameters and aliases included); null past the end.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_variable_name(r: *const omc_result, i: usize) -> *const c_char {
    with(r, ptr::null(), |r| r.names.get(i).map_or(ptr::null(), |n| n.as_ptr()))
}

/// The variables `omc_result_diff` compares when given none: the real
/// (non-alias) variables and parameters.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_num_compared_variables(r: *const omc_result) -> usize {
    with(r, 0, |r| r.compared.len())
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_compared_variable_name(r: *const omc_result, i: usize) -> *const c_char {
    with(r, ptr::null(), |r| r.compared.get(i).map_or(ptr::null(), |n| n.as_ptr()))
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_has_variable(r: *const omc_result, var: *const c_char) -> c_int {
    with(r, 0, |r| c_int::from(r.file.has_variable(&cstr(var))))
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_is_parameter(r: *const omc_result, var: *const c_char) -> c_int {
    with(r, 0, |r| c_int::from(r.file.is_parameter(&cstr(var))))
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_description(r: *const omc_result, var: *const c_char) -> *mut c_char {
    with(r, ptr::null_mut(), |r| malloc_str(&r.file.description(&cstr(var))))
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_unit(r: *const omc_result, var: *const c_char) -> *mut c_char {
    with(r, ptr::null_mut(), |r| malloc_str(&r.file.unit(&cstr(var))))
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_display_unit(r: *const omc_result, var: *const c_char) -> *mut c_char {
    with(r, ptr::null_mut(), |r| malloc_str(&r.file.display_unit(&cstr(var))))
}

/// `Real`, `Integer`, `Boolean` or `String`.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_type(r: *const omc_result, var: *const c_char) -> *mut c_char {
    with(r, ptr::null_mut(), |r| malloc_str(&r.file.var_type(&cstr(var))))
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_num_rows(r: *const omc_result) -> usize {
    with(r, 0, |r| r.file.nrows())
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_time_name(r: *const omc_result) -> *const c_char {
    with(r, ptr::null(), |r| r.time_name.as_ptr())
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_start_time(r: *mut omc_result) -> c_double {
    with_mut(r, f64::NAN, |r| r.file.start_time())
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_stop_time(r: *mut omc_result) -> c_double {
    with_mut(r, f64::NAN, |r| r.file.stop_time())
}

/// The trajectory of `var` over every row (a parameter repeats its value),
/// `*len` values; null if it cannot be read. Owned by the reader.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_trajectory(r: *mut omc_result, var: *const c_char, len: *mut usize) -> *const c_double {
    with_mut(r, ptr::null(), |r| {
        let var = cstr(var);
        if !r.trajectories.contains_key(&var) {
            let Some(v) = r.file.trajectory(&var) else { return ptr::null() };
            r.trajectories.insert(var.clone(), v);
        }
        let v = &r.trajectories[&var];
        if !len.is_null() {
            unsafe { *len = v.len() };
        }
        v.as_ptr()
    })
}

/// A String variable's text per row (`*len` entries), owned by the reader; null
/// unless the file stores Strings and `var` is one.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_strings(r: *mut omc_result, var: *const c_char, len: *mut usize) -> *const *const c_char {
    with_mut(r, ptr::null(), |r| {
        let var = cstr(var);
        if !r.strings.contains_key(&var) {
            let Some(v) = r.file.strings(&var) else { return ptr::null() };
            let owned: Vec<CString> = v.iter().map(|s| CString::new(s.replace('\0', " ")).unwrap_or_default()).collect();
            let ptrs = owned.iter().map(|c| c.as_ptr()).collect();
            r.strings.insert(var.clone(), (owned, ptrs));
        }
        let (_, ptrs) = &r.strings[&var];
        if !len.is_null() {
            unsafe { *len = ptrs.len() };
        }
        ptrs.as_ptr()
    })
}

/// The text of String `var` at `time`, `malloc`'d for `omc_result_free_string`;
/// null unless `var` is a String with a value there.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_string_at(r: *mut omc_result, var: *const c_char, time: c_double) -> *mut c_char {
    with_mut(r, ptr::null_mut(), |r| r.file.string_at(&cstr(var), time).map_or(ptr::null_mut(), |s| malloc_str(&s)))
}

/// `*out = val(var, time)`; 0 if the variable cannot be read there.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_value_at(r: *mut omc_result, var: *const c_char, time: c_double, out: *mut c_double) -> c_int {
    with_mut(r, 0, |r| match r.file.value_at(&cstr(var), time) {
        Some(v) => {
            if !out.is_null() {
                unsafe { *out = v };
            }
            1
        }
        None => 0,
    })
}

/// Write `path` (format by suffix: .mat, .arrow, .csv) with `n` `vars` (all
/// when `n` is 0), resampled onto `intervals` steps unless 0, reals as f32 when
/// `single`. 1 on success.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_write(
    r: *mut omc_result,
    path: *const c_char,
    vars: *const *const c_char,
    n: usize,
    intervals: c_uint,
    single: c_int,
    error: *mut *mut c_char,
) -> c_int {
    with_mut(r, 0, |r| {
        let path = cstr(path);
        let suffix = path.rsplit('.').next().unwrap_or("");
        let written = r.file.write(suffix, names(vars, n), intervals, single != 0).and_then(|bytes| std::fs::write(&path, bytes).map_err(|e| format!("{path}: {e}")));
        match written {
            Ok(()) => 1,
            Err(e) => {
                set_error(error, &e);
                0
            }
        }
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_default_tolerances() -> omc_result_tolerances {
    let t = Tolerances::default();
    omc_result_tolerances { reltol: t.reltol, reltol_diff_min_max: t.reltol_diff_min_max, range_delta: t.range_delta }
}

/// `diffSimulationResults`: the names of the `n` `vars` (the reference's
/// compared variables when `n` is 0) whose trajectory in `actual` leaves the
/// tube around `reference`, `*n_out` of them, to free with
/// `omc_result_free_strings`. Null with `*error` set on failure (`tol` null
/// means the defaults).
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_diff(
    actual: *mut omc_result,
    reference: *mut omc_result,
    vars: *const *const c_char,
    n: usize,
    tol: *const omc_result_tolerances,
    n_out: *mut usize,
    error: *mut *mut c_char,
) -> *mut *mut c_char {
    if actual.is_null() || reference.is_null() || n_out.is_null() {
        return ptr::null_mut();
    }
    guard(ptr::null_mut(), || {
        let (a, r) = unsafe { (&mut *actual, &mut *reference) };
        match file::diff_all(&mut a.file, &mut r.file, names(vars, n), omc_result_tolerances::get(tol)) {
            Ok(list) => {
                unsafe { *n_out = list.len() };
                let arr = unsafe { libc::malloc(list.len().max(1) * size_of::<*mut c_char>()) } as *mut *mut c_char;
                for (i, name) in list.iter().enumerate() {
                    unsafe { *arr.add(i) = malloc_str(name) };
                }
                arr
            }
            Err(e) => {
                set_error(error, &e);
                ptr::null_mut()
            }
        }
    })
}

/// One variable's tube comparison; null with `*error` set on failure.
#[unsafe(no_mangle)]
pub extern "C" fn omc_result_diff_variable(
    actual: *mut omc_result,
    reference: *mut omc_result,
    var: *const c_char,
    tol: *const omc_result_tolerances,
    error: *mut *mut c_char,
) -> *mut omc_result_tube {
    if actual.is_null() || reference.is_null() {
        return ptr::null_mut();
    }
    guard(ptr::null_mut(), || {
        let (a, r) = unsafe { (&mut *actual, &mut *reference) };
        match file::diff_variable(&mut a.file, &mut r.file, &cstr(var), omc_result_tolerances::get(tol)) {
            Ok(data) => {
                let view = omc_result_tube {
                    differs: c_int::from(data.differs),
                    n: data.time.len(),
                    time: data.time.as_ptr(),
                    reference: data.reference.as_ptr(),
                    actual: data.actual.as_ptr(),
                    high: data.high.as_ptr(),
                    low: data.low.as_ptr(),
                    n_error: data.error.len(),
                    error: data.error.as_ptr(),
                    n_actual: data.actual_time.len(),
                    actual_time: data.actual_time.as_ptr(),
                    actual_original: data.actual_original.as_ptr(),
                    abstol: data.abstol,
                };
                Box::into_raw(Box::new(TubeOwner { view, data })).cast()
            }
            Err(e) => {
                set_error(error, &e);
                ptr::null_mut()
            }
        }
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn omc_result_tube_free(t: *mut omc_result_tube) {
    if !t.is_null() {
        drop(unsafe { Box::from_raw(t.cast::<TubeOwner>()) });
    }
}
