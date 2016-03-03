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

encapsulated package ExpressionDump
" file:        ExpressionDump.mo
  package:     ExpressionDump
  description: ExpressionDump


  This file contains the module ExpressionDump, which contains functions
  to dump and print DAE.Expression."

// public imports
public import Absyn;
public import DAE;
public import Graphviz;

// protected imports
protected import ComponentReference;
protected import Config;
protected import DAEDump;
protected import Dump;
protected import Expression;
public import ExpressionDumpTpl;
protected import List;
protected import Patternm;
protected import Print;
protected import System;
protected import Tpl;
protected import Types;

/*
 * - Printing expressions
 *   This module provides some functions to print data to the standard
 *   output.  This is used for error messages, and for debugging the
 *   semantic description.
 */

public function subscriptString
  "Returns a string representation of a subscript."
  input DAE.Subscript subscript;
  output String str;
algorithm
  str := match(subscript)
    local
      Integer i;
      String res;
      Absyn.Path enum_lit;
    case (DAE.INDEX(exp = DAE.ICONST(integer = i)))
      equation
        res = intString(i);
      then
        res;
    case (DAE.INDEX(exp = DAE.ENUM_LITERAL(name = enum_lit)))
      equation
        res = Absyn.pathString(enum_lit);
      then
        res;
  end match;
end subscriptString;

public function binopSymbol "
function: binopSymbol
  Return a string representation of the Operator."
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString := if Config.typeinfo()
               then binopSymbol2(inOperator)
               else binopSymbol1(inOperator);
end binopSymbol;

public function binopSymbol1
"Helper function to binopSymbol"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString := match (inOperator)
    case (DAE.ADD()) then " + ";
    case (DAE.SUB()) then " - ";
    case (DAE.MUL()) then " * ";
    case (DAE.DIV()) then " / ";
    case (DAE.POW()) then " ^ ";
    case (DAE.ADD_ARR()) then " + ";
    case (DAE.SUB_ARR()) then " - ";
    case (DAE.MUL_ARR()) then " * ";
    case (DAE.DIV_ARR()) then " / ";
    case (DAE.POW_ARR()) then " ^ ";
    case (DAE.POW_ARR2()) then " ^ ";
    case (DAE.MUL_ARRAY_SCALAR()) then " * ";
    case (DAE.ADD_ARRAY_SCALAR()) then " + ";
    case (DAE.SUB_SCALAR_ARRAY()) then " - ";
    case (DAE.POW_SCALAR_ARRAY()) then " ^ ";
    case (DAE.POW_ARRAY_SCALAR()) then " ^ ";
    case (DAE.MUL_SCALAR_PRODUCT()) then " * ";
    case (DAE.MUL_MATRIX_PRODUCT()) then " * ";
    case (DAE.DIV_SCALAR_ARRAY()) then " / ";
    case (DAE.DIV_ARRAY_SCALAR()) then " / ";
    else " <UNKNOWN_SYMBOL> ";
  end match;
end binopSymbol1;

public function debugBinopSymbol
"Helper function to binopSymbol"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString := match (inOperator)
    case (DAE.ADD()) then " + ";
    case (DAE.SUB()) then " - ";
    case (DAE.MUL()) then " * ";
    case (DAE.DIV()) then " / ";
    case (DAE.POW()) then " ^ ";
    case (DAE.EQUAL()) then " = ";
    case (DAE.ADD_ARR()) then " +ARR ";
    case (DAE.SUB_ARR()) then " -ARR ";
    case (DAE.MUL_ARR()) then " *ARR ";
    case (DAE.DIV_ARR()) then " /ARR ";
    case (DAE.POW_ARR()) then " ^ARR ";
    case (DAE.POW_ARR2()) then " ^ARR2 ";
    case (DAE.MUL_ARRAY_SCALAR()) then " ARR*S ";
    case (DAE.ADD_ARRAY_SCALAR()) then " ARR+S ";
    case (DAE.SUB_SCALAR_ARRAY()) then " - ";
    case (DAE.POW_SCALAR_ARRAY()) then " S^ARR ";
    case (DAE.POW_ARRAY_SCALAR()) then " ARR^S ";
    case (DAE.MUL_SCALAR_PRODUCT()) then " Dot ";
    case (DAE.MUL_MATRIX_PRODUCT()) then " MatrixProd ";
    case (DAE.DIV_SCALAR_ARRAY()) then " S/ARR ";
    case (DAE.DIV_ARRAY_SCALAR()) then " ARR/S ";
  end match;
end debugBinopSymbol;

protected function binopSymbol2
"Helper function to binopSymbol."
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString := match (inOperator)
    local
      String ts,s;
      DAE.Type t;

    case (DAE.ADD(ty = t))
      equation
        ts = Types.unparseType(t);
        s = stringAppendList({" +<", ts, "> "});
      then
        s;

    case (DAE.SUB(ty = t))
      equation
        ts = Types.unparseType(t);
        s = stringAppendList({" -<", ts, "> "});
      then
        s;

    case (DAE.MUL(ty = t))
      equation
        ts = Types.unparseType(t);
        s = stringAppendList({" *<", ts, "> "});
      then
        s;

    case (DAE.DIV(ty = t))
      equation
        ts = Types.unparseType(t);
        s = stringAppendList({" /<", ts, "> "});
      then
        s;

    case (DAE.POW()) then " ^ ";
    case (DAE.ADD_ARR(ty = t))
      equation
        ts = Types.unparseType(t);
        s = stringAppendList({" +<ADD_ARR><", ts, "> "});
      then
        s;
    case (DAE.SUB_ARR(ty = t))
      equation
        ts = Types.unparseType(t);
        s = stringAppendList({" -<SUB_ARR><", ts, "> "});
      then
        s;
    case (DAE.MUL_ARR()) then " *<MUL_ARRAY> ";
    case (DAE.DIV_ARR(ty = t))
      equation
        ts = Types.unparseType(t);
        s = stringAppendList({" /<DIV_ARR><", ts, "> "});
      then
        s;
    case (DAE.POW_ARR()) then " ^<POW_ARR> ";
    case (DAE.POW_ARR2()) then " ^<POW_ARR2> ";
    case (DAE.MUL_ARRAY_SCALAR()) then " *<MUL_ARRAY_SCALAR> ";
    case (DAE.ADD_ARRAY_SCALAR()) then " +<ADD_ARRAY_SCALAR> ";
    case (DAE.SUB_SCALAR_ARRAY()) then " -<SUB_SCALAR_ARRAY> ";
    case (DAE.POW_SCALAR_ARRAY()) then " ^<POW_SCALAR_ARRAY> ";
    case (DAE.POW_ARRAY_SCALAR()) then " ^<POW_ARRAY_SCALAR> ";
    case (DAE.MUL_SCALAR_PRODUCT()) then " *<MUL_SCALAR_PRODUCT> ";
    case (DAE.MUL_MATRIX_PRODUCT()) then " *<MUL_MATRIX_PRODUCT> ";
    case (DAE.DIV_SCALAR_ARRAY()) then " /<DIV_SCALAR_ARRAY> ";
    case (DAE.DIV_ARRAY_SCALAR()) then " /<DIV_ARRAY_SCALAR> ";
  end match;
end binopSymbol2;

public function unaryopSymbol
"Return string representation of unary operators."
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  match (inOperator)
    case (DAE.UMINUS()) then if Config.typeinfo() then "-<UMINUS>" else "-";
    case (DAE.UMINUS_ARR()) then if Config.typeinfo() then "-<UMINUS_ARR>" else "-";
  end match;
