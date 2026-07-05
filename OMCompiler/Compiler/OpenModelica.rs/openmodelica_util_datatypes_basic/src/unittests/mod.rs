//! Hand-written unit tests (in-crate, so they can use `pub(crate)` helpers).
//! Moved out of `tests/` (which compiles as a separate crate).
mod array_tests;
mod double_ended_tests;
mod list_tests;
mod mutable_cycle_drop_tests;
mod mutable_tests;
