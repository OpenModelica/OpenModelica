//! `modelInfoGetEquation`: the `<Model>_info.json` reader.
//!
//! Port of `simulation_info_json.c`'s equation half. Every generated nonlinear
//! residual names its iteration variables through it on an inf/nan, so the symbol
//! has to exist for such a model to link at all; `LOG_NLS`, the homotopy path CSV
//! and the Newton diagnostics then read the same list.
//!
//! Read lazily and once, as C does, and never freed: the strings are handed out as
//! `const char*` the generated code keeps no ownership of.

use core::ffi::{c_char, c_int};

use openmodelica_solvers::omclog;

use crate::abi::*;

/// One equation's decoded entry. The `CString`s and the `*const c_char` array over
/// them are leaked with the table, so a handed-out `EQUATION_INFO` stays valid.
struct Entry {
    section: c_int,
    vars: Vec<*const c_char>,
    uses: Vec<*const c_char>,
}

struct Table {
    entries: Vec<Entry>,
}

struct TableCell(core::cell::UnsafeCell<Option<Table>>);
// A simulation executable runs one model on one thread, as the C runtime does.
unsafe impl Sync for TableCell {}
static TABLE: TableCell = TableCell(core::cell::UnsafeCell::new(None));

/// The empty entry C hands back for a model with no `_info.json` (`--fmiFilter`
/// strips it) or an index out of range.
fn dummy() -> EQUATION_INFO {
    // The generated residual reads `vars[i]` before it knows `numVar`, so the
    // dummy still has to point somewhere: one empty string, as C's does.
    struct Empty([*const c_char; 1]);
    unsafe impl Sync for Empty {}
    static EMPTY: Empty = Empty([c"".as_ptr()]);
    EQUATION_INFO {
        id: -1,
        section: EQUATION_SECTION_UNKNOWN,
        profileBlockIndex: 0,
        parent: 0,
        numVar: -1,
        vars: EMPTY.0.as_ptr(),
        numVarUsed: 0,
        varsUsed: core::ptr::null(),
    }
}

fn leak_str(s: &str) -> *const c_char {
    let c = std::ffi::CString::new(s).unwrap_or_default();
    Box::leak(c.into_boxed_c_str()).as_ptr()
}

fn section_code(s: Option<&str>) -> c_int {
    match s {
        Some("initial-lambda0") => EQUATION_SECTION_INIT_LAMBDA0,
        Some("initial") => EQUATION_SECTION_INITIAL,
        Some("regular") => EQUATION_SECTION_REGULAR,
        _ => EQUATION_SECTION_UNKNOWN,
    }
}

/// C's `modelInfoInit`: read the file (or the embedded copy) once. A model whose
/// `_info.json` is missing keeps an empty table and every lookup is the dummy.
fn load(xml: &MODEL_DATA_XML) -> &'static Table {
    let cell = unsafe { &mut *TABLE.0.get() };
    if cell.is_none() {
        *cell = Some(Table { entries: read(xml) });
    }
    cell.as_ref().expect("info.json table")
}

fn read(xml: &MODEL_DATA_XML) -> Vec<Entry> {
    let text = if !xml.infoXMLData.is_null() {
        unsafe { core::ffi::CStr::from_ptr(xml.infoXMLData) }.to_string_lossy().into_owned()
    } else if !xml.fileName.is_null() {
        let name = unsafe { core::ffi::CStr::from_ptr(xml.fileName) }.to_string_lossy().into_owned();
        match std::fs::read_to_string(&name) {
            Ok(s) => s,
            Err(e) => {
                omclog::warning(
                    omclog::STDOUT,
                    false,
                    &format!("could not read {name}: {e}; equation names are unavailable"),
                );
                return Vec::new();
            }
        }
    } else {
        return Vec::new();
    };
    let doc: serde_json::Value = match serde_json::from_str(&text) {
        Ok(v) => v,
        Err(e) => {
            omclog::warning(
                omclog::STDOUT,
                false,
                &format!("could not parse the model's info JSON: {e}"),
            );
            return Vec::new();
        }
    };
    let Some(eqs) = doc.get("equations").and_then(|v| v.as_array()) else {
        return Vec::new();
    };
    let strings = |v: Option<&serde_json::Value>| -> Vec<*const c_char> {
        v.and_then(|v| v.as_array())
            .map(|a| a.iter().filter_map(|s| s.as_str()).map(leak_str).collect())
            .unwrap_or_default()
    };
    eqs.iter()
        .map(|e| Entry {
            section: section_code(e.get("section").and_then(|v| v.as_str())),
            vars: strings(e.get("defines")),
            uses: strings(e.get("uses")),
        })
        .collect()
}

/// C's `modelInfoGetEquation`, by value as the generated code calls it.
#[unsafe(no_mangle)]
pub extern "C" fn modelInfoGetEquation(xml: *mut MODEL_DATA_XML, ix: usize) -> EQUATION_INFO {
    if xml.is_null() {
        return dummy();
    }
    let table = load(unsafe { &*xml });
    let Some(e) = table.entries.get(ix) else {
        return dummy();
    };
    EQUATION_INFO {
        id: ix as c_int,
        section: e.section,
        profileBlockIndex: 0,
        parent: 0,
        numVar: e.vars.len() as c_int,
        vars: e.vars.as_ptr(),
        numVarUsed: e.uses.len() as c_int,
        varsUsed: e.uses.as_ptr(),
    }
}

/// The iteration-variable names of one system, for the shared solver's log lines.
pub fn equation_vars(data: *mut DATA, eq_index: u32) -> Vec<String> {
    let xml = unsafe { &mut (*(*data).modelData).modelDataXml };
    let table = load(xml);
    match table.entries.get(eq_index as usize) {
        Some(e) => e
            .vars
            .iter()
            .map(|p| unsafe { core::ffi::CStr::from_ptr(*p) }.to_string_lossy().into_owned())
            .collect(),
        None => Vec::new(),
    }
}

/// Whether the equation is in the section `LOG_NLS_NEWTON_DIAGNOSTICS` reports on:
/// `initialEquations_lambda0`, or `initialEquations` for a model without one.
pub fn is_init_diag_section(data: *mut DATA, eq_index: u32) -> bool {
    let has_lambda0 = unsafe { (*(*data).callback).functionInitialEquations_lambda0.is_some() };
    let xml = unsafe { &mut (*(*data).modelData).modelDataXml };
    match load(xml).entries.get(eq_index as usize) {
        Some(e) => {
            e.section == EQUATION_SECTION_INIT_LAMBDA0
                || (e.section == EQUATION_SECTION_INITIAL && !has_lambda0)
        }
        None => false,
    }
}
