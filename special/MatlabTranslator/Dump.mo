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

encapsulated package Dump
" file:        Dump.mo
  package:     Dump
  description: debug printing

  RCS: $Id: Dump.mo 24752 2015-02-24 20:07:39Z sjoelund.se $

  Printing routines for debugging of the AST.  These functions do
  nothing but print the data structures to the standard output.

  The main entrypoint for this module is the function Dump.dump
  which takes an entire program as an argument, and prints it all
  in Modelica source form. The other interface functions can be
  used to print smaller portions of a program."

// public imports
import Absyn;

// protected imports
protected
import AbsynDumpTpl;
import Config;
import Error;
import List;
import Print;
import Tpl;
import Util;

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
  input Boolean markup = false "
    Used by MathCore, and dependencies to other modules requires this to also be in OpenModelica.
    Contact peter.aronsson@mathcore.com for an explanation.

    Note: This will be used for a different purpose in OpenModelica once we redesign Dump to use templates
          ... by sending in DumpOptions (for example to add markup, etc)
    ";
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dump, inProgram);
end unparseStr;

public function unparseClassList
  "Prettyprints a list of classes"
  input list<Absyn.Class> inClasses;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dump, Absyn.PROGRAM(inClasses, Absyn.TOP()));
end unparseClassList;

public function unparseClassStr
  "Prettyprints a Class."
  input Absyn.Class inClass;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpClass, inClass);
end unparseClassStr;

public function unparseWithin
  "Prettyprints a within statement."
  input Absyn.Within inWithin;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpWithin, inWithin);
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

    case Absyn.CLASS(partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r)
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
  input Option<Absyn.Comment> inComment;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpCommentOpt, inComment);
end unparseCommentOption;

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
  outString := Tpl.tplString(AbsynDumpTpl.dumpRestriction, inRestriction);
end unparseRestrictionStr;

public function printInfo
"author: adrpo, 2006-02-05
  Dumps an Info to the Print buffer."
  input SourceInfo inInfo;
algorithm
  _ := match (inInfo)
    local
      String s1,s2,s3,s4,filename;
      Boolean isReadOnly;
      Integer sline,scol,eline,ecol;
    case (SOURCEINFO(fileName = filename,isReadOnly = isReadOnly,
                     lineNumberStart = sline,columnNumberStart = scol,
                     lineNumberEnd = eline,columnNumberEnd = ecol))
      equation
        Print.printBuf("SOURCEINFO(\"");
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
  input SourceInfo inInfo;
  output String outString;
algorithm
  outString:=
  match (inInfo)
    local
      String s1,s2,s3,s4,s5,str,filename;
      Boolean isReadOnly;
      Integer sline,scol,eline,ecol;
    case (SOURCEINFO(fileName = filename,isReadOnly = isReadOnly,
                     lineNumberStart = sline,columnNumberStart = scol,
                     lineNumberEnd = eline,columnNumberEnd = ecol))
      equation
        s1 = selectString(isReadOnly, "readonly", "writable");
        s2 = intString(sline);
        s3 = intString(scol);
        s4 = intString(eline);
        s5 = intString(ecol);
        str = stringAppendList({"SOURCEINFO(\"",filename,"\", ",s1,", ",s2,", ",s3,", ",s4,", ",s5,")\n"});
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
      SourceInfo info;
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
    case (Absyn.OVERLOAD())
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
    // BTH
    case Absyn.R_PREDEFINED_CLOCK() equation Print.printBuf("Absyn.R_PREDEFINED_CLOCK"); then ();
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
    case (Absyn.REDECLARATION(finalPrefix = f,elementSpec = spec))
      equation
        Print.printBuf("Absyn.REDECLARATION(");
        printBool(f);
        printElementspec(spec);
        Print.printBuf(",_)");
      then
        ();
  end match;
end printElementArg;

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
        Print.printBuf("Error Dump.printElementitems2\n");
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

public function unparseElementArgStr "Prettyprints an Absyn.ElementArg"
  input Absyn.ElementArg inElementArg;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpElementArg,inElementArg);
end unparseElementArgStr;

