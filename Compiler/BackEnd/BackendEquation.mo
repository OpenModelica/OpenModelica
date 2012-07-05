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

encapsulated package BackendEquation
" file:        BackendEquation.mo
  package:     BackendEquation
  description: BackendEquation contains functions that do something with
               BackendDAEEquation datatype.

  RCS: $Id$  
"

public import Absyn;
public import BackendDAE;
public import DAE;

protected import Algorithm;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendVariable;
protected import BaseHashTable;
protected import ClassInf;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionSimplify;
protected import Flags;
protected import HashTable;
protected import List;
protected import Util;

public function getWhenEquationExpr
"function: getWhenEquationExpr
  Get the left and right hand parts from an equation appearing in a when clause"
  input BackendDAE.WhenEquation inWhenEquation;
  output DAE.ComponentRef outComponentRef;
  output DAE.Exp outExp;
algorithm
  (outComponentRef,outExp) := match (inWhenEquation)
    local DAE.ComponentRef cr; DAE.Exp e;
    case (BackendDAE.WHEN_EQ(left = cr,right = e)) then (cr,e);
  end match;
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
  input BackendDAE.BackendDAE inBackendDAE;
  input Integer inInteger;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inBackendDAE,inInteger)
    local
      list<BackendDAE.Value> res;
      list<BackendDAE.ZeroCrossing> zcLst;
      BackendDAE.Value when_index;
    case (BackendDAE.DAE(shared=BackendDAE.SHARED(eventInfo = BackendDAE.EVENT_INFO(zeroCrossingLst = zcLst))),when_index)
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
        count_1 = count + 1;
        resx = getZeroCrossingIndicesFromWhenClause2(rest, count_1, when_index);
      then
        Util.if_(listMember(when_index, whenClauseList), count::resx, resx);
    else
      equation
        print("- BackendEquation.getZeroCrossingIndicesFromWhenClause2 failed\n");
      then
        fail();
  end matchcontinue;
end getZeroCrossingIndicesFromWhenClause2;


public function copyEquationArray
"function: copyEquationArray
  author: wbraun"
  input BackendDAE.EquationArray inEquations;
  output BackendDAE.EquationArray outEquations;
protected
  Integer n,size,arrsize;
  array<Option<BackendDAE.Equation>> arr,arr_1;
algorithm
  BackendDAE.EQUATION_ARRAY(size=size,numberOfElement = n,arrSize = arrsize,equOptArr = arr) := inEquations;
  arr_1 := arrayCreate(arrsize, NONE());
  arr_1 := Util.arrayCopy(arr, arr_1);
  outEquations := BackendDAE.EQUATION_ARRAY(size,n,arrsize,arr_1);
end copyEquationArray;

public function equationsLstVarsWithoutRelations
"function: equationsLstVarsWithoutRelations
  author: Frenkel TUD 2012-03
  From the equations and a variable array return all
  occuring variables form the array."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVars;
  input BackendDAE.Variables inVars1;
  output BackendDAE.Variables outVars;
algorithm
  (_,(_,outVars)) := traverseBackendDAEExpsEqnList(inEquationLst,checkEquationsVarsWithoutRelations,(inVars,inVars1));
end equationsLstVarsWithoutRelations;

public function equationsVarsWithoutRelations
"function: equationsVarsWithoutRelations
  author: Frenkel TUD 2012-03
  From the equations and a variable array return all
  occuring variables form the array without relations."
  input BackendDAE.EquationArray inEquations;
  input BackendDAE.Variables inVars;
  output BackendDAE.Variables outVars;
algorithm
  outVars := BackendDAEUtil.emptyVars();
  ((_,outVars)) := BackendDAEUtil.traverseBackendDAEExpsEqns(inEquations,checkEquationsVarsWithoutRelations,(inVars,outVars));
end equationsVarsWithoutRelations;

protected function checkEquationsVarsWithoutRelations
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local  
      DAE.Exp exp;
      BackendDAE.Variables vars,vars1;
    case ((exp,(vars,vars1)))
      equation
         ((_,(_,vars1))) = Expression.traverseExpWithoutRelations(exp,checkEquationsVarsExp,(vars,vars1));
       then
        ((exp,(vars,vars1)));
    case inTpl then inTpl;
  end matchcontinue;
end checkEquationsVarsWithoutRelations;

public function equationsLstVars
"function: equationsLstVars
  author: Frenkel TUD 2011-05
  From the equations and a variable array return all
  occuring variables form the array."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVars;
  input BackendDAE.Variables inVars1;
  output BackendDAE.Variables outVars;
algorithm
  (_,(_,outVars)) := traverseBackendDAEExpsEqnList(inEquationLst,checkEquationsVars,(inVars,inVars1));
end equationsLstVars;

public function equationsVars
"function: equationsVars
  author: Frenkel TUD 2011-05
  From the equations and a variable array return all
  occuring variables form the array."
  input BackendDAE.EquationArray inEquations;
  input BackendDAE.Variables inVars;
  output BackendDAE.Variables outVars;
algorithm
  outVars := BackendDAEUtil.emptyVars();
  ((_,outVars)) := BackendDAEUtil.traverseBackendDAEExpsEqns(inEquations,checkEquationsVars,(inVars,outVars));
end equationsVars;

public function equationVars
"function: equationVars
  author: Frenkel TUD 2012-03
  From the equation and a variable array return all
  variables in the equation."
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inVars;
  output BackendDAE.Variables outVars;
algorithm
  outVars := BackendDAEUtil.emptyVars();
  (_,(_,outVars)) := traverseBackendDAEExpsEqn(inEquation,checkEquationsVars,(inVars,outVars));
end equationVars;

protected function checkEquationsVars
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local  
      DAE.Exp exp;
      BackendDAE.Variables vars,vars1;
    case ((exp,(vars,vars1)))
      equation
         ((_,(_,vars1))) = Expression.traverseExp(exp,checkEquationsVarsExp,(vars,vars1));
       then
        ((exp,(vars,vars1)));
    case inTpl then inTpl;
  end matchcontinue;
end checkEquationsVars;

protected function checkEquationsVarsExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> inTuple;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e,e1;
      BackendDAE.Variables vars,vars1;
      DAE.ComponentRef cr;
      list<DAE.Exp> expl;
      list<DAE.Var> varLst;
      DAE.Ident ident;
      list<BackendDAE.Var> backendVars;
      BackendDAE.Var var;
      DAE.ReductionIterators riters;
    
    // special case for time, it is never part of the equation system  
    case ((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,vars1)))
      then ((e, (vars,vars1)));
        
    // case for functionpointers    
    case ((e as DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC(builtin=_)),(vars,vars1)))
      then
        ((e, (vars,vars1)));

    // already there
    case ((e as DAE.CREF(componentRef = cr),(vars,vars1)))
      equation
         (_::_,_) = BackendVariable.getVar(cr, vars1);
      then
        ((e, (vars,vars1)));

    // add it
    case ((e as DAE.CREF(componentRef = cr),(vars,vars1)))
      equation
         (backendVars,_) = BackendVariable.getVar(cr, vars);
         vars1 = BackendVariable.addVars(backendVars,vars1);
      then
        ((e, (vars,vars1)));
    
    case inTuple then inTuple;
  end matchcontinue;
end checkEquationsVarsExp;

public function equationsStates
"function: equationsStates
  author: Frenkel TUD
  From a list of equations return all
  occuring state variables references."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVars; 
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  (_,(outExpComponentRefLst,_)) := traverseBackendDAEExpsEqnList(inEquationLst,extractStatesFromExp,({},inVars));
end equationsStates;

