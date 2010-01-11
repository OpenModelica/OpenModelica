/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package Dump
"
  file:	       Dump.mo
  package:     Dump
  description: debug printing

  RCS: $Id$

  Printing routines for debugging of the AST.  These functions do
  nothing but print the data structures to the standard output.

  The main entrypoint for this module is the function \"dump\" which
  takes an entire program as an argument, and prints it all in
  Modelica source form. The other interface functions can be used
  to print smaller portions of a program."

public import Absyn;
public import Interactive;

public type Ident = String;

protected import Print;
protected import Util;
protected import Debug;

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
"function: dump
  Prints a program, i.e. the whole AST, to the Print buffer."
  input Absyn.Program inProgram;
algorithm
  _ := matchcontinue (inProgram)
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
  end matchcontinue;
end dump;

public function unparseStr 
"function: unparseStr
  Prettyprints the Program, i.e. the whole AST, to a string."
  input Absyn.Program inProgram;
  input Boolean inBoolean "Used by MathCore, and dependencies to other modules requires this to also be in OpenModelica. Contact peter.aronsson@mathcore.com for
  explanation";
  output String outString;
algorithm
  outString := matchcontinue (inProgram,inBoolean)
    local
      Ident s1,s2,s3,str;
      list<Absyn.Class> cs;
      Absyn.Within w;
    case (Absyn.PROGRAM(classes = {}),_) then "";
    case (Absyn.PROGRAM(classes = cs,within_ = w),_)
      equation
        s1 = unparseWithin(0, w);
        s2 = unparseClassList(0, cs);
        str = Util.stringAppendList({s1,s2,"\n"});
      then
        str;
    case (_,_) then "unparsing failed\n";
  end matchcontinue;
end unparseStr;

public function unparseClassList 
"function: unparseClassList
  Prettyprints a list of classes"
  input Integer inInteger;
  input list<Absyn.Class> inAbsynClassLst;
  output String outString;
algorithm
  outString := matchcontinue (inInteger,inAbsynClassLst)
    local
      Ident s1,s2,res;
      Integer i;
      Absyn.Class c;
      list<Absyn.Class> cs;
    case (_,{}) then "";
    case (i,(c :: cs))
      equation
        s1 = unparseClassStr(i, c, "", ("",""), "");
        s2 = unparseClassList(i, cs);
        res = Util.stringAppendList({s1,";\n",s2});
      then
        res;
  end matchcontinue;
end unparseClassList;

public function unparseWithin 
"function: unparseWithin
  Prettyprints a within statement."
  input Integer inInteger;
  input Absyn.Within inWithin;
  output String outString;
algorithm
  outString := matchcontinue (inInteger,inWithin)
    local
      Ident s1,s2,str;
      Integer i;
      Absyn.Path p;
    case (_,Absyn.TOP()) then "";
    case (i,Absyn.WITHIN(path = p))
      equation
        s1 = indentStr(i);
        s2 = Absyn.pathString(p);
        str = Util.stringAppendList({s1,"within ",s2,";\n"});
      then
        str;
  end matchcontinue;
end unparseWithin;

protected function dumpWithin 
"function: dumpWithin
  Dumps within to the Print buffer."
  input Absyn.Within inWithin;
algorithm
  _ := matchcontinue (inWithin)
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
  end matchcontinue;
end dumpWithin;

public function unparseClassStr 
"function: unparseClassStr
  Prettyprints a Class.
    // adrpo: BEWARE! the prefix keywords HAVE TO BE IN A SPECIFIC ORDER:
    //  ([final] | [redeclare] [final] [inner] [outer]) [replaceable] [encapsulated] [partial] [restriction] name
    // if the order is not the one above on re-parse will give errors!"
  input Integer indent;
  input Absyn.Class ourClass;
  input String finalStr;
  input tuple<String,String> redeclareKeywords;
  input String innerouterStr;
  output String outString;
algorithm
  outString := matchcontinue (indent,ourClass,finalStr,redeclareKeywords,innerouterStr)
    local
      Ident is,s1,s2,s2_1,s3,s4,s5,str,n,fi,io,s6,s7,s8,s9,name,baseClassName;
      Integer i_1,i,indent;
      Boolean p,f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
      Option<Ident> optcmt;
      Absyn.TypeSpec tspec;
      Absyn.ElementAttributes attr;
      list<Absyn.ElementArg> m,cmod;
      Option<Absyn.Comment> cmt;
      list<Absyn.EnumLiteral> l;
      Absyn.EnumDef ENUM_COLON;
      Absyn.Path fname;
      list<Ident> vars;
      tuple<String,String> re;
      String redeclareStr, replaceableStr, partialStr, finalStr, encapsulatedStr, restrictionStr, prefixKeywords;
    // adrpo: BEWARE! the prefix keywords HAVE TO BE IN A SPECIFIC ORDER:
    //  ([final] | [redeclare] [final] [inner] [outer]) [replaceable] [encapsulated] [partial] [restriction] name
    // if the order is not the one above the parser will give errors!
    case (i,Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                        body = Absyn.PARTS(classParts = parts,comment = optcmt)),fi,re,io)
      equation
        is = indentStr(i);
        encapsulatedStr = selectString(e, "encapsulated ", "");
        partialStr = selectString(p, "partial ", "");
        finalStr = selectString(f, "final ", fi);
        restrictionStr = unparseRestrictionStr(r);
        i_1 = i + 1;
        s4 = unparseClassPartStrLst(i_1, parts, true);
        s5 = unparseStringCommentOption(optcmt);
        // the prefix keywords MUST be in the order below given below! See the function comment.
        prefixKeywords = unparseElementPrefixKeywords(re, finalStr, innerouterStr, encapsulatedStr, partialStr);
        str = Util.stringAppendList({is,prefixKeywords,restrictionStr," ",n,s5,"\n",s4,is,"end ",n});
      then
        str;
    case (indent,Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                             body = Absyn.DERIVED(typeSpec = tspec,attributes = attr,arguments = m,comment = optcmt)),fi,re,io)
      local Option<Absyn.Comment> optcmt;
      equation
        is = indentStr(indent);        
        partialStr = selectString(p, "partial ", "");
        finalStr = selectString(f, "final ", fi);
        encapsulatedStr = selectString(e, "encapsulated ", "");
        restrictionStr = unparseRestrictionStr(r);
        s4 = unparseElementattrStr(attr);
        s6 = unparseTypeSpec(tspec);
        s8 = unparseMod1Str(m);
        s9 = unparseCommentOption(optcmt);
        // the prefix keywords MUST be in the order below given below! See the function comment.        
        prefixKeywords = unparseElementPrefixKeywords(re, finalStr, innerouterStr, encapsulatedStr, partialStr);
        str = Util.stringAppendList({is,prefixKeywords,restrictionStr," ",n," = ",s4,s6,s8,s9});
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
        str = Util.stringAppendList({is,prefixKeywords,restrictionStr," ",n," = enumeration(",s4,")",s5});
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
        str = Util.stringAppendList({is,prefixKeywords,restrictionStr," ",n," = enumeration(:)",s5});
      then
        str;
    case (i,Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,
                        body = Absyn.CLASS_EXTENDS(baseClassName = baseClassName,modifications = cmod,comment = optcmt,parts = parts)),fi,re,io)
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
        // the prefix keywords MUST be in the order below given below! See the function comment.        
        prefixKeywords = unparseElementPrefixKeywords(re, finalStr, innerouterStr, encapsulatedStr, partialStr);        
        str = Util.stringAppendList({is,prefixKeywords,restrictionStr," extends ",baseClassName,s5,s6,"\n",s4,is,"end ",baseClassName});
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
        s5 = Util.stringDelimitList(vars, ", ");
        s6 = unparseCommentOption(cmt);
        prefixKeywords = unparseElementPrefixKeywords(re, finalStr, innerouterStr, encapsulatedStr, partialStr);        
        str = Util.stringAppendList({is,prefixKeywords,restrictionStr," ",n," = der(",s4,", ",s5,")", s6});
      then
        str;
  end matchcontinue;
end unparseClassStr;

public function unparseClassAttributesStr 
"function: unparseClassAttributesStr
  Prettyprints Class attributes."
  input Absyn.Class inClass;
  output String outString;
algorithm
  outString := matchcontinue (inClass)
    local
      Ident is,s1,s2,s2_1,s3,s4,s5,str,n,fi,re,io,s6,s7,s8,s9,name;
      Integer i_1,i,indent;
      Boolean p,f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
      Option<Ident> optcmt;
      Absyn.TypeSpec tspec;
      Absyn.ElementAttributes attr;
      list<Absyn.ElementArg> m,cmod;
      Option<Absyn.Comment> cmt;
      list<Absyn.EnumLiteral> l;
      Absyn.EnumDef ENUM_COLON;
      Absyn.Path fname;
      list<Ident> vars;
    case (Absyn.CLASS(name = n,partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r,body = _))
      equation
        s1 = selectString(p, "partial ", "");
        s2 = selectString(f, "final ", "");
        s2_1 = selectString(e, "encapsulated ", "");
        s3 = unparseRestrictionStr(r);
        str = Util.stringAppendList({s2_1,s1,s2,s3});
      then
        str;
  end matchcontinue;
end unparseClassAttributesStr;

public function unparseCommentOption 
"function: unparseCommentOption
  Prettyprints a Comment."
  input Option<Absyn.Comment> inAbsynCommentOption;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynCommentOption)
    local
      Ident s1,str,cmt;
      Option<Absyn.Annotation> annopt;
    case (NONE) then "";
    case (SOME(Absyn.COMMENT(annopt,SOME(cmt))))
      equation
        s1 = unparseAnnotationOption(0, annopt);
        str = Util.stringAppendList({" \"",cmt,"\"",s1});
      then
        str;
    case (SOME(Absyn.COMMENT(annopt,NONE)))
      equation
        str = unparseAnnotationOption(0, annopt);
      then
        str;
  end matchcontinue;
end unparseCommentOption;

public function unparseCommentOptionNoAnnotation 
"function: unparseCommentOptionNoAnnotation
  Prettyprints a Comment without printing the annotation part."
  input Option<Absyn.Comment> inAbsynCommentOption;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynCommentOption)
    local Ident str,cmt;
    case (SOME(Absyn.COMMENT(_,SOME(cmt))))
      equation
        str = Util.stringAppendList({" \"",cmt,"\""});
      then
        str;
    case (_) then "";
  end matchcontinue;
end unparseCommentOptionNoAnnotation;

protected function dumpCommentOption 
"function: dumpCommentOption
  Prints a Comment to the Print buffer."
  input Option<Absyn.Comment> inAbsynCommentOption;
algorithm
  _ := matchcontinue (inAbsynCommentOption)
    local
      Ident str,cmt;
      Option<Absyn.Annotation> annopt;
    case (NONE)
      equation
        Print.printBuf("NONE()");
      then
        ();
    case (SOME(Absyn.COMMENT(annopt,SOME(cmt))))
      equation
        Print.printBuf("SOME(Absyn.COMMENT(");
        dumpAnnotationOption(annopt);
        str = Util.stringAppendList({"SOME(\"",cmt,"\")))"});
        Print.printBuf(str);
      then
        ();
    case (SOME(Absyn.COMMENT(annopt,NONE)))
      equation
        Print.printBuf("SOME(Absyn.COMMENT(");
        dumpAnnotationOption(annopt);
        Print.printBuf(",NONE))");
      then
        ();
  end matchcontinue;
end dumpCommentOption;

protected function dumpAnnotationOption 
"function: dumpAnnotationOption
  Dumps an annotation option to the Print buffer."
  input Option<Absyn.Annotation> inAbsynAnnotationOption;
algorithm
  _ := matchcontinue (inAbsynAnnotationOption)
    local list<Absyn.ElementArg> mod;
    case (NONE)
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
  end matchcontinue;
end dumpAnnotationOption;

protected function unparseEnumliterals 
"function: unparseEnumliterals
  Prettyprints enumeration literals, each consisting of an identifier and an optional comment."
  input list<Absyn.EnumLiteral> inAbsynEnumLiteralLst;
  output String outString;
algorithm
  outString := matchcontinue (inAbsynEnumLiteralLst)
    local
      Ident s1,s2,res,str,str2;
      Option<Absyn.Comment> optcmt,optcmt2;
      Absyn.EnumLiteral a;
      list<Absyn.EnumLiteral> b;
    case ({}) then "";
    case ((Absyn.ENUMLITERAL(literal = str,comment = optcmt) :: (a :: b)))
      equation
        s1 = unparseCommentOption(optcmt);
        s2 = unparseEnumliterals((a :: b));
        res = Util.stringAppendList({str,s1,", ",s2});
      then
        res;
    case ({Absyn.ENUMLITERAL(literal = str,comment = optcmt),Absyn.ENUMLITERAL(literal = str2,comment = optcmt2)})
      equation
        s1 = unparseCommentOption(optcmt);
        s2 = unparseCommentOption(optcmt2);
        res = Util.stringAppendList({str," ",s1,", ",str2," ",s2});
      then
        res;
  end matchcontinue;
end unparseEnumliterals;

protected function printEnumliterals 
"function: printEnumliterals
  Prints enumeration literals, each consisting of an 
  identifier and an optional comment to the Print buffer."
  input list<Absyn.EnumLiteral> lst;
algorithm
  Print.printBuf("[");
  printEnumliterals2(lst);
  Print.printBuf("]");
end printEnumliterals;

protected function printEnumliterals2 
"function: printEnumliterals2
  Helper function to printEnumliterals"
  input list<Absyn.EnumLiteral> inAbsynEnumLiteralLst;
algorithm
  _ := matchcontinue (inAbsynEnumLiteralLst)
    local
      Ident str,str2;
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
"function: unparseRestrictionStr
  Prettyprints the class restriction."
  input Absyn.Restriction inRestriction;
  output String outString;
algorithm
  outString := matchcontinue (inRestriction)
    case Absyn.R_CLASS() then "class";
    case Absyn.R_MODEL() then "model";
    case Absyn.R_RECORD() then "record";
    case Absyn.R_BLOCK() then "block";
    case Absyn.R_CONNECTOR() then "connector";
    case Absyn.R_EXP_CONNECTOR() then "expandable connector";
    case Absyn.R_TYPE() then "type";
    case Absyn.R_UNIONTYPE() then "uniontype";
    case Absyn.R_PACKAGE() then "package";
    case Absyn.R_FUNCTION() then "function";
    case Absyn.R_PREDEFINED_INT() then "Integer";
    case Absyn.R_PREDEFINED_REAL() then "Real";
    case Absyn.R_PREDEFINED_STRING() then "String";
    case Absyn.R_PREDEFINED_BOOL() then "Boolean";
  end matchcontinue;
end unparseRestrictionStr;

public function dumpIstmt 
"function: dumpIstmt
  Dumps an interactive statement to the Print buffer."
  input Interactive.InteractiveStmts inInteractiveStmts;
algorithm
  _ := matchcontinue (inInteractiveStmts)
    local
      Absyn.AlgorithmItem alg;
      Absyn.Exp expr;
      list<Interactive.InteractiveStmt> l;
      Boolean sc;
    case (Interactive.ISTMTS(interactiveStmtLst = {Interactive.IALG(algItem = alg)}))
      equation
        Print.printBuf("IALG(");
        printAlgorithmitem(alg);
        Print.printBuf(")\n");
      then
        ();
    case (Interactive.ISTMTS(interactiveStmtLst = {Interactive.IEXP(exp = expr)}))
      equation
        Print.printBuf("IEXP(");
        printExp(expr);
        Print.printBuf(")\n");
      then
        ();
    case (Interactive.ISTMTS(interactiveStmtLst = (Interactive.IALG(algItem = alg) :: l),semicolon = sc))
      equation
        Print.printBuf("IALG(");
        printAlgorithmitem(alg);
        Print.printBuf(",");
        dumpIstmt(Interactive.ISTMTS(l,sc));
      then
        ();
    case (Interactive.ISTMTS(interactiveStmtLst = (Interactive.IEXP(exp = expr) :: l),semicolon = sc))
      equation
        Print.printBuf("IEXP(");
        printExp(expr);
        Print.printBuf(",");
        dumpIstmt(Interactive.ISTMTS(l,sc));
      then
        ();
    case (_) then ();
  end matchcontinue;
end dumpIstmt;

public function printInfo 
"function: printInfo
  author: adrpo, 2006-02-05
  Dumps an Info to the Print buffer."
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue (inInfo)
    local
      Ident s1,s2,s3,s4,filename;
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
  end matchcontinue;
