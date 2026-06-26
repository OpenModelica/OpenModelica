// Engine registrations binding the `wasi_snapshot_preview1` imports of the
// standalone wasm-jit *command* module to the engine-independent `WasiCtx`
// (moved to `openmodelica_wasi::wasi`, the single FS surface over the in-memory
// store). wasmtime is the native default (and the only engine testable without a
// browser); wasmer drives the OMEdit worker (js backend) and native-wasmer.
//
// `WasiCtx`, `SliceMem`, the `GuestMem` trait and the WASI constants all come
// from `openmodelica_wasi::wasi`; each `mod` below re-imports them via
// `use super::*`.

use anyhow::{Result, anyhow};

pub use openmodelica_wasi::wasi::*;

// ─────────────────────────── wasmtime registration ───────────────────────────
//
// Native default engine. Host functions reach the guest memory and the fd table
// together via `Memory::data_and_store_mut`, which hands back
// `(&mut [u8], &mut WasiCtx)` from the `Caller`. `proc_exit` records its code and
// traps; `run_command` turns that trap back into the exit code.

#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
mod wasmtime_impl {
    use super::*;
    use wasmtime::Caller;

    type Linker = wasmtime::Linker<WasiCtx>;

    /// Borrow `(SliceMem, ctx)` from the caller, or return ERRNO_FAULT if the
    /// guest exports no `memory`.
    macro_rules! mem_ctx {
        ($caller:expr) => {{
            match $caller.get_export("memory").and_then(|e| e.into_memory()) {
                Some(m) => {
                    let (data, ctx) = m.data_and_store_mut(&mut $caller);
                    (SliceMem(data), ctx)
                }
                None => return ERRNO_FAULT,
            }
        }};
    }

