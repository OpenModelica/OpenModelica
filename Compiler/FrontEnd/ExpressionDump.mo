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

encapsulated package ExpressionDump
"
  file:         ExpressionDump.mo
  package:     ExpressionDump
  description: ExpressionDump

  RCS: $Id$

  This file contains the module ExpressionDump, which contains functions
  to dump and print DAE.Expression."

// public imports
public import Absyn;
public import ClassInf;
public import DAE;
public import Graphviz;

public type ComponentRef = DAE.ComponentRef;
public type Ident = String;
public type Operator = DAE.Operator;
public type Type = DAE.ExpType;
public type Subscript = DAE.Subscript;
public type Var = DAE.ExpVar;

// protected imports
protected import ComponentReference;
protected import Config;
protected import DAEDump;
protected import Dump;
protected import Error;
protected import Expression;
protected import List;
protected import Patternm;
protected import Util;
protected import Print;
protected import System;

/*
 * - Printing expressions
 *   This module provides some functions to print data to the standard
 *   output.  This is used for error messages, and for debugging the
 *   semantic description.
 */

public function subscriptString
  "Returns a string representation of a subscript."
  input Subscript subscript;
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

public function typeString "function typeString
  Converts a type into a String"
  input Type inType;
  output String outString;
algorithm
  outString := matchcontinue (inType)
    local
      list<Ident> ss;
      Type t;
      list<DAE.Dimension> dims;
      String s1,ts,res,s;
      list<Var> vars;
      ClassInf.State ci;
      
    case DAE.ET_INT() then "INT";
    case DAE.ET_REAL() then "REAL";
    case DAE.ET_BOOL() then "BOOL";
    case DAE.ET_STRING() then "STRING";
    case DAE.ET_ENUMERATION(path = _) then "ENUM TYPE";
    case DAE.ET_OTHER() then "OTHER";
    
    case (DAE.ET_ARRAY(ty = t,arrayDimensions = dims))
      equation
        ss = List.map(dims, dimensionString);
        s1 = Util.stringDelimitListNonEmptyElts(ss, ", ");
        ts = typeString(t);
        res = stringAppendList({"/tp:",ts,"[",s1,"]/"});
      then
        res;
    
    case(DAE.ET_COMPLEX(varLst=vars,complexClassType=ci))
      equation
        s = "DAE.ET_COMPLEX(" +& typeVarsStr(vars) +& "):" +& ClassInf.printStateStr(ci);
      then s;
    
    case (DAE.ET_METATYPE()) then "METATYPE";
    case (DAE.ET_BOXED(_)) then "BOXED";
    case (DAE.ET_NORETCALL()) then "ET_NORETCALL";
    case (DAE.ET_FUNCTION_REFERENCE_VAR()) then "ET_FUNCTION_REFERENCE_VAR";
    case (DAE.ET_FUNCTION_REFERENCE_FUNC(builtin=_)) then "ET_FUNCTION_REFERENCE_FUNC";
    
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"ExpressionDump.typeString failed"});
      then "#ExpressionDump.typeString failed#";
  end matchcontinue;
end typeString;

public function binopSymbol "
function: binopSymbol
  Return a string representation of the Operator."
  input Operator inOperator;
  output String outString;
algorithm
  outString := matchcontinue (inOperator)
    local
      Ident s;
      Operator op;
    
    case op
      equation
        false = Config.typeinfo();
        s = binopSymbol1(op);
      then
        s;
    
    case op
      equation
        true = Config.typeinfo();
        s = binopSymbol2(op);
      then
        s;
  end matchcontinue;
end binopSymbol;

public function binopSymbol1
"function: binopSymbol1
  Helper function to binopSymbol"
  input Operator inOperator;
  output String outString;
algorithm
  outString := match (inOperator)
    case (DAE.ADD(ty = _)) then " + ";
    case (DAE.SUB(ty = _)) then " - ";
    case (DAE.MUL(ty = _)) then " * ";
    case (DAE.DIV(ty = _)) then " / ";
    case (DAE.POW(ty = _)) then " ^ ";
    case (DAE.EQUAL(ty = _)) then " = ";
    case (DAE.ADD_ARR(ty = _)) then " + ";
    case (DAE.SUB_ARR(ty = _)) then " - ";
    case (DAE.MUL_ARR(ty = _)) then " * ";
    case (DAE.DIV_ARR(ty = _)) then " / ";
    case (DAE.POW_ARR(ty = _)) then " ^ ";
    case (DAE.POW_ARR2(ty = _)) then " ^ ";
    case (DAE.MUL_ARRAY_SCALAR(ty = _)) then " * ";
    case (DAE.ADD_ARRAY_SCALAR(ty = _)) then " + ";
    case (DAE.SUB_SCALAR_ARRAY(ty = _)) then " - ";
    case (DAE.POW_SCALAR_ARRAY(ty = _)) then " ^ ";
    case (DAE.POW_ARRAY_SCALAR(ty = _)) then " ^ ";
    case (DAE.MUL_SCALAR_PRODUCT(ty = _)) then " * ";
    case (DAE.MUL_MATRIX_PRODUCT(ty = _)) then " * ";
    case (DAE.DIV_SCALAR_ARRAY(ty = _)) then " / ";
    case (DAE.DIV_ARRAY_SCALAR(ty = _)) then " / ";
  end match;
end binopSymbol1;

public function debugBinopSymbol 
"function: binopSymbol1 
  Helper function to binopSymbol"
  input Operator inOperator;
  output String outString;
algorithm 
  outString := match (inOperator)
    case (DAE.ADD(ty = _)) then " + ";
    case (DAE.SUB(ty = _)) then " - ";
    case (DAE.MUL(ty = _)) then " * ";
    case (DAE.DIV(ty = _)) then " / ";
    case (DAE.POW(ty = _)) then " ^ ";
    case (DAE.EQUAL(ty = _)) then " = ";
    case (DAE.ADD_ARR(ty = _)) then " +ARR ";
    case (DAE.SUB_ARR(ty = _)) then " -ARR ";
    case (DAE.MUL_ARR(ty = _)) then " *ARR ";
    case (DAE.DIV_ARR(ty = _)) then " /ARR ";
    case (DAE.POW_ARR(ty = _)) then " ^ARR ";
    case (DAE.POW_ARR2(ty = _)) then " ^ARR2 ";
    case (DAE.MUL_ARRAY_SCALAR(ty = _)) then " ARR*S ";
    case (DAE.ADD_ARRAY_SCALAR(ty = _)) then " ARR+S ";
    case (DAE.SUB_SCALAR_ARRAY(ty = _)) then " - ";
    case (DAE.POW_SCALAR_ARRAY(ty = _)) then " S^ARR ";
    case (DAE.POW_ARRAY_SCALAR(ty = _)) then " ARR^S ";
    case (DAE.MUL_SCALAR_PRODUCT(ty = _)) then " Dot ";
    case (DAE.MUL_MATRIX_PRODUCT(ty = _)) then " MatrixProd ";
    case (DAE.DIV_SCALAR_ARRAY(ty = _)) then " S/ARR ";
    case (DAE.DIV_ARRAY_SCALAR(ty = _)) then " ARR/S ";
  end match;