end printInfo;

public function unparseInfoStr 
"function: unparseInfoStr
  author: adrpo, 2006-02-05
  Translates Info to a string representation"
  input Absyn.Info inInfo;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInfo)
    local
      Ident s1,s2,s3,s4,s5,str,filename;
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
        str = Util.stringAppendList({"Absyn.INFO(\"",filename,"\", ",s1,", ",s2,", ",s3,", ",s4,", ",s5,")\n"});
      then
        str;
  end matchcontinue;
end unparseInfoStr;

protected function printClass 
"function: printClass
  Dumps a Class to the Print buffer.
  changed by adrpo, 2006-02-05 to use printInfo."
  input Absyn.Class inClass;
algorithm
  _ := matchcontinue (inClass)
    local
      Ident n;
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
  end matchcontinue;
end printClass;

protected function printClassdef 
"function: printClassdef
  Prints a ClassDef to the Print buffer."
  input Absyn.ClassDef inClassDef;
algorithm
  _ := matchcontinue (inClassDef)
    local
      list<Absyn.ClassPart> parts;
      Option<Ident> commentStr;
      Option<Absyn.Comment> comment;      
      Ident s,baseClassName;
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
  end matchcontinue;
end printClassdef;

protected function printClassRestriction 
"function: printClassRestriction
  Prints the class restriction to the Print buffer."
  input Absyn.Restriction inRestriction;
algorithm
  _ := matchcontinue (inRestriction)
    case Absyn.R_CLASS() equation Print.printBuf("Absyn.R_CLASS"); then ();
    case Absyn.R_MODEL() equation Print.printBuf("Absyn.R_MODEL"); then ();
    case Absyn.R_RECORD() equation Print.printBuf("Absyn.R_RECORD"); then ();
    case Absyn.R_BLOCK() equation Print.printBuf("Absyn.R_BLOCK"); then ();
    case Absyn.R_CONNECTOR() equation Print.printBuf("Absyn.R_CONNECTOR"); then ();
    case Absyn.R_EXP_CONNECTOR() equation Print.printBuf("Absyn.R_EXP_CONNECTOR"); then ();
    case Absyn.R_TYPE() equation Print.printBuf("Absyn.R_TYPE"); then ();
    case Absyn.R_UNIONTYPE() equation Print.printBuf("Absyn.R_UNIONTYPE"); then ();
    case Absyn.R_PACKAGE() equation Print.printBuf("Absyn.R_PACKAGE"); then ();
    case Absyn.R_FUNCTION() equation Print.printBuf("Absyn.R_FUNCTION"); then ();
    case Absyn.R_ENUMERATION() equation Print.printBuf("Absyn.R_ENUMERATION"); then ();
    case Absyn.R_PREDEFINED_INT() equation Print.printBuf("Absyn.R_PREDEFINED_INT"); then ();
    case Absyn.R_PREDEFINED_REAL() equation Print.printBuf("Absyn.R_PREDEFINED_REAL"); then ();
    case Absyn.R_PREDEFINED_STRING() equation Print.printBuf("Absyn.R_PREDEFINED_STRING"); then ();
    case Absyn.R_PREDEFINED_BOOL() equation Print.printBuf("Absyn.R_PREDEFINED_BOOL"); then ();
    case Absyn.R_PREDEFINED_ENUM() equation Print.printBuf("Absyn.R_PREDEFINED_ENUM"); then ();
    case _ then ();
  end matchcontinue;
end printClassRestriction;

protected function printClassModification 
"function: printClassModification
  Prints a class modification to a print buffer."
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
"function: unparseClassModificationStr
  Prettyprints a class modification to a string."
  input Absyn.Modification inModification;
  output String outString;
algorithm
  outString := matchcontinue (inModification)
    local
      Ident s1,s2,str;
      list<Absyn.ElementArg> l;
      Absyn.Exp e;
    case (Absyn.CLASSMOD(elementArgLst = {})) then "";
    case (Absyn.CLASSMOD(elementArgLst = l,expOption = NONE))
      equation
        s1 = getStringList(l, unparseElementArgStr, ", ");
        s2 = stringAppend("(", s1);
        str = stringAppend(s2, ")");
      then
        str;
    case (Absyn.CLASSMOD(expOption = SOME(e)))
      equation
        s1 = printExpStr(e);
        str = Util.stringAppendList({" = ",s1});
      then
        str;
  end matchcontinue;
end unparseClassModificationStr;

protected function printElementArg 
"function: printElementArg
  Prints an ElementArg to the Print buffer."
  input Absyn.ElementArg inElementArg;
algorithm
  _ := matchcontinue (inElementArg)
    local
      Boolean f;
      Absyn.Each each_;
      Absyn.ComponentRef r;
      Option<Absyn.Modification> optm;
      Option<Ident> optcmt;
      Absyn.RedeclareKeywords keywords;
      Absyn.ElementSpec spec;
    case (Absyn.MODIFICATION(finalItem = f,each_ = each_,componentRef = r,modification = optm,comment = optcmt))
      equation
        Print.printBuf("Absyn.MODIFICATION(");
        printBool(f);
        Print.printBuf(", ");
        dumpEach(each_);
        Print.printBuf(", ");
        printComponentRef(r);
        Print.printBuf(", ");
        printOptModification(optm);
        Print.printBuf(", ");
        printStringCommentOption(optcmt);
        Print.printBuf(")");
      then
        ();
    case (Absyn.REDECLARATION(finalItem = f,redeclareKeywords = keywords,each_ = each_,elementSpec = spec))
      equation
        Print.printBuf("Absyn.REDECLARATION(");
        printBool(f);
        printElementspec(spec);
        Print.printBuf(",_)");
      then
        ();
  end matchcontinue;
end printElementArg;

public function unparseElementArgStr 
"function: unparseElementArgStr
  Prettyprints an ElementArg to a string."
  input Absyn.ElementArg inElementArg;
  output String outString;
algorithm
  outString := matchcontinue (inElementArg)
    local
      Ident s1,s2,s3,s4,s5,str;
      Boolean f;
      Absyn.Each each_;
      Absyn.ComponentRef r;
      Option<Absyn.Modification> optm;
      Option<Ident> optstr;
      Absyn.RedeclareKeywords keywords;
      Absyn.ElementSpec spec;
      Option<Absyn.ConstrainClass> constr;
      String redeclareStr, replaceableStr;
      
    case (Absyn.MODIFICATION(finalItem = f,each_ = each_,componentRef = r,modification = optm,comment = optstr))
      equation
        s1 = unparseEachStr(each_);
        s2 = selectString(f, "final ", "");
        s3 = printComponentRefStr(r);
        s4 = unparseOptModificationStr(optm);
        s5 = unparseStringCommentOption(optstr);
        str = Util.stringAppendList({s1,s2,s3,s4,s5});
      then
        str;
    case (Absyn.REDECLARATION(finalItem = f,redeclareKeywords = keywords,each_ = each_,elementSpec = spec,constrainClass = constr))
      equation
        s1 = unparseEachStr(each_);
        s2 = selectString(f, "final ", "");
        ((redeclareStr, replaceableStr)) = unparseRedeclarekeywords(keywords);
        // append each after redeclare because we need this order:
        // [redeclare] [each] [final] [replaceable]
        redeclareStr = redeclareStr +& s1; 
        s4 = unparseElementspecStr(0, spec, s2, (redeclareStr,replaceableStr), "");
        s5 = unparseConstrainclassOptStr(constr);
        str = Util.stringAppendList({s4,s5});
      then
        str;
  end matchcontinue;
end unparseElementArgStr;

protected function unparseRedeclarekeywords 
"function: unparseRedeclarekeywords
  Prettyprints the redeclare keywords, i.e replaceable and redeclare"
  input Absyn.RedeclareKeywords inRedeclareKeywords;
  output tuple<String,String> outTupleRedeclareReplaceable;
algorithm
  outTupleRedeclareReplaceable := matchcontinue (inRedeclareKeywords)
    case Absyn.REDECLARE() then (("redeclare ",""));
    case Absyn.REPLACEABLE() then (("","replaceable "));
    case Absyn.REDECLARE_REPLACEABLE() then (("redeclare ","replaceable "));
  end matchcontinue;
end unparseRedeclarekeywords;

public function unparseEachStr 
"function: unparseEachStr
  Prettyprints the each keyword."
  input Absyn.Each inEach;
  output String outString;
algorithm
  outString := matchcontinue (inEach)
    case (Absyn.EACH()) then "each ";
    case (Absyn.NON_EACH()) then "";
  end matchcontinue;
end unparseEachStr;

protected function dumpEach 
"function: dumpEach
  Print the each keyword to the Print buffer"
  input Absyn.Each inEach;
algorithm
  _ := matchcontinue (inEach)
    case (Absyn.EACH()) equation Print.printBuf("Absyn.EACH"); then ();
    case (Absyn.NON_EACH()) equation Print.printBuf("Absyn.NON_EACH"); then ();
  end matchcontinue;
end dumpEach;

protected function printClassPart 
"function: printClassPart
  Prints the ClassPart to the Print buffer."
  input Absyn.ClassPart inClassPart;
algorithm
  _ := matchcontinue (inClassPart)
    local
      list<Absyn.ElementItem> el;
      list<Absyn.EquationItem> eqs;
      list<Absyn.AlgorithmItem> algs;
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
  end matchcontinue;
end printClassPart;

protected function printExternalDecl 
"function: printExternalDecl
  Prints an external declaration to the Print buffer."
  input Absyn.ExternalDecl inExternalDecl;
algorithm
  _ := matchcontinue (inExternalDecl)
    local
      Ident idstr,crefstr,expstr,str,lang;
      Option<Ident> id;
      Option<Absyn.ComponentRef> cref;
      list<Absyn.Exp> exps;
    case Absyn.EXTERNALDECL(funcName = id,lang = NONE,output_ = cref,args = exps)
      equation
        idstr = getOptionStr(id, identity);
        crefstr = getOptionStr(cref, printComponentRefStr);
        expstr = printListStr(exps, printExpStr, ",");
        str = Util.stringAppendList({idstr,", ",crefstr,", (",expstr,")"});
        Print.printBuf(str);
      then
        ();
    case Absyn.EXTERNALDECL(funcName = id,lang = SOME(lang),output_ = cref,args = exps)
      equation
        idstr = getOptionStr(id, identity);
        crefstr = getOptionStr(cref, printComponentRefStr);
        expstr = printListStr(exps, printExpStr, ",");
        str = Util.stringAppendList({idstr,", \"",lang,"\", ",crefstr,", (",expstr,")"});
        Print.printBuf(str);
      then
        ();
  end matchcontinue;
end printExternalDecl;

public function unparseClassPartStrLst 
"function: unparseClassPartStrLst
  Prettyprints a ClassPart list to a string."
  input Integer inInteger;
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Boolean inBoolean;
  output String outString;
algorithm
  outString := matchcontinue (inInteger,inAbsynClassPartLst,inBoolean)
    local
      Ident s1,s2,res;
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
  end matchcontinue;
end unparseClassPartStrLst;

protected function unparseClassPartStr
"function: unparseClassPartStr
  Prettyprints a ClassPart to a string."
  input Integer inInteger;
  input Absyn.ClassPart inClassPart;
  input Boolean inBoolean;
  output String outString;
algorithm
  outString := matchcontinue (inInteger,inClassPart,inBoolean)
    local
      Integer i,i_1;
      Ident s1,is,str,langstr,outputstr,expstr,annstr,annstr2,ident,res;
      list<Absyn.ElementItem> el;
      list<Absyn.EquationItem> eqs;
      Option<Ident> lang;
      Absyn.ComponentRef output_;
      list<Absyn.Exp> expl;
      Option<Absyn.Annotation> ann,ann2;
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
        str = Util.stringAppendList({s1});
      then
        str;
    case (i,Absyn.PUBLIC(contents = el),false)
      equation
        s1 = unparseElementitemStrLst(i, el);
        i_1 = i - 1;
        is = indentStr(i_1);
        str = Util.stringAppendList({is,"public \n",s1});
      then
        str;
    case (i,Absyn.PROTECTED(contents = el),_)
      equation
        s1 = unparseElementitemStrLst(i, el);
        i_1 = i - 1;
        is = indentStr(i_1);
        str = Util.stringAppendList({is,"protected \n",s1});
      then
        str;
    case (i,Absyn.EQUATIONS(contents = eqs),_)
      equation
        s1 = unparseEquationitemStrLst(i, eqs, ";\n");
        i_1 = i - 1;
        is = indentStr(i_1);
        str = Util.stringAppendList({"\n",is,"equation \n",s1});
      then
        str;
    case (i,Absyn.INITIALEQUATIONS(contents = eqs),_)
      equation
        s1 = unparseEquationitemStrLst(i, eqs, ";\n");
        i_1 = i - 1;
        is = indentStr(i_1);
        str = Util.stringAppendList({"\n",is,"initial equation \n",s1});
      then
        str;
    case (i,Absyn.ALGORITHMS(contents = eqs),_)
      local list<Absyn.AlgorithmItem> eqs;
      equation
        s1 = unparseAlgorithmStrLst(i, eqs, "\n");
        i_1 = i - 1;
        is = indentStr(i_1);
        str = Util.stringAppendList({is,"algorithm \n",s1});
      then
        str;
    case (i,Absyn.INITIALALGORITHMS(contents = eqs),_)
      local list<Absyn.AlgorithmItem> eqs;
      equation
        s1 = unparseAlgorithmStrLst(i, eqs, "\n");
        i_1 = i - 1;
        is = indentStr(i_1);
        str = Util.stringAppendList({is,"initial algorithm \n",s1});
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
        str = Util.stringAppendList(
          {"\n",is,"external ",langstr," ",outputstr," = ",ident,"(",
          expstr,") ",annstr,";",annstr2,"\n"});
      then
        str;
    case (i,Absyn.EXTERNAL(externalDecl = Absyn.EXTERNALDECL(
                           funcName = SOME(ident),lang = lang,output_ = NONE,
                           args = expl,annotation_ = ann),annotation_ = ann2),_)
      equation
        langstr = getExtlangStr(lang);
        expstr = printListStr(expl, printExpStr, ",");
        s1 = stringAppend(langstr, " ");
        is = indentStr(i);
        annstr = unparseAnnotationOption(i, ann);
        annstr2 = unparseAnnotationOptionSemi(i, ann2);
        str = Util.stringAppendList(
          {"\n",is,"external ",langstr," ",ident,"(",expstr,") ",
          annstr,"; ",annstr2,"\n"});
      then
        str;
    case (i,Absyn.EXTERNAL(externalDecl = Absyn.EXTERNALDECL(
                           funcName = NONE,lang = lang,output_ = NONE,
                           annotation_ = ann),annotation_ = ann2),_)
      equation
        is = indentStr(i);
        langstr = getExtlangStr(lang);
        annstr = unparseAnnotationOption(i, ann);
        annstr2 = unparseAnnotationOptionSemi(i, ann2);
        res = Util.stringAppendList({"\n",is,"external ",langstr," ",annstr,";",annstr2,"\n"});
      then
        res;
  end matchcontinue;
end unparseClassPartStr;

protected function getExtlangStr 
"function: getExtlangStr
  Prettyprints the external function language string to a string."
  input Option<String> inStringOption;
  output String outString;
algorithm
  outString := matchcontinue (inStringOption)
    local Ident res,str;
    case (NONE) then "";
    case (SOME(str)) equation res = Util.stringAppendList({"\"",str,"\""}); then res;
  end matchcontinue;
end getExtlangStr;

protected function printElementitems 
"function: printElementitems
  Print a list of ElementItems to the Print buffer."
  input list<Absyn.ElementItem> elts;
algorithm
  Print.printBuf("[");
  printElementitems2(elts);
  Print.printBuf("]");
end printElementitems;

protected function printElementitems2 
"function: printElementitems2
  Helper function to printElementitems"
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
    case ({Absyn.ANNOTATIONITEM(annotation_ = a)})
      equation
        Print.printBuf("Absyn.ANNOTATIONITEM(");
        printAnnotation(a);
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
    case (Absyn.ANNOTATIONITEM(annotation_ = a) :: els)
      equation
        Print.printBuf("Absyn.ANNOTATIONITEM(");
        printAnnotation(a);
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
"function: printAnnotation
  Prints an annotation to the Print buffer."
  input Absyn.Annotation inAnnotation;
