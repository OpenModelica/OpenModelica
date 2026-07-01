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
// (mirroring the C struct layout) rather than going through the runtime's
// boxed-`Values` marshalling, so scalar calls need no GC allocation at all.
// Structured values (lists, options, tuples, records, MetaModelica arrays)
// cross the boundary as `TYPE_DESC_MMC`: real MMC heap objects allocated
// through the runtime's `mmc_mk_box_arr`/`mmc_mk_rcon`. Modelica arrays cross
// as `TYPE_DESC_*_ARRAY` with a C `base_array_t` payload. This mirrors
// `value_to_type_desc`/`value_to_mmc`/`mmc_to_value`/`type_desc_to_value` in
// `Compiler/runtime/Dynload.cpp`.
//
// `crate::dynload` (in `openmodelica_util`) owns the loaded libraries, resolves
// the `in_*` address and provides the initialised `threadData`. `mmtorust`
// routes `DynLoad_executeFunction` here via `external_c_impl_path`.

use std::ffi::{CStr, CString, c_char, c_void};
use std::sync::Arc;

use anyhow::{Result, bail};
use arcstr::ArcStr;
use metamodelica::List;

use openmodelica_ast::Absyn;
use openmodelica_frontend_dump::AbsynUtil;
use openmodelica_frontend_types::Values;
use openmodelica_util::dynload;

// MMC object headers (`MMC_STRUCTHDR(slots, ctor) = (slots << 10) | (ctor << 2)`)
// for the `RML_STYLE_TAGPTR` representation the runtime is built with: a value
// is an immediate integer when bit 0 is clear (`i << 1`), otherwise a pointer
// tagged `+3`. A struct has `hdr & 3 == 0`; a boxed string has `hdr & 7 == 5`;
// anything else boxed is a real.
const MMC_NILHDR: usize = 0; // STRUCTHDR(0, 0): {}
const MMC_CONSHDR: usize = (2 << 10) | (1 << 2); // STRUCTHDR(2, 1): cons
const MMC_NONEHDR: usize = 1 << 2; // STRUCTHDR(0, 1): NONE()
const MMC_SOMEHDR: usize = (1 << 10) | (1 << 2); // STRUCTHDR(1, 1): SOME(x)
const MMC_REALHDR: usize = (1 << 10) | 9; // boxed double
const MMC_SIZE_INT: usize = 8;
/// `MMC_ARRAY_TAG`: constructor of a MetaModelica array (`arrayCreate`).
const MMC_ARRAY_CTOR: usize = 255;

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

/// `struct record_description` from `meta_modelica.h`. Slot 1 of every MMC
/// record/uniontype object points at one of these (untagged).
#[repr(C)]
struct RecordDescription {
    /// `_`-delimited path, a literal `_` in an ident escaped as `__`
    /// (the generated code's identifier mangling, e.g. `package_record__X`).
    path: *const c_char,
    /// `.`-delimited path (e.g. `package.record_X`).
    name: *const c_char,
    /// one entry per field, in slot order.
    field_names: *const *const c_char,
}

type InFn = extern "C" fn(*mut c_void, *mut TypeDesc, *mut TypeDesc) -> i32;

/// The runtime's MMC allocators, resolved from the loaded shared object once
/// per `executeFunction` call (this is not a hot path). Everything allocated
/// through these lives in the C side's GC heap; the collector is paused for
/// the duration of the call, so the objects cannot move or be freed while the
/// generated function can see them.
struct MmcAlloc {
    mk_box_arr: extern "C" fn(isize, usize, *const usize) -> usize,
    mk_rcon: extern "C" fn(f64) -> usize,
}

impl MmcAlloc {
    fn resolve() -> Result<Self> {
        let mk_box_arr = dynload::runtime_symbol("mmc_mk_box_arr")
            .ok_or_else(|| anyhow::anyhow!("runtime symbol `mmc_mk_box_arr` not found"))?;
        let mk_rcon = dynload::runtime_symbol("mmc_mk_rcon")
            .ok_or_else(|| anyhow::anyhow!("runtime symbol `mmc_mk_rcon` not found"))?;
        Ok(MmcAlloc {
            mk_box_arr: unsafe { std::mem::transmute::<usize, extern "C" fn(isize, usize, *const usize) -> usize>(mk_box_arr) },
            mk_rcon: unsafe { std::mem::transmute::<usize, extern "C" fn(f64) -> usize>(mk_rcon) },
        })
    }

    /// Allocate an MMC struct with the given constructor and slots and return
    /// the tagged pointer. `nil`/`NONE()` come out of here too — the runtime
    /// tests them by header (`MMC_NILTEST` compares `MMC_GETHDR`), not by
    /// pointer identity, so a fresh 0-slot box is equivalent to the statics.
    fn mk_box(&self, ctor: usize, slots: &[usize]) -> usize {
        (self.mk_box_arr)(slots.len() as isize, ctor, slots.as_ptr())
    }
}

/// An MMC immediate integer (bit 0 clear).
fn mmc_immediate(i: i64) -> usize {
    (i << 1) as usize
}

