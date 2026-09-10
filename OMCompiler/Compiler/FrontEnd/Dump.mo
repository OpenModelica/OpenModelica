/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
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


  Printing routines for debugging of the AST.  These functions do
  nothing but print the data structures to the standard output.

  The main entrypoint for this module is the function Dump.dump
  which takes an entire program as an argument, and prints it all
  in Modelica source form. The other interface functions can be
  used to print smaller portions of a program."

// public imports
import Absyn;
import File;
import File.Escape;

// protected imports
protected

import AbsynDumpTpl;
import Config;
import Flags;
import FlagsUtil;
import List;
import Print;
import Tpl;
import Util;

public

uniontype DumpOptions
  record DUMPOPTIONS
    String fileName;
  end DUMPOPTIONS;
end DumpOptions;

constant DumpOptions defaultDumpOptions = DUMPOPTIONS("");

function boolUnparseFileFromInfo "Returns true if the filename in the SOURCEINFO should be unparsed"
  input SourceInfo info;
  input DumpOptions options;
  output Boolean b;
algorithm
  b := match (options,info)
    case (DUMPOPTIONS(fileName=""),_) then true; // The default is to not filter
    case (DUMPOPTIONS(),SOURCEINFO()) then options.fileName == info.fileName;
  end match;
end boolUnparseFileFromInfo;

public function unparseStr
"Prettyprints the Program, i.e. the whole AST, to a string."
  input Absyn.Program inProgram;
  input Boolean markup = false "
    Used by MathCore, and dependencies to other modules requires this to also be in OpenModelica.
    Contact peter.aronsson@mathcore.com for an explanation.

    Note: This will be used for a different purpose in OpenModelica once we redesign Dump to use templates
          ... by sending in DumpOptions (for example to add markup, etc)
    ";
  input DumpOptions options = defaultDumpOptions;
  output String outString;
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString2(AbsynDumpTpl.dump, inProgram, options);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
end unparseStr;

public function unparseClassList
  "Prettyprints a list of classes"
  input list<Absyn.Class> inClasses;
  output String outString;
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString2(AbsynDumpTpl.dump, Absyn.PROGRAM(inClasses, Absyn.TOP()), defaultDumpOptions);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
end unparseClassList;

public function unparseClassStr
  "Prettyprints a Class."
  input Absyn.Class inClass;
  output String outString;
algorithm
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString3(AbsynDumpTpl.dumpClass, inClass, "", defaultDumpOptions);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
end unparseClassStr;

public function unparseWithin
  "Prettyprints a within statement."
  input Absyn.Within inWithin;
  output String outString;
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString(AbsynDumpTpl.dumpWithin, inWithin);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
end unparseWithin;

public function unparseClassAttributesStr
"Prettyprints Class attributes."
  input Absyn.Class inClass;
  output String outString;
algorithm
  outString := match inClass
    local
      String s1,s2,s2_1,s3,str;
      Boolean p,f,e;
      Absyn.Restriction r;

    case Absyn.CLASS(partialPrefix = p,finalPrefix = f,encapsulatedPrefix = e,restriction = r)
      algorithm
        s1 := if p then "partial " else "";
        s2 := if f then "final " else "";
        s2_1 := if e then "encapsulated " else "";
        s3 := unparseRestrictionStr(r);
        str := stringAppendList({s2_1,s1,s2,s3});
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

public function unparseRestrictionStr
"Prettyprints the class restriction."
  input Absyn.Restriction inRestriction;
  output String outString;
algorithm
  outString := Tpl.tplString(AbsynDumpTpl.dumpRestriction, inRestriction);
end unparseRestrictionStr;

public function unparseEachStr
"Prettyprints the each keyword."
  input Absyn.Each inEach;
  output String outString;
algorithm
  outString := match inEach
    case Absyn.EACH() then "each ";
    case Absyn.NON_EACH() then "";
  end match;
end unparseEachStr;

