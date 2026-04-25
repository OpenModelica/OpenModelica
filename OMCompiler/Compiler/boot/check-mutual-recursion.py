#!/usr/bin/env python3

# This file is part of OpenModelica.
#
# Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
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
