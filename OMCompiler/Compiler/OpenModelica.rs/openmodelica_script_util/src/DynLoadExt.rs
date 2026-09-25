// Manually written file.
//
// `Values` marshalling for the `-d=gen` dynamic-load pipeline — the
// implementation behind `DynLoad.executeFunction`'s `external "C"
// DynLoad_executeFunction`.
//
// A `-d=gen` function is compiled to C with an entry point
//
//     int in_<name>(threadData_t *threadData,
//                   type_description *inArgs, type_description *outVar);
//
// `in_*` reads its arguments out of the `inArgs` array with the runtime's
// `read_modelica_*` helpers (each advances the cursor by one element) and writes
// its results into `outVar`, accumulating several outputs into a `TYPE_DESC_TUPLE`.
// `type_description` is a small tagged union; we build/read it directly here
// (mirroring the C struct layout). MetaModelica values have no representation
// here -- the counted runtime has no MMC heap -- so they are rejected.
//
// `crate::dynload` (in `openmodelica_util`) owns the loaded libraries, resolves
// the `in_*` address and provides the initialised `threadData`. `mmtorust`
// routes `DynLoad_executeFunction` here via `external_c_impl_path`.

use std::ffi::{CStr, CString, c_char, c_void};

use metamodelica::Result;
use arcstr::ArcStr;
use metamodelica::List;

use openmodelica_ast::Absyn;
use openmodelica_frontend_dump::AbsynUtil;
use openmodelica_frontend_types::Values;
use openmodelica_util::dynload;

// `enum type_desc_e` tags from `openmodelica.h`.
const TD_NONE: i32 = 0;
const TD_REAL: i32 = 1;
const TD_REAL_ARRAY: i32 = 2;
const TD_INT: i32 = 3;
const TD_INT_ARRAY: i32 = 4;
const TD_BOOL: i32 = 5;
const TD_BOOL_ARRAY: i32 = 6;
const TD_STRING: i32 = 7;
const TD_STRING_ARRAY: i32 = 8;
const TD_TUPLE: i32 = 9;
const TD_RECORD: i32 = 11;
const TD_MMC: i32 = 13;
const TD_NORETCALL: i32 = 14;

/// `struct type_desc_s` from `openmodelica.h` (40 bytes): an `enum` tag, a
/// 1-bit `retval` flag (its storage int), then an 8-byte-aligned union. The
/// union members we touch all start at offset 8; `d0..d3` cover its 32 bytes.
/// For a scalar the value lives in `d0`. The other union members, by field:
///   tuple:      d0 = element count (`size_t`), d1 = `type_desc_s*` elements
///   record:     d0 = `char*` record name, d1 = element count,
///               d2 = `char**` field names, d3 = `type_desc_s*` elements
///   base_array: d0 = `int` ndims, d1 = `_index_t*` dim sizes, d2 = `void*`
///               data, d3 = `modelica_boolean` flexible
#[repr(C)]
#[derive(Clone, Copy)]
struct TypeDesc {
    tag: i32,
    retval: i32,
    d0: u64,
    d1: u64,
    d2: u64,
    d3: u64,
}

impl TypeDesc {
    const fn none() -> Self {
        TypeDesc { tag: TD_NONE, retval: 0, d0: 0, d1: 0, d2: 0, d3: 0 }
    }
    const fn scalar(tag: i32, d0: u64) -> Self {
        TypeDesc { tag, retval: 0, d0, d1: 0, d2: 0, d3: 0 }
    }
}

type InFn = extern "C" fn(*mut c_void, *mut TypeDesc, *mut TypeDesc) -> i32;

/// Owns the C-visible buffers behind the argument `type_description`s for the
/// duration of the call. The C implementation mallocs these and frees them
/// right after `in_*` returns (`free_type_description` on each argument), so
/// holding them across the call — and dropping them afterwards — matches the
/// lifetime the generated code is written against.
#[derive(Default)]
struct ArgStorage {
    /// nested member descriptions of `TYPE_DESC_RECORD` arguments
    descs: Vec<Box<[TypeDesc]>>,
    /// string arguments, and the record and field names of record arguments
    cstrings: Vec<CString>,
    name_arrays: Vec<Box<[*const c_char]>>,
    /// `base_array_t` payloads of array arguments
    dims: Vec<Box<[i64]>>,
    reals: Vec<Box<[f64]>>,
    ints: Vec<Box<[i64]>>,
    bools: Vec<Box<[i32]>>,
    /// string-array elements
    str_arrays: Vec<Box<[*const c_char]>>,
}

