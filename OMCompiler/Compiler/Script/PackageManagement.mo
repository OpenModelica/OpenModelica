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

import BaseAvlTree;
import JSON;
import SemanticVersion;

protected

import Autoconf;
import AvlSetString;
import Curl;
import Error;
import Global;
import List;
import Settings;
import StringUtil;
import System;
import Testsuite;
import Util;
import Unzip;

public

encapsulated package AvailableLibraries
  import BaseAvlTree;
  import PackageManagement.VersionMap;
  extends BaseAvlTree;
  redeclare type Key = String;
  redeclare type Value = PackageManagement.VersionMap.Tree;
  redeclare function extends keyStr
  algorithm
    outString := inKey;
  end keyStr;
  redeclare function extends valueStr
  algorithm
    outString := PackageManagement.VersionMap.printTreeStr(inValue);
  end valueStr;
  redeclare function extends keyCompare
  algorithm
    outResult := stringCompare(inKey1, inKey2);
  end keyCompare;
end AvailableLibraries;

encapsulated package VersionMap
  import BaseAvlTree;
  import SemanticVersion;
  extends BaseAvlTree;
  redeclare type Key = SemanticVersion.Version;
  redeclare type Value = String;
  redeclare function extends keyStr
  algorithm
    outString := SemanticVersion.toString(inKey);
  end keyStr;
  redeclare function extends valueStr
  algorithm
    outString := inValue;
  end valueStr;
  redeclare function extends keyCompare
  algorithm
    outResult := SemanticVersion.compare(inKey1, inKey2, compareBuildInformation=true);
  end keyCompare;
end VersionMap;

constant String metaDataFileName = "openmodelica.metadata.json";

function getInstalledLibraries
  output AvailableLibraries.Tree tree;
protected
  String mp, gd, first, ver, lib;
  list<String> mps, files, dirs, rest;
  VersionMap.Tree versions;
algorithm
  mp := Settings.getModelicaPath(Testsuite.isRunning());
  gd := Autoconf.groupDelimiter;
  mps := System.strtok(mp, gd);
  tree := AvailableLibraries.new();
  files := {};
  dirs := {};
  for mp in mps loop
    files := listAppend(list(mp + "/" + file for file in System.moFiles(mp)), files);
    dirs := listAppend(list(mp + "/" + dir for dir in getLibrarySubdirectories(mp)), dirs);
  end for;
  for path in listAppend(files, dirs) loop
    lib := System.basename(path);
    if StringUtil.endsWith(lib, ".mo") then
      lib := Util.removeLast3Char(lib);
    end if;
    first::rest := System.strtok(lib, " ");
    ver := stringDelimitList(rest, " ");
    versions := if AvailableLibraries.hasKey(tree, first) then AvailableLibraries.get(tree, first) else VersionMap.new();
    versions := VersionMap.add(versions, SemanticVersion.parse(ver), path, conflictFunc=VersionMap.addConflictReplace);
    tree := AvailableLibraries.add(tree, first, versions, conflictFunc=AvailableLibraries.addConflictReplace);
  end for;
end getInstalledLibraries;

function getInstalledLibraryVersions
  input String libraryName;
  output list<String> libraryVersions = {};
protected
  AvailableLibraries.Tree tree;
  VersionMap.Tree versionTree;
  list<SemanticVersion.Version> versions = {};
  String versionStr;
algorithm
  tree := getInstalledLibraries();
  versionTree := AvailableLibraries.get(tree, libraryName);
  versions := VersionMap.listKeys(versionTree);
  for version in versions loop
    versionStr := VersionMap.keyStr(version);
    if (stringCompare(versionStr, "") > 0) then
      libraryVersions := versionStr::libraryVersions;
    end if;
  end for;
end getInstalledLibraryVersions;

function getLibrarySubdirectories "This function returns a list of subdirectories that contain a package.mo file."
  input String inPath;
  output list<String> outSubdirectories = {};
protected
  list<String> allSubdirectories = System.subDirectories(inPath);
  String pd = Autoconf.pathDelimiter;
algorithm
  for dir in allSubdirectories loop
    if System.regularFileExists(inPath + pd + dir + pd + "package.mo") then
      outSubdirectories := dir::outSubdirectories;
    end if;
  end for;
end getLibrarySubdirectories;

function providesExpectedVersion
  input String version;
  input JSON provides;
  input SemanticVersion.Version wantedVersion;
  output Boolean matches;
protected
  list<String> providedVersions;
  String str;
  SemanticVersion.Version thisVersion;
algorithm
  () := match wantedVersion
    case SemanticVersion.NONSEMVER(str) guard str == "default" or str == ""
      algorithm
        matches := true; /* Any version matches the empty */
        return;
      then fail();
    case SemanticVersion.SEMVER(major=0, minor=0, patch=0, prerelease={"default"})
      algorithm
        matches := true; /* Any version matches the empty */
        return;
      then fail();
    else ();
  end match;
  providedVersions := JSON.getStringList(provides);
  matches := false;
  for v in version::providedVersions loop
    thisVersion := SemanticVersion.parse(v, nonsemverAsZeroZeroZero=true);
    if SemanticVersion.compare(thisVersion,wantedVersion,comparePrerelease=SemanticVersion.isPrerelease(wantedVersion) and SemanticVersion.isPrerelease(wantedVersion)) == 0 then
      matches := true;
      return;
    end if;
  end for;
