//! wasm stub for [`crate::FFI`]. The native module evaluates `external "C"`
//! functions at compile time by dlopen'ing the shared library and calling
//! through libffi; wasm has neither dlopen nor libffi, and evaluates functions
//! through the in-process wasm JIT instead. Only the `ArgSpec` enum (pure data,
//! shared by NFEvalFunction's argument mapping) and a `callFunction` that
//! reports the path unavailable are provided.

use std::sync::Arc;

use anyhow::{Result, bail};

use crate::NFExpression as Expression;
use crate::NFType as Type;

/// Argument passing mode for an external-function parameter. Mirrors the native
/// `FFI::ArgSpec`; kept on wasm because NFEvalFunction's argument mapping builds
/// `Array<ArgSpec>` regardless of whether the call can be performed.
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

pub fn callFunction(
    _fnHandle: i32,
    _args: metamodelica::Array<Arc<Expression::NFExpression>>,
    _specs: metamodelica::Array<ArgSpec>,
    _returnType: Arc<Type::NFType>,
) -> Result<(Arc<Expression::NFExpression>, Arc<metamodelica::List<Arc<Expression::NFExpression>>>)> {
    bail!("FFI.callFunction: external \"C\" evaluation (dlopen+libffi) is unavailable on wasm")
}
