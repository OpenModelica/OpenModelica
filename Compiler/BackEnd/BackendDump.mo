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

encapsulated package BackendDump
" file:        BackendDump.mo
  package:     BackendDump
  description: Unparsing the BackendDAE structure

  RCS: $Id$
"

public import BackendDAE;
public import DAE;

protected import Absyn;
protected import Algorithm;
protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendVariable;
protected import BackendEquation;
protected import ComponentReference;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import IOStream;
protected import List;
protected import SCode;
protected import Util;
protected import ClassInf;

public function printComponentRefStrDIVISION
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inVars;
  output String outString;
algorithm 
  outString := matchcontinue(inCref,inVars)
    local 
      DAE.ComponentRef c,co;
      BackendDAE.Variables variables;
      String sc;
    case(c,variables)
      equation
        ((BackendDAE.VAR(varName=co):: _),_) = BackendVariable.getVar(c,variables);
        sc = ComponentReference.printComponentRefStr(co);
      then
        sc;
    case(c,variables)
      equation
        sc = ComponentReference.printComponentRefStr(c);
      then
        sc;
  end matchcontinue;
end printComponentRefStrDIVISION;

public function printCallFunction2StrDIVISION
"function: printCallFunction2Str
  Print the exp of typ DAE.CALL."
  input DAE.Exp inExp;
  input String stringDelimiter;
  input Option<tuple<printComponentRefStrFunc,Type_a>> opcreffunc "tuple of function that print component references and a extra parameter passet throug the function";
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function printComponentRefStrFunc
    input DAE.ComponentRef inComponentRef;
    input Type_a Param;
    output String outString;
  end printComponentRefStrFunc;
algorithm
  outString := matchcontinue (inExp,stringDelimiter,opcreffunc)
    local
      Expression.Ident s,s_1,s_2,fs,argstr;
      Absyn.Path fcn;
      list<DAE.Exp> args;
      DAE.Exp e1,e2;
      Expression.Type ty;
    case( DAE.CALL(path = Absyn.IDENT("DIVISION"), expLst = {e1,e2,DAE.SCONST(_)}, attr = DAE.CALL_ATTR(ty = ty)), _, _)
      equation
        s = ExpressionDump.printExp2Str(DAE.BINARY(e1,DAE.DIV(ty),e2),stringDelimiter,opcreffunc, SOME(printCallFunction2StrDIVISION));
      then
        s;
    case( DAE.CALL(path = Absyn.IDENT("DIVISION_ARRAY_SCALAR"),expLst = {e1,e2,DAE.SCONST(_)}, attr = DAE.CALL_ATTR(ty =ty)), _, _)
      equation
        s = ExpressionDump.printExp2Str(DAE.BINARY(e1,DAE.DIV_ARRAY_SCALAR(ty),e2),stringDelimiter,opcreffunc, SOME(printCallFunction2StrDIVISION));
      then
        s;
    case( DAE.CALL(path = Absyn.IDENT("DIVISION_SCALAR_ARRAY"),expLst = {e1,e2,DAE.SCONST(_)}, attr = DAE.CALL_ATTR(ty =ty)), _, _)
      equation
        s = ExpressionDump.printExp2Str(DAE.BINARY(e1,DAE.DIV_SCALAR_ARRAY(ty),e2),stringDelimiter,opcreffunc, SOME(printCallFunction2StrDIVISION));
      then
        s;
    case (DAE.CALL(path = fcn,expLst = args), _,_)
      equation
        fs = Absyn.pathString(fcn);
        argstr = stringDelimitList(
          List.map3(args, ExpressionDump.printExp2Str, stringDelimiter,opcreffunc, SOME(printCallFunction2StrDIVISION)), ",");
        s = stringAppend(fs, "(");
        s_1 = stringAppend(s, argstr);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;
  end matchcontinue;
end printCallFunction2StrDIVISION;

public function printTuple
  input list<tuple<DAE.ComponentRef,Integer>> outTuple;
algorithm
  _ := matchcontinue(outTuple)
    local
      DAE.ComponentRef currVar;
      Integer currInd;
      list<tuple<DAE.ComponentRef,Integer>> restTuple;
    case ({}) then ();
    case ((currVar,currInd)::restTuple)
      equation
        Debug.fcall(Flags.VAR_INDEX,print, ComponentReference.printComponentRefStr(currVar))  ;
        Debug.fcall(Flags.VAR_INDEX,print,":   ");
        Debug.fcall(Flags.VAR_INDEX,print,intString(currInd));
        Debug.fcall(Flags.VAR_INDEX,print,"\n");
        printTuple(restTuple);
      then ();
    case (_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"printTuple() failed"});
    then fail();
  end matchcontinue;
end printTuple;

protected function printPrioTuplesStr
"Debug function for printing the priorities of state selection to a string"
  input tuple<DAE.ComponentRef,Integer,Real> prioTuples;
  output String str;
algorithm
  str := matchcontinue(prioTuples)
    local DAE.ComponentRef cr; Real prio; String s1,s2;
    case((cr,_,prio))
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = realString(prio);
        str = stringAppendList({"(",s1,", ",s2,")"});
      then str;
  end matchcontinue;
end printPrioTuplesStr;

public function printEquations
  input list<Integer> inIntegerLst;
  input BackendDAE.EqSystem syst;
algorithm
  _:=
  match (inIntegerLst,syst)
    local
      BackendDAE.Value n;
      list<BackendDAE.Value> rest;
      BackendDAE.BackendDAE dae;
    case ({},_) then ();
    case ((n :: rest),syst)
      equation
        printEquations(rest, syst);
        printEquationNo(n, syst);
      then
        ();
  end match;
end printEquations;

protected function printEquationNo "function: printEquationNo
  author: PA
  Helper function to print_equations"
  input Integer inInteger;
  input BackendDAE.EqSystem syst;
algorithm
  _:=
  match (inInteger,syst)
    local
      BackendDAE.Value eqno_1,eqno;
      BackendDAE.Equation eq;
      BackendDAE.EquationArray eqns;
    case (eqno,BackendDAE.EQSYSTEM(orderedEqs = eqns))
      equation
        eqno_1 = eqno - 1;
        eq = BackendDAEUtil.equationNth(eqns, eqno_1);
        printEquation(eq);
      then
        ();
  end match;
end printEquationNo;

public function printEquation "function: printEquation
  author: PA

  Helper function to print_equations
"
  input BackendDAE.Equation inEquation;
algorithm
  _:=
  match (inEquation)
    local
      String s1,s2,res;
      DAE.Exp e1,e2;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation w;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," = ",s2,"\n"});
        print(res);
      then
        ();
    case (BackendDAE.WHEN_EQUATION(whenEquation = w))
      equation
        (cr,e2) = BackendEquation.getWhenEquationExpr(w);
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," =  ",s2,"\n"});
        print(res);
      then
        ();
  end match;
end printEquation;

public function dumpEquation "function: dumpEquation
  author: Frenkel TUD

"
  input BackendDAE.Equation inEquation;
algorithm
  _:=
  match (inEquation)
    local
      String s1,s2,res;
      DAE.Exp e1,e2;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation w;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2))
      equation
        ExpressionDump.dumpExp(e1);
        print("=\n");
        ExpressionDump.dumpExp(e2);
      then
        ();
    case (_)
      then
        ();
  end match;
end dumpEquation;

protected function printVarsStatistics "function: printVarsStatistics
  author: PA

  Prints statistics on variables, currently depth of BinTree, etc.
"
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables inVariables2;
algorithm
  _:=
  matchcontinue (inVariables1,inVariables2)
    local
      String lenstr,bstr;
      BackendDAE.VariableArray v1,v2;
      BackendDAE.Value bsize1,n1,bsize2,n2;
    case (BackendDAE.VARIABLES(varArr = v1,bucketSize = bsize1,numberOfVars = n1),BackendDAE.VARIABLES(varArr = v2,bucketSize = bsize2,numberOfVars = n2))
      equation
        print("Variable Statistics\n");
        print("===================\n");
        print("Number of variables: ");
        lenstr = intString(n1);
        print(lenstr);
        print("\n");
        print("Bucket size for variables: ");
        bstr = intString(bsize1);
        print(bstr);
        print("\n");
        print("Number of known variables: ");
        lenstr = intString(n2);
        print(lenstr);
        print("\n");
        print("Bucket size for known variables: ");
        bstr = intString(bsize1);
        print(bstr);
        print("\n");
      then
        ();
  end matchcontinue;
end printVarsStatistics;

public function dumpTypeStr
"Dump BackendDAE.Type to a string."
  input BackendDAE.Type inType;
  output String outString;
