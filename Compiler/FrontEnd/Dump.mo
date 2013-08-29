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

encapsulated package Dump
" file:        Dump.mo
  package:     Dump
  description: debug printing

  RCS: $Id$

  Printing routines for debugging of the AST.  These functions do
  nothing but print the data structures to the standard output.

  The main entrypoint for this module is the function Dump.dump
  which takes an entire program as an argument, and prints it all
  in Modelica source form. The other interface functions can be
  used to print smaller portions of a program."

// public imports
public import Absyn;

// protected imports
protected import Error;
protected import List;
protected import Print;
protected import System;
protected import Util;

public function dumpExpStr
  input Absyn.Exp exp;
  output String str;
algorithm
  Print.clearBuf();
  printExp(exp);
  str := Print.getString();
end dumpExpStr;

public function dumpExp
  input Absyn.Exp exp;
  protected String str;
algorithm
  Print.clearBuf();
  printExp(exp);
  str := Print.getString();
  print(str);
  print("--------------------\n");
end dumpExp;

public function dump
"Prints a program, i.e. the whole AST, to the Print buffer."
  input Absyn.Program inProgram;
algorithm
  _ := match (inProgram)
    local
      list<Absyn.Class> cs;
      Absyn.Within w;
    case Absyn.PROGRAM(classes = cs,within_ = w)
      equation
        Print.printBuf("Absyn.PROGRAM([\n");
        printList(cs, printClass, ", ");
        Print.printBuf("],");
        dumpWithin(w);
        Print.printBuf(")\n");
      then
        ();
  end match;
end dump;

public function unparseStr
"Prettyprints the Program, i.e. the whole AST, to a string."
  input Absyn.Program inProgram;
  input Boolean markup "
    Used by MathCore, and dependencies to other modules requires this to also be in OpenModelica.
    Contact peter.aronsson@mathcore.com for an explanation.

    Note: This will be used for a different purpose in OpenModelica once we redesign Dump to use templates
          ... by sending in DumpOptions (for example to add markup, etc)
    ";
  output String outString;
algorithm
  outString := matchcontinue (inProgram,markup)
    local
      String s1,s2,str;
      list<Absyn.Class> cs;
      Absyn.Within w;
    case (Absyn.PROGRAM(classes = {}),_) then "";
    case (Absyn.PROGRAM(classes = cs,within_ = w),_)
      equation
        s1 = unparseWithin(0, w);
        s2 = unparseClassList(0, cs);
        str = stringAppendList({s1,s2,"\n"});
      then
        str;
    case (_,_) then "unparsing failed\n";
  end matchcontinue;
end unparseStr;

public function unparseClassList
"Prettyprints a list of classes"
  input Integer inInteger;
  input list<Absyn.Class> inAbsynClassLst;
  output String outString;
algorithm
  outString := match (inInteger,inAbsynClassLst)
    local
      String s1,s2,res;
      Integer i;
      Absyn.Class c;
      list<Absyn.Class> cs;
    case (_,{}) then "";
    case (i,(c :: cs))
      equation
        s1 = unparseClassStr(i, c, "", ("",""), "");
        s2 = unparseClassList(i, cs);
        res = stringAppendList({s1,";\n",s2});
      then
        res;
  end match;
end unparseClassList;

public function unparseWithin
"Prettyprints a within statement."
  input Integer inInteger;
  input Absyn.Within inWithin;
  output String outString;
algorithm
  outString := match (inInteger,inWithin)
    local
      String s1,s2,str;
      Integer i;
      Absyn.Path p;
    case (_,Absyn.TOP()) then "";
    case (i,Absyn.WITHIN(path = p))
      equation
        s1 = indentStr(i);
        s2 = Absyn.pathString(p);
        str = stringAppendList({s1,"within ",s2,";\n"});
      then
        str;
  end match;
end unparseWithin;

protected function dumpWithin
"Dumps within to the Print buffer."
  input Absyn.Within inWithin;
algorithm
  _ := match (inWithin)
    local Absyn.Path p;
    case (Absyn.TOP())
      equation
        Print.printBuf("Absyn.TOP");
      then
        ();
    case (Absyn.WITHIN(path = p))
      equation
        Print.printBuf("Absyn.WITHIN(");
        dumpPath(p);
        Print.printBuf("\n");
      then
        ();
  end match;
end dumpWithin;

public function unparseClassStr
"Prettyprints a Class.
    // adrpo: BEWARE! the prefix keywords HAVE TO BE IN A SPECIFIC ORDER:
    //  ([final] | [redeclare] [final] [inner] [outer]) [replaceable] [encapsulated] [partial] [restriction] name
    // if the order is not the one above on re-parse will give errors!"
  input Integer indent;
  input Absyn.Class ourClass;
  input String inFinalStr;
  input tuple<String,String> redeclareKeywords;
  input String innerouterStr;
  output String outString;
algorithm
  outString := match (indent,ourClass,inFinalStr,redeclareKeywords,innerouterStr)
    local
      String is,s4,s5,str,n,fi,io,s6,s8,s9,baseClassName;
      Integer i_1,i;
      Boolean p,f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
      Option<String> optcmt;
      Absyn.TypeSpec tspec;
      Absyn.ElementAttributes attr;
      list<Absyn.ElementArg> m,cmod;
      Option<Absyn.Comment> cmt;
      list<Absyn.EnumLiteral> l;
      Absyn.EnumDef ENUM_COLON;
      Absyn.Path fname;
      list<String> vars,typeVars;
      tuple<String,String> re;
      list<Absyn.Path> paths;
      String   partialStr, encapsulatedStr, restrictionStr, prefixKeywords, tvs, finalStr, annStr;
      list<Absyn.Annotation> ann;

    // adrpo: BEWARE! the prefix keywords HAVE TO BE IN A SPECIFIC ORDER:
    //  ([final] | [redeclare] [final] [inner] [outer]) [replaceable] [encapsulated] [partial] [restriction] name
    // if the order is not the one above the parser will give errors!
    case (i,Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                        body = Absyn.PARTS(typeVars = typeVars,classParts = parts,ann = ann,comment = optcmt)),fi,re,io)
      equation
        is = indentStr(i);
        encapsulatedStr = selectString(e, "encapsulated ", "");
        partialStr = selectString(p, "partial ", "");
        finalStr = selectString(f, "final ", fi);
        restrictionStr = unparseRestrictionStr(r);
        i_1 = i + 1;
        s4 = unparseClassPartStrLst(i_1, parts, true);
        s5 = unparseStringCommentOption(optcmt);
        annStr = stringAppendList(List.map1(List.map1Reverse(ann,unparseAnnotation,i_1),stringAppend,";\n"));
        // the prefix keywords MUST be in the order below given below! See the function comment.
        prefixKeywords = unparseElementPrefixKeywords(re, finalStr, innerouterStr, encapsulatedStr, partialStr);
        tvs = Util.if_(List.isEmpty(typeVars),"","<"+&stringDelimitList(typeVars,",")+&">");
        str = stringAppendList({is,prefixKeywords,restrictionStr," ",n,tvs,s5,"\n",s4,annStr,is,"end ",n});
      then
        str;

    case (_,Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                             body = Absyn.DERIVED(typeSpec = tspec,attributes = attr,arguments = m,comment = cmt)),fi,re,io)
      equation
        is = indentStr(indent);
        partialStr = selectString(p, "partial ", "");
        finalStr = selectString(f, "final ", fi);
        encapsulatedStr = selectString(e, "encapsulated ", "");
        restrictionStr = unparseRestrictionStr(r);
        s4 = unparseElementattrStr(attr);
        s6 = unparseTypeSpec(tspec);
        s8 = unparseMod1Str(m);
        s9 = unparseCommentOption(cmt);
        // the prefix keywords MUST be in the order below given below! See the function comment.
        prefixKeywords = unparseElementPrefixKeywords(re, finalStr, innerouterStr, encapsulatedStr, partialStr);
        str = stringAppendList({is,prefixKeywords,restrictionStr," ",n," = ",s4,s6,s8,s9});
      then
        str;

    case (i,Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                        body = Absyn.ENUMERATION(enumLiterals = Absyn.ENUMLITERALS(enumLiterals = l),comment = cmt)),fi,re,io)
      equation
        is = indentStr(i);
        partialStr = selectString(p, "partial ", "");
        finalStr = selectString(f, "final ", fi);
        encapsulatedStr = selectString(e, "encapsulated ", "");
        restrictionStr = unparseRestrictionStr(r);
        s4 = unparseEnumliterals(l);
        s5 = unparseCommentOption(cmt);
        // the prefix keywords MUST be in the order below given below! See the function comment.
        prefixKeywords = unparseElementPrefixKeywords(re, finalStr, innerouterStr, encapsulatedStr, partialStr);
        str = stringAppendList({is,prefixKeywords,restrictionStr," ",n," = enumeration(",s4,")",s5});
      then
        str;

    case (i,Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                        body = Absyn.ENUMERATION(enumLiterals = ENUM_COLON,comment = cmt)),fi,re,io)
      equation
        is = indentStr(i);
        partialStr = selectString(p, "partial ", "");
        finalStr = selectString(f, "final ", fi);
        encapsulatedStr = selectString(e, "encapsulated ", "");
        restrictionStr = unparseRestrictionStr(r);
        s5 = unparseCommentOption(cmt);
        // the prefix keywords MUST be in the order below given below! See the function comment.
        prefixKeywords = unparseElementPrefixKeywords(re, finalStr, innerouterStr, encapsulatedStr, partialStr);
        str = stringAppendList({is,prefixKeywords,restrictionStr," ",n," = enumeration(:)",s5});
      then
        str;

    case (i,Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                        body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,modifications = cmod,ann = ann,comment = optcmt,parts = parts)),fi,re,io)
      equation
        is = indentStr(i);
        partialStr = selectString(p, "partial ", "");
        finalStr = selectString(f, "final ", fi);
        encapsulatedStr = selectString(e, "encapsulated ", "");
        restrictionStr = unparseRestrictionStr(r);
        i_1 = i + 1;
        s4 = unparseClassPartStrLst(i_1, parts, true);
        s5 = unparseMod1Str(cmod);
        s6 = unparseStringCommentOption(optcmt);
        annStr = stringAppendList(List.map1(List.map1Reverse(ann,unparseAnnotation,i_1),stringAppend,";\n"));
        // the prefix keywords MUST be in the order below given below! See the function comment.
        prefixKeywords = unparseElementPrefixKeywords(re, finalStr, innerouterStr, encapsulatedStr, partialStr);
        str = stringAppendList({is,prefixKeywords,restrictionStr," extends ",baseClassName,s5,s6,"\n",s4,annStr,is,"end ",baseClassName});
      then
        str;

    case (i,Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
          body = Absyn.PDER(functionName = fname,vars = vars,comment=cmt)),fi,re,io)
      equation
        is = indentStr(i);
        partialStr = selectString(p, "partial ", "");
        finalStr = selectString(f, "final ", fi);
        encapsulatedStr = selectString(e, "encapsulated ", "");
        restrictionStr = unparseRestrictionStr(r);
        s4 = Absyn.pathString(fname);
        s5 = stringDelimitList(vars, ", ");
        s6 = unparseCommentOption(cmt);
        prefixKeywords = unparseElementPrefixKeywords(re, finalStr, innerouterStr, encapsulatedStr, partialStr);
        str = stringAppendList({is,prefixKeywords,restrictionStr," ",n," = der(",s4,", ",s5,")", s6});
      then
        str;

    case (i,Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
          body = Absyn.OVERLOAD(functionNames=paths, comment=cmt)),fi,re,io)
      equation
        is = indentStr(i);
        partialStr = selectString(p, "partial ", "");
        finalStr = selectString(f, "final ", fi);
        encapsulatedStr = selectString(e, "encapsulated ", "");
        restrictionStr = unparseRestrictionStr(r);
        s5 = stringDelimitList(List.map(paths,Absyn.pathString), ", ");
        s6 = unparseCommentOption(cmt);
        prefixKeywords = unparseElementPrefixKeywords(re, finalStr, innerouterStr, encapsulatedStr, partialStr);
        str = stringAppendList({is,prefixKeywords,restrictionStr," ",n," = $overload(",s5,")", s6});
      then
        str;

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Dump.unparseClassStr"});
      then fail();
  end match;
end unparseClassStr;

public function unparseClassAttributesStr
"Prettyprints Class attributes."
  input Absyn.Class inClass;
  output String outString;
algorithm
  outString := match (inClass)
    local
      String s1,s2,s2_1,s3,str,n;
      Boolean p,f,e;
      Absyn.Restriction r;

    case (Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = _))
      equation
        s1 = selectString(p, "partial ", "");
        s2 = selectString(f, "final ", "");
        s2_1 = selectString(e, "encapsulated ", "");
        s3 = unparseRestrictionStr(r);
        str = stringAppendList({s2_1,s1,s2,s3});
      then
        str;
  end match;
end unparseClassAttributesStr;

public function unparseCommentOption
"Prettyprints a Comment."
  input Option<Absyn.Comment> inAbsynCommentOption;
  output String outString;
algorithm
  outString := match (inAbsynCommentOption)
    local
      String s1,str,cmt;
      Option<Absyn.Annotation> annopt;

    case (NONE()) then "";

    case (SOME(Absyn.COMMENT(annopt,SOME(cmt))))
      equation
        s1 = unparseAnnotationOption(0, annopt);
        str = stringAppendList({" \"",cmt,"\"",s1});
      then
        str;

    case (SOME(Absyn.COMMENT(annopt,NONE())))
      equation
        str = unparseAnnotationOption(0, annopt);
      then
        str;
  end match;
end unparseCommentOption;

public function unparseCommentOptionNoAnnotation
"Prettyprints a Comment without printing the annotation part."
  input Option<Absyn.Comment> inAbsynCommentOption;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynCommentOption)
    local
      String str,cmt;
    case (SOME(Absyn.COMMENT(_,SOME(cmt))))
      equation
        str = stringAppendList({" \"",cmt,"\""});
      then
        str;

    case (_) then "";
  end matchcontinue;
end unparseCommentOptionNoAnnotation;

protected function dumpCommentOption
"Prints a Comment to the Print buffer."
  input Option<Absyn.Comment> inAbsynCommentOption;
algorithm
  _ := match (inAbsynCommentOption)
    local
      String str,cmt;
      Option<Absyn.Annotation> annopt;

    case (NONE())
      equation
        Print.printBuf("NONE()");
      then
        ();

    case (SOME(Absyn.COMMENT(annopt,SOME(cmt))))
      equation
        Print.printBuf("SOME(Absyn.COMMENT(");
        dumpAnnotationOption(annopt);
        str = stringAppendList({"SOME(\"",cmt,"\")))"});
        Print.printBuf(str);
      then
        ();

    case (SOME(Absyn.COMMENT(annopt,NONE())))
      equation
        Print.printBuf("SOME(Absyn.COMMENT(");
        dumpAnnotationOption(annopt);
        Print.printBuf(",NONE()))");
      then
        ();
  end match;
end dumpCommentOption;

protected function dumpAnnotationOption
"Dumps an annotation option to the Print buffer."
  input Option<Absyn.Annotation> inAbsynAnnotationOption;
algorithm
  _ := match (inAbsynAnnotationOption)
    local list<Absyn.ElementArg> mod;

    case (NONE())
      equation
        Print.printBuf("NONE()");
      then
        ();

    case (SOME(Absyn.ANNOTATION(mod)))
      equation
        Print.printBuf("SOME(Absyn.ANNOTATION(");
        printMod1(mod);
        Print.printBuf("))");
      then
        ();
  end match;
end dumpAnnotationOption;

protected function unparseEnumliterals
"Prettyprints enumeration literals, each consisting of an identifier and an optional comment."
  input list<Absyn.EnumLiteral> inAbsynEnumLiteralLst;
  output String outString;
algorithm
  outString := match (inAbsynEnumLiteralLst)
    local
      String s1,s2,res,str;
      Option<Absyn.Comment> optcmt;
      Absyn.EnumLiteral a;
      list<Absyn.EnumLiteral> b;

    case ({}) then "";

    case ((Absyn.ENUMLITERAL(literal = str,comment = optcmt) :: (a :: b)))
      equation
        s1 = unparseCommentOption(optcmt);
        s2 = unparseEnumliterals((a :: b));
        res = stringAppendList({str,s1,", ",s2});
      then
        res;

    case ({Absyn.ENUMLITERAL(literal = str,comment = NONE())}) then str;
    case ({Absyn.ENUMLITERAL(literal = str,comment = optcmt as SOME(_))})
      equation
        s1 = unparseCommentOption(optcmt);
        res = stringAppendList({str," ",s1});
      then
        res;

    end match;
end unparseEnumliterals;

protected function printEnumliterals
"Prints enumeration literals, each consisting of an
  identifier and an optional comment to the Print buffer."
  input list<Absyn.EnumLiteral> lst;
algorithm
  Print.printBuf("[");
  printEnumliterals2(lst);
  Print.printBuf("]");
end printEnumliterals;

protected function printEnumliterals2
"Helper function to printEnumliterals"
  input list<Absyn.EnumLiteral> inAbsynEnumLiteralLst;
algorithm
  _ := matchcontinue (inAbsynEnumLiteralLst)
    local
      String str,str2;
      Option<Absyn.Comment> optcmt,optcmt2;
      Absyn.EnumLiteral a;
      list<Absyn.EnumLiteral> b;

    case ({}) then ();

    case ((Absyn.ENUMLITERAL(literal = str,comment = optcmt) :: (a :: b)))
      equation
        Print.printBuf("Absyn.ENUMLITERAL(\"");
        Print.printBuf(str);
        Print.printBuf("\",");
        dumpCommentOption(optcmt);
        Print.printBuf("), ");
        printEnumliterals2((a :: b));
      then
        ();

    case ({Absyn.ENUMLITERAL(literal = str,comment = optcmt),Absyn.ENUMLITERAL(literal = str2,comment = optcmt2)})
      equation
        Print.printBuf("Absyn.ENUMLITERAL(\"");
        Print.printBuf(str);
        Print.printBuf("\",");
        dumpCommentOption(optcmt);
        Print.printBuf("), Absyn.ENUMLITERAL(\"");
        Print.printBuf(str2);
        Print.printBuf("\",");
        dumpCommentOption(optcmt2);
        Print.printBuf(")");
      then
        ();
  end matchcontinue;
end printEnumliterals2;

public function unparseRestrictionStr
"Prettyprints the class restriction."
  input Absyn.Restriction inRestriction;
  output String outString;
algorithm
  outString := match (inRestriction)
    case Absyn.R_CLASS() then "class";
    case Absyn.R_OPTIMIZATION() then "optimization";
    case Absyn.R_MODEL() then "model";
    case Absyn.R_RECORD() then "record";
    case Absyn.R_BLOCK() then "block";
    case Absyn.R_CONNECTOR() then "connector";
    case Absyn.R_EXP_CONNECTOR() then "expandable connector";
    case Absyn.R_TYPE() then "type";
    case Absyn.R_UNIONTYPE() then "uniontype";
    case Absyn.R_PACKAGE() then "package";
    case Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.IMPURE())) then "impure function";
    case Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.PURE())) then "pure function";
    case Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.NO_PURITY())) then "function";
    case Absyn.R_FUNCTION(Absyn.FR_OPERATOR_FUNCTION()) then "operator function";
    case Absyn.R_FUNCTION(Absyn.FR_PARALLEL_FUNCTION()) then "parallel function";
    case Absyn.R_FUNCTION(Absyn.FR_KERNEL_FUNCTION()) then "kernel function";
    case Absyn.R_PREDEFINED_INTEGER() then "Integer";
    case Absyn.R_PREDEFINED_REAL() then "Real";
    case Absyn.R_PREDEFINED_STRING() then "String";
    case Absyn.R_PREDEFINED_BOOLEAN() then "Boolean";
    case Absyn.R_METARECORD(index=_) then "metarecord";
    case Absyn.R_OPERATOR() then "operator";
    case Absyn.R_OPERATOR_RECORD() then "operator record";
    else "*unknown*";
  end match;
end unparseRestrictionStr;

public function printInfo
"author: adrpo, 2006-02-05
  Dumps an Info to the Print buffer."
  input Absyn.Info inInfo;
algorithm
  _ := match (inInfo)
    local
      String s1,s2,s3,s4,filename;
      Boolean isReadOnly;
      Integer sline,scol,eline,ecol;
    case (Absyn.INFO(fileName = filename,isReadOnly = isReadOnly,
                     lineNumberStart = sline,columnNumberStart = scol,
                     lineNumberEnd = eline,columnNumberEnd = ecol))
      equation
        Print.printBuf("Absyn.INFO(\"");
        Print.printBuf(filename);
        Print.printBuf("\", ");
        printBool(isReadOnly);
        Print.printBuf(", ");
        s1 = intString(sline);
        Print.printBuf(s1);
        Print.printBuf(", ");
        s2 = intString(scol);
        Print.printBuf(s2);
        Print.printBuf(", ");
        s3 = intString(eline);
        Print.printBuf(s3);
        Print.printBuf(", ");
        s4 = intString(ecol);
        Print.printBuf(s4);
        Print.printBuf(")");
      then
        ();
  end match;
end printInfo;

public function unparseInfoStr
"author: adrpo, 2006-02-05
  Translates Info to a string representation"
  input Absyn.Info inInfo;
  output String outString;
algorithm
  outString:=
  match (inInfo)
    local
      String s1,s2,s3,s4,s5,str,filename;
      Boolean isReadOnly;
      Integer sline,scol,eline,ecol;
    case (Absyn.INFO(fileName = filename,isReadOnly = isReadOnly,
                     lineNumberStart = sline,columnNumberStart = scol,
                     lineNumberEnd = eline,columnNumberEnd = ecol))
      equation
        s1 = selectString(isReadOnly, "readonly", "writable");
        s2 = intString(sline);
        s3 = intString(scol);
        s4 = intString(eline);
        s5 = intString(ecol);
        str = stringAppendList({"Absyn.INFO(\"",filename,"\", ",s1,", ",s2,", ",s3,", ",s4,", ",s5,")\n"});
      then
        str;
  end match;
end unparseInfoStr;

protected function printClass
"Dumps a Class to the Print buffer.
  changed by adrpo, 2006-02-05 to use printInfo."
  input Absyn.Class inClass;
algorithm
  _ := match (inClass)
    local
      String n;
      Boolean p,f,e;
      Absyn.Restriction r;
      Absyn.ClassDef cdef;
      Absyn.Info info;
    case (Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = cdef,info = info))
      equation
        Print.printBuf("Absyn.CLASS(\""); Print.printBuf(n);
        Print.printBuf("\", ");           printBool(p);
        Print.printBuf(", ");             printBool(f);
        Print.printBuf(", ");             printBool(e);
        Print.printBuf(", ");             printClassRestriction(r);
        Print.printBuf(", ");             printClassdef(cdef);
        Print.printBuf(", ");             printInfo(info);
        Print.printBuf(")\n");
      then
        ();
  end match;
end printClass;

protected function printClassdef
"Prints a ClassDef to the Print buffer."
  input Absyn.ClassDef inClassDef;
algorithm
  _ := match (inClassDef)
    local
      list<Absyn.ClassPart> parts;
      Option<String> commentStr;
      Option<Absyn.Comment> comment;
      String s,baseClassName;
      Absyn.TypeSpec tspec;
      Absyn.ElementAttributes attr;
      list<Absyn.ElementArg> earg,modifications;
      list<Absyn.EnumLiteral> enumlst;
    case (Absyn.PARTS(classParts = parts,comment = commentStr))
      equation
        Print.printBuf("Absyn.PARTS([");
        printListDebug("print_classdef", parts, printClassPart, ", ");
        Print.printBuf("], ");
        printStringCommentOption(commentStr);
        Print.printBuf(")");
      then
        ();
    case (Absyn.CLASS_EXTENDS(baseClassName = baseClassName,
                              modifications = modifications,
                              parts = parts,
                              comment = commentStr))
      equation
        Print.printBuf("Absyn.CLASS_EXTENDS([");
        Print.printBuf(baseClassName); Print.printBuf(",[");
        printList(modifications, printElementArg, ",");
        Print.printBuf("], ");
        printStringCommentOption(commentStr);
        Print.printBuf(", ");
        Print.printBuf("Absyn.PARTS([");
        printListDebug("print_classdef", parts, printClassPart, ", ");
        Print.printBuf("]))");
      then
        ();
    case (Absyn.DERIVED(typeSpec = tspec,attributes = attr,arguments = earg,comment = comment))
      equation
        Print.printBuf("Absyn.DERIVED(");
        s = unparseTypeSpec(tspec);
        Print.printBuf(s);
        Print.printBuf(", ");
        printElementattr(attr);
        Print.printBuf(",[");
        printList(earg, printElementArg, ",");
        Print.printBuf("], ");
        s = unparseCommentOption(comment);
        Print.printBuf(s);
        Print.printBuf(")");
      then
        ();
    case (Absyn.ENUMERATION(enumLiterals = Absyn.ENUMLITERALS(enumLiterals = enumlst),comment = comment))
      equation
        Print.printBuf("Absyn.ENUMERATION(");
        printEnumliterals(enumlst);
        Print.printBuf(", ");
        dumpCommentOption(comment);
        Print.printBuf(")");
      then
        ();
    case (Absyn.ENUMERATION(enumLiterals = Absyn.ENUM_COLON(),comment = comment))
      equation
        Print.printBuf("Absyn.ENUMERATION( :, ");
        dumpCommentOption(comment);
        Print.printBuf(")");
      then
        ();
    case (Absyn.OVERLOAD(functionNames = _))
      equation
        Print.printBuf("Absyn.OVERLOAD( fill in )");
      then
        ();
  end match;
end printClassdef;

protected function printClassRestriction
"Prints the class restriction to the Print buffer."
  input Absyn.Restriction inRestriction;
algorithm
  _ := matchcontinue (inRestriction)
    case Absyn.R_CLASS() equation Print.printBuf("Absyn.R_CLASS"); then ();
    case Absyn.R_OPTIMIZATION() equation Print.printBuf("Absyn.R_OPTIMIZATION"); then ();
    case Absyn.R_MODEL() equation Print.printBuf("Absyn.R_MODEL"); then ();
    case Absyn.R_RECORD() equation Print.printBuf("Absyn.R_RECORD"); then ();
    case Absyn.R_BLOCK() equation Print.printBuf("Absyn.R_BLOCK"); then ();
    case Absyn.R_CONNECTOR() equation Print.printBuf("Absyn.R_CONNECTOR"); then ();
    case Absyn.R_EXP_CONNECTOR() equation Print.printBuf("Absyn.R_EXP_CONNECTOR"); then ();
    case Absyn.R_TYPE() equation Print.printBuf("Absyn.R_TYPE"); then ();
    case Absyn.R_PACKAGE() equation Print.printBuf("Absyn.R_PACKAGE"); then ();
    case Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.IMPURE()))
      equation Print.printBuf("Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.IMPURE))"); then ();
    case Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.PURE()))
      equation Print.printBuf("Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.PURE))"); then ();
    case Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.NO_PURITY()))
      equation Print.printBuf("Absyn.R_FUNCTION(Absyn.FR_NORMAL_FUNCTION(Absyn.NO_PURITY))"); then ();
    case Absyn.R_FUNCTION(Absyn.FR_OPERATOR_FUNCTION()) equation Print.printBuf("Absyn.R_FUNCTION(Absyn.FR_OPERATOR_FUNCTION)"); then ();
    case Absyn.R_FUNCTION(Absyn.FR_PARALLEL_FUNCTION()) equation Print.printBuf("Absyn.R_FUNCTION(Absyn.FR_PARALLEL_FUNCTION)"); then ();
    case Absyn.R_FUNCTION(Absyn.FR_KERNEL_FUNCTION()) equation Print.printBuf("Absyn.R_FUNCTION(Absyn.FR_KERNEL_FUNCTION)"); then ();
    case Absyn.R_OPERATOR() equation Print.printBuf("Absyn.R_OPERATOR"); then ();
    case Absyn.R_OPERATOR_RECORD() equation Print.printBuf("Absyn.R_OPERATOR_RECORD"); then ();
    case Absyn.R_ENUMERATION() equation Print.printBuf("Absyn.R_ENUMERATION"); then ();
    case Absyn.R_PREDEFINED_INTEGER() equation Print.printBuf("Absyn.R_PREDEFINED_INTEGER"); then ();
    case Absyn.R_PREDEFINED_REAL() equation Print.printBuf("Absyn.R_PREDEFINED_REAL"); then ();
    case Absyn.R_PREDEFINED_STRING() equation Print.printBuf("Absyn.R_PREDEFINED_STRING"); then ();
    case Absyn.R_PREDEFINED_BOOLEAN() equation Print.printBuf("Absyn.R_PREDEFINED_BOOLEAN"); then ();
    case Absyn.R_PREDEFINED_ENUMERATION() equation Print.printBuf("Absyn.R_PREDEFINED_ENUMERATION"); then ();
    case Absyn.R_UNIONTYPE() equation Print.printBuf("Absyn.R_UNIONTYPE"); then ();
    case _ equation Print.printBuf("/* UNKNOWN RESTRICTION! FIXME! */"); then ();
  end matchcontinue;