end providesExpectedVersion;

constant list<String> supportLevels = {"fullSupport", "support", "experimental", "obsolete", "unknown", "noSupport"};
type SupportLevel = enumeration(noSupport, unknown, obsolete, experimental, support, fullSupport);

function getSupportLevel
  input JSON obj;
  output SupportLevel support;
algorithm
  support := match obj
    case JSON.STRING("fullSupport") then SupportLevel.fullSupport;
    case JSON.STRING("support") then SupportLevel.support;
    case JSON.STRING("experimental") then SupportLevel.experimental;
    case JSON.STRING("obsolete") then SupportLevel.obsolete;
    case JSON.STRING("unknown") then SupportLevel.unknown;
    case JSON.STRING("noSupport") then SupportLevel.noSupport;
    else
      algorithm
        Error.addInternalError("Unknown support level " + JSON.toString(obj), sourceInfo());
      then fail();
  end match;
end getSupportLevel;

function compareVersionsAndSupportLevel
  input tuple<String,SemanticVersion.Version,SupportLevel> x1, x2;
  output Boolean c;
protected
  SupportLevel s1, s2;
  SemanticVersion.Version v1, v2;
algorithm
  (_, v1, s1) := x1;
  (_, v2, s2) := x2;
  if s1 < s2 then
    c := true;
    return;
  elseif s1 > s2 then
    c := false;
    return;
  end if;
  if SemanticVersion.isPrerelease(v1) <> SemanticVersion.isPrerelease(v2) then
    c := SemanticVersion.isPrerelease(v2);
    return;
  end if;
  c := SemanticVersion.compare(v1, v2, compareBuildInformation=true) < 0;
end compareVersionsAndSupportLevel;

function updateIndex
  output Boolean success;
protected
  String userLibraries, packageIndex;
  constant String url = "https://libraries.openmodelica.org/index/v1/index.json";
algorithm
  userLibraries := getUserLibraryPath();
  Util.createDirectoryTree(userLibraries);
  packageIndex := userLibraries + "index.json";
  if not Curl.multiDownload({({url},packageIndex)}) then
    Error.addMessage(Error.ERROR_PKG_INDEX_FAILED_DOWNLOAD, {url,packageIndex});
    success := false;
  else
    Error.addSourceMessage(Error.NOTIFY_PKG_INDEX_DOWNLOAD, {url}, makeSourceInfo(getIndexPath()));
    success := true;
  end if;
  setGlobalRoot(Global.packageIndexCacheIndex, 0);
end updateIndex;

function upgradeInstalledPackages
  input Boolean installNewestVersions;
  input Integer wasmABI = 0;
  output Boolean success;
protected
  AvailableLibraries.Tree installedLibraries;
  VersionMap.Tree versions;
algorithm
  success := true;
  installedLibraries := getInstalledLibraries();
  for pkg in AvailableLibraries.listKeys(installedLibraries) loop
    versions := AvailableLibraries.get(installedLibraries, pkg);
    for version in VersionMap.listKeys(versions) loop
      success := success and installPackage(pkg, SemanticVersion.toString(version), exactMatch=true, wasmABI=wasmABI);
    end for;
    if installNewestVersions then
      success := success and installPackage(pkg, "", exactMatch=false, wasmABI=wasmABI);
    end if;
  end for;
end upgradeInstalledPackages;

function getPackageIndex
  input Boolean printError;
  output JSON obj;
protected
  String userLibraries, packageIndex, gd, mp;
  list<String> mps;
algorithm
  try
    obj := getGlobalRoot(Global.packageIndexCacheIndex);
    return;
  else
  end try;
  mp := Settings.getModelicaPath(Testsuite.isRunning());
  gd := Autoconf.groupDelimiter;
  mps := System.strtok(mp, gd);
  userLibraries := getUserLibraryPath();
  packageIndex := userLibraries + "index.json";
  obj := JSON.emptyObject();
  // User library path ends with forward slash so compare the path with and without leading forward slash
  if not listMember(userLibraries, mps) and not listMember(Util.removeLastNChar(userLibraries, 1), mps) then
    if printError then
      Error.addMessage(Error.ERROR_PKG_INDEX_NOT_ON_PATH, {mp, userLibraries});
    end if;
    return;
  end if;

  if not System.regularFileExists(packageIndex) then
    if not updateIndex() then
      return;
    end if;
  end if;
  try
    obj := JSON.parseFile(packageIndex);
    setGlobalRoot(Global.packageIndexCacheIndex, obj);
  else
    Error.addSourceMessage(Error.ERROR_PKG_INDEX_NOT_PARSED, {packageIndex}, makeSourceInfo(getIndexPath()));
  end try;
end getPackageIndex;

function getAllProvidedVersionsForLibrary
  input String lib;
  input Boolean printError;
  output list<String> result;
protected
  JSON obj, libobject, vers, provides;
  AvlSetString.Tree tree;
