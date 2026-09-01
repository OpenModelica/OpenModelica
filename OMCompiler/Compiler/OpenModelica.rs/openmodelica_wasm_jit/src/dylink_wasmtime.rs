//! Loading shared-everything wasm libraries into a running simulation (wasmtime).
//!
//! The libraries share the runtime's memory and `__indirect_function_table`, so an
//! `external "C"` function takes pointers straight from the model. Placing one
//! means giving it a slice of the runtime heap (`env.__memory_base`), a run of
//! table slots (`env.__table_base`) and a stack; its own start function then
//! initialises its data relative to that base.

use std::collections::HashMap;

use wasmtime::{Caller, Extern, Func, FuncType, Global, GlobalType, Memory, Mutability, Ref, Table, Val, ValType};

use crate::dylink::{self, Dylink, SIDE_STACK_SIZE};
use openmodelica_wasi::wasi::WasiCtx;
use crate::model::SimModel;

type Result<T> = std::result::Result<T, String>;

pub struct Library {
    pub name: String,
    pub bytes: Vec<u8>,
    /// Worth an on-disk AOT artifact: a built-in library or one a `Library`
    /// annotation named, so every run loads the same bytes. One compiled from a
    /// model's own `Include` sources is not — caching it would leave a file per
    /// model behind, and only that process ever reloads it.
    pub fixed: bool,
}

impl Library {
    pub fn model(name: &str, bytes: Vec<u8>) -> Self {
        Library { name: name.to_string(), bytes, fixed: false }
    }
    fn ext(l: &crate::model::ExtLibrary) -> Self {
        Library { name: l.name.clone(), bytes: l.bytes.clone(), fixed: l.fixed }
    }
    /// One of the libraries built into omc, which also takes the on-disk artifact.
    pub fn builtin(name: &str, bytes: &'static [u8]) -> Self {
        Library { name: name.to_string(), bytes: bytes.to_vec(), fixed: true }
    }
}

pub struct Loaded {
    /// First library to define a symbol wins.
    funcs: HashMap<String, Func>,
    /// Data symbols as absolute addresses in the shared memory.
    data: HashMap<String, u32>,
    func_slots: HashMap<String, u32>,
    table: Table,
    /// The libraries' shared shadow stack: after a `ModelicaError` unwound their
    /// frames the epilogues that would have handed it back never ran, so the
    /// model's recovery path restores what it saved (`rt_ext_stack_restore`).
    stack_pointer: Option<Global>,
}

impl Loaded {
    pub fn func(&self, name: &str) -> Option<&Func> {
        self.funcs.get(name)
    }
    /// `name`, else its `Include` wrapper: the call one for a macro, or what the
    /// address one points at.
    pub fn func_or_addr(&self, store: &mut wasmtime::Store<WasiCtx>, name: &str) -> Option<Func> {
        if let Some(f) = self.funcs.get(name) {
            return Some(f.clone());
        }
        if let Some(f) = self.funcs.get(&format!("{}{name}", crate::model::EXT_CALL_PREFIX)) {
            return Some(f.clone());
        }
        let w = self.funcs.get(&format!("{}{name}", crate::model::EXT_ADDR_PREFIX))?;
        // Slot 0 is the null function pointer: the sources only declared it.
        match w.typed::<(), i32>(&*store).ok()?.call(&mut *store, ()).ok()? {
            0 => None,
            idx => self.table.get(store, idx as u64)?.as_func().flatten().cloned(),
        }
    }
    pub fn shadow_stack(&self) -> Option<Global> {
        self.stack_pointer
    }
}

/// `rt_alloc` guarantees only 8-byte alignment, so over-allocate and round up.
fn alloc_aligned(
    store: &mut wasmtime::Store<WasiCtx>,
    rt_alloc: &wasmtime::TypedFunc<u32, u32>,
    size: u32,
    align: u32,
) -> Result<u32> {
    if size == 0 {
        // A distinct base even so: a zero-size library must not alias another.
        return rt_alloc.call(&mut *store, 8).map_err(|e| format!("rt_alloc: {e}"));
    }
    let raw = rt_alloc
        .call(&mut *store, size + align)
        .map_err(|e| format!("rt_alloc: {e}"))?;
    Ok(dylink::align_up(raw, align))
}

/// Load `libs` in order — a library may use anything an earlier one exports, so
/// `libc.so` goes first. `memory`, `table` and `rt_alloc` are the runtime's.
pub fn load(
    store: &mut wasmtime::Store<WasiCtx>,
    engine: &wasmtime::Engine,
    memory: Memory,
    table: Table,
    rt_alloc: &wasmtime::TypedFunc<u32, u32>,
    libs: &[Library],
    host_imports: &HashMap<String, Func>,
) -> Result<Loaded> {
    let mut loaded = Loaded {
        funcs: HashMap::new(),
        data: HashMap::new(),
        func_slots: HashMap::new(),
        table,
        stack_pointer: None,
    };
    if libs.is_empty() {
        return Ok(loaded);
    }
    // A library imports the memory rather than exporting one, so the WASI shim
    // cannot find it through the caller.
    crate::host::set_sim_memory(memory);

    // `libc.so` asks for the stack bounds by name (weak `GOT.mem` imports a main
    // module would define), so they are seeded as data symbols.
    let stack = alloc_aligned(store, rt_alloc, SIDE_STACK_SIZE, 16)?;
    let stack_pointer = Global::new(
        &mut *store,
        GlobalType::new(ValType::I32, Mutability::Var),
        Val::I32((stack + SIDE_STACK_SIZE) as i32),
    )
    .map_err(|e| format!("dylink: cannot create __stack_pointer: {e}"))?;
    loaded.stack_pointer = Some(stack_pointer);
    loaded.data.insert("__stack_low".to_string(), stack);
    loaded.data.insert("__stack_high".to_string(), stack + SIDE_STACK_SIZE);
    // An empty initial dlmalloc segment: every allocation then comes from `sbrk`,
    // i.e. freshly grown pages, so libc cannot hand out `rt_alloc`'s bytes.
    loaded.data.insert("__heap_base".to_string(), stack + SIDE_STACK_SIZE);
    loaded.data.insert("__heap_end".to_string(), stack + SIDE_STACK_SIZE);

    // A GOT entry may name a symbol only a later library defines, so these are
    // mutable and patched once everything is placed.
    let mut got_mem: HashMap<String, Global> = HashMap::new();
    let mut got_func: HashMap<String, Global> = HashMap::new();

    // libc's file I/O goes through the same VFS omc uses.
    let mut wasi = wasmtime::Linker::new(engine);
    crate::wasi_shim::add_to_linker(&mut wasi).map_err(|e| format!("dylink: {e}"))?;

    // Every library's exports before any is placed: a PIC library reaches even its
    // own exported symbols through `env`, so they can be interposed, and one may
    // call what a later one defines. Such an import gets a trampoline, bound below.
    let mut modules = Vec::with_capacity(libs.len());
    let mut defined: std::collections::HashSet<String> = std::collections::HashSet::new();
    for lib in libs {
        let module = crate::sim_runtime::library_module(engine, &lib.name, &lib.bytes, lib.fixed)
            .map_err(|e| format!("external \"C\" library `{}` is not valid wasm: {e}", lib.name))?;
        defined.extend(module.exports().filter(|e| e.ty().func().is_some()).map(|e| e.name().to_string()));
        modules.push(module);
    }
    let mut deferred: HashMap<String, DeferredTarget> = HashMap::new();

    let mut weak: std::collections::HashSet<String> = std::collections::HashSet::new();
    for (lib, module) in libs.iter().zip(&modules) {
        let dl = dylink::parse(&lib.bytes).ok_or_else(|| {
            format!(
                "external \"C\" library `{}` is not a shared library (no dylink.0 section) \
                 — build it with `clang -fPIC -shared`, not `-c`",
                lib.name
            )
        })?;
        weak.extend(dl.weak_imports.iter().cloned());
        place(
            store,
            module,
            &lib.name,
            &dl,
            memory,
            table,
            rt_alloc,
            &stack_pointer,
            &wasi,
            host_imports,
            &defined,
            &mut deferred,
            &mut got_mem,
            &mut got_func,
            &mut loaded,
        )?;
    }
    for (sym, target) in &deferred {
        if let Some(f) = loaded.funcs.get(sym) {
            let _ = target.set(*f);
        }
    }

    for (sym, g) in &got_mem {
        let addr = match loaded.data.get(sym).copied() {
            Some(a) => a,
            None if weak.contains(sym) => 0,
            None => {
                return Err(format!("external \"C\" library references undefined data symbol `{sym}`"))
            }
        };
        g.set(&mut *store, Val::I32(addr as i32))
            .map_err(|e| format!("dylink: cannot set GOT.mem.{sym}: {e}"))?;
    }
    for (sym, g) in &got_func {
        let idx = match func_slot(store, &mut loaded, sym) {
            Ok(i) => i,
            Err(_) if weak.contains(sym) => 0,
            Err(e) => return Err(e),
        };
        g.set(&mut *store, Val::I32(idx as i32))
            .map_err(|e| format!("dylink: cannot set GOT.func.{sym}: {e}"))?;
    }

    // Data relocations read the GOT, so they wait for its final values.
    for lib in libs {
        if let Some(f) = loaded.funcs.get(&reloc_key(&lib.name)).cloned() {
            f.call(&mut *store, &[], &mut [])
                .map_err(|e| format!("external \"C\" library `{}` failed to relocate: {e}", lib.name))?;
        }
    }

    // Last, so a constructor may call into any library.
    for lib in libs {
        if let Some(init) = loaded.funcs.get(&init_key(&lib.name)).cloned() {
            init.call(&mut *store, &[], &mut [])
                .map_err(|e| format!("external \"C\" library `{}` failed to initialise: {e}", lib.name))?;
        }
    }
    set_guest_cwd(store, rt_alloc, memory, &loaded)?;
    unbuffer_stdout(store, &loaded)?;
    Ok(loaded)
}

