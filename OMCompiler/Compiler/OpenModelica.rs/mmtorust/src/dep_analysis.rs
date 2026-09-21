//! Dependency analysis for MetaModelica packages.
//!
//! Analyses which top-level packages import from which other top-level packages
//! (derived solely from `import` statements, not from type or function references),
//! then maps those packages to the Rust crates they belong to and reports:
//!
//!  * The crate-level dependency graph (which crates depend on which).
//!  * Intra-crate package clusters: sets of packages within the same crate that
//!    have circular imports — these **must** be kept in the same crate.
//!  * Packages that are "leaf" nodes within their crate (no intra-crate imports
//!    at all) — candidates for being split into smaller crates.
//!  * Optional Graphviz `.dot` files for visual inspection.

#![allow(unused)]

use std::collections::{BTreeMap, BTreeSet, HashMap};
use crate::MM;
use openmodelica_ast::Absyn;

// ── Path helper ──────────────────────────────────────────────────────────────

fn path_to_dotted(path: &Absyn::Path) -> String {
    match path {
        Absyn::Path::IDENT { name } => name.to_string(),
        Absyn::Path::QUALIFIED { name, path } => format!("{}.{}", name, path_to_dotted(path)),
        Absyn::Path::FULLYQUALIFIED { path } => path_to_dotted(path),
    }
}

fn top_package(dotted: &str) -> &str {
    dotted.split('.').next().unwrap_or(dotted)
}

// ── Import collection ─────────────────────────────────────────────────────────

/// Recursively collect all top-level package names that `class` imports from,
/// at any nesting depth (including imports inside nested packages and functions).
fn collect_imported_packages(class: &MM::Class, out: &mut BTreeSet<String>) {
    collect_from_class_def(&class.body, out);
}

fn collect_from_class_def(def: &MM::ClassDef, out: &mut BTreeSet<String>) {
    let members = match def {
        MM::ClassDef::Parts { members, .. } | MM::ClassDef::ClassExtends { members, .. } => members,
        _ => return,
    };
    for member in members {
        match member {
            MM::ClassMember::Import(m) => {
                let dotted = import_path(&m.import);
                let top = top_package(&dotted).to_owned();
                out.insert(top);
            }
            MM::ClassMember::ClassDef(m) => {
                collect_from_class_def(&m.class_def.body, out);
            }
            _ => {}
        }
    }
}

fn import_path(import: &Absyn::Import) -> String {
    match import {
        Absyn::Import::UNQUAL_IMPORT { path }
        | Absyn::Import::QUAL_IMPORT { path }
        | Absyn::Import::NAMED_IMPORT { path, .. } => path_to_dotted(path),
        Absyn::Import::GROUP_IMPORT { prefix, .. } => path_to_dotted(prefix),
    }
}

// ── Tarjan SCC ────────────────────────────────────────────────────────────────

struct TarjanState<'a> {
    index_counter: usize,
    stack: Vec<&'a str>,
    on_stack: HashMap<&'a str, bool>,
    index: HashMap<&'a str, usize>,
    lowlink: HashMap<&'a str, usize>,
    sccs: Vec<Vec<String>>,
}

fn tarjan_scc(
    nodes: &[&str],
    adj: &BTreeMap<String, BTreeSet<String>>,
) -> Vec<Vec<String>> {
    let mut state = TarjanState {
        index_counter: 0,
        stack: Vec::new(),
        on_stack: HashMap::new(),
        index: HashMap::new(),
        lowlink: HashMap::new(),
        sccs: Vec::new(),
    };
    for &node in nodes {
        if !state.index.contains_key(node) {
            strongconnect(node, adj, &mut state);
        }
    }
    state.sccs
}

