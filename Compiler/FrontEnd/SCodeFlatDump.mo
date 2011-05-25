/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package SCodeFlatDump
" file:        SCodeFlatDump.mo
  package:     SCodeFlatDump
  description: SCodeFlatDump has functionality for printing SCodeFlat

  RCS: $Id: SCodeFlatDump.mo 8980 2011-05-13 09:12:21Z perost $

  The SCodeFlatDump dumps SCodeFlat."

public import Absyn;
public import SCode;
public import SCodeEnv;
public import IOStream;
public import SCodeFlat;

protected import Util;
protected import Dump;
protected import SCodeDump;

public function outputFlatProgram
  "to standard out" 
  input SCodeFlat.FlatProgram inFlatProgram;
algorithm
  _ := matchcontinue(inFlatProgram)
    local
      IOStream.IOStream ios;

    // handle empty
    case ({}) then (); 

    case (inFlatProgram)
      equation
        ios = IOStream.create("flatProgram", IOStream.LIST());
        ios = printFlatProgramToStream(inFlatProgram, ios);
        IOStream.print(ios, IOStream.stdOutput);
      then
        ();
    
    case (_)
      equation
        print("SCodeFlatDump.outputFlatProgram: printing of flattened program failed!\n");
      then
        ();
  end matchcontinue;
end outputFlatProgram;

public function printFlatProgramToStream
  input SCodeFlat.FlatProgram inFlatProgram;
  input IOStream.IOStream inIOStream;
  output IOStream.IOStream outIOStream;
algorithm
  outIOStream := matchcontinue(inFlatProgram, inIOStream)
    local
      SCodeFlat.CompPath cp;
      SCodeFlat.FlatProgram rest;
      IOStream.IOStream oIOStream;
      String str;

    // handle empty
    case ({}, inIOStream) then inIOStream; 

    case (cp::rest, inIOStream)
      equation
        oIOStream = printCompPathToStream(listReverse(cp), inIOStream);
        oIOStream = printFlatProgramToStream(rest, oIOStream); 
      then
        oIOStream;
  end matchcontinue;
end printFlatProgramToStream;

public function printCompPathToStream
  input SCodeFlat.CompPath inCompPath;
  input IOStream.IOStream inIOStream;
  output IOStream.IOStream outIOStream;
algorithm
  outIOStream := matchcontinue(inCompPath, inIOStream)
    local
      SCodeFlat.Component c;
      SCodeFlat.CompPath rest;
      IOStream.IOStream oIOStream;
      String str;
      SCode.Ident name "the type name, for derived/extends we use the predefined constants above: extendsName and derivedName";
      SCode.Element origin "the element from which the component originates";
      SCodeFlat.Kind kind "what kind of component it is";
      SCodeFlat.TypePath ty "the full type path for this component";
    
    case (inCompPath, oIOStream)
      equation
        ty = getComponentTypePath(Util.listLast(inCompPath));
        str = Util.stringDelimitList(Util.listMap(inCompPath, getComponentName), "/"); 
        oIOStream = IOStream.appendList(oIOStream, {str, "\n    "});
        oIOStream = printTypePathToStream(listReverse(ty), oIOStream);
        oIOStream = IOStream.append(oIOStream, "\n");        
      then
        oIOStream;
  end matchcontinue;
end printCompPathToStream;

public function printTypePathToStream
  input SCodeFlat.TypePath inTypePath;
  input IOStream.IOStream inIOStream;
  output IOStream.IOStream outIOStream;
algorithm
  outIOStream := matchcontinue(inTypePath, inIOStream)
    local
      SCodeFlat.Component c;
      SCodeFlat.TypePath rest;
      IOStream.IOStream oIOStream;
      String str;
      SCode.Ident name "the type name, for derived/extends we use the predefined constants above: extendsName and derivedName";
      SCode.Element origin "the element from which the component originates";
      SCodeFlat.Kind kind "what kind of component it is";
      SCodeFlat.TypePath ty "the full type path for this component";
      SCode.Mod mod;
    
    // handle empty
    case ({}, inIOStream) then inIOStream; 
    
    // handle last
    case ({SCodeFlat.T(name = name, origin = origin, mod = mod, kind = kind)}, inIOStream)
      equation
        str = printElementStr(name, origin, mod);
        oIOStream = IOStream.appendList(inIOStream, {name, "[", str, "]"});
      then
        oIOStream;    
    
    // handle rest
    case (SCodeFlat.T(name = name, origin = origin, mod = mod, kind = kind)::rest, inIOStream)
      equation
        str = printElementStr(name, origin, mod);
        oIOStream = IOStream.appendList(inIOStream, {name, "[", str, "]/"});
        oIOStream = printTypePathToStream(rest, oIOStream);
      then
        oIOStream;
  end matchcontinue;
end printTypePathToStream;

