//! `build_sim_model`: assembling the model module from the SimCode, plus the
//! compiler-flag readers it needs.

use super::*;

/// Wasm function indices of the generated equation functions (after the
/// imports and the model's Modelica functions).
pub(super) struct EqFnIdx {
    parameters: u32,
    initial: u32,
    pub(super) ode: u32,
    pub(super) algebraics: u32,
    init_start_values: u32,
}

/// Where the model will run, which decides how an `Include` C source is built: for
/// the host, or for an artifact that is itself wasm (an FMU, the standalone module).
#[derive(Clone, Copy, PartialEq)]
pub(super) enum ExtHost {
    Native,
    Wasm,
}

impl ExtHost {
    /// A simulation run. The browser omc has neither a host compiler nor a dynamic
    /// loader, so there a run is as wasm as an exported FMU.
    pub(super) const SIM: ExtHost = if cfg!(target_arch = "wasm32") { ExtHost::Wasm } else { ExtHost::Native };
}

/// The wasm signature an `ext.*` import is declared with. In a shared-memory module
/// the import binds directly to the real symbol, so it takes the C or Fortran
/// argument list rather than the host-trampoline shape.
fn ext_import_sig(sig: &ExtCallSig) -> openmodelica_wasm_jit::sig::FnSig {
    use openmodelica_wasm_jit::sig::ExtLang;
    if !crate::CodegenWasmJitFunctions::externals_shared() {
        return sig.wasm_sig();
    }
    match sig.lang {
        ExtLang::Fortran77 => sig.wasm_sig_f77_shared(),
        ExtLang::C => sig.wasm_sig_c_shared(),
    }
}

/// `fmi_vrs`: also record the FMI value-reference table (FMU export only).
/// One `<entry>$guard`, per the wrappers `build_sim_model` emits.
fn build_guard_fn(target: u32) -> we::Function {
    use we::Instruction as I;
    let mut f = we::Function::new([(1, we::ValType::I32)]);
    let threw = 1; // param 0 is the SimData pointer
    f.instruction(&I::Block(we::BlockType::Empty)); // done
    f.instruction(&I::Block(we::BlockType::Result(we::ValType::EXNREF))); // handler
    f.instruction(&I::TryTable(we::BlockType::Empty, vec![we::Catch::OneRef { tag: 0, label: 0 }].into()));
    f.instruction(&I::LocalGet(0));
    f.instruction(&I::Call(target));
    f.instruction(&I::End); // try_table
    f.instruction(&I::I32Const(0));
    f.instruction(&I::LocalSet(threw));
    f.instruction(&I::Br(1)); // done
    f.instruction(&I::End); // handler: the exception is on the stack
    f.instruction(&I::Drop);
    f.instruction(&I::I32Const(1));
    f.instruction(&I::LocalSet(threw));
    f.instruction(&I::End); // done
    f.instruction(&I::LocalGet(threw));
    f.instruction(&I::End);
    f
}

