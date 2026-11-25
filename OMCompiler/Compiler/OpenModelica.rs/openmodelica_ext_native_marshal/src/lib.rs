//! Marshalling for `external "C"` functions a wasm FMU reaches through the host
//! (`om:ext/native`): the function table, and the copy between the stub's frame
//! in wasm memory and the [`Value`]s that cross to the host. Shared by the two
//! sides that hold the memory: the FMI adapter in the component, and an omc
//! that linked the model itself.
//!
//! The frame is one 8-byte slot per C argument in declaration order, the return
//! value in the slot after them ([`result_slot`]). A String or array argument is
//! the runtime handle; an `_Out_` scalar or String is the address of a cell. A
//! FORTRAN 77 or `by_ref` C scalar goes through a cell both ways, Fortran arrays
//! column-major. A record is the address of its C struct (MLS 3.7, section
//! 12.9.1.3) in the wasm32 layout, an array of records that of the structs after
//! an 8-byte element count, and a struct returned by value comes back through
//! an `sret` address ahead of the arguments ([`ret_abi`]).
#![no_std]
extern crate alloc;

use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Scalar {
    Int,
    Real,
    Bool,
}

#[derive(Clone, PartialEq, Eq, Debug)]
pub enum Ty {
    Scalar(Scalar),
    Str,
    /// An external object.
    Ptr,
    Array(Scalar),
    /// A pointer to a record's C struct; the member types in declaration order,
    /// each a scalar, a String or a record.
    Record(Vec<Ty>),
    /// A pointer to an array of such structs.
    RecordArray(Vec<Ty>),
}

impl Ty {
    pub fn elem_size(s: Scalar) -> u32 {
        match s {
            Scalar::Real => 8,
            Scalar::Int | Scalar::Bool => 4,
        }
    }
}

#[derive(Clone, Debug)]
pub struct Arg {
    pub ty: Ty,
    pub out: bool,
    /// A C input scalar passed by pointer, as a protected variable is.
    pub by_ref: bool,
}

#[derive(Clone, Debug)]
pub struct Sig {
    pub name: String,
    pub fortran: bool,
    pub args: Vec<Arg>,
    pub ret: Option<Ty>,
}

/// `resources/native_externals.txt`: the libraries to load, then the functions.
#[derive(Clone, Debug, Default)]
pub struct Table {
    /// Shipped inside the FMU, opened from its `binaries/<platform>/`.
    pub libs: Vec<String>,
    /// Named but not shipped (FMI 3.0 `<Library external="true"/>`): a system
    /// library, opened by soname so the platform's loader finds it.
    pub system_libs: Vec<String>,
    pub fns: Vec<Sig>,
}

/// A value crossing to or from the host; `om:ext/native`'s `value`. A record is
/// `Bytes`: its struct in the wasm32 layout, a String member's pointer zero, then
/// each String member's `u32` length and bytes in member order. An array of
/// records is the `u32` element count, the structs, then the Strings likewise.
#[derive(Clone, Debug, PartialEq)]
pub enum Value {
    Int(i32),
    Real(f64),
    Str(String),
    Bytes(Vec<u8>),
    Handle(u32),
}

fn parse_ty(code: &str) -> Result<Ty, String> {
    match parse_one(code)? {
        (ty, "") => Ok(ty),
        _ => Err(format!("native externals: unsupported type code `{code}`")),
    }
}

/// One type code from the start of `s` and what follows it: `[`s before an element
/// type, `{path;name:code;…}` a record.
fn parse_one(s: &str) -> Result<(Ty, &str), String> {
    let bad = || format!("native externals: unsupported type code `{s}`");
    let rest = s.get(1..).unwrap_or("");
    Ok(match s.as_bytes().first() {
        Some(b'I') => (Ty::Scalar(Scalar::Int), rest),
        Some(b'R') => (Ty::Scalar(Scalar::Real), rest),
        Some(b'B') => (Ty::Scalar(Scalar::Bool), rest),
        Some(b'S') => (Ty::Str, rest),
        Some(b'P') => (Ty::Ptr, rest),
        Some(b'[') => match parse_one(rest)? {
            (Ty::Scalar(e) | Ty::Array(e), rest) => (Ty::Array(e), rest),
            (Ty::Record(m) | Ty::RecordArray(m), rest) => (Ty::RecordArray(m), rest),
            _ => return Err(bad()),
        },
        Some(b'{') => {
            let mut rest = &rest[rest.find([';', '}']).ok_or_else(bad)?..];
            let mut members = Vec::new();
            while let Some(r) = rest.strip_prefix(';') {
                let colon = r.find(':').ok_or_else(bad)?;
                let name = &r[..colon];
                let (ty, r) = parse_one(&r[colon + 1..])?;
                if !matches!(ty, Ty::Scalar(_) | Ty::Str | Ty::Record(_)) {
                    return Err(format!(
                        "native externals: record member `{name}` cannot be copied to C - only Real, \
                         Integer, Boolean, String and record members can"
                    ));
                }
                members.push(ty);
                rest = r;
            }
            (Ty::Record(members), rest.strip_prefix('}').ok_or_else(bad)?)
        }
        _ => return Err(bad()),
    })
}

