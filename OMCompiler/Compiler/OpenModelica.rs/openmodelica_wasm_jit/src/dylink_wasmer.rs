//! Loading shared-everything wasm libraries under wasmer: the `dylink.0` protocol
//! of [`crate::dylink_wasmtime`], and a port of its marshalling.
//!
//! With a simulation behind it ([`link_into`]) the libraries go in the runtime's
//! memory. Without one — the compiler evaluating a function — this loader owns the
//! memory: it places them with a bump allocator and leaves `__heap_base` at the
//! top, so libc's dlmalloc grows the rest from `sbrk`.

use std::collections::HashMap;
use std::sync::{Arc, OnceLock};

use wasmer::{
    AsStoreMut, AsStoreRef, Extern, Function, FunctionEnv, FunctionEnvMut, FunctionType, Global, Imports,
    Instance, Memory, MemoryType, Module, Pages, RuntimeError, Store, Table, TableType, Type,
    TypedFunction, Value,
};

use crate::dylink::{self, Dylink, SIDE_STACK_SIZE};

type Result<T> = std::result::Result<T, String>;

/// A shared library to place, in link order (first definition of a symbol wins).
pub struct Library<'a> {
    pub name: &'a str,
    pub bytes: &'a [u8],
}

/// Host state the `Modelica*` imports work against. The memory and the allocator
/// exist only once the libraries are placed, so the imports read them from here
/// rather than capturing them.
pub struct Host {
    memory: Option<Memory>,
    malloc: Option<TypedFunction<u32, u32>>,
    /// The guest's own `vsnprintf`, so a `Modelica*Format*` message is interpolated
    /// where its `va_list` lives rather than shown as a bare format string.
    vsnprintf: Option<TypedFunction<(u32, u32, u32, u32), u32>>,
    /// Offsets `ModelicaAllocateString` handed out since the last [`Linked::take_temps`].
    temps: Vec<u32>,
    /// The message of the last `ModelicaError`, which the trap itself cannot carry
    /// across the engine.
    error: Option<String>,
}

pub struct Linked {
    pub memory: Memory,
    pub table: Table,
    funcs: HashMap<String, Function>,
    pub malloc: TypedFunction<u32, u32>,
    pub free: TypedFunction<u32, ()>,
    /// The libraries' shared shadow stack: after a `ModelicaError` unwound their
    /// frames, the epilogues that would have handed it back never ran.
    pub stack_pointer: Option<Global>,
    host: FunctionEnv<Host>,
}

impl Linked {
    pub fn func(&self, name: &str) -> Option<&Function> {
        self.funcs.get(name)
    }

    /// `name`, else its `Include` wrapper: the call one for a macro, or what the
    /// address one points at.
    pub fn func_or_addr(&self, store: &mut impl AsStoreMut, name: &str) -> Option<Function> {
        if let Some(f) = self.funcs.get(name) {
            return Some(f.clone());
        }
        if let Some(f) = self.funcs.get(&format!("{}{name}", crate::model::EXT_CALL_PREFIX)) {
            return Some(f.clone());
        }
        let w = self.funcs.get(&format!("{}{name}", crate::model::EXT_ADDR_PREFIX))?;
        let w: TypedFunction<(), i32> = w.typed(&*store).ok()?;
        // Slot 0 is the null function pointer: the sources only declared it.
        match w.call(&mut *store).ok()? {
            0 => None,
            idx => self.table.get(store, idx as u32)?.funcref().cloned().flatten(),
        }
    }

    /// What `ModelicaAllocateString` allocated for the call just made; the caller
    /// frees them once it has copied the results out.
    pub fn take_temps(&self, store: &mut impl AsStoreMut) -> Vec<u32> {
        std::mem::take(&mut self.host.as_mut(store).temps)
    }

    /// The `ModelicaError` message behind the last trap, if that is what it was.
    pub fn take_error(&self, store: &mut impl AsStoreMut) -> Option<String> {
        self.host.as_mut(store).error.take()
    }
}

/// How the loader reserves bytes in the memory it places libraries in: its own
/// bump allocator when it created that memory, the runtime's `rt_alloc` when a
/// simulation owns it.
enum Reserve<'a> {
    /// The libraries' data segments and their shared shadow stack, and nothing
    /// else. It never runs again once a library has been called, so the pages
    /// dlmalloc grows for itself stay its own.
    Bump { memory: Memory, next: u32 },
    Guest(&'a TypedFunction<u32, u32>),
}

impl Reserve<'_> {
    fn alloc(&mut self, store: &mut impl AsStoreMut, size: u32, align: u32) -> Result<u32> {
        match self {
            Reserve::Bump { memory, next } => {
                let align = align.max(1);
                let addr = next.next_multiple_of(align);
                let end = addr.checked_add(size.max(1)).ok_or("dylink: the libraries do not fit in 4 GB")?;
                let have = memory.view(&store.as_store_ref()).data_size();
                if u64::from(end) > have {
                    let need = u64::from(end) - have;
                    let pages = need.div_ceil(u64::from(wasmer::WASM_PAGE_SIZE as u32));
                    memory
                        .grow(store, Pages(pages as u32))
                        .map_err(|e| format!("dylink: cannot grow the memory for a library: {e}"))?;
                }
                *next = end;
                Ok(addr)
            }
            // `rt_alloc` guarantees only 8-byte alignment, so over-allocate and
            // round up. A zero-size library still gets a distinct base.
            Reserve::Guest(alloc) => {
                let raw = alloc
                    .call(store, if size == 0 { 8 } else { size + align })
                    .map_err(|e| format!("rt_alloc: {e}"))?;
                Ok(if size == 0 { raw } else { dylink::align_up(raw, align) })
            }
        }
    }
}

/// Place `libs` in a memory of this loader's own, with the `Modelica*` utilities
/// of a host that has no run for a message to belong to.
pub fn link(store: &mut Store, libs: &[Library]) -> Result<Linked> {
    let memory = Memory::new(store, MemoryType::new(Pages(4), None, false))
        .map_err(|e| format!("dylink: cannot create the memory: {e}"))?;
    // Slot 0 stays the null function pointer, address 0 unused: both are real
    // values in the C these libraries are compiled from.
    let table = Table::new(store, TableType::new(Type::FuncRef, 1, None), Value::FuncRef(None))
        .map_err(|e| format!("dylink: cannot create the indirect function table: {e}"))?;
    let mut reserve = Reserve::Bump { memory: memory.clone(), next: 64 };
    let host = FunctionEnv::new(store, Host {
        memory: Some(memory.clone()),
        malloc: None,
        vsnprintf: None,
        temps: Vec::new(),
        error: None,
    });
    let imports = modelica_utilities_imports(store, &host);
    link_with(store, memory, table, &mut reserve, libs, &imports, host)
}

