#!/usr/bin/env python3
"""
Check that source files carry the OpenModelica Run-Time System license mark
and have an up-to-date copyright year.

Usage:
  check_runtime_license.py [--root ROOT] [--fix-year] [--fix-license] DIRS...

Arguments:
  DIRS          One or more directories to check (relative to ROOT).
  --root ROOT   Repository root (default: directory of this script + "/../..").
  --exceptions FILE
                Path to the exception list (default: next to this script,
                SimulationRuntime-license-exceptions.txt).
  --update-year Update copyright end-year to current year.
  --fix-license Replace wrong/missing license headers with the correct one.
  --summary     Print a one-line summary even when there are no errors.

Exit codes:
  0  All files pass (or all failures were fixed with --fix-license).
  1  One or more files fail.

Exception-list format (one entry per line):
  # comment lines and blank lines are ignored
  path/relative/to/ROOT     exact file or directory (excluded)
  glob/pattern/**/*.h       fnmatch glob relative to ROOT (excluded)
  !path/relative/to/ROOT    negation — re-includes a previously excluded path

  Patterns are evaluated in order; last match wins (same as .gitignore).

Supported file types and their expected comment style:
  C/C++   .c .h .cpp .cc .cxx .inc .inl .hpp .cl   /* block comment */
  Python  .py                          # line comments
  Modelica .mo .tpl                    /* block */ or // line comments
"""

from __future__ import annotations

import argparse
import fnmatch
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Iterable

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

CURRENT_YEAR: int = datetime.now().year

RUNTIME_MARK = "This file belongs to the OpenModelica Run-Time System"
NORMAL_FILE_MARK = "This file is part of OpenModelica."

# Regex that matches "Copyright (c) YYYY" or "Copyright (c) YYYY-YYYY".
# Case-insensitive so "(C)" and "(c)" both match.
_COPYRIGHT_RE = re.compile(
    r"[Cc]opyright\s+\(c\)\s+(\d{4})(?:-(\d{4}))?",
    re.IGNORECASE,
)

# Regex that matches "OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8"
_OSMC_PL_1_8_RE = re.compile(
    r"OSMC PUBLIC LICENSE \(OSMC-PL\) VERSION 1\.8"
)

# Regex that matches any "OSMC PUBLIC LICENSE (OSMC-PL)" regardless of version
_OSMC_PL_ANY_RE = re.compile(
    r"OSMC PUBLIC LICENSE \(OSMC-PL\)"
)

OSMC_PL_1_8_LICENSE_TEXT_C = f"""
/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-{CURRENT_YEAR}, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
"""

OSMC_PL_1_8_LICENSE_TEXT_PY = f"""
# This file is part of OpenModelica.
#
# Copyright (c) 1998-{CURRENT_YEAR}, Open Source Modelica Consortium (OSMC),
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
"""


OSMC_PL_1_8_RUNTIME_LICENSE_TEXT_PY = f"""
#
# This file is part of OpenModelica.
#
# Copyright (c) 1998-{CURRENT_YEAR}, Open Source Modelica Consortium (OSMC),
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
#
"""

OSMC_PL_1_8_RUNTIME_LICENSE_TEXT_C = f"""
/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-{CURRENT_YEAR}, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */
"""


# ---------------------------------------------------------------------------
# File-type groups
# ---------------------------------------------------------------------------

C_STYLE_EXTS = frozenset({".c", ".h", ".cpp", ".cc", ".cxx", ".inc", ".inl", ".hpp", ".cl"})
PYTHON_EXTS = frozenset({".py"})
MODELICA_EXTS = frozenset({".mo", ".tpl"})

SUPPORTED_EXTS = C_STYLE_EXTS | PYTHON_EXTS | MODELICA_EXTS

# How many bytes of a file to read when looking for the header.
HEADER_READ_BYTES = 4096


# ---------------------------------------------------------------------------
# Header extraction
# ---------------------------------------------------------------------------