end printClassRestriction;

protected function printClassModification
"Prints a class modification to a print buffer."
  input list<Absyn.ElementArg> inAbsynElementArgLst;
algorithm
  _ := matchcontinue (inAbsynElementArgLst)
    local list<Absyn.ElementArg> l;
    case ({}) then ();
    case (l)
      equation
        Print.printBuf("(");
        printListDebug("print_class_modification", l, printElementArg, ",");
        Print.printBuf(")");
      then
        ();
  end matchcontinue;
end printClassModification;

protected function unparseClassModificationStr
"Prettyprints a class modification to a string."
  input Absyn.Modification inModification;
  output String outString;
algorithm
  outString := matchcontinue (inModification)
    local
      String s1,s2,str;
      list<Absyn.ElementArg> l;
      Absyn.Exp e;
    case (Absyn.CLASSMOD(elementArgLst = {})) then "";
    case (Absyn.CLASSMOD(elementArgLst = l,eqMod = Absyn.NOMOD()))
      equation
        s1 = getStringList(l, unparseElementArgStr, ", ");
        s2 = stringAppend("(", s1);
        str = stringAppend(s2, ")");
      then
        str;
    case (Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp=e)))
      equation
        s1 = printExpStr(e);
        str = stringAppendList({" = ",s1});
      then
        str;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Dump.unparseClassModificationStr"});
      then fail();
  end matchcontinue;
end unparseClassModificationStr;

protected function printElementArg
"Prints an ElementArg to the Print buffer."
  input Absyn.ElementArg inElementArg;
algorithm
  _ := match (inElementArg)
    local
      Boolean f;
      Absyn.Each each_;
      Option<Absyn.Modification> optm;
      Option<String> optcmt;
      Absyn.RedeclareKeywords keywords;
      Absyn.ElementSpec spec;
      Absyn.Path p;
    case (Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,path = p,modification = optm,comment = optcmt))
      equation
        Print.printBuf("Absyn.MODIFICATION(");
        printBool(f);
        Print.printBuf(", ");
        dumpEach(each_);
        Print.printBuf(", ");
        printPath(p);
        Print.printBuf(", ");
        printOptModification(optm);
        Print.printBuf(", ");
        printStringCommentOption(optcmt);
        Print.printBuf(")");
      then
        ();
    case (Absyn.REDECLARATION(finalPrefix = f,redeclareKeywords = keywords,eachPrefix = each_,elementSpec = spec))
      equation
        Print.printBuf("Absyn.REDECLARATION(");
        printBool(f);
        printElementspec(spec);
        Print.printBuf(",_)");
      then
        ();
  end match;
end printElementArg;

public function unparseElementArgStr
"Prettyprints an ElementArg to a string."
  input Absyn.ElementArg inElementArg;
  output String outString;
algorithm
  outString := match (inElementArg)
    local
      String s1,s2,s3,s4,s5,str;
      Boolean f;
      Absyn.Each each_;
      Option<Absyn.Modification> optm;
      Option<String> optstr;
      Absyn.RedeclareKeywords keywords;
      Absyn.ElementSpec spec;
      Option<Absyn.ConstrainClass> constr;
      String redeclareStr, replaceableStr;
      Absyn.Path p;

    case (Absyn.MODIFICATION(finalPrefix = f,eachPrefix = each_,path = p,modification = optm,comment = optstr))
      equation
        s1 = unparseEachStr(each_);
        s2 = selectString(f, "final ", "");
        s3 = Absyn.pathString(p);
        s4 = unparseOptModificationStr(optm);
        s5 = unparseStringCommentOption(optstr);
        str = stringAppendList({s1,s2,s3,s4,s5});
      then
        str;
    case (Absyn.REDECLARATION(finalPrefix = f,redeclareKeywords = keywords,eachPrefix = each_,elementSpec = spec,constrainClass = constr))
      equation
        s1 = unparseEachStr(each_);
        s2 = selectString(f, "final ", "");
        ((redeclareStr, replaceableStr)) = unparseRedeclarekeywords(keywords);
        // append each after redeclare because we need this order:
        // [redeclare] [each] [final] [replaceable]
        redeclareStr = redeclareStr +& s1;
        s4 = unparseElementspecStr(0, spec, s2, (redeclareStr,replaceableStr), "");
        s5 = unparseConstrainclassOptStr(constr);
        str = stringAppendList({s4,s5});
      then
        str;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Dump.unparseElementArgStr"});
      then fail();
  end match;
end unparseElementArgStr;

protected function unparseRedeclarekeywords
"Prettyprints the redeclare keywords, i.e replaceable and redeclare"
  input Absyn.RedeclareKeywords inRedeclareKeywords;
  output tuple<String,String> outTupleRedeclareReplaceable;
algorithm
  outTupleRedeclareReplaceable := match (inRedeclareKeywords)
    case Absyn.REDECLARE() then (("redeclare ",""));
    case Absyn.REPLACEABLE() then (("","replaceable "));
    case Absyn.REDECLARE_REPLACEABLE() then (("redeclare ","replaceable "));
  end match;
end unparseRedeclarekeywords;

public function unparseEachStr
"Prettyprints the each keyword."
  input Absyn.Each inEach;
  output String outString;
algorithm
  outString := match (inEach)
    case (Absyn.EACH()) then "each ";
    case (Absyn.NON_EACH()) then "";
  end match;
end unparseEachStr;

protected function dumpEach
"Print the each keyword to the Print buffer"
  input Absyn.Each inEach;
algorithm
  _ := match (inEach)
    case (Absyn.EACH()) equation Print.printBuf("Absyn.EACH"); then ();
    case (Absyn.NON_EACH()) equation Print.printBuf("Absyn.NON_EACH"); then ();
  end match;
end dumpEach;

protected function printClassPart
"Prints the ClassPart to the Print buffer."
  input Absyn.ClassPart inClassPart;
algorithm
  _ := match (inClassPart)
    local
      list<Absyn.ElementItem> el;
      list<Absyn.EquationItem> eqs;
      // list<Absyn.ConstraintItem> constr;
      list<Absyn.AlgorithmItem> algs;
      list<Absyn.Exp> exps;
      Absyn.ExternalDecl edecl;
    case (Absyn.PUBLIC(contents = el))
      equation
        Print.printBuf("Absyn.PUBLIC(");
        printElementitems(el);
        Print.printBuf(")");
      then
        ();
    case (Absyn.PROTECTED(contents = el))
      equation
        Print.printBuf("Absyn.PROTECTED(");
        printElementitems(el);
        Print.printBuf(")");
      then
        ();
    case (Absyn.EQUATIONS(contents = eqs))
      equation
        Print.printBuf("Absyn.EQUATIONS([");
        printList(eqs, printEquationitem, ", ");
        Print.printBuf("])");
      then
        ();
    case (Absyn.CONSTRAINTS(contents = exps))
      equation
        Print.printBuf("Absyn.CONSTRAINTS([");
        printList(exps, printExp, "; ");
        Print.printBuf("])");
      then
        ();
    case (Absyn.INITIALEQUATIONS(contents = eqs))
      equation
        Print.printBuf("Absyn.INITIALEQUATIONS([");
        printList(eqs, printEquationitem, ", ");
        Print.printBuf("])");
      then
        ();
    case (Absyn.ALGORITHMS(contents = algs))
      equation
        Print.printBuf("Absyn.ALGORITHMS(");
        printList(algs, printAlgorithmitem, ", ");
        Print.printBuf(")");
      then
        ();
    case (Absyn.INITIALALGORITHMS(contents = algs))
      equation
        Print.printBuf("Absyn.INITIALALGORITHMS([");
        printList(algs, printAlgorithmitem, ", ");
        Print.printBuf("])");
      then
        ();
    case (Absyn.EXTERNAL(externalDecl = edecl))
      equation
        Print.printBuf("Absyn.EXTERNAL(");
        printExternalDecl(edecl);
        Print.printBuf(")");
      then
        ();
  end match;
end printClassPart;

protected function printExternalDecl
"Prints an external declaration to the Print buffer."
  input Absyn.ExternalDecl inExternalDecl;
algorithm
  _ := match (inExternalDecl)
    local
      String idstr,crefstr,expstr,str,lang;
      Option<String> id;
      Option<Absyn.ComponentRef> cref;
      list<Absyn.Exp> exps;
    case Absyn.EXTERNALDECL(funcName = id,lang = NONE(),output_ = cref,args = exps)
      equation
        idstr = Util.getOptionOrDefault(id, "");
        crefstr = getOptionStr(cref, printComponentRefStr);
        expstr = printListStr(exps, printExpStr, ",");
        str = stringAppendList({idstr,", ",crefstr,", (",expstr,")"});
        Print.printBuf(str);
      then
        ();
    case Absyn.EXTERNALDECL(funcName = id,lang = SOME(lang),output_ = cref,args = exps)
      equation
        idstr = Util.getOptionOrDefault(id, "");
        crefstr = getOptionStr(cref, printComponentRefStr);
        expstr = printListStr(exps, printExpStr, ",");
        str = stringAppendList({idstr,", \"",lang,"\", ",crefstr,", (",expstr,")"});
        Print.printBuf(str);
      then
        ();
  end match;
end printExternalDecl;

public function unparseClassPartStrLst
"Prettyprints a ClassPart list to a string."
  input Integer inInteger;
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Boolean inBoolean;
  output String outString;
algorithm
  outString := match (inInteger,inAbsynClassPartLst,inBoolean)
    local
      String s1,s2,res;
      Integer i;
      Absyn.ClassPart x;
      list<Absyn.ClassPart> xs;
      Boolean skippublic;
    case (_,{},_) then "";
    case (i,(x :: xs),skippublic)
      equation
        s1 = unparseClassPartStr(i, x, skippublic);
        s2 = unparseClassPartStrLst(i, xs, false);
        res = stringAppend(s1, s2);
      then
        res;
  end match;
end unparseClassPartStrLst;

protected function unparseClassPartStr
"Prettyprints a ClassPart to a string."
  input Integer inInteger;
  input Absyn.ClassPart inClassPart;
  input Boolean inBoolean;
  output String outString;
algorithm
  outString := match (inInteger,inClassPart,inBoolean)
    local
      Integer i,i_1;
      String s1,is,str,langstr,outputstr,expstr,annstr,annstr2,ident,res;
      list<Absyn.ElementItem> el;
      list<Absyn.EquationItem> eqs;
      Option<String> lang;
      Absyn.ComponentRef output_;
      list<Absyn.Exp> expl;
      Option<Absyn.Annotation> ann,ann2;
      list<Absyn.AlgorithmItem> als;
      list<Absyn.Exp> exps;

    case (i,Absyn.PUBLIC(contents = {}),_) then "";
    case (i,Absyn.PROTECTED(contents = {}),_) then "";
    case (i,Absyn.EQUATIONS(contents = {}),_) then "";
    case (i,Absyn.INITIALEQUATIONS(contents = {}),_) then "";
    case (i,Absyn.ALGORITHMS(contents = {}),_) then "";
    case (i,Absyn.INITIALALGORITHMS(contents = {}),_) then "";

    case (i,Absyn.PUBLIC(contents = el),true)
      equation
        s1 = unparseElementitemStrLst(i, el);
        // no ident needed! i_1 = i - 1; is = indentStr(i_1);
        str = stringAppendList({s1});
      then
        str;

    case (i,Absyn.PUBLIC(contents = el),false)
      equation
        s1 = unparseElementitemStrLst(i, el);
        i_1 = i - 1;
        is = indentStr(i_1);
        str = stringAppendList({is,"public\n",s1});
      then
        str;

    case (i,Absyn.PROTECTED(contents = el),_)
      equation
        s1 = unparseElementitemStrLst(i, el);
        i_1 = i - 1;
        is = indentStr(i_1);
        str = stringAppendList({is,"protected\n",s1});
      then
        str;

    case (i,Absyn.CONSTRAINTS(contents = exps),_)
      equation
        // s1 = unparseEquationitemStrLst(i, eqs, "\n");
        s1 = stringDelimitList(List.map(exps,printExpStr),"; ");
        i_1 = i - 1;
        is = indentStr(i_1);
        str = stringAppendList({is,"constraint\n",s1});
      then
        str;

    case (i,Absyn.EQUATIONS(contents = eqs),_)
      equation
        s1 = unparseEquationitemStrLst(i, eqs, "\n");
        i_1 = i - 1;
        is = indentStr(i_1);
        str = stringAppendList({is,"equation\n",s1});
      then
        str;

    case (i,Absyn.INITIALEQUATIONS(contents = eqs),_)
      equation
        s1 = unparseEquationitemStrLst(i, eqs, "\n");
        i_1 = i - 1;
        is = indentStr(i_1);
        str = stringAppendList({is,"initial equation\n",s1});
      then
        str;

    case (i,Absyn.ALGORITHMS(contents = als),_)
      equation
        s1 = unparseAlgorithmStrLst(i, als, "\n");
        i_1 = i - 1;
        is = indentStr(i_1);
        str = stringAppendList({is,"algorithm\n",s1,"\n"});
      then
        str;

    case (i,Absyn.INITIALALGORITHMS(contents = als),_)
      equation
        s1 = unparseAlgorithmStrLst(i, als, "\n");
        i_1 = i - 1;
        is = indentStr(i_1);
        str = stringAppendList({is,"initial algorithm\n",s1,"\n"});
      then
        str;

    case (i,Absyn.EXTERNAL(externalDecl = Absyn.EXTERNALDECL(
                          funcName = SOME(ident),lang = lang,output_ = SOME(output_),
                          args = expl,annotation_ = ann),annotation_ = ann2),_)
      equation
        langstr = getExtlangStr(lang);
        outputstr = printComponentRefStr(output_);
        expstr = printListStr(expl, printExpStr, ",");
        s1 = stringAppend(langstr, " ");
        is = indentStr(i);
        annstr = unparseAnnotationOption(i, ann);
        annstr2 = unparseAnnotationOptionSemi(i, ann2);
        str = stringAppendList(
          {"\n",is,"external ",langstr," ",outputstr," = ",ident,"(",
          expstr,") ",annstr,";",annstr2,"\n"});
      then
        str;

    case (i,Absyn.EXTERNAL(externalDecl = Absyn.EXTERNALDECL(
                           funcName = SOME(ident),lang = lang,output_ = NONE(),
                           args = expl,annotation_ = ann),annotation_ = ann2),_)
      equation
        langstr = getExtlangStr(lang);
        expstr = printListStr(expl, printExpStr, ",");
        s1 = stringAppend(langstr, " ");
        is = indentStr(i);
        annstr = unparseAnnotationOption(i, ann);
        annstr2 = unparseAnnotationOptionSemi(i, ann2);
        str = stringAppendList(
          {"\n",is,"external ",langstr," ",ident,"(",expstr,") ",
          annstr,"; ",annstr2,"\n"});
      then
        str;

    case (i,Absyn.EXTERNAL(externalDecl = Absyn.EXTERNALDECL(
                           funcName = NONE(),lang = lang,output_ = NONE(),
                           annotation_ = ann),annotation_ = ann2),_)
      equation
        is = indentStr(i);
        langstr = getExtlangStr(lang);
        annstr = unparseAnnotationOption(i, ann);
        annstr2 = unparseAnnotationOptionSemi(i, ann2);
        res = stringAppendList({"\n",is,"external ",langstr," ",annstr,";",annstr2,"\n"});
      then
        res;

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Dump.unparseClassPartStr"});
      then fail();
  end match;
end unparseClassPartStr;

protected function getExtlangStr
"Prettyprints the external function language string to a string."
  input Option<String> inStringOption;
  output String outString;
algorithm
  outString := match (inStringOption)
    local
      String res,str;
    case (NONE()) then "";
    case (SOME(str)) equation res = stringAppendList({"\"",str,"\""}); then res;
  end match;
end getExtlangStr;

protected function printElementitems
"Print a list of ElementItems to the Print buffer."
  input list<Absyn.ElementItem> elts;
algorithm
  Print.printBuf("[");
  printElementitems2(elts);
  Print.printBuf("]");
end printElementitems;

protected function printElementitems2
"Helper function to printElementitems"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
algorithm
  _ := matchcontinue (inAbsynElementItemLst)
    local
      Absyn.Element e;
      Absyn.Annotation a;
      list<Absyn.ElementItem> els;
    case {} then ();
    case {Absyn.ELEMENTITEM(element = e)}
      equation
        Print.printBuf("Absyn.ELEMENTITEM(");
        printElement(e);
        Print.printBuf(")");
      then
        ();
    case (Absyn.ELEMENTITEM(element = e) :: els)
      equation
        Print.printBuf("Absyn.ELEMENTITEM(");
        printElement(e);
        Print.printBuf("), ");
        printElementitems2(els);
      then
        ();
    case _
      equation
        Print.printBuf("Error print_elementitems\n");
      then
        ();
  end matchcontinue;
end printElementitems2;

protected function printAnnotation
"Prints an annotation to the Print buffer."
  input Absyn.Annotation inAnnotation;
algorithm
  _ := match (inAnnotation)
    local list<Absyn.ElementArg> mod;
    case (Absyn.ANNOTATION(elementArgs = mod))
      equation
        Print.printBuf("ANNOTATION(");
        printModification(Absyn.CLASSMOD(mod,Absyn.NOMOD()));
        Print.printBuf(")");
      then
        ();
  end match;
end printAnnotation;

public function unparseElementitemStrLst
"Prettyprints a list of ElementItem to a string."
  input Integer inInteger;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output String outString;
algorithm
  outString := match (inInteger,inAbsynElementItemLst)
    local
      String s1,s2,res;
      Integer i;
      Absyn.ElementItem x;
      list<Absyn.ElementItem> xs;
    case (_,{}) then "";  /* indent */
    case (i,(x :: xs))
      equation
        s1 = unparseElementitemStr(i, x);
        s2 = unparseElementitemStrLst(i, xs);
        res = stringAppendList({s1,"\n",s2});
      then
        res;
  end match;
end unparseElementitemStrLst;

public function unparseElementitemStr
"Prettyprints and ElementItem."
  input Integer inInteger;
  input Absyn.ElementItem inElementItem;
  output String outString;
algorithm
  outString := match (inInteger,inElementItem)
    local
      String str,s1;
      Integer i;
      Absyn.Element e;
      Absyn.Annotation a;
    case (i,Absyn.ELEMENTITEM(element = e)) /* indent */
      equation
        str = unparseElementStr(i, e);
      then
        str;
    case (i,Absyn.LEXER_COMMENT(comment=str))
      equation
        str = System.trimWhitespace(str);
        str = indentStr(i) +& str;
      then str;
  end match;
end unparseElementitemStr;

protected function unparseAnnotationOptionSemi
"Prettyprint an annotation and a semicolon if annoation present."
  input Integer inInteger;
  input Option<Absyn.Annotation> inAbsynAnnotationOption;
  output String outString;
algorithm
  outString := matchcontinue (inInteger,inAbsynAnnotationOption)
    local
      String s,res;
      Integer i;
      Absyn.Annotation ann;
    case (_,NONE()) then "";
    case (i,SOME(ann))
      equation
        s = unparseAnnotation(ann,i);
        res = stringAppend(s, ";");
      then
        res;
  end matchcontinue;
end unparseAnnotationOptionSemi;

public function unparseAnnotation
"Prettyprint an annotation."
  input Absyn.Annotation inAbsynAnnotation;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynAnnotation,inInteger)
    local
      String s1,s2,str,is;
      list<Absyn.ElementArg> mod;
      Integer i;
    case (Absyn.ANNOTATION(mod),0)
      equation
        s1 = unparseClassModificationStr(Absyn.CLASSMOD(mod,Absyn.NOMOD()));
        s2 = stringAppend(" annotation", s1);
        str = s2;
      then
        str;
    case (Absyn.ANNOTATION(mod),i)
      equation
        s1 = unparseClassModificationStr(Absyn.CLASSMOD(mod,Absyn.NOMOD()));
        is = indentStr(i);
        str = stringAppendList({is,"annotation",s1});
      then
        str;
  end matchcontinue;
end unparseAnnotation;

public function unparseAnnotationOption
"Prettyprint an annotation."
  input Integer i;
  input Option<Absyn.Annotation> inAbsynAnnotation;
  output String outString;
algorithm
  outString := match (i,inAbsynAnnotation)
    local
      Absyn.Annotation ann;
    case (_,SOME(ann)) then unparseAnnotation(ann,i);
    else "";
  end match;
end unparseAnnotationOption;

protected function printElement "
  Prints an Element to the Print buffer.
  changed by adrpo, 2006-02-06 to use print_info and dump Absyn.TEXT also
"
  input Absyn.Element inElement;
algorithm
  _:=
  match (inElement)
    local
      Boolean finalPrefix;
      Option<Absyn.RedeclareKeywords> repl;
      Absyn.InnerOuter inout;
      String name,text;
      Absyn.ElementSpec spec;
      Absyn.Info info;
    case (Absyn.ELEMENT(finalPrefix = finalPrefix,redeclareKeywords = repl,innerOuter = inout,
                        specification = spec,info = info,constrainClass = NONE()))
      equation
        Print.printBuf("Absyn.ELEMENT(");
        printBool(finalPrefix);
        Print.printBuf(", _");
        Print.printBuf(", ");
        printInnerouter(inout);
        Print.printBuf(", ");
        printElementspec(spec);
        Print.printBuf(", ");
        printInfo(info);
        Print.printBuf("),NONE())");
      then
        ();
    case (Absyn.ELEMENT(finalPrefix = finalPrefix,redeclareKeywords = repl,innerOuter = inout,
                        specification = spec,info = info,constrainClass = SOME(_)))
      equation
        Print.printBuf("Absyn.ELEMENT(");
        printBool(finalPrefix);
        Print.printBuf(", _");
        Print.printBuf(", ");
        printInnerouter(inout);
        Print.printBuf(",");
        printElementspec(spec);
        Print.printBuf(", ");
        printInfo(info);
        Print.printBuf(", SOME(...))");
      then
        ();
    case (Absyn.TEXT(optName = SOME(name),string = text,info = info))
      equation
        Print.printBuf("Absyn.TEXT(");
        Print.printBuf("SOME(\"");
        Print.printBuf(name);
        Print.printBuf("\"), \"");
        Print.printBuf(text);
        Print.printBuf("\", ");
        printInfo(info);
        Print.printBuf(")");
      then
        ();
    case (Absyn.TEXT(optName = NONE(),string = text,info = info))
      equation
        Print.printBuf("Absyn.TEXT(");
        Print.printBuf("NONE, \"");
        Print.printBuf(text);
        Print.printBuf("\", ");
        printInfo(info);
        Print.printBuf(")");
      then
        ();
  end match;
end printElement;

public function unparseElementStr "
  Prettyprints and Element to a string.
  changed by adrpo 2006-02-05 to print also Absyn.TEXT as a comment
  TODO?? - should we also dump info as a comment for an element??
         - should we dump Absyn.TEXT as an Annotation Item??
"
  input Integer inInteger;
  input Absyn.Element inElement;
  output String outString;
algorithm
  outString := match (inInteger,inElement)
    local
      String s1,s2,s3,s4,s5,str,name,text;
      Integer i;
      Boolean finalPrefix;
      Absyn.RedeclareKeywords repl;
      Absyn.InnerOuter inout;
      Absyn.ElementSpec spec;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      list<Absyn.NamedArg> nargs;
      tuple<String,String> redeclareKeywords;

    case (i,Absyn.ELEMENT(finalPrefix = finalPrefix,redeclareKeywords = SOME(repl),innerOuter = inout,specification = spec,info = info,constrainClass = constr))
      equation
        s1 = selectString(finalPrefix, "final ", "");
        redeclareKeywords = unparseRedeclarekeywords(repl);
        s3 = unparseInnerouterStr(inout);
        s4 = unparseElementspecStr(i, spec, s1, redeclareKeywords, s3);
        s5 = unparseConstrainclassOptStr(constr);
        str = stringAppendList({s4,s5,";"});
      then
        str;
    case (i,Absyn.ELEMENT(finalPrefix = finalPrefix,redeclareKeywords = NONE(),innerOuter = inout,specification = spec,info = info,constrainClass = constr))
      equation
        s1 = selectString(finalPrefix, "final ", "");
        s3 = unparseInnerouterStr(inout);
        s4 = unparseElementspecStr(i, spec, s1, ("",""), s3);
        s5 = unparseConstrainclassOptStr(constr);
        str = stringAppendList({s4,s5,";"});
      then
        str;
    case(i,Absyn.DEFINEUNIT(name,{})) equation
      s1 = indentStr(i)+&"defineunit "+&name+&";";
    then s1;

    case(i,Absyn.DEFINEUNIT(name,nargs)) equation
      s1 = printListStr(nargs, printNamedArgStr, ", ");
      s2 = indentStr(i)+&"defineunit "+&name+&" ("+&s1+&");";
    then s2;

    case (i,Absyn.TEXT(optName = SOME(name),string = text,info = info))
      equation
        s1 = unparseInfoStr(info);
        str = stringAppendList(
          {"/* Absyn.TEXT(SOME(\"",name,"\"), \"",text,"\", ",s1,
          "); */"});
      then
        str;
    case (i,Absyn.TEXT(optName = NONE(),string = text,info = info))
      equation
        s1 = unparseInfoStr(info);
        str = stringAppendList({"/* Absyn.TEXT(NONE(), \"",text,"\", ",s1,"); */"});
      then
        str;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Dump.unparseElementStr"});
      then fail();
  end match;
end unparseElementStr;

protected function unparseConstrainclassOptStr
"author: PA
  This function prettyprints a ConstrainClass option to a string."
  input Option<Absyn.ConstrainClass> inAbsynConstrainClassOption;
  output String outString;
algorithm
  outString:=
  match (inAbsynConstrainClassOption)
    local
      String res;
      Absyn.ConstrainClass constr;
    case (NONE()) then "";
    case (SOME(constr))
      equation
        res = " " +& unparseConstrainclassStr(constr);
      then
        res;
  end match;
end unparseConstrainclassOptStr;

public function unparseConstrainclassStr
"author: PA
  This function prettyprints a ConstrainClass to a string."
  input Absyn.ConstrainClass inConstrainClass;
  output String outString;
algorithm
  outString:=
  match (inConstrainClass)
    local
      String res;
      Option<Absyn.Comment> cmt;
      Absyn.Path path;
      list<Absyn.ElementArg> el;
      String path_str, el_str, cmt_str;

    case (Absyn.CONSTRAINCLASS(elementSpec =
        Absyn.EXTENDS(path = path, elementArg = el), comment = cmt))
      equation
        path_str = Absyn.pathString(path);
        cmt_str = unparseCommentOption(cmt);
        el_str = getStringList(el, unparseElementArgStr, ", ");
        el_str = Util.if_(Util.isEmptyString(el_str), el_str, "(" +& el_str +& ")");
        res = stringAppendList({"constrainedby ", path_str, el_str, cmt_str});
      then
        res;
  end match;
end unparseConstrainclassStr;

protected function printInnerouter
"Prints the inner or outer keyword to the Print buffer."
  input Absyn.InnerOuter inInnerOuter;
algorithm
  _:=
  match (inInnerOuter)
    case (Absyn.INNER())
      equation
        Print.printBuf("Absyn.INNER");
      then
        ();
    case (Absyn.OUTER())
      equation
        Print.printBuf("Absyn.OUTER");
      then
        ();
    case (Absyn.INNER_OUTER())
      equation
        Print.printBuf("Absyn.INNER_OUTER ");
      then
        ();
    case (Absyn.NOT_INNER_OUTER())
      equation
        Print.printBuf("Absyn.NOT_INNER_OUTER ");
      then
        ();
  end match;
end printInnerouter;

public function unparseInnerouterStr "
  Prettyprints the inner or outer keyword to a string.
"
  input Absyn.InnerOuter inInnerOuter;
  output String outString;
algorithm
  outString:=
  match (inInnerOuter)
    case (Absyn.INNER()) then "inner ";
    case (Absyn.OUTER()) then "outer ";
    case (Absyn.INNER_OUTER()) then "inner outer ";
    case (Absyn.NOT_INNER_OUTER()) then "";
  end match;
end unparseInnerouterStr;

function unparseElementPrefixKeywords
"adrpo: BEWARE! the prefix keywords HAVE TO BE IN A SPECIFIC ORDER:
 ([final] | [redeclare] [final] [inner] [outer]) [replaceable] followed by:
 - class:    [encapsulated] [partial] [restriction] name
 - component
 For the component give empty encapsulated and partial strings to this function.
 if the order is not the one above on re-parse will give errors!"
  input tuple<String,String> redeclareKeywords;
  input String finalStr;
  input String innerouterStr;
  input String encapsulatedStr;
  input String partialStr;
  output String prefixKeywords;
  protected
    String redeclareStr,replaceableStr;
