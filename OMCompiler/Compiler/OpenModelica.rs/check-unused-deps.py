#!/usr/bin/env python3
# This file is part of OpenModelica.
#
# Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
# c/o Linköpings universitet, Department of Computer and Information Science,
# SE-58183 Linköping, Sweden.
#
# All rights reserved.
#
# THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
# THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
# ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
# RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
# VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
#
# The OpenModelica software and the OSMC (Open Source Modelica Consortium)
# Public License (OSMC-PL) are obtained from OSMC, either from the above
# address, from the URLs:
# http://www.openmodelica.org or
# https://github.com/OpenModelica/ or
# http://www.ida.liu.se/projects/OpenModelica,
# and in the OpenModelica distribution.
#
# GNU AGPL version 3 is obtained from:
# https://www.gnu.org/licenses/licenses.html#GPL
#
# This program is distributed WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
# IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
#
# See the full OSMC Public License conditions for more details.

"""Report Cargo.toml dependencies that the crate's source never references.

For every workspace member this checks each declared dependency against the
identifier it would have to be spelled as in Rust code (the dependency *key*,
with `-` mapped to `_`; a `package = "x"` rename does not change the key the
code uses). A dependency whose identifier never appears as a source token is
reported as a candidate for removal.

To avoid false positives the check tokenises the Rust source rather than doing a
substring grep: line comments, (nested) block comments, char literals and string
literals — including raw strings `r#"..."#` and byte strings — are stripped
before identifiers are collected, so a crate name occurring only in a comment or
string does not count as a use. Dependency kinds are matched against the targets
that can actually see them:

  * `[dependencies]`        → lib/bin/test/bench/example sources (every `.rs`
                              except `build.rs`)
  * `[dev-dependencies]`    → same set (tests/examples/benches plus `#[cfg(test)]`
                              code under `src/`)
  * `[build-dependencies]`  → `build.rs` only

`[target.'cfg(...)'.*]` dependency tables are folded into the matching kind.

Known limitations (documented rather than worked around; verify a hit by hand
before deleting): a dependency used *only* through a re-exported proc-macro
derive (e.g. `metamodelica_derive`'s derives surfaced as
`metamodelica::ReferenceEq`) or a macro whose invocation name differs from the
crate name will be reported even though it is needed. These are flagged with a
note when the dependency looks like a `*_derive`/`*-macros` crate.
"""

from __future__ import annotations

import sys
import tomllib
from pathlib import Path

REPO = Path(__file__).resolve().parent


def strip_rust(src: str) -> str:
    """Return `src` with comments, char/string/byte/raw-string literals replaced
    by spaces, preserving everything else so identifier boundaries are intact."""
    out: list[str] = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        nxt = src[i + 1] if i + 1 < n else ""
        # Line comment.
        if c == "/" and nxt == "/":
            while i < n and src[i] != "\n":
                i += 1
            continue
        # Block comment (Rust allows nesting).
        if c == "/" and nxt == "*":
            depth = 1
            i += 2
            while i < n and depth:
                if src[i] == "/" and i + 1 < n and src[i + 1] == "*":
                    depth += 1
                    i += 2
                elif src[i] == "*" and i + 1 < n and src[i + 1] == "/":
                    depth -= 1
                    i += 2
                else:
                    i += 1
            out.append(" ")
            continue
        # Raw string: r"...", r#"..."#, br"...", br#"..."#.
        if _is_raw_string_start(src, i):
            i = _skip_raw_string(src, i)
            out.append(' ""')
            continue
        # Normal / byte string literal.
        if c == '"' or (c == "b" and nxt == '"'):
            i += 2 if c == "b" else 1
            while i < n:
                if src[i] == "\\":
                    i += 2
                    continue
                if src[i] == '"':
                    i += 1
                    break
                i += 1
            out.append(' ""')
            continue
        # Char / byte-char literal — but not a lifetime (`'a`) and not the
        # `'label:` loop label. A char literal has a closing `'` within 1-2
        # logical chars; a lifetime/label does not. Be conservative: only treat
        # it as a literal when a closing quote follows soon.
        if c == "'":
            if nxt == "\\":
                # escaped char literal: '\n', '\\', '\u{..}', etc.
                k = i + 2
                while k < n and src[k] != "'":
                    k += 1
                i = k + 1 if k < n else n
                out.append(" ")
                continue
            if i + 2 < n and src[i + 2] == "'":
                # simple 'x' char literal
                i += 3
                out.append(" ")
                continue
            # otherwise a lifetime or label — keep as-is
        out.append(c)
        i += 1
    return "".join(out)


