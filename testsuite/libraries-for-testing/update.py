#!/usr/bin/env python3

import requests
import json
import os
from datetime import datetime

data = requests.get('https://libraries.openmodelica.org/index/v1/index.json').json()
desired = {
  "BioChem": {"1.0.1+msl.3.2.1"},
  "Complex": {
    "3.2.1+maint.om",
    "3.2.2+maint.om",
    "3.2.3+maint.om",
    "4.0.0+maint.om"
  },
  "Modelica": {
    "2.2.2+maint.om",
    "3.1.0+maint.om",
    "3.2.1+maint.om",
    "3.2.2+maint.om",
    "3.2.3+maint.om",
    "4.0.0+maint.om"
  },
  "ModelicaServices": {
    "1.0.0",
    "3.2.1+maint.om",
    "3.2.2+maint.om",
    "3.2.3+maint.om",
    "4.0.0+maint.om"
  },
  "ModelicaTest": {
    "3.2.3+maint.om"
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
  "SiemensPower": {
    "2.1.0-beta",
    "2.2.0",
    "0.0.0-OMCtest"
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

with open("index.mos", "w") as fout:
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
if 0 <> system("cp index.json .openmodelica/libraries/") then
  print("Failed to cp index.json");
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
  fout.write('system("touch .openmodelica/libraries/%s")' % stamp)

with open("index.json", "w") as fout:
  fout.write(json.dumps({"libs":newdata}, indent=2))
with open("Makefile.version", "w") as fout:
  fout.write('STAMP=%s' % stamp)