public function unparseElementItemStr
  "Prettyprints and ElementItem."
  input Absyn.ElementItem inElementItem;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpElementItem, inElementItem);
end unparseElementItemStr;

public function unparseAnnotation
  "Prettyprint an annotation."
  input Absyn.Annotation inAnnotation;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpAnnotation, inAnnotation);
end unparseAnnotation;

public function unparseAnnotationOption
  "Prettyprint an annotation."
  input Option<Absyn.Annotation> inAbsynAnnotation;
  output String outString;
algorithm
  outString := match (inAbsynAnnotation)
    local
      Absyn.Annotation ann;
    case SOME(ann) then unparseAnnotation(ann);
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
      SourceInfo info;
    case (Absyn.ELEMENT(finalPrefix = finalPrefix,innerOuter = inout,
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
    case (Absyn.ELEMENT(finalPrefix = finalPrefix,innerOuter = inout,
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
    else
      equation
        Print.printBuf(" ##ERROR## ");
      then
        ();
  end matchcontinue;
end printElementspec;

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
      then rename + " = " + name;
  end match;
end unparseGroupImport;

public function unparseImportStr
  "Prettyprints an Import to a string."
  input Absyn.Import inImport;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpImport, inImport);
end unparseImportStr;

protected function printElementattr "Prints ElementAttributes to the Print buffer."
  input Absyn.ElementAttributes inElementAttributes;
algorithm
  _ := matchcontinue (inElementAttributes)
    local
      String vs,ds,ps;
      Boolean fl,st;
      Absyn.Parallelism par;
      Absyn.Variability var;
      Absyn.Direction dir;
      list<Absyn.Subscript> adim;

    case (Absyn.ATTR(flowPrefix = fl,streamPrefix=st,parallelism= par,variability = var,direction = dir,arrayDim = adim))
      equation
        Print.printBuf("Absyn.ATTR(");
        printBool(fl);
        Print.printBuf(", ");
        printBool(st);
        Print.printBuf(", ");
        ps =parallelSymbol(par);
        Print.printBuf(ps);
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

    else
      equation
        Print.printBuf(" ##ERROR## print_elementattr");
      then
        ();
  end matchcontinue;
end printElementattr;

public function parallelSymbol "
  Returns a string for the Variability.
"
  input Absyn.Parallelism inparallel;
  output String outString;
algorithm
  outString:=
  match (inparallel)
    case (Absyn.NON_PARALLEL()) then "Absyn.NON_PARALLEL";
    case (Absyn.PARGLOBAL()) then "Absyn.PARGLOBAL";
    case (Absyn.PARLOCAL()) then "Absyn.PARLOCAL";
  end match;
end parallelSymbol;


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
    case (Absyn.COMPONENTITEM(component = c,comment = optcmt))
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

public function unparseComponentCondition "Prints a ComponentCondition option to a string."
  input Option<Absyn.ComponentCondition> inComponentCondition;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpComponentCondition, inComponentCondition);
end unparseComponentCondition;

protected function printArraydimOpt "
  Prints an ArrayDim option to the Print buffer.
"
  input Option<Absyn.ArrayDim> inAbsynArrayDimOption;
algorithm
  _:=
  match (inAbsynArrayDimOption)
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
  end match;
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
    else
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

public function unparseModificationStr
  "Prettyprints a Modification to a string."
  input Absyn.Modification inModification;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpModification, inModification);
end unparseModificationStr;

public function equationName
  input Absyn.Equation eq;
  output String name;
algorithm
  name := match eq
    case Absyn.EQ_IF() then "if";
    case Absyn.EQ_EQUALS() then "equals";
    case Absyn.EQ_CONNECT() then "connect";
    case Absyn.EQ_WHEN_E() then "when";
    case Absyn.EQ_NORETCALL() then "function call";
    case Absyn.EQ_FAILURE() then "failure";
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
        Print.printBuf(printComponentRefStr(cr) + "(");
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

    else
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

public function unparseClassPart
  "Prettyprints an Equation to a string."
  input Absyn.ClassPart classPart;
  output String outString;
algorithm
  outString := Tpl.tplString2(AbsynDumpTpl.dumpClassPart, classPart, 0);
end unparseClassPart;

public function unparseEquationStr
  "Prettyprints an Equation to a string."
  input Absyn.Equation inEquation;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpEquation, inEquation);