algorithm
  outString:=
  match (inType)
    local
      String s1,s2,str;
      list<String> l;
    case DAE.T_INTEGER(source = _) then "Integer ";
    case DAE.T_REAL(source = _) then "Real ";
    case DAE.T_BOOL(source = _) then "Boolean ";
    case DAE.T_STRING(source = _) then "String ";

    case DAE.T_ENUMERATION(names = l)
      equation
        s1 = stringDelimitList(l, ", ");
        s2 = stringAppend("enumeration(", s1);
        str = stringAppend(s2, ")");
      then
        str;
    case DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_)) then "ExternalObject ";
  end match;
end dumpTypeStr;

public function dumpTearing
" function: dumpTearing
  autor: Frenkel TUD
  Dump tearing vars and residual equations."
  input list<list<Integer>> inResEqn;
  input list<list<Integer>> inTearVar;
algorithm
  _:=
  match (inResEqn,inTearVar)
    local
      list<Integer> tearingvars,residualeqns;
      list<list<Integer>> r,t;
      list<String> str_r,str_t;
      String str_r_f,str_r_1,str_t_f,str_t_1,str,sr,st;
    case (residualeqns::r,tearingvars::t)
      equation
        str_r = List.map(residualeqns, intString);
        str_r_f = stringDelimitList(str_r, ", ");
        str_r_1 = stringAppend(str_r_f, "\n");
        sr = stringAppend("ResidualEqns: ",str_r_1);
        str_t = List.map(tearingvars, intString);
        str_t_f = stringDelimitList(str_t, ", ");
        str_t_1 = stringAppend(str_t_f, "\n");
        st = stringAppend("TearingVars: ",str_t_1);
        str = stringAppend(sr, st);
        print(str);
        print("\n");
        dumpTearing(r,t);
      then
        ();
  end match;
end dumpTearing;

public function dumpBackendDAEEqnList
  input list<BackendDAE.Equation> inBackendDAEEqnList;
  input String header;
  input Boolean printExpTree;
algorithm
   print(header);
   dumpBackendDAEEqnList2(inBackendDAEEqnList,printExpTree);
   print("===================\n");
end dumpBackendDAEEqnList;

protected function dumpBackendDAEEqnList2
  input list<BackendDAE.Equation> inBackendDAEEqnList;
  input Boolean printExpTree;
