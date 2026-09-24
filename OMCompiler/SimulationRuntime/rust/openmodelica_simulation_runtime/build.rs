//! Compiles `src/shim.c`, and derives the ABI layout checks
//! (`tests/abi_layout.rs`) from `src/abi.rs`.
//!
//! Every `#[repr(C)] pub struct` in the mirror becomes a `sizeof` check plus one
//! `offsetof` per field, and every `FLAG_*` constant an index check, each paired
//! with the same expression in C. Generating them keeps the check list from
//! drifting away from the mirror it is checking.

use std::fmt::Write as _;
use std::path::PathBuf;

/// libOpenModelicaRuntimeC, which owns the state this runtime shares with the
/// generated code. Only an ELF `.so` may leave those to bind from the executable
/// at load, so `--no-undefined` holds it to what a DLL and a dylib require.
fn link_runtime_c() {
    println!("cargo:rerun-if-env-changed=OMC_RUNTIME_C_DIR");
    println!("cargo:rerun-if-env-changed=OMC_RUNTIME_C_LINK");
    println!("cargo:rerun-if-env-changed=OMC_RUNTIME_C_DEF");
    // MSVC links the static archive *into* SimulationRuntimeC.dll, so absorb it
    // the same way. CMake names its dependencies, which an archive lacks.
    if let Ok(libs) = std::env::var("OMC_RUNTIME_C_LINK") {
        for lib in libs.split('|').filter(|s| !s.is_empty()) {
            println!("cargo:rustc-cdylib-link-arg={lib}");
        }
        // Absorbing it leaves its symbols unexported, and --simCodeTarget=C
        // links this cdylib rather than SimulationRuntimeC.dll. reexport_def.cmake
        // derives /EXPORT: switches from the archive; they have to be a response
        // file because rustc writes the cdylib's own .def and ours would replace it.
        if let Ok(rsp) = std::env::var("OMC_RUNTIME_C_DEF") {
            println!("cargo:rustc-cdylib-link-arg=@{rsp}");
        }
        return;
    }
    let Ok(dir) = std::env::var("OMC_RUNTIME_C_DIR") else { return };
    println!("cargo:rustc-link-search=native={dir}");
    println!("cargo:rustc-link-lib=dylib=OpenModelicaRuntimeC");
    if !matches!(std::env::var("CARGO_CFG_TARGET_OS").as_deref(), Ok("windows" | "macos" | "ios")) {
        println!("cargo:rustc-cdylib-link-arg=-Wl,--no-undefined");
    }
}

/// BLAS and LAPACK, which a dylib must resolve where an ELF `.so` leaves them to
/// the executable. macOS ships them in Accelerate, under the same Fortran names.
fn link_blas() {
    if !matches!(std::env::var("CARGO_CFG_TARGET_OS").as_deref(), Ok("macos" | "ios")) {
        return;
    }
    // Cross-compiling the frameworks live in the SDK, and only the compiler has
    // been told where that is (-iframework), not the linker.
    println!("cargo:rerun-if-env-changed=SDKROOT");
    if let Ok(sdk) = std::env::var("SDKROOT") {
        println!("cargo:rustc-cdylib-link-arg=-F{sdk}/System/Library/Frameworks");
    }
    println!("cargo:rustc-cdylib-link-arg=-framework");
    println!("cargo:rustc-cdylib-link-arg=Accelerate");
}

/// The architectures src/shim_export.rs has a tail jump for. There Rust owns
/// the public names of shim.c's variadic entry points and rustc exports them
/// like any other, which is what the version script below is for elsewhere.
fn shim_trampolines() -> bool {
    println!("cargo:rustc-check-cfg=cfg(shim_trampolines)");
    let arch = std::env::var("CARGO_CFG_TARGET_ARCH").unwrap_or_default();
    let ok = matches!(arch.as_str(), "x86_64" | "x86" | "aarch64" | "arm" | "riscv64");
    if ok {
        println!("cargo:rustc-cfg=shim_trampolines");
    }
    ok
}

/// The variadic entry points src/shim.c defines.
const SHIM_ENTRY_POINTS: &[&str] = &[
    "omc_assert_simulation",
    "omc_assert_simulation_withEquationIndexes",
    "omc_assert_warning_simulation",
    "omc_assert_warning_simulation_withEquationIndexes",
    "omc_terminate_simulation",
];

/// A cdylib exports only the symbols Rust itself defines, so without this the
/// generated model does not link. Only for the architectures `shim_trampolines`
/// does not cover: ld before 2.41 rejects this version script beside the one
/// rustc writes for its own exports.
fn export_shim_entry_points() {
    let out = PathBuf::from(std::env::var("OUT_DIR").expect("OUT_DIR"));
    match std::env::var("CARGO_CFG_TARGET_OS").as_deref() {
        // link.exe honours the objects' __declspec(dllexport) alongside its /DEF.
        Ok("windows") => {}
        Ok("macos" | "ios") => {
            let path = out.join("shim_exports.txt");
            let names: String = SHIM_ENTRY_POINTS.iter().map(|s| format!("_{s}\n")).collect();
            std::fs::write(&path, names).expect("write the export list");
            println!("cargo:rustc-cdylib-link-arg=-Wl,-exported_symbols_list,{}", path.display());
        }
        _ => {
            let path = out.join("shim_exports.map");
            let names: String = SHIM_ENTRY_POINTS.iter().map(|s| format!("  {s};\n")).collect();
            std::fs::write(&path, format!("{{\n global:\n{names}}};\n")).expect("write the map");
            println!("cargo:rustc-cdylib-link-arg=-Wl,--version-script={}", path.display());
        }
    }
}

