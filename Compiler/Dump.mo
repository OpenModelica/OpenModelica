package Dump "
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
  file:	 Dump.mo
  module:      Dump
  description: debug printing
 
  RCS: $Id$
 
  Printing routines for debugging of the AST.  These functions do
  nothing but print the data structures to the standard output.
 
  The main entrypoint for this module is the function \"dump\" which
  takes an entire program as an argument, and prints it all in
  Modelica source form. The other interface functions can be used
  to print smaller portions of a program.
"

public import Absyn;
public import Interactive;

public 
type Ident = String;

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



public function dump "function: dump
 
  Prints a program, i.e. the whole AST, to the Print buffer.
"
  input Absyn.Program inProgram;
algorithm 
  _:=
  matchcontinue (inProgram)
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

public function unparseStr "function: unparseStr
  
  Prettyprints the Program, i.e. the whole AST, to a string.
"
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inProgram)
    local
      Ident s1,s2,s3,str;
      list<Absyn.Class> cs;
      Absyn.Within w;
    case Absyn.PROGRAM(classes = {}) then ""; 
    case Absyn.PROGRAM(classes = cs,within_ = w)
      equation 
        s1 = unparseWithin(0, w);
        s2 = unparseClassList(0, cs);
        str = Util.stringAppendList({s1,s2,"\n"});
      then
        str;
    case (_) then "unparsing failed\n"; 
  end matchcontinue;
end unparseStr;

public function unparseClassList "function: unparseClassList
 
  Prettyprints a list of classes
"
  input Integer inInteger;
  input list<Absyn.Class> inAbsynClassLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger,inAbsynClassLst)
    local
      Ident s1,s2,res;
      Integer i;
      Absyn.Class c;
      list<Absyn.Class> cs;
    case (_,{}) then ""; 
    case (i,(c :: cs))
      equation 
        s1 = unparseClassStr(i, c, "", "", "");
        s2 = unparseClassList(i, cs);
        res = Util.stringAppendList({s1,";\n",s2});
      then
        res;
  end matchcontinue;
end unparseClassList;

public function unparseWithin "function: unparseWithin
 
  Prettyprints a within statement.
"
  input Integer inInteger;
  input Absyn.Within inWithin;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger,inWithin)
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

protected function dumpWithin "function: dumpWithin
 
  Dumps within to the Print buffer.
"
  input Absyn.Within inWithin;
algorithm 
  _:=
  matchcontinue (inWithin)
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

public function unparseClassStr "function: unparseClassStr
 
  Prettyprints a Class.
"
  input Integer inInteger1;
  input Absyn.Class inClass2;
  input String inString3;
  input String inString4;
  input String inString5;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger1,inClass2,inString3,inString4,inString5)
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
    case (i,Absyn.CLASS(name = n,partial_ = p,final_ = f,encapsulated_ = e,restriction = r,body = Absyn.PARTS(classParts = parts,comment = optcmt)),fi,re,io)
      equation 
        is = indentStr(i);
        s1 = selectString(p, "partial ", "");
        s2 = selectString(f, "final ", "");
        s2_1 = selectString(e, "encapsulated ", "");
        s3 = unparseRestrictionStr(r);
        i_1 = i + 1;
        s4 = unparseClassPartStrLst(i_1, parts, true);
        s5 = unparseStringCommentOption(optcmt);
        str = Util.stringAppendList({is,s2_1,s1,s2,re,io,s3," ",n,s5,"\n",s4,is,"end ",n});
      then
        str;
    case (indent,Absyn.CLASS(name = n,partial_ = p,final_ = f,encapsulated_ = e,restriction = r,body = Absyn.DERIVED(typeSpec = tspec,attributes = attr,arguments = m,comment = optcmt)),fi,re,io)
      local Option<Absyn.Comment> optcmt;
      equation 
        is = indentStr(indent);
        s1 = selectString(p, "partial ", "");
        s2 = selectString(f, "final ", "");
        s2_1 = selectString(e, "encapsulated ", "");
        s3 = unparseRestrictionStr(r);
        s4 = unparseElementattrStr(attr);
        s5 = stringAppend(s1, s2);
        s6 = unparseTypeSpec(tspec);
        s8 = unparseMod1Str(m);
        s9 = unparseCommentOption(optcmt);
        str = Util.stringAppendList({is,s2_1,s1,s2,re,io,s3," ",n,"= ",s4,s5,s6,s8,s9});
      then
        str;
    case (i,Absyn.CLASS(name = n,partial_ = p,final_ = f,encapsulated_ = e,restriction = r,body = Absyn.ENUMERATION(enumLiterals = Absyn.ENUMLITERALS(enumLiterals = l),comment = cmt)),fi,re,io)
      equation 
        is = indentStr(i);
        s1 = selectString(p, "partial ", "");
        s2 = selectString(f, "final ", "");
        s2_1 = selectString(e, "encapsulated ", "");
        s3 = unparseRestrictionStr(r);
        s4 = unparseEnumliterals(l);
        s5 = unparseCommentOption(cmt);
        str = Util.stringAppendList({is,s2_1,s1,s2,re,io,s3," ",n,"= enumeration(",s4,")",s5});
      then
        str;
    case (i,Absyn.CLASS(name = n,partial_ = p,final_ = f,encapsulated_ = e,restriction = r,body = Absyn.ENUMERATION(enumLiterals = ENUM_COLON,comment = cmt)),fi,re,io)
      equation 
        is = indentStr(i);
        s1 = selectString(p, "partial ", "");
        s2 = selectString(f, "final ", "");
        s2_1 = selectString(e, "encapsulated ", "");
        s3 = unparseRestrictionStr(r);
        s5 = unparseCommentOption(cmt);
        str = Util.stringAppendList({is,s2_1,s1,s2,re,io,s3," ",n,"= enumeration(:)",s5});
      then
        str;
    case (i,Absyn.CLASS(name = n,partial_ = p,final_ = f,encapsulated_ = e,restriction = r,body = Absyn.CLASS_EXTENDS(name = name,arguments = cmod,comment = optcmt,parts = parts)),fi,re,io)
      equation 
        is = indentStr(i);
        s1 = selectString(p, "partial ", "");
        s2 = selectString(f, "final ", "");
        s2_1 = selectString(e, "encapsulated ", "");
        s3 = unparseRestrictionStr(r);
        i_1 = i + 1;
        s4 = unparseClassPartStrLst(i_1, parts, true);
        s5 = unparseMod1Str(cmod);
        s6 = unparseStringCommentOption(optcmt);
        str = Util.stringAppendList(
          {is,s2_1,s1,s2,re,io,s3," extends ",name,s5,s6,"\n",s4,is,
          "end ",name});
      then
        str;
    case (i,Absyn.CLASS(name = n,partial_ = p,final_ = f,encapsulated_ = e,restriction = r,body = Absyn.PDER(functionName = fname,vars = vars)),fi,re,io)
      equation 
        is = indentStr(i);
        s1 = selectString(p, "partial ", "");
        s2 = selectString(f, "final ", "");
        s2_1 = selectString(e, "encapsulated ", "");
        s3 = unparseRestrictionStr(r);
        s4 = Absyn.pathString(fname);
        s5 = Util.stringDelimitList(vars, ", ");
        str = Util.stringAppendList({is,s2_1,s1,s2,re,io,s3," ",n," = der(",s4,", ",s5,")"});
      then
        str;
  end matchcontinue;
