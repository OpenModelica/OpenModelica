//! The host side of `om:ext/native`: the FMU's platform libraries, `dlopen`ed
//! from its resources, called through libffi with the arguments the marshalling
//! crate copied over.
//!
//! What the export writes and this reads: `resources/native_externals.txt`
//! (see [`marshal::parse`]) and the libraries it names, beside the loader in
//! `binaries/<platform>/`.
#![cfg_attr(feature = "utilities", feature(c_variadic))]

use std::path::Path;

pub use openmodelica_ext_native_marshal as marshal;
use marshal::{Scalar, Sig, Table, Ty, Value};

#[cfg(all(feature = "utilities", unix))]
pub mod utilities;

#[cfg(unix)]
use std::ffi::{c_void, CStr, CString};

/// FMI 3.0's tuple for this machine: the `resources/ext/<platform>/` the
/// libraries are shipped under.
pub fn host_platform() -> Option<&'static str> {
    Some(match (std::env::consts::ARCH, std::env::consts::OS) {
        ("x86_64", "linux") => "x86_64-linux",
        ("aarch64", "linux") => "aarch64-linux",
        ("x86_64", "windows") => "x86_64-windows",
        ("aarch64", "windows") => "aarch64-windows",
        ("x86_64", "macos") => "x86_64-darwin",
        ("aarch64", "macos") => "aarch64-darwin",
        _ => return None,
    })
}

/// FMI 2.0's name for the same platform directory (`linux64`, `win64`, …).
pub fn host_platform_fmi2() -> Option<&'static str> {
    Some(match host_platform()? {
        "x86_64-linux" => "linux64",
        "x86_64-windows" => "win64",
        "x86_64-darwin" => "darwin64",
        other => other,
    })
}

/// The table file under an FMU's `resources/`.
pub const TABLE_FILE: &str = "native_externals.txt";

/// The FMU's `binaries/<platform>/` for this machine, where the libraries are
/// beside the loader and the `.cwasm` (FMI: everything a platform's binary needs
/// is unpacked at its location). `fmu` is the unpacked FMU's root.
pub fn binaries_dir(fmu: &Path) -> Option<std::path::PathBuf> {
    [host_platform()?, host_platform_fmi2()?]
        .iter()
        .map(|p| fmu.join("binaries").join(p))
        .find(|d| d.is_dir())
}

/// The shared library this code is linked into: for the FMU loader,
/// `binaries/<platform>/<modelIdentifier>.<ext>`, whose stem names the model's
/// files beside it.
#[cfg(unix)]
pub fn this_library_path() -> Option<std::path::PathBuf> {
    let mut info: libc::Dl_info = unsafe { std::mem::zeroed() };
    if unsafe { libc::dladdr(this_library_path as *const std::ffi::c_void, &mut info) } == 0 || info.dli_fname.is_null() {
        return None;
    }
    let path = unsafe { CStr::from_ptr(info.dli_fname) }.to_string_lossy().into_owned();
    Some(std::path::PathBuf::from(path))
}

#[cfg(not(unix))]
pub fn this_library_path() -> Option<std::path::PathBuf> {
    None
}

/// The directory of the shared library this code is linked into: for the FMU
/// loader, the platform folder it was unpacked to.
pub fn this_library_dir() -> Option<std::path::PathBuf> {
    this_library_path()?.parent().map(Path::to_path_buf)
}

#[cfg(not(unix))]
pub struct Natives;

#[cfg(not(unix))]
impl Natives {
    pub fn open(_table: &Table, _lib_dir: &Path) -> Result<Natives, String> {
        Err("this FMU's `external \"C\"` platform libraries can only be loaded on a Unix host".to_string())
    }
    pub fn call(&mut self, _index: u32, _args: &[Value]) -> Result<Vec<Value>, String> {
        Err("native externals are not served on this host".to_string())
    }
}

#[cfg(unix)]
pub use unix::Natives;