algorithm
  _ := matchcontinue (inBackendDAEEqnList,printExpTree)
    local
      DAE.Exp e1_1,e2_1,e1,e2,e_1,e;
      String str;
      list<String> strList;
      list<BackendDAE.Equation> res;
      list<DAE.Exp> expList,expList2;
      Integer i;
      DAE.ElementSource source "the element source";

     case ({},_) then ();
     case (BackendDAE.EQUATION(e1,e2,source)::res,printExpTree) /* header */
      equation
        dumpBackendDAEEqnList2(res,printExpTree);
        print("EQUATION: ");
        str = ExpressionDump.printExpStr(e1);
        print(str);
        print("\n");
        str = ExpressionDump.dumpExpStr(e1,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
     case (BackendDAE.COMPLEX_EQUATION(i,e1,e2,source)::res,printExpTree) /* header */
      equation
        dumpBackendDAEEqnList2(res,printExpTree);
        print("COMPLEX_EQUATION: ");
        str = ExpressionDump.printExpStr(e1);
        print(str);
        print("\n");
        str = ExpressionDump.dumpExpStr(e1,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
    case (BackendDAE.SOLVED_EQUATION(_,e,source)::res,printExpTree)
      equation
        dumpBackendDAEEqnList2(res,printExpTree);
        print("SOLVED_EQUATION: ");
        str = ExpressionDump.printExpStr(e);
        print(str);
        print("\n");
        str = ExpressionDump.dumpExpStr(e,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
    case (BackendDAE.RESIDUAL_EQUATION(e,source)::res,printExpTree)
      equation
        dumpBackendDAEEqnList2(res,printExpTree);
        print("RESIDUAL_EQUATION: ");
        str = ExpressionDump.printExpStr(e);
        print(str);
        print("\n");
        str = ExpressionDump.dumpExpStr(e,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
    case (BackendDAE.ARRAY_EQUATION(_,expList,source)::res,printExpTree)
      equation
        dumpBackendDAEEqnList2(res,printExpTree);
        print("ARRAY_EQUATION: ");
        strList = List.map(expList,ExpressionDump.printExpStr);
        str = stringDelimitList(strList," | ");
        print(str);
        print("\n");
      then
        ();
     case (BackendDAE.ALGORITHM(_,expList,expList2,source)::res,printExpTree)
      equation
        dumpBackendDAEEqnList2(res,printExpTree);
        print("ALGORITHM: ");
        strList = List.map(expList,ExpressionDump.printExpStr);
        str = stringDelimitList(strList," | ");
        print(str);
        print("\n");
        strList = List.map(expList2,ExpressionDump.printExpStr);
        str = stringDelimitList(strList," | ");
        print(str);
        print("\n");
      then
        ();
     case (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(_,_,e,_/*TODO handle elsewhe also*/),source)::res,printExpTree)
      equation
        dumpBackendDAEEqnList2(res,printExpTree);
        print("WHEN_EQUATION: ");
        str = ExpressionDump.printExpStr(e);
        print(str);
        print("\n");
        str = ExpressionDump.dumpExpStr(e,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
     case (_::res,printExpTree)
      equation
      then ();
  end matchcontinue;
end dumpBackendDAEEqnList2;

public function dumpZcStr1 ""
  input list<BackendDAE.ZeroCrossing> zero_crossings;
  output String outString;
algorithm outString := matchcontinue(zero_crossings)
  local
    BackendDAE.ZeroCrossing vf;
    String s1,s2,s3;
    list<BackendDAE.ZeroCrossing> rest;
  case({}) then "";
  case( vf::rest )
    equation
      s1=  dumpZcStr(vf);
      s2= dumpZcStr1(rest);
      s3 = stringAppendList({s1,"\n", s2 });
    then
      s3;
end matchcontinue;
end dumpZcStr1;

public function dumpZcStr
"function: dumpZcStr
  Dumps a zerocrossing into a string, for debugging purposes."
  input BackendDAE.ZeroCrossing inZeroCrossing;
  output String outString;
algorithm
  outString:=
  match (inZeroCrossing)
  local
  list<String> eq_s_list,wc_s_list;
  String eq_s,wc_s,str,str2,str_index;
  DAE.Exp e;
  Integer index_;
  list<BackendDAE.Value> eq,wc;
  case BackendDAE.ZERO_CROSSING(relation_ = e as DAE.RELATION(index=index_),occurEquLst = eq,occurWhenLst = wc)
  equation
  eq_s_list = List.map(eq, intString);
  eq_s = stringDelimitList(eq_s_list, ",");
  wc_s_list = List.map(wc, intString);
  wc_s = stringDelimitList(wc_s_list, ",");
  str = ExpressionDump.printExpStr(e);
  str_index=intString(index_);
  str2 = stringAppendList({str," with index = ",str_index," in equations [",eq_s,"] and when conditions [",wc_s,"]"});
  then
  str2;
  end match;
end dumpZcStr;


public function dumpWcStr
"function: dumpWcStr
  Dumps a whenclause into a string, for debugging purposes."
  input BackendDAE.WhenClause inWhenClause;
  output String outString;
algorithm
  outString:=
  match (inWhenClause)
    local
      String sc,s1,si,str;
      DAE.Exp c;
      list<BackendDAE.WhenOperator> reinitStmtLst;
      Integer i;
    case BackendDAE.WHEN_CLAUSE(condition = c,reinitStmtLst = reinitStmtLst,elseClause = SOME(i))
     equation
      sc = ExpressionDump.printExpStr(c);
      s1 = stringDelimitList(List.map(reinitStmtLst,dumpWhenOperatorStr),"  ");              
      si = intString(i);
      str = stringAppendList({" whenclause = ",sc," then ",s1," else whenclause",si});
     then
      str;
    case BackendDAE.WHEN_CLAUSE(condition = c,reinitStmtLst = reinitStmtLst,elseClause = NONE())
     equation
      sc = ExpressionDump.printExpStr(c);
      s1 = stringDelimitList(List.map(reinitStmtLst,dumpWhenOperatorStr),"  ");              
      str = stringAppendList({" whenclause = ",sc," then ",s1});
     then
      str;
  end match;
end dumpWcStr;

public function dumpWhenOperatorStr
"function: dumpWhenOperatorStr
  Dumps a WhenOperator into a string, for debugging purposes."
  input BackendDAE.WhenOperator inWhenOperator;
  output String outString;
algorithm
  outString:=
  match (inWhenOperator)
    local
      String scr,se,se1,str;
      DAE.ComponentRef cr;
      DAE.Exp e,e1;
    case BackendDAE.REINIT(stateVar=cr,value=e)
     equation
      scr = ComponentReference.printComponentRefStr(cr);       
      se = ExpressionDump.printExpStr(e);
      str = stringAppendList({"reinit(",scr,",",se,")"});
     then
      str;
    case BackendDAE.ASSERT(condition=e,message=e1)
     equation
      se = ExpressionDump.printExpStr(e);
      se1 = ExpressionDump.printExpStr(e1);
      str = stringAppendList({"assert(",se,",",se1,")"});
     then
      str;      
    case BackendDAE.TERMINATE(message=e)
     equation
      se = ExpressionDump.printExpStr(e);
      str = stringAppendList({"terminate(",se,")"});
     then
      str;      
  end match;
end dumpWhenOperatorStr;


public function dump
"function: dump
  This function dumps the BackendDAE.BackendDAE representaton to stdout."
  input BackendDAE.BackendDAE inBackendDAE;
algorithm
  _:=
  match (inBackendDAE)
    local
      BackendDAE.EqSystems eqs;
      BackendDAE.Shared shared;
    case (BackendDAE.DAE(eqs,shared))
      equation
        List.map_0(eqs,dumpEqSystem);
        print("\n"); 
        dumpShared(shared);
      then
        ();
  end match;
end dump;

public function dumpOption
  replaceable type Type_A subtypeof Any;
  input Option<Type_A> inType;
  input printType_A infunc;
  partial function printType_A
    input Type_A inType;
  end printType_A;
algorithm
  _ := 
  match(inType,infunc)
    local 
      Type_A a;
    case(SOME(a),infunc) equation infunc(a); then ();
    else
      then ();
  end match;
end dumpOption;

public function dumpEqSystem
"function: dumpEqSystem
  This function dumps the BackendDAE.EqSystem representaton to stdout."
  input BackendDAE.EqSystem inEqSystem;
algorithm
  _:=
  match (inEqSystem)
    local
      list<BackendDAE.Var> vars;
      BackendDAE.Value varlen,eqnlen;
      String varlen_str,eqnlen_str,s;
      list<BackendDAE.Equation> eqnsl;
      list<String> ss;
      BackendDAE.Variables vars1;
      BackendDAE.EquationArray eqns;
		  Option<BackendDAE.IncidenceMatrix> m;
		  Option<BackendDAE.IncidenceMatrix> mT;
		  BackendDAE.Matching matching;     
    case (BackendDAE.EQSYSTEM(orderedVars=vars1,orderedEqs=eqns,m=m,mT=mT,matching=matching))
      equation
        print("Variables (");
        vars = BackendDAEUtil.varList(vars1);
        varlen = listLength(vars);
        varlen_str = intString(varlen);
        print(varlen_str);
        print(")\n");
        print("=========\n");
        dumpVars(vars);
        print("\n");        
        print("\nEquations (");
        eqnsl = BackendDAEUtil.equationList(eqns);
        eqnlen = listLength(eqnsl);
        eqnlen_str = intString(eqnlen);
        print(eqnlen_str);
        print(")\n");
        print("=========\n");
        dumpEqns(eqnsl);
        print("\n");
        dumpOption(m,dumpIncidenceMatrix);
        dumpOption(mT,dumpIncidenceMatrixT);
        dumpFullMatching(matching);
       then
        ();
    case (BackendDAE.EQSYSTEM(orderedVars=vars1,orderedEqs=eqns))
      equation
        print("Variables (");
        vars = BackendDAEUtil.varList(vars1);
        varlen = listLength(vars);
        varlen_str = intString(varlen);
        print(varlen_str);
        print(")\n");
        print("=========\n");
        dumpVars(vars);
        print("\n");        
        print("\nEquations (");
        eqnsl = BackendDAEUtil.equationList(eqns);
        eqnlen = listLength(eqnsl);
        eqnlen_str = intString(eqnlen);
        print(eqnlen_str);
        print(")\n");
        print("=========\n");
        dumpEqns(eqnsl);
        print("\n");
       then
        ();        
  end match;
end dumpEqSystem;

public function dumpShared
"function: dumpShared
  This function dumps the BackendDAE.Shared representaton to stdout."
  input BackendDAE.Shared inShared;
algorithm
  _:=
  match (inShared)
    local
      list<BackendDAE.Var> knvars,extvars;
      BackendDAE.Value varlen,eqnlen;
      String varlen_str,eqnlen_str,s;
      list<BackendDAE.Equation> reqnsl,ieqnsl;
      list<String> ss;
      list<BackendDAE.MultiDimEquation> ae_lst;
      BackendDAE.Variables vars2,vars3;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray reqns,ieqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> algs;
      list<BackendDAE.ZeroCrossing> zc;
      list<BackendDAE.WhenClause> wc;
      BackendDAE.ExternalObjectClasses extObjCls;
      BackendDAE.BackendDAEType btp;
    case (BackendDAE.SHARED(vars2,vars3,av,ieqns,reqns,ae,algs,BackendDAE.EVENT_INFO(zeroCrossingLst = zc,whenClauseLst=wc),extObjCls,btp))
      equation
        print("BackendDAEType: ");
        dumpBackendDAEType(btp);
        print("\n\n");
        
        print("Known Variables (constants) (");
        knvars = BackendDAEUtil.varList(vars2);
        varlen = listLength(knvars);
        varlen_str = intString(varlen);
        print(varlen_str);
        print(")\n");
        print("=============================\n");
        dumpVars(knvars);
        print("External Objects (");
        extvars = BackendDAEUtil.varList(vars3);
        varlen = listLength(extvars);
        varlen_str = intString(varlen);
        print(varlen_str);
        print(")\n");
        print("=============================\n");
        dumpVars(extvars);

        print("Classes of External Objects (");
        varlen = listLength(extObjCls);
        varlen_str = intString(varlen);
        print(varlen_str);
        print(")\n");
        print("=============================\n");
        dumpExtObjCls(extObjCls);
        
        dumpAliasVariables(av);
        
        print("Simple Equations (");
        reqnsl = BackendDAEUtil.equationList(reqns);
        eqnlen = listLength(reqnsl);
        eqnlen_str = intString(eqnlen);
        print(eqnlen_str);
        print(")\n");
        print("=========\n");
        dumpEqns(reqnsl);
        print("Initial Equations (");
        ieqnsl = BackendDAEUtil.equationList(ieqns);
        eqnlen = listLength(ieqnsl);
        eqnlen_str = intString(eqnlen);
        print(eqnlen_str);
        print(")\n");
        print("=========\n");
        dumpEqns(ieqnsl);
        print("Zero Crossings :\n");
        print("===============\n");
        ss = List.map(zc, dumpZcStr);
        s = stringDelimitList(ss, ",\n");
        print(s);
        print("\n");
        print("When Clauses :\n");
        print("===============\n");
        ss = List.map(wc, dumpWcStr);
        s = stringDelimitList(ss, ",\n");
        print(s);
        print("\n");
        print("Array Equations :\n");
        print("===============\n");
        ae_lst = arrayList(ae);
        dumpArrayEqns(ae_lst,0);

        print("Algorithms:\n");
        print("===============\n");
        dumpAlgorithms(arrayList(algs),0);
      then
        ();
  end match;
end dumpShared;

public function dumpBackendDAEType
  input BackendDAE.BackendDAEType btp; 
algorithm
  _ := match(btp)
    case (BackendDAE.SIMULATION())equation print("simulation"); then ();
    case (BackendDAE.JACOBIAN()) equation print("jacobian"); then ();
    case (BackendDAE.ALGEQSYSTEM()) equation print("algebraic loop"); then ();
    case (BackendDAE.ARRAYSYSTEM()) equation print("multidim equation arrays"); then ();
    case (BackendDAE.PARAMETERSYSTEM()) equation print("parameter system"); then ();
  end match;
end dumpBackendDAEType;

public function dumpAlgorithms "Help function to dump, prints algorithms to stdout"
  input list<DAE.Algorithm> ialgs;
  input Integer indx;
algorithm
  _ := match(ialgs,indx)
    local 
      list<Algorithm.Statement> stmts;
      IOStream.IOStream myStream;
      String is;
      list<DAE.Algorithm> algs;
      
    case({},_) then ();
    case(DAE.ALGORITHM_STMTS(stmts)::algs,indx) 
      equation
        is = intString(indx);
        myStream = IOStream.create("", IOStream.LIST());
        myStream = IOStream.append(myStream,stringAppend(is,". "));
        myStream = DAEDump.dumpAlgorithmStream(DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),DAE.emptyElementSource), myStream);
        IOStream.print(myStream, IOStream.stdOutput);
        dumpAlgorithms(algs,indx+1);
    then ();
  end match;
end dumpAlgorithms;


public function dumpSparsePattern
"function:  dumpSparsePattern
 author: wbraun
 description: fucntion dumps sparse pattern of Jacobain System."
  input list<list<Integer>> inSparsePatter;
protected
 list<String> sparsepatternStr; 
algorithm
	print("Print sparse pattern: \n");
	sparsepatternStr := List.map6(inSparsePatter,List.toString,intString,"Sparse pattern","\n"," ","\n",false);
	List.map_0(sparsepatternStr,print);
	print("\n");
end dumpSparsePattern;

public function dumpJacobianStr
"function: dumpJacobianStr
  Dumps the sparse jacobian.
  Uses the variables to determine size of Jacobian matrix."
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> inTplIntegerIntegerEquationLstOption;
  output String outString;
algorithm
  outString:=
  match (inTplIntegerIntegerEquationLstOption)
    local
      list<String> res;
      String res_1;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> eqns;
    case (SOME(eqns))
      equation
        res = dumpJacobianStr2(eqns);
        res_1 = stringDelimitList(res, ", ");
      then
        res_1;
    case (NONE()) then "No analytic jacobian available\n";
  end match;
end dumpJacobianStr;

protected function dumpJacobianStr2
"function: dumpJacobianStr2
  Helper function to dumpJacobianStr"
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inTplIntegerIntegerEquationLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  match (inTplIntegerIntegerEquationLst)
    local
      String estr,rowstr,colstr,str;
      list<String> strs;
      BackendDAE.Value row,col;
      DAE.Exp e;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> eqns;
    case ({}) then {};
    case (((row,col,BackendDAE.RESIDUAL_EQUATION(exp = e)) :: eqns))
      equation
        estr = ExpressionDump.printExpStr(e);
        rowstr = intString(row);
        colstr = intString(col);
        str = stringAppendList({"{",rowstr,",",colstr,"}:",estr});
        strs = dumpJacobianStr2(eqns);
      then
        (str :: strs);
  end match;
end dumpJacobianStr2;

protected function dumpArrayEqns
"function: dumpArrayEqns
  helper function to dump"
  input list<BackendDAE.MultiDimEquation> inMultiDimEquationLst;
  input Integer inInteger;
algorithm
  _ := match (inMultiDimEquationLst,inInteger)
    local
      String s1,s2,s,is;
      DAE.Exp e1,e2;
      list<BackendDAE.MultiDimEquation> es;
    case ({},_) then ();
    case ((BackendDAE.MULTIDIM_EQUATION(left = e1,right = e2) :: es),inInteger)
      equation
        is = intString(inInteger);
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        s = stringAppendList({is," : ",s1," = ",s2,"\n"});
        print(s);
        dumpArrayEqns(es,inInteger + 1);
      then
        ();
  end match;
end dumpArrayEqns;

public function dumpEqns
"function: dumpEqns
  Helper function to dump."
  input list<BackendDAE.Equation> eqns;
algorithm
  dumpEqns2(eqns, 1);
end dumpEqns;

protected function dumpEqns2
"function: dumpEqns2
  Helper function to dump_eqns"
  input list<BackendDAE.Equation> inEquationLst;
  input Integer inInteger;
algorithm
  _ := match (inEquationLst,inInteger)
    local
      String es,is;
      BackendDAE.Value index_1,index;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
    case ({},_) then ();
    case ((eqn :: eqns),index)
      equation
        es = equationStr(eqn);
        is = intString(index);
        print(is);
        print(" : ");
        print(es);
        print("\n");
        index_1 = index + 1;
        dumpEqns2(eqns, index_1);
      then
        ();
  end match;
end dumpEqns2;

public function dumpEqnsStr
"function: dumpEqns
  Helper function to dump."
  input list<BackendDAE.Equation> eqns;
  output String str;
algorithm
  str := stringDelimitList(dumpEqnsStr2(eqns, 1, {}),"\n");
end dumpEqnsStr;

protected function dumpEqnsStr2
"function: dumpEqns2
  Helper function to dump_eqns"
  input list<BackendDAE.Equation> inEquationLst;
  input Integer inInteger;
  input list<String> inAcc;
  output list<String> strs;
algorithm
  strs := match (inEquationLst,inInteger,inAcc)
    local
      String es,is,str;
      BackendDAE.Value index_1,index;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      list<String> acc;
      
    case ({},_,acc) then listReverse(acc);
    case ((eqn :: eqns),index,acc)
      equation
        es = equationStr(eqn);
        is = intString(index);
        str = (is +& " : ") +& es;
        index_1 = index + 1;
        acc = str::acc;
      then dumpEqnsStr2(eqns, index_1, acc);
  end match;
end dumpEqnsStr2;

protected function whenEquationStr
"function: whenEquationStr
  Helper function to equationStr"
  input BackendDAE.WhenEquation inWhenEqn;
  output String outString;
algorithm
  outString := match (inWhenEqn)
    local
      String s1,s2,res,is;
      DAE.Exp e2;
      BackendDAE.Value i;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation weqn;
    case (BackendDAE.WHEN_EQ(index = i,left = cr,right = e2, elsewhenPart = SOME(weqn)))
      equation
        s1 = whenEquationStr(weqn);
        s2 = ExpressionDump.printExpStr(e2);
        is = intString(i);
        res = stringAppendList({" ; ",s2," elsewhen clause no: ",is /*, "\n" */, s1});
      then
        res;
    case (BackendDAE.WHEN_EQ(index = i,left = cr,right = e2, elsewhenPart = NONE()))
      equation
        s2 = ExpressionDump.printExpStr(e2);
        is = intString(i);
        res = stringAppendList({" ; ",s2," elsewhen clause no: ",is /*, "\n" */});
      then
        res;
  end match;
end whenEquationStr;

public function equationStr
"function: equationStr
  Helper function to e.g. dump."
  input BackendDAE.Equation inEquation;
  output String outString;
algorithm
  outString := matchcontinue (inEquation)
    local
      String s1,s2,s3,res,indx_str,is,var_str,intsStr,outsStr;
      DAE.Exp e1,e2,e;
      BackendDAE.Value indx,i;
      list<DAE.Exp> expl,inps,outs;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation weqn;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," = ",s2});
      then
        res;
    case (BackendDAE.COMPLEX_EQUATION(lhs = e1,rhs = e2))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," = ",s2});
      then
        res;
    case (BackendDAE.ARRAY_EQUATION(index = indx,crefOrDerCref = expl))
      equation
        indx_str = intString(indx);
        var_str=stringDelimitList(List.map(expl,ExpressionDump.printExpStr),", ");
        res = stringAppendList({"Array eqn no: ",indx_str," for variables: ",var_str /*,"\n"*/});
      then
        res;
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2))
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," := ",s2});
      then
        res;
        
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index = i,left = cr,right = e2, elsewhenPart = SOME(weqn))))
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = ExpressionDump.printExpStr(e2);
        is = intString(i);
        s3 = whenEquationStr(weqn);
        res = stringAppendList({s1," := ",s2," when clause no: ",is /*, "\n" */, s3});
      then
        res;
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index = i,left = cr,right = e2)))
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = ExpressionDump.printExpStr(e2);
        is = intString(i);
        res = stringAppendList({s1," := ",s2," when clause no: ",is /*, "\n" */});
      then
        res;
    case (BackendDAE.RESIDUAL_EQUATION(exp = e))
      equation
        s1 = ExpressionDump.printExpStr(e);
        res = stringAppendList({s1,"= 0"});
      then
        res;
    case (BackendDAE.ALGORITHM(index = i, in_ = inps, out = outs))
      equation
        is = intString(i);
        intsStr = stringDelimitList(List.map(inps, ExpressionDump.printExpStr), ", ");
        outsStr = stringDelimitList(List.map(outs, ExpressionDump.printExpStr), ", ");
        res = stringAppendList({"Algorithm no: ", is, " for inputs: (", 
                                      intsStr, ") => outputs: (", 
                                      outsStr, ")" /*,"\n"*/});
      then
        res;
  end matchcontinue;