/// The member offsets, size and alignment of a record's C struct where a pointer
/// is `ptr` bytes: each member at its natural alignment, the struct padded to the
/// widest.
pub fn layout(members: &[Ty], ptr: u32) -> (Vec<u32>, u32, u32) {
    let (mut off, mut align) = (0u32, 1u32);
    let mut offsets = Vec::with_capacity(members.len());
    for m in members {
        let (size, a) = match m {
            Ty::Scalar(Scalar::Real) => (8, 8),
            Ty::Scalar(_) => (4, 4),
            Ty::Record(inner) => {
                let (_, size, a) = layout(inner, ptr);
                (size, a)
            }
            _ => (ptr, ptr),
        };
        off = off.next_multiple_of(a);
        offsets.push(off);
        off += size;
        align = align.max(a);
    }
    (offsets, off.next_multiple_of(align), align)
}

/// How the wasm C ABI returns a struct: through an `sret` address ahead of the
/// arguments, or as the scalar of its single member.
#[derive(Clone, Debug, PartialEq)]
pub enum RetAbi {
    Sret,
    Scalar(Ty),
    Dropped,
}

pub fn ret_abi(members: &[Ty]) -> RetAbi {
    match members {
        [] => RetAbi::Dropped,
        [Ty::Record(inner)] => ret_abi(inner),
        [m] => RetAbi::Scalar(m.clone()),
        _ => RetAbi::Sret,
    }
}

/// Whether the frame's first slot is a returned struct's `sret` address.
fn has_sret(sig: &Sig) -> bool {
    matches!(&sig.ret, Some(Ty::Record(m)) if ret_abi(m) == RetAbi::Sret)
}

fn arg_slot(sig: &Sig, frame: u32, j: usize) -> u32 {
    frame + 8 * (j as u32 + u32::from(has_sret(sig)))
}

fn read_cstr(g: &dyn Guest, mut p: u32) -> Vec<u8> {
    let mut out = Vec::new();
    loop {
        let chunk = g.read(p, 64);
        match chunk.iter().position(|b| *b == 0) {
            Some(n) => {
                out.extend_from_slice(&chunk[..n]);
                return out;
            }
            None if chunk.is_empty() => return out,
            None => {
                out.extend_from_slice(&chunk);
                p += chunk.len() as u32;
            }
        }
    }
}

/// Append the String members of the struct `raw` (wasm32 layout) to `out`,
/// zeroing their pointers in `raw`.
fn gather_strings(g: &dyn Guest, members: &[Ty], raw: &mut [u8], out: &mut Vec<u8>) {
    let (offsets, _, _) = layout(members, 4);
    for (m, off) in members.iter().zip(offsets) {
        let off = off as usize;
        match m {
            Ty::Str => {
                let s = u32::from_le_bytes([raw[off], raw[off + 1], raw[off + 2], raw[off + 3]]);
                let bytes = if s == 0 { Vec::new() } else { read_cstr(g, s) };
                out.extend_from_slice(&(bytes.len() as u32).to_le_bytes());
                out.extend_from_slice(&bytes);
                raw[off..off + 4].fill(0);
            }
            Ty::Record(inner) => gather_strings(g, inner, &mut raw[off..], out),
            _ => {}
        }
    }
}