end unparseClassStr;

public function unparseCommentOption "function: unparseCommentOption
 
  Prettyprints a Comment.
"
  input Option<Absyn.Comment> inAbsynCommentOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynCommentOption)
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

public function unparseCommentOptionNoAnnotation "function: unparseCommentOptionNoAnnotation
 
  Prettyprints a Comment without printing the annotation part.
"
  input Option<Absyn.Comment> inAbsynCommentOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynCommentOption)
    local Ident str,cmt;
    case (SOME(Absyn.COMMENT(_,SOME(cmt))))
      equation 
        str = Util.stringAppendList({" \"",cmt,"\""});
      then
        str;
    case (_) then ""; 
  end matchcontinue;
end unparseCommentOptionNoAnnotation;

protected function dumpCommentOption "function: dumpCommentOption
 
  Prints a Comment to the Print buffer.
"
  input Option<Absyn.Comment> inAbsynCommentOption;
algorithm 
  _:=
  matchcontinue (inAbsynCommentOption)
    local
      Ident str,cmt;
      Option<Absyn.Annotation> annopt;
    case (NONE)
      equation 
        Print.printBuf("NONE");
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

protected function dumpAnnotationOption "function: dumpAnnotationOption
 
  Dumps an annotation option to the Print buffer.
"
  input Option<Absyn.Annotation> inAbsynAnnotationOption;
algorithm 
  _:=
  matchcontinue (inAbsynAnnotationOption)
    local list<Absyn.ElementArg> mod;
    case (NONE)
      equation 
        Print.printBuf("NONE");
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

protected function unparseEnumliterals "function: unparseEnumliterals
 
  Prettyprints enumeration literals, each consisting of an identifier
  and an optional comment.
"
  input list<Absyn.EnumLiteral> inAbsynEnumLiteralLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynEnumLiteralLst)
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

protected function printEnumliterals "function: printEnumliterals
 
  Prints enumeration literals, each consisting of an identifier
  and an optional comment to the Print buffer.
"
  input list<Absyn.EnumLiteral> lst;
algorithm 
  Print.printBuf("[");
  printEnumliterals2(lst);
  Print.printBuf("]");
end printEnumliterals;

protected function printEnumliterals2 "function: printEnumliterals2
 
  Helper function to print_enumliterals
"
  input list<Absyn.EnumLiteral> inAbsynEnumLiteralLst;
algorithm 
  _:=
  matchcontinue (inAbsynEnumLiteralLst)
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

public function unparseRestrictionStr "function: unparseRestrictionStr
 
  Prettyprints the class restriction.
"
  input Absyn.Restriction inRestriction;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inRestriction)
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

public function dumpIstmt "function: dumpIstmt
 
  Dumps an interactive statement to the Print buffer.
"
  input Interactive.InteractiveStmts inInteractiveStmts;
algorithm 
  _:=
  matchcontinue (inInteractiveStmts)
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

public function printInfo "function: printInfo
 
  Dumps an Info to the Print buffer.
  author: adrpo, 2006-02-05
"
  input Absyn.Info inInfo;
algorithm 
  _:=
  matchcontinue (inInfo)
    local
      Ident s1,s2,s3,s4,filename;
      Boolean isReadOnly;
      Integer sline,scol,eline,ecol;
    case (Absyn.INFO(fileName = filename,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol))
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

public function unparseInfoStr "function: unparseInfoStr
 
  Translates Info to a string representation
  author: adrpo, 2006-02-05