fn strongconnect<'a>(
    v: &'a str,
    adj: &'a BTreeMap<String, BTreeSet<String>>,
    state: &mut TarjanState<'a>,
) {
    let idx = state.index_counter;
    state.index.insert(v, idx);
    state.lowlink.insert(v, idx);
    state.index_counter += 1;
    state.stack.push(v);
    state.on_stack.insert(v, true);

    if let Some(neighbors) = adj.get(v) {
        // Collect neighbors first to avoid borrow issues
        let neighbors: Vec<&str> = neighbors.iter().map(|s| s.as_str()).collect();
        for w in neighbors {
            if !state.index.contains_key(w) {
                strongconnect(w, adj, state);
                let w_low = *state.lowlink.get(w).unwrap_or(&usize::MAX);
                let v_low = state.lowlink.get_mut(v).unwrap();
                *v_low = (*v_low).min(w_low);
            } else if *state.on_stack.get(w).unwrap_or(&false) {
                let w_idx = *state.index.get(w).unwrap();
                let v_low = state.lowlink.get_mut(v).unwrap();
                *v_low = (*v_low).min(w_idx);
            }
        }
    }

    if state.lowlink[v] == state.index[v] {
        let mut scc = Vec::new();
        loop {
            let w = state.stack.pop().unwrap();
            state.on_stack.insert(w, false);
            scc.push(w.to_owned());
            if w == v {
                break;
            }
        }
        state.sccs.push(scc);
    }
}

// ── Analysis entry point ──────────────────────────────────────────────────────

/// Maps a package to its crate label.  Packages without an annotation end up
/// in `"openmodelica"` (the default crate).
fn package_crate(class: &MM::Class) -> String {
    class
        .crate_name
        .clone()
        .unwrap_or_else(|| "openmodelica".to_owned())
}

pub struct DepAnalysis {
    /// package → crate
    pub package_to_crate: BTreeMap<String, String>,
    /// package → set of top-level packages it imports (including self / same-crate)
    pub package_imports: BTreeMap<String, BTreeSet<String>>,
}

impl DepAnalysis {
    pub fn build(programs: &[MM::Class]) -> Self {
        let mut package_to_crate: BTreeMap<String, String> = BTreeMap::new();
        let mut package_imports: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();

        for class in programs {
            package_to_crate.insert(class.name.clone(), package_crate(class));
            let mut imports = BTreeSet::new();
            collect_imported_packages(class, &mut imports);
            // Remove self-reference
            imports.remove(&class.name);
            package_imports.insert(class.name.clone(), imports);
        }

        DepAnalysis { package_to_crate, package_imports }
    }
}

// ── Text report ───────────────────────────────────────────────────────────────