/// Place `libs` in a running simulation's memory, reserving with its `rt_alloc`
/// and giving the libraries its own `ModelicaUtilities`.
pub fn link_into(
    store: &mut Store,
    memory: Memory,
    table: Table,
    rt_alloc: &TypedFunction<u32, u32>,
    libs: &[Library],
    host_imports: &HashMap<String, Function>,
) -> Result<Linked> {
    let mut reserve = Reserve::Guest(rt_alloc);
    let host = FunctionEnv::new(store, Host {
        memory: Some(memory.clone()),
        malloc: None,
        vsnprintf: None,
        temps: Vec::new(),
        error: None,
    });
    link_with(store, memory, table, &mut reserve, libs, host_imports, host)
}

fn link_with(
    store: &mut Store,
    memory: Memory,
    table: Table,
    reserve: &mut Reserve,
    libs: &[Library],
    host_imports: &HashMap<String, Function>,
    host: FunctionEnv<Host>,
) -> Result<Linked> {
    if libs.is_empty() {
        return Err("dylink: nothing to link".to_owned());
    }
    let mut funcs: HashMap<String, Function> = HashMap::new();
    let mut data: HashMap<String, u32> = HashMap::new();

    // `libc.so` asks for the stack bounds by name (weak `GOT.mem` imports a main
    // module would define). An empty initial dlmalloc segment (base == end) sends
    // every allocation to `sbrk`, i.e. to freshly grown pages.
    let stack = reserve.alloc(store, SIDE_STACK_SIZE, 16)?;
    let stack_pointer = Global::new_mut(store, Value::I32((stack + SIDE_STACK_SIZE) as i32));
    data.insert("__stack_low".to_owned(), stack);
    data.insert("__stack_high".to_owned(), stack + SIDE_STACK_SIZE);
    data.insert("__heap_base".to_owned(), stack + SIDE_STACK_SIZE);
    data.insert("__heap_end".to_owned(), stack + SIDE_STACK_SIZE);

    // Every library's exports before any is placed: a PIC library reaches even its
    // own exported symbols through `env`, so one may call what a later one defines.
    // Such an import gets a trampoline, bound once everything is placed.
    let mut modules = Vec::with_capacity(libs.len());
    let mut defined: std::collections::HashSet<String> = std::collections::HashSet::new();
    for lib in libs {
        let module = Module::from_binary(store.engine(), lib.bytes)
            .map_err(|e| format!("external \"C\" library `{}` is not valid wasm: {e}", lib.name))?;
        defined.extend(
            module.exports().filter(|e| e.ty().func().is_some()).map(|e| e.name().to_owned()),
        );
        modules.push(module);
    }

    let mut got_mem: HashMap<String, Global> = HashMap::new();
    let mut got_func: HashMap<String, Global> = HashMap::new();
    let mut deferred: HashMap<String, DeferredTarget> = HashMap::new();
    let mut weak: std::collections::HashSet<String> = std::collections::HashSet::new();
    let mut relocs: Vec<(String, Function)> = Vec::new();
    let mut inits: Vec<(String, Function)> = Vec::new();

    let wasi_env = FunctionEnv::new(store, crate::wasi_shim::Env::new(&cwd()));
    wasi_env.as_mut(store).set_memory(memory.clone());

    for (lib, module) in libs.iter().zip(&modules) {
        let dl = dylink::parse(lib.bytes).ok_or_else(|| {
            format!(
                "external \"C\" library `{}` is not a shared library (no dylink.0 section) \
                 — build it with `clang -fPIC -shared`, not `-c`",
                lib.name
            )
        })?;
        weak.extend(dl.weak_imports.iter().cloned());
        let placed = place(
            store, module, lib.name, &dl, &memory, &table, reserve, &stack_pointer, &wasi_env,
            &host, host_imports, &defined, &mut deferred, &mut got_mem, &mut got_func, &mut funcs,
            &mut data,
        )?;
        if let Some(f) = placed.relocs {
            relocs.push((lib.name.to_owned(), f));
        }
        if let Some(f) = placed.init {
            inits.push((lib.name.to_owned(), f));
        }
    }

    for (sym, target) in &deferred {
        if let Some(f) = funcs.get(sym) {
            let _ = target.set(f.clone());
        }
    }

    for (sym, g) in &got_mem {
        let addr = match data.get(sym).copied() {
            Some(a) => a,
            None if weak.contains(sym) => 0,
            None => {
                return Err(format!("external \"C\" library references undefined data symbol `{sym}`"))
            }
        };
        g.set(store, Value::I32(addr as i32))
            .map_err(|e| format!("dylink: cannot set GOT.mem.{sym}: {e}"))?;
    }
    let mut func_slots: HashMap<String, u32> = HashMap::new();
    for (sym, g) in &got_func {
        let idx = match func_slot(store, &table, &funcs, &mut func_slots, sym) {
            Ok(i) => i,
            Err(_) if weak.contains(sym) => 0,
            Err(e) => return Err(e),
        };
        g.set(store, Value::I32(idx as i32))
            .map_err(|e| format!("dylink: cannot set GOT.func.{sym}: {e}"))?;
    }

    // Data relocations read the GOT, so they wait for its final values.
    for (name, f) in &relocs {
        f.call(&mut *store, &[])
            .map_err(|e| format!("external \"C\" library `{name}` failed to relocate: {e}"))?;
    }
    // Last, so a constructor may call into any library.
    for (name, f) in &inits {
        f.call(&mut *store, &[])
            .map_err(|e| format!("external \"C\" library `{name}` failed to initialise: {e}"))?;
    }

    let malloc = typed(store, &funcs, "malloc")?;
    let free: TypedFunction<u32, ()> = funcs
        .get("free")
        .ok_or_else(|| "dylink: the linked libraries define no `free`".to_owned())?
        .typed(&*store)
        .map_err(|e| format!("dylink: `free` has an unexpected signature: {e}"))?;
    host.as_mut(store).malloc = Some(malloc.clone());
    host.as_mut(store).vsnprintf = funcs.get("vsnprintf").and_then(|f| f.typed(&*store).ok());
    set_guest_cwd(store, &memory, &data)?;

    Ok(Linked { memory, table, funcs, malloc, free, stack_pointer: Some(stack_pointer), host })
}

fn typed(
    store: &mut Store,
    funcs: &HashMap<String, Function>,
    name: &str,
) -> Result<TypedFunction<u32, u32>> {
    funcs
        .get(name)
        .ok_or_else(|| format!("dylink: the linked libraries define no `{name}`"))?
        .typed(&*store)
        .map_err(|e| format!("dylink: `{name}` has an unexpected signature: {e}"))
}

fn cwd() -> String {
    openmodelica_wasi::fs::cwd().unwrap_or_else(|_| "/".to_owned())
}

