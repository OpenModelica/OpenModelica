//! The SimulationRuntime C ABI OMEdit uses for plotting/animation/formatting,
//! backed by the Rust port so OMEdit links no OpenModelica C runtime library:
//!
//!  * MATLAB v4 result reader (`omc_*matlab4*`) over `openmodelica_result_files::MatReader`,
//!  * CSV result reader (`read_csv`/`read_csv_dataset`) over `openmodelica_result_files::CsvReader`,
//!  * the realtime stopwatch (`rt_ext_tp_*`) OMEdit's animation TimeManager uses,
//!  * `ryu_hr_tdzp` number formatting (`StringHandler::number`).
//!
//! Single-threaded by the embedding contract. The matlab4 `ModelicaMatReader`
//! the C ABI exposes is only ever inspected by OMEdit through its `file` field
//! (open flag) and the accessor functions; we therefore mirror just that field
//! and stash a boxed Rust reader behind it (OMEdit owns the full-size struct).

use std::cell::RefCell;
use std::collections::HashMap;
use std::ffi::{CStr, CString, c_char, c_double, c_int, c_void};
use std::panic::catch_unwind;
use std::ptr;

use openmodelica_result_files::{CsvReader, MatReader};

// ───────────────────────────── MATLAB v4 reader ──────────────────────────────

/// Mirror of `ModelicaMatVariable_t` (read_matlab4.h). `name`/`descr` are
/// `malloc`'d C strings; `index` is the 1-based data column (sign selects the
/// negated alias), as in the C reader.
#[repr(C)]
pub struct ModelicaMatVariable_t {
    name: *mut c_char,
    descr: *mut c_char,
    isParam: c_int,
    /// Non-zero for a time-varying String variable, whose value lives in the
    /// `stringData` matrix and whose `index` is a string-signal number.
    isString: c_int,
    index: c_int,
}

/// Full mirror of `ModelicaMatReader` (read_matlab4.h) — the layout must match
/// exactly, because consumers (OMEdit, and especially libOMPlot) read several
/// fields directly: `file` (open flag / our reader handle), `nall`/`allInfo[]`
/// (variable enumeration), `nvar`/`nrows`. We repurpose `file` to hold the boxed
/// Rust [`ReaderState`] (non-null = open); the accessor functions go through it.
/// Fields consumers reach only via functions (`params`/`vars`/`var_offset`/…)
/// are left null/zero.
#[repr(C)]
struct ModelicaMatReader {
    file: *mut c_void,
    fileName: *mut c_char,
    nall: u32,
    allInfo: *mut ModelicaMatVariable_t,
    nparam: u32,
    startTime: c_double,
    stopTime: c_double,
    params: *mut c_double,
    nvar: u32,
    nrows: u32,
    var_offset: usize,
    readAll: c_int,
    vars: *mut *mut c_double,
    doublePrecision: c_char,
    /// String result support; consumers reach the values through
    /// [`omc_matlab4_read_string_val`], so these stay null/zero here.
    stringData: *mut c_char,
    stringMaxLen: u32,
    nStringSignals: u32,
    nStringRows: u32,
}

struct ReaderState {
    reader: MatReader,
    /// C variable descriptors, parallel to `reader.allInfo`; `find_var` returns
    /// pointers into this (stable for the reader's lifetime).
    vars: Vec<ModelicaMatVariable_t>,
    /// Trajectories handed out by `omc_matlab4_read_vals`, kept alive (the C ABI
    /// returns a reader-owned `double*` the caller does not free), keyed by the
    /// requested column index.
    cached: HashMap<c_int, Vec<f64>>,
    /// String values handed out by `omc_matlab4_read_string_val`, kept alive for
    /// the reader's lifetime as the C reader's `stringData` is, keyed by
    /// (variable, requested time).
    strings: HashMap<(usize, u64), CString>,
}

thread_local! {
    /// Error message returned by `omc_new_matlab4_reader` on failure (the C ABI
    /// returns a borrowed string). Valid until the next failing call.
    static MAT_ERR: RefCell<Option<CString>> = const { RefCell::new(None) };
}

