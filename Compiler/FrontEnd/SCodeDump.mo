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

encapsulated package SCodeDump
" file:        SCodeDump.mo
  package:     SCodeDump
  description: SCodeDump intermediate form

  RCS: $Id: SCodeDump.mo 8980 2011-05-13 09:12:21Z perost $

  This module functions for printing SCode."

public import Absyn;
public import SCode;

protected import Dump;
protected import List;
protected import SCodeDumpTpl;
protected import Tpl;

public constant SCodeDumpOptions defaultOptions = OPTIONS(false,false,false,false,true,true,false,false,false);

public uniontype SCodeDumpOptions
  record OPTIONS
    Boolean stripAlgorithmSections;
    Boolean stripProtectedImports;
    Boolean stripProtectedClasses;
    Boolean stripProtectedComponents;
    Boolean stripMetaRecords "The automatically generated records that change scope from uniontype to the package";
    Boolean stripGraphicalAnnotations;
    Boolean stripStringComments;
    Boolean stripExternalDecl;
    Boolean stripOutputBindings;
  end OPTIONS;
end SCodeDumpOptions;

public function programStr
  input SCode.Program inProgram;
  input SCodeDumpOptions options = defaultOptions;
  output String outString;
algorithm
  outString := Tpl.tplString2(SCodeDumpTpl.dumpProgram, inProgram, options);
end programStr;

public function classDefStr
  input SCode.ClassDef cd;
  input SCodeDumpOptions options = defaultOptions;
  output String outString;
algorithm
  outString := Tpl.tplString2(SCodeDumpTpl.dumpClassDef, cd, options);
end classDefStr;

public function statementStr
  input SCode.Statement stmt;
  input SCodeDumpOptions options = defaultOptions;
  output String outString;
algorithm
  outString := Tpl.tplString2(SCodeDumpTpl.dumpStatement, stmt, options);
end statementStr;

public function equationStr
  input SCode.EEquation inEEquation;
  input SCodeDumpOptions options = defaultOptions;
  output String outString;
algorithm
  outString := Tpl.tplString2(SCodeDumpTpl.dumpEEquation, inEEquation, options);
end equationStr;

public function printModStr
"Prints SCode.Mod to a string."
  input SCode.Mod inMod;
  input SCodeDumpOptions options = defaultOptions;
  output String outString;
algorithm
  outString := Tpl.tplString2(SCodeDumpTpl.dumpModifier, inMod, options);
end printModStr;

public function printCommentAndAnnotationStr
"Prints SCode.Comment to a string."
  input SCode.Comment inComment;
  input SCodeDumpOptions options = defaultOptions;
  output String outString;
algorithm
  outString := Tpl.tplString2(SCodeDumpTpl.dumpComment, inComment, options);
end printCommentAndAnnotationStr;

public function printCommentStr
"Prints SCode.Comment.comment to a string."
  input SCode.Comment inComment;
  input SCodeDumpOptions options = defaultOptions;
  output String outString;
algorithm
  outString := match(inComment)
    local Option<String> comment;
    case (SCode.COMMENT(comment = comment))
      then Tpl.tplString2(SCodeDumpTpl.dumpCommentStr, comment, options);
    else "";
  end match;
end printCommentStr;

public function printAnnotationStr
"Prints SCode.Comment.annotation to a string."
  input SCode.Comment inComment;
  input SCodeDumpOptions options = defaultOptions;
  output String outString;
algorithm
  outString := match(inComment, options)
    local Option<SCode.Annotation> annotation_;
    case (SCode.COMMENT(annotation_ = annotation_), _)
      then Tpl.tplString2(SCodeDumpTpl.dumpAnnotationOpt, annotation_, options);
    else "";
  end match;
end printAnnotationStr;

public function restrString
"Prints SCode.Restriction to a string."
  input SCode.Restriction inRestriction;
  output String outString;
