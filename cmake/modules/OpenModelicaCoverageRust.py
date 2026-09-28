#!/usr/bin/env python3
"""Turn the Rust code's LLVM coverage profiles into a gcovr JSON tracefile.

A coverage build compiles OpenModelica's Rust libraries (libomc_result,
libSimulationRuntimeRust) with -C instrument-coverage, see
OpenModelicaCoverage.cmake. Their counters are not gcov's: every process
writes a .profraw where LLVM_PROFILE_FILE says, and only an llvm-profdata and
llvm-cov of the LLVM rustc was built with can read them - the ones of the
system are usually older. This merges the profiles, exports the libraries'
coverage with llvm-cov, and writes it as a gcovr JSON tracefile, so that it
merges into the report like the gcov tracefiles do.

The LLVM tools are taken from rustc's sysroot (rustup component llvm-tools),
and otherwise downloaded once, the component matching rustc, into --tools-dir.
"""

import argparse
import hashlib
import json
import re
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
from collections import defaultdict
from pathlib import Path

LIBRARIES = ('libomc_result.so', 'libSimulationRuntimeRust.so')


def rustc_info(rustc):
    out = subprocess.run([rustc, '-vV'], check=True, capture_output=True, text=True).stdout
    info = dict(line.split(': ', 1) for line in out.splitlines() if ': ' in line)
    sysroot = subprocess.run([rustc, '--print', 'sysroot'], check=True,
                             capture_output=True, text=True).stdout.strip()
    return info['release'], info['host'], info.get('commit-hash', ''), Path(sysroot)


def find_tools(rustc, tools_dir):
    release, host, commit, sysroot = rustc_info(rustc)
    candidates = [sysroot / 'lib' / 'rustlib' / host / 'bin']
    cache = tools_dir / f'llvm-tools-{release}-{host}'
    candidates.append(cache / 'llvm-tools-preview' / 'lib' / 'rustlib' / host / 'bin')
    for bin_dir in candidates:
        if (bin_dir / 'llvm-profdata').is_file() and (bin_dir / 'llvm-cov').is_file():
            return bin_dir

    # What `rustup component add llvm-tools` would install, from the same
    # manifest. Stable releases only; others have no per-version manifest.
    if not re.fullmatch(r'\d+\.\d+\.\d+', release):
        sys.exit(f'No llvm-profdata/llvm-cov for rustc {release}: '
                 f'run `rustup component add llvm-tools`.')
    manifest_url = f'https://static.rust-lang.org/dist/channel-rust-{release}.toml'
    print(f'Downloading the LLVM tools of rustc {release} ({manifest_url})', flush=True)
    manifest = urllib.request.urlopen(manifest_url, timeout=60).read().decode()
    section = re.search(r'^\[pkg\.llvm-tools(?:-preview)?\.target\.' + re.escape(host) + r'\]\n(.*?)(?=^\[)',
                        manifest, re.MULTILINE | re.DOTALL)
    url = section and re.search(r'^xz_url = "([^"]+)"', section.group(1), re.MULTILINE)
    if not url:
        sys.exit(f'No llvm-tools for {host} in {manifest_url}')
    cache.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryFile() as archive:
        with urllib.request.urlopen(url.group(1), timeout=300) as response:
            while chunk := response.read(1 << 20):
                archive.write(chunk)
        archive.seek(0)
        with tarfile.open(fileobj=archive, mode='r:xz') as tar:
            # The component tarball: llvm-tools-<version>-<host>/llvm-tools-preview/...
            for member in tar.getmembers():
                parts = Path(member.name).parts
                if len(parts) > 1 and '..' not in parts:
                    member.name = str(Path(*parts[1:]))
                    tar.extract(member, cache)
    bin_dir = candidates[-1]
    if not (bin_dir / 'llvm-cov').is_file():
        sys.exit(f'The downloaded llvm-tools have no llvm-cov in {bin_dir}')
    return bin_dir


