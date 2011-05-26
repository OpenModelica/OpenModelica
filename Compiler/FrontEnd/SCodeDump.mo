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
protected import Util;
protected import Print;

protected function elseWhenEquationStr
"@author: adrpo
  Return the elsewhen parts as a string."
  input  list<tuple<Absyn.Exp, list<SCode.EEquation>>> elseBranches;
  output String str;
algorithm
  str := match(elseBranches)
    local
      Absyn.Exp exp;
      list<SCode.EEquation> eqn_lst;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> rest;
      String s1, s2, s3, res;
      list<String> str_lst;
    
    case ({}) then "";
    
    case ((exp,eqn_lst)::rest)
      equation
        s1 = Dump.printExpStr(exp);
        str_lst = Util.listMap(eqn_lst, equationStr);
        s2 = Util.stringDelimitList(str_lst, "\n");
        s3 = elseWhenEquationStr(elseBranches);
        res = stringAppendList({"\nelsewhen ",s1," then\n",s2,"\n", s3});
      then 
        res;
  end match;
end elseWhenEquationStr;

public function equationStr
"function: equationStr
  author: PA
  Return the equation as a string."
  input SCode.EEquation inEEquation;
  output String outString;
algorithm
  outString := match (inEEquation)
    local
      String s1,s2,s3,s4,res,id;
      list<String> tb_strs,fb_strs,str_lst;
      Absyn.Exp e1,e2,exp;
      list<Absyn.Exp> ifexp;
      list<SCode.EEquation> ttb,fb,eqn_lst;
      list<list<SCode.EEquation>> tb;
      Absyn.ComponentRef cr1,cr2,cr;
      Absyn.FunctionArgs fargs;
      list<tuple<Absyn.Exp, list<SCode.EEquation>>> elseBranches;
      
    case (SCode.EQ_IF(condition = e1::ifexp,thenBranch = ttb::tb,elseBranch = fb))
      equation
        s1 = Dump.printExpStr(e1);
        tb_strs = Util.listMap(ttb, equationStr);
        fb_strs = Util.listMap(fb, equationStr);
        s2 = Util.stringDelimitList(tb_strs, "\n");
        s3 = Util.stringDelimitList(fb_strs, "\n");
        s4 = elseIfEquationStr(ifexp,tb);
        res = stringAppendList({"if ",s1," then ",s2,s4,"else ",s3,"end if;"});
      then
        res;
    case (SCode.EQ_EQUALS(expLeft = e1,expRight = e2))
      equation
        s1 = Dump.printExpStr(e1);
        s2 = Dump.printExpStr(e2);
        res = stringAppendList({s1," = ",s2,";"});
      then
        res;
    case (SCode.EQ_CONNECT(crefLeft = cr1,crefRight = cr2))
      equation
        s1 = Dump.printComponentRefStr(cr1);
        s2 = Dump.printComponentRefStr(cr2);
        res = stringAppendList({"connect(",s1,", ",s2,");"});
      then
        res;
    case (SCode.EQ_FOR(index = id,range = exp,eEquationLst = eqn_lst))
      equation
        s1 = Dump.printExpStr(exp);
        str_lst = Util.listMap(eqn_lst, equationStr);
        s2 = Util.stringDelimitList(str_lst, "\n");
        res = stringAppendList({"for ",id," in ",s1," loop\n",s2,"\nend for;"});
      then
        res;
    case (SCode.EQ_WHEN(condition=exp, eEquationLst=eqn_lst, elseBranches=elseBranches))
      equation
        s1 = Dump.printExpStr(exp);
        str_lst = Util.listMap(eqn_lst, equationStr);
        s2 = Util.stringDelimitList(str_lst, "\n");
        s3 = elseWhenEquationStr(elseBranches);
        res = stringAppendList({"when ",s1," then\n",s2,s3,"\nend when;"});
      then 
        res;
    case (SCode.EQ_ASSERT(condition = e1,message = e2))
      equation
        s1 = Dump.printExpStr(e1);
        s2 = Dump.printExpStr(e2);
        res = stringAppendList({"assert(",s1,", ",s2,");"});
      then
        res;
    case (SCode.EQ_REINIT(cref = cr,expReinit = e1))
      equation
        s1 = Dump.printComponentRefStr(cr);
        s2 = Dump.printExpStr(e1);
        res = stringAppendList({"reinit(",s1,", ",s2,");"});
      then
        res;
    case(SCode.EQ_NORETCALL(functionName = cr, functionArgs = fargs))
      equation
        s1 = Dump.printComponentRefStr(cr);
        s2 = Dump.printFunctionArgsStr(fargs);
        res = s1 +& "(" +& s2 +& ");";
      then res;
  end match;
