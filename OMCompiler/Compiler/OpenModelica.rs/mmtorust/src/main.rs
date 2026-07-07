use openmodelica_ast::parser::parse;
use openmodelica_ast::parser::Grammar;
use openmodelica_ast::Absyn;
use metamodelica::nil;

mod MM;
mod hierarchy;
mod typedexp;
mod codegen;
mod external_c_calls;
mod fallibility;
mod fix;
mod visibility;
mod validate;
mod dep_analysis;
mod unused_functions;
mod const_patterns;
mod mutable_cycles;
mod scripting_api_qt;
use rayon::prelude::*;

fn start_compilation(results: Vec<Absyn::Program>, fix: bool) {
    let mut failures = 0;
    let t0 = std::time::Instant::now();
    let mut all_classes: Vec<MM::Class> = Vec::new();
    for program in &results {
        match MM::from_program(program) {
            Ok(mm_program) => {
                all_classes.extend(mm_program);
            }
            Err(e) => {
                eprintln!("MM ERR: {e}");
                failures += 1;
            }
        }
    }
    println!("MM conversion: {} files, {} failures {:.2}s", results.len(), failures, t0.elapsed().as_secs_f64());
    let t0 = std::time::Instant::now();
    let mut hier = hierarchy::InstanceHierarchy::from_program(&all_classes);
    hierarchy::flatten_extends(&mut hier);
    let mut warnings = std::collections::BTreeSet::new();
    while hierarchy::resolve_pass(&mut hier, &mut warnings) {}
    println!("Hierarchy extends+resolve types: {:.2}s", t0.elapsed().as_secs_f64());
    for w in &warnings {
        eprintln!("{w}");
    }

    // Reject `match`/`matchcontinue` cases whose body is an `equation` section:
    // the MetaModelica sources are migrating every case to `algorithm`, so an
    // `equation` case is a migration miss and must be fixed at the source, not
    // silently translated.
    let equation_cases = validate::match_cases_with_equation_sections(&hier);
    if !equation_cases.is_empty() {
        eprintln!(
            "error: {} match/matchcontinue case(s) use an `equation` section; rewrite them as `algorithm`:",
            equation_cases.len(),
        );
        for c in &equation_cases {
            eprintln!("  {c}");
        }
        std::process::exit(1);
    }
    let t0 = std::time::Instant::now();
    hierarchy::detect_recursive_types(&mut hier);
    hierarchy::detect_types_containing_mutable(&mut hier);
    hierarchy::detect_types_containing_array(&mut hier);
    hierarchy::detect_types_containing_dyn_fn(&mut hier);
    println!("Hierarchy recursive+mutable detection: {:.2}s", t0.elapsed().as_secs_f64());
    // println!("{hier}");

    // Fallibility analysis: classify every user-defined function as fallible
    // (lowers to `-> Result<T>`) or infallible (lowers to `-> T`). The result
    // is consumed by codegen to decide whether each call site needs `?` and
    // whether function-pointer references need a `fnptr!`-style wrapper.
    let t0 = std::time::Instant::now();
    let info = fallibility::analyze(&hier);
    hier.fallible_functions = info.fallible_functions.clone();
    let infallible_count = info.total_functions.saturating_sub(info.fallible_functions.len());
    println!(
        "Fallibility analysis: {} functions ({} fallible, {} infallible), {} externals; {} ext registry entries; {:.2}s",
        info.total_functions,
        info.fallible_functions.len(),
        infallible_count,
        info.external_functions,
        external_c_calls::registered_count(),
        t0.elapsed().as_secs_f64(),
    );
    // Surface `matchcontinue`s that are provably equivalent to a `match` so the
    // MetaModelica source can be simplified. Advisory only — does not affect
    // codegen. Printed to stderr like the parser warnings above.
    for w in &info.matchcontinue_as_match {
        eprintln!("{w}");
    }
    if !info.matchcontinue_as_match.is_empty() {
        println!(
            "Fallibility analysis: {} matchcontinue expression(s) could be rewritten as `match`",
            info.matchcontinue_as_match.len(),
        );
    }

    // `--fix`: rewrite those provably-equivalent `matchcontinue`s to `match` in
    // the MetaModelica sources and stop (no code generation). The user then
    // verifies the rewrites by rebuilding the boot compiler / running tests.
    if fix {
        match fix::apply_match_fixes(&info.matchcontinue_as_match_locs) {
            Ok(s) => println!(
                "--fix: rewrote {} matchcontinue → match across {} file(s); {} skipped",
                s.rewritten, s.files_changed, s.skipped,
            ),
            Err(e) => eprintln!("--fix: failed: {e}"),
        }
        return;
    }

    // Visibility analysis: narrow every public function not reachable across a
    // crate boundary from `pub` to `pub(crate)`.
    let t0 = std::time::Instant::now();
    let vis = visibility::analyze(&hier);
    let total_fns = info.total_functions;
    let crate_local = total_fns.saturating_sub(vis.keep_public.len());
    hier.keep_public = vis.keep_public;
    // The typed OMEdit interface (`openmodelica_scripting_qt`, see
    // `codegen::emit_scripting_api_qt`) is a separate crate whose generated
    // wrappers call every `OpenModelicaScriptingAPI` function across the crate
    // boundary. The visibility pass only sees MetaModelica callers (none
    // cross-crate), so it would narrow them to `pub(crate)`; force them `pub`.
    if let Some(node) = hier.top_level.get("OpenModelicaScriptingAPI") {
        for (name, child) in &node.children {
            if matches!(child.ty, hierarchy::Ty::Function { .. }) {
                hier.keep_public.insert(format!("OpenModelicaScriptingAPI.{name}"));
            }
        }
    }
    // `TplMain.main` is the entry point of the `susan` binary
    // (`openmodelica_susan/src/main.rs`), which calls it across the lib→bin
    // crate boundary. The visibility pass only sees MetaModelica callers, so on
    // a Susan-only subset build (`mmtorust susan`) it would narrow `main` to
    // `pub(crate)`; force it `pub` like the scripting-API entries above.
    hier.keep_public.insert("TplMain.main".to_owned());
    println!(
        "Visibility analysis: {} functions kept `pub`, ~{} narrowable to `pub(crate)`; {:.2}s",
        hier.keep_public.len(),
        crate_local,
        t0.elapsed().as_secs_f64(),
    );

    // PartialEq requirement analysis: for each user-defined function,
    // figure out which of its type parameters need a `+ PartialEq` bound
    // in the emitted Rust signature. This runs after fallibility so we
    // can use its results (though right now it only needs `top_level`).
    // Without this pass codegen would either over-require PartialEq
    // (breaking callbacks forwarded through generic helpers like
    // `List.map3`) or under-require it (breaking transitive callers of
    // `valueEq`/`listMember`).
    //
    // `analyze_default` is a sibling pass that computes which type
    // parameters need a `+ Default` bound, driven by
    // `arrayCreateNoInit(size, <unassigned dummy>)` call sites that lower
    // to `arrayCreateDefault(size)`. The two passes share no mutable state
    // and only read `hier.top_level`, so we run them concurrently via
    // `rayon::join` to overlap their costs.
    let t0 = std::time::Instant::now();
    // `analyze_reference_eq` is a third sibling pass (referenceEq on
    // type-variable-typed operands lowers to a `metamodelica::ReferenceEq`
    // trait call that needs the bound); independent like the other two, so
    // it joins the same concurrent batch.
    let (partial_eq_required, (default_required, reference_eq_required)) = rayon::join(
        || codegen::analyze_partial_eq(&hier.top_level),
        || rayon::join(
            || codegen::analyze_default(&hier.top_level),
            || codegen::analyze_reference_eq(&hier.top_level),
        ),
    );
    hier.partial_eq_required = partial_eq_required;
    hier.default_required = default_required;
    hier.reference_eq_required = reference_eq_required;
    let with_eq = hier.partial_eq_required.values().filter(|s| !s.is_empty()).count();
    let with_default = hier.default_required.values().filter(|s| !s.is_empty()).count();
    let with_refeq = hier.reference_eq_required.values().filter(|s| !s.is_empty()).count();
    println!(
        "PartialEq + Default + ReferenceEq analysis: {} PartialEq-bounded, {} Default-bounded, {} ReferenceEq-bounded; {:.2}s",
        with_eq,
        with_default,
        with_refeq,
        t0.elapsed().as_secs_f64(),
    );

    let t0 = std::time::Instant::now();
    codegen::generate_all(&hier, "openmodelica/src").expect("code generation failed");
    println!("Code generation {:.2}s", t0.elapsed().as_secs_f64())
}

