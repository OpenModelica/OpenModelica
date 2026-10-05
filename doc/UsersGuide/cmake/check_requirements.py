#!/usr/bin/env python3
"""Report which of the distributions in a requirements file are not installed.

Prints the missing ones, one per line, and nothing at all when they are all
there. Run with the interpreter that is being checked:

    python3 check_requirements.py source/requirements.txt
"""

import re
import sys
from importlib.metadata import PackageNotFoundError, distribution

missing = []

with open(sys.argv[1], encoding="utf-8") as requirements:
    for line in requirements:
        # 'ompython >= 4.0' and 'sphinx[docs]==1.2  # comment' both name a
        # distribution up to the first version specifier, extra or comment.
        name = re.split(r"[<>=!~;\[ ]", line.split("#")[0].strip())[0]
        if not name:
            continue
        try:
            distribution(name)
        except PackageNotFoundError:
            missing.append(name)

print("\n".join(missing))
