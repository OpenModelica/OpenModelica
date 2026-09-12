//! Byte-level rewrites of emitted wasm modules: `dylink.0` sections, import
//! module renames, dropping imports/exports, scanning imports and exports.

use super::*;

/// Renames the model's `rt`/`ext` import modules → `env`, the dylink convention
/// `wit_component::Linker` resolves against (so `ext.<fn>` binds to the
/// ModelicaExternalC side module's export `<fn>`).
struct RtToEnv;

impl RtToEnv {
    fn rename(module: &str) -> &str {
        if module == "rt" || module == "ext" { "env" } else { module }
    }
}

impl wasm_encoder::reencode::Reencode for RtToEnv {
    type Error = core::convert::Infallible;
    /// `parse_imports`, not `parse_import`: only this one is on the section's
    /// dispatch path (`parse_import` is a convenience wrapper nothing calls).
    fn parse_imports(
        &mut self,
        imports: &mut wasm_encoder::ImportSection,
        group: wasmparser::Imports<'_>,
    ) -> core::result::Result<(), wasm_encoder::reencode::Error<Self::Error>> {
        let group = match group {
            wasmparser::Imports::Single(n, import) => wasmparser::Imports::Single(
                n,
                wasmparser::Import { module: Self::rename(import.module), ..import },
            ),
            wasmparser::Imports::Compact1 { module, items } => {
                wasmparser::Imports::Compact1 { module: Self::rename(module), items }
            }
            wasmparser::Imports::Compact2 { module, ty, names } => {
                wasmparser::Imports::Compact2 { module: Self::rename(module), ty, names }
            }
        };
        wasm_encoder::reencode::utils::parse_imports(self, imports, group)
    }
}

fn uleb(v: u32, out: &mut Vec<u8>) {
    let mut v = v;
    loop {
        let mut b = (v & 0x7f) as u8;
        v >>= 7;
        if v != 0 {
            b |= 0x80;
        }
        out.push(b);
        if v == 0 {
            break;
        }
    }
}

/// Splice a `dylink.0` section after the 8-byte header, marking the module a
/// shared-everything library. MEM_INFO is all-zero because the model has no
/// static data (its only data segment is passive) and no own table.
fn add_dylink0(module: &[u8]) -> Vec<u8> {
    add_dylink0_sized(module, 0, 0)
}

/// `mem_size` bytes of `__memory_base`-relative data, `mem_align` its log2 alignment.
pub(super) fn add_dylink0_sized(module: &[u8], mem_size: u32, mem_align: u32) -> Vec<u8> {
    let mut meminfo = Vec::new();
    for v in [mem_size, mem_align, 0, 0] {
        uleb(v, &mut meminfo); // mem_size, mem_align, table_size, table_align
    }
    let mut sub = Vec::new();
    sub.push(1u8); // WASM_DYLINK_MEM_INFO
    uleb(meminfo.len() as u32, &mut sub);
    sub.extend_from_slice(&meminfo);
    let mut content = Vec::new();
    uleb(8, &mut content);
    content.extend_from_slice(b"dylink.0");
    content.extend_from_slice(&sub);
    let mut sec = Vec::new();
    sec.push(0u8); // custom section id
    uleb(content.len() as u32, &mut sec);
    sec.extend_from_slice(&content);
    let mut out = Vec::with_capacity(module.len() + sec.len());
    out.extend_from_slice(&module[..8]);
    out.extend_from_slice(&sec);
    out.extend_from_slice(&module[8..]);
    out
}

const NATIVE_EXT_ABSENT: &str = "om_ext_native_absent";