end unparseEquationStr;

public function unparseEquationItemStr
  "Prettyprints an EquationItem to a string."
  input Absyn.EquationItem inEquation;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpEquationItem, inEquation);
end unparseEquationItemStr;

public function unparseEquationItemStrLst
  "Prettyprints and EquationItem list to a string."
  input list<Absyn.EquationItem> inEquationItems;
  input String inSeparator;
  output String outString;
algorithm
  outString := stringDelimitList(
    List.map(inEquationItems, unparseEquationItemStr), inSeparator);
end unparseEquationItemStrLst;

protected function printEqElseif "Prints an Elseif branch to the Print buffer."
  input tuple<Absyn.Exp, list<Absyn.EquationItem>> inElseIfBranch;
protected
  Absyn.Exp e;
  list<Absyn.EquationItem> el;
algorithm
  (e, el) := inElseIfBranch;
  Print.printBuf(" ELSEIF ");
  printExp(e);
  Print.printBuf(" THEN ");
  printListDebug("print_eq_elseif", el, printEquationitem, ";");
end printEqElseif;

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
        Print.printBuf(printComponentRefStr(cr) + "(");
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

    case Absyn.ALG_WHEN_A(boolExpr = e,whenBody = al)
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

    else
      equation
        Print.printBuf(" ** UNKNOWN ALGORITHM CLAUSE ** ");
      then
        ();
  end matchcontinue;
end printAlgorithm;

public function unparseAlgorithmStrLst
  "Prettyprints an AlgorithmItem list to a string."
  input list<Absyn.AlgorithmItem> inAlgorithmItems;
  input String inSeparator;
  output String outString;
algorithm
  outString := stringDelimitList(
    List.map(inAlgorithmItems, unparseAlgorithmStr), inSeparator);
end unparseAlgorithmStrLst;

public function unparseAlgorithmStr
  "Helper function to unparseAlgorithmStr"
  input Absyn.AlgorithmItem inAlgorithmItem;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpAlgorithmItem, inAlgorithmItem);
end unparseAlgorithmStr;

protected function printAlgElseif "Prints an algorithm elseif branch to the Print buffer."
  input tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> inElseIfBranch;
protected
  Absyn.Exp e;
  list<Absyn.AlgorithmItem> el;
algorithm
  (e, el) := inElseIfBranch;
  Print.printBuf(" ELSEIF ");
  printExp(e);
  Print.printBuf(" THEN ");
  printListDebug("print_alg_elseif", el, printAlgorithmitem, ";");
end printAlgElseif;

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

    case Absyn.WILD() then if Config.acceptMetaModelicaGrammar() then "_" else "";

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

    case (Absyn.REAL(value = s))
      equation
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

    case (Absyn.IFEXP(ifExp = cond,trueBranch = t,elseBranch = f))
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

    else
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

public function shouldParenthesize
  "Determines whether an operand in an expression needs parentheses around it."
  input Absyn.Exp inOperand;
  input Absyn.Exp inOperator;
  input Boolean inLhs;
  output Boolean outShouldParenthesize;
algorithm
  outShouldParenthesize := match(inOperand, inOperator, inLhs)
    local
      Integer diff;

    case (Absyn.UNARY(), _, _) then true;

    else
      equation
        diff = Util.intCompare(expPriority(inOperand, inLhs),
                               expPriority(inOperator, inLhs));
      then
        shouldParenthesize2(diff, inOperand, inLhs);

  end match;
end shouldParenthesize;

protected function shouldParenthesize2
  input Integer inPrioDiff;
  input Absyn.Exp inOperand;
  input Boolean inLhs;
  output Boolean outShouldParenthesize;
algorithm
  outShouldParenthesize := match(inPrioDiff, inOperand, inLhs)
    case (1, _, _) then true;
    case (0, _, false) then not isAssociativeExp(inOperand);
    else false;
  end match;
