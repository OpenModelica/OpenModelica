// Manually written file.
//
// Rust port of `OMCompiler/Compiler/runtime/ffi_omc.cpp`: the dynamic
// foreign-function call behind `FFI.callFunction` (Compiler/Util/FFI.mo),
// used by `NFEvalFunction.callExternalFunction` to evaluate `external "C"`
// functions from shared libraries at compile time.
//
// The C implementation marshals `NFExpression` values to C values, performs
// the call through libffi, and converts the results back. We use the
// `libffi` crate (bundled libffi built via cc, no system dependency) and
// mirror the C marshalling:
//
//   * Scalars map to C `int` (Integer/Boolean/enumeration index), `double`
//     (Real) and `char*` (String).
//   * Arrays are written as one contiguous buffer of scalars (row-major,
//     same as the C `write_exp_value` recursion) and passed by pointer.
//   * Records are written as a C struct (offsets computed with the standard
//     C layout algorithm, like `ffi_get_struct_offsets`) and passed by
//     pointer.
//   * INPUT scalars are passed by value; INPUT arrays/records and all
//     OUTPUT/LOCAL arguments are passed by pointer to a caller-owned buffer
//     that is read back after the call.
//
// Because records and arrays always travel by pointer, the only ffi-level
// types are sint/double/pointer/void — libffi's struct-by-value support is
// never needed; struct layout only drives our own buffer (de)serialisation.
//
// Known C-side quirks preserved here (documented, not "fixed", so the port
// stays comparable to the reference):
//   * Arrays nested inside records are laid out as a pointer-sized field
//     (`exp_alignment_and_type`'s ARRAY case), not inline storage.
//   * An array *element* alignment is only computed from the first element
//     (`align->fields[0]`), and `write_exp_value` passes the array's own
//     alignment record down to its elements, so arrays of records do not
//     round-trip — same as the C code.
// Where the C code would read through invalid pointers (e.g. a NULL string
// returned by the external function), we fail with an error instead of
// crashing; that is the only intentional behavioural difference.

#![allow(warnings)]
#![allow(non_snake_case, non_camel_case_types)]

use std::ffi::{CStr, CString};
use std::sync::Arc;

use anyhow::{Result, bail};
use arcstr::ArcStr;
use libffi::middle::{Cif, Type as MiddleType};

unsafe extern "C" {
    /// C++ shim (src/ffi_catch.cpp): performs the libffi call inside a
    /// `try { } catch (...) { }` so that an exception thrown by the external
    /// function becomes a plain failure instead of unwinding through Rust
    /// frames (which aborts). Returns 0 on success, 1 if an exception was
    /// caught — mirroring ffi_omc.cpp's `try { ffi_call(...) } catch (...)
    /// { MMC_THROW(); }`.
    fn omrs_ffi_call_catch(
        cif: *mut libc::c_void,
        f: Option<unsafe extern "C" fn()>,
        rvalue: *mut libc::c_void,
        avalue: *mut *mut libc::c_void,
    ) -> libc::c_int;
}

use crate::NFDimension as Dimension;
use crate::NFExpression as Expression;
use crate::NFType as Type;

#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
#[repr(i32)]
pub enum ArgSpec {
    INPUT = 1,
    OUTPUT = 2,
    LOCAL = 3,
}
impl PartialOrd for ArgSpec {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> { Some(self.cmp(other)) }
}
impl Ord for ArgSpec {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering { (*self as i32).cmp(&(*other as i32)) }
}
impl Default for ArgSpec {
    fn default() -> Self { Self::INPUT }
}

/// The C type an expression or type maps to at the ffi level
/// (`type_to_type_spec` / the return value of `exp_alignment_and_type`).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum CType {
    SInt,
    Double,
    Pointer,
    Void,
}