/// Give libc the process's own working directory: `__wasilibc_find_relpath`
/// resolves every relative path a library opens against `__wasilibc_cwd`.
fn set_guest_cwd(store: &mut Store, memory: &Memory, data: &HashMap<String, u32>) -> Result<()> {
    let (Some(&slot), Ok(dir)) = (data.get("__wasilibc_cwd"), openmodelica_wasi::fs::cwd()) else {
        return Ok(());
    };
    let mut bytes = dir.into_bytes();
    bytes.push(0);
    let Some(off) = grow_for(store, memory, bytes.len() as u32) else { return Ok(()) };
    let view = memory.view(&*store);
    view.write(off as u64, &bytes).map_err(|e| format!("dylink: cannot write the cwd: {e}"))?;
    view.write(slot as u64, &off.to_le_bytes())
        .map_err(|e| format!("dylink: cannot set __wasilibc_cwd: {e}"))
}

/// A page past everything placed, rather than a byte of dlmalloc's.
fn grow_for(store: &mut Store, memory: &Memory, size: u32) -> Option<u32> {
    let have = memory.view(&*store).data_size();
    let pages = u64::from(size).div_ceil(u64::from(wasmer::WASM_PAGE_SIZE as u32));
    memory.grow(store, Pages(pages as u32)).ok()?;
    Some(have as u32)
}

/// What [`place`] leaves for `link` to run once every library is in.
struct Placed {
    relocs: Option<Function>,
    init: Option<Function>,
}

/// Give one library its addresses, bind its imports and instantiate it.
#[allow(clippy::too_many_arguments)]
fn place(
    store: &mut Store,
    module: &Module,
    lib_name: &str,
    dl: &Dylink,
    memory: &Memory,
    table: &Table,
    reserve: &mut Reserve,
    stack_pointer: &Global,
    wasi_env: &FunctionEnv<crate::wasi_shim::Env>,
    host: &FunctionEnv<Host>,
    host_imports: &HashMap<String, Function>,
    defined: &std::collections::HashSet<String>,
    deferred: &mut HashMap<String, DeferredTarget>,
    got_mem: &mut HashMap<String, Global>,
    got_func: &mut HashMap<String, Global>,
    funcs: &mut HashMap<String, Function>,
    data: &mut HashMap<String, u32>,
) -> Result<Placed> {
    let memory_base = reserve.alloc(store, dl.mem.mem_size, dl.mem.mem_align())?;
    let table_base = if dl.mem.table_size == 0 {
        table.size(&*store)
    } else {
        table
            .grow(store, dl.mem.table_size, Value::FuncRef(None))
            .map_err(|e| format!("dylink: cannot grow the table for `{lib_name}`: {e}"))?
    };

    let mut imports = Imports::new();
    // Real file I/O over omc's VFS, for a library that reads files.
    crate::wasi_shim::add_to_imports(store, wasi_env, &mut imports);
    for imp in module.imports() {
        let (m, name) = (imp.module().to_owned(), imp.name().to_owned());
        let ext: Extern = match (m.as_str(), name.as_str()) {
            ("env", "memory") => memory.clone().into(),
            ("env", "__indirect_function_table") => table.clone().into(),
            ("env", "__stack_pointer") => stack_pointer.clone().into(),
            ("env", "__memory_base") => Global::new(store, Value::I32(memory_base as i32)).into(),
            // `__table_base32` is the 64-bit variant's spelling of the same value.
            ("env", "__table_base" | "__table_base32") => {
                Global::new(store, Value::I32(table_base as i32)).into()
            }
            ("GOT.mem", sym) => got_entry(store, got_mem, sym).into(),
            ("GOT.func", sym) => got_entry(store, got_func, sym).into(),
            ("env", sym) => {
                let Some(ty) = imp.ty().func().cloned() else {
                    return Err(format!(
                        "external \"C\" library `{lib_name}` imports env.{sym}, which is not a function"
                    ));
                };
                // A placed library's export, else a host import, else deferred.
                match funcs.get(sym).or_else(|| host_imports.get(sym)) {
                    Some(f) => f.clone().into(),
                    None if defined.contains(sym) => {
                        deferred_import(store, host, &ty, deferred, sym).into()
                    }
                    None => missing_symbol_stub(store, host, &ty, lib_name, sym).into(),
                }
            }
            ("wasi_snapshot_preview1", sym) => match imports.get_export(&m, sym) {
                Some(e) => e,
                None => {
                    let Some(ty) = imp.ty().func().cloned() else { continue };
                    missing_symbol_stub(store, host, &ty, lib_name, sym).into()
                }
            },
            (m, name) => {
                return Err(format!(
                    "external \"C\" library `{lib_name}` imports {m}.{name}, which no wasm-jit host provides"
                ))
            }
        };
        imports.define(&m, &name, ext);
    }

    let instance = Instance::new(store, module, &imports)
        .map_err(|e| format!("external \"C\" library `{lib_name}` failed to load: {e}"))?;

    let mut placed = Placed { relocs: None, init: None };
    for (name, ext) in instance.exports.iter() {
        match ext {
            Extern::Function(f) => {
                match name.as_str() {
                    "__wasm_apply_data_relocs" => placed.relocs = Some(f.clone()),
                    // A reactor's `_initialize` runs `__wasm_call_ctors` itself.
                    "_initialize" => placed.init = Some(f.clone()),
                    "__wasm_call_ctors" if placed.init.is_none() => placed.init = Some(f.clone()),
                    _ => {}
                }
                funcs.entry(name.clone()).or_insert_with(|| f.clone());
            }
            // A data symbol's global holds an offset within the library's data.
            Extern::Global(g) => {
                if let Value::I32(off) = g.get(store) {
                    data.entry(name.clone()).or_insert(memory_base.wrapping_add(off as u32));
                }
            }
            _ => {}
        }
    }
    Ok(placed)
}

/// The table index of `sym`, appending it the first time it is taken by address.
fn func_slot(
    store: &mut Store,
    table: &Table,
    funcs: &HashMap<String, Function>,
    slots: &mut HashMap<String, u32>,
    sym: &str,
) -> Result<u32> {
    if let Some(idx) = slots.get(sym) {
        return Ok(*idx);
    }
    let f = funcs
        .get(sym)
        .cloned()
        .ok_or_else(|| format!("external \"C\" library takes the address of undefined function `{sym}`"))?;
    let idx = table
        .grow(store, 1, Value::FuncRef(Some(f)))
        .map_err(|e| format!("dylink: cannot grow the indirect function table: {e}"))?;
    slots.insert(sym.to_owned(), idx);
    Ok(idx)
}

/// The mutable global backing one GOT entry, created on first reference.
fn got_entry(store: &mut Store, map: &mut HashMap<String, Global>, sym: &str) -> Global {
    map.entry(sym.to_owned())
        .or_insert_with(|| Global::new_mut(store, Value::I32(0)))
        .clone()
}