algorithm
  _ := matchcontinue (inAnnotation)
    local list<Absyn.ElementArg> mod;
    case (Absyn.ANNOTATION(elementArgs = mod))
      equation
        Print.printBuf("ANNOTATION(");
        printModification(Absyn.CLASSMOD(mod,NONE));
        Print.printBuf(")");
      then
        ();
  end matchcontinue;
end printAnnotation;

public function unparseElementitemStrLst 
"function: unparseElementitemStrLst
  Prettyprints a list of ElementItem to a string."
  input Integer inInteger;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output String outString;
algorithm
  outString := matchcontinue (inInteger,inAbsynElementItemLst)
    local
      Ident s1,s2,res;
      Integer i;
      Absyn.ElementItem x;
      list<Absyn.ElementItem> xs;
    case (_,{}) then "";  /* indent */
    case (i,(x :: xs))
      equation
        s1 = unparseElementitemStr(i, x);
        s2 = unparseElementitemStrLst(i, xs);
        res = Util.stringAppendList({s1,"\n",s2});
      then
        res;
  end matchcontinue;
end unparseElementitemStrLst;

public function unparseElementitemStr 
"function: unparseElementitemStr
  Prettyprints and ElementItem."
  input Integer inInteger;
  input Absyn.ElementItem inElementItem;
  output String outString;
algorithm
  outString := matchcontinue (inInteger,inElementItem)
    local
      Ident str,s1;
      Integer i;
      Absyn.Element e;
      Absyn.Annotation a;
    case (i,Absyn.ELEMENTITEM(element = e)) /* indent */
      equation
        str = unparseElementStr(i, e);
      then
        str;
    case (i,Absyn.ANNOTATIONITEM(annotation_ = a))
      equation
        s1 = unparseAnnotationOption(i, SOME(a));
        str = stringAppend(s1, ";");
      then
        str;
  end matchcontinue;
end unparseElementitemStr;

protected function unparseAnnotationOptionSemi 
"function: unparseAnnotationOptionSemi
  Prettyprint an annotation and a semicolon if annoation present."
  input Integer inInteger;
  input Option<Absyn.Annotation> inAbsynAnnotationOption;
  output String outString;
algorithm
  outString := matchcontinue (inInteger,inAbsynAnnotationOption)
    local
      Ident s,res;
      Integer i;
      Option<Absyn.Annotation> ann;
    case (_,NONE) then "";
    case (i,ann)
      equation
        s = unparseAnnotationOption(i, ann);
        res = stringAppend(s, ";");
      then
        res;
  end matchcontinue;
end unparseAnnotationOptionSemi;

public function unparseAnnotationOption 
"function: unparseAnnotationOption
  Prettyprint an annotation."
  input Integer inInteger;
  input Option<Absyn.Annotation> inAbsynAnnotationOption;
  output String outString;
algorithm
  outString := matchcontinue (inInteger,inAbsynAnnotationOption)
    local
      Ident s1,s2,str,is;
      list<Absyn.ElementArg> mod;
      Integer i;
    case (0,SOME(Absyn.ANNOTATION(mod)))
      equation
        s1 = unparseClassModificationStr(Absyn.CLASSMOD(mod,NONE));
        s2 = stringAppend(" annotation", s1);
        str = stringAppend(s2, "");
      then
        str;
    case (i,SOME(Absyn.ANNOTATION(mod)))
      equation
        s1 = unparseClassModificationStr(Absyn.CLASSMOD(mod,NONE));
        is = indentStr(i);
        str = Util.stringAppendList({is,"annotation",s1});
      then
        str;
    case (_,NONE) then "";
  end matchcontinue;
end unparseAnnotationOption;

protected function printElement "function: printElement

  Prints an Element to the Print buffer.
  changed by adrpo, 2006-02-06 to use print_info and dump Absyn.TEXT also
"
  input Absyn.Element inElement;
algorithm
  _:=
  matchcontinue (inElement)
    local
      Boolean finalPrefix;
      Option<Absyn.RedeclareKeywords> repl;
      Absyn.InnerOuter inout;
      Ident name,text;
      Absyn.ElementSpec spec;
      Absyn.Info info;
    case (Absyn.ELEMENT(finalPrefix = finalPrefix,redeclareKeywords = repl,innerOuter = inout,name = name,
                        specification = spec,info = info,constrainClass = NONE))
      equation
        Print.printBuf("Absyn.ELEMENT(");
        printBool(finalPrefix);
        Print.printBuf(", _");
        Print.printBuf(", ");
        printInnerouter(inout);
        Print.printBuf(", \"");
        Print.printBuf(name);
        Print.printBuf("\", ");
        printElementspec(spec);
        Print.printBuf(", ");
        printInfo(info);
        Print.printBuf("), NONE)");
      then
        ();
    case (Absyn.ELEMENT(finalPrefix = finalPrefix,redeclareKeywords = repl,innerOuter = inout,name = name,
                        specification = spec,info = info,constrainClass = SOME(_)))
      equation
        Print.printBuf("Absyn.ELEMENT(");
        printBool(finalPrefix);
        Print.printBuf(", _");
        Print.printBuf(", ");
        printInnerouter(inout);
        Print.printBuf(", \"");
        Print.printBuf(name);
        Print.printBuf("\", ");
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
    case (Absyn.TEXT(optName = NONE,string = text,info = info))
      equation
        Print.printBuf("Absyn.TEXT(");
        Print.printBuf("NONE, \"");
        Print.printBuf(text);
        Print.printBuf("\", ");
        printInfo(info);
        Print.printBuf(")");
      then
        ();
  end matchcontinue;
end printElement;

public function unparseElementStr "function: unparseElementStr

  Prettyprints and Element to a string.
  changed by adrpo 2006-02-05 to print also Absyn.TEXT as a comment
  TODO?? - should we also dump info as a comment for an element??
         - should we dump Absyn.TEXT as an Annotation Item??
"
  input Integer inInteger;
  input Absyn.Element inElement;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger,inElement)
    local
      Ident s1,s2,s3,s4,s5,str,name,text;
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
        str = Util.stringAppendList({s4,s5,";"});
      then
        str;
    case (i,Absyn.ELEMENT(finalPrefix = finalPrefix,redeclareKeywords = NONE,innerOuter = inout,specification = spec,info = info,constrainClass = constr))
      equation
        s1 = selectString(finalPrefix, "final ", "");
        s3 = unparseInnerouterStr(inout);
        s4 = unparseElementspecStr(i, spec, s1, ("",""), s3);
        s5 = unparseConstrainclassOptStr(constr);
        str = Util.stringAppendList({s4,s5,";"});
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
        str = Util.stringAppendList(
          {"/* Absyn.TEXT(SOME(\"",name,"\"), \"",text,"\", ",s1,
          "); */"});
      then
        str;
    case (i,Absyn.TEXT(optName = NONE,string = text,info = info))
      equation
        s1 = unparseInfoStr(info);
        str = Util.stringAppendList({"/* Absyn.TEXT(NONE, \"",text,"\", ",s1,"); */"});
      then
        str;
    case(_,_) equation
      print("unparseElementStr failed\n");
    then fail();
  end matchcontinue;
end unparseElementStr;

protected function unparseConstrainclassOptStr 
"function: unparseConstrainclassOptStr
  author: PA
  This function prettyprints a ConstrainClass option to a string."
  input Option<Absyn.ConstrainClass> inAbsynConstrainClassOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynConstrainClassOption)
    local
      Ident res;
      Absyn.ConstrainClass constr;
    case (NONE) then "";
    case (SOME(constr))
      equation
        res = " " +& unparseConstrainclassStr(constr);
      then
        res;
  end matchcontinue;
end unparseConstrainclassOptStr;

protected function unparseConstrainclassStr 
"function: unparseConstrainclassStr
  author: PA
  This function prettyprints a ConstrainClass to a string."
  input Absyn.ConstrainClass inConstrainClass;
  output String outString;
algorithm
  outString:=
  matchcontinue (inConstrainClass)
    local
      Ident s1,s2,res;
      Absyn.ElementSpec spec;
      Option<Absyn.Comment> cmt;
    case (Absyn.CONSTRAINCLASS(elementSpec = spec,comment = cmt))
      equation
        s1 = unparseElementspecStr(0, spec, "", ("",""), "");
        s2 = unparseCommentOption(cmt);
        res = stringAppend(s1, s2);
      then
        res;
  end matchcontinue;
end unparseConstrainclassStr;

protected function printInnerouter 
"function: printInnerouter
  Prints the inner or outer keyword to the Print buffer."
  input Absyn.InnerOuter inInnerOuter;
algorithm
  _:=
  matchcontinue (inInnerOuter)
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
    case (Absyn.INNEROUTER())
      equation
        Print.printBuf("Absyn.INNEROUTER ");
      then
        ();
    case (Absyn.UNSPECIFIED())
      equation
        Print.printBuf("Absyn.UNSPECIFIED ");
      then
        ();
  end matchcontinue;
end printInnerouter;

public function unparseInnerouterStr "function: unparseInnerouterStr

  Prettyprints the inner or outer keyword to a string.
"
  input Absyn.InnerOuter inInnerOuter;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInnerOuter)
    case (Absyn.INNER()) then "inner ";
    case (Absyn.OUTER()) then "outer ";
    case (Absyn.INNEROUTER()) then "inner outer ";
    case (Absyn.UNSPECIFIED()) then "";
  end matchcontinue;
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
"function: printElementspec
  Prints the ElementSpec to the Print buffer."
  input Absyn.ElementSpec inElementSpec;
algorithm
  _:=
  matchcontinue (inElementSpec)
    local
      Boolean repl;
      Absyn.Class cl;
      Absyn.Path p;
      list<Absyn.ElementArg> l;
      Ident s;
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
"function: unparseElementspecStr
  Prettyprints the ElementSpec to a string."
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
      Ident str,f,io,s1,s2,is,s3,ad,s4;
      tuple<String,String> r;
      Integer i,indent;
      Boolean repl;
      Absyn.Class cl;
      Absyn.Path p;
      list<Absyn.ElementArg> l;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec t;
      list<Absyn.ComponentItem> cs;
      String prefixKeywords;
      Option<Absyn.Annotation> annOpt;
      
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
        str = Util.stringAppendList({is,s2,s3});
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
        str = Util.stringAppendList({is,s2,"(",s3,")",s4});
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
        str = Util.stringAppendList({is,prefixKeywords,s2,s1,ad," ",s3});
      then
        str;
    case (indent,Absyn.IMPORT(import_ = i),f,r,io)
      local Absyn.Import i;
      equation
        s1 = unparseImportStr(i);
        s2 = stringAppend("import ", s1);
        is = indentStr(indent);
        // adrpo: NOTE final, replaceable/redeclare, inner/outer should NOT be used for import!        
        str = Util.stringAppendList({is,s2});
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
"function: printImport
  Prints an Import to the Print buffer."
  input Absyn.Import inImport;
algorithm
  _:=
  matchcontinue (inImport)
    local
      Ident i;
      Absyn.Path p;
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
  end matchcontinue;
end printImport;

public function unparseImportStr 
"function: unparseImportStr
  Prettyprints an Import to a string."
  input Absyn.Import inImport;
  output String outString;
algorithm
  outString := matchcontinue (inImport)
    local
      Ident s1,s2,str,i;
      Absyn.Path p;
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
  end matchcontinue;
end unparseImportStr;

protected function printElementattr "function: printElementattr

  Prints ElementAttributes to the Print buffer.
"
  input Absyn.ElementAttributes inElementAttributes;
algorithm
  _:=
  matchcontinue (inElementAttributes)
    local
      Ident vs,ds;
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

protected function unparseElementattrStr "function: unparseElementattrStr

  Prettyprints ElementAttributes to a string.
"
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  matchcontinue (inElementAttributes)
    local
      Ident fs,ss,vs,ds,str;
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
        str = Util.stringAppendList({fs,ss,vs,ds});
      then
        str;
    case (_)
      equation
        Print.printBuf(" ##ERROR## unparse_elementattr_str");
      then
        "";
  end matchcontinue;
end unparseElementattrStr;

protected function unparseArraydimInAttr "function: unparseArraydimInAttr

  Prettyprints the arraydimension in ElementAttributes to a string.
"
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm
  outString:=
  matchcontinue (inElementAttributes)
    local
      Ident str;
      list<Absyn.Subscript> adim;
    case (Absyn.ATTR(arrayDim = adim))
      equation
        str = printArraydimStr(adim);
      then
        str;
    case (_) then "";
  end matchcontinue;
end unparseArraydimInAttr;

public function variabilitySymbol "function: variabilitySymbol

  Returns a string for the Variability.
"
  input Absyn.Variability inVariability;
  output String outString;
algorithm
  outString:=
  matchcontinue (inVariability)
    case (Absyn.VAR()) then "Absyn.VAR";
    case (Absyn.DISCRETE()) then "Absyn.DISCRETE";
    case (Absyn.PARAM()) then "Absyn.PARAM";
    case (Absyn.CONST()) then "Absyn.CONST";
  end matchcontinue;
end variabilitySymbol;

public function directionSymbol "function: directionSymbol

  Returns a string for the direction.
"
  input Absyn.Direction inDirection;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDirection)
    case (Absyn.BIDIR()) then "Absyn.BIDIR";
    case (Absyn.INPUT()) then "Absyn.INPUT";
    case (Absyn.OUTPUT()) then "Absyn.OUTPUT";
  end matchcontinue;
end directionSymbol;

protected function unparseVariabilitySymbolStr "function: unparseVariabilitySymbolStr

  Returns a prettyprinted string of variability.
"
  input Absyn.Variability inVariability;
  output String outString;
algorithm
  outString:=
  matchcontinue (inVariability)
    case (Absyn.VAR()) then "";
    case (Absyn.DISCRETE()) then "discrete ";
    case (Absyn.PARAM()) then "parameter ";
    case (Absyn.CONST()) then "constant ";
  end matchcontinue;
end unparseVariabilitySymbolStr;

protected function unparseDirectionSymbolStr "function: unparseDirectionSymbolStr

  Returns a prettyprinted string of direction.
"
  input Absyn.Direction inDirection;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDirection)
    case (Absyn.BIDIR()) then "";
    case (Absyn.INPUT()) then "input ";
    case (Absyn.OUTPUT()) then "output ";
  end matchcontinue;
end unparseDirectionSymbolStr;

public function printComponent "function: printComponent

  Prints a Component to the Print buffer.
"
  input Absyn.Component inComponent;
algorithm
  _:=
  matchcontinue (inComponent)
    local
      Ident n;
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
  end matchcontinue;
end printComponent;

protected function printComponentitem "function: printComponentitem

  Prints a ComponentItem to the Print buffer.
"
  input Absyn.ComponentItem inComponentItem;
algorithm
  _:=
  matchcontinue (inComponentItem)
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
  end matchcontinue;
end printComponentitem;

protected function unparseComponentStr "function: unparseComponentStr

  Prettyprints a Component to a string.
"
  input Absyn.Component inComponent;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponent)
    local
      Ident s1,s2,s3,str,n;
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
  end matchcontinue;
end unparseComponentStr;

protected function unparseComponentitemStr "function: unparseComponentitemStr

  Prettyprints a ComponentItem to a string.
"
  input Absyn.ComponentItem inComponentItem;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentItem)
    local
      Ident s1,s3,s2,str;
      Absyn.Component c;
      Option<Absyn.Exp> optcond;
      Option<Absyn.Comment> cmtopt;
    case (Absyn.COMPONENTITEM(component = c,condition = optcond,comment = cmtopt))
      equation
        s1 = unparseComponentStr(c);
        s2 = unparseComponentCondition(optcond);
        s3 = unparseCommentOption(cmtopt);
        str = Util.stringAppendList({s1,s2,s3});
      then
        str;
  end matchcontinue;
end unparseComponentitemStr;

protected function unparseComponentCondition "function: unparseComponentCondition

  Prints a ComponentCondition option to a string.
"
  input Option<Absyn.ComponentCondition> inAbsynComponentConditionOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynComponentConditionOption)
    local
      Ident s1,res;
      Absyn.Exp cond;
    case (SOME(cond))
      equation
        s1 = printExpStr(cond);
        res = stringAppend(" if ", s1);
      then
        res;
    case (NONE) then "";
  end matchcontinue;
end unparseComponentCondition;

protected function printArraydimOpt "function: printArraydimOpt

  Prints an ArrayDim option to the Print buffer.