impl CType {
    fn middle_type(self) -> MiddleType {
        match self {
            // `c_int` is 32-bit on every platform the port targets
            // (LP64 Linux and LLP64 Windows alike).
            CType::SInt => MiddleType::i32(),
            CType::Double => MiddleType::f64(),
            CType::Pointer => MiddleType::pointer(),
            CType::Void => MiddleType::void(),
        }
    }

    /// Natural C alignment of the value; only used for struct field layout.
    fn align(self) -> usize {
        match self {
            CType::SInt => 4,
            CType::Double | CType::Pointer => 8,
            CType::Void => 1,
        }
    }
}

/// Mirror of `struct Alignment` in ffi_omc.cpp, with the alignment made
/// explicit (the C version gets it implicitly from the ffi_type it builds
/// for `ffi_get_struct_offsets`).
#[derive(Clone, Debug, Default)]
struct Alignment {
    /// Size in bytes of the value when stored as a struct field.
    size: usize,
    /// C alignment requirement of the value.
    align: usize,
    /// Byte offset of each record field (records only).
    offsets: Vec<usize>,
    /// Field alignments: one per record field, or the first element's
    /// alignment for arrays (see the module comment on quirks).
    fields: Vec<Alignment>,
}

fn round_up(n: usize, align: usize) -> usize {
    let align = align.max(1);
    n.div_ceil(align) * align
}

fn list_len<T: Clone>(list: &Arc<metamodelica::List<T>>) -> usize {
    let mut n = 0;
    let mut cur = list;
    while let metamodelica::List::Cons { tail, .. } = &**cur {
        n += 1;
        cur = tail;
    }
    n
}

/// `array_dim_size`: the number of values a dimension spans.
fn dim_size(dim: &Dimension::NFDimension) -> usize {
    match dim {
        Dimension::NFDimension::INTEGER { size, .. } => (*size).max(0) as usize,
        Dimension::NFDimension::BOOLEAN => 2,
        Dimension::NFDimension::ENUM { enumType } => match &**enumType {
            Type::NFType::ENUMERATION { literals, .. } => list_len(literals),
            _ => 0,
        },
        _ => 0,
    }
}

/// `array_length`: the size of an array type's *first* dimension,
/// i.e. `Real[2, 3]` => 2.
fn array_length(ty: &Type::NFType) -> usize {
    match ty {
        Type::NFType::ARRAY { dimensions, .. } => match &**dimensions {
            metamodelica::List::Cons { head, .. } => dim_size(head),
            metamodelica::List::Nil => 0,
        },
        _ => 0,
    }
}

/// `array_scalar_count`: the total number of scalar elements of an array
/// type, i.e. `Real[2, 3]` => 6.
fn array_scalar_count(ty: &Type::NFType) -> usize {
    match ty {
        Type::NFType::ARRAY { dimensions, .. } => {
            let mut count = 1usize;
            let mut cur = dimensions;
            while let metamodelica::List::Cons { head, tail } = &**cur {
                count *= dim_size(head);
                cur = tail;
            }
            count
        }
        _ => 1,
    }
}

/// `unlift_array_type`: the array type with its first dimension removed.
fn unlift_array_type(ty: &Arc<Type::NFType>) -> Arc<Type::NFType> {
    match &**ty {
        Type::NFType::ARRAY { elementType, dimensions } => {
            let rest = match &**dimensions {
                metamodelica::List::Cons { tail, .. } => tail.clone(),
                metamodelica::List::Nil => metamodelica::nil(),
            };
            Arc::new(Type::NFType::ARRAY { elementType: elementType.clone(), dimensions: rest })
        }
        _ => ty.clone(),
    }
}

/// `size_of_type`: size in bytes of the C value corresponding to a type.
fn size_of_type(ty: &Type::NFType) -> usize {
    match ty {
        Type::NFType::INTEGER | Type::NFType::BOOLEAN | Type::NFType::ENUMERATION { .. } => 4,
        Type::NFType::REAL => 8,
        Type::NFType::STRING => 8,
        Type::NFType::ARRAY { elementType, .. } => {
            size_of_type(elementType) * array_scalar_count(ty)
        }
        _ => 0,
    }
}