/// Traps naming the symbol, rather than returning a plausible zero.
fn missing_symbol_stub(
    store: &mut Store,
    host: &FunctionEnv<Host>,
    ty: &FunctionType,
    lib_name: &str,
    sym: &str,
) -> Function {
    let msg =
        format!("external \"C\" library `{lib_name}` called `{sym}`, which is not available in wasm");
    Function::new_with_env(store, host, ty.clone(), move |_: FunctionEnvMut<Host>, _: &[Value]| {
        Err(RuntimeError::new(msg.clone()))
    })
}

/// Where a deferred `env` import ends up, once every library is instantiated.
type DeferredTarget = Arc<OnceLock<Function>>;

/// A trampoline over the [`DeferredTarget`] `link` fills in; one target per symbol.
fn deferred_import(
    store: &mut Store,
    host: &FunctionEnv<Host>,
    ty: &FunctionType,
    deferred: &mut HashMap<String, DeferredTarget>,
    sym: &str,
) -> Function {
    let target = deferred.entry(sym.to_owned()).or_default().clone();
    let sym = sym.to_owned();
    Function::new_with_env(store, host, ty.clone(), move |mut env: FunctionEnvMut<Host>, args: &[Value]| {
        match target.get() {
            Some(f) => f.call(&mut env, args).map(Vec::from),
            None => Err(RuntimeError::new(format!("external \"C\": `{sym}` was never defined"))),
        }
    })
}

// ── the ModelicaUtilities a library links against ────────────────────────────

/// `vsnprintf(buf, 2048, fmt, va)` in the guest, as C's `SIZE_LOG_BUFFER` does.
/// Without a `vsnprintf` to call, the format string itself is the best available.
fn format_va(
    env: &mut FunctionEnvMut<Host>,
    fmt: i32,
    va: i32,
) -> std::result::Result<String, RuntimeError> {
    const LOG_BUFFER: u32 = 2048;
    let (vsnprintf, malloc) = (env.data().vsnprintf.clone(), env.data().malloc.clone());
    let (Some(vsnprintf), Some(malloc)) = (vsnprintf, malloc) else {
        return Ok(read_cstr(&*env, fmt));
    };
    let buf = malloc.call(&mut *env, LOG_BUFFER)?;
    if buf == 0 {
        return Ok(read_cstr(&*env, fmt));
    }
    vsnprintf.call(&mut *env, buf, LOG_BUFFER, fmt as u32, va as u32)?;
    let msg = read_cstr(&*env, buf as i32);
    env.data_mut().temps.push(buf);
    Ok(msg)
}

fn read_cstr(env: &FunctionEnvMut<Host>, ptr: i32) -> String {
    let Some(mem) = env.data().memory.clone() else { return String::new() };
    crate::sim_runtime::read_cstr(&mem, &env.as_store_ref(), ptr as u32)
}

/// The `env` functions a library compiled against `ModelicaUtilities.h` expects,
/// and the `rt_ext_*` one carrying `external_c_callbacks.c` calls instead. A
/// `ModelicaError` ends the call, its message kept for the caller since the trap
/// cannot carry it.
fn modelica_utilities_imports(
    store: &mut Store,
    host: &FunctionEnv<Host>,
) -> HashMap<String, Function> {
    let mut m: HashMap<String, Function> = HashMap::new();

    let error = Function::new_typed_with_env(store, host, |mut env: FunctionEnvMut<Host>, ptr: i32| {
        let msg = read_cstr(&env, ptr);
        env.data_mut().error = Some(msg.clone());
        Err::<(), _>(RuntimeError::new(msg))
    });
    let warning = Function::new_typed_with_env(store, host, |env: FunctionEnvMut<Host>, ptr: i32| {
        openmodelica_error::ErrorExt::runtime_warning(&read_cstr(&env, ptr));
    });
    let message = Function::new_typed_with_env(store, host, |env: FunctionEnvMut<Host>, ptr: i32| {
        openmodelica_error::ErrorExt::runtime_message(&read_cstr(&env, ptr));
    });
    // The varargs forms: `%s` and friends are interpolated by the guest's own
    // `vsnprintf`, where the `va_list` it is given points.
    let error_fmt = Function::new_typed_with_env(store, host, |mut env: FunctionEnvMut<Host>, fmt: i32, va: i32| -> std::result::Result<(), RuntimeError> {
        let msg = format_va(&mut env, fmt, va)?;
        env.data_mut().error = Some(msg.clone());
        Err(RuntimeError::new(msg))
    });
    let warning_fmt = Function::new_typed_with_env(store, host, |mut env: FunctionEnvMut<Host>, fmt: i32, va: i32| -> std::result::Result<(), RuntimeError> {
        openmodelica_error::ErrorExt::runtime_warning(&format_va(&mut env, fmt, va)?);
        Ok(())
    });
    let message_fmt = Function::new_typed_with_env(store, host, |mut env: FunctionEnvMut<Host>, fmt: i32, va: i32| -> std::result::Result<(), RuntimeError> {
        openmodelica_error::ErrorExt::runtime_message(&format_va(&mut env, fmt, va)?);
        Ok(())
    });
    // `ModelicaAllocateString`'s buffer lives in the shared memory, so the caller
    // can read it; it is freed once the call's results are out.
    let allocate = Function::new_typed_with_env(store, host, |mut env: FunctionEnvMut<Host>, len: i32| -> std::result::Result<i32, RuntimeError> {
        let malloc = env.data().malloc.clone()
            .ok_or_else(|| RuntimeError::new("ModelicaAllocateString before the libraries are up"))?;
        let n = len.max(0) as u32 + 1;
        let off = malloc.call(&mut env, n)?;
        if let Some(mem) = env.data().memory.clone() {
            mem.view(&env).write(off as u64, &vec![0u8; n as usize])
                .map_err(|e| RuntimeError::new(format!("{e}")))?;
        }
        env.data_mut().temps.push(off);
        Ok(off as i32)
    });
    // ModelicaRandom's automatic global seed is the only caller: `getTime` leaves
    // its seven int* outputs alone and `getpid` is a constant.
    let get_time = Function::new_typed(store, |_: i32, _: i32, _: i32, _: i32, _: i32, _: i32, _: i32| {});
    let getpid = Function::new_typed(store, || -> i32 { 1 });

    m.insert("ModelicaError".into(), error.clone());
    m.insert("ModelicaFormatError".into(), error_fmt.clone());
    m.insert("ModelicaVFormatError".into(), error_fmt);
    m.insert("ModelicaWarning".into(), warning.clone());
    m.insert("ModelicaFormatWarning".into(), warning_fmt.clone());
    m.insert("ModelicaVFormatWarning".into(), warning_fmt);
    m.insert("ModelicaMessage".into(), message.clone());
    m.insert("ModelicaFormatMessage".into(), message_fmt.clone());
    m.insert("ModelicaVFormatMessage".into(), message_fmt);
    m.insert("rt_ext_error".into(), error);
    m.insert("rt_ext_warning".into(), warning);
    m.insert("rt_ext_message".into(), message);
    m.insert("ModelicaAllocateString".into(), allocate.clone());
    m.insert("ModelicaAllocateStringWithErrorReturn".into(), allocate);
    m.insert("ModelicaInternal_getTime".into(), get_time);
    m.insert("ModelicaInternal_getpid".into(), getpid);
    m
}

