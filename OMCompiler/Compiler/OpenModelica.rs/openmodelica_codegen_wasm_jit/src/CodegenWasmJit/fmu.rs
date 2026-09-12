//! FMI wasm FMU export: `translateFmu`, `emit_fmu`, kernel lowering, the CS
//! method, native platform compilation, model-description patching.

use super::*;

/// Co-Simulation: the FMU integrates itself, so the adapter embeds the driver.
///
/// Served by the me_cs component, which substitutes for a `co-simulation-fmu`:
/// identical imports, a superset of its exports. `modelDescription.xml` still
/// declares CoSimulation alone; the unused ME exports cost ~38 KB against the
/// 1.28 MB a fourth adapter blob costs every omc.
pub fn emitCsFmu(
    sim_code: SimCode::SimCode,
    fmu_path: ArcStr,
    _guid: ArcStr,
    model_description: ArcStr,
    ls_dae_manifest: ArcStr,
    documentation_dir: ArcStr,
    terminals_dir: ArcStr,
    simulation_flags_json: ArcStr,
) -> Result<()> {
    emit_fmu(sim_code, fmu_path, model_description, ls_dae_manifest, documentation_dir, terminals_dir, simulation_flags_json, FMI3_MECS_ADAPTER(), "CS")
}

/// me_cs: one component exporting both interfaces (the wasm equivalent of a
/// classic me_cs FMU — a single binary and modelIdentifier).
pub fn emitMeCsFmu(
    sim_code: SimCode::SimCode,
    fmu_path: ArcStr,
    _guid: ArcStr,
    model_description: ArcStr,
    ls_dae_manifest: ArcStr,
    documentation_dir: ArcStr,
    terminals_dir: ArcStr,
    simulation_flags_json: ArcStr,
) -> Result<()> {
    emit_fmu(sim_code, fmu_path, model_description, ls_dae_manifest, documentation_dir, terminals_dir, simulation_flags_json, FMI3_MECS_ADAPTER(), "me_cs")
}

/// Say that the FMU answers `fmi3GetDirectionalDerivative` when the model was
/// compiled with its symbolic Jacobian, which the adapter answers from.
///
/// The shared template only sets the attribute from `<ModelStructure>`'s
/// `continuousPartialDerivatives`, which the C export needs and this one does
/// not: what matters here is whether the metadata carries the Jacobian.
fn announce_directional_derivatives(model_description: &str, model: &SimModel) -> String {
    let has_symbolic = model.jac_a.as_ref().is_some_and(|j| j.sym.is_some());
    if !has_symbolic {
        return model_description.to_string();
    }
    model_description.replace(
        "providesDirectionalDerivatives=\"false\"",
        "providesDirectionalDerivatives=\"true\"",
    )
}

/// The runtime's `-lv` streams as log categories of an FMI 3.0 export, so an
/// importer can ask the FMU for the trace `simulate()` would print.
fn declare_log_streams(model_description: &str) -> String {
    let end = model_description.find("</LogCategories>").filter(|_| fmi_version() == "3.0");
    let Some(end) = end else { return model_description.to_string() };
    let categories: String = omclog::STREAM_NAME[1..]
        .iter()
        .map(|s| format!("      <Category name=\"{s}\" />\n"))
        .collect();
    format!("{}{categories}    {}", &model_description[..end], &model_description[end..])
}

/// The FMI version being exported, `"3.0"` unless `buildModelFMU` asked otherwise.
fn fmi_version() -> String {
    let v = openmodelica_util::Flags::getConfigString(openmodelica_util::Flags::FMI_VERSION.clone())
        .unwrap_or_default();
    if v.is_empty() { "3.0".to_string() } else { v.to_string() }
}

/// Where an unzipped export keeps the model kernel. Not `binaries/wasm32-wasip2/`,
/// which fmi-ls-wasm defines as a *component*: this is a dylink library, and only
/// a host that links it against the adapter can run it.
pub(crate) const DYLINK_DIR: &str = "binaries/wasm32-om-dylink";