"
  input Absyn.Info inInfo;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInfo)
    local
      Ident s1,s2,s3,s4,s5,str,filename;
      Boolean isReadOnly;
      Integer sline,scol,eline,ecol;
    case (Absyn.INFO(fileName = filename,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol))
      equation 
        s1 = selectString(isReadOnly, "readonly", "writable");
        s2 = intString(sline);
        s3 = intString(scol);
        s4 = intString(eline);
        s5 = intString(ecol);
        str = Util.stringAppendList(
          {"Absyn.INFO(\"",filename,"\", ",s1,", ",s2,", ",s3,", ",s4,
          ", ",s5,")\n"});
      then
        str;
  end matchcontinue;
end unparseInfoStr;

protected function printClass "function: printClass
 
  Dumps a Class to the Print buffer.
  changed by adrpo, 2006-02-05 to use print_info.
"
  input Absyn.Class inClass;
algorithm 
  _:=
  matchcontinue (inClass)
    local
      Ident n;
      Boolean p,f,e;
      Absyn.Restriction r;
      Absyn.ClassDef cdef;
      Absyn.Info info;
    case (Absyn.CLASS(name = n,partial_ = p,final_ = f,encapsulated_ = e,restriction = r,body = cdef,info = info))
      equation 
        Print.printBuf("Absyn.CLASS(\"");
        Print.printBuf(n);
        Print.printBuf("\", ");
        printBool(p);
        Print.printBuf(", ");
        printBool(f);
        Print.printBuf(", ");
        printBool(e);
        Print.printBuf(", ");
        printClassRestriction(r);
        Print.printBuf(", ");
        printClassdef(cdef);
        Print.printBuf(", ");
        printInfo(info);
        Print.printBuf(")\n");
      then
        ();
  end matchcontinue;
end printClass;

protected function printClassdef "function: printClassdef
 
  Prints a ClassDef to the Print buffer.
"
  input Absyn.ClassDef inClassDef;
algorithm 
  _:=
  matchcontinue (inClassDef)
    local
      list<Absyn.ClassPart> parts;
      Option<Ident> comment;
      Ident s;
      Absyn.TypeSpec tspec;
      Absyn.ElementAttributes attr;
      list<Absyn.ElementArg> earg;
      list<Absyn.EnumLiteral> enumlst;
    case (Absyn.PARTS(classParts = parts,comment = comment))
      equation 
        Print.printBuf("Absyn.PARTS([");
        printListDebug("print_classdef", parts, printClassPart, ", ");
        Print.printBuf("], ");
        printStringCommentOption(comment);
        Print.printBuf(")");
      then
        ();
    case (Absyn.DERIVED(typeSpec = tspec,attributes = attr,arguments = earg,comment = comment))
      local Option<Absyn.Comment> comment;
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
      local Option<Absyn.Comment> comment;
      equation 
        Print.printBuf("Absyn.ENUMERATION(");
        printEnumliterals(enumlst);
        Print.printBuf(", ");
        dumpCommentOption(comment);
        Print.printBuf(")");
      then
        ();
    case (Absyn.ENUMERATION(enumLiterals = Absyn.ENUM_COLON(),comment = comment))
      local Option<Absyn.Comment> comment;
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

protected function printClassRestriction "function: printClassRestriction
 
  Prints the class restriction to the Print buffer.
"
  input Absyn.Restriction inRestriction;
algorithm 
  _:=
  matchcontinue (inRestriction)
    case Absyn.R_CLASS()
      equation 
        Print.printBuf("Absyn.R_CLASS");
      then
        ();
    case Absyn.R_MODEL()
      equation 
        Print.printBuf("Absyn.R_MODEL");
      then
        ();
    case Absyn.R_RECORD()
      equation 
        Print.printBuf("Absyn.R_RECORD");
      then
        ();
    case Absyn.R_BLOCK()
      equation 
        Print.printBuf("Absyn.R_BLOCK");
      then
        ();
    case Absyn.R_CONNECTOR()
      equation 
        Print.printBuf("Absyn.R_CONNECTOR");
      then
        ();
    case Absyn.R_EXP_CONNECTOR()
      equation 
        Print.printBuf("Absyn.R_EXP_CONNECTOR");
      then
        ();
    case Absyn.R_TYPE()
      equation 
        Print.printBuf("Absyn.R_TYPE");
      then
        ();
    case Absyn.R_UNIONTYPE()
      equation 
        Print.printBuf("Absyn.R_UNIONTYPE");
      then
        ();
    case Absyn.R_PACKAGE()
      equation 
        Print.printBuf("Absyn.R_PACKAGE");
      then
        ();
    case Absyn.R_FUNCTION()
      equation 
        Print.printBuf("Absyn.R_FUNCTION");
      then
        ();
    case Absyn.R_ENUMERATION()
      equation 
        Print.printBuf("Absyn.R_ENUMERATION");
      then
        ();
    case Absyn.R_PREDEFINED_INT()
      equation 
        Print.printBuf("Absyn.R_PREDEFINED_INT");
      then
        ();
    case Absyn.R_PREDEFINED_REAL()
      equation 
        Print.printBuf("Absyn.R_PREDEFINED_REAL");
      then
        ();
    case Absyn.R_PREDEFINED_STRING()
      equation 
        Print.printBuf("Absyn.R_PREDEFINED_STRING");
      then
        ();
    case Absyn.R_PREDEFINED_BOOL()
      equation 
        Print.printBuf("Absyn.R_PREDEFINED_BOOL");
      then
        ();
    case Absyn.R_PREDEFINED_ENUM()
      equation 
        Print.printBuf("Absyn.R_PREDEFINED_ENUM");
      then
        ();
    case _ then (); 
  end matchcontinue;
end printClassRestriction;

protected function printClassModification "function: printClassModification
 
  Prints a class modification to a print buffer.
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
algorithm 
  _:=
  matchcontinue (inAbsynElementArgLst)
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