/// Give libc the process's own working directory: `__wasilibc_find_relpath`
/// resolves every path a library opens against `__wasilibc_cwd`, which is `"/"` out
/// of the box. A later `chdir` frees only a buffer libc allocated itself.
fn set_guest_cwd(
    store: &mut wasmtime::Store<WasiCtx>,
    rt_alloc: &wasmtime::TypedFunc<u32, u32>,
    memory: Memory,
    loaded: &Loaded,
) -> Result<()> {
    let (Some(&slot), Ok(cwd)) = (loaded.data.get("__wasilibc_cwd"), openmodelica_wasi::fs::cwd()) else {
        return Ok(());
    };
    let bytes = cwd.as_bytes();
    let p = rt_alloc
        .call(&mut *store, bytes.len() as u32 + 1)
        .map_err(|e| format!("rt_alloc: {e}"))?;
    let data = memory.data_mut(&mut *store);
    let too_small = "dylink: the shared memory is too small for the working directory";
    let dst = data.get_mut(p as usize..p as usize + bytes.len() + 1).ok_or(too_small)?;
    dst[..bytes.len()].copy_from_slice(bytes);
    dst[bytes.len()] = 0;
    let ptr = data.get_mut(slot as usize..slot as usize + 4).ok_or(too_small)?;
    ptr.copy_from_slice(&p.to_le_bytes());
    Ok(())
}

/// Nothing flushes libc's buffer — the module is torn down, not exited — so a
/// library's `printf` would come out interleaved, or not at all.
fn unbuffer_stdout(store: &mut wasmtime::Store<WasiCtx>, loaded: &Loaded) -> Result<()> {
    const IONBF: i32 = 2;
    let (Some(setvbuf), Some(&stdout)) = (loaded.funcs.get("setvbuf").cloned(), loaded.data.get("stdout"))
    else {
        return Ok(());
    };
    // `stdout` is a `FILE **`, so the stream is one load away.
    let handle = crate::host::get_sim_memory()
        .and_then(|m| {
            let d = m.data(&*store);
            d.get(stdout as usize..stdout as usize + 4)
                .map(|b| u32::from_le_bytes(b.try_into().unwrap()))
        })
        .unwrap_or(0);
    if handle == 0 {
        return Ok(());
    }
    let mut ret = [Val::I32(0)];
    setvbuf
        .call(
            &mut *store,
            &[Val::I32(handle as i32), Val::I32(0), Val::I32(IONBF), Val::I32(0)],
            &mut ret,
        )
        .map_err(|e| format!("dylink: cannot make the external library's stdout unbuffered: {e}"))?;
    Ok(())
}

fn init_key(lib: &str) -> String {
    format!("\0init\0{lib}")
}

fn reloc_key(lib: &str) -> String {
    format!("\0reloc\0{lib}")
}

/// The table index of `sym`, appending it the first time it is taken by address.
fn func_slot(store: &mut wasmtime::Store<WasiCtx>, loaded: &mut Loaded, sym: &str) -> Result<u32> {
    if let Some(idx) = loaded.func_slots.get(sym) {
        return Ok(*idx);
    }
    let f = loaded
        .funcs
        .get(sym)
        .cloned()
        .ok_or_else(|| format!("external \"C\" library takes the address of undefined function `{sym}`"))?;
    let idx = loaded
        .table
        .grow(&mut *store, 1, Ref::Func(Some(f)))
        .map_err(|e| format!("dylink: cannot grow the indirect function table: {e}"))? as u32;
    loaded.func_slots.insert(sym.to_string(), idx);
    Ok(idx)
}

/// Give one library its addresses, bind its imports and instantiate it.
#[allow(clippy::too_many_arguments)]
fn place(
    store: &mut wasmtime::Store<WasiCtx>,
    module: &wasmtime::Module,
    lib_name: &str,
    dl: &Dylink,
    memory: Memory,
    table: Table,
    rt_alloc: &wasmtime::TypedFunc<u32, u32>,
    stack_pointer: &Global,
    wasi: &wasmtime::Linker<WasiCtx>,
    host_imports: &HashMap<String, Func>,
    defined: &std::collections::HashSet<String>,
    deferred: &mut HashMap<String, DeferredTarget>,
    got_mem: &mut HashMap<String, Global>,
    got_func: &mut HashMap<String, Global>,
    loaded: &mut Loaded,
) -> Result<()> {
    let memory_base = alloc_aligned(store, rt_alloc, dl.mem.mem_size, dl.mem.mem_align())?;
    let table_base = if dl.mem.table_size == 0 {
        table.size(&*store)
    } else {
        table
            .grow(&mut *store, dl.mem.table_size as u64, Ref::Func(None))
            .map_err(|e| format!("dylink: cannot grow the indirect function table for `{lib_name}`: {e}"))?
    } as u32;

    let mut imports: Vec<Extern> = Vec::new();
    for imp in module.imports() {
        let ext = match (imp.module(), imp.name()) {
            ("env", "memory") => Extern::Memory(memory),
            ("env", "__indirect_function_table") => Extern::Table(table),
            ("env", "__stack_pointer") => Extern::Global(*stack_pointer),
            ("env", "__memory_base") => Extern::Global(const_i32(store, memory_base)?),
            ("env", "__table_base") => Extern::Global(const_i32(store, table_base)?),
            // The 64-bit variant's spelling; same value.
            ("env", "__table_base32") => Extern::Global(const_i32(store, table_base)?),
            ("GOT.mem", sym) => Extern::Global(got_entry(store, got_mem, sym)?),
            ("GOT.func", sym) => Extern::Global(got_entry(store, got_func, sym)?),
            ("env", sym) => {
                // A placed library's export, else a host import, else deferred.
                let ty = imp
                    .ty()
                    .func()
                    .cloned()
                    .ok_or_else(|| format!("external \"C\" library `{lib_name}` imports env.{sym}, which is not a function"))?;
                match loaded.funcs.get(sym).or_else(|| host_imports.get(sym)) {
                    Some(f) => Extern::Func(*f),
                    None if defined.contains(sym) => Extern::Func(deferred_import(store, &ty, deferred, sym)),
                    None => Extern::Func(missing_symbol_stub(store, &ty, lib_name, sym)),
                }
            }
            ("wasi_snapshot_preview1", sym) => {
                // Real file I/O over omc's VFS.
                let ty = imp.ty().func().cloned().ok_or_else(|| {
                    format!("external \"C\" library `{lib_name}` imports a non-function from wasi_snapshot_preview1")
                })?;
                match wasi.get(&mut *store, "wasi_snapshot_preview1", sym) {
                    Ok(e) => e,
                    Err(_) => Extern::Func(missing_symbol_stub(store, &ty, lib_name, sym)),
                }
            }
            (module, name) => {
                return Err(format!(
                    "external \"C\" library `{lib_name}` imports {module}.{name}, which no wasm-jit host provides"
                ))
            }
        };
        imports.push(ext);
    }

    let instance = wasmtime::Instance::new(&mut *store, &module, &imports)
        .map_err(|e| format!("external \"C\" library `{lib_name}` failed to load: {e}"))?;

    // Before running anything, so a constructor can reach the rest of the library.
    let mut apply_relocs = None;
    let mut initialize = None;
    for exp in module.exports() {
        let name = exp.name().to_string();
        match instance.get_export(&mut *store, &name) {
            Some(Extern::Func(f)) => {
                match name.as_str() {
                    "__wasm_apply_data_relocs" => apply_relocs = Some(f),
                    // A reactor's `_initialize` runs `__wasm_call_ctors` itself.
                    "_initialize" => initialize = Some(f),
                    "__wasm_call_ctors" if initialize.is_none() => initialize = Some(f),
                    _ => {}
                }
                loaded.funcs.entry(name).or_insert(f);
            }
            Some(Extern::Global(g)) => {
                // A data symbol's global holds an offset within the library's data.
                if let Val::I32(off) = g.get(&mut *store) {
                    loaded.data.entry(name).or_insert(memory_base.wrapping_add(off as u32));
                }
            }
            _ => {}
        }
    }
    // Deferred to `load`: the GOT is not final until every library is placed.
    if let Some(f) = apply_relocs {
        loaded.funcs.insert(reloc_key(lib_name), f);
    }
    if let Some(f) = initialize {
        loaded.funcs.insert(init_key(lib_name), f);
    }
    Ok(())
}

