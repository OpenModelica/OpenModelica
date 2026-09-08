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
  "BioChem": {"1.0.1+msl.3.2.1"},
  "Buildings": {"12.1.2-maint.12.x"},
  "Complex": {
    "3.2.1+maint.om",
    "3.2.2+maint.om",
    "3.2.3+maint.om",
    "4.0.0+maint.om",
    "4.1.0+maint.om"
  },
  "Modelica": {
    "2.2.2+maint.om",
    "3.1.0+maint.om",
    "3.2.1+maint.om",
    "3.2.2+maint.om",
    "3.2.3+maint.om",
    "4.0.0+maint.om",
    "4.1.0+maint.om"
  },
  "ModelicaServices": {
    "1.0.0",
    "3.2.1+maint.om",
    "3.2.2+maint.om",
    "3.2.3+maint.om",
    "4.0.0+maint.om",
    "4.1.0+maint.om"
  },
  "ModelicaTest": {
    "3.2.3+maint.om",
    "4.0.0+maint.om",
    "4.1.0+maint.om"
  },
  "ModelicaCompliance": {
    "3.2.0-master"
  },
  "Modelica_DeviceDrivers": {
    "1.8.2"
  },
  "Modelica_Synchronous": {
    "0.92.2"
  },
  "ScalableTestSuite": {
    "2.2.0"
  },
  "SiemensPower": {
    "2.1.0-beta",
    "2.2.0",
    "OMCtest"
  },
  "ThermoPower": {
    "3.1.0-master"
  },
  "ThermoSysPro": {
    "3.2.0"
  },
  "WasteWater": {
    "2.1.0"
  }
}

# Everything that is shipped with an installation is tested as well.
for lib, versions in installed.items():
  testing.setdefault(lib, set()).update(versions)

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

with open(args.filenameprefix + "index.mos", "w") as fout:
  fout.write('''
setEnvironmentVar("HOME", OpenModelica.Scripting.cd());
setEnvironmentVar("APPDATA", OpenModelica.Scripting.cd());
getEnvironmentVar("HOME");
getErrorString();
setModelicaPath(OpenModelica.Scripting.cd() + "/.openmodelica/libraries/");
getModelicaPath();
echo(false);
OpenModelica.Scripting.mkdir(".openmodelica");
if not OpenModelica.Scripting.mkdir(".openmodelica/libraries/") then
  print("\\nmkdir failed\\n");
  print(getErrorString());
  exit(1);
end if;
vers:=OpenModelica.Scripting.getAvailablePackageVersions(Modelica, "3.2.3");
if size(vers,1) <> 1 then
  print("getAvailablePackageVersions(Modelica, \\"3.2.3\\") returned " + String(size(vers,1)) + " results\\n");
  print(getErrorString());
  exit(1);
end if;
if vers[1] <> "3.2.3+maint.om" then
  print("getAvailablePackageVersions(Modelica, \\"3.2.3\\") returned " + vers[1] + "\\n");
  print(getErrorString());
  exit(1);
end if;
''')
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
  fout.write(f'system("touch .openmodelica/{stamp}")')

with open(args.filenameprefix + "index.json", "w") as fout:
  fout.write(json.dumps({"libs":newdata,"mirrors":["https://libraries.openmodelica.org/cache/"]}, indent=2))
with open("Makefile.version", "w") as fout:
  fout.write(f'STAMP={stamp}')