end equationStr;

protected function dumpExtObjCls "dump classes of external objects"
  input BackendDAE.ExternalObjectClasses cls;
algorithm
  _ := match(cls)
    local
      BackendDAE.ExternalObjectClasses xs;
      Absyn.Path path;
      list<Absyn.Path> paths;
      list<String> paths_lst;
      DAE.ElementSource source "the element source";
      String path_str;

    case {} then ();

    case BackendDAE.EXTOBJCLASS(path,source)::xs
      equation
        print("class ");
        print(Absyn.pathString(path));
        print("\n  extends ExternalObject;");
        print("\n origin: ");
        paths = DAEUtil.getElementSourceTypes(source);
        paths_lst = List.map(paths, Absyn.pathString);
        path_str = stringDelimitList(paths_lst, ", ");
        print(path_str +& "\n");
        print("end ");print(Absyn.pathString(path));
      then ();
  end match;
end dumpExtObjCls;

public function dumpVars
"function: dumpVars
  Helper function to dump."
  input list<BackendDAE.Var> vars;
algorithm
  dumpVars2(vars, 1);
end dumpVars;

protected function dumpVars2
"function: dumpVars2
  Helper function to dumpVars."
  input list<BackendDAE.Var> inVarLst;
  input Integer inInteger;
algorithm
  _ := matchcontinue (inVarLst,inInteger)
    local
      String varnostr,dirstr,str,path_str,comment_str,s,indx_str;
      list<String> paths_lst,path_strs;
      BackendDAE.Value varno_1,indx,varno;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Exp e;
      list<Absyn.Path> paths;
      DAE.ElementSource source "the origin of the element";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<BackendDAE.Var> xs;
      BackendDAE.Type var_type;
      DAE.InstDims arrayDim;
      Boolean b;

    case ({},_) then ();

    case (((v as BackendDAE.VAR(varName = cr,
                     varKind = kind,
                     varDirection = dir,
                     varType = var_type,
                     arryDim = arrayDim,
                     bindExp = SOME(e),
                     index = indx,
                     source = source,
                     values = dae_var_attr,
                     comment = comment,
                     flowPrefix = flowPrefix,
                     streamPrefix = streamPrefix)) :: xs),varno)
      equation
        varnostr = intString(varno);
        print(varnostr);
        print(": ");
        dirstr = DAEDump.dumpDirectionStr(dir);
        print(dirstr);
        print(" ");
        str = ComponentReference.printComponentRefStr(cr);
        print(str);
        print(":");
        dumpKind(kind);
        dumpAttributes(dae_var_attr);
        paths = DAEUtil.getElementSourceTypes(source);
        paths_lst = List.map(paths, Absyn.pathString);
        path_str = stringDelimitList(paths_lst, ", ");
        comment_str = DAEDump.dumpCommentOptionStr(comment);
        print(" = ");
        s = ExpressionDump.printExpStr(e);
        print(s);
        print(" ");
        print(path_str);
        indx_str = intString(indx) "print \"  \" & print comment_str & print \" former: \" & print old_name &" ;
        str = dumpTypeStr(var_type);print( " type: "); print(str);
        print(ComponentReference.printComponentRef2Str("", arrayDim));
        dumpAttributes(dae_var_attr);
        print(" indx = ");
        print(indx_str);
        print("\n");
        varno_1 = varno + 1;
        dumpVars2(xs, varno_1) "DAEDump.dump_variable_attributes(dae_var_attr) &" ;
      then
        ();

    case (((v as BackendDAE.VAR(varName = cr,
                     varKind = kind,
                     varDirection = dir,
                     varType = var_type,
                     arryDim = arrayDim,
                     bindExp = NONE(),
                     index = indx,
                     source = source,
                     values = dae_var_attr,
                     comment = comment,
                     flowPrefix = flowPrefix,
                     streamPrefix = streamPrefix)) :: xs),varno)
      equation
        varnostr = intString(varno);
        print(varnostr);
        print(": ");
        dirstr = DAEDump.dumpDirectionStr(dir);
        print(dirstr);
        print(" ");
        str = ComponentReference.printComponentRefStr(cr);
        paths = DAEUtil.getElementSourceTypes(source);
        path_strs = List.map(paths, Absyn.pathString);
        path_str = stringDelimitList(path_strs, ", ");
        comment_str = DAEDump.dumpCommentOptionStr(comment);
        print(str);
        print(":");
        dumpKind(kind);
        dumpAttributes(dae_var_attr);
        print(path_str);
        indx_str = intString(indx) "print \" former: \" & print old_name &" ;
        str = dumpTypeStr(var_type);print( " type: "); print(str);
        print(ComponentReference.printComponentRef2Str("", arrayDim));
        print(" indx = ");
        print(indx_str);
        print("\n");
        varno_1 = varno + 1;
        dumpVars2(xs, varno_1);
      then
        ();

    case (v :: xs,varno)
      equation
        varnostr = intString(varno);
        print(varnostr);
        print(": UNKNOWN VAR!");
        print("\n");
        debug_print("variable",v);
        varno_1 = varno + 1;
        dumpVars2(xs, varno_1);
      then ();

  end matchcontinue;