fn render_dot_if_available(dot_file: &str, svg_file: &str) {
    // Check whether `dot` (Graphviz) is on PATH by running `dot -V`.
    let available = std::process::Command::new("dot")
        .arg("-V")
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .is_ok();

    if !available {
        println!("(dot not found on PATH; render manually: dot -Tsvg {dot_file} -o {svg_file})");
        return;
    }

    // `dot`'s default layout can spin effectively forever on the ~450-node
    // package graph, so cap it with a wall-clock timeout and kill the child
    // if it overruns rather than hanging the whole tool.
    const TIMEOUT: std::time::Duration = std::time::Duration::from_secs(30);
    let child = std::process::Command::new("dot")
        .args(["-Tsvg", dot_file, "-o", svg_file])
        .spawn();
    let mut child = match child {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Failed to run dot for {dot_file}: {e}");
            return;
        }
    };
    let start = std::time::Instant::now();
    loop {
        match child.try_wait() {
            Ok(Some(s)) if s.success() => println!("Rendered: {svg_file}"),
            Ok(Some(s)) => eprintln!("dot exited with {s} for {dot_file}"),
            Ok(None) => {
                if start.elapsed() >= TIMEOUT {
                    let _ = child.kill();
                    let _ = child.wait();
                    eprintln!("dot timed out after {}s on {dot_file}; render manually: dot -Tsvg {dot_file} -o {svg_file}", TIMEOUT.as_secs());
                } else {
                    std::thread::sleep(std::time::Duration::from_millis(100));
                    continue;
                }
            }
            Err(e) => eprintln!("Failed to wait for dot on {dot_file}: {e}"),
        }
        break;
    }
}