algorithm
   (redeclareStr,replaceableStr) := redeclareKeywords;
   prefixKeywords := redeclareStr +& finalStr +& innerouterStr +& replaceableStr +& encapsulatedStr +& partialStr;
end unparseElementPrefixKeywords;

public function printElementspec
"Prints the ElementSpec to the Print buffer."
  input Absyn.ElementSpec inElementSpec;
algorithm
  _:=
  matchcontinue (inElementSpec)
    local
      Boolean repl;
      Absyn.Class cl;
      Absyn.Path p;
      list<Absyn.ElementArg> l;
      String s;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec t;
      list<Absyn.ComponentItem> cs;
      Absyn.Import i;
      Absyn.Annotation ann;

    case (Absyn.CLASSDEF(replaceable_ = repl,class_ = cl))
      equation
        Print.printBuf("Absyn.CLASSDEF(");
        printBool(repl);
        Print.printBuf(", ");
        printClass(cl);
        Print.printBuf(")");
      then
        ();
    case (Absyn.EXTENDS(path = p,elementArg = l,annotationOpt=SOME(ann)))
      equation
        Print.printBuf("Absyn.EXTENDS(");
        dumpPath(p);
        Print.printBuf(", [");
        printListDebug("print_elementspec", l, printElementArg, ",");
        printAnnotation(ann);
        Print.printBuf("])");
      then
        ();
    case (Absyn.EXTENDS(path = p,elementArg = l,annotationOpt=NONE()))
      equation
        Print.printBuf("Absyn.EXTENDS(");
        dumpPath(p);
        Print.printBuf(", [");
        printListDebug("print_elementspec", l, printElementArg, ",");
        Print.printBuf("])");
      then
        ();
    case (Absyn.COMPONENTS(attributes = attr,typeSpec = t,components = cs))
      equation
        Print.printBuf("Absyn.COMPONENTS(");
        printElementattr(attr);
        Print.printBuf(",");
        s = unparseTypeSpec(t);
        Print.printBuf(s);
        Print.printBuf(",[");
        printListDebug("print_elementspec", cs, printComponentitem, ",");
        Print.printBuf("])");
      then
        ();
    case (Absyn.IMPORT(import_ = i))
      equation
        Print.printBuf("Absyn.IMPORT(");
        printImport(i);
        Print.printBuf(")");
      then
        ();
    case (_)
      equation
        Print.printBuf(" ##ERROR## ");
      then
        ();
  end matchcontinue;
end printElementspec;

protected function unparseElementspecStr
"Prettyprints the ElementSpec to a string."
  input Integer indent "indent";
  input Absyn.ElementSpec elementSpec "element specification";
  input String finalStr;
  input tuple<String,String> redeclareKeywords "redeclare replaceable";
  input String innerouterKeywords;
  output String outString;
algorithm
  outString:=
  matchcontinue (indent,elementSpec,finalStr,redeclareKeywords,innerouterKeywords)
    local
      String str,f,io,s1,s2,is,s3,ad,s4;
      tuple<String,String> r;
      Integer i;
      Boolean repl;
      Absyn.Class cl;
      Absyn.Path p;
      list<Absyn.ElementArg> l;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec t;
      list<Absyn.ComponentItem> cs;
      String prefixKeywords;
      Option<Absyn.Annotation> annOpt;
      Absyn.Import imp;

    case (i,Absyn.CLASSDEF(replaceable_ = repl,class_ = cl),f,r,io) /* indent */
      equation
        str = unparseClassStr(i, cl, f, r, io);
      then
        str;

    case (i,Absyn.EXTENDS(path = p,elementArg = {},annotationOpt=annOpt),f,r,io)
      equation
        s1 = Absyn.pathString(p);
        s2 = stringAppend("extends ", s1);
        is = indentStr(i);
        s3 = unparseAnnotationOption(0, annOpt);
        // adrpo: NOTE final, replaceable/redeclare, inner/outer should NOT be used for extends!
        str = stringAppendList({is,s2,s3});
      then
        str;

    case (i,Absyn.EXTENDS(path = p,elementArg = l,annotationOpt=annOpt),f,r,io)
      equation
        s1 = Absyn.pathString(p);
        s2 = stringAppend("extends ", s1);
        s3 = getStringList(l, unparseElementArgStr, ", ");
        is = indentStr(i);
        s4 = unparseAnnotationOption(0, annOpt);
        // adrpo: NOTE final, replaceable/redeclare, inner/outer should NOT be used for extends!
        str = stringAppendList({is,s2,"(",s3,")",s4});
      then
        str;

    case (i,Absyn.COMPONENTS(attributes = attr,typeSpec = t,components = cs),f,r,io)
      equation
        s1 = unparseTypeSpec(t);
        s2 = unparseElementattrStr(attr);
        ad = unparseArraydimInAttr(attr);
        s3 = getStringList(cs, unparseComponentitemStr, ",");
        is = indentStr(i);
        prefixKeywords = unparseElementPrefixKeywords(r, f, io, "", "");
        str = stringAppendList({is,prefixKeywords,s2,s1,ad," ",s3});
      then
        str;

    case (i,Absyn.IMPORT(import_ = imp),f,r,io)
      equation
        s1 = unparseImportStr(imp);
        s2 = stringAppend("import ", s1);
        is = indentStr(i);
        // adrpo: NOTE final, replaceable/redeclare, inner/outer should NOT be used for import!
        str = stringAppendList({is,s2});
      then
        str;

    case (_,_,_,_,_)
      equation
        Print.printBuf(" ##ERROR## ");
      then
        "";
  end matchcontinue;
end unparseElementspecStr;

public function printImport
"Prints an Import to the Print buffer."
  input Absyn.Import inImport;
algorithm
  _ := match (inImport)
    local
      String i;
      Absyn.Path p;
      list<Absyn.GroupImport> groups;

    case (Absyn.NAMED_IMPORT(name = i,path = p))
      equation
        Print.printBuf(i);
        Print.printBuf(" = ");
        printPath(p);
      then
        ();

    case (Absyn.QUAL_IMPORT(path = p))
      equation
        printPath(p);
      then
        ();

    case (Absyn.UNQUAL_IMPORT(path = p))
      equation
        printPath(p);
        Print.printBuf(".*");
      then
        ();
    case (Absyn.GROUP_IMPORT(prefix = p, groups = groups))
      equation
        printPath(p);
        Print.printBuf(".{");
        Print.printBuf(stringDelimitList(List.map(groups, unparseGroupImport), ","));
        Print.printBuf("}");
      then
        ();
    else
      equation
        Print.printBuf("/* Unknown import */");
      then
        ();
  end match;
end printImport;

protected function unparseGroupImport
  input Absyn.GroupImport gimp;
  output String str;
algorithm
  str := match gimp
    local
      String name,rename;
    case Absyn.GROUP_IMPORT_NAME(name=name) then name;
    case Absyn.GROUP_IMPORT_RENAME(rename=rename,name=name)
      then rename +& " = " +& name;
  end match;
end unparseGroupImport;

public function unparseImportStr
"Prettyprints an Import to a string."
  input Absyn.Import inImport;
  output String outString;
algorithm
  outString := match (inImport)
    local
      String s1,s2,str,i;
      Absyn.Path p;
      list<Absyn.GroupImport> groups;

    case (Absyn.NAMED_IMPORT(name = i,path = p))
      equation
        s1 = stringAppend(i, " = ");
        s2 = Absyn.pathString(p);
        str = stringAppend(s1, s2);
      then
        str;

    case (Absyn.QUAL_IMPORT(path = p))
      equation
        str = Absyn.pathString(p);
      then
        str;

    case (Absyn.UNQUAL_IMPORT(path = p))
      equation
        s1 = Absyn.pathString(p);
        str = stringAppend(s1, ".*");
      then
        str;

    case (Absyn.GROUP_IMPORT(prefix = p, groups = groups))
      equation
        s1 = Absyn.pathString(p);
        s2 = stringDelimitList(List.map(groups, unparseGroupImport), ",");
        str = stringAppendList({s1,".{",s2,"}"});
      then
        str;

    else "/* Unknown import */";
  end match;
end unparseImportStr;

protected function printElementattr "Prints ElementAttributes to the Print buffer."
  input Absyn.ElementAttributes inElementAttributes;
algorithm
  _ := matchcontinue (inElementAttributes)
    local
      String vs,ds;
      Boolean fl,st;
      Absyn.Variability var;
      Absyn.Direction dir;
      list<Absyn.Subscript> adim;

    case (Absyn.ATTR(flowPrefix = fl,streamPrefix=st,variability = var,direction = dir,arrayDim = adim))
      equation
        Print.printBuf("Absyn.ATTR(");
        printBool(fl);
        Print.printBuf(", ");
        printBool(st);
        Print.printBuf(", ");
        vs = variabilitySymbol(var);
        Print.printBuf(vs);
        Print.printBuf(", ");
        ds = directionSymbol(dir);
        Print.printBuf(ds);
        Print.printBuf(", ");
        printArraydim(adim);
        Print.printBuf(")");
      then
        ();

    case (_)
      equation
        Print.printBuf(" ##ERROR## print_elementattr");
      then
        ();
  end matchcontinue;
end printElementattr;

protected function unparseElementattrStr "
  Prettyprints ElementAttributes to a string.
"
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  matchcontinue (inElementAttributes)
    local
      String fs,ss,vs,ds,str;
      Boolean fl,st;
      Absyn.Variability var;
      Absyn.Direction dir;
      list<Absyn.Subscript> adim;
    case (Absyn.ATTR(flowPrefix = fl,streamPrefix=st,variability = var,direction = dir,arrayDim = adim))
      equation
        fs = selectString(fl, "flow ", "");
        ss = selectString(st, "stream ", "");
        vs = unparseVariabilitySymbolStr(var);
        ds = unparseDirectionSymbolStr(dir);
        str = stringAppendList({fs,ss,vs,ds});
      then
        str;
    case (_)
      equation
        Print.printBuf(" ##ERROR## unparse_elementattr_str");
      then
        "";
  end matchcontinue;
end unparseElementattrStr;

protected function unparseArraydimInAttr "
  Prettyprints the arraydimension in ElementAttributes to a string.
"
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  matchcontinue (inElementAttributes)
    local
      String str;
      list<Absyn.Subscript> adim;
    case (Absyn.ATTR(arrayDim = adim))
      equation
        str = printArraydimStr(adim);
      then
        str;
    case (_) then "";
  end matchcontinue;
end unparseArraydimInAttr;

public function variabilitySymbol "
  Returns a string for the Variability.
"
  input Absyn.Variability inVariability;
  output String outString;
algorithm
  outString:=
  match (inVariability)
    case (Absyn.VAR()) then "Absyn.VAR";
    case (Absyn.DISCRETE()) then "Absyn.DISCRETE";
    case (Absyn.PARAM()) then "Absyn.PARAM";
    case (Absyn.CONST()) then "Absyn.CONST";
  end match;
end variabilitySymbol;

public function directionSymbol "
  Returns a string for the direction.
"
  input Absyn.Direction inDirection;
  output String outString;
algorithm
  outString:=
  match (inDirection)
    case (Absyn.BIDIR()) then "Absyn.BIDIR";
    case (Absyn.INPUT()) then "Absyn.INPUT";
    case (Absyn.OUTPUT()) then "Absyn.OUTPUT";
  end match;
end directionSymbol;

protected function unparseVariabilitySymbolStr "
  Returns a prettyprinted string of variability.
"
  input Absyn.Variability inVariability;
  output String outString;
algorithm
  outString:=
  match (inVariability)
    case (Absyn.VAR()) then "";
    case (Absyn.DISCRETE()) then "discrete ";
    case (Absyn.PARAM()) then "parameter ";
    case (Absyn.CONST()) then "constant ";
  end match;
end unparseVariabilitySymbolStr;

public function unparseDirectionSymbolStr "Returns a prettyprinted string of direction."
  input Absyn.Direction inDirection;
  output String outString;
algorithm
  outString:=
  match (inDirection)
    case (Absyn.BIDIR()) then "";
    case (Absyn.INPUT()) then "input ";
    case (Absyn.OUTPUT()) then "output ";
  end match;
end unparseDirectionSymbolStr;

public function unparseParallelismSymbolStr
  input Absyn.Parallelism inParallelism;
  output String outString;
algorithm
  outString:=
  match (inParallelism)
    case (Absyn.NON_PARALLEL()) then "";
    case (Absyn.PARGLOBAL()) then "parglobal ";
    case (Absyn.PARLOCAL()) then "parlocal ";
  end match;
end unparseParallelismSymbolStr;

public function printComponent "Prints a Component to the Print buffer."
  input Absyn.Component inComponent;
algorithm
  _ := match (inComponent)
    local
      String n;
      list<Absyn.Subscript> a;
      Option<Absyn.Modification> m;
    case (Absyn.COMPONENT(name = n,arrayDim = a,modification = m))
      equation
        Print.printBuf("Absyn.COMPONENT(\"");
        Print.printBuf(n);
        Print.printBuf("\",");
        printArraydim(a);
        Print.printBuf(", ");
        printOption(m, printModification);
        Print.printBuf(")");
      then
        ();
  end match;
end printComponent;

protected function printComponentitem "Prints a ComponentItem to the Print buffer."
  input Absyn.ComponentItem inComponentItem;
algorithm
  _ := match (inComponentItem)
    local
      Absyn.Component c;
      Option<Absyn.Exp> optcond;
      Option<Absyn.Comment> optcmt;
    case (Absyn.COMPONENTITEM(component = c,condition = optcond,comment = optcmt))
      equation
        Print.printBuf("Absyn.COMPONENTITEM(");
        printComponent(c);
        Print.printBuf(", ");
        dumpCommentOption(optcmt);
        Print.printBuf(")");
      then
        ();
  end match;
end printComponentitem;

protected function unparseComponentStr "
  Prettyprints a Component to a string.
"
  input Absyn.Component inComponent;
  output String outString;
algorithm
  outString:=
  match (inComponent)
    local
      String s1,s2,s3,str,n;
      list<Absyn.Subscript> a;
      Option<Absyn.Modification> m;
    case (Absyn.COMPONENT(name = n,arrayDim = a,modification = m))
      equation
        s1 = printArraydimStr(a);
        s2 = stringAppend(n, s1);
        s3 = getOptionStr(m, unparseModificationStr);
        str = stringAppend(s2, s3);
      then
        str;
  end match;
end unparseComponentStr;

public function unparseComponentitemStr "Prettyprints a ComponentItem to a string."
  input Absyn.ComponentItem inComponentItem;
  output String outString;
algorithm
  outString := match (inComponentItem)
    local
      String s1,s3,s2,str;
      Absyn.Component c;
      Option<Absyn.Exp> optcond;
      Option<Absyn.Comment> cmtopt;
    case (Absyn.COMPONENTITEM(component = c,condition = optcond,comment = cmtopt))
      equation
        s1 = unparseComponentStr(c);
        s2 = unparseComponentCondition(optcond);
        s3 = unparseCommentOption(cmtopt);
        str = stringAppendList({s1,s2,s3});
      then
        str;
  end match;
end unparseComponentitemStr;

public function unparseComponentCondition "Prints a ComponentCondition option to a string."
  input Option<Absyn.ComponentCondition> inAbsynComponentConditionOption;
  output String outString;
algorithm
  outString := match (inAbsynComponentConditionOption)
    local
      String s1,res;
      Absyn.Exp cond;
    case (SOME(cond))
      equation
        s1 = printExpStr(cond);
        res = stringAppend(" if ", s1);
      then
        res;
    case (NONE()) then "";
  end match;
end unparseComponentCondition;

protected function printArraydimOpt "
  Prints an ArrayDim option to the Print buffer.
"
  input Option<Absyn.ArrayDim> inAbsynArrayDimOption;
algorithm
  _:=
  matchcontinue (inAbsynArrayDimOption)
    local list<Absyn.Subscript> s;
    case (NONE())
      equation
        Print.printBuf("NONE()");
      then
        ();
    case (SOME(s))
      equation
        Print.printBuf("SOME(");
        printSubscripts(s);
        Print.printBuf(")");
      then
        ();
  end matchcontinue;
end printArraydimOpt;

public function printArraydim "
  Prints an ArrayDim to the Print buffer.
"
  input Absyn.ArrayDim s;
algorithm
  printSubscripts(s);
end printArraydim;

public function printArraydimStr "
  Prettyprints an ArrayDim to a string.
"
  input Absyn.ArrayDim s;
  output String str;
algorithm
  str := printSubscriptsStr(s);
end printArraydimStr;

protected function printSubscript "
  Prints an Subscript to the Print buffer.
"
  input Absyn.Subscript inSubscript;
algorithm
  _:=
  match (inSubscript)
    local Absyn.Exp e1;
    case (Absyn.NOSUB())
      equation
        Print.printBuf("Absyn.NOSUB");
      then
        ();
    case (Absyn.SUBSCRIPT(subscript = e1))
      equation
        Print.printBuf("Absyn.SUBSCRIPT(");
        printExp(e1);
        Print.printBuf(")");
      then
        ();
  end match;
end printSubscript;

public function printSubscriptStr "
  Prettyprints an Subscript to a string.
"
  input Absyn.Subscript inSubscript;
  output String outString;
algorithm
  outString:=
  match (inSubscript)
    local
      String s;
      Absyn.Exp e1;
    case (Absyn.NOSUB()) then ":";
    case (Absyn.SUBSCRIPT(subscript = e1))
      equation
        s = printExpStr(e1);
      then
        s;
  end match;
end printSubscriptStr;

protected function printOptModification "
  Prints a Modification option to the Print buffer.
"
  input Option<Absyn.Modification> inAbsynModificationOption;
algorithm
  _:=
  match (inAbsynModificationOption)
    local Absyn.Modification m;
    case (SOME(m))
      equation
        Print.printBuf("SOME(");
        printModification(m);
        Print.printBuf(")");
      then
        ();
    case (NONE()) then ();
  end match;
end printOptModification;

protected function printModification "
  Prints a Modification to the Print buffer.
"
  input Absyn.Modification inModification;
algorithm
  _:=
  matchcontinue (inModification)
    local
      list<Absyn.ElementArg> l;
      Absyn.EqMod e;
    case (Absyn.CLASSMOD(elementArgLst = l,eqMod = e))
      equation
        Print.printBuf("Absyn.CLASSMOD([");
        printMod1(l);
        Print.printBuf("], ");
        printMod2(e);
        Print.printBuf(")");
      then
        ();
    case (_)
      equation
        Print.printBuf("( ** MODIFICATION ** )");
      then
        ();
  end matchcontinue;
end printModification;

protected function printMod1 "
  Helper relaton to print_modification.
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
algorithm
  _:=
  matchcontinue (inAbsynElementArgLst)
    local list<Absyn.ElementArg> l;
    case {} then ();
    case l
      equation
        Print.printBuf("(");
        printListDebug("print_mod1", l, printElementArg, ",");
        Print.printBuf(")");
      then
        ();
  end matchcontinue;
end printMod1;

protected function printMod2 "
  Helper relaton to print_mod1
"
  input Absyn.EqMod inAbsynExpOption;
algorithm
  _:=
  match (inAbsynExpOption)
    local Absyn.Exp e;
    case Absyn.NOMOD()
      equation
        Print.printBuf("Absyn.NOMOD()");
      then
        ();
    case Absyn.EQMOD(exp=e)
      equation
        Print.printBuf("Absyn.EQMOD([");
        printExp(e);
        Print.printBuf("])");
      then
        ();
  end match;
end printMod2;

public function unparseOptModificationStr "
  Prettyprints a Modification option to a string.
"
  input Option<Absyn.Modification> inAbsynModificationOption;
  output String outString;
algorithm
  outString:=
  match (inAbsynModificationOption)
    local
      String str;
      Absyn.Modification opt;
    case (SOME(opt))
      equation
        str = unparseModificationStr(opt);
      then
        str;
    case (NONE()) then "";
  end match;
end unparseOptModificationStr;

public function unparseModificationStr "
  Prettyprints a Modification to a string.
"
  input Absyn.Modification inModification;
  output String outString;
algorithm
  outString:=
  matchcontinue (inModification)
    local
      String s1,s2,str;
      list<Absyn.ElementArg> l;
      Absyn.EqMod eqMod;
    case (Absyn.CLASSMOD(elementArgLst = {},eqMod = Absyn.NOMOD())) then "()";  /* Special case for empty modifications */
    case (Absyn.CLASSMOD(elementArgLst = l,eqMod = eqMod))
      equation
        s1 = unparseMod1Str(l);
        s2 = unparseMod2Str(eqMod);
        str = stringAppend(s1, s2);
      then
        str;
    case (_)
      equation
        Print.printBuf(" Failure MODIFICATION \n");
      then
        "";
  end matchcontinue;
end unparseModificationStr;

public function unparseMod1Str "
  Helper function to unparse_modification_str
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynElementArgLst)
    local
      String s1,s2,str;
      list<Absyn.ElementArg> l;
    case {} then "";
    case l
      equation
        s1 = getStringList(l, unparseElementArgStr, ", ");
        s2 = stringAppend("(", s1);
        str = stringAppend(s2, ")");
      then
        str;
  end matchcontinue;
end unparseMod1Str;

protected function unparseMod2Str "
  Helper function to unparse_mod1_str
"
  input Absyn.EqMod eqMod;
  output String outString;
algorithm
  outString := match eqMod
    local
      String s1,str;
      Absyn.Exp e;
    case Absyn.NOMOD() then "";
    case Absyn.EQMOD(exp=e)
      equation
        s1 = printExpStr(e);
        str = stringAppend(" = ", s1);
      then
        str;
  end match;
end unparseMod2Str;

public function equationName
  input Absyn.Equation eq;
  output String name;
algorithm
  name := match eq
    case Absyn.EQ_IF(ifExp = _) then "if";
    case Absyn.EQ_EQUALS(leftSide = _) then "equals";
    case Absyn.EQ_CONNECT(connector1 = _) then "connect";
    case Absyn.EQ_WHEN_E(whenExp = _) then "when";
    case Absyn.EQ_NORETCALL(functionName = _) then "function call";
    case Absyn.EQ_FAILURE(equ = _) then "failure";
  end match;
end equationName;

public function printEquation "Equations
  function: printEquation
  Prints an Equation to the Print buffer."
  input Absyn.Equation inEquation;
algorithm
  _ := matchcontinue (inEquation)
    local
      Absyn.Exp e,e1,e2;
      list<Absyn.EquationItem> tb,fb,el;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> eb;
      Absyn.ForIterators iterators;
      Absyn.EquationItem equItem;
      Absyn.ComponentRef cr;
      Absyn.FunctionArgs fargs;
      Absyn.ComponentRef cr1,cr2;

    case (Absyn.EQ_IF(ifExp = e,equationTrueItems = tb,elseIfBranches = eb,equationElseItems = fb))
      equation
        Print.printBuf("IF (");
        printExp(e);
        Print.printBuf(") THEN ");
        printListDebug("print_equation", tb, printEquationitem, ";");
        printListDebug("print_equation", eb, printEqElseif, " ");
        Print.printBuf(" ELSE ");
        printListDebug("print_equation", fb, printEquationitem, ";");
      then
        ();

    case (Absyn.EQ_EQUALS(leftSide = e1,rightSide = e2))
      equation
        Print.printBuf("EQ_EQUALS(");
        printExp(e1);
        Print.printBuf(",");
        printExp(e2);
        Print.printBuf(")");
      then
        ();

    case (Absyn.EQ_NORETCALL(functionName = cr,functionArgs = fargs)) /* EQ_NORETCALL */
      equation
        Print.printBuf("EQ_NORETCALL(");
        Print.printBuf(printComponentRefStr(cr) +& "(");
        Print.printBuf(printFunctionArgsStr(fargs));
        Print.printBuf(")");
      then
        ();

    case (Absyn.EQ_CONNECT(connector1 = cr1,connector2 = cr2))
      equation
        Print.printBuf("EQ_CONNECT(");
        printComponentRef(cr1);
        Print.printBuf(",");
        printComponentRef(cr2);
        Print.printBuf(")");
      then
        ();

    case Absyn.EQ_FOR(iterators=iterators,forEquations = el)
      equation
        Print.printBuf("FOR ");
        printListDebug("print_iterators", iterators, printIterator, ", ");
        Print.printBuf(" {");
        printListDebug("print_equation", el, printEquationitem, ";");
        Print.printBuf("}");
      then
        ();

    case Absyn.EQ_FAILURE(equItem)
      equation
        Print.printBuf("FAILURE(");
        printEquationitem(equItem);
        Print.printBuf(")");
      then
        ();

    case (_)
      equation
        Print.printBuf(" ** UNKNOWN EQUATION ** ");
      then
        ();
  end matchcontinue;
end printEquation;

protected function printEquationitem "Prints and EquationItem to the Print buffer."
  input Absyn.EquationItem inEquationItem;
algorithm
  _ := match (inEquationItem)
    local
      Absyn.Equation eq;

    case Absyn.EQUATIONITEM(equation_ = eq)
      equation
        Print.printBuf("EQUATIONITEM(");
        printEquation(eq);
        Print.printBuf(", <comment>)\n");
      then
        ();

  end match;
end printEquationitem;

public function unparseEquationStr
"Prettyprints an Equation to a string."
  input Integer inInteger;
  input Absyn.Equation inEquation;
  output String outString;
algorithm
  outString := matchcontinue (inInteger,inEquation)
    local
      String s1,s2,is,str,s3,s4,id;
      Absyn.ComponentRef cref,cr1,cr2;
      Integer i_1,i;
      Absyn.Exp e,e1,e2,exp;
      Absyn.ForIterators iterators;
      list<Absyn.EquationItem> tb,fb,el,eql;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> eb,eqlelse;
      Absyn.FunctionArgs fargs;
      Absyn.EquationItem equItem;

    case (i,Absyn.EQ_IF(ifExp = e,equationTrueItems = tb,elseIfBranches = {},equationElseItems = {}))
      equation
        s1 = printExpStr(e);
        i_1 = i + 1;
        s2 = unparseEquationitemStrLst(i_1, tb, "\n");
        is = indentStr(i);
        str = stringAppendList({is,"if ",s1," then\n",s2,is,"end if"});
      then
        str;

    case (i,Absyn.EQ_IF(ifExp = e,equationTrueItems = tb,elseIfBranches = eb,equationElseItems = fb))
      equation
        s1 = printExpStr(e);
        i_1 = i + 1;
        s2 = unparseEquationitemStrLst(i_1, tb, "\n");
        s3 = unparseEqElseifStrLst(i_1, eb, "\n");
        s4 = unparseEquationitemStrLst(i_1, fb, "\n");
        is = indentStr(i);
        str = stringAppendList(
          {is,"if ",s1," then\n",s2,s3,is,"else\n",s4,is, "end if"});
      then
        str;

    case (i,Absyn.EQ_EQUALS(leftSide = e1,rightSide = e2))
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        is = indentStr(i);
        str = stringAppendList({is,s1," = ",s2});
      then
        str;

    case (i,Absyn.EQ_CONNECT(connector1 = cr1,connector2 = cr2))
      equation
        s1 = printComponentRefStr(cr1);
        s2 = printComponentRefStr(cr2);
        is = indentStr(i);
        str = stringAppendList({is,"connect(",s1,",",s2,")"});
      then
        str;

    case (i,Absyn.EQ_FOR(iterators = iterators,forEquations = el))
      equation
        s1 = printIteratorsStr(iterators);
        s2 = unparseEquationitemStrLst(i, el, "\n");
        is = indentStr(i);
        str = stringAppendList({is,"for ",s1," loop\n",s2,"\n",is,"end for"});
      then
        str;

    case (i,Absyn.EQ_NORETCALL(functionName = cref,functionArgs = fargs))
      equation
        s2 = printFunctionArgsStr(fargs);
        id = printComponentRefStr(cref);
        is = indentStr(i);
        str = stringAppendList({is, id,"(",s2,")"});
      then
        str;

    case (i,Absyn.EQ_WHEN_E(whenExp = exp,whenEquations = eql,elseWhenEquations = eqlelse))
      equation
        s1 = printExpStr(exp);
        i_1 = i + 1;
        s2 = unparseEquationitemStrLst(i_1, eql, "\n");
        is = indentStr(i);
        s4 = unparseEqElsewhenStrLst(i_1, eqlelse);
        str = stringAppendList({is,"when ",s1," then\n",is,s2,is,s4,"\n",is,"end when"});
      then
        str;

    case (i,Absyn.EQ_FAILURE(equItem))
      equation
        s1 = unparseEquationitemStr(0, equItem);
        is = indentStr(i);
        str = stringAppendList({is,"failure(",s1,")"});
      then
        str;

    case (_,_)
      equation
        Print.printBuf(" /** Dump.unparseEquationStr Failure! UNKNOWN EQUATION **/ ");
      then
        "";
  end matchcontinue;