end equationStr;

protected function prettyPrintOptModifier 
"Author BZ, 2008-07
 Pretty print SCode.Mod"
input Option<Absyn.Modification> oam;
input String comp;
output String str;
algorithm str := matchcontinue(oam,comp)
  local
    Absyn.Modification m;
  case(NONE(),_) then "";
  case(SOME(m),comp)
    equation
      str = prettyPrintModifier(m,comp);
      then
        str;
  end matchcontinue;
end prettyPrintOptModifier;

protected function prettyPrintModifier "
Author BZ, 2008-07
Helper function for prettyPrintOptModifier"
  input Absyn.Modification oam;
  input String comp;
  output String str;
algorithm str := matchcontinue(oam,comp)
  local
    Absyn.Modification m;
    Absyn.Exp exp;
    list<Absyn.ElementArg> laea;
    Absyn.ElementArg aea;
  case(Absyn.CLASSMOD(eqMod=Absyn.EQMOD(exp=exp)),comp)
    equation
      str = comp +& " = " +&Dump.printExpStr(exp);
      then
        str;
  case(Absyn.CLASSMOD((laea as aea::{}),Absyn.NOMOD()),comp)
    equation
    str = comp +& "(" +&prettyPrintElementModifier(aea) +&")";
    then
      str;
  case(Absyn.CLASSMOD((laea as _::{}),Absyn.NOMOD()),comp)
    equation
      str = comp +& "({" +& Util.stringDelimitList(Util.listMap(laea,prettyPrintElementModifier),", ") +& "})";
    then
      str;
  end matchcontinue;
end prettyPrintModifier;

protected function prettyPrintElementModifier 
"Author BZ, 2008-07
 Helper function for prettyPrintOptModifier
 TODO: implement type of new redeclare component"
  input Absyn.ElementArg aea;
  output String str;
algorithm str := matchcontinue(aea)
  local
    Option<Absyn.Modification> oam;
    String compName;
    Absyn.ElementSpec spec;
    Absyn.ComponentRef cr;
  case(Absyn.MODIFICATION(modification = oam,componentRef=cr))
    equation
      compName = Absyn.printComponentRefStr(cr);
    then prettyPrintOptModifier(oam,compName);
  case(Absyn.REDECLARATION(elementSpec=spec))
    equation
      compName = Absyn.elementSpecName(spec);
    then
      "Redeclaration of (" +& compName +& ")";
end matchcontinue;
end prettyPrintElementModifier;

public function printMod
"function: printMod
  This function prints a modification.
  The code is excluded from the report for brevity."
  input SCode.Mod m;
  String s;
algorithm
  s := printModStr(m);
  Print.printBuf(s);
end printMod;

public function printModStr
"function: printModStr
  Prints SCode.Mod to a string."
  input SCode.Mod inMod;
  output String outString;
algorithm
  outString := matchcontinue (inMod)
    local
      String finalPrefixstr,str,res,each_str,subs_str,ass_str;
      list<String> strs;
      SCode.Final finalPrefix;
      list<SCode.Element> elist;
      SCode.Each each_;
      list<SCode.SubMod> subs;
      Option<tuple<Absyn.Exp,Boolean>> ass;
    
    case SCode.NOMOD() then "";
    
    case SCode.REDECL(finalPrefix = finalPrefix,elementLst = elist)
      equation
        Print.printBuf("redeclare(");
        finalPrefixstr = finalStr(finalPrefix);
        strs = Util.listMap(elist, printElementStr);
        str = Util.stringDelimitList(strs, ",");
        res = stringAppendList({"redeclare(",finalPrefixstr,str,")"});
      then
        res;
    
    case SCode.MOD(finalPrefix = finalPrefix,eachPrefix = each_,subModLst = subs,binding = ass)
      equation
        finalPrefixstr = finalStr(finalPrefix);
        each_str = eachStr(each_);
        subs_str = printSubs1Str(subs);
        ass_str = printEqmodStr(ass);
        res = stringAppendList({finalPrefixstr,each_str,subs_str,ass_str});
      then
        res;
    case _
      equation
        Print.printBuf("#-- SCodeDump.printModStr failed\n");
      then
        fail();
  end matchcontinue;