/// Marshal one argument `Value` into a `type_description`. Mirrors
/// `value_to_type_desc`; a scalar needs no allocation at all.
fn value_to_desc(v: &Values::Value, store: &mut ArgStorage) -> Result<TypeDesc> {
    match v {
        Values::Value::INTEGER { integer } => Ok(TypeDesc::scalar(TD_INT, *integer as i64 as u64)),
        Values::Value::REAL { real } => Ok(TypeDesc::scalar(TD_REAL, real.into_inner().to_bits())),
        Values::Value::BOOL { boolean } => Ok(TypeDesc::scalar(TD_BOOL, *boolean as u64)),
        Values::Value::STRING { string } => Ok(TypeDesc::scalar(TD_STRING, make_c_string(string, store)? as u64)),
        Values::Value::ENUM_LITERAL { index, .. } => Ok(TypeDesc::scalar(TD_INT, *index as i64 as u64)),
        Values::Value::RECORD { record_, orderd, comp, index } if *index == -1 => record_to_desc(record_, orderd, comp, store),
        Values::Value::ARRAY { valueLst, dimLst } => array_to_desc(valueLst, dimLst, store),
        other => return Err("DynLoad.executeFunction: marshalling argument {other:?} not yet supported"),
    }
}

/// A plain Modelica record argument (`Values.RECORD` with index -1) becomes a
/// `TYPE_DESC_RECORD`: a parallel array of field names and member
/// descriptions, read back by the generated `read_modelica_record` call.
fn record_to_desc(
    path: &metamodelica::Ref<Absyn::Path>,
    fields: &List<metamodelica::Ref<Values::Value>>,
    field_names: &List<ArcStr>,
    store: &mut ArgStorage,
) -> Result<TypeDesc> {
    let elems: Vec<TypeDesc> = fields.into_iter().map(|f| value_to_desc(f, store)).collect::<Result<_>>()?;
    let names: Vec<*const c_char> = field_names
        .into_iter()
        .map(|n| {
            let c = CString::new(n.as_str()).map_err(|_| "DynLoad: NUL byte in field name")?;
            let p = c.as_ptr();
            store.cstrings.push(c);
            Ok(p)
        })
        .collect::<Result<_>>()?;
    if elems.len() != names.len() {
        return Err("DynLoad.executeFunction: record argument has {} fields but {} field names");
    }
    let record_name = CString::new(AbsynUtil::pathString(path.clone(), arcstr::literal!("."), false, false)?.as_str()).map_err(|_| "DynLoad: NUL byte in record name")?;
    let d0 = record_name.as_ptr() as u64;
    store.cstrings.push(record_name);
    let elems = elems.into_boxed_slice();
    let names = names.into_boxed_slice();
    let desc = TypeDesc { tag: TD_RECORD, retval: 0, d0, d1: elems.len() as u64, d2: names.as_ptr() as u64, d3: elems.as_ptr() as u64 };
    store.descs.push(elems);
    store.name_arrays.push(names);
    Ok(desc)
}

/// The scalar element type of a Modelica array argument, from its first leaf
/// element (an empty array marshals as a real array, like the C runtime).
fn array_element_tag(values: &List<metamodelica::Ref<Values::Value>>) -> Result<i32> {
    match values.into_iter().next().map(|v| &**v) {
        None => Ok(TD_REAL_ARRAY),
        Some(Values::Value::INTEGER { .. }) | Some(Values::Value::ENUM_LITERAL { .. }) => Ok(TD_INT_ARRAY),
        Some(Values::Value::REAL { .. }) => Ok(TD_REAL_ARRAY),
        Some(Values::Value::BOOL { .. }) => Ok(TD_BOOL_ARRAY),
        Some(Values::Value::STRING { .. }) => Ok(TD_STRING_ARRAY),
        Some(Values::Value::ARRAY { valueLst, .. }) => array_element_tag(valueLst),
        Some(other) => return Err("DynLoad.executeFunction: array argument of {other:?} not supported"),
    }
}