pub fn print_report(analysis: &DepAnalysis) {
    let DepAnalysis { package_to_crate, package_imports } = analysis;

    // Invert: crate → packages
    let mut crate_packages: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
    for (pkg, cr) in package_to_crate {
        crate_packages.entry(cr.clone()).or_default().insert(pkg.clone());
    }

    // Crate-level dependency graph
    let mut crate_deps: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
    for (pkg, imports) in package_imports {
        let src_crate = &package_to_crate[pkg];
        for imported_pkg in imports {
            if let Some(dst_crate) = package_to_crate.get(imported_pkg.as_str())
                && dst_crate != src_crate {
                    crate_deps
                        .entry(src_crate.clone())
                        .or_default()
                        .insert(dst_crate.clone());
                }
        }
    }

    println!("═══════════════════════════════════════════════════════════");
    println!("  MetaModelica Package → Crate Dependency Analysis");
    println!("═══════════════════════════════════════════════════════════");
    println!();

    // ── Crate membership ─────────────────────────────────────────────────────
    println!("── Crate membership ────────────────────────────────────────");
    for (crate_name, pkgs) in &crate_packages {
        println!("  {crate_name}  ({} packages)", pkgs.len());
        for pkg in pkgs {
            println!("    · {pkg}");
        }
    }
    println!();

    // ── Crate-level dependency graph ─────────────────────────────────────────
    println!("── Crate-level dependencies (A → B means A imports from B) ─");
    for crate_name in crate_packages.keys() {
        if let Some(deps) = crate_deps.get(crate_name) {
            for dep in deps {
                println!("  {crate_name} → {dep}");
            }
        } else {
            println!("  {crate_name}  (no outgoing crate deps)");
        }
    }
    println!();

    // ── Per-crate analysis ───────────────────────────────────────────────────
    println!("── Per-crate analysis ──────────────────────────────────────");
    for (crate_name, pkgs) in &crate_packages {
        let pkg_vec: Vec<&str> = pkgs.iter().map(|s| s.as_str()).collect();

        // Build intra-crate adjacency (only edges within this crate)
        let mut intra_adj: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
        for pkg in pkgs {
            let empty = BTreeSet::new();
            let imports = package_imports.get(pkg.as_str()).unwrap_or(&empty);
            let intra: BTreeSet<String> = imports
                .iter()
                .filter(|dep| pkgs.contains(dep.as_str()))
                .cloned()
                .collect();
            intra_adj.insert(pkg.clone(), intra);
        }

        // SCCs on intra-crate graph
        let sccs = tarjan_scc(&pkg_vec, &intra_adj);
        let non_trivial_sccs: Vec<&Vec<String>> =
            sccs.iter().filter(|s| s.len() > 1).collect();

        // Leaf packages: no intra-crate imports AND no packages in this crate import them
        let packages_with_intra_imports: BTreeSet<&str> = intra_adj
            .iter()
            .filter(|(_, deps)| !deps.is_empty())
            .map(|(pkg, _)| pkg.as_str())
            .collect();

        let imported_by_others_in_crate: BTreeSet<String> = intra_adj
            .values()
            .flat_map(|deps| deps.iter().cloned())
            .collect();

        let leaf_packages: BTreeSet<&str> = pkg_vec
            .iter()
            .copied()
            .filter(|p| {
                !packages_with_intra_imports.contains(p)
                    && !imported_by_others_in_crate.contains(*p)
            })
            .collect();

        // Packages that import nothing from the same crate but ARE imported by others
        let no_intra_imports_but_used: Vec<&str> = pkg_vec
            .iter()
            .copied()
            .filter(|p| {
                !packages_with_intra_imports.contains(p)
                    && imported_by_others_in_crate.contains(*p)
            })
            .collect();

        println!("  Crate: {crate_name}");

        if non_trivial_sccs.is_empty() {
            println!("    No circular import clusters (all packages can be separated).");
        } else {
            println!("    Circular import clusters (must stay in same crate):");
            for scc in &non_trivial_sccs {
                let mut sorted = scc.to_vec();
                sorted.sort();
                println!("      cluster: {}", sorted.join(", "));
            }
        }

        if leaf_packages.is_empty() {
            println!("    No fully isolated packages.");
        } else {
            let mut sorted: Vec<&str> = leaf_packages.iter().copied().collect();
            sorted.sort();
            println!("    Fully isolated packages (split candidates — no intra-crate deps in or out):");
            for p in &sorted {
                // Show what they DO import cross-crate
                let empty = BTreeSet::new();
                let cross: Vec<String> = package_imports
                    .get(*p)
                    .unwrap_or(&empty)
                    .iter()
                    .filter_map(|dep| {
                        package_to_crate.get(dep.as_str()).map(|cr| format!("{dep} ({cr})"))
                    })
                    .collect();
                if cross.is_empty() {
                    println!("      · {p}  (no external deps either)");
                } else {
                    println!("      · {p}  imports: {}", cross.join(", "));
                }
            }
        }

        if !no_intra_imports_but_used.is_empty() {
            let mut sorted = no_intra_imports_but_used.clone();
            sorted.sort();
            println!("    Packages with no intra-crate imports (used by others in crate, but could move to a lower crate):");
            for p in &sorted {
                let empty = BTreeSet::new();
                let cross: Vec<String> = package_imports
                    .get(*p)
                    .unwrap_or(&empty)
                    .iter()
                    .filter_map(|dep| {
                        package_to_crate.get(dep.as_str()).map(|cr| format!("{dep} ({cr})"))
                    })
                    .collect();
                if cross.is_empty() {
                    println!("      · {p}  (no external deps)");
                } else {
                    println!("      · {p}  imports: {}", cross.join(", "));
                }
            }
        }

        println!();
    }

    // ── Full package dependency table ─────────────────────────────────────────
    println!("── Full package → package import table ─────────────────────");
    for (pkg, imports) in package_imports {
        if imports.is_empty() {
            continue;
        }
        let src_crate = &package_to_crate[pkg];
        let annotated: Vec<String> = imports
            .iter()
            .map(|dep| {
                if let Some(cr) = package_to_crate.get(dep.as_str()) {
                    if cr == src_crate {
                        format!("{dep}[same]")
                    } else {
                        format!("{dep}[{cr}]")
                    }
                } else {
                    format!("{dep}[?]")
                }
            })
            .collect();
        println!("  {pkg} ({src_crate}) → {}", annotated.join(", "));
    }
    println!();
}