fn const_i32(store: &mut wasmtime::Store<WasiCtx>, value: u32) -> Result<Global> {
    Global::new(
        &mut *store,
        GlobalType::new(ValType::I32, Mutability::Const),
        Val::I32(value as i32),
    )
    .map_err(|e| format!("dylink: cannot create a base global: {e}"))
}

/// The mutable global backing one GOT entry, created on first reference.
fn got_entry(
    store: &mut wasmtime::Store<WasiCtx>,
    map: &mut HashMap<String, Global>,
    sym: &str,
) -> Result<Global> {
    if let Some(g) = map.get(sym) {
        return Ok(*g);
    }
    let g = Global::new(
        &mut *store,
        GlobalType::new(ValType::I32, Mutability::Var),
        Val::I32(0),
    )
    .map_err(|e| format!("dylink: cannot create GOT entry for {sym}: {e}"))?;
    map.insert(sym.to_string(), g);
    Ok(g)
}

/// Traps naming the symbol, rather than returning a plausible zero.
fn missing_symbol_stub(
    store: &mut wasmtime::Store<WasiCtx>,
    ty: &FuncType,
    lib_name: &str,
    sym: &str,
) -> Func {
    let msg = format!("external \"C\" library `{lib_name}` called `{sym}`, which is not available in wasm");
    Func::new(&mut *store, ty.clone(), move |_: Caller<'_, WasiCtx>, _, _| {
        Err(wasmtime::Error::msg(msg.clone()))
    })
}

/// Where a deferred `env` import ends up, once every library is instantiated.
type DeferredTarget = std::sync::Arc<std::sync::OnceLock<Func>>;

