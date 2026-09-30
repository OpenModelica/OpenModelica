//! `susan-index --rust-src <dir> --out-dir <dir> [--report <file>] <TV.mo>...`
//!
//! Each `<TV.mo>` names the packages a template interface exposes (its
//! `package` blocks; `protected package` keeps a package out of unqualified
//! lookup). For every one, `<out-dir>/<TV.mo>` is written with the contents of
//! those packages taken from the Rust sources under `<rust-src>`; `builtin` and
//! packages without Rust sources are copied as they are. `<out-dir>/susan-index.json`
//! holds the same packages (and Tpl) for Susan's Rust backend. Outputs are only
//! rewritten when they change.

use std::fmt::Write as _;
use std::path::{Path, PathBuf};

use openmodelica_susan_index::extract::{SourceFiles, extract, extract_builtins};
use openmodelica_susan_index::{Index, Ty, TypeDef};

struct TvPackage {
    name: String,
    public: bool,
    indent: usize,
    text: String,
}

struct Tv {
    header: String,
    packages: Vec<TvPackage>,
    footer: String,
}

fn parse_tv(src: &str) -> Tv {
    let mut tv = Tv { header: String::new(), packages: vec![], footer: String::new() };
    let mut cur: Option<TvPackage> = None;
    for line in src.lines() {
        if let Some(p) = &mut cur {
            p.text.push_str(line);
            p.text.push('\n');
            if line.trim_end() == format!("{}end {};", " ".repeat(p.indent), p.name) {
                tv.packages.push(cur.take().unwrap());
            }
            continue;
        }
        let trimmed = line.trim_start();
        let (public, rest) = match trimmed.strip_prefix("protected ") {
            Some(r) => (false, r),
            None => (true, trimmed.strip_prefix("public ").unwrap_or(trimmed)),
        };
        if let Some(n) = rest.strip_prefix("package ") {
            let indent = line.len() - trimmed.len();
            cur = Some(TvPackage { name: n.trim().to_string(), public, indent, text: format!("{line}\n") });
        } else if tv.packages.is_empty() {
            writeln!(tv.header, "{line}").unwrap();
        } else {
            writeln!(tv.footer, "{line}").unwrap();
        }
    }
    tv
}

fn emit_package(name: &str, public: bool, idx: &Index, out: &mut String) {
    let p = &idx.packages[name];
    writeln!(out, "{}package {name}\n", if public { "" } else { "protected " }).unwrap();
    for (n, t) in &p.types {
        match t {
            TypeDef::Union { records, .. } => {
                writeln!(out, "  uniontype {n}").unwrap();
                for r in records {
                    writeln!(out, "    record {}", r.name).unwrap();
                    for f in &r.fields {
                        writeln!(out, "      {} {};", f.ty.susan(), f.name).unwrap();
                    }
                    writeln!(out, "    end {};", r.name).unwrap();
                }
                writeln!(out, "  end {n};\n").unwrap();
            }
            TypeDef::Alias(t) => writeln!(out, "  type {n} = {};\n", t.susan()).unwrap(),
        }
    }
    for (n, c) in &p.constants {
        writeln!(out, "  constant {} {n};\n", c.ty.susan()).unwrap();
    }
    for (n, f) in &p.functions {
        writeln!(out, "  function {n}").unwrap();
        for tv in &f.tyvars {
            writeln!(out, "    replaceable type {tv} subtypeof Any;").unwrap();
        }
        for a in &f.params {
            writeln!(out, "    input {} {};", a.ty.susan(), a.name).unwrap();
        }
        // Susan pairs a Text output with the Text input of the same name.
        let mut text_ins = f.params.iter().filter(|a| a.ty == Ty::Text).map(|a| &a.name);
        for (i, t) in f.outs.iter().enumerate() {
            let n = match text_ins.next() {
                Some(n) if *t == Ty::Text => n.clone(),
                _ => format!("out{i}"),
            };
            writeln!(out, "    output {} {n};", t.susan()).unwrap();
        }
        writeln!(out, "  end {n};\n").unwrap();
    }
    writeln!(out, "end {name};\n").unwrap();
}