// ── calling a library from a running simulation ──────────────────────────────
//
// Port of `dylink_wasmtime`'s `bind_in_wasm_external` / `call_external_in_wasm`,
// differing in how the memory is reached (a `MemoryView` that copies, where
// wasmtime lends a slice) and in recovering a failed call through the runtime's
// NLS trial state rather than a pending exception.

/// The runtime entry points an external "C" call needs.
#[derive(Clone)]
pub struct ExtRt {
    pub str_new: TypedFunction<u32, u32>,
    pub str_data: TypedFunction<u32, u32>,
    pub release: TypedFunction<u32, ()>,
    pub alloc: TypedFunction<u32, u32>,
    pub free: TypedFunction<u32, ()>,
    pub record_new: TypedFunction<(u32, u32), u32>,
    /// A run's solver state; there is none outside a simulation.
    pub nls: Option<NlsHooks>,
}

/// The runtime's recoverable-model-error state, so an external `ModelicaError`
/// inside a residual backs the trial off instead of ending the run.
#[derive(Clone)]
pub struct NlsHooks {
    pub recovering: TypedFunction<(), i32>,
    pub note: TypedFunction<(), ()>,
}

/// Per-`ext.<name>` state of a trampoline.
struct CallEnv {
    memory: Memory,
    rt: ExtRt,
    target: Function,
    sig: crate::sig::ExtCallSig,
    /// The libraries' shared shadow stack, restored after a call that abandoned
    /// frames on its way out.
    stack: Option<Global>,
}

/// The shared memory, read and written through a view (wasmer copies; there is no
/// slice into a js `WebAssembly.Memory`).
#[derive(Clone)]
struct Mem(Memory);

impl Mem {
    fn read(&self, store: &impl AsStoreRef, at: u32, buf: &mut [u8]) -> Result<()> {
        self.0.view(store).read(at as u64, buf).map_err(|e| format!("external \"C\": bad read: {e}"))
    }
    fn write(&self, store: &impl AsStoreRef, at: u32, bytes: &[u8]) -> Result<()> {
        self.0.view(store).write(at as u64, bytes).map_err(|e| format!("external \"C\": bad write: {e}"))
    }
    fn u32(&self, store: &impl AsStoreRef, at: u32) -> u32 {
        let mut b = [0u8; 4];
        let _ = self.read(store, at, &mut b);
        u32::from_le_bytes(b)
    }
    fn u64(&self, store: &impl AsStoreRef, at: u32) -> u64 {
        let mut b = [0u8; 8];
        let _ = self.read(store, at, &mut b);
        u64::from_le_bytes(b)
    }
    fn put_u32(&self, store: &impl AsStoreRef, at: u32, v: u32) {
        let _ = self.write(store, at, &v.to_le_bytes());
    }
    fn put_u64(&self, store: &impl AsStoreRef, at: u32, v: u64) {
        let _ = self.write(store, at, &v.to_le_bytes());
    }
    fn take(&self, store: &impl AsStoreRef, at: u32, len: usize) -> Result<Vec<u8>> {
        let mut buf = vec![0u8; len];
        self.read(store, at, &mut buf)?;
        Ok(buf)
    }
    /// `memcpy` within the shared memory, plus a trailing NUL when `nul`.
    fn copy(&self, store: &impl AsStoreRef, src: u32, dst: u32, len: usize, nul: bool) -> Result<()> {
        let mut buf = self.take(store, src, len + usize::from(nul))?;
        if nul {
            buf[len] = 0;
        }
        self.write(store, dst, &buf)
    }
    fn strlen(&self, store: &impl AsStoreRef, ptr: u32) -> Result<usize> {
        if ptr == 0 {
            return Ok(0);
        }
        let view = self.0.view(store);
        let end = view.data_size();
        let mut at = ptr as u64;
        let mut b = [0u8; 1];
        while at < end {
            view.read(at, &mut b).map_err(|e| format!("external \"C\": bad read: {e}"))?;
            if b[0] == 0 {
                return Ok((at - ptr as u64) as usize);
            }
            at += 1;
        }
        return Err("external \"C\": unterminated `char*`".to_string())
    }
    /// The dimensions of an in-wasm array object and the offset of its elements.
    fn array(&self, store: &impl AsStoreRef, obj: u32) -> Result<(Vec<usize>, u32)> {
        let ndims = self.u32(store, obj + 8) as usize;
        let dims = (0..ndims).map(|k| self.u32(store, obj + 16 + 4 * k as u32) as usize).collect();
        Ok((dims, ((16 + ndims * 4 + 7) & !7) as u32))
    }
}

/// Bind `ext.<name>` to a library export. An array argument is passed as the
/// address of the model's own elements — no copy either way; only a String
/// (length-prefixed, not NUL-terminated) and an `_Out_` cell need scratch.
///
/// `None` when the library's function has the wrong wasm type.
pub fn bind_in_wasm_external(
    store: &mut Store,
    sig: &crate::sig::ExtCallSig,
    functype: &FunctionType,
    target: Function,
    rt: &ExtRt,
    memory: &Memory,
    stack: Option<Global>,
) -> Option<Extern> {
    if dylink::is_direct_call(sig) {
        let ty = target.ty(&*store);
        let same = ty.params() == functype.params() && ty.results() == functype.results();
        return same.then(|| target.into());
    }
    let env = FunctionEnv::new(
        store,
        CallEnv { memory: memory.clone(), rt: rt.clone(), target, sig: sig.clone(), stack },
    );
    let name = sig.name.to_string();
    Some(
        Function::new_with_env(store, &env, functype.clone(), move |mut env: FunctionEnvMut<CallEnv>, args: &[Value]| {
            let saved = saved_stack(&mut env);
            match call_external_in_wasm(&mut env, args) {
                Ok(v) => Ok(v),
                Err(e) => match recover_trial(&mut env, saved)? {
                    Some(zeroed) => Ok(zeroed),
                    None => Err(RuntimeError::new(format!("external \"C\" `{name}`: {e}"))),
                },
            }
        })
        .into(),
    )
}

fn saved_stack(env: &mut FunctionEnvMut<CallEnv>) -> Option<i32> {
    let g = env.data().stack.clone()?;
    g.get(env).i32()
}

