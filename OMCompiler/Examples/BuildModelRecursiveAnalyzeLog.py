#!/usr/bin/env python

from glob import glob
import re
import numpy as np
import collections
import statsmodels.api as sm
import statsmodels.formula.api as smf
import sys
import traceback
import math

lookupMemSize = {"kB":1024,"MB":1024**2,"GB":1024**3,"TB":1024**4}
logs = {}
actions = collections.OrderedDict()
for f in sys.argv[1:]:
  res = re.search("^([_A-Za-z0-9.]*)(_N_([0-9]*))(_?M_([0-9]*))?.err$", f)
  if res is None:
    continue
  name = res.group(1)
  lst = logs.get(name) or {}
  logs[name] = lst
  tpl = (int(res.group(3) or 0),int(res.group(5) or 0))
  lst[tpl] = {}
  for line in open(f, "r"):
    res = re.search("^Notification: Performance of ([^:]*): time ([0-9.]*)/([0-9.])*, memory: ([0-9.]*) ([kMGT]B)? / ([0-9.]*) ([kMGT]B)?", line)
    if res is None:
      continue
    action = re.sub("[(]n=[0-9]*[)]","",res.group(1))
    if action in lst[tpl]:
      if action == "prepare postOptimizeDAE":
        action = "prepare postOptimizeDAE 2"
      else:
        raise Exception("Duplicate element %s in file %s" % (action,f))
    time = float(res.group(2))
    memory = float(res.group(4)) * (lookupMemSize[res.group(5)] if res.group(5) else 1)
    actions[action] = None
    lst[tpl][action] = (time,memory)
    if action=="Templates":
      time = float(res.group(3))
      memory = float(res.group(6)) * (lookupMemSize[res.group(7)] if res.group(7) else 1)
      actions["Total"] = None
      lst[tpl]["Total"] = (time,memory)
actions = actions.keys()
for f in logs:
    for action in actions:
      try:
        xn = []
        xm = []
        xsz = []
        yt = []
        ym = []
        for (n,m) in logs[f]:
          try:
            sz = n*m
            if sz==0:
              continue
            time, memory = logs[f][(n,m)][action]
          except:
            continue
          xn.append(n)
          xm.append(m)
          xsz.append(sz)
          yt.append(time)
          ym.append(memory)
        if len(xn)==0:
          continue
        if max(yt)<0.5:
          continue
        if max(ym)<100*lookupMemSize["MB"]:
          continue
        # Fit regression model
        data = {"memory":ym, "n":xn, "m": xm, "sz": xsz, "szlogsz": [n*math.log(n,2) for n in xsz]}
        results = smf.ols(formula = 'memory ~ np.power(sz, 2) + sz + szlogsz', data=data).fit()
        # Inspect the results
        sz2 = results.params[1]
        sz1 = results.params[2]
        sz1log1 = results.params[3]
        if sz2 > (max(sz1log1,0)+max(sz1,0))**0.5:
          print("%s is n^2 for %s. Parameters were: n^2: %f, n*log(n): %f, n: %f"%(f, action, sz2, sz1log1, sz1))
        elif max(ym)>50*lookupMemSize["GB"]:
          print("%s is using > 50 GB memory for %s. Parameters were: n^2: %f, n*log(n): %f, n: %f"%(f,action, sz2, sz1log1, sz1))
        elif action=="Total":
          pass
          # print("%s for %s. Parameters were: n^2: %f, n*log(n): %f, n: %f"%(f,action, sz2, sz1log1, sz1))
        #print(action,max(yt),max(ym)/lookupMemSize["MB"],np.polyfit(x,yt,2),np.polyfit(x,ym,2))
      except:
        print("Skipping file %s %s: %s" % (f,action,traceback.format_exc()))
