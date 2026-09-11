//! `cyclic-cells --fix`: migrate cells that can sit on a reference cycle from
//! `Mutable`/`Pointer` to `MutableCyclic`/`PointerCyclic`.
//!
//! `crate::mutable_cycles` decides which cells those are. Finding their uses in
//! the source needs several passes because MetaModelica expressions carry no
//! position: a call can only be located through its enclosing statement, and
//! plenty of cell operations sit where there is no statement at all (constant
//! declarations, `if`/`for` headers, `match` arms). Each pass below covers a
//! blind spot of the others.
//!
//! Nothing is rewritten on a guess — over-migrating is as broken as
//! under-migrating, since both are type errors. An ambiguous site is reported
//! and left alone, and as in [`crate::fix`] a file is written only if every
//! edit for it verified.

use std::collections::BTreeMap;

use openmodelica_ast::Absyn;

use crate::mutable_cycles::CellKind;

/// One `Mutable.*`/`Pointer.*` call whose cell content can sit on a cycle.
pub struct CyclicUse {
    /// Enclosing statement's span.
    pub info: Absyn::Info,
    pub kind: CellKind,
}

impl CellKind {
    fn package(self) -> &'static str {
        match self {
            CellKind::Mutable => "Mutable",
            CellKind::Pointer => "Pointer",
            // An array standing in for a cell has no drop-in cyclic spelling —
            // it has to become a `Mutable`/`MutableCyclic` by hand, which is a
            // change of shape, not of name.
            CellKind::Array => "",
        }
    }
    fn cyclic_package(self) -> &'static str {
        match self {
            CellKind::Mutable => "MutableCyclic",
            CellKind::Pointer => "PointerCyclic",
            CellKind::Array => "",
        }
    }
}

/// An identifier occurrence outside comments and string literals.
struct Ident {
    name: String,
    byte: usize,
    line: i32,
    /// First non-space byte after the identifier — distinguishes `Mutable.f`
    /// (a call) from `Mutable<T>` (a type reference).
    next: u8,
    /// Offset of that byte.
    next_byte: usize,
}

/// Scan `src` for identifier occurrences, skipping comments and strings.
fn scan_idents(src: &str) -> Vec<Ident> {
    let b = src.as_bytes();
    let mut out = Vec::new();
    let (mut i, mut line) = (0usize, 1i32);
    while i < b.len() {
        let c = b[i];
        if c == b'\n' {
            line += 1;
            i += 1;
            continue;
        }
        if c == b'/' && i + 1 < b.len() && b[i + 1] == b'/' {
            while i < b.len() && b[i] != b'\n' {
                i += 1;
            }
            continue;
        }
        if c == b'/' && i + 1 < b.len() && b[i + 1] == b'*' {
            i += 2;
            while i + 1 < b.len() && !(b[i] == b'*' && b[i + 1] == b'/') {
                if b[i] == b'\n' {
                    line += 1;
                }
                i += 1;
            }
            i = (i + 2).min(b.len());
            continue;
        }
        if c == b'"' {
            i += 1;
            while i < b.len() && b[i] != b'"' {
                if b[i] == b'\\' && i + 1 < b.len() {
                    i += 1;
                }
                if b[i] == b'\n' {
                    line += 1;
                }
                i += 1;
            }
            i = (i + 1).min(b.len());
            continue;
        }
        if c.is_ascii_alphabetic() || c == b'_' {
            let start = i;
            while i < b.len() && (b[i].is_ascii_alphanumeric() || b[i] == b'_') {
                i += 1;
            }
            let mut j = i;
            while j < b.len() && (b[j] == b' ' || b[j] == b'\t') {
                j += 1;
            }
            out.push(Ident {
                name: src[start..i].to_owned(),
                byte: start,
                line,
                next: if j < b.len() { b[j] } else { 0 },
                next_byte: j,
            });
            continue;
        }
        i += 1;
    }
    out
}

/// `import Alias = Some.Path;` renames a type inside a file, so a declaration
/// reads `Pointer<Class>` while the analysis knows the type as `NFClass`. Map
/// each alias to its target's last segment so the two can be compared.
fn import_aliases(src: &str) -> BTreeMap<String, String> {
    let mut out = BTreeMap::new();
    for line in src.lines() {
        let line = line.trim();
        let Some(rest) = line.strip_prefix("import ") else { continue };
        let Some((alias, target)) = rest.split_once('=') else { continue };
        let alias = alias.trim();
        let target = target.trim().trim_end_matches(';').trim();
        if alias.is_empty() || !alias.chars().all(|c| c.is_alphanumeric() || c == '_') {
            continue;
        }
        if let Some(last) = target.rsplit('.').next()
            && !last.is_empty()
        {
            out.insert(alias.to_owned(), last.to_owned());
        }
    }
    out
}