end debugBinopSymbol;

protected function binopSymbol2
"function: binopSymbol2
  Helper function to binopSymbol."
  input Operator inOperator;
  output String outString;
algorithm
  outString := match (inOperator)
    local
      Ident ts,s;
      Type t;
    
    case (DAE.ADD(ty = t))
      equation
        ts = typeString(t);
        s = stringAppendList({" +<", ts, "> "});
      then
        s;
    
    case (DAE.SUB(ty = t)) 
      equation
        ts = typeString(t);
        s = stringAppendList({" -<", ts, "> "});
      then
        s;
    
    case (DAE.MUL(ty = t)) 
      equation
        ts = typeString(t);
        s = stringAppendList({" *<", ts, "> "});
      then
        s;
    
    case (DAE.DIV(ty = t))
      equation
        ts = typeString(t);
        s = stringAppendList({" /<", ts, "> "});
      then
        s;
    
    case (DAE.POW(ty = t)) then " ^ ";
    case (DAE.ADD_ARR(ty = t))
      equation
        ts = typeString(t);
        s = stringAppendList({" +<ADD_ARR><", ts, "> "});
      then
        s;
    case (DAE.SUB_ARR(ty = t))
      equation
        ts = typeString(t);
        s = stringAppendList({" -<SUB_ARR><", ts, "> "});
      then
        s;
    case (DAE.MUL_ARR(ty = _)) then " *<MUL_ARRAY> ";
    case (DAE.DIV_ARR(ty = _)) then " / ";
    case (DAE.POW_ARR(ty = _)) then " ^ ";
    case (DAE.POW_ARR2(ty = _)) then " ^ ";
    case (DAE.MUL_ARRAY_SCALAR(ty = _)) then " *<MUL_ARRAY_SCALAR> ";
    case (DAE.ADD_ARRAY_SCALAR(ty = _)) then " + ";
    case (DAE.SUB_SCALAR_ARRAY(ty = _)) then " - ";
    case (DAE.POW_SCALAR_ARRAY(ty = _)) then " ^ ";
    case (DAE.POW_ARRAY_SCALAR(ty = _)) then " ^ ";
    case (DAE.MUL_SCALAR_PRODUCT(ty = _)) then " *<MUL_SCALAR_PRODUCT> ";
    case (DAE.MUL_MATRIX_PRODUCT(ty = _)) then " *<MUL_MATRIX_PRODUCT> ";
    case (DAE.DIV_SCALAR_ARRAY(ty = _)) then " / ";
    case (DAE.DIV_ARRAY_SCALAR(ty = _)) then " / ";
  end match;
end binopSymbol2;

public function unaryopSymbol
"function: unaryopSymbol
  Return string representation of unary operators."
  input Operator inOperator;
  output String outString;
algorithm
  outString:=
  match (inOperator)
    case (DAE.UMINUS(ty = _)) then "-";
    case (DAE.UPLUS(ty = _)) then "+";
    case (DAE.UMINUS_ARR(ty = _)) then "-";
    case (DAE.UPLUS_ARR(ty = _)) then "+";
  end match;
end unaryopSymbol;

public function lbinopSymbol
"function: lbinopSymbol
  Return string representation of logical binary operator."
  input Operator inOperator;
  output String outString;
algorithm
  outString:=
  match (inOperator)
    case (DAE.AND(_)) then " and ";
    case (DAE.OR(_)) then " or ";
  end match;
end lbinopSymbol;

public function lunaryopSymbol
"function: lunaryopSymbol
  Return string representation of logical unary operator."
  input Operator inOperator;
  output String outString;
algorithm
  outString := match (inOperator)
    case (DAE.NOT(_)) then "not ";
  end match;
end lunaryopSymbol;

public function relopSymbol
"function: relopSymbol
  Return string representation of function operator."
  input Operator inOperator;
  output String outString;
algorithm
  outString:=
  match (inOperator)
    case (DAE.LESS(ty = _)) then " < ";
    case (DAE.LESSEQ(ty = _)) then " <= ";
    case (DAE.GREATER(ty = _)) then " > ";
    case (DAE.GREATEREQ(ty = _)) then " >= ";
    case (DAE.EQUAL(ty = _)) then " == ";
    case (DAE.NEQUAL(ty = _)) then " <> ";
  end match;
end relopSymbol;

public function printList
"function: printList
  Print a list of values given a print
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

protected function printRow
"function: printRow
  Print a list of expressions to the Print buffer."
  input list<DAE.Exp> es_1;
algorithm
  printList(es_1, printExp, ",");
end printRow;

public function printListStr
"function: printListStr
  Same as printList, except it returns
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
  outString := matchcontinue (inTypeALst,inFuncTypeTypeAToString,inString)
    local
      Ident s,srest,sep;
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
        s = stringAppendList({s, sep, srest});
      then
        s;
  end matchcontinue;
end printListStr;

public function debugPrintSubscriptStr "
  Print a Subscript into a String."
  input Subscript inSubscript;
  output String outString;
algorithm
  outString := match (inSubscript)
    local
      Ident s;
      DAE.Exp e1;
    case (DAE.WHOLEDIM()) then ":";
    case (DAE.INDEX(exp = e1))
      equation
        s = dumpExpStr(e1,0);
      then
        s;
    case (DAE.SLICE(exp = e1))
      equation
        s = dumpExpStr(e1,0);
      then
        s;
    case (DAE.WHOLE_NONEXP(exp = e1))
      equation
        s = dumpExpStr(e1,0);
      then
        "1:"+&s;
  end match;
end debugPrintSubscriptStr;

public function printSubscriptStr "
  Print a Subscript into a String."
  input Subscript inSubscript;
  output String outString;
algorithm
  outString:=
  match (inSubscript)
    local
      Ident s;
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
        "1:"+&s;
  end match;
end printSubscriptStr;

public function printExpListStr
"function: printExpListStr
 prints a list of expressions with commas between expressions."
  input list<DAE.Exp> expl;
  output String res;
algorithm
  res := stringDelimitList(List.map(expl,printExpStr),", ");
end printExpListStr;