/// The stub module for host-served externals, among the linked form's libraries.
pub(crate) const NATIVE_STUB: &str = "native_stub";

/// The host-served externals' table (`openmodelica_ext_native_marshal::parse`).
pub(crate) const NATIVE_TABLE: &str = "resources/native_externals.txt";

/// What the host has to load beside the model kernel, decided here because this
/// is where the model's `external "C"` libraries were resolved. A tiny JSON, read
/// by `CodegenWasmJit::artifact`.
/// `sundials` is the *fused* runtime's, which this form binds the model to: it links
/// the archives statically, so it has every solver whatever the flags say.
fn artifact_manifest(model: &SimModel, sundials: bool) -> String {
    let ext = first_external_import(&model.wasm).is_some();
    let mut out = String::from("{\n");
    out.push_str(&format!("  \"externalC\": {ext},\n"));
    out.push_str(&format!("  \"lapack\": {},\n", needs_lapack(&model.wasm, &model.ext_libs)));
    out.push_str(&format!("  \"sundials\": {sundials},\n"));
    out.push_str(&format!("  \"extLibraries\": {}\n", model.ext_libs.len()));
    out.push_str("}\n");
    out
}

/// `--fmuDirectory`: write the export as an unzipped directory holding only what
/// an OpenModelica importer reads, rather than a portable FMU in a zip.
fn fmu_directory() -> bool {
    openmodelica_util::Flags::getConfigBool(openmodelica_util::Flags::FMU_DIRECTORY.clone())
        .unwrap_or(false)
}

/// A `-d=execstat` phase, beside the `FMU modelDescription.xml` ones the
/// MetaModelica side emits. Not a compiler notification: those reach
/// `getErrorString()`, where a timing makes every FMU test depend on the clock.
fn export_phase(name: &str) {
    let _ = openmodelica_util::ExecStat::execStat(ArcStr::from(name));
}

/// The platforms `platforms={...}` named besides `"wasm"`.
fn requested_native_platforms() -> Vec<String> {
    openmodelica_util::Flags::getConfigString(openmodelica_util::Flags::FMU_NATIVE_PLATFORMS.clone())
        .unwrap_or_default()
        .split(',')
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_owned)
        .collect()
}

/// Per platform named in `platforms={...}` besides `"wasm"`: the component
/// compiled ahead of time for it, plus the loader that serves the FMI C API from
/// that artifact. The FMU then works with a WebAssembly-unaware importer.
/// Compile the component for this machine and keep it, so the runs that follow
/// the export in this session neither serialize it nor read it back.
///
/// An unzipped export is for this omc, so it is always compiled — and then the
/// `.cwasm` need not be written at all unless `platforms` asked for one. A zipped
/// export is only compiled here if it is going to carry this machine's artifact
/// anyway. `None` if the engine refuses it; the caller then falls back to
/// [`native_fmu::precompile`].
#[cfg(all(feature = "artifact", not(target_arch = "wasm32")))]
fn compile_for_host(
    component: &[u8],
    fmu_path: &str,
    linked: bool,
    bare: bool,
) -> Option<std::sync::Arc<openmodelica_fmi_driver::component::WasmArtifact>> {
    // The unzipped form is not a component at all — the host links the model
    // kernel against the adapter it has already compiled — so there is nothing
    // here to compile ahead of time.
    if linked {
        return None;
    }
    let host = native_fmu::host_platform()?;
    // An unzipped export is for this omc: compiling here means the runs that
    // follow take the live component rather than each compiling it again.
    if !bare
        && !requested_native_platforms().iter().any(|n| native_fmu::lookup(n).is_some_and(|p| p.fmi == host.fmi))
    {
        return None;
    }
    // The resources it reads through are written after this, so the caller points
    // it at them ([`WasmArtifact::use_resources`]) and remembers it then.
    let _ = fmu_path;
    Some(std::sync::Arc::new(
        openmodelica_fmi_driver::component::WasmArtifact::compile(component, None).ok()?,
    ))
}

