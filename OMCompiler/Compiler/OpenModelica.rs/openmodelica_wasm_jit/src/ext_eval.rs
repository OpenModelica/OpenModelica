//! Compile-time `external "C"` evaluation for a wasm build of omc: the loader and
//! call primitives behind `System.loadLibrary`/`lookupFunction` and
//! `FFI.callFunction`, where there is no dlopen and no libffi.
//!
//! The library is the same PIC dylink module the simulation loads and an FMU
//! export links, placed in a memory of its own by [`crate::dylink_wasmer`], so
//! arguments are written into that memory rather than passed as host pointers.
//! This module owns the loader half, `FFI_wasm` the Modelica half.
//!
//! `NFEvalFunction` searches two kinds of path: `""`, the libraries omc carries,
//! and a `<lib>.wasm` under a Modelica library's `Resources/Library`, which is
//! linked in front of them so it may interpose. [`install`] hands the lot to
//! `openmodelica_util::dynload`, which cannot reach this crate itself.
use std::cell::RefCell;

use wasmer::{Function, Store, Value};

use crate::dylink_wasmer::{self, Linked};
use crate::sim_runtime::sim_engine;

/// A value crossing the wasm boundary: the C types an external function takes
/// reduce to these two once a pointer is an offset into its memory.
#[derive(Clone, Copy, Debug)]
pub enum Val {
    I32(i32),
    F64(f64),
}

/// What one `System.loadLibrary` handle stands for: the linked sets it has needed
/// so far. A library named by path is one set; the libraries omc carries are a set
/// per entry point asked for, since which of them to link follows from the name.
struct LibEntry {
    key: String,
    worlds: Vec<Linked>,
}

struct FuncEntry {
    lib: usize,
    world: usize,
    func: Function,
}

struct Registry {
    store: Store,
    libs: Vec<Option<LibEntry>>,
    funcs: Vec<Option<FuncEntry>>,
}

thread_local! {
    static REG: RefCell<Option<Registry>> = const { RefCell::new(None) };
}

fn with_reg<R>(f: impl FnOnce(&mut Registry) -> R) -> R {
    REG.with(|r| {
        let mut r = r.borrow_mut();
        let reg = r.get_or_insert_with(|| Registry {
            store: Store::new(sim_engine().clone()),
            libs: Vec::new(),
            funcs: Vec::new(),
        });
        f(reg)
    })
}

impl Registry {
    fn lib(&mut self, handle: i32) -> std::result::Result<&mut LibEntry, String> {
        let i = (handle - 1).max(-1) as usize;
        self.libs.get_mut(i).and_then(|l| l.as_mut()).ok_or_else(|| "no such library handle".to_owned())
    }

    fn of(&mut self, handle: i32) -> std::result::Result<(&mut Store, &Linked, &Function), String> {
        let i = (handle - 1).max(-1) as usize;
        let (lib, world) = {
            let f = self.funcs.get(i).and_then(|f| f.as_ref())
                .ok_or_else(|| "no such function handle".to_owned())?;
            (f.lib, f.world)
        };
        let func = &self.funcs[i].as_ref().expect("checked above").func;
        let linked = self
            .libs
            .get(lib)
            .and_then(|l| l.as_ref())
            .and_then(|l| l.worlds.get(world))
            .ok_or_else(|| "the library the function came from was freed".to_owned())?;
        Ok((&mut self.store, linked, func))
    }
}

// ── the loader `openmodelica_util::dynload` routes to ────────────────────────