protected function unparseClassModificationStr "function: unparseClassModificationStr
 
  Prettyprints a class modification to a string.
"
  input Absyn.Modification inModification;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inModification)
    local
      Ident s1,s2,str;
      list<Absyn.ElementArg> l;
      Absyn.Exp e;
    case (Absyn.CLASSMOD(elementArgLst = {})) then ""; 
    case (Absyn.CLASSMOD(elementArgLst = l,expOption = NONE))
      equation 
        s1 = getStringList(l, unparseElementArgStr, ",");
        s2 = stringAppend("(", s1);
        str = stringAppend(s2, ")");
      then
        str;
    case (Absyn.CLASSMOD(expOption = SOME(e)))
      equation 
        s1 = printExpStr(e);
        str = Util.stringAppendList({"=",s1});
      then
        str;
  end matchcontinue;
end unparseClassModificationStr;

protected function printElementArg "function: printElementArg
 
  Prints an ElementArg to the Print buffer.
"
  input Absyn.ElementArg inElementArg;
algorithm 
  _:=
  matchcontinue (inElementArg)
    local
      Boolean f;
      Absyn.Each each_;
      Absyn.ComponentRef r;
      Option<Absyn.Modification> optm;
      Option<Ident> optcmt;
      Absyn.RedeclareKeywords keywords;
      Absyn.ElementSpec spec;
    case (Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = r,modification = optm,comment = optcmt))
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

public function unparseElementArgStr "function: unparseElementArgStr
 
  Prettyprints an ElementArg to a string.
"
  input Absyn.ElementArg inElementArg;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementArg)
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
    case (Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = r,modification = optm,comment = optstr))
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
        s3 = unparseRedeclarekeywords(keywords);
        s4 = unparseElementspecStr(0, spec, s2, "", "");
        s5 = unparseConstrainclassOptStr(constr);
        str = Util.stringAppendList({s1,s2,s3,s4," ",s5});
      then
        str;
  end matchcontinue;
end unparseElementArgStr;

protected function unparseRedeclarekeywords "function: unparseRedeclarekeywords
  
  Prettyprints the redeclare keywords, i.e \'replaceable\' and \'redeclare\'
"
  input Absyn.RedeclareKeywords inRedeclareKeywords;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inRedeclareKeywords)
    case Absyn.REDECLARE() then "redeclare "; 
    case Absyn.REPLACEABLE() then "replaceable "; 
    case Absyn.REDECLARE_REPLACEABLE() then "redeclare replaceable "; 
  end matchcontinue;
end unparseRedeclarekeywords;

public function unparseEachStr "function: unparseEachStr
 
  Prettyprints the each keyword.
"
  input Absyn.Each inEach;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inEach)
    case (Absyn.EACH()) then "each "; 
    case (Absyn.NON_EACH()) then ""; 
  end matchcontinue;
end unparseEachStr;

protected function dumpEach "function: dumpEach
 
  Print the each keyword to the Print buffer
"
  input Absyn.Each inEach;
algorithm 
  _:=
  matchcontinue (inEach)
    case (Absyn.EACH())
      equation 
        Print.printBuf("Absyn.EACH");
      then
        ();
    case (Absyn.NON_EACH())
      equation 
        Print.printBuf("Absyn.NON_EACH");
      then
        ();
  end matchcontinue;
end dumpEach;

protected function printClassPart "function: printClassPart
 
  Prints the ClassPart to the Print buffer.
"
  input Absyn.ClassPart inClassPart;
algorithm 
  _:=
  matchcontinue (inClassPart)
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

protected function printExternalDecl "function: printExternalDecl
 
  Prints an external declaration to the Print buffer.
"
  input Absyn.ExternalDecl inExternalDecl;
algorithm 
  _:=
  matchcontinue (inExternalDecl)
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

public function unparseClassPartStrLst "function: unparseClassPartStrLst
 
  Prettyprints a ClassPart list to a string.
"
  input Integer inInteger;
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Boolean inBoolean;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger,inAbsynClassPartLst,inBoolean)
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
  input Integer inInteger;
  input Absyn.ClassPart inClassPart;
  input Boolean inBoolean;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger,inClassPart,inBoolean)
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
        i_1 = i - 1;
        is = indentStr(i_1);
        str = Util.stringAppendList({is,s1});
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
    case (i,Absyn.EXTERNAL(externalDecl = Absyn.EXTERNALDECL(funcName = SOME(ident),lang = lang,output_ = SOME(output_),args = expl,annotation_ = ann),annotation_ = ann2),_)
      equation 
        langstr = getExtlangStr(lang);
        outputstr = printComponentRefStr(output_);
        expstr = printListStr(expl, printExpStr, ",");
        s1 = stringAppend(langstr, " ");
        is = indentStr(i);
        annstr = unparseAnnotationOption(i, ann);
        annstr2 = unparseAnnotationOptionSemi(i, ann2);
        str = Util.stringAppendList(
          {"\n",is,"external ",langstr," ",outputstr,"=",ident,"(",
          expstr,") ",annstr,";",annstr2,"\n"});
      then
        str;
    case (i,Absyn.EXTERNAL(externalDecl = Absyn.EXTERNALDECL(funcName = SOME(ident),lang = lang,output_ = NONE,args = expl,annotation_ = ann),annotation_ = ann2),_)
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
    case (i,Absyn.EXTERNAL(externalDecl = Absyn.EXTERNALDECL(funcName = NONE,lang = lang,output_ = NONE,annotation_ = ann),annotation_ = ann2),_)
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

protected function getExtlangStr "function: getExtlangStr
 
  Prettyprints the external function language string to a string.