/// A trampoline over the [`DeferredTarget`] `load` fills in; one target per symbol.
fn deferred_import(
    store: &mut wasmtime::Store<WasiCtx>,
    ty: &FuncType,
    deferred: &mut HashMap<String, DeferredTarget>,
    sym: &str,
) -> Func {
    let target = deferred.entry(sym.to_string()).or_default().clone();
    let sym = sym.to_string();
    Func::new(&mut *store, ty.clone(), move |mut caller: Caller<'_, WasiCtx>, args, rets| {
        match target.get() {
            Some(f) => f.call(&mut caller, args, rets),
            None => Err(wasmtime::Error::msg(format!("external \"C\": `{sym}` was never defined"))),
        }
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Compile `src` the way a user (and the testsuite's `setup_command`) does.
    fn build_library(name: &str, src: &str) -> Option<Vec<u8>> {
        let sysroot = option_env!("OMC_WASI_PIC_SYSROOT")?;
        let dir = std::env::temp_dir().join(format!("om-dylink-test-{}-{name}", std::process::id()));
        std::fs::create_dir_all(&dir).ok()?;
        let c = dir.join(format!("{name}.c"));
        let wasm = dir.join(format!("{name}.wasm"));
        std::fs::write(&c, src).ok()?;
        let status = std::process::Command::new("clang")
            .args(["--target=wasm32-wasip1", "-fPIC", "-shared", "-nodefaultlibs", "-O1"])
            .arg(format!("--sysroot={sysroot}"))
            .args(["-Wl,--export-all", "-Wl,--allow-undefined"])
            .arg("-o")
            .arg(&wasm)
            .arg(&c)
            .status()
            .ok()?;
        status.success().then(|| std::fs::read(&wasm).ok())?
    }

    /// `libc.so` under the library: a library's `_initialize` calls its
    /// `__wasi_init_tp`, so it is never absent.
    fn with_libc(name: &str, bytes: Vec<u8>) -> Option<[Library; 2]> {
        if openmodelica_wasi_libc::LIBC_PIC.is_empty() {
            eprintln!("no PIC libc; skipping");
            return None;
        }
        Some([
            Library::builtin("libc.so", openmodelica_wasi_libc::LIBC_PIC),
            Library::model(name, bytes),
        ])
    }

    /// The runtime owns the memory, table and allocator the libraries go in.
    fn runtime() -> (wasmtime::Store<WasiCtx>, wasmtime::Engine, wasmtime::Instance) {
        let engine = wasmtime::Engine::default();
        let module = wasmtime::Module::new(&engine, crate::RUNTIME_WASM).unwrap();
        let mut store = wasmtime::Store::new(&engine, WasiCtx::new("/", Vec::new()));
        let mut linker = wasmtime::Linker::new(&engine);
        crate::host::add_host_builtins(&mut linker).unwrap();
        let inst = linker.instantiate(&mut store, &module).unwrap();
        (store, engine, inst)
    }

    /// Placement, data-segment init against `__memory_base`, and the call.
    #[test]
    fn loads_a_library_and_calls_it() {
        let Some(bytes) = build_library("scalar", "double triple(double x) { return 3*x; }") else {
            eprintln!("no wasi sysroot; skipping");
            return;
        };
        let (mut store, engine, rt_inst) = runtime();
        let memory = rt_inst.get_memory(&mut store, "memory").unwrap();
        let table = rt_inst.get_table(&mut store, "__indirect_function_table").unwrap();
        let alloc = rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_alloc").unwrap();

        let Some(libs) = with_libc("scalar.wasm", bytes) else { return };
        let loaded = load(&mut store, &engine, memory, table, &alloc, &libs, &HashMap::new()).unwrap();
        let f = loaded.func("triple").expect("the library exports `triple`").clone();
        let f = f.typed::<f64, f64>(&store).unwrap();
        assert_eq!(f.call(&mut store, 5.0).unwrap(), 15.0);
    }

    /// Static data is reachable, and inside the region the loader allocated.
    #[test]
    fn static_data_is_relocated_into_the_shared_memory() {
        let Some(bytes) = build_library(
            "data",
            "static const double table[3] = {1.5, 2.5, 3.5};\n\
             double pick(int i) { return table[i]; }\n\
             const double *addr(void) { return table; }",
        ) else {
            eprintln!("no wasi sysroot; skipping");
            return;
        };
        let (mut store, engine, rt_inst) = runtime();
        let memory = rt_inst.get_memory(&mut store, "memory").unwrap();
        let table = rt_inst.get_table(&mut store, "__indirect_function_table").unwrap();
        let alloc = rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_alloc").unwrap();

        let Some(libs) = with_libc("data.wasm", bytes) else { return };
        let loaded = load(&mut store, &engine, memory, table, &alloc, &libs, &HashMap::new()).unwrap();
        let pick = loaded.func("pick").unwrap().clone().typed::<i32, f64>(&store).unwrap();
        assert_eq!(pick.call(&mut store, 1).unwrap(), 2.5);

        // It really is in the simulation's memory, so the host can read it.
        let addr = loaded.func("addr").unwrap().clone().typed::<(), i32>(&store).unwrap();
        let at = addr.call(&mut store, ()).unwrap() as usize;
        let raw = &memory.data(&store)[at..at + 8];
        assert_eq!(f64::from_le_bytes(raw.try_into().unwrap()), 1.5);
    }

    /// A library calling libc is served by the `libc.so` beneath it.
    #[test]
    fn a_library_can_use_libc() {
        let Some(bytes) = build_library(
            "uselibc",
            "#include <string.h>\n#include <stdlib.h>\n\
             int len_of_copy(const char *s) { char *d = strdup(s); int n = strlen(d); free(d); return n; }",
        ) else {
            eprintln!("no wasi sysroot; skipping");
            return;
        };
        let (mut store, engine, rt_inst) = runtime();
        let memory = rt_inst.get_memory(&mut store, "memory").unwrap();
        let table = rt_inst.get_table(&mut store, "__indirect_function_table").unwrap();
        let alloc = rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_alloc").unwrap();

        let Some(libs) = with_libc("uselibc.wasm", bytes) else { return };
        let loaded = load(&mut store, &engine, memory, table, &alloc, &libs, &HashMap::new()).unwrap();

        // A NUL-terminated string in the shared memory, as `Str` marshalling does.
        let cell = alloc.call(&mut store, 6).unwrap();
        memory.data_mut(&mut store)[cell as usize..cell as usize + 6].copy_from_slice(b"hello\0");
        let f = loaded.func("len_of_copy").unwrap().clone().typed::<i32, i32>(&store).unwrap();
        assert_eq!(f.call(&mut store, cell as i32).unwrap(), 5);
    }

    /// A scalar external is called wasm→wasm, so the types must agree.
    #[test]
    fn a_scalar_external_binds_directly() {
        use crate::sig::{ExtCallSig, ExtLang, SigTy};
        let Some(bytes) = build_library("bind", "double triple(double x) { return 3*x; }") else {
            return;
        };
        let Some(libs) = with_libc("bind.wasm", bytes) else { return };
        let (mut store, engine, rt_inst) = runtime();
        let memory = rt_inst.get_memory(&mut store, "memory").unwrap();
        let table = rt_inst.get_table(&mut store, "__indirect_function_table").unwrap();
        let alloc = rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_alloc").unwrap();
        let loaded = load(&mut store, &engine, memory, table, &alloc, &libs, &HashMap::new()).unwrap();

        let rt = ExtRt {
            str_new: rt_inst.get_typed_func(&mut store, "rt_str_new").unwrap(),
            str_data: rt_inst.get_typed_func(&mut store, "rt_str_data").unwrap(),
            release: rt_inst.get_typed_func(&mut store, "rt_release").unwrap(),
            alloc: alloc.clone(),
            free: rt_inst.get_typed_func(&mut store, "rt_free").unwrap(),
            record_new: rt_inst.get_typed_func(&mut store, "rt_record_new").unwrap(),
            nls: None,
        };
        let sig = ExtCallSig {
            name: "triple".into(),
            lang: ExtLang::C,
            args: vec![(SigTy::Real, false)],
            ret: Some(SigTy::Real),
        };
        let functype = wasmtime::FuncType::new(
            &engine,
            sig.wasm_params().iter().map(|t| match t.wty() {
                crate::sig::WTy::I32 => wasmtime::ValType::I32,
                crate::sig::WTy::F64 => wasmtime::ValType::F64,
            }),
            sig.wasm_results().iter().map(|t| match t.wty() {
                crate::sig::WTy::I32 => wasmtime::ValType::I32,
                crate::sig::WTy::F64 => wasmtime::ValType::F64,
            }),
        );
        let target = loaded.func("triple").unwrap().clone();
        let bound = bind_in_wasm_external(&mut store, &sig, &functype, target, &rt)
            .unwrap()
            .expect("a matching scalar external binds");
        let f = bound.into_func().unwrap().typed::<f64, f64>(&store).unwrap();
        assert_eq!(f.call(&mut store, 5.0).unwrap(), 15.0);
    }

    fn functype(engine: &wasmtime::Engine, sig: &crate::sig::FnSig) -> wasmtime::FuncType {
        let val = |t: &crate::sig::SigTy| match t.wty() {
            crate::sig::WTy::I32 => wasmtime::ValType::I32,
            crate::sig::WTy::F64 => wasmtime::ValType::F64,
        };
        wasmtime::FuncType::new(engine, sig.params.iter().map(val), sig.results.iter().map(val))
    }

    fn same_type(a: &wasmtime::FuncType, b: &wasmtime::FuncType) -> bool {
        a.params().len() == b.params().len()
            && a.results().len() == b.results().len()
            && a.params().zip(b.params()).all(|(x, y)| x.matches(&y))
            && a.results().zip(b.results()).all(|(x, y)| x.matches(&y))
    }

    /// A shared-memory kernel imports a library's function under the C prototype
    /// (`wasm_sig_c_shared`), the only shape that links against its export;
    /// `ModelicaRandom_xorshift64star(const int*, int*, double*)` is the case.
    #[test]
    fn shared_c_import_links_against_the_c_prototype() {
        use crate::sig::{ExtCallSig, ExtLang, SigTy};
        let Some(bytes) = build_library(
            "outptr",
            "void xorshift(const int *in, int *out, double *y) { out[0] = in[0] + 1; out[1] = in[1]; *y = 0.5; }\n\
             const char *greet(const char *s, int n) { return n > 0 ? s : \"\"; }",
        ) else {
            return;
        };
        let Some(libs) = with_libc("outptr.wasm", bytes) else { return };
        let (mut store, engine, rt_inst) = runtime();
        let memory = rt_inst.get_memory(&mut store, "memory").unwrap();
        let table = rt_inst.get_table(&mut store, "__indirect_function_table").unwrap();
        let alloc = rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_alloc").unwrap();
        let loaded = load(&mut store, &engine, memory, table, &alloc, &libs, &HashMap::new()).unwrap();

        let ints = SigTy::Array { elem: std::sync::Arc::new(SigTy::Int), rank: 1 };
        let xorshift = ExtCallSig {
            name: "xorshift".into(),
            lang: ExtLang::C,
            args: vec![(ints.clone(), false), (ints, true), (SigTy::Real, true)],
            ret: None,
        };
        let export = loaded.func("xorshift").unwrap().ty(&store);
        assert!(same_type(&export, &functype(&engine, &xorshift.wasm_sig_c_shared())));
        assert!(!same_type(&export, &functype(&engine, &xorshift.wasm_sig())), "the host shape must not link");

        let greet = ExtCallSig {
            name: "greet".into(),
            lang: ExtLang::C,
            args: vec![(SigTy::Str, false), (SigTy::Int, false)],
            ret: Some(SigTy::Str),
        };
        let export = loaded.func("greet").unwrap().ty(&store);
        assert!(same_type(&export, &functype(&engine, &greet.wasm_sig_c_shared())));

        // The `_Out_` cell and the `char*` result, as the generated code passes them.
        let cell_r = rt_inst.get_typed_func::<f64, u32>(&mut store, "rt_f77_cell_r").unwrap();
        let cell_get_r = rt_inst.get_typed_func::<u32, f64>(&mut store, "rt_f77_cell_get_r").unwrap();
        let ints_in = alloc.call(&mut store, 8).unwrap();
        let ints_out = alloc.call(&mut store, 8).unwrap();
        memory.write(&mut store, ints_in as usize, &[7, 0, 0, 0, 9, 0, 0, 0]).unwrap();
        let y = cell_r.call(&mut store, 0.0).unwrap();
        let f = loaded.func("xorshift").unwrap().clone().typed::<(i32, i32, i32), ()>(&store).unwrap();
        f.call(&mut store, (ints_in as i32, ints_out as i32, y as i32)).unwrap();
        let mut out = [0u8; 8];
        memory.read(&store, ints_out as usize, &mut out).unwrap();
        assert_eq!(out, [8, 0, 0, 0, 9, 0, 0, 0]);
        assert_eq!(cell_get_r.call(&mut store, y).unwrap(), 0.5);

        let from_cstr = rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_str_from_cstr").unwrap();
        let str_len = rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_str_len").unwrap();
        let str_data = rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_str_data").unwrap();
        let cstr = alloc.call(&mut store, 6).unwrap();
        memory.write(&mut store, cstr as usize, b"hello\0").unwrap();
        let g = loaded.func("greet").unwrap().clone().typed::<(i32, i32), i32>(&store).unwrap();
        let ret = g.call(&mut store, (cstr as i32, 1)).unwrap() as u32;
        let s = from_cstr.call(&mut store, ret).unwrap();
        assert_eq!(str_len.call(&mut store, s).unwrap(), 5);
        let mut bytes = [0u8; 5];
        let data = str_data.call(&mut store, s).unwrap() as usize;
        memory.read(&store, data, &mut bytes).unwrap();
        assert_eq!(&bytes, b"hello");
        let empty = from_cstr.call(&mut store, 0).unwrap();
        assert_eq!(str_len.call(&mut store, empty).unwrap(), 0);
    }

    /// The mistake to expect, reported as such rather than as unresolved imports.
    #[test]
    fn an_object_file_is_rejected_with_a_useful_message() {
        let Some(sysroot) = option_env!("OMC_WASI_PIC_SYSROOT") else { return };
        let dir = std::env::temp_dir().join(format!("om-dylink-test-{}-obj", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let c = dir.join("obj.c");
        let o = dir.join("obj.o");
        std::fs::write(&c, "double twice(double x) { return 2*x; }").unwrap();
        let ok = std::process::Command::new("clang")
            .args(["--target=wasm32-wasip1", "-fPIC", "-c"])
            .arg(format!("--sysroot={sysroot}"))
            .arg("-o")
            .arg(&o)
            .arg(&c)
            .status()
            .map(|s| s.success())
            .unwrap_or(false);
        if !ok {
            return;
        }
        let (mut store, engine, rt_inst) = runtime();
        let memory = rt_inst.get_memory(&mut store, "memory").unwrap();
        let table = rt_inst.get_table(&mut store, "__indirect_function_table").unwrap();
        let alloc = rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_alloc").unwrap();
        let libs = [Library::model("obj.o", std::fs::read(&o).unwrap())];
        let err = match load(&mut store, &engine, memory, table, &alloc, &libs, &HashMap::new()) {
            Err(e) => e,
            Ok(_) => panic!("an object file was accepted as a library"),
        };
        assert!(err.contains("not a shared library"), "{err}");
    }
}

// ─────────────────── calling into a loaded library ───────────────────

/// The model's own `external "C"` libraries, with the PIC `libc.so` under them.
pub fn load_ext_libraries(
    store: &mut wasmtime::Store<WasiCtx>,
    engine: &wasmtime::Engine,
    rt_inst: wasmtime::Instance,
    memory: wasmtime::Memory,
    model: &SimModel,
    rt: &ExtRt,
) -> std::result::Result<Loaded, String> {
    use Library;
    let table = rt_inst
        .get_table(&mut *store, "__indirect_function_table")
        .ok_or_else(|| "CodegenWasmJit: runtime has no __indirect_function_table export".to_string())?;
    if model.ext_libs.is_empty() && !model.ext_builtin {
        return load(store, engine, memory, table, &rt.alloc, &[], &HashMap::new());
    }
    let libc = openmodelica_wasi_libc::LIBC_PIC;
    if libc.is_empty() {
        return Err("CodegenWasmJit: this omc was built without the PIC wasi-libc, so it cannot \
                    load an external \"C\" library"
            .to_string());
    }
    let mut libs = Vec::with_capacity(model.ext_libs.len() + 3);
    libs.push(Library::builtin("libc.so", libc));
    for l in &model.ext_libs {
        libs.push(Library::ext(l));
    }
    // After the model's own libraries, so those still define a symbol they share.
    // Binding an `external "C"` here makes the call wasm->wasm; the dlopen
    // fallback costs a host trampoline and libffi marshalling per call.
    if model.ext_builtin {
        libs.push(Library::builtin("modelicaexternalc", openmodelica_wasi_libc::EXTERNAL_C_DYLINK));
        // The dummy `usertab` ModelicaExternalC imports; last, so a `usertab` from
        // the model's own libraries wins.
        if !openmodelica_wasi_libc::USERTAB_DYLINK.is_empty() {
            libs.push(Library::builtin("usertab", openmodelica_wasi_libc::USERTAB_DYLINK));
        }
    }
    let host = modelica_utilities_imports(store, rt);
    load(store, engine, memory, table, &rt.alloc, &libs, &host)
}

fn shared_cstr(caller: &mut wasmtime::Caller<'_, WasiCtx>, ptr: i32) -> String {
    let Some(memory) = crate::host::get_sim_memory() else { return String::new() };
    let data = memory.data(&*caller);
    let p = ptr as usize;
    let Some(rest) = data.get(p..) else { return String::new() };
    let len = rest.iter().position(|&b| b == 0).unwrap_or(0);
    String::from_utf8_lossy(&rest[..len]).into_owned()
}

/// The ModelicaUtilities a library may call: host imports, because the messages
/// belong in the run's log (or, outside a run, in omc's error buffer). A formatted
/// variant gets `(format, va_list)` and is not interpolated, as on the web target.
pub fn modelica_utilities_imports(
    store: &mut wasmtime::Store<WasiCtx>,
    rt: &ExtRt,
) -> HashMap<String, wasmtime::Func> {
    use wasmtime::{Caller, Func};
    use openmodelica_sim_meta::omclog;
    let mut m: HashMap<String, Func> = HashMap::new();

    let nls = rt.nls.clone();
    let err_fn = |store: &mut wasmtime::Store<WasiCtx>, nls: Option<NlsHooks>| Func::wrap(
        store,
        move |mut caller: Caller<'_, WasiCtx>, ptr: i32| -> std::result::Result<(), wasmtime::Error> {
            raise_model_error(&nls, &mut caller, ptr)
        },
    );
    let err_fmt_fn = |store: &mut wasmtime::Store<WasiCtx>, nls: Option<NlsHooks>| Func::wrap(
        store,
        move |mut caller: Caller<'_, WasiCtx>, fmt: i32, _va: i32| -> std::result::Result<(), wasmtime::Error> {
            raise_model_error(&nls, &mut caller, fmt)
        },
    );
    // C sends both to `OMC_LOG_STDOUT`. The `-d=gen` function JIT has no run and no
    // such log, and neither does the compiler process in C.
    let in_run = rt.nls.is_some();
    let warning = move |mut caller: Caller<'_, WasiCtx>, ptr: i32| {
        let msg = shared_cstr(&mut caller, ptr);
        if in_run {
            omclog::warning(omclog::STDOUT, false, &msg);
        } else {
            openmodelica_error::ErrorExt::runtime_warning(&msg);
        }
    };
    let warning_fmt = move |mut caller: Caller<'_, WasiCtx>, fmt: i32, _va: i32| {
        let msg = shared_cstr(&mut caller, fmt);
        if in_run {
            omclog::warning(omclog::STDOUT, false, &msg);
        } else {
            openmodelica_error::ErrorExt::runtime_warning(&msg);
        }
    };

    let message = move |mut caller: Caller<'_, WasiCtx>, ptr: i32| {
        if in_run {
            let msg = shared_cstr(&mut caller, ptr);
            omclog::info(omclog::STDOUT, false, &msg);
        }
    };
    let message_fmt = move |mut caller: Caller<'_, WasiCtx>, fmt: i32, _va: i32| {
        if in_run {
            let msg = shared_cstr(&mut caller, fmt);
            omclog::info(omclog::STDOUT, false, &msg);
        }
    };

    m.insert("ModelicaError".into(), err_fn(&mut *store, nls.clone()));
    m.insert("ModelicaFormatError".into(), err_fmt_fn(&mut *store, nls.clone()));
    m.insert("ModelicaVFormatError".into(), err_fmt_fn(&mut *store, nls.clone()));
    m.insert("ModelicaWarning".into(), Func::wrap(&mut *store, warning));
    m.insert("ModelicaFormatWarning".into(), Func::wrap(&mut *store, warning_fmt));
    m.insert("ModelicaVFormatWarning".into(), Func::wrap(&mut *store, warning_fmt));
    m.insert("ModelicaMessage".into(), Func::wrap(&mut *store, message));
    m.insert("ModelicaFormatMessage".into(), Func::wrap(&mut *store, message_fmt));
    m.insert("ModelicaVFormatMessage".into(), Func::wrap(&mut *store, message_fmt));

    // A side module carrying `external_c_callbacks.c` has the `Modelica*` entry
    // points itself, so what arrives here is already through `vsnprintf`.
    m.insert("rt_ext_error".into(), err_fn(&mut *store, nls));
    m.insert("rt_ext_message".into(), Func::wrap(&mut *store, message));
    m.insert("rt_ext_warning".into(), Func::wrap(&mut *store, warning));

    // The simulation's allocator, so a string the callee builds is readable from
    // the model's memory.
    let alloc = rt.alloc.clone();
    let allocate = move |mut caller: Caller<'_, WasiCtx>, len: i32| -> std::result::Result<i32, wasmtime::Error> {
        let n = len.max(0) as u32 + 1;
        let p = alloc.call(&mut caller, n)?;
        if let Some(memory) = crate::host::get_sim_memory() {
            memory.data_mut(&mut caller)[p as usize..(p + n) as usize].fill(0);
        }
        Ok(p as i32)
    };
    let allocate2 = allocate.clone();
    m.insert("ModelicaAllocateString".into(), Func::wrap(&mut *store, allocate));
    m.insert("ModelicaAllocateStringWithErrorReturn".into(), Func::wrap(&mut *store, allocate2));
    m
}