// stefan
public function printExpListStrNoSpace
"function: printExpListStrNoSpace
  same as printExpListStr, but the string will not have any spaces or commas between expressions"
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
  str := matchcontinue(oexp)
    local DAE.Exp e;
    case(NONE()) then "";
    case(SOME(e)) then printExpStr(e);
  end matchcontinue;
end printOptExpStr;

public function printExpStr
"function: printExpStr
  This function prints a complete expression."
  input DAE.Exp e;
  output String s;
algorithm
  s := printExp2Str(e, "\"",NONE(),NONE());
end printExpStr;

public function printExp2Str
"function: printExp2Str
  Helper function to printExpStr."
  input DAE.Exp inExp;
  input String stringDelimiter;
  input Option<tuple<printComponentRefStrFunc,Type_a>> opcreffunc "tuple of function that prints component references and an extra parameter passed through to the function";
  input Option<printCallFunc> opcallfunc "function that prints function calls";
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function printComponentRefStrFunc
    input ComponentRef inComponentRef;
    input Type_a Param;
    output String outString;
  end printComponentRefStrFunc;
  partial function printCallFunc
    input DAE.Exp inExp;
    input String stringDelimiter;
    input Option<tuple<printComponentRefStrFunc,Type_a>> opcreffunc "tuple of function that prints component references and an extra parameter passed through to the function";
    output String outString;
    partial function printComponentRefStrFunc
      input ComponentRef inComponentRef;
      input Type_a Param;
      output String outString;
    end printComponentRefStrFunc;
  end printCallFunc;
algorithm
  outString := matchcontinue (inExp, stringDelimiter, opcreffunc, opcallfunc)
    local
      String s,s_1,s_2,sym,s1,s2,s3,s4,res,fs,argstr,s_4,res2,str,crstr,dimstr,expstr,iterstr,id,s1_1,s2_1,cs,ts,cs_1,ts_1,fs_1,s3_1;
      Integer ival,i,pe1,p1,p2,pc,pt,pf,p,pstop,pstart,pstep;
      Real rval,r;
      ComponentRef c;
      Type t,tp;
      DAE.Exp e1,e2,e,start,stop,step,cr,dim,exp,iterexp,cond,tb,fb;
      Operator op;
      Absyn.Path fcn,lit;
      list<DAE.Exp> args,es;
      printComponentRefStrFunc pcreffunc;
      Type_a creffuncparam;
      printCallFunc pcallfunc;
      Boolean b;
      list<DAE.Exp> aexpl;
      list<list<DAE.Exp>> lstes;
      DAE.MatchType matchTy;
      DAE.ExpType et;
      list<DAE.MatchCase> cases;
      DAE.Pattern pat;
      Absyn.CodeNode code;
      DAE.ReductionIterators riters;
      DAE.ComponentRef name;
      String index_str, scope, tyStr;

    case (DAE.EMPTY(scope = scope, name = name, tyStr = tyStr), _, _, _) 
      then "<EMPTY(scope: " +& scope +& ", name: " +& ComponentReference.printComponentRefStr(name) +& ", ty: " +& tyStr +& ")>";
      
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
    
    case (DAE.SCONST(string = s), stringDelimiter, _, _)
      equation
        s = System.escapedString(s);
        s = stringAppendList({stringDelimiter, s, stringDelimiter});
      then
        s;
    
    case (DAE.BCONST(bool = b), _, _, _) then boolString(b);
    
    case (DAE.CREF(componentRef = c,ty = t), _, SOME((pcreffunc,creffuncparam)), _)
      equation
        s = pcreffunc(c,creffuncparam);
      then
        s;
    
    case (DAE.CREF(componentRef = c,ty = t), _, _, _)
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
        p2 = expPriority(e2);
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
    
    case (e as DAE.CALL(path = fcn,expLst = args), _, _, SOME(pcallfunc))
      equation
        s_2 = pcallfunc(e,stringDelimiter,opcreffunc);
      then
        s_2;
    
    case (e as DAE.CALL(path = fcn,expLst = args), _, _, _)
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
    
    case (DAE.ARRAY(array = es,ty=tp), _, _, _)
      equation
        // s3 = typeString(tp); // adrpo: not used!
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
    
    case (DAE.MATRIX(matrix = lstes,ty=tp), _, _, _)
      equation
        // s3 = typeString(tp); // adrpo: not used!
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
    
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e), _, _, _)
      equation
        s = printExp2Str(e, stringDelimiter, opcreffunc, opcallfunc);
        s_2 = stringAppendList({"Real(",s,")"});
      then
        s_2;
    
    case (DAE.CAST(ty = tp,exp = e), _, _, _)
      equation
        str = typeString(tp);
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
        s_4 = s1_1+& "["+& s4 +& "]";
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
        s = "Tuple" +& printExp2Str(DAE.TUPLE(es), stringDelimiter, opcreffunc, opcallfunc);
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
    
    case (DAE.SHARED_LITERAL(index=i,ty=et), _, _, _)
      equation
        s1 = intString(i);
        s2 = typeString(et);
        s = stringAppendList({"#SHARED_LITERAL_",s1," (",s2,")#"});
      then s;

    case (DAE.PATTERN(pattern=pat),_,_,_)
      then Patternm.patternStr(pat);
        
    case (DAE.CODE(code=code),_,_,_) then "$Code(" +& Dump.printCodeStr(code) +& ")";

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
    case DAE.ENUM_LITERAL(name = _) then "ENUM_LITERAL";
    case DAE.CREF(componentRef = _) then "CREF";
    case DAE.BINARY(exp1 = _) then "BINARY";
    case DAE.UNARY(exp = _) then "UNARY";
    case DAE.LBINARY(exp1 = _) then "LBINARY";
    case DAE.LUNARY(exp = _) then "LUNARY";
    case DAE.RELATION(exp1 = _) then "RELATION";
    case DAE.IFEXP(expCond = _) then "IFEXP";
    case DAE.CALL(path = _) then "CALL";
    case DAE.PARTEVALFUNCTION(path = _) then "PARTEVALFUNCTION";
    case DAE.ARRAY(ty = _) then "ARRAY";
    case DAE.MATRIX(ty = _) then "MATRIX";
    case DAE.RANGE(ty = _) then "RANGE";
    case DAE.TUPLE(PR = _) then "TUPLE";
    case DAE.CAST(ty = _) then "CAST";
    case DAE.ASUB(exp = _) then "ASUB";
    case DAE.TSUB(exp = _) then "TSUB";
    case DAE.SIZE(exp = _) then "SIZE";
    case DAE.CODE(code = _) then "CODE";
    case DAE.EMPTY(scope = _) then "EMPTY";
    case DAE.REDUCTION(reductionInfo = _) then "REDUCTION";
    case DAE.LIST(valList = _) then "LIST";
    case DAE.CONS(car = _) then "CAR";
    case DAE.META_TUPLE(listExp = _) then "META_TUPLE";
    case DAE.META_OPTION(exp = _) then "META_OPTION";
    case DAE.METARECORDCALL(path = _) then "METARECORDCALL";
    case DAE.MATCHEXPRESSION(matchType = _) then "MATCHEXPRESSION";
    case DAE.BOX(exp = _) then "BOX";
    case DAE.UNBOX(exp = _) then "UNBOX";
    case DAE.SHARED_LITERAL(index = _) then "SHARED_LITERAL";
    case DAE.PATTERN(pattern = _) then "PATTERN";
    else "#UNKNOWN EXPRESSION#";
  end match;