protected function extractStatesFromExp "function: extractStatesFromExp
  author: Frenkel TUD 2011-05
  helper for equationsCrefs"
 input tuple<DAE.Exp, tuple<list<DAE.ComponentRef>,BackendDAE.Variables>> inTpl;
 output tuple<DAE.Exp, tuple<list<DAE.ComponentRef>,BackendDAE.Variables>> outTpl;
algorithm 
  outTpl := match(inTpl)
    local 
      tuple<list<DAE.ComponentRef>,BackendDAE.Variables> arg,arg1;
      DAE.Exp e,e1;
    case((e,arg))
      equation
        ((e1,arg1)) = Expression.traverseExp(e, traversingStateRefFinder, arg);
      then
        ((e1,arg1));
  end match;
end extractStatesFromExp;

public function traversingStateRefFinder "
Author: Frenkel TUD 2011-05"
  input tuple<DAE.Exp, tuple<list<DAE.ComponentRef>,BackendDAE.Variables>> inExp;
  output tuple<DAE.Exp, tuple<list<DAE.ComponentRef>,BackendDAE.Variables>> outExp;
algorithm 
  outExp := matchcontinue(inExp)
    local
      BackendDAE.Variables vars;
      list<DAE.ComponentRef> crefs;
      DAE.ComponentRef cr;
      DAE.Exp e;
    
    case((e as DAE.CREF(componentRef=cr), (crefs,vars)))
      equation
        true = BackendVariable.isState(cr,vars);
        crefs = List.unionEltOnTrue(cr,crefs,ComponentReference.crefEqual);
      then
        ((e, (crefs,vars) ));
    
    case(inExp) then inExp;
    
  end matchcontinue;
end traversingStateRefFinder;

public function equationsCrefs
"function: equationsCrefs
  author: PA
  From a list of equations return all
  occuring variables/component references."
  input list<BackendDAE.Equation> inEquationLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  (_,outExpComponentRefLst) := traverseBackendDAEExpsEqnList(inEquationLst,extractCrefsFromExp,{});
end equationsCrefs;

public function getAllCrefFromEquations
  input BackendDAE.EquationArray inEqns;
  output list<DAE.ComponentRef> cr_lst;
algorithm
  cr_lst := traverseBackendDAEEqns(inEqns,traversingEquationCrefFinder,{});
end getAllCrefFromEquations;

protected function traversingEquationCrefFinder
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Equation, list<DAE.ComponentRef>> inTpl;
 output tuple<BackendDAE.Equation, list<DAE.ComponentRef>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Equation e;
      list<DAE.ComponentRef> cr_lst,cr_lst1;
    case ((e,cr_lst))
      equation
        (_,cr_lst1) = traverseBackendDAEExpsEqn(e,extractCrefsFromExp,cr_lst);
      then ((e,cr_lst1));
    case inTpl then inTpl;
  end matchcontinue;
end traversingEquationCrefFinder;

protected function extractCrefsFromExp "function: extractCrefsFromExp
  author: Frenkel TUD 2010-11
  helper for equationsCrefs"
 input tuple<DAE.Exp, list<DAE.ComponentRef>> inTpl;
 output tuple<DAE.Exp, list<DAE.ComponentRef>> outTpl;
algorithm 
  outTpl := match(inTpl)
    local 
      list<DAE.ComponentRef> crefs,crefs1;
      DAE.Exp e,e1;
    case((e,crefs))
      equation
        ((e1,crefs1)) = Expression.traverseExp(e, Expression.traversingComponentRefFinder, crefs);
      then
        ((e1,crefs1));
  end match;
end extractCrefsFromExp;

public function equationUnknownCrefs
"function: equationUnknownVars
  author: Frenkel TUD 2012-05
  From the equation and a variable array return all
  variables in the equation an not in the variable array."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVars;
  input BackendDAE.Variables inKnVars;
  output list<DAE.ComponentRef> cr_lst;
protected
  HashTable.HashTable ht;
algorithm
  ht := HashTable.emptyHashTable();
  (_,(_,_,ht)) := traverseBackendDAEExpsEqnList(inEquationLst,checkEquationsUnknownCrefs,(inVars,inKnVars,ht));
  cr_lst := BaseHashTable.hashTableKeyList(ht);
end equationUnknownCrefs;

protected function checkEquationsUnknownCrefs
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables,HashTable.HashTable>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables,HashTable.HashTable>> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local  
      DAE.Exp exp;
      tuple<BackendDAE.Variables,BackendDAE.Variables,HashTable.HashTable> tpl;
    case ((exp,tpl))
      equation
         ((_,tpl)) = Expression.traverseExp(exp,checkEquationsUnknownCrefsExp,tpl);
       then
        ((exp,tpl));
    case inTpl then inTpl;
  end matchcontinue;
end checkEquationsUnknownCrefs;

protected function checkEquationsUnknownCrefsExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables,HashTable.HashTable>> inTuple;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,BackendDAE.Variables,HashTable.HashTable>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e,e1;
      BackendDAE.Variables vars,knvars;
      HashTable.HashTable ht;
      DAE.ComponentRef cr;
      list<DAE.Exp> expl;
      list<DAE.Var> varLst;
      DAE.Ident ident;
      list<BackendDAE.Var> backendVars;
      BackendDAE.Var var;
      DAE.ReductionIterators riters;
    
    // special case for time, it is never part of the equation system  
    case ((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),(vars,knvars,ht)))
      then ((e, (vars,knvars,ht)));
    
    // Special Case for Records
    case ((e as DAE.CREF(componentRef = cr,ty= DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),(vars,knvars,ht)))
      equation
        expl = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        ((_,(vars,knvars,ht))) = Expression.traverseExpList(expl,checkEquationsUnknownCrefsExp,(vars,knvars,ht));
      then
        ((e, (vars,knvars,ht)));

    // Special Case for Arrays
    case ((e as DAE.CREF(ty = DAE.T_ARRAY(ty=_)),(vars,knvars,ht)))
      equation
        ((e1,(_,true))) = BackendDAEUtil.extendArrExp((e,(NONE(),false)));
        ((_,(vars,knvars,ht))) = Expression.traverseExp(e1,checkEquationsUnknownCrefsExp,(vars,knvars,ht));
      then
        ((e, (vars,knvars,ht)));
    
    // case for functionpointers    
    case ((e as DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC(builtin=_)),(vars,knvars,ht)))
      then
        ((e, (vars,knvars,ht)));

    // already there
    case ((e as DAE.CREF(componentRef = cr),(vars,knvars,ht)))
      equation
         _ = BaseHashTable.get(cr,ht);
      then
        ((e, (vars,knvars,ht)));

    // known
    case ((e as DAE.CREF(componentRef = cr),(vars,knvars,ht)))
      equation
         (_,_) = BackendVariable.getVar(cr, vars);
      then
        ((e, (vars,knvars,ht)));
    case ((e as DAE.CREF(componentRef = cr),(vars,knvars,ht)))
      equation
         (_,_) = BackendVariable.getVar(cr, knvars);
      then
        ((e, (vars,knvars,ht)));
        
    // add it
    case ((e as DAE.CREF(componentRef = cr),(vars,knvars,ht)))
      equation
         ht = BaseHashTable.add((cr,0),ht);
      then
        ((e, (vars,knvars,ht)));
    
    case inTuple then inTuple;
  end matchcontinue;
end checkEquationsUnknownCrefsExp;

public function traverseBackendDAEExpsEqnList"function: traverseBackendDAEExpsEqnList
  author: Frenkel TUD 2010-11
  traverse all expressions of a list of Equations. It is possible to change the equations"
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.Equation> inEquations;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<BackendDAE.Equation> outEquations;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquations,outTypeA) := List.map1Fold(inEquations,traverseBackendDAEExpsEqn,func,inTypeA);
end traverseBackendDAEExpsEqnList;