#[cfg(not(all(feature = "artifact", not(target_arch = "wasm32"))))]
fn compile_for_host(_component: &[u8], _fmu_path: &str, _linked: bool, _bare: bool) -> Option<()> {
    None
}

/// The `.cwasm` for `platform`: serialized out of what [`compile_for_host`] just
/// compiled when it is this machine's, and a cross-compile otherwise.
#[cfg(all(feature = "artifact", not(target_arch = "wasm32")))]
fn host_cwasm(
    host: Option<&std::sync::Arc<openmodelica_fmi_driver::component::WasmArtifact>>,
    platform: &native_fmu::Platform,
    component: &[u8],
) -> Result<Vec<u8>> {
    match host.filter(|_| native_fmu::host_platform().is_some_and(|h| h.fmi == platform.fmi)) {
        Some(a) => a.serialize().map_err(|e| {
            record_error(format!("CodegenWasmJit: serializing the artifact for {}: {e}", platform.fmi));
            "CodegenWasmJit: cannot serialize the compiled artifact"
        }),
        None => native_fmu::precompile(component, platform),
    }
}

#[cfg(not(all(feature = "artifact", not(target_arch = "wasm32"))))]
fn host_cwasm(_host: Option<&()>, platform: &native_fmu::Platform, component: &[u8]) -> Result<Vec<u8>> {
    native_fmu::precompile(component, platform)
}

fn add_native_platforms(
    entries: &mut Vec<(String, Vec<u8>)>,
    component: &[u8],
    model_id: &str,
    version: &str,
    linked: bool,
    natives: Option<&NativeExternals>,
    #[cfg(all(feature = "artifact", not(target_arch = "wasm32")))]
    host: Option<&std::sync::Arc<openmodelica_fmi_driver::component::WasmArtifact>>,
    #[cfg(not(all(feature = "artifact", not(target_arch = "wasm32"))))] host: Option<&()>,
) -> Result<()> {
    // The host-served externals' libraries, beside the platform's binary as FMI
    // has it; only this machine's exist.
    if let (Some(n), Some(host_platform)) = (natives, native_fmu::host_platform()) {
        let dir = native_fmu::fmi_dir(host_platform, version);
        for (name, bytes) in &n.libs {
            entries.push((format!("binaries/{dir}/{name}"), bytes.clone()));
        }
    }
    if linked {
        // Nothing to precompile: see `compile_for_host`.
        return Ok(());
    }
    for name in requested_native_platforms() {
        let Some(platform) = native_fmu::lookup(&name) else {
            record_error(format!(
                "CodegenWasmJit: `{name}` is not a platform a wasm FMU can be built for. \
                 Available: {}.",
                native_fmu::PLATFORMS.iter().map(|p| p.fmi).collect::<Vec<_>>().join(", ")
            ));
            return Err("CodegenWasmJit: unknown FMU platform");
        };
        let dir = native_fmu::fmi_dir(platform, version);
        let Some(loader) = native_fmu::loader(platform) else {
            record_error(format!(
                "CodegenWasmJit: this omc has no FMI loader library for `{}`, so an FMU \
                 cannot serve that platform. Available: {}. Rebuild omc with \
                 OMC_FMU_NATIVE_TARGETS={} to add it.",
                platform.fmi,
                native_fmu::available().join(", "),
                platform.triple
            ));
            return Err("CodegenWasmJit: no FMU loader for the requested platform");
        };
        let cwasm = host_cwasm(host, platform, component)?;
        entries.push((
            format!("binaries/{dir}/{}", native_fmu::loader_file_name(platform, model_id)),
            loader,
        ));
        entries.push((format!("binaries/{dir}/{model_id}.cwasm"), cwasm));
    }
    Ok(())
}

/// One `--fmiFlags` entry, out of the `"name" : "value"` pairs `CodegenFMU`
/// renders into `resources/<prefix>_flags.json`.
pub(super) fn fmi_flag(json: &str, name: &str) -> Option<String> {
    let key = format!("\"{name}\"");
    json.match_indices(&key).find_map(|(i, _)| {
        let rest = json[i + key.len()..].trim_start().strip_prefix(':')?.trim_start().strip_prefix('"')?;
        Some(rest[..rest.find('"')?].to_string())
    })
}

