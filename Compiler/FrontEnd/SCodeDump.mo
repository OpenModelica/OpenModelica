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
protected import Print;
protected import SCodeDumpTpl;
protected import Tpl;
protected import Util;

public function programStr
  input SCode.Program inProgram;
  output String outString;
algorithm
  outString := Tpl.tplString(SCodeDumpTpl.dumpProgram, inProgram);
end programStr;

public function classDefStr
  input SCode.ClassDef cd;
  output String outString;
algorithm
  outString := Tpl.tplString(SCodeDumpTpl.dumpClassDef, cd);
end classDefStr;

public function statementStr
  input SCode.Statement stmt;
  output String outString;
algorithm
  outString := Tpl.tplString(SCodeDumpTpl.dumpStatement, stmt);
end statementStr;

public function equationStr
  input SCode.EEquation inEEquation;
  output String outString;
algorithm
  outString := Tpl.tplString(SCodeDumpTpl.dumpEEquation, inEEquation);
end equationStr;

public function printModStr
"Prints SCode.Mod to a string."
  input SCode.Mod inMod;
  output String outString;
algorithm
  outString := Tpl.tplString(SCodeDumpTpl.dumpModifier, inMod);
end printModStr;

public function restrString
"Prints SCode.Restriction to a string."
  input SCode.Restriction inRestriction;
  output String outString;
algorithm
  outString := match (inRestriction)
    case SCode.R_CLASS() then "CLASS";
    case SCode.R_OPTIMIZATION() then "OPTIMIZATION";
    case SCode.R_MODEL() then "MODEL";
    case SCode.R_RECORD(false) then "RECORD";
    case SCode.R_RECORD(true) then "OPERATOR_RECORD";
    case SCode.R_BLOCK() then "BLOCK";
    case SCode.R_CONNECTOR(false) then "CONNECTOR";
    case SCode.R_CONNECTOR(true) then "EXPANDABLE_CONNECTOR";
    case SCode.R_OPERATOR() then "OPERATOR";
    case SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(false)) then "PURE FUNCTION";
    case SCode.R_FUNCTION(SCode.FR_NORMAL_FUNCTION(true)) then "IMPURE FUNCTION";
    case SCode.R_FUNCTION(SCode.FR_OPERATOR_FUNCTION()) then "OPERATOR_FUNCTION";
    case SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(false)) then "PURE EXTERNAL_FUNCTION";
    case SCode.R_FUNCTION(SCode.FR_EXTERNAL_FUNCTION(true)) then "IMPURE PURE EXTERNAL_FUNCTION";
    case SCode.R_FUNCTION(SCode.FR_RECORD_CONSTRUCTOR()) then "RECORD_CONSTRUCTOR";
    case SCode.R_FUNCTION(SCode.FR_PARALLEL_FUNCTION()) then "PARALLEL FUNCTION";
    case SCode.R_FUNCTION(SCode.FR_KERNEL_FUNCTION()) then "KERNEL_FUNCTION";
    case SCode.R_TYPE() then "TYPE";
    case SCode.R_PACKAGE() then "PACKAGE";
    case SCode.R_ENUMERATION() then "ENUMERATION";
    case SCode.R_METARECORD(index=_) then "METARECORD";
    case SCode.R_UNIONTYPE() then "UNIONTYPE";
    // predefined types
    case SCode.R_PREDEFINED_INTEGER() then "PREDEFINED_INT";
    case SCode.R_PREDEFINED_REAL() then "PREDEFINED_REAL";
    case SCode.R_PREDEFINED_STRING() then "PREDEFINED_STRING";
    case SCode.R_PREDEFINED_BOOLEAN() then "PREDEFINED_BOOL";
    case SCode.R_PREDEFINED_ENUMERATION() then "PREDEFINED_ENUM";
  end match;
end restrString;

public function restrictionStringPP
  "Translates a SCode.Restriction to a String."
  input SCode.Restriction inRestriction;
  output String outString;
algorithm
  outString := Tpl.tplString(SCodeDumpTpl.dumpRestriction, inRestriction);
end restrictionStringPP;

public function printRestr
"Prints SCode.Restriction to the Print buffer."
  input SCode.Restriction restr;
protected
  String str;
algorithm
  str := restrString(restr);
  Print.printBuf(str);
end printRestr;

protected function printFinal
"Prints \"final\" to the Print buffer."
  input Boolean inBoolean;
algorithm
  _ := matchcontinue (inBoolean)
    case false then ();
    case true
      equation
        Print.printBuf(" final ");
      then
        ();
  end matchcontinue;
end printFinal;

public function printElementList
"Print SCode.Element list to Print buffer."
  input list<SCode.Element> inElementLst;
algorithm
  _ := matchcontinue (inElementLst)
    local
      SCode.Element x;
      list<SCode.Element> xs;
    case ({}) then ();
    case ((x :: xs))
      equation
        printElement(x);
        printElementList(xs);
      then
        ();
  end matchcontinue;