/// The libraries to link for `sym`. Empty when nothing omc carries exports it.
fn libraries_for(sym: &str) -> std::result::Result<Vec<dylink_wasmer::Library<'static>>, String> {
    let carried = crate::dylink::libraries_for([sym]);
    if carried.is_empty() {
        return Ok(Vec::new());
    }
    if crate::LIBC_PIC().is_empty() {
        return Err("this omc carries no PIC libc, so no shared library can be loaded".to_owned());
    }
    // `libc.so` first and the rest dependency-first: see `dylink::libraries_for`.
    let mut libs: Vec<dylink_wasmer::Library<'static>> =
        vec![dylink_wasmer::Library { name: "libc.so", bytes: crate::LIBC_PIC() }];
    for file in carried {
        match crate::ext_library(file) {
            Some(bytes) => libs.push(dylink_wasmer::Library { name: file, bytes }),
            None => return Err(format!("`{sym}` is in `{file}`, which this bundle does not have")),
        }
    }
    libs.push(dylink_wasmer::Library { name: "usertab", bytes: crate::USERTAB_DYLINK() });
    Ok(libs)
}

/// `System.loadLibrary`. An empty `path` means the libraries omc carries: which
/// ones is not known until a name is looked up, so the handle starts empty and
/// grows a linked set per name ([`lookup_function`]). Anything else is a `.wasm`
/// read through the VFS. Lazy loading has no meaning for a wasm module, so both
/// spellings do the same thing.
fn open_library(path: &str, _lazy: bool) -> std::result::Result<i32, String> {
    let own = if path.is_empty() {
        Vec::new()
    } else {
        openmodelica_wasi::fs::read(path).map_err(|e| format!("{e}"))?
    };
    with_reg(|reg| {
        if let Some(i) = reg.libs.iter().position(|l| l.as_ref().is_some_and(|l| l.key == path)) {
            return Ok(i as i32 + 1);
        }
        let mut entry = LibEntry { key: path.to_owned(), worlds: Vec::new() };
        if !own.is_empty() {
            if crate::LIBC_PIC().is_empty() {
                return Err("this omc carries no PIC libc, so no shared library can be loaded".to_owned());
            }
            // `libc.so` first, then the model's library ahead of the family's
            // base, so its own symbols win.
            let mut libs = vec![
                dylink_wasmer::Library { name: "libc.so", bytes: crate::LIBC_PIC() },
                dylink_wasmer::Library { name: path, bytes: &own },
            ];
            for file in ["ModelicaExternalC.wasm"] {
                if let Some(bytes) = crate::ext_library(file) {
                    libs.push(dylink_wasmer::Library { name: file, bytes });
                }
            }
            libs.push(dylink_wasmer::Library { name: "usertab", bytes: crate::USERTAB_DYLINK() });
            entry.worlds.push(dylink_wasmer::link(&mut reg.store, &libs)?);
        }
        reg.libs.push(Some(entry));
        Ok(reg.libs.len() as i32)
    })
}

/// `System.lookupFunction`. For the libraries omc carries this is where the set to
/// link is decided: the index says which library exports the name, and `dylink.0`
/// NEEDED says what that one needs.
fn lookup_function(lib: i32, name: &str) -> std::result::Result<i32, String> {
    with_reg(|reg| {
        let found = reg
            .lib(lib)?
            .worlds
            .iter()
            .enumerate()
            .find_map(|(i, w)| w.func(name).cloned().map(|f| (i, f)));
        if let Some((world, func)) = found {
            reg.funcs.push(Some(FuncEntry { lib: (lib - 1) as usize, world, func }));
            return Ok(reg.funcs.len() as i32);
        }
        if !reg.lib(lib)?.key.is_empty() {
            return Err(format!("it exports no `{name}`"));
        }
        let libs = libraries_for(name)?;
        if libs.is_empty() {
            return Err(missing(name));
        }
        let world = dylink_wasmer::link(&mut reg.store, &libs)?;
        let Some(func) = world.func(name).cloned() else {
            return Err(missing(name));
        };
        let entry = reg.lib(lib)?;
        entry.worlds.push(world);
        let world = entry.worlds.len() - 1;
        reg.funcs.push(Some(FuncEntry { lib: (lib - 1) as usize, world, func }));
        Ok(reg.funcs.len() as i32)
    })
}

fn missing(name: &str) -> String {
    if crate::ondemand_index_read() {
        format!("no shared library this omc carries exports `{name}`")
    } else {
        format!("no shared library this omc carries exports `{name}`, and the \
                 bundle's `wasm-blobs/index.json` could not be read")
    }
}