/// `malloc`-allocate a C copy of `s` (so `omc_free_matlab4_reader` frees it with
/// `libc::free`).
unsafe fn dup_cstr(s: &str) -> *mut c_char {
    let c = CString::new(s).unwrap_or_default();
    unsafe { libc::strdup(c.as_ptr()) }
}

/// Open a MATLAB v4 result file. Returns null on success (populating `reader`),
/// or a borrowed error string on failure, matching the C ABI.
#[unsafe(no_mangle)]
pub extern "C" fn omc_new_matlab4_reader(
    filename: *const c_char,
    reader: *mut ModelicaMatReader,
) -> *const c_char {
    let fname = unsafe { CStr::from_ptr(filename) }.to_string_lossy().into_owned();
    match catch_unwind(|| MatReader::open(&fname)) {
        Ok(Ok(mut mr)) => {
            let vars: Vec<ModelicaMatVariable_t> = mr
                .allInfo
                .iter()
                .map(|v| ModelicaMatVariable_t {
                    name: unsafe { dup_cstr(&v.name) },
                    descr: unsafe { dup_cstr(&v.descr) },
                    isParam: v.isParam as c_int,
                    isString: v.isString as c_int,
                    index: v.index,
                })
                .collect();
            let (nall, nparam, nvar, nrows) =
                (vars.len() as u32, mr.nparam as u32, mr.nvar as u32, mr.nrows as u32);
            let (start, stop) = (mr.start_time(), mr.stop_time());
            let state = Box::new(ReaderState {
                reader: mr,
                vars,
                cached: HashMap::new(),
                strings: HashMap::new(),
            });
            let p = Box::into_raw(state);
            // Populate exactly the fields consumers read directly; the rest is
            // reached only through the accessor functions (which use `file`).
            unsafe {
                let r = &mut *reader;
                r.file = p as *mut c_void;
                r.allInfo = (*p).vars.as_mut_ptr();
                r.nall = nall;
                r.nparam = nparam;
                r.nvar = nvar;
                r.nrows = nrows;
                r.startTime = start;
                r.stopTime = stop;
                // Consumers (e.g. OMEdit's getVariableInformation) read this
                // directly and `strcmp` it, so it must be a valid C string like
                // the C reader's `omc_strdup(filename)`, not null.
                r.fileName = dup_cstr(&fname);
                r.params = ptr::null_mut();
                r.var_offset = 0;
                r.readAll = 0;
                r.vars = ptr::null_mut();
                r.doublePrecision = 0;
                r.stringData = ptr::null_mut();
                r.stringMaxLen = 0;
                r.nStringSignals = 0;
                r.nStringRows = 0;
            }
            ptr::null()
        }
        Ok(Err(e)) => {
            unsafe {
                (*reader).file = ptr::null_mut();
                (*reader).fileName = ptr::null_mut();
            }
            MAT_ERR.with(|c| {
                let msg = CString::new(e).unwrap_or_default();
                let p = msg.as_ptr();
                *c.borrow_mut() = Some(msg);
                p
            })
        }
        Err(_) => {
            unsafe {
                (*reader).file = ptr::null_mut();
                (*reader).fileName = ptr::null_mut();
            }
            c"matlab4 reader panicked".as_ptr()
        }
    }
}

/// Free a reader opened by [`omc_new_matlab4_reader`] (and its descriptors).
#[unsafe(no_mangle)]
pub extern "C" fn omc_free_matlab4_reader(reader: *mut ModelicaMatReader) {
    if reader.is_null() {
        return;
    }
    let p = unsafe { (*reader).file } as *mut ReaderState;
    if p.is_null() {
        return;
    }
    let state = unsafe { Box::from_raw(p) };
    for v in &state.vars {
        if !v.name.is_null() {
            unsafe { libc::free(v.name as *mut c_void) };
        }
        if !v.descr.is_null() {
            unsafe { libc::free(v.descr as *mut c_void) };
        }
    }
    drop(state);
    unsafe {
        // Mirror the C reader: free the malloc'd `fileName` set on open.
        let fname = (*reader).fileName;
        if !fname.is_null() {
            libc::free(fname as *mut c_void);
            (*reader).fileName = ptr::null_mut();
        }
        (*reader).file = ptr::null_mut();
    }
}