end printExpTypeStr;

protected function reductionIteratorStr
  input DAE.ReductionIterator riter;
  output String str;
algorithm
  str := match riter
    local
      String id,str;
      DAE.Exp exp,gexp;
    case (DAE.REDUCTIONITER(id=id,exp=exp,guardExp=NONE()))
      equation
        str = id +& " in " +& printExpStr(exp);
      then str;
    case (DAE.REDUCTIONITER(id=id,exp=exp,guardExp=SOME(gexp)))
      equation
        str = id +& " guard " +& printExpStr(gexp) +& " in " +& printExpStr(exp);
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
"function: expPriority
 Returns a priority number for an expression.
 This function is used to output parenthesis
 when needed, e.g., 3(1+2) should output 3(1+2)
 and not 31+2."
  input DAE.Exp inExp;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inExp)
    case (DAE.ICONST(_)) then 0;
    case (DAE.RCONST(_)) then 0;
    case (DAE.SCONST(_)) then 0;
    case (DAE.BCONST(_)) then 0;
    case (DAE.ENUM_LITERAL(name = _)) then 0;
    case (DAE.CREF(_,_)) then 0;
    case (DAE.ASUB(_,_)) then 0;
    case (DAE.CAST(_,_)) then 0;
    case (DAE.CALL(path=_)) then 0;
    case (DAE.PARTEVALFUNCTION(path=_)) then 0;
    case (DAE.ARRAY(ty = _)) then 0;
    case (DAE.MATRIX(ty= _)) then 0;
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
    case (DAE.UNARY(operator = DAE.UPLUS(_))) then 8;
    case (DAE.UNARY(operator = DAE.UMINUS(_))) then 8;
    case (DAE.UNARY(operator = DAE.UMINUS_ARR(_))) then 8;
    case (DAE.UNARY(operator = DAE.UPLUS_ARR(_))) then 8;
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
    case (DAE.RANGE(ty = _)) then 19;
    case (DAE.IFEXP(expCond = _)) then 21;
    case (DAE.TUPLE(_)) then 23;  /* Not valid in inner expressions, only included here for completeness */
    case (_) then 25;
  end matchcontinue;
end expPriority;

public function printRowStr
"function: printRowStr
  Prints a list of expressions to a string."
  input list<DAE.Exp> es_1;
  input String stringDelimiter;
  output String s;
algorithm
  s := stringDelimitList(List.map3(es_1, printExp2Str, stringDelimiter, NONE(), NONE()), ",");
end printRowStr;

public function printLeftparStr
"function: printLeftparStr
  Print a left parenthesis to a string if priorities require it."
  input Integer inInteger1;
  input Integer inInteger2;
  output String outString;
  output Integer outInteger;
algorithm
  (outString,outInteger) := matchcontinue (inInteger1,inInteger2)
    local Integer x,y,pri1,pri2;
    // prio1 prio2 
    case (x,y)
      equation
        (x > y) = true;
      then
        ("(",0);
    case (pri1,pri2) then ("",pri2);
  end matchcontinue;
end printLeftparStr;

public function printRightparStr
"function: printRightparStr
  Print a right parenthesis to a
 string if priorities require it."
  input Integer inInteger1;
  input Integer inInteger2;
  output String outString;
algorithm
  outString := matchcontinue (inInteger1,inInteger2)
    local Integer x,y;
    case (x,y)
      equation
        (x > y) = true;
      then
        ")";
    case (_,_) then "";
  end matchcontinue;
end printRightparStr;

public function dumpExpGraphviz
"function: dumpExpGraphviz
  Creates a Graphviz Node from an Expression."
  input DAE.Exp inExp;
  output Graphviz.Node outNode;
