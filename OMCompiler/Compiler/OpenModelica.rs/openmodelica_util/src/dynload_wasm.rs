//! wasm stub for [`crate::dynload`]. The native module dlopen()s shared objects
//! to run the `-d=gen` C/.so function-evaluation pipeline; wasm has no dynamic
//! loading, so every entry point reports the loader as unavailable. The wasm
//! build evaluates functions through the in-process wasm JIT
//! (`openmodelica_codegen_wasm_jit`) instead of this C/.so path.

use anyhow::{Result, bail};

pub fn load_library(_path: &str, _relative: bool, _debug: bool) -> Result<i32> {
    bail!("System.loadLibrary: dynamic loading (dlopen) is unavailable on wasm")
}

pub fn lookup_function(_lib: i32, _name: &str) -> Result<i32> {
    bail!("System.lookupFunction: dynamic loading is unavailable on wasm")
}

pub fn free_function(_func: i32, _debug: bool) -> Result<()> {
    // No handle was ever allocated; freeing nothing is a no-op.
    Ok(())
}

pub fn free_library(_lib: i32, _debug: bool) -> Result<()> {
    Ok(())
}

pub fn function_addr(_func: i32) -> Result<usize> {
    bail!("dynload::function_addr: dynamic loading is unavailable on wasm")
}

pub fn runtime_symbol(_name: &str) -> Option<usize> {
    None
}

pub fn thread_data() -> Result<usize> {
    bail!("dynload::thread_data: the dlopen'd MMC runtime is unavailable on wasm")
}