end unparseEquationStr;

public function unparseEquationitemStrLst "function:unparseEquationitemStrLst
  Prettyprints and EquationItem list to a string."
  input Integer inInteger;
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  input String inString;
  output String outString;
algorithm
  outString := match (inInteger,inAbsynEquationItemLst,inString)
    local
      String s1,s2,res,sep;
      Integer i;
      Absyn.EquationItem x;
      list<Absyn.EquationItem> xs;

    case (_,{},_) then "";  /* indent */

    case (i,(x :: xs),sep)
      equation
        s1 = unparseEquationitemStr(i, x);
        s2 = unparseEquationitemStrLst(i, xs, sep);
        res = stringAppendList({s1,sep,s2});
      then
        res;
  end match;
end unparseEquationitemStrLst;

public function unparseEquationitemStr "Prettyprints an EquationItem to a string."
  input Integer inInteger;
  input Absyn.EquationItem inEquationItem;
  output String outString;
algorithm
  outString := match (inInteger,inEquationItem)
    local
      String s1,s2,str;
      Integer i;
      Absyn.Equation eq;
      Option<Absyn.Comment> optcmt;
      Absyn.Annotation ann;

    case (i,Absyn.EQUATIONITEM(equation_ = eq,comment = optcmt))
      equation
        s1 = unparseEquationStr(i, eq);
        s2 = unparseCommentOption(optcmt);
        str = stringAppend(s1, s2);
      then
        str +& ";";

    case (i,Absyn.EQUATIONITEMCOMMENT(str))
      then indentStr(i) +& System.trimWhitespace(str);

  end match;
end unparseEquationitemStr;

protected function printEqElseif "Prints an Elseif branch to the Print buffer."
  input tuple<Absyn.Exp, list<Absyn.EquationItem>> inTplAbsynExpAbsynEquationItemLst;
algorithm
  _ := match (inTplAbsynExpAbsynEquationItemLst)
    local
      Absyn.Exp e;
      list<Absyn.EquationItem> el;

    case ((e,el))
      equation
        Print.printBuf(" ELSEIF ");
        printExp(e);
        Print.printBuf(" THEN ");
        printListDebug("print_eq_elseif", el, printEquationitem, ";");
      then
        ();
  end match;
end printEqElseif;

protected function unparseEqElseifStrLst "Prettyprints an elseif branch to a string."
  input Integer inInteger;
  input list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> inTplAbsynExpAbsynEquationItemLstLst;
  input String inString;
  output String outString;
algorithm
  outString := matchcontinue (inInteger,inTplAbsynExpAbsynEquationItemLstLst,inString)
    local
      String s1,res,sep,s2;
      Integer i;
      tuple<Absyn.Exp, list<Absyn.EquationItem>> x1,x,x2;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> xs;

    case (_,{},_) then "";

    case (i,{x1},sep)
      equation
        res = unparseEqElseifStr(i, x1);
      then
        res;

    case (i,(x :: (xs as (_ :: _))),sep)
      equation
        s2 = unparseEqElseifStrLst(i, xs, sep);
        s1 = unparseEqElseifStr(i, x);
        res = stringAppendList({s1,s2});
      then
        res;

    case (i,{x1,x2},sep)
      equation
        s1 = unparseEqElseifStr(i, x1);
        s2 = unparseEqElseifStr(i, x2);
        res = stringAppendList({s1,s2});
      then
        res;
  end matchcontinue;
end unparseEqElseifStrLst;

protected function unparseEqElseifStr "Helper function to unparseEqElseifStrLst"
  input Integer inInteger;
  input tuple<Absyn.Exp, list<Absyn.EquationItem>> inTplAbsynExpAbsynEquationItemLst;
  output String outString;
algorithm
  outString := match (inInteger,inTplAbsynExpAbsynEquationItemLst)
    local
      String s1,s2,is,res;
      Integer i_1,i;
      Absyn.Exp e;
      list<Absyn.EquationItem> el;

    case (i,(e,el))
      equation
        s1 = printExpStr(e);
        s2 = unparseEquationitemStrLst(i, el, "\n");
        i_1 = i - 1;
        is = indentStr(i_1);
        res = stringAppendList({is,"elseif ",s1," then\n",s2});
      then
        res;
  end match;
end unparseEqElseifStr;

public function printAlgorithmitem "Algorithm clauses
  function: printAlgorithmitem
  Prints an AlgorithmItem to the Print buffer."
  input Absyn.AlgorithmItem inAlgorithmItem;
algorithm
  _ := match (inAlgorithmItem)
    local
      Absyn.Algorithm alg;
      Absyn.Annotation ann;

    case (Absyn.ALGORITHMITEM(algorithm_ = alg))
      equation
        Print.printBuf("ALGORITHMITEM(");
        printAlgorithm(alg);
        Print.printBuf(")\n");
      then
        ();

  end match;
end printAlgorithmitem;

public function printAlgorithm
"Prints an Algorithm to the Print buffer."
  input Absyn.Algorithm inAlgorithm;
algorithm
  _ := matchcontinue (inAlgorithm)
    local
      Absyn.ComponentRef cr;
      Absyn.Exp exp,e, assignComp;
      list<Absyn.AlgorithmItem> tb,fb,el,al;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> eb;
      Absyn.ForIterators iterators;
      Absyn.AlgorithmItem algItem;
      Absyn.FunctionArgs fargs;

    case (Absyn.ALG_ASSIGN(assignComponent = assignComp,value = exp))
      equation
        Print.printBuf("ALG_ASSIGN(");
        printExp(assignComp);
        Print.printBuf(" := ");
        printExp(exp);
        Print.printBuf(")");
      then
        ();

    case (Absyn.ALG_NORETCALL(functionCall = cr,functionArgs = fargs)) /* ALG_NORETCALL */
      equation
        Print.printBuf("ALG_NORETCALL(");
        Print.printBuf(printComponentRefStr(cr) +& "(");
        Print.printBuf(printFunctionArgsStr(fargs));
        Print.printBuf(")");
      then
        ();

    case (Absyn.ALG_IF(ifExp = e,trueBranch = tb,elseIfAlgorithmBranch = eb,elseBranch = fb))
      equation
        Print.printBuf("IF (");
        printExp(e);
        Print.printBuf(") THEN ");
        printListDebug("print_algorithm", tb, printAlgorithmitem, ";");
        printListDebug("print_algorithm", eb, printAlgElseif, " ");
        Print.printBuf(" ELSE ");
        printListDebug("print_algorithm", fb, printAlgorithmitem, ";");
      then
        ();

    case Absyn.ALG_FOR(iterators=iterators,forBody = el)
      equation
        Print.printBuf("FOR ");
        printListDebug("print_iterators", iterators, printIterator, ", ");
        Print.printBuf(" {");
        printListDebug("print_algorithm", el, printAlgorithmitem, ";");
        Print.printBuf("}");
      then
        ();

    case Absyn.ALG_PARFOR(iterators=iterators,parforBody = el)
      equation
        Print.printBuf("PARFOR ");
        printListDebug("print_iterators", iterators, printIterator, ", ");
        Print.printBuf(" {");
        printListDebug("print_algorithm", el, printAlgorithmitem, ";");
        Print.printBuf("}");
      then
        ();

    case Absyn.ALG_WHILE(boolExpr = e,whileBody = al)
      equation
        Print.printBuf("WHILE ");
        printExp(e);
        Print.printBuf(" {");
        printListDebug("print_algorithm", al, printAlgorithmitem, ";");
        Print.printBuf("}");
      then
        ();

    case Absyn.ALG_WHEN_A(boolExpr = e,whenBody = al,elseWhenAlgorithmBranch = eb)
      /* rule  Print.print_buf \"WHEN_E \" & print_exp(e) &
         Print.print_buf \" {\" & print_list_debug(\"print_algorithm\",al, print_algorithmitem, \";\") & Print.print_buf \"}\"
         ----------------------------------------------------------
         print_algorithm Absyn.ALG_WHEN_E(e,al)
      */
      equation
        Print.printBuf("WHEN_A ");
        printExp(e);
        Print.printBuf(" {");
        printListDebug("print_algorithm", al, printAlgorithmitem, ";");
        Print.printBuf("}");
      then
        ();

    case Absyn.ALG_RETURN()
      equation
        Print.printBuf("RETURN()");
      then
        ();

    case Absyn.ALG_BREAK()
      equation
        Print.printBuf("BREAK()");
      then
        ();

    case Absyn.ALG_FAILURE({algItem})
      equation
        Print.printBuf("FAILURE(");
        printAlgorithmitem(algItem);
        Print.printBuf(")");
      then
        ();

    case Absyn.ALG_FAILURE(_)
      equation
        Print.printBuf("FAILURE(...)");
      then
        ();

    case (_)
      equation
        Print.printBuf(" ** UNKNOWN ALGORITHM CLAUSE ** ");
      then
        ();
  end matchcontinue;
end printAlgorithm;

public function unparseAlgorithmStrLst "Prettyprints an AlgorithmItem list to a string."
  input Integer inInteger;
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input String inString;
  output String outString;
algorithm
  outString := match (inInteger,inAbsynAlgorithmItemLst,inString)
    local
      String s1,s2,res,sep;
      Integer i;
      Absyn.AlgorithmItem x;
      list<Absyn.AlgorithmItem> xs;

    case (_,{},_) then "";

    case (i,{x},sep)
      then unparseAlgorithmStr(i, x);

    case (i,(x :: xs),sep)
      equation
        s1 = unparseAlgorithmStr(i, x);
        s2 = unparseAlgorithmStrLst(i, xs, sep);
        res = stringAppendList({s1,sep,s2});
      then res;
  end match;
end unparseAlgorithmStrLst;

protected function unparseAlgorithmStrLstLst
  input Integer inInteger;
  input list<list<Absyn.AlgorithmItem>> inAbsynAlgorithmItemLst;
  input String inString;
  output list<String> outString;
algorithm
  outString := matchcontinue (inInteger,inAbsynAlgorithmItemLst,inString)
    local
      String s1,sep;
      list<String> s2;
      Integer i;
      list<Absyn.AlgorithmItem> x;
      list<list<Absyn.AlgorithmItem>> xs;

    case (_,{},_) then {};

    case (i,(x :: xs),sep)
      equation
        s1 = unparseAlgorithmStrLst(i, x, sep);
        s2 = unparseAlgorithmStrLstLst(i, xs, sep);
      then
        s1::s2;
  end matchcontinue;
end unparseAlgorithmStrLstLst;

public function unparseAlgorithmStr "Helper function to unparseAlgorithmStr"
  input Integer inInteger;
  input Absyn.AlgorithmItem inAlgorithmItem;
  output String outString;
algorithm
  outString := matchcontinue (inInteger,inAlgorithmItem)
    local
      String s1,s2,s3,is,str,s4,s5,str_1;
      Integer i,i_1;
      Absyn.ComponentRef cr;
      Absyn.Exp exp,e, assignComp;
      Option<Absyn.Comment> optcmt;
      list<Absyn.AlgorithmItem> tb,fb,el,al;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> eb,al2;
      Absyn.FunctionArgs fargs;
      Absyn.Annotation ann;
      Absyn.ForIterators iterators;
      Absyn.AlgorithmItem algItem;

    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_ASSIGN(assignComponent = assignComp,value = exp),comment = optcmt)) /* ALG_ASSIGN */
      equation
        s1 = printExpStr(assignComp);
        s2 = printExpStr(exp);
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = stringAppendList({is,s1,":=",s2,s3,";"});
      then
        str;

    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_IF(ifExp = e,trueBranch = tb,elseIfAlgorithmBranch = eb,elseBranch = fb),comment = optcmt)) /* ALG_IF */
      equation
        s1 = printExpStr(e);
        i_1 = i + 1;
        s2 = unparseAlgorithmStrLst(i_1, tb, "\n");
        s3 = unparseAlgElseifStrLst(i, eb, "\n");
        s4 = unparseAlgorithmStrLst(i_1, fb, "\n");
        s5 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = stringAppendList(
          {is,"if ",s1," then \n",s2,s3,"\n",is,"else\n",s4,"\n",is,
          "end if",s5,";"});
      then
        str;

    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_FOR(iterators=iterators,forBody = el),comment = optcmt)) /* ALG_FOR */
      equation
        i_1 = i + 1;
        s1 = printIteratorsStr(iterators);
        s2 = unparseAlgorithmStrLst(i_1, el, "\n");
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = stringAppendList({is,"for ",s1," loop\n",is,s2,"\n",is,"end for",s3,";"});
      then
        str;

    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_PARFOR(iterators=iterators,parforBody = el),comment = optcmt)) /* ALG_PARFOR */
      equation
        i_1 = i + 1;
        s1 = printIteratorsStr(iterators);
        s2 = unparseAlgorithmStrLst(i_1, el, "\n");
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = stringAppendList({is,"parfor ",s1," loop\n",is,s2,"\n",is,"end parfor",s3,";"});
      then
        str;

    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_WHILE(boolExpr = e,whileBody = al),comment = optcmt)) /* ALG_WHILE */
      equation
        s1 = printExpStr(e);
        i_1 = i + 1;
        s2 = unparseAlgorithmStrLst(i_1, al, "\n");
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = stringAppendList({is,"while (",s1,") loop\n",is,s2,"\n",is,"end while",s3,";"});
      then
        str;

    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_WHEN_A(boolExpr = e,whenBody = al,elseWhenAlgorithmBranch = al2),comment = optcmt)) /* ALG_WHEN_A */
      equation
        s1 = printExpStr(e);
        i_1 = i + 1;
        s2 = unparseAlgorithmStrLst(i_1, al, "\n");
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        s4 = unparseAlgElsewhenStrLst(i_1, al2);
        str = stringAppendList({is,"when ",s1," then\n",is,s2,is,s4,"\n",is,"end when",s3,";"});
      then
        str;

    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_NORETCALL(functionCall = cr,functionArgs = fargs),comment = optcmt)) /* ALG_NORETCALL */
      equation
        s1 = printComponentRefStr(cr);
        s2 = printFunctionArgsStr(fargs);
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = stringAppendList({is,s1,"(",s2,")",s3,";"});
      then
        str;

    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_RETURN(),comment = optcmt)) /* ALG_RETURN */
      equation
        s3 = unparseCommentOption(optcmt);
        str = "return" +& s3 +& ";";
      then
        str;

    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_BREAK(),comment = optcmt)) /* ALG_BREAK */
      equation
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = is +& "break" +& s3 +& ";";
      then
        str;

    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_FAILURE({algItem}),comment = optcmt)) /* ALG_FAILURE */
      equation
        s1 = unparseAlgorithmStr(0, algItem);
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = is +& "failure(" +& s1 +& ")" +& s3 +& ";";
      then
        str;

    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_FAILURE(_),comment = optcmt)) /* ALG_FAILURE */
      equation
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = is +& "failure(...)" +& s3 +& ";";
      then
        str;

    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_TRY(al),comment = optcmt)) /* ALG_TRY */
      equation
        i_1 = i + 1;
        s2 = unparseAlgorithmStrLst(i_1, al, "\n");
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = stringAppendList(
          {is,"try\n",is,s2,is,"end try",s3,";"});
      then
        str;
    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_THROW(),comment = optcmt)) /* ALG_THROW */
      equation
        is = indentStr(i);
        str = is +& "throw;";
      then
        str;
    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_CATCH(al),comment = optcmt)) /* ALG_CATCH */
      equation
        i_1 = i + 1;
        s2 = unparseAlgorithmStrLst(i_1, al, "\n");
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = stringAppendList(
          {is,"catch\n",is,s2,is,"end catch",s3,";"});
      then
        str;

    case (i,Absyn.ALGORITHMITEMCOMMENT(comment = str))
      then indentStr(i) +& System.trimWhitespace(str);

    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Dump.unparseAlgorithmStr failed"});
      then fail();
  end matchcontinue;
end unparseAlgorithmStr;

protected function unparseAlgElsewhenStrLst "Unparses an elsewhen branch in an algorithm to a string."
  input Integer inInteger;
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  output String outString;
algorithm
  outString := matchcontinue (inInteger,inTplAbsynExpAbsynAlgorithmItemLstLst)
    local
      String res,s1,s2;
      Integer i;
      tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> x,x1,x2;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> xs;

    case (_,{}) then "";

    case (i,{x})
      equation
        res = unparseAlgElsewhenStr(i, x);
      then
        res;

    case (i,{x1,x2})
      equation
        s1 = unparseAlgElsewhenStr(i, x1);
        s2 = unparseAlgElsewhenStr(i, x2);
        res = stringAppendList({s1,"\n",s2});
      then
        res;

    case (i,(x :: (xs as (_ :: _))))
      equation
        s1 = unparseAlgElsewhenStr(i, x);
        s2 = unparseAlgElsewhenStrLst(i, xs);
        res = stringAppendList({s1,"\n",s2});
      then
        res;
  end matchcontinue;
end unparseAlgElsewhenStrLst;

protected function unparseAlgElsewhenStr "Helper function to unparseAlgElsewhenStrLst"
  input Integer inInteger;
  input tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> inTplAbsynExpAbsynAlgorithmItemLst;
  output String outString;
algorithm
  outString := match (inInteger,inTplAbsynExpAbsynAlgorithmItemLst)
    local
      String is,s1,s2,res;
      Integer i;
      Absyn.Exp exp;
      list<Absyn.AlgorithmItem> algl;

    case (i,(exp,algl))
      equation
        is = indentStr(i);
        s1 = unparseAlgorithmStrLst(i, algl, "\n");
        s2 = printExpStr(exp);
        res = stringAppendList({"elsewhen ",s2," then\n",s1});
      then
        res;
  end match;
end unparseAlgElsewhenStr;

protected function unparseEqElsewhenStrLst "Prettyprints an equation elsewhen branch to a string."
  input Integer inInteger;
  input list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> inTplAbsynExpAbsynEquationItemLstLst;
  output String outString;
algorithm
  outString := matchcontinue (inInteger,inTplAbsynExpAbsynEquationItemLstLst)
    local
      String res,s1,s2;
      Integer i;
      tuple<Absyn.Exp, list<Absyn.EquationItem>> x,x1,x2;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> xs;

    case (_,{}) then "";

    case (i,{x})
      equation
        res = unparseEqElsewhenStr(i, x);
      then
        res;

    case (i,{x1,x2})
      equation
        s1 = unparseEqElsewhenStr(i, x1);
        s2 = unparseEqElsewhenStr(i, x2);
        res = stringAppendList({s1,"\n",s2});
      then
        res;

    case (i,(x :: xs))
      equation
        s1 = unparseEqElsewhenStr(i, x);
        s2 = unparseEqElsewhenStrLst(i, xs);
        res = stringAppendList({s1,"\n",s2});
      then
        res;
  end matchcontinue;
end unparseEqElsewhenStrLst;

protected function unparseEqElsewhenStr "Helper function to unparseEqWlsewhenStrLst"
  input Integer inInteger;
  input tuple<Absyn.Exp, list<Absyn.EquationItem>> inTplAbsynExpAbsynEquationItemLst;
  output String outString;
algorithm
  outString := match (inInteger,inTplAbsynExpAbsynEquationItemLst)
    local
      String is,s1,s2,res;
      Integer i;
      Absyn.Exp exp;
      list<Absyn.EquationItem> eql;

    case (i,(exp,eql))
      equation
        is = indentStr(i);
        s1 = unparseEquationitemStrLst(i, eql, "\n");
        s2 = printExpStr(exp);
        res = stringAppendList({"elsewhen ",s2," then\n",s1});
      then
        res;
  end match;
end unparseEqElsewhenStr;

protected function printAlgElseif "Prints an algorithm elseif branch to the Print buffer."
  input tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> inTplAbsynExpAbsynAlgorithmItemLst;
algorithm
  _ := match (inTplAbsynExpAbsynAlgorithmItemLst)
    local
      Absyn.Exp e;
      list<Absyn.AlgorithmItem> el;

    case ((e,el))
      equation
        Print.printBuf(" ELSEIF ");
        printExp(e);
        Print.printBuf(" THEN ");
        printListDebug("print_alg_elseif", el, printAlgorithmitem, ";");
      then
        ();
  end match;
end printAlgElseif;

protected function unparseAlgElseifStrLst "Prettyprints an algorithm elseif branch to a string."
  input Integer inInteger;
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  input String inString;
  output String outString;
algorithm
  outString := match (inInteger,inTplAbsynExpAbsynAlgorithmItemLstLst,inString)
    local
      String s2,s1,res,sep;
      Integer i;
      tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> x;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> xs;

    case (_,{},_) then "";

    case (i,{x},sep)
      then unparseAlgElseifStr(i, x);

    case (i,(x :: xs),sep)
      equation
        s2 = unparseAlgElseifStrLst(i, xs, sep);
        s1 = unparseAlgElseifStr(i, x);
        res = stringAppendList({s1,sep,s2});
      then res;
  end match;
end unparseAlgElseifStrLst;

protected function unparseAlgElseifStr "Helper function to unparseAlgElseifStrLst"
  input Integer inInteger;
  input tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> inTplAbsynExpAbsynAlgorithmItemLst;
  output String outString;
algorithm
  outString := match (inInteger,inTplAbsynExpAbsynAlgorithmItemLst)
    local
      String s1,s2,is,str;
      Integer i;
      Absyn.Exp e;
      list<Absyn.AlgorithmItem> el;

    case (i,(e,el))
      equation
        s1 = printExpStr(e);
        s2 = unparseAlgorithmStrLst(i+1, el, "\n");
        is = indentStr(i);
        str = stringAppendList({"\n",is,"elseif ",s1," then\n",s2});
      then
        str;
  end match;
end unparseAlgElseifStr;

public function printComponentRef "Component references and paths
  function: printComponentRef
  Print a ComponentRef to the Print buffer."
  input Absyn.ComponentRef inComponentRef;
algorithm
  _ := match (inComponentRef)
    local
      String s;
      list<Absyn.Subscript> subs;
      Absyn.ComponentRef cr;

    case Absyn.CREF_IDENT(name = s,subscripts = subs)
      equation
        Print.printBuf("Absyn.CREF_IDENT(\"");
        Print.printBuf(s);
        Print.printBuf("\", ");
        printSubscripts(subs);
        Print.printBuf(")");
      then
        ();

    case Absyn.CREF_QUAL(name = s,subscripts = subs,componentRef = cr)
      equation
        Print.printBuf("Absyn.CREF_QUAL(\"");
        Print.printBuf(s);
        Print.printBuf("\", ");
        printSubscripts(subs);
        Print.printBuf(",");
        printComponentRef(cr);
        Print.printBuf(")");
      then
        ();

    // MetaModelica wildcard
    case Absyn.WILD()
      equation
        Print.printBuf("Absyn.WILD");
      then
        ();
    case Absyn.ALLWILD()
      equation
        Print.printBuf("Absyn.ALLWILD");
      then
        ();

    case Absyn.CREF_INVALID(componentRef = cr)
      equation
        Print.printBuf("Absyn.CREF_INVALID(\"");
        printComponentRef(cr);
        Print.printBuf("\")");
      then
        ();
  end match;
end printComponentRef;

public function printSubscripts "Prints a Subscript to the Print buffer."
  input list<Absyn.Subscript> inAbsynSubscriptLst;
algorithm
  _ := matchcontinue (inAbsynSubscriptLst)
    local
      list<Absyn.Subscript> l;

    case {}
      equation
        Print.printBuf("[]");
      then
        ();

    case l
      equation
        Print.printBuf("[");
        printListDebug("print_subscripts", l, printSubscript, ",");
        Print.printBuf("]");
      then
        ();
  end matchcontinue;
end printSubscripts;

public function printComponentRefStr "Print a ComponentRef and return as a string."
  input Absyn.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := match (inComponentRef)
    local
      String subsstr,s_1,s,crs,s_2,s_3;
      list<Absyn.Subscript> subs;
      Absyn.ComponentRef cr;

    case Absyn.CREF_IDENT(name = s,subscripts = subs)
      equation
        subsstr = printSubscriptsStr(subs);
        s_1 = stringAppend(s, subsstr);
      then
        s_1;

    case Absyn.CREF_QUAL(name = s,subscripts = subs,componentRef = cr)
      equation
        crs = printComponentRefStr(cr);
        subsstr = printSubscriptsStr(subs);
        s_1 = stringAppend(s, subsstr);
        s_2 = stringAppend(s_1, ".");
        s_3 = stringAppend(s_2, crs);
      then
        s_3;

    case Absyn.CREF_FULLYQUALIFIED(componentRef = cr)
      equation
        crs = printComponentRefStr(cr);
        s_3 = stringAppend(".", crs);
      then
        s_3;

    case Absyn.ALLWILD() then "__";

    case Absyn.WILD() then "_";

    case Absyn.CREF_INVALID(componentRef = cr)
      then printComponentRefStr(cr);
  end match;
end printComponentRefStr;

public function printSubscriptsStr "Prettyprint a Subscript list to a string."
  input list<Absyn.Subscript> inAbsynSubscriptLst;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynSubscriptLst)
    local
      String s,s_1,s_2;
      list<Absyn.Subscript> l;

    case {} then "";

    case l
      equation
        s = printListStr(l, printSubscriptStr, ",");
        s_1 = stringAppend("[", s);
        s_2 = stringAppend(s_1, "]");
      then
        s_2;
  end matchcontinue;
end printSubscriptsStr;

public function printPath "Print a Path."
  input Absyn.Path p;
protected
  String s;
algorithm
  s := Absyn.pathString(p);
  Print.printBuf(s);
end printPath;

protected function dumpPath "Dumps path to the Print buffer"
  input Absyn.Path inPath;
algorithm
  _ := match (inPath)
    local
      String str;
      Absyn.Path path;

    case (Absyn.IDENT(name = str))
      equation
        Print.printBuf("Absyn.IDENT(\"");
        Print.printBuf(str);
        Print.printBuf("\")");
      then
        ();

    case (Absyn.QUALIFIED(name = str,path = path))
      equation
        Print.printBuf("Absyn.QUALIFIED(\"");
        Print.printBuf(str);
        Print.printBuf("\",");
        dumpPath(path);
        Print.printBuf(")");
      then
        ();
  end match;
end dumpPath;

protected function printPathStr "Print a Path."
  input Absyn.Path p;
  output String s;
algorithm
  s := Absyn.pathString(p);
end printPathStr;

public function printExp "This function prints a complete expression to the Print buffer."
  input Absyn.Exp inExp;
