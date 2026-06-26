// The execute half of the `wasm-jit` target: load a module produced by
// `super::translateFunctions`, JIT it with `wasmer` and call its `main`
// export, marshalling `Values.Value`s in and out. Counterpart of
// `DynLoadExt::executeFunction` for the C/dlopen target — far simpler here
// because the calling convention is just scalar wasm params/results plus the
// `.wasm.sig` sidecar, with no MMC heap to build.

use std::collections::HashMap;
use std::sync::{Arc, Mutex, OnceLock};

use anyhow::{Result, anyhow, bail};
use arcstr::ArcStr;
use metamodelica::List;

use openmodelica_ast::Absyn;
use openmodelica_frontend_types::Values;

use super::SigTy;

/// Flatten any wasmer engine/runtime error into our `anyhow` (their error types
/// — `RuntimeError`, `InstantiationError`, `ExportError`, … — do not share a
/// single anyhow-convertible type, so we format via `Debug`).
fn wt<T, E: std::fmt::Debug>(r: std::result::Result<T, E>) -> Result<T> {
    r.map_err(|e| anyhow!("{e:?}"))
}

/// The static linear-memory runtime, precompiled from
/// `openmodelica_codegen_wasm_jit_runtime` to `wasm32-unknown-unknown` (rebuild
/// with that crate's `build-runtime.sh`). Instantiated alongside every generated
/// module, which imports its `memory` and `rt_*` exports — so the allocator,
/// reference counting and string ops are shared precompiled code, not re-emitted
/// per module.
pub(super) static RUNTIME_WASM: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/runtime.wasm"));

/// Process-wide JIT cache shared across all `load_and_execute` calls.
///
/// Building a `wasmer::Engine` and (especially) compiling a module with
/// Cranelift are the expensive steps; both are independent of the call
/// arguments, so we do them once and reuse the results. Only the `Store` and
/// `Instance` are rebuilt per call — they are cheap and a fresh instance keeps
/// each evaluation isolated (no leftover globals/linear memory between calls).
///
/// Compiled modules are keyed by their wasm *bytes*, not by file name: a
/// function redefined in an interactive session is re-translated to different
/// bytes and so compiles afresh, while repeated evaluation of the same function
/// hits the cache.
struct JitCache {
    engine: wasmer::Engine,
    /// The static linear-memory runtime ([`RUNTIME_WASM`]), compiled once. A
    /// fresh instance is created per call to give each evaluation its own heap.
    runtime_module: wasmer::Module,
    modules: Mutex<HashMap<Vec<u8>, wasmer::Module>>,
}

fn jit_cache() -> &'static JitCache {
    static CACHE: OnceLock<JitCache> = OnceLock::new();
    CACHE.get_or_init(|| {
        let engine = wasmer::Engine::default();
        let runtime_module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).expect("compile wasm-jit runtime");
        JitCache { engine, runtime_module, modules: Mutex::new(HashMap::new()) }
    })
}

/// Return the compiled module for `bytes`, compiling and caching it on a miss.
///
/// Compilation runs outside the lock so that concurrent compiles of *different*
/// modules do not serialise; if two threads race to compile the *same* module
/// the first insert wins and the duplicate result is discarded (both are
/// equivalent).
fn get_or_compile_module(cache: &JitCache, bytes: &[u8]) -> Result<wasmer::Module> {
    if let Some(module) = cache.modules.lock().unwrap().get(bytes) {
        return Ok(module.clone());
    }
    let module = wt(wasmer::Module::from_binary(&cache.engine, bytes))?;
    Ok(cache
        .modules
        .lock()
        .unwrap()
        .entry(bytes.to_vec())
        .or_insert(module)
        .clone())
}

/// Parsed `.wasm.sig` sidecar: scalar types of the main function's inputs and
/// outputs.
struct Sig {
    inputs: Vec<SigTy>,
    outputs: Vec<SigTy>,
}

fn read_sig(path: &str) -> Result<Sig> {
    // Native reads the sidecar from disk; wasm reads it from the VFS where
    // `translateFunctions` staged it.
    #[cfg(target_arch = "wasm32")]
    let text = {
        let bytes = openmodelica_wasi::read(path)
            .ok_or_else(|| anyhow!("CodegenWasmJit: no such sidecar in VFS: {path}"))?;
        String::from_utf8(bytes)?
    };
    #[cfg(not(target_arch = "wasm32"))]
    let text = std::fs::read_to_string(path)?;
    let mut lines = text.lines();
    let parse = |line: Option<&str>| -> Result<Vec<SigTy>> {
        super::parse_sig_types(line.unwrap_or(""))
    };
    let inputs = parse(lines.next())?;
    let outputs = parse(lines.next())?;
    Ok(Sig { inputs, outputs })
}

/// Register the host-imported math builtins (module `"env"`) into `imports`,
/// matching `super::BUILTINS` one-for-one. wasmer host functions are bound to
/// the `Store` they are created in, so (unlike the wasmtime `Linker`) this is
/// rebuilt per instantiation rather than cached; it is cheap function-handle
/// creation with no compilation.
pub(crate) fn add_host_builtins(store: &mut Store, imports: &mut wasmer::Imports) -> Result<()> {
    use wasmer::Function;
    // The transcendental math `BUILTINS` are now provided in-wasm by the runtime
    // module (`rt_math*` exports, via libm) and imported under the `rt` namespace,
    // so they no longer cross the wasm<->host boundary. Only the effectful
    // `ENV_EXTRA` imports remain host-side here.
    // `rt_assert` (see `super::ENV_EXTRA`): record the failing assertion's message
    // and source-info handles so `load_and_execute` can route them to the error
    // buffer after the generated code traps. The handles point into the shared
    // linear memory, which is still live when `load_and_execute` reads them.
    // Registered under `rt` (not `env`): the model imports rt_assert from `rt` so
    // the standalone wasip1 export — where the merged runtime provides it — never
    // needs an `env` namespace. The runtime instance does not export rt_assert, so
    // merging it into the `rt` namespace alongside `rt_inst.exports` cannot collide.
    imports.define(
        "rt",
        "rt_assert",
        Function::new_typed(
            store,
            |msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32| {
                PENDING_ASSERT.with(|p| {
                    *p.borrow_mut() = Some(PendingAssert { msg, file, sline, scol, eline, ecol, read_only: read_only != 0 });
                });
            },
        ),
    );
    Ok(())
}

/// A failing assertion recorded by the `rt_assert` host import, to be reported by
/// [`load_and_execute`] after the wasm trap. The `msg`/`file` fields are handles
/// into the shared linear memory (read with [`read_rt_string`]).
struct PendingAssert {
    msg: i32,
    file: i32,
    sline: i32,
    scol: i32,
    eline: i32,
    ecol: i32,
    read_only: bool,
}

thread_local! {
    /// The most recent assertion recorded by `rt_assert` on this thread, consumed
    /// by [`load_and_execute`]. Single-threaded per call, so a plain cell suffices.
    static PENDING_ASSERT: std::cell::RefCell<Option<PendingAssert>> = const { std::cell::RefCell::new(None) };
}

/// Extract a numeric argument as an `f64`, accepting any scalar `Values.Value`.
fn value_as_f64(v: &Values::Value) -> Result<f64> {
    Ok(match v {
        Values::Value::REAL { real } => real.into_inner(),
        Values::Value::INTEGER { integer } => *integer as f64,
        Values::Value::BOOL { boolean } => *boolean as i64 as f64,
        Values::Value::ENUM_LITERAL { index, .. } => *index as f64,
        other => bail!("CodegenWasmJit: cannot pass {other:?} to a wasm function"),
    })
}

/// Extract a numeric argument as an `i32`, accepting any scalar `Values.Value`.
fn value_as_i32(v: &Values::Value) -> Result<i32> {
    Ok(match v {
        Values::Value::INTEGER { integer } => *integer,
        Values::Value::BOOL { boolean } => *boolean as i32,
        Values::Value::ENUM_LITERAL { index, .. } => *index,
        Values::Value::REAL { real } => real.into_inner() as i32,
        other => bail!("CodegenWasmJit: cannot pass {other:?} to a wasm function"),
    })
}

