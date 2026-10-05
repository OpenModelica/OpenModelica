#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Inline BibTeX crossref fields.

pybtex, which sphinxcontrib-bibtex parses the bibliography with, does not expand
``crossref``, so an entry inheriting its venue from a ``@proceedings`` parent
would be rendered without it. Copy every field and person role the child does
not define itself from its parent and drop the ``crossref``.
"""

import sys

from pybtex.database import parse_file

bib = parse_file(sys.argv[1], "bibtex")

for entry in bib.entries.values():
    parent_key = entry.fields.get("crossref")
    if parent_key is None:
        continue
    parent = bib.entries[parent_key]
    for name, value in parent.fields.items():
        entry.fields.setdefault(name, value)
    for role, persons in parent.persons.items():
        if role not in entry.persons:
            entry.persons[role] = persons
    del entry.fields["crossref"]
    if "pdf" in entry.fields:
        del entry.fields["pdf"]  # Not used by the template and contains %20 sometimes...

bib.to_file(sys.argv[2], "bibtex")