"
  input Option<String> inStringOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStringOption)
    local Ident res,str;
    case (NONE) then ""; 
    case (SOME(str))
      equation 
        res = Util.stringAppendList({"\"",str,"\""});
      then
        res;
  end matchcontinue;
end getExtlangStr;

protected function printElementitems "function: printElementitems
 
  Print a list of ElementItems to the Print buffer.
"
  input list<Absyn.ElementItem> elts;
algorithm 
  Print.printBuf("[");
  printElementitems2(elts);
  Print.printBuf("]");
end printElementitems;

protected function printElementitems2 "function: printElementitems2
  
  Helper function to print_elementitems
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
algorithm 
  _:=
  matchcontinue (inAbsynElementItemLst)
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

protected function printAnnotation "function: printAnnotation
 
  Prints an annotation to the Print buffer.
"
  input Absyn.Annotation inAnnotation;
algorithm 
  _:=
  matchcontinue (inAnnotation)
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

protected function unparseElementitemStrLst "function: unparseElementitemStrLst
 
  Prettyprints a list of ElementItem to a string.
"
  input Integer inInteger;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger,inAbsynElementItemLst)
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

public function unparseElementitemStr "function: unparseElementitemStr
 
  Prettyprints and ElementItem.
"
  input Integer inInteger;
  input Absyn.ElementItem inElementItem;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger,inElementItem)
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

protected function unparseAnnotationOptionSemi "function: unparseAnnotationOptionSemi
 
  Prettyprint an annotation and a semicolon if annoation present.
"
  input Integer inInteger;
  input Option<Absyn.Annotation> inAbsynAnnotationOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger,inAbsynAnnotationOption)
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

public function unparseAnnotationOption "function: unparseAnnotationOption
 
  Prettyprint an annotation.
"
  input Integer inInteger;
  input Option<Absyn.Annotation> inAbsynAnnotationOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger,inAbsynAnnotationOption)
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
      Boolean final_;
      Option<Absyn.RedeclareKeywords> repl;
      Absyn.InnerOuter inout;
      Ident name,text;
      Absyn.ElementSpec spec;
      Absyn.Info info;
    case (Absyn.ELEMENT(final_ = final_,redeclareKeywords = repl,innerOuter = inout,name = name,specification = spec,info = info,constrainClass = NONE))
      equation 
        Print.printBuf("Absyn.ELEMENT(");
        printBool(final_);
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
    case (Absyn.ELEMENT(final_ = final_,redeclareKeywords = repl,innerOuter = inout,name = name,specification = spec,info = info,constrainClass = SOME(_)))
      equation 
        Print.printBuf("Absyn.ELEMENT(");
        printBool(final_);
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
      Boolean final_;
      Absyn.RedeclareKeywords repl;
      Absyn.InnerOuter inout;
      Absyn.ElementSpec spec;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
    case (i,Absyn.ELEMENT(final_ = final_,redeclareKeywords = SOME(repl),innerOuter = inout,specification = spec,info = info,constrainClass = constr))
      equation 
        s1 = selectString(final_, "final ", "");
        s2 = unparseRedeclarekeywords(repl);
        s3 = unparseInnerouterStr(inout);
        s4 = unparseElementspecStr(i, spec, s1, s2, s3);
        s5 = unparseConstrainclassOptStr(constr);
        str = Util.stringAppendList({s4,s5,";"});
      then
        str;
    case (i,Absyn.ELEMENT(final_ = final_,redeclareKeywords = NONE,innerOuter = inout,specification = spec,info = info,constrainClass = constr))
      equation 
        s1 = selectString(final_, "final ", "");
        s3 = unparseInnerouterStr(inout);
        s4 = unparseElementspecStr(i, spec, s1, "", s3);
        s5 = unparseConstrainclassOptStr(constr);
        str = Util.stringAppendList({s4,s5,";"});
      then
        str;
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
  end matchcontinue;
end unparseElementStr;

protected function unparseConstrainclassOptStr "function: unparseConstrainclassOptStr
  author: PA
 
  This function prettyprints a ConstrainClass option to a string.
"
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
        res = unparseConstrainclassStr(constr);
      then
        res;
  end matchcontinue;
end unparseConstrainclassOptStr;

protected function unparseConstrainclassStr "function: unparseConstrainclassStr
  author: PA
 
  This function prettyprints a ConstrainClass to a string.
"
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
        s1 = unparseElementspecStr(0, spec, "", "", "");
        s2 = unparseCommentOption(cmt);
        res = stringAppend(s1, s2);
      then
        res;
  end matchcontinue;
end unparseConstrainclassStr;

protected function printInnerouter "function: printInnerouter
 
  Prints the inner or outer keyword to the Print buffer.
"
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

protected function unparseInnerouterStr "function: unparseInnerouterStr
 
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

public function printElementspec "function: printElementspec
 
  Prints the ElementSpec to the Print buffer.
"
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
    case (Absyn.CLASSDEF(replaceable_ = repl,class_ = cl))
      equation 
        Print.printBuf("Absyn.CLASSDEF(");
        printBool(repl);
        Print.printBuf(", ");
        printClass(cl);
        Print.printBuf(")");
      then
        ();
    case (Absyn.EXTENDS(path = p,elementArg = l))
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

protected function unparseElementspecStr "function: unparseElementspecStr
 
  Prettyprints the ElementSpec to a string.
