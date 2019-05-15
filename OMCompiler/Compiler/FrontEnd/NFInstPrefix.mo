/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

encapsulated package NFInstPrefix
" file:        NFInstPrefix.mo
  package:     NFInstPrefix
  description: Prefix type and utilities for NFInst.


"

public import Absyn;
public import DAE;

public uniontype Prefix
  record EMPTY_PREFIX
    Option<Absyn.Path> classPath "The path of the class the prefix originates from.";
  end EMPTY_PREFIX;

  record PREFIX
    String name;
    DAE.Dimensions dims;
    Prefix restPrefix;
  end PREFIX;
end Prefix;

public constant Prefix emptyPrefix = EMPTY_PREFIX(NONE());
public constant Prefix functionPrefix = EMPTY_PREFIX(NONE());

public function makePrefix
  "Creates a new prefix with one identifier."
  input String inName;
  input DAE.Dimensions inDims;
  output Prefix outPrefix;
algorithm
  outPrefix := PREFIX(inName, inDims, emptyPrefix);
end makePrefix;

public function makeEmptyPrefix
  "Creates a new empty prefix with the given class path."
  input Absyn.Path inClassPath;
  output Prefix outPrefix;
algorithm
  outPrefix := EMPTY_PREFIX(SOME(inClassPath));
end makeEmptyPrefix;

public function add
  "Adds a new identifier to the given prefix."
  input String inName;
  input DAE.Dimensions inDimensions;
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := PREFIX(inName, inDimensions, inPrefix);
end add;

public function addPath
  "Prefixes the prefix with the given path."
  input Absyn.Path inPath;
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := fromPath2(inPath, inPrefix);
end addPath;

public function addOptPath
  input Option<Absyn.Path> inOptPath;
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := match(inOptPath, inPrefix)
    local
      Absyn.Path p;

    case (NONE(), _) then inPrefix;
    case (SOME(p), _) then addPath(p, inPrefix);

  end match;
end addOptPath;

public function addString
  "Prefixes the prefix with the given String."
  input String inName;
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := PREFIX(inName, {}, inPrefix);
end addString;

public function addStringList
  "Prefixes the prefix with the given list of strings."
  input list<String> inStrings;
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := fromStringList2(inStrings, inPrefix);
end addStringList;

public function restPrefix
  "Discards the head of a prefix and returns the rest."
  input Prefix inPrefix;
  output Prefix outRestPrefix;
algorithm
  PREFIX(restPrefix = outRestPrefix) := inPrefix;
end restPrefix;

public function firstName
  "Returns the name of the first scope of the prefix, or an empty string if the
   prefix is empty."
  input Prefix inPrefix;
  output String outStr;
algorithm
  outStr := match(inPrefix)
    local
      String name, str;
      Prefix rest_prefix;
      Absyn.Path path;

    case EMPTY_PREFIX() then "";
    case PREFIX(name = name) then name;

  end match;
end firstName;

public function prefixCref
  "Applies a prefix to a cref."
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref, inPrefix)
    local
      String name;
      Prefix rest_prefix;
      DAE.ComponentRef cref;

    case (_, EMPTY_PREFIX()) then inCref;

    case (_, PREFIX(name = name, restPrefix = rest_prefix))
      equation
        cref = DAE.CREF_QUAL(name, DAE.T_UNKNOWN_DEFAULT, {}, inCref);
      then
        prefixCref(cref, rest_prefix);

  end match;
end prefixCref;

public function prefixPath
  "Applies a prefix to a path."
  input Absyn.Path inPath;
  input Prefix inPrefix;
  output Absyn.Path outPath;
algorithm
  outPath := match(inPath, inPrefix)
    local
      String name;
      Prefix rest_prefix;
      Absyn.Path path;

    case (_, EMPTY_PREFIX()) then inPath;

    case (_, PREFIX(name = name, restPrefix = rest_prefix))
      equation
        path = Absyn.QUALIFIED(name, inPath);
      then
        prefixPath(path, rest_prefix);

  end match;
end prefixPath;

public function prefixStr
  "Applies a prefix to a string, using dot-notation."
  input String inString;
  input Prefix inPrefix;
  output String outString;
algorithm
  outString := match(inString, inPrefix)
    local
      String str;

    case (_, EMPTY_PREFIX()) then inString;

    else
      equation
        str = toStr(inPrefix);
        str = str + "." + inString;
      then
        str;

  end match;
end prefixStr;