algorithm
  _ := matchcontinue (inExp)
    local
      String s,sym;
      Integer i;
      Real r;
      Absyn.ComponentRef c,fcn;
      Absyn.Exp e1,e2,e,t,f,start,stop,step;
      Absyn.Operator op;
      list<tuple<Absyn.Exp, Absyn.Exp>> lst;
      Absyn.FunctionArgs args;
      list<Absyn.Exp> es;
      Absyn.MatchType matchType;
      Absyn.Exp head, rest,inputExp,cond;
      list<Absyn.ElementItem> localDecls;
      list<Absyn.Case> cases;
      Option<String> comment;
      list<list<Absyn.Exp>> esLst;

    case (Absyn.INTEGER(value = i))
      equation
        s = intString(i);
        Print.printBuf("Absyn.INTEGER(");
        Print.printBuf(s);
        Print.printBuf(")");
      then
        ();

    case (Absyn.REAL(value = r))
      equation
        s = realString(r);
        Print.printBuf("Absyn.REAL(");
        Print.printBuf(s);
        Print.printBuf(")");
      then
        ();

    case (Absyn.CREF(componentRef = c))
      equation
        Print.printBuf("Absyn.CREF(");
        printComponentRef(c);
        Print.printBuf(")");
      then
        ();

    case (Absyn.STRING(value = s))
      equation
        Print.printBuf("Absyn.STRING(\"");
        Print.printBuf(s);
        Print.printBuf("\")");
      then
        ();

    case (Absyn.BOOL(value = false))
      equation
        Print.printBuf("Absyn.BOOL(false)");
      then
        ();

    case (Absyn.BOOL(value = true))
      equation
        Print.printBuf("Absyn.BOOL(true)");
      then
        ();

    case (Absyn.BINARY(exp1 = e1,op = op,exp2 = e2))
      equation
        sym = dumpOpSymbol(op);
        Print.printBuf("Absyn.BINARY(");
        printExp(e1);
        Print.printBuf(",");
        Print.printBuf(sym);
        Print.printBuf(",");
        printExp(e2);
        Print.printBuf(")");
      then
        ();

    case (Absyn.UNARY(op = op,exp = e))
      equation
        sym = dumpOpSymbol(op);
        Print.printBuf("Absyn.UNARY(");
        Print.printBuf(sym);
        Print.printBuf(", ");
        printExp(e);
        Print.printBuf(")");
      then
        ();

    case (Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2))
      equation
        sym = dumpOpSymbol(op);
        Print.printBuf("Absyn.LBINARY(");
        printExp(e1);
        Print.printBuf(",");
        Print.printBuf(sym);
        Print.printBuf(",");
        printExp(e2);
        Print.printBuf(")");
      then
        ();

    case (Absyn.LUNARY(op = op,exp = e))
      equation
        sym = dumpOpSymbol(op);
        Print.printBuf("Absyn.UNARY(");
        Print.printBuf(sym);
        Print.printBuf(", ");
        printExp(e);
        Print.printBuf(")");
      then
        ();

    case (Absyn.RELATION(exp1 = e1,op = op,exp2 = e2))
      equation
        sym = dumpOpSymbol(op);
        Print.printBuf("Absyn.RELATION(");
        printExp(e1);
        Print.printBuf(",");
        Print.printBuf(sym);
        Print.printBuf(",");
        printExp(e2);
        Print.printBuf(")");
      then
        ();

    case (Absyn.IFEXP(ifExp = cond,trueBranch = t,elseBranch = f,elseIfBranch = lst))
      equation
        Print.printBuf("Absyn.IFEXP(");
        printExp(cond);
        Print.printBuf(", ");
        printExp(t);
        Print.printBuf(", ");
        printExp(f);
        Print.printBuf(")");
      then
        ();

    case (Absyn.CALL(function_ = fcn,functionArgs = args))
      equation
        Print.printBuf("Absyn.CALL(");
        printComponentRef(fcn);
        Print.printBuf(", ");
        printFunctionArgs(args);
        Print.printBuf(")");
      then
        ();

    case (Absyn.PARTEVALFUNCTION(function_ = fcn, functionArgs = args))
      equation
        Print.printBuf("Absyn.PARTEVALFUNCTION(");
        printComponentRef(fcn);
        Print.printBuf(", ");
        printFunctionArgs(args);
        Print.printBuf(")");
      then
        ();

    case Absyn.ARRAY(arrayExp = es)
      equation
        Print.printBuf("Absyn.ARRAY([");
        printListDebug("print_exp", es, printExp, ",");
        Print.printBuf("])");
      then
        ();

    case Absyn.TUPLE(expressions = es) /* PR. */
      equation
        Print.printBuf("Absyn.TUPLE([");
        Print.printBuf("(");
        printListDebug("print_exp", es, printExp, ",");
        Print.printBuf("])");
      then
        ();

    case Absyn.MATRIX(matrix = esLst)
      equation
        Print.printBuf("Absyn.MATRIX([");
        printListDebug("print_exp", esLst, printRow, ";");
        Print.printBuf("])");
      then
        ();

    case Absyn.RANGE(start = start,step = NONE(),stop = stop)
      equation
        Print.printBuf("Absyn.RANGE(");
        printExp(start);
        Print.printBuf(",NONE(),");
        printExp(stop);
        Print.printBuf(")");
      then
        ();

    case Absyn.RANGE(start = start,step = SOME(step),stop = stop)
      equation
        Print.printBuf("Absyn.RANGE(");
        printExp(start);
        Print.printBuf(",SOME(");
        printExp(step);
        Print.printBuf("),");
        printExp(stop);
        Print.printBuf(")");
      then
        ();

    case Absyn.END()
      equation
        Print.printBuf("Absyn.END");
      then
        ();

    // MetaModelica expressions!
    case Absyn.LIST(es)
      equation
        Print.printBuf("Absyn.LIST([");
        printListDebug("print_exp", es, printExp, ",");
        Print.printBuf("])");
      then
        ();

    case Absyn.CONS(head, rest)
      equation
        Print.printBuf("Absyn.CONS(");
        printExp(head);
        Print.printBuf(", ");
        printExp(rest);
        Print.printBuf(")");
      then
        ();

    case Absyn.AS(s, rest)
      equation
        Print.printBuf("Absyn.AS(");
        Print.printBuf(s);
        Print.printBuf(", ");
        printExp(rest);
        Print.printBuf(")");
      then
        ();

    case Absyn.MATCHEXP(matchType, inputExp, localDecls, cases, comment)
      equation
        Print.printBuf("Absyn.MATCHEXP(MatchType(");
        s = printMatchType(matchType);
        Print.printBuf(s);
        Print.printBuf("), Input Exps(");
        printExp(inputExp);
        Print.printBuf("), \nLocal Decls(");
        printElementitems(localDecls);
        Print.printBuf("), \nCASES(");
        printListDebug("CASE", cases, printCase, ";");
        Print.printBuf(")");
        printStringCommentOption(comment);
        Print.printBuf(")");
      then
        ();

    case (_)
      equation
        Print.printBuf("#UNKNOWN EXPRESSION#");
      then
        ();
  end matchcontinue;
end printExp;

public function printMatchType "
MetaModelica construct printing
@author Adrian Pop "
  input Absyn.MatchType matchType;
  output String out;
algorithm
  out := match matchType
    case Absyn.MATCH() then "match";
    case Absyn.MATCHCONTINUE() then "matchcontinue";
  end match;
end printMatchType;

public function printCase "
MetaModelica construct printing
@author Adrian Pop "
  input Absyn.Case cas;
algorithm
  _ := match cas
    local
      Absyn.Exp p;
      list<Absyn.ElementItem> l;
      list<Absyn.EquationItem> e;
      Absyn.Exp r;
      Option<String> c;
    case Absyn.CASE(p, _, _, l, e, r, _, c, _)
      equation
        Print.printBuf("Absyn.CASE(");
        Print.printBuf("Pattern(");
        printExp(p);
        Print.printBuf("), \nLocal Decls(");
        printElementitems(l);
        Print.printBuf("), \nEQUATIONS(");
        printListDebug("EQUATION", e, printEquationitem, ";");
        Print.printBuf("), ");
        printExp(r);
        Print.printBuf(", ");
        printStringCommentOption(c);
        Print.printBuf(")");
      then ();
    case Absyn.ELSE(l, e, r, _, c, _)
      equation
        Print.printBuf("Absyn.ELSE(\nLocal Decls(");
        printElementitems(l);
        Print.printBuf("), \nEQUATIONS(");
        printListDebug("EQUATION", e, printEquationitem, ";");
        Print.printBuf("), ");
        printExp(r);
        Print.printBuf(", ");
        printStringCommentOption(c);
        Print.printBuf(")");
      then ();
  end match;
end printCase;

protected function printFunctionArgs "
  Prints FunctionArgs to Print buffer.
"
  input Absyn.FunctionArgs inFunctionArgs;
algorithm
  _:=
  match (inFunctionArgs)
    local
      list<Absyn.Exp> expargs;
      list<Absyn.NamedArg> nargs;
      Absyn.Exp exp;
      Absyn.ForIterators iterators;
    case Absyn.FUNCTIONARGS(args = expargs,argNames = nargs)
      equation
        Print.printBuf("FUNCTIONARGS(");
        printListDebug("print_exp", expargs, printExp, ", ");
        Print.printBuf(", ");
        printListDebug("print_namedarg", nargs, printNamedArg, ", ");
        Print.printBuf(")");
      then
        ();
    case Absyn.FOR_ITER_FARG(exp = exp,iterators = iterators)
      equation
        Print.printBuf("FOR_ITER_FARG(");
        printExp(exp);
        Print.printBuf(", ");
        printListDebug("print_iterators", iterators, printIterator, ", ");
        Print.printBuf(")");
      then
        ();
  end match;
end printFunctionArgs;

function printIterator
" @author adrpo
  prints iterator: (i,exp1)"
  input Absyn.ForIterator iterator;
algorithm
  _ := match(iterator)
    local
      Absyn.Exp exp;
      Absyn.Ident id;
    case (Absyn.ITERATOR(id, NONE(), SOME(exp)))
      equation
        Print.printBuf("(");
        Print.printBuf(id);
        Print.printBuf(", ");
        printExp(exp);
        Print.printBuf(")");
      then ();
    case (Absyn.ITERATOR(id, NONE(), NONE()))
      equation
        Print.printBuf("(");
        Print.printBuf(id);
        Print.printBuf(")");
      then ();
  end match;
end printIterator;


public function printFunctionArgsStr "
  Prettyprint FunctionArgs to a string.
"
  input Absyn.FunctionArgs inFunctionArgs;
  output String outString;
algorithm
  outString:=
  matchcontinue (inFunctionArgs)
    local
      String s1,s2,s3,str,estr,istr;
      list<Absyn.Exp> expargs;
      list<Absyn.NamedArg> nargs;
      Absyn.Exp exp;
      Absyn.ForIterators iterators;
    case Absyn.FUNCTIONARGS(args = (expargs as (_ :: _)),argNames = (nargs as (_ :: _)))
      equation
        s1 = printListStr(expargs, printExpStr, ", ") "Both positional and named arguments" ;
        s2 = stringAppend(s1, ", ");
        s3 = printListStr(nargs, printNamedArgStr, ", ");
        str = stringAppend(s2, s3);
      then
        str;
    case Absyn.FUNCTIONARGS(args = {},argNames = nargs)
      equation
        str = printListStr(nargs, printNamedArgStr, ", ") "Only named arguments" ;
      then
        str;
    case Absyn.FUNCTIONARGS(args = expargs,argNames = {})
      equation
        str = printListStr(expargs, printExpStr, ", ") "Only positional arguments" ;
      then
        str;
    case Absyn.FOR_ITER_FARG(exp = exp,iterators = iterators)
      equation
        estr = printExpStr(exp);
        istr = printIteratorsStr(iterators);
        str = stringAppendList({estr," for ", istr});
      then
        str;
  end matchcontinue;
end printFunctionArgsStr;

function printIteratorsStr
" @author adrpo
  prints iterators: i in exp1, j in exp2, k in exp3"
  input Absyn.ForIterators iterators;
  output String iteratorsStr;
algorithm
  iteratorsStr := matchcontinue(iterators)
    local
      String s, s1, s2;
      Absyn.Exp guardExp,exp;
      Absyn.Ident id;
      Absyn.ForIterators rest;
      Absyn.ForIterator x;
    case ({}) then "";
    case ({Absyn.ITERATOR(id, SOME(guardExp), SOME(exp))})
      equation
        s1 = printExpStr(exp);
        s2 = printExpStr(guardExp);
        s = stringAppendList({id, " guard ", s2, " in ", s1});
      then s;
    case ({Absyn.ITERATOR(id, NONE(), SOME(exp))})
      equation
        s1 = printExpStr(exp);
        s = stringAppendList({id, " in ", s1});
      then s;
    case ({Absyn.ITERATOR(id, NONE(), NONE())}) then id;
    case (x::rest)
      equation
        s1 = printIteratorsStr({x});
        s2 = printIteratorsStr(rest);
        s = stringAppendList({s1, ", ", s2});
      then s;
  end matchcontinue;
end printIteratorsStr;

public function printNamedArg
"Print NamedArg to the Print buffer."
  input Absyn.NamedArg inNamedArg;
algorithm
  _:=
  match (inNamedArg)
    local
      String ident;
      Absyn.Exp e;
    case Absyn.NAMEDARG(argName = ident,argValue = e)
      equation
        Print.printBuf(ident);
        Print.printBuf(" = ");
        printExp(e);
      then
        ();
  end match;
end printNamedArg;

public function printNamedArgStr
"Prettyprint NamedArg to a string."
  input Absyn.NamedArg inNamedArg;
  output String outString;
algorithm
  outString:=
  match (inNamedArg)
    local
      String s1,s2,str,ident;
      Absyn.Exp e;
    case Absyn.NAMEDARG(argName = ident,argValue = e)
      equation
        s1 = stringAppend(ident, " = ");
        s2 = printExpStr(e);
        str = stringAppend(s1, s2);
      then
        str;
  end match;
end printNamedArgStr;


protected function printRow "
  Print an Expression list to the Print buffer.
"
  input list<Absyn.Exp> es;
algorithm
  printListDebug("print_row", es, printExp, ",");
end printRow;

public function expPriority
  "Returns an integer priority given an expression, which is used by
   printOperatorStr to add parentheses around operands when dumping expressions.
   The inLhs argument should be true if the expression occurs on the left side
   of a binary operation, otherwise false. This is because we don't need to add
   parentheses to expressions such as x * y / z, but x / (y * z) needs them, so
   the priorities of some binary operations differ depending on which side they
   are."
  input Absyn.Exp inExp;
  input Boolean inLhs;
  output Integer outPriority;
algorithm
  outPriority := match(inExp, inLhs)
    local
      Absyn.Operator op;

    case (Absyn.BINARY(op = op), false) then priorityBinopRhs(op);
    case (Absyn.BINARY(op = op), true) then priorityBinopLhs(op);
    case (Absyn.UNARY(op = _), _) then 4;
    case (Absyn.LBINARY(op = op), _) then priorityLBinop(op);
    case (Absyn.LUNARY(op = _), _) then 7;
    case (Absyn.RELATION(op = op), _) then 6;
    case (Absyn.RANGE(start = _), _) then 10;
    case (Absyn.IFEXP(ifExp = _), _) then 11;
    else 0;
  end match;
end expPriority;

protected function priorityBinopLhs
  "Returns the priority for a binary operation on the left hand side. Add and
   sub has the same priority, and mul and div too, in contrast with
   priorityBinopRhs."
  input Absyn.Operator inOp;
  output Integer outPriority;
algorithm
  outPriority := match(inOp)
    case Absyn.ADD() then 5;
    case Absyn.SUB() then 5;
    case Absyn.MUL() then 2;
    case Absyn.DIV() then 2;
    case Absyn.POW() then 1;
    case Absyn.ADD_EW() then 5;
    case Absyn.SUB_EW() then 5;
    case Absyn.MUL_EW() then 2;
    case Absyn.DIV_EW() then 2;
    case Absyn.POW_EW() then 1;
  end match;
end priorityBinopLhs;

protected function priorityBinopRhs
  "Returns the priority for a binary operation on the right hand side. Add and
   sub has different priorities, and mul and div too, in contrast with
   priorityBinopLhs."
  input Absyn.Operator inOp;
  output Integer outPriority;
algorithm
  outPriority := match(inOp)
    case Absyn.ADD() then 6;
    case Absyn.SUB() then 5;
    case Absyn.MUL() then 3;
    case Absyn.DIV() then 2;
    case Absyn.POW() then 1;
    case Absyn.ADD_EW() then 6;
    case Absyn.SUB_EW() then 5;
    case Absyn.MUL_EW() then 3;
    case Absyn.DIV_EW() then 2;
    case Absyn.POW_EW() then 1;
  end match;
end priorityBinopRhs;

protected function priorityLBinop
  input Absyn.Operator inOp;
  output Integer outPriority;
algorithm
  outPriority := match(inOp)
    case Absyn.AND() then 8;
    case Absyn.OR() then 9;
  end match;
end priorityLBinop;

protected function printOperandStr
  "Prints an operand to a string."
  input Absyn.Exp inOperand "The operand expression.";
  input Absyn.Exp inOperation "The unary/binary operation which the operand belongs to.";
  input Boolean inLhs "True if the operand is the left hand operand, otherwise false.";
  output String outString;
algorithm
  outString := matchcontinue(inOperand, inOperation, inLhs)
    local
      String op_str;

    // Special case for unary operation on rhs, always print parentheses.
    case (Absyn.UNARY(op = _), _, false)
      equation
        op_str = printExpStr(inOperand);
        op_str = stringAppendList({"(", op_str, ")"});
      then
        op_str;

    // Print parentheses around an operand if the priority of the operation is
    // less than the priority of the operand.
    case (_, _, _)
      equation
        true = intLt(expPriority(inOperation, inLhs), expPriority(inOperand, inLhs));
        op_str = printExpStr(inOperand);
        op_str = stringAppendList({"(", op_str, ")"});
      then
        op_str;

    else printExpStr(inOperand);

  end matchcontinue;
end printOperandStr;

public function printExpLstStr "exp

Prints a list of expressions to a string
"
  input list<Absyn.Exp> expl;
  output String outString;
algorithm
  outString := stringDelimitList(List.map(expl,printExpStr),", ");
end printExpLstStr;

public function printExpStr "
  This function prints a complete expression.
"
  input Absyn.Exp inExp;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExp)
    local
      String s,s_1,s_2,s_3,sym,s1,s2,s1_1,s2_1,cs,ts,fs,cs_1,ts_1,fs_1,el,str,argsstr,s3,s3_1,res,res_1;
      String s4, s5, lhs_str, rhs_str, op_str;
      Integer i,p,p1,p2,pc,pt,pf,pstart,pstop,pstep;
      Absyn.ComponentRef c,fcn;
      Boolean b;
      Real r;
      Absyn.Exp e,e1,e2,t,f,start,stop,step,head,rest,inputExp,cond;
      Absyn.Operator op;
      list<tuple<Absyn.Exp, Absyn.Exp>> elseif_;
      Absyn.FunctionArgs args;
      list<Absyn.Exp> es;
      Absyn.MatchType matchType;
      list<Absyn.ElementItem> localDecls;
      list<Absyn.Case> cases;
      Option<String> comment;
      list<list<Absyn.Exp>> lstEs;
      Absyn.CodeNode cod;

    case (Absyn.INTEGER(value = i))
      equation
        s = intString(i);
      then
        s;

    case (Absyn.REAL(value = r))
      equation
        s = realString(r);
      then
        s;

    case (Absyn.CREF(componentRef = c))
      equation
        s = printComponentRefStr(c);
      then
        s;

    case (Absyn.STRING(value = s))
      equation
        s = stringAppendList({"\"", s, "\""});
      then
        s;

    case (Absyn.BOOL(value = b))
      equation
        s = printBoolStr(b);
      then
        s;

    case ((e as Absyn.BINARY(exp1 = e1,op = op,exp2 = e2)))
      equation
        lhs_str = printOperandStr(e1, e, true);
        rhs_str = printOperandStr(e2, e, false);
        op_str = opSymbol(op);
        s = stringAppendList({lhs_str, op_str, rhs_str});
      then
        s;

    case ((e as Absyn.UNARY(op = op,exp = e1)))
      equation
        s = printOperandStr(e1, e, false);
        op_str = opSymbol(op);
        s = stringAppendList({op_str, s});
      then
        s;

    case ((e as Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2)))
      equation
        lhs_str = printOperandStr(e1, e, true);
        rhs_str = printOperandStr(e2, e, false);
        op_str = opSymbol(op);
        s = stringAppendList({lhs_str, op_str, rhs_str});
      then
        s;

    case ((e as Absyn.LUNARY(op = op,exp = e1)))
      equation
        s = printOperandStr(e1, e, false);
        op_str = opSymbol(op);
        s = stringAppendList({op_str, s});
      then
        s;

    case ((e as Absyn.RELATION(exp1 = e1,op = op,exp2 = e2)))
      equation
        lhs_str = printOperandStr(e1, e, true);
        rhs_str = printOperandStr(e2, e, false);
        op_str = opSymbol(op);
        s = stringAppendList({lhs_str, op_str, rhs_str});
      then
        s;

    case ((e as Absyn.IFEXP(ifExp = cond,trueBranch = t,elseBranch = f,elseIfBranch = elseif_)))
      equation
        cs = printExpStr(cond);
        ts = printExpStr(t);
        fs = printExpStr(f);
        el = printElseifStr(elseif_);
        str = stringAppendList({"if ",cs," then ",ts,el," else ",fs});
      then
        str;

    case (Absyn.CALL(function_ = fcn,functionArgs = args))
      equation
        fs = printComponentRefStr(fcn);
        argsstr = printFunctionArgsStr(args);
        s = stringAppend(fs, "(");
        s_1 = stringAppend(s, argsstr);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;

    case (Absyn.PARTEVALFUNCTION(function_ = fcn,functionArgs = args))
      equation
        fs = printComponentRefStr(fcn);
        argsstr = printFunctionArgsStr(args);
        s = stringAppend("function ", fs);
        s_1 = stringAppend(s, "(");
        s_2 = stringAppend(s_1, argsstr);
        s_3 = stringAppend(s_2, ")");
      then
        s_3;

    case Absyn.ARRAY(arrayExp = es)
      equation
        s = printListStr(es, printExpStr, ",") "Does not need parentheses" ;
        s_1 = stringAppend("{", s);
        s_2 = stringAppend(s_1, "}");
      then
        s_2;

    case Absyn.LIST(exps = es)
      equation
        s = printListStr(es, printExpStr, ",") "Does not need parentheses" ;
        s_1 = stringAppend("{", s);
        s_2 = stringAppend(s_1, "}");
      then
        s_2;

    case Absyn.TUPLE(expressions = es)
      equation
        s = printListStr(es, printExpStr, ",") "Does not need parentheses" ;
        s_1 = stringAppend("(", s);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;

    case Absyn.MATRIX(matrix = lstEs)
      equation
        s = printListStr(lstEs, printRowStr, ";") "Does not need parentheses" ;
        s_1 = stringAppend("[", s);
        s_2 = stringAppend(s_1, "]");
      then
        s_2;

    case ((e as Absyn.RANGE(start = start,step = NONE(),stop = stop)))
      equation
        s1 = printOperandStr(start, e, false);
        s3 = printOperandStr(stop, e, false);
        s = stringAppendList({s1, ":", s3});
      then
        s;

    case ((e as Absyn.RANGE(start = start,step = SOME(step),stop = stop)))
      equation
        s1 = printOperandStr(start, e, false);
        s2 = printOperandStr(step, e, false);
        s3 = printOperandStr(stop, e, false);
        s = stringAppendList({s1, ":", s2, ":", s3});
      then
        s;

    case (Absyn.CODE(code = cod))
      equation
        res = printCodeStr(cod);
        res_1 = stringAppendList({"$Code(",res,")"});
      then
        res_1;

    case Absyn.END() then "end";

    // MetaModelica expressions
    case Absyn.CONS(head, rest)
      equation
        s1 = printExpStr(head);
        s2 = printExpStr(rest);
        s = stringAppendList({s1, "::", s2});
      then
        s;

    case Absyn.AS(s1, rest)
      equation
        s2 = printExpStr(rest);
        s = stringAppendList({s1, " as ", s2});
      then
        s;

    case Absyn.MATCHEXP(matchType, inputExp, localDecls, cases, comment)
      equation
        s1 = printMatchType(matchType);
        s2 = printExpStr(inputExp);
        s3 = unparseStringCommentOption(comment);
        s4 = unparseLocalElements(3, localDecls);
        s5 = getStringList(cases, printCaseStr, "\n");
        s = stringAppendList({s1, " ", s2, s3, s4, s5, "\n\tend ", s1});
      then
        s;

    case (_) then "#UNKNOWN EXPRESSION#";
  end matchcontinue;
end printExpStr;

function unparseLocalElements
"@author: adrpo
  unparses the local declarations of elements
  (they can appear only in MetaModelica)"
  input Integer indent;
  input list<Absyn.ElementItem> localDecls;
  output String outStr;
algorithm
  outStr := matchcontinue(indent, localDecls)
    local Integer i;  list<Absyn.ElementItem> dcls; String s;
    case (i, {}) then "\n";
    case (i, dcls)
      equation
        s = unparseElementitemStrLst(i, dcls);
        s = "\n\t  local\n" +& s;
      then s;
  end matchcontinue;
end unparseLocalElements;

function unparseLocalEquations
"@author: adrpo
  unparses the local declarations of elements
  (they can appear only in MetaModelica)"
  input Integer indent;
  input list<Absyn.EquationItem> localEqs;
  output String outStr;
algorithm
  outStr := matchcontinue(indent, localEqs)
    local Integer i;  list<Absyn.EquationItem> eq; String s;
    case (i, {}) then "\n";
    case (i, eq)
      equation
        s = unparseEquationitemStrLst(i, eq, "\n");
        s = "\t  equation\n" +& s;
      then s;
  end matchcontinue;
end unparseLocalEquations;

public function printCaseStr
"@author: adrpo
  MetaModelica case construct printing"
  input Absyn.Case cas;
  output String out;
algorithm
  out := matchcontinue cas
    local
      String s1, s2, s3, s4, s5, s;
      Absyn.Exp p;
      list<Absyn.ElementItem> l;
      list<Absyn.EquationItem> eq;
      Absyn.Exp r;
      Option<String> c;
      Option<Absyn.Exp> patternGuard;
    case Absyn.CASE(p, patternGuard, _, {}, {}, r, _, c, _)
      equation
        s1 = printExpStr(p);
        s4 = printExpStr(r);
        s5 = printPatternGuard(patternGuard);
        s = stringAppendList({"\tcase (", s1, ") ",s5,"then ", s4, ";"});
      then s;
    case Absyn.CASE(p, patternGuard, _, l, eq, r, _, c, _)
      equation
        s1 = printExpStr(p);
        s2 = unparseLocalElements(3, l);
        s3 = unparseLocalEquations(3, eq);
        s4 = printExpStr(r);
        s5 = printPatternGuard(patternGuard);
        s = stringAppendList({"\tcase (", s1, ")", s5, s2, s3, "\t  then ", s4, ";"});
      then s;
    case Absyn.ELSE({}, {}, r, _, c, _)
      equation
        s4 = printExpStr(r);
        s = stringAppendList({"\telse then ", s4, ";"});
      then s;
    case Absyn.ELSE(l, eq, r, _, c, _)
      equation
        s2 = unparseLocalElements(3, l);
        s3 = unparseLocalEquations(3, eq);
        s4 = printExpStr(r);
        s = stringAppendList({"\telse", s2, s3, "\t  then ", s4, ";"});
      then s;
  end matchcontinue;
end printCaseStr;

protected function printPatternGuard
  input Option<Absyn.Exp> oexp;
  output String str;
algorithm
  str := match oexp
    local
      Absyn.Exp exp;
    case NONE() then "";
    case SOME(exp) then " guard " +& printExpStr(exp) +& " ";
  end match;
end printPatternGuard;

public function printCodeStr
"Prettyprint Code to a string."
  input Absyn.CodeNode inCode;
  output String outString;
algorithm
  outString := match (inCode)
    local
      String s,s1,s2,res;
      Absyn.Path p;
      Absyn.ComponentRef cr;
      Boolean b;
      list<Absyn.EquationItem> eqitems;
      list<Absyn.AlgorithmItem> algitems;
      Absyn.Element elt;
      Absyn.Exp exp;
      Absyn.Modification m;
    case (Absyn.C_TYPENAME(path = p))
      equation
        s = printPathStr(p);
      then
        s;
    case (Absyn.C_VARIABLENAME(componentRef = cr))
      equation
        s = printComponentRefStr(cr);
      then
        s;
    case (Absyn.C_EQUATIONSECTION(boolean = b,equationItemLst = eqitems))
      equation
        s1 = selectString(b, "initial ", "");
        s2 = unparseEquationitemStrLst(1, eqitems, "\n");
        res = stringAppendList({s1,"equation ",s2});
      then
        res;
    case (Absyn.C_ALGORITHMSECTION(boolean = b,algorithmItemLst = algitems))
      equation
        s1 = selectString(b, "initial ", "");
        s2 = unparseAlgorithmStrLst(1, algitems, ";\n");
        res = stringAppendList({s1,"algorithm ",s2});
      then
        res;
    case (Absyn.C_ELEMENT(element = elt))
      equation
        res = unparseElementStr(1, elt);
      then
        res;
    case (Absyn.C_EXPRESSION(exp = exp))
      equation
        res = printExpStr(exp);
      then
        res;
    case (Absyn.C_MODIFICATION(modification = m))
      equation
        res = unparseModificationStr(m);
      then
        res;
  end match;
end printCodeStr;

protected function printElseifStr
"Prettyprint elseif to a string"
  input list<tuple<Absyn.Exp, Absyn.Exp>> inTplAbsynExpAbsynExpLst;
  output String outString;
algorithm
  outString := match (inTplAbsynExpAbsynExpLst)
    local
      String s1,s2,s3,str;
      Absyn.Exp ec,ee;
      list<tuple<Absyn.Exp, Absyn.Exp>> rest;
    case ({}) then "";
    case (((ec,ee) :: rest))
      equation
        s1 = printExpStr(ec);
        s2 = printExpStr(ee);
        s3 = printElseifStr(rest);
        str = stringAppendList({" elseif ",s1," then ",s2,s3});
      then
        str;
  end match;
end printElseifStr;

protected function printRowStr
"Prettyprint a list of expressions to a string."
  input list<Absyn.Exp> es;
  output String s;
algorithm
  s := printListStr(es, printExpStr, ",");
end printRowStr;

protected function printListStr
"Same as printList, except it returns a string instead of printing"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  input String inString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  outString := matchcontinue (inTypeALst,inFuncTypeTypeAToString,inString)
    local
      String s,srest,s_1,s_2,sep;
      Type_a h;
      FuncTypeType_aToString r;
      list<Type_a> t;
    case ({},_,_) then "";
    case ({h},r,_)
      equation
        s = r(h);
      then
        s;
    case ((h :: t),r,sep)
      equation
        s = r(h);
        srest = printListStr(t, r, sep);
        s_1 = stringAppend(s, sep);
        s_2 = stringAppend(s_1, srest);
      then
        s_2;
  end matchcontinue;
