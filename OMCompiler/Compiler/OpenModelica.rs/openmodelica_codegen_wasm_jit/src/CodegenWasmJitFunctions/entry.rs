//! MetaModelica entry points: `translateFunctions`, `loadAndExecute`.

use super::*;

/// `CodegenWasmJitFunctions.translateFunctions`: lower `fnCode` to a wasm module
/// written to `<name>.wasm` (+ `<name>.wasm.sig`).
///
/// When the `wasm-jit` target is selected it is authoritative: a construct it
/// cannot lower is a hard, visible failure with the precise reason, **not** a
/// silent degradation to the C target. The reason is recorded as an internal
/// error (so `getErrorString()`/OMEdit show it and the scripting layer treats the
/// build as failed) rather than raised as a panic — a panic traps the wasm omc
/// instance, after which the buffered error can't be read back. Stale artefacts
/// from a previous target are removed first so a failure cannot leave a
/// mismatched module behind. Mirrors [`CodegenWasmJit::translateModel`].
pub fn translateFunctions(fnCode: SimCodeFunction::FunctionCode) {
    let _ = std::fs::remove_file(format!("{}.wasm", fnCode.name));
    let _ = std::fs::remove_file(format!("{}.wasm.sig", fnCode.name));
    if let Err(e) = translate_functions_inner(&fnCode) {
        crate::CodegenWasmJit::record_error(format!(
            "CodegenWasmJit: cannot JIT function `{}` for the wasm-jit target: {e:#}",
            fnCode.name
        ));
    }
}

fn translate_functions_inner(fn_code: &SimCodeFunction::FunctionCode) -> Result<()> {
    let BuiltModule { bytes, in_sig, out_sig, ext_imports } = build_module(fn_code)?;
    let base = fn_code.name.to_string();
    // Sidecar: input type codes, output type codes, then a `lib`/`ext` line per
    // external "C" library and per function called in one.
    let mut in_codes = String::new();
    in_sig.iter().for_each(|s| s.write_code(&mut in_codes));
    let mut out_codes = String::new();
    out_sig.iter().for_each(|s| s.write_code(&mut out_codes));
    let mut sig = format!("{in_codes}\n{out_codes}\n");
    if !ext_imports.is_empty() {
        let mut notes: Vec<String> = Vec::new();
        let fortran = ext_imports.iter().any(|s| s.lang == ExtLang::Fortran77);
        let resolved = crate::CodegenWasmJit::resolve_ext_libraries(&fn_code.makefileParams, fortran, &mut notes)?;
        let wasm_libs = resolved.wasm;
        for lib in &wasm_libs {
            sig.push_str(&format!("lib\t{}\n", lib.name));
        }
        // C source: an `Include`, or a `Library` naming a `.c` file.
        let sources: Vec<String> = crate::CodegenWasmJit::lst(&fn_code.externalFunctionIncludes)
            .map(|s| s.to_string())
            .chain(resolved.sources)
            .collect();
        let dirs: Vec<String> = crate::CodegenWasmJit::lst(&fn_code.makefileParams.includes).map(|s| s.to_string()).collect();
        // A host build compiles them the way the C target does and calls them
        // through libffi, as `build_sim_model` does: the in-wasm `Modelica*`
        // callbacks are host imports, which cannot take C varargs, so a
        // `ModelicaFormatMessage` there would lose its arguments. The browser has
        // no host library to call, so there the wasm unit is all.
        #[cfg(target_arch = "wasm32")]
        {
            let missing = crate::CodegenWasmJit::missing_ext_symbols(&ext_imports, &wasm_libs);
            if let Some(l) = crate::CodegenWasmJit::compile_include_library(&base, &sources, &dirs, &fn_code.makefileParams.cflags, &missing, &mut notes)? {
                let path = format!("{base}_includes.wasm");
                openmodelica_wasi::fs::write(&path, &l.bytes)
                    .map_err(|_| "CodegenWasmJitFunctions: cannot stage the compiled include library")?;
                sig.push_str(&format!("lib\t{path}\n"));
            }
        }
        // The model's own code first: it shadows a same-named symbol in a `Library`
        // shared object, as the C target's own link order does.
        #[cfg(not(target_arch = "wasm32"))]
        for lib in native_fallbacks(&base, fn_code, &resolved.native, &resolved.archives, &sources, &dirs, &ext_imports, &wasm_libs, &mut notes) {
            sig.push_str(&format!("nlib\t{lib}\n"));
        }
        for lib in &resolved.native {
            sig.push_str(&format!("nlib\t{lib}\n"));
        }
        for e in &ext_imports {
            sig.push_str(&format!("ext\t{}\n", write_ext_sig(e)));
        }
        for n in &notes {
            sig.push_str(&format!("note\t{}\n", n.replace('\n', " ")));
        }
    }
    // Native writes the module + sidecar to disk; wasm has no OS filesystem, so
    // the facade stages them in the VFS where `load_and_execute` reads them back.
    openmodelica_wasi::fs::write(&format!("{base}.wasm"), &bytes).map_err(|_| "CodegenWasmJitFunctions: cannot write wasm")?;
    openmodelica_wasi::fs::write(&format!("{base}.wasm.sig"), sig.as_bytes()).map_err(|_| "CodegenWasmJitFunctions: cannot write wasm.sig")?;
    Ok(())
}

