#!/usr/bin/env python
# -*- coding: utf-8 -*-

import bibtexparser
import sys

with open(sys.argv[1], 'r') as bibtex_file:
    bibtex_str = bibtex_file.read()

bib_database = bibtexparser.loads(bibtex_str)

for e in bib_database.entries:
  if e.has_key('crossref'):
    e2 = bib_database.entries_dict[e['crossref']]
    for k in e2.keys():
      if not e.has_key(k):
        e[k] = e2[k]
    del(e['crossref'])
    if 'pdf' in e:
      del(e['pdf']) # Not used by the template and contains %20 sometimes...

open(sys.argv[2], "w").write(bibtexparser.dumps(bib_database).encode("utf8"))