pub(super) fn load_and_execute(
    file_name: &str,
    _name: &str,
    args: &Arc<List<Arc<Values::Value>>>,
) -> Result<Arc<Values::Value>> {
    let wasm_path = format!("{file_name}.wasm");
    let sig = read_sig(&format!("{file_name}.wasm.sig"))?;
    #[cfg(target_arch = "wasm32")]
    let bytes = openmodelica_wasi::read(&wasm_path)
        .ok_or_else(|| anyhow!("CodegenWasmJit: no such module in VFS: {wasm_path}"))?;
    #[cfg(not(target_arch = "wasm32"))]
    let bytes = std::fs::read(&wasm_path)?;

    // Reuse the shared engine and the per-content compiled module. Each call
    // gets a fresh store + runtime instance (its own heap/linear memory); the
    // generated module imports the runtime's `memory` and `rt_*` exports under
    // module name "rt", plus the `env` math builtins (rebuilt per call, as
    // wasmer host functions are store-bound).
    let cache = jit_cache();
    let module = get_or_compile_module(cache, &bytes)?;
    let mut store = wasmer::Store::new(cache.engine.clone());
    let mut imports = wasmer::Imports::new();
    add_host_builtins(&mut store, &mut imports)?;
    let rt_inst = wt(wasmer::Instance::new(&mut store, &cache.runtime_module, &imports))?;
    imports.register_namespace("rt", rt_inst.exports.iter().map(|(k, v)| (k.clone(), v.clone())));
    let instance = wt(wasmer::Instance::new(&mut store, &module, &imports))?;

    // Runtime entry points needed to marshal heap values (strings, arrays) in
    // and out of the shared heap.
    let memory = rt_inst
        .exports
        .get_memory("memory")
        .map_err(|e| anyhow!("CodegenWasmJit: runtime has no `memory` export: {e:?}"))?
        .clone();
    let rt = RtFns {
        mem: memory,
        str_new: wt(rt_inst.exports.get_typed_function(&store, "rt_str_new"))?,
        str_len: wt(rt_inst.exports.get_typed_function(&store, "rt_str_len"))?,
        str_data: wt(rt_inst.exports.get_typed_function(&store, "rt_str_data"))?,
        arr_new: wt(rt_inst.exports.get_typed_function(&store, "rt_array_new"))?,
        arr_set_dim: wt(rt_inst.exports.get_typed_function(&store, "rt_array_set_dim"))?,
        arr_ndims: wt(rt_inst.exports.get_typed_function(&store, "rt_array_ndims"))?,
        arr_total: wt(rt_inst.exports.get_typed_function(&store, "rt_array_total"))?,
        arr_dim: wt(rt_inst.exports.get_typed_function(&store, "rt_array_dim"))?,
        arr_elem_ptr: wt(rt_inst.exports.get_typed_function(&store, "rt_array_elem_ptr"))?,
        rec_new: wt(rt_inst.exports.get_typed_function(&store, "rt_record_new"))?,
    };

    let func = instance
        .exports
        .get_function("main")
        .map_err(|e| anyhow!("CodegenWasmJit: module has no `main` export: {e:?}"))?
        .clone();

    // Marshal the arguments according to the input signature.
    let argv: Vec<&Arc<Values::Value>> = (&**args).into_iter().collect();
    if argv.len() != sig.inputs.len() {
        bail!("CodegenWasmJit: function expects {} arguments, got {}", sig.inputs.len(), argv.len());
    }
    let mut params: Vec<wasmer::Value> = Vec::with_capacity(argv.len());
    for (a, ty) in argv.iter().zip(sig.inputs.iter()) {
        params.push(marshal_in(&mut store, &rt, ty, a)?);
    }

    // Clear any stale pending assertion before the call (defensive — each call
    // consumes its own).
    PENDING_ASSERT.with(|p| *p.borrow_mut() = None);
    // wasmer returns the result values directly (no out-parameter buffer).
    let results = match func.call(&mut store, &params) {
        Ok(r) => r,
        Err(e) => {
            // A failed `assert` records its message + source info via the
            // `rt_assert` host import, then traps. Route it to the error buffer
            // (matching the C target's `[info] Error: <msg>`) and return
            // `META_FAIL` directly — this is an expected runtime failure, not an
            // internal error, so it should not be reported as a wasm trap on
            // stderr by `loadAndExecute`.
            if let Some(pa) = PENDING_ASSERT.with(|p| p.borrow_mut().take()) {
                report_pending_assert(&mut store, &rt, &pa)?;
                return Ok(Arc::new(Values::Value::META_FAIL));
            }
            return Err(anyhow!("{e:?}"));
        }
    };

    if results.len() != sig.outputs.len() {
        bail!("CodegenWasmJit: wasm returned {} values but signature has {}", results.len(), sig.outputs.len());
    }

    let mut out: Vec<Arc<Values::Value>> = Vec::with_capacity(results.len());
    for (val, ty) in results.iter().zip(sig.outputs.iter()) {
        out.push(Arc::new(marshal_out(&mut store, &rt, ty, val)?));
    }

    Ok(match out.len() {
        0 => Arc::new(Values::Value::NORETCALL),
        1 => out.pop().unwrap(),
        _ => Arc::new(Values::Value::TUPLE { valueLst: Arc::new(List::from_iter(out)) }),
    })
}

/// Read a runtime String (handle into the shared linear memory) into a Rust
/// `String`. Used to report a failed assertion's message after the trap (the
/// memory is still live).
fn read_rt_str(store: &mut Store, rt: &RtFns, handle: i32) -> Result<String> {
    let len = wt(rt.str_len.call(&mut *store, handle))? as usize;
    let data = wt(rt.str_data.call(&mut *store, handle))? as usize;
    let mut buf = vec![0u8; len];
    rt.mem.view(&*store).read(data as u64, &mut buf).map_err(|e| anyhow!("CodegenWasmJit: {e}"))?;
    Ok(String::from_utf8_lossy(&buf).into_owned())
}

/// Route a failed assertion's message and source info to the global error buffer
/// via `Error::addSourceMessage`, reproducing the C target's
/// `[file:l:c-l:c:writable] Error: <msg>` output. The `%s`-templated
/// `COMPILER_ERROR` message renders the assertion message verbatim at `Error`
/// severity.
fn report_pending_assert(store: &mut Store, rt: &RtFns, pa: &PendingAssert) -> Result<()> {
    use openmodelica_util::Error;
    let msg = read_rt_str(store, rt, pa.msg)?;
    let file = read_rt_str(store, rt, pa.file)?;
    let info = metamodelica::SourceInfo {
        fileName: ArcStr::from(file),
        isReadOnly: pa.read_only,
        lineNumberStart: pa.sline,
        columnNumberStart: pa.scol,
        lineNumberEnd: pa.eline,
        columnNumberEnd: pa.ecol,
        lastModification: metamodelica::OrderedFloat(0.0),
    };
    Error::addSourceMessage(Error::COMPILER_ERROR.clone(), metamodelica::cons(ArcStr::from(msg), metamodelica::nil()), info)?;
    Ok(())
}

/// The runtime entry points (and shared memory) the host needs to build/read
/// heap values. `wasmer::TypedFunction` and `Memory` are cheap handles, so this is
/// passed by reference alongside `&mut Store`.
struct RtFns {
    mem: wasmer::Memory,
    str_new: wasmer::TypedFunction<i32, i32>,
    str_len: wasmer::TypedFunction<i32, i32>,
    str_data: wasmer::TypedFunction<i32, i32>,
    arr_new: wasmer::TypedFunction<(i32, i32, i32), i32>,
    arr_set_dim: wasmer::TypedFunction<(i32, i32, i32), ()>,
    arr_ndims: wasmer::TypedFunction<i32, i32>,
    arr_total: wasmer::TypedFunction<i32, i32>,
    arr_dim: wasmer::TypedFunction<(i32, i32), i32>,
    arr_elem_ptr: wasmer::TypedFunction<(i32, i32), i32>,
    rec_new: wasmer::TypedFunction<(i32, i32), i32>,
}

type Store = wasmer::Store;

/// Build a `wasmer::Value` (scalar, or an `i32` handle into the heap) for the
/// argument value `v` of the given Modelica type. Heap values (strings, arrays)
/// are materialized in the runtime heap; the generated callee owns/consumes
/// them, so the host does not release them afterwards.
fn marshal_in(store: &mut Store, rt: &RtFns, ty: &SigTy, v: &Values::Value) -> Result<wasmer::Value> {
    Ok(match ty {
        SigTy::Real => wasmer::Value::F64(value_as_f64(v)?),
        SigTy::Int | SigTy::Bool => wasmer::Value::I32(value_as_i32(v)?),
        SigTy::Str => wasmer::Value::I32(str_to_handle(store, rt, v)?),
        SigTy::Array { elem, rank } => wasmer::Value::I32(array_to_handle(store, rt, elem, *rank, v)?),
        SigTy::Record { fields, .. } => wasmer::Value::I32(record_to_handle(store, rt, fields, v)?),
    })
}

/// Materialize a `Values.RECORD` into a fresh runtime record object, returning
/// its handle. Fields are matched to the type's components by name and written
/// at their layout offsets; the inline heap-field table is filled so the object
/// is self-describing for release/copy.
fn record_to_handle(store: &mut Store, rt: &RtFns, fields: &[(ArcStr, SigTy)], v: &Values::Value) -> Result<i32> {
    let Values::Value::RECORD { orderd, comp, .. } = v else {
        bail!("CodegenWasmJit: expected a record argument, got {v:?}");
    };
    let layout = super::record_layout(fields);
    let obj = wt(rt.rec_new.call(&mut *store, layout.heap.len() as i32, layout.size as i32))?;
    // Inline heap-field table.
    for (k, (kind, foff)) in layout.heap.iter().enumerate() {
        let base = obj as usize + 8 + k * 8;
        write_bytes(store, rt, base, &(*kind).to_le_bytes())?;
        write_bytes(store, rt, base + 4, &(*foff).to_le_bytes())?;
    }
    // Match the provided values to fields by name.
    let names: Vec<&ArcStr> = (&**comp).into_iter().collect();
    let vals: Vec<&Arc<Values::Value>> = (&**orderd).into_iter().collect();
    let by_name: std::collections::HashMap<&str, &Values::Value> =
        names.iter().zip(vals.iter()).map(|(n, v)| (n.as_str(), &***v)).collect();
    for (i, (fname, fty)) in fields.iter().enumerate() {
        let fv = by_name
            .get(fname.as_str())
            .ok_or_else(|| anyhow!("CodegenWasmJit: record argument missing field `{fname}`"))?;
        let addr = obj as usize + layout.data_off as usize + layout.field_off[i] as usize;
        write_elem(store, rt, fty, addr, fv)?;
    }
    Ok(obj)
}

/// Materialize a `Values.STRING` into a fresh runtime string, returning its handle.
fn str_to_handle(store: &mut Store, rt: &RtFns, v: &Values::Value) -> Result<i32> {
    let Values::Value::STRING { string } = v else {
        bail!("CodegenWasmJit: expected a String argument, got {v:?}");
    };
    let b = string.as_bytes();
    let h = wt(rt.str_new.call(&mut *store, b.len() as i32))?;
    let d = wt(rt.str_data.call(&mut *store, h))? as usize;
    rt.mem.view(&*store).write(d as u64, b).map_err(|e| anyhow!("CodegenWasmJit: memory write: {e}"))?;
    Ok(h)
}

/// Materialize a (nested) `Values.ARRAY` into a flat row-major runtime array of
/// `elem`/`rank`, returning its handle. The `Values.ARRAY` nests one level per
/// dimension; the leaves are flattened row-major and written into the object.
fn array_to_handle(store: &mut Store, rt: &RtFns, elem: &SigTy, rank: u32, v: &Values::Value) -> Result<i32> {
    let Values::Value::ARRAY { dimLst, .. } = v else {
        bail!("CodegenWasmJit: expected an array argument, got {v:?}");
    };
    let dims: Vec<i32> = (&**dimLst).into_iter().copied().collect();
    if dims.len() as u32 != rank {
        bail!("CodegenWasmJit: array argument has {} dimensions, expected rank {rank}", dims.len());
    }
    let total: i32 = dims.iter().product();
    let obj = wt(rt.arr_new.call(&mut *store, elem.elem_kind() as i32, rank as i32, total))?;
    for (axis, d) in dims.iter().enumerate() {
        wt(rt.arr_set_dim.call(&mut *store, obj, axis as i32, *d))?;
    }
    // Flatten the nested value into row-major scalar leaves and write each.
    let mut leaves = Vec::new();
    flatten_values(v, &mut leaves);
    if leaves.len() as i32 != total {
        bail!("CodegenWasmJit: array argument has {} elements but dimensions imply {total}", leaves.len());
    }
    for (k, leaf) in leaves.iter().enumerate() {
        let addr = wt(rt.arr_elem_ptr.call(&mut *store, obj, k as i32 + 1))? as usize;
        write_elem(store, rt, elem, addr, leaf)?;
    }
    Ok(obj)
}