fn run_dep_analysis(programs: Vec<Absyn::Program>) {
    let t0 = std::time::Instant::now();
    let mut all_classes: Vec<MM::Class> = Vec::new();
    let mut failures = 0;
    for program in &programs {
        match MM::from_program(program) {
            Ok(mm_program) => all_classes.extend(mm_program),
            Err(e) => {
                eprintln!("MM ERR: {e}");
                failures += 1;
            }
        }
    }
    println!(
        "MM conversion: {} files, {} failures, {:.2}s",
        programs.len(),
        failures,
        t0.elapsed().as_secs_f64()
    );
    println!();

    let analysis = dep_analysis::DepAnalysis::build(&all_classes);
    dep_analysis::print_report(&analysis);

    let crate_dot = "dep_analysis_crates.dot";
    let pkg_dot = "dep_analysis_packages.dot";
    match dep_analysis::write_crate_dot(&analysis, crate_dot) {
        Ok(()) => println!("Wrote crate-level graph: {crate_dot}"),
        Err(e) => eprintln!("Failed to write {crate_dot}: {e}"),
    }
    match dep_analysis::write_package_dot(&analysis, pkg_dot) {
        Ok(()) => println!("Wrote package-level graph: {pkg_dot}"),
        Err(e) => eprintln!("Failed to write {pkg_dot}: {e}"),
    }
    println!();
    render_dot_if_available(crate_dot, "dep_analysis_crates.svg");
    // The package graph has ~450 nodes; rendering it is slow and rarely needed,
    // so only attempt it when explicitly requested.
    if std::env::var_os("MMTORUST_RENDER_PKG").is_some() {
        render_dot_if_available(pkg_dot, "dep_analysis_packages.svg");
    } else {
        println!("(skipping package-graph SVG; set MMTORUST_RENDER_PKG=1 to render {pkg_dot})");
    }
}