/// Owns the C-visible buffers behind the argument `type_description`s for the
/// duration of the call. The C implementation mallocs these and frees them
/// right after `in_*` returns (`free_type_description` on each argument), so
/// holding them across the call — and dropping them afterwards — matches the
/// lifetime the generated code is written against.
#[derive(Default)]
struct ArgStorage {
    /// nested member descriptions of `TYPE_DESC_RECORD` arguments
    descs: Vec<Box<[TypeDesc]>>,
    /// record names + field names of `TYPE_DESC_RECORD` arguments
    cstrings: Vec<CString>,
    name_arrays: Vec<Box<[*const c_char]>>,
    /// `base_array_t` payloads of array arguments
    dims: Vec<Box<[i64]>>,
    reals: Vec<Box<[f64]>>,
    ints: Vec<Box<[i64]>>,
    bools: Vec<Box<[i32]>>,
    /// string-array elements are `modelica_string` (MMC string metatypes)
    metatypes: Vec<Box<[usize]>>,
}

/// Marshal one argument `Value` into a `type_description`. The runtime's
/// `read_modelica_metatype` boxes the scalar tags on demand, so an `Integer`/
/// `Real`/`Boolean` argument needs no allocation whether the parameter is a
/// builtin scalar or a `MetaModelica` value. Mirrors `value_to_type_desc`.
fn value_to_desc(rt: &MmcAlloc, v: &Values::Value, store: &mut ArgStorage) -> Result<TypeDesc> {
    match v {
        Values::Value::INTEGER { integer } => Ok(TypeDesc::scalar(TD_INT, *integer as i64 as u64)),
        Values::Value::REAL { real } => Ok(TypeDesc::scalar(TD_REAL, real.into_inner().to_bits())),
        Values::Value::BOOL { boolean } => Ok(TypeDesc::scalar(TD_BOOL, *boolean as u64)),
        Values::Value::STRING { string } => Ok(TypeDesc::scalar(TD_STRING, make_c_string(string)? as u64)),
        Values::Value::ENUM_LITERAL { index, .. } => Ok(TypeDesc::scalar(TD_INT, *index as i64 as u64)),
        // Structured MetaModelica values cross as MMC heap data. A plain
        // Modelica record (index -1) instead becomes a TYPE_DESC_RECORD of
        // nested descriptions, read back field by field.
        Values::Value::LIST { .. }
        | Values::Value::OPTION { .. }
        | Values::Value::META_TUPLE { .. }
        | Values::Value::META_ARRAY { .. } => Ok(TypeDesc::scalar(TD_MMC, value_to_mmc(rt, v)? as u64)),
        Values::Value::RECORD { index, .. } if *index != -1 => Ok(TypeDesc::scalar(TD_MMC, value_to_mmc(rt, v)? as u64)),
        Values::Value::RECORD { record_, orderd, comp, .. } => record_to_desc(rt, record_, orderd, comp, store),
        Values::Value::ARRAY { valueLst, dimLst } => array_to_desc(rt, valueLst, dimLst, store),
        other => bail!("DynLoad.executeFunction: marshalling argument {other:?} not yet supported"),
    }
}

/// Encode a `Value` as an MMC heap object (`modelica_metatype`), the dual of
/// [`decode_metatype`]. Mirrors `value_to_mmc` in Dynload.cpp.
fn value_to_mmc(rt: &MmcAlloc, v: &Values::Value) -> Result<usize> {
    Ok(match v {
        Values::Value::INTEGER { integer } => mmc_immediate(*integer as i64),
        Values::Value::BOOL { boolean } => mmc_immediate(*boolean as i64),
        Values::Value::REAL { real } => (rt.mk_rcon)(real.into_inner()),
        Values::Value::STRING { string } => make_c_string(string)?,
        Values::Value::LIST { valueLst } => {
            // Build the cons spine back to front.
            let items: Vec<usize> = (&**valueLst).into_iter().map(|x| value_to_mmc(rt, x)).collect::<Result<_>>()?;
            let mut lst = rt.mk_box(0, &[]); // {}
            for item in items.into_iter().rev() {
                lst = rt.mk_box(1, &[item, lst]);
            }
            lst
        }
        Values::Value::OPTION { some: None } => rt.mk_box(1, &[]),
        Values::Value::OPTION { some: Some(x) } => {
            let x = value_to_mmc(rt, x)?;
            rt.mk_box(1, &[x])
        }
        Values::Value::META_TUPLE { valueLst } => {
            let slots: Vec<usize> = (&**valueLst).into_iter().map(|x| value_to_mmc(rt, x)).collect::<Result<_>>()?;
            rt.mk_box(0, &slots)
        }
        Values::Value::META_ARRAY { valueLst } => {
            let slots: Vec<usize> = (&**valueLst).into_iter().map(|x| value_to_mmc(rt, x)).collect::<Result<_>>()?;
            rt.mk_box(MMC_ARRAY_CTOR, &slots)
        }
        Values::Value::RECORD { record_, orderd, comp, index } => {
            // ctor == index + 3; a plain record (index -1) nested inside
            // MetaModelica data gets ctor 2, exactly like the C runtime.
            let desc = leak_record_description(record_, comp)?;
            let mut slots: Vec<usize> = vec![desc];
            for field in &**orderd {
                slots.push(value_to_mmc(rt, field)?);
            }
            rt.mk_box((*index as i64 + 3) as usize, &slots)
        }
        other => bail!("DynLoad.executeFunction: cannot marshal {other:?} into MetaModelica data"),
    })
}