algorithm
  outNode := matchcontinue (inExp)
    local
      Ident s,s_1,s_2,sym,fs,tystr,istr,id;
      Integer i;
      ComponentRef c;
      Graphviz.Node lt,rt,ct,tt,ft,t1,t2,t3,crt,dimt,expt,itert;
      DAE.Exp e1,e2,e,t,f,start,stop,step,cr,dim,exp,iterexp,cond,ae1;
      Operator op;
      list<Graphviz.Node> argnodes,nodes;
      Absyn.Path fcn;
      list<DAE.Exp> args,es;
      Type ty;
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
        s = System.escapedString(s);
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
        fs = Absyn.pathString(fcn);
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
    
    case (DAE.RANGE(exp = start,expOption = NONE(),range = stop))
      equation
        t1 = dumpExpGraphviz(start);
        t2 = Graphviz.NODE(":",{},{});
        t3 = dumpExpGraphviz(stop);
      then
        Graphviz.NODE("RANGE",{},{t1,t2,t3});
    
    case (DAE.RANGE(exp = start,expOption = SOME(step),range = stop))
      equation
        t1 = dumpExpGraphviz(start);
        t2 = dumpExpGraphviz(step);
        t3 = dumpExpGraphviz(stop);
      then
        Graphviz.NODE("RANGE",{},{t1,t2,t3});
    
    case (DAE.CAST(ty = ty,exp = e))
      equation
        tystr = typeString(ty);
        ct = dumpExpGraphviz(e);
      then
        Graphviz.LNODE("CAST",{tystr},{},{ct});
    
    case (DAE.ASUB(exp = e,sub = ((ae1 as DAE.ICONST(i))::{})))
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
"function: dumpExpStr
  Dumps expression to a string."
  input DAE.Exp inExp;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inExp,inInteger)
    local
      String gen_str,res_str,s,sym,lt,rt,ct,tt,ft,fs,argnodes_1,nodes_1,t1,t2,t3,tystr,istr,crt,dimt,expt,itert,id,tpStr,str;
      Integer level,x,new_level1,new_level2,new_level3,i;
      ComponentRef c;
      DAE.Exp e1,e2,e,t,f,start,stop,step,cr,dim,exp,iterexp,cond,ae1;
      Operator op;
      list<Ident> argnodes,nodes;
      Absyn.Path fcn;
      list<DAE.Exp> args,es;
      Type tp,ty;
      Real r;
      list<list<DAE.Exp>> lstes;
      Boolean b;
    
    case (DAE.ICONST(integer = x),level) /* Graphviz.LNODE(\"ICONST\",{s},{},{}) */
      equation
        gen_str = genStringNTime("   |", level);
        s = intString(x);
        res_str = stringAppendList({gen_str,"ICONST ",s,"\n"});
      then
        res_str;
    
    case (DAE.RCONST(real = r),level) /* Graphviz.LNODE(\"RCONST\",{s},{},{}) */
      equation
        gen_str = genStringNTime("   |", level);
        s = realString(r);
        res_str = stringAppendList({gen_str,"RCONST ",s,"\n"});
      then
        res_str;
    
    case (DAE.SCONST(string = s),level) /* Graphviz.LNODE(\"SCONST\",{s\'\'},{},{}) */
      equation
        gen_str = genStringNTime("   |", level);
        s = System.escapedString(s);
        res_str = stringAppendList({gen_str,"SCONST ","\"", s,"\"\n"});
      then
        res_str;
    
    case (DAE.BCONST(bool = false),level) /* Graphviz.LNODE(\"BCONST\",{\"false\"},{},{}) */
      equation
        gen_str = genStringNTime("   |", level);
        res_str = stringAppendList({gen_str,"BCONST ","false","\n"});
      then
        res_str;
    
    case (DAE.BCONST(bool = true),level) /* Graphviz.LNODE(\"BCONST\",{\"true\"},{},{}) */
      equation
        gen_str = genStringNTime("   |", level);
        res_str = stringAppendList({gen_str,"BCONST ","true","\n"});
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
    
    case (DAE.CREF(componentRef = c,ty=ty),level) /* Graphviz.LNODE(\"CREF\",{s},{},{}) */
      equation
        gen_str = genStringNTime("   |", level);
        s = /*ComponentReference.printComponentRefStr*/ComponentReference.debugPrintComponentRefTypeStr(c);
        tpStr= typeString(ty);
        res_str = stringAppendList({gen_str,"CREF ",s," CREFTYPE:",tpStr,"\n"});
      then
        res_str;
    
    case (exp as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),level) /* Graphviz.LNODE(\"BINARY\",{sym},{},{lt,rt}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        sym = debugBinopSymbol(op);
        tp = Expression.typeof(exp);
        str = typeString(tp);
        lt = dumpExpStr(e1, new_level1);
        rt = dumpExpStr(e2, new_level2);
        res_str = stringAppendList({gen_str,"BINARY ",sym," ",str,"\n",lt,rt,""});
      then
        res_str;
    
    case (DAE.UNARY(operator = op,exp = e),level) /* Graphviz.LNODE(\"UNARY\",{sym},{},{ct}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        sym = unaryopSymbol(op);
        ct = dumpExpStr(e, new_level1);
        str = "expType:"+&typeString(Expression.typeof(e))+&" optype:"+&typeString(Expression.typeofOp(op))+&"\n";
        res_str = stringAppendList({gen_str,"UNARY ",sym," ",str,"\n",ct,""});
      then
        res_str;
    
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),level) /* Graphviz.LNODE(\"LBINARY\",{sym},{},{lt,rt}) */
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
    
    case (DAE.LUNARY(operator = op,exp = e),level) /* Graphviz.LNODE(\"LUNARY\",{sym},{},{ct}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        sym = lunaryopSymbol(op);
        ct = dumpExpStr(e, new_level1);
        res_str = stringAppendList({gen_str,"LUNARY ",sym,"\n",ct,""});
      then
        res_str;
    
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),level) /* Graphviz.LNODE(\"RELATION\",{sym},{},{lt,rt}) */
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
    
    case (DAE.IFEXP(expCond = cond,expThen = t,expElse = f),level) /* Graphviz.NODE(\"IFEXP\",{},{ct,tt,ft}) */
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
    
    case (DAE.CALL(path = fcn,expLst = args),level) /* Graphviz.LNODE(\"CALL\",{fs},{},argnodes) Graphviz.NODE(\"ARRAY\",{},nodes) */
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
        tpStr = typeString(tp);
        res_str = stringAppendList({gen_str,"ARRAY scalar:",s," tp: ",tpStr,"\n",nodes_1});
      then
        res_str;
    
    case (DAE.TUPLE(PR = es),level) /* Graphviz.NODE(\"TUPLE\",{},nodes) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        nodes = List.map1(es, dumpExpStr, new_level1);
        nodes_1 = stringAppendList(nodes);
        res_str = stringAppendList({gen_str,"TUPLE ",nodes_1,"\n"});
      then
        res_str;
    
    case (DAE.MATRIX(matrix = lstes),level) /* Graphviz.LNODE(\"MATRIX\",{s\'\'},{},{}) */
      equation
        gen_str = genStringNTime("   |", level);
        s = stringDelimitList(List.map1(lstes, printRowStr, "\""), "},{");
        res_str = stringAppendList({gen_str,"MATRIX ","\n","{{",s,"}}","\n"});
      then
        res_str;
    
    case (DAE.RANGE(exp = start,expOption = NONE(),range = stop),level) /* Graphviz.NODE(\"RANGE\",{},{t1,t2,t3}) */
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
    
    case (DAE.RANGE(exp = start,expOption = SOME(step),range = stop),level) /* Graphviz.NODE(\"RANGE\",{},{t1,t2,t3}) */
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
    
    case (DAE.CAST(ty = ty,exp = e),level) /* Graphviz.LNODE(\"CAST\",{tystr},{},{ct}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        tystr = typeString(ty);
        ct = dumpExpStr(e, new_level1);
        res_str = stringAppendList({gen_str,"CAST ","\n",ct,""});
      then
        res_str;
    
    case (DAE.ASUB(exp = e,sub = ((ae1 as DAE.ICONST(i))::{})),level) /* Graphviz.LNODE(\"ASUB\",{s},{},{ct}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        ct = dumpExpStr(e, new_level1);
        istr = intString(i);
        s = stringAppendList({"[",istr,"]"});
        res_str = stringAppendList({gen_str,"ASUB ",s,"\n",ct,""});
      then
        res_str;
    
    case (DAE.SIZE(exp = cr,sz = SOME(dim)),level) /* Graphviz.NODE(\"SIZE\",{},{crt,dimt}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        crt = dumpExpStr(cr, new_level1);
        dimt = dumpExpStr(dim, new_level2);
        res_str = stringAppendList({gen_str,"SIZE ","\n",crt,dimt,""});
      then
        res_str;
    
    case (DAE.SIZE(exp = cr,sz = NONE()),level) /* Graphviz.NODE(\"SIZE\",{},{crt}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        crt = dumpExpStr(cr, new_level1);
        res_str = stringAppendList({gen_str,"SIZE ","\n",crt,""});
      then
        res_str;
    
    case (DAE.REDUCTION(reductionInfo=DAE.REDUCTIONINFO(path = fcn),expr = exp,iterators={DAE.REDUCTIONITER(exp=iterexp)}),level) /* Graphviz.LNODE(\"REDUCTION\",{fs},{},{expt,itert}) */
      equation
        gen_str = genStringNTime("   |", level);
        new_level1 = level + 1;
        new_level2 = level + 1;
        fs = Absyn.pathString(fcn);
        expt = dumpExpStr(exp, new_level1);
        itert = dumpExpStr(iterexp, new_level2);
        res_str = stringAppendList({gen_str,"REDUCTION ","\n",expt,itert,""});
      then
        res_str;
    
    case (_,level) /* Graphviz.NODE(\"#UNKNOWN EXPRESSION# ----eeestr \",{},{}) */
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
      Ident str,new_str,res_str;
      Integer new_level,level;
    
    case (str,0) then "";  /* n */
    
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
  s := matchcontinue(e1,e2)
    case(e1,e2)
      equation
        true = Expression.expEqual(e1,e2);
      then
        "";
    case(e1,e2)
      equation
        false = Expression.expEqual(e1,e2);
        s = printExpStr(e1) +& " =!= " +& printExpStr(e2) +& "\n";
      then
        s;
  end matchcontinue;
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
"function typeOfString
  Retrieves the Type of the Expression as a String"
  input DAE.Exp inExp;
  output String str;