fn run_unused_functions(programs: Vec<Absyn::Program>) {
    let t0 = std::time::Instant::now();
    let mut all_classes: Vec<MM::Class> = Vec::new();
    let mut failures = 0;
    for program in &programs {
        match MM::from_program(program) {
            Ok(mm_program) => all_classes.extend(mm_program),
            Err(e) => {
                eprintln!("MM ERR: {e}");
                failures += 1;
            }
        }
    }
    println!(
        "MM conversion: {} files, {} failures, {:.2}s",
        programs.len(),
        failures,
        t0.elapsed().as_secs_f64()
    );

    let t0 = std::time::Instant::now();
    let mut hier = hierarchy::InstanceHierarchy::from_program(&all_classes);
    hierarchy::flatten_extends(&mut hier);
    let mut warnings = std::collections::BTreeSet::new();
    while hierarchy::resolve_pass(&mut hier, &mut warnings) {}
    println!(
        "Hierarchy extends+resolve types: {:.2}s",
        t0.elapsed().as_secs_f64()
    );

    let t0 = std::time::Instant::now();
    let report = unused_functions::analyze(&hier);
    println!(
        "Unused-function reachability: {:.2}s",
        t0.elapsed().as_secs_f64()
    );
    println!();
    unused_functions::print_report(&report);
}

fn run_const_patterns(programs: Vec<Absyn::Program>) {
    let t0 = std::time::Instant::now();
    let mut all_classes: Vec<MM::Class> = Vec::new();
    let mut failures = 0;
    for program in &programs {
        match MM::from_program(program) {
            Ok(mm_program) => all_classes.extend(mm_program),
            Err(e) => {
                eprintln!("MM ERR: {e}");
                failures += 1;
            }
        }
    }
    println!(
        "MM conversion: {} files, {} failures, {:.2}s",
        programs.len(),
        failures,
        t0.elapsed().as_secs_f64()
    );

    let t0 = std::time::Instant::now();
    let mut hier = hierarchy::InstanceHierarchy::from_program(&all_classes);
    hierarchy::flatten_extends(&mut hier);
    let mut warnings = std::collections::BTreeSet::new();
    while hierarchy::resolve_pass(&mut hier, &mut warnings) {}
    println!(
        "Hierarchy extends+resolve types: {:.2}s",
        t0.elapsed().as_secs_f64()
    );

    let t0 = std::time::Instant::now();
    let report = const_patterns::analyze(&hier);
    println!(
        "Constant-pattern scan: {:.2}s",
        t0.elapsed().as_secs_f64()
    );
    println!();
    const_patterns::print_report(&report);
}