public function traverseBackendDAEExpsEqn "function: traverseBackendDAEExpsEqn
  author: Frenkel TUD 2010-11
  traverse all expressions of a Equation. It is possible to change the equation"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Equation inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.Equation outEquation;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquation,outTypeA):= match (inEquation,func,inTypeA)
    local
      DAE.Exp e1,e2,e_1,e_2;
      list<DAE.Exp> expl;
      DAE.Type tp;
      DAE.ComponentRef cr,cr1;
      BackendDAE.WhenEquation elsePart,elsePart1;
      DAE.ElementSource source;
      Integer index,size;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
      list<Integer> dimSize;
      DAE.Algorithm alg;
      list<DAE.Statement> stmts,stmts1;
      list<BackendDAE.Equation> eqns;
      list<list<BackendDAE.Equation>> eqnslst;      
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source=source),func,inTypeA)
      equation
        ((e_1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.EQUATION(e_1,e_2,source),ext_arg_2);
    case (BackendDAE.ARRAY_EQUATION(dimSize=dimSize,left = e1,right = e2,source=source),func,inTypeA)
      equation
        ((e_1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.ARRAY_EQUATION(dimSize,e_1,e_2,source),ext_arg_2);        
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2,source=source),func,inTypeA)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.SOLVED_EQUATION(cr1,e_2,source),ext_arg_2);
    case (BackendDAE.RESIDUAL_EQUATION(exp = e1,source=source),func,inTypeA)
      equation
        ((e_1,ext_arg_1)) = func((e1,inTypeA));
      then
        (BackendDAE.RESIDUAL_EQUATION(e_1,source),ext_arg_1);
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index=index,left = cr,right = e2,elsewhenPart=NONE()),source = source),func,inTypeA)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
      then
       (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(index,cr1,e_2,NONE()),source),ext_arg_2);
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index=index,left=cr,right=e2,elsewhenPart=SOME(elsePart)),source = source),func,inTypeA)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
        (BackendDAE.WHEN_EQUATION(whenEquation=elsePart1),ext_arg_3) = traverseBackendDAEExpsEqn(BackendDAE.WHEN_EQUATION(elsePart,source),func,ext_arg_2);
      then
        (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(index,cr1,e_2,SOME(elsePart1)),source),ext_arg_3);
    case (BackendDAE.ALGORITHM(size=size,alg=alg as DAE.ALGORITHM_STMTS(statementLst = stmts),source=source),func,inTypeA)
      equation
        (stmts1,ext_arg_1) = DAEUtil.traverseDAEEquationsStmts(stmts,func,inTypeA);
        alg = Util.if_(referenceEq(stmts,stmts1),alg,DAE.ALGORITHM_STMTS(stmts1));
      then
        (BackendDAE.ALGORITHM(size,alg,source),ext_arg_1);        
    case (BackendDAE.COMPLEX_EQUATION(size=size,left = e1,right = e2,source=source),func,inTypeA)
      equation
        ((e_1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.COMPLEX_EQUATION(size,e_1,e_2,source),ext_arg_2); 
        
    case (BackendDAE.IF_EQUATION(conditions=expl, eqnstrue=eqnslst, eqnsfalse=eqns, source=source),func,inTypeA)
      equation
        (expl,ext_arg_1) = traverseBackendDAEExpList(expl,func,inTypeA);
        (eqnslst,ext_arg_2) = List.map1Fold(eqnslst,traverseBackendDAEExpsEqnList,func,ext_arg_1);
        (eqns,ext_arg_2) = List.map1Fold(eqns,traverseBackendDAEExpsEqn,func,ext_arg_2);
      then
        (BackendDAE.IF_EQUATION(expl,eqnslst,eqns,source),ext_arg_2);         
  end match;
end traverseBackendDAEExpsEqn;

public function traverseBackendDAEExpsEqnListOutEqn
"function: traverseBackendDAEExpsEqnList
  author: Frenkel TUD 2010-11
  traverse all expressions of a list of Equations. It is possible to change the equations"
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.Equation> inEquations;
  input list<BackendDAE.Equation> inlistchangedEquations;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<BackendDAE.Equation> outEquations;
  output list<BackendDAE.Equation> outchangedEquations;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquations,outchangedEquations,outTypeA) := match(inEquations,inlistchangedEquations,func,inTypeA)
  local 
       BackendDAE.Equation e,e1;
       list<BackendDAE.Equation> res,eqns, changedeqns;
       Type_a ext_arg_1,ext_arg_2;
       Boolean b;
    case({},changedeqns,func,inTypeA) then ({},changedeqns,inTypeA);
    case(e::res,changedeqns,func,inTypeA)
     equation
      (e1,b,ext_arg_1) = traverseBackendDAEExpsEqnOutEqn(e,func,inTypeA);
      changedeqns = List.consOnTrue(b, e1, changedeqns);
      (eqns,changedeqns,ext_arg_2)  = traverseBackendDAEExpsEqnListOutEqn(res,changedeqns,func,ext_arg_1);
    then 
      (e1::eqns,changedeqns,ext_arg_2);
    end match;
end traverseBackendDAEExpsEqnListOutEqn;

public function traverseBackendDAEExpsEqnOutEqn
 "function: traverseBackendDAEExpsEqnOutEqn
  copy of traverseBackendDAEExpsEqn
  author: Frenkel TUD 2010-11
  traverse all expressions of a Equation. It is possible to change the equation.
  additinal the equation is passed to FuncExpTyp.
  "
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Equation inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.Equation outEquation;
  output Boolean outflag;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquation,outflag,outTypeA):= match (inEquation,func,inTypeA)
    local
      DAE.Exp e1,e2,e_1,e_2;
      list<DAE.Exp> expl,exps;
      DAE.Type tp;
      DAE.ComponentRef cr,cr1;
      BackendDAE.WhenEquation elsePart,elsePart1;
      DAE.ElementSource source;
      Integer index,size;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
      BackendDAE.Equation eq;
      Boolean b1,b2,b3,bres;
      list<Integer> dimSize;
      DAE.Algorithm alg;
      list<list<BackendDAE.Equation>> eqnstrue;
      list<BackendDAE.Equation> eqnsfalse;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source=source),func,inTypeA)
      equation
        ((e_1,b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        bres = Util.boolOrList({b1,b2});
      then
        (BackendDAE.EQUATION(e_1,e_2,source),bres,ext_arg_2);
    case (BackendDAE.ARRAY_EQUATION(dimSize=dimSize,left = e1,right = e2,source=source),func,inTypeA)
      equation
        ((e_1,b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        bres = Util.boolOrList({b1,b2});
      then
        (BackendDAE.ARRAY_EQUATION(dimSize,e_1,e_2,source),bres,ext_arg_2);
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2,source=source),func,inTypeA)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        bres = Util.boolOrList({b1,b2});
      then
        (BackendDAE.SOLVED_EQUATION(cr1,e_2,source),bres,ext_arg_2);
    case (eq as BackendDAE.RESIDUAL_EQUATION(exp = e1,source=source),func,inTypeA)
      equation
        ((e_1,b1,ext_arg_1)) = func((e1,inTypeA));
      then
        (BackendDAE.RESIDUAL_EQUATION(e_1,source),b1,ext_arg_1);
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index=index,left = cr,right = e2,elsewhenPart=NONE()),source = source),func,inTypeA)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        bres = Util.boolOrList({b1,b2});
      then
       (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(index,cr1,e_2,NONE()),source),bres,ext_arg_2);
    case (eq as BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index=index,left=cr,right=e2,elsewhenPart=SOME(elsePart)),source = source),func,inTypeA)
      equation
        tp = Expression.typeof(e2);
        e1 = Expression.makeCrefExp(cr,tp);
        ((DAE.CREF(cr1,_),b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        (BackendDAE.WHEN_EQUATION(whenEquation=elsePart1),b3,ext_arg_3) = traverseBackendDAEExpsEqnOutEqn(BackendDAE.WHEN_EQUATION(elsePart,source),func,ext_arg_2);
        bres = Util.boolOrList({b1,b2,b3});
      then
        (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(index,cr1,e_2,SOME(elsePart1)),source),bres,ext_arg_3);
    case (BackendDAE.ALGORITHM(size=size,alg=alg,source=source),func,inTypeA)
      then
        (BackendDAE.ALGORITHM(size,alg,source),false,inTypeA);
    case (BackendDAE.COMPLEX_EQUATION(size=size,left = e1,right = e2,source=source),func,inTypeA)
      equation
        ((e_1,b1,ext_arg_1)) = func((e1,inTypeA));
        ((e_2,b2,ext_arg_2)) = func((e2,ext_arg_1));
        bres = Util.boolOrList({b1,b2});
      then
        (BackendDAE.COMPLEX_EQUATION(size,e_1,e_2,source),bres,ext_arg_2);
    case (BackendDAE.IF_EQUATION(conditions = expl, eqnstrue = eqnstrue, eqnsfalse = eqnsfalse,source=source),func,inTypeA)
      equation
        //(expl,ext_arg_1) = traverseBackendDAEExpList(expl,func,inTypeA);
        //(eqnslst,ext_arg_2) = List.map1Fold(eqnslst,traverseBackendDAEExpsEqnList,func,ext_arg_1);
        //(eqnsfalse,ext_arg_2) = traverseBackendDAEExpsEqnListOutEqn(eqnsfalse,func,ext_arg_2);
      then
        (BackendDAE.IF_EQUATION(expl,eqnstrue,eqnsfalse,source),false,inTypeA);        
  end match;
end traverseBackendDAEExpsEqnOutEqn;

public function traverseBackendDAEExpList
"function traverseBackendDAEExps
 author Frenkel TUD:
 Calls user function for each element of list."
  replaceable type Type_a subtypeof Any;
  input list<DAE.Exp> inExpl;
  input FuncExpType rel;
  input Type_a ext_arg;
  output list<DAE.Exp> outExpl;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outExpl,outTypeA) := match(inExpl,rel,ext_arg)
  local 
      DAE.Exp e,e1;
      list<DAE.Exp> expl1,res;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
    case({},_,ext_arg_1) then ({},ext_arg_1);
    case(e::res,rel,ext_arg_1) equation
      ((e1,ext_arg_2)) = rel((e, ext_arg_1));
      (expl1,ext_arg_3) = traverseBackendDAEExpList(res,rel,ext_arg_2);
    then (e1::expl1,ext_arg_3);
  end match;
