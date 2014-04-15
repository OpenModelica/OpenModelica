#!/usr/bin/env python
# coding=utf8

from optparse import OptionParser
import sys
import re

curYear = 2014

head_1_1 = r"""/[*].*This file is part of OpenModelica.*OSMC-PL[^/]*[*]/"""

head_1_2 = """/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-%d, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */""" % curYear
head_1_2_runtime = """/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-%d, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */""" % curYear

parser = OptionParser()
parser.add_option("--runtime", action="store_true", dest="runtime", default=False)
(options,args) = parser.parse_args()

expected = head_1_2_runtime if options.runtime else head_1_2

re_1_1 = re.compile(head_1_1,re.DOTALL)

def update(f,lines):
  fout = open(f,'w')
  for line in lines:
    fout.write(line)  

for f in args:
  lines = open(f).readlines()
  nlines = 35
  content = "".join([line.rstrip() + "\n" for line in lines[0:nlines]])
  if expected in content:
    continue
  if content.startswith("encapsulated package"):
    print "Updating %s from no header to 1.2 %sheader" % (f,"runtime " if options.runtime else "")
    lines = [expected,"\n"] + lines
    update(f,lines)
  else:
    newcontent = re_1_1.split(content)
    if len(newcontent) == 2:
      print "Updating %s from existing header to 1.2 %sheader" % (f,"runtime " if options.runtime else "")
      lines[0:nlines] = newcontent[0] + expected + newcontent[1]
      update(f,lines)
    else:
      print "Wrong header for file %s" % f