/// Build the `record_description` for a record/uniontype argument and return
/// its address (stored untagged in slot 1 of the record box). The description
/// is deliberately leaked, like the C implementation (`value_to_mmc` mallocs
/// and never frees): the generated function may keep the record value — and
/// with it the description pointer — alive across calls, so no scope bounds
/// its lifetime. The handful of bytes per interactive call is acceptable.
fn leak_record_description(path: &Arc<Absyn::Path>, field_names: &List<ArcStr>) -> Result<usize> {
    let name = AbsynUtil::pathString(path.clone(), arcstr::literal!("."), false, false)?;
    let fields: Vec<&str> = field_names.into_iter().map(|f| f.as_str()).collect();
    leak_record_description_raw(&underscore_path_string(path), name.as_str(), &fields)
}

/// Lower-level form of [`leak_record_description`] for descriptions whose
/// paths are known statically (the Flags marshalling below).
fn leak_record_description_raw(mangled_path: &str, dotted_name: &str, field_names: &[&str]) -> Result<usize> {
    let fields: Vec<*const c_char> = field_names
        .iter()
        .map(|f| Ok(CString::new(*f)?.into_raw() as *const c_char))
        .collect::<Result<_>>()?;
    let desc = RecordDescription {
        path: CString::new(mangled_path)?.into_raw(),
        name: CString::new(dotted_name)?.into_raw(),
        field_names: Box::leak(fields.into_boxed_slice()).as_ptr(),
    };
    Ok(Box::into_raw(Box::new(desc)) as usize)
}