pub(super) fn build_sim_model(
    sim_code: &SimCode::SimCode,
    fmi_vrs: bool,
    ext_host: ExtHost,
    cs_method: &str,
    fmi_solver_flags: &str,
) -> Result<SimModel> {
    crate::CodegenWasmJitFunctions::set_record_decls(&sim_code.recordDecls)?;
    let mi = &sim_code.modelInfo;
    let vi = &mi.varInfo;
    let scalarized_vars = scalarize_sim_vars(&mi.vars)?;
    let vars = &scalarized_vars;
    let states: Vec<&SimCodeVar::SimVar> = lst(&vars.stateVars).collect();

    let n_states = count(&vars.stateVars) as u32;
    let n_real_alg = real_alg_vars(vars).len() as u32;
    let n_real_param = count(&vars.paramVars) as u32;
    let samples = collect_samples(&sim_code.timeEvents)?;
    let zero_crossings = collect_zero_crossings(&sim_code.zeroCrossings)?;
    let relations = collect_relations(&sim_code.relations)?;
    let stateset_scratch_f64 = stateset_scratch_f64(&sim_code.stateSets)?;
    // Jacobian scratch region: nonlinear-system slots + torn-linear slots (after).
    let nls_jac_scratch_f64 = nls_jac_scratch_f64(sim_code) + lin_jac_scratch_f64(sim_code);
    let all_eqs = flatten_eqs(&sim_code.allEquations);
    let local_known_eqs = flatten_eqs(&sim_code.localKnownVars);
    // `--daeMode`: `allEquations`/`odeEquations` are empty and the whole continuous
    // system is `daeModeData.daeEquations`, the residual `F(t, y, y') = 0`.
    let dae_mode = sim_code.daeModeData.as_ref();
    let dae_eqs: Vec<(Arc<SimCode::SimEqSystem>, u32)> =
        dae_mode.map(|d| dae_residual_equations(d)).unwrap_or_default();
    let dae_res_vars: Vec<&SimCodeVar::SimVar> =
        dae_mode.map(|d| lst(&d.residualVars).collect()).unwrap_or_default();
    let dae_aux_vars: Vec<&SimCodeVar::SimVar> =
        dae_mode.map(|d| lst(&d.auxiliaryVars).collect()).unwrap_or_default();
    let dae_alg_vars: Vec<&SimCodeVar::SimVar> =
        dae_mode.map(|d| lst(&d.algebraicVars).collect()).unwrap_or_default();
    if dae_mode.is_some() && dae_res_vars.len() != (n_states as usize + dae_alg_vars.len()) {
        return Err("CodegenWasmJit: DAE mode residual count does not match states + algebraic unknowns");
    }
    // A model has discrete `when` behaviour through when-equations (SES_WHEN) or
    // when-statements inside an algorithm — both need the per-step pre-value save
    // and the full `allEquations` list as the per-step function.
    let when_scan = eqs_with_nested(&all_eqs);
    let has_when = dae_eqs.iter().map(|(e, _)| e).chain(when_scan.iter()).any(|e| match &**e {
        SimCode::SimEqSystem::SES_WHEN { .. } => true,
        SimCode::SimEqSystem::SES_ALGORITHM { statements, .. }
        | SimCode::SimEqSystem::SES_INVERSE_ALGORITHM { statements, .. } => {
            (&**statements).into_iter().any(|s| matches!(&**s, DAE::Statement::STMT_WHEN { .. }))
        }
        _ => false,
    });
    let has_homotopy = nls_homotopy_support(sim_code);
    // `--calculateSensitivities`: `sensitivityVars` is the `Ns` differentiated
    // parameters followed by the `Ns * nStates` `$Sensitivities.<par>.<state>`
    // signals (C's `rSen` init-XML category, split by `numSensitivityParameters`).
    let n_sens_par = vi.numSensitivityParameters.max(0) as usize;
    let sens_vars: Vec<&SimCodeVar::SimVar> = lst(&mi.vars.sensitivityVars).collect();
    let n_sens = sens_vars.len().saturating_sub(n_sens_par) as u32;
    let clocks = collect_clocks(&sim_code.clockedPartitions)?;
    let n_sub_clocks: u32 = clocks.iter().map(|c| c.meta.sub.len() as u32).sum();
    // `-l`: the symbolic A/B/C/D and the scratch their column equations need.
    let mut linz = build_linz_plan(sim_code, vars, n_states)?;
    // `-reconcile`: F/H, laid out right behind them.
    let mut recon = datarecon::build_plan(sim_code, vars);
    let sym_solver = sym_solver_kind()?;
    let layout = SimLayout::new(
        n_states,
        n_real_alg,
        n_real_param,
        count(&vars.intAlgVars) as u32,
        count(&vars.intParamVars) as u32,
        count(&vars.boolAlgVars) as u32,
        count(&vars.boolParamVars) as u32,
        count(&vars.stringAlgVars) as u32,
        count(&vars.stringParamVars) as u32,
        count(&vars.extObjVars) as u32,
        samples.len() as u32,
        zero_crossings.len() as u32,
        vi.numRelations.max(0) as u32,
        stateset_scratch_f64,
        nls_jac_scratch_f64,
        vi.numMathEventFunctions.max(0) as u32,
        n_sens,
        dae_res_vars.len() as u32,
        dae_aux_vars.len() as u32,
        dae_alg_vars.len() as u32,
        clocks.len() as u32,
        n_sub_clocks,
        linz.n_scratch_f64() + recon.n_scratch_f64(),
        // The optimizer's attribute arrays: one entry per real variable, only for a
        // model that carries an optimization problem.
        if optimization::is_optimization(sim_code) { 2 * n_states + n_real_alg } else { 0 },
        bound_attr_equations(sim_code).len() as u32,
        removed_init_residuals(sim_code).len() as u32,
        sym_solver,
        has_when,
        has_homotopy,
        homotopy_method()?,
        lst(&sim_code.initialEquations_lambda0).next().is_some(),
        // `delay(...)` / `spatialDistribution(...)`: the driver has to store their
        // accepted points, which costs an extra evaluation, so it asks first.
        sim_code.delayedExps.maxDelayedIndex >= 0 || sim_code.spatialInfo.maxIndex >= 0,
        // Mirroring the last accepted step's reals costs a copy per step, so only
        // a model with a method-1 linear system to read them asks for it.
        has_method1_linear(sim_code),
    );

    let (mut var_map, mut result_vars, editable_params) = build_var_map(vars, &layout)?;
    let (prof_plan, prof_info) = prof_plan(sim_code, mi)?;
    var_map.prof = prof_plan;
    // DAE-mode residual/auxiliary variables: their own `SimData` regions, indexed by
    // the SimVar's `index` as C's `crefToCStr` does. Solver workspace, not results.
    for (svs, base) in [(&dae_res_vars, layout.dae_res_off), (&dae_aux_vars, layout.dae_aux_off)] {
        for sv in svs.iter() {
            let i = u32::try_from(sv.index).map_err(|_| "CodegenWasmJit: DAE mode variable has no index")?;
            insert_var(&mut var_map, sv, base + i * 8, WTy::F64, false)?;
        }
    }
    // An auxiliary variable can be a whole array (`$AUX.w = f(…)`), so its element
    // group needs finalizing too.
    if dae_mode.is_some() {
        finalize_array_groups(&mut var_map)?;
    }
    // The inline equations' `__OMC_DT` and `<state>$Old` operands: `SimCodeUtil`
    // only ever put them in the cref->SimVar table, so no `modelInfo.vars` walk
    // reaches them.
    if sym_solver > 0 {
        Arc::make_mut(&mut var_map.vars).insert(
            "__OMC_DT".to_string(),
            SimSlot { off: layout.inline_dt_off, wty: WTy::F64, negate: Neg::None, heap: false },
        );
        for (i, sv) in states.iter().enumerate() {
            let old = openmodelica_frontend_base::ComponentReference::appendStringLastIdent(
                arcstr::literal!("$Old"),
                sv.name.clone(),
            )?;
            Arc::make_mut(&mut var_map.vars).insert(
                sim_cref_key(&old)?,
                SimSlot {
                    off: layout.alg_old_off + (i as u32) * 8,
                    wty: WTy::F64,
                    negate: Neg::None,
                    heap: false,
                },
            );
        }
    }
    let sens_params = push_sensitivity_vars(&sens_vars, n_sens_par, vars, &layout, &mut result_vars)?;
    let var_units = collect_var_units(vars)?;
    var_map.n_samples = samples.len() as u32;
    var_map.sample_active_off = layout.sample_active_off;
    // Delay-buffer count (0 when the model has no `delay(...)`).
    var_map.n_delays = (sim_code.delayedExps.maxDelayedIndex + 1).max(0) as u32;
    // Transported-profile count (`maxIndex` is -1 when the model has none).
    var_map.n_spatial = (sim_code.spatialInfo.maxIndex + 1).max(0) as u32;

    // State sets: register the Jacobian seed/result crefs at the scratch region
    // and collect the driver-side selection metadata (candidate/state/A offsets).
    let state_sets = build_state_set_infos(&sim_code.stateSets, &layout, &mut var_map)?;

    // Index -> equation map (for SES_ALIAS, which re-runs another equation by
    // index). An alias may point at an equation defined in a different system
    // list than the one being lowered (e.g. a parameter-equation alias to an
    // initial equation), or at an equation nested inside a torn linear/nonlinear
    // (or mixed / if-) system, so index every list recursively. `eqFunction_<n>`
    // is emitted once in the C target and shared; here the target is inlined.
    let mut eq_index: HashMap<i32, Arc<SimCode::SimEqSystem>> = HashMap::new();
    let index_list = |eqs: &List<Arc<SimCode::SimEqSystem>>, idx: &mut HashMap<i32, Arc<SimCode::SimEqSystem>>| {
        for e in lst(eqs) {
            index_eq_recursive(e, idx);
        }
    };
    index_list(&sim_code.allEquations, &mut eq_index);
    index_list(&sim_code.initialEquations, &mut eq_index);
    index_list(&sim_code.removedInitialEquations, &mut eq_index);
    index_list(&sim_code.parameterEquations, &mut eq_index);
    index_list(&sim_code.removedEquations, &mut eq_index);
    index_list(&sim_code.startValueEquations, &mut eq_index);
    index_list(&sim_code.algorithmAndEquationAsserts, &mut eq_index);
    index_list(&sim_code.equationsForZeroCrossings, &mut eq_index);
    index_list(&sim_code.inlineEquations, &mut eq_index);
    for e in dae_eqs.iter() {
        index_eq_recursive(&e.0, &mut eq_index);
    }
    for part in lst(&sim_code.odeEquations).chain(lst(&sim_code.algebraicEquations)) {
        index_list(part, &mut eq_index);
    }
    // Last: an index these lists share with one above keeps the earlier entry.
    index_list(&sim_code.initialEquations_lambda0, &mut eq_index);
    for e in clocked_eqs(sim_code).iter() {
        index_eq_recursive(e, &mut eq_index);
    }

    // --- Collect the model's Modelica functions (callable from equations). ---
    reset_declined_externals();
    let model_fns: Vec<&SimCodeFunction::Function::Function> = lst(&mi.functions)
        .map(|f| &**f)
        .filter(|f| {
            if matches!(f, SimCodeFunction::Function::Function::FUNCTION { .. }) || external_known(f) {
                return true;
            }
            match external_general_why(f) {
                Ok(()) => true,
                Err(why) => {
                    note_declined_external(f, why);
                    false
                }
            }
        })
        .collect();

    // Distinct `ext.<extName>` host imports for the general external scalar
    // functions, resolved by the host at instantiation (dlopen-self native; a
    // side module on wasm). Models without such externals emit none.
    let mut ext_imports: Vec<ExtCallSig> = Vec::new();
    let mut ext_seen: HashSet<String> = HashSet::new();
    for f in &model_fns {
        if external_general_why(f).is_ok() {
            let sig = external_import_sig(f)?;
            if ext_seen.insert(sig.name.clone()) {
                ext_imports.push(sig);
            }
        }
    }
    // A `Library` on a function the model never reaches must not fail the build.
    let mut ext_lib_notes: Vec<String> = Vec::new();
    let mut ext_libs = ExtLibraries::default();
    let mut ext_includes = None;
    let mut ext_archives = None;
    let mut ext_builtin = false;
    let mut ext_native: Vec<ExtCallSig> = Vec::new();
    if !ext_imports.is_empty() {
        let fortran = ext_imports.iter().any(|s| s.lang == openmodelica_wasm_jit::sig::ExtLang::Fortran77);
        ext_libs = resolve_ext_libraries(&sim_code.makefileParams, fortran, &mut ext_lib_notes)?;
        ext_builtin = builtin_wasm_needed(&ext_imports, &ext_libs.wasm);
        // What the `Library` annotations did not provide may come from an `Include`
        // carrying the C source, though most carry only the declarations.
        let mp = &sim_code.makefileParams;
        let sources: Vec<String> = lst(&sim_code.externalFunctionIncludes)
            .map(|s| s.to_string())
            .chain(std::mem::take(&mut ext_libs.sources))
            .collect();
        let dirs: Vec<String> = lst(&mp.includes).map(|s| s.to_string()).collect();
        let prefix = sim_code.fileNamePrefix.to_string();
        if !sources.is_empty() {
            // A hook ModelicaExternalC calls from inside the wasm is named by no
            // `ext` import and the native fallback cannot reach it, so it takes a
            // wasm library on either host. A wasm artifact carries every
            // implementation, so there the same decision is made off the exports.
            let hook = ext_builtin && include_overrides_builtin(&sources);
            if hook || ext_host == ExtHost::Wasm {
                let missing = missing_ext_symbols(&ext_imports, &ext_libs.wasm);
                if hook || !missing.is_empty() {
                    if let Some(l) = compile_include_library(&prefix, &sources, &dirs, &mp.cflags, &missing, &mut ext_lib_notes)? {
                        // Sources that only wrap a platform library still compile,
                        // and keeping the result would hide the functions from the
                        // host fallback that can serve them.
                        let unresolved = unresolved_dylink_needs(&dylink_needs(&l.bytes), &l, &ext_libs.wasm);
                        if unresolved.is_empty() {
                            ext_libs.wasm.push(l);
                        } else {
                            ext_lib_notes.push(format!(
                                "the `Include` C sources compiled for wasm but need `{}`, which no \
                                 wasm library defines; serving them from the host instead",
                                unresolved.join("`, `")
                            ));
                        }
                    }
                }
            }
        }
        // What no wasm library defines, a shared-memory kernel hands to the host.
        if ext_host == ExtHost::Wasm && crate::CodegenWasmJitFunctions::externals_shared() {
            ext_native = missing_ext_symbols(&ext_imports, &ext_libs.wasm);
        }
        crate::CodegenWasmJitFunctions::set_native_externals(ext_native.iter().map(|s| s.name.clone()));
        let want_native = ext_host == ExtHost::Native || !ext_native.is_empty();
        let symbols: Vec<String> = ext_imports.iter().map(|s| s.name.clone()).collect();
        // Built on demand, for a symbol the loaded libraries turn out not to define.
        // The archives are on this link too, not only on their own: a member only
        // these sources reference is pulled in by nothing else.
        if !sources.is_empty() && want_native {
            ext_includes = Some(ExtIncludes {
                sources,
                include_dirs: dirs,
                libs: ext_libs.native.iter().chain(&ext_libs.fallback).cloned().collect(),
                archives: ext_libs.archives.clone(),
                symbols: symbols.clone(),
                ccompiler: mp.ccompiler.to_string(),
                cflags: mp.cflags.to_string(),
                dllext: mp.dllext.to_string(),
                prefix: prefix.clone(),
            });
        }
        if !ext_libs.archives.is_empty() && want_native {
            ext_archives = Some(ExtArchives {
                archives: std::mem::take(&mut ext_libs.archives),
                symbols,
                ccompiler: mp.ccompiler.to_string(),
                dllext: mp.dllext.to_string(),
                prefix,
            });
        }
    }

    // Function index space: imports (env builtins, rt runtime, env-extra, then
    // the `ext.*` externals), then the model's Modelica functions, then the
    // generated equation functions.
    let ext_base = (BUILTINS.len() + RT_BUILTINS.len() + ENV_EXTRA.len()) as u32;
    let import_base = ext_base + ext_imports.len() as u32;
    let mut by_name: HashMap<String, FnInfo> = HashMap::new();
    for (i, sig) in ext_imports.iter().enumerate() {
        by_name.insert(format!("ext.{}", sig.name), FnInfo { index: ext_base + i as u32, sig: ext_import_sig(sig) });
    }
    for (id, f) in model_fns.iter().enumerate() {
        let (name, sig) = function_signature(f)?;
        by_name.insert(name, FnInfo { index: import_base + id as u32, sig });
    }
    let eq_base = import_base + model_fns.len() as u32;
    let eqfn = EqFnIdx {
        parameters: eq_base,
        initial: eq_base + 1,
        ode: eq_base + 2,
        algebraics: eq_base + 3,
        // Always emitted (no-op with no states) so the fixed indices below hold.
        init_start_values: eq_base + 4,
    };
    let simulate_idx = eq_base + 5;
    // The two metadata accessors the standalone wasip1 runtime imports
    // (`om_meta_ptr`/`om_meta_len`), appended after `simulate`.
    let om_meta_ptr_idx = eq_base + 6;
    let om_meta_len_idx = eq_base + 7;

    // --- Equation lists + nonlinear-system registration. Flattened here (before
    // the type/import sections, which need to know whether the model has any
    // nonlinear systems) and consumed by the equation-function builders below. ---
    let param_eqs = flatten_eqs(&sim_code.parameterEquations);
    mark_unvarying(&mut result_vars, &param_eqs)?;
    let initial_eqs = flatten_eqs(&sim_code.initialEquations);
    let mut computed_params = assigned_cref_keys(&eqs_with_nested(&param_eqs));
    computed_params.extend(assigned_cref_keys(&eqs_with_nested(&initial_eqs)));
    let param_bindings = collect_param_bindings(vars, &computed_params);
    // C's `functionODE` and `functionDAE` both open with `functionLocalKnownVars`
    // (`--preOptModules+=removeLocalKnownVars` moves the equations that depend only
    // on states and inputs there); empty unless that module ran.
    let with_local_known = |eqs: Vec<Arc<SimCode::SimEqSystem>>| -> Vec<Arc<SimCode::SimEqSystem>> {
        if local_known_eqs.is_empty() {
            return eqs;
        }
        let mut out = local_known_eqs.clone();
        out.extend(eqs);
        out
    };
    let alg_eqs_raw = flatten_eqs_ll(&sim_code.algebraicEquations);
    let algebraic_eqs = with_local_known(alg_eqs_raw.clone());
    // C's `storePreValues` at the end of `updateContinuousSystem`, which here tails
    // `functionAlgebraics` (see `sim_save_pre_values`).
    let save_pre: Vec<(u32, u32, u32)> = if has_when {
        vec![
            (layout.pre_real_off, REAL_OFF, (2 * layout.n_states + layout.n_real_alg) * 8),
            (layout.pre_int_off, layout.int_off, layout.n_int_alg() * 4),
            (layout.pre_bool_off, layout.bool_off, layout.n_bool_alg() * 4),
        ]
    } else {
        Vec::new()
    };
    let lambda0_eqs = flatten_eqs(&sim_code.initialEquations_lambda0);
    let assert_eqs = flatten_eqs(&sim_code.algorithmAndEquationAsserts);
    let ode_eqs = with_local_known(flatten_eqs_ll(&sim_code.odeEquations));
    let parmod = openmodelica_util::Flags::getConfigBool(openmodelica_util::Flags::PARMODAUTO.clone())?;
    let ode_task_eqs = flatten_eqs_ll(&sim_code.odeEquations);
    let parmod_info = match parmod && !ode_task_eqs.is_empty() {
        true => Some(parmod_info(&ode_task_eqs)?),
        false => None,
    };
    let zc_eqs = flatten_eqs(&sim_code.equationsForZeroCrossings);
    let inline_eqs = flatten_eqs(&sim_code.inlineEquations);
    // Register every nonlinear system with the runtime solver `rt_solve_nls`
    // *before* lowering the equation functions (which call it): assign each a
    // shared-table job and thread the map through `var_map`. The systems' own
    // `residual`/`load` callbacks are emitted after the equation functions.
    let nls_nominal_map = build_nls_nominal_map(vars);
    let mut attr_targets: HashMap<String, AttrTargets> = HashMap::new();
    let dae_only_eqs: Vec<Arc<SimCode::SimEqSystem>> = dae_eqs.iter().map(|(e, _)| e.clone()).collect();
    let removed_init_eqs = flatten_eqs(&sim_code.removedInitialEquations);
    let clocked = clocked_eqs(sim_code);
    let nls_scan: Vec<Vec<Arc<SimCode::SimEqSystem>>> = [
        &param_eqs, &initial_eqs, &lambda0_eqs, &ode_eqs, &algebraic_eqs, &dae_only_eqs, &zc_eqs,
        &assert_eqs, &removed_init_eqs, &clocked, &inline_eqs,
    ]
    .iter()
    .map(|l| eqs_with_nested(l.as_slice()))
    .collect();
    let (nls_systems, nls_jobs, nls_hist_bytes, nls_nominals, nls_bounds, nls_patterns, nls_warnings) = collect_nls_jobs(
        &nls_scan.iter().map(|l| l.as_slice()).collect::<Vec<_>>(),
        &nls_nominal_map,
        &mut attr_targets,
    );
    // Dynamic tearing: casual set index -> strict set index.
    let nls_strict_of = nls_strict_map(&nls_scan.iter().map(|l| l.as_slice()).collect::<Vec<_>>());
    // The integrator's per-unknown atol and the Jacobian's FD step floor: the states,
    // then in DAE mode the algebraic unknowns (C's `getAlgebraicDAEVarNominals`).
    let mut nominal_defaults: Vec<(u32, f64)> = Vec::new();
    for (svs, base) in [
        (lst(&vars.stateVars).take(n_states as usize).collect::<Vec<_>>(), layout.state_nom_off),
        (dae_alg_vars.clone(), layout.dae_alg_nom_off),
    ] {
        for (i, sv) in svs.iter().enumerate() {
            let off = base + (i as u32) * 8;
            nominal_defaults.push((off, const_value(&sv.nominalValue).unwrap_or(1.0).abs().max(1e-32)));
            if let Ok(k) = sim_cref_key(&sv.name) {
                attr_targets.entry(k).or_default().nom_offs.push(off);
            }
        }
    }
    // C's `functionJacAC_num` reads each state's `max` to sign its step.
    let mut max_defaults: Vec<(u32, f64)> = Vec::new();
    for (i, sv) in lst(&vars.stateVars).take(n_states as usize).enumerate() {
        let off = layout.state_max_off + (i as u32) * 8;
        max_defaults.push((off, const_value(&sv.maxValue).unwrap_or(f64::MAX)));
        if let Ok(k) = sim_cref_key(&sv.name) {
            attr_targets.entry(k).or_default().max_offs.push(off);
        }
    }
    // Register the analytic-Jacobian seed/result crefs before the equation
    // functions are lowered, so the column equations resolve their slots.
    let nls_jac_infos = build_nls_jac_infos(&nls_systems, &layout, &mut var_map)?;
    // Same, for torn linear systems that assemble A analytically.
    build_lin_jac_infos(sim_code, &layout, &mut var_map)?;
    // Same, for the `-l` matrices; "A" there is the ODE state Jacobian, so these
    // are also the slots the integrators seed and read.
    let (linz_jac_infos, adj_jac_info) = build_linz_jac_infos(&linz, &layout, &mut var_map)?;
    let recon_base = layout.linz_off + linz.n_scratch_f64() * 8;
    let mut recon_jac_infos = datarecon::build_jac_infos(&recon, recon_base, &mut var_map)?;
    var_map.nls_jobs = Arc::new(nls_jobs);
    var_map.generic_calls = Arc::new(
        lst(&sim_code.generic_loop_calls).map(|c| (generic_call_index(c), c.clone())).collect(),
    );

    // --- Type section: one type per import, per model function, per equation
    // function (all take one i32 `SimData` ptr, no result), then `simulate`
    // (f64,f64,f64,i32 -> i32). ---
    let mut types = we::TypeSection::new();
    for (_, params, result) in BUILTINS {
        types.ty().function(params.iter().map(|w| w.val()), [result.val()]);
    }
    for (_, params, results) in RT_BUILTINS {
        types.ty().function(params.iter().map(|w| w.val()), results.iter().map(|w| w.val()));
    }
    for (_, params, results) in ENV_EXTRA {
        types.ty().function(params.iter().map(|w| w.val()), results.iter().map(|w| w.val()));
    }
    // One type per `ext.*` external import: input args -> outputs (multi-value).
    let mut ext_type: Vec<u32> = Vec::with_capacity(ext_imports.len());
    for sig in &ext_imports {
        let ti = types.len();
        let s = ext_import_sig(sig);
        types.ty().function(
            s.params.iter().map(|s| s.wty().val()),
            s.results.iter().map(|s| s.wty().val()),
        );
        ext_type.push(ti);
    }
    // `om_throw_model_error`'s type, shared with the `model_error` tag: a
    // library's `ModelicaError` throws it and the `ext` call site catches it,
    // C's `longjmp` out of a residual. Only a model with external "C" carries a
    // tag — a module with one needs an engine that takes the exception-handling
    // proposal.
    let throw_fn_type = types.len();
    types.ty().function([], []);
    // A host-free module also carries one: nothing outside it catches a trap, so a
    // failed `assert()` unwinds to the entry point it fired under instead.
    let host_free = matches!(ext_host, ExtHost::Wasm);
    let error_tag_type = (!ext_imports.is_empty() || host_free).then_some(throw_fn_type);
    // `<entry>$guard`'s type: (i32 SimData) -> i32, nonzero if it threw.
    let guard_fn_type = types.len();
    types.ty().function([we::ValType::I32], [we::ValType::I32]);
    let mut model_fn_type: Vec<u32> = Vec::with_capacity(model_fns.len());
    for f in &model_fns {
        let (_, sig) = function_signature(f)?;
        let ti = types.len();
        types.ty().function(
            sig.params.iter().map(|s| s.wty().val()),
            sig.results.iter().map(|s| s.wty().val()),
        );
        model_fn_type.push(ti);
    }
    // Equation function type: (i32) -> ().
    let eqfn_type = types.len();
    types.ty().function([we::ValType::I32], []);
    // simulate type: (i32 simdata, f64 start, f64 stop, i32 nsteps) -> i32 buf.
    let simulate_type = types.len();
    types.ty().function(
        [we::ValType::I32, we::ValType::F64, we::ValType::F64, we::ValType::I32],
        [we::ValType::I32],
    );
    // `om_meta_ptr`/`om_meta_len` type: () -> i32.
    let meta_fn_type = types.len();
    types.ty().function([], [we::ValType::I32]);
    // Nonlinear-solver callback types (only when the model has nonlinear systems,
    // so output stays byte-identical otherwise): `residual` (i32,i32,i32)->(),
    // `load` (i32,i32)->(). The `start` type is allocated at the end, with the
    // closure thunks' types.
    let nls_types = if nls_systems.is_empty() {
        None
    } else {
        let residual_type = types.len();
        types.ty().function([we::ValType::I32, we::ValType::I32, we::ValType::I32], []);
        let load_type = types.len();
        types.ty().function([we::ValType::I32, we::ValType::I32], []);
        // Dynamic tearing's strict-set callback: (i32) -> i32.
        let strict_type = types.len();
        types.ty().function([we::ValType::I32], [we::ValType::I32]);
        Some((residual_type, load_type, strict_type))
    };
    // `evaluateDAEResiduals(SimData*, stage)`: (i32,i32) -> (). Emitted (empty for an
    // explicit-ODE model) either way, so the shared FMI adapter can import it.
    let dae_fn_type = {
        let ti = types.len();
        types.ty().function([we::ValType::I32, we::ValType::I32], []);
        ti
    };
    // `functionUpdateSynchronous`/`functionEquationsSynchronous`: (i32,i32) -> ().
    let sync_fn_type = {
        let ti = types.len();
        types.ty().function([we::ValType::I32, we::ValType::I32], []);
        ti
    };
    // Function references met while lowering the bodies add thunks to the closure
    // pool; this global holds their shared-table base.
    let closure_global = crate::CodegenWasmJitFunctions::closure_base_global(nls_types.is_some());
    crate::CodegenWasmJitFunctions::closures::begin(types.len(), closure_global);
    let lit_global = crate::CodegenWasmJitFunctions::lit_base_global(nls_types.is_some());
    crate::CodegenWasmJitFunctions::shared_lits::begin(lit_global);

    // --- Import section. ---
    let mut imports = we::ImportSection::new();
    imports.import(
        "rt",
        "memory",
        we::MemoryType { minimum: 0, maximum: None, memory64: false, shared: false, page_size_log2: None },
    );
    for (i, (name, _, _)) in BUILTINS.iter().enumerate() {
        // Math builtins are provided in-wasm by the runtime module (via libm),
        // not the host `env` namespace — see the runtime's rt_math exports.
        imports.import("rt", *name, we::EntityType::Function(i as u32));
    }
    for (j, (name, _, _)) in RT_BUILTINS.iter().enumerate() {
        imports.import("rt", *name, we::EntityType::Function((BUILTINS.len() + j) as u32));
    }
    for (k, (name, _, _)) in ENV_EXTRA.iter().enumerate() {
        // `rt_assert` is imported from `rt`, not the host `env`: for the JIT path
        // the host registers it under `rt` alongside the runtime instance, and for
        // the standalone wasip1 export the merged runtime provides it — so the
        // model module never imports anything from `env` (clean wasm-merge).
        imports.import("rt", *name, we::EntityType::Function((BUILTINS.len() + RT_BUILTINS.len() + k) as u32));
    }
    // General external "C" functions: imported from module `ext`, resolved by
    // the host (dlopen-self native; side module on wasm).
    for (i, sig) in ext_imports.iter().enumerate() {
        imports.import("ext", &sig.name, we::EntityType::Function(ext_type[i]));
    }

    // --- Compile bodies (collecting String literals into the module pool). ---
    let mut literals = Literals::default();
    let mut bodies: Vec<we::Function> = Vec::new();
    // With a tag in the module, every `ext` call is lowered under a `try_table`
    // (tag index 0: the module imports none).
    crate::CodegenWasmJitFunctions::set_ext_error_catch(error_tag_type.map(|_| 0));
    crate::CodegenWasmJitFunctions::set_assert_throw_tag(host_free.then_some(0));
    // Model functions first, in index order; poll for cancellation between them so
    // a long emit is interruptible like the frontend/backend upstream.
    for f in &model_fns {
        metamodelica::cancel::bail_if_cancelled()?;
        bodies.push(compile_function(f, &by_name, &mut literals)?);
    }
    // C's `setAllParamsToStart`: every parameter from its binding, in declaration
    // order (the backend sorts dependent parameters so a binding only references
    // earlier ones). `parameterEquations` belongs to `functionUpdateBoundParameters`
    // alone — evaluated in both, an external object's constructor runs twice.
    let stateset_diag = stateset_diag_offsets(&sim_code.stateSets, &var_map)?;
    let mut pool = ChunkPool::default();
    let mut splits: Vec<SplitFn> = Vec::new();
    let param_units: Vec<EqUnit> =
        param_bindings.iter().map(|(cref, exp)| EqUnit::Binding(cref, exp)).collect();
    splits.push(build_split_fn("functionParameters", &param_units, 1, eqfn_type, &stateset_diag, &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
    // Seed `relationsPre := relations` at the end of init (the in-wasm `simulate`
    // path skips the host `run_initialization`).
    let init_save: Vec<(u32, u32, u32)> = if layout.n_rel > 0 {
        vec![(layout.relations_pre_off, layout.relations_off, layout.n_rel * 4)]
    } else {
        Vec::new()
    };
    splits.push(build_split_fn("functionInitialEquations", &eq_units(&initial_eqs), 1, eqfn_type, &[], &init_save, &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
    // Three orders over one equation set, so where they agree on a run they call the
    // same chunk. Not under `--parmodauto`, whose tasks *are* the ODE chunks.
    let shared = match parmod_info.is_none() {
        true => eq_segments(&ode_task_eqs, &alg_eqs_raw, &all_eqs),
        false => None,
    };
    // A chunk of its own, so the equations before it stay shared.
    let pre_store = |pool: &mut ChunkPool, literals: &mut Literals| -> Result<Vec<usize>> {
        match save_pre.is_empty() {
            true => Ok(Vec::new()),
            false => build_chunks("storePreValues", &[], 1, eqfn_type, &[], &save_pre, &var_map, &eq_index, &by_name, literals, pool, false),
        }
    };
    let ode_split = splits.len();
    let dae_chunks = match shared {
        Some(segs) => {
            let (ode, mut alg, dae) = build_shared_eq_chunks(segs, &all_eqs, &local_known_eqs, eqfn_type, &var_map, &eq_index, &by_name, &mut literals, &mut pool)?;
            alg.extend(pre_store(&mut pool, &mut literals)?);
            for chunks in [ode, alg] {
                let slot = bodies.len();
                bodies.push(empty_eqfn());
                splits.push(SplitFn { slot, chunks, n_params: 1, pre_calls: Vec::new() });
            }
            Some(dae)
        }
        // `--parmodauto`: one chunk per ODE equation, each a schedulable task.
        None => {
            if parmod_info.is_some() {
                splits.push(build_split_fn("functionODE", &eq_units(&ode_task_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, true)?);
            } else {
                splits.push(build_split_fn("functionODE", &eq_units(&ode_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
            }
            let slot = bodies.len();
            bodies.push(empty_eqfn());
            let mut chunks = build_chunks("functionAlgebraics", &eq_units(&algebraic_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut pool, false)?;
            chunks.extend(pre_store(&mut pool, &mut literals)?);
            splits.push(SplitFn { slot, chunks, n_params: 1, pre_calls: Vec::new() });
            None
        }
    };
    // eq_base + 4, before `simulate` so the in-wasm integrator can call it.
    let all_reals: Vec<&SimCodeVar::SimVar> = states
        .iter()
        .copied()
        .chain(lst(&vars.derivativeVars))
        .chain(real_alg_vars(vars))
        .collect();
    bodies.push(build_init_start_values_fn(&all_reals, &layout, &var_map, &by_name, &mut literals)?);
    // A start or nominal bound to a parameter arrives as an attribute equation;
    // `functionUpdateBoundVariableAttributes` fills these slots from those.
    for (i, sv) in all_reals.iter().enumerate() {
        let nom_off = layout.real_nominal_off(i as u32);
        nominal_defaults.push((nom_off, literal_value(&sv.nominalValue).unwrap_or(1.0)));
        if let Ok(k) = sim_cref_key(&sv.name) {
            let t = attr_targets.entry(k).or_default();
            t.start_offs.push(layout.real_start_off(i as u32));
            t.raw_nom_offs.push(nom_off);
        }
    }
    // The integrator loop calls `functionCheckAsserts`, whose index is only known
    // once the nonlinear systems below have taken theirs; keep its fixed slot
    // (`simulate_idx`) and fill it in there.
    let simulate_slot = bodies.len();
    bodies.push(empty_eqfn());

    // --- Standalone-export metadata: encode the SimData layout, the run settings
    // and the result variables into a blob the standalone wasip1 runtime decodes
    // (via the `om_meta_ptr`/`om_meta_len` exports). It rides in the last passive
    // data segment and is materialized at run time into a runtime-allocated buffer
    // with `memory.init`, exactly like a String literal. These accessors are
    // harmless on the JIT path (unused). ---
    let settings = sim_code
        .simulationSettingsOpt
        .as_ref()
        .ok_or_else(|| "CodegenWasmJit: model has no simulation settings")?;
    apply_variable_filter(&mut result_vars, &settings.variableFilter);
    let model_name = openmodelica_frontend_dump::AbsynUtil::pathString(mi.name.clone(), arcstr::literal!("."), true, false)?.to_string();
    // Solver metadata, shared by the embedded blob and the host `SimModel`.
    let jac_a_n = match dae_mode {
        Some(_) => dae_res_vars.len() as u32,
        None => n_states,
    };
    let mut jac_a = build_jac_a_info(sim_code, jac_a_n);
    // Build the driver metadata once: embedded in the module (for the in-wasm
    // driver / standalone) and kept on the `SimModel` (for the host driver).
    // Only the FMU export needs the vr table; a plain simulation would just carry
    // it around unused.
    let (fmi_vrs, fmi_dae_enable_vr) =
        if fmi_vrs { build_fmi_vrs(sim_code, &var_map, &layout)? } else { (Vec::new(), 0) };
    // C labels its `-lv=LOG_NLS` unknowns from the `_info.json` `defines` array,
    // which `SerializeModelInfo` writes from these same `crefs`.
    // C diagnoses (`newtonDiagnostics`) the systems of `initialEquations_lambda0`,
    // or of `initialEquations` when there is no lambda0 section.
    let nls_in = |eqs: &[Arc<SimCode::SimEqSystem>]| -> HashSet<i32> {
        eqs.iter()
            .filter_map(|e| match &**e {
                SimCode::SimEqSystem::SES_NONLINEAR { nlSystem, .. } => Some(nlSystem.index),
                _ => None,
            })
            .collect()
    };
    let diag_nls = if lambda0_eqs.is_empty() { nls_in(&initial_eqs) } else { nls_in(&lambda0_eqs) };
    let nls_vars = nls_systems
        .iter()
        .map(|sys| {
            let names = lst(&sys.crefs).map(cref_display).collect::<Result<Vec<_>>>()?;
            // C's `eqn_simcode_indices` runs over the torn equations first; only
            // the `size` residual ones at the end are read back.
            let eqns: Vec<i32> = lst(&sys.eqs).map(|e| eq_index_of(e)).collect();
            let tail = eqns.len().saturating_sub(names.len());
            let pattern = match &sys.jacobianMatrix {
                Some(jm) => [
                    lst(&jm.nonlinear).count() as u32,
                    lst(&jm.nonlinearT).count() as u32,
                    lst(&jm.nonlinear).map(|(_, cols)| lst(cols).count() as u32).sum(),
                ],
                None => [0; 3],
            };
            Ok(openmodelica_sim_meta::NlsVars {
                eq_index: sys.index as u32,
                names,
                eqns: eqns[tail..].to_vec(),
                pattern,
                init_diag: diag_nls.contains(&sys.index),
            })
        })
        .collect::<Result<Vec<_>>>()?;
    // The residual Jacobian's sparsity is a matrix of its own, not the ODE `A` that
    // the backend leaves empty in DAE mode.
    let dae = dae_mode
        .map(|d| -> Result<openmodelica_sim_meta::DaeInfo> {
            let alg_offs = dae_alg_vars
                .iter()
                .map(|sv| {
                    let key = sim_cref_key(&sv.name)?;
                    var_map
                        .vars
                        .get(&key)
                        .map(|s| s.off)
                        .ok_or("CodegenWasmJit: DAE mode algebraic unknown has no SimData slot")
                })
                .collect::<Result<Vec<u32>>>()?;
            Ok(openmodelica_sim_meta::DaeInfo {
                alg_offs,
                sparsity: d.sparsityPattern.as_ref().and_then(|jm| jac_pattern_info(jm, dae_res_vars.len())),
            })
        })
        .transpose()?;
    // Lowering the columns is what decides which matrices survive; everything below
    // reads `linz.jacs` after this.
    let (linz_jac_fns, jac_a_fns, opt_jac_fns, jac_adj_fns) = build_jac_fns(
        &mut linz, &linz_jac_infos, optimization::is_optimization(sim_code), &layout, &var_map,
        &eq_index, &by_name, &mut literals, adj_jac_info.as_ref().map(|a| &a.map),
    )?;
    // Same for F/H, before the metadata is built: a matrix that does not lower is
    // dropped from the plan, and `ReconInfo` must not advertise it.
    let recon_jac_fns = match recon.present {
        true => Some(datarecon::build_jac_fns(
            &mut recon, &mut recon_jac_infos, &var_map, &eq_index, &by_name, &mut literals,
        )?),
        false => None,
    };
    // C's `JACOBIAN_AVAILABLE`: "A" lowered, at a shape indexable by state.
    if let (Some(info), Some(sym_info)) = (jac_a.as_mut(), linz_jac_infos[0].as_ref())
        && linz.jacs[0].is_some()
        && sym_info.seed_offs.len() == n_states as usize
        && sym_info.result_offs.len() == n_states as usize
    {
        info.sym = Some(openmodelica_sim_meta::JacSym {
            seed_offs: sym_info.seed_offs.clone(),
            // A row the backend left out is structurally zero, so it has no slot.
            result_offs: sym_info.result_offs.iter().map(|o| o.unwrap_or(u32::MAX)).collect(),
            has_constant: linz.jacs[0]
                .as_ref()
                .and_then(|jm| lst(&jm.columns).next())
                .is_some_and(|c| lst(&c.constantEqns).next().is_some()),
            adj: None,
        });
        if let (Some(jm), Some(adj), Some(sym)) = (linz.adj.as_ref(), adj_jac_info.as_ref(), info.sym.as_mut())
            && adj.info.seed_offs.len() == n_states as usize
            && adj.info.result_offs.len() == n_states as usize
        {
            sym.adj = Some(openmodelica_sim_meta::JacAdj {
                seed_offs: adj.info.seed_offs.clone(),
                result_offs: adj.info.result_offs.iter().map(|o| o.unwrap_or(u32::MAX)).collect(),
                zero_offs: adj.zero_offs.clone(),
                has_constant: lst(&jm.columns).next().is_some_and(|c| lst(&c.constantEqns).next().is_some()),
                row_colors: row_coloring(&info.rows_by_col, n_states as usize),
            });
        }
    }
    // `method="optimization"`: B, C and D with the slots the optimizer seeds and
    // reads, plus the problem's own metadata.
    let opt_info = {
        let jacs: [Option<openmodelica_sim_meta::OptJac>; 3] = core::array::from_fn(|i| {
            let k = i + 1; // B, C, D
            let (jm, info) = (linz.jacs[k].as_ref()?, linz_jac_infos.get(k)?.as_ref()?);
            Some(optimization::opt_jac(
                jm,
                linz.real_rows[k],
                linz.real_cols[k],
                &info.seed_offs,
                &info.result_offs,
                OPT_JAC_FNS[2 * i + 1],
                match lst(&jm.columns).next().is_some_and(|c| lst(&c.constantEqns).next().is_some()) {
                    true => OPT_JAC_FNS[2 * i],
                    false => "",
                },
            ))
        });
        let reals: Vec<&SimCodeVar::SimVar> = states
            .iter()
            .copied()
            .chain(lst(&vars.derivativeVars))
            .chain(real_alg_vars(vars))
            .collect();
        optimization::build_opt_info(sim_code, vars, &reals, jacs, &var_map)?
    };
    // C's `inputNames` / `nInputVars`. No slot ⇒ no column to receive.
    let mut input_vars: Vec<openmodelica_sim_meta::InputVar> = Vec::new();
    for sv in lst(&vars.inputVars) {
        let key = sim_cref_key(&sv.name)?;
        let name = cref_display(&sv.name)?;
        match all_reals.iter().position(|r| sim_cref_key(&r.name).ok().as_deref() == Some(key.as_str())) {
            Some(i) => input_vars.push(openmodelica_sim_meta::InputVar {
                off: openmodelica_sim_meta::REAL_OFF + i as u32 * 8,
                start_off: layout.real_start_off(i as u32),
                wty: WTy::F64,
                name,
            }),
            None => {
                if let Some(slot) = var_map.vars.get(&key) {
                    input_vars.push(openmodelica_sim_meta::InputVar {
                        off: slot.off,
                        start_off: slot.off,
                        wty: slot.wty,
                        name,
                    });
                }
            }
        }
    }
    let meta = build_sim_meta(
        &layout, &result_vars, collect_unit_defs(mi, &result_vars), settings, cs_method, fmi_solver_flags, &model_name,
        &sim_code.fileNamePrefix, jac_a.clone(), &state_sets,
        fmi_vrs, fmi_dae_enable_vr, zc_descriptions(&zero_crossings), rel_descriptions(&sim_code.relations),
        param_vars(vars)?, attr_log_entries(sim_code)?,
        removed_init_residuals(sim_code).iter().map(|e| dump_exp(e)).collect(),
        nls_warnings.clone(),
        samples.iter().map(|s| s.index).collect(), soti_vars(vars)?, sens_params, nls_vars,
        mi.varInfo.numLinearSystems.max(0) as u32, dae,
        clocks.iter().map(|c| c.meta.clone()).collect(),
        build_lin_info(&linz, vars, &var_map)?,
        opt_info, input_vars,
        datarecon::build_recon_info(
            sim_code, vars, &recon, &recon_jac_infos, &var_map,
            mi.varInfo.numRelatedBoundaryConditions.max(0) as u32,
        )?,
        prof_info,
        parmod_info.clone(),
    );
    let meta_bytes = openmodelica_sim_meta::encode(&meta);
    let meta_len = meta_bytes.len() as u32;
    let meta_off = literals.intern(&meta_bytes);
    {
        // om_meta_ptr(): rt_alloc(len), memory.init the blob into it, return ptr.
        use we::Instruction as I;
        let mut f = we::Function::new([(1, we::ValType::I32)]);
        f.instruction(&I::I32Const(meta_len as i32));
        f.instruction(&I::Call(rt_index("rt_alloc")?));
        f.instruction(&I::LocalTee(0));
        f.instruction(&I::I32Const(meta_off as i32));
        f.instruction(&I::I32Const(meta_len as i32));
        f.instruction(&I::MemoryInit { mem: 0, data_index: 0 });
        f.instruction(&I::LocalGet(0));
        f.instruction(&I::End);
        bodies.push(f);
    }
    {
        // om_meta_len(): the constant blob length.
        use we::Instruction as I;
        let mut f = we::Function::new([]);
        f.instruction(&I::I32Const(meta_len as i32));
        f.instruction(&I::End);
        bodies.push(f);
    }

    // --- External-object destructors (teardown). One function that calls each
    // extObj's `<class>.destructor(handle)`, reading the handle from its SimData
    // slot, in `listReverse(extObjInfo.vars)` order as CodegenC's
    // `callExternalObjectDestructors` does — the causalized construction order,
    // a different permutation from the `extObjVars` slot order. ---
    let extobj_vars: Vec<&SimCodeVar::SimVar> = lst(&vars.extObjVars).collect();
    let extobj_slot: HashMap<String, u32> = extobj_vars
        .iter()
        .enumerate()
        .map(|(i, sv)| Ok((sim_cref_key(&sv.name)?, layout.eobj_off + (i as u32) * 4)))
        .collect::<Result<_>>()?;
    let mut destruct_order: Vec<&SimCodeVar::SimVar> = lst(&sim_code.extObjInfo.vars).collect();
    if destruct_order.len() != extobj_vars.len()
        || destruct_order.iter().any(|sv| {
            sim_cref_key(&sv.name).is_ok_and(|k| !extobj_slot.contains_key(&k))
        })
    {
        destruct_order = extobj_vars.clone();
    }
    destruct_order.reverse();
    // `(destructor index, SimData slot)` per object, in that order.
    let destruct_calls: Vec<(u32, u32)> = destruct_order
        .iter()
        .map(|sv| {
            let key = extobj_destructor_key(sv)?;
            let didx = by_name
                .get(&key)
                .ok_or_else(|| "CodegenWasmJit: external-object destructor was not compiled")?
                .index;
            let slot = *extobj_slot
                .get(&sim_cref_key(&sv.name)?)
                .ok_or_else(|| "CodegenWasmJit: external object has no SimData slot")?;
            Ok((didx, slot))
        })
        .collect::<Result<_>>()?;
    // Always emitted + exported (empty when the model has no external objects) so
    // the standalone `wasm-merge` and interactive table always resolve it. It is
    // the first body after the fixed base functions, so its index stays `eq_base+8`.
    let destructors_idx = {
        use we::Instruction as I;
        let mut f = we::Function::new([]);
        for &(didx, slot) in &destruct_calls {
            f.instruction(&I::LocalGet(0)); // SimData*
            f.instruction(&I::I32Load(crate::CodegenWasmJitFunctions::mem_arg(slot, 2))); // handle
            f.instruction(&I::Call(didx));
        }
        f.instruction(&I::End);
        bodies.push(f);
        eq_base + 8
    };

    // --- Nonlinear-system callbacks: per system a `residual`/`load` function.
    // The module's `start` (built last, shared with the closure thunks) appends
    // them to the shared table, base in the `nls_base` global; every `ref.func`d
    // callback is also listed in the declared element segment below so the
    // references validate. Only when the model has nonlinear systems. ---
    let nls_wiring = if nls_types.is_some() {
        let mut callback_indices: Vec<u32> = Vec::new(); // for the declared segment
        // (residual, load, Option<jac>, Option<strict>) per system; the shared table
        // gets 4 slots per system (`4k`..`4k+3`), unused ones left null.
        let mut fn_indices: Vec<(u32, u32, Option<u32>, Option<u32>)> = Vec::new();
        for sys in &nls_systems {
            // The job the casual set's fourth callback solves.
            let strict = nls_strict_of
                .get(&sys.index)
                .and_then(|i| var_map.nls_jobs.get(i))
                .copied();
            let (res_fn, load_fn, jac_fn, strict_fn) = build_nls_fns(
                sys, &var_map, &eq_index, &by_name, &mut literals,
                nls_jac_infos.get(&sys.index), strict, &mut pool,
                nls_types.map(|(residual, _, _)| residual).unwrap_or_default(),
            )?;
            let res_idx = import_base + bodies.len() as u32;
            match res_fn {
                NlsResidualFn::Whole(f) => bodies.push(f),
                // A split residual keeps this index: its body is the thunk calling
                // the chunks, filled in once the chunk base is known.
                NlsResidualFn::Chunked(chunks) => {
                    let slot = bodies.len();
                    bodies.push(empty_eqfn());
                    splits.push(SplitFn { slot, chunks, n_params: 3, pre_calls: Vec::new() });
                }
            }
            let load_idx = import_base + bodies.len() as u32;
            bodies.push(load_fn);
            callback_indices.push(res_idx);
            callback_indices.push(load_idx);
            let jac_idx = jac_fn.map(|f| {
                let idx = import_base + bodies.len() as u32;
                bodies.push(f);
                callback_indices.push(idx);
                idx
            });
            let strict_idx = strict_fn.map(|f| {
                let idx = import_base + bodies.len() as u32;
                bodies.push(f);
                callback_indices.push(idx);
                idx
            });
            fn_indices.push((res_idx, load_idx, jac_idx, strict_idx));
        }
        Some((fn_indices, callback_indices))
    } else {
        None
    };

    // --- The optional equation functions, appended last so the indices above are
    // undisturbed. All always emitted + exported (an empty stub when the model
    // lacks the feature) so the standalone `wasm-merge` and the interactive shared
    // table always resolve every driver entry point; the shared driver only calls
    // one when its metadata count is nonzero, so a stub is never entered. ---
    let init_sample_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if samples.is_empty() {
            empty_eqfn()
        } else {
            build_init_sample_fn(&samples, &layout, &var_map, &by_name, &mut literals)?
        });
        idx
    };
    let zc_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if zero_crossings.is_empty() {
            empty_eqfn()
        } else {
            build_zero_crossings_fn(&zero_crossings, &var_map, &by_name, &mut literals)?
        });
        idx
    };
    let stateset_jac_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if state_sets.is_empty() {
            empty_eqfn()
        } else {
            build_stateset_jac_fn(&sim_code.stateSets, &var_map, &eq_index, &by_name, &mut literals)?
        });
        idx
    };
    // C's `functionJacA_constantEqns` / `functionJacA_column`.
    let jac_a_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.extend(jac_a_fns);
        idx
    };
    let jac_adj_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.extend(jac_adj_fns);
        idx
    };
    // The lambda-0 (simplified) initial system, for the homotopy continuation's
    // first step; a stub for models that do not use `homotopy()`.
    let init_lambda0_idx = {
        let idx = import_base + bodies.len() as u32;
        splits.push(build_split_fn("functionInitialEquations_lambda0", &eq_units(&lambda0_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
        idx
    };
    // Min/max variable-attribute (and equation) assertion checks: C's
    // `checkForAsserts`, evaluated at each accepted output point. Warning-level
    // asserts record a `LOG_ASSERT` via `rt_assert_warning` and continue.
    let has_asserts = !assert_eqs.is_empty();
    let check_asserts_idx = {
        let idx = import_base + bodies.len() as u32;
        splits.push(build_split_fn("functionCheckAsserts", &eq_units(&assert_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
        idx
    };
    // C's `function_ZeroCrossingsEquations`: what the crossings read, which is
    // neither `functionODE` nor all of `functionAlgebraics`.
    let zc_equations_idx = {
        let idx = import_base + bodies.len() as u32;
        splits.push(build_split_fn("functionZeroCrossingsEquations", &eq_units(&zc_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
        idx
    };
    // The name the FMI getters call `functionAlgebraics` by.
    let outputs_idx = {
        let idx = import_base + bodies.len() as u32;
        use we::Instruction as I;
        let mut f = we::Function::new([]);
        f.instruction(&I::LocalGet(0));
        f.instruction(&I::Call(eqfn.algebraics));
        f.instruction(&I::End);
        bodies.push(f);
        idx
    };
    bodies[simulate_slot] = build_simulate(&layout, &eqfn, has_asserts.then_some(check_asserts_idx))?;
    let update_relations_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if relations.iter().all(Option::is_none) {
            empty_eqfn()
        } else {
            build_update_relations_fn(&relations, &var_map, &by_name, &mut literals)?
        });
        idx
    };
    // `functionStoreDelayed` / `functionInitDelay` (C's `function_storeDelayed` +
    // `rt_delay_init`); empty stubs when the model has no `delay(...)`.
    let store_delayed_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if var_map.n_delays == 0 {
            empty_eqfn()
        } else {
            build_store_delayed_fn(sim_code, &var_map, &by_name, &mut literals)?
        });
        idx
    };
    let init_delay_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if var_map.n_delays == 0 {
            empty_eqfn()
        } else {
            build_init_delay_fn(var_map.n_delays)
        });
        idx
    };
    // `functionStoreSpatialDistribution` / `functionInitSpatialDistribution` (C's
    // `function_storeSpatialDistribution` + `function_initSpatialDistribution`);
    // empty stubs when the model has no `spatialDistribution(...)`.
    let store_spatial_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if var_map.n_spatial == 0 {
            empty_eqfn()
        } else {
            build_store_spatial_fn(sim_code, &var_map, &by_name, &mut literals)?
        });
        idx
    };
    let init_spatial_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if var_map.n_spatial == 0 {
            empty_eqfn()
        } else {
            build_init_spatial_fn(sim_code, &var_map, &by_name, &mut literals)?
        });
        idx
    };
    // C's `updateBoundParameters`: `parameterEquations` *without* the constant
    // bindings, so re-evaluating the dependent parameters does not undo a
    // perturbation IDAS made to a sensitivity parameter.
    let update_bound_params_idx = {
        let idx = import_base + bodies.len() as u32;
        splits.push(build_split_fn("functionUpdateBoundParameters", &eq_units(&param_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
        idx
    };
    // The optimizer's per-real-variable attributes (C reads them out of the
    // `_init.xml`): constants here, parameter-dependent ones through `attr_targets`.
    let opt_attrs = match layout.n_opt_attr {
        0 => optimization::AttrDefaults { reals: Vec::new(), ints: Vec::new() },
        _ => {
            let reals: Vec<&SimCodeVar::SimVar> = states
                .iter()
                .copied()
                .chain(lst(&vars.derivativeVars))
                .chain(real_alg_vars(vars))
                .collect();
            optimization::attr_defaults(&reals, &layout, &mut attr_targets)
        }
    };
    let update_bound_attrs_idx = {
        let idx = import_base + bodies.len() as u32;
        let defaults: Vec<(u32, f64)> = nominal_defaults
            .iter()
            .chain(max_defaults.iter())
            .chain(opt_attrs.reals.iter())
            .copied()
            .collect();
        bodies.push(build_update_bound_attrs_fn(
            sim_code, &layout, &defaults, &opt_attrs.ints, &attr_targets, &var_map, &by_name,
            &mut literals,
        )?);
        idx
    };
    // C's `setupDataStruc` half: the constant defaults, written before the solver is
    // allocated. The expression-bound ones stay in the update function.
    let attr_defaults_idx = {
        let idx = import_base + bodies.len() as u32;
        let defaults: Vec<(u32, f64)> =
            nominal_defaults.iter().chain(max_defaults.iter()).copied().collect();
        bodies.push(build_attr_defaults_fn(&defaults, &var_map, &by_name, &mut literals)?);
        idx
    };
    // Always exported (empty when the backend generated none) so the standalone
    // merge resolves regardless of the model.
    let linz_jac_idx = {
        let base = import_base + bodies.len() as u32;
        bodies.extend(linz_jac_fns);
        base
    };
    let opt_jac_idx = {
        let base = import_base + bodies.len() as u32;
        bodies.extend(opt_jac_fns);
        base
    };
    // `-reconcile`'s F/H, only for a model the extraction algorithm ran on.
    let recon_jac_idx = recon_jac_fns.map(|fns| {
        let base = import_base + bodies.len() as u32;
        bodies.extend(fns);
        base
    });
    // Synchronous features. Always emitted, as the C target emits them (empty
    // without clocked partitions): an FMU adapter cannot import them
    // conditionally without leaving a clock-free model's `env` import unresolved.
    let sync_idx = {
        let init = import_base + bodies.len() as u32;
        bodies.push(build_init_synchronous_fn(&clocks, &layout, &var_map, &by_name, &mut literals)?);
        bodies.push(build_update_synchronous_fn(&clocks, &layout, &var_map, &by_name, &mut literals)?);
        bodies.push(build_equations_synchronous_fn(
            &clocks, &layout, &var_map, &eq_index, &by_name, &mut literals,
        )?);
        (init, init + 1, init + 2)
    };
    // C's over-determined check; a stub when nothing was removed.
    let removed_init_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if count(&sim_code.removedInitialEquations) == 0 {
            empty_eqfn()
        } else {
            build_removed_init_eqs_fn(sim_code, &layout, &var_map, &eq_index, &by_name, &mut literals)?
        });
        idx
    };
    // `layout.dae_mode()`, not this function's presence, is what tells a driver
    // which form the model is in.
    let dae_residuals_idx = {
        let idx = import_base + bodies.len() as u32;
        splits.push(build_split_fn("evaluateDAEResiduals", &dae_units(&dae_eqs), 2, dae_fn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
        idx
    };
    // C's `symbolicInlineSystem`. Emitted (empty without `--symSolver`) either way,
    // so every module's entry points sit at the same indices.
    let sym_inline_idx = {
        let idx = import_base + bodies.len() as u32;
        splits.push(build_split_fn("symbolicInlineSystem", &eq_units(&inline_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
        idx
    };

    // C's `functionDAE`: `functionLocalKnownVars` + `allEquations` in the discrete
    // context, and the discrete pass wherever `functionAlgebraics` is not already the
    // full list: the sorted order interleaves the two subsets, so `functionODE` then
    // `functionAlgebraics` would read an algebraic variable one pass stale. Exported
    // from every model, as `MODEL_FNS` promises the runtimes that import it by name.
    let dae_entry_idx = {
        let idx = import_base + bodies.len() as u32;
        match dae_chunks {
            Some(chunks) => {
                let slot = bodies.len();
                bodies.push(empty_eqfn());
                splits.push(SplitFn { slot, chunks, n_params: 1, pre_calls: Vec::new() });
            }
            None => {
                let mut units = eq_units(&local_known_eqs);
                units.extend(eq_units(&all_eqs));
                splits.push(build_split_fn("functionDAE", &units, 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
            }
        }
        idx
    };

    // `parmodTask(sim_data, k)` `call_indirect`s task `k` out of the module's own table 1.
    let parmod_fns = match parmod_info.is_some() {
        false => None,
        true => {
            let lk_idx = import_base + bodies.len() as u32;
            splits.push(build_split_fn("functionLocalKnownVars", &eq_units(&local_known_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
            splits[ode_split].pre_calls.push(lk_idx);
            let task_idx = import_base + bodies.len() as u32;
            let mut f = we::Function::new([]);
            f.instruction(&we::Instruction::LocalGet(0));
            f.instruction(&we::Instruction::LocalGet(1));
            f.instruction(&we::Instruction::CallIndirect { type_index: eqfn_type as u32, table_index: 1 });
            f.instruction(&we::Instruction::End);
            bodies.push(f);
            Some((lk_idx, task_idx))
        }
    };

    // The chunks, after all fixed-index bodies; each entry point's placeholder
    // becomes a thunk calling the ones it needs.
    let chunk_base = import_base + bodies.len() as u32;
    let ChunkPool { fns: chunk_fns, meta: chunk_meta } = pool;
    bodies.extend(chunk_fns);
    for s in &splits {
        bodies[s.slot] = s.thunk(chunk_base);
    }
    let parmod_tasks: Option<Vec<u32>> = parmod_fns.map(|_| {
        splits[ode_split].chunks.iter().map(|c| chunk_base + *c as u32).collect()
    });

    // --- Function section (type index per body, in body order). ---
    crate::CodegenWasmJitFunctions::set_ext_error_catch(None);
    crate::CodegenWasmJitFunctions::set_assert_throw_tag(None);
    crate::CodegenWasmJitFunctions::set_native_externals([]);

    let mut functions = we::FunctionSection::new();
    for ti in &model_fn_type {
        functions.function(*ti);
    }
    // param / initial / ode / algebraics / initStartValues — all (i32) -> ().
    for _ in 0..5 {
        functions.function(eqfn_type);
    }
    functions.function(simulate_type);
    functions.function(meta_fn_type); // om_meta_ptr
    functions.function(meta_fn_type); // om_meta_len
    // Optional eq functions — always emitted (order must match the `bodies` pushes:
    // destructors, nls callbacks, initSample, zc, statesetJac,
    // lambda0, …, then the closure thunks and `start` below).
    functions.function(eqfn_type); // callExternalObjectDestructors
    if let Some((residual_type, load_type, strict_type)) = nls_types {
        for sys in &nls_systems {
            functions.function(residual_type);
            functions.function(load_type);
            // The analytic-Jacobian callback (3 params, like the residual) is emitted
            // and type-listed only for systems that have a usable symbolic Jacobian —
            // matching the conditional body push in `nls_wiring`.
            if nls_jac_infos.contains_key(&sys.index) {
                functions.function(residual_type);
            }
            if nls_strict_of.contains_key(&sys.index) {
                functions.function(strict_type);
            }
        }
    }
    functions.function(eqfn_type); // initSample: (i32) -> ()
    functions.function(sync_fn_type); // functionZeroCrossings: (i32 SimData, i32 gout) -> ()
    functions.function(eqfn_type); // functionStateSetJacobians: (i32) -> ()
    functions.function(eqfn_type); // functionJacA_constantEqns: (i32) -> ()
    functions.function(eqfn_type); // functionJacA_column: (i32) -> ()
    functions.function(eqfn_type); // functionJacADJ_constantEqns: (i32) -> ()
    functions.function(eqfn_type); // functionJacADJ_column: (i32) -> ()
    functions.function(eqfn_type); // functionInitialEquations_lambda0: (i32) -> ()
    functions.function(eqfn_type); // functionCheckAsserts: (i32) -> ()
    functions.function(eqfn_type); // functionZeroCrossingsEquations: (i32) -> ()
    functions.function(eqfn_type); // functionOutputs: (i32) -> ()
    functions.function(eqfn_type); // functionUpdateRelations: (i32) -> ()
    functions.function(eqfn_type); // functionStoreDelayed: (i32) -> ()
    functions.function(eqfn_type); // functionInitDelay: (i32) -> ()
    functions.function(eqfn_type); // functionStoreSpatialDistribution: (i32) -> ()
    functions.function(eqfn_type); // functionInitSpatialDistribution: (i32) -> ()
    functions.function(eqfn_type); // functionUpdateBoundParameters: (i32) -> ()
    functions.function(eqfn_type); // functionUpdateBoundVariableAttributes: (i32) -> ()
    functions.function(eqfn_type); // functionAttrDefaults: (i32) -> ()
    for _ in 0..4 {
        functions.function(eqfn_type); // linearJacA..linearJacD: (i32) -> ()
    }
    for _ in 0..OPT_JAC_FNS.len() {
        functions.function(eqfn_type); // optJac{B,C,D}{_const,}: (i32) -> ()
    }
    for _ in 0..(if recon.present { datarecon::JAC_FNS.len() } else { 0 }) {
        functions.function(eqfn_type); // reconJacF / reconJacH: (i32) -> ()
    }
    functions.function(eqfn_type); // functionInitSynchronous: (i32) -> ()
    functions.function(sync_fn_type); // functionUpdateSynchronous: (i32, i32) -> ()
    functions.function(sync_fn_type); // functionEquationsSynchronous: (i32, i32) -> ()
    functions.function(eqfn_type); // functionRemovedInitialEquations: (i32) -> ()
    functions.function(dae_fn_type); // evaluateDAEResiduals: (i32, i32) -> ()
    functions.function(eqfn_type); // symbolicInlineSystem: (i32) -> ()
    functions.function(eqfn_type); // functionDAE: (i32) -> ()
    if parmod_fns.is_some() {
        functions.function(eqfn_type); // functionLocalKnownVars: (i32) -> ()
        functions.function(dae_fn_type); // parmodTask: (i32 SimData, i32 task) -> ()
    }
    for (ty, _) in &chunk_meta {
        functions.function(*ty);
    }

    // --- Shared literals, closure thunks and the module `start`. Both come after
    // every other body — their indices are only known here. ---
    let lits = crate::CodegenWasmJitFunctions::shared_lits::take();
    let lit_init = lits
        .iter()
        .any(|s| s.is_some())
        .then(|| {
            crate::CodegenWasmJitFunctions::shared_lits::build_init_fn(
                &lits, lit_global, &by_name, &mut literals,
            )
        })
        .transpose()?;
    let closure_wiring = crate::CodegenWasmJitFunctions::closures::take();
    let mut thunk_indices: Vec<u32> = Vec::new();
    for (type_index, body) in closure_wiring.thunks {
        thunk_indices.push(import_base + bodies.len() as u32);
        functions.function(type_index);
        bodies.push(body);
    }
    for (params, results) in &closure_wiring.types {
        types.ty().function(params.iter().copied(), results.iter().copied());
    }
    let start_wiring = if nls_wiring.is_some() || !thunk_indices.is_empty() || lit_init.is_some() {
        let void_type = types.len();
        types.ty().function([], []);
        let lit_init_idx = lit_init.map(|f| {
            let idx = import_base + bodies.len() as u32;
            functions.function(void_type);
            bodies.push(f);
            idx
        });
        let start_idx = import_base + bodies.len() as u32;
        let mut f = we::Function::new([]);
        if let Some(i) = lit_init_idx {
            f.instruction(&we::Instruction::Call(i));
        }
        if let Some((fn_indices, _)) = &nls_wiring {
            let sizes: Vec<u32> = nls_systems.iter().map(|s| lst(&s.crefs).count() as u32).collect();
            emit_nls_start(&mut f, fn_indices, nls_hist_bytes, &sizes, &nls_nominals, &nls_bounds, &nls_patterns);
        }
        if !thunk_indices.is_empty() {
            crate::CodegenWasmJitFunctions::closures::emit_start(&mut f, &thunk_indices, closure_global);
        }
        f.instruction(&we::Instruction::End);
        functions.function(void_type);
        bodies.push(f);
        let mut declared: Vec<u32> =
            nls_wiring.as_ref().map(|(_, cbs)| cbs.clone()).unwrap_or_default();
        declared.extend_from_slice(&thunk_indices);
        Some((start_idx, declared))
    } else {
        None
    };
    // The throw a host-free `rt_ext_error` reaches for, rustc emitting none for a
    // wasm target. Always exported, whatever the model does: the runtime module is
    // prebuilt and its import cannot be conditional.
    let throw_fn = import_base + bodies.len() as u32;
    {
        let mut f = we::Function::new([]);
        f.instruction(&match error_tag_type {
            Some(_) => we::Instruction::Throw(0),
            None => we::Instruction::Unreachable,
        });
        f.instruction(&we::Instruction::End);
        functions.function(throw_fn_type);
        bodies.push(f);
    }
    if nls_wiring.is_some() || !thunk_indices.is_empty() || parmod_fns.is_some() {
        imports.import("rt", "__indirect_function_table", we::EntityType::Table(we::TableType {
            element_type: we::RefType::FUNCREF,
            table64: false,
            minimum: 1,
            maximum: None,
            shared: false,
        }));
    }

    // `<entry>$guard`: the entry point under a `try_table` for the model-error tag, so
    // the adapter answers a status rather than trapping — a trapped component is done.
    let guarded: Vec<(&str, u32)> = vec![
        ("functionParameters", eqfn.parameters),
        ("functionInitialEquations", eqfn.initial),
        ("functionInitStartValues", eqfn.init_start_values),
        ("functionODE", eqfn.ode),
        ("functionAlgebraics", eqfn.algebraics),
        ("functionOutputs", outputs_idx),
        ("callExternalObjectDestructors", destructors_idx),
        ("initSample", init_sample_idx),
        ("functionZeroCrossingsEquations", zc_equations_idx),
        ("functionStateSetJacobians", stateset_jac_idx),
        ("functionJacA_constantEqns", jac_a_idx),
        ("functionJacA_column", jac_a_idx + 1),
        ("functionInitialEquations_lambda0", init_lambda0_idx),
        ("functionCheckAsserts", check_asserts_idx),
        ("functionUpdateRelations", update_relations_idx),
        ("functionStoreDelayed", store_delayed_idx),
        ("functionInitDelay", init_delay_idx),
        ("functionStoreSpatialDistribution", store_spatial_idx),
        ("functionInitSpatialDistribution", init_spatial_idx),
        ("functionUpdateBoundParameters", update_bound_params_idx),
        ("functionUpdateBoundVariableAttributes", update_bound_attrs_idx),
        ("functionAttrDefaults", attr_defaults_idx),
        ("functionRemovedInitialEquations", removed_init_idx),
        ("functionInitSynchronous", sync_idx.0),
        ("symbolicInlineSystem", sym_inline_idx),
        ("functionDAE", dae_entry_idx),
        ("linearJacA", linz_jac_idx),
        ("linearJacB", linz_jac_idx + 1),
        ("linearJacC", linz_jac_idx + 2),
        ("linearJacD", linz_jac_idx + 3),
    ];
    let guard_base = import_base + bodies.len() as u32;
    if error_tag_type.is_some() {
        for (_, target) in &guarded {
            functions.function(guard_fn_type);
            bodies.push(build_guard_fn(*target));
        }
    }

    // --- Code section. ---
    let mut code = we::CodeSection::new();
    for body in &bodies {
        code.function(body);
    }

    // --- Exports: the equation functions (for the host-driven driver) and
    // `simulate` (for the in-wasm driver). ---
    let mut exports = we::ExportSection::new();
    if error_tag_type.is_some() {
        // Exported for the host to throw with; caught here whoever throws, so the
        // tag itself never crosses a module boundary.
        exports.export("model_error", we::ExportKind::Tag, 0);
    }
    exports.export("om_throw_model_error", we::ExportKind::Func, throw_fn);
    exports.export("functionParameters", we::ExportKind::Func, eqfn.parameters);
    exports.export("functionInitialEquations", we::ExportKind::Func, eqfn.initial);
    exports.export("functionInitStartValues", we::ExportKind::Func, eqfn.init_start_values);
    exports.export("functionODE", we::ExportKind::Func, eqfn.ode);
    exports.export("functionAlgebraics", we::ExportKind::Func, eqfn.algebraics);
    exports.export("functionOutputs", we::ExportKind::Func, outputs_idx);
    if let Some((lk_idx, task_idx)) = parmod_fns {
        exports.export("functionLocalKnownVars", we::ExportKind::Func, lk_idx);
        exports.export("parmodTask", we::ExportKind::Func, task_idx);
    }
    exports.export("simulate", we::ExportKind::Func, simulate_idx);
    exports.export("om_meta_ptr", we::ExportKind::Func, om_meta_ptr_idx);
    exports.export("om_meta_len", we::ExportKind::Func, om_meta_len_idx);
    exports.export("callExternalObjectDestructors", we::ExportKind::Func, destructors_idx);
    exports.export("initSample", we::ExportKind::Func, init_sample_idx);
    exports.export("functionZeroCrossings", we::ExportKind::Func, zc_idx);
    exports.export("functionZeroCrossingsEquations", we::ExportKind::Func, zc_equations_idx);
    exports.export("functionStateSetJacobians", we::ExportKind::Func, stateset_jac_idx);
    exports.export("functionJacA_constantEqns", we::ExportKind::Func, jac_a_idx);
    exports.export("functionJacA_column", we::ExportKind::Func, jac_a_idx + 1);
    exports.export("functionJacADJ_constantEqns", we::ExportKind::Func, jac_adj_idx);
    exports.export("functionJacADJ_column", we::ExportKind::Func, jac_adj_idx + 1);
    exports.export("functionInitialEquations_lambda0", we::ExportKind::Func, init_lambda0_idx);
    exports.export("functionCheckAsserts", we::ExportKind::Func, check_asserts_idx);
    exports.export("functionUpdateRelations", we::ExportKind::Func, update_relations_idx);
    exports.export("functionStoreDelayed", we::ExportKind::Func, store_delayed_idx);
    exports.export("functionInitDelay", we::ExportKind::Func, init_delay_idx);
    exports.export("functionStoreSpatialDistribution", we::ExportKind::Func, store_spatial_idx);
    exports.export("functionInitSpatialDistribution", we::ExportKind::Func, init_spatial_idx);
    exports.export("functionUpdateBoundParameters", we::ExportKind::Func, update_bound_params_idx);
    exports.export("functionUpdateBoundVariableAttributes", we::ExportKind::Func, update_bound_attrs_idx);
    exports.export("functionAttrDefaults", we::ExportKind::Func, attr_defaults_idx);
    for (k, name) in ["linearJacA", "linearJacB", "linearJacC", "linearJacD"].iter().enumerate() {
        exports.export(name, we::ExportKind::Func, linz_jac_idx + k as u32);
    }
    for (k, name) in OPT_JAC_FNS.iter().enumerate() {
        exports.export(*name, we::ExportKind::Func, opt_jac_idx + k as u32);
    }
    if let Some(base) = recon_jac_idx {
        for (k, name) in datarecon::JAC_FNS.iter().enumerate() {
            exports.export(name, we::ExportKind::Func, base + k as u32);
        }
    }
    exports.export("functionDAE", we::ExportKind::Func, dae_entry_idx);
    let (sync_init, sync_update, sync_eqs) = sync_idx;
    exports.export("functionRemovedInitialEquations", we::ExportKind::Func, removed_init_idx);
    exports.export("functionInitSynchronous", we::ExportKind::Func, sync_init);
    exports.export("functionUpdateSynchronous", we::ExportKind::Func, sync_update);
    exports.export("functionEquationsSynchronous", we::ExportKind::Func, sync_eqs);
    exports.export("evaluateDAEResiduals", we::ExportKind::Func, dae_residuals_idx);
    exports.export("symbolicInlineSystem", we::ExportKind::Func, sym_inline_idx);
    if error_tag_type.is_some() {
        for (k, (name, _)) in guarded.iter().enumerate() {
            exports.export(&format!("{name}$guard"), we::ExportKind::Func, guard_base + k as u32);
        }
    }

    // --- Name section: without it a trap backtrace is bare function indices. The
    // unnamed remainder is the NLS callbacks, the closure thunks and `start`. ---
    let mut names: Vec<(u32, String)> = Vec::new();
    for (i, name) in BUILTINS
        .iter()
        .map(|b| b.0)
        .chain(RT_BUILTINS.iter().map(|b| b.0))
        .chain(ENV_EXTRA.iter().map(|b| b.0))
        .enumerate()
    {
        names.push((i as u32, name.to_string()));
    }
    for (i, sig) in ext_imports.iter().enumerate() {
        names.push((ext_base + i as u32, format!("ext.{}", sig.name)));
    }
    for (id, f) in model_fns.iter().enumerate() {
        names.push((import_base + id as u32, function_signature(f)?.0));
    }
    for (name, idx) in [
        ("functionParameters", eqfn.parameters),
        ("functionInitialEquations", eqfn.initial),
        ("functionInitStartValues", eqfn.init_start_values),
        ("functionODE", eqfn.ode),
        ("functionAlgebraics", eqfn.algebraics),
        ("functionOutputs", outputs_idx),
        ("simulate", simulate_idx),
        ("om_meta_ptr", om_meta_ptr_idx),
        ("om_meta_len", om_meta_len_idx),
        ("callExternalObjectDestructors", destructors_idx),
        ("initSample", init_sample_idx),
        ("functionZeroCrossings", zc_idx),
        ("functionZeroCrossingsEquations", zc_equations_idx),
        ("functionStateSetJacobians", stateset_jac_idx),
        ("functionJacA_constantEqns", jac_a_idx),
        ("functionJacA_column", jac_a_idx + 1),
        ("functionJacADJ_constantEqns", jac_adj_idx),
        ("functionJacADJ_column", jac_adj_idx + 1),
        ("functionInitialEquations_lambda0", init_lambda0_idx),
        ("functionCheckAsserts", check_asserts_idx),
        ("functionUpdateRelations", update_relations_idx),
        ("functionStoreDelayed", store_delayed_idx),
        ("functionInitDelay", init_delay_idx),
        ("functionStoreSpatialDistribution", store_spatial_idx),
        ("functionInitSpatialDistribution", init_spatial_idx),
        ("functionUpdateBoundParameters", update_bound_params_idx),
        ("functionUpdateBoundVariableAttributes", update_bound_attrs_idx),
        ("functionAttrDefaults", attr_defaults_idx),
        ("linearJacA", linz_jac_idx),
        ("linearJacB", linz_jac_idx + 1),
        ("linearJacC", linz_jac_idx + 2),
        ("linearJacD", linz_jac_idx + 3),
        (OPT_JAC_FNS[0], opt_jac_idx),
        (OPT_JAC_FNS[1], opt_jac_idx + 1),
        (OPT_JAC_FNS[2], opt_jac_idx + 2),
        (OPT_JAC_FNS[3], opt_jac_idx + 3),
        (OPT_JAC_FNS[4], opt_jac_idx + 4),
        (OPT_JAC_FNS[5], opt_jac_idx + 5),
    ] {
        names.push((idx, name.to_string()));
    }
    names.push((removed_init_idx, "functionRemovedInitialEquations".to_string()));
    if let Some(base) = recon_jac_idx {
        for (k, name) in datarecon::JAC_FNS.iter().enumerate() {
            names.push((base + k as u32, name.to_string()));
        }
    }
    names.push((dae_entry_idx, "functionDAE".to_string()));
    names.push((sync_init, "functionInitSynchronous".to_string()));
    names.push((sync_update, "functionUpdateSynchronous".to_string()));
    names.push((sync_eqs, "functionEquationsSynchronous".to_string()));
    names.push((dae_residuals_idx, "evaluateDAEResiduals".to_string()));
    names.push((sym_inline_idx, "symbolicInlineSystem".to_string()));
    if let Some((lk_idx, task_idx)) = parmod_fns {
        names.push((lk_idx, "functionLocalKnownVars".to_string()));
        names.push((task_idx, "parmodTask".to_string()));
    }
    for (k, (_, name)) in chunk_meta.iter().enumerate() {
        names.push((chunk_base + k as u32, name.clone()));
    }
    names.sort_by_key(|(idx, _)| *idx);
    let mut fn_names = we::NameMap::new();
    for (idx, name) in &names {
        fn_names.append(*idx, name);
    }
    let mut name_section = we::NameSection::new();
    name_section.functions(&fn_names);

    let mut module = we::Module::new();
    module.section(&types);
    module.section(&imports);
    module.section(&functions);
    if let Some(tasks) = &parmod_tasks {
        let mut tables = we::TableSection::new();
        tables.table(we::TableType {
            element_type: we::RefType::FUNCREF,
            table64: false,
            minimum: tasks.len() as u64,
            maximum: Some(tasks.len() as u64),
            shared: false,
        });
        module.section(&tables);
    }
    if let Some(ti) = error_tag_type {
        let mut tags = we::TagSection::new();
        tags.tag(we::TagType { kind: we::TagKind::Exception, func_type_idx: ti });
        module.section(&tags);
    }
    // Global + Start + Element sections (in the canonical order) carry the
    // shared-table wiring (NLS callbacks and/or closure thunks) and the
    // shared-literal objects.
    // Flag slots need the globals even with no `start` to fill them.
    if start_wiring.is_some() || !lits.is_empty() {
        let mut globals = we::GlobalSection::new();
        // NLS_BASE_GLOBAL (shared-table base), NLS_HIST_GLOBAL (history block base),
        // NLS_NOMINAL_GLOBAL (nominal block base), NLS_PAT_GLOBAL (sparse-pattern
        // block base) and NLS_BOUNDS_GLOBAL (min/max block base) when the model has
        // nonlinear systems, then the closure-thunk table base and one per shared
        // literal; all set by `start`.
        for _ in 0..lit_global as usize + lits.len() {
            globals.global(
                we::GlobalType { val_type: we::ValType::I32, mutable: true, shared: false },
                &we::ConstExpr::i32_const(0),
            );
        }
        module.section(&globals);
    }
    module.section(&exports);
    let mut elements = we::ElementSection::new();
    let mut have_elements = false;
    if let Some((start_idx, declared)) = &start_wiring {
        module.section(&we::StartSection { function_index: *start_idx });
        if !declared.is_empty() {
            elements.declared(we::Elements::Functions(declared.as_slice().into()));
            have_elements = true;
        }
    }
    if let Some(tasks) = &parmod_tasks {
        elements.active(Some(1), &we::ConstExpr::i32_const(0), we::Elements::Functions(tasks.as_slice().into()));
        have_elements = true;
    }
    if have_elements {
        module.section(&elements);
    }
    if !literals.is_empty() {
        module.section(&we::DataCountSection { count: 1 });
    }
    module.section(&code);
    if !literals.is_empty() {
        let mut data = we::DataSection::new();
        data.passive(literals.blob().iter().copied());
        module.section(&data);
    }
    module.section(&name_section);
    let wasm = module.finish();
    // `OMC_WASM_DUMP_DIR=<dir>`: the lowered module as `<dir>/<prefix>.wasm`, for
    // `wasm-objdump` on a trap the backtrace names only by function index.
    #[cfg(not(target_arch = "wasm32"))]
    if let Ok(dir) = std::env::var("OMC_WASM_DUMP_DIR") {
        let _ = std::fs::write(format!("{dir}/{}.wasm", sim_code.fileNamePrefix), &wasm);
    }

    // Kick off the (cranelift) JIT compile of this model module on a background
    // thread now, while the rest of the OMC pipeline (remaining templates,
    // buildModel, the scripting round-trip) runs, so it is off `runSimulation`'s
    // critical path. The thread also warms the process-wide runtime module
    // (compiled once). `runSimulation` joins this via `take_compiled_model`.
    // The runtime module is already compiling (started at `translateModel`
    // entry); compile the model module concurrently here so the two overlap.
    let compile_wasm = wasm.clone();
    // Native: compile on a background thread to overlap the rest of the pipeline.
    // wasm: no threads — compile eagerly and store the result for take_compiled_model.
    // `-n=1`: no job, so `take_compiled_model` compiles inline where it is timed.
    #[cfg(not(target_arch = "wasm32"))]
    let compiled = Mutex::new(match openmodelica_wasm_jit::model::single_threaded() {
        true => None,
        false => Some(std::thread::spawn(move || {
            sim_runtime::compile_model_module(&compile_wasm)
        })),
    });
    #[cfg(target_arch = "wasm32")]
    let compiled = Mutex::new(Some(sim_runtime::compile_model_module(&compile_wasm)));

    Ok(SimModel {
        wasm,
        compiled,
        prepared: Mutex::new(None),
        layout,
        result_vars,
        ext_libs: ext_libs.wasm,
        ext_native,
        ext_builtin,
        ext_native_libs: ext_libs.native,
        ext_native_fallback: ext_libs.fallback,
        ext_native_system: ext_libs.native_system,
        ext_outside_process: Default::default(),
        ext_archives,
        ext_includes,
        ext_lib_notes,
        ext_imports,
        model_name,
        start_time: settings.startTime.into_inner(),
        stop_time: settings.stopTime.into_inner(),
        n_intervals: settings.numberOfIntervals.max(0) as u32,
        output_format: settings.outputFormat.to_string(),
        method: settings.method.to_string(),
        tolerance: settings.tolerance.into_inner(),
        state_sets,
        jac_a,
        sparse_nls: var_map.nls_jobs.values().any(|j| j.sparse_default),
        editable_params,
        var_units,
        meta,
    })
}

/// Wrap a `\n`-separated message in the `LOG_STDOUT`/continuation prefixes.
pub(super) fn format_log_stdout(msg: &str) -> String {
    openmodelica_modelica_utilities::format_log_stdout(msg, openmodelica_modelica_utilities::LOG_STDOUT_INFO)
}

/// C's `homotopySupport` loop over `nonlinearSystemData`: whether a nonlinear
/// system carries the operator, not whether the model uses `homotopy()` at all.
fn nls_homotopy_support(sim_code: &SimCode::SimCode) -> bool {
    let has = |eqs: Vec<Arc<SimCode::SimEqSystem>>| {
        eqs.iter().any(|e| match &**e {
            SimCode::SimEqSystem::SES_NONLINEAR { nlSystem, .. } => nlSystem.homotopySupport,
            _ => false,
        })
    };
    has(flatten_eqs(&sim_code.parameterEquations))
        || has(flatten_eqs(&sim_code.initialEquations))
        || has(flatten_eqs_ll(&sim_code.odeEquations))
        || has(flatten_eqs_ll(&sim_code.algebraicEquations))
}

/// C's `homotopyMethod` model-callback entry, from the same `Config` predicates.
pub(super) fn homotopy_method() -> Result<openmodelica_sim_meta::HomotopyMethod> {
    use openmodelica_sim_meta::HomotopyMethod as H;
    use openmodelica_util::Config;
    Ok(if Config::replacedHomotopy()? {
        H::None
    } else if Config::adaptiveHomotopy()? {
        if Config::globalHomotopy()? { H::GlobalAdaptive } else { H::LocalAdaptive }
    } else if Config::globalHomotopy()? {
        H::GlobalEquidistant
    } else {
        H::LocalEquidistant
    })
}

/// C's `compiledWithSymSolver`: which `--symSolver` variant generated the model's
/// inline update equations, 0 for none.
fn sym_solver_kind() -> Result<u8> {
    Ok(openmodelica_util::Flags::getConfigEnum(openmodelica_util::Flags::SYM_SOLVER.clone())?
        .clamp(0, 2) as u8)
}

/// C's `LOG_STDOUT` "… changed to …" lines, ahead of everything the run prints.
pub(super) fn flag_change_log(flags: &simflags::SimFlags) -> String {
    use openmodelica_modelica_utilities::{LOG_STDOUT_INFO, LOG_STDOUT_WARNING};
    let mut out = String::new();
    for (ty, msg) in simflags::notices(flags) {
        let prefix = if ty == openmodelica_sim_meta::omclog::WARNING {
            LOG_STDOUT_WARNING
        } else {
            LOG_STDOUT_INFO
        };
        out.push_str(&openmodelica_modelica_utilities::format_log_stdout(&msg, prefix));
    }
    out
}

/// The nonzero count of a linear system's matrix `A`, matching C's
/// `initializeLinearSystems`: `listLength(simJac)` for the non-torn (method-0)
/// form, else the symbolic Jacobian's sparsity nnz (method 1, torn systems).
pub(super) fn lin_system_nnz(lsystem: &SimCode::LinearSystem) -> usize {
    let sj = count(&lsystem.simJac) as usize;
    if sj > 0 {
        return sj;
    }
    lsystem
        .jacobianMatrix
        .as_ref()
        .map(|jm| lst(&jm.sparsity).map(|(_, rows)| lst(rows).count()).sum())
        .unwrap_or(0)
}

/// The lowering context every generated `SimData*` function shares: local 0 is the
/// `SimData` pointer, and every slot comes from the one variable map.
pub(crate) fn sim_ctx(var_map: &SimVarMap) -> SimCtx {
    SimCtx {
        data_local: 0,
        vars: var_map.vars.clone(),
        starts: var_map.starts.clone(),
        start_slots: var_map.start_slots.clone(),
        array_groups: var_map.array_groups.clone(),
        scatter_groups: var_map.scatter_groups.clone(),
        consts: var_map.consts.clone(),
        const_groups: var_map.const_groups.clone(),
        extobj_dtors: var_map.extobj_dtors.clone(),
        terminate_off: var_map.terminate_off,
        terminal_off: var_map.terminal_off,
        initial_off: var_map.initial_off,
        term_info_off: var_map.term_info_off,
        nls_fail_off: var_map.nls_fail_off,
        nls_jobs: var_map.nls_jobs.clone(),
        generic_calls: var_map.generic_calls.clone(),
        n_samples: var_map.n_samples,
        sample_active_off: var_map.sample_active_off,
        relations_off: var_map.relations_off,
        rel_fresh_off: var_map.rel_fresh_off,
        stored_rel_off: var_map.stored_rel_off,
        relations_pre_off: var_map.relations_pre_off,
        n_relations: var_map.n_relations,
        mathevents_off: var_map.mathevents_off,
        n_mathevents: var_map.n_mathevents,
        lambda_off: var_map.lambda_off,
        homotopy_method: var_map.homotopy_method,
        old_real: var_map.old_real,
        zctol_off: var_map.zctol_off,
        zc_pre_off: var_map.zc_pre_off,
        zc_context: false,
        clock_fire_off: var_map.clock_fire_off,
        sub_clock_off: None,
        prof: var_map.prof.clone(),
    }
}