    /// Register the `wasi_snapshot_preview1` imports into `linker`.
    pub fn add_to_linker(linker: &mut Linker) -> Result<()> {
        let m = "wasi_snapshot_preview1";
        let wt = |r: std::result::Result<&mut Linker, wasmtime::Error>| r.map(|_| ()).map_err(|e| anyhow!("{e:?}"));

        wt(linker.func_wrap(m, "fd_write", |mut c: Caller<'_, WasiCtx>, fd: i32, iovs: i32, n: i32, nw: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.fd_write(&mut mem, fd as u32, iovs as u32, n as u32, nw as u32)
        }))?;
        wt(linker.func_wrap(m, "fd_read", |mut c: Caller<'_, WasiCtx>, fd: i32, iovs: i32, n: i32, nr: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.fd_read(&mut mem, fd as u32, iovs as u32, n as u32, nr as u32)
        }))?;
        wt(linker.func_wrap(m, "fd_seek", |mut c: Caller<'_, WasiCtx>, fd: i32, off: i64, whence: i32, no: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.fd_seek(&mut mem, fd as u32, off, whence, no as u32)
        }))?;
        wt(linker.func_wrap(m, "path_open", |mut c: Caller<'_, WasiCtx>, dirfd: i32, dirflags: i32, path: i32, plen: i32, oflags: i32, rb: i64, ri: i64, fdflags: i32, ofd: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.path_open(&mut mem, dirfd as u32, dirflags as u32, path as u32, plen as u32, oflags, rb as u64, ri as u64, fdflags, ofd as u32)
        }))?;
        wt(linker.func_wrap(m, "path_filestat_get", |mut c: Caller<'_, WasiCtx>, dirfd: i32, flags: i32, path: i32, plen: i32, buf: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.path_filestat_get(&mut mem, dirfd as u32, flags as u32, path as u32, plen as u32, buf as u32)
        }))?;
        wt(linker.func_wrap(m, "fd_filestat_get", |mut c: Caller<'_, WasiCtx>, fd: i32, buf: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.fd_filestat_get(&mut mem, fd as u32, buf as u32)
        }))?;
        wt(linker.func_wrap(m, "fd_fdstat_get", |mut c: Caller<'_, WasiCtx>, fd: i32, buf: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.fd_fdstat_get(&mut mem, fd as u32, buf as u32)
        }))?;
        wt(linker.func_wrap(m, "fd_fdstat_set_flags", |_c: Caller<'_, WasiCtx>, _fd: i32, _flags: i32| -> i32 {
            ERRNO_SUCCESS
        }))?;
        wt(linker.func_wrap(m, "fd_close", |mut c: Caller<'_, WasiCtx>, fd: i32| -> i32 {
            c.data_mut().fd_close(fd as u32)
        }))?;
        wt(linker.func_wrap(m, "fd_prestat_get", |mut c: Caller<'_, WasiCtx>, fd: i32, buf: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.fd_prestat_get(&mut mem, fd as u32, buf as u32)
        }))?;
        wt(linker.func_wrap(m, "fd_prestat_dir_name", |mut c: Caller<'_, WasiCtx>, fd: i32, path: i32, plen: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.fd_prestat_dir_name(&mut mem, fd as u32, path as u32, plen as u32)
        }))?;
        wt(linker.func_wrap(m, "args_sizes_get", |mut c: Caller<'_, WasiCtx>, argc: i32, bs: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.args_sizes_get(&mut mem, argc as u32, bs as u32)
        }))?;
        wt(linker.func_wrap(m, "args_get", |mut c: Caller<'_, WasiCtx>, argv: i32, buf: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.args_get(&mut mem, argv as u32, buf as u32)
        }))?;
        wt(linker.func_wrap(m, "environ_sizes_get", |mut c: Caller<'_, WasiCtx>, count: i32, bs: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.environ_sizes_get(&mut mem, count as u32, bs as u32)
        }))?;
        wt(linker.func_wrap(m, "environ_get", |mut c: Caller<'_, WasiCtx>, env: i32, buf: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.environ_get(&mut mem, env as u32, buf as u32)
        }))?;
        wt(linker.func_wrap(m, "clock_time_get", |mut c: Caller<'_, WasiCtx>, id: i32, prec: i64, time: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.clock_time_get(&mut mem, id as u32, prec as u64, time as u32)
        }))?;
        wt(linker.func_wrap(m, "random_get", |mut c: Caller<'_, WasiCtx>, buf: i32, len: i32| -> i32 {
            let (mut mem, ctx) = mem_ctx!(c);
            ctx.random_get(&mut mem, buf as u32, len as u32)
        }))?;
        // `proc_exit` is a normal termination: record the code and unwind via a
        // wasmtime error, which `run_command` turns back into the exit code.
        wt(linker.func_wrap(m, "proc_exit", |mut c: Caller<'_, WasiCtx>, code: i32| -> std::result::Result<(), wasmtime::Error> {
            c.data_mut().exit_code = Some(code as u32);
            Err(wasmtime::Error::msg("wasi proc_exit"))
        }))?;
        Ok(())
    }

    /// Instantiate `wasm` as a WASI command module and call `_start`, returning
    /// the process exit code (0 if `_start` returns normally). Files land in
    /// `openmodelica_wasi`, with relative paths keyed under `cwd`.
    pub fn run_command(wasm: &[u8], cwd: &str, args: Vec<String>) -> Result<u32> {
        let engine = wasmtime::Engine::default();
        let module = wasmtime::Module::new(&engine, wasm).map_err(|e| anyhow!("{e:?}"))?;
        let mut linker = Linker::new(&engine);
        add_to_linker(&mut linker)?;
        let mut store = wasmtime::Store::new(&engine, WasiCtx::new(cwd, args));
        let instance = linker.instantiate(&mut store, &module).map_err(|e| anyhow!("{e:?}"))?;
        let start = instance
            .get_typed_func::<(), ()>(&mut store, "_start")
            .map_err(|e| anyhow!("module has no `_start`: {e:?}"))?;
        match start.call(&mut store, ()) {
            Ok(()) => Ok(0),
            // A `proc_exit` unwinds as an error after setting `exit_code`; that is
            // a normal termination, not a trap.
            Err(e) => match store.data().exit_code {
                Some(code) => Ok(code),
                None => Err(anyhow!("wasi command trapped: {e:?}")),
            },
        }
    }
}

// ──────────────────────────── wasmer registration ────────────────────────────
//
// Drives the OMEdit worker (wasmer's js backend) and native-wasmer. Host
// functions reach the guest memory + fd table via `FunctionEnvMut`'s
// `data_and_store_mut`; the memory is a `MemoryView` (copy-based, the only option
// on the js backend), set into the env after instantiation since the command
// module exports its own `memory`. `proc_exit` records its code and unwinds via
// a `RuntimeError`, which `run_command` turns back into the exit code.

#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
mod wasmer_impl {
    use super::*;
    use wasmer::{Function, FunctionEnv, FunctionEnvMut, Imports, Instance, Memory, Module, RuntimeError, Store};

    /// Host-function environment: the WASI state plus the guest memory, which is
    /// filled in after instantiation (the command module exports its own `memory`).
    pub struct Env {
        ctx: WasiCtx,
        memory: Option<Memory>,
    }

