//! Hand-written unit tests (in-crate, so they can use `pub(crate)` helpers).
//! Moved out of `tests/` (which compiles as a separate crate).
mod avl_set_string_tests;
mod avl_tree_string_tests;
mod diff_algorithm_tests;
mod flags_util_tests;
mod hash_set_string_tests;
mod sb_tests;
mod string_allocator_tests;
mod string_util_tests;
mod unordered_map_tests;
mod unordered_set_tests;
mod util_tests;
