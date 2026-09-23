//! wasm counterpart of [`crate::FFI`], which evaluates `external "C"` by dlopen +
//! libffi. Here the library is a wasm shared library with its own memory, loaded
//! by `openmodelica_wasm_jit::ext_eval`, so the marshalling mirrors `FFI.rs` —
//! same struct layout algorithm, same by-pointer rules, same documented quirks —
//! over wasm32's C ABI (a pointer is 4 bytes) and with the buffers written into
//! that memory.

use arcstr::ArcStr;
use metamodelica::Result;
use openmodelica_wasm_jit::ext_eval::{self, Val};

use super::ArgSpec;
use crate::NFDimension as Dimension;
use crate::NFExpression as Expression;
use crate::NFType as Type;

/// The wasm32 C type of a value.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum CType {
    SInt,
    Double,
    Pointer,
    Void,
}

impl CType {
    fn align(self) -> usize {
        match self {
            CType::SInt | CType::Pointer => 4,
            CType::Double => 8,
            CType::Void => 1,
        }
    }
}

/// Mirror of `FFI::Alignment`.
#[derive(Clone, Debug, Default)]
struct Alignment {
    size: usize,
    align: usize,
    offsets: Vec<usize>,
    /// One per record field, or the first element's for an array.
    fields: Vec<Alignment>,
}

/// The library a call runs in, and what it allocated for that call.
struct Ctx {
    func: i32,
    temps: Vec<u32>,
}

impl Ctx {
    fn alloc(&mut self, size: usize) -> Result<u32> {
        let off = ext_eval::malloc(self.func, size as u32).map_err(detail)?;
        if off == 0 {
            return Err("FFI.callFunction: the external library is out of memory");
        }
        self.temps.push(off);
        Ok(off)
    }

    fn write(&self, off: u32, bytes: &[u8]) -> Result<()> {
        ext_eval::write_mem(self.func, off, bytes).map_err(detail)
    }

    fn read(&self, off: u32, len: usize) -> Result<Vec<u8>> {
        let mut buf = vec![0u8; len];
        ext_eval::read_mem(self.func, off, &mut buf).map_err(detail)?;
        Ok(buf)
    }

    fn cstring(&self, off: u32) -> Result<ArcStr> {
        if off == 0 {
            // The native version would read through the NULL pointer; fail instead.
            return Err("FFI.callFunction: external function returned a NULL string");
        }
        Ok(ArcStr::from(ext_eval::read_cstring(self.func, off).map_err(detail)?))
    }

    /// A NUL-terminated copy of `s` in the library's memory.
    fn c_str_arg(&mut self, s: &str) -> Result<u32> {
        if s.as_bytes().contains(&0) {
            return Err("FFI.callFunction: string argument contains NUL");
        }
        let off = self.alloc(s.len() + 1)?;
        let mut bytes = s.as_bytes().to_vec();
        bytes.push(0);
        self.write(off, &bytes)?;
        Ok(off)
    }

    fn release(self) {
        for off in &self.temps {
            let _ = ext_eval::free(self.func, *off);
        }
        ext_eval::free_call_temps(self.func);
    }
}

/// The crate's error type cannot carry the engine's message; the buffer can.
fn detail(msg: String) -> &'static str {
    openmodelica_error::ErrorExt::runtime_error(&msg);
    "FFI.callFunction: the external function could not be called"
}

fn round_up(n: usize, align: usize) -> usize {
    let align = align.max(1);
    n.div_ceil(align) * align
}

fn list_len<T: Clone>(list: &metamodelica::List<T>) -> usize {
    list.iter().count()
}

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

/// The size of an array type's *first* dimension.
fn array_length(ty: &Type::NFType) -> usize {
    match ty {
        Type::NFType::ARRAY { dimensions, .. } => match &**dimensions {
            metamodelica::ListNode::Cons { head, .. } => dim_size(head),
            metamodelica::ListNode::Nil => 0,
        },
        _ => 0,
    }
}

fn array_scalar_count(ty: &Type::NFType) -> usize {
    match ty {
        Type::NFType::ARRAY { dimensions, .. } => {
            let mut count = 1usize;
            let mut cur = dimensions;
            while let metamodelica::ListNode::Cons { head, tail } = &**cur {
                count *= dim_size(head);
                cur = tail;
            }
            count
        }
        _ => 1,
    }
}