/// A plain Modelica record argument (`Values.RECORD` with index -1) becomes a
/// `TYPE_DESC_RECORD`: a parallel array of field names and member
/// descriptions, read back by the generated `read_modelica_record` call.
fn record_to_desc(
    rt: &MmcAlloc,
    path: &Arc<Absyn::Path>,
    fields: &List<Arc<Values::Value>>,
    field_names: &List<ArcStr>,
    store: &mut ArgStorage,
) -> Result<TypeDesc> {
    let elems: Vec<TypeDesc> = fields.into_iter().map(|f| value_to_desc(rt, f, store)).collect::<Result<_>>()?;
    let names: Vec<*const c_char> = field_names
        .into_iter()
        .map(|n| {
            let c = CString::new(n.as_str())?;
            let p = c.as_ptr();
            store.cstrings.push(c);
            Ok(p)
        })
        .collect::<Result<_>>()?;
    if elems.len() != names.len() {
        bail!("DynLoad.executeFunction: record argument has {} fields but {} field names", elems.len(), names.len());
    }
    let record_name = CString::new(AbsynUtil::pathString(path.clone(), arcstr::literal!("."), false, false)?.as_str())?;
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
fn array_element_tag(values: &List<Arc<Values::Value>>) -> Result<i32> {
    match values.into_iter().next().map(|v| &**v) {
        None => Ok(TD_REAL_ARRAY),
        Some(Values::Value::INTEGER { .. }) | Some(Values::Value::ENUM_LITERAL { .. }) => Ok(TD_INT_ARRAY),
        Some(Values::Value::REAL { .. }) => Ok(TD_REAL_ARRAY),
        Some(Values::Value::BOOL { .. }) => Ok(TD_BOOL_ARRAY),
        Some(Values::Value::STRING { .. }) => Ok(TD_STRING_ARRAY),
        Some(Values::Value::ARRAY { valueLst, .. }) => array_element_tag(valueLst),
        Some(other) => bail!("DynLoad.executeFunction: array argument of {other:?} not supported"),
    }
}

/// Flatten a (possibly nested) `Values.ARRAY` into `out` in row-major order.
/// `depth` counts the remaining dimensions; leaves must be scalars of the
/// array's element type.
fn flatten_array(rt: &MmcAlloc, values: &List<Arc<Values::Value>>, depth: usize, out: &mut dyn FnMut(&Values::Value) -> Result<()>) -> Result<()> {
    for v in values {
        match (&**v, depth) {
            (Values::Value::ARRAY { valueLst, .. }, 2..) => flatten_array(rt, valueLst, depth - 1, out)?,
            (scalar, 1) => out(scalar)?,
            (other, _) => bail!("DynLoad.executeFunction: ragged or mixed array argument at {other:?}"),
        }
    }
    Ok(())
}

/// A Modelica array argument becomes a typed `TYPE_DESC_*_ARRAY` with a
/// `base_array_t` payload (row-major data, like `parse_array` in Dynload.cpp).
fn array_to_desc(rt: &MmcAlloc, values: &List<Arc<Values::Value>>, dim_lst: &List<i32>, store: &mut ArgStorage) -> Result<TypeDesc> {
    let tag = array_element_tag(values)?;
    let dims: Box<[i64]> = dim_lst.into_iter().map(|d| *d as i64).collect();
    let ndims = dims.len();
    if ndims == 0 {
        bail!("DynLoad.executeFunction: array argument without dimensions");
    }
    let expected: i64 = dims.iter().product();

    // Fill the element buffer and produce (element count, data pointer).
    let (count, data): (usize, u64) = match tag {
        TD_INT_ARRAY => {
            let mut buf: Vec<i64> = Vec::new();
            flatten_array(rt, values, ndims, &mut |v| match v {
                Values::Value::INTEGER { integer } => {
                    buf.push(*integer as i64);
                    Ok(())
                },
                Values::Value::ENUM_LITERAL { index, .. } => {
                    buf.push(*index as i64);
                    Ok(())
                },
                other => bail!("DynLoad.executeFunction: expected Integer array element, got {other:?}"),
            })?;
            let buf = buf.into_boxed_slice();
            let r = (buf.len(), buf.as_ptr() as u64);
            store.ints.push(buf);
            r
        }
        TD_REAL_ARRAY => {
            let mut buf: Vec<f64> = Vec::new();
            flatten_array(rt, values, ndims, &mut |v| match v {
                Values::Value::REAL { real } => {
                    buf.push(real.into_inner());
                    Ok(())
                },
                other => bail!("DynLoad.executeFunction: expected Real array element, got {other:?}"),
            })?;
            let buf = buf.into_boxed_slice();
            let r = (buf.len(), buf.as_ptr() as u64);
            store.reals.push(buf);
            r
        }
        TD_BOOL_ARRAY => {
            let mut buf: Vec<i32> = Vec::new();
            flatten_array(rt, values, ndims, &mut |v| match v {
                Values::Value::BOOL { boolean } => {
                    buf.push(*boolean as i32);
                    Ok(())
                },
                other => bail!("DynLoad.executeFunction: expected Boolean array element, got {other:?}"),
            })?;
            let buf = buf.into_boxed_slice();
            let r = (buf.len(), buf.as_ptr() as u64);
            store.bools.push(buf);
            r
        }
        TD_STRING_ARRAY => {
            let mut buf: Vec<usize> = Vec::new();
            flatten_array(rt, values, ndims, &mut |v| match v {
                Values::Value::STRING { string } => {
                    buf.push(make_c_string(string)?);
                    Ok(())
                },
                other => bail!("DynLoad.executeFunction: expected String array element, got {other:?}"),
            })?;
            let buf = buf.into_boxed_slice();
            let r = (buf.len(), buf.as_ptr() as u64);
            store.metatypes.push(buf);
            r
        }
        _ => unreachable!("array_element_tag returns array tags only"),
    };
    if count as i64 != expected {
        bail!("DynLoad.executeFunction: array argument has {count} elements but dimensions {dims:?}");
    }
    let d1 = dims.as_ptr() as u64;
    store.dims.push(dims);
    Ok(TypeDesc { tag, retval: 0, d0: ndims as u64, d1, d2: data, d3: 0 })
}

/// `_`-mangled path string for a `record_description`, the inverse of
/// [`underscore_name_to_path`]: idents joined by `_`, a literal `_` escaped as
/// `__` (the same mangling the code generator applies to identifiers).
fn underscore_path_string(path: &Absyn::Path) -> String {
    match path {
        Absyn::Path::IDENT { name } => name.replace('_', "__"),
        Absyn::Path::QUALIFIED { name, path } => format!("{}_{}", name.replace('_', "__"), underscore_path_string(path)),
        Absyn::Path::FULLYQUALIFIED { path } => underscore_path_string(path),
    }
}

/// Parse a `_`-delimited `record_description` path (`__` is a literal
/// underscore) back into an `Absyn.Path`. Mirrors `name_to_path` in
/// Dynload.cpp.
fn underscore_name_to_path(name: &str) -> Arc<Absyn::Path> {
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
    let mut path = Arc::new(Absyn::Path::IDENT { name: ArcStr::from(parts.pop().unwrap()) });
    for part in parts.into_iter().rev() {
        path = Arc::new(Absyn::Path::QUALIFIED { name: ArcStr::from(part), path });
    }
    path
}

/// Allocate a boxed MMC string (`modelica_metatype`) holding `s` and return the
/// tagged metatype pointer. `mmc_mk_scon_len_ret_ptr` returns the string's data
/// region; the object header is 8 bytes before it and the tagged pointer adds 3.
fn make_c_string(s: &str) -> Result<usize> {
    let mk = dynload::runtime_symbol("mmc_mk_scon_len_ret_ptr")
        .ok_or_else(|| anyhow::anyhow!("runtime symbol `mmc_mk_scon_len_ret_ptr` not found"))?;
    let mk: extern "C" fn(usize) -> *mut u8 = unsafe { std::mem::transmute(mk) };
    let bytes = s.as_bytes();
    let data = mk(bytes.len());
    if data.is_null() {
        bail!("DynLoad.executeFunction: string allocation failed");
    }
    unsafe {
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), data, bytes.len());
        *data.add(bytes.len()) = 0; // NUL terminator
    }
    Ok(data as usize - 5)
}

/// Read a NUL-terminated C string the generated code handed us.
fn read_c_str(p: *const c_char) -> Result<String> {
    if p.is_null() {
        bail!("DynLoad.executeFunction: NULL string in result description");
    }
    Ok(unsafe { CStr::from_ptr(p) }.to_string_lossy().into_owned())
}