end shouldParenthesize2;

protected function isAssociativeExp
  "Determines whether the given expression represents an associative operation or not."
  input Absyn.Exp inExp;
  output Boolean outIsAssociative;
algorithm
  outIsAssociative := match(inExp)
    local
      Absyn.Operator op;

    case Absyn.BINARY(op = op) then isAssociativeOp(op);
    case Absyn.LBINARY() then true;
    else false;
  end match;
end isAssociativeExp;

protected function isAssociativeOp
  "Determines whether the given operator is associative or not."
  input Absyn.Operator inOperator;
  output Boolean outIsAssociative;
algorithm
  outIsAssociative := match(inOperator)
    case Absyn.ADD() then true;
    case Absyn.ADD_EW() then true;
    case Absyn.MUL_EW() then true;
    else false;
  end match;
end isAssociativeOp;

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
    case (Absyn.UNARY(), _) then 4;
    case (Absyn.LBINARY(op = op), _) then priorityLBinop(op);
    case (Absyn.LUNARY(), _) then 7;
    case (Absyn.RELATION(), _) then 6;
    case (Absyn.RANGE(), _) then 10;
    case (Absyn.IFEXP(), _) then 11;
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
    case Absyn.MUL() then 2;
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

    // Print parentheses around an operand if the priority of the operation is
    // less than the priority of the operand.
    case (_, _, _)
      equation
        true = shouldParenthesize(inOperand, inOperation, inLhs);
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
  outString := Tpl.tplString(AbsynDumpTpl.dumpExp, inExp);
end printExpStr;

public function printCodeStr
"Prettyprint Code to a string."
  input Absyn.CodeNode inCode;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpCodeNode, inCode);
end printCodeStr;

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
    case (true,a,_) then a;
    case (false,_,b) then b;
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
    case (_,{h},r,_)
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
  match (inTypeAOption,inFuncTypeTypeAToString,inString)
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
  end match;
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
    case (NONE(),_,_) then "";
  end match;
end getOptionWithConcatStr;

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

public function unparseTypeSpec
  input Absyn.TypeSpec inTypeSpec;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpTypeSpec, inTypeSpec);
end unparseTypeSpec;

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
    case Absyn.PROGRAM(classes = classes, within_ = within_)
      equation
        Print.printBuf("record Absyn.PROGRAM\nclasses = ");
        printListAsCorbaString(classes,printClassAsCorbaString,",\n");
        Print.printBuf(",\nwithin_ = ");
        printWithinAsCorbaString(within_);
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

protected function printClassAsCorbaString
  input Absyn.Class cl;
algorithm
  _ := match cl
    local
      String name;
      Boolean partialPrefix, finalPrefix, encapsulatedPrefix;
      Absyn.Restriction restriction;
      Absyn.ClassDef    body;
      SourceInfo info;
    case Absyn.CLASS(name,partialPrefix,finalPrefix,encapsulatedPrefix,restriction,body,info)
      equation
        Print.printBuf("record Absyn.CLASS name = \"");
        Print.printBuf(name);
        Print.printBuf("\", partialPrefix = ");
        Print.printBuf(boolString(partialPrefix));
        Print.printBuf(", finalPrefix = ");
        Print.printBuf(boolString(finalPrefix));
        Print.printBuf(", encapsulatedPrefix = ");
        Print.printBuf(boolString(encapsulatedPrefix));
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
  input SourceInfo info;