fn unlift_array_type(ty: &metamodelica::Ref<Type::NFType>) -> metamodelica::Ref<Type::NFType> {
    match &**ty {
        Type::NFType::ARRAY { elementType, dimensions } => {
            let rest = match &**dimensions {
                metamodelica::ListNode::Cons { tail, .. } => tail.clone(),
                metamodelica::ListNode::Nil => metamodelica::nil(),
            };
            metamodelica::Ref::new(Type::NFType::ARRAY { elementType: elementType.clone(), dimensions: rest })
        }
        _ => ty.clone(),
    }
}

fn size_of_type(ty: &Type::NFType) -> usize {
    match ty {
        Type::NFType::INTEGER | Type::NFType::BOOLEAN | Type::NFType::ENUMERATION { .. } => 4,
        Type::NFType::REAL => 8,
        Type::NFType::STRING => 4,
        Type::NFType::ARRAY { elementType, .. } => size_of_type(elementType) * array_scalar_count(ty),
        _ => 0,
    }
}

fn type_ctype(ty: &Type::NFType) -> CType {
    match ty {
        Type::NFType::INTEGER | Type::NFType::BOOLEAN | Type::NFType::ENUMERATION { .. } => CType::SInt,
        Type::NFType::REAL => CType::Double,
        Type::NFType::STRING | Type::NFType::ARRAY { .. } | Type::NFType::COMPLEX { .. } => CType::Pointer,
        _ => CType::Void,
    }
}

/// Arguments passed by pointer even as INPUT.
fn is_exp_pointer_type(exp: &Expression::NFExpression) -> bool {
    matches!(exp, Expression::NFExpression::ARRAY { .. } | Expression::NFExpression::RECORD { .. })
}

/// `FFI::exp_alignment`, with wasm32's pointer size.
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
            (CType::Pointer, Alignment { size: 4, align: 4, ..Default::default() })
        }
        Expression::NFExpression::ARRAY { elements, .. } => {
            let mut fields = Vec::new();
            let elems = elements.borrow();
            if let Some(first) = elems.first() {
                fields.push(exp_alignment(first)?.1);
            }
            (CType::Pointer, Alignment { size: 4, align: 4, offsets: Vec::new(), fields })
        }
        Expression::NFExpression::RECORD { elements, .. } => {
            let mut fields = Vec::new();
            let mut offsets = Vec::new();
            let mut off = 0usize;
            let mut max_align = 1usize;
            let mut cur = elements;
            while let metamodelica::ListNode::Cons { head, tail } = &**cur {
                let (_, field) = exp_alignment(head)?;
                off = round_up(off, field.align);
                offsets.push(off);
                off += field.size;
                max_align = max_align.max(field.align);
                fields.push(field);
                cur = tail;
            }
            (CType::Pointer, Alignment { size: round_up(off, max_align), align: max_align, offsets, fields })
        }
        Expression::NFExpression::EMPTY { ty } => {
            let ctype = type_ctype(ty);
            (ctype, Alignment { size: size_of_type(ty), align: ctype.align(), ..Default::default() })
        }
        _ => return Err("FFI.callFunction: unsupported argument expression"),
    })
}

fn size_of_exp(exp: &Expression::NFExpression, align: &Alignment) -> usize {
    match exp {
        Expression::NFExpression::INTEGER { .. }
        | Expression::NFExpression::BOOLEAN { .. }
        | Expression::NFExpression::ENUM_LITERAL { .. } => 4,
        Expression::NFExpression::REAL { .. } => 8,
        Expression::NFExpression::STRING { .. } => 4,
        Expression::NFExpression::ARRAY { ty, .. } => size_of_type(ty),
        Expression::NFExpression::RECORD { .. } => align.size,
        Expression::NFExpression::EMPTY { ty } => size_of_type(ty),
        _ => 0,
    }
}

fn put(buf: &mut [u8], at: usize, bytes: &[u8]) -> Result<()> {
    let end = at + bytes.len();
    if end > buf.len() {
        return Err("FFI.callFunction: argument buffer overrun");
    }
    buf[at..end].copy_from_slice(bytes);
    Ok(())
}