protected
  Type ty;
algorithm
  ty := Expression.typeof(inExp);
  str := typeString(ty);
end typeOfString;

protected function typeVarsStr "help function to typeString"
  input list<Var> vars;
  output String s;
algorithm
  s := stringDelimitList(List.map(vars,typeVarString),",");
end typeVarsStr;

protected function typeVarString "help function to typeVarsStr"
  input Var v;
  output String s;
algorithm
  s := match (v)
    local 
      String name; Type tp;
    
    case(DAE.COMPLEX_VAR(name,tp)) 
      equation
        s = name +& ":" +& typeString(tp);
      then s;
  end match;
end typeVarString;

public function debugPrintComponentRefExp "
This function takes an DAE.Exp and tries to print ComponentReferences.
Uses debugPrint.ComponentRefTypeStr, which gives type information to stdout.
NOTE Only used for debugging.
"
  input DAE.Exp inExp;
  output String str;
algorithm str := matchcontinue(inExp)
  local
    ComponentRef cr;
    String s1;
    list<DAE.Exp> expl;
  case(DAE.CREF(cr,_)) then ComponentReference.debugPrintComponentRefTypeStr(cr);
  case(DAE.ARRAY(_,_,expl))
    equation
      s1 = "{" +& stringAppendList(List.map(expl,debugPrintComponentRefExp)) +& "}";
    then
      s1;
  case(inExp) then printExpStr(inExp); // when not cref, print expression anyways since it is used for some debugging.
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
    
    case DAE.DIM_UNKNOWN() then ":";
    
    case DAE.DIM_ENUM(enumTypeName = p) 
      equation
        s = Absyn.pathString(p);
      then 
        s;
    
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
"function: printSubscript
  Print a Subscript."
  input Subscript inSubscript;
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
"function: printExp
  This function prints a complete expression."
  input DAE.Exp e;
algorithm
  printExp2(e, 0);
end printExp;

protected function printExp2
"function: printExp2
  Helper function to printExpression."
  input DAE.Exp inExp;
  input Integer inInteger;