algorithm
  outString := match (inRestriction)
    case SCode.R_CLASS() then "class";
    case SCode.R_OPTIMIZATION() then "optimization";
    case SCode.R_MODEL() then "model";
    case SCode.R_RECORD(false) then "record";
    case SCode.R_RECORD(true) then "operator record";
    case SCode.R_BLOCK() then "block";
    case SCode.R_CONNECTOR(false) then "connector";
    case SCode.R_CONNECTOR(true) then "expandable connector";
    case SCode.R_OPERATOR() then "operator";
    case SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(false)) then "pure function";
    case SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(true)) then "impure function";
    case SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION()) then "operator function";
    case SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(false)) then "pure external function";
    case SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(true)) then "impure external function";
    case SCode.R_FUNCTION(SCode.FR_RECORD_CONSTRUCTOR()) then "record constructor";
    case SCode.R_FUNCTION(SCode.FR_PARALLEL_FUNCTION()) then "parallel function";
    case SCode.R_FUNCTION(SCode.FR_KERNEL_FUNCTION()) then "kernel function";
    case SCode.R_TYPE() then "type";
    case SCode.R_PACKAGE() then "package";
    case SCode.R_ENUMERATION() then "enumeration";
    case SCode.R_METARECORD() then "metarecord";
    case SCode.R_UNIONTYPE() then "uniontype";
    // predefined types
    case SCode.R_PREDEFINED_INTEGER() then "Integer";
    case SCode.R_PREDEFINED_REAL() then "Real";
    case SCode.R_PREDEFINED_STRING() then "String";
    case SCode.R_PREDEFINED_BOOLEAN() then "Boolean";
    // BTH
    case SCode.R_PREDEFINED_CLOCK() then "Clock";
    case SCode.R_PREDEFINED_ENUMERATION() then "enumeration";
  end match;
end restrString;

public function restrictionStringPP
  "Translates a SCode.Restriction to a String."
  input SCode.Restriction inRestriction;
  output String outString;
algorithm
  outString := Tpl.tplString(SCodeDumpTpl.dumpRestriction, inRestriction);
end restrictionStringPP;

protected constant String noEachStr = "";

public function unparseElementStr
"Print SCode.Element to a string."
  input SCode.Element inElement;
  input SCodeDumpOptions options = defaultOptions;
  output String outString;
algorithm
  outString := Tpl.tplString3(SCodeDumpTpl.dumpElement, inElement, noEachStr, options);
end unparseElementStr;

public function shortElementStr
"Print SCode.Element to a string."
  input SCode.Element inElement;
  output String outString;
algorithm
  outString := match (inElement)
    local
      String str,res,n,ioStr;
      SCode.Mod mod;
      Absyn.Path path;
      Absyn.Import imp;
      Absyn.InnerOuter io;
      SCode.Redeclare rdp;
      SCode.Replaceable rpp;
      SCode.Partial pp;

    case SCode.EXTENDS(baseClassPath = path,modifications = mod)
      equation
        str = Absyn.pathString(path);
        str = str + printModStr(mod,defaultOptions);
        res = stringAppendList({"extends ",str,";"});
      then
        res;

    case SCode.COMPONENT()
      equation
        res = unparseElementStr(inElement,defaultOptions);
      then
        res;

    case SCode.CLASS(prefixes = SCode.PREFIXES(),
                     classDef = SCode.DERIVED())
      equation
        res = unparseElementStr(inElement,defaultOptions);
      then
        res;

    case SCode.CLASS(name = n, partialPrefix = pp, prefixes = SCode.PREFIXES(innerOuter = io, redeclarePrefix = rdp, replaceablePrefix = rpp),
                     classDef = SCode.CLASS_EXTENDS(baseClassName = str))
      equation
        ioStr = Dump.unparseInnerouterStr(io) + redeclareStr(rdp) + replaceablePrefixStr(rpp) + partialStr(pp);
        res = stringAppendList({ioStr, "class extends ",n," extends ", str, ";"});
      then
        res;

    case SCode.CLASS(name = n, partialPrefix = pp, prefixes = SCode.PREFIXES(innerOuter = io, redeclarePrefix = rdp, replaceablePrefix = rpp),
                     classDef = SCode.ENUMERATION())
      equation
        ioStr = Dump.unparseInnerouterStr(io) + redeclareStr(rdp) + replaceablePrefixStr(rpp) + partialStr(pp);
        res = stringAppendList({ioStr, "class ",n," enumeration;"});
      then
        res;

    case SCode.CLASS(name = n, partialPrefix = pp, prefixes = SCode.PREFIXES(innerOuter = io, redeclarePrefix = rdp, replaceablePrefix = rpp))
      equation
        ioStr = Dump.unparseInnerouterStr(io) + redeclareStr(rdp) + replaceablePrefixStr(rpp) + partialStr(pp);
        res = stringAppendList({ioStr, "class ",n,";"});
      then
        res;

    case (SCode.IMPORT(imp = imp))
      equation
         str = "import "+ Absyn.printImportString(imp) + ";";
      then str;
  end match;