/// `fmi2GetReal` and friends name a base type, not a value-reference space: the
/// loader recovers the component's value reference by adding the offset for the
/// type the call names (`SimCodeUtil.getFMI2ValueReferenceOffsets`).
fn fmi2_vr_offsets(sim_code: &SimCode::SimCode) -> Result<String> {
    let offsets = openmodelica_backend::SimCodeUtil::getFMI2ValueReferenceOffsets(sim_code.modelInfo.clone());
    let [real, integer, boolean, string] = lst(&offsets).collect::<Vec<_>>()[..] else {
        return Err("CodegenWasmJit: expected four FMI 2.0 value-reference offsets");
    };
    Ok(format!("{{\"real\":{real},\"integer\":{integer},\"boolean\":{boolean},\"string\":{string}}}\n"))
}

/// The distinct CAD file references (`<type>` values ending in a CAD extension)
/// in a `_visual.xml`, in document order.
fn cad_type_refs(visual_xml: &str) -> Vec<String> {
    let mut out: Vec<String> = Vec::new();
    let mut rest = visual_xml;
    while let Some(i) = rest.find("<type>") {
        rest = &rest[i + "<type>".len()..];
        let Some(j) = rest.find("</type>") else { break };
        let t = &rest[..j];
        let lower = t.to_ascii_lowercase();
        if [".dxf", ".stl", ".obj", ".3ds"].iter().any(|e| lower.ends_with(e))
            && !out.iter().any(|s| s == t)
        {
            out.push(t.to_string());
        }
        rest = &rest[j + "</type>".len()..];
    }
    out
}

/// The FMU-resource file name for a CAD reference (its basename).
fn cad_basename(uri: &str) -> &str {
    uri.rsplit(['/', '\\']).next().unwrap_or(uri)
}

/// The integrator a Co-Simulation FMU embeds: `-s` from the export's `_flags.json`,
/// else the model's own method, with DASKR for one this build cannot step with. A
/// `--daeMode` model integrates with IDA. Empty for Model Exchange.
fn fmu_cs_method(simulation_flags_json: &str, kind: &str, sim_code: &SimCode::SimCode) -> String {
    let own = sim_code.simulationSettingsOpt.as_ref().map(|s| s.method.to_string()).unwrap_or_default();
    cs_method_from(simulation_flags_json, kind, sim_code.daeModeData.is_some(), &own)
}

pub(super) fn cs_method_from(simulation_flags_json: &str, kind: &str, dae_mode: bool, own: &str) -> String {
    if kind == "ME" {
        return String::new();
    }
    if dae_mode {
        return "ida".to_string();
    }
    if let Some(s) = fmi_flag(simulation_flags_json, "s") {
        return s;
    }
    let own = if own.is_empty() { "dassl".to_string() } else { own.to_string() };
    if fmu_cs_solvers().contains(&own.as_str()) {
        return own;
    }
    let _ = openmodelica_util::Error::addCompilerNotification(ArcStr::from(format!(
        "A Co-Simulation wasm FMU cannot integrate with method=\"{own}\"; it integrates with dassl. \
         Available: {}.",
        fmu_cs_solvers().join(", ")
    )));
    "dassl".to_string()
}

/// Lower the model kernel a wasm FMU is built around, and check that this omc and
/// this `kind` can serve it. Shared linear memory across model + runtime +
/// ModelicaExternalC, so `external "C"` calls pass real pointers rather than
/// runtime handles — which is also why the simulation path cannot bind it.
fn lower_fmu_kernel(
    sim_code: &SimCode::SimCode,
    kind: &str,
    cs_method: &str,
    fmi_solver_flags: &str,
) -> Result<SimModel> {
    let model = crate::CodegenWasmJitFunctions::with_shared_externals(|| {
        build_sim_model(sim_code, true, ExtHost::Wasm, cs_method, fmi_solver_flags)
    })?;
    if let Some(func) = first_external_import(&model.wasm) {
        if !external_c_available() {
            record_error(format!(
                "CodegenWasmJit: model `{}` uses the external C function `{func}`, but this omc \
                 was built without the PIC wasi-libc needed for external \"C\" in a host-free \
                 wasm FMU. Rebuild with a PIC wasi-libc (set OMC_WASI_PIC_SYSROOT), or simulate \
                 the model in the browser (`--simCodeTarget=wasm-jit`) instead.", model.model_name));
            return Err("CodegenWasmJit: external \"C\" support not built into this omc");
        }
    }
    check_fmu_method(&model, kind)?;
    Ok(model)
}