/// What the model's `try_table` would have done for a `ModelicaError` whose throw
/// could not cross this host frame: inside a residual, note the trial and hand
/// back zeroed results; outside one, `None` — the call really failed. The shadow
/// stack goes back either way.
fn recover_trial(
    env: &mut FunctionEnvMut<CallEnv>,
    saved: Option<i32>,
) -> std::result::Result<Option<Vec<Value>>, RuntimeError> {
    use crate::sig::SigTy;
    let (data, mut store) = env.data_and_store_mut();
    let (nls, str_new, sig, stack) =
        (data.rt.nls.clone(), data.rt.str_new.clone(), data.sig.clone(), data.stack.clone());
    if let (Some(g), Some(v)) = (stack, saved) {
        g.set(&mut store, Value::I32(v))?;
    }
    let Some(nls) = nls else { return Ok(None) };
    if nls.recovering.call(&mut store)? == 0 {
        return Ok(None);
    }
    nls.note.call(&mut store)?;
    let mut out = Vec::new();
    for ty in sig.wasm_results() {
        out.push(match ty {
            SigTy::Real => Value::F64(0.0),
            SigTy::Str => Value::I32(str_new.call(&mut store, 0)? as i32),
            _ => Value::I32(0),
        });
    }
    Ok(Some(out))
}

/// Call the library with the C argument list its prototype expects, then hand the
/// results back as the import's wasm results.
fn call_external_in_wasm(env: &mut FunctionEnvMut<CallEnv>, args: &[Value]) -> Result<Vec<Value>> {
    use crate::sig::SigTy;
    use dylink::{abi_of, c_record_layout, record_leaf, Abi};

    let (data, mut store) = env.data_and_store_mut();
    let mem = Mem(data.memory.clone());
    let rt = data.rt.clone();
    let target = data.target.clone();
    let sig = data.sig.clone();
    let fortran = sig.lang == crate::sig::ExtLang::Fortran77;

    let mut call_args: Vec<Value> = Vec::with_capacity(sig.args.len());
    let mut temps: Vec<u32> = Vec::new();
    // (output type, scratch address), in the order the import returns them.
    let mut out_cells: Vec<(SigTy, u32)> = Vec::new();
    // Column-major copies a FORTRAN 77 callee gets instead of the array itself:
    // (scratch, element area, dims, element size, is output).
    let mut f77_arrays: Vec<(u32, u32, Vec<usize>, usize, bool)> = Vec::new();
    // Output `String[…]`: (`char**` scratch, element area, element count).
    let mut str_out_arrays: Vec<(u32, u32, usize)> = Vec::new();

    // A returned struct comes back through an `sret` pointer ahead of every
    // declared argument (`struct ADD f(double)` → `(i32, f64) -> ()`).
    let sret = match sig.ret.as_ref().map(|t| (t, abi_of(t))) {
        Some((SigTy::Record { fields, .. }, Abi::Indirect)) => {
            let size = c_record_layout(fields).size.max(1);
            let cell = rt.alloc.call(&mut store, size).map_err(|e| format!("rt_alloc: {e}"))?;
            mem.write(&store, cell, &vec![0u8; size as usize])?;
            temps.push(cell);
            call_args.push(Value::I32(cell as i32));
            Some(cell)
        }
        _ => None,
    };

    let mut in_i = 0usize;
    for (ty, is_out) in &sig.args {
        // A struct: by pointer, or as its member's scalar when it has one member.
        if let SigTy::Record { fields, .. } = ty {
            // An output record is a wasm *result*, so it consumes no parameter.
            let v = if *is_out {
                None
            } else {
                let v = args.get(in_i).ok_or_else(|| {
                    "external \"C\": the call passes fewer arguments than the signature declares".to_string()
                })?;
                in_i += 1;
                Some(v)
            };
            match abi_of(ty) {
                // No members: no argument at all.
                Abi::Dropped => {
                    if *is_out {
                        out_cells.push((ty.clone(), 0));
                    }
                }
                Abi::Scalar(_) => {
                    if *is_out {
                        return Err("external \"C\": a single-member record cannot be an output".to_string());
                    }
                    let handle = v.and_then(|v| v.i32()).unwrap_or(0) as u32;
                    let (off, leaf) = record_leaf(fields);
                    call_args.push(match leaf {
                        SigTy::Real => Value::F64(f64::from_bits(mem.u64(&store, handle + off))),
                        _ => Value::I32(mem.u32(&store, handle + off) as i32),
                    });
                }
                Abi::Indirect => {
                    let c = c_record_layout(fields);
                    let cell = rt.alloc.call(&mut store, c.size.max(1)).map_err(|e| format!("rt_alloc: {e}"))?;
                    mem.write(&store, cell, &vec![0u8; c.size.max(1) as usize])?;
                    if let Some(v) = v {
                        let handle = v.i32().ok_or("external \"C\": expected a record handle")? as u32;
                        record_to_c(&mut store, &mem, &rt, fields, handle, cell, &mut temps)?;
                    }
                    temps.push(cell);
                    if *is_out {
                        out_cells.push((ty.clone(), cell));
                    }
                    call_args.push(Value::I32(cell as i32));
                }
            }
            continue;
        }
        // An `_Out_` scalar/string is written through a pointer; an output array is
        // filled in place, so it goes through the `Array` arm like an input.
        if *is_out && !matches!(ty, SigTy::Array { .. }) {
            let cell = rt.alloc.call(&mut store, 8).map_err(|e| format!("rt_alloc: {e}"))?;
            mem.write(&store, cell, &[0u8; 8])?;
            temps.push(cell);
            out_cells.push((ty.clone(), cell));
            call_args.push(Value::I32(cell as i32));
            continue;
        }
        let v = args.get(in_i).ok_or_else(|| {
            "external \"C\": the call passes fewer arguments than the signature declares".to_string()
        })?;
        in_i += 1;
        // FORTRAN 77 takes every argument by reference.
        if fortran && matches!(ty, SigTy::Real | SigTy::Int | SigTy::Bool) {
            let cell = rt.alloc.call(&mut store, 8).map_err(|e| format!("rt_alloc: {e}"))?;
            let mut raw = [0u8; 8];
            match ty {
                SigTy::Real => raw.copy_from_slice(&v.f64().ok_or("external \"C\": expected f64")?.to_le_bytes()),
                _ => raw[..4].copy_from_slice(&v.i32().ok_or("external \"C\": expected i32")?.to_le_bytes()),
            }
            mem.write(&store, cell, &raw)?;
            temps.push(cell);
            call_args.push(Value::I32(cell as i32));
            continue;
        }
        match ty {
            SigTy::Real => call_args.push(Value::F64(v.f64().ok_or("external \"C\": expected f64")?)),
            SigTy::Int | SigTy::Bool | SigTy::Ptr => {
                call_args.push(Value::I32(v.i32().ok_or("external \"C\": expected i32")?))
            }
            SigTy::Str => {
                // `char*`: the same bytes, NUL-terminated.
                let off = v.i32().ok_or("external \"C\": expected a String handle")? as u32;
                let len = mem.u32(&store, off + 4) as usize;
                let cell = rt.alloc.call(&mut store, (len + 1) as u32).map_err(|e| format!("rt_alloc: {e}"))?;
                mem.copy(&store, off + 8, cell, len, true)?;
                temps.push(cell);
                call_args.push(Value::I32(cell as i32));
            }
            SigTy::Array { elem, .. } => {
                let off = v.i32().ok_or("external \"C\": expected an array handle")? as u32;
                let (dims, data_off) = mem.array(&store, off)?;
                let base = off + data_off;
                // Handles, not the `const char**` C declares: rebuilt as a vector of
                // NUL-terminated copies (C's `data_of_string_c89_array`).
                if let SigTy::Str = &**elem {
                    let n: usize = dims.iter().product();
                    let vec_cell = rt.alloc.call(&mut store, (n * 4).max(1) as u32).map_err(|e| format!("rt_alloc: {e}"))?;
                    temps.push(vec_cell);
                    for k in 0..n {
                        let h = mem.u32(&store, base + (k * 4) as u32);
                        let len = if h == 0 { 0 } else { mem.u32(&store, h + 4) as usize };
                        let cell = rt.alloc.call(&mut store, (len + 1) as u32).map_err(|e| format!("rt_alloc: {e}"))?;
                        temps.push(cell);
                        mem.copy(&store, h + 8, cell, len, true)?;
                        mem.put_u32(&store, vec_cell + (k * 4) as u32, cell);
                    }
                    call_args.push(Value::I32(vec_cell as i32));
                    if *is_out {
                        str_out_arrays.push((vec_cell, base, n));
                    }
                    continue;
                }
                if fortran && dims.len() > 1 {
                    // C's `convert_alloc_*_to_f77`.
                    let esz = crate::host::array_abi::elem_size(elem);
                    let n = dims.iter().product::<usize>() * esz;
                    let cell = rt.alloc.call(&mut store, n as u32).map_err(|e| format!("rt_alloc: {e}"))?;
                    let src = mem.take(&store, base, n)?;
                    let mut buf = vec![0u8; n];
                    crate::host::array_abi::reorder(&src, &mut buf, &dims, esz, true);
                    mem.write(&store, cell, &buf)?;
                    temps.push(cell);
                    call_args.push(Value::I32(cell as i32));
                    f77_arrays.push((cell, base, dims, esz, *is_out));
                } else {
                    call_args.push(Value::I32(base as i32));
                }
            }
            _ => return Err("external \"C\": input argument type not marshalled".to_string()),
        }
    }

    // A struct return goes through `sret`, so the call itself yields nothing.
    let raw_out = target.call(&mut store, &call_args).map_err(|e| format!("{e}"))?;
    let raw_ret = raw_out.first().cloned().unwrap_or(Value::I32(0));

    // C's `convert_alloc_*_from_f77`.
    for (cell, base, dims, esz, is_out) in &f77_arrays {
        if !*is_out {
            continue;
        }
        let n = dims.iter().product::<usize>() * esz;
        let src = mem.take(&store, *cell, n)?;
        let mut buf = vec![0u8; n];
        crate::host::array_abi::reorder(&src, &mut buf, dims, *esz, false);
        mem.write(&store, *base, &buf)?;
    }

    // C's `unpack_string_array`; an element the callee did not write still points
    // at our own input copy.
    for (vec_cell, base, n) in &str_out_arrays {
        for k in 0..*n {
            let ptr = mem.u32(&store, vec_cell + (k * 4) as u32);
            let len = mem.strlen(&store, ptr)?;
            let handle = rt.str_new.call(&mut store, len as u32).map_err(|e| format!("rt_str_new: {e}"))?;
            let dst = rt.str_data.call(&mut store, handle).map_err(|e| format!("rt_str_data: {e}"))?;
            mem.copy(&store, ptr, dst, len, false)?;
            let slot = *base + (k * 4) as u32;
            let old = mem.u32(&store, slot);
            mem.put_u32(&store, slot, handle);
            if old != 0 {
                rt.release.call(&mut store, old).map_err(|e| format!("rt_release: {e}"))?;
            }
        }
    }

    let mut result: Vec<Value> = Vec::new();
    if let Some(ret_ty) = &sig.ret {
        match (ret_ty, abi_of(ret_ty)) {
            (SigTy::Record { fields, .. }, Abi::Indirect | Abi::Dropped) => {
                let handle = record_from_c(&mut store, &mem, &rt, fields, sret.unwrap_or(0))?;
                result.push(Value::I32(handle as i32));
            }
            (SigTy::Record { fields, .. }, Abi::Scalar(leaf)) => {
                let (off, _) = record_leaf(fields);
                let handle = record_from_scalar(&mut store, &mem, &rt, fields, off, &leaf, &raw_ret)?;
                result.push(Value::I32(handle as i32));
            }
            _ => {
                let raw = match ret_ty {
                    SigTy::Real => raw_ret.f64().unwrap_or(0.0).to_le_bytes(),
                    _ => {
                        let mut b = [0u8; 8];
                        b[..4].copy_from_slice(&raw_ret.i32().unwrap_or(0).to_le_bytes());
                        b
                    }
                };
                result.push(ext_result(&mut store, &mem, &rt, ret_ty, raw)?);
            }
        }
    }
    for (ty, cell) in &out_cells {
        if let SigTy::Record { fields, .. } = ty {
            let handle = record_from_c(&mut store, &mem, &rt, fields, *cell)?;
            result.push(Value::I32(handle as i32));
            continue;
        }
        let mut raw = [0u8; 8];
        mem.read(&store, *cell, &mut raw)?;
        result.push(ext_result(&mut store, &mem, &rt, ty, raw)?);
    }
    for t in temps {
        let _ = rt.free.call(&mut store, t);
    }
    Ok(result)
}