public function unparseElementArgStr "Prettyprints an Absyn.ElementArg"
  input Absyn.ElementArg inElementArg;
  output String outString;
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString(AbsynDumpTpl.dumpElementArg,inElementArg);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
end unparseElementArgStr;

public function shouldSeparateAfterElementArg
  input list<Absyn.ElementArg> args;
  output list<tuple<Absyn.ElementArg,Boolean>> outArgs;
protected
  Integer numNonComment=0, cur=0;
  Boolean b;
algorithm
  for arg in args loop
    numNonComment := match arg
      case Absyn.ELEMENTARGCOMMENT() then numNonComment;
      else numNonComment + 1;
    end match;
  end for;
  outArgs := {};
  for arg in args loop
    b := match arg
      case Absyn.ELEMENTARGCOMMENT() then false;
      else
        algorithm
          cur := cur + 1;
        then cur < numNonComment;
    end match;
    outArgs := (arg,b)::outArgs;
  end for;
  outArgs := listReverse(outArgs);
end shouldSeparateAfterElementArg;

public function unparseElementItemStr
  "Prettyprints and ElementItem."
  input Absyn.ElementItem inElementItem;
  output String outString;
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString2(AbsynDumpTpl.dumpElementItem, inElementItem, defaultDumpOptions);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
end unparseElementItemStr;

public function unparseAnnotation
  "Prettyprint an annotation."
  input Absyn.Annotation inAnnotation;
  output String outString;
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString(AbsynDumpTpl.dumpAnnotation, inAnnotation);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
end unparseAnnotation;

public function unparseAnnotationOption
  "Prettyprint an annotation."
  input Option<Absyn.Annotation> inAbsynAnnotation;
  output String outString;
algorithm
  outString := match inAbsynAnnotation
    local
      Absyn.Annotation ann;
    case SOME(ann) then unparseAnnotation(ann);
    else "";
  end match;
end unparseAnnotationOption;

public function unparseInnerOuterStr
  "Prettyprints the inner or outer keyword to a string."
  input Absyn.InnerOuter inInnerOuter;
  output String outString;
algorithm
  outString:= match inInnerOuter
    case Absyn.INNER() then "inner ";
    case Absyn.OUTER() then "outer ";
    case Absyn.INNER_OUTER() then "inner outer ";
    case Absyn.NOT_INNER_OUTER() then "";
  end match;
end unparseInnerOuterStr;

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
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString(AbsynDumpTpl.dumpImport, inImport);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
end unparseImportStr;

protected function unparseVariabilitySymbolStr "
  Returns a prettyprinted string of variability.
"
  input Absyn.Variability inVariability;
  output String outString;
algorithm
  outString:=
  match inVariability
    case Absyn.VAR() then "";
    case Absyn.DISCRETE() then "discrete ";
    case Absyn.PARAM() then "parameter ";
    case Absyn.CONST() then "constant ";
  end match;
end unparseVariabilitySymbolStr;

public function unparseDirectionSymbolStr "Returns a prettyprinted string of direction."
  input Absyn.Direction inDirection;
  output String outString;
algorithm
  outString:=
  match inDirection
    case Absyn.BIDIR() then "";
    case Absyn.INPUT() then "input ";
    case Absyn.OUTPUT() then "output ";
  end match;
end unparseDirectionSymbolStr;

public function directionSymbol "
  Returns a string for the direction.
"
  input Absyn.Direction inDirection;
  output String outString;
algorithm
  outString:= match inDirection
    case Absyn.BIDIR() then "";
    case Absyn.INPUT() then "input";
    case Absyn.OUTPUT() then "output";
  end match;
end directionSymbol;

public function unparseParallelismSymbolStr
  input Absyn.Parallelism inParallelism;
  output String outString;
algorithm
  outString:=
  match inParallelism
    case Absyn.NON_PARALLEL() then "";
    case Absyn.PARGLOBAL() then "parglobal ";
    case Absyn.PARLOCAL() then "parlocal ";
  end match;