/// `type_to_type_spec`: the ffi-level C type for a type.
fn type_ctype(ty: &Type::NFType) -> CType {
    match ty {
        Type::NFType::INTEGER | Type::NFType::BOOLEAN | Type::NFType::ENUMERATION { .. } => {
            CType::SInt
        }
        Type::NFType::REAL => CType::Double,
        Type::NFType::STRING | Type::NFType::ARRAY { .. } | Type::NFType::COMPLEX { .. } => {
            CType::Pointer
        }
        _ => CType::Void,
    }
}

/// `is_exp_pointer_type`: arguments passed by pointer even as INPUT.
fn is_exp_pointer_type(exp: &Expression::NFExpression) -> bool {
    matches!(
        exp,
        Expression::NFExpression::ARRAY { .. } | Expression::NFExpression::RECORD { .. }
    )
}

/// `exp_alignment_and_type`: the ffi-level C type of an argument expression
/// plus the layout information needed to (de)serialise it. The returned
/// [`Alignment`] carries the *field-level* size/alignment (the C version's
/// `field = 1` view), while the returned [`CType`] is the *argument-level*
/// type (`field = 0`), where records collapse to a pointer.
fn exp_alignment(exp: &Expression::NFExpression) -> Result<(CType, Alignment)> {
    Ok(match exp {
        Expression::NFExpression::INTEGER { .. }
        | Expression::NFExpression::BOOLEAN { .. }
        | Expression::NFExpression::ENUM_LITERAL { .. } => {
            (CType::SInt, Alignment { size: 4, align: 4, ..Default::default() })
        }
        Expression::NFExpression::REAL { .. } => {
            (CType::Double, Alignment { size: 8, align: 8, ..Default::default() })
        }
        Expression::NFExpression::STRING { .. } => {
            (CType::Pointer, Alignment { size: 8, align: 8, ..Default::default() })
        }
        Expression::NFExpression::ARRAY { elements, .. } => {
            let mut fields = Vec::new();
            let elems = elements.borrow();
            if let Some(first) = elems.first() {
                fields.push(exp_alignment(first)?.1);
            }
            (CType::Pointer, Alignment { size: 8, align: 8, offsets: Vec::new(), fields })
        }
        Expression::NFExpression::RECORD { elements, .. } => {
            // Standard C struct layout, like `ffi_get_struct_offsets`:
            // each field is placed at the next multiple of its alignment,
            // and the struct size is rounded up to the largest alignment.
            let mut fields = Vec::new();
            let mut offsets = Vec::new();
            let mut off = 0usize;
            let mut max_align = 1usize;
            let mut cur = elements;
            while let metamodelica::List::Cons { head, tail } = &**cur {
                let (_, field) = exp_alignment(head)?;
                off = round_up(off, field.align);
                offsets.push(off);
                off += field.size;
                max_align = max_align.max(field.align);
                fields.push(field);
                cur = tail;
            }
            let size = round_up(off, max_align);
            (CType::Pointer, Alignment { size, align: max_align, offsets, fields })
        }
        Expression::NFExpression::EMPTY { ty } => {
            let ctype = type_ctype(ty);
            (ctype, Alignment { size: size_of_type(ty), align: ctype.align(), ..Default::default() })
        }
        _ => bail!("FFI.callFunction: unsupported argument expression"),
    })
}

/// `size_of_exp`: size in bytes of an expression's C value buffer.
fn size_of_exp(exp: &Expression::NFExpression, align: &Alignment) -> usize {
    match exp {
        Expression::NFExpression::INTEGER { .. }
        | Expression::NFExpression::BOOLEAN { .. }
        | Expression::NFExpression::ENUM_LITERAL { .. } => 4,
        Expression::NFExpression::REAL { .. } => 8,
        Expression::NFExpression::STRING { .. } => 8,
        Expression::NFExpression::ARRAY { ty, .. } => size_of_type(ty),
        Expression::NFExpression::RECORD { .. } => align.size,
        Expression::NFExpression::EMPTY { ty } => size_of_type(ty),
        _ => 0,
    }
}