end printListStr;

public function opSymbol
"Make a string describing different operators."
  input Absyn.Operator inOperator;
  output String outString;
algorithm
  outString := match (inOperator)
    /* arithmetic operators */
    case (Absyn.ADD()) then " + ";
    case (Absyn.SUB()) then " - ";
    case (Absyn.MUL()) then " * ";
    case (Absyn.DIV()) then " / ";
    case (Absyn.POW()) then " ^ ";
    case (Absyn.UMINUS()) then "-";
    case (Absyn.UPLUS()) then "+";
    /* element-wise arithmetic operators */
    case (Absyn.ADD_EW()) then " .+ ";
    case (Absyn.SUB_EW()) then " .- ";
    case (Absyn.MUL_EW()) then " .* ";
    case (Absyn.DIV_EW()) then " ./ ";
    case (Absyn.POW_EW()) then " .^ ";
    case (Absyn.UMINUS_EW()) then " .-";
    case (Absyn.UPLUS_EW()) then " .+";
    /* logical operators */
    case (Absyn.AND()) then " and ";
    case (Absyn.OR()) then " or ";
    case (Absyn.NOT()) then "not ";
    /* relational operators */
    case (Absyn.LESS()) then " < ";
    case (Absyn.LESSEQ()) then " <= ";
    case (Absyn.GREATER()) then " > ";
    case (Absyn.GREATEREQ()) then " >= ";
    case (Absyn.EQUAL()) then " == ";
    case (Absyn.NEQUAL()) then " <> ";
  end match;
end opSymbol;

public function opSymbolCompact
"same as opSymbol but without spaces included
  used for operator overload resolving.
  Some of them are not supported ?? but have them
  anyway"
  input Absyn.Operator inOperator;
  output String outString;
algorithm
  outString := match (inOperator)
    /* arithmetic operators */
    case (Absyn.ADD()) then "+";
    case (Absyn.SUB()) then "-";
    case (Absyn.MUL()) then "*";
    case (Absyn.DIV()) then "/";
    case (Absyn.POW()) then "^";
    case (Absyn.UMINUS()) then "-";
    case (Absyn.UPLUS()) then "+";
    /* element-wise arithmetic operators */
    case (Absyn.ADD_EW()) then "+";
    case (Absyn.SUB_EW()) then "-";
    case (Absyn.MUL_EW()) then "*";
    case (Absyn.DIV_EW()) then "/";
    case (Absyn.POW_EW()) then "^";
    case (Absyn.UMINUS_EW()) then "-";
    // case (Absyn.UPLUS_EW()) then "+";
    /* logical operators */
    case (Absyn.AND()) then "and";
    case (Absyn.OR()) then "or";
    case (Absyn.NOT()) then "not";
    /* relational operators */
    case (Absyn.LESS()) then "<";
    case (Absyn.LESSEQ()) then "<=";
    case (Absyn.GREATER()) then ">";
    case (Absyn.GREATEREQ()) then ">=";
    case (Absyn.EQUAL()) then "==";
    case (Absyn.NEQUAL()) then "<>";
  else fail();
  end match;
end opSymbolCompact;

protected function dumpOpSymbol
"Make a string describing different operators."
  input Absyn.Operator inOperator;
  output String outString;
algorithm
  outString := match (inOperator)
    /* arithmetic operators */
    case (Absyn.ADD()) then "Absyn.ADD";
    case (Absyn.SUB()) then "Absyn.SUB";
    case (Absyn.MUL()) then "Absyn.MUL";
    case (Absyn.DIV()) then "Absyn.DIV";
    case (Absyn.POW()) then "Absyn.POW";
    case (Absyn.UMINUS()) then "Absyn.UMINUS";
    case (Absyn.UPLUS()) then "Absyn.UPLUS";
    /* element-wise arithmetic operators */
    case (Absyn.ADD_EW()) then "Absyn.ADD_EW";
    case (Absyn.SUB_EW()) then "Absyn.SUB_EW";
    case (Absyn.MUL_EW()) then "Absyn.MUL_EW";
    case (Absyn.DIV_EW()) then "Absyn.DIV_EW";
    case (Absyn.POW_EW()) then "Absyn.POW_EW";
    case (Absyn.UMINUS_EW()) then "Absyn.UMINUS_EW";
    case (Absyn.UPLUS_EW()) then "Absyn.UPLUS_EW";
    /* logical operators */
    case (Absyn.AND()) then "Absyn.AND";
    case (Absyn.OR()) then "Absyn.OR";
    case (Absyn.NOT()) then "Absyn.NOT";
    /* relational operators */
    case (Absyn.LESS()) then "Absyn.LESS";
    case (Absyn.LESSEQ()) then "Absyn.LESSEQ";
    case (Absyn.GREATER()) then "Absyn.GREATER";
    case (Absyn.GREATEREQ()) then "Absyn.GREATEREQ";
    case (Absyn.EQUAL()) then "Absyn.EQUAL";
    case (Absyn.NEQUAL()) then "Absyn.NEQUAL";
  end match;
end dumpOpSymbol;

/*
 *
 * Utility functions
 * These are utility functions used in some of the other functions.
 *
 */

public function selectString
"Select one of the two strings depending on boolean value."
  input Boolean inBoolean1;
  input String inString2;
  input String inString3;
  output String outString;
algorithm
  outString:=
  match (inBoolean1,inString2,inString3)
    local
      String a,b;
    case (true,a,b) then a;
    case (false,a,b) then b;
  end match;
end selectString;

public function printSelect "
  Select one of the two string depending on boolean value
  and print it on the Print buffer.
"
  input Boolean f;
  input String yes;
  input String no;
protected
  String res;
algorithm
  res := selectString(f, yes, no);
  Print.printBuf(res);
end printSelect;

public function printOption "
  Prints an option value given a print function.
"
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  _:=
  match (inTypeAOption,inFuncTypeTypeATo)
    local
      Type_a x;
      FuncTypeType_aTo r;
    case (NONE(),_)
      equation
        Print.printBuf("NONE()");
      then
        ();
    case (SOME(x),r)
      equation
        Print.printBuf("SOME(");
        r(x);
        Print.printBuf(")");
      then
        ();
  end match;
end printOption;

public function printListDebug "
  Prints a list of values given a print function and a caller string.
"
  input String inString1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aTo inFuncTypeTypeATo3;
  input String inString4;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  _ := match(inString1,inTypeALst2,inFuncTypeTypeATo3,inString4)
    local
      String caller,s1,sep;
      Type_a h;
      FuncTypeType_aTo r;
      list<Type_a> rest;
    case (_,{},_,_) then ();
    case (caller,{h},r,_)
      equation
        r(h);
      then
        ();
    case (caller,(h :: rest),r,sep)
      equation
        s1 = stringAppend("print_list_debug-3 from ", caller);
        r(h);
        Print.printBuf(sep);
        printListDebug(s1, rest, r, sep);
      then
        ();
  end match;
end printListDebug;

public function printList "
  Prints a list of values given a print function.
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input String inString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  _:=
  matchcontinue (inTypeALst,inFuncTypeTypeATo,inString)
    local
      Type_a h;
      FuncTypeType_aTo r;
      list<Type_a> t;
      String sep;
    case ({},_,_) then ();
    case ({h},r,_)
      equation
        r(h);
      then
        ();
    case ((h :: t),r,sep)
      equation
        r(h);
        Print.printBuf(sep);
        printList(t, r, sep);
      then
        ();
  end matchcontinue;
end printList;

public function getStringList "a value to a string.
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  input String inString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  outString:=
  matchcontinue (inTypeALst,inFuncTypeTypeAToString,inString)
    local
      String s,s_1,srest,s_2,sep;
      Type_a h;
      FuncTypeType_aToString r;
      list<Type_a> t;
    case ({},_,_) then "";
    case ({h},r,_)
      equation
        s = r(h);
      then
        s;
    case ((h :: t),r,sep)
      equation
        s = r(h);
        s_1 = stringAppend(s, sep);
        srest = getStringList(t, r, sep);
        s_2 = stringAppend(s_1, srest);
      then
        s_2;
  end matchcontinue;
end getStringList;

public function printBool "
  Print a bool value to the Print buffer
"
  input Boolean b;
algorithm
  printSelect(b, "true", "false");
end printBool;

public function getOptionStr "Retrieve the string from a string option.
  If NONE() return empty string.
"
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  outString:=
  match (inTypeAOption,inFuncTypeTypeAToString)
    local
      String str;
      Type_a a;
      FuncTypeType_aToString r;
    case (SOME(a),r)
      equation
        str = r(a);
      then
        str;
    case (NONE(),_) then "";
  end match;
end getOptionStr;

public function getOptionStrDefault "Retrieve the string from a string option.
  If NONE() return default string.
"
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  input String inString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  outString:=
  matchcontinue (inTypeAOption,inFuncTypeTypeAToString,inString)
    local
      String str,def;
      Type_a a;
      FuncTypeType_aToString r;
    case (SOME(a),r,_)
      equation
        str = r(a);
      then
        str;
    case (NONE(),_,def) then def;
  end matchcontinue;
end getOptionStrDefault;

public function getOptionWithConcatStr "
  Get option string value using a function translating the value to a string
  and concatenate with an additional suffix string.
"
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  input String inString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  outString:=
  match (inTypeAOption,inFuncTypeTypeAToString,inString)
    local
      String str,str_1,default_str;
      Type_a a;
      FuncTypeType_aToString r;
    case (SOME(a),r,default_str) /* suffix */
      equation
        str = r(a);
        str_1 = stringAppend(default_str, str);
      then
        str_1;
    case (NONE(),_,default_str) then "";
  end match;
end getOptionWithConcatStr;

protected function unparseStringCommentOption "
  Prettyprint a string comment option, which is a string option.
"
  input Option<String> inStringOption;
  output String outString;
algorithm
  outString:=
  match (inStringOption)
    local String str,s;
    case (NONE()) then "";
    case (SOME(s))
      equation
        str = stringAppendList({" \"",s,"\""});
      then
        str;
  end match;
end unparseStringCommentOption;

protected function printStringCommentOption "
  Print a string comment option on the Print buffer
"
  input Option<String> inStringOption;
algorithm
  _:=
  match (inStringOption)
    local String str,s;
    case (NONE())
      equation
        Print.printBuf("NONE()");
      then
        ();
    case (SOME(s))
      equation
        str = stringAppendList({"SOME(\"",s,"\")"});
        Print.printBuf(str);
      then
        ();
  end match;
end printStringCommentOption;

public function printBoolStr "
 Prints a bool to a string.
"
  input Boolean b;
  output String s;
algorithm
  s := selectString(b, "true", "false");
end printBoolStr;

public function indentStr "
  Creates an indentation string, i.e. whitespaces, given and indentation
  level.
"
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger)
    local
      Integer i_1,i;
      String s1,res;
    case (0) then "";
    case (i)
      equation
        true = i > 0;
        i_1 = i - 1;
        s1 = indentStr(i_1);
        res = stringAppend(s1, "  ") "Indent using two whitespaces" ;
      then
        res;
    else "";
  end matchcontinue;
end indentStr;

public function unparseTypeSpec "adrpo added metamodelica stuff"
  input Absyn.TypeSpec inTypeSpec;
  output String outString;
algorithm
  outString:=
  match (inTypeSpec)
    local
      String str,s,str1,str2,str3;
      Absyn.Path path;
      Option<list<Absyn.Subscript>> adim;
      list<Absyn.TypeSpec> typeSpecLst;
    case (Absyn.TPATH(path = path,arrayDim = adim))
      equation
        str = Absyn.pathString(path);
        s = getOptionStr(adim, printArraydimStr);
        str = stringAppend(str, s);
      then
        str;
    case (Absyn.TCOMPLEX(path = path,typeSpecs = typeSpecLst,arrayDim = adim))
      equation
        str1 = Absyn.pathString(path);
        str2 = unparseTypeSpecLst(typeSpecLst);
        str3 = stringAppendList({str1,"<",str2,">"});
        s = getOptionStr(adim, printArraydimStr);
        str = stringAppend(str3, s);
      then
        str;
  end match;
end unparseTypeSpec;

public function unparseTypeSpecLst
  input list<Absyn.TypeSpec> inTypeSpecLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inTypeSpecLst)
    local
      String str, str1, str2, str3;
      Absyn.TypeSpec x;
      list<Absyn.TypeSpec> rest;
    case ({x})
      equation
        str = unparseTypeSpec(x);
      then
        str;
    case (x::rest)
      equation
        str1 = unparseTypeSpec(x);
        str2 = unparseTypeSpecLst(rest);
        str3 = stringAppendList({str1,", ",str2});
      then
        str3;
  end matchcontinue;
end unparseTypeSpecLst;

public function printTypeSpec
  input Absyn.TypeSpec typeSpec;
protected
  String str;
algorithm
  str := unparseTypeSpec(typeSpec);
  print(str);
end printTypeSpec;

public function stdout "
  Prints the text sent to the print buffer (Print.mo) to stdout (i.e.
  using MetaModelica Compiler (MMC) standard print). After printing, the print buffer is cleared.
"
protected
  String str;
algorithm
  str := Print.getString();
  print(str);
  Print.clearBuf();
end stdout;

public function getAstAsCorbaString
  input Absyn.Program program;
algorithm
  _ := match program
    local
      list<Absyn.Class> classes;
      Absyn.Within within_;
      Absyn.TimeStamp globalBuildTimes;
    case Absyn.PROGRAM(classes = classes, within_ = within_, globalBuildTimes = globalBuildTimes)
      equation
        Print.printBuf("record Absyn.PROGRAM\nclasses = ");
        printListAsCorbaString(classes,printClassAsCorbaString,",\n");
        Print.printBuf(",\nwithin_ = ");
        printWithinAsCorbaString(within_);
        Print.printBuf(",\nglobalBuildTimes = ");
        printTimeStampAsCorbaString(globalBuildTimes);
        Print.printBuf("\nend Absyn.PROGRAM;");
      then ();
  end match;
end getAstAsCorbaString;

protected function printPathAsCorbaString
  input Absyn.Path inPath;
algorithm
  _ := match inPath
    local
      String s;
      Absyn.Path p;
    case Absyn.QUALIFIED(name = s, path = p)
      equation
        Print.printBuf("record Absyn.QUALIFIED name = \"");
        Print.printBuf(s);
        Print.printBuf("\", path = ");
        printPathAsCorbaString(p);
        Print.printBuf(" end Absyn.QUALIFIED;");
      then ();
    case Absyn.IDENT(name = s)
      equation
        Print.printBuf("record Absyn.IDENT name = \"");
        Print.printBuf(s);
        Print.printBuf("\" end Absyn.IDENT;");
      then ();
    case Absyn.FULLYQUALIFIED(path = p)
      equation
        Print.printBuf("record Absyn.FULLYQUALIFIED path = \"");
        printPathAsCorbaString(p);
        Print.printBuf("\" end Absyn.FULLYQUALIFIED;");
      then ();
  end match;
end printPathAsCorbaString;


protected function printComponentRefAsCorbaString
  input Absyn.ComponentRef cref;
algorithm
  _ := match cref
    local
      String s;
      Absyn.ComponentRef p;
      list<Absyn.Subscript> subscripts;
    case Absyn.CREF_QUAL(name = s, subscripts = subscripts, componentRef = p)
      equation
        Print.printBuf("record Absyn.CREF_QUAL name = \"");
        Print.printBuf(s);
        Print.printBuf("\", subscripts = ");
        printListAsCorbaString(subscripts, printSubscriptAsCorbaString, ",");
        Print.printBuf(", componentRef = ");
        printComponentRefAsCorbaString(p);
        Print.printBuf(" end Absyn.CREF_QUAL;");
      then ();
    case Absyn.CREF_IDENT(name = s, subscripts = subscripts)
      equation
        Print.printBuf("record Absyn.CREF_IDENT name = \"");
        Print.printBuf(s);
        Print.printBuf("\", subscripts = ");
        printListAsCorbaString(subscripts, printSubscriptAsCorbaString, ",");
        Print.printBuf(" end Absyn.CREF_IDENT;");
      then ();
    case Absyn.ALLWILD()
      equation
        Print.printBuf("record Absyn.ALLWILD end Absyn.ALLWILD;");
      then ();
    case Absyn.WILD()
      equation
        Print.printBuf("record Absyn.WILD end Absyn.WILD;");
      then ();
    case Absyn.CREF_INVALID(componentRef = p)
      equation
        Print.printBuf("record Absyn.CREF_INVALID componentRef = ");
        printComponentRefAsCorbaString(p);
        Print.printBuf(" end Absyn.CREF_INVALID;");
      then
        ();
  end match;
end printComponentRefAsCorbaString;

protected function printWithinAsCorbaString
  input Absyn.Within within_;
algorithm
  _ := match within_
    local
      Absyn.Path path;
    case Absyn.WITHIN(path = path)
      equation
        Print.printBuf("record Absyn.WITHIN path = ");
        printPathAsCorbaString(path);
        Print.printBuf(" end Absyn.WITHIN;");
      then ();
    case Absyn.TOP()
      equation
        Print.printBuf("record Absyn.TOP end Absyn.TOP;");
      then ();
  end match;
end printWithinAsCorbaString;

protected function printTimeStampAsCorbaString
  input Absyn.TimeStamp timeStamp;
algorithm
  _ := match timeStamp
    local
      Real r1,r2;
    case Absyn.TIMESTAMP(lastBuildTime = r1, lastEditTime = r2)
      equation
        Print.printBuf("record Absyn.TIMESTAMP lastBuildTime = ");
        Print.printBuf(realString(r1));
        Print.printBuf(", lastEditTime = ");
        Print.printBuf(realString(r2));
        Print.printBuf(" end Absyn.TIMESTAMP;");
      then ();
  end match;
end printTimeStampAsCorbaString;

protected function printClassAsCorbaString
  input Absyn.Class cl;
algorithm
  _ := match cl
    local
      String name;
      Boolean partialPrefix, finalPrefix, encapsulatedPrefix;
      Absyn.Restriction restriction;
      Absyn.ClassDef    body;
      Absyn.Info info;
    case Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,body,info)
      equation
        Print.printBuf("record Absyn.CLASS name = \"");
        Print.printBuf(name);
        Print.printBuf("\", partialPrefix = ");
        Print.printBuf(Util.if_(partialPrefix,"true","false"));
        Print.printBuf(", finalPrefix = ");
        Print.printBuf(Util.if_(finalPrefix,"true","false"));
        Print.printBuf(", encapsulatedPrefix = ");
        Print.printBuf(Util.if_(encapsulatedPrefix,"true","false"));
        Print.printBuf(", restriction = ");
        printRestrictionAsCorbaString(restriction);
        Print.printBuf(", body = ");
        printClassDefAsCorbaString(body);
        Print.printBuf(", info = ");
        printInfoAsCorbaString(info);
        Print.printBuf(" end Absyn.CLASS;");
      then ();
    else equation Error.addMessage(Error.INTERNAL_ERROR,{"printClassAsCorbaString failed"}); then fail();
  end match;
end printClassAsCorbaString;

protected function printInfoAsCorbaString
  input Absyn.Info info;
algorithm
  _ := match info
    local
      String fileName;
      Boolean isReadOnly;
      Integer lineNumberStart,columnNumberStart,lineNumberEnd,columnNumberEnd;
      Absyn.TimeStamp buildTimes;
    case Absyn.INFO(fileName,isReadOnly,lineNumberStart,columnNumberStart,lineNumberEnd,columnNumberEnd,buildTimes)
      equation
        Print.printBuf("record Absyn.INFO fileName = \"");
        Print.printBuf(fileName);
        Print.printBuf("\", isReadOnly = ");
        Print.printBuf(Util.if_(isReadOnly,"true","false"));
        Print.printBuf(", lineNumberStart = ");
        Print.printBuf(intString(lineNumberStart));
        Print.printBuf(", columnNumberStart = ");
        Print.printBuf(intString(columnNumberStart));
        Print.printBuf(", lineNumberEnd = ");
        Print.printBuf(intString(lineNumberEnd));
        Print.printBuf(", columnNumberEnd = ");
        Print.printBuf(intString(columnNumberEnd));
        Print.printBuf(", buildTimes = ");
        printTimeStampAsCorbaString(buildTimes);
        Print.printBuf(" end Absyn.INFO;");
      then ();
    else equation Error.addMessage(Error.INTERNAL_ERROR,{"printInfoAsCorbaString failed"}); then fail();
  end match;
end printInfoAsCorbaString;

protected function printClassDefAsCorbaString
  input Absyn.ClassDef classDef;
algorithm
  _ := match classDef
    local
      list<Absyn.ClassPart> classParts;
      Option<String>  optString;
      Absyn.TypeSpec typeSpec;
      Absyn.ElementAttributes attributes;
      list<Absyn.ElementArg> arguments,modifications;
      Option<Absyn.Comment> comment;
      Absyn.EnumDef enumLiterals;
      list<Absyn.Path> functionNames;
      String baseClassName;
      Absyn.Path functionName;
      list<String> typeVars,vars;
      list<Absyn.NamedArg> classAttrs;
      list<Absyn.Annotation> ann;
    case Absyn.PARTS(typeVars,classAttrs,classParts,ann,optString)
      equation
        Print.printBuf("record Absyn.PARTS typeVars = {");
        Print.printBuf(stringDelimitList(typeVars, ","));
        Print.printBuf("}, classParts = ");
        printListAsCorbaString(classParts, printClassPartAsCorbaString, ",");
        Print.printBuf(", ann = ");
        printListAsCorbaString(ann, printAnnotationAsCorbaString, ",");
        Print.printBuf(", comment = ");
        printStringCommentOption(optString);
        Print.printBuf(" end Absyn.PARTS;");
      then ();
    case Absyn.DERIVED(typeSpec,attributes,arguments,comment)
      equation
        Print.printBuf("record Absyn.DERIVED typeSpec = ");
        printTypeSpecAsCorbaString(typeSpec);
        Print.printBuf(", attributes = ");
        printElementAttributesAsCorbaString(attributes);
        Print.printBuf(", arguments = ");
        printListAsCorbaString(arguments, printElementArgAsCorbaString, ",");
        Print.printBuf(", comment = ");
        printOption(comment, printCommentAsCorbaString);
        Print.printBuf("end Absyn.DERIVED;");
      then ();
    case Absyn.ENUMERATION(enumLiterals,comment)
      equation
        Print.printBuf("record Absyn.ENUMERATION enumLiterals = ");
        printEnumDefAsCorbaString(enumLiterals);
        Print.printBuf(", comment = ");
        printOption(comment, printCommentAsCorbaString);
        Print.printBuf("end Absyn.ENUMERATION;");
      then ();
    case Absyn.OVERLOAD(functionNames,comment)
      equation
        Print.printBuf("record Absyn.OVERLOAD functionNames = ");
        printListAsCorbaString(functionNames, printPathAsCorbaString, ",");
        Print.printBuf(", comment = ");
        printOption(comment, printCommentAsCorbaString);
        Print.printBuf("end Absyn.OVERLOAD;");
      then ();
    case Absyn.CLASS_EXTENDS(baseClassName,modifications,optString,classParts,ann)
      equation
        Print.printBuf("record Absyn.CLASS_EXTENDS baseClassName = \"");
        Print.printBuf(baseClassName);
        Print.printBuf("\", modifications = ");
        printListAsCorbaString(modifications, printElementArgAsCorbaString, ",");
        Print.printBuf(", comment = ");
        printStringCommentOption(optString);
        Print.printBuf(", parts = ");
        printListAsCorbaString(classParts,printClassPartAsCorbaString,",");
        Print.printBuf(", ann = ");
        printListAsCorbaString(ann, printAnnotationAsCorbaString, ",");
        Print.printBuf("end Absyn.CLASS_EXTENDS;");
      then ();
    case Absyn.PDER(functionName,vars,comment)
      equation
        Print.printBuf("record Absyn.PDER functionName = ");
        printPathAsCorbaString(functionName);
        Print.printBuf(", vars = ");
        printListAsCorbaString(vars, printStringAsCorbaString, ",");
        Print.printBuf(", comment = ");
        printOption(comment, printCommentAsCorbaString);
        Print.printBuf("end Absyn.PDER;");
      then ();
    else equation Error.addMessage(Error.INTERNAL_ERROR,{"printClassDefAsCorbaString failed"}); then fail();
  end match;
end printClassDefAsCorbaString;

protected function printEnumDefAsCorbaString
  input Absyn.EnumDef enumDef;
algorithm
  _ := match enumDef
    local
      list<Absyn.EnumLiteral> enumLiterals;
    case Absyn.ENUMLITERALS(enumLiterals)
      equation
        Print.printBuf("record Absyn.ENUMLITERALS enumLiterals = ");
        printListAsCorbaString(enumLiterals, printEnumLiteralAsCorbaString, ",");
        Print.printBuf("end Absyn.ENUMLITERALS;");
      then ();
    case Absyn.ENUM_COLON()
      equation
        Print.printBuf("record Absyn.ENUM_COLON end Absyn.ENUM_COLON;");
      then ();
    else equation Error.addMessage(Error.INTERNAL_ERROR,{"printEnumDefAsCorbaString failed"}); then fail();
  end match;
end printEnumDefAsCorbaString;

protected function printEnumLiteralAsCorbaString
  input Absyn.EnumLiteral enumLit;
algorithm
  _ := match enumLit
    local
      String literal;
      Option<Absyn.Comment> comment;
    case Absyn.ENUMLITERAL(literal,comment)
      equation
        Print.printBuf("record Absyn.ENUMLITERAL literal = \"");
        Print.printBuf(literal);
        Print.printBuf("\", comment = ");
        printOption(comment, printCommentAsCorbaString);
        Print.printBuf("end Absyn.ENUMLITERAL;");
      then ();
    else equation Error.addMessage(Error.INTERNAL_ERROR,{"printEnumLiteralAsCorbaString failed"}); then fail();
  end match;
end printEnumLiteralAsCorbaString;

protected function printRestrictionAsCorbaString
  input Absyn.Restriction r;
algorithm
  _ := match (r)
    local
      Absyn.Path path;
      Integer i;
      Absyn.FunctionRestriction functionRestriction;

    case Absyn.R_CLASS()
      equation
        Print.printBuf("record Absyn.R_CLASS end Absyn.R_CLASS;");
      then ();

    case Absyn.R_OPTIMIZATION()
      equation
        Print.printBuf("record Absyn.R_OPTIMIZATION end Absyn.R_OPTIMIZATION;");
      then ();

    case Absyn.R_MODEL()
      equation
        Print.printBuf("record Absyn.R_MODEL end Absyn.R_MODEL;");
      then ();

    case Absyn.R_RECORD()
      equation
        Print.printBuf("record Absyn.R_RECORD end Absyn.R_RECORD;");
      then ();

    case Absyn.R_BLOCK()
      equation
        Print.printBuf("record Absyn.R_BLOCK end Absyn.R_BLOCK;");
      then ();

    case Absyn.R_CONNECTOR()
      equation
        Print.printBuf("record Absyn.R_CONNECTOR end Absyn.R_CONNECTOR;");
      then ();

    case Absyn.R_EXP_CONNECTOR()
      equation
        Print.printBuf("record Absyn.R_EXP_CONNECTOR end Absyn.R_EXP_CONNECTOR;");
      then ();

    case Absyn.R_TYPE()
      equation
        Print.printBuf("record Absyn.R_TYPE end Absyn.R_TYPE;");
      then ();

    case Absyn.R_PACKAGE()
      equation
        Print.printBuf("record Absyn.R_PACKAGE end Absyn.R_PACKAGE;");
      then ();

    case Absyn.R_FUNCTION(functionRestriction=functionRestriction)
      equation
        Print.printBuf("record Absyn.R_FUNCTION functionRestriction = ");
        printFunctionRestrictionAsCorbaString(functionRestriction);
        Print.printBuf("end Absyn.R_FUNCTION;");
      then ();

    case Absyn.R_OPERATOR()
      equation
        Print.printBuf("record Absyn.R_OPERATOR end Absyn.R_OPERATOR;");
      then ();

    case Absyn.R_ENUMERATION()
      equation
        Print.printBuf("record Absyn.R_ENUMERATION end Absyn.R_ENUMERATION;");
      then ();

    case Absyn.R_PREDEFINED_INTEGER()
      equation
        Print.printBuf("record Absyn.R_PREDEFINED_INTEGER end Absyn.R_PREDEFINED_INTEGER;");
      then ();

    case Absyn.R_PREDEFINED_REAL()
      equation
        Print.printBuf("record Absyn.R_PREDEFINED_REAL end Absyn.R_PREDEFINED_REAL;");
      then ();

    case Absyn.R_PREDEFINED_STRING()
      equation
        Print.printBuf("record Absyn.R_PREDEFINED_STRING end Absyn.R_PREDEFINED_STRING;");
      then ();

    case Absyn.R_PREDEFINED_BOOLEAN()
      equation
        Print.printBuf("record Absyn.R_PREDEFINED_BOOLEAN end Absyn.R_PREDEFINED_BOOLEAN;");
      then ();

    case Absyn.R_PREDEFINED_ENUMERATION()
      equation
        Print.printBuf("record Absyn.R_PREDEFINED_ENUMERATION end Absyn.R_PREDEFINED_ENUMERATION;");
      then ();

    case Absyn.R_UNIONTYPE()
      equation
        Print.printBuf("record Absyn.R_UNIONTYPE end Absyn.R_UNIONTYPE;");
      then ();

    case Absyn.R_METARECORD(name=path,index=i)
      equation
        Print.printBuf("record Absyn.R_METARECORD name = ");
        printPathAsCorbaString(path);
        Print.printBuf(", index = ");
        Print.printBuf(intString(i));
        Print.printBuf(" end Absyn.R_METARECORD;");
      then ();

    case Absyn.R_UNKNOWN()
      equation
        Print.printBuf("record Absyn.R_UNKNOWN end Absyn.R_UNKNOWN;");
      then ();

    else equation Error.addMessage(Error.INTERNAL_ERROR,{"printRestrictionAsCorbaString failed"}); then fail();
  end match;