end unparseParallelismSymbolStr;

public function unparseComponentCondition "Prints a ComponentCondition option to a string."
  input Option<Absyn.ComponentCondition> inComponentCondition;
  output String outString;
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString(AbsynDumpTpl.dumpComponentCondition, inComponentCondition);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
end unparseComponentCondition;

public function printArraydimStr "
  Prettyprints an ArrayDim to a string.
"
  input Absyn.ArrayDim s;
  output String str;
algorithm
  str := printSubscriptsStr(s);
end printArraydimStr;

public function printSubscriptStr "
  Prettyprints an Subscript to a string.
"
  input Absyn.Subscript inSubscript;
  output String outString;
algorithm
  outString:=
  match inSubscript
    local
      String s;
      Absyn.Exp e1;
    case Absyn.NOSUB() then ":";
    case Absyn.SUBSCRIPT(subscript = e1)
      algorithm
        s := printExpStr(e1);
      then
        s;
  end match;
end printSubscriptStr;

public function unparseModificationStr
  "Prettyprints a Modification to a string."
  input Absyn.Modification inModification;
  output String outString;
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString(AbsynDumpTpl.dumpModification, inModification);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
end unparseModificationStr;

public function equationName
  input Absyn.Equation eq;
  output String name;
algorithm
  name := match eq
    case Absyn.EQ_IF() then "if";
    case Absyn.EQ_EQUALS() then "equals";
    case Absyn.EQ_PDE() then "pde";
    case Absyn.EQ_CONNECT() then "connect";
    case Absyn.EQ_WHEN_E() then "when";
    case Absyn.EQ_NORETCALL() then "function call";
    case Absyn.EQ_FAILURE() then "failure";
  end match;
end equationName;

public function unparseClassPart
  "Prettyprints an Equation to a string."
  input Absyn.ClassPart classPart;
  output String outString;
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString3(AbsynDumpTpl.dumpClassPart, classPart, 0, defaultDumpOptions);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
end unparseClassPart;

public function unparseEquationStr
  "Prettyprints an Equation to a string."
  input Absyn.Equation inEquation;
  output String outString;
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString(AbsynDumpTpl.dumpEquation, inEquation);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
end unparseEquationStr;

public function unparseEquationItemStr
  "Prettyprints an EquationItem to a string."
  input Absyn.EquationItem inEquation;
  output String outString;
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString(AbsynDumpTpl.dumpEquationItem, inEquation);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
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
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString(AbsynDumpTpl.dumpAlgorithmItem, inAlgorithmItem);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
end unparseAlgorithmStr;

public function printComponentRefStr "Print a ComponentRef and return as a string."
  input Absyn.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := match inComponentRef
    local
      String subsstr,s_1,s,crs,s_2,s_3;
      list<Absyn.Subscript> subs;
      Absyn.ComponentRef cr;

    case Absyn.CREF_IDENT(name = s,subscripts = subs)
      algorithm
        subsstr := printSubscriptsStr(subs);
        s_1 := stringAppend(s, subsstr);
      then
        s_1;

    case Absyn.CREF_QUAL(name = s,subscripts = subs,componentRef = cr)
      algorithm
        crs := printComponentRefStr(cr);
        subsstr := printSubscriptsStr(subs);
        s_1 := stringAppend(s, subsstr);
        s_2 := stringAppend(s_1, ".");
        s_3 := stringAppend(s_2, crs);
      then
        s_3;

    case Absyn.CREF_FULLYQUALIFIED(componentRef = cr)
      algorithm
        crs := printComponentRefStr(cr);
        s_3 := stringAppend(".", crs);
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
  outString := match inAbsynSubscriptLst
    local
      String s,s_1,s_2;
      list<Absyn.Subscript> l;

    case {} then "";

    case l
      algorithm
        s := printListStr(l, printSubscriptStr, ",");
        s_1 := stringAppend("[", s);
        s_2 := stringAppend(s_1, "]");
      then
        s_2;
  end match;
