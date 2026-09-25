#!/usr/bin/env python3
"""Attribute coverage of Susan's generated MetaModelica back to the *.tpl.

The code generator is written as Susan templates, which are translated to
MetaModelica (*Tpl.mo) and only then to C, so gcov reports the generated
MetaModelica and the templates themselves never show up. There is no line
mapping from the generated .mo back to the .tpl - Susan only records template
positions at a handful of error sites - but it does keep the names: every
`template foo` becomes a `public function foo`.

That is enough for per-template coverage. For each generated function this
takes the coverage of its lines and attributes it to the `template foo` line
in the .tpl, so a template that never ran shows up as an uncovered line.
Coverage of a .tpl therefore reads as "how many of its templates ran", which
is what tells dead templates apart from live ones. It is not line coverage
*within* a template; that would need Susan to emit a real line map.

Reads a gcovr JSON tracefile and writes another one, to be merged into the
report with `gcovr --add-tracefile`. Its paths are relative to --root, like
gcovr's own, so it merges with tracefiles collected in another checkout.
"""

import argparse
import hashlib
import json
import os
import re
import sys
from pathlib import Path

# `public function foo` / `protected function lm_9` in the generated .mo.
MO_FUNCTION_RE = re.compile(r"^\s*(?:public|protected)\s+function\s+(\w+)")
# `template foo(...)` in the .tpl.
TPL_TEMPLATE_RE = re.compile(r"^\s*template\s+(\w+)")


def function_ranges(mo_path):
    """name -> (first line, last line) for every function in a generated .mo."""
    ranges = {}
    open_name = None
    open_line = 0
    for lineno, text in enumerate(mo_path.read_text(errors="replace").splitlines(), 1):
        if open_name is None:
            match = MO_FUNCTION_RE.match(text)
            if match:
                open_name, open_line = match.group(1), lineno
        elif text.strip() == f"end {open_name};":
            ranges[open_name] = (open_line, lineno)
            open_name = None
    return ranges


def template_lines(tpl_path):
    """name -> line number of its `template` declaration."""
    return {
        match.group(1): lineno
        for lineno, text in enumerate(tpl_path.read_text(errors="replace").splitlines(), 1)
        if (match := TPL_TEMPLATE_RE.match(text))
    }


def line_md5(text):
    """gcovr hashes the source line to notice that the file changed under it."""
    return hashlib.md5(text.encode("utf-8", errors="replace")).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gcovr-json", required=True, type=Path,
                        help="gcovr JSON covering the generated *Tpl.mo")
    parser.add_argument("--generated-mo-dir", required=True, type=Path,
                        help="directory holding the generated *Tpl.mo")
    parser.add_argument("--template-dir", required=True, type=Path,
                        help="source directory holding the *.tpl")
    parser.add_argument("--root", required=True, type=Path,
                        help="the --root gcovr was given; paths are written relative to it")
    parser.add_argument("--output", required=True, type=Path,
                        help="gcovr JSON tracefile to write")
    args = parser.parse_args()

    coverage = json.loads(args.gcovr_json.read_text())
    # Generated .mo path -> {line number: hit count}
    hits_by_file = {
        Path(entry["file"]).name: {l["line_number"]: l["count"] for l in entry["lines"]}
        for entry in coverage.get("files", [])
    }

    files_out = []
    total_templates = covered_templates = 0

    for tpl_path in sorted(args.template_dir.glob("*.tpl")):
        hits = hits_by_file.get(tpl_path.stem + ".mo")
        mo_path = args.generated_mo_dir / (tpl_path.stem + ".mo")
        if hits is None or not mo_path.is_file():
            continue

        ranges = function_ranges(mo_path)
        templates = template_lines(tpl_path)
        tpl_text = tpl_path.read_text(errors="replace").splitlines()

        lines_out = []
        for name, decl_line in sorted(templates.items(), key=lambda kv: kv[1]):
            span = ranges.get(name)
            if span is None:
                # A template with no generated function of its own; Susan
                # inlines some of them. Nothing to attribute.
                continue
            first, last = span
            # How often the template ran: the busiest line of its function.
            # Its own lines are not all reachable, so a min/average would
            # understate a template that clearly did run.
            count = max((hits.get(n, 0) for n in range(first, last + 1)), default=0)
            total_templates += 1
            if count:
                covered_templates += 1
            lines_out.append({
                "branches": [],
                "count": count,
                "gcovr/md5": line_md5(tpl_text[decl_line - 1] if decl_line <= len(tpl_text) else ""),
                "line_number": decl_line,
            })

        if lines_out:
            files_out.append({
                "file": os.path.relpath(tpl_path, args.root),
                "functions": [],
                "lines": lines_out,
            })

    args.output.write_text(json.dumps({
        "gcovr/format_version": coverage.get("gcovr/format_version", "0.6"),
        "files": files_out,
    }, indent=1))

    percent = 100.0 * covered_templates / total_templates if total_templates else 0.0
    print(f"templates: {percent:.1f}% ({covered_templates} out of {total_templates}) "
          f"in {len(files_out)} of {len(list(args.template_dir.glob('*.tpl')))} .tpl files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