/// The wire form of `n` structs at `p` (see [`Value`]).
fn gather_records(g: &dyn Guest, members: &[Ty], p: u32, n: u32) -> Vec<u8> {
    let (_, size, _) = layout(members, 4);
    let mut raw = if p == 0 {
        alloc::vec![0u8; (n * size) as usize]
    } else {
        g.read(p, n * size)
    };
    let mut strings = Vec::new();
    for k in 0..n as usize {
        gather_strings(g, members, &mut raw[k * size as usize..], &mut strings);
    }
    raw.extend(strings);
    raw
}

/// Write the String members of a struct at `p` from `strings`: each into a
/// scratch C string, its address into the member.
fn scatter_strings(
    g: &mut dyn Guest,
    members: &[Ty],
    p: u32,
    strings: &mut &[u8],
    scratch: &mut Vec<u32>,
) -> Result<(), String> {
    let (offsets, _, _) = layout(members, 4);
    for (m, off) in members.iter().zip(offsets) {
        match m {
            Ty::Str => {
                let len = strings
                    .get(..4)
                    .map(|b| u32::from_le_bytes([b[0], b[1], b[2], b[3]]) as usize)
                    .ok_or("native externals: a record lacks a String member")?;
                let bytes = strings
                    .get(4..4 + len)
                    .ok_or("native externals: a record String is cut short")?;
                let s = g.alloc(len as u32 + 1);
                g.write(s, bytes);
                g.write(s + len as u32, &[0]);
                scratch.push(s);
                g.store_i32(p + off, s as i32);
                *strings = &strings[4 + len..];
            }
            Ty::Record(inner) => scatter_strings(g, inner, p + off, strings, scratch)?,
            _ => {}
        }
    }
    Ok(())
}

/// Write the wire form of `n` structs (see [`Value`]) to `p`.
fn scatter_records(
    g: &mut dyn Guest,
    members: &[Ty],
    p: u32,
    n: u32,
    bytes: &[u8],
    scratch: &mut Vec<u32>,
) -> Result<(), String> {
    let (_, size, _) = layout(members, 4);
    let raw = bytes
        .get(..(n * size) as usize)
        .ok_or("native externals: a record is cut short")?;
    g.write(p, raw);
    let mut strings = &bytes[raw.len()..];
    for k in 0..n {
        scatter_strings(g, members, p + k * size, &mut strings, scratch)?;
    }
    Ok(())
}

/// The element count ahead of an array of structs at `p`.
fn record_count(g: &dyn Guest, p: u32) -> u32 {
    if p == 0 { 0 } else { g.load_i32(p - 8) as u32 }
}

/// The table's text form (see [`Table`]):
///
/// ```text
/// lib libfoo.so
/// extlib libpython3.8.so
/// fn wa_split C - R *R *I
/// ```
///
/// An `extlib` line names a library the FMU does not ship, opened by soname.
/// A `fn` line is the name, the language (`C`/`F`), the return type or `-`, then
/// each argument, `*` marking an `_Out_` and `&` a `by_ref` input. Types are the
/// wasm-jit `SigTy` codes.
pub fn parse(text: &str) -> Result<Table, String> {
    let mut t = Table::default();
    for line in text
        .lines()
        .map(str::trim)
        .filter(|l| !l.is_empty() && !l.starts_with('#'))
    {
        let mut words = line.split_whitespace();
        match words.next() {
            Some("lib") => t.libs.push(words.collect::<Vec<_>>().join(" ")),
            Some("extlib") => t.system_libs.push(words.collect::<Vec<_>>().join(" ")),
            Some("fn") => {
                let name = words.next().ok_or("native externals: `fn` without a name")?.to_string();
                let fortran = words.next() == Some("F");
                let ret = match words.next() {
                    Some("-") | None => None,
                    Some(c) => Some(parse_ty(c)?),
                };
                let mut args = Vec::new();
                for w in words {
                    let (out, by_ref, code) = match (w.strip_prefix('*'), w.strip_prefix('&')) {
                        (Some(c), _) => (true, false, c),
                        (_, Some(c)) => (false, true, c),
                        _ => (false, false, w),
                    };
                    args.push(Arg {
                        ty: parse_ty(code)?,
                        out,
                        by_ref,
                    });
                }
                t.fns.push(Sig {
                    name,
                    fortran,
                    args,
                    ret,
                });
            }
            Some(other) => return Err(format!("native externals: unknown line `{other}`")),
            None => {}
        }
    }
    Ok(t)
}