algorithm
  _ := matchcontinue (inExp,inInteger)
    local
      Ident s,sym,fs,rstr,str;
      Integer pri2_1,pri2,pri3,pri1,i;
      Real r;
      ComponentRef c;
      DAE.Exp e1,e2,e21,e22,e,t,f,start,stop,step,cr,dim,exp,iterexp,cond;
      Operator op;
      Type ty,ty2,expTy;
      Absyn.Path fcn,enum_lit;
      list<DAE.Exp> args,es;
      list<list<DAE.Exp>> lstes;
      DAE.Exp ae1;
      Boolean b;
      DAE.MatchType matchTy;
      list<DAE.MatchCase> cases;
      DAE.Pattern pat;
    
    case (DAE.ICONST(integer = i),_)
      equation
        s = intString(i);
        Print.printBuf(s);
      then
        ();
    
    case (DAE.RCONST(real = r),_)
      equation
        s = realString(r);
        Print.printBuf(s);
      then
        ();
    
    case (DAE.SCONST(string = s),_)
      equation
        s = System.escapedString(s);
        Print.printBuf("\"");
        Print.printBuf(s);
        Print.printBuf("\"");
      then
        ();
    
    case (DAE.BCONST(bool = b),_)
      equation
        Print.printBuf(boolString(b));
      then
        ();
    
    case (DAE.CREF(componentRef = c),_)
      equation
        ComponentReference.printComponentRef(c);
      then
        ();

    case (DAE.ENUM_LITERAL(name = enum_lit), _)
      equation
        s = Absyn.pathString(enum_lit);
        Print.printBuf(s);
      then
        ();

    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.SUB(ty = ty)),exp2 = (e2 as DAE.BINARY(exp1 = e21,operator = DAE.SUB(ty = ty2),exp2 = e22))),pri1)
      equation
        sym = binopSymbol(op);
        pri2_1 = binopPriority(op);
        pri2 = pri2_1 + 1;
        pri3 = printLeftpar(pri1, pri2) "binary minus have higher priority than itself" ;
        printExp2(e1, pri3);
        Print.printBuf(sym);
        printExp2(e2, pri2);
        printRightpar(pri1, pri2);
      then
        ();
    
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation
        sym = binopSymbol(op);
        pri2 = binopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        printExp2(e1, pri3);
        Print.printBuf(sym);
        printExp2(e2, pri2);
        printRightpar(pri1, pri2);
      then
        ();
    
    case (DAE.UNARY(operator = op,exp = e),pri1)
      equation
        sym = unaryopSymbol(op);
        pri2 = unaryopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        Print.printBuf(sym);
        printExp2(e, pri3);
        printRightpar(pri1, pri2);
      then
        ();
    
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation
        sym = lbinopSymbol(op);
        pri2 = lbinopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        printExp2(e1, pri3);
        Print.printBuf(sym);
        printExp2(e2, pri2);
        printRightpar(pri1, pri2);
      then
        ();
    
    case (DAE.LUNARY(operator = op,exp = e),pri1)
      equation
        sym = lunaryopSymbol(op);
        pri2 = lunaryopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        Print.printBuf(sym);
        printExp2(e, pri3);
        printRightpar(pri1, pri2);
      then
        ();
    
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation
        sym = relopSymbol(op);
        pri2 = relopPriority(op);
        pri3 = printLeftpar(pri1, pri2);
        printExp2(e1, pri3);
        Print.printBuf(sym);
        printExp2(e2, pri2);
        printRightpar(pri1, pri2);
      then
        ();
    
    case (DAE.IFEXP(expCond = cond,expThen = t,expElse = f),pri1)
      equation
        Print.printBuf("if ");
        printExp2(cond, 0);
        Print.printBuf(" then ");
        printExp2(t, 0);
        Print.printBuf(" else ");
        printExp2(f, 0);
      then
        ();
    
    case (DAE.CALL(path = fcn,expLst = args),_)
      equation
        fs = Absyn.pathString(Absyn.makeNotFullyQualified(fcn));
        Print.printBuf(fs);
        Print.printBuf("(");
        printList(args, printExp, ",");
        Print.printBuf(")");
      then
        ();
    
    case (DAE.PARTEVALFUNCTION(path = fcn, expList = args),_)
      equation
        fs = Absyn.pathString(Absyn.makeNotFullyQualified(fcn));
        Print.printBuf("function ");
        Print.printBuf(fs);
        Print.printBuf("(");
        printList(args, printExp, ",");
        Print.printBuf(")");
      then
        ();

    case (DAE.ARRAY(array = es),_)
      equation
        Print.printBuf("{") "Print.printBuf \"This an array: \" &" ;
        printList(es, printExp, ",");
        Print.printBuf("}");
      then
        ();
    
    case (DAE.TUPLE(PR = es),_) /* PR. */
      equation
        Print.printBuf("(");
        printList(es, printExp, ",");
        Print.printBuf(")");
      then
        ();
    
    case (DAE.MATRIX(matrix = lstes),_)
      equation
        Print.printBuf("<matrix>[");
        printList(lstes, printRow, ";");
        Print.printBuf("]");
      then
        ();
    
    case (DAE.RANGE(exp = start,expOption = NONE(),range = stop),pri1)
      equation
        pri2 = 41;
        pri3 = printLeftpar(pri1, pri2);
        printExp2(start, pri3);
        Print.printBuf(":");
        printExp2(stop, pri3);
        printRightpar(pri1, pri2);
      then
        ();
    
    case (DAE.RANGE(exp = start,expOption = SOME(step),range = stop),pri1)
      equation
        pri2 = 41;
        pri3 = printLeftpar(pri1, pri2);
        printExp2(start, pri3);
        Print.printBuf(":");
        printExp2(step, pri3);
        Print.printBuf(":");
        printExp2(stop, pri3);
        printRightpar(pri1, pri2);
      then
        ();
    
    case (DAE.CAST(ty = expTy,exp = e),_)
      equation
        false = Config.modelicaOutput();
        s = "/*" +& typeString(expTy) +& "*/";
        Print.printBuf(s +& "(");
        printExp(e);
        Print.printBuf(")");
      then
        ();

    case (DAE.CAST(ty = _,exp = e),_)
      equation
        true = Config.modelicaOutput();
        printExp(e);
      then
        ();

    case (DAE.ASUB(exp = e,sub = ((ae1 as DAE.ICONST(i)))::{}),pri1)
      equation
        pri2 = 51;
        pri3 = printLeftpar(pri1, pri2);
        printExp2(e, pri3);
        printRightpar(pri1, pri2);
        Print.printBuf("[");
        s = intString(i);
        Print.printBuf(s);
        Print.printBuf("]");
      then
        ();

    case (DAE.ASUB(exp = e,sub = es),pri1)
      equation
        pri2 = 51;
        pri3 = printLeftpar(pri1, pri2);
        printExp2(e, pri3);
        printRightpar(pri1, pri2);
        Print.printBuf("[");
        s = stringDelimitList(List.map(es,printExpStr),",");
        Print.printBuf(s);
        Print.printBuf("]");
      then
        ();
    
    case ((e as DAE.SIZE(exp = cr,sz = SOME(dim))),_)
      equation
        str = printExpStr(e);
        Print.printBuf(str);
      then
        ();
    
    case ((e as DAE.SIZE(exp = cr,sz = NONE())),_)
      equation
        str = printExpStr(e);
        Print.printBuf(str);
      then
        ();
    
    case ((e as DAE.REDUCTION(reductionInfo = _)),_)
      equation
        str = printExpStr(e);
        Print.printBuf(str);
      then
        ();

    // MetaModelica list
    case (DAE.LIST(valList=es),_)
      equation
        Print.printBuf("List(");
        printList(es, printExp, ",");
        Print.printBuf(")");
      then
        ();

    case (DAE.META_OPTION(NONE()),_)
      equation
        Print.printBuf("NONE()");
      then
        ();

    case (DAE.META_OPTION(SOME(exp)),_)
      equation
        Print.printBuf("SOME(");
        printExp(exp);
        Print.printBuf(")");
      then
        ();

    case (DAE.META_TUPLE(es),_)
      equation
        Print.printBuf("Tuple(");
        printList(es, printExp, ",");
        Print.printBuf(")");
      then
        ();

    // MetaModelica list cons
    case (DAE.CONS(car=e1,cdr=e2),_)
      equation
        Print.printBuf("listCons(");
        printExp(e1);
        Print.printBuf(",");
        printExp(e2);
        Print.printBuf(")");
      then
        ();

      // MetaModelica Uniontype Constructor
    case (DAE.METARECORDCALL(path = fcn, args=args),_)
      equation
        fs = Absyn.pathString(fcn);
        Print.printBuf(fs);
        Print.printBuf("(");
        printList(args, printExp, ",");
        Print.printBuf(")");
      then
        ();

    case (DAE.MATCHEXPRESSION(matchType=matchTy,inputs=es,cases=cases), _)
      equation
        Print.printBuf(printMatchType(matchTy));
        Print.printBuf(" (");
        printList(es, printExp, ",");
        Print.printBuf(") \n");
        Print.printBuf(stringAppendList(List.map(cases,printCase2Str)));
        Print.printBuf("  end ");
        Print.printBuf(printMatchType(matchTy));
      then ();

    case (DAE.BOX(e),_)
      equation
        Print.printBuf("#(");
        printExp(e);
        Print.printBuf(")");
      then
        ();

    case (DAE.UNBOX(exp=e),_)
      equation
        Print.printBuf("unbox(");
        printExp(e);
        Print.printBuf(")");
      then
        ();

    case (DAE.PATTERN(pattern=pat),_)
      equation
        Print.printBuf(Patternm.patternStr(pat));
      then
        ();

    case (e,_)
      equation
        // debug_print("unknown expression - printExp2: ", e);
        Print.printBuf("#UNKNOWN EXPRESSION# ----eee " +& printExpStr(e));
      then
        ();
  end matchcontinue;