/// Read a `type_description` produced by `in_*` back into a `Value`. Multiple
/// function outputs arrive as a `TYPE_DESC_TUPLE` and become a `Values.TUPLE`.
/// Mirrors `type_desc_to_value`.
fn desc_to_value(d: &TypeDesc) -> Result<Arc<Values::Value>> {
    match d.tag {
        TD_INT => Ok(Arc::new(Values::Value::INTEGER { integer: d.d0 as i64 as i32 })),
        TD_REAL => Ok(Arc::new(Values::Value::REAL { real: metamodelica::Real::from(f64::from_bits(d.d0)) })),
        TD_BOOL => Ok(Arc::new(Values::Value::BOOL { boolean: (d.d0 as i32) != 0 })),
        TD_NORETCALL => Ok(Arc::new(Values::Value::NORETCALL)),
        TD_TUPLE => {
            let n = d.d0 as usize;
            let elems = d.d1 as *const TypeDesc;
            if n != 0 && elems.is_null() {
                bail!("DynLoad.executeFunction: malformed result tuple");
            }
            let mut vals: Vec<Arc<Values::Value>> = Vec::with_capacity(n);
            for i in 0..n {
                let e = unsafe { &*elems.add(i) };
                vals.push(desc_to_value(e)?);
            }
            Ok(Arc::new(Values::Value::TUPLE { valueLst: Arc::new(List::from_iter(vals)) }))
        }
        TD_RECORD => {
            // union: d0 = record name, d1 = count, d2 = names, d3 = elements.
            // Produced by `write_modelica_record`, whose record name is the
            // `_`-mangled `record_description.path`.
            let n = d.d1 as usize;
            let names = d.d2 as *const *const c_char;
            let elems = d.d3 as *const TypeDesc;
            if n != 0 && (names.is_null() || elems.is_null()) {
                bail!("DynLoad.executeFunction: malformed result record");
            }
            let mut vals: Vec<Arc<Values::Value>> = Vec::with_capacity(n);
            let mut comps: Vec<ArcStr> = Vec::with_capacity(n);
            for i in 0..n {
                vals.push(desc_to_value(unsafe { &*elems.add(i) })?);
                comps.push(ArcStr::from(read_c_str(unsafe { *names.add(i) })?));
            }
            Ok(Arc::new(Values::Value::RECORD {
                record_: underscore_name_to_path(&read_c_str(d.d0 as *const c_char)?),
                orderd: Arc::new(List::from_iter(vals)),
                comp: Arc::new(List::from_iter(comps)),
                index: -1,
            }))
        }
        TD_REAL_ARRAY | TD_INT_ARRAY | TD_BOOL_ARRAY | TD_STRING_ARRAY => desc_array_to_value(d),
        // `modelica_string` is itself a boxed MMC string metatype.
        TD_STRING => decode_metatype(d.d0 as usize),
        TD_MMC => decode_metatype(d.d0 as usize),
        other => bail!("DynLoad.executeFunction: unsupported result type_description tag {other}"),
    }
}

/// Decode a `TYPE_DESC_*_ARRAY` result (`base_array_t` payload) into nested
/// `Values.ARRAY`s, the same shape `generate_array` in Dynload.cpp produces:
/// each nesting level carries the dimension list from that level outwards.
fn desc_array_to_value(d: &TypeDesc) -> Result<Arc<Values::Value>> {
    let ndims = d.d0 as i32;
    let dim_size = d.d1 as *const i64;
    let data = d.d2 as *const u8;
    if ndims < 1 || dim_size.is_null() {
        bail!("DynLoad.executeFunction: malformed result array");
    }
    let dims: Vec<i64> = (0..ndims as usize).map(|i| unsafe { *dim_size.add(i) }).collect();
    if data.is_null() && dims.iter().product::<i64>() != 0 {
        bail!("DynLoad.executeFunction: result array without data");
    }
    let mut cursor = data;
    decode_array_level(d.tag, &dims, &mut cursor)
}

fn decode_array_level(tag: i32, dims: &[i64], cursor: &mut *const u8) -> Result<Arc<Values::Value>> {
    /// Read one element of `T` and advance the row-major cursor.
    unsafe fn take<T: Copy>(cursor: &mut *const u8) -> T {
        let v = unsafe { (*cursor as *const T).read() };
        *cursor = unsafe { cursor.add(std::mem::size_of::<T>()) };
        v
    }
    let n = dims[0].max(0) as usize;
    let mut items: Vec<Arc<Values::Value>> = Vec::with_capacity(n);
    if dims.len() == 1 {
        for _ in 0..n {
            items.push(match tag {
                TD_REAL_ARRAY => Arc::new(Values::Value::REAL { real: metamodelica::Real::from(unsafe { take::<f64>(cursor) }) }),
                TD_INT_ARRAY => Arc::new(Values::Value::INTEGER { integer: unsafe { take::<i64>(cursor) } as i32 }),
                TD_BOOL_ARRAY => Arc::new(Values::Value::BOOL { boolean: unsafe { take::<i32>(cursor) } != 0 }),
                TD_STRING_ARRAY => decode_metatype(unsafe { take::<usize>(cursor) })?,
                _ => unreachable!("desc_array_to_value passes array tags only"),
            });
        }
    } else {
        for _ in 0..n {
            items.push(decode_array_level(tag, &dims[1..], cursor)?);
        }
    }
    Ok(Arc::new(Values::Value::ARRAY {
        valueLst: Arc::new(List::from_iter(items)),
        dimLst: Arc::new(List::from_iter(dims.iter().map(|d| *d as i32))),
    }))
}