/// Flatten a (possibly nested) `Values.ARRAY` into `out` in row-major order.
/// `depth` counts the remaining dimensions; leaves must be scalars of the
/// array's element type.
fn flatten_array(values: &List<metamodelica::Ref<Values::Value>>, depth: usize, out: &mut dyn FnMut(&Values::Value) -> Result<()>) -> Result<()> {
    for v in values {
        match (&**v, depth) {
            (Values::Value::ARRAY { valueLst, .. }, 2..) => flatten_array(valueLst, depth - 1, out)?,
            (scalar, 1) => out(scalar)?,
            (other, _) => return Err("DynLoad.executeFunction: ragged or mixed array argument at {other:?}"),
        }
    }
    Ok(())
}

/// A Modelica array argument becomes a typed `TYPE_DESC_*_ARRAY` with a
/// `base_array_t` payload (row-major data, like `parse_array` in Dynload.cpp).
fn array_to_desc(values: &List<metamodelica::Ref<Values::Value>>, dim_lst: &List<i32>, store: &mut ArgStorage) -> Result<TypeDesc> {
    let tag = array_element_tag(values)?;
    let dims: Box<[i64]> = dim_lst.into_iter().map(|d| *d as i64).collect();
    let ndims = dims.len();
    if ndims == 0 {
        return Err("DynLoad.executeFunction: array argument without dimensions");
    }
    let expected: i64 = dims.iter().product();

    // Fill the element buffer and produce (element count, data pointer).
    let (count, data): (usize, u64) = match tag {
        TD_INT_ARRAY => {
            let mut buf: Vec<i64> = Vec::new();
            flatten_array(values, ndims, &mut |v| match v {
                Values::Value::INTEGER { integer } => {
                    buf.push(*integer as i64);
                    Ok(())
                },
                Values::Value::ENUM_LITERAL { index, .. } => {
                    buf.push(*index as i64);
                    Ok(())
                },
                other => return Err("DynLoad.executeFunction: expected Integer array element, got {other:?}"),
            })?;
            let buf = buf.into_boxed_slice();
            let r = (buf.len(), buf.as_ptr() as u64);
            store.ints.push(buf);
            r
        }
        TD_REAL_ARRAY => {
            let mut buf: Vec<f64> = Vec::new();
            flatten_array(values, ndims, &mut |v| match v {
                Values::Value::REAL { real } => {
                    buf.push(real.into_inner());
                    Ok(())
                },
                other => return Err("DynLoad.executeFunction: expected Real array element, got {other:?}"),
            })?;
            let buf = buf.into_boxed_slice();
            let r = (buf.len(), buf.as_ptr() as u64);
            store.reals.push(buf);
            r
        }
        TD_BOOL_ARRAY => {
            let mut buf: Vec<i32> = Vec::new();
            flatten_array(values, ndims, &mut |v| match v {
                Values::Value::BOOL { boolean } => {
                    buf.push(*boolean as i32);
                    Ok(())
                },
                other => return Err("DynLoad.executeFunction: expected Boolean array element, got {other:?}"),
            })?;
            let buf = buf.into_boxed_slice();
            let r = (buf.len(), buf.as_ptr() as u64);
            store.bools.push(buf);
            r
        }
        TD_STRING_ARRAY => {
            let mut buf: Vec<*const c_char> = Vec::new();
            flatten_array(values, ndims, &mut |v| match v {
                Values::Value::STRING { string } => {
                    buf.push(make_c_string(string, store)? as *const c_char);
                    Ok(())
                },
                other => return Err("DynLoad.executeFunction: expected String array element, got {other:?}"),
            })?;
            let buf = buf.into_boxed_slice();
            let r = (buf.len(), buf.as_ptr() as u64);
            store.str_arrays.push(buf);
            r
        }
        _ => unreachable!("array_element_tag returns array tags only"),
    };
    if count as i64 != expected {
        return Err("DynLoad.executeFunction: array argument has {count} elements but dimensions {dims:?}");
    }
    let d1 = dims.as_ptr() as u64;
    store.dims.push(dims);
    Ok(TypeDesc { tag, retval: 0, d0: ndims as u64, d1, d2: data, d3: 0 })
}