/// `FFI::write_exp_value`: serialise into `buf` at `at`, returning the position
/// just after the value. A string is copied into the library's memory and stored
/// as its offset.
fn write_exp_value(
    exp: &Expression::NFExpression,
    buf: &mut [u8],
    at: usize,
    align: &Alignment,
    ctx: &mut Ctx,
) -> Result<usize> {
    Ok(match exp {
        Expression::NFExpression::INTEGER { value } => {
            put(buf, at, &value.to_le_bytes())?;
            at + 4
        }
        Expression::NFExpression::BOOLEAN { value } => {
            put(buf, at, &i32::from(*value).to_le_bytes())?;
            at + 4
        }
        Expression::NFExpression::REAL { value } => {
            put(buf, at, &value.0.to_le_bytes())?;
            at + 8
        }
        Expression::NFExpression::STRING { value } => {
            let off = ctx.c_str_arg(value)?;
            put(buf, at, &off.to_le_bytes())?;
            at + 4
        }
        Expression::NFExpression::ENUM_LITERAL { index, .. } => {
            put(buf, at, &index.to_le_bytes())?;
            at + 4
        }
        Expression::NFExpression::ARRAY { elements, .. } => {
            let mut p = at;
            for elem in elements.borrow().iter() {
                p = write_exp_value(elem, buf, p, align, ctx)?;
            }
            p
        }
        Expression::NFExpression::RECORD { elements, .. } => {
            let mut cur = elements;
            let mut i = 0usize;
            while let metamodelica::ListNode::Cons { head, tail } = &**cur {
                if i >= align.offsets.len() {
                    break;
                }
                write_exp_value(head, buf, at + align.offsets[i], &align.fields[i], ctx)?;
                i += 1;
                cur = tail;
            }
            at + align.size
        }
        // EMPTY (an output placeholder) and anything else: the zeroed buffer is
        // the value.
        _ => at,
    })
}

fn get_i32(buf: &[u8], at: usize) -> Result<i32> {
    buf.get(at..at + 4)
        .map(|b| i32::from_le_bytes(b.try_into().expect("4 bytes")))
        .ok_or("FFI.callFunction: result buffer underrun")
}

fn get_f64(buf: &[u8], at: usize) -> Result<f64> {
    buf.get(at..at + 8)
        .map(|b| f64::from_le_bytes(b.try_into().expect("8 bytes")))
        .ok_or("FFI.callFunction: result buffer underrun")
}

fn mk_int_exp(buf: &[u8], at: usize) -> Result<metamodelica::Ref<Expression::NFExpression>> {
    Ok(metamodelica::Ref::new(Expression::NFExpression::INTEGER { value: get_i32(buf, at)? }))
}

fn mk_bool_exp(buf: &[u8], at: usize) -> Result<metamodelica::Ref<Expression::NFExpression>> {
    Ok(metamodelica::Ref::new(Expression::NFExpression::BOOLEAN { value: get_i32(buf, at)? != 0 }))
}

fn mk_real_exp(buf: &[u8], at: usize) -> Result<metamodelica::Ref<Expression::NFExpression>> {
    Ok(metamodelica::Ref::new(Expression::NFExpression::REAL {
        value: metamodelica::OrderedFloat(get_f64(buf, at)?),
    }))
}

fn mk_string_exp(buf: &[u8], at: usize, ctx: &Ctx) -> Result<metamodelica::Ref<Expression::NFExpression>> {
    let value = ctx.cstring(get_i32(buf, at)? as u32)?;
    Ok(metamodelica::Ref::new(Expression::NFExpression::STRING { value }))
}

fn mk_enum_exp(
    buf: &[u8],
    at: usize,
    enum_ty: &metamodelica::Ref<Type::NFType>,
) -> Result<metamodelica::Ref<Expression::NFExpression>> {
    let index = get_i32(buf, at)?;
    let Type::NFType::ENUMERATION { literals, .. } = &**enum_ty else {
        return Err("FFI.callFunction: expected an enumeration type");
    };
    let mut cur = literals;
    let mut i = 1;
    while let metamodelica::ListNode::Cons { head, tail } = &**cur {
        if i == index {
            return Ok(metamodelica::Ref::new(Expression::NFExpression::ENUM_LITERAL {
                ty: enum_ty.clone(),
                name: head.clone(),
                index,
            }));
        }
        i += 1;
        cur = tail;
    }
    return Err("FFI.callFunction: enumeration index out of range")
}