/// Read MMC slot `i` (a machine word) of an untagged object at `base`.
#[inline]
unsafe fn slot(base: usize, i: usize) -> usize {
    unsafe { *((base + i * std::mem::size_of::<usize>()) as *const usize) }
}

/// Decode a boxed MMC value (`modelica_metatype`) into a `Values.Value`,
/// mirroring `mmc_to_value`: immediate integers, boxed reals/strings, lists,
/// options, tuples, MetaModelica arrays (constructor 255) and record/uniontype
/// instances (constructor >= 2, field names from the `record_description` in
/// slot 1).
fn decode_metatype(m: usize) -> Result<Arc<Values::Value>> {
    // Immediate integer: bit 0 clear, value is an arithmetic right shift.
    if m & 1 == 0 {
        return Ok(Arc::new(Values::Value::INTEGER { integer: ((m as isize) >> 1) as i32 }));
    }
    let base = m - 3; // untag the pointer
    let hdr = unsafe { *(base as *const usize) };
    if hdr & 3 != 0 {
        // Not a struct: either a boxed string (`hdr & 7 == 5`) or a boxed real.
        if hdr & 7 == 5 {
            let len = (hdr >> 3) - MMC_SIZE_INT;
            let data = (base + std::mem::size_of::<usize>()) as *const u8;
            let bytes = unsafe { std::slice::from_raw_parts(data, len) };
            return Ok(Arc::new(Values::Value::STRING { string: arcstr::ArcStr::from(String::from_utf8_lossy(bytes)) }));
        }
        let val = f64::from_bits(unsafe { slot(base, 1) } as u64);
        return Ok(Arc::new(Values::Value::REAL { real: metamodelica::Real::from(val) }));
    }
    // Struct: distinguish by constructor / slot count.
    let ctor = (hdr >> 2) & 0xff;
    let slots = hdr >> 10;
    match (ctor, slots) {
        _ if hdr == MMC_NILHDR => Ok(Arc::new(Values::Value::LIST { valueLst: metamodelica::nil() })),
        _ if hdr == MMC_CONSHDR => {
            // Walk the cons spine, decoding each element.
            let mut items: Vec<Arc<Values::Value>> = Vec::new();
            let mut cur = m;
            loop {
                let b = cur - 3;
                let h = unsafe { *(b as *const usize) };
                if h == MMC_NILHDR {
                    break;
                }
                if h != MMC_CONSHDR {
                    bail!("DynLoad.executeFunction: malformed list");
                }
                items.push(decode_metatype(unsafe { slot(b, 1) })?);
                cur = unsafe { slot(b, 2) };
            }
            Ok(Arc::new(Values::Value::LIST { valueLst: Arc::new(List::from_iter(items)) }))
        }
        _ if hdr == MMC_NONEHDR => Ok(Arc::new(Values::Value::OPTION { some: None })),
        _ if hdr == MMC_SOMEHDR => {
            Ok(Arc::new(Values::Value::OPTION { some: Some(decode_metatype(unsafe { slot(base, 1) })?) }))
        }
        // MetaModelica array (`arrayCreate`): every slot is an element.
        (MMC_ARRAY_CTOR, n) => {
            let mut items: Vec<Arc<Values::Value>> = Vec::with_capacity(n);
            for i in 1..=n {
                items.push(decode_metatype(unsafe { slot(base, i) })?);
            }
            Ok(Arc::new(Values::Value::META_ARRAY { valueLst: Arc::new(List::from_iter(items)) }))
        }
        // Constructor 0 with at least one field is a MetaModelica tuple.
        (0, n) if n >= 1 => {
            let mut items: Vec<Arc<Values::Value>> = Vec::with_capacity(n);
            for i in 1..=n {
                items.push(decode_metatype(unsafe { slot(base, i) })?);
            }
            Ok(Arc::new(Values::Value::META_TUPLE { valueLst: Arc::new(List::from_iter(items)) }))
        }
        // Constructor >= 2 is a record/uniontype instance: slot 1 points
        // (untagged) at the generated `record_description`, the fields follow.
        // ctor == Values.RECORD index + 3, so ctor 2 is a plain record (-1).
        (c, n) if c >= 2 && n >= 1 => {
            let desc = unsafe { &*(slot(base, 1) as *const RecordDescription) };
            let mut vals: Vec<Arc<Values::Value>> = Vec::with_capacity(n - 1);
            let mut comps: Vec<ArcStr> = Vec::with_capacity(n - 1);
            for i in 2..=n {
                vals.push(decode_metatype(unsafe { slot(base, i) })?);
                // A missing field name decodes as "(null)", like the C runtime.
                let fname = unsafe { *desc.field_names.add(i - 2) };
                comps.push(if fname.is_null() { arcstr::literal!("(null)") } else { ArcStr::from(read_c_str(fname)?) });
            }
            Ok(Arc::new(Values::Value::RECORD {
                record_: underscore_name_to_path(&read_c_str(desc.path)?),
                orderd: Arc::new(List::from_iter(vals)),
                comp: Arc::new(List::from_iter(comps)),
                index: c as i32 - 3,
            }))
        }
        _ => bail!("DynLoad.executeFunction: unsupported MMC header {hdr:#x}"),
    }
}

