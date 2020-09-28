/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
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
import Curl;
import Error;
import Global;
import List;
import Settings;
import System;
import Testsuite;
import Util;
import Unzip;

public

encapsulated package AvailableLibraries
  import BaseAvlTree;
  import VersionMap;
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
    if Util.endsWith(lib, ".mo") then
      lib := Util.removeLast3Char(lib);
    end if;
    first::rest := System.strtok(lib, " ");
    ver := stringDelimitList(rest, " ");
    versions := if AvailableLibraries.hasKey(tree, first) then AvailableLibraries.get(tree, first) else VersionMap.new();
    versions := VersionMap.add(versions, SemanticVersion.parse(ver), path, conflictFunc=VersionMap.addConflictReplace);
    tree := AvailableLibraries.add(tree, first, versions, conflictFunc=AvailableLibraries.addConflictReplace);
  end for;
end getInstalledLibraries;

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
  list<JSON> providedVersions;
  String str;
algorithm
  _ := match wantedVersion
    case SemanticVersion.NONSEMVER(str) guard str == "default" or str == ""
      algorithm
        matches := true; /* Any version matches the empty */
        return;
      then fail();
    else ();
  end match;
  JSON.ARRAY(providedVersions) := provides;
  matches := false;
  for v in JSON.STRING(version)::providedVersions loop
    JSON.STRING(str) := v;
    if SemanticVersion.compare(SemanticVersion.parse(str),wantedVersion) == 0 then
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
  if not Curl.multiDownload({(url,packageIndex)}) then
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
      success := success and installPackage(pkg, SemanticVersion.toString(version), exactMatch=true);
    end for;
    if installNewestVersions then
      success := success and installPackage(pkg, "", exactMatch=false);
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
  if not listMember(userLibraries, mps) then
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

function versionsThatProvideTheWanted
  input String id;
  input String version;
  input Boolean printError;
  output list<String> result;
protected
  JSON obj, libobject, vers;
  list<String> versions;
  SemanticVersion.Version wantedVersion;
algorithm
  result := {};
  try
    obj := getPackageIndex(printError);
    libobject := JSON.get(JSON.get(obj, "libs"), id);
    (vers as JSON.OBJECT(orderedKeys=versions)) := JSON.get(libobject, "versions");
    wantedVersion := SemanticVersion.parse(version);
    result := List.map(List.sort(list((version,SemanticVersion.parse(version),getSupportLevel(JSON.get(JSON.get(vers, version),"support"))) for version guard providesExpectedVersion(version, JSON.getOrDefault(JSON.get(vers, version), "provides", JSON.ARRAY({})), wantedVersion) in versions), compareVersionsAndSupportLevel), Util.tuple31);
  else
    return;
  end try;
end versionsThatProvideTheWanted;

function installPackage
  input String pkg;
  input String version;
  input Boolean exactMatch;
  output Boolean success;
protected
  list<PackageInstallInfo> packageList, packagesToInstall;
  list<tuple<String,String>> urlPathList, urlPathListToDownload;
  String cachePath, path, destPath, destPathPkgMo, destPathPkgInfo, oldSha;
algorithm
  (success,packageList) := installPackageWork(pkg, version, exactMatch, false, {});
  packagesToInstall := list(p for p guard p.needsInstall in packageList);
  cachePath := getCachePath();

  for pack in packagesToInstall loop
    Util.createDirectoryTree(cachePath);
  end for;

  urlPathList := List.sort(list((p.urlToZipFile, cachePath + System.basename(p.urlToZipFile)) for p in packagesToInstall), compareUrlBool);
  urlPathListToDownload := list(tpl for tpl guard not System.regularFileExists(Util.tuple22(tpl)) in urlPathList);
  if not Curl.multiDownload(urlPathListToDownload) then
    fail();
  end if;

  for pack in packagesToInstall loop
    destPath := getUserLibraryPath() + pack.pkg + " " + SemanticVersion.toString(pack.version);

    System.removeDirectory(destPath);
    System.createDirectory(destPath);

    destPathPkgMo := destPath + "/package.mo";
    destPathPkgInfo := destPath + "/" + metaDataFileName;
    if Util.endsWith(pack.path, ".mo") then
      destPath := destPathPkgMo;
    end if;
    oldSha := "";
    if System.regularFileExists(destPathPkgInfo) then
      try
        oldSha := getShaOrZipfile(JSON.parseFile(destPathPkgInfo));
      else
      end try;
    end if;

    Unzip.unzipPath(cachePath + System.basename(pack.urlToZipFile), pack.path, destPath);
    if System.regularFileExists(destPathPkgMo) then
      if oldSha == "" then
        Error.addSourceMessage(Error.NOTIFY_PKG_INSTALL_DONE, {pack.sha}, makeSourceInfo(destPathPkgMo));
      else
        Error.addSourceMessage(Error.NOTIFY_PKG_UPGRADE_DONE, {pack.sha, oldSha}, makeSourceInfo(destPathPkgMo));
      end if;
    else
      Error.addMessage(Error.ERROR_PKG_INSTALL_NO_PACKAGE_MO, {cachePath + System.basename(pack.urlToZipFile), destPathPkgMo});
      System.removeDirectory(destPath);
      fail();
    end if;
    System.writeFile(destPathPkgInfo, JSON.toString(pack.json)+"\n");
  end for;