end printModStr;

public function restrString
"function: restrString
  Prints SCode.Restriction to a string."
  input SCode.Restriction inRestriction;
  output String outString;
algorithm
  outString := match (inRestriction)
    case SCode.R_CLASS() then "CLASS";
    case SCode.R_OPTIMIZATION() then "OPTIMIZATION";
    case SCode.R_MODEL() then "MODEL";
    case SCode.R_RECORD() then "RECORD";
    case SCode.R_BLOCK() then "BLOCK";
    case SCode.R_CONNECTOR(false) then "CONNECTOR";
    case SCode.R_CONNECTOR(true) then "EXPANDABLE_CONNECTOR";
    case SCode.R_OPERATOR(false) then "OPERATOR";
    case SCode.R_OPERATOR(true) then "OPERATOR_FUNCTION";
    case SCode.R_TYPE() then "TYPE";
    case SCode.R_PACKAGE() then "PACKAGE";
    case SCode.R_FUNCTION() then "FUNCTION";
    case SCode.R_EXT_FUNCTION() then "EXTFUNCTION";
    case SCode.R_ENUMERATION() then "ENUMERATION";
    case SCode.R_METARECORD(_,_) then "METARECORD";
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
  outString := match(inRestriction)
    case SCode.R_CLASS() then "class";
    case SCode.R_OPTIMIZATION() then "optimization";
    case SCode.R_MODEL() then "model";
    case SCode.R_RECORD() then "record";
    case SCode.R_BLOCK() then "block";
    case SCode.R_CONNECTOR(true) then "expandable connector";
    case SCode.R_CONNECTOR(false) then "connector";
    case SCode.R_OPERATOR(true) then "operator function";
    case SCode.R_OPERATOR(false) then "operator";
    case SCode.R_TYPE() then "type";
    case SCode.R_PACKAGE() then "package";
    case SCode.R_FUNCTION() then "function";
    case SCode.R_EXT_FUNCTION() then "external function";
    case SCode.R_ENUMERATION() then "enumeration";
    case SCode.R_PREDEFINED_INTEGER() then "IntegerType";
    case SCode.R_PREDEFINED_REAL() then "RealType";
    case SCode.R_PREDEFINED_STRING() then "StringType";
    case SCode.R_PREDEFINED_BOOLEAN() then "BooleanType";
    case SCode.R_PREDEFINED_ENUMERATION() then "EnumType";
    case SCode.R_METARECORD(name = _) then "record";
    case SCode.R_UNIONTYPE() then "uniontype";
    else "#Internal error: missing case in SCode.restrictionStringPP#";
  end match;
end restrictionStringPP;

public function printRestr
"function: printRestr
  Prints SCode.Restriction to the Print buffer."
  input SCode.Restriction restr;
  String str;
algorithm
  str := restrString(restr);
  Print.printBuf(str);
end printRestr;

protected function printFinal
"function: printFinal
  Prints \"final\" to the Print buffer."
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

protected function printSubsStr
"function: printSubsStr
  Prints a SCode.SubMod list to a string."
  input list<SCode.SubMod> inSubModLst;
  output String outString;
algorithm
  outString := matchcontinue (inSubModLst)
    local
      String s,res,n,mod_str,str,sub_str;
      SCode.Mod mod;
      list<SCode.SubMod> subs;
      list<SCode.Subscript> ss;
    
    case {} then "";
    
    case {SCode.NAMEMOD(ident = n,A = mod)}
      equation
        s = printModStr(mod);
        res = n +& " " +& s;
      then
        res;
    case (SCode.NAMEMOD(ident = n,A = mod) :: subs)
      equation
        mod_str = printModStr(mod);
        str = printSubsStr(subs);
        res = stringAppendList({n, " ", mod_str, ", ", str});
      then
        res;
    case {SCode.IDXMOD(subscriptLst = ss,an = mod)}
      equation
        str = Dump.printSubscriptsStr(ss);
        mod_str = printModStr(mod);
        res = stringAppend(str, mod_str);
      then
        res;
    case (SCode.IDXMOD(subscriptLst = ss,an = mod) :: subs)
      equation
        str = Dump.printSubscriptsStr(ss);
        mod_str = printModStr(mod);
        sub_str = printSubsStr(subs);
        res = stringAppendList({str,mod_str,", ",sub_str});
      then
        res;
  end matchcontinue;
end printSubsStr;

