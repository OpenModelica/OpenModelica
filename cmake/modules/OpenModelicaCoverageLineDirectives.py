#!/usr/bin/env python3
"""Move Clang's coverage of the compiler's generated C onto the MetaModelica.

The C omc generates for the compiler carries a `#line` directive naming the
.mo for every statement (-d=gendebugsymbols), and `#line <n> OMC_FILE` back to
the C in between. GCC's gcov honours them. LLVM's gcov instrumentation drops
every line whose #line names another file than its function's, so a Clang
coverage build compiles that C without them (OpenModelicaCoverageClangLauncher.py),
and its counters come out as c_files/<Module>.c, at the C's own line numbers.

This replays the #line directives of each generated C file to find the .mo
line of each of those, and moves them to entries of their own in the gcovr
JSON tracefile, in place. The entries of the generated C are dropped, as the
report filters them out anyway: what is left of them is C of its own.

See OpenModelicaCoverage.cmake, which runs this for Clang builds.
"""

import argparse
import hashlib
import json
import re
from collections import defaultdict
from pathlib import Path

LINE_DIRECTIVE = re.compile(rb'^\s*#\s*line\s+(\d+)(?:\s+(.*?))?\s*$')


def presumed_lines(c_path):
    """For each physical line of c_path, 1-based: None where it is C, else
    (mo_path, line) as the #line directives above it make it."""
    result = [None]  # index 0 unused
    target, line = None, 0
    with open(c_path, 'rb') as f:
        for text in f:
            m = LINE_DIRECTIVE.match(text)
            if m:
                result.append(None)
                spec = (m.group(2) or b'').strip()
                line = int(m.group(1))
                if spec.startswith(b'"') and spec.endswith(b'"') and spec[1:-1].endswith(b'.mo'):
                    target = spec[1:-1].decode('utf-8', 'replace')
                else:
                    target = None  # OMC_FILE, or the C file by name
                continue
            if target is None:
                result.append(None)
            else:
                result.append((target, line))
                line += 1
    return result


def remap_entry(entry, c_path, root, moved, stats):
    presumed = presumed_lines(c_path)
    for line in entry['lines']:
        n = line['line_number']
        where = presumed[n] if n < len(presumed) else None
        if where is None:
            stats['c'] += 1
            continue
        stats['mo'] += 1
        moved[relative(where[0], root)][where[1]].append(line)


def relative(path, root):
    try:
        return Path(path).resolve().relative_to(root).as_posix()
    except ValueError:
        return Path(path).as_posix()


def merge_lines(records):
    """One line record out of those of several C lines under the same .mo
    line: run as often as the most run of them, as gcov counts a line."""
    first = dict(records[0])
    first['count'] = max(r['count'] for r in records)
    first['branches'] = [b for r in records for b in r.get('branches', [])]
    return first


def md5_lines(path):
    try:
        with open(path, 'rb') as f:
            return [hashlib.md5(t.rstrip(b'\n')).hexdigest() for t in f]
    except OSError:
        return None


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--gcovr-json', required=True, type=Path,
                        help='gcovr JSON tracefile, rewritten in place')
    parser.add_argument('--c-files-dir', required=True, type=Path,
                        help="directory of the compiler's generated C")
    parser.add_argument('--root', required=True, type=Path,
                        help='the --root the tracefile paths are relative to')
    parser.add_argument('--filter', action='append', default=[],
                        help="gcovr's --filter: keep only the .mo matching one")
    args = parser.parse_args()
    filters = [re.compile(f) for f in args.filter]

    root = args.root.resolve()
    c_files_dir = args.c_files_dir.resolve()
    with open(args.gcovr_json) as f:
        coverage = json.load(f)

    moved = defaultdict(lambda: defaultdict(list))
    stats = defaultdict(int)
    kept = []
    for entry in coverage.get('files', []):
        path = (root / entry['file']).resolve()
        if path.parent != c_files_dir:
            kept.append(entry)
            continue
        stats['files'] += 1
        if path.suffix == '.c' and path.is_file():
            remap_entry(entry, path, root, moved, stats)
        else:
            stats['missing'] += 1

    existing = {e['file']: e for e in kept}
    for mo_file, lines in list(moved.items()):
        # gcovr filtered what it collected, but not what this makes of it.
        if filters and not any(f.match(str(root / mo_file)) for f in filters):
            stats['filtered'] += sum(len(v) for v in lines.values())
            del moved[mo_file]
            continue
        hashes = md5_lines(root / mo_file)
        records = []
        for n in sorted(lines):
            record = merge_lines(lines[n])
            record['line_number'] = n
            # Like GCC's gcov gives it for a line under #line: no function of
            # its own, as the function starts in the C.
            record['function_name'] = f'<unknown function {min(lines)}>'
            if hashes and n <= len(hashes):
                record['gcovr/md5'] = hashes[n - 1]
            else:
                record.pop('gcovr/md5', None)
            records.append(record)
        entry = existing.get(mo_file)
        if entry is None:
            entry = {'file': mo_file, 'lines': [],
                     'functions': [{'name': f'<unknown function {min(lines)}>',
                                    'lineno': min(lines), 'gcovr/excluded': True}]}
            existing[mo_file] = entry
            kept.append(entry)
        by_number = {line['line_number']: line for line in entry['lines']}
        for record in records:
            n = record['line_number']
            by_number[n] = merge_lines([by_number[n], record]) if n in by_number else record
        entry['lines'] = [by_number[n] for n in sorted(by_number)]

    coverage['files'] = kept
    with open(args.gcovr_json, 'w') as f:
        json.dump(coverage, f)
    print(f"line directives: {stats['mo']} lines of {stats['files']} generated C files "
          f"moved to {len(moved)} .mo files, "
          f"{stats['filtered']} filtered out, {stats['c']} left as C, "
          f"{stats['missing']} files without their C")


if __name__ == '__main__':
    main()
