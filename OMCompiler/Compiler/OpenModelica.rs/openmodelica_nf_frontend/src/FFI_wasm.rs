//! The `external "C"` evaluation used where the native path (dlopen + libffi) is
//! not available: the wasm32 build of omc, and a native build without the `ffi`
//! feature. On wasm the library is a wasm shared library called through
//! [`marshal`]; elsewhere `callFunction` reports the path unavailable.

#![allow(non_snake_case, non_camel_case_types)]

/// Mirrors the native `FFI::ArgSpec`.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
#[repr(i32)]
pub enum ArgSpec {
    INPUT = 1,
    OUTPUT = 2,
    LOCAL = 3,
}
impl PartialOrd for ArgSpec {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> { Some(self.cmp(other)) }
}
impl Ord for ArgSpec {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering { (*self as i32).cmp(&(*other as i32)) }
}
impl Default for ArgSpec {
    fn default() -> Self { Self::INPUT }
}

#[cfg(target_arch = "wasm32")]
#[path = "FFI_wasm_marshal.rs"]
mod marshal;
#[cfg(target_arch = "wasm32")]
pub use marshal::callFunction;

#[cfg(not(target_arch = "wasm32"))]
pub fn callFunction(
    _fnHandle: i32,
    _args: metamodelica::Array<metamodelica::Ref<crate::NFExpression::NFExpression>>,
    _specs: metamodelica::Array<ArgSpec>,
    _returnType: metamodelica::Ref<crate::NFType::NFType>,
) -> metamodelica::Result<(
    metamodelica::Ref<crate::NFExpression::NFExpression>,
    metamodelica::List<metamodelica::Ref<crate::NFExpression::NFExpression>>,
)> {
    Err("FFI.callFunction: external \"C\" evaluation (dlopen+libffi) is unavailable on this target")
}
