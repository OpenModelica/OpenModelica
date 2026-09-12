//! Externals an exported FMU serves natively: the stub module, the externals
//! table and the build description.

use super::*;

/// `sources/buildDescription.xml` declaring the libraries the FMU does not ship
/// (FMI 3.0 `<Library external="true"/>`). `system` are sonames; `name` carries the
/// linker name, as the schema's examples spell it.
pub(super) fn external_build_description(model_id: &str, system: &[String]) -> String {
    let platform = native_fmu::host_platform().map(|p| format!(" platform=\"{}\"", p.fmi)).unwrap_or_default();
    let mut out = String::from(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\
         <fmiBuildDescription fmiVersion=\"3.0\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" \
         xsi:noNamespaceSchemaLocation=\"https://raw.githubusercontent.com/modelica/fmi-standard/v3.0.2/schema/fmi3BuildDescription.xsd\">\n",
    );
    out.push_str(&format!("  <BuildConfiguration modelIdentifier=\"{}\"{platform}>\n", xml_escape(model_id)));
    for soname in system {
        let name = soname
            .strip_prefix(std::env::consts::DLL_PREFIX)
            .unwrap_or(soname)
            .strip_suffix(std::env::consts::DLL_SUFFIX)
            .unwrap_or(soname);
        out.push_str(&format!(
            "    <Library name=\"{}\" external=\"true\" description=\"a Library annotation named it; \
             resolved as {} by the loader of the platform running the FMU\"/>\n",
            xml_escape(name),
            xml_escape(soname),
        ));
    }
    out.push_str("  </BuildConfiguration>\n</fmiBuildDescription>\n");
    out
}

/// The dylink stub module defining the host-served externals: each stores its
/// parameters in a frame of 8-byte slots, calls the adapter's
/// `om_ext_native_call(index, frame, table, table_len)` and loads the return value
/// from the slot after them. The table text rides in the module's data.
/// One 8-byte frame slot; wasm rejects an alignment hint larger than the access.
fn slot_mem(offset: u32, wty: openmodelica_wasm_jit::sig::WTy) -> we::MemArg {
    let align = match wty {
        openmodelica_wasm_jit::sig::WTy::F64 => 3,
        openmodelica_wasm_jit::sig::WTy::I32 => 2,
    };
    we::MemArg { offset: offset as u64, align, memory_index: 0 }
}

fn native_ext_stub(sigs: &[ExtCallSig], table: &str) -> Result<Vec<u8>> {
    let table_bytes = table.as_bytes();
    let frame_off = (table_bytes.len() as u32 + 7) & !7;
    let mut frame_slots = 1u32;
    let mut types = we::TypeSection::new();
    let val = |t: &openmodelica_wasm_jit::sig::SigTy| match t.wty() {
        openmodelica_wasm_jit::sig::WTy::I32 => we::ValType::I32,
        openmodelica_wasm_jit::sig::WTy::F64 => we::ValType::F64,
    };
    types.ty().function([we::ValType::I32; 4], []);
    let mut fn_sigs = Vec::with_capacity(sigs.len());
    for sig in sigs {
        let fs = match sig.lang {
            openmodelica_wasm_jit::sig::ExtLang::Fortran77 => sig.wasm_sig_f77_shared(),
            openmodelica_wasm_jit::sig::ExtLang::C => sig.wasm_sig_c_shared(),
        };
        types.ty().function(fs.params.iter().map(val), fs.results.iter().map(val));
        frame_slots = frame_slots.max(fs.params.len() as u32 + 1);
        fn_sigs.push(fs);
    }
    let mut imports = we::ImportSection::new();
    imports.import("env", "memory", we::MemoryType { minimum: 0, maximum: None, memory64: false, shared: false, page_size_log2: None });
    imports.import("env", "__memory_base", we::GlobalType { val_type: we::ValType::I32, mutable: false, shared: false });
    imports.import("env", "om_ext_native_call", we::EntityType::Function(0));
    let mut functions = we::FunctionSection::new();
    let mut exports = we::ExportSection::new();
    let mut code = we::CodeSection::new();
    for (i, (sig, fs)) in sigs.iter().zip(&fn_sigs).enumerate() {
        functions.function(i as u32 + 1);
        exports.export(&sig.name, we::ExportKind::Func, i as u32 + 1);
        let mut f = we::Function::new(Vec::<(u32, we::ValType)>::new());
        for (p, t) in fs.params.iter().enumerate() {
            let mem = slot_mem(frame_off + 8 * p as u32, t.wty());
            f.instruction(&we::Instruction::GlobalGet(0));
            f.instruction(&we::Instruction::LocalGet(p as u32));
            f.instruction(&match t.wty() {
                openmodelica_wasm_jit::sig::WTy::F64 => we::Instruction::F64Store(mem),
                openmodelica_wasm_jit::sig::WTy::I32 => we::Instruction::I32Store(mem),
            });
        }
        f.instruction(&we::Instruction::I32Const(i as i32));
        f.instruction(&we::Instruction::GlobalGet(0));
        f.instruction(&we::Instruction::I32Const(frame_off as i32));
        f.instruction(&we::Instruction::I32Add);
        f.instruction(&we::Instruction::GlobalGet(0));
        f.instruction(&we::Instruction::I32Const(table_bytes.len() as i32));
        f.instruction(&we::Instruction::Call(0));
        if let Some(r) = fs.results.first() {
            let mem = slot_mem(frame_off + 8 * fs.params.len() as u32, r.wty());
            f.instruction(&we::Instruction::GlobalGet(0));
            f.instruction(&match r.wty() {
                openmodelica_wasm_jit::sig::WTy::F64 => we::Instruction::F64Load(mem),
                openmodelica_wasm_jit::sig::WTy::I32 => we::Instruction::I32Load(mem),
            });
        }
        f.instruction(&we::Instruction::End);
        code.function(&f);
    }
    let mut data = we::DataSection::new();
    data.active(0, &we::ConstExpr::global_get(0), table_bytes.iter().copied());
    let mut m = we::Module::new();
    m.section(&types).section(&imports).section(&functions).section(&exports).section(&code).section(&data);
    Ok(add_dylink0_sized(&m.finish(), frame_off + 8 * frame_slots, 3))
}