/// `write_exp_value`: serialise an expression into the buffer at `ptr`,
/// returning the position just after the written value. Strings are
/// NUL-terminated copies whose storage is kept alive in `strings` until the
/// call (and the output read-back) is done.
unsafe fn write_exp_value(
    exp: &Expression::NFExpression,
    ptr: *mut u8,
    align: &Alignment,
    strings: &mut Vec<CString>,
) -> Result<*mut u8> {
    unsafe {
        Ok(match exp {
            Expression::NFExpression::INTEGER { value } => {
                (ptr as *mut i32).write_unaligned(*value);
                ptr.add(4)
            }
            Expression::NFExpression::BOOLEAN { value } => {
                (ptr as *mut i32).write_unaligned(if *value { 1 } else { 0 });
                ptr.add(4)
            }
            Expression::NFExpression::REAL { value } => {
                (ptr as *mut f64).write_unaligned(value.0);
                ptr.add(8)
            }
            Expression::NFExpression::STRING { value } => {
                let c = CString::new(value.as_bytes())
                    .map_err(|_| anyhow::anyhow!("FFI.callFunction: string argument contains NUL"))?;
                (ptr as *mut *const libc::c_char).write_unaligned(c.as_ptr());
                strings.push(c);
                ptr.add(8)
            }
            Expression::NFExpression::ENUM_LITERAL { index, .. } => {
                (ptr as *mut i32).write_unaligned(*index);
                ptr.add(4)
            }
            Expression::NFExpression::ARRAY { elements, .. } => {
                let mut p = ptr;
                for elem in elements.borrow().iter() {
                    p = write_exp_value(elem, p, align, strings)?;
                }
                p
            }
            Expression::NFExpression::RECORD { elements, .. } => {
                let mut cur = elements;
                let mut i = 0usize;
                while let metamodelica::List::Cons { head, tail } = &**cur {
                    if i >= align.offsets.len() {
                        break;
                    }
                    write_exp_value(head, ptr.add(align.offsets[i]), &align.fields[i], strings)?;
                    i += 1;
                    cur = tail;
                }
                ptr.add(align.size)
            }
            // EMPTY (output placeholders) and anything else: nothing to
            // write; the zero-initialised buffer is the value.
            _ => ptr,
        })
    }
}

unsafe fn mk_int_exp(ptr: *const u8) -> Arc<Expression::NFExpression> {
    Arc::new(Expression::NFExpression::INTEGER {
        value: unsafe { (ptr as *const i32).read_unaligned() },
    })
}

unsafe fn mk_bool_exp(ptr: *const u8) -> Arc<Expression::NFExpression> {
    Arc::new(Expression::NFExpression::BOOLEAN {
        value: unsafe { (ptr as *const i32).read_unaligned() } != 0,
    })
}

unsafe fn mk_real_exp(ptr: *const u8) -> Arc<Expression::NFExpression> {
    Arc::new(Expression::NFExpression::REAL {
        value: metamodelica::OrderedFloat(unsafe { (ptr as *const f64).read_unaligned() }),
    })
}

unsafe fn mk_string_exp(ptr: *const u8) -> Result<Arc<Expression::NFExpression>> {
    let s = unsafe { (ptr as *const *const libc::c_char).read_unaligned() };
    if s.is_null() {
        // The C version would crash here; fail instead.
        bail!("FFI.callFunction: external function returned a NULL string");
    }
    let value = ArcStr::from(unsafe { CStr::from_ptr(s) }.to_string_lossy().as_ref());
    Ok(Arc::new(Expression::NFExpression::STRING { value }))
}