algorithm
  _ := match info
    local
      String fileName;
      Boolean isReadOnly;
      Integer lineNumberStart,columnNumberStart,lineNumberEnd,columnNumberEnd;
      Real lastModified;
    case SOURCEINFO(fileName,isReadOnly,lineNumberStart,columnNumberStart,lineNumberEnd,columnNumberEnd,lastModified)
      equation
        Print.printBuf("record SOURCEINFO fileName = \"");
        Print.printBuf(fileName);
        Print.printBuf("\", isReadOnly = ");
        Print.printBuf(boolString(isReadOnly));
        Print.printBuf(", lineNumberStart = ");
        Print.printBuf(intString(lineNumberStart));
        Print.printBuf(", columnNumberStart = ");
        Print.printBuf(intString(columnNumberStart));
        Print.printBuf(", lineNumberEnd = ");
        Print.printBuf(intString(lineNumberEnd));
        Print.printBuf(", columnNumberEnd = ");
        Print.printBuf(intString(columnNumberEnd));
        Print.printBuf(", lastModified = ");
        Print.printBuf(realString(lastModified));
        Print.printBuf(" end SOURCEINFO;");
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
    case Absyn.PARTS(typeVars,_,classParts,ann,optString)
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

    // BTH
    case Absyn.R_PREDEFINED_CLOCK()
      equation
        Print.printBuf("record Absyn.R_PREDEFINED_CLOCK end Absyn.R_PREDEFINED_CLOCK;");
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
      SourceInfo info;
      Option<Absyn.ConstrainClass> constrainClass;
      list<Absyn.NamedArg> args;
      Option<String> optName;
    case Absyn.ELEMENT(finalPrefix,redeclareKeywords,innerOuter,specification,info,constrainClass)
      equation
        Print.printBuf("\nrecord Absyn.ELEMENT finalPrefix = ");
        Print.printBuf(boolString(finalPrefix));
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
      SourceInfo info;
    case Absyn.CLASSDEF(replaceable_,class_)
      equation
        Print.printBuf("record Absyn.CLASSDEF replaceable_ = ");
        Print.printBuf(boolString(replaceable_));
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
      SourceInfo info;
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
      SourceInfo info;
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
      SourceInfo info;
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
        Print.printBuf(boolString(flowPrefix));
        Print.printBuf(", streamPrefix = ");
        Print.printBuf(boolString(streamPrefix));
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
      SourceInfo info;
      Absyn.Path p;
    case Absyn.MODIFICATION(finalPrefix,eachPrefix,p,modification,comment,info)
      equation
        Print.printBuf("record Absyn.MODIFICATION finalPrefix = ");
        Print.printBuf(boolString(finalPrefix));
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
        Print.printBuf(boolString(finalPrefix));
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
    case Absyn.FOR_ITER_FARG(exp,_,iterators)
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
    case Absyn.REAL(value = s)
      equation
        Print.printBuf("record Absyn.REAL value = ");
        Print.printBuf(s);
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
        Print.printBuf(boolString(b));
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
      SourceInfo patternInfo,info,resultInfo;
      list<Absyn.ElementItem> localDecls;
      Absyn.ClassPart classPart;
      Absyn.Exp result;
      Option<String> comment;
    case Absyn.CASE(pattern,patternGuard,patternInfo,localDecls,classPart,result,resultInfo,comment,info)
      equation
        Print.printBuf("record Absyn.CASE pattern = ");
        printExpAsCorbaString(pattern);
        Print.printBuf(", patternGuard = ");
        printOption(patternGuard,printExpAsCorbaString);
        Print.printBuf(", patternInfo = ");
        printInfoAsCorbaString(patternInfo);
        Print.printBuf(", localDecls = ");
        printListAsCorbaString(localDecls, printElementItemAsCorbaString, ",");
        Print.printBuf(", classPart = ");
        printClassPartAsCorbaString(classPart);
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
    case Absyn.ELSE(localDecls,classPart,result,resultInfo,comment,info)
      equation
        Print.printBuf("record Absyn.ELSE localDecls = ");
        printListAsCorbaString(localDecls, printElementItemAsCorbaString, ",");
        Print.printBuf(", classPart = ");
        printClassPartAsCorbaString(classPart);
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
        Print.printBuf(boolString(boolean));
        Print.printBuf(", equationItemLst = ");
        printListAsCorbaString(equationItemLst, printEquationItemAsCorbaString, ",");
        Print.printBuf(" end Absyn.C_EQUATIONSECTION;");
      then ();
    case Absyn.C_ALGORITHMSECTION(boolean, algorithmItemLst)
      equation
        Print.printBuf("record Absyn.C_ALGORITHMSECTION boolean = ");
        Print.printBuf(boolString(boolean));
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

annotation(__OpenModelica_Interface="frontend");
end Dump;
