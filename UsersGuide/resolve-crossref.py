#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import bibtexparser
import re, sys

with open(sys.argv[1], 'r') as bibtex_file:
    bibtex_str = bibtex_file.read()
# Work-around for new (broken?) bibtexparser
for (m,month) in [("jan","January"),("feb","February"),("mar","March"),("apr","April"),("may","May"),("jun","June"),("jul","July"),("aug","August"),("sep","September"),("oct","October"),("nov","November"),("dec","December")]:
  bibtex_str = re.sub(r"\n *month *= *%s *" % m, "\nmonth={%s}\n" % month, bibtex_str, flags=re.IGNORECASE)
bib_database = bibtexparser.loads(bibtex_str)

for e in bib_database.entries:
  if 'crossref' in e:
    e2 = bib_database.entries_dict[e['crossref']]
    for k in e2.keys():
      if not k in e:
        e[k] = e2[k]
    del(e['crossref'])
    if 'pdf' in e:
      del(e['pdf']) # Not used by the template and contains %20 sometimes...

open(sys.argv[2], "w").write(bibtexparser.dumps(bib_database))