/// `lookup_enum_literal_name` + `mk_enum_exp`: read a 1-based enumeration
/// index and build the corresponding literal expression.
unsafe fn mk_enum_exp(
    ptr: *const u8,
    enum_ty: &Arc<Type::NFType>,
) -> Result<Arc<Expression::NFExpression>> {
    let index = unsafe { (ptr as *const i32).read_unaligned() };
    let Type::NFType::ENUMERATION { literals, .. } = &**enum_ty else {
        bail!("FFI.callFunction: expected an enumeration type");
    };
    if index < 1 {
        bail!("FFI.callFunction: enumeration index {index} out of range");
    }
    let mut cur = literals;
    let mut i = 1;
    while let metamodelica::List::Cons { head, tail } = &**cur {
        if i == index {
            return Ok(Arc::new(Expression::NFExpression::ENUM_LITERAL {
                ty: enum_ty.clone(),
                name: head.clone(),
                index,
            }));
        }
        i += 1;
        cur = tail;
    }
    bail!("FFI.callFunction: enumeration index {index} out of range")
}

/// `mk_array_exp` / `mk_array_exp_2`: deserialise a contiguous C array into
/// a (possibly nested) ARRAY expression of the given array type.
unsafe fn mk_array_exp(ptr: *const u8, ty: &Arc<Type::NFType>) -> Result<Arc<Expression::NFExpression>> {
    let Type::NFType::ARRAY { elementType, dimensions } = &**ty else {
        bail!("FFI.callFunction: expected an array type");
    };
    let dim_count = list_len(dimensions);
    let elem_count = array_scalar_count(ty);
    let elem_size = size_of_type(elementType);

    let elems: Vec<Arc<Expression::NFExpression>> = if dim_count <= 1 {
        let mut v = Vec::with_capacity(elem_count);
        for i in 0..elem_count {
            let p = unsafe { ptr.add(i * elem_size) };
            v.push(match &**elementType {
                Type::NFType::INTEGER => unsafe { mk_int_exp(p) },
                Type::NFType::BOOLEAN => unsafe { mk_bool_exp(p) },
                Type::NFType::REAL => unsafe { mk_real_exp(p) },
                Type::NFType::STRING => unsafe { mk_string_exp(p) }?,
                Type::NFType::ENUMERATION { .. } => unsafe { mk_enum_exp(p, elementType) }?,
                _ => bail!("FFI.callFunction: unsupported array element type"),
            });
        }
        v
    } else {
        // Split the buffer into `array_length` equal chunks and convert
        // each chunk into an element of the unlifted array type.
        let arr_len = array_length(ty);
        let chunk_scalars = if arr_len == 0 { 0 } else { elem_count / arr_len };
        let chunk_bytes = elem_size * chunk_scalars;
        let elem_ty = unlift_array_type(ty);
        let mut v = Vec::with_capacity(arr_len);
        for i in 0..arr_len {
            v.push(unsafe { mk_array_exp(ptr.add(i * chunk_bytes), &elem_ty) }?);
        }
        v
    };

    Ok(Arc::new(Expression::NFExpression::ARRAY {
        ty: ty.clone(),
        elements: std::rc::Rc::new(std::cell::RefCell::new(elems)),
        literal: true,
    }))
}

/// `mk_record_exp`: deserialise a C struct into a RECORD expression shaped
/// like `arg` (another record expression of the same type).
unsafe fn mk_record_exp(
    ptr: *const u8,
    arg: &Expression::NFExpression,
    align: &Alignment,
) -> Result<Arc<Expression::NFExpression>> {
    let Expression::NFExpression::RECORD { path, ty, elements } = arg else {
        bail!("FFI.callFunction: expected a record expression");
    };
    let mut out: Vec<Arc<Expression::NFExpression>> = Vec::with_capacity(align.fields.len());
    let mut cur = elements;
    let mut i = 0usize;
    while let metamodelica::List::Cons { head, tail } = &**cur {
        if i >= align.fields.len() {
            break;
        }
        out.push(unsafe { mk_exp_from_arg(head, ptr.add(align.offsets[i]), &align.fields[i]) }?);
        i += 1;
        cur = tail;
    }
    let mut list = metamodelica::nil();
    for e in out.into_iter().rev() {
        list = metamodelica::cons(e, list);
    }
    Ok(Arc::new(Expression::NFExpression::RECORD {
        path: path.clone(),
        ty: ty.clone(),
        elements: list,
    }))
}