algorithm
  result := {};
  tree := AvlSetString.new();
  try
    obj := getPackageIndex(printError);
    libobject := JSON.get(JSON.get(obj, "libs"), lib);
    vers := JSON.get(libobject, "versions");

    for version in JSON.getKeys(vers) loop
      tree := AvlSetString.add(tree, version);
      provides := JSON.getOrDefault(JSON.get(vers, version), "provides", JSON.emptyArray());

      for i in 1:JSON.size(provides) loop
        tree := AvlSetString.add(tree, JSON.getString(JSON.at(provides, i)));
      end for;
    end for;

    result := AvlSetString.listKeys(tree);
  else
    return;
  end try;
end getAllProvidedVersionsForLibrary;

function versionsThatProvideTheWanted
  input String id;
  input String version;
  input Boolean printError;
  output list<String> result;
protected
  JSON obj, libobject, vers;
  SemanticVersion.Version wantedVersion;
algorithm
  result := {};
  try
    obj := getPackageIndex(printError);
    libobject := JSON.get(JSON.get(obj, "libs"), id);
    vers := JSON.get(libobject, "versions");
    wantedVersion := SemanticVersion.parse(version, nonsemverAsZeroZeroZero=true);
    result := List.map(List.sort(list((version,SemanticVersion.parse(version, nonsemverAsZeroZeroZero=true),getSupportLevel(JSON.get(JSON.get(vers, version),"support"))) for version guard providesExpectedVersion(version, JSON.getOrDefault(JSON.get(vers, version), "provides", JSON.emptyArray()), wantedVersion) in JSON.getKeys(vers)), compareVersionsAndSupportLevel), Util.tuple31);
  else
    return;
  end try;
end versionsThatProvideTheWanted;

function versionsThatConvertFromTheWanted
  "Returns a list of versions that provide conversion from the given version of a library."
  input String id;
  input String version;
  input Boolean printError;
  output list<String> result;
protected
  JSON obj, libobject, vers;
  SemanticVersion.Version wantedVersion, convertVersion;
  JSON convertFrom;
  String versionStr;
algorithm
  result := {};
  try
    obj := getPackageIndex(printError);
    libobject := JSON.get(JSON.get(obj, "libs"), id);
    vers := JSON.get(libobject, "versions");
    wantedVersion := SemanticVersion.parse(version, nonsemverAsZeroZeroZero=true);

    for v in JSON.getKeys(vers) loop
      convertFrom := JSON.getOrDefault(JSON.get(vers, v), "convertFromVersion", JSON.emptyArray());

      for i in 1:JSON.size(convertFrom) loop
        JSON.STRING(versionStr) := JSON.at(convertFrom, i);
        convertVersion := SemanticVersion.parse(versionStr, nonsemverAsZeroZeroZero=true);

        if SemanticVersion.compare(wantedVersion, convertVersion) == 0 then
          result := v :: result;
          continue;
        end if;
      end for;
    end for;
  else
    return;
  end try;
end versionsThatConvertFromTheWanted;

function versionsThatConvertToTheWanted
  "Returns a list of versions that can be converted to the given version of a library."
  input String id;
  input String version;
  input Boolean printError;
  output list<String> result;
protected
  JSON obj, libobject, vers;
  SemanticVersion.Version wantedVersion, libVersion;
algorithm
  result := {};
  try
    obj := getPackageIndex(printError);
    libobject := JSON.get(JSON.get(obj, "libs"), id);
    vers := JSON.get(libobject, "versions");
    wantedVersion := SemanticVersion.parse(version, nonsemverAsZeroZeroZero=true);

    for v in JSON.getKeys(vers) loop
      libVersion := SemanticVersion.parse(v, nonsemverAsZeroZeroZero=true);

      if SemanticVersion.compare(wantedVersion, libVersion) == 0 then
        result := JSON.getStringList(JSON.get(JSON.get(vers, v), "convertFromVersion"));
        return;
      end if;
    end for;
  else
    return;
  end try;
end versionsThatConvertToTheWanted;

function installPackage
  input String pkg;
  input String version;
  input Boolean exactMatch;
  input Boolean skipDownload = false;
  input Integer wasmABI = 0 "Also install the prebuilt wasm external \"C\" modules of this ABI, if the index has any";
  output Boolean success;
  output list<String> wasmDirs = {} "The libraries prebuilt wasm modules were unpacked into";
protected
  list<PackageInstallInfo> packageList, packagesToInstall;
  list<tuple<list<String>,String>> urlPathList, urlPathListToDownload;
  String path, destPath, destPathPkgMo, destPathPkgInfo, oldSha, dirOfPath, expectedLocation, cachePath=getCachePath(), installCachePath=getInstallationCachePath(), curCachePath;
  list<String> mirrors;
  list<tuple<String,String>> wasmZips;