end printRestrictionAsCorbaString;

protected function printFunctionRestrictionAsCorbaString
  input Absyn.FunctionRestriction functionRestriction;
algorithm
  _ := match functionRestriction
    local Absyn.FunctionPurity purity;
    case Absyn.FR_NORMAL_FUNCTION(purity)
      equation
        Print.printBuf("record Absyn.FR_NORMAL_FUNCTION purity = ");
        printFunctionPurityAsCorbaString(purity);
        Print.printBuf(" end Absyn.FR_NORMAL_FUNCTION;");
      then ();
    case Absyn.FR_OPERATOR_FUNCTION()
      equation
        Print.printBuf("record Absyn.FR_OPERATOR_FUNCTION end Absyn.FR_OPERATOR_FUNCTION;");
      then ();
    case Absyn.FR_PARALLEL_FUNCTION()
      equation
        Print.printBuf("record Absyn.FR_PARALLEL_FUNCTION end Absyn.FR_PARALLEL_FUNCTION;");
      then ();
    case Absyn.FR_KERNEL_FUNCTION()
      equation
        Print.printBuf("record Absyn.FR_KERNEL_FUNCTION end Absyn.FR_KERNEL_FUNCTION;");
      then ();
  end match;
end printFunctionRestrictionAsCorbaString;

protected function printFunctionPurityAsCorbaString
  input Absyn.FunctionPurity functionPurity;
algorithm
  _ := match functionPurity
    case Absyn.PURE()
      equation
        Print.printBuf("record Absyn.PURE end Absyn.PURE;");
      then ();
    case Absyn.IMPURE()
      equation
        Print.printBuf("record Absyn.IMPURE end Absyn.IMPURE;");
      then ();
    case Absyn.NO_PURITY()
      equation
        Print.printBuf("record Absyn.NO_PURITY end Absyn.NO_PURITY;");
      then ();
  end match;
end printFunctionPurityAsCorbaString;

protected function printClassPartAsCorbaString
  input Absyn.ClassPart classPart;