fn mk_array_exp(
    buf: &[u8],
    at: usize,
    ty: &metamodelica::Ref<Type::NFType>,
    ctx: &Ctx,
) -> Result<metamodelica::Ref<Expression::NFExpression>> {
    let Type::NFType::ARRAY { elementType, dimensions } = &**ty else {
        return Err("FFI.callFunction: expected an array type");
    };
    let dim_count = list_len(dimensions);
    let elem_count = array_scalar_count(ty);
    let elem_size = size_of_type(elementType);

    let elems: Vec<metamodelica::Ref<Expression::NFExpression>> = if dim_count <= 1 {
        let mut v = Vec::with_capacity(elem_count);
        for i in 0..elem_count {
            let p = at + i * elem_size;
            v.push(match &**elementType {
                Type::NFType::INTEGER => mk_int_exp(buf, p)?,
                Type::NFType::BOOLEAN => mk_bool_exp(buf, p)?,
                Type::NFType::REAL => mk_real_exp(buf, p)?,
                Type::NFType::STRING => mk_string_exp(buf, p, ctx)?,
                Type::NFType::ENUMERATION { .. } => mk_enum_exp(buf, p, elementType)?,
                _ => return Err("FFI.callFunction: unsupported array element type"),
            });
        }
        v
    } else {
        let arr_len = array_length(ty);
        let chunk_scalars = if arr_len == 0 { 0 } else { elem_count / arr_len };
        let chunk_bytes = elem_size * chunk_scalars;
        let elem_ty = unlift_array_type(ty);
        let mut v = Vec::with_capacity(arr_len);
        for i in 0..arr_len {
            v.push(mk_array_exp(buf, at + i * chunk_bytes, &elem_ty, ctx)?);
        }
        v
    };

    Ok(metamodelica::Ref::new(Expression::NFExpression::ARRAY {
        ty: ty.clone(),
        elements: metamodelica::arrayFromVec(elems),
        literal: true,
    }))
}

fn mk_record_exp(
    buf: &[u8],
    at: usize,
    arg: &Expression::NFExpression,
    align: &Alignment,
    ctx: &Ctx,
) -> Result<metamodelica::Ref<Expression::NFExpression>> {
    let Expression::NFExpression::RECORD { path, ty, elements } = arg else {
        return Err("FFI.callFunction: expected a record expression");
    };
    let mut out: Vec<metamodelica::Ref<Expression::NFExpression>> = Vec::with_capacity(align.fields.len());
    let mut cur = elements;
    let mut i = 0usize;
    while let metamodelica::ListNode::Cons { head, tail } = &**cur {
        if i >= align.fields.len() {
            break;
        }
        out.push(mk_exp_from_arg(head, buf, at + align.offsets[i], &align.fields[i], ctx)?);
        i += 1;
        cur = tail;
    }
    let mut list = metamodelica::nil();
    for e in out.into_iter().rev() {
        list = metamodelica::cons(e, list);
    }
    Ok(metamodelica::Ref::new(Expression::NFExpression::RECORD {
        path: path.clone(),
        ty: ty.clone(),
        elements: list,
    }))
}

fn mk_exp_from_type(
    ty: &metamodelica::Ref<Type::NFType>,
    buf: &[u8],
    at: usize,
    ctx: &Ctx,
) -> Result<metamodelica::Ref<Expression::NFExpression>> {
    Ok(match &**ty {
        Type::NFType::INTEGER => mk_int_exp(buf, at)?,
        Type::NFType::BOOLEAN => mk_bool_exp(buf, at)?,
        Type::NFType::REAL => mk_real_exp(buf, at)?,
        Type::NFType::STRING => mk_string_exp(buf, at, ctx)?,
        Type::NFType::ENUMERATION { .. } => mk_enum_exp(buf, at, ty)?,
        Type::NFType::ARRAY { .. } => mk_array_exp(buf, at, ty, ctx)?,
        _ => metamodelica::Ref::new(Expression::NFExpression::EMPTY { ty: ty.clone() }),
    })
}

fn mk_exp_from_arg(
    arg: &Expression::NFExpression,
    buf: &[u8],
    at: usize,
    align: &Alignment,
    ctx: &Ctx,
) -> Result<metamodelica::Ref<Expression::NFExpression>> {
    Ok(match arg {
        Expression::NFExpression::INTEGER { .. } => mk_int_exp(buf, at)?,
        Expression::NFExpression::BOOLEAN { .. } => mk_bool_exp(buf, at)?,
        Expression::NFExpression::REAL { .. } => mk_real_exp(buf, at)?,
        Expression::NFExpression::STRING { .. } => mk_string_exp(buf, at, ctx)?,
        Expression::NFExpression::ENUM_LITERAL { ty, .. } => mk_enum_exp(buf, at, ty)?,
        Expression::NFExpression::ARRAY { ty, .. } => mk_array_exp(buf, at, ty, ctx)?,
        Expression::NFExpression::RECORD { .. } => mk_record_exp(buf, at, arg, align, ctx)?,
        Expression::NFExpression::EMPTY { ty } => mk_exp_from_type(ty, buf, at, ctx)?,
        _ => return Err("FFI.callFunction: unsupported argument expression"),
    })
}