algorithm
  (success,packageList) := installPackageWork(pkg, version, exactMatch, false, {});
  for p in packageList loop
    if p.pkg == pkg and not p.needsInstall then
      if version == SemanticVersion.toString(p.version) then
        Error.addSourceMessage(Error.NOTIFY_PKG_ALREADY_INSTALLED, {pkg, SemanticVersion.toString(p.version)}, makeSourceInfo(p.path));
      else
        Error.addSourceMessage(Error.NOTIFY_PKG_NO_INSTALL, {pkg, version, SemanticVersion.toString(p.version)}, makeSourceInfo(p.path));
      end if;
    end if;
  end for;
  packagesToInstall := list(p for p guard p.needsInstall in packageList);
  if not skipDownload then
    for p in packageList loop
      if not p.needsInstall then
        if installMissingWasm(p.path, wasmExternalsZips(p.json, wasmABI), cachePath) then
          wasmDirs := p.path :: wasmDirs;
        end if;
      end if;
    end for;
  end if;

  for pack in packagesToInstall loop
    Util.createDirectoryTree(cachePath);
  end for;

  if not skipDownload then
    mirrors := getMirrors();
    urlPathList := List.sort(list((getAllUrls(p.urlToZipFile, mirrors), if System.regularFileExists(installCachePath + System.basename(p.urlToZipFile)) then installCachePath + System.basename(p.urlToZipFile) else cachePath + System.basename(p.urlToZipFile)) for p in packagesToInstall), compareUrlBool);
    urlPathList := listAppend(list(({Util.tuple21(z)}, cachePath + System.basename(Util.tuple21(z))) for z in List.flatten(list(wasmExternalsZips(p.json, wasmABI) for p in packagesToInstall))), urlPathList);
    urlPathList := List.unique(urlPathList);
    urlPathListToDownload := list(tpl for tpl guard not System.regularFileExists(Util.tuple22(tpl)) in urlPathList);
    if not Curl.multiDownload(urlPathListToDownload) then
      fail();
    end if;
  end if;

  for pack in packagesToInstall loop
    destPath := getUserLibraryPath() + pack.pkg + " " + SemanticVersion.toString(pack.version);

    System.removeDirectory(destPath);
    System.createDirectory(destPath);

    destPathPkgMo := destPath + "/package.mo";
    destPathPkgInfo := destPath + "/" + metaDataFileName;
    oldSha := "";
    if System.regularFileExists(destPathPkgInfo) then
      try
        oldSha := getShaOrZipfile(JSON.parseFile(destPathPkgInfo));
      else
      end try;
    end if;

    curCachePath := if System.regularFileExists(installCachePath + System.basename(pack.urlToZipFile)) then installCachePath else cachePath;
    if StringUtil.endsWith(pack.path, ".mo") then
      // We are not copying a full directory, so also look for Resources in the zip-file
      dirOfPath := System.dirname(pack.path);
      if pack.singleFileStructureCopyAllFiles then
        Unzip.unzipPath(curCachePath + System.basename(pack.urlToZipFile), if dirOfPath =="." then "" else dirOfPath, destPath);
        expectedLocation := destPath + "/" + System.basename(pack.path);
        if not System.rename(expectedLocation, destPathPkgMo) then
          Error.addMessage(Error.ERROR_PKG_INSTALL_NO_PACKAGE_MO, {curCachePath + System.basename(pack.urlToZipFile), expectedLocation});
          // System.removeDirectory(destPath);
          fail();
        end if;
      else
        Unzip.unzipPath(curCachePath + System.basename(pack.urlToZipFile), pack.path, destPathPkgMo);
      end if;
    else
      Unzip.unzipPath(curCachePath + System.basename(pack.urlToZipFile), pack.path, destPath);
    end if;

    if System.regularFileExists(destPathPkgMo) then
      wasmZips := list(z for z guard System.regularFileExists(cachePath + System.basename(Util.tuple21(z))) in wasmExternalsZips(pack.json, wasmABI));
      unpackWasm(destPath, wasmZips, cachePath);
      if not listEmpty(wasmZips) then
        wasmDirs := destPath :: wasmDirs;
      end if;
      if oldSha == "" then
        Error.addSourceMessage(Error.NOTIFY_PKG_INSTALL_DONE, {pack.sha}, makeSourceInfo(destPathPkgMo));
      else
        Error.addSourceMessage(Error.NOTIFY_PKG_UPGRADE_DONE, {pack.sha, oldSha}, makeSourceInfo(destPathPkgMo));
      end if;
    else
      Error.addMessage(Error.ERROR_PKG_INSTALL_NO_PACKAGE_MO, {curCachePath + System.basename(pack.urlToZipFile), destPathPkgMo});
      System.removeDirectory(destPath);
      fail();
    end if;
    System.writeFile(destPathPkgInfo, JSON.toString(pack.json)+"\n");
  end for;
end installPackage;

function installCachedPackages
  "Installs cached libraries from the installation directory if the user's
   library directory is empty or doesn't exist, to allow bundling libraries with
   the installation."
protected
  String packageIndex, homeDir;
  JSON obj, libs_obj, lib_obj, versions_obj;
  list<String> libs;
