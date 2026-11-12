#!/usr/bin/env python3
"""Converts each <name>.html in a directory to <name>.inc, as reST.

Usage: html-to-rst.py PANDOC DIR

A link to modelica://OpenModelica.Scripting.f becomes a reference to the
section of f in the scripting API chapter.
"""

import concurrent.futures
import pathlib
import re
import subprocess
import sys

SCRIPTING_LINK = re.compile(r"`([^`]*) <modelica://OpenModelica\.Scripting\.([A-Za-z0-9_-]*)>`__")


def convert(pandoc, html):
    rst = subprocess.run([pandoc, "--wrap=none", "-f", "html", "-t", "rst", str(html)],
                         check=True, capture_output=True, encoding="utf-8").stdout
    html.with_suffix(".inc").write_text(SCRIPTING_LINK.sub(r":ref:`\1 <\2>`", rst), encoding="utf-8")


def main(pandoc, directory):
    with concurrent.futures.ThreadPoolExecutor() as pool:
        jobs = [pool.submit(convert, pandoc, html) for html in sorted(pathlib.Path(directory).glob("*.html"))]
        for job in jobs:
            job.result()


if __name__ == "__main__":
    main(*sys.argv[1:])