/// The me_cs adapter always imports `om:ext/native@0.1.0`, but only an export whose
/// `external "C"` a host must serve reaches it, and a component importing it is one
/// no fmi-ls-wasm host will instantiate. Point it at [`native_ext_absent`] instead.
pub(super) fn drop_native_ext_import(adapter: &[u8]) -> Option<Vec<u8>> {
    const MODULE: &str = "om:ext/native@0.1.0";
    struct Redirect;
    impl wasm_encoder::reencode::Reencode for Redirect {
        type Error = core::convert::Infallible;
        fn parse_imports(
            &mut self,
            imports: &mut we::ImportSection,
            group: wasmparser::Imports<'_>,
        ) -> core::result::Result<(), wasm_encoder::reencode::Error<Self::Error>> {
            use wasmparser::Imports;
            let single = |ty| wasmparser::Import { module: "env", name: NATIVE_EXT_ABSENT, ty };
            match group {
                Imports::Single(n, import) if import.module == MODULE => {
                    let group = Imports::Single(n, single(import.ty));
                    wasm_encoder::reencode::utils::parse_imports(self, imports, group)
                }
                Imports::Compact1 { module: MODULE, items } => {
                    for item in items {
                        let group = Imports::Single(0, single(item?.ty));
                        wasm_encoder::reencode::utils::parse_imports(self, imports, group)?;
                    }
                    Ok(())
                }
                Imports::Compact2 { module: MODULE, ty, names } => {
                    for _ in names {
                        let group = Imports::Single(0, single(ty));
                        wasm_encoder::reencode::utils::parse_imports(self, imports, group)?;
                    }
                    Ok(())
                }
                group => wasm_encoder::reencode::utils::parse_imports(self, imports, group),
            }
        }
    }
    if !wasm_imports_module(adapter, MODULE) {
        return None;
    }
    use wasm_encoder::reencode::Reencode;
    let mut m = we::Module::new();
    Redirect.parse_core_module(&mut m, wasmparser::Parser::new(0), adapter).ok()?;
    Some(m.finish())
}

/// Defines [`NATIVE_EXT_ABSENT`] as a trap: its only caller is the stub of a
/// host-served `external "C"`, which such an export has none of.
pub(super) fn native_ext_absent() -> Vec<u8> {
    let mut types = we::TypeSection::new();
    types.ty().function([we::ValType::I32; 4], []);
    let mut functions = we::FunctionSection::new();
    functions.function(0);
    let mut exports = we::ExportSection::new();
    exports.export(NATIVE_EXT_ABSENT, we::ExportKind::Func, 0);
    let mut code = we::CodeSection::new();
    let mut f = we::Function::new(Vec::<(u32, we::ValType)>::new());
    f.instruction(&we::Instruction::Unreachable);
    f.instruction(&we::Instruction::End);
    code.function(&f);
    let mut m = we::Module::new();
    m.section(&types).section(&functions).section(&exports).section(&code);
    add_dylink0(&m.finish())
}

fn wasm_imports_module(wasm: &[u8], module: &str) -> bool {
    use wasmparser::Imports;
    wasmparser::Parser::new(0).parse_all(wasm).flatten().any(|payload| {
        let wasmparser::Payload::ImportSection(reader) = payload else { return false };
        reader.into_iter().flatten().any(|group| match group {
            Imports::Single(_, imp) => imp.module == module,
            Imports::Compact1 { module: m, .. } | Imports::Compact2 { module: m, .. } => m == module,
        })
    })
}

/// Turn an emitted model kernel module into a dylink side module.
pub(super) fn model_to_dylink(model_wasm: &[u8]) -> Result<Vec<u8>> {
    use wasm_encoder::reencode::Reencode;
    let mut re = RtToEnv;
    let mut m = wasm_encoder::Module::new();
    re.parse_core_module(&mut m, wasmparser::Parser::new(0), model_wasm)
        .map_err(|_| "CodegenWasmJit: cannot reencode model module to dylink")?;
    Ok(add_dylink0(&m.finish()))
}

/// `wit_component` rejects a library exporting both `__wasm_call_ctors` and
/// `_initialize`, which is what clang's reactor mode emits. Keep the dylink
/// convention. `openmodelica_wasi_libc` does this to ModelicaExternalC at build
/// time; a model's own `Library=`/`Include=` arrives already built.
pub(super) fn drop_redundant_initialize(lib: &[u8]) -> Vec<u8> {
    let mut has_ctors = false;
    let mut has_initialize = false;
    for payload in wasmparser::Parser::new(0).parse_all(lib).flatten() {
        if let wasmparser::Payload::ExportSection(reader) = payload {
            for e in reader.into_iter().flatten() {
                has_ctors |= e.name == "__wasm_call_ctors";
                has_initialize |= e.name == "_initialize";
            }
        }
    }
    if !(has_ctors && has_initialize) {
        return lib.to_vec();
    }
    struct DropInitialize;
    impl wasm_encoder::reencode::Reencode for DropInitialize {
        type Error = std::convert::Infallible;
        fn parse_export_section(
            &mut self,
            exports: &mut wasm_encoder::ExportSection,
            section: wasmparser::ExportSectionReader<'_>,
        ) -> Result<(), wasm_encoder::reencode::Error<Self::Error>> {
            for e in section {
                let e = e?;
                if e.name != "_initialize" {
                    exports.export(e.name, self.export_kind(e.kind)?, self.external_index(e.kind, e.index)?);
                }
            }
            Ok(())
        }
    }
    use wasm_encoder::reencode::Reencode;
    let mut re = DropInitialize;
    let mut m = wasm_encoder::Module::new();
    match re.parse_core_module(&mut m, wasmparser::Parser::new(0), lib) {
        Ok(()) => m.finish(),
        Err(_) => lib.to_vec(),
    }
}