def _extract_c_header(content: str) -> str:
    """Return the license /* ... */ block, or leading // lines as fallback.

    Scans all /* */ blocks (skipping doxygen blocks like /** @addtogroup */)
    until a license block is found. This handles files where non-license code
    or doxygen comments (e.g. #pragma once, /** @addtogroup ... */) appear
    before the actual license header.
    """
    pos = 0
    while True:
        start = content.find("/*", pos)
        if start == -1:
            break
        end = content.find("*/", start)
        if end == -1:
            break
        block = content[start : end + 2]
        if _is_license_block(block):
            return block
        pos = end + 2
    # Fallback: leading // comment lines
    lines: list[str] = []
    for line in content.splitlines():
        s = line.strip()
        if s.startswith("//") or s == "":
            lines.append(line)
        else:
            break
    return "\n".join(lines)


def _extract_python_header(content: str) -> str:
    """Return leading # comment lines (and blank lines) from a Python file."""
    lines: list[str] = []
    for line in content.splitlines():
        s = line.strip()
        if s.startswith("#") or s == "":
            lines.append(line)
        else:
            break
    return "\n".join(lines)


def _extract_modelica_header(content: str) -> str:
    """Return the license /* ... */ block, or leading // lines."""
    pos = 0
    while True:
        start = content.find("/*", pos)
        if start == -1:
            break
        end = content.find("*/", start)
        if end == -1:
            break
        block = content[start : end + 2]
        if _is_license_block(block):
            return block
        pos = end + 2
    lines: list[str] = []
    for line in content.splitlines():
        s = line.strip()
        if s.startswith("//") or s == "":
            lines.append(line)
        else:
            break
    return "\n".join(lines)


def extract_header(content: str, ext: str) -> str:
    if ext in C_STYLE_EXTS:
        return _extract_c_header(content)
    if ext in PYTHON_EXTS:
        return _extract_python_header(content)
    if ext in MODELICA_EXTS:
        return _extract_modelica_header(content)
    return content[:HEADER_READ_BYTES]


# ---------------------------------------------------------------------------
# Exception list
# ---------------------------------------------------------------------------