end traverseBackendDAEExpList;

public function traverseBackendDAEEqns "function: traverseBackendDAEEqns
  author: Frenkel TUD

  traverses all equations of a BackendDAE.EquationArray.
"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.EquationArray inEquationArray;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Equation, Type_a> inTpl;
    output tuple<BackendDAE.Equation, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA :=
  matchcontinue (inEquationArray,func,inTypeA)
    local
      array<Option<BackendDAE.Equation>> equOptArr;
    case ((BackendDAE.EQUATION_ARRAY(equOptArr = equOptArr)),func,inTypeA)
      then BackendDAEUtil.traverseBackendDAEArrayNoCopy(equOptArr,func,traverseBackendDAEOptEqn,1,arrayLength(equOptArr),inTypeA);
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendEquation.traverseBackendDAEEqns failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEEqns;

protected function traverseBackendDAEOptEqn "function: traverseBackendDAEOptEqn
  author: Frenkel TUD 2010-11
  Helper for traverseBackendDAEExpsEqns."
  replaceable type Type_a subtypeof Any;
  input Option<BackendDAE.Equation> inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Equation, Type_a> inTpl;
    output tuple<BackendDAE.Equation, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA:=  matchcontinue (inEquation,func,inTypeA)
    local
      BackendDAE.Equation eqn;
     Type_a ext_arg;
    case (NONE(),func,inTypeA) then inTypeA;
    case (SOME(eqn),func,inTypeA)
      equation
        ((_,ext_arg)) = func((eqn,inTypeA));
      then
        ext_arg;
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendEquation.traverseBackendDAEOptEqn failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEOptEqn;

public function traverseBackendDAEEqnsWithStop "function: traverseBackendDAEEqns
  author: Frenkel TUD

  traverses all equations of a BackendDAE.EquationArray.
"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.EquationArray inEquationArray;
  input FuncExpType func;
  input Type_a inTypeA;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Equation, Type_a> inTpl;
    output tuple<BackendDAE.Equation, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  outTypeA :=
  matchcontinue (inEquationArray,func,inTypeA)
    local
      array<Option<BackendDAE.Equation>> equOptArr;
    case ((BackendDAE.EQUATION_ARRAY(equOptArr = equOptArr)),func,inTypeA)
      then BackendDAEUtil.traverseBackendDAEArrayNoCopyWithStop(equOptArr,func,traverseBackendDAEOptEqnWithStop,1,arrayLength(equOptArr),inTypeA);
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendEquation.traverseBackendDAEEqnsWithStop failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEEqnsWithStop;

protected function traverseBackendDAEOptEqnWithStop "function: traverseBackendDAEOptEqnWithStop
  author: Frenkel TUD 2010-11
  Helper for traverseBackendDAEExpsEqnsWithStop."
  replaceable type Type_a subtypeof Any;
  input Option<BackendDAE.Equation> inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output Boolean outBoolean;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Equation, Type_a> inTpl;
    output tuple<BackendDAE.Equation, Boolean, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outBoolean,outTypeA):=  matchcontinue (inEquation,func,inTypeA)
    local
      BackendDAE.Equation eqn;
     Type_a ext_arg;
     Boolean b;
    case (NONE(),func,inTypeA) then (true,inTypeA);
    case (SOME(eqn),func,inTypeA)
      equation
        ((_,b,ext_arg)) = func((eqn,inTypeA));
      then
        (b,ext_arg);
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendEquation.traverseBackendDAEOptEqnWithStop failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEOptEqnWithStop;

public function traverseBackendDAEEqnsWithUpdate "function: traverseBackendDAEEqnsWithUpdate
  author: Frenkel TUD

  traverses all equations of a BackendDAE.EquationArray.
"
  replaceable type Type_a subtypeof Any;
  input BackendDAE.EquationArray inEquationArray;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.EquationArray outEquationArray;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Equation, Type_a> inTpl;
    output tuple<BackendDAE.Equation, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquationArray,outTypeA) :=
  matchcontinue (inEquationArray,func,inTypeA)
    local
      Integer numberOfElement, arrSize, size;
      array<Option<BackendDAE.Equation>> equOptArr;
      Type_a ext_arg;
    case ((BackendDAE.EQUATION_ARRAY(size=size,numberOfElement=numberOfElement,arrSize=arrSize,equOptArr = equOptArr)),func,inTypeA)
      equation
        (equOptArr,ext_arg) = BackendDAEUtil.traverseBackendDAEArrayNoCopyWithUpdate(equOptArr,func,traverseBackendDAEOptEqnWithUpdate,1,arrayLength(equOptArr),inTypeA);
      then (BackendDAE.EQUATION_ARRAY(size,numberOfElement,arrSize,equOptArr),ext_arg);
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendEquation.traverseBackendDAEEqnsWithStop failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEEqnsWithUpdate;

