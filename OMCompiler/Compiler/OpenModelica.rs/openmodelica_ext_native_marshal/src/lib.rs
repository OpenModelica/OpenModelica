//! Marshalling for `external "C"` functions a wasm FMU reaches through the host
//! (`om:ext/native`): the function table, and the copy between the stub's frame
//! in wasm memory and the [`Value`]s that cross to the host. Shared by the two
//! sides that hold the memory: the FMI adapter in the component, and an omc
//! that linked the model itself.
//!
//! The frame is one 8-byte slot per C argument in declaration order, the return
//! value in the slot after them ([`result_slot`]). A String or array argument is
//! the runtime handle; an `_Out_` scalar or String is the address of a cell.
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

/// A value crossing to or from the host; `om:ext/native`'s `value`.
#[derive(Clone, Debug, PartialEq)]
pub enum Value {
    Int(i32),
    Real(f64),
    Str(String),
    Bytes(Vec<u8>),
    Handle(u32),
}

fn parse_ty(code: &str) -> Result<Ty, String> {
    let scalar = |c: &str| match c {
        "I" => Ok(Scalar::Int),
        "R" => Ok(Scalar::Real),
        "B" => Ok(Scalar::Bool),
        _ => Err(format!("native externals: unsupported type code `{code}`")),
    };
    match code {
        "S" => Ok(Ty::Str),
        "P" => Ok(Ty::Ptr),
        c if c.starts_with('[') => Ok(Ty::Array(scalar(c.trim_start_matches('['))?)),
        c => Ok(Ty::Scalar(scalar(c)?)),
    }
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
/// each argument, `*` marking an `_Out_`. Types are the wasm-jit `SigTy` codes.
pub fn parse(text: &str) -> Result<Table, String> {
    let mut t = Table::default();
    for line in text.lines().map(str::trim).filter(|l| !l.is_empty() && !l.starts_with('#')) {
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
                    let (out, code) = match w.strip_prefix('*') {
                        Some(c) => (true, c),
                        None => (false, w),
                    };
                    args.push(Arg { ty: parse_ty(code)?, out });
                }
                t.fns.push(Sig { name, fortran, args, ret });
            }
            Some(other) => return Err(format!("native externals: unknown line `{other}`")),
            None => {}
        }
    }
    Ok(t)
}

/// The frame slot the C return value is read from: after the arguments.
pub fn result_slot(sig: &Sig) -> u32 {
    8 * sig.args.len() as u32
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
    fn alloc(&mut self, len: u32) -> u32;
    fn free(&mut self, addr: u32);
}

/// Whether the argument is passed as a cell the callee writes, and so is neither
/// an input value nor a wasm result.
fn is_cell(a: &Arg) -> bool {
    a.out && !matches!(a.ty, Ty::Array(_))
}

/// The host's argument list, read out of the frame.
pub fn gather(sig: &Sig, frame: u32, g: &dyn Guest) -> Result<Vec<Value>, String> {
    if sig.fortran {
        return Err(format!("native externals: `{}` is FORTRAN 77, which is not served natively", sig.name));
    }
    let mut out = Vec::with_capacity(sig.args.len());
    for (j, a) in sig.args.iter().enumerate() {
        if is_cell(a) {
            continue;
        }
        let slot = frame + 8 * j as u32;
        out.push(match &a.ty {
            Ty::Scalar(Scalar::Real) => Value::Real(g.load_f64(slot)),
            Ty::Scalar(_) => Value::Int(g.load_i32(slot)),
            Ty::Ptr => Value::Handle(g.load_i32(slot) as u32),
            Ty::Str => {
                let h = g.load_i32(slot) as u32;
                let bytes = if h == 0 { Vec::new() } else { g.read(g.str_data(h), g.str_len(h)) };
                Value::Str(String::from_utf8_lossy(&bytes).into_owned())
            }
            Ty::Array(elem) => {
                let h = g.load_i32(slot) as u32;
                let bytes = if h == 0 { Vec::new() } else { g.read(g.array_data(h), g.array_total(h) * Ty::elem_size(*elem)) };
                Value::Bytes(bytes)
            }
        });
    }
    Ok(out)
}

/// Put the host's results where the kernel reads them: return value, `_Out_`
/// cells, `_Out_` array elements. A `char*` the kernel copies out of is
/// allocated here and listed in `scratch` for the caller to free at the next call.
pub fn scatter(sig: &Sig, frame: u32, results: &[Value], g: &mut dyn Guest, scratch: &mut Vec<u32>) -> Result<(), String> {
    let mut results = results.iter();
    let mut next = |what: &str| results.next().ok_or_else(|| format!("native externals: `{}` returned no {what}", sig.name));
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
            _ => return Err(format!("native externals: `{}` returned a value of the wrong type", sig.name)),
        }
        Ok(())
    };
    if let Some(ret) = &sig.ret {
        let v = next("return value")?;
        store(g, frame + result_slot(sig), ret, v, scratch)?;
    }
    for (j, a) in sig.args.iter().enumerate() {
        if is_cell(a) {
            let cell = g.load_i32(frame + 8 * j as u32) as u32;
            let v = next("output")?;
            store(g, cell, &a.ty, v, scratch)?;
        }
    }
    for (j, a) in sig.args.iter().enumerate() {
        let Ty::Array(elem) = &a.ty else { continue };
        if !a.out {
            continue;
        }
        let Value::Bytes(bytes) = next("output array")? else {
            return Err(format!("native externals: `{}` returned a non-array for an output array", sig.name));
        };
        let h = g.load_i32(frame + 8 * j as u32) as u32;
        let len = g.array_total(h) * Ty::elem_size(*elem);
        if bytes.len() as u32 != len {
            return Err(format!("native externals: `{}` returned {} bytes for an output array of {len}", sig.name, bytes.len()));
        }
        g.write(g.array_data(h), bytes);
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
            let h = self.alloc(24 + 8 * v.len() as u32);
            self.put(h + 8, &1u32.to_le_bytes());
            self.put(h + 12, &(v.len() as u32).to_le_bytes());
            self.put(h + 16, &(v.len() as u32).to_le_bytes());
            for (i, x) in v.iter().enumerate() {
                self.put(h + 24 + 8 * i as u32, &x.to_le_bytes());
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
        fn alloc(&mut self, len: u32) -> u32 {
            let p = self.next + 1024;
            self.next = p + ((len + 7) & !7);
            p
        }
        fn free(&mut self, _a: u32) {}
    }

    #[test]
    fn table_round_trip() {
        let t = parse("# libs\nlib libfoo.so\nextlib libpython3.8.so\nfn wa_split C - R *R *I\nfn greet C S S I [R\n").unwrap();
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
        assert_eq!(args, vec![Value::Str("hi".into()), Value::Bytes([1.0f64, 2.0].iter().flat_map(|x| x.to_le_bytes()).collect())]);
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
}