    /// A wasmer `MemoryView` as `GuestMem`. Reads/writes copy (the js backend has
    /// no Rust slice into linear memory), matching the trait's copy-based contract.
    struct ViewMem<'a>(wasmer::MemoryView<'a>);
    impl GuestMem for ViewMem<'_> {
        fn size(&self) -> usize {
            self.0.data_size() as usize
        }
        fn read(&self, addr: u32, buf: &mut [u8]) -> bool {
            self.0.read(addr as u64, buf).is_ok()
        }
        fn write(&mut self, addr: u32, bytes: &[u8]) -> bool {
            self.0.write(addr as u64, bytes).is_ok()
        }
    }

    /// Bind `$mem` (a `ViewMem` over the guest memory) and `$ctx` (`&mut WasiCtx`)
    /// from the function env, or `return ERRNO_FAULT` if memory is not set yet.
    macro_rules! view_ctx {
        ($env:ident, $mem:ident, $ctx:ident) => {
            let (data, store) = $env.data_and_store_mut();
            let memory = match &data.memory {
                Some(m) => m.clone(),
                None => return ERRNO_FAULT,
            };
            let mut $mem = ViewMem(memory.view(&store));
            let $ctx = &mut data.ctx;
        };
    }

    /// Register the `wasi_snapshot_preview1` imports into `imports`.
    pub fn add_to_imports(store: &mut Store, env: &FunctionEnv<Env>, imports: &mut Imports) {
        let m = "wasi_snapshot_preview1";
        let mut def = |name: &str, f: Function| {
            imports.define(m, name, f);
        };

        def("fd_write", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32, iovs: i32, n: i32, nw: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.fd_write(&mut mem, fd as u32, iovs as u32, n as u32, nw as u32)
        }));
        def("fd_read", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32, iovs: i32, n: i32, nr: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.fd_read(&mut mem, fd as u32, iovs as u32, n as u32, nr as u32)
        }));
        def("fd_seek", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32, off: i64, whence: i32, no: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.fd_seek(&mut mem, fd as u32, off, whence, no as u32)
        }));
        def("path_open", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, dirfd: i32, dirflags: i32, path: i32, plen: i32, oflags: i32, rb: i64, ri: i64, fdflags: i32, ofd: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.path_open(&mut mem, dirfd as u32, dirflags as u32, path as u32, plen as u32, oflags, rb as u64, ri as u64, fdflags, ofd as u32)
        }));
        def("path_filestat_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, dirfd: i32, flags: i32, path: i32, plen: i32, buf: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.path_filestat_get(&mut mem, dirfd as u32, flags as u32, path as u32, plen as u32, buf as u32)
        }));
        def("fd_filestat_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32, buf: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.fd_filestat_get(&mut mem, fd as u32, buf as u32)
        }));
        def("fd_fdstat_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32, buf: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.fd_fdstat_get(&mut mem, fd as u32, buf as u32)
        }));
        def("fd_fdstat_set_flags", Function::new_typed_with_env(store, env, |_env: FunctionEnvMut<Env>, _fd: i32, _flags: i32| -> i32 {
            ERRNO_SUCCESS
        }));
        def("fd_close", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32| -> i32 {
            env.data_mut().ctx.fd_close(fd as u32)
        }));
        def("fd_prestat_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32, buf: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.fd_prestat_get(&mut mem, fd as u32, buf as u32)
        }));
        def("fd_prestat_dir_name", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, fd: i32, path: i32, plen: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.fd_prestat_dir_name(&mut mem, fd as u32, path as u32, plen as u32)
        }));
        def("args_sizes_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, argc: i32, bs: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.args_sizes_get(&mut mem, argc as u32, bs as u32)
        }));
        def("args_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, argv: i32, buf: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.args_get(&mut mem, argv as u32, buf as u32)
        }));
        def("environ_sizes_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, count: i32, bs: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.environ_sizes_get(&mut mem, count as u32, bs as u32)
        }));
        def("environ_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, e: i32, buf: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.environ_get(&mut mem, e as u32, buf as u32)
        }));
        def("clock_time_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, id: i32, prec: i64, time: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.clock_time_get(&mut mem, id as u32, prec as u64, time as u32)
        }));
        def("random_get", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, buf: i32, len: i32| -> i32 {
            view_ctx!(env, mem, ctx);
            ctx.random_get(&mut mem, buf as u32, len as u32)
        }));
        def("proc_exit", Function::new_typed_with_env(store, env, |mut env: FunctionEnvMut<Env>, code: i32| -> std::result::Result<(), RuntimeError> {
            env.data_mut().ctx.exit_code = Some(code as u32);
            Err(RuntimeError::new("wasi proc_exit"))
        }));
    }

    /// Instantiate `wasm` as a WASI command module and call `_start`, returning
    /// the exit code (0 if `_start` returns normally). Files land in
    /// `openmodelica_wasi`, with relative paths keyed under `cwd`.
    pub fn run_command(wasm: &[u8], cwd: &str, args: Vec<String>) -> Result<u32> {
        // Match the engine/store construction the rest of the wasmer paths use
        // (works on both the native `sys` and the worker `js` backends, where
        // `Store::default()` is not available).
        let engine = wasmer::Engine::default();
        let module = Module::new(&engine, wasm).map_err(|e| anyhow!("{e:?}"))?;
        let mut store = Store::new(engine);
        let env = FunctionEnv::new(&mut store, Env { ctx: WasiCtx::new(cwd, args), memory: None });
        let mut imports = Imports::new();
        add_to_imports(&mut store, &env, &mut imports);
        let instance = Instance::new(&mut store, &module, &imports).map_err(|e| anyhow!("{e:?}"))?;
        let memory = instance.exports.get_memory("memory").map_err(|e| anyhow!("no `memory` export: {e:?}"))?.clone();
        env.as_mut(&mut store).memory = Some(memory);
        let start = instance
            .exports
            .get_typed_function::<(), ()>(&store, "_start")
            .map_err(|e| anyhow!("module has no `_start`: {e:?}"))?;
        match start.call(&mut store) {
            Ok(()) => Ok(0),
            Err(e) => match env.as_ref(&store).ctx.exit_code {
                Some(code) => Ok(code),
                None => Err(anyhow!("wasi command trapped: {e:?}")),
            },
        }
    }
}

