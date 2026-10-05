//! The public names of the variadic entry points in `shim.c`.
//!
//! A cdylib exports only what Rust defines, and the second version script that
//! would add the C ones is one ld before 2.41 refuses to combine with rustc's
//! own. So Rust owns the names and tail-jumps into C, which leaves the
//! arguments, varargs included, where the caller put them. `build.rs` picks the
//! architectures this has an instruction for and renames the C side to match.
#![allow(non_snake_case)]

#[cfg(any(target_arch = "x86_64", target_arch = "x86"))]
macro_rules! tail_jump {
    () => {
        "jmp {0}"
    };
}
#[cfg(any(target_arch = "aarch64", target_arch = "arm"))]
macro_rules! tail_jump {
    () => {
        "b {0}"
    };
}
#[cfg(target_arch = "riscv64")]
macro_rules! tail_jump {
    () => {
        "tail {0}"
    };
}

macro_rules! shim_entry {
    ($public:ident, $target:ident) => {
        unsafe extern "C" {
            fn $target();
        }
        #[unsafe(naked)]
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $public() {
            core::arch::naked_asm!(concat!(tail_jump!()), sym $target);
        }
    };
}

shim_entry!(omc_assert_simulation, omr_shim_assert_simulation);
shim_entry!(
    omc_assert_simulation_withEquationIndexes,
    omr_shim_assert_simulation_withEquationIndexes
);
shim_entry!(omc_assert_warning_simulation, omr_shim_assert_warning_simulation);
shim_entry!(
    omc_assert_warning_simulation_withEquationIndexes,
    omr_shim_assert_warning_simulation_withEquationIndexes
);
shim_entry!(omc_terminate_simulation, omr_shim_terminate_simulation);