/// A CS FMU integrates itself, so an unservable method has to fail at export
/// rather than at the importer's first do-step.
fn check_fmu_method(model: &SimModel, kind: &str) -> Result<()> {
    if kind != "ME" && !fmu_cs_solvers().contains(&model.meta.cs_method.as_str()) {
        record_error(format!(
            "CodegenWasmJit: a Co-Simulation wasm FMU cannot integrate with method=\"{}\". \
             Available: {}.",
            model.meta.cs_method,
            fmu_cs_solvers().join(", ")
        ));
        return Err("CodegenWasmJit: unusable Co-Simulation integration method");
    }
    Ok(())
}

/// The kernel to build this FMU around: the one [`translateFmu`] left behind if it
/// was lowered the way this export needs, and a fresh lowering otherwise.
fn fmu_kernel(
    sim_code: &SimCode::SimCode,
    kind: &str,
    cs_method: &str,
    fmi_solver_flags: &str,
) -> Result<Arc<SimModel>> {
    let prefix = sim_code.fileNamePrefix.to_string();
    let cached = fmu_kernels().lock().unwrap_or_else(|e| e.into_inner()).get(&prefix).cloned();
    // Both are baked into the kernel's metadata, so a re-export that changed either
    // has to lower again rather than reuse what the last one left behind.
    if let Some(k) = cached
        .filter(|k| k.cs_method == cs_method && k.fmi_solver_flags == fmi_solver_flags)
    {
        check_fmu_method(&k.model, kind)?;
        return Ok(k.model.clone());
    }
    let model = Arc::new(lower_fmu_kernel(sim_code, kind, cs_method, fmi_solver_flags)?);
    keep_fmu_kernel(&prefix, &model);
    Ok(model)
}

fn keep_fmu_kernel(prefix: &str, model: &Arc<SimModel>) {
    fmu_kernels().lock().unwrap_or_else(|e| e.into_inner()).insert(
        prefix.to_string(),
        Arc::new(FmuKernel {
            model: model.clone(),
            cs_method: model.meta.cs_method.clone(),
            fmi_solver_flags: model.meta.fmi_solver_flags.clone(),
        }),
    );
}

/// `CodegenWasmJit.translateFmu`: the wasm counterpart of the C target generating
/// the FMU sources without building them. Lower the model once and keep it, both
/// for the `buildModelFMU` that follows and as the prepared simulation model, so a
/// run and an export share one kernel.
pub fn translateFmu(sim_code: SimCode::SimCode, fmu_type: ArcStr, simulation_flags_json: ArcStr) -> Result<()> {
    sync_engine_threading()?;
    sim_runtime::start_runtime_compile();
    let kind = fmu_kind(&fmu_type);
    let cs_method = fmu_cs_method(&simulation_flags_json, kind, &sim_code);
    let fmi_solver_flags = fmu_solver_flags(&simulation_flags_json);
    let prefix = sim_code.fileNamePrefix.to_string();
    let _ = openmodelica_wasi::fs::remove_file(&format!("{prefix}.wasm"));
    let errs_before = openmodelica_util::Error::getNumErrorMessages();
    let outcome = (|| -> Result<()> {
        // Lowered the way the simulation path binds it, since that is what runs it.
        // With no `external "C"` this is the FMU kernel too: shared externals
        // change the lowering only where there are `ext` imports.
        let model = Arc::new(build_sim_model(&sim_code, true, ExtHost::SIM, &cs_method, &fmi_solver_flags)?);
        check_fmu_method(&model, kind)?;
        write_output(&format!("{prefix}.wasm"), &model.wasm).map_err(|_| "CodegenWasmJit: write failed")?;
        sim_models().lock().unwrap_or_else(|e| e.into_inner()).insert(prefix.clone(), model.clone());
        // With `external "C"` the two differ, and the export lowers its own.
        if first_external_import(&model.wasm).is_none() {
            keep_fmu_kernel(&prefix, &model);
        }
        Ok(())
    })();
    if let Err(e) = &outcome {
        if openmodelica_util::Error::getNumErrorMessages() == errs_before {
            record_error(format!(
                "CodegenWasmJit: cannot build the FMU model kernel for `{prefix}`: {}",
                with_engine_detail(e)
            ));
        }
    }
    outcome
}