/// The 8 raw bytes the C side produced, as the wasm value the import declares. A
/// `char*` becomes a fresh String: the callee's buffer is its own to reuse.
fn ext_result(
    store: &mut impl AsStoreMut,
    mem: &Mem,
    rt: &ExtRt,
    ty: &crate::sig::SigTy,
    raw: [u8; 8],
) -> Result<Value> {
    use crate::sig::SigTy;
    Ok(match ty {
        SigTy::Real => Value::F64(f64::from_le_bytes(raw)),
        SigTy::Int | SigTy::Bool | SigTy::Ptr => {
            Value::I32(i32::from_le_bytes(raw[..4].try_into().expect("4 bytes")))
        }
        SigTy::Str => {
            let ptr = u32::from_le_bytes(raw[..4].try_into().expect("4 bytes"));
            let len = mem.strlen(&*store, ptr)?;
            let handle = rt.str_new.call(&mut *store, len as u32).map_err(|e| format!("rt_str_new: {e}"))?;
            let dst = rt.str_data.call(&mut *store, handle).map_err(|e| format!("rt_str_data: {e}"))?;
            mem.copy(&*store, ptr, dst, len, false)?;
            Value::I32(handle as i32)
        }
        _ => return Err("external \"C\": result type not marshalled".to_string()),
    })
}