/// Port of `FFI::callFunction`: marshal the arguments into the library's memory,
/// call the export behind `fnHandle`, and convert the return value and the OUTPUT
/// arguments back, in declaration order.
pub fn callFunction(
    fnHandle: i32,
    args: metamodelica::Array<metamodelica::Ref<Expression::NFExpression>>,
    specs: metamodelica::Array<ArgSpec>,
    returnType: metamodelica::Ref<Type::NFType>,
) -> Result<(metamodelica::Ref<Expression::NFExpression>, metamodelica::List<metamodelica::Ref<Expression::NFExpression>>)> {
    let args_vec: Vec<metamodelica::Ref<Expression::NFExpression>> = args.borrow().clone();
    let specs_vec: Vec<ArgSpec> = specs.borrow().clone();
    if args_vec.len() != specs_vec.len() {
        return Err("FFI.callFunction: argument/spec count mismatch");
    }

    let mut ctx = Ctx { func: fnHandle, temps: Vec::new() };
    let result = call_marshalled(&mut ctx, &args_vec, &specs_vec, &returnType);
    ctx.release();
    result
}

fn call_marshalled(
    ctx: &mut Ctx,
    args: &[metamodelica::Ref<Expression::NFExpression>],
    specs: &[ArgSpec],
    returnType: &metamodelica::Ref<Type::NFType>,
) -> Result<(metamodelica::Ref<Expression::NFExpression>, metamodelica::List<metamodelica::Ref<Expression::NFExpression>>)> {
    let mut call_args: Vec<Val> = Vec::with_capacity(args.len());
    let mut aligns: Vec<Alignment> = Vec::with_capacity(args.len());
    // Where each by-pointer argument's buffer landed, for the read-back.
    let mut buffers: Vec<Option<(u32, usize)>> = Vec::with_capacity(args.len());

    for (arg, spec) in args.iter().zip(specs.iter()) {
        let (ctype, align) = exp_alignment(arg)?;
        let size = size_of_exp(arg, &align).max(1);
        let mut data = vec![0u8; size];
        write_exp_value(arg, &mut data, 0, &align, ctx)?;

        if *spec != ArgSpec::INPUT || is_exp_pointer_type(arg) {
            let off = ctx.alloc(size)?;
            ctx.write(off, &data)?;
            call_args.push(Val::I32(off as i32));
            buffers.push(Some((off, size)));
        } else {
            call_args.push(match ctype {
                CType::Double => Val::F64(get_f64(&data, 0)?),
                _ => Val::I32(get_i32(&data, 0)?),
            });
            buffers.push(None);
        }
        aligns.push(align);
    }

    let ret = ext_eval::call(ctx.func, &call_args).map_err(detail)?;

    let mut outputs: Vec<metamodelica::Ref<Expression::NFExpression>> = Vec::new();
    for (i, spec) in specs.iter().enumerate() {
        if *spec != ArgSpec::OUTPUT {
            continue;
        }
        let Some((off, size)) = buffers[i] else {
            return Err("FFI.callFunction: an output argument was not passed by pointer");
        };
        let buf = ctx.read(off, size)?;
        outputs.push(mk_exp_from_arg(&args[i], &buf, 0, &aligns[i], ctx)?);
    }
    let mut output_list = metamodelica::nil();
    for o in outputs.into_iter().rev() {
        output_list = metamodelica::cons(o, output_list);
    }

    // The return value arrives as a wasm value, or through a pointer into the side
    // module's memory for a `char*`/array return.
    let ret_ctype = type_ctype(returnType);
    let mut ret_buf = vec![0u8; size_of_type(returnType).max(8)];
    match (ret_ctype, ret) {
        (CType::Void, _) | (_, None) => (),
        (CType::Double, Some(Val::F64(v))) => ret_buf[..8].copy_from_slice(&v.to_le_bytes()),
        (CType::SInt, Some(Val::I32(v))) => ret_buf[..4].copy_from_slice(&v.to_le_bytes()),
        (CType::Pointer, Some(Val::I32(v))) => match &**returnType {
            // A `char*` return is the pointer itself; an array return points at the
            // values, which are read from there.
            Type::NFType::ARRAY { .. } => ret_buf = ctx.read(v as u32, ret_buf.len())?,
            _ => ret_buf[..4].copy_from_slice(&v.to_le_bytes()),
        },
        _ => return Err("FFI.callFunction: the external function returned the wrong kind of value"),
    }
    let return_value = mk_exp_from_type(returnType, &ret_buf, 0, ctx)?;

    Ok((return_value, output_list))
}