/// Keep the model translated the way `simulate` runs it, for `artifact::translated`.
/// Without `external "C"` the kernel is that model; with it the two lowerings
/// differ. Its compile is joined here so it counts as the build.
fn keep_translated_model(sim_code: &SimCode::SimCode, kernel: &Arc<SimModel>) -> Result<()> {
    let prefix = sim_code.fileNamePrefix.to_string();
    let kept = sim_models().lock().unwrap_or_else(|e| e.into_inner()).get(&prefix).cloned();
    let model = match kept {
        Some(m) => m,
        None if first_external_import(&kernel.wasm).is_none() => kernel.clone(),
        None => Arc::new(build_sim_model(sim_code, true, ExtHost::SIM, &kernel.meta.cs_method, &kernel.meta.fmi_solver_flags)?),
    };
    if model.prepared.lock().unwrap_or_else(|e| e.into_inner()).is_none()
        && let Ok(compiled) = sim_runtime::take_compiled_model(&model)
    {
        *model.prepared.lock().unwrap_or_else(|e| e.into_inner()) = Some(compiled);
    }
    sim_models().lock().unwrap_or_else(|e| e.into_inner()).insert(prefix, model);
    Ok(())
}

/// `emit_fmu`'s `kind` for a `buildModelFMU(fmuType=)`.
fn fmu_kind(fmu_type: &str) -> &'static str {
    match fmu_type {
        "me" => "ME",
        "cs" => "CS",
        _ => "me_cs",
    }
}

/// `adapter` is `(plain, with-SUNDIALS)`; the second is picked for a method that needs
/// CVODE/IDA and is empty for Model Exchange.
/// `openmodelica_fmi::lsdae::MANIFEST_PATH`, which the web build does not link.
const LS_DAE_MANIFEST: &str = "extra/org.fmi-standard.fmi-ls-dae/fmi-ls-manifest.xml";