protected function traverseBackendDAEOptEqnWithUpdate "function: traverseBackendDAEOptEqnWithUpdate
  author: Frenkel TUD 2010-11
  Helper for traverseBackendDAEExpsEqnsWithUpdate."
  replaceable type Type_a subtypeof Any;
  input Option<BackendDAE.Equation> inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output Option<BackendDAE.Equation> outEquation;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<BackendDAE.Equation, Type_a> inTpl;
    output tuple<BackendDAE.Equation, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquation,outTypeA):=  matchcontinue (inEquation,func,inTypeA)
    local
      Option<BackendDAE.Equation> oeqn;
      BackendDAE.Equation eqn,eqn1;
     Type_a ext_arg;
    case (oeqn as NONE(),func,inTypeA) then (oeqn,inTypeA);
    case (oeqn as SOME(eqn),func,inTypeA)
      equation
        ((eqn1,ext_arg)) = func((eqn,inTypeA));
        oeqn = Util.if_(referenceEq(eqn,eqn1),oeqn,SOME(eqn1));
      then
        (oeqn,ext_arg);
    case (_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendEquation.traverseBackendDAEOptEqnWithUpdate failed");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEOptEqnWithUpdate;

public function equationEqual "Returns true if two equations are equal"
  input BackendDAE.Equation e1;
  input BackendDAE.Equation e2;
  output Boolean res;
algorithm
  res := matchcontinue(e1,e2)
    local
      DAE.Exp e11,e12,e21,e22,exp1,exp2;
      DAE.ComponentRef cr1,cr2;
      DAE.Algorithm alg1,alg2;
      list<DAE.Exp> explst1,explst2;
      Integer i1,i2;
    case (_,_)
      equation
        true = referenceEq(e1,e2);
      then 
        true;
    case (BackendDAE.EQUATION(exp = e11,scalar = e12),
          BackendDAE.EQUATION(exp = e21, scalar = e22))
      equation
        res = boolAnd(Expression.expEqual(e11,e21),Expression.expEqual(e12,e22));
      then res;

    case (BackendDAE.ARRAY_EQUATION(left = e11,right = e12),
          BackendDAE.ARRAY_EQUATION(left = e21,right = e22))
      equation
        res = boolAnd(Expression.expEqual(e11,e21),Expression.expEqual(e12,e22));
      then res;

    case (BackendDAE.COMPLEX_EQUATION(left = e11,right = e12),
          BackendDAE.COMPLEX_EQUATION(left = e21,right = e22))
      equation
        res = boolAnd(Expression.expEqual(e11,e21),Expression.expEqual(e12,e22));
      then res;

    case(BackendDAE.SOLVED_EQUATION(componentRef = cr1,exp = exp1),
         BackendDAE.SOLVED_EQUATION(componentRef = cr2,exp = exp2))
      equation
        res = boolAnd(ComponentReference.crefEqualNoStringCompare(cr1,cr2),Expression.expEqual(exp1,exp2));
      then res;

    case(BackendDAE.RESIDUAL_EQUATION(exp = exp1),
         BackendDAE.RESIDUAL_EQUATION(exp = exp2))
      equation
        res = Expression.expEqual(exp1,exp2);
      then res;

    case(BackendDAE.ALGORITHM(alg = alg1),
         BackendDAE.ALGORITHM(alg = alg2))
      equation
        explst1 = Algorithm.getAllExps(alg1);
        explst2 = Algorithm.getAllExps(alg2);
        res = List.isEqualOnTrue(explst1, explst2, Expression.expEqual);
      then res;

    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index = i1)),
          BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index = i2)))
      equation
        res = intEq(i1,i2);
      then res;

    case(_,_) then false;

  end matchcontinue;
end equationEqual;

public function addEquations "function: addEquations
  author: wbraun
  Adds a list of BackendDAE.Equation to BackendDAE.EquationArray"
  input list<BackendDAE.Equation> eqnlst;
  input BackendDAE.EquationArray eqns;
  output BackendDAE.EquationArray eqns_1;
algorithm
  eqns_1 := List.fold(eqnlst, equationAdd, eqns);
end addEquations;

public function equationAdd "function: equationAdd
  author: PA

  Adds an equation to an EquationArray.
"
  input BackendDAE.Equation inEquation;
  input BackendDAE.EquationArray inEquationArray;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray:=
  matchcontinue (inEquation,inEquationArray)
    local
      Integer n_1,n,arrsize,expandsize,expandsize_1,newsize,size;
      array<Option<BackendDAE.Equation>> arr_1,arr,arr_2;
      BackendDAE.Equation e;
      Real rsize,rexpandsize;
    case (e,BackendDAE.EQUATION_ARRAY(size=size,numberOfElement = n,arrSize = arrsize,equOptArr = arr))
      equation
        (n < arrsize) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n_1, SOME(e));
        size = equationSize(e) + size;
      then
        BackendDAE.EQUATION_ARRAY(size,n_1,arrsize,arr_1);
    case (e,BackendDAE.EQUATION_ARRAY(size=size,numberOfElement = n,arrSize = arrsize,equOptArr = arr)) /* Do NOT Have space to add array elt. Expand array 1.4 times */
      equation
        (n < arrsize) = false;
        rsize = intReal(arrsize);
        rexpandsize = rsize *. 0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + arrsize;
        arr_1 = Util.arrayExpand(expandsize_1, arr,NONE());
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n_1, SOME(e));
        size = equationSize(e) + size;
      then
        BackendDAE.EQUATION_ARRAY(size,n_1,newsize,arr_2);
    case (_,BackendDAE.EQUATION_ARRAY(size=size,numberOfElement = n,arrSize = arrsize,equOptArr = arr))
      equation
        print("- BackendEquation.equationAdd failed\nArraySize: " +& intString(arrsize) +& 
            "\nnumberOfElement " +& intString(n) +& "\nSize " +& intString(size));
      then
        fail();
  end matchcontinue;
end equationAdd;

public function equationAddDAE
"function: equationAddDAE
  author: Frenkel TUD 2011-05"
  input BackendDAE.Equation inEquation;
  input BackendDAE.EqSystem syst;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (inEquation,syst)
    local
      BackendDAE.Variables ordvars;
      BackendDAE.EquationArray eqns,eqns1;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
    case (inEquation,BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns,m=m,mT=mT))
      equation
        eqns1 = equationAdd(inEquation,eqns);
      then BackendDAE.EQSYSTEM(ordvars,eqns1,m,mT,BackendDAE.NO_MATCHING());
  end match;
end equationAddDAE;

public function equationsAddDAE
"function: equationAddDAE
  author: Frenkel TUD 2011-05"
  input list<BackendDAE.Equation> inEquations;
  input BackendDAE.EqSystem syst;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (inEquations,syst)
    local
      BackendDAE.Variables ordvars;
      BackendDAE.EquationArray eqns,eqns1;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
    case (_,BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns,m=m,mT=mT))
      equation
        eqns1 = List.fold(inEquations,equationAdd,eqns);
      then BackendDAE.EQSYSTEM(ordvars,eqns1,m,mT,BackendDAE.NO_MATCHING());
  end match;
end equationsAddDAE;

public function equationSetnthDAE
  "Note: Does not update the incidence matrix (just like equationSetnth).
  Call BackendDAEUtil.updateIncidenceMatrix if the inc.matrix changes."
  input Integer inInteger;
  input BackendDAE.Equation inEquation;
  input BackendDAE.EqSystem syst;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (inInteger,inEquation,syst)
    local
      BackendDAE.Variables ordvars,knvars,exobj;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.Shared shared;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Matching matching;
    case (inInteger,inEquation,BackendDAE.EQSYSTEM(ordvars,eqns,m,mT,matching))
      equation
        eqns1 = equationSetnth(eqns,inInteger,inEquation);
      then BackendDAE.EQSYSTEM(ordvars,eqns1,m,mT,matching);
  end match;
end equationSetnthDAE;