/// The runtime entry points an external "C" call needs.
#[derive(Clone)]
pub struct ExtRt {
    pub str_new: wasmtime::TypedFunc<u32, u32>,
    pub str_data: wasmtime::TypedFunc<u32, u32>,
    pub release: wasmtime::TypedFunc<u32, ()>,
    pub alloc: wasmtime::TypedFunc<u32, u32>,
    pub free: wasmtime::TypedFunc<u32, ()>,
    pub record_new: wasmtime::TypedFunc<(u32, u32), u32>,
    /// A run's solver state; the `-d=gen` function JIT has no solver.
    pub nls: Option<NlsHooks>,
}

/// The runtime's recoverable-model-error state, reached from the host so an
/// external "C" `ModelicaError` inside a residual backs the trial off.
#[derive(Clone)]
pub struct NlsHooks {
    pub recovering: wasmtime::TypedFunc<(), i32>,
    pub note: wasmtime::TypedFunc<(), ()>,
}

impl NlsHooks {
    pub fn recovering(&self, caller: &mut wasmtime::Caller<'_, WasiCtx>) -> std::result::Result<bool, wasmtime::Error> {
        Ok(self.recovering.call(&mut *caller, ())? != 0)
    }
    pub fn note(&self, caller: &mut wasmtime::Caller<'_, WasiCtx>) -> std::result::Result<(), wasmtime::Error> {
        self.note.call(&mut *caller, ())
    }
}

/// End the call the way C's `throwStreamPrint` does: with the model's
/// `model_error` tag, which the `ext` call site catches — inside a residual to
/// reject the trial, outside one to end the run (so only then is the message
/// worth reporting). With no tag registered (the `-d=gen` function JIT, whose
/// module has no solver to recover into) it stays a trap.
pub fn raise_model_error(
    nls: &Option<NlsHooks>,
    caller: &mut wasmtime::Caller<'_, WasiCtx>,
    ptr: i32,
) -> std::result::Result<(), wasmtime::Error> {
    let recovering = match nls {
        Some(nls) => nls.recovering(caller)?,
        None => false,
    };
    if !recovering {
        let msg = shared_cstr(caller, ptr);
        // A run reports itself through its log alone, as C's separate executable
        // does; the function JIT has no log and answers through the Error buffer.
        match nls {
            Some(_) => crate::sim_driver::note_runtime_error(&msg),
            None => openmodelica_error::ErrorExt::runtime_error(&msg),
        }
    }
    match crate::host::model_error_exception(caller)? {
        Some(exn) => {
            use wasmtime::AsContextMut;
            caller.as_context_mut().throw::<()>(exn).map_err(wasmtime::Error::new)
        }
        None => Err(wasmtime::Error::msg(format!("ModelicaError: {}", shared_cstr(caller, ptr)))),
    }
}