end shortElementStr;

public function printEnumStr
  input SCode.Enum en;
  output String str;
algorithm
  str := match (en)
    local
      String s;
    case SCode.ENUM(s, _) then s;
  end match;
end printEnumStr;

public function variabilityString
"Print Variability to a string."
  input SCode.Variability inVariability;
  output String outString;
algorithm
  outString := match (inVariability)
    case (SCode.VAR()) then "VAR";
    case (SCode.DISCRETE()) then "DISCRETE";
    case (SCode.PARAM()) then "PARAM";
    case (SCode.CONST()) then "CONST";
  end match;
end variabilityString;

public function parallelismString
"Print parallelism to a string."
  input SCode.Parallelism inParallelism;
  output String outString;
algorithm
  outString := match (inParallelism)
    case (SCode.PARGLOBAL()) then "PARGLOBAL";
    case (SCode.PARLOCAL()) then "PARLOCAL";
    case (SCode.NON_PARALLEL()) then "NON_PARALLEL";
  end match;
end parallelismString;

public function innerouterString
"Print a inner outer info to a string."
  input Absyn.InnerOuter innerOuter;
  output String outString;
algorithm
  outString := match (innerOuter)
    case (Absyn.INNER_OUTER()) then "INNER/OUTER";
    case (Absyn.INNER()) then "INNER";
    case (Absyn.OUTER()) then "OUTER";
    case (Absyn.NOT_INNER_OUTER()) then "";
  end match;
end innerouterString;

public function unparseVariability
"Print Variability to a string."
  input SCode.Variability inVariability;
  output String outString;
algorithm
  outString := match (inVariability)
    case (SCode.VAR()) then "";
    case (SCode.DISCRETE()) then "discrete";
    case (SCode.PARAM()) then "parameter";
    case (SCode.CONST()) then "constant";
  end match;
end unparseVariability;

public function equationStr2
"Takes a SCode.Equation rather then SCode.EEquation as equationStr does."
  input SCode.Equation eqns;
  input SCodeDumpOptions options;
  output String s;
algorithm
  s := match(eqns,options)
    local SCode.EEquation e;
    case(SCode.EQUATION(eEquation=e),_) then equationStr(e,options);
  end match;
end equationStr2;

public function printInitialStr
"prints SCode.Initial to a string"
  input SCode.Initial initial_;
  output String str;
algorithm
  str := match(initial_)
    case (SCode.INITIAL()) then "initial";
    case (SCode.NON_INITIAL()) then "non initial";
  end match;
end printInitialStr;

public function connectorTypeStr
  input SCode.ConnectorType inConnectorType;
  output String str;
algorithm
  str := match(inConnectorType)
    case SCode.POTENTIAL() then "";
    case SCode.FLOW() then "flow";
    case SCode.STREAM() then "stream";
  end match;
end connectorTypeStr;

public function encapsulatedStr
  input SCode.Encapsulated inEncapsulated;
  output String str;
algorithm
  str := match(inEncapsulated)
    case (SCode.ENCAPSULATED()) then "encapsulated ";
    case (SCode.NOT_ENCAPSULATED()) then "";
  end match;
end encapsulatedStr;

public function partialStr
  input SCode.Partial inPartial;
  output String str;
algorithm
  str := match(inPartial)
    case (SCode.PARTIAL())     then "partial ";
    case (SCode.NOT_PARTIAL()) then "";
  end match;
end partialStr;