/// SAFETY helper: borrow the boxed state behind `reader.file`, or `None`.
unsafe fn state<'a>(reader: *mut ModelicaMatReader) -> Option<&'a mut ReaderState> {
    if reader.is_null() {
        return None;
    }
    let p = unsafe { (*reader).file } as *mut ReaderState;
    if p.is_null() { None } else { Some(unsafe { &mut *p }) }
}

/// Look up a variable by name; returns a pointer into the reader's descriptor
/// table (stable until the reader is freed), or null.
#[unsafe(no_mangle)]
pub extern "C" fn omc_matlab4_find_var(
    reader: *mut ModelicaMatReader,
    var_name: *const c_char,
) -> *mut ModelicaMatVariable_t {
    let Some(st) = (unsafe { state(reader) }) else { return ptr::null_mut() };
    let name = unsafe { CStr::from_ptr(var_name) }.to_string_lossy();
    match st.reader.find_var(&name) {
        Some(i) => &mut st.vars[i] as *mut ModelicaMatVariable_t,
        None => ptr::null_mut(),
    }
}

/// Read a whole column trajectory by data index. Returns a reader-owned
/// `double*` (cached; the caller must not free it), or null.
#[unsafe(no_mangle)]
pub extern "C" fn omc_matlab4_read_vals(
    reader: *mut ModelicaMatReader,
    var_index: c_int,
) -> *mut c_double {
    let Some(st) = (unsafe { state(reader) }) else { return ptr::null_mut() };
    if !st.cached.contains_key(&var_index) {
        let vals = st.reader.read_vals(var_index).unwrap_or_default();
        st.cached.insert(var_index, vals);
    }
    st.cached.get(&var_index).unwrap().as_ptr() as *mut c_double
}

/// Interpolate the value of `var` at `time` into `*res`. Returns 0 on success,
/// non-zero on failure (matching the C `omc_matlab4_val`).
#[unsafe(no_mangle)]
pub extern "C" fn omc_matlab4_val(
    res: *mut c_double,
    reader: *mut ModelicaMatReader,
    var: *mut ModelicaMatVariable_t,
    time: c_double,
) -> c_int {
    let Some(st) = (unsafe { state(reader) }) else { return 1 };
    if var.is_null() {
        return 1;
    }
    // `var` points into `st.vars`; recover its index by offset.
    let base = st.vars.as_ptr();
    let i = (var as usize).wrapping_sub(base as usize)
        / std::mem::size_of::<ModelicaMatVariable_t>();
    if i >= st.vars.len() {
        return 1;
    }
    match st.reader.val(i, time) {
        Some(v) => {
            unsafe { *res = v };
            0
        }
        None => 1,
    }
}

/// The value of a time-varying String variable at `time`, as a reader-owned C
/// string (valid until the reader is freed, as the C reader's pointer into
/// `stringData` is), or null when `var` is not a String variable. A String is a
/// step-like display value, so this is the value at the row at or just before
/// `time`, not an interpolation.
#[unsafe(no_mangle)]
pub extern "C" fn omc_matlab4_read_string_val(
    reader: *mut ModelicaMatReader,
    var: *mut ModelicaMatVariable_t,
    time: c_double,
) -> *const c_char {
    let Some(st) = (unsafe { state(reader) }) else { return ptr::null() };
    if var.is_null() {
        return ptr::null();
    }
    // `var` points into `st.vars`; recover its index by offset.
    let base = st.vars.as_ptr();
    let i = (var as usize).wrapping_sub(base as usize)
        / std::mem::size_of::<ModelicaMatVariable_t>();
    if i >= st.vars.len() {
        return ptr::null();
    }
    let key = (i, time.to_bits());
    if !st.strings.contains_key(&key) {
        let Some(s) = st.reader.read_string_val(i, time) else { return ptr::null() };
        let Ok(c) = CString::new(s) else { return ptr::null() };
        st.strings.insert(key, c);
    }
    st.strings.get(&key).unwrap().as_ptr()
}