// ─────────────────── records across the C boundary ───────────────────

/// Rebuild a single-member record from the scalar the ABI returned in place of it.
fn record_from_scalar(
    store: &mut impl AsStoreMut,
    mem: &Mem,
    rt: &ExtRt,
    fields: &[(arcstr::ArcStr, crate::sig::SigTy)],
    leaf_off: u32,
    leaf: &crate::sig::SigTy,
    value: &Value,
) -> Result<u32> {
    use crate::sig::SigTy;
    let layout = crate::sig::record_layout(fields);
    let handle = rt
        .record_new
        .call(&mut *store, layout.heap.len() as u32, layout.size)
        .map_err(|e| format!("rt_record_new: {e}"))?;
    for (k, (kind, off)) in layout.heap.iter().enumerate() {
        mem.put_u32(&*store, handle + 8 + k as u32 * 8, *kind);
        mem.put_u32(&*store, handle + 8 + k as u32 * 8 + 4, *off);
    }
    // A nested one needs its own object before the value can go in.
    if let Some((_, SigTy::Record { fields: inner, .. })) = fields.first()
        && inner.len() == 1
    {
        let nested = record_from_scalar(store, mem, rt, inner, leaf_off, leaf, value)?;
        mem.put_u32(&*store, handle + layout.data_off + layout.field_off[0], nested);
        return Ok(handle);
    }
    let at = handle + layout.data_off + layout.field_off.first().copied().unwrap_or(0);
    match leaf {
        SigTy::Real => mem.put_u64(&*store, at, value.f64().unwrap_or(0.0).to_bits()),
        SigTy::Str => {
            let s = wasm_string(store, mem, rt, value.i32().unwrap_or(0) as u32)?;
            mem.put_u32(&*store, at, s);
        }
        _ => mem.put_u32(&*store, at, value.i32().unwrap_or(0) as u32),
    }
    Ok(handle)
}

/// Write the record object `handle` into the C struct at `dst`; `temps` collects
/// scratch to release after.
fn record_to_c(
    store: &mut impl AsStoreMut,
    mem: &Mem,
    rt: &ExtRt,
    fields: &[(arcstr::ArcStr, crate::sig::SigTy)],
    handle: u32,
    dst: u32,
    temps: &mut Vec<u32>,
) -> Result<()> {
    use crate::sig::SigTy;
    let layout = crate::sig::record_layout(fields);
    let c = dylink::c_record_layout(fields);
    for (i, (_, ty)) in fields.iter().enumerate() {
        let src = handle + layout.data_off + layout.field_off[i];
        let at = dst + c.offsets[i];
        match ty {
            SigTy::Real => {
                let v = mem.u64(&*store, src);
                mem.put_u64(&*store, at, v);
            }
            SigTy::Int | SigTy::Bool | SigTy::Ptr => {
                let v = mem.u32(&*store, src);
                mem.put_u32(&*store, at, v);
            }
            SigTy::Str => {
                let s = mem.u32(&*store, src);
                let p = c_string(store, mem, rt, s, temps)?;
                mem.put_u32(&*store, at, p);
            }
            SigTy::Array { .. } => {
                // The elements themselves, so the callee writes the model's array.
                let h = mem.u32(&*store, src);
                let (_, data_off) = mem.array(&*store, h)?;
                mem.put_u32(&*store, at, h + data_off);
            }
            SigTy::Record { fields: inner, .. } => {
                let h = mem.u32(&*store, src);
                record_to_c(store, mem, rt, inner, h, at, temps)?;
            }
            _ => return Err("external \"C\": record field type not marshalled".to_string()),
        }
    }
    Ok(())
}

/// The inverse of [`record_to_c`], for an `_Out_` record or a returned struct.
fn record_from_c(
    store: &mut impl AsStoreMut,
    mem: &Mem,
    rt: &ExtRt,
    fields: &[(arcstr::ArcStr, crate::sig::SigTy)],
    src: u32,
) -> Result<u32> {
    use crate::sig::SigTy;
    let layout = crate::sig::record_layout(fields);
    let c = dylink::c_record_layout(fields);
    let handle = rt
        .record_new
        .call(&mut *store, layout.heap.len() as u32, layout.size)
        .map_err(|e| format!("rt_record_new: {e}"))?;
    // The inline table the runtime releases the record's heap fields by.
    for (k, (kind, off)) in layout.heap.iter().enumerate() {
        mem.put_u32(&*store, handle + 8 + k as u32 * 8, *kind);
        mem.put_u32(&*store, handle + 8 + k as u32 * 8 + 4, *off);
    }
    for (i, (_, ty)) in fields.iter().enumerate() {
        let at = src + c.offsets[i];
        let dst = handle + layout.data_off + layout.field_off[i];
        match ty {
            SigTy::Real => {
                let v = mem.u64(&*store, at);
                mem.put_u64(&*store, dst, v);
            }
            SigTy::Int | SigTy::Bool | SigTy::Ptr => {
                let v = mem.u32(&*store, at);
                mem.put_u32(&*store, dst, v);
            }
            SigTy::Str => {
                let p = mem.u32(&*store, at);
                let s = wasm_string(store, mem, rt, p)?;
                mem.put_u32(&*store, dst, s);
            }
            SigTy::Record { fields: inner, .. } => {
                let h = record_from_c(store, mem, rt, inner, at)?;
                mem.put_u32(&*store, dst, h);
            }
            _ => return Err("external \"C\": record field type not marshalled".to_string()),
        }
    }
    Ok(handle)
}

/// A NUL-terminated copy of the String `handle`, as a `char*`.
fn c_string(
    store: &mut impl AsStoreMut,
    mem: &Mem,
    rt: &ExtRt,
    handle: u32,
    temps: &mut Vec<u32>,
) -> Result<u32> {
    if handle == 0 {
        return Ok(0);
    }
    let len = mem.u32(&*store, handle + 4) as usize;
    let cell = rt.alloc.call(&mut *store, (len + 1) as u32).map_err(|e| format!("rt_alloc: {e}"))?;
    mem.copy(&*store, handle + 8, cell, len, true)?;
    temps.push(cell);
    Ok(cell)
}

/// A fresh String with the bytes of the `char*` at `ptr`.
fn wasm_string(store: &mut impl AsStoreMut, mem: &Mem, rt: &ExtRt, ptr: u32) -> Result<u32> {
    let len = mem.strlen(&*store, ptr)?;
    let handle = rt.str_new.call(&mut *store, len as u32).map_err(|e| format!("rt_str_new: {e}"))?;
    let dst = rt.str_data.call(&mut *store, handle).map_err(|e| format!("rt_str_data: {e}"))?;
    if len > 0 {
        mem.copy(&*store, ptr, dst, len, false)?;
    }
    Ok(handle)
}