/// Parse a `_`-delimited `record_description` path (`__` is a literal
/// underscore) back into an `Absyn.Path`. Mirrors `name_to_path` in
/// Dynload.cpp.
fn underscore_name_to_path(name: &str) -> metamodelica::Ref<Absyn::Path> {
    let mut parts: Vec<String> = vec![String::new()];
    let mut chars = name.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '_' {
            if chars.peek() == Some(&'_') {
                chars.next();
                parts.last_mut().unwrap().push('_');
            } else {
                parts.push(String::new());
            }
        } else {
            parts.last_mut().unwrap().push(c);
        }
    }
    let mut path = metamodelica::Ref::new(Absyn::Path::IDENT { name: ArcStr::from(parts.pop().unwrap()) });
    for part in parts.into_iter().rev() {
        path = metamodelica::Ref::new(Absyn::Path::QUALIFIED { name: ArcStr::from(part), path });
    }
    path
}

/// A string argument crosses as a C string, owned by [`ArgStorage`].
fn make_c_string(s: &str, store: &mut ArgStorage) -> Result<usize> {
    let c = CString::new(s).map_err(|_| "DynLoad: NUL byte in string argument")?;
    let p = c.as_ptr() as usize;
    store.cstrings.push(c);
    Ok(p)
}

/// Read a NUL-terminated C string the generated code handed us.
fn read_c_str(p: *const c_char) -> Result<String> {
    if p.is_null() {
        return Err("DynLoad.executeFunction: NULL string in result description");
    }
    Ok(unsafe { CStr::from_ptr(p) }.to_string_lossy().into_owned())
}

/// Read a `type_description` produced by `in_*` back into a `Value`. Multiple
/// function outputs arrive as a `TYPE_DESC_TUPLE` and become a `Values.TUPLE`.
/// Mirrors `type_desc_to_value`.
fn desc_to_value(d: &TypeDesc) -> Result<metamodelica::Ref<Values::Value>> {
    match d.tag {
        TD_INT => Ok(metamodelica::Ref::new(Values::Value::INTEGER { integer: d.d0 as i64 as i32 })),
        TD_REAL => Ok(metamodelica::Ref::new(Values::Value::REAL { real: metamodelica::Real::from(f64::from_bits(d.d0)) })),
        TD_BOOL => Ok(metamodelica::Ref::new(Values::Value::BOOL { boolean: (d.d0 as i32) != 0 })),
        TD_NORETCALL => Ok(metamodelica::Ref::new(Values::Value::NORETCALL)),
        TD_TUPLE => {
            let n = d.d0 as usize;
            let elems = d.d1 as *const TypeDesc;
            if n != 0 && elems.is_null() {
                return Err("DynLoad.executeFunction: malformed result tuple");
            }
            let mut vals: Vec<metamodelica::Ref<Values::Value>> = Vec::with_capacity(n);
            for i in 0..n {
                let e = unsafe { &*elems.add(i) };
                vals.push(desc_to_value(e)?);
            }
            Ok(metamodelica::Ref::new(Values::Value::TUPLE { valueLst: List::from_iter(vals) }))
        }
        TD_RECORD => {
            // union: d0 = record name, d1 = count, d2 = names, d3 = elements.
            // Produced by `write_modelica_record`, whose record name is the
            // `_`-mangled `record_description.path`.
            let n = d.d1 as usize;
            let names = d.d2 as *const *const c_char;
            let elems = d.d3 as *const TypeDesc;
            if n != 0 && (names.is_null() || elems.is_null()) {
                return Err("DynLoad.executeFunction: malformed result record");
            }
            let mut vals: Vec<metamodelica::Ref<Values::Value>> = Vec::with_capacity(n);
            let mut comps: Vec<ArcStr> = Vec::with_capacity(n);
            for i in 0..n {
                vals.push(desc_to_value(unsafe { &*elems.add(i) })?);
                comps.push(ArcStr::from(read_c_str(unsafe { *names.add(i) })?));
            }
            Ok(metamodelica::Ref::new(Values::Value::RECORD {
                record_: underscore_name_to_path(&read_c_str(d.d0 as *const c_char)?),
                orderd: List::from_iter(vals),
                comp: List::from_iter(comps),
                index: -1,
            }))
        }
        TD_REAL_ARRAY | TD_INT_ARRAY | TD_BOOL_ARRAY | TD_STRING_ARRAY => desc_array_to_value(d),
        TD_STRING => Ok(metamodelica::Ref::new(Values::Value::STRING { string: ArcStr::from(read_c_str(d.d0 as *const c_char)?) })),
        TD_MMC => return Err("DynLoad.executeFunction: MetaModelica result from a generated function"),
        other => return Err("DynLoad.executeFunction: unsupported result type_description tag {other}"),
    }
}