/// Zeroed results (an empty String for `char*`) after a recovered `ModelicaError`.
/// The solver discards the residual they feed, but they must be valid handles.
pub fn zero_results(
    sig: &crate::sig::ExtCallSig,
    caller: &mut wasmtime::Caller<'_, WasiCtx>,
    rt_str_new: &wasmtime::TypedFunc<u32, u32>,
    rets: &mut [wasmtime::Val],
) -> std::result::Result<(), wasmtime::Error> {
    use crate::sig::SigTy;
    for (slot, ty) in rets.iter_mut().zip(sig.wasm_results()) {
        *slot = match ty {
            SigTy::Real => wasmtime::Val::F64(0.0f64.to_bits()),
            SigTy::Str => wasmtime::Val::I32(rt_str_new.call(&mut *caller, 0)? as i32),
            _ => wasmtime::Val::I32(0),
        };
    }
    Ok(())
}

/// Whether the import is already exactly the C function, so the engine can call it
/// wasm→wasm. `Ptr` qualifies: with shared memory it is a real address.
fn is_direct_call(sig: &crate::sig::ExtCallSig) -> bool {
    use crate::sig::SigTy;
    fn scalar(t: &SigTy) -> bool {
        matches!(t, SigTy::Int | SigTy::Real | SigTy::Bool | SigTy::Ptr)
    }
    sig.lang == crate::sig::ExtLang::C
        && sig.args.iter().all(|(t, is_out)| !*is_out && scalar(t))
        && sig.ret.as_ref().is_none_or(scalar)
}

/// Bind `ext.<name>` to a library export. An array argument is passed as the
/// address of the model's own elements — no copy either way; only a String
/// (length-prefixed, not NUL-terminated) and an `_Out_` cell need scratch.
///
/// `None` when the library's function has the wrong wasm type.
pub fn bind_in_wasm_external(
    store: &mut wasmtime::Store<WasiCtx>,
    sig: &crate::sig::ExtCallSig,
    functype: &wasmtime::FuncType,
    target: wasmtime::Func,
    rt: &ExtRt,
) -> Result<Option<wasmtime::Extern>> {
    if is_direct_call(sig) {
        let same = {
            let ty = target.ty(&*store);
            ty.params().len() == functype.params().len()
                && ty.results().len() == functype.results().len()
                && ty.params().zip(functype.params()).all(|(a, b)| a.matches(&b))
                && ty.results().zip(functype.results()).all(|(a, b)| a.matches(&b))
        };
        return Ok(same.then_some(wasmtime::Extern::Func(target)));
    }
    let sig = sig.clone();
    let rt = rt.clone();
    let f = wasmtime::Func::new(&mut *store, functype.clone(), move |mut caller, args, rets| {
        let mut thrown = None;
        let r = call_external_in_wasm(&sig, &rt, &target, &mut caller, args, rets, &mut thrown);
        match thrown {
            Some(e) => Err(e),
            None => r.map_err(|e| wasmtime::Error::msg(format!("external \"C\" `{}`: {e}", sig.name))),
        }
    });
    Ok(Some(wasmtime::Extern::Func(f)))
}

/// Call `target` with the C argument list its prototype expects, then hand the
/// results back as the import's wasm results.
fn call_external_in_wasm(
    sig: &crate::sig::ExtCallSig,
    rt: &ExtRt,
    target: &wasmtime::Func,
    caller: &mut wasmtime::Caller<'_, WasiCtx>,
    args: &[wasmtime::Val],
    rets: &mut [wasmtime::Val],
    thrown: &mut Option<wasmtime::Error>,
) -> Result<()> {
    use crate::sig::SigTy;
    use wasmtime::Val;

    let memory = crate::host::get_sim_memory().ok_or_else(|| "external \"C\": the run has no shared memory".to_string())?;
    let fortran = sig.lang == crate::sig::ExtLang::Fortran77;
    let mut call_args: Vec<Val> = Vec::with_capacity(sig.args.len());
    let mut temps: Vec<u32> = Vec::new();
    // (output type, scratch address), in the order the import returns them.
    let mut out_cells: Vec<(SigTy, u32)> = Vec::new();
    // Column-major copies a FORTRAN 77 callee gets instead of the array itself:
    // (scratch, element area, dims, element size, is output).
    let mut f77_arrays: Vec<(u32, u32, Vec<usize>, usize, bool)> = Vec::new();
    // Output `String[…]`: (`char**` scratch, element area, element count).
    let mut str_out_arrays: Vec<(u32, u32, usize)> = Vec::new();

    let alloc = |caller: &mut wasmtime::Caller<'_, WasiCtx>, n: u32| -> Result<u32> {
        rt.alloc.call(&mut *caller, n).map_err(|e| format!("rt_alloc: {e}"))
    };

    // A returned struct comes back through an `sret` pointer ahead of every declared
    // argument (`struct ADD f(double)` → `(i32, f64) -> ()`).
    let sret = match sig.ret.as_ref().map(|t| (t, abi_of(t))) {
        Some((SigTy::Record { fields, .. }, Abi::Indirect)) => {
            let cell = alloc(caller, c_record_layout(fields).size.max(1))?;
            memory.data_mut(&mut *caller)[cell as usize..cell as usize + c_record_layout(fields).size as usize].fill(0);
            temps.push(cell);
            call_args.push(Val::I32(cell as i32));
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
                Abi::Scalar(s) => {
                    if *is_out {
                        return Err("external \"C\": a single-member record cannot be an output".to_string());
                    }
                    let handle = v.map(|v| v.unwrap_i32()).unwrap_or(0) as u32;
                    let (off, leaf) = record_leaf(fields);
                    call_args.push(match leaf {
                        SigTy::Real => Val::F64(read_u64(memory, caller, handle + off)),
                        _ => Val::I32(read_u32(memory, caller, handle + off) as i32),
                    });
                    let _ = s;
                }
                Abi::Indirect => {
                    let c = c_record_layout(fields);
                    let cell = alloc(caller, c.size.max(1))?;
                    memory.data_mut(&mut *caller)[cell as usize..cell as usize + c.size as usize].fill(0);
                    if let Some(v) = v {
                        record_to_c(caller, memory, rt, fields, v.unwrap_i32() as u32, cell, &mut temps)?;
                    }
                    temps.push(cell);
                    if *is_out {
                        out_cells.push((ty.clone(), cell));
                    }
                    call_args.push(Val::I32(cell as i32));
                }
            }
            continue;
        }
        // An `_Out_` scalar/string is written through a pointer; an output array is
        // filled in place, so it goes through the `Array` arm like an input.
        if *is_out && !matches!(ty, SigTy::Array { .. }) {
            let cell = alloc(caller, 8)?;
            memory.data_mut(&mut *caller)[cell as usize..cell as usize + 8].fill(0);
            temps.push(cell);
            out_cells.push((ty.clone(), cell));
            call_args.push(Val::I32(cell as i32));
            continue;
        }
        let v = args.get(in_i).ok_or_else(|| {
            "external \"C\": the call passes fewer arguments than the signature declares".to_string()
        })?;
        in_i += 1;
        if fortran && matches!(ty, SigTy::Real | SigTy::Int | SigTy::Bool) {
            let cell = alloc(caller, 8)?;
            let raw = match ty {
                SigTy::Real => v.unwrap_f64().to_le_bytes(),
                _ => {
                    let mut b = [0u8; 8];
                    b[..4].copy_from_slice(&v.unwrap_i32().to_le_bytes());
                    b
                }
            };
            memory.data_mut(&mut *caller)[cell as usize..cell as usize + 8].copy_from_slice(&raw);
            temps.push(cell);
            call_args.push(Val::I32(cell as i32));
            continue;
        }
        match ty {
            SigTy::Real => call_args.push(Val::F64(v.unwrap_f64().to_bits())),
            SigTy::Int | SigTy::Bool | SigTy::Ptr => call_args.push(Val::I32(v.unwrap_i32())),
            SigTy::Str => {
                // `char*`: the same bytes, NUL-terminated.
                let off = v.unwrap_i32() as u32 as usize;
                let data = memory.data(&*caller);
                let len = u32::from_le_bytes(
                    data.get(off + 4..off + 8).ok_or_else(|| "external \"C\": malformed String argument".to_string())?.try_into().unwrap(),
                ) as usize;
                let cell = alloc(caller, (len + 1) as u32)?;
                let mem = memory.data_mut(&mut *caller);
                mem.copy_within(off + 8..off + 8 + len, cell as usize);
                mem[cell as usize + len] = 0;
                temps.push(cell);
                call_args.push(Val::I32(cell as i32));
            }
            SigTy::Array { elem, .. } => {
                let off = v.unwrap_i32() as u32 as usize;
                let (dims, data_off) = crate::host::array_abi::dims_and_data(memory.data(&*caller), off)
                    .ok_or_else(|| "external \"C\": malformed array argument".to_string())?;
                let base = (off + data_off) as u32;
                // Handles, not the `const char**` C declares: rebuilt as a vector of
                // NUL-terminated copies (C's `data_of_string_c89_array`).
                if let SigTy::Str = &**elem {
                    let n = dims.iter().product::<usize>();
                    let vec_cell = alloc(caller, (n * 4).max(1) as u32)?;
                    temps.push(vec_cell);
                    for k in 0..n {
                        let h = read_u32(memory, caller, base + (k * 4) as u32);
                        let len = if h == 0 { 0 } else { read_u32(memory, caller, h + 4) as usize };
                        let cell = alloc(caller, (len + 1) as u32)?;
                        temps.push(cell);
                        let mem = memory.data_mut(&mut *caller);
                        mem.copy_within(h as usize + 8..h as usize + 8 + len, cell as usize);
                        mem[cell as usize + len] = 0;
                        let slot = vec_cell as usize + k * 4;
                        mem[slot..slot + 4].copy_from_slice(&cell.to_le_bytes());
                    }
                    call_args.push(Val::I32(vec_cell as i32));
                    if *is_out {
                        str_out_arrays.push((vec_cell, base, n));
                    }
                    continue;
                }
                if fortran && dims.len() > 1 {
                    // C's `convert_alloc_*_to_f77`.
                    let esz = crate::host::array_abi::elem_size(elem);
                    let n = dims.iter().product::<usize>() * esz;
                    let cell = alloc(caller, n as u32)?;
                    let mut buf = vec![0u8; n];
                    let mem = memory.data_mut(&mut *caller);
                    crate::host::array_abi::reorder(&mem[base as usize..base as usize + n], &mut buf, &dims, esz, true);
                    mem[cell as usize..cell as usize + n].copy_from_slice(&buf);
                    temps.push(cell);
                    call_args.push(Val::I32(cell as i32));
                    f77_arrays.push((cell, base, dims, esz, *is_out));
                } else {
                    call_args.push(Val::I32(base as i32));
                }
            }
            _ => return Err("external \"C\": input argument type not marshalled".to_string()),
        }
    }

    // A struct return goes through `sret`, so the call itself yields nothing.
    let returns_value = match sig.ret.as_ref().map(abi_of) {
        None | Some(Abi::Dropped) | Some(Abi::Indirect) => false,
        Some(Abi::Scalar(_)) => true,
    };
    let mut raw_ret = [Val::I32(0)];
    let ret_slice = if returns_value { &mut raw_ret[..] } else { &mut raw_ret[..0] };
    if let Err(e) = target.call(&mut *caller, &call_args, ret_slice) {
        // A `model_error` on its way to the model's `try_table` passes straight
        // through: rewritten, the store's pending exception would never land.
        if e.downcast_ref::<wasmtime::ThrownException>().is_some() {
            *thrown = Some(e);
            return Ok(());
        }
        // `{e:?}`: whatever ended the call is the trap's cause.
        return Err(format!("{e:?}"));
    }

    // C's `convert_alloc_*_from_f77`.
    for (cell, base, dims, esz, is_out) in &f77_arrays {
        if !*is_out {
            continue;
        }
        let n = dims.iter().product::<usize>() * esz;
        let mem = memory.data_mut(&mut *caller);
        let mut buf = vec![0u8; n];
        crate::host::array_abi::reorder(&mem[*cell as usize..*cell as usize + n], &mut buf, dims, *esz, false);
        mem[*base as usize..*base as usize + n].copy_from_slice(&buf);
    }

    // C's `unpack_string_array`; an element the callee did not write still points
    // at our own input copy.
    for (vec_cell, base, n) in &str_out_arrays {
        for k in 0..*n {
            let ptr = read_u32(memory, caller, vec_cell + (k * 4) as u32) as usize;
            let len = str_len(memory, caller, ptr)?;
            let handle = rt.str_new.call(&mut *caller, len as u32).map_err(|e| format!("{e}"))?;
            let dst = rt.str_data.call(&mut *caller, handle).map_err(|e| format!("{e}"))? as usize;
            let slot = *base as usize + k * 4;
            let old = {
                let mem = memory.data_mut(&mut *caller);
                mem.copy_within(ptr..ptr + len, dst);
                let old = u32::from_le_bytes(mem[slot..slot + 4].try_into().unwrap());
                mem[slot..slot + 4].copy_from_slice(&handle.to_le_bytes());
                old
            };
            if old != 0 {
                rt.release.call(&mut *caller, old).map_err(|e| format!("{e}"))?;
            }
        }
    }

    let mut result = Vec::with_capacity(rets.len());
    if let Some(ret_ty) = &sig.ret {
        match (ret_ty, abi_of(ret_ty)) {

            (SigTy::Record { fields, .. }, Abi::Indirect | Abi::Dropped) => {
                let handle = record_from_c(caller, memory, rt, fields, sret.unwrap_or(0))?;
                result.push(Val::I32(handle as i32));
            }

            (SigTy::Record { fields, .. }, Abi::Scalar(leaf)) => {
                let (off, _) = record_leaf(fields);
                let handle = record_from_scalar(caller, memory, rt, fields, off, &leaf, &raw_ret[0])?;
                result.push(Val::I32(handle as i32));
            }
            _ => {
                let raw = match ret_ty {
                    SigTy::Real => raw_ret[0].unwrap_f64().to_le_bytes(),
                    _ => {
                        let mut b = [0u8; 8];
                        b[..4].copy_from_slice(&raw_ret[0].unwrap_i32().to_le_bytes());
                        b
                    }
                };
                result.push(ext_result(ret_ty, raw, rt, caller, memory)?);
            }
        }
    }
    for (ty, cell) in &out_cells {
        if let SigTy::Record { fields, .. } = ty {
            let handle = record_from_c(caller, memory, rt, fields, *cell)?;
            result.push(Val::I32(handle as i32));
            continue;
        }
        let mut raw = [0u8; 8];
        raw.copy_from_slice(&memory.data(&*caller)[*cell as usize..*cell as usize + 8]);
        result.push(ext_result(ty, raw, rt, caller, memory)?);
    }
    for (slot, v) in rets.iter_mut().zip(result) {
        *slot = v;
    }
    for t in temps {
        let _ = rt.free.call(&mut *caller, t);
    }
    Ok(())
}