def parse_lcov(text, files):
    """files[path][line] += count, and the functions, from llvm-cov's lcov."""
    current = None
    for line in text.splitlines():
        if line.startswith('SF:'):
            current = files[line[3:]]
        elif line.startswith('DA:') and current is not None:
            number, count = line[3:].split(',')[:2]
            current['lines'][int(number)] += int(count)
        elif line.startswith('FN:') and current is not None:
            number, name = line[3:].split(',', 1)
            current['functions'].setdefault(name, [int(number), 0])
        elif line.startswith('FNDA:') and current is not None:
            count, name = line[5:].split(',', 1)
            current['functions'].setdefault(name, [0, 0])[1] += int(count)
        elif line == 'end_of_record':
            current = None


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--profile-dir', required=True, type=Path,
                        help='where the .profraw files are (LLVM_PROFILE_FILE)')
    parser.add_argument('--build-dir', required=True, type=Path,
                        help='build tree holding the instrumented Rust libraries')
    parser.add_argument('--root', required=True, type=Path,
                        help='source tree, which the tracefile paths are relative to')
    parser.add_argument('--source-dir', action='append', default=[],
                        help='keep only sources below these, relative to --root')
    parser.add_argument('--gcovr-json', type=Path,
                        help='a gcovr tracefile to take the format version from')
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--rustc', default='rustc')
    parser.add_argument('--tools-dir', required=True, type=Path,
                        help='where to download the LLVM tools to, if needed')
    args = parser.parse_args()

    root = args.root.resolve()
    version = '0.14'
    if args.gcovr_json and args.gcovr_json.is_file():
        with open(args.gcovr_json) as f:
            version = json.load(f).get('gcovr/format_version', version)
    result = {'gcovr/format_version': version, 'files': []}

    profiles = sorted(args.profile_dir.glob('*.profraw')) if args.profile_dir.is_dir() else []
    objects = [p for name in LIBRARIES for p in sorted(args.build_dir.rglob(name))
               if p.parent.name == 'release' and p.is_file()]
    if not profiles or not objects:
        print(f'rust: {len(profiles)} profiles in {args.profile_dir}, '
              f'{len(objects)} instrumented libraries: nothing to report')
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with open(args.output, 'w') as f:
            json.dump(result, f)
        return

    bin_dir = find_tools(args.rustc, args.tools_dir.resolve())
    files = defaultdict(lambda: {'lines': defaultdict(int), 'functions': {}})
    with tempfile.TemporaryDirectory() as tmp:
        profdata = Path(tmp) / 'merged.profdata'
        subprocess.run([str(bin_dir / 'llvm-profdata'), 'merge', '-sparse',
                        *map(str, profiles), '-o', str(profdata)], check=True)
        # One object at a time: llvm-cov rejects the lot if one of them was
        # not instrumented or has no profile.
        for obj in objects:
            run = subprocess.run([str(bin_dir / 'llvm-cov'), 'export', '-format=lcov',
                                  f'-instr-profile={profdata}', str(obj)],
                                 capture_output=True, text=True)
            if run.returncode != 0:
                print(f'rust: skipping {obj}: {run.stderr.strip()}')
                continue
            parse_lcov(run.stdout, files)

    prefixes = [d.rstrip('/') + '/' for d in args.source_dir]
    lines_total = lines_hit = 0
    for path, data in sorted(files.items()):
        try:
            relative = Path(path).resolve().relative_to(root).as_posix()
        except ValueError:
            continue  # the standard library, crates.io
        if prefixes and not any(relative.startswith(p) for p in prefixes):
            continue
        try:
            with open(root / relative, 'rb') as f:
                hashes = [hashlib.md5(t.rstrip(b'\n')).hexdigest() for t in f]
        except OSError:
            hashes = []
        lines = []
        for number in sorted(data['lines']):
            record = {'line_number': number, 'count': data['lines'][number], 'branches': []}
            if number <= len(hashes):
                record['gcovr/md5'] = hashes[number - 1]
            lines.append(record)
            lines_total += 1
            lines_hit += record['count'] > 0
        functions = [{'name': name, 'demangled_name': name, 'lineno': lineno,
                      'execution_count': count, 'blocks_percent': 100.0 if count else 0.0}
                     for name, (lineno, count) in sorted(data['functions'].items())]
        result['files'].append({'file': relative, 'lines': lines, 'functions': functions})

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with open(args.output, 'w') as f:
        json.dump(result, f)
    print(f'rust: {lines_hit}/{lines_total} lines in {len(result["files"])} files, '
          f'from {len(profiles)} profiles of {len(objects)} libraries')


if __name__ == '__main__':
    main()