end unaryopSymbol;

public function lbinopSymbol
"Return string representation of logical binary operator."
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  match (inOperator)
    case (DAE.AND(_)) then " and ";
    case (DAE.OR(_)) then " or ";
  end match;
end lbinopSymbol;

public function lunaryopSymbol
"Return string representation of logical unary operator."
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString := match (inOperator)
    case (DAE.NOT(_)) then "not ";
  end match;
end lunaryopSymbol;

public function relopSymbol
"Return string representation of function operator."
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  match (inOperator)
    case (DAE.LESS()) then " < ";
    case (DAE.LESSEQ()) then " <= ";
    case (DAE.GREATER()) then " > ";
    case (DAE.GREATEREQ()) then " >= ";
    case (DAE.EQUAL()) then " == ";
    case (DAE.NEQUAL()) then " <> ";
  end match;
end relopSymbol;

public function printList
"Print a list of values given a print
  function and a separator string."
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

protected function printRow
"Print a list of expressions to the Print buffer."
  input list<DAE.Exp> es_1;
algorithm
  printList(es_1, printExp, ",");
end printRow;

public function printListStr
"Same as printList, except it returns
  a string instead of printing."
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
  outString := stringDelimitList(List.map(inTypeALst,inFuncTypeTypeAToString),inString);
end printListStr;

public function debugPrintSubscriptStr "
  Print a Subscript into a String."
  input DAE.Subscript inSubscript;
  output String outString;
algorithm
  outString := match (inSubscript)
    local
      String s;
      DAE.Exp e1;
    case (DAE.WHOLEDIM()) then ":";
    case (DAE.INDEX(exp = e1))
      equation
        s = dumpExpStr(e1,0);
        s = System.stringReplace(s, "\n", "");
      then
        s;
    case (DAE.SLICE(exp = e1))
      equation
        s = dumpExpStr(e1,0);
        s = System.stringReplace(s, "\n", "");
      then
        s;
    case (DAE.WHOLE_NONEXP(exp = e1))
      equation
        s = dumpExpStr(e1,0);
        s = System.stringReplace(s, "\n", "");
      then
        "1:"+s;
  end match;
end debugPrintSubscriptStr;

public function printSubscriptStr "
  Print a Subscript into a String."
  input DAE.Subscript inSubscript;
  output String outString;
algorithm
  outString:=
  match (inSubscript)
    local
      String s;
      DAE.Exp e1;
    case (DAE.WHOLEDIM()) then ":";
    case (DAE.INDEX(exp = e1))
      equation
        s = printExpStr(e1);
      then
        s;
    case (DAE.SLICE(exp = e1))
      equation
        s = printExpStr(e1);
      then
        s;
    case (DAE.WHOLE_NONEXP(exp = e1))
      equation
        s = printExpStr(e1);
      then
        "1:"+s;
  end match;
end printSubscriptStr;

public function printSubscriptLstStr
  "Print a list of Subscripts into a String."
  input list<DAE.Subscript> inSubscriptLst;
  output String outString;
algorithm
  outString := stringDelimitList(List.map(inSubscriptLst,printSubscriptStr)," , ");
end printSubscriptLstStr;

public function printExpListStr
" prints a list of expressions with commas between expressions."
  input list<DAE.Exp> expl;
  output String res;
algorithm
  res := stringDelimitList(List.map(expl,printExpStr),", ");
end printExpListStr;

// stefan
public function printExpListStrNoSpace
"same as printExpListStr, but the string will not have any spaces or commas between expressions"
  input list<DAE.Exp> expl;
  output String res;
algorithm
  res := stringAppendList(List.map(expl,printExpStr));
end printExpListStrNoSpace;

public function printOptExpStr "
Returns a string if SOME otherwise ''"
  input Option<DAE.Exp> oexp;
  output String str;
algorithm
  str := match(oexp)
    local DAE.Exp e;
    case(NONE()) then "";
    case(SOME(e)) then printExpStr(e);
  end match;
end printOptExpStr;

public function printExpStr
"This function prints a complete expression."
  input DAE.Exp e;
  output String s;
algorithm
  s := Tpl.tplString2(ExpressionDumpTpl.dumpExp, e, "\"");
end printExpStr;

public function printCrefsFromExpStr
  input DAE.Exp e;
  output String s;
algorithm
  s := Tpl.tplString2(ExpressionDumpTpl.dumpExpCrefs, e, "");
end printCrefsFromExpStr;

public function printExp2Str
"Helper function to printExpStr."
  input DAE.Exp inExp;
  input String stringDelimiter;
  input Option<tuple<printComponentRefStrFunc,Type_a>> opcreffunc "tuple of function that prints component references and an extra parameter passed through to the function";
  input Option<printCallFunc> opcallfunc "function that prints function calls";
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function printComponentRefStrFunc
    input DAE.ComponentRef inComponentRef;
    input Type_a Param;
    output String outString;
  end printComponentRefStrFunc;
  partial function printCallFunc
    input DAE.Exp inExp;
    input String stringDelimiter;
    input Option<tuple<printComponentRefStrFunc,Type_a>> opcreffunc "tuple of function that prints component references and an extra parameter passed through to the function";
    output String outString;
    partial function printComponentRefStrFunc
      input DAE.ComponentRef inComponentRef;
      input Type_a Param;
      output String outString;
    end printComponentRefStrFunc;
  end printCallFunc;
