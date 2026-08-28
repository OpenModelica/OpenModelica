//! The run's linear memory, whichever kind wasmtime gave it: the plain runtime's
//! own memory, or the `SharedMemory` the parmodauto runtime and its per-thread
//! worker instances import. Same surface as `wasmtime::Memory` for the host code
//! that marshals through it.

use wasmtime::{AsContext, AsContextMut, Extern, Memory, SharedMemory, StoreContext, StoreContextMut};

#[derive(Clone)]
pub enum SimMem {
    Plain(Memory),
    Shared(SharedMemory),
}

/// Access to a shared memory is a plain slice here: the host reads and writes it
/// only while no worker thread runs, and the workers only through wasm.
fn shared_slice(m: &SharedMemory) -> &[u8] {
    let d = m.data();
    unsafe { core::slice::from_raw_parts(d.as_ptr().cast::<u8>(), d.len()) }
}

#[allow(clippy::mut_from_ref)]
fn shared_slice_mut(m: &SharedMemory) -> &mut [u8] {
    let d = m.data();
    unsafe { core::slice::from_raw_parts_mut(d.as_ptr().cast::<u8>().cast_mut(), d.len()) }
}

impl SimMem {
    pub fn from_extern(e: Extern) -> Option<SimMem> {
        match e {
            Extern::Memory(m) => Some(SimMem::Plain(m)),
            Extern::SharedMemory(m) => Some(SimMem::Shared(m)),
            _ => None,
        }
    }

    pub fn to_extern(&self) -> Extern {
        match self {
            SimMem::Plain(m) => Extern::Memory(*m),
            SimMem::Shared(m) => Extern::SharedMemory(m.clone()),
        }
    }

    pub fn is_shared(&self) -> bool {
        matches!(self, SimMem::Shared(_))
    }

    pub fn data<'a, T: 'static>(&'a self, store: impl Into<StoreContext<'a, T>>) -> &'a [u8] {
        match self {
            SimMem::Plain(m) => m.data(store),
            SimMem::Shared(m) => shared_slice(m),
        }
    }

    pub fn data_mut<'a, T: 'static>(&'a self, store: impl Into<StoreContextMut<'a, T>>) -> &'a mut [u8] {
        match self {
            SimMem::Plain(m) => m.data_mut(store),
            SimMem::Shared(m) => shared_slice_mut(m),
        }
    }

    pub fn data_and_store_mut<'a, T: 'static>(&'a self, store: impl Into<StoreContextMut<'a, T>>) -> (&'a mut [u8], &'a mut T) {
        match self {
            SimMem::Plain(m) => m.data_and_store_mut(store),
            SimMem::Shared(m) => {
                let mut store = store.into();
                // The memory is not part of the store, so the two borrows are disjoint.
                let data = unsafe { &mut *(store.data_mut() as *mut T) };
                (shared_slice_mut(m), data)
            }
        }
    }

    pub fn data_size(&self, store: impl AsContext) -> usize {
        match self {
            SimMem::Plain(m) => m.data_size(store),
            SimMem::Shared(m) => m.data_size(),
        }
    }

    pub fn read(&self, store: impl AsContext, offset: usize, buf: &mut [u8]) -> Result<(), &'static str> {
        let store = store.as_context();
        let src = self.data(&store).get(offset..).and_then(|s| s.get(..buf.len())).ok_or("read outside linear memory")?;
        buf.copy_from_slice(src);
        Ok(())
    }

    pub fn write(&self, mut store: impl AsContextMut, offset: usize, buf: &[u8]) -> Result<(), &'static str> {
        let mut ctx = store.as_context_mut();
        let dst = self.data_mut(&mut ctx).get_mut(offset..).and_then(|s| s.get_mut(..buf.len())).ok_or("write outside linear memory")?;
        dst.copy_from_slice(buf);
        Ok(())
    }
}

/// `wasm` with its memory import (or definition) retyped as shared, 4 GiB maximum:
/// a PIC library built for a plain memory, instantiated over the parmodauto
/// runtime's shared one. Plain loads and stores are valid on a shared memory, so
/// nothing else about the module changes.
pub fn retype_memory_shared(wasm: &[u8]) -> Result<Vec<u8>, String> {
    use wasm_encoder::reencode::{self, Reencode};
    struct Shared;
    impl Reencode for Shared {
        type Error = core::convert::Infallible;
        fn memory_type(
            &mut self,
            ty: wasmparser::MemoryType,
        ) -> std::result::Result<wasm_encoder::MemoryType, reencode::Error<Self::Error>> {
            let mut t = reencode::utils::memory_type(self, ty);
            t.shared = true;
            t.maximum.get_or_insert(65536);
            Ok(t)
        }
    }
    let mut m = wasm_encoder::Module::new();
    Shared
        .parse_core_module(&mut m, wasmparser::Parser::new(0), wasm)
        .map_err(|e| format!("cannot retype the memory import as shared: {e}"))?;
    Ok(m.finish())
}