/// Offset just past the `>` closing the `<` at `open`, tracking nesting.
/// `None` if the brackets do not balance before end of file.
fn matching_angle(src: &str, open: usize) -> Option<usize> {
    let b = src.as_bytes();
    if b.get(open) != Some(&b'<') {
        return None;
    }
    let mut depth = 0usize;
    for (i, &c) in b.iter().enumerate().skip(open) {
        match c {
            b'<' => depth += 1,
            b'>' => {
                depth -= 1;
                if depth == 0 {
                    return Some(i);
                }
            }
            // A declaration never spans a statement terminator; bail rather
            // than run away on a stray `<` used as less-than.
            b';' => return None,
            _ => {}
        }
    }
    None
}

#[derive(Default)]
pub struct CyclicFixStats {
    pub files_changed: usize,
    pub decls_rewritten: usize,
    pub calls_rewritten: usize,
    /// Spans where the reported call count did not match the source.
    pub ambiguous_spans: usize,
    /// Calls with no usable position (a cell op in an `if`/`for` header).
    pub calls_without_position: usize,
}

/// Rewrite the sources in place. `cyclic_simple_names` holds the *simple*
/// names of the types on a cell-crossing cycle — MetaModelica writes a type
/// reference unqualified (`Mutable<InstNode>`, not
/// `Mutable<NFInstNode.InstNode>`), so declarations are matched on that.
pub fn apply(
    uses: Vec<CyclicUse>,
    cyclic_simple_names: &std::collections::BTreeSet<String>,
    all_files: &[String],
) -> CyclicFixStats {
    let mut stats = CyclicFixStats::default();

    // Group the reported calls by file, then by (line span, cell kind).
    let mut per_file: BTreeMap<String, Vec<CyclicUse>> = BTreeMap::new();
    for u in uses {
        if u.info.lineNumberStart == 0 {
            // `if`/`for`/`while` carry no `Info`; those are fixed by hand.
            stats.calls_without_position += 1;
            continue;
        }
        per_file.entry(u.info.fileName.to_string()).or_default().push(u);
    }

    // Every source is scanned, not just the ones with reported calls: a file
    // can declare a cyclic cell without ever operating on it here.
    let mut files: std::collections::BTreeSet<String> = per_file.keys().cloned().collect();
    files.extend(all_files.iter().cloned());

    for file in files {
        let Ok(src) = std::fs::read_to_string(&file) else {
            eprintln!("cyclic-fix: cannot read {file}");
            continue;
        };
        let idents = scan_idents(&src);
        let aliases = import_aliases(&src);
        let is_cyclic_name = |n: &String| {
            cyclic_simple_names.contains(n)
                || aliases.get(n).is_some_and(|t| cyclic_simple_names.contains(t))
        };
        // byte -> replacement package name
        let mut edits: BTreeMap<usize, &'static str> = BTreeMap::new();

        // ── declarations: `Mutable<T>` / `Pointer<T>` with cyclic `T` ────────
        for (n, id) in idents.iter().enumerate() {
            let kind = match id.name.as_str() {
                "Mutable" => CellKind::Mutable,
                "Pointer" => CellKind::Pointer,
                _ => continue,
            };
            if id.next != b'<' {
                continue;
            }
            // Only identifiers inside the type argument count.
            let Some(end) = matching_angle(&src, id.next_byte) else { continue };
            let cyclic = idents[n + 1..]
                .iter()
                .take_while(|a| a.byte < end)
                .any(|a| is_cyclic_name(&a.name));
            if cyclic {
                edits.insert(id.byte, kind.cyclic_package());
                stats.decls_rewritten += 1;
            }
        }

        // ── declaration initialisers ─────────────────────────────────────────
        //
        // A component default (`PointerCyclic<X> v = Pointer.create(..)`) is
        // not a statement. Convert one `create` per cyclic layer of the declared
        // type, so nested cyclic layers convert and an inner
        // `Pointer.create(0)` building something else does not.
        for (n, id) in idents.iter().enumerate() {
            // Either a declaration this run just rewrote, or one an earlier run
            // already did — a re-run has to reach the same fixed point.
            let kind = match id.name.as_str() {
                "Mutable" if edits.contains_key(&id.byte) => CellKind::Mutable,
                "Pointer" if edits.contains_key(&id.byte) => CellKind::Pointer,
                "MutableCyclic" => CellKind::Mutable,
                "PointerCyclic" => CellKind::Pointer,
                _ => continue,
            };
            if id.next != b'<' {
                continue;
            }
            let Some(type_end) = matching_angle(&src, id.next_byte) else { continue };
            // How many cyclic layers this declaration's type has: the one we
            // just rewrote, plus any already-cyclic names inside it.
            let layers = 1 + idents[n + 1..]
                .iter()
                .take_while(|a| a.byte < type_end)
                .filter(|a| a.name == kind.cyclic_package())
                .count();
            let Some(semi) = src[type_end..].find(';').map(|o| type_end + o) else { continue };
            let mut done = 0;
            for a in idents[n + 1..].iter().take_while(|a| a.byte < semi) {
                if done == layers {
                    break;
                }
                if a.name == kind.package()
                    && a.next == b'.'
                    && src[a.next_byte..].starts_with(".create")
                {
                    edits.insert(a.byte, kind.cyclic_package());
                    stats.calls_rewritten += 1;
                    done += 1;
                }
            }
        }

        // ── calls on a variable whose declaration is cyclic ──────────────────
        //
        // Catches an initialiser on a non-cell declaration (`Equation eqn =
        // Pointer.access(eqn_ptr)`) and statement kinds with no `Info`. A name
        // declared both cyclic and plain in one file is ambiguous: skipped.
        {
            let mut cyclic_vars: std::collections::BTreeSet<&str> = Default::default();
            let mut plain_vars: std::collections::BTreeSet<&str> = Default::default();
            for (n, id) in idents.iter().enumerate() {
                let (set, kind) = match id.name.as_str() {
                    "MutableCyclic" => (&mut cyclic_vars, CellKind::Mutable),
                    "PointerCyclic" => (&mut cyclic_vars, CellKind::Pointer),
                    "Mutable" => (&mut plain_vars, CellKind::Mutable),
                    "Pointer" => (&mut plain_vars, CellKind::Pointer),
                    _ => continue,
                };
                let _ = kind;
                if id.next != b'<' {
                    continue;
                }
                let Some(type_end) = matching_angle(&src, id.next_byte) else { continue };
                // The declared name is the first identifier after the type.
                if let Some(name) = idents[n + 1..].iter().find(|a| a.byte > type_end) {
                    set.insert(name.name.as_str());
                }
            }
            for name in cyclic_vars.intersection(&plain_vars) {
                eprintln!(
                    "cyclic-fix: {file}: `{name}` is declared both cyclic and plain; \
                     calls on it left alone"
                );
            }
            for (n, id) in idents.iter().enumerate() {
                let kind = match id.name.as_str() {
                    "Mutable" => CellKind::Mutable,
                    "Pointer" => CellKind::Pointer,
                    _ => continue,
                };
                if id.next != b'.' || edits.contains_key(&id.byte) {
                    continue;
                }
                // `Pointer` `.` `op` `(` <first argument>. The argument is a
                // variable or a dotted field access (`sev.auxiliary`); the cell
                // is named by its last segment either way.
                // The argument identifier must be the one that *immediately*
                // follows the `(`. Without this check a literal first argument
                // (`Pointer.create({})`) makes the scan run past the call and
                // pick up an identifier from a later line.
                let Some(op) = idents.get(n + 1) else { continue };
                let open = op.next_byte;
                if src.as_bytes().get(open) != Some(&b'(') {
                    continue;
                }
                let mut arg = match idents.get(n + 2) {
                    Some(a) if src[open + 1..a.byte].trim().is_empty() => a,
                    _ => continue,
                };
                while arg.next == b'.' {
                    match idents.get(idents.iter().position(|x| x.byte == arg.byte).unwrap() + 1) {
                        Some(next) => arg = next,
                        None => break,
                    }
                }
                let named = cyclic_vars.contains(arg.name.as_str())
                    && !plain_vars.contains(arg.name.as_str());
                // Deliberately no rule keyed on the assignment target: an inner
                // `Pointer.create` building a different cell in the same
                // statement is indistinguishable textually, and guessing there
                // mis-migrated `makeAssignment(idx = Pointer.create(eqIndex))`.
                if named {
                    edits.insert(id.byte, kind.cyclic_package());
                    stats.calls_rewritten += 1;
                }
            }
        }

        // ── call sites, located by their statement's span ────────────────────
        if let Some(file_uses) = per_file.get(&file) {
            let mut by_span: BTreeMap<(i32, i32, CellKind), usize> = BTreeMap::new();
            for u in file_uses {
                *by_span
                    .entry((u.info.lineNumberStart, u.info.lineNumberEnd, u.kind))
                    .or_default() += 1;
            }
            for ((lo, hi, kind), reported) in by_span {
                let pkg = kind.package();
                let cyc = kind.cyclic_package();
                let in_span = |id: &&Ident| id.line >= lo && id.line <= hi && id.next == b'.';
                let hits: Vec<&Ident> =
                    idents.iter().filter(|id| in_span(id) && id.name == pkg).collect();
                // Calls this span already carries in migrated form. Counting
                // them is what makes a re-run converge instead of reporting
                // every finished span as ambiguous.
                let done = idents.iter().filter(|id| in_span(id) && id.name == cyc).count();
                // Already migrated; a plain call still in the span reads a
                // different, non-cyclic cell.
                if done >= reported {
                    continue;
                }
                // Mixed cyclic and non-cyclic calls in one statement; telling
                // them apart would need per-expression positions.
                if hits.len() + done != reported {
                    eprintln!(
                        "cyclic-fix: {file}:{lo}-{hi}: {reported} cyclic {pkg} call(s) \
                         reported but {} in the source; left alone",
                        hits.len()
                    );
                    stats.ambiguous_spans += 1;
                    continue;
                }
                for h in hits {
                    edits.insert(h.byte, kind.cyclic_package());
                    stats.calls_rewritten += 1;
                }
            }
        }

        // ── declarations of variables that are called cyclically ─────────────
        //
        // The reverse of the pass above, and the only thing that catches a
        // declaration whose cyclic payload hides behind a type alias
        // (`Pointer<Option<ClockTpl>>`, where `ClockTpl` aliases a tuple
        // containing a cyclic type). The call sites are driven by the analysis,
        // which resolves aliases, so a name called cyclically must have been
        // declared cyclically too.
        {
            let called_cyclic: std::collections::BTreeSet<&str> = idents
                .iter()
                .enumerate()
                .filter(|(n, id)| {
                    let migrated = matches!(id.name.as_str(), "MutableCyclic" | "PointerCyclic")
                        || edits.contains_key(&id.byte);
                    let _ = n;
                    migrated && id.next == b'.'
                })
                .filter_map(|(n, _)| idents.get(n + 2))
                .map(|a| a.name.as_str())
                .collect();
            for (n, id) in idents.iter().enumerate() {
                let kind = match id.name.as_str() {
                    "Mutable" => CellKind::Mutable,
                    "Pointer" => CellKind::Pointer,
                    _ => continue,
                };
                if id.next != b'<' || edits.contains_key(&id.byte) {
                    continue;
                }
                let Some(type_end) = matching_angle(&src, id.next_byte) else { continue };
                let Some(name) = idents[n + 1..].iter().find(|a| a.byte > type_end) else {
                    continue;
                };
                if called_cyclic.contains(name.name.as_str()) {
                    edits.insert(id.byte, kind.cyclic_package());
                    stats.decls_rewritten += 1;
                }
            }
        }

        if edits.is_empty() {
            continue;
        }

        // Apply back-to-front so earlier byte offsets stay valid.
        let mut out = src.clone();
        for (byte, repl) in edits.iter().rev() {
            let old_len = if repl.starts_with("Mutable") { "Mutable".len() } else { "Pointer".len() };
            if out.get(*byte..*byte + old_len).is_none() {
                eprintln!("cyclic-fix: offset out of range in {file}; file left untouched");
                out = src.clone();
                break;
            }
            out.replace_range(*byte..*byte + old_len, repl);
        }
        if out != src {
            add_imports(&mut out);
            if std::fs::write(&file, out).is_ok() {
                stats.files_changed += 1;
            } else {
                eprintln!("cyclic-fix: cannot write {file}");
            }
        }
    }
    stats
}

/// `Mutable.f(..)` needs `import Mutable;` in scope, so a file that gained a
/// `*Cyclic` reference needs the matching import. The original import stays —
/// the plain package is usually still used in the same file.
fn add_imports(src: &mut String) {
    for (plain, cyclic) in [("Mutable", "MutableCyclic"), ("Pointer", "PointerCyclic")] {
        if !src.contains(cyclic) || src.contains(&format!("import {cyclic};")) {
            continue;
        }
        let needle = format!("import {plain};");
        if let Some(pos) = src.find(&needle) {
            let end = pos + needle.len();
            src.insert_str(end, &format!("\nimport {cyclic};"));
        }
    }
}