/// Decode a `TYPE_DESC_*_ARRAY` result (`base_array_t` payload) into nested
/// `Values.ARRAY`s, the same shape `generate_array` in Dynload.cpp produces:
/// each nesting level carries the dimension list from that level outwards.
fn desc_array_to_value(d: &TypeDesc) -> Result<metamodelica::Ref<Values::Value>> {
    let ndims = d.d0 as i32;
    let dim_size = d.d1 as *const i64;
    let data = d.d2 as *const u8;
    if ndims < 1 || dim_size.is_null() {
        return Err("DynLoad.executeFunction: malformed result array");
    }
    let dims: Vec<i64> = (0..ndims as usize).map(|i| unsafe { *dim_size.add(i) }).collect();
    if data.is_null() && dims.iter().product::<i64>() != 0 {
        return Err("DynLoad.executeFunction: result array without data");
    }
    let mut cursor = data;
    decode_array_level(d.tag, &dims, &mut cursor)
}

fn decode_array_level(tag: i32, dims: &[i64], cursor: &mut *const u8) -> Result<metamodelica::Ref<Values::Value>> {
    /// Read one element of `T` and advance the row-major cursor.
    unsafe fn take<T: Copy>(cursor: &mut *const u8) -> T {
        let v = unsafe { (*cursor as *const T).read() };
        *cursor = unsafe { cursor.add(std::mem::size_of::<T>()) };
        v
    }
    let n = dims[0].max(0) as usize;
    let mut items: Vec<metamodelica::Ref<Values::Value>> = Vec::with_capacity(n);
    if dims.len() == 1 {
        for _ in 0..n {
            items.push(match tag {
                TD_REAL_ARRAY => metamodelica::Ref::new(Values::Value::REAL { real: metamodelica::Real::from(unsafe { take::<f64>(cursor) }) }),
                TD_INT_ARRAY => metamodelica::Ref::new(Values::Value::INTEGER { integer: unsafe { take::<i64>(cursor) } as i32 }),
                TD_BOOL_ARRAY => metamodelica::Ref::new(Values::Value::BOOL { boolean: unsafe { take::<i32>(cursor) } != 0 }),
                TD_STRING_ARRAY => metamodelica::Ref::new(Values::Value::STRING { string: ArcStr::from(read_c_str(unsafe { take::<*const c_char>(cursor) })?) }),
                _ => unreachable!("desc_array_to_value passes array tags only"),
            });
        }
    } else {
        for _ in 0..n {
            items.push(decode_array_level(tag, &dims[1..], cursor)?);
        }
    }
    Ok(metamodelica::Ref::new(Values::Value::ARRAY {
        valueLst: List::from_iter(items),
        dimLst: List::from_iter(dims.iter().map(|d| *d as i32)),
    }))
}

/// A boxed MMC string, for [`omc_Error_getCurrentComponent`] alone: its caller
/// is still MetaModelica. The header is 8 bytes before the data, the tag adds 3.
fn make_mmc_string(s: &str) -> Result<usize> {
    let mk = dynload::runtime_symbol("mmc_mk_scon_len_ret_ptr")
        .ok_or_else(|| "runtime symbol `mmc_mk_scon_len_ret_ptr` not found")?;
    let mk: extern "C" fn(usize) -> *mut u8 = unsafe { std::mem::transmute(mk) };
    let bytes = s.as_bytes();
    let data = mk(bytes.len());
    if data.is_null() {
        return Err("DynLoad.executeFunction: string allocation failed");
    }
    unsafe {
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), data, bytes.len());
        *data.add(bytes.len()) = 0;
    }
    Ok(data as usize - 5)
}