end printSubscriptsStr;

public function printFunctionArgsStr "
  Prettyprint FunctionArgs to a string.
"
  input Absyn.FunctionArgs inFunctionArgs;
  output String outString;
algorithm
  outString:=
  matchcontinue inFunctionArgs
    local
      String s1,s2,s3,str,estr,istr;
      list<Absyn.Exp> expargs;
      list<Absyn.NamedArg> nargs;
      Absyn.Exp exp;
      Absyn.ForIterators iterators;
    case Absyn.FUNCTIONARGS(args = (expargs as (_ :: _)),argNames = (nargs as (_ :: _)))
      algorithm
        s1 := printListStr(expargs, printExpStr, ", ") "Both positional and named arguments" ;
        s2 := stringAppend(s1, ", ");
        s3 := printListStr(nargs, printNamedArgStr, ", ");
        str := stringAppend(s2, s3);
      then
        str;
    case Absyn.FUNCTIONARGS(args = {},argNames = nargs)
      algorithm
        str := printListStr(nargs, printNamedArgStr, ", ") "Only named arguments" ;
      then
        str;
    case Absyn.FUNCTIONARGS(args = expargs,argNames = {})
      algorithm
        str := printListStr(expargs, printExpStr, ", ") "Only positional arguments" ;
      then
        str;
    case Absyn.FOR_ITER_FARG(exp = exp,iterators = iterators)
      algorithm
        estr := printExpStr(exp);
        istr := printIteratorsStr(iterators);
        str := stringAppendList({estr," for ", istr});
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
  iteratorsStr := matchcontinue iterators
    local
      String s, s1, s2;
      Absyn.Exp guardExp,exp;
      Absyn.Ident id;
      Absyn.ForIterators rest;
      Absyn.ForIterator x;
    case {} then "";
    case {Absyn.ITERATOR(id, SOME(guardExp), SOME(exp))}
      algorithm
        s1 := printExpStr(exp);
        s2 := printExpStr(guardExp);
        s := stringAppendList({id, " guard ", s2, " in ", s1});
      then s;
    case {Absyn.ITERATOR(id, NONE(), SOME(exp))}
      algorithm
        s1 := printExpStr(exp);
        s := stringAppendList({id, " in ", s1});
      then s;
    case {Absyn.ITERATOR(id, NONE(), NONE())} then id;
    case x::rest
      algorithm
        s1 := printIteratorsStr({x});
        s2 := printIteratorsStr(rest);
        s := stringAppendList({s1, ", ", s2});
      then s;
  end matchcontinue;
end printIteratorsStr;

public function printNamedArgStr
"Prettyprint NamedArg to a string."
  input Absyn.NamedArg inNamedArg;
  output String outString;
algorithm
  outString:=
  match inNamedArg
    local
      String s1,s2,str,ident;
      Absyn.Exp e;
    case Absyn.NAMEDARG(argName = ident,argValue = e)
      algorithm
        s1 := stringAppend(ident, " = ");
        s2 := printExpStr(e);
        str := stringAppend(s1, s2);
      then
        str;
  end match;
end printNamedArgStr;

public function printNamedArgValueStr
  "Prettyprint NamedArg value to a string."
  input Absyn.NamedArg inNamedArg;
  output String outString;
algorithm
  outString:=
  match inNamedArg
    local
      String str;
      Absyn.Exp e;
    case Absyn.NAMEDARG(argValue = e)
      algorithm
        str := printExpStr(e);
      then
        str;
  end match;
end printNamedArgValueStr;

public function shouldParenthesize
  "Determines whether an operand in an expression needs parentheses around it."
  input Absyn.Exp inOperand;
  input Absyn.Exp inOperator;
  input Boolean inLhs;
  output Boolean outShouldParenthesize;