/// Body of `DynLoad.executeFunction`: call the dynamically loaded `in_*` entry
/// point identified by `handle`, marshalling `values` in and the result out. A
/// non-zero return from `in_*` means the generated function failed (`MMC_THROW`);
/// the C runtime returns `Values.META_FAIL` for that, so we do too.
/// Interned `record_description`s for the Flags structures marshalled by
/// [`sync_flags_global_root`]. Indexed by the MMC constructor they describe;
/// built once (the descriptions are immutable and deliberately leaked).
fn flag_data_descs() -> &'static [usize; 8] {
    static DESCS: std::sync::OnceLock<[usize; 8]> = std::sync::OnceLock::new();
    DESCS.get_or_init(|| {
        let d = |mangled: &str, dotted: &str, fields: &[&str]| {
            leak_record_description_raw(mangled, dotted, fields)
                .expect("static record description")
        };
        [
            d("Flags_FlagData_EMPTY__FLAG", "Flags.FlagData.EMPTY_FLAG", &[]),
            d("Flags_FlagData_BOOL__FLAG", "Flags.FlagData.BOOL_FLAG", &["data"]),
            d("Flags_FlagData_INT__FLAG", "Flags.FlagData.INT_FLAG", &["data"]),
            d("Flags_FlagData_INT__LIST__FLAG", "Flags.FlagData.INT_LIST_FLAG", &["data"]),
            d("Flags_FlagData_REAL__FLAG", "Flags.FlagData.REAL_FLAG", &["data"]),
            d("Flags_FlagData_STRING__FLAG", "Flags.FlagData.STRING_FLAG", &["data"]),
            d("Flags_FlagData_STRING__LIST__FLAG", "Flags.FlagData.STRING_LIST_FLAG", &["data"]),
            d("Flags_FlagData_ENUM__FLAG", "Flags.FlagData.ENUM_FLAG", &["data", "validValues"]),
        ]
    })
}

/// Encode one [`Flags::FlagData`] as an MMC record box. Constructor numbers
/// are `3 + declaration index` like every MMC uniontype record.
fn flag_data_to_mmc(rt: &MmcAlloc, fd: &openmodelica_util::Flags::FlagData) -> Result<usize> {
    use openmodelica_util::Flags::FlagData;
    let descs = flag_data_descs();
    let cons_spine = |rt: &MmcAlloc, items: Vec<usize>| {
        let mut lst = rt.mk_box(0, &[]); // {}
        for item in items.into_iter().rev() {
            lst = rt.mk_box(1, &[item, lst]);
        }
        lst
    };
    Ok(match fd {
        FlagData::EMPTY_FLAG => rt.mk_box(3, &[descs[0]]),
        FlagData::BOOL_FLAG { data } => rt.mk_box(4, &[descs[1], mmc_immediate(*data as i64)]),
        FlagData::INT_FLAG { data } => rt.mk_box(5, &[descs[2], mmc_immediate(*data as i64)]),
        FlagData::INT_LIST_FLAG { data } => {
            let items: Vec<usize> = (&**data).into_iter().map(|i| mmc_immediate(*i as i64)).collect();
            rt.mk_box(6, &[descs[3], cons_spine(rt, items)])
        }
        FlagData::REAL_FLAG { data } => rt.mk_box(7, &[descs[4], (rt.mk_rcon)(data.into_inner())]),
        FlagData::STRING_FLAG { data } => rt.mk_box(8, &[descs[5], make_c_string(data)?]),
        FlagData::STRING_LIST_FLAG { data } => {
            let items: Vec<usize> = (&**data).into_iter().map(|s| make_c_string(s)).collect::<Result<_>>()?;
            rt.mk_box(9, &[descs[6], cons_spine(rt, items)])
        }
        FlagData::ENUM_FLAG { data, validValues } => {
            let items: Vec<usize> = (&**validValues)
                .into_iter()
                .map(|(name, value)| Ok(rt.mk_box(0, &[make_c_string(name)?, mmc_immediate(*value as i64)])))
                .collect::<Result<_>>()?;
            rt.mk_box(10, &[descs[7], mmc_immediate(*data as i64), cons_spine(rt, items)])
        }
    })
}