#[cfg(unix)]
mod unix {
use super::*;

/// One 8-aligned native cell: a scalar, a pointer, or a `char*` written by the callee.
struct Cell(u64);

struct Resolved {
    sig: Sig,
    addr: usize,
    cif: libffi::middle::Cif,
    ret_bytes: usize,
}

pub struct Natives {
    fns: Vec<Resolved>,
    /// External-object pointers, by the handle the model holds; 0 is null.
    registry: Vec<usize>,
}

unsafe impl Send for Natives {}

fn dl_error() -> String {
    let e = unsafe { libc::dlerror() };
    if e.is_null() { "unknown dlopen error".to_string() } else { unsafe { CStr::from_ptr(e) }.to_string_lossy().into_owned() }
}

fn ffi_ty(ty: &Ty, out: bool) -> libffi::middle::Type {
    use libffi::middle::Type;
    if out {
        return Type::pointer();
    }
    match ty {
        Ty::Scalar(Scalar::Real) => Type::f64(),
        // Every integer argument fills a 64-bit slot, correct for `int` and `long` alike.
        Ty::Scalar(_) => Type::i64(),
        Ty::Str | Ty::Ptr | Ty::Array(_) | Ty::Record(_) => Type::pointer(),
    }
}

impl Natives {
    /// Load the libraries `table` names from `lib_dir` and resolve its functions.
    pub fn open(table: &Table, lib_dir: &Path) -> Result<Natives, String> {
        #[cfg(feature = "utilities")]
        utilities::publish();
        let mut handles: Vec<*mut c_void> = Vec::new();
        // A library may need one loaded after it; keep trying until a pass loads none.
        // A shipped library is opened from the FMU, a system one (`extlib`) by the
        // soname alone, so the platform's loader searches its own path for it.
        let mut pending: Vec<(String, bool)> = table
            .libs
            .iter()
            .map(|l| (lib_dir.join(l).to_string_lossy().into_owned(), false))
            .chain(table.system_libs.iter().map(|l| (l.clone(), true)))
            .collect();
        loop {
            let before = pending.len();
            let mut failed: Vec<(String, bool, String)> = Vec::new();
            for (lib, system) in std::mem::take(&mut pending) {
                let c = CString::new(lib.clone()).map_err(|_| "NUL in a library path")?;
                let h = unsafe { libc::dlopen(c.as_ptr(), libc::RTLD_GLOBAL | libc::RTLD_LAZY) };
                if h.is_null() {
                    failed.push((lib, system, dl_error()));
                } else {
                    handles.push(h);
                }
            }
            if failed.is_empty() {
                break;
            }
            if failed.len() == before {
                return Err(failed
                    .into_iter()
                    .map(|(l, system, e)| match system {
                        true => format!(
                            "cannot load `{l}`: {e}\n  The FMU does not ship it: \
                             sources/buildDescription.xml declares it external, so it has to be \
                             installed on this machine."
                        ),
                        false => format!("cannot load `{l}`: {e}"),
                    })
                    .collect::<Vec<_>>()
                    .join("\n"));
            }
            pending = failed.into_iter().map(|(l, system, _)| (l, system)).collect();
        }
        let mut fns = Vec::with_capacity(table.fns.len());
        for sig in &table.fns {
            let addr = resolve(&handles, &sig.name)
                .ok_or_else(|| format!("`external \"C\"` function `{}` is in none of the FMU's libraries", sig.name))?;
            let args: Vec<libffi::middle::Type> = sig.args.iter().map(|a| ffi_ty(&a.ty, a.out)).collect();
            let (ret, ret_bytes) = match &sig.ret {
                None => (libffi::middle::Type::void(), 8),
                Some(Ty::Scalar(Scalar::Real)) => (libffi::middle::Type::f64(), 8),
                Some(Ty::Scalar(_)) => (libffi::middle::Type::i32(), 8),
                Some(Ty::Str | Ty::Ptr) => (libffi::middle::Type::pointer(), 8),
                Some(Ty::Array(_) | Ty::Record(_)) => {
                    return Err(format!("`{}` returns an array or record, which C cannot", sig.name))
                }
            };
            fns.push(Resolved { sig: sig.clone(), addr, cif: libffi::middle::Cif::new(args, ret), ret_bytes });
        }
        Ok(Natives { fns, registry: vec![0] })
    }

