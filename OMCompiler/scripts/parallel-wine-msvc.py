#!/usr/bin/env python3

import argparse, os, subprocess, sys
from pathlib import Path
from joblib import Parallel, delayed

parser = argparse.ArgumentParser(description='OpenModelica parallel wine MSVC (VS2015) builder')
parser.add_argument('--omdev')
parser.add_argument('--wsdk', help="Path to VisualStudio 14.0")
parser.add_argument('--w10sdk', help="Path to Windows Kits")
parser.add_argument('--wine', default="wine", help="wine command to use")
parser.add_argument('--winetricks', default="winetricks", help="winetricks command to use")
parser.add_argument('--wineprefixesdir', default="%s/.wineprefixes/" % str(Path.home()), help="wineprefixes directory")
parser.add_argument('--wineprefixprefix', default="vs2015-", help="The prefix used for each wineprefix")

args = parser.parse_args()

print("Warning: Running wine in parallel seems slower than running it in serial")

for (val,var) in [(args.omdev,'OMDEV'),(args.wsdk,'WSDK'),(args.w10sdk,'W10SDK')]:
  if val:
    os.environ[var] = val
  if os.environ.get(var) is None:
    raise Exception('%s env.var cannot be empty. Set it in the environment or through the command-line option' % var)

omcdir = os.path.realpath(os.path.dirname(__file__)+"/..")

def runMake(target):
  env = os.environ.copy()
  env["WINEPREFIX"] = "%s/%s%s" % (args.wineprefixesdir, args.wineprefixprefix, target)
  try:
    return (True, target, subprocess.check_output(["/bin/bash", "-c", "source '%s/scripts/wine-msvc.source' && make %s" % (omcdir,target)], stderr=subprocess.STDOUT, env=env))
  except subprocess.CalledProcessError as ex:
    return (False, target, ex.output)

res1=Parallel(n_jobs=6)(delayed(runMake)(target) for target in ["wine_runc_msvc_gc","wine_fmil_msvc","wine_sundials_msvc"])
for (b,target,output) in res1:
  if not b:
    print(output)
    sys.exit(1)

print("Did the first batch")

res2=Parallel(n_jobs=6)(delayed(runMake)(target) for target in ["wine_runc_msvc_release","wine_runc_msvc_debug"])
for (b,target,output) in res2:
  if not b:
    print(output)
    print("%s failed" % target)
    sys.exit(1)
for (b,target,output) in res1+res2:
  print("")
  print(target)
  print(output)
  print("")