"
  input Integer inInteger1;
  input Absyn.ElementSpec inElementSpec2;
  input String inString3;
  input String inString4;
  input String inString5;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger1,inElementSpec2,inString3,inString4,inString5)
    local
      Ident str,f,r,io,s1,s2,is,s3,ad;
      Integer i,indent;
      Boolean repl;
      Absyn.Class cl;
      Absyn.Path p;
      list<Absyn.ElementArg> l;
      Absyn.ElementAttributes attr;
      Absyn.TypeSpec t;
      list<Absyn.ComponentItem> cs;
    case (i,Absyn.CLASSDEF(replaceable_ = repl,class_ = cl),f,r,io) /* indent */ 
      equation 
        str = unparseClassStr(i, cl, f, r, io);
      then
        str;
    case (i,Absyn.EXTENDS(path = p,elementArg = {}),f,r,io)
      equation 
        s1 = Absyn.pathString(p);
        s2 = stringAppend("extends ", s1);
        is = indentStr(i);
        str = Util.stringAppendList({is,f,r,io,s2});
      then
        str;
    case (i,Absyn.EXTENDS(path = p,elementArg = l),f,r,io)
      equation 
        s1 = Absyn.pathString(p);
        s2 = stringAppend("extends ", s1);
        s3 = getStringList(l, unparseElementArgStr, ",");
        is = indentStr(i);
        str = Util.stringAppendList({is,f,r,io,s2,"(",s3,")"});
      then
        str;
    case (i,Absyn.COMPONENTS(attributes = attr,typeSpec = t,components = cs),f,r,io)
      equation 
        s1 = unparseTypeSpec(t);
        s2 = unparseElementattrStr(attr);
        ad = unparseArraydimInAttr(attr);
        s3 = getStringList(cs, unparseComponentitemStr, ",");
        is = indentStr(i);
        str = Util.stringAppendList({is,f,r,io,s2,s1,ad," ",s3});
      then
        str;
    case (indent,Absyn.IMPORT(import_ = i),f,r,io)
      local Absyn.Import i;
      equation 
        s1 = unparseImportStr(i);
        s2 = stringAppend("import ", s1);
        is = indentStr(indent);
        str = Util.stringAppendList({is,f,r,io,s2});
      then
        str;
    case (_,_,_,_,_)
      equation 
        Print.printBuf(" ##ERROR## ");
      then
        "";
  end matchcontinue;
end unparseElementspecStr;

public function printImport "function: printImport
 
  Prints an Import to the Print buffer.
"
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

public function unparseImportStr "function: unparseImportStr
 
  Prettyprints an Import to a string.
"
  input Absyn.Import inImport;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inImport)
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
      Boolean fl;
      Absyn.Variability var;
      Absyn.Direction dir;
      list<Absyn.Subscript> adim;
    case (Absyn.ATTR(flow_ = fl,variability = var,direction = dir,arrayDim = adim))
      equation 
        Print.printBuf("Absyn.ATTR(");
        printBool(fl);
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
      Ident fs,vs,ds,str;
      Boolean fl;
      Absyn.Variability var;
      Absyn.Direction dir;
      list<Absyn.Subscript> adim;
    case (Absyn.ATTR(flow_ = fl,variability = var,direction = dir,arrayDim = adim))
      equation 
        fs = selectString(fl, "flow ", "");
        vs = unparseVariabilitySymbolStr(var);
        ds = unparseDirectionSymbolStr(dir);
        str = Util.stringAppendList({fs,vs,ds});
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
        s3 = unparseCommentOption(cmtopt);
        s2 = unparseComponentCondition(optcond);
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
        Print.printBuf("NONE");
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

protected function printSubscriptStr "function: printSubscriptStr
 
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
        Print.printBuf("NONE");
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

protected function unparseOptModificationStr "function: unparseOptModificationStr
 
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
    case (Absyn.CLASSMOD(elementArgLst = l,expOption = e))
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
        s1 = getStringList(l, unparseElementArgStr, ",");
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
        str = stringAppend("=", s1);
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
      Ident i;
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
    case Absyn.EQ_FOR(forVariable = i,forExp = e,forEquations = el)
      equation 
        Print.printBuf("FOR ");
        Print.printBuf(i);
        Print.printBuf(" in ");
        printExp(e);
        Print.printBuf(" {");
        printListDebug("print_equation", el, printEquationitem, ";");
        Print.printBuf("}");
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

protected function unparseEquationStr "function: unparseEquationStr
 
  Prettyprints an Equation to a string.
"
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
      list<Absyn.EquationItem> tb,fb,el,eql;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> eb,eqlelse;
      Absyn.FunctionArgs fargs;
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
        str = Util.stringAppendList({is,s1,"=",s2});
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
    case (indent,Absyn.EQ_FOR(forVariable = i,forExp = e,forEquations = el))
      local Ident i;
      equation 
        s1 = printExpStr(e);
        s2 = unparseEquationitemStrLst(indent, el, ";\n");
        is = indentStr(indent);
        str = Util.stringAppendList({is,"for ",i," in ",s1," loop\n",s2,"\n",is,"end for"});
      then
        str;
    case (i,Absyn.EQ_NORETCALL(functionName = cref,functionArgs = fargs))
      equation 
        s2 = printFunctionArgsStr(fargs);
        id = printComponentRefStr(cref);
        str = Util.stringAppendList({id,"(",s2,")"});
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
    case (_,_)
      equation 
        Print.printBuf(" ** Failure! UNKNOWN EQUATION ** ");
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

public function printAlgorithm "function: printAlgorithm
 
  Prints an Algorithm to the Print buffer.
"
  input Absyn.Algorithm inAlgorithm;