/// What an export with host-served externals adds: the stub linked in, and the
/// table and platform libraries written as resources.
pub(super) struct NativeExternals {
    pub(super) table: String,
    pub(super) stub: Vec<u8>,
    /// (file name under `binaries/<platform>/`, contents)
    pub(super) libs: Vec<(String, Vec<u8>)>,
    /// Sonames declared but not shipped, for `sources/buildDescription.xml`.
    pub(super) system: Vec<String>,
}

#[cfg(not(target_arch = "wasm32"))]
pub(super) fn native_externals(model: &SimModel, kind: &str) -> Result<Option<NativeExternals>> {
    if model.ext_native.is_empty() {
        return Ok(None);
    }
    let names: Vec<&str> = model.ext_native.iter().map(|s| s.name.as_str()).collect();
    if kind == "ME" {
        record_error(format!(
            "CodegenWasmJit: `external \"C\"` {} has no wasm implementation; only an me_cs wasm FMU \
             can serve it from a platform library (fmuType=\"me_cs\").",
            names.join(", ")
        ));
        return Err("CodegenWasmJit: host-served externals need an me_cs FMU");
    }
    let files = sim_runtime::native_external_library_files(model).map_err(|e| {
        record_error(format!(
            "CodegenWasmJit: `external \"C\"` {} has no wasm implementation and no platform library \
             this omc can ship either:\n{e}",
            names.join(", ")
        ));
        "CodegenWasmJit: unresolved host-served externals"
    })?;
    let mut libs = Vec::new();
    let mut system = Vec::new();
    for path in &files {
        // Declared, not shipped: no file behind the soname to pack.
        if model.ext_native_system.iter().any(|s| s == path) {
            system.push(path.clone());
            continue;
        }
        let name = std::path::Path::new(path).file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default();
        let bytes = std::fs::read(path).map_err(|e| {
            record_error(format!("CodegenWasmJit: cannot read `{path}`: {e}"));
            "CodegenWasmJit: cannot read a platform library"
        })?;
        libs.push((name, bytes));
    }
    let table =
        native_externals_table(&model.ext_native, &libs.iter().map(|(n, _)| n.clone()).collect::<Vec<_>>(), &system);
    let stub = native_ext_stub(&model.ext_native, &table)?;
    Ok(Some(NativeExternals { table, stub, libs, system }))
}

#[cfg(target_arch = "wasm32")]
pub(super) fn native_externals(model: &SimModel, _kind: &str) -> Result<Option<NativeExternals>> {
    if let Some(sig) = model.ext_native.first() {
        record_error(format!(
            "CodegenWasmJit: `external \"C\"` `{}` has no wasm implementation, and the browser omc has \
             no platform library to serve it from.",
            sig.name
        ));
        return Err("CodegenWasmJit: unresolved external \"C\"");
    }
    Ok(None)
}

