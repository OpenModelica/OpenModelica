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

encapsulated package SemanticVersion

protected

import Util;
import System;

public

uniontype Version
record SEMVER
  Integer major, minor, patch;
  list<String> prerelease, meta;
end SEMVER;
record NONSEMVER
  String version;
end NONSEMVER;
end Version;

function parse
  input String s;
  output Version v;
protected
  Integer n;
  String major, minor, patch, prerelease, meta, nextString, versions;
  list<String> prereleaseLst, metaLst, matches, split, versionsLst;
  constant String semverRegex = "^([0-9][0-9]*\\.?[0-9]*\\.?[0-9]*)([+-][0-9A-Za-z.-]*)?$";
algorithm
  (n, matches) := System.regex(s, semverRegex, maxMatches=5, extended=true);
  if n < 2 then
    v := NONSEMVER(s);
    return;
  end if;
  // OSX regex cannot handle everything in the same regex, so we have manual splitting of prerelease and meta strings

  _::versions::split := matches;
  versionsLst := Util.stringSplitAtChar(versions, ".");
  major::versionsLst := versionsLst;
  if not listEmpty(versionsLst) then
    minor::versionsLst := versionsLst;
  else
    minor := "0";
  end if;
  if not listEmpty(versionsLst) then
    patch::versionsLst := versionsLst;
  else
    patch := "0";
  end if;

  nextString := if listEmpty(split) then "" else listGet(split, 1);
  if stringEmpty(nextString) then
    prerelease := "";
    meta := "";
  elseif stringGetStringChar(nextString, 1) == "+" then
    prerelease := "";
    meta := nextString;
  else
    split := Util.stringSplitAtChar(nextString, "+");
    prerelease::split := split;
    meta := if listEmpty(split) then "" else listGet(split, 1);
  end if;
  prereleaseLst := if stringLength(prerelease) > 0 then Util.stringSplitAtChar(Util.stringRest(prerelease), ".") else {};
  metaLst := if stringLength(meta) > 0 then Util.stringSplitAtChar(Util.stringRest(meta), ".") else {};
  v := SEMVER(stringInt(major),stringInt(minor),stringInt(patch),prereleaseLst,metaLst);
end parse;

function compare
  input Version v1, v2;
  input Boolean comparePrerelease = true;
  input Boolean compareBuildInformation = false;
  output Integer c;
algorithm
  c := match (v1, v2)
    case (NONSEMVER(),NONSEMVER()) then stringCompare(v1.version, v2.version);
    case (NONSEMVER(),_) then -1;
    case (_,NONSEMVER()) then 1;
    case (SEMVER(),SEMVER())
      algorithm
        c := Util.intCompare(v1.major, v2.major);
        if c <> 0 then
          return;
        end if;
        c := Util.intCompare(v1.minor, v2.minor);
        if c <> 0 then
          return;
        end if;
        c := Util.intCompare(v1.patch, v2.patch);
        if c <> 0 then
          return;
        end if;

        c := compareIdentifierList(v1.prerelease, v2.prerelease);
        if c == 0 and compareBuildInformation then
          c := compareIdentifierList(v1.meta, v2.meta);
        end if;
      then c;
  end match;
end compare;

function toString
  input Version v;
  output String out;
algorithm
  out := match v
    case SEMVER()
      algorithm
        out := String(v.major) + "." + String(v.minor) + "." + String(v.patch);
        if not listEmpty(v.prerelease) then
          out := out + "-" + stringDelimitList(v.prerelease, ".");
        end if;
        if not listEmpty(v.meta) then
          out := out + "+" + stringDelimitList(v.meta, ".");
        end if;
      then out;
    case NONSEMVER() then v.version;
  end match;
end toString;

function isPrerelease
  input Version v;
  output Boolean b;
algorithm
  b := match v
    case SEMVER(prerelease=_::_) then true;
    else false;
  end match;
end isPrerelease;

function hasMetaInformation
  input Version v;
  output Boolean b;
algorithm
  b := match v
    case SEMVER(meta={}) then false;
    case NONSEMVER() then false;
    else true;
  end match;
end hasMetaInformation;

function isSemVer
  input Version v;
  output Boolean b;
algorithm
  b := match v
    case NONSEMVER() then false;
    else true;
  end match;
end isSemVer;

protected

function compareIdentifierList
  input list<String> w1, w2;
  output Integer c;
protected
  list<String> l1, l2;
  String s1, s2;
algorithm
  l1 := w1;
  l2 := w2;
  if listEmpty(l1) and not listEmpty(l2) then
    c := 1;
  end if;
  if listEmpty(l2) and not listEmpty(l1) then
    c := -1;
  end if;
  while not (listEmpty(l1) and listEmpty(l2)) loop
    (c, l1, l2) := match (l1, l2)
      case ({},_::_) then (-1, l1, l2);
      case (_::_,{}) then (1, l1, l2);
      case (s1::l1, s2::l2) then (compareIdentifier(s1, s2), l1, l2);
    end match;
    if c <> 0 then
      return;
    end if;
  end while;
  c := 0;
end compareIdentifierList;

function compareIdentifier
  input String s1, s2;
  output Integer c;
algorithm
  if Util.isIntegerString(s1) then
    c := if Util.isIntegerString(s2) then Util.intCompare(stringInt(s1), stringInt(s2)) else -1;
    return;
  end if;
  if Util.isIntegerString(s2) then
    c := 1;
  end if;
  c := stringCompare(s1, s2);
end compareIdentifier;

annotation(__OpenModelica_Interface="util");
end SemanticVersion;