end dumpVars2;

public function dumpKind
"function: dumpKind
  Helper function to dump."
  input BackendDAE.VarKind inVarKind;
algorithm
  _:=
  match (inVarKind)
    local Absyn.Path path;
    case BackendDAE.VARIABLE()    equation print("VARIABLE");    then ();
    case BackendDAE.STATE()       equation print("STATE");       then ();
    case BackendDAE.STATE_DER()   equation print("STATE_DER");   then ();
    case BackendDAE.DUMMY_DER()   equation print("DUMMY_DER");   then ();
    case BackendDAE.DUMMY_STATE() equation print("DUMMY_STATE"); then ();
    case BackendDAE.DISCRETE()    equation print("DISCRETE");    then ();
    case BackendDAE.PARAM()       equation print("PARAM");       then ();
    case BackendDAE.CONST()       equation print("CONST");       then ();
    case BackendDAE.EXTOBJ(path)  equation print("EXTOBJ: ");print(Absyn.pathString(path)); then ();
    case BackendDAE.JAC_VAR()     equation print("JACOBIAN_VAR");then ();
    case BackendDAE.JAC_DIFF_VAR()equation print("JACOBIAN_DIFF_VAR");then ();      
  end match;
end dumpKind;

public function dumpAttributes
"function: dumpAttributes
  Helper function to dump."
  input Option<DAE.VariableAttributes> inAttr;
