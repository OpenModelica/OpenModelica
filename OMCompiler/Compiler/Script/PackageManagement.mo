/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package PackageManagement
  "The package manager, in OpenModelica.rs/openmodelica_package_manager."

protected

import Autoconf;
import Config;
import Error;
import ErrorTypes;
import JSON;
import PackageManagerExt;
import Settings;
import Testsuite;
import Util;

public

function getInstalledLibraries
  "The names of the libraries in the MODELICAPATH."
  output list<String> names;
algorithm
  names := JSON.getStringList(JSON.get(call("installedLibraries"), "libraries"));
end getInstalledLibraries;

function getInstalledLibraryVersions
  "The versions of a library in the MODELICAPATH, newest first. Fails if there
   is none."
  input String libraryName;
  output list<String> libraryVersions;
protected
  JSON response;
algorithm
  response := call("installedVersions", {("name", JSON.makeString(libraryName))});
  true := succeeded(response);
  libraryVersions := JSON.getStringList(JSON.get(response, "versions"));
end getInstalledLibraryVersions;

function updateIndex
  output Boolean success = succeeded(call("updateIndex"));
end updateIndex;

function upgradeInstalledPackages
  input Boolean installNewestVersions;
  input Integer wasmABI = 0;
  output Boolean success;
algorithm
  success := succeeded(call("upgrade", {("newest", JSON.makeBoolean(installNewestVersions)), ("wasmAbi", JSON.makeInteger(wasmABI))}));
end upgradeInstalledPackages;

function versionsThatProvideTheWanted
  "The versions of the index that can be used for the wanted version, best
   first, development branches last."
  input String id;
  input String version;
  input Boolean printError;
  output list<String> result;
algorithm
  result := versionsResponse("versions", id, version, printError);
end versionsThatProvideTheWanted;

function versionsThatConvertFromTheWanted
  "The versions of the index that can convert from the given version."
  input String id;
  input String version;
  input Boolean printError;
  output list<String> result;
algorithm
  result := versionsResponse("convertFrom", id, version, printError);
end versionsThatConvertFromTheWanted;

function versionsThatConvertToTheWanted
  "The versions that the given version of the index can convert from."
  input String id;
  input String version;
  input Boolean printError;
  output list<String> result;
algorithm
  result := versionsResponse("convertTo", id, version, printError);
end versionsThatConvertToTheWanted;

uniontype Requirement
  record REQUIREMENT
    String name;
    list<String> versions "To try in order; empty for any version";
    Boolean exact;
    String origin;
  end REQUIREMENT;
end Requirement;

uniontype Selection
  record SELECTION
    String name;
    String version;
    String path "Empty if not installed";
    Boolean loaded;
    String origin;
  end SELECTION;
end Selection;

uniontype ResolveMessage
  record RESOLVE_MESSAGE
    String kind "missing, incompatible, unknownVersion or branchFallback";
    String name;
    String version;
    String selected;
    String origin;
  end RESOLVE_MESSAGE;
end ResolveMessage;

function resolve
  "Chooses the versions of the required libraries and of the libraries they
   use, all together. The loaded libraries are kept. Only installed versions
   are used, unless install is set."
  input list<Requirement> requirements;
  input list<tuple<String, String>> loaded "Names and versions";
  input Boolean install;
  input Boolean exactUses;
  input String modelicaPath = Settings.getModelicaPath(Testsuite.isRunning());
  output Boolean ok;
  output list<Selection> selected = {};
  output list<ResolveMessage> messages = {};
  output String error = "";
protected
  JSON solution, entries;
  list<String> mps;
algorithm
  solution := call("resolve", {
    ("searchPath", JSON.makeString(modelicaPath)),
    ("install", JSON.makeBoolean(install)),
    ("exactUses", JSON.makeBoolean(exactUses)),
    ("requirements", JSON.makeList(list(JSON.LIST_OBJECT({
      ("origin", JSON.makeString(r.origin)),
      ("exact", JSON.makeBoolean(r.exact)),
      ("versions", JSON.makeList(list(JSON.makeString(v) for v in r.versions))),
      ("name", JSON.makeString(r.name))}) for r in requirements))),
    ("loaded", JSON.makeList(list(JSON.LIST_OBJECT({
      ("version", JSON.makeString(Util.tuple22(l))),
      ("name", JSON.makeString(Util.tuple21(l)))}) for l in loaded)))});
  ok := succeeded(solution);
  if not ok then
    error := stringOrEmpty(JSON.getOrDefault(solution, "error", JSON.makeNull()));
    return;
  end if;
  mps := JSON.getStringList(JSON.get(solution, "modelicaPath"));
  entries := JSON.get(solution, "selected");
  for i in JSON.size(entries):-1:1 loop
    selected := selectionFromJSON(JSON.at(entries, i), mps) :: selected;
  end for;
  entries := JSON.get(solution, "resolveMessages");
  for i in JSON.size(entries):-1:1 loop
    messages := messageFromJSON(JSON.at(entries, i)) :: messages;
  end for;