public function equationSetnth
  "Sets the nth array element of an EquationArray."
  input BackendDAE.EquationArray inEquationArray;
  input Integer inInteger;
  input BackendDAE.Equation inEquation;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray := match (inEquationArray,inInteger,inEquation)
    local
      array<Option<BackendDAE.Equation>> arr_1,arr;
      Integer n,arrsize,pos,size;
      BackendDAE.Equation eqn;
    case (BackendDAE.EQUATION_ARRAY(size=size,numberOfElement = n,arrSize = arrsize,equOptArr = arr),pos,eqn)
      equation
        pos = pos+1;
        size = size - equationOptSize(arr[pos]) + equationSize(eqn);
        arr_1 = arrayUpdate(arr, pos, SOME(eqn));
      then
        BackendDAE.EQUATION_ARRAY(size,n,arrsize,arr_1);
  end match;
end equationSetnth;

public function getEqns "function: getEqns
  author: Frenkel TUD 2011-05
  retursn the equations given by the list of indexes"
  input list<BackendDAE.Value> inIndxes;
  input BackendDAE.EquationArray inEquationArray;
  output list<BackendDAE.Equation> outEqns;
protected
  list<BackendDAE.Value> indxs;
algorithm
  indxs := List.map1(inIndxes, intSub, 1);
  outEqns := List.map1r(indxs, BackendDAEUtil.equationNth, inEquationArray);  
end getEqns;
  
public function equationDeleteDAE
"function: equationDeleteDAE
  author: Frenkel TUD 2011-05"
  input list<Integer> inIntLst;
  input BackendDAE.EqSystem syst;
  output BackendDAE.EqSystem osyst;
algorithm
  osyst := match (inIntLst,syst)
    local
      BackendDAE.Variables ordvars;
      BackendDAE.EquationArray eqns,eqns1;
      Option<BackendDAE.IncidenceMatrix> m;
      Option<BackendDAE.IncidenceMatrixT> mT;
    case (_,BackendDAE.EQSYSTEM(orderedVars=ordvars,orderedEqs=eqns,m=m,mT=mT))
      equation
        eqns1 = equationDelete(eqns,inIntLst);
      then BackendDAE.EQSYSTEM(ordvars,eqns1,m,mT,BackendDAE.NO_MATCHING());
  end match;
end equationDeleteDAE;  
  
public function equationDelete "function: equationDelete
  author: Frenkel TUD 2010-12
  Delets the equations from the list of Integers."
  input BackendDAE.EquationArray inEquationArray;
  input list<Integer> inIntLst;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray := match (inEquationArray,inIntLst)
    local
      list<BackendDAE.Equation> eqnlst,eqnlst1;
    case (inEquationArray,{})
      then
        inEquationArray;
    case (inEquationArray,inIntLst)
      equation
        eqnlst = BackendDAEUtil.equationList(inEquationArray);
        eqnlst1 = List.deletePositions(eqnlst,inIntLst);
        outEquationArray =  BackendDAEUtil.listEquation(eqnlst1);
      then
        outEquationArray;
  end match;   
end equationDelete;

public function equationToScalarResidualForm "function: equationToScalarResidualForm
  author: Frenkel TUD 2012-06
  This function transforms an equation to its scalar residual form.
  For instance, a=b is transformed to a-b=0, and the instance {a[1],a[2]}=b to a[1]=b[1] and a[2]=b[2]"
  input BackendDAE.Equation inEquation;
  output list<BackendDAE.Equation> outEquations;
algorithm
  outEquations := matchcontinue (inEquation)
    local
      DAE.Exp e,e1,e2,exp;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      BackendDAE.Equation backendEq;
      list<Integer> ds;
      list<Option<Integer>> ad;
      list<DAE.Exp> explst;
      list<BackendDAE.Equation> eqns;
      list<list<DAE.Subscript>> subslst;
    
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source = source))
      equation
        //ExpressionDump.dumpExpWithTitle("equationToResidualForm 1\n",e2);
        exp = Expression.expSub(e1,e2);
        (e,_) = ExpressionSimplify.simplify(exp);
      then
        {BackendDAE.RESIDUAL_EQUATION(e,source)};
    
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2,source = source))
      equation
        e1 = Expression.crefExp(cr);
        exp = Expression.expSub(e1,e2);
        (e,_) = ExpressionSimplify.simplify(exp);
      then
        {BackendDAE.RESIDUAL_EQUATION(e,source)};
    
    case (BackendDAE.ARRAY_EQUATION(dimSize=ds,left=e1, right=e2,source=source))
      equation
        exp = Expression.expSub(e1,e2);
        ad = List.map(ds,Util.makeOption);
        subslst = BackendDAEUtil.arrayDimensionsToRange(ad);
        subslst = BackendDAEUtil.rangesToSubscripts(subslst);
        explst = List.map1r(subslst,Expression.applyExpSubscripts,exp);
        explst = ExpressionSimplify.simplifyList(explst, {});
        eqns = List.map1(explst,generateRESIDUAL_EQUATION,source);
      then eqns;          
      
    case (backendEq as BackendDAE.COMPLEX_EQUATION(source = source)) then {backendEq};
    
    case (backendEq as BackendDAE.RESIDUAL_EQUATION(exp = _,source = source)) then {backendEq};
    
    case (backendEq as BackendDAE.ALGORITHM(alg = _)) then {backendEq};
    
    case (backendEq as BackendDAE.WHEN_EQUATION(whenEquation = _)) then {backendEq};
    
    case (backendEq)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendDAE.equationToScalarResidualForm failed");
      then
        fail();
  end matchcontinue;
end equationToScalarResidualForm;

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
      DAE.ElementSource source;
      BackendDAE.Equation backendEq;
    
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source = source))
      equation
        //ExpressionDump.dumpExpWithTitle("equationToResidualForm 1\n",e2);
        exp = Expression.expSub(e1,e2);
        (e,_) = ExpressionSimplify.simplify(exp);
      then
        BackendDAE.RESIDUAL_EQUATION(e,source);
    
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2,source = source))
      equation
        e1 = Expression.crefExp(cr);
        exp = Expression.expSub(e1,e2);
        (e,_) = ExpressionSimplify.simplify(exp);
      then
        BackendDAE.RESIDUAL_EQUATION(e,source);
    
    case (BackendDAE.ARRAY_EQUATION(left = e1,right = e2,source = source))
      equation
        exp = Expression.expSub(e1,e2);
        (e,_) = ExpressionSimplify.simplify(exp);        
      then
        BackendDAE.RESIDUAL_EQUATION(e,source);    
    
    case (BackendDAE.COMPLEX_EQUATION(left = e1,right = e2,source = source))
      equation
         exp = Expression.expSub(e1,e2);
        (e,_) = ExpressionSimplify.simplify(exp);
      then
        BackendDAE.RESIDUAL_EQUATION(e,source);     
    
    case (backendEq as BackendDAE.RESIDUAL_EQUATION(exp = _,source = source)) then backendEq;
    
    case (backendEq as BackendDAE.ALGORITHM(alg = _)) then backendEq;
    
    case (backendEq as BackendDAE.WHEN_EQUATION(whenEquation = _)) then backendEq;
    
    case (backendEq)
      equation
        Debug.fprintln(Flags.FAILTRACE, "- BackendDAE.equationToResidualForm failed");
      then
        fail();
  end matchcontinue;
end equationToResidualForm;

public function equationToExp
  input tuple<BackendDAE.Equation, tuple<BackendDAE.Variables,list<DAE.Exp>,list<DAE.ElementSource>>> inTpl;
  output tuple<BackendDAE.Equation, tuple<BackendDAE.Variables,list<DAE.Exp>,list<DAE.ElementSource>>> outTpl;  