algorithm
  outString := matchcontinue (inExp, stringDelimiter, opcreffunc, opcallfunc)
    local
      String s,s_1,s_2,sym,s1,s2,s3,s4,res,fs,argstr,s_4,str,crstr,dimstr,expstr,iterstr,s1_1,s2_1,cs,ts,cs_1,ts_1,fs_1,s3_1;
      Integer i,pe1,p1,p2,pc,pt,pf,p,pstop,pstart,pstep;
      Real r;
      DAE.ComponentRef c,name;
      DAE.Type t,tp;
      DAE.Exp e1,e2,e,start,stop,step,cr,dim,exp,cond,tb,fb;
      DAE.Operator op;
      Absyn.Path fcn,lit;
      list<DAE.Exp> args,es;
      printComponentRefStrFunc pcreffunc;
      Type_a creffuncparam;
      printCallFunc pcallfunc;
      Boolean b;
      list<DAE.Exp> aexpl;
      list<list<DAE.Exp>> lstes;
      DAE.MatchType matchTy;
      DAE.Type et;
      list<DAE.MatchCase> cases;
      DAE.Pattern pat;
      Absyn.CodeNode code;
      DAE.ReductionIterators riters;
      String  scope, tyStr;

    case (DAE.EMPTY(scope = scope, name = name, tyStr = tyStr), _, _, _)
      then "<EMPTY(scope: " + scope + ", name: " + ComponentReference.printComponentRefStr(name) + ", ty: " + tyStr + ")>";

    case (DAE.ICONST(integer = i), _, _, _)
      equation
        s = intString(i);
      then
        s;

    case (DAE.RCONST(real = r), _, _, _)
      equation
        s = realString(r);
      then
        s;

    case (DAE.SCONST(string = s), _, _, _)
      equation
        s = System.escapedString(s,false);
        s = stringAppendList({stringDelimiter, s, stringDelimiter});
      then
        s;

    case (DAE.BCONST(bool = b), _, _, _) then boolString(b);

    case (DAE.CREF(componentRef = c), _, SOME((pcreffunc,creffuncparam)), _)
      equation
        s = pcreffunc(c,creffuncparam);
      then
        s;

    case (DAE.CREF(componentRef = c), _, _, _)
      equation
        s = ComponentReference.printComponentRefStr(c);
      then
        s;

    case (DAE.ENUM_LITERAL(name = lit), _, _, _)
      equation
        s = Absyn.pathString(lit);
      then
        s;

    case (e as DAE.BINARY(e1,op,e2), _, _, _)
      equation
        sym = binopSymbol(op);
        s1 = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        s2 = printExp2Str(e2, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        p1 = expPriority(e1);
        p2 = expPriority(e2);
        s1_1 = parenthesize(s1, p1, p,false);
        s2_1 = parenthesize(s2, p2, p,true);
        s = stringAppendList({s1_1, sym, s2_1});
      then
        s;

    case ((e as DAE.UNARY(op,e1)), _, _, _)
      equation
        sym = unaryopSymbol(op);
        s = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        p1 = expPriority(e1);
        s_1 = parenthesize(s, p1, p,true);
        s_2 = stringAppend(sym, s_1);
      then
        s_2;

    case ((e as DAE.LBINARY(e1,op,e2)), _, _, _)
      equation
        sym = lbinopSymbol(op);
        s1 = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        s2 = printExp2Str(e2, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        p1 = expPriority(e1);
        p2 = expPriority(e2);
        s1_1 = parenthesize(s1, p1, p,false);
        s2_1 = parenthesize(s2, p2, p,true);
        s = stringAppendList({s1_1, sym, s2_1});
      then
        s;

    case ((e as DAE.LUNARY(op,e1)), _, _, _)
      equation
        sym = lunaryopSymbol(op);
        s = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        p1 = expPriority(e1);
        s_1 = parenthesize(s, p1, p,false);
        s_2 = stringAppend(sym, s_1);
      then
        s_2;

    case ((e as DAE.RELATION(exp1=e1,operator=op,exp2=e2)), _, _, _)
      equation
        sym = relopSymbol(op);
        s1 = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        s2 = printExp2Str(e2, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        p1 = expPriority(e1);
        _ = expPriority(e2);
        s1_1 = parenthesize(s1, p1, p,false);
        s2_1 = parenthesize(s2, p1, p,true);
        s = stringAppendList({s1_1, sym, s2_1});
      then
        s;

    case ((e as DAE.IFEXP(cond,tb,fb)), _, _, _)
      equation
        cs = printExp2Str(cond, stringDelimiter, opcreffunc, opcallfunc);
        ts = printExp2Str(tb, stringDelimiter, opcreffunc, opcallfunc);
        fs = printExp2Str(fb, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        pc = expPriority(cond);
        pt = expPriority(tb);
        pf = expPriority(fb);
        cs_1 = parenthesize(cs, pc, p,false);
        ts_1 = parenthesize(ts, pt, p,false);
        fs_1 = parenthesize(fs, pf, p,false);
        str = stringAppendList({"if ",cs_1," then ",ts_1," else ",fs_1});
      then
        str;

    case (e as DAE.CALL(), _, _, SOME(pcallfunc))
      equation
        s_2 = pcallfunc(e,stringDelimiter,opcreffunc);
      then
        s_2;

    case (DAE.CALL(path = fcn,expLst = args), _, _, _)
      equation
        fs = Absyn.pathString(Absyn.makeNotFullyQualified(fcn));
        argstr = stringDelimitList(
          List.map3(args, printExp2Str, stringDelimiter, opcreffunc, opcallfunc), ",");
        s = stringAppendList({fs, "(", argstr, ")"});
      then
        s;

    case (DAE.PARTEVALFUNCTION(path = fcn, expList = args), _, _, _)
      equation
        fs = Absyn.pathString(Absyn.makeNotFullyQualified(fcn));
        argstr = stringDelimitList(
          List.map3(args, printExp2Str, stringDelimiter, opcreffunc, opcallfunc), ",");
        s = stringAppendList({"function ", fs, "(", argstr, ")"});
      then
        s;

    case (DAE.ARRAY(array = es), _, _, _)
      equation
        // s3 = Types.unparseType(tp); // adrpo: not used!
        s = stringDelimitList(
          List.map3(es, printExp2Str, stringDelimiter, opcreffunc, opcallfunc), ",");
        s = stringAppendList({"{", s, "}"});
      then
        s;

    case (DAE.TUPLE(PR = es), _, _, _)
      equation
        s = stringDelimitList(
          List.map3(es, printExp2Str, stringDelimiter, opcreffunc, opcallfunc), ",");
        s = stringAppendList({"(", s, ")"});
      then
        s;

    case (DAE.MATRIX(matrix = lstes), _, _, _)
      equation
        // s3 = Types.unparseType(tp); // adrpo: not used!
        s = stringDelimitList(List.map1(lstes, printRowStr, stringDelimiter), "},{");
        s = stringAppendList({"{{",s,"}}"});
      then
        s;

    case (e as DAE.RANGE(_,start,NONE(),stop), _, _, _)
      equation
        s1 = printExp2Str(start, stringDelimiter, opcreffunc, opcallfunc);
        s3 = printExp2Str(stop, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        pstart = expPriority(start);
        pstop = expPriority(stop);
        s1_1 = parenthesize(s1, pstart, p,false);
        s3_1 = parenthesize(s3, pstop, p,false);
        s = stringAppendList({s1_1, ":", s3_1});
      then
        s;

    case ((e as DAE.RANGE(_,start,SOME(step),stop)), _, _, _)
      equation
        s1 = printExp2Str(start, stringDelimiter, opcreffunc, opcallfunc);
        s2 = printExp2Str(step, stringDelimiter, opcreffunc, opcallfunc);
        s3 = printExp2Str(stop, stringDelimiter, opcreffunc, opcallfunc);
        p = expPriority(e);
        pstart = expPriority(start);
        pstop = expPriority(stop);
        pstep = expPriority(step);
        s1_1 = parenthesize(s1, pstart, p,false);
        s3_1 = parenthesize(s3, pstop, p,false);
        s2_1 = parenthesize(s2, pstep, p,false);
        s = stringAppendList({s1_1,":",s2_1,":",s3_1});
      then
        s;

    case (DAE.CAST(ty = tp,exp = e), _, _, _)
      equation
        str = Types.unparseType(tp);
        s = printExp2Str(e, stringDelimiter, opcreffunc, opcallfunc);
        res = stringAppendList({"DAE.CAST(",str,", ",s,")"});
      then
        res;

    case (e as DAE.ASUB(exp = e1,sub = aexpl), _, _, _)
      equation
        p = expPriority(e);
        pe1 = expPriority(e1);
        s1 = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        s1_1 = parenthesize(s1, pe1, p,false);
        s4 = stringDelimitList(
          List.map3(aexpl,printExp2Str, stringDelimiter, opcreffunc, opcallfunc),",");
        s_4 = s1_1+ "["+ s4 + "]";
      then
        s_4;

    case (DAE.SIZE(exp = cr,sz = SOME(dim)), _, _, _)
      equation
        crstr = printExp2Str(cr, stringDelimiter, opcreffunc, opcallfunc);
        dimstr = printExp2Str(dim, stringDelimiter, opcreffunc, opcallfunc);
        str = stringAppendList({"size(",crstr,",",dimstr,")"});
      then
        str;

    case (DAE.SIZE(exp = cr,sz = NONE()), _, _, _)
      equation
        crstr = printExp2Str(cr, stringDelimiter, opcreffunc, opcallfunc);
        str = stringAppendList({"size(",crstr,")"});
      then
        str;

    case (DAE.REDUCTION(reductionInfo=DAE.REDUCTIONINFO(path = fcn),expr = exp,iterators = riters), _, _, _)
      equation
        fs = Absyn.pathStringNoQual(fcn);
        expstr = printExp2Str(exp, stringDelimiter, opcreffunc, opcallfunc);
        iterstr = stringDelimitList(List.map(riters, reductionIteratorStr),",");
        str = stringAppendList({"<reduction>",fs,"(",expstr," for ",iterstr,")"});
      then
        str;

    // MetaModelica tuple
    case (DAE.META_TUPLE(es), _, _, _)
      equation
        s = "Tuple" + printExp2Str(DAE.TUPLE(es), stringDelimiter, opcreffunc, opcallfunc);
      then
        s;

    // MetaModelica list
    case (DAE.LIST(valList=es), _, _, _)
      equation
        s = stringDelimitList(List.map3(es,printExp2Str, stringDelimiter, opcreffunc, opcallfunc),",");
        s = stringAppendList({"List(", s, ")"});
      then
        s;

    // MetaModelica list cons
    case (DAE.CONS(car=e1,cdr=e2), _, _, _)
      equation
        s1 = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        s2 = printExp2Str(e2, stringDelimiter, opcreffunc, opcallfunc);
        s_2 = stringAppendList({"listCons(", s1, ",", s2, ")"});
      then
        s_2;

    // MetaModelica Option
    case (DAE.META_OPTION(NONE()), _, _, _) then "NONE()";
    case (DAE.META_OPTION(SOME(e1)), _, _, _)
      equation
        s1 = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        s_1 = stringAppendList({"SOME(",s1,")"});
      then
        s_1;

    case (DAE.BOX(e1), _, _, _)
      equation
        s1 = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        s_1 = stringAppendList({"#(",s1,")"});
      then
        s_1;

    case (DAE.UNBOX(e1,_), _, _, _)
      equation
        s1 = printExp2Str(e1, stringDelimiter, opcreffunc, opcallfunc);
        s_1 = stringAppendList({"unbox(",s1,")"});
      then
        s_1;

    // MetaModelica Uniontype Constructor
    case (DAE.METARECORDCALL(path = fcn, args=args), _, _, _)
      equation
        fs = Absyn.pathString(fcn);
        argstr = stringDelimitList(
          List.map3(args,printExp2Str, stringDelimiter, opcreffunc, opcallfunc),",");
        s = stringAppendList({fs, "(", argstr, ")"});
      then
        s;

    case (DAE.MATCHEXPRESSION(matchType=matchTy,inputs=es,cases=cases), _, _, _)
      equation
        s1 = printMatchType(matchTy);
        s2 = printExp2Str(DAE.TUPLE(es), stringDelimiter, opcreffunc, opcallfunc);
        s3 = stringAppendList(List.map(cases,printCase2Str));
        s = stringAppendList({s1,s2,"\n",s3,"  end ",s1});
      then s;

    case (DAE.SHARED_LITERAL(exp=e), _, _, _)
      then printExp2Str(e, stringDelimiter, opcreffunc, opcallfunc);

    case (DAE.PATTERN(pattern=pat),_,_,_)
      then Patternm.patternStr(pat);

    case (DAE.CODE(code=code),_,_,_) then "$Code(" + Dump.printCodeStr(code) + ")";

    else printExpTypeStr(inExp);

  end matchcontinue;
end printExp2Str;

protected function printExpTypeStr
  "Prints out the name of the expression uniontype to a string."
  input DAE.Exp inExp;
  output String outString;
algorithm
  outString := match(inExp)
    case DAE.ICONST(_) then "ICONST";
    case DAE.RCONST(_) then "RCONST";
    case DAE.SCONST(_) then "SCONST";
    case DAE.BCONST(_) then "BCONST";
    case DAE.ENUM_LITERAL() then "ENUM_LITERAL";
    case DAE.CREF() then "CREF";
    case DAE.BINARY() then "BINARY";
    case DAE.UNARY() then "UNARY";
    case DAE.LBINARY() then "LBINARY";
    case DAE.LUNARY() then "LUNARY";
    case DAE.RELATION() then "RELATION";
    case DAE.IFEXP() then "IFEXP";
    case DAE.CALL() then "CALL";
    case DAE.PARTEVALFUNCTION() then "PARTEVALFUNCTION";
    case DAE.ARRAY() then "ARRAY";
    case DAE.MATRIX() then "MATRIX";
    case DAE.RANGE() then "RANGE";
    case DAE.TUPLE() then "TUPLE";
    case DAE.CAST() then "CAST";
    case DAE.ASUB() then "ASUB";
    case DAE.TSUB() then "TSUB";
    case DAE.SIZE() then "SIZE";
    case DAE.CODE() then "CODE";
    case DAE.EMPTY() then "EMPTY";
    case DAE.REDUCTION() then "REDUCTION";
    case DAE.LIST() then "LIST";
    case DAE.CONS() then "CAR";
    case DAE.META_TUPLE() then "META_TUPLE";
    case DAE.META_OPTION() then "META_OPTION";
    case DAE.METARECORDCALL() then "METARECORDCALL";
    case DAE.MATCHEXPRESSION() then "MATCHEXPRESSION";
    case DAE.BOX() then "BOX";
    case DAE.UNBOX() then "UNBOX";
    case DAE.SHARED_LITERAL() then "SHARED_LITERAL";
    case DAE.PATTERN() then "PATTERN";
    else "#UNKNOWN EXPRESSION#";
  end match;
end printExpTypeStr;

protected function reductionIteratorStr
  input DAE.ReductionIterator riter;
  output String str;
algorithm
  str := match riter
    local
      String id;
      DAE.Exp exp,gexp;
    case (DAE.REDUCTIONITER(id=id,exp=exp,guardExp=NONE()))
      equation
        str = id + " in " + printExpStr(exp);
      then str;
    case (DAE.REDUCTIONITER(id=id,exp=exp,guardExp=SOME(gexp)))
      equation
        str = id + " guard " + printExpStr(gexp) + " in " + printExpStr(exp);
      then str;
  end match;
end reductionIteratorStr;

protected function printMatchType
  input DAE.MatchType ty;
  output String str;
algorithm
  str := match ty
    case DAE.MATCHCONTINUE() then "matchcontinue";
    case DAE.MATCH(NONE()) then "match";
    case DAE.MATCH(SOME(_)) then "match /* switch */";
  end match;
end printMatchType;

protected function printCase2Str
  "Prints a matchcase as string"
  input DAE.MatchCase matchCase;
  output String str;
algorithm
  str := match matchCase
    local
      list<DAE.Pattern> patterns;
      list<DAE.Statement> body;
      DAE.Exp result;
      String resultStr,patternsStr,bodyStr;
    case DAE.CASE(patterns=patterns, body={}, result=SOME(result))
      equation
        patternsStr = Patternm.patternStr(DAE.PAT_META_TUPLE(patterns));
        resultStr = printExpStr(result);
      then stringAppendList({"    case ",patternsStr," then ",resultStr,";\n"});
    case DAE.CASE(patterns=patterns, body={}, result=NONE())
      equation
        patternsStr = Patternm.patternStr(DAE.PAT_META_TUPLE(patterns));
      then stringAppendList({"    case ",patternsStr," then fail();\n"});
    case DAE.CASE(patterns=patterns, body=body, result=SOME(result))
      equation
        patternsStr = Patternm.patternStr(DAE.PAT_META_TUPLE(patterns));
        resultStr = printExpStr(result);
        bodyStr = stringAppendList(List.map1(body, DAEDump.ppStmtStr, 8));
      then stringAppendList({"    case ",patternsStr,"\n      algorithm\n",bodyStr,"      then ",resultStr,";\n"});
    case DAE.CASE(patterns=patterns, body=body, result=NONE())
      equation
        patternsStr = Patternm.patternStr(DAE.PAT_META_TUPLE(patterns));
        bodyStr = stringAppendList(List.map1(body, DAEDump.ppStmtStr, 8));
      then stringAppendList({"    case ",patternsStr,"\n      algorithm\n",bodyStr,"      then fail();\n"});
  end match;
end printCase2Str;

public function expPriority
" Returns a priority number for an expression.
 This function is used to output parenthesis
 when needed, e.g., 3(1+2) should output 3(1+2)
 and not 31+2."
  input DAE.Exp inExp;
  output Integer outInteger;
algorithm
  outInteger := match (inExp)
    case (DAE.ICONST(_)) then 0;
    case (DAE.RCONST(_)) then 0;
    case (DAE.SCONST(_)) then 0;
    case (DAE.BCONST(_)) then 0;
    case (DAE.ENUM_LITERAL()) then 0;
    case (DAE.CREF(_,_)) then 0;
    case (DAE.ASUB(_,_)) then 0;
    case (DAE.CAST(_,_)) then 0;
    case (DAE.CALL()) then 0;
    case (DAE.PARTEVALFUNCTION()) then 0;
    case (DAE.ARRAY()) then 0;
    case (DAE.MATRIX()) then 0;
    case (DAE.BINARY(operator = DAE.POW(_))) then 3;
    case (DAE.BINARY(operator = DAE.POW_ARR(_))) then 3;
    case (DAE.BINARY(operator = DAE.POW_ARR2(_))) then 3;
    case (DAE.BINARY(operator = DAE.POW_SCALAR_ARRAY(_))) then 3;
    case (DAE.BINARY(operator = DAE.POW_ARRAY_SCALAR(_))) then 3;
    case (DAE.BINARY(operator = DAE.DIV(_))) then 5;
    case (DAE.BINARY(operator = DAE.DIV_ARR(_))) then 5;
    case (DAE.BINARY(operator = DAE.DIV_SCALAR_ARRAY(_))) then 5;
    case (DAE.BINARY(operator = DAE.DIV_ARRAY_SCALAR(_))) then 5;
    case (DAE.BINARY(operator = DAE.MUL(_))) then 7;
    case (DAE.BINARY(operator = DAE.MUL_ARR(_))) then 7;
    case (DAE.BINARY(operator = DAE.MUL_ARRAY_SCALAR(_))) then 7;
    case (DAE.BINARY(operator = DAE.MUL_SCALAR_PRODUCT(_))) then 7;
    case (DAE.BINARY(operator = DAE.MUL_MATRIX_PRODUCT(_))) then 7;
    case (DAE.UNARY(operator = DAE.UMINUS(_))) then 8;
    case (DAE.UNARY(operator = DAE.UMINUS_ARR(_))) then 8;
    case (DAE.BINARY(operator = DAE.ADD(_))) then 9;
    case (DAE.BINARY(operator = DAE.ADD_ARR(_))) then 9;
    case (DAE.BINARY(operator = DAE.ADD_ARRAY_SCALAR(_))) then 9;
    case (DAE.BINARY(operator = DAE.SUB(_))) then 9;
    case (DAE.BINARY(operator = DAE.SUB_ARR(_))) then 9;
    case (DAE.BINARY(operator = DAE.SUB_SCALAR_ARRAY(_))) then 9;
    case (DAE.RELATION(operator = DAE.LESS(_))) then 11;
    case (DAE.RELATION(operator = DAE.LESSEQ(_))) then 11;
    case (DAE.RELATION(operator = DAE.GREATER(_))) then 11;
    case (DAE.RELATION(operator = DAE.GREATEREQ(_))) then 11;
    case (DAE.RELATION(operator = DAE.EQUAL(_))) then 11;
    case (DAE.RELATION(operator = DAE.NEQUAL(_))) then 11;
    case (DAE.LUNARY(operator = DAE.NOT(_))) then 13;
    case (DAE.LBINARY(operator = DAE.AND(_))) then 15;
    case (DAE.LBINARY(operator = DAE.OR(_))) then 17;
    case (DAE.RANGE()) then 19;
    case (DAE.IFEXP()) then 21;
    case (DAE.TUPLE(_)) then 23;  /* Not valid in inner expressions, only included here for completeness */
    else 25;
  end match;
end expPriority;

public function printRowStr
"Prints a list of expressions to a string."
  input list<DAE.Exp> es_1;
  input String stringDelimiter;
  output String s;
algorithm
  s := stringDelimitList(List.map3(es_1, printExp2Str, stringDelimiter, NONE(), NONE()), ",");
end printRowStr;

public function dumpExpGraphviz
"Creates a Graphviz Node from an Expression."
  input DAE.Exp inExp;
  output Graphviz.Node outNode;
algorithm
  outNode := matchcontinue (inExp)
    local
      String s,s_1,s_2,sym,fs,tystr,istr,id;
      Integer i;
      DAE.ComponentRef c;
      Graphviz.Node lt,rt,ct,tt,ft,t1,t2,t3,crt,dimt,expt,itert;
      DAE.Exp e1,e2,e,t,f,start,stop,step,cr,dim,exp,iterexp,cond,ae1;
      DAE.Operator op;
      list<Graphviz.Node> argnodes,nodes;
      Absyn.Path fcn;
      list<DAE.Exp> args,es;
      DAE.Type ty;
      Real r;
      Boolean b;
      list<list<DAE.Exp>> lstes;

    case (DAE.ICONST(integer = i))
      equation
        s = intString(i);
      then
        Graphviz.LNODE("ICONST",{s},{},{});

    case (DAE.RCONST(real = r))
      equation
        s = realString(r);
      then
        Graphviz.LNODE("RCONST",{s},{},{});

    case (DAE.SCONST(string = s))
      equation
        s = System.escapedString(s,true);
        s = stringAppendList({"\"", s, "\""});
      then
        Graphviz.LNODE("SCONST",{s},{},{});

    case (DAE.BCONST(bool = b))
      equation
        s = boolString(b);
      then
        Graphviz.LNODE("BCONST",{s},{},{});

    case (DAE.CREF(componentRef = c))
      equation
        s = ComponentReference.printComponentRefStr(c);
      then
        Graphviz.LNODE("CREF",{s},{},{});

    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        sym = binopSymbol(op);
        lt = dumpExpGraphviz(e1);
        rt = dumpExpGraphviz(e2);
      then
        Graphviz.LNODE("BINARY",{sym},{},{lt,rt});

    case (DAE.UNARY(operator = op,exp = e))
      equation
        sym = unaryopSymbol(op);
        ct = dumpExpGraphviz(e);
      then
        Graphviz.LNODE("UNARY",{sym},{},{ct});

    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        sym = lbinopSymbol(op);
        lt = dumpExpGraphviz(e1);
        rt = dumpExpGraphviz(e2);
      then
        Graphviz.LNODE("LBINARY",{sym},{},{lt,rt});

    case (DAE.LUNARY(operator = op,exp = e))
      equation
        sym = lunaryopSymbol(op);
        ct = dumpExpGraphviz(e);
      then
        Graphviz.LNODE("LUNARY",{sym},{},{ct});

    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation
        sym = relopSymbol(op);
        lt = dumpExpGraphviz(e1);
        rt = dumpExpGraphviz(e2);
      then
        Graphviz.LNODE("RELATION",{sym},{},{lt,rt});

    case (DAE.IFEXP(expCond = cond,expThen = t,expElse = f))
      equation
        ct = dumpExpGraphviz(cond);
        tt = dumpExpGraphviz(t);
        ft = dumpExpGraphviz(f);
      then
        Graphviz.NODE("IFEXP",{},{ct,tt,ft});

    case (DAE.CALL(path = fcn,expLst = args))
      equation
        fs = Absyn.pathString(fcn);
        argnodes = List.map(args, dumpExpGraphviz);
      then
        Graphviz.LNODE("CALL",{fs},{},argnodes);

    case(DAE.PARTEVALFUNCTION(path = fcn,expList = args))
      equation
        _ = Absyn.pathString(fcn);
        argnodes = List.map(args, dumpExpGraphviz);
      then
        Graphviz.NODE("PARTEVALFUNCTION",{},argnodes);

    case (DAE.ARRAY(array = es))
      equation
        nodes = List.map(es, dumpExpGraphviz);
      then
        Graphviz.NODE("ARRAY",{},nodes);

    case (DAE.TUPLE(PR = es))
      equation
        nodes = List.map(es, dumpExpGraphviz);
      then
        Graphviz.NODE("TUPLE",{},nodes);

    case (DAE.MATRIX(matrix = lstes))
      equation
        s = stringDelimitList(List.map1(lstes, printRowStr, "\""), "},{");
        s = stringAppendList({"{{", s, "}}"});
      then
        Graphviz.LNODE("MATRIX",{s},{},{});

    case (DAE.RANGE(start = start,step = NONE(),stop = stop))
      equation
        t1 = dumpExpGraphviz(start);
        t2 = Graphviz.NODE(":",{},{});
        t3 = dumpExpGraphviz(stop);
      then
        Graphviz.NODE("RANGE",{},{t1,t2,t3});

    case (DAE.RANGE(start = start,step = SOME(step),stop = stop))
      equation
        t1 = dumpExpGraphviz(start);
        t2 = dumpExpGraphviz(step);
        t3 = dumpExpGraphviz(stop);
      then
        Graphviz.NODE("RANGE",{},{t1,t2,t3});

    case (DAE.CAST(ty = ty,exp = e))
      equation
        tystr = Types.unparseType(ty);
        ct = dumpExpGraphviz(e);
      then
        Graphviz.LNODE("CAST",{tystr},{},{ct});

    case (DAE.ASUB(exp = e,sub = ((DAE.ICONST(i))::{})))
      equation
        ct = dumpExpGraphviz(e);
        istr = intString(i);
        s = stringAppendList({"[",istr,"]"});
      then
        Graphviz.LNODE("ASUB",{s},{},{ct});

    case (DAE.SIZE(exp = cr,sz = SOME(dim)))
      equation
        crt = dumpExpGraphviz(cr);
        dimt = dumpExpGraphviz(dim);
      then
        Graphviz.NODE("SIZE",{},{crt,dimt});

    case (DAE.SIZE(exp = cr,sz = NONE()))
      equation
        crt = dumpExpGraphviz(cr);
      then
        Graphviz.NODE("SIZE",{},{crt});

    case (DAE.REDUCTION(reductionInfo=DAE.REDUCTIONINFO(path = fcn),expr = exp,iterators = {DAE.REDUCTIONITER(exp=iterexp)}))
      equation
        fs = Absyn.pathString(fcn);
        expt = dumpExpGraphviz(exp);
        itert = dumpExpGraphviz(iterexp);
      then
        Graphviz.LNODE("REDUCTION",{fs},{},{expt,itert});

    case (_) then Graphviz.NODE("#UNKNOWN EXPRESSION# ----eeestr ",{},{});
  end matchcontinue;
end dumpExpGraphviz;

public function dumpExpStr
"Dumps expression to a string."
  input DAE.Exp inExp;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inExp,inInteger)
    local
      String gen_str,res_str,s,sym,lt,rt,ct,tt,ft,fs,argnodes_1,nodes_1,t1,t2,t3,tystr,istr,crt,dimt,expt,itert,id,tpStr,str;
      Integer level,x,new_level1,new_level2,new_level3,i;
      DAE.ComponentRef c;
      DAE.Exp e1,e2,e,t,f,start,stop,step,cr,dim,exp,iterexp,cond,ae1;
      DAE.Operator op;
      DAE.ClockKind clk;
      list<String> argnodes,nodes;
      Absyn.Path fcn;
      list<DAE.Exp> args,es;
      DAE.Type tp,ty;
      Real r;
      list<list<DAE.Exp>> lstes;
      Boolean b;

    case (DAE.ICONST(integer = x),level)
      equation
        gen_str = genStringNTime("   |", level);
        s = intString(x);
        res_str = stringAppendList({gen_str,"ICONST ",s,"\n"});
      then
        res_str;

    case (DAE.RCONST(real = r),level)
      equation
        gen_str = genStringNTime("   |", level);
        s = realString(r);
        res_str = stringAppendList({gen_str,"RCONST ",s,"\n"});
      then
        res_str;

    case (DAE.SCONST(string = s),level)
      equation
        gen_str = genStringNTime("   |", level);
        s = System.escapedString(s,true);
        res_str = stringAppendList({gen_str,"SCONST ","\"", s,"\"\n"});
      then
        res_str;

    case (DAE.BCONST(bool = false),level)
      equation
        gen_str = genStringNTime("   |", level);
        res_str = stringAppendList({gen_str,"BCONST ","false","\n"});
      then
        res_str;

    case (DAE.BCONST(bool = true),level)
      equation
        gen_str = genStringNTime("   |", level);
        res_str = stringAppendList({gen_str,"BCONST ","true","\n"});
      then
        res_str;

    // BTH TODO
    case (DAE.CLKCONST(clk = clk),level)
      equation
        gen_str = genStringNTime("   |", level);
        s = clockKindString(clk);
        res_str = stringAppendList({gen_str,"CLKCONST ",s,"\n"});
      then
        res_str;

    case (DAE.ENUM_LITERAL(name = fcn, index = i), level)
      equation
        gen_str = genStringNTime("   |", level);
        s = Absyn.pathString(fcn);
        istr = intString(i);
        res_str = stringAppendList({gen_str, "ENUM_LITERAL ", s, " [", istr, "]", "\n"});
      then
        res_str;

    case (DAE.CREF(componentRef = c,ty=ty),level)
      equation
        gen_str = genStringNTime("   |", level);
        s = /*ComponentReference.printComponentRefStr*/ComponentReference.debugPrintComponentRefTypeStr(c);
        tpStr= Types.unparseType(ty);
        res_str = stringAppendList({gen_str,"CREF ",s," CREFTYPE:",tpStr,"\n"});
      then
        res_str;

    case (exp as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        sym = debugBinopSymbol(op);
        tp = Expression.typeof(exp);
        str = Types.unparseType(tp);
        lt = dumpExpStr(e1, new_level1);
        rt = dumpExpStr(e2, new_level2);
        res_str = stringAppendList({gen_str,"BINARY ",sym," ",str,"\n",lt,rt,""});
      then
        res_str;

    case (DAE.UNARY(operator = op,exp = e),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        sym = unaryopSymbol(op);
        ct = dumpExpStr(e, new_level1);
        str = "expType:"+Types.unparseType(Expression.typeof(e))+" optype:"+Types.unparseType(Expression.typeofOp(op));
        res_str = stringAppendList({gen_str,"UNARY ",sym," ",str,"\n",ct,""});
      then
        res_str;

    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        sym = lbinopSymbol(op);
        lt = dumpExpStr(e1, new_level1);
        rt = dumpExpStr(e2, new_level2);
        res_str = stringAppendList({gen_str,"LBINARY ",sym,"\n",lt,rt,""});
      then
        res_str;

    case (DAE.LUNARY(operator = op,exp = e),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        sym = lunaryopSymbol(op);
        ct = dumpExpStr(e, new_level1);
        res_str = stringAppendList({gen_str,"LUNARY ",sym,"\n",ct,""});
      then
        res_str;

    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        sym = relopSymbol(op);
        lt = dumpExpStr(e1, new_level1);
        rt = dumpExpStr(e2, new_level2);
        res_str = stringAppendList({gen_str,"RELATION ",sym,"\n",lt,rt,""});
      then
        res_str;

    case (DAE.IFEXP(expCond = cond,expThen = t,expElse = f),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        new_level3 = level + 1;
        ct = dumpExpStr(cond, new_level1);
        tt = dumpExpStr(t, new_level2);
        ft = dumpExpStr(f, new_level3);
        res_str = stringAppendList({gen_str,"IFEXP ","\n",ct,tt,ft,""});
      then
        res_str;

    case (DAE.CALL(path = fcn,expLst = args),level)
      equation
        gen_str = genStringNTime("   |", level);
        fs = Absyn.pathString(fcn);
        new_level1 = level + 1;
        argnodes = List.map1(args, dumpExpStr, new_level1);
        argnodes_1 = stringAppendList(argnodes);
        res_str = stringAppendList({gen_str,"CALL ",fs,"\n",argnodes_1,""});
      then
        res_str;

    case (DAE.PARTEVALFUNCTION(path = fcn,expList = args),level)
      equation
        gen_str = genStringNTime("   |", level);
        fs = Absyn.pathString(fcn);
        new_level1 = level + 1;
        argnodes = List.map1(args, dumpExpStr, new_level1);
        argnodes_1 = stringAppendList(argnodes);
        res_str = stringAppendList({gen_str,"CALL ",fs,"\n",argnodes_1,""});
      then
        res_str;

    case (DAE.ARRAY(array = es,scalar=b,ty=tp),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        nodes = List.map1(es, dumpExpStr, new_level1);
        nodes_1 = stringAppendList(nodes);
        s = boolString(b);
        tpStr = Types.unparseType(tp);
        res_str = stringAppendList({gen_str,"ARRAY scalar:",s," tp: ",tpStr,"\n",nodes_1});
      then
        res_str;

    case (DAE.TUPLE(PR = es),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        nodes = List.map1(es, dumpExpStr, new_level1);
        nodes_1 = stringAppendList(nodes);
        res_str = stringAppendList({gen_str,"TUPLE ",nodes_1,"\n"});
      then
        res_str;

    case (DAE.MATRIX(matrix = lstes),level)
      equation
        gen_str = genStringNTime("   |", level);
        s = stringDelimitList(List.map1(lstes, printRowStr, "\""), "},{");
        res_str = stringAppendList({gen_str,"MATRIX ","\n","{{",s,"}}","\n"});
      then
        res_str;

    case (DAE.RANGE(start = start,step = NONE(),stop = stop),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        t1 = dumpExpStr(start, new_level1);
        t2 = ":";
        t3 = dumpExpStr(stop, new_level2);
        res_str = stringAppendList({gen_str,"RANGE ","\n",t1,t2,t3,""});
      then
        res_str;

    case (DAE.RANGE(start = start,step = SOME(step),stop = stop),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        new_level3 = level + 1;
        t1 = dumpExpStr(start, new_level1);
        t2 = dumpExpStr(step, new_level2);
        t3 = dumpExpStr(stop, new_level3);
        res_str = stringAppendList({gen_str,"RANGE ","\n",t1,t2,t3,""});
      then
        res_str;

    case (DAE.CAST(ty = ty,exp = e),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        _ = Types.unparseType(ty);
        ct = dumpExpStr(e, new_level1);
        res_str = stringAppendList({gen_str,"CAST ","\n",ct,""});
      then
        res_str;

    case (DAE.ASUB(exp = e,sub = ((DAE.ICONST(i))::{})),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        ct = dumpExpStr(e, new_level1);
        istr = intString(i);
        s = stringAppendList({"[",istr,"]"});
        res_str = stringAppendList({gen_str,"ASUB ",s,"\n",ct,""});
      then
        res_str;

    case (DAE.ASUB(exp = e),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        ct = dumpExpStr(e, new_level1);
        res_str = stringAppendList({gen_str,"ASUB ","\n",ct,""});
      then
        res_str;

    case (DAE.SIZE(exp = cr,sz = SOME(dim)),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        crt = dumpExpStr(cr, new_level1);
        dimt = dumpExpStr(dim, new_level2);
        res_str = stringAppendList({gen_str,"SIZE ","\n",crt,dimt,""});
      then
        res_str;

    case (DAE.SIZE(exp = cr,sz = NONE()),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        crt = dumpExpStr(cr, new_level1);
        res_str = stringAppendList({gen_str,"SIZE ","\n",crt,""});
      then
        res_str;

    case (DAE.REDUCTION(reductionInfo=DAE.REDUCTIONINFO(path = fcn),expr = exp,iterators={DAE.REDUCTIONITER(exp=iterexp)}),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        _ = Absyn.pathString(fcn);
        expt = dumpExpStr(exp, new_level1);
        itert = dumpExpStr(iterexp, new_level2);
        res_str = stringAppendList({gen_str,"REDUCTION ","\n",expt,itert,""});
      then
        res_str;

    case (DAE.RECORD(path=fcn, exps=args),level)
      equation
        gen_str = genStringNTime("   |", level);
        fs = Absyn.pathString(fcn);
        new_level1 = level + 1;
        argnodes = List.map1(args, dumpExpStr, new_level1);
        argnodes_1 = stringAppendList(argnodes);
        res_str = stringAppendList({gen_str,"RECORD ",fs,"\n",argnodes_1,""});
      then
        res_str;

    case (DAE.BOX(exp=e),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        ct = dumpExpStr(e, new_level1);
        res_str = stringAppendList({gen_str,"BOX ","\n",ct,""});
      then
        res_str;

     case (DAE.UNBOX(exp=e),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        ct = dumpExpStr(e, new_level1);
        res_str = stringAppendList({gen_str,"UNBOX ","\n",ct,""});
      then
        res_str;

     case (DAE.SUM(startIt=start, endIt=stop, body=e),level)
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        res_str = "("+dumpExpStr(start,new_level1)+" to "+dumpExpStr(stop,new_level1)+")["+dumpExpStr(e,new_level1)+"]";
        res_str = stringAppendList({gen_str,"SIGMA ","\n",res_str,""});
      then
        res_str;

    case (_,level)
      equation
        gen_str = genStringNTime("   |", level);
        res_str = stringAppendList({gen_str," UNKNOWN EXPRESSION ","\n"});
      then
        res_str;
  end matchcontinue;
end dumpExpStr;

protected function genStringNTime
"function:getStringNTime
  Appends the string to itself n times."
  input String inString;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inString,inInteger)
    local
      String str,new_str,res_str;
      Integer new_level,level;

    case (_,0) then "";  /* n */

    case (str,level)
      equation
        new_level = level + (-1);
        new_str = genStringNTime(str, new_level);
        res_str = stringAppend(str, new_str);
      then
        res_str;
  end matchcontinue;
end genStringNTime;

protected function printExpIfDiff ""
  input DAE.Exp e1,e2;
  output String s;
algorithm
  s := if Expression.expEqual(e1,e2)
       then ""
       else printExpStr(e1) + " =!= " + printExpStr(e2) + "\n";
end printExpIfDiff;

public function printArraySizes "Function: printArraySizes"
  input list<Option <Integer>> inLst;
  output String out;
algorithm
  out := matchcontinue(inLst)
    local
      Integer x;
      list<Option<Integer>> lst;
      String s,s2;

    case({}) then "";

    case(SOME(x) :: lst)
      equation
        s = printArraySizes(lst);
        s2 = intString(x);
        s = stringAppendList({s2, s});
      then s;

    case(_ :: lst)
      equation
        s = printArraySizes(lst);
      then s;
  end matchcontinue;
end printArraySizes;

public function typeOfString
"Retrieves the Type of the Expression as a String"
  input DAE.Exp inExp;
  output String str;
protected
  DAE.Type ty;
algorithm
  ty := Expression.typeof(inExp);
  str := Types.unparseType(ty);
end typeOfString;

public function debugPrintComponentRefExp "
This function takes an DAE.Exp and tries to print ComponentReferences.
Uses debugPrint.ComponentRefTypeStr, which gives type information to stdout.
NOTE Only used for debugging.
"
  input DAE.Exp inExp;
  output String str;
algorithm str := matchcontinue(inExp)
  local
    DAE.ComponentRef cr;
    String s1;
    list<DAE.Exp> expl;
  case(DAE.CREF(cr,_)) then ComponentReference.debugPrintComponentRefTypeStr(cr);
  case(DAE.ARRAY(_,_,expl))
    equation
      s1 = "{" + stringAppendList(List.map(expl,debugPrintComponentRefExp)) + "}";
    then
      s1;
  else printExpStr(inExp); // when not cref, print expression anyways since it is used for some debugging.
end matchcontinue;
end debugPrintComponentRefExp;

public function dimensionString
  "Returns a string representation of an array dimension."
  input DAE.Dimension dim;
  output String str;
algorithm
  str := match(dim)
    local
      String s;
      Integer x;
      Absyn.Path p;
      DAE.Exp e;
      Integer size;
    case DAE.DIM_UNKNOWN() then ":";

    case DAE.DIM_ENUM(enumTypeName = p)
      equation
        s = Absyn.pathString(p);
      then
        s;

    case DAE.DIM_BOOLEAN() then "Boolean";

    case DAE.DIM_INTEGER(integer = x)
      equation
        s = intString(x);
      then
        s;

    case DAE.DIM_EXP(exp = e)
      equation
        s = printExpStr(e);
      then
        s;
  end match;
end dimensionString;

public function dimensionsString
  "Returns a string representation of an array dimension."
  input DAE.Dimensions dims;
  output String str;
algorithm
  str := stringDelimitList(List.map(dims,dimensionString),",");
end dimensionsString;

public function dimensionIntString
  "Returns a integer string representation of an array dimension."
  input DAE.Dimension dim;
  output String str;
algorithm
  str := match(dim)
    local
      String s;
      Integer x, size;
      DAE.Exp e;
    case DAE.DIM_UNKNOWN() then ":";
    case DAE.DIM_ENUM(size =size)
      then intString(size);
    case DAE.DIM_BOOLEAN() then "1";
    case DAE.DIM_INTEGER(integer = x)
      then intString(x);
    case DAE.DIM_EXP(exp = e)
      equation
        s = printExpStr(e);
      then s;
  end match;
end dimensionIntString;

public function dumpExpWithTitle
  input String title;
  input DAE.Exp exp;
  protected String str;
algorithm
  str := dumpExpStr(exp,0);
  print(title);
  print(str);
  print("\n");
end dumpExpWithTitle;

public function dumpExp
  input DAE.Exp exp;
  protected String str;
algorithm
  str := dumpExpStr(exp,0);
  print(str);
  print("--------------------\n");
end dumpExp;

public function printSubscript
"Print a Subscript."
  input DAE.Subscript inSubscript;
algorithm
  _ := match (inSubscript)
    local DAE.Exp e1;
    case (DAE.WHOLEDIM())
      equation
        Print.printBuf(":");
      then
        ();
    case (DAE.INDEX(exp = e1))
      equation
        printExp(e1);
      then
        ();
    case (DAE.SLICE(exp = e1))
      equation
        printExp(e1);
      then
        ();
    case (DAE.WHOLE_NONEXP(exp = e1))
      equation
        Print.printBuf("1:");
        printExp(e1);
      then
        ();
  end match;
end printSubscript;

public function printExp
"This function prints a complete expression."
  input DAE.Exp e;
algorithm
  Tpl.tplPrint2(ExpressionDumpTpl.dumpExp, e, "\"");
end printExp;

public function parenthesize
"Adds parentheisis to a string if expression
  and parent expression priorities requires it."
  input String inString1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Boolean rightOpParenthesis "true for right hand side operators";
  output String outString;
algorithm
  outString := matchcontinue (inString1,inInteger2,inInteger3,rightOpParenthesis)
    local
      String str_1,str;
      Integer pparent,pexpr;

    // expr, prio. parent expr, prio. expr
    case (str,pparent,pexpr,_)
      equation
        (pparent > pexpr) = true;
        str_1 = stringAppendList({"(",str,")"});
      then str_1;

    // If priorites are equal and str is from right hand side, parenthesize to make left associative
    case (str,pparent,pexpr,true)
      equation
        (pparent == pexpr) = true;
        str_1 = stringAppendList({"(",str,")"});
      then
        str_1;
    case (str,_,_,_) then str;
  end matchcontinue;
end parenthesize;

public function clockKindString "
Author: BTH
Return textual representation of a ClockKind."
  input DAE.ClockKind inClockKind;
  output String outString;
algorithm
  outString := match inClockKind
    local
      DAE.Exp c, intervalCounter, interval, condition, resolution, startInterval, solverMethod;

    case DAE.INFERRED_CLOCK()
    then "Clock()";

    case DAE.INTEGER_CLOCK(intervalCounter=intervalCounter, resolution=resolution)
    then "Clock(" + dumpExpStr(intervalCounter,0) + ", " + dumpExpStr(resolution,0) + ")";

    case DAE.REAL_CLOCK(interval=interval)
    then "Clock(" + dumpExpStr(interval,0) + ")";

    case DAE.BOOLEAN_CLOCK(condition=condition, startInterval=startInterval)
    then "Clock(" + dumpExpStr(condition,0) + ", " + dumpExpStr(startInterval,0) + ")";

    case DAE.SOLVER_CLOCK(c=c, solverMethod=solverMethod)
    then "Clock(" + dumpExpStr(c,0) + ", " + dumpExpStr(solverMethod,0) + ")";
  end match;
end clockKindString;

annotation(__OpenModelica_Interface="frontend");
end ExpressionDump;