algorithm
  outShouldParenthesize := match inOperand
    local
      Integer diff;

    case Absyn.UNARY() then true;

    else
      algorithm
        diff := Util.intCompare(expPriority(inOperand, inLhs),
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
  outShouldParenthesize := match inPrioDiff
    case 1 then true;
    case 0 then if inLhs then isNonAssociativeExp(inOperand) else
                              not isAssociativeExp(inOperand);
    else false;
  end match;
end shouldParenthesize2;

protected function isAssociativeExp
  "Determines whether the given expression represents an associative operation or not."
  input Absyn.Exp inExp;
  output Boolean outIsAssociative;
algorithm
  outIsAssociative := match inExp
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
  outIsAssociative := match inOperator
    case Absyn.ADD() then true;
    case Absyn.ADD_EW() then true;
    case Absyn.MUL_EW() then true;
    else false;
  end match;
end isAssociativeOp;

protected function isNonAssociativeExp
  input Absyn.Exp exp;
  output Boolean isNonAssociative;
algorithm
  isNonAssociative := match exp
    case Absyn.BINARY() then isNonAssociativeOp(exp.op);
    else false;
  end match;
end isNonAssociativeExp;

protected function isNonAssociativeOp
  input Absyn.Operator operator;
  output Boolean isNonAssociative;
algorithm
  isNonAssociative := match operator
    case Absyn.POW() then true;
    case Absyn.POW_EW() then true;
    else false;
  end match;
end isNonAssociativeOp;

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
  outPriority := match inOp
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
  outPriority := match inOp
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
  outPriority := match inOp
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
  outString := matchcontinue inLhs
    local
      String op_str;

    // Print parentheses around an operand if the priority of the operation is
    // less than the priority of the operand.
    case _
      algorithm
        true := shouldParenthesize(inOperand, inOperation, inLhs);
        op_str := printExpStr(inOperand);
        op_str := stringAppendList({"(", op_str, ")"});
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
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString(AbsynDumpTpl.dumpExp, inExp);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
end printExpStr;

public function printCodeStr
"Prettyprint Code to a string."
  input Absyn.CodeNode inCode;
  output String outString;
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString(AbsynDumpTpl.dumpCodeNode, inCode);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
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
      algorithm
        s := r(h);
      then
        s;
    case ((h :: t),r,sep)
      algorithm
        s := r(h);
        srest := printListStr(t, r, sep);
        s_1 := stringAppend(s, sep);
        s_2 := stringAppend(s_1, srest);
      then
        s_2;
  end matchcontinue;
end printListStr;

public function opSymbol
"Make a string describing different operators."
  input Absyn.Operator inOperator;
  output String outString;
algorithm
  outString := match inOperator
    /* arithmetic operators */
    case Absyn.ADD() then " + ";
    case Absyn.SUB() then " - ";
    case Absyn.MUL() then " * ";
    case Absyn.DIV() then " / ";
    case Absyn.POW() then " ^ ";
    case Absyn.UMINUS() then "-";
    case Absyn.UPLUS() then "+";
    /* element-wise arithmetic operators */
    case Absyn.ADD_EW() then " .+ ";
    case Absyn.SUB_EW() then " .- ";
    case Absyn.MUL_EW() then " .* ";
    case Absyn.DIV_EW() then " ./ ";
    case Absyn.POW_EW() then " .^ ";
    case Absyn.UMINUS_EW() then " .-";
    case Absyn.UPLUS_EW() then " .+";
    /* logical operators */
    case Absyn.AND() then " and ";
    case Absyn.OR() then " or ";
    case Absyn.NOT() then "not ";
    /* relational operators */
    case Absyn.LESS() then " < ";
    case Absyn.LESSEQ() then " <= ";
    case Absyn.GREATER() then " > ";
    case Absyn.GREATEREQ() then " >= ";
    case Absyn.EQUAL() then " == ";
    case Absyn.NEQUAL() then " <> ";
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
  outString := match inOperator
    /* arithmetic operators */
    case Absyn.ADD() then "+";
    case Absyn.SUB() then "-";
    case Absyn.MUL() then "*";
    case Absyn.DIV() then "/";
    case Absyn.POW() then "^";
    case Absyn.UMINUS() then "-";
    case Absyn.UPLUS() then "+";
    /* element-wise arithmetic operators */
    case Absyn.ADD_EW() then "+";
    case Absyn.SUB_EW() then "-";
    case Absyn.MUL_EW() then "*";
    case Absyn.DIV_EW() then "/";
    case Absyn.POW_EW() then "^";
    case Absyn.UMINUS_EW() then "-";
    // case (Absyn.UPLUS_EW()) then "+";
    /* logical operators */
    case Absyn.AND() then "and";
    case Absyn.OR() then "or";
    case Absyn.NOT() then "not";
    /* relational operators */
    case Absyn.LESS() then "<";
    case Absyn.LESSEQ() then "<=";
    case Absyn.GREATER() then ">";
    case Absyn.GREATEREQ() then ">=";
    case Absyn.EQUAL() then "==";
    case Absyn.NEQUAL() then "<>";
  else fail();
  end match;
end opSymbolCompact;

/*
 *
 * Utility functions
 * These are utility functions used in some of the other functions.
 *
 */

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
  ():= match inTypeAOption
    local
      Type_a x;
    case NONE()
      algorithm
        Print.printBuf("NONE()");
      then
        ();
    case SOME(x)
      algorithm
        Print.printBuf("SOME(");
        inFuncTypeTypeATo(x);
        Print.printBuf(")");
      then
        ();
  end match;
end printOption;

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
  ():=
  matchcontinue (inTypeALst,inFuncTypeTypeATo,inString)
    local
      Type_a h;
      FuncTypeType_aTo r;
      list<Type_a> t;
      String sep;
    case ({},_,_) then ();
    case ({h},r,_)
      algorithm
        r(h);
      then
        ();
    case ((h :: t),r,sep)
      algorithm
        r(h);
        Print.printBuf(sep);
        printList(t, r, sep);
      then
        ();
  end matchcontinue;
end printList;

protected function printStringCommentOption "
  Print a string comment option on the Print buffer
"
  input Option<String> inStringOption;
algorithm
  () := match inStringOption
    local String str,s;
    case NONE()
      algorithm
        Print.printBuf("NONE()");
      then
        ();
    case SOME(s)
      algorithm
        str := stringAppendList({"SOME(\"",s,"\")"});
        Print.printBuf(str);
      then
        ();
  end match;
end printStringCommentOption;

public function unparseTypeSpec
  input Absyn.TypeSpec inTypeSpec;
  output String outString;
protected
  Boolean status;
algorithm
  // adrpo: make sure WE DO NOT HAVE this config flag set here: #5680
  // -m, --modelicaOutput       Enables valid modelica output for flat modelica.
  status := Flags.getConfigBool(Flags.MODELICA_OUTPUT);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, false);
  outString := Tpl.tplString(AbsynDumpTpl.dumpTypeSpec, inTypeSpec);
  FlagsUtil.setConfigBool(Flags.MODELICA_OUTPUT, status);
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

public function writePath
  input File.File file;
  input Absyn.Path path;
  input Escape escape=Escape.None;
  input String delimiter=".";
  input Boolean initialDot=true;
protected
  Absyn.Path p=path;
algorithm
  while true loop
    p := match p
      case Absyn.IDENT()
        algorithm
          File.writeEscape(file, p.name, escape);
          return;
        then fail();
      case Absyn.QUALIFIED()
        algorithm
          File.writeEscape(file, p.name, escape);
          File.writeEscape(file, delimiter, escape);
        then p.path;
      case Absyn.FULLYQUALIFIED()
        algorithm
          if initialDot then
            File.writeEscape(file, delimiter, escape);
          end if;
        then p.path;
    end match;
  end while;
end writePath;

annotation(__OpenModelica_Interface="frontend_dump");
end Dump;