/// The frame slot the C return value is read from: after the arguments.
pub fn result_slot(sig: &Sig) -> u32 {
    8 * (sig.args.len() as u32 + u32::from(has_sret(sig)))
}

/// The wasm side of the frame: the memory and the runtime primitives the
/// handles in it are read and written with.
pub trait Guest {
    fn load_i32(&self, addr: u32) -> i32;
    fn load_f64(&self, addr: u32) -> f64;
    fn store_i32(&mut self, addr: u32, v: i32);
    fn store_f64(&mut self, addr: u32, v: f64);
    fn read(&self, addr: u32, len: u32) -> Vec<u8>;
    fn write(&mut self, addr: u32, bytes: &[u8]);
    fn str_len(&self, handle: u32) -> u32;
    fn str_data(&self, handle: u32) -> u32;
    fn array_total(&self, handle: u32) -> u32;
    fn array_data(&self, handle: u32) -> u32;
    fn array_dims(&self, handle: u32) -> Vec<u32>;
    fn alloc(&mut self, len: u32) -> u32;
    fn free(&mut self, addr: u32);
}

/// Whether the callee writes this argument through a scalar cell the caller
/// allocates, and so is neither an input value nor a wasm result. An array or
/// record crosses as a pointer, which *is* the value.
pub fn is_cell(sig: &Sig, a: &Arg) -> bool {
    a.out && !matches!(a.ty, Ty::Array(_) | Ty::Record(_) | Ty::RecordArray(_)) && !is_ref(sig, a)
}

/// A FORTRAN 77 or `by_ref` C scalar: by reference, in and out.
pub fn is_ref(sig: &Sig, a: &Arg) -> bool {
    (sig.fortran || a.by_ref) && matches!(a.ty, Ty::Scalar(_))
}

/// Row-major <-> column-major, the runtime's `f77_reorder`.
pub fn reorder(src: &[u8], dims: &[u32], esz: usize, to_f77: bool) -> Vec<u8> {
    let total = src.len() / esz.max(1);
    if dims.len() < 2 || total == 0 {
        return src.to_vec();
    }
    let mut dst = alloc::vec![0u8; src.len()];
    for i in 0..total {
        let mut rest = i;
        let mut col = 0usize;
        let mut sub = Vec::with_capacity(dims.len());
        for d in dims.iter().rev() {
            let d = (*d as usize).max(1);
            sub.push(rest % d);
            rest /= d;
        }
        for (d, s) in dims.iter().rev().zip(&sub) {
            col = col * (*d as usize).max(1) + s;
        }
        let (from, to) = if to_f77 { (i, col) } else { (col, i) };
        dst[to * esz..(to + 1) * esz].copy_from_slice(&src[from * esz..(from + 1) * esz]);
    }
    dst
}

fn read_array(g: &dyn Guest, h: u32, elem: Scalar, fortran: bool) -> Vec<u8> {
    if h == 0 {
        return Vec::new();
    }
    let esz = Ty::elem_size(elem);
    let bytes = g.read(g.array_data(h), g.array_total(h) * esz);
    if fortran {
        reorder(&bytes, &g.array_dims(h), esz as usize, true)
    } else {
        bytes
    }
}

/// The host's argument list, read out of the frame.
pub fn gather(sig: &Sig, frame: u32, g: &dyn Guest) -> Result<Vec<Value>, String> {
    let mut out = Vec::with_capacity(sig.args.len());
    for (j, a) in sig.args.iter().enumerate() {
        if is_cell(sig, a) {
            continue;
        }
        let slot = arg_slot(sig, frame, j);
        // Fortran: the slot holds the cell's address.
        let at = if is_ref(sig, a) { g.load_i32(slot) as u32 } else { slot };
        out.push(match &a.ty {
            Ty::Scalar(Scalar::Real) => Value::Real(g.load_f64(at)),
            Ty::Scalar(_) => Value::Int(g.load_i32(at)),
            Ty::Ptr => Value::Handle(g.load_i32(slot) as u32),
            Ty::Str => {
                let h = g.load_i32(slot) as u32;
                let bytes = if h == 0 {
                    Vec::new()
                } else {
                    g.read(g.str_data(h), g.str_len(h))
                };
                Value::Str(String::from_utf8_lossy(&bytes).into_owned())
            }
            Ty::Array(elem) => Value::Bytes(read_array(g, g.load_i32(slot) as u32, *elem, sig.fortran)),
            // The slot holds the address of the kernel's scratch struct.
            Ty::Record(members) => Value::Bytes(gather_records(g, members, g.load_i32(slot) as u32, 1)),
            Ty::RecordArray(members) => {
                let p = g.load_i32(slot) as u32;
                let n = record_count(g, p);
                let mut bytes = n.to_le_bytes().to_vec();
                bytes.extend(gather_records(g, members, p, n));
                Value::Bytes(bytes)
            }
        });
    }
    Ok(out)
}