algorithm
  outTpl := matchcontinue inTpl
    local
      Integer   index;
      DAE.Exp e;
      DAE.Exp e1,e2,new_exp,new_exp1,rhs_exp,rhs_exp_1,rhs_exp_2;
      list<Integer> ds;
      list<Option<Integer>> ad;
      list<DAE.Subscript> subs;
      BackendDAE.Equation eqn;
      BackendDAE.Variables v;
      list<DAE.Exp> explst,explst1;
      list<DAE.ElementSource> sources;
      DAE.ElementSource source;
      String str;
      list<list<DAE.Subscript>> subslst;
      
    case ((eqn as BackendDAE.RESIDUAL_EQUATION(exp=e,source=source),(v,explst,sources)))
      equation
        rhs_exp = BackendDAEUtil.getEqnsysRhsExp(e, v);
        (rhs_exp_1,_) = ExpressionSimplify.simplify(rhs_exp);
      then ((eqn,(v,rhs_exp_1::explst,source::sources)));
        
    case ((eqn as BackendDAE.EQUATION(exp=e1, scalar=e2,source=source),(v,explst,sources)))
      equation
        new_exp = Expression.expSub(e1,e2);
        rhs_exp = BackendDAEUtil.getEqnsysRhsExp(new_exp, v);
        rhs_exp_1 = Expression.negate(rhs_exp);
        (rhs_exp_2,_) = ExpressionSimplify.simplify(rhs_exp_1);
      then ((eqn,(v,rhs_exp_2::explst,source::sources)));
       
    case ((eqn as BackendDAE.ARRAY_EQUATION(dimSize=ds,left=e1, right=e2,source=source),(v,explst,sources)))
      equation
        new_exp = Expression.expSub(e1,e2);
        ad = List.map(ds,Util.makeOption);
        subslst = BackendDAEUtil.arrayDimensionsToRange(ad);
        subslst = BackendDAEUtil.rangesToSubscripts(subslst);
        explst1 = List.map1r(subslst,Expression.applyExpSubscripts,new_exp);
        explst1 = List.map1(explst1,BackendDAEUtil.getEqnsysRhsExp,v);
        explst1 = List.map(explst1,Expression.negate);
        explst1 = ExpressionSimplify.simplifyList(explst1, {});
        explst = listAppend(listReverse(explst1),explst);
        sources = List.consN(equationSize(eqn), source, sources);
      then ((eqn,(v,explst,sources)));       
       
    case ((eqn as BackendDAE.COMPLEX_EQUATION(source=source),(v,explst,sources)))
      equation
        str = BackendDump.equationStr(eqn);
        str = "BackendEquation.equationToExp failed: " +& str;
        Error.addSourceMessage(Error.INTERNAL_ERROR,{str},equationInfo(eqn));
      then fail();       
        
    case ((eqn,_))
      equation
        str = BackendDump.equationStr(eqn);
        str = "BackendEquation.equationToExp failed: " +& str;
        Error.addSourceMessage(Error.INTERNAL_ERROR,{str},equationInfo(eqn));
      then
        fail();
  end matchcontinue;
end equationToExp;

public function equationInfo "Retrieve the line number information from a BackendDAE.BackendDAE equation"
  input BackendDAE.Equation eq;
  output Absyn.Info info;
algorithm
  info := DAEUtil.getElementSourceFileInfo(equationSource(eq));
end equationInfo;

public function markedEquationSource
  input BackendDAE.EqSystem syst;
  input Integer i;
  output DAE.ElementSource source;
protected
  BackendDAE.EquationArray eqns;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs = eqns) := syst;
  source := equationSource(BackendDAEUtil.equationNth(eqns,i-1));
end markedEquationSource;

public function equationSource "Retrieve the source from a BackendDAE.BackendDAE equation"
  input BackendDAE.Equation eq;
  output DAE.ElementSource source;
algorithm
  source := match eq
    case BackendDAE.EQUATION(source=source) then source;
    case BackendDAE.ARRAY_EQUATION(source=source) then source;
    case BackendDAE.SOLVED_EQUATION(source=source) then source;
    case BackendDAE.RESIDUAL_EQUATION(source=source) then source;
    case BackendDAE.WHEN_EQUATION(source=source) then source;
    case BackendDAE.ALGORITHM(source=source) then source;
    case BackendDAE.COMPLEX_EQUATION(source=source) then source;
  end match;
end equationSource;

public function equationSize "Retrieve the size from a BackendDAE.BackendDAE equation"
  input BackendDAE.Equation eq;
  output Integer osize;
algorithm
  osize := match eq
    local 
      list<Integer> ds;
      Integer size;
      list<BackendDAE.Equation> eqnsfalse;
    case BackendDAE.EQUATION(source=_) then 1;
    case BackendDAE.ARRAY_EQUATION(dimSize=ds)
      equation
        size = List.fold(ds,intMul,1);
      then
        size;
    case BackendDAE.SOLVED_EQUATION(source=_) then 1;
    case BackendDAE.RESIDUAL_EQUATION(source=_) then 1;
    case BackendDAE.WHEN_EQUATION(source=_) then 1;
    case BackendDAE.ALGORITHM(size=size) then size;
    case BackendDAE.COMPLEX_EQUATION(size=size) then size;
    case BackendDAE.IF_EQUATION(eqnsfalse=eqnsfalse)
      equation
        size = equationLstSize(eqnsfalse);
      then size;
    case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"BackendEquation.equationSize failed!"});
      then
        fail();    
  end match;
end equationSize;

public function equationOptSize
  input Option<BackendDAE.Equation> oeqn;
  output Integer size;
algorithm
  size := match(oeqn)
    local BackendDAE.Equation eqn;
    case(NONE()) then 0;
    case(SOME(eqn)) then equationSize(eqn);
  end match;
end equationOptSize;

public function equationLstSize
  input list<BackendDAE.Equation> inEqns;
  output Integer size;
algorithm
  size := equationLstSize_impl(inEqns,0);
end equationLstSize;

protected function equationLstSize_impl
  input list<BackendDAE.Equation> inEqns;
  input Integer isize;
  output Integer size;
algorithm
  size := match(inEqns,isize)
    local
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> rest;
    case({},_) then isize;
    case(eqn::rest,_)
      then
        equationLstSize_impl(rest,isize+equationSize(eqn));
   end match;
end equationLstSize_impl;


public function generateEQUATION "
Author: Frenkel TUD 2010-05"
  input tuple<DAE.Exp,DAE.Exp> inTpl;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
protected
  DAE.Exp e1,e2;
algorithm 
  (e1,e2) := inTpl;
  outEqn :=BackendDAE.EQUATION(e1,e2,Source);
end generateEQUATION;

public function generateRESIDUAL_EQUATION "
Author: Frenkel TUD 2010-05"
  input DAE.Exp inExp;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm 
  outEqn := BackendDAE.RESIDUAL_EQUATION(inExp,Source);
end generateRESIDUAL_EQUATION;

public function daeEqns
  input BackendDAE.EqSystem syst;
  output BackendDAE.EquationArray eqnarr;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs = eqnarr) := syst;
end daeEqns;

public function aliasEquation
"function aliasEquation
  autor Frenkel TUD 2011-04
  Returns the two sides of an alias equation as expressions and cref.
  If the equation is not simple, this function will fail."
  input BackendDAE.Equation eqn;
  output DAE.ComponentRef cr1;
  output DAE.ComponentRef cr2;
  output DAE.Exp e1;
  output DAE.Exp e2;
  output Boolean negate;