fn write_if_changed(path: &Path, content: &str) -> std::io::Result<()> {
    if std::fs::read_to_string(path).is_ok_and(|old| old == content) {
        return Ok(());
    }
    std::fs::write(path, content)
}

fn run() -> Result<(), String> {
    let mut args = std::env::args().skip(1);
    let (mut rust_src, mut out_dir, mut report_file) = (None, None, None);
    let mut tvs: Vec<PathBuf> = vec![];
    while let Some(a) = args.next() {
        match a.as_str() {
            "--rust-src" => rust_src = args.next().map(PathBuf::from),
            "--out-dir" => out_dir = args.next().map(PathBuf::from),
            "--report" => report_file = args.next().map(PathBuf::from),
            _ if a.starts_with("--") => return Err(format!("unknown option {a}")),
            _ => tvs.push(PathBuf::from(a)),
        }
    }
    let usage = "usage: susan-index --rust-src <dir> --out-dir <dir> [--report <file>] <TV.mo>...";
    let (Some(rust_src), Some(out_dir)) = (rust_src, out_dir) else { return Err(usage.into()) };

    let parsed: Vec<(PathBuf, Tv)> = tvs
        .iter()
        .map(|p| Ok((p.clone(), parse_tv(&std::fs::read_to_string(p).map_err(|e| format!("{}: {e}", p.display()))?))))
        .collect::<Result<_, String>>()?;
    let files = SourceFiles::scan(&rust_src);
    let mut wanted: Vec<String> = parsed.iter().flat_map(|(_, tv)| tv.packages.iter().map(|p| p.name.clone())).collect();
    wanted.push("Tpl".into());
    let (mut idx, mut report) = extract(&files, &wanted);
    idx.crates = files.packages.iter().map(|(p, (c, _))| (p.clone(), c.clone())).collect();
    let builtins = extract_builtins(&rust_src, &mut report);
    idx.packages.insert("builtin".into(), builtins);

    std::fs::create_dir_all(&out_dir).map_err(|e| format!("{}: {e}", out_dir.display()))?;
    for (path, tv) in &parsed {
        let mut out = tv.header.clone();
        for p in &tv.packages {
            if p.name == "builtin" {
                out.push_str(&p.text.replace("end builtin;", "  uniontype FuncPtr end FuncPtr;\nend builtin;"));
                out.push('\n');
            } else if idx.packages.contains_key(&p.name) {
                emit_package(&p.name, p.public, &idx, &mut out);
            } else {
                out.push_str(&p.text);
                out.push('\n');
            }
        }
        out.push_str(&tv.footer);
        let dest = out_dir.join(path.file_name().unwrap());
        write_if_changed(&dest, &out).map_err(|e| format!("{}: {e}", dest.display()))?;
    }
    let json = serde_json::to_string_pretty(&idx.to_json()).unwrap();
    let dest = out_dir.join("susan-index.json");
    write_if_changed(&dest, &json).map_err(|e| format!("{}: {e}", dest.display()))?;

    let unresolved: Vec<&String> = wanted.iter().filter(|n| *n != "builtin" && !idx.packages.contains_key(*n)).collect();
    let mut rep = String::new();
    for n in unresolved {
        writeln!(rep, "{n}: no Rust sources, copied from the interface file").unwrap();
    }
    for r in &report {
        writeln!(rep, "{r}").unwrap();
    }
    match report_file {
        Some(f) => write_if_changed(&f, &rep).map_err(|e| format!("{}: {e}", f.display()))?,
        None => eprint!("{rep}"),
    }
    Ok(())
}

fn main() -> std::process::ExitCode {
    match run() {
        Ok(()) => std::process::ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("susan-index: {e}");
            std::process::ExitCode::FAILURE
        }
    }
}