#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
#[allow(unused_imports)] // wired into the run path in a later step
pub use wasmtime_impl::{add_to_linker, run_command};

#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
#[allow(unused_imports)] // wired into the run path in a later step
pub use wasmer_impl::{add_to_imports, run_command};

#[cfg(test)]
#[cfg(all(feature = "jit", not(target_arch = "wasm32")))]
mod tests {
    use super::*;
    use wasm_encoder as we;

    /// Build a tiny wasip1 command module that, from `_start`:
    ///   * `path_open`s a relative name for writing (CREAT|TRUNC, write rights),
    ///   * `fd_write`s a fixed payload,
    ///   * `fd_close`s (flushing to the VFS),
    ///   * `proc_exit(0)`.
    /// The data segment lays out, from address 0:
    ///   [0]   the path string         (`path_bytes`)
    ///   [64]  the payload string      (`data_bytes`)
    ///   [128] iovec { buf=64, len }
    ///   [136] scratch: opened-fd out  (u32)
    ///   [140] scratch: nwritten out   (u32)
    fn build_writer_module(path: &str, data: &str) -> Vec<u8> {
        use we::Instruction as I;
        const PATH_OFF: i32 = 0;
        const DATA_OFF: i32 = 64;
        const IOVEC_OFF: i32 = 128;
        const OPENED_FD_OFF: i32 = 136;
        const NWRITTEN_OFF: i32 = 140;
        const WASI: &str = "wasi_snapshot_preview1";

        let mut m = we::Module::new();

        // Types: each import + _start. Index them as we add.
        let mut types = we::TypeSection::new();
        // 0: path_open (i32 x4, i32 oflags, i64, i64, i32 fdflags, i32) -> i32  => 9 params
        types.ty().function(
            [we::ValType::I32, we::ValType::I32, we::ValType::I32, we::ValType::I32, we::ValType::I32, we::ValType::I64, we::ValType::I64, we::ValType::I32, we::ValType::I32],
            [we::ValType::I32],
        );
        // 1: fd_write (i32,i32,i32,i32) -> i32
        types.ty().function([we::ValType::I32; 4], [we::ValType::I32]);
        // 2: fd_close (i32) -> i32
        types.ty().function([we::ValType::I32], [we::ValType::I32]);
        // 3: proc_exit (i32) -> ()
        types.ty().function([we::ValType::I32], []);
        // 4: _start () -> ()
        types.ty().function([], []);
        m.section(&types);

        let mut imports = we::ImportSection::new();
        imports.import(WASI, "path_open", we::EntityType::Function(0));
        imports.import(WASI, "fd_write", we::EntityType::Function(1));
        imports.import(WASI, "fd_close", we::EntityType::Function(2));
        imports.import(WASI, "proc_exit", we::EntityType::Function(3));
        m.section(&imports);
        // Import function indices: path_open=0, fd_write=1, fd_close=2, proc_exit=3.

        let mut funcs = we::FunctionSection::new();
        funcs.function(4); // _start uses type 4
        m.section(&funcs);

        let mut mems = we::MemorySection::new();
        mems.memory(we::MemoryType { minimum: 1, maximum: None, memory64: false, shared: false, page_size_log2: None });
        m.section(&mems);

        let mut exports = we::ExportSection::new();
        exports.export("memory", we::ExportKind::Memory, 0);
        exports.export("_start", we::ExportKind::Func, 4); // after 4 imported funcs
        m.section(&exports);

        let mut code = we::CodeSection::new();
        let mut f = we::Function::new([]);
        // path_open(dirfd=3, dirflags=0, path=PATH_OFF, path_len, oflags=CREAT|TRUNC,
        //           rights_base=FD_WRITE, rights_inheriting=0, fdflags=0, &opened_fd)
        f.instruction(&I::I32Const(3));
        f.instruction(&I::I32Const(0));
        f.instruction(&I::I32Const(PATH_OFF));
        f.instruction(&I::I32Const(path.len() as i32));
        f.instruction(&I::I32Const(OFLAGS_CREAT | OFLAGS_TRUNC));
        f.instruction(&I::I64Const(RIGHTS_FD_WRITE as i64));
        f.instruction(&I::I64Const(0));
        f.instruction(&I::I32Const(0));
        f.instruction(&I::I32Const(OPENED_FD_OFF));
        f.instruction(&I::Call(0));
        f.instruction(&I::Drop);
        // fd_write(opened_fd, iovec=IOVEC_OFF, iovs_len=1, &nwritten)
        f.instruction(&I::I32Const(OPENED_FD_OFF));
        f.instruction(&I::I32Load(we::MemArg { offset: 0, align: 2, memory_index: 0 }));
        f.instruction(&I::I32Const(IOVEC_OFF));
        f.instruction(&I::I32Const(1));
        f.instruction(&I::I32Const(NWRITTEN_OFF));
        f.instruction(&I::Call(1));
        f.instruction(&I::Drop);
        // fd_close(opened_fd)
        f.instruction(&I::I32Const(OPENED_FD_OFF));
        f.instruction(&I::I32Load(we::MemArg { offset: 0, align: 2, memory_index: 0 }));
        f.instruction(&I::Call(2));
        f.instruction(&I::Drop);
        // proc_exit(0)
        f.instruction(&I::I32Const(0));
        f.instruction(&I::Call(3));
        f.instruction(&I::End);
        code.function(&f);
        m.section(&code);

        // Active data: path, payload, and the iovec {buf=DATA_OFF, len=data.len}.
        let mut iovec = Vec::new();
        iovec.extend_from_slice(&(DATA_OFF as u32).to_le_bytes());
        iovec.extend_from_slice(&(data.len() as u32).to_le_bytes());
        let off = |o: i32| we::ConstExpr::i32_const(o);
        let mut dsec = we::DataSection::new();
        dsec.active(0, &off(PATH_OFF), path.as_bytes().iter().copied());
        dsec.active(0, &off(DATA_OFF), data.as_bytes().iter().copied());
        dsec.active(0, &off(IOVEC_OFF), iovec.iter().copied());
        m.section(&dsec);

        m.finish()
    }

    #[test]
    fn wasi_writes_through_vfs() {
        let path = "wasi_shim_test_out.txt";
        let payload = "hello from wasi over the vfs\n";
        let wasm = build_writer_module(path, payload);
        let code = run_command(&wasm, "", vec!["sim".to_string()]).unwrap();
        assert_eq!(code, 0);
        let got = openmodelica_wasi::read(path).expect("file should exist in the VFS");
        assert_eq!(String::from_utf8(got).unwrap(), payload);
        openmodelica_wasi::remove(path);
    }

    #[test]
    fn wasi_writes_under_cwd_prefix() {
        let path = "res.mat";
        let payload = "MATDATA";
        let wasm = build_writer_module(path, payload);
        let code = run_command(&wasm, "rundir", vec!["sim".to_string()]).unwrap();
        assert_eq!(code, 0);
        // cwd "rundir" + relative "res.mat" -> VFS key "rundir/res.mat".
        let got = openmodelica_wasi::read("rundir/res.mat").expect("file under cwd prefix");
        assert_eq!(String::from_utf8(got).unwrap(), payload);
        openmodelica_wasi::remove("rundir/res.mat");
    }
}