/// Collect the scalar leaf values of a (possibly nested) `Values.ARRAY` in
/// row-major order.
fn flatten_values<'a>(v: &'a Values::Value, out: &mut Vec<&'a Values::Value>) {
    match v {
        Values::Value::ARRAY { valueLst, .. } => {
            for e in &**valueLst {
                flatten_values(e, out);
            }
        }
        other => out.push(other),
    }
}

/// Write one array element of type `elem` at byte address `addr`.
fn write_elem(store: &mut Store, rt: &RtFns, elem: &SigTy, addr: usize, v: &Values::Value) -> Result<()> {
    match elem {
        SigTy::Real => write_bytes(store, rt, addr, &value_as_f64(v)?.to_le_bytes())?,
        SigTy::Int | SigTy::Bool => write_bytes(store, rt, addr, &value_as_i32(v)?.to_le_bytes())?,
        SigTy::Str => {
            let h = str_to_handle(store, rt, v)?;
            write_bytes(store, rt, addr, &h.to_le_bytes())?;
        }
        SigTy::Array { elem, rank } => {
            let h = array_to_handle(store, rt, elem, *rank, v)?;
            write_bytes(store, rt, addr, &h.to_le_bytes())?;
        }
        SigTy::Record { fields, .. } => {
            let h = record_to_handle(store, rt, fields, v)?;
            write_bytes(store, rt, addr, &h.to_le_bytes())?;
        }
    }
    Ok(())
}

fn write_bytes(store: &mut Store, rt: &RtFns, addr: usize, bytes: &[u8]) -> Result<()> {
    rt.mem.view(&*store).write(addr as u64, bytes).map_err(|e| anyhow!("CodegenWasmJit: memory write: {e}"))
}

/// Build a `Values.Value` from a wasm result of the given Modelica type.
fn marshal_out(store: &mut Store, rt: &RtFns, ty: &SigTy, val: &wasmer::Value) -> Result<Values::Value> {
    Ok(match ty {
        SigTy::Int => Values::Value::INTEGER {
            integer: val.i32().ok_or_else(|| anyhow!("CodegenWasmJit: expected i32 result"))?,
        },
        SigTy::Bool => Values::Value::BOOL {
            boolean: val.i32().ok_or_else(|| anyhow!("CodegenWasmJit: expected i32 result"))? != 0,
        },
        SigTy::Real => Values::Value::REAL {
            real: metamodelica::Real::from(val.f64().ok_or_else(|| anyhow!("CodegenWasmJit: expected f64 result"))?),
        },
        SigTy::Str => {
            let h = val.i32().ok_or_else(|| anyhow!("CodegenWasmJit: expected i32 string handle result"))?;
            Values::Value::STRING { string: ArcStr::from(read_string(store, rt, h)?.as_str()) }
        }
        SigTy::Array { elem, .. } => {
            let h = val.i32().ok_or_else(|| anyhow!("CodegenWasmJit: expected i32 array handle result"))?;
            read_array(store, rt, elem, h)?
        }
        SigTy::Record { path, fields } => {
            let h = val.i32().ok_or_else(|| anyhow!("CodegenWasmJit: expected i32 record handle result"))?;
            record_to_value(store, rt, path, fields, h)?
        }
    })
}

/// Read a runtime record handle into a `Values.RECORD`, reading each field at
/// its layout offset.
fn record_to_value(store: &mut Store, rt: &RtFns, path: &ArcStr, fields: &[(ArcStr, SigTy)], h: i32) -> Result<Values::Value> {
    let layout = super::record_layout(fields);
    let mut comp = Vec::with_capacity(fields.len());
    let mut orderd = Vec::with_capacity(fields.len());
    for (i, (fname, fty)) in fields.iter().enumerate() {
        let addr = h as usize + layout.data_off as usize + layout.field_off[i] as usize;
        orderd.push(Arc::new(read_elem(store, rt, fty, addr)?));
        comp.push(fname.clone());
    }
    Ok(Values::Value::RECORD {
        record_: path_from_dotted(path),
        orderd: Arc::new(List::from_iter(orderd)),
        comp: Arc::new(List::from_iter(comp)),
        index: -1,
    })
}

/// Rebuild an `Absyn.Path` from a dotted record name (`"A.B.C"`).
fn path_from_dotted(s: &str) -> Arc<Absyn::Path> {
    let parts: Vec<&str> = s.split('.').collect();
    let mut it = parts.iter().rev();
    let last = it.next().copied().unwrap_or("");
    let mut p = Absyn::Path::IDENT { name: ArcStr::from(last) };
    for name in it {
        p = Absyn::Path::QUALIFIED { name: ArcStr::from(*name), path: Arc::new(p) };
    }
    Arc::new(p)
}

/// Read a runtime string handle's bytes into a `String`.
fn read_string(store: &mut Store, rt: &RtFns, h: i32) -> Result<String> {
    let len = wt(rt.str_len.call(&mut *store, h))? as usize;
    let d = wt(rt.str_data.call(&mut *store, h))? as usize;
    let mut buf = vec![0u8; len];
    rt.mem.view(&*store).read(d as u64, &mut buf).map_err(|e| anyhow!("CodegenWasmJit: memory read: {e}"))?;
    String::from_utf8(buf).map_err(|e| anyhow!("CodegenWasmJit: non-utf8 result string: {e}"))
}

/// Read a runtime array handle into a (nested) `Values.ARRAY` of element type
/// `elem`. The flat row-major elements are folded into the nested
/// dimension-by-dimension structure the rest of the compiler uses.
fn read_array(store: &mut Store, rt: &RtFns, elem: &SigTy, h: i32) -> Result<Values::Value> {
    let ndims = wt(rt.arr_ndims.call(&mut *store, h))?;
    let total = wt(rt.arr_total.call(&mut *store, h))?;
    let mut dims = Vec::with_capacity(ndims as usize);
    for axis in 1..=ndims {
        dims.push(wt(rt.arr_dim.call(&mut *store, h, axis))?);
    }
    // Read every scalar leaf row-major.
    let mut flat = Vec::with_capacity(total as usize);
    for k in 0..total {
        let addr = wt(rt.arr_elem_ptr.call(&mut *store, h, k + 1))? as usize;
        flat.push(read_elem(store, rt, elem, addr)?);
    }
    Ok(nest_values(&dims, &flat))
}

/// Read one array element of type `elem` at byte address `addr`.
fn read_elem(store: &mut Store, rt: &RtFns, elem: &SigTy, addr: usize) -> Result<Values::Value> {
    Ok(match elem {
        SigTy::Real => Values::Value::REAL { real: metamodelica::Real::from(f64::from_le_bytes(read_bytes::<8>(store, rt, addr)?)) },
        SigTy::Int => Values::Value::INTEGER { integer: i32::from_le_bytes(read_bytes::<4>(store, rt, addr)?) },
        SigTy::Bool => Values::Value::BOOL { boolean: i32::from_le_bytes(read_bytes::<4>(store, rt, addr)?) != 0 },
        SigTy::Str => {
            let h = i32::from_le_bytes(read_bytes::<4>(store, rt, addr)?);
            Values::Value::STRING { string: ArcStr::from(read_string(store, rt, h)?.as_str()) }
        }
        SigTy::Array { elem, .. } => {
            let h = i32::from_le_bytes(read_bytes::<4>(store, rt, addr)?);
            read_array(store, rt, elem, h)?
        }
        SigTy::Record { path, fields } => {
            let h = i32::from_le_bytes(read_bytes::<4>(store, rt, addr)?);
            record_to_value(store, rt, path, fields, h)?
        }
    })
}

fn read_bytes<const N: usize>(store: &mut Store, rt: &RtFns, addr: usize) -> Result<[u8; N]> {
    let mut buf = [0u8; N];
    rt.mem.view(&*store).read(addr as u64, &mut buf).map_err(|e| anyhow!("CodegenWasmJit: memory read: {e}"))?;
    Ok(buf)
}

// `elem_kind` reuses `super::SigTy::elem_kind` so the host and codegen share one
// definition of the element-kind tags.

