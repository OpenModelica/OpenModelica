#!/usr/bin/env python3
"""Compiler launcher: compile the compiler's generated C without its #line.

Usage: OpenModelicaCoverageClangLauncher.py --c-files-dir DIR -- [launcher...] compiler args...

For Clang coverage builds only. LLVM's gcov instrumentation drops every line
whose #line names another file than the one its function starts in, which in
the compiler's generated C is every line of MetaModelica. So a source in DIR
is compiled from a copy next to its object file instead, which names the
original in a #line 1 and has the other #line directives commented out: Clang
then records every line under the original, at its own line number, and
OpenModelicaCoverageLineDirectives.py maps them onto the MetaModelica through
the original's #line directives when the coverage is collected.

Everything else is run as it is.
"""

import os
import re
import sys
from pathlib import Path

LINE_DIRECTIVE = re.compile(rb'^(\s*)#(\s*line\b)', re.MULTILINE)


def main():
    args = sys.argv[1:]
    if len(args) < 4 or args[0] != '--c-files-dir' or args[2] != '--':
        sys.exit(__doc__.splitlines()[2])
    c_files_dir = Path(args[1]).resolve()
    command = args[3:]

    try:
        output = Path(command[command.index('-o') + 1])
    except (ValueError, IndexError):
        output = None
    for i, arg in enumerate(command):
        if output is None or not arg.endswith('.c'):
            continue
        source = Path(arg)
        if not source.is_absolute() or source.resolve().parent != c_files_dir:
            continue
        text = source.read_bytes()
        copy = LINE_DIRECTIVE.sub(rb'\1//#\2', text)
        header = b'#line 1 "' + arg.encode().replace(b'\\', b'\\\\') + b'"\n'
        copy_path = output.with_name(output.name + '.lines.c')
        copy_path.parent.mkdir(parents=True, exist_ok=True)
        # Only when it changed: its time stamp is in the dependency file.
        if not copy_path.is_file() or copy_path.read_bytes() != header + copy:
            copy_path.write_bytes(header + copy)
        # #include "..." looks next to the including file first, which the
        # copy is not.
        command[i:i + 1] = ['-iquote', str(source.parent), str(copy_path)]
        break

    os.execvp(command[0], command)


if __name__ == '__main__':
    main()
