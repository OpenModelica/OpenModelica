#!/usr/bin/env python3

import requests
import json
import os
from datetime import datetime
import argparse

parser = argparse.ArgumentParser(prog="OpenModelica index.json creator")
parser.add_argument('--test', action="store_true")
parser.add_argument('filenameprefix')
args = parser.parse_args()


data = requests.get('https://libraries.openmodelica.org/index/v1/index.json').json()
desired = {
  "BioChem": {"1.0.1+msl.3.2.1"},
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
} if args.test else {
  "Complex": {
    "4.0.0+maint.om"
  },
  "Modelica": {
    "3.2.3+maint.om",
    "4.0.0+maint.om"
  },
  "ModelicaServices": {
    "4.0.0+maint.om"
  },
  "ObsoleteModelica4": { # Used by MSL 3 to 4 conversion scripts
    "4.0.0+maint.om"
  },
  "ModelicaReference": {
    "4.0.0+maint.om"
  }
}
newdata = {}
for key in data["libs"].keys():
  if key not in desired:
    continue
  newdata[key] = {"versions": {}}
  versions = data["libs"][key]["versions"]
  for version in versions.keys():
    if version not in desired[key]:
      continue
    newdata[key]["versions"][version] = versions[version]

now = datetime.now()
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
  for lib in desired.keys():
    for version in desired[lib]:
      fout.write('''if not installPackage(%s, "%s", exactMatch=true) then
  print("%s %s failed.\\n");
  print(getErrorString());
  exit(1);
else
  print("Installed: %s %s\\n");
end if;
''' % (lib, version, lib, version, lib, version))
  fout.write('system("touch .openmodelica/%s")' % stamp)

with open(args.filenameprefix + "index.json", "w") as fout:
  fout.write(json.dumps({"libs":newdata,"mirrors":["https://libraries.openmodelica.org/cache/"]}, indent=2))
with open("Makefile.version", "w") as fout:
  fout.write('STAMP=%s' % stamp)