algorithm
  homeDir := Settings.getHomeDir(runningTestsuite=Testsuite.isRunning());
  if not listEmpty(System.subDirectories(getUserLibraryPath())) or homeDir=="" or homeDir=="/" then
    // Return if the user's library directory isn't empty, or if we're running
    // e.g. rtest in which case the path might not be correct but we don't care
    // and don't want any extra output.
    return;
  end if;

  // Try to fetch the package index from the installation directory.
  packageIndex := getInstallationIndexPath();

  if not System.regularFileExists(packageIndex) then
    return;
  end if;

  obj := JSON.makeNull();

  try
    obj := JSON.parseFile(packageIndex);
  else
    Error.addSourceMessage(Error.ERROR_PKG_INDEX_NOT_PARSED, {packageIndex}, makeSourceInfo(packageIndex));
  end try;

  // Fetch the names of all the libraries in the package index.
  try
    libs_obj := JSON.get(obj, "libs");
    libs := JSON.getKeys(libs_obj);
  else
    return;
  end try;

  if not listEmpty(libs) then
    Error.addSourceMessage(Error.NOTIFY_INITIALIZING_USER_LIBRARIES, {getUserLibraryPath()}, makeSourceInfo(packageIndex));
  end if;

  // Copy the index to the user library folder to avoid getting errors when
  // installing the libraries.
  if not System.regularFileExists(getIndexPath()) then
    Util.createDirectoryTree(getUserLibraryPath());
    System.copyFile(packageIndex, getIndexPath());
  end if;

  // Install each version of each library in the package index.
  for lib in libs loop
    lib_obj := JSON.get(libs_obj, lib);
    versions_obj := JSON.getOrDefault(lib_obj, "versions", JSON.emptyObject());

    for version in JSON.getKeys(versions_obj) loop
      installPackage(lib, version, true, skipDownload = true);
    end for;
  end for;

  // Try to download a new package index so the user gets an up to date one.
  updateIndex();
end installCachedPackages;

function installMissingWasmOfLoaded
  "Fetches the prebuilt wasm modules the index has for loaded libraries the
   package manager installed without them: before the wasm-jit target was used,
   or before the index had them. `files` are the loaded top-level classes' files."
  input list<String> files;
  input Integer abi;
  output list<String> wasmDirs = {} "The libraries the modules were unpacked into";
protected
  list<String> dirs;
  JSON index, installed, obj;
algorithm
  if abi <= 0 then
    return;
  end if;
  dirs := list(d for d guard System.regularFileExists(d + "/" + metaDataFileName) in list(System.dirname(f) for f in files));
  if listEmpty(dirs) then
    return;
  end if;
  index := getPackageIndex(false);
  // An index from before any wasm modules were built.
  if not JSON.hasKey(index, "systemLibraries") and not Testsuite.isRunning() then
    if updateIndex() then
      index := getPackageIndex(false);
    end if;
  end if;
  for dir in dirs loop
    try
      installed := JSON.parseFile(dir + "/" + metaDataFileName);
      obj := installedIndexEntry(index, listHead(System.strtok(System.basename(dir), " ")), SemanticVersion.parse(JSON.getString(JSON.get(installed, "version"))), getShaOrZipfile(installed));
      if installMissingWasm(dir, wasmExternalsZips(obj, abi), getCachePath()) then
        wasmDirs := dir :: wasmDirs;
      end if;
    else
    end try;
  end for;
end installMissingWasmOfLoaded;

function installWasmToolchain
  "Installs the index's wasm sysroot under ~/.openmodelica/wasm32-wasip1/omc-<generation>,
   with libc++ for `cxx`, and returns its path, or \"\" if there is none."
  input Boolean cxx = false;
  output String sysroot = "";
protected
  JSON obj;
  Integer generation;
  String dir;
algorithm
  try
    obj := JSON.get(getPackageIndex(true), "wasmToolchain");
    JSON.INTEGER(generation) := JSON.get(obj, "generation");
  else
    Error.addCompilerError("The package index has no wasm toolchain; updatePackageIndex() may fetch a newer index.");
    return;
  end try;
  dir := Settings.getHomeDir(Testsuite.isRunning()) + "/.openmodelica/wasm32-wasip1/omc-" + intString(generation) + "/sysroot";
  if not unpackToolchainPart(obj, dir, "/lib/wasm32-wasip1/libc.so") then
    return;
  end if;
  if cxx then
    try
      obj := JSON.get(obj, "cxx");
    else
      Error.addCompilerError("The package index has no libc++ for its wasm toolchain.");
      return;
    end try;
    if not unpackToolchainPart(obj, dir, "/lib/wasm32-wasip1/libc++.so") then
      return;
    end if;
  end if;
  sysroot := dir;
end installWasmToolchain;

protected

function unpackToolchainPart
  "Unpacks the zip-file `obj` names into `dir`, unless `marker` shows it is there."
  input JSON obj;
  input String dir;
  input String marker;
  output Boolean success = true;
protected
  String url, zip, cachePath = getCachePath();
algorithm
  if System.regularFileExists(dir + marker) then
    return;
  end if;
  url := JSON.getString(JSON.get(obj, "zipfile"));
  zip := cachePath + System.basename(url);
  Util.createDirectoryTree(cachePath);
  if not System.regularFileExists(zip) then
    success := Curl.multiDownload({({url}, zip)});
  end if;
  if success then
    Util.createDirectoryTree(dir);
    Unzip.unzipPath(zip, "", dir);
  end if;
end unpackToolchainPart;

function compareUrlBool
  input tuple<list<String>,String> tpl1, tpl2;
  output Boolean b;
protected
  String s1, s2;
algorithm
  (s1::_,_) := tpl1;
  (s2::_,_) := tpl2;
  b := stringCompare(s1, s2) > 0;
end compareUrlBool;

uniontype PackageInstallInfo
  record PKG_INSTALL_INFO
    Boolean needsInstall;
    String pkg;
    SemanticVersion.Version version;
    String urlToZipFile;
    String path;
    String sha;
    Boolean singleFileStructureCopyAllFiles;
    JSON json;
  end PKG_INSTALL_INFO;