/// The 8 raw bytes the C side produced, as the wasm value the import declares. A
/// `char*` becomes a fresh String: the callee's buffer is its own to reuse.

fn ext_result(
    ty: &crate::sig::SigTy,
    raw: [u8; 8],
    rt: &ExtRt,
    caller: &mut wasmtime::Caller<'_, WasiCtx>,
    memory: wasmtime::Memory,
) -> Result<wasmtime::Val> {
    use crate::sig::SigTy;
    use wasmtime::Val;
    Ok(match ty {
        SigTy::Real => Val::F64(f64::from_le_bytes(raw).to_bits()),
        SigTy::Int | SigTy::Bool | SigTy::Ptr => Val::I32(i32::from_le_bytes(raw[..4].try_into().unwrap())),
        SigTy::Str => {
            let ptr = u32::from_le_bytes(raw[..4].try_into().unwrap()) as usize;
            let len = str_len(memory, caller, ptr)?;
            let handle = rt.str_new.call(&mut *caller, len as u32).map_err(|e| format!("{e}"))?;
            let dst = rt.str_data.call(&mut *caller, handle).map_err(|e| format!("{e}"))? as usize;
            memory.data_mut(&mut *caller).copy_within(ptr..ptr + len, dst);
            Val::I32(handle as i32)
        }
        _ => return Err("external \"C\": result type not marshalled".to_string()),
    })
}


// ─────────────────── records across the C boundary ───────────────────

/// The C struct the callee declares, in the side module's wasm32 ABI.
fn c_record_layout(fields: &[(arcstr::ArcStr, crate::sig::SigTy)]) -> crate::sig::CRecordLayout {
    crate::sig::c_record_layout(fields, 4)
}

/// How the wasm C ABI passes a value.
enum Abi {
    /// No members: no argument, no result.
    Dropped,
    /// A struct with exactly one member passes and returns as that member,
    /// recursively: clang lowers `struct One { double x; } f(double)` to
    /// `(f64) -> f64`.
    Scalar(crate::sig::SigTy),
    /// By pointer; a return value gets a prepended `sret` pointer.
    Indirect,
}

fn abi_of(t: &crate::sig::SigTy) -> Abi {
    use crate::sig::SigTy;
    match t {
        SigTy::Record { fields, .. } => match fields.len() {
            0 => Abi::Dropped,
            1 => abi_of(&fields[0].1),
            _ => Abi::Indirect,
        },
        other => Abi::Scalar(other.clone()),
    }
}

/// The member a single-member struct collapses to, as `(offset from the record
/// object's base, type)`. Descends nested single-member records.
fn record_leaf(fields: &[(arcstr::ArcStr, crate::sig::SigTy)]) -> (u32, crate::sig::SigTy) {
    use crate::sig::SigTy;
    let layout = crate::sig::record_layout(fields);
    let off = layout.data_off + layout.field_off.first().copied().unwrap_or(0);
    match fields.first().map(|(_, t)| t) {
        Some(SigTy::Record { fields: inner, .. }) if inner.len() == 1 => {
            // The member is itself a record *object*, so its own base is stored here.
            let (inner_off, ty) = record_leaf(inner);
            (off + inner_off, ty)
        }
        Some(t) => (off, t.clone()),
        None => (off, SigTy::Int),
    }
}