public function toCref
  "Converts a prefix to an untyped DAE.ComponentRef."
  input Prefix inPrefix;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inPrefix)
    local
      String name;
      Prefix rest_prefix;
      DAE.ComponentRef cref;

    case (PREFIX(name = name, restPrefix = EMPTY_PREFIX()))
      then
        DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, {});

    case (PREFIX(name = name, restPrefix = rest_prefix))
      equation
        cref = DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, {});
      then
        prefixCref(cref, rest_prefix);

  end match;
end toCref;

public function toPath
  "Converts a prefix to a path."
  input Prefix inPrefix;
  output Absyn.Path outPath;
algorithm
  outPath := match(inPrefix)
    local
      String name;
      Prefix rest_prefix;
      Absyn.Path path;

    case PREFIX(name = name, restPrefix = EMPTY_PREFIX())
      then Absyn.IDENT(name);

    case PREFIX(name = name, restPrefix = rest_prefix)
      equation
        path = Absyn.IDENT(name);
      then
        prefixPath(path, rest_prefix);

  end match;
end toPath;

public function fromPath
  "Converts a path to a prefix."
  input Absyn.Path inPath;
  output Prefix outPrefix;
algorithm
  outPrefix := fromPath2(inPath, emptyPrefix);
end fromPath;

protected function fromPath2
  "Helper function to fromPath."
  input Absyn.Path inPath;
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := match(inPath, inPrefix)
    local
      Absyn.Path path;
      String name;

    case (Absyn.QUALIFIED(name, path), _)
      then fromPath2(path, PREFIX(name, {}, inPrefix));

    case (Absyn.IDENT(name), _)
      then PREFIX(name, {}, inPrefix);

    case (Absyn.FULLYQUALIFIED(path), _)
      then fromPath2(path, inPrefix);

  end match;
end fromPath2;

public function fromStringList
  "Converts a list of strings to a prefix."
  input list<String> inStrings;
  output Prefix outPrefix;
algorithm
  outPrefix := fromStringList2(inStrings, emptyPrefix);
end fromStringList;

protected function fromStringList2
  "Helper function to fromStringList."
  input list<String> inStrings;
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := match(inStrings, inPrefix)
    local
      list<String> strl;
      String str;

    case (str :: strl, _) then fromStringList2(strl, PREFIX(str, {}, inPrefix));
    else inPrefix;

  end match;
end fromStringList2;

public function toStr
  "Converts a prefix to a string using dot-notation."
  input Prefix inPrefix;
  output String outStr;
algorithm
  outStr := match(inPrefix)
    local
      String name, str;
      Prefix rest_prefix;

    case EMPTY_PREFIX() then "";

    case PREFIX(name = name, restPrefix = EMPTY_PREFIX())
      then name;

    case PREFIX(name = name, restPrefix = rest_prefix)
      equation
        str = toStr(rest_prefix) + "." + name;
      then
        str;

  end match;
end toStr;

public function toStrWithEmpty
  "Converts a prefix to a string using dot-notation, and also prints out the
   class path of the empty prefix (for e.g. debugging)."
  input Prefix inPrefix;
  output String outStr;
algorithm
  outStr := match(inPrefix)
    local
      String name, str;
      Prefix rest_prefix;
      Absyn.Path path;

    case EMPTY_PREFIX(classPath = NONE()) then "E()";

    case EMPTY_PREFIX(classPath = SOME(path))
      equation
        str = "E(" + Absyn.pathLastIdent(path) + ")";
      then
        str;

    case PREFIX(name = name, restPrefix = rest_prefix)
      equation
        str = toStrWithEmpty(rest_prefix) + "." + name;
      then
        str;

  end match;
end toStrWithEmpty;

public function isPackagePrefix
  "Returns true if the prefix is a package prefix, i.e. a prefix without an
   associated class path."
  input Prefix inPrefix;
  output Boolean outIsPackagePrefix;
algorithm
  outIsPackagePrefix := match(inPrefix)
    local
      Prefix prefix;

    case PREFIX(restPrefix = prefix) then isPackagePrefix(prefix);
    case EMPTY_PREFIX(classPath = NONE()) then true;
    else false;
  end match;
end isPackagePrefix;

public function toPackagePrefix
  "Converts a prefix to a package prefix, i.e. strips it's associated class path."
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := match(inPrefix)
    local
      String name;
      DAE.Dimensions dims;
      Prefix rest_prefix;

    case PREFIX(name, dims, rest_prefix)
      equation
        rest_prefix = toPackagePrefix(rest_prefix);
      then
        PREFIX(name, dims, rest_prefix);

    case EMPTY_PREFIX() then EMPTY_PREFIX(NONE());

  end match;
end toPackagePrefix;

annotation(__OpenModelica_Interface="frontend");
end NFInstPrefix;