algorithm 
  _:=
  matchcontinue (inAlgorithm)
    local
      Absyn.ComponentRef cr;
      Absyn.Exp exp,e1,e2,e, assignComp;
      list<Absyn.AlgorithmItem> tb,fb,el,al;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> eb;
      Ident i;
    case (Absyn.ALG_ASSIGN(assignComponent = assignComp,value = exp))
      equation 
        Print.printBuf("ALG_ASSIGN(");
        printExp(assignComp);
        Print.printBuf(" := ");
        printExp(exp);
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
    case Absyn.ALG_FOR(forVariable = i,forStmt = e,forBody = el)
      equation 
        Print.printBuf("FOR ");
        Print.printBuf(i);
        Print.printBuf(" in ");
        printExp(e);
        Print.printBuf(" {");
        printListDebug("print_algorithm", el, printAlgorithmitem, ";");
        Print.printBuf("}");
      then
        ();
    case Absyn.ALG_WHILE(whileStmt = e,whileBody = al)
      equation 
        Print.printBuf("WHILE ");
        printExp(e);
        Print.printBuf(" {");
        printListDebug("print_algorithm", al, printAlgorithmitem, ";");
        Print.printBuf("}");
      then
        ();
    case Absyn.ALG_WHEN_A(whenStmt = e,whenBody = al,elseWhenAlgorithmBranch = el) /* rule	Print.print_buf \"WHEN_E \" & print_exp(e) &
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
    case (ident,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_FOR(forVariable = i,forStmt = e,forBody = el),comment = optcmt)) /* ALG_FOR */ 
      local Ident i;
      equation 
        s1 = printExpStr(e);
        ident_1 = ident + 1;
        s2 = unparseAlgorithmStrLst(ident_1, el, "\n");
        s3 = unparseCommentOption(optcmt);
        is = indentStr(ident);
        str = Util.stringAppendList(
          {is,"for ",i," in ",s1," loop\n",is,s2,"\n",is,"end for",s3,
          ";"});
      then
        str;
    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_WHILE(whileStmt = e,whileBody = al),comment = optcmt)) /* ALG_WHILE */ 
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
    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_WHEN_A(whenStmt = e,whenBody = al,elseWhenAlgorithmBranch = al2),comment = optcmt)) /* ALG_WHEN_A */ 
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
      then
        "return;";
    case (i,Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_BREAK(),comment = optcmt)) /* ALG_BREAK */ 
      then
        "break;";
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
    case (Absyn.CREF(componentReg = c))
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
      Absyn.Exp exp,iterexp;
      Ident id;
    case Absyn.FUNCTIONARGS(args = expargs,argNames = nargs)
      equation 
        Print.printBuf("FUNCTIONARGS(");
        printListDebug("print_exp", expargs, printExp, ", ");
        Print.printBuf(", ");
        printListDebug("print_namedarg", nargs, printNamedArg, ", ");
        Print.printBuf(")");
      then
        ();
    case Absyn.FOR_ITER_FARG(from = exp,var = id,to = iterexp)
      equation 
        Print.printBuf("FOR_ITER_FARG(");
        printExp(exp);
        Print.printBuf(", ");
        Print.printBuf(id);
        Print.printBuf(", ");
        printExp(iterexp);
        Print.printBuf(")");
      then
        ();
  end matchcontinue;
end printFunctionArgs;

protected function printFunctionArgsStr "function: printFunctionArgsStr
 
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
    case Absyn.FOR_ITER_FARG(from = exp,var = id,to = iterexp)
      equation 
        estr = printExpStr(exp);
        istr = printExpStr(iterexp);
        str = Util.stringAppendList({estr," for ",id," in ",istr});
      then
        str;
  end matchcontinue;
end printFunctionArgsStr;

public function printNamedArg "function: printNamedArg
 
  Print NamedArg to the Print buffer.
"
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
        Print.printBuf("=");
        printExp(e);
      then
        ();
  end matchcontinue;
end printNamedArg;

protected function printNamedArgStr "function: printNamedArgStr
 
  Prettyprint NamedArg to a string.
"
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
        s1 = stringAppend(ident, "=");
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
    case (Absyn.CREF(componentReg = _)) then 0; 
    case (Absyn.END()) then 0; 
    case (Absyn.CALL(function_ = _)) then 0; 
    case (Absyn.ARRAY(arrayExp = _)) then 0; 
    case (Absyn.MATRIX(matrix = _)) then 0; 
    case (Absyn.BINARY(op = Absyn.POW())) then 1; 
    case (Absyn.BINARY(op = Absyn.DIV())) then 2; 
    case (Absyn.BINARY(op = Absyn.MUL())) then 3; 
    case (Absyn.UNARY(op = Absyn.UPLUS())) then 4; 
    case (Absyn.UNARY(op = Absyn.UMINUS())) then 4; 
    case (Absyn.BINARY(op = Absyn.ADD())) then 5; 
    case (Absyn.BINARY(op = Absyn.SUB())) then 5; 
    case (Absyn.RELATION(op = Absyn.LESS())) then 6; 
    case (Absyn.RELATION(op = Absyn.LESSEQ())) then 6; 
    case (Absyn.RELATION(op = Absyn.GREATER())) then 6; 
    case (Absyn.RELATION(op = Absyn.GREATEREQ())) then 6; 
    case (Absyn.RELATION(op = Absyn.EQUAL())) then 6; 
    case (Absyn.RELATION(op = Absyn.NEQUAL())) then 6; 
    case (Absyn.LUNARY(op = Absyn.NOT())) then 7; 
    case (Absyn.LBINARY(op = Absyn.AND())) then 8; 
    case (Absyn.LBINARY(op = Absyn.OR())) then 9; 
    case (Absyn.RANGE(start = _)) then 10; 
    case (Absyn.IFEXP(ifExp = _)) then 11; 
    case (Absyn.TUPLE(expressions = _)) then 12;  /* Not valid in inner expressions, only included here for completeness */ 
    case (_) then 13; 
  end matchcontinue;