public function printSubs1Str
"function: printSubs1Str
  Helper function to printSubsStr."
  input list<SCode.SubMod> inSubModLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inSubModLst)
    local
      String s,res;
      list<SCode.SubMod> l;
    case {} then "";
    case l
      equation
        s = printSubsStr(l);
        res = stringAppendList({"(",s,")"});
      then
        res;
  end matchcontinue;
end printSubs1Str;

protected function printEqmodStr
"function: printEqmodStr
  Helper function to printModStr."
  input Option<tuple<Absyn.Exp,Boolean>> inAbsynExpOption;
  output String outString;
algorithm
  outString := match (inAbsynExpOption)
    local
      String str,res;
      Absyn.Exp e;
      Boolean b;
    case NONE() then "";
    case SOME((e,b))
      equation
        str = Dump.printExpStr(e);
        res = stringAppend(" = ", str);
      then
        res;
  end match;
end printEqmodStr;

public function printElementList
"function: printElementList
  Print SCode.Element list to Print buffer."
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
"function: printElement
  Print SCode.Element to Print buffer."
  input SCode.Element elt;
  String str;
algorithm
  str := printElementStr(elt);
  Print.printBuf(str);
end printElement;

public function printElementStr
"function: printElementStr
  Print SCode.Element to a string."
  input SCode.Element inElement;
  output String outString;
algorithm
  outString :=  matchcontinue (inElement)
    local
      String str,str2,res,n,mod_str,s,vs,modStr,strFinalPrefix,strReplaceablePrefix,prefStr;
      Absyn.Path path;
      SCode.Mod mod;
      SCode.Final finalPrefix;
      SCode.Replaceable repl;
      SCode.Visibility vis;
      SCode.Redeclare red;
      Absyn.InnerOuter io;
      SCode.Element cl;
      SCode.Variability var;
      Absyn.TypeSpec tySpec;
      Option<SCode.Comment> comment;
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
                   modifications = mod,comment = comment)
      equation
        mod_str = printModStr(mod);
        s = Dump.unparseTypeSpec(tySpec);
        vs = variabilityString(var);
        str2 = innerouterString(io);
        prefStr = prefixesStr(pref);
        res = stringAppendList({"COMPONENT(",n, " in/out: ", str2, " mod: ",mod_str, " tp: ", s," var :",vs," prefixes: ",prefStr,")"});
      then
        res;
    case inElement
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

public function unparseElementStr
"function: unparseElementStr
  Print SCode.Element to a string."
  input SCode.Element inElement;
  output String outString;
algorithm
  outString := match (inElement)
    local
      String str,res,n,mod_str,s,vs,ioStr;
      Absyn.TypeSpec typath;
      SCode.Mod mod;
      SCode.Element cl;
      SCode.Variability var;
      Option<SCode.Comment> comment;
      Absyn.Path path;
      Absyn.Import imp;
      Absyn.InnerOuter io;

    case SCode.EXTENDS(baseClassPath = path,modifications = mod)
      equation
        str = Absyn.pathString(path);
        res = stringAppendList({"extends ",str,";"});
      then
        res;

    case SCode.COMPONENT(name = n,prefixes = SCode.PREFIXES(innerOuter = io),
                   attributes = SCode.ATTR(variability = var),
                   typeSpec = typath,modifications = mod,comment = comment)
      equation
        ioStr = Dump.unparseInnerouterStr(io);
        mod_str = printModStr(mod);
        s = Dump.unparseTypeSpec(typath);
        vs = unparseVariability(var);
        vs = Util.if_(stringEq(vs, ""), "", vs +& " ");
        res = stringAppendList({ioStr,vs,s," ",n," ",mod_str,";\n"});
      then
        res;

    case inElement
      equation
        str = printClassStr(inElement);
        res = stringAppendList({"class ",str,";\n"});
      then
        res;

    case (SCode.IMPORT(imp = imp))
      equation
         str = "import "+& Absyn.printImportString(imp) +& ";";
      then str;
  end match;
end unparseElementStr;

public function shortElementStr
"function: shortElementStr
  Print SCode.Element to a string."
  input SCode.Element inElement;
  output String outString;