/// The `external` functions (import module `ext`) the model calls.
fn external_imports(model_wasm: &[u8]) -> Vec<String> {
    use wasmparser::Imports;
    let mut out = Vec::new();
    for payload in wasmparser::Parser::new(0).parse_all(model_wasm).flatten() {
        if let wasmparser::Payload::ImportSection(reader) = payload {
            for group in reader.into_iter().flatten() {
                match group {
                    Imports::Single(_, imp) if imp.module == "ext" => out.push(imp.name.to_string()),
                    Imports::Compact1 { module: "ext", items } => {
                        out.extend(items.into_iter().flatten().map(|it| it.name.to_string()));
                    }
                    Imports::Compact2 { module: "ext", names, .. } => {
                        out.extend(names.into_iter().flatten().map(|n| n.to_string()));
                    }
                    _ => {}
                }
            }
        }
    }
    out
}

/// The first `external "C"` import (module `ext`) in the model, if any. A
/// host-free FMU has no host to provide these, so the export names the function
/// rather than failing later inside `wit_component`.
pub(super) fn first_external_import(model_wasm: &[u8]) -> Option<String> {
    external_imports(model_wasm).into_iter().next()
}

/// Whether the FMU has to carry [`LAPACK_DYLINK`]: the model calls a routine only
/// it defines. A model whose own `Library` resolved to a `liblapack.wasm` brings
/// its own, and then that one is linked instead of this 1.3 MB.
pub(super) fn needs_lapack(model_wasm: &[u8], ext_libs: &[ExtLibrary]) -> bool {
    if LAPACK_DYLINK().is_empty() {
        return false;
    }
    let mut wanted: HashSet<String> = external_imports(model_wasm).into_iter().collect();
    if wanted.is_empty() {
        return false;
    }
    for bytes in ext_libs.iter().map(|l| &l.bytes[..]).chain([LIBC_PIC(), EXTERNAL_C_DYLINK()]) {
        for name in wasm_exports(bytes) {
            wanted.remove(name);
        }
    }
    wasm_exports(LAPACK_DYLINK()).any(|name| wanted.contains(name))
}

/// The names a wasm module exports.
pub(super) fn wasm_exports(bytes: &[u8]) -> impl Iterator<Item = &str> {
    wasmparser::Parser::new(0).parse_all(bytes).flatten().filter_map(|p| match p {
        wasmparser::Payload::ExportSection(exports) => Some(exports),
        _ => None,
    })
    .flat_map(|exports| exports.into_iter().flatten().map(|e| e.name))
}

/// `resources/native_externals.txt`: the platform libraries to load and the
/// functions to serve from them, in the form `openmodelica_ext_native_marshal`
/// parses. `libs` are file names under `binaries/<platform>/`; `system` are the
/// sonames the FMU does not ship, which its loader opens through the platform's.
pub(super) fn native_externals_table(sigs: &[ExtCallSig], libs: &[String], system: &[String]) -> String {
    use openmodelica_wasm_jit::sig::ExtLang;
    let mut out = String::new();
    for l in libs {
        out.push_str(&format!("lib {l}\n"));
    }
    for l in system {
        out.push_str(&format!("extlib {l}\n"));
    }
    for sig in sigs {
        let mut code = String::new();
        let mut line = format!("fn {} {}", sig.name, if sig.lang == ExtLang::Fortran77 { "F" } else { "C" });
        match &sig.ret {
            Some(t) => {
                code.clear();
                t.write_code(&mut code);
                line.push_str(&format!(" {code}"));
            }
            None => line.push_str(" -"),
        }
        for (t, out) in &sig.args {
            code.clear();
            t.write_code(&mut code);
            line.push_str(&format!(" {}{code}", if *out { "*" } else { "" }));
        }
        out.push_str(&line);
        out.push('\n');
    }
    out
}