    /// Call function `index` with `args` as [`marshal::gather`] laid them out;
    /// the results as [`marshal::scatter`] expects them.
    pub fn call(&mut self, index: u32, args: &[Value]) -> Result<Vec<Value>, String> {
        unsafe extern "C-unwind" {
            fn ffi_call(cif: *mut c_void, f: Option<unsafe extern "C-unwind" fn()>, rvalue: *mut c_void, avalue: *mut *mut c_void);
        }
        let f = self.fns.get(index as usize).ok_or("native externals: no such function")?;
        let sig = &f.sig;
        // Every argument as an 8-byte slot libffi points at; pointers point into
        // `buffers`/`cstrings`, which outlive the call.
        let mut slots: Vec<Cell> = Vec::with_capacity(sig.args.len());
        let mut cstrings: Vec<CString> = Vec::new();
        let mut buffers: Vec<Vec<u8>> = Vec::new();
        // (argument index, slot index, buffer index) of each output array.
        let mut out_arrays: Vec<(usize, usize)> = Vec::new();
        let mut cells: Vec<(usize, Box<Cell>)> = Vec::new();
        let mut next = args.iter();
        for (j, a) in sig.args.iter().enumerate() {
            if marshal::is_cell(a) {
                let mut cell = Box::new(Cell(0));
                slots.push(Cell(&mut *cell as *mut Cell as u64));
                cells.push((j, cell));
                continue;
            }
            let v = next.next().ok_or_else(|| format!("`{}`: too few arguments", sig.name))?;
            slots.push(match (&a.ty, v) {
                (Ty::Scalar(Scalar::Real), Value::Real(x)) => Cell(x.to_bits()),
                (Ty::Scalar(_), Value::Int(i)) => Cell(*i as i64 as u64),
                (Ty::Ptr, Value::Handle(h)) => Cell(self.registry.get(*h as usize).copied().unwrap_or(0) as u64),
                (Ty::Str, Value::Str(s)) => {
                    let c = CString::new(s.as_str()).map_err(|_| "string argument has an interior NUL")?;
                    let p = c.as_ptr() as u64;
                    cstrings.push(c);
                    Cell(p)
                }
                // A record crosses the same way, as a pointer to the bytes.
                (Ty::Array(_) | Ty::Record(_), Value::Bytes(b)) => {
                    let mut buf = b.clone();
                    // An empty array still needs an address.
                    buf.reserve(8);
                    let p = buf.as_mut_ptr() as u64;
                    if a.out {
                        out_arrays.push((j, buffers.len()));
                    }
                    buffers.push(buf);
                    Cell(p)
                }
                _ => return Err(format!("`{}`: argument {} has the wrong type", sig.name, j + 1)),
            });
        }
        let mut avalue: Vec<*mut c_void> = slots.iter_mut().map(|s| &mut s.0 as *mut u64 as *mut c_void).collect();
        let mut rvalue = vec![0u64; f.ret_bytes.div_ceil(8).max(1)];
        let target = unsafe { std::mem::transmute::<usize, unsafe extern "C-unwind" fn()>(f.addr) };
        let cif = f.cif.as_raw_ptr() as *mut c_void;
        error::begin();
        let outcome = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| unsafe {
            ffi_call(cif, Some(target), rvalue.as_mut_ptr() as *mut c_void, avalue.as_mut_ptr());
        }));
        let failure = error::end();
        #[cfg(feature = "utilities")]
        let _release = utilities::ReleaseStrings;
        if outcome.is_err() {
            return Err(failure.unwrap_or_else(|| format!("external \"C\" `{}` failed", sig.name)));
        }
        let mut results = Vec::new();
        let read = |ty: &Ty, word: u64, registry: &mut Vec<usize>| -> Result<Value, String> {
            Ok(match ty {
                Ty::Scalar(Scalar::Real) => Value::Real(f64::from_bits(word)),
                Ty::Scalar(_) => Value::Int(word as u32 as i32),
                Ty::Ptr => {
                    if word == 0 {
                        Value::Handle(0)
                    } else {
                        registry.push(word as usize);
                        Value::Handle(registry.len() as u32 - 1)
                    }
                }
                Ty::Str => {
                    let p = word as usize as *const libc::c_char;
                    Value::Str(if p.is_null() { String::new() } else { unsafe { CStr::from_ptr(p) }.to_string_lossy().into_owned() })
                }
                Ty::Array(_) => return Err("an array cannot be a C result".into()),
                Ty::Record(_) => return Err("a record cannot be a C result".into()),
            })
        };
        if let Some(ret) = &sig.ret {
            results.push(read(ret, rvalue[0], &mut self.registry)?);
        }
        for (j, cell) in &cells {
            results.push(read(&sig.args[*j].ty, cell.0, &mut self.registry)?);
        }
        for (_, b) in &out_arrays {
            results.push(Value::Bytes(buffers[*b].clone()));
        }
        Ok(results)
    }
}

/// The `omc_ext_call_<name>` wrapper an `Include` build carries (it adapts the
/// declared C prototype to this call shape), else the symbol itself.
fn resolve(handles: &[*mut c_void], name: &str) -> Option<usize> {
    for candidate in [format!("omc_ext_call_{name}"), name.to_string()] {
        let c = CString::new(candidate).ok()?;
        for h in handles {
            let p = unsafe { libc::dlsym(*h, c.as_ptr()) };
            if !p.is_null() {
                return Some(p as usize);
            }
        }
    }
    None
}

}

/// A `ModelicaError` inside the call reaches [`Natives::call`] as a panic
/// unwinding through the C frames. With `utilities` this crate raises it;
/// otherwise the host's own does, and [`error::set_message_source`] says where
/// it left the text.
pub mod error {
    use std::cell::RefCell;

    thread_local! {
        static MESSAGE: RefCell<Option<String>> = const { RefCell::new(None) };
        static SOURCE: RefCell<Option<fn() -> Option<String>>> = const { RefCell::new(None) };
    }

    /// Where the host's `ModelicaError` left the message of the error that unwound.
    pub fn set_message_source(f: fn() -> Option<String>) {
        SOURCE.with(|s| *s.borrow_mut() = Some(f));
    }

    pub(crate) fn begin() {
        MESSAGE.with(|m| *m.borrow_mut() = None);
    }

    pub(crate) fn end() -> Option<String> {
        MESSAGE.with(|m| m.borrow_mut().take()).or_else(|| SOURCE.with(|s| s.borrow().and_then(|f| f())))
    }

    /// Record `msg` and unwind out of the external call.
    pub fn raise(msg: String) -> ! {
        MESSAGE.with(|m| *m.borrow_mut() = Some(msg));
        std::panic::resume_unwind(Box::new(ModelicaError))
    }

    /// The panic payload; carries nothing, the message is in `MESSAGE`.
    pub struct ModelicaError;
}