end printElementList;

public function printElement
"Print SCode.Element to Print buffer."
  input SCode.Element elt;
protected
  String str;
algorithm
  str := printElementStr(elt);
  Print.printBuf(str);
end printElement;

public function printElementStr
"Print SCode.Element to a string."
  input SCode.Element inElement;
  output String outString;
algorithm
  outString :=  matchcontinue (inElement)
    local
      String str,str2,res,n,mod_str,s,vs,modStr,prefStr;
      Absyn.Path path;
      SCode.Mod mod;
      SCode.Final finalPrefix;
      SCode.Replaceable repl;
      SCode.Visibility vis;
      SCode.Redeclare red;
      Absyn.InnerOuter io;
      SCode.Variability var;
      Absyn.TypeSpec tySpec;
      Absyn.Import imp;
      SCode.Prefixes pref;

    case SCode.EXTENDS(baseClassPath = path,modifications = mod)
      equation
        str = Absyn.pathString(path);
        modStr = printModStr(mod);
        res = stringAppendList({"EXTENDS(",str,", modification=",modStr,")"});
      then
        res;
    case SCode.COMPONENT(name = n,
                   prefixes = pref as SCode.PREFIXES(
                     innerOuter=io,
                     finalPrefix = finalPrefix,
                     replaceablePrefix = repl,
                     visibility = vis,
                     redeclarePrefix = red),
                     attributes = SCode.ATTR(variability = var),typeSpec = tySpec,
                   modifications = mod)
      equation
        mod_str = printModStr(mod);
        s = Dump.unparseTypeSpec(tySpec);
        vs = variabilityString(var);
        str2 = innerouterString(io);
        prefStr = prefixesStr(pref);
        res = stringAppendList({"COMPONENT(",n, " in/out: ", str2, " mod: ",mod_str, " tp: ", s," var :",vs," prefixes: ",prefStr,")"});
      then
        res;
    case _
      equation
        res = printClassStr(inElement);
      then
        res;
    case (SCode.IMPORT(imp = imp))
      equation
         str = "IMPORT("+& Absyn.printImportString(imp) +& ");";
      then str;
  end matchcontinue;
end printElementStr;

protected constant String noEachStr = "";

public function unparseElementStr
"Print SCode.Element to a string."
  input SCode.Element inElement;
  output String outString;
algorithm
  outString := Tpl.tplString2(SCodeDumpTpl.dumpElement, inElement, noEachStr);
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
        str = str +& printModStr(mod);
        res = stringAppendList({"extends ",str,";"});
      then
        res;

    case SCode.COMPONENT(name = n)
      equation
        res = unparseElementStr(inElement);
      then
        res;

    case SCode.CLASS(name = n, partialPrefix = pp, prefixes = SCode.PREFIXES(innerOuter = io, redeclarePrefix = rdp, replaceablePrefix = rpp),
                     classDef = SCode.DERIVED(typeSpec = _))
      equation
        res = unparseElementStr(inElement);
      then
        res;

    case SCode.CLASS(name = n, partialPrefix = pp, prefixes = SCode.PREFIXES(innerOuter = io, redeclarePrefix = rdp, replaceablePrefix = rpp),
                     classDef = SCode.CLASS_EXTENDS(baseClassName = str))
      equation
        ioStr = Dump.unparseInnerouterStr(io) +& redeclareStr(rdp) +& replaceablePrefixStr(rpp) +& partialStr(pp);
        res = stringAppendList({ioStr, "class extends ",n," extends ", str, ";"});
      then
        res;

    case SCode.CLASS(name = n, partialPrefix = pp, prefixes = SCode.PREFIXES(innerOuter = io, redeclarePrefix = rdp, replaceablePrefix = rpp),
                     classDef = SCode.ENUMERATION(enumLst = _))
      equation
        ioStr = Dump.unparseInnerouterStr(io) +& redeclareStr(rdp) +& replaceablePrefixStr(rpp) +& partialStr(pp);
        res = stringAppendList({ioStr, "class ",n," enumeration;"});
      then
        res;

    case SCode.CLASS(name = n, partialPrefix = pp, prefixes = SCode.PREFIXES(innerOuter = io, redeclarePrefix = rdp, replaceablePrefix = rpp))
      equation
        ioStr = Dump.unparseInnerouterStr(io) +& redeclareStr(rdp) +& replaceablePrefixStr(rpp) +& partialStr(pp);
        res = stringAppendList({ioStr, "class ",n,";"});
      then
        res;

    case (SCode.IMPORT(imp = imp))
      equation
         str = "import "+& Absyn.printImportString(imp) +& ";";
      then str;
  end match;
end shortElementStr;

public function printClassStr "
  prints a class to a string"
  input SCode.Element inClass;
  output String outString;
