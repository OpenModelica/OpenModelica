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

package DAELow
" file:         DAELow.mo
  package:     DAELow
  description: BackendDAE.DAELow a lower form of DAE including sparse matrises for
               BLT decomposition, etc.

  RCS: $Id$

  This module is a lowered form of a DAE including equations
  and simple equations in
  two separate lists. The variables are split into known variables
  parameters and constants, and unknown variables,
  states and algebraic variables.
  The module includes the BLT sorting algorithm which sorts the
  equations into blocks, and the index reduction algorithm using
  dummy derivatives for solving higher index problems.
  It also includes the tarjan algorithm to detect strong components
  in the BLT sorting."

public import Absyn;
public import BackendDAE;
public import BackendDAEUtil;
public import ComponentReference;
public import DAE;
public import SCode;
public import Values;
public import Builtin;
public import HashTable2;

protected import Algorithm;
protected import BackendDump;
protected import BackendVarTransform;
protected import Ceval;
protected import ClassInf;
protected import DAEEXT;
protected import DAEUtil;
protected import Debug;
protected import Derive;
protected import Env;
protected import Error;
protected import Exp;
protected import OptManager;
protected import RTOpts;
protected import System;
protected import Util;
protected import DAEDump;
protected import Inline;
protected import ValuesUtil;
protected import VarTransform;

protected function hasNoStates
"@author: adrpo
 this function tells if there are NO states in the binary tree"
  input BackendDAE.BinTree states;
  output Boolean out;
algorithm
  out := matchcontinue (states)
    // if the tree is empty then there are no states
    case (BackendDAE.TREENODE(NONE(),NONE(),NONE())) then true;
    case (_) then false;
  end matchcontinue;
end hasNoStates;

public function lower
"function: lower
  This function translates a DAE, which is the result from instantiating a
  class, into a more precise form, called BackendDAE.DAELow defined in this module.
  The BackendDAE.DAELow representation splits the DAE into equations and variables
  and further divides variables into known and unknown variables and the
  equations into simple and nonsimple equations.
  The variables are inserted into a hash table. This gives a lookup cost of
  O(1) for finding a variable. The equations are put in an expandable
  array. Where adding a new equation can be done in O(1) time if space
  is available.
  inputs:  daeList: DAE.DAElist, simplify: bool)
  outputs: DAELow"
  input DAE.DAElist lst;
  input DAE.FunctionTree functionTree;
  input Boolean addDummyDerivativeIfNeeded;
  input Boolean simplify;
//  input Boolean removeTrivEqs "temporal input, for legacy purposes; doesn't add trivial equations to removed equations";
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow := matchcontinue(lst, functionTree, addDummyDerivativeIfNeeded, simplify)
    local
      BackendDAE.BinTree s;
      BackendDAE.Variables vars,knvars,vars_1,extVars;
      BackendDAE.AliasVariables aliasVars "hash table with alias vars' replacements (a=b or a=-b)";
      list<BackendDAE.Equation> eqns,reqns,ieqns,algeqns,multidimeqns,imultidimeqns,eqns_1;
      list<BackendDAE.MultiDimEquation> aeqns,aeqns1,iaeqns;
      list<DAE.Algorithm> algs,algs_1;
      list<BackendDAE.WhenClause> whenclauses,whenclauses_1;
      list<BackendDAE.ZeroCrossing> zero_crossings;
      BackendDAE.EquationArray eqnarr,reqnarr,ieqnarr;
      array<BackendDAE.MultiDimEquation> arr_md_eqns;
      array<DAE.Algorithm> algarr;
      BackendDAE.ExternalObjectClasses extObjCls;
      Boolean daeContainsNoStates, shouldAddDummyDerivative;
      BackendDAE.EventInfo einfo;
      DAE.FunctionTree funcs;
      list<DAE.Element> elems;

    case(lst, functionTree, addDummyDerivativeIfNeeded, true) // simplify by default
      equation
        (DAE.DAE(elems),functionTree)  = processDelayExpressions(lst,functionTree);
        s = states(elems, BackendDAE.emptyBintree);
        vars = emptyVars();
        knvars = emptyVars();
        extVars = emptyVars();
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses,extObjCls,s) = lower2(elems, functionTree, s, vars, knvars, extVars, {});

        daeContainsNoStates = hasNoStates(s); // check if the DAE has states
        // adrpo: add the dummy derivative state ONLY IF the DAE contains
        //        no states AND ONLY if addDummyDerivative is set to true!
        shouldAddDummyDerivative =  boolAnd(addDummyDerivativeIfNeeded, daeContainsNoStates);
        (vars,eqns) = addDummyState(vars, eqns, shouldAddDummyDerivative);

        whenclauses_1 = listReverse(whenclauses);
        algeqns = lowerAlgorithms(vars, algs);
        (multidimeqns,imultidimeqns) = lowerMultidimeqns(vars, aeqns, iaeqns);
        eqns = listAppend(algeqns, eqns);
        eqns = listAppend(multidimeqns, eqns);
        ieqns = listAppend(imultidimeqns, ieqns);
        aeqns = listAppend(aeqns,iaeqns);
        (vars,knvars,eqns,reqns,ieqns,aeqns1,algs_1,aliasVars) = removeSimpleEquations(vars, knvars, eqns, reqns, ieqns, aeqns, algs, s);
        vars_1 = detectImplicitDiscrete(vars, eqns);
        eqns_1 = sortEqn(eqns);
        (eqns_1,ieqns,aeqns1,algs,vars_1) = expandDerOperator(vars_1,eqns_1,ieqns,aeqns1,algs_1,functionTree);
        (zero_crossings) = findZeroCrossings(vars_1,knvars,eqns_1,aeqns1,whenclauses_1,algs);
        eqnarr = listEquation(eqns_1);
        reqnarr = listEquation(reqns);
        ieqnarr = listEquation(ieqns);
        arr_md_eqns = listArray(aeqns1);
        algarr = listArray(algs);
        einfo = Inline.inlineEventInfo(BackendDAE.EVENT_INFO(whenclauses_1,zero_crossings),(SOME(functionTree),{DAE.NORM_INLINE()}));
        BackendDAEUtil.checkBackendDAEWithErrorMsg(BackendDAE.DAELOW(vars_1,knvars,extVars,aliasVars,eqnarr,reqnarr,ieqnarr,arr_md_eqns,algarr,einfo,extObjCls));
      then BackendDAE.DAELOW(vars_1,knvars,extVars,aliasVars,eqnarr,reqnarr,ieqnarr,arr_md_eqns,algarr,einfo,extObjCls);

    case(lst, functionTree, addDummyDerivativeIfNeeded, false) // do not simplify
      equation
        (DAE.DAE(elems),functionTree)  = processDelayExpressions(lst,functionTree);
        s = states(elems, BackendDAE.emptyBintree);
        vars = emptyVars();
        knvars = emptyVars();
        extVars = emptyVars();
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses,extObjCls,s) = lower2(elems, functionTree, s, vars, knvars, extVars, {});

        daeContainsNoStates = hasNoStates(s); // check if the DAE has states
        // adrpo: add the dummy derivative state ONLY IF the DAE contains
        //        no states AND ONLY if addDummyDerivative is set to true!
        shouldAddDummyDerivative =  boolAnd(addDummyDerivativeIfNeeded, daeContainsNoStates);
        (vars,eqns) = addDummyState(vars, eqns, shouldAddDummyDerivative);

        whenclauses_1 = listReverse(whenclauses);
        algeqns = lowerAlgorithms(vars, algs);
       (multidimeqns,imultidimeqns) = lowerMultidimeqns(vars, aeqns, iaeqns);
        eqns = listAppend(algeqns, eqns);
        eqns = listAppend(multidimeqns, eqns);
        ieqns = listAppend(imultidimeqns, ieqns);
        // no simplify (vars,knvars,eqns,reqns,ieqns,aeqns1) = removeSimpleEquations(vars, knvars, eqns, reqns, ieqns, aeqns, s);
        aliasVars = emptyAliasVariables();
        vars_1 = detectImplicitDiscrete(vars, eqns);
        eqns_1 = sortEqn(eqns);
        // no simplify (eqns_1,ieqns,aeqns1,algs,vars_1) = expandDerOperator(vars_1,eqns_1,ieqns,aeqns1,algs);
        (zero_crossings) = findZeroCrossings(vars_1,knvars,eqns_1,aeqns,whenclauses_1,algs);
        eqnarr = listEquation(eqns_1);
        reqnarr = listEquation(reqns);
        ieqnarr = listEquation(ieqns);
        arr_md_eqns = listArray(aeqns);
        algarr = listArray(algs);
        einfo = Inline.inlineEventInfo(BackendDAE.EVENT_INFO(whenclauses_1,zero_crossings),(SOME(functionTree),{DAE.NORM_INLINE()}));        
        BackendDAEUtil.checkBackendDAEWithErrorMsg(BackendDAE.DAELOW(vars_1,knvars,extVars,aliasVars,eqnarr,reqnarr,ieqnarr,arr_md_eqns,algarr,einfo,extObjCls));        
      then BackendDAE.DAELOW(vars_1,knvars,extVars,aliasVars,eqnarr,reqnarr,ieqnarr,arr_md_eqns,algarr,einfo,extObjCls);
  end matchcontinue;
end lower;

protected function expandDerOperator
"function expandDerOperator
  expands der(expr) using Derive.differentiteExpTime.
  This can not be done in Static, since we need all time-
  dependent variables, which is only available in DAELow."
  input BackendDAE.Variables vars;
  input list<BackendDAE.Equation> eqns;
  input list<BackendDAE.Equation> ieqns;
  input list<BackendDAE.MultiDimEquation> aeqns;
  input list<DAE.Algorithm> algs;
  input DAE.FunctionTree functions;

  output list<BackendDAE.Equation> outEqns;
  output list<BackendDAE.Equation> outIeqns;
  output list<BackendDAE.MultiDimEquation> outAeqns;
  output list<DAE.Algorithm> outAlgs;
  output BackendDAE.Variables outVars;
algorithm
  (outEqns, outIeqns,outAeqns,outAlgs,outVars) :=
  matchcontinue(vars,eqns,ieqns,aeqns,algs,functions)
    case(vars,eqns,ieqns,aeqns,algs,functions) equation
      (eqns,(vars,_)) = expandDerOperatorEqns(eqns,(vars,functions));
      (ieqns,(vars,_)) = expandDerOperatorEqns(ieqns,(vars,functions));
      (aeqns,(vars,_)) = expandDerOperatorArrEqns(aeqns,(vars,functions));
      (algs,(vars,_)) = expandDerOperatorAlgs(algs,(vars,functions));
    then(eqns,ieqns,aeqns,algs,vars);
  end matchcontinue;
end expandDerOperator;

protected function expandDerOperatorEqns
"Help function to expandDerOperator"
  input list<BackendDAE.Equation> eqns;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output list<BackendDAE.Equation> outEqns;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outEqns,outVars) := matchcontinue(eqns,vars)
  local BackendDAE.Equation e;
    case({},vars) then ({},vars);
    case(e::eqns,vars) equation
      (e,vars) = expandDerOperatorEqn(e,vars);
      (eqns,vars)  = expandDerOperatorEqns(eqns,vars);
    then (e::eqns,vars);
    case(_,_) equation
      Debug.fprint("failtrace", "-DAELow.expandDerOperatorEqns failed\n");
      then fail();
    end matchcontinue;
end expandDerOperatorEqns;

protected function expandDerOperatorEqn
"Help function to expandDerOperator, handles Equations"
  input BackendDAE.Equation eqn;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output BackendDAE.Equation outEqn;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outEqn,outVars) := matchcontinue(eqn,vars)
    local
      DAE.Exp e1,e2; list<DAE.Exp> expl; Integer i;
      DAE.ComponentRef cr; BackendDAE.WhenEquation wheneq;
      DAE.ElementSource source "the element source";

    case(BackendDAE.EQUATION(e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (BackendDAE.EQUATION(e1,e2,source),vars);
    case(BackendDAE.COMPLEX_EQUATION(i,e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (BackendDAE.COMPLEX_EQUATION(i,e1,e2,source),vars);
    case  (BackendDAE.ARRAY_EQUATION(i,expl,source),vars)
    then (BackendDAE.ARRAY_EQUATION(i,expl,source),vars);
    case (BackendDAE.SOLVED_EQUATION(cr,e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (BackendDAE.SOLVED_EQUATION(cr,e1,source),vars);
    case(BackendDAE.RESIDUAL_EQUATION(e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (BackendDAE.RESIDUAL_EQUATION(e1,source),vars);
    case (eqn as BackendDAE.ALGORITHM(index = _),vars) then (eqn,vars);
    case (BackendDAE.WHEN_EQUATION(wheneq,source),vars) equation
      (wheneq,vars) = expandDerOperatorWhenEqn(wheneq,vars);
    then (BackendDAE.WHEN_EQUATION(wheneq,source),vars);
    case (eqn ,vars) equation
      true = RTOpts.debugFlag("failtrace");
      Debug.fprint("failtrace", "- DAELow.expandDerOperatorEqn, eqn =");
      Debug.fprint("failtrace", BackendDump.equationStr(eqn));
      Debug.fprint("failtrace", " failed\n");
    then fail();
  end matchcontinue;
end expandDerOperatorEqn;

protected function expandDerOperatorWhenEqn
"Helper function to expandDerOperatorWhenEqn"
  input BackendDAE.WhenEquation wheneq;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output BackendDAE.WhenEquation outWheneq;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outWheneq, outVars) := matchcontinue(wheneq,vars)
    local DAE.ComponentRef cr; DAE.Exp e1; Integer indx; BackendDAE.WhenEquation elsewheneq;
    case(BackendDAE.WHEN_EQ(indx,cr,e1,SOME(elsewheneq)),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      (elsewheneq,vars) = expandDerOperatorWhenEqn(elsewheneq,vars);
    then (BackendDAE.WHEN_EQ(indx,cr,e1,SOME(elsewheneq)),vars);

    case(BackendDAE.WHEN_EQ(indx,cr,e1,NONE()),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (BackendDAE.WHEN_EQ(indx,cr,e1,NONE()),vars);
  end matchcontinue;
end expandDerOperatorWhenEqn;

protected function expandDerOperatorAlgs
"Help function to expandDerOperator"
  input list<DAE.Algorithm> algs;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output list<DAE.Algorithm> outAlgs;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outAlgs,outVars) := matchcontinue(algs,vars)
  local DAE.Algorithm a;
    case({},vars) then ({},vars);
    case(a::algs,vars) equation
      (a,vars) = expandDerOperatorAlg(a,vars);
      (algs,vars)  = expandDerOperatorAlgs(algs,vars);
    then (a::algs,vars);

    case(_,_) equation
      Debug.fprint("failtrace", "-DAELow.expandDerOperatorAlgs failed\n");
      then fail();

  end matchcontinue;
end expandDerOperatorAlgs;

protected function expandDerOperatorAlg
"Help function to to expandDerOperator, handles Algorithms"
  input DAE.Algorithm alg;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output DAE.Algorithm outAlg;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outAlg,outVars) := matchcontinue(alg,vars)
  local list<Algorithm.Statement> stmts;
    case(DAE.ALGORITHM_STMTS(stmts),vars) equation
      (stmts,vars)  = expandDerOperatorStmts(stmts,vars);
    then (DAE.ALGORITHM_STMTS(stmts),vars);
  end matchcontinue;
end expandDerOperatorAlg;

protected function expandDerOperatorStmts
"Help function to expandDerOperatorAlg"
  input list<Algorithm.Statement> stmts;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output list<Algorithm.Statement> outStmts;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outStmts,outVars) := matchcontinue(stmts,vars)
  local Algorithm.Statement s;
    case({},vars) then ({},vars);
    case(s::stmts,vars) equation
      (s,vars) = expandDerOperatorStmt(s,vars);
      (stmts,vars)  = expandDerOperatorStmts(stmts,vars);
      then (s::stmts,vars);
  end matchcontinue;
end expandDerOperatorStmts;

protected function expandDerOperatorStmt
"Help function to expandDerOperatorAlg."
  input Algorithm.Statement stmt;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output Algorithm.Statement outStmt;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outStmt,outVars) := matchcontinue(stmt,vars)
    local DAE.ExpType tp; DAE.ComponentRef cr;
      list<DAE.Exp> expl;
      Algorithm.Ident id; Boolean b;
      list<Algorithm.Statement> stmts;
      list<Integer> hv;
      Algorithm.Statement stmt;
      DAE.Exp e1,e2;
      Algorithm.Else elseB;
      DAE.ElementSource source;

    case(DAE.STMT_ASSIGN(tp,e2,e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (DAE.STMT_ASSIGN(tp,e2,e1,source),vars);

    case(DAE.STMT_TUPLE_ASSIGN(tp,expl,e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      (expl,vars) = expandDerExps(expl,vars);
    then (DAE.STMT_TUPLE_ASSIGN(tp,expl,e1,source),vars);

    case(DAE.STMT_ASSIGN_ARR(tp,cr,e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_ASSIGN_ARR(tp,cr,e1,source),vars);

    case(DAE.STMT_IF(e1,stmts,elseB,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      (elseB,vars) = expandDerOperatorElseBranch(elseB,vars);
    then (DAE.STMT_IF(e1,stmts,elseB,source),vars);

    case(DAE.STMT_FOR(tp,b,id,e1,stmts,source),vars) equation
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_FOR(tp,b,id,e1,stmts,source),vars);

    case(DAE.STMT_WHILE(e1,stmts,source),vars) equation
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_WHILE(e1,stmts,source),vars);

    case(DAE.STMT_WHEN(e1,stmts,SOME(stmt),hv,source),vars) equation
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      (stmt,vars) = expandDerOperatorStmt(stmt,vars);
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_WHEN(e1,stmts,SOME(stmt),hv,source),vars);

    case(DAE.STMT_WHEN(e1,stmts,NONE(),hv,source),vars) equation
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_WHEN(e1,stmts,NONE(),hv,source),vars);

    case(DAE.STMT_ASSERT(e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (DAE.STMT_ASSERT(e1,e2,source),vars);

    case(DAE.STMT_TERMINATE(e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_TERMINATE(e1,source),vars);

    case(DAE.STMT_REINIT(e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e1,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (DAE.STMT_REINIT(e1,e2,source),vars);

    case(stmt,vars)      then (stmt,vars);

  end matchcontinue;
end  expandDerOperatorStmt;

protected function expandDerOperatorElseBranch
"Help function to expandDerOperatorStmt, for else branches in if statements"
  input Algorithm.Else elseB;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output Algorithm.Else outElseB;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outElseB,outVars) := matchcontinue(elseB,vars)
    local DAE.Exp e1;
      list<Algorithm.Statement> stmts;
      Algorithm.Else elseB;

    case(DAE.NOELSE(),vars) then (DAE.NOELSE(),vars);

    case(DAE.ELSEIF(e1,stmts,elseB),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      (elseB,vars) = expandDerOperatorElseBranch(elseB,vars);
    then (DAE.ELSEIF(e1,stmts,elseB),vars);
  end matchcontinue;
end expandDerOperatorElseBranch;

protected function expandDerOperatorArrEqns
"Help function to expandDerOperator"
  input list<BackendDAE.MultiDimEquation> eqns;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output list<BackendDAE.MultiDimEquation> outEqns;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outEqns,outVars) := matchcontinue(eqns,vars)
  local BackendDAE.MultiDimEquation e;
    case({},vars) then ({},vars);
    case(e::eqns,vars) equation
      (e,vars) = expandDerOperatorArrEqn(e,vars);
      (eqns,vars)  = expandDerOperatorArrEqns(eqns,vars);
    then (e::eqns,vars);

    case(_,_) equation
      Debug.fprint("failtrace", "-DAELow.expandDerOperatorArrEqns failed\n");
    then fail();
  end matchcontinue;
end expandDerOperatorArrEqns;

protected function expandDerOperatorArrEqn
"Help function to to expandDerOperator, handles Array equations"
  input BackendDAE.MultiDimEquation arrEqn;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output BackendDAE.MultiDimEquation outArrEqn;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outArrEqn,outVars) := matchcontinue(arrEqn,vars)
    local
      list<Integer> dims; DAE.Exp e1,e2;
      DAE.ElementSource source "the element source";

    case(BackendDAE.MULTIDIM_EQUATION(dims,e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (BackendDAE.MULTIDIM_EQUATION(dims,e1,e2,source),vars);
  end matchcontinue;
end expandDerOperatorArrEqn;

protected function expandDerExps
"Help function to e.g. expandDerOperatorEqn"
  input list<DAE.Exp> expl;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output list<DAE.Exp> outExpl;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outExpl,outVars) := matchcontinue(expl,vars)
    local DAE.Exp e;
    case({},vars) then ({},vars);
    case(e::expl,vars) equation
      ((e,vars)) = expandDerExp((e,vars));
      (expl,vars) = expandDerExps(expl,vars);
    then (e::expl,vars);
  end matchcontinue;
end expandDerExps;

protected function expandDerExp
"Help function to e.g. expandDerOperatorEqn"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,DAE.FunctionTree>> tpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,DAE.FunctionTree>> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local DAE.Exp inExp;
      BackendDAE.Variables vars;
      DAE.FunctionTree funcs;
      DAE.Exp e1;
      list<DAE.ComponentRef> newStates;
    case((DAE.CALL(Absyn.IDENT(name = "der"),{e1},tuple_ = false,builtin = true),(vars,funcs))) equation
      e1 = Derive.differentiateExpTime(e1,(vars,funcs));
      e1 = Exp.simplify(e1);
      (newStates,_) = bintreeToList(statesExp(e1,BackendDAE.emptyBintree));
      vars = updateStatesVars(vars,newStates);
    then ((e1,(vars,funcs)));
    case((e1,(vars,funcs))) then ((e1,(vars,funcs)));
  end matchcontinue;
end expandDerExp;

protected function updateStatesVars
"Help function to expandDerExp"
  input BackendDAE.Variables vars;
  input list<DAE.ComponentRef> newStates;
  output BackendDAE.Variables outVars;
algorithm
  outVars := matchcontinue(vars,newStates)
    local
      DAE.ComponentRef cr1;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type vartype;
      Option<DAE.Exp> bind;
      Option<Values.Value> value;
      list<DAE.Subscript> dims;
      BackendDAE.Value ind;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ComponentRef cr;

    case(vars,{}) then vars;
    case(vars,cr::newStates)
      equation
        ((BackendDAE.VAR(cr1,kind,dir,vartype,bind,value,dims,ind,source,attr,comment,flowPrefix,streamPrefix) :: _),_) = getVar(cr, vars);
        vars = addVar(BackendDAE.VAR(cr1,BackendDAE.STATE(),dir,vartype,bind,value,dims,ind,source,attr,comment,flowPrefix,streamPrefix), vars);
        vars = updateStatesVars(vars,newStates);
      then vars;
    case(vars,cr::newStates)
      equation
        print("Internal error, variable ");print(ComponentReference.printComponentRefStr(cr));print("not found in variables.\n");
        vars = updateStatesVars(vars,newStates);
      then vars;
  end matchcontinue;
end updateStatesVars;

protected function addDummyState
"function: addDummyState
  In order for the solver to work correctly at least one state variable
  must exist in the equation system. This function therefore adds a
  dummy state variable and an equation for that variable.
  inputs:  (vars: Variables, eqns: BackendDAE.Equation list, bool)
  outputs: (Variables, BackendDAE.Equation list)"
  input BackendDAE.Variables inVariables;
  input list<BackendDAE.Equation> inEquationLst;
  input Boolean inBoolean;
  output BackendDAE.Variables outVariables;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  (outVariables,outEquationLst):=
  matchcontinue (inVariables,inEquationLst,inBoolean)
    local
      BackendDAE.Variables v,vars_1,vars;
      list<BackendDAE.Equation> e,eqns;
      DAE.ComponentRef cref_;
    case (v,e,false) then (v,e);
    case (vars,eqns,true) /* TODO::The dummy variable must be fixed */
      equation
        cref_ = ComponentReference.makeCrefIdent("$dummy",DAE.ET_REAL(),{});
        vars_1 = addVar(BackendDAE.VAR(cref_, BackendDAE.STATE(),DAE.BIDIR(),BackendDAE.REAL(),NONE(),NONE(),{},-1,
                            DAE.emptyElementSource,
                            SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(true)),NONE(),NONE(),NONE(),NONE(),NONE())),
                            NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM()), vars);
      then
        /*
         * Add equation der(dummy) = sin(time*6628.318530717). This so the solver has something to solve
         * if the model does not contain states. To prevent the solver from taking larger and larger steps
         * (which would happen if der(dymmy) = 0) when using automatic, we have a osciallating derivative.
        (vars_1,(BackendDAE.EQUATION(
          DAE.CALL(Absyn.IDENT("der"),
          {DAE.CREF(cref_},false,true,DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sin"),{DAE.BINARY(
          	DAE.CREF(ComponentReference.makeCrefIdent("time",{}),DAE.ET_REAL()),
          	DAE.MUL(DAE.ET_REAL()),
          	DAE.RCONST(628.318530717))},false,true,DAE.ET_REAL()))  :: eqns)); */
        /*
         *
         * adrpo: after a bit of talk with Francesco Casella & Peter Aronsson we will add der($dummy) = 0;
         */
        (vars_1,(BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("der"),
                          {DAE.CREF(cref_,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE()),
                          DAE.RCONST(0.0), DAE.emptyElementSource)  :: eqns));

  end matchcontinue;
end addDummyState;

public function zeroCrossingsEquations
"Returns a list of all equations (by their index) that contain a zero crossing
 Used e.g. to find out which discrete equations are not part of a zero crossing"
  input BackendDAE.DAELow dae;
  output list<Integer> eqns;
algorithm
  eqns := matchcontinue(dae)
    case (BackendDAE.DAELOW(eventInfo=BackendDAE.EVENT_INFO(zeroCrossingLst = zcLst),orderedEqs=eqnArr)) local
      list<BackendDAE.ZeroCrossing> zcLst;
      list<list<Integer>> zcEqns;
      list<Integer> wcEqns;
      BackendDAE.EquationArray eqnArr;
      equation
        zcEqns = Util.listMap(zcLst,zeroCrossingEquations);
        wcEqns = whenEquationsIndices(eqnArr);
        eqns = Util.listListUnion(listAppend(zcEqns,{wcEqns}));
      then eqns;
  end matchcontinue;
end zeroCrossingsEquations;

protected function whenEquationsIndices "Returns all equation-indices that contain a when clause"
  input BackendDAE.EquationArray eqns;
  output list<Integer> res;
algorithm
   res := matchcontinue(eqns)
     case(eqns) equation
         res=whenEquationsIndices2(1,equationSize(eqns),eqns);
       then res;
   end matchcontinue;
end whenEquationsIndices;

protected function whenEquationsIndices2
"Help function"
  input Integer i;
  input Integer size;
  input BackendDAE.EquationArray eqns;
  output list<Integer> eqnLst;
algorithm
  eqnLst := matchcontinue(i,size,eqns)
    case(i,size,eqns) equation
      true = (i > size );
    then {};
    case(i,size,eqns)
      equation
        BackendDAE.WHEN_EQUATION(whenEquation = _) = equationNth(eqns,i-1);
        eqnLst = whenEquationsIndices2(i+1,size,eqns);
    then i::eqnLst;
    case(i,size,eqns)
      equation
        eqnLst=whenEquationsIndices2(i+1,size,eqns);
      then eqnLst;
  end matchcontinue;
end whenEquationsIndices2;

protected function zeroCrossingEquations
"Returns the list of equations (indices) from a ZeroCrossing"
  input BackendDAE.ZeroCrossing zc;
  output list<Integer> lst;
algorithm
  lst := matchcontinue(zc)
    case(BackendDAE.ZERO_CROSSING(_,lst,_)) then lst;
  end matchcontinue;
end zeroCrossingEquations;

protected function mergeZeroCrossings
"function: mergeZeroCrossings
  Takes a list of zero crossings and if more than one have identical
  function expressions they are merged into one zerocrossing.
  In the resulting list all zerocrossing have uniq function expressions."
  input list<BackendDAE.ZeroCrossing> inZeroCrossingLst;
  output list<BackendDAE.ZeroCrossing> outZeroCrossingLst;
algorithm
  outZeroCrossingLst:=
  matchcontinue (inZeroCrossingLst)
    local
      BackendDAE.ZeroCrossing zc,same_1;
      list<BackendDAE.ZeroCrossing> samezc,diff,diff_1,xs;
    case {} then {};
    case {zc} then {zc};
    case (zc :: xs)
      equation
        samezc = Util.listSelect1(xs, zc, sameZeroCrossing);
        diff = Util.listSelect1(xs, zc, differentZeroCrossing);
        diff_1 = mergeZeroCrossings(diff);
        same_1 = Util.listFold(samezc, mergeZeroCrossing, zc);
      then
        (same_1 :: diff_1);
  end matchcontinue;
end mergeZeroCrossings;

protected function mergeZeroCrossing "function: mergeZeroCrossing

  Merges two zero crossings into one by makeing the union of the lists of
  equaions and when clauses they appear in.
"
  input BackendDAE.ZeroCrossing inZeroCrossing1;
  input BackendDAE.ZeroCrossing inZeroCrossing2;
  output BackendDAE.ZeroCrossing outZeroCrossing;
algorithm
  outZeroCrossing:=
  matchcontinue (inZeroCrossing1,inZeroCrossing2)
    local
      list<BackendDAE.Value> eq,zc,eq1,wc1,eq2,wc2;
      DAE.Exp e1,e2;
    case (BackendDAE.ZERO_CROSSING(relation_ = e1,occurEquLst = eq1,occurWhenLst = wc1),BackendDAE.ZERO_CROSSING(relation_ = e2,occurEquLst = eq2,occurWhenLst = wc2))
      equation
        eq = Util.listUnion(eq1, eq2);
        zc = Util.listUnion(wc1, wc2);
      then
        BackendDAE.ZERO_CROSSING(e1,eq,zc);
  end matchcontinue;
end mergeZeroCrossing;

protected function sameZeroCrossing "function: sameZeroCrossing

  Returns true if both zero crossings have the same function expression
"
  input BackendDAE.ZeroCrossing inZeroCrossing1;
  input BackendDAE.ZeroCrossing inZeroCrossing2;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inZeroCrossing1,inZeroCrossing2)
    local
      Boolean res;
      DAE.Exp e1,e2;
    case (BackendDAE.ZERO_CROSSING(relation_ = e1),BackendDAE.ZERO_CROSSING(relation_ = e2))
      equation
        res = Exp.expEqual(e1, e2);
      then
        res;
  end matchcontinue;
end sameZeroCrossing;

protected function differentZeroCrossing "function: differentZeroCrossing

  Return true if the realation expressions differ.
"
  input BackendDAE.ZeroCrossing zc1;
  input BackendDAE.ZeroCrossing zc2;
  output Boolean res_1;
  Boolean res,res_1;
algorithm
  res := sameZeroCrossing(zc1, zc2);
  res_1 := boolNot(res);
end differentZeroCrossing;

protected function findZeroCrossings "function: findZeroCrossings

  This function finds all zerocrossings in the list of equations and
  the list of when clauses. Used in lower2.
"
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  input list<BackendDAE.Equation> eq;
  input list<BackendDAE.MultiDimEquation> multiDimEqs;
  input list<BackendDAE.WhenClause> wc;
  input list<DAE.Algorithm> algs;
  output list<BackendDAE.ZeroCrossing> res_1;
  list<BackendDAE.ZeroCrossing> res,res_1;
algorithm
  res := findZeroCrossings2(vars, knvars,eq,multiDimEqs,1, wc, 1, algs);
  res_1 := mergeZeroCrossings(res);
end findZeroCrossings;

protected function findZeroCrossings2 "function: findZeroCrossings2

  Helper function to find_zero_crossing.
"
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables knvars;
  input list<BackendDAE.Equation> inEquationLst2;
  input list<BackendDAE.MultiDimEquation> inMultiDimEqs;
  input Integer inInteger3;
  input list<BackendDAE.WhenClause> inWhenClauseLst4;
  input Integer inInteger5;
  input list<DAE.Algorithm> algs;

  output list<BackendDAE.ZeroCrossing> outZeroCrossingLst;
algorithm
  outZeroCrossingLst:=
  matchcontinue (inVariables1,knvars,inEquationLst2,inMultiDimEqs,inInteger3,inWhenClauseLst4,inInteger5,algs)
    local
      BackendDAE.Variables v;
      list<DAE.Exp> rellst1,rellst2,rel;
      list<BackendDAE.ZeroCrossing> zc1,zc2,zc3,zc4,res,res1,res2;
      list<BackendDAE.MultiDimEquation> mdeqs;
      BackendDAE.Value eq_count_1,eq_count,wc_count_1,wc_count;
      BackendDAE.Equation e;
      DAE.Exp e1,e2;
      list<BackendDAE.Equation> xs,el;
      BackendDAE.WhenClause wc;
      Integer ind;
      DAE.ElementSource source "the element source";

    case (v,knvars,{},_,_,{},_,_) then {};
    case (v,knvars,((e as BackendDAE.EQUATION(exp = e1,scalar = e2)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1, v,knvars);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        rellst2 = findZeroCrossings3(e2, v,knvars);
        zc2 = makeZeroCrossings(rellst2, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, knvars,xs,mdeqs,eq_count_1, {}, 0,algs);
        zc4 = listAppend(zc1, zc2);
        res = listAppend(zc3, zc4);
      then
        res;
    case (v,knvars,((e as BackendDAE.COMPLEX_EQUATION(lhs = e1,rhs = e2)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1, v,knvars);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        rellst2 = findZeroCrossings3(e2, v,knvars);
        zc2 = makeZeroCrossings(rellst2, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, knvars,xs,mdeqs,eq_count_1, {}, 0,algs);
        zc4 = listAppend(zc1, zc2);
        res = listAppend(zc3, zc4);
      then
        res;
    case (v,knvars,((e as BackendDAE.ARRAY_EQUATION(index = ind)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        // Find the correct multidim equation from the index
        BackendDAE.MULTIDIM_EQUATION(left=e1,right=e2,source=source) = listNth(mdeqs,ind);
        e = BackendDAE.EQUATION(e1,e2,source);
        res = findZeroCrossings2(v,knvars,e::xs,mdeqs,eq_count,{},0,algs);
      then
        res;
    case (v,knvars,((e as BackendDAE.SOLVED_EQUATION(exp = e1)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1, v,knvars);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, knvars,xs,mdeqs,eq_count_1, {}, 0,algs);
        res = listAppend(zc3, zc1);
      then
        res;
    case (v,knvars,((e as BackendDAE.RESIDUAL_EQUATION(exp = e1)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1,v,knvars);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, knvars,xs,mdeqs,eq_count_1, {}, 0,algs);
        res = listAppend(zc3, zc1);
      then
        res;
    case (v,knvars,((e as BackendDAE.ALGORITHM(index = ind)) :: xs),mdeqs,eq_count,{},_,algs)
      local
        list<Algorithm.Statement> stmts;
      equation
        eq_count_1 = eq_count + 1;
        zc1 = findZeroCrossings2(v,knvars,xs,mdeqs,eq_count_1,{},0,algs);
        DAE.ALGORITHM_STMTS(stmts) = listNth(algs,ind);
        rel = Algorithm.getAllExpsStmts(stmts);
        rellst1 = Util.listFlatten(Util.listMap2(rel,findZeroCrossings3,v,knvars));
        zc2 = makeZeroCrossings(rellst1, {eq_count}, {});
        res = listAppend(zc2, zc1);
      then
        res;
    case (v,knvars,(e :: xs),mdeqs,eq_count,{},_,algs)
      equation
        eq_count_1 = eq_count + 1;
        (res) = findZeroCrossings2(v,knvars, xs,mdeqs,eq_count_1, {}, 0,algs);
      then
        res;
    case (v,knvars,el,mdeqs,eq_count,((wc as BackendDAE.WHEN_CLAUSE(condition = e)) :: xs),wc_count,algs)
      local
        DAE.Exp e;
        list<BackendDAE.WhenClause> xs;
      equation
        wc_count_1 = wc_count + 1;
        (res1) = findZeroCrossings2(v, knvars,el,mdeqs,eq_count, xs, wc_count_1,algs);
        rel = findZeroCrossings3(e, v,knvars);
        res2 = makeZeroCrossings(rel, {}, {wc_count});
        res = listAppend(res1, res2);
      then
        res;
  end matchcontinue;
end findZeroCrossings2;

protected function collectZeroCrossings "function: collectZeroCrossings

  Collects zero crossings
"
  input tuple<DAE.Exp, tuple<list<DAE.Exp>, tuple<BackendDAE.Variables,BackendDAE.Variables>>> inTplExpExpTplExpExpLstVariables;
  output tuple<DAE.Exp, tuple<list<DAE.Exp>, tuple<BackendDAE.Variables,BackendDAE.Variables>>> outTplExpExpTplExpExpLstVariables;
algorithm
  outTplExpExpTplExpExpLstVariables:=
  matchcontinue (inTplExpExpTplExpExpLstVariables)
    local
      DAE.Exp e,e1,e2,e_1;
      BackendDAE.Variables vars,knvars;
      list<DAE.Exp> zeroCrossings,zeroCrossings_1,zeroCrossings_2,zeroCrossings_3,el;
      DAE.Operator op;
      DAE.ExpType tp;
      Boolean scalar;
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "noEvent"))),(zeroCrossings,(vars,knvars)))) then ((e,({},(vars,knvars))));
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "sample"))),(zeroCrossings,(vars,knvars)))) then ((e,((e :: zeroCrossings),(vars,knvars))));

    case (((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),(zeroCrossings,(vars,knvars)))) /* function with discrete expressions generate no zerocrossing */
      equation
        true = isDiscreteExp(e1, vars,knvars);
        true = isDiscreteExp(e2, vars,knvars);
      then
        ((e,(zeroCrossings,(vars,knvars))));
    case (((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),(zeroCrossings,(vars,knvars))))
      equation
      then ((e,((e :: zeroCrossings),(vars,knvars))));  /* All other functions generate zerocrossing. */
    case (((e as DAE.ARRAY(array = {})),(zeroCrossings,(vars,knvars))))
      equation
      then ((e,(zeroCrossings,(vars,knvars))));
    case ((e1 as DAE.ARRAY(ty = tp,scalar = scalar,array = (e :: el)),(zeroCrossings,(vars,knvars))))
      equation
        ((_,(zeroCrossings_1,(vars,knvars)))) = Exp.traverseExp(e, collectZeroCrossings, (zeroCrossings,(vars,knvars)));
        ((e_1,(zeroCrossings_2,(vars,knvars)))) = collectZeroCrossings((DAE.ARRAY(tp,scalar,el),(zeroCrossings,(vars,knvars))));
        zeroCrossings_3 = listAppend(zeroCrossings_1, zeroCrossings_2);
      then
        ((e1,(zeroCrossings_3,(vars,knvars))));
    case ((e,(zeroCrossings,(vars,knvars))))
      equation
      then ((e,(zeroCrossings,(vars,knvars))));
  end matchcontinue;
end collectZeroCrossings;

public function isVarDiscrete " returns true if variable is discrete"
input BackendDAE.Var var;
output Boolean res;
algorithm
  res := matchcontinue(var)
    case(BackendDAE.VAR(varKind=kind)) local BackendDAE.VarKind kind;
      then isKindDiscrete(kind);
  end matchcontinue;
end isVarDiscrete;


protected function isKindDiscrete "function: isKindDiscrete

  Returns true if BackendDAE.VarKind is discrete.
"
  input BackendDAE.VarKind inVarKind;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVarKind)
    case (BackendDAE.DISCRETE()) then true;
    case (BackendDAE.PARAM()) then true;
    case (BackendDAE.CONST()) then true;
    case (_) then false;
  end matchcontinue;
end isKindDiscrete;

protected function isDiscreteExp "function: isDiscreteExp
 Returns true if expression is a discrete expression."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables knvars;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp,inVariables,knvars)
    local
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      Boolean res,b1,b2,b3;
      DAE.Exp e1,e2,e,e3;
      DAE.Operator op;
      list<Boolean> blst;
      list<DAE.Exp> expl,expl_2;
      DAE.ExpType tp;
      list<tuple<DAE.Exp, Boolean>> expl_1;

    case (DAE.ICONST(integer = _),vars,knvars) then true;
    case (DAE.RCONST(real = _),vars,knvars) then true;
    case (DAE.SCONST(string = _),vars,knvars) then true;
    case (DAE.BCONST(bool = _),vars,knvars) then true;
    case (DAE.ENUM_LITERAL(name = _),vars,knvars) then true;

    case (DAE.CREF(componentRef = cr),vars,knvars)
      equation
        ((BackendDAE.VAR(varKind = kind) :: _),_) = getVar(cr, vars);
        res = isKindDiscrete(kind);
      then
        res;
        /* builtin variable time is not discrete */
    case (DAE.CREF(componentRef = DAE.CREF_IDENT("time",_,_)),vars,knvars)
      then false;

        /* Known variables that are input are continous */
    case (DAE.CREF(componentRef = cr),vars,knvars)
      local BackendDAE.Var v;
      equation
        failure((_,_) = getVar(cr, vars));
        (v::_,_) = getVar(cr,knvars);
        true = isInput(v);
      then
        false;

        /* parameters & constants */
    case (DAE.CREF(componentRef = cr),vars,knvars)
      equation
        failure((_,_) = getVar(cr, vars));
        ((BackendDAE.VAR(varKind = kind) :: _),_) = getVar(cr, knvars);
        res = isKindDiscrete(kind);
      then
        res;
        /* enumerations */
    //case (DAE.CREF(DAE.CREF_IDENT(identType = DAE.ET_ENUMERATION(path = _)),_),vars,knvars) then true;

    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (DAE.UNARY(operator = op,exp = e),vars,knvars)
      equation
        res = isDiscreteExp(e, vars,knvars);
      then
        res;
    case (DAE.LUNARY(operator = op,exp = e),vars,knvars)
      equation
        res = isDiscreteExp(e, vars,knvars);
      then
        res;
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),vars,knvars) then true;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        b3 = isDiscreteExp(e3, vars,knvars);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    case (DAE.CALL(path = Absyn.IDENT(name = "pre")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "edge")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "change")),vars,knvars) then true;

    case (DAE.CALL(path = Absyn.IDENT(name = "ceil")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "floor")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "div")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "mod")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "rem")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "abs")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "sign")),vars,knvars) then true;

    case (DAE.CALL(path = Absyn.IDENT(name = "noEvent")),vars,knvars) then false;

    case (DAE.CALL(expLst = expl),vars,knvars)
      equation
        blst = Util.listMap2(expl, isDiscreteExp, vars,knvars);
        res = Util.boolAndList(blst);
      then
        res;
    case (DAE.ARRAY(ty = tp,array = expl),vars,knvars)
      equation
        blst = Util.listMap2(expl, isDiscreteExp, vars,knvars);
        res = Util.boolAndList(blst);
      then
        res;
    case (DAE.MATRIX(ty = tp,scalar = expl),vars,knvars)
      local list<list<tuple<DAE.Exp, Boolean>>> expl;
      equation
        expl_1 = Util.listFlatten(expl);
        expl_2 = Util.listMap(expl_1, Util.tuple21);
        blst = Util.listMap2(expl_2, isDiscreteExp, vars,knvars);
        res = Util.boolAndList(blst);
      then
        res;
    case (DAE.RANGE(ty = tp,exp = e1,expOption = SOME(e2),range = e3),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        b3 = isDiscreteExp(e3, vars,knvars);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    case (DAE.RANGE(ty = tp,exp = e1,expOption = NONE(),range = e2),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (DAE.TUPLE(PR = expl),vars,knvars)
      equation
        blst = Util.listMap2(expl, isDiscreteExp, vars,knvars);
        res = Util.boolAndList(blst);
      then
        res;
    case (DAE.CAST(ty = tp,exp = e1),vars,knvars)
      equation
        res = isDiscreteExp(e1, vars,knvars);
      then
        res;
    case (DAE.ASUB(exp = e),vars,knvars)
      equation
        res = isDiscreteExp(e, vars,knvars);
      then
        res;
    case (DAE.SIZE(exp = e1,sz = SOME(e2)),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (DAE.SIZE(exp = e1,sz = NONE()),vars,knvars)
      equation
        res = isDiscreteExp(e1, vars,knvars);
      then
        res;
    case (DAE.REDUCTION(expr = e1,range = e2),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (_,vars,knvars) then false;
  end matchcontinue;
end isDiscreteExp;

public function isDiscreteEquation
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output Boolean b;
algorithm
  b := matchcontinue(eqn,vars,knvars)
  local DAE.Exp e1,e2; DAE.ComponentRef cr; list<DAE.Exp> expl;
    case(BackendDAE.EQUATION(exp = e1,scalar = e2),vars,knvars) equation
      b = boolAnd(isDiscreteExp(e1,vars,knvars), isDiscreteExp(e2,vars,knvars));
    then b;
    case(BackendDAE.COMPLEX_EQUATION(lhs = e1,rhs = e2),vars,knvars) equation
      b = boolAnd(isDiscreteExp(e1,vars,knvars), isDiscreteExp(e2,vars,knvars));
    then b;
    case(BackendDAE.ARRAY_EQUATION(crefOrDerCref = expl),vars,knvars) equation
      b = Util.boolAndList(Util.listMap2(expl,isDiscreteExp,vars,knvars));
    then b;
    case(BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2),vars,knvars) equation
      b = boolAnd(isDiscreteExp(DAE.CREF(cr,DAE.ET_OTHER()),vars,knvars), isDiscreteExp(e2,vars,knvars));
    then b;
    case(BackendDAE.RESIDUAL_EQUATION(exp = e1),vars,knvars) equation
      b = isDiscreteExp(e1,vars,knvars);
    then b;
    case(BackendDAE.ALGORITHM(in_ = expl),vars,knvars) equation
      b = Util.boolAndList(Util.listMap2(expl,isDiscreteExp,vars,knvars));
    then b;
    case(BackendDAE.WHEN_EQUATION(whenEquation = _),vars,knvars) then true;
  end matchcontinue;
end isDiscreteEquation;

protected function findZeroCrossings3
"function: findZeroCrossings3
  Helper function to findZeroCrossing."
  input DAE.Exp e;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output list<DAE.Exp> zeroCrossings;
algorithm
  ((_,(zeroCrossings,_))) := Exp.traverseExp(e, collectZeroCrossings, ({},(vars,knvars)));
end findZeroCrossings3;

protected function makeZeroCrossing
"function: makeZeroCrossing
  Constructs a BackendDAE.ZeroCrossing from an expression and lists of equation indices
  and when clause indices."
  input DAE.Exp inExp1;
  input list<Integer> inIntegerLst2;
  input list<Integer> inIntegerLst3;
  output BackendDAE.ZeroCrossing outZeroCrossing;
algorithm
  outZeroCrossing := matchcontinue (inExp1,inIntegerLst2,inIntegerLst3)
    local
      DAE.Exp e;
      list<BackendDAE.Value> eq_ind,wc_ind;
    case (e,eq_ind,wc_ind) then BackendDAE.ZERO_CROSSING(e,eq_ind,wc_ind);
  end matchcontinue;
end makeZeroCrossing;

protected function makeZeroCrossings
"function: makeZeroCrossings
  Constructs a list of ZeroCrossings from a list expressions
  and lists of equation indices and when clause indices.
  Each Zerocrossing gets the same lists of indicies."
  input list<DAE.Exp> inExpExpLst1;
  input list<Integer> inIntegerLst2;
  input list<Integer> inIntegerLst3;
  output list<BackendDAE.ZeroCrossing> outZeroCrossingLst;
algorithm
  outZeroCrossingLst := matchcontinue (inExpExpLst1,inIntegerLst2,inIntegerLst3)
    local
      BackendDAE.ZeroCrossing res;
      list<BackendDAE.ZeroCrossing> resx;
      DAE.Exp e;
      list<DAE.Exp> xs;
      list<BackendDAE.Value> eq_ind,wc_ind;
    case ({},_,_) then {};
    case ((e :: xs),eq_ind,wc_ind)
      equation
        res = makeZeroCrossing(e, eq_ind, wc_ind);
        resx = makeZeroCrossings(xs, eq_ind, wc_ind);
      then
        (res :: resx);
  end matchcontinue;
end makeZeroCrossings;

protected function detectImplicitDiscrete
"function: detectImplicitDiscrete
  This function updates the variable kind to discrete
  for variables set in when equations."
  input BackendDAE.Variables inVariables;
  input list<BackendDAE.Equation> inEquationLst;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inVariables,inEquationLst)
    local
      BackendDAE.Variables v,v_1,v_2;
      DAE.ComponentRef cr,orig;
      DAE.VarDirection dir;
      BackendDAE.Type vartype;
      Option<DAE.Exp> bind;
      Option<Values.Value> value;
      list<DAE.Subscript> dims;
      BackendDAE.Value ind;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<BackendDAE.Equation> xs;
    case (v,{}) then v;
    case (v,(BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left = cr)) :: xs))
      equation
        ((BackendDAE.VAR(cr,_,dir,vartype,bind,value,dims,ind,source,attr,comment,flowPrefix,streamPrefix) :: _),_) = getVar(cr, v);
        v_1 = addVar(BackendDAE.VAR(cr,BackendDAE.DISCRETE(),dir,vartype,bind,value,dims,ind,source,attr,comment,flowPrefix,streamPrefix), v);
        v_2 = detectImplicitDiscrete(v_1, xs);
      then
        v_2;
        /* TODO: should also check when-algorithms */
    case (v,(_ :: xs))
      equation
        v_1 = detectImplicitDiscrete(v, xs);
      then
        v_1;
  end matchcontinue;
end detectImplicitDiscrete;

protected function sortEqn
"function: sortEqn
  This function sorts the equation. It puts first the algebraic eqns
  and last the differentiated eqns"
  input list<BackendDAE.Equation> inEquationLst;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst:=
  matchcontinue (inEquationLst)
    local list<BackendDAE.Equation> algEqns,diffEqns,res,eqns,resArrayEqns;
    case (eqns)
      equation
        (algEqns,diffEqns,resArrayEqns) = extractAlgebraicAndDifferentialEqn(eqns);
        res = Util.listFlatten({algEqns, diffEqns,resArrayEqns});
      then
        res;
    case (eqns)
      equation
        print("sort_eqn failed \n");
      then
        fail();
  end matchcontinue;
end sortEqn;

protected function extractAlgebraicAndDifferentialEqn
"function: extractAlgebraicAndDifferentialEqn

  Splits the equation list into two lists. One that only contain differential
  equations and one that only contain algebraic equations."
  input list<BackendDAE.Equation> inEquationLst;
  output list<BackendDAE.Equation> outEquationLst1;
  output list<BackendDAE.Equation> outEquationLst2;
  output list<BackendDAE.Equation> outEquationLst3;
algorithm
  (outEquationLst1,outEquationLst2,outEquationLst3):= matchcontinue (inEquationLst)
    local
      list<BackendDAE.Equation> resAlgEqn,resDiffEqn,rest,resArrayEqns;
      BackendDAE.Equation eqn,alg;
      DAE.Exp exp1,exp2;
      list<Boolean> bool_lst;
      BackendDAE.Value indx;
      list<DAE.Exp> expl;
    case ({}) then ({},{},{});  /* algebraic equations differential equations */
    case (((eqn as BackendDAE.EQUATION(exp = exp1,scalar = exp2)) :: rest)) /* scalar equation */
      equation
        true = isAlgebraic(exp1);
        true = isAlgebraic(exp2);
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        ((eqn :: resAlgEqn),resDiffEqn,resArrayEqns);
    case (((eqn as BackendDAE.COMPLEX_EQUATION(lhs = exp1,rhs = exp2)) :: rest)) /* complex equation */
      equation
        true = isAlgebraic(exp1);
        true = isAlgebraic(exp2);
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        ((eqn :: resAlgEqn),resDiffEqn,resArrayEqns);
    case (((eqn as BackendDAE.ARRAY_EQUATION(index = indx,crefOrDerCref = expl)) :: rest)) /* array equation */
      equation
        bool_lst = Util.listMap(expl, isAlgebraic);
        true = Util.boolAndList(bool_lst);
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        (resAlgEqn,resDiffEqn,(eqn :: resArrayEqns));
    case (((eqn as BackendDAE.EQUATION(exp = exp1,scalar = exp2)) :: rest))
      equation
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        (resAlgEqn,(eqn :: resDiffEqn),resArrayEqns);
    case (((eqn as BackendDAE.COMPLEX_EQUATION(lhs = exp1,rhs = exp2)) :: rest))
      equation
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        (resAlgEqn,(eqn :: resDiffEqn),resArrayEqns);
    case (((eqn as BackendDAE.ARRAY_EQUATION(index = _)) :: rest))
      equation
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        (resAlgEqn,(eqn :: resDiffEqn),resArrayEqns);
    case ((alg :: rest))
      equation
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest) "Put algorithms in algebraic equations" ;
      then
        ((alg :: resAlgEqn),resDiffEqn,resArrayEqns);
  end matchcontinue;
end extractAlgebraicAndDifferentialEqn;

public function generateStatePartition "function:generateStatePartition

  This function traverses the equations to find out which blocks needs to
  be solved by the numerical solver (Dynamic Section) and which blocks only
  needs to be solved for output to file ( Accepted Section).
  This is done by traversing the graph of strong components, where
  equations/variable pairs correspond to nodes of the graph. The edges of
  this graph are the dependencies between blocks or components.
  The traversal is made in the backward direction of this graph.
  The result is a split of the blocks into two lists.
  inputs: (blocks: int list list,
             daeLow: DAELow,
             assignments1: int vector,
             assignments2: int vector,
             incidenceMatrix: IncidenceMatrix,
             incidenceMatrixT: IncidenceMatrixT)
  outputs: (dynamicBlocks: int list list, outputBlocks: int list list)
"
  input list<list<Integer>> inIntegerLstLst1;
  input BackendDAE.DAELow inDAELow2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix5;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT6;
  output list<list<Integer>> outIntegerLstLst1;
  output list<list<Integer>> outIntegerLstLst2;
algorithm
  (outIntegerLstLst1,outIntegerLstLst2):=
  matchcontinue (inIntegerLstLst1,inDAELow2,inIntegerArray3,inIntegerArray4,inIncidenceMatrix5,inIncidenceMatrixT6)
    local
      BackendDAE.Value size;
      array<BackendDAE.Value> arr,arr_1;
      list<list<BackendDAE.Value>> blt_states,blt_no_states,blt;
      BackendDAE.DAELow dae;
      BackendDAE.Variables v,kv;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      array<BackendDAE.Value> ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
    case (blt,(dae as BackendDAE.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = e,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al)),ass1,ass2,m,mt)
      equation
        size = arrayLength(ass1) "equation_size(e) => size &" ;
        arr = arrayCreate(size, 0);
        arr_1 = markStateEquations(dae, arr, m, mt, ass1, ass2);
        (blt_states,blt_no_states) = splitBlocks(blt, arr);
      then
        (blt_states,blt_no_states);
    case (_,_,_,_,_,_)
      equation
        print("-generate_state_partition failed\n");
      then
        fail();
  end matchcontinue;
end generateStatePartition;

protected function splitBlocks "function: splitBlocks

  Split the blocks into two parts, one dynamic and one output, depedning
  on if an equation in the block is marked or not.
  inputs:  (blocks: int list list, marks: int array)
  outputs: (dynamic: int list list, output: int list list)
"
  input list<list<Integer>> inIntegerLstLst;
  input array<Integer> inIntegerArray;
  output list<list<Integer>> outIntegerLstLst1;
  output list<list<Integer>> outIntegerLstLst2;
algorithm
  (outIntegerLstLst1,outIntegerLstLst2):=
  matchcontinue (inIntegerLstLst,inIntegerArray)
    local
      list<list<BackendDAE.Value>> states,output_,blocks;
      list<BackendDAE.Value> block_;
      array<BackendDAE.Value> arr;
    case ({},_) then ({},{});
    case ((block_ :: blocks),arr)
      equation
        true = blockIsDynamic(block_, arr) "block is dynamic, belong in dynamic section" ;
        (states,output_) = splitBlocks(blocks, arr);
      then
        ((block_ :: states),output_);
    case ((block_ :: blocks),arr)
      equation
        (states,output_) = splitBlocks(blocks, arr) "block is not dynamic, belong in output section" ;
      then
        (states,(block_ :: output_));
  end matchcontinue;
end splitBlocks;

protected function blockIsDynamic "function blockIsDynamic

  Return true if the block contains a variable that is marked
"
  input list<Integer> inIntegerLst;
  input array<Integer> inIntegerArray;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inIntegerLst,inIntegerArray)
    local
      BackendDAE.Value x_1,x,mark_value;
      Boolean res;
      list<BackendDAE.Value> xs;
      array<BackendDAE.Value> arr;
    case ({},_) then false;
    case ((x :: xs),arr)
      equation
        x_1 = x - 1;
        0 = arr[x_1 + 1];
        res = blockIsDynamic(xs, arr);
      then
        res;
    case ((x :: xs),arr)
      equation
        x_1 = x - 1;
        mark_value = arr[x_1 + 1];
        (mark_value <> 0) = true;
      then
        true;
  end matchcontinue;
end blockIsDynamic;

protected function markStateEquations "function: markStateEquations

  This function goes through all equations and marks the ones that
  calculates a state, or is needed in order to calculate a state,
  with a non-zero value in the array passed as argument.
  This is done by traversing the directed graph of nodes where
  a node is an equation/solved variable and following the edges in the
  backward direction.
  inputs: (daeLow: DAELow,
             marks: int array,
    incidenceMatrix: IncidenceMatrix,
    incidenceMatrixT: IncidenceMatrixT,
    assignments1: int vector,
    assignments2: int vector)
  outputs: marks: int array
"
  input BackendDAE.DAELow inDAELow1;
  input array<Integer> inIntegerArray2;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix3;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT4;
  input array<Integer> inIntegerArray5;
  input array<Integer> inIntegerArray6;
  output array<Integer> outIntegerArray;
algorithm
  outIntegerArray:=
  matchcontinue (inDAELow1,inIntegerArray2,inIncidenceMatrix3,inIncidenceMatrixT4,inIntegerArray5,inIntegerArray6)
    local
      list<BackendDAE.Var> v_lst,statevar_lst;
      BackendDAE.DAELow dae;
      array<BackendDAE.Value> arr_1,arr;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      BackendDAE.Variables v,kn;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> alg;
    case ((dae as BackendDAE.DAELOW(orderedVars = v,knownVars = kn,orderedEqs = e,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = alg)),arr,m,mt,a1,a2)
      equation
        v_lst = varList(v);
        statevar_lst = Util.listSelect(v_lst, isStateVar);
        ((dae,arr_1,m,mt,a1,a2)) = Util.listFold(statevar_lst, markStateEquation, (dae,arr,m,mt,a1,a2));
      then
        arr_1;
    case (_,_,_,_,_,_)
      equation
        print("-mark_state_equations failed\n");
      then
        fail();
  end matchcontinue;
end markStateEquations;

protected function markStateEquation
"function: markStateEquation
  This function is a helper function to mark_state_equations
  It performs marking for one equation and its transitive closure by
  following edges in backward direction.
  inputs and outputs are tuples so we can use Util.list_fold"
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.DAELow, array<Integer>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>> inTplDAELowIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
  output tuple<BackendDAE.DAELow, array<Integer>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>> outTplDAELowIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
algorithm
  outTplDAELowIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray:=
  matchcontinue (inVar,inTplDAELowIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray)
    local
      list<BackendDAE.Value> v_indxs,v_indxs_1,eqns;
      array<BackendDAE.Value> arr_1,arr;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      DAE.ComponentRef cr;
      BackendDAE.DAELow dae;
      BackendDAE.Variables vars;
      String s,str;
      BackendDAE.Value v_indx,v_indx_1;
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAELOW(orderedVars = vars)),arr,m,mt,a1,a2))
      equation
        (_,v_indxs) = getVar(cr, vars);
        v_indxs_1 = Util.listMap1(v_indxs, int_sub, 1);
        eqns = Util.listMap1r(v_indxs_1, arrayNth, a1);
        ((arr_1,m,mt,a1,a2)) = markStateEquation2(eqns, (arr,m,mt,a1,a2));
      then
        ((dae,arr_1,m,mt,a1,a2));
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAELOW(orderedVars = vars)),arr,m,mt,a1,a2))
      equation
        failure((_,_) = getVar(cr, vars));
        print("mark_state_equation var ");
        s = ComponentReference.printComponentRefStr(cr);
        print(s);
        print("not found\n");
      then
        fail();
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAELOW(orderedVars = vars)),arr,m,mt,a1,a2))
      equation
        (_,{v_indx}) = getVar(cr, vars);
        v_indx_1 = v_indx - 1;
        failure(eqn = a1[v_indx_1 + 1]);
        print("mark_state_equation index =");
        str = intString(v_indx);
        print(str);
        print(", failed\n");
      then
        fail();
  end matchcontinue;
end markStateEquation;

protected function markStateEquation2
"function: markStateEquation2
  Helper function to mark_state_equation
  Does the job by looking at variable indexes and incidencematrices.
  inputs: (eqns: int list,
             marks: (int array  BackendDAE.IncidenceMatrix  BackendDAE.IncidenceMatrixT  int vector  int vector))
  outputs: ((marks: int array  BackendDAE.IncidenceMatrix  IncidenceMatrixT
        int vector  int vector))"
  input list<Integer> inIntegerLst;
  input tuple<array<Integer>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>> inTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
  output tuple<array<Integer>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>> outTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
algorithm
  outTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray:=
  matchcontinue (inIntegerLst,inTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray)
    local
      array<BackendDAE.Value> marks,marks_1,marks_2,marks_3;
      array<list<BackendDAE.Value>> m,mt,m_1,mt_1;
      array<BackendDAE.Value> a1,a2,a1_1,a2_1;
      BackendDAE.Value eqn_1,eqn,mark_value,len;
      list<BackendDAE.Value> inv_reachable,inv_reachable_1,eqns;
      list<list<BackendDAE.Value>> inv_reachable_2;
      String eqnstr,lens,ms;
    case ({},(marks,m,mt,a1,a2)) then ((marks,m,mt,a1,a2));
    case ((eqn :: eqns),(marks,m,mt,a1,a2))
      equation
        eqn_1 = eqn - 1 "Mark an unmarked node/equation" ;
        0 = marks[eqn_1 + 1];
        marks_1 = arrayUpdate(marks, eqn_1 + 1, 1);
        inv_reachable = invReachableNodes(eqn, m, mt, a1, a2);
        inv_reachable_1 = removeNegative(inv_reachable);
        inv_reachable_2 = Util.listMap(inv_reachable_1, Util.listCreate);
        ((marks_2,m,mt,a1,a2)) = Util.listFold(inv_reachable_2, markStateEquation2, (marks_1,m,mt,a1,a2));
        ((marks_3,m_1,mt_1,a1_1,a2_1)) = markStateEquation2(eqns, (marks_2,m,mt,a1,a2));
      then
        ((marks_3,m_1,mt_1,a1_1,a2_1));
    case ((eqn :: eqns),(marks,m,mt,a1,a2))
      equation
        eqn_1 = eqn - 1 "Node allready marked." ;
        mark_value = marks[eqn_1 + 1];
        (mark_value <> 0) = true;
        ((marks_1,m_1,mt_1,a1_1,a2_1)) = markStateEquation2(eqns, (marks,m,mt,a1,a2));
      then
        ((marks_1,m_1,mt_1,a1_1,a2_1));
    case ((eqn :: _),(marks,m,mt,a1,a2))
      equation
        print("mark_state_equation2 failed, eqn:");
        eqnstr = intString(eqn);
        print(eqnstr);
        print("array length =");
        len = arrayLength(marks);
        lens = intString(len);
        print(lens);
        print("\n");
        eqn_1 = eqn - 1;
        mark_value = marks[eqn_1 + 1];
        ms = intString(mark_value);
        print("mark_value:");
        print(ms);
        print("\n");
      then
        fail();
  end matchcontinue;
end markStateEquation2;

protected function invReachableNodes "function: invReachableNodes

  Similar to reachable_nodes, but follows edges in backward direction
  I.e. what equations/variables needs to be solved to solve this one.
"
  input Integer inInteger1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input array<Integer> inIntegerArray4;
  input array<Integer> inIntegerArray5;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inInteger1,inIncidenceMatrix2,inIncidenceMatrixT3,inIntegerArray4,inIntegerArray5)
    local
      BackendDAE.Value eqn_1,e,eqn;
      list<BackendDAE.Value> var_lst,var_lst_1,lst;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      String eqn_str;
    case (e,m,mt,a1,a2)
      equation
        eqn_1 = e - 1;
        var_lst = m[eqn_1 + 1];
        var_lst_1 = removeNegative(var_lst);
        lst = invReachableNodes2(var_lst_1, a1);
      then
        lst;
    case (eqn,_,_,_,_)
      equation
        print("-inv_reachable_nodes failed, eqn:");
        eqn_str = intString(eqn);
        print(eqn_str);
        print("\n");
      then
        fail();
  end matchcontinue;
end invReachableNodes;

protected function invReachableNodes2 "function: invReachableNodes2

  Helper function to inv_reachable_nodes
  inputs:  (variables: int list, assignments1: int vector)
  outputs: int list
"
  input list<Integer> inIntegerLst;
  input array<Integer> inIntegerArray;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inIntegerLst,inIntegerArray)
    local
      list<BackendDAE.Value> eqns,vs;
      BackendDAE.Value v_1,eqn,v;
      array<BackendDAE.Value> a1;
    case ({},_) then {};
    case ((v :: vs),a1)
      equation
        eqns = invReachableNodes2(vs, a1);
        v_1 = v - 1;
        eqn = a1[v_1 + 1] "Which equation is variable solved in?" ;
      then
        (eqn :: eqns);
    case (_,_)
      equation
        print("-inv_reachable_nodes2 failed\n");
      then
        fail();
  end matchcontinue;
end invReachableNodes2;

public function isStateVar
"function: isStateVar
  Returns true for state variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local DAE.Flow flowPrefix;
    case (BackendDAE.VAR(varKind = BackendDAE.STATE())) then true;
    case (_) then false;
  end matchcontinue;
end isStateVar;

public function isNonStateVar
"function: isStateVar
  Returns true for state variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local DAE.Flow flowPrefix;
    case (BackendDAE.VAR(varKind = BackendDAE.STATE())) then false;
    case (_) then true;
  end matchcontinue;
end isNonStateVar;


public function isDummyStateVar
"function isDummyStateVar
  Returns true for dummy state variables, false otherwise."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE())) then true;
    case (_) then false;
  end matchcontinue;
end isDummyStateVar;

public function isNonState
"function: isNonState
  this equation checks if the the varkind is state of variable
  used both in build_equation and generate_compute_state"
  input BackendDAE.VarKind inVarKind;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVarKind)
    case (BackendDAE.VARIABLE()) then true;
    case (BackendDAE.PARAM()) then true;
    case (BackendDAE.DUMMY_DER()) then true;
    case (BackendDAE.DUMMY_STATE()) then true;
    case (BackendDAE.DISCRETE()) then true;
    case (BackendDAE.STATE_DER()) then true;
    case (_) then false;
  end matchcontinue;
end isNonState;

public function isDiscrete
"function: isDiscrete
  This equation checks if the the varkind is discrete,
  used both in build_equation and generate_compute_state"
  input BackendDAE.VarKind inVarKind;
algorithm
  _:=
  matchcontinue (inVarKind)
    case (BackendDAE.DISCRETE()) then ();
  end matchcontinue;
end isDiscrete;

public function varList
"function: varList
  Takes BackendDAE.Variables and returns a list of \'Var\', useful for e.g. dumping."
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVariables)
    local
      list<BackendDAE.Var> varlst;
      BackendDAE.VariableArray vararr;
    case (BackendDAE.VARIABLES(varArr = vararr))
      equation
        varlst = vararrayList(vararr);
      then
        varlst;
  end matchcontinue;
end varList;

public function listVar
"function: listVar
  author: PA
  Takes BackendDAE.Var list and creates a BackendDAE.Variables structure, see also var_list."
  input list<BackendDAE.Var> inVarLst;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables:=
  matchcontinue (inVarLst)
    local
      BackendDAE.Variables res,vars,vars_1;
      BackendDAE.Var v;
      list<BackendDAE.Var> vs;
    case ({})
      equation
        res = emptyVars();
      then
        res;
    case ((v :: vs))
      equation
        vars = listVar(vs);
        vars_1 = addVar(v, vars);
      then
        vars_1;
  end matchcontinue;
end listVar;

public function varCref
"function: varCref
  author: PA
  extracts the ComponentRef of a variable."
  input BackendDAE.Var inVar;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inVar)
    local
      DAE.ComponentRef cr;
      DAE.Flow flowPrefix;
    case (BackendDAE.VAR(varName = cr,flowPrefix = flowPrefix)) then cr;
  end matchcontinue;
end varCref;

public function varType "function: varType
  author: PA

  extracts the type of a variable.
"
  input BackendDAE.Var inVar;
  output BackendDAE.Type outType;
algorithm
  outType:=
  matchcontinue (inVar)
    local BackendDAE.Type tp;
    case (BackendDAE.VAR(varType = tp)) then tp;
  end matchcontinue;
end varType;

public function varKind "function: varKind
  author: PA

  extracts the kind of a variable.
"
  input BackendDAE.Var inVar;
  output BackendDAE.VarKind outVarKind;
algorithm
  outVarKind:=
  matchcontinue (inVar)
    local BackendDAE.VarKind kind;
    case (BackendDAE.VAR(varKind = kind)) then kind;
  end matchcontinue;
end varKind;

public function varIndex "function: varIndex
  author: PA

  extracts the index in the implementation vector of a Var
"
  input BackendDAE.Var inVar;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inVar)
    local BackendDAE.Value i;
    case (BackendDAE.VAR(index = i)) then i;
  end matchcontinue;
end varIndex;

public function varNominal "function: varNominal
  author: PA

  Extacts the nominal attribute of a variable. If the variable has no
  nominal value, the function fails.
"
  input BackendDAE.Var inVar;
  output Real outReal;
algorithm
  outReal := matchcontinue (inVar)
    local
      Real nominal;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,_,SOME(DAE.RCONST(nominal)),_,_,_,_)))) then nominal;
  end matchcontinue;
end varNominal;

public function setVarFixed
"function: setVarFixed
  author: PA
  Sets the fixed attribute of a variable."
  input BackendDAE.Var inVar;
  input Boolean inBoolean;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inVar,inBoolean)
    local
      DAE.ComponentRef a;
      BackendDAE.VarKind b;
      DAE.VarDirection c;
      BackendDAE.Type d;
      Option<DAE.Exp> e,h;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      BackendDAE.Value i;
      list<Absyn.Path> k;
      DAE.ElementSource source "the element source";
      Option<DAE.Exp> l,m,n;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> o;
      Option<DAE.Exp> p,q;
      Option<DAE.StateSelect> r;
      Option<SCode.Comment> s;
      DAE.Flow t;
      DAE.Stream streamPrefix;
      Boolean fixed;
      Option<DAE.StateSelect> stateSelectOption;
      Option<DAE.Exp> equationBound;
      Option<Boolean> isProtected;
      Option<Boolean> finalPrefix;

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(DAE.VAR_ATTR_REAL(l,m,n,o,p,_,q,r,equationBound,isProtected,finalPrefix)),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
    then BackendDAE.VAR(a,b,c,d,e,f,g,i,source,
             SOME(DAE.VAR_ATTR_REAL(l,m,n,o,p,SOME(DAE.BCONST(fixed)),q,r,equationBound,isProtected,finalPrefix)),
             s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(DAE.VAR_ATTR_INT(l,o,n,_,equationBound,isProtected,finalPrefix)),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        BackendDAE.VAR(a,b,c,d,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_INT(l,o,n,SOME(DAE.BCONST(fixed)),equationBound,isProtected,finalPrefix)),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(DAE.VAR_ATTR_BOOL(l,m,_,equationBound,isProtected,finalPrefix)),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        BackendDAE.VAR(a,b,c,d,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_BOOL(l,m,SOME(DAE.BCONST(fixed)),equationBound,isProtected,finalPrefix)),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(DAE.VAR_ATTR_ENUMERATION(l,o,n,_,equationBound,isProtected,finalPrefix)),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        BackendDAE.VAR(a,b,c,d,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_ENUMERATION(l,o,n,SOME(DAE.BCONST(fixed)),equationBound,isProtected,finalPrefix)),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = BackendDAE.REAL(),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE(),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        BackendDAE.VAR(a,b,c,BackendDAE.REAL(),e,f,g,i,source,
            SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(fixed)),NONE(),NONE(),NONE(),NONE(),NONE())),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = BackendDAE.INT(),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE(),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        BackendDAE.VAR(a,b,c,BackendDAE.REAL(),e,f,g,i,source,
            SOME(DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(fixed)),NONE(),NONE(),NONE())),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = BackendDAE.BOOL(),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE(),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        BackendDAE.VAR(a,b,c,BackendDAE.REAL(),e,f,g,i,source,
            SOME(DAE.VAR_ATTR_BOOL(NONE(),NONE(),SOME(DAE.BCONST(fixed)),NONE(),NONE(),NONE())),
            s,t,streamPrefix);

    case (BackendDAE.VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = BackendDAE.ENUMERATION(_),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE(),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        BackendDAE.VAR(a,b,c,BackendDAE.REAL(),e,f,g,i,source,
            SOME(DAE.VAR_ATTR_ENUMERATION(NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(fixed)),NONE(),NONE(),NONE())),
            s,t,streamPrefix);
  end matchcontinue;
end setVarFixed;

public function varFixed
"function: varFixed
  author: PA
  Extacts the fixed attribute of a variable.
  The default fixed value is used if not found. Default is true for parameters
  (and constants) and false for variables."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local
      Boolean fixed;
      BackendDAE.Var v;
    case (v as BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,SOME(DAE.BCONST(fixed)),_,_,_,_,_)))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_INT(_,_,_,SOME(DAE.BCONST(fixed)),_,_,_)))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_BOOL(_,_,SOME(DAE.BCONST(fixed)),_,_,_)))) then fixed;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_ENUMERATION(_,_,_,SOME(DAE.BCONST(fixed)),_,_,_)))) then fixed;
    case (v) /* param is fixed */
      equation
        BackendDAE.PARAM() = varKind(v);
      then
        true;
    case (v) /* states are by default fixed. */
      equation
        BackendDAE.STATE() = varKind(v);
      then
        true;
    case (_) then false;  /* rest defaults to false*/
  end matchcontinue;
end varFixed;

public function varStartValue
"function varStartValue
  author: PA
  Returns the DAE.StartValue of a variable."
  input BackendDAE.Var v;
  output DAE.Exp sv;
algorithm
  sv := matchcontinue(v)
    local
      Option<DAE.VariableAttributes> attr;
    case (BackendDAE.VAR(values = attr))
      equation
        sv=DAEUtil.getStartAttr(attr);
      then sv;
   end matchcontinue;
end varStartValue;

public function varStateSelect
"function varStateSelect
  author: PA
  Extacts the state select attribute of a variable. If no stateselect explicilty set, return
  StateSelect.default"
  input BackendDAE.Var inVar;
  output DAE.StateSelect outStateSelect;
algorithm
  outStateSelect:=
  matchcontinue (inVar)
    local
      DAE.StateSelect stateselect;
      BackendDAE.Var v;
    case (BackendDAE.VAR(values = SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,_,_,SOME(stateselect),_,_,_)))) then stateselect;
    case (_) then DAE.DEFAULT();
  end matchcontinue;
end varStateSelect;

public function vararrayList
"function: vararrayList
  Transforms a BackendDAE.VariableArray to a BackendDAE.Var list"
  input BackendDAE.VariableArray inVariableArray;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVariableArray)
    local
      array<Option<BackendDAE.Var>> arr;
      BackendDAE.Var elt;
      BackendDAE.Value lastpos,n,size;
      list<BackendDAE.Var> lst;
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = 0,varOptArr = arr)) then {};
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = 1,varOptArr = arr))
      equation
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr))
      equation
        lastpos = n - 1;
        lst = vararrayList2(arr, 0, lastpos);
      then
        lst;
  end matchcontinue;
end vararrayList;

protected function vararrayList2
"function: vararrayList2
  Helper function to vararrayList"
  input array<Option<BackendDAE.Var>> inVarOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVarOptionArray1,inInteger2,inInteger3)
    local
      BackendDAE.Var v;
      array<Option<BackendDAE.Var>> arr;
      BackendDAE.Value pos,lastpos,pos_1;
      list<BackendDAE.Var> res;
    case (arr,pos,lastpos)
      equation
        (pos == lastpos) = true;
        SOME(v) = arr[pos + 1];
      then
        {v};
    case (arr,pos,lastpos)
      equation
        pos_1 = pos + 1;
        SOME(v) = arr[pos + 1];
        res = vararrayList2(arr, pos_1, lastpos);
      then
        (v :: res);
  end matchcontinue;
end vararrayList2;

protected function removeSimpleEquations
"function: removeSimpleEquations
  This function moves simple equations on the form a=b from equations 2nd
  in BackendDAE.DAELow to simple equations 3rd in BackendDAE.DAELow to speed up assignment alg.
  inputs:  (vars: Variables,
              knownVars: Variables,
              eqns: BackendDAE.Equation list,
              simpleEqns: BackendDAE.Equation list,
        initEqns : Equatoin list,
              binTree: BinTree)
  outputs: (Variables, BackendDAE.Variables, BackendDAE.Equation list, BackendDAE.Equation list
         BackendDAE.Equation list)"
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables inVariables2;
  input list<BackendDAE.Equation> inEquationLst3;
  input list<BackendDAE.Equation> inEquationLst4;
  input list<BackendDAE.Equation> inEquationLst5;
  input list<BackendDAE.MultiDimEquation> inArrayEquationLst;
  input list<DAE.Algorithm> inAlgs;
  input BackendDAE.BinTree inBinTree6;
  output BackendDAE.Variables outVariables1;
  output BackendDAE.Variables outVariables2;
  output list<BackendDAE.Equation> outEquationLst3;
  output list<BackendDAE.Equation> outEquationLst4;
  output list<BackendDAE.Equation> outEquationLst5;
  output list<BackendDAE.MultiDimEquation> outArrayEquationLst;
  output list<DAE.Algorithm> outAlgs;
  output BackendDAE.AliasVariables aliasVars; // hash tables of alias-variables' replacement (a = b or a = -b)
algorithm
  (outVariables1,outVariables2,outEquationLst3,outEquationLst4,outEquationLst5,outArrayEquationLst,outAlgs,aliasVars):=
  matchcontinue (inVariables1,inVariables2,inEquationLst3,inEquationLst4,inEquationLst5,inArrayEquationLst,inAlgs,inBinTree6)
    local
      VarTransform.VariableReplacements repl,replc,replc_1,vartransf,vartransf1;
      list<BackendDAE.Equation> eqns_1,seqns,eqns_2,seqns_1,ieqns_1,eqns_3,seqns_2,ieqns_2,seqns_3,eqns,reqns,ieqns;
      list<BackendDAE.MultiDimEquation> arreqns,arreqns1,arreqns2;
      BackendDAE.BinTree movedvars_1,states,outputs;
      BackendDAE.Variables vars_1,knvars_1,vars,knvars;
      list<DAE.Exp> crlst,elst;
      list<DAE.Algorithm> algs,algs_1;
      list<tuple<list<DAE.Exp>,list<DAE.Exp>>> inputsoutputs;
      BackendDAE.AliasVariables varsAliases;      
      //HashTable2.HashTable aliasMappings "mappings alias-variable => true-variable";
      //Variables aliasVars "alias-variables metadata";
    case (vars,knvars,eqns,reqns,ieqns,arreqns,algs,states)
      equation
        repl = VarTransform.emptyReplacements();
        replc = VarTransform.emptyReplacements();

        outputs = BackendDAE.emptyBintree;
        outputs = getOutputsFromAlgorithms(eqns,outputs);
        (eqns_1,seqns,movedvars_1,vartransf,_,replc_1) = removeSimpleEquations2(eqns, simpleEquation, vars, knvars, BackendDAE.emptyBintree, states, outputs, repl, {},replc);
        vartransf1 = VarTransform.addMultiDimReplacements(vartransf);
        Debug.fcall("dumprepl", VarTransform.dumpReplacements, vartransf1);
        Debug.fcall("dumpreplc", VarTransform.dumpReplacements, replc_1);
        eqns_2 = BackendVarTransform.replaceEquations(eqns_1, replc_1);
        seqns_1 = BackendVarTransform.replaceEquations(seqns, replc_1);
        ieqns_1 = BackendVarTransform.replaceEquations(ieqns, replc_1);
        arreqns1 = BackendVarTransform.replaceMultiDimEquations(arreqns, replc_1);
        eqns_3 = BackendVarTransform.replaceEquations(eqns_2, vartransf1);
        seqns_2 = BackendVarTransform.replaceEquations(seqns_1, vartransf1);
        ieqns_2 = BackendVarTransform.replaceEquations(ieqns_1, vartransf1);
        arreqns2 = BackendVarTransform.replaceMultiDimEquations(arreqns1, vartransf1);
        algs_1 = BackendVarTransform.replaceAlgorithms(algs,vartransf1);
        (vars_1,knvars_1) = moveVariables(vars, knvars, movedvars_1);
        inputsoutputs = Util.listMap1r(algs_1,lowerAlgorithmInputsOutputs,vars_1);
        eqns_3 = Util.listMap1(eqns_3,updateAlgorithmInputsOutputs,inputsoutputs);
        seqns_3 = listAppend(seqns_2, reqns) "& print_vars_statistics(vars\',knvars\')" ;
        // return aliasVars empty for now
        varsAliases = emptyAliasVariables();
      then
        (vars_1,knvars_1,eqns_3,seqns_3,ieqns_2,arreqns2, algs_1, varsAliases);
    case (_,_,_,_,_,_,_,_)
      equation
        print("-remove_simple_equations failed\n");
      then
        fail();
  end matchcontinue;
end removeSimpleEquations;

protected function removeSimpleEquations2
"Traverses all equations and puts those that are simple in
 a separate list. It builds a set of varable replacements that
 are later used to replace these variable substitutions in the
 equations that are left."
  input list<BackendDAE.Equation> eqns;
  input FuncTypeSimpleEquation funcSimpleEquation "function as argument so it can be distinguish between a=b/a=-b and a=const.";
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  input BackendDAE.BinTree mvars;
  input BackendDAE.BinTree states;
  input BackendDAE.BinTree outputs;
  input VarTransform.VariableReplacements repl;
  input list<DAE.ComponentRef> inExtendLst;
  input VarTransform.VariableReplacements replc;
  output list<BackendDAE.Equation> outEqns;
  output list<BackendDAE.Equation> outSimpleEqns;
  output BackendDAE.BinTree outMvars;
  output VarTransform.VariableReplacements outRepl;
  output list<DAE.ComponentRef> outExtendLst;
  output VarTransform.VariableReplacements outReplc;
  partial function FuncTypeSimpleEquation
    input BackendDAE.Equation eqn;
    input Boolean swap;
    output DAE.Exp e1;
    output DAE.Exp e2;
    output DAE.ElementSource source;
  end FuncTypeSimpleEquation;  
algorithm
  (outEqns,outSimpleEqns,outMvars,outRepl,outExtendLst,outReplc) := matchcontinue (eqns,funcSimpleEquation,vars,knvars,mvars,states,outputs,repl,inExtendLst,replc)
    local
      BackendDAE.BinTree mvars_1,mvars_2;
      VarTransform.VariableReplacements repl_1,repl_2,replc_1,replc_2;
      DAE.ComponentRef cr1,cr2;
      list<BackendDAE.Equation> eqns_1,seqns_1;
      BackendDAE.Equation e;
      DAE.ExpType t;
      DAE.Exp e1,e2;
      DAE.ElementSource source "the element source";
      list<DAE.ComponentRef> extlst,extlst1;
      
    case ({},funcSimpleEquation,vars,knvars,mvars,states,outputs,repl,extlst,replc) then ({},{},mvars,repl,extlst,replc);

    case (e::eqns,funcSimpleEquation,vars,knvars,mvars,states,outputs,repl,inExtendLst,replc) equation
      {e} = BackendVarTransform.replaceEquations({e},repl);
      {e} = BackendVarTransform.replaceEquations({e},replc);
      (e1 as DAE.CREF(cr1,t),e2,source) = funcSimpleEquation(e,false);
      failure(_ = treeGet(states, cr1)) "cr1 not state";
      isVariable(cr1, vars, knvars) "cr1 not constant";
      false = isTopLevelInputOrOutput(cr1,vars,knvars);
      failure(_ = treeGet(outputs, cr1)) "cr1 not output of algorithm";
      (extlst,replc_1) = removeSimpleEquations3(inExtendLst,replc,cr1,e2,t); 
      repl_1 = VarTransform.addReplacement(repl, cr1, e2);      
      mvars_1 = treeAdd(mvars, cr1, 0);
      (eqns_1,seqns_1,mvars_2,repl_2,extlst1,replc_2) = removeSimpleEquations2(eqns, funcSimpleEquation, vars, knvars, mvars_1, states, outputs, repl_1, extlst,replc_1);
    then
      (eqns_1,(BackendDAE.SOLVED_EQUATION(cr1,e2,source) :: seqns_1),mvars_2,repl_2,extlst1,replc_2);

      // Swapped args
    case (e::eqns,funcSimpleEquation,vars,knvars,mvars,states,outputs,repl,inExtendLst,replc) equation
      {e} = BackendVarTransform.replaceEquations({e},replc);
      {BackendDAE.EQUATION(e1,e2,source)} = BackendVarTransform.replaceEquations({e},repl);
      (e1 as DAE.CREF(cr1,t),e2,source) = simpleEquation(BackendDAE.EQUATION(e2,e1,source),true);
      failure(_ = treeGet(states, cr1)) "cr1 not state";
      isVariable(cr1, vars, knvars) "cr1 not constant";
      false = isTopLevelInputOrOutput(cr1,vars,knvars);
      failure(_ = treeGet(outputs, cr1)) "cr1 not output of algorithm";
      (extlst,replc_1) = removeSimpleEquations3(inExtendLst,replc,cr1,e2,t); 
      repl_1 = VarTransform.addReplacement(repl, cr1, e2);
      mvars_1 = treeAdd(mvars, cr1, 0);
      (eqns_1,seqns_1,mvars_2,repl_2,extlst1,replc_2) = removeSimpleEquations2(eqns, funcSimpleEquation, vars, knvars, mvars_1, states, outputs, repl_1, extlst,replc_1);
    then
      (eqns_1,(BackendDAE.SOLVED_EQUATION(cr1,e2,source) :: seqns_1),mvars_2,repl_2,extlst1,replc_2);

      // try next equation.
    case ((e :: eqns),funcSimpleEquation,vars,knvars,mvars,states,outputs,repl,extlst,replc)
      local BackendDAE.Equation eq1,eq2;
      equation
        {eq1} = BackendVarTransform.replaceEquations({e},repl);
        {eq2} = BackendVarTransform.replaceEquations({eq1},replc);
        //print("not removed simple ");print(equationStr(e));print("\n     -> ");print(equationStr(eq1));
        //print("\n\n");
        (eqns_1,seqns_1,mvars_1,repl_1,extlst1,replc_1) = removeSimpleEquations2(eqns, funcSimpleEquation, vars, knvars, mvars, states, outputs, repl, extlst,replc) "Not a simple variable, check rest" ;
      then
        ((e :: eqns_1),seqns_1,mvars_1,repl_1,extlst1,replc_1);
  end matchcontinue;
end removeSimpleEquations2;

protected function removeSimpleEquations3"
Author: Frenkel TUD 2010-07 function removeSimpleEquations3
  helper for removeSimpleEquations2
  if a element of a cref from typ array has to be replaced
  the array have to extend"
  input list<DAE.ComponentRef> increflst;
  input VarTransform.VariableReplacements inrepl;
  input DAE.ComponentRef cr;
  input DAE.Exp e;
  input DAE.ExpType t;
  output list<DAE.ComponentRef> outcreflst;
  output VarTransform.VariableReplacements outrepl;
algorithm
  (outcreflst,outrepl) := matchcontinue (increflst,inrepl,cr,e,t)
    local
      list<DAE.ComponentRef> crlst;
      VarTransform.VariableReplacements repl,repl_1;
      DAE.Exp e1;
      DAE.ComponentRef sc;
      DAE.ExpType ty;
     case (crlst,repl,cr,e,t)
      equation
        // is Array
        (_::_) = ComponentReference.crefLastSubs(cr);
        // check if e is not array
        false = Exp.isArray(e);
        // stripLastIdent
        sc = ComponentReference.crefStripLastSubs(cr);
        ty = ComponentReference.crefLastType(cr);
        // check List
        failure(_ = Util.listFindWithCompareFunc(crlst,sc,ComponentReference.crefEqualNoStringCompare,false));
        // extend cr
        (e1,_) = extendArrExp(DAE.CREF(sc,ty),NONE());
        // add
        repl_1 = VarTransform.addReplacement(repl, sc, e1);
      then
        (sc::crlst,repl_1);
    case (crlst,repl,_,_,_) then (crlst,repl);
  end matchcontinue;
end removeSimpleEquations3;

protected function getOutputsFromAlgorithms"
Author: Frenkel TUD 2010-09 function getOutputsFromAlgorithms
  helper for removeSimpleEquations
  collect all outpus from algorithms to avoid replacement
  of a algorithm output"
  input list<BackendDAE.Equation> inEqns;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inEqns,inBinTree)
    local
      list<BackendDAE.Equation> es;
      BackendDAE.Equation e;
      BackendDAE.BinTree bt,bt_1,bt_2;
      list<DAE.Exp> explst;
      list<DAE.ComponentRef> crefs;
    case ({},bt) then bt;
     case (BackendDAE.ALGORITHM(out=explst)::es,bt)
      equation
        crefs = Util.listFlatten(Util.listMap(explst,Exp.getCrefFromExp));
        bt_1 = treeAddList(bt,crefs);
        bt_2 = getOutputsFromAlgorithms(es,bt_1);  
      then bt_2;
    case (e::es,bt)
      equation
        bt_1 = getOutputsFromAlgorithms(es,bt);  
      then bt_1;
  end matchcontinue;
end getOutputsFromAlgorithms;

protected function updateAlgorithmInputsOutputs"
Author: Frenkel TUD 2010-09 function updateAlgorithmInputsOutputs
  helper for removeSimpleEquations
  update inputs and outputs of algorithms after remove simple equations"
  input BackendDAE.Equation inEqn;
  input list<tuple<list<DAE.Exp>,list<DAE.Exp>>> inAlgsInputsOutputs;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := matchcontinue (inEqn,inAlgsInputsOutputs)
    local
      BackendDAE.Equation e;
      list<tuple<list<DAE.Exp>,list<DAE.Exp>>> inputsoutputs;
      Integer index;
      list<DAE.Exp> inputs,outputs;
      DAE.ElementSource source;
     case (BackendDAE.ALGORITHM(index=index,source=source),inputsoutputs)
      equation
        true = listLength(inputsoutputs) > index;
        ((inputs,outputs)) = listNth(inputsoutputs,index);
      then BackendDAE.ALGORITHM(index,inputs,outputs,source);
    case (e,_) then e;
  end matchcontinue;
end updateAlgorithmInputsOutputs;

public function countSimpleEquations
"Counts the number of trivial/simple equations
 e.g on form a=b, a=-b or a=constant"
  input BackendDAE.EquationArray eqns;
  output Integer numEqns;
protected Integer elimLevel;
algorithm
 elimLevel := RTOpts.eliminationLevel();
 RTOpts.setEliminationLevel(2) "Full elimination";
 numEqns := countSimpleEquations2(equationList(eqns),0);
 RTOpts.setEliminationLevel(elimLevel);
end countSimpleEquations;

protected function countSimpleEquations2
  input list<BackendDAE.Equation> eqns;
  input Integer partialSum "to enable tail-recursion";
  output Integer numEqns;
algorithm
  numEqns := matchcontinue(eqns,partialSum)
  local BackendDAE.Equation e;
    case({},partialSum) then partialSum;

    case (e::eqns,partialSum) equation
        (_,_,_) = simpleEquation(e,false);
        partialSum = partialSum +1;
    then countSimpleEquations2(eqns,partialSum);

      // Swaped args in simpleEquation
    case (e::eqns,partialSum) equation
      (_,_,_) = simpleEquation(e,true);
      partialSum = partialSum +1;
    then countSimpleEquations2(eqns,partialSum);

      //Not simple eqn.
    case (e::eqns,partialSum)
    then countSimpleEquations2(eqns,partialSum);
  end matchcontinue;
end countSimpleEquations2;

protected function simpleEquation
"Returns the two sides of an equation as expressions if it is a
 simple equation. Simple equations are
 a+b=0, a-b=0, a=constant, a=-b, etc.
 The first expression returned, e1, is always a CREF.
 If the equation is not simple, this function will fail."
  input BackendDAE.Equation eqn;
  input Boolean swap "if true swap args.";
  output DAE.Exp e1;
  output DAE.Exp e2;
  output DAE.ElementSource source "the element source";
algorithm
  (e1,e2,source) := matchcontinue (eqn,swap)
      local
        DAE.Exp e;
        DAE.ExpType t;
        DAE.ElementSource src "the element source";
      // a = b;
      case (BackendDAE.EQUATION(e1 as DAE.CREF(componentRef = _),e2 as  DAE.CREF(componentRef = _),src),swap)
        equation
          true = RTOpts.eliminationLevel() > 0;
          true = RTOpts.eliminationLevel() <> 3;
        then (e1,e2,src);
        // a-b = 0
    case (BackendDAE.EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e1,e2,src);
    case (BackendDAE.EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e1,e2,src);        
      // a-b = 0 swap
    case (BackendDAE.EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e2,e1,src);
    case (BackendDAE.EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e2,e1,src);        
        // 0 = a-b
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e1,e2,src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e1,e2,src);
        // 0 = a-b  swap
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e2,e1,src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e2,e1,src);
        // a + b = 0
     case (BackendDAE.EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),e,src),false) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
      true = Exp.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS(t),e2),src);
     case (BackendDAE.EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),e,src),false) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
      true = Exp.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e2),src);
        // a + b = 0 swap
     case (BackendDAE.EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),e,src),true) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
       true = Exp.isZero(e);
     then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
     case (BackendDAE.EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),e,src),true) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
       true = Exp.isZero(e);
     then (e2,DAE.UNARY(DAE.UMINUS_ARR(t),e1),src);
      // 0 = a+b
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),src),false) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Exp.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS(t),e2),src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),src),false) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Exp.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e2),src);
      // 0 = a+b swap
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),src),true) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Exp.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),src),true) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Exp.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS_ARR(t),e1),src);
     // a = -b
    case (BackendDAE.EQUATION(e1 as DAE.CREF(_,_),e2 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);
    case (BackendDAE.EQUATION(e1 as DAE.CREF(_,_),e2 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);
      // -a = b => a = -b
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS(t),e1 as DAE.CREF(_,_)),e2 as DAE.CREF(_,_),src),swap)
      equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
    then (e1,DAE.UNARY(DAE.UMINUS(t),e2),src);
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS_ARR(t),e1 as DAE.CREF(_,_)),e2 as DAE.CREF(_,_),src),swap)
      equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
    then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e2),src);
      // -b - a = 0 => a = -b
    case (BackendDAE.EQUATION(DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e1,e2,src);
    case (BackendDAE.EQUATION(DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e1,e2,src);
      // -b - a = 0 => a = -b swap
    case (BackendDAE.EQUATION(DAE.BINARY(DAE.UNARY(DAE.UMINUS(t),e2 as DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
    case (BackendDAE.EQUATION(DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(t),e2 as DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
        // 0 = -b - a => a = -b
    case (BackendDAE.EQUATION(e,DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e1,e2,src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e1,e2,src);
        // 0 = -b - a => a = -b swap
    case (BackendDAE.EQUATION(e,DAE.BINARY(DAE.UNARY(DAE.UMINUS(t),e2 as DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
    case (BackendDAE.EQUATION(e,DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(t),e2 as DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS_ARR(t),e1),src);
        // -a = -b
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS(_),e1 as DAE.CREF(_,_)),DAE.UNARY(DAE.UMINUS(_),e2 as DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(_,_)),DAE.UNARY(DAE.UMINUS_ARR(_),e2 as DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);        
        // a = constant
    case (BackendDAE.EQUATION(e1 as DAE.CREF(_,_),e,src),swap) equation
      true = RTOpts.eliminationLevel() > 1;
      true = Exp.isConst(e);
      then (e1,e,src);

        // -a = constant
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS(t),e1 as DAE.CREF(_,_)),e,src),swap) equation
      true = RTOpts.eliminationLevel() > 1;
      true = Exp.isConst(e);
      then (e1,DAE.UNARY(DAE.UMINUS(t),e),src);
    case (BackendDAE.EQUATION(DAE.UNARY(DAE.UMINUS_ARR(t),e1 as DAE.CREF(_,_)),e,src),swap) equation
      true = RTOpts.eliminationLevel() > 1;
      true = Exp.isConst(e);
      then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e),src);
  end matchcontinue;
end simpleEquation;

protected function isTopLevelInputOrOutput
"function isTopLevelInputOrOutput
  author: LP

  This function checks if the provided cr is from a var that is on top model
  and is an input or an output, and returns true for such variables.
  It also returns true for input/output connector variables, i.e. variables
  instantiated from a  connector class, that are instantiated on the top level.
  The check for top-model is done by spliting the name at \'.\' and
  check if the list-length is 1.
  Note: The function needs the known variables to search for input variables
  on the top level.
  inputs:  (cref: DAE.ComponentRef,
              vars: Variables, /* BackendDAE.Variables */
              knownVars: BackendDAE.Variables /* Known BackendDAE.Variables */)
  outputs: bool"
  input DAE.ComponentRef inComponentRef1;
  input BackendDAE.Variables inVariables2;
  input BackendDAE.Variables inVariables3;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef1,inVariables2,inVariables3)
    local
      DAE.ComponentRef cr;
      BackendDAE.Variables vars,knvars;
    case (cr,vars,_)
      equation
        ((BackendDAE.VAR(varName = DAE.CREF_IDENT(ident = _), varDirection = DAE.OUTPUT()) :: _),_) = getVar(cr, vars);
      then
        true;
    case (cr,vars,knvars)
      equation
        ((BackendDAE.VAR(varDirection = DAE.INPUT()) :: _),_) = getVar(cr, knvars) "input variables stored in known variables are input on top level" ;
      then
        true;
    case (_,_,_) then false;
  end matchcontinue;
end isTopLevelInputOrOutput;

public function isVarOnTopLevelAndOutput
"function isVarOnTopLevelAndOutput
  this function checks if the provided cr is from a var that is on top model
  and has the DAE.VarDirection = OUTPUT
  The check for top-model is done by spliting the name at \'.\' and
  check if the list-length is 1"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local
      DAE.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.Flow flowPrefix;
    case (BackendDAE.VAR(varName = cr,varDirection = dir,flowPrefix = flowPrefix))
      equation
        topLevelOutput(cr, dir, flowPrefix);
      then
        true;
    case (_) then false;
  end matchcontinue;
end isVarOnTopLevelAndOutput;

public function isVarOnTopLevelAndInput
"function isVarOnTopLevelAndInput
  this function checks if the provided cr is from a var that is on top model
  and has the DAE.VarDirection = INPUT
  The check for top-model is done by spliting the name at \'.\' and
  check if the list-length is 1"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local
      DAE.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.Flow flowPrefix;
    case (BackendDAE.VAR(varName = cr,varDirection = dir,flowPrefix = flowPrefix))
      equation
        topLevelInput(cr, dir, flowPrefix);
      then
        true;
    case (_) then false;
  end matchcontinue;
end isVarOnTopLevelAndInput;

protected function typeofEquation
"function: typeofEquation
  Returns the DAE.ExpType of an equation"
  input BackendDAE.Equation inEquation;
  output DAE.ExpType outType;
algorithm
  outType:=
  matchcontinue (inEquation)
    local
      DAE.ExpType t;
      DAE.Exp e;
    case (BackendDAE.EQUATION(exp = e))
      equation
        t = Exp.typeof(e);
      then
        t;
    case (BackendDAE.COMPLEX_EQUATION(lhs = e))
      equation
        t = Exp.typeof(e);
      then
        t;
    case (BackendDAE.SOLVED_EQUATION(exp = e))
      equation
        t = Exp.typeof(e);
      then
        t;
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(right = e)))
      equation
        t = Exp.typeof(e);
      then
        t;
  end matchcontinue;
end typeofEquation;

protected function moveVariables
"function: moveVariables
  This function takes the two variable lists of a dae (states+alg) and
  known vars and moves a set of variables from the first to the second set.
  This function is needed to manage this in complexity O(n) by only
  traversing the set once for all variables.
  inputs:  (algAndState: Variables, /* alg+state */
              known: Variables,       /* known */
              binTree: BinTree)       /* vars to move from first7 to second */
  outputs:  (Variables,        /* updated alg+state vars */
               Variables)             /* updated known vars */
"
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables inVariables2;
  input BackendDAE.BinTree inBinTree3;
  output BackendDAE.Variables outVariables1;
  output BackendDAE.Variables outVariables2;
algorithm
  (outVariables1,outVariables2):=
  matchcontinue (inVariables1,inVariables2,inBinTree3)
    local
      list<BackendDAE.Var> lst1,lst2,lst1_1,lst2_1;
      BackendDAE.Variables v1,v2,vars,knvars,vars1,vars2;
      BackendDAE.BinTree mvars;
    case (vars1,vars2,mvars)
      equation
        lst1 = varList(vars1);
        lst2 = varList(vars2);
        (lst1_1,lst2_1) = moveVariables2(lst1, lst2, mvars);
        v1 = emptyVars();
        v2 = emptyVars();
        vars = addVars(lst1_1, v1);
        knvars = addVars(lst2_1, v2);
      then
        (vars,knvars);
  end matchcontinue;
end moveVariables;

protected function moveVariables2
"function: moveVariables2
  helper function to move_variables.
  inputs:  (Var list,  /* alg+state vars as list */
              BackendDAE.Var list,  /* known vars as list */
              BinTree)  /* move-variables as BackendDAE.BinTree */
  outputs: (Var list,  /* updated alg+state vars as list */
              BackendDAE.Var list)  /* update known vars as list */"
  input list<BackendDAE.Var> inVarLst1;
  input list<BackendDAE.Var> inVarLst2;
  input BackendDAE.BinTree inBinTree3;
  output list<BackendDAE.Var> outVarLst1;
  output list<BackendDAE.Var> outVarLst2;
algorithm
  (outVarLst1,outVarLst2):=
  matchcontinue (inVarLst1,inVarLst2,inBinTree3)
    local
      list<BackendDAE.Var> knvars,vs_1,knvars_1,vs;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      BackendDAE.BinTree mvars;
    case ({},knvars,_) then ({},knvars);
    case (((v as BackendDAE.VAR(varName = cr)) :: vs),knvars,mvars)
      equation
        _ = treeGet(mvars, cr) "alg var moved to known vars" ;
        (vs_1,knvars_1) = moveVariables2(vs, knvars, mvars);
      then
        (vs_1,(v :: knvars_1));
    case (((v as BackendDAE.VAR(varName = cr)) :: vs),knvars,mvars)
      equation
        failure(_ = treeGet(mvars, cr)) "alg var not moved to known vars" ;
        (vs_1,knvars_1) = moveVariables2(vs, knvars, mvars);
      then
        ((v :: vs_1),knvars_1);
  end matchcontinue;
end moveVariables2;

protected function isVariable
"function: isVariable

  This function takes a DAE.ComponentRef and two Variables. It searches
  the two sets of variables and succeed if the variable is STATE or
  VARIABLE. Otherwise it fails.
  Note: An array variable is currently assumed that each scalar element has
  the same type.
  inputs:  (DAE.ComponentRef,
              Variables, /* vars */
              Variables) /* known vars */
  outputs: ()"
  input DAE.ComponentRef inComponentRef1;
  input BackendDAE.Variables inVariables2;
  input BackendDAE.Variables inVariables3;
algorithm
  _:=
  matchcontinue (inComponentRef1,inVariables2,inVariables3)
    local
      DAE.ComponentRef cr;
      BackendDAE.Variables vars,knvars;
    case (cr,vars,_)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE()) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,vars,_)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.STATE()) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,vars,_)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE()) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,vars,_)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER()) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,_,knvars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE()) :: _),_) = getVar(cr, knvars);
      then
        ();
    case (cr,_,knvars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE()) :: _),_) = getVar(cr, knvars);
      then
        ();
    case (cr,_,knvars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER()) :: _),_) = getVar(cr, knvars);
      then
        ();
  end matchcontinue;
end isVariable;

protected function removeVariableNamed
"function: removeVariableNamed
  Removes a varaible from the BackendDAE.Variables set given a ComponentRef name.
  The removed variable is returned, such that is can be used elsewhere."
  input BackendDAE.Variables inVariables;
  input DAE.ComponentRef inComponentRef;
  output BackendDAE.Variables outVariables;
  output BackendDAE.Var outVar;
algorithm
  (outVariables,outVar):=
  matchcontinue (inVariables,inComponentRef)
    local
      String str;
      BackendDAE.Variables vars,vars_1;
      DAE.ComponentRef cr;
      list<BackendDAE.Var> vs;
      list<BackendDAE.Key> crefs;
      BackendDAE.Var var;
    case (vars,cr)
      equation
        failure((_,_) = getVar(cr, vars));
        print("-remove_variable_named failed. variable ");
        str = ComponentReference.printComponentRefStr(cr);
        print(str);
        print(" not found.\n");
      then
        fail();
    case (vars,cr)
      equation
        (vs,_) = getVar(cr, vars);
        crefs = Util.listMap(vs, varCref);
        vars_1 = Util.listFold(crefs, deleteVar, vars);
        var = Util.listFirst(vs) "NOTE: returns first var even if array variable" ;
      then
        (vars_1,var);
    case (_,_)
      equation
        print("-remove_variable_named failed\n");
      then
        fail();
  end matchcontinue;
end removeVariableNamed;

public function states
"function: states
  Returns a BackendDAE.BinTree of all states in the DAE.
  This function is used by the lower function."
  input list<DAE.Element> inElems;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree:=
  matchcontinue (inElems,inBinTree)
    local
      BackendDAE.BinTree bt;
      DAE.Exp e1,e2;
      list<DAE.Element> xs;
      DAE.DAElist dae;
      DAE.FunctionTree funcs;
      list<DAE.Element> daeElts;

    case ({},bt) then bt;

    case (DAE.EQUATION(exp = e1,scalar = e2) :: xs,bt)
      equation
        bt = states(xs, bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2) :: xs,bt)
      equation
        bt = states(xs, bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.INITIALEQUATION(exp1 = e1, exp2 = e2) :: xs,bt)
      equation
        bt = states(xs, bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.DEFINE(componentRef = _, exp = e2) :: xs,bt)
      equation
        bt = states(xs, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.INITIALDEFINE(componentRef = _, exp = e2) :: xs,bt)
      equation
        bt = states(xs, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.ARRAY_EQUATION(exp = e1,array = e2) :: xs,bt)
      equation
        bt = states(xs, bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.INITIAL_ARRAY_EQUATION(exp = e1, array = e2) :: xs, bt)
      equation
        bt = states(xs, bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.COMP(dAElist = daeElts) :: xs,bt)
      equation
        bt = states(daeElts, bt);
        bt = states(xs, bt);
      then
        bt;

    case (_ :: xs,bt)
      equation
        bt = states(xs, bt);
      then
        bt;
  end matchcontinue;
end states;

protected function statesDaelow
"function: statesDaelow
  author: PA
  Returns a BackendDAE.BinTree of all states in the DAELow
  This function is used in matching algorithm."
  input BackendDAE.DAELow inDAELow;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inDAELow)
    local
      list<BackendDAE.Var> v_lst;
      BackendDAE.BinTree bt;
      BackendDAE.Variables v,kn;
      BackendDAE.EquationArray e,re,ia;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ev;
    case (BackendDAE.DAELOW(orderedVars = v,knownVars = kn,orderedEqs = e,removedEqs = re,initialEqs = ia,arrayEqs = ae,algorithms = al,eventInfo = ev))
      equation
        v_lst = varList(v);
        bt = statesDaelow2(v_lst, BackendDAE.emptyBintree);
      then
        bt;
  end matchcontinue;
end statesDaelow;

protected function statesDaelow2
"function: statesDaelow2
  author: PA
  Helper function to statesDaelow."
  input list<BackendDAE.Var> inVarLst;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inVarLst,inBinTree)
    local
      BackendDAE.BinTree bt;
      DAE.ComponentRef cr;
      BackendDAE.Var v;
      list<BackendDAE.Var> vs;

    case ({},bt) then bt;

    case ((v :: vs),bt)
      equation
        BackendDAE.STATE() = varKind(v);
        cr = varCref(v);
        bt = treeAdd(bt, cr, 0);
        bt = statesDaelow2(vs, bt);
      then
        bt;
/*  is not realy a state
    case ((v :: vs),bt)
      equation
        BackendDAE.DUMMY_STATE() = varKind(v);
        cr = varCref(v);
        bt = treeAdd(bt, cr, 0);
        bt = statesDaelow2(vs, bt);
      then
        bt;
*/
    case ((v :: vs),bt)
      equation
        bt = statesDaelow2(vs, bt);
      then
        bt;
  end matchcontinue;
end statesDaelow2;

protected function statesExp
"function: statesExp
  Helper function to states."
  input DAE.Exp inExp;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inExp,inBinTree)
    local
      BackendDAE.BinTree bt;
      DAE.Exp e1,e2,e,e3;
      DAE.ComponentRef cr_1,cr;
      list<DAE.Exp> expl;
      list<list<tuple<DAE.Exp, Boolean>>> m;

    case (DAE.BINARY(exp1 = e1,exp2 = e2),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (DAE.UNARY(exp = e),bt)
      equation
        bt = statesExp(e, bt);
      then
        bt;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (DAE.LUNARY(exp = e),bt)
      equation
        bt = statesExp(e, bt);
      then
        bt;
    case (DAE.RELATION(exp1 = e1,exp2 = e2),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
        bt = statesExp(e3, bt);
      then
        bt;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),bt)
      equation
        //cr_1 = Exp.stringifyComponentRef(cr) "value irrelevant, give zero" ;
        bt = treeAdd(bt, cr, 0);
      then
        bt;
    case (DAE.CALL(expLst = expl),bt)
      equation
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case (DAE.ARRAY(array = expl),bt)
      equation
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case (DAE.MATRIX(scalar = m),bt)
      equation
        bt = statesExpMatrix(m, bt);
      then
        bt;
    case (DAE.TUPLE(PR = expl),bt)
      equation
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case (DAE.CAST(exp = e),bt)
      equation
        bt = statesExp(e, bt);
      then
        bt;
    case (DAE.ASUB(exp = e),bt)
      equation
        bt = statesExp(e, bt);
      then
        bt;
    case (DAE.REDUCTION(expr = e1,range = e2),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (_,bt) then bt;
  end matchcontinue;
end statesExp;

protected function statesExpMatrix
"function: statesExpMatrix
  author: PA
  Helper function to statesExp. Deals with matrix exp list."
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inTplExpExpBooleanLstLst,inBinTree)
    local
      list<list<DAE.Exp>> expl_1;
      list<DAE.Exp> expl_2;
      BackendDAE.BinTree bt;
      list<list<tuple<DAE.Exp, Boolean>>> expl;

    case (expl,bt)
      equation
        expl_1 = Util.listListMap(expl, Util.tuple21);
        expl_2 = Util.listFlatten(expl_1);
        bt = Util.listFold(expl_2, statesExp, bt);
      then
        bt;
    case (_,_)
      equation
        Debug.fprint("failtrace", "-states_exp_matrix failed\n");
      then
        fail();
  end matchcontinue;
end statesExpMatrix;

protected function lowerWhenEqn
"function lowerWhenEqn
  This function lowers a when clause. The condition expresion is put in the
  BackendDAE.WhenClause list and the equations inside are put in the equation list.
  For each equation in the clause a new entry in the BackendDAE.WhenClause list is generated
  and one extra for all the reinit statements.
  inputs:  (DAE.Element, int /* when-clause index */, BackendDAE.WhenClause list)
  outputs: (Equation list, BackendDAE.Variables, int /* when-clause index */, BackendDAE.WhenClause list)"
  input DAE.Element inElement;
  input Integer inWhenClauseIndex;
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  output list<BackendDAE.Equation> outEquationLst;
  output BackendDAE.Variables outVariables;
  output Integer outWhenClauseIndex;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
algorithm
  (outEquationLst,outVariables,outWhenClauseIndex,outWhenClauseLst):=
  matchcontinue (inElement,inWhenClauseIndex,inWhenClauseLst)
    local
      BackendDAE.Variables vars;
      BackendDAE.Variables elseVars;
      list<BackendDAE.Equation> res, res1;
      list<BackendDAE.Equation> trueEqnLst, elseEqnLst;
      list<BackendDAE.ReinitStatement> reinit;
      Integer equation_count,reinit_count,extra,tot_count,i_1,i,nextWhenIndex;
      Boolean hasReinit;
      list<BackendDAE.WhenClause> whenClauseList1,whenClauseList2,whenClauseList3,whenClauseList4,whenList,elseClauseList;
      DAE.Exp cond;
      list<DAE.Element> eqnl;
      DAE.Element elsePart;

    case (DAE.WHEN_EQUATION(condition = cond,equations = eqnl,elsewhen_ = NONE()),i,whenList)
      equation
        vars = emptyVars();
        (res,reinit) = lowerWhenEqn2(eqnl, i);
        equation_count = listLength(res);
        reinit_count = listLength(reinit);
        hasReinit = (reinit_count > 0);
        extra = Util.if_(hasReinit, 1, 0);
        tot_count = equation_count + extra;
        i_1 = i + tot_count;
        whenClauseList1 = makeWhenClauses(equation_count, cond, {});
        whenClauseList2 = makeWhenClauses(extra, cond, reinit);
        whenClauseList3 = listAppend(whenClauseList2, whenClauseList1);
        whenClauseList4 = listAppend(whenClauseList3, whenList);
      then
        (res,vars,i_1,whenClauseList4);

    case (DAE.WHEN_EQUATION(condition = cond,equations = eqnl,elsewhen_ = SOME(elsePart)),i,whenList)
      equation
        vars = emptyVars();
        (elseEqnLst,_,nextWhenIndex,elseClauseList) = lowerWhenEqn(elsePart,i,whenList);
        (trueEqnLst,reinit) = lowerWhenEqn2(eqnl, nextWhenIndex);
        equation_count = listLength(trueEqnLst);
        reinit_count = listLength(reinit);
        hasReinit = (reinit_count > 0);
        extra = Util.if_(hasReinit, 1, 0);
        tot_count = equation_count + extra;
        whenClauseList1 = makeWhenClauses(equation_count, cond, {});
        whenClauseList2 = makeWhenClauses(extra, cond, reinit);
        whenClauseList3 = listAppend(whenClauseList2, whenClauseList1);
        (res1,i_1,whenClauseList4) = mergeClauses(trueEqnLst,elseEqnLst,whenClauseList3,
          elseClauseList,nextWhenIndex + tot_count);
      then
        (res1,vars,i_1,whenClauseList4);

    case (DAE.WHEN_EQUATION(condition = cond),_,_)
      local String scond;
      equation
        scond = Exp.printExpStr(cond);
        print("- DAELow.lowerWhenEqn: Error in lowerWhenEqn. \n when ");
        print(scond);
        print(" ... \n");
      then fail();
  end matchcontinue;
end lowerWhenEqn;

protected function mergeClauses
"function mergeClauses
   merges the true part end the elsewhen part of a set of when equations.
   For each equation in trueEqnList, find an equation in elseEqnList solving
   the same variable and put it in the else elseWhenPart of the first equation."
  input list<BackendDAE.Equation> trueEqnList "List of equations in the true part of the when clause.";
  input list<BackendDAE.Equation> elseEqnList "List of equations in the elsewhen part of the when clause.";
  input list<BackendDAE.WhenClause> trueClauses "List of when clauses from the true part.";
  input list<BackendDAE.WhenClause> elseClauses "List of when clauses from the elsewhen part.";
  input Integer nextWhenClauseIndex  "Next available when clause index.";
  output list<BackendDAE.Equation> outEquationLst;
  output Integer outWhenClauseIndex;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
algorithm
  (outEquationLst,outWhenClauseIndex,outWhenClauseLst) :=
  matchcontinue (trueEqnList, elseEqnList, trueClauses, elseClauses, nextWhenClauseIndex)
    local
      DAE.ComponentRef cr;
      DAE.Exp rightSide;
      Integer ind;
      BackendDAE.Equation res;
      list<BackendDAE.Equation> trueEqns;
      list<BackendDAE.Equation> elseEqns;
      list<BackendDAE.WhenClause> trueCls;
      list<BackendDAE.WhenClause> elseCls;
      Integer nextInd;
      list<BackendDAE.Equation> resRest;
      Integer outNextIndex;
      list<BackendDAE.WhenClause> outClauseList;
      BackendDAE.WhenEquation foundEquation;
      list<BackendDAE.Equation> elseEqnsRest;
      DAE.ElementSource source "the element source";

    case (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(index = ind,left = cr,right=rightSide),source)::trueEqns, elseEqns,trueCls,elseCls,nextInd)
      equation
        (foundEquation, elseEqnsRest) = getWhenEquationFromVariable(cr,elseEqns);
        res = BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(ind,cr,rightSide,SOME(foundEquation)),source);
        (resRest, outNextIndex, outClauseList) = mergeClauses(trueEqns,elseEqnsRest,trueCls, elseCls,nextInd);
      then (res::resRest, outNextIndex, outClauseList);

    case ({},{},trueCls,elseCls,nextInd) then ({},nextInd,listAppend(trueCls,elseCls));

    case (_,_,_,_,_)
      equation
        print("- DAELow.mergeClauses: Error in mergeClauses.\n");
      then fail();
  end matchcontinue;
end mergeClauses;

protected function getWhenEquationFromVariable
"Finds the when equation solving the variable given by inCr among equations in inEquations
 the found equation is then taken out of the list."
  input DAE.ComponentRef inCr;
  input list<BackendDAE.Equation> inEquations;
  output BackendDAE.WhenEquation outEquation;
  output list<BackendDAE.Equation> outEquations;
algorithm
  (outEquation, outEquations) := matchcontinue(inCr,inEquations)
    local
      DAE.ComponentRef cr1,cr2;
      BackendDAE.WhenEquation eq;
      BackendDAE.Equation eq2;
      list<BackendDAE.Equation> rest, rest2;

    case (cr1,BackendDAE.WHEN_EQUATION(eq as BackendDAE.WHEN_EQ(left=cr2),_)::rest)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr1,cr2);
      then (eq, rest);

    case (cr1,(eq2 as BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(left=cr2),_))::rest)
      equation
        false = ComponentReference.crefEqualNoStringCompare(cr1,cr2);
        (eq,rest2) = getWhenEquationFromVariable(cr1,rest);
      then (eq, eq2::rest2);

    case (_,{})
      equation
        Error.addMessage(Error.DIFFERENT_VARIABLES_SOLVED_IN_ELSEWHEN, {});
      then
        fail();
  end matchcontinue;
end getWhenEquationFromVariable;

protected function makeWhenClauses
"function: makeWhenClauses
  Constructs a list of identical BackendDAE.WhenClause elements
  Arg1: Number of elements to construct
  Arg2: condition expression of the when clause
  outputs: (WhenClause list)"
  input Integer n           "Number of copies to make.";
  input DAE.Exp inCondition "the condition expression";
  input list<BackendDAE.ReinitStatement> inReinitStatementLst;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
algorithm
  outWhenClauseLst:=
  matchcontinue (n,inCondition,inReinitStatementLst)
    local
      BackendDAE.Value i_1,i;
      list<BackendDAE.WhenClause> res;
      DAE.Exp cond;
      list<BackendDAE.ReinitStatement> reinit;

    case (0,_,_) then {};
    case (i,cond,reinit)
      equation
        i_1 = i - 1;
        res = makeWhenClauses(i_1, cond, reinit);
      then
        (BackendDAE.WHEN_CLAUSE(cond,reinit,NONE()) :: res);
  end matchcontinue;
end makeWhenClauses;

protected function lowerWhenEqn2
"function lowerWhenEqn2
  Helper function to lowerWhenEqn. Lowers the equations inside a when clause"
  input list<DAE.Element> inDAEElementLst "The List of equations inside a when clause";
  input Integer inWhenClauseIndex;
  output list<BackendDAE.Equation> outEquationLst;
  output list<BackendDAE.ReinitStatement> outReinitStatementLst;
algorithm
  (outEquationLst,outReinitStatementLst):=
  matchcontinue (inDAEElementLst,inWhenClauseIndex)
    local
      BackendDAE.Value i;
      list<BackendDAE.Equation> eqnl;
      list<BackendDAE.ReinitStatement> reinit;
      DAE.Exp e_2,cre,e;
      DAE.ComponentRef cr_1,cr;
      list<DAE.Element> xs;
      DAE.Element el;
      DAE.ElementSource source "the element source";

    case ({},_) then ({},{});
    case ((DAE.EQUATION(exp = (cre as DAE.CREF(componentRef = cr)),scalar = e, source = source) :: xs),i)
      equation
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1);
      then
        ((BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e,NONE()),source) :: eqnl),reinit);

    case ((DAE.COMPLEX_EQUATION(lhs = (cre as DAE.CREF(componentRef = cr)),rhs = e,source = source) :: xs),i)
      equation
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1);
      then
        ((BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e,NONE()),source) :: eqnl),reinit);

    case ((DAE.REINIT(componentRef = cr,exp = e,source = source) :: xs),i)
      equation
        (eqnl,reinit) = lowerWhenEqn2(xs, i);
      then
        (eqnl,(BackendDAE.REINIT(cr,e,source) :: reinit));

    case ((DAE.TERMINATE(message = e,source = source) :: xs),i)
      local DAE.ComponentRef cref_;
      equation
        (eqnl,reinit) = lowerWhenEqn2(xs, i);
        e_2 = Exp.simplify(e); // Exp.stringifyCrefs(Exp.simplify(e));
        cref_ = ComponentReference.makeCrefIdent("_", DAE.ET_OTHER(), {});
      then
        ((BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cref_,e_2,NONE()),source) :: eqnl),reinit);
    
    case ((DAE.ARRAY_EQUATION(exp = (cre as DAE.CREF(componentRef = cr)),array = e,source = source) :: xs),i)
      equation
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1);
      then
        ((BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e,NONE()),source) :: eqnl),reinit);    
    
    // failure  
    case ((el::xs), i)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- DAELow.lowerWhenEqn2 failed on:" +& DAEDump.dumpElementsStr({el}));
      then 
        fail();
    
    // adrpo: 2010-09-26
    // allow to continue when checking the model
    // just ignore this equation.
    case ((el::xs), i)
      equation
        true = OptManager.getOption("checkModel");
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1);
      then
        (eqnl, reinit);
  end matchcontinue;
end lowerWhenEqn2;
        
protected function isStateOrAlgvar
  "@author adrpo
   check if this variable is a state or algebraic"
  input DAE.Element e;
  output Boolean out;
algorithm
  out := matchcontinue(e)
    case (DAE.VAR(kind = DAE.VARIABLE())) then true;
    case (DAE.VAR(kind = DAE.DISCRETE())) then true;
    case (_) then false;
  end matchcontinue;
end isStateOrAlgvar;

protected function lower2
"function: lower2
  Helper function to lower.
  inputs:  (DAE.DAElist,BinTree /* states */,BackendDAE.Variables,BackendDAE.Variables,BackendDAE.Variables,WhenClause list)
  outputs: (Variables,BackendDAE.Variables,BackendDAE.Variables,Equation list,Equation list,Equation list,MultiDimEquation list,DAE.Algorithm list,WhenClause list)"
  input list<DAE.Element> inElements;
  input DAE.FunctionTree functionTree;
  input BackendDAE.BinTree inStatesBinTree;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables inKnownVariables;
  input BackendDAE.Variables inExternalVariables;
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  output BackendDAE.Variables outVariables;
  output BackendDAE.Variables outKnownVariables;
  output BackendDAE.Variables outExternalVariables;
  output list<BackendDAE.Equation> outEquationLst3;
  output list<BackendDAE.Equation> outEquationLst4;
  output list<BackendDAE.Equation> outEquationLst5;
  output list<BackendDAE.MultiDimEquation> outMultiDimEquationLst6;
  output list<BackendDAE.MultiDimEquation> outMultiDimEquationLst7;
  output list<DAE.Algorithm> outAlgorithmAlgorithmLst8;
  output list<BackendDAE.WhenClause> outWhenClauseLst9;
  output BackendDAE.ExternalObjectClasses outExtObjClasses;
  output BackendDAE.BinTree outStatesBinTree;
algorithm
  (outVariables,outKnownVariables,outExternalVariables,outEquationLst3,outEquationLst4,outEquationLst5,
   outMultiDimEquationLst6,outMultiDimEquationLst7,outAlgorithmAlgorithmLst8,outWhenClauseLst9,outExtObjClasses,outStatesBinTree):=
   matchcontinue (inElements,functionTree,inStatesBinTree,inVariables,inKnownVariables,inExternalVariables,inWhenClauseLst)
    local
      BackendDAE.Variables v1,v2,v3,vars,knvars,extVars,extVars1,extVars2,vars_1,knvars_1,vars1,vars2,knvars1,knvars2,kv;
      list<BackendDAE.WhenClause> whenclauses,whenclauses_1,whenclauses_2;
      list<BackendDAE.Equation> eqns,reqns,ieqns,eqns1,eqns2,reqns1,ieqns1,reqns2,ieqns2,re,ie,eqsComplex;
      list<BackendDAE.MultiDimEquation> aeqns,aeqns1,aeqns2,ae,iaeqns,iaeqns1,iaeqns2,iae;
      list<DAE.Algorithm> algs,algs1,algs2,al;
      BackendDAE.ExternalObjectClasses extObjCls,extObjCls1,extObjCls2;
      BackendDAE.ExternalObjectClass extObjCl;
      BackendDAE.Var v_1,v_2;
      DAE.Element v,e;
      list<DAE.Element> xs;
      BackendDAE.BinTree states;
      BackendDAE.Equation e_1, e_2;
      DAE.Exp e1,e2,c;
      list<BackendDAE.Value> ds;
      BackendDAE.Value count,count_1;
      DAE.Algorithm a,a1,a2;
      DAE.DAElist dae;
      DAE.ExpType ty;
      DAE.ComponentRef cr;
      Absyn.InnerOuter io;
      DAE.ElementSource source "the element source";
      DAE.FunctionTree funcs;
      list<DAE.Element> daeElts;
      Absyn.Info info;
    
    // the empty case 
    case ({},functionTree,states,v1,v2,v3,whenclauses)
      then
        (v1,v2,v3,{},{},{},{},{},{},whenclauses,{},states);

    // adrpo: should we ignore OUTER vars?!
    //case (((v as DAE.VAR(innerOuter=io)) :: xs),states,vars,knvars,extVars,whenclauses)
    //  equation
    //    DAEUtil.isOuterVar(v);
    //    (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls) =
    //    lower2(xs, states, vars, knvars, extVars, whenclauses);
    //  then
    //    (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls);
    
    // external object variables
    case ((v as DAE.VAR(componentRef = _)) :: xs,functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states) =
        lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        v_1 = lowerExtObjVar(v);
        SOME(v_2) = Inline.inlineVarOpt(SOME(v_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
        extVars2 = addVar(v_2, extVars);
      then
        (vars,knvars,extVars2,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);

    // class for external object
    case (((v as DAE.EXTOBJECTCLASS(path,constr,destr,source)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local
        Absyn.Path path;
        DAE.Function constr,destr;
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        {extObjCl} = Inline.inlineExtObjClasses({BackendDAE.EXTOBJCLASS(path,constr,destr,source)},(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,
        extObjCl::extObjCls,states);
    
    // variables: states and algebraic variables with binding equation
    case (((v as DAE.VAR(componentRef = cr, source = source)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states) =
        lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        // adrpo 2009-09-07 - according to MathCore
        // add the binding as an equation and remove the binding from variable!
        true = isStateOrAlgvar(v);
        (v_1,SOME(e1),states) = lowerVar(v, states);
        SOME(v_2) = Inline.inlineVarOpt(SOME(v_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
        e2 = Inline.inlineExp(e1,(SOME(functionTree),{DAE.NORM_INLINE()}));
        vars_1 = addVar(v_2, vars);
      then
        (vars_1,knvars,extVars,BackendDAE.EQUATION(DAE.CREF(cr, DAE.ET_OTHER()), e2, source)::eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // variables: states and algebraic variables with NO binding equation
    case (((v as DAE.VAR(componentRef = cr, source = source)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states) =
        lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        true = isStateOrAlgvar(v);
        (v_1,NONE(),states) = lowerVar(v, states);
        SOME(v_2) = Inline.inlineVarOpt(SOME(v_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
        vars_1 = addVar(v_2, vars);
      then
        (vars_1,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // known variables: parameters and constants
    case (((v as DAE.VAR(componentRef = _)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        v_1 = lowerKnownVar(v) "in previous rule, lower_var failed." ;
        SOME(v_2) = Inline.inlineVarOpt(SOME(v_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
        knvars_1 = addVar(v_2, knvars);
      then
        (vars,knvars_1,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // tuple equations are rewritten to algorihm tuple assign.
    case (((e as DAE.EQUATION(exp = e1,scalar = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        a = lowerTupleEquation(e);
        a1 = Inline.inlineAlgorithm(a,(SOME(functionTree),{DAE.NORM_INLINE()}));
        a2 = extendAlgorithm(a1,SOME(functionTree));
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
          = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,a2::algs,whenclauses_1,extObjCls,states);
    
    // tuple-tuple assignments are split into one equation for each tuple
    // element, i.e. (i1, i2) = (4, 6) => i1 = 4; i2 = 6; 
    case ((DAE.EQUATION(DAE.TUPLE(targets), DAE.TUPLE(sources), source = eq_source) :: xs),
        functionTree,states,vars,knvars,extVars,whenclauses)
      local
        list<DAE.Exp> targets;
        list<DAE.Exp> sources;
        DAE.ElementSource eq_source;
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
          = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        eqns2 = lowerTupleAssignment(targets, sources, eq_source, functionTree);
        eqns = listAppend(eqns2, eqns);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // scalar equations
    case (((e as DAE.EQUATION(exp = e1,scalar = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        e_1 = lowerEqn(e);
        SOME(e_2) = Inline.inlineEqOpt(SOME(e_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,(e_2 :: eqns),reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // effort variable equality equations
    case (((e as DAE.EQUEQUATION(cr1 = _)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        e_1 = lowerEqn(e);
        SOME(e_2) = Inline.inlineEqOpt(SOME(e_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,(e_2 :: eqns),reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // a solved equation 
    case (((e as DAE.DEFINE(componentRef = _)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        e_1 = lowerEqn(e);
        SOME(e_2) = Inline.inlineEqOpt(SOME(e_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,e_2 :: eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // complex equations
    case (((e as DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        (eqsComplex,aeqns1) = lowerComplexEqn(e, functionTree);
        eqns = listAppend(eqsComplex, eqns);
        aeqns2 = listAppend(aeqns, aeqns1);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns2,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // complex initial equations
    case (((e as DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        (eqsComplex,iaeqns1) = lowerComplexEqn(e, functionTree);
        ieqns = listAppend(eqsComplex, ieqns);
        iaeqns2 = listAppend(iaeqns, iaeqns1);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns2,algs,whenclauses_1,extObjCls,states);
    
    // array equations
    case (((e as DAE.ARRAY_EQUATION(dimension = ds,exp = e1,array = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local 
        DAE.Exp e_11,e_21;
        list<DAE.Exp> ea1,ea2;
        list<tuple<DAE.Exp,DAE.Exp>> ealst;
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        BackendDAE.MULTIDIM_EQUATION(left=e_11 as DAE.ARRAY(scalar=true,array=ea1),
                          right=e_21 as DAE.ARRAY(scalar=true,array=ea2),source=source)
          = lowerArrEqn(e,functionTree);
        ealst = Util.listThreadTuple(ea1,ea2);
        re = Util.listMap1(ealst,generateEQUATION,source);
        eqns = listAppend(re, eqns);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // array equations
    case (((e as DAE.ARRAY_EQUATION(dimension = ds,exp = e1,array = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local 
        BackendDAE.MultiDimEquation e_1;
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        e_1 = lowerArrEqn(e,functionTree);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,(e_1 :: aeqns),iaeqns,algs,whenclauses_1,extObjCls,states);
        
    // initial array equations 
    case (((e as DAE.INITIAL_ARRAY_EQUATION(dimension = ds,exp = e1,array = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local 
        DAE.Exp e_11,e_21;
        list<DAE.Exp> ea1,ea2;
        list<tuple<DAE.Exp,DAE.Exp>> ealst;
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        BackendDAE.MULTIDIM_EQUATION(left=e_11 as DAE.ARRAY(scalar=true,array=ea1),
                          right=e_21 as DAE.ARRAY(scalar=true,array=ea2),source=source)
          = lowerArrEqn(e,functionTree);
        ealst = Util.listThreadTuple(ea1,ea2);
        re = Util.listMap1(ealst,generateEQUATION,source);
        ieqns = listAppend(re, ieqns);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);    
    
    // initial array equations
    case (((e as DAE.INITIAL_ARRAY_EQUATION(dimension = ds, exp = e1, array = e2)) :: xs), 
        functionTree, states, vars, knvars, extVars, whenclauses)
      local 
        BackendDAE.MultiDimEquation e_1;
      equation
        (vars, knvars, extVars, eqns, reqns, ieqns, aeqns,iaeqns, algs, whenclauses_1, extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        e_1 = lowerArrEqn(e,functionTree);
      then
        (vars, knvars, extVars, eqns, reqns, ieqns, aeqns,(e_1 :: iaeqns), algs, whenclauses_1, extObjCls,states);
    
    // when equations
    case (((e as DAE.WHEN_EQUATION(condition = c,equations = eqns)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local list<Option<BackendDAE.Equation>> opteqlst;
      equation
        (vars1,knvars,extVars,eqns1,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        count = listLength(whenclauses_1);
        (eqns2,vars2,count_1,whenclauses_2) = lowerWhenEqn(e, count, whenclauses_1);
        vars = mergeVars(vars1, vars2);
        opteqlst = Util.listMap(eqns2,Util.makeOption);
        opteqlst = Util.listMap1(opteqlst,Inline.inlineEqOpt,(SOME(functionTree),{DAE.NORM_INLINE()}));
        eqns2 = Util.listMap(opteqlst,Util.getOption);
        eqns = listAppend(eqns1, eqns2);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_2,extObjCls,states);
    
    // initial equations
    case (((e as DAE.INITIALEQUATION(exp1 = e1,exp2 = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        e_1 = lowerEqn(e);
        SOME(e_2) = Inline.inlineEqOpt(SOME(e_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,eqns,reqns,(e_2 :: ieqns),aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // algorithm
    case ((DAE.ALGORITHM(algorithm_ = a) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
       a1 = Inline.inlineAlgorithm(a,(SOME(functionTree),{DAE.NORM_INLINE()})); 
       a2 = extendAlgorithm(a1,SOME(functionTree));
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,(a2 :: algs),whenclauses_1,extObjCls,states);
    
    // flat class / COMP
    case ((DAE.COMP(dAElist = daeElts) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars1,knvars1,extVars1,eqns1,reqns1,ieqns1,aeqns1,iaeqns1,algs1,whenclauses_1,extObjCls1,states) = lower2(daeElts, functionTree, states, vars, knvars, extVars, whenclauses);
        (vars2,knvars2,extVars2,eqns2,reqns2,ieqns2,aeqns2,iaeqns2,algs2,whenclauses_2,extObjCls2,states) = lower2(xs, functionTree, states, vars1, knvars1, extVars1, whenclauses_1);
        vars = vars2; // vars = mergeVars(vars1, vars2);
        knvars = knvars2; // knvars = mergeVars(knvars1, knvars2);
        extVars = extVars2; // extVars = mergeVars(extVars1,extVars2);
        eqns = listAppend(eqns1, eqns2);
        ieqns = listAppend(ieqns1, ieqns2);
        reqns = listAppend(reqns1, reqns2);
        aeqns = listAppend(aeqns1, aeqns2);
        iaeqns = listAppend(iaeqns1, iaeqns2);
        algs = listAppend(algs1, algs2);
        extObjCls = listAppend(extObjCls1,extObjCls2);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_2,extObjCls,states);
    
    // assert in equation section is converted to ALGORITHM
    case ((DAE.ASSERT(cond,msg,source) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local
        BackendDAE.Variables v;
        list<BackendDAE.Equation> e;
        DAE.Exp cond,msg;
        DAE.Algorithm alg;
      equation
        checkAssertCondition(cond,msg);
        (v,kv,extVars,e,re,ie,ae,iae,al,whenclauses_1,extObjCls,states) = lower2(xs,functionTree,states,vars,knvars,extVars,whenclauses);
        a = Inline.inlineAlgorithm(DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond,msg,source)}),(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (v,kv,extVars,e,re,ie,ae,iae,a::al,whenclauses_1,extObjCls,states);
    
    // terminate in equation section is converted to ALGORITHM
    case ((DAE.TERMINATE(message = msg, source = source) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local
        BackendDAE.Variables v;
        list<BackendDAE.Equation> e;
        DAE.Exp cond,msg;
      equation
        (v,kv,extVars,e,re,ie,ae,iae,al,whenclauses_1,extObjCls,states) = lower2(xs, functionTree, states, vars,knvars,extVars, whenclauses) ;
        a = Inline.inlineAlgorithm(DAE.ALGORITHM_STMTS({DAE.STMT_TERMINATE(msg,source)}),(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (v,kv,extVars,e,re,ie,ae,iae,a::al,whenclauses_1,extObjCls,states);
    
    case ((DAE.NORETCALL(functionName = func_name, functionArgs = args, source = source) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local
        Absyn.Path func_name;
        list<DAE.Exp> args;
        DAE.Statement s;
        Boolean b1, b2, b;
      equation
        // make sure is not constrain as we don't support it, see below.
        b1 = boolNot(Util.isEqual(func_name, Absyn.IDENT("constrain")));
        // constrain is fine when we do check model!
        b2 = OptManager.getOption("checkModel");
        true = boolOr(b1, b2);
        
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses_1,extObjCls,states) = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        s = DAE.STMT_NORETCALL(DAE.CALL(func_name, args, false, false, DAE.ET_NORETCALL(), DAE.NORM_INLINE()),source);
        a = Inline.inlineAlgorithm(DAE.ALGORITHM_STMTS({s}),(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (vars,kv,extVars,eqns,re,ie,ae,iae,a :: al,whenclauses_1,extObjCls,states);

    // when running checkModel ignore some of the unsupported features as we only want to see nr eqs/vars
    // if equation that cannot be translated to if expression but have initial() as condition
    case (((e as DAE.IF_EQUATION(condition1 = {DAE.CALL(path=Absyn.IDENT("initial"))}, source = DAE.SOURCE(info = info))) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        true = OptManager.getOption("checkModel");
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses,extObjCls,states) = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);        
      then
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses,extObjCls,states);
    
    // when running checkModel ignore some of the unsupported features as we only want to see nr eqs/vars
    // initial if equation that cannot be translated to if expression 
    case (((e as DAE.INITIAL_IF_EQUATION(condition1 = _, source = DAE.SOURCE(info = info))) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        true = OptManager.getOption("checkModel");
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses,extObjCls,states) = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);        
      then
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses,extObjCls,states);
    
    // when running checkModel ignore some of the unsupported features as we only want to see nr eqs/vars
    // initial algorithm
    case (((e as DAE.INITIALALGORITHM(algorithm_ = _, source = DAE.SOURCE(info=info))) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        true = OptManager.getOption("checkModel");
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses,extObjCls,states) = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
      then
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses,extObjCls,states);

    // error reporting from now on
     
    // if equation that cannot be translated to if expression
    case ((e as DAE.IF_EQUATION(condition1 = _, source = DAE.SOURCE(info = info))) :: xs,functionTree,states,vars,knvars,extVars,whenclauses)
      local String str;
      equation
        str = DAEDump.dumpElementsStr({e});
        str = stringAppend("rewrite equations using if-expressions: ",str);
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"if-equations",str}, info);
      then
        fail();
    
    // initial if equation that cannot be translated to if expression 
    case ((e as DAE.INITIAL_IF_EQUATION(condition1 = _, source = DAE.SOURCE(info = info))) :: xs,functionTree,states,vars,knvars,extVars,whenclauses)
      local String str;
      equation
        str = DAEDump.dumpElementsStr({e});
        str = stringAppend("rewrite equations using if-expressions: ",str);
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"if-equations",str}, info);
      then
        fail();
    
    // initial algorithm
    case (((e as DAE.INITIALALGORITHM(algorithm_ = _, source = DAE.SOURCE(info=info))) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local String str;
      equation
        str = DAEDump.dumpElementsStr({e});
        str = stringAppend("rewrite initial algorithms to initial equations",str);        
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,{"initial algorithm",str}, info);
      then
        fail();
      
    // constrain is not a standard Modelica function, but used in old libraries such as the old Multibody library.
    // The OpenModelica backend does not support constrain, but the frontend does (Mathcore needs it for their backend).
    // To get a meaningful error message when constrain is used we catch it here, instead of silently failing. 
    // User-defined functions should have fully qualified names here, so Absyn.IDENT should only match the builtin constrain function.        
    case (((e as DAE.NORETCALL(functionName = Absyn.IDENT(name = "constrain"), source = DAE.SOURCE(info=info))) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local String str;
      equation
        str = DAEDump.dumpElementsStr({e});
        str = stringAppend("rewrite code without using constrain",str);        
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,{"constrain function",str}, info);
      then
        fail();
        
    case (ddl::xs,functionTree,_,vars,knvars,extVars,_)
      local DAE.Element ddl; String s3;
      equation
        // show only on failtrace!
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- DAELow.lower2 failed on: " +& DAEDump.dumpElementsStr({ddl}));
      then
        fail();
  end matchcontinue;
end lower2;

protected function checkAssertCondition "Succeds if condition of assert is not constant false"
  input DAE.Exp cond;
  input DAE.Exp message;
algorithm
  _ := matchcontinue(cond,message)
    case(_, _)
      equation
        // Don't check assertions when checking models
        true = OptManager.getOption("checkModel");
      then ();
    case(cond,message) equation
      false = Exp.isConstFalse(cond);
      then ();
    case(cond,message)
      local String messageStr;
      equation
        true = Exp.isConstFalse(cond);
        messageStr = Exp.printExpStr(message);
        Error.addMessage(Error.ASSERT_CONSTANT_FALSE_ERROR,{messageStr});
      then fail();
  end matchcontinue;
end checkAssertCondition;

protected function lowerTupleAssignment
  "Used by lower2 to split a tuple-tuple assignment into one equation for each
  tuple-element"
  input list<DAE.Exp> target_expl;
  input list<DAE.Exp> source_expl;
  input DAE.ElementSource eq_source;
  input DAE.FunctionTree funcs;
  output list<BackendDAE.Equation> eqns;
algorithm
  eqns := matchcontinue(target_expl, source_expl, eq_source,funcs)
    local
      DAE.Exp target, source;
      list<DAE.Exp> rest_targets, rest_sources;
      DAE.Element e;
      BackendDAE.Equation eq,eq1;
      list<BackendDAE.Equation> new_eqns;
    case ({}, {}, _, funcs) then {};
    case (target :: rest_targets, source :: rest_sources, _, funcs)
      equation
        new_eqns = lowerTupleAssignment(rest_targets, rest_sources, eq_source, funcs);
        e = DAE.EQUATION(target, source, eq_source);
        eq = lowerEqn(e);
        SOME(eq1) = Inline.inlineEqOpt(SOME(eq),(SOME(funcs),{DAE.NORM_INLINE()}));
      then eq :: new_eqns;
  end matchcontinue;
end lowerTupleAssignment;


protected function lowerTupleEquation
"Lowers a tuple equation, e.g. (a,b) = foo(x,y)
 by transforming it to an algorithm (TUPLE_ASSIGN), e.g. (a,b) := foo(x,y);
 author: PA"
  input DAE.Element eqn;
  output DAE.Algorithm alg;
algorithm
  alg := matchcontinue(eqn)
    local
      DAE.ElementSource source;
      DAE.Exp e1,e2;
      list<DAE.Exp> expl;
      /* Only succeds for tuple equations, i.e. (a,b,c) = foo(x,y,z) or foo(x,y,z) = (a,b,c) */
    case(DAE.EQUATION(DAE.TUPLE(expl),e2 as DAE.CALL(path =_),source))
    then DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(DAE.ET_OTHER(),expl,e2,source)});

    case(DAE.EQUATION(e2 as DAE.CALL(path =_),DAE.TUPLE(expl),source))
    then DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(DAE.ET_OTHER(),expl,e2,source)});
  end matchcontinue;
end lowerTupleEquation;

protected function lowerMultidimeqns
"function: lowerMultidimeqns
  author: PA

  Lowers MultiDimEquations by creating ARRAY_EQUATION nodes that points
  to the array equation, stored in a BackendDAE.MultiDimEquation array.
  each BackendDAE.MultiDimEquation has as many ARRAY_EQUATION nodes as it has array
  elements. This to ensure correct sorting using BLT.
  inputs:  (Variables, /* vars */
              BackendDAE.MultiDimEquation list)
  outputs: BackendDAE.Equation list"
  input BackendDAE.Variables vars;
  input list<BackendDAE.MultiDimEquation> algs;
  input list<BackendDAE.MultiDimEquation> ialgs;
  output list<BackendDAE.Equation> eqns;
  output list<BackendDAE.Equation> ieqns;
protected
  Integer indx;  
algorithm
  (eqns,indx) := lowerMultidimeqns2(vars, algs, 0);
  (ieqns,_) := lowerMultidimeqns2(vars, ialgs, indx);
end lowerMultidimeqns;

protected function lowerMultidimeqns2
"function: lowerMultidimeqns2
  Helper function to lower_multidimeqns. To handle indexes in BackendDAE.Equation nodes
  for multidimensional equations to indentify the corresponding
  MultiDimEquation
  inputs:  (Variables, /* vars */
              BackendDAE.MultiDimEquation list,
              int /* index */)
  outputs: (Equation list,
      int) /* updated index */"
  input BackendDAE.Variables inVariables;
  input list<BackendDAE.MultiDimEquation> inMultiDimEquationLst;
  input Integer inInteger;
  output list<BackendDAE.Equation> outEquationLst;
  output Integer outInteger;
algorithm
  (outEquationLst,outInteger) := matchcontinue (inVariables,inMultiDimEquationLst,inInteger)
    local
      BackendDAE.Variables vars;
      BackendDAE.Value aindx;
      list<BackendDAE.Equation> eqns,eqns2,res;
      BackendDAE.MultiDimEquation a;
      list<BackendDAE.MultiDimEquation> algs;
      DAE.Exp e1,e2;
      list<DAE.Exp> a1,a2,a1_1,an;
      list<tuple<DAE.Exp,DAE.Exp>> ealst;
      list<list<tuple<DAE.Exp, Boolean>>> al1,al2;
      list<tuple<DAE.Exp, Boolean>> ebl1,ebl2;
      DAE.ElementSource source;      
    case (vars,{},aindx) then ({},aindx);
    case (vars,((a as BackendDAE.MULTIDIM_EQUATION(left=DAE.ARRAY(array=a1),right=DAE.ARRAY(array=a2),source=source)) :: algs),aindx)
      equation
        ealst = Util.listThreadTuple(a1,a2);
        eqns = Util.listMap1(ealst,generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);
    case (vars,((a as BackendDAE.MULTIDIM_EQUATION(left=DAE.UNARY(exp=DAE.ARRAY(array=a1)),right=DAE.ARRAY(array=a2),source=source)) :: algs),aindx)
      equation
        an = Util.listMap(a1,Exp.negate);
        ealst = Util.listThreadTuple(an,a2);
        eqns = Util.listMap1(ealst,generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);              
    case (vars,((a as BackendDAE.MULTIDIM_EQUATION(left=DAE.ARRAY(array=a1),right=DAE.UNARY(exp=DAE.ARRAY(array=a2)),source=source)) :: algs),aindx)
      equation
        an = Util.listMap(a2,Exp.negate);
        ealst = Util.listThreadTuple(a1,an);
        eqns = Util.listMap1(ealst,generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);
    case (vars,((a as BackendDAE.MULTIDIM_EQUATION(left=DAE.MATRIX(scalar=al1),right=DAE.MATRIX(scalar=al2),source=source)) :: algs),aindx)
      equation
        ebl1 = Util.listFlatten(al1);
        ebl2 = Util.listFlatten(al2);
        a1 = Util.listMap(ebl1,Util.tuple21);
        a2 = Util.listMap(ebl2,Util.tuple21);
        ealst = Util.listThreadTuple(a1,a2);
        eqns = Util.listMap1(ealst,generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);  
    case (vars,((a as BackendDAE.MULTIDIM_EQUATION(left=DAE.UNARY(exp=DAE.MATRIX(scalar=al1)),right=DAE.MATRIX(scalar=al2),source=source)) :: algs),aindx)
      equation
        ebl1 = Util.listFlatten(al1);
        ebl2 = Util.listFlatten(al2);
        a1 = Util.listMap(ebl1,Util.tuple21);
        a2 = Util.listMap(ebl2,Util.tuple21);        
        an = Util.listMap(a1,Exp.negate);
        ealst = Util.listThreadTuple(an,a2);
        eqns = Util.listMap1(ealst,generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);              
    case (vars,((a as BackendDAE.MULTIDIM_EQUATION(left=DAE.MATRIX(scalar=al1),right=DAE.UNARY(exp=DAE.MATRIX(scalar=al2)),source=source)) :: algs),aindx)
      equation
        ebl1 = Util.listFlatten(al1);
        ebl2 = Util.listFlatten(al2);
        a1 = Util.listMap(ebl1,Util.tuple21);
        a2 = Util.listMap(ebl2,Util.tuple21);        
        an = Util.listMap(a2,Exp.negate);
        ealst = Util.listThreadTuple(a1,an);
        eqns = Util.listMap1(ealst,generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);              
    case (vars,((a as BackendDAE.MULTIDIM_EQUATION(left=e1,right=e2,source=source)) :: algs),aindx)
      equation
        eqns = lowerMultidimeqn(vars, a, aindx);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);
  end matchcontinue;
end lowerMultidimeqns2;

protected function lowerMultidimeqn
"function: lowerMultidimeqn
  Lowers a BackendDAE.MultiDimEquation by creating an equation for each array
  index, such that BLT can be run correctly.
  inputs:  (Variables, /* vars */
              MultiDimEquation,
              int) /* indx */
  outputs:  BackendDAE.Equation list"
  input BackendDAE.Variables inVariables;
  input BackendDAE.MultiDimEquation inMultiDimEquation;
  input Integer inInteger;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := matchcontinue (inVariables,inMultiDimEquation,inInteger)
    local
      list<DAE.Exp> expl1,expl2,expl;
      BackendDAE.Value numnodes,aindx;
      list<BackendDAE.Equation> lst;
      BackendDAE.Variables vars;
      list<BackendDAE.Value> ds;
      DAE.Exp e1,e2;
      DAE.ElementSource source "the element source";

    case (vars,BackendDAE.MULTIDIM_EQUATION(dimSize = ds,left = e1,right = e2,source = source),aindx)
      equation
        expl1 = statesAndVarsExp(e1, vars);
        expl2 = statesAndVarsExp(e2, vars);
        expl = listAppend(expl1, expl2);
        numnodes = Util.listReduce(ds, int_mul);
        lst = lowerMultidimeqn2(expl, numnodes, aindx, source);
      then
        lst;
  end matchcontinue;
end lowerMultidimeqn;

protected function lowerMultidimeqn2
"function: lower_multidimeqns2
  Helper function to lower_multidimeqns
  Creates numnodes BackendDAE.Equation nodes so BLT can be run correctly.
  inputs:  (DAE.Exp list, int /* numnodes */, int /* indx */)
  outputs: BackendDAE.Equation list ="
  input list<DAE.Exp> inExpExpLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  input DAE.ElementSource source "the element source";
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := matchcontinue (inExpExpLst1,inInteger2,inInteger3,source)
    local
      list<DAE.Exp> expl;
      BackendDAE.Value numnodes_1,numnodes,indx;
      list<BackendDAE.Equation> res;
    case (expl,0,_,_) then {};
    case (expl,numnodes,indx,source)
      equation
        numnodes_1 = numnodes - 1;
        res = lowerMultidimeqn2(expl, numnodes_1, indx, source);
      then
        (BackendDAE.ARRAY_EQUATION(indx,expl,source) :: res);
  end matchcontinue;
end lowerMultidimeqn2;

protected function lowerAlgorithms
"function: lowerAlgorithms
  This function lowers algorithm sections by generating a list
  of ALGORITHMS nodes for the BLT sorting, which are put in
  the equation list.
  An algorithm that calculates n variables will get n  ALGORITHM nodes
  such that the BLT sorting can be done correctly.
  inputs:  (Variables /* vars */, DAE.Algorithm list)
  outputs: BackendDAE.Equation list"
  input BackendDAE.Variables vars;
  input list<DAE.Algorithm> algs;
  output list<BackendDAE.Equation> eqns;
algorithm
  (eqns,_) := lowerAlgorithms2(vars, algs, 0);
end lowerAlgorithms;

protected function lowerAlgorithms2
"function: lowerAlgorithms2
  Helper function to lowerAlgorithms. To handle indexes in BackendDAE.Equation nodes
  for algorithms to indentify the corresponding algorithm.
  inputs:  (Variables /* vars */, DAE.Algorithm list, int /* algindex*/ )
  outputs: (Equation list, int /* updated algindex */ ) ="
  input BackendDAE.Variables inVariables;
  input list<DAE.Algorithm> inAlgorithmAlgorithmLst;
  input Integer inInteger;
  output list<BackendDAE.Equation> outEquationLst;
  output Integer outInteger;
algorithm
  (outEquationLst,outInteger) := matchcontinue (inVariables,inAlgorithmAlgorithmLst,inInteger)
    local
      BackendDAE.Variables vars;
      BackendDAE.Value aindx;
      list<BackendDAE.Equation> eqns,eqns2,res;
      DAE.Algorithm a;
      list<DAE.Algorithm> algs;
    case (vars,{},aindx) then ({},aindx);
    case (vars,(a :: algs),aindx)
      equation
        eqns = lowerAlgorithm(vars, a, aindx);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerAlgorithms2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);
  end matchcontinue;
end lowerAlgorithms2;

protected function lowerAlgorithm
"function: lowerAlgorithm
  Lowers a single algorithm. Creates n ALGORITHM nodes for blt sorting.
  inputs:  (Variables, /* vars */
              DAE.Algorithm,
              int /* algindx */)
  outputs: BackendDAE.Equation list"
  input BackendDAE.Variables vars;
  input DAE.Algorithm a;
  input Integer aindx;
  output list<BackendDAE.Equation> lst;
  list<DAE.Exp> inputs,outputs;
  BackendDAE.Value numnodes;
algorithm
  ((inputs,outputs)) := lowerAlgorithmInputsOutputs(vars, a);
  numnodes := listLength(outputs);
  lst := lowerAlgorithm2(inputs, outputs, numnodes, aindx);
end lowerAlgorithm;

protected function lowerAlgorithm2
"function: lowerAlgorithm2
  Helper function to lower_algorithm
  inputs:  (DAE.Exp list /* inputs   */,
              DAE.Exp list /* outputs  */,
              int          /* numnodes */,
              int          /* aindx    */)
  outputs:  (Equation list)"
  input list<DAE.Exp> inExpExpLst1;
  input list<DAE.Exp> inExpExpLst2;
  input Integer inInteger3;
  input Integer inInteger4;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := matchcontinue (inExpExpLst1,inExpExpLst2,inInteger3,inInteger4)
    local
      BackendDAE.Value numnodes_1,numnodes,aindx;
      list<BackendDAE.Equation> res;
      list<DAE.Exp> inputs,outputs;
    case (_,_,0,_) then {};
    case (inputs,outputs,numnodes,aindx)
      equation
        numnodes_1 = numnodes - 1;
        res = lowerAlgorithm2(inputs, outputs, numnodes_1, aindx);
      then
        (BackendDAE.ALGORITHM(aindx,inputs,outputs,DAE.emptyElementSource) :: res);
  end matchcontinue;
end lowerAlgorithm2;

public function lowerAlgorithmInputsOutputs
"function: lowerAlgorithmInputsOutputs
  This function finds the inputs and the outputs of an algorithm.
  An input is all values that are reffered on the right hand side of any
  statement in the algorithm and an output is a variables belonging to the
  variables that are assigned a value in the algorithm."
  input BackendDAE.Variables inVariables;
  input DAE.Algorithm inAlgorithm;
  output tuple<list<DAE.Exp>,list<DAE.Exp>> outTplExpExpLst;
algorithm
  outTplExpExpLst := matchcontinue (inVariables,inAlgorithm)
    local
      list<DAE.Exp> inputs1,outputs1,inputs2,outputs2,inputs,outputs;
      BackendDAE.Variables vars;
      Algorithm.Statement s;
      list<Algorithm.Statement> ss;
    case (_,DAE.ALGORITHM_STMTS(statementLst = {})) then (({},{}));
    case (vars,DAE.ALGORITHM_STMTS(statementLst = (s :: ss)))
      equation
        (inputs1,outputs1) = lowerStatementInputsOutputs(vars, s);
        ((inputs2,outputs2)) = lowerAlgorithmInputsOutputs(vars, DAE.ALGORITHM_STMTS(ss));
        inputs = Util.listUnionOnTrue(inputs1, inputs2, Exp.expEqual);
        outputs = Util.listUnionOnTrue(outputs1, outputs2, Exp.expEqual);
      then
        ((inputs,outputs));
  end matchcontinue;
end lowerAlgorithmInputsOutputs;

protected function lowerStatementInputsOutputs
"function: lowerStatementInputsOutputs
  Helper relatoin to lowerAlgorithmInputsOutputs
  Investigates single statements. Returns DAE.Exp list
  instead of DAE.ComponentRef list because derivatives must
  be handled as well.
  inputs:  (Variables, /* vars */
              Algorithm.Statement)
  outputs: (DAE.Exp list, /* inputs, CREF or der(CREF)  */
              DAE.Exp list  /* outputs, CREF or der(CREF) */)"
  input BackendDAE.Variables inVariables;
  input Algorithm.Statement inStatement;
  output list<DAE.Exp> outExpExpLst1;
  output list<DAE.Exp> outExpExpLst2;
algorithm
  (outExpExpLst1,outExpExpLst2) := matchcontinue (inVariables,inStatement)
    local
      BackendDAE.Variables vars;
      DAE.ExpType tp;
      DAE.ComponentRef cr;
      DAE.Exp e, e2;
      list<Algorithm.Statement> statements;
      Algorithm.Statement stmt;
      list<DAE.Exp> expl;
      list<Algorithm.Statement> stmts;
      Algorithm.Else elsebranch;
      list<DAE.Exp> inputs,inputs1,inputs2,inputs3,outputs,outputs1,outputs2;
      list<DAE.ComponentRef> crefs;
      DAE.Exp exp1;
      list<DAE.Dimension> ad;
      list<list<DAE.Subscript>> subslst,subslst1;
      // a := expr;
    case (vars,DAE.STMT_ASSIGN(type_ = tp,exp1 = exp1,exp = e))
      equation
        inputs = statesAndVarsExp(e, vars);
      then
        (inputs,{exp1});
    case (vars,DAE.STMT_WHEN(exp = e,statementLst = statements,elseWhen = NONE()))
      equation
        ((inputs,outputs)) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(statements));
        inputs2 = list_append(statesAndVarsExp(e, vars),inputs);
      then
        (inputs2,outputs);
    case (vars,DAE.STMT_WHEN(exp = e,statementLst = statements,elseWhen = SOME(stmt)))
      equation
        (inputs1, outputs1) = lowerStatementInputsOutputs(vars,stmt);
        ((inputs,outputs)) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(statements));
        inputs2 = list_append(statesAndVarsExp(e, vars),inputs);
        outputs2 = list_append(outputs, outputs1);
      then
        (inputs2,outputs2);
      // (a,b,c) := foo(...)
    case (vars,DAE.STMT_TUPLE_ASSIGN(type_ = tp, expExpLst = expl, exp = e))
      equation
        inputs = statesAndVarsExp(e,vars);
        crefs = Util.listFlatten(Util.listMap(expl,Exp.getCrefFromExp));
        outputs =  Util.listMap1(crefs,Exp.makeCrefExp,DAE.ET_OTHER());
      then
        (inputs,outputs);

    // v := expr   where v is array.
    case (vars,DAE.STMT_ASSIGN_ARR(type_ = DAE.ET_ARRAY(ty=tp,arrayDimensions=ad), componentRef = cr, exp = e))
      equation
        inputs = statesAndVarsExp(e,vars);  
        subslst = dimensionsToRange(ad);
        subslst1 = rangesToSubscripts(subslst);
        crefs = Util.listMap1r(subslst1,ComponentReference.subscriptCref,cr);
        expl = Util.listMap1(crefs,Exp.makeCrefExp,tp);             
      then (inputs,expl);

    case(vars,DAE.STMT_IF(exp = e, statementLst = stmts, else_ = elsebranch))
      equation
        ((inputs1,outputs1)) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(stmts));
        (inputs2,outputs2) = lowerElseAlgorithmInputsOutputs(vars,elsebranch);
        inputs3 = statesAndVarsExp(e,vars);
        inputs = Util.listListUnionOnTrue({inputs1, inputs2,inputs3}, Exp.expEqual);
        outputs = Util.listUnionOnTrue(outputs1, outputs2, Exp.expEqual);
      then (inputs,outputs);

    case(vars,DAE.STMT_ASSERT(cond = e1,msg=e2))
      local DAE.Exp e1,e2;
      equation
        inputs1 = statesAndVarsExp(e1,vars);
        inputs2 = statesAndVarsExp(e1,vars);
        inputs = Util.listListUnionOnTrue({inputs1, inputs2}, Exp.expEqual);
     then (inputs,{});

    case(vars, DAE.STMT_FOR(ident = iteratorName, exp = e, statementLst = stmts))
      local
        DAE.Ident iteratorName;
        DAE.Exp iteratorExp;
        list<DAE.Exp> arrayVars, nonArrayVars;
        list<list<DAE.Exp>> arrayElements;
        list<DAE.Exp> flattenedElements;
        DAE.ComponentRef cref_;
      equation
        ((inputs1,outputs1)) = lowerAlgorithmInputsOutputs(vars, DAE.ALGORITHM_STMTS(stmts));
        inputs2 = statesAndVarsExp(e, vars);
        // Split the output variables into variables that depend on the loop
        // variable and variables that don't.
        cref_ = ComponentReference.makeCrefIdent(iteratorName, DAE.ET_INT(), {});
        iteratorExp = DAE.CREF(cref_, DAE.ET_INT());
        (arrayVars, nonArrayVars) = Util.listSplitOnTrue1(outputs1, isLoopDependent, iteratorExp);
        arrayVars = Util.listMap(arrayVars, devectorizeArrayVar);
        // Explode array variables into their array elements.
        // I.e. var[i] => var[1], var[2], var[3] etc.
        arrayElements = Util.listMap3(arrayVars, explodeArrayVars, iteratorExp, e, vars);
        flattenedElements = Util.listFlatten(arrayElements);
        inputs = Util.listUnion(inputs1, inputs2);
        outputs = Util.listUnion(nonArrayVars, flattenedElements);
      then (inputs, outputs);
        
    case(vars, DAE.STMT_WHILE(exp = e, statementLst = stmts))
      equation
        ((inputs1,outputs)) = lowerAlgorithmInputsOutputs(vars, DAE.ALGORITHM_STMTS(stmts));
        inputs2 = statesAndVarsExp(e, vars);
        inputs = Util.listUnion(inputs1, inputs2);
      then (inputs, outputs);
        
    case(vars, DAE.STMT_NORETCALL(exp = e))
      equation
        inputs = statesAndVarsExp(e, vars);
      then
        (inputs, {});
    
    case(vars, DAE.STMT_REINIT(var = e as DAE.CREF(componentRef = _), value = e2))
      equation
        inputs = statesAndVarsExp(e2, vars);
      then
        (e :: inputs, {});
        
    case(_, _)
      equation
        Debug.fprintln("failtrace", "- DAELow.lowerStatementInputsOutputs failed\n");
      then 
        fail();
  end matchcontinue;
end lowerStatementInputsOutputs;

protected function lowerElseAlgorithmInputsOutputs
"Helper function to lowerStatementInputsOutputs"
  input BackendDAE.Variables vars;
  input Algorithm.Else elseBranch;
  output list<DAE.Exp> inputs;
  output list<DAE.Exp> outputs;
algorithm
  (inputs,outputs) := matchcontinue (vars,elseBranch)
    local
      list<Algorithm.Statement> stmts;
      list<DAE.Exp> inputs1,inputs2,inputs3,outputs1,outputs2;
      DAE.Exp e;

    case(vars,DAE.NOELSE()) then ({},{});

    case(vars,DAE.ELSEIF(e,stmts,elseBranch))
      equation
        (inputs1, outputs1) = lowerElseAlgorithmInputsOutputs(vars,elseBranch);
        ((inputs2, outputs2)) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(stmts));
        inputs3 = statesAndVarsExp(e,vars);
        inputs = Util.listListUnionOnTrue({inputs1, inputs2, inputs3}, Exp.expEqual);
        outputs = Util.listUnionOnTrue(outputs1, outputs2, Exp.expEqual);
      then (inputs,outputs);

    case(vars,DAE.ELSE(stmts))
      equation
        ((inputs, outputs)) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(stmts));
      then (inputs,outputs);
  end matchcontinue;
end lowerElseAlgorithmInputsOutputs;

protected function statesAndVarsExp
"function: statesAndVarsExp
  This function investigates an expression and returns as subexpressions
  that are variable names or derivatives of state names or states
  inputs:  (DAE.Exp, BackendDAE.Variables /* vars */)
  outputs: DAE.Exp list"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := matchcontinue (inExp,inVariables)
    local
      DAE.Exp e,e1,e2,e3;
      DAE.ComponentRef cr;
      DAE.ExpType tp;
      BackendDAE.Variables vars;
      list<DAE.Exp> s1,s2,res,s3,expl;
      DAE.Flow flowPrefix;
      list<BackendDAE.Value> p;
      list<list<DAE.Exp>> lst;
      list<list<tuple<DAE.Exp, Boolean>>> mexp;
      list<DAE.ExpVar> varLst;
    /* Special Case for Records */
    case ((e as DAE.CREF(componentRef = cr)),vars)
      equation
        DAE.ET_COMPLEX(varLst=varLst) = ComponentReference.crefLastType(cr);
        expl = Util.listMap1(varLst,generateCrefsExpFromType,e);
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;  
    /* Special Case for unextended arrays */
    case ((e as DAE.CREF(componentRef = cr,ty = DAE.ET_ARRAY(arrayDimensions=_))),vars)
      equation
        (e1,_) = extendArrExp(e,NONE());
        res = statesAndVarsExp(e1, vars);
      then
        res; 
    case ((e as DAE.CREF(componentRef = cr,ty = tp)),vars)
      equation
        (_,_) = getVar(cr, vars);
      then
        {e};
    case (DAE.BINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = Util.listUnionOnTrue(s1, s2, Exp.expEqual);
      then
        res;
    case (DAE.UNARY(exp = e),vars)
      equation
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = Util.listUnionOnTrue(s1, s2, Exp.expEqual);
      then
        res;
    case (DAE.LUNARY(exp = e),vars)
      equation
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (DAE.RELATION(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        s3 = statesAndVarsExp(e3, vars);
        res = Util.listListUnionOnTrue({s1,s2,s3}, Exp.expEqual);
      then
        res;
    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.STATE()) :: _),_) = getVar(cr, vars);
      then
        {e};
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars)
      equation
        (_,p) = getVar(cr, vars);
      then
        {};
    case (DAE.CALL(expLst = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;
    case (DAE.PARTEVALFUNCTION(expList = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;
    case (DAE.ARRAY(array = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;
    case (DAE.MATRIX(scalar = mexp),vars)
      equation
        res = statesAndVarsMatrixExp(mexp, vars);
      then
        res;
    case (DAE.TUPLE(PR = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;
    case (DAE.CAST(exp = e),vars)
      equation
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (DAE.ASUB(exp = e),vars)
      equation
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (DAE.REDUCTION(expr = e1,range = e2),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = Util.listUnionOnTrue(s1, s2, Exp.expEqual);
      then
        res;
    // ignore constants!
    case (DAE.ICONST(_),_) then {};
    case (DAE.RCONST(_),_) then {};
    case (DAE.BCONST(_),_) then {};
    case (DAE.SCONST(_),_) then {};
    case (DAE.ENUM_LITERAL(name = _),_) then {};

    // deal with possible failure
    case (e,vars)
      equation
        // adrpo: TODO! FIXME! this function fails for some of the expressions: cr.cr.cr[{1,2,3}] for example.
        // Debug.fprintln("daelow", "- DAELow.statesAndVarsExp failed to extract states or vars from expression: " +& Exp.dumpExpStr(e,0));
      then {};
  end matchcontinue;
end statesAndVarsExp;

protected function statesAndVarsMatrixExp
"function: statesAndVarsMatrixExp"
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input BackendDAE.Variables inVariables;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inTplExpExpBooleanLstLst,inVariables)
    local
      list<DAE.Exp> expl_1,ms_1,res;
      list<list<DAE.Exp>> lst;
      list<tuple<DAE.Exp, Boolean>> expl;
      list<list<tuple<DAE.Exp, Boolean>>> ms;
      BackendDAE.Variables vars;
    case ({},_) then {};
    case ((expl :: ms),vars)
      equation
        expl_1 = Util.listMap(expl, Util.tuple21);
        lst = Util.listMap1(expl_1, statesAndVarsExp, vars);
        ms_1 = statesAndVarsMatrixExp(ms, vars);
        res = Util.listListUnionOnTrue((ms_1 :: lst), Exp.expEqual);
      then
        res;
  end matchcontinue;
end statesAndVarsMatrixExp;

protected function isLoopDependent
  "Checks if an expression is a variable that depends on a loop iterator,
  ie. for i loop
        V[i] = ...  // V depends on i
      end for;
  Used by lowerStatementInputsOutputs in STMT_FOR case."
  input DAE.Exp varExp;
  input DAE.Exp iteratorExp;
  output Boolean isDependent;
algorithm
  isDependent := matchcontinue(varExp, iteratorExp)
    local
      list<DAE.Exp> subscript_exprs;
      list<DAE.Subscript> subscripts;
      DAE.ComponentRef cr;
    case (DAE.CREF(componentRef = cr), _)
      equation
        subscripts = ComponentReference.crefSubs(cr);
        subscript_exprs = Util.listMap(subscripts, Exp.subscriptExp);
        true = isLoopDependentHelper(subscript_exprs, iteratorExp);
      then true;
    case (DAE.ASUB(sub = subscript_exprs), _)
      equation
        true = isLoopDependentHelper(subscript_exprs, iteratorExp);
      then true;
    case (_,_)
      then false;
  end matchcontinue;
end isLoopDependent;

protected function isLoopDependentHelper
  "Helper for isLoopDependent.
  Checks if a list of subscripts contains a certain iterator expression."
  input list<DAE.Exp> subscripts;
  input DAE.Exp iteratorExp;
  output Boolean isDependent;
algorithm
  isDependent := matchcontinue(subscripts, iteratorExp)
    local
      DAE.Exp subscript;
      list<DAE.Exp> rest;
    case ({}, _) then false;
    case (subscript :: rest, _)
      equation
        true = Exp.expContains(subscript, iteratorExp);
      then true;
    case (subscript :: rest, _)
      equation
        true = isLoopDependentHelper(rest, iteratorExp);
      then true;
    case (_, _) then false;
  end matchcontinue;
end isLoopDependentHelper;

public function devectorizeArrayVar
  input DAE.Exp arrayVar;
  output DAE.Exp newArrayVar;
algorithm
  newArrayVar := matchcontinue(arrayVar)
    local 
      DAE.ComponentRef cr;
      DAE.ExpType ty;
      list<DAE.Exp> subs;
    case (DAE.ASUB(exp = DAE.ARRAY(array = (DAE.CREF(componentRef = cr, ty = ty) :: _)), sub = subs))
      equation
        cr = ComponentReference.crefStripLastSubs(cr);
      then
        DAE.ASUB(DAE.CREF(cr, ty), subs);
    case (DAE.ASUB(exp = DAE.MATRIX(scalar = (((DAE.CREF(componentRef = cr, ty = ty), _) :: _) :: _)), sub = subs))
      equation
        cr = ComponentReference.crefStripLastSubs(cr);
      then
        DAE.ASUB(DAE.CREF(cr, ty), subs);
    case (_) then arrayVar;
  end matchcontinue;
end devectorizeArrayVar;

protected function explodeArrayVars
  "Explodes an array variable into its elements. Takes a variable that is a CREF
  or ASUB, the name of the iterator variable and a range expression that the
  iterator iterates over."
  input DAE.Exp arrayVar;
  input DAE.Exp iteratorExp;
  input DAE.Exp rangeExpr;
  input BackendDAE.Variables vars;
  output list<DAE.Exp> arrayElements;
algorithm
  arrayElements := matchcontinue(arrayVar, iteratorExp, rangeExpr, vars)
    local
      list<DAE.Exp> subs;
      list<DAE.Exp> clonedElements, newElements;
      list<DAE.Exp> indices;
      DAE.ComponentRef cref;
      list<BackendDAE.Var> arrayElements;
      list<DAE.ComponentRef> varCrefs;
      list<DAE.Exp> varExprs;

    case (DAE.CREF(componentRef = _), _, _, _)
      equation
        indices = rangeIntExprs(rangeExpr);
        clonedElements = Util.listFill(arrayVar, listLength(indices));
        newElements = generateArrayElements(clonedElements, indices, iteratorExp);
      then newElements;
        
    case (DAE.ASUB(exp = DAE.CREF(componentRef = _)), _, _, _)
      equation
        // If the range is constant, then we can use it to generate only those
        // array elements that are actually used.
        indices = rangeIntExprs(rangeExpr);
        clonedElements = Util.listFill(arrayVar, listLength(indices));
        newElements = generateArrayElements(clonedElements, indices, iteratorExp);
      then newElements;
        
    case (DAE.CREF(componentRef = cref), _, _, _)
      equation
        (arrayElements, _) = getVar(cref, vars);
        varCrefs = Util.listMap(arrayElements, varCref);
        varExprs = Util.listMap(varCrefs, Exp.crefExp);
      then varExprs;

    case (DAE.ASUB(exp = DAE.CREF(componentRef = cref)), _, _, _)
      equation
        // If the range is not constant, then we just extract all array elements
        // of the array.
        (arrayElements, _) = getVar(cref, vars);
        varCrefs = Util.listMap(arrayElements, varCref);
        varExprs = Util.listMap(varCrefs, Exp.crefExp);
      then varExprs;
      
    case (DAE.ASUB(exp = e), _, _, _)
      local DAE.Exp e;
      equation
        varExprs = Exp.flattenArrayExpToList(e);
      then
        varExprs;
  end matchcontinue;
end explodeArrayVars;

protected function rangeIntExprs
  "Tries to convert a range to a list of integer expressions. Returns a list of
  integer expressions if possible, or fails. Used by explodeArrayVars."
  input DAE.Exp range;
  output list<DAE.Exp> integers;
algorithm
  integers := matchcontinue(range)
    local
      list<DAE.Exp> arrayElements;
    case (DAE.ARRAY(array = arrayElements))
      then arrayElements;
    case (DAE.RANGE(exp = DAE.ICONST(integer = start), range = DAE.ICONST(integer = stop), expOption = NONE()))
      local
        Integer start, stop;
        list<Values.Value> vals;
      equation
        vals = Ceval.cevalRange(start, 1, stop);
        arrayElements = Util.listMap(vals, ValuesUtil.valueExp);
      then
        arrayElements;  
    case (_) then fail();
  end matchcontinue;
end rangeIntExprs;

protected function generateArrayElements
  "Takes a list of identical CREF or ASUB expressions, a list of ICONST indices
  and a loop iterator expression, and recursively replaces the loop iterator
  with a constant index. Ex:
    generateArrayElements(cref[i,j], {1,2,3}, j) =>
      {cref[i,1], cref[i,2], cref[i,3]}"
  input list<DAE.Exp> clones;
  input list<DAE.Exp> indices;
  input DAE.Exp iteratorExp;
  output list<DAE.Exp> newElements;
algorithm
  newElements := matchcontinue(clones, indices, iteratorExp)
    local
      DAE.Exp clone, newElement, newElement2, index;
      list<DAE.Exp> restClones, restIndices, elements;
    case ({}, {}, _) then {};
    case (clone :: restClones, index :: restIndices, _)
      equation
        (newElement, _) = Exp.replaceExp(clone, iteratorExp, index);
        newElement2 = simplifySubscripts(newElement);
        elements = generateArrayElements(restClones, restIndices, iteratorExp);
      then (newElement2 :: elements);
  end matchcontinue;
end generateArrayElements;

protected function simplifySubscripts
  "Tries to simplify the subscripts of a CREF or ASUB. If an ASUB only contains
  constant subscripts, such as cref[1,4], then it also needs to be converted to
  a CREF."
  input DAE.Exp asub;
  output DAE.Exp maybeCref;
algorithm
  maybeCref := matchcontinue(asub)
    local
      DAE.Ident varIdent;
      DAE.ExpType arrayType, varType;
      list<DAE.Exp> subExprs, subExprsSimplified;
      list<DAE.Subscript> subscripts;
      DAE.Exp newCref;
      DAE.ComponentRef cref_;

    // A CREF => just simplify the subscripts.
    case (DAE.CREF(DAE.CREF_IDENT(varIdent, arrayType, subscripts), varType))
      equation
        subscripts = Util.listMap(subscripts, simplifySubscript);
        cref_ = ComponentReference.makeCrefIdent(varIdent, arrayType, subscripts);
      then DAE.CREF(cref_, varType);
        
    // An ASUB => convert to CREF if only constant subscripts.
    case (DAE.ASUB(DAE.CREF(DAE.CREF_IDENT(varIdent, arrayType, _), varType), subExprs))
      equation
        {} = Util.listSelect(subExprs, Exp.isNotConst);
        // If a subscript is not a single constant value it needs to be
        // simplified, e.g. cref[3+4] => cref[7], otherwise some subscripts
        // might be counted twice, such as cref[3+4] and cref[2+5], even though
        // they reference the same element.
        subExprsSimplified = Util.listMap(subExprs, Exp.simplify);
        subscripts = Util.listMap(subExprsSimplified, Exp.makeIndexSubscript);
        cref_ = ComponentReference.makeCrefIdent(varIdent, arrayType, subscripts);
      then DAE.CREF(cref_, varType);
    case (_) then asub;
  end matchcontinue;
end simplifySubscripts;

protected function simplifySubscript
  input DAE.Subscript sub;
  output DAE.Subscript simplifiedSub;
algorithm
  simplifiedSub := matchcontinue(sub)
    case (DAE.INDEX(exp = e))
      local
        DAE.Exp e;
      equation
        e = Exp.simplify(e);
      then DAE.INDEX(e);
    case (_) then sub;
  end matchcontinue;
end simplifySubscript;

protected function lowerEqn
"function: lowerEqn
  Helper function to lower2.
  Transforms a DAE.Element to Equation."
  input DAE.Element inElement;
  output BackendDAE.Equation outEquation;
algorithm
  outEquation :=  matchcontinue (inElement)
    local DAE.Exp e1,e2;
          DAE.ComponentRef cr1,cr2;
          DAE.ElementSource source "the element source";

    case (DAE.EQUATION(exp = e1,scalar = e2,source = source))
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
      then
        BackendDAE.EQUATION(e1,e2,source);

    case (DAE.INITIALEQUATION(exp1 = e1,exp2 = e2,source = source))
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
      then
        BackendDAE.EQUATION(e1,e2,source);

    case (DAE.EQUEQUATION(cr1 = cr1, cr2 = cr2,source = source))
      equation
        e1 = Exp.simplify(DAE.CREF(cr1, DAE.ET_OTHER()));
        e2 = Exp.simplify(DAE.CREF(cr2, DAE.ET_OTHER()));
      then
        BackendDAE.EQUATION(e1,e2,source);

    case (DAE.DEFINE(componentRef = cr1, exp = e2, source = source))
      equation
        e1 = Exp.simplify(DAE.CREF(cr1, DAE.ET_OTHER()));
        e2 = Exp.simplify(e2);
      then
        BackendDAE.EQUATION(e1,e2,source);

    case (DAE.INITIALDEFINE(componentRef = cr1, exp = e2, source = source))
      equation
        e1 = Exp.simplify(DAE.CREF(cr1, DAE.ET_OTHER()));
        e2 = Exp.simplify(e2);
      then
        BackendDAE.EQUATION(e1,e2,source);
  end matchcontinue;
end lowerEqn;

protected function lowerArrEqn
"function: lowerArrEqn
  Helper function to lower2.
  Transform a DAE.Element to MultiDimEquation."
  input DAE.Element inElement;
  input DAE.FunctionTree funcs;
  output BackendDAE.MultiDimEquation outMultiDimEquation;
algorithm
  outMultiDimEquation := matchcontinue (inElement,funcs)
    local
      DAE.Exp e1,e2,e1_1,e2_1,e1_2,e2_2,e1_3,e2_3;
      list<BackendDAE.Value> ds;
      DAE.ElementSource source;

    case (DAE.ARRAY_EQUATION(dimension = ds, exp = e1, array = e2, source = source),funcs)
      equation
        e1_1 = Inline.inlineExp(e1,(SOME(funcs),{DAE.NORM_INLINE()}));
        e2_1 = Inline.inlineExp(e2,(SOME(funcs),{DAE.NORM_INLINE()}));
        (e1_2,_) = extendArrExp(e1_1,SOME(funcs));
        (e2_2,_) = extendArrExp(e2_1,SOME(funcs));
        e1_3 = Exp.simplify(e1_2);
        e2_3 = Exp.simplify(e2_2);
      then
        BackendDAE.MULTIDIM_EQUATION(ds,e1_3,e2_3,source);

    case (DAE.INITIAL_ARRAY_EQUATION(dimension = ds, exp = e1, array = e2, source = source),funcs)
      equation
        e1_1 = Inline.inlineExp(e1,(SOME(funcs),{DAE.NORM_INLINE()}));
        e2_1 = Inline.inlineExp(e2,(SOME(funcs),{DAE.NORM_INLINE()}));
        (e1_2,_) = extendArrExp(e1_1,SOME(funcs));
        (e2_2,_) = extendArrExp(e2_1,SOME(funcs));
        e1_3 = Exp.simplify(e1_2);
        e2_3 = Exp.simplify(e2_2);
      then
        BackendDAE.MULTIDIM_EQUATION(ds,e1_3,e2_3,source);
  end matchcontinue;
end lowerArrEqn;

protected function extendAlgorithm "
Author: Frenkel TUD 2010-07"
  input DAE.Algorithm inAlg;
  input Option<DAE.FunctionTree> funcs;  
  output DAE.Algorithm outAlg;
algorithm 
  outAlg := matchcontinue(inAlg,funcs)
    local list<DAE.Statement> statementLst;
    case(DAE.ALGORITHM_STMTS(statementLst=statementLst),funcs)
      equation
        (statementLst,_) = DAEUtil.traverseDAEEquationsStmts(statementLst, extendArrExp, funcs);
      then
        DAE.ALGORITHM_STMTS(statementLst);
    case(inAlg,funcs) then inAlg;        
  end matchcontinue;
end extendAlgorithm;

protected function extendArrExp "
Author: Frenkel TUD 2010-07"
  input DAE.Exp inExp;
  input Option<DAE.FunctionTree> infuncs;  
  output DAE.Exp outExp;
  output Option<DAE.FunctionTree> outfuncs;  
algorithm 
  (outExp,outfuncs) := matchcontinue(inExp,infuncs)
    local DAE.Exp e;
    case(inExp,infuncs)
      equation
        ((e,outfuncs)) = Exp.traverseExp(inExp, traversingextendArrExp, infuncs);
      then
        (e,outfuncs);
    case(inExp,infuncs) then (inExp,infuncs);        
  end matchcontinue;
end extendArrExp;

protected function traversingextendArrExp "
Author: Frenkel TUD 2010-07.
  This function extend all array and record componentrefs to there
  elements. This is necessary for BLT and substitution of simple 
  equations."
  input tuple<DAE.Exp, Option<DAE.FunctionTree> > inExp;
  output tuple<DAE.Exp, Option<DAE.FunctionTree> > outExp;
algorithm outExp := matchcontinue(inExp)
  local
    Option<DAE.FunctionTree> funcs;
    DAE.ComponentRef cr;
    list<DAE.ComponentRef> crlst;
    DAE.ExpType t,ty;
    DAE.Dimension id, jd;
    list<DAE.Dimension> ad;
    Integer i,j;
    list<list<DAE.Subscript>> subslst,subslst1;
    list<DAE.Exp> expl;
    DAE.Exp e,e_new;
    list<DAE.ExpVar> varLst;
    Absyn.Path name;
    tuple<DAE.Exp, Option<DAE.FunctionTree> > restpl;  
    list<list<tuple<DAE.Exp, Boolean>>> scalar;
    
  // CASE for Matrix    
  case( (DAE.CREF(componentRef=cr,ty= t as DAE.ET_ARRAY(ty=ty,arrayDimensions=ad as {id, jd})), funcs) )
    equation
        i = Exp.dimensionSize(id);
        j = Exp.dimensionSize(jd);
        subslst = dimensionsToRange(ad);
        subslst1 = rangesToSubscripts(subslst);
        crlst = Util.listMap1r(subslst1,ComponentReference.subscriptCref,cr);
        expl = Util.listMap1(crlst,Exp.makeCrefExp,ty);
        scalar = makeMatrix(expl,j,j,{});
        e_new = DAE.MATRIX(t,i,scalar);
        restpl = Exp.traverseExp(e_new, traversingextendArrExp, funcs);
    then
      (restpl);
  
  // CASE for Matrix and checkModel is on    
  case( (DAE.CREF(componentRef=cr,ty= t as DAE.ET_ARRAY(ty=ty,arrayDimensions=ad as {id, jd})), funcs) )
    equation
        true = OptManager.getOption("checkModel");
        // consider size 1
        i = Exp.dimensionSize(DAE.DIM_INTEGER(1));
        j = Exp.dimensionSize(DAE.DIM_INTEGER(1));
        subslst = dimensionsToRange(ad);
        subslst1 = rangesToSubscripts(subslst);
        crlst = Util.listMap1r(subslst1,ComponentReference.subscriptCref,cr);
        expl = Util.listMap1(crlst,Exp.makeCrefExp,ty);
        scalar = makeMatrix(expl,j,j,{});
        e_new = DAE.MATRIX(t,i,scalar);
        restpl = Exp.traverseExp(e_new, traversingextendArrExp, funcs);
    then
      (restpl);
  
  // CASE for Array
  case( (DAE.CREF(componentRef=cr,ty= t as DAE.ET_ARRAY(ty=ty,arrayDimensions=ad)), funcs) )
    equation
        subslst = dimensionsToRange(ad);
        subslst1 = rangesToSubscripts(subslst);
        crlst = Util.listMap1r(subslst1,ComponentReference.subscriptCref,cr);
        expl = Util.listMap1(crlst,Exp.makeCrefExp,ty);
        e_new = DAE.ARRAY(t,true,expl);
        restpl = Exp.traverseExp(e_new, traversingextendArrExp, funcs);
    then
      (restpl);

  // CASE for Array and checkModel is on
  case( (DAE.CREF(componentRef=cr,ty= t as DAE.ET_ARRAY(ty=ty,arrayDimensions=ad)), funcs) )
    equation
        true = OptManager.getOption("checkModel");
        // consider size 1      
        subslst = dimensionsToRange({DAE.DIM_INTEGER(1)});
        subslst1 = rangesToSubscripts(subslst);
        crlst = Util.listMap1r(subslst1,ComponentReference.subscriptCref,cr);
        expl = Util.listMap1(crlst,Exp.makeCrefExp,ty);
        e_new = DAE.ARRAY(t,true,expl);
        restpl = Exp.traverseExp(e_new, traversingextendArrExp, funcs);
    then
      (restpl);
  // CASE for Records
  case( (e as DAE.CREF(componentRef=cr,ty= t as DAE.ET_COMPLEX(name=name,varLst=varLst,complexClassType=ClassInf.RECORD(_))), funcs) )
    equation
        expl = Util.listMap1(varLst,generateCrefsExpFromType,e);
        e_new = DAE.CALL(name,expl,false,false,t,DAE.NO_INLINE());
        restpl = Exp.traverseExp(e_new, traversingextendArrExp, funcs);
    then 
      (restpl);
  case(inExp) then inExp;
end matchcontinue;
end traversingextendArrExp;

protected function makeMatrix
  input list<DAE.Exp> expl;
  input Integer r;
  input Integer n;
  input list<tuple<DAE.Exp, Boolean>> incol;
  output list<list<tuple<DAE.Exp, Boolean>>> scalar;
algorithm
  scalar := matchcontinue (expl, r, n, incol)
    local 
      DAE.Exp e;
      list<DAE.Exp> rest;
      list<list<tuple<DAE.Exp, Boolean>>> res;
      list<tuple<DAE.Exp, Boolean>> col;
      Exp.Type tp;
      Boolean builtin;      
  case({},r,n,incol)
    equation
      col = listReverse(incol);
    then {col};  
  case(e::rest,r,n,incol)
    equation
      true = intEq(r,0);
      col = listReverse(incol);
      res = makeMatrix(e::rest,n,n,{});
    then      
      (col::res);
  case(e::rest,r,n,incol)
    equation
      tp = Exp.typeof(e);
      builtin = Exp.typeBuiltin(tp);
      res = makeMatrix(rest,r-1,n,(e,builtin)::incol);
    then      
      res;
  end matchcontinue;
end makeMatrix;
  
public function collateAlgorithm "
Author: Frenkel TUD 2010-07"
  input DAE.Algorithm inAlg;
  input Option<DAE.FunctionTree> infuncs;  
  output DAE.Algorithm outAlg;
algorithm 
  outAlg := matchcontinue(inAlg,infuncs)
    local list<DAE.Statement> statementLst;
    case(DAE.ALGORITHM_STMTS(statementLst=statementLst),infuncs)
      equation
        (statementLst,_) = DAEUtil.traverseDAEEquationsStmts(statementLst, collateArrExp, infuncs);
      then
        DAE.ALGORITHM_STMTS(statementLst);
    case(inAlg,infuncs) then inAlg;        
  end matchcontinue;
end collateAlgorithm;

public function collateArrExp "
Author: Frenkel TUD 2010-07"
  input DAE.Exp inExp;
  input Option<DAE.FunctionTree> infuncs;  
  output DAE.Exp outExp;
  output Option<DAE.FunctionTree> outfuncs;  
algorithm 
  (outExp,outfuncs) := matchcontinue(inExp,infuncs)
    local DAE.Exp e;
    case(inExp,infuncs)
      equation
        ((e,outfuncs)) = Exp.traverseExp(inExp, traversingcollateArrExp, infuncs);
      then
        (e,outfuncs);
    case(inExp,infuncs) then (inExp,infuncs);        
  end matchcontinue;
end collateArrExp;  
  
protected function traversingcollateArrExp "
Author: Frenkel TUD 2010-07."
  input tuple<DAE.Exp, Option<DAE.FunctionTree> > inExp;
  output tuple<DAE.Exp, Option<DAE.FunctionTree> > outExp;
algorithm outExp := matchcontinue(inExp)
  local
    Option<DAE.FunctionTree> funcs;
    DAE.ComponentRef cr;
    DAE.ExpType ty;
    Integer i;
    DAE.Exp e,e1,e1_1,e1_2;
    Boolean b;
    case ((e as DAE.MATRIX(ty=ty,integer=i,scalar=(((e1 as DAE.CREF(componentRef = cr)),_)::_)::_),funcs))
      equation
        e1_1 = Exp.expStripLastSubs(e1);
        (e1_2,_) = extendArrExp(e1_1,funcs);
        true = Exp.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));
    case ((e as DAE.MATRIX(ty=ty,integer=i,scalar=(((e1 as DAE.UNARY(exp = DAE.CREF(componentRef = cr))),_)::_)::_),funcs))
      equation
        e1_1 = Exp.expStripLastSubs(e1);
        (e1_2,_) = extendArrExp(e1_1,funcs);
        true = Exp.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));        
    case ((e as DAE.ARRAY(ty=ty,scalar=b,array=(e1 as DAE.CREF(componentRef = cr))::_),funcs))
      equation
        e1_1 = Exp.expStripLastSubs(e1);
        (e1_2,_) = extendArrExp(e1_1,funcs);
        true = Exp.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));  
    case ((e as DAE.ARRAY(ty=ty,scalar=b,array=(e1 as DAE.UNARY(exp = DAE.CREF(componentRef = cr)))::_),funcs))
      equation
        e1_1 = Exp.expStripLastSubs(e1);
        (e1_2,_) = extendArrExp(e1_1,funcs);
        true = Exp.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));               
  case(inExp) then inExp;
end matchcontinue;
end traversingcollateArrExp;  
  
protected function lowerComplexEqn
"function: lowerComplexEqn
  Helper function to lower2.
  Transform a DAE.Element to ComplexEquation."
  input DAE.Element inElement;
  input DAE.FunctionTree funcs;
  output list<BackendDAE.Equation> outComplexEquations;
  output list<BackendDAE.MultiDimEquation> outMultiDimEquations;  
algorithm
  (outComplexEquations,outMultiDimEquations) := matchcontinue (inElement, funcs)
    local
      DAE.Exp e1,e2,e1_1,e2_1;
      DAE.ExpType ty;
      list<DAE.ExpVar> varLst;
      Integer i;
      list<BackendDAE.Equation> complexEqs;
      list<BackendDAE.MultiDimEquation> arreqns;
      DAE.ElementSource source "the element source";

    // normal first try to inline function calls and extend the equations
    case (DAE.COMPLEX_EQUATION(lhs = e1, rhs = e2,source = source),funcs)
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
        ty = Exp.typeof(e1);
        i = Exp.sizeOf(ty);
        // inline 
        e1_1 = Inline.inlineExp(e1,(SOME(funcs),{DAE.NORM_INLINE()}));
        e2_1 = Inline.inlineExp(e2,(SOME(funcs),{DAE.NORM_INLINE()}));
        // extend      
        ((complexEqs,arreqns)) = extendRecordEqns(BackendDAE.COMPLEX_EQUATION(-1,e1_1,e2_1,source),funcs);
      then
        (complexEqs,arreqns);
    case (DAE.COMPLEX_EQUATION(lhs = e1, rhs = e2,source = source),funcs)
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
        // create as many equations as the dimension of the record
        ty = Exp.typeof(e1);
        i = Exp.sizeOf(ty);
        complexEqs = Util.listFill(BackendDAE.COMPLEX_EQUATION(-1,e1,e2,source), i);
      then
        (complexEqs,{});
    // initial first try to inline function calls and extend the equations
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = e1, rhs = e2,source = source),funcs)
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
        ty = Exp.typeof(e1);
        i = Exp.sizeOf(ty);
        // inline 
        e1_1 = Inline.inlineExp(e1,(SOME(funcs),{DAE.NORM_INLINE()}));
        e2_1 = Inline.inlineExp(e2,(SOME(funcs),{DAE.NORM_INLINE()}));
        // extend      
        ((complexEqs,arreqns)) = extendRecordEqns(BackendDAE.COMPLEX_EQUATION(-1,e1_1,e2_1,source),funcs);
      then
        (complexEqs,arreqns);
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = e1, rhs = e2,source = source),funcs)
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
        // create as many equations as the dimension of the record
        ty = Exp.typeof(e1);
        i = Exp.sizeOf(ty);
        complexEqs = Util.listFill(BackendDAE.COMPLEX_EQUATION(-1,e1,e2,source), i);
      then
        (complexEqs,{});
    case (_,_)
      equation
        print("- DAELow.lowerComplexEqn failed!\n");
      then ({},{});
  end matchcontinue;
end lowerComplexEqn;

protected function lowerVar
"function: lowerVar
  Transforms a DAE variable to DAELOW variable.
  Includes changing the ComponentRef name to a simpler form
  \'a\'.\'b\'{2}\'c\'{5} becomes
  \'a.b{2}.c\' (as CREF_IDENT(\"a.b.c\",{2}) )
  inputs: (DAE.Element, BackendDAE.BinTree /* states */)
  outputs: Var"
  input DAE.Element inElement;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.Var outVar;
  output Option<DAE.Exp> outBinding;
  output BackendDAE.BinTree outBinTree;
algorithm
  (outVar,outBinding,outBinTree) := matchcontinue (inElement,inBinTree)
    local
      list<DAE.Subscript> dims;
      DAE.ComponentRef name;
      BackendDAE.VarKind kind_1;
      Option<DAE.Exp> bind;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      BackendDAE.BinTree states;
      DAE.Type t;

    case (DAE.VAR(componentRef = name,
                  kind = kind,
                  direction = dir,
                  ty = t,
                  binding = bind,
                  dims = dims,
                  flowPrefix = flowPrefix,
                  streamPrefix = streamPrefix,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  absynCommentOption = comment),states)
      equation
        (kind_1,states) = lowerVarkind(kind, t, name, dir, flowPrefix, streamPrefix, states, dae_var_attr);
        tp = lowerType(t);
      then
        (BackendDAE.VAR(name,kind_1,dir,tp,NONE(),NONE(),dims,-1,source,dae_var_attr,comment,flowPrefix,streamPrefix), bind, states);
  end matchcontinue;
end lowerVar;

protected function lowerKnownVar
"function: lowerKnownVar
  Helper function to lower2"
  input DAE.Element inElement;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inElement)
    local
      list<DAE.Subscript> dims;
      DAE.ComponentRef name;
      BackendDAE.VarKind kind_1;
      Option<DAE.Exp> bind;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Type t;

    case (DAE.VAR(componentRef = name,
                  kind = kind,
                  direction = dir,
                  ty = t,
                  binding = bind,
                  dims = dims,
                  flowPrefix = flowPrefix,
                  streamPrefix = streamPrefix,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  absynCommentOption = comment))
      equation
        kind_1 = lowerKnownVarkind(kind, name, dir, flowPrefix);
        tp = lowerType(t);
      then
        BackendDAE.VAR(name,kind_1,dir,tp,bind,NONE(),dims,-1,source,dae_var_attr,comment,flowPrefix,streamPrefix);

    case (_)
      equation
        print("-DAELow.lowerKnownVar failed\n");
      then
        fail();
  end matchcontinue;
end lowerKnownVar;

protected function lowerExtObjVar
" Helper function to lower2
  Fails for all variables except external object instances."
  input DAE.Element inElement;
  output BackendDAE.Var outVar;
algorithm
  outVar:=
  matchcontinue (inElement)
    local
      list<DAE.Subscript> dims;
      DAE.ComponentRef name;
      BackendDAE.VarKind kind_1;
      Option<DAE.Exp> bind;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Type t;

    case (DAE.VAR(componentRef = name,
                  kind = kind,
                  direction = dir,
                  ty = t,
                  binding = bind,
                  dims = dims,
                  flowPrefix = flowPrefix,
                  streamPrefix = streamPrefix,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  absynCommentOption = comment))
      equation
        kind_1 = lowerExtObjVarkind(t);
        tp = lowerType(t);
      then
        BackendDAE.VAR(name,kind_1,dir,tp,bind,NONE(),dims,-1,source,dae_var_attr,comment,flowPrefix,streamPrefix);
  end matchcontinue;
end lowerExtObjVar;

protected function lowerVarkind
"function: lowerVarkind
  Helper function to lowerVar.
  inputs: (DAE.VarKind,
           Type,
           DAE.ComponentRef,
           DAE.VarDirection, /* input/output/bidir */
           DAE.Flow,
           DAE.Stream,
           BackendDAE.BinTree /* states */)
  outputs  VarKind
  NOTE: Fails for not states that are not algebraic
        variables, e.g. parameters and constants"
  input DAE.VarKind inVarKind;
  input DAE.Type inType;
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
  input DAE.Stream inStream;
  input BackendDAE.BinTree inBinTree;
  input option<DAE.VariableAttributes> daeAttr;
  output BackendDAE.VarKind outVarKind;
  output BackendDAE.BinTree outBinTree;
algorithm
  (outVarKind,outBinTree) := matchcontinue (inVarKind,inType,inComponentRef,inVarDirection,inFlow,inStream,inBinTree,daeAttr)
    local
      DAE.ComponentRef v,cr;
      BackendDAE.BinTree states;
      DAE.VarDirection dir;
      DAE.Flow flowPrefix;
    // States appear differentiated among equations
    case (DAE.VARIABLE(),_,v,_,_,_,states,daeAttr)
      equation
        _ = treeGet(states, v);
      then
        (BackendDAE.STATE(),states);
    // Or states have StateSelect.always
    case (DAE.VARIABLE(),_,v,_,_,_,states,SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,_,_,SOME(DAE.ALWAYS()),_,_,_)))
      equation
      states = treeAdd(states, v, 0);  
    then (BackendDAE.STATE(),states);

    case (DAE.VARIABLE(),(DAE.T_BOOL(_),_),cr,dir,flowPrefix,_,states,_)
      equation
        failure(topLevelInput(cr, dir, flowPrefix));
      then
        (BackendDAE.DISCRETE(),states);

    case (DAE.DISCRETE(),(DAE.T_BOOL(_),_),cr,dir,flowPrefix,_,states,_)
      equation
        failure(topLevelInput(cr, dir, flowPrefix));
      then
        (BackendDAE.DISCRETE(),states);

    case (DAE.VARIABLE(),(DAE.T_INTEGER(_),_),cr,dir,flowPrefix,_,states,_)
      equation
        failure(topLevelInput(cr, dir, flowPrefix));
      then
        (BackendDAE.DISCRETE(),states);

    case (DAE.DISCRETE(),(DAE.T_INTEGER(_),_),cr,dir,flowPrefix,_,states,_)
      equation
        failure(topLevelInput(cr, dir, flowPrefix));
      then
        (BackendDAE.DISCRETE(),states);

    case (DAE.VARIABLE(),_,cr,dir,flowPrefix,_,states,_)
      equation
        failure(topLevelInput(cr, dir, flowPrefix));
      then
        (BackendDAE.VARIABLE(),states);

    case (DAE.DISCRETE(),_,cr,dir,flowPrefix,_,states,_)
      equation
        failure(topLevelInput(cr, dir, flowPrefix));
      then
        (BackendDAE.DISCRETE(),states);
  end matchcontinue;
end lowerVarkind;

protected function topLevelInput
"function: topLevelInput
  author: PA
  Succeds if variable is input declared at the top level of the model,
  or if it is an input in a connector instance at top level."
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
algorithm
  _ := matchcontinue (inComponentRef,inVarDirection,inFlow)
    local
      DAE.ComponentRef cr;
      String name;
    case ((cr as DAE.CREF_IDENT(ident = name)),DAE.INPUT(),_)
      equation
        {_} = Util.stringSplitAtChar(name, ".") "top level ident, no dots" ;
      then
        ();
    case (DAE.CREF_IDENT(ident = name),DAE.INPUT(),DAE.NON_FLOW()) /* Connector input variables at top level for crefs that are stringified */
      equation
        {_,_} = Util.stringSplitAtChar(name, ".");
      then
        ();
    case (DAE.CREF_IDENT(ident = name),DAE.INPUT(),DAE.FLOW())
      equation
        {_,_} = Util.stringSplitAtChar(name, ".");
      then
        ();
    /* For crefs that are not yet stringified, e.g. lower_known_var */
    case (DAE.CREF_QUAL(ident = name,componentRef = DAE.CREF_IDENT(ident = _)),DAE.INPUT(),DAE.FLOW()) then ();
    case ((cr as DAE.CREF_QUAL(ident = name,componentRef = DAE.CREF_IDENT(ident = _))),DAE.INPUT(),DAE.NON_FLOW()) then ();
  end matchcontinue;
end topLevelInput;

protected function topLevelOutput
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
algorithm
  _ := matchcontinue(inComponentRef, inVarDirection, inFlow)
  local 
    DAE.ComponentRef cr;
    String name;
    case ((cr as DAE.CREF_IDENT(ident = name)),DAE.OUTPUT(),_)
      equation
        {_} = Util.stringSplitAtChar(name, ".") "top level ident, no dots" ;
      then
        ();
    case (DAE.CREF_IDENT(ident = name),DAE.OUTPUT(),DAE.NON_FLOW()) /* Connector input variables at top level for crefs that are stringified */
      equation
        {_,_} = Util.stringSplitAtChar(name, ".");
      then
        ();
    case (DAE.CREF_IDENT(ident = name),DAE.OUTPUT(),DAE.FLOW())
      equation
        {_,_} = Util.stringSplitAtChar(name, ".");
      then
        ();
    /* For crefs that are not yet stringified, e.g. lower_known_var */
    case (DAE.CREF_QUAL(ident = name,componentRef = DAE.CREF_IDENT(ident = _)),DAE.OUTPUT(),DAE.FLOW()) then ();
    case ((cr as DAE.CREF_QUAL(ident = name,componentRef = DAE.CREF_IDENT(ident = _))),DAE.OUTPUT(),DAE.NON_FLOW()) then ();
  end matchcontinue;
end topLevelOutput;  

protected function lowerKnownVarkind
"function: lowerKnownVarkind
  Helper function to lowerKnownVar.
  NOTE: Fails for everything but parameters and constants and top level inputs"
  input DAE.VarKind inVarKind;
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
  output BackendDAE.VarKind outVarKind;
algorithm
  outVarKind := matchcontinue (inVarKind,inComponentRef,inVarDirection,inFlow)
    local
      DAE.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.Flow flowPrefix;
    case (DAE.PARAM(),_,_,_) then BackendDAE.PARAM();
    case (DAE.CONST(),_,_,_) then BackendDAE.CONST();
    case (DAE.VARIABLE(),cr,dir,flowPrefix)
      equation
        topLevelInput(cr, dir, flowPrefix);
      then
        BackendDAE.VARIABLE();
    // adrpo: topLevelInput might fail!
    // case (DAE.VARIABLE(),cr,dir,flowPrefix)
    //  then
    //    BackendDAE.VARIABLE();
    case (_,_,_,_)
      equation
        print("lower_known_varkind failed\n");
      then
        fail();
  end matchcontinue;
end lowerKnownVarkind;

protected function lowerExtObjVarkind
" Helper function to lowerExtObjVar.
  NOTE: Fails for everything but External objects"
  input DAE.Type inType;
  output BackendDAE.VarKind outVarKind;
algorithm
  outVarKind:=
  matchcontinue (inType)
    local Absyn.Path path;
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path)),_)) then BackendDAE.EXTOBJ(path);
  end matchcontinue;
end lowerExtObjVarkind;

public function incidenceMatrix
"function: incidenceMatrix
  author: PA
  Calculates the incidence matrix, i.e. which variables are present
  in each equation."
  input BackendDAE.DAELow inDAELow;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
algorithm
  outIncidenceMatrix := matchcontinue (inDAELow)
    local
      list<BackendDAE.Equation> eqnsl;
      list<list<BackendDAE.Value>> lstlst;
      array<list<BackendDAE.Value>> arr;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.WhenClause> wc;
    case (BackendDAE.DAELOW(orderedVars = vars,orderedEqs = eqns, eventInfo = BackendDAE.EVENT_INFO(whenClauseLst = wc)))
      equation
        eqnsl = equationList(eqns);
        lstlst = incidenceMatrix2(vars, eqnsl, wc);
        arr = listArray(lstlst);
      then
        arr;
    case (_)
      equation
        print("incidence_matrix failed\n");
      then
        fail();
  end matchcontinue;
end incidenceMatrix;

protected function incidenceMatrix2
"function: incidenceMatrix2
  author: PA

  Helper function to incidenceMatrix
  Calculates the incidence matrix as a list of list of integers"
  input BackendDAE.Variables inVariables;
  input list<BackendDAE.Equation> inEquationLst;
  input list<BackendDAE.WhenClause> inWhenClause;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst:=
  matchcontinue (inVariables,inEquationLst,inWhenClause)
    local
      list<list<BackendDAE.Value>> lst;
      list<BackendDAE.Value> row;
      BackendDAE.Variables vars;
      BackendDAE.Equation e;
      list<BackendDAE.Equation> eqns;
      list<BackendDAE.WhenClause> wc;
    case (_,{},_) then {};
    case (vars,(e :: eqns),wc)
      equation
        lst = incidenceMatrix2(vars, eqns, wc);
        row = incidenceRow(vars, e, wc);
      then
        (row :: lst);
    case (_,_,_)
      equation
        print("incidence_matrix2 failed\n");
      then
        fail();
  end matchcontinue;
end incidenceMatrix2;

protected function incidenceRow
"function: incidenceRow
  author: PA
  Helper function to incidenceMatrix. Calculates the indidence row
  in the matrix for one equation."
  input BackendDAE.Variables inVariables;
  input BackendDAE.Equation inEquation;
  input list<BackendDAE.WhenClause> inWhenClause;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inVariables,inEquation,inWhenClause)
    local
      list<BackendDAE.Value> lst1,lst2,res,res_1;
      BackendDAE.Variables vars;
      DAE.Exp e1,e2,e;
      list<list<BackendDAE.Value>> lst3;
      list<DAE.Exp> expl,inputs,outputs;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation we;
      BackendDAE.Value indx;
      list<BackendDAE.WhenClause> wc;
      Integer wc_index;
    case (vars,BackendDAE.EQUATION(exp = e1,scalar = e2),_)
      equation
        lst1 = incidenceRowExp(e1, vars) "EQUATION" ;
        lst2 = incidenceRowExp(e2, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,BackendDAE.COMPLEX_EQUATION(lhs = e1,rhs = e2),_)
      equation
        lst1 = incidenceRowExp(e1, vars) "COMPLEX_EQUATION" ;
        lst2 = incidenceRowExp(e2, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,BackendDAE.ARRAY_EQUATION(crefOrDerCref = expl),_) /* ARRAY_EQUATION */
      equation
        lst3 = Util.listMap1(expl, incidenceRowExp, vars);
        res = Util.listFlatten(lst3);
      then
        res;
    case (vars,BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e),_) /* SOLVED_EQUATION */
      equation
        lst1 = incidenceRowExp(DAE.CREF(cr,DAE.ET_REAL()), vars);
        lst2 = incidenceRowExp(e, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,BackendDAE.RESIDUAL_EQUATION(exp = e),_) /* RESIDUAL_EQUATION */
      equation
        res = incidenceRowExp(e, vars);
      then
        res;
    case (vars,BackendDAE.WHEN_EQUATION(whenEquation = we as BackendDAE.WHEN_EQ(index=wc_index)),wc) /* WHEN_EQUATION */
      equation
        (cr,e2) = getWhenEquationExpr(we);
        e1 = DAE.CREF(cr,DAE.ET_OTHER());
        expl = getWhenCondition(wc,wc_index);
        lst3 = Util.listMap1(expl, incidenceRowExp, vars);
        lst1 = Util.listFlatten(lst3);
        lst2 = incidenceRowExp(e1, vars);
        res = listAppend(lst1, lst2);
        lst1 = incidenceRowExp(e2, vars);
        res = listAppend(res, lst1);
      then
        res;
    case (vars,BackendDAE.ALGORITHM(index = indx,in_ = inputs,out = outputs),_)
      /* ALGORITHM For now assume that algorithm will be solvable for correct
         variables. I.e. find all variables in algorithm and add to lst.
         If algorithm later on needs to be inverted, i.e. solved for
         different variables than calculated, a non linear solver or
         analysis of algorithm itself needs to be implemented.
      */
      local list<list<BackendDAE.Value>> lst1,lst2,res;
      equation
        lst1 = Util.listMap1(inputs, incidenceRowExp, vars);
        lst2 = Util.listMap1(outputs, incidenceRowExp, vars);
        res = listAppend(lst1, lst2);
        res_1 = Util.listFlatten(res);
      then
        res_1;
    case (vars,inEquation,_)
      local 
        String eqnstr;
      equation
        eqnstr = BackendDump.equationStr(inEquation);
        print("-DAELow.incidence_row failed for eqn: ");
        print(eqnstr);
        print("\n");
      then
        fail();
  end matchcontinue;
end incidenceRow;

protected function incidenceRowStmts
"function: incidenceRowStmts
  author: PA
  Helper function to incidenceRow, investigates statements for
  variables, returning variable indexes."
  input list<Algorithm.Statement> inAlgorithmStatementLst;
  input BackendDAE.Variables inVariables;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inAlgorithmStatementLst,inVariables)
    local
      list<BackendDAE.Value> lst1,lst2,lst3,res,lst3_1;
      DAE.ExpType tp;
      DAE.ComponentRef cr;
      DAE.Exp e,e1;
      list<Algorithm.Statement> rest,stmts;
      BackendDAE.Variables vars;
      list<DAE.Exp> expl;
      Algorithm.Else else_;

    case ({},_) then {};
    case ((DAE.STMT_ASSIGN(type_ = tp,exp1 = e1,exp = e) :: rest),vars)
      equation
        lst1 = incidenceRowStmts(rest, vars);
        lst2 = incidenceRowExp(e, vars);
        lst3 = incidenceRowExp(e1, vars);
        res = Util.listFlatten({lst1,lst2,lst3});
      then
        res;
    case ((DAE.STMT_TUPLE_ASSIGN(type_ = tp,expExpLst = expl,exp = e) :: rest),vars)
      local list<list<BackendDAE.Value>> lst3;
      equation
        lst1 = incidenceRowStmts(rest, vars);
        lst2 = incidenceRowExp(e, vars);
        lst3 = Util.listMap1(expl, incidenceRowExp, vars);
        lst3_1 = Util.listFlatten(lst3);
        res = Util.listFlatten({lst1,lst2,lst3_1});
      then
        res;
    case ((DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr,exp = e) :: rest),vars)
      equation
        lst1 = incidenceRowStmts(rest, vars);
        lst2 = incidenceRowExp(e, vars);
        lst3 = incidenceRowExp(DAE.CREF(cr,DAE.ET_OTHER()), vars);
        res = Util.listFlatten({lst1,lst2,lst3});
      then
        res;
    case ((DAE.STMT_IF(exp = e,statementLst = stmts,else_ = else_) :: rest),vars)
      equation
        print("incidence_row_stmts on IF not implemented\n");
      then
        {};
    case ((DAE.STMT_FOR(type_ = _) :: rest),vars)
      equation
        print("incidence_row_stmts on FOR not implemented\n");
      then
        {};
    case ((DAE.STMT_WHILE(exp = _) :: rest),vars)
      equation
        print("incidence_row_stmts on WHILE not implemented\n");
      then
        {};
    case ((DAE.STMT_WHEN(exp = e) :: rest),vars)
      equation
        print("incidence_row_stmts on WHEN not implemented\n");
      then
        {};
    case ((DAE.STMT_ASSERT(cond = _) :: rest),vars)
      equation
        print("incidence_row_stmts on ASSERT not implemented\n");
      then
        {};
  end matchcontinue;
end incidenceRowStmts;

protected function incidenceRowExp
"function: incidenceRowExp
  author: PA

  Helper function to incidenceRow, investigates expressions for
  variables, returning variable indexes."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inExp,inVariables)
    local
      list<BackendDAE.Value> p,p_1,s1,s2,res,s3,lst_1;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      DAE.Exp e1,e2,e,e3;
      list<list<BackendDAE.Value>> lst;
      list<DAE.Exp> expl;
      list<BackendDAE.Var> varslst;

    case (DAE.CREF(componentRef = cr),vars)
      equation
        (varslst,p) = getVar(cr, vars);
        p_1 = incidenceRowExp1(varslst,p,true);
      then
        p_1;
    case (DAE.BINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (DAE.UNARY(exp = e),vars)
      equation
        res = incidenceRowExp(e, vars);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (DAE.LUNARY(exp = e),vars)
      equation
        res = incidenceRowExp(e, vars);
      then
        res;
    case (DAE.RELATION(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars) /* if expressions. */
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        s3 = incidenceRowExp(e3, vars);
        res = Util.listFlatten({s1,s2,s3});
      then
        res;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars)
      equation
        (varslst,p) = getVar(cr, vars);
        p_1 = incidenceRowExp1(varslst,p,false);
      then
        p_1;        
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars)
      equation
        cr = ComponentReference.makeCrefQual("$DER", DAE.ET_REAL(), {}, cr);
        (varslst,p) = getVar(cr, vars);
        p_1 = incidenceRowExp1(varslst,p,false);
      then
        p_1;
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"),expLst = {DAE.CREF(componentRef = cr)}),vars) then {};  /* pre(v) is considered a known variable */
    case (DAE.CALL(expLst = expl),vars)
      equation
        lst = Util.listMap1(expl, incidenceRowExp, vars);
        res = Util.listFlatten(lst);
      then
        res;
    case (DAE.ARRAY(array = expl),vars)
      equation
        lst = Util.listMap1(expl, incidenceRowExp, vars);
        lst_1 = Util.listFlatten(lst);
      then
        lst_1;
    case (DAE.MATRIX(scalar = expl),vars)
      local list<list<tuple<DAE.Exp, Boolean>>> expl;
      equation
        res = incidenceRowMatrixExp(expl, vars);
      then
        res;
    case (DAE.TUPLE(PR = expl),vars)
      equation
        lst = Util.listMap1(expl, incidenceRowExp, vars);
        lst_1 = Util.listFlatten(lst);
        //print("incidence_row_exp TUPLE not impl. yet.");
      then
        lst_1;
    case (DAE.CAST(exp = e),vars)
      equation
        res = incidenceRowExp(e, vars);
      then
        res;
    case (DAE.ASUB(exp = e),vars)
      equation
        res = incidenceRowExp(e, vars);
      then
        res;
    case (DAE.REDUCTION(expr = e1,range = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (_,_) then {};
  end matchcontinue;
end incidenceRowExp;

protected function incidenceRowExp1
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> inIntegerLst;
  input Boolean notinder;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inVarLst,inIntegerLst,notinder)
    local
       list<BackendDAE.Var> rest;
       BackendDAE.Var v;
       list<Integer> irest,res;
       Integer i,i1;  
       Boolean b;
    case ({},{},_) then {};   
    /*If variable x is a state, der(x) is a variable in incidence matrix,
         x is inserted as negative value, since it is needed by debugging and
         index reduction using dummy derivatives */ 
    case (BackendDAE.VAR(varKind = BackendDAE.STATE()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
        i1 = Util.if_(b,-i,i);
      then (i1::res);
    case (BackendDAE.VAR(varKind = BackendDAE.STATE_DER()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);        
    case (BackendDAE.VAR(varKind = BackendDAE.VARIABLE()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);                
    case (_ :: rest,_::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b);  
      then res;
  end matchcontinue;      
end incidenceRowExp1;

protected function incidenceRowMatrixExp
"function: incidenceRowMatrixExp
  author: PA
  Traverses matrix expressions for building incidence matrix."
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input BackendDAE.Variables inVariables;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inTplExpExpBooleanLstLst,inVariables)
    local
      list<DAE.Exp> expl_1;
      list<list<BackendDAE.Value>> res1;
      list<BackendDAE.Value> res2,res1_1,res;
      list<tuple<DAE.Exp, Boolean>> expl;
      list<list<tuple<DAE.Exp, Boolean>>> es;
      BackendDAE.Variables vars;
    case ({},_) then {};
    case ((expl :: es),vars)
      equation
        expl_1 = Util.listMap(expl, Util.tuple21);
        res1 = Util.listMap1(expl_1, incidenceRowExp, vars);
        res2 = incidenceRowMatrixExp(es, vars);
        res1_1 = Util.listFlatten(res1);
        res = listAppend(res1_1, res2);
      then
        res;
  end matchcontinue;
end incidenceRowMatrixExp;

public function emptyVars
"function: emptyVars
  author: PA
  Returns a Variable datastructure that is empty.
  Using the bucketsize 10000 and array size 1000."
  output BackendDAE.Variables outVariables;
  array<list<BackendDAE.CrefIndex>> arr;
  array<list<BackendDAE.StringIndex>> arr2;
  list<Option<BackendDAE.Var>> lst;
  array<Option<BackendDAE.Var>> emptyarr;
algorithm
  arr := arrayCreate(10, {});
  arr2 := arrayCreate(10, {});
  lst := Util.listFill(NONE(), 10);
  emptyarr := listArray(lst);
  outVariables := BackendDAE.VARIABLES(arr,arr2,BackendDAE.VARIABLE_ARRAY(0,10,emptyarr),10,0);
end emptyVars;

public function mergeVars
"function: mergeVars
  author: PA
  Takes two sets of BackendDAE.Variables and merges them. The variables of the
  first argument takes precedence over the second set, i.e. if a
  variable name exists in both sets, the variable definition from
  the first set is used."
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables inVariables2;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inVariables1,inVariables2)
    local
      list<BackendDAE.Var> varlst;
      BackendDAE.Variables vars1_1,vars1,vars2;
    case (vars1,vars2)
      equation
        varlst = varList(vars2);
        vars1_1 = Util.listFold(varlst, addVar, vars1);
      then
        vars1_1;
    case (_,_)
      equation
        print("-merge_vars failed\n");
      then
        fail();
  end matchcontinue;
end mergeVars;

public function addVar
"function: addVar
  author: PA
  Add a variable to Variables.
  If the variable already exists, the function updates the variable."
  input BackendDAE.Var inVar;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inVar,inVariables)
    local
      BackendDAE.Value hval,indx,newpos,n_1,hvalold,indxold,bsize,n,indx_1;
      BackendDAE.VariableArray varr_1,varr;
      list<BackendDAE.CrefIndex> indexes;
      array<list<BackendDAE.CrefIndex>> hashvec_1,hashvec;
      String name_str;
      list<BackendDAE.StringIndex> indexexold;
      array<list<BackendDAE.StringIndex>> oldhashvec_1,oldhashvec;
      BackendDAE.Var v,newv;
      DAE.ComponentRef cr,name;
      DAE.Flow flowPrefix;
      BackendDAE.Variables vars;
    /* adrpo: ignore records!
    case ((v as BackendDAE.VAR(varName = cr,origVarName = name,flowPrefix = flowPrefix, varType = DAE.COMPLEX(_,_))),
          (vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
    then
      vars;
    */
    case ((v as BackendDAE.VAR(varName = cr,flowPrefix = flowPrefix)),(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        failure((_,_) = getVar(cr, vars)) "adding when not existing previously" ;
        hval = hashComponentRef(cr);
        indx = intMod(hval, bsize);
        newpos = vararrayLength(varr);
        varr_1 = vararrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, (BackendDAE.CREFINDEX(cr,newpos) :: indexes));
        n_1 = vararrayLength(varr_1);
        name_str = ComponentReference.printComponentRefStr(cr);
        hvalold = hashString(name_str);
        indxold = intMod(hvalold, bsize);
        indexexold = oldhashvec[indxold + 1];
        oldhashvec_1 = arrayUpdate(oldhashvec, indxold + 1,
          (BackendDAE.STRINGINDEX(name_str,newpos) :: indexexold));
      then
        BackendDAE.VARIABLES(hashvec_1,oldhashvec_1,varr_1,bsize,n_1);

    case ((newv as BackendDAE.VAR(varName = cr,flowPrefix = flowPrefix)),(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        (_,{indx}) = getVar(cr, vars) "adding when already present => Updating value" ;
        indx_1 = indx - 1;
        varr_1 = vararraySetnth(varr, indx_1, newv);
      then
        BackendDAE.VARIABLES(hashvec,oldhashvec,varr_1,bsize,n);

    case (_,_)
      equation
        print("-add_var failed\n");
      then
        fail();
  end matchcontinue;
end addVar;

public function vararrayLength
"function: vararrayLength
  author: PA
  Returns the number of variable in the BackendDAE.VariableArray"
  input BackendDAE.VariableArray inVariableArray;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inVariableArray)
    local BackendDAE.Value n;
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n)) then n;
  end matchcontinue;
end vararrayLength;

public function vararrayAdd
"function: vararrayAdd
  author: PA
  Adds a variable last to the BackendDAE.VariableArray, increasing array size
  if no space left by factor 1.4"
  input BackendDAE.VariableArray inVariableArray;
  input BackendDAE.Var inVar;
  output BackendDAE.VariableArray outVariableArray;
algorithm
  outVariableArray := matchcontinue (inVariableArray,inVar)
    local
      BackendDAE.Value n_1,n,size,expandsize,expandsize_1,newsize;
      array<Option<BackendDAE.Var>> arr_1,arr,arr_2;
      BackendDAE.Var v;
      Real rsize,rexpandsize;
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),v)
      equation
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(v));
      then
        BackendDAE.VARIABLE_ARRAY(n_1,size,arr_1);
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),v)
      equation
        (n < size) = false "Do NOT have splace to add array elt. Expand with factor 1.4" ;
        rsize = intReal(size);
        rexpandsize = rsize*. 0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr,NONE());
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(v));
      then
        BackendDAE.VARIABLE_ARRAY(n_1,newsize,arr_2);
    case (_,_)
      equation
        print("-vararray_add failed\n");
      then
        fail();
  end matchcontinue;
end vararrayAdd;

public function vararraySetnth
"function: vararraySetnth
  author: PA
  Set the n:th variable in the BackendDAE.VariableArray to v.
 inputs:  (BackendDAE.VariableArray, int /* n */, BackendDAE.Var /* v */)
 outputs: BackendDAE.VariableArray ="
  input BackendDAE.VariableArray inVariableArray;
  input Integer inInteger;
  input BackendDAE.Var inVar;
  output BackendDAE.VariableArray outVariableArray;
algorithm
  outVariableArray := matchcontinue (inVariableArray,inInteger,inVar)
    local
      array<Option<BackendDAE.Var>> arr_1,arr;
      BackendDAE.Value n,size,pos;
      BackendDAE.Var v;

    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),pos,v)
      equation
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, SOME(v));
      then
        BackendDAE.VARIABLE_ARRAY(n,size,arr_1);

    case (_,_,_)
      equation
        print("-vararray_setnth failed\n");
      then
        fail();
  end matchcontinue;
end vararraySetnth;

public function vararrayNth
"function: vararrayNth
 author: PA
 Retrieve the n:th BackendDAE.Var from BackendDAE.VariableArray, index from 0..n-1.
 inputs:  (BackendDAE.VariableArray, int /* n */)
 outputs: Var"
  input BackendDAE.VariableArray inVariableArray;
  input Integer inInteger;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inVariableArray,inInteger)
    local
      BackendDAE.Var v;
      BackendDAE.Value n,pos,len;
      array<Option<BackendDAE.Var>> arr;
      String ps,lens,ns;
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,varOptArr = arr),pos)
      equation
        (pos < n) = true;
        SOME(v) = arr[pos + 1];
      then
        v;
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,varOptArr = arr),pos)
      equation
        (pos < n) = true;
        NONE() = arr[pos + 1];
        print("vararray_nth has NONE!!!\n");
      then
        fail();
  end matchcontinue;
end vararrayNth;

protected function replaceVar
"function: replaceVar
  author: PA
  Takes a list<BackendDAE.Var> and a BackendDAE.Var and replaces the
  var with the same ComponentRef in BackendDAE.Var list with Var"
  input list<BackendDAE.Var> inVarLst;
  input BackendDAE.Var inVar;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst := matchcontinue (inVarLst,inVar)
    local
      DAE.ComponentRef cr1,cr2;
      DAE.Flow flow1,flow2,flowPrefix;
      list<BackendDAE.Var> vs,vs_1;
      BackendDAE.Var v,repl;

    case ({},_) then {};
    case ((BackendDAE.VAR(varName = cr1,flowPrefix = flow1) :: vs),(v as BackendDAE.VAR(varName = cr2,flowPrefix = flow2)))
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr1, cr2);
      then
        (v :: vs);
    case ((v :: vs),(repl as BackendDAE.VAR(varName = cr2,flowPrefix = flowPrefix)))
      equation
        vs_1 = replaceVar(vs, repl);
      then
        (v :: vs_1);
  end matchcontinue;
end replaceVar;

protected function hashComponentRef
"function: hashComponentRef
  author: PA
  Calculates a hash value for DAE.ComponentRef"
  input DAE.ComponentRef cr;
  output Integer res;
  String crstr;
algorithm
  crstr := ComponentReference.printComponentRefStr(cr);
  res := hashString(crstr);
end hashComponentRef;

protected function hashString
"function: hashString
  author: PA
  Calculates a hash value of a string"
  input String str;
  output Integer res;
algorithm
  res := System.hash(str);
end hashString;

protected function hashChars
"function: hashChars
  author: PA
  Calculates a hash value for a list of chars"
  input list<String> inStringLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inStringLst)
    local
      BackendDAE.Value c2,c1;
      String c;
      list<String> cs;
    case ({}) then 0;
    case ((c :: cs))
      equation
        c2 = stringCharInt(c);
        c1 = hashChars(cs);
      then
        c1 + c2;
  end matchcontinue;
end hashChars;

public function getVarAt
"function: getVarAt
  author: PA
  Return variable at a given position, enumerated from 1..n"
  input BackendDAE.Variables inVariables;
  input Integer inInteger;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inVariables,inInteger)
    local
      BackendDAE.Value pos,n;
      BackendDAE.Var v;
      BackendDAE.VariableArray vararr;
    case (BackendDAE.VARIABLES(varArr = vararr),n)
      equation
        pos = n - 1;
        v = vararrayNth(vararr, pos);
      then
        v;
    case (BackendDAE.VARIABLES(varArr = vararr),n)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "DAELow.getVarAt failed to get the variable at index:" +& intString(n));
      then
        fail();
  end matchcontinue;
end getVarAt;

public function getVar
"function: getVar
  author: PA
  Return a variable(s) and its index(es) in the vector.
  The indexes is enumerated from 1..n
  Normally a variable has only one index, but in case of an array variable
  it may have several indexes and several scalar variables,
  therefore a list of variables and a list of  indexes is returned.
  inputs:  (DAE.ComponentRef, BackendDAE.Variables)
  outputs: (Var list, int list /* indexes */)"
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := matchcontinue (inComponentRef,inVariables)
    local
      BackendDAE.Var v;
      BackendDAE.Value indx;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      list<BackendDAE.Value> indxs;
      list<BackendDAE.Var> vLst;

    case (cr,vars)
      equation
        (v,indx) = getVar2(cr, vars) "if scalar found, return it" ;
      then
        ({v},{indx});
    case (cr,vars) /* check if array */
      equation
        (vLst,indxs) = getArrayVar(cr, vars);
      then
        (vLst,indxs);
    /* failure
    case (cr,vars)
      equation
        Debug.fprintln("daelow", "- DAELow.getVar failed on component reference: " +& ComponentReference.printComponentRefStr(cr));
      then
        fail();
    */
  end matchcontinue;
end getVar;

protected function getVar2
"function: getVar2
  author: PA
  Helper function to getVar, checks one scalar variable"
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Var outVar;
  output Integer outInteger;
algorithm
  (outVar,outInteger) := matchcontinue (inComponentRef,inVariables)
    local
      BackendDAE.Value hval,hashindx,indx,indx_1,bsize,n;
      list<BackendDAE.CrefIndex> indexes;
      BackendDAE.Var v;
      DAE.ComponentRef cr2,cr;
      DAE.Flow flowPrefix;
      array<list<BackendDAE.CrefIndex>> hashvec;
      array<list<BackendDAE.StringIndex>> oldhashvec;
      BackendDAE.VariableArray varr;
      String str;
    case (cr,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        hval = hashComponentRef(cr);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr, indexes);
        ((v as BackendDAE.VAR(varName = cr2, flowPrefix = flowPrefix))) = vararrayNth(varr, indx);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        indx_1 = indx + 1;
      then
        (v,indx_1);
  end matchcontinue;
end getVar2;

protected function getArrayVar
"function: getArrayVar
  author: PA
  Helper function to get_var, checks one array variable.
  I.e. get_array_var(v,<vars>) will for an array v{3} return
  { v{1},v{2},v{3} }"
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := matchcontinue (inComponentRef,inVariables)
    local
      DAE.ComponentRef cr_1,cr2,cr;
      BackendDAE.Value hval,hashindx,indx,bsize,n;
      list<BackendDAE.CrefIndex> indexes;
      BackendDAE.Var v;
      list<DAE.Subscript> instdims;
      DAE.Flow flowPrefix;
      list<BackendDAE.Var> vs;
      list<BackendDAE.Value> indxs;
      BackendDAE.Variables vars;
      array<list<BackendDAE.CrefIndex>> hashvec;
      array<list<BackendDAE.StringIndex>> oldhashvec;
      BackendDAE.VariableArray varr;
    case (cr,(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        cr_1 = ComponentReference.subscriptCref(cr, {DAE.INDEX(DAE.ICONST(1))}) "one dimensional arrays" ;
        hval = hashComponentRef(cr_1);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr_1, indexes);
        ((v as BackendDAE.VAR(varName = cr2, arryDim = instdims, flowPrefix = flowPrefix))) = vararrayNth(varr, indx);
        true = ComponentReference.crefEqualNoStringCompare(cr_1, cr2);
        (vs,indxs) = getArrayVar2(instdims, cr, vars);
      then
        (vs,indxs);
    case (cr,(vars as BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))) /* two dimensional arrays */
      equation
        cr_1 = ComponentReference.subscriptCref(cr, {DAE.INDEX(DAE.ICONST(1)),DAE.INDEX(DAE.ICONST(1))});
        hval = hashComponentRef(cr_1);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr_1, indexes);
        ((v as BackendDAE.VAR(varName = cr2, arryDim = instdims, flowPrefix = flowPrefix))) = vararrayNth(varr, indx);
        true = ComponentReference.crefEqualNoStringCompare(cr_1, cr2);
        (vs,indxs) = getArrayVar2(instdims, cr, vars);
      then
        (vs,indxs);
  end matchcontinue;
end getArrayVar;

protected function getArrayVar2
"function: getArrayVar2
  author: PA
  Helper function to getArrayVar.
  Note: Only implemented for arrays of dimension 1 and 2.
  inputs:  (DAE.InstDims, /* array_inst_dims */
              DAE.ComponentRef, /* array_var_name */
              Variables)
  outputs: (Var list /* arrays scalar vars */,
              int list /* arrays scalar indxs */)"
  input DAE.InstDims inInstDims;
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := matchcontinue (inInstDims,inComponentRef,inVariables)
    local
      list<BackendDAE.Value> indx_lst,indxs_1,indx_lst1,indx_lst2;
      list<list<BackendDAE.Value>> indx_lstlst,indxs,indx_lstlst1,indx_lstlst2;
      list<list<DAE.Subscript>> subscripts_lstlst,subscripts_lstlst1,subscripts_lstlst2,subscripts;
      list<BackendDAE.Key> scalar_crs;
      list<list<BackendDAE.Var>> vs;
      list<BackendDAE.Var> vs_1;
      BackendDAE.Value i1,i2;
      DAE.ComponentRef arr_cr;
      BackendDAE.Variables vars;
    case ({DAE.INDEX(exp = DAE.ICONST(integer = i1))},arr_cr,vars)
      equation
        indx_lst = Util.listIntRange(i1);
        indx_lstlst = Util.listMap(indx_lst, Util.listCreate);
        subscripts_lstlst = Util.listMap(indx_lstlst, Exp.intSubscripts);
        scalar_crs = Util.listMap1r(subscripts_lstlst, ComponentReference.subscriptCref, arr_cr);
        (vs,indxs) = Util.listMap12(scalar_crs, getVar, vars);
        vs_1 = Util.listFlatten(vs);
        indxs_1 = Util.listFlatten(indxs);
      then
        (vs_1,indxs_1);
    case ({DAE.INDEX(exp = DAE.ICONST(integer = i1)),DAE.INDEX(exp = DAE.ICONST(integer = i2))},arr_cr,vars)
      equation
        indx_lst1 = Util.listIntRange(i1);
        indx_lstlst1 = Util.listMap(indx_lst1, Util.listCreate);
        subscripts_lstlst1 = Util.listMap(indx_lstlst1, Exp.intSubscripts);
        indx_lst2 = Util.listIntRange(i2);
        indx_lstlst2 = Util.listMap(indx_lst2, Util.listCreate);
        subscripts_lstlst2 = Util.listMap(indx_lstlst2, Exp.intSubscripts);
        subscripts = subscript2dCombinations(subscripts_lstlst1, subscripts_lstlst2) "make all possbible combinations to get all 2d indexes" ;
        scalar_crs = Util.listMap1r(subscripts, ComponentReference.subscriptCref, arr_cr);
        (vs,indxs) = Util.listMap12(scalar_crs, getVar, vars);
        vs_1 = Util.listFlatten(vs);
        indxs_1 = Util.listFlatten(indxs);
      then
        (vs_1,indxs_1);
    // adrpo: cr can be of form cr.cr.cr[2].cr[3] which means that it has type dimension [2,3] but we only need to walk [3]
    case ({_,DAE.INDEX(exp = DAE.ICONST(integer = i1))},arr_cr,vars)
      equation
        // see if cr contains ANY array dimensions. if it doesn't this case is not valid!
        true = ComponentReference.crefHaveSubs(arr_cr);
        indx_lst = Util.listIntRange(i1);
        indx_lstlst = Util.listMap(indx_lst, Util.listCreate);
        subscripts_lstlst = Util.listMap(indx_lstlst, Exp.intSubscripts);
        scalar_crs = Util.listMap1r(subscripts_lstlst, ComponentReference.subscriptCref, arr_cr);
        (vs,indxs) = Util.listMap12(scalar_crs, getVar, vars);
        vs_1 = Util.listFlatten(vs);
        indxs_1 = Util.listFlatten(indxs);
      then
        (vs_1,indxs_1);
  end matchcontinue;
end getArrayVar2;

protected function subscript2dCombinations
"function: susbscript_2d_combinations
  This function takes two lists of list of subscripts and combines them in
  all possible combinations. This is used when finding all indexes of a 2d
  array.
  For instance, subscript2dCombinations({{a},{b},{c}},{{x},{y},{z}})
  => {{a,x},{a,y},{a,z},{b,x},{b,y},{b,z},{c,x},{c,y},{c,z}}
  inputs:  (DAE.Subscript list list /* dim1 subs */,
              DAE.Subscript list list /* dim2 subs */)
  outputs: (DAE.Subscript list list)"
  input list<list<DAE.Subscript>> inExpSubscriptLstLst1;
  input list<list<DAE.Subscript>> inExpSubscriptLstLst2;
  output list<list<DAE.Subscript>> outExpSubscriptLstLst;
algorithm
  outExpSubscriptLstLst := matchcontinue (inExpSubscriptLstLst1,inExpSubscriptLstLst2)
    local
      list<list<DAE.Subscript>> lst1,lst2,res,ss,ss2;
      list<DAE.Subscript> s1;
    case ({},_) then {};
    case ((s1 :: ss),ss2)
      equation
        lst1 = subscript2dCombinations2(s1, ss2);
        lst2 = subscript2dCombinations(ss, ss2);
        res = listAppend(lst1, lst2);
      then
        res;
  end matchcontinue;
end subscript2dCombinations;

protected function subscript2dCombinations2
  input list<DAE.Subscript> inExpSubscriptLst;
  input list<list<DAE.Subscript>> inExpSubscriptLstLst;
  output list<list<DAE.Subscript>> outExpSubscriptLstLst;
algorithm
  outExpSubscriptLstLst := matchcontinue (inExpSubscriptLst,inExpSubscriptLstLst)
    local
      list<list<DAE.Subscript>> lst1,ss2;
      list<DAE.Subscript> elt1,ss,s2;
    case (_,{}) then {};
    case (ss,(s2 :: ss2))
      equation
        lst1 = subscript2dCombinations2(ss, ss2);
        elt1 = listAppend(ss, s2);
      then
        (elt1 :: lst1);
  end matchcontinue;
end subscript2dCombinations2;

public function existsVar
"function: existsVar
  author: PA
  Return true if a variable exists in the vector"
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef,inVariables)
    local
      BackendDAE.Value hval,hashindx,indx,bsize,n;
      list<BackendDAE.CrefIndex> indexes;
      BackendDAE.Var v;
      DAE.ComponentRef cr2,cr;
      array<list<BackendDAE.CrefIndex>> hashvec;
      array<list<BackendDAE.StringIndex>> oldhashvec;
      BackendDAE.VariableArray varr;
      String str;
    case (cr,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        hval = hashComponentRef(cr);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr, indexes);
        ((v as BackendDAE.VAR(varName = cr2))) = vararrayNth(varr, indx);
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
      then
        true;
    case (cr,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        hval = hashComponentRef(cr);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr, indexes);
        failure((_) = vararrayNth(varr, indx));
        print("could not found variable, cr:");
        str = ComponentReference.printComponentRefStr(cr);
        print(str);
        print("\n");
      then
        false;
    case (_,_) then false;
  end matchcontinue;
end existsVar;

public function getVarUsingName
"function: getVarUsingName
  author: lucian
  Return a variable and its index in the vector.
  The index is enumerated from 1..n"
  input String inString;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Var outVar;
  output Integer outInteger;
algorithm
  (outVar,outInteger) := matchcontinue (inString,inVariables)
    local
      BackendDAE.Value hval,hashindx,indx,indx_1,bsize,n;
      list<BackendDAE.StringIndex> indexes;
      BackendDAE.Var v;
      DAE.ComponentRef cr2,name;
      DAE.Flow flowPrefix;
      String name_str,cr;
      array<list<BackendDAE.CrefIndex>> hashvec;
      array<list<BackendDAE.StringIndex>> oldhashvec;
      BackendDAE.VariableArray varr;
    case (cr,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        hval = hashString(cr);
        hashindx = intMod(hval, bsize);
        indexes = oldhashvec[hashindx + 1];
        indx = getVarUsingName2(cr, indexes);
        ((v as BackendDAE.VAR(varName = cr2))) = vararrayNth(varr, indx);
        name_str = ComponentReference.printComponentRefStr(cr2);
        true = stringEqual(name_str, cr);
        indx_1 = indx + 1;
      then
        (v,indx_1);
  end matchcontinue;
end getVarUsingName;

public function setVarKind
"function setVarKind
  author: PA
  Sets the BackendDAE.VarKind of a variable"
  input BackendDAE.Var inVar;
  input BackendDAE.VarKind inVarKind;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inVar,inVarKind)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind,new_kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind,st;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      BackendDAE.Value i;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;

    case (BackendDAE.VAR(varName = cr,
              varKind = kind,
              varDirection = dir,
              varType = tp,
              bindExp = bind,
              bindValue = v,
              arryDim = dim,
              index = i,
              source = source,
              values = attr,
              comment = comment,
              flowPrefix = flowPrefix,
              streamPrefix = streamPrefix),new_kind)
    then BackendDAE.VAR(cr,new_kind,dir,tp,bind,v,dim,i,source,attr,comment,flowPrefix,streamPrefix);
  end matchcontinue;
end setVarKind;

public function setVarIndex
"function setVarKind
  author: PA
  Sets the BackendDAE.VarKind of a variable"
  input BackendDAE.Var inVar;
  input BackendDAE.Value inVarIndex;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inVar,inVarIndex)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind,new_kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind,st;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      BackendDAE.Value i,new_i;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;

    case (BackendDAE.VAR(varName = cr,
              varKind = kind,
              varDirection = dir,
              varType = tp,
              bindExp = bind,
              bindValue = v,
              arryDim = dim,
              index = i,
              source = source,
              values = attr,
              comment = comment,
              flowPrefix = flowPrefix,
              streamPrefix = streamPrefix),new_i)
    then BackendDAE.VAR(cr,kind,dir,tp,bind,v,dim,new_i,source,attr,comment,flowPrefix,streamPrefix);
  end matchcontinue;
end setVarIndex;

protected function getVar3
"function: getVar3
  author: PA
  Helper function to getVar"
  input DAE.ComponentRef inComponentRef;
  input list<BackendDAE.CrefIndex> inCrefIndexLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inComponentRef,inCrefIndexLst)
    local
      DAE.ComponentRef cr,cr2;
      BackendDAE.Value v,res;
      list<BackendDAE.CrefIndex> vs;
    case (cr,{})
      equation
        //Debug.fprint("failtrace", "-DAELow.getVar3 failed on:" +& ComponentReference.printComponentRefStr(cr) +& "\n");
      then
        fail();
    case (cr,(BackendDAE.CREFINDEX(cref = cr2,index = v) :: _))
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
      then
        v;
    case (cr,(v :: vs))
      local BackendDAE.CrefIndex v;
      equation
        res = getVar3(cr, vs);
      then
        res;
  end matchcontinue;
end getVar3;

protected function getVarUsingName2
"function: getVarUsingName2
  author: PA
  Helper function to getVarUsingName"
  input String inString;
  input list<BackendDAE.StringIndex> inStringIndexLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inString,inStringIndexLst)
    local
      String cr,cr2;
      BackendDAE.Value v,res;
      list<BackendDAE.StringIndex> vs;
    case (cr,(BackendDAE.STRINGINDEX(str = cr2,index = v) :: _))
      equation
        true = stringEqual(cr, cr2);
      then
        v;
    case (cr,(v :: vs))
      local BackendDAE.StringIndex v;
      equation
        res = getVarUsingName2(cr, vs);
      then
        res;
  end matchcontinue;
end getVarUsingName2;

protected function deleteVar
"function: deleteVar
  author: PA
  Deletes a variable from Variables. This is an expensive operation
  since we need to create a new binary tree with new indexes as well
  as a new compacted vector of variables."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inComponentRef,inVariables)
    local
      list<BackendDAE.Var> varlst,varlst_1;
      BackendDAE.Variables newvars,newvars_1;
      DAE.ComponentRef cr;
      array<list<BackendDAE.CrefIndex>> hashvec;
      array<list<BackendDAE.StringIndex>> oldhashvec;
      BackendDAE.VariableArray varr;
      BackendDAE.Value bsize,n;
    case (cr,BackendDAE.VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        varlst = vararrayList(varr);
        varlst_1 = deleteVar2(cr, varlst);
        newvars = emptyVars();
        newvars_1 = addVars(varlst_1, newvars);
      then
        newvars_1;
  end matchcontinue;
end deleteVar;

protected function deleteVar2
"function: deleteVar2
  author: PA
  Helper function to deleteVar.
  Deletes the var named DAE.ComponentRef from the BackendDAE.Variables list."
  input DAE.ComponentRef inComponentRef;
  input list<BackendDAE.Var> inVarLst;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst := matchcontinue (inComponentRef,inVarLst)
    local
      DAE.ComponentRef cr1,cr2;
      list<BackendDAE.Var> vs,vs_1;
      BackendDAE.Var v;
    case (_,{}) then {};
    case (cr1,(BackendDAE.VAR(varName = cr2) :: vs))
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr1, cr2);
      then
        vs;
    case (cr1,(v :: vs))
      equation
        vs_1 = deleteVar2(cr1, vs);
      then
        (v :: vs_1);
  end matchcontinue;
end deleteVar2;

public function transposeMatrix
"function: transposeMatrix
  author: PA
  Calculates the transpose of the incidence matrix,
  i.e. which equations each variable is present in."
  input BackendDAE.IncidenceMatrix m;
  output BackendDAE.IncidenceMatrixT mt;
  list<list<BackendDAE.Value>> mlst,mtlst;
algorithm
  mlst := arrayList(m);
  mtlst := transposeMatrix2(mlst);
  mt := listArray(mtlst);
end transposeMatrix;

protected function transposeMatrix2
"function: transposeMatrix2
  author: PA
  Helper function to transposeMatrix"
  input list<list<Integer>> inIntegerLstLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst := matchcontinue (inIntegerLstLst)
    local
      BackendDAE.Value neq;
      list<list<BackendDAE.Value>> mt,m;
    case (m)
      equation
        neq = listLength(m);
        mt = transposeMatrix3(m, neq, 0, {});
      then
        mt;
    case (_)
      equation
        print("#transpose_matrix2 failed\n");
      then
        fail();
  end matchcontinue;
end transposeMatrix2;

protected function transposeMatrix3
"function: transposeMatrix3
  author: PA
  Helper function to transposeMatrix2"
  input list<list<Integer>> inIntegerLstLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  input list<list<Integer>> inIntegerLstLst4;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst := matchcontinue (inIntegerLstLst1,inInteger2,inInteger3,inIntegerLstLst4)
    local
      BackendDAE.Value neq_1,eqno_1,neq,eqno;
      list<list<BackendDAE.Value>> mt_1,m,mt;
      list<BackendDAE.Value> row;
    case (_,0,_,_) then {};
    case (m,neq,eqno,mt)
      equation
        neq_1 = neq - 1;
        eqno_1 = eqno + 1;
        mt_1 = transposeMatrix3(m, neq_1, eqno_1, mt);
        row = transposeRow(m, eqno_1, 1);
      then
        (row :: mt_1);
  end matchcontinue;
end transposeMatrix3;

public function absIncidenceMatrix
"function absIncidenceMatrix
  author: PA
  Applies absolute value to all entries in the incidence matrix.
  This can be used when e.g. der(x) and x are considered the same variable."
  input BackendDAE.IncidenceMatrix m;
  output BackendDAE.IncidenceMatrix res;
  list<list<BackendDAE.Value>> lst,lst_1;
algorithm
  lst := arrayList(m);
  lst_1 := Util.listListMap(lst, int_abs);
  res := listArray(lst_1);
end absIncidenceMatrix;

public function varsIncidenceMatrix
"function: varsIncidenceMatrix
  author: PA
  Return all variable indices in the incidence
  matrix, i.e. all elements of the matrix."
  input BackendDAE.IncidenceMatrix m;
  output list<Integer> res;
  list<list<BackendDAE.Value>> mlst;
algorithm
  mlst := arrayList(m);
  res := Util.listFlatten(mlst);
end varsIncidenceMatrix;

protected function transposeRow
"function: transposeRow
  author: PA
  Helper function to transposeMatrix2.
  Input: BackendDAE.IncidenceMatrix (eqn => var)
  Input: row number (variable)
  Input: iterator (start with one)
  inputs:  (int list list, int /* row */,int /* iter */)
  outputs:  int list"
  input list<list<Integer>> inIntegerLstLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inIntegerLstLst1,inInteger2,inInteger3)
    local
      BackendDAE.Value eqn_1,varno,eqn,varno_1,eqnneg;
      list<BackendDAE.Value> res,m;
      list<list<BackendDAE.Value>> ms;
    case ({},_,_) then {};
    case ((m :: ms),varno,eqn)
      equation
        true = listMember(varno, m);
        eqn_1 = eqn + 1;
        res = transposeRow(ms, varno, eqn_1);
      then
        (eqn :: res);
    case ((m :: ms),varno,eqn)
      equation
        varno_1 = 0 - varno "Negative index present, state variable. list_member(varno,m) => false &" ;
        true = listMember(varno_1, m);
        eqnneg = 0 - eqn;
        eqn_1 = eqn + 1;
        res = transposeRow(ms, varno, eqn_1);
      then
        (eqnneg :: res);
    case ((m :: ms),varno,eqn)
      equation
        eqn_1 = eqn + 1 "not present at all" ;
        res = transposeRow(ms, varno, eqn_1);
      then
        res;
    case (_,_,_)
      equation
        print("-transpose_row failed\n");
      then
        fail();
  end matchcontinue;
end transposeRow;

public function matchingAlgorithm
"function: matchingAlgorithm
  author: PA
  This function performs the matching algorithm, which is the first
  part of sorting the equations into BLT (Block Lower Triangular) form.
  The matching algorithm finds a variable that is solved in each equation.
  But to also find out which equations forms a block of equations, the
  the second algorithm of the BLT sorting: strong components
  algorithm is run.
  This function returns the updated DAE in case of index reduction has
  added equations and variables, and the incidence matrix. The variable
  assignments is returned as a vector of variable indices, as well as its
  inverse, i.e. which equation a variable is solved in as a vector of
  equation indices.
  BackendDAE.MatchingOptions contain options given to the algorithm.
    - if index reduction should be used or not.
    - if the equation system is allowed to be under constrained or not
      which is used when generating code for initial equations.

  inputs:  (DAELow,IncidenceMatrix, BackendDAE.IncidenceMatrixT, MatchingOptions)
  outputs: (int vector /* vector of equation indices */ ,
              int vector /* vector of variable indices */,
              DAELow,IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input DAE.FunctionTree inFunctions;
  output array<Integer> outIntegerArray1;
  output array<Integer> outIntegerArray2;
  output BackendDAE.DAELow outDAELow3;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix4;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT5;
algorithm
  (outIntegerArray1,outIntegerArray2,outDAELow3,outIncidenceMatrix4,outIncidenceMatrixT5) :=
  matchcontinue (inDAELow,inIncidenceMatrix,inIncidenceMatrixT,inMatchingOptions,inFunctions)
    local
      BackendDAE.Value nvars,neqns,memsize;
      String ns,ne;
      BackendDAE.Assignments assign1,assign2,ass1,ass2;
      BackendDAE.DAELow dae,dae_1,dae_2;
      BackendDAE.Variables v,kv,v_1,kv_1,vars,exv;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray e,re,ie,e_1,re_1,ie_1,eqns;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ev,einfo;
      array<list<BackendDAE.Value>> m,mt,m_1,mt_1;
      BackendDAE.BinTree s;
      list<BackendDAE.Equation> e_lst,re_lst,ie_lst,e_lst_1,re_lst_1,ie_lst_1;
      list<BackendDAE.MultiDimEquation> ae_lst,ae_lst1;
      array<BackendDAE.Value> vec1,vec2;
      BackendDAE.MatchingOptions match_opts;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.BinTree s;
      list<BackendDAE.WhenClause> whenclauses;
      list<BackendDAE.ZeroCrossing> zero_crossings;
      list<DAE.Algorithm> algs;
    /* fail case if daelow is empty */
    case ((dae as BackendDAE.DAELOW(orderedVars = vars,orderedEqs = eqns)),m,mt,match_opts,inFunctions)
      equation
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        (nvars == 0) = true;
        (neqns == 0) = true;
        vec1 = listArray({});
        vec2 = listArray({});
      then
        (vec1,vec2,dae,m,mt);
    case ((dae as BackendDAE.DAELOW(orderedVars = vars,orderedEqs = eqns)),m,mt,(match_opts as (_,_,BackendDAE.REMOVE_SIMPLE_EQN())),inFunctions)
      equation
        DAEEXT.clearDifferentiated();
        checkMatching(dae, match_opts);
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        ns = intString(nvars);
        ne = intString(neqns);
        (nvars > 0) = true;
        (neqns > 0) = true;
        memsize = nvars + nvars "Worst case, all eqns are differentiated once. Create nvars2 assignment elements" ;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,(dae as BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc)),m,mt,_,_) = matchingAlgorithm2(dae, m, mt, nvars, neqns, 1, assign1, assign2, match_opts,inFunctions,{},{});
        /* NOTE: Here it could be possible to run removeSimpleEquations again, since algebraic equations
        could potentially be removed after a index reduction has been done. However, removing equations here
        also require that e.g. zero crossings, array equations, etc. must be recalculated. */       
        s = statesDaelow(dae);
        e_lst = equationList(e);
        re_lst = equationList(re);
        ie_lst = equationList(ie);
        ae_lst = arrayList(ae);
        algs = arrayList(al);
        (v,kv,e_lst,re_lst,ie_lst,ae_lst,algs,av) = removeSimpleEquations(v,kv, e_lst, re_lst, ie_lst, ae_lst, algs, s); 
         BackendDAE.EVENT_INFO(whenClauseLst=whenclauses) = ev;
        (zero_crossings) = findZeroCrossings(v,kv,e_lst,ae_lst,whenclauses,algs);
        e = listEquation(e_lst);
        re = listEquation(re_lst);
        ie = listEquation(ie_lst);
        ae = listArray(ae_lst);    
        einfo = BackendDAE.EVENT_INFO(whenclauses,zero_crossings); 
        dae_1 = BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,einfo,eoc);   
        m_1 = incidenceMatrix(dae_1) "Rerun matching to get updated assignments and incidence matrices
                                    TODO: instead of rerunning: find out which equations are removed
                                    and remove those from assignments and incidence matrix." ;
        mt_1 = transposeMatrix(m_1);
        nvars = arrayLength(m_1);
        neqns = arrayLength(mt_1);
        memsize = nvars + nvars;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,dae_2,m,mt,_,_) = matchingAlgorithm2(dae_1, m_1, mt_1, nvars, neqns, 1, assign1, assign2, match_opts, inFunctions,{},{});
        vec1 = assignmentsVector(ass1);
        vec2 = assignmentsVector(ass2);
      then
        (vec1,vec2,dae_2,m,mt);

    case ((dae as BackendDAE.DAELOW(orderedVars = vars,orderedEqs = eqns)),m,mt,(match_opts as (_,_,BackendDAE.KEEP_SIMPLE_EQN())),inFunctions)
      equation
        checkMatching(dae, match_opts);
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        ns = intString(nvars);
        ne = intString(neqns);
        (nvars > 0) = true;
        (neqns > 0) = true;
        memsize = nvars + nvars "Worst case, all eqns are differentiated once. Create nvars2 assignment elements" ;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,dae,m,mt,_,_) = matchingAlgorithm2(dae, m, mt, nvars, neqns, 1, assign1, assign2, match_opts, inFunctions,{},{});
        vec1 = assignmentsVector(ass1);
        vec2 = assignmentsVector(ass2);
      then
        (vec1,vec2,dae,m,mt);
    case (_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "- DAELow.MatchingAlgorithm failed\n");
      then
        fail();        
  end matchcontinue;
end matchingAlgorithm;

protected function checkMatching
"function: checkMatching
  author: PA

  Checks that the matching is correct, i.e. that the number of variables
  is the same as the number of equations. If not, the function fails and
  prints an error message.
  If matching options indicate that underconstrained systems are ok, no
  check is performed."
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.MatchingOptions inMatchingOptions;
algorithm
  _ := matchcontinue (inDAELow,inMatchingOptions)
    local
      BackendDAE.Value esize,vars_size;
      BackendDAE.EquationArray eqns;
      String esize_str,vsize_str;
    case (_,(_,BackendDAE.ALLOW_UNDERCONSTRAINED(),_)) then ();
    case (BackendDAE.DAELOW(orderedVars = BackendDAE.VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
      equation
        esize = equationSize(eqns);
        (esize == vars_size) = true;
      then
        ();
    case (BackendDAE.DAELOW(orderedVars = BackendDAE.VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
      equation
        esize = equationSize(eqns);
        (esize < vars_size) = true;
        esize = esize - 1;
        vars_size = vars_size - 1 "remove dummy var" ;
        esize_str = intString(esize) "remove dummy var" ;
        vsize_str = intString(vars_size);
        Error.addMessage(Error.UNDERDET_EQN_SYSTEM, {esize_str,vsize_str});
      then
        fail();
    case (BackendDAE.DAELOW(orderedVars = BackendDAE.VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
      equation
        esize = equationSize(eqns);
        (esize > vars_size) = true;
        esize = esize - 1;
        vars_size = vars_size - 1 "remove dummy var" ;
        esize_str = intString(esize) "remove dummy var" ;
        vsize_str = intString(vars_size);
        Error.addMessage(Error.OVERDET_EQN_SYSTEM, {esize_str,vsize_str});
      then
        fail();
    case (_,_)
      equation
        Debug.fprint("failtrace", "- DAELow.checkMatching failed\n");
      then
        fail();
  end matchcontinue;
end checkMatching;

protected function assignmentsVector
"function: assignmentsVector
  author: PA
  Converts BackendDAE.Assignments to vector of int elements"
  input BackendDAE.Assignments inAssignments;
  output array<Integer> outIntegerArray;
algorithm
  outIntegerArray := matchcontinue (inAssignments)
    local
      array<BackendDAE.Value> newarr,newarr_1,arr;
      array<BackendDAE.Value> vec;
      BackendDAE.Value size;
    case (BackendDAE.ASSIGNMENTS(actualSize = size,arrOfIndices = arr))
      equation
        newarr = arrayCreate(size, 0);
        newarr_1 = Util.arrayNCopy(arr, newarr, size);
        vec = array_copy(newarr_1);
      then
        vec;
    case (_)
      equation
        print("- DAELow.assignmentsVector failed\n");
      then
        fail();
  end matchcontinue;
end assignmentsVector;

protected function assignmentsCreate
"function: assignmentsCreate
  author: PA
  Creates an assignment array of n elements, filled with value v
  inputs:  (int /* size */, int /* memsize */, int)
  outputs: => Assignments"
  input Integer n;
  input Integer memsize;
  input Integer v;
  output BackendDAE.Assignments outAssignments;
  list<BackendDAE.Value> lst;
  array<BackendDAE.Value> arr;
algorithm
  lst := Util.listFill(0, memsize);
  arr := listArray(lst) "  array_create(memsize,v) => arr &" ;
  outAssignments := BackendDAE.ASSIGNMENTS(n,memsize,arr);
end assignmentsCreate;

protected function assignmentsSetnth
"function: assignmentsSetnth
  author: PA
  Sets the n:nt assignment Value.
  inputs:  (Assignments, int /* n */, int /* value */)
  outputs:  Assignments"
  input BackendDAE.Assignments inAssignments1;
  input Integer inInteger2;
  input Integer inInteger3;
  output BackendDAE.Assignments outAssignments;
algorithm
  outAssignments := matchcontinue (inAssignments1,inInteger2,inInteger3)
    local
      array<BackendDAE.Value> arr;
      BackendDAE.Value s,ms,n,v;
    case (BackendDAE.ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),n,v)
      equation
        arr = arrayUpdate(arr, n + 1, v);
      then
        BackendDAE.ASSIGNMENTS(s,ms,arr);
    case (_,_,_)
      equation
        print("-assignments_setnth failed\n");
      then
        fail();
  end matchcontinue;
end assignmentsSetnth;

protected function assignmentsExpand
"function: assignmentsExpand
  author: PA
  Expands the assignments array with n values, initialized with zero.
  inputs:  (Assignments, int /* n */)
  outputs:  Assignments"
  input BackendDAE.Assignments inAssignments;
  input Integer inInteger;
  output BackendDAE.Assignments outAssignments;
algorithm
  outAssignments := matchcontinue (inAssignments,inInteger)
    local
      BackendDAE.Assignments ass,ass_1,ass_2;
      BackendDAE.Value n_1,n;
    case (ass,0) then ass;
    case (ass,n)
      equation
        true = n > 0;
        ass_1 = assignmentsAdd(ass, 0);
        n_1 = n - 1;
        ass_2 = assignmentsExpand(ass_1, n_1);
      then
        ass_2;
    case (ass,_)
      equation
        print("DAELow.assignmentsExpand: n should not be negative!");
      then
        fail();
  end matchcontinue;
end assignmentsExpand;

protected function assignmentsAdd
"function: assignmentsAdd
  author: PA
  Adds a value to the end of the assignments array. If memsize = actual size
  this means copying the whole array, expanding it size to fit the value
  Expansion is made by a factor 1.4. Otherwise, the element is inserted taking O(1) in
  insertion cost.
  inputs:  (Assignments, int /* value */)
  outputs:  Assignments"
  input BackendDAE.Assignments inAssignments;
  input Integer inInteger;
  output BackendDAE.Assignments outAssignments;
algorithm
  outAssignments := matchcontinue (inAssignments,inInteger)
    local
      Real msr,msr_1;
      BackendDAE.Value ms_1,s_1,ms_2,s,ms,v;
      array<BackendDAE.Value> arr_1,arr_2,arr;

    case (BackendDAE.ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),v)
      equation
        (s == ms) = true "Out of bounds, increase and copy." ;
        msr = intReal(ms);
        msr_1 = msr *. 0.4;
        ms_1 = realInt(msr_1);
        s_1 = s + 1;
        ms_2 = ms_1 + ms;
        arr_1 = Util.arrayExpand(ms_1, arr, 0);
        arr_2 = arrayUpdate(arr_1, s + 1, v);
      then
        BackendDAE.ASSIGNMENTS(s_1,ms_2,arr_2);

    case (BackendDAE.ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),v)
      equation
        arr_1 = arrayUpdate(arr, s + 1, v) "space available, increase size and insert element." ;
        s_1 = s + 1;
      then
        BackendDAE.ASSIGNMENTS(s_1,ms,arr_1);

    case (BackendDAE.ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),v)
      equation
        print("-assignments_add failed\n");
      then
        fail();
  end matchcontinue;
end assignmentsAdd;

protected function matchingAlgorithm2
"function: matchingAlgorithm2
  author: PA
  This is the outer loop of the matching algorithm
  The find_path algorithm is called for each equation/variable.
  inputs:  (DAELow,IncidenceMatrix, IncidenceMatrixT
             ,int /* number of vars */
             ,int /* number of eqns */
             ,int /* current var */
             ,Assignments  /* assignments, array of eqn indices */
             ,Assignments /* assignments, array of var indices */
             ,MatchingOptions) /* options for matching alg. */
  outputs: (Assignments, /* assignments, array of equation indices */
              Assignments, /* assignments, list of variable indices */
              DAELow, BackendDAE.IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.DAELow inDAELow1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  input BackendDAE.Assignments inAssignments7;
  input BackendDAE.Assignments inAssignments8;
  input BackendDAE.MatchingOptions inMatchingOptions9;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;  
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
  output BackendDAE.DAELow outDAELow3;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix4;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT5;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;  
algorithm
  (outAssignments1,outAssignments2,outDAELow3,outIncidenceMatrix4,outIncidenceMatrixT5,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inInteger6,inAssignments7,inAssignments8,inMatchingOptions9,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2,ass1_2,ass2_2;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value nv,nf,i,i_1,nv_1,nkv,nf_1,nvd;
      BackendDAE.MatchingOptions match_opts;
      BackendDAE.EquationArray eqns;
      BackendDAE.EquationConstraints eq_cons;
      BackendDAE.EquationReduction r_simple;
      list<BackendDAE.Value> eqn_lst,var_lst;
      String eqn_str,var_str;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1,derivedAlgs2;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1,derivedMultiEqn2;      

    case (dae,m,mt,nv,nf,i,ass1,ass2,_,_,derivedAlgs,derivedMultiEqn)
      equation
        (nv == i) = true;
        DAEEXT.initMarks(nv, nf);
        (ass1_1,ass2_1) = pathFound(m, mt, i, ass1, ass2) "eMark(i)=vMark(i)=false; eMark(i)=vMark(i)=false exit loop";
      then
        (ass1_1,ass2_1,dae,m,mt,derivedAlgs,derivedMultiEqn);

    case (dae,m,mt,nv,nf,i,ass1,ass2,match_opts,inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        i_1 = i + 1;
        DAEEXT.initMarks(nv, nf);
        (ass1_1,ass2_1) = pathFound(m, mt, i, ass1, ass2) "eMark(i)=vMark(i)=false" ;
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs1,derivedMultiEqn1) = matchingAlgorithm2(dae, m, mt, nv, nf, i_1, ass1_1, ass2_1, match_opts, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs1,derivedMultiEqn1);

    case (dae,m,mt,nv,nf,i,ass1,ass2,(BackendDAE.INDEX_REDUCTION(),eq_cons,r_simple),inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        ((dae as BackendDAE.DAELOW(BackendDAE.VARIABLES(_,_,_,_,nv_1),BackendDAE.VARIABLES(_,_,_,_,nkv),_,_,eqns,_,_,_,_,_,_)),m,mt,derivedAlgs1,derivedMultiEqn1) = reduceIndexDummyDer(dae, m, mt, nv, nf, i, inFunctions,derivedAlgs,derivedMultiEqn) 
        "path_found failed, Try index reduction using dummy derivatives.
         When a constraint exist between states and index reduction is needed
         the dummy derivative will select one of the states as a dummy state
         (and the derivative of that state as a dummy derivative).
         For instance, u1=u2 is a constraint between states. Choose u1 as dummy state
         and der(u1) as dummy derivative, named der_u1. The differentiated function
         then becomes: der_u1 = der(u2).
         In the dummy derivative method this equation is added and the original equation
         u1=u2 is kept. This is not the case for the original pantilides algorithm, where
         the original equation is removed from the system." ;
        nf_1 = equationSize(eqns) "and try again, restarting. This could be optimized later. It should not
                                   be necessary to restart the matching, according to Bernard Bachmann. Instead one
                                   could continue the matching as usual. This was tested (2004-11-22) and it does not
                                   work to continue without restarting.
                                   For instance the Influenca model \"../testsuite/mofiles/Influenca.mo\" does not work if
                                   not restarting.
                                   2004-12-29 PA. This was a bug, assignment lists needed to be expanded with the size
                                   of the system in order to work. SO: Matching is not needed to be restarted from
                                   scratch." ;
        nvd = nv_1 - nv;
        ass1_1 = assignmentsExpand(ass1, nvd);
        ass2_1 = assignmentsExpand(ass2, nvd);
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs2,derivedMultiEqn2) = matchingAlgorithm2(dae, m, mt, nv_1, nf_1, i, ass1_1, ass2_1, (BackendDAE.INDEX_REDUCTION(),eq_cons,r_simple),inFunctions,derivedAlgs1,derivedMultiEqn1);
      then
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs2,derivedMultiEqn2);

    case (dae,m,mt,nv,nf,i,ass1,ass2,_,_,_,_)
      equation
        eqn_lst = DAEEXT.getMarkedEqns() "When index reduction also fails, the model is structurally singular." ;
        var_lst = DAEEXT.getMarkedVariables();
        eqn_str = BackendDump.dumpMarkedEqns(dae, eqn_lst);
        var_str = BackendDump.dumpMarkedVars(dae, var_lst);
        Error.addMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,var_str});
        //print("structurally singular. IM:");
        //dumpIncidenceMatrix(m);
        //print("daelow:");
        //dump(dae);
      then
        fail();

  end matchcontinue;
end matchingAlgorithm2;

protected function reduceIndexDummyDer
"function: reduceIndexDummyDer
  author: PA
  When matching fails, this function is called to try to
  reduce the index by differentiating the marked equations and
  replacing one of the variable with a dummy derivative, i.e. making
  it algebraic.
  The new BackendDAE.DAELow is returned along with an updated incidence matrix.

  inputs: (DAELow, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT,
             int /* number of vars */, int /* number of eqns */, int /* i */)
  outputs: (DAELow, BackendDAE.IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.DAELow inDAELow1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;  
  output BackendDAE.DAELow outDAELow;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;  
algorithm
  (outDAELow,outIncidenceMatrix,outIncidenceMatrixT,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inInteger6,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      list<BackendDAE.Value> eqns,diff_eqns,eqns_1,stateindx,deqns,reqns,changedeqns;
      list<BackendDAE.Key> states;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value nv,nf,stateno,i;
      DAE.ComponentRef state,dummy_der;
      list<String> es;
      String es_1;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1;      

    case (dae,m,mt,nv,nf,i,inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        eqns = DAEEXT.getMarkedEqns();
        // print("marked equations:");print(Util.stringDelimitList(Util.listMap(eqns,intString),","));
        // print("\n");
        diff_eqns = DAEEXT.getDifferentiatedEqns();
        eqns_1 = Util.listSetDifferenceOnTrue(eqns, diff_eqns, intEq);
        // print("differentiating equations:");print(Util.stringDelimitList(Util.listMap(eqns_1,intString),","));
        // print("\n");

        // Collect the states in the equations that are singular, i.e. composing a constraint between states.
        // Note that states are collected from -all- marked equations, not only the differentiated ones.
        (states,stateindx) = statesInEqns(eqns, dae, m, mt) "" ;
        (dae,m,mt,nv,nf,deqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(dae, m, mt, nv, nf, eqns_1,inFunctions,derivedAlgs,derivedMultiEqn);
        (state,stateno) = selectDummyState(states, stateindx, dae, m, mt);
        //  print("Selected ");print(ComponentReference.printComponentRefStr(state));print(" as dummy state\n");
        //  print(" From candidates:");print(Util.stringDelimitList(Util.listMap(states,ComponentReference.printComponentRefStr),", "));print("\n");
        dae = propagateDummyFixedAttribute(dae, eqns_1, state, stateno);
        (dummy_der,dae) = newDummyVar(state, dae)  ;
        // print("Chosen dummy: ");print(ComponentReference.printComponentRefStr(dummy_der));print("\n");
        reqns = eqnsForVarWithStates(mt, stateno);
        changedeqns = Util.listUnionOnTrue(deqns, reqns, int_eq);
        (dae,m,mt) = replaceDummyDer(state, dummy_der, dae, m, mt, changedeqns)
        "We need to change variables in the differentiated equations and in the equations having the dummy derivative" ;
        dae = makeAlgebraic(dae, state);
        (m,mt) = updateIncidenceMatrix(dae, m, mt, changedeqns);
        // print("new DAE:");
        // dump(dae);
        // print("new IM:");
        // dumpIncidenceMatrix(m);
      then
        (dae,m,mt,derivedAlgs1,derivedMultiEqn1);

    case (dae,m,mt,nv,nf,i,_,_,_)
      equation
        eqns = DAEEXT.getMarkedEqns();
        diff_eqns = DAEEXT.getDifferentiatedEqns();
        eqns_1 = Util.listSetDifferenceOnTrue(eqns, diff_eqns, intEq);
        es = Util.listMap(eqns_1, intString);
        es_1 = Util.stringDelimitList(es, ", ");
        print("eqns =");print(es_1);print("\n");
        ({},_) = statesInEqns(eqns_1, dae, m, mt);
        print("no states found in equations:");
        BackendDump.printEquations(eqns_1, dae);
        print("differentiated equations:");
        BackendDump.printEquations(diff_eqns,dae);
        print("Variables :");
        print(Util.stringDelimitList(Util.listMap(DAEEXT.getMarkedVariables(),intString),", "));
        print("\n");
      then
        fail();

    case (_,_,_,_,_,_,_,_,_)
      equation
        print("-reduce_index_dummy_der failed\n");
      then
        fail();

  end matchcontinue;
end reduceIndexDummyDer;

protected function propagateDummyFixedAttribute
"function: propagateDummyFixedAttribute
  author: PA
  This function takes a list of equations that are differentiated
  and the chosen dummy state.
  The fixed attribute of the selected dummy state is propagated to
  the other state. This must be done since the dummy state becomes
  an algebraic state which has fixed = false by default.
  For example consider the equations:
  s1 = b;
  b=2c;
  c = s2;
  if s2 is selected as dummy derivative and s2 has an initial equation
  i.e. fixed should be false for the state s2 (which is set by the user),
  this fixed value has to be propagated to s1 when s2 becomes a dummy
  state."
  input BackendDAE.DAELow inDAELow;
  input list<Integer> inIntegerLst;
  input DAE.ComponentRef inComponentRef;
  input Integer inInteger;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow := matchcontinue (inDAELow,inIntegerLst,inComponentRef,inInteger)
    local
      list<BackendDAE.Value> eqns_1,eqns;
      list<BackendDAE.Equation> eqns_lst;
      list<BackendDAE.Key> crefs;
      DAE.ComponentRef state,dummy;
      BackendDAE.Var v,v_1,v_2;
      BackendDAE.Value indx,indx_1,dummy_no;
      Boolean dummy_fixed;
      BackendDAE.Variables vars_1,vars,kv,ev;
      BackendDAE.AliasVariables av;      
      BackendDAE.DAELow dae;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ei;
      BackendDAE.ExternalObjectClasses eoc;

   /* eqns dummy state */
    case ((dae as BackendDAE.DAELOW(vars,kv,ev,av,e,se,ie,ae,al,ei,eoc)),eqns,dummy,dummy_no)
      equation
        eqns_1 = Util.listMap1(eqns, int_sub, 1);
        eqns_lst = Util.listMap1r(eqns_1, equationNth, e);
        crefs = equationsCrefs(eqns_lst);
        crefs = Util.listDeleteMemberOnTrue(crefs, dummy, ComponentReference.crefEqualNoStringCompare);
        state = findState(vars, crefs);
        ({v},{indx}) = getVar(dummy, vars);
        (dummy_fixed as false) = varFixed(v);
        ({v_1},{indx_1}) = getVar(state, vars);
        v_2 = setVarFixed(v_1, dummy_fixed);
        vars_1 = addVar(v_2, vars);
      then
        BackendDAE.DAELOW(vars_1,kv,ev,av,e,se,ie,ae,al,ei,eoc);

    // Never propagate fixed=true
    case ((dae as BackendDAE.DAELOW(vars,kv,ev,av,e,se,ie,ae,al,ei,eoc)),eqns,dummy,dummy_no)
      equation
        eqns_1 = Util.listMap1(eqns, int_sub, 1);
        eqns_lst = Util.listMap1r(eqns_1, equationNth, e);
        crefs = equationsCrefs(eqns_lst);
        crefs = Util.listDeleteMemberOnTrue(crefs, dummy, ComponentReference.crefEqualNoStringCompare);
        state = findState(vars, crefs);
        ({v},{indx}) = getVar(dummy, vars);
       true = varFixed(v);
      then dae;

    case (dae,_,_,_)
      equation
        Debug.fprint("failtrace", "propagate_dummy_initial_equations failed\n");
      then
        dae;

  end matchcontinue;
end propagateDummyFixedAttribute;

protected function findState
"function: findState
  author: PA
  Returns the first state from a list of component references."
  input BackendDAE.Variables inVariables;
  input list<DAE.ComponentRef> inExpComponentRefLst;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inVariables,inExpComponentRefLst)
    local
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      list<BackendDAE.Key> crs;

    case (vars,(cr :: crs))
      equation
        ((v :: _),_) = getVar(cr, vars);
        BackendDAE.STATE() = varKind(v);
      then
        cr;

    case (vars,(cr :: crs))
      equation
        cr = findState(vars, crs);
      then
        cr;

  end matchcontinue;
end findState;

public function equationsCrefs
"function: equationsCrefs
  author: PA
  From a list of equations return all
  occuring variables/component references."
  input list<BackendDAE.Equation> inEquationLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inEquationLst)
    local
      list<BackendDAE.Key> crs1,crs2,crs3,crs,crs2_1,crs3_1;
      DAE.Exp e1,e2,e;
      list<BackendDAE.Equation> es;
      DAE.ComponentRef cr;
      BackendDAE.Value indx;
      list<DAE.Exp> expl,expl1,expl2;
      BackendDAE.WhenEquation weq;
      DAE.ElementSource source "the element source";

    case ({}) then {};

    case ((BackendDAE.EQUATION(exp = e1,scalar = e2) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Exp.getCrefFromExp(e1);
        crs3 = Exp.getCrefFromExp(e2);
        crs = Util.listFlatten({crs1,crs2,crs3});
      then
        crs;

    case ((BackendDAE.RESIDUAL_EQUATION(exp = e1) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Exp.getCrefFromExp(e1);
        crs = listAppend(crs1, crs2);
      then
        crs;

    case ((BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e1) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Exp.getCrefFromExp(e1);
        crs = listAppend(crs1, crs2);
      then
        (cr :: crs);

    case ((BackendDAE.ARRAY_EQUATION(index = indx,crefOrDerCref = expl) :: es))
      local list<list<DAE.ComponentRef>> crs2;
      equation
        crs1 = equationsCrefs(es);
        crs2 = Util.listMap(expl, Exp.getCrefFromExp);
        crs2_1 = Util.listFlatten(crs2);
        crs = listAppend(crs1, crs2_1);
      then
        crs;

    case ((BackendDAE.ALGORITHM(index = indx,in_ = expl1,out = expl2) :: es))
      local list<list<DAE.ComponentRef>> crs2,crs3;
      equation
        crs1 = equationsCrefs(es);
        crs2 = Util.listMap(expl1, Exp.getCrefFromExp);
        crs3 = Util.listMap(expl2, Exp.getCrefFromExp);
        crs2_1 = Util.listFlatten(crs2);
        crs3_1 = Util.listFlatten(crs3);
        crs = Util.listFlatten({crs1,crs2_1,crs3_1});
      then
        crs;

    case ((BackendDAE.WHEN_EQUATION(whenEquation =
           BackendDAE.WHEN_EQ(index = indx,left = cr,right = e,elsewhenPart=SOME(weq)),source = source) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Exp.getCrefFromExp(e);
        crs3 = equationsCrefs({BackendDAE.WHEN_EQUATION(weq,source)});
        crs = listAppend(crs1, listAppend(crs2, crs3));
      then
        (cr :: crs);
  end matchcontinue;
end equationsCrefs;

protected function updateIncidenceMatrix
"function: updateIncidenceMatrix
  author: PA
  Takes a daelow and the incidence matrix and its transposed
  represenation and a list of  equation indexes that needs to be updated.
  First the BackendDAE.IncidenceMatrix is updated, i.e. the mapping from equations
  to variables. Then, by collecting all variables in the list of equations
  to update, a list of changed variables are retrieved. This is used to
  update the BackendDAE.IncidenceMatrixT (transpose) mapping from variables to
  equations. The function returns an updated incidence matrix.
  inputs:  (DAELow,
            IncidenceMatrix,
            IncidenceMatrixT,
            int list /* list of equations to update */)
  outputs: (IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input list<Integer> inIntegerLst;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
algorithm
  (outIncidenceMatrix,outIncidenceMatrixT):=
  matchcontinue (inDAELow,inIncidenceMatrix,inIncidenceMatrixT,inIntegerLst)
    local
      array<list<BackendDAE.Value>> m_1,mt_1,m,mt;
      list<list<BackendDAE.Value>> changedvars;
      list<BackendDAE.Value> changedvars_1,eqns;
      BackendDAE.DAELow dae;

    case (dae,m,mt,eqns)
      equation
        (m_1,changedvars) = updateIncidenceMatrix2(dae, m, eqns);
        changedvars_1 = Util.listFlatten(changedvars);
        mt_1 = updateTransposedMatrix(changedvars_1, m_1, mt);
      then
        (m_1,mt_1);

    case (dae,m,mt,eqns)
      equation
        print("- DAELow.updateIncidenceMatrix failed\n");
      then
        fail();
  end matchcontinue;
end updateIncidenceMatrix;

protected function updateIncidenceMatrix2
"function: updateIncidenceMatrix2
  author: PA
  Helper function to updateIncidenceMatrix
  inputs:  (DAELow,
            IncidenceMatrix,
            int list /* list of equations to update */)
  outputs: (IncidenceMatrix, int list list /* changed vars */)"
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input list<Integer> inIntegerLst;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outIncidenceMatrix,outIntegerLstLst):=
  matchcontinue (inDAELow,inIncidenceMatrix,inIntegerLst)
    local
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,m_1,m_2;
      BackendDAE.Value e_1,e;
      BackendDAE.Equation eqn;
      list<BackendDAE.Value> row,changedvars1,eqns;
      list<list<BackendDAE.Value>> changedvars2;
      BackendDAE.Variables vars,knvars;
      BackendDAE.EquationArray daeeqns,daeseqns;
      list<BackendDAE.WhenClause> wc;

    case (dae,m,{}) then (m,{{}});

    case ((dae as BackendDAE.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = daeeqns,removedEqs = daeseqns,eventInfo = BackendDAE.EVENT_INFO(whenClauseLst = wc))),m,(e :: eqns))
      equation
        e_1 = e - 1;
        eqn = equationNth(daeeqns, e_1);
        row = incidenceRow(vars, eqn,wc);
        m_1 = Util.arrayReplaceAtWithFill(row, e_1 + 1, m, {});
        changedvars1 = varsInEqn(m_1, e);
        (m_2,changedvars2) = updateIncidenceMatrix2(dae, m_1, eqns);
      then
        (m_2,(changedvars1 :: changedvars2));

    case (_,_,_)
      equation
        print("-update_incididence_matrix2 failed\n");
      then
        fail();

  end matchcontinue;
end updateIncidenceMatrix2;

protected function updateTransposedMatrix
"function: updateTransposedMatrix
  author: PA
  Takes a list of variables and the transposed
  IncidenceMatrix, and updates the variable rows.
  inputs:  (int list /* var list */,
              IncidenceMatrix,
              IncidenceMatrixT)
  outputs:  IncidenceMatrixT"
  input list<Integer> inIntegerLst;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
algorithm
  outIncidenceMatrixT:=
  matchcontinue (inIntegerLst,inIncidenceMatrix,inIncidenceMatrixT)
    local
      array<list<BackendDAE.Value>> m,mt,mt_1,mt_2;
      list<list<BackendDAE.Value>> mlst;
      list<BackendDAE.Value> row_1,vars;
      BackendDAE.Value v_1,v;
    case ({},m,mt) then mt;
    case ((v :: vars),m,mt)
      equation
        mlst = arrayList(m);
        row_1 = transposeRow(mlst, v, 1);
        v_1 = v - 1;
        mt_1 = Util.arrayReplaceAtWithFill(row_1, v_1 + 1, mt, {});
        mt_2 = updateTransposedMatrix(vars, m, mt_1);
      then
        mt_2;
    case (_,_,_)
      equation
        print("DAELow.updateTransposedMatrix failed\n");
      then
        fail();
  end matchcontinue;
end updateTransposedMatrix;

public function makeAllStatesAlgebraic
"function: makeAllStatesAlgebraic
  author: PA
  This function makes all states of a BackendDAE.DAELow algebraic.
  Is used when solving an initial value problem, since
  states are just an algebraic variable in that case."
  input BackendDAE.DAELow inDAELow;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow:=
  matchcontinue (inDAELow)
    local
      list<BackendDAE.Var> var_lst,var_lst_1;
      BackendDAE.Variables vars_1,vars,knvar,evar;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,reqns,ieqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ev;
      BackendDAE.ExternalObjectClasses eoc;
    case (BackendDAE.DAELOW(vars,knvar,evar,av,eqns,reqns,ieqns,ae,al,ev,eoc))
      equation
        var_lst = varList(vars);
        var_lst_1 = makeAllStatesAlgebraic2(var_lst);
        vars_1 = listVar(var_lst_1);
      then
        BackendDAE.DAELOW(vars_1,knvar,evar,av,eqns,reqns,ieqns,ae,al,ev,eoc);
  end matchcontinue;
end makeAllStatesAlgebraic;

protected function makeAllStatesAlgebraic2
"function: makeAllStatesAlgebraic2
  author: PA
  Helper function to makeAllStatesAlgebraic"
  input list<BackendDAE.Var> inVarLst;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVarLst)
    local
      list<BackendDAE.Var> vs_1,vs;
      DAE.ComponentRef cr;
      DAE.VarDirection d;
      BackendDAE.Type t;
      Option<DAE.Exp> b;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      BackendDAE.Value idx;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      BackendDAE.Var v;

    case ({}) then {};

    case ((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.STATE(),
               varDirection = d,
               varType = t,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               index = idx,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix) :: vs))
      equation
        vs_1 = makeAllStatesAlgebraic2(vs);
      then
        (BackendDAE.VAR(cr,BackendDAE.VARIABLE(),d,t,b,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: vs_1);

    case ((v :: vs))
      equation
        vs_1 = makeAllStatesAlgebraic2(vs);
      then
        (v :: vs_1);
  end matchcontinue;
end makeAllStatesAlgebraic2;

protected function makeAlgebraic
"function: makeAlgebraic
  author: PA
  Make the variable a dummy derivative, i.e.
  change varkind from STATE to DUMMY_STATE.
  inputs:  (DAELow, DAE.ComponentRef /* state */)
  outputs: (DAELow) = "
  input BackendDAE.DAELow inDAELow;
  input DAE.ComponentRef inComponentRef;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow:=
  matchcontinue (inDAELow,inComponentRef)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection d;
      BackendDAE.Type t;
      Option<DAE.Exp> b;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      BackendDAE.Value idx;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<BackendDAE.Value> indx;
      BackendDAE.Variables vars_1,vars,kv,ev;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.DAELow daelow, daelow_1;

    case (BackendDAE.DAELOW(vars,kv,ev,av,e,se,ie,ae,al,wc,eoc),cr)
      equation
        ((BackendDAE.VAR(cr,kind,d,t,b,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),indx) = getVar(cr, vars);
        vars_1 = addVar(BackendDAE.VAR(cr,BackendDAE.DUMMY_STATE(),d,t,b,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix), vars);        
      then
        BackendDAE.DAELOW(vars_1,kv,ev,av,e,se,ie,ae,al,wc,eoc);

    case (_,_)
      equation
        print("DAELow.makeAlgebraic failed\n");
      then
        fail();

  end matchcontinue;
end makeAlgebraic;

protected function replaceDummyDer
"function: replaceDummyDer
  author: PA
  Helper function to reduceIndexDummyDer
  replaces der(state) with the variable dummy der.
  inputs:   (DAE.ComponentRef, /* state */
             DAE.ComponentRef, /* dummy der name */
             DAELow,
             IncidenceMatrix,
             IncidenceMatrixT,
             int list /* equations */)
  outputs:  (DAELow,
             IncidenceMatrix,
             IncidenceMatrixT)"
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
  input BackendDAE.DAELow inDAELow3;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix4;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT5;
  input list<Integer> inIntegerLst6;
  output BackendDAE.DAELow outDAELow;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
algorithm
  (outDAELow,outIncidenceMatrix,outIncidenceMatrixT):=
  matchcontinue (inComponentRef1,inComponentRef2,inDAELow3,inIncidenceMatrix4,inIncidenceMatrixT5,inIntegerLst6)
    local
      DAE.ComponentRef state,dummy,dummyder;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value e_1,e;
      BackendDAE.Equation eqn,eqn_1;
      BackendDAE.Variables v_1,v,kv,ev;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns_1,eqns,seqns,ie,ie1;
      array<BackendDAE.MultiDimEquation> ae,ae1,ae2,ae3;
      array<DAE.Algorithm> al,al1,al2,al3;
      BackendDAE.EventInfo wc;
      list<BackendDAE.Value> rest;
      BackendDAE.ExternalObjectClasses eoc;
      list<BackendDAE.Equation> ieLst1,ieLst;

    case (state,dummy,dae,m,mt,{}) then (dae,m,mt);

    case (state,dummyder,BackendDAE.DAELOW(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc),m,mt,(e :: rest))
      equation
        e_1 = e - 1;
        eqn = equationNth(eqns, e_1);
        ieLst = equationList(ie);
        (eqn_1,al1,ae1) = replaceDummyDer2(state, dummyder, eqn, al, ae);
        (ieLst1,al2,ae2) = replaceDummyDerEqns(ieLst,state,dummyder, al1,ae1);
        ie1 = listEquation(ieLst1);
        (eqn_1,v_1,al3,ae3) = replaceDummyDerOthers(eqn_1, v,al2,ae2);
        eqns_1 = equationSetnth(eqns, e_1, eqn_1)
         "incidence_row(v\'\',eqn\') => row\' &
          Util.list_replaceat(row\',e\',m) => m\' &
          transpose_matrix(m\') => mt\' &" ;
        (dae,m,mt) = replaceDummyDer(state, dummyder, BackendDAE.DAELOW(v_1,kv,ev,av,eqns_1,seqns,ie1,ae3,al3,wc,eoc), m, mt, rest);
      then
        (dae,m,mt);

    case (_,_,_,_,_,_)
      equation
        print("-replace_dummy_der failed\n");
      then
        fail();

  end matchcontinue;
end replaceDummyDer;

protected function replaceDummyDer2
"function: replaceDummyDer2
  author: PA
  Helper function to reduceIndexDummyDer
  replaces der(state) with dummyDer variable in equation"
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
  input BackendDAE.Equation inEquation3;
  input array<DAE.Algorithm> inAlgs;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  output BackendDAE.Equation outEquation;
  output array<DAE.Algorithm> outAlgs;
  output array<BackendDAE.MultiDimEquation> outMultiDimEquationArray;
algorithm
  (outEquation,outAlgs,outMultiDimEquationArray) := matchcontinue (inComponentRef1,inComponentRef2,inEquation3,inAlgs,inMultiDimEquationArray)
    local
      DAE.Exp dercall,e1_1,e2_1,e1,e2;
      DAE.ComponentRef st,dummyder,cr;
      BackendDAE.Value ds,indx,i;
      list<DAE.Exp> expl,expl1,in_,in_1,out,out1;
      BackendDAE.Equation res;
      BackendDAE.WhenEquation elsepartRes;
      BackendDAE.WhenEquation elsepart;
      DAE.ElementSource source,source1;
      array<DAE.Algorithm> algs;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      list<Integer> dimSize;
    case (st,dummyder,BackendDAE.EQUATION(exp = e1,scalar = e2,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE()) "scalar equation" ;
        (e1_1,_) = Exp.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (e2_1,_) = Exp.replaceExp(e2, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
      then
        (BackendDAE.EQUATION(e1_1,e2_1,source),inAlgs,ae);
    case (st,dummyder,BackendDAE.ARRAY_EQUATION(index = ds,crefOrDerCref = expl,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (expl1,_) = Exp.replaceListExp(expl, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        i = ds+1;
        BackendDAE.MULTIDIM_EQUATION(dimSize=dimSize,left=e1,right = e2,source=source1) = ae[i];
        (e1_1,_) = Exp.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (e2_1,_) = Exp.replaceExp(e2, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));    
        ae1 = arrayUpdate(ae,i,BackendDAE.MULTIDIM_EQUATION(dimSize,e1_1,e2_1,source1));
      then (BackendDAE.ARRAY_EQUATION(ds,expl1,source),inAlgs,ae1);  /* array equation */
    case (st,dummyder,BackendDAE.ALGORITHM(index = indx,in_ = in_,out = out,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (in_1,_) = Exp.replaceListExp(in_, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));        
        (out1,_) = Exp.replaceListExp(out, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));  
        algs = replaceDummyDerAlgs(indx,inAlgs,dercall, DAE.CREF(dummyder,DAE.ET_REAL()));     
      then (BackendDAE.ALGORITHM(indx,in_1,out1,source),algs,ae);  /* Algorithms */
    case (st,dummyder,BackendDAE.WHEN_EQUATION(whenEquation =
          BackendDAE.WHEN_EQ(index = i,left = cr,right = e1,elsewhenPart=NONE()),source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (e1_1,_) = Exp.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        res = BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e1_1,NONE()),source);
      then
        (res,inAlgs,ae);

    case (st,dummyder,BackendDAE.WHEN_EQUATION(whenEquation =
          BackendDAE.WHEN_EQ(index = i,left = cr,right = e1,elsewhenPart=SOME(elsepart)),source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (e1_1,_) = Exp.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (BackendDAE.WHEN_EQUATION(elsepartRes,source),algs,ae1) = replaceDummyDer2(st,dummyder, BackendDAE.WHEN_EQUATION(elsepart,source),inAlgs,ae);
        res = BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e1_1,SOME(elsepartRes)),source);
      then
        (res,algs,ae1);
    case (st,dummyder,BackendDAE.COMPLEX_EQUATION(index=i,lhs = e1,rhs = e2,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE()) "scalar equation" ;
        (e1_1,_) = Exp.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (e2_1,_) = Exp.replaceExp(e2, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
      then
        (BackendDAE.COMPLEX_EQUATION(i,e1_1,e2_1,source),inAlgs,ae);
     case (_,_,_,_,_)
      equation
        print("-DAELow.replaceDummyDer2 failed\n");
      then
        fail();
  end matchcontinue;
end replaceDummyDer2;

protected function replaceDummyDerAlgs
  input Integer inIndex;
  input array<DAE.Algorithm> inAlgs;  
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;  
  output array<DAE.Algorithm> outAlgs;  
algorithm
  outAlgs:=
  matchcontinue (inIndex,inAlgs,inExp2,inExp3)
    local  
      array<DAE.Algorithm> algs;
      list<DAE.Statement> statementLst,statementLst1;
      Integer i_1;
  case (inIndex,inAlgs,inExp2,inExp3)
    equation
        // get Allgorithm
        i_1 = inIndex+1;
        DAE.ALGORITHM_STMTS(statementLst= statementLst) = inAlgs[i_1];  
        statementLst1 = replaceDummyDerAlgs1(statementLst,inExp2,inExp3); 
        algs = arrayUpdate(inAlgs,i_1,DAE.ALGORITHM_STMTS(statementLst1));   
    then
      algs;
  end matchcontinue;      
end replaceDummyDerAlgs;

protected function replaceDummyDerAlgs1
  input list<DAE.Statement> inStatementLst;  
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;  
  output list<DAE.Statement> outStatementLst;  
algorithm
  outStatementLst:=
  matchcontinue (inStatementLst,inExp2,inExp3)
    local  
      list<DAE.Statement> rest,st,stlst,stlst1;
      DAE.Statement s,s1;
      DAE.Exp e,e1,e_1,e1_1;
      list<DAE.Exp> elst,elst1,inputExps;
      DAE.ExpType t;
      DAE.ComponentRef cr,cr1;
      DAE.Else else_,else_1;
      DAE.ElementSource source;
      Absyn.MatchType matchType;
  case ({},_,_) then {};
  case (DAE.STMT_ASSIGN(type_=t,exp1=e1,exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        (e_1,_) = Exp.replaceExp(e1,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_ASSIGN(t,e1,e_1,source)::st);
  case (DAE.STMT_TUPLE_ASSIGN(type_=t,expExpLst=elst,exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        (elst1,_) = Exp.replaceListExp(elst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_TUPLE_ASSIGN(t,elst1,e1,source)::st);
  case (DAE.STMT_ASSIGN_ARR(type_=t,componentRef=cr,exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        (DAE.CREF(componentRef = cr1),_) = Exp.replaceExp(DAE.CREF(cr,DAE.ET_REAL()),inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_ASSIGN_ARR(t,cr1,e1,source)::st);
  case (DAE.STMT_IF(exp=e,statementLst=stlst,else_=else_,source=source)::rest,inExp2,inExp3)
    equation
       (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
       stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
       else_1 = replaceDummyDerAlgs2(else_,inExp2,inExp3);
       st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_IF(e1,stlst1,else_1,source)::st);
  case (DAE.STMT_FOR(type_=t,iterIsArray=b,ident=id,exp=e,statementLst=stlst,source=source)::rest,inExp2,inExp3)
    local 
      Boolean b;
      DAE.Ident id;
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_FOR(t,b,id,e1,stlst1,source)::st);
  case (DAE.STMT_WHILE(exp=e,statementLst=stlst,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_WHILE(e1,stlst1,source)::st);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=SOME(s),helpVarIndices=helpVarIndices,source=source)::rest,inExp2,inExp3)
    local list<Integer> helpVarIndices;
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        {s1} = replaceDummyDerAlgs1({s},inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_WHEN(e1,stlst1,SOME(s1),helpVarIndices,source)::st);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=NONE(),helpVarIndices=helpVarIndices,source=source)::rest,inExp2,inExp3)
    local list<Integer> helpVarIndices;
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_WHEN(e1,stlst1,NONE(),helpVarIndices,source)::st);
  case (DAE.STMT_ASSERT(cond=e1,msg=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        (e_1,_) = Exp.replaceExp(e1,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_ASSERT(e1,e_1,source)::st);
  case (DAE.STMT_TERMINATE(msg=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_TERMINATE(e1,source)::st);
  case (DAE.STMT_REINIT(var=e1,value=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        (e_1,_) = Exp.replaceExp(e1,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_REINIT(e1,e_1,source)::st);
  case (DAE.STMT_NORETCALL(exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_NORETCALL(e1,source)::st);
  case (DAE.STMT_RETURN(source)::rest,inExp2,inExp3)
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_RETURN(source)::st);
  case (DAE.STMT_BREAK(source)::rest,inExp2,inExp3)
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_BREAK(source)::st);
  case (DAE.STMT_FAILURE(body=stlst,source=source)::rest,inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_FAILURE(stlst1,source)::st);
  case (DAE.STMT_TRY(tryBody=stlst,source=source)::rest,inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_TRY(stlst1,source)::st);
  case (DAE.STMT_CATCH(catchBody=stlst,source=source)::rest,inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_CATCH(stlst1,source)::st);
  case (DAE.STMT_THROW(source=source)::rest,inExp2,inExp3)
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_THROW(source)::st);
  case (DAE.STMT_GOTO(labelName=labelName,source=source)::rest,inExp2,inExp3)
    local String labelName;
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_GOTO(labelName,source)::st);
  case (DAE.STMT_LABEL(labelName=labelName,source=source)::rest,inExp2,inExp3)
    local String labelName;
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_LABEL(labelName,source)::st);
  case (DAE.STMT_MATCHCASES(matchType=matchType,inputExps=inputExps,caseStmt=elst,source=source)::rest,inExp2,inExp3)
    equation
        (elst1,_) = Exp.replaceListExp(elst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_MATCHCASES(matchType,inputExps,elst1,source)::st);
  case (_,_,_)
    equation
      print("-DAELow.replaceDummyDerAlgs1 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerAlgs1;

protected function replaceDummyDerAlgs2
  input DAE.Else inElse;  
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;  
  output DAE.Else outElse;  
algorithm
  outElse:=
  matchcontinue (inElse,inExp2,inExp3)
    local  
      DAE.Exp e,e1;
      list<DAE.Statement> stlst,stlst1;
      DAE.Else else_,else_1;
  case (DAE.NOELSE(),_,_) then DAE.NOELSE();
  case (DAE.ELSEIF(exp=e,statementLst=stlst,else_=else_),inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        else_1 = replaceDummyDerAlgs2(else_,inExp2,inExp3);
    then
      DAE.ELSEIF(e1,stlst1,else_1);
  case (DAE.ELSE(statementLst=stlst),inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
    then
      DAE.ELSE(stlst1);
  case (_,_,_)
    equation
      print("-DAELow.replaceDummyDerAlgs2 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerAlgs2;

protected function replaceDummyDerEqns
"function replaceDummyDerEqns
  author: PA
  Helper function to reduceIndexDummy<der
  replaces der(state) with dummy_der variable in list of equations."
  input list<BackendDAE.Equation> eqns;
  input DAE.ComponentRef st;
  input DAE.ComponentRef dummyder;
  input array<DAE.Algorithm> inAlgs;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  output list<BackendDAE.Equation> outEqns;
  output array<DAE.Algorithm> outAlgs;
  output array<BackendDAE.MultiDimEquation> outMultiDimEquationArray;
algorithm
  (outEqns,outAlgs,outMultiDimEquationArray):=
  matchcontinue (eqns,st,dummyder,inAlgs,inMultiDimEquationArray)
    local
      DAE.ComponentRef st,dummyder;
      list<BackendDAE.Equation> eqns1,eqns;
      BackendDAE.Equation e,e1;
      array<DAE.Algorithm> algs,algs1;
      array<BackendDAE.MultiDimEquation> ae,ae1,ae2;
    case ({},st,dummyder,inAlgs,ae) then ({},inAlgs,ae);
    case (e::eqns,st,dummyder,inAlgs,ae)
      equation
         (e1,algs,ae1) = replaceDummyDer2(st,dummyder,e,inAlgs,ae);
         (eqns1,algs1,ae2) = replaceDummyDerEqns(eqns,st,dummyder,algs,ae1);
      then
        (e1::eqns1,algs1,ae2);
  end matchcontinue;
end replaceDummyDerEqns;

protected function replaceDummyDerOthers
"function: replaceDummyDerOthers
  author: PA
  Helper function to reduceIndexDummyDer.
  This function replaces
  1. der(der_s)  with der2_s (Where der_s is a dummy state)
  2. der(der(v)) with der2_v (where v is a state)
  3. der(v)  for alg. var v with der_v
  in the BackendDAE.Equation given as arguments. To do this it needs the Variables
  also passed as argument to the function to e.g. determine if a variable
  is a dummy variable, etc."
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inVariables;
  input array<DAE.Algorithm> inAlgs;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;  
  output BackendDAE.Equation outEquation;
  output BackendDAE.Variables outVariables;
  output array<DAE.Algorithm> outAlgs;
  output array<BackendDAE.MultiDimEquation> outMultiDimEquationArray;
algorithm
  (outEquation,outVariables,outAlgs,outMultiDimEquationArray):=
  matchcontinue (inEquation,inVariables,inAlgs,inMultiDimEquationArray)
    local
      DAE.Exp e1_1,e2_1,e1,e2;
      BackendDAE.Variables vars_1,vars_2,vars_3,vars;
      BackendDAE.Value ds,i;
      list<DAE.Exp> expl,expl1,in_,in_1,out,out1;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation elsePartRes;
      BackendDAE.WhenEquation elsePart;
      DAE.ElementSource source,source1;
      Integer indx;
      array<DAE.Algorithm> al;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      list<Integer> dimSize;

    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source = source),vars,inAlgs,ae)
      equation
        ((e1_1,vars_1)) = Exp.traverseExp(e1,replaceDummyDerOthersExp,vars) "scalar equation" ;
        ((e2_1,vars_2)) = Exp.traverseExp(e2,replaceDummyDerOthersExp,vars_1);
      then
        (BackendDAE.EQUATION(e1_1,e2_1,source),vars_2,inAlgs,ae);

    case (BackendDAE.ARRAY_EQUATION(index = ds,crefOrDerCref = expl,source = source),vars,inAlgs,ae) 
      equation
        (expl1,vars_1) = replaceDummyDerOthersExpLst(expl,vars);
        i = ds+1;
        BackendDAE.MULTIDIM_EQUATION(dimSize=dimSize,left=e1,right = e2,source=source1) = ae[i];
        ((e1_1,vars_2)) = Exp.traverseExp(e1,replaceDummyDerOthersExp,vars_1);
        ((e2_1,vars_3)) = Exp.traverseExp(e2,replaceDummyDerOthersExp,vars_2);       
        ae1 = arrayUpdate(ae,i,BackendDAE.MULTIDIM_EQUATION(dimSize,e1_1,e2_1,source1));
      then (BackendDAE.ARRAY_EQUATION(ds,expl1,source),vars_3,inAlgs,ae1);  /* array equation */

    case (BackendDAE.WHEN_EQUATION(whenEquation =
            BackendDAE.WHEN_EQ(index = i,left = cr,right = e2,elsewhenPart=NONE()),source = source),vars,inAlgs,ae)
      equation
        ((e2_1,vars_1)) = Exp.traverseExp(e2,replaceDummyDerOthersExp,vars);
      then
        (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e2_1,NONE()),source),vars_1,inAlgs,ae);

    case (BackendDAE.WHEN_EQUATION(whenEquation =
            BackendDAE.WHEN_EQ(index = i,left = cr,right = e2,elsewhenPart=SOME(elsePart)),source = source),vars,inAlgs,ae)
      equation
        ((e2_1,vars_1)) = Exp.traverseExp(e2,replaceDummyDerOthersExp,vars);
        (BackendDAE.WHEN_EQUATION(elsePartRes,source), vars_2,al,ae1) = replaceDummyDerOthers(BackendDAE.WHEN_EQUATION(elsePart,source),vars_1,inAlgs,ae);
      then
        (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e2_1,SOME(elsePartRes)),source),vars_2,al,ae1);

    case (BackendDAE.ALGORITHM(index = indx,in_ = in_,out = out,source = source),vars,inAlgs,ae)
      equation
        (in_1,vars_1) = replaceDummyDerOthersExpLst(in_, vars);
        (out1,vars_2) = replaceDummyDerOthersExpLst(out, vars_1);
        (vars_2,al) = replaceDummyDerOthersAlgs(indx,vars_1,inAlgs);     
      then (BackendDAE.ALGORITHM(indx,in_1,out1,source),vars_2,al,ae);

   case (BackendDAE.COMPLEX_EQUATION(index=i,lhs = e1,rhs = e2,source = source),vars,inAlgs,ae)      
      equation
        ((e1_1,vars_1)) = Exp.traverseExp(e1,replaceDummyDerOthersExp,vars) "scalar equation" ;
        ((e2_1,vars_2)) = Exp.traverseExp(e2,replaceDummyDerOthersExp,vars_1);
      then
        (BackendDAE.COMPLEX_EQUATION(i,e1_1,e2_1,source),vars_2,inAlgs,ae);

    case (_,_,_,_)
      equation
        print("-DAELow.replaceDummyDerOthers failed\n");
      then
        fail();
  end matchcontinue;
end replaceDummyDerOthers;

protected function replaceDummyDerOthersAlgs
  input Integer inIndex;
  input BackendDAE.Variables inVariables;
  input array<DAE.Algorithm> inAlgs;
  output BackendDAE.Variables outVariables;
  output array<DAE.Algorithm> outAlgs;
algorithm
  (outVariables,outAlgs):=
  matchcontinue (inIndex,inVariables,inAlgs)
    local
      array<DAE.Algorithm> algs;
      list<DAE.Statement> statementLst,statementLst1;
      Integer i_1;
      BackendDAE.Variables vars;
      case(inIndex,inVariables,inAlgs)
        equation
        // get Allgorithm
        i_1 = inIndex+1;
        DAE.ALGORITHM_STMTS(statementLst= statementLst) = inAlgs[i_1];  
        (statementLst1,vars) = replaceDummyDerOthersAlgs1(statementLst,inVariables); 
        algs = arrayUpdate(inAlgs,i_1,DAE.ALGORITHM_STMTS(statementLst1));           
      then
       (vars,algs); 
  end matchcontinue;        
end replaceDummyDerOthersAlgs;

protected function replaceDummyDerOthersAlgs1
  input list<DAE.Statement> inStatementLst;  
  input BackendDAE.Variables inVariables;
  output list<DAE.Statement> outStatementLst;  
  output BackendDAE.Variables outVariables;
algorithm
  (outStatementLst,outVariables) :=
  matchcontinue (inStatementLst,inVariables)
    local  
      list<DAE.Statement> rest,st,stlst,stlst1;
      DAE.Statement s,s1;
      DAE.Exp e,e1,e_1,e1_1;
      list<DAE.Exp> elst,elst1,inputExps;
      DAE.ExpType t;
      DAE.ComponentRef cr,cr1;
      DAE.Else else_,else_1;
      BackendDAE.Variables vars,vars1,vars2,vars3;
      DAE.ElementSource source;
      Absyn.MatchType matchType;
  case ({},inVariables) then ({},inVariables);
  case (DAE.STMT_ASSIGN(type_=t,exp1=e1,exp=e,source=source)::rest,inVariables)
    equation
        ((e_1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((e1_1,vars1)) = Exp.traverseExp(e1,replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_ASSIGN(t,e_1,e1_1,source)::st,vars2);
  case (DAE.STMT_TUPLE_ASSIGN(type_=t,expExpLst=elst,exp=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (elst1,vars1) = replaceDummyDerOthersExpLst(elst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_TUPLE_ASSIGN(t,elst1,e1,source)::st,vars2);
  case (DAE.STMT_ASSIGN_ARR(type_=t,componentRef=cr,exp=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((DAE.CREF(componentRef = cr1),vars1)) = Exp.traverseExp(DAE.CREF(cr,DAE.ET_REAL()),replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_ASSIGN_ARR(t,cr1,e1,source)::st,vars2);
  case (DAE.STMT_IF(exp=e,statementLst=stlst,else_=else_,source=source)::rest,inVariables)
    equation
       ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
       (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
       (else_1,vars2) = replaceDummyDerOthersAlgs2(else_,vars1);
       (st,vars3) = replaceDummyDerOthersAlgs1(rest,vars2);
    then
      (DAE.STMT_IF(e1,stlst1,else_1,source)::st,vars3);
  case (DAE.STMT_FOR(type_=t,iterIsArray=b,ident=id,exp=e,statementLst=stlst,source=source)::rest,inVariables)
    local 
      Boolean b;
      DAE.Ident id;
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_FOR(t,b,id,e1,stlst1,source)::st,vars2);
  case (DAE.STMT_WHILE(exp=e,statementLst=stlst,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_WHILE(e1,stlst1,source)::st,vars2);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=SOME(s),helpVarIndices=helpVarIndices,source=source)::rest,inVariables)
    local list<Integer> helpVarIndices;
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        ({s1},vars2) = replaceDummyDerOthersAlgs1({s},vars1);
        (st,vars3) = replaceDummyDerOthersAlgs1(rest,vars2);
    then
      (DAE.STMT_WHEN(e1,stlst1,SOME(s1),helpVarIndices,source)::st,vars3);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=NONE(),helpVarIndices=helpVarIndices,source=source)::rest,inVariables)
    local list<Integer> helpVarIndices;
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_WHEN(e1,stlst1,NONE(),helpVarIndices,source)::st,vars2);
  case (DAE.STMT_ASSERT(cond=e1,msg=e,source=source)::rest,inVariables)
    equation
        ((e_1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((e1_1,vars1)) = Exp.traverseExp(e1,replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_ASSERT(e_1,e1_1,source)::st,vars2);
  case (DAE.STMT_TERMINATE(msg=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_TERMINATE(e1,source)::st,vars1);
  case (DAE.STMT_REINIT(var=e1,value=e,source=source)::rest,inVariables)
    equation
        ((e_1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((e1_1,vars1)) = Exp.traverseExp(e1,replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_REINIT(e_1,e1_1,source)::st,vars2);
  case (DAE.STMT_NORETCALL(exp=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_NORETCALL(e1,source)::st,vars1);
  case (DAE.STMT_RETURN(source=source)::rest,inVariables)
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_RETURN(source)::st,vars);
  case (DAE.STMT_BREAK(source=source)::rest,inVariables)
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_BREAK(source)::st,vars);
  case (DAE.STMT_FAILURE(body=stlst,source=source)::rest,inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_FAILURE(stlst1,source)::st,vars1);
  case (DAE.STMT_TRY(tryBody=stlst,source=source)::rest,inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_TRY(stlst1,source)::st,vars1);
  case (DAE.STMT_CATCH(catchBody=stlst,source=source)::rest,inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_CATCH(stlst1,source)::st,vars1);
  case (DAE.STMT_THROW(source=source)::rest,inVariables)
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_THROW(source)::st,vars);
  case (DAE.STMT_GOTO(labelName=labelName,source=source)::rest,inVariables)
    local String labelName;
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_GOTO(labelName,source)::st,vars);
  case (DAE.STMT_LABEL(labelName=labelName,source=source)::rest,inVariables)
    local String labelName;
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_LABEL(labelName,source)::st,vars);
  case (DAE.STMT_MATCHCASES(matchType=matchType,inputExps=inputExps,caseStmt=elst,source=source)::rest,inVariables)
    equation
        (elst1,vars) = replaceDummyDerOthersExpLst(elst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_MATCHCASES(matchType,inputExps,elst1,source)::st,vars1);
  case (_,_)
    equation
      print("-DAELow.replaceDummyDerOthersAlgs1 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerOthersAlgs1;

protected function replaceDummyDerOthersAlgs2
  input DAE.Else inElse;  
  input BackendDAE.Variables inVariables;
  output DAE.Else outElse; 
  output BackendDAE.Variables outVariables; 
algorithm
  (outElse,outVariables):=
  matchcontinue (inElse,inVariables)
    local  
      DAE.Exp e,e1;
      list<DAE.Statement> stlst,stlst1;
      DAE.Else else_,else_1;
      BackendDAE.Variables vars,vars1,vars2;
  case (DAE.NOELSE(),inVariables) then (DAE.NOELSE(),inVariables);
  case (DAE.ELSEIF(exp=e,statementLst=stlst,else_=else_),inVariables)
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (else_1,vars2) = replaceDummyDerOthersAlgs2(else_,vars1);
    then
      (DAE.ELSEIF(e1,stlst1,else_1),vars2);
  case (DAE.ELSE(statementLst=stlst),inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
    then
      (DAE.ELSE(stlst1),vars);
  case (_,_)
    equation
      print("-DAELow.replaceDummyDerOthersAlgs2 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerOthersAlgs2;

protected function replaceDummyDerOthersExpLst
"function: replaceDummyDerOthersExp
  author: PA
  Helper function for replaceDummyDer_others"
  input list<DAE.Exp> inExpLst;
  input BackendDAE.Variables inVariables;
  output list<DAE.Exp> outExpLst;
  output BackendDAE.Variables outVariables;
algorithm
  (outExpLst,outVariables) := matchcontinue (inExpLst,inVariables)
  local 
    list<DAE.Exp> rest,elst;
    DAE.Exp e,e1;
    BackendDAE.Variables vars,vars1,vars2;
    case ({},vars) then ({},vars); 
    case (e::rest,vars)
      equation
        ((e1,vars1)) = Exp.traverseExp(e,replaceDummyDerOthersExp,vars);
        (elst,vars2) = replaceDummyDerOthersExpLst(rest,vars1);
      then
       (e1::elst,vars2); 
  end matchcontinue;       
end replaceDummyDerOthersExpLst;

protected function replaceDummyDerOthersExp
"function: replaceDummyDerOthersExp
  author: PA
  Helper function for replaceDummyDer_others"
  input tuple<DAE.Exp,BackendDAE.Variables> inExp;
  output tuple<DAE.Exp,BackendDAE.Variables> outExp;
algorithm
  (outExp) := matchcontinue (inExp)
    local
      DAE.Exp e;
      BackendDAE.Variables vars,vars_1;
      DAE.VarDirection a;
      BackendDAE.Type b;
      Option<DAE.Exp> c;
      Option<Values.Value> d;
      BackendDAE.Value g;
      DAE.ComponentRef dummyder,dummyder_1,cr;
      DAE.ElementSource source "the source of the element";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})}),vars))
      local list<DAE.Subscript> e;
      equation
        ((BackendDAE.VAR(_,BackendDAE.STATE(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = getVar(cr, vars) "der(der(s)) s is state => der_der_s" ;
        dummyder = crefPrefixDer(cr);
        dummyder = crefPrefixDer(dummyder);
        vars_1 = addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b,NONE(), NONE(), e, 0, source, dae_var_attr, comment, flowPrefix, streamPrefix), vars);
      then
        ((DAE.CREF(dummyder,DAE.ET_REAL()),vars_1));

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars))
      local list<DAE.Subscript> e;
      equation
        ((BackendDAE.VAR(_,BackendDAE.DUMMY_DER(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = getVar(cr, vars) "der(der_s)) der_s is dummy var => der_der_s" ;
        dummyder = crefPrefixDer(cr);
        vars_1 = addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b,NONE(), NONE(), e, 0, source, dae_var_attr, comment, flowPrefix, streamPrefix), vars);
      then
        ((DAE.CREF(dummyder,DAE.ET_REAL()),vars_1));

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars))
      local list<DAE.Subscript> e;
      equation
        ((BackendDAE.VAR(_,BackendDAE.VARIABLE(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = getVar(cr, vars) "der(v) v is alg var => der_v" ;
        dummyder = crefPrefixDer(cr);
        vars_1 = addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b,NONE(), NONE(), e, 0, source, dae_var_attr, comment, flowPrefix, streamPrefix), vars);
      then
        ((DAE.CREF(dummyder,DAE.ET_REAL()),vars_1));

    case ((e,vars)) then ((e,vars));

  end matchcontinue;
end replaceDummyDerOthersExp;

public function varEqual
"function: varEqual
  author: PA
  Returns true if two Vars are equal."
  input BackendDAE.Var inVar1;
  input BackendDAE.Var inVar2;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar1,inVar2)
    local
      Boolean res;
      DAE.ComponentRef cr1,cr2;
    case (BackendDAE.VAR(varName = cr1),BackendDAE.VAR(varName = cr2))
      equation
        res = ComponentReference.crefEqualNoStringCompare(cr1, cr2) "A BackendDAE.Var is identified by its component reference" ;
      then
        res;
  end matchcontinue;
end varEqual;

public function equationEqual "Returns true if two equations are equal"
  input BackendDAE.Equation e1;
  input BackendDAE.Equation e2;
  output Boolean res;
algorithm
  res := matchcontinue(e1,e2)
    local
      DAE.Exp e11,e12,e21,e22,exp1,exp2;
      Integer i1,i2;
      DAE.ComponentRef cr1,cr2;
    case (BackendDAE.EQUATION(exp = e11,scalar = e12),
          BackendDAE.EQUATION(exp = e21, scalar = e22))
      equation
        res = boolAnd(Exp.expEqual(e11,e21),Exp.expEqual(e12,e22));
      then res;

    case(BackendDAE.ARRAY_EQUATION(index = i1),
         BackendDAE.ARRAY_EQUATION(index = i2))
      equation
        res = intEq(i1,i2);
      then res;

    case(BackendDAE.SOLVED_EQUATION(componentRef = cr1,exp = exp1),
         BackendDAE.SOLVED_EQUATION(componentRef = cr2,exp = exp2))
      equation
        res = boolAnd(ComponentReference.crefEqualNoStringCompare(cr1,cr2),Exp.expEqual(exp1,exp2));
      then res;

    case(BackendDAE.RESIDUAL_EQUATION(exp = exp1),
         BackendDAE.RESIDUAL_EQUATION(exp = exp2))
      equation
        res = Exp.expEqual(exp1,exp2);
      then res;

    case(BackendDAE.ALGORITHM(index = i1),
         BackendDAE.ALGORITHM(index = i2))
      equation
        res = intEq(i1,i2);
      then res;

    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index = i1)),
          BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index = i2)))
      equation
        res = intEq(i1,i2);
      then res;

    case(_,_) then false;

  end matchcontinue;
end equationEqual;

protected function newDummyVar
"function: newDummyVar
  author: PA
  This function creates a new variable named
  der+<varname> and adds it to the dae."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.DAELow inDAELow;
  output DAE.ComponentRef outComponentRef;
  output BackendDAE.DAELow outDAELow;
algorithm
  (outComponentRef,outDAELow):=
  matchcontinue (inComponentRef,inDAELow)
    local
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      BackendDAE.Value idx;
      DAE.ComponentRef name,dummyvar_cr,var;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      BackendDAE.Variables vars_1,vars,kv,ev;
      BackendDAE.AliasVariables av;      
      BackendDAE.EquationArray eqns,seqns,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.Var dummyvar;

    case (var,BackendDAE.DAELOW(vars, kv, ev, av, eqns, seqns, ie, ae, al, wc,eoc))
      equation
        ((BackendDAE.VAR(name,kind,dir,tp,bind,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = getVar(var, vars);
        dummyvar_cr = crefPrefixDer(var);
        dummyvar = BackendDAE.VAR(dummyvar_cr,BackendDAE.DUMMY_DER(),dir,tp,NONE(),NONE(),dim,0,source,dae_var_attr,comment,flowPrefix,streamPrefix);
        /* Dummy variables are algebraic variables, hence fixed = false */
        dummyvar = setVarFixed(dummyvar,false);
        vars_1 = addVar(dummyvar, vars);
      then
        (dummyvar_cr,BackendDAE.DAELOW(vars_1,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc));

    case (_,_)
      equation
        print("-DAELow.newDummyVar failed!\n");
      then
        fail();
  end matchcontinue;
end newDummyVar;

protected function selectDummyState
"function: selectDummyState
  author: PA
  This function is the heuristic to select among the states which one
  will be transformed into  an algebraic variable, a so called dummy state
 (dummy derivative). It should in the future consider initial values, etc.
  inputs:  (DAE.ComponentRef list, /* variable names */
            int list, /* variable numbers */
            DAELow,
            IncidenceMatrix,
            IncidenceMatrixT)
  outputs: (DAE.ComponentRef, int)"
  input list<DAE.ComponentRef> varCrefs;
  input list<Integer> varIndices;
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output DAE.ComponentRef outComponentRef;
  output Integer outInteger;
algorithm
  (outComponentRef,outInteger):=
  matchcontinue (varCrefs,varIndices,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef s;
      BackendDAE.Value sn;
      BackendDAE.Variables vars;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.EquationArray eqns;
      list<tuple<DAE.ComponentRef,Integer,Real>> prioTuples;

    case (varCrefs,varIndices,BackendDAE.DAELOW(orderedVars=vars,orderedEqs = eqns),m,mt)
      equation
        prioTuples = calculateVarPriorities(varCrefs,varIndices,vars,eqns,m,mt);
        //print("priorities:");print(Util.stringDelimitList(Util.listMap(prioTuples,printPrioTuplesStr),","));print("\n");
        (s,sn) = selectMinPrio(prioTuples);
      then (s,sn);

    case ({},_,dae,_,_)
      local BackendDAE.DAELow dae;
      equation
        print("Error, no state to select\nDAE:");
        //dump(dae);
      then
        fail();

  end matchcontinue;
end selectDummyState;

protected function selectMinPrio
"Selects the state with lowest priority. This will become a dummy state"
  input list<tuple<DAE.ComponentRef,Integer,Real>> tuples;
  output DAE.ComponentRef s;
  output Integer sn;
algorithm
  (s,sn) := matchcontinue(tuples)
    case(tuples)
      equation
        ((s,sn,_)) = Util.listReduce(tuples,ssPrioTupleMin);
      then (s,sn);
  end matchcontinue;
end selectMinPrio;

protected function ssPrioTupleMin
"Select the minimum tuple of two tuples"
  input tuple<DAE.ComponentRef,Integer,Real> tuple1;
  input tuple<DAE.ComponentRef,Integer,Real> tuple2;
  output tuple<DAE.ComponentRef,Integer,Real> tuple3;
algorithm
  tuple3 := matchcontinue(tuple1,tuple2)
    local DAE.ComponentRef cr1,cr2;
      Integer ns1,ns2;
      Real rs1,rs2;
    case((cr1,ns1,rs1),(cr2,ns2,rs2))
      equation
        true = (rs1 <. rs2);
      then ((cr1,ns1,rs1));

    case ((cr1,ns1,rs1),(cr2,ns2,rs2))
      equation
        true = (rs2 <. rs1);
      then ((cr2,ns2,rs2));

    //exactly equal, choose first one.
    case ((cr1,ns1,rs1),(cr2,ns2,rs2)) then ((cr1,ns1,rs1));

  end matchcontinue;
end ssPrioTupleMin;

protected function calculateVarPriorities
"Calculates state selection priorities"
  input list<DAE.ComponentRef> varCrefs;
  input list<Integer> varIndices;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  output list<tuple<DAE.ComponentRef,Integer,Real>> tuples;
algorithm
  tuples := matchcontinue(varCrefs,varIndices,vars,eqns,m,mt)
  local DAE.ComponentRef varCref;
    Integer varIndx;
    BackendDAE.Var v;
    Real prio,prio1,prio2;
    list<tuple<DAE.ComponentRef,Integer,Real>> prios;
    case({},{},_,_,_,_) then {};
    case (varCref::varCrefs,varIndx::varIndices,vars,eqns,m,mt) equation
      prios = calculateVarPriorities(varCrefs,varIndices,vars,eqns,m,mt);
      (v::_,_) = getVar(varCref,vars);
      prio1 = varStateSelectPrio(v);
      prio2 = varStateSelectHeuristicPrio(v,vars,eqns,m,mt);
      prio = prio1 +. prio2;
    then ((varCref,varIndx,prio)::prios);
  end matchcontinue;
end calculateVarPriorities;

protected function varStateSelectHeuristicPrio
"function varStateSelectHeuristicPrio
  author: PA
  A heuristic for selecting states when no stateSelect information is available.
  This heuristic is based on.
  1. If a state variable s has an equation on the form s = expr(s1,s2,...,sn) where s1..sn are states
     it should be a candiate for dummy state. Like for instance phi_rel = J1.phi-J2.phi will make phi_rel
     a candidate for dummy state whereas J1.phi and J2.phi would be candidates for states.

  2. If a state variable komponent_x.s has been selected as a dummy state then komponent_x.s2 could also
     be a dummy_state. Rationale: This will increase probability that all states belong to the same component
     which is more likely what a user expects.

  3. A priority based on the number of selectable states with the same name.
     For example if the state candidates are: m1.s, m1.v, m2.s, m2.v sd.s_rel (Two translational masses and a springdamper)
     then sd.s_rel should have lower priority than the others."
  input BackendDAE.Var v;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  output Real prio;
protected
  list<Integer> vEqns;
  DAE.ComponentRef vCr;
  Integer vindx;
  Real prio1,prio2,prio3;
algorithm
  (_,vindx::_) := getVar(varCref(v),vars); // Variable index not stored in var itself => lookup required
  vEqns := eqnsForVarWithStates(mt,vindx);
  vCr := varCref(v);
  prio1 := varStateSelectHeuristicPrio1(vCr,vEqns,vars,eqns);
  prio2 := varStateSelectHeuristicPrio2(vCr,vars);
  prio3 := varStateSelectHeuristicPrio3(vCr,vars);
  prio:= prio1 +. prio2 +. prio3;
end varStateSelectHeuristicPrio;

protected function varStateSelectHeuristicPrio3
"function varStateSelectHeuristicPrio3
  author: PA
  Helper function to varStateSelectHeuristicPrio"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  output Real prio;
algorithm
  prio := matchcontinue(cr,vars)
    local list<BackendDAE.Var> varLst,sameIdentVarLst; Real c,prio;
    case(cr,vars)
      equation
        varLst = varList(vars);
        sameIdentVarLst = Util.listSelect1(varLst,cr,varHasSameLastIdent);
        c = intReal(listLength(sameIdentVarLst));
        prio = c *. 0.01;
      then prio;
  end matchcontinue;
end varStateSelectHeuristicPrio3;

protected function varHasSameLastIdent
"function varHasSameLastIdent
  Helper funciton to varStateSelectHeuristicPrio3.
  Returns true if the variable has the same name (the last identifier)
  as the variable name given as second argument."
  input BackendDAE.Var v;
  input DAE.ComponentRef cr;
  output Boolean b;
algorithm
  b := matchcontinue(v,cr)
    local DAE.ComponentRef cr2; DAE.Ident id1,id2;
    case(BackendDAE.VAR(varName=cr2 ),cr )
      equation
        true = ComponentReference.crefLastIdentEqual(cr,cr2);
      then true;
    case(_,_) then false;
  end matchcontinue;
end varHasSameLastIdent;


protected function varStateSelectHeuristicPrio2
"function varStateSelectHeuristicPrio2
  author: PA
  Helper function to varStateSelectHeuristicPrio"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  output Real prio;
algorithm
  prio := matchcontinue(cr,vars)
    local
      list<BackendDAE.Var> varLst,sameCompVarLst;
    case(cr,vars)
      equation
        varLst = varList(vars);
        sameCompVarLst = Util.listSelect1(varLst,cr,varInSameComponent);
        _::_ = Util.listSelect(sameCompVarLst,isDummyStateVar);
      then -1.0;
    case(cr,vars) then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio2;

protected function varInSameComponent
"function varInSameComponent
  Helper funciton to varStateSelectHeuristicPrio2.
  Returns true if the variable is defined in the same sub
  component as the variable name given as second argument."
  input BackendDAE.Var v;
  input DAE.ComponentRef cr;
  output Boolean b;
algorithm
  b := matchcontinue(v,cr)
    local DAE.ComponentRef cr2; DAE.Ident id1,id2;
    case(BackendDAE.VAR(varName=cr2 ),cr )
      equation
        true = ComponentReference.crefEqualNoStringCompare(ComponentReference.crefStripLastIdent(cr2),ComponentReference.crefStripLastIdent(cr));
      then true;
    case(_,_) then false;
  end matchcontinue;
end varInSameComponent;

protected function varStateSelectHeuristicPrio1
"function varStateSelectHeuristicPrio1
  author:  PA
  Helper function to varStateSelectHeuristicPrio"
  input DAE.ComponentRef cr;
  input list<Integer> eqnLst;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  output Real prio;
algorithm
  prio := matchcontinue(cr,eqnLst,vars,eqns)
    local Integer e; BackendDAE.Equation eqn;
    case(cr,{},_,_) then 0.0;
    case(cr,e::eqnLst,vars,eqns)
      equation
        eqn = equationNth(eqns,e-1);
        true = isStateConstraintEquation(cr,eqn,vars);
      then -1.0;
    case(cr,_::eqnLst,vars,eqns) then varStateSelectHeuristicPrio1(cr,eqnLst,vars,eqns);
 end matchcontinue;
end varStateSelectHeuristicPrio1;

protected function isStateConstraintEquation
"function isStateConstraintEquation
  author: PA
  Help function to varStateSelectHeuristicPrio2
  Returns true if an equation is on the form cr = expr(s1,s2...sn) for states cr, s1,s2..,sn"
  input DAE.ComponentRef cr;
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  output Boolean res;
algorithm
  res := matchcontinue(cr,eqn,vars)
    local
      DAE.ComponentRef cr2;
      list<DAE.ComponentRef> crs;
      list<list<BackendDAE.Var>> crVars;
      list<Boolean> blst;
      DAE.Exp e2;

    // s = expr(s1,..,sn)  where s1 .. sn are states
    case(cr,BackendDAE.EQUATION(exp = DAE.CREF(cr2,_), scalar = e2),vars)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr,cr2);
        _::_::_ = Exp.terms(e2);
        crs = Exp.getCrefFromExp(e2);
        (crVars,_) = Util.listMap12(crs,getVar,vars);
        blst = Util.listMap(Util.listFlatten(crVars),isStateVar);
        res = Util.boolAndList(blst);
      then res;

    case(cr,BackendDAE.EQUATION(exp = e2, scalar = DAE.CREF(cr2,_)),vars)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr,cr2);
        _::_::_ = Exp.terms(e2);
        crs = Exp.getCrefFromExp(e2);
        (crVars,_) = Util.listMap12(crs,getVar,vars);
        blst = Util.listMap(Util.listFlatten(crVars),isStateVar);
        res = Util.boolAndList(blst);
      then res;

    case(cr,eqn,vars) then false;
  end matchcontinue;
end isStateConstraintEquation;

protected function varStateSelectPrio
"function varStateSelectPrio
  Helper function to calculateVarPriorities.
  Calculates a priority contribution bases on the stateSelect attribute."
  input BackendDAE.Var v;
  output Real prio;
  protected
  DAE.StateSelect ss;
algorithm
  ss := varStateSelect(v);
  prio := varStateSelectPrio2(ss);
end varStateSelectPrio;

protected function varStateSelectPrio2
"helper function to varStateSelectPrio"
  input DAE.StateSelect ss;
  output Real prio;
algorithm
  prio := matchcontinue(ss)
    case (DAE.NEVER()) then -10.0;
    case (DAE.AVOID()) then 0.0;
    case (DAE.DEFAULT()) then 10.0;
    case (DAE.PREFER()) then 50.0;
    case (DAE.ALWAYS()) then 100.0;
  end matchcontinue;
end varStateSelectPrio2;

protected function calculateDummyStatePriorities
"function: calculateDummyStatePriority
  Calculates a priority for dummy state candidates.
  The state with lowest priority number is selected as a dummy variable.
  Heuristic parameters:
   1. States that has an initial condition is given pentalty 10.
   2. BackendDAE.Equation s1= p  s2 with states s1 and s2 gives penalty 1 for state s1.
  The heuristic parameters are summed to get the priority number."
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input list<Integer> inIntegerLst;
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output list<tuple<DAE.ComponentRef, Integer, Integer>> outTplExpComponentRefIntegerIntegerLst;
algorithm
  outTplExpComponentRefIntegerIntegerLst:=
  matchcontinue (inExpComponentRefLst,inIntegerLst,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef cr;
      BackendDAE.Value indx,prio;
      list<tuple<BackendDAE.Key, BackendDAE.Value, BackendDAE.Value>> res;
      list<BackendDAE.Key> crs;
      list<BackendDAE.Value> indxs;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
    case ({},{},_,_,_) then {};
    case ((cr :: crs),(indx :: indxs),dae,m,mt)
      equation
        (cr,indx,prio) = calculateDummyStatePriority(cr, indx, dae, m, mt);
        res = calculateDummyStatePriorities(crs, indxs, dae, m, mt);
      then
        ((cr,indx,prio) :: res);
  end matchcontinue;
end calculateDummyStatePriorities;

protected function calculateDummyStatePriority
  input DAE.ComponentRef inComponentRef;
  input Integer inInteger;
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output DAE.ComponentRef outComponentRef1;
  output Integer outInteger2;
  output Integer outInteger3;
algorithm
  (outComponentRef1,outInteger2,outInteger3):=
  matchcontinue (inComponentRef,inInteger,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef cr;
      BackendDAE.Value indx;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
    case (cr,indx,dae,m,mt) then (cr,indx,0);
  end matchcontinue;
end calculateDummyStatePriority;

protected function statesInEqns
"function: statesInEqns
  author: PA
  Helper function to reduce_index_dummy_der.
  Returns all states in the equations given as equation index list.
  inputs:  (int list /* eqns */,
              DAELow,
              IncidenceMatrix,
              IncidenceMatrixT)
  outputs: (DAE.ComponentRef list, /* name for each state */
              int list)  /* number for each state */"
  input list<Integer> inIntegerLst;
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output list<DAE.ComponentRef> outExpComponentRefLst;
  output list<Integer> outIntegerLst;
algorithm
  (outExpComponentRefLst,outIntegerLst):=
  matchcontinue (inIntegerLst,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      list<BackendDAE.Key> res1,res11,res1_1;
      list<BackendDAE.Value> res2,vars2,res22,res2_1,rest;
      BackendDAE.Value e_1,e;
      BackendDAE.Equation eqn;
      list<BackendDAE.Var> varlst;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.DAELow daelow;
    case ({},_,_,_) then ({},{});
    case ((e :: rest),daelow as BackendDAE.DAELOW(orderedVars = vars,orderedEqs = eqns),m,mt)
      equation
        (res1,res2) = statesInEqns(rest, daelow, m, mt);
        e_1 = e - 1;
        eqn = equationNth(eqns, e_1);
        vars2 = statesInEqn(eqn, vars);
        varlst = varList(vars);
        (res11,res22) = statesInVars(varlst, vars2);
        res1_1 = listAppend(res11, res1);
        res2_1 = listAppend(res22, res2);
      then
        (res1_1,res2_1);
    case ((e :: rest),_,_,_)
      local String se;
      equation
        se = intString(e);
        print("-DAELow.statesInEqns failed for eqn: ");
        print(se);
        print("\n");
      then
        fail();
  end matchcontinue;
end statesInEqns;

protected function statesInVars "function: statesInVars
  author: PA

  Helper function to states_in_eqns

  inputs:  (Var list, int list)
  outputs: (DAE.ComponentRef list, /* names of the states */
              int list /* number for each state */)
"
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> inIntegerLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
  output list<Integer> outIntegerLst;
algorithm
  (outExpComponentRefLst,outIntegerLst):=
  matchcontinue (inVarLst,inIntegerLst)
    local
      list<BackendDAE.Var> vars;
      BackendDAE.Value v_1,v;
      DAE.ComponentRef cr;
      DAE.Flow flowPrefix;
      list<BackendDAE.Key> res1;
      list<BackendDAE.Value> res2,rest;
    case (vars,{}) then ({},{});
    case (vars,(v :: rest))
      equation
        v_1 = v - 1;
        BackendDAE.VAR(varName = cr, flowPrefix = flowPrefix) = listNth(vars, v_1);
        (res1,res2) = statesInVars(vars, rest);
      then
        ((cr :: res1),(v :: res2));
    case (vars,(v :: rest))
      equation
        (res1,res2) = statesInVars(vars, rest);
      then
        (res1,res2);
  end matchcontinue;
end statesInVars;

protected function differentiateEqns
"function: differentiateEqns
  author: PA
  This function takes a dae, its incidence matrices and the number of
  equations an variables and a list of equation indices to
  differentiate. This is used in the index reduction algorithm
  using dummy derivatives, when all marked equations are differentiated.
  The function updates the dae, the incidence matrix and returns
  a list of indices of the differentiated equations, they are added last in
  the dae.
  inputs:  (DAELow,
            IncidenceMatrix,
            IncidenceMatrixT,
            int, /* number of vars */
            int, /* number of eqns */
            int list) /* equations */
  outputs: (DAELow,
            IncidenceMatrix,
            IncidenceMatrixT,
            int, /* number of vars */
            int, /* number of eqns */
            int list /* differentiated equations */)"
  input BackendDAE.DAELow inDAELow1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input list<Integer> inIntegerLst6;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  output BackendDAE.DAELow outDAELow1;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix2;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT3;
  output Integer outInteger4;
  output Integer outInteger5;
  output list<Integer> outIntegerLst6;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
algorithm
  (outDAELow1,outIncidenceMatrix2,outIncidenceMatrixT3,outInteger4,outInteger5,outIntegerLst6,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inIntegerLst6,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value nv,nf,e_1,leneqns,e;
      BackendDAE.Equation eqn,eqn_1;
      String str;
      BackendDAE.EquationArray eqns_1,eqns,seqns,ie;
      list<BackendDAE.Value> reqns,es;
      BackendDAE.Variables v,kv,ev;
      BackendDAE.AliasVariables av;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<DAE.Algorithm> al,al1;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses eoc;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1;
    case (dae,m,mt,nv,nf,{},_,inDerivedAlgs,inDerivedMultiEqn) then (dae,m,mt,nv,nf,{},inDerivedAlgs,inDerivedMultiEqn);
    case ((dae as BackendDAE.DAELOW(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc)),m,mt,nv,nf,(e :: es),inFunctions,inDerivedAlgs,inDerivedMultiEqn)
      equation
        e_1 = e - 1;
        eqn = equationNth(eqns, e_1);

        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,true) = Derive.differentiateEquationTime(eqn, v, inFunctions, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        Debug.fprint("bltdump", "High index problem, differentiated equation: ") "update equation row in IncidenceMatrix" ;
        str = BackendDump.equationStr(eqn);
        //print( "differentiated equation ") ;
        Debug.fprint("bltdump", str)  ;
        //print(str); print("\n");
        Debug.fprint("bltdump", " to ");
        //print(" to ");
        str = BackendDump.equationStr(eqn_1);
        //print(str);
        //print("\n");
        Debug.fprint("bltdump", str) "  print \" to \" & print str &  print \"\\n\" &" ;
        Debug.fprint("bltdump", "\n");
        eqns_1 = equationAdd(eqns, eqn_1);
        leneqns = equationSize(eqns_1);
        DAEEXT.markDifferentiated(e) "length gives index of new equation Mark equation as differentiated so it won\'t be differentiated again" ;
        (dae,m,mt,nv,nf,reqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(BackendDAE.DAELOW(v,kv,ev,av,eqns_1,seqns,ie,ae1,al1,wc,eoc), m, mt, nv, nf, es, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (dae,m,mt,nv,nf,(leneqns :: (e :: reqns)),derivedAlgs1,derivedMultiEqn1);
    case ((dae as BackendDAE.DAELOW(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc)),m,mt,nv,nf,(e :: es),inFunctions,inDerivedAlgs,inDerivedMultiEqn)
      equation
        e_1 = e - 1;
        eqn = equationNth(eqns, e_1);

        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,false) = Derive.differentiateEquationTime(eqn, v, inFunctions, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        Debug.fprint("bltdump", "High index problem, differentiated equation: ") "update equation row in IncidenceMatrix" ;
        str = BackendDump.equationStr(eqn);
        //print( "differentiated equation ") ;
        Debug.fprint("bltdump", str)  ;
        //print(str); print("\n");
        Debug.fprint("bltdump", " to ");
        //print(" to ");
        str = BackendDump.equationStr(eqn_1);
        //print(str);
        //print("\n");
        Debug.fprint("bltdump", str) "  print \" to \" & print str &  print \"\\n\" &" ;
        Debug.fprint("bltdump", "\n");
        leneqns = equationSize(eqns);
        DAEEXT.markDifferentiated(e) "length gives index of new equation Mark equation as differentiated so it won\'t be differentiated again" ;
        (dae,m,mt,nv,nf,reqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(BackendDAE.DAELOW(v,kv,ev,av,eqns,seqns,ie,ae1,al1,wc,eoc), m, mt, nv, nf, es, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (dae,m,mt,nv,nf,(e :: reqns),derivedAlgs1,derivedMultiEqn1);        
    case (_,_,_,_,_,_,_,_,_)
      equation
        print("-differentiate_eqns failed\n");
      then
        fail();
  end matchcontinue;
end differentiateEqns;

public function equationAdd "function: equationAdd
  author: PA

  Adds an equation to an EquationArray.
"
  input BackendDAE.EquationArray inEquationArray;
  input BackendDAE.Equation inEquation;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray:=
  matchcontinue (inEquationArray,inEquation)
    local
      BackendDAE.Value n_1,n,size,expandsize,expandsize_1,newsize;
      array<Option<BackendDAE.Equation>> arr_1,arr,arr_2;
      BackendDAE.Equation e;
      Real rsize,rexpandsize;
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr),e)
      equation
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(e));
      then
        BackendDAE.EQUATION_ARRAY(n_1,size,arr_1);
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr),e) /* Do NOT Have space to add array elt. Expand array 1.4 times */
      equation
        (n < size) = false;
        rsize = intReal(size);
        rexpandsize = rsize *. 0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr,NONE());
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(e));
      then
        BackendDAE.EQUATION_ARRAY(n_1,newsize,arr_2);
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr),e)
      equation
        print("-equation_add failed\n");
      then
        fail();
  end matchcontinue;
end equationAdd;

public function equationList "function: equationList
  author: PA

  Transform the expandable BackendDAE.Equation array to a list of Equations.
"
  input BackendDAE.EquationArray inEquationArray;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst:=
  matchcontinue (inEquationArray)
    local
      array<Option<BackendDAE.Equation>> arr;
      BackendDAE.Equation elt;
      BackendDAE.Value lastpos,n,size;
      list<BackendDAE.Equation> lst;
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = 0,equOptArr = arr)) then {};
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = 1,equOptArr = arr))
      equation
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr))
      equation
        lastpos = n - 1;
        lst = equationList2(arr, 0, lastpos);
      then
        lst;
    case (_)
      equation
        print("equation_list failed\n");
      then
        fail();
  end matchcontinue;
end equationList;

public function listEquation "function: listEquation
  author: PA

  Transform the a list of Equations into an expandable BackendDAE.Equation array.
"
  input list<BackendDAE.Equation> lst;
  output BackendDAE.EquationArray outEquationArray;
  BackendDAE.Value len,size;
  Real rlen,rlen_1;
  array<Option<BackendDAE.Equation>> optarr,eqnarr,newarr;
  list<Option<BackendDAE.Equation>> eqn_optlst;
algorithm
  len := listLength(lst);
  rlen := intReal(len);
  rlen_1 := rlen *. 1.4;
  size := realInt(rlen_1);
  optarr := arrayCreate(size, NONE());
  eqn_optlst := Util.listMap(lst, Util.makeOption);
  eqnarr := listArray(eqn_optlst);
  newarr := Util.arrayCopy(eqnarr, optarr);
  outEquationArray := BackendDAE.EQUATION_ARRAY(len,size,newarr);
end listEquation;

protected function equationList2 "function: equationList2
  author: PA

  Helper function to equation_list

  inputs:  (Equation option array, int /* pos */, int /* lastpos */)
  outputs: BackendDAE.Equation list

"
  input array<Option<BackendDAE.Equation>> inEquationOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst:=
  matchcontinue (inEquationOptionArray1,inInteger2,inInteger3)
    local
      BackendDAE.Equation e;
      array<Option<BackendDAE.Equation>> arr;
      BackendDAE.Value pos,lastpos,pos_1;
      list<BackendDAE.Equation> res;
    case (arr,pos,lastpos)
      equation
        (pos == lastpos) = true;
        SOME(e) = arr[pos + 1];
      then
        {e};
    case (arr,pos,lastpos)
      equation
        pos_1 = pos + 1;
        SOME(e) = arr[pos + 1];
        res = equationList2(arr, pos_1, lastpos);
      then
        (e :: res);
  end matchcontinue;
end equationList2;

public function systemSize "returns the size of the dae system"
input BackendDAE.DAELow dae;
output Integer n;
algorithm
  n := matchcontinue(dae)
  local BackendDAE.EquationArray eqns;
    case(BackendDAE.DAELOW(orderedEqs = eqns))
      equation
        n = equationSize(eqns);
      then n;

  end matchcontinue;
end systemSize;

public function equationSize "function: equationSize
  author: PA

  Returns the number of equations in an EquationArray, which
  corresponds to the number of equations in a system.
  NOTE: Array equations and algorithms are represented several times
  in the array so the number of elements of the array corresponds to
  the equation system size.
"
  input BackendDAE.EquationArray inEquationArray;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inEquationArray)
    local BackendDAE.Value n;
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n)) then n;
  end matchcontinue;
end equationSize;

public function varsSize "function: varsSize
  author: PA

  Returns the number of variables
"
  input BackendDAE.Variables inVariables;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inVariables)
    local BackendDAE.Value n;
    case (BackendDAE.VARIABLES(numberOfVars = n)) then n;
  end matchcontinue;
end varsSize;

public function equationNth "function: equationNth
  author: PA

  Return the n:th equation from the expandable equation array
  indexed from 0..1.

  inputs:  (EquationArray, int /* n */)
  outputs:  Equation

"
  input BackendDAE.EquationArray inEquationArray;
  input Integer inInteger;
  output BackendDAE.Equation outEquation;
algorithm
  outEquation:=
  matchcontinue (inEquationArray,inInteger)
    local
      BackendDAE.Equation e;
      BackendDAE.Value n,pos;
      array<Option<BackendDAE.Equation>> arr;
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,equOptArr = arr),pos)
      equation
        (pos < n) = true;
        SOME(e) = arr[pos + 1];
      then
        e;
    case (_,_)
      equation
        print("equation_nth failed\n");
      then
        fail();
  end matchcontinue;
end equationNth;

public function equationSetnth "function: equationSetnth
  author: PA

  Sets the nth array element of an EquationArray.
"
  input BackendDAE.EquationArray inEquationArray;
  input Integer inInteger;
  input BackendDAE.Equation inEquation;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray:=
  matchcontinue (inEquationArray,inInteger,inEquation)
    local
      array<Option<BackendDAE.Equation>> arr_1,arr;
      BackendDAE.Value n,size,pos;
      BackendDAE.Equation eqn;
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr),pos,eqn)
      equation
        arr_1 = arrayUpdate(arr, pos + 1, SOME(eqn));
      then
        BackendDAE.EQUATION_ARRAY(n,size,arr_1);
  end matchcontinue;
end equationSetnth;

protected function addMarkedVars "function: addMarkedVars
  author: PA

  This function is part of the matching algorithm.

  inputs:  (DAELow,
              IncidenceMatrix,
              IncidenceMatrixT,
              int, /* number of vars */
              int, /* number of eqns */
              int list /* marked vars */)
  outputs: (DAELow,
              IncidenceMatrix,
              IncidenceMatrixT,
              int, /* number of vars */
              int  /* number of eqns */)
"
  input BackendDAE.DAELow inDAELow1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input list<Integer> inIntegerLst6;
  output BackendDAE.DAELow outDAELow1;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix2;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT3;
  output Integer outInteger4;
  output Integer outInteger5;
algorithm
  (outDAELow1,outIncidenceMatrix2,outIncidenceMatrixT3,outInteger4,outInteger5):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inIntegerLst6)
    local
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt,nt;
      BackendDAE.Value nv,nf,nv_1,v;
      list<BackendDAE.Value> vs;
    case (dae,m,mt,nv,nf,{}) then (dae,m,mt,nv,nf);
    case (dae,m,nt,nv,nf,(v :: vs))
      equation
        nv_1 = nv + 1 "TODO remove variable from dae and m,mt and add der{variable} instead" ;
        DAEEXT.setV(v, nv_1);
        (dae,m,mt,nv,nf) = addMarkedVars(dae, m, nt, nv_1, nf, vs);
      then
        (dae,m,mt,nv,nf);
  end matchcontinue;
end addMarkedVars;

protected function pathFound "function: pathFound
  author: PA

  This function is part of the matching algorithm.
  It tries to find a matching for the equation index given as
  third argument, i.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int /* equation */,
               Assignments, Assignments)
  outputs: (Assignments, Assignments)
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input BackendDAE.Assignments inAssignments4;
  input BackendDAE.Assignments inAssignments5;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inAssignments4,inAssignments5)
    local
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value i;
    case (m,mt,i,ass1,ass2)
      equation
        DAEEXT.eMark(i) "Side effect" ;
        (ass1_1,ass2_1) = assignOneInEqn(m, mt, i, ass1, ass2);
      then
        (ass1_1,ass2_1);
    case (m,mt,i,ass1,ass2)
      equation
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqn(m, mt, i, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end pathFound;

protected function assignOneInEqn "function: assignOneInEqn
  author: PA

  Helper function to path_found.
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input BackendDAE.Assignments inAssignments4;
  input BackendDAE.Assignments inAssignments5;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inAssignments4,inAssignments5)
    local
      list<BackendDAE.Value> vars;
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value i;
    case (m,mt,i,ass1,ass2)
      equation
        vars = varsInEqn(m, i);
        (ass1_1,ass2_1) = assignFirstUnassigned(i, vars, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assignOneInEqn;

protected function statesInEqn "function: statesInEqn
  author: PA
  Helper function to states_in_eqns
"
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  output list<Integer> res;
  BackendDAE.Variables vars_1;
algorithm
  vars_1 := statesAsAlgebraicVars(vars);
  res := incidenceRow(vars_1, eqn,{});
end statesInEqn;

protected function statesAsAlgebraicVars "function: statesAsAlgebraicVars
  author: PA

  Return the subset of variables consisting of all states, but changed
  varkind to variable.
"
  input BackendDAE.Variables vars;
  output BackendDAE.Variables v1_1;
  list<BackendDAE.Var> varlst,varlst_1;
  BackendDAE.Variables v1,v1_1;
algorithm
  varlst := varList(vars) "Creates a new set of BackendDAE.Variables from a BackendDAE.Var list" ;
  varlst_1 := statesAsAlgebraicVars2(varlst);
  v1 := emptyVars();
  v1_1 := addVars(varlst_1, v1);
end statesAsAlgebraicVars;

protected function statesAsAlgebraicVars2 "function: statesAsAlgebraicVars2
  author: PA

  helper function to states_as_algebraic_vars
"
  input list<BackendDAE.Var> inVarLst;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVarLst)
    local
      list<BackendDAE.Var> res,vs;
      DAE.ComponentRef cr;
      DAE.VarDirection a;
      BackendDAE.Type b;
      Option<DAE.Exp> c,f;
      Option<Values.Value> d;
      list<DAE.Subscript> e;
      BackendDAE.Value g;
      list<Absyn.Path> i;
      DAE.ElementSource source "the element source";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;

    case {} then {};
    case ((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.STATE(),
               varDirection = a,
               varType = b,
               bindExp = c,
               bindValue = d,
               arryDim = e,
               index = g,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix) :: vs))
      equation
        res = statesAsAlgebraicVars2(vs) "states treated as algebraic variables" ;
      then
        (BackendDAE.VAR(cr,BackendDAE.VARIABLE(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: res);

    case ((BackendDAE.VAR(varName = cr,
               varDirection = a,
               varType = b,
               bindExp = c,
               bindValue = d,
               arryDim = e,
               index = g,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix) :: vs))
      equation
        res = statesAsAlgebraicVars2(vs) "other variables treated as known" ;
      then
        (BackendDAE.VAR(cr,BackendDAE.CONST(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: res);

    case ((_ :: vs))
      equation
        res = statesAsAlgebraicVars2(vs);
      then
        res;
  end matchcontinue;
end statesAsAlgebraicVars2;

public function varsInEqn
"function: varsInEqn
  author: PA
  This function returns all variable indices as a list for
  a given equation, given as an equation index. (1...n)
  Negative indexes are removed.
  See also: eqnsForVar and eqnsForVarWithStates
  inputs:  (IncidenceMatrix, int /* equation */)
  outputs:  int list /* variables */"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input Integer inInteger;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inIncidenceMatrix,inInteger)
    local
      BackendDAE.Value n_1,n,indx;
      list<BackendDAE.Value> res,res_1;
      array<list<BackendDAE.Value>> m;
      String s;
    case (m,n)
      equation
        n_1 = n - 1;
        res = m[n_1 + 1];
        res_1 = removeNegative(res);
      then
        res_1;
    case (_,indx)
      equation
        print("vars_in_eqn failed, indx=");
        s = intString(indx);
        print(s);
        print("\n");
      then
        fail();
  end matchcontinue;
end varsInEqn;

protected function removeNegative
"function: removeNegative
  author: PA
  Removes all negative integers."
  input list<Integer> lst;
  output list<Integer> lst_1;
algorithm
  lst_1 := Util.listSelect(lst, Util.intPositive);
end removeNegative;

protected function eqnsForVar
"function: eqnsForVar
  author: PA
  This function returns all equations as a list of
  equation indices given a variable as a variable index.
  See also: eqnsForVarWithStates and varsInEqn
  inputs:  (IncidenceMatrixT, int /* variable */)
  outputs:  int list /* equations */"
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input Integer inInteger;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inIncidenceMatrixT,inInteger)
    local
      BackendDAE.Value n_1,n,indx;
      list<BackendDAE.Value> res,res_1;
      array<list<BackendDAE.Value>> mt;
      String s;
    case (mt,n)
      equation
        n_1 = n - 1;
        res = mt[n_1 + 1];
        res_1 = removeNegative(res);
      then
        res_1;
    case (_,indx)
      equation
        print("eqnsForVar failed, indx=");
        s = intString(indx);
        print(s);
        print("\n");
      then
        fail();
  end matchcontinue;
end eqnsForVar;

protected function eqnsForVarWithStates
"function: eqnsForVarWithStates
  author: PA
  This function returns all equations as a list of equation indices
  given a variable as a variable index, including the equations containing
  the state variable but not its derivative. This must be used to update
  equations when a state is changed to algebraic variable in index reduction
  using dummy derivatives.
  These equation indices are represented with negative index, thus all
  indices are mapped trough int_abs (absolute value).
  inputs:  (IncidenceMatrixT, int /* variable */)
  outputs:  int list /* equations */"
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input Integer inInteger;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inIncidenceMatrixT,inInteger)
    local
      BackendDAE.Value n_1,n,indx;
      list<BackendDAE.Value> res,res_1;
      array<list<BackendDAE.Value>> mt;
      String s;
    case (mt,n)
      equation
        n_1 = n - 1;
        res = mt[n_1 + 1];
        res_1 = Util.listMap(res, int_abs);
      then
        res_1;
    case (_,indx)
      equation
        print("eqnsForVarWithStates failed, indx=");
        s = intString(indx);
        print(s);
        print("\n");
      then
        fail();
  end matchcontinue;
end eqnsForVarWithStates;

protected function assignFirstUnassigned
"function: assignFirstUnassigned
  author: PA
  This function assigns the first unassign variable to the equation
  given as first argument. It is part of the matching algorithm.
  inputs:  (int /* equation */,
            int list /* variables */,
            BackendDAE.Assignments /* ass1 */,
            BackendDAE.Assignments /* ass2 */)
  outputs: (Assignments,  /* ass1 */
            Assignments)  /* ass2 */"
  input Integer inInteger1;
  input list<Integer> inIntegerLst2;
  input BackendDAE.Assignments inAssignments3;
  input BackendDAE.Assignments inAssignments4;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inInteger1,inIntegerLst2,inAssignments3,inAssignments4)
    local
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
      BackendDAE.Value i,v;
      list<BackendDAE.Value> vs;
    case (i,(v :: vs),ass1,ass2)
      equation
        0 = getAssigned(v, ass1, ass2);
        (ass1_1,ass2_1) = assign(v, i, ass1, ass2);
      then
        (ass1_1,ass2_1);
    case (i,(v :: vs),ass1,ass2)
      equation
        (ass1_1,ass2_1) = assignFirstUnassigned(i, vs, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assignFirstUnassigned;

protected function getAssigned
"function: getAssigned
  author: PA
  returns the assigned equation for a variable.
  inputs:  (int    /* variable */,
            Assignments,  /* ass1 */
            Assignments)  /* ass2 */
  outputs:  int /* equation */"
  input Integer inInteger1;
  input BackendDAE.Assignments inAssignments2;
  input BackendDAE.Assignments inAssignments3;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inInteger1,inAssignments2,inAssignments3)
    local
      BackendDAE.Value v;
      array<BackendDAE.Value> m;
    case (v,BackendDAE.ASSIGNMENTS(arrOfIndices = m),_) then m[v];
  end matchcontinue;
end getAssigned;

protected function assign
"function: assign
  author: PA
  Assign a variable to an equation, updating both assignment lists.
  inputs: (int, /* variable */
           int, /* equation */
           Assignments, /* ass1 */
           Assignments) /* ass2 */
  outputs: (Assignments,  /* updated ass1 */
            Assignments)  /* updated ass2 */"
  input Integer inInteger1;
  input Integer inInteger2;
  input BackendDAE.Assignments inAssignments3;
  input BackendDAE.Assignments inAssignments4;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inInteger1,inInteger2,inAssignments3,inAssignments4)
    local
      BackendDAE.Value v_1,e_1,v,e;
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
    case (v,e,ass1,ass2)
      equation
        v_1 = v - 1 "print \"assign \" & intString v => vs & intString e => es & print vs & print \" to eqn \" & print es & print \"\\n\" &" ;
        e_1 = e - 1;
        ass1_1 = assignmentsSetnth(ass1, v_1, e);
        ass2_1 = assignmentsSetnth(ass2, e_1, v);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assign;

protected function forallUnmarkedVarsInEqn
"function: forallUnmarkedVarsInEqn
  author: PA
  This function is part of the matching algorithm.
  It loops over all umarked variables in an equation.
  inputs:  (IncidenceMatrix,
            IncidenceMatrixT,
            int,
            BackendDAE.Assignments /* ass1 */,
            BackendDAE.Assignments /* ass2 */)
  outputs: (Assignments, Assignments)"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input BackendDAE.Assignments inAssignments4;
  input BackendDAE.Assignments inAssignments5;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inAssignments4,inAssignments5)
    local
      list<BackendDAE.Value> vars,vars_1;
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value i;
    case (m,mt,i,ass1,ass2)
      equation
        vars = varsInEqn(m, i);
        vars_1 = Util.listFilter(vars, isNotVMarked);
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqnBody(m, mt, i, vars_1, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end forallUnmarkedVarsInEqn;

protected function isNotVMarked
"function: isNotVMarked
  author: PA
  This function succeds for variables that are not marked."
  input Integer i;
algorithm
  false := DAEEXT.getVMark(i);
end isNotVMarked;

protected function forallUnmarkedVarsInEqnBody
"function: forallUnmarkedVarsInEqnBody
  author: PA
  This function is part of the matching algorithm.
  It is the body of the loop over all unmarked variables.
  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT,
            int,
            int list /* var list */
            Assignments
            Assignments)
  outputs: (Assignments, Assignments)"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input list<Integer> inIntegerLst4;
  input BackendDAE.Assignments inAssignments5;
  input BackendDAE.Assignments inAssignments6;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inIntegerLst4,inAssignments5,inAssignments6)
    local
      BackendDAE.Value assarg,i,v;
      BackendDAE.Assignments ass1_1,ass2_1,ass1_2,ass2_2,ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
      list<BackendDAE.Value> vars,vs;
    case (m,mt,i,(vars as (v :: vs)),ass1,ass2)
      equation
        DAEEXT.vMark(v);
        assarg = getAssigned(v, ass1, ass2);
        (ass1_1,ass2_1) = pathFound(m, mt, assarg, ass1, ass2);
        (ass1_2,ass2_2) = assign(v, i, ass1_1, ass2_1);
      then
        (ass1_2,ass2_2);
    case (m,mt,i,(vars as (v :: vs)),ass1,ass2)
      equation
        DAEEXT.vMark(v);
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqnBody(m, mt, i, vs, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end forallUnmarkedVarsInEqnBody;

public function strongComponents "function: strongComponents
  author: PA

  This is the second part of the BLT sorting. It takes the variable
  assignments and the incidence matrix as input and identifies strong
  components, i.e. subsystems of equations.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector)
  outputs: (int list list /* list of components */ )
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst:=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4)
    local
      BackendDAE.Value n,i;
      list<BackendDAE.Value> stack;
      list<list<BackendDAE.Value>> comps;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> ass1,ass2;
    case (m,mt,ass1,ass2)
      equation
        n = arrayLength(m);
        DAEEXT.initLowLink(n);
        DAEEXT.initNumber(n);
        (i,stack,comps) = strongConnectMain(m, mt, ass1, ass2, n, 0, 1, {}, {});
      then
        comps;
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "strong_components failed\n");
        Error.addMessage(Error.INTERNAL_ERROR,
          {"sorting equations(strong components failed)"});
      then
        fail();
  end matchcontinue;
end strongComponents;

protected function strongConnectMain "function: strongConnectMain
  author: PA

  Helper function to strong_components

  inputs:  (IncidenceMatrix,
              IncidenceMatrixT,
              int vector, /* Assignment */
              int vector, /* Assignment */
              int, /* n - number of equations */
              int, /* i */
              int, /* w */
              int list, /* stack */
              int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */)
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input Integer inInteger7;
  input list<Integer> inIntegerLst8;
  input list<list<Integer>> inIntegerLstLst9;
  output Integer outInteger;
  output list<Integer> outIntegerLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outInteger,outIntegerLst,outIntegerLstLst):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inInteger7,inIntegerLst8,inIntegerLstLst9)
    local
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      BackendDAE.Value n,i,w,w_1,num;
      list<BackendDAE.Value> stack,stack_1,stack_2;
      list<list<BackendDAE.Value>> comp,comps;
    case (m,mt,a1,a2,n,i,w,stack,comp)
      equation
        (w > n) = true;
      then
        (i,stack,comp);
    case (m,mt,a1,a2,n,i,w,stack,comps)
      local list<list<Integer>> comps2;

      equation
        0 = DAEEXT.getNumber(w);
        (i,stack_1,comps) = strongConnect(m, mt, a1, a2, i, w, stack, comps);
        w_1 = w + 1;
        (i,stack_2,comps) = strongConnectMain(m, mt, a1, a2, n, i, w_1, stack_1, comps);
      then
        (i,stack_2,comps);
    case (m,mt,a1,a2,n,i,w,stack,comps)
      equation
        num = DAEEXT.getNumber(w);
        (num == 0) = false;
        w_1 = w + 1;
        (i,stack_1,comps) = strongConnectMain(m, mt, a1, a2, n, i, w_1, stack, comps);
      then
        (i,stack_1,comps);
  end matchcontinue;
end strongConnectMain;

protected function strongConnect "function: strongConnect
  author: PA

  Helper function to strong_connect_main

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */ )
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input list<Integer> inIntegerLst7;
  input list<list<Integer>> inIntegerLstLst8;
  output Integer outInteger;
  output list<Integer> outIntegerLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outInteger,outIntegerLst,outIntegerLstLst):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inIntegerLst7,inIntegerLstLst8)
    local
      BackendDAE.Value i_1,i,v;
      list<BackendDAE.Value> stack_1,eqns,stack_2,stack_3,comp,stack;
      list<list<BackendDAE.Value>> comps_1,comps_2,comps;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
    case (m,mt,a1,a2,i,v,stack,comps)
      equation
        i_1 = i + 1;
        DAEEXT.setNumber(v, i_1)  ;
        DAEEXT.setLowLink(v, i_1);
        stack_1 = (v :: stack);
        eqns = reachableNodes(v, m, mt, a1, a2);
        (i_1,stack_2,comps_1) = iterateReachableNodes(eqns, m, mt, a1, a2, i_1, v, stack_1, comps);
        (i_1,stack_3,comp) = checkRoot(m, mt, a1, a2, i_1, v, stack_2);
        comps_2 = consIfNonempty(comp, comps_1);
      then
        (i_1,stack_3,comps_2);
    case (_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-strong_connect failed\n");
      then
        fail();
  end matchcontinue;
end strongConnect;

protected function consIfNonempty "function: consIfNonempty
  author: PA

  Small helper function to avoid empty sublists.
  Consider moving to Util?
"
  input list<Integer> inIntegerLst;
  input list<list<Integer>> inIntegerLstLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst:=
  matchcontinue (inIntegerLst,inIntegerLstLst)
    local
      list<list<BackendDAE.Value>> lst;
      list<BackendDAE.Value> e;
    case ({},lst) then lst;
    case (e,lst) then (e :: lst);
  end matchcontinue;
end consIfNonempty;

public function reachableNodes "function: reachableNodes
  author: PA

  Helper function to strong_connect.
  Returns a list of reachable nodes (equations), corresponding
  to those equations that uses the solved variable of this equation.
  The edges of the graph that identifies strong components/blocks are
  dependencies between blocks. A directed edge e = (n1,n2) means
  that n1 solves for a variable (e.g. \'a\') that is used in the equation
  of n2, i.e. the equation of n1 must be solved before the equation of n2.
"
  input Integer inInteger1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input array<Integer> inIntegerArray4;
  input array<Integer> inIntegerArray5;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inInteger1,inIncidenceMatrix2,inIncidenceMatrixT3,inIntegerArray4,inIntegerArray5)
    local
      BackendDAE.Value eqn_1,var,var_1,pos,eqn;
      list<BackendDAE.Value> reachable,reachable_1,reachable_2;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      String eqnstr;
    case (eqn,m,mt,a1,a2)
      equation
        eqn_1 = eqn - 1;
        var = a2[eqn_1 + 1];
        var_1 = var - 1;
        reachable = mt[var_1 + 1] "Got the variable that is solved in the equation" ;
        reachable_1 = removeNegative(reachable) "in which other equations is this variable present ?" ;
        pos = Util.listPosition(eqn, reachable_1) ".. except this one" ;
        reachable_2 = listDelete(reachable_1, pos);
      then
        reachable_2;
    case (eqn,_,_,_,_)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "-reachable_nodes failed, eqn: ");
        eqnstr = intString(eqn);
        Debug.fprint("failtrace", eqnstr);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end reachableNodes;

protected function iterateReachableNodes "function: iterateReachableNodes
  author: PA

  Helper function to strong_connect.

  inputs:  (int list, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */)
"
  input list<Integer> inIntegerLst1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input array<Integer> inIntegerArray4;
  input array<Integer> inIntegerArray5;
  input Integer inInteger6;
  input Integer inInteger7;
  input list<Integer> inIntegerLst8;
  input list<list<Integer>> inIntegerLstLst9;
  output Integer outInteger;
  output list<Integer> outIntegerLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outInteger,outIntegerLst,outIntegerLstLst):=
  matchcontinue (inIntegerLst1,inIncidenceMatrix2,inIncidenceMatrixT3,inIntegerArray4,inIntegerArray5,inInteger6,inInteger7,inIntegerLst8,inIntegerLstLst9)
    local
      BackendDAE.Value i,lv,lw,minv,w,v,nw,nv,lowlinkv;
      list<BackendDAE.Value> stack,ws;
      list<list<BackendDAE.Value>> comps_1,comps_2,comps;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        0 = DAEEXT.getNumber(w);
        (i,stack,comps_1) = strongConnect(m, mt, a1, a2, i, w, stack, comps);
        lv = DAEEXT.getLowLink(v);
        lw = DAEEXT.getLowLink(w);
        minv = intMin(lv, lw);
        DAEEXT.setLowLink(v, minv);
        (i,stack,comps_2) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps_1);
      then
        (i,stack,comps_2);
    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        nw = DAEEXT.getNumber(w);
        nv = DAEEXT.getNumber(v);
        (nw < nv) = true;
        true = listMember(w, stack);
        lowlinkv = DAEEXT.getLowLink(v);
        minv = intMin(nw, lowlinkv);
        DAEEXT.setLowLink(v, minv);
        (i,stack,comps_1) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps);
      then
        (i,stack,comps_1);

    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        (i,stack,comps_1) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps);
      then
        (i,stack,comps_1);
    case ({},m,mt,a1,a2,i,v,stack,comps) then (i,stack,comps);
  end matchcontinue;
end iterateReachableNodes;

protected function checkRoot "function: checkRoot
  author: PA

  Helper function to strong_connect.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */)
  outputs: (int /* i */, int list /* stack */, int list /* comps */)
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input list<Integer> inIntegerLst7;
  output Integer outInteger1;
  output list<Integer> outIntegerLst2;
  output list<Integer> outIntegerLst3;
algorithm
  (outInteger1,outIntegerLst2,outIntegerLst3):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inIntegerLst7)
    local
      BackendDAE.Value lv,nv,i,v;
      list<BackendDAE.Value> stack_1,comps,stack;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
    case (m,mt,a1,a2,i,v,stack)
      equation
        lv = DAEEXT.getLowLink(v);
        nv = DAEEXT.getNumber(v);
        (lv == nv) = true;
        (i,stack_1,comps) = checkStack(m, mt, a1, a2, i, v, stack, {});
      then
        (i,stack_1,comps);
    case (m,mt,a1,a2,i,v,stack) then (i,stack,{});
  end matchcontinue;
end checkRoot;

protected function checkStack "function: checkStack
  author: PA

  Helper function to check_root.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list /* component list */)
  outputs: (int /* i */, int list /* stack */, int list /* comps */)
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input list<Integer> inIntegerLst7;
  input list<Integer> inIntegerLst8;
  output Integer outInteger1;
  output list<Integer> outIntegerLst2;
  output list<Integer> outIntegerLst3;
algorithm
  (outInteger1,outIntegerLst2,outIntegerLst3):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inIntegerLst7,inIntegerLst8)
    local
      BackendDAE.Value topn,vn,i,v,top;
      list<BackendDAE.Value> stack_1,comp_1,rest,comp,stack;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
    case (m,mt,a1,a2,i,v,(top :: rest),comp)
      equation
        topn = DAEEXT.getNumber(top);
        vn = DAEEXT.getNumber(v);
        (topn >= vn) = true;
        (i,stack_1,comp_1) = checkStack(m, mt, a1, a2, i, v, rest, comp);
      then
        (i,stack_1,(top :: comp_1));
    case (m,mt,a1,a2,i,v,stack,comp) then (i,stack,comp);
  end matchcontinue;
end checkStack;

public function translateDae "function: translateDae
  author: PA

  Translates the dae so variables are indexed into different arrays:
  - xd for derivatives
  - x for states
  - dummy_der for dummy derivatives
  - dummy for dummy states
  - y for algebraic variables
  - p for parameters
"
  input BackendDAE.DAELow inDAELow;
  input Option<String> dummy;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow:=
  matchcontinue (inDAELow,dummy)
    local
      list<BackendDAE.Var> varlst,knvarlst,extvarlst;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      list<BackendDAE.WhenClause> wc;
      list<BackendDAE.ZeroCrossing> zc;
      BackendDAE.Variables vars, knvars, extVars;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,seqns,ieqns;
      BackendDAE.DAELow trans_dae;
      BackendDAE.ExternalObjectClasses extObjCls;
    case (BackendDAE.DAELOW(vars,knvars,extVars,av,eqns,seqns,ieqns,ae,al,BackendDAE.EVENT_INFO(whenClauseLst = wc,zeroCrossingLst = zc),extObjCls),_)
      equation
        varlst = varList(vars);
        knvarlst = varList(knvars);
        extvarlst = varList(extVars);
        varlst = listReverse(varlst);
        knvarlst = listReverse(knvarlst);
        extvarlst = listReverse(extvarlst);
        (varlst,knvarlst,extvarlst) = calculateIndexes(varlst, knvarlst,extvarlst);
        vars = addVars(varlst, vars);
        knvars = addVars(knvarlst, knvars);
        extVars = addVars(extvarlst, extVars);
        trans_dae = BackendDAE.DAELOW(vars,knvars,extVars,av,eqns,seqns,ieqns,ae,al,
          BackendDAE.EVENT_INFO(wc,zc),extObjCls);
        Debug.fcall("dumpindxdae", BackendDump.dump, trans_dae);
      then
        trans_dae;
  end matchcontinue;
end translateDae;

public function addVars "function: addVars
  author: PA

  Adds a list of \'Var\' to \'Variables\'
"
  input list<BackendDAE.Var> varlst;
  input BackendDAE.Variables vars;
  output BackendDAE.Variables vars_1;
  BackendDAE.Variables vars_1;
algorithm
  vars_1 := Util.listFold(varlst, addVar, vars);
end addVars;

public function analyzeJacobian "function: analyzeJacobian
  author: PA

  Analyze the jacobian to find out if the jacobian of system of equations
  can be solved at compiletime or runtime or if it is a nonlinear system
  of equations.
"
  input BackendDAE.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> inTplIntegerIntegerEquationLstOption;
  output BackendDAE.JacobianType outJacobianType;
algorithm
  outJacobianType:=
  matchcontinue (inDAELow,inTplIntegerIntegerEquationLstOption)
    local
      BackendDAE.DAELow daelow;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> jac;
    case (daelow,SOME(jac))
      equation
        true = jacobianConstant(jac);
        true = rhsConstant(daelow);
      then
        BackendDAE.JAC_CONSTANT();
    case (daelow,SOME(jac))
      equation
        true = jacobianNonlinear(daelow, jac);
      then
        BackendDAE.JAC_NONLINEAR();
    case (daelow,SOME(jac)) then BackendDAE.JAC_TIME_VARYING();
    case (daelow,NONE()) then BackendDAE.JAC_NO_ANALYTIC();
  end matchcontinue;
end analyzeJacobian;

protected function rhsConstant "function: rhsConstant
  author: PA

  Determines if the right hand sides of an equation system,
  represented as a DAELow, is constant.
"
  input BackendDAE.DAELow inDAELow;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inDAELow)
    local
      list<BackendDAE.Equation> eqn_lst;
      Boolean res;
      BackendDAE.DAELow dae;
      BackendDAE.Variables vars,knvars;
      BackendDAE.EquationArray eqns;
    case ((dae as BackendDAE.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns)))
      equation
        eqn_lst = equationList(eqns);
        res = rhsConstant2(eqn_lst, dae);
      then
        res;
  end matchcontinue;
end rhsConstant;

public function getEqnsysRhsExp "function: getEqnsysRhsExp
  author: PA

  Retrieve the right hand side expression of an equation
  in an equation system, given a set of variables.

  inputs:  (DAE.Exp, BackendDAE.Variables /* variables of the eqn sys. */)
  outputs:  DAE.Exp =
"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp,inVariables)
    local
      list<DAE.Exp> term_lst,rhs_lst,rhs_lst2;
      DAE.Exp new_exp,res,exp;
      BackendDAE.Variables vars;
    case (exp,vars)
      equation
        term_lst = Exp.allTerms(exp);
        rhs_lst = Util.listSelect1(term_lst, vars, freeFromAnyVar);
        /* A term can contain if-expressions that has branches that are on rhs and other branches that
        are on lhs*/
        rhs_lst2 = ifBranchesFreeFromVar(term_lst,vars);
        new_exp = Exp.makeSum(listAppend(rhs_lst,rhs_lst2));
        res = Exp.simplify(new_exp);
      then
        res;
    case (_,_)
      equation
        Debug.fprint("failtrace", "-get_eqnsys_rhs_exp failed\n");
      then
        fail();
  end matchcontinue;
end getEqnsysRhsExp;

public function ifBranchesFreeFromVar "Retrieves if-branches free from any of the variables passed as argument.

This is done by replacing the variables with zero."
  input list<DAE.Exp> expl;
  input BackendDAE.Variables vars;
  output list<DAE.Exp> outExpl;
algorithm
  outExpl := matchcontinue(expl,vars)
    local DAE.Exp cond,t,f,e1,e2;
      VarTransform.VariableReplacements repl;
      DAE.Operator op;
      Absyn.Path path;
      list<DAE.Exp> expl2;
      Boolean tpl ;
      Boolean b;
      DAE.InlineType i;
      DAE.ExpType ty;
    case({},vars) then {};
    case(DAE.IFEXP(cond,t,f)::expl,vars) equation
      repl = makeZeroReplacements(vars);
      t = ifBranchesFreeFromVar2(t,repl);
      f = ifBranchesFreeFromVar2(f,repl);
      expl = ifBranchesFreeFromVar(expl,vars);
    then (DAE.IFEXP(cond,t,f)::expl);
    case(DAE.BINARY(e1,op,e2)::expl,vars) equation
      repl = makeZeroReplacements(vars);
      {e1} = ifBranchesFreeFromVar({e1},vars);
      {e2} = ifBranchesFreeFromVar({e2},vars);
      expl = ifBranchesFreeFromVar(expl,vars);
    then (DAE.BINARY(e1,op,e2)::expl);

    case(DAE.UNARY(op,e1)::expl,vars) equation
      repl = makeZeroReplacements(vars);
      {e1} = ifBranchesFreeFromVar({e1},vars);
      expl = ifBranchesFreeFromVar(expl,vars);
    then (DAE.UNARY(op,e1)::expl);

    case(DAE.CALL(path,expl2,tpl,b,ty,i)::expl,vars) equation
      repl = makeZeroReplacements(vars);
      (expl2 as _::_) = ifBranchesFreeFromVar(expl2,vars);
      expl = ifBranchesFreeFromVar(expl,vars);
    then (DAE.CALL(path,expl2,tpl,b,ty,i)::expl);

  case(_::expl,vars) equation
      expl = ifBranchesFreeFromVar(expl,vars);
  then expl;
  end matchcontinue;
end ifBranchesFreeFromVar;

protected function ifBranchesFreeFromVar2 "Help function to ifBranchesFreeFromVar,
replaces variables in if branches (not conditions) recursively (to include elseifs)"
  input DAE.Exp ifBranch;
  input VarTransform.VariableReplacements repl;
  output DAE.Exp outIfBranch;
algorithm
  outIfBranch := matchcontinue(ifBranch,repl)
  local DAE.Exp cond,t,f,e;
    case(DAE.IFEXP(cond,t,f),repl) equation
      t = ifBranchesFreeFromVar2(t,repl);
      f = ifBranchesFreeFromVar2(f,repl);
    then DAE.IFEXP(cond,t,f);
    case(e,repl) equation
      e = VarTransform.replaceExp(e,repl,NONE());
    then e;
  end matchcontinue;
end ifBranchesFreeFromVar2;

protected function makeZeroReplacements "Help function to ifBranchesFreeFromVar, creates replacement rules
v -> 0, for all variables"
  input BackendDAE.Variables vars;
  output VarTransform.VariableReplacements repl;
  protected list<BackendDAE.Var> varLst;
algorithm
  varLst := varList(vars);
  repl := Util.listFold(varLst,makeZeroReplacement,VarTransform.emptyReplacements());
end makeZeroReplacements;

protected function makeZeroReplacement "helper function to makeZeroReplacements.
Creates replacement Var-> 0"
  input BackendDAE.Var var;
  input VarTransform.VariableReplacements repl;
  output VarTransform.VariableReplacements outRepl;
  protected
  DAE.ComponentRef cr;
algorithm
  cr :=  varCref(var);
  outRepl := VarTransform.addReplacement(repl,cr,DAE.RCONST(0.0));
end makeZeroReplacement;

public function getEquationBlock "function: getEquationBlock
  author: PA

  Returns the block the equation belongs to.
"
  input Integer inInteger;
  input list<list<Integer>> inIntegerLstLst;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inInteger,inIntegerLstLst)
    local
      BackendDAE.Value e;
      list<BackendDAE.Value> block_,res;
      list<list<BackendDAE.Value>> blocks;
    case (e,(block_ :: blocks))
      equation
        true = listMember(e, block_);
      then
        block_;
    case (e,(block_ :: blocks))
      equation
        res = getEquationBlock(e, blocks);
      then
        res;
  end matchcontinue;
end getEquationBlock;

protected function rhsConstant2 "function: rhsConstant2
  author: PA
  Helper function to rhsConstant, traverses equation list."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.DAELow inDAELow;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inEquationLst,inDAELow)
    local
      DAE.ExpType tp;
      DAE.Exp new_exp,rhs_exp,e1,e2,e;
      Boolean res;
      list<BackendDAE.Equation> rest;
      BackendDAE.DAELow dae;
      BackendDAE.Variables vars;
      BackendDAE.Value indx_1,indx;
      list<BackendDAE.Value> ds;
      list<DAE.Exp> expl;
      array<BackendDAE.MultiDimEquation> arreqn;

    case ({},_) then true;
    // check rhs for for EQUATION nodes.
    case ((BackendDAE.EQUATION(exp = e1,scalar = e2) :: rest),(dae as BackendDAE.DAELOW(orderedVars = vars)))
      equation
        tp = Exp.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        rhs_exp = getEqnsysRhsExp(new_exp, vars);
        true = Exp.isConst(rhs_exp);
        res = rhsConstant2(rest, dae);
      then
        res;
    // check rhs for for ARRAY_EQUATION nodes. check rhs for for RESIDUAL_EQUATION nodes.
    case ((BackendDAE.ARRAY_EQUATION(index = indx,crefOrDerCref = expl) :: rest),(dae as BackendDAE.DAELOW(orderedVars = vars,arrayEqs = arreqn)))
      equation
        indx_1 = indx - 1;
        BackendDAE.MULTIDIM_EQUATION(ds,e1,e2,_) = arreqn[indx + 1];
        tp = Exp.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB_ARR(tp),e2);
        rhs_exp = getEqnsysRhsExp(new_exp, vars);
        true = Exp.isConst(rhs_exp);
        res = rhsConstant2(rest, dae);
      then
        res;

    case ((BackendDAE.RESIDUAL_EQUATION(exp = e) :: rest),(dae as BackendDAE.DAELOW(orderedVars = vars))) /* check rhs for for RESIDUAL_EQUATION nodes. */
      equation
        rhs_exp = getEqnsysRhsExp(e, vars);
        true = Exp.isConst(rhs_exp);
        res = rhsConstant2(rest, dae);
      then
        res;
    case (_,_) then false;
  end matchcontinue;
end rhsConstant2;

protected function freeFromAnyVar "function: freeFromAnyVar
  author: PA
  Helper function to rhsConstant2
  returns true if expression does not contain
  anyof the variables passed as argument."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp,inVariables)
    local
      DAE.Exp e;
      list<BackendDAE.Key> crefs;
      list<Boolean> b_lst;
      Boolean res,res_1;
      BackendDAE.Variables vars;

    case (e,_)
      equation
        {} = Exp.getCrefFromExp(e) "Special case for expressions with no variables" ;
      then
        true;
    case (e,vars)
      equation
        crefs = Exp.getCrefFromExp(e);
        b_lst = Util.listMap1(crefs, existsVar, vars);
        res = Util.boolOrList(b_lst);
        res_1 = boolNot(res);
      then
        res_1;
    case (_,_) then true;
  end matchcontinue;
end freeFromAnyVar;

public function jacobianTypeStr "function: jacobianTypeStr
  author: PA
  Returns the jacobian type as a string, used for debugging."
  input BackendDAE.JacobianType inJacobianType;
  output String outString;
algorithm
  outString := matchcontinue (inJacobianType)
    case BackendDAE.JAC_CONSTANT() then "Jacobian Constant";
    case BackendDAE.JAC_TIME_VARYING() then "Jacobian Time varying";
    case BackendDAE.JAC_NONLINEAR() then "Jacobian Nonlinear";
    case BackendDAE.JAC_NO_ANALYTIC() then "No analythic jacobian";
  end matchcontinue;
end jacobianTypeStr;

protected function jacobianConstant "function: jacobianConstant
  author: PA
  Checks if jacobian is constant, i.e. all expressions in each equation are constant."
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inTplIntegerIntegerEquationLst;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inTplIntegerIntegerEquationLst)
    local
      DAE.Exp e1,e2,e;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> eqns;
    case ({}) then true;
    case (((_,_,BackendDAE.EQUATION(exp = e1,scalar = e2)) :: eqns)) /* TODO: Algorithms and ArrayEquations */
      equation
        true = Exp.isConst(e1);
        true = Exp.isConst(e2);
        true = jacobianConstant(eqns);
      then
        true;
    case (((_,_,BackendDAE.RESIDUAL_EQUATION(exp = e)) :: eqns))
      equation
        true = Exp.isConst(e);
        true = jacobianConstant(eqns);
      then
        true;
    case (((_,_,BackendDAE.SOLVED_EQUATION(exp = e)) :: eqns))
      equation
        true = Exp.isConst(e);
        true = jacobianConstant(eqns);
      then
        true;
    case (_) then false;
  end matchcontinue;
end jacobianConstant;

protected function jacobianNonlinear "function: jacobianNonlinear
  author: PA
  Check if jacobian indicates a nonlinear system.
  TODO: Algorithms and Array equations"
  input BackendDAE.DAELow inDAELow;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inTplIntegerIntegerEquationLst;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inDAELow,inTplIntegerIntegerEquationLst)
    local
      BackendDAE.DAELow daelow;
      DAE.Exp e1,e2,e;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> xs;

    case (daelow,((_,_,BackendDAE.EQUATION(exp = e1,scalar = e2)) :: xs))
      equation
        false = jacobianNonlinearExp(daelow, e1);
        false = jacobianNonlinearExp(daelow, e2);
        false = jacobianNonlinear(daelow, xs);
      then
        false;
    case (daelow,((_,_,BackendDAE.RESIDUAL_EQUATION(exp = e)) :: xs))
      equation
        false = jacobianNonlinearExp(daelow, e);
        false = jacobianNonlinear(daelow, xs);
      then
        false;
    case (_,{}) then false;
    case (_,_) then true;
  end matchcontinue;
end jacobianNonlinear;

protected function jacobianNonlinearExp "function: jacobianNonlinearExp
  author: PA
  Checks wheter the jacobian indicates a nonlinear system.
  This is true if the jacobian contains any of the variables
  that is solved for."
  input BackendDAE.DAELow inDAELow;
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inDAELow,inExp)
    local
      list<BackendDAE.Key> crefs;
      Boolean res;
      BackendDAE.Variables vars;
      DAE.Exp e;
    case (BackendDAE.DAELOW(orderedVars = vars),e)
      equation
        crefs = Exp.getCrefFromExp(e);
        res = containAnyVar(crefs, vars);
      then
        res;
  end matchcontinue;
end jacobianNonlinearExp;

protected function containAnyVar "function: containAnyVar
  author: PA
  Returns true if any of the variables given
  as ComponentRef list is among the Variables."
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input BackendDAE.Variables inVariables;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExpComponentRefLst,inVariables)
    local
      DAE.ComponentRef cr;
      list<BackendDAE.Key> crefs;
      BackendDAE.Variables vars;
      Boolean res;
    case ({},_) then false;
    case ((cr :: crefs),vars)
      equation
        (_,_) = getVar(cr, vars);
      then
        true;
    case ((_ :: crefs),vars)
      equation
        res = containAnyVar(crefs, vars);
      then
        res;
  end matchcontinue;
end containAnyVar;

public function calculateJacobian "function: calculateJacobian
  This function takes an array of equations and the variables of the equation
  and calculates the jacobian of the equations."
  input BackendDAE.Variables inVariables;
  input BackendDAE.EquationArray inEquationArray;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
algorithm
  outTplIntegerIntegerEquationLstOption:=
  matchcontinue (inVariables,inEquationArray,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT,differentiateIfExp)
    local
      list<BackendDAE.Equation> eqn_lst,eqn_lst_1;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> jac;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<list<BackendDAE.Value>> m,mt;
    case (vars,eqns,ae,m,mt,differentiateIfExp)
      equation
        eqn_lst = equationList(eqns);
        eqn_lst_1 = Util.listMap(eqn_lst, equationToResidualForm);
        SOME(jac) = calculateJacobianRows(eqn_lst_1, vars, ae, m, mt,differentiateIfExp);
      then
        SOME(jac);
    case (_,_,_,_,_,_) then NONE();  /* no analythic jacobian available */
  end matchcontinue;
end calculateJacobian;

protected function calculateJacobianRows "function: calculateJacobianRows
  author: PA
  This function takes a list of Equations and a set of variables and
  calculates the jacobian expression for each variable over each equations,
  returned in a sparse matrix representation.
  For example, the equation on index e1: 3ax+5yz+ zz  given the
  variables {x,y,z} on index x1,y1,z1 gives
  {(e1,x1,3a), (e1,y1,5z), (e1,z1,5y+2z)}"
  input list<BackendDAE.Equation> eqns;
  input BackendDAE.Variables vars;
  input array<BackendDAE.MultiDimEquation> ae;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> res;
algorithm
  (res,_) := calculateJacobianRows2(eqns, vars, ae, m, mt, 1,differentiateIfExp, {});
end calculateJacobianRows;

protected function calculateJacobianRows2 "function: calculateJacobianRows2
  author: PA
  Helper function to calculateJacobianRows"
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVariables;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input Integer inInteger;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inEntrylst;
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outEntrylst;
algorithm
  (outTplIntegerIntegerEquationLstOption,outEntrylst):=
  matchcontinue (inEquationLst,inVariables,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT,inInteger,differentiateIfExp,inEntrylst)
    local
      BackendDAE.Value eqn_indx_1,eqn_indx;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> l1,l2,res;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      BackendDAE.Variables vars;
      array<BackendDAE.MultiDimEquation> ae;
      array<list<BackendDAE.Value>> m,mt;
      list<tuple<Integer,list<list<DAE.Subscript>>>> entrylst1,entrylst2; 
    case ({},_,_,_,_,_,_,inEntrylst) then (SOME({}),inEntrylst);
    case ((eqn :: eqns),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst)
      equation
        eqn_indx_1 = eqn_indx + 1;
        (SOME(l1),entrylst1) = calculateJacobianRows2(eqns, vars, ae, m, mt, eqn_indx_1,differentiateIfExp,inEntrylst);
        (SOME(l2),entrylst2) = calculateJacobianRow(eqn, vars, ae, m, mt, eqn_indx,differentiateIfExp,entrylst1);
        res = listAppend(l1, l2);
      then
        (SOME(res),entrylst2);
  end matchcontinue;
end calculateJacobianRows2;

protected function calculateJacobianRow "function: calculateJacobianRow
  author: PA
  Calculates the jacobian for one equation. See calculateJacobianRows.
  inputs:  (Equation,
              Variables,
              BackendDAE.MultiDimEquation array,
              IncidenceMatrix,
              IncidenceMatrixT,
              int /* eqn index */)
  outputs: ((int  int  Equation) list option)"
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inVariables;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input Integer inInteger;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inEntrylst;
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outEntrylst;
algorithm
  (outTplIntegerIntegerEquationLstOption,outEntrylst):=
  matchcontinue (inEquation,inVariables,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT,inInteger,differentiateIfExp,inEntrylst)
    local
      list<BackendDAE.Value> var_indxs,var_indxs_1,ds;
      list<Option<Integer>> ad;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> eqns;
      DAE.Exp e,e1,e2,new_exp;
      BackendDAE.Variables vars;
      array<BackendDAE.MultiDimEquation> ae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value eqn_indx,indx;
      list<DAE.Exp> in_,out,expl;
      Exp.Type t;
      list<DAE.Subscript> subs;   
      list<tuple<Integer,list<list<DAE.Subscript>>>> entrylst1;   
    // residual equations
    case (BackendDAE.RESIDUAL_EQUATION(exp = e),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst)
      equation
        var_indxs = varsInEqn(m, eqn_indx);
        var_indxs_1 = Util.listUnionOnTrue(var_indxs, {}, int_eq) "Remove duplicates and get in correct order: ascending index" ;
        SOME(eqns) = calculateJacobianRow2(e, vars, eqn_indx, var_indxs_1,differentiateIfExp);
      then
        (SOME(eqns),inEntrylst);
    // algorithms give no jacobian
    case (BackendDAE.ALGORITHM(index = indx,in_ = in_,out = out),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst) then (NONE(),inEntrylst);
    // array equations
    case (BackendDAE.ARRAY_EQUATION(index = indx,crefOrDerCref = expl),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst)
      equation
        BackendDAE.MULTIDIM_EQUATION(ds,e1,e2,_) = ae[indx + 1];
        t = Exp.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB_ARR(t),e2);
        ad = Util.listMap(ds,Util.makeOption);
        (subs,entrylst1) = getArrayEquationSub(indx,ad,inEntrylst);
        new_exp = Exp.applyExpSubscripts(new_exp,subs); 
        var_indxs = varsInEqn(m, eqn_indx);
        var_indxs_1 = Util.listUnionOnTrue(var_indxs, {}, int_eq) "Remove duplicates and get in correct order: acsending index";
        SOME(eqns) = calculateJacobianRow2(new_exp, vars, eqn_indx, var_indxs_1,differentiateIfExp);
      then
        (SOME(eqns),entrylst1);
  end matchcontinue;
end calculateJacobianRow;

public function getArrayEquationSub"function: getArrayEquationSub
  author: Frenkel TUD
  helper for calculateJacobianRow and SimCode.dlowEqToExp"
  input Integer Index;
  input list<Option<Integer>> inAD;
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inList;
  output list<DAE.Subscript> outSubs;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outList;
algorithm
  (outSubs,outList) := 
  matchcontinue (Index,inAD,inList)
    local
      Integer i,ie;
      list<Option<Integer>> ad;
      list<DAE.Subscript> subs,subs1;
      list<list<DAE.Subscript>> subslst,subslst1;
      list<tuple<Integer,list<list<DAE.Subscript>>>> rest,entrylst;
      tuple<Integer,list<list<DAE.Subscript>>> entry;
    // new entry  
    case (i,ad,{})
      equation
        subslst = arrayDimensionsToRange(ad);
        (subs::subslst1) = rangesToSubscripts(subslst);
      then
        (subs,{(i,subslst1)});
    // found last entry
    case (i,ad,(entry as (ie,{subs}))::rest)
      equation
        true = intEq(i,ie);
      then   
        (subs,rest);         
    // found entry
    case (i,ad,(entry as (ie,subs::subslst))::rest)
      equation
        true = intEq(i,ie);
      then   
        (subs,(ie,subslst)::rest); 
    // next entry  
    case (i,ad,(entry as (ie,subslst))::rest)
      equation
        false = intEq(i,ie);
        (subs1,entrylst) = getArrayEquationSub(i,ad,rest);
      then   
        (subs1,entry::entrylst); 
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- DAELow.getArrayEquationSub failed");
      then
        fail();          
  end matchcontinue;      
end getArrayEquationSub;

protected function makeResidualEqn "function: makeResidualEqn
  author: PA
  Transforms an expression into a residual equation"
  input DAE.Exp inExp;
  output BackendDAE.Equation outEquation;
algorithm
  outEquation := matchcontinue (inExp)
    local DAE.Exp e;
    case (e) then BackendDAE.RESIDUAL_EQUATION(e,DAE.emptyElementSource);
  end matchcontinue;
end makeResidualEqn;

protected function calculateJacobianRow2 "function: calculateJacobianRow2
  author: PA
  Helper function to calculateJacobianRow
  Differentiates expression for each variable cref.
  inputs: (DAE.Exp,
             Variables,
             int, /* equation index */
             int list) /* var indexes */
  outputs: ((int int Equation) list option)"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  input Integer inInteger;
  input list<Integer> inIntegerLst;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
algorithm
  outTplIntegerIntegerEquationLstOption := matchcontinue (inExp,inVariables,inInteger,inIntegerLst,differentiateIfExp)
    local
      DAE.Exp e,e_1,e_2;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> es;
      BackendDAE.Variables vars;
      BackendDAE.Value eqn_indx,vindx;
      list<BackendDAE.Value> vindxs;

    case (e,_,_,{},_) then SOME({});
    case (e,vars,eqn_indx,(vindx :: vindxs),differentiateIfExp)
      equation
        v = getVarAt(vars, vindx);
        cr = varCref(v);
        e_1 = Derive.differentiateExp(e, cr, differentiateIfExp);
        e_2 = Exp.simplify(e_1);
        SOME(es) = calculateJacobianRow2(e, vars, eqn_indx, vindxs, differentiateIfExp);
      then
        SOME(((eqn_indx,vindx,BackendDAE.RESIDUAL_EQUATION(e_2,DAE.emptyElementSource)) :: es));
  end matchcontinue;
end calculateJacobianRow2;

public function residualExp "function: residualExp
  author: PA
  This function extracts the residual expression from a residual equation"
  input BackendDAE.Equation inEquation;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inEquation)
    local DAE.Exp e;
    case (BackendDAE.RESIDUAL_EQUATION(exp = e)) then e;
  end matchcontinue;
end residualExp;

public function toResidualForm "function: toResidualForm
  author: PA
  This function transforms a daelow to residualform on the equations."
  input BackendDAE.DAELow inDAELow;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow := matchcontinue (inDAELow)
    local
      list<BackendDAE.Equation> eqn_lst,eqn_lst2;
      BackendDAE.EquationArray eqns2,eqns,seqns,ieqns;
      BackendDAE.Variables vars,knvars,extVars;
      BackendDAE.AliasVariables av;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> ialg;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses extobjcls;

    case (BackendDAE.DAELOW(vars,knvars,extVars,av,eqns,seqns,ieqns,ae,ialg,wc,extobjcls))
      equation
        eqn_lst = equationList(eqns);
        eqn_lst2 = Util.listMap(eqn_lst, equationToResidualForm);
        eqns2 = listEquation(eqn_lst2);
      then
        BackendDAE.DAELOW(vars,knvars,extVars,av,eqns2,seqns,ieqns,ae,ialg,wc,extobjcls);
  end matchcontinue;
end toResidualForm;

public function equationToResidualForm "function: equationToResidualForm
  author: PA
  This function transforms an equation to its residual form.
  For instance, a=b is transformed to a-b=0"
  input BackendDAE.Equation inEquation;
  output BackendDAE.Equation outEquation;
algorithm
  outEquation := matchcontinue (inEquation)
    local
      DAE.Exp e,e1,e2,exp;
      DAE.ComponentRef cr;
      DAE.ExpType tp;
      DAE.ElementSource source "origin of the element";
      DAE.Operator op;
      Boolean b;

    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source = source))
      equation
         //Exp.dumpExpWithTitle("equationToResidualForm 1\n",e2);
        tp = Exp.typeof(e2);
        b = DAEUtil.expTypeArray(tp);
        op = Util.if_(b,DAE.SUB_ARR(tp),DAE.SUB(tp));
        e = Exp.simplify(DAE.BINARY(e1,op,e2));
      then
        BackendDAE.RESIDUAL_EQUATION(e,source);
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = exp,source = source))
      equation
         //Exp.dumpExpWithTitle("equationToResidualForm 2\n",exp);
        tp = Exp.typeof(exp);
        b = DAEUtil.expTypeArray(tp);
        op = Util.if_(b,DAE.SUB_ARR(tp),DAE.SUB(tp));        
        e = Exp.simplify(DAE.BINARY(DAE.CREF(cr,tp),op,exp));
      then
        BackendDAE.RESIDUAL_EQUATION(e,source);
    case ((e as BackendDAE.RESIDUAL_EQUATION(exp = _,source = source)))
      local BackendDAE.Equation e;
      then
        e;
    case ((e as BackendDAE.ALGORITHM(index = _)))
      local BackendDAE.Equation e;
      then
        e;
    case ((e as BackendDAE.ARRAY_EQUATION(index = _)))
      local BackendDAE.Equation e;
      then
        e;
    case ((e as BackendDAE.WHEN_EQUATION(whenEquation = _)))
      local BackendDAE.Equation e;
      then
        e;
    case (e)
      local BackendDAE.Equation e;
      equation
        Debug.fprintln("failtrace", "- DAELow.equationToResidualForm failed");
      then
        fail();
  end matchcontinue;
end equationToResidualForm;

public function calculateSizes "function: calculateSizes
  author: PA
  Calculates the number of state variables, nx,
  the number of algebraic variables, ny
  and the number of parameters/constants, np.
  inputs:  DAELow
  outputs: (int, /* nx */
            int, /* ny */
            int, /* np */
            int  /* ng */
            int) next"
  input BackendDAE.DAELow inDAELow;
  output Integer outnx        "number of states";
  output Integer outny        "number of alg. vars";
  output Integer outnp        "number of parameters";
  output Integer outng        "number of zerocrossings";
  output Integer outng_sample "number of zerocrossings that are samples";
  output Integer outnext      "number of external objects";
  // nx cannot be strings
  output Integer outny_string "number of alg.vars which are strings";
  output Integer outnp_string "number of parameters which are strings";
  // nx cannot be int
  output Integer outny_int    "number of alg.vars which are ints";
  output Integer outnp_int    "number of parameters which are ints";
  // nx cannot be int
  output Integer outny_bool   "number of alg.vars which are bools";
  output Integer outnp_bool   "number of parameters which are bools";    
algorithm
  (outnx,outny,outnp,outng,outng_sample,outnext, outny_string, outnp_string, outny_int, outnp_int, outny_bool, outnp_bool):=
  matchcontinue (inDAELow)
    local
      list<BackendDAE.Var> varlst,knvarlst,extvarlst;
      BackendDAE.Value np,ng,nsam,nx,ny,nx_1,ny_1,next,ny_string,np_string,ny_1_string,np_int,np_bool,ny_int,ny_1_int,ny_bool,ny_1_bool;
      String np_str;
      BackendDAE.Variables vars,knvars,extvars;
      list<BackendDAE.WhenClause> wc;
      list<BackendDAE.ZeroCrossing> zc;
    
    case (BackendDAE.DAELOW(orderedVars = vars,knownVars = knvars, externalObjects = extvars,
                 eventInfo = BackendDAE.EVENT_INFO(whenClauseLst = wc,
                                        zeroCrossingLst = zc)))
      equation
        varlst = varList(vars) "input variables are put in the known var list, but they should be counted by the ny counter.";
        extvarlst = varList(extvars);
        next = listLength(extvarlst);
        knvarlst = varList(knvars);
        (np,np_string,np_int, np_bool) = calculateParamSizes(knvarlst);
        np_str = intString(np);
        (ng,nsam) = calculateNumberZeroCrossings(zc, 0, 0);
        (nx,ny,ny_string,ny_int, ny_bool) = calculateVarSizes(varlst, 0, 0, 0, 0, 0);
        (nx_1,ny_1,ny_1_string,ny_1_int, ny_1_bool) = calculateVarSizes(knvarlst, nx, ny, ny_string, ny_int, ny_bool);
      then
        (nx_1,ny_1,np,ng,nsam,next,ny_1_string, np_string, ny_1_int, np_int, ny_1_bool, np_bool);
  end matchcontinue;
end calculateSizes;

protected function calculateNumberZeroCrossings
  input list<BackendDAE.ZeroCrossing> zcLst;
  input Integer zc_index;
  input Integer sample_index;
  output Integer zc;
  output Integer sample;
algorithm
  (zc,sample) := matchcontinue (zcLst,zc_index,sample_index)
    local
      list<BackendDAE.ZeroCrossing> xs;
    
    case ({},zc_index,sample_index) then (zc_index,sample_index);

    case (BackendDAE.ZERO_CROSSING(relation_ = DAE.CALL(path = Absyn.IDENT(name = "sample"))) :: xs,zc_index,sample_index)
      equation
        sample_index = sample_index + 1;
        zc_index = zc_index + 1;
        (zc,sample) = calculateNumberZeroCrossings(xs,zc_index,sample_index);
      then (zc,sample);

    case (BackendDAE.ZERO_CROSSING(relation_ = DAE.RELATION(operator = _), occurEquLst = _) :: xs,zc_index,sample_index)
      equation
        zc_index = zc_index + 1;
        (zc,sample) = calculateNumberZeroCrossings(xs,zc_index,sample_index);
      then (zc,sample);

    case (_,_,_)
      equation
        print("- DAELow.calculateNumberZeroCrossings failed\n");
      then
        fail();

  end matchcontinue;
end calculateNumberZeroCrossings;

protected function calculateParamSizes "function: calculateParamSizes
  author: PA
  Helper function to calculateSizes"
  input list<BackendDAE.Var> inVarLst;
  output Integer outInteger;
  output Integer outInteger2;
  output Integer outInteger3;
  output Integer outInteger4;
algorithm
  (outInteger,outInteger2,outInteger3, outInteger4):=
  matchcontinue (inVarLst)
    local
      BackendDAE.Value s1,s2,s3, s4;
      BackendDAE.Var var;
      list<BackendDAE.Var> vs;
    case ({}) then (0,0,0,0);
    case ((var :: vs))
      equation
        (s1,s2,s3,s4) = calculateParamSizes(vs);
        true = isBoolParam(var);
      then
        (s1,s2,s3,s4 + 1);  
    case ((var :: vs))
      equation
        (s1,s2,s3,s4) = calculateParamSizes(vs);
        true = isIntParam(var);
      then
        (s1,s2,s3 + 1,s4);
    case ((var :: vs))
      equation
        (s1,s2,s3,s4) = calculateParamSizes(vs);
        true = isStringParam(var);
      then
        (s1,s2 + 1,s3,s4);
    case ((var :: vs))
      equation
        (s1,s2,s3,s4) = calculateParamSizes(vs);
        true = isParam(var);
      then
        (s1 + 1,s2,s3,s4);
    case ((_ :: vs))
      equation
        (s1,s2,s3,s4) = calculateParamSizes(vs);
      then
        (s1,s2,s3,s4);
    case (_)
      equation
        print("- DAELow.calculateParamSizes failed\n");
      then
        fail();        
  end matchcontinue;
end calculateParamSizes;

protected function calculateVarSizes "function: calculateVarSizes
  author: PA
  Helper function to calculateSizes"
  input list<BackendDAE.Var> inVarLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;

  output Integer outInteger1;
  output Integer outInteger2;
  output Integer outInteger3;
  output Integer outInteger4;
  output Integer outInteger5;

algorithm
  (outInteger1,outInteger2,outInteger3, outInteger4,outInteger5):=
  matchcontinue (inVarLst1,inInteger2,inInteger3,inInteger4,inInteger5,inInteger6)
    local
      BackendDAE.Value nx,ny,ny_1,nx_2,ny_2,nx_1,nx_string,ny_string,ny_1_string,ny_2_string;
      BackendDAE.Value ny_int, ny_1_int, ny_2_int, ny_bool, ny_1_bool, ny_2_bool;
      DAE.Flow flowPrefix;
      list<BackendDAE.Var> vs;
    
    case ({},nx,ny,ny_string, ny_int, ny_bool) then (nx,ny,ny_string,ny_int, ny_bool);

    case ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),varType=BackendDAE.STRING(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_1_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);

    case ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),varType=BackendDAE.INT(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int,ny_bool)
      equation
        ny_1_int = ny_int + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_1_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);    

    case ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),varType=BackendDAE.BOOL(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int,ny_bool)
      equation
        ny_1_bool = ny_bool + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_int, ny_1_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);    

    case ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int,ny_bool)
      equation
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny_1, ny_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool); 
    
     case ((BackendDAE.VAR(varKind = BackendDAE.DISCRETE(),varType=BackendDAE.STRING(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_1_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);
        
     case ((BackendDAE.VAR(varKind = BackendDAE.DISCRETE(),varType=BackendDAE.INT(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        ny_1_int = ny_int + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_1_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);
     
     case ((BackendDAE.VAR(varKind = BackendDAE.DISCRETE(),varType=BackendDAE.BOOL(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int,ny_bool)
      equation
        ny_1_bool = ny_bool + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_int, ny_1_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);     
                 
     case ((BackendDAE.VAR(varKind = BackendDAE.DISCRETE(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny_1, ny_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);

    case ((BackendDAE.VAR(varKind = BackendDAE.STATE(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        nx_1 = nx + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx_1, ny, ny_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);

    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),varType=BackendDAE.STRING(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool) /* A dummy state is an algebraic variable */
      equation
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_1_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);
        
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),varType=BackendDAE.INT(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool) /* A dummy state is an algebraic variable */
      equation
        ny_1_int = ny_int + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_1_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);
    
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),varType=BackendDAE.BOOL(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int,ny_bool)
      equation
        ny_1_bool = ny_bool + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_int, ny_1_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);   
        
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool) /* A dummy state is an algebraic variable */
      equation
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny_1,ny_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);

    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),varType=BackendDAE.STRING(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny,ny_1_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);
        
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),varType=BackendDAE.INT(),flowPrefix = flowPrefix) :: vs),nx, ny, ny_string, ny_int, ny_bool)
      equation
         ny_1_int = ny_int + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_1_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);
    
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),varType=BackendDAE.BOOL(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int,ny_bool)
      equation
        ny_1_bool = ny_bool + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_int, ny_1_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);  
        
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny_1,ny_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool); 

    case ((_ :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        (nx_1,ny_1,ny_1_string, ny_1_int, ny_1_bool) = calculateVarSizes(vs, nx, ny,ny_string,ny_int, ny_bool);
      then
        (nx_1,ny_1,ny_1_string, ny_1_int, ny_1_bool);
        
    case (_,_,_,_,_,_)
      equation
        print("- DAELow.calculateVarSizes failed\n");
      then
        fail();
  end matchcontinue;
end calculateVarSizes;

public function calculateValues "function: calculateValues
  author: PA
  This function calculates the values from the parameter binding expressions."
  input BackendDAE.DAELow inDAELow;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow := matchcontinue (inDAELow)
    local
      list<BackendDAE.Var> knvarlst;
      BackendDAE.Variables knvars,vars,extVars;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,seqns,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses extObjCls;
    case (BackendDAE.DAELOW(orderedVars = vars,knownVars = knvars,externalObjects=extVars,aliasVars = av,orderedEqs = eqns,
                 removedEqs = seqns,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = wc,extObjClasses=extObjCls))
      equation
        knvarlst = varList(knvars);
        knvarlst = Util.listMap1(knvarlst, calculateValue, knvars);
        knvars = listVar(knvarlst);
      then
        BackendDAE.DAELOW(vars,knvars,extVars,av,eqns,seqns,ie,ae,al,wc,extObjCls);
  end matchcontinue;
end calculateValues;

protected function calculateValue
  input BackendDAE.Var inVar;
  input BackendDAE.Variables vars;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue(inVar, vars)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind vk;
      DAE.VarDirection vd;
      BackendDAE.Type ty;
      DAE.Exp e, e2;
      DAE.InstDims dims;
      Integer idx;
      DAE.ElementSource src;
      Option<DAE.VariableAttributes> va;
      Option<SCode.Comment> c;
      DAE.Flow fp;
      DAE.Stream sp;
      Values.Value v;
    case (BackendDAE.VAR(varName = cr, varKind = vk, varDirection = vd, varType = ty,
          bindExp = SOME(e), arryDim = dims, index = idx, source = src, 
          values = va, comment = c, flowPrefix = fp, streamPrefix = sp), _)
      equation
        ((e2, _)) = Exp.traverseExp(e, replaceCrefsWithValues, vars);
        (_, v, _) = Ceval.ceval(Env.emptyCache(), Env.emptyEnv, e2, false,NONE(), NONE(), Ceval.MSG());
      then
        BackendDAE.VAR(cr, vk, vd, ty, SOME(e), SOME(v), dims, idx, src, va, c, fp, sp);
    case (_, _) then inVar;
  end matchcontinue;
end calculateValue;

protected function replaceCrefsWithValues
  input tuple<DAE.Exp, BackendDAE.Variables> inTuple;
  output tuple<DAE.Exp, BackendDAE.Variables> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
    case ((DAE.CREF(cr, _), vars))
      equation
         ({BackendDAE.VAR(bindExp = SOME(e))}, _) = getVar(cr, vars);
         ((e, _)) = Exp.traverseExp(e, replaceCrefsWithValues, vars);
      then
        ((e, vars));
    case (_) then inTuple;
  end matchcontinue;
end replaceCrefsWithValues;
  
protected function statesEqns "function: statesEqns
  author: PA
  Takes a list of equations and an (empty) BackendDAE.BinTree and
  fills the tree with the state variables present in the 
  equations"
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inEquationLst,inBinTree)
    local
      BackendDAE.BinTree bt;
      DAE.Exp e1,e2;
      list<BackendDAE.Equation> es;
      BackendDAE.Value ds,indx;
      list<DAE.Exp> expl,expl1,expl2;
    case ({},bt) then bt;
    case ((BackendDAE.EQUATION(exp = e1,scalar = e2) :: es),bt)
      equation
        bt = statesEqns(es, bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case ((BackendDAE.ARRAY_EQUATION(index = ds,crefOrDerCref = expl) :: es),bt)
      equation
        bt = statesEqns(es, bt);
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case ((BackendDAE.ALGORITHM(index = indx,in_ = expl1,out = expl2) :: es),bt)
      equation
        bt = Util.listFold(expl1, statesExp, bt);
        bt = Util.listFold(expl2, statesExp, bt);
        bt = statesEqns(es, bt);
      then
        bt;
    case ((BackendDAE.WHEN_EQUATION(whenEquation = _) :: es),bt)
      equation
        bt = statesEqns(es, bt);
      then
        bt;
    case (_,_)
      equation
        print("-states_eqns failed\n");
      then
        fail();
  end matchcontinue;
end statesEqns;

protected function getIndex "function: getIndex
  author: PA
  Helper function to derivativeReplacements"
  input DAE.ComponentRef inComponentRef;
  input list<BackendDAE.Var> inVarLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inComponentRef,inVarLst)
    local
      DAE.ComponentRef cr1,cr2;
      BackendDAE.Value indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      list<BackendDAE.Var> vs;
    case (cr1,(BackendDAE.VAR(varName = cr2,index = indx,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: _))
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr1, cr2);
      then
        indx;
    case (cr1,(_ :: vs))
      equation
        indx = getIndex(cr1, vs);
      then
        indx;
  end matchcontinue;
end getIndex;

protected function calculateIndexes "function: calculateIndexes
  author: PA modified by Frenkel TUD

  Helper function to translate_dae. Calculates the indexes for each variable
  in one of the arrays. x, xd, y and extobjs.
  To ensure that arrays(matrix,vector) are in a continuous memory block
  the indexes from vars, knvars and extvars has to be calculate at the same time.
  To seperate them after that they are stored in a list with
  the information about the type(vars=0,knvars=1,extvars=2) and the place at the
  original list."
  input list<BackendDAE.Var> inVarLst1;
  input list<BackendDAE.Var> inVarLst2;
  input list<BackendDAE.Var> inVarLst3;

  output list<BackendDAE.Var> outVarLst1;
  output list<BackendDAE.Var> outVarLst2;
  output list<BackendDAE.Var> outVarLst3;
algorithm
  (outVarLst1,outVarLst2,outVarLst3) := matchcontinue (inVarLst1,inVarLst2,inVarLst3)
    local
      list<BackendDAE.Var> vars_2,knvars_2,extvars_2,extvars,vars,knvars;
      list< tuple<BackendDAE.Var,Integer> > vars_1,knvars_1,extvars_1;
      list< tuple<BackendDAE.Var,Integer,Integer> > vars_map,knvars_map,extvars_map,all_map,all_map1,noScalar_map,noScalar_map1,scalar_map,all_map2,mergedvar_map,sort_map,sort_map1;
      BackendDAE.Value x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType;
    case (vars,knvars,extvars)
      equation
        // store vars,knvars,extvars in the list
        vars_map = fillListConst(vars,0,0);
        knvars_map = fillListConst(knvars,1,0);
        extvars_map = fillListConst(extvars,2,0);
        // connect the lists
        all_map = listAppend(vars_map,knvars_map);
        all_map1 = listAppend(all_map,extvars_map);
        // seperate scalars and non scalars
        (noScalar_map,scalar_map) = getNoScalarVars(all_map1);

        noScalar_map1 = getAllElements(noScalar_map);
        sort_map = sortNoScalarList(noScalar_map1);
        //print("\nsort_map:\n");
        //dumpSortMap(sort_map);
        // connect scalars and sortet non scalars
        mergedvar_map = listAppend(scalar_map,sort_map);
        // calculate indexes
        (all_map2,x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType) = calculateIndexes2(mergedvar_map, 0, 0, 0, 0, 0,0,0,0,0,0,0);
        // seperate vars,knvars,extvas
        vars_1 = getListConst(all_map2,0);
        knvars_1 = getListConst(all_map2,1);
        extvars_1 =  getListConst(all_map2,2);
        // arrange lists in original order
        vars_2 = sortList(vars_1,0);
        knvars_2 = sortList(knvars_1,0);
        extvars_2 =  sortList(extvars_1,0);
      then
        (vars_2,knvars_2,extvars_2);
    case (_,_,_)
      equation
        print("-calculate_indexes failed\n");
      then
        fail();
  end matchcontinue;
end calculateIndexes;

protected function fillListConst
"function: fillListConst
author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a list, a type value an a start place and store all elements
  of the list in a list of tuples (element,type,place)"
  input list<Type_a> inTypeALst;
  input Integer inType;
  input Integer inPlace;
  output list< tuple<Type_a,Integer,Integer> > outlist;
  replaceable type Type_a subtypeof Any;
algorithm
  outlist := matchcontinue (inTypeALst,inType,inPlace)
    local
      list<Type_a> rest;
      Type_a item;
      Integer value,place;
      list< tuple<Type_a,Integer,Integer> > out_lst,val_lst;
    case ({},value,place) then {};
    case (item::rest,value,place)
      equation
        /* recursive */
        val_lst = fillListConst(rest,value,place+1);
        /* fill  */
        out_lst = listAppend({(item,value,place)},val_lst);
      then
        out_lst;
  end matchcontinue;
end fillListConst;

protected function getListConst
"function: getListConst
  author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a list of tuples (element,type,place) and a type value
  and pitch on all elements with the same type value.
  The output is a list of tuples (element,place)."
  input list< tuple<Type_a,Integer,Integer> > inTypeALst;
  input Integer inValue;
  output list<tuple<Type_a,Integer>> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst :=
  matchcontinue (inTypeALst,inValue)
    local
      list<tuple<Type_a,Integer,Integer>> rest;
      Type_a item;
      Integer value, itemvalue,place;
      list<tuple<Type_a,Integer>> out_lst,val_lst,val_lst1;
    case ({},value) then {};
    case ((item,itemvalue,place)::rest,value)
      equation
        /* recursive */
        val_lst = getListConst(rest,value);
        /* fill  */
        val_lst1 = Util.if_(itemvalue == value,{(item,place)},{});
        out_lst = listAppend(val_lst1,val_lst);
      then
        out_lst;
  end matchcontinue;
end getListConst;

protected function sortList
"function: sortList
  author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a list of tuples (element,place)and generate a
  list of elements with the order given by the place value."
  input list< tuple<Type_a,Integer> > inTypeALst;
  input Integer inPlace;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst := matchcontinue (inTypeALst,inPlace)
    local
      list<tuple<Type_a,Integer>> itemlst,rest;
      Type_a item,outitem;
      Integer place,itemplace;
      list<Type_a> out_lst,val_lst;
    case ({},place) then {};
    case (itemlst,place)
      equation
        /* get item */
        (outitem,rest) = sortList1(itemlst,place);
        /* recursive */
        val_lst = sortList(rest,place+1);
        /* append  */
        out_lst = listAppend({outitem},val_lst);
      then
        out_lst;
  end matchcontinue;
end sortList;

protected function sortList1
"function: sortList1
  author: Frenkel TUD
  Helper function for sortList"
  input list< tuple<Type_a,Integer> > inTypeALst;
  input Integer inPlace;
  output Type_a outType;
  output list< tuple<Type_a,Integer> > outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  (outType,outTypeALst) :=
  matchcontinue (inTypeALst,inPlace)
    local
      list<tuple<Type_a,Integer>> rest,out_itemlst;
      Type_a item;
      Integer place,itemplace;
      Type_a out_item;
    case ({},_)
      equation
        print("-sortList1 failed\n");
      then
        fail();
    case ((item,itemplace)::rest,place)
      equation
        /* compare */
        (place == itemplace) = true;
        /* ok */
        then
          (item,rest);
    case ((item,itemplace)::rest,place)
      equation
        /* recursive */
        (out_item,out_itemlst) = sortList1(rest,place);
      then
        (out_item,(item,itemplace)::out_itemlst);
  end matchcontinue;
end sortList1;

protected function getNoScalarVars
"function: getNoScalarVars
  author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a List of variables and seperate them
  in two lists. One for scalars and one for non scalars"
  input list< tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outnoScalarlist;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outScalarlist;
algorithm
  (outnoScalarlist,outScalarlist) := matchcontinue (inlist)
    local
      list< tuple<BackendDAE.Var,Integer,Integer> > noScalarlst,scalarlst,rest,noScalarlst1,scalarlst1,noScalarlst2,scalarlst2;
      BackendDAE.Var var,var1;
      Integer typ,place;
    case {} then ({},{});
    case ((var,typ,place) :: rest)
      equation
        /* recursive */
        (noScalarlst,scalarlst) = getNoScalarVars(rest);
        /* check  */
        (noScalarlst1,scalarlst1) = checkVarisNoScalar(var,typ,place);
        noScalarlst2 = listAppend(noScalarlst1,noScalarlst);
        scalarlst2 = listAppend(scalarlst1,scalarlst);
      then
        (noScalarlst2,scalarlst2);
    case (_)
      equation
        print("getNoScalarVars fails\n");
      then
        fail();
  end matchcontinue;
end getNoScalarVars;

protected function checkVarisNoScalar
"function: checkVarisNoScalar
  author: Frenkel TUD
  Helper function for getNoScalarVars.
  Take a variable and push them in a list
  for scalars ore non scalars"
  input BackendDAE.Var invar;
  input Integer inTyp;
  input Integer inPlace;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outlist;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outlist1;
algorithm
  (outlist,outlist1) :=
  matchcontinue (invar,inTyp,inPlace)
    local
      DAE.InstDims dimlist;
      BackendDAE.Var var;
      Integer typ,place;
    case (var as (BackendDAE.VAR(arryDim = {})),typ,place) then ({},{(var,typ,place)});
    case (var as (BackendDAE.VAR(arryDim = dimlist)),typ,place) then ({(var,typ,place)},{});
  end matchcontinue;
end checkVarisNoScalar;

protected function getAllElements
"function: getAllElements
  author: Frenkel TUD
  Takes a list of unsortet noScalarVars
  and returns a sorted list"
  input list<tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist;
algorithm
  outlist:=
  matchcontinue (inlist)
    local
      list<tuple<BackendDAE.Var,Integer,Integer>> rest,var_lst,var_lst1,var_lst2,out_lst;
      BackendDAE.Var var,var1;
      Boolean ins;
      Integer typ,place;
    case {} then {};
    case ((var,typ,place) :: rest)
      equation
        (var_lst,var_lst1) = getAllElements1((var,typ,place),rest);
        var_lst2 = getAllElements(var_lst1);
        out_lst = listAppend(var_lst,var_lst2);
      then
        out_lst;
  end matchcontinue;
end getAllElements;

protected function getAllElements1
"function: getAllElements1
  author: Frenkel TUD
  Helper function for getAllElements."
  input tuple<BackendDAE.Var,Integer,Integer>  inVar;
  input list<tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist1;
algorithm
  (outlist,outlist1) := matchcontinue (inVar,inlist)
    local
      list<tuple<BackendDAE.Var,Integer,Integer>> rest,var_lst,var_lst1,var_lst2,var_lst3,out_lst;
      DAE.ComponentRef varName1, varName2,c2,c1;
      BackendDAE.Var var1,var2;
      Boolean ins;
      Integer typ1,typ2,place1,place2;
    case ((var1,typ1,place1),{}) then ({(var1,typ1,place1)},{});
    case ((var1 as BackendDAE.VAR(varName = varName1), typ1, place1), (var2 as BackendDAE.VAR(varName = varName2), typ2, place2) :: rest)
      equation
        (var_lst, var_lst1) = getAllElements1((var1, typ1, place1), rest);
        c1 = ComponentReference.crefStripLastSubs(varName1);
        c2 = ComponentReference.crefStripLastSubs(varName2);        
        ins = ComponentReference.crefEqualNoStringCompare(c1, c2); 
        var_lst2 = listAppendTyp(ins, (var2, typ2, place2), var_lst);
        var_lst3 = listAppendTyp(boolNot(ins), (var2, typ2, place2), var_lst1);
      then
        (var_lst2, var_lst3);
  end matchcontinue;
end getAllElements1;

protected function sortNoScalarList
"function: sortNoScalarList
  author: Frenkel TUD
  Takes a list of unsortet noScalarVars
  and returns a sorted list"
  input list<tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist;
algorithm
  outlist:=
  matchcontinue (inlist)
    local
      list<tuple<BackendDAE.Var,Integer,Integer>> rest,var_lst,var_lst1,out_lst;
      BackendDAE.Var var,var1;
      Boolean ins;
      Integer typ,place;
    case {} then {};
    case ((var,typ,place) :: rest)
      equation
        var_lst = sortNoScalarList(rest);
        (var_lst1,ins) = sortNoScalarList1((var,typ,place),var_lst);
        out_lst = listAppendTyp(boolNot(ins),(var,typ,place),var_lst1);
      then
        out_lst;
  end matchcontinue;
end sortNoScalarList;

protected function listAppendTyp
"function: listAppendTyp
  author: Frenkel TUD
  Takes a list of unsortet noScalarVars
  and returns a sorted list"
  input Boolean append;
  input Type_a  invar;
  input list<Type_a > inlist;
  output list<Type_a > outlist;
  replaceable type Type_a subtypeof Any;
algorithm
  (outlist):=
  matchcontinue (append,invar,inlist)
    local
      list<Type_a > var_lst;
      Type_a var;
    case (false,_,var_lst) then var_lst;
    case (true,var,var_lst)
      local
       list<Type_a > out_lst;
      equation
        out_lst = var::var_lst;
      then
        out_lst;
  end matchcontinue;
end listAppendTyp;

protected function sortNoScalarList1
"function: sortNoScalarList1
  author: Frenkel TUD
  Helper function for sortNoScalarList"
  input tuple<BackendDAE.Var,Integer,Integer>  invar;
  input list<tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist;
  output Boolean insert;
algorithm
  (outlist,insert):=
  matchcontinue (invar,inlist)
    local
      list<tuple<BackendDAE.Var,Integer,Integer>> rest,var_lst,var_lst1,var_lst2;
      BackendDAE.Var var,var1;
      Boolean ins,ins1,ins2;
      Integer typ,typ1,place,place1;
    case (_,{}) then ({},false);
    case ((var,typ,place),(var1,typ1,place1)::rest)
      equation
        (var_lst,ins) = sortNoScalarList1((var,typ,place),rest);
        (var_lst1,ins1) = sortNoScalarList2(ins,(var,typ,place),(var1,typ1,place1),var_lst);
      then
        (var_lst1,ins1);
  end matchcontinue;
end sortNoScalarList1;

protected function sortNoScalarList2
"function: sortNoScalarList2
  author: Frenkel TUD
  Helper function for sortNoScalarList
  Takes a list of unsortet noScalarVars
  and returns a sorte list"
  input Boolean ininsert;
  input tuple<BackendDAE.Var,Integer,Integer>  invar;
  input tuple<BackendDAE.Var,Integer,Integer>  invar1;
  input list< tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outlist;
  output Boolean outinsert;
algorithm
  (outlist,outinsert):=
  matchcontinue (ininsert,invar,invar1,inlist)
    local
      list< tuple<BackendDAE.Var,Integer,Integer> > var_lst,var_lst1,var_lst2,out_lst;
      BackendDAE.Var var,var1;
      Integer typ,typ1,place,place1;
      Boolean ins;
    case (false,(var,typ,place),(var1,typ1,place1),var_lst)
      equation
        ins = comparingNonScalars(var,var1);
        var_lst1 = Util.if_(ins,{(var1,typ1,place1),(var,typ,place)},{(var1,typ1,place1)});
        var_lst2 = listAppend(var_lst1,var_lst);
      then
        (var_lst2,ins);
    case (true,(var,typ,place),(var1,typ1,place1),var_lst)
      equation
        var_lst1 = listAppend({(var1,typ1,place1)},var_lst);
      then
        (var_lst1,true);
  end matchcontinue;
end sortNoScalarList2;

protected function comparingNonScalars
"function: comparingNonScalars
  author: Frenkel TUD
  Helper function for sortNoScalarList2
  Takes two NonScalars an returns
  it in right order
  Example1:  A[2,2],A[1,1] -> {A[1,1],A[2,2]}
  Example2:  A[2,2],B[1,1] -> {A[2,2],B[1,1]}"
  input BackendDAE.Var invar1;
  input BackendDAE.Var invar2;
  output Boolean outval;
algorithm
  outval:=
  matchcontinue (invar1,invar2)
    local
      DAE.Ident origName1,origName2;
      DAE.ComponentRef varName1, varName2,c1,c2;
      list<DAE.Subscript> arryDim, arryDim1;
      list<DAE.Subscript> subscriptLst, subscriptLst1;
      Boolean out_val;
    case (BackendDAE.VAR(varName = varName1,arryDim = arryDim),BackendDAE.VAR(varName = varName2,arryDim = arryDim1))
      equation
        c1 = ComponentReference.crefStripLastSubs(varName1);
        c2 = ComponentReference.crefStripLastSubs(varName2);
        true = ComponentReference.crefEqualNoStringCompare(c1, c2); 
        subscriptLst = ComponentReference.crefLastSubs(varName1);
        subscriptLst1 = ComponentReference.crefLastSubs(varName2);
        out_val = comparingNonScalars1(subscriptLst,subscriptLst1,arryDim,arryDim1);
      then
        out_val;        
    case (_,_) then false;
  end matchcontinue;
end comparingNonScalars;

protected function comparingNonScalars1
"function: comparingNonScalars1
  author: Frenkel TUD
  Helper function for comparingNonScalars.
  Check if a element of a non scalar has his place
  before or after another element in a one
  dimensional array."
  input list<DAE.Subscript> inlist;
  input list<DAE.Subscript> inlist1;
  input list<DAE.Subscript> inarryDim;
  input list<DAE.Subscript> inarryDim1;
  output Boolean outval;
algorithm
  outval:=
  matchcontinue (inlist, inlist1, inarryDim, inarryDim1)
    local
      list<DAE.Subscript> arryDim, arryDim1;
      list<DAE.Subscript> subscriptLst, subscriptLst1;
      list<Integer> dim_lst,dim_lst1,dim_lst_1,dim_lst1_1;
      list<Integer> index,index1;
      Integer val1,val2;
    case (subscriptLst,subscriptLst1,arryDim,arryDim1)
      equation
        dim_lst = getArrayDim(arryDim);
        dim_lst1 = getArrayDim(arryDim1);
        index = getArrayDim(subscriptLst);
        index1 = getArrayDim(subscriptLst1);
        dim_lst_1 = Util.listStripFirst(dim_lst);
        dim_lst1_1 = Util.listStripFirst(dim_lst1);
        val1 = calcPlace(index,dim_lst_1);
        val2 = calcPlace(index1,dim_lst1_1);
        (val1 > val2) = true;
      then
       true;
    case (_,_,_,_) then false;
  end matchcontinue;
end comparingNonScalars1;

protected function calcPlace
"function: calcPlace
  author: Frenkel TUD
  Helper function for comparingNonScalars1.
  Calculate based on the dimensions and the
  indexes the place of the element in a one
  dimensional array."
  input list<Integer> inindex;
  input list<Integer> dimlist;
  output Integer value;
algorithm
  value:=
  matchcontinue (inindex,dimlist)
    local
      list<Integer> index_lst,dim_lst;
      Integer value,value1,index,dim;
    case ({},{}) then 0;
    case (index::{},_) then index;
    case (index::index_lst,dim::dim_lst)
      equation
        value = calcPlace(index_lst,dim_lst);
        value1 = value + (index*dim);
      then
        value1;
     case (_,_)
      equation
        print("-calcPlace failed\n");
      then
        fail();
  end matchcontinue;
end calcPlace;

protected function getArrayDim
"function: getArrayDim
  author: Frenkel TUD
  Helper function for comparingNonScalars1.
  Return the dimension of an array in a list."
  input list<DAE.Subscript> inarryDim;
  output list<Integer> dimlist;
algorithm
  dimlist:=
  matchcontinue (inarryDim)
    local
      list<DAE.Subscript> arryDim_lst,rest;
      DAE.Subscript arryDim;
      list<Integer> dim_lst,dim_lst1;
      Integer dim;
    case {} then {};
    case ((arryDim as DAE.INDEX(DAE.ICONST(dim)))::rest)
      equation
        dim_lst = getArrayDim(rest);
        dim_lst1 = dim::dim_lst;
      then
        dim_lst1;       
  end matchcontinue;
end getArrayDim;

protected function calculateIndexes2
"function: calculateIndexes2
  author: PA
  Helper function to calculateIndexes"
  input list< tuple<BackendDAE.Var,Integer,Integer> > inVarLst1;
  input Integer inInteger2; //X
  input Integer inInteger3; //xd
  input Integer inInteger4; //y
  input Integer inInteger5; //p
  input Integer inInteger6; //dummy
  input Integer inInteger7; //ext

  input Integer inInteger8; //X_str
  input Integer inInteger9; //xd_str
  input Integer inInteger10; //y_str
  input Integer inInteger11; //p_str
  input Integer inInteger12; //dummy_str

  output list<tuple<BackendDAE.Var,Integer,Integer> > outVarLst1;
  output Integer outInteger2;
  output Integer outInteger3;
  output Integer outInteger4;
  output Integer outInteger5;
  output Integer outInteger6;
  output Integer outInteger7;

  output Integer outInteger8; //x_str
  output Integer outInteger9; //xd_str
  output Integer outInteger10; //y_str
  output Integer outInteger11; //p_str
  output Integer outInteger12; //dummy_str
algorithm
  (outVarLst1,outInteger2,outInteger3,outInteger4,outInteger5,outInteger6,outInteger7,outInteger8,outInteger9,outInteger10,outInteger11,outInteger12):=
  matchcontinue (inVarLst1,inInteger2,inInteger3,inInteger4,inInteger5,inInteger6,inInteger7,inInteger8,inInteger9,inInteger10,inInteger11,inInteger12)
    local
      BackendDAE.Value x,xd,y,p,dummy,y_1,x1,xd1,y1,p1,dummy1,x_1,p_1,ext,ext_1,x_strType,xd_strType,y_strType,p_strType,dummy_strType,y_1_strType,x_1_strType,p_1_strType;
      BackendDAE.Value x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1;
      list< tuple<BackendDAE.Var,Integer,Integer> > vars_1,vs;
      DAE.ComponentRef cr,name;
      DAE.VarDirection d;
      BackendDAE.Type tp;
      Option<DAE.Exp> b;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Integer typ,place;
    
    case ({},x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      then ({},x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.VARIABLE(),
               varDirection = d,
               varType = tp as BackendDAE.STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1_strType = y_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.VARIABLE(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.VARIABLE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1 = y + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.VARIABLE(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.STATE(),
               varDirection = d,
               varType = tp as BackendDAE.STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        x_1_strType = x_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_1_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.STATE(),d,tp,b,value,dim,x_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.STATE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        x_1 = x + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x_1, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.STATE(),d,tp,b,value,dim,x,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DUMMY_DER(),
               varDirection = d,
               varType = tp as BackendDAE.STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1_strType = y_strType + 1 "Dummy derivatives become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.DUMMY_DER(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DUMMY_DER(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1 = y + 1 "Dummy derivatives become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.DUMMY_DER(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DUMMY_STATE(),
               varDirection = d,
               varType = tp as BackendDAE.STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1_strType = y_strType + 1 "Dummy state become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.DUMMY_STATE(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DUMMY_STATE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1 = y + 1 "Dummy state become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.DUMMY_STATE(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DISCRETE(),
               varDirection = d,
               varType = tp as BackendDAE.STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1_strType = y_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.DISCRETE(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DISCRETE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1 = y + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.DISCRETE(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.PARAM(),
               varDirection = d,
               varType = tp as BackendDAE.STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        p_1_strType = p_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_1_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.PARAM(),d,tp,b,value,dim,p_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.PARAM(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        p_1 = p + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p_1, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.PARAM(),d,tp,b,value,dim,p,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.CONST(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
         //IS THIS A BUG??
         // THE INDEX FOR const IS SET TO p (=last parameter index)
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.CONST(),d,tp,b,value,dim,p,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.EXTOBJ(path),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      local Absyn.Path path;
      equation
        ext_1 = ext+1;
        (vars_1,x1,xd1,y1,p1,dummy,ext_1,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext_1,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.EXTOBJ(path),d,tp,b,value,dim,p,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy,ext_1,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
  end matchcontinue;
end calculateIndexes2;

protected function treeGet "function: treeGet
  author: PA

  Copied from generic implementation. Changed that no hashfunction is passed
  since a string can not be uniquely mapped to an int. Therefore we need to compare two strings
  to get a unique ordering.
"
  input BackendDAE.BinTree bt;
  input BackendDAE.Key key;
  output BackendDAE.Value v;
  String keystr;
algorithm
  keystr := ComponentReference.printComponentRefStr(key);
  v := treeGet2(bt, keystr);
end treeGet;

protected function treeGet2 "function: treeGet2
  author: PA

  Helper function to tree_get
"
  input BackendDAE.BinTree inBinTree;
  input String inString;
  output BackendDAE.Value outValue;
algorithm
  outValue:=
  matchcontinue (inBinTree,inString)
    local
      String rkeystr,keystr;
      DAE.ComponentRef rkey;
      BackendDAE.Value rval,cmpval,res;
      Option<BackendDAE.BinTree> left,right;
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = right),keystr)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        0 = System.strcmp(rkeystr, keystr);
      then
        rval;
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = SOME(right)),keystr)
      local BackendDAE.BinTree right;
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "Search to the right" ;
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        res = treeGet2(right, keystr);
      then
        res;
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = SOME(left),rightSubTree = right),keystr)
      local BackendDAE.BinTree left;
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "Search to the left" ;
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        res = treeGet2(left, keystr);
      then
        res;
  end matchcontinue;
end treeGet2;

protected function treeAddList "function: treeAddList
  author: Frenkel TUD
"
  input BackendDAE.BinTree inBinTree;
  input list<BackendDAE.Key> inKeyLst;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree :=
  matchcontinue (inBinTree,inKeyLst)
    local
      BackendDAE.Key key;
      list<BackendDAE.Key> res;
      BackendDAE.BinTree bt,bt_1,bt_2;
    case (bt,{}) then bt;
    case (bt,key::res)
      local DAE.ComponentRef nkey;
    equation
      bt_1 = treeAdd(bt,key,0);
      bt_2 = treeAddList(bt_1,res);
    then bt_2;  
  end matchcontinue;
end treeAddList;

protected function treeAdd "function: treeAdd
  author: PA

  Copied from generic implementation. Changed that no hashfunction is passed
  since a string (ComponentRef) can not be uniquely mapped to an int. Therefore we need to compare two strings
  to get a unique ordering.
"
  input BackendDAE.BinTree inBinTree;
  input BackendDAE.Key inKey;
  input BackendDAE.Value inValue;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree:=
  matchcontinue (inBinTree,inKey,inValue)
    local
      DAE.ComponentRef key,rkey;
      BackendDAE.Value value,rval,cmpval;
      String rkeystr,keystr;
      Option<BackendDAE.BinTree> left,right;
      BackendDAE.BinTree t_1,t,right_1,left_1;
    case (BackendDAE.TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE()),key,value)
      local DAE.ComponentRef nkey;
      equation
        nkey = key;
      then BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(nkey,value)),NONE(),NONE());
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = right),key,value)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "Replace this node" ;
        keystr = ComponentReference.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,value)),left,right);
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = (right as SOME(t))),key,value)
      equation
        keystr = ComponentReference.printComponentRefStr(key) "Insert to right subtree";
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        t_1 = treeAdd(t, key, value);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),left,SOME(t_1));
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = (right as NONE())),key,value)
      equation
        keystr = ComponentReference.printComponentRefStr(key) "Insert to right node";
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        right_1 = treeAdd(BackendDAE.TREENODE(NONE(),NONE(),NONE()), key, value);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),left,SOME(right_1));
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = (left as SOME(t)),rightSubTree = right),key,value)
      equation
        keystr = ComponentReference.printComponentRefStr(key) "Insert to left subtree";
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        t_1 = treeAdd(t, key, value);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),SOME(t_1),right);
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = (left as NONE()),rightSubTree = right),key,value)
      equation
        keystr = ComponentReference.printComponentRefStr(key) "Insert to left node";
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        left_1 = treeAdd(BackendDAE.TREENODE(NONE(),NONE(),NONE()), key, value);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),SOME(left_1),right);
    case (_,_,_)
      equation
        print("tree_add failed\n");
      then
        fail();
  end matchcontinue;
end treeAdd;

protected function treeDelete "function: treeDelete
  author: PA

  This function deletes an entry from the BinTree.
"
  input BackendDAE.BinTree inBinTree;
  input BackendDAE.Key inKey;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree:=
  matchcontinue (inBinTree,inKey)
    local
      BackendDAE.BinTree bt,right_1,right,t_1,t;
      DAE.ComponentRef key,rkey;
      String rkeystr,keystr;
      BackendDAE.TreeValue rightmost;
      Option<BackendDAE.BinTree> optright_1,left,lleft,lright,topt_1;
      BackendDAE.Value rval,cmpval;
      Option<BackendDAE.TreeValue> leftval;
    case ((bt as BackendDAE.TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE())),key) then bt;
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = SOME(right)),key)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "delete this node, when existing right node" ;
        keystr = ComponentReference.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
        (rightmost,right_1) = treeDeleteRightmostValue(right);
        optright_1 = treePruneEmptyNodes(right_1);
      then
        BackendDAE.TREENODE(SOME(rightmost),left,optright_1);
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = SOME(BackendDAE.TREENODE(leftval,lleft,lright)),rightSubTree = NONE()),key)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "delete this node, when no right node, but left node" ;
        keystr = ComponentReference.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        BackendDAE.TREENODE(leftval,lleft,lright);
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = NONE(),rightSubTree = NONE()),key)
      equation
        rkeystr = ComponentReference.printComponentRefStr(rkey) "delete this node, when no left or right node" ;
        keystr = ComponentReference.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        BackendDAE.TREENODE(NONE(),NONE(),NONE());
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = (right as SOME(t))),key)
      local Option<BackendDAE.BinTree> right;
      equation
        keystr = ComponentReference.printComponentRefStr(key) "delete in right subtree" ;
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        t_1 = treeDelete(t, key);
        topt_1 = treePruneEmptyNodes(t_1);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),left,topt_1);
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(rkey,rval)),leftSubTree = (left as SOME(t)),rightSubTree = right),key)
      local Option<BackendDAE.BinTree> right;
      equation
        keystr = ComponentReference.printComponentRefStr(key) "delete in left subtree" ;
        rkeystr = ComponentReference.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        t_1 = treeDelete(t, key);
        topt_1 = treePruneEmptyNodes(t_1);
      then
        BackendDAE.TREENODE(SOME(BackendDAE.TREEVALUE(rkey,rval)),topt_1,right);
    case (_,_)
      equation
        print("tree_delete failed\n");
      then
        fail();
  end matchcontinue;
end treeDelete;

protected function treeDeleteRightmostValue "function: treeDeleteRightmostValue
  author: PA

  This function takes a BackendDAE.BinTree and deletes the rightmost value of the tree.
  Tt returns this value and the updated BinTree. This function is used in
  the binary tree deletion function \'tree_delete\'.

  inputs:  (BinTree)
  outputs: (TreeValue, /* deleted value */
              BackendDAE.BinTree    /* updated bintree */)
"
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.TreeValue outTreeValue;
  output BackendDAE.BinTree outBinTree;
algorithm
  (outTreeValue,outBinTree):=
  matchcontinue (inBinTree)
    local
      BackendDAE.TreeValue treevalue,value;
      BackendDAE.BinTree left,right_1,right,bt;
      Option<BackendDAE.BinTree> rightopt_1;
      Option<BackendDAE.TreeValue> treeval;
    case (BackendDAE.TREENODE(value = SOME(treevalue),leftSubTree = NONE(),rightSubTree = NONE())) then (treevalue,BackendDAE.TREENODE(NONE(),NONE(),NONE()));
    case (BackendDAE.TREENODE(value = SOME(treevalue),leftSubTree = SOME(left),rightSubTree = NONE())) then (treevalue,left);
    case (BackendDAE.TREENODE(value = treeval,leftSubTree = left,rightSubTree = SOME(right)))
      local Option<BackendDAE.BinTree> left;
      equation
        (value,right_1) = treeDeleteRightmostValue(right);
        rightopt_1 = treePruneEmptyNodes(right_1);
      then
        (value,BackendDAE.TREENODE(treeval,left,rightopt_1));
    case (BackendDAE.TREENODE(value = SOME(treeval),leftSubTree = NONE(),rightSubTree = SOME(right)))
      local BackendDAE.TreeValue treeval;
      equation
        failure((_,_) = treeDeleteRightmostValue(right));
        print("right value was empty , left NONE\n");
      then
        (treeval,BackendDAE.TREENODE(NONE(),NONE(),NONE()));
    case (bt)
      equation
        print("-tree_delete_rightmost_value failed\n");
      then
        fail();
  end matchcontinue;
end treeDeleteRightmostValue;

protected function treePruneEmptyNodes "function: tree_prune_emtpy_nodes
  author: PA

  This function is a helper function to tree_delete
  It is used to delete empty nodes of the BackendDAE.BinTree representation, that might be introduced
  when deleting nodes.
"
  input BackendDAE.BinTree inBinTree;
  output Option<BackendDAE.BinTree> outBinTreeOption;
algorithm
  outBinTreeOption:=
  matchcontinue (inBinTree)
    local BackendDAE.BinTree bt;
    case BackendDAE.TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE()) then NONE();
    case bt then SOME(bt);
  end matchcontinue;
end treePruneEmptyNodes;

protected function bintreeToList "function: bintreeToList
  author: PA

  This function takes a BackendDAE.BinTree and transform it into a list
  representation, i.e. two lists of keys and values
"
  input BackendDAE.BinTree inBinTree;
  output list<BackendDAE.Key> outKeyLst;
  output list<BackendDAE.Value> outValueLst;
algorithm
  (outKeyLst,outValueLst):=
  matchcontinue (inBinTree)
    local
      list<BackendDAE.Key> klst;
      list<BackendDAE.Value> vlst;
      BackendDAE.BinTree bt;
    case (bt)
      equation
        (klst,vlst) = bintreeToList2(bt, {}, {});
      then
        (klst,vlst);
    case (_)
      equation
        print("-bintree_to_list failed\n");
      then
        fail();
  end matchcontinue;
end bintreeToList;

protected function bintreeToList2 "function: bintreeToList2
  author: PA

  helper function to bintree_to_list
"
  input BackendDAE.BinTree inBinTree;
  input list<BackendDAE.Key> inKeyLst;
  input list<BackendDAE.Value> inValueLst;
  output list<BackendDAE.Key> outKeyLst;
  output list<BackendDAE.Value> outValueLst;
algorithm
  (outKeyLst,outValueLst):=
  matchcontinue (inBinTree,inKeyLst,inValueLst)
    local
      list<BackendDAE.Key> klst;
      list<BackendDAE.Value> vlst;
      DAE.ComponentRef key;
      BackendDAE.Value value;
      Option<BackendDAE.BinTree> left,right;
    case (BackendDAE.TREENODE(value = NONE(),leftSubTree = NONE(),rightSubTree = NONE()),klst,vlst) then (klst,vlst);
    case (BackendDAE.TREENODE(value = SOME(BackendDAE.TREEVALUE(key,value)),leftSubTree = left,rightSubTree = right),klst,vlst)
      equation
        (klst,vlst) = bintreeToListOpt(left, klst, vlst);
        (klst,vlst) = bintreeToListOpt(right, klst, vlst);
      then
        ((key :: klst),(value :: vlst));
    case (BackendDAE.TREENODE(value = NONE(),leftSubTree = left,rightSubTree = right),klst,vlst)
      equation
        (klst,vlst) = bintreeToListOpt(left, klst, vlst);
        (klst,vlst) = bintreeToListOpt(left, klst, vlst);
      then
        (klst,vlst);
  end matchcontinue;
end bintreeToList2;

protected function bintreeToListOpt "function: bintreeToListOpt
  author: PA

  helper function to bintree_to_list
"
  input Option<BackendDAE.BinTree> inBinTreeOption;
  input list<BackendDAE.Key> inKeyLst;
  input list<BackendDAE.Value> inValueLst;
  output list<BackendDAE.Key> outKeyLst;
  output list<BackendDAE.Value> outValueLst;
algorithm
  (outKeyLst,outValueLst):=
  matchcontinue (inBinTreeOption,inKeyLst,inValueLst)
    local
      list<BackendDAE.Key> klst;
      list<BackendDAE.Value> vlst;
      BackendDAE.BinTree bt;
    case (NONE(),klst,vlst) then (klst,vlst);
    case (SOME(bt),klst,vlst)
      equation
        (klst,vlst) = bintreeToList2(bt, klst, vlst);
      then
        (klst,vlst);
  end matchcontinue;
end bintreeToListOpt;

protected function bintreeDepth "function: bintreeDepth
  author: PA

  This function calculates the depth of the Binary Tree given
  as input. It can be used for debugging purposes to investigate
  how balanced binary trees are.
"
  input BackendDAE.BinTree inBinTree;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inBinTree)
    local
      BackendDAE.Value ld,rd,res;
      BackendDAE.BinTree left,right;
    case (BackendDAE.TREENODE(leftSubTree = NONE(),rightSubTree = NONE())) then 1;
    case (BackendDAE.TREENODE(leftSubTree = SOME(left),rightSubTree = SOME(right)))
      equation
        ld = bintreeDepth(left);
        rd = bintreeDepth(right);
        res = intMax(ld, rd);
      then
        res + 1;
    case (BackendDAE.TREENODE(leftSubTree = SOME(left),rightSubTree = NONE()))
      equation
        ld = bintreeDepth(left);
      then
        ld;
    case (BackendDAE.TREENODE(leftSubTree = NONE(),rightSubTree = SOME(right)))
      equation
        rd = bintreeDepth(right);
      then
        rd;
  end matchcontinue;
end bintreeDepth;

protected function isAlgebraic "function: isAlgebraic
  author: PA

  This function returns true if an expression is purely algebraic, i.e. not
  containing any derivatives
  Otherwise it returns false.
"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    local
      BackendDAE.Value x,ival;
      String s,id;
      DAE.ComponentRef c;
      DAE.Exp e1,e2,e21,e22,e,t,f,stop,start,step,cr,dim,exp,iterexp;
      DAE.Operator op;
      DAE.ExpType ty,ty2,REAL;
      list<DAE.Exp> args,es,sub;
      Absyn.Path fcn;
    case (DAE.END()) then true;
    case (DAE.ICONST(integer = x)) then true;
    case (DAE.RCONST(real = x))
      local Real x;
      then
        true;
    case (DAE.SCONST(string = s)) then true;
    case (DAE.BCONST(bool = false)) then true;
    case (DAE.BCONST(bool = true)) then true;
    case (DAE.ENUM_LITERAL(name = _)) then true;

    case (DAE.CREF(componentRef = c)) then true;
    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.SUB(ty = ty)),exp2 = (e2 as DAE.BINARY(exp1 = e21,operator = DAE.SUB(ty = ty2),exp2 = e22))))
      equation
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (DAE.UNARY(operator = op,exp = e))
      equation
        true = isAlgebraic(e);
      then
        true;
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (DAE.LUNARY(operator = op,exp = e))
      equation
        true = isAlgebraic(e);
      then
        true;
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (DAE.IFEXP(expCond = c,expThen = t,expElse = f))
      local DAE.Exp c;
      equation
        true = isAlgebraic(c);
        true = isAlgebraic(t);
        true = isAlgebraic(f);
      then
        true;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = args)) then false;
    case (DAE.CALL(path = fcn,expLst = args)) then true;
    case (DAE.ARRAY(array = es)) then true;
    case (DAE.TUPLE(PR = es)) then true;
    case (DAE.MATRIX(scalar = es))
      local list<list<tuple<DAE.Exp, Boolean>>> es;
      then
        true;
    case (DAE.RANGE(exp = start,expOption = NONE(),range = stop))
      equation
        true = isAlgebraic(start);
        true = isAlgebraic(stop);
      then
        true;
    case (DAE.RANGE(exp = start,expOption = SOME(step),range = stop))
      equation
        true = isAlgebraic(start);
        true = isAlgebraic(step);
        true = isAlgebraic(stop);
      then
        true;
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e)) then true;
    case (DAE.ASUB(exp = e,sub = sub))
      equation
        true = isAlgebraic(e);
      then
        true;
    case (DAE.SIZE(exp = cr)) then true;
    case (DAE.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp)) then true;
    case (_) then true;
  end matchcontinue;
end isAlgebraic;

public function isVarKnown "function: isVarKnown
  author: PA

  Returns true if the the variable is present in the variable list.
  This is done by traversing the list, searching for a matching variable
  name.
"
  input list<BackendDAE.Var> inVarLst;
  input DAE.ComponentRef inComponentRef;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVarLst,inComponentRef)
    local
      DAE.ComponentRef var_name,cr;
      BackendDAE.Var variable;
      BackendDAE.Value indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<BackendDAE.Var> rest;
      Boolean res;
    case ({},var_name) then false;
    case (((variable as BackendDAE.VAR(varName = cr,index = indx,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix,streamPrefix = streamPrefix)) :: rest),var_name)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr, var_name);
      then
        true;
    case (((variable as BackendDAE.VAR(varName = cr,index = indx,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix,streamPrefix = streamPrefix)) :: rest),var_name)
      equation
        res = isVarKnown(rest, var_name);
      then
        res;
  end matchcontinue;
end isVarKnown;

public function getAllExps "function: getAllExps
  author: PA

  This function goes through the BackendDAE.DAELow structure and finds all the
  expressions and returns them in a list
"
  input BackendDAE.DAELow inDAELow;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inDAELow)
    local
      list<DAE.Exp> exps1,exps2,exps3,exps4,exps5,exps6,exps;
      list<DAE.Algorithm> alglst;
      list<list<DAE.Exp>> explist6,explist;
      BackendDAE.Variables vars1,vars2;
      BackendDAE.EquationArray eqns,reqns,ieqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> algs;
    case (BackendDAE.DAELOW(orderedVars = vars1,knownVars = vars2,orderedEqs = eqns,removedEqs = reqns,initialEqs = ieqns,arrayEqs = ae,algorithms = algs))
      equation
        exps1 = getAllExpsVars(vars1);
        exps2 = getAllExpsVars(vars2);
        exps3 = getAllExpsEqns(eqns);
        exps4 = getAllExpsEqns(reqns);
        exps5 = getAllExpsEqns(ieqns);
        exps6 = getAllExpsArrayEqns(ae);
        alglst = arrayList(algs);
        explist6 = Util.listMap(alglst, Algorithm.getAllExps);
        explist = listAppend({exps1,exps2,exps3,exps4,exps5,exps6}, explist6);
        exps = Util.listFlatten(explist);
      then
        exps;
  end matchcontinue;
end getAllExps;

protected function getAllExpsArrayEqns "function: getAllExpsArrayEqns
  author: PA

  Returns all expressions in array equations
"
  input array<BackendDAE.MultiDimEquation> arr;
  output list<DAE.Exp> res;
  list<BackendDAE.MultiDimEquation> lst;
  list<list<DAE.Exp>> llst;
algorithm
  lst := arrayList(arr);
  llst := Util.listMap(lst, getAllExpsArrayEqn);
  res := Util.listFlatten(llst);
end getAllExpsArrayEqns;

protected function getAllExpsArrayEqn "function: getAllExpsArrayEqn
  author: PA

  Helper function to get_all_exps_array_eqns
"
  input BackendDAE.MultiDimEquation inMultiDimEquation;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inMultiDimEquation)
    local DAE.Exp e1,e2;
    case (BackendDAE.MULTIDIM_EQUATION(left = e1,right = e2)) then {e1,e2};
  end matchcontinue;
end getAllExpsArrayEqn;

protected function getAllExpsVars "function: getAllExpsVars
  author: PA

  Helper to get_all_exps. Goes through the BackendDAE.Variables type
"
  input BackendDAE.Variables inVariables;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inVariables)
    local
      list<BackendDAE.Var> vars;
      list<DAE.Exp> exps;
      array<list<BackendDAE.CrefIndex>> crefindex;
      array<list<BackendDAE.StringIndex>> oldcrefindex;
      BackendDAE.VariableArray vararray;
      BackendDAE.Value bsize,nvars;
    case BackendDAE.VARIABLES(crefIdxLstArr = crefindex,strIdxLstArr = oldcrefindex,varArr = vararray,bucketSize = bsize,numberOfVars = nvars)
      equation
        vars = vararrayList(vararray) "We can ignore crefs, they don\'t contain real expressions" ;
        exps = Util.listMap(vars, getAllExpsVar);
        exps = Util.listFlatten(exps);
      then
        exps;
  end matchcontinue;
end getAllExpsVars;

protected function getAllExpsVar "function: getAllExpsVar
  author: PA
  Helper to get_all_exps_vars. Get all exps from a  Var.
  DAE.ET_OTHER is used as type for componentref. Not important here.
  We only use the exp list for finding function calls"
  input BackendDAE.Var inVar;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inVar)
    local
      list<DAE.Exp> e1,e2,e3,exps;
      DAE.ComponentRef cref;
      Option<DAE.Exp> bndexp;
      list<DAE.Subscript> instdims;
    case BackendDAE.VAR(varName = cref,
             bindExp = bndexp,
             arryDim = instdims
             )
      equation
        e1 = Util.optionToList(bndexp);
        e3 = Util.listMap(instdims, getAllExpsSubscript);
        e3 = Util.listFlatten(e3);
        exps = Util.listFlatten({e1,e3,{DAE.CREF(cref,DAE.ET_OTHER())}});
      then
        exps;
  end matchcontinue;
end getAllExpsVar;

protected function getAllExpsSubscript "function: getAllExpsSubscript
  author: PA
  Get all exps from a Subscript"
  input DAE.Subscript inSubscript;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inSubscript)
    local DAE.Exp e;
    case DAE.WHOLEDIM() then {};
    case DAE.SLICE(exp = e) then {e};
    case DAE.INDEX(exp = e) then {e};
  end matchcontinue;
end getAllExpsSubscript;

protected function getAllExpsEqns "function: getAllExpsEqns
  author: PA

  Helper to get_all_exps. Goes through the BackendDAE.EquationArray type
"
  input BackendDAE.EquationArray inEquationArray;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inEquationArray)
    local
      list<BackendDAE.Equation> eqns;
      list<DAE.Exp> exps;
      BackendDAE.EquationArray eqnarray;
    case ((eqnarray as BackendDAE.EQUATION_ARRAY(numberOfElement = _)))
      equation
        eqns = equationList(eqnarray);
        exps = Util.listMap(eqns, getAllExpsEqn);
        exps = Util.listFlatten(exps);
      then
        exps;
  end matchcontinue;
end getAllExpsEqns;

protected function getAllExpsEqn "function: getAllExpsEqn
  author: PA
  Helper to get_all_exps_eqns. Get all exps from an Equation."
  input BackendDAE.Equation inEquation;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst :=  matchcontinue (inEquation)
    local
      DAE.Exp e1,e2,e;
      list<DAE.Exp> expl,exps;
      DAE.ExpType tp;
      DAE.ComponentRef cr;
      BackendDAE.Value ind;
      BackendDAE.WhenEquation elsePart;
      DAE.ElementSource source;

    case BackendDAE.EQUATION(exp = e1,scalar = e2) then {e1,e2};
    case BackendDAE.ARRAY_EQUATION(crefOrDerCref = expl) then expl;
    case BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e)
      equation
        tp = Exp.typeof(e);
      then
        {DAE.CREF(cr,tp),e};
    case BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left = cr,right = e,elsewhenPart=NONE()))
      equation
        tp = Exp.typeof(e);
      then
        {DAE.CREF(cr,tp),e};
    case BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(_,cr,e,SOME(elsePart)),source = source)
      equation
        tp = Exp.typeof(e);
        expl = getAllExpsEqn(BackendDAE.WHEN_EQUATION(elsePart,source));
        exps = listAppend({DAE.CREF(cr,tp),e},expl);
      then
        exps;
    case BackendDAE.ALGORITHM(index = ind,in_ = e1,out = e2)
      local list<DAE.Exp> e1,e2;
      equation
        exps = listAppend(e1, e2);
      then
        exps;
  end matchcontinue;
end getAllExpsEqn;

public function traverseDEALowExps "function: traverseDEALowExps
  author: Frenkel TUD

  This function goes through the BackendDAE.DAELow structure and finds all the
  expressions and performs the function on them in a list 
  an extra argument passed through the function.
"
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any;  
  input BackendDAE.DAELow inDAELow;
  input Boolean traverseAlgorithms "true if traverse also algorithms";
  input FuncExpType func;
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeB;
  end FuncExpType;
algorithm
  outTypeBLst:=
  matchcontinue (inDAELow,traverseAlgorithms,func,inTypeA)
    local
      list<Type_b> exps1,exps2,exps3,exps4,exps5,exps6,exps7,exps;
      list<DAE.Algorithm> alglst;
      BackendDAE.Variables vars1,vars2;
      BackendDAE.EquationArray eqns,reqns,ieqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> algs;
    case (BackendDAE.DAELOW(orderedVars = vars1,knownVars = vars2,orderedEqs = eqns,removedEqs = reqns,
          initialEqs = ieqns,arrayEqs = ae,algorithms = algs),true,func,inTypeA)
      equation
        exps1 = traverseDEALowExpsVars(vars1,func,inTypeA);
        exps2 = traverseDEALowExpsVars(vars2,func,inTypeA);
        exps3 = traverseDEALowExpsEqns(eqns,func,inTypeA);
        exps4 = traverseDEALowExpsEqns(reqns,func,inTypeA);
        exps5 = traverseDEALowExpsEqns(ieqns,func,inTypeA);
        exps6 = traverseDEALowExpsArrayEqns(ae,func,inTypeA);
        alglst = arrayList(algs);
        exps7 = Util.listMapFlat2(alglst, Algorithm.traverseExps,func,inTypeA);
        exps = Util.listFlatten({exps1,exps2,exps3,exps4,exps5,exps6,exps7});
      then
        exps;
    case (BackendDAE.DAELOW(orderedVars = vars1,knownVars = vars2,orderedEqs = eqns,removedEqs = reqns,
          initialEqs = ieqns,arrayEqs = ae,algorithms = algs),false,func,inTypeA)
      equation
        exps1 = traverseDEALowExpsVars(vars1,func,inTypeA);
        exps2 = traverseDEALowExpsVars(vars2,func,inTypeA);
        exps3 = traverseDEALowExpsEqns(eqns,func,inTypeA);
        exps4 = traverseDEALowExpsEqns(reqns,func,inTypeA);
        exps5 = traverseDEALowExpsEqns(ieqns,func,inTypeA);
        exps6 = traverseDEALowExpsArrayEqns(ae,func,inTypeA);
        exps = Util.listFlatten({exps1,exps2,exps3,exps4,exps5,exps6});
      then
        exps;        
    case (_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- DAELow.traverseDEALowExps failed");
      then
        fail();         
  end matchcontinue;
end traverseDEALowExps;

protected function traverseDEALowExpsVars "function: traverseDEALowExpsVars
  author: Frenkel TUD

  Helper for traverseDEALowExps
"
  input BackendDAE.Variables inVariables;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeb;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any; 
algorithm
  outTypeBLst:=
  matchcontinue (inVariables,func,inTypeA)
    local
      list<BackendDAE.Var> vars;
      list<Type_b> talst;
      array<list<BackendDAE.CrefIndex>> crefindex;
      array<list<BackendDAE.StringIndex>> oldcrefindex;
      BackendDAE.VariableArray vararray;
      BackendDAE.Value bsize,nvars;
    case (BackendDAE.VARIABLES(crefIdxLstArr = crefindex,strIdxLstArr = oldcrefindex,varArr = vararray,bucketSize = bsize,numberOfVars = nvars),func,inTypeA)
      equation
        vars = vararrayList(vararray) "We can ignore crefs, they don\'t contain real expressions" ;
        talst = Util.listMapFlat2(vars, traverseDEALowExpsVar,func,inTypeA);
      then
        talst;
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- DAELow.traverseDEALowExpsVars failed");
      then
        fail();        
  end matchcontinue;
end traverseDEALowExpsVars;

protected function traverseDEALowExpsVar "function: traverseDEALowExpsVar
  author: Frenkel TUD
  Helper traverseDEALowExpsVar. Get all exps from a  Var.
  DAE.ET_OTHER is used as type for componentref. Not important here.
  We only use the exp list for finding function calls"
  input BackendDAE.Var inVar;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeb;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeBLst:=
  matchcontinue (inVar,func,inTypeA)
    local
      list<DAE.Exp> e1;
      Type_a ta;
      list<Type_b> talst,talst1,talst2,talst3,talst4;
      DAE.ComponentRef cref;
      Option<DAE.Exp> bndexp;
      list<DAE.Subscript> instdims;
    case (BackendDAE.VAR(varName = cref,
             bindExp = bndexp,
             arryDim = instdims
             ),func,inTypeA)
      equation
        e1 = Util.optionToList(bndexp);
        talst = Util.listMapFlat1(e1,func,inTypeA);
        talst1 = Util.listMapFlat2(instdims, traverseDEALowExpsSubscript,func,inTypeA);
        talst2 = listAppend(talst,talst1);
        talst3 = func(DAE.CREF(cref,DAE.ET_OTHER()),inTypeA);
        talst4 = listAppend(talst2,talst3);
      then
        talst4;
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- DAELow.traverseDEALowExpsVar failed");
      then
        fail();          
  end matchcontinue;
end traverseDEALowExpsVar;

protected function traverseDEALowExpsSubscript "function: traverseDEALowExpsSubscript
  author: Frenkel TUD
  helper for traverseDEALowExpsSubscript"
  input DAE.Subscript inSubscript;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeb;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeBLst:=
  matchcontinue (inSubscript,func,inTypeA)
    local
      DAE.Exp e;
      list<Type_b> talst;      
    case (DAE.WHOLEDIM(),_,inTypeA) then {};
    case (DAE.SLICE(exp = e),func,inTypeA)
      equation
        talst = func(e,inTypeA);  
      then talst;
    case (DAE.INDEX(exp = e),func,inTypeA)
      equation
        talst = func(e,inTypeA);  
      then talst;
  end matchcontinue;
end traverseDEALowExpsSubscript;

protected function traverseDEALowExpsEqns "function: traverseDEALowExpsEqns
  author: Frenkel TUD

  Helper for traverseDEALowExpsEqns
"
  input BackendDAE.EquationArray inEquationArray;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeb;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeBLst:=
  matchcontinue (inEquationArray,func,inTypeA)
    local
      list<BackendDAE.Equation> eqns;
      list<Type_b> talst;
      BackendDAE.EquationArray eqnarray;
    case ((eqnarray as BackendDAE.EQUATION_ARRAY(numberOfElement = _)),func,inTypeA)
      equation
        eqns = equationList(eqnarray);
        talst = Util.listMapFlat2(eqns, traverseDEALowExpsEqn,func,inTypeA);
      then
        talst;
  end matchcontinue;
end traverseDEALowExpsEqns;

protected function traverseDEALowExpsEqn "function: traverseDEALowExpsEqn
  author: PA
  Helper for traverseDEALowExpsEqn."
  input BackendDAE.Equation inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeb;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeBLst:=  matchcontinue (inEquation,func,inTypeA)
    local
      DAE.Exp e1,e2,e;
      list<DAE.Exp> expl,exps;
      DAE.ExpType tp;
      DAE.ComponentRef cr;
      BackendDAE.Value ind;
      BackendDAE.WhenEquation elsePart;
      DAE.ElementSource source;
      list<Type_b> talst,talst1,talst2,talst3,talst4;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2),func,inTypeA)
      equation
        talst = func(e1,inTypeA);
        talst1 = func(e2,inTypeA); 
        talst2 = listAppend(talst,talst1);
      then
        talst2;
    case (BackendDAE.ARRAY_EQUATION(crefOrDerCref = expl),func,inTypeA)
      equation
        talst = Util.listMapFlat1(expl,func,inTypeA);
      then
        talst;
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e),func,inTypeA)
      equation
        tp = Exp.typeof(e);
        talst = func(DAE.CREF(cr,tp),inTypeA);
        talst1 = func(e,inTypeA); 
        talst2 = listAppend(talst,talst1);
      then
        talst2;
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left = cr,right = e,elsewhenPart=NONE())),func,inTypeA)
      equation
        tp = Exp.typeof(e);
        talst = func(DAE.CREF(cr,tp),inTypeA);
        talst1 = func(e,inTypeA); 
        talst2 = listAppend(talst,talst1);
      then
        talst2;
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(_,cr,e,SOME(elsePart)),source = source),func,inTypeA)
      equation
        tp = Exp.typeof(e);
        talst = func(DAE.CREF(cr,tp),inTypeA);
        talst1 = func(e,inTypeA); 
        talst2 = listAppend(talst,talst1);  
        talst3 = traverseDEALowExpsEqn(BackendDAE.WHEN_EQUATION(elsePart,source),func,inTypeA);
        talst4 = listAppend(talst2,talst3);  
      then
        talst4;
    case (BackendDAE.ALGORITHM(index = ind,in_ = e1,out = e2),func,inTypeA)
      local list<DAE.Exp> e1,e2;
      equation
        expl = listAppend(e1, e2);
        talst = Util.listMapFlat1(expl,func,inTypeA);
      then
        talst;
  end matchcontinue;
end traverseDEALowExpsEqn;

protected function traverseDEALowExpsArrayEqns "function: traverseDEALowExpsArrayEqns
  author: Frenkel TUD

  helper for traverseDEALowExps
"
  input array<BackendDAE.MultiDimEquation> arr;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeb;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any;
  list<BackendDAE.MultiDimEquation> lst;
algorithm
  lst := arrayList(arr);
  outTypeBLst := Util.listMapFlat2(lst, traverseDEALowExpsArrayEqn,func,inTypeA);
end traverseDEALowExpsArrayEqns;

protected function traverseDEALowExpsArrayEqn "function: traverseDEALowExpsArrayEqn
  author: Frenkel TUD

  Helper function to traverseDEALowExpsArrayEqns
"
  input BackendDAE.MultiDimEquation inMultiDimEquation;
  input FuncExpType func;  
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeb;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeBLst:=
  matchcontinue (inMultiDimEquation,func,inTypeA)
    local 
      DAE.Exp e1,e2;
      list<Type_b> talst,talst1,talst2;
    case (BackendDAE.MULTIDIM_EQUATION(left = e1,right = e2),func,inTypeA)
      equation
        talst = func(e1,inTypeA);
        talst1 = func(e2,inTypeA); 
        talst2 = listAppend(talst,talst1);
      then
        talst2;
  end matchcontinue;
end traverseDEALowExpsArrayEqn;

public function isParam
"function: isParam
  Return true if variable is a parameter."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case BackendDAE.VAR(varKind = BackendDAE.PARAM()) then true;
    case (_) then false;
  end matchcontinue;
end isParam;

public function isIntParam
"function: isIntParam
  Return true if variable is a parameter and integer."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = BackendDAE.INT())) then true;
    case (_) then false;
  end matchcontinue;
end isIntParam;

public function isBoolParam
"function: isBoolParam
  Return true if variable is a parameter and boolean."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = BackendDAE.BOOL())) then true;
    case (_) then false;
  end matchcontinue;
end isBoolParam;

public function isStringParam
"function: isStringParam
  Return true if variable is a parameter."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = BackendDAE.STRING())) then true;
    case (_) then false;
  end matchcontinue;
end isStringParam;

public function isExtObj
"function: isExtObj
  Return true if variable is an external object."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.EXTOBJ(_))) then true;
    case (_) then false;
  end matchcontinue;
end isExtObj;

public function isRealParam
"function: isParam
  Return true if variable is a parameter of real-type"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inVar)
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(),varType = BackendDAE.REAL())) then true;
    case (_) then false;
  end matchcontinue;
end isRealParam;

public function isNonRealParam
"function: isNonRealParam
  Return true if variable is NOT a parameter of real-type"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := not isRealParam(inVar);
end isNonRealParam;

public function isOutput
"function: isOutput
  Return true if variable is declared as output. Note that the output
  attribute sticks with a variable even if it is originating from a sub
  component, which is not the case for Dymola."
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varDirection = DAE.OUTPUT())) then true;
    case (_) then false;
  end matchcontinue;
end isOutput;

public function isInput
"function: isInput
  Returns true if variable is declared as input.
  See also is_ouput above"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (BackendDAE.VAR(varDirection = DAE.INPUT())) then true;
    case (_) then false;
  end matchcontinue;
end isInput;

public function getWhenEquationExpr
"function: getWhenEquationExpr
  Get the left and right hand parts from an equation appearing in a when clause"
  input BackendDAE.WhenEquation inWhenEquation;
  output DAE.ComponentRef outComponentRef;
  output DAE.Exp outExp;
algorithm
  (outComponentRef,outExp):=
  matchcontinue (inWhenEquation)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
    case (BackendDAE.WHEN_EQ(left = cr,right = e)) then (cr,e);
  end matchcontinue;
end getWhenEquationExpr;

public function getWhenCondition
"function: getWhenCodition
  Get expression's of condition by when equation"
  input list<BackendDAE.WhenClause> inWhenClause;
  input Integer inIndex;
  output list<DAE.Exp> conditionList;
algorithm
  conditionList := matchcontinue (inWhenClause, inIndex)
    local
      list<BackendDAE.WhenClause> wc;
      Integer ind;
      list<DAE.Exp> condlst;
      DAE.Exp e;
    case (wc, ind)
      equation
        BackendDAE.WHEN_CLAUSE(condition=DAE.ARRAY(_,_,condlst)) = listNth(wc, ind);
      then condlst;
    case (wc, ind)
      equation
        BackendDAE.WHEN_CLAUSE(condition=e) = listNth(wc, ind);
      then {e};
  end matchcontinue;
end getWhenCondition;

public function getZeroCrossingIndicesFromWhenClause "function: getZeroCrossingIndicesFromWhenClause
  Returns a list of indices of zerocrossings that a given when clause is dependent on.
"
  input BackendDAE.DAELow inDAELow;
  input Integer inInteger;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inDAELow,inInteger)
    local
      list<BackendDAE.Value> res;
      list<BackendDAE.ZeroCrossing> zcLst;
      BackendDAE.Value when_index;
    case (BackendDAE.DAELOW(eventInfo = BackendDAE.EVENT_INFO(zeroCrossingLst = zcLst)),when_index)
      equation
        res = getZeroCrossingIndicesFromWhenClause2(zcLst, 0, when_index);
      then
        res;
  end matchcontinue;
end getZeroCrossingIndicesFromWhenClause;

protected function getZeroCrossingIndicesFromWhenClause2 "function: getZeroCrossingIndicesFromWhenClause2
  helper function to get_zero_crossing_indices_from_when_clause
"
  input list<BackendDAE.ZeroCrossing> inZeroCrossingLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inZeroCrossingLst1,inInteger2,inInteger3)
    local
      BackendDAE.Value count_1,count,when_index;
      list<BackendDAE.Value> resx,whenClauseList;
      list<BackendDAE.ZeroCrossing> rest;
    case ({},_,_) then {};
    case ((BackendDAE.ZERO_CROSSING(occurWhenLst = whenClauseList) :: rest),count,when_index)
      equation
        _ = Util.listGetMember(when_index, whenClauseList);
        count_1 = count + 1;
        resx = getZeroCrossingIndicesFromWhenClause2(rest, count_1, when_index);
      then
        (count :: resx);
    case ((BackendDAE.ZERO_CROSSING(occurWhenLst = whenClauseList) :: rest),count,when_index)
      equation
        failure(_ = Util.listGetMember(when_index, whenClauseList));
        count_1 = count + 1;
        resx = getZeroCrossingIndicesFromWhenClause2(rest, count_1, when_index);
      then
        resx;
    case (_,_,_)
      equation
        print("-get_zero_crossing_indices_from_when_clause2 failed\n");
      then
        fail();
  end matchcontinue;
end getZeroCrossingIndicesFromWhenClause2;

public function daeVars
  input BackendDAE.DAELow inDAELow;
  output BackendDAE.Variables vars;
algorithm
  vars := matchcontinue (inDAELow)
    local BackendDAE.Variables vars1,vars2;
    case (BackendDAE.DAELOW(orderedVars = vars1, knownVars = vars2))
      then vars1;
  end matchcontinue;
end daeVars;

public function daeKnVars
  input BackendDAE.DAELow inDAELow;
  output BackendDAE.Variables vars;
algorithm
  vars := matchcontinue (inDAELow)
    local BackendDAE.Variables vars1,vars2;
    case (BackendDAE.DAELOW(orderedVars = vars1, knownVars = vars2))
      then vars2;
  end matchcontinue;
end daeKnVars;

public function makeExpType
"Transforms a BackendDAE.Type to DAE.ExpType
"
  input BackendDAE.Type inType;
  output DAE.ExpType outType;
algorithm
  outType := matchcontinue(inType)
    local
      list<String> strLst;
    case BackendDAE.REAL() then DAE.ET_REAL();
    case BackendDAE.INT() then DAE.ET_INT();
    case BackendDAE.BOOL() then DAE.ET_BOOL();
    case BackendDAE.STRING() then DAE.ET_STRING();
    case BackendDAE.ENUMERATION(strLst) then DAE.ET_ENUMERATION(Absyn.IDENT(""),strLst,{});
    case BackendDAE.EXT_OBJECT(_) then DAE.ET_OTHER();
  end matchcontinue;
end makeExpType;

protected function generateDaeType
"Transforms a BackendDAE.Type to DAE.Type
"
  input BackendDAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(inType)
    local
      list<String> strLst;
      Absyn.Path path;
    case BackendDAE.REAL() then DAE.T_REAL_DEFAULT;
    case BackendDAE.INT() then DAE.T_INTEGER_DEFAULT;
    case BackendDAE.BOOL() then DAE.T_BOOL_DEFAULT;
    case BackendDAE.STRING() then DAE.T_STRING_DEFAULT;
    case BackendDAE.ENUMERATION(strLst) then ((DAE.T_ENUMERATION(NONE(),Absyn.IDENT(""),strLst,{},{}),NONE()));
    case BackendDAE.EXT_OBJECT(path) then ((DAE.T_COMPLEX(ClassInf.EXTERNAL_OBJ(path),{},NONE(),NONE()),NONE()));
  end matchcontinue;
end generateDaeType;

protected function lowerType
"Transforms a DAE.Type to Type
"
  input  DAE.Type inType;
  output BackendDAE.Type outType;
algorithm
  outType := matchcontinue(inType)
    local
      list<String> strLst;
      Absyn.Path path;
    case ((DAE.T_REAL(_),_)) then BackendDAE.REAL();
    case ((DAE.T_INTEGER(_),_)) then BackendDAE.INT();
    case ((DAE.T_BOOL(_),_)) then BackendDAE.BOOL();
    case ((DAE.T_STRING(_),_)) then BackendDAE.STRING();
    case ((DAE.T_ENUMERATION(names = strLst),_)) then BackendDAE.ENUMERATION(strLst);
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path)),_)) then BackendDAE.EXT_OBJECT(path);
  end matchcontinue;
end lowerType;

public function tearingSystem
" function: tearingSystem
  autor: Frenkel TUD
  Pervormes tearing method on a system.
  This is just a funktion to check the flack tearing.
  All other will be done at tearingSystem1."
  input BackendDAE.DAELow inDlow;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<list<Integer>> inComps;
  output BackendDAE.DAELow outDlow;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComps;
  output list<list<Integer>> outResEqn;
  output list<list<Integer>> outTearVar;
algorithm
  (outDlow,outM,outMT,outV1,outV2,outComps,outResEqn,outTearVar):=
  matchcontinue (inDlow,inM,inMT,inV1,inV2,inComps)
    local
      BackendDAE.DAELow dlow,dlow_1,dlow1;
      BackendDAE.IncidenceMatrix m,m_1;
      BackendDAE.IncidenceMatrixT mT,mT_1;
      array<Integer> v1,v2,v1_1,v2_1;
      list<list<Integer>> comps,comps_1;
      list<list<Integer>> r,t;
    case (dlow,m,mT,v1,v2,comps)
      equation
        Debug.fcall("tearingdump", print, "Tearing\n==========\n");
        // get residual eqn and tearing var for each block
        // copy dlow
        dlow1 = copyDaeLowforTearing(dlow);
        (r,t,_,dlow_1,m_1,mT_1,v1_1,v2_1,comps_1) = tearingSystem1(dlow,dlow1,m,mT,v1,v2,comps);
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrix, m_1);
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrixT, mT_1);
        Debug.fcall("tearingdump", BackendDump.dump, dlow_1);
        Debug.fcall("tearingdump", BackendDump.dumpMatching, v1_1);
        Debug.fcall("tearingdump", BackendDump.dumpComponents, comps_1);
        Debug.fcall("tearingdump", print, "==========\n");
        Debug.fcall2("tearingdump", BackendDump.dumpTearing, r,t);
        Debug.fcall("tearingdump", print, "==========\n");
      then
        (dlow_1,m_1,mT_1,v1_1,v2_1,comps_1,r,t);
    case (dlow,m,mT,v1,v2,comps)
      equation
        Debug.fcall("tearingdump", print, "No Tearing\n==========\n");
      then
        (dlow,m,mT,v1,v2,comps,{},{});
  end matchcontinue;
end tearingSystem;

protected function copyDaeLowforTearing
" function: copyDaeLowforTearing
  autor: Frenkel TUD
  Copy the dae to avoid changes in
  vectors."
  input BackendDAE.DAELow inDlow;
  output BackendDAE.DAELow outDlow;
algorithm
  outDlow:=
  matchcontinue (inDlow)
    local
      BackendDAE.Variables ordvars,knvars,exobj,ordvars1;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.Value n,size,n1,size1;
      array<Option<BackendDAE.Equation>> arr_1,arr;
      array<list<BackendDAE.CrefIndex>> crefIdxLstArr,crefIdxLstArr1;
      array<list<BackendDAE.StringIndex>> strIdxLstArr,strIdxLstArr1;
      BackendDAE.VariableArray varArr;
      Integer bucketSize;
      Integer numberOfVars;
      array<Option<BackendDAE.Var>> varOptArr,varOptArr1;
    case (BackendDAE.DAELOW(ordvars,knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc))
      equation
        BackendDAE.VARIABLES(crefIdxLstArr,strIdxLstArr,varArr,bucketSize,numberOfVars) = ordvars;
        BackendDAE.VARIABLE_ARRAY(n1,size1,varOptArr) = varArr;
        crefIdxLstArr1 = arrayCreate(size1, {});
        crefIdxLstArr1 = Util.arrayCopy(crefIdxLstArr, crefIdxLstArr1);
        strIdxLstArr1 = arrayCreate(size1, {});
        strIdxLstArr1 = Util.arrayCopy(strIdxLstArr, strIdxLstArr1);
        varOptArr1 = arrayCreate(size1, NONE());
        varOptArr1 = Util.arrayCopy(varOptArr, varOptArr1);
        ordvars1 = BackendDAE.VARIABLES(crefIdxLstArr1,strIdxLstArr1,BackendDAE.VARIABLE_ARRAY(n1,size1,varOptArr1),bucketSize,numberOfVars);
        BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr) = eqns;
        arr_1 = arrayCreate(size, NONE());
        arr_1 = Util.arrayCopy(arr, arr_1);
        eqns1 = BackendDAE.EQUATION_ARRAY(n,size,arr_1);
      then
        BackendDAE.DAELOW(ordvars1,knvars,exobj,av,eqns1,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
  end matchcontinue;
end copyDaeLowforTearing;

protected function tearingSystem1
" function: tearingSystem1
  autor: Frenkel TUD
  Main loop. Check all Comps and start tearing if
  strong connected components there"
  input BackendDAE.DAELow inDlow;
  input BackendDAE.DAELow inDlow1;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<list<Integer>> inComps;
  output list<list<Integer>> outResEqn;
  output list<list<Integer>> outTearVar;
  output BackendDAE.DAELow outDlow;
  output BackendDAE.DAELow outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComps;
algorithm
  (outResEqn,outTearVar,outDlow,outDlow1,outM,outMT,outV1,outV2,outComps):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComps)
    local
      BackendDAE.DAELow dlow,dlow_1,dlow_2,dlow1,dlow1_1,dlow1_2;
      BackendDAE.IncidenceMatrix m,m_1,m_2,m_3,m_4;
      BackendDAE.IncidenceMatrixT mT,mT_1,mT_2,mT_3,mT_4;
      array<Integer> v1,v2,v1_1,v2_1,v1_2,v2_2,v1_3,v2_3;
      list<list<Integer>> comps,comps_1;
      list<Integer> tvars,comp,comp_1,tearingvars,residualeqns,tearingeqns,l2,l2_1;
      list<list<Integer>> r,t;
      Integer ll;
      list<DAE.ComponentRef> crlst;
    case (dlow,dlow1,m,mT,v1,v2,{})
      then
        ({},{},dlow,dlow1,m,mT,v1,v2,{});
    case (dlow,dlow1,m,mT,v1,v2,comp::comps)
      equation
        // block ?
        ll = listLength(comp);
        true = ll > 1;
        // get all interesting vars
        (tvars,crlst) = getTearingVars(m,v1,v2,comp,dlow);
        // try tearing
        (residualeqns,tearingvars,tearingeqns,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem2(dlow,dlow1,m,mT,v1,v2,comp,tvars,{},{},{},{},crlst);
        // clean v1,v2,m,mT
        v2_2 = arrayCreate(ll, 0);
        v2_2 = Util.arrayNCopy(v2_1, v2_2,ll);
        v1_2 = arrayCreate(ll, 0);
        v1_2 = Util.arrayNCopy(v1_1, v1_2,ll);
        m_3 = incidenceMatrix(dlow1_1);
        mT_3 = transposeMatrix(m_3);
        (v1_3,v2_3) = correctAssignments(v1_2,v2_2,residualeqns,tearingvars);
        // next Block
        (r,t,dlow_2,dlow1_2,m_4,mT_4,v1_3,v2_3,comps_1) = tearingSystem1(dlow_1,dlow1_1,m_3,mT_3,v1_2,v2_2,comps);
      then
        (residualeqns::r,tearingvars::t,dlow_2,dlow1_2,m_4,mT_4,v1_3,v2_3,comp_1::comps_1);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps)
      equation
        // block ?
        ll = listLength(comp);
        false = ll > 1;
        // next Block
        (r,t,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comps_1) = tearingSystem1(dlow,dlow1,m,mT,v1,v2,comps);
      then
        ({0}::r,{0}::t,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp::comps_1);
  end matchcontinue;
end tearingSystem1;

protected function correctAssignments
" function: correctAssignments
  Correct the assignments"
  input array<BackendDAE.Value> inV1;
  input array<BackendDAE.Value> inV2;
  input list<Integer> inRLst;
  input list<Integer> inTLst;
  output array<BackendDAE.Value> outV1;
  output array<BackendDAE.Value> outV2;
algorithm
  (outV1,outV2):=
  matchcontinue (inV1,inV2,inRLst,inTLst)
    local
      array<BackendDAE.Value> v1,v2,v1_1,v2_1,v1_2,v2_2;
      list<BackendDAE.Value> comp;
      list<Integer> rlst,tlst;
      Integer r,t;
    case (v1,v2,{},{}) then (v1,v2);
    case (v1,v2,r::rlst,t::tlst)
      equation
         v1_1 = arrayUpdate(v1,t,r);
         v2_1 = arrayUpdate(v2,r,t);
         (v1_2,v2_2) = correctAssignments(v1_1,v2_1,rlst,tlst);
      then
        (v1_2,v2_2);
  end matchcontinue;
end correctAssignments;

protected function getTearingVars
" function: getTearingVars
  Substracts all interesting vars for tearing"
  input BackendDAE.IncidenceMatrix inM;
  input array<BackendDAE.Value> inV1;
  input array<BackendDAE.Value> inV2;
  input list<BackendDAE.Value> inComp;
  input BackendDAE.DAELow inDlow;
  output list<BackendDAE.Value> outVarLst;
  output list<DAE.ComponentRef> outCrLst;
algorithm
  (outVarLst,outCrLst):=
  matchcontinue (inM,inV1,inV2,inComp,inDlow)
    local
      BackendDAE.IncidenceMatrix m;
      array<BackendDAE.Value> v1,v2;
      BackendDAE.Value c,v;
      list<BackendDAE.Value> comp,varlst;
      BackendDAE.DAELow dlow;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      BackendDAE.Variables ordvars;
      BackendDAE.VariableArray varr;
    case (m,v1,v2,{},dlow) then ({},{});
    case (m,v1,v2,c::comp,dlow as BackendDAE.DAELOW(orderedVars = ordvars as BackendDAE.VARIABLES(varArr=varr)))
      equation
        v = v2[c];
        BackendDAE.VAR(varName = cr) = vararrayNth(varr, v-1);
        (varlst,crlst) = getTearingVars(m,v1,v2,comp,dlow);
      then
        (v::varlst,cr::crlst);
  end matchcontinue;
end getTearingVars;

protected function tearingSystem2
" function: tearingSystem2
  Residualequation loop. This function
  select a residual equation.
  The equation with most connections to
  variables will be selected."
  input BackendDAE.DAELow inDlow;
  input BackendDAE.DAELow inDlow1;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<Integer> inComp;
  input list<Integer> inTVars;
  input list<Integer> inExclude;
  input list<Integer> inResEqns;
  input list<Integer> inTearVars;
  input list<Integer> inTearEqns;
  input list<DAE.ComponentRef> inCrlst;
  output list<Integer> outResEqns;
  output list<Integer> outTearVars;
  output list<Integer> outTearEqns;
  output BackendDAE.DAELow outDlow;
  output BackendDAE.DAELow outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<Integer> outComp;
algorithm
  (outResEqns,outTearVars,outTearEqns,outDlow,outDlow1,outM,outMT,outV1,outV2,outComp):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComp,inTVars,inExclude,inResEqns,inTearVars,inTearEqns,inCrlst)
    local
      BackendDAE.DAELow dlow,dlow_1,dlow1,dlow1_1;
      BackendDAE.IncidenceMatrix m,m_1;
      BackendDAE.IncidenceMatrixT mT,mT_1;
      array<Integer> v1,v2,v1_1,v2_1;
      list<Integer> tvars,vars,vars_1,comp,comp_1,exclude;
      String str,str1;
      Integer residualeqn;
      list<Integer> tearingvars,residualeqns,tearingvars_1,residualeqns_1,tearingeqns,tearingeqns_1;
      list<DAE.ComponentRef> crlst;
    case (dlow,dlow1,m,mT,v1,v2,comp,tvars,exclude,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        // get from eqn equation with most variables
        (residualeqn,_) = getMaxfromListList(m,comp,tvars,0,0,exclude);
        true = residualeqn > 0;
        str = intString(residualeqn);
        str1 = stringAppend("ResidualEqn: ", str);
        Debug.fcall("tearingdump", print, str1);
         // get from mT variable with most equations
        vars = m[residualeqn];
        vars_1 = Util.listSelect1(vars,tvars,Util.listContains);
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem3(dlow,dlow1,m,mT,v1,v2,comp,vars_1,{},residualeqn,residualeqns,tearingvars,tearingeqns,crlst);
        // only succeed if tearing need less equations than system size is
//        true = listLength(tearingvars_1) < systemsize;
    then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1);
    case (dlow,dlow1,m,mT,v1,v2,comp,tvars,exclude,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        // get from eqn equation with most variables
        (residualeqn,_) = getMaxfromListList(m,comp,tvars,0,0,exclude);
        true = residualeqn > 0;
        // try next equation
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem2(dlow,dlow1,m,mT,v1,v2,comp,tvars,residualeqn::exclude,residualeqns,tearingvars,tearingeqns,crlst);
      then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1);
    case (dlow,dlow1,m,mT,v1,v2,comp,tvars,exclude,residualeqns,tearingvars,tearingeqns,_)
      equation
        // get from eqn equation with most variables
        (residualeqn,_) = getMaxfromListList(m,comp,tvars,0,0,exclude);
        false = residualeqn > 0;
        Debug.fcall("tearingdump", print, "Select Residual BackendDAE.Equation failed\n");
      then
        fail();
  end matchcontinue;
end tearingSystem2;

protected function tearingSystem3
" function: tearingSystem3
  TearingVar loop. This function select
  a tearing variable. The variable with
  most connections to equations will be
  selected."
  input BackendDAE.DAELow inDlow;
  input BackendDAE.DAELow inDlow1;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<Integer> inComp;
  input list<Integer> inTVars;
  input list<Integer> inExclude;
  input Integer inResEqn;
  input list<Integer> inResEqns;
  input list<Integer> inTearVars;
  input list<Integer> inTearEqns;
  input list<DAE.ComponentRef> inCrlst;
  output list<Integer> outResEqns;
  output list<Integer> outTearVars;
  output list<Integer> outTearEqns;
  output BackendDAE.DAELow outDlow;
  output BackendDAE.DAELow outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<Integer> outComp;
algorithm
  (outResEqns,outTearVars,outTearEqns,outDlow,outDlow1,outM,outMT,outV1,outV2,outComp):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComp,inTVars,inExclude,inResEqn,inResEqns,inTearVars,inTearEqns,inCrlst)
    local
      BackendDAE.DAELow dlow,dlow_1,dlow_2,dlow_3,dlow1,dlow1_1,dlow1,dlow1_1,dlow1_2,dlowc,dlowc1;
      BackendDAE.IncidenceMatrix m,m_1,m_2,m_3;
      BackendDAE.IncidenceMatrixT mT,mT_1,mT_2,mT_3;
      array<Integer> v1,v2,v1_1,v2_1,v1_2,v2_2;
      list<list<Integer>> comps,comps_1,lstm,lstmp,onecomp,morecomps;
      list<Integer> vars,comp,comp_1,comp_2,r,t,exclude,b,cmops_flat,onecomp_flat,othereqns,resteareqns;
      String str,str1,str2;
      Integer tearingvar,residualeqn,compcount,tearingeqnid;
      list<Integer> residualeqns,residualeqns_1,tearingvars,tearingvars_1,tearingeqns,tearingeqns_1,tearingeqns_2;
      DAE.ComponentRef cr,crt;
      list<DAE.ComponentRef> crlst;
      DAE.Ident ident,ident_t;
      BackendDAE.VariableArray varr;
      BackendDAE.Value nvars,neqns,memsize;
      BackendDAE.Variables ordvars,vars_1,knvars,exobj,ordvars1;
      BackendDAE.AliasVariables av;
      BackendDAE.Assignments assign1,assign2,assign1_1,assign2_1,ass1,ass2;
      BackendDAE.EquationArray eqns, eqns_1, eqns_2,removedEqs,remeqns,inieqns,eqns1,eqns1_1,eqns1_2;
      array<BackendDAE.MultiDimEquation> arreqns;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      DAE.Exp eqn,eqn_1,scalar,scalar_1;
      DAE.ElementSource source;
      DAE.ExpType identType;
      list<DAE.Subscript> subscriptLst;
      Integer replace,replace1;
    case (dlow,dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        (tearingvar,_) = getMaxfromListList(mT,vars,comp,0,0,exclude);
        // check if tearing var is found
        true = tearingvar > 0;
        str = intString(tearingvar);
        str1 = stringAppend("\nTearingVar: ", str);
        str2 = stringAppend(str1,"\n");
        Debug.fcall("tearingdump", print, str2);
        // copy dlow
        dlowc = copyDaeLowforTearing(dlow);
        BackendDAE.DAELOW(ordvars as BackendDAE.VARIABLES(varArr=varr),knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc) = dlowc;
        dlowc1 = copyDaeLowforTearing(dlow1);
        BackendDAE.DAELOW(orderedVars = ordvars1,orderedEqs = eqns1) = dlowc1;
        // add Tearing Var
        BackendDAE.VAR(varName = cr as DAE.CREF_IDENT(ident = ident, identType = identType, subscriptLst = subscriptLst )) = vararrayNth(varr, tearingvar-1);
        ident_t = stringAppend("tearingresidual_",ident);
        crt = ComponentReference.makeCrefIdent(ident_t,identType,subscriptLst);
         vars_1 = addVar(BackendDAE.VAR(crt, BackendDAE.VARIABLE(),DAE.BIDIR(),BackendDAE.REAL(),NONE(),NONE(),{},-1,DAE.emptyElementSource,
                            SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(true)),NONE(),NONE(),NONE(),NONE(),NONE())),
                            NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM()), ordvars);
        // replace in residual equation orgvar with Tearing Var
        BackendDAE.EQUATION(eqn,scalar,source) = equationNth(eqns,residualeqn-1);
//        (eqn_1,replace) =  Exp.replaceExp(eqn,DAE.CREF(cr,DAE.ET_REAL()),DAE.CREF(crt,DAE.ET_REAL()));
//        (scalar_1,replace1) =  Exp.replaceExp(scalar,DAE.CREF(cr,DAE.ET_REAL()),DAE.CREF(crt,DAE.ET_REAL()));
//        true = replace + replace1 > 0;
        // Add Residual eqn
        eqns_1 = equationSetnth(eqns,residualeqn-1,BackendDAE.EQUATION(DAE.BINARY(eqn,DAE.SUB(DAE.ET_REAL()),scalar),DAE.CREF(crt,DAE.ET_REAL()),source));
        eqns1_1 = equationSetnth(eqns1,residualeqn-1,BackendDAE.EQUATION(DAE.BINARY(eqn,DAE.SUB(DAE.ET_REAL()),scalar),DAE.RCONST(0.0),source));
        // add equation to calc org var
        eqns_2 = equationAdd(eqns_1,BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("tearing"),
                          {},false,true,DAE.ET_REAL(),DAE.NO_INLINE()),
                          DAE.CREF(cr,DAE.ET_REAL()), DAE.emptyElementSource));
        tearingeqnid = equationSize(eqns_2);
        dlow_1 = BackendDAE.DAELOW(vars_1,knvars,exobj,av,eqns_2,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
        dlow1_1 = BackendDAE.DAELOW(ordvars1,knvars,exobj,av,eqns1_1,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
        // try causalisation
        m_1 = incidenceMatrix(dlow_1);
        mT_1 = transposeMatrix(m_1);
        nvars = arrayLength(m_1);
        neqns = arrayLength(mT_1);
        memsize = nvars + nvars "Worst case, all eqns are differentiated once. Create nvars2 assignment elements" ;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        // try matching
        checkMatching(dlow_1, (BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.KEEP_SIMPLE_EQN()));
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrix, m_1);
        Debug.fcall("tearingdump", BackendDump.dumpIncidenceMatrixT, mT_1);
        Debug.fcall("tearingdump", BackendDump.dump, dlow_1);
        (ass1,ass2,dlow_2,m_2,mT_2,_,_) = matchingAlgorithm2(dlow_1, m_1, mT_1, nvars, neqns, 1, assign1, assign2, (BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.KEEP_SIMPLE_EQN()),DAEUtil.avlTreeNew(),{},{});
        v1_1 = assignmentsVector(ass1);
        v2_1 = assignmentsVector(ass2);
        (comps) = strongComponents(m_2, mT_2, v1_1, v2_1);
        Debug.fcall("tearingdump", BackendDump.dumpMatching, v1_1);
        Debug.fcall("tearingdump", BackendDump.dumpComponents, comps);
        // check strongComponents and split it into two lists: len(comp)==1 and len(comp)>1
        (morecomps,onecomp) = splitComps(comps);
        // try to solve the equations
        onecomp_flat = Util.listFlatten(onecomp);
        // remove residual equations and tearing eqns
        resteareqns = listAppend(tearingeqnid::tearingeqns,residualeqn::residualeqns);
        othereqns = Util.listSelect1(onecomp_flat,resteareqns,Util.listNotContains);
        eqns1_2 = solveEquations(eqns1_1,othereqns,v2_1,vars_1,crlst);
         // if we have not make alle equations causal select next residual equation
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_3,dlow1_2,m_3,mT_3,v1_2,v2_2,comps_1,compcount) = tearingSystem4(dlow_2,dlow1_1,m_2,mT_2,v1_1,v2_1,comps,residualeqn::residualeqns,tearingvar::tearingvars,tearingeqnid::tearingeqns,comp,0,crlst);
        // check
        true = ((listLength(residualeqns_1) > listLength(residualeqns)) and
                (listLength(tearingvars_1) > listLength(tearingvars)) ) or (compcount == 0);
        // get specifig comps
        cmops_flat = Util.listFlatten(comps_1);
        comp_2 = Util.listSelect1(cmops_flat,comp,Util.listContains);
      then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_3,dlow1_2,m_3,mT_3,v1_2,v2_2,comp_2);
    case (dlow as BackendDAE.DAELOW(orderedVars = BackendDAE.VARIABLES(varArr=varr)),dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        (tearingvar,_) = getMaxfromListList(mT,vars,comp,0,0,exclude);
        // check if tearing var is found
        true = tearingvar > 0;
        // clear errors
        Error.clearMessages();
        // try next TearingVar
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem3(dlow,dlow1,m,mT,v1,v2,comp,vars,tearingvar::exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst);
      then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1);
    case (dlow as BackendDAE.DAELOW(orderedVars = BackendDAE.VARIABLES(varArr=varr)),dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,_)
      equation
        (tearingvar,_) = getMaxfromListList(mT,vars,comp,0,0,exclude);
        // check if tearing var is found
        false = tearingvar > 0;
        // clear errors
        Error.clearMessages();
        Debug.fcall("tearingdump", print, "Select Tearing BackendDAE.Var failed\n");
      then
        fail();
  end matchcontinue;
end tearingSystem3;

protected function tearingSystem4
" function: tearingSystem4
  autor: Frenkel TUD
  Internal Main loop for additional
  tearing vars and residual eqns."
  input BackendDAE.DAELow inDlow;
  input BackendDAE.DAELow inDlow1;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<Integer> inV1;
  input array<Integer> inV2;
  input list<list<Integer>> inComps;
  input list<Integer> inResEqns;
  input list<Integer> inTearVars;
  input list<Integer> inTearEqns;
  input list<Integer> inComp;
  input Integer inCompCount;
  input list<DAE.ComponentRef> inCrlst;
  output list<Integer> outResEqns;
  output list<Integer> outTearVars;
  output list<Integer> outTearEqns;
  output BackendDAE.DAELow outDlow;
  output BackendDAE.DAELow outDlow1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComp;
  output Integer outCompCount;
algorithm
  (outResEqns,outTearVars,outTearEqns,outDlow,outDlow1,outM,outMT,outV1,outV2,outComp,outCompCount):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComps,inResEqns,inTearVars,inTearEqns,inComp,inCompCount,inCrlst)
    local
      BackendDAE.DAELow dlow,dlow_1,dlow_2,dlow1,dlow1_1,dlow1_2;
      BackendDAE.IncidenceMatrix m,m_1,m_2;
      BackendDAE.IncidenceMatrixT mT,mT_1,mT_2;
      array<Integer> v1,v2,v1_1,v2_1,v1_2,v2_2;
      list<list<Integer>> comps,comps_1;
      list<Integer> tvars,comp,comp_1,tearingvars,residualeqns,ccomp,r,t,r_1,t_1,te,te_1,tearingeqns;
      Integer ll,compcount,compcount_1,compcount_2;
      list<Boolean> checklst;
      list<DAE.ComponentRef> crlst;
    case (dlow,dlow1,m,mT,v1,v2,{},r,t,te,ccomp,compcount,crlst)
      then
        (r,t,te,dlow,dlow1,m,mT,v1,v2,{},compcount);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps,r,t,te,ccomp,compcount,crlst)
      equation
        // block ?
        ll = listLength(comp);
        true = ll > 1;
        // check block
        checklst = Util.listMap1(comp,Util.listContains,ccomp);
        true = Util.listContains(true,checklst);
        // this is a block
        compcount_1 = compcount + 1;
        // get all interesting vars
        (tvars,_) = getTearingVars(m,v1,v2,comp,dlow);
        // try tearing
        (residualeqns,tearingvars,tearingeqns,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem2(dlow,dlow1,m,mT,v1,v2,comp,tvars,{},r,t,te,crlst);
        // next Block
        (r_1,t_1,te_1,dlow_2,dlow1_2,m_2,mT_2,v1_2,v2_2,comps_1,compcount_2) = tearingSystem4(dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comps,residualeqns,tearingvars,tearingeqns,ccomp,compcount_1,crlst);
      then
        (r_1,t_1,te_1,dlow_2,dlow1_2,m_2,mT_2,v1_2,v2_2,comp_1::comps_1,compcount_2);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps,r,t,te,ccomp,compcount,crlst)
      equation
        // block ?
        ll = listLength(comp);
        true = ll > 1;
        // check block
        checklst = Util.listMap1(comp,Util.listContains,ccomp);
        true = Util.listContains(true,checklst);
        // this is a block
        compcount_1 = compcount + 1;
        // next Block
        (r_1,t_1,tearingeqns,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comps_1,compcount_2) = tearingSystem4(dlow,dlow1,m,mT,v1,v2,comps,r,t,te,ccomp,compcount_1,crlst);
      then
        (r_1,t_1,tearingeqns,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comp::comps_1,compcount_2);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps,r,t,te,ccomp,compcount,crlst)
      equation
        // next Block
        (r_1,t_1,te_1,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comps_1,compcount_1) = tearingSystem4(dlow,dlow1,m,mT,v1,v2,comps,r,t,te,ccomp,compcount,crlst);
      then
        (r_1,t_1,te_1,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comp::comps_1,compcount_1);
  end matchcontinue;
end tearingSystem4;

protected function getMaxfromListList
" function: getMaxfromArrayList
  helper for tearingSystem2 and tearingSystem3
  This function select the equation/variable
  with most connections to variables/equations.
  If more than once is there the first will
  be selected."
  input BackendDAE.IncidenceMatrixT inM;
  input list<BackendDAE.Value> inLst;
  input list<BackendDAE.Value> inComp;
  input BackendDAE.Value inMax;
  input BackendDAE.Value inEqn;
  input list<BackendDAE.Value> inExclude;
  output BackendDAE.Value outEqn;
  output BackendDAE.Value outMax;
algorithm
  (outEqn,outMax):=
  matchcontinue (inM,inLst,inComp,inMax,inEqn,inExclude)
    local
      BackendDAE.IncidenceMatrixT m;
      list<BackendDAE.Value> rest,eqn,eqn_1,eqn_2,eqn_3,comp,exclude;
      BackendDAE.Value v,v1,v2,max,max_1,en,en_1,en_2;
    case (m,{},comp,max,en,exclude) then (en,max);
    case (m,v::rest,comp,max,en,exclude)
      equation
        (en_1,max_1) = getMaxfromListList(m,rest,comp,max,en,exclude);
        true = v > 0;
        false = Util.listContains(v,exclude);
        eqn = m[v];
        // remove negative
        eqn_1 = removeNegative(eqn);
        // select entries
        eqn_2 = Util.listSelect1(eqn_1,comp,Util.listContains);
        // remove multiple entries
        eqn_3 = removeMultiple(eqn_2);
        v1 = listLength(eqn_3);
        v2 = intMax(v1,max_1);
        en_2 = Util.if_(v1>max_1,v,en_1);
      then
        (en_2,v2);
    case (m,v::rest,comp,max,en,exclude)
      equation
        (en_2,v2) = getMaxfromListList(m,rest,comp,max,en,exclude);
      then
        (en_2,v2);
  end matchcontinue;
end getMaxfromListList;

protected function removeMultiple
" function: removeMultiple
  remove mulitple entries from the list"
  input list<BackendDAE.Value> inLst;
  output list<BackendDAE.Value> outLst;
algorithm
  outLst:=
  matchcontinue (inLst)
    local
      list<BackendDAE.Value> rest,lst;
      BackendDAE.Value v;
    case ({}) then {};
    case (v::{})
      then
        {v};
    case (v::rest)
      equation
        lst = removeMultiple(rest);
        false = Util.listContains(v,lst);
      then
        (v::lst);
    case (v::rest)
      equation
        lst = removeMultiple(rest);
        true = Util.listContains(v,lst);
      then
        lst;
  end matchcontinue;
end removeMultiple;

protected function splitComps
" function: splitComps
  splits the comp in two list
  1: len(comp) == 1
  2: len(comp) > 1"
  input list<list<Integer>> inComps;
  output list<list<Integer>> outComps;
  output list<list<Integer>> outComps1;
algorithm
  (outComps,outComps1):=
  matchcontinue (inComps)
    local
      list<list<Integer>> rest,comps,comps1;
      list<Integer> comp;
      Integer v;
    case ({}) then ({},{});
    case ({v}::rest)
      equation
        (comps,comps1) = splitComps(rest);
      then
        (comps,{v}::comps1);
    case (comp::rest)
      equation
        (comps,comps1) = splitComps(rest);
      then
        (comp::comps,comps1);
  end matchcontinue;
end splitComps;

protected function solveEquations
" function: solveEquations
  try to solve the equations"
  input BackendDAE.EquationArray inEqnArray;
  input list<Integer> inEqns;
  input array<Integer> inAssigments;
  input BackendDAE.Variables inVars;
  input list<DAE.ComponentRef> inCrlst;
  output BackendDAE.EquationArray outEqnArray;
algorithm
  outEqnArray:=
  matchcontinue (inEqnArray,inEqns,inAssigments,inVars,inCrlst)
    local
      BackendDAE.EquationArray eqns,eqns_1,eqns_2;
      list<Integer> rest;
      Integer e,e_1,v,v_1;
      array<Integer> ass;
      BackendDAE.Variables vars;
      DAE.Exp e1,e2,varexp,expr;
      list<DAE.Exp> divexplst,constexplst,nonconstexplst,tfixedexplst,tnofixedexplst;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      list<list<DAE.ComponentRef>> crlstlst;
      DAE.ElementSource source;
      BackendDAE.VariableArray varr;
      list<Boolean> blst,blst_1;
      list<list<Boolean>> blstlst;
      list<String> s;
    case (eqns,{},ass,vars,crlst) then eqns;
    case (eqns,e::rest,ass,vars as BackendDAE.VARIABLES(varArr=varr),crlst)
      equation
        e_1 = e - 1;
        BackendDAE.EQUATION(e1,e2,source) = equationNth(eqns, e_1);
        v = ass[e_1 + 1];
        v_1 = v - 1;
        BackendDAE.VAR(varName=cr) = vararrayNth(varr, v_1);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        expr = Exp.solve(e1, e2, varexp);
        divexplst = Exp.extractDivExpFromExp(expr);
        (constexplst,nonconstexplst) = Util.listSplitOnTrue(divexplst,Exp.isConst);
        // check constexplst if equal 0
        blst = Util.listMap(constexplst, Exp.isZero);
        false = Util.boolOrList(blst);
        // check nonconstexplst if tearing variables or variables which will be
        // changed during solving process inside
        crlstlst = Util.listMap(nonconstexplst,Exp.extractCrefsFromExp);
        // add explst with variables which will not be changed during solving prozess
        blstlst = Util.listListMap2(crlstlst,Util.listContainsWithCompareFunc,crlst,ComponentReference.crefEqualNoStringCompare);
        blst_1 = Util.listMap(blstlst,Util.boolOrList);
        (tnofixedexplst,tfixedexplst) = listSplitOnTrue(nonconstexplst,blst_1);
        true = listLength(tnofixedexplst) < 1;
/*        print("\ntfixedexplst DivExpLst:\n");
        s = Util.listMap(tfixedexplst, Exp.printExpStr);
        Util.listMap0(s,print);
        print("\n===============================\n");
        print("\ntnofixedexplst DivExpLst:\n");
        s = Util.listMap(tnofixedexplst, Exp.printExpStr);
        Util.listMap0(s,print);
        print("\n===============================\n");
*/        eqns_1 = equationSetnth(eqns,e_1,BackendDAE.EQUATION(expr,varexp,source));
        eqns_2 = solveEquations(eqns_1,rest,ass,vars,crlst);
      then
        eqns_2;
  end matchcontinue;
end solveEquations;

public function listSplitOnTrue "Splits a list into two sublists depending on second list of bools"
  input list<Type_a> lst;
  input list<Boolean> blst;
  output list<Type_a> tlst;
  output list<Type_a> flst;
  replaceable type Type_a subtypeof Any;
algorithm
  (tlst,flst) := matchcontinue(lst,blst)
  local Type_a l;
    case({},{}) then ({},{});
    case(l::lst,true::blst) equation
      (tlst,flst) = listSplitOnTrue(lst,blst);
    then (l::tlst,flst);
    case(l::lst,false::blst) equation
      (tlst,flst) = listSplitOnTrue(lst,blst);
    then (tlst,l::flst);
  end matchcontinue;
end listSplitOnTrue;

protected function transformDelayExpression
"Insert a unique index into the arguments of a delay() expression.
Repeat delay as maxDelay if not present."
  input tuple<DAE.Exp, Integer> inTuple;
  output tuple<DAE.Exp, Integer> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e, e1, e2, e3;
      Integer i;
      list<DAE.Exp> l;
      Boolean t, b;
      DAE.ExpType ty;
      DAE.InlineType it;
    case ((DAE.CALL(Absyn.IDENT("delay"), {e1, e2}, t, b, ty, it), i))
      then ((DAE.CALL(Absyn.IDENT("delay"), {DAE.ICONST(i), e1, e2, e2}, t, b, ty, it), i + 1));
    case ((DAE.CALL(Absyn.IDENT("delay"), {e1, e2, e3}, t, b, ty, it), i))
      then ((DAE.CALL(Absyn.IDENT("delay"), {DAE.ICONST(i), e1, e2, e3}, t, b, ty, it), i + 1));
    case ((e, i)) then ((e, i));
  end matchcontinue;
end transformDelayExpression;

protected function transformDelayExpressions
"Helper for processDelayExpressions()"
  input DAE.Exp inExp;
  input Integer inInteger;
  output DAE.Exp outExp;
  output Integer outInteger;
algorithm
  ((outExp, outInteger)) := Exp.traverseExp(inExp, transformDelayExpression, inInteger);
end transformDelayExpressions;

public function processDelayExpressions
"Assign each call to delay() with a unique id argument"
  input DAE.DAElist inDAE;
  input DAE.FunctionTree functionTree;
  output DAE.DAElist outDAE;
  output DAE.FunctionTree outTree;
algorithm
  (outDAE,outTree) := matchcontinue(inDAE,functionTree)
    local
      DAE.DAElist dae, dae2;
    case (dae,functionTree)
      equation
        (dae,functionTree,_) = DAEUtil.traverseDAE(dae, functionTree, transformDelayExpressions, 0);
      then
        (dae,functionTree);
  end matchcontinue;
end processDelayExpressions;

protected function collectDelayExpressions
"Put expression into a list if it is a call to delay().
Useable as a function parameter for Exp.traverseExp."
  input tuple<DAE.Exp, list<DAE.Exp>> inTuple;
  output tuple<DAE.Exp, list<DAE.Exp>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      list<DAE.Exp> l;
    case ((e as DAE.CALL(path = Absyn.IDENT("delay")), l))
      then ((e, e :: l));
    case ((e, l)) then ((e, l));
  end matchcontinue;
end collectDelayExpressions;

public function findDelaySubExpressions
"Return all subexpressions of inExp that are calls to delay()"
  input DAE.Exp inExp;
  input list<Integer> inDummy "this is a dummy for traverseDEALowExps";
  output list<DAE.Exp> outExps;
algorithm
  ((_, outExps)) := Exp.traverseExp(inExp, collectDelayExpressions, {});
end findDelaySubExpressions;

public function addDivExpErrorMsgtoExp "
Author: Frenkel TUD 2010-02, Adds the error msg to Exp.Div.
"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace> inDlowMode;
  output DAE.Exp outExp;
  output list<DAE.Exp> outDivLst;
algorithm 
  (outExp,outDivLst) := matchcontinue(inExp,inDlowMode)
  case(inExp,inDlowMode as (vars,varlst,dzer))
    local 
      DAE.Exp exp; 
      BackendDAE.DAELow dlow;
      BackendDAE.DivZeroExpReplace dzer;
      list<DAE.Exp> divlst;
      BackendDAE.Variables vars;
      list<BackendDAE.Var> varlst;
    equation
      ((exp,(_,_,_,divlst))) = Exp.traverseExp(inExp, traversingDivExpFinder, (vars,varlst,dzer,{}));
      then
        (exp,divlst);
  end matchcontinue;
end addDivExpErrorMsgtoExp;

protected function traversingDivExpFinder "
Author: Frenkel TUD 2010-02"
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace,list<DAE.Exp>> > inExp;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace,list<DAE.Exp>> > outExp;
algorithm
outExp := matchcontinue(inExp)
  local
    BackendDAE.Variables vars;
    list<BackendDAE.Var> varlst;
    BackendDAE.DivZeroExpReplace dzer;
    list<DAE.Exp> divLst;
    tuple<BackendDAE.Variables,BackendDAE.DivZeroExpReplace,list<DAE.Exp>> dlowmode;
    DAE.Exp e,e1,e2;
    Exp.Type ty;
    String se;
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV(ty),exp2 = e2),(vars,varlst,dzer,divLst)))
    equation
      (se,true) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
    then ((DAE.CALL(Absyn.IDENT("DIVISION"), {e1,e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE()), (vars,varlst,dzer,divLst) ));
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
    equation
      (se,false) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
    then ((e, (vars,varlst,dzer,DAE.CALL(Absyn.IDENT("DIVISION"), {DAE.RCONST(1.0),e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE())::divLst) ));
/*
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARR(ty),exp2 = e2), dlowmode as (dlow,_)))
    then ((e, dlowmode ));
*/    
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARRAY_SCALAR(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
    equation
      (se,true) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
    then ((DAE.CALL(Absyn.IDENT("DIVISION_ARRAY_SCALAR"), {e1,e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE()), (vars,varlst,dzer,divLst) ));
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARRAY_SCALAR(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
    equation
      (se,false) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
    then ((e, (vars,varlst,dzer,DAE.CALL(Absyn.IDENT("DIVISION_ARRAY_SCALAR"), {DAE.RCONST(1.0),e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE())::divLst) ));
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_SCALAR_ARRAY(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
    equation
      (se,true) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
    then ((DAE.CALL(Absyn.IDENT("DIVISION_SCALAR_ARRAY"), {e1,e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE()), (vars,varlst,dzer,divLst) ));
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_SCALAR_ARRAY(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
    equation
      (se,false) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
    then ((e, (vars,varlst,dzer,DAE.CALL(Absyn.IDENT("DIVISION_SCALAR_ARRAY"), {DAE.RCONST(1.0),e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE())::divLst) ));
  case(inExp) then (inExp);
end matchcontinue;
end traversingDivExpFinder;

protected function traversingDivExpFinder1 "
Author: Frenkel TUD 2010-02 
  helper for traversingDivExpFinder"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace> inMode;
  output String outString;
  output Boolean outBool;
algorithm
  (outString,outBool) := matchcontinue(inExp1,inExp2,inMode)
  local
    BackendDAE.Variables vars;
    DAE.Exp e,e2;
    String se;
    list<DAE.ComponentRef> crlst;
    BackendDAE.Variables vars;
    list<BackendDAE.Var> varlst;
    list<Boolean> boollst;
    Boolean bres;
  case( e , e2, (vars,varlst,BackendDAE.ALL()) )
    equation
      /* generade modelica strings */
      se = generadeDivExpErrorMsg(e,e2,vars);
    then (se,false);    
  case( e , e2, (vars,varlst,BackendDAE.ONLY_VARIABLES()) )
    equation
      /* generade modelica strings */
      se = generadeDivExpErrorMsg(e,e2,vars);
      /* check if expression contains variables */
      crlst = Exp.extractCrefsFromExp(e2);
      boollst = Util.listMap1r(crlst,isVarKnown,varlst);
      bres = Util.boolOrList(boollst);
    then (se,bres);
end matchcontinue;
end traversingDivExpFinder1;

protected  function generadeDivExpErrorMsg "
Author: Frenkel TUD 2010-02. varOrigCref
"
input DAE.Exp inExp;
input DAE.Exp inDivisor;
input BackendDAE.Variables inVars;
output String outString;
protected String se,se2,s,s1;
algorithm
  se := Exp.printExp2Str(inExp,"\"",SOME((BackendDump.printComponentRefStrDIVISION,inVars)), SOME(BackendDump.printCallFunction2StrDIVISION));
  se2 := Exp.printExp2Str(inDivisor,"\"",SOME((BackendDump.printComponentRefStrDIVISION,inVars)), SOME(BackendDump.printCallFunction2StrDIVISION));
  s := stringAppend(se," because ");
  s1 := stringAppend(s,se2);
  outString := stringAppend(s1," == 0");
end generadeDivExpErrorMsg;

protected function extendRecordEqns "
Author: Frenkel TUD 2010-05"
  input BackendDAE.Equation inEqn;
  input DAE.FunctionTree inFuncs;
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.MultiDimEquation>> outTuplEqnLst;
algorithm 
  outTuplEqnLst := matchcontinue(inEqn,inFuncs)
  local
    DAE.FunctionTree funcs;
    BackendDAE.Equation eqn;
    DAE.ComponentRef cr1,cr2;
    DAE.Exp e1,e2;
    list<DAE.Exp> e1lst,e2lst;
    list<DAE.ExpVar> varLst;
    Integer i;
    list<tuple<list<BackendDAE.Equation>,list<BackendDAE.MultiDimEquation>>> compmultilistlst,compmultilistlst1;
    list<list<BackendDAE.MultiDimEquation>> multiEqsLst,multiEqsLst1;
    list<list<BackendDAE.Equation>> complexEqsLst,complexEqsLst1;
    list<BackendDAE.MultiDimEquation> multiEqs,multiEqs1,multiEqs2;  
    list<BackendDAE.Equation> complexEqs,complexEqs1;  
    DAE.ElementSource source;  
    Absyn.Path path,fname;
    list<DAE.Exp> expLst;
    list<tuple<DAE.Exp,DAE.Exp>> exptpllst;
  // a=b
  case (BackendDAE.COMPLEX_EQUATION(index=i,lhs = e1 as DAE.CREF(componentRef=cr1), rhs = e2  as DAE.CREF(componentRef=cr2),source = source),funcs)
    equation
      // create as many equations as the dimension of the record
      DAE.ET_COMPLEX(varLst=varLst) = ComponentReference.crefLastType(cr1);
      e1lst = Util.listMap1(varLst,generateCrefsExpFromType,e1);
      e2lst = Util.listMap1(varLst,generateCrefsExpFromType,e2);
      exptpllst = Util.listThreadTuple(e1lst,e2lst);
      compmultilistlst = Util.listMap2(exptpllst,generateextendedRecordEqn,source,funcs);
      complexEqsLst = Util.listMap(compmultilistlst,Util.tuple21);
      multiEqsLst = Util.listMap(compmultilistlst,Util.tuple22);
      complexEqs = Util.listFlatten(complexEqsLst);
      multiEqs = Util.listFlatten(multiEqsLst);
      // nested Records
      compmultilistlst1 = Util.listMap1(complexEqs,extendRecordEqns,funcs);
      complexEqsLst1 = Util.listMap(compmultilistlst1,Util.tuple21);
      multiEqsLst1 = Util.listMap(compmultilistlst1,Util.tuple22);
      complexEqs1 = Util.listFlatten(complexEqsLst1);
      multiEqs1 = Util.listFlatten(multiEqsLst1);
      multiEqs2 = listAppend(multiEqs,multiEqs1);
    then
      ((complexEqs1,multiEqs2)); 
  // a=Record()
  case (BackendDAE.COMPLEX_EQUATION(index=i,lhs = e1 as DAE.CREF(componentRef=cr1), rhs = e2  as DAE.CALL(path=path,expLst=expLst),source = source),funcs)
    equation
      SOME(DAE.RECORD_CONSTRUCTOR(path=fname)) = DAEUtil.avlTreeGet(funcs,path);
      // create as many equations as the dimension of the record
      DAE.ET_COMPLEX(varLst=varLst) = ComponentReference.crefLastType(cr1);
      e1lst = Util.listMap1(varLst,generateCrefsExpFromType,e1);
      exptpllst = Util.listThreadTuple(e1lst,expLst);
      compmultilistlst = Util.listMap2(exptpllst,generateextendedRecordEqn,source,funcs);
      complexEqsLst = Util.listMap(compmultilistlst,Util.tuple21);
      multiEqsLst = Util.listMap(compmultilistlst,Util.tuple22);
      complexEqs = Util.listFlatten(complexEqsLst);
      multiEqs = Util.listFlatten(multiEqsLst);
      // nested Records
      compmultilistlst1 = Util.listMap1(complexEqs,extendRecordEqns,funcs);
      complexEqsLst1 = Util.listMap(compmultilistlst1,Util.tuple21);
      multiEqsLst1 = Util.listMap(compmultilistlst1,Util.tuple22);
      complexEqs1 = Util.listFlatten(complexEqsLst1);
      multiEqs1 = Util.listFlatten(multiEqsLst1);
      multiEqs2 = listAppend(multiEqs,multiEqs1);
    then
      ((complexEqs1,multiEqs2)); 
  case(eqn,_) then (({eqn},{}));      
end matchcontinue;
end extendRecordEqns;

public function generateCrefsExpFromType "
Author: Frenkel TUD 2010-05"
  input DAE.ExpVar inVar;
  input DAE.Exp inExp;
  output DAE.Exp outCrefExp;
algorithm outCrefExp := matchcontinue(inVar,inExp)
  local
    String name;
    DAE.ExpType tp;
    DAE.ComponentRef cr,cr1;
    DAE.Exp e;
  case (DAE.COMPLEX_VAR(name=name,tp=tp),DAE.CREF(componentRef=cr))
  equation
    cr1 = ComponentReference.crefPrependIdent(cr,name,{},tp);
    e = Exp.makeCrefExp(cr1, tp);
  then
    e;
 end matchcontinue;
end generateCrefsExpFromType;

protected function generateextendedRecordEqn "
Author: Frenkel TUD 2010-05"
  input tuple<DAE.Exp,DAE.Exp> inExp;
  input DAE.ElementSource Source;
  input DAE.FunctionTree inFuncs;
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.MultiDimEquation>> outTuplEqnLst;
algorithm 
  outTuplEqnLst := matchcontinue(inExp,Source,inFuncs)
  local
    DAE.Exp e1,e2,e1_1,e2_1,e2_2;
    list<DAE.Exp> e1lst, e2lst;
    DAE.ElementSource source;
    DAE.ComponentRef cr1,cr2;
    list<DAE.ComponentRef> crlst1,crlst2;
    BackendDAE.Equation eqn;
    list<BackendDAE.Equation> eqnlst;
    list<tuple<DAE.Exp,DAE.Exp>> exptplst;
    list<list<DAE.Subscript>> subslst,subslst1;
    Exp.Type tp;
    list<DAE.Dimension> ad;
    list<Integer> ds;
  // array types to array equations  
  case ((e1 as DAE.CREF(componentRef=cr1,ty=DAE.ET_ARRAY(arrayDimensions=ad)),e2),source,inFuncs)
  equation 
    (e1_1,_) = extendArrExp(e1,SOME(inFuncs));
    (e2_1,_) = extendArrExp(e2,SOME(inFuncs));
    e2_2 = Exp.simplify(e2_1);
    ds = Util.listMap(ad, Exp.dimensionSize);
  then
    (({},{BackendDAE.MULTIDIM_EQUATION(ds,e1_1,e2_2,source)}));
  // other types  
  case ((e1 as DAE.CREF(componentRef=cr1),e2),source,inFuncs)
  equation 
    tp = Exp.typeof(e1);
    false = DAEUtil.expTypeComplex(tp);
    (e1_1,_) = extendArrExp(e1,SOME(inFuncs));
    (e2_1,_) = extendArrExp(e2,SOME(inFuncs));
    e2_2 = Exp.simplify(e2_1);
    eqn = generateEQUATION((e1_1,e2_2),source);
  then
    (({eqn},{}));    
  // complex type
  case ((e1,e2),source,inFuncs)
  equation 
    tp = Exp.typeof(e1);
    true = DAEUtil.expTypeComplex(tp);
  then
    (({BackendDAE.COMPLEX_EQUATION(-1,e1,e2,source)},{}));    
 end matchcontinue;
end generateextendedRecordEqn;

public function arrayDimensionsToRange "
Author: Frenkel TUD 2010-05"
  input list<Option<Integer>> dims;
  output list<list<DAE.Subscript>> outRangelist;
algorithm
  outRangelist := matchcontinue(dims)
  local 
    Integer i;
    list<list<DAE.Subscript>> rangelist;
    list<Integer> range;
    list<DAE.Subscript> subs;
    case({}) then {};
    case(NONE()::dims) equation
      rangelist = arrayDimensionsToRange(dims);
    then {}::rangelist;
    case(SOME(i)::dims) equation
      range = Util.listIntRange(i);
      subs = rangesToSubscript(range);
      rangelist = arrayDimensionsToRange(dims);
    then subs::rangelist;
  end matchcontinue;
end arrayDimensionsToRange;

public function dimensionsToRange
  "Converts a list of dimensions to a list of integer ranges."
  input list<DAE.Dimension> dims;
  output list<list<DAE.Subscript>> outRangelist;
algorithm
  outRangelist := matchcontinue(dims)
  local 
    Integer i;
    list<list<DAE.Subscript>> rangelist;
    list<Integer> range;
    list<DAE.Subscript> subs;
    DAE.Dimension d;
    case({}) then {};
    case(DAE.DIM_UNKNOWN::dims) 
      equation
        rangelist = dimensionsToRange(dims);
      then {}::rangelist;
    case(d::dims) equation
      i = Exp.dimensionSize(d);
      range = Util.listIntRange(i);
      subs = rangesToSubscript(range);
      rangelist = dimensionsToRange(dims);
    then subs::rangelist;
  end matchcontinue;
end dimensionsToRange;

protected function rangesToSubscript "
Author: Frenkel TUD 2010-05"
  input list<Integer> inRange;
  output list<DAE.Subscript> outSubs;
algorithm
  outSubs := matchcontinue(inRange)
  local 
    Integer i;
    list<Integer> res;
    list<DAE.Subscript> range;
    case({}) then {};
    case(i::res) 
      equation
        range = rangesToSubscript(res);
      then DAE.INDEX(DAE.ICONST(i))::range;
  end matchcontinue;
end rangesToSubscript;

public function rangesToSubscripts "
Author: Frenkel TUD 2010-05"
  input list<list<DAE.Subscript>> inRangelist;
  output list<list<DAE.Subscript>> outSubslst;
algorithm
  outSubslst := matchcontinue(inRangelist)
  local 
    list<list<DAE.Subscript>> rangelist,rangelist1;
    list<list<list<DAE.Subscript>>> rangelistlst;
    list<DAE.Subscript> range;
    case({}) then {};
    case(range::{})
      equation
        rangelist = Util.listMap(range,Util.listCreate); 
      then rangelist;
    case(range::rangelist)
      equation
      rangelist = rangesToSubscripts(rangelist);
      rangelistlst = Util.listMap1(range,rangesToSubscripts1,rangelist);
      rangelist1 = Util.listFlatten(rangelistlst);
    then rangelist1;
  end matchcontinue;
end rangesToSubscripts;

protected function rangesToSubscripts1 "
Author: Frenkel TUD 2010-05"
  input DAE.Subscript inSub;
  input list<list<DAE.Subscript>> inRangelist;
  output list<list<DAE.Subscript>> outSubslst;
algorithm
  outSubslst := matchcontinue(inSub,inRangelist)
  local 
    list<list<DAE.Subscript>> rangelist,rangelist1;
    DAE.Subscript sub;
    case(sub,rangelist)
      equation
      rangelist1 = Util.listMap1r(rangelist,Util.listAddElementFirst,sub);
    then rangelist1;
  end matchcontinue;
end rangesToSubscripts1;

public function generateEQUATION "
Author: Frenkel TUD 2010-05"
  input tuple<DAE.Exp,DAE.Exp> inTpl;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm outEqn := matchcontinue(inTpl,Source)
  local
    DAE.Exp e1,e2;
    DAE.ElementSource source;
  case ((e1,e2),source) then BackendDAE.EQUATION(e1,e2,source);
 end matchcontinue;
end generateEQUATION;

public function crefPrefixDer
  "Appends $DER to a cref, so a => $DER.a"
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := ComponentReference.makeCrefQual("$DER", DAE.ET_REAL(), {}, inCref);
end crefPrefixDer;

public function makeDerCref
  "Appends $DER to a cref and constructs a DAE.CREF_QUAL from the resulting cref."
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := ComponentReference.makeCrefQual("$DER", DAE.ET_REAL(), {}, inCref);
end makeDerCref;

public function equationSource "Retrieve the source from a BackendDAE.DAELow equation"
  input BackendDAE.Equation eq;
  output DAE.ElementSource source;
algorithm
  source := matchcontinue eq
    case BackendDAE.EQUATION(source=source) then source;
    case BackendDAE.ARRAY_EQUATION(source=source) then source;
    case BackendDAE.SOLVED_EQUATION(source=source) then source;
    case BackendDAE.RESIDUAL_EQUATION(source=source) then source;
    case BackendDAE.WHEN_EQUATION(source=source) then source;
    case BackendDAE.ALGORITHM(source=source) then source;
    case BackendDAE.COMPLEX_EQUATION(source=source) then source;
  end matchcontinue;
end equationSource;

public function equationInfo "Retrieve the line number information from a BackendDAE.DAELow equation"
  input BackendDAE.Equation eq;
  output Absyn.Info info;
algorithm
  info := DAEUtil.getElementSourceFileInfo(equationSource(eq));
end equationInfo;

protected function emptyAliasVariables
  output BackendDAE.AliasVariables outAliasVariables;
  HashTable2.HashTable aliasMappings;
  BackendDAE.Variables aliasVariables;
algorithm
  aliasMappings := HashTable2.emptyHashTable();
  aliasVariables := emptyVars();
  outAliasVariables := BackendDAE.ALIASVARS(aliasMappings,aliasVariables);
end emptyAliasVariables;

public function generateLinearMatrix
  // function: generateLinearMatrix
  // author: wbraun
  input BackendDAE.DAELow inDAELow;
  input DAE.FunctionTree functionTree;
  input list<DAE.ComponentRef> inComRef1; // eqnvars
  input list<DAE.ComponentRef> inComRef2; // vars to differentiate 
  input list<BackendDAE.Var> inAllVar;
  output BackendDAE.DAELow outJacobian;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComps1;
algorithm 
  (outJacobian,outV1,outV2,outComps1) :=
    matchcontinue (inDAELow,functionTree,inComRef1,inComRef2,inAllVar)
    local
      DAE.DAElist dae;
      BackendDAE.DAELow dlow;
      
      list<DAE.ComponentRef> eqvars,diffvars;
      list<BackendDAE.Var> varlst;
      array<Integer> v1,v2,v4,v31;
      list<Integer> v3;
      list<list<Integer>> comps1,comps2;
      list<BackendDAE.Var> derivedVariables;
      list<BackendDAE.Var> derivedVars;
      BackendDAE.BinTree jacElements;
      list<tuple<String,Integer>> varTuple;
      array<list<Integer>> m,mT;
      
      BackendDAE.Variables v,kv,exv;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray e,re,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ev;
      BackendDAE.ExternalObjectClasses eoc;
      list<BackendDAE.Equation> e_lst,re_lst,ie_lst;
      list<DAE.Algorithm> algs;
      list<BackendDAE.MultiDimEquation> ae_lst;
      
      list<String> s;
      String str;
      
      case(dlow as BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),_,{},_,_)
        equation
      v = listVar({});    
      then (BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),listArray({}),listArray({}),{});
      case(dlow as BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),_,_,{},_)
        equation
      v = listVar({});    
      then (BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),listArray({}),listArray({}),{});
      case(dlow as BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),functionTree,eqvars,diffvars,varlst)
        equation

        // prepare index for Matrix and variables for simpleEquations
        derivedVariables = varList(v);
        (varTuple) = determineIndices(eqvars, diffvars, 0, varlst);
        BackendDump.printTuple(varTuple);
        jacElements = BackendDAE.emptyBintree;
        (derivedVariables,jacElements) = changeIndices(derivedVariables, varTuple, jacElements);
        v = listVar(derivedVariables);
        
        // Remove simple Equtaion and 
        e_lst = equationList(e);
        re_lst = equationList(re);
        ie_lst = equationList(ie);
        ae_lst = arrayList(ae);
        algs = arrayList(al);
        (v,kv,e_lst,re_lst,ie_lst,ae_lst,algs,av) = removeSimpleEquations(v,kv, e_lst, re_lst, ie_lst, ae_lst, algs, jacElements); 
        e = listEquation(e_lst);
        re = listEquation(re_lst);
        ie = listEquation(ie_lst);
        ae = listArray(ae_lst);
        al = listArray(algs);
        dlow = BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc);
     
        // figure out new matching and the strong components  
        m = incidenceMatrix(dlow);
        mT = transposeMatrix(m);
        (v1,v2,dlow,m,mT) = matchingAlgorithm(dlow, m, mT, (BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.KEEP_SIMPLE_EQN()),functionTree);
        Debug.fcall("jacdump2", BackendDump.dumpIncidenceMatrix, m);
        Debug.fcall("jacdump2", BackendDump.dumpIncidenceMatrixT, mT);
        Debug.fcall("jacdump2", BackendDump.dump, dlow);
        Debug.fcall("jacdump2", BackendDump.dumpMatching, v1);
        (comps1) = strongComponents(m, mT, v1, v2);
        Debug.fcall("jacdump2", BackendDump.dumpComponents, comps1);

        // figure out wich comps are needed to evaluate all derivedVariables  
        derivedVariables = varList(v);
        (derivedVars,_) = Util.listSplitOnTrue(derivedVariables,checkIndex);
        v3 = getVarIndex(derivedVars,derivedVariables);
        v31 = Util.arraySelect(v1,v3);
        v3 = arrayList(v31);
        s = Util.listMap(v3,intString);
        str = Util.stringDelimitList(s,",");
        Debug.fcall("markblocks",print,"Vars Indecies : " +& str +& "\n");
        v4 = fill(0,listLength(comps1));
        v4 = MarkArray(v3,comps1,v4);
        (comps1,_) = splitBlocks2(comps1,v4,1);
        
        Debug.fcall("jacdump2", BackendDump.dumpComponents, comps1);
        
        then (dlow,v1,v2,comps1);
    case(_, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.generateLinearMatrix failed"});
    then fail();          
   end matchcontinue;
end generateLinearMatrix;         

protected function splitBlocks2 
//function: splitBlocks2
//author: wbraun 
  input list<list<Integer>> inIntegerLstLst;
  input Integer[:] inIntegerArray;
  input Integer inPos;
  output list<list<Integer>> outIntegerLstLst1;
  output list<list<Integer>> outIntegerLstLst2;
algorithm
  (outIntegerLstLst1,outIntegerLstLst2):=
  matchcontinue (inIntegerLstLst,inIntegerArray,inPos)
    local
      list<list<BackendDAE.Value>> states,output_,blocks;
      list<BackendDAE.Value> block_;
      array<BackendDAE.Value> arr;
      BackendDAE.Value i;
    case ({},_,_) then ({},{});
    case ((block_ :: blocks),arr,i)
      equation
        1 = arr[i];
        (states,output_) = splitBlocks2(blocks, arr,i+1);
      then
        ((block_ :: states),output_);
    case ((block_ :: blocks),arr,i)
      equation
        (states,output_) = splitBlocks2(blocks, arr,i+1);
      then
        (states,(block_ :: output_));
    case ((block_ :: blocks),arr,i)
      equation
        (states,output_) = splitBlocks2(blocks, arr,i+1);
      then
        (states,(block_ :: output_));        
  end matchcontinue;
end splitBlocks2;

protected function MarkArray
  // function : MarkArray
  // author : wbraun
  input list<Integer> inVars1;
  input list<list<Integer>> inVars2;
  input Integer[:] inInt;
  output Integer[:] outJacobian;
algorithm
  outJacobian := matchcontinue(inVars1,inVars2,inInt)
    local
      list<Integer> rest;
      list<list<Integer>> vars;
      Integer var;
      list<Integer> intlst,ilst2;
      Integer i;
      Integer[:] arr,arr1;
      list<String> s,s1;
      String str;
    case({},_,arr) then arr;      
    case(var::rest,vars,arr)
      equation
        i = Util.listlistPosition(var,vars);
        Debug.fcall("markblocks",print,"Var " +& intString(var) +& " at pos : " +& intString(i) +& "\n");
        arr1 = fill(1,i+1);
        arr = Util.arrayCopy(arr1,arr);
        arr = MarkArray(rest,vars,arr);
        s = Util.listMap(arrayList(arr),intString);
        str = Util.stringAppendList(s);
        Debug.fcall("markblocks",print,str);
        Debug.fcall("markblocks",print,"\n");
      then arr;        
     case(_,_,_)
       equation
        Debug.fcall("failtrace",print,"DAELow.MarkArray failed\n");
       then fail();
  end matchcontinue;
end MarkArray; 


protected function getVarIndex
  // function : getVarIndex
  // author : wbraun
  input list<BackendDAE.Var> inVars1;
  input list<BackendDAE.Var> inVars2;
  output list<Integer> outJacobian;
algorithm
  outJacobian := matchcontinue(inVars1, inVars2)
    local
      list<BackendDAE.Var> vars,rest;
      BackendDAE.Var var;
      list<Integer> intlst;
      Integer i;
    case({},_) then {};      
    case(var::rest,vars)
      equation
        i = Util.listPosition(var,vars)+1;
        intlst = getVarIndex(rest,vars);
      then (i::intlst);
    case(var::rest,_)
      equation
        Debug.fcall("failtrace",print,"DAELow.getVarIndex failed\n");
      then fail();
  end matchcontinue;
end getVarIndex;  

public function checkIndex "function: checkIndex
  author: wbraun

  check if the index is greater 0
"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local BackendDAE.Value i;
    case (BackendDAE.VAR(index = i)) then i >= 0;
  end matchcontinue;
end checkIndex;

public function generateSymbolicJacobian
  // function: generateSymbolicJacobian
  // author: lochel
  input BackendDAE.DAELow inDAELow;
  input DAE.FunctionTree functions;
  input list<DAE.ComponentRef> inVars;
  input list<BackendDAE.Var> stateVars;
  input list<BackendDAE.Var> inputVars;
  input list<BackendDAE.Var> paramVars;
  output BackendDAE.DAELow outJacobian;
algorithm
  outJacobian := matchcontinue(inDAELow, functions, inVars, stateVars, inputVars, paramVars)
    local
      BackendDAE.DAELow daeLow;
      DAE.DAElist daeList;
      list<DAE.ComponentRef> vars;
      BackendDAE.DAELow jacobian;
      
      // DAELOW
      BackendDAE.Variables orderedVars, jacOrderedVars;
      BackendDAE.Variables knownVars, jacKnownVars;
      BackendDAE.Variables externalObjects, jacExternalObjects;
      BackendDAE.AliasVariables aliasVars, jacAliasVars;
      BackendDAE.EquationArray orderedEqs, jacOrderedEqs;
      BackendDAE.EquationArray removedEqs, jacRemovedEqs;
      BackendDAE.EquationArray initialEqs, jacInitialEqs;
      array<BackendDAE.MultiDimEquation> arrayEqs, jacArrayEqs;
      array<DAE.Algorithm> algorithms, jacAlgorithms;
      BackendDAE.EventInfo eventInfo, jacEventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses, jacExtObjClasses;
      // end DAELOW
      
      list<BackendDAE.Var> allVars, inputVars, paramVars, stateVars, derivedVariables;
      list<BackendDAE.Equation> solvedEquations, derivedEquations, derivedEquations2;
      list<DAE.Algorithm> derivedAlgorithms;
      list<tuple<Integer, DAE.ComponentRef>> derivedAlgorithmsLookUp;
      
    case(_, _, {}, _, _,_) equation
      jacOrderedVars = emptyVars();
      jacKnownVars = emptyVars();
      jacExternalObjects = emptyVars();
      jacAliasVars =  emptyAliasVariables();
      jacOrderedEqs = listEquation({});
      jacRemovedEqs = listEquation({});
      jacInitialEqs = listEquation({});
      jacArrayEqs = listArray({});
      jacAlgorithms = listArray({});
      jacEventInfo = BackendDAE.EVENT_INFO({},{});
      jacExtObjClasses = {};
      
      jacobian = BackendDAE.DAELOW(jacOrderedVars, jacKnownVars, jacExternalObjects, jacAliasVars, jacOrderedEqs, jacRemovedEqs, jacInitialEqs, jacArrayEqs, jacAlgorithms, jacEventInfo, jacExtObjClasses);
    then jacobian;
      
    case(daeLow as BackendDAE.DAELOW(orderedVars=orderedVars, knownVars=knownVars, externalObjects=externalObjects, aliasVars=aliasVars, orderedEqs=orderedEqs, removedEqs=removedEqs, initialEqs=initialEqs, arrayEqs=arrayEqs, algorithms=algorithms, eventInfo=eventInfo, extObjClasses=extObjClasses), functions, vars, stateVars, inputVars, paramVars) equation
      Debug.fcall("jacdump", print, "\n+++++++++++++++++++++ daeLow-dump:    input +++++++++++++++++++++\n");
      Debug.fcall("jacdump", BackendDump.dump, daeLow);
      Debug.fcall("jacdump", print, "##################### daeLow-dump:    input #####################\n\n");
      
      allVars = listAppend(listAppend(stateVars, inputVars), paramVars);
      
      derivedVariables = generateJacobianVars(varList(orderedVars), vars, stateVars);
      (derivedAlgorithms, derivedAlgorithmsLookUp) = deriveAllAlg(arrayList(algorithms), vars, functions, 0);
      derivedEquations = deriveAll(equationList(orderedEqs), vars, functions, inputVars, paramVars, stateVars, derivedAlgorithmsLookUp);
      
      jacOrderedVars = listVar(derivedVariables);
      jacKnownVars = emptyVars();
      jacExternalObjects = emptyVars();
      jacAliasVars =  emptyAliasVariables();
      jacOrderedEqs = listEquation(derivedEquations);
      jacRemovedEqs = listEquation({});
      jacInitialEqs = listEquation({});
      jacArrayEqs = listArray({});
      jacAlgorithms = listArray(derivedAlgorithms);
      jacEventInfo = BackendDAE.EVENT_INFO({},{});
      jacExtObjClasses = {};
      
      jacobian = BackendDAE.DAELOW(jacOrderedVars, jacKnownVars, jacExternalObjects, jacAliasVars, jacOrderedEqs, jacRemovedEqs, jacInitialEqs, jacArrayEqs, jacAlgorithms, jacEventInfo, jacExtObjClasses);
      
      Debug.fcall("jacdump", print, "\n+++++++++++++++++++++ daeLow-dump: jacobian +++++++++++++++++++++\n");
      Debug.fcall("jacdump", BackendDump.dump, jacobian);
      Debug.fcall("jacdump", print, "##################### daeLow-dump: jacobian #####################\n");
    then jacobian;  
      
    case(_, _, _, _, _,_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.generateSymbolicJacobian failed"});
    then fail();
  end matchcontinue;
end generateSymbolicJacobian;

protected function deriveAllAlg
  // function: deriveAllAlg
  // author: lochel
  input list<DAE.Algorithm> inAlgorithms;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input Integer inAlgIndex; // 0
  output list<DAE.Algorithm> outDerivedAlgorithms;
  output list<tuple<Integer, DAE.ComponentRef>> outDerivedAlgorithmsLookUp;
algorithm
  (outDerivedAlgorithms, outDerivedAlgorithmsLookUp) := matchcontinue(inAlgorithms, inVars, inFunctions, inAlgIndex)
    case({}, _, _, _)
    then ({}, {});
      
    case(currAlg::restAlgs, vars, functions, algIndex) local
      DAE.Algorithm currAlg;
      list<DAE.Algorithm> restAlgs;
      list<DAE.ComponentRef> vars;
      DAE.FunctionTree functions;
      Integer algIndex;
      list<DAE.Algorithm> rAlgs1, rAlgs2;
      list<tuple<Integer, DAE.ComponentRef>> rLookUp1, rLookUp2;
    equation
      (rAlgs1, rLookUp1) = deriveOneAlg(currAlg, vars, functions, algIndex);
      (rAlgs2, rLookUp2) = deriveAllAlg(restAlgs, vars, functions, algIndex+1);
      rAlgs1 = listAppend(rAlgs1, rAlgs2);
      rLookUp1 = listAppend(rLookUp1, rLookUp2);
    then (rAlgs1, rLookUp1);
  end matchcontinue;
end deriveAllAlg;

protected function deriveOneAlg
  // function: deriveOneAlg
  // author: lochel
  input DAE.Algorithm inAlgorithm;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input Integer inAlgIndex;
  output list<DAE.Algorithm> outDerivedAlgorithms;
  output list<tuple<Integer, DAE.ComponentRef>> outDerivedAlgorithmsLookUp;
algorithm
  (outDerivedAlgorithms, outDerivedAlgorithmsLookUp) := matchcontinue(inAlgorithm, inVars, inFunctions, inAlgIndex)
    case(_, {}, _, _)
    then ({}, {});
      
    case(currAlg as DAE.ALGORITHM_STMTS(statementLst=statementLst), currVar::restVars, functions, algIndex) local
      DAE.Algorithm currAlg;
      list<DAE.Statement> statementLst, derivedStatementLst;
      DAE.ComponentRef currVar;
      list<DAE.ComponentRef> restVars;
      DAE.FunctionTree functions;
      Integer algIndex;
      list<DAE.Algorithm> rAlgs1, rAlgs2;
      list<tuple<Integer, DAE.ComponentRef>> rLookUp1, rLookUp2;
    equation
      derivedStatementLst = differentiateAlgorithmStatements(statementLst, currVar, functions);
      rAlgs1 = {DAE.ALGORITHM_STMTS(derivedStatementLst)};
      rLookUp1 = {(algIndex, currVar)};
      (rAlgs2, rLookUp2) = deriveOneAlg(currAlg, restVars, functions, algIndex);
      rAlgs1 = listAppend(rAlgs1, rAlgs2);
      rLookUp1 = listAppend(rLookUp1, rLookUp2);
    then (rAlgs1, rLookUp1);
  end matchcontinue;
end deriveOneAlg;

protected function generateJacobianVars
  // function: generateJacobianVars
  // author: lochel
  input list<BackendDAE.Var> inVars1;
  input list<DAE.ComponentRef> inVars2;
  input list<BackendDAE.Var> inStateVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := matchcontinue(inVars1, inVars2, inStateVars)
  local
    BackendDAE.Var currVar;
    list<BackendDAE.Var> restVar, r1, r2, r, stateVars;
    list<DAE.ComponentRef> vars2;
    
    case({}, _, _)
    then {}; 
      
    case(currVar::restVar, vars2, stateVars) equation
      r1 = generateJacobianVars2(currVar, vars2, stateVars);
      r2 = generateJacobianVars(restVar, vars2, stateVars);
      r = listAppend(r1, r2);
    then r;
      
    case(_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.generateJacobianVars failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars;

protected function generateJacobianVars2
  // function: generateJacobianVars2
  // author: lochel
  input BackendDAE.Var inVar1;
  input list<DAE.ComponentRef> inVars2;
  input list<BackendDAE.Var> inStateVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := matchcontinue(inVar1, inVars2, inStateVars)
  local
    BackendDAE.Var var, r1;
    DAE.ComponentRef currVar, cref, derivedCref;
    list<DAE.ComponentRef> restVar;
    list<BackendDAE.Var> r2;
    list<BackendDAE.Var> stateVars;
    
    case(_, {}, _)
    then {};
    
    case(var as BackendDAE.VAR(varName=cref), currVar::restVar, stateVars) equation
      derivedCref = differentiateVarWithRespectToX(cref, currVar, stateVars);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), BackendDAE.REAL(), NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      r2 = generateJacobianVars2(var, restVar, stateVars);
    then r1::r2;
      
    case(_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.generateJacobianVars2 failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars2;

protected function deriveAll
  // function: deriveAll
  // author: lochel
  input list<BackendDAE.Equation> inEquations;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquations, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inAlgorithmsLookUp)
    local
      BackendDAE.Equation currEquation;
      list<BackendDAE.Equation> restEquations;
      DAE.FunctionTree functions;
      list<DAE.ComponentRef> vars;
      list<BackendDAE.Equation> currDerivedEquations, restDerivedEquations, derivedEquations;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      list<tuple<Integer, DAE.ComponentRef>> algorithmsLookUp;
    case({}, _, _, _, _, _, _) then {};
      
    case(currEquation::restEquations, vars, functions, inputVars, paramVars, stateVars, algorithmsLookUp) equation
      Debug.fcall("jacdumptime", BackendDump.dumpEqns, {currEquation});
      currDerivedEquations = deriveOne(currEquation, vars, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      restDerivedEquations = deriveAll(restEquations, vars, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      derivedEquations = listAppend(currDerivedEquations, restDerivedEquations);
    then derivedEquations;
      
    case(_, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.deriveAll failed"});
    then fail();
  end matchcontinue;
end deriveAll;

protected function deriveOne
  // function: deriveOne
  // author: lochel
  input BackendDAE.Equation inEquation;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquation, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inAlgorithmsLookUp)
    local
      BackendDAE.Equation currEquation;
      list<DAE.Algorithm> algorithms;
      DAE.FunctionTree functions;
      DAE.ComponentRef currVar;
      list<DAE.ComponentRef> restVars;
      Integer algNum;
      
      list<BackendDAE.Var> currDerivedVariables, restDerivedVariables, derivedVariables;
      list<BackendDAE.Equation> currDerivedEquations, restDerivedEquations, derivedEquations;
      list<DAE.Algorithm> currDerivedAlgorithms, restDerivedAlgorithms, derivedAlgorithms;
      
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      list<tuple<Integer, DAE.ComponentRef>> algorithmsLookUp;
      Integer i; 
    case(_, {}, _, _, _, _, _) then {};
      
    case(currEquation, currVar::restVars, functions, inputVars, paramVars, stateVars, algorithmsLookUp) equation
      currDerivedEquations = derive(currEquation, currVar, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      restDerivedEquations = deriveOne(currEquation, restVars, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      
      derivedEquations = listAppend(currDerivedEquations, restDerivedEquations);
    then derivedEquations;
      
    case(_, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.deriveOne failed"});
    then fail();
  end matchcontinue;
end deriveOne;

protected function derive
  // function: derive
  // author: lochel
  input BackendDAE.Equation inEquation;
  input DAE.ComponentRef inVar;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquation, inVar, inFunctions, inInputVars, inParamVars, inStateVars, inAlgorithmsLookUp)
    local
      BackendDAE.Equation currEquation;
      list<DAE.Algorithm> algorithms;
      DAE.FunctionTree functions;
      DAE.ComponentRef var, cref, cref_;
      
      BackendDAE.Var currDerivedVariable;
      BackendDAE.Equation currDerivedEquation;
      DAE.Algorithm currDerivedAlgorithm;
      
      DAE.Exp lhs, rhs, lhs_, rhs_, exp, exp_;
      DAE.ElementSource source;
      
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      
    case(currEquation as BackendDAE.EQUATION(exp=lhs, scalar=rhs, source=source), var, functions, inputVars, paramVars, stateVars, _) equation
      lhs_ = differentiateWithRespectToX(lhs, var, functions, inputVars, paramVars, stateVars);
      rhs_ = differentiateWithRespectToX(rhs, var, functions, inputVars, paramVars, stateVars);
    then {BackendDAE.EQUATION(lhs_, rhs_, source)};
      
    case(currEquation as BackendDAE.ARRAY_EQUATION(_, _, _), var, functions, inputVars, paramVars, stateVars, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.derive failed: ARRAY_EQUATION-case"});
    then fail();
      
    case(currEquation as BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=exp, source=source), var, functions, inputVars, paramVars, stateVars, _) equation
      cref_ = differentiateVarWithRespectToX(cref, var, stateVars);
      exp_ = differentiateWithRespectToX(exp, var, functions, inputVars, paramVars, stateVars);
    then {BackendDAE.SOLVED_EQUATION(cref_, exp_, source)};
      
    case(currEquation as BackendDAE.RESIDUAL_EQUATION(exp=exp, source=source), var, functions, inputVars, paramVars, stateVars, _) equation
      exp_ = differentiateWithRespectToX(exp, var, functions, inputVars, paramVars, stateVars);
    then {BackendDAE.RESIDUAL_EQUATION(exp_, source)};
      
    case(currEquation as BackendDAE.ALGORITHM(index=index, in_=in_, out=out, source=source), var, functions, inputVars, paramVars, stateVars, algorithmsLookUp) local
      Integer index;
      list<DAE.Exp> in_, derivedIn_;
      list<DAE.Exp> out, derivedOut;
      DAE.ElementSource source;
      DAE.Algorithm singleAlgorithm, derivedAlgorithm;
      list<tuple<Integer, DAE.ComponentRef>> algorithmsLookUp;
      Integer newAlgIndex;
    equation
      derivedIn_ = Util.listMap5(in_, differentiateWithRespectToX, var, functions, {}, {}, {});
      derivedIn_ = listAppend(in_, derivedIn_);
      derivedOut = Util.listMap5(out, differentiateWithRespectToX, var, functions, {}, {}, {});
        
      newAlgIndex = Util.listPosition((index, var), algorithmsLookUp);
    then {BackendDAE.ALGORITHM(newAlgIndex, derivedIn_, derivedOut, source)};
        
    case(currEquation as BackendDAE.WHEN_EQUATION(_, _), var, functions, inputVars, paramVars, stateVars, _) equation
      Debug.fcall("jacdump",print,"DAELow.derive: WHEN_EQUATION has been removed");
    then {};
      
    case(currEquation as BackendDAE.COMPLEX_EQUATION(_, _, _, _), var, functions, inputVars, paramVars, stateVars, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.derive failed: COMPLEX_EQUATION-case"});
    then fail();
      
    case(_, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.derive failed"});
    then fail();
  end matchcontinue;
end derive;

protected function differentiateVarWithRespectToX
  // function: differentiateVarWithRespectToX
  // author: lochel
  input DAE.ComponentRef inCref;
  input DAE.ComponentRef inX;
  input list<BackendDAE.Var> inStateVars;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inX, inStateVars)
    local
      DAE.ComponentRef cref, x;
      String id;
      DAE.ExpType idType;
      list<DAE.Subscript> sLst;
      list<BackendDAE.Var> stateVars;
      BackendDAE.Var v1;
    
    // d(state)/d(x)
    case(cref, x, stateVars) equation
      ({v1}, _) = getVar(cref, listVar(stateVars));
      true = isStateVar(v1);
      cref = makeDerCref(cref);
      id = ComponentReference.printComponentRefStr(cref) +& BackendDAE.partialDerivativeNamePrefix +& ComponentReference.printComponentRefStr(x);
      id = Util.stringReplaceChar(id, ".", "$P");
      id = Util.stringReplaceChar(id, "[", "$pL");
      id = Util.stringReplaceChar(id, "]", "$pR");
    then ComponentReference.makeCrefIdent(id, DAE.ET_REAL(), {});
    
    // d(no state)/d(x)
    case(cref, x, _) equation
      id = ComponentReference.printComponentRefStr(cref) +& BackendDAE.partialDerivativeNamePrefix +& ComponentReference.printComponentRefStr(x);
      id = Util.stringReplaceChar(id, ".", "$P");
      id = Util.stringReplaceChar(id, "[", "$pL");
      id = Util.stringReplaceChar(id, "]", "$pR");
    then ComponentReference.makeCrefIdent(id, DAE.ET_REAL(), {});
      
    case(cref, _, _) local
      String str; 
      equation
        str = "DAELow.differentiateVarWithRespectToX failed: " +&  ComponentReference.printComponentRefStr(cref);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end differentiateVarWithRespectToX;

protected function differentiateWithRespectToX
  // function: differentiateWithRespectToX
  // author: lochel
  
  input DAE.Exp inExp;
  input DAE.ComponentRef inX;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp, inX, inFunctions, inInputVars, inParamVars, inStateVars)
    local
      DAE.ComponentRef x, cref, cref_;
      DAE.FunctionTree functions;
      DAE.Exp e1, e1_, e2, e2_, e;
      DAE.ExpType et;
      DAE.Operator op;
      
      
      list<DAE.ComponentRef> diff_crefs;
      Absyn.Path fname;
      
      list<DAE.Exp> expList1, expList2;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      
    case(DAE.ICONST(_), _, _, _, _, _)
    then DAE.ICONST(0);
      
    case(DAE.RCONST(_), _, _, _, _, _)
    then DAE.RCONST(0.0);
      
    case (DAE.CAST(ty=et, exp=e1), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.CAST(et, e1_);
      
    // d(x)/d(x)
    case(DAE.CREF(componentRef=cref), x, functions, inputVars, paramVars, stateVars) equation
      true = ComponentReference.crefEqual(cref, x);
    then DAE.RCONST(1.0);
      
    // d(time)/d(x)
    case(DAE.CREF(componentRef=(cref as DAE.CREF_IDENT(ident = "time",subscriptLst = {}))), x, functions, inputVars, paramVars, stateVars)
    then DAE.RCONST(0.0);
    
    // d(state1)/d(state2) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars) local BackendDAE.Var v1, v2; equation
      ({v1}, _) = getVar(cref, listVar(stateVars));
      ({v2}, _) = getVar(x, listVar(stateVars));
    then DAE.RCONST(0.0);
      
    // d(state)/d(input) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars) local BackendDAE.Var v1, v2; equation
      ({v1}, _) = getVar(cref, listVar(stateVars));
      ({v2}, _) = getVar(x, listVar(inputVars));
    then DAE.RCONST(0.0);
      
    // d(input)/d(state) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars) local BackendDAE.Var v1, v2; equation
      ({v1}, _) = getVar(cref, listVar(inputVars));
      ({v2}, _) = getVar(x, listVar(stateVars));
    then DAE.RCONST(0.0);
      
    // d(parameter1)/d(parameter2) != 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars) local BackendDAE.Var v1, v2; equation
      ({v1}, _) = getVar(cref, listVar(paramVars));
      ({v2}, _) = getVar(x, listVar(paramVars));
      cref_ = differentiateVarWithRespectToX(cref, x, stateVars);
    then DAE.CREF(cref_, et);
      
    // d(parameter)/d(no parameter) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars) local BackendDAE.Var v1; equation
      ({v1}, _) = getVar(cref, listVar(paramVars));
    then DAE.RCONST(0.0);
      
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars) equation
      cref_ = differentiateVarWithRespectToX(cref, x, stateVars);
    then DAE.CREF(cref_, et);
      
    // a + b
    case(DAE.BINARY(exp1=e1, operator=DAE.ADD(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.ADD(et), e2_);
      
    // a - b
    case(DAE.BINARY(exp1=e1, operator=DAE.SUB(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.SUB(et), e2_);
      
    // a * b
    case(DAE.BINARY(exp1=e1, operator=DAE.MUL(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
      e = DAE.BINARY(DAE.BINARY(e1_, DAE.MUL(et), e2), DAE.ADD(et), DAE.BINARY(e1, DAE.MUL(et), e2_));
      e = Exp.simplify(e);
    then e;
      
    // a / b
    case(DAE.BINARY(exp1=e1, operator=DAE.DIV(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
      e = DAE.BINARY(DAE.BINARY(DAE.BINARY(e1_, DAE.MUL(et), e2), DAE.SUB(et), DAE.BINARY(e1, DAE.MUL(et), e2_)), DAE.DIV(et), DAE.BINARY(e2, DAE.MUL(et), e2));
      e = Exp.simplify(e);
    then e;
    
    // a(x)^b
    case(e as DAE.BINARY(exp1=e1, operator=DAE.POW(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      true = Exp.isConst(e2);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e = DAE.BINARY(e1_, DAE.MUL(et), DAE.BINARY(e2, DAE.MUL(et), DAE.BINARY(e1, DAE.POW(et), DAE.BINARY(e2, DAE.SUB(et), DAE.RCONST(1.0)))));
    then e;
    
    // der(x)
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars)
      local
        String str;
        DAE.ComponentRef cref; 
      equation
      Builtin.isDer(fname);
      cref = Exp.expCref(e1);
      cref = makeDerCref(cref);
      //str = derivativeNamePrefix +& Exp.printExpStr(e1);
      //cref = ComponentReference.makeCrefIdent(str, DAE.ET_REAL(),{});
      e1_ = differentiateWithRespectToX(Exp.crefExp(cref), x, functions, inputVars, paramVars, stateVars);
    then e1_;
    
    // -exp
    case(DAE.UNARY(operator=op, exp=e1), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.UNARY(op, e1_);
      
    // sin(x)
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isSin(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("cos"),{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE()));

    // cos(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isCos(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()), DAE.BINARY(e1_,DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("sin"),{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE())));

    // ln(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isLog(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.DIV(DAE.ET_REAL()), e1);

    // log10(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isLog10(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.DIV(DAE.ET_REAL()), DAE.BINARY(e1, DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("log"),{DAE.RCONST(10.0)},false,true,DAE.ET_REAL(),DAE.NO_INLINE())));

    // exp(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isExp(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_,DAE.MUL(DAE.ET_REAL()), DAE.CALL(fname,{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE()));
  
    // sqrt(x)
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars)
      equation
        Builtin.isSqrt(fname) "sqrt(x) => 1(2  sqrt(x))  der(x)" ;
        e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE()))),DAE.MUL(DAE.ET_REAL()),e1_);
        
    // abs(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isAbs(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.IFEXP(DAE.RELATION(e1_,DAE.GREATER(DAE.ET_REAL()),DAE.RCONST(0.0)), e1_, DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),e1_));
      
      // differentiate if-expressions
    case (DAE.IFEXP(expCond=e, expThen=e1, expElse=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
    then DAE.IFEXP(e, e1_, e2_);

    // extern functions (analytical)
    case (e as DAE.CALL(path=fname, expLst=expList1, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), x, functions, inputVars, paramVars, stateVars)
    local
        list<DAE.Exp> expList2;
        list<tuple<Integer,DAE.derivativeCond>> conditions;
        Absyn.Path derFname;
        DAE.Type tp;
        Integer nArgs;
    equation
        nArgs = listLength(expList1);
        (DAE.FUNCTION_DER_MAPPER(derivativeFunction=derFname,conditionRefs=conditions), tp) = Derive.getFunctionMapper(fname, functions);
        expList2 = deriveExpListwrtstate(expList1, nArgs, conditions, x, functions, inputVars, paramVars, stateVars);
        e1 = partialAnalyticalDifferentiation(expList1, expList2, e, derFname, listLength(expList2));  
    then e1;

    // extern functions (numeric)
    case (e as DAE.CALL(path=fname, expLst=expList1, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), x, functions, inputVars, paramVars, stateVars)
    local
        list<DAE.Exp> expList2;
        Integer nArgs;
    equation
        nArgs = listLength(expList1);
        expList2 = deriveExpListwrtstate2(expList1, nArgs, x, functions, inputVars, paramVars, stateVars);
        e1 = partialNumericalDifferentiation(expList1, expList2, x, e);  
    then e1;
           
    case(e, x, _, _, _, _)
      local String str;
      equation
        str = "differentiateWithRespectToX failed: " +& Exp.printExpStr(e) +& " | " +& ComponentReference.printComponentRefStr(x);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
end differentiateWithRespectToX;

protected function deriveExpListwrtstate
  input list<DAE.Exp> inExpList;
  input Integer inLengthExpList;
  input list<tuple<Integer,DAE.derivativeCond>> inConditios;
  input DAE.ComponentRef inState;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := matchcontinue(inExpList, inLengthExpList, inConditios, inState, inFunctions, inInputVars, inParamVars, inStateVars)
    local
      DAE.ComponentRef x;
      DAE.Exp curr,r1;
      list<DAE.Exp> rest, r2;
      DAE.FunctionTree functions;
      Integer LengthExpList,n, argnum;
      list<tuple<Integer,DAE.derivativeCond>> conditions;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
    case ({},_,_,_,_,_,_,_) then ({});
    case (curr::rest, LengthExpList, conditions, x, functions,inputVars, paramVars, stateVars) equation
      n = listLength(rest);
      argnum = LengthExpList - n;
      true = checkcondition(conditions,argnum); 
      r1 = differentiateWithRespectToX(curr, x, functions, inputVars, paramVars, stateVars); 
      r2 = deriveExpListwrtstate(rest,LengthExpList,conditions, x, functions,inputVars, paramVars, stateVars);
    then (r1::r2);
    case (curr::rest, LengthExpList, conditions, x, functions,inputVars, paramVars, stateVars) equation
      r2 = deriveExpListwrtstate(rest,LengthExpList,conditions, x, functions,inputVars, paramVars, stateVars);
    then r2;  
  end matchcontinue;
end deriveExpListwrtstate;

protected function deriveExpListwrtstate2
  input list<DAE.Exp> inExpList;
  input Integer inLengthExpList;
  input DAE.ComponentRef inState;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := matchcontinue(inExpList, inLengthExpList, inState, inFunctions, inInputVars, inParamVars, inStateVars)
    local
      DAE.ComponentRef x;
      DAE.Exp curr,r1;
      list<DAE.Exp> rest, r2;
      DAE.FunctionTree functions;
      Integer LengthExpList,n, argnum;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;    
    case ({}, _, _, _, _, _, _) then ({});
    case (curr::rest, LengthExpList, x, functions, inputVars, paramVars, stateVars) equation
      n = listLength(rest);
      argnum = LengthExpList - n;
      r1 = differentiateWithRespectToX(curr, x, functions, inputVars, paramVars, stateVars); 
      r2 = deriveExpListwrtstate2(rest,LengthExpList, x, functions, inputVars, paramVars, stateVars);
    then (r1::r2);
  end matchcontinue;
end deriveExpListwrtstate2;

protected function checkcondition
  input list<tuple<Integer,DAE.derivativeCond>> inConditions;
  input Integer inArgs;
  output Boolean outBool;
algorithm
  outBool := matchcontinue(inConditions, inArgs)
    local
      list<tuple<Integer,DAE.derivativeCond>> rest;
      Integer i,nArgs;
      DAE.derivativeCond cond;
      Boolean res;
    case ({},_) then true;
    case((i,cond)::rest,nArgs) 
      equation
        equality(i = nArgs);
        cond = DAE.ZERO_DERIVATIVE();
      then false;
      case((i,cond)::rest,nArgs) 
        local
          DAE.Exp e1;
         equation
         equality(i = nArgs);
         DAE.NO_DERIVATIVE(_) = cond;
         then false;
    case((i,cond)::rest,nArgs) 
      equation
        res = checkcondition(rest,nArgs);
      then res;           
  end matchcontinue;
end checkcondition;

protected function partialAnalyticalDifferentiation
  input list<DAE.Exp> varExpList;
  input list<DAE.Exp> derVarExpList;
  input DAE.Exp functionCall;
  input Absyn.Path derFname;
  input Integer nDerArgs;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(varExpList, derVarExpList, functionCall, derFname, nDerArgs)
    local
      DAE.Exp e, currVar, currDerVar, derFun, delta, absCurr;
      list<DAE.Exp> restVar, restDerVar, varExpList1Added, varExpListTotal;
      DAE.ExpType et;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      DAE.FunctionTree functions;
    case ( _, {}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, functionCall as DAE.CALL(expLst=varExpListTotal, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), derFname, nDerArgs)
      local
        Integer nArgs1, nArgs2;
      equation
        e = partialAnalyticalDifferentiation(restVar, restDerVar, functionCall, derFname, nDerArgs);
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restDerVar);
        varExpList1Added = Util.listReplaceAtWithFill(DAE.RCONST(0.0),nArgs1 + nDerArgs - 1, varExpListTotal ,DAE.RCONST(0.0));
        varExpList1Added = Util.listReplaceAtWithFill(DAE.RCONST(1.0),nArgs1 + nDerArgs - nArgs2 + 1, varExpList1Added,DAE.RCONST(0.0));
        derFun = DAE.CALL(derFname, varExpList1Added, tuple_, builtin, et, inlineType);
      then DAE.BINARY(e, DAE.ADD(DAE.ET_REAL()), DAE.BINARY(derFun, DAE.MUL(DAE.ET_REAL()), currDerVar)); 
  end matchcontinue;
end partialAnalyticalDifferentiation;

protected function partialNumericalDifferentiation
  input list<DAE.Exp> varExpList;
  input list<DAE.Exp> derVarExpList;
  input DAE.ComponentRef inState;
  input DAE.Exp functionCall;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(varExpList, derVarExpList, inState, functionCall)
    local
      DAE.Exp e, currVar, currDerVar, derFun, delta, absCurr;
      list<DAE.Exp> restVar, restDerVar, varExpListHAdded, varExpListTotal;
      DAE.ExpType et;
      Absyn.Path fname;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      DAE.FunctionTree functions;
    case ({}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, inState, functionCall as DAE.CALL(path=fname, expLst=varExpListTotal, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType))
      local
        Integer nArgs1, nArgs2;
      equation
        e = partialNumericalDifferentiation(restVar, restDerVar, inState, functionCall);
        absCurr = DAE.LBINARY(DAE.RELATION(currVar,DAE.GREATER(DAE.ET_REAL()),DAE.RCONST(1e-8)),DAE.OR(),DAE.RELATION(currVar,DAE.LESS(DAE.ET_REAL()),DAE.RCONST(-1e-8)));
        delta = DAE.IFEXP( absCurr, DAE.BINARY(currVar,DAE.MUL(DAE.ET_REAL()),DAE.RCONST(1e-8)), DAE.RCONST(1e-8));
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restVar);
        varExpListHAdded = Util.listReplaceAtWithFill(DAE.BINARY(currVar, DAE.ADD(DAE.ET_REAL()),delta),nArgs1-nArgs2+1, varExpListTotal,DAE.RCONST(0.0));
        derFun = DAE.BINARY(DAE.BINARY(DAE.CALL(fname, varExpListHAdded, tuple_, builtin, et, inlineType), DAE.SUB(DAE.ET_REAL()), DAE.CALL(fname, varExpListTotal, tuple_, builtin, et, inlineType)), DAE.DIV(DAE.ET_REAL()), delta);
      then DAE.BINARY(e, DAE.ADD(DAE.ET_REAL()), DAE.BINARY(derFun, DAE.MUL(DAE.ET_REAL()), currDerVar)); 
  end matchcontinue;
end partialNumericalDifferentiation;

protected function differentiateAlgorithmStatements
  // function: differentiateAlgorithmStatements
  // author: lochel
  input list<DAE.Statement> inStatements;
  input DAE.ComponentRef inVar;
  input DAE.FunctionTree inFunctions;
  output list<DAE.Statement> outStatements;
algorithm
  outStatements := matchcontinue(inStatements, inVar, inFunctions)
    local
      list<DAE.Statement> restStatements;
      DAE.ComponentRef var;
      list<DAE.ComponentRef> dependentVars;
      DAE.FunctionTree functions;
      
      DAE.Exp e1, e2;
      DAE.ExpType type_;
      
      DAE.Exp lhsExps;
      DAE.Exp rhsExps;
      
      DAE.Statement currStmt;
      list<DAE.Statement> derivedStatements1;
      list<DAE.Statement> derivedStatements2;
      
      list<DAE.Exp> eLst;
      
      list<DAE.ComponentRef> vars1, vars2;
      list<DAE.Exp> exps1, exps2;
      DAE.FunctionTree functions;
      list<DAE.Algorithm> algorithms;
      DAE.ElementSource elemSrc;
      
    case({}, _, _) then {};
      
    case((currStmt as DAE.STMT_ASSIGN(type_=type_, exp1=e1, exp=e2))::restStatements, var, functions) equation
      lhsExps = differentiateWithRespectToX(e1, var, functions, {}, {}, {});
      rhsExps = differentiateWithRespectToX(e2, var, functions, {}, {}, {});
      derivedStatements1 = {DAE.STMT_ASSIGN(type_, lhsExps, rhsExps, DAE.emptyElementSource), currStmt};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_TUPLE_ASSIGN(exp=e2)::restStatements, var, functions) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.differentiateAlgorithmStatements failed: DAE.STMT_TUPLE_ASSIGN"});
    then fail();
      
    case(DAE.STMT_ASSIGN_ARR(exp=e2)::restStatements, var, functions) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.differentiateAlgorithmStatements failed: DAE.STMT_ASSIGN_ARR"});
    then fail();
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.NOELSE(), source=source)::restStatements, var, functions) local
      DAE.Exp exp;
      list<DAE.Statement> statementLst;
      DAE.ElementSource source;
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.NOELSE, source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSEIF(exp=elseif_exp, statementLst=elseif_statementLst, else_=elseif_else_), source=source)::restStatements, var, functions) local
      DAE.Exp exp;
      list<DAE.Statement> statementLst;
      DAE.Exp elseif_exp;
      list<DAE.Statement> elseif_statementLst;
      DAE.Else elseif_else_;
      DAE.ElementSource source;
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements2 = differentiateAlgorithmStatements({DAE.STMT_IF(elseif_exp, elseif_statementLst, elseif_else_, source)}, var, functions);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSE(statementLst=else_statementLst), source=source)::restStatements, var, functions) local
      DAE.Exp exp;
      list<DAE.Statement> statementLst;
      list<DAE.Statement> else_statementLst;
      DAE.ElementSource source;
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements2 = differentiateAlgorithmStatements(else_statementLst, var, functions);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_FOR(type_=type_, iterIsArray=iterIsArray, ident=ident, exp=exp, statementLst=statementLst, source=elemSrc)::restStatements, var, functions) local
      DAE.ExpType type_;
      Boolean iterIsArray;
      DAE.Ident ident;
      DAE.Exp exp, exp2;
      list<DAE.Statement> statementLst;
      DAE.ComponentRef cref;
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      
      /*cref = ComponentReference.makeCrefIdent(ident, DAE.ET_INT(), {});
      cref = differentiateVarWithRespectToX(cref, var, {});
      exp2 = DAE.CREF(cref, DAE.ET_INT());
      
      derivedStatements2 = {DAE.STMT_ASSIGN(DAE.ET_INT(), exp2, DAE.ICONST(StateVar);0), DAE.emptyElementSource)};
      derivedStatements1 = listAppend(derivedStatements2, derivedStatements1);*/
      
      derivedStatements1 = {DAE.STMT_FOR(type_, iterIsArray, ident, exp, derivedStatements1, elemSrc)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
        
    case(DAE.STMT_WHILE(exp=e1, statementLst=statementLst, source=elemSrc)::restStatements, var, functions) local
      list<DAE.Statement> statementLst;
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements1 = {DAE.STMT_WHILE(e1, derivedStatements1, elemSrc)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_WHEN(exp=e2)::restStatements, var, functions) equation
      derivedStatements1 = differentiateAlgorithmStatements(restStatements, var, functions);
    then derivedStatements1;
      
    case((currStmt as DAE.STMT_ASSERT(cond=e2))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case((currStmt as DAE.STMT_TERMINATE(msg=e2))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case(DAE.STMT_REINIT(value=e2)::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
    then derivedStatements2;
      
    case(DAE.STMT_NORETCALL(exp=e1, source=elemSrc)::restStatements, var, functions) equation
      e2 = differentiateWithRespectToX(e1, var, functions, {}, {}, {});
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend({DAE.STMT_NORETCALL(e2, elemSrc)}, derivedStatements2);
    then fail();
      
    case((currStmt as DAE.STMT_RETURN(source=elemSrc))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case((currStmt as DAE.STMT_BREAK(source=elemSrc))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case(_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.differentiateAlgorithmStatements failed"});
    then fail();
  end matchcontinue;
end differentiateAlgorithmStatements;

public function determineIndices
  // function: determineIndices
  // using column major order
  input list<DAE.ComponentRef> inStates;
  input list<DAE.ComponentRef> inStates2;
  input Integer inActInd;
  input list<BackendDAE.Var> inAllVars;
  output list<tuple<String,Integer>> outTuple;
algorithm
  outTuple := matchcontinue(inStates, inStates2, inActInd,inAllVars)
    local
      list<tuple<String,Integer>> str;
      list<tuple<String,Integer>> erg;
      list<DAE.ComponentRef> rest, states;
      DAE.ComponentRef curr;
      Boolean searchForStates;
      Integer actInd;
      list<BackendDAE.Var> allVars;
      
    case ({}, states, _, _) then {};
    case (curr::rest, states, actInd, allVars) equation
      (str, actInd) = determineIndices2(curr, states, actInd, allVars);
      erg = determineIndices(rest, states, actInd, allVars);
      str = listAppend(str, erg);
    then str;
  end matchcontinue;
end determineIndices;

protected function determineIndices2
  // function: determineIndices2
  input DAE.ComponentRef inDStates;
  input list<DAE.ComponentRef> inStates;
  input Integer actInd;
  input list<BackendDAE.Var> inAllVars;
  output list<tuple<String,Integer>> outTuple;
  output Integer outActInd;
algorithm
  (outTuple,outActInd) := matchcontinue(inDStates, inStates, actInd, inAllVars)
    local
      tuple<String,Integer> str;
      list<tuple<String,Integer>> erg;
      list<DAE.ComponentRef> rest;
      DAE.ComponentRef new, curr, dState;
      list<BackendDAE.Var> allVars;
      //String debug1;Integer debug2;
    case (dState, {}, actInd, allVars) then ({}, actInd);
    case (dState,curr::rest, actInd, allVars) equation
      new = differentiateVarWithRespectToX(dState,curr,allVars);
      str = (ComponentReference.printComponentRefStr(new) ,actInd);
      actInd = actInd+1;      
      (erg, actInd) = determineIndices2(dState, rest, actInd, allVars);
    then (str::erg, actInd);
    case (_,_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.determineIndices2() failed"});
    then fail();
  end matchcontinue;
end determineIndices2;

public function changeIndices
  input list<BackendDAE.Var> derivedVariables;
  input list<tuple<String,Integer>> outTuple;
  input BackendDAE.BinTree inBinTree;
  output list<BackendDAE.Var> derivedVariablesChanged;
  output BackendDAE.BinTree outBinTree;
algorithm
  (derivedVariablesChanged,outBinTree) := matchcontinue(derivedVariables,outTuple,inBinTree)
    local
      list<BackendDAE.Var> rest,changedVariables;
      BackendDAE.Var derivedVariable;
      list<tuple<String,Integer>> restTuple;
      BackendDAE.BinTree bt;
    case ({},_,bt) then ({},bt);
    case (derivedVariable::rest,restTuple,bt) equation
      (derivedVariable,bt) = changeIndices2(derivedVariable,restTuple,bt);
      (changedVariables,bt) = changeIndices(rest,restTuple,bt);
    then (derivedVariable::changedVariables,bt);
    case (_,_,_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.changeIndices() failed"});
    then fail();      
  end matchcontinue;
end changeIndices;

protected function changeIndices2
  input BackendDAE.Var derivedVariable;
  input list<tuple<String,Integer>> varIndex; 
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.Var derivedVariablesChanged;
  output BackendDAE.BinTree outBinTree;
algorithm
 (derivedVariablesChanged,outBinTree) := matchcontinue(derivedVariable, varIndex,inBinTree)
    local
      BackendDAE.Var curr, changedVar;
      DAE.ComponentRef currCREF;
      list<tuple<String,Integer>> restTuple;
      String currVar;
      Integer currInd;
      BackendDAE.BinTree bt;
      list<Integer> varInt;
    case (curr  as BackendDAE.VAR(varName=currCREF),(currVar,currInd)::restTuple,bt) equation
      true = stringEqual(currVar,ComponentReference.printComponentRefStr(currCREF));
      changedVar = setVarIndex(curr,currInd);
      Debug.fcall("varIndex2",print, currVar +& " " +& intString(currInd)+&"\n");
      bt = treeAddList(bt,{currCREF});
    then (changedVar,bt);
    case (curr  as BackendDAE.VAR(varName=currCREF),{},bt) equation
      changedVar = setVarIndex(curr,-1);
      Debug.fcall("varIndex2",print, ComponentReference.printComponentRefStr(currCREF) +& " -1\n");
    then (changedVar,bt);      
    case (curr  as BackendDAE.VAR(varName=currCREF),(currVar,currInd)::restTuple,bt) equation
      changedVar = setVarIndex(curr,-1);
      Debug.fcall("varIndex2",print, ComponentReference.printComponentRefStr(currCREF) +& " -1\n");
      (changedVar,bt) = changeIndices2(changedVar,restTuple,bt);
    then (changedVar,bt);
    case (_,_,_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.changeIndices2() failed"});
    then fail();      
  end matchcontinue;
end changeIndices2;

end DAELow;