"
  input Option<Absyn.ArrayDim> inAbsynArrayDimOption;
algorithm
  _:=
  matchcontinue (inAbsynArrayDimOption)
    local list<Absyn.Subscript> s;
    case (NONE)
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

public function printArraydim "function: printArraydim

  Prints an ArrayDim to the Print buffer.
"
  input Absyn.ArrayDim s;
algorithm
  printSubscripts(s);
end printArraydim;

public function printArraydimStr "function: printArraydimStr

  Prettyprints an ArrayDim to a string.
"
  input Absyn.ArrayDim s;
  output String str;
algorithm
  str := printSubscriptsStr(s);
end printArraydimStr;

protected function printSubscript "function: printSubscript

  Prints an Subscript to the Print buffer.
"
  input Absyn.Subscript inSubscript;
algorithm
  _:=
  matchcontinue (inSubscript)
    local Absyn.Exp e1;
    case (Absyn.NOSUB())
      equation
        Print.printBuf("Absyn.NOSUB");
      then
        ();
    case (Absyn.SUBSCRIPT(subScript = e1))
      equation
        Print.printBuf("Absyn.SUBSCRIPT(");
        printExp(e1);
        Print.printBuf(")");
      then
        ();
  end matchcontinue;
end printSubscript;

public function printSubscriptStr "function: printSubscriptStr

  Prettyprints an Subscript to a string.
"
  input Absyn.Subscript inSubscript;
  output String outString;
algorithm
  outString:=
  matchcontinue (inSubscript)
    local
      Ident s;
      Absyn.Exp e1;
    case (Absyn.NOSUB()) then ":";
    case (Absyn.SUBSCRIPT(subScript = e1))
      equation
        s = printExpStr(e1);
      then
        s;
  end matchcontinue;
end printSubscriptStr;

protected function printOptModification "function: printOptModification

  Prints a Modification option to the Print buffer.
"
  input Option<Absyn.Modification> inAbsynModificationOption;
algorithm
  _:=
  matchcontinue (inAbsynModificationOption)
    local Absyn.Modification m;
    case (SOME(m))
      equation
        Print.printBuf("SOME(");
        printModification(m);
        Print.printBuf(")");
      then
        ();
    case (NONE) then ();
  end matchcontinue;
end printOptModification;

protected function printModification "function: printModification

  Prints a Modification to the Print buffer.
"
  input Absyn.Modification inModification;
algorithm
  _:=
  matchcontinue (inModification)
    local
      list<Absyn.ElementArg> l;
      Option<Absyn.Exp> e;
    case (Absyn.CLASSMOD(elementArgLst = l,expOption = e))
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

protected function printMod1 "function: printMod1

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

protected function printMod2 "function: printMod2

  Helper relaton to print_mod1
"
  input Option<Absyn.Exp> inAbsynExpOption;
algorithm
  _:=
  matchcontinue (inAbsynExpOption)
    local Absyn.Exp e;
    case NONE
      equation
        Print.printBuf("NONE()");
      then
        ();
    case SOME(e)
      equation
        Print.printBuf("SOME(");
        printExp(e);
        Print.printBuf(")");
      then
        ();
  end matchcontinue;
end printMod2;

public function unparseOptModificationStr "function: unparseOptModificationStr

  Prettyprints a Modification option to a string.
"
  input Option<Absyn.Modification> inAbsynModificationOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynModificationOption)
    local
      Ident str;
      Absyn.Modification opt;
    case (SOME(opt))
      equation
        str = unparseModificationStr(opt);
      then
        str;
    case (NONE) then "";
  end matchcontinue;
end unparseOptModificationStr;

public function unparseModificationStr "function: unparseModificationStr

  Prettyprints a Modification to a string.
"
  input Absyn.Modification inModification;
  output String outString;
algorithm
  outString:=
  matchcontinue (inModification)
    local
      Ident s1,s2,str;
      list<Absyn.ElementArg> l;
      Option<Absyn.Exp> e;
    case (Absyn.CLASSMOD(elementArgLst = {},expOption = NONE)) then "()";  /* Special case for empty modifications */
    case (Absyn.CLASSMOD(elementArgLst = l, expOption = e))
      equation
        s1 = unparseMod1Str(l);
        s2 = unparseMod2Str(e);
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

protected function unparseMod1Str "function: unparseMod1Str

  Helper function to unparse_modification_str
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynElementArgLst)
    local
      Ident s1,s2,str;
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

protected function unparseMod2Str "function: unparseMod2Str

  Helper function to unparse_mod1_str
"
  input Option<Absyn.Exp> inAbsynExpOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynExpOption)
    local
      Ident s1,str;
      Absyn.Exp e;
    case NONE then "";
    case SOME(e)
      equation
        s1 = printExpStr(e);
        str = stringAppend(" = ", s1);
      then
        str;
  end matchcontinue;
end unparseMod2Str;

public function printEquation "Equations
  function: printEquation

  Prints an Equation to the Print buffer.
"
  input Absyn.Equation inEquation;
algorithm
  _:=
  matchcontinue (inEquation)
    local
      Absyn.Exp e,e1,e2;
      list<Absyn.EquationItem> tb,fb,el;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> eb;
      Absyn.ForIterators iterators;
      Ident i;
      Absyn.EquationItem equItem;
      Absyn.ComponentRef cr;
      Absyn.FunctionArgs fargs;
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
    case (Absyn.EQ_CONNECT(connector1 = e1,connector2 = e2))
      local Absyn.ComponentRef e1,e2;
      equation
        Print.printBuf("EQ_CONNECT(");
        printComponentRef(e1);
        Print.printBuf(",");
        printComponentRef(e2);
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

protected function printEquationitem "function: printEquationitem

  Prints and EquationItem to the Print buffer.
"
  input Absyn.EquationItem inEquationItem;
algorithm
  _:=
  matchcontinue (inEquationItem)
    local Absyn.Equation eq;
    case Absyn.EQUATIONITEM(equation_ = eq)
      equation
        Print.printBuf("EQUATIONITEM(");
        printEquation(eq);
        Print.printBuf(", <comment>)\n");
      then
        ();
    case Absyn.EQUATIONITEMANN(annotation_ = _)
      equation
        Print.printBuf("EQUATIONITEMANN(<annotation>)\n");
      then
        ();
  end matchcontinue;
end printEquationitem;

public function unparseEquationStr 
"function: unparseEquationStr
  Prettyprints an Equation to a string."
  input Integer inInteger;
  input Absyn.Equation inEquation;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger,inEquation)
    local
      Ident s1,s2,is,str,s3,s4,id;
      Absyn.ComponentRef cref;
      Integer i_1,i,indent;
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
        s2 = unparseEquationitemStrLst(i_1, tb, ";\n");
        is = indentStr(i);
        str = Util.stringAppendList({"if ",s1," then\n",is,s2,is,"end if"});
      then
        str;
    case (i,Absyn.EQ_IF(ifExp = e,equationTrueItems = tb,elseIfBranches = eb,equationElseItems = fb))
      equation
        s1 = printExpStr(e);
        i_1 = i + 1;
        s2 = unparseEquationitemStrLst(i_1, tb, ";\n");
        s3 = unparseEqElseifStrLst(i_1, eb, "\n");
        s4 = unparseEquationitemStrLst(i_1, fb, ";\n");
        is = indentStr(i);
        str = Util.stringAppendList(
          {is,"if ",s1," then\n",s2,s3,"\n",is,"else\n",s4,"\n",is,
          "end if"});
      then
        str;
    case (i,Absyn.EQ_EQUALS(leftSide = e1,rightSide = e2))
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        is = indentStr(i);
        str = Util.stringAppendList({is,s1," = ",s2});
      then
        str;
    case (i,Absyn.EQ_CONNECT(connector1 = e1,connector2 = e2))
      local Absyn.ComponentRef e1,e2;
      equation
        s1 = printComponentRefStr(e1);
        s2 = printComponentRefStr(e2);
        is = indentStr(i);
        str = Util.stringAppendList({is,"connect(",s1,",",s2,")"});
      then
        str;
    case (indent,Absyn.EQ_FOR(iterators = iterators,forEquations = el))
      equation
        s1 = printIteratorsStr(iterators);
        s2 = unparseEquationitemStrLst(indent, el, ";\n");
        is = indentStr(indent);
        str = Util.stringAppendList({is,"for ",s1," loop\n",s2,"\n",is,"end for"});
      then
        str;
    case (i,Absyn.EQ_NORETCALL(functionName = cref,functionArgs = fargs))
      equation
        s2 = printFunctionArgsStr(fargs);
        id = printComponentRefStr(cref);
        is = indentStr(i);
        str = Util.stringAppendList({is, id,"(",s2,")"});
      then
        str;
    case (i,Absyn.EQ_WHEN_E(whenExp = exp,whenEquations = eql,elseWhenEquations = eqlelse))
      equation
        s1 = printExpStr(exp);
        i_1 = i + 1;
        s2 = unparseEquationitemStrLst(i_1, eql, ";\n");
        is = indentStr(i);
        s4 = unparseEqElsewhenStrLst(i_1, eqlelse);
        str = Util.stringAppendList({is,"when ",s1," then\n",is,s2,is,s4,"\n",is,"end when"});
      then
        str;
    case (i,Absyn.EQ_FAILURE(equItem))
      equation        
        s1 = unparseEquationitemStr(0, equItem);
        is = indentStr(i);
        str = Util.stringAppendList({is,"failure(",s1,")"});
      then
        str;
    case (_,_)
      equation
        Print.printBuf(" /** Failure! UNKNOWN EQUATION **/ ");
      then
        "";
  end matchcontinue;
end unparseEquationStr;

protected function unparseEquationitemStrLst "function:unparseEquationitemStrLst

  Prettyprints and EquationItem list to a string.
"
  input Integer inInteger;
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  input String inString;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger,inAbsynEquationItemLst,inString)
    local
      Ident s1,s2,res,sep;
      Integer i;
      Absyn.EquationItem x;
      list<Absyn.EquationItem> xs;
    case (_,{},_) then "";  /* indent */
    case (i,(x :: xs),sep)
      equation
        s1 = unparseEquationitemStr(i, x);
        s2 = unparseEquationitemStrLst(i, xs, sep);
        res = Util.stringAppendList({s1,sep,s2});
      then
        res;
  end matchcontinue;
end unparseEquationitemStrLst;

protected function unparseEquationitemStr "function: unparseEquationitemStr

  Prettyprints an EquationItem to a string.
"
  input Integer inInteger;
  input Absyn.EquationItem inEquationItem;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger,inEquationItem)
    local
      Ident s1,s2,str;
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
        str;
    case (i,Absyn.EQUATIONITEMANN(annotation_ = ann))
      equation
        str = unparseAnnotationOption(i, SOME(ann));
      then
        str;
  end matchcontinue;
end unparseEquationitemStr;

protected function printEqElseif "function: printEqElseif

  Prints an Elseif branch to the Print buffer.
"
  input tuple<Absyn.Exp, list<Absyn.EquationItem>> inTplAbsynExpAbsynEquationItemLst;
algorithm
  _:=
  matchcontinue (inTplAbsynExpAbsynEquationItemLst)
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
  end matchcontinue;
end printEqElseif;

protected function unparseEqElseifStrLst "function: unparseEqElseifStrLst

  Prettyprints an elseif branch to a string.
"
  input Integer inInteger;
  input list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> inTplAbsynExpAbsynEquationItemLstLst;
  input String inString;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger,inTplAbsynExpAbsynEquationItemLstLst,inString)
    local
      Ident s1,res,sep,s2;
      Integer i;
      tuple<Absyn.Exp, list<Absyn.EquationItem>> x1,x,x2;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> xs;
    case (_,{},_) then "";
    case (i,{x1},sep)
      equation
        s1 = unparseEqElseifStr(i, x1);
        res = Util.stringAppendList({s1,sep});
      then
        res;
    case (i,(x :: (xs as (_ :: _))),sep)
      equation
        s2 = unparseEqElseifStrLst(i, xs, sep);
        s1 = unparseEqElseifStr(i, x);
        res = Util.stringAppendList({s1,sep,s2});
      then
        res;
    case (i,{x1,x2},sep)
      equation
        s1 = unparseEqElseifStr(i, x1);
        s2 = unparseEqElseifStr(i, x2);
        res = Util.stringAppendList({s1,sep,s2});
      then
        res;
  end matchcontinue;
end unparseEqElseifStrLst;

protected function unparseEqElseifStr "function: unparseEqElseifStr

  Helper function to unparse_eq_elseif_str_lst
"
  input Integer inInteger;
  input tuple<Absyn.Exp, list<Absyn.EquationItem>> inTplAbsynExpAbsynEquationItemLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger,inTplAbsynExpAbsynEquationItemLst)
    local
      Ident s1,s2,is,res;
      Integer i_1,i;
      Absyn.Exp e;
      list<Absyn.EquationItem> el;
    case (i,(e,el))
      equation
        s1 = printExpStr(e);
        s2 = unparseEquationitemStrLst(i, el, ";\n");
        i_1 = i - 1;
        is = indentStr(i_1);
        res = Util.stringAppendList({"\n",is,"elseif ",s1," then\n",s2});
      then
        res;
  end matchcontinue;
end unparseEqElseifStr;

protected function printAlgorithmitem "Algorithm clauses
  function: printAlgorithmitem

  Prints an AlgorithmItem to the Print buffer.
"
  input Absyn.AlgorithmItem inAlgorithmItem;
algorithm
  _:=
  matchcontinue (inAlgorithmItem)
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
    case (Absyn.ALGORITHMITEMANN(annotation_ = ann))
      equation
        Print.printBuf("ALGORITHMITEMANN(<annotation>)\n");
      then
        ();
  end matchcontinue;
end printAlgorithmitem;

public function printAlgorithm
"function: printAlgorithm
  Prints an Algorithm to the Print buffer."
  input Absyn.Algorithm inAlgorithm;
algorithm
  _:=
  matchcontinue (inAlgorithm)
    local
      Absyn.ComponentRef cr;
      Absyn.Exp exp,e1,e2,e, assignComp;
      list<Absyn.AlgorithmItem> tb,fb,el,al;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> eb;
      Absyn.ForIterators iterators;
      Ident i;
      Absyn.AlgorithmItem algItem;
      Absyn.ComponentRef cref;
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
    case Absyn.ALG_WHILE(boolExpr = e,whileBody = al)
      equation
        Print.printBuf("WHILE ");
        printExp(e);
        Print.printBuf(" {");
        printListDebug("print_algorithm", al, printAlgorithmitem, ";");
        Print.printBuf("}");
      then
        ();
    case Absyn.ALG_WHEN_A(boolExpr = e,whenBody = al,elseWhenAlgorithmBranch = el) 
      /* rule	Print.print_buf \"WHEN_E \" & print_exp(e) &
	       Print.print_buf \" {\" & print_list_debug(\"print_algorithm\",al, print_algorithmitem, \";\") & Print.print_buf \"}\"
	       ----------------------------------------------------------
	       print_algorithm Absyn.ALG_WHEN_E(e,al)
      */
      local list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> el;
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
    case Absyn.ALG_FAILURE(algItem)
      equation
        Print.printBuf("FAILURE(");
        printAlgorithmitem(algItem);
        Print.printBuf(")");
      then
        ();        
    case (_)
      equation
        Print.printBuf(" ** UNKNOWN ALGORITHM CLAUSE ** ");
      then
        ();
  end matchcontinue;
end printAlgorithm;

protected function unparseAlgorithmStrLst "function: unparseAlgorithmStrLst

  Prettyprints an AlgorithmItem list to a string.
"
  input Integer inInteger;
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input String inString;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger,inAbsynAlgorithmItemLst,inString)
    local
      Ident s1,s2,res,sep;
      Integer i;
      Absyn.AlgorithmItem x;
      list<Absyn.AlgorithmItem> xs;
    case (_,{},_) then "";
    case (i,(x :: xs),sep)
      equation
        s1 = unparseAlgorithmStr(i, x);
        s2 = unparseAlgorithmStrLst(i, xs, sep);
        res = Util.stringAppendList({s1,sep,s2});
      then
        res;
  end matchcontinue;
end unparseAlgorithmStrLst;

protected function unparseAlgorithmStrLstLst
  input Integer inInteger;
  input list<list<Absyn.AlgorithmItem>> inAbsynAlgorithmItemLst;
  input String inString;
  output list<String> outString;