/// Interpolate `n` variables at `time` into `res[0..n]` (libOMPlot's parametric
/// path). Returns 0 on success, non-zero if any lookup fails.
#[unsafe(no_mangle)]
pub extern "C" fn omc_matlab4_read_vars_val(
    res: *mut c_double,
    reader: *mut ModelicaMatReader,
    var: *mut *mut ModelicaMatVariable_t,
    n: c_int,
    time: c_double,
) -> c_int {
    for k in 0..n as isize {
        let v = unsafe { *var.offset(k) };
        if omc_matlab4_val(unsafe { res.offset(k) }, reader, v, time) != 0 {
            return 1;
        }
    }
    0
}

/// Print every variable name to `stream` (debug aid; OMEdit's animation path
/// calls it). Mirrors the C `omc_matlab4_print_all_vars` loosely.
#[unsafe(no_mangle)]
pub extern "C" fn omc_matlab4_print_all_vars(stream: *mut c_void, reader: *mut ModelicaMatReader) {
    let Some(st) = (unsafe { state(reader) }) else { return };
    let f = stream as *mut libc::FILE;
    if f.is_null() {
        return;
    }
    for v in &st.vars {
        if !v.name.is_null() {
            unsafe {
                libc::fputs(v.name, f);
                libc::fputc(b'\n' as c_int, f);
            }
        }
    }
}

/// Start time of the contained time series.
#[unsafe(no_mangle)]
pub extern "C" fn omc_matlab4_startTime(reader: *mut ModelicaMatReader) -> c_double {
    match unsafe { state(reader) } {
        Some(st) => st.reader.start_time(),
        None => f64::NAN,
    }
}

/// Stop time of the contained time series.
#[unsafe(no_mangle)]
pub extern "C" fn omc_matlab4_stopTime(reader: *mut ModelicaMatReader) -> c_double {
    match unsafe { state(reader) } {
        Some(st) => st.reader.stop_time(),
        None => f64::NAN,
    }
}

// ─────────────────────────────── CSV reader ──────────────────────────────────

/// What the opaque `struct csv_data*` points at: the reader plus the `char**`
/// arrays [`read_csv_dataset_str`] hands out, which the C ABI keeps alive for
/// the reader's lifetime.
struct CsvState {
    reader: CsvReader,
    strings: HashMap<String, (Vec<CString>, Vec<*mut c_char>)>,
}

fn csv_open(filename: *const c_char, keep_strings: bool) -> *mut c_void {
    let fname = unsafe { CStr::from_ptr(filename) }.to_string_lossy().into_owned();
    let open = || if keep_strings { CsvReader::open_all(&fname) } else { CsvReader::open(&fname) };
    match catch_unwind(open) {
        Ok(Ok(reader)) => {
            Box::into_raw(Box::new(CsvState { reader, strings: HashMap::new() })) as *mut c_void
        }
        _ => ptr::null_mut(),
    }
}

/// Open a CSV result file. Returns an opaque `struct csv_data*` (a boxed
/// [`CsvState`]) or null on failure, matching the C `read_csv`.
#[unsafe(no_mangle)]
pub extern "C" fn read_csv(filename: *const c_char) -> *mut c_void {
    csv_open(filename, false)
}

/// `read_csv_all`: like [`read_csv`] but keeps the String columns readable
/// through [`read_csv_dataset_str`] instead of failing on them.
#[unsafe(no_mangle)]
pub extern "C" fn read_csv_all(filename: *const c_char) -> *mut c_void {
    csv_open(filename, true)
}

/// Return the trajectory of `var` as a reader-owned `double*` (the caller does
/// not free it), or null. Mirrors the C `read_csv_dataset`.
#[unsafe(no_mangle)]
pub extern "C" fn read_csv_dataset(data: *mut c_void, var: *const c_char) -> *mut c_double {
    if data.is_null() {
        return ptr::null_mut();
    }
    let st = unsafe { &*(data as *const CsvState) };
    let name = unsafe { CStr::from_ptr(var) }.to_string_lossy();
    match st.reader.dataset(&name) {
        Some(s) => s.as_ptr() as *mut c_double,
        None => ptr::null_mut(),
    }
}