fn run_mutable_cycles(programs: Vec<Absyn::Program>) {
    let t0 = std::time::Instant::now();
    let mut all_classes: Vec<MM::Class> = Vec::new();
    let mut failures = 0;
    for program in &programs {
        match MM::from_program(program) {
            Ok(mm_program) => all_classes.extend(mm_program),
            Err(e) => {
                eprintln!("MM ERR: {e}");
                failures += 1;
            }
        }
    }
    println!(
        "MM conversion: {} files, {} failures, {:.2}s",
        programs.len(),
        failures,
        t0.elapsed().as_secs_f64()
    );

    let t0 = std::time::Instant::now();
    let mut hier = hierarchy::InstanceHierarchy::from_program(&all_classes);
    hierarchy::flatten_extends(&mut hier);
    let mut warnings = std::collections::BTreeSet::new();
    while hierarchy::resolve_pass(&mut hier, &mut warnings) {}
    // Needed for the dyn-fn overlap section of the report.
    hierarchy::detect_types_containing_dyn_fn(&mut hier);
    println!(
        "Hierarchy extends+resolve types: {:.2}s",
        t0.elapsed().as_secs_f64()
    );

    let t0 = std::time::Instant::now();
    let report = mutable_cycles::analyze(&hier);
    println!(
        "Mutable-cycle analysis: {:.2}s",
        t0.elapsed().as_secs_f64()
    );
    println!();
    mutable_cycles::print_report(&report);
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    // The first non-flag argument (if any) selects an analysis subcommand;
    // flags like `--fix`/`--sources` must not be mistaken for it.
    let subcommand = args.get(1).map(|s| s.as_str()).filter(|s| !s.starts_with("--"));
    // `--fix` rewrites provably-safe `matchcontinue`s to `match` in the sources
    // (see `crate::fix`) instead of generating code.
    let fix = args.iter().any(|a| a == "--fix");
    // `--sources <file>` reads the list of MetaModelica files to transpile from
    // `<file>` instead of the default `compilerSources.txt`. This is how the
    // build transpiles only the subset needed to build the Susan binary
    // (`--sources susanSources.txt`); a `susan` subcommand is a shorthand for
    // that. Only the listed files are parsed and generated — classes still
    // route to their crate via the `__OpenModelica_Interface` annotation, so a
    // subset run emits exactly the crates those files belong to.
    let source_path: String = args
        .iter()
        .position(|a| a == "--sources")
        .and_then(|i| args.get(i + 1))
        .cloned()
        .unwrap_or_else(|| match subcommand {
            Some("susan") => "susanSources.txt".to_owned(),
            _ => "compilerSources.txt".to_owned(),
        });
    let t0 = std::time::Instant::now();
    rayon::ThreadPoolBuilder::new()
    .stack_size(16 * 1024 * 1024) // 16 MiB stack size, to avoid "thread stack overflow" on large files, especially on debug builds
    .num_threads(12)
    .build_global()
    .unwrap();

    let grammar = Grammar::MetaModelica;
    let sources = std::fs::read_to_string(&source_path)
        .unwrap_or_else(|e| panic!("could not read sources list {source_path:?}: {e}"));
    let mut i = 0;
    // Skip blank lines and `//`/`#` comment lines, so a source list (e.g.
    // susanSources.txt) can carry a documentation header. `compilerSources.txt`
    // is pure paths; this only adds tolerance.
    let files: Vec<(&str, usize)> = sources
        .lines()
        .map(|l| l.trim())
        .filter(|l| !l.is_empty() && !l.starts_with("//") && !l.starts_with('#'))
        .map(|f| {i += 1;(f,i-1)})
        .collect();

    let programs: Vec<std::sync::Mutex<Absyn::Program>> = files.iter().map(|_| std::sync::Mutex::new(Absyn::Program{classes: nil(), within_: Absyn::Within::TOP})).collect();

    let results: Vec<Result<(), String>> = files
        .par_iter()
        .map(|(path, ix)| {
            let result = std::fs::read_to_string(path)
                .map_err(|e| format!("read error: {e}"))
                .and_then(|code: String| parse(&code, path, path, grammar, /*readonly=*/false, /*timestamp=*/0.0).map_err(|e| format!("{e}")));
            match result {
                Ok(program) => {
                    *programs[*ix].lock().unwrap() = program;
                    Ok(())
                },
                Err(e) => Err(e),
            }
        })
        .collect();
    let elapsed = t0.elapsed();

    let mut failures = 0;
    for result in &results {
        match result {
            Ok(_) => (), // println!("OK  {path}"),
            Err(e) => {
                eprintln!("ERR: {e}");
                failures += 1;
            }
        }
    }

    println!("OpenModelica: {} files, {} failures, {:.2}s", results.len(), failures, elapsed.as_secs_f64());
    let parsed: Vec<Absyn::Program> = programs.iter().map(|p| p.lock().unwrap().clone()).collect();
    match subcommand {
        Some("dep-analysis") => run_dep_analysis(parsed),
        Some("unused-functions") => run_unused_functions(parsed),
        Some("const-patterns") => run_const_patterns(parsed),
        Some("mutable-cycles") => run_mutable_cycles(parsed),
        _ => start_compilation(parsed, fix),
    }
}