/// `mk_exp_from_type`: deserialise a C value into an expression of `ty`.
unsafe fn mk_exp_from_type(
    ty: &Arc<Type::NFType>,
    ptr: *const u8,
) -> Result<Arc<Expression::NFExpression>> {
    Ok(match &**ty {
        Type::NFType::INTEGER => unsafe { mk_int_exp(ptr) },
        Type::NFType::BOOLEAN => unsafe { mk_bool_exp(ptr) },
        Type::NFType::REAL => unsafe { mk_real_exp(ptr) },
        Type::NFType::STRING => unsafe { mk_string_exp(ptr) }?,
        Type::NFType::ENUMERATION { .. } => unsafe { mk_enum_exp(ptr, ty) }?,
        Type::NFType::ARRAY { .. } => unsafe { mk_array_exp(ptr, ty) }?,
        // No return value (NORETCALL etc.) or an unsupported type: an
        // EMPTY expression, same as the C default branch.
        _ => Arc::new(Expression::NFExpression::EMPTY { ty: ty.clone() }),
    })
}

/// `mk_exp_from_arg`: deserialise a C value into an expression shaped like
/// the given argument expression.
unsafe fn mk_exp_from_arg(
    arg: &Expression::NFExpression,
    ptr: *const u8,
    align: &Alignment,
) -> Result<Arc<Expression::NFExpression>> {
    Ok(match arg {
        Expression::NFExpression::INTEGER { .. } => unsafe { mk_int_exp(ptr) },
        Expression::NFExpression::BOOLEAN { .. } => unsafe { mk_bool_exp(ptr) },
        Expression::NFExpression::REAL { .. } => unsafe { mk_real_exp(ptr) },
        Expression::NFExpression::STRING { .. } => unsafe { mk_string_exp(ptr) }?,
        Expression::NFExpression::ENUM_LITERAL { ty, .. } => unsafe { mk_enum_exp(ptr, ty) }?,
        Expression::NFExpression::ARRAY { ty, .. } => unsafe { mk_array_exp(ptr, ty) }?,
        Expression::NFExpression::RECORD { .. } => unsafe { mk_record_exp(ptr, arg, align) }?,
        Expression::NFExpression::EMPTY { ty } => unsafe { mk_exp_from_type(ty, ptr) }?,
        _ => bail!("FFI.callFunction: unsupported argument expression"),
    })
}

/// One marshalled argument: the value buffer, plus (for by-pointer
/// arguments) an extra pointer-sized slot holding the buffer's address.
/// The address passed to libffi is `wrapper`'s address when present,
/// otherwise `data`'s — libffi reads the argument *value* from there.
struct MarshalledArg {
    data: Vec<u8>,
    wrapper: Option<Box<*mut u8>>,
}

impl MarshalledArg {
    fn ffi_addr(&self) -> *mut libc::c_void {
        match &self.wrapper {
            Some(w) => &**w as *const *mut u8 as *mut libc::c_void,
            None => self.data.as_ptr() as *mut libc::c_void,
        }
    }
}