end expPriority;


protected function parenthesize "function: parenthesize
 
  Adds parentheisis to a string if expression and parent expression 
  priorities requires it.
"
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


public function printExpStr "function: print_exp
 
  This function prints a complete expression.
"
  input Absyn.Exp inExp;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExp)
    local
      String s,s_1,s_2,sym,s1,s2,s1_1,s2_1,cs,ts,fs,cs_1,ts_1,fs_1,el,str,argsstr,s3,s3_1,res,res_1;
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
    case (Absyn.CREF(componentReg = c))
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
        s4 = unparseElementitemStrLst(3, localDecls);
        s5 = getStringList(cases, printCaseStr, "\n"); 
        s = Util.stringAppendList({s1, " ", s2, s3, "\n\tlocal ", s3, "\n\t", s4, s5, "\n\tend ", s1});
      then
        s;              
    case (_) then "#UNKNOWN EXPRESSION#"; 
  end matchcontinue;
end printExpStr;

public function printCaseStr "
MetaModelica construct printing 
@author Adrian Pop "
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
    case Absyn.CASE(p, l, eq, r, c)
      equation
        s1 = printExpStr(p);
        s2 = unparseElementitemStrLst(4, l);
        s3 = unparseEquationitemStrLst(4, eq, ";\n");
        s4 = printExpStr(r);        
        s = Util.stringAppendList({"\n\tcase (", s1, ")\n\tlocal ", s2, "\n\t", s3, "\n\tthen ", s4, ";"});
      then s;
    case Absyn.ELSE(l, eq, r, c)
      equation
        s2 = unparseElementitemStrLst(4, l);
        s3 = unparseEquationitemStrLst(4, eq, ";\n");
        s4 = printExpStr(r);        
        s = Util.stringAppendList({"\n\telse", "\n\t", s2, "\n\tlocal ", s3, "\n\tthen ", s4, ";"});
      then s;
  end matchcontinue;
end printCaseStr;

public function printCodeStr "function: printCodeStr
 
   Prettyprint Code to a string.
"
  input Absyn.CodeNode inCode;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inCode)
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

protected function printElseifStr "function: print_eleseif_str
 
  Prettyprint elseif to a string
"
  input list<tuple<Absyn.Exp, Absyn.Exp>> inTplAbsynExpAbsynExpLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inTplAbsynExpAbsynExpLst)
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

protected function printRowStr "function: printRowStr
 
  Prettyprint a list of expressions to a string.
"
  input list<Absyn.Exp> es;
  output String s;
algorithm 
  s := printListStr(es, printExpStr, ",");
end printRowStr;

protected function printListStr "function: printListStr
 
  Same as print_list, except it returns a string
  instead of printing
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

public function opSymbol "function: opSymbol
 
  Make a string describing different operators.
"
  input Absyn.Operator inOperator;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inOperator)
    case (Absyn.ADD()) then " + "; 
    case (Absyn.SUB()) then " - "; 
    case (Absyn.MUL()) then "*"; 
    case (Absyn.DIV()) then "/"; 
    case (Absyn.POW()) then "^"; 
    case (Absyn.UMINUS()) then "-"; 
    case (Absyn.UPLUS()) then "+"; 
    case (Absyn.AND()) then " and "; 
    case (Absyn.OR()) then " or "; 
    case (Absyn.NOT()) then "not "; 
    case (Absyn.LESS()) then " < "; 
    case (Absyn.LESSEQ()) then " <= "; 
    case (Absyn.GREATER()) then " > "; 
    case (Absyn.GREATEREQ()) then " >= "; 
    case (Absyn.EQUAL()) then " == "; 
    case (Absyn.NEQUAL()) then " <> "; 
  end matchcontinue;
end opSymbol;

protected function dumpOpSymbol "function: dumpOpSymbol
 
  Make a string describing different operators.
"
  input Absyn.Operator inOperator;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inOperator)
    case (Absyn.ADD()) then "Absyn.ADD"; 
    case (Absyn.SUB()) then "Absyn.SUB"; 
    case (Absyn.MUL()) then "Absyn.MUL"; 
    case (Absyn.DIV()) then "Absyn.DIV"; 
    case (Absyn.POW()) then "Absyn.POW"; 
    case (Absyn.UMINUS()) then "Absyn.UMINUS"; 
    case (Absyn.UPLUS()) then "Absyn.UPLUS"; 
    case (Absyn.AND()) then "Absyn.AND"; 
    case (Absyn.OR()) then "Absyn.OR"; 
    case (Absyn.NOT()) then "Absyn.NOT"; 
    case (Absyn.LESS()) then "Absyn.LESS"; 
    case (Absyn.LESSEQ()) then "Absyn.LESSEQ"; 
    case (Absyn.GREATER()) then "Absyn.GREATER"; 
    case (Absyn.GREATEREQ()) then "Absyn.GREATEREQ"; 
    case (Absyn.EQUAL()) then "Absyn.EQUAL"; 
    case (Absyn.NEQUAL()) then "Absyn.NEQUAL"; 
  end matchcontinue;
end dumpOpSymbol;

public function selectString "- Utility functions
 
  These are utility functions used in some of the other
  functions.
  function: selectString
 
  Select one of the two strings depending on boolean value.
"
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
        Print.printBuf("NONE");
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
        Print.printBuf("NONE");
      then
        ();
    case (SOME(s))
      equation 
        str = Util.stringAppendList({"SOME( \"",s,"\")"});
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
end Dump;