end installPackage;

protected

function compareUrlBool
  input tuple<String,String> tpl1, tpl2;
  output Boolean b;
protected
  String s1, s2;
algorithm
  (s1,_) := tpl1;
  (s2,_) := tpl2;
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
  list<String> candidates, usesPackages;
  list<SemanticVersion.Version> candidatesSemver, exactMatches;
  String versionToInstall, usedVersion, path, sha, jsonPath;
  SemanticVersion.Version semverToInstall, semver;
  JSON index, versionObj, versionsObj, usesObj;
  Boolean indexHasPkg;
  PackageInstallInfo packageToInstall;
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
      success := false;
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
        sha := JSON.getString(JSON.get(JSON.parseFile(jsonPath), "sha"));
      end if;
      packageToInstall := PKG_INSTALL_INFO(false, pkg, semverToInstall, "", "", sha, JSON.emptyObject());
      indexHasPkg := JSON.hasKey(JSON.get(index, "libs"), pkg);
    end if;
  end if;

  if not success then
    if listEmpty(candidates) then
      Error.addSourceMessage(Error.ERROR_PKG_NOT_FOUND_VERSION, {pkg, version}, makeSourceInfo(getIndexPath()));
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
    packagesToInstall := packageToInstall :: packagesToInstall;
    return;
  end if;

  versionsObj := JSON.get(JSON.get(JSON.get(index, "libs"), pkg), "versions");
  if success and not JSON.hasKey(versionsObj, versionToInstall) then
    packagesToInstall := packageToInstall :: packagesToInstall;
    return;
  end if;
  versionObj := JSON.get(versionsObj, versionToInstall);

  if (not success) or (sha <> "" and sha <> getShaOrZipfile(versionObj)) then
    success := true;
    packageToInstall := PKG_INSTALL_INFO(true, pkg, semverToInstall, JSON.getString(JSON.get(versionObj, "zipfile")), JSON.getString(JSON.get(versionObj, "path")), getShaOrZipfile(versionObj), versionObj);
  end if;

  (usesObj as JSON.OBJECT(orderedKeys=usesPackages)) := JSON.getOrDefault(versionObj, "uses", JSON.emptyObject());

  packagesToInstall := packageToInstall :: packagesToInstall;

  for usesPackage in usesPackages loop
    JSON.STRING(usedVersion) := JSON.get(usesObj, usesPackage);
    (success, packagesToInstall) := installPackageWork(usesPackage, usedVersion, exactMatch, true, packagesToInstall);
    if not success then
      return;
    end if;
  end for;
end installPackageWork;

function getShaOrZipfile
  input JSON obj;
  output String res;
algorithm
  res := if JSON.hasKey(obj, "sha") then JSON.getString(JSON.get(obj, "sha")) else System.basename(JSON.getString(JSON.get(obj, "zipfile")));
end getShaOrZipfile;

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

function getCachePath
  output String path;
algorithm
  path := Settings.getHomeDir(Testsuite.isRunning()) + "/.openmodelica/cache/";
end getCachePath;

protected

function makeSourceInfo
  input String fileName;
  output SourceInfo info;
algorithm
  info := SOURCEINFO(fileName, true, 0, 0, 0, 0, 0.0);
end makeSourceInfo;

annotation(__OpenModelica_Interface="frontend");
end PackageManagement;