def load_exceptions(exc_path: str | None) -> list[str]:
    if not exc_path or not os.path.exists(exc_path):
        return []
    patterns: list[str] = []
    with open(exc_path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line and not line.startswith("#"):
                patterns.append(line)
    return patterns


def _matches_pattern(rel: str, pattern: str) -> bool:
    """Return True if *rel* (forward-slash path) matches a single pattern."""
    pat = pattern.rstrip("/")
    if rel == pat or rel.startswith(pat + "/"):
        return True
    if fnmatch.fnmatch(rel, pattern):
        return True
    if fnmatch.fnmatch(os.path.basename(rel), pattern):
        return True
    return False


def is_excluded(rel_path: str, patterns: Iterable[str]) -> bool:
    """
    Return True if *rel_path* (relative to repo root, using forward slashes)
    is excluded by the pattern list.

    Patterns are evaluated in order, last match wins — identical to .gitignore:
      - A plain pattern excludes matching paths.
      - A pattern starting with '!' re-includes matching paths (negation).
      - If a pattern ends with '/' it matches the directory and everything
        inside it.
    """
    rel = rel_path.replace(os.sep, "/")

    excluded = False
    for pattern in patterns:
        if pattern.startswith("!"):
            if _matches_pattern(rel, pattern[1:]):
                excluded = False
        else:
            if _matches_pattern(rel, pattern):
                excluded = True
    return excluded


# ---------------------------------------------------------------------------
# License header replacement
# ---------------------------------------------------------------------------

def _is_license_block(block: str) -> bool:
    """Return True if a /* */ block looks like a license header (not doxygen)."""
    lower = block.lower()
    return "copyright" in lower or "osmc" in lower or "license" in lower


def _replace_c_license_header(filepath: str, content: str, is_runtime: bool) -> bool:
    """Replace or prepend the correct OSMC-PL 1.8 license header.

    Scans all /* */ blocks to find an existing license block (skipping doxygen
    blocks and other non-license comments). If found, the old block is removed
    and the new header is placed at the top of the file. If no license block
    exists the header is prepended before all existing content (including any
    leading #pragma once or doxygen comments).
    Works for C/C++ and Modelica files (both use /* */ block comments).
    Returns True after rewriting the file.
    """
    new_header = (
        OSMC_PL_1_8_RUNTIME_LICENSE_TEXT_C if is_runtime else OSMC_PL_1_8_LICENSE_TEXT_C
    ).strip()

    pos = 0
    while True:
        start = content.find("/*", pos)
        if start == -1:
            break
        end = content.find("*/", start)
        if end == -1:
            break
        block = content[start : end + 2]
        if _is_license_block(block):
            # Remove the old license block and prepend the new header,
            # keeping all surrounding content (including any preceding
            # #pragma once or doxygen comments) intact.
            before = content[:start]
            after = content[end + 2:]
            remaining = (before + after).lstrip("\n")
            new_content = new_header + "\n\n" + remaining
            with open(filepath, "w", encoding="utf-8") as fh:
                fh.write(new_content)
            return True
        pos = end + 2

    # No existing license /* */ block — prepend the header.
    new_content = new_header + "\n\n" + content
    with open(filepath, "w", encoding="utf-8") as fh:
        fh.write(new_content)
    return True


def _replace_python_license_header(filepath: str, content: str, is_runtime: bool) -> bool:
    """Replace or prepend the correct OSMC-PL 1.8 license header in a Python file.

    Preserves a shebang line (``#!``) as the very first line.  Any existing
    leading ``#`` comment block that contains license markers is replaced; if
    no such block exists the header is inserted right after the shebang (or at
    the top of the file when there is no shebang).
    Returns True after rewriting the file.
    """

    if is_runtime:
        raise ValueError("No Python runtime license available.")
    new_header = (OSMC_PL_1_8_LICENSE_TEXT_PY).strip()

    lines = content.splitlines(keepends=True)

    shebang = ""
    rest_start = 0
    if lines and lines[0].startswith("#!"):
        shebang = lines[0]
        rest_start = 1

    # Find the end of the leading # comment block (after optional shebang).
    comment_block_end = rest_start
    for j in range(rest_start, len(lines)):
        s = lines[j].strip()
        if s.startswith("#") or s == "":
            comment_block_end = j + 1
        else:
            break

    comment_block = "".join(lines[rest_start:comment_block_end])
    rest = "".join(lines[comment_block_end:])

    sep = "\n" if shebang else ""
    lower = comment_block.lower()
    if "copyright" in lower or "osmc" in lower or "license" in lower:
        # Remove the old license comment block; insert new header after shebang.
        new_content = shebang + sep + new_header + "\n\n" + rest.lstrip("\n")
    else:
        # No existing license — insert after shebang, preserving any other
        # leading comments that were already present.
        new_content = shebang + sep + new_header + "\n\n" + comment_block + rest

    with open(filepath, "w", encoding="utf-8") as fh:
        fh.write(new_content)
    return True


def _replace_license_header(filepath: str, content: str, is_runtime: bool, ext: str) -> bool:
    """Dispatch to the correct license-replacement helper based on file type."""
    if ext in PYTHON_EXTS:
        return _replace_python_license_header(filepath, content, is_runtime)
    return _replace_c_license_header(filepath, content, is_runtime)


def _update_copyright_year(filepath: str, content: str) -> bool:
    """Update the end year in the first copyright line to CURRENT_YEAR.

    Returns True if the file was rewritten.
    """
    m = _COPYRIGHT_RE.search(content)
    if not m:
        return False
    start_year = m.group(1)
    end_year = int(m.group(2) or m.group(1))
    if end_year == CURRENT_YEAR:
        return False
    new_text = f"Copyright (c) {start_year}-{CURRENT_YEAR}"
    new_content = content[:m.start()] + new_text + content[m.end():]
    with open(filepath, "w", encoding="utf-8") as fh:
        fh.write(new_content)
    return True


# ---------------------------------------------------------------------------
# Per-file check
# ---------------------------------------------------------------------------

def check_file(
    filepath: str,
    fix_year: bool,
    fix_license: bool,
    part_of_runtime: bool,
) -> list[str]:
    """Return a list of error strings for *filepath*, empty if the file passes.

    Errors for fixed issues are suffixed with " [FIXED]".
    """
    ext = os.path.splitext(filepath)[1].lower()
    errors: list[str] = []

    try:
        with open(filepath, encoding="utf-8", errors="replace") as fh:
            content = fh.read()
    except OSError as exc:
        return [f"cannot read file: {exc}"]

    header = extract_header(content[:HEADER_READ_BYTES], ext)

    has_runtime_mark = RUNTIME_MARK in header
    has_osmc_pl_1_8 = bool(_OSMC_PL_1_8_RE.search(header))
    has_osmc_pl_any = bool(_OSMC_PL_ANY_RE.search(header))

    if part_of_runtime:
        if has_runtime_mark and has_osmc_pl_1_8:
            if NORMAL_FILE_MARK in header:
                # Runtime file has a spurious "This file is part of OpenModelica."
                # prefix that belongs only in the normal (compiler) license.
                errors.append(
                    "runtime header contains spurious normal-file prefix"
                    f' ("{NORMAL_FILE_MARK}")'
                )
                if fix_license and ext in C_STYLE_EXTS | MODELICA_EXTS | PYTHON_EXTS:
                    if _replace_license_header(filepath, content, is_runtime=True, ext=ext):
                        errors[-1] += " [FIXED]"
            elif fix_year:
                _update_copyright_year(filepath, content)
        elif not has_runtime_mark and has_osmc_pl_1_8:
            errors.append(
                "wrong license type: has normal OSMC-PL 1.8 header, expected runtime header"
            )
            if fix_license and ext in C_STYLE_EXTS | MODELICA_EXTS | PYTHON_EXTS:
                if _replace_license_header(filepath, content, is_runtime=True, ext=ext):
                    errors[-1] += " [FIXED]"
        elif has_runtime_mark and not has_osmc_pl_1_8:
            if has_osmc_pl_any:
                errors.append("wrong OSMC-PL version in runtime header: expected 1.8")
            else:
                errors.append("missing OSMC-PL 1.8 in runtime license header")
            if fix_license and ext in C_STYLE_EXTS | MODELICA_EXTS | PYTHON_EXTS:
                if _replace_license_header(filepath, content, is_runtime=True, ext=ext):
                    errors[-1] += " [FIXED]"
        else:
            # Neither runtime mark nor OSMC-PL 1.8 found.
            if has_osmc_pl_any:
                errors.append("wrong OSMC-PL version: expected 1.8 runtime header")
            else:
                errors.append("missing OSMC-PL 1.8 runtime license header")
            if fix_license and ext in C_STYLE_EXTS | MODELICA_EXTS | PYTHON_EXTS:
                if _replace_license_header(filepath, content, is_runtime=True, ext=ext):
                    errors[-1] += " [FIXED]"
    else:
        if has_osmc_pl_1_8 and not has_runtime_mark:
            # Correct normal license; optionally update year.
            if fix_year:
                _update_copyright_year(filepath, content)
        elif has_osmc_pl_1_8 and has_runtime_mark:
            errors.append(
                "wrong license type: has runtime header, expected normal OSMC-PL 1.8 header"
            )
            if fix_license and ext in C_STYLE_EXTS | MODELICA_EXTS | PYTHON_EXTS:
                if _replace_license_header(filepath, content, is_runtime=False, ext=ext):
                    errors[-1] += " [FIXED]"
        else:
            if has_osmc_pl_any:
                errors.append("wrong OSMC-PL version: expected 1.8")
            else:
                errors.append("missing OSMC-PL 1.8 license header")
            if fix_license and ext in C_STYLE_EXTS | MODELICA_EXTS | PYTHON_EXTS:
                if _replace_license_header(filepath, content, is_runtime=False, ext=ext):
                    errors[-1] += " [FIXED]"

    return errors


# ---------------------------------------------------------------------------
# Directory walk
# ---------------------------------------------------------------------------

def iter_source_files(root: Path, check_dirs: list[Path]) -> Iterable[Path]:
    """Yield absolute paths of all source files under *check_dirs*."""
    for rel_dir in check_dirs:
        abs_dir = root.joinpath(rel_dir)
        if not abs_dir.is_dir():
            print(f"WARNING: directory not found: {abs_dir}", file=sys.stderr)
            continue
        for dirpath, dirnames, filenames in abs_dir.walk():
            dirnames[:] = sorted(d for d in dirnames if not d.startswith("."))
            for fn in sorted(filenames):
                if os.path.splitext(fn)[1].lower() in SUPPORTED_EXTS:
                    yield dirpath.joinpath(fn)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    default_root = os.path.normpath(os.path.join(script_dir, "..", ".."))
    default_exc = os.path.join(
        script_dir, "SimulationRuntime-license-exceptions.txt"
    )

    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "dirs",
        metavar="DIR",
        nargs="+",
        help="Directories to check, relative to ROOT.",
    )
    parser.add_argument(
        "--root",
        default=default_root,
        help="Repository root (default: %(default)s).",
    )
    parser.add_argument(
        "--exceptions",
        default=default_exc,
        metavar="FILE",
        help="Exception list file (default: %(default)s).",
    )
    parser.add_argument(
        "--update-year",
        action="store_true",
        help="Update the copyright end-year to the current year"
        f" ({CURRENT_YEAR}).",
    )
    parser.add_argument(
        "--fix-license",
        action="store_true",
        help="Replace wrong or missing license headers with the correct"
        " OSMC-PL 1.8 header (runtime or normal, depending on location).",
    )
    parser.add_argument(
        "--summary",
        action="store_true",
        help="Always print a summary line.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(args.root)
    dirs = [Path(raw_path) for raw_path in args.dirs]
    exceptions = load_exceptions(args.exceptions)

    failures: list[tuple[str, list[str]]] = []
    checked = 0
    skipped = 0
    runtime_roots = [
        Path(root) / "OMCompiler" / "SimulationRuntime",
        Path(root) / "OMCompiler" / "3rdParty" / "ryu",
    ]

    for abspath in iter_source_files(root, dirs):
        rel = str(abspath.relative_to(root)).replace(os.sep, "/")
        if is_excluded(rel, exceptions):
            skipped += 1
            continue
        checked += 1
        part_of_runtime = any(abspath.is_relative_to(r) for r in runtime_roots)
        errs = check_file(str(abspath), args.update_year, args.fix_license, part_of_runtime)
        if errs:
            failures.append((rel, errs))

    # --- Report ---
    unfixed_count = 0
    for rel, errs in failures:
        for err in errs:
            if err.endswith(" [FIXED]"):
                print(f"FIXED {rel}: {err[:-8]}")
            else:
                unfixed_count += 1
                print(f"FAIL  {rel}: {err}")

    if args.summary or failures:
        fixed_count = sum(
            1 for _, errs in failures for e in errs if e.endswith(" [FIXED]")
        )
        status = "PASSED" if unfixed_count == 0 else "FAILED"
        fix_note = f", {fixed_count} fixed" if fixed_count else ""
        print(
            f"\n{status}: checked {checked} files, "
            f"skipped {skipped} (excluded), "
            f"{unfixed_count} failures{fix_note}."
        )

    return 1 if unfixed_count > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