end resolve;

function installPackage
  input String pkg;
  input String version;
  input Boolean exactMatch;
  input Boolean skipDownload = false;
  input Integer wasmABI = 0 "Also install the prebuilt wasm external \"C\" modules of this ABI, if the index has any";
  output Boolean success;
  output list<String> wasmDirs "The libraries prebuilt wasm modules were unpacked into";
protected
  JSON response;
algorithm
  response := call("installPackage", {
    ("pkg", JSON.makeString(pkg)),
    ("version", JSON.makeString(version)),
    ("exactMatch", JSON.makeBoolean(exactMatch)),
    ("skipDownload", JSON.makeBoolean(skipDownload)),
    ("wasmAbi", JSON.makeInteger(wasmABI))});
  success := succeeded(response);
  wasmDirs := JSON.getStringList(JSON.getOrDefault(response, "wasmDirs", JSON.emptyArray()));
end installPackage;

function installCachedPackages
  "Installs the libraries cached in the installation directory if the user's
   library directory is empty, to allow bundling libraries with omc."
algorithm
  call("installCached");
end installCachedPackages;

function installMissingWasmOfLoaded
  "Fetches the prebuilt wasm modules the index has for loaded libraries the
   package manager installed without them. `files` are the loaded top-level
   classes' files."
  input list<String> files;
  input Integer abi;
  output list<String> wasmDirs = {} "The libraries the modules were unpacked into";
protected
  JSON response;
algorithm
  if abi <= 0 then
    return;
  end if;
  response := call("missingWasmOfLoaded", {
    ("files", JSON.makeList(list(JSON.makeString(f) for f in files))),
    ("wasmAbi", JSON.makeInteger(abi))});
  wasmDirs := JSON.getStringList(JSON.getOrDefault(response, "wasmDirs", JSON.emptyArray()));
end installMissingWasmOfLoaded;

function installWasmToolchain
  "Installs the index's wasm sysroot under ~/.openmodelica/wasm32-wasip1/omc-<generation>,
   with libc++ for `cxx`, and returns its path, or \"\" if there is none."
  input Boolean cxx = false;
  output String sysroot;
algorithm
  sysroot := stringOrEmpty(JSON.getOrDefault(call("wasmToolchain", {("cxx", JSON.makeBoolean(cxx))}), "sysroot", JSON.makeNull()));
end installWasmToolchain;

protected

function call
  "Runs a package manager operation and reports its messages."
  input String op;
  input list<tuple<String, JSON>> args = {};
  output JSON response;
protected
  JSON messages;
  Boolean testsuite = Testsuite.isRunning();
algorithm
  response := JSON.parse(PackageManagerExt.call(JSON.toString(JSON.LIST_OBJECT(listAppend({
    ("op", JSON.makeString(op)),
    ("home", JSON.makeString(Settings.getHomeDir(testsuite))),
    ("installationDir", JSON.makeString(Settings.getInstallationDirectoryPath())),
    ("modelicaPath", JSON.makeString(Settings.getModelicaPath(testsuite))),
    ("groupDelimiter", JSON.makeString(Autoconf.groupDelimiter)),
    ("testsuite", JSON.makeBoolean(testsuite)),
    ("maxParallel", JSON.makeInteger(Config.noProc()))}, args)))));
  messages := JSON.getOrDefault(response, "messages", JSON.emptyArray());
  for i in 1:JSON.size(messages) loop
    report(JSON.at(messages, i));
  end for;
end call;

function succeeded
  input JSON response;
  output Boolean b;
algorithm
  b := match JSON.getOrDefault(response, "ok", JSON.makeNull())
    case JSON.TRUE() then true;
    else false;
  end match;
end succeeded;

function versionsResponse
  input String op;
  input String id;
  input String version;
  input Boolean printError;
  output list<String> result;
algorithm
  result := JSON.getStringList(JSON.getOrDefault(call(op, {
    ("name", JSON.makeString(id)),
    ("version", JSON.makeString(version)),
    ("printError", JSON.makeBoolean(printError))}), "versions", JSON.emptyArray()));
end versionsResponse;

function report
  input JSON message;
protected
  String name, file;
  list<String> tokens;