/// Mirror types that are not a C struct of the same name, or whose fields the C
/// side does not have under those names.
const SKIP: &[&str] = &["rtclock_t", "threadData_t"];
/// `field in Rust` -> `field in C`, where the C name is a Rust keyword.
const RENAME: &[(&str, &str)] = &[("ty", "type")];
/// Mirrors of a plain C `struct` with no typedef, which C must name with the tag.
const C_TAG: &[&str] = &["OpenModelicaGeneratedFunctionCallbacks"];

/// The FMU flavour of this runtime: an archive a source-code FMU links, where the
/// C half is the FMU's own minimal one. What it cannot rely on there is behind
/// `cfg(omc_fmi_runtime)`.
fn fmi_runtime_cfg() -> bool {
    println!("cargo:rustc-check-cfg=cfg(omc_fmi_runtime)");
    println!("cargo:rerun-if-env-changed=OMC_SIMRT_FMI");
    let fmi = std::env::var("OMC_SIMRT_FMI").is_ok_and(|v| v != "0" && !v.is_empty());
    if fmi {
        println!("cargo:rustc-cfg=omc_fmi_runtime");
    }
    fmi
}

/// The attribute that takes a mirror item out of the FMU flavour. `build.rs` reads
/// `abi.rs` as text, so it has to honour the same gate the compiler will.
const FMI_GATE: &str = "#[cfg(not(omc_fmi_runtime))]";

fn main() {
    let fmi = fmi_runtime_cfg();
    println!("cargo:rerun-if-changed=src/shim.c");
    let trampolines = shim_trampolines();
    let mut shim = cc::Build::new();
    shim.file("src/shim.c").warnings(true);
    if trampolines {
        shim.define("OMR_SHIM_TRAMPOLINES", None);
    }
    shim.compile("omc_rust_runtime_shim");
    if !trampolines {
        export_shim_entry_points();
    }
    link_runtime_c();
    link_blas();
    println!("cargo:rerun-if-changed=src/abi.rs");
    println!("cargo:rerun-if-env-changed=OMC_SIMRT_INCLUDE_DIRS");
    let src = std::fs::read_to_string("src/abi.rs").expect("src/abi.rs");
    let mut out = String::from(
        "/// (C expression, the mirror's value). Generated by build.rs from src/abi.rs.\n\
         fn checks() -> Vec<(String, u64)> {\n  let mut v: Vec<(String, u64)> = Vec::new();\n",
    );
    let mut lines = src.lines().peekable();
    let mut gated = false;
    while let Some(line) = lines.next() {
        if line.trim() == FMI_GATE {
            gated = true;
            continue;
        }
        if line.trim() != "#[repr(C)]" {
            if !line.trim().starts_with("#[") {
                gated = false;
            }
            continue;
        }
        // Skip the derives between the attribute and the item.
        let mut head = lines.next().unwrap_or("");
        while head.trim_start().starts_with("#[") {
            head = lines.next().unwrap_or("");
        }
        let struct_gated = core::mem::take(&mut gated);
        let Some(name) = head.trim().strip_prefix("pub struct ").and_then(|s| s.split_whitespace().next())
        else {
            continue;
        };
        if !head.trim_end().ends_with('{') || SKIP.contains(&name) || (fmi && struct_gated) {
            continue;
        }
        let c_name = if C_TAG.contains(&name) { format!("struct {name}") } else { name.to_string() };
        let _ = writeln!(
            out,
            "  v.push((\"sizeof({c_name})\".into(), core::mem::size_of::<abi::{name}>() as u64));"
        );
        // Fields end at the closing brace; `pub <name>:` at one indent level.
        let mut depth = 1usize;
        let mut field_gated = false;
        for body in lines.by_ref() {
            depth += body.matches('{').count();
            depth -= body.matches('}').count();
            if depth == 0 {
                break;
            }
            let t = body.trim();
            if t == FMI_GATE {
                field_gated = true;
                continue;
            }
            let Some(field) = t.strip_prefix("pub ").and_then(|s| s.split(':').next()) else { continue };
            if fmi && core::mem::take(&mut field_gated) {
                continue;
            }
            field_gated = false;
            if !field.chars().all(|c| c.is_alphanumeric() || c == '_') || field.is_empty() {
                continue;
            }
            let c_field = RENAME.iter().find(|(r, _)| *r == field).map_or(field, |(_, c)| *c);
            let _ = writeln!(
                out,
                "  v.push((\"offsetof({c_name}, {c_field})\".into(), core::mem::offset_of!(abi::{name}, {field}) as u64));"
            );
        }
    }
    // The `enum _FLAG` indices `omc_flag`/`omc_flagValue` are addressed with, the
    // `errorStage` values `threadData->currentErrorStage` takes, and the solver
    // enumerations `simulationInfo` holds.
    for line in src.lines() {
        let t = line.trim();
        for (prefix, ty) in [
            ("pub const FLAG_", ": usize = "),
            ("pub const ERROR_", ": i32 = "),
            ("pub const LS_", ": c_int = "),
            ("pub const LSS_", ": c_int = "),
            ("pub const NLS_", ": c_int = "),
        ] {
            let Some(rest) = t.strip_prefix(prefix) else { continue };
            let Some((name, value)) = rest.split_once(ty) else { continue };
            let value = value.trim_end_matches(';');
            let c_name = &prefix["pub const ".len()..];
            let _ = writeln!(out, "  v.push((\"{c_name}{name}\".into(), {value}u64));");
        }
    }
    out.push_str("  v\n}\n");
    let path = PathBuf::from(std::env::var("OUT_DIR").expect("OUT_DIR")).join("abi_layout_checks.rs");
    std::fs::write(&path, out).expect("write the layout checks");
}
