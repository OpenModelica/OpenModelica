#!/usr/bin/env python3

# Simple script that checks if any packages mutually depend on itself

import re

contents = open("Makefile.depends").read()
contents = contents.replace(".stamp","").replace(".mo","").replace("$(GEN_DIR)","")
# You can remove this line to see if public interfaces mutually depend on each other; this should be caught by OMC already though
contents = contents.replace(".interface", "")
contents = re.sub("RELPATH_[^)]*","",contents).replace("$()","")

lines = contents.split("\n")

m = {}

for l in lines:
  [a,b] = l.split(":")
  a = a.strip()
  bs = [c.strip() for c in b.split(" ") if (c.strip() and (not ".interface" in c))]
  m[a] = set(bs)

for k in sorted(m.keys()):
  for e in m[k]:
    if k in m[e]:
      print("Mutual recursion. Module %s imports %s which imports itself again" % (k,e))
      break
