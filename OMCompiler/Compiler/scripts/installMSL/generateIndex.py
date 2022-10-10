#!/usr/bin/env python3

import requests
import json

data = requests.get('https://libraries.openmodelica.org/index/v1/index.json').json()
desired = {
  "Complex": {
    "3.2.3+maint.om",
    "4.0.0+maint.om"
  },
  "Modelica": {
    "3.2.3+maint.om",
    "4.0.0+maint.om"
  },
  "ModelicaServices": {
    "3.2.3+maint.om",
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

with open("index.json", "w") as fout:
  fout.write(json.dumps({"libs":newdata}, indent=2))