/// Fold a flat row-major element list into the nested `Values.ARRAY` structure:
/// one nesting level per dimension, each level's `dimLst` being the dimensions
/// at and below it.
fn nest_values(dims: &[i32], flat: &[Values::Value]) -> Values::Value {
    let d = dims[0];
    let values: Vec<Arc<Values::Value>> = if dims.len() == 1 {
        flat.iter().cloned().map(Arc::new).collect()
    } else {
        let chunk = flat.len() / d.max(1) as usize;
        (0..d as usize)
            .map(|i| Arc::new(nest_values(&dims[1..], &flat[i * chunk..(i + 1) * chunk])))
            .collect()
    };
    Values::Value::ARRAY {
        valueLst: Arc::new(List::from_iter(values)),
        dimLst: Arc::new(List::from_iter(dims.iter().copied())),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use wasm_encoder as we;

    /// Read the bytes of a runtime string handle out of an instance's memory.
    fn read_rt_string(
        store: &mut wasmer::Store,
        inst: &wasmer::Instance,
        mem: &wasmer::Memory,
        handle: i32,
    ) -> String {
        let len = inst.exports.get_typed_function::<i32, i32>(&*store, "rt_str_len").unwrap().call(&mut *store, handle).unwrap();
        let data = inst.exports.get_typed_function::<i32, i32>(&*store, "rt_str_data").unwrap().call(&mut *store, handle).unwrap();
        let mut buf = vec![0u8; len as usize];
        mem.view(&*store).read(data as usize as u64, &mut buf).unwrap();
        String::from_utf8(buf).unwrap()
    }

    /// The precompiled runtime instantiates and its `rt_*` string ABI works,
    /// including `rt_real_string` matching the canonical `metamodelica::realString`
    /// byte-for-byte (so `String(Real)` stays identical to the C target).
    #[test]
    fn precompiled_runtime_string_abi() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let mem = inst.exports.get_memory("memory").unwrap();

        let int_string = inst.exports.get_typed_function::<i32, i32>(&store, "rt_int_string").unwrap();
        let real_string = inst.exports.get_typed_function::<f64, i32>(&store, "rt_real_string").unwrap();
        let bool_string = inst.exports.get_typed_function::<i32, i32>(&store, "rt_bool_string").unwrap();
        let concat = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_concat").unwrap();
        let streq = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_streq").unwrap();
        let substring = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_substring").unwrap();
        let retain = inst.exports.get_typed_function::<i32, ()>(&store, "rt_retain").unwrap();
        let release = inst.exports.get_typed_function::<i32, ()>(&store, "rt_release").unwrap();

        let h42 = int_string.call(&mut store, 42).unwrap();
        assert_eq!(read_rt_string(&mut store, &inst, mem, h42), "42");
        let htrue = bool_string.call(&mut store, 1).unwrap();
        assert_eq!(read_rt_string(&mut store, &inst, mem, htrue), "true");

        // Concatenation: "12" + "3" via int formatting.
        let a = int_string.call(&mut store, 12).unwrap();
        let b = int_string.call(&mut store, 3).unwrap();
        let ab = concat.call(&mut store, a, b).unwrap();
        assert_eq!(read_rt_string(&mut store, &inst, mem, ab), "123");

        // substring("123", 2, 3) = "23".
        let sub = substring.call(&mut store, ab, 2, 3).unwrap();
        assert_eq!(read_rt_string(&mut store, &inst, mem, sub), "23");

        // Equality.
        let a2 = int_string.call(&mut store, 12).unwrap();
        assert_eq!(streq.call(&mut store, a, a2).unwrap(), 1);
        assert_eq!(streq.call(&mut store, a, b).unwrap(), 0);

        // realString must match the canonical formatter for a spread of values.
        for v in [0.0, 1.5, -2.0, 1.0 / 3.0, 1e-7, 1234567.0, 6.022e23, std::f64::consts::PI] {
            let h = real_string.call(&mut store, v).unwrap();
            let got = read_rt_string(&mut store, &inst, mem, h);
            let want = metamodelica::realString(metamodelica::Real::from(v)).to_string();
            assert_eq!(got, want, "realString({v})");
        }

        // Refcount: retain then two releases frees without trapping; the freed
        // slot is reused by the next allocation (allocator actually frees).
        let r = int_string.call(&mut store, 7).unwrap();
        retain.call(&mut store, r).unwrap();
        release.call(&mut store, r).unwrap();
        release.call(&mut store, r).unwrap();
    }

    /// The N-D array ABI: header bookkeeping (ndims/total/dims), row-major
    /// element addressing, and `rt_array_release` freeing nested heap (String)
    /// elements without trapping.
    #[test]
    fn precompiled_runtime_array_abi() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let mem = inst.exports.get_memory("memory").unwrap();

        let arr_new = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_array_new").unwrap();
        let set_dim = inst.exports.get_typed_function::<(i32, i32, i32), ()>(&store, "rt_array_set_dim").unwrap();
        let ndims = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_ndims").unwrap();
        let total = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_total").unwrap();
        let dim = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_dim").unwrap();
        let elem_ptr = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_elem_ptr").unwrap();
        let arr_release = inst.exports.get_typed_function::<i32, ()>(&store, "rt_array_release").unwrap();
        let int_string = inst.exports.get_typed_function::<i32, i32>(&store, "rt_int_string").unwrap();

        // A 2x3 Real array (elem_kind 1). Header reports rank/total/dims.
        let a = arr_new.call(&mut store, 1, 2, 6).unwrap();
        set_dim.call(&mut store, a, 0, 2).unwrap();
        set_dim.call(&mut store, a, 1, 3).unwrap();
        assert_eq!(ndims.call(&mut store, a).unwrap(), 2);
        assert_eq!(total.call(&mut store, a).unwrap(), 6);
        assert_eq!(dim.call(&mut store, a, 1).unwrap(), 2);
        assert_eq!(dim.call(&mut store, a, 2).unwrap(), 3);

        // Round-trip f64 elements through the row-major linear addresses.
        for k in 1..=6i32 {
            let addr = elem_ptr.call(&mut store, a, k).unwrap() as usize;
            mem.view(&store).write(addr as u64, &(k as f64 * 1.5).to_le_bytes()).unwrap();
        }
        for k in 1..=6i32 {
            let addr = elem_ptr.call(&mut store, a, k).unwrap() as usize;
            let mut buf = [0u8; 8];
            mem.view(&store).read(addr as u64, &mut buf).unwrap();
            assert_eq!(f64::from_le_bytes(buf), k as f64 * 1.5);
        }
        arr_release.call(&mut store, a).unwrap();

        // An array of two Strings (elem_kind 3): releasing the array must release
        // the contained string handles (no trap, double release is the symptom).
        let s = arr_new.call(&mut store, 3, 1, 2).unwrap();
        set_dim.call(&mut store, s, 0, 2).unwrap();
        for (k, n) in [(1, 11), (2, 22)] {
            let h = int_string.call(&mut store, n).unwrap();
            let addr = elem_ptr.call(&mut store, s, k).unwrap() as usize;
            mem.view(&store).write(addr as u64, &h.to_le_bytes()).unwrap();
        }
        arr_release.call(&mut store, s).unwrap();

        // rt_array_copy gives independent storage (value semantics): mutating the
        // copy must not change the original.
        let arr_copy = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_copy").unwrap();
        let orig = arr_new.call(&mut store, 1, 1, 3).unwrap();
        set_dim.call(&mut store, orig, 0, 3).unwrap();
        for k in 1..=3i32 {
            let addr = elem_ptr.call(&mut store, orig, k).unwrap() as usize;
            mem.view(&store).write(addr as u64, &(k as f64).to_le_bytes()).unwrap();
        }
        let dup = arr_copy.call(&mut store, orig).unwrap();
        assert_ne!(dup, orig);
        // Mutate the copy's first element.
        let addr = elem_ptr.call(&mut store, dup, 1).unwrap() as usize;
        mem.view(&store).write(addr as u64, &(99.0f64).to_le_bytes()).unwrap();
        // Original is unchanged.
        let addr = elem_ptr.call(&mut store, orig, 1).unwrap() as usize;
        let mut buf = [0u8; 8];
        mem.view(&store).read(addr as u64, &mut buf).unwrap();
        assert_eq!(f64::from_le_bytes(buf), 1.0);
        arr_release.call(&mut store, dup).unwrap();
        arr_release.call(&mut store, orig).unwrap();
    }

    /// The numeric array builtins (`fill`/`zeros`/`ones`, `sum`/`product`,
    /// `min`/`max`) over a Real array.
    #[test]
    fn precompiled_runtime_array_builtins() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let mem = inst.exports.get_memory("memory").unwrap();

        let arr_new = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_array_new").unwrap();
        let set_dim = inst.exports.get_typed_function::<(i32, i32, i32), ()>(&store, "rt_array_set_dim").unwrap();
        let elem_ptr = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_elem_ptr").unwrap();
        let fill_f64 = inst.exports.get_typed_function::<(i32, f64), ()>(&store, "rt_array_fill_f64").unwrap();
        let sum_f64 = inst.exports.get_typed_function::<i32, f64>(&store, "rt_array_sum_f64").unwrap();
        let product_f64 = inst.exports.get_typed_function::<i32, f64>(&store, "rt_array_product_f64").unwrap();
        let extreme_f64 = inst.exports.get_typed_function::<(i32, i32), f64>(&store, "rt_array_extreme_f64").unwrap();

        // fill a Real[3] with 2.5 -> sum 7.5, product 15.625.
        let a = arr_new.call(&mut store, 1, 1, 3).unwrap();
        set_dim.call(&mut store, a, 0, 3).unwrap();
        fill_f64.call(&mut store, a, 2.5).unwrap();
        assert_eq!(sum_f64.call(&mut store, a).unwrap(), 7.5);
        assert_eq!(product_f64.call(&mut store, a).unwrap(), 2.5 * 2.5 * 2.5);

        // Distinct values for min/max.
        for (k, v) in [(1, 3.0), (2, 1.0), (3, 4.0)] {
            let addr = elem_ptr.call(&mut store, a, k).unwrap() as usize;
            mem.view(&store).write(addr as u64, &(v as f64).to_le_bytes()).unwrap();
        }
        assert_eq!(extreme_f64.call(&mut store, a, 0).unwrap(), 1.0); // min
        assert_eq!(extreme_f64.call(&mut store, a, 1).unwrap(), 4.0); // max
    }

    /// `rt_real_format` (`String(Real, significantDigits, minimumLength,
    /// leftJustified)`) must match the canonical `printf`-`%g` formatter that
    /// `Ceval.cevalBuiltinString` / the C target use, and `rt_str_pad`
    /// (`String(Integer/Boolean/String, minimumLength, leftJustified)`) must
    /// match `ExpressionSimplify.cevalBuiltinStringFormat`'s space-padding.
    #[test]
    fn precompiled_runtime_real_format_and_pad_abi() {
        use openmodelica_util::System;

        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let mem = inst.exports.get_memory("memory").unwrap();

        let real_format =
            inst.exports.get_typed_function::<(f64, i32, i32, i32), i32>(&store, "rt_real_format").unwrap();
        let str_new = inst.exports.get_typed_function::<i32, i32>(&store, "rt_str_new").unwrap();
        let str_data = inst.exports.get_typed_function::<i32, i32>(&store, "rt_str_data").unwrap();
        let str_pad = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_str_pad").unwrap();

        // String(Real, sig, minlen, leftjust): mirror Ceval's format string
        // `"%[-]{minlen}.{sig}g"` evaluated with `System.snprintff` (the canonical
        // C-printf port) and compare byte-for-byte.
        let values = [0.0, 1.5, -2.0, 1.0 / 3.0, 1e-7, 1234567.0, 6.022e23, std::f64::consts::PI, -0.000123456];
        for &v in &values {
            for &(sig, minlen, leftjust) in &[(6, 0, 1), (3, 0, 1), (6, 12, 1), (6, 12, 0), (2, 0, 1)] {
                let h = real_format.call(&mut store, v, sig, minlen, leftjust).unwrap();
                let got = read_rt_string(&mut store, &inst, mem, h);
                let dash = if leftjust != 0 { "-" } else { "" };
                let fmt = format!("%{dash}{minlen}.{sig}g");
                let want = System::snprintff(
                    arcstr::ArcStr::from(fmt),
                    minlen + 20,
                    metamodelica::Real::from(v),
                )
                .unwrap()
                .to_string();
                assert_eq!(got, want, "String({v}, sig={sig}, minlen={minlen}, leftjust={leftjust})");
            }
        }

        // rt_str_pad: write a string into a fresh runtime object, then pad.
        let make = |store: &mut wasmer::Store, s: &str| -> i32 {
            let h = str_new.call(&mut *store, s.len() as i32).unwrap();
            let d = str_data.call(&mut *store, h).unwrap() as usize;
            mem.view(&*store).write(d as u64, s.as_bytes()).unwrap();
            h
        };
        // Shorter than minlen: pad with spaces (trailing when leftjust, else leading).
        let h = make(&mut store, "hi");
        let p = str_pad.call(&mut store, h, 6, 1).unwrap();
        assert_eq!(read_rt_string(&mut store, &inst, mem, p), "hi    ");
        let h = make(&mut store, "hi");
        let p = str_pad.call(&mut store, h, 6, 0).unwrap();
        assert_eq!(read_rt_string(&mut store, &inst, mem, p), "    hi");
        // Already at least minlen: returned unchanged.
        let h = make(&mut store, "already long");
        let p = str_pad.call(&mut store, h, 4, 0).unwrap();
        assert_eq!(read_rt_string(&mut store, &inst, mem, p), "already long");
    }

    /// Encode a one-function module exporting `main` with the given signature
    /// and body, write it plus its sidecar under a temp basename, and return
    /// the basename for `load_and_execute`.
    fn emit(base: &str, params: &[we::ValType], results: &[we::ValType], sig: &str, body: &[we::Instruction]) -> String {
        let mut m = we::Module::new();
        let mut types = we::TypeSection::new();
        types.ty().function(params.iter().copied(), results.iter().copied());
        m.section(&types);
        let mut funcs = we::FunctionSection::new();
        funcs.function(0);
        m.section(&funcs);
        let mut exports = we::ExportSection::new();
        exports.export("main", we::ExportKind::Func, 0);
        m.section(&exports);
        let mut code = we::CodeSection::new();
        let mut f = we::Function::new([]);
        for i in body {
            f.instruction(i);
        }
        code.function(&f);
        m.section(&code);
        let path = std::env::temp_dir().join(base);
        let path = path.to_str().unwrap().to_string();
        std::fs::write(format!("{path}.wasm"), m.finish()).unwrap();
        std::fs::write(format!("{path}.wasm.sig"), sig).unwrap();
        path
    }

    fn ival(v: &Values::Value) -> i32 {
        match v {
            Values::Value::INTEGER { integer } => *integer,
            other => panic!("expected INTEGER, got {other:?}"),
        }
    }
    fn rval(v: &Values::Value) -> f64 {
        match v {
            Values::Value::REAL { real } => real.into_inner(),
            other => panic!("expected REAL, got {other:?}"),
        }
    }

    #[test]
    fn integer_add() {
        let base = emit(
            "wjit_iadd",
            &[we::ValType::I32, we::ValType::I32],
            &[we::ValType::I32],
            "II\nI\n",
            &[we::Instruction::LocalGet(0), we::Instruction::LocalGet(1), we::Instruction::I32Add, we::Instruction::End],
        );
        let args = Arc::new(List::from_iter([
            Arc::new(Values::Value::INTEGER { integer: 3 }),
            Arc::new(Values::Value::INTEGER { integer: 4 }),
        ]));
        let r = load_and_execute(&base, "main", &args).unwrap();
        assert_eq!(ival(&r), 7);
    }

    #[test]
    fn real_scale() {
        // main(x) = x * 2.0
        let base = emit(
            "wjit_rscale",
            &[we::ValType::F64],
            &[we::ValType::F64],
            "R\nR\n",
            &[
                we::Instruction::LocalGet(0),
                we::Instruction::F64Const(2.0.into()),
                we::Instruction::F64Mul,
                we::Instruction::End,
            ],
        );
        let args = Arc::new(List::from_iter([Arc::new(Values::Value::REAL { real: metamodelica::Real::from(21.0) })]));
        let r = load_and_execute(&base, "main", &args).unwrap();
        assert_eq!(rval(&r), 42.0);
    }

    #[test]
    fn multi_output_tuple() {
        // main(x) = (x, x+1)
        let base = emit(
            "wjit_tuple",
            &[we::ValType::I32],
            &[we::ValType::I32, we::ValType::I32],
            "I\nII\n",
            &[
                we::Instruction::LocalGet(0),
                we::Instruction::LocalGet(0),
                we::Instruction::I32Const(1),
                we::Instruction::I32Add,
                we::Instruction::End,
            ],
        );
        let args = Arc::new(List::from_iter([Arc::new(Values::Value::INTEGER { integer: 41 })]));
        let r = load_and_execute(&base, "main", &args).unwrap();
        match &*r {
            Values::Value::TUPLE { valueLst } => {
                let v: Vec<_> = (&**valueLst).into_iter().collect();
                assert_eq!(v.len(), 2);
                assert_eq!(ival(&v[0]), 41);
                assert_eq!(ival(&v[1]), 42);
            }
            other => panic!("expected TUPLE, got {other:?}"),
        }
    }

    #[test]
    fn cache_reuse_and_redefinition() {
        // First definition of `main(a,b) = a + b`. Running it twice must give
        // the same answer (the second call hits the compiled-module cache).
        let base = emit(
            "wjit_cache",
            &[we::ValType::I32, we::ValType::I32],
            &[we::ValType::I32],
            "II\nI\n",
            &[we::Instruction::LocalGet(0), we::Instruction::LocalGet(1), we::Instruction::I32Add, we::Instruction::End],
        );
        let args = Arc::new(List::from_iter([
            Arc::new(Values::Value::INTEGER { integer: 5 }),
            Arc::new(Values::Value::INTEGER { integer: 7 }),
        ]));
        assert_eq!(ival(&load_and_execute(&base, "main", &args).unwrap()), 12);
        assert_eq!(ival(&load_and_execute(&base, "main", &args).unwrap()), 12);

        // Redefine the same basename to `main(a,b) = a * b` (different bytes).
        // The cache is keyed by content, so this must recompile rather than
        // reuse the stale `+` module.
        emit(
            "wjit_cache",
            &[we::ValType::I32, we::ValType::I32],
            &[we::ValType::I32],
            "II\nI\n",
            &[we::Instruction::LocalGet(0), we::Instruction::LocalGet(1), we::Instruction::I32Mul, we::Instruction::End],
        );
        assert_eq!(ival(&load_and_execute(&base, "main", &args).unwrap()), 35);
    }

    #[test]
    fn host_builtin_sin() {
        // main(x) = sin(x), importing the runtime builtin "sin" (now provided
        // in-wasm by the runtime under module "rt", not the host "env").
        let mut m = we::Module::new();
        let mut types = we::TypeSection::new();
        types.ty().function([we::ValType::F64], [we::ValType::F64]); // type 0: sin
        types.ty().function([we::ValType::F64], [we::ValType::F64]); // type 1: main
        m.section(&types);
        let mut imports = we::ImportSection::new();
        imports.import("rt", "sin", we::EntityType::Function(0));
        m.section(&imports);
        let mut funcs = we::FunctionSection::new();
        funcs.function(1);
        m.section(&funcs);
        let mut exports = we::ExportSection::new();
        exports.export("main", we::ExportKind::Func, 1); // func 0 is the import
        m.section(&exports);
        let mut code = we::CodeSection::new();
        let mut f = we::Function::new([]);
        f.instruction(&we::Instruction::LocalGet(0));
        f.instruction(&we::Instruction::Call(0));
        f.instruction(&we::Instruction::End);
        code.function(&f);
        m.section(&code);
        let path = std::env::temp_dir().join("wjit_sin");
        let path = path.to_str().unwrap().to_string();
        std::fs::write(format!("{path}.wasm"), m.finish()).unwrap();
        std::fs::write(format!("{path}.wasm.sig"), "R\nR\n").unwrap();

        let args = Arc::new(List::from_iter([Arc::new(Values::Value::REAL {
            real: metamodelica::Real::from(std::f64::consts::FRAC_PI_2),
        })]));
        let r = load_and_execute(&path, "main", &args).unwrap();
        assert!((rval(&r) - 1.0).abs() < 1e-12);
    }

    /// Element-wise array arithmetic: array op array, scalar broadcast (both
    /// operand orders) and negation, over Real and Integer elements.
    #[test]
    fn precompiled_runtime_array_elementwise() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let mem = inst.exports.get_memory("memory").unwrap();
        let arr_new = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_array_new").unwrap();
        let set_dim = inst.exports.get_typed_function::<(i32, i32, i32), ()>(&store, "rt_array_set_dim").unwrap();
        let elem_ptr = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_elem_ptr").unwrap();
        let ew_f64 = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_array_ew_f64").unwrap();
        let scalar_f64 = inst.exports.get_typed_function::<(i32, f64, i32, i32), i32>(&store, "rt_array_scalar_f64").unwrap();
        let neg_i32 = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_neg_i32").unwrap();

        // Build a Real[3] from a slice.
        let mut mk_f64 = |store: &mut Store, vals: &[f64]| -> i32 {
            let a = arr_new.call(&mut *store, 1, 1, vals.len() as i32).unwrap();
            set_dim.call(&mut *store, a, 0, vals.len() as i32).unwrap();
            for (k, v) in vals.iter().enumerate() {
                let addr = elem_ptr.call(&mut *store, a, k as i32 + 1).unwrap() as usize;
                mem.view(&*store).write(addr as u64, &v.to_le_bytes()).unwrap();
            }
            a
        };
        let mut read_f64 = |store: &mut Store, h: i32, n: usize| -> Vec<f64> {
            (0..n)
                .map(|k| {
                    let addr = elem_ptr.call(&mut *store, h, k as i32 + 1).unwrap() as usize;
                    let mut b = [0u8; 8];
                    mem.view(&*store).read(addr as u64, &mut b).unwrap();
                    f64::from_le_bytes(b)
                })
                .collect()
        };

        let a = mk_f64(&mut store, &[1.0, 2.0, 3.0]);
        let b = mk_f64(&mut store, &[10.0, 20.0, 30.0]);

        // a + b = {11, 22, 33}.
        let sum = ew_f64.call(&mut store, a, b, 0).unwrap();
        assert_eq!(read_f64(&mut store, sum, 3), [11.0, 22.0, 33.0]);
        // a * 2 = {2, 4, 6}.
        let scaled = scalar_f64.call(&mut store, a, 2.0, 2, 0).unwrap();
        assert_eq!(read_f64(&mut store, scaled, 3), [2.0, 4.0, 6.0]);
        // 10 - a = {9, 8, 7} (rev = 1).
        let sub = scalar_f64.call(&mut store, a, 10.0, 1, 1).unwrap();
        assert_eq!(read_f64(&mut store, sub, 3), [9.0, 8.0, 7.0]);

        // Integer negation: -{1,-2,3} = {-1,2,-3}.
        let ai = arr_new.call(&mut store, 0, 1, 3).unwrap();
        set_dim.call(&mut store, ai, 0, 3).unwrap();
        for (k, v) in [1i32, -2, 3].iter().enumerate() {
            let addr = elem_ptr.call(&mut store, ai, k as i32 + 1).unwrap() as usize;
            mem.view(&store).write(addr as u64, &v.to_le_bytes()).unwrap();
        }
        let neg = neg_i32.call(&mut store, ai).unwrap();
        for (k, want) in [-1i32, 2, -3].iter().enumerate() {
            let addr = elem_ptr.call(&mut store, neg, k as i32 + 1).unwrap() as usize;
            let mut buf = [0u8; 4];
            mem.view(&store).read(addr as u64, &mut buf).unwrap();
            assert_eq!(i32::from_le_bytes(buf), *want);
        }
    }

    /// `transpose` of a 2x3 Integer matrix gives a 3x2 with swapped indices.
    #[test]
    fn precompiled_runtime_array_transpose() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let mem = inst.exports.get_memory("memory").unwrap();
        let arr_new = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_array_new").unwrap();
        let set_dim = inst.exports.get_typed_function::<(i32, i32, i32), ()>(&store, "rt_array_set_dim").unwrap();
        let elem_ptr = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_elem_ptr").unwrap();
        let dim = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_dim").unwrap();
        let transpose = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_transpose").unwrap();

        // [[1,2,3],[4,5,6]] row-major: 1,2,3,4,5,6.
        let a = arr_new.call(&mut store, 0, 2, 6).unwrap();
        set_dim.call(&mut store, a, 0, 2).unwrap();
        set_dim.call(&mut store, a, 1, 3).unwrap();
        for (k, v) in [1i32, 2, 3, 4, 5, 6].iter().enumerate() {
            let addr = elem_ptr.call(&mut store, a, k as i32 + 1).unwrap() as usize;
            mem.view(&store).write(addr as u64, &v.to_le_bytes()).unwrap();
        }
        let t = transpose.call(&mut store, a).unwrap();
        assert_eq!(dim.call(&mut store, t, 1).unwrap(), 3);
        assert_eq!(dim.call(&mut store, t, 2).unwrap(), 2);
        // transpose is [[1,4],[2,5],[3,6]] row-major: 1,4,2,5,3,6.
        for (k, want) in [1i32, 4, 2, 5, 3, 6].iter().enumerate() {
            let addr = elem_ptr.call(&mut store, t, k as i32 + 1).unwrap() as usize;
            let mut b = [0u8; 4];
            mem.view(&store).read(addr as u64, &mut b).unwrap();
            assert_eq!(i32::from_le_bytes(b), *want);
        }
    }

    /// `rt_array_slice` on a 3x3 Real matrix: a row slice `m[2,:]` (INDEX,
    /// WHOLE), a column slice `m[:,2]` (WHOLE, INDEX, strided), and an explicit
    /// index-array slice `m[1,{3,1}]` (INDEX, SLICE). The spec is an Integer
    /// array of (kind, value) pairs as the codegen builds it.
    #[test]
    fn precompiled_runtime_array_slice() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let mem = inst.exports.get_memory("memory").unwrap();
        let arr_new = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_array_new").unwrap();
        let set_dim = inst.exports.get_typed_function::<(i32, i32, i32), ()>(&store, "rt_array_set_dim").unwrap();
        let elem_ptr = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_elem_ptr").unwrap();
        let dim = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_dim").unwrap();
        let ndims = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_ndims").unwrap();
        let slice = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_array_slice").unwrap();

        // m = [[1,2,3],[4,5,6],[7,8,9]] Real, row-major.
        let m = arr_new.call(&mut store, 1, 2, 9).unwrap();
        set_dim.call(&mut store, m, 0, 3).unwrap();
        set_dim.call(&mut store, m, 1, 3).unwrap();
        for k in 0..9 {
            let addr = elem_ptr.call(&mut store, m, k + 1).unwrap() as usize;
            mem.view(&store).write(addr as u64, &((k + 1) as f64).to_le_bytes()).unwrap();
        }
        let rf = |store: &mut Store, h: i32, k: i32| {
            let addr = elem_ptr.call(&mut *store, h, k).unwrap() as usize;
            let mut b = [0u8; 8];
            mem.view(&*store).read(addr as u64, &mut b).unwrap();
            f64::from_le_bytes(b)
        };
        // Build a 2-axis (kind, value) Integer spec array.
        let make_spec = |store: &mut Store, pairs: &[(i32, i32)]| -> i32 {
            let s = arr_new.call(&mut *store, 0, 1, pairs.len() as i32 * 2).unwrap();
            for (i, (k, v)) in pairs.iter().enumerate() {
                let ka = elem_ptr.call(&mut *store, s, i as i32 * 2 + 1).unwrap() as usize;
                mem.view(&*store).write(ka as u64, &k.to_le_bytes()).unwrap();
                let va = elem_ptr.call(&mut *store, s, i as i32 * 2 + 2).unwrap() as usize;
                mem.view(&*store).write(va as u64, &v.to_le_bytes()).unwrap();
            }
            s
        };

        // Row slice m[2,:] = {4,5,6}: axis0 INDEX 2, axis1 WHOLE.
        let sp = make_spec(&mut store, &[(0, 2), (1, 0)]);
        let row = slice.call(&mut store, m, 2, sp).unwrap();
        assert_eq!(ndims.call(&mut store, row).unwrap(), 1);
        assert_eq!(dim.call(&mut store, row, 1).unwrap(), 3);
        assert_eq!((rf(&mut store, row, 1), rf(&mut store, row, 2), rf(&mut store, row, 3)), (4.0, 5.0, 6.0));

        // Column slice m[:,2] = {2,5,8}: axis0 WHOLE, axis1 INDEX 2.
        let sp = make_spec(&mut store, &[(1, 0), (0, 2)]);
        let col = slice.call(&mut store, m, 2, sp).unwrap();
        assert_eq!(dim.call(&mut store, col, 1).unwrap(), 3);
        assert_eq!((rf(&mut store, col, 1), rf(&mut store, col, 2), rf(&mut store, col, 3)), (2.0, 5.0, 8.0));

        // Index-array slice m[1,{3,1}] = {3,1}: axis0 INDEX 1, axis1 SLICE {3,1}.
        let idx = arr_new.call(&mut store, 0, 1, 2).unwrap();
        set_dim.call(&mut store, idx, 0, 2).unwrap();
        let a0 = elem_ptr.call(&mut store, idx, 1).unwrap() as usize;
        mem.view(&store).write(a0 as u64, &3i32.to_le_bytes()).unwrap();
        let a1 = elem_ptr.call(&mut store, idx, 2).unwrap() as usize;
        mem.view(&store).write(a1 as u64, &1i32.to_le_bytes()).unwrap();
        let sp = make_spec(&mut store, &[(0, 1), (2, idx)]);
        let pick = slice.call(&mut store, m, 2, sp).unwrap();
        assert_eq!(dim.call(&mut store, pick, 1).unwrap(), 2);
        assert_eq!((rf(&mut store, pick, 1), rf(&mut store, pick, 2)), (3.0, 1.0));
    }

    /// `rt_array_cat` on Real arrays: a 1-D 3-way concat along dim 1, and a 2-D
    /// concat along dim 2 (strided copy into the result).
    #[test]
    fn precompiled_runtime_array_cat() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let mem = inst.exports.get_memory("memory").unwrap();
        let arr_new = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_array_new").unwrap();
        let set_dim = inst.exports.get_typed_function::<(i32, i32, i32), ()>(&store, "rt_array_set_dim").unwrap();
        let elem_ptr = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_elem_ptr").unwrap();
        let dim = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_dim").unwrap();
        let total = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_total").unwrap();
        let cat = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_array_cat").unwrap();
        let rf = |store: &mut Store, h: i32, k: i32| {
            let addr = elem_ptr.call(&mut *store, h, k).unwrap() as usize;
            let mut b = [0u8; 8];
            mem.view(&*store).read(addr as u64, &mut b).unwrap();
            f64::from_le_bytes(b)
        };
        // Build a 1-D Real vector from a slice of values.
        let vec = |store: &mut Store, vals: &[f64]| -> i32 {
            let h = arr_new.call(&mut *store, 1, 1, vals.len() as i32).unwrap();
            set_dim.call(&mut *store, h, 0, vals.len() as i32).unwrap();
            for (k, v) in vals.iter().enumerate() {
                let addr = elem_ptr.call(&mut *store, h, k as i32 + 1).unwrap() as usize;
                mem.view(&*store).write(addr as u64, &v.to_le_bytes()).unwrap();
            }
            h
        };
        // An Integer array of handles for the cat call.
        let handles = |store: &mut Store, hs: &[i32]| -> i32 {
            let h = arr_new.call(&mut *store, 0, 1, hs.len() as i32).unwrap();
            for (k, v) in hs.iter().enumerate() {
                let addr = elem_ptr.call(&mut *store, h, k as i32 + 1).unwrap() as usize;
                mem.view(&*store).write(addr as u64, &v.to_le_bytes()).unwrap();
            }
            h
        };

        // cat(1, {1}, {2,3}, {4,5,6}) = {1,2,3,4,5,6}.
        let a = vec(&mut store, &[1.0]);
        let b = vec(&mut store, &[2.0, 3.0]);
        let c = vec(&mut store, &[4.0, 5.0, 6.0]);
        let hs = handles(&mut store, &[a, b, c]);
        let r = cat.call(&mut store, 1, 3, hs).unwrap();
        assert_eq!(total.call(&mut store, r).unwrap(), 6);
        for k in 0..6 {
            assert_eq!(rf(&mut store, r, k + 1), (k + 1) as f64);
        }

        // cat(2, [[1,2],[3,4]], [[5],[6]]) = [[1,2,5],[3,4,6]] (strided copy).
        let m = arr_new.call(&mut store, 1, 2, 4).unwrap();
        set_dim.call(&mut store, m, 0, 2).unwrap();
        set_dim.call(&mut store, m, 1, 2).unwrap();
        for (k, v) in [1.0f64, 2.0, 3.0, 4.0].iter().enumerate() {
            let addr = elem_ptr.call(&mut store, m, k as i32 + 1).unwrap() as usize;
            mem.view(&store).write(addr as u64, &v.to_le_bytes()).unwrap();
        }
        let p = arr_new.call(&mut store, 1, 2, 2).unwrap();
        set_dim.call(&mut store, p, 0, 2).unwrap();
        set_dim.call(&mut store, p, 1, 1).unwrap();
        for (k, v) in [5.0f64, 6.0].iter().enumerate() {
            let addr = elem_ptr.call(&mut store, p, k as i32 + 1).unwrap() as usize;
            mem.view(&store).write(addr as u64, &v.to_le_bytes()).unwrap();
        }
        let hs = handles(&mut store, &[m, p]);
        let r = cat.call(&mut store, 2, 2, hs).unwrap();
        assert_eq!((dim.call(&mut store, r, 1).unwrap(), dim.call(&mut store, r, 2).unwrap()), (2, 3));
        // row-major [[1,2,5],[3,4,6]] = 1,2,5,3,4,6.
        for (k, want) in [1.0f64, 2.0, 5.0, 3.0, 4.0, 6.0].iter().enumerate() {
            assert_eq!(rf(&mut store, r, k as i32 + 1), *want);
        }
    }

    /// `rt_array_dot_f64` and `rt_array_matmul_f64`: a vector dot product, a
    /// matrix·vector, and a non-square matrix·matrix product.
    #[test]
    fn precompiled_runtime_array_matmul() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let mem = inst.exports.get_memory("memory").unwrap();
        let arr_new = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_array_new").unwrap();
        let set_dim = inst.exports.get_typed_function::<(i32, i32, i32), ()>(&store, "rt_array_set_dim").unwrap();
        let elem_ptr = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_elem_ptr").unwrap();
        let dim = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_dim").unwrap();
        let ndims = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_ndims").unwrap();
        let dot = inst.exports.get_typed_function::<(i32, i32), f64>(&store, "rt_array_dot_f64").unwrap();
        let matmul = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_matmul_f64").unwrap();
        let rf = |store: &mut Store, h: i32, k: i32| {
            let addr = elem_ptr.call(&mut *store, h, k).unwrap() as usize;
            let mut b = [0u8; 8];
            mem.view(&*store).read(addr as u64, &mut b).unwrap();
            f64::from_le_bytes(b)
        };
        // An n-D Real array from flat row-major data + dims.
        let arr = |store: &mut Store, dims: &[i32], vals: &[f64]| -> i32 {
            let h = arr_new.call(&mut *store, 1, dims.len() as i32, vals.len() as i32).unwrap();
            for (a, d) in dims.iter().enumerate() {
                set_dim.call(&mut *store, h, a as i32, *d).unwrap();
            }
            for (k, v) in vals.iter().enumerate() {
                let addr = elem_ptr.call(&mut *store, h, k as i32 + 1).unwrap() as usize;
                mem.view(&*store).write(addr as u64, &v.to_le_bytes()).unwrap();
            }
            h
        };

        // {1,2,3} . {4,5,6} = 32.
        let a = arr(&mut store, &[3], &[1.0, 2.0, 3.0]);
        let b = arr(&mut store, &[3], &[4.0, 5.0, 6.0]);
        assert_eq!(dot.call(&mut store, a, b).unwrap(), 32.0);

        // [[1,2],[3,4]] * {5,6} = {17,39} (matrix·vector → rank-1).
        let m = arr(&mut store, &[2, 2], &[1.0, 2.0, 3.0, 4.0]);
        let v = arr(&mut store, &[2], &[5.0, 6.0]);
        let r = matmul.call(&mut store, m, v).unwrap();
        assert_eq!(ndims.call(&mut store, r).unwrap(), 1);
        assert_eq!((rf(&mut store, r, 1), rf(&mut store, r, 2)), (17.0, 39.0));

        // [[1,2,3]] (1x3) * [[1],[2],[3]] (3x1) = [[14]] (1x1).
        let p = arr(&mut store, &[1, 3], &[1.0, 2.0, 3.0]);
        let q = arr(&mut store, &[3, 1], &[1.0, 2.0, 3.0]);
        let r = matmul.call(&mut store, p, q).unwrap();
        assert_eq!((dim.call(&mut store, r, 1).unwrap(), dim.call(&mut store, r, 2).unwrap()), (1, 1));
        assert_eq!(rf(&mut store, r, 1), 14.0);
    }

    /// `rt_real_int_pow` (scalar integer power by squaring): exact values,
    /// the zero / negative-exponent cases, and the reciprocal branch.
    #[test]
    fn precompiled_runtime_real_int_pow() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let pow = inst.exports.get_typed_function::<(f64, i32), f64>(&store, "rt_real_int_pow").unwrap();
        assert_eq!(pow.call(&mut store, 2.0, 10).unwrap(), 1024.0);
        assert_eq!(pow.call(&mut store, 10.0, 3).unwrap(), 1000.0);
        assert_eq!(pow.call(&mut store, 1.5, 4).unwrap(), 5.0625);
        assert_eq!(pow.call(&mut store, 7.0, 0).unwrap(), 1.0);
        assert_eq!(pow.call(&mut store, 2.0, 1).unwrap(), 2.0);
        assert_eq!(pow.call(&mut store, 2.0, -2).unwrap(), 0.25);
        assert_eq!(pow.call(&mut store, 4.0, -1).unwrap(), 0.25);
    }

    /// `rt_real_pow` (generic scalar power): positive base, negative base with
    /// an integer-ish exponent, an odd root of a negative base, and the invalid
    /// / nan-inf cases that must trap.
    #[test]
    fn precompiled_runtime_real_pow() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let pow = inst.exports.get_typed_function::<(f64, f64), f64>(&store, "rt_real_pow").unwrap();
        assert_eq!(pow.call(&mut store, 2.0, 3.0).unwrap(), 8.0);
        assert_eq!(pow.call(&mut store, 4.0, 0.5).unwrap(), 2.0);
        // Negative base, (effectively) integer exponent → real.
        assert_eq!(pow.call(&mut store, -2.0, 3.0).unwrap(), -8.0);
        // Odd root of a negative base → real (within rounding of 1/3).
        assert!((pow.call(&mut store, -27.0, 1.0 / 3.0).unwrap() + 3.0).abs() < 1e-9);
        // Invalid root and overflow-to-inf both trap.
        assert!(pow.call(&mut store, -2.0, 0.5).is_err());
        assert!(pow.call(&mut store, 1e300, 2.0).is_err());
    }

    /// `rt_mod_int`: floored integer modulo, result takes the divisor's sign.
    #[test]
    fn precompiled_runtime_mod_int() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let m = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_mod_int").unwrap();
        assert_eq!(m.call(&mut store, 7, 3).unwrap(), 1);
        assert_eq!(m.call(&mut store, -7, 3).unwrap(), 2);
        assert_eq!(m.call(&mut store, 7, -3).unwrap(), -2);
        assert_eq!(m.call(&mut store, -7, -3).unwrap(), -1);
        assert_eq!(m.call(&mut store, 6, 3).unwrap(), 0);
        assert!(m.call(&mut store, 1, 0).is_err()); // zero divisor traps
    }

    /// Shape / geometric builtins: vector / matrix / promote reshape,
    /// symmetric, cross, outerProduct, skew (all Real where numeric).
    #[test]
    fn precompiled_runtime_shape_builtins() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let mem = inst.exports.get_memory("memory").unwrap();
        let arr_new = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_array_new").unwrap();
        let set_dim = inst.exports.get_typed_function::<(i32, i32, i32), ()>(&store, "rt_array_set_dim").unwrap();
        let elem_ptr = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_elem_ptr").unwrap();
        let dim = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_dim").unwrap();
        let ndims = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_ndims").unwrap();
        let cross = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_cross_f64").unwrap();
        let outer = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_outer_f64").unwrap();
        let skew = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_skew_f64").unwrap();
        let vector = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_vector").unwrap();
        let promote = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_promote").unwrap();
        let sym = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_symmetric").unwrap();
        let rf = |store: &mut Store, h: i32, k: i32| {
            let addr = elem_ptr.call(&mut *store, h, k).unwrap() as usize;
            let mut b = [0u8; 8];
            mem.view(&*store).read(addr as u64, &mut b).unwrap();
            f64::from_le_bytes(b)
        };
        let vecf = |store: &mut Store, dims: &[i32], vals: &[f64]| -> i32 {
            let h = arr_new.call(&mut *store, 1, dims.len() as i32, vals.len() as i32).unwrap();
            for (a, d) in dims.iter().enumerate() {
                set_dim.call(&mut *store, h, a as i32, *d).unwrap();
            }
            for (k, v) in vals.iter().enumerate() {
                let addr = elem_ptr.call(&mut *store, h, k as i32 + 1).unwrap() as usize;
                mem.view(&*store).write(addr as u64, &v.to_le_bytes()).unwrap();
            }
            h
        };

        // cross(e1, e2) = e3.
        let x = vecf(&mut store, &[3], &[1.0, 0.0, 0.0]);
        let y = vecf(&mut store, &[3], &[0.0, 1.0, 0.0]);
        let c = cross.call(&mut store, x, y).unwrap();
        assert_eq!((rf(&mut store, c, 1), rf(&mut store, c, 2), rf(&mut store, c, 3)), (0.0, 0.0, 1.0));

        // outerProduct({1,2},{3,4,5}) = {{3,4,5},{6,8,10}} (2x3).
        let a = vecf(&mut store, &[2], &[1.0, 2.0]);
        let b = vecf(&mut store, &[3], &[3.0, 4.0, 5.0]);
        let o = outer.call(&mut store, a, b).unwrap();
        assert_eq!((dim.call(&mut store, o, 1).unwrap(), dim.call(&mut store, o, 2).unwrap()), (2, 3));
        assert_eq!((rf(&mut store, o, 3), rf(&mut store, o, 6)), (5.0, 10.0));

        // skew({1,2,3}) row 1 = {0,-3,2}.
        let sk = vecf(&mut store, &[3], &[1.0, 2.0, 3.0]);
        let s = skew.call(&mut store, sk).unwrap();
        assert_eq!((rf(&mut store, s, 1), rf(&mut store, s, 2), rf(&mut store, s, 3)), (0.0, -3.0, 2.0));

        // vector of a 1x3 → 1-D {1,2,3}.
        let v13 = vecf(&mut store, &[1, 3], &[1.0, 2.0, 3.0]);
        let v = vector.call(&mut store, v13).unwrap();
        assert_eq!(ndims.call(&mut store, v).unwrap(), 1);
        assert_eq!(rf(&mut store, v, 2), 2.0);

        // promote({1,2}, 3) → 3-D with dims {2,1,1}.
        let pv = vecf(&mut store, &[2], &[1.0, 2.0]);
        let p = promote.call(&mut store, pv, 3).unwrap();
        assert_eq!(ndims.call(&mut store, p).unwrap(), 3);
        assert_eq!((dim.call(&mut store, p, 1).unwrap(), dim.call(&mut store, p, 2).unwrap()), (2, 1));

        // symmetric mirrors the upper triangle: a[2,1] is replaced by a[1,2].
        let m = arr_new.call(&mut store, 1, 2, 4).unwrap();
        set_dim.call(&mut store, m, 0, 2).unwrap();
        set_dim.call(&mut store, m, 1, 2).unwrap();
        for (k, vv) in [1.0f64, 2.0, 9.0, 4.0].iter().enumerate() {
            let addr = elem_ptr.call(&mut store, m, k as i32 + 1).unwrap() as usize;
            mem.view(&store).write(addr as u64, &vv.to_le_bytes()).unwrap();
        }
        let sm = sym.call(&mut store, m).unwrap();
        // row-major {1,2,2,4} (the 9 is discarded).
        for (k, want) in [1.0f64, 2.0, 2.0, 4.0].iter().enumerate() {
            assert_eq!(rf(&mut store, sm, k as i32 + 1), *want);
        }
    }

    /// Integer[] -> Real[] cast, and element-wise Boolean and/or/not.
    #[test]
    fn precompiled_runtime_int_to_real_and_logical() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let mem = inst.exports.get_memory("memory").unwrap();
        let arr_new = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_array_new").unwrap();
        let set_dim = inst.exports.get_typed_function::<(i32, i32, i32), ()>(&store, "rt_array_set_dim").unwrap();
        let elem_ptr = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_elem_ptr").unwrap();
        let i2r = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_int_to_real").unwrap();
        let ew = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_array_ew_i32").unwrap();
        let notf = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_not_i32").unwrap();
        // i32 vector {dims, vals}.
        let iv = |store: &mut Store, vals: &[i32]| -> i32 {
            let h = arr_new.call(&mut *store, 0, 1, vals.len() as i32).unwrap();
            set_dim.call(&mut *store, h, 0, vals.len() as i32).unwrap();
            for (k, v) in vals.iter().enumerate() {
                let addr = elem_ptr.call(&mut *store, h, k as i32 + 1).unwrap() as usize;
                mem.view(&*store).write(addr as u64, &v.to_le_bytes()).unwrap();
            }
            h
        };
        let ri = |store: &mut Store, h: i32, k: i32| {
            let addr = elem_ptr.call(&mut *store, h, k).unwrap() as usize;
            let mut b = [0u8; 4];
            mem.view(&*store).read(addr as u64, &mut b).unwrap();
            i32::from_le_bytes(b)
        };
        let rf = |store: &mut Store, h: i32, k: i32| {
            let addr = elem_ptr.call(&mut *store, h, k).unwrap() as usize;
            let mut b = [0u8; 8];
            mem.view(&*store).read(addr as u64, &mut b).unwrap();
            f64::from_le_bytes(b)
        };
        // {7,8,9} -> {7.0,8.0,9.0}.
        let iarr = iv(&mut store, &[7, 8, 9]);
        let r = i2r.call(&mut store, iarr).unwrap();
        assert_eq!((rf(&mut store, r, 1), rf(&mut store, r, 3)), (7.0, 9.0));
        // {1,0,1} and {1,1,0} = {1,0,0}; or = {1,1,1}.
        let a = iv(&mut store, &[1, 0, 1]);
        let b = iv(&mut store, &[1, 1, 0]);
        let and = ew.call(&mut store, a, b, 5).unwrap(); // OP_AND
        assert_eq!((ri(&mut store, and, 1), ri(&mut store, and, 2), ri(&mut store, and, 3)), (1, 0, 0));
        let or = ew.call(&mut store, a, b, 6).unwrap(); // OP_OR
        assert_eq!((ri(&mut store, or, 1), ri(&mut store, or, 2), ri(&mut store, or, 3)), (1, 1, 1));
        // not {1,0,1} = {0,1,0}.
        let n = notf.call(&mut store, a).unwrap();
        assert_eq!((ri(&mut store, n, 1), ri(&mut store, n, 2), ri(&mut store, n, 3)), (0, 1, 0));
    }

    /// The matrix-constructor builtins: identity, diagonal, linspace.
    #[test]
    fn precompiled_runtime_array_constructors() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let mem = inst.exports.get_memory("memory").unwrap();
        let arr_new = inst.exports.get_typed_function::<(i32, i32, i32), i32>(&store, "rt_array_new").unwrap();
        let set_dim = inst.exports.get_typed_function::<(i32, i32, i32), ()>(&store, "rt_array_set_dim").unwrap();
        let elem_ptr = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_elem_ptr").unwrap();
        let dim = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_array_dim").unwrap();
        let identity = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_identity").unwrap();
        let diagonal = inst.exports.get_typed_function::<i32, i32>(&store, "rt_array_diagonal").unwrap();
        let linspace = inst.exports.get_typed_function::<(f64, f64, i32), i32>(&store, "rt_array_linspace").unwrap();
        let ri = |store: &mut Store, h: i32, k: i32| {
            let addr = elem_ptr.call(&mut *store, h, k).unwrap() as usize;
            let mut b = [0u8; 4];
            mem.view(&*store).read(addr as u64, &mut b).unwrap();
            i32::from_le_bytes(b)
        };
        let rf = |store: &mut Store, h: i32, k: i32| {
            let addr = elem_ptr.call(&mut *store, h, k).unwrap() as usize;
            let mut b = [0u8; 8];
            mem.view(&*store).read(addr as u64, &mut b).unwrap();
            f64::from_le_bytes(b)
        };

        // identity(3): 3x3, diagonal 1, rest 0 (row-major 1,0,0,0,1,0,0,0,1).
        let id = identity.call(&mut store, 3).unwrap();
        assert_eq!((dim.call(&mut store, id, 1).unwrap(), dim.call(&mut store, id, 2).unwrap()), (3, 3));
        assert_eq!((ri(&mut store, id, 1), ri(&mut store, id, 2), ri(&mut store, id, 5)), (1, 0, 1));

        // diagonal({7,8,9}): 3x3 with 7,8,9 on the diagonal.
        let v = arr_new.call(&mut store, 0, 1, 3).unwrap();
        set_dim.call(&mut store, v, 0, 3).unwrap();
        for (k, n) in [7i32, 8, 9].iter().enumerate() {
            let addr = elem_ptr.call(&mut store, v, k as i32 + 1).unwrap() as usize;
            mem.view(&store).write(addr as u64, &n.to_le_bytes()).unwrap();
        }
        let dg = diagonal.call(&mut store, v).unwrap();
        assert_eq!((ri(&mut store, dg, 1), ri(&mut store, dg, 5), ri(&mut store, dg, 9), ri(&mut store, dg, 2)), (7, 8, 9, 0));

        // linspace(0, 1, 5) = {0, 0.25, 0.5, 0.75, 1.0}.
        let ls = linspace.call(&mut store, 0.0, 1.0, 5).unwrap();
        assert_eq!((rf(&mut store, ls, 1), rf(&mut store, ls, 2), rf(&mut store, ls, 5)), (0.0, 0.25, 1.0));
    }

    /// The record runtime: a self-describing object with a String + Integer
    /// field. `rt_record_copy` must retain the (immutable) string and give
    /// independent scalar storage; `rt_record_release` must release the string
    /// once per record (no double free, no leak).
    #[test]
    fn precompiled_runtime_record() {
        let engine = wasmer::Engine::default();
        let module = wasmer::Module::from_binary(&engine, RUNTIME_WASM).unwrap();
        let mut store = wasmer::Store::new(engine.clone());
        let inst = wasmer::Instance::new(&mut store, &module, &wasmer::Imports::new()).unwrap();
        let mem = inst.exports.get_memory("memory").unwrap();
        let rec_new = inst.exports.get_typed_function::<(i32, i32), i32>(&store, "rt_record_new").unwrap();
        let rec_copy = inst.exports.get_typed_function::<i32, i32>(&store, "rt_record_copy").unwrap();
        let rec_release = inst.exports.get_typed_function::<i32, ()>(&store, "rt_record_release").unwrap();
        let int_string = inst.exports.get_typed_function::<i32, i32>(&store, "rt_int_string").unwrap();

        // Layout for `{String s; Integer k;}`: nheap=1, data_off=align8(8+8)=16,
        // s at +0 (4 bytes), k at +4 → size = 16 + align8(8) = 24.
        let w32 = |store: &mut Store, addr: usize, v: i32| mem.view(&*store).write(addr as u64, &v.to_le_bytes()).unwrap();
        let r32 = |store: &Store, addr: usize| {
            let mut b = [0u8; 4];
            mem.view(store).read(addr as u64, &mut b).unwrap();
            i32::from_le_bytes(b)
        };

        let r = rec_new.call(&mut store, 1, 24).unwrap();
        // Inline heap table: (EK_STR=3, field_off=0) at obj+8.
        w32(&mut store, r as usize + 8, 3);
        w32(&mut store, r as usize + 12, 0);
        let s = int_string.call(&mut store, 7).unwrap();
        w32(&mut store, r as usize + 16, s); // s field
        w32(&mut store, r as usize + 20, 42); // k field

        // Copy: independent scalar storage, shared (retained) string.
        let dup = rec_copy.call(&mut store, r).unwrap();
        assert_ne!(dup, r);
        assert_eq!(r32(&store, dup as usize + 16), s, "string field shared by retain");
        w32(&mut store, dup as usize + 20, 99); // mutate copy's k
        assert_eq!(r32(&store, r as usize + 20), 42, "original k unchanged");

        // Releasing both records releases the shared string exactly to zero
        // (a double free or use-after-free would trap).
        rec_release.call(&mut store, dup).unwrap();
        rec_release.call(&mut store, r).unwrap();
    }
}
