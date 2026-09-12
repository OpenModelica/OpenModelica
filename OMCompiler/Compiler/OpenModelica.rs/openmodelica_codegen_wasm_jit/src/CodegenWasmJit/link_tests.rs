//! Tests of the two link paths: the standalone merge and the FMU component.

use super::*;
use wasm_encoder as we;

/// A minimal stand-in for a lowered model module: it exports the four model
/// functions and the two metadata accessors the standalone runtime imports
/// (module `model`), and imports `rt.memory` + `rt.rt_alloc` like a real model,
/// so the merge must resolve both directions of the contract.
fn build_stub_model() -> Vec<u8> {
    use we::Instruction as I;
    let mut m = we::Module::new();

    let mut types = we::TypeSection::new();
    types.ty().function([we::ValType::I32], [we::ValType::I32]); // 0: (i32)->i32  (rt_alloc)
    types.ty().function([we::ValType::I32], []); // 1: (i32)->()   (model fns)
    types.ty().function([], [we::ValType::I32]); // 2: ()->i32      (om_meta_*)
    // 3: (i32,f64,f64,i32)->i32  (simulate)
    types.ty().function(
        [we::ValType::I32, we::ValType::F64, we::ValType::F64, we::ValType::I32],
        [we::ValType::I32],
    );
    // 4: (i32,i32)->()  (functionUpdateSynchronous / functionEquationsSynchronous)
    types.ty().function([we::ValType::I32, we::ValType::I32], []);
    types.ty().function([], []); // 5: ()->()      (om_throw_model_error)
    m.section(&types);

    let mut imports = we::ImportSection::new();
    imports.import(
        "rt",
        "memory",
        we::MemoryType { minimum: 0, maximum: None, memory64: false, shared: false, page_size_log2: None },
    );
    imports.import("rt", "rt_alloc", we::EntityType::Function(0));
    m.section(&imports);
    // Imported func index: rt_alloc = 0.

    // The standalone runtime imports every driver entry point from `model`; the
    // emitter always exports them, so the stub must too or the merge leaves
    // unresolved `model.*` imports. Taken from the canonical list rather than
    // copied, so adding an entry point cannot leave this stub behind.
    // `simulate` aside, the entry points that are not `fn(SimData*)`.
    let two_arg = [
        openmodelica_sim_meta::driver::MODEL_FN_UPDATE_SYNC,
        openmodelica_sim_meta::driver::MODEL_FN_EQS_SYNC,
        openmodelica_sim_meta::driver::MODEL_FN_ZC,
        openmodelica_sim_meta::driver::MODEL_FN_DAE,
    ];
    let one_arg: Vec<&str> = openmodelica_sim_meta::driver::MODEL_FNS
        .iter()
        .copied()
        .filter(|n| *n != "simulate" && !two_arg.contains(n))
        .collect();

    let mut funcs = we::FunctionSection::new();
    for _ in &one_arg {
        funcs.function(1);
    }
    funcs.function(2); // om_meta_ptr
    funcs.function(2); // om_meta_len
    funcs.function(3); // simulate
    for _ in &two_arg {
        funcs.function(4);
    }
    funcs.function(5); // om_throw_model_error
    for _ in &one_arg {
        funcs.function(0); // <entry>$guard: (i32)->i32, like rt_alloc's type
    }
    m.section(&funcs);

    // Defined-func indices start at 1 (rt_alloc is import 0).
    let mut exports = we::ExportSection::new();
    for (i, name) in one_arg.iter().enumerate() {
        exports.export(name, we::ExportKind::Func, 1 + i as u32);
    }
    let meta_ptr_idx = 1 + one_arg.len() as u32;
    exports.export("om_meta_ptr", we::ExportKind::Func, meta_ptr_idx);
    exports.export("om_meta_len", we::ExportKind::Func, meta_ptr_idx + 1);
    exports.export("simulate", we::ExportKind::Func, meta_ptr_idx + 2);
    for (i, name) in two_arg.iter().enumerate() {
        exports.export(name, we::ExportKind::Func, meta_ptr_idx + 3 + i as u32);
    }
    exports.export(
        "om_throw_model_error",
        we::ExportKind::Func,
        meta_ptr_idx + 3 + two_arg.len() as u32,
    );
    // The adapter reaches the one-argument entry points only through their guards.
    let guard_base = meta_ptr_idx + 4 + two_arg.len() as u32;
    for (i, name) in one_arg.iter().enumerate() {
        exports.export(&format!("{name}$guard"), we::ExportKind::Func, guard_base + i as u32);
    }
    m.section(&exports);

    let mut code = we::CodeSection::new();
    for _ in &one_arg {
        let mut f = we::Function::new([]);
        f.instruction(&I::End);
        code.function(&f);
    }
    // om_meta_ptr(): rt_alloc(8) — exercises the model->rt import resolution.
    let mut ptr = we::Function::new([]);
    ptr.instruction(&I::I32Const(8));
    ptr.instruction(&I::Call(0));
    ptr.instruction(&I::End);
    code.function(&ptr);
    // om_meta_len(): 0.
    let mut len = we::Function::new([]);
    len.instruction(&I::I32Const(0));
    len.instruction(&I::End);
    code.function(&len);
    // simulate(...): return 0.
    let mut sim = we::Function::new([]);
    sim.instruction(&I::I32Const(0));
    sim.instruction(&I::End);
    code.function(&sim);
    // The two-argument entry points: noop.
    for _ in &two_arg {
        let mut f = we::Function::new([]);
        f.instruction(&I::End);
        code.function(&f);
    }
    // om_throw_model_error(): the emitter's no-external-"C" body.
    let mut throw = we::Function::new([]);
    throw.instruction(&I::Unreachable);
    throw.instruction(&I::End);
    code.function(&throw);
    // Each guard: nothing threw.
    for _ in &one_arg {
        let mut f = we::Function::new([]);
        f.instruction(&I::I32Const(0));
        f.instruction(&I::End);
        code.function(&f);
    }
    m.section(&code);

    m.finish()
}