public function getComponentName
  input SCodeFlat.Component inComponent;
  output SCode.Ident outName;
algorithm
  SCodeFlat.C(name = outName) := inComponent;
end getComponentName;

public function getComponentTypePath
  input SCodeFlat.Component inComponent;
  output SCodeFlat.TypePath outTypePath;
algorithm
  SCodeFlat.C(ty = outTypePath) := inComponent;
end getComponentTypePath;

public function printElementStr
"function: printElementStr
  Print SCode.Element to a string depending on the type of the name"
  input SCode.Ident    inName;
  input SCode.Element inElement;
  input SCode.Mod     inMod;
  output String outString;
algorithm
  outString := matchcontinue (inName, inElement, inMod)
    local
      String n, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, res;
      Absyn.TypeSpec typath;
      SCode.Mod mod;
      SCode.Element cl;
      SCode.Variability var;
      Option<SCode.Comment> comment;
      Absyn.Path path;
      Absyn.Import imp;
      Absyn.InnerOuter io;
      SCode.Redeclare red;
      SCode.Replaceable rep;
      SCode.Visibility vis;
      Absyn.ArrayDim ad;
      Absyn.Direction direction;
      SCode.Final fin;
      SCode.Flow fp;
      SCode.Stream sp;
      SCode.Accessibility acc;
      Option<Absyn.Exp> cond;
      SCode.Partial pp;
      SCode.Encapsulated ep;
      SCode.Restriction r;

    case (_, SCode.EXTENDS(baseClassPath = path,modifications = mod, visibility = vis), _)
      equation
        s1 = visibilityStr(vis);
        s2 = Absyn.pathString(path);
        s3 = SCodeDump.printModStr(mod);
        res = stringAppendList({s1, "|", s2, s3});
      then
        res;

    case (_, SCode.COMPONENT(name = n,
                             prefixes = SCode.PREFIXES(vis, red, fin, io, rep),
                             attributes = SCode.ATTR(ad, fp, sp, acc, var, direction),
                             typeSpec = typath,
                             modifications = mod,
                             condition = cond), _)
      equation
        s1 = visibilityStr(vis) +& redeclareStr(red) +& finalStr(fin) +& ioStr(io) +& replaceableStr(rep);
        s2 = flowStr(fp) +& streamStr(sp) +& variabilityStr(var) +& directionStr(direction);    
        s3 = Dump.unparseTypeSpec(typath) +& Dump.printArraydimStr(ad) +& SCodeDump.printModStr(mod);
        s4 = Dump.unparseComponentCondition(cond);  
        res = stringAppendList({s1, "|", s2, "|", s3, s4});
      then
        res;

    // derived
    case (inName, SCode.CLASS(classDef = SCode.DERIVED(typeSpec = typath, modifications = mod, attributes = SCode.ATTR(ad, fp, sp, acc, var, direction))), _)
      equation
        true = stringEq(inName, SCodeFlat.derivedName);
        s1 = flowStr(fp) +& streamStr(sp) +& variabilityStr(var) +& directionStr(direction);
        s2 = Dump.unparseTypeSpec(typath) +& Dump.printArraydimStr(ad) +& SCodeDump.printModStr(mod);
        res = stringAppendList({s1, "|", s2});
      then
        res;

    // class extends
    case (inName, SCode.CLASS(classDef = SCode.CLASS_EXTENDS(n, modifications = mod)), _)
      equation
        true = stringEq(inName, SCodeFlat.classExName);
        s1 = SCodeDump.printModStr(mod);
        res = stringAppendList({n, s1});
      then
        res;

    // normal class
    case (_, SCode.CLASS(prefixes = SCode.PREFIXES(vis, red, fin, io, rep), 
                         encapsulatedPrefix = ep, 
                         partialPrefix = pp, 
                         restriction = r), _)
      equation
        s1 = visibilityStr(vis) +& redeclareStr(red) +& finalStr(fin) +& ioStr(io) +& replaceableStr(rep);
        s2 = encapsulatedStr(ep) +& partialStr(pp);
        s3 = restrictionStr(r);
        res = stringAppendList({s1, "|", s2, "|", s3});
      then
        res;

    // import, we shouldn't have any!
    case (_, SCode.IMPORT(imp = imp, visibility = vis), _)
      equation
        s1 = visibilityStr(vis);
        s2 = Dump.unparseImportStr(imp);
        res = stringAppendList({s1, "|imp:", s2});
      then 
        res;
        
    // other?
    case (_, SCode.DEFINEUNIT(n, vis, _, _), _)
      equation
        s1 = visibilityStr(vis);
        res = stringAppendList({s1, "|", n});
      then 
        res;
        
    // other?
    case (_, inElement, _)
      equation
        s1 = SCodeDump.printElementStr(inElement);
        res = stringAppendList({"FAILED|", s1});
      then 
        res;
    
  end matchcontinue;
end printElementStr;