#[allow(clippy::too_many_arguments)]
pub(super) fn emit_fmu(
    sim_code: SimCode::SimCode,
    fmu_path: ArcStr,
    model_description: ArcStr,
    ls_dae_manifest: ArcStr,
    documentation_dir: ArcStr,
    terminals_dir: ArcStr,
    simulation_flags_json: ArcStr,
    adapter: &[u8],
    kind: &str,
) -> Result<()> {
    sync_engine_threading()?;
    sim_runtime::start_runtime_compile();
    let cs_method = fmu_cs_method(&simulation_flags_json, kind, &sim_code);
    let fmi_solver_flags = fmu_solver_flags(&simulation_flags_json);
    // Emitting the model takes seconds; a host that compiles the native platforms
    // out of process can spend them loading its compiler.
    if !requested_native_platforms().is_empty() {
        native_fmu::preload_aot_compiler();
    }
    let errs_before = openmodelica_util::Error::getNumErrorMessages();
    let outcome = (|| -> Result<()> {
        let model = fmu_kernel(&sim_code, kind, &cs_method, &fmi_solver_flags)?;
        export_phase("FMU model kernel");
        let natives = native_externals(&model, kind)?;
        let bare = fmu_directory();
        if bare {
            keep_translated_model(&sim_code, &model)?;
            export_phase("FMU translated model");
        }
        let cs = kind != "ME";
        // Both adapters import every solver, real or stubbed; only the integrator is
        // Co-Simulation's alone.
        let solvers = sundials_available()
            .then(|| fmu_solver_libraries(&simulation_flags_json, &cs_method, cs, model.sparse_nls));
        // An unzipped export is for an OpenModelica importer: it holds the model
        // description and the model kernel and nothing else, and the host links
        // that kernel against an adapter it compiled once into
        // `~/.openmodelica/cache`. A component would carry that megabyte itself
        // and be compiled with it, which is nearly all of what exporting a small
        // model used to cost. `OMC_WASM_LINKED_ARTIFACT=0` asks for one anyway.
        let linked = bare && std::env::var("OMC_WASM_LINKED_ARTIFACT").as_deref() != Ok("0");
        let component = if linked {
            // The model kernel exactly as the ordinary simulation path runs it —
            // not a dylink library. PIC would put its every data access behind
            // `__memory_base` and its calls through the indirect table, in the
            // loop that dominates a run; only the *adapter* has to be relocatable,
            // because only the adapter is shared between models.
            model.wasm.clone()
        } else {
            link_fmu_component(
                &model.wasm,
                adapter,
                solvers.as_deref(),
                &model.ext_libs,
                natives.as_ref().map(|n| &n.stub[..]),
            )?
        };
        export_phase("FMU component link");
        // The modelIdentifier modelDescription.xml declares, not the class name:
        // an importer resolves `binaries/<platform>/<modelIdentifier>`.
        let model_id = model_name_prefix(&sim_code);
        let mut entries = vec![
            (
                "modelDescription.xml".to_string(),
                declare_log_streams(&announce_directional_derivatives(&model_description, &model)).into_bytes(),
            ),
        ];
        if !ls_dae_manifest.is_empty() {
            entries.push((LS_DAE_MANIFEST.to_string(), ls_dae_manifest.as_bytes().to_vec()));
        }
        if !bare {
            add_directory(&mut entries, &documentation_dir, "documentation");
            add_directory(&mut entries, &terminals_dir, "terminalsAndIcons");
        }
        // What the FMU was built with, where C's carries what its runtime reads.
        if !simulation_flags_json.is_empty() {
            entries.push((
                format!("resources/{}_flags.json", sim_code.fileNamePrefix),
                simulation_flags_json.as_bytes().to_vec(),
            ));
        }
        let version = fmi_version();
        // This machine's artifact, compiled once: the runs that follow in this
        // session get the live component and never read a `.cwasm` back.
        let host = compile_for_host(&component, &fmu_path, linked, bare);
        add_native_platforms(&mut entries, &component, &model_id, &version, linked, natives.as_ref(), host.as_ref())?;
        export_phase("FMU precompile");
        if version == "2.0" {
            if requested_native_platforms().is_empty() {
                record_error(format!(
                    "CodegenWasmJit: an FMI 2.0 FMU can only be loaded through a native binary — \
                     fmi-ls-wasm, which is what platforms={{\"wasm\"}} alone produces, is layered on \
                     FMI 3.0. Add the platforms to serve ({}), or export with version=\"3.0\".",
                    native_fmu::available().join(", ")
                ));
                return Err("CodegenWasmJit: an FMI 2.0 FMU needs a native platform");
            }
            entries.push(("resources/fmi2vr.json".to_string(), fmi2_vr_offsets(&sim_code)?.into_bytes()));
            // Not in binaries/: an FMI 2.0 FMU is not an fmi-ls-wasm one. Here so
            // a platform can still be added to it later, as the browser page does.
            entries.push((format!("resources/{model_id}.wasm"), component));
        } else if linked {
            // Not a component: the model kernel as a dylink library, which the host
            // links against the adapter and libc it has already compiled.
            entries.push((format!("{DYLINK_DIR}/{model_id}.wasm"), component));
            entries.push(("resources/artifact.json".to_string(), artifact_manifest(&model, sundials_available()).into_bytes()));
            for (i, lib) in model.ext_libs.iter().enumerate() {
                entries.push((format!("resources/ext/{i:02}.wasm"), lib.bytes.clone()));
            }
            if let Some(n) = &natives {
                entries.push((format!("resources/ext/{NATIVE_STUB}.wasm"), n.stub.clone()));
            }
        } else if natives.is_some() {
            // Imports `om:ext/native`, so no fmi-ls-wasm host can instantiate it:
            // out of `binaries/`, as an FMI 2.0 export is for the same reason.
            let names: Vec<&str> = model.ext_native.iter().map(|s| s.name.as_str()).collect();
            let _ = openmodelica_util::Error::addCompilerNotification(ArcStr::from(format!(
                "`external \"C\"` {} is served from a platform library, so this FMU's wasm binary \
                 imports `om:ext/native`, which fmi-ls-wasm does not define. It is at \
                 `resources/{model_id}.wasm` rather than `binaries/wasm32-wasip2/`, and runs only \
                 in an OpenModelica host or through one of the FMU's native platform binaries.",
                names.join(", ")
            ).as_str()));
            entries.push((format!("resources/{model_id}.wasm"), component));
        } else {
            entries.push((format!("binaries/wasm32-wasip2/{model_id}.wasm"), component));
        }
        if let Some(n) = &natives {
            entries.push((NATIVE_TABLE.to_string(), n.table.clone().into_bytes()));
            if version == "3.0" && !n.system.is_empty() {
                entries.push(("sources/buildDescription.xml".to_string(), external_build_description(&model_id, &n.system).into_bytes()));
            }
        }
        // What `Modelica.Utilities.Files.loadResource` named; C's `SimCodeMain`
        // copies the same set.
        for path in lst(&sim_code.modelInfo.resourcePaths) {
            add_resource(&mut entries, path);
        }
        // Ship the -d=visxml scene as a resource (the <Visualization> annotation
        // points at it), plus the CAD files it references so the scene is
        // self-contained. openmodelica_wasi::fs, not std::fs, which no-ops on wasm.
        if openmodelica_util::Flags::isSet(openmodelica_util::Flags::VISUAL_XML.clone()).unwrap_or(false) {
            let visual = format!("{}_visual.xml", sim_code.fileNamePrefix);
            if let Ok(data) = openmodelica_wasi::fs::read(&visual) {
                let xml = String::from_utf8_lossy(&data).into_owned();
                entries.push((format!("resources/{visual}"), data));
                for uri in cad_type_refs(&xml) {
                    let base = cad_basename(&uri);
                    if let Ok(path) = metamodelica::uriToFilename(ArcStr::from(uri.as_str())) {
                        if let Ok(bytes) = openmodelica_wasi::fs::read(&path) {
                            entries.push((format!("resources/{base}"), bytes));
                        }
                    }
                }
            }
        }
        let (packed, how) = if bare {
            write_directory(&fmu_path, &entries)?;
            (entries.iter().map(|(_, b)| b.len()).sum::<usize>(), "unzipped")
        } else {
            let fmu = zip_archive(&entries);
            let n = fmu.len();
            write_output(&fmu_path, &fmu).map_err(|_| "CodegenWasmJit: cannot write .fmu")?;
            (n, "zipped")
        };
        // Now that the files are there, hand the compiled component to the runs
        // that follow, pointed at the resources they read through.
        #[cfg(all(feature = "artifact", not(target_arch = "wasm32")))]
        if let Some(a) = &host {
            let path = std::path::Path::new(&*fmu_path);
            let resources = path.join("resources");
            if bare && resources.is_dir() {
                a.use_resources(&resources);
            }
            artifact::remember(path, a.clone());
        }
        export_phase(&format!("FMU write ({} MB {how})", (packed as f64 / 1.0e6 * 10.0).round() / 10.0));
        Ok(())
    })();
    if let Err(e) = &outcome {
        if openmodelica_util::Error::getNumErrorMessages() == errs_before {
            record_error(format!(
                "CodegenWasmJit: cannot build FMI {} {kind} FMU: {}",
                fmi_version(),
                with_engine_detail(e)
            ));
        }
    }
    outcome
}
