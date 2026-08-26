//! The guest side of `om:ext/native`: the generated stub for an `external "C"`
//! function no wasm library defines lands here with its frame, and the call
//! crosses to the host as copied values (`openmodelica_ext_native_marshal`).

use alloc::vec::Vec;

use openmodelica_codegen_wasm_jit_runtime as rt;
use openmodelica_ext_native_marshal::{self as marshal, Guest, Table, Value};

use crate::om::ext::native;

unsafe extern "C" {
    fn rt_ext_error(msg: u32) -> !;
}

struct Memory;

impl Guest for Memory {
    fn load_i32(&self, addr: u32) -> i32 {
        unsafe { (addr as *const i32).read_unaligned() }
    }
    fn load_f64(&self, addr: u32) -> f64 {
        unsafe { (addr as *const f64).read_unaligned() }
    }
    fn store_i32(&mut self, addr: u32, v: i32) {
        unsafe { (addr as *mut i32).write_unaligned(v) }
    }
    fn store_f64(&mut self, addr: u32, v: f64) {
        unsafe { (addr as *mut f64).write_unaligned(v) }
    }
    fn read(&self, addr: u32, len: u32) -> Vec<u8> {
        unsafe { core::slice::from_raw_parts(addr as *const u8, len as usize) }.to_vec()
    }
    fn write(&mut self, addr: u32, bytes: &[u8]) {
        unsafe { core::ptr::copy_nonoverlapping(bytes.as_ptr(), addr as *mut u8, bytes.len()) }
    }
    fn str_len(&self, handle: u32) -> u32 {
        rt::rt_str_len(handle)
    }
    fn str_data(&self, handle: u32) -> u32 {
        rt::rt_str_data(handle)
    }
    fn array_total(&self, handle: u32) -> u32 {
        rt::rt_array_total(handle)
    }
    fn array_data(&self, handle: u32) -> u32 {
        rt::rt_array_data(handle)
    }
    fn alloc(&mut self, len: u32) -> u32 {
        rt::rt_alloc(len)
    }
    fn free(&mut self, addr: u32) {
        rt::rt_free(addr)
    }
}

struct State {
    table: Option<(u32, Table)>,
    /// C strings the previous call handed the kernel, which copied them out
    /// before making this one.
    scratch: Vec<u32>,
}

static mut STATE: State = State { table: None, scratch: Vec::new() };

fn fail(msg: &str) -> ! {
    let mut c = Vec::with_capacity(msg.len() + 1);
    c.extend_from_slice(msg.as_bytes());
    c.push(0);
    unsafe { rt_ext_error(c.as_ptr() as u32) }
}

fn to_wit(v: Value) -> native::Value {
    match v {
        Value::Int(i) => native::Value::Int(i),
        Value::Real(r) => native::Value::Real(r),
        Value::Str(s) => native::Value::Str(s),
        Value::Bytes(b) => native::Value::Bytes(b),
        Value::Handle(h) => native::Value::Handle(h),
    }
}

fn from_wit(v: native::Value) -> Value {
    match v {
        native::Value::Int(i) => Value::Int(i),
        native::Value::Real(r) => Value::Real(r),
        native::Value::Str(s) => Value::Str(s),
        native::Value::Bytes(b) => Value::Bytes(b),
        native::Value::Handle(h) => Value::Handle(h),
    }
}

/// Called by the stub for function `index` of the table at `table`, with its
/// parameters in `frame` (see `openmodelica_ext_native_marshal`).
#[unsafe(no_mangle)]
pub extern "C" fn om_ext_native_call(index: u32, frame: u32, table: u32, table_len: u32) {
    let state = unsafe { &mut *core::ptr::addr_of_mut!(STATE) };
    let mut mem = Memory;
    for p in state.scratch.drain(..) {
        mem.free(p);
    }
    if state.table.as_ref().is_none_or(|(at, _)| *at != table) {
        let text = mem.read(table, table_len);
        match marshal::parse(core::str::from_utf8(&text).unwrap_or("")) {
            Ok(t) => state.table = Some((table, t)),
            Err(e) => fail(&e),
        }
    }
    let Some(sig) = state.table.as_ref().and_then(|(_, t)| t.fns.get(index as usize)) else {
        fail("native externals: the stub names a function the table does not have");
    };
    let args = match marshal::gather(sig, frame, &mem) {
        Ok(a) => a,
        Err(e) => fail(&e),
    };
    let wit_args: Vec<native::Value> = args.into_iter().map(to_wit).collect();
    match native::call(index, &wit_args) {
        Ok(results) => {
            let results: Vec<Value> = results.into_iter().map(from_wit).collect();
            if let Err(e) = marshal::scatter(sig, frame, &results, &mut mem, &mut state.scratch) {
                fail(&e);
            }
        }
        Err(e) => fail(&e),
    }
}