public function finalStr
  input SCode.Final inFinal;
  output String str;
algorithm
  str := match(inFinal)
    case (SCode.FINAL()) then "F";
    case (SCode.NOT_FINAL()) then "X";
  end match;
end finalStr;

public function ioStr 
  input Absyn.InnerOuter inInnerOuter;
  output String outString;
algorithm
  outString := match (inInnerOuter)
    case (Absyn.INNER()) then "ix";
    case (Absyn.OUTER()) then "ox";
    case (Absyn.INNER_OUTER()) then "io";
    case (Absyn.NOT_INNER_OUTER()) then "xx";
  end match;
end ioStr;

public function visibilityStr
  input SCode.Visibility inVisibility;
  output String str;
algorithm
  str := match(inVisibility)
    case (SCode.PUBLIC()) then "p";
    case (SCode.PROTECTED()) then "x";
  end match;
end visibilityStr;

public function variabilityStr
  input SCode.Variability inVariability;
  output String outString;
algorithm
  outString := match (inVariability)
    case (SCode.VAR()) then "v";
    case (SCode.DISCRETE()) then "d";
    case (SCode.PARAM()) then "p";
    case (SCode.CONST()) then "c";
  end match;
end variabilityStr;

public function redeclareStr
  input SCode.Redeclare inRedeclare;
  output String str;
algorithm
  str := match(inRedeclare)
    case (SCode.REDECLARE()) then "R";
    case (SCode.NOT_REDECLARE()) then "X";
  end match;
end redeclareStr;

public function replaceableStr
  input SCode.Replaceable inReplaceable;
  output String strReplaceable;
algorithm
  strReplaceable := match(inReplaceable)
    local Absyn.ConstrainClass cc;
    case (SCode.REPLACEABLE(SOME(cc))) then "{r:" +& Dump.unparseConstrainclassStr(cc) +& "}";
    case (SCode.REPLACEABLE(NONE()))   then "{r:}";
    case (SCode.NOT_REPLACEABLE())     then "{}";
  end match;
end replaceableStr;

public function flowStr
  input SCode.Flow inFlow;
  output String str;
algorithm
  str := match(inFlow)
    case (SCode.FLOW()) then "f";
    case (SCode.NOT_FLOW()) then "x";
  end match;
end flowStr;

public function streamStr
  input SCode.Stream inStream;
  output String str;
algorithm
  str := match(inStream)
    case (SCode.STREAM()) then "s";
    case (SCode.NOT_STREAM()) then "x";
  end match;
end streamStr;

protected function directionStr
  input Absyn.Direction inDirection;
  output String outString;
algorithm
  outString := match (inDirection)
    case (Absyn.BIDIR())  then "x";
    case (Absyn.INPUT())  then ">";
    case (Absyn.OUTPUT()) then "<";
  end match;
end directionStr;

public function encapsulatedStr
  input SCode.Encapsulated inEncapsulated;
  output String str;
algorithm
  str := match(inEncapsulated)
    case (SCode.ENCAPSULATED()) then "E";
    case (SCode.NOT_ENCAPSULATED()) then "X";
  end match;
end encapsulatedStr;

public function partialStr
  input SCode.Partial inPartial;
  output String str;
algorithm
  str := match(inPartial)
    case (SCode.PARTIAL())     then "~";
    case (SCode.NOT_PARTIAL()) then "*";
  end match;
end partialStr;

public function restrictionStr
  "Translates a SCode.Restriction to a String."
  input SCode.Restriction inRestriction;
  output String outString;
algorithm
  outString := match(inRestriction)
    case SCode.R_CLASS() then "CL";
    case SCode.R_OPTIMIZATION() then "OZ";
    case SCode.R_MODEL() then "MO";
    case SCode.R_RECORD() then "RE";
    case SCode.R_BLOCK() then "BL";
    case SCode.R_CONNECTOR(true) then "EC";
    case SCode.R_CONNECTOR(false) then "CN";
    case SCode.R_OPERATOR(true) then "OF";
    case SCode.R_OPERATOR(false) then "OP";
    case SCode.R_TYPE() then "TY";
    case SCode.R_PACKAGE() then "PK";
    case SCode.R_FUNCTION() then "FU";
    case SCode.R_EXT_FUNCTION() then "EF";
    case SCode.R_ENUMERATION() then "EN";
    case SCode.R_PREDEFINED_INTEGER() then "Ti";
    case SCode.R_PREDEFINED_REAL() then "Tr";
    case SCode.R_PREDEFINED_STRING() then "Ts";
    case SCode.R_PREDEFINED_BOOLEAN() then "Tb";
    case SCode.R_PREDEFINED_ENUMERATION() then "Te";
    case SCode.R_METARECORD(name = _) then "MR";
    case SCode.R_UNIONTYPE() then "UT";
    else "UK";
  end match;
end restrictionStr;

end SCodeFlatDump;