/// Host libraries holding the `external "C"` implementations no module in
/// `wasm_libs` defines: the `Library` archives linked into a loadable one, and the
/// C sources compiled. Built in the compile phase, as the simulation's are.
#[cfg(not(target_arch = "wasm32"))]
fn native_fallbacks(
    base: &str,
    fn_code: &SimCodeFunction::FunctionCode,
    libs: &[String],
    archives: &[String],
    sources: &[String],
    dirs: &[String],
    ext_imports: &[ExtCallSig],
    wasm_libs: &[openmodelica_wasm_jit::model::ExtLibrary],
    notes: &mut Vec<String>,
) -> Vec<String> {
    let missing = crate::CodegenWasmJit::missing_ext_symbols(ext_imports, wasm_libs);
    if missing.is_empty() {
        return Vec::new();
    }
    let mp = &fn_code.makefileParams;
    let mut out = Vec::new();
    if !sources.is_empty() {
        let inc = openmodelica_wasm_jit::model::ExtIncludes {
            sources: sources.to_vec(),
            include_dirs: dirs.to_vec(),
            libs: libs.to_vec(),
            archives: archives.to_vec(),
            symbols: ext_imports.iter().map(|s| s.name.clone()).collect(),
            ccompiler: mp.ccompiler.to_string(),
            cflags: mp.cflags.to_string(),
            dllext: mp.dllext.to_string(),
            prefix: base.to_string(),
        };
        match inc.compile(&missing) {
            Ok(b) => {
                notes.extend(b.note);
                out.push(b.path);
            }
            Err(e) => notes.push(e),
        }
    }
    if !archives.is_empty() {
        let arch = openmodelica_wasm_jit::model::ExtArchives {
            archives: archives.to_vec(),
            symbols: ext_imports.iter().map(|s| s.name.clone()).collect(),
            ccompiler: mp.ccompiler.to_string(),
            dllext: mp.dllext.to_string(),
            prefix: base.to_string(),
        };
        match arch.link() {
            Ok(path) => out.push(path),
            Err(e) => notes.push(e),
        }
    }
    out
}

/// `CodegenWasmJitFunctions.loadAndExecute`: instantiate `<fileName>.wasm` and
/// call the exported `main`, marshalling `args` in and the result out. Returns
/// `Values.META_FAIL` on any failure (missing/invalid module, a wasm trap from
/// a failed assertion or division by zero, …), mirroring `DynLoad.executeFunction`.
pub fn loadAndExecute(fileName: ArcStr, name: ArcStr, args: List<Arc<Values::Value>>) -> Arc<Values::Value> {
    match runtime::load_and_execute(&fileName, &name, &args) {
        Ok(v) => v,
        // Failure is a normal MetaModelica value the caller handles; no stderr.
        Err(_) => Arc::new(Values::Value::META_FAIL),
    }
}