algorithm
  _ := match classPart
    local
      list<Absyn.ElementItem> contents;
      list<Absyn.EquationItem> eqContents;
      list<Absyn.AlgorithmItem> algContents;
      Absyn.ExternalDecl externalDecl;
      Option<Absyn.Annotation> annotation_;
    case Absyn.PUBLIC(contents)
      equation
        Print.printBuf("\nrecord Absyn.PUBLIC contents = ");
        printListAsCorbaString(contents, printElementItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.PUBLIC;");
      then ();
    case Absyn.PROTECTED(contents)
      equation
        Print.printBuf("\nrecord Absyn.PROTECTED contents = ");
        printListAsCorbaString(contents, printElementItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.PROTECTED;");
      then ();
    case Absyn.EQUATIONS(eqContents)
      equation
        Print.printBuf("\nrecord Absyn.EQUATIONS contents = ");
        printListAsCorbaString(eqContents, printEquationItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.EQUATIONS;");
      then ();
    case Absyn.INITIALEQUATIONS(eqContents)
      equation
        Print.printBuf("\nrecord Absyn.INITIALEQUATIONS contents = ");
        printListAsCorbaString(eqContents, printEquationItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.INITIALEQUATIONS;");
      then ();
    case Absyn.ALGORITHMS(algContents)
      equation
        Print.printBuf("\nrecord Absyn.ALGORITHMS contents = ");
        printListAsCorbaString(algContents, printAlgorithmItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.ALGORITHMS;");
      then ();
    case Absyn.INITIALALGORITHMS(algContents)
      equation
        Print.printBuf("\nrecord Absyn.INITIALALGORITHMS contents = ");
        printListAsCorbaString(algContents, printAlgorithmItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.INITIALALGORITHMS;");
      then ();
    case Absyn.EXTERNAL(externalDecl,annotation_)
      equation
        Print.printBuf("\nrecord Absyn.EXTERNAL externalDecl = ");
        printExternalDeclAsCorbaString(externalDecl);
        Print.printBuf(", annotation_ = ");
        printOption(annotation_, printAnnotationAsCorbaString);
        Print.printBuf(" end Absyn.EXTERNAL;");
      then ();
    else equation Error.addMessage(Error.INTERNAL_ERROR,{"printClassPartAsCorbaString failed"}); then fail();
  end match;
end printClassPartAsCorbaString;

protected function printExternalDeclAsCorbaString
  input Absyn.ExternalDecl decl;
algorithm
  _ := match decl
    local
      Option<String> funcName, lang;
      Option<Absyn.ComponentRef> output_;
      list<Absyn.Exp> args;
      Option<Absyn.Annotation> annotation_;
    case Absyn.EXTERNALDECL(funcName,lang,output_,args,annotation_)
      equation
        Print.printBuf("record Absyn.EXTERNALDECL funcName = ");
        printStringCommentOption(funcName);
        Print.printBuf(", lang = ");
        printStringCommentOption(lang);
        Print.printBuf(", output_ = ");
        printOption(output_, printComponentRefAsCorbaString);
        Print.printBuf(", args = ");
        printListAsCorbaString(args,printExpAsCorbaString,",");
        Print.printBuf(", annotation_ = ");
        printOption(annotation_, printAnnotationAsCorbaString);
        Print.printBuf(" end Absyn.EXTERNALDECL;");
      then ();
    else equation Error.addMessage(Error.INTERNAL_ERROR,{"printExternalDeclAsCorbaString failed"}); then fail();
  end match;
end printExternalDeclAsCorbaString;

protected function printElementItemAsCorbaString
  input Absyn.ElementItem el;
algorithm
  _ := match el
    local
      Absyn.Element element;
      Absyn.Annotation annotation_;
      String cmt;
    case Absyn.ELEMENTITEM(element)
      equation
        Print.printBuf("record Absyn.ELEMENTITEM element = ");
        printElementAsCorbaString(element);
        Print.printBuf(" end Absyn.ELEMENTITEM;");
      then ();
    case Absyn.LEXER_COMMENT(cmt)
      equation
        Print.printBuf("record Absyn.ELEMENTITEM element = \"");
        Print.printBuf(cmt);
        Print.printBuf("\" end Absyn.ELEMENTITEM;");
      then ();
    else equation Error.addMessage(Error.INTERNAL_ERROR,{"printElementItemAsCorbaString failed"}); then fail();
  end match;
end printElementItemAsCorbaString;

protected function printElementAsCorbaString
  input Absyn.Element el;
algorithm
  _ := match el
    local
      Boolean finalPrefix;
      Option<Absyn.RedeclareKeywords> redeclareKeywords;
      Absyn.InnerOuter innerOuter;
      String name, string;
      Absyn.ElementSpec specification;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constrainClass;
      list<Absyn.NamedArg> args;
      Option<String> optName;
    case Absyn.ELEMENT(finalPrefix,redeclareKeywords,innerOuter,specification,info,constrainClass)
      equation
        Print.printBuf("\nrecord Absyn.ELEMENT finalPrefix = ");
        Print.printBuf(Util.if_(finalPrefix,"true","false"));
        Print.printBuf(",redeclareKeywords = ");
        printOption(redeclareKeywords, printRedeclareKeywordsAsCorbaString);
        Print.printBuf(",innerOuter = ");
        printInnerOuterAsCorbaString(innerOuter);
        Print.printBuf(",specification = ");
        printElementSpecAsCorbaString(specification);
        Print.printBuf(",info = ");
        printInfoAsCorbaString(info);
        Print.printBuf(",constrainClass = ");
        printOption(constrainClass,printConstrainClassAsCorbaString);
        Print.printBuf(" end Absyn.ELEMENT;");
      then ();
    case Absyn.DEFINEUNIT(name,args)
      equation
        Print.printBuf("\nrecord Absyn.DEFINEUNIT name = \"");
        Print.printBuf(name);
        Print.printBuf("\", args = ");
        printListAsCorbaString(args, printNamedArg, ",");
        Print.printBuf(" end Absyn.DEFINEUNIT;");
      then ();
    case Absyn.TEXT(optName,string,info)
      equation
        Print.printBuf("\nrecord Absyn.TEXT optName = ");
        printStringCommentOption(optName);
        Print.printBuf(", string = \"");
        Print.printBuf(string);
        Print.printBuf("\", info = ");
        printInfoAsCorbaString(info);
        Print.printBuf(" end Absyn.TEXT;");
      then ();
    else equation Error.addMessage(Error.INTERNAL_ERROR,{"printElementAsCorbaString failed"}); then fail();
  end match;
end printElementAsCorbaString;

protected function printInnerOuterAsCorbaString
  input Absyn.InnerOuter innerOuter;
algorithm
  _ := match innerOuter
    case Absyn.INNER()
      equation
        Print.printBuf("record Absyn.INNER end Absyn.INNER;");
      then ();
    case Absyn.OUTER()
      equation
        Print.printBuf("record Absyn.OUTER end Absyn.OUTER;");
      then ();
    case Absyn.INNER_OUTER()
      equation
        Print.printBuf("record Absyn.INNER_OUTER end Absyn.INNER_OUTER;");
      then ();
    case Absyn.NOT_INNER_OUTER()
      equation
        Print.printBuf("record Absyn.NOT_INNER_OUTER end Absyn.NOT_INNER_OUTER;");
      then ();
  end match;
end printInnerOuterAsCorbaString;

protected function printRedeclareKeywordsAsCorbaString
  input Absyn.RedeclareKeywords redeclareKeywords;
algorithm
  _ := match redeclareKeywords
    case Absyn.REDECLARE()
      equation
        Print.printBuf("record Absyn.REDECLARE end Absyn.REDECLARE;");
      then ();
    case Absyn.REPLACEABLE()
      equation
        Print.printBuf("record Absyn.REPLACEABLE end Absyn.REPLACEABLE;");
      then ();
    case Absyn.REDECLARE_REPLACEABLE()
      equation
        Print.printBuf("record Absyn.REDECLARE_REPLACEABLE end Absyn.REDECLARE_REPLACEABLE;");
      then ();
  end match;
end printRedeclareKeywordsAsCorbaString;

protected function printConstrainClassAsCorbaString
  input Absyn.ConstrainClass constrainClass;
algorithm
  _ := match constrainClass
    local
      Absyn.ElementSpec elementSpec;
      Option<Absyn.Comment> comment;
    case Absyn.CONSTRAINCLASS(elementSpec,comment)
      equation
        Print.printBuf("record Absyn.CONSTRAINCLASS elementSpec = ");
        printElementSpecAsCorbaString(elementSpec);
        Print.printBuf(", comment = ");
        printOption(comment, printCommentAsCorbaString);
        Print.printBuf(" end Absyn.CONSTRAINCLASS;");
      then ();
  end match;
end printConstrainClassAsCorbaString;

protected function printElementSpecAsCorbaString
  input Absyn.ElementSpec spec;
algorithm
  _ := match spec
    local
      Boolean replaceable_;
      Absyn.Class class_;
      Absyn.Import import_;
      Option<Absyn.Comment> comment;
      Absyn.ElementAttributes attributes;
      Absyn.TypeSpec typeSpec;
      list<Absyn.ComponentItem> components;
      Option<Absyn.Annotation> annotationOpt;
      list<Absyn.ElementArg> elementArg;
      Absyn.Path path;
      Absyn.Info info;
    case Absyn.CLASSDEF(replaceable_,class_)
      equation
        Print.printBuf("record Absyn.CLASSDEF replaceable_ = ");
        Print.printBuf(Util.if_(replaceable_, "true", "false"));
        Print.printBuf(", class_ = ");
        printClassAsCorbaString(class_);
        Print.printBuf(" end Absyn.CLASSDEF;");
      then ();
    case Absyn.EXTENDS(path,elementArg,annotationOpt)
      equation
        Print.printBuf("record Absyn.EXTENDS path = ");
        printPathAsCorbaString(path);
        Print.printBuf(", elementArg = ");
        printListAsCorbaString(elementArg, printElementArgAsCorbaString, ",");
        Print.printBuf(", annotationOpt = ");
        printOption(annotationOpt, printAnnotationAsCorbaString);
        Print.printBuf(" end Absyn.EXTENDS;");
      then ();
    case Absyn.IMPORT(import_, comment, info)
      equation
        Print.printBuf("record Absyn.IMPORT import_ = ");
        printImportAsCorbaString(import_);
        Print.printBuf(", comment = ");
        printOption(comment, printCommentAsCorbaString);
        Print.printBuf(", info = ");
        printInfoAsCorbaString(info);
        Print.printBuf(" end Absyn.IMPORT;");
      then ();
    case Absyn.COMPONENTS(attributes,typeSpec,components)
      equation
        Print.printBuf("record Absyn.COMPONENTS attributes = ");
        printElementAttributesAsCorbaString(attributes);
        Print.printBuf(", typeSpec = ");
        printTypeSpecAsCorbaString(typeSpec);
        Print.printBuf(", components = ");
        printListAsCorbaString(components, printComponentItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.COMPONENTS;");
      then ();
  end match;
end printElementSpecAsCorbaString;

protected function printComponentItemAsCorbaString
  input Absyn.ComponentItem componentItem;
algorithm
  _ := match componentItem
    local
      Absyn.Component component;
      Option<Absyn.ComponentCondition> condition;
      Option<Absyn.Comment> comment;
    case Absyn.COMPONENTITEM(component,condition,comment)
      equation
        Print.printBuf("record Absyn.COMPONENTITEM component = ");
        printComponentAsCorbaString(component);
        Print.printBuf(", condition = ");
        printOption(condition, printExpAsCorbaString);
        Print.printBuf(", comment = ");
        printOption(comment, printCommentAsCorbaString);
        Print.printBuf(" end Absyn.COMPONENTITEM;");
      then ();
  end match;
end printComponentItemAsCorbaString;

protected function printComponentAsCorbaString
  input Absyn.Component component;
algorithm
  _ := match component
    local
      String name;
      Absyn.ArrayDim arrayDim;
      Option<Absyn.Modification> modification;
    case Absyn.COMPONENT(name,arrayDim,modification)
      equation
        Print.printBuf("record Absyn.COMPONENT name = \"");
        Print.printBuf(name);
        Print.printBuf("\", arrayDim = ");
        printArrayDimAsCorbaString(arrayDim);
        Print.printBuf(", modification = ");
        printOption(modification, printModificationAsCorbaString);
        Print.printBuf(" end Absyn.COMPONENT;");
      then ();
  end match;
end printComponentAsCorbaString;

protected function printModificationAsCorbaString
  input Absyn.Modification mod;
algorithm
  _ := match mod
    local
      list<Absyn.ElementArg> elementArgLst;
      Absyn.EqMod eqMod;
    case Absyn.CLASSMOD(elementArgLst, eqMod)
      equation
        Print.printBuf("record Absyn.CLASSMOD elementArgLst = ");
        printListAsCorbaString(elementArgLst, printElementArgAsCorbaString, ",");
        Print.printBuf(", eqMod = ");
        printEqModAsCorbaString(eqMod);
        Print.printBuf(" end Absyn.CLASSMOD;");
     then ();
  end match;
end printModificationAsCorbaString;

protected function printEqModAsCorbaString
  input Absyn.EqMod eqMod;
algorithm
  _ := match eqMod
    local
      Absyn.Exp exp;
      Absyn.Info info;
    case Absyn.NOMOD()
      equation
        Print.printBuf("record Absyn.NOMOD end Absyn.NOMOD;");
      then ();
    case Absyn.EQMOD(exp,info)
      equation
        Print.printBuf("record Absyn.EQMOD exp = ");
        printExpAsCorbaString(exp);
        Print.printBuf(", info = ");
        printInfoAsCorbaString(info);
        Print.printBuf(" end Absyn.EQMOD;");
      then ();
  end match;
end printEqModAsCorbaString;

protected function printEquationItemAsCorbaString
  input Absyn.EquationItem el;
algorithm
  _ := match el
    local
      Absyn.Equation equation_;
      Option<Absyn.Comment> comment;
      Absyn.Annotation annotation_;
      Absyn.Info info;
    case Absyn.EQUATIONITEM(equation_,comment,info)
      equation
        Print.printBuf("\nrecord Absyn.EQUATIONITEM equation_ = ");
        printEquationAsCorbaString(equation_);
        Print.printBuf(", comment = ");
        printOption(comment, printCommentAsCorbaString);
        Print.printBuf(", info = ");
        printInfoAsCorbaString(info);
        Print.printBuf(" end Absyn.EQUATIONITEM;");
      then ();
  end match;
end printEquationItemAsCorbaString;

protected function printEquationAsCorbaString
  input Absyn.Equation eq;
algorithm
  _ := match eq
    local
      Absyn.Exp ifExp,leftSide,rightSide,whenExp;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> elseIfBranches, elseWhenEquations;
      Absyn.ComponentRef connector1,connector2,functionName;
      Absyn.ForIterators iterators;
      list<Absyn.EquationItem> equationTrueItems,equationElseItems,forEquations,whenEquations;
      Absyn.FunctionArgs functionArgs;
      Absyn.EquationItem equ;
    case Absyn.EQ_IF(ifExp,equationTrueItems,elseIfBranches,equationElseItems)
      equation
        Print.printBuf("record Absyn.EQ_IF ifExp = ");
        printExpAsCorbaString(ifExp);
        Print.printBuf(", equationTrueItems = ");
        printListAsCorbaString(equationTrueItems, printEquationItemAsCorbaString, ",");
        Print.printBuf(", elseIfBranches = ");
        printListAsCorbaString(elseIfBranches, printEquationBranchAsCorbaString, ",");
        Print.printBuf(", equationElseItems = ");
        printListAsCorbaString(equationElseItems, printEquationItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.EQ_IF;");
      then ();
    case Absyn.EQ_EQUALS(leftSide,rightSide)
      equation
        Print.printBuf("record Absyn.EQ_EQUALS leftSide = ");
        printExpAsCorbaString(leftSide);
        Print.printBuf(", rightSide = ");
        printExpAsCorbaString(rightSide);
        Print.printBuf(" end Absyn.EQ_EQUALS;");
      then ();
    case Absyn.EQ_CONNECT(connector1,connector2)
      equation
        Print.printBuf("record Absyn.EQ_CONNECT connector1 = ");
        printComponentRefAsCorbaString(connector1);
        Print.printBuf(", connector2 = ");
        printComponentRefAsCorbaString(connector2);
        Print.printBuf(" end Absyn.EQ_CONNECT;");
      then ();
    case Absyn.EQ_FOR(iterators,forEquations)
      equation
        Print.printBuf("record Absyn.EQ_FOR iterators = ");
        printListAsCorbaString(iterators,printForIteratorAsCorbaString,",");
        Print.printBuf(", forEquations = ");
        printListAsCorbaString(forEquations,printEquationItemAsCorbaString,",");
        Print.printBuf(" end Absyn.EQ_FOR;");
      then ();
    case Absyn.EQ_WHEN_E(whenExp,whenEquations,elseWhenEquations)
      equation
        Print.printBuf("record Absyn.EQ_WHEN_E whenExp = ");
        printExpAsCorbaString(whenExp);
        Print.printBuf(", whenEquations = ");
        printListAsCorbaString(whenEquations, printEquationItemAsCorbaString, ",");
        Print.printBuf(", elseWhenEquations = ");
        printListAsCorbaString(elseWhenEquations, printEquationBranchAsCorbaString, ",");
        Print.printBuf(" end Absyn.EQ_WHEN_E;");
      then ();
    case Absyn.EQ_NORETCALL(functionName,functionArgs)
      equation
        Print.printBuf("record Absyn.EQ_NORETCALL functionName = ");
        printComponentRefAsCorbaString(functionName);
        Print.printBuf(", functionArgs = ");
        printFunctionArgsAsCorbaString(functionArgs);
        Print.printBuf(" end Absyn.EQ_NORETCALL;");
      then ();
    case Absyn.EQ_FAILURE(equ)
      equation
        Print.printBuf("record Absyn.EQ_FAILURE equ = ");
        printEquationItemAsCorbaString(equ);
        Print.printBuf(" end Absyn.EQ_FAILURE;");
      then ();  end match;
end printEquationAsCorbaString;

protected function printAlgorithmItemAsCorbaString
  input Absyn.AlgorithmItem el;
algorithm
  _ := match el
    local
      Absyn.Algorithm algorithm_;
      Option<Absyn.Comment> comment;
      Absyn.Annotation annotation_;
      Absyn.Info info;
    case Absyn.ALGORITHMITEM(algorithm_,comment,info)
      equation
        Print.printBuf("\nrecord Absyn.ALGORITHMITEM algorithm_ = ");
        printAlgorithmAsCorbaString(algorithm_);
        Print.printBuf(", comment = ");
        printOption(comment, printCommentAsCorbaString);
        Print.printBuf(", info = ");
        printInfo(info);
        Print.printBuf(" end Absyn.ALGORITHMITEM;");
      then ();
  end match;
end printAlgorithmItemAsCorbaString;

protected function printAlgorithmAsCorbaString
  input Absyn.Algorithm alg;
algorithm
  _ := match alg
    local
      Absyn.Exp assignComponent, value, ifExp, boolExpr;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> elseIfAlgorithmBranch,elseWhenAlgorithmBranch;
      list<Absyn.AlgorithmItem> trueBranch,elseBranch,forBody,whileBody,whenBody,tryBody,catchBody,body;
      Absyn.ForIterators iterators;
      Absyn.ComponentRef functionCall;
      Absyn.FunctionArgs functionArgs;
    case Absyn.ALG_ASSIGN(assignComponent,value)
      equation
        Print.printBuf("record Absyn.ALG_ASSIGN assignComponent = ");
        printExpAsCorbaString(assignComponent);
        Print.printBuf(", value = ");
        printExpAsCorbaString(value);
        Print.printBuf(" end Absyn.ALG_ASSIGN;");
      then ();
    case Absyn.ALG_IF(ifExp,trueBranch,elseIfAlgorithmBranch,elseBranch)
      equation
        Print.printBuf("record Absyn.ALG_IF ifExp = ");
        printExpAsCorbaString(ifExp);
        Print.printBuf(", trueBranch = ");
        printListAsCorbaString(trueBranch, printAlgorithmItemAsCorbaString, ",");
        Print.printBuf(", elseIfAlgorithmBranch = ");
        printListAsCorbaString(elseIfAlgorithmBranch, printAlgorithmBranchAsCorbaString, ",");
        Print.printBuf(", elseBranch = ");
        printListAsCorbaString(elseBranch, printAlgorithmItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.ALG_IF;");
      then ();
    case Absyn.ALG_FOR(iterators,forBody)
      equation
        Print.printBuf("record Absyn.ALG_FOR iterators = ");
        printListAsCorbaString(iterators,printForIteratorAsCorbaString,",");
        Print.printBuf(", forBody = ");
        printListAsCorbaString(forBody, printAlgorithmItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.ALG_FOR;");
      then ();
    case Absyn.ALG_PARFOR(iterators,forBody)
      equation
        Print.printBuf("record Absyn.ALG_PARFOR iterators = ");
        printListAsCorbaString(iterators,printForIteratorAsCorbaString,",");
        Print.printBuf(", parforBody = ");
        printListAsCorbaString(forBody, printAlgorithmItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.ALG_PARFOR;");
      then ();
    case Absyn.ALG_WHILE(boolExpr,whileBody)
      equation
        Print.printBuf("record Absyn.ALG_WHILE boolExpr = ");
        printExpAsCorbaString(boolExpr);
        Print.printBuf(", whileBody = ");
        printListAsCorbaString(whileBody, printAlgorithmItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.ALG_WHILE;");
      then ();
    case Absyn.ALG_WHEN_A(boolExpr,whenBody,elseWhenAlgorithmBranch)
      equation
        Print.printBuf("record Absyn.ALG_WHEN_A boolExpr = ");
        printExpAsCorbaString(boolExpr);
        Print.printBuf(", whenBody = ");
        printListAsCorbaString(whenBody, printAlgorithmItemAsCorbaString, ",");
        Print.printBuf(", elseWhenAlgorithmBranch = ");
        printListAsCorbaString(elseWhenAlgorithmBranch, printAlgorithmBranchAsCorbaString, ",");
        Print.printBuf(" end Absyn.ALG_WHEN_A;");
      then ();
    case Absyn.ALG_NORETCALL(functionCall,functionArgs)
      equation
        Print.printBuf("record Absyn.ALG_NORETCALL functionCall = ");
        printComponentRefAsCorbaString(functionCall);
        Print.printBuf(", functionArgs = ");
        printFunctionArgsAsCorbaString(functionArgs);
        Print.printBuf(" end Absyn.ALG_NORETCALL;");
      then ();
    case Absyn.ALG_RETURN()
      equation
        Print.printBuf("record Absyn.ALG_RETURN end Absyn.ALG_RETURN;");
      then ();
    case Absyn.ALG_BREAK()
      equation
        Print.printBuf("record Absyn.ALG_BREAK end Absyn.ALG_BREAK;");
      then ();
    case Absyn.ALG_TRY(tryBody)
      equation
        Print.printBuf("record Absyn.ALG_TRY tryBody = ");
        printListAsCorbaString(tryBody, printAlgorithmItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.ALG_TRY;");
      then ();
    case Absyn.ALG_CATCH(catchBody)
      equation
        Print.printBuf("record Absyn.ALG_CATCH catchBody = ");
        printListAsCorbaString(catchBody, printAlgorithmItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.ALG_CATCH;");
      then ();
    case Absyn.ALG_THROW()
      equation
        Print.printBuf("record Absyn.ALG_THROW end Absyn.ALG_THROW;");
      then ();
    case Absyn.ALG_FAILURE(body)
      equation
        Print.printBuf("record Absyn.ALG_FAILURE body = ");
        printListAsCorbaString(body, printAlgorithmItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.ALG_FAILURE;");
      then ();
  end match;
end printAlgorithmAsCorbaString;

protected function printAlgorithmBranchAsCorbaString
  input tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> inBranch;
algorithm
  printTupleAsCorbaString(inBranch,printExpAsCorbaString,printAlgorithmItemListAsCorbaString);
end printAlgorithmBranchAsCorbaString;

protected function printAlgorithmItemListAsCorbaString
  input list<Absyn.AlgorithmItem> inLst;
algorithm
  printListAsCorbaString(inLst,printAlgorithmItemAsCorbaString,",");
end printAlgorithmItemListAsCorbaString;

protected function printEquationBranchAsCorbaString
  input tuple<Absyn.Exp, list<Absyn.EquationItem>> inBranch;
algorithm
  printTupleAsCorbaString(inBranch,printExpAsCorbaString,printEquationItemListAsCorbaString);
end printEquationBranchAsCorbaString;

protected function printEquationItemListAsCorbaString
  input list<Absyn.EquationItem> inLst;
algorithm
  printListAsCorbaString(inLst,printEquationItemAsCorbaString,",");
end printEquationItemListAsCorbaString;

protected function printAnnotationAsCorbaString
  input Absyn.Annotation annotation_;
algorithm
  _ := match annotation_
    local
      list<Absyn.ElementArg> elementArgs;
    case Absyn.ANNOTATION(elementArgs)
      equation
        Print.printBuf("record Absyn.ANNOTATION elementArgs = ");
        printListAsCorbaString(elementArgs, printElementArgAsCorbaString, ",");
        Print.printBuf(" end Absyn.ANNOTATION;");
      then ();
  end match;
end printAnnotationAsCorbaString;

protected function printCommentAsCorbaString
  input Absyn.Comment inComment;
algorithm
  _ := match inComment
    local
      Option<Absyn.Annotation> annotation_;
      Option<String> comment;
    case Absyn.COMMENT(annotation_, comment)
      equation
        Print.printBuf("record Absyn.COMMENT annotation_ = ");
        printOption(annotation_, printAnnotationAsCorbaString);
        Print.printBuf(", comment = ");
        printStringCommentOption(comment);
        Print.printBuf(" end Absyn.COMMENT;");
      then ();
  end match;
end printCommentAsCorbaString;

protected function printTypeSpecAsCorbaString
  input Absyn.TypeSpec typeSpec;
algorithm
  _ := match typeSpec
    local
      Absyn.Path path;
      Option<Absyn.ArrayDim> arrayDim;
      list<Absyn.TypeSpec> typeSpecs;
    case Absyn.TPATH(path, arrayDim)
      equation
        Print.printBuf("record Absyn.TPATH path = ");
        printPathAsCorbaString(path);
        Print.printBuf(", arrayDim = ");
        printOption(arrayDim, printArrayDimAsCorbaString);
        Print.printBuf(" end Absyn.TPATH;");
      then ();
    case Absyn.TCOMPLEX(path, typeSpecs, arrayDim)
      equation
        Print.printBuf("record Absyn.TPATH path = ");
        printPathAsCorbaString(path);
        Print.printBuf(", typeSpecs = ");
        printListAsCorbaString(typeSpecs, printTypeSpecAsCorbaString, ",");
        Print.printBuf(", arrayDim = ");
        printOption(arrayDim, printArrayDimAsCorbaString);
        Print.printBuf(" end Absyn.TPATH;");
      then ();
  end match;
end printTypeSpecAsCorbaString;

protected function printArrayDimAsCorbaString
  input Absyn.ArrayDim arrayDim;
algorithm
  printListAsCorbaString(arrayDim, printSubscriptAsCorbaString, ",");
end printArrayDimAsCorbaString;

protected function printSubscriptAsCorbaString
  input Absyn.Subscript subscript;
algorithm
  _ := match subscript
    local
      Absyn.Exp sub;
    case Absyn.NOSUB()
      equation
        Print.printBuf("record Absyn.NOSUB end Absyn.NOSUB;");
      then ();
    case Absyn.SUBSCRIPT(sub)
      equation
        Print.printBuf("record Absyn.SUBSCRIPT subscript = ");
        printExpAsCorbaString(sub);
        Print.printBuf(" end Absyn.SUBSCRIPT;");
      then ();
  end match;
end printSubscriptAsCorbaString;

protected function printImportAsCorbaString
  input Absyn.Import import_;
algorithm
  _ := match import_
    local
      String name;
      Absyn.Path path;
    case Absyn.NAMED_IMPORT(name,path)
      equation
        Print.printBuf("record Absyn.NAMED_IMPORT name = \"");
        Print.printBuf(name);
        Print.printBuf("\", path = ");
        printPathAsCorbaString(path);
        Print.printBuf(" end Absyn.NAMED_IMPORT;");
      then ();
    case Absyn.QUAL_IMPORT(path)
      equation
        Print.printBuf("record Absyn.QUAL_IMPORT path = ");
        printPathAsCorbaString(path);
        Print.printBuf(" end Absyn.QUAL_IMPORT;");
      then ();
    case Absyn.UNQUAL_IMPORT(path)
      equation
        Print.printBuf("record Absyn.UNQUAL_IMPORT path = ");
        printPathAsCorbaString(path);
        Print.printBuf(" end Absyn.UNQUAL_IMPORT;");
      then ();
  end match;
end printImportAsCorbaString;

protected function printElementAttributesAsCorbaString
  input Absyn.ElementAttributes attr;
algorithm
  _ := match attr
    local
      Boolean flowPrefix;
      Boolean streamPrefix;
      Absyn.Parallelism parallelism;
      Absyn.Variability variability;
      Absyn.Direction direction;
      Absyn.ArrayDim arrayDim;
    case Absyn.ATTR(flowPrefix,streamPrefix,parallelism,variability,direction,arrayDim)
      equation
        Print.printBuf("record Absyn.ATTR flowPrefix = ");
        Print.printBuf(Util.if_(flowPrefix, "true", "false"));
        Print.printBuf(", streamPrefix = ");
        Print.printBuf(Util.if_(streamPrefix, "true", "false"));
        Print.printBuf(", parallelism = ");
        printParallelismAsCorbaString(parallelism);
        Print.printBuf(", variability = ");
        printVariabilityAsCorbaString(variability);
        Print.printBuf(", direction = ");
        printDirectionAsCorbaString(direction);
        Print.printBuf(", arrayDim = ");
        printArrayDimAsCorbaString(arrayDim);
        Print.printBuf(" end Absyn.ATTR;");
      then ();
  end match;
end printElementAttributesAsCorbaString;

protected function printParallelismAsCorbaString
  input Absyn.Parallelism parallelism;
algorithm
  _ := match parallelism
    case Absyn.PARGLOBAL()
      equation
        Print.printBuf("record Absyn.PARGLOBAL end Absyn.PARGLOBAL;");
      then ();
    case Absyn.PARLOCAL()
      equation
        Print.printBuf("record Absyn.PARLOCAL end Absyn.PARLOCAL;");
      then ();
    case Absyn.NON_PARALLEL()
      equation
        Print.printBuf("record Absyn.NON_PARALLEL end Absyn.NON_PARALLEL;");
      then ();
  end match;
end printParallelismAsCorbaString;

protected function printVariabilityAsCorbaString
  input Absyn.Variability var;
algorithm
  _ := match var
    case Absyn.VAR()
      equation
        Print.printBuf("record Absyn.VAR end Absyn.VAR;");
      then ();
    case Absyn.DISCRETE()
      equation
        Print.printBuf("record Absyn.DISCRETE end Absyn.DISCRETE;");
      then ();
    case Absyn.PARAM()
      equation
        Print.printBuf("record Absyn.PARAM end Absyn.PARAM;");
      then ();
    case Absyn.CONST()
      equation
        Print.printBuf("record Absyn.CONST end Absyn.CONST;");
      then ();
  end match;
end printVariabilityAsCorbaString;

protected function printDirectionAsCorbaString
  input Absyn.Direction dir;
algorithm
  _ := match dir
    case Absyn.INPUT()
      equation
        Print.printBuf("record Absyn.INPUT end Absyn.INPUT;");
      then ();
    case Absyn.OUTPUT()
      equation
        Print.printBuf("record Absyn.OUTPUT end Absyn.OUTPUT;");
      then ();
    case Absyn.BIDIR()
      equation
        Print.printBuf("record Absyn.BIDIR end Absyn.BIDIR;");
      then ();
  end match;
end printDirectionAsCorbaString;

protected function printElementArgAsCorbaString
  input Absyn.ElementArg arg;
algorithm
  _ := match arg
    local
      Boolean finalPrefix;
      Absyn.Each eachPrefix;
      Option<Absyn.Modification> modification;
      Option<String> comment;
      Absyn.RedeclareKeywords redeclareKeywords;
      Absyn.ElementSpec elementSpec;
      Option<Absyn.ConstrainClass> constrainClass;
      Absyn.Info info;
      Absyn.Path p;
    case Absyn.MODIFICATION(finalPrefix,eachPrefix,p,modification,comment,info)
      equation
        Print.printBuf("record Absyn.MODIFICATION finalPrefix = ");
        Print.printBuf(Util.if_(finalPrefix,"true","false"));
        Print.printBuf(", eachPrefix = ");
        printEachAsCorbaString(eachPrefix);
        Print.printBuf(", path = ");
        printPathAsCorbaString(p);
        Print.printBuf(", modification = ");
        printOption(modification, printModificationAsCorbaString);
        Print.printBuf(", comment = ");
        printStringCommentOption(comment);
        Print.printBuf(", info = ");
        printInfoAsCorbaString(info);
        Print.printBuf(" end Absyn.MODIFICATION;");
      then ();
    case Absyn.REDECLARATION(finalPrefix,redeclareKeywords,eachPrefix,elementSpec,constrainClass,info)
      equation
        Print.printBuf("record Absyn.REDECLARATION finalPrefix = ");
        Print.printBuf(Util.if_(finalPrefix,"true","false"));
        Print.printBuf(", redeclareKeywords = ");
        printRedeclareKeywordsAsCorbaString(redeclareKeywords);
        Print.printBuf(", eachPrefix = ");
        printEachAsCorbaString(eachPrefix);
        Print.printBuf(", elementSpec = ");
        printElementSpecAsCorbaString(elementSpec);
        Print.printBuf(", constrainClass = ");
        printOption(constrainClass, printConstrainClassAsCorbaString);
        Print.printBuf(", info = ");
        printInfoAsCorbaString(info);
        Print.printBuf(" end Absyn.REDECLARATION;");
      then ();
  end match;
end printElementArgAsCorbaString;

protected function printFunctionArgsAsCorbaString
  input Absyn.FunctionArgs fargs;
algorithm
  _ := match fargs
    local
      list<Absyn.Exp> args;
      list<Absyn.NamedArg> argNames;
      Absyn.Exp exp;
      Absyn.ForIterators iterators;
    case Absyn.FUNCTIONARGS(args,argNames)
      equation
        Print.printBuf("record Absyn.FUNCTIONARGS args = ");
        printListAsCorbaString(args, printExpAsCorbaString, ",");
        Print.printBuf(", argNames = ");
        printListAsCorbaString(argNames, printNamedArgAsCorbaString, ",");
        Print.printBuf(" end Absyn.FUNCTIONARGS;");
      then ();
    case Absyn.FOR_ITER_FARG(exp,iterators)
      equation
        Print.printBuf("record Absyn.FOR_ITER_FARG exp = ");
        printExpAsCorbaString(exp);
        Print.printBuf(", iterators = ");
        printListAsCorbaString(iterators, printForIteratorAsCorbaString, ",");
        Print.printBuf(" end Absyn.FOR_ITER_FARG;");
      then ();
  end match;
end printFunctionArgsAsCorbaString;

protected function printForIteratorAsCorbaString
  input Absyn.ForIterator iter;
algorithm
  _ := match iter
    local
      String id;
      Option<Absyn.Exp> guardExp,range;
    case (Absyn.ITERATOR(id,guardExp,range))
      equation
        Print.printBuf("record Absyn.ITERATOR name = \"");
        Print.printBuf(id);
        Print.printBuf("\", guardExp = ");
        printOption(guardExp,printExpAsCorbaString);
        Print.printBuf(", range = ");
        printOption(range,printExpAsCorbaString);
        Print.printBuf("end Absyn.ITERATOR;");
      then ();
  end match;
end printForIteratorAsCorbaString;

protected function printNamedArgAsCorbaString
  input Absyn.NamedArg arg;
algorithm
  _ := match arg
    local
      String argName;
      Absyn.Exp argValue;
    case Absyn.NAMEDARG(argName,argValue)
      equation
        Print.printBuf("record Absyn.NAMEDARG argName = \"");
        Print.printBuf(argName);
        Print.printBuf("\", argValue = ");
        printExpAsCorbaString(argValue);
        Print.printBuf(" end Absyn.NAMEDARG;");
      then ();
  end match;
end printNamedArgAsCorbaString;

protected function printExpAsCorbaString
  input Absyn.Exp inExp;
algorithm
  _ := match inExp
    local
      Integer i;
      Real r;
      String s,id;
      Boolean b;
      Absyn.ComponentRef componentRef,function_;
      Absyn.FunctionArgs functionArgs;
      Absyn.Exp exp,exp1,exp2,ifExp,trueBranch,elseBranch,start,stop,head,rest,inputExp;
      Option<Absyn.Exp> step;
      Absyn.Operator op;
      list<Absyn.Exp> arrayExp, expressions;
      list<list<Absyn.Exp>> matrix;
      list<tuple<Absyn.Exp,Absyn.Exp>> elseIfBranch;
      Absyn.CodeNode code;
      Absyn.MatchType matchTy;
      list<Absyn.ElementItem> localDecls;
      list<Absyn.Case> cases;
      Option<String> comment;
    case Absyn.INTEGER(value = i)
      equation
        Print.printBuf("record Absyn.INTEGER value = ");
        Print.printBuf(intString(i));
        Print.printBuf(" end Absyn.INTEGER;");
      then ();
    case Absyn.REAL(value = r)
      equation
        Print.printBuf("record Absyn.REAL value = ");
        Print.printBuf(realString(r));
        Print.printBuf(" end Absyn.REAL;");
      then ();
    case Absyn.CREF(componentRef)
      equation
        Print.printBuf("record Absyn.CREF componentRef = ");
        printComponentRefAsCorbaString(componentRef);
        Print.printBuf(" end Absyn.CREF;");
      then ();
    case Absyn.STRING(value = s)
      equation
        Print.printBuf("record Absyn.STRING value = \"");
        Print.printBuf(s);
        Print.printBuf("\" end Absyn.STRING;");
      then ();
    case Absyn.BOOL(value = b)
      equation
        Print.printBuf("record Absyn.BOOL value = ");
        Print.printBuf(Util.if_(b, "true", "false"));
        Print.printBuf(" end Absyn.BOOL;");
      then ();
    case Absyn.BINARY(exp1,op,exp2)
      equation
        Print.printBuf("record Absyn.BINARY exp1 = ");
        printExpAsCorbaString(exp1);
        Print.printBuf(", op = ");
        printOperatorAsCorbaString(op);
        Print.printBuf(", exp2 = ");
        printExpAsCorbaString(exp2);
        Print.printBuf(" end Absyn.BINARY;");
      then ();
    case Absyn.UNARY(op,exp)
      equation
        Print.printBuf("record Absyn.UNARY op = ");
        printOperatorAsCorbaString(op);
        Print.printBuf(", exp = ");
        printExpAsCorbaString(exp);
        Print.printBuf(" end Absyn.UNARY;");
      then ();
    case Absyn.LBINARY(exp1,op,exp2)
      equation
        Print.printBuf("record Absyn.LBINARY exp1 = ");
        printExpAsCorbaString(exp1);
        Print.printBuf(", op = ");
        printOperatorAsCorbaString(op);
        Print.printBuf(", exp2 = ");
        printExpAsCorbaString(exp2);
        Print.printBuf(" end Absyn.LBINARY;");
      then ();
    case Absyn.LUNARY(op,exp)
      equation
        Print.printBuf("record Absyn.LUNARY op = ");
        printOperatorAsCorbaString(op);
        Print.printBuf(", exp = ");
        printExpAsCorbaString(exp);
        Print.printBuf(" end Absyn.LUNARY;");
      then ();
    case Absyn.RELATION(exp1,op,exp2)
      equation
        Print.printBuf("record Absyn.RELATION exp1 = ");
        printExpAsCorbaString(exp1);
        Print.printBuf(", op = ");
        printOperatorAsCorbaString(op);
        Print.printBuf(", exp2 = ");
        printExpAsCorbaString(exp2);
        Print.printBuf(" end Absyn.RELATION;");
      then ();
    case Absyn.IFEXP(ifExp,trueBranch,elseBranch,elseIfBranch)
      equation
        Print.printBuf("record Absyn.IFEXP ifExp = ");
        printExpAsCorbaString(ifExp);
        Print.printBuf(", trueBranch = ");
        printExpAsCorbaString(trueBranch);
        Print.printBuf(", elseBranch = ");
        printExpAsCorbaString(elseBranch);
        Print.printBuf(", elseIfBranch = ");
        printListAsCorbaString(elseIfBranch,printTupleExpExpAsCorbaString,",");
        Print.printBuf(" end Absyn.IFEXP;");
      then ();
    case Absyn.CALL(function_,functionArgs)
      equation
        Print.printBuf("record Absyn.CALL function_ = ");
        printComponentRefAsCorbaString(function_);
        Print.printBuf(", functionArgs = ");
        printFunctionArgsAsCorbaString(functionArgs);
        Print.printBuf(" end Absyn.CALL;");
      then ();
    case Absyn.PARTEVALFUNCTION(function_,functionArgs)
      equation
        Print.printBuf("record Absyn.PARTEVALFUNCTION function_ = ");
        printComponentRefAsCorbaString(function_);
        Print.printBuf(", functionArgs = ");
        printFunctionArgsAsCorbaString(functionArgs);
        Print.printBuf(" end Absyn.PARTEVALFUNCTION;");
      then ();
    case Absyn.ARRAY(arrayExp)
      equation
        Print.printBuf("record Absyn.ARRAY arrayExp = ");
        printListAsCorbaString(arrayExp, printExpAsCorbaString, ",");
        Print.printBuf(" end Absyn.ARRAY;");
      then ();
    case Absyn.MATRIX(matrix)
      equation
        Print.printBuf("record Absyn.MATRIX matrix = ");
        printListAsCorbaString(matrix, printListExpAsCorbaString, ",");
        Print.printBuf(" end Absyn.MATRIX;");
      then ();
    case Absyn.RANGE(start,step,stop)
      equation
        Print.printBuf("record Absyn.RANGE start = ");
        printExpAsCorbaString(start);
        Print.printBuf(", step = ");
        printOption(step,printExpAsCorbaString);
        Print.printBuf(", stop = ");
        printExpAsCorbaString(stop);
        Print.printBuf(" end Absyn.RANGE;");
      then ();
    case Absyn.TUPLE(expressions)
      equation
        Print.printBuf("record Absyn.TUPLE expressions = ");
        printListAsCorbaString(expressions, printExpAsCorbaString, ",");
        Print.printBuf(" end Absyn.TUPLE;");
      then ();
    case Absyn.END()
      equation
        Print.printBuf("record Absyn.END end Absyn.END;");
      then ();
    case Absyn.CODE(code)
      equation
        Print.printBuf("record Absyn.CODE code = ");
        printCodeAsCorbaString(code);
        Print.printBuf(" end Absyn.CODE;");
      then ();
    case Absyn.AS(id,exp)
      equation
        Print.printBuf("record Absyn.AS id = \"");
        Print.printBuf(id);
        Print.printBuf("\", exp = ");
        printExpAsCorbaString(exp);
        Print.printBuf(" end Absyn.AS;");
      then ();
    case Absyn.CONS(head,rest)
      equation
        Print.printBuf("record Absyn.CONS head = ");
        printExpAsCorbaString(head);
        Print.printBuf(", rest = ");
        printExpAsCorbaString(rest);
        Print.printBuf(" end Absyn.CONS;");
      then ();
    case Absyn.MATCHEXP(matchTy,inputExp,localDecls,cases,comment)
      equation
        Print.printBuf("record Absyn.MATCHEXP matchTy = ");
        printMatchTypeAsCorbaString(matchTy);
        Print.printBuf(", inputExp = ");
        printExpAsCorbaString(inputExp);
        Print.printBuf(", localDecls = ");
        printListAsCorbaString(localDecls, printElementItemAsCorbaString, ",\n");
        Print.printBuf(", cases = ");
        printListAsCorbaString(cases, printCaseAsCorbaString, ",\n");
        Print.printBuf(", comment = ");
        printStringCommentOption(comment);
        Print.printBuf(" end Absyn.MATCHEXP;");
      then ();
      /* Absyn.LIST and Absyn.VALUEBLOCK are only used internally, not by the parser. */
  end match;
end printExpAsCorbaString;

protected function printMatchTypeAsCorbaString
  input Absyn.MatchType matchTy;
algorithm
  _ := match matchTy
    case Absyn.MATCH()
      equation
        Print.printBuf("record Absyn.MATCH end Absyn.MATCH;");
      then ();
    case Absyn.MATCHCONTINUE()
      equation
        Print.printBuf("record Absyn.MATCHCONTINUE end Absyn.MATCHCONTINUE;");
      then ();
  end match;
end printMatchTypeAsCorbaString;

protected function printCaseAsCorbaString
  input Absyn.Case case_;
algorithm
  _ := match case_
    local
      Absyn.Exp pattern;
      Option<Absyn.Exp> patternGuard;
      Absyn.Info patternInfo,info,resultInfo;
      list<Absyn.ElementItem> localDecls;
      list<Absyn.EquationItem>  equations;
      Absyn.Exp result;
      Option<String> comment;
    case Absyn.CASE(pattern,patternGuard,patternInfo,localDecls,equations,result,resultInfo,comment,info)
      equation
        Print.printBuf("record Absyn.CASE pattern = ");
        printExpAsCorbaString(pattern);
        Print.printBuf(", patternGuard = ");
        printOption(patternGuard,printExpAsCorbaString);
        Print.printBuf(", patternInfo = ");
        printInfoAsCorbaString(patternInfo);
        Print.printBuf(", localDecls = ");
        printListAsCorbaString(localDecls, printElementItemAsCorbaString, ",");
        Print.printBuf(", equations = ");
        printListAsCorbaString(equations, printEquationItemAsCorbaString, ",");
        Print.printBuf(", result = ");
        printExpAsCorbaString(result);
        Print.printBuf(", resultInfo = ");
        printInfoAsCorbaString(resultInfo);
        Print.printBuf(", comment = ");
        printStringCommentOption(comment);
        Print.printBuf(", info = ");
        printInfoAsCorbaString(info);
        Print.printBuf(" end Absyn.CASE;");
      then ();
    case Absyn.ELSE(localDecls,equations,result,resultInfo,comment,info)
      equation
        Print.printBuf("record Absyn.ELSE localDecls = ");
        printListAsCorbaString(localDecls, printElementItemAsCorbaString, ",");
        Print.printBuf(", equations = ");
        printListAsCorbaString(equations, printEquationItemAsCorbaString, ",");
        Print.printBuf(", result = ");
        printExpAsCorbaString(result);
        Print.printBuf(", resultInfo = ");
        printInfoAsCorbaString(resultInfo);
        Print.printBuf(", comment = ");
        printStringCommentOption(comment);
        Print.printBuf(", info = ");
        printInfoAsCorbaString(info);
        Print.printBuf(" end Absyn.ELSE;");
      then ();
  end match;
end printCaseAsCorbaString;

protected function printCodeAsCorbaString
  input Absyn.CodeNode code;
algorithm
  _ := match code
    local
      Absyn.Path path;
      Absyn.ComponentRef componentRef;
      Boolean boolean;
      list<Absyn.EquationItem> equationItemLst;
      list<Absyn.AlgorithmItem> algorithmItemLst;
      Absyn.Element element;
      Absyn.Exp exp;
      Absyn.Modification modification;
    case Absyn.C_TYPENAME(path)
      equation
        Print.printBuf("record Absyn.C_TYPENAME path = ");
        printPathAsCorbaString(path);
        Print.printBuf(" end Absyn.C_TYPENAME;");
      then ();
    case Absyn.C_VARIABLENAME(componentRef)
      equation
        Print.printBuf("record Absyn.C_VARIABLENAME componentRef = ");
        printComponentRefAsCorbaString(componentRef);
        Print.printBuf(" end Absyn.C_VARIABLENAME;");
      then ();
    case Absyn.C_EQUATIONSECTION(boolean, equationItemLst)
      equation
        Print.printBuf("record Absyn.C_EQUATIONSECTION boolean = ");
        Print.printBuf(Util.if_(boolean,"true","false"));
        Print.printBuf(", equationItemLst = ");
        printListAsCorbaString(equationItemLst, printEquationItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.C_EQUATIONSECTION;");
      then ();
    case Absyn.C_ALGORITHMSECTION(boolean, algorithmItemLst)
      equation
        Print.printBuf("record Absyn.C_ALGORITHMSECTION boolean = ");
        Print.printBuf(Util.if_(boolean,"true","false"));
        Print.printBuf(", algorithmItemLst = ");
        printListAsCorbaString(algorithmItemLst, printAlgorithmItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.C_ALGORITHMSECTION;");
      then ();
    case Absyn.C_ELEMENT(element)
      equation
        Print.printBuf("record Absyn.C_ELEMENT element = ");
        printElementAsCorbaString(element);
        Print.printBuf(" end Absyn.C_ELEMENT;");
      then ();
    case Absyn.C_EXPRESSION(exp)
      equation
        Print.printBuf("record Absyn.C_EXPRESSION exp = ");
        printExpAsCorbaString(exp);
        Print.printBuf(" end Absyn.C_EXPRESSION;");
      then ();
    case Absyn.C_MODIFICATION(modification)
      equation
        Print.printBuf("record Absyn.C_MODIFICATION modification = ");
        printModificationAsCorbaString(modification);
        Print.printBuf(" end Absyn.C_MODIFICATION;");
      then ();
  end match;
end printCodeAsCorbaString;

protected function printListExpAsCorbaString
  input list<Absyn.Exp> inLst;
algorithm
  printListAsCorbaString(inLst, printExpAsCorbaString, ",");
end printListExpAsCorbaString;

protected function printListAsCorbaString
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input String inString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  Print.printBuf("{");
  printList(inTypeALst,inFuncTypeTypeATo,inString);
  Print.printBuf("}");
end printListAsCorbaString;

protected function printTupleAsCorbaString
  input tuple<Type_a,Type_b> inTpl;
  input FuncTypeType_a fnA;
  input FuncTypeType_b fnB;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  partial function FuncTypeType_a
    input Type_a inTypeA;
  end FuncTypeType_a;
  partial function FuncTypeType_b
    input Type_b inTypeB;
  end FuncTypeType_b;
algorithm
  _ := match (inTpl,fnA,fnB)
    local
      Type_a a;
      Type_b b;
    case ((a,b),_,_)
      equation
        Print.printBuf("(");
        fnA(a);
        Print.printBuf(",");
        fnB(b);
        Print.printBuf(")");
      then ();
  end match;
end printTupleAsCorbaString;

protected function printOperatorAsCorbaString
  input Absyn.Operator op;
algorithm
  _ := match op
    case Absyn.ADD() equation Print.printBuf("record Absyn.ADD end Absyn.ADD;"); then ();
    case Absyn.SUB() equation Print.printBuf("record Absyn.SUB end Absyn.SUB;"); then ();
    case Absyn.MUL() equation Print.printBuf("record Absyn.MUL end Absyn.MUL;"); then ();
    case Absyn.DIV() equation Print.printBuf("record Absyn.DIV end Absyn.DIV;"); then ();
    case Absyn.POW() equation Print.printBuf("record Absyn.POW end Absyn.POW;"); then ();
    case Absyn.UPLUS() equation Print.printBuf("record Absyn.UPLUS end Absyn.UPLUS;"); then ();
    case Absyn.UMINUS() equation Print.printBuf("record Absyn.UMINUS end Absyn.UMINUS;"); then ();
    case Absyn.ADD_EW() equation Print.printBuf("record Absyn.ADD_EW end Absyn.ADD_EW;"); then ();
    case Absyn.SUB_EW() equation Print.printBuf("record Absyn.SUB_EW end Absyn.SUB_EW;"); then ();
    case Absyn.MUL_EW() equation Print.printBuf("record Absyn.MUL_EW end Absyn.MUL_EW;"); then ();
    case Absyn.DIV_EW() equation Print.printBuf("record Absyn.DIV_EW end Absyn.DIV_EW;"); then ();
    case Absyn.UPLUS_EW() equation Print.printBuf("record Absyn.UPLUS_EW end Absyn.UPLUS_EW;"); then ();
    case Absyn.UMINUS_EW() equation Print.printBuf("record Absyn.UMINUS_EW end Absyn.UMINUS_EW;"); then ();
    case Absyn.AND() equation Print.printBuf("record Absyn.AND end Absyn.AND;"); then ();
    case Absyn.OR() equation Print.printBuf("record Absyn.OR end Absyn.OR;"); then ();
    case Absyn.NOT() equation Print.printBuf("record Absyn.NOT end Absyn.NOT;"); then ();
    case Absyn.LESS() equation Print.printBuf("record Absyn.LESS end Absyn.LESS;"); then ();
    case Absyn.LESSEQ() equation Print.printBuf("record Absyn.LESSEQ end Absyn.LESSEQ;"); then ();
    case Absyn.GREATER() equation Print.printBuf("record Absyn.GREATER end Absyn.GREATER;"); then ();
    case Absyn.GREATEREQ() equation Print.printBuf("record Absyn.GREATEREQ end Absyn.GREATEREQ;"); then ();
    case Absyn.EQUAL() equation Print.printBuf("record Absyn.EQUAL end Absyn.EQUAL;"); then ();
    case Absyn.NEQUAL() equation Print.printBuf("record Absyn.NEQUAL end Absyn.NEQUAL;"); then ();
  end match;
end printOperatorAsCorbaString;

protected function printEachAsCorbaString
  input Absyn.Each each_;
algorithm
  _ := match each_
    case Absyn.EACH() equation Print.printBuf("record Absyn.EACH end Absyn.EACH;"); then ();
    case Absyn.NON_EACH() equation Print.printBuf("record Absyn.NON_EACH end Absyn.NON_EACH;"); then ();
  end match;
end printEachAsCorbaString;

protected function printTupleExpExpAsCorbaString
  input tuple<Absyn.Exp,Absyn.Exp> tpl;
algorithm
  printTupleAsCorbaString(tpl,printExpAsCorbaString,printExpAsCorbaString);
end printTupleExpExpAsCorbaString;

protected function printStringAsCorbaString
  input String s;
algorithm
  Print.printBuf("\"");
  Print.printBuf(s);
  Print.printBuf("\"");
end printStringAsCorbaString;

end Dump;