// ── DOT output ────────────────────────────────────────────────────────────────

/// Write a Graphviz `.dot` file for the **crate-level** dependency graph.
pub fn write_crate_dot(analysis: &DepAnalysis, path: &str) -> std::io::Result<()> {
    let DepAnalysis { package_to_crate, package_imports } = analysis;

    let mut crate_deps: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
    for (pkg, imports) in package_imports {
        let src_crate = &package_to_crate[pkg];
        for imported_pkg in imports {
            if let Some(dst_crate) = package_to_crate.get(imported_pkg.as_str())
                && dst_crate != src_crate {
                    crate_deps
                        .entry(src_crate.clone())
                        .or_default()
                        .insert(dst_crate.clone());
                }
        }
    }

    let mut out = String::new();
    out.push_str("digraph crate_deps {\n");
    out.push_str("  rankdir=LR;\n");
    out.push_str("  node [shape=box, style=filled, fillcolor=lightblue];\n");

    let all_crates: BTreeSet<String> = package_to_crate.values().cloned().collect();
    for cr in &all_crates {
        let safe = dot_id(cr);
        out.push_str(&format!("  {safe} [label=\"{cr}\"];\n"));
    }
    for (src, dsts) in &crate_deps {
        let src_id = dot_id(src);
        for dst in dsts {
            let dst_id = dot_id(dst);
            out.push_str(&format!("  {src_id} -> {dst_id};\n"));
        }
    }
    out.push_str("}\n");
    std::fs::write(path, out)
}

/// Write a Graphviz `.dot` file for the **package-level** dependency graph,
/// with clusters grouping packages by crate.
pub fn write_package_dot(analysis: &DepAnalysis, path: &str) -> std::io::Result<()> {
    let DepAnalysis { package_to_crate, package_imports } = analysis;

    let mut crate_packages: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
    for (pkg, cr) in package_to_crate {
        crate_packages.entry(cr.clone()).or_default().insert(pkg.clone());
    }

    let mut out = String::new();
    out.push_str("digraph package_deps {\n");
    out.push_str("  rankdir=LR;\n");
    out.push_str("  node [shape=ellipse, fontsize=10];\n");
    out.push_str("  compound=true;\n");

    // Subgraph (cluster) per crate
    for (cr, pkgs) in &crate_packages {
        let cr_id = dot_cluster_id(cr);
        out.push_str(&format!("  subgraph cluster_{cr_id} {{\n"));
        out.push_str(&format!("    label=\"{cr}\";\n"));
        out.push_str("    style=filled;\n");
        out.push_str("    fillcolor=lightyellow;\n");
        for pkg in pkgs {
            let pkg_id = dot_id(pkg);
            out.push_str(&format!("    {pkg_id} [label=\"{pkg}\"];\n"));
        }
        out.push_str("  }\n");
    }

    // Edges
    for (pkg, imports) in package_imports {
        let src_id = dot_id(pkg);
        let src_crate = &package_to_crate[pkg];
        for dep in imports {
            if package_to_crate.contains_key(dep.as_str()) {
                let dst_id = dot_id(dep);
                let dst_crate = &package_to_crate[dep.as_str()];
                let cross = src_crate != dst_crate;
                if cross {
                    out.push_str(&format!(
                        "  {src_id} -> {dst_id} [color=red, style=dashed];\n"
                    ));
                } else {
                    out.push_str(&format!("  {src_id} -> {dst_id};\n"));
                }
            }
        }
    }

    out.push_str("}\n");
    std::fs::write(path, out)
}

fn dot_id(s: &str) -> String {
    // Wrap in double quotes so reserved DOT keywords (graph, node, edge,
    // subgraph, digraph — matched case-insensitively) are safe as identifiers.
    // Escape any embedded double-quotes and backslashes.
    let escaped = s.replace('\\', "\\\\").replace('"', "\\\"");
    format!("\"{escaped}\"")
}

/// Produce a safe unquoted identifier for use in `subgraph cluster_<id>` names.
/// DOT requires subgraph names to be plain identifiers (no spaces), but the
/// `cluster_` prefix plus alphanumeric-only body is always safe.
fn dot_cluster_id(s: &str) -> String {
    s.chars()
        .map(|c| if c.is_alphanumeric() || c == '_' { c } else { '_' })
        .collect()
}