/// Port of `FFI_callFunction`. Calls the function behind `fnHandle` (from
/// `System.lookupFunction`) with the marshalled `args` and returns the
/// converted return value plus the read-back OUTPUT arguments, in
/// declaration order.
pub fn callFunction(
    fnHandle: i32,
    args: metamodelica::Array<Arc<Expression::NFExpression>>,
    specs: metamodelica::Array<ArgSpec>,
    returnType: Arc<Type::NFType>,
) -> Result<(Arc<Expression::NFExpression>, Arc<metamodelica::List<Arc<Expression::NFExpression>>>)> {
    let fn_addr = openmodelica_util::dynload::function_addr(fnHandle)?;

    let args_vec: Vec<Arc<Expression::NFExpression>> = args.borrow().clone();
    let specs_vec: Vec<ArgSpec> = specs.borrow().clone();
    if args_vec.len() != specs_vec.len() {
        bail!("FFI.callFunction: argument/spec count mismatch");
    }

    // Marshal the arguments. String storage must outlive both the call and
    // the output read-back (an output char* may point at an input string).
    let mut strings: Vec<CString> = Vec::new();
    let mut marshalled: Vec<MarshalledArg> = Vec::with_capacity(args_vec.len());
    let mut aligns: Vec<Alignment> = Vec::with_capacity(args_vec.len());
    let mut ffi_types: Vec<MiddleType> = Vec::with_capacity(args_vec.len());

    for (arg, spec) in args_vec.iter().zip(specs_vec.iter()) {
        let (ctype, align) = exp_alignment(arg)?;
        let mut data = vec![0u8; size_of_exp(arg, &align).max(1)];
        unsafe { write_exp_value(arg, data.as_mut_ptr(), &align, &mut strings)? };

        let by_pointer = *spec != ArgSpec::INPUT || is_exp_pointer_type(arg);
        let wrapper = if by_pointer { Some(Box::new(data.as_mut_ptr())) } else { None };
        ffi_types.push(if by_pointer { MiddleType::pointer() } else { ctype.middle_type() });
        marshalled.push(MarshalledArg { data, wrapper });
        aligns.push(align);
    }

    // Prepare and perform the call through the C++ exception barrier.
    // `ret_buf` must be at least `ffi_arg`-sized: libffi widens integral
    // return values to a full word, which it writes whole. Reading the i32
    // from the buffer start afterwards relies on little-endian layout —
    // fine for every target the port supports (x86-64 / aarch64 / Windows).
    let ret_ctype = type_ctype(&returnType);
    let cif = Cif::new(ffi_types, ret_ctype.middle_type());
    let mut ffi_args: Vec<*mut libc::c_void> = marshalled.iter().map(|m| m.ffi_addr()).collect();
    let mut ret_buf = vec![0u8; size_of_type(&returnType).max(8)];

    let caught = unsafe {
        omrs_ffi_call_catch(
            cif.as_raw_ptr() as *mut libc::c_void,
            Some(std::mem::transmute::<usize, unsafe extern "C" fn()>(fn_addr)),
            ret_buf.as_mut_ptr() as *mut libc::c_void,
            ffi_args.as_mut_ptr(),
        )
    };
    if caught != 0 {
        // Same as the C version's catch-all: the call failed, make the
        // surrounding evaluation fail (NFEvalFunction reports it).
        bail!("FFI.callFunction: external function threw an exception");
    }

    // Read back the OUTPUT arguments, in declaration order.
    let mut outputs: Vec<Arc<Expression::NFExpression>> = Vec::new();
    for (i, spec) in specs_vec.iter().enumerate() {
        if *spec == ArgSpec::OUTPUT {
            let value =
                unsafe { mk_exp_from_arg(&args_vec[i], marshalled[i].data.as_ptr(), &aligns[i]) }?;
            outputs.push(value);
        }
    }
    let mut output_list = metamodelica::nil();
    for o in outputs.into_iter().rev() {
        output_list = metamodelica::cons(o, output_list);
    }

    let return_value = unsafe { mk_exp_from_type(&returnType, ret_buf.as_ptr()) }?;
    drop(strings); // explicit: string storage must live until after read-back
    Ok((return_value, output_list))
}