algorithm
  outString:=
  matchcontinue (inInteger,inAbsynAlgorithmItemLst,inString)
    local
      Ident s1,sep;
      list<Ident> s2;
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

public function unparseAlgorithmStr "function: unparseAlgorithmStr

  Helper function to unparse_algorithm_str
"
  input Integer inInteger;
  input Absyn.AlgorithmItem inAlgorithmItem;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger,inAlgorithmItem)
    local
      Ident s1,s2,s3,is,str,s4,s5,str_1;
      Integer i,i_1,ident_1,ident;
      Absyn.ComponentRef cr;
      Absyn.Exp exp,e1,e2,e, assignComp;
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
        str = Util.stringAppendList({is,s1,":=",s2,s3,";"});
      then
        str;
    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_IF(ifExp = e,trueBranch = tb,elseIfAlgorithmBranch = eb,elseBranch = fb),comment = optcmt)) /* ALG_IF */
      equation
        s1 = printExpStr(e);
        i_1 = i + 1;
        s2 = unparseAlgorithmStrLst(i, tb, "\n");
        s3 = unparseAlgElseifStrLst(i_1, eb, "\n");
        s4 = unparseAlgorithmStrLst(i, fb, "\n");
        s5 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = Util.stringAppendList(
          {is,"if ",s1," then \n",is,s2,s3,"\n",is,"else ",s4,"\n",is,
          "end if",s5,";"});
      then
        str;
    case (ident,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_FOR(iterators=iterators,forBody = el),comment = optcmt)) /* ALG_FOR */
      local Ident i;
      equation
        ident_1 = ident + 1;
        s1 = printIteratorsStr(iterators);
        s2 = unparseAlgorithmStrLst(ident_1, el, "\n");
        s3 = unparseCommentOption(optcmt);
        is = indentStr(ident);
        str = Util.stringAppendList(
          {is,"for ",s1," loop\n",is,s2,"\n",is,"end for",s3,
          ";"});
      then
        str;
    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_WHILE(boolExpr = e,whileBody = al),comment = optcmt)) /* ALG_WHILE */
      equation
        s1 = printExpStr(e);
        i_1 = i + 1;
        s2 = unparseAlgorithmStrLst(i_1, al, "\n");
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = Util.stringAppendList(
          {is,"while (",s1,") loop\n",is,s2,"\n",is,"end while",s3,";"});
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
        str = Util.stringAppendList(
          {is,"when ",s1," then\n",is,s2,is,s4,"\n",is,"end when",s3,
          ";"});
      then
        str;
    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_NORETCALL(functionCall = cr,functionArgs = fargs),comment = optcmt)) /* ALG_NORETCALL */
      equation
        s1 = printComponentRefStr(cr);
        s2 = printFunctionArgsStr(fargs);
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = Util.stringAppendList({is,s1,"(",s2,")",s3,";"});
      then
        str;
    case (i,Absyn.ALGORITHMITEMANN(annotation_ = ann))
      equation
        str = unparseAnnotationOption(i, SOME(ann));
        str_1 = stringAppend(str, ";");
      then
        str_1;
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
    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_FAILURE(algItem),comment = optcmt)) /* ALG_FAILURE */
      equation
        s1 = unparseAlgorithmStr(0, algItem); 
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = is +& "failure(" +& s1 +& ")" +& s3 +& ";";
      then
        str;        
    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_MATCHCASES(explist), comment = optcmt))
      local
        list<Absyn.Exp> explist;
        list<String> strlist;
      equation
        s3 = unparseCommentOption(optcmt);
        strlist = Util.listMap(explist, printExpStr);
        strlist = Util.listMap1r(strlist, stringAppend, "\ncase:\n    ");
        s2 = Util.stringAppendList(strlist);
        str_1 = "matchcases { " +& s2 +& " } "+& s3 +&";";
      then
        str_1;
    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_TRY(al),comment = optcmt)) /* ALG_TRY */
      equation
        i_1 = i + 1;
        s2 = unparseAlgorithmStrLst(i_1, al, "\n");
        s3 = unparseCommentOption(optcmt);
        is = indentStr(i);
        str = Util.stringAppendList(
          {is,"try\n",is,s2,is,"end try",s3,";"});
      then
        str;
    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_THROW,comment = optcmt)) /* ALG_THROW */
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
        str = Util.stringAppendList(
          {is,"catch\n",is,s2,is,"end catch",s3,";"});
      then
        str;
    case (_,_)
      equation
        Print.printErrorBuf("#Error, unparse_algorithm_str failed\n");
      then
        "";
  end matchcontinue;
end unparseAlgorithmStr;

protected function unparseAlgElsewhenStrLst "function: unparseAlgElsewhenStrLst

  Unparses an elsewhen branch in an algorithm to a string.
"
  input Integer inInteger;
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger,inTplAbsynExpAbsynAlgorithmItemLstLst)
    local
      Ident res,s1,s2;
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
        res = Util.stringAppendList({s1,"\n",s2});
      then
        res;
    case (i,(x :: (xs as (_ :: _))))
      equation
        s1 = unparseAlgElsewhenStr(i, x);
        s2 = unparseAlgElsewhenStrLst(i, xs);
        res = Util.stringAppendList({s1,"\n",s2});
      then
        res;
  end matchcontinue;
end unparseAlgElsewhenStrLst;

protected function unparseAlgElsewhenStr "function: unparseAlgElsewhenStr

  Helper function to unparse_alg_elsewhen_str_lst
"
  input Integer inInteger;
  input tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> inTplAbsynExpAbsynAlgorithmItemLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger,inTplAbsynExpAbsynAlgorithmItemLst)
    local
      Ident is,s1,s2,res;
      Integer i;
      Absyn.Exp exp;
      list<Absyn.AlgorithmItem> algl;
    case (i,(exp,algl))
      equation
        is = indentStr(i);
        s1 = unparseAlgorithmStrLst(i, algl, "\n");
        s2 = printExpStr(exp);
        res = Util.stringAppendList({"elsewhen ",s2," then\n",s1});
      then
        res;
  end matchcontinue;
end unparseAlgElsewhenStr;

protected function unparseEqElsewhenStrLst "function: unparseEqElsewhenStrLst

  Prettyprints an equation elsewhen branch to a string.
"
  input Integer inInteger;
  input list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> inTplAbsynExpAbsynEquationItemLstLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger,inTplAbsynExpAbsynEquationItemLstLst)
    local
      Ident res,s1,s2;
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
        res = Util.stringAppendList({s1,"\n",s2});
      then
        res;
    case (i,(x :: xs))
      equation
        s1 = unparseEqElsewhenStr(i, x);
        s2 = unparseEqElsewhenStrLst(i, xs);
        res = Util.stringAppendList({s1,"\n",s2});
      then
        res;
  end matchcontinue;
end unparseEqElsewhenStrLst;

protected function unparseEqElsewhenStr "function: unparseEqElsewhenStr

  Helper function to unparse_eq_elsewhen_str_lst
"
  input Integer inInteger;
  input tuple<Absyn.Exp, list<Absyn.EquationItem>> inTplAbsynExpAbsynEquationItemLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger,inTplAbsynExpAbsynEquationItemLst)
    local
      Ident is,s1,s2,res;
      Integer i;
      Absyn.Exp exp;
      list<Absyn.EquationItem> eql;
    case (i,(exp,eql))
      equation
        is = indentStr(i);
        s1 = unparseEquationitemStrLst(i, eql, ";\n");
        s2 = printExpStr(exp);
        res = Util.stringAppendList({"elsewhen ",s2," then\n",s1});
      then
        res;
  end matchcontinue;
end unparseEqElsewhenStr;

protected function printAlgElseif "function: printAlgElseif

  Prints an algorithm elseif branch to the Print buffer.
"
  input tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> inTplAbsynExpAbsynAlgorithmItemLst;
algorithm
  _:=
  matchcontinue (inTplAbsynExpAbsynAlgorithmItemLst)
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
  end matchcontinue;
end printAlgElseif;

protected function unparseAlgElseifStrLst "function: unparseAlgElseifStrLst

  Prettyprints an algorithm elseif branch to a string.
"
  input Integer inInteger;
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  input String inString;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger,inTplAbsynExpAbsynAlgorithmItemLstLst,inString)
    local
      Ident s2,s1,res,sep;
      Integer i;
      tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> x;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> xs;
    case (_,{},_) then "";
    case (i,(x :: xs),sep)
      equation
        s2 = unparseAlgElseifStrLst(i, xs, sep);
        s1 = unparseAlgElseifStr(i, x);
        res = Util.stringAppendList({s1,sep,s2});
      then
        res;
  end matchcontinue;
end unparseAlgElseifStrLst;

protected function unparseAlgElseifStr "function: unparseAlgElseifStr

  Helper function to unparse_alg_elseif_str_lst
"
  input Integer inInteger;
  input tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> inTplAbsynExpAbsynAlgorithmItemLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger,inTplAbsynExpAbsynAlgorithmItemLst)
    local
      Ident s1,s2,is,str;
      Integer i_1,i;
      Absyn.Exp e;
      list<Absyn.AlgorithmItem> el;
    case (i,(e,el))
      equation
        s1 = printExpStr(e);
        s2 = unparseAlgorithmStrLst(i, el, "\n");
        i_1 = i - 1;
        is = indentStr(i_1);
        str = Util.stringAppendList({is,"elseif ",s1," then\n",s2});
      then
        str;
  end matchcontinue;
end unparseAlgElseifStr;

public function printComponentRef "Component references and paths
  function: printComponentRef

  Print a `ComponentRef\' to the Print buffer.
"
  input Absyn.ComponentRef inComponentRef;
algorithm
  _:=
  matchcontinue (inComponentRef)
    local
      Ident s;
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
    case Absyn.CREF_QUAL(name = s,subScripts = subs,componentRef = cr)
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
    /* MetaModelica wildcard */
    case Absyn.WILD()
      equation
        Print.printBuf("Absyn.WILD");
      then
        ();
  end matchcontinue;
end printComponentRef;

public function printSubscripts "function: printSubscripts

  Prints a Subscript to the Print buffer.
"
  input list<Absyn.Subscript> inAbsynSubscriptLst;
algorithm
  _:=
  matchcontinue (inAbsynSubscriptLst)
    local list<Absyn.Subscript> l;
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

public function printComponentRefStr "function: printComponentRefStr

  Print a `ComponentRef\' and return as a string.
"
  input Absyn.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef)
    local
      Ident subsstr,s_1,s,crs,s_2,s_3;
      list<Absyn.Subscript> subs;
      Absyn.ComponentRef cr;
    case Absyn.CREF_IDENT(name = s,subscripts = subs)
      equation
        subsstr = printSubscriptsStr(subs);
        s_1 = stringAppend(s, subsstr);
      then
        s_1;
    case Absyn.CREF_QUAL(name = s,subScripts = subs,componentRef = cr)
      equation
        crs = printComponentRefStr(cr);
        subsstr = printSubscriptsStr(subs);
        s_1 = stringAppend(s, subsstr);
        s_2 = stringAppend(s_1, ".");
        s_3 = stringAppend(s_2, crs);
      then
        s_3;
    case Absyn.WILD() then "_";
  end matchcontinue;
end printComponentRefStr;

public function printSubscriptsStr "function: printSubscriptsStr

  Prettyprint a Subscript list to a string.
"
  input list<Absyn.Subscript> inAbsynSubscriptLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynSubscriptLst)
    local
      Ident s,s_1,s_2;
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

public function printPath "function: printPath

  Print a `Path\'.
"
  input Absyn.Path p;
  Ident s;
algorithm
  s := Absyn.pathString(p);
  Print.printBuf(s);
end printPath;

protected function dumpPath "function: dumpPath

  Dumps path to the Print buffer
"
  input Absyn.Path inPath;
algorithm
  _:=
  matchcontinue (inPath)
    local
      Ident str;
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
  end matchcontinue;
end dumpPath;

protected function printPathStr "function: print_path

  Print a `Path\'.
"
  input Absyn.Path p;
  output String s;
algorithm
  s := Absyn.pathString(p);
end printPathStr;

public function printExp "- Expressions
  function: printExp

  This function prints a complete expression to the Print buffer.
"
  input Absyn.Exp inExp;
algorithm
  _:=
  matchcontinue (inExp)
    local
      Ident s,sym;
      Integer x;
      Absyn.ComponentRef c,fcn;
      Absyn.Exp e1,e2,e,t,f,start,stop,step;
      Absyn.Operator op;
      list<tuple<Absyn.Exp, Absyn.Exp>> lst;
      Absyn.FunctionArgs args;
      list<Absyn.Exp> es;
      Absyn.MatchType matchType;
      Absyn.Exp head, rest;
      Absyn.Exp inputExp;
      list<Absyn.ElementItem> localDecls;
      list<Absyn.Case> cases;
      Option<String> comment;
    case (Absyn.INTEGER(value = x))
      equation
        s = intString(x);
        Print.printBuf("Absyn.INTEGER(");
        Print.printBuf(s);
        Print.printBuf(")");
      then
        ();
    case (Absyn.REAL(value = x))
      local Real x;
      equation
        s = realString(x);
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
    case (Absyn.IFEXP(ifExp = c,trueBranch = t,elseBranch = f,elseIfBranch = lst))
      local Absyn.Exp c;
      equation
        Print.printBuf("Absyn.IFEXP(");
        printExp(c);
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
    case Absyn.MATRIX(matrix = es)
      local list<list<Absyn.Exp>> es;
      equation
        Print.printBuf("Absyn.MATRIX([");
        printListDebug("print_exp", es, printRow, ";");
        Print.printBuf("])");
      then
        ();
    case Absyn.RANGE(start = start,step = NONE,stop = stop)
      equation
        Print.printBuf("Absyn.RANGE(");
        printExp(start);
        Print.printBuf(",NONE,");
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

    /* MetaModelica expressions! */
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
  out := matchcontinue matchType
    case Absyn.MATCH() then "match";
    case Absyn.MATCHCONTINUE() then "matchcontinue";
  end matchcontinue;
end printMatchType;

public function printCase "
MetaModelica construct printing
@author Adrian Pop "
  input Absyn.Case cas;
algorithm
  _ := matchcontinue cas
    local
      Absyn.Exp p;
      list<Absyn.ElementItem> l;
      list<Absyn.EquationItem> e;
      Absyn.Exp r;
      Option<String> c;
    case Absyn.CASE(p, l, e, r, c)
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
    case Absyn.ELSE(l, e, r, c)
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
  end matchcontinue;
end printCase;

protected function printFunctionArgs "function: printFunctionArgs

  Prints FunctionArgs to Print buffer.
"
  input Absyn.FunctionArgs inFunctionArgs;
algorithm
  _:=
  matchcontinue (inFunctionArgs)
    local
      list<Absyn.Exp> expargs;
      list<Absyn.NamedArg> nargs;
      Absyn.Exp exp;
      Ident id;
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
  end matchcontinue;
end printFunctionArgs;

function printIterator
" @author adrpo
  prints iterator: (i,exp1)"
  input Absyn.ForIterator iterator;
algorithm
  _ := matchcontinue(iterator)
    local
      String s, s1, s2, s3;
      Absyn.Exp exp;
      Absyn.Ident id;
      list<tuple<Absyn.Ident, Absyn.Exp>> rest;
    case ((id, SOME(exp)))
      equation
        Print.printBuf("(");
        Print.printBuf(id);
        Print.printBuf(", ");
        printExp(exp);
        Print.printBuf(")");
      then ();
    case ((id, NONE))
      equation
        Print.printBuf("(");
        Print.printBuf(id);
        Print.printBuf(")");
      then ();
  end matchcontinue;
end printIterator;


public function printFunctionArgsStr "function: printFunctionArgsStr

  Prettyprint FunctionArgs to a string.
"
  input Absyn.FunctionArgs inFunctionArgs;
  output String outString;
algorithm
  outString:=
  matchcontinue (inFunctionArgs)
    local
      Ident s1,s2,s3,str,estr,istr,id;
      list<Absyn.Exp> expargs;
      list<Absyn.NamedArg> nargs;
      Absyn.Exp exp,iterexp;
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
        str = Util.stringAppendList({estr," for ", istr});
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
      String s, s1, s2, s3;
      Absyn.Exp exp;
      Absyn.Ident id;
      Absyn.ForIterators rest;
      Absyn.ForIterator x;
    case ({}) then "";
    case ({(id, SOME(exp))})
      equation
        s1 = printExpStr(exp);
        s = Util.stringAppendList({id, " in ", s1});
      then s;
    case ({(id, NONE())}) then id;
    case (x::rest)
      equation
        s1 = printIteratorsStr({x});
        s2 = printIteratorsStr(rest);
        s = Util.stringAppendList({s1, ", ", s2});
      then s;
  end matchcontinue;