/// Mirror the host's Flags global root into the dlopened runtime.
///
/// In the C omc the `-d=gen` generated code runs inside the same MMC runtime
/// as the compiler, so `getGlobalRoot(Global.flagsIndex)` inside a generated
/// function sees the live flags. The Rust port dlopens a *separate* MMC
/// runtime whose global roots start unset, so any generated function that
/// consults Flags (`Flags.getConfigBool` & co. — e.g. `Dump.unparseStr`)
/// silently failed. Marshal the current FLAGS structure (an `array<Boolean>`
/// plus an `array<FlagData>`; the flag *descriptors* are not part of the
/// root) into the C heap and store it with `boxptr_setGlobalRoot` before
/// every call — flags can change between interactive statements. The root
/// set keeps the structure alive; the previous copy becomes garbage.
fn sync_flags_global_root(rt: &MmcAlloc, thread_data: *mut c_void) -> Result<()> {
    use openmodelica_util::Flags;
    let Flags::Flag::FLAGS { debugFlags, configFlags } = Flags::getFlags(true) else {
        return Ok(()); // host flags not loaded yet: nothing to mirror
    };
    let debug: Vec<usize> = debugFlags.borrow().iter().map(|b| mmc_immediate(*b as i64)).collect();
    let config: Vec<usize> = configFlags
        .borrow()
        .iter()
        .map(|fd| flag_data_to_mmc(rt, fd))
        .collect::<Result<_>>()?;
    static FLAGS_DESC: std::sync::OnceLock<usize> = std::sync::OnceLock::new();
    let desc = *FLAGS_DESC.get_or_init(|| {
        leak_record_description_raw("Flags_Flag_FLAGS", "Flags.Flag.FLAGS", &["debugFlags", "configFlags"])
            .expect("static record description")
    });
    let flags_box = rt.mk_box(3, &[
        desc,
        rt.mk_box(MMC_ARRAY_CTOR, &debug),
        rt.mk_box(MMC_ARRAY_CTOR, &config),
    ]);
    let set_root = dynload::runtime_symbol("boxptr_setGlobalRoot")
        .ok_or_else(|| anyhow::anyhow!("runtime symbol `boxptr_setGlobalRoot` not found"))?;
    let set_root: extern "C" fn(*mut c_void, usize, usize) = unsafe { std::mem::transmute(set_root) };
    set_root(thread_data, mmc_immediate(openmodelica_util::Global::flagsIndex as i64), flags_box);
    Ok(())
}

/// `omc_Error_getCurrentComponent`, exported for the dlopened `-d=gen`
/// runtime: libomcruntime.so's error reporting (`c_add_message` in
/// errorext.cpp) calls back into the *compiler* for the current
/// instantiation-context prefix. In the C omc that symbol comes from the
/// compiled Error module inside the omc executable; the Rust port must
/// provide it itself or `dlopen` of any generated function linking
/// `-lomcruntime` fails with an unresolved-symbol error. Delegates to the
/// port's Error module and marshals the two strings into the caller's MMC
/// heap (the GC is paused around every `executeFunction` call, so they stay
/// put while errorext copies them). Exported from the executable's dynamic
/// symbol table via the link flag in `openmodelica/build.rs`.
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
    let str_box = make_c_string(s.as_str()).unwrap_or_else(|e| {
        eprintln!("omc_Error_getCurrentComponent: {e}");
        std::process::abort()
    });
    let file_box = make_c_string(file.as_str()).unwrap_or_else(|e| {
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

pub fn executeFunction(handle: i32, values: Arc<List<Arc<Values::Value>>>, _debug: bool) -> Result<Arc<Values::Value>> {
    let addr = dynload::function_addr(handle)?;
    let thread_data = dynload::thread_data()? as *mut c_void;

    // Argument and result metatypes (boxed strings, lists, …) are only reachable
    // from the C `type_description` buffers and the GC has no roots into them, so
    // a collection triggered while the function runs could free them underneath
    // us. Pause the collector across marshalling, the call, and decoding; the
    // `-d=gen` functions evaluated this way are small. No-op for purely scalar
    // calls.
    let gc_disable = dynload::runtime_symbol("GC_disable");
    let gc_enable = dynload::runtime_symbol("GC_enable");
    if let Some(d) = gc_disable {
        let d: extern "C" fn() = unsafe { std::mem::transmute(d) };
        d();
    }
    let result = executeFunctionGuarded(addr, thread_data, &values);
    if let Some(e) = gc_enable {
        let e: extern "C" fn() = unsafe { std::mem::transmute(e) };
        e();
    }
    result
}

fn executeFunctionGuarded(addr: usize, thread_data: *mut c_void, values: &Arc<List<Arc<Values::Value>>>) -> Result<Arc<Values::Value>> {
    let rt = MmcAlloc::resolve()?;
    // Generated functions read the compiler flags through the dlopened
    // runtime's global roots; keep them in sync with the host's (see
    // `sync_flags_global_root`).
    sync_flags_global_root(&rt, thread_data)?;
    // Keeps the buffers behind structured arguments alive until after the call
    // (and after result decoding — a result may alias argument data).
    let mut store = ArgStorage::default();
    let mut args: Vec<TypeDesc> = Vec::new();
    for v in &**values {
        args.push(value_to_desc(&rt, v, &mut store)?);
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
    // returns through `MMC_CATCH_TOP` before its own trailing `fflush`, so a
    // function's `print` side effects would otherwise surface out of order
    // (after the caller has already printed this call's result).
    if let Some(fflush_addr) = dynload::runtime_symbol("fflush") {
        let fflush: extern "C" fn(*mut c_void) -> i32 = unsafe { std::mem::transmute(fflush_addr) };
        fflush(std::ptr::null_mut());
    }

    if rc != 0 {
        return Ok(Arc::new(Values::Value::META_FAIL));
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