/// Every adapter `env` import must be satisfied by the model or by the runtime
/// linked into the adapter itself; an `env` host callback (`rt_host_log`) is an
/// unresolved symbol here.
#[test]
fn fmu_component_links_without_a_host() {
    // Both ends of the selection have to resolve, for both adapters: each imports
    // every solver whatever its flags named.
    let all: Vec<&str> = SOLVER_LIBRARIES.iter().map(|l| l.name).collect();
    let mut cases: Vec<(&str, &[u8], Option<&[&str]>)> = Vec::new();
    if sundials_available() {
        for (label, adapter) in [("ME", FMI3_ME_ADAPTER()), ("me_cs", FMI3_MECS_ADAPTER())] {
            cases.push((label, adapter, Some(&all)));
            cases.push((label, adapter, Some(&[])));
        }
    } else {
        cases.push(("ME", FMI3_ME_ADAPTER(), None));
    }
    for (label, adapter, solvers) in cases {
        if adapter.is_empty() {
            continue; // omc built without the wasm32 toolchain
        }
        assert!(
            link_fmu_component(&build_stub_model(), adapter, solvers, &[], None).is_ok(),
            "{label} does not link into a component: {}",
            openmodelica_util::Error::printMessagesStr(false)
        );
    }
}

/// The mapping has to name `klu`, the shared core, whenever anything else is named.
/// Only the integrator is Co-Simulation's alone: a Model Exchange FMU runs the same
/// nonlinear and linear solvers during initialisation. A model with a sparse
/// nonlinear system needs kinsol+KLU with no flag saying so.
#[test]
fn solver_libraries_follow_the_fmi_flags() {
    for (json, cs, sparse_nls, want) in [
        ("{}", true, false, vec![]),
        (r#"{"s":"euler"}"#, true, false, vec![]),
        (r#"{"s":"cvode"}"#, true, false, vec!["sundials_driver", "klu"]),
        (r#"{"s":"ida"}"#, true, false, vec!["sundials_driver", "klu"]),
        (r#"{"nls":"kinsol"}"#, true, false, vec!["kinsol", "klu"]),
        (r#"{"lss":"lis"}"#, true, false, vec!["lis", "klu"]),
        (r#"{"ls":"umfpack"}"#, true, false, vec!["umfpack", "klu"]),
        (r#"{"nlsLS":"klu"}"#, true, false, vec!["klu"]),
        (r#"{"ls":"lapack"}"#, true, false, vec![]),
        // ME: the same solvers, never the integrator.
        (r#"{"nls":"kinsol"}"#, false, false, vec!["kinsol", "klu"]),
        (r#"{"lss":"lis"}"#, false, false, vec!["lis", "klu"]),
        (r#"{"s":"cvode"}"#, false, false, vec![]),
        // The density rule's own choice, which no flag records.
        ("{}", false, true, vec!["kinsol", "klu"]),
        ("{}", true, true, vec!["kinsol", "klu"]),
        (r#"{"nls":"kinsol"}"#, true, true, vec!["kinsol", "klu"]),
        (r#"{"s":"ida"}"#, true, true, vec!["sundials_driver", "kinsol", "klu"]),
    ] {
        let method = cs_method_from(json, if cs { "CS" } else { "ME" }, false, "dassl");
        assert_eq!(
            fmu_solver_libraries(json, &method, cs, sparse_nls), want,
            "{json} cs={cs} sparse_nls={sparse_nls}"
        );
    }
    // Every name the mapping can produce must be a library that exists.
    let known: Vec<&str> = SOLVER_LIBRARIES.iter().map(|l| l.name).collect();
    let all = r#"{"s":"ida","nls":"kinsol","ls":"lis","lss":"umfpack"}"#;
    for name in fmu_solver_libraries(all, "ida", true, true) {
        assert!(known.contains(&name), "{name} is not a solver library");
    }
}

/// What the FMU applies when it instantiates, since an importer cannot pass flags.
/// `-s` is not among them: it is the integrator, carried by `SimMeta::cs_method`.
#[test]
fn baked_solver_flags_come_from_the_fmi_flags() {
    assert_eq!(fmu_solver_flags("{}"), "");
    assert_eq!(fmu_solver_flags(r#"{"s":"cvode"}"#), "");
    assert_eq!(fmu_solver_flags(r#"{"nls":"kinsol"}"#), "-nls=kinsol");
    assert_eq!(
        fmu_solver_flags(r#"{"s":"ida","nls":"kinsol","lss":"klu"}"#),
        "-nls=kinsol -lss=klu"
    );
    // Whatever is baked has to parse, and be servable by the libraries the same
    // flags select.
    for json in [r#"{"nls":"kinsol"}"#, r#"{"ls":"lis"}"#, r#"{"lss":"umfpack"}"#,
                 r#"{"nlsLS":"klu"}"#] {
        let baked = fmu_solver_flags(json);
        let argv: Vec<String> = core::iter::once("model".to_string())
            .chain(baked.split_whitespace().map(str::to_string))
            .collect();
        let f = simflags::parse(&argv).expect(&baked);
        let libs =
            fmu_solver_libraries(json, &cs_method_from(json, "CS", false, "dassl"), true, false);
        let cap = simflags::Capabilities {
            klu: libs.contains(&"klu"),
            kinsol: libs.contains(&"kinsol"),
            umfpack: libs.contains(&"umfpack"),
            lis: libs.contains(&"lis"),
            ida: false,
            cvode: false,
            alarm: true,
            variable_filter: false,
            optimization: false,
            qss: true,
        };
        assert!(simflags::check(&f, cap).is_ok(), "{json}: {baked}");
    }
}

// The standalone-export merge validates the result with `wasmtime::Module`, so
// it runs only under the default (wasmtime) engine.
#[cfg(all(feature = "jit", not(feature = "engine-wasmer")))]
#[test]
fn merge_leaves_only_wasi_imports() {
    let merged = merge_standalone(&build_stub_model()).expect("wasm-merge should succeed");
    let engine = wasmtime::Engine::default();
    let module = wasmtime::Module::new(&engine, &merged).expect("merged module should validate");
    // After the merge the only remaining imports are the WASI surface the shim
    // (or `wasmtime run`) provides; every `rt.*`/`model.*` import is internalized.
    for imp in module.imports() {
        assert_eq!(
            imp.module(),
            "wasi_snapshot_preview1",
            "unexpected unresolved import {}::{}",
            imp.module(),
            imp.name()
        );
    }
    // And the command entry point survives the merge.
    assert!(module.get_export("_start").is_some(), "merged module must export `_start`");
}