end printIteratorsStr;

public function printNamedArg
"function: printNamedArg
  Print NamedArg to the Print buffer."
  input Absyn.NamedArg inNamedArg;
algorithm
  _:=
  matchcontinue (inNamedArg)
    local
      Ident ident;
      Absyn.Exp e;
    case Absyn.NAMEDARG(argName = ident,argValue = e)
      equation
        Print.printBuf(ident);
        Print.printBuf(" = ");
        printExp(e);
      then
        ();
  end matchcontinue;
end printNamedArg;

public function printNamedArgStr 
"function: printNamedArgStr
  Prettyprint NamedArg to a string."
  input Absyn.NamedArg inNamedArg;
  output String outString;
algorithm
  outString:=
  matchcontinue (inNamedArg)
    local
      Ident s1,s2,str,ident;
      Absyn.Exp e;
    case Absyn.NAMEDARG(argName = ident,argValue = e)
      equation
        s1 = stringAppend(ident, " = ");
        s2 = printExpStr(e);
        str = stringAppend(s1, s2);
      then
        str;
  end matchcontinue;
end printNamedArgStr;


protected function printRow "function: printRow

  Print an Expression list to the Print buffer.
"
  input list<Absyn.Exp> es;
algorithm
  printListDebug("print_row", es, printExp, ",");
end printRow;


protected function expPriority "function: expPriority

 Returns a priority number for an expression.
 This function is used to output parenthesis when needed, e.g., 3(1+2) should output 3(1+2)
 and not 31+2.
"
  input Absyn.Exp inExp;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inExp)
    case (Absyn.INTEGER(value = _)) then 0;
    case (Absyn.REAL(value = _)) then 0;
    case (Absyn.STRING(value = _)) then 0;
    case (Absyn.BOOL(value = _)) then 0;
    case (Absyn.CREF(componentRef = _)) then 0;
    case (Absyn.END()) then 0;
    case (Absyn.CALL(function_ = _)) then 0;
    case (Absyn.PARTEVALFUNCTION(function_= _)) then 0;
    case (Absyn.ARRAY(arrayExp = _)) then 0;
    case (Absyn.MATRIX(matrix = _)) then 0;
    /* arithmetic operators */
    case (Absyn.BINARY(op = Absyn.POW())) then 1;      
    case (Absyn.BINARY(op = Absyn.DIV())) then 2;
    case (Absyn.BINARY(op = Absyn.MUL())) then 3;      
    case (Absyn.UNARY(op = Absyn.UPLUS())) then 4;
    case (Absyn.UNARY(op = Absyn.UMINUS())) then 4;
    case (Absyn.BINARY(op = Absyn.ADD())) then 5;
    case (Absyn.BINARY(op = Absyn.SUB())) then 5;
    /* the new arithmetic operators element-wise from Modelica 3.0  */
    case (Absyn.BINARY(op = Absyn.POW_EW())) then 1;      
    case (Absyn.BINARY(op = Absyn.DIV_EW())) then 2;
    case (Absyn.BINARY(op = Absyn.MUL_EW())) then 3;
    case (Absyn.UNARY(op = Absyn.UPLUS_EW())) then 4;
    case (Absyn.UNARY(op = Absyn.UMINUS_EW())) then 4;           
    case (Absyn.BINARY(op = Absyn.ADD_EW())) then 5;
    case (Absyn.BINARY(op = Absyn.SUB_EW())) then 5;
    /* relational operators */    
    case (Absyn.RELATION(op = Absyn.LESS())) then 6;
    case (Absyn.RELATION(op = Absyn.LESSEQ())) then 6;
    case (Absyn.RELATION(op = Absyn.GREATER())) then 6;
    case (Absyn.RELATION(op = Absyn.GREATEREQ())) then 6;
    case (Absyn.RELATION(op = Absyn.EQUAL())) then 6;
    case (Absyn.RELATION(op = Absyn.NEQUAL())) then 6;
    /* logical operatos */
    case (Absyn.LUNARY(op = Absyn.NOT())) then 7;
    case (Absyn.LBINARY(op = Absyn.AND())) then 8;
    case (Absyn.LBINARY(op = Absyn.OR())) then 9;
    case (Absyn.RANGE(start = _)) then 10;
    case (Absyn.IFEXP(ifExp = _)) then 11;
    case (Absyn.TUPLE(expressions = _)) then 12;  /* Not valid in inner expressions, only included here for completeness */
    case (_) then 13;
  end matchcontinue;
end expPriority;

protected function parenthesize 
"function: parenthesize
  Adds parentheisis to a string if expression 
  and parent expression priorities requires it."
  input String inString1;
  input Integer inInteger2;
  input Integer inInteger3;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inInteger2,inInteger3)
    local
      Ident str_1,str;
      Integer pparent,pexpr;
    case (str,pparent,pexpr) /* expr, prio. parent expr, prio. expr */
      equation
        (pparent > pexpr) = true;
        str_1 = Util.stringAppendList({"(",str,")"});
      then
        str_1;
    case (str,_,_) then str;
  end matchcontinue;
end parenthesize;

public function printExpLstStr "exp
 
Prints a list of expressions to a string
"
  input list<Absyn.Exp> expl;
  output String outString;
algorithm 
  outString := Util.stringDelimitList(Util.listMap(expl,printExpStr),", ");
end printExpLstStr;

public function printExpStr "function: print_exp

  This function prints a complete expression.
"
  input Absyn.Exp inExp;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExp)
    local
      String s,s_1,s_2,s_3,sym,s1,s2,s1_1,s2_1,cs,ts,fs,cs_1,ts_1,fs_1,el,str,argsstr,s3,s3_1,res,res_1;
      String s4, s5, s6;
      Integer x,p,p1,p2,pc,pt,pf,pstart,pstop,pstep;
      Absyn.ComponentRef c,fcn;
      Boolean b;
      Absyn.Exp e,e1,e2,t,f,start,stop,step;
      Absyn.Operator op;
      list<tuple<Absyn.Exp, Absyn.Exp>> elseif_;
      Absyn.FunctionArgs args;
      list<Absyn.Exp> es;
      Absyn.MatchType matchType;
      Absyn.Exp head, rest;
      Absyn.Exp inputExp;
      list<Absyn.ElementItem> localDecls;
      list<Absyn.Case> cases;
      Option<String> comment;
    case (Absyn.INTEGER(value = x))
      equation
        s = intString(x);
      then
        s;
    case (Absyn.REAL(value = x))
      local Real x;
      equation
        s = realString(x);
      then
        s;
    case (Absyn.CREF(componentRef = c))
      equation
        s = printComponentRefStr(c);
      then
        s;
    case (Absyn.STRING(value = s))
      equation
        s_1 = stringAppend("\"", s);
        s_2 = stringAppend(s_1, "\"");
      then
        s_2;
    case (Absyn.BOOL(value = b))
      equation
        s = printBoolStr(b);
      then
        s;
    case ((e as Absyn.BINARY(exp1 = e1,op = op,exp2 = e2)))
      equation
        sym = opSymbol(op);
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        p = expPriority(e);
        p1 = expPriority(e1);
        p2 = expPriority(e2);
        s1_1 = parenthesize(s1, p1, p);
        s2_1 = parenthesize(s2, p2, p);
        s = stringAppend(s1_1, sym);
        s_1 = stringAppend(s, s2_1);
      then
        s_1;
    case ((e as Absyn.UNARY(op = op,exp = e1)))
      equation
        sym = opSymbol(op);
        s = printExpStr(e1);
        p = expPriority(e);
        p1 = expPriority(e1);
        s_1 = parenthesize(s, p1, p);
        s_2 = stringAppend(sym, s_1);
      then
        s_2;
    case ((e as Absyn.LBINARY(exp1 = e1,op = op,exp2 = e2)))
      equation
        sym = opSymbol(op);
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        p = expPriority(e);
        p1 = expPriority(e1);
        p2 = expPriority(e2);
        s1_1 = parenthesize(s1, p1, p);
        s2_1 = parenthesize(s2, p2, p);
        s = stringAppend(s1_1, sym);
        s_1 = stringAppend(s, s2_1);
      then
        s_1;
    case ((e as Absyn.LUNARY(op = op,exp = e1)))
      equation
        sym = opSymbol(op);
        s = printExpStr(e1);
        p = expPriority(e);
        p1 = expPriority(e1);
        s_1 = parenthesize(s, p1, p);
        s_2 = stringAppend(sym, s_1);
      then
        s_2;
    case ((e as Absyn.RELATION(exp1 = e1,op = op,exp2 = e2)))
      equation
        sym = opSymbol(op);
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        p = expPriority(e);
        p1 = expPriority(e1);
        p2 = expPriority(e2);
        s1_1 = parenthesize(s1, p1, p);
        s2_1 = parenthesize(s2, p1, p);
        s = stringAppend(s1_1, sym);
        s_1 = stringAppend(s, s2_1);
      then
        s_1;
    case ((e as Absyn.IFEXP(ifExp = c,trueBranch = t,elseBranch = f,elseIfBranch = elseif_)))
      local Absyn.Exp c;
      equation
        cs = printExpStr(c);
        ts = printExpStr(t);
        fs = printExpStr(f);
        p = expPriority(e);
        pc = expPriority(c);
        pt = expPriority(t);
        pf = expPriority(f);
        cs_1 = parenthesize(cs, pc, p);
        ts_1 = parenthesize(ts, pt, p);
        fs_1 = parenthesize(fs, pf, p);
        el = printElseifStr(elseif_);
        str = Util.stringAppendList({"if ",cs_1," then ",ts_1,el," else ",fs_1});
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
    case Absyn.TUPLE(expressions = es)
      equation
        s = printListStr(es, printExpStr, ",") "Does not need parentheses" ;
        s_1 = stringAppend("(", s);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;
    case Absyn.MATRIX(matrix = es)
      local list<list<Absyn.Exp>> es;
      equation
        s = printListStr(es, printRowStr, ";") "Does not need parentheses" ;
        s_1 = stringAppend("[", s);
        s_2 = stringAppend(s_1, "]");
      then
        s_2;
    case ((e as Absyn.RANGE(start = start,step = NONE,stop = stop)))
      equation
        s1 = printExpStr(start);
        s3 = printExpStr(stop);
        p = expPriority(e);
        pstart = expPriority(start);
        pstop = expPriority(stop);
        s1_1 = parenthesize(s1, pstart, p);
        s3_1 = parenthesize(s3, pstop, p);
        s = Util.stringAppendList({s1_1,":",s3_1});
      then
        s;
    case ((e as Absyn.RANGE(start = start,step = SOME(step),stop = stop)))
      equation
        s1 = printExpStr(start);
        s2 = printExpStr(step);
        s3 = printExpStr(stop);
        p = expPriority(e);
        pstart = expPriority(start);
        pstop = expPriority(stop);
        pstep = expPriority(step);
        s1_1 = parenthesize(s1, pstart, p);
        s3_1 = parenthesize(s3, pstop, p);
        s2_1 = parenthesize(s2, pstep, p);
        s = Util.stringAppendList({s1_1,":",s2_1,":",s3_1});
      then
        s;
    case (Absyn.CODE(code = c))
      local Absyn.CodeNode c;
      equation
        res = printCodeStr(c);
        res_1 = Util.stringAppendList({"Code(",res,")"});
      then
        res_1;
    case Absyn.END() then "end";

    /* MetaModelica expressions */
    case Absyn.CONS(head, rest)
      equation
        s1 = printExpStr(head);
        s2 = printExpStr(rest);
        s = Util.stringAppendList({s1, "::", s2});
      then
        s;
    case Absyn.AS(s1, rest)
      equation
        s2 = printExpStr(rest);
        s = Util.stringAppendList({s1, " as ", s2});
      then
        s;
    case Absyn.MATCHEXP(matchType, inputExp, localDecls, cases, comment)
      equation
        s1 = printMatchType(matchType);
        s2 = printExpStr(inputExp);
        s3 = unparseStringCommentOption(comment);
        s4 = unparseLocalElements(3, localDecls);
        s5 = getStringList(cases, printCaseStr, "\n");
        s = Util.stringAppendList({s1, " ", s2, s3, s4, s5, "\n\tend ", s1});
      then
        s;
    case Absyn.VALUEBLOCK(els,_ /*Absyn.VALUEBLOCKALGORITHMS(algs)*/,result)
    local Absyn.Exp result; list<Absyn.ElementItem> els; list<Absyn.AlgorithmItem> algs;
      equation
        s1 = printExpStr(result);
        s = "valueblock(...)";
        /*
        s2 = Print.getString();
        Print.clearBuf();
        printElementitems(els);
        Util.listMap0(algs, printAlgorithmitem);
        s3 = Print.getString();
        Print.printBuf(s2);
        s = "valueblock(" +& s3 +& ", result=" +& s1 +& ")";
        */
      then s;
    case (_) then "#UNKNOWN EXPRESSION#";
  end matchcontinue;
end printExpStr;

function unparseLocalElements
"function: unparseLocalElements
  @author: adrpo
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
"function: unparseLocalElements
  @author: adrpo
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
        s = unparseEquationitemStrLst(i, eq, ";\n");
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
      String s1, s2, s3, s4, s;
      Absyn.Exp p;
      list<Absyn.ElementItem> l;
      list<Absyn.EquationItem> eq;
      Absyn.Exp r;
      Option<String> c;
    case Absyn.CASE(p, {}, {}, r, c)
      equation
        s1 = printExpStr(p);
        s4 = printExpStr(r);
        s = Util.stringAppendList({"\tcase (", s1, ") then ", s4, ";"});
      then s;            
    case Absyn.CASE(p, l, eq, r, c)
      equation
        s1 = printExpStr(p);
        s2 = unparseLocalElements(3, l);
        s3 = unparseLocalEquations(3, eq);
        s4 = printExpStr(r);
        s = Util.stringAppendList({"\tcase (", s1, ")", s2, s3, "\t  then ", s4, ";"});
      then s;
    case Absyn.ELSE({}, {}, r, c)
      equation
        s4 = printExpStr(r);
        s = Util.stringAppendList({"\telse then ", s4, ";"});
      then s;            
    case Absyn.ELSE(l, eq, r, c)
      equation
        s2 = unparseLocalElements(3, l);
        s3 = unparseLocalEquations(3, eq);
        s4 = printExpStr(r);
        s = Util.stringAppendList({"\telse", s2, s3, "\t  then ", s4, ";"});
      then s;
  end matchcontinue;
end printCaseStr;

public function printCodeStr 
"function: printCodeStr
  Prettyprint Code to a string."
  input Absyn.CodeNode inCode;
  output String outString;
algorithm
  outString := matchcontinue (inCode)
    local
      Ident s,s1,s2,res;
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
        s2 = unparseEquationitemStrLst(1, eqitems, ";\n");
        res = Util.stringAppendList({s1,"equation ",s2});
      then
        res;
    case (Absyn.C_ALGORITHMSECTION(boolean = b,algorithmItemLst = algitems))
      equation
        s1 = selectString(b, "initial ", "");
        s2 = unparseAlgorithmStrLst(1, algitems, ";\n");
        res = Util.stringAppendList({s1,"algorithm ",s2});
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
  end matchcontinue;
end printCodeStr;

protected function printElseifStr 
"function: printEleseifStr
  Prettyprint elseif to a string"
  input list<tuple<Absyn.Exp, Absyn.Exp>> inTplAbsynExpAbsynExpLst;
  output String outString;
algorithm
  outString := matchcontinue (inTplAbsynExpAbsynExpLst)
    local
      Ident s1,s2,s3,str;
      Absyn.Exp ec,ee;
      list<tuple<Absyn.Exp, Absyn.Exp>> rest;
    case ({}) then "";
    case (((ec,ee) :: rest))
      equation
        s1 = printExpStr(ec);
        s2 = printExpStr(ee);
        s3 = printElseifStr(rest);
        str = Util.stringAppendList({" elseif ",s1," then ",s2,s3});
      then
        str;
  end matchcontinue;
end printElseifStr;

protected function printRowStr 
"function: printRowStr
  Prettyprint a list of expressions to a string."
  input list<Absyn.Exp> es;
  output String s;
algorithm
  s := printListStr(es, printExpStr, ",");