algorithm
  outString := match (inElement)
    local
      String str,res,n,mod_str,s,vs,ioStr;
      Absyn.TypeSpec typath;
      SCode.Mod mod;
      SCode.Element cl;
      SCode.Variability var;
      Option<SCode.Comment> comment;
      Absyn.Path path;
      Absyn.Import imp;
      Absyn.InnerOuter io;

    case SCode.EXTENDS(baseClassPath = path,modifications = mod)
      equation
        str = Absyn.pathString(path);
        str = str +& printModStr(mod);        
        res = stringAppendList({"extends ",str,";"});
      then
        res;

    case SCode.COMPONENT(name = n,prefixes = SCode.PREFIXES(innerOuter = io),attributes = SCode.ATTR(variability = var),
                   typeSpec = typath,modifications = mod,comment = comment)
      equation
        ioStr = Dump.unparseInnerouterStr(io);
        mod_str = printModStr(mod);
        s = Dump.unparseTypeSpec(typath);
        vs = unparseVariability(var);
        vs = Util.if_(stringEq(vs, ""), "", vs +& " ");
        mod_str = Util.if_(stringEq(mod_str, ""),"", " " +& mod_str); 
        res = stringAppendList({ioStr,vs,s," ",n,mod_str,";"});
      then
        res;

    case SCode.CLASS(name = n)
      equation
        res = stringAppendList({"class ",n,";"});
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
"function printClassdefStr
  prints the class definition to a string"
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
        elts_str = Util.listMap(elts, printElementStr);
        s1 = Util.stringDelimitList(elts_str, ",\n");
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
        elts_str = Util.listMap(elts, printElementStr);
        s1 = Util.stringDelimitList(elts_str, ",\n");
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
    case (SCode.ENUMERATION(enumLst, _))
      equation
        s1 = Util.stringDelimitList(Util.listMap(enumLst, printEnumStr), ", ");
        res = stringAppendList({"ENUMERATION(", s1, ")"});
      then
        res;
    case (SCode.OVERLOAD(plst, _))
      equation
        s1 = Util.stringDelimitList(Util.listMap(plst, Absyn.pathString), ", ");
        res = stringAppendList({"OVERLOAD(", s1, ")"});
      then
        res;
    case (SCode.PDER(path, slst, _))
      equation
        s1 = Absyn.pathString(path);
        s2 = Util.stringDelimitList(slst, ", ");
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
"function: variabilityString
  Print Variability to a string."
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

public function innerouterString
"function: innerouterString
  Print a inner outer info to a string."
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
"function: variabilityString
  Print Variability to a string."
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

protected function elseIfEquationStr
"Author BZ, 2008-09
 Function for printing elseif statements to string."
  input list<Absyn.Exp> conditions;
  input list<list<SCode.EEquation>> elseIfBodies;
  output String elseIfString;
algorithm
  elseIfString := match(conditions,elseIfBodies)
    local
      Absyn.Exp cond;
      list<SCode.EEquation> eib;
      String conString, bodyString,recString,resString;
      list<String> bodyStrings;
    case({},{}) then "";
    case(cond::conditions,eib::elseIfBodies)
      equation
        conString = Dump.printExpStr(cond);
        bodyStrings = Util.listMap(eib, equationStr);
        bodyString = Util.stringDelimitList(bodyStrings, "\n");
        recString = elseIfEquationStr(conditions,elseIfBodies);
        recString = Util.if_(Util.isEmptyString(recString), "", "\n" +& recString);
        resString = " elseif " +& conString +& " then\n" +& bodyString +& recString;
      then
        resString;
  end match;
end elseIfEquationStr;

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

public function flowStr
  input SCode.Flow inFlow;
  output String str;
algorithm
  str := match(inFlow)
    case (SCode.FLOW()) then "flow";
    case (SCode.NOT_FLOW()) then "";
  end match;
end flowStr;

public function streamStr
  input SCode.Stream inStream;
  output String str;
algorithm
  str := match(inStream)
    case (SCode.STREAM()) then "stream";
    case (SCode.NOT_STREAM()) then "";
  end match;
end streamStr;

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
    local Absyn.ConstrainClass cc;
    case (SCode.REPLACEABLE(SOME(cc))) then ("replaceable ", Dump.unparseConstrainclassStr(cc));
    case (SCode.REPLACEABLE(NONE())) then ("replaceable ", "");
    case (SCode.NOT_REPLACEABLE()) then ("", "");
  end match;
end replaceableStr;

public function replaceablePrefixStr
  input SCode.Replaceable inReplaceable;
  output String strReplaceable;
algorithm
  (strReplaceable) := match(inReplaceable)
    local Absyn.ConstrainClass cc;
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
  str := matchcontinue(prefixes)
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
    
  end matchcontinue;
end prefixesStr;

end SCodeDump;