algorithm
  outString := match (inClass)
    local
      String s,res,id,re,strPartialPrefix,strEncapsulatedPrefix,prefStr;
      SCode.Partial p;
      SCode.Encapsulated en;
      SCode.Restriction rest;
      SCode.ClassDef def;
      SCode.Visibility vis;
      SCode.Redeclare red;
      SCode.Final fin;
      Absyn.InnerOuter io;
      SCode.Replaceable rep;
      SCode.Prefixes pref;

    case (SCode.CLASS(name = id,prefixes = pref as SCode.PREFIXES(vis,red,fin,io,rep),partialPrefix = p,encapsulatedPrefix = en,restriction = rest,classDef = def))
      equation
        s = printClassdefStr(def);
        re = restrString(rest);
        strPartialPrefix = Util.if_(SCode.partialBool(p), "true", "false");
        strEncapsulatedPrefix = Util.if_(SCode.encapsulatedBool(en), "true", "false");
        prefStr = prefixesStr(pref);
        res = stringAppendList({"CLASS(",id,", partial = ",strPartialPrefix, ", encapsulated = ", strEncapsulatedPrefix, ", prefixes: ",prefStr, ", ", re, ", ", s, ")\n"});
      then
        res;
  end match;
end printClassStr;

public function printClassdefStr
"prints the class definition to a string"
  input SCode.ClassDef inClassDef;
  output String outString;
algorithm
  outString := matchcontinue (inClassDef)
    local
      list<String> elts_str;
      String s1,res,s2,s3,baseClassName;
      list<SCode.Element> elts;
      list<SCode.Equation> eqns,ieqns;
      list<SCode.AlgorithmSection> alg,ial;
      Option<SCode.ExternalDecl> ext;
      Absyn.TypeSpec typeSpec;
      SCode.Mod mod;
      list<SCode.Enum> enumLst;
      list<Absyn.Path> plst;
      Absyn.Path path;
      list<String> slst;

    case (SCode.PARTS(elementLst = elts,
                normalEquationLst = eqns,
                initialEquationLst = ieqns,
                normalAlgorithmLst = alg,
                initialAlgorithmLst = ial,
                externalDecl = ext))
      equation
        elts_str = List.map(elts, printElementStr);
        s1 = stringDelimitList(elts_str, ",\n");
        res = stringAppendList({"PARTS(\n",s1,",_,_,_,_,_)"});
      then
        res;
    /* adrpo: handle also the case: model extends X end X; */
    case (SCode.CLASS_EXTENDS(
              baseClassName = baseClassName,
              modifications = mod,
              composition = SCode.PARTS(
              elementLst = elts,
              normalEquationLst = eqns,
              initialEquationLst = ieqns,
              normalAlgorithmLst = alg,
              initialAlgorithmLst = ial,
              externalDecl = ext)))
      equation
        elts_str = List.map(elts, printElementStr);
        s1 = stringDelimitList(elts_str, ",\n");
        res = stringAppendList({"CLASS_EXTENDS(", baseClassName, " PARTS(\n",s1,",_,_,_,_,_)"});
      then
        res;
    case (SCode.DERIVED(typeSpec = typeSpec,modifications = mod))
      equation
        s2 = Dump.unparseTypeSpec(typeSpec);
        s3 = printModStr(mod);
        res = stringAppendList({"DERIVED(",s2,",",s3,")"});
      then
        res;
    case (SCode.ENUMERATION(enumLst))
      equation
        s1 = stringDelimitList(List.map(enumLst, printEnumStr), ", ");
        res = stringAppendList({"ENUMERATION(", s1, ")"});
      then
        res;
    case (SCode.OVERLOAD(plst))
      equation
        s1 = stringDelimitList(List.map(plst, Absyn.pathString), ", ");
        res = stringAppendList({"OVERLOAD(", s1, ")"});
      then
        res;
    case (SCode.PDER(path, slst))
      equation
        s1 = Absyn.pathString(path);
        s2 = stringDelimitList(slst, ", ");
        res = stringAppendList({"PDER(", s1, ", ", s2, ")"});
      then
        res;
    case (_)
      equation
        res = "SCode.printClassdefStr -> UNKNOWN_CLASS(CheckME)";
      then
        res;
  end matchcontinue;
end printClassdefStr;

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
  output String s;
algorithm
  s := matchcontinue(eqns)
    local SCode.EEquation e;
    case(SCode.EQUATION(eEquation=e)) then equationStr(e);
  end matchcontinue;
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
        mod_str = printModStr(mod);
      then ("replaceable ", path_str +& "(" +& mod_str +& ")");
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
        s = visibilityStr(v) +&
            redeclareStr(rd) +&
            finalStr(f) +&
            Absyn.innerOuterStr(io) +&
            replaceablePrefixStr(rpl);
      then
        s;

  end match;
end prefixesStr;

end SCodeDump;