end printRowStr;

protected function printListStr 
"function: printListStr
  Same as printList, except it returns a string instead of printing"
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
      Ident s,srest,s_1,s_2,sep;
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
"function: opSymbol
  Make a string describing different operators."
  input Absyn.Operator inOperator;
  output String outString;
algorithm
  outString := matchcontinue (inOperator)
    /* arithmetic operators */
    case (Absyn.ADD()) then " + ";
    case (Absyn.SUB()) then " - ";
    case (Absyn.MUL()) then " * ";
    case (Absyn.DIV()) then " / ";
    case (Absyn.POW()) then " ^ ";
    case (Absyn.UMINUS()) then " -";
    case (Absyn.UPLUS()) then " +";
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
  end matchcontinue;
end opSymbol;

protected function dumpOpSymbol 
"function: dumpOpSymbol
  Make a string describing different operators."
  input Absyn.Operator inOperator;
  output String outString;
algorithm
  outString := matchcontinue (inOperator)
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
  end matchcontinue;
end dumpOpSymbol;

/*
 *
 * Utility functions
 * These are utility functions used in some of the other functions.
 *
 */

public function selectString 
"function: selectString
  Select one of the two strings depending on boolean value."
  input Boolean inBoolean1;
  input String inString2;
  input String inString3;
  output String outString;
algorithm
  outString:=
  matchcontinue (inBoolean1,inString2,inString3)
    local Ident a,b;
    case (true,a,b) then a;
    case (false,a,b) then b;
  end matchcontinue;
end selectString;

public function printSelect "function: printSelect

  Select one of the two string depending on boolean value
  and print it on the Print buffer.
"
  input Boolean f;
  input String yes;
  input String no;
  Ident res;
algorithm
  res := selectString(f, yes, no);
  Print.printBuf(res);
end printSelect;

public function printOption "function: printOption

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
  matchcontinue (inTypeAOption,inFuncTypeTypeATo)
    local
      Type_a x;
      FuncTypeType_aTo r;
    case (NONE,_)
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
  end matchcontinue;
end printOption;

public function printListDebug "function: printListDebug

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
  _:=
  matchcontinue (inString1,inTypeALst2,inFuncTypeTypeATo3,inString4)
    local
      Ident caller,s1,sep;
      Type_a h;
      FuncTypeType_aTo r;
      list<Type_a> rest;
    case (_,{},_,_)
      equation
        Debug.fprintln("dumptr", "print_list_debug-1");
      then
        ();
    case (caller,{h},r,_)
      equation
        Debug.fprintl("dumptr", {"print_list_debug-2 from ",caller,"\n"});
        r(h);
        Debug.fprintln("dumptr", "//print_list_debug-2");
      then
        ();
    case (caller,(h :: rest),r,sep)
      equation
        s1 = stringAppend("print_list_debug-3 from ", caller);
        Debug.fprintl("dumptr", {s1,"\n"});
        r(h);
        Print.printBuf(sep);
        Debug.fprintln("dumptr", "//print_list_debug-3");
        printListDebug(s1, rest, r, sep);
      then
        ();
  end matchcontinue;
end printListDebug;

public function printList "function: printList

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
      Ident sep;
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

public function getStringList "function getStringList

  Append strings from a list of values output with a function converting
  a value to a string.
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
      Ident s,s_1,srest,s_2,sep;
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

public function printBool "function: printBool

  Print a bool value to the Print buffer
"
  input Boolean b;
algorithm
  printSelect(b, "true", "false");
end printBool;

public function getOptionStr "function getOptionStr

  Retrieve the string from a string option.
  If NONE return empty string.
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
  matchcontinue (inTypeAOption,inFuncTypeTypeAToString)
    local
      Ident str;
      Type_a a;
      FuncTypeType_aToString r;
    case (SOME(a),r)
      equation
        str = r(a);
      then
        str;
    case (NONE,_) then "";
  end matchcontinue;
end getOptionStr;

public function getOptionStrDefault "function getOptionStrDefault

  Retrieve the string from a string option.
  If NONE return default string.
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
      Ident str,def;
      Type_a a;
      FuncTypeType_aToString r;
    case (SOME(a),r,_)
      equation
        str = r(a);
      then
        str;
    case (NONE,_,def) then def;
  end matchcontinue;
end getOptionStrDefault;

public function getOptionWithConcatStr "function: getOptionWithConcatStr

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
  matchcontinue (inTypeAOption,inFuncTypeTypeAToString,inString)
    local
      Ident str,str_1,default_str;
      Type_a a;
      FuncTypeType_aToString r;
    case (SOME(a),r,default_str) /* suffix */
      equation
        str = r(a);
        str_1 = stringAppend(default_str, str);
      then
        str_1;
    case (NONE,_,default_str) then "";
  end matchcontinue;
end getOptionWithConcatStr;

protected function unparseStringCommentOption "function: unparseStringCommentOption

  Prettyprint a string comment option, which is a string option.
"
  input Option<String> inStringOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inStringOption)
    local Ident str,s;
    case (NONE) then "";
    case (SOME(s))
      equation
        str = Util.stringAppendList({" \"",s,"\""});
      then
        str;
  end matchcontinue;
end unparseStringCommentOption;

protected function printStringCommentOption "function: printStringCommentOption

  Print a string comment option on the Print buffer
"
  input Option<String> inStringOption;
algorithm
  _:=
  matchcontinue (inStringOption)
    local Ident str,s;
    case (NONE)
      equation
        Print.printBuf("NONE()");
      then
        ();
    case (SOME(s))
      equation
        str = Util.stringAppendList({"SOME(\"",s,"\")"});
        Print.printBuf(str);
      then
        ();
  end matchcontinue;
end printStringCommentOption;

protected function identity "function: identity

  The identity function.
"
  input Type_a inTypeA;
  output Type_a outTypeA;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeA:=
  matchcontinue (inTypeA)
    local Type_a x;
    case (x) then x;
  end matchcontinue;
end identity;

public function printBoolStr "function: printBoolStr

 Prints a bool to a string.
"
  input Boolean b;
  output String s;
algorithm
  s := selectString(b, "true", "false");
end printBoolStr;

public function indentStr "function: indentStr

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
      Ident s1,res;
    case (0) then "";
    case (i)
      equation
        i_1 = i - 1;
        s1 = indentStr(i_1);
        res = stringAppend(s1, "  ") "Indent using two whitespaces" ;
      then
        res;
  end matchcontinue;
end indentStr;

public function unparseTypeSpec "adrpo added metamodelica stuff"
  input Absyn.TypeSpec inTypeSpec;
  output String outString;
algorithm
  outString:=
  matchcontinue (inTypeSpec)
    local
      Ident str,s,str1,str2,str3;
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
        str3 = Util.stringAppendList({str1,"<",str2,">"});
        s = getOptionStr(adim, printArraydimStr);
        str = stringAppend(str3, s);
      then
        str;
  end matchcontinue;
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
        str3 = Util.stringAppendList({str1,", ",str2});
      then
        str3;
  end matchcontinue;
end unparseTypeSpecLst;

public function printTypeSpec
  input Absyn.TypeSpec typeSpec;
  Ident str;
algorithm
  str := unparseTypeSpec(typeSpec);
  print(str);
end printTypeSpec;

public function stdout "function: stdout

  Prints the text sent to the print buffer (Print.mo) to stdout (i.e.
  using MetaModelica Compiler (MMC) standard print). After printing, the print buffer is cleared.
"
  Ident str;
algorithm
  str := Print.getString();
  print(str);
  Print.clearBuf();
end stdout;

public function getAstAsCorbaString
  input Absyn.Program program;
  output String outStr;
algorithm
  outStr := matchcontinue program
    local
      list<Absyn.Class> classes;
      Absyn.Within within_;
      Absyn.TimeStamp globalBuildTimes;
      String old;
    case Absyn.PROGRAM(classes = classes, within_ = within_, globalBuildTimes = globalBuildTimes)
      equation
        old = Print.getString();
        Print.clearBuf();
        Print.printBuf("record Absyn.PROGRAM\nclasses = ");
        printListAsCorbaString(classes,printClassAsCorbaString,",\n");
        Print.printBuf(",\nwithin_ = ");
        printWithinAsCorbaString(within_);
        Print.printBuf(",\nglobalBuildTimes = ");
        printTimeStampAsCorbaString(globalBuildTimes);
        Print.printBuf("\nend Absyn.PROGRAM;");
        outStr = Print.getString();
        Print.clearBuf();
        Print.printBuf(old);
      then outStr;
  end matchcontinue;
end getAstAsCorbaString;

protected function printPathAsCorbaString
  input Absyn.Path inPath;
algorithm
  _ := matchcontinue inPath
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
  end matchcontinue;
end printPathAsCorbaString;


protected function printComponentRefAsCorbaString
  input Absyn.ComponentRef cref;
algorithm
  _ := matchcontinue cref
    local
      String s;
      Absyn.ComponentRef p;
      list<Absyn.Subscript> subscripts;
    case Absyn.CREF_QUAL(name = s, subScripts = subscripts, componentRef = p)
      equation
        Print.printBuf("record Absyn.QUALIFIED name = \"");
        Print.printBuf(s);
        Print.printBuf("\", subScripts = ");
        printListAsCorbaString(subscripts, printSubscriptAsCorbaString, ",");
        Print.printBuf(", componentRef = ");
        printComponentRefAsCorbaString(p);
        Print.printBuf(" end Absyn.QUALIFIED;");        
      then ();
    case Absyn.CREF_IDENT(name = s, subscripts = subscripts)
      equation
        Print.printBuf("record Absyn.CREF_IDENT name = \"");
        Print.printBuf(s);
        Print.printBuf("\", subscripts = ");
        printListAsCorbaString(subscripts, printSubscriptAsCorbaString, ",");
        Print.printBuf(" end Absyn.CREF_IDENT;");        
      then ();
    case Absyn.WILD()
      equation
        Print.printBuf("record Absyn.WILD end Absyn.WILD;");
      then ();
  end matchcontinue;
end printComponentRefAsCorbaString;

protected function printWithinAsCorbaString
  input Absyn.Within within_;
algorithm
  _ := matchcontinue within_
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
  end matchcontinue;
end printWithinAsCorbaString;

protected function printTimeStampAsCorbaString
  input Absyn.TimeStamp timeStamp;
algorithm
  _ := matchcontinue timeStamp
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
  end matchcontinue;
end printTimeStampAsCorbaString;

protected function printClassAsCorbaString
  input Absyn.Class cl;
algorithm
  _ := matchcontinue cl
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
  end matchcontinue;
end printClassAsCorbaString;

protected function printInfoAsCorbaString
  input Absyn.Info info;
algorithm
  _ := matchcontinue info
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
  end matchcontinue;
end printInfoAsCorbaString;

protected function printClassDefAsCorbaString
  input Absyn.ClassDef classDef;
algorithm
  _ := matchcontinue classDef
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
      list<String> vars;
    case Absyn.PARTS(classParts,optString)
      equation
        Print.printBuf("record Absyn.PARTS classParts = ");
        printListAsCorbaString(classParts, printClassPartAsCorbaString, ",");
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
    case Absyn.CLASS_EXTENDS(baseClassName,modifications,optString,classParts)
      equation
        Print.printBuf("record Absyn.CLASS_EXTENDS baseClassName = \"");
        Print.printBuf(baseClassName);
        Print.printBuf("\", modifications = ");
        printListAsCorbaString(modifications, printElementArgAsCorbaString, ",");
        Print.printBuf(", optString = ");
        printStringCommentOption(optString);
        Print.printBuf(", classParts = ");
        printListAsCorbaString(classParts,printClassPartAsCorbaString,",");
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
  end matchcontinue;
end printClassDefAsCorbaString;

protected function printEnumDefAsCorbaString
  input Absyn.EnumDef enumDef;
algorithm
  _ := matchcontinue enumDef
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
  end matchcontinue;
end printEnumDefAsCorbaString;

protected function printEnumLiteralAsCorbaString
  input Absyn.EnumLiteral enumLit;
algorithm
  _ := matchcontinue enumLit
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
  end matchcontinue;
end printEnumLiteralAsCorbaString;

protected function printRestrictionAsCorbaString
  input Absyn.Restriction r;
algorithm 
  _ := matchcontinue r
    case Absyn.R_CLASS()
      equation
        Print.printBuf("record Absyn.R_CLASS end Absyn.R_CLASS;");
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
    case Absyn.R_FUNCTION()
      equation
        Print.printBuf("record Absyn.R_FUNCTION end Absyn.R_FUNCTION;");
      then ();
    case Absyn.R_OPERATOR()
      equation
        Print.printBuf("record Absyn.R_OPERATOR end Absyn.R_OPERATOR;");
      then ();
    case Absyn.R_OPERATOR_FUNCTION()
      equation
        Print.printBuf("record Absyn.R_OPERATOR_FUNCTION end Absyn.R_OPERATOR_FUNCTION;");
      then ();
    case Absyn.R_ENUMERATION()
      equation
        Print.printBuf("record Absyn.R_ENUMERATION end Absyn.R_ENUMERATION;");
      then ();
    case Absyn.R_PREDEFINED_INT()
      equation
        Print.printBuf("record Absyn.R_PREDEFINED_INT end Absyn.R_PREDEFINED_INT;");
      then ();
    case Absyn.R_PREDEFINED_REAL()
      equation
        Print.printBuf("record Absyn.R_PREDEFINED_REAL end Absyn.R_PREDEFINED_REAL;");
      then ();
    case Absyn.R_PREDEFINED_STRING()
      equation
        Print.printBuf("record Absyn.R_PREDEFINED_STRING end Absyn.R_PREDEFINED_STRING;");
      then ();
    case Absyn.R_PREDEFINED_BOOL()
      equation
        Print.printBuf("record Absyn.R_PREDEFINED_BOOL end Absyn.R_PREDEFINED_BOOL;");
      then ();
    case Absyn.R_PREDEFINED_ENUM()
      equation
        Print.printBuf("record Absyn.R_PREDEFINED_ENUM end Absyn.R_PREDEFINED_ENUM;");
      then ();
    case Absyn.R_UNIONTYPE()
      equation
        Print.printBuf("record Absyn.R_UNIONTYPE end Absyn.R_UNIONTYPE;");
      then ();
    case Absyn.R_METARECORD(name=path,index=i)
      local
        Absyn.Path path;
        Integer i;
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
  end matchcontinue;
end printRestrictionAsCorbaString;

protected function printClassPartAsCorbaString
  input Absyn.ClassPart classPart;
algorithm
  _ := matchcontinue classPart
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
  end matchcontinue;
end printClassPartAsCorbaString;

protected function printExternalDeclAsCorbaString
  input Absyn.ExternalDecl decl;
algorithm
  _ := matchcontinue decl
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
  end matchcontinue;
end printExternalDeclAsCorbaString;

protected function printElementItemAsCorbaString
  input Absyn.ElementItem el;
algorithm
  _ := matchcontinue el
    local
      Absyn.Element element;
      Absyn.Annotation annotation_;
    case Absyn.ELEMENTITEM(element)
      equation
        Print.printBuf("record Absyn.ELEMENTITEM element = ");
        printElementAsCorbaString(element);
        Print.printBuf(" end Absyn.ELEMENTITEM;");
      then ();
    case Absyn.ANNOTATIONITEM(annotation_)
      equation
        Print.printBuf("record Absyn.ANNOTATIONITEM annotation_ = ");
        printAnnotationAsCorbaString(annotation_);
        Print.printBuf(" end Absyn.ANNOTATIONITEM;");
      then ();
  end matchcontinue;
end printElementItemAsCorbaString;

protected function printElementAsCorbaString
  input Absyn.Element el;
algorithm
  _ := matchcontinue el
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
    case Absyn.ELEMENT(finalPrefix,redeclareKeywords,innerOuter,name,specification,info,constrainClass)
      equation
        Print.printBuf("\nrecord Absyn.ELEMENT finalPrefix = ");
        Print.printBuf(Util.if_(finalPrefix,"true","false"));
        Print.printBuf(",redeclareKeywords = ");
        printOption(redeclareKeywords, printRedeclareKeywordsAsCorbaString);
        Print.printBuf(",innerOuter = ");
        printInnerOuterAsCorbaString(innerOuter);
        Print.printBuf(",name = \"");
        Print.printBuf(name);
        Print.printBuf("\",specification = ");
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
  end matchcontinue;
end printElementAsCorbaString;