/// Put the host's results where the kernel reads them: return value, `_Out_`
/// and Fortran cells, `_Out_` array elements. A `char*` the kernel copies out of
/// is allocated here and listed in `scratch` for the caller to free at the next call.
pub fn scatter(
    sig: &Sig,
    frame: u32,
    results: &[Value],
    g: &mut dyn Guest,
    scratch: &mut Vec<u32>,
) -> Result<(), String> {
    let mut results = results.iter();
    let mut next = |what: &str| {
        results
            .next()
            .ok_or_else(|| format!("native externals: `{}` returned no {what}", sig.name))
    };
    let cstr = |g: &mut dyn Guest, s: &str, scratch: &mut Vec<u32>| -> u32 {
        let p = g.alloc(s.len() as u32 + 1);
        g.write(p, s.as_bytes());
        g.write(p + s.len() as u32, &[0]);
        scratch.push(p);
        p
    };
    let store = |g: &mut dyn Guest, at: u32, ty: &Ty, v: &Value, scratch: &mut Vec<u32>| -> Result<(), String> {
        match (ty, v) {
            (Ty::Scalar(Scalar::Real), Value::Real(x)) => g.store_f64(at, *x),
            (Ty::Scalar(_), Value::Int(x)) => g.store_i32(at, *x),
            (Ty::Ptr, Value::Handle(h)) => g.store_i32(at, *h as i32),
            (Ty::Str, Value::Str(s)) => {
                let p = cstr(g, s, scratch);
                g.store_i32(at, p as i32);
            }
            _ => {
                return Err(format!(
                    "native externals: `{}` returned a value of the wrong type",
                    sig.name
                ));
            }
        }
        Ok(())
    };
    match &sig.ret {
        Some(Ty::Record(members)) => {
            let Value::Bytes(bytes) = next("return value")? else {
                return Err(format!("native externals: `{}` returned a non-record", sig.name));
            };
            match ret_abi(members) {
                RetAbi::Sret => {
                    let p = g.load_i32(frame) as u32;
                    scatter_records(g, members, p, 1, bytes, scratch)?;
                }
                // The single member at offset 0, through a scratch struct for a String.
                RetAbi::Scalar(leaf) => {
                    let (_, size, _) = layout(members, 4);
                    let p = g.alloc(size.max(8));
                    scratch.push(p);
                    scatter_records(g, members, p, 1, bytes, scratch)?;
                    let at = frame + result_slot(sig);
                    match leaf {
                        Ty::Scalar(Scalar::Real) => g.store_f64(at, g.load_f64(p)),
                        _ => g.store_i32(at, g.load_i32(p)),
                    }
                }
                RetAbi::Dropped => {}
            }
        }
        Some(ret) => {
            let v = next("return value")?;
            store(g, frame + result_slot(sig), ret, v, scratch)?;
        }
        None => {}
    }
    for (j, a) in sig.args.iter().enumerate() {
        if is_cell(sig, a) || is_ref(sig, a) {
            let cell = g.load_i32(arg_slot(sig, frame, j)) as u32;
            let v = next("output")?;
            store(g, cell, &a.ty, v, scratch)?;
        }
    }
    // In argument order: that is the order the host returns them in.
    for (j, a) in sig.args.iter().enumerate() {
        if !a.out {
            continue;
        }
        let slot = arg_slot(sig, frame, j);
        let (what, len, at) = match &a.ty {
            Ty::Array(elem) => {
                let h = g.load_i32(slot) as u32;
                ("array", g.array_total(h) * Ty::elem_size(*elem), g.array_data(h))
            }
            Ty::Record(members) | Ty::RecordArray(members) => {
                let p = g.load_i32(slot) as u32;
                let n = match &a.ty {
                    Ty::RecordArray(_) => record_count(g, p),
                    _ => 1,
                };
                let Value::Bytes(bytes) = next("output record")? else {
                    return Err(format!(
                        "native externals: `{}` returned a non-record for an output record",
                        sig.name
                    ));
                };
                let body = match &a.ty {
                    Ty::RecordArray(_) => bytes.get(4..).unwrap_or(&[]),
                    _ => &bytes[..],
                };
                if p != 0 {
                    scatter_records(g, members, p, n, body, scratch)?;
                }
                continue;
            }
            _ => continue,
        };
        let Value::Bytes(bytes) = next(&format!("output {what}"))? else {
            return Err(format!(
                "native externals: `{}` returned a non-{what} for an output {what}",
                sig.name
            ));
        };
        if bytes.len() as u32 != len {
            return Err(format!(
                "native externals: `{}` returned {} bytes for an output {what} of {len}",
                sig.name,
                bytes.len()
            ));
        }
        match &a.ty {
            Ty::Array(elem) if sig.fortran => {
                let h = g.load_i32(slot) as u32;
                g.write(
                    at,
                    &reorder(bytes, &g.array_dims(h), Ty::elem_size(*elem) as usize, false),
                );
            }
            _ => g.write(at, bytes),
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use alloc::collections::BTreeMap;
    use alloc::vec;

    /// A memory with the runtime's String (`[rc][len][bytes]`) and array
    /// (`[rc][kind][ndims][total][dims…]` then 8-aligned elements) layouts.
    #[derive(Default)]
    struct Mem {
        bytes: BTreeMap<u32, u8>,
        next: u32,
    }
    impl Mem {
        fn put(&mut self, at: u32, b: &[u8]) {
            for (i, x) in b.iter().enumerate() {
                self.bytes.insert(at + i as u32, *x);
            }
        }
        fn string(&mut self, s: &str) -> u32 {
            let h = self.alloc(8 + s.len() as u32 + 1);
            self.put(h + 4, &(s.len() as u32).to_le_bytes());
            self.put(h + 8, s.as_bytes());
            h
        }
        fn reals(&mut self, v: &[f64]) -> u32 {
            self.reals_nd(v, &[v.len() as u32])
        }
        fn reals_nd(&mut self, v: &[f64], dims: &[u32]) -> u32 {
            let data = (16 + 4 * dims.len() as u32 + 7) & !7;
            let h = self.alloc(data + 8 * v.len() as u32);
            self.put(h + 8, &(dims.len() as u32).to_le_bytes());
            self.put(h + 12, &(v.len() as u32).to_le_bytes());
            for (k, d) in dims.iter().enumerate() {
                self.put(h + 16 + 4 * k as u32, &d.to_le_bytes());
            }
            for (i, x) in v.iter().enumerate() {
                self.put(h + data + 8 * i as u32, &x.to_le_bytes());
            }
            h
        }
    }
    impl Guest for Mem {
        fn load_i32(&self, a: u32) -> i32 {
            i32::from_le_bytes(self.read(a, 4).try_into().unwrap())
        }
        fn load_f64(&self, a: u32) -> f64 {
            f64::from_le_bytes(self.read(a, 8).try_into().unwrap())
        }
        fn store_i32(&mut self, a: u32, v: i32) {
            self.put(a, &v.to_le_bytes())
        }
        fn store_f64(&mut self, a: u32, v: f64) {
            self.put(a, &v.to_le_bytes())
        }
        fn read(&self, a: u32, len: u32) -> Vec<u8> {
            (a..a + len).map(|k| *self.bytes.get(&k).unwrap_or(&0)).collect()
        }
        fn write(&mut self, a: u32, b: &[u8]) {
            self.put(a, b)
        }
        fn str_len(&self, h: u32) -> u32 {
            self.load_i32(h + 4) as u32
        }
        fn str_data(&self, h: u32) -> u32 {
            h + 8
        }
        fn array_total(&self, h: u32) -> u32 {
            self.load_i32(h + 12) as u32
        }
        fn array_data(&self, h: u32) -> u32 {
            h + ((16 + 4 * self.load_i32(h + 8) as u32 + 7) & !7)
        }
        fn array_dims(&self, h: u32) -> Vec<u32> {
            (0..self.load_i32(h + 8) as u32)
                .map(|k| self.load_i32(h + 16 + 4 * k) as u32)
                .collect()
        }
        fn alloc(&mut self, len: u32) -> u32 {
            let p = self.next + 1024;
            self.next = p + ((len + 7) & !7);
            p
        }
        fn free(&mut self, _a: u32) {}
    }

    /// `struct R f(const struct R *a, struct R *b, const struct Inner *c)` with
    /// `struct R {double x; const char *s; struct Inner {int i;} in1;}`.
    #[test]
    fn records_and_struct_return() {
        let r = "{P.R;x:R;s:S;in1:{P.Inner;i:I}}";
        let sig = parse(&format!("fn f C {r} {r} *{r} [{{P.Inner;i:I}}"))
            .unwrap()
            .fns
            .remove(0);
        assert_eq!(
            ret_abi(match &sig.ret {
                Some(Ty::Record(m)) => m,
                _ => panic!(),
            }),
            RetAbi::Sret
        );
        let mut m = Mem::default();
        let hi = m.alloc(8);
        m.put(hi, b"hi\0");
        let a = m.alloc(16);
        m.store_f64(a, 1.5);
        m.store_i32(a + 8, hi as i32);
        m.store_i32(a + 12, 7);
        let b = m.alloc(16);
        let sret = m.alloc(16);
        let c = m.alloc(16) + 8;
        m.put(c - 8, &2u64.to_le_bytes());
        m.store_i32(c, 3);
        m.store_i32(c + 4, 4);
        let frame = m.alloc(8 * 5);
        m.store_i32(frame, sret as i32);
        m.store_i32(frame + 8, a as i32);
        m.store_i32(frame + 16, b as i32);
        m.store_i32(frame + 24, c as i32);
        let wire = |x: f64, i: i32, s: &str| -> Vec<u8> {
            let mut v = x.to_le_bytes().to_vec();
            v.extend([0, 0, 0, 0]);
            v.extend(i.to_le_bytes());
            v.extend((s.len() as u32).to_le_bytes());
            v.extend(s.as_bytes());
            v
        };
        let args = gather(&sig, frame, &m).unwrap();
        assert_eq!(
            args,
            vec![
                Value::Bytes(wire(1.5, 7, "hi")),
                Value::Bytes(wire(0.0, 0, "")),
                Value::Bytes([2u32, 3, 4].iter().flat_map(|x| x.to_le_bytes()).collect()),
            ]
        );
        let mut scratch = Vec::new();
        let results = [Value::Bytes(wire(2.5, 9, "ret")), Value::Bytes(wire(3.5, 10, "out"))];
        scatter(&sig, frame, &results, &mut m, &mut scratch).unwrap();
        assert_eq!((m.load_f64(sret), m.load_i32(sret + 12)), (2.5, 9));
        assert_eq!(m.read(m.load_i32(sret + 8) as u32, 4), b"ret\0");
        assert_eq!((m.load_f64(b), m.load_i32(b + 12)), (3.5, 10));
        assert_eq!(m.read(m.load_i32(b + 8) as u32, 4), b"out\0");
    }

    #[test]
    fn table_round_trip() {
        let t = parse("# libs\nlib libfoo.so\nextlib libpython3.8.so\nfn wa_split C - R *R *I\nfn greet C S S I [R\n")
            .unwrap();
        assert_eq!(t.system_libs, ["libpython3.8.so"]);
        assert_eq!(t.libs, vec!["libfoo.so".to_string()]);
        assert_eq!(t.fns.len(), 2);
        let f = &t.fns[0];
        assert_eq!(f.name, "wa_split");
        assert!(f.ret.is_none());
        assert_eq!(f.args.len(), 3);
        assert!(f.args[1].out && f.args[1].ty == Ty::Scalar(Scalar::Real));
        assert!(f.args[2].out && f.args[2].ty == Ty::Scalar(Scalar::Int));
        let g = &t.fns[1];
        assert_eq!(g.ret, Some(Ty::Str));
        assert_eq!(g.args[2].ty, Ty::Array(Scalar::Real));
        assert!(parse("fn x C - Q").is_err());
    }

    /// `void f(const char* s, double* ip, int* sign, double* arr)` with `arr` an
    /// output array: the frame carries the String handle, two cells and the
    /// array handle; the results land in the cells and the elements.
    #[test]
    fn frame_gather_and_scatter() {
        let sig = parse("fn f C S S *R *I *[R").unwrap().fns.remove(0);
        let mut m = Mem::default();
        let s = m.string("hi");
        let arr = m.reals(&[1.0, 2.0]);
        let cell_r = m.alloc(8);
        let cell_i = m.alloc(8);
        let frame = m.alloc(8 * 5);
        m.store_i32(frame, s as i32);
        m.store_i32(frame + 8, cell_r as i32);
        m.store_i32(frame + 16, cell_i as i32);
        m.store_i32(frame + 24, arr as i32);
        let args = gather(&sig, frame, &m).unwrap();
        assert_eq!(
            args,
            vec![
                Value::Str("hi".into()),
                Value::Bytes([1.0f64, 2.0].iter().flat_map(|x| x.to_le_bytes()).collect())
            ]
        );
        let mut scratch = Vec::new();
        let results = [
            Value::Str("out".into()),
            Value::Real(3.5),
            Value::Int(-1),
            Value::Bytes([7.0f64, 8.0].iter().flat_map(|x| x.to_le_bytes()).collect()),
        ];
        scatter(&sig, frame, &results, &mut m, &mut scratch).unwrap();
        assert_eq!(m.load_f64(cell_r), 3.5);
        assert_eq!(m.load_i32(cell_i), -1);
        assert_eq!(m.load_f64(m.array_data(arr) + 8), 8.0);
        let ret = m.load_i32(frame + result_slot(&sig)) as u32;
        assert_eq!(m.read(ret, 4), b"out\0");
        assert_eq!(scratch, vec![ret]);
        assert!(scatter(&sig, frame, &results[..2], &mut m, &mut scratch).is_err());
    }

    /// `void f(double *y, int *n)` with `n` protected: its value goes in a cell.
    #[test]
    fn by_ref_c_scalar() {
        let sig = parse("fn f C - *[R &I").unwrap().fns.remove(0);
        assert!(!sig.fortran && sig.args[1].by_ref);
        assert!(is_ref(&sig, &sig.args[1]) && !is_cell(&sig, &sig.args[1]));
        let mut m = Mem::default();
        let n = m.alloc(8);
        m.store_i32(n, 3);
        let frame = m.alloc(8 * 3);
        m.store_i32(frame + 8, n as i32);
        let y = m.reals_nd(&[0.0, 0.0, 0.0], &[3]);
        m.store_i32(frame, y as i32);
        assert_eq!(gather(&sig, frame, &m).unwrap()[1], Value::Int(3));
    }

    /// `SUBROUTINE F(N, A, INFO)`, `A` a 2x3 matrix the callee overwrites.
    #[test]
    fn fortran_cells_and_column_major() {
        let sig = parse("fn f_ F - I *[R *I").unwrap().fns.remove(0);
        assert!(sig.fortran);
        assert!(is_ref(&sig, &sig.args[0]) && is_ref(&sig, &sig.args[2]) && !is_cell(&sig, &sig.args[2]));
        let mut m = Mem::default();
        let a = m.reals_nd(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0], &[2, 3]);
        let n = m.alloc(8);
        m.store_i32(n, 3);
        let info = m.alloc(8);
        let frame = m.alloc(8 * 4);
        m.store_i32(frame, n as i32);
        m.store_i32(frame + 8, a as i32);
        m.store_i32(frame + 16, info as i32);
        let args = gather(&sig, frame, &m).unwrap();
        let col: Vec<u8> = [1.0f64, 4.0, 2.0, 5.0, 3.0, 6.0]
            .iter()
            .flat_map(|x| x.to_le_bytes())
            .collect();
        assert_eq!(args, vec![Value::Int(3), Value::Bytes(col.clone()), Value::Int(0)]);
        let mut scratch = Vec::new();
        let back: Vec<u8> = [10.0f64, 40.0, 20.0, 50.0, 30.0, 60.0]
            .iter()
            .flat_map(|x| x.to_le_bytes())
            .collect();
        scatter(
            &sig,
            frame,
            &[Value::Int(3), Value::Int(7), Value::Bytes(back)],
            &mut m,
            &mut scratch,
        )
        .unwrap();
        assert_eq!(m.load_i32(info), 7);
        let d = m.array_data(a);
        assert_eq!(
            (0..6).map(|k| m.load_f64(d + 8 * k)).collect::<Vec<_>>(),
            [10.0, 20.0, 30.0, 40.0, 50.0, 60.0]
        );
        assert!(scratch.is_empty());
    }
}