fn free_library(lib: i32) {
    with_reg(|reg| {
        let i = (lib - 1).max(-1) as usize;
        if let Some(slot) = reg.libs.get_mut(i) {
            *slot = None;
        }
        for f in reg.funcs.iter_mut() {
            if f.as_ref().is_some_and(|f| f.lib == i) {
                *f = None;
            }
        }
    })
}

fn free_function(func: i32) {
    with_reg(|reg| {
        let i = (func - 1).max(-1) as usize;
        if let Some(slot) = reg.funcs.get_mut(i) {
            *slot = None;
        }
    })
}

/// Let `System.loadLibrary` and friends reach this loader. `openmodelica_util`
/// depends on nothing that can run wasm, so it holds a hook instead.
pub fn install() {
    openmodelica_util::dynload::set_backend(openmodelica_util::dynload::Backend {
        open: open_library,
        lookup: lookup_function,
        free_library,
        free_function,
    });
}

// ── the call primitives `FFI_wasm` marshals with ─────────────────────────────

pub fn malloc(func: i32, size: u32) -> std::result::Result<u32, String> {
    with_reg(|reg| {
        let (store, linked, _) = reg.of(func)?;
        let malloc = linked.malloc.clone();
        malloc.call(store, size.max(1)).map_err(|e| format!("{e}"))
    })
}

pub fn free(func: i32, off: u32) -> std::result::Result<(), String> {
    with_reg(|reg| {
        let (store, linked, _) = reg.of(func)?;
        let free = linked.free.clone();
        free.call(store, off).map_err(|e| format!("{e}"))
    })
}

pub fn write_mem(func: i32, off: u32, bytes: &[u8]) -> std::result::Result<(), String> {
    with_reg(|reg| {
        let (store, linked, _) = reg.of(func)?;
        linked.memory.view(&*store).write(off as u64, bytes).map_err(|e| format!("{e}"))
    })
}

pub fn read_mem(func: i32, off: u32, out: &mut [u8]) -> std::result::Result<(), String> {
    with_reg(|reg| {
        let (store, linked, _) = reg.of(func)?;
        linked.memory.view(&*store).read(off as u64, out).map_err(|e| format!("{e}"))
    })
}

/// A NUL-terminated string in that memory, as a `char*` return value is.
pub fn read_cstring(func: i32, off: u32) -> std::result::Result<String, String> {
    with_reg(|reg| {
        let (store, linked, _) = reg.of(func)?;
        Ok(crate::sim_runtime::read_cstr(&linked.memory, &*store, off))
    })
}

/// Call the export, returning its result if it has one. The wasm signature is the
/// library's own: passing the wrong number or kind of argument is an engine error
/// here, which is what a mismatched `external "C"` declaration deserves.
pub fn call(func: i32, args: &[Val]) -> std::result::Result<Option<Val>, String> {
    let values: Vec<Value> = args.iter().map(|v| match v {
        Val::I32(i) => Value::I32(*i),
        Val::F64(f) => Value::F64(*f),
    }).collect();
    with_reg(|reg| {
        let (store, linked, f) = reg.of(func)?;
        let f = f.clone();
        // A `ModelicaError` the library raised is the reason the call trapped; the
        // trap itself cannot carry the message.
        let out = f.call(&mut *store, &values)
            .map_err(|e| linked.take_error(store).unwrap_or_else(|| format!("{e}")))?;
        Ok(match out.first() {
            Some(Value::F64(v)) => Some(Val::F64(*v)),
            Some(Value::I32(v)) => Some(Val::I32(*v)),
            _ => None,
        })
    })
}

/// Free what `ModelicaAllocateString` handed out during the last [`call`]. The
/// caller copies the strings out first — like the native arena, the storage lives
/// only as long as the call that produced it.
pub fn free_call_temps(func: i32) {
    let temps = with_reg(|reg| {
        let Ok((store, linked, _)) = reg.of(func) else { return Vec::new() };
        linked.take_temps(store)
    });
    for off in temps {
        let _ = free(func, off);
    }
}