protected function printInnerOuterAsCorbaString
  input Absyn.InnerOuter innerOuter;
algorithm
  _ := matchcontinue innerOuter
    case Absyn.INNER()
      equation
        Print.printBuf("record Absyn.INNER end Absyn.INNER;");
      then ();
    case Absyn.OUTER()
      equation
        Print.printBuf("record Absyn.OUTER end Absyn.OUTER;");
      then ();
    case Absyn.INNEROUTER()
      equation
        Print.printBuf("record Absyn.INNEROUTER end Absyn.INNEROUTER;");
      then ();
    case Absyn.UNSPECIFIED()
      equation
        Print.printBuf("record Absyn.UNSPECIFIED end Absyn.UNSPECIFIED;");
      then ();
  end matchcontinue;
end printInnerOuterAsCorbaString;

protected function printRedeclareKeywordsAsCorbaString
  input Absyn.RedeclareKeywords redeclareKeywords;
algorithm
  _ := matchcontinue redeclareKeywords
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
  end matchcontinue;
end printRedeclareKeywordsAsCorbaString;

protected function printConstrainClassAsCorbaString
  input Absyn.ConstrainClass constrainClass;
algorithm
  _ := matchcontinue constrainClass
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
  end matchcontinue;
end printConstrainClassAsCorbaString;

protected function printElementSpecAsCorbaString
  input Absyn.ElementSpec spec;
algorithm
  _ := matchcontinue spec
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
    case Absyn.IMPORT(import_, comment)
      equation
        Print.printBuf("record Absyn.IMPORT import_ = ");
        printImportAsCorbaString(import_);
        Print.printBuf(", comment = ");
        printOption(comment, printCommentAsCorbaString);
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
  end matchcontinue;
end printElementSpecAsCorbaString;

protected function printComponentItemAsCorbaString
  input Absyn.ComponentItem componentItem;
algorithm
  _ := matchcontinue componentItem
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
  end matchcontinue;
end printComponentItemAsCorbaString;

protected function printComponentAsCorbaString
  input Absyn.Component component;
algorithm
  _ := matchcontinue component
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
  end matchcontinue;
end printComponentAsCorbaString;

protected function printModificationAsCorbaString
  input Absyn.Modification mod;
algorithm
  _ := matchcontinue mod
    local
      list<Absyn.ElementArg> elementArgLst;
      Option<Absyn.Exp> expOption;
    case Absyn.CLASSMOD(elementArgLst, expOption)
      equation
        Print.printBuf("record Absyn.CLASSMOD elementArgLst = ");
        printListAsCorbaString(elementArgLst, printElementArgAsCorbaString, ",");
        Print.printBuf(", expOption = ");
        printOption(expOption, printExpAsCorbaString);
        Print.printBuf(" end Absyn.CLASSMOD;");
     then ();
  end matchcontinue;
end printModificationAsCorbaString;

protected function printEquationItemAsCorbaString
  input Absyn.EquationItem el;
algorithm
  _ := matchcontinue el
    local
      Absyn.Equation equation_;
      Option<Absyn.Comment> comment;
      Absyn.Annotation annotation_;
    case Absyn.EQUATIONITEM(equation_,comment)
      equation
        Print.printBuf("\nrecord Absyn.EQUATIONITEM equation_ = ");
        printEquationAsCorbaString(equation_);
        Print.printBuf(", comment = ");
        printOption(comment, printCommentAsCorbaString);
        Print.printBuf(" end Absyn.EQUATIONITEM;");
      then ();
    case Absyn.EQUATIONITEMANN(annotation_)
      equation
        Print.printBuf("\nrecord Absyn.EQUATIONITEMANN annotation_ = ");
        printAnnotationAsCorbaString(annotation_);
        Print.printBuf(" end Absyn.EQUATIONITEMANN;");
      then ();
  end matchcontinue;
end printEquationItemAsCorbaString;

protected function printEquationAsCorbaString
  input Absyn.Equation eq;
algorithm
  _ := matchcontinue eq
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
      then ();  end matchcontinue;
end printEquationAsCorbaString;

protected function printAlgorithmItemAsCorbaString
  input Absyn.AlgorithmItem el;
algorithm
  _ := matchcontinue el
    local
      Absyn.Algorithm algorithm_;
      Option<Absyn.Comment> comment;
      Absyn.Annotation annotation_;
    case Absyn.ALGORITHMITEM(algorithm_,comment)
      equation
        Print.printBuf("\nrecord Absyn.ALGORITHMITEM algorithm_ = ");
        printAlgorithmAsCorbaString(algorithm_);
        Print.printBuf(", comment = ");
        printOption(comment, printCommentAsCorbaString);
        Print.printBuf(" end Absyn.ALGORITHMITEM;");
      then ();
    case Absyn.ALGORITHMITEMANN(annotation_)
      equation
        Print.printBuf("\nrecord Absyn.ALGORITHMITEMANN annotation_ = ");
        printAnnotationAsCorbaString(annotation_);
        Print.printBuf(" end Absyn.ALGORITHMITEMANN;");
      then ();
  end matchcontinue;
end printAlgorithmItemAsCorbaString;

protected function printAlgorithmAsCorbaString
  input Absyn.Algorithm alg;
algorithm
  _ := matchcontinue alg
    local
      Absyn.Exp assignComponent, value, ifExp, boolExpr;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> elseIfAlgorithmBranch,elseWhenAlgorithmBranch;
      list<Absyn.AlgorithmItem> trueBranch,elseBranch,forBody,whileBody,whenBody,tryBody,catchBody;
      Absyn.ForIterators iterators;
      Absyn.ComponentRef functionCall;
      Absyn.FunctionArgs functionArgs;
      list<Absyn.Exp> switchCases;
      String label;
      Absyn.AlgorithmItem equ;
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
    case Absyn.ALG_MATCHCASES(switchCases)
      equation
        Print.printBuf("record Absyn.ALG_MATCHCASES switchCases = ");
        printListAsCorbaString(switchCases, printExpAsCorbaString, ",");
        Print.printBuf(" end Absyn.ALG_MATCHCASES;");
      then ();
    case Absyn.ALG_GOTO(label)
      equation
        Print.printBuf("record Absyn.ALG_GOTO label = \"");
        Print.printBuf(label);
        Print.printBuf("\" end Absyn.ALG_GOTO;");
      then ();
    case Absyn.ALG_LABEL(label)
      equation
        Print.printBuf("record Absyn.ALG_LABEL label = \"");
        Print.printBuf(label);
        Print.printBuf("\" end Absyn.ALG_LABEL;");
      then ();
    case Absyn.ALG_FAILURE(equ)
      equation
        Print.printBuf("record Absyn.ALG_FAILURE equ = ");
        printAlgorithmItemAsCorbaString(equ);
        Print.printBuf(" end Absyn.ALG_FAILURE;");
      then ();
  end matchcontinue;
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
  _ := matchcontinue annotation_
    local
      list<Absyn.ElementArg> elementArgs;
    case Absyn.ANNOTATION(elementArgs)
      equation
        Print.printBuf("record Absyn.ANNOTATION elementArgs = "); 
        printListAsCorbaString(elementArgs, printElementArgAsCorbaString, ",");
        Print.printBuf(" end Absyn.ANNOTATION;");
      then ();
  end matchcontinue;
end printAnnotationAsCorbaString;

protected function printCommentAsCorbaString
  input Absyn.Comment inComment;
algorithm
  _ := matchcontinue inComment
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
  end matchcontinue;
end printCommentAsCorbaString;

protected function printTypeSpecAsCorbaString
  input Absyn.TypeSpec typeSpec;
algorithm
  _ := matchcontinue typeSpec
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
  end matchcontinue;
end printTypeSpecAsCorbaString;

protected function printArrayDimAsCorbaString
  input Absyn.ArrayDim arrayDim;
algorithm
  printListAsCorbaString(arrayDim, printSubscriptAsCorbaString, ",");
end printArrayDimAsCorbaString;

protected function printSubscriptAsCorbaString
  input Absyn.Subscript subscript;
algorithm
  _ := matchcontinue subscript
    local
      Absyn.Exp subScript;
    case Absyn.NOSUB()
      equation
        Print.printBuf("record Absyn.NOSUB end Absyn.NOSUB;");
      then ();
    case Absyn.SUBSCRIPT(subScript)
      equation
        Print.printBuf("record Absyn.SUB subScript = ");
        printExpAsCorbaString(subScript);
        Print.printBuf(" end Absyn.SUB;");
      then ();
  end matchcontinue;
end printSubscriptAsCorbaString;

protected function printImportAsCorbaString
  input Absyn.Import import_;
algorithm
  _ := matchcontinue import_
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
  end matchcontinue;
end printImportAsCorbaString;

protected function printElementAttributesAsCorbaString
  input Absyn.ElementAttributes attr;
algorithm
  _ := matchcontinue attr
    local
      Boolean flowPrefix;
      Boolean streamPrefix;
      Absyn.Variability variability;
      Absyn.Direction direction;
      Absyn.ArrayDim arrayDim;
    case Absyn.ATTR(flowPrefix,streamPrefix,variability,direction,arrayDim)
      equation
        Print.printBuf("record Absyn.ATTR flowPrefix = ");
        Print.printBuf(Util.if_(flowPrefix, "true", "false"));        
        Print.printBuf(", streamPrefix = ");
        Print.printBuf(Util.if_(streamPrefix, "true", "false"));
        Print.printBuf(", variability = ");
        printVariabilityAsCorbaString(variability);
        Print.printBuf(", direction = ");
        printDirectionAsCorbaString(direction);
        Print.printBuf(", arrayDim = ");
        printArrayDimAsCorbaString(arrayDim);
        Print.printBuf(" end Absyn.ATTR;");        
      then ();
  end matchcontinue;
end printElementAttributesAsCorbaString;

protected function printVariabilityAsCorbaString
  input Absyn.Variability var;
algorithm
  _ := matchcontinue var
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
  end matchcontinue;
end printVariabilityAsCorbaString;

protected function printDirectionAsCorbaString
  input Absyn.Direction dir;
algorithm
  _ := matchcontinue dir
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
  end matchcontinue;
end printDirectionAsCorbaString;

protected function printElementArgAsCorbaString
  input Absyn.ElementArg arg;
algorithm
  _ := matchcontinue arg
    local
      Boolean finalItem;
      Absyn.Each each_;
      Absyn.ComponentRef componentRef;
      Option<Absyn.Modification> modification;
      Option<String> comment;
      Absyn.RedeclareKeywords redeclareKeywords;
      Absyn.ElementSpec elementSpec;
      Option<Absyn.ConstrainClass> constrainClass;
    case Absyn.MODIFICATION(finalItem,each_,componentRef,modification,comment)
      equation
        Print.printBuf("record Absyn.MODIFICATION finalItem = ");
        Print.printBuf(Util.if_(finalItem,"true","false"));
        Print.printBuf(", each_ = ");
        printEachAsCorbaString(each_);
        Print.printBuf(", componentRef = ");
        printComponentRefAsCorbaString(componentRef);
        Print.printBuf(", modification = ");
        printOption(modification, printModificationAsCorbaString);
        Print.printBuf(", comment = ");
        printStringCommentOption(comment);
        Print.printBuf(" end Absyn.MODIFICATION;");
      then ();
    case Absyn.REDECLARATION(finalItem,redeclareKeywords,each_,elementSpec,constrainClass)
      equation
        Print.printBuf("record Absyn.REDECLARATION finalItem = ");
        Print.printBuf(Util.if_(finalItem,"true","false"));
        Print.printBuf(", redeclareKeywords = ");
        printRedeclareKeywordsAsCorbaString(redeclareKeywords);
        Print.printBuf(", each_ = ");
        printEachAsCorbaString(each_);
        Print.printBuf(", elementSpec = ");
        printElementSpecAsCorbaString(elementSpec);
        Print.printBuf(", constrainClass = ");
        printOption(constrainClass, printConstrainClassAsCorbaString);
        Print.printBuf(" end Absyn.REDECLARATION;");
      then ();
  end matchcontinue;
end printElementArgAsCorbaString;

protected function printFunctionArgsAsCorbaString
  input Absyn.FunctionArgs fargs;
algorithm
  _ := matchcontinue fargs
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
        printList(iterators, printForIteratorAsCorbaString, ",");
        Print.printBuf(" end Absyn.FOR_ITER_FARG;");  
      then ();
  end matchcontinue;
end printFunctionArgsAsCorbaString;

protected function printForIteratorAsCorbaString
  input Absyn.ForIterator iter;
algorithm
  _ := matchcontinue iter
    local
      String id;
      Option<Absyn.Exp> optExp;
    case ((id,optExp))
      equation
        Print.printBuf("(\"");
        Print.printBuf(id);
        Print.printBuf("\",");
        printOption(optExp,printExpAsCorbaString);
        Print.printBuf(")");
      then ();
  end matchcontinue;
end printForIteratorAsCorbaString;

protected function printNamedArgAsCorbaString
  input Absyn.NamedArg arg;
algorithm
  _ := matchcontinue arg
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
  end matchcontinue;
end printNamedArgAsCorbaString;

protected function printExpAsCorbaString
  input Absyn.Exp inExp;
algorithm
  _ := matchcontinue inExp
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
      list<Absyn.Exp> arrayExp, expressions, exps;
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
  end matchcontinue;
end printExpAsCorbaString;

protected function printMatchTypeAsCorbaString
  input Absyn.MatchType matchTy;
algorithm
  _ := matchcontinue matchTy
    case Absyn.MATCH()
      equation
        Print.printBuf("record Absyn.MATCH end Absyn.MATCH;");
      then ();
    case Absyn.MATCHCONTINUE()
      equation
        Print.printBuf("record Absyn.MATCHCONTINUE end Absyn.MATCHCONTINUE;");
      then ();
  end matchcontinue;
end printMatchTypeAsCorbaString;

protected function printCaseAsCorbaString
  input Absyn.Case case_;
algorithm
  _ := matchcontinue case_
    local
      Absyn.Exp pattern; 
      list<Absyn.ElementItem> localDecls;
      list<Absyn.EquationItem>  equations;
      Absyn.Exp result;
      Option<String> comment;
    case Absyn.CASE(pattern,localDecls,equations,result,comment)
      equation
        Print.printBuf("record Absyn.CASE pattern = ");
        printExpAsCorbaString(pattern);
        Print.printBuf(", localDecls = ");
        printListAsCorbaString(localDecls, printElementItemAsCorbaString, ",");
        Print.printBuf(", equations = ");
        printListAsCorbaString(equations, printEquationItemAsCorbaString, ",");
        Print.printBuf(", result = ");
        printExpAsCorbaString(result);
        Print.printBuf(", comment = ");
        printStringCommentOption(comment);
        Print.printBuf(" end Absyn.CASE;");
      then ();    
    case Absyn.ELSE(localDecls,equations,result,comment)
      equation
        Print.printBuf("record Absyn.ELSE localDecls = ");
        printListAsCorbaString(localDecls, printElementItemAsCorbaString, ",");
        Print.printBuf(", equations = ");
        printListAsCorbaString(equations, printEquationItemAsCorbaString, ",");
        Print.printBuf(", result = ");
        printExpAsCorbaString(result);
        Print.printBuf(", comment = ");
        printStringCommentOption(comment);
        Print.printBuf(" end Absyn.ELSE;");
      then ();
  end matchcontinue;
end printCaseAsCorbaString;

protected function printCodeAsCorbaString
  input Absyn.CodeNode code;
algorithm
  _ := matchcontinue code
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
  end matchcontinue;
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
  _ := matchcontinue (inTpl,fnA,fnB)
    local
      Type_a a;
      Type_b b;
    case ((a,b),fnA,fnB)
      equation
        Print.printBuf("(");
        fnA(a);
        Print.printBuf(",");
        fnB(b);
        Print.printBuf(")");
      then ();
  end matchcontinue;
end printTupleAsCorbaString;

protected function printOperatorAsCorbaString
  input Absyn.Operator op;
algorithm
  _ := matchcontinue op
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
  end matchcontinue;
end printOperatorAsCorbaString;

protected function printEachAsCorbaString
  input Absyn.Each each_;
algorithm
  _ := matchcontinue each_
    case Absyn.EACH() equation Print.printBuf("record Absyn.EACH end Absyn.EACH;"); then ();
    case Absyn.NON_EACH() equation Print.printBuf("record Absyn.NON_EACH end Absyn.NON_EACH;"); then ();
  end matchcontinue;
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