/// Rebuild a single-member record from the scalar the ABI returned in place of it.
fn record_from_scalar(
    caller: &mut wasmtime::Caller<'_, WasiCtx>,
    memory: wasmtime::Memory,
    rt: &ExtRt,
    fields: &[(arcstr::ArcStr, crate::sig::SigTy)],
    leaf_off: u32,
    leaf: &crate::sig::SigTy,
    value: &wasmtime::Val,
) -> Result<u32> {
    use crate::sig::SigTy;
    let layout = crate::sig::record_layout(fields);
    let handle = rt
        .record_new
        .call(&mut *caller, (layout.heap.len() as u32, layout.size))
        .map_err(|e| format!("rt_record_new: {e}"))?;
    for (k, (kind, off)) in layout.heap.iter().enumerate() {
        write_u32(memory, caller, handle + 8 + k as u32 * 8, *kind);
        write_u32(memory, caller, handle + 8 + k as u32 * 8 + 4, *off);
    }
    // A nested one needs its own object before the value can go in.
    if let Some((_, SigTy::Record { fields: inner, .. })) = fields.first()
        && inner.len() == 1
    {
        let nested = record_from_scalar(caller, memory, rt, inner, leaf_off, leaf, value)?;
        write_u32(memory, caller, handle + layout.data_off + layout.field_off[0], nested);
        return Ok(handle);
    }
    let at = handle + layout.data_off + layout.field_off.first().copied().unwrap_or(0);
    match leaf {
        SigTy::Real => write_u64(memory, caller, at, value.unwrap_f64().to_bits()),
        SigTy::Str => {
            let s = wasm_string(caller, memory, rt, value.unwrap_i32() as u32)?;
            write_u32(memory, caller, at, s);
        }
        _ => write_u32(memory, caller, at, value.unwrap_i32() as u32),
    }
    Ok(handle)
}

/// Write the record object `handle` into the C struct at `dst`; `temps` collects
/// scratch to release after.
fn record_to_c(
    caller: &mut wasmtime::Caller<'_, WasiCtx>,
    memory: wasmtime::Memory,
    rt: &ExtRt,
    fields: &[(arcstr::ArcStr, crate::sig::SigTy)],
    handle: u32,
    dst: u32,
    temps: &mut Vec<u32>,
) -> Result<()> {
    use crate::sig::SigTy;
    let layout = crate::sig::record_layout(fields);
    let c = c_record_layout(fields);
    for (i, (_, ty)) in fields.iter().enumerate() {
        let src = handle + layout.data_off + layout.field_off[i];
        let at = dst + c.offsets[i];
        match ty {
            SigTy::Real => {
                let v = read_u64(memory, caller, src);
                write_u64(memory, caller, at, v);
            }
            SigTy::Int | SigTy::Bool | SigTy::Ptr => {
                let v = read_u32(memory, caller, src);
                write_u32(memory, caller, at, v);
            }
            SigTy::Str => {
                let s = read_u32(memory, caller, src);
                let p = c_string(caller, memory, rt, s, temps)?;
                write_u32(memory, caller, at, p);
            }
            SigTy::Array { .. } => {
                // The elements themselves, so the callee writes the model's array.
                let h = read_u32(memory, caller, src) as usize;
                let (_, data_off) = crate::host::array_abi::dims_and_data(memory.data(&*caller), h)
                    .ok_or_else(|| "external \"C\": malformed array field".to_string())?;
                write_u32(memory, caller, at, h as u32 + data_off as u32);
            }
            SigTy::Record { fields: inner, .. } => {
                let h = read_u32(memory, caller, src);
                record_to_c(caller, memory, rt, inner, h, at, temps)?;
            }
            _ => return Err("external \"C\": record field type not marshalled".to_string()),
        }
    }
    Ok(())
}

/// The inverse of [`record_to_c`], for an `_Out_` record or a returned struct.
fn record_from_c(
    caller: &mut wasmtime::Caller<'_, WasiCtx>,
    memory: wasmtime::Memory,
    rt: &ExtRt,
    fields: &[(arcstr::ArcStr, crate::sig::SigTy)],
    src: u32,
) -> Result<u32> {
    use crate::sig::SigTy;
    let layout = crate::sig::record_layout(fields);
    let c = c_record_layout(fields);
    let handle = rt
        .record_new
        .call(&mut *caller, (layout.heap.len() as u32, layout.size))
        .map_err(|e| format!("rt_record_new: {e}"))?;
    // The inline table the runtime releases the record's heap fields by.
    for (k, (kind, off)) in layout.heap.iter().enumerate() {
        write_u32(memory, caller, handle + 8 + k as u32 * 8, *kind);
        write_u32(memory, caller, handle + 8 + k as u32 * 8 + 4, *off);
    }
    for (i, (_, ty)) in fields.iter().enumerate() {
        let at = src + c.offsets[i];
        let dst = handle + layout.data_off + layout.field_off[i];
        match ty {
            SigTy::Real => {
                let v = read_u64(memory, caller, at);
                write_u64(memory, caller, dst, v);
            }
            SigTy::Int | SigTy::Bool | SigTy::Ptr => {
                let v = read_u32(memory, caller, at);
                write_u32(memory, caller, dst, v);
            }
            SigTy::Str => {
                let p = read_u32(memory, caller, at);
                let s = wasm_string(caller, memory, rt, p)?;
                write_u32(memory, caller, dst, s);
            }
            SigTy::Record { fields: inner, .. } => {
                let h = record_from_c(caller, memory, rt, inner, at)?;
                write_u32(memory, caller, dst, h);
            }
            _ => return Err("external \"C\": record field type not marshalled".to_string()),
        }
    }
    Ok(handle)
}

/// A NUL-terminated copy of `handle`, as a `char*`.
fn c_string(
    caller: &mut wasmtime::Caller<'_, WasiCtx>,
    memory: wasmtime::Memory,
    rt: &ExtRt,
    handle: u32,
    temps: &mut Vec<u32>,
) -> Result<u32> {
    if handle == 0 {
        return Ok(0);
    }
    let len = read_u32(memory, caller, handle + 4) as usize;
    let cell = rt
        .alloc
        .call(&mut *caller, (len + 1) as u32)
        .map_err(|e| format!("rt_alloc: {e}"))?;
    let mem = memory.data_mut(&mut *caller);
    mem.copy_within(handle as usize + 8..handle as usize + 8 + len, cell as usize);
    mem[cell as usize + len] = 0;
    temps.push(cell);
    Ok(cell)
}

/// A fresh String with the bytes of the `char*` at `ptr`.
fn wasm_string(
    caller: &mut wasmtime::Caller<'_, WasiCtx>,
    memory: wasmtime::Memory,
    rt: &ExtRt,
    ptr: u32,
) -> Result<u32> {
    let len = if ptr == 0 {
        0
    } else {
        let data = memory.data(&*caller);
        data.get(ptr as usize..)
            .and_then(|r| r.iter().position(|&b| b == 0))
            .ok_or_else(|| "external \"C\": unterminated `char*`".to_string())?
    };
    let handle = rt
        .str_new
        .call(&mut *caller, len as u32)
        .map_err(|e| format!("rt_str_new: {e}"))?;
    let dst = rt
        .str_data
        .call(&mut *caller, handle)
        .map_err(|e| format!("rt_str_data: {e}"))? as usize;
    if len > 0 {
        memory.data_mut(&mut *caller).copy_within(ptr as usize..ptr as usize + len, dst);
    }
    Ok(handle)
}

/// `strlen` of the NUL-terminated `char*` at `ptr` in the shared memory.
fn str_len(memory: wasmtime::Memory, caller: &mut wasmtime::Caller<'_, WasiCtx>, ptr: usize) -> Result<usize> {
    if ptr == 0 {
        return Ok(0);
    }
    memory.data(&*caller)[ptr..]
        .iter()
        .position(|&b| b == 0)
        .ok_or_else(|| "external \"C\": unterminated `char*`".to_string())
}

fn read_u32(memory: wasmtime::Memory, caller: &mut wasmtime::Caller<'_, WasiCtx>, at: u32) -> u32 {
    let d = memory.data(&*caller);
    d.get(at as usize..at as usize + 4)
        .map(|b| u32::from_le_bytes(b.try_into().unwrap()))
        .unwrap_or(0)
}

fn read_u64(memory: wasmtime::Memory, caller: &mut wasmtime::Caller<'_, WasiCtx>, at: u32) -> u64 {
    let d = memory.data(&*caller);
    d.get(at as usize..at as usize + 8)
        .map(|b| u64::from_le_bytes(b.try_into().unwrap()))
        .unwrap_or(0)
}

fn write_u32(memory: wasmtime::Memory, caller: &mut wasmtime::Caller<'_, WasiCtx>, at: u32, v: u32) {
    let d = memory.data_mut(&mut *caller);
    if let Some(s) = d.get_mut(at as usize..at as usize + 4) {
        s.copy_from_slice(&v.to_le_bytes());
    }
}

fn write_u64(memory: wasmtime::Memory, caller: &mut wasmtime::Caller<'_, WasiCtx>, at: u32, v: u64) {
    let d = memory.data_mut(&mut *caller);
    if let Some(s) = d.get_mut(at as usize..at as usize + 8) {
        s.copy_from_slice(&v.to_le_bytes());
    }
}