def _is_raw_string_start(src: str, i: int) -> bool:
    # (b?) r #* "
    j = i
    if j < len(src) and src[j] == "b":
        j += 1
    if j < len(src) and src[j] == "r":
        j += 1
    else:
        return False
    while j < len(src) and src[j] == "#":
        j += 1
    return j < len(src) and src[j] == '"'


def _skip_raw_string(src: str, i: int) -> int:
    j = i
    if src[j] == "b":
        j += 1
    j += 1  # 'r'
    hashes = 0
    while src[j] == "#":
        hashes += 1
        j += 1
    j += 1  # opening quote
    closer = '"' + "#" * hashes
    end = src.find(closer, j)
    return (end + len(closer)) if end != -1 else len(src)


def identifiers(text: str) -> set[str]:
    ids: set[str] = set()
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c.isalpha() or c == "_":
            j = i + 1
            while j < n and (text[j].isalnum() or text[j] == "_"):
                j += 1
            ids.add(text[i:j])
            i = j
        else:
            i += 1
    return ids


def rs_files(crate: Path, *, build_rs: bool) -> list[Path]:
    if build_rs:
        f = crate / "build.rs"
        return [f] if f.exists() else []
    return [p for p in crate.rglob("*.rs") if p.name != "build.rs"]


def ident_set(files: list[Path]) -> set[str]:
    ids: set[str] = set()
    for f in files:
        try:
            ids |= identifiers(strip_rust(f.read_text(encoding="utf-8", errors="replace")))
        except OSError:
            pass
    return ids


def dep_keys(table: dict) -> list[str]:
    """Dependency keys from a `[*dependencies]` table, including any folded in
    from `[target.'cfg(..)'.*dependencies]` by the caller."""
    return list(table.keys())


def collect(data: dict, kind: str) -> list[str]:
    keys = list(data.get(kind, {}).keys())
    for tgt in data.get("target", {}).values():
        keys += list(tgt.get(kind, {}).keys())
    return keys


def main() -> int:
    cargo = tomllib.loads((REPO / "Cargo.toml").read_text())
    members = cargo["workspace"]["members"]
    any_unused = False
    for m in members:
        crate = REPO / m
        manifest = crate / "Cargo.toml"
        if not manifest.exists():
            continue
        data = tomllib.loads(manifest.read_text())

        regular = collect(data, "dependencies")
        dev = collect(data, "dev-dependencies")
        build = collect(data, "build-dependencies")

        non_build_ids = ident_set(rs_files(crate, build_rs=False))
        build_ids = ident_set(rs_files(crate, build_rs=True))

        unused: list[str] = []
        for kind, keys, ids in (
            ("dep", regular, non_build_ids),
            ("dev", dev, non_build_ids),
            ("build", build, build_ids),
        ):
            for k in keys:
                code_ident = k.replace("-", "_")
                if code_ident not in ids:
                    note = ""
                    if k.endswith(("_derive", "-derive", "_macros", "-macros")):
                        note = "  (proc-macro crate — may be used via a re-exported derive; verify)"
                    unused.append(f"    [{kind}] {k}{note}")

        if unused:
            any_unused = True
            print(f"{m}:")
            print("\n".join(unused))
    if not any_unused:
        print("No unused dependencies found.")
    return 1 if any_unused else 0


if __name__ == "__main__":
    sys.exit(main())