algorithm
  (cr1,cr2,e1,e2,negate) := match (eqn)
      local
        DAE.Exp e,ne,ne1;
      // a = b;
      case (BackendDAE.EQUATION(exp=e1 as DAE.CREF(componentRef = cr1),scalar=e2 as  DAE.CREF(componentRef = cr2)))
        then (cr1,cr2,e1,e2,false);
      // a = -b;
      case (BackendDAE.EQUATION(exp=e1 as DAE.CREF(componentRef = cr1),scalar=e2 as  DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr2))))
        equation
          ne = Expression.negate(e1);
        then (cr1,cr2,ne,e2,true);
      case (BackendDAE.EQUATION(exp=e1 as DAE.CREF(componentRef = cr1),scalar=e2 as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr2))))
        equation
          ne = Expression.negate(e1);
        then (cr1,cr2,ne,e2,true);
      // -a = b;
      case (BackendDAE.EQUATION(exp=e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),scalar=e2 as  DAE.CREF(componentRef = cr2)))
        equation
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne,true);
      case (BackendDAE.EQUATION(exp=e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),scalar=e2 as  DAE.CREF(componentRef = cr2)))
        equation
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne,true);
      // a + b = 0
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne1 = Expression.negate(e1);
          ne = Expression.negate(e2);
        then (cr1,cr2,ne1,ne,true);
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne1 = Expression.negate(e1);
          ne = Expression.negate(e2);
        then (cr1,cr2,ne1,ne,true);
      // a - b = 0
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2,false);
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2,false);
      // -a + b = 0
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e1);
        then (cr1,cr2,ne,e2,false);
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e1);
        then (cr1,cr2,ne,e2,false);
      // -a - b = 0
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne,true);
      case (BackendDAE.EQUATION(exp=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2)),scalar=e))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne,true);
      // 0 = a + b 
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne1 = Expression.negate(e1);
          ne = Expression.negate(e2);
        then (cr1,cr2,ne1,ne,true);
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne1 = Expression.negate(e1);
          ne = Expression.negate(e2);
        then (cr1,cr2,ne1,ne,true);
      // 0 = a - b 
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2,false);
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.CREF(componentRef = cr1),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
        then (cr1,cr2,e1,e2,false);
      // 0 = -a + b 
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e1);
        then (cr1,cr2,ne,e2,false);
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e1);
        then (cr1,cr2,ne,e2,false);
      // 0 = -a - b 
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = cr1)),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne,true);
      case (BackendDAE.EQUATION(exp=e,scalar=DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = cr1)),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = cr2))))
        equation
          true = Expression.isZero(e);
          ne = Expression.negate(e2);
        then (cr1,cr2,e1,ne,true);
  end match;
end aliasEquation;

public function derivativeEquation
"function derivativeEquation
  autor Frenkel TUD 2011-04
  Returns the two sides of an derivative equation as expressions and cref.
  If the equation is not a derivative equaiton, this function will fail."
  input BackendDAE.Equation eqn;
  output DAE.ComponentRef cr;
  output DAE.ComponentRef dcr "the derivative of cr";
  output DAE.Exp e;
  output DAE.Exp de "der(cr)";
  output Boolean negate;
algorithm
  (cr,dcr,e,de,negate) := match (eqn)
      local
        DAE.Exp e,ne,ne1;
      // a = der(b);
      case (BackendDAE.EQUATION(exp=e as DAE.CREF(componentRef = dcr),scalar=de as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})))
        then (cr,dcr,e,de,false);
      // der(a) = b;
      case (BackendDAE.EQUATION(exp=de as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),scalar=e as DAE.CREF(componentRef = dcr)))
        then (cr,dcr,e,de,false);
      // a = -der(b);
      case (BackendDAE.EQUATION(exp=e as DAE.CREF(componentRef = cr),scalar=de as  DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = dcr)}))))
        equation
          ne = Expression.negate(e);
        then (cr,dcr,ne,de,true);
      case (BackendDAE.EQUATION(exp=e as DAE.CREF(componentRef = cr),scalar=de as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = dcr)}))))
        equation
          ne = Expression.negate(e);
        then (cr,dcr,ne,de,true);
      // -der(a) = b;
      case (BackendDAE.EQUATION(exp=de as  DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),scalar=e as DAE.CREF(componentRef = dcr)))
        equation
          ne = Expression.negate(e);
        then (cr,dcr,ne,de,true);
      case (BackendDAE.EQUATION(exp=de as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),scalar=e as DAE.CREF(componentRef = dcr)))
        equation
          ne = Expression.negate(e);
        then (cr,dcr,ne,de,true);
      // -a = der(b);
      case (BackendDAE.EQUATION(exp=e as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = dcr)),scalar=de as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})))
        equation
          ne = Expression.negate(de);
        then (cr,dcr,e,ne,true);
      case (BackendDAE.EQUATION(exp=e as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = dcr)),scalar=de as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})))
        equation
          ne = Expression.negate(de);
        then (cr,dcr,e,ne,true);
      // der(a) = -b;
      case (BackendDAE.EQUATION(exp=de as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),scalar=e as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = dcr))))
        equation
          ne = Expression.negate(de);
        then (cr,dcr,e,ne,true);
      case (BackendDAE.EQUATION(exp=de as  DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),scalar=e as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = dcr))))
        equation
          ne = Expression.negate(de);
        then (cr,dcr,e,ne,true);
      // -a = -der(b);
      case (BackendDAE.EQUATION(exp=e as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = dcr)),scalar=de as  DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))))
        then (cr,dcr,e,de,false);
      case (BackendDAE.EQUATION(exp=e as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = dcr)),scalar=de as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}))))
        then (cr,dcr,e,de,false);     
      // -der(a) = -b;
      case (BackendDAE.EQUATION(exp=de as  DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),scalar=e as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = dcr))))
        then (cr,dcr,e,de,false);
      case (BackendDAE.EQUATION(exp=de as  DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),scalar=e as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = dcr))))
        then (cr,dcr,e,de,false);               
  end match;
end derivativeEquation;

public function addOperation
  input BackendDAE.Equation eq;
  input DAE.SymbolicOperation op;
  output BackendDAE.Equation oeq;
algorithm
  oeq := match (eq,op)
    local
      Integer i1,i2,size;
      DAE.Exp e1,e2;
      list<DAE.Exp> es,es1,es2,conditions;
      DAE.ElementSource source;
      BackendDAE.WhenEquation whenEquation;
      DAE.ComponentRef cr1;
      list<BackendDAE.Equation> eqnsfalse;
      list<list<BackendDAE.Equation>> eqnstrue;
      list<Integer> ds;
      DAE.Algorithm alg;
    case (BackendDAE.EQUATION(e1,e2,source),op)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.EQUATION(e1,e2,source);
    case (BackendDAE.ARRAY_EQUATION(ds,e1,e2,source),op)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.ARRAY_EQUATION(ds,e1,e2,source);
    case (BackendDAE.SOLVED_EQUATION(cr1,e1,source),op)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.SOLVED_EQUATION(cr1,e1,source);
    case (BackendDAE.RESIDUAL_EQUATION(e1,source),op)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.RESIDUAL_EQUATION(e1,source);
    case (BackendDAE.ALGORITHM(size,alg,source),op)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.ALGORITHM(size,alg,source);
    case (BackendDAE.WHEN_EQUATION(whenEquation,source),op)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.WHEN_EQUATION(whenEquation,source);
    case (BackendDAE.COMPLEX_EQUATION(size,e1,e2,source),op)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.COMPLEX_EQUATION(size,e1,e2,source);
    case (BackendDAE.IF_EQUATION(conditions,eqnstrue,eqnsfalse,source),op)
      equation
        source = DAEUtil.addSymbolicTransformation(source,op);
      then BackendDAE.IF_EQUATION(conditions,eqnstrue,eqnsfalse,source);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"BackendEquation.addOperation failed"});
      then fail();
  end match;
end addOperation;

public function isWhenEquation
  input BackendDAE.Equation inEqn;
  output Boolean b;
algorithm
  b := match(inEqn)
    case BackendDAE.WHEN_EQUATION(whenEquation=_) then true;
    else then false;
  end match;
end isWhenEquation;

end BackendEquation;