algorithm
  _:=
  match (inAttr)
    local
       Option<DAE.Exp> min,max,start,fixed,nominal;
       String snominal;
       Option<Boolean> isProtected,finalPrefix;
    case NONE() then ();
    case SOME(DAE.VAR_ATTR_REAL(min=(min,max),initial_=start,fixed=fixed,nominal=nominal,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
        print("(");
        dumpOptExpression(min,"min");
        dumpOptExpression(max,"max");
        dumpOptExpression(start,"start");
        dumpOptExpression(fixed,"fixed");
        dumpOptExpression(nominal,"nominal");
        dumpOptBoolean(isProtected,"protected");
        dumpOptBoolean(finalPrefix,"final");
        print(") ");
     then ();
    case SOME(DAE.VAR_ATTR_INT(min=(min,max),initial_=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
        print("(");
        dumpOptExpression(min,"min");
        dumpOptExpression(max,"max");
        dumpOptExpression(start,"start");
        dumpOptExpression(fixed,"fixed");
        dumpOptBoolean(isProtected,"protected");
        dumpOptBoolean(finalPrefix,"final");
        print(") ");
     then ();
    case SOME(DAE.VAR_ATTR_BOOL(initial_=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
        print("(");
        dumpOptExpression(start,"start");
        dumpOptExpression(fixed,"fixed");
        dumpOptBoolean(isProtected,"protected");
        dumpOptBoolean(finalPrefix,"final");
        print(") ");
     then ();
    case SOME(DAE.VAR_ATTR_STRING(initial_=start,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
        print("(");
        dumpOptExpression(start,"start");
        dumpOptBoolean(isProtected,"protected");
        dumpOptBoolean(finalPrefix,"final");
        print(") ");
     then ();
    case SOME(DAE.VAR_ATTR_ENUMERATION(min=(min,max),start=start,fixed=fixed,isProtected=isProtected,finalPrefix=finalPrefix))
      equation
        print("(");
        dumpOptExpression(min,"min");
        dumpOptExpression(max,"max");
        dumpOptExpression(start,"start");
        dumpOptExpression(fixed,"fixed");
        dumpOptBoolean(isProtected,"protected");
        dumpOptBoolean(finalPrefix,"final");
        print(") ");
     then ();
    else ();
  end match;
end dumpAttributes;

protected function dumpOptExpression
"function: dumpOptExpression
  Helper function to dump."
  input Option<DAE.Exp> inExp;
  input String inString;
algorithm
  _:=
  match (inExp,inString)
    local
       DAE.Exp e;
       String s,se,str;
    case (SOME(e),s)
      equation
         se = ExpressionDump.printExpStr(e);
         str = stringAppendList({s," = ",se," "});
         print(str);
     then ();
    else ();
  end match;
end dumpOptExpression;

protected function dumpOptBoolean
"function: dumpOptBoolean
  Helper function to dump."
  input Option<Boolean> inExp;
  input String inString;
algorithm
  _:=
  match (inExp,inString)
    local
       Boolean e;
       String s,str;
    case (SOME(true),s)
      equation
         str = stringAppendList({s," = true "});
         print(str);
     then ();
    else ();
  end match;
end dumpOptBoolean;

public function dumpIncidenceMatrix
"function: dumpIncidenceMatrix
  author: PA
  Prints the incidence matrix on stdout."
  input BackendDAE.IncidenceMatrix m;
protected
  BackendDAE.Value mlen;
  String mlen_str;
  list<list<BackendDAE.Value>> m_1;
algorithm
  print("Incidence Matrix (row == equation)\n");
  print("====================================\n");
  mlen := arrayLength(m);
  mlen_str := intString(mlen);
  print("number of rows: ");
  print(mlen_str);
  print("\n");
  m_1 := arrayList(m);
  dumpIncidenceMatrix2(m_1,1);
end dumpIncidenceMatrix;

public function dumpIncidenceMatrixT
"function: dumpIncidenceMatrixT
  author: PA
  Prints the transposed incidence matrix on stdout."
  input BackendDAE.IncidenceMatrix m;
protected
  BackendDAE.Value mlen;
  String mlen_str;
  list<list<BackendDAE.Value>> m_1;
algorithm
  print("Transpose Incidence Matrix (row == var)\n");
  print("=====================================\n");
  mlen := arrayLength(m);
  mlen_str := intString(mlen);
  print("number of rows: ");
  print(mlen_str);
  print("\n");
  m_1 := arrayList(m);
  dumpIncidenceMatrix2(m_1,1);
end dumpIncidenceMatrixT;

protected function dumpIncidenceMatrix2
"function: dumpIncidenceMatrix2
  author: PA
  Helper function to dumpIncidenceMatrix (+T)."
  input list<list<Integer>> inIntegerLstLst;
  input Integer rowIndex;
algorithm
  _ := match (inIntegerLstLst,rowIndex)
    local
      list<BackendDAE.Value> row;
      list<list<BackendDAE.Value>> rows;
    case ({},_) then ();
    case ((row :: rows),rowIndex)
      equation
        print(intString(rowIndex));print(":");
        dumpIncidenceRow(row);
        dumpIncidenceMatrix2(rows,rowIndex+1);
      then
        ();
  end match;
end dumpIncidenceMatrix2;

public function dumpIncidenceRow
"function: dumpIncidenceRow
  author: PA
  Helper function to dumpIncidenceMatrix2."
  input list<Integer> inIntegerLst;
algorithm
  _ := match (inIntegerLst)
    local
      String s;
      BackendDAE.Value x;
      list<BackendDAE.Value> xs;
    case ({})
      equation
        print("\n");
      then
        ();
    case ((x :: xs))
      equation
        s = intString(x);
        print(s);
        print(" ");
        dumpIncidenceRow(xs);
      then
        ();
  end match;
end dumpIncidenceRow;

public function dumpFullMatching
  input BackendDAE.Matching inMatch;
algorithm
  _:= match(inMatch)
    local 
      array<Integer> ass1;
      BackendDAE.StrongComponents comps;
      case (BackendDAE.NO_MATCHING()) equation print("NoMatching\n"); then ();
      case (BackendDAE.MATCHING(ass1,_,comps))
        equation
				  dumpMatching(ass1);
				  dumpComponents(comps);          
        then
          ();
    end match;
end dumpFullMatching;

public function dumpMatching
"function: dumpMatching
  author: PA
  prints the matching information on stdout."
  input array<Integer> v;
protected
  BackendDAE.Value len;
  String len_str;
algorithm
  print("Matching\n");
  print("========\n");
  len := arrayLength(v);
  len_str := intString(len);
  print(len_str);
  print(" variables and equations\n");
  dumpMatching2(v, 0);
end dumpMatching;

protected function dumpMatching2
"function: dumpMatching2
  author: PA
  Helper function to dumpMatching."
  input array<Integer> inIntegerArray;
  input Integer inInteger;
algorithm
  _ := matchcontinue (inIntegerArray,inInteger)
    local
      BackendDAE.Value len,i_1,eqn,i;
      String s,s2;
      array<BackendDAE.Value> v;
    case (v,i)
      equation
        len = arrayLength(v);
        i_1 = i + 1;
        (len == i_1) = true;
        s = intString(i_1);
        eqn = v[i_1];
        s2 = intString(eqn);
        print("var ");
        print(s);
        print(" is solved in eqn ");
        print(s2);
        print("\n");
      then
        ();
    case (v,i)
      equation
        len = arrayLength(v);
        i_1 = i + 1;
        (len == i_1) = false;
        s = intString(i_1);
        eqn = v[i_1];
        s2 = intString(eqn);
        print("var ");
        print(s);
        print(" is solved in eqn ");
        print(s2);
        print("\n");
        dumpMatching2(v, i_1);
      then
        ();
  end matchcontinue;
end dumpMatching2;

public function dumpMarkedEqns
"Dumps only the equations given as list of indexes to a string."
  input BackendDAE.EqSystem syst;
  input list<Integer> inIntegerLst;
  output String outString;
algorithm
  outString := match (syst,inIntegerLst)
    local
      String s1,s2,res;
      BackendDAE.Value e_1,e;
      BackendDAE.Equation eqn;
      BackendDAE.BackendDAE dae;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.Value> es;
    case (_,{}) then "";
    case (syst as BackendDAE.EQSYSTEM(orderedEqs = eqns),(e :: es))
      equation
        s1 = dumpMarkedEqns(syst, es);
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        s2 = equationStr(eqn);
        res = stringAppendList({s2,";\n",s1});
      then
        res;
  end match;
end dumpMarkedEqns;

public function dumpMarkedVars
"Dumps only the variable names given as list of indexes to a string."
  input BackendDAE.EqSystem syst;
  input list<Integer> inIntegerLst;
  output String outString;
algorithm
  outString:=
  match (syst,inIntegerLst)
    local
      String s1,s2,res,s3;
      BackendDAE.Value v;
      DAE.ComponentRef cr;
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables vars;
      list<BackendDAE.Value> vs;
    case (_,{}) then "";
    case (syst as BackendDAE.EQSYSTEM(orderedVars = vars),(v :: vs))
      equation
        s1 = dumpMarkedVars(syst, vs);
        BackendDAE.VAR(varName = cr) = BackendVariable.getVarAt(vars, v);
        s2 = ComponentReference.printComponentRefStr(cr);
        s3 = intString(v);
        res = stringAppendList({s2,"(",s3,"), ",s1});
      then
        res;
  end match;
end dumpMarkedVars;

public function dumpComponentsGraphStr
"Dumps the assignment graph used to determine strong
 components to format suitable for Mathematica"
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.BackendDAE outDAE;
  output Boolean outRunMatching;
protected
  Integer n;
  list<String> lst;
  String s;
  BackendDAE.EqSystem syst;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.IncidenceMatrix mT;
  array<Integer> ass1,ass2;
algorithm
  BackendDAE.DAE(eqs={syst as BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mT),matching=BackendDAE.MATCHING(ass1,ass2,_))}) := inDAE;
  n :=  BackendDAEUtil.systemSize(syst);
  lst := dumpComponentsGraphStr2(1,n,m,mT,ass1,ass2);
  s := stringDelimitList(lst,",");
  s := stringAppendList({"{",s,"}"});
  print(s);
  outDAE := inDAE;
  outRunMatching := false;
end dumpComponentsGraphStr;

protected function dumpComponentsGraphStr2 "help function"
  input Integer i;
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output list<String> lst;
algorithm
  lst := matchcontinue(i,n,m,mT,ass1,ass2)
    local
      list<list<Integer>> llst;
      list<Integer> eqns;
      list<String> strLst,slst;
      String str;
    case(i,n,m,mT,ass1,ass2) equation
      true = (i > n);
      then {};
    case(i,n,m,mT,ass1,ass2)
      equation
        eqns = BackendDAETransform.reachableNodes(i, m, mT, ass1, ass2);
        llst = List.map(eqns,List.create);
        llst = List.map1(llst, List.consr, i);
        slst = List.map(llst,intListStr);
        str = stringDelimitList(slst,",");
        str = stringAppendList({"{",str,"}"});
        strLst = dumpComponentsGraphStr2(i+1,n,m,mT,ass1,ass2);
      then str::strLst;
  end matchcontinue;
end dumpComponentsGraphStr2;

public function dumpList "function: dumpList
  author: PA

  Helper function to dump.
"
  input list<Integer> l;
  input String str;
  list<String> s;
  String sl;
algorithm
  s := List.map(l, intString);
  sl := stringDelimitList(s, ", ");
  print(str);
  print(sl);
  print("\n");
end dumpList;

public function dumpComponentsOLD "function: dumpComponents
  author: PA

  Prints the blocks of the BLT sorting on stdout.
"
  input list<list<Integer>> l;
algorithm
  print("Blocks\n");
  print("=======\n");
  dumpComponents2(l, 1);
end dumpComponentsOLD;

protected function dumpComponents2 "function: dumpComponents2
  author: PA

  Helper function to dump_components.
"
  input list<list<Integer>> inIntegerLstLst;
  input Integer inInteger;
algorithm
  _:=
  match (inIntegerLstLst,inInteger)
    local
      BackendDAE.Value i_1,i;
      list<String> ls;
      String s;
      list<BackendDAE.Value> l;
      list<list<BackendDAE.Value>> lst;
    case ({},_) then ();
    case ((l :: lst),i)
      equation
        print("{");
        ls = List.map(l, intString);
        s = stringDelimitList(ls, ", ");
        print(s);
        print("}\n");
        i_1 = i + 1;
        dumpComponents2(lst, i_1);
      then
        ();
  end match;
end dumpComponents2;

protected function intListStr "Takes a list of Integers and produces a string  on form: \"{1,2,3}\" "
  input list<Integer> lst;
  output String res;
algorithm
  res := stringDelimitList(List.map(lst,intString),",");
  res := stringAppendList({"{",res,"}"});
end intListStr;

public function dumpAliasVariables "function: dumpAliasVariables
  author: Frenkel TUD 2010-12

  dump AliasVariables.
"
  input BackendDAE.AliasVariables inAliasVars;
protected
  BackendDAE.Variables aliasVars;
  list<BackendDAE.Var> vars;
  String sl;
  Integer l;
algorithm
  BackendDAE.ALIASVARS(aliasVars=aliasVars) := inAliasVars;
  l := BackendVariable.varsSize(aliasVars);
  sl := intString(l);
  vars := BackendDAEUtil.varList(aliasVars);
  print("AliasVariables: ");
  print(sl);
  print("\n===============\n");
  dumpVars(vars);
  print("\n");
end dumpAliasVariables;

protected function dumpAliasVariable
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var,list<Integer>> inTpl;
 output tuple<BackendDAE.Var,list<Integer>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      DAE.Exp e;
      String s,scr,se;
    case ((v,_))
      equation
        cr = BackendVariable.varCref(v);
        e = BackendVariable.varBindExp(v);
        //print("### dump var : " +&  ComponentReference.printComponentRefStr(cr) +& "\n");
        scr = ComponentReference.printComponentRefStr(cr);
        se = ExpressionDump.printExpStr(e);
        s = stringAppendList({scr," = ",se,"\n"});
        print(s);
      then ((v,{}));
    case inTpl then inTpl;
  end matchcontinue;
end dumpAliasVariable;

public function dumpStateVariables "function: dumpStateVariables
  author: Frenkel TUD 2010-12

  dump State Variables.
"
  input BackendDAE.Variables inVars;
algorithm
  print("States Variables\n");
  print("=================\n");
  _ := BackendVariable.traverseBackendDAEVars(inVars,dumpStateVariable,1);
  print("\n");
end dumpStateVariables;

protected function dumpStateVariable
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, Integer> inTpl;
 output tuple<BackendDAE.Var, Integer> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      String scr;
      Integer pos;
    case ((v,pos))
      equation
        true = BackendVariable.isStateVar(v);
        cr = BackendVariable.varCref(v);
        scr = ComponentReference.printComponentRefStr(cr);
        print(intString(pos)); print(": ");
        print(scr); print("\n");
      then ((v,pos+1));
    case inTpl then inTpl;
  end matchcontinue;
end dumpStateVariable;

public function bltdump
"autor: Frenkel TUD 2011-03"
  input tuple<String,BackendDAE.BackendDAE> inTpl;
protected
  String str;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.IncidenceMatrix mT;
  array<Integer> v1,v2;
  BackendDAE.StrongComponents comps;
  BackendDAE.BackendDAE ode;
algorithm
  (str,ode) := inTpl;
  print(str); print(":\n");
  dump(ode);
end bltdump;

public function dumpComponentsAdvanced "function: dumpComponents
  author: Frenkel TUD

  Prints the blocks of the BLT sorting on stdout.
"
  input list<list<Integer>> l;
  input array<Integer> v2;
  input BackendDAE.EqSystem syst;
protected
  BackendDAE.Variables vars;
algorithm
  print("Blocks\n");
  print("=======\n");
  vars := BackendVariable.daeVars(syst);
  dumpComponentsAdvanced2(l, 1,v2,vars);
end dumpComponentsAdvanced;

protected function dumpComponentsAdvanced2 "function: dumpComponents2
  author: PA

  Helper function to dump_components.
"
  input list<list<Integer>> inIntegerLstLst;
  input Integer inInteger;
  input array<Integer> v2;
  input BackendDAE.Variables vars;
algorithm
  _:=
  match (inIntegerLstLst,inInteger,v2,vars)
    local
      BackendDAE.Value ni,i_1,i;
      list<String> ls;
      String s;
      list<BackendDAE.Value> l;
      list<list<BackendDAE.Value>> lst;
    case ({},_,_,_) then ();
    case ((l :: lst),i,v2,vars)
      equation
        print("{");
        ls = List.map(l, intString);
        s = stringDelimitList(ls, ", ");
        print(s);
        print("} ");
        dumpComponentsAdvanced3(l,v2,vars);
        print("\n");
        i_1 = i + 1;
        dumpComponentsAdvanced2(lst, i_1,v2,vars);
      then
        ();
  end match;
end dumpComponentsAdvanced2;

protected function dumpComponentsAdvanced3 "function: dumpComponents2
  author: PA

  Helper function to dump_components.
"
  input list<Integer> inIntegerLst;
  input array<Integer> v2;
  input BackendDAE.Variables vars;
algorithm
  _:=
  match (inIntegerLst,v2,vars)
    local
      BackendDAE.Value i,v;
      list<String> ls;
      String s;
      list<BackendDAE.Value> l;
      DAE.ComponentRef c;
      BackendDAE.Var var;
      Boolean b;
    case ({},_,_) then ();
    case (i::{},v2,vars)
      equation
        v = v2[i];
        var = BackendVariable.getVarAt(vars,v);
        c = BackendVariable.varCref(var);
        b = BackendVariable.isStateVar(var);
        s = Util.if_(b,"der(","");
        print(s);
        s = ComponentReference.printComponentRefStr(c);
        print(s);
        s = Util.if_(b,") "," ");
        print(s);
      then
        ();
    case (i::l,v2,vars)
      equation
        v = v2[i];
        var = BackendVariable.getVarAt(vars,v);
        c = BackendVariable.varCref(var);
        b = BackendVariable.isStateVar(var);
        s = Util.if_(b,"der(","");
        print(s);
        s = ComponentReference.printComponentRefStr(c);
        print(s);
        s = Util.if_(b,") "," ");
        print(s);
        dumpComponentsAdvanced3(l,v2,vars);
      then
        ();
  end match;
end dumpComponentsAdvanced3;

public function dumpComponents
  input BackendDAE.StrongComponents inComps;
algorithm
  print("StrongComponents\n");
  print("=======\n");  
  List.map_0(inComps,dumpComponent);
end dumpComponents;

public function dumpComponent
  input BackendDAE.StrongComponent inComp;
algorithm
  _:=
  match (inComp)
    local
      BackendDAE.Value i,v;
      list<BackendDAE.Value> ilst,vlst;
      list<String> ls;
      String s;
      BackendDAE.JacobianType jacType;
      BackendDAE.StrongComponent comp;
    case BackendDAE.SINGLEEQUATION(eqn=i,var=v)
      equation
        print("{");
        print(intString(i)); 
        print(":");
        print(intString(v)); 
        print("}\n");
      then ();
    case BackendDAE.EQUATIONSYSTEM(eqns=ilst,vars=vlst,jacType=jacType)
      equation
        print("{");
        ls = List.map(ilst, intString);
        s = stringDelimitList(ls, ", ");
        print(s);
        print(":");
        ls = List.map(vlst, intString);
        s = stringDelimitList(ls, ", ");
        print(s);
        print("} Size: ");
        print(intString(listLength(ilst)));
        print(" ");
        print(BackendDAEUtil.jacobianTypeStr(jacType)); 
        print("\n");
      then
        ();
    case BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp,disc_eqns=ilst,disc_vars=vlst)
      equation
        print("{{");
        ls = List.map(ilst, intString);
        s = stringDelimitList(ls, ", ");
        print(s);
        print(":");
        ls = List.map(vlst, intString);
        s = stringDelimitList(ls, ", ");
        print(s);
        print("},\n");
        dumpComponent(comp);
        print("} Size: ");
        print(intString(listLength(ilst)));
        print("\n");
      then
        ();        
    case BackendDAE.SINGLEARRAY(arrayIndx=i,vars=vlst)
      equation
        print("Array ");
        print(intString(i));
        print(" {");
        ls = List.map(vlst, intString);
        s = stringDelimitList(ls, ", ");
        print(s);
        print("}\n");
      then
        ();        
    case BackendDAE.SINGLEALGORITHM(algorithmIndx=i,vars=vlst)
      equation
        print("Algorithm ");
        print(intString(i));
        print(" {");
        ls = List.map(vlst, intString);
        s = stringDelimitList(ls, ", ");
        print(s);
        print("}\n");
      then
        ();        
  end match;  
end dumpComponent;

/*******************************************/
/* Debug dump functions */
/*******************************************/

public function debugCrefStr
  input tuple<DAE.ComponentRef,String> inTpl;
protected
  DAE.ComponentRef a;
  String b;
algorithm
  (a,b) := inTpl;
  print(ComponentReference.printComponentRefStr(a) +& b);
end debugCrefStr;

public function debugStrIntStr
  input tuple<String,Integer,String> inTpl;
protected
  String a,c;
  Integer b;
algorithm
  (a,b,c) := inTpl;
  print(a +& intString(b) +& c);
end debugStrIntStr;

public function debugStrIntStrIntStr
  input tuple<String,Integer,String,Integer,String> inTpl;
protected
  String a,c,e;
  Integer b,d;
algorithm
  (a,b,c,d,e) := inTpl;
  print(a +& intString(b) +& c +& intString(d) +& e);
end debugStrIntStrIntStr;

public function debugCrefStrIntStr
  input tuple<DAE.ComponentRef,String,Integer,String> inTpl;
protected
  DAE.ComponentRef a;
  String b,d;
  Integer c;
algorithm
  (a,b,c,d) := inTpl;
  print(ComponentReference.printComponentRefStr(a) +& b +& intString(c) +& d);
end debugCrefStrIntStr;

public function debugStrCrefStr
  input tuple<String,DAE.ComponentRef,String> inTpl;
protected
  String a,c;
  DAE.ComponentRef b;
algorithm
  (a,b,c) := inTpl;
  print(a +&ComponentReference.printComponentRefStr(b) +& c);
end debugStrCrefStr;

public function debugStrCrefStrIntStr
  input tuple<String,DAE.ComponentRef,String,Integer,String> inTpl;
protected
  String a,c,e;
  DAE.ComponentRef b;
  Integer d;
algorithm
  (a,b,c,d,e) := inTpl;
  print(a +& ComponentReference.printComponentRefStr(b) +& c +& intString(d) +& e);
end debugStrCrefStrIntStr;

public function debugStrCrefStrRealStrRealStrRealStr
  input tuple<String,DAE.ComponentRef,String,Real,String,Real,String,Real,String> inTpl;
protected
  String a,c,e,g,i;
  DAE.ComponentRef b;
  Real d,f,h;
algorithm
  (a,b,c,d,e,f,g,h,i) := inTpl;
  print(a +& ComponentReference.printComponentRefStr(b) +& c +& realString(d) +& e +& realString(f) +& g +& realString(h) +& i);
end debugStrCrefStrRealStrRealStrRealStr;

public function debugStrRealStrRealStrRealStrRealStr
  input tuple<String,Real,String,Real,String,Real,String,Real,String> inTpl;
protected
  String a,c,e,g,i;
  Real b,d,f,h;
algorithm
  (a,b,c,d,e,f,g,h,i) := inTpl;
  print(a +& realString(b) +& c +& realString(d) +& e +& realString(f) +& g +& realString(h) +& i);
end debugStrRealStrRealStrRealStrRealStr;

public function debugStrCrefStrExpStr
  input tuple<String,DAE.ComponentRef,String,DAE.Exp,String> inTpl;
protected
  String a,c,e;
  DAE.ComponentRef b;
  DAE.Exp d;
algorithm
  (a,b,c,d,e) := inTpl;
  print(a +& ComponentReference.printComponentRefStr(b) +& c +& ExpressionDump.printExpStr(d) +& e);
end debugStrCrefStrExpStr;

public function debugStrCrefStrCrefStr
  input tuple<String,DAE.ComponentRef,String,DAE.ComponentRef,String> inTpl;
protected
  String a,c,e;
  DAE.ComponentRef b,d;
algorithm
  (a,b,c,d,e) := inTpl;
  print(a +& ComponentReference.printComponentRefStr(b) +& c +& ComponentReference.printComponentRefStr(d) +& e);
end debugStrCrefStrCrefStr;

public function debugExpStr
  input tuple<DAE.Exp,String> inTpl;
protected
  String b;
  DAE.Exp a;
algorithm
  (a,b) := inTpl;
  print(ExpressionDump.printExpStr(a) +& b);
end debugExpStr;

public function debugStrExpStr
  input tuple<String,DAE.Exp,String> inTpl;
protected
  String a,c;
  DAE.Exp b;
algorithm
  (a,b,c) := inTpl;
  print(a +& ExpressionDump.printExpStr(b) +& c);
end debugStrExpStr;

public function debugStrExpStrCrefStr
  input tuple<String,DAE.Exp,String,DAE.ComponentRef,String> inTpl;
protected
  String a,c,e;
  DAE.Exp b;
  DAE.ComponentRef d;
algorithm
  (a,b,c,d,e) := inTpl;
  print(a +& ExpressionDump.printExpStr(b) +& c +& ComponentReference.printComponentRefStr(d) +& e);
end debugStrExpStrCrefStr;

public function debugStrExpStrExpStr
  input tuple<String,DAE.Exp,String,DAE.Exp,String> inTpl;
protected
  String a,c,e;
  DAE.Exp b,d;
algorithm
  (a,b,c,d,e) := inTpl;
  print(a +& ExpressionDump.printExpStr(b) +& c +& ExpressionDump.printExpStr(d) +& e);
end debugStrExpStrExpStr;

public function debugExpStrExpStrExpStr
  input tuple<DAE.Exp,String,DAE.Exp,String,DAE.Exp,String> inTpl;
protected
  DAE.Exp a,c,e;
  String b,d,f;
algorithm
  (a,b,c,d,e,f) := inTpl;
  print(ExpressionDump.printExpStr(a) +& b +& ExpressionDump.printExpStr(c) +& d +& ExpressionDump.printExpStr(e) +& f);
end debugExpStrExpStrExpStr;

public function debugStrExpStrExpStrExpStr
  input tuple<String,DAE.Exp,String,DAE.Exp,String,DAE.Exp,String> inTpl;
protected
  String a,c,e,g;
  DAE.Exp b,d,f;
algorithm
  (a,b,c,d,e,f,g) := inTpl;
  print(a +& ExpressionDump.printExpStr(b) +& c +& ExpressionDump.printExpStr(d) +& e +& ExpressionDump.printExpStr(f) +& g);
end debugStrExpStrExpStrExpStr;


public function debugStrEqnStrEqnStr
  input tuple<String,BackendDAE.Equation,String,BackendDAE.Equation,String> inTpl;
protected
  String a,c,e;
  BackendDAE.Equation b,d;
algorithm
  (a,b,c,d,e) := inTpl;
  print(a +& equationStr(b) +& c +& equationStr(d) +& e);
end debugStrEqnStrEqnStr;

public function debuglst
  input tuple<list<Type_a>,FuncTypeType_aToStr> inTpl;
  partial function FuncTypeType_aToStr
    input Type_a inTypeA;
    output String outTypeA;
  end FuncTypeType_aToStr;
  replaceable type Type_a subtypeof Any;
algorithm
   _ := matchcontinue(inTpl)
    local  
      Type_a a;
      list<Type_a> rest;
      FuncTypeType_aToStr f;
      String s;
    case (({},_)) then ();
    case ((a::rest,f))
      equation 
       s = f(a);
       print(s); print(" ");
       debuglst((rest,f));
    then ();  
  end matchcontinue;  
end debuglst;

end BackendDump;
