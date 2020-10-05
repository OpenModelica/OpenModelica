#!/usr/bin/env python3

import os.path
import json
import OMPython

with open(os.path.expanduser("~/.openmodelica/libraries/index.json")) as f:
  data = json.load(f)
om = OMPython.OMCSessionZMQ()
for lib in data['libs'].keys():
  om.sendExpression("installPackage(%s)" % lib)
  s = om.sendExpression("getErrorString()").strip()
  if s:
    print(s)