end printExp2;

protected function printLeftpar
"function: printLeftpar
  Print a left paranthesis if priorities require it."
  input Integer inInteger1;
  input Integer inInteger2;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inInteger1,inInteger2)
    local Integer x,y,pri1,pri2;
    case (x,y) /* prio1 prio2 */
      equation
        (x > y) = true;
        Print.printBuf("(");
      then
        0;
    case (pri1,pri2) then pri2;
  end matchcontinue;
end printLeftpar;

public function binopPriority
"function: binopPriority
  Returns a priority number for each operator.
  Used to determine when parenthesis in expressions is required.
  Priorities:
    and, or    10
    not    11
    <, >, =, != etc.  21
    bin +    32
    bin -    33
          35
    /      36
    unary +, unary -  37
    ^      38
    :      41
    {}    51

  LS: Changed precedence for unary +-
   which must be higher than binary operators but lower than power
   according to e.g. matlab

  LS: Changed precedence for binary - , should be higher than + and also
      itself, but this is specially handled in printExp2 and printExp2Str"
  input Operator inOperator;
  output Integer outInteger;
algorithm
  outInteger := match (inOperator)
    case (DAE.ADD(ty = _)) then 32;
    case (DAE.SUB(ty = _)) then 33;
    case (DAE.ADD_ARR(ty = _)) then 32;
    case (DAE.SUB_ARR(ty = _)) then 33;
    case (DAE.MUL_ARR(ty = _)) then 35;
    case (DAE.DIV_ARR(ty = _)) then 36;
    case (DAE.POW_ARR(ty = _)) then 38;
    case (DAE.POW_ARR2(ty = _)) then 38;
    case (DAE.MUL(ty = _)) then 35;
    case (DAE.MUL_ARRAY_SCALAR(ty = _)) then 35;
    case (DAE.ADD_ARRAY_SCALAR(ty = _)) then 32;
    case (DAE.SUB_SCALAR_ARRAY(ty = _)) then 33;
    case (DAE.MUL_SCALAR_PRODUCT(ty = _)) then 35;
    case (DAE.MUL_MATRIX_PRODUCT(ty = _)) then 35;
    case (DAE.DIV(ty = _)) then 36;
    case (DAE.DIV_SCALAR_ARRAY(ty = _)) then 36;
    case (DAE.DIV_ARRAY_SCALAR(ty = _)) then 36;
    case (DAE.POW(ty = _)) then 38;
    case (DAE.POW_SCALAR_ARRAY(ty = _)) then 38;
    case (DAE.POW_ARRAY_SCALAR(ty = _)) then 38;
  end match;
end binopPriority;

public function unaryopPriority
"function: unaryopPriority
  Determine unary operator priorities, see binopPriority."
  input Operator inOperator;
  output Integer outInteger;
algorithm
  outInteger := match (inOperator)
    case (DAE.UMINUS(ty = _)) then 37;
    case (DAE.UPLUS(ty = _)) then 37;
    case (DAE.UMINUS_ARR(ty = _)) then 37;
    case (DAE.UPLUS_ARR(ty = _)) then 37;
  end match;
end unaryopPriority;

public function lbinopPriority
"function: lbinopPriority
  Determine logical binary operator
  priorities, see binopPriority."
  input Operator inOperator;
  output Integer outInteger;
algorithm
  outInteger := match (inOperator)
    case (DAE.AND(_)) then 10;
    case (DAE.OR(_)) then 10;
  end match;
end lbinopPriority;

public function lunaryopPriority
"function: lunaryopPriority
  Determine logical unary operator
  priorities, see binopPriority."
  input Operator inOperator;
  output Integer outInteger;
algorithm
  outInteger := match (inOperator)
    case (DAE.NOT(_)) then 11;
  end match;
end lunaryopPriority;

public function relopPriority
"function: relopPriority
  Determine function operator
  priorities, see binopPriority."
  input Operator inOperator;
  output Integer outInteger;
algorithm
  outInteger := match (inOperator)
    case (DAE.LESS(ty = _)) then 21;
    case (DAE.LESSEQ(ty = _)) then 21;
    case (DAE.GREATER(ty = _)) then 21;
    case (DAE.GREATEREQ(ty = _)) then 21;
    case (DAE.EQUAL(ty = _)) then 21;
    case (DAE.NEQUAL(ty = _)) then 21;
  end match;
end relopPriority;

public function parenthesize
"function: parenthesize
  Adds parentheisis to a string if expression
  and parent expression priorities requires it."
  input String inString1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Boolean rightOpParenthesis "true for right hand side operators";
  output String outString;
algorithm
  outString := matchcontinue (inString1,inInteger2,inInteger3,rightOpParenthesis)
    local
      Ident str_1,str;
      Integer pparent,pexpr;
    
    // expr, prio. parent expr, prio. expr
    case (str,pparent,pexpr,rightOpParenthesis)
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

protected function printRightpar
"function: printRightpar
  Print a left paranthesis if priorities require it."
  input Integer inInteger1;
  input Integer inInteger2;
algorithm
  _ := matchcontinue (inInteger1,inInteger2)
    local Integer x,y;
    case (x,y) /* prio1 prio2 */
      equation
        (x > y) = true;
        Print.printBuf(")");
      then
        ();
    case (_,_) then ();
  end matchcontinue;
end printRightpar;

protected function dumpSimplifiedExp
"a function to dump simplified expressions"
  input DAE.Exp inExp;
  input DAE.Exp outExp;
algorithm
  _ := matchcontinue(inExp,outExp)
    case(inExp,outExp) equation
      true = Expression.expEqual(inExp,outExp);
      then ();
    case(inExp,outExp) equation
      false= Expression.expEqual(inExp,outExp);
      print(printExpStr(inExp));print( " simplified to "); print(printExpStr(outExp));print("\n");
      then ();
  end matchcontinue;
end dumpSimplifiedExp;

public function tmpPrint "
"
  input list<Option <Integer>> inLst;
algorithm
  _ := matchcontinue(inLst)
    local
      Integer x;
      list<Option<Integer>> lst;
  
    case({}) then ();
    
    case(SOME(x) :: lst)
      equation
        print(intString(x)); print(" ,");
        tmpPrint(lst);
      then ();
    
    case(_ :: lst)
      equation
        tmpPrint(lst);
      then ();
  end matchcontinue;
end tmpPrint;

end ExpressionDump;