public function visibilityStr
  input SCode.Visibility inVisibility;
  output String str;
algorithm
  str := match(inVisibility)
    case (SCode.PUBLIC()) then "public ";
    case (SCode.PROTECTED()) then "protected ";
  end match;
end visibilityStr;

public function finalStr
  input SCode.Final inFinal;
  output String str;
algorithm
  str := match(inFinal)
    case (SCode.FINAL()) then "final ";
    case (SCode.NOT_FINAL()) then "";
  end match;
end finalStr;

public function eachStr
  input SCode.Each inEach;
  output String str;
algorithm
  str := match(inEach)
    case (SCode.EACH()) then "each ";
    case (SCode.NOT_EACH()) then "";
  end match;
end eachStr;

public function redeclareStr
  input SCode.Redeclare inRedeclare;
  output String str;
algorithm
  str := match(inRedeclare)
    case (SCode.REDECLARE()) then "redeclare ";
    case (SCode.NOT_REDECLARE()) then "";
  end match;
end redeclareStr;

public function replaceableStr
  input SCode.Replaceable inReplaceable;
  output String strReplaceable;
  output String strConstraint;
algorithm
  (strReplaceable, strConstraint) := match(inReplaceable)
    local
      Absyn.Path path;
      SCode.Mod mod;
      String path_str, mod_str;

    case (SCode.REPLACEABLE(SOME(SCode.CONSTRAINCLASS(
        constrainingClass = path, modifier = mod))))
      equation
        path_str = Absyn.pathString(path);
        mod_str = printModStr(mod,defaultOptions);
      then ("replaceable ", path_str + "(" + mod_str + ")");
    case (SCode.REPLACEABLE(NONE())) then ("replaceable ", "");
    case (SCode.NOT_REPLACEABLE()) then ("", "");
  end match;
end replaceableStr;

public function replaceablePrefixStr
  input SCode.Replaceable inReplaceable;
  output String strReplaceable;
algorithm
  (strReplaceable) := match(inReplaceable)
    case (SCode.REPLACEABLE(_)) then "replaceable ";
    case (SCode.NOT_REPLACEABLE()) then "";
  end match;
end replaceablePrefixStr;

public function replaceableConstrainClassStr
  input SCode.Replaceable inReplaceable;
  output String strReplaceable;
algorithm
  (_, strReplaceable) := replaceableStr(inReplaceable);
end replaceableConstrainClassStr;

public function prefixesStr "Returns prefixes as string"
  input SCode.Prefixes prefixes;
  output String str;
algorithm
  str := match(prefixes)
    local
      SCode.Visibility v;
      SCode.Redeclare rd;
      SCode.Final f;
      Absyn.InnerOuter io;
      SCode.Replaceable rpl;
      String s;

    case(SCode.PREFIXES(v,rd,f,io,rpl))
      equation
        s = visibilityStr(v) +
            redeclareStr(rd) +
            finalStr(f) +
            Absyn.innerOuterStr(io) +
            replaceablePrefixStr(rpl);
      then
        s;

  end match;
end prefixesStr;

public function filterElements
  input list<SCode.Element> elements;
  input SCodeDumpOptions options;
  output list<SCode.Element> outElements;
algorithm
  outElements := List.select1(elements,filterElement,options);
end filterElements;

protected function filterElement
  input SCode.Element element;
  input SCodeDumpOptions options;
  output Boolean b;
algorithm
  b := match (element,options)
    case (SCode.IMPORT(visibility=SCode.PROTECTED()),OPTIONS(stripProtectedImports=true)) then false;
    case (SCode.CLASS(prefixes=SCode.PREFIXES(visibility=SCode.PROTECTED())),OPTIONS(stripProtectedClasses=true)) then false;
    case (SCode.COMPONENT(prefixes=SCode.PREFIXES(visibility=SCode.PROTECTED())),OPTIONS(stripProtectedComponents=true)) then false;
    case (SCode.CLASS(restriction=SCode.R_METARECORD(moved = true)),OPTIONS(stripMetaRecords=true)) then false;
    else true;
  end match;
end filterElement;

annotation(__OpenModelica_Interface="frontend");
end SCodeDump;