algorithm
  name := JSON.getString(JSON.get(message, "name"));
  tokens := JSON.getStringList(JSON.get(message, "tokens"));
  file := stringOrEmpty(JSON.getOrDefault(message, "file", JSON.makeNull()));
  if file == "" then
    Error.addMessage(errorMessage(name), tokens);
  else
    Error.addSourceMessage(errorMessage(name), tokens, SOURCEINFO(file, true, 0, 0, 0, 0, 0.0));
  end if;
end report;

function errorMessage
  "The Error.mo message the crate names.
   TODO: when MetaModelica is gone, Error is Rust in every omc; let the crate
   report through a trait that openmodelica_util implements, and remove this
   function, report and the messages of the JSON response."
  input String name;
  output ErrorTypes.Message message;
algorithm
  message := match name
    case "ERROR_PKG_INDEX_FAILED_DOWNLOAD" then Error.ERROR_PKG_INDEX_FAILED_DOWNLOAD;
    case "NOTIFY_PKG_INDEX_DOWNLOAD" then Error.NOTIFY_PKG_INDEX_DOWNLOAD;
    case "ERROR_PKG_INDEX_NOT_ON_PATH" then Error.ERROR_PKG_INDEX_NOT_ON_PATH;
    case "ERROR_PKG_INDEX_NOT_PARSED" then Error.ERROR_PKG_INDEX_NOT_PARSED;
    case "NOTIFY_PKG_ALREADY_INSTALLED" then Error.NOTIFY_PKG_ALREADY_INSTALLED;
    case "NOTIFY_PKG_NO_INSTALL" then Error.NOTIFY_PKG_NO_INSTALL;
    case "ERROR_PKG_INSTALL_NO_PACKAGE_MO" then Error.ERROR_PKG_INSTALL_NO_PACKAGE_MO;
    case "NOTIFY_PKG_INSTALL_DONE" then Error.NOTIFY_PKG_INSTALL_DONE;
    case "NOTIFY_PKG_UPGRADE_DONE" then Error.NOTIFY_PKG_UPGRADE_DONE;
    case "NOTIFY_INITIALIZING_USER_LIBRARIES" then Error.NOTIFY_INITIALIZING_USER_LIBRARIES;
    case "ERROR_PKG_CONFLICT" then Error.ERROR_PKG_CONFLICT;
    case "ERROR_PKG_NOT_EXACT_MATCH" then Error.ERROR_PKG_NOT_EXACT_MATCH;
    case "ERROR_PKG_NOT_FOUND_VERSION" then Error.ERROR_PKG_NOT_FOUND_VERSION;
    case "compilerWarning" then Error.COMPILER_WARNING;
    case "compilerError" then Error.COMPILER_ERROR;
    case "runtimeError" then ErrorTypes.MESSAGE(-1, ErrorTypes.SIMULATION(), ErrorTypes.ERROR(), "%s");
    else
      algorithm
        Error.addInternalError("Unknown package manager message " + name, sourceInfo());
      then ErrorTypes.MESSAGE(-1, ErrorTypes.SIMULATION(), ErrorTypes.ERROR(), "%s");
  end match;
end errorMessage;

function stringOrEmpty
  input JSON obj;
  output String str;
algorithm
  str := match obj
    case JSON.STRING() then obj.str;
    else "";
  end match;
end stringOrEmpty;

function selectionFromJSON
  input JSON obj;
  input list<String> mps;
  output Selection selection;
protected
  String path;
algorithm
  path := match (JSON.getOrDefault(obj, "modelicaPathIndex", JSON.makeNull()), JSON.getOrDefault(obj, "file", JSON.makeNull()))
    local
      Integer i;
      String file;
    case (JSON.INTEGER(i = i), JSON.STRING(str = file)) then listGet(mps, i + 1) + "/" + file;
    else stringOrEmpty(JSON.getOrDefault(obj, "path", JSON.makeNull()));
  end match;
  selection := SELECTION(
    JSON.getString(JSON.get(obj, "name")),
    JSON.getString(JSON.get(obj, "version")),
    path,
    JSON.getBoolean(JSON.get(obj, "loaded")),
    JSON.getString(JSON.get(obj, "origin")));
end selectionFromJSON;

function messageFromJSON
  input JSON obj;
  output ResolveMessage message;
algorithm
  message := RESOLVE_MESSAGE(
    JSON.getString(JSON.get(obj, "kind")),
    JSON.getString(JSON.get(obj, "name")),
    JSON.getString(JSON.get(obj, "version")),
    stringOrEmpty(JSON.get(obj, "selected")),
    JSON.getString(JSON.get(obj, "origin")));
end messageFromJSON;

annotation(__OpenModelica_Interface="script_util");
end PackageManagement;