end PackageInstallInfo;

function installPackageWork
  input String pkg;
  input String version;
  input Boolean exactMatch;
  input Boolean fallbackOnNonExactMatch;
  output Boolean success;
  input output list<PackageInstallInfo> packagesToInstall;
protected
  AvailableLibraries.Tree installedLibraries;
  VersionMap.Tree installedVersions;
  list<String> candidates;
  list<SemanticVersion.Version> candidatesSemver, exactMatches;
  String versionToInstall, usedVersion, path, sha, jsonPath, zip;
  SemanticVersion.Version semverToInstall, semver;
  JSON index, versionObj, versionsObj, usesObj;
  Boolean indexHasPkg;
  Option<PackageInstallInfo> packageToInstall = NONE();
algorithm
  candidates := versionsThatProvideTheWanted(pkg, version, printError=true);
  candidatesSemver := list(SemanticVersion.parse(candidate) for candidate in candidates);
  semver := SemanticVersion.parse(version);
  exactMatches := list(candidate for candidate guard 0==SemanticVersion.compare(candidate, semver, compareBuildInformation=SemanticVersion.hasMetaInformation(semver)) in candidatesSemver);
  success := false;
  for pkgInfo in packagesToInstall loop
    if pkgInfo.pkg == pkg then
      if SemanticVersion.compare(pkgInfo.version, semver)==0 or max(0==SemanticVersion.compare(pkgInfo.version, candidate) for candidate in candidatesSemver) then
        success := true;
        return;
      end if;
      Error.addMessage(Error.WARNING_PKG_CONFLICTING_VERSIONS, {pkg, SemanticVersion.toString(pkgInfo.version), version});
      success := true;
      return;
    end if;
  end for;

  // We know which version we want now. Check with the installed ones
  installedLibraries := getInstalledLibraries();

  if listEmpty(candidates) then
    versionToInstall := version;
    semverToInstall := semver;
  elseif exactMatch and not listEmpty(exactMatches) then
    semverToInstall := listHead(exactMatches);
    versionToInstall := SemanticVersion.toString(semverToInstall);
  else
    versionToInstall := listHead(candidates);
    semverToInstall := listHead(candidatesSemver);
  end if;
  index := getPackageIndex(printError=true);
  indexHasPkg := true;
  sha := "";

  if AvailableLibraries.hasKey(installedLibraries, pkg) then
    installedVersions := AvailableLibraries.get(installedLibraries, pkg);
    if VersionMap.hasKey(installedVersions, semverToInstall) or (version=="" and not indexHasPkg) then
      success := true;
      path := if VersionMap.hasKey(installedVersions, semverToInstall) then VersionMap.get(installedVersions, semverToInstall) else "#DUMMY#";
      jsonPath := path + "/" + metaDataFileName;
      if System.regularFileExists(jsonPath) then
        versionObj := JSON.parseFile(jsonPath);
        zip := JSON.getString(JSON.get(versionObj, "zipfile"));
        try
          sha := JSON.getString(JSON.get(versionObj, "sha"));
        else
        end try;
      else
        zip := "";
      end if;
      packageToInstall := SOME(PKG_INSTALL_INFO(false, pkg, semverToInstall, zip, path, sha, false,
        installedIndexEntry(index, pkg, semverToInstall, if sha <> "" then sha else zip)));
      indexHasPkg := JSON.hasKey(JSON.get(index, "libs"), pkg);
    end if;
  end if;
  if not success then
    if listEmpty(candidates) then
      Error.addSourceMessage(Error.ERROR_PKG_NOT_FOUND_VERSION, {pkg, version, stringDelimitList(getAllProvidedVersionsForLibrary(pkg, true),"\n")}, makeSourceInfo(getIndexPath()));
      return;
    end if;

    if exactMatch and not max(0==SemanticVersion.compare(semver, candidate) for candidate in candidatesSemver) then
      if not fallbackOnNonExactMatch then
        Error.addSourceMessage(Error.ERROR_PKG_NOT_EXACT_MATCH, {pkg, version, stringDelimitList(candidates, ", ")}, makeSourceInfo(getIndexPath()));
        return;
      end if;
      versionToInstall := listHead(candidates);
      semverToInstall := listHead(candidatesSemver);
    end if;
  end if;

  if not indexHasPkg then
    packagesToInstall := Util.getOption(packageToInstall) :: packagesToInstall;
    return;
  end if;

  versionsObj := JSON.get(JSON.get(JSON.get(index, "libs"), pkg), "versions");
  if success and not JSON.hasKey(versionsObj, versionToInstall) then
    packagesToInstall := Util.getOption(packageToInstall) :: packagesToInstall;
    return;
  end if;
  versionObj := JSON.get(versionsObj, versionToInstall);

  if (not success) or (sha <> "" and sha <> getShaOrZipfile(versionObj)) then
    success := true;
    packageToInstall := SOME(PKG_INSTALL_INFO(true, pkg, semverToInstall, JSON.getString(JSON.get(versionObj, "zipfile")), JSON.getString(JSON.get(versionObj, "path")), getShaOrZipfile(versionObj), JSON.getBoolean(JSON.getOrDefault(versionObj, "singleFileStructureCopyAllFiles", JSON.FALSE())), versionObj));
  end if;

  usesObj := JSON.getOrDefault(versionObj, "uses", JSON.emptyObject());

  packagesToInstall := Util.getOption(packageToInstall) :: packagesToInstall;

  for usesPackage in JSON.getKeys(usesObj) loop
    JSON.STRING(usedVersion) := JSON.get(usesObj, usesPackage);
    (success, packagesToInstall) := installPackageWork(usesPackage, usedVersion, exactMatch, true, packagesToInstall);
    if not success then
      return;
    end if;
  end for;