/// `omc_Error_getCurrentComponent`, for a dlopened libomcruntime: its
/// `c_add_message` calls back for the instantiation-context prefix, so the
/// port has to export it or the dlopen fails unresolved.
#[unsafe(no_mangle)]
pub extern "C" fn omc_Error_getCurrentComponent(
    _thread_data: *mut c_void,
    sline: *mut i64,
    scol: *mut i64,
    eline: *mut i64,
    ecol: *mut i64,
    read_only: *mut i64,
    filename: *mut *mut c_void,
) -> *mut c_void {
    let (s, sl, sc, el, ec, ro, file) = openmodelica_util::Error::getCurrentComponent()
        .unwrap_or_else(|_| (ArcStr::default(), 0, 0, 0, 0, false, ArcStr::default()));
    // Allocation failure leaves us with nothing valid to hand the C side;
    // that only happens if the runtime is torn down mid-call. Abort rather
    // than unwind across the FFI boundary.
    let str_box = make_mmc_string(s.as_str()).unwrap_or_else(|e| {
        eprintln!("omc_Error_getCurrentComponent: {e}");
        std::process::abort()
    });
    let file_box = make_mmc_string(file.as_str()).unwrap_or_else(|e| {
        eprintln!("omc_Error_getCurrentComponent: {e}");
        std::process::abort()
    });
    unsafe {
        *sline = sl as i64;
        *scol = sc as i64;
        *eline = el as i64;
        *ecol = ec as i64;
        *read_only = ro as i64;
        *filename = file_box as *mut c_void;
    }
    str_box as *mut c_void
}

/// Call the dynamically loaded `in_*` entry point identified by `handle`,
/// marshalling `values` in and the result out. A non-zero return from `in_*`
/// means the generated function failed; the C runtime returns
/// `Values.META_FAIL` for that, so we do too.
pub fn executeFunction(handle: i32, values: List<metamodelica::Ref<Values::Value>>, _debug: bool) -> Result<metamodelica::Ref<Values::Value>> {
    let addr = dynload::function_addr(handle)?;
    let thread_data = dynload::thread_data()? as *mut c_void;
    // Keeps the buffers behind structured arguments alive until after the call
    // (and after result decoding — a result may alias argument data).
    let mut store = ArgStorage::default();
    let mut args: Vec<TypeDesc> = Vec::new();
    for v in &values {
        args.push(value_to_desc(v, &mut store)?);
    }

    let mut out = TypeDesc::none();
    out.retval = 1; // request owned (malloc'd) array/string results we can free

    // The generated function prints side effects through the C runtime's
    // `stdout`, a different buffer from the port's own output. Flush ours first
    // so anything already produced precedes the function's output.
    {
        use std::io::Write;
        let _ = std::io::stdout().flush();
    }

    // SAFETY: `addr` is the resolved `in_<name>` entry; its ABI is fixed by the
    // code generator. `args` outlives the call; `in_*` reads at most one element
    // per declared input.
    let func: InFn = unsafe { std::mem::transmute(addr) };
    let rc = func(thread_data, args.as_mut_ptr(), &mut out);

    // Flush the C runtime's streams: on failure the generated `in_*` wrapper
    // returns through `OMC_CATCH_TOP` before its own trailing `fflush`, so a
    // function's `print` side effects would otherwise surface out of order
    // (after the caller has already printed this call's result).
    if let Some(fflush_addr) = dynload::runtime_symbol("fflush") {
        let fflush: extern "C" fn(*mut c_void) -> i32 = unsafe { std::mem::transmute(fflush_addr) };
        fflush(std::ptr::null_mut());
    }

    if rc != 0 {
        return Ok(metamodelica::Ref::new(Values::Value::META_FAIL));
    }

    let result = desc_to_value(&out);

    // Release any heap the runtime allocated for the result (the tuple element
    // array, owned arrays/strings). Scalars own nothing, so this is a no-op for
    // them; best-effort if the symbol is unavailable.
    if let Some(free_addr) = dynload::runtime_symbol("free_type_description") {
        let free_fn: extern "C" fn(*mut TypeDesc) = unsafe { std::mem::transmute(free_addr) };
        free_fn(&mut out);
    }

    drop(store);
    result
}