/// The `numsteps` String values of a String column as a reader-owned `char**`
/// (the caller frees neither), or null when `var` is not a String column or the
/// file was opened with [`read_csv`]. Mirrors the C `read_csv_dataset_str`.
#[unsafe(no_mangle)]
pub extern "C" fn read_csv_dataset_str(data: *mut c_void, var: *const c_char) -> *mut *mut c_char {
    if data.is_null() {
        return ptr::null_mut();
    }
    let st = unsafe { &mut *(data as *mut CsvState) };
    let name = unsafe { CStr::from_ptr(var) }.to_string_lossy().into_owned();
    if !st.strings.contains_key(&name) {
        let Some(vals) = st.reader.dataset_str(&name) else { return ptr::null_mut() };
        let owned: Vec<CString> =
            vals.iter().map(|v| CString::new(v.as_str()).unwrap_or_default()).collect();
        let ptrs: Vec<*mut c_char> = owned.iter().map(|c| c.as_ptr() as *mut c_char).collect();
        st.strings.insert(name.clone(), (owned, ptrs));
    }
    st.strings.get_mut(&name).unwrap().1.as_mut_ptr()
}

/// Free a reader returned by [`read_csv`] / [`read_csv_all`].
#[unsafe(no_mangle)]
pub extern "C" fn omc_free_csv_reader(data: *mut c_void) {
    if !data.is_null() {
        unsafe { drop(Box::from_raw(data as *mut CsvState)) };
    }
}

// ────────────────────────── realtime stopwatch ───────────────────────────────

/// Mirror of the non-Windows `rtclock_t` (`union { struct timespec; unsigned
/// long long; }` — 16 bytes); we use the timespec view.
#[repr(C)]
pub struct rtclock_t {
    tv_sec: i64,
    tv_nsec: i64,
}

/// Process-global monotonic origin. `rtclock_t` stores the elapsed time since
/// this origin (decomposed into sec/nsec), so tick/tock measure a relative
/// interval — all OMEdit's TimeManager needs. `Instant` is monotonic on every
/// platform, avoiding a POSIX `clock_gettime` (absent on Windows libc).
fn rt_clock_origin() -> std::time::Instant {
    static ORIGIN: std::sync::OnceLock<std::time::Instant> = std::sync::OnceLock::new();
    *ORIGIN.get_or_init(std::time::Instant::now)
}

/// Record the current (monotonic) time into `*tp` — OMEdit's animation
/// TimeManager uses this to pace real-time playback.
#[unsafe(no_mangle)]
pub extern "C" fn rt_ext_tp_tick_realtime(tp: *mut rtclock_t) {
    if tp.is_null() {
        return;
    }
    let d = rt_clock_origin().elapsed();
    unsafe {
        (*tp).tv_sec = d.as_secs() as i64;
        (*tp).tv_nsec = d.subsec_nanos() as i64;
    }
}

/// Seconds elapsed since the [`rt_ext_tp_tick_realtime`] stored in `*tp`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_ext_tp_tock(tp: *mut rtclock_t) -> c_double {
    if tp.is_null() {
        return 0.0;
    }
    let now = rt_clock_origin().elapsed().as_secs_f64();
    let (s, ns) = unsafe { ((*tp).tv_sec, (*tp).tv_nsec) };
    now - (s as c_double + ns as c_double * 1e-9)
}

// ─────────────────────────── number formatting ───────────────────────────────

/// `char* ryu_hr_tdzp(double)` — OMEdit-style shortest number formatting
/// (`StringHandler::number`). Returns a `malloc`'d string the caller frees with
/// `free()`.
#[unsafe(no_mangle)]
pub extern "C" fn ryu_hr_tdzp(d: c_double) -> *mut c_char {
    let s = metamodelica::ryu_hr_tdzp(d);
    let bytes = s.as_bytes();
    unsafe {
        let buf = libc::malloc(bytes.len() + 1) as *mut u8;
        if buf.is_null() {
            return ptr::null_mut();
        }
        ptr::copy_nonoverlapping(bytes.as_ptr(), buf, bytes.len());
        *buf.add(bytes.len()) = 0;
        buf as *mut c_char
    }
}
