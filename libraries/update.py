#!/usr/bin/env python3

import argparse
import json
from datetime import datetime
from zoneinfo import ZoneInfo

import requests

parser = argparse.ArgumentParser(
  description="Create the package index (index.json) and the omc script installing the packages "
              "(index.mos) for a set of Modelica libraries. The versions to use are listed in the "
              "'installed' and 'testing' dicts in this script, the index itself is fetched from "
              "libraries.openmodelica.org.")
parser.add_argument('--test', action="store_true",
                    help="use the libraries needed by the testsuite instead of the ones shipped "
                         "with an installation")
parser.add_argument('filenameprefix',
                    help="prefix of the files to write, e.g. 'install-' writes install-index.json "
                         "and install-index.mos. Pass an empty string to write index.json and "
                         "index.mos")
args = parser.parse_args()


data = requests.get('https://libraries.openmodelica.org/index/v1/index.json').json()
# The libraries that are shipped with an installation.
installed = {
  "Complex": {
    "4.0.0+maint.om",
    "4.1.0+maint.om"
  },
  "Modelica": {
    "3.2.3+maint.om",
    "4.0.0+maint.om",
    "4.1.0+maint.om"
  },
  "ModelicaServices": {
    "4.0.0+maint.om",
    "4.1.0+maint.om",
  },
  "ObsoleteModelica4": { # Used by MSL 3 to 4 conversion scripts
    "4.0.0+maint.om",
    "4.1.0+maint.om"
  },
  "ModelicaReference": {
    "4.0.0+maint.om",
    "4.1.0+maint.om"
  }
}

# The libraries needed by the testsuite.
testing = {
  "BioChem": {"1.1.3"},
  "Buildings": {"12.1.2-maint.12.x"},
  "Complex": {
    "4.0.0+maint.om",
    "4.1.0+maint.om"
  },
  "Modelica": {
    "4.0.0+maint.om",
    "4.1.0+maint.om"
  },
  "ModelicaServices": {
    "4.0.0+maint.om",
    "4.1.0+maint.om"
  },
  "ModelicaTest": {
    "4.0.0+maint.om",
    "4.1.0+maint.om"
  },
  "ModelicaCompliance": {
    "3.2.0-master"
  },
  "Modelica_DeviceDrivers": {
    "2.2.0"
  },
  "ScalableTestSuite": {
    "2.2.0"
  },
  "ThermoPower": {
    "4.0.0-dev"
  },
  "ThermoSysPro": {
    "4.2.0"
  }
}

# Everything that is shipped with an installation is tested as well, except MSL 3.x which the
# testsuite no longer uses.
for lib, versions in installed.items():
  testing.setdefault(lib, set()).update(v for v in versions if not v.startswith("3."))

desired = testing if args.test else installed
newdata = {}
for key in data["libs"]:
  if key not in desired:
    continue
  newdata[key] = {"versions": {}}
  versions = data["libs"][key]["versions"]
  for version in versions:
    if version not in desired[key]:
      continue
    newdata[key]["versions"][version] = versions[version]

now = datetime.now(ZoneInfo("Europe/Stockholm"))
stamp = now.strftime("%Y%m%d%H%M%S.stamp")

# The testsuite also runs the wasm-jit target, for which installPackage fetches
# the prebuilt wasm modules too.
wasm = 'setCommandLineOptions("--simCodeTarget=wasm-jit");\n' if args.test else ""
with open(args.filenameprefix + "index.mos", "w") as fout:
  fout.write('''
setEnvironmentVar("HOME", OpenModelica.Scripting.cd());
setEnvironmentVar("APPDATA", OpenModelica.Scripting.cd());
getEnvironmentVar("HOME");
getErrorString();
setModelicaPath(OpenModelica.Scripting.cd() + "/.openmodelica/libraries/");
getModelicaPath();
echo(false);
{wasm}OpenModelica.Scripting.mkdir(".openmodelica");
if not OpenModelica.Scripting.mkdir(".openmodelica/libraries/") then
  print("\\nmkdir failed\\n");
  print(getErrorString());
  exit(1);
end if;
vers:=OpenModelica.Scripting.getAvailablePackageVersions(Modelica, "4.1.0");
if size(vers,1) <> 1 then
  print("getAvailablePackageVersions(Modelica, \\"4.1.0\\") returned " + String(size(vers,1)) + " results\\n");
  print(getErrorString());
  exit(1);
end if;
if vers[1] <> "4.1.0+maint.om" then
  print("getAvailablePackageVersions(Modelica, \\"4.1.0\\") returned " + vers[1] + "\\n");
  print(getErrorString());
  exit(1);
end if;
'''.replace("{wasm}", wasm))
  # Sorted, so that regenerating gives a stable order instead of the iteration order of the sets.
  for lib in sorted(desired.keys()):
    for version in sorted(desired[lib]):
      fout.write(f'''if not installPackage({lib}, "{version}", exactMatch=true) then
  print("{lib} {version} failed.\\n");
  print(getErrorString());
  exit(1);
else
  print("Installed: {lib} {version}\\n");
end if;
''')
  fout.write(f'system("touch .openmodelica/{stamp}")\n')

with open(args.filenameprefix + "index.json", "w") as fout:
  index = {"libs":newdata,"mirrors":["https://libraries.openmodelica.org/cache/"]}
  # What the versions' prebuilt wasm modules use.
  index.update({k: data[k] for k in ("systemLibraries", "wasmToolchain") if k in data})
  fout.write(json.dumps(index, indent=2) + "\n")
with open("Makefile.version", "w") as fout:
  fout.write(f'STAMP={stamp}\n')