end installPackageWork;

function installedIndexEntry
  "The index's entry for an installed package version, if it is still built from
   the same sources (`shaOrZip`); its prebuilt wasm modules are only good then."
  input JSON index;
  input String pkg;
  input SemanticVersion.Version version;
  input String shaOrZip;
  output JSON obj = JSON.emptyObject();
protected
  JSON o;
algorithm
  try
    o := JSON.get(JSON.get(JSON.get(JSON.get(index, "libs"), pkg), "versions"), SemanticVersion.toString(version));
    // A package installed from an index without shas only knows its zipfile.
    if shaOrZip <> "" and (getShaOrZipfile(o) == shaOrZip or JSON.hasKey(o, "zipfile") and System.basename(JSON.getString(JSON.get(o, "zipfile"))) == shaOrZip) then
      obj := o;
    end if;
  else
  end try;
end installedIndexEntry;

function installMissingWasm
  "Fetches and unpacks the prebuilt wasm modules of an installed package that it
   does not have yet: those of a newer generation, or a rebuild of one."
  input String destPath;
  input list<tuple<String,String>> zips;
  input String cachePath;
  output Boolean unpacked = false;
protected
  list<tuple<String,String>> missing;
  String lock = destPath + "/Resources/Library/wasm32-wasip1.lock";
algorithm
  missing := list(z for z guard not wasmUnpacked(destPath, z) in zips);
  if listEmpty(missing) then
    return;
  end if;
  // Another omc is unpacking them; this one goes on with what is there.
  if not wasmLock(lock) then
    return;
  end if;
  missing := list(z for z guard not wasmUnpacked(destPath, z) in zips);
  // The library's own zip unpacks into the generation directory that holds the
  // system libraries' ones, so replacing it replaces them all.
  if List.any(missing, wasmIsGenerationZip) then
    missing := zips;
  end if;
  try
    Util.createDirectoryTree(cachePath);
    if not listEmpty(missing) and Curl.multiDownload(list(({Util.tuple21(z)}, cachePath + System.basename(Util.tuple21(z))) for z guard not System.regularFileExists(cachePath + System.basename(Util.tuple21(z))) in missing)) then
      unpackWasm(destPath, missing, cachePath);
      unpacked := true;
    end if;
  else
    System.removeDirectory(lock);
    fail();
  end try;
  System.removeDirectory(lock);
end installMissingWasm;

function wasmLock
  "Takes the lock directory `lock`, unless another omc holds it. Renaming a
   non-empty directory onto an existing one fails, which makes it exclusive. A
   lock older than ten minutes was left by an omc that died and is taken over."
  input String lock;
  output Boolean locked;
protected
  String tmp;
  Option<Real> t;
algorithm
  Util.createDirectoryTree(System.dirname(lock));
  tmp := System.createTemporaryDirectory(lock + ".");
  System.writeFile(tmp + "/owner", "");
  locked := System.rename(tmp, lock);
  if not locked then
    t := System.getFileModificationTime(lock);
    if isSome(t) and System.getCurrentTime() - Util.getOption(t) > 600 then
      System.removeDirectory(lock);
      locked := System.rename(tmp, lock);
    end if;
  end if;
  if not locked then
    System.removeDirectory(tmp);
  end if;
end wasmLock;

constant String wasmZipMarker = ".omc-zipfile" "Names the zip a directory of wasm modules was unpacked from";

function wasmIsGenerationZip
  input tuple<String,String> zip;
  output Boolean b = listLength(System.strtok(Util.tuple22(zip), "/")) == 1;
end wasmIsGenerationZip;

function wasmUnpacked
  input String destPath;
  input tuple<String,String> zip;
  output Boolean b;
protected
  String marker = destPath + "/Resources/Library/wasm32-wasip1/" + Util.tuple22(zip) + "/" + wasmZipMarker;
algorithm
  b := System.regularFileExists(marker) and System.readFile(marker) == System.basename(Util.tuple21(zip));
end wasmUnpacked;

function unpackWasm
  "Unpacks zips of prebuilt wasm modules into Resources/Library/wasm32-wasip1.
   A generation's system libraries go into its tree before it is renamed into
   place, so an omc running at the same time never sees it half written."
  input String destPath;
  input list<tuple<String,String>> zips;
  input String cachePath;
protected
  String base = destPath + "/Resources/Library/wasm32-wasip1/";
  list<tuple<String,String>> gens, libs;