/// Link the adapter + model into an fmi-ls-wasm component (pure Rust, so it runs in
/// the browser omc too). When the model uses `external "C"`, ModelicaExternalC +
/// PIC `libc.so` are added as shared-everything libraries. The reactor adapter
/// bridges preview1 to the component's preview2 WASI: libc's calls, and the FMI
/// adapter's own `fd_write` for the simulation log.
pub(super) fn link_fmu_component(
    model_wasm: &[u8],
    adapter: &[u8],
    solvers: Option<&[&str]>,
    ext_libs: &[ExtLibrary],
    native_stub: Option<&[u8]>,
) -> Result<Vec<u8>> {
    let sundials = solvers.is_some();
    if adapter.is_empty() {
        // The plain adapter is always built; the SUNDIALS one only where the
        // wasm SUNDIALS archives were, so name which is missing.
        if sundials {
            record_error(
                "CodegenWasmJit: this omc has no SUNDIALS FMI3 adapter, so a Co-Simulation FMU                  cannot embed CVODE or IDA. Export with `--fmiFlags=s:dassl` (or euler), or                  rebuild omc with RUST_OMC_ENABLE_SUNDIALS=ON."
                    .to_string(),
            );
            return Err("CodegenWasmJit: no SUNDIALS FMI3 adapter in this omc");
        }
        return Err("CodegenWasmJit: FMI3 adapter unavailable (build wasm32-unknown-unknown + -Z build-std)");
    }
    let has_ext = first_external_import(model_wasm).is_some();
    let model = model_to_dylink(model_wasm)?;
    let plain_adapter = native_stub.is_none().then(|| drop_native_ext_import(adapter)).flatten();
    let mut l = wit_component::Linker::default().validate(true);
    l = l.library("adapter", plain_adapter.as_deref().unwrap_or(adapter), false).map_err(link_err)?;
    if plain_adapter.is_some() {
        l = l.library("native_absent", &native_ext_absent(), false).map_err(link_err)?;
    }
    l = l.library("model", &model, false).map_err(link_err)?;
    // The adapter imports every solver whatever the flags say, so each is resolved
    // either way; what changes is whether the real library or its stub answers. CVODE
    // reaches the residual through a C function pointer, which works because every
    // library here imports the one `env.__indirect_function_table`.
    if let Some(wanted) = solvers {
        for lib in SOLVER_LIBRARIES {
            let bytes =
                if wanted.contains(&lib.name) { lib.module() } else { lib.stub() };
            l = l.library(lib.name, bytes, false).map_err(link_err)?;
        }
    }
    if needs_lapack(model_wasm, ext_libs) {
        l = l.library("lapack", LAPACK_DYLINK(), false).map_err(link_err)?;
    }
    let real_solvers = solvers.is_some_and(|w| !w.is_empty());
    if has_ext || real_solvers {
        // modelicaexternalc before libc; the coexisting allocator (libc dlmalloc +
        // runtime rt_alloc over one shared heap) is intentional. A solver library
        // needs libc too, so it brings the same libraries along; the stubs do not.
        if has_ext {
            // First, so a symbol they define wins over ModelicaExternalC's.
            let ext_bytes: Vec<Vec<u8>> =
                ext_libs.iter().map(|lib| drop_redundant_initialize(&lib.bytes)).collect();
            for (lib, bytes) in ext_libs.iter().zip(&ext_bytes) {
                l = l.library(&lib.name, bytes, false).map_err(link_err)?;
            }
            if let Some(stub) = native_stub {
                l = l.library("native_stub", stub, false).map_err(link_err)?;
            }
            l = l.library("modelicaexternalc", EXTERNAL_C_DYLINK(), false).map_err(link_err)?;
        }
        l = l.library("libc", LIBC_PIC(), false).map_err(link_err)?;
        if has_ext {
            // Last, so a `usertab` from the model's own libraries wins.
            l = l.library("usertab", USERTAB_DYLINK(), false).map_err(link_err)?;
        }
    }
    // Unconditional: the adapter is also what gives the FMU the stdout its
    // simulation log goes to.
    l = l.adapter("wasi_snapshot_preview1", WASI_P1_ADAPTER()).map_err(link_err)?;
    l.encode().map_err(link_err)
}
