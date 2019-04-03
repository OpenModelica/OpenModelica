#!/usr/bin/env python3

import sys
import json
import time
from os import system
import itertools
import multiprocessing
from collections import OrderedDict
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--report",  help="Produce a text report", action='store_const', const=True)
parser.add_argument("--run", help="Select the run to create. Choose from msl32, rml, and omc")
parser.add_argument("--resultFile", default="result.json", help="The file to save/report results of")

args = parser.parse_args()

if (args.report is None and (args.run is None or ['msl32','rml','omc'].count(args.run) == 0)):
  parser.print_help()
  sys.exit(1)

def timeCmd(i,cmd,cleanCommand=None):
  if not cleanCommand is None:
    system(cleanCommand)
  t1 = time.monotonic()
  for j in range(0,i):
    if 0 != system(cmd):
      raise Exception("Compilation failed: %s" % cmd)
  t2 = time.monotonic()
  return (t2-t1) / i

def readableConfig(config):
  return "-j%2d %8s %5s" % (config['numMakeJobs'],config['compiler'],config['flags'])

allJobs = [
#  max(1,multiprocessing.cpu_count()/2),
  multiprocessing.cpu_count()*3/2
#  multiprocessing.cpu_count()*2
]
compilationOnly = True
numRuns = 1 # Use 3 to remove some spikes/randomness
allCompilers = ['gcc-4.4','gcc-4.6','gcc-4.7','gcc-4.8','clang']
# allCompilers = ['gcc-4.4','gcc-4.6','gcc-4.7','gcc-4.8','clang']
# allCompilers = ['gcc-4.4','clang']
allFlags = ['-O0 -fPIC','-O1 -fPIC','-O2 -fPIC','-Os -fPIC','-O3 -fPIC']
# allFlags = ['-O0','-O1','-O2','-Os','-O3']
# allFlags = ['-O0 -pipe','-O0']

allModels = []
if args.run == "msl32":
  # 'Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6'
  modelicaModels = ['Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulum','Modelica.Electrical.Spice3.Examples.Oscillator', 'Modelica.Fluid.Examples.DrumBoiler.DrumBoiler']
  allModels = [(x, x + ".mos", "rm -f *.o" % x, "-f %s.makefile" % x,'test -f %s.makefile' % x) for x in modelicaModels] # Test Modelica model compilation + simulation
  compilationOnly = False
  numRuns = 2
elif args.run == "rml":
  allModels = [('omc-rml','','rm -f Compiler/omc_release/*.o','-C Compiler/omc_release/',None)]
elif args.run == "omc":
  allModels = [('omc-bootstrapped','','rm -f testsuite/openmodelica/bootstrapping/build/*.o','-C testsuite/openmodelica/bootstrapping -f LinkMain.makefile make-separate-internal',None)]

res = {}

if args.run:
  for (n,(model,mosfile,cleanCommand,makefile,testCommand),compiler,flags) in itertools.product(allJobs,allModels,allCompilers,allFlags):
    if res.get(model) is None:
      res[model] = []
    if not testCommand is None:
      system('%s || omc %s > /dev/null' % (testCommand,mosfile))
    tmake = timeCmd(numRuns,"make CC=%s CFLAGS='%s' -j%d %s > /dev/null 2>&1" % (compiler,flags,n,makefile), cleanCommand)
    tsim = 0 if compilationOnly else timeCmd(numRuns,'./%s' % model) 
    print("%s %s %s Compilation Time: %.3f Simulation Time: %.3f" % (model,compiler,flags,tmake,tsim))
    res[model] += [{'numMakeJobs':n,'compiler':compiler,'flags':flags,'tmake':tmake,'tsim':tsim}]
  io = open(args.resultFile,'w')
  json.dump(res,io)
elif args.report:
  io = open(args.resultFile,'r')
  db = json.load(io)
  byConfig = {}
  for model in db.keys():
    bestmake = None
    bestmakeconfig = None
    bestsim = None
    bestsimconfig = None
    besttotal = None
    besttotalconfig = None
    for config in db[model]:
      tmake = config['tmake']
      tsim = config['tsim']
      config.pop('tmake')
      config.pop('tsim')
      ttotal = tmake+tsim
      configstr = readableConfig(config)
      if byConfig.get(configstr) is None:
        byConfig[configstr] = (0,0,0)
      byConfig[configstr] = tuple(x + y for x, y in zip((tmake, tsim, ttotal), byConfig[configstr]))
      if bestmake is None or tmake < bestmake:
        bestmake = tmake
        bestmakeconfig = config
      if bestsim is None or tsim < bestsim:
        bestsim = tsim
        bestsimconfig = config
      if besttotal is None or ttotal < besttotal:
        besttotal = ttotal
        besttotalconfig = config
    print(model)
    print("   Best Total        %.3f %s " % (besttotal,besttotalconfig))
    print("   Best Compile-time %.3f %s " % (bestmake,bestmakeconfig))
    print("   Best Run-time     %.3f %s " % (bestsim,bestsimconfig))
  for (i,name) in [(0,'make')] if compilationOnly else [(0,'make'),(1,'sim'),(2,'total')]:
    byConfigSortTotal = OrderedDict(sorted(byConfig.items(), key=lambda x: x[1][i]))
    print("Accumulated time for the given config (%s)" % name)
    base = byConfigSortTotal.values().__iter__().__next__()[i]
    for k in byConfigSortTotal.keys():
      t = byConfigSortTotal[k][i]
      print("%8.3f (x%3.2f)   %s" % (t,t/base,k))
  for weight in [] if compilationOnly else range(5,30,5):
    byConfigSortTotal = OrderedDict(sorted(byConfig.items(), key=lambda x: x[1][0] + weight*x[1][1]))
    print("Accumulated time for the given config (compilation + %d * simulation)" % weight)
    base = byConfigSortTotal.values().__iter__().__next__()
    baseTime = base[0] + weight*base[1]
    for k in byConfigSortTotal.keys():
      t = byConfigSortTotal[k][0] + weight*byConfigSortTotal[k][1]
      print("%8.3f (x%3.2f)   %s" % (t,t/baseTime,k))