algorithm
  (gens, libs) := List.splitOnTrue(zips, wasmIsGenerationZip);
  for g in gens loop
    unpackWasmTree(base + Util.tuple22(g), g :: list(z for z guard System.dirname(Util.tuple22(z)) == Util.tuple22(g) in libs), cachePath);
    libs := list(z for z guard System.dirname(Util.tuple22(z)) <> Util.tuple22(g) in libs);
  end for;
  for z in libs loop
    unpackWasmTree(base + Util.tuple22(z), {z}, cachePath);
  end for;
end unpackWasm;

function unpackWasmTree
  "Replaces `dir` with the first zip's contents and each other's in a
   subdirectory named after it, built beside `dir` and renamed into place."
  input String dir;
  input list<tuple<String,String>> zips;
  input String cachePath;
protected
  String tmp, sub;
  Boolean first = true;
algorithm
  Util.createDirectoryTree(System.dirname(dir));
  tmp := System.createTemporaryDirectory(dir + ".tmp");
  for z in zips loop
    sub := if first then tmp else tmp + "/" + System.basename(Util.tuple22(z));
    first := false;
    Util.createDirectoryTree(sub);
    Unzip.unzipPath(cachePath + System.basename(Util.tuple21(z)), "", sub);
    System.writeFile(sub + "/" + wasmZipMarker, System.basename(Util.tuple21(z)));
  end for;
  System.removeDirectory(dir);
  if not System.rename(tmp, dir) then
    // Another omc put its copy in place first.
    System.removeDirectory(tmp);
  end if;
end unpackWasmTree;

function wasmExternalsZips
  "The zip-files with the prebuilt wasm external \"C\" modules of a package
   version, each with the directory under Resources/Library/wasm32-wasip1 it
   unpacks into: the library's own bundle, then the system libraries it needs,
   all under the generation they were built in. Older generations stay."
  input JSON versionObj;
  input Integer abi;
  output list<tuple<String,String>> zips = {};
protected
  JSON obj, systemLibraries;
  Integer generation;
algorithm
  if abi <= 0 then
    return;
  end if;
  try
    obj := JSON.get(JSON.get(versionObj, "wasm"), intString(abi));
    JSON.INTEGER(generation) := JSON.get(obj, "generation");
    zips := {(JSON.getString(JSON.get(obj, "zipfile")), "omc-" + intString(generation))};
  else
    return;
  end try;
  systemLibraries := JSON.getOrDefault(getPackageIndex(false), "systemLibraries", JSON.emptyObject());
  for name in JSON.getStringList(JSON.getOrDefault(obj, "systemLibraries", JSON.emptyArray())) loop
    try
      zips := (JSON.getString(JSON.get(JSON.get(JSON.get(JSON.get(systemLibraries, name), "wasm"), intString(abi)), "zipfile")), "omc-" + intString(generation) + "/" + name) :: zips;
    else
      Error.addCompilerWarning("The package index has no wasm system library " + name + " for ABI " + intString(abi) + ".");
    end try;
  end for;
  zips := listReverse(zips);
end wasmExternalsZips;

function getShaOrZipfile
  input JSON obj;
  output String res;
algorithm
  res := if JSON.hasKey(obj, "sha") then JSON.getString(JSON.get(obj, "sha")) else System.basename(JSON.getString(JSON.get(obj, "zipfile")));
end getShaOrZipfile;

function getAllUrls
  input String url;
  input list<String> mirrors;
  output list<String> urls;
protected
  String urlWithoutProtocol, newUrl;
algorithm
  urls := {url};
  if not StringUtil.startsWith(url, "https://") then
    return;
  end if;
  urlWithoutProtocol := substring(url,9,stringLength(url));
  for mirror in mirrors loop
    newUrl := if StringUtil.endsWith(mirror, "/") then (mirror + urlWithoutProtocol) else (mirror + "/" + urlWithoutProtocol);
    urls := newUrl::urls;
  end for;
end getAllUrls;

function getMirrors
  output list<String> mirrors;
protected
  JSON obj;
algorithm
  obj := getPackageIndex(false);
  if not JSON.hasKey(obj, "mirrors") then
    mirrors := {};
    return;
  end if;
  obj := JSON.get(obj, "mirrors");
  mirrors := JSON.getStringList(obj);
end getMirrors;

function getUserLibraryPath
  output String path;
algorithm
  path := Settings.getHomeDir(Testsuite.isRunning()) + "/.openmodelica/libraries/";
end getUserLibraryPath;

function getIndexPath
  output String path;
algorithm
  path := Settings.getHomeDir(Testsuite.isRunning()) + "/.openmodelica/libraries/index.json";
end getIndexPath;

public
function getCachePath
  output String path;
algorithm
  path := Settings.getHomeDir(Testsuite.isRunning()) + "/.openmodelica/cache/";
end getCachePath;

protected

function getInstallationIndexPath
  output String path;
algorithm
  path := Settings.getInstallationDirectoryPath() + "/share/omlibrary/cache/index.json";
end getInstallationIndexPath;

function getInstallationCachePath
  output String path;
algorithm
  path := Settings.getInstallationDirectoryPath() + "/share/omlibrary/cache/";
end getInstallationCachePath;

function makeSourceInfo
  input String fileName;
  output SourceInfo info;
algorithm
  info := SOURCEINFO(fileName, true, 0, 0, 0, 0, 0.0);
end makeSourceInfo;

annotation(__OpenModelica_Interface="script_util");
end PackageManagement